# 四大功能集详细设计文档 — Solver 域（数值算法层）

> **文档位置**: `L2_NM/Solver/DESIGN_Solver_FourTypes.md`
> **版本**: v1.0
> **最后更新**: 2026-03-31
> **关联规范**: [@00-域级划分规范.md](UFC/docs/六层架构拆分/00-总纲/00-域级划分规范.md)

---

## 1. 概述

本文档定义 L2_NM/Solver 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：线性/非线性求解器、预条件子、稀疏求解、伴随求解

**AI-ready 插槽**：
- ⑤ AI_Precond（预条件子）
- ⑥ AI_SparseSolver（稀疏求解器）
- ⑦ AI_AdjointSolver（伴随求解器）

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `solver_type` | INTEGER(i4) | 求解器类型：1=Direct, 2=Iterative | NM_Solver_Desc |
| `precond_type` | INTEGER(i4) | 预条件子类型 | NM_Precond_Desc |
| `max_iter` | INTEGER(i4) | 最大迭代次数 | NM_Solver_Desc |
| `tolerance` | REAL(wp) | 收敛容差 | NM_Solver_Desc |
| `restart_dim` | INTEGER(i4) | GMRES 重启维数 | NM_Solver_Desc |

**生命周期**：
- **写入阶段**：分析步初始化
- **读取阶段**：迭代内只读
- **释放时机**：分析步结束

**内存策略**：
- 冷数据，可 ALLOCATABLE
- 跨步复用

---

### 2.2 State（状态型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `iter_count` | INTEGER(i4) | 当前迭代计数 | NM_Solver_State |
| `residual_norm` | REAL(wp) | 残差范数 | NM_Solver_State |
| `converged` | LOGICAL | 收敛标志 | NM_Solver_State |
| `matrix_is_symmetric` | LOGICAL | 矩阵对称标志 | NM_Solver_State |
| `factorization_ready` | LOGICAL | 分解就绪标志 | NM_Solver_State |

**生命周期**：
- **写入阶段**：每次迭代更新
- **读取阶段**：迭代内复用
- **释放时机**：求解器重置

**内存策略**：
- 温数据，Step 级 ALLOCATE
- 高频读写

---

### 2.3 Algo（算法型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `gmres_restart` | INTEGER(i4) | GMRES 重启维数 | NM_Solver_Algo |
| `krylov_dim` | INTEGER(i4) | Krylov 子空间维数 | NM_Solver_Algo |
| `ai_precond_enabled` | LOGICAL | AI 预条件子开关 | AI_Precond_Algo |
| `ai_sparse_solver_enabled` | LOGICAL | AI 稀疏求解开关 | AI_SparseSolver_Algo |
| `ai_adjoint_enabled` | LOGICAL | AI 伴随求解开关 | AI_Adjoint_Algo |
| `ai_model_path` | CHARACTER(LEN=256) | AI 模型路径 | AI_*_Algo |

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
| `rhs_vector(:)` | REAL(wp), ALLOCATABLE | 右端矢量 | NM_Solver_Ctx |
| `solution_vector(:)` | REAL(wp), ALLOCATABLE | 解矢量 | NM_Solver_Ctx |
| `work_array(:)` | REAL(wp), ALLOCATABLE | 工作数组 | NM_Solver_Ctx |
| `temp_matrix(:,:)` | REAL(wp), ALLOCATABLE | 临时矩阵 | NM_Solver_Ctx |

**生命周期**：
- **写入阶段**：求解器调用入口
- **读取阶段**：单次调用内
- **释放时机**：调用返回

**内存策略**：
- **热路径核心，零 ALLOCATE**
- 64-byte 对齐（AVX-512）
- 栈分配，禁止堆分配

---

## 3. AI-ready 插槽集成

| 插槽编号 | 插槽名称 | 域级归属 | 四型职责 |
|----------|---------|---------|----------|
| ⑤ | AI_Precond | Solver | Algo（预条件子配置） |
| ⑥ | AI_SparseSolver | Solver | Algo（稀疏求解策略） |
| ⑦ | AI_AdjointSolver | Solver | Algo（伴随求解配置，仅离线激活） |

**接口规范**：
- AI_Precond: `AI_Precond_Algo.f90`
- AI_SparseSolver: `AI_SparseSolver_Algo.f90`
- AI_AdjointSolver: `AI_Adjoint_Algo.f90`

**启动时序**：
- 插槽⑤⑥：AI P1 阶段
- 插槽⑦：AI P3 阶段（或 AI P1-C 试点离线灵敏度分析）

---

## 4. 核心求解算法

| 算法 | 文件 | 说明 |
|------|------|------|
| GMRES | `LinSolv/GMRES_Core.f90` | 广义最小残差法 |
| GMRES-Transpose | `GMRES_Solve_Transpose.f90` | 伴随求解专用 |
| CG | `LinSolv/CG_Core.f90` | 共轭梯度法 |
| Direct | `NM_Solver_Direct.f90` | 直接求解器 |
| SVD | `NM_Solver_SVD_Core.f90` | 奇异值分解 |

---

## 5. 依赖关系

```
NM_Solver_Algo (L2) → NM_Solver_Ctx (L2) → NM_Solver_State (L2)
NM_Matrix_CSR (L2) → NM_Solver_Ctx (L2)
RT_Solver (L5) → NM_Solver (L2)  [求解器调用]
```

---

## 6. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含求解器配置 | ✅ | 类型/容差/迭代控制 |
| State 含迭代追踪 | ✅ | 收敛历史 |
| Algo 含 AI 插槽 | ✅ | ⑤⑥⑦ 三个插槽 |
| Ctx 零 ALLOCATE | ✅ | AP-8 热路径约束 |
| GMRES-Transpose 支持 | ✅ | 伴随求解 |
| SVD 封装 | ✅ | LAPACK 封装 |

---

**版本历史**：
- v1.0 (2026-03-31) - 初始版本