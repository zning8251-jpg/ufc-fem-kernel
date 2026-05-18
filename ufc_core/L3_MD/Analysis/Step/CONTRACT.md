## Step 域级合同卡

- **层级**：L3_MD
- **域名**：Step / 分析步与过程元数据
- **缩写**：Step（`MD_Step_*`）
- **合同同步（2026-05-12）**：`MODULE` 列与 **`MD_Step_Mgr.f90`** 头一致（**`MODULE MD_Step_Mgr`**）；**`MD_Step_Desc` / `MD_Step_Domain` / `StepAlgo`** 均在 **`MD_Step_Mgr`**，**`MD_Step_Def`** 仅 **`MD_Step_State` / `MD_Step_Ctx`**。总索引见 **`../Analysis/CONTRACT.md` §二**。
- **职责**：分析步、过程类型（PROC_*）、步级控制参数等 **Desc**；对齐 HYPLAS **ININCR/过程** 的 **输入定义**，不在 L3 做增量求解。
- **四型裁剪决策** (v4.0, 议题2):
  - **Desc**：Y -- 步表、过程枚举、与 LoadBC/Out 的关联索引（核心产出）。
  - **State**：Y -- current_time/increment/is_active/is_complete 等分离态字段。
  - **Ctx**：Y -- 步进推演上下文（增量信息）。
  - **Algo**：Y -- StepAlgo 块（步级元数据算法，非 Newton 体本身）。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Init | `MD_Step_Domain_Init` 等 | |
| Query | Get | 只读 |
| Valid | 步引用检查 | |

- **依赖**：Model、LoadBC、Out、Solv 等。
- **Bridge**：经 L5 StepDriver 消费；无单一模块名时见总索引。
- **热路径**：**否**。

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### P7 职责子表（ININCR 元数据 / 方案 §5.2）

| 条目 | 本域（Step）责任 | 禁止 |
|------|------------------|------|
| `*STEP` / `*END STEP` | 步容器、`MD_Step_Domain_AddStep` 等 | 增量循环实现 |
| 过程关键字（`*STATIC`、`*DYNAMIC`、`*HEAT TRANSFER`、…） | `MD_Step_Proc`（PROC_*）写入步 Desc | Newton 迭代体 |
| `*CONTROLS`、时间/增量 **输入**参数 | `MD_Step_Opt` / `MD_Step_Core`（按实现） | 运行时覆盖已冻结 Desc |
| WriteBack | 仅 **白名单**（`current_time`、`current_increment`、`is_complete` 等） | 写回 `procedure`/材料 |

**主模块（与源码一致）**：**`MD_Step_Mgr.f90`**（**`MODULE MD_Step_Mgr`**，`MD_Step_Domain`）、**`MD_Step_Def.f90`**、**`MD_Step_Proc.f90`**、**`MD_Step_Sync.f90`**。

**关键字 → 模块表**：[INDATA_MAP.md](INDATA_MAP.md) §6。

- **对端 L4 Populate**：层顺序与桥接约定见 [`../../../L4_PH/Bridge/CONTRACT.md`](../../../L4_PH/Bridge/CONTRACT.md)（步级 Desc 由冷路径 **`PH_L4_Populate_*`** 消费；PROC→Runner 见 PPLAN 金线映射文档 §7）。

### 核心模块（当前树）

- `MD_Step_Mgr.f90` — **`MODULE MD_Step_Mgr`**：**`MD_Step_Domain`**、**`MD_Step_Desc`**、**`StepAlgo`**、Init/AddStep/Get/WriteBack/Idx API、SIO `MD_Step_*_Arg`、TBP
- `MD_Step_Def.f90` — **`MODULE MD_Step_Def`**：仅 **`MD_Step_State`**、**`MD_Step_Ctx`**（四型中的 State/Ctx）；**`MD_Step_Desc` / `MD_Step_Domain` / `StepAlgo`** 在 **`MD_Step_Mgr`**
- `MD_Step_Proc.f90` — **`MODULE MD_Step_Proc`**：`PROC_*`、`UF_Step*` / `UF_AnalysisStep`（多域 `USE`）；新增 `ProcToSolverType` (PROC_* → RT_SOLVER_*)
- `MD_Step_Sync.f90` — **`MODULE MD_Step_Sync`**：`MD_Step_SyncFromLegacy`；**`UF_Step_BuildLegacyLoadDefs_FromLdbc`**（LoadBC → 扁平 **`LoadDef(:)`**，供 L5 **`RT_Asm_GlobalLoad`** 冷路径；原独立模块已并入本文件）

