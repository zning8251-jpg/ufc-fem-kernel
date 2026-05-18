# 四大功能集详细设计文档 — Solver 域（运行时层）

> **文档位置**: `L5_RT/Solver/DESIGN_Solv_FourTypes.md`
> **版本**: v1.0
> **最后更新**: 2026-03-31
> **关联规范**: [@00-域级划分规范.md](UFC/docs/六层架构拆分/00-总纲/00-域级划分规范.md)

---

## 1. 概述

本文档定义 L5_RT/Solver 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：线性/非线性求解、收敛控制、NR 迭代、稀疏矩阵装配、接触残差集成

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `runtime_id` | INTEGER(i4) | 运行时实例 ID | RT_Solv_Base_Desc |
| `solver_label` | CHARACTER(LEN=64) | 求解器配置标签 | RT_Solv_Base_Desc |
| `md_linear` | TYPE(MD_LinearSolver_Desc), POINTER | 线性求解器配置 | RT_Solv_Base_Desc |
| `md_nr` | TYPE(MD_NR_Algo), POINTER | NR 算法配置 | RT_Solv_Base_Desc |
| `md_precond` | TYPE(MD_Precond_Desc), POINTER | 预条件子配置 | RT_Solv_Base_Desc |

**生命周期**：
- **写入阶段**：模型建立时（MD 层）
- **读取阶段**：计算全过程只读
- **释放时机**：模型销毁时

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 步内只读，不进入热路径

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `curr_iter` | INTEGER(i4) | 当前 NR 迭代 | RT_Solv_NRState |
| `max_iter_reached` | INTEGER(i4) | 最大迭代计数 | RT_Solv_NRState |
| `residual_norm` | REAL(wp) | 残差范数 | RT_Solv_NRState |
| `converged` | LOGICAL | 收敛标志 | RT_Solv_NRState |
| `ndof` | INTEGER(i4) | DOF 总数 | RT_Solv_LinearState |
| `nnz` | INTEGER(i4) | 刚度矩阵非零元数 | RT_Solv_LinearState |
| `sparse_matrix%values(:)` | REAL(wp), ALLOCATABLE | 稀疏矩阵值 | RT_Solv_LinearState |
| `sparse_matrix%row_ptr(:)` | INTEGER(i4), ALLOCATABLE | 行指针 | RT_Solv_LinearState |
| `sparse_matrix%col_idx(:)` | INTEGER(i4), ALLOCATABLE | 列索引 | RT_Solv_LinearState |

**生命周期**：
- **写入阶段**：每次增量步/迭代更新
- **读取阶段**：增量步内多迭代复用
- **释放时机**：增量步结束时

**内存策略**：
- 温数据，Step 级 ALLOCATE
- 高频读写，进入热路径
- 需 Rollback 机制支持

---

### 2.3 Algo（算法型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `nr_max_iter` | INTEGER(i4) | NR 最大迭代数 | RT_Solv |
| `nr_max_severe` | INTEGER(i4) | 严重不连续限值 | RT_Solv |
| `res_tol` | REAL(wp) | 残差容差 | RT_Solv |
| `energy_tol` | REAL(wp) | 能量容差 | RT_Solv |
| `line_search_max_iter` | INTEGER(i4) | 线搜索最大迭代 | RT_Solv |
| `ai_enabled` | LOGICAL | AI 收敛预测开关 | AI_ConvPredict_Algo |
| `ai_model_path` | CHARACTER(LEN=256) | AI 模型路径 | AI_ConvPredict_Algo |

**生命周期**：
- **写入阶段**：分析步初始化
- **读取阶段**：迭代内只读
- **释放时机**：分析步结束

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 迭代内只读，跨步复用

---

### 2.4 Ctx（上下文型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `step_id` | INTEGER(i4) | 当前分析步 ID | RT_Solv_Ctx |
| `incr_id` | INTEGER(i4) | 当前增量步 ID | RT_Solv_Ctx |
| `time_current` | REAL(wp) | 当前时间 | RT_Solv_Ctx |
| `time_total` | REAL(wp) | 总时间 | RT_Solv_Ctx |
| `res_tol_rel` | REAL(wp) | 相对残差容差 | RT_Solv_ConvergenceCtx |
| `res_tol_abs` | REAL(wp) | 绝对残差容差 | RT_Solv_ConvergenceCtx |
| `contact_residual(:)` | REAL(wp), ALLOCATABLE | 接触残差矢量 | RT_Solv_Cont_Residual |

**生命周期**：
- **写入阶段**：每次增量步入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回即释放

**内存策略**：
- **热路径核心，零 ALLOCATE**
- 64-byte 对齐（AVX-512）
- 栈分配，禁止堆分配

---

## 3. AI-ready 插槽集成

| 插槽编号 | 插槽名称 | 域级归属 | 四型职责 |
|----------|---------|---------|----------|
| ② | AI_ConvPredict | Solver | Algo（收敛准则）+ State（残差历史） |

**接口规范**：
- 文件：`AI_ConvPredict_Algo.f90`
- 神经网络预测收敛趋势
- 批量推理接口

---

## 4. 核心功能模块

| 模块 | 文件 | 职责 |
|------|------|------|
| 线性求解 | `RT_Solv_Lin_Core.f90` | 直接/迭代求解器 |
| 非线性求解 | `RT_Solv_Nonlin.f90` | NR 迭代控制 |
| 稀疏矩阵 | `RT_Solv_Sparse_Core.f90` | CSR 装配 |
| 时间积分 | `RT_Solv_TimeInt_Core.f90` | Newmark/HHT-α |
| 接触残差 | `RT_Solv_Cont_Residual.f90` | 接触约束集成 |

---

## 5. 依赖关系

```
MD_NR_Algo (L3) → RT_Solv (L5) → RT_Solv_Ctx (L5)
MD_LinearSolver_Desc (L3) → RT_Solv_State (L5) → RT_Solv_Ctx (L5)
L4_PH/Contact (L4) → RT_Solv_Cont_Residual (L5)
RT_Solv (L5) → RT_Solv_Ctx (L5) → RT_Solv_State (L5)
```

---

## 6. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含 L3 配置引用 | ✅ | 线性/NR/预条件子 |
| State 含线性/非线性状态 | ✅ | 完整迭代追踪 |
| Algo 含 NR/线搜索参数 | ✅ | 收敛控制 |
| Ctx 零 ALLOCATE | ✅ | AP-8 热路径约束 |
| AI 插槽已部署 | ✅ | AI_ConvPredict_Algo |
| 稀疏矩阵支持 | ✅ | CSR 格式 |

---

**版本历史**：
- v1.0 (2026-03-31) - 初始版本