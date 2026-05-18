## Solv（Solver 配置）域级合同卡

> **版本**: v2.0 · **最后更新**: 2026-04-25 · **Phase 1 样板间完整落地**

- **层级**：L3_MD
- **域名**：Solver **配置 Desc**（非 L2 数值核）
- **缩写**：Solv（`MD_Solv_*`、`MD_Solver_*`）
- **职责**：求解器类型、容差、最大迭代等 **输入侧** 元数据；**不**实现稀疏求解算法。
- **热路径**：**否**。

---

### 域概述

L3_MD/Analysis/Solver 是 L3 模型数据层 Analysis 域下的 **求解器配置** 子域。其唯一职责是存储和管理求解器的输入侧描述参数（solver type、tolerances、max iterations 等），作为 L5_RT/Solver 和 L2_NM/Solver 的 **SSOT 配置来源**。本域不包含任何数值求解算法，不参与热路径。

---

### 职责边界

| 本域负责 | 本域**不**负责 |
|----------|---------------|
| 求解器参数描述（类型、容差、迭代上限） | 线性/非线性求解算法（→ L2_NM/Solver） |
| 配置的增删查（AddConfig / GetConfig） | Newton 迭代残差累积（→ L5_RT/Solver State） |
| Step 到 Solver 配置的同步映射 | 求解器分发调度（→ L5_RT/Solver） |
| 参数合法性校验（拒绝非正容差等） | 瞬态工作区管理（→ L5/L2 Ctx） |

---

### 四型定义

定义见 **`MD_Solv_Def`**；L3 配置域 **主真相** 为 **`MD_Solver_Desc` + `MD_Solver_Domain`**。

| 四型 | TYPE 名 | 温度 | 生命周期 | 说明 |
|------|---------|------|----------|------|
| **Desc** | `MD_Solver_Desc` | 冷 | 建模期写一次，求解期只读 | 与 Step 侧 `UF_SolutionControl` / Sync 对齐 |
| **Algo** | `MD_Solver_Algo` | 冷 | 建模期 | Newton/回切等扩展字段；经 `MD_Solver_Desc_From_Algo` / `MD_Solver_Algo_From_Desc` 互转 |
| **State** | `MD_Solver_State` | — | 占位 | L3 占位；运行时真相在 L5/L2 |
| **Ctx** | `MD_Solver_Ctx` | — | 占位 | L3 占位；瞬态工作区在 L5/L2 |

桩类型 `MD_LinearSolver_Desc` / `MD_NR_Algo` / `MD_Precond_Desc` 供 L5 路由预留。

---

### 核心接口（按功能集）

| 功能集 | 绑定 | 入口（调用面） | 说明 |
|--------|------|----------------|------|
| Init | `MD_Solver_Domain%Init` | `MD_Solver_Domain%Init` | 初始化域容器 |
| Finalize | `MD_Solver_Domain%Finalize` | `MD_Solver_Domain%Finalize` | 释放资源 |
| Mutate | `MD_Solver_Domain%AddConfig` | `MD_Solver_Domain%AddConfig` | 建模期增加配置 |
| Query | `MD_Solver_Domain%GetConfig` | `MD_Solver_Domain%GetConfig` | 查询配置 |
| Query | `MD_Solver_Domain%GetSummary` | `MD_Solver_Domain%GetSummary` | 汇总信息 |
| Query | — | `MD_Solver_GetConfig_Idx` | 按索引查询 |
| Bridge | — | `MD_Solver_Brg_GetConfigForStep` | 按步查询（供 L5） |
| Sync | — | `MD_Solver_SyncFromStep` | Step sol_ctrl → 域同步 |

---

### 依赖关系