**可选 Legacy 载荷接线（L5）**：`UF_StepDef` / `UF_AnalysisStep` 含 **`loadDefs`** 指针（`MD_Load_Mgr::LoadDef`）。解析或驱动在步生命周期内对 **`TARGET`** 的 **`load_array(:)`** 调用 **`UF_Step_AttachLoadDefs(step, load_array)`**，供 **`RT_Asm_GlobalLoad`** Legacy 分支消费；**`UF_Step_ClearLoadDefs`** 或 **`step_destroy`** 会 **`NULLIFY`**。与 **`body_force_lumped_to_fext`** 的配合见 [`../../../L5_RT/Assembly/CONTRACT.md`](../../../L5_RT/Assembly/CONTRACT.md)。

### PROC → Solver Routing 映射 (v2.0)

`MD_Step_Proc` 现提供两条并行的 PROC 映射路径：

| 映射 | 目标 | 用途 |
|------|------|------|
| `ProcToRTStepType` | 11 种 `RT_STEP_TYPE_*` (L1_IF) | L5_RT 步分发（向后兼容） |
| `ProcToSolverType` | 8 种 `RT_SOLVER_*` (L1_IF) | 正交矩阵求解器轴、`MD_AnalysisCompat` |

两者从同一 `PROC_*` 出发，前者粗粒度（向后兼容），后者对齐 8-engine 正交设计。

### 已删除 / 非本目录（历史名）

- ~~`MD_Step_Core.f90`~~、~~`MD_Step_Types.f90`~~ 等：不在 `Analysis/Step/` 现树；勿与上表混用。
- ~~`MD_Step_API.f90`~~、~~`MD_Step_Opt.f90`~~、~~`MD_Modal_Desc.f90`~~、~~`MD_Step_MPh.f90`~~ — 已精简删除

---

### 与跨层灵敏度契约的衔接

本域承载 **步 / 过程输入侧 Desc**，**不** 承载运行时 **全局残差 R**、**L5_RT 步进 Arg 内工作区指针**。灵敏度与优化下 **R、θ 在四型中的落位** 见 [`../../contracts/CONTRACT_R_Theta_FourKind.md`](../../contracts/CONTRACT_R_Theta_FourKind.md)。


---

### L1_IF 基础设施集成 (v3.0)

| 设施 | 集成方式 | 说明 |
|------|---------|------|
| **SymTbl** | `MD_Step_Domain_AddStep` 注册 `STEP:{name}` | 建模期 O(1) 命名查找 |
| **SymTbl** | `MD_Step_Domain_GetStepByName` 优先 SymTbl 查找 | 命中返回; 未命中回退线性扫描 |
| **错误链** | Bridge 出口 `UFC_Err_Wrap` | 见 L1_IF_INTEGRATION.md |

