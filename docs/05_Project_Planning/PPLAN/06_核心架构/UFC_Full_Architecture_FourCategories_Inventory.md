# UFC 全架构四大类（Desc/State/Algo/Ctx）详细清单

> **数据来源**：基于 `d:\TEST7\UFC\ufc_core` 现有代码 + `d:\TEST7\Markdown` ABAQUS 手册映射  
> **提取范围**：L3_MD/L4_PH/L5_RT三层 × 14 个域级 × 四大类（Desc/State/Algo/Ctx）  
> **状态**：Phase A - 初稿（待补全所有域级）

---

## 一、提取方法论

### 1.1 四大类语义定义（全架构版）

| 类型 | 归属层 | 职责 | 访问模式 | 典型生命周期 | 内存特征 |
|------|--------|------|---------|-------------|---------|
| **Desc（描述型）** | L3_MD（冷路径） | "是什么" - 模型元信息、拓扑、配置参数 | 只读（热路径期间冻结） | 整个分析存活 | 一次分配，多次读取 |
| **State（状态型）** | L4_PH（热路径） | "变成什么" - 计算过程动态状态、中间结果 | 读写（每增量更新） | 单个增量步或内变量持久 | ALLOCATABLE 支持演化 |
| **Algo（算法型）** | L3+L4+L5 | "如何计算" - 求解器参数、超参数 | L3: 分析前配置<br>L4: 迭代内只读<br>L5: 步间可调整 | 分析前/步间/增量内 | 分层缓存 |
| **Ctx（上下文型）** | L4+L5 | "当前环境" - 热路径临时缓冲 | 读写（栈上分配） | 单次调用或增量步 | 固定大小，禁止 ALLOCATABLE |

### 1.2 域级识别原则

**已识别的 14 个域级**（按 UFC 六层架构）：

| 编号 | 域名 | 说明 | 跨越层级 | 优先级 |
|------|------|------|---------|--------|
| D01 | **Material** | 材料本构 | L3_MD + L4_PH | P0（已完成） |
| D02 | **Element** | 单元公式 | L3_MD + L4_PH | P0（已完成） |
| D03 | **Section** | 截面桥梁 | L3_MD only | P0（已完成） |
| D04 | **Part** | 部件几何 | L3_MD only | P1 |
| D05 | **Assembly** | 装配体 | L3_MD only | P1 |
| D06 | **Step** | 分析步配置 | L3_MD + L5_RT | P1 |
| D07 | **Load** | 载荷 | L3_MD + L4_PH + L5_RT | P1（进行中） |
| D08 | **BC** | 边界条件 | L3_MD + L4_PH + L5_RT | P1（进行中） |
| D09 | **Constraint** | 约束方程 | L3_MD + L4_PH + L5_RT | P1 |
| D10 | **Contact** | 接触对 | L3_MD + L4_PH + L5_RT | P2 |
| D11 | **Interaction** | 相互作用 | L3_MD + L4_PH | P2 |
| D12 | **Output** | 输出请求 | L3_MD + L5_RT | P2 |
| D13 | **Solver** | 求解器配置 | L5_RT + L4_PH | P2 |
| D14 | **Mesh** | 网格拓扑 | L3_MD only | P1 |

---

## 二、详细清单（按域级分类）

### 2.1 Material 域（材料本构）

**状态**：✅ 已完成（参考 `L3MD_Type_System_Design.md Part VI-VIII`）

#### L3_MD 层（冷路径）

| 类型名 | 四大类 | 字段清单 | 来源文件 | ABAQUS 映射 |
|--------|--------|---------|---------|------------|
| `MD_Mat_Base_Desc` | Desc | mat_id, mat_name, mat_model_id, density, nprops, props(:) | `MD_Mat_Types.f90` | *MATERIAL |
| `MD_Mat_Elas_Desc` | Desc (扩展) | youngs_mod, poisson_ratio | `MD_Mat_ELA_Types.f90` | *ELASTIC |
| `MD_Mat_Plast_Des c` | Desc (扩展) | yield_stress, plastic_strain(:), hardening_type | `MD_Mat_PLA_Types.f90` | *PLASTIC |

#### L4_PH 层（热路径）

