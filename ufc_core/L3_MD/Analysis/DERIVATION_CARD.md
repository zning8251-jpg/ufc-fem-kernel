# Analysis 域推演卡 (Derivation Card)

**层级**: L3_MD | **域**: Analysis | **版本**: v1.0 | **日期**: 2026-04-26

---

## 〇、总览 — Analysis 域 f90 功能模块全图

### 现有文件清单 (18 个 .f90)

| # | 子域 | 文件 | MODULE | 角色后缀 | 状态 |
|---|------|------|--------|----------|------|
| 1 | 域级 | ~~`MD_Analysis_Def.f90`~~ | — | — | **DELETED** — 平坦原型，已由子域替代 |
| 2 | 域级 | ~~`MD_Analysis_Core.f90`~~ | — | — | **DELETED** — 与子域 Step/Amp 重复 |
| 3 | 域级 | `MD_Ana_Brg.f90` | `MD_Ana_Brg` | `_Brg` | ACTIVE — 域级聚合桥接 |
| 4 | 域级 | `MD_Ana_Comp.f90` | `MD_Ana_Comp` | `_Comp` | ACTIVE — 3D 兼容矩阵 (Def+Core+Brg 三合一) |
| 5 | Step | `MD_Step_Def.f90` | `MD_Step_Def` | `_Def` | ACTIVE — State/Ctx 类型 |
| 6 | Step | `MD_Step_Mgr.f90` | `MD_Step_Mgr` | `_Mgr` | ACTIVE — 域容器 + TBP + SIO |
| 7 | Step | `MD_Step_Proc.f90` | `MD_Step_Proc` | `_Proc` | ACTIVE — PROC_* + UF_* |
| 8 | Step | `MD_Step_Sync.f90` | `MD_Step_Sync` | `_Sync` | ACTIVE — Legacy→Domain |
| 9 | Amplitude | `MD_Amp_Def.f90` | `MD_Amp_Def` | `_Def` | ACTIVE — 四型 + SIO + 标量核 |
| 10 | Amplitude | `MD_Amp_Mgr.f90` | `MD_Amp_Mgr` | `_Mgr` | ACTIVE — 域容器 + GetFactor + Sync |
| 11 | Amplitude | `MD_Amp_UF.f90` | `MD_Amp_UF` | `_UF` | ACTIVE — UF 遗留 + UAMP |
| 12 | Amplitude | `MD_Amp_Idx.f90` | `MD_Amp_Idx` | `_Idx` | ACTIVE — g_ufc_global 索引 |
| 13 | Solver | `MD_Solv_Def.f90` | `MD_Solv_Def` | `_Def` | ACTIVE — 四型 |
| 14 | Solver | `MD_Solv_Mgr.f90` | `MD_Solv_Mgr` | `_Mgr` | ACTIVE — 域容器 + SIO + Bridge |
| 15 | Solver | `MD_Solv_Sync.f90` | `MD_Solv_Sync` | `_Sync` | ACTIVE — Step→Solver 同步 |
| 16 | Coupling | `MD_Cpl_Def.f90` | `MD_Cpl_Def` | `_Def` | Phase A — 四型完整 |
| 17 | Coupling | `MD_Cpl_Core.f90` | `MD_Cpl_Core` | `_Core` | Phase A — **缺口待修** |

### 命名漂移记录

| CONTRACT 写法 | 实际文件 | 实际 MODULE | 说明 |
|---------------|----------|-------------|------|
| `MD_Step.f90` / `MODULE MD_Step`（旧稿） | `MD_Step_Mgr.f90` | `MD_Step_Mgr` | **`Analysis/CONTRACT.md` §二、`Step/CONTRACT.md` 细粒度表已于 2026-05-12 同步** |
| `MD_Solv.f90` / `MODULE MD_Solv`（旧稿） | `MD_Solv_Mgr.f90` | `MD_Solv_Mgr` | **`Analysis/CONTRACT.md` §二、§十六已于 2026-05-12 同步** |
| `MD_Amp_Mgr.f90` / `MODULE MD_Amp_Mgr` | `MD_Amp_Mgr.f90` | `MD_Amp_Mgr` | 同上 |
| `MD_Amp_Def.f90` | `MD_Amp_Def.f90` | `MD_Amp_Def` | 缩写化合规 |
| `MD_Amp_UF.f90` | `MD_Amp_UF.f90` | `MD_Amp_UF` | 缩写化合规 |
| `MD_Amp_Idx.f90` | `MD_Amp_Idx.f90` | `MD_Amp_Idx` | 缩写化合规 |

