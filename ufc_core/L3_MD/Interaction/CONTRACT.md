# Interaction 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Interaction (接触与相互作用定义)  
**Version**: v3.1  
**Updated**: 2026-04-30  
**Status**: ✅ 补全至标准格式

### 报告侧：过程算法叙事（stub / archive）

- **入口（根 stub）**：[`Contact_Procedure_Algorithm.md`](../../../REPORTS/Contact_Procedure_Algorithm.md)；长文：[`archive/Contact_Procedure_Algorithm.md`](../../../REPORTS/archive/Contact_Procedure_Algorithm.md)。
- **Registry**：[Domain Procedure Registry](../../../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md)（与叙事无机器对账；优先级见该 README）。

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### 双名制统一（R-10 域缩规则）

域缩 `Cont`（短）和 `Contact`（长）当前等价并用。遵循命名规范 v2.0：
- **新代码优先 `Cont`**：`MD_Cont_*`, `PH_Cont_*`, `RT_Cont_*` 为推荐域缩
- **`Contact` 保留**：`PH_Contact_*` 用于 ABI 镜像类型（`PH_Contact_Base_Ctx/State` 等用户子程序接口），不做强制改名
- **`Interaction`（L3 长名）**：L3 域目录名 `Interaction/` 不变；模块前缀 `MD_Int_*` 保持不变（`Int` 为旧域缩）
- **域合同行文**：新合同段落优先使用 `Cont`；引用 ABI 类型时用 `Contact` 全称

---

## 1. 域职责定义

### 核心职责（一句话）

UFC L3_MD 层 Interaction 域，接触与相互作用参数的 Desc 真相源（SSOT），为 L4_PH Contact 与 L5_RT Contact 提供接触对定义、摩擦参数、表面定义等冷数据。

### 职责边界

| 做什么 | 不做什么 |
|--------|----------|
| 接触对定义（Contact Pairs）与管理 | 接触牛顿迭代（由 L4_PH Contact 处理） |
| 表面相互作用属性（Surface Interaction Properties） | 罚矩阵组装（由 L5_RT Assembly 处理） |
| 摩擦模型参数管理（Coulomb/Stick-Slip/User） | 接触搜索执行（搜索算法实现在本域但由 L5 调度） |
| 接触算法枚举与配置 | 接触状态演化（由 L4/L5 持有） |
| 连接器定义（Spring/Joint/Dashpot/Bushing） | 接触力学计算（应力/切线由 L4 执行） |
| Legacy→Domain 数据同步 | 接触后处理输出（由 Output 域处理） |
| 接触参数解析（*CONTACT PAIR / *FRICTION 关键字） | |

### 依赖关系

- **同层依赖**: L3_MD/Element/Mesh（表面名解析）、L3_MD/Assembly（装配体引用）、L3_MD/Step（分析步上下文）
- **下层依赖**: L1_IF/Prec_Core（精度）、L1_IF/Err_Brg（错误处理）

---

## 2. 四类 TYPE 清单

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名 | 定义文件 | 核心字段 | 用途 |
|----------|----------|----------|------|
| `MD_Interaction_Desc` | `MD_Int_Def.f90` | `interaction_name`, `interaction_id`, `contact_type`, `slave_surface`, `master_surface`, `contact_pairs(:)`, `surface_interactions(:)`, `friction_models(:)` | 接触相互作用描述符（Write-Once 冷数据） |
| `ContactPairType` | `MD_Int_Def.f90` | `pair_name`, `pair_id`, `slave_surface`, `master_surface`, `contact_type`, `is_active` | 单个接触对定义 |
| `SurfaceInteractionType` | `MD_Int_Def.f90` | `interaction_name`, `interaction_id`, `normal_behavior`, `normal_stiffness`, `tangent_behavior`, `tangent_stiffness` | 表面相互作用属性 |
| `FrictionModelType` | `MD_Int_Def.f90` | `friction_name`, `friction_id`, `model_type`, `static_coeff`, `kinetic_coeff`, `stick_slip_ratio`, `damping_coeff` | 摩擦模型定义 |
| `MD_ContactPairDef` | `MD_Cont_Mgr.f90` | `master_surface`, `slave_surface`, `prop_name`, `formulation`, `adjust` | 接触对定义（Domain 层级） |
| `MD_ContactProperty` | `MD_Cont_Mgr.f90` | `name`, `friction`, `cohesion`, `damping`, `pressure_overclosure` | 接触属性定义 |
| `MD_InterDesc` | `MD_Int_Ctx.f90` | 交互描述综合容器 | 交互描述核心类型 |
| `ContPairDef` | `MD_Int_Types.f90` | `master_surf_id`, `slave_surf_id`, `contact_type`, `enforcement_met`, `penalty_n/t`, `mu_static/kinetic` | 接触对定义（低层级数值算法用） |
| `ContAlgoDesc` | `MD_Int_Types.f90` | `name`, `method`, `frictionModel`, `searchAlgo`, `searchRadius`, `use_stabilization` | 接触算法描述 |
| `UF_ContactAlgoDesc` | `MD_Int_Types.f90` | `name`, `method`, `frictionModel`, `searchAlgo` | 用户接口接触算法描述 |
| `SpringProperties` | `MD_Int_Connector.f90` | `name`, `dof`, `stiffness`, `damping`, `nonlinear` | 弹簧连接器 Desc |
| `JointProperties` | `MD_Int_Connector.f90` | `name`, `jointType`, `rotationStiffness`, `translationStiffness` | 铰接连接器 Desc |
| `DashProperties` | `MD_Int_Connector.f90` | `name`, `dof`, `dampingCoefficient` | 阻尼器连接器 Desc |
| `BushingProperties` | `MD_Int_Connector.f90` | `name`, `stiffness(6)`, `damping(6)` | 衬套连接器 Desc |
| `ConnectorProperties` | `MD_Int_Connector.f90` | `name`, `connectorType`, `sectionName`, `behaviorName`, `numNodes` | 通用连接器 Desc |
| `SurfaceSetType` | `MD_Int_Mapper.f90` | `surface_name`, `surface_id`, `node_indices(:)`, `element_indices(:)` | 表面集定义 |
| `InteractionMappingType` | `MD_Int_Mapper.f90` | `pair_id`, `pair_name` | 接触映射结果 |

