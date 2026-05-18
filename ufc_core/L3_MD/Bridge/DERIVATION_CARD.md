# Bridge 域推演卡 (Derivation Card)

**层级**: L3_MD | **域**: Bridge (基础设施域) | **版本**: v1.0 | **日期**: 2026-04-26

---

## 〇、总览 — Bridge 域 f90 功能模块全图

### 域特性

Bridge 是**基础设施域** (Infrastructure Domain)，不是带有四型 (Desc/State/Algo/Ctx) 结构的柱域：
- 每个模块是**纯 pass-through 映射**：L3 Desc → L4/L5 结构化类型
- **无 State/Algo 持有**：Bridge 不持有运行时状态，不执行物理/数值算法
- **无 _Core.f90 原型轨道**：不存在蓝图-生产二轨制
- 两个子目录：`Bridge_L4/` (L3→L4, 6 个) + `Bridge_L5/` (L3→L5, 13 个)

### 现有文件清单 (19 个 .f90)

#### Bridge_L4 子目录 (L3→L4 桥接, 6 个)

| # | 文件 | MODULE | 行数 | 源域 | 目标 | 状态 |
|---|------|--------|------|------|------|------|
| 1 | `MD_MatLibPH_Brg.f90` | `MD_MatLibPH_Brg` | 412 | Material | L4 PH | **ACTIVE** (LEGACY 热路径) |
| 2 | `MD_ElemPH_Brg.f90` | `MD_ElemPH_Brg` | 274 | Element | L4 PH | **ACTIVE** |
| 3 | `MD_LBCPH_Brg.f90` | `MD_LBCPH_Brg` | 489 | LoadBC | L4 PH | **ACTIVE** |
| 4 | `MD_GeomPH_Brg.f90` | `MD_GeomPH_Brg` | 235 | Geometry | L4 PH | **ACTIVE** |
| 5 | `MD_ContPH_Brg.f90` | `MD_ContPH_Brg` | 131 | Contact | L4 PH | **ACTIVE** |
| 6 | `MD_ConstraintPH_Brg.f90` | `MD_ConstraintPH_Brg` | 270 | Constraint | L4 PH | **ACTIVE** |

#### Bridge_L5 子目录 (L3→L5 桥接, 13 个)

| # | 文件 | MODULE | 行数 | 源域 | 目标 | 状态 |
|---|------|--------|------|------|------|------|
| 7 | `MD_AssemRT_Brg.f90` | `MD_AssemRT_Brg` | ~180 | Assembly | L5 RT | **ACTIVE** |
| 8 | `MD_ContRT_Brg.f90` | `MD_ContRT_Brg` | ~100 | Contact | L5 RT | **ACTIVE** |
| 9 | `MD_ElemRT_Brg.f90` | `MD_ElemRT_Brg` | ~180 | Element | L5 RT | **ACTIVE** |
| 10 | `MD_Int_Brg.f90` | `MD_Int_Brg` | 1167 | Interaction | L5 RT | **ACTIVE** (最大桥模块) |
| 11 | `MD_Int_ContactArgs.f90` | `MD_Int_ContactArgs` | 76 | Interaction | L5 RT | **ACTIVE** (Arg 定义) |
| 12 | `MD_KWRT_Brg.f90` | `MD_KWRT_Brg` | ~268 | KeyWord | L5 RT | **ACTIVE** |
| 13 | `MD_LBCRT_Brg.f90` | `MD_LBCRT_Brg` | ~180 | LoadBC | L5 RT | **ACTIVE** |
| 14 | `MD_Mesh_Brg.f90` | `MD_Mesh_Brg` | ~460 | Mesh | L5 RT | **ACTIVE** (命名异常) |
| 15 | `MD_Model_Brg.f90` | `MD_Model_Brg` | ~870 | Model | L5 RT | **ACTIVE** |
| 16 | `MD_ModelRT_Brg.f90` | `MD_ModelRT_Brg` | ~220 | Model | L5 RT | **ACTIVE** |
| 17 | `MD_Out_Brg.f90` | `MD_Out_Brg` | ~300 | Output | L5 RT | **ACTIVE** |
| 18 | `MD_UIRT_Brg.f90` | `MD_UIRT_Brg` | ~150 | UI | L5 RT | **ACTIVE** |
| 19 | `MD_UniFldRT_Brg.f90` | `MD_UniFldRT_Brg` | ~120 | UniFld | L5 RT | **ACTIVE** |