**结论**: 实际代码 MODULE==文件名 100% 合规；**Step / Solv** 主合同条目已与 **`MD_Step_Mgr` / `MD_Solv_Mgr`** 对齐（2026-05-12）；其它文档若仍见旧名请按本卡更新。

---

## 一、推演路径 A→E

### A: CONTRACT → 意图提取

| 子域 | 核心意图 | 热路径 | 下游消费者 |
|------|----------|--------|------------|
| **Step** | 分析步定义、过程类型映射、步级控制参数 SSOT | 否 | L5 StepDriver, L3 Boundary |
| **Amplitude** | 幅值曲线定义与有界标量求值 A(t) | 否 | L4 PH LoadBC, L5 RT AmpFactor |
| **Solver** | 求解器输入侧配置 Desc SSOT | 否 | L5 RT Solver, L2 NM Solver |
| **Coupling** | 多物理场耦合对定义 SSOT | 否 | L5 RT MFCoordinator |
| **AnalysisCompat** | 3D 正交兼容性矩阵 (8×4×12) + 物理组 G1-G9 | 否 | 步验证、Mat/Elem 兼容性检查 |

### B: 四型裁剪决策

| 子域 | Desc | State | Algo | Ctx | 裁剪理由 |
|------|------|-------|------|-----|----------|
| **Step** | ✅ `MD_Step_Desc` | ✅ `MD_Step_State` | ✅ `StepAlgo` | ✅ `MD_Step_Ctx` | 步有完整生命周期 |
| **Amplitude** | ✅ `MD_Amp_Desc` | ✅ `MD_Amp_State` | ✅ `MD_Amp_Algo` | ✅ `MD_Amp_Eval_Ctx` | 有求值算法与 UAMP 上下文 |
| **Solver** | ✅ `MD_Solver_Desc` | ⬜ 占位 | ✅ `MD_Solver_Algo` | ⬜ 占位 | 纯配置存转；运行时在 L5/L2 |
| **Coupling** | ✅ `MD_Cpl_Desc` | ✅ `MD_Cpl_State` | ✅ `MD_Cpl_Algo` | ✅ `MD_Cpl_Ctx` | 有配对生命周期 |
| **AnalysisCompat** | N/A | N/A | N/A | N/A | 无状态查询工具 |

### C: 算法锚定 — 每子域核心算法

| 子域 | 算法 | 对应 SUBROUTINE |
|------|------|-----------------|
| Step | 步容器 CRUD | `MD_Step_Domain_{Init,AddStep,GetStep,...}` |
| Step | PROC→RT_STEP_TYPE 映射 | `ProcToRTStepType` |
| Step | PROC→RT_SOLVER 映射 | `ProcToSolverType` |
| Step | Legacy→Domain 同步 | `MD_Step_SyncFromLegacy` |
| Amplitude | 分段线性插值 (TABULAR) | `MD_AmpShared_TabularEval` |
| Amplitude | 平滑阶跃 (SMOOTH) | `MD_AmpShared_SmoothStep` |
| Amplitude | 斜坡 (RAMP) | `MD_AmpShared_RampUnit` |
| Amplitude | 调制 (MODULATED) | `MD_AmpShared_Modulated` |
| Amplitude | 域→UF 回退求值 | `Amp_GetFactor` |
| Amplitude | UAMP 结构化回调 | `Amp_User_IF_Structured` |
| Solver | 配置 CRUD + 事务 Sync | `MD_Solver_Domain%{AddConfig,GetConfig,...}` |
| Solver | Step sol_ctrl→Desc | `MD_Solver_SyncFromStep` |
| Solver | Desc↔Algo 互转 | `MD_Solver_Desc_From_Algo` / `_Algo_From_Desc` |
| Coupling | 耦合对 CRUD | `MD_Cpl_Init_Proc` / `MD_Cpl_AddPair_Proc` / `MD_Cpl_Validate_Proc` / `MD_Cpl_GetConfig_Proc`（+ `Finalize` / `GetPair` / `GetSummary` 同模块） |
| AnaComp | 3D 矩阵填充 | `MD_Ana_Comp_Init` |
| AnaComp | 三元组检查 | `MD_Ana_Comp_CheckTriple` |
| AnaComp | PROC→分析组 | `MD_Ana_Comp_ProcToGroup` |
| AnaComp | 端到端验证 | `MD_Ana_Comp_FullCheck` |