| 类型名 | 四大类 | 字段清单 | 来源文件 | 理论依据 |
|--------|--------|---------|---------|---------|
| `PH_Mat_State` | State | stress(6), strain(6), statev(:), C_tan(6,6) | `PH_Mat_Types.f90` | 本构积分算法 |
| `PH_Mat_Ctx` | Ctx | dstran(6), dfgrd1(3,3), temp, dtemp | `PH_Mat_Types.f90` | UMAT 接口变量 |
| `PH_Mat_Algo` | Algo | max_iter, tolerance, integ_scheme | `PH_Mat_Types.f90` | Newton 迭代控制 |

#### L5_RT 层（框架调度）

| 类型名 | 四大类 | 字段清单 | 来源文件 | 说明 |
|--------|--------|---------|---------|------|
| `RT_Common_Ctx` | Ctx | kstep, kinc, time, dt, nlgeom, lflags(6) | `RT_Com_Types.f90` | UMAT/UEL 共享上下文 |

---

### 2.2 Element 域（单元公式）

**状态**：✅ 已完成

#### L3_MD 层

| 类型名 | 四大类 | 字段清单 | 来源文件 |
|--------|--------|---------|---------|
| `MD_Elem_Base_Desc` | Desc | nnode, ndofel, mcrd, jtype, nprops, props(:) | `MD_Elem_Types.f90` |

#### L4_PH 层

| 类型名 | 四大类 | 字段清单 | 来源文件 |
|--------|--------|---------|---------|
| `PH_Elem_State` | State | rhs(ndofel), amatrx(ndofel,ndofel), svars(:), energy(8) | `PH_Elem_Types.f90` |
| `PH_Elem_Ctx` | Ctx | coords(mcrd,nnode), du(ndofel,nnode), predef(npredef) | `PH_Elem_Types.f90` |
| `PH_Elem_Algo` | Algo | params(3) [Newmark γ, β, α] | `PH_Elem_Types.f90` |

---

### 2.3 Section 域（截面属性）

**状态**：✅ 已完成

#### L3_MD 层

| 类型名 | 四大类 | 字段清单 | 来源文件 |
|--------|--------|---------|---------|
| `MD_Sect_Base_Desc` | Desc | section_id, section_type, mat_ids(:), thickness, offset | `MD_Sect_Types.f90` |

---

### 2.4 Load 域（载荷）⭐ 重点提取

**状态**：🔄 进行中（基于 `MD_LoadBC_Types.f90` + `PH_Load_Types.f90`）

#### L3_MD 层（冷路径 · Desc 专属）

| 类型名 | 四大类 | 字段清单 | 语义说明 | 来源文件行号 |
|--------|--------|---------|---------|------------|
| `MD_BC_Def_Type` | Desc | id, name, stepId, nodeSet, dof, magnitude, ampName, type, isFixed | BC 定义：u(t) = u_0 × A(t) | `MD_LoadBC_Types.f90:45-60` |
| `MD_Load_Def_Type` | Desc | id, name, stepId, loadType, target, magnitude(3), ampName, dof | 载荷定义：F(t) = F_0 × A(t) | `MD_LoadBC_Types.f90:70-95` |
| `MD_InitialCond_Def_Type` | Desc | id, name, type, nodeSet, nDofs, values(:) | 初始条件：u_0, v_0, T_0 | `MD_LoadBC_Types.f90:105-116` |
| `MD_PredefinedField_Type` | Desc | id, name, stepId, fieldType, region, fieldData(:,:), ampName | 预定义场（温度/应力） | `MD_LoadBC_Types.f90:123-131` |

**ABAQUS 关键字映射**：
- `*BOUNDARY` → MD_BC_Def_Type (DISPLACEMENT/ROTATION/TEMPERATURE)
- `*CLOAD` → MD_Load_Def_Type (loadType="CLOAD")
- `*DLOAD` → MD_Load_Def_Type (loadType="DLOAD")
- `*GRAVITY` → MD_Load_Def_Type (loadType="GRAVITY")
- `*INITIAL CONDITIONS` → MD_InitialCond_Def_Type
- `*PREDEFINED FIELDS` → MD_PredefinedField_Type

#### L4_PH 层（热路径 · State/Ctx）

| 类型名 | 四大类 | 字段清单 | 语义说明 | 来源文件行号 |
|--------|--------|---------|---------|------------|
| `PH_ElemEquivForce_Type` | State | elemId, nNodes, nodeIds(:), equiv_forces(:,:) | 单元等效节点力：F_elem = ∫N^T·t dS | `PH_Load_Types.f90:67-72` |
| `PH_SurfaceTraction_Type` | State | surfaceName, nFaces, faceIds(:), traction(:,:) | 表面牵引力：t(ξ,η) | `PH_Load_Types.f90:75-80` |
| `PH_Load_Integration_Type` | Algo | quad_order, use_nodal_lumping, use_reduced_integration | 积分策略（Gauss 阶数/缩聚） | `PH_Load_Types.f90:83-87` |
| `PH_Load_Cache_Type` | Ctx | loadId, loadType, target, magnitude(3), current_time, amp_factor | 当前步载荷缓存（热路径临时缓冲） | `PH_Load_Types.f90:90-97` |
| `PH_LoadCtrl_Type` | State (聚合) | integration, load_vector(:), elem_equiv_forces(:), surface_tractions(:), gravity_vector(3), load_cache(:) | 载荷控制器（全局载荷向量组装） | `PH_Load_Types.f90:100-124` |

**理论公式**：
```fortran
! 1. 集中力：F_i = f_i (直接节点组装)
! 2. 分布载荷：F_elem = ∫N^T·t dS (表面积分)
! 3. 体力：F_elem = ∫N^T·b dV (体积分)
! 4. 压力载荷：F_elem = ∫N^T·p·n dS (法向量)
! 5. 重力：F = M·g (质量矩阵×加速度)
```

#### L5_RT 层（框架调度 · Ctx/Algo）

**待提取**（从 `RT_Cont_Algo.f90` + `RT_Driver_Core.f90` 推断）：

| 预期类型名 | 四大类 | 预期字段 | 说明 |
|-----------|--------|---------|------|
| `RT_Load_Ctx` | Ctx | step_time, total_time, time_increment, step_number, increment_number | 框架时间上下文 |
| `RT_Load_Algo` | Algo | auto_stabilize, viscous_factor, load_cutback_tolerance | 载荷步控制算法 |

---

### 2.5 BC 域（边界条件）⭐ 重点提取

**状态**：🔄 进行中

#### L3_MD 层（Desc 专属）

已在 `MD_LoadBC_Types.f90:45-60` 定义（见 2.4 Load 域）

#### L4_PH 层（State/Ctx）

**待补全**（预期在 `PH_BC_Types.f90`）：

| 预期类型名 | 四大类 | 预期字段 | 说明 |
|-----------|--------|---------|------|
| `PH_BC_State` | State | current_value, reaction_force, penetration_gap | BC 当前值 + 反力 |
| `PH_BC_Ctx` | Ctx | prescribed_value, prescribed_delta, rotation_matrix(3,3) | BC 驱动值 + 增量 |
| `PH_BC_Algo` | Algo | tolerance, penalty_factor, constraint_method | BC 施加算法（罚函数/拉格朗日） |

#### L5_RT 层（Ctx/Algo）

**待提取**：

| 预期类型名 | 四大类 | 预期字段 | 说明 |
|-----------|--------|---------|------|
| `RT_BC_Ctx` | Ctx | step_time, kstep, kinc, analysis_type, nlgeom | 框架上下文 |
| `RT_BC_Algo` | Algo | adjust_initial_bc, overclosure_tolerance | BC 初始调整 |

---

### 2.6 Contact 域（接触对）⭐ 重点提取

**状态**：📋 规划中（基于 `RT_Cont_Algo.f90` + Markdown KEYWORD 映射）

#### L3_MD 层（Desc 专属）

**预期类型**（从 ABAQUS `*CONTACT PAIR` 推断）：

| 预期类型名 | 四大类 | 预期字段 | ABAQUS 映射 |
|-----------|--------|---------|------------|
| `MD_Contact_Pair_Desc` | Desc | contact_id, master_surf, slave_surf, formulation, friction_coeff | *CONTACT PAIR |
| `MD_Contact_Prop_Desc` | Desc | prop_id, pressure_overclosure, stiffness, damping | *CONTACT PROPERTY |

#### L4_PH 层（State/Ctx/Algo）

**预期类型**（从 `PH_Contact` 目录推断）：

| 预期类型名 | 四大类 | 预期字段 | 说明 |
|-----------|--------|---------|------|
| `PH_Contact_State` | State | gap(:), pressure(:), slip_distance(:), bond_damage(:) | 接触状态变量 |
| `PH_Contact_Ctx` | Ctx | normal_vec(:,:), tangent_vec(:,:), contact_status(:) | 接触局部坐标系 |
| `PH_Contact_Algo` | Algo | penalty_stiffness, tolerance, max_augmentations, friction_model | 接触算法参数 |

#### L5_RT 层（Ctx/Algo）

**已部分实现**（`RT_Cont_Algo.f90`）：

| 类型名 | 四大类 | 字段清单（预期） | 说明 |
|--------|--------|----------------|------|
| `RT_Contact_Ctx` | Ctx | global_iter, contact_iter, stabilization_factor | 接触迭代上下文 |
| `RT_Contact_Algo` | Algo | auto_adjust_gap, overclosure_tol, cutback_strategy | 接触步控制 |

**ABAQUS 关键字映射**（来自 `Markdown/KEYWORD`）：
- `*CONTACT` → 通用接触定义
- `*CONTACT PAIR` → 接触对定义
- `*CONTACT PROPERTY` → 接触属性
- `*FRICTION` → 摩擦模型
- `*CLEARANCE` → 初始间隙

---

### 2.7 Constraint 域（约束方程）

**状态**：📋 规划中

#### L3_MD 层（Desc 专属）

**预期类型**（从 ABAQUS `*CONSTRAINT` 推断）：

| 预期类型名 | 四大类 | 预期字段 | ABAQUS 映射 |
|-----------|--------|---------|------------|
| `MD_Constraint_MPC_Desc` | Desc | constraint_id, ref_node, member_nodes(:), mpc_type | *MPC (RBE2/RBE3) |
| `MD_Constraint_Tie_Desc` | Desc | tie_id, master_surf, slave_surf, position_tolerance | *TIE |
| `MD_Constraint_Coupling_Desc` | Desc | coupling_id, ref_node, coupled_nodes(:), dof_mask | *COUPLING |

#### L4_PH 层（State/Ctx/Algo）

**预期类型**：

| 预期类型名 | 四大类 | 预期字段 | 说明 |
|-----------|--------|---------|------|
| `PH_Constraint_State` | State | lagrange_mult(:), constraint_force(:), violation(:) | 拉格朗日乘子 + 约束力 |
| `PH_Constraint_Ctx` | Ctx | current_jacobian(:,:), active_flag(:) | 约束雅可比矩阵 |
| `PH_Constraint_Algo` | Algo | tolerance, weight_factor, enforcement_method | 约束施加方法 |

#### L5_RT 层（Ctx/Algo）

| 预期类型名 | 四大类 | 预期字段 | 说明 |
|-----------|--------|---------|------|
| `RT_Constraint_Ctx` | Ctx | is_broken, failure_mode | 约束失效状态 |
| `RT_Constraint_Algo` | Algo | failure_criterion, auto_release | 约束自动释放 |

---

### 2.8 Step 域（分析步配置）

**状态**：📋 规划中（部分在 `RT_Step_Type.f90`）

#### L3_MD 层（Desc 专属）

**预期类型**（从 ABAQUS `*STEP` 推断）：

| 预期类型名 | 四大类 | 预期字段 | ABAQUS 映射 |
|-----------|--------|---------|------------|
| `MD_Step_Base_Desc` | Desc | step_id, step_name, step_type, time_period, nlgeom_flag | *STEP |
| `MD_Step_Static_Desc` | Desc (扩展) | stabilizaton, unsymmetric_matrix | *STATIC |
| `MD_Step_Dynamic_Desc` | Desc (扩展) | alpha_param, beta_param, gamma_param | *DYNAMIC |

#### L5_RT 层（Ctx/Algo）

**已部分实现**（`RT_Step_Type.f90`）：

| 类型名 | 四大类 | 字段清单 | 来源文件行号 |
|--------|--------|---------|------------|
| `RT_Step_Ctx` | Ctx | step_idx, incr_idx, iter_idx, model, current_time, step_time | `RT_Step_Type.f90:108-` |
| `RT_Step_Algo` | Algo | time_auto_cut, adaptive_dt_params, cutback_ratio | （待提取） |

---

### 2.9 Mesh 域（网格拓扑）

**状态**：📋 规划中

#### L3_MD 层（Desc 专属）

**预期类型**：

| 预期类型名 | 四大类 | 预期字段 | 说明 |
|-----------|--------|---------|------|
| `MD_Mesh_Node_Desc` | Desc | node_id, coords(3), node_set_id | 节点坐标 |
| `MD_Mesh_Elem_Desc` | Desc | elem_id, connectivity(:), elem_type, section_id | 单元连接性 |
| `MD_Mesh_Set_Desc` | Desc | set_id, set_type, member_ids(:) | 节点集/单元集 |

---

### 2.10 Output 域（输出请求）

**状态**：✅ 已部分实现（`MD_Out_Types.f90`）

#### L3_MD 层（Desc 专属）

| 类型名 | 四大类 | 字段清单 | 来源文件 |
|--------|--------|---------|---------|
| `MD_OutFrequency_Type` | Desc | frequency_type, interval, time_interval, time_points(:) | `MD_Out_Types.f90:93-99` |
| `MD_OutVariable_Type` | Desc | name, category, description, output_invariants | `MD_Out_Types.f90:108-` |
| `MD_FieldOut_Type` | Desc | output_name, variables(:), region, frequency | `MD_Out_Types.f90` |
| `MD_HistOut_Type` | Desc | output_name, variables(:), frequency | `MD_Out_Types.f90` |

#### L5_RT 层（Ctx）

| 预期类型名 | 四大类 | 预期字段 | 说明 |
|-----------|--------|---------|------|
| `RT_Output_Ctx` | Ctx | current_frame, write_flag, file_unit | 输出运行时上下文 |

---

## 三、完整矩阵表（14 域 × 3 层 × 4 类型）

> ✅ = 已完成 | 🔄 = 进行中 | 📋 = 规划中 | — = 不存在（如 L4 无 Desc）

| 域级 | L3_MD Desc | L3_MD State | L3_MD Algo | L4_PH Desc | L4_PH State | L4_PH Ctx | L4_PH Algo | L5_RT Desc | L5_RT State | L5_RT Ctx | L5_RT Algo |
|------|----------|-----------|----------|----------|-----------|---------|----------|----------|-----------|---------|----------|
| **Material** | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ | — | — | ✅ | — |
| **Element** | ✅ | — | — | — | ✅ | ✅ | ✅ | — | — | — | — |
| **Section** | ✅ | — | — | — | — | — | — | — | — | — | — |
| **Part** | 📋 | — | — | — | — | — | — | — | — | — | — |
| **Assembly** | 📋 | — | — | — | — | — | — | — | — | — | — |
| **Step** | 📋 | — | 📋 | — | — | — | — | — | — | ✅ | 📋 |
| **Load** | ✅ | — | — | — | ✅ | ✅ | ✅ | — | — | 📋 | 📋 |
| **BC** | ✅ | — | — | — | 📋 | 📋 | 📋 | — | — | 📋 | 📋 |
| **Constraint** | 📋 | — | 📋 | — | 📋 | 📋 | 📋 | — | — | 📋 | 📋 |
| **Contact** | 📋 | — | 📋 | — | 📋 | 📋 | 📋 | — | — | 📋 | ✅ |
| **Interaction** | 📋 | — | 📋 | — | 📋 | — | — | — | — | — | — |
| **Output** | ✅ | — | — | — | — | — | — | — | — | 📋 | — |
| **Mesh** | 📋 | — | — | — | — | — | — | — | — | — | — |
| **Solver** | — | — | 📋 | — | 📋 | — | 📋 | — | — | — | 📋 |

---

## 四、下一步行动计划

### Phase 1：完成 Load/BC 域详细设计（P1 优先级）

| 任务 | 产出文件 | 预计周期 | 依赖 |
|------|---------|---------|------|
| 1.1 提取 L3_MD Load/BC 完整 Desc | `MD_LoadBC_Types.f90` | 2 天 | 现有代码审查 |
| 1.2 设计 L4_PH Load State/Ctx | `PH_Load_Types.f90` | 3 天 | ABAQUS 手册映射 |
| 1.3 设计 L4_PH BC State/Ctx | `PH_BC_Types.f90` | 3 天 | 同上 |
| 1.4 提取 L5_RT Load/BC Ctx/Algo | `RT_LoadBC_Types.f90` | 2 天 | RT_Step_Type 参考 |

### Phase 2：完成 Contact/Constraint 域（P1 优先级）

| 任务 | 产出文件 | 预计周期 |
|------|---------|---------|
| 2.1 提取 L3_MD Contact Desc | `MD_Contact_Types.f90` | 3 天 |
| 2.2 设计 L4_PH Contact State/Ctx/Algo | `PH_Contact_Types.f90` | 4 天 |
| 2.3 提取 L5_RT Contact Ctx/Algo | 扩展现有 `RT_Cont_*` | 3 天 |
| 2.4 Constraint 域三大层设计 | `MD_Constraint_*` + `PH_Constraint_*` | 5 天 |

### Phase 3：补全其他域级（P2 优先级）

| 任务 | 产出 | 周期 |
|------|------|------|
| 3.1 Step 域完整设计 | `MD_Step_Types.f90` + `RT_Step_Types.f90` | 3 天 |
| 3.2 Mesh 域 Desc 设计 | `MD_Mesh_Complete_Types.f90` | 2 天 |
| 3.3 Output 域补全 | `MD_Out_Types.f90` + `RT_Output_Types.f90` | 2 天 |
| 3.4 Solver 域 Algo 设计 | `PH_Solver_Algo.f90` + `RT_Solver_Types.f90` | 3 天 |

### Phase 4：整合验证（P2 优先级）

| 任务 | 说明 | 周期 |
|------|------|------|
| 4.1 单步非线性静力分析 | Load+BC+Contact 协同验证 | 5 天 |
| 4.2 多步分析 | Step 切换 + 载荷序列验证 | 3 天 |
| 4.3 输出完整性检查 | Field/History Output 全链路 | 2 天 |

---

## 五、提取自 Markdown 文档的关键映射

### 5.1 ABAQUS 关键字 → UFC 类型映射（来自 `KEYWORD.md`）

| ABAQUS 关键字 | UFC L3_MD Desc | UFC L4_PH State/Ctx | UFC L5_RT Ctx/Algo |
|--------------|---------------|-------------------|------------------|
| `*MATERIAL` | MD_Mat_Base_Desc | — | — |
| `*ELASTIC` | MD_Mat_Elas_Desc | — | — |
| `*PLASTIC` | MD_Mat_Plast_Desc | PH_Plast_State(statev) | — |
| `*STEP` | MD_Step_Base_Desc | — | RT_Step_Ctx |
| `*STATIC` | MD_Step_Static_Desc | — | RT_Static_Algo |
| `*DYNAMIC` | MD_Step_Dynamic_Desc | — | RT_Dyn_Algo |
| `*BOUNDARY` | MD_BC_Def_Type | PH_BC_State/Ctx | RT_BC_Ctx |
| `*CLOAD` | MD_Load_Def_Type | PH_Load_Cache | RT_Load_Ctx |
| `*DLOAD` | MD_Load_Def_Type | PH_SurfaceTraction | — |
| `*GRAVITY` | MD_Load_Def_Type | PH_LoadCtrl(gravity) | — |
| `*CONTACT PAIR` | MD_Contact_Pair_Desc | PH_Contact_State | RT_Cont_Ctx |
| `*FRICTION` | MD_Contact_Frict_Desc | PH_Contact_State(slip) | RT_Cont_Algo |
| `*MPC` | MD_Constraint_MPC_Desc | PH_Constraint_State | — |
| `*TIE` | MD_Constraint_Tie_Desc | PH_Constraint_State | — |
| `*OUTPUT` | MD_Out_Field/Hist_Type | — | RT_Output_Ctx |

### 5.2 ANALYSIS 手册章节 → UFC 域级映射（来自 `ANALYSIS_1.md` 等）

| ABAQUS章节 | UFC 域级 | 关键变量/参数 |
|------------|---------|--------------|
| Chapter 2: Spatial Modeling | Mesh/Assembly | node_coords, elem_connectivity |
| Chapter 21-26: Materials | Material | E, ν, σ_y, H' |
| Chapter 27-33: Elements | Element | B-matrix, J-det, N-shape |
| Chapter 34: Prescribed Conditions | Load/BC | F(t), u_0, A(t) |
| Chapter 35: Constraints | Constraint | MPC equations, tie constraints |
| Chapter 36-41: Interactions | Contact | gap, p, μ, τ_f |

---

## 六、命名规范速查

### 6.1 四大类后缀规则

