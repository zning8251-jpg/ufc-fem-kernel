# 算法步规约：L3_MD — 模型描述层（15 域）

> **版本**: v1.0 | **日期**: 2026-04-26
>
> L3 特征：**唯一真相源**。全部域在 Config Phase 完成，Verb 集中在 Init/Access(CRUD)/Validate。
> 热路径禁入——L4/L5 仅通过 Populate/Bridge 单向读取。
>
> **统一模式**: Init(空容器) → CRUD(Add/Set/Get) → Validate(闸门) → Finalize(释放)
>
> **详细样板**: [ASP_GOLDEN_MD_Model.md](ASP_GOLDEN_MD_Model.md)

---

## 数据域统一算法步模板

L3 的 13 个数据域（除 WriteBack、Bridge 外）共享相同的算法步模式：

```
Step 0: Core_Init      Config/Init        → 空容器就绪
Step 1: Add/Set (×N)   Config/Access(Add)  → 填充数据（来自 INP/API）
Step 2: Validate        Config/Validate     → 闸门检查
Step 3: Get/Find (×M)  (any)/Access(Get)   → 只读查询
Step 4: Core_Finalize   Config/Init(Fin)    → 释放资源
```

以下按域展开每域的**特有算法步**（Init/Finalize 不重复）。

---

## Model（10 过程）

> 详见 [ASP_GOLDEN_MD_Model.md](ASP_GOLDEN_MD_Model.md) 完整五要素

**特有步**: Set_Name, Register_Part(×N), Register_Step(×N), Validate_All, Summary, Get_NDim/N_Parts/N_Steps
**跨域供数**: n_dim → L1_IF/Base, L4_PH/Element; parts/steps → Bridge(L3→L4/L5)

---

## Analysis（8 过程）

**特有算法步**:

| Step | 过程 | 消费 | 生产 | 算法核 |
|------|------|------|------|--------|
| 1 | `MD_Analysis_Add_Step` | step_desc(外部) | steps(n+1) | 注册分析步定义 |
| 2 | `MD_Analysis_Get_Step` | step_id | step_desc | 按 ID 查询 |
| 3 | `MD_Analysis_Add_Amplitude` | ampl_desc(外部) | amplitudes(n+1) | 注册幅值曲线 |
| 4 | `MD_Analysis_Eval_Amplitude` | ampl_id, time | factor(wp) | 线性/平滑插值 |
| 5 | `MD_Analysis_Validate` | steps, amplitudes | status | 步时间窗合法性 |
| 6 | `MD_Analysis_Get_N_Steps` | n_steps | result(i4) | 查询 |

**关键数据流**: steps → L5_RT/StepDriver.Desc (Populate); amplitudes → L4_PH/LoadBC 幅值求值

**Eval_Amplitude 算法核**:
```
给定 time, 在 ampl.times(:) 中二分查找区间 [t_i, t_{i+1}]
factor = lerp(ampl.values(i), ampl.values(i+1), (time-t_i)/(t_{i+1}-t_i))
```

---

## Mesh（9 过程）

**特有算法步**:

| Step | 过程 | 消费 | 生产 | 算法核 |
|------|------|------|------|--------|
| 1 | `MD_Mesh_Set_Nodes` | n_nodes, coords(ndim,n) | mesh_desc.coords | 拷贝节点坐标 |
| 2 | `MD_Mesh_Set_Connectivity` | n_elem, conn(:,:), types(:) | mesh_desc.conn | 拷贝连接表 |
| 3 | `MD_Mesh_Get_Node_Coords` | node_id | coords(ndim) | 按节点查询 |
| 4 | `MD_Mesh_Get_Elem_Conn` | elem_id | conn(:) | 按单元查询 |
| 5 | `MD_Mesh_Add_NodeSet` | set_name, node_ids(:) | mesh_desc.nodesets(+1) | 注册节点集 |
| 6 | `MD_Mesh_Add_ElemSet` | set_name, elem_ids(:) | mesh_desc.elemsets(+1) | 注册单元集 |
| 7 | `MD_Mesh_Validate` | mesh_desc | status | 节点/连接完整性 |

**关键数据流**: coords → L4_PH/Element.Desc (Populate); conn → L5_RT/Assembly.DofMap; nodesets → L4_PH/LoadBC/Contact

**Validate 算法核**:
```
检查: n_nodes > 0, n_elem > 0
检查: conn 中所有节点 ID ∈ [1, n_nodes]
检查: 无重复节点 ID
检查: 每个单元至少 2 个节点
```

---

## Material（9 过程）

**特有算法步**:

| Step | 过程 | 消费 | 生产 | 算法核 |
|------|------|------|------|--------|
| 1 | `MD_Material_Add` | mat_desc(id,name,type,nprops) | materials(+1) | 注册材料卡 |
| 2 | `MD_Material_Get_By_ID` | mat_id | mat_desc | ID 查询 |
| 3 | `MD_Material_Get_By_Name` | name | mat_desc | 名称查找 O(n) |
| 4 | `MD_Material_Set_Property` | mat_id, prop_idx, value | materials(id).props(idx) | 设置参数 |
| 5 | `MD_Material_Get_Property` | mat_id, prop_idx | value(wp) | 查询参数 |
| 6 | `MD_Material_Validate` | materials(:) | status | 参数范围检查 |

**关键数据流**: materials → Bridge(L3→L4) → L4_PH/Material.Desc (E, nu, yield_stress, …)

---

## Section（8 过程）

| Step | 过程 | 算法核 |
|------|------|--------|
| 1 | `MD_Section_Add` | 注册截面 (type, thickness, mat_id) |
| 2 | `MD_Section_Get_By_ID` | ID 查询 |
| 3 | `MD_Section_Get_Material_ID` | 查询关联材料 ID |
| 4 | `MD_Section_Set_Thickness` | 设置/更新厚度 |
| 5 | `MD_Section_Validate` | 检查 mat_id 存在、thickness>0 |
| 6 | `MD_Section_Validate_Triple` | Mesh↔Section↔Material 三元一致性 |

**Validate_Triple 算法核**: 每个 elem 的 section.mat_id 在 materials 中存在，且 section.type 与 elem.type 兼容。

---

## Part（6 过程）

| Step | 过程 | 算法核 |
|------|------|--------|
| 1 | `MD_Part_Add` | 注册部件 (id, name) |
| 2 | `MD_Part_Get_By_ID` | ID 查询 |
| 3 | `MD_Part_Assign_Section` | 绑定 section_id |
| 4 | `MD_Part_Validate` | 检查 section_id 存在 |

---

## Assembly（7 过程）

| Step | 过程 | 算法核 |
|------|------|--------|
| 1 | `MD_Assembly_Add_Instance` | 注册部件实例 (part_id, transform) |
| 2 | `MD_Assembly_Get_Instance` | ID 查询 |
| 3 | `MD_Assembly_Build_GlobalMap` | 部件内编号 → 全局编号映射 O(n_nodes) |
| 4 | `MD_Assembly_Get_Global_NodeID` | 局部→全局节点 ID 转换 |
| 5 | `MD_Assembly_Get_NEQ` | 返回方程总数 |

**关键数据流**: global_map → L5_RT/Assembly.DofMap; NEQ → L2_NM/Solver.n

---

## Boundary（7 过程）

| Step | 过程 | 算法核 |
|------|------|--------|
| 1 | `MD_Boundary_Add_Dirichlet` | 注册 Dirichlet BC (dof, value, ampl_id) |
| 2 | `MD_Boundary_Add_Neumann` | 注册 Neumann BC (surface, value, ampl_id) |
| 3 | `MD_Boundary_Get_By_Index` | 索引查询 |
| 4 | `MD_Boundary_Get_Count` | 返回 BC 数量 |
| 5 | `MD_Boundary_Clear_Step` | 步切换时清除活跃 BC 列表 |

**跨域供数**: bc_list → L4_PH/LoadBC.Desc (Populate)

---

## Constraint（8 过程）

| Step | 过程 | 算法核 |
|------|------|--------|
| 1 | `MD_Constraint_Add_MPC` | 注册多点约束 (master, slaves, coeffs) |
| 2 | `MD_Constraint_Add_Tie` | 注册 Tie 约束 (surface_pair, tolerance) |
| 3 | `MD_Constraint_Add_Equation` | 注册方程约束 |
| 4 | `MD_Constraint_Get_By_Index` | 索引查询 |
| 5 | `MD_Constraint_Get_Count` | 返回约束数量 |
| 6 | `MD_Constraint_Validate` | 检查节点存在、系数非零 |

**跨域供数**: constraints → L4_PH/Constraint.Desc (Populate)

---

## Field（7 过程）

| Step | 过程 | 算法核 |
|------|------|--------|
| 1 | `MD_Field_Define` | 注册命名场变量 (name, components, location) |
| 2 | `MD_Field_Set_Initial` | 设置初始值 O(n_nodes) |
| 3 | `MD_Field_Get_By_ID` | ID 查询 |
| 4 | `MD_Field_Get_By_Name` | 名称查找 O(n) |
| 5 | `MD_Field_Get_Count` | 返回场变量数量 |

---

## Interaction（8 过程）

| Step | 过程 | 算法核 |
|------|------|--------|
| 1 | `MD_Interaction_Add_Surface` | 注册接触面 (name, elem_set/node_set) |
| 2 | `MD_Interaction_Add_Pair` | 注册接触对 (master_surf, slave_surf) |
| 3 | `MD_Interaction_Set_Friction` | 设置摩擦属性 (mu, model) |
| 4 | `MD_Interaction_Get_Pair` | ID 查询 |
| 5 | `MD_Interaction_Validate` | 检查面存在、对不自交 |

**跨域供数**: pairs → L4_PH/Contact.Desc (Populate)

---

## KeyWord（9 过程）

**特有算法步**（解析域，逻辑稍复杂）:

| Step | 过程 | 消费 | 生产 | 算法核 |
|------|------|------|------|--------|
| 1 | `MD_KeyWord_Register` | kw_name, handler | kw_table(+1) | 注册关键字及其处理器 |
| 2 | `MD_KeyWord_Parse_Line` | line_string | kw_state(current_kw, params) | 词法解析: 分割逗号/等号 |
| 3 | `MD_KeyWord_Match` | kw_name | kw_entry 或 NULL | 在注册表中查找 |
| 4 | `MD_KeyWord_Get_Int_Param` | param_name | value(i4) | 参数提取 |
| 5 | `MD_KeyWord_Get_Real_Param` | param_name | value(wp) | 参数提取 |
| 6 | `MD_KeyWord_Get_Current` | — | current_kw_name | 当前关键字名 |
| 7 | `MD_KeyWord_Is_DataLine` | line | result(LOGICAL) | 判断是否数据行(非关键字行) |

**Parse_Line 算法核**:
```
IF (line 以 * 开头) THEN
  kw_name = 提取关键字名
  params = 解析 key=value 对
  current_kw = Match(kw_name)
ELSE
  标记为数据行
END IF
```

---

## Output（7 过程）

| Step | 过程 | 算法核 |
|------|------|--------|
| 1 | `MD_Output_Add_Field_Request` | 注册场输出请求 (variables, frequency) |
| 2 | `MD_Output_Add_History_Request` | 注册历史输出请求 (variables, region) |
| 3 | `MD_Output_Validate` | 检查请求的变量名在 Field 中已定义 |

**跨域供数**: field_requests → L5_RT/Output.Desc (Populate)

---

## WriteBack（7 过程 — 桥接域）

**核心意图**: L5→L3 回写映射

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | Phase |
|------|------|-----------|-----------|-------|
| 0 | `MD_WriteBack_Core_Init` | — | wb_desc | Config |
| 1 | `MD_WriteBack_Register_Map` | source_field, target_field | maps(+1) | Config |
| 2 | `MD_WriteBack_Get_Map` | map_id | map_entry | (any) |
| 3 | `MD_WriteBack_Execute` | maps, source_data | target_data | Step |
| 4 | `MD_WriteBack_Validate` | maps | status | Config |

**Execute 算法核**: 遍历所有注册的映射，从 L5 源数组拷贝到 L3 目标字段。

---

## Bridge（桥接域 — 无 Core 过程）

**核心意图**: L3↔L4/L5 的 Populate 阶段单向数据搬运

### 算法步模式

每个 `*_Brg.f90` 模块遵循：

```
Step 0: 读取 L3 域 Desc 的相关字段
Step 1: 映射/转换为 L4/L5 目标 Desc 的字段
Step 2: 写入目标 Desc slot
```

| Bridge 模块 | 源 | 目标 | 搬运数据 |
|-------------|-----|------|---------|
| MD_MatLibPH_Brg | L3/Material | L4/Material.Desc | props, mat_type |
| MD_ElemPH_Brg | L3/Mesh+Section | L4/Element.Desc | n_nodes, coords |
| MD_ContPH_Brg | L3/Boundary | L4/LoadBC.Desc | load_cache |
| MD_ConstraintPH_Brg | L3/Constraint | L4/Constraint.Desc | coeffs |
| MD_Model_Brg | L3/Model | L5/StepDriver | n_dim |
| MD_Mesh_Brg | L3/Mesh | L5/Assembly | coords, conn |
| MD_KWRT_Brg | L3/KeyWord | L5/RT | 关键字参数 |
| MD_UniFldRT_Brg | L3/Field | L5/RT | 场变量定义 |

**闭合性**: 每个 Bridge 的生产数据恰被一个 L4/L5 Desc slot 消费。✓