### D: 过程绑定 — 按子域完整清单

#### D1. Step 子域 (4 文件, ~30 过程)

| 过程 | 类型 | 时相 | Verb | 文件 |
|------|------|------|------|------|
| `MD_Step_Domain_Init` | SUB | Setup | Init | `MD_Step_Mgr` |
| `MD_Step_Domain_Finalize` | SUB | Teardown | Finalize | `MD_Step_Mgr` |
| `MD_Step_Domain_AddStep` | SUB | Setup | Mutate | `MD_Step_Mgr` |
| `MD_Step_Domain_AdvanceStep` | SUB | Step | Evolve | `MD_Step_Mgr` |
| `MD_Step_Domain_GetCurrentStep` | SUB | Query | Get | `MD_Step_Mgr` |
| `MD_Step_Domain_GetStep` | SUB | Query | Get | `MD_Step_Mgr` |
| `MD_Step_Domain_GetStepByName` | SUB | Query | Get | `MD_Step_Mgr` |
| `MD_Step_Domain_GetSummary` | SUB | Query | Get | `MD_Step_Mgr` |
| `MD_Step_Domain_AddLoadId` | SUB | Setup | Mutate | `MD_Step_Mgr` |
| `MD_Step_Domain_AddBCId` | SUB | Setup | Mutate | `MD_Step_Mgr` |
| `MD_Step_Domain_AddPairId` | SUB | Setup | Mutate | `MD_Step_Mgr` |
| `MD_Step_Domain_AddOutputId` | SUB | Setup | Mutate | `MD_Step_Mgr` |
| `MD_Step_Domain_SetSolverConfigId` | SUB | Setup | Mutate | `MD_Step_Mgr` |
| `MD_Step_WriteBack` | SUB | Step | WriteBack | `MD_Step_Mgr` |
| `MD_Step_GetStep_Idx` | SUB | Query | Get | `MD_Step_Mgr` |
| `MD_Step_GetStepByName_Idx` | SUB | Query | Get | `MD_Step_Mgr` |
| `MD_Step_WriteBack_Idx` | SUB | Step | WriteBack | `MD_Step_Mgr` |
| `MD_Step_DP_RegisterStructType` | SUB | Setup | Init | `MD_Step_Mgr` |
| `ProcToRTStepType` | SUB | Query | Map | `MD_Step_Proc` |
| `ProcToSolverType` | SUB | Query | Map | `MD_Step_Proc` |
| `MD_Step_SyncFromLegacy` | SUB | Populate | Sync | `MD_Step_Sync` |

#### D2. Amplitude 子域 (4 文件, ~40 过程)

| 过程 | 类型 | 时相 | Verb | 文件 |
|------|------|------|------|------|
| `MD_Amp_Domain%Init` | TBP | Setup | Init | `MD_Amp_Def` |
| `MD_Amp_Domain%Finalize` | TBP | Teardown | Finalize | `MD_Amp_Def` |
| `MD_Amp_Domain%AddAmplitude` | TBP | Setup | Mutate | `MD_Amp_Def` |
| `MD_Amp_Domain%GetAmplitude` | TBP | Query | Get | `MD_Amp_Def` |
| `MD_Amp_Domain%EvalAtTime` | TBP | Compute | Evaluate | `MD_Amp_Def` |
| `MD_Amp_Domain%WriteBack` | TBP | Step | WriteBack | `MD_Amp_Def` |
| `MD_Amp_Domain%GetSummary` | TBP | Query | Get | `MD_Amp_Def` |
| `MD_AmpShared_TabularEval` | FN | Compute | Evaluate | `MD_Amp_Def` |
| `MD_AmpShared_SmoothStep` | FN | Compute | Evaluate | `MD_Amp_Def` |
| `MD_AmpShared_RampUnit` | FN | Compute | Evaluate | `MD_Amp_Def` |
| `MD_AmpShared_Modulated` | FN | Compute | Evaluate | `MD_Amp_Def` |
| `MD_Amp_Apply_Add_Arg` | SUB | SIO | Apply | `MD_Amp_Def` |
| `MD_Amp_Apply_Get_Arg` | SUB | SIO | Apply | `MD_Amp_Def` |
| `MD_Amp_Apply_EvalAtTime_Arg` | SUB | SIO | Apply | `MD_Amp_Def` |
| `MD_Amp_Apply_GetSummary_Arg` | SUB | SIO | Apply | `MD_Amp_Def` |
| `MD_Amp_DP_RegisterStructType` | SUB | Setup | Init | `MD_Amp_Def` |
| `Amp_GetFactor` | FN | Compute | Query | `MD_Amp_Mgr` |
| `MD_Amp_GetFactor` | FN | Compute | Query | `MD_Amp_Mgr` |
| `MD_Amp_Slot_To_MD_Desc` | SUB | Populate | Map | `MD_Amp_Mgr` |
| `MD_Amp_SyncFromLegacy` | SUB | Populate | Sync | `MD_Amp_Mgr` |
| `MD_Amp_ResolveName` | FN | Query | Find | `MD_Amp_Mgr` |
| `MD_Amp_Apply_AddAmplitude_MDL` | SUB | SIO | Apply | `MD_Amp_Mgr` |
| `MD_Amp_GetAmplitude_Idx` | SUB | Query | Get | `MD_Amp_Idx` |
| `MD_Amp_EvalAtTime_Idx` | SUB | Compute | Evaluate | `MD_Amp_Idx` |
| `MD_Amp_FromExt` | SUB | Populate | Map | `MD_Amp_UF` |
| `MD_Amp_FromExt_Def` | SUB | Populate | Map | `MD_Amp_UF` |
| `MD_Amp_FromExt_DB` | SUB | Populate | Map | `MD_Amp_UF` |
| *(UF TBP: init, evaluate, set_*, add_point, clear, ...)* | TBP | Various | Various | `MD_Amp_UF` |

#### D3. Solver 子域 (3 文件, ~20 过程)

| 过程 | 类型 | 时相 | Verb | 文件 |
|------|------|------|------|------|
| `MD_Solver_Desc_Init` | SUB | Setup | Init | `MD_Solv_Def` |
| `MD_Solver_Desc_SetTolerances` | SUB | Setup | Mutate | `MD_Solv_Def` |
| `MD_Solver_Desc_Finalize` | SUB | Teardown | Finalize | `MD_Solv_Def` |
| `MD_Solver_Desc_From_Algo` | SUB | Query | Map | `MD_Solv_Def` |
| `MD_Solver_Algo_From_Desc` | SUB | Query | Map | `MD_Solv_Def` |
| `MD_Solver_Domain%Init` | TBP | Setup | Init | `MD_Solv_Mgr` |
| `MD_Solver_Domain%Finalize` | TBP | Teardown | Finalize | `MD_Solv_Mgr` |
| `MD_Solver_Domain%AddConfig` | TBP | Setup | Mutate | `MD_Solv_Mgr` |
| `MD_Solver_Domain%GetConfig` | TBP | Query | Get | `MD_Solv_Mgr` |
| `MD_Solver_Domain%GetSummary` | TBP | Query | Get | `MD_Solv_Mgr` |
| `MD_Solver_Apply_AddConfig_Arg` | SUB | SIO | Apply | `MD_Solv_Mgr` |
| `MD_Solver_Apply_GetConfig_Arg` | SUB | SIO | Apply | `MD_Solv_Mgr` |
| `MD_Solver_Apply_GetSummary_Arg` | SUB | SIO | Apply | `MD_Solv_Mgr` |
| `MD_Solver_GetConfig_Idx` | SUB | Query | Get | `MD_Solv_Mgr` |
| `MD_Solver_Brg_GetConfigForStep` | SUB | Bridge | Get | `MD_Solv_Mgr` |
| `MD_Solver_Brg_GetConfigForStep_Select` | SUB | Bridge | Get | `MD_Solv_Mgr` |
| `MD_Solver_SyncFromStep` | SUB | Populate | Sync | `MD_Solv_Sync` |