| 方向 | 模块 | 层 | 说明 |
|------|------|----|------|
| USE ← | `IF_Prec_Core` | L1_IF | wp, i4 |
| USE ← | `IF_Err_Brg` | L1_IF | ErrorStatusType |
| USE ← | `MD_Step` / `MD_Step_Proc` | L3_MD | Step 域的 UF_SolutionControl |
| USE ← | `MD_L3Layer` | L3_MD | 容器（仅 Sync 模块） |
| USE ← | `UFC_GlobalContainer_Core` | L3_MD | g_ufc_global（仅 **`MD_Solv_Mgr`** 路径） |
| USE → | L5_RT/Solver | L5_RT | L5 读取本域 Desc（通过 Bridge） |
| USE → | L2_NM/Solver | L2_NM | L2 消费本域的收敛参数 |

**环依赖防护**：`MD_Solv_Sync` 独立模块，避免 **`MD_L3Layer` ↔ `MD_Solv_Mgr`** 环（`L3` 容器已 `USE MD_Solv_Mgr`）。

---

### 错误处理

| 错误场景 | 错误码 | 严重级 | 处理方式 |
|----------|--------|--------|----------|
| `max_iterations < 1` | `IF_STATUS_INVALID` | WARN | AddConfig 拒绝，返回 status |
| 非正容差（residual/correction/energy_tol） | `IF_STATUS_INVALID` | WARN | AddConfig 拒绝 |
| SyncFromStep 时 `l3Frozen=.TRUE.` | `IF_STATUS_INVALID` | ERROR | 同步中止，保持原状 |
| SyncFromStep 单步失败 | `IF_STATUS_INVALID` | ERROR | 事务回滚至调用前状态 |
| configs 数组越界 | `IF_STATUS_INVALID` | ERROR | 返回 status，不 STOP |

**不变量**：所有公开过程接受 `ErrorStatusType` 的 `status` 参数（INTENT(OUT)），通过 `init_error_status` 初始化后设置。**不使用** `STOP`。

---

### 域际关系

| 序号 | 关联域（层/域路径） | 相对本域 | 契约类型 | 主要接触面 | 备注 |
|------|---------------------|----------|----------|------------|------|
| R1 | L3_MD/Analysis/Step | 上游 | T+U | `UF_SolutionControl`（Step 侧 sol_ctrl 字段）→ `MD_Solver_SyncFromStep` | Sync 依赖 Step 的分析步定义 |
| R2 | L5_RT/Solver | 下游 | T+B | `MD_Solver_Desc` 经 `MD_Solver_Brg_GetConfigForStep` → L5 读取 | L5 消费本域配置 |
| R3 | L2_NM/Solver | 下游 | T | `MD_Solver_Desc` 的容差/迭代参数 → L2 收敛判据 | 间接消费（经 L5 转发） |
| R4 | L3_MD（L3Layer 容器） | 上游 | U | `MD_L3_LayerContainer` → `MD_Solv_Sync` 读取容器 | 同步时需访问 md_layer |

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**本域保留 `*_Arg`**：`MD_Solver_AddConfig_Arg`、`MD_Solver_GetConfig_Arg`、`MD_Solver_GetSummary_Arg`、`MD_Solver_GetConfigForStep_Arg`。

**本域不提供 `*_Arg`**：`MD_Solver_SyncFromStep` — 主 API 签名 `(md_layer, status)` 即足，无额外协同字段。

---

### 约束分级

| 约束 | 级别 | 说明 |
|------|------|------|
| 不实现数值求解（职责边界） | **硬** | 违反则架构原则崩溃 |
| Desc 建模期冻结后只读 | **硬** | 求解期改写 Desc 会导致不确定行为 |
| AddConfig 拒绝非法参数 | **硬** | 非正容差/迭代≤0 必须拒绝 |
| SyncFromStep 事务语义（回滚） | **硬** | 部分失败后状态不一致不可接受 |
| 不使用 STOP（错误传播） | **硬** | H-ERR-01 门禁 |
| State/Ctx 占位（不累积运行状态） | **软** | 后续若需 L3 侧缓存可扩展 |
| 桩类型（LinearSolver_Desc 等）完善 | **软** | 当前为预留，L5 路由就绪后补齐 |

---

### 十件套 v2.0 映射

