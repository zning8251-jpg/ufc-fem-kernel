# Bridge 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Bridge (层间桥接与数据映射)  
**Version**: v3.1  
**Updated**: 2026-04-30  
**Status**: ✅ 补全至标准格式

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

---

## 1. 域职责定义

### 核心职责（一句话）

UFC L3_MD 层 Bridge 域，层间数据桥接与映射的唯一宿主，定义 L3_MD→L4_PH 和 L3_MD→L5_RT 的官方 Bridge 模块，提供模型数据到物理计算层/运行时层的标准化只读映射。

### 职责边界

| 做什么 | 不做什么 |
|--------|----------|
| L3→L4 桥接：将 L3 模型 Desc 映射为 L4 可消费结构 | 物理计算（L4_PH 职责） |
| L3→L5 桥接：将 L3 模型 Desc 映射为 L5 运行时结构 | 求解流程编排（L5_RT 职责） |
| 索引登记：BRIDGE_INDEX.md 作为 Bridge 模块真值表 | 持有可变状态（Bridge 无状态） |
| 数据格式转换与索引映射 | 执行算法（Algo 类型不适用） |
| 向后兼容适配（Legacy bridge） | 创建新 Desc 数据（仅转发只读 Desc） |
| O(1)/O(n) 拷贝/映射操作 | 内嵌单元积分或 NR 迭代 |

### 设计意图

Bridge 域重新分类为**基础设施域 (Infrastructure Domain)**，与 L1_IF 的 SymTbl/DP/MemPool 同级，不承载物理/数值语义。

### 依赖关系

- **同层消费**: L3_MD 各域（Material/Element/LoadBC/Mesh/Interaction/Assembly/Analysis/Output/Field/Constraint）的 Desc 类型
- **下层依赖**: L1_IF/Prec_Core（精度）、L1_IF/Err_Brg（错误处理）

---

## 2. 四类 TYPE 清单

> **注**: Bridge 域以 **Desc/Ctx** 为主（概念级），**不**作为 Algo/State 真相源。Bridge 模块本身不定义实质四型 TYPE，而是映射/转发其他域的四型。

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名 | 定义文件 | 核心字段 | 用途 |
|----------|----------|----------|------|
| `MD_Bridge_Desc` | 概念级 | `bridge_id`, `source_layer`, `target_layer` | 桥接描述（Bridge 不持有实质 Desc TYPE） |
| `PH_Constraint_Params` | `MD_ConstraintPH_Brg.f90` | 约束参数 | L3 约束→L4 PH 参数映射载体 |
| `PH_Constraint_Params_Array` | `MD_ConstraintPH_Brg.f90` | 约束参数数组 | 批量约束映射 |
| `MD_PH_Elem_GetElemCtx_Arg` | `MD_ElemPH_Brg.f90` | 单元上下文查询参数 | Arg 束 |
| `MD_PH_Geom_FillElemCtx_Arg` | `MD_GeomPH_Brg.f90` | 几何填充参数 | Arg 束 |
| `MD_LoadBC_StepBCsOut_Type` | `MD_LBCPH_Brg.f90` | BC 输出缓存 | 步级 BC 映射载体 |
| `MD_LoadBC_StepLoadsOut_Type` | `MD_LBCPH_Brg.f90` | Load 输出缓存 | 步级载荷映射载体 |
| `MD_LoadBC_BuildStepBCs_Ctx_Type` | `MD_LBCPH_Brg.f90` | BC 构建上下文 | 步级 BC 构建 |
| `MD_LoadBC_BuildStepLoads_Ctx_Type` | `MD_LBCPH_Brg.f90` | Load 构建上下文 | 步级载荷构建 |
| `RT_Mesh_IDMap` | `MD_Mesh_Brg.f90` | ID 映射表 | 网格 ID 映射 |
| `MD_RT_Elem_Comp_Idx_Arg` | `MD_ElemRT_Brg.f90` | 单元计算索引参数 | Arg 束 |
| `MD_IC_ContactAddK_Arg` | `MD_Int_ContactArgs.f90` | 接触刚度添加参数 | Arg 束 |
| `MD_IC_ContactAddForce_Arg` | `MD_Int_ContactArgs.f90` | 接触力添加参数 | Arg 束 |
| `MD_IC_ContactAssemTriplets_Arg` | `MD_Int_ContactArgs.f90` | 接触三元组装配参数 | Arg 束 |
| `MD_IC_ContactInit_Arg` | `MD_Int_ContactArgs.f90` | 接触初始化参数 | Arg 束 |
| `MD_IC_ContactUpdateGeom_Arg` | `MD_Int_ContactArgs.f90` | 接触几何更新参数 | Arg 束 |
| `MD_IC_ContactEvalFace_Arg` | `MD_Int_ContactArgs.f90` | 接触面求值参数 | Arg 束 |