#### D4. Coupling 子域 (2 文件, 7 过程)

| 过程 | 类型 | 时相 | Verb | 文件 | 状态 |
|------|------|------|------|------|------|
| `MD_Cpl_Init_Proc` | SUB | Setup | Init | `MD_Cpl_Core` | ✅ `ErrorStatusType` |
| `MD_Cpl_Finalize_Proc` | SUB | Teardown | Finalize | `MD_Cpl_Core` | ✅ |
| `MD_Cpl_AddPair_Proc` | SUB | Setup | Mutate | `MD_Cpl_Core` | ✅ |
| `MD_Cpl_Validate_Proc` | SUB | Setup | Validate | `MD_Cpl_Core` | ✅ |
| `MD_Cpl_GetConfig_Proc` | SUB | Query | Get | `MD_Cpl_Core` | ✅ |
| `MD_Cpl_GetPair_Proc` | SUB | Query | Get | `MD_Cpl_Core` | ✅ 按下标查询单对 |
| `MD_Cpl_GetSummary_Proc` | SUB | Query | Get | `MD_Cpl_Core` | ✅ 诊断汇总 |

#### D5. AnaComp (1 文件, 10 过程) — 完整

| 过程 | 类型 | 时相 | Verb | 文件 |
|------|------|------|------|------|
| `MD_Ana_Comp_Init` | SUB | Setup | Init | `MD_Ana_Comp` |
| `MD_Ana_Comp_CheckTriple` | SUB | Query | Validate | `MD_Ana_Comp` |
| `MD_Ana_Comp_CheckGroupMat` | FN | Query | Validate | `MD_Ana_Comp` |
| `MD_Ana_Comp_CheckGroupElem` | FN | Query | Validate | `MD_Ana_Comp` |
| `MD_Ana_Comp_ProcToGroup` | SUB | Query | Map | `MD_Ana_Comp` |
| `MD_Ana_Comp_PhysToGroup` | FN | Query | Map | `MD_Ana_Comp` |
| `MD_Ana_Comp_ValidateStep` | SUB | Bridge | Validate | `MD_Ana_Comp` |
| `MD_Ana_Comp_ValidateGroupMat` | SUB | Bridge | Validate | `MD_Ana_Comp` |
| `MD_Ana_Comp_ValidateGroupElem` | SUB | Bridge | Validate | `MD_Ana_Comp` |
| `MD_Ana_Comp_FullCheck` | SUB | Bridge | Validate | `MD_Ana_Comp` |

#### D6. 域级文件 — 已清理

| 文件 | MODULE | 处置 |
|------|--------|------|
| ~~`MD_Analysis_Def.f90`~~ | ~~`MD_Analysis_Def`~~ | **DELETED** — 平坦原型已被子域替代 |
| ~~`MD_Analysis_Core.f90`~~ | ~~`MD_Analysis_Core`~~ | **DELETED** — 8 过程全部与子域重复 |
| `MD_Ana_Brg.f90` | `MD_Ana_Brg` | **ACTIVE** — 域级聚合桥接门面 |

### E: f90 模块全图 — 应有 vs 现有