### 命名评估

Bridge_L4 命名一致：`MD_{源域缩写}PH_Brg`（无下划线分隔）。
Bridge_L5 命名一致：`MD_{源域缩写}RT_Brg` 或 `MD_{源域}_Brg`。

**命名异常**:

| 文件 | MODULE 名 | 问题 | 处理 |
|------|-----------|------|------|
| `MD_Mesh_Brg.f90` | `MD_Mesh_Brg` | CONTRACT/INDEX 声称 MODULE 为 `RT_Mesh_Brg`，实际为 `MD_Mesh_Brg` | **文档漂移** — 修正 CONTRACT/INDEX |
| `MD_Mesh_Brg.f90` | `MD_Mesh_Brg` | 文件头注释 `Layer: L5_RT`，实际在 L3_MD | **头注释漂移** — 修正头注释 |
| `MD_Int_ContactArgs.f90` | `MD_Int_ContactArgs` | 纯 Arg 定义，无 `_Brg` 后缀 | 合理 — Arg 定义独立于 Bridge 过程 |

---

## 一、推演路径 A→E

### A: CONTRACT → 意图

| 项目 | 说明 |
|------|------|
| **域名** | Bridge (基础设施域) |
| **职责** | L3_MD Desc → L4_PH / L5_RT 结构化映射；**不执行**物理计算/算法 |
| **四型** | 不适用 — Bridge 不持有 Desc/State/Algo/Ctx |
| **金线** | KeyWord → L3 Desc 填充 → **Bridge 映射** → L4 Populate / L5 Init |
| **热路径** | 否（Populate/Step-Init 冷路径；`MD_MatLibPH_Brg` 热路径为 LEGACY） |

### B: 四型裁剪

**N/A** — Bridge 是基础设施域，不参与四型体系。各 Bridge 模块仅定义映射过程和少量 Arg/Ctx 输出类型。

### C: 算法锚定 — 按子目录

#### C1. Bridge_L4 (L3→L4 映射)

| 模块 | 核心映射算法 | 过程 |
|------|-------------|------|
| `MD_MatLibPH_Brg` | mat_type→Reg ID→UMAT dispatch | `MD_PH_GetMaterialType`, `MD_PH_RouteToConstitutive`, `_Idx`, `MD_PH_TransferModelDef` |
| `MD_ElemPH_Brg` | ElemType→L4 计算分发 | `MD_PH_Elem_CalcContinuum2D/3D`, `CalcPoro*`, `CalcThermal/THM/Thm`, `GetElemCtx_Idx` |
| `MD_LBCPH_Brg` | MD BC/Load→PH Cache + Amp 标度 | `BuildStepBCs/Loads`, `_FromDomain`, `_Idx`, `LoadBC/BC/Load_FromDesc` |
| `MD_GeomPH_Brg` | 几何+材料→PH ElemCtx | `MD_PH_Geom_FillElemCtx`, `_Idx` |
| `MD_ContPH_Brg` | 接触属性→PH Params | `MD_Cont_PH_FillParams_FromMD` (generic: _From_Type / _From_Union) |
| `MD_ConstraintPH_Brg` | MPC/Tie/Coupling→PH Params | `MD_Constraint_PH_FillParams_FromMD` / `MD_Constraint_PH_Fill_*` |

#### C2. Bridge_L5 (L3→L5 映射)

| 模块 | 核心映射算法 | 过程 |
|------|-------------|------|
| `MD_AssemRT_Brg` | Triplet/CSR 稀疏操作转发 | `TripletInit/Add/Free`, `CSRFromTriplet/Free/SpMV` |
| `MD_ContRT_Brg` | 接触→RT triplet/EqId | `TripletAdd`, `GetEqId` |
| `MD_ElemRT_Brg` | 单元计算→RT | `Comp`, `Comp_Idx` |
| `MD_Int_Brg` | 接触对/表面构建→RT | `BuildStepPairs`, `ConvertProperty`, `InitFromMD`, `IncrInit`, `IterationInit` |
| `MD_Int_ContactArgs` | Arg 类型定义 | (无过程，纯类型) |
| `MD_KWRT_Brg` | KW AST→RT Solver 属性 | `ParseComplexFrequency/Direct/ModalDamping/...` (8 个) |
| `MD_LBCRT_Brg` | 载荷/BC→RT EqId/Workspace | `GetBCWorkspace`, `GetEqId`, `GetEqIdByDofType`, `GetThreadWS` |
| `MD_Mesh_Brg` | 网格 ID 映射 Model↔RT | `BrgInit/Clean`, `MapNodeId/ElemId/MatId/SectId`, `GetNodeCoords/ElemConnect_Idx` |
| `MD_Model_Brg` | 模型→DP/Contact 构建 | `BindModelRuntime_ToDataPlatform`, `BuildContMesh/StepBC/StepLoad`, `BuildContact*` |
| `MD_ModelRT_Brg` | 模型→RT 步管理器 | `StepMgr_Init/AddStep/GetStepCfg/InitModelVars` |
| `MD_Out_Brg` | 输出请求→RT 任务 | `BuildFieldOutTasks/HistOutTasks`, `_FromDomain`, `_Select`, `ShouldOutput` |
| `MD_UIRT_Brg` | UI→RT Job 运行 | `MD_RT_UI_RunJob` |
| `MD_UniFldRT_Brg` | 统一场→RT IP 求值 | `EvalStructAtIp`, `IntegrateIp` |