| 序号 | 逻辑件 | 物理落地 | 状态 |
|------|--------|----------|------|
| 1 | **Contract** | `CONTRACT.md`（本文件） | Active |
| 2 | **Definition / Schema** | `MD_Solv_Def.f90` | Active |
| 3 | **Description (Desc)** | TYPE `MD_Solver_Desc` in `MD_Solv_Def.f90` | Active |
| 4 | **State** | TYPE `MD_Solver_State` in `MD_Solv_Def.f90` | Active（占位） |
| 5 | **Algorithm Descriptor (Algo)** | TYPE `MD_Solver_Algo` in `MD_Solv_Def.f90` | Active |
| 6 | **Context (Ctx)** | TYPE `MD_Solver_Ctx` in `MD_Solv_Def.f90` | Active（占位） |
| 7 | **Main Algorithm / Kernel** | `MD_Solv_Mgr.f90`（`MD_Solver_Domain` TBP + SIO Apply） | Active |
| 8 | **Bridge / Facade** | `MD_Solver_Brg_GetConfigForStep*` in `MD_Solv_Mgr.f90`（Bridge 并入主模块） | Merged |
| 9 | **Runtime Procedure / SIO Entry** | N/A（本域非 L5，无 `_Proc`） | N/A |
| 10 | **Registry / Index / Map** | `MD_Solver_GetConfig_Idx` in `MD_Solv_Mgr.f90` | Merged |
| 11 | **Populate / Builder / Import** | `MD_Solver_SyncFromStep` in `MD_Solv_Sync.f90` | Active |
| 12 | **Diagnostics / IO / Dump** | `MD_Solver_Domain%GetSummary` in `MD_Solv_Mgr.f90` | Active（基础） |
| 13 | **Test / Mock** | 待建 `Tests/` | Deferred |

---

### 四链说明

| 链 | 本域可核对说明 |
|----|---------------|
| **理论链** | 求解器配置映射 ABAQUS `*CONTROLS` / `*SOLUTION TECHNIQUE` 关键字参数到 `MD_Solver_Desc` 字段（solver_type, residual_tol, correction_tol, max_iterations 等），不涉及数值理论本身 |
| **逻辑链** | `KeyWord Parser` → `Step.sol_ctrl` → `MD_Solver_SyncFromStep` → `MD_Solver_Domain.configs(:)` → `MD_Solver_Brg_GetConfigForStep` → L5_RT/Solver 消费；单向数据流，无反馈 |
| **计算链** | 本域无计算；唯一数值操作为 `AddConfig` 中的参数合法性校验（正值检查），O(1) |
| **数据链** | `MD_Solver_Desc`（冷，建模期写入）存储在 `MD_Solver_Domain%configs(:)` 数组中，按 step 索引映射；Sync 成功后 CompactConfigs 回收多余空间；销毁在 `Finalize` |

---

### 细粒度清单（TYPE / 过程 / 绑定）

| 文件 | `MODULE` | TYPE（`PUBLIC`） | 过程 / TBP |
|------|----------|------------------|------------|
| `MD_Solv_Def.f90` | `MD_Solv_Def` | `MD_Solver_Desc`, `MD_Solver_Algo`, `MD_Solver_State`, `MD_Solver_Ctx`；桩 `MD_LinearSolver_Desc`, `MD_NR_Algo`, `MD_Precond_Desc` | `MD_Solver_Desc_Init`, `MD_Solver_Desc_SetTolerances`, `MD_Solver_Desc_Finalize`；`MD_Solver_Desc_From_Algo`、`MD_Solver_Algo_From_Desc` |
| `MD_Solv_Mgr.f90` | `MD_Solv_Mgr` | `MD_Solver_Domain`；SIO `MD_Solver_AddConfig_Arg`, `MD_Solver_GetConfig_Arg`, `MD_Solver_GetSummary_Arg`、`MD_Solver_GetConfigForStep_Arg` | TBP：`MD_Solver_Domain%Init`、`MD_Solver_Domain%Finalize`、`MD_Solver_Domain%AddConfig`、`MD_Solver_Domain%GetConfig`、`MD_Solver_Domain%GetSummary`；`MD_Solver_Apply_AddConfig_Arg`、`MD_Solver_Apply_GetConfig_Arg`、`MD_Solver_Apply_GetSummary_Arg`；`MD_Solver_GetConfig_Idx` / `MD_Solver_Apply_GetConfig_Idx_Arg`；`MD_Solver_Brg_GetConfigForStep`、`MD_Solver_Brg_GetConfigForStep_Select`；`MD_Solver_Apply_GetConfigForStep_Arg`、`MD_Solver_Apply_GetConfigForStep_Select_Arg` |
| `MD_Solv_Sync.f90` | `MD_Solv_Sync` | — | `MD_Solver_SyncFromStep`（主 API）；内部 `SolCtrl_To_SolverDesc`（`PRIVATE`）；`MD_Solv_Sync_CompactConfigs`（`PRIVATE`） |

