## LoadBC（P4 · 原 Boundary 目录）域级合同卡

- **层级**：L3_MD
- **域名**：Load / Boundary / IC — **模型定义层**
- **状态**：**DEPRECATED** — 本域内容已在 Phase 3 中迁移至独立 `L3_MD/LoadBC/` 目录
- **迁移目标**：`ufc_core/L3_MD/LoadBC/CONTRACT.md`
- **缩写**：LoadBC（历史目录名 **Boundary**；实现以 `MD_LBC_*` / `MD_LBC_Domain` / `MD_LBC_Idx` 为主；域容器真源已迁移至 **`MODULE MD_LBC_Def` 内 `MD_LoadBC_Domain`**）
- **旧文件保留**：`MD_Load_Def.f90`, `MD_BC_Def.f90`, `MD_LBC_Domain.f90` 标记 `! DEPRECATED`，为向后兼容保留
- **职责**：载荷、边界、初值的 **Desc**（类型、幅值引用、作用集等），对齐 HYPLAS **INLOAD 输入侧**；**不在 L3 做施加算法**（施加在 L4 `PH_Ldbc` / L5）。
- **四型配置**：
  - **Desc**：`LoadDef`、`BCDef`、`LoadBCTree`、`MD_LdbcDesc`、IC/场相关 Desc；载荷类型常量（集中/分布/体/压等）与目标（节点/单元集/面）。
  - **State**：`MD_LoadBC_*_Sta`（若存在）、树/索引的物化状态；**不**存放步内收敛历史。
  - **Ctx**：`MD_LoadBC_*_Ctx`（若存在）；**无** L5 求解器 Ctx；Bridge 入参由 RT/PH 注入。
  - **Algo**：`MD_LoadBC_Algo`（容量/映射等元算法）；**无**单元积分 `Compute_Fe`；分布载荷到节点/面的几何权重可为占位或解析默认。
- **幅值（Amp）耦合（单向）**：`UF_Model%amplitudes(:)` 为 `TYPE(MD_Amp_Slot_Desc)`；载荷/BC 的 `amplitudeId` 为 **1-based 槽位索引**。标度因子经 **`MD_Amplitude::Amp_GetFactor`**：无 L3 层容器时三参 `(amplitudes, id, time)`；调用方传入 **`TYPE(MD_L3_LayerContainer), OPTIONAL :: md_layer`** 时经模块内私有封装走 **四参** `Amp_GetFactor(..., md_layer%amplitude)`（域优先 + UF 回退，与 `RT_Amp_FactorAt` 一致；见 [Amplitude/CONTRACT.md](../Analysis/Amplitude/CONTRACT.md)）。id≤0、未分配或越界 → `1.0`。L3 **不**手写替代时间插值旁路。
- **核心模块（当前树，与源码一致）**：
  - `MD_BC_Def.f90` — BC 四型基类与 DISP/UTEMP/UMASFL/UPOT 等 Desc 特化
  - `MD_Load_Def.f90` — Load 四型基类与 DLOAD/DFILM 等特化；`MD_LoadBC_State` / `MD_LoadBC_Algo` / `MD_LoadBC_Ctx`
  - `MD_LBC_Domain.f90` — 破环依赖：`MD_LoadBC_Domain`、Idx 用 `*_Arg`、Legacy 侧 `MD_Load_Desc` / `MD_BC_Desc` 等
  - `MD_LBC_Mgr.f90` — **`MODULE MD_LBC_Mgr`**：`LoadDef` / `BCDef`、目标/类型常量、Legacy→域转换、`MD_LoadBC_SyncFromLegacy`、步/幅值查询与分布载荷骨架
  - `MD_LBC_Idx.f90` — **`MD_LoadBC_Idx_Bind` / `MD_LoadBC_Idx_Reset`** 与 `MD_LoadBC_Get*_Idx`（避免与全局容器的循环 `USE`）
  - `MD_LBC_Brg.f90` — L6 向 **`UF_*`** API 类型与兼容常量（与 `MD_Brg_API` 衔接）
  - `DESIGN_BC_FourTypes.md` — BC 四型设计说明（非合同正文）

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### P7 职责子表（INLOAD 定义 / 方案 §5.2）