```fortran
! L3_MD 层：MD_XXX_Desc / MD_XXX_State / MD_XXX_Algo / MD_XXX_Ctx
TYPE :: MD_Mat_Base_Desc    ! ✅ Desc：材料描述
TYPE :: MD_Mat_Base_State   ! ✅ State：材料状态（如有）

! L4_PH 层：PH_XXX_Desc / PH_XXX_State / PH_XXX_Ctx / PH_XXX_Algo
TYPE :: PH_Mat_State        ! ✅ State：材料计算状态
TYPE :: PH_Mat_Ctx          ! ✅ Ctx：材料上下文
TYPE :: PH_Mat_Algo         ! ✅ Algo：材料算法参数

! L5_RT 层：RT_XXX_Desc / RT_XXX_State / RT_XXX_Ctx / RT_XXX_Algo
TYPE :: RT_Common_Ctx       ! ✅ Ctx：通用运行时上下文
TYPE :: RT_Step_Ctx         ! ✅ Ctx：分析步上下文
```

### 6.2 不对称矩阵规则

| 层级 | 有 Desc | 有 State | 有 Ctx | 有 Algo |
|------|-------|--------|-------|--------|
| **L3_MD** | ✅ 专属 | ⚠️ 少量 | ❌ 无 | ⚠️ 配置 |
| **L4_PH** | ❌ 无 | ✅ 专属 | ✅ 专属 | ✅ 专属 |
| **L5_RT** | ❌ 无 | ⚠️ 少量 | ✅ 专属 | ✅ 专属 |

**记忆口诀**：
- L3 冷：Desc 主战场，State 偶尔出现（如 WriteBack），无 Ctx
- L4 热：State+Ctx+Algo 三驾马车，无 Desc（从 L3 投影而来）
- L5 调度：Ctx+Algo 双轮驱动，Desc/State 极少

---

## 七、待确认问题清单

### Q1：Load/BC 的 State 是否应该在 L4_PH 存在？

**争议点**：
- 正方：Load/BC 有幅值插值、跟随力更新、疲劳计数等动态状态，应该有 State
- 反方：Load/BC 只是"加载"动作，State 应该归入 Material/Element 响应

**建议方案**：保留 `PH_Load_State` 和 `PH_BC_State`，用于存储：
- 当前载荷幅值 `current_magnitude`
- 累积做功 `accumulated_work`
- 反力 `reaction_force`
- 穿透间隙 `penetration_gap`

### Q2：Contact 的 Algo 应该分几层？

**建议方案**：三层分离
- L3_MD Algo：接触公式选择（Penalty/Augmented Lagrange/Mortar）
- L4_PH Algo：迭代控制参数（penalty_stiffness, tolerance, max_aug）
- L5_RT Algo：步级调度（auto_adjust_gap, cutback_strategy）

### Q3：Ctx 是否允许 ALLOCATABLE？

**严格模式**（推荐）：❌ 禁止
- 理由：Ctx 是热路径临时缓冲，ALLOCATABLE 破坏缓存连续性

**宽松模式**：⚠️ 条件允许
- 条件：只在 L5_RT Ctx 允许（如 `RT_Output_Ctx%file_buffer(:)`）
- 禁止：L4_PH Ctx 严禁 ALLOCATABLE

---

## 八、版本历史

| 版本 | 日期 | 更新内容 | 状态 |
|------|------|---------|------|
| v1.0 | 2026-03-27 | 初稿：Material/Element/Section/Load(部分)/BC(部分) | 🔄 进行中 |
| v0.1 | 2026-03-26 | 框架搭建：14 域级识别 + 三维矩阵设计 | ✅ 已完成 |

---

## 九、使用说明

### 9.1 如何使用本文档

1. **查找某域级的完整设计**：
   - 直接跳转到对应章节（如 2.4 Load 域）
   - 查看 L3/L4/L5三层的四大类表格

2. **查找某变量的归类**：
   - 使用全文搜索（Ctrl+F）搜索变量名
   - 或在对应域级的表格中查找

3. **查找 ABAQUS 映射**：
   - 查看 5.1 节「ABAQUS 关键字 → UFC 类型映射」
   - 或搜索关键字（如 `*CONTACT PAIR`）

### 9.2 如何贡献/修正

1. **发现缺失的类型**：
   - 在对应域级表格中添加新行
   - 标注来源文件行号
   - 更新状态标记（📋→🔄→✅）

2. **发现错误的归类**：
   - 在「待确认问题清单」中添加新问题
   - 或直接修正并更新版本历史

3. **补充 ABAQUS 映射**：
   - 阅读 `Markdown/KEYWORD/*.md` 或 `ANALYSIS_*.md`
   - 提取关键变量到 5.1/5.2 节表格

---

**文档维护者**：UFC 架构组  
**最后更新**：2026-03-27  
**下次审查**：完成 Phase 1 后（预计 2026-04-03）