---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `MD_Step_Mgr.f90` | `MD_Step_Mgr` | `StepAlgo`, `MD_Step_Desc`, `MD_Step_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `AddStep` (TBP,PRV,—); `AdvanceStep` (TBP,PRV,—); `GetCurrentStep` (TBP,PRV,—); `GetStep` (TBP,PRV,—); `GetStepByName` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `WriteBack` (TBP,PRV,—); `AddLoadId` (TBP,PRV,—); `AddBCId` (TBP,PRV,—); `AddPairId` (TBP,PRV,—); `AddOutputId` (TBP,PRV,—); `SetSolverConfigId` (TBP,PRV,—); `MD_Step_Domain_AddStep` (SUB,PRV,Mutate); `MD_Step_Domain_AdvanceStep` (SUB,PRV,—); `MD_Step_Domain_Finalize` (SUB,PRV,Finalize); `MD_Step_Domain_GetCurrentStep` (SUB,PRV,Query); `MD_Step_Domain_GetStep` (SUB,PRV,Query); `MD_Step_GetStep_Idx` (SUB,PUB,Query); `MD_Step_WriteBack_Idx` (SUB,PUB,IO); `MD_Step_Domain_Init` (SUB,PRV,Init); `MD_Step_DP_RegisterStructType` (SUB,PRV,—); `MD_Step_WriteBack` (SUB,PRV,IO); `MD_Step_Domain_GetStepByName` (SUB,PRV,Query); `MD_Step_GetStepByName_Idx` (SUB,PUB,Query); `MD_Step_Domain_GetSummary` (SUB,PRV,Query); `MD_Step_GetSummary_Impl` (SUB,PRV,Query); `MD_Step_Domain_AddLoadId` (SUB,PRV,Mutate); `MD_Step_Domain_AddBCId` (SUB,PRV,Mutate); `MD_Step_Domain_AddPairId` (SUB,PRV,Mutate); `MD_Step_Domain_AddOutputId` (SUB,PRV,Mutate); `MD_Step_Domain_SetSolverConfigId` (SUB,PRV,Mutate) |
| `MD_Step_Def.f90` | `MD_Step_Def` | `MD_Step_State`, `MD_Step_Ctx` | — |
| `MD_Step_Proc.f90` | `MD_Step_Proc` | `UF_IncrementControl`, `UF_SolutionControl`, `UF_RiksControl`, `UF_ModalControl`, `UF_ModalStepDef`, `UF_SSDControl`, `UF_BuckleControl`, `UF_HeatTransControl`, `UF_ThermalBCManager`, `UF_CTDispControl`, `UF_CTElecControl`, `UF_ElecBCManager`, `UF_GeostaticControl`, `UF_SoilsControl`, `UF_PoreBCManager`, `UF_ViscoControl`, `UF_AnnealControl`, `UF_StaticPerturbControl`, `UF_DynamicSubspaceControl`, `UF_ModalDynamicControl`, `UF_RandomResponseControl`, `UF_ResponseSpectrumControl`, `UF_ComplexFreqControl`, `UF_MassDiffControl`, `UF_CoupledTESControl`, `UF_PiezoControl`, `UF_ElectromagneticControl`, `UF_AcousticControl`, `UF_SteadyStateTransportControl`, `UF_SubstructureControl`, `UF_DynamicParams`, `StepStateData`, `StepDesc`, `StepCtx`, `MD_TimeIncrementControl`, `MD_TimeIncrementResult`, `MD_ConvergenceCriteria`, `MD_ConvergenceResult`, `MD_NonlinSolv`, `MD_SolverState`, `MD_RestartData`, `MD_OutCfg`, `MD_OutReq`, `IncState`, `IncCtx`, `MD_Model_StepConfig`, `UF_StepDef` | `init` (TBP,PRV,—); `set_procedure` (TBP,PRV,—); `set_time` (TBP,PRV,—); `set_nlgeom` (TBP,PRV,—); `set_increment` (TBP,PRV,—); `get_time_fraction` (TBP,PRV,—); `advance_increment` (TBP,PRV,—); `print_info` (TBP,PRV,—); `destroy` (TBP,PRV,—); `AddPairId` (TBP,PRV,—); `step_init` (SUB,PRV,Init); `step_set_procedure` (SUB,PRV,Mutate); `step_set_time` (SUB,PRV,Mutate); `step_set_nlgeom` (SUB,PRV,Mutate); `step_set_increment` (SUB,PRV,Mutate); `step_get_time_fraction` (FN,PRV,Query); `step_advance_increment` (SUB,PRV,—); `step_print_info` (SUB,PRV,IO); `step_destroy` (SUB,PRV,Finalize); `step_add_pair_id` (SUB,PRV,Mutate); `stepmgr_init` (SUB,PRV,Init); `stepmgr_add_step` (SUB,PRV,Mutate); `stepmgr_get_step` (FN,PRV,Query); `stepmgr_get_current` (FN,PRV,Query); `stepmgr_advance_step` (FN,PRV,—); `stepmgr_print_summary` (SUB,PRV,IO); `stepmgr_destroy` (SUB,PRV,Finalize); `MD_Conv_Check` (SUB,PRV,Validate); `ProcToRTStepType` (SUB,PUB,—); `ProcToSolverType` (SUB,PUB,—); `MD_TimeIncrement_Calc` (SUB,PRV,—) |
| `MD_Step_Sync.f90` | `MD_Step_Sync` | — | `MD_Step_SyncFromLegacy` (SUB,PUB,Populate); `UF_Step_BuildLegacyLoadDefs_FromLdbc` (SUB,PUB,Populate) |

---

### Partial Pillar v2.0 Update (H4a Step)

> 更新日期: 2026-04-26

**半柱分类**: H4a Step 是 L3+L5 半贯通柱，L4 无独立 Step 目录。

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| L3 | `MD_Step_Mgr.f90` | **AUTHORITY** — 步定义 Desc, StepAlgo, MD_Step_Domain | ACTIVE |
| L3 | `MD_Step_Def.f90` | 补充 State/Ctx 类型 | Phase B |
| L3 | `MD_Step_Proc.f90` | PROC_* 过程枚举, ProcToSolverType 映射 | ACTIVE |
| L4 | (不存在) | 步非物理计算概念 | — |
| L5 | `RT_StepDriver_Def.f90` | **AUTHORITY** — 三级状态机四型 (本层) | FOUR-TYPE |
| L5 | `RT_Step_Exec.f90` | **GOLDEN-LINE** — 生产步驱动 | ACTIVE |
| L5 | `RT_StepDriver_Core.f90` | DEMO/FACADE — 教学/测试 | DEMO |

**L4 缺席说明**: Step 是分析编排概念（何时计算），而非物理计算概念（怎么计算）。

**L5 融入点**: StepDriver 编排调用: Assembly, Solver, Output, WriteBack。

**跨层数据流**: `MD_Step_Desc`(L3) → `RT_StepDriver_Brg` → `RT_StepDriver_Desc`(L5) → `RT_StepExec` 驱动

**架构文档**: `UFC_DOMAIN_PILLAR_ARCHITECTURE.md`