### 2.2 State 类型（可变运行时状态）

| TYPE 名 | 定义文件 | 核心字段 | 用途 |
|----------|----------|----------|------|
| `MD_Interaction_State` | `MD_Int_Def.f90` | `is_active`, `contact_status`, `contact_pressure` [WL 1/3], `contact_area`, `slip_distance` [WL 2/3], `total_contact_points` [WL 3/3], `normal_stress(:)`, `tangent_stress(:)`, `slip_rate(:)` | 接触运行时状态（WriteBack 白名单标记） |
| `MD_ContactPairState` | `MD_Cont_Mgr.f90` | `gap`, `normal_force`, `tangent_force`, `isActive`, `contact_state` | 接触对状态（WriteBack 白名单） |
| `ContNode` | `MD_Int_Types.f90` | `global_id`, `state`, `coords(3)`, `gap`, `penetration`, `normal(3)`, `force_n`, `force_t(3)`, `slip`, `lambda` | 接触节点运行时状态 |
| `ContForceRes` | `MD_Int_Types.f90` | `normal_forces(:)`, `tangent_forces(:,:)`, `lagrange_multip(:)`, `nActiveCont`, `total_normal_fo`, `total_friction` | 接触力结果容器 |

### 2.3 Algo 类型（算法配置）

| TYPE 名 | 定义文件 | 核心字段 | 用途 |
|----------|----------|----------|------|
| `MD_Cont_Algo` | `MD_Cont_Mgr.f90` | stp_ctl(`MD_Cont_Stp_Ctl_Algo`) + legacy(`ContAlgo`) | **统一接触算法聚合 (P1 补全)** |
| `MD_Cont_Stp_Ctl_Algo` | `MD_Cont_Aux_Def.f90` | enforcement_method/penalty_normal/tangent/lagrange_tol/max_aug_iter/rho_aug/search_strategy/friction_coeff/tolerance_gap/slip/stabilization | **步级接触算法控制** |
| `MD_Interaction_Algo` | `MD_Int_Def.f90` | `algorithm_type`, `use_penalty`, `penalty_stiffness`, `convergence_tolerance`, `use_friction`, `use_damping`, `damping_factor` | 接触算法参数（可调） |
| `ContAlgoCtrl` | `MD_Int_Types.f90` | `algorithm_type`, `friction_model`, `penalty_stiffne`, `penalty_tangent`, `friction_coeffi`, `tolerance_gap`, `tolerance_slip`, `use_adaptive_pe`, `include_frictio` | 接触算法控制参数 |
| `ContAlgo` | `MD_Cont_Mgr.f90` | `search_radius`, `penalty_factor`, `lagrange_tol`, `max_search_iter` | 域级接触算法配置（legacy，新代码用 `MD_Cont_Algo%stp_ctl`） |

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名 | 定义文件 | 核心字段 | 用途 |
|----------|----------|----------|------|
| `MD_Int_Ctx` | `MD_Int_Def.f90` | `contact_ctx_id`, `contact_dir`, `result_unit`, `result_filename`, `work_array(:,:)` | 接触执行上下文 |
| `ContCtx` | `MD_Cont_Mgr.f90` | 逐对迭代跟踪 | Domain 层级接触上下文（由 L5_RT 内部持有） |
| `ContContext` | `MD_Int_Types.f90` | 接触上下文 | 低层级接触计算上下文 |
| `MD_Interaction_Domain` | `MD_Cont_Mgr.f90` | `pairs(:)`, `props(:)`, `pair_state(:)`, `initialized` | 接触域容器（聚合 Desc/State/Algo/Ctx） |
| `MD_Inter_Mgr` | `MD_Int_Ctx.f90` | Interaction 管理器（CRUD + 一致性校验） | 上层交互管理器 |
| `UF_ContProblem` | `MD_Int_Mgr.f90` | `contact_dim`, `n_surfaces`, `n_pairs`, `surfaces(:)`, `pairs(:)`, `active_pairs(:)` | 接触问题上下文 |
| `HashTableType` | `MD_Hash_Table.f90` | `entries(:)`, `size`, `count` | 字符串→整数哈希表 |

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|----------|-----------|------|
| `MD_Int_Def.f90` | `MD_Int_Def` | _Def | `IsValidContactPair`, `IsValidSurfaceInteraction`, `IsValidFrictionModel`, `Initialize_InteractionDesc`, `AddContactPair` | ✅ 已实现 |
| `MD_Int_Types.f90` | `MD_Int_Types` | _Types | 基础 TYPE/常量/参数定义（`ContNode`, `ContAlgoCtrl`, `ContForceRes`, `ContAlgoDesc` 等），无独立过程 | ✅ 已实现 |
| `MD_Int_Core.f90` | `MD_Int_Core` | _Core | `MD_Interaction_Core_Init`, `Core_Finalize`, `Add_Surface`, `Add_Pair`, `Set_Friction`, `Get_Pair`, `Get_N_Pairs`, `Validate` | ✅ 已实现 |
| `MD_Int_API.f90` | `MD_Int_API` | _API | 薄再导出层，聚合 8 个子模块（Types/Convert/Detect/Enforce/Friction/Stiffness/Query/Manager），保留 149 个 PUBLIC 符号向后兼容 | ✅ 已实现 |
| `MD_Int_Convert.f90` | `MD_Int_Convert` | — | `Cont_UpdateGeometry`, `Cont_ProjectToSurface`, `Cont_ComputeTangents`, `Cont_Geometry_Compute_gap_2d/3d`, `Cont_Geometry_project_point_2d/3d` 等几何/投影/坐标映射（25+ 过程） | ✅ 已实现 |
| `MD_Int_Detect.f90` | `MD_Int_Detect` | — | `Cont_Bucket_grid_init/build/query/cleanup`, `Cont_BVH_tree_build/query/cleanup`, `brute_force_search`, `contact_detect/2d/3d`, `Cont_Search_global_init` 等搜索检测（20+ 过程） | ✅ 已实现 |
| `MD_Int_Enforce.f90` | `MD_Int_Enforce` | — | `Cont_Enforce_penalty`, `Cont_Enforce_augmented_lagrange`, `Cont_Enforce_lagrange_multiplier`, `Cont_Enforce_update_multipliers` | ✅ 已实现 |
| `MD_Int_Friction.f90` | `MD_Int_Friction` | — | `Cont_ApplyFriction`, `Cont_Friction_COULOM`, `Cont_Friction_STICK`, `Cont_Friction_bond_debond`, `Cont_Friction_Compute_force/2d/3d` 等摩擦模型（26 过程） | ✅ 已实现 |
| `MD_Int_Stiffness.f90` | `MD_Int_Stiffness` | — | `contact_add_contact_k`, `contact_add_force`, `contact_Assemble_triplets`, `md_cont_add_stif_contact_to_csr`, `penalty_stif_csr`, `alm_stif_csr` 等刚度/CSR 装配（20 过程） | ✅ 已实现 |
| `MD_Int_Query.f90` | `MD_Int_Query` | _Query | `contact_find_Elem_index`, `contact_find_node_index_in_part`, `UF_Contact_ComputeNormalForce`, `UF_Co_GetContactPressure`, `UF_Co_GetStatistics` 等查询/UF 接口（18 过程） | ✅ 已实现 |
| `MD_Int_Manager.f90` | `MD_Int_Manager` | — | `Cont_Surface_init`, `Cont_Surface_add_nodes`, `contact_init`, `contact_update_geometry`, `contact_Eval_face_gap`, `uinter_call`, `fric_call` 等表面管理/用户回调（15+ 过程） | ✅ 已实现 |
| `MD_Int_Mgr.f90` | `MD_IntMgr` | _Mgr | `contact_Mgr_init`, `contact_add_surface`, `contact_add_pair`, `contact_setup_dof_mapping`, `contact_global_search`, `contact_Assem_csr`, `contact_update_state`, `contact_Mgr_cleanup`（20 过程） | ✅ 已实现 |
| `MD_Cont_Mgr.f90` | `MD_Cont_Mgr` | — | `MD_Interaction_Domain_Init`, `AddPair`, `AddProperty`, `GetPairsForStep`, `GetPair`, `GetProperty`, `WriteBack_State`, `WriteBack_Active`, `ValidateAllRefs`, `Finalize`（28 过程） | ✅ 已实现 |
| `MD_Int_Connector.f90` | `MD_Int_Connector` | — | `Parse_SPRING_Keyword`, `Parse_JOINT_Keyword`, `Parse_DASHPOT_Keyword`, `Parse_BUSHING_Keyword`, `Parse_CONNECTOR_Keyword` 及各 Init/Valid/Clear/Configure（32 过程） | ✅ 已实现 |
| `MD_Int_Ctx.f90` | 多 MODULE (22 个子模块) | _Ctx | `MD_Interaction_Ctx_Core`（Init/Ensure/RegLayout）、`MD_Interaction_Ctx_Mgr`（CRUD）、10 个 `*_Type` 模块（Friction/Clearance/Controls 等属性类型）、11 个 `*_Validate`/`*_Parse` 模块 | ✅ 已实现 |
| `MD_Int_Parser.f90` | `MD_Int_Parser` | _Parser | `MD_Parse_ContactPair`, `MD_Parse_SurfaceInteraction`, `MD_Parse_Friction`, `MD_Parse_InteractionVariables`, `Convert_To_Upper`, `Extract_Parameter_Value` | ✅ 已实现 |
| `MD_Int_Mapper.f90` | `MD_Int_Mapper` | _Mapper | `MD_Validate_ContactPair`, `MD_Validate_SurfaceInteraction`, `MD_Allocate_InteractionArrays`, `MD_Map_InteractionToMesh`, `MD_Build_InteractionMapping`, `MD_Get_SurfaceNodeCount/ElementCount` | ✅ 已实现 |
| `MD_Int_Sync.f90` | `MD_Int_Sync` | _Sync | `MD_Interaction_SyncFromLegacy` | ✅ 已实现 |
| `MD_Hash_Table.f90` | `MD_Hash_Table` | — | `Init_HashTable`, `Destroy_HashTable`, `HashTable_Insert`, `HashTable_Lookup`, `HashTable_Remove`, `HashTable_Clear`, `HashString` | ✅ 已实现 |