### 2.2 State 类型（可变运行时状态）

| TYPE 名 | 说明 |
|----------|------|
| 无 | Bridge 不持有状态（无状态转发） |

### 2.3 Algo 类型（算法配置）

| TYPE 名 | 说明 |
|----------|------|
| 无 | Bridge 不执行算法 |

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名 | 定义文件 | 核心字段 | 用途 |
|----------|----------|----------|------|
| `MD_Bridge_Ctx` | 概念级 | `mapping_rules`, `version`, `status` | 桥接上下文（概念级，实际内嵌于各 Brg 过程参数） |

---

## 3. 功能模块清单

### 3.1 Bridge_L4 子目录（L3→L4 桥接，6 个文件）

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|----------|-----------|------|
| `MD_MatLibPH_Brg.f90` | `MD_MatLibPH_Brg` | _Brg | `MD_PH_GetMaterialType`, `MD_PH_GetMaterialType_FromDesc`, `MD_PH_RouteToConstitutive`, `MD_PH_RouteToConstitutive_Idx`, `MD_PH_TransferModelDef` | ✅ 已实现 (**LEGACY** for hot path) |
| `MD_ElemPH_Brg.f90` | `MD_ElemPH_Brg` | _Brg | `MD_PH_Elem_GetElemCtx_Idx`, `MD_PH_Elem_CalcContinuum2D/3D`, `MD_PH_Elem_CalcPoroSaturated/TwoPhase`, `MD_PH_Elem_CalcThermal/THM/Poro/Thm` | ✅ 已实现 |
| `MD_LBCPH_Brg.f90` | `MD_LBCPH_Brg` | _Brg | `LoadBC_FromDesc`, `BC_FromDesc`, `Load_FromDesc`, `MD_LoadBC_PH_Brg_BuildStepBCs/Loads`, `*_FromDomain`, `*_Idx` | ✅ 已实现 |
| `MD_GeomPH_Brg.f90` | `MD_GeomPH_Brg` | _Brg | `MD_PH_Geom_FillElemCtx`, `MD_PH_Geom_FillElemCtx_Idx` | ✅ 已实现 |
| `MD_ContPH_Brg.f90` | `MD_ContPH_Brg` | _Brg | `MD_Cont_PH_FillParams_FromMD` (generic: `MD_Cont_PH_Fill_From_Type` / `MD_Cont_PH_Fill_From_Union`) | ✅ 已实现 |
| `MD_ConstraintPH_Brg.f90` | `MD_ConstraintPH_Brg` | _Brg | `MD_Constraint_PH_FillParams_FromMD`（generic→`MD_Constraint_PH_Fill_MPC/Tie/Coupling`） | ✅ 已实现 |

### 3.2 Bridge_L5 子目录（L3→L5 桥接，13 个文件）

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|----------|-----------|------|
| `MD_AssemRT_Brg.f90` | `MD_AssemRT_Brg` | _Brg | `MD_RT_Assem_CSRFree/CSRFromTriplet/CSRSpMV/TripletAdd/TripletFree/TripletInit` | ✅ 已实现 |
| `MD_ContRT_Brg.f90` | `MD_ContRT_Brg` | _Brg | `MD_RT_Cont_TripletAdd`, `MD_RT_Cont_GetEqId` | ✅ 已实现 |
| `MD_ElemRT_Brg.f90` | `MD_ElemRT_Brg` | _Brg | `MD_RT_Elem_Comp_Idx`, `MD_RT_Elem_Comp` | ✅ 已实现 |
| `MD_Int_Brg.f90` | `MD_Int_Brg` | _Brg | `MD_Contact_Brg_BuildStepPairs`, `MD_Contact_Brg_ConvertProperty`, `UF_ContBrg_InitFromMD/IncrInit/IterationInit`, `UF_ContBrg_GetPropForInteract` | ✅ 已实现 |
| `MD_Int_ContactArgs.f90` | `MD_IntContactArgs` | — | Arg 束 TYPE 定义（6 个 `MD_IC_*_Arg`），无过程 | ✅ 已实现 |
| `MD_KWRT_Brg.f90` | `MD_KWRT_Brg` | _Brg | `MD_RT_KW_ParseComplexFrequency/Direct/ModalDamping/ModalDynamic/ResponseSpectrum/SteadyState/Substructure/StaticRiks` | ✅ 已实现 |
| `MD_LBCRT_Brg.f90` | `MD_LBCRT_Brg` | _Brg | `MD_RT_LoadBC_GetBCWorkspace`, `MD_RT_LoadBC_GetEqId/GetEqIdByDofType/GetThreadWS` | ✅ 已实现 |
| `MD_Mesh_Brg.f90` | `MD_Mesh_Brg` | _Brg | `RT_Mesh_BrgInit/InitElems/InitMats/InitSects`, `RT_Mesh_BrgMapNodeId/ElemId/MatId/SectId`, `RT_Mesh_BrgClean`, `RT_Mesh_BrgGetNodeCnt/ElemCnt`, `RT_Mesh_Brg_GetNodeCoords_Idx/GetElemConnect_Idx` | ✅ 已实现 |
| `MD_Model_Brg.f90` | `MD_Model_Brg` | _Brg | `UF_BindModelRuntime_ToDataPlatform`, `UF_BuildContMesh_FromUFModel`, `UF_BuildStepBC/Load_ForNewCore`, `UF_ProjectSectionsToModelCtx`, `UF_BuildContactPairDef_FromDB/Surface_FromNodeSet/Contact_FromUFModel`, `UF_FillSurfaceDofMap_FromDOFMgr` | ✅ 已实现 |
| `MD_ModelRT_Brg.f90` | `MD_ModelRT_Brg` | _Brg | `MD_RT_Model_Sys_StepMgr_AddStep/GetStepCfg/Init/InitModelVars` | ✅ 已实现 |
| `MD_Out_Brg.f90` | `MD_Out_Brg` | _Brg | `MD_Out_Brg_BuildFieldOutTasks/FromDomain/Select`, `MD_Out_Brg_BuildHistOutTasks/FromDomain/Select`, `MD_Out_Brg_ShouldOutput` | ✅ 已实现 |
| `MD_UIRT_Brg.f90` | `MD_UIRT_Brg` | _Brg | `MD_RT_UI_RunJob` | ✅ 已实现 |
| `MD_UniFldRT_Brg.f90` | `MD_UniFldRT_Brg` | _Brg | `MD_RT_UniFld_EvalStructAtIp`, `MD_RT_UniFld_IntegrateIp` | ✅ 已实现 |

