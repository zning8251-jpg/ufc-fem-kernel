# `MD_KW_Mapper.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Mapper.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KW_Mapper`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Mapper`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW_Mapper`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Mapper.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `KW_MapperStateType` (lines 215–240)

```fortran
    TYPE, PUBLIC :: KW_MapperStateType
        TYPE(KW_ParserStateType), POINTER :: parser => NULL()
        TYPE(UF_ModelDef), POINTER :: model => NULL()
        
        ! Current context
        TYPE(UF_PartDef), POINTER :: current_part => NULL()
        TYPE(UF_InstanceDef), POINTER :: current_instance => NULL()
        TYPE(UF_MaterialDef), POINTER :: current_material => NULL()
        TYPE(UF_ContactPropertyDef), POINTER :: current_contact_prop => NULL()
        INTEGER(i4) :: current_step_idx = 0

        ! Performance optimization: Memory pool
        TYPE(MemoryPoolManager) :: memoryPool
        
        ! Statistics
        INTEGER(i4) :: nodes_mapped = 0
        INTEGER(i4) :: elements_mapped = 0
        INTEGER(i4) :: materials_mapped = 0
        INTEGER(i4) :: sections_mapped = 0
        INTEGER(i4) :: steps_mapped = 0
        
        ! Error tracking
        INTEGER(i4) :: error_count = 0
        INTEGER(i4) :: warning_count = 0
        LOGICAL :: stop_on_error = .FALSE.
    END TYPE KW_MapperStateType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `kw_mapper_init` | 256 | `SUBROUTINE kw_mapper_init(mapper, parser, model)` |
| SUBROUTINE | `kw_mapper_map_to_model` | 290 | `SUBROUTINE kw_mapper_map_to_model(mapper, success)` |
| SUBROUTINE | `map_structural_node` | 379 | `SUBROUTINE map_structural_node(mapper, node)` |
| SUBROUTINE | `map_mesh_node` | 409 | `SUBROUTINE map_mesh_node(mapper, node)` |
| SUBROUTINE | `map_property_node` | 457 | `SUBROUTINE map_property_node(mapper, node)` |
| SUBROUTINE | `map_equation` | 971 | `SUBROUTINE map_equation(mapper, node)` |
| SUBROUTINE | `md_kw_get_param_int` | 1049 | `SUBROUTINE md_kw_get_param_int(node, param_name, int_val, found)` |
| SUBROUTINE | `map_tie_constraint` | 1077 | `SUBROUTINE map_tie_constraint(mapper, node)` |
| SUBROUTINE | `map_coupling_constraint` | 1125 | `SUBROUTINE map_coupling_constraint(mapper, node)` |
| SUBROUTINE | `map_kinematic_coupling_constraint` | 1172 | `SUBROUTINE map_kinematic_coupling_constraint(mapper, node)` |
| SUBROUTINE | `map_distributing_coupling_constraint` | 1222 | `SUBROUTINE map_distributing_coupling_constraint(mapper, node)` |
| SUBROUTINE | `map_rigid_body_constraint` | 1270 | `SUBROUTINE map_rigid_body_constraint(mapper, node)` |
| SUBROUTINE | `map_analysis_node` | 1323 | `SUBROUTINE map_analysis_node(mapper, node)` |
| SUBROUTINE | `map_part` | 1475 | `SUBROUTINE map_part(mapper, node)` |
| SUBROUTINE | `map_instance` | 1499 | `SUBROUTINE map_instance(mapper, node)` |
| SUBROUTINE | `map_translate` | 1539 | `SUBROUTINE map_translate(mapper, node)` |
| SUBROUTINE | `map_nodes` | 1563 | `SUBROUTINE map_nodes(mapper, node)` |
| SUBROUTINE | `map_elements` | 1679 | `SUBROUTINE map_elements(mapper, node)` |
| SUBROUTINE | `map_nset` | 1777 | `SUBROUTINE map_nset(mapper, node)` |
| SUBROUTINE | `map_elset` | 1899 | `SUBROUTINE map_elset(mapper, node)` |
| SUBROUTINE | `map_surface` | 2005 | `SUBROUTINE map_surface(mapper, node)` |
| SUBROUTINE | `map_material` | 2196 | `SUBROUTINE map_material(mapper, node)` |
| SUBROUTINE | `map_elastic` | 2226 | `SUBROUTINE map_elastic(mapper, node)` |
| SUBROUTINE | `map_thermo_elastic_kw` | 2316 | `SUBROUTINE map_thermo_elastic_kw(mapper, node)` |
| SUBROUTINE | `map_piezo_elastic_kw` | 2357 | `SUBROUTINE map_piezo_elastic_kw(mapper, node)` |
| SUBROUTINE | `map_thermo_elec_elastic_kw` | 2389 | `SUBROUTINE map_thermo_elec_elastic_kw(mapper, node)` |
| SUBROUTINE | `map_hyperelastic` | 2424 | `SUBROUTINE map_hyperelastic(mapper, node)` |
| SUBROUTINE | `map_creep` | 2488 | `SUBROUTINE map_creep(mapper, node)` |
| SUBROUTINE | `map_damage_puck` | 2548 | `SUBROUTINE map_damage_puck(mapper, node)` |
| SUBROUTINE | `map_plastic` | 2595 | `SUBROUTINE map_plastic(mapper, node)` |
| SUBROUTINE | `map_surface_interaction` | 2635 | `SUBROUTINE map_surface_interaction(mapper, node)` |
| SUBROUTINE | `map_friction` | 2670 | `SUBROUTINE map_friction(mapper, node)` |
| SUBROUTINE | `map_density` | 2703 | `SUBROUTINE map_density(mapper, node)` |
| SUBROUTINE | `map_mass` | 2763 | `SUBROUTINE map_mass(mapper, node)` |
| SUBROUTINE | `map_rotary_inertia` | 2790 | `SUBROUTINE map_rotary_inertia(mapper, node)` |
| SUBROUTINE | `map_point_mass` | 2814 | `SUBROUTINE map_point_mass(mapper, node)` |
| SUBROUTINE | `map_nonstructural_mass` | 2839 | `SUBROUTINE map_nonstructural_mass(mapper, node)` |
| SUBROUTINE | `map_conductivity` | 2864 | `SUBROUTINE map_conductivity(mapper, node)` |
| SUBROUTINE | `map_specific_heat` | 2881 | `SUBROUTINE map_specific_heat(mapper, node)` |
| SUBROUTINE | `map_expansion` | 2898 | `SUBROUTINE map_expansion(mapper, node)` |
| SUBROUTINE | `map_uf_thermal` | 2947 | `SUBROUTINE map_uf_thermal(mapper, node)` |
| SUBROUTINE | `map_damping` | 2979 | `SUBROUTINE map_damping(mapper, node)` |
| SUBROUTINE | `map_viscosity` | 3015 | `SUBROUTINE map_viscosity(mapper, node)` |
| SUBROUTINE | `map_thermal_conductivity` | 3051 | `SUBROUTINE map_thermal_conductivity(mapper, node)` |
| SUBROUTINE | `map_permeability` | 3087 | `SUBROUTINE map_permeability(mapper, node)` |
| SUBROUTINE | `map_sorption` | 3123 | `SUBROUTINE map_sorption(mapper, node)` |
| SUBROUTINE | `map_sfilm` | 3158 | `SUBROUTINE map_sfilm(mapper, node)` |
| SUBROUTINE | `map_sradiation` | 3188 | `SUBROUTINE map_sradiation(mapper, node)` |
| SUBROUTINE | `map_specific_heat` | 3218 | `SUBROUTINE map_specific_heat(mapper, node)` |
| SUBROUTINE | `map_latent_heat` | 3253 | `SUBROUTINE map_latent_heat(mapper, node)` |
| SUBROUTINE | `map_joule_heat` | 3288 | `SUBROUTINE map_joule_heat(mapper, node)` |
| SUBROUTINE | `map_cohesive_behavior` | 3322 | `SUBROUTINE map_cohesive_behavior(mapper, node)` |
| SUBROUTINE | `map_damage_initiation` | 3348 | `SUBROUTINE map_damage_initiation(mapper, node)` |
| SUBROUTINE | `map_damage_evolution` | 3383 | `SUBROUTINE map_damage_evolution(mapper, node)` |
| SUBROUTINE | `map_progressive_damage` | 3418 | `SUBROUTINE map_progressive_damage(mapper, node)` |
| SUBROUTINE | `map_rate_dependent` | 3453 | `SUBROUTINE map_rate_dependent(mapper, node)` |
| SUBROUTINE | `map_visco` | 3487 | `SUBROUTINE map_visco(mapper, node)` |
| SUBROUTINE | `map_hyperfoam` | 3521 | `SUBROUTINE map_hyperfoam(mapper, node)` |
| SUBROUTINE | `map_hypoelastic` | 3556 | `SUBROUTINE map_hypoelastic(mapper, node)` |
| SUBROUTINE | `map_cap_plasticity` | 3591 | `SUBROUTINE map_cap_plasticity(mapper, node)` |
| SUBROUTINE | `map_crystal_plasticity` | 3626 | `SUBROUTINE map_crystal_plasticity(mapper, node)` |
| SUBROUTINE | `map_drucker_prager` | 3659 | `SUBROUTINE map_drucker_prager(mapper, node)` |
| SUBROUTINE | `map_mohr_coulomb` | 3694 | `SUBROUTINE map_mohr_coulomb(mapper, node)` |
| SUBROUTINE | `map_orientation` | 3729 | `SUBROUTINE map_orientation(mapper, node)` |
| SUBROUTINE | `map_transform` | 3752 | `SUBROUTINE map_transform(mapper, node)` |
| SUBROUTINE | `map_system` | 3775 | `SUBROUTINE map_system(mapper, node)` |
| SUBROUTINE | `map_normal` | 3801 | `SUBROUTINE map_normal(mapper, node)` |
| SUBROUTINE | `map_distribution` | 3824 | `SUBROUTINE map_distribution(mapper, node)` |
| SUBROUTINE | `map_table` | 3849 | `SUBROUTINE map_table(mapper, node)` |
| SUBROUTINE | `map_field` | 3873 | `SUBROUTINE map_field(mapper, node)` |
| SUBROUTINE | `map_parameter` | 3895 | `SUBROUTINE map_parameter(mapper, node)` |
| SUBROUTINE | `map_variable` | 3916 | `SUBROUTINE map_variable(mapper, node)` |
| SUBROUTINE | `map_filter` | 3937 | `SUBROUTINE map_filter(mapper, node)` |
| SUBROUTINE | `map_include` | 3958 | `SUBROUTINE map_include(mapper, node)` |
| SUBROUTINE | `map_preprint` | 3979 | `SUBROUTINE map_preprint(mapper, node)` |
| SUBROUTINE | `map_file_format` | 4001 | `SUBROUTINE map_file_format(mapper, node)` |
| SUBROUTINE | `map_physical_constants` | 4022 | `SUBROUTINE map_physical_constants(mapper, node)` |
| SUBROUTINE | `map_node_file` | 4043 | `SUBROUTINE map_node_file(mapper, node)` |
| SUBROUTINE | `map_el_file` | 4064 | `SUBROUTINE map_el_file(mapper, node)` |
| SUBROUTINE | `map_modal_damping` | 4085 | `SUBROUTINE map_modal_damping(mapper, node)` |
| SUBROUTINE | `map_steady_state_dynamics` | 4106 | `SUBROUTINE map_steady_state_dynamics(mapper, node)` |
| SUBROUTINE | `map_direct` | 4127 | `SUBROUTINE map_direct(mapper, node)` |
| SUBROUTINE | `map_substructure` | 4148 | `SUBROUTINE map_substructure(mapper, node)` |
| SUBROUTINE | `map_modal_dynamic` | 4169 | `SUBROUTINE map_modal_dynamic(mapper, node)` |
| SUBROUTINE | `map_complex_frequency` | 4190 | `SUBROUTINE map_complex_frequency(mapper, node)` |
| SUBROUTINE | `map_response_spectrum` | 4211 | `SUBROUTINE map_response_spectrum(mapper, node)` |
| SUBROUTINE | `map_user_material` | 4232 | `SUBROUTINE map_user_material(mapper, node)` |
| SUBROUTINE | `map_user_element` | 4266 | `SUBROUTINE map_user_element(mapper, node)` |
| SUBROUTINE | `map_user_defined_field` | 4278 | `SUBROUTINE map_user_defined_field(mapper, node)` |
| SUBROUTINE | `map_user_load` | 4310 | `SUBROUTINE map_user_load(mapper, node)` |
| SUBROUTINE | `map_user_contact` | 4331 | `SUBROUTINE map_user_contact(mapper, node)` |
| SUBROUTINE | `map_user_output` | 4352 | `SUBROUTINE map_user_output(mapper, node)` |
| SUBROUTINE | `map_user_amplitude` | 4373 | `SUBROUTINE map_user_amplitude(mapper, node)` |
| SUBROUTINE | `map_user_subroutine` | 4394 | `SUBROUTINE map_user_subroutine(mapper, node)` |
| SUBROUTINE | `map_design_response` | 4440 | `SUBROUTINE map_design_response(mapper, node)` |
| SUBROUTINE | `map_objective` | 4458 | `SUBROUTINE map_objective(mapper, node)` |
| SUBROUTINE | `map_design_variable` | 4476 | `SUBROUTINE map_design_variable(mapper, node)` |
| SUBROUTINE | `map_optimization_constraint` | 4494 | `SUBROUTINE map_optimization_constraint(mapper, node)` |
| SUBROUTINE | `map_sensitivity` | 4511 | `SUBROUTINE map_sensitivity(mapper, node)` |
| SUBROUTINE | `map_topology_optimization` | 4528 | `SUBROUTINE map_topology_optimization(mapper, node)` |
| SUBROUTINE | `map_shape_optimization` | 4545 | `SUBROUTINE map_shape_optimization(mapper, node)` |
| SUBROUTINE | `map_size_optimization` | 4562 | `SUBROUTINE map_size_optimization(mapper, node)` |
| SUBROUTINE | `map_optimization_controls` | 4580 | `SUBROUTINE map_optimization_controls(mapper, node)` |
| SUBROUTINE | `map_optimization_history` | 4598 | `SUBROUTINE map_optimization_history(mapper, node)` |
| SUBROUTINE | `map_connector` | 4615 | `SUBROUTINE map_connector(mapper, node)` |
| SUBROUTINE | `map_connector_behavior` | 4632 | `SUBROUTINE map_connector_behavior(mapper, node)` |
| SUBROUTINE | `map_connector_section` | 4650 | `SUBROUTINE map_connector_section(mapper, node)` |
| SUBROUTINE | `map_joint` | 4667 | `SUBROUTINE map_joint(mapper, node)` |
| SUBROUTINE | `map_bushing` | 4685 | `SUBROUTINE map_bushing(mapper, node)` |
| SUBROUTINE | `map_spring` | 4702 | `SUBROUTINE map_spring(mapper, node)` |
| SUBROUTINE | `map_dashpot` | 4720 | `SUBROUTINE map_dashpot(mapper, node)` |
| SUBROUTINE | `map_kinematic` | 4738 | `SUBROUTINE map_kinematic(mapper, node)` |
| SUBROUTINE | `map_motion` | 4755 | `SUBROUTINE map_motion(mapper, node)` |
| SUBROUTINE | `map_velocity` | 4773 | `SUBROUTINE map_velocity(mapper, node)` |
| SUBROUTINE | `map_acceleration` | 4791 | `SUBROUTINE map_acceleration(mapper, node)` |
| SUBROUTINE | `map_base_motion` | 4809 | `SUBROUTINE map_base_motion(mapper, node)` |
| SUBROUTINE | `map_composite` | 4827 | `SUBROUTINE map_composite(mapper, node)` |
| SUBROUTINE | `map_laminate` | 4848 | `SUBROUTINE map_laminate(mapper, node)` |
| SUBROUTINE | `map_fiber_reinforced` | 4869 | `SUBROUTINE map_fiber_reinforced(mapper, node)` |
| SUBROUTINE | `map_puck_criterion` | 4889 | `SUBROUTINE map_puck_criterion(mapper, node)` |
| SUBROUTINE | `map_hashin_criterion` | 4909 | `SUBROUTINE map_hashin_criterion(mapper, node)` |
| SUBROUTINE | `map_johnson_cook` | 4929 | `SUBROUTINE map_johnson_cook(mapper, node)` |
| SUBROUTINE | `map_zerilli_armstrong` | 4949 | `SUBROUTINE map_zerilli_armstrong(mapper, node)` |
| SUBROUTINE | `map_anand` | 4969 | `SUBROUTINE map_anand(mapper, node)` |
| SUBROUTINE | `map_bodner_partom` | 4989 | `SUBROUTINE map_bodner_partom(mapper, node)` |
| SUBROUTINE | `map_chaboche` | 5009 | `SUBROUTINE map_chaboche(mapper, node)` |
| SUBROUTINE | `map_arruda_boyce` | 5029 | `SUBROUTINE map_arruda_boyce(mapper, node)` |
| SUBROUTINE | `map_van_der_waals` | 5049 | `SUBROUTINE map_van_der_waals(mapper, node)` |
| SUBROUTINE | `map_marlow` | 5069 | `SUBROUTINE map_marlow(mapper, node)` |
| SUBROUTINE | `map_fabric` | 5090 | `SUBROUTINE map_fabric(mapper, node)` |
| SUBROUTINE | `map_anisotropic_hyperelastic` | 5110 | `SUBROUTINE map_anisotropic_hyperelastic(mapper, node)` |
| SUBROUTINE | `map_aqua` | 5131 | `SUBROUTINE map_aqua(mapper, node)` |
| SUBROUTINE | `map_fluid` | 5151 | `SUBROUTINE map_fluid(mapper, node)` |
| SUBROUTINE | `map_fluid_cavity` | 5171 | `SUBROUTINE map_fluid_cavity(mapper, node)` |
| SUBROUTINE | `map_fluid_exchange` | 5190 | `SUBROUTINE map_fluid_exchange(mapper, node)` |
| SUBROUTINE | `map_flow` | 5209 | `SUBROUTINE map_flow(mapper, node)` |
| SUBROUTINE | `map_pressure_penetration` | 5228 | `SUBROUTINE map_pressure_penetration(mapper, node)` |
| SUBROUTINE | `map_drag` | 5247 | `SUBROUTINE map_drag(mapper, node)` |
| SUBROUTINE | `map_lift` | 5266 | `SUBROUTINE map_lift(mapper, node)` |
| SUBROUTINE | `map_multiphysics_coupling_removed` | 5283 | `SUBROUTINE map_multiphysics_coupling_removed(mapper, node)` |
| SUBROUTINE | `map_electrical` | 5293 | `SUBROUTINE map_electrical(mapper, node)` |
| SUBROUTINE | `map_magnetic` | 5312 | `SUBROUTINE map_magnetic(mapper, node)` |
| SUBROUTINE | `map_acoustic` | 5331 | `SUBROUTINE map_acoustic(mapper, node)` |
| SUBROUTINE | `map_piezoelectric` | 5350 | `SUBROUTINE map_piezoelectric(mapper, node)` |
| SUBROUTINE | `map_multiphysics` | 5369 | `SUBROUTINE map_multiphysics(mapper, node)` |
| SUBROUTINE | `map_contact_interference` | 5388 | `SUBROUTINE map_contact_interference(mapper, node)` |
| SUBROUTINE | `map_contact_clearance` | 5407 | `SUBROUTINE map_contact_clearance(mapper, node)` |
| SUBROUTINE | `map_contact_initialization` | 5426 | `SUBROUTINE map_contact_initialization(mapper, node)` |
| SUBROUTINE | `map_contact_output` | 5445 | `SUBROUTINE map_contact_output(mapper, node)` |
| SUBROUTINE | `map_contact_controls` | 5464 | `SUBROUTINE map_contact_controls(mapper, node)` |
| SUBROUTINE | `map_contact_stabilization` | 5483 | `SUBROUTINE map_contact_stabilization(mapper, node)` |
| SUBROUTINE | `map_friction` | 5502 | `SUBROUTINE map_friction(mapper, node)` |
| SUBROUTINE | `map_friction_coefficient` | 5522 | `SUBROUTINE map_friction_coefficient(mapper, node)` |
| SUBROUTINE | `map_stick_slip` | 5541 | `SUBROUTINE map_stick_slip(mapper, node)` |
| SUBROUTINE | `map_friction_output` | 5560 | `SUBROUTINE map_friction_output(mapper, node)` |
| SUBROUTINE | `map_output_request` | 5588 | `SUBROUTINE map_output_request(mapper, node)` |
| SUBROUTINE | `map_output_variable` | 5607 | `SUBROUTINE map_output_variable(mapper, node)` |
| SUBROUTINE | `map_output_filter` | 5626 | `SUBROUTINE map_output_filter(mapper, node)` |
| SUBROUTINE | `map_output_frequency` | 5645 | `SUBROUTINE map_output_frequency(mapper, node)` |
| SUBROUTINE | `map_output_format` | 5665 | `SUBROUTINE map_output_format(mapper, node)` |
| SUBROUTINE | `map_post_processing` | 5684 | `SUBROUTINE map_post_processing(mapper, node)` |
| SUBROUTINE | `map_animation` | 5703 | `SUBROUTINE map_animation(mapper, node)` |
| SUBROUTINE | `map_plot` | 5723 | `SUBROUTINE map_plot(mapper, node)` |
| SUBROUTINE | `map_report` | 5742 | `SUBROUTINE map_report(mapper, node)` |
| SUBROUTINE | `map_export` | 5761 | `SUBROUTINE map_export(mapper, node)` |
| SUBROUTINE | `map_uf_poro` | 5781 | `SUBROUTINE map_uf_poro(mapper, node)` |
| SUBROUTINE | `map_uf_poro_2ph` | 5833 | `SUBROUTINE map_uf_poro_2ph(mapper, node)` |
| SUBROUTINE | `map_amplitude` | 5909 | `SUBROUTINE map_amplitude(mapper, node)` |
| SUBROUTINE | `map_damping` | 6014 | `SUBROUTINE map_damping(mapper, node)` |
| SUBROUTINE | `map_solid_section` | 6041 | `SUBROUTINE map_solid_section(mapper, node)` |
| SUBROUTINE | `map_shell_section` | 6063 | `SUBROUTINE map_shell_section(mapper, node)` |
| SUBROUTINE | `map_beam_section` | 6092 | `SUBROUTINE map_beam_section(mapper, node)` |
| SUBROUTINE | `map_step` | 6131 | `SUBROUTINE map_step(mapper, node)` |
| SUBROUTINE | `map_static_procedure` | 6158 | `SUBROUTINE map_static_procedure(mapper, node)` |
| SUBROUTINE | `map_dynamic_procedure` | 6206 | `SUBROUTINE map_dynamic_procedure(mapper, node)` |
| SUBROUTINE | `map_frequency_procedure` | 6255 | `SUBROUTINE map_frequency_procedure(mapper, node)` |
| SUBROUTINE | `map_buckle_procedure` | 6317 | `SUBROUTINE map_buckle_procedure(mapper, node)` |
| SUBROUTINE | `map_steady_state_procedure` | 6344 | `SUBROUTINE map_steady_state_procedure(mapper, node)` |
| SUBROUTINE | `map_heat_transfer_procedure` | 6395 | `SUBROUTINE map_heat_transfer_procedure(mapper, node)` |
| SUBROUTINE | `map_coupled_procedure` | 6433 | `SUBROUTINE map_coupled_procedure(mapper, node)` |
| SUBROUTINE | `map_coupled_thermal_electrical_procedure` | 6470 | `SUBROUTINE map_coupled_thermal_electrical_procedure(mapper, node)` |
| SUBROUTINE | `map_geostatic_procedure` | 6507 | `SUBROUTINE map_geostatic_procedure(mapper, node)` |
| SUBROUTINE | `map_soils_procedure` | 6537 | `SUBROUTINE map_soils_procedure(mapper, node)` |
| SUBROUTINE | `map_visco_procedure` | 6570 | `SUBROUTINE map_visco_procedure(mapper, node)` |
| SUBROUTINE | `map_anneal_procedure` | 6603 | `SUBROUTINE map_anneal_procedure(mapper, node)` |
| SUBROUTINE | `map_modal_dynamic_procedure` | 6632 | `SUBROUTINE map_modal_dynamic_procedure(mapper, node)` |
| SUBROUTINE | `map_random_response_procedure` | 6642 | `SUBROUTINE map_random_response_procedure(mapper, node)` |
| SUBROUTINE | `map_response_spectrum_procedure` | 6652 | `SUBROUTINE map_response_spectrum_procedure(mapper, node)` |
| SUBROUTINE | `map_complex_frequency_procedure` | 6662 | `SUBROUTINE map_complex_frequency_procedure(mapper, node)` |
| SUBROUTINE | `map_mass_diffusion_procedure` | 6672 | `SUBROUTINE map_mass_diffusion_procedure(mapper, node)` |
| SUBROUTINE | `map_coupled_tes_procedure` | 6682 | `SUBROUTINE map_coupled_tes_procedure(mapper, node)` |
| SUBROUTINE | `map_piezoelectric_procedure` | 6692 | `SUBROUTINE map_piezoelectric_procedure(mapper, node)` |
| SUBROUTINE | `map_electromagnetic_procedure` | 6702 | `SUBROUTINE map_electromagnetic_procedure(mapper, node)` |
| SUBROUTINE | `map_acoustic_procedure` | 6712 | `SUBROUTINE map_acoustic_procedure(mapper, node)` |
| SUBROUTINE | `map_steady_state_transport_procedure` | 6722 | `SUBROUTINE map_steady_state_transport_procedure(mapper, node)` |
| SUBROUTINE | `map_substructure_procedure` | 6732 | `SUBROUTINE map_substructure_procedure(mapper, node)` |
| SUBROUTINE | `map_boundary` | 6742 | `SUBROUTINE map_boundary(mapper, node)` |
| SUBROUTINE | `map_cload` | 6846 | `SUBROUTINE map_cload(mapper, node)` |
| SUBROUTINE | `map_film` | 6898 | `SUBROUTINE map_film(mapper, node)` |
| SUBROUTINE | `map_radiate` | 6933 | `SUBROUTINE map_radiate(mapper, node)` |
| SUBROUTINE | `map_dsflux` | 6968 | `SUBROUTINE map_dsflux(mapper, node)` |
| SUBROUTINE | `map_massflow` | 6998 | `SUBROUTINE map_massflow(mapper, node)` |
| SUBROUTINE | `map_dload` | 7047 | `SUBROUTINE map_dload(mapper, node)` |
| SUBROUTINE | `map_temperature` | 7373 | `SUBROUTINE map_temperature(mapper, node)` |
| SUBROUTINE | `map_initial_conditions` | 7464 | `SUBROUTINE map_initial_conditions(mapper, node)` |
| SUBROUTINE | `map_output` | 7537 | `SUBROUTINE map_output(mapper, node)` |
| SUBROUTINE | `map_create_default_part` | 7764 | `SUBROUTINE map_create_default_part(mapper)` |
| SUBROUTINE | `md_kw_get_param_value` | 7784 | `SUBROUTINE md_kw_get_param_value(node, param_name, value)` |
| FUNCTION | `get_element_type_code` | 7806 | `FUNCTION get_element_type_code(type_str) RESULT(code)` |
| FUNCTION | `get_element_num_nodes` | 7931 | `FUNCTION get_element_num_nodes(type_code) RESULT(num)` |
| SUBROUTINE | `add_mapping_error` | 7980 | `SUBROUTINE add_mapping_error(mapper, line_num, message)` |
| SUBROUTINE | `kw_mapper_get_statistics` | 7992 | `SUBROUTINE kw_mapper_get_statistics(mapper, nodes, elements, materials, sections, steps)` |
| SUBROUTINE | `kw_mapper_cleanup` | 8006 | `SUBROUTINE kw_mapper_cleanup(mapper)` |
| SUBROUTINE | `map_embedded_element` | 8030 | `SUBROUTINE map_embedded_element(mapper, node)` |
| SUBROUTINE | `map_clearance` | 8052 | `SUBROUTINE map_clearance(mapper, node)` |
| SUBROUTINE | `map_shell_to_solid_coupling` | 8077 | `SUBROUTINE map_shell_to_solid_coupling(mapper, node)` |
| SUBROUTINE | `map_cyclic_symmetry` | 8098 | `SUBROUTINE map_cyclic_symmetry(mapper, node)` |
| SUBROUTINE | `map_contact_pair` | 8127 | `SUBROUTINE map_contact_pair(mapper, node)` |
| SUBROUTINE | `map_surface_to_surface_contact` | 8196 | `SUBROUTINE map_surface_to_surface_contact(mapper, node)` |
| SUBROUTINE | `map_surface_behavior` | 8263 | `SUBROUTINE map_surface_behavior(mapper, node)` |
| SUBROUTINE | `map_gap` | 8285 | `SUBROUTINE map_gap(mapper, node)` |
| SUBROUTINE | `map_contact_damping` | 8306 | `SUBROUTINE map_contact_damping(mapper, node)` |
| SUBROUTINE | `map_contact_stabilization` | 8324 | `SUBROUTINE map_contact_stabilization(mapper, node)` |
| SUBROUTINE | `map_geostatic_stress` | 8354 | `SUBROUTINE map_geostatic_stress(mapper, node)` |
| SUBROUTINE | `map_initial_state_ldbc` | 8375 | `SUBROUTINE map_initial_state_ldbc(mapper, node)` |
| SUBROUTINE | `map_hyperelastic` | 8398 | `SUBROUTINE map_hyperelastic(mapper, node)` |
| SUBROUTINE | `map_hyperfoam` | 8421 | `SUBROUTINE map_hyperfoam(mapper, node)` |
| SUBROUTINE | `map_hypoelastic` | 8446 | `SUBROUTINE map_hypoelastic(mapper, node)` |
| SUBROUTINE | `map_viscoelastic` | 8461 | `SUBROUTINE map_viscoelastic(mapper, node)` |
| SUBROUTINE | `map_rate_dependent` | 8482 | `SUBROUTINE map_rate_dependent(mapper, node)` |
| SUBROUTINE | `map_concrete` | 8503 | `SUBROUTINE map_concrete(mapper, node)` |
| SUBROUTINE | `map_foam_hardening` | 8518 | `SUBROUTINE map_foam_hardening(mapper, node)` |
| SUBROUTINE | `map_joule_heat_fraction` | 8533 | `SUBROUTINE map_joule_heat_fraction(mapper, node)` |
| SUBROUTINE | `map_cohesive_section` | 8551 | `SUBROUTINE map_cohesive_section(mapper, node)` |
| SUBROUTINE | `map_gasket_section` | 8575 | `SUBROUTINE map_gasket_section(mapper, node)` |
| SUBROUTINE | `map_surface_section` | 8597 | `SUBROUTINE map_surface_section(mapper, node)` |
| SUBROUTINE | `map_frame` | 8625 | `SUBROUTINE map_frame(mapper, node)` |
| SUBROUTINE | `map_el_print` | 8651 | `SUBROUTINE map_el_print(mapper, node)` |
| SUBROUTINE | `map_contact_print` | 8677 | `SUBROUTINE map_contact_print(mapper, node)` |
| SUBROUTINE | `map_energy_print` | 8702 | `SUBROUTINE map_energy_print(mapper, node)` |
| SUBROUTINE | `map_modal_output` | 8726 | `SUBROUTINE map_modal_output(mapper, node)` |
| SUBROUTINE | `map_coriolis_force` | 8755 | `SUBROUTINE map_coriolis_force(mapper, node)` |
| SUBROUTINE | `map_rotary_acceleration` | 8770 | `SUBROUTINE map_rotary_acceleration(mapper, node)` |
| SUBROUTINE | `map_foundation` | 8785 | `SUBROUTINE map_foundation(mapper, node)` |
| SUBROUTINE | `map_spring` | 8806 | `SUBROUTINE map_spring(mapper, node)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