### D: 过程绑定 — 完整过程清单

(见 CONTRACT.md §细粒度子程序清单，已与代码一致)

### E: 目标文件结构

**无删除/重命名/合并**。19 个文件均为 ACTIVE，无死代码文件。

---

## 二、逆向闭合验证 — 缺口清单

### GAP-01: 重复 QUENCH 标记

**现状**: 15+ 个文件各有 **2 个** `!>>> UFC_L3_QUENCH` 标记块（应为 1 个）。
**处置**: 移除重复。

### GAP-02: CONTRACT/INDEX MODULE 名漂移 (MD_Mesh_Brg)

**现状**: CONTRACT.md §二/§六 和 BRIDGE_INDEX.md §2/§6 声称 MODULE 为 `RT_Mesh_Brg`，但源码 `MD_Mesh_Brg.f90` 第 30 行实际 MODULE 名为 `MD_Mesh_Brg`。
**影响**: 文档误导开发者写出 `USE RT_Mesh_Brg` (编译失败)。
**处置**: 修正 CONTRACT.md 和 BRIDGE_INDEX.md，删除 §6 命名异常条目。

### GAP-03: 头注释层级错误 (MD_Mesh_Brg)

**现状**: `MD_Mesh_Brg.f90` 文件头注释写 `Layer: L5_RT`，实际文件在 `L3_MD/Bridge/Bridge_L5/`。
**处置**: 修正为 `Layer: L3_MD`。

### GAP-04: 编码损坏 (mojibake)

**现状**:
- `MD_LBCPH_Brg.f90` 第 65 行: `四大` 后乱码
- `MD_Model_Brg.f90` 第 15 行: `L3鈫扡1/L5` 乱码
- `MD_MatLibPH_Brg.f90` 第 51 行: `mapping only.` 前乱码 (`只`)
**处置**: 修正为正确 UTF-8 注释。

### GAP-05: 重复 Status 行 (MD_MatLibPH_Brg)

**现状**: `MD_MatLibPH_Brg.f90` 有 3 个 Status 行（行 11, 82, 84），互相矛盾。
**处置**: 合并为 1 个一致的 Status 行。

### GAP-06: CONTRACT Solver 引用漂移

**现状**: CONTRACT §六 引用 `MD_Solv` (MODULE)，但 Analysis/Solver 域重构后实际 MODULE 为 `MD_Solv_Mgr`。
**处置**: 修正 CONTRACT 引用。

---

## 三、修复实施计划

| 序号 | 修复项 | 类型 | 优先级 | 影响文件 |
|------|--------|------|--------|----------|
| F1 | 移除重复 QUENCH 标记 | 代码清理 | P0 | 15+ 个 .f90 |
| F2 | 修正 MODULE 名漂移 (MD_Mesh_Brg) | 文档 | P0 | CONTRACT.md, BRIDGE_INDEX.md |
| F3 | 修正头注释层级 (MD_Mesh_Brg) | 头注释 | P1 | MD_Mesh_Brg.f90 |
| F4 | 修正编码损坏 | 代码注释 | P1 | 3 个 .f90 |
| F5 | 合并重复 Status 行 | 头注释 | P2 | MD_MatLibPH_Brg.f90 |
| F6 | CONTRACT Solver 引用修正 | 文档 | P2 | CONTRACT.md |

---

## 四、版本历史

- v1.0 (2026-04-26) — 初始版本