| # | 应有模块 | 现有状态 | 行动 |
|---|----------|----------|------|
| 1 | `MD_Step_Def` | ✅ ACTIVE | 无需改动 |
| 2 | `MD_Step_Mgr` | ✅ ACTIVE | CONTRACT 命名同步 |
| 3 | `MD_Step_Proc` | ✅ ACTIVE | 无需改动 |
| 4 | `MD_Step_Sync` | ✅ ACTIVE | 无需改动 |
| 5 | `MD_Amp_Def` | ✅ ACTIVE | 无需改动 |
| 6 | `MD_Amp_Mgr` | ✅ ACTIVE | CONTRACT 命名同步 |
| 7 | `MD_Amp_UF` | ✅ ACTIVE | 无需改动 |
| 8 | `MD_Amp_Idx` | ✅ ACTIVE | 无需改动 |
| 9 | `MD_Solv_Def` | ✅ ACTIVE | 无需改动 |
| 10 | `MD_Solv_Mgr` | ✅ ACTIVE | CONTRACT 命名同步 |
| 11 | `MD_Solv_Sync` | ✅ ACTIVE | 无需改动 |
| 12 | `MD_Cpl_Def` | ✅ Phase A | 无需改动 |
| 13 | `MD_Cpl_Core` | ✅ Phase A | 与 CONTRACT 对齐：`MD_Cpl_*_Proc` + `ErrorStatusType` |
| 14 | `MD_Ana_Comp` | ✅ ACTIVE | 三合一 (Def+Core+Brg → 单文件 `_Comp` 后缀) |
| 17 | `MD_Ana_Brg` | ✅ ACTIVE | 重命名自 `MD_Analysis_Brg`，域级聚合门面 |
| 18 | ~~`MD_Analysis_Def`~~ | ❌ DELETED | 已删除 |
| 19 | ~~`MD_Analysis_Core`~~ | ❌ DELETED | 已删除 |

---

## 二、Core 蓝图闭合校验

> `MD_Analysis_Def.f90` + `MD_Analysis_Core.f90` 已删除（平坦原型，零外部消费），但 `MD_Analysis_Core` 定义的 **8 个过程**是域应具备的核心算法蓝图。
> 该模块为域级聚合器（操作 `MD_Analysis_Desc`：内含 `MD_StepEntry(N)` + `MD_AmplitudeEntry(N)` 固定数组）。
> 以下逐条校验：每条蓝图过程必须在生产子域代码中有对应实现，否则标记 **GAP**。
>
> **注**: 原文件未入 git，蓝图基于 transcript 记录重建（"Legacy CRUD on MD_Analysis_Desc, 8 procedures"）。

### 蓝图来源：已删除的 `MD_Analysis_Core.f90` (MODULE MD_Analysis_Core)

| # | 蓝图过程 (域级聚合) | 签名语义 | 生产落地 (子域) | 状态 |
|---|---------------------|----------|----------------|------|
| C1 | `MD_Analysis_Init(desc, status)` | 初始化域级容器 | `MD_Step_Domain_Init` (`MD_Step_Mgr`) + `MD_Amp_Domain%Init` (`MD_Amp_Def`) + `MD_Solver_Domain%Init` (`MD_Solv_Mgr`) + `MD_Cpl_Init_Proc` (`MD_Cpl_Core`) | ✅ 覆盖 (分解为 4 子域 Init) |
| C2 | `MD_Analysis_Finalize(desc, status)` | 释放域级容器 | `MD_Step_Domain_Finalize` + `MD_Amp_Domain%Finalize` + `MD_Solver_Domain%Finalize` + `MD_Cpl_Finalize_Proc` | ✅ 覆盖 (分解为 4 子域 Finalize) |
| C3 | `MD_Analysis_AddStep(desc, step_entry, status)` | 添加步定义 | `MD_Step_Domain_AddStep` (`MD_Step_Mgr`) | ✅ 覆盖 (更丰富: 含 PROC 映射 + 子步绑定) |
| C4 | `MD_Analysis_GetStep(desc, idx, step_entry, status)` | 按索引查询步 | `MD_Step_Domain_GetStep` + `MD_Step_GetStep_Idx` (`MD_Step_Mgr`) | ✅ 覆盖 (更丰富: 含 ByName/ByIndex/Current) |
| C5 | `MD_Analysis_AddAmplitude(desc, amp_entry, status)` | 添加幅值曲线 | `MD_Amp_Domain%AddAmplitude` (`MD_Amp_Def`) | ✅ 覆盖 (更丰富: 含 SIO Arg) |
| C6 | `MD_Analysis_GetAmplitude(desc, idx, amp_entry, status)` | 按索引查询幅值 | `MD_Amp_Domain%GetAmplitude` + `MD_Amp_GetAmplitude_Idx` (`MD_Amp_Idx`) | ✅ 覆盖 |
| C7 | `MD_Analysis_GetStepCount(desc) → n` | 步计数 | `MD_Step_Domain%n_steps` 字段 + `MD_Step_Domain_GetSummary` | ✅ 覆盖 (字段级) |
| C8 | `MD_Analysis_Validate(desc, status)` | 全域一致性验证 | `MD_Ana_Comp_FullCheck` (`MD_Ana_Comp`) + `MD_Ana_Comp_ValidateStep` + `MD_Cpl_Validate_Proc` (`MD_Cpl_Core`) | ✅ 覆盖 (分解为兼容性+耦合验证) |