### 3.3 求解器桥（不在 Bridge 目录）

| 文件名 | MODULE 名 | 说明 | 状态 |
|--------|-----------|------|------|
| `Analysis/Solver/MD_Solv_Mgr.f90` | `MD_Solv_Mgr` | 求解器配置域 + `MD_Solver_Brg_*` 选路过程（原独立 `MD_Solv_Brg.f90` 已并入） | ✅ 已实现 |

### 3.4 真值表索引

| 文档 | 位置 | 说明 |
|------|------|------|
| `BRIDGE_INDEX.md` | `L3_MD/Bridge/BRIDGE_INDEX.md` | 新增/改名桥模块必须先登记再写合同表 |

---

## 4. 对外接口（公开 API）

### 4.1 Bridge_L4 接口（L3→L4 映射）

| 接口 | MODULE | 功能 | 参数 |
|------|--------|------|------|
| `MD_PH_GetMaterialType` | `MD_MatLibPH_Brg` | 查询材料类型 | `mat_def → mat_type (FN)` |
| `MD_PH_GetMaterialType_FromDesc` | `MD_MatLibPH_Brg` | 从 Desc 查询材料类型 | `mat_desc → mat_type (FN)` |
| `MD_PH_RouteToConstitutive` | `MD_MatLibPH_Brg` | 材料路由到 L4 本构 (**LEGACY**) | `mat_def, mat_ctx(MD_PH_Legacy_MatEval_Ctx), status` |
| `MD_PH_RouteToConstitutive_Idx` | `MD_MatLibPH_Brg` | 索引版材料路由 (**LEGACY**) | `mat_idx, mat_ctx(MD_PH_Legacy_MatEval_Ctx), status` |
| `MD_PH_TransferModelDef` | `MD_MatLibPH_Brg` | 转移材料模型定义 | `mat_def, ph_slot, status` |
| `MD_PH_Elem_GetElemCtx_Idx` | `MD_ElemPH_Brg` | 获取单元上下文 | `elem_idx, ctx [OUT], status` |
| `MD_PH_Elem_CalcContinuum2D` | `MD_ElemPH_Brg` | 2D 连续体计算桥接 | `elem_type, formul, ctx, state_in/out` |
| `MD_PH_Elem_CalcContinuum3D` | `MD_ElemPH_Brg` | 3D 连续体计算桥接 | `elem_type, formul, ctx, state_in/out` |
| `MD_Cont_PH_FillParams_FromMD` | `MD_ContPH_Brg` | 接触参数→PH 填充 | `prop [IN], ph_params [OUT], status` |
| `MD_PH_Geom_FillElemCtx` | `MD_GeomPH_Brg` | 几何→PH ElemCtx 填充 | `geom_ctx [IN], elem_ctx [OUT], status` |
| `LoadBC_FromDesc` / `BC_FromDesc` / `Load_FromDesc` | `MD_LBCPH_Brg` | 载荷/BC Desc→PH 映射 | `desc [IN], cache [OUT], status` |
| `MD_LoadBC_PH_Brg_BuildStepBCs` | `MD_LBCPH_Brg` | 构建步级 BCs | `ctrl [IN], bcs_out [OUT], status` |
| `MD_LoadBC_PH_Brg_BuildStepLoads` | `MD_LBCPH_Brg` | 构建步级载荷 | `ctrl [IN], loads_out [OUT], status` |
| `MD_Constraint_PH_FillParams_FromMD` | `MD_ConstraintPH_Brg` | MPC / Tie / Coupling→`PH_Constraint_Params`（generic 接口，见 `MD_Constraint_PH_Fill_MPC` 等） | 各 Def `[IN]`, `ph_params [OUT]`, `status` |