> **已删除**: ~~`MD_Interaction_API.f90`~~ — 零调用的 API 封装层(2KB)  
> **已删除**: ~~`L3_MD/Interaction/MD_Int_Brg.f90`~~ — 空 `MODULE MD_Int_Brg` 与 **`L3_MD/Bridge/Bridge_L5/MD_Int_Brg.f90`** 同名冲突；L3 Interaction 域内不保留桥接 `.f90`，金线桥接仅 Bridge_L5。  
> **瘦身评估**: 原 `MD_Int_API.f90` (239KB) 已拆为上表所列 `MD_Int_*` / `MD_Cont_*` 等模块；历史规划中的 `REPORTS/Contact_MD_Int_API_瘦身评估报告.md` **未入库**，以 **本表 + `MD_Int_API.f90` 头注释** 为准。

---

## 4. 对外接口（公开 API）

### 4.1 域级 CRUD 接口（MD_Cont_Mgr / MD_Int_Core）

| 接口 | 功能 | 参数 | 方向 |
|------|------|------|------|
| `MD_Interaction_Domain_Init` | 初始化接触域容器 | `domain [INOUT], status [OUT]` | Init |
| `MD_Interaction_Domain_Finalize` | 释放接触域 | `domain [INOUT], status [OUT]` | Finalize |
| `MD_Interaction_Domain_AddPair` | 添加接触对 | `domain [INOUT], pair_def [IN], status [OUT]` | Mutate |
| `MD_Interaction_Domain_AddProperty` | 添加接触属性 | `domain [INOUT], prop [IN], status [OUT]` | Mutate |
| `MD_Interaction_Domain_GetPair` | 查询接触对 | `domain [IN], pair_id [IN], pair [OUT], status [OUT]` | Query |
| `MD_Interaction_Domain_GetProperty` | 查询接触属性 | `domain [IN], name [IN], prop [OUT], status [OUT]` | Query |
| `MD_Interaction_Domain_GetPairsForStep` | 查询步级接触对 | `domain [IN], step_id [IN], pairs [OUT], status [OUT]` | Query |
| `MD_Interaction_Domain_ValidateAllRefs` | 验证所有引用一致性 | `domain [IN], status [OUT]` | Validate |
| `MD_Interaction_WriteBack_State` | 写回接触状态 | `domain [INOUT], idx [IN], gap/force [IN]` | WriteBack |
| `MD_Interaction_WriteBack_Active` | 写回激活状态 | `domain [INOUT], idx [IN], isActive [IN]` | WriteBack |

### 4.2 四型 Core 接口（MD_Int_Core）

| 接口 | 功能 | 参数 |
|------|------|------|
| `MD_Interaction_Core_Init` | 初始化 Desc+State | `desc [INOUT], state [OUT], status [OUT]` |
| `MD_Interaction_Core_Finalize` | 释放 Desc+State | `desc [INOUT], state [INOUT], status [OUT]` |
| `MD_Interaction_Add_Surface` | 添加表面 | `desc [INOUT], id [IN], name [IN], surface_type [IN], status [OUT]` |
| `MD_Interaction_Add_Pair` | 添加接触对 | `desc [INOUT], pair_id [IN], master_id [IN], slave_id [IN], status [OUT]` |
| `MD_Interaction_Set_Friction` | 设置摩擦 | `desc [INOUT], pair_id [IN], mu [IN], status [OUT]` |
| `MD_Interaction_Get_Pair` | 查询接触对 | `desc [IN], idx [IN], pair [OUT], status [OUT]` |
| `MD_Interaction_Validate` | 验证一致性 | `desc [IN], status [OUT]` |

### 4.3 解析接口（MD_Int_Parser）

| 接口 | 功能 | 参数 |
|------|------|------|
| `MD_Parse_ContactPair` | 解析 *CONTACT PAIR | `line, desc, status` |
| `MD_Parse_SurfaceInteraction` | 解析 *SURFACE INTERACTION | `line, desc, status` |
| `MD_Parse_Friction` | 解析 *FRICTION | `line, desc, status` |
| `MD_Parse_InteractionVariables` | 解析变量 | `line, desc, status` |

### 4.4 映射接口（MD_Int_Mapper）

| 接口 | 功能 | 参数 |
|------|------|------|
| `MD_Map_InteractionToMesh` | 接触定义→网格拓扑映射 | `desc [IN], mesh [IN], mapping [OUT], status [OUT]` |
| `MD_Build_InteractionMapping` | 构建完整映射 | `desc [IN], mesh [IN], mapping [OUT], status [OUT]` |
| `MD_Validate_ContactPair` | 验证接触对有效性 | `pair [IN] → LOGICAL` |
| `MD_Validate_SurfaceInteraction` | 验证相互作用有效性 | `interaction [IN] → LOGICAL` |

### 4.5 接触力学接口（经 MD_Int_API 再导出）

> **注**: 以下 149 个 PUBLIC 符号经 `MD_Int_API` 再导出，分布在 8 个子模块，此处列出核心编排过程：

| 接口 | 子模块 | 功能 |
|------|--------|------|
| `Cont_ApplyPenaltyMethod` | API (orchestrator) | 罚函数法应用 |
| `Cont_ApplyLagrangeMultiplier` | API (orchestrator) | 拉格朗日乘子法应用 |
| `ContForceRes_Init_Structured` | API (orchestrator) | 结构化力结果初始化 |
| `Cont_UpdateGeometry_Structured` | API (orchestrator) | 结构化几何更新 |
| `Cont_ApplyFriction_Structured` | API (orchestrator) | 结构化摩擦应用 |

### 4.6 同步接口（MD_Int_Sync）

| 接口 | 功能 | 参数 |
|------|------|------|
| `MD_Interaction_SyncFromLegacy` | Legacy UF_ModelDef → MD_Interaction_Domain 同步 | `model_def [IN], md_layer [INOUT], status [OUT]` |

---

## 5. 跨层数据流

### 5.1 上游依赖（L2/L1 的什么数据）

| 上游模块 | 消费内容 | 用途 |
|----------|----------|------|
| `IF_Prec_Core` (L1) | `wp`, `i4` 精度参数 | 全域数值精度 |
| `IF_Err_Brg` (L1) | `ErrorStatusType`, `init_error_status`, `IF_STATUS_OK` | 错误传播 |
| `MD_Field_Mgr` (L3 同层) | `MD_NodeDisp` | 节点位移数据 |
| `MD_Base_ObjModel` (L3 同层) | `DescBase` | 连接器基类 |
| `MD_KW_Def` (L3 同层) | `KW_ASTNodeType` | 关键字 AST 节点 |
| `MD_Model_Lib` (L3 同层) | `UF_ModelDef` | Legacy 模型定义（Sync 用） |
| `MD_Constr_Prop` (L3 同层) | `UF_ContactPropertyDB`, `UF_ContactPropertyDef` | Legacy 接触属性（Sync 用） |
| `MD_L3_Layer` (L3 同层) | `MD_L3_LayerContainer` | L3 层容器（Sync 用） |

### 5.2 下游消费者（L4/L5 如何读取本域数据）

| 下游消费者 | 消费内容 | 桥接模块 |
|-----------|----------|----------|
| L4_PH/Contact | 接触参数 Desc → L4 接触力学计算 | `MD_ContPH_Brg` (Bridge_L4/) |
| L5_RT/Contact | 接触 Desc → L5 接触编排 | `MD_ContRT_Brg` (Bridge_L5/) |
| L5_RT/Assembly | 接触三元组/CSR → RT 装配 | `MD_Int_Brg` (Bridge_L5/) |
| L6_AP/Input | 接触定义解析 | 经 `MD_KWRT_Brg` 间接 |

### 5.3 数据流图

```
[L1_IF] Prec/Err ──────────────────────────────────────────────────────┐
                                                                       ↓
[L3_MD/Element/Mesh] 表面名解析 ──→ [L3_MD/Interaction] ──→ MD_ContPH_Brg ──→ [L4_PH/Contact]
[L3_MD/Assembly] 装配体引用 ──┘  │  Desc 真相源     ──→ MD_ContRT_Brg ──→ [L5_RT/Contact]
[L3_MD/Step] 分析步上下文 ───────┘                   ──→ MD_Int_Brg ────→ [L5_RT/Assembly]
                                                       
WriteBack (白名单):  L5_RT → MD_Interaction_WriteBack_State/Active → L3_MD/Interaction
```

---

## 6. 域间契约

### 6.1 同层域间关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Element/Mesh | S(消费) | 表面名解析（master_surf / slave_surf） |
| R2 | L3_MD/Assembly | S(消费) | 装配体引用（接触对定位） |
| R3 | L3_MD/Analysis/Step | S(消费) | `current_step_idx` / `current_incr_idx` |
| R4 | L3_MD/Bridge/Bridge_L4 | T(合同) | `MD_ContPH_Brg` 映射 |
| R5 | L3_MD/Bridge/Bridge_L5 | T(合同) | `MD_ContRT_Brg` / `MD_Int_Brg` |
| R6 | L3_MD/Field | S(消费) | `MD_NodeDisp` 节点位移 |

### 6.2 跨层域间关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R7 | L4_PH/Contact | B(桥接) | Desc → L4 接触力学计算 |
| R8 | L5_RT/Contact | B(桥接) | Desc → L5 接触编排 |
| R9 | L5_RT/Assembly | B(桥接) | `RT_Asm_ApplyContact` 消费 |
| R10 | L1_IF/Error | U(USE) | 错误码定义 |

### 6.3 Bridge 接口

| 方向 | 接口 | 功能 |
|------|------|------|
| L3→L4 | `MD_Cont_PH_Fill_From_Type` / `MD_Cont_PH_Fill_From_Union` | 填充 L4 接触参数 |
| L3→L5 | `MD_RT_Cont_TripletAdd` | 添加三元组接触 |
| L3→L5 | `MD_RT_Cont_GetEqId` | 获取方程 ID |
| L3→L5 | `MD_Contact_Brg_BuildStepPairs` | 构建步级接触对 |
| L3→L5 | `MD_Contact_Brg_ConvertProperty` | 转换接触属性 |
| L3→L5 | `UF_ContBrg_InitFromMD` / `IncrInit` / `IterationInit` | 接触桥接初始化 |

### 6.4 WriteBack 白名单

| 方向 | API | 可写字段 |
|------|-----|---------|
| L5→L3 | `MD_Interaction_WriteBack_State` | `gap`, `normal_force`, `tangent_force`, `contact_state` |
| L5→L3 | `MD_Interaction_WriteBack_Active` | `isActive` |
| 冻结字段（禁止写回） | — | `master_surface`, `slave_surface`, `prop_name`, `friction`, `cohesion`, `algo` |

---

## 7. 验收标准

### 7.1 功能完整性检查项

- [ ] 接触对注册：`pair_id` 唯一性校验通过
- [ ] 接触属性：罚刚度/摩擦系数范围检查通过
- [ ] 表面名解析：master/slave 表面在 Mesh 域中存在
- [ ] 四型 TYPE 完整：Desc/State/Algo/Ctx 均已定义
- [ ] Init/Finalize 对称：所有 ALLOCATE 均有对应 DEALLOCATE
- [ ] WriteBack 白名单：仅允许 `WriteBack_State`/`WriteBack_Active` 两个入口
- [ ] 连接器定义：Spring/Joint/Dashpot/Bushing 四种连接器 Parse/Validate/Configure 完整

### 7.2 命名合规要求

- [ ] 模块命名：`MD_Int_*` / `MD_Cont_*` 前缀
- [ ] TYPE 命名：四型后缀（`_Desc`/`_State`/`_Algo`/`_Ctx`）对齐
- [ ] 文件后缀：`_Def` / `_Core` / `_Ops` / `_Brg` / `_Sync` / `_Parser` / `_Mapper` 角色对齐
- [ ] 使用 `IF_Prec_Core` 的 `wp`/`i4`（Harness Gate H-ERR-01）
- [ ] L3→L4/L5 须经 Bridge，禁止直接 USE L4/L5（Harness Gate H-DEP-03）

### 7.3 测试覆盖要求

- [ ] 单元级：接触对注册 `pair_id` 唯一性
- [ ] 单元级：摩擦系数范围检查（0.0~1.0）
- [ ] 单元级：连接器属性验证（Valid_Fn）
- [ ] 集成级：Interaction ↔ Mesh 表面名解析
- [ ] 集成级：Interaction ↔ L5_RT 接触装配正确性
- [ ] 集成级：Legacy Sync 数据一致性

---

## 附录 A. 接触算法枚举

```fortran
! 接触算法类型 (MD_Int_Def.f90)
INTEGER(i4), PARAMETER :: ALGORITHM_PENALTY = 1             ! 罚函数法
INTEGER(i4), PARAMETER :: ALGORITHM_LAGRANGE = 2            ! 拉格朗日乘子法
INTEGER(i4), PARAMETER :: ALGORITHM_AUGMENTED_LAGRANGE = 3  ! 增强拉格朗日法

! 摩擦类型 (MD_Int_Def.f90)
INTEGER(i4), PARAMETER :: FRICTION_COULOMB = 1   ! 库伦摩擦
INTEGER(i4), PARAMETER :: FRICTION_VISCOUS = 2   ! 粘摩擦
INTEGER(i4), PARAMETER :: FRICTION_PENALTY = 3   ! 罚函数摩擦

! 接触类型 (MD_Int_Def.f90)
INTEGER(i4), PARAMETER :: CONTACT_TYPE_S2S = 1   ! Surface-to-Surface
INTEGER(i4), PARAMETER :: CONTACT_TYPE_P2S = 2   ! Point-to-Surface
INTEGER(i4), PARAMETER :: CONTACT_TYPE_E2E = 3   ! Edge-to-Edge
INTEGER(i4), PARAMETER :: CONTACT_TYPE_SELF = 4  ! Self-Contact
```

## 附录 B. 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L3_INTERACTION_xxx` (30700–30799) |
| 严重级 | WARNING: 接触属性缺失(使用默认); ERROR: 接触对表面未找到; FATAL: 接触算法不支持 |
| 传播规则 | 经 `status` 参数返回调用方；不自行 STOP |
| 恢复策略 | WARNING：日志 + 默认摩擦系数 0.0；ERROR：中止接触对注册并上报 |

## 附录 C. 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 接触 Desc 为 Write-Once，解析后只读 | 硬 | Code Review | — |
| 接触对 pair_id 唯一性 | 硬 | Init 时校验 | — |
| 禁止在 Interaction 域执行接触力学计算 | 硬 | Code Review | — |
| L3→L4/L5 须经 Bridge，禁止直接 USE L4/L5 | 硬 | Harness | H-DEP-03 |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 接触算法枚举变更须同步更新本 CONTRACT | 软 | Code Review | — |

## 附录 D. 已知问题 (v3.0)

- `MD_Interaction_Desc` 在 `MD_Int_Def.f90` 中定义了两种不同布局（v1 四型版 + v2 Domain 版）
- `MD_Int_Types.f90` 中的接触力学计算过程（违反 L3 无计算原则），系原 `MD_Int_API.f90` 拆分遗产
- `MD_Model_Brg.f90` 中的接触桥接子程序已禁用（DANGLING-REF 到已删除的 `RT_ContactSurface`/`RT_ContactTypes`）

## 附录 E. Domain Pillar 交叉引用 (v2.0)

**Domain Pillar**: P3 Contact (Full Pillar, L3/L4/L5 three-layer)

| Layer | Directory | Prefix | CONTRACT |
|-------|-----------|--------|----------|
| L3_MD | Interaction/ | `MD_Interaction_*`, `MD_Cont_*`, `MD_Int_*` | this file |
| L4_PH | Contact/ | `PH_Contact_*`, `PH_Cont_*` | L4_PH/Contact/CONTRACT.md |
| L5_RT | Contact/ | `RT_Contact_*`, `RT_Cont_*` | L5_RT/Contact/CONTRACT.md |

**Bridge chain**: L3→L4: `MD_ContPH_Brg` (Bridge_L4/) · L3→L5: `MD_ContRT_Brg`, `MD_Int_Brg`, `MD_IntContactArgs` (Bridge_L5/) · L5→L3: `RT_Contact_Brg_WriteBack` (diagnostics only)

---

## 附录 F. 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `MD_Int_Def.f90` | `MD_Int_Def` | `ContactPairType`, `SurfaceInteractionType`, `FrictionModelType`, `MD_Interaction_Desc`, `MD_Interaction_State`, `MD_Interaction_Algo`, `MD_Int_Ctx` | `IsValidContactPair` (FN,PUB), `IsValidSurfaceInteraction` (FN,PUB), `IsValidFrictionModel` (FN,PUB), `Initialize_InteractionDesc` (SUB,PUB), `AddContactPair` (SUB,PUB) |
| `MD_Int_Core.f90` | `MD_Int_Core` | — | `MD_Interaction_Core_Init` (SUB,PUB,Init), `MD_Interaction_Core_Finalize` (SUB,PUB,Finalize), `MD_Interaction_Add_Surface` (SUB,PUB,Mutate), `MD_Interaction_Add_Pair` (SUB,PUB,Mutate), `MD_Interaction_Set_Friction` (SUB,PUB,Mutate), `MD_Interaction_Get_Pair` (SUB,PUB,Query), `MD_Interaction_Get_N_Pairs` (FN,PUB,Query), `MD_Interaction_Validate` (SUB,PUB,Validate) |
| `MD_Int_Parser.f90` | `MD_Int_Parser` | — | `MD_Parse_ContactPair` (SUB,PUB,Parse), `MD_Parse_SurfaceInteraction` (SUB,PUB,Parse), `MD_Parse_Friction` (SUB,PUB,Parse), `MD_Parse_InteractionVariables` (SUB,PUB,Parse), `Convert_To_Upper` (SUB,PUB), `Extract_Parameter_Value` (FN,PUB) |
| `MD_Int_Mapper.f90` | `MD_Int_Mapper` | `SurfaceSetType`, `InteractionMappingType` | `MD_Validate_ContactPair` (FN,PUB,Validate), `MD_Validate_SurfaceInteraction` (FN,PUB,Validate), `MD_Allocate_InteractionArrays` (SUB,PUB), `MD_Map_InteractionToMesh` (SUB,PUB,Populate), `MD_Build_InteractionMapping` (SUB,PUB,Populate), `MD_Get_SurfaceNodeCount` (FN,PUB,Query), `MD_Get_SurfaceElementCount` (FN,PUB,Query) |
| `MD_Int_Sync.f90` | `MD_Int_Sync` | — | `MD_Interaction_SyncFromLegacy` (SUB,PUB,Populate) |
| `MD_Hash_Table.f90` | `MD_Hash_Table` | `HashTableEntry`, `HashTableType` | `Init_HashTable` (SUB,PUB), `Destroy_HashTable` (SUB,PUB), `HashTable_Insert` (SUB,PUB,Mutate), `HashTable_Lookup` (SUB,PUB,Query), `HashTable_Remove` (SUB,PUB,Mutate), `HashTable_Clear` (SUB,PUB,Mutate), `HashString` (FN,PUB), `IsEmpty_HashTable` (FN,PUB,Query), `GetSize_HashTable` (FN,PUB,Query), `HashTable_GetLoadFactor` (FN,PUB,Query) |

> **完整 MD_Int_API 再导出符号清单 (149 个)**: 见 `MD_Int_API.f90` 头注释及上表模块边界（历史 REPORTS 专文未入库）。

---

## 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 早期 | 初始简版合同卡(49行) |
| v2.0 | 2026-04-17 | 扩充为标准格式，200+行 |
| v3.0 | 2026-04-28 | 补全至标准 7 章节格式，完整四类 TYPE 清单、功能模块清单、对外接口签名、跨层数据流、域间契约、验收标准 |
| v3.1 | 2026-04-30 | Pilot：删除域内空 `MD_Int_Brg` 存根；`MODULE MD_Int_Brg` 仅保留于 `L3_MD/Bridge/Bridge_L5/MD_Int_Brg.f90` |


*维护: Interaction 域 TYPE/接口变更时须同步更新本 CONTRACT*
