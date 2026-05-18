# Mesh域合同卡 (L3_MD/Element/Mesh)

**Layer**: L3_MD (模型数据层)  
**Domain**: Mesh (节点、单元、DOF、面)  
**Version**: v2.1  
**Updated**: 2026-04-30  
**Status**: ✅ 扩充完成

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 一、职责边界

### 核心职责
- **定位**: UFC L3_MD层Mesh域,网格拓扑与元数据Desc真相源
- **职责**: 节点管理、单元实例、单元族、DOF管理、面定义、全局编号
- **边界**: 仅提供网格拓扑与元数据;形函数/单元刚度积分由L4 Element处理
- **依赖**: L3_MD/Part(部件), L3_MD/Assembly(装配体), L3_MD/Model(模型树)

### 对齐规范
> **L3网格拓扑真相源**: 对齐`UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md`一附.5.1(2);形函数/Ke在L4 Element

---

## 二、文件清单 (18个核心文件)

### 核心文件
| 文件 | 行数 | 职责 |
|------|------|------|
| MD_Elem_Core.f90 | ~178KB | Element Core实现 |
| MD_Mesh_Core.f90 | ~152KB | Mesh Core实现 |
| MD_DOF_Core.f90 | ~65KB | DOF Core实现 |
| MD_Mesh_Domain_Core.f90 | ~38KB | Domain容器 |
| MD_Node.f90 | ~27KB | Node类型(待验证是否与MD_Mesh_Node重复) |
| MD_Mesh_Data.f90 | ~18KB | MeshData DTO |
| MD_Mesh_GlobalNum.f90 | ~17KB | 全局编号管理 |
| MD_DOF_Mgr.f90 | ~14KB | DOF Manager(被Model使用) |
| MD_Mesh_Elem.f90 | ~11KB | Element API |
| MD_Elem_Inp_Map.f90 | ~10KB | INP映射表 |
| MD_Mesh_Sync.f90 | ~8KB | Legacy→Domain同步 |
| MD_Mesh_Node.f90 | ~8KB | Node API |
| MD_Mesh_API.f90 | ~7KB | API封装层(部分使用) |
| MD_Elem_Types.f90 | ~6KB | Elem类型定义 |
| MD_Elem_Family.f90 | ~4KB | Elem族映射(L4使用) |
| MD_Mesh_Mgr.f90 | ~4KB | Mesh Manager(广泛使用) |
| MD_Mesh_Types.f90 | ~2KB | Mesh类型定义 |

### 已删除模块
- ~~`MD_Mesh_Util.f90`~~ - 零调用的工具模块(31KB)
- ~~`MD_Field_Mgr_API.f90`~~ - 零调用的FieldState API(4KB)
- ~~`MD_DOF_API.f90`~~ - 零调用的DOF API(3KB)

---

## 三、四类TYPE映射

| Type种类 | TYPE名称 | 核心职责 | 字段示例 |
|----------|----------|----------|----------|
| **Desc** | MD_Mesh_NodeDesc | 节点描述符 | node_id, coords(3) |
| **Desc** | MD_Mesh_ElemDesc | 单元描述符 | elem_id, node_conn(:), elem_type |
| **Desc** | MD_Mesh_FaceDesc | 面描述符 | face_id, elem_id, face_nodes(:) |
| **Desc** | MD_DOF_Desc | DOF描述符 | dof_id, node_id, dof_idx | **PLANNED** — 待 `MD_DOF_Core` 重构后引入 |
| **State** | MD_Mesh_State | 网格运行时状态 | n_nodes, n_elems, n_dofs |
| **Algo** | 无B矩阵/高斯积分 | - | - |
| **Ctx** | 无 | - | - |

---

## 四、四链映射

| 链 | 映射说明 |
|---|----------|
| **理论链** | 网格拓扑→节点坐标→单元连接→L4形函数 |
| **逻辑链** | Mesh↔Element(L4)↔Assembly闭环 |
| **计算链** | 无(L3仅管理拓扑,不执行计算) |
| **数据链** | INP→MD_Mesh_NodeDesc/MD_Mesh_ElemDesc→L4 Populate |

---

## 五、Populate/Asm消费字段(MeshData/raw_data)

### 关键字段契约
| 字段 | 含义 | L3典型写入方 | L4/L5消费方 |
|------|------|---------------|--------------|
| **`element_types(:)`** | 每单元`ELEM_*`整型码 | INP:`MD_ELEM_MAPABQTYPESTRING`;Legacy同步:`MD_Mesh_SyncFromLegacy` | **L4**`PH_L4_Populate_Element`→`elem_type_cache`;**L5**`RT_Asm_Solv`回退读`raw_data%element_types` |
| **`elem_section_ref(:)`** | 单元→截面在`section_db`中的1-based索引 | `Mesh_Sync_PopulateElemSectionRef`(elset_name匹配) | **L4**`PH_L4_Populate_Element`:`sect_idx`→`section%desc_array(sect_idx)%material_ref`→`elem_to_mat_map` |
| **`element_connect`/`node_coords`** | 拓扑与几何 | `MD_Mesh_Sync`/`MeshData%Set*` | **L4 Populate**填`elem_coords_cache`/`elem_npe_cache`;**L5**组装与dofMap |

---

## 六、核心接口清单

### 节点管理
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Mesh_AddNode | 添加节点 | node_desc, node_id, status |
| MD_Mesh_GetNode | 查询节点 | node_id, node_desc, status |
| MD_Mesh_GetNodeCount | 获取节点总数 | count |

### 单元管理
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Mesh_AddElem | 添加单元 | elem_desc, elem_id, status |
| MD_Mesh_GetElem | 查询单元 | elem_id, elem_desc, status |
| MD_Mesh_GetElemCount | 获取单元总数 | count |