### 4.2 Bridge_L5 接口（L3→L5 映射）

| 接口 | MODULE | 功能 | 参数 |
|------|--------|------|------|
| `MD_RT_Assem_TripletInit/Add/Free` | `MD_AssemRT_Brg` | 三元组装配操作 | `triplet [INOUT], row/col/val [IN]` |
| `MD_RT_Assem_CSRFromTriplet/SpMV/Free` | `MD_AssemRT_Brg` | CSR 格式操作 | `triplet [IN], csr [OUT]` |
| `MD_RT_Cont_TripletAdd` | `MD_ContRT_Brg` | 接触三元组添加 | `row/col/val [IN]` |
| `MD_RT_Cont_GetEqId` | `MD_ContRT_Brg` | 接触方程 ID | `node_id [IN] → eq_id (FN)` |
| `MD_RT_Elem_Comp_Idx` / `MD_RT_Elem_Comp` | `MD_ElemRT_Brg` | 单元计算调用 | `elem_idx, ctx, state_in/out` |
| `MD_Contact_Brg_BuildStepPairs` | `MD_Int_Brg` | 构建步级接触对 | `step_id, pairs [OUT], status` |
| `MD_Contact_Brg_ConvertProperty` | `MD_Int_Brg` | 转换接触属性 | `prop [IN], rt_prop [OUT], status` |
| `UF_ContBrg_InitFromMD` | `MD_Int_Brg` | 从 MD 初始化接触桥 | `model [IN], status [OUT]` |
| `RT_Mesh_BrgInit/InitElems/InitMats/InitSects` | `MD_Mesh_Brg` | 网格→RT 初始化 | `mesh [IN], rt_mesh [OUT], status` |
| `RT_Mesh_BrgMapNodeId/ElemId/MatId/SectId` | `MD_Mesh_Brg` | ID 映射 | `l3_id [IN] → rt_id` |
| `UF_BuildContMesh_FromUFModel` | `MD_Model_Brg` | 从模型构建接触网格 | `model [IN], status [OUT]` |
| `UF_BuildStepBC/Load_ForNewCore` | `MD_Model_Brg` | 步级 BC/Load 构建 | `model [IN], step_id [IN], status [OUT]` |
| `MD_RT_KW_Parse*` (8 个) | `MD_KWRT_Brg` | 关键字→RT 解析 | `tokens [IN], cfg [OUT], status` |
| `MD_RT_LoadBC_GetBCWorkspace/GetEqId` | `MD_LBCRT_Brg` | 载荷/BC→RT 查询 | `bc_id [IN], workspace/eq_id [OUT]` |
| `MD_Out_Brg_Build*OutTasks` (6 个) | `MD_Out_Brg` | 输出任务构建 | `cfg [IN], tasks [OUT], status` |
| `MD_RT_Model_Sys_StepMgr_*` (4 个) | `MD_ModelRT_Brg` | 步管理器操作 | `step_cfg [IN], status [OUT]` |

---

## 5. 跨层数据流

### 5.1 上游依赖（L2/L1 的什么数据）

| 上游模块 | 消费内容 | 用途 |
|----------|----------|------|
| `IF_Prec_Core` (L1) | `wp`, `i4`, `i8` 精度参数 | 全域数值精度 |
| `IF_Err_Brg` (L1) | `ErrorStatusType`, `init_error_status` | 错误传播 |
| L3_MD/Material | 材料 Desc（`MD_Mat_Desc` 等） | Bridge_L4 映射到 `PH_Mat_Slot` |
| L3_MD/Element | 单元 Desc（`UF_ElemType` 等） | Bridge_L4/L5 映射到 PH/RT |
| L3_MD/Element/Mesh | 网格 Desc（节点/单元拓扑） | Bridge_L4/L5 映射到 PH/RT |
| L3_MD/Boundary (LoadBC) | 载荷/BC Desc | Bridge_L4 映射到 `PH_BC_Cache` |
| L3_MD/Interaction | 接触 Desc | Bridge_L4/L5 映射到 PH/RT |
| L3_MD/Constraint | 约束 Desc（MPC/Tie/Coupling） | Bridge_L4 映射到 PH |
| L3_MD/Analysis | 分析步/求解器 Desc | Bridge_L5 映射到 RT |
| L3_MD/Output | 输出 Desc | Bridge_L5 映射到 RT |

