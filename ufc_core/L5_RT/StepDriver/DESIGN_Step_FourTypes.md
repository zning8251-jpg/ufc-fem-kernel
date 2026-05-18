# 四大功能集详细设计文档 — StepDriver 域

> **文档位置**: `L5_RT/StepDriver/DESIGN_Step_FourTypes.md`
> **版本**: v2.0
> **最后更新**: 2026-04-28
> **关联规范**: `L5_RT/StepDriver/DOMAIN_PILLAR_CARD.md`（域柱卡）

---

## 1. 概述

本文档定义 L5_RT/StepDriver 域的四大功能集（Desc/State/Algo/Ctx）详细设计，包括字段定义、生命周期管理、内存策略。

**域级职责**：分析步驱动、增量步控制、时间步长预测、迭代控制

---

## 2. 功能集详细设计

### 2.1 Desc（描述型）

| 字段名 | 类型 | 语义 | 来源 |
|--------|------|------|------|
| `step_idx` | INTEGER(i4) | 步索引 | RT_StepDriver_Desc |
| `step_id` | INTEGER(i4) | 步 ID | RT_StepDriver_Desc |
| `category` | INTEGER(i4) | 步类型 | RT_StepDriver_Desc |
| `n_steps` | INTEGER(i4) | 总步数 | RT_StepDrv_Desc |
| `job_name` | CHARACTER(LEN=64) | 作业名称 | RT_StepDrv_Desc |

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
| `current_step_idx` | INTEGER(i4) | 当前步索引 | RT_StepDriver_State |
| `current_increment` | INTEGER(i4) | 当前增量步 | RT_StepDriver_State |
| `current_iteration` | INTEGER(i4) | 当前迭代 | RT_StepDriver_State |
| `current_step` | INTEGER(i4) | 当前分析步 | RT_StepDrv_State |
| `total_increments` | INTEGER(i4) | 总增量步数 | RT_StepDriver_Result |
| `converged` | LOGICAL | 收敛标志 | RT_StepDriver_Result |
| `success` | LOGICAL | 成功标志 | RT_StepDriver_Result |

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
| `max_iter` | INTEGER(i4) | 最大迭代数 | RT_StepDriver_Algo |
| `tol_residual` | REAL(wp) | 残差容差 | RT_StepDriver_Algo |
| `tol_displ` | REAL(wp) | 位移容差 | RT_StepDriver_Algo |
| `job_control_method` | INTEGER(i4) | 作业控制方法 | RT_StepDrv_Algo |
| `step_sequence_strategy` | INTEGER(i4) | 步序列策略 | RT_StepDrv_Algo |
| `dt_increase_factor` | REAL(wp) | 时间增量增长因子 | RT_StepDrv_Algo |
| `ai_enabled` | LOGICAL | AI 步长预测开关 | AI_StepCtr_Algo |
| `ai_model_path` | CHARACTER(LEN=256) | AI 模型路径 | AI_StepCtr_Algo |

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
| `t_start` | REAL(wp) | 起始时间 | RT_StepDriver_TimeCfg |
| `t_end` | REAL(wp) | 终止时间 | RT_StepDriver_TimeCfg |
| `dt_init` | REAL(wp) | 初始时间步 | RT_StepDriver_TimeCfg |
| `work_vec(:)` | REAL(wp), POINTER | 工作矢量 | RT_StepDriver_Ctx |
| `temp_scalar` | REAL(wp) | 临时标量 | RT_StepDriver_Ctx |
| `pool_slot` | INTEGER(i4) | 内存池槽位 | RT_StepDriver_Ctx |
| `grow_factor` | REAL(wp) | 增长因子 | RT_StepDTCtrl |
| `cutback_factor` | REAL(wp) | 回退因子 | RT_StepDTCtrl |

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
| ① | AI_StepCtr | StepDriver | Algo（步长预测参数）+ Ctx（历史缓存） |

**接口规范**：
- 文件：`AI_StepCtr_Algo.f90`
- 神经网络步长预测
- 批量推理接口

---

## 4. 时间步长控制策略

| 策略 | 值 | 说明 |
|------|-----|------|
| `DT_CTRL_AUTO` | 1 | 自动时间步长 |
| `DT_CTRL_FIXED` | 2 | 固定时间步长 |
| `DT_CTRL_ADAPTIVE` | 3 | 自适应时间步长 |

---

## 5. 四型裁剪决策（三层统一视图）

| 层 | Desc | State | Algo | Ctx |
|----|------|-------|------|-----|
| L3 | RETAINED(`MD_Step_Desc`) | RETAINED(`MD_Step_State`) | RETAINED(`MD_Step_Algo`) | TRIMMED |
| L4 | N/A(无独立域) | N/A | N/A | N/A |
| L5 | DELEGATED->L3(via Populate) | RETAINED(`RT_Step_State`) | RETAINED(`RT_Step_Algo`) | RETAINED(`RT_Step_Ctx`) |

**裁剪说明**：
- L3 保留步定义Desc/State/Algo权威，Ctx由L5独立持有
- L4 无独立StepDriver域，不参与四型裁剪
- L5 Desc委托L3(经Populate)，State/Algo/Ctx均保留为运行时载体

---

## 6. 依赖关系

```text
MD_Step_Desc(L3) → RT_Step_Populate → RT_Step_Desc/State/Algo(L5)
RT_Step_Algo(L5) → RT_Step_Exec 状态机(L5) → RT_Step_Impl 分派(L5)
RT_Step_Impl(L5) → L4_PH 残差/切线 → L2_NM 线性求解
RT_Step_Ctx(L5) → RT_Step_WS 工作空间(L5) → RT_Step_Core 编排(L5)
RT_Step_Brg(L5) → L4_PH Material/Element/Contact/LoadBC/Field 物理核
```

---

## 7. 验证清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| Desc 含步配置 | PASS | 步索引/类型/作业名 |
| State 含增量步/迭代追踪 | PASS | 完整进度追踪 |
| Algo 含收敛/步长参数 | PASS | 容差/迭代控制 |
| Ctx 零 ALLOCATE | PASS | AP-8 热路径约束 |
| AI 插槽已部署 | PASS | AI_StepCtr_Algo(插槽①) |
| 时间步长控制 | PASS | AUTO/FIXED/ADAPTIVE 三策略 |
| 三层裁剪表对齐 | PASS | 与域柱卡 Section 3 一致 |
| L3 Ctx TRIMMED | PASS | 上下文由L5独立持有 |
| 金线主链完整 | PASS | L6→L3 Def→L5 Populate→Exec→L4/L2→Output |

---

**版本历史**：
- v2.0 (2026-04-28) - 对齐域柱卡v2统一模板，增加三层裁剪视图与依赖链更新
- v1.0 (2026-03-31) - 初始版本