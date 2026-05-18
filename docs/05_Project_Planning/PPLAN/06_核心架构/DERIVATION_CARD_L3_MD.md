# 推演卡综合：L3_MD — 模型描述层

> 推演引擎 v1.0 | 2026-04-26 | 15 域全覆盖
>
> L3 特征：模型数据真相源，所有域集中在 Config Phase，Verb 以 Init/Access(CRUD)/Validate 为主。
> 热路径禁入——L4/L5 仅通过 Populate/Bridge 读取 L3，不在步内直读。

---

## Model

**域**：L3_MD / Model | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：顶层模型树——部件注册、步注册、全局校验

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Model_Core_Init` | Config | Init | O(1) |
| `MD_Model_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Model_Set_Name` | Config | Access(Set) | O(1) |
| `MD_Model_Register_Part` | Config | Access(Add) | O(1) |
| `MD_Model_Register_Step` | Config | Access(Add) | O(1) |
| `MD_Model_Validate_All` | Config | Validate | O(n_parts+n_steps) |
| `MD_Model_Summary` | (any) | Access(Get) | O(1) |
| `MD_Model_Get_NDim` | (any) | Access(Get) | O(1) |
| `MD_Model_Get_N_Parts` | (any) | Access(Get) | O(1) |
| `MD_Model_Get_N_Steps` | (any) | Access(Get) | O(1) |

---

## Analysis

**域**：L3_MD / Analysis | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：分析步/幅值/求解器配置管理

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Analysis_Core_Init` | Config | Init | O(1) |
| `MD_Analysis_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Analysis_Add_Step` | Config | Access(Add) | O(1) |
| `MD_Analysis_Get_Step` | Config | Access(Get) | O(1) |
| `MD_Analysis_Add_Amplitude` | Config | Access(Add) | O(1) |
| `MD_Analysis_Eval_Amplitude` | (any) | Compute(Evaluate) | O(n_pts) |
| `MD_Analysis_Validate` | Config | Validate | O(n_steps) |
| `MD_Analysis_Get_N_Steps` | (any) | Access(Get) | O(1) |

**子域**：`Step/`（MD_Step_*）、`Amplitude/`（MD_Amplitude_*）、`Solver/`（MD_Solv_*）

---

## Mesh

**域**：L3_MD / Mesh | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：节点坐标、单元连接、节点集/单元集、DOF 管理

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Mesh_Core_Init` | Config | Init | O(1) |
| `MD_Mesh_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Mesh_Set_Nodes` | Config | Access(Set) | O(n_nodes) |
| `MD_Mesh_Set_Connectivity` | Config | Access(Set) | O(n_elem) |
| `MD_Mesh_Get_Node_Coords` | (any) | Access(Get) | O(1) |
| `MD_Mesh_Get_Elem_Conn` | (any) | Access(Get) | O(1) |
| `MD_Mesh_Add_NodeSet` | Config | Access(Add) | O(n_set) |
| `MD_Mesh_Add_ElemSet` | Config | Access(Add) | O(n_set) |
| `MD_Mesh_Validate` | Config | Validate | O(n_nodes+n_elem) |

**子域**：`Element/`（单元族注册/校验/Populate，含 Beam/Shell/Solid/Truss 等 12 子族）

---

## Material

**域**：L3_MD / Material | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：材料卡 Desc 真相源（ID→名称→属性→类型）

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Material_Core_Init` | Config | Init | O(1) |
| `MD_Material_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Material_Add` | Config | Access(Add) | O(1) |
| `MD_Material_Get_By_ID` | (any) | Access(Get) | O(1) |
| `MD_Material_Get_By_Name` | (any) | Access(Find) | O(n) |
| `MD_Material_Validate` | Config | Validate | O(n_mats) |
| `MD_Material_Set_Property` | Config | Access(Set) | O(1) |
| `MD_Material_Get_Property` | (any) | Access(Get) | O(1) |
| `MD_Material_Get_Count` | (any) | Access(Get) | O(1) |

---

## Section

**域**：L3_MD / Section | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：截面属性、材料绑定、厚度/惯性矩管理

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Section_Core_Init` | Config | Init | O(1) |
| `MD_Section_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Section_Add` | Config | Access(Add) | O(1) |
| `MD_Section_Get_By_ID` | (any) | Access(Get) | O(1) |
| `MD_Section_Get_Material_ID` | (any) | Access(Get) | O(1) |
| `MD_Section_Set_Thickness` | Config | Access(Set) | O(1) |
| `MD_Section_Validate` | Config | Validate | O(n_sects) |
| `MD_Section_Validate_Triple` | Config | Validate | O(1) |

---

## Part

**域**：L3_MD / Part | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：部件管理、截面指派

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Part_Core_Init` | Config | Init | O(1) |
| `MD_Part_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Part_Add` | Config | Access(Add) | O(1) |
| `MD_Part_Get_By_ID` | (any) | Access(Get) | O(1) |
| `MD_Part_Assign_Section` | Config | Access(Set) | O(1) |
| `MD_Part_Validate` | Config | Validate | O(1) |

---

## Assembly

**域**：L3_MD / Assembly | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：部件实例化、全局编号映射

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Assembly_Core_Init` | Config | Init | O(1) |
| `MD_Assembly_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Assembly_Add_Instance` | Config | Access(Add) | O(1) |
| `MD_Assembly_Get_Instance` | (any) | Access(Get) | O(1) |
| `MD_Assembly_Build_GlobalMap` | Config | Compute(Build) | O(n_nodes) |
| `MD_Assembly_Get_Global_NodeID` | (any) | Access(Get) | O(1) |
| `MD_Assembly_Get_NEQ` | (any) | Access(Get) | O(1) |

---

## Boundary

**域**：L3_MD / Boundary | **域类型**：数据域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(Y)

**核心意图**：载荷/边界条件 Desc（Dirichlet/Neumann）管理

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Boundary_Core_Init` | Config | Init | O(1) |
| `MD_Boundary_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Boundary_Add_Dirichlet` | Config | Access(Add) | O(1) |
| `MD_Boundary_Add_Neumann` | Config | Access(Add) | O(1) |
| `MD_Boundary_Get_By_Index` | (any) | Access(Get) | O(1) |
| `MD_Boundary_Get_Count` | (any) | Access(Get) | O(1) |
| `MD_Boundary_Clear_Step` | Step | Init(Reset) | O(n_bcs) |

---

## Constraint

**域**：L3_MD / Constraint | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：MPC/Tie/方程约束 Desc 管理

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Constraint_Core_Init` | Config | Init | O(1) |
| `MD_Constraint_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Constraint_Add_MPC` | Config | Access(Add) | O(1) |
| `MD_Constraint_Add_Tie` | Config | Access(Add) | O(1) |
| `MD_Constraint_Add_Equation` | Config | Access(Add) | O(1) |
| `MD_Constraint_Get_By_Index` | (any) | Access(Get) | O(1) |
| `MD_Constraint_Get_Count` | (any) | Access(Get) | O(1) |
| `MD_Constraint_Validate` | Config | Validate | O(n_const) |

---

## Field

**域**：L3_MD / Field | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：命名场变量定义与初始值设置

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Field_Domain_Init` | Config | Init | O(1) |
| `MD_Field_Domain_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Field_Define` | Config | Access(Add) | O(1) |
| `MD_Field_Set_Initial` | Config | Access(Set) | O(n_nodes) |
| `MD_Field_Get_By_ID` | (any) | Access(Get) | O(1) |
| `MD_Field_Get_By_Name` | (any) | Access(Find) | O(n) |
| `MD_Field_Get_Count` | (any) | Access(Get) | O(1) |

---

## Interaction

**域**：L3_MD / Interaction | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：接触面/接触对/摩擦属性 Desc 管理

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Interaction_Core_Init` | Config | Init | O(1) |
| `MD_Interaction_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Interaction_Add_Surface` | Config | Access(Add) | O(1) |
| `MD_Interaction_Add_Pair` | Config | Access(Add) | O(1) |
| `MD_Interaction_Set_Friction` | Config | Access(Set) | O(1) |
| `MD_Interaction_Get_Pair` | (any) | Access(Get) | O(1) |
| `MD_Interaction_Validate` | Config | Validate | O(n_pairs) |
| `MD_Interaction_Get_N_Pairs` | (any) | Access(Get) | O(1) |

---

## KeyWord

**域**：L3_MD / KeyWord | **域类型**：数据域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(Y)

**核心意图**：ABAQUS 风格关键字解析、注册、参数提取

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_KeyWord_Core_Init` | Config | Init | O(1) |
| `MD_KeyWord_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_KeyWord_Register` | Config | Access(Add) | O(1) |
| `MD_KeyWord_Parse_Line` | Config | Compute | O(line_len) |
| `MD_KeyWord_Match` | Config | Access(Find) | O(n_kw) |
| `MD_KeyWord_Get_Int_Param` | Config | Access(Get) | O(1) |
| `MD_KeyWord_Get_Real_Param` | Config | Access(Get) | O(1) |
| `MD_KeyWord_Get_Current` | Config | Access(Get) | O(1) |
| `MD_KeyWord_Is_DataLine` | Config | Control(Check) | O(1) |

---

## Output

**域**：L3_MD / Output | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：输出请求（Field/History）管理、统一场注册

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_Output_Core_Init` | Config | Init | O(1) |
| `MD_Output_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_Output_Add_Field_Request` | Config | Access(Add) | O(1) |
| `MD_Output_Add_History_Request` | Config | Access(Add) | O(1) |
| `MD_Output_Validate` | Config | Validate | O(n_req) |
| `MD_Output_Get_N_Field_Requests` | (any) | Access(Get) | O(1) |
| `MD_Output_Get_N_History_Requests` | (any) | Access(Get) | O(1) |

---

## WriteBack

**域**：L3_MD / WriteBack | **域类型**：桥接域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(N)

**核心意图**：将求解器/运行时结果写回模型侧映射

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `MD_WriteBack_Core_Init` | Config | Init | O(1) |
| `MD_WriteBack_Core_Finalize` | Config | Init(Fin) | O(1) |
| `MD_WriteBack_Register_Map` | Config | Access(Add) | O(1) |
| `MD_WriteBack_Get_Map` | (any) | Access(Get) | O(1) |
| `MD_WriteBack_Execute` | Step | Bridge(WriteBack) | O(n_maps*n_data) |
| `MD_WriteBack_Validate` | Config | Validate | O(n_maps) |
| `MD_WriteBack_Get_Count` | (any) | Access(Get) | O(1) |

---

## Bridge

**域**：L3_MD / Bridge | **域类型**：桥接域 | 无 `*_Core.f90`

**核心意图**：L3↔L4（Bridge_L4/）和 L3↔L5（Bridge_L5/）的跨层数据桥接。19 个 `*_Brg.f90` 模块，负责 Populate 阶段的单向数据流。

| 子模块 | 方向 | 说明 |
|--------|------|------|
| `MD_Model_Brg` | L3→L5 | 模型树桥接 |
| `MD_Mesh_Brg` | L3→L4/L5 | 网格数据桥接 |
| `MD_MatLibPH_Brg` | L3→L4 | 材料参数→L4 slot |
| `MD_ElemPH_Brg` | L3→L4 | 单元元数据→L4 |
| `MD_ContPH_Brg` | L3→L4 | 约束→L4 |
| `MD_ConstraintPH_Brg` | L3→L4 | 约束详细→L4 |
| `MD_KWRT_Brg` | L3→L5 | 关键字→RT |
| `MD_UniFldRT_Brg` | L3→L5 | 统一场→RT |

**Phase**：Config/Populate | **Verb**：Bridge(Populate)