### 5.2 下游消费者（L4/L5 如何读取本域数据）

| 下游消费者 | 消费内容 | 调用路径 |
|-----------|----------|----------|
| L4_PH/Populate | 通过官方 Brg 填充 L4 slot | `PH_L4_Populate_*` → `MD_*PH_Brg` |
| L4_PH/Bridge | L3→L4 查询与薄组装 | `MD_ElemPH_Brg` / `MD_GeomPH_Brg` |
| L5_RT/Assembly | L3→L5 运行时映射 | `MD_AssemRT_Brg` |
| L5_RT/Solver | L3→L5 求解器映射 | `MD_Solv_Mgr` (Solver_Brg_*) |
| L5_RT/Contact | L3→L5 接触映射 | `MD_ContRT_Brg` / `MD_Int_Brg` |
| L6_AP/Input | L3→L6 关键字映射 | `MD_KWRT_Brg` |

### 5.3 数据流图

```
[L3_MD 各域 Desc] ──┐
  Material           │
  Element            ├──→ [L3_MD/Bridge] ──→ Bridge_L4/ ──→ [L4_PH Populate/Slots]
  LoadBC             │    (只读映射)     ──→ Bridge_L5/ ──→ [L5_RT Init/Assembly]
  Mesh               │                  ──→ MD_Solv_Mgr ──→ [L5_RT Solver]
  Interaction        │
  Constraint         │
  Analysis/Output    │
[L1_IF] Prec/Err ───┘

数据方向: L3 Desc (冷数据) → Bridge 映射 → L4 PH Slot/L5 RT Pool (热数据)
写回方向: 仅 L5_RT/WriteBack，不经 Bridge 反向回写
```

### 5.4 数据映射规则

1. **单向映射**: L3→L4/L5 单向，禁止反向依赖
2. **只读访问**: L4/L5 通过官方 Brg 只读访问 L3 Desc
3. **索引转换**: Bridge 负责 L3 索引→L4/L5 索引转换
4. **单位一致**: 映射前后单位必须一致
5. **版本管理**: 新增字段向后兼容，删除字段需 major 版本

---

## 6. 域间契约

### 6.1 同层域间关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Material | S(消费) | Bridge_L4 消费 Material Desc 映射到 PH_Mat_Slot |
| R2 | L3_MD/Element/Mesh + Elem | S(消费) | Bridge_L4/L5 消费 Mesh 拓扑与 Elem 单元族 Desc |
| R3 | L3_MD/Boundary | S(消费) | Bridge_L4 消费 Boundary Desc |
| R4 | L3_MD/Interaction | S(消费) | Bridge_L4 消费 Interaction Desc |
| R5 | L3_MD/Analysis | S(消费) | Bridge_L5 消费 Step/Solver Desc |
| R6 | L3_MD/Output | S(消费) | Bridge_L5 消费 Output Desc |
| R7 | L3_MD/Constraint | S(消费) | Bridge_L4 消费 Constraint Desc |
| R8 | L3_MD/Field | S(消费) | Bridge_L5 消费 Field Desc |

### 6.2 跨层域间关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R9 | L4_PH/Populate | B(桥接) | L4 Populate 调用 Bridge_L4 模块 |
| R10 | L4_PH/Bridge | B(桥接) | L4 侧桥接适配 |
| R11 | L5_RT/Init | B(桥接) | L5 Init 调用 Bridge_L5 模块 |
| R12 | L5_RT/Assembly | B(桥接) | L5 装配调用 Bridge_L5 |
| R13 | L1_IF/Error | U(USE) | 错误码定义 |

### 6.3 与邻层合同

| 对端 | 合同/代码 | 关系 |
|------|-----------|------|
| L4_PH Bridge | `L4_PH/Bridge/CONTRACT.md` | L3 为 `MD_*_PH_Brg` 唯一宿主；禁止 L4 USE L3 Core |
| L4_PH Populate | `L4_PH/contracts/CONTRACT_Populate_Layer.md` | Populate 通过官方 Brg 或只读 API 填充 L4 slot |
| L5_RT Bridge | `L5_RT/Bridge/CONTRACT.md` | L3 为 `MD_*_RT_Brg` 唯一宿主；L5 编排 RT 桥接 |
| BRIDGE_INDEX | `L3_MD/Bridge/BRIDGE_INDEX.md` | 新增/改名桥模块必须先登记再写合同表 |

### 6.4 WriteBack 白名单

| 方向 | 字段 | 说明 |
|------|------|------|
| L3→L4 | 所有 Desc 字段 | 只读（冷数据） |
| L3→L5 | 所有 Desc 字段 | 只读（冷数据） |
| L4→L3 | 不回写 | 通过 Output 域间接回写 |
| L5→L3 | 不回写 | 通过 Output 域间接回写 |

---

## 7. 验收标准

### 7.1 功能完整性检查项

- [ ] Bridge_L4 模块完整：Material/Element/LoadBC/Geom/Contact/Constraint 六个桥接模块全部实现
- [ ] Bridge_L5 模块完整：13 个桥接模块全部实现（含 MD_IntContactArgs Arg 束）
- [ ] BRIDGE_INDEX.md 与实际文件一致：MODULE 名、文件名、职责摘要同步
- [ ] 所有 Bridge 模块均为无状态转发（禁止持有 State）
- [ ] 所有映射操作为 O(1) 或 O(n)（禁止内嵌计算）
- [ ] Init/Finalize 对称：所有 ALLOCATE 均有对应 DEALLOCATE
- [ ] 求解器桥（MD_Solv_Mgr）已登记在 BRIDGE_INDEX §3

### 7.2 命名合规要求

- [ ] Bridge_L4 文件命名：`MD_*PH_Brg.f90` 格式
- [ ] Bridge_L5 文件命名：`MD_*RT_Brg.f90` 格式
- [ ] MODULE 名与文件名一致（Harness Gate H-NAM-03）
- [ ] MODULE 前缀与源层一致（L3 侧用 `MD_*`）
- [ ] 使用 `IF_Prec_Core` 的 `wp`/`i4`（Harness Gate H-ERR-01）

### 7.3 测试覆盖要求

- [ ] 单元级：`MD_MatLibPH_Brg` 材料映射正确性（非热路径/迁移期）
- [ ] 单元级：`MD_ElemPH_Brg` 字段对齐
- [ ] 单元级：`MD_LBCPH_Brg` 参数传递
- [ ] 集成级：L3→L4 Populate 流程端到端
- [ ] 集成级：L3→L5 Assembly 流程端到端
- [ ] 集成级：版本兼容（新旧 Bridge 接口共存）

---

## 附录 A. 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L3_BRIDGE_xxx` (30100–30199) |
| 严重级 | WARNING: 映射字段缺失(可降级); ERROR: Bridge 模块未注册; FATAL: 跨层类型不匹配 |
| 传播规则 | Bridge 内部错误经 `status` 返回调用方（L4 Populate 或 L5 Init）；不自行 STOP |
| 恢复策略 | WARNING 级：日志记录 + 使用默认映射；ERROR/FATAL：中止 Populate 并上报 |

## 附录 B. 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Bridge 模块须在 BRIDGE_INDEX.md 登记 | 硬 | Harness 检查 | H-BRG-01 |
| Bridge 模块禁止持有 State（无状态转发） | 硬 | Code Review | — |
| Bridge 仅做 O(1)/O(n) 映射，禁止内嵌计算 | 硬 | Code Review | H-HOT-01 |
| Bridge 接口变更须同步更新本 CONTRACT | 软 | Code Review | — |
| Bridge_L4/L5 文件命名 `MD_*PH_Brg` / `MD_*RT_Brg` | 软 | Harness 命名检查 | H-NAM-03 |

## 附录 C. 热路径规范

- **热路径**: 否（Populate/Step-Init 冷路径）
- **性能要求**: O(1) 或 O(n) 拷贝/映射
- **内存管理**: Init 阶段预分配，禁止步内 ALLOCATE
- **禁止项**: 内嵌单元积分/NR 迭代/全局 CSR 持有
- **例外**: `MD_MatLibPH_Brg` 中 `MD_PH_RouteToConstitutive_Idx` 标为 **LEGACY for hot path**，禁止在装配/IP 循环新增调用

## 附录 D. Phase 4 双桥接收敛（Populate 单向 · 前提）

1. **L4 侧 Populate 单向**: 材料/单元等热数据以 `PH_L4_*_Populate` + slot 为金线，从 L3 只读拉取
2. **`MD_MatLibPH_Brg`**: `MD_PH_RouteToConstitutive` / `MD_PH_RouteToConstitutive_Idx` 标为 LEGACY for hot path；禁止在装配/IP 循环新增调用；迁移完成后删除
3. **写回**: 仅 `L5_RT/WriteBack`

## 附录 E. 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | MD_Bridge_Desc (概念级) | Bridge 不持有实质 Desc TYPE |
| 2 | State 定义 | N/A | Bridge 无状态 |
| 3 | Algo 定义 | N/A | Bridge 不执行算法 |
| 4 | Ctx 定义 | MD_Bridge_Ctx (概念级) | 映射上下文 |
| 5 | Init/Finalize | 各 Brg 模块初始化 | Populate 期调用 |
| 6 | Query | `MD_*_Brg_Map` 系列 | 只读映射查询 |
| 7 | Validate | 映射前参数校验 | 内嵌于 Map 过程 |
| 8 | Populate | Bridge 本身即 Populate 管道 | 核心职责 |
| 9 | Bridge | 自身即 Bridge 域 | — |
| 10 | WriteBack | N/A | Bridge 不参与写回 |
| 11 | Parse | N/A | 由 KeyWord 域处理 |
| 12 | Compute | N/A | 禁止计算 |
| 13 | Error | status 参数返回 | 见附录 A |

## 附录 F. 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `Bridge_L4/MD_ConstraintPH_Brg.f90` | `MD_ConstraintPH_Brg` | `PH_Constraint_Params`, `PH_Constraint_Params_Array` | `MD_Constraint_PH_FillParams_FromMD` (PUB,generic), `MD_Constraint_PH_Fill_MPC` (PRV,Populate), `MD_Constraint_PH_Fill_Tie` (PRV,Populate), `MD_Constraint_PH_Fill_Coupling` (PRV,Populate) |
| `Bridge_L4/MD_ContPH_Brg.f90` | `MD_ContPH_Brg` | — | `MD_Cont_PH_Fill_From_Type` (PRV,Populate), `MD_Cont_PH_Fill_From_Union` (PRV,Populate) |
| `Bridge_L4/MD_ElemPH_Brg.f90` | `MD_ElemPH_Brg` | `MD_PH_Elem_GetElemCtx_Arg` | `MD_PH_Elem_GetElemCtx_Idx` (PUB,Query), `MD_PH_Elem_CalcContinuum2D/3D` (PUB), `MD_PH_Elem_CalcPoro*` (PUB), `MD_PH_Elem_CalcThermal/THM/Poro/Thm` (PUB) |
| `Bridge_L4/MD_GeomPH_Brg.f90` | `MD_GeomPH_Brg` | `MD_PH_Geom_FillElemCtx_Arg` | `MD_PH_Geom_FillElemCtx` (PUB,Populate), `MD_PH_Geom_FillElemCtx_Idx` (PUB,Populate) |
| `Bridge_L4/MD_LBCPH_Brg.f90` | `MD_LBCPH_Brg` | `MD_LoadBC_StepBCsOut_Type`, `MD_LoadBC_StepLoadsOut_Type`, `MD_LoadBC_BuildStepBCs_Ctx_Type`, `MD_LoadBC_BuildStepLoads_Ctx_Type` | `LoadBC_FromDesc` (PUB), `BC_FromDesc` (PUB), `Load_FromDesc` (PUB), `MD_LoadBC_PH_Brg_BuildStepBCs/Loads` (PUB,Parse), `*_FromDomain` (PUB,Parse), `*_Idx` (PUB,Parse) |
| `Bridge_L4/MD_MatLibPH_Brg.f90` | `MD_MatLibPH_Brg` | — | `MD_PH_GetMaterialType` (FN,PUB,Query), `MD_PH_GetMaterialType_FromDesc` (FN,PUB,Query), `MD_PH_RouteToConstitutive` (PUB,LEGACY), `MD_PH_RouteToConstitutive_Idx` (PUB,LEGACY), `MD_PH_TransferModelDef` (PUB) |
| `Bridge_L5/MD_AssemRT_Brg.f90` | `MD_AssemRT_Brg` | — | `MD_RT_Assem_CSRFree/CSRFromTriplet/CSRSpMV/TripletAdd/TripletFree/TripletInit` (PUB) |
| `Bridge_L5/MD_ContRT_Brg.f90` | `MD_ContRT_Brg` | — | `MD_RT_Cont_TripletAdd` (PUB), `MD_RT_Cont_GetEqId` (FN,PUB,Query) |
| `Bridge_L5/MD_ElemRT_Brg.f90` | `MD_ElemRT_Brg` | `MD_RT_Elem_Comp_Idx_Arg` | `MD_RT_Elem_Comp_Idx` (PUB), `MD_RT_Elem_Comp` (PUB) |
| `Bridge_L5/MD_Int_ContactArgs.f90` | `MD_IntContactArgs` | `MD_IC_ContactAddK_Arg`, `MD_IC_ContactAddForce_Arg`, `MD_IC_ContactAssemTriplets_Arg`, `MD_IC_ContactInit_Arg`, `MD_IC_ContactUpdateGeom_Arg`, `MD_IC_ContactEvalFace_Arg` | 无过程 |
| `Bridge_L5/MD_Int_Brg.f90` | `MD_Int_Brg` | — | `MD_Contact_Brg_BuildStepPairs` (PUB,Bridge), `MD_Contact_Brg_ConvertProperty` (PUB,Bridge), `UF_ContBrg_GetPropForInteract` (PUB,Query), `UF_ContBrg_IncrInit` (PUB), `UF_ContBrg_InitFromMD` (PUB,Init), `UF_ContBrg_IterationInit` (PUB), + 11 PRV helpers |
| `Bridge_L5/MD_KWRT_Brg.f90` | `MD_KWRT_Brg` | — | `MD_RT_KW_Parse*` (8 个 PUB,Parse) |
| `Bridge_L5/MD_LBCRT_Brg.f90` | `MD_LBCRT_Brg` | — | `MD_RT_LoadBC_GetBCWorkspace` (PUB,Query), `MD_RT_LoadBC_GetEqId` (FN,PUB,Query), `MD_RT_LoadBC_GetEqIdByDofType` (FN,PUB,Query), `MD_RT_LoadBC_GetThreadWS` (FN,PUB,Query) |
| `Bridge_L5/MD_Mesh_Brg.f90` | `MD_Mesh_Brg` | `RT_Mesh_IDMap` | `RT_Mesh_BrgInit/InitElems/InitMats/InitSects` (PUB,Bridge), `RT_Mesh_BrgMap*Id` (PUB,Bridge), `RT_Mesh_BrgClean` (PUB,Bridge), `RT_Mesh_BrgGet*Cnt` (FN,PUB,Bridge), `RT_Mesh_Brg_Get*_Idx` (PUB,Query) |
| `Bridge_L5/MD_ModelRT_Brg.f90` | `MD_ModelRT_Brg` | — | `MD_RT_Model_Sys_StepMgr_AddStep/GetStepCfg/Init/InitModelVars` (PUB) |
| `Bridge_L5/MD_Model_Brg.f90` | `MD_Model_Brg` | — | `UF_BindModelRuntime_ToDataPlatform` (PUB), `UF_BuildContMesh_FromUFModel` (PUB,Populate), `UF_BuildStepBC/Load_ForNewCore` (PUB,Populate), `UF_ProjectSectionsToModelCtx` (PUB), `UF_BuildContactPairDef_FromDB` (PUB,Populate), `UF_BuildContact_FromUFModel` (PUB,Populate), `UF_FillSurfaceDofMap_FromDOFMgr` (PUB,Populate) |
| `Bridge_L5/MD_Out_Brg.f90` | `MD_Out_Brg` | — | `MD_Out_Brg_BuildFieldOutTasks/FromDomain/Select` (PUB,Bridge), `MD_Out_Brg_BuildHistOutTasks/FromDomain/Select` (PUB,Bridge), `MD_Out_Brg_ShouldOutput` (PUB,Bridge) |
| `Bridge_L5/MD_UIRT_Brg.f90` | `MD_UIRT_Brg` | — | `MD_RT_UI_RunJob` (PUB) |
| `Bridge_L5/MD_UniFldRT_Brg.f90` | `MD_UniFldRT_Brg` | — | `MD_RT_UniFld_EvalStructAtIp` (PUB), `MD_RT_UniFld_IntegrateIp` (PUB,Compute) |