### 蓝图类型映射

| 蓝图原型类型 | 用途 | 生产对应 |
|--------------|------|----------|
| `MD_StepEntry` (name/proc_type/time/nlgeom/...) | 平坦步条目 | `MD_Step_Desc` (`MD_Step_Def.f90`) — 完整四型 |
| `MD_AmplitudeEntry` (name/type/points/...) | 平坦幅值条目 | `MD_Amp_Desc` (`MD_Amp_Def.f90`) — 完整四型 + 求值核 |
| `MD_Analysis_Desc` (steps(N)/amplitudes(N)/固定数组) | 域级聚合容器 | 子域各自管理: `MD_Step_Domain` + `MD_Amp_Domain` + `MD_Solver_Domain` + `MD_Cpl_Desc`（经 `MD_Cpl_*_Proc` 编排）— 可分配 |

**结论**: 8 条蓝图过程在生产子域代码中 **全部覆盖**，且功能更丰富（SIO/TBP/可分配）。蓝图已安全归档于此推演卡。

---

## 三、逆向闭合验证 — 缺口清单

### GAP-01: Coupling 错误处理不规范 (RESOLVED)

**原状**: `MD_Cpl_Core` 曾使用 `INTEGER(i4) :: status`。
**现状**: 已统一为 `ErrorStatusType` + `init_error_status` + `IF_STATUS_OK/INVALID`。

### GAP-02: Coupling 缺失 Finalize / GetSummary / GetPair (RESOLVED)

**现状**: `MD_Cpl_Core` 已提供 **`MD_Cpl_Finalize_Proc`**、**`MD_Cpl_GetSummary_Proc`**、**`MD_Cpl_GetPair_Proc`**；公开过程命名为 **`MD_Cpl_*_Proc`**，与 **`MD_Cpl_*`** TYPE 同柱前缀。

### GAP-03: L5 Coupling CONTRACT.md 编码损坏 (RESOLVED)

**原状**: `UFC/ufc_core/L5_RT/Solver/Coupling/CONTRACT.md` 中文曾显示为 `?`（编码损坏）。  
**处置**: v2.1 已 **全文重写** 为可读 UTF-8，并与 L3 `MD_Cpl_*` / `RT_MF_*` 命名对齐。

### GAP-04: 域级 Def/Core (RESOLVED — DELETED)

**原状**: `MD_Analysis_Def` + `MD_Analysis_Core` 与子域完全重复。
**处置**: 已删除。零外部引用。

### GAP-05: 域级 Brg + AnaCompat 命名 (RESOLVED — REFACTORED)

**原状**: `MD_Analysis_Brg` 为空壳；`MD_Analysis_Compat` 混合 `_Def` 与 `_Core` 职责。
**处置**: 合并为单文件 `MD_Ana_Comp.f90`（三段式 `_Comp` 后缀，Def+Core+Brg 三合一）；`MD_Analysis_Brg` → `MD_Ana_Brg`（聚合门面）。

### GAP-06: CONTRACT 命名漂移

**现状（2026-05-12 起）**：`Analysis/CONTRACT.md` §二、§十六与 `Step/CONTRACT.md` 细粒度表已同步 **`MD_Step_Mgr.f90` / `MODULE MD_Step_Mgr`**、**`MD_Solv_Mgr.f90` / `MODULE MD_Solv_Mgr`**；幅值侧 **`MD_Amp_Mgr`** 本即一致。
**修复**: 历史缺口以合同修订闭合；不改代码文件名。

---

## 四、算法步规约 — 每过程五要素步

### Coupling 子域 — 过程算法步

#### MD_Cpl_Init_Proc