### DOF管理
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_DOF_Allocate | 分配DOF | n_dofs, status |
| MD_DOF_Map | DOF映射 | node_id, dof_idx, global_dof_id |
| MD_DOF_GetTotalCount | 获取总DOF数 | count |

---

## 七、依赖关系

### 向上依赖(被谁使用)
- L4/Element: 单元刚度积分(通过Populate)
- L5/Assembly: 组装与dofMap
- L3_MD/Model: 模型树管理

### 向下依赖(依赖谁)
- L3_MD/Part: 部件实例
- L3_MD/Assembly: 装配体引用

---

## 八、Bridge接口

### L3→L4 Bridge
| 接口 | 功能 | 说明 |
|------|------|------|
| MD_Elem_PH_Brg | L3→L4桥接 | 单元数据传递 |

### L3→L5 Bridge
| 接口 | 功能 | 说明 |
|------|------|------|
| MD_Elem_RT_Brg | L3→L5桥接 | 单元运行时数据 |
| MD_Mesh_Brg (RT_Mesh_Brg) | 网格ID映射桥 | 文件名与MODULE名不一致,见Bridge/BRIDGE_INDEX.md |

---

## 九、热路径规范

- **热路径**: 否(步内拓扑只读;Populate缓存)
- **冷路径**: Populate期一次性写入
- **步内**: 仅读取,不修改

---

## 十、清单入口

详见: `PLAN/inventory_by_domain/inventory_L3__Mesh.csv`
- `public=Y`优先:`MD_Mesh_*_Idx`、`MD_Mesh_SyncFromLegacy`、`MD_ELEM_MAPABQTYPESTRING`、`ElemTypeToFamily`等

---

## 十一、测试策略

### 单元级测试
- 节点注册: 验证node_id唯一性
- 单元注册: 验证elem_id唯一性
- DOF分配: 验证全局DOF编号连续性

### 集成级测试
- Mesh↔Element: 单元连接正确性
- Mesh↔L4_PH: Populate数据传递

---

## 十二、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 早期 | 初始简版合同卡(63行) |
| v2.0 | 2026-04-17 | 扩充为标准格式,200+行 |
| v2.1 | 2026-04-25 | Phase 2 补齐: 错误处理/域际关系/约束分级/十件套映射 |

---

## 十三、错误处理

| 错误场景 | 错误码 | 处理方式 |
|----------|--------|----------|
| 节点 ID 不存在 | `IF_STATUS_INVALID` | 返回 status |
| 单元连接无效（npe≤0） | `IF_STATUS_INVALID` | 返回 status |
| DOF 越界 | `IF_STATUS_INVALID` | 返回 status |
| Sync 数据不一致 | `IF_STATUS_ERROR` | 返回 status |

所有公开过程通过 `ErrorStatusType` 返回状态。不使用 `STOP`。

---

## 十四、域际关系

| 序号 | 关联域 | 相对本域 | 契约类型 | 主要接触面 | 备注 |
|------|--------|----------|----------|------------|------|
| R1 | L3_MD/Part | 上游 | U | Part 持有节点/单元实例 | |
| R2 | L3_MD/Section | 上游 | U | Section 通过 elset 引用 Element | elem_section_ref |
| R3 | L3_MD/Material | 上游 | U | 间接（通过 Section → Material） | |
| R4 | L4_PH/Element | 下游 | T+B | `MD_Mesh_ElemDesc` → Populate → L4 elem cache | Bridge: `MD_ElemPH_Brg` |
| R5 | L5_RT/Assembly | 下游 | T+B | 拓扑/DOF → L5 dofMap 构建 | Bridge: `MD_Mesh_Brg` |
| R6 | L5_RT/Element | 下游 | T+B | 单元连接 → L5 单元循环 | |

---

## 十五、约束分级

| 约束 | 级别 | 说明 |
|------|------|------|
| L3 仅拓扑 Desc，不做形函数/积分 | **硬** | 架构原则 |
| 步内拓扑只读（Populate 缓存） | **硬** | 步内不改写 |
| 不使用 STOP | **硬** | H-ERR-01 |
| Element 子域与 L4_PH 对齐 | **软** | 部分族待补齐 |
| 测试覆盖率 | **软** | 待建 |

---

## 十六、十件套 v2.0 映射

