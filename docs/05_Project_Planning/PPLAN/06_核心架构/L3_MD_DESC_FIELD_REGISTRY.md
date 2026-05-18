# L3_MD Desc 字段注册表

> 状态: CORE | 创建: 2026-04-26 | 版本: v1.0
> 关联: L3_MD_DESIGN_DECISIONS.md (议题8)

## 命名约定

| 字段类型 | 命名模式 | 示例 |
|---------|---------|------|
| 引用 ID | `{语义}_id` | `material_id`, `section_id`, `step_ref` |
| 枚举类型 | `{语义}_type` | `amp_type`, `mat_type`, `section_type` |
| 计数 | `n_{语义}` | `n_parts`, `n_steps`, `n_materials` |
| 字符串名称 | `{语义}_name` 或 `name` | `step_name`, `model_name` |
| 布尔标志 | `is_{语义}` 或 `{语义}` (LOGICAL) | `is_active`, `nlgeom`, `smooth` |
| 浮点参数 | 语义明确名称 | `time_period`, `penalty_factor` |
| 固定数组 | `{语义}(MAX_CONST)` | `parts(MD_PART_MAX)` |
| 动态数组 | `{语义}`, ALLOCATABLE | `time_data(:)`, `load_ids(:)` |

---

## 权威 Desc TYPE 注册表

### 约定

- **A**: 权威 (Authoritative) -- 运行时使用的版本
- **L**: 遗留 (Legacy) -- 仍存在但不应扩展
- **D**: 重复 (Duplicate) -- 与 A 版本字段不同，需统一

### Model 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Model_Desc` | `Model/MD_ModelDomain.f90` (MODULE MD_Model) | **A** | model_name(256), spatial_dim, analysis_type, 8 count 字段 |
| `MD_Model_Desc` | `Model/MD_Model_Def.f90` | **L** | name(128), ndim, n_parts, n_steps, part_ids(256), step_ids(100) |

### Part 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Part_Desc` | `Part/MD_Part_Def.f90` | **A** | parts(MD_PART_MAX) :: MD_PartEntry, n_parts |
| `MD_PartEntry` | `Part/MD_Part_Def.f90` | **A** | id, name(64), section_id, valid |

### Assembly 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Assembly_Desc` | `Assembly/MD_Assembly_Def.f90` | **A** | instances(MD_ASM_MAX_INSTANCES), n_instances, global_node_map => NULL, n_global_nodes, n_eq |

### Mesh 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Mesh_Desc` | `Mesh/MD_Mesh_Def.f90` | **A** | n_nodes, n_elements, ndim, max_nn, coords/conn/elem_type POINTER, nodesets/elemsets |

### Section 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Section_Desc` | `Section/MD_Section_Def.f90` | **A** | sections(MD_SECTION_MAX) :: MD_SectionEntry, n_sections |
| `MD_SectDesc` | `Section/MD_Sect_Def.f90` | **A** | name(64), section_id, section_type, thickness, n_integration_pts, material_ref, orientation(3), n_layers |

### Material 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Material_Desc` | `Material/MD_Material_Def.f90` | **A** | materials(MD_MAT_MAX_MATERIALS) :: MD_MaterialEntry, n_materials |

### Amplitude 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Amp_Desc` | `Analysis/Amplitude/MD_Amp_Def.f90` | **A** | name(64), amp_id, amp_type, definition, time_data(:)/value_data(:), n_points, smooth/omega/periodic/modulated/decay fields, tabular_extrapolate |
| `MD_Amp_Tabular_Desc` | `Analysis/Amplitude/MD_Amp_Def.f90` | **A** | 表格幅值特化 |
| `MD_Amp_User_Desc` | `Analysis/Amplitude/MD_Amp_Def.f90` | **A** | 用户子程序幅值 |
| `MD_Amp_Periodic_Desc` | `Analysis/Amplitude/MD_Amp_Def.f90` | **A** | 周期性幅值 |
| `MD_Amp_Modulated_Desc` | `Analysis/Amplitude/MD_Amp_Def.f90` | **A** | 调制幅值 |

### Step 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Step_Desc` | `Analysis/Step/MD_Step.f90` | **A** | name(64), step_number, procedure, nlgeom, time_period, start_time, perturbation, load_ids(:), bc_ids(:), pair_ids(:), output_ids(:), solver_config_id, algo :: StepAlgo, current_time/increment, is_active/is_complete |

### Solver 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Solver_Desc` | `Analysis/Solver/MD_Solv_Def.f90` | **A** | 求解器配置描述 |

### Interaction 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Interaction_Desc` | `Interaction/MD_Interaction_Def.f90` | **A** | surfaces(MAX), n_surfaces, pairs(MAX), n_pairs |
| `MD_Interaction_Desc` | `Interaction/MD_Int_Def.f90` | **D** | interaction_name/id, contact_type, slave/master_surface, contact_pairs(:), surface_interactions(:), friction_models(:), output_format |

### LoadBC 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_LoadBC_Desc` | `Boundary/MD_LBC.f90` | **A** | nLoadBCs, parallel arrays: loadBCId/name/type/region/dofs/amplitude/value/direction/etc. |
| `MD_Boundary_Desc` | `Boundary/MD_Boundary_Def.f90` | **A** | bcs :: MD_BCEntry(:), n_bcs (BC-only 子集) |

### Constraint 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Constraint_Desc` | `Constraint/MD_Constraint_Def.f90` | **A** | constraints(MD_CONS_MAX), n_constraints |

### Output 域

| TYPE | 文件 | 状态 | 字段摘要 |
|------|------|------|---------|
| `MD_Output_Desc` | `Output/MD_Output_Def.f90` | **A** | requests(:), n_field_requests, n_history_requests |
| `MD_Output_Desc` | `Output/MD_Out_Def.f90` | **D** | output_name/id, output_type, variables(:), num_variables, target_set, frequency, time_interval, format, step_ref, element_position |

---

## 双重定义清理优先级

| 域 | 重复 TYPE | 清理策略 | 优先级 |
|----|----------|---------|--------|
| Model | `MD_Model_Desc` (2 个不同定义) | `MD_Model_Def.f90` 标记 Legacy，`MD_ModelDomain.f90` 为权威 | 中 |
| Interaction | `MD_Interaction_Desc` (2 个不同定义) | 统一到 `MD_Interaction_Def.f90`（注册表格式），`MD_Int_Def.f90` 标记 Legacy | 高 |
| Output | `MD_Output_Desc` (2 个不同定义) | 统一到 `MD_Output_Def.f90`（注册表格式），`MD_Out_Def.f90` 标记 Legacy | 中 |

---

## ABAQUS 关键字覆盖度（概要）

| 域 | 已覆盖关键字 | 未覆盖关键字（示例） |
|----|------------|-------------------|
| Part | *PART, *END PART | *PART INPUT |
| Assembly | *ASSEMBLY, *INSTANCE | *TRANSFORM |
| Section | *SOLID SECTION, *SHELL SECTION | *MEMBRANE SECTION, *BEAM GENERAL SECTION |
| Material | *MATERIAL, *ELASTIC, *PLASTIC, *DENSITY | *CREEP, *VISCOELASTIC (部分), *DAMPING |
| Step | *STEP, *STATIC, *DYNAMIC | *FREQUENCY, *HEAT TRANSFER, *COUPLED |
| LoadBC | *CLOAD, *DLOAD, *BOUNDARY | *DSLOAD, *FILM, *RADIATION |
| Amplitude | *AMPLITUDE (tabular, periodic, modulated, user) | *AMPLITUDE SMOOTH |
| Interaction | *CONTACT PAIR, *SURFACE INTERACTION | *GENERAL CONTACT |
| Constraint | *TIE, *COUPLING, *MPC, *RIGID BODY | *EMBEDDED ELEMENT |
| Output | *OUTPUT, *FIELD OUTPUT, *HISTORY OUTPUT | *ENERGY OUTPUT, *CONTACT OUTPUT |

> 注: 覆盖度为 Desc 字段层面的评估，非完整功能实现。