---

### 数值可靠性

`MD_Solver_Domain%AddConfig` 拒绝 `max_iterations < 1` 及非正容差（`residual_tol` / `correction_tol` / `energy_tol`），避免下游 L5/L2 使用非法收敛阈值。

---

### 同步事务语义（幂等）

`MD_Solver_SyncFromStep` 每次调用先清空当前 `MD_Solver_Domain` 逻辑计数与各步 `solver_config_id`，再按步 `sol_ctrl` 重建；任一步失败则完整恢复调用前的 `configs(1:n_prev)`、`n_configs` 与各步 `solver_config_id`。**要求**：`l3Frozen=.FALSE.`。

---

### 存储紧凑化

同步成功后调用内部 `MD_Solv_Sync_CompactConfigs`：若 `SIZE(configs) > MAX(16, n_configs)`，则收缩为 `MAX(16, n_configs)`，丢弃尾部陈旧槽位（分配失败则保持原状）。

---

### 与跨层灵敏度契约的衔接

本域不承载 Newton 迭代中的全局残差向量 R、L2 数值求解 State。灵敏度与优化场景下 R、θ 在四型中的落位见跨层摘要卡：[`../../contracts/CONTRACT_R_Theta_FourKind.md`](../../contracts/CONTRACT_R_Theta_FourKind.md)。

---

### 对端合同

- **L4_PH**：无（本域仅求解配置 Desc；数值求解在 L5 `Solver/` + L2）。
- **L5_RT/Solver**：[`../../../../L5_RT/Solver/CONTRACT.md`](../../../../ufc_core/L5_RT/Solver/CONTRACT.md) — 消费本域 `MD_Solver_Desc`。
- **L2_NM/Solver**：[`../../../../L2_NM/Solver/CONTRACT.md`](../../../../ufc_core/L2_NM/Solver/CONTRACT.md) — 间接消费容差参数。

---

### Partial Pillar v2.0 Update (H4b Solver)

> 更新日期: 2026-04-26

**半柱分类**: H4b Solver 是 L3+L5 半贯通柱，L4 无独立 Solver 目录。

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| L3 | `MD_Solv_Def.f90` | **AUTHORITY** — 求解器配置 Desc/Algo (本层) | ACTIVE |
| L3 | `MD_Solv_Mgr.f90` | 域容器 + SIO Apply + Bridge | ACTIVE |
| L3 | `MD_Solv_Sync.f90` | Legacy Populate | ACTIVE |
| L4 | (不存在) | 求解器非单元级物理计算 | — |
| L5 | `RT_Solv_Def.f90` | **AUTHORITY** — 运行时求解器类型 (本层) | ACTIVE |
| L5 | `RT_Solv.f90` | **GOLDEN-LINE** — 生产求解器框架 | ACTIVE |
| L5 | `RT_Solv_Nonlin.f90` | GOLDEN-LINE — 非线性求解核 | ACTIVE |

**L4 缺席说明**: 求解器是方程组级概念（全局 K·x=F），L4 各域提供单元级贡献（Ke/Fe）但不参与全局求解决策。求解器配置从 L3 直达 L5，跳过 L4。

**跨层数据流**: `MD_Solver_Desc`(L3) → `MD_Solver_Brg_GetConfigForStep` → L5 `RT_SolverSys_*` 消费