| 条目 | 本域（LoadBC）责任 | 禁止 |
|------|------------------|------|
| `KW_CAT_LOAD` 全部关键字（`*CLOAD`、`*DLOAD`、`*DSLOAD`、热流等） | Desc → `MD_LBC` / `MD_LBC_Domain`（Keyword 解析链见 **KeyWord** 域） | 单元上积分与组装外力 |
| `*INITIAL STATE`、`*GEOSTATIC STRESS` | **强制** 本域（`KW_CAT_LOAD`；Mapper：`map_initial_state_ldbc`、`map_geostatic_stress`） | 写入 **Const**；与 `*GEOSTATIC` **过程**（Step）混淆 |
| `*BOUNDARY`、`*INITIAL CONDITIONS` | Desc（BC/IC） | 约束方程数值处理（MPC 求解在 L4/L5） |
| 幅值 | 仅 **名字引用**；曲线真相源在 **Amp** | 在 L3 内插值时间历程（步内） |

**约束类关键字**（`*TIE`、`*MPC` 等）主域为 **Const**；与 LoadBC 分界见 [`../Constraint/CONTRACT.md`](../Constraint/CONTRACT.md) 及 L4 Constraint 合同。

**INDATA 关键字表**：仓库内独立 `INDATA_MAP.md` 尚未落盘；职责与 P7 子表以 [`UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md) §5.2 为准。

- **对端 L4 合同**：[`../../../L4_PH/LoadBC/CONTRACT.md`](../../../L4_PH/LoadBC/CONTRACT.md)（`PH_LoadBC_Domain`、Populate、与 L5 `CONTRACT_LoadBC` 交叉引用见该文）。

### Domain Pillar 交叉引用 (v2.0)

- **域柱**: P4 LoadBC (贯通柱 L3/L4/L5)
- **域柱架构文档**: `UFC/docs/05_Project_Planning/PPLAN/06_核心架构/UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §P4
- **L4 合同**: `L4_PH/LoadBC/CONTRACT.md`
- **L5 合同**: `L5_RT/LoadBC/CONTRACT.md` (v2.0)
- **设计决策**: `UFC/docs/05_Project_Planning/PPLAN/06_核心架构/L5_RT_DESIGN_DECISIONS.md` §LoadBC 域重构

**角色分工**:
- L3 (本层): **Desc 定义者** — `LoadDef`, `BCDef`, Amplitude 引用, 步绑定
- L4: **物理计算者** — `PH_LoadBC_Domain`, `PH_BC_Apply`, `PH_Load_Assemble_Fext`
- L5: **运行调度者** — 收敛控制, cutback, 载荷/BC 编排

---

### 待完善（Backlog）

- **`MD_LBC_Mgr.f90`**：面元面积、node/elem set 物化、`MD_LoadBC_Domain` Init/Finalize 骨架、与 Step 的同步委托等处仍有 `TODO`；实现须与 **Mesh / Assembly / Model** 真源对齐，并保持 **Amp** 仅经 `Amp_GetFactor`。
- **构建**：`UFC/ufc_core/CMakeLists.txt` 仍将 `L3_MD/Boundary/*.f90` 从默认 `ufc_core` 源列表 **排除**；纳入主目标前解除 `EXCLUDE` 并收敛 `USE` 依赖图。
- **`INDATA_MAP.md`**：仓库内文件落盘后，可将本卡「关键字 → 模块」链接改回仓库内锚点（当前以 PPLAN §5.2 为准）。

---

### 错误处理

| 错误场景 | 错误码 | 处理方式 |
|----------|--------|----------|
| 载荷/BC 类型未知 | `IF_STATUS_INVALID` | 返回 status |
| 幅值 ID 越界或无效 | — | 默认因子 1.0（退化处理） |
| 目标节点/单元集不存在 | `IF_STATUS_INVALID` | 返回 status |
| SyncFromLegacy 数据不一致 | `IF_STATUS_ERROR` | 返回 status |

所有公开过程通过 `ErrorStatusType` 返回状态。不使用 `STOP`。

---

### 域际关系

| 序号 | 关联域 | 相对本域 | 契约类型 | 主要接触面 | 备注 |
|------|--------|----------|----------|------------|------|
| R1 | L3_MD/Analysis/Amplitude | 上游 | T+U | `amplitudeId` 索引 → `Amp_GetFactor` | 幅值耦合 |
| R2 | L3_MD/Analysis/Step | 上游 | T+U | 步定义绑定载荷/BC 激活 | |
| R3 | L3_MD/Element/Mesh | 上游 | U | 目标节点/单元/面引用 | |
| R4 | L3_MD/Constraint | 平级 | U | 约束类关键字分界 | 见 Constraint CONTRACT |
| R5 | L4_PH/LoadBC | 下游 | T+B | `LoadDef`/`BCDef` → L4 施加算法 | |
| R6 | L5_RT/LoadBC | 下游 | T+B | L5 组装消费 | |

---

### 约束分级

| 约束 | 级别 | 说明 |
|------|------|------|
| L3 仅 Desc，不做施加算法 | **硬** | 架构原则 |
| 不使用 STOP | **硬** | H-ERR-01 |
| 幅值仅经 `Amp_GetFactor` | **硬** | 不手写插值旁路 |
| CMake 排除待解除 | **软** | 已登记 Backlog |
| 测试覆盖率 | **软** | 待建 |

---

### 十件套 v2.0 映射

| 序号 | 逻辑件 | 物理落地 | 状态 |
|------|--------|----------|------|
| 1 | Contract | `CONTRACT.md`（本文件） | Active |
| 2 | Definition | `MD_BC_Def.f90`, `MD_Load_Def.f90` | Active |
| 3 | Desc | `LoadDef`, `BCDef`, `MD_LdbcDesc` 等 | Active |
| 4 | State | `MD_LoadBC_State` in `MD_Load_Def.f90` | Active |
| 5 | Algo | `MD_LoadBC_Algo` in `MD_Load_Def.f90` | Active |
| 6 | Ctx | `MD_LoadBC_Ctx` in `MD_Load_Def.f90` | Active（占位） |
| 7 | Main/Kernel | `MD_LBC_Mgr.f90` | Active |
| 8 | Bridge | `MD_LBC_Brg.f90` | Active |
| 9 | Runtime Proc | N/A (L3 域) | N/A |
| 10 | Registry | `MD_LBC_Domain.f90` | Active |
| 11 | Populate | `MD_LBC_Mgr.f90` 内 Sync/Legacy 转换 | Active |
| 12 | Diagnostics | 待补 | Deferred |
| 13 | Test | 待建 | Deferred |

---

### 四链说明

| 链 | 本域可核对说明 |
|----|---------------|
| **理论链** | 载荷/边界条件映射 ABAQUS `*CLOAD`/`*DLOAD`/`*BOUNDARY` 等关键字；IC 映射 `*INITIAL CONDITIONS` |
| **逻辑链** | `KeyWord Parser` → `MD_LBC` Desc 填充 → Step 激活 → Amp 标度 → L4 `PH_LoadBC` 施加 → L5 组装 |
| **计算链** | 无（L3 仅存储 Desc；施加与积分在 L4/L5） |
| **数据链** | `LoadDef`/`BCDef`（冷）存储在 `MD_LoadBC_Domain`；幅值通过 `amplitudeId` 索引关联 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `MD_BC_Def.f90` | `MD_BC_Def` | `MD_BC_Base_Desc` | `Init` (TBP,PRV,—); `Reset` (TBP,PRV,—); `BC_Desc_Init` (SUB,PRV,Init); `BC_Desc_Reset` (SUB,PRV,Mutate) |
| `MD_LBC_Mgr.f90` | `MD_LBC_Mgr` | `LoadDef` | `Init` (TBP,PRV,—); `Valid` (TBP,PRV,—); `Clear` (TBP,PRV,—); `md_lbc_amp_from_uf` (FN,PRV,—); `MD_LoadBC_ToLdbcLoadType` (FN,PUB,Parse); `MD_LdbcTo_LoadBCCoreLoadType` (FN,PUB,Parse); `MD_LoadBC_SyncFromLegacy` (SUB,PUB,Parse); `UF_BCDef_To_MD_BC_Desc` (SUB,PUB,—); `UF_CLoadDef_To_MD_Load_Desc` (SUB,PUB,Parse); `UF_DLoadDef_To_MD_Load_Desc` (SUB,PUB,Parse); `UF_BodyForceDef_To_MD_Load_Desc` (SUB,PUB,Parse); `LoadDef_Init_Structured` (SUB,PUB,Init); `BCDef_Init_Structured` (SUB,PUB,Init); `MD_LoadBC_Domain_Init` (SUB,PRV,Init); `MD_LoadBC_Domain_Reset` (SUB,PRV,Mutate); `MD_LoadBC_Domain_Finalize` (SUB,PRV,Finalize); `MD_LoadBC_Domain_SyncFromStep` (SUB,PRV,Parse); `MD_LoadBC_Table_Init` (SUB,PUB,Init); `MD_LoadBC_Table_Reset` (SUB,PUB,Mutate); `MD_LoadBC_Table_Finalize` (SUB,PUB,Finalize); `MD_LoadBC_Table_SyncFromStep` (SUB,PUB,Parse); `Init` (SUB,PRV,—); `Valid` (SUB,PRV,—); `Clear` (SUB,PRV,—); `Init` (SUB,PRV,—); `Valid` (SUB,PRV,—); `Clear` (SUB,PRV,—); `MD_LdbcDesc_Init` (SUB,PRV,Init); `MD_LdbcDesc_GetName` (FN,PRV,Query); `MD_LdbcDesc_Destroy` (SUB,PRV,Finalize); `MD_LdbcDesc_RegLayout` (SUB,PRV,—); `MD_LdbcDesc_Ensure` (SUB,PRV,—); `MD_LdbcSta_Init` (SUB,PRV,Init); `MD_LdbcSta_Destroy` (SUB,PRV,Finalize); `MD_LdbcSta_RegLayout` (SUB,PRV,—); `MD_LdbcSta_Ensure` (SUB,PRV,—); `MD_LdbcCtx_Init` (SUB,PRV,Init); `MD_LdbcCtx_RegLayout` (SUB,PRV,—); `MD_LdbcCtx_Ensure` (SUB,PRV,—); `MD_LoadDesc_Init` (SUB,PRV,Init); `MD_LoadDesc_GetName` (FN,PRV,Query); `MD_LoadDesc_RegLayout` (SUB,PRV,Parse); `MD_LoadDesc_Ensure` (SUB,PRV,Parse); `MD_BndDesc_Init` (SUB,PRV,Init); `MD_BndDesc_RegLayout` (SUB,PRV,—); `MD_BndDesc_Ensure` (SUB,PRV,—); `MD_ConcForceDesc_Init` (SUB,PRV,Init); `MD_ConcForceDesc_RegLayout` (SUB,PRV,—); `MD_ConcForceDesc_Ensure` (SUB,PRV,—); `MD_DistLoadDesc_Init` (SUB,PRV,Init); `MD_DistLoadDesc_RegLayout` (SUB,PRV,—); `MD_DistLoadDesc_Ensure` (SUB,PRV,—); `MD_DispBCDesc_Init` (SUB,PRV,Init); `MD_DispBCDesc_RegLayout` (SUB,PRV,—); `MD_DispBCDesc_Ensure` (SUB,PRV,—); `MD_VelBCDesc_Init` (SUB,PRV,Init); `MD_VelBCDesc_RegLayout` (SUB,PRV,—); `MD_VelBCDesc_Ensure` (SUB,PRV,—); `MD_BodyForceDesc_Init` (SUB,PRV,Init); `MD_BodyForceDesc_RegLayout` (SUB,PRV,—); `MD_BodyForceDesc_Ensure` (SUB,PRV,—); `MD_NeumBCDesc_RegLayout` (SUB,PRV,—); `MD_NeumBCDesc_Ensure` (SUB,PRV,—); `MD_NeumBCDesc_Init` (SUB,PRV,Init); `MD_RobinBCDesc_RegLayout` (SUB,PRV,—); `MD_RobinBCDesc_Ensure` (SUB,PRV,—); `MD_RobinBCDesc_Init` (SUB,PRV,Init); `MD_PerBCDesc_RegLayout` (SUB,PRV,—); `MD_PerBCDesc_Ensure` (SUB,PRV,—); `MD_PerBCDesc_Init` (SUB,PRV,Init); `MD_LdbcAlgo_Init` (SUB,PRV,Init); `MD_LdbcAlgo_RegLayout` (SUB,PRV,—); `MD_LdbcAlgo_Ensure` (SUB,PRV,—); `LoadBCTree_GetID` (FN,PRV,Query); `LoadBCTree_GetName` (FN,PRV,Query); `LoadBCTree_GetType` (FN,PRV,Query); `LoadBCTree_GetParentID` (FN,PRV,Query); `LoadBCTree_GetByPath` (FN,PRV,Query); `LoadBCTree_GetFullPath` (FN,PRV,Query); `LoadBCTree_InitTree` (SUB,PRV,Init); `LoadBCTree_DestroyTree` (SUB,PRV,Finalize); `LoadBCTree_RebuildIndex` (SUB,PRV,—); `LoadBCTree_ValidateTree` (SUB,PRV,Validate); `LoadBCTree_Serialize` (SUB,PRV,—); `LoadBCTree_Deserialize` (SUB,PRV,—); `LoadBCTree_BeginBatch` (SUB,PRV,—); `LoadBCTree_EndBatch` (SUB,PRV,—); `LoadBC_DistributeLoad_ToNodes` (SUB,PUB,—); `LoadBC_DistributeLoad_ToElements` (SUB,PUB,—); `LoadBC_DistributeLoad_ToSurface` (SUB,PUB,—); `LoadBC_ApplyBC_Velocity` (SUB,PUB,—); `LoadBC_ApplyBC_Acceleration` (SUB,PUB,—); `LoadBC_ApplyBC_Displacement_GetNodes` (SUB,PUB,Query); `Ldbc_FlatMap_NodeSet` (SUB,PRV,—); `Ldbc_FlatMap_ElemSet` (SUB,PRV,—); `Ldbc_FlatMap_SurfSet` (SUB,PRV,—); `Ldbc_FindElementIndexById` (SUB,PRV,Query); `Ldbc_GetSurfaceElemFaceArrays` (SUB,PRV,Query); `Ldbc_GetNodeSetNodes` (SUB,PRV,Query); `Ldbc_GetElemSetElements` (SUB,PRV,Query); `Ldbc_GetElementNodes` (SUB,PRV,Query); `Ldbc_GetFaceNodes` (SUB,PRV,Query); `Ldbc_NodeCoordsForMeshIndex` (SUB,PRV,—); `ApplyLoad_FollowerForce` (SUB,PUB,—); `ApplyLoad_PressureFollowing` (SUB,PUB,—); `ApplyLoad_BodyForce` (SUB,PUB,—); `UF_Di_GetStatistics` (SUB,PRV,Query); `UF_Di_ApplyAtTime` (SUB,PRV,—); `UF_VelocityBC_GetStatistics` (SUB,PRV,Query); `UF_Ac_GetStatistics` (SUB,PRV,Query); `UF_Co_GetStatistics` (SUB,PRV,Query); `UF_Co_ApplyAtTime` (SUB,PRV,—); `UF_Di_GetStatistics` (SUB,PRV,Query); `UF_Di_ComputeNodalForces` (SUB,PRV,Compute); `UF_In_GetStatistics` (SUB,PRV,Query); `UF_In_GetStatistics` (SUB,PRV,Query); `UF_In_GetStatistics` (SUB,PRV,Query); `UF_Te_GetStatistics` (SUB,PRV,Query); `UF_Te_Interpolate` (SUB,PRV,—); `MD_Amp_Slot_GetStatistics` (SUB,PRV,Query); `UF_Lo_ComputeEffectiveLoad` (SUB,PRV,Compute); `MD_LoadBC_Algo_Init` (SUB,PRV,Init); `MD_LoadBC_Algo_Reset` (SUB,PRV,Mutate); `MD_LoadBC_Algo_Finalize` (SUB,PRV,Finalize); `MD_LoadBC_Algo_SyncFromStep` (SUB,PRV,Parse); `MD_LoadBC_Algo_SyncFromTree` (SUB,PRV,Parse); `MD_LoadBC_Algo_GetActiveLoadsForStep` (SUB,PRV,Query); `MD_LoadBC_Helper_FindNodeSetId` (FN,PRV,Query); `MD_LoadBC_Helper_FindSurfaceSetId` (FN,PRV,Query); `MD_LoadBC_Helper_FindElementSetId` (FN,PRV,Query); `MD_LoadBC_Algo_GetRegionNodes` (SUB,PRV,Query); `MD_LoadBC_Algo_GetAmplitudeFactor` (SUB,PRV,Query); `MD_LoadBC_Algo_GetDofIndices` (SUB,PRV,Query); `MD_LoadBC_Algo_WriteBack` (SUB,PRV,Parse); `MD_LoadBC_TableAlgo_Init` (SUB,PRV,Init); `MD_LoadBC_TableAlgo_Reset` (SUB,PRV,Mutate); `MD_LoadBC_TableAlgo_Finalize` (SUB,PRV,Finalize); `MD_LoadBC_TableAlgo_SyncFromStep` (SUB,PRV,Parse); `MD_LoadBC_TableAlgo_GetActiveLoadsForStep` (SUB,PRV,Query); `MD_LoadBC_TableAlgo_GetRegionNodes` (SUB,PRV,Query); `MD_LoadBC_TableAlgo_GetAmplitudeFactor` (SUB,PRV,Query); `MD_LoadBC_TableAlgo_WriteBack` (SUB,PRV,Parse); `MD_LoadBC_TableAlgo_ApplyToForce` (SUB,PRV,Parse); `MD_LoadBC_TableAlgo_ApplyConcentratedLoad_Internal` (SUB,PRV,Parse); `MD_LoadBC_TableAlgo_ApplyDistributedLoad_Internal` (SUB,PRV,Parse); `MD_LoadBC_TableAlgo_ApplyBodyForce_Internal` (SUB,PRV,Parse); `MD_LoadBC_Helper_GrowRegionCache` (SUB,PRV,Parse); `MD_LoadBC_Helper_ComputeFaceNormalArea` (SUB,PRV,Compute); `MD_LoadBC_Helper_AddNodalVectorForce` (SUB,PRV,Mutate) |
| `MD_LBC_Brg.f90` | `MD_LBC_Brg` | `UF_BCDef` | `init` (TBP,PRV,—); `set_displacement` (TBP,PRV,—); `set_fixed` (TBP,PRV,—); `set_symmetry` (TBP,PRV,—); `get_value_at_time` (TBP,PRV,—); `print_info` (TBP,PRV,—); `bc_init` (SUB,PRV,Init); `bc_set_displacement` (SUB,PRV,Mutate); `bc_set_fixed` (SUB,PRV,Mutate); `bc_set_symmetry` (SUB,PRV,Mutate); `bc_get_value_at_time` (FN,PRV,Query); `bc_print_info` (SUB,PRV,IO); `cload_init` (SUB,PRV,Init); `cload_set_value` (SUB,PRV,Mutate); `cload_get_value_at_time` (FN,PRV,Query); `cload_print_info` (SUB,PRV,IO); `dload_init` (SUB,PRV,Init); `dload_set_pressure` (SUB,PRV,Mutate); `dload_set_traction` (SUB,PRV,Mutate); `dload_get_value_at_time` (FN,PRV,Query); `dload_print_info` (SUB,PRV,IO); `bforce_init` (SUB,PRV,Init); `bforce_set_gravity` (SUB,PRV,Mutate); `bforce_set_centrifugal` (SUB,PRV,Mutate); `bforce_print_info` (SUB,PRV,IO); `thermal_init` (SUB,PRV,Init); `thermal_set_convection` (SUB,PRV,Mutate); `thermal_set_radiation` (SUB,PRV,Mutate); `thermal_set_flux` (SUB,PRV,Mutate); `thermal_print_info` (SUB,PRV,IO); `manager_init` (SUB,PRV,Init); `manager_add_bc` (SUB,PRV,Mutate); `manager_add_bc_simple` (SUB,PRV,Mutate); `manager_add_cload` (SUB,PRV,Mutate); `manager_add_dload` (SUB,PRV,Mutate); `manager_add_bforce` (SUB,PRV,Mutate); `manager_add_thermal` (SUB,PRV,Mutate); `manager_get_bc` (FN,PRV,Query); `manager_get_cload` (FN,PRV,Query); `manager_deactivate_all` (SUB,PRV,—); `manager_print_summary` (SUB,PRV,IO); `manager_destroy` (SUB,PRV,Finalize) |
| `MD_LBC_Domain.f90` | `MD_LBC_Domain` | `MD_LBC_Algo`, `MD_LBC_Ctx`, `MD_Load_Desc`, `MD_Load_State`, `MD_BC_Desc`, `MD_BC_State`, `MD_IC_Desc`, `MD_LBC_GetSummary_Arg`, `MD_LoadBC_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `AddLoad` (TBP,PRV,—); `AddBC` (TBP,PRV,—); `AddInitialCondition` (TBP,PRV,—); `GetLoadsForStep` (TBP,PRV,—); `GetBCsForStep` (TBP,PRV,—); `GetLoad` (TBP,PRV,—); `GetBC` (TBP,PRV,—); `GetInitialCondition` (TBP,PRV,—); `GetICsByType` (TBP,PRV,—); `GetLoadByName` (TBP,PRV,—); `GetBCByName` (TBP,PRV,—); `WriteBack` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `MD_LoadBC_Init` (SUB,PRV,Init); `MD_LoadBC_Finalize` (SUB,PRV,Finalize); `MD_LoadBC_Domain_AddBC` (SUB,PRV,Mutate); `MD_LoadBC_Domain_AddLoad` (SUB,PRV,Mutate); `MD_LoadBC_Domain_AddInitialCondition` (SUB,PRV,Mutate); `MD_LoadBC_Domain_GetLoadsForStep` (SUB,PRV,Query); `MD_LoadBC_Domain_GetBCsForStep` (SUB,PRV,Query); `MD_LoadBC_Domain_GetLoad` (SUB,PRV,Query); `MD_LoadBC_Domain_GetBC` (SUB,PRV,Query); `MD_LoadBC_Domain_GetInitialCondition` (SUB,PRV,Query); `MD_LoadBC_Domain_GetICsByType` (SUB,PRV,Query); `MD_LoadBC_Domain_GetLoadByName` (SUB,PRV,Query); `MD_LoadBC_Domain_GetBCByName` (SUB,PRV,Query); `MD_LoadBC_WriteBack` (SUB,PRV,Parse); `MD_LoadBC_GetSummary` (SUB,PRV,Query) |
| `MD_LBC_Idx.f90` | `MD_LBC_Idx` | — | `MD_LoadBC_Idx_Bind` (SUB,PUB,Parse); `MD_LoadBC_Idx_Reset` (SUB,PUB,Mutate); `idx_dom_ok` (FN,PRV,—); `MD_LoadBC_GetLoadsForStep_Idx` (SUB,PUB,Query); `MD_LoadBC_GetBCsForStep_Idx` (SUB,PUB,Query); `MD_LoadBC_GetBC_Idx` (SUB,PUB,Query); `MD_LoadBC_GetLoad_Idx` (SUB,PUB,Query); `MD_LoadBC_GetLoadByName_Idx` (SUB,PUB,Query); `MD_LoadBC_GetBCByName_Idx` (SUB,PUB,Query) |
| `MD_Load_Def.f90` | `MD_Load_Def` | `MD_Load_Base_Desc` | `Init` (TBP,PRV,—); `Reset` (TBP,PRV,—); `Load_Desc_Init` (SUB,PRV,Init); `Load_Desc_Reset` (SUB,PRV,Mutate) |