---

## 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 2026-04-17 | 初始版本，P2 阶段补全 L3_MD Bridge 合同卡 |
| v1.1 | 2026-04-25 | Bridge_L4 文件名与模块名对齐真源；新增 §十六 Phase4 收敛 |
| v1.2 | 2026-04-25 | Bridge_L5 与 BRIDGE_INDEX.md 对齐；跨域矩阵中 RT 桥名修正 |
| v2.1 | 2026-04-26 | 文件计数修正 (6+13)；Layer-Only 域诊断修复 |
| v2.2 | 2026-04-26 | MODULE 名修正: `RT_Mesh_Brg` → `MD_Mesh_Brg`; Solver 引用 `MD_Solv` → `MD_Solv_Mgr` |
| v3.0 | 2026-04-28 | 补全至标准 7 章节格式，完整四类 TYPE 清单、功能模块清单、对外接口签名、跨层数据流、域间契约、验收标准 |
| v3.1 | 2026-04-30 | Pilot：删除 `MD_*_PH_Bridge`、`MD_RT_UI_RunJob_Ctx` 无实质转发；对外以 `MD_Constraint_PH_FillParams_FromMD`、`MD_RT_UI_RunJob` 为准 |

---

*维护: 新增 `MD_*_Brg` 模块或变更桥接规则时，先改 BRIDGE_INDEX.md，再更新本卡*