| 序号 | 逻辑件 | 物理落地 | 状态 |
|------|--------|----------|------|
| 1 | Contract | `CONTRACT.md`（本文件）+ `Element/CONTRACT.md` | Active |
| 2 | Definition | `MD_Mesh_Def.f90`, `Element/Elem/MD_Elem_Def.f90`（域柱四型）, `Element/Elem/MD_Elem_UEL_Def.f90`（UEL 桥接 bundle） | Active |
| 3 | Desc | TYPE `MD_Mesh_NodeDesc`, `MD_Mesh_ElemDesc` 等 | Active |
| 4 | State | TYPE `MD_Mesh_State` | Active |
| 5 | Algo | 无（L3 拓扑域无算法参数） | N/A |
| 6 | Ctx | 无 | N/A |
| 7 | Main/Kernel | `MD_Mesh.f90`, `MD_Elem.f90`, `MD_DOF.f90` | Active |
| 8 | Bridge | `MD_Mesh_API.f90`, Bridge_L4/`MD_ElemPH_Brg` | Active |
| 9 | Runtime Proc | N/A (L3 域) | N/A |
| 10 | Registry | `MD_Elem_Reg.f90`, `MD_Elem_InpMap.f90` | Active |
| 11 | Populate | `MD_Elem_Populate.f90` | Active |
| 12 | Diagnostics | `MD_Mesh_Domain.f90` 内 Summary | Active（基础） |
| 13 | Test | 待建 `Tests/` | Deferred |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `MD_DOF.f90` | `MD_DOF` | `UF_DOFLabelMapType`, `MD_DOFDesc` | `RegLayout` (TBP,PRV,—); `Ensure` (TBP,PRV,—); `Init` (TBP,PRV,—); `Configure` (TBP,PRV,—); `MD_DOFDesc_Init` (SUB,PRV,Init); `MD_DOFDesc_Configure` (SUB,PRV,—); `MD_DOFDesc_RegLayout` (SUB,PRV,—); `MD_DOFDesc_Ensure` (SUB,PRV,—); `MD_DOFSta_Init` (SUB,PRV,Init); `MD_DOFSta_RegLayout` (SUB,PRV,—); `MD_DOFSta_Ensure` (SUB,PRV,—); `MD_DOFCtx_Init` (SUB,PRV,Init); `MD_DOFCtx_Configure` (SUB,PRV,—); `MD_DOFCtx_RegLayout` (SUB,PRV,—); `MD_DOFCtx_Ensure` (SUB,PRV,—); `MD_NodalDOFDesc_Init` (SUB,PRV,Init); `MD_NodalDOFDesc_Configure` (SUB,PRV,—); `MD_NodalDOFDesc_RegLayout` (SUB,PRV,—); `MD_NodalDOFDesc_Ensure` (SUB,PRV,—); `MD_NodalDOFSta_Init` (SUB,PRV,Init); `MD_NodalDOFSta_RegLayout` (SUB,PRV,—); `MD_NodalDOFSta_Ensure` (SUB,PRV,—); `MD_NodalDOF_Setup` (SUB,PRV,Init); `Activate` (SUB,PRV,—); `Fix` (SUB,PRV,—); `Prescribe` (SUB,PRV,—); `GetEqn` (FN,PRV,—); `IsFree` (FN,PRV,—); `GetStatus` (FN,PRV,—); `GetPrescribedValue` (FN,PRV,—); `GetReaction` (FN,PRV,—); `SetReaction` (SUB,PRV,—); `MD_DOF_Setup` (SUB,PRV,Init); `MD_DOF_Free` (SUB,PRV,Finalize); `ActivateDOFs` (SUB,PRV,—); `FixDOF` (SUB,PRV,—); `PrescribeDOF` (SUB,PRV,—); `NumberEquations` (SUB,PRV,—); `GetNodalDOF` (FN,PRV,—); `GetElementDOFs` (SUB,PRV,—); `AssembleVector` (SUB,PRV,—); `ScatterSolution` (SUB,PRV,—); `GetDisplacement` (FN,PRV,—); `SetDisplacement` (SUB,PRV,—); `GetVelocity` (FN,PRV,—); `SetVelocity` (SUB,PRV,—); `GetAcceleration` (FN,PRV,—); `SetAcceleration` (SUB,PRV,—); `GetDOFValue` (FN,PRV,—); `SetDOFValue` (SUB,PRV,—); `GetDOFStatus` (FN,PRV,—); `MD_DOFMap_Init` (SUB,PRV,Init); `MD_DOFMap_Free` (SUB,PRV,Finalize); `SetNdof` (SUB,PRV,—); `MakeEq` (SUB,PRV,—); `GetEq` (FN,PRV,—); `NodeRng` (SUB,PRV,—); `NEq` (FN,PRV,—); `InitLabelMap` (SUB,PRV,—); `RegisterLabel` (SUB,PRV,—); `GetSlotFromLabel` (SUB,PRV,—); `GetLabelFromSlot` (SUB,PRV,—); `HasLabel` (FN,PRV,—); `GetNumLabels` (FN,PRV,—); `ActivateByLabel` (SUB,PRV,—); `FixByLabel` (SUB,PRV,—); `PrescribeByLabel` (SUB,PRV,—); `GetEqnByLabel` (FN,PRV,—); `IsFreeByLabel` (FN,PRV,—); `GetDOFValueByLabel` (FN,PRV,—); `SetDOFValueByLabel` (SUB,PRV,—); `UF_DOFLabelMap_Init` (SUB,PUB,Init); `UF_DOFLabelMap_Register` (SUB,PUB,—); `UF_DOFLabelMap_GetSlot` (SUB,PUB,Query); `UF_DOFLabelMap_GetLabel` (SUB,PUB,Query) |
| `MD_DOF_Mgr.f90` | `MD_DOFMgr` | `UF_NodalDOF` | `init` (TBP,PRV,—); `activate` (TBP,PRV,—); `fix` (TBP,PRV,—); `prescribe` (TBP,PRV,—); `get_eqn` (TBP,PRV,—); `is_free` (TBP,PRV,Finalize); `ndof_init` (SUB,PRV,Init); `ndof_activate` (SUB,PRV,—); `ndof_fix` (SUB,PRV,—); `ndof_prescribe` (SUB,PRV,—); `ndof_get_eqn` (FN,PRV,Query); `ndof_is_free` (FN,PRV,Finalize); `dofmgr_init` (SUB,PRV,Init); `dofmgr_activate_dofs` (SUB,PRV,—); `dofmgr_fix_dof` (SUB,PRV,—); `dofmgr_prescribe_dof` (SUB,PRV,—); `dofmgr_number_eqns` (SUB,PRV,—); `dofmgr_get_nodal` (FN,PRV,Query); `dofmgr_get_elem_dofs` (SUB,PRV,Query); `dofmgr_assemble_vec` (SUB,PRV,—); `dofmgr_scatter` (SUB,PRV,—); `dofmgr_print_summary` (SUB,PRV,IO); `dofmgr_destroy` (SUB,PRV,Finalize) |
| `MD_Elem.f90` | `MD_Elem` | `ElemType` | `RegLayout` (TBP,PRV,—); `Ensure` (TBP,PRV,—); `Init` (TBP,PRV,—); `UF_Struct_IpKernel` (SUB,PRV,—); `UF_ElementType_FillById` (SUB,PUB,Populate); `UF_ElementType_FromId` (FN,PUB,—); `ElemType_Init_Structured` (SUB,PUB,Init); `ElemType_Init_Base` (SUB,PRV,Init); `ElemType_Init` (SUB,PRV,Init); `ElemType_RegLayout` (SUB,PRV,—); `ElemType_Ensure` (SUB,PRV,—); `ElemFormul_Init_Base` (SUB,PRV,Init); `ElemFormul_Init` (SUB,PRV,Init); `ElemFormul_RegLayout` (SUB,PRV,—); `ElemFormul_Ensure` (SUB,PRV,—); `ElemCtx_Init` (SUB,PRV,Init); `ElemCtx_RegLayout` (SUB,PRV,—); `ElemCtx_Ensure` (SUB,PRV,—); `ElemState_RegLayout` (SUB,PRV,—); `ElemState_Ensure` (SUB,PRV,—); `ElemState_Init` (SUB,PRV,Init); `ShapeFuncResult_Init` (SUB,PRV,Init); `ShapeFuncResult_Clear` (SUB,PRV,Mutate); `UF_Elem_PrepareStructStorage` (SUB,PUB,—); `UF_El_PrepareIntPointStates` (SUB,PRV,—); `ElementMetadata_Init` (SUB,PRV,Init); `Element_FromDesc_Metadata` (SUB,PUB,—); `ElementMetadata_Clean` (SUB,PRV,—); `ElementMetadata_Valid` (SUB,PRV,Validate); `ElementMetadata_GetFamilyName` (FN,PRV,Query); `ElementCatalog_Init` (SUB,PRV,Init); `ElementCatalog_Clean` (SUB,PRV,—); `ElementCatalog_RegElement` (SUB,PRV,—); `ElementCatalog_GetElement` (SUB,PRV,Query); `ElementCatalog_FindElement` (SUB,PRV,Query); `ElementCatalog_ListElements` (SUB,PRV,—); `El_GetElementsByFamily` (SUB,PRV,Query); `ElementCatalog_InitDefaults` (SUB,PRV,Init); `ElementDispatcher_Init` (SUB,PRV,Init); `ElementDispatcher_Clean` (SUB,PRV,—); `ElementDispatcher_Dispatch` (SUB,PRV,—); `El_GetElementInfo` (SUB,PRV,Query); `El_ValidElement` (SUB,PRV,Validate); `ElementAdapter_Init` (SUB,PRV,Init); `ElementAdapter_Clean` (SUB,PRV,—); `ElementAdapter_Adapt` (SUB,PRV,Bridge); `ElementAdapter_Valid` (SUB,PRV,Validate); `UserElement_Init` (SUB,PRV,Init); `UserElement_Clean` (SUB,PRV,—); `UserElement_Load` (SUB,PRV,Parse); `UserElement_Valid` (SUB,PRV,Validate); `UserElement_GetMetadata` (SUB,PRV,Query); `ElementManager_Init` (SUB,PRV,Init); `ElementManager_Clean` (SUB,PRV,—); `ElementMgr_RegElement` (SUB,PRV,—); `ElementMgr_RegUserElement` (SUB,PRV,—); `ElementMgr_GetElementInfo` (SUB,PRV,Query); `ElementManager_ListElements` (SUB,PRV,—); `ElementManager_Dispatch` (SUB,PRV,—); `ElementManager_Valid` (SUB,PRV,Validate); `UF_El_GetConnectivity` (SUB,PRV,Query); `UF_GetFaceNormal` (SUB,PUB,Query); `UF_ApplyFacePressure` (SUB,PUB,—); `UF_ApplyFaceTraction` (SUB,PUB,—); `UF_ApplyEdgeLoad` (SUB,PUB,—); `UF_Ad_El_To_State` (SUB,PRV,—); `UF_Adapt_ElementType_To_Desc` (SUB,PUB,Bridge); `UF_Struct_GaussKernel` (SUB,PUB,—); `UF_Be_EulerBernoulli` (SUB,PRV,—); `DispatchCompute` (SUB,PUB,—); `DispatchFromType` (SUB,PUB,—); `UF_Ki_So_FromContxt` (SUB,PRV,—); `UF_Init_UserElement` (SUB,PUB,Init); `Calc_UserElement` (SUB,PUB,—); `MD_Element_Init_Base` (SUB,PRV,Init); `MD_Element_Init` (SUB,PRV,Init); `MD_Element_Clean` (SUB,PRV,—); `MD_Element_GetConnectivity` (SUB,PRV,Query); `MD_Element_SetConnectivity` (SUB,PRV,Mutate); `MD_Element_GetSection` (SUB,PRV,Query); `MD_Element_SetSection` (SUB,PRV,Mutate); `MD_Element_GetVolume_Func` (FN,PRV,Query); `MD_Element_GetArea_Func` (FN,PRV,Query); `MD_Element_ComputeJacobian` (SUB,PRV,Compute); `MD_Element_GetQuality` (SUB,PRV,Query); `MD_Element_AddIntegrationPoint` (SUB,PRV,Mutate); `MD_Element_GetIntegrationPoint` (SUB,PRV,Query); `MD_Element_AddNeighbor` (SUB,PRV,Mutate); `MD_Element_RemoveNeighbor` (SUB,PRV,Mutate); `MD_Element_AddTag` (SUB,PRV,Mutate); `MD_Element_HasTag` (FN,PRV,Query); `MD_Element_Valid` (FN,PRV,Validate); `MD_Element_GetStatistics` (SUB,PRV,Query); `MD_Elem_Create` (SUB,PUB,Init); `MD_Elem_Destroy` (SUB,PUB,Finalize); `MD_Elem_SetConnectivity` (SUB,PUB,Mutate); `MD_Elem_GetConnectivity` (SUB,PUB,Query); `MD_Elem_SetSection` (SUB,PUB,Mutate); `MD_Elem_GetSection` (SUB,PUB,Query); `MD_Element_GetVolume` (FN,PUB,Query); `MD_Element_GetArea` (FN,PUB,Query); `MD_Elem_ComputeJacobian` (SUB,PUB,Compute); `MD_Elem_GetQuality` (SUB,PUB,Query); `MD_Elem_GetStatistics` (SUB,PUB,Query); `MD_Elem_Valid` (SUB,PUB,Validate); `MD_ElementState_Init` (SUB,PRV,Init); `MD_ElementState_Clean` (SUB,PRV,—); `MD_ElementState_Update` (SUB,PRV,Compute); `MD_ElementState_GetStrainEnergy` (FN,PRV,Query); `MD_ElementState_SetStrainEnergy` (SUB,PRV,Mutate) |
| `Element/Elem/MD_Elem_Family.f90` | `MD_Elem_Family` | — | `ElemTypeToFamily` (FN,PUB,—) |
| `Element/Elem/MD_Elem_InpMap.f90` | `MD_Elem_InpMap` | — | `MD_Elem_MapAbqTypeString` (SUB,PUB,Populate) |
| `Element/Elem/MD_Elem_Def.f90` | `MD_Elem_Def` | `MD_Elem_Base_Desc` / `MD_Elem_Base_Algo` / `MD_Elem_Base_Ctx` / `MD_Elem_Base_State` + 族 Desc | 域柱注册真源（与 L4 `PH_Elem_*` 对齐） |
| `Element/Elem/MD_Elem_UEL_Def.f90` | `MD_Elem_UEL_Def` | `MD_Elem_UEL_Desc` | `Init` / `Reset` (TBP); `UEL_Elem_Desc_Init` / `UEL_Elem_Desc_Reset` — UEL 调用参数 bundle，**不得**与 `MD_Elem_Base_Desc` 同名混用 |
| `MD_Mesh.f90` | `MD_Mesh` | `NodeGlobalMapEntry`, `ElemGlobalMapEntry`, `MeshGlobalNum`, `GeoRegionDesc` | `RegLayout` (TBP,PRV,—); `Ensure` (TBP,PRV,—); `Init` (TBP,PRV,—); `MeshDesc_Init` (SUB,PRV,Init); `MeshDesc_RegLayout` (SUB,PRV,—); `MeshDesc_Ensure` (SUB,PRV,—); `MeshState_Init` (SUB,PRV,Init); `MeshState_RegLayout` (SUB,PRV,—); `MeshState_Ensure` (SUB,PRV,—); `MeshCtx_Init` (SUB,PRV,Init); `MeshCtx_RegLayout` (SUB,PRV,—); `MeshCtx_Ensure` (SUB,PRV,—); `MeshNodeDesc_Init` (SUB,PRV,Init); `MeshNodeDesc_RegLayout` (SUB,PRV,—); `MeshNodeDesc_Ensure` (SUB,PRV,—); `MeshElemDesc_Init` (SUB,PRV,Init); `MeshElemDesc_RegLayout` (SUB,PRV,—); `MeshElemDesc_Ensure` (SUB,PRV,—); `MeshNodeState_Init` (SUB,PRV,Init); `MeshNodeState_RegLayout` (SUB,PRV,—); `MeshNodeState_Ensure` (SUB,PRV,—); `MeshElemState_Init` (SUB,PRV,Init); `MeshElemState_RegLayout` (SUB,PRV,—); `MeshElemState_Ensure` (SUB,PRV,—); `GeoRegionDesc_Init` (SUB,PRV,Init); `GeoRegionDesc_RegLayout` (SUB,PRV,—); `GeoRegionDesc_Ensure` (SUB,PRV,—); `GeoCtx_Init` (SUB,PRV,Init); `GeoCtx_RegLayout` (SUB,PRV,—); `GeoCtx_Ensure` (SUB,PRV,—); `Init` (SUB,PRV,—); `Clean` (SUB,PRV,—); `GetNodeCoords` (SUB,PRV,—); `SetNodeCoords` (SUB,PRV,—); `GetElementConnectivity` (SUB,PRV,—); `SetElementConnectivity` (SUB,PRV,—); `GetElementNodes` (SUB,PRV,—); `Valid` (SUB,PRV,—); `GlobalNum_Build` (SUB,PUB,Populate); `GlobalNum_GetDofIndices` (SUB,PUB,Query); `find_part_index` (FN,PRV,—); `FindGlobalNodeIdForInstance` (FN,PRV,—); `ModelTreeNode_Init` (SUB,PRV,Init); `ModelTreeNode_Destroy` (SUB,PRV,Finalize); `ModelTreeNode_AddChild` (SUB,PRV,Mutate); `ModelTreeNode_RemoveChild` (SUB,PRV,Mutate); `ModelTreeNode_GetChildren` (FN,PRV,Query); `ModelTreeNode_HasChildren` (FN,PRV,Query); `ModelTree_Init` (SUB,PRV,Init); `ModelTree_Clean` (SUB,PRV,—); `ModelTree_CreateNode` (FN,PRV,Init); `ModelTree_DeleteNode` (SUB,PRV,Mutate); `ModelTree_FindNode` (SUB,PRV,Query); `ModelTree_FindNodeByName` (SUB,PRV,Query); `ModelTree_GetRoot` (FN,PRV,Query); `ModelTree_GetNode` (FN,PRV,Query); `ModelTree_GetParent` (FN,PRV,Query); `ModelTree_GetChildren` (FN,PRV,Query); `ModelTree_GetPath` (FN,PRV,Query); `ModelTree_Valid` (FN,PRV,Validate); `Topology_Init` (SUB,PRV,Init); `Topology_Clean` (SUB,PRV,—); `Topology_BuildNodeToElements` (SUB,PRV,Populate); `Topology_BuildElementToElements` (SUB,PRV,Populate); `Topology_BuildEdges` (SUB,PRV,Populate); `Topology_BuildFaces` (SUB,PRV,Populate); `Topology_GetNodeElements` (FN,PRV,Query); `Topology_GetElementNeighbors` (FN,PRV,Query); `Topology_GetElementEdges` (FN,PRV,Query); `Topology_GetElementFaces` (FN,PRV,Query); `Topology_Valid` (FN,PRV,Validate); `GeometryManager_Init` (SUB,PRV,Init); `GeometryManager_Clean` (SUB,PRV,—); `GeometryManager_GetModelTree` (FN,PRV,Query); `GeometryMgr_GetGlobalNumbering` (FN,PRV,Query); `GeometryManager_GetTopology` (FN,PRV,Query); `GeometryMgr_BuildGeometry` (SUB,PRV,Populate); `GeometryManager_Valid` (FN,PRV,Validate); `CreateMeshQualityMetrics` (SUB,PRV,—); `MeshQualityMetrics_Init` (SUB,PRV,Init); `CreateMeshQualityMetrics` (SUB,PRV,—); `MeshQualityMetrics_Init` (SUB,PRV,Init); `MeshQualityMetrics_Calc` (SUB,PRV,—); `MeshQualityMetrics_GetQualityReport` (SUB,PRV,Query); `ComputeMeshQuality` (SUB,PRV,—); `CreateMeshGenerator` (SUB,PRV,—); `MeshGenerator_Init` (SUB,PRV,Init); `MeshGenerator_SetDimensions` (SUB,PRV,Mutate); `MeshGenerator_SetElementCounts` (SUB,PRV,Mutate); `MeshGenerator_SetOrigin` (SUB,PRV,Mutate); `MeshGenerator_Generate` (SUB,PRV,—); `GenerateStructuredMesh` (SUB,PRV,—); `GenerateUnstructuredMesh` (SUB,PRV,—); `CreateMeshRefinement` (SUB,PRV,—); `MeshRefinement_Init` (SUB,PRV,Init); `MeshRefinement_SetRefinementLevel` (SUB,PRV,Mutate); `MeshRefinement_SetRefinementRatio` (SUB,PRV,Mutate); `MeshRefinement_MarkElementsForRefinement` (SUB,PRV,—); `MeshRefinement_Refine` (SUB,PRV,—); `RefineMeshUniform` (SUB,PRV,—); `RefineMeshAdaptive` (SUB,PRV,—); `CreateMeshSmoothing` (SUB,PRV,—); `MeshSmoothing_Init` (SUB,PRV,Init); `MeshSmoothing_SetSmoothingParameters` (SUB,PRV,Mutate); `MeshSmoothing_SetFixedNodes` (SUB,PRV,Mutate); `MeshSmoothing_Smooth` (SUB,PRV,—); `SmoothMeshLaplacian` (SUB,PRV,—); `SmoothMeshOptimization` (SUB,PRV,—); `CreateMeshConnectivity` (SUB,PRV,—); `MeshConnectivity_Init` (SUB,PRV,Init); `MeshConnectivity_ComputeElementNeighbors` (SUB,PRV,Compute); `MeshConnectivity_ComputeElementFaces` (SUB,PRV,Compute); `MeshConnectivity_ComputeElementEdges` (SUB,PRV,Compute); `MeshConnectivity_ComputeNodeElements` (SUB,PRV,Compute); `MeshConnectivity_ComputeNodeNeighbors` (SUB,PRV,Compute); `MeshConnectivity_GetNeighborElements` (SUB,PRV,Query); `MeshConnectivity_GetNeighborNodes` (SUB,PRV,Query); `FindElementNeighbors` (SUB,PRV,—); `FindElementFaces` (SUB,PRV,—); `FindElementEdges` (SUB,PRV,—); `CreateMeshGeometry` (SUB,PRV,—); `MeshGeometry_Init` (SUB,PRV,Init); `MeshGeometry_ComputeBoundingBox` (SUB,PRV,Compute); `MeshGeometry_ComputeVolume` (SUB,PRV,Compute); `MeshGeometry_ComputeSurfArea` (SUB,PRV,Compute); `MeshGeometry_ComputeCentroid` (SUB,PRV,Compute); `MeshGeometry_ComputeEdgeLengths` (SUB,PRV,Compute); `MeshGeometry_GetGeometryReport` (SUB,PRV,Query); `ComputeMeshBoundingBox` (SUB,PRV,—); `ComputeMeshVolume` (SUB,PRV,—); `ComputeMeshSurfaceArea` (SUB,PRV,—); `CreateMeshTransform` (SUB,PRV,—); `MeshTransform_Init` (SUB,PRV,Init); `MeshTransform_SetScale` (SUB,PRV,Mutate); `MeshTransform_SetRotation` (SUB,PRV,Mutate); `MeshTransform_SetTranslation` (SUB,PRV,Mutate); `MeshTransform_ComputeRotationMat` (SUB,PRV,Compute); `MeshTransform_ApplyScale` (SUB,PRV,—); `MeshTransform_ApplyRotation` (SUB,PRV,—); `MeshTransform_ApplyTranslation` (SUB,PRV,—); `MeshTransform_ApplyTransform` (SUB,PRV,—); `TransformMeshScale` (SUB,PRV,—); `TransformMeshRotate` (SUB,PRV,—); `TransformMeshTranslate` (SUB,PRV,—); `CreateMeshIO` (SUB,PRV,—); `MeshIO_Init` (SUB,PRV,Init); `MeshIO_SetInputFile` (SUB,PRV,Mutate); `MeshIO_SetOutputFile` (SUB,PRV,Mutate); `MeshIO_SetFileFormat` (SUB,PRV,Mutate); `MeshIO_ExportMesh` (SUB,PRV,—); `MeshIO_ImportMesh` (SUB,PRV,Parse); `ExportMeshToVTK` (SUB,PRV,—); `ImportMeshFromVTK` (SUB,PRV,—); `GenerateMeshReport` (SUB,PRV,—); `RefineMeshAdaptive_H` (SUB,PUB,—); `RefineMeshAdaptive_P` (SUB,PUB,—); `RefineMeshAdaptive_HP` (SUB,PUB,—); `EstimateMeshError` (SUB,PUB,—); `OptimizeMeshQuality` (SUB,PUB,—); `Calc_adaptive_efficiencies` (SUB,PRV,Bridge); `perform_mesh_h_refinement` (SUB,PRV,—); `refine_single_Elem` (SUB,PRV,—); `refine_hexahedral_Elem` (SUB,PRV,—); `create_edge_midpoint` (FN,PRV,—); `create_face_center` (FN,PRV,—); `create_Elem_center` (FN,PRV,—); `refine_quadrilateral_Elem` (SUB,PRV,—); `perform_selective_h_refinement` (SUB,PRV,—); `Calc_Elem_gradient` (SUB,PRV,—); `Solv_small_system` (SUB,PRV,—); `error_estimation_zz` (SUB,PRV,—); `error_estimation_spr` (SUB,PRV,—); `error_estimation_residual` (SUB,PRV,—); `error_estimation_goal` (SUB,PRV,—); `Opt_laplacian_smoothing` (SUB,PRV,—); `Opt_Opt_based` (SUB,PRV,—); `estimate_Elem_size` (FN,PRV,—); `count_Elem_nodes` (FN,PRV,—) |
| `MD_Mesh_Data.f90` | `MD_MeshData` | `MeshData` | `Init` (TBP,PRV,—); `Clean` (TBP,PRV,—); `GetNodeCoords` (TBP,PRV,—); `SetNodeCoords` (TBP,PRV,—); `GetElementConnectivity` (TBP,PRV,—); `SetElementConnectivity` (TBP,PRV,—); `GetElementNodes` (TBP,PRV,—); `Valid` (TBP,PRV,—); `Init` (SUB,PRV,—); `Clean` (SUB,PRV,—); `GetNodeCoords` (SUB,PRV,—); `SetNodeCoords` (SUB,PRV,—); `GetElementConnectivity` (SUB,PRV,—); `SetElementConnectivity` (SUB,PRV,—); `GetElementNodes` (SUB,PRV,—); `Valid` (SUB,PRV,—); `MeshDesc_Init` (SUB,PRV,Init); `MeshDesc_RegLayout` (SUB,PRV,—); `MeshDesc_Ensure` (SUB,PRV,—); `MeshState_Init` (SUB,PRV,Init); `MeshState_RegLayout` (SUB,PRV,—); `MeshState_Ensure` (SUB,PRV,—); `MeshCtx_Init` (SUB,PRV,Init); `MeshCtx_RegLayout` (SUB,PRV,—); `MeshCtx_Ensure` (SUB,PRV,—) |
| `MD_Mesh_Domain.f90` | `MD_MeshDomain` | `MeshAlgo`, `MD_Mesh_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `GetNodeCoords` (TBP,PRV,—); `GetElemConnect` (TBP,PRV,—); `GetElemSection` (TBP,PRV,—); `GetDofMap` (TBP,PRV,—); `GetSurfaceByName` (TBP,PRV,—); `GetNodeByName` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `WriteBack_NodePos` (TBP,PRV,—); `WriteBack_NodeDisp` (TBP,PRV,—); `WriteBack_NodeVel` (TBP,PRV,—); `WriteBack_NodeAcc` (TBP,PRV,—); `WriteBack_ElemStress` (TBP,PRV,—); `WriteBack_State` (TBP,PRV,—); `MD_Mesh_Domain_Finalize` (SUB,PRV,Finalize); `MD_Mesh_Domain_GetDofMap` (SUB,PRV,Query); `MD_Mesh_Domain_GetElemConnect` (SUB,PRV,Query); `MD_Mesh_Domain_GetElemSection` (SUB,PRV,Query); `MD_Mesh_GetElemSection_Idx` (SUB,PUB,Query); `MD_Mesh_Domain_GetNodeCoords` (SUB,PRV,Query); `MD_Mesh_GetNodeCoords_Idx` (SUB,PUB,Query); `MD_Mesh_GetElemConnect_Idx` (SUB,PUB,Query); `MD_Mesh_GetDofMap_Idx` (SUB,PUB,Query); `MD_Mesh_WriteBack_NodePos_Idx` (SUB,PUB,IO); `MD_Mesh_Domain_Init` (SUB,PRV,Init); `MD_Mesh_WriteBack_NodePos` (SUB,PRV,IO); `MD_Mesh_WriteBack_NodeDisp` (SUB,PRV,IO); `MD_Mesh_WriteBack_NodeVel` (SUB,PRV,IO); `MD_Mesh_WriteBack_NodeAcc` (SUB,PRV,IO); `MD_Mesh_WriteBack_ElemStress_Idx` (SUB,PUB,IO); `MD_Mesh_WriteBack_ElemStress` (SUB,PRV,IO); `MD_Mesh_WriteBack_State` (SUB,PRV,IO); `MD_Mesh_Domain_GetSurfaceByName` (SUB,PRV,Query); `MD_Mesh_GetSurfaceByName_Idx` (SUB,PUB,Query); `MD_Mesh_Domain_GetNodeByName` (SUB,PRV,Query); `MD_Mesh_GetNodeByName_Idx` (SUB,PUB,Query); `MD_Mesh_Domain_GetSummary` (SUB,PRV,Query); `MD_Mesh_GetSummary_Impl` (SUB,PRV,Query) |
| `MD_Mesh_Elem.f90` | `MD_MeshElem` | `IPState` | `RegLayout` (TBP,PRV,—); `Ensure` (TBP,PRV,—); `Init` (TBP,PRV,—); `IPState_Init` (SUB,PRV,Init); `IPState_RegLayout` (SUB,PRV,—); `IPState_Ensure` (SUB,PRV,—); `MeshElemDesc_Init` (SUB,PRV,Init); `MeshElemDesc_RegLayout` (SUB,PRV,—); `MeshElemDesc_Ensure` (SUB,PRV,—); `MeshElemState_Init` (SUB,PRV,Init); `MeshElemState_RegLayout` (SUB,PRV,—); `MeshElemState_Ensure` (SUB,PRV,—) |
| `MD_Mesh_GlobalNum.f90` | `MD_MeshGlobalNum` | `NodeGlobalMapEntry`, `ElemGlobalMapEntry`, `MeshGlobalNum` | `GlobalNum_BuildFromFlat` (SUB,PUB,Populate); `GlobalNum_Build` (SUB,PUB,Populate); `GlobalNum_GetDofIndices` (SUB,PUB,Query); `find_part_index` (FN,PRV,—); `FindGlobalNodeIdForInstance` (FN,PRV,—) |
| `MD_Mesh_Mgr.f90` | `MD_MeshMgr` | `MeshManager` | `Init` (TBP,PRV,—); `Clean` (TBP,PRV,—); `CreateMesh` (TBP,PRV,—); `GetMesh` (TBP,PRV,—); `Valid` (TBP,PRV,—); `Init` (SUB,PRV,—); `Clean` (SUB,PRV,—); `CreateMesh` (SUB,PRV,—); `GetMesh` (SUB,PRV,—); `Valid` (SUB,PRV,—) |
| `MD_Mesh_Node.f90` | `MD_MeshNode` | `MeshNodeDesc` | `RegLayout` (TBP,PRV,—); `Ensure` (TBP,PRV,—); `Init` (TBP,PRV,—); `MeshNodeDesc_Init` (SUB,PRV,Init); `MeshNodeDesc_RegLayout` (SUB,PRV,—); `MeshNodeDesc_Ensure` (SUB,PRV,—); `MeshNodeState_Init` (SUB,PRV,Init); `MeshNodeState_RegLayout` (SUB,PRV,—); `MeshNodeState_Ensure` (SUB,PRV,—) |
| `MD_Mesh_Sync.f90` | `MD_MeshSync` | — | `MD_Mesh_SyncFromLegacy` (SUB,PUB,Populate); `Mesh_Sync_PopulateElemSectionRef` (SUB,PRV,Populate) |
| `MD_Mesh_API.f90` | `MD_Mesh_API` | `Desc_Mesh` | `MD_Mesh_IsAvailable` (FN,PUB,Query); `MD_Mesh_GetNumElements` (FN,PUB,Query); `MD_Mesh_GetNumNodes` (FN,PUB,Query); `MD_Mesh_GetElementConnectivity` (SUB,PUB,Query); `MD_Mesh_GetNodeCoords` (SUB,PUB,Query); `MD_Mesh_GetElementFamily` (FN,PUB,Query); `MD_Mesh_GetElementDimension` (FN,PUB,Query); `Mesh_FromDesc` (SUB,PUB,—); `Mesh_FromDesc_Data` (SUB,PUB,—) |
| `MD_Mesh_Def.f90` | `MD_Mesh_Def` | — | — |
| `MD_Node.f90` | `MD_Node` | `MD_Node_Type` | `Init` (TBP,PRV,—); `Clean` (TBP,PRV,—); `Valid` (TBP,PRV,—); `GetCoords` (TBP,PRV,—); `SetCoords` (TBP,PRV,—); `GetDOF` (TBP,PRV,—); `SetDOF` (TBP,PRV,—); `Transform` (TBP,PRV,—); `GetDistance` (TBP,PRV,—); `GetStatistics` (TBP,PRV,—); `AddElement` (TBP,PRV,—); `RemoveElement` (TBP,PRV,—); `AddTag` (TBP,PRV,—); `HasTag` (TBP,PRV,—); `Node_Init` (SUB,PRV,Init); `Node_Clean` (SUB,PRV,—); `Node_GetCoords` (SUB,PRV,Query); `Node_SetCoords` (SUB,PRV,Mutate); `Node_GetDOF` (SUB,PRV,Query); `Node_SetDOF` (SUB,PRV,Mutate); `Node_Transform` (SUB,PRV,Bridge); `Node_GetDistance` (FN,PRV,Query); `Node_AddElement` (SUB,PRV,Mutate); `Node_RemoveElement` (SUB,PRV,Mutate); `Node_AddTag` (SUB,PRV,Mutate); `Node_HasTag` (FN,PRV,Query); `Node_Valid_Fn` (FN,PRV,Validate); `Node_GetStatistics` (SUB,PRV,Query); `MD_Node_Create` (SUB,PUB,Init); `MD_Node_Destroy` (SUB,PUB,Finalize); `MD_Node_SetCoords` (SUB,PUB,Mutate); `MD_Node_GetCoords` (SUB,PUB,Query); `MD_Node_SetDOF` (SUB,PUB,Mutate); `MD_Node_GetDOF` (SUB,PUB,Query); `MD_Node_Transform` (SUB,PUB,Bridge); `MD_Node_GetDistance` (FN,PUB,Query); `MD_Node_GetStatistics` (SUB,PUB,Query); `MD_Node_Valid` (SUB,PUB,Validate); `NodeState_Init` (SUB,PRV,Init); `NodeState_Clean` (SUB,PRV,—); `NodeState_Update` (SUB,PRV,Compute); `NodeState_GetDisplacement` (SUB,PRV,Query); `NodeState_SetDisplacement` (SUB,PRV,Mutate) |