| Step | 算法步 | 对应逻辑 |
|------|--------|----------|
| S1 | 初始化 error status | `CALL init_error_status(status)` |
| S2 | 重置 n_pairs 和 strategy 等标量字段 | 赋默认值 |
| S3 | 清空 pairs 数组各条目 | 循环 1..MAX_PAIRS |
| S4 | 设置 is_configured = .FALSE. | 标记未配置 |
| S5 | 返回 IF_STATUS_OK | `status%status_code = IF_STATUS_OK` |

#### MD_Cpl_AddPair_Proc

| Step | 算法步 | 对应逻辑 |
|------|--------|----------|
| S1 | 初始化 error status | `CALL init_error_status(status)` |
| S2 | 检查 n_pairs < MAX_PAIRS | 越界返回 IF_STATUS_INVALID |
| S3 | 递增 n_pairs，复制 pair 到数组 | `desc%pairs(n) = pair` |
| S4 | 分配 pair_id = n_pairs | 自增编号 |
| S5 | 返回 IF_STATUS_OK | `status%status_code = IF_STATUS_OK` |

#### MD_Cpl_Validate_Proc

| Step | 算法步 | 对应逻辑 |
|------|--------|----------|
| S1 | 初始化 error status | `CALL init_error_status(status)` |
| S2 | 检查 n_pairs > 0 | 空则 is_configured=F, 返回 OK |
| S3 | 遍历每对: src/dst 必须 > 0 | 无效返回 IF_STATUS_INVALID |
| S4 | 遍历每对: src ≠ dst | 自耦返回 IF_STATUS_INVALID |
| S5 | 设置 is_configured = .TRUE.，返回 OK | |

#### MD_Cpl_GetConfig_Proc

| Step | 算法步 | 对应逻辑 |
|------|--------|----------|
| S1 | 初始化 error status | |
| S2 | 输出 n_pairs, strategy, is_configured | 只读赋值 |
| S3 | 返回 IF_STATUS_OK | |

#### MD_Cpl_Finalize_Proc

| Step | 算法步 | 对应逻辑 |
|------|--------|----------|
| S1 | 初始化 error status | |
| S2 | 重置 n_pairs = 0 | |
| S3 | 清空 pairs 数组 | 循环清零 |
| S4 | 重置 is_configured = .FALSE. | |
| S5 | 重置 State / Algo / Ctx 为默认值 | |
| S6 | 返回 IF_STATUS_OK | |

#### MD_Cpl_GetSummary_Proc

| Step | 算法步 | 对应逻辑 |
|------|--------|----------|
| S1 | 初始化 error status | |
| S2 | 汇总 n_pairs, strategy, is_configured | 只读提取 |
| S3 | 统计 n_active_pairs | 遍历 pairs 计数 is_active |
| S4 | 返回 IF_STATUS_OK | |

#### MD_Cpl_GetPair_Proc

| Step | 算法步 | 对应逻辑 |
|------|--------|----------|
| S1 | 初始化 error status | |
| S2 | 检查 pair_idx 范围 [1, n_pairs] | 越界返回 IF_STATUS_INVALID |
| S3 | 复制 pairs(pair_idx) 到输出 | |
| S4 | 返回 IF_STATUS_OK | |

---

## 五、修复实施计划

### 修复优先级

| 序号 | 修复项 | 文件 | 类型 | 优先级 |
|------|--------|------|------|--------|
| F1 | Coupling ErrorStatusType + 补全过程 | `MD_Cpl_Core.f90` | 代码修改 | P0 |
| F2 | Coupling CONTRACT.md 重写 | `Coupling/CONTRACT.md` | 文档修复 | P0 |
| F3 | MD_Analysis_Def/Core 已删除 | ~~2 文件~~ | ✅ DONE | — |
| F4 | MD_Analysis_Brg → MD_Ana_Brg + AnaCompat 拆分重构 | 5 文件 | ✅ DONE | — |
| F5 | Analysis/CONTRACT.md 命名同步 | 1 文件 | 文档修正 | P1 |
| F6 | Step/CONTRACT.md 命名同步 | 1 文件 | 文档修正 | P1 |
| F7 | Solver/CONTRACT.md 命名同步 | 1 文件 | 文档修正 | P1 |
| F8 | Amplitude/CONTRACT.md 命名同步 | 1 文件 | 文档修正 | P1 |
