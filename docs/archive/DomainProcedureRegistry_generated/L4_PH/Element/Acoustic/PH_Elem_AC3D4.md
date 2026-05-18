# `PH_Elem_AC3D4.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC3D4.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_AC3D4`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC3D4`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC3D4`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC3D4.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_AC3D4_UEL_Args` (lines 142–174)

```fortran
  TYPE, PUBLIC :: PH_AC3D4_UEL_Args
    !-- [IN] Flags for computation control
    LOGICAL     :: compute_amatrx = .TRUE.   ! Compute tangent stiffness matrix
    LOGICAL     :: compute_rhs    = .TRUE.   ! Compute residual vector
    
    !-- [IN] P3 dynamic analysis extensions
    LOGICAL     :: compute_mass   = .FALSE.  ! Mass matrix computation flag (P3)
    INTEGER(i4) :: mass_method    = 0_i4    ! 0=None, 1=Consistent, 2=Lumped(HRZ), 3=Lumped(RowSum), 4=Lumped(Uniform)
    LOGICAL     :: compute_damping = .FALSE. ! Damping matrix computation flag (P3)
    REAL(wp)    :: alpha_M        = 0.0_wp  ! Mass proportional damping coefficient [1/s]
    REAL(wp)    :: beta_K         = 0.0_wp  ! Stiffness proportional damping coefficient [s]
    
    !-- [IN] Step control (from RT_Com_Ctx%lflags)
    INTEGER(i4) :: lflags_kstep   = 0_i4
    
    !-- [IN] P5 numerical enhancements
    LOGICAL     :: use_hht_alpha  = .FALSE.  ! Use HHT-α method (default: Newmark-β)
    REAL(wp)    :: hht_alpha_param = -0.05_wp ! HHT-α parameter α ?[-? 0]
    REAL(wp)    :: dt_current     = 1.0e-6_wp ! Current time step size [s]
    REAL(wp)    :: dt_previous    = 1.0e-6_wp ! Previous time step size [s]
    LOGICAL     :: adaptive_dt    = .FALSE.  ! Enable adaptive time stepping
    REAL(wp)    :: error_tolerance = 1.0e-6_wp ! Local error tolerance for adaptive dt
    
    !-- [OUT] Status and diagnostics
    TYPE(ErrorStatusType) :: status      ! Error status (required by SIO-03)
    LOGICAL               :: success      = .FALSE.  ! Overall step success flag
    REAL(wp)              :: pnewdt       = 1.0_wp   ! Suggested time step change ratio
    REAL(wp)              :: strain_energy = 0.0_wp  ! Element strain energy (acoustic potential)
    INTEGER(i4)           :: ip_failed    = 0_i4     ! IP index where failure occurred
    REAL(wp)              :: total_mass   = 0.0_wp  ! Total element mass (P3 diagnostic)
    REAL(wp)              :: local_error  = 0.0_wp  ! Local truncation error estimate (P5)
    LOGICAL               :: state_saved  = .FALSE.  ! State backup flag (P5)
  END TYPE PH_AC3D4_UEL_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_AC3D4_UEL_API` | 185 | `SUBROUTINE PH_AC3D4_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &` |
| SUBROUTINE | `PH_AC3D4_UEL_Impl` | 216 | `SUBROUTINE PH_AC3D4_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &` |
| SUBROUTINE | `C3D4_GetGaussPoint` | 413 | `SUBROUTINE C3D4_GetGaussPoint(ip, xi, eta, zeta, w)` |
| SUBROUTINE | `C3D4_Shape_Functions` | 425 | `SUBROUTINE C3D4_Shape_Functions(xi, eta, zeta, N)` |
| SUBROUTINE | `C3D4_Shape_Functions_Derivatives` | 437 | `SUBROUTINE C3D4_Shape_Functions_Derivatives(dNdxi, dNdeta, dNdzeta)` |
| SUBROUTINE | `C3D4_Jacobian` | 461 | `SUBROUTINE C3D4_Jacobian(coords, N, xi, eta, zeta, dNdX, detJ)` |
| SUBROUTINE | `AC3D4_B_Matrix` | 503 | `SUBROUTINE AC3D4_B_Matrix(dNdX, B)` |
| SUBROUTINE | `PH_Elem_AC3D4_GetArea` | 524 | `SUBROUTINE PH_Elem_AC3D4_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_AC3D4_GetCentroid` | 530 | `SUBROUTINE PH_Elem_AC3D4_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_AC3D4_GetSectProps` | 541 | `SUBROUTINE PH_Elem_AC3D4_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_AC3D4_ApplyConstraint` | 552 | `SUBROUTINE PH_Elem_AC3D4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D4_ApplyMPC` | 565 | `SUBROUTINE PH_Elem_AC3D4_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormContactContrib` | 583 | `SUBROUTINE PH_Elem_AC3D4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormContactEdgeCtr` | 593 | `SUBROUTINE PH_Elem_AC3D4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormBodyForce` | 606 | `SUBROUTINE PH_Elem_AC3D4_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormNodalForce` | 613 | `SUBROUTINE PH_Elem_AC3D4_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_AC3D4_CollectIPVars` | 625 | `SUBROUTINE PH_Elem_AC3D4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_AC3D4_EvalVonMises` | 634 | `SUBROUTINE PH_Elem_AC3D4_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_AC3D4_GetExtrapMat` | 640 | `SUBROUTINE PH_Elem_AC3D4_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_AC3D4_MapToNode` | 645 | `SUBROUTINE PH_Elem_AC3D4_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_ELEM_AC3D4_VolumeInt` | 655 | `SUBROUTINE PH_ELEM_AC3D4_VolumeInt(coords, volume)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormStiffMatrix` | 666 | `SUBROUTINE PH_Elem_AC3D4_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_AC3D4_ThermStrainVector` | 690 | `SUBROUTINE PH_Elem_AC3D4_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_AC3D4_ConsMass` | 696 | `SUBROUTINE PH_Elem_AC3D4_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_AC3D4_DefInit` | 719 | `SUBROUTINE PH_Elem_AC3D4_DefInit()` |
| SUBROUTINE | `PH_Elem_AC3D4_FormIntForce` | 722 | `SUBROUTINE PH_Elem_AC3D4_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_AC3D4_LumpMass` | 732 | `SUBROUTINE PH_Elem_AC3D4_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_AC3D4_NL_TL` | 746 | `SUBROUTINE PH_Elem_AC3D4_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D4_NL_UL` | 765 | `SUBROUTINE PH_Elem_AC3D4_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D4_GetMaterialProps` | 789 | `SUBROUTINE PH_Elem_AC3D4_GetMaterialProps(density, bulk_modulus, sound_speed)` |
| SUBROUTINE | `PH_Elem_AC3D4_GetMaterialProps_FromDesc` | 796 | `SUBROUTINE PH_Elem_AC3D4_GetMaterialProps_FromDesc(desc)` |
| SUBROUTINE | `PH_Elem_AC3D4_GetVolume` | 803 | `SUBROUTINE PH_Elem_AC3D4_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_AC3D4_GetAcousticProps` | 810 | `SUBROUTINE PH_Elem_AC3D4_GetAcousticProps(acoustic_density, acoustic_impedance)` |
| SUBROUTINE | `PH_Elem_AC3D4_SetSectionProps` | 818 | `SUBROUTINE PH_Elem_AC3D4_SetSectionProps(density, bulk_modulus)` |
| SUBROUTINE | `PH_Elem_AC3D4_SetSectionProps_FromDesc` | 823 | `SUBROUTINE PH_Elem_AC3D4_SetSectionProps_FromDesc(sect_desc)` |
| SUBROUTINE | `PH_Elem_AC3D4_ApplyEssentialBC` | 829 | `SUBROUTINE PH_Elem_AC3D4_ApplyEssentialBC(Ke, F_ext, constrained_nodes, prescribed_values)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormConstraintMatrix` | 851 | `SUBROUTINE PH_Elem_AC3D4_FormConstraintMatrix(constrained_nodes, C_matrix)` |
| SUBROUTINE | `PH_Elem_AC3D4_ApplyPenaltyBC` | 862 | `SUBROUTINE PH_Elem_AC3D4_ApplyPenaltyBC(Ke, F_ext, constrained_nodes, prescribed_values, penalty)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormAcousticImpedance` | 877 | `SUBROUTINE PH_Elem_AC3D4_FormAcousticImpedance(coords, impedance, face, K_impedance)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormRadiationCondition` | 920 | `SUBROUTINE PH_Elem_AC3D4_FormRadiationCondition(coords, radiation_coeff, face, K_radiation)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormStructureCoupling` | 928 | `SUBROUTINE PH_Elem_AC3D4_FormStructureCoupling(coords, coupling_coeff, face, K_coupling)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormPressureLoad` | 937 | `SUBROUTINE PH_Elem_AC3D4_FormPressureLoad(coords, pressure, F_ext)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormBodyForce` | 950 | `SUBROUTINE PH_Elem_AC3D4_FormBodyForce(coords, body_force, F_ext)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormSurfaceTraction` | 963 | `SUBROUTINE PH_Elem_AC3D4_FormSurfaceTraction(coords, traction, face, F_ext)` |
| SUBROUTINE | `PH_Elem_AC3D4_CalcAcousticIntensity` | 998 | `SUBROUTINE PH_Elem_AC3D4_CalcAcousticIntensity(coords, nodal_pressures, nodal_velocities, intensity)` |
| SUBROUTINE | `PH_Elem_AC3D4_CalcEnergy` | 1013 | `SUBROUTINE PH_Elem_AC3D4_CalcEnergy(coords, nodal_pressures, nodal_velocities, density, kinetic_energy, potential_energy)` |
| SUBROUTINE | `PH_Elem_AC3D4_CalcEnergy_FromDesc` | 1034 | `SUBROUTINE PH_Elem_AC3D4_CalcEnergy_FromDesc(coords, nodal_pressures, nodal_velocities, sect_desc, kinetic_energy, potential_energy)` |
| SUBROUTINE | `PH_Elem_AC3D4_OutputResults` | 1046 | `SUBROUTINE PH_Elem_AC3D4_OutputResults(coords, nodal_pressures, nodal_velocities, filename)` |
| SUBROUTINE | `PH_Elem_AC3D4_CalcPressure` | 1056 | `SUBROUTINE PH_Elem_AC3D4_CalcPressure(coords, nodal_pressures, gauss_points, pressure_field)` |
| SUBROUTINE | `AC3D4_ConsMass` | 1077 | `SUBROUTINE AC3D4_ConsMass(density, N, w_ip, det_J, Me)` |
| SUBROUTINE | `AC3D4_LumpMass_HRZ` | 1092 | `SUBROUTINE AC3D4_LumpMass_HRZ(density, N, w_ip, det_J, Me)` |
| SUBROUTINE | `AC3D4_LumpMass_RowSum` | 1121 | `SUBROUTINE AC3D4_LumpMass_RowSum(density, N, w_ip, det_J, Me)` |
| SUBROUTINE | `AC3D4_LumpMass_Uniform` | 1143 | `SUBROUTINE AC3D4_LumpMass_Uniform(density, N, w_ip, det_J, Me)` |
| SUBROUTINE | `PH_Elem_AC3D4_FormDampingMatrix` | 1162 | `SUBROUTINE PH_Elem_AC3D4_FormDampingMatrix(mass_matrix, stiffness_matrix, alpha_M, beta_K, damping_matrix)` |
| SUBROUTINE | `PH_Elem_AC3D4_ConsMass` | 1172 | `SUBROUTINE PH_Elem_AC3D4_ConsMass(coords, density, mass_matrix)` |
| SUBROUTINE | `PH_Elem_AC3D4_LumpMass` | 1185 | `SUBROUTINE PH_Elem_AC3D4_LumpMass(coords, density, method, mass_matrix)` |
| SUBROUTINE | `PH_Elem_AC3D4_Temperature_Dependent_Speed` | 1215 | `SUBROUTINE PH_Elem_AC3D4_Temperature_Dependent_Speed(c0, T0, T_current, c_T)` |
| SUBROUTINE | `PH_Elem_AC3D4_UpdateMaterialProps_TempDep` | 1233 | `SUBROUTINE PH_Elem_AC3D4_UpdateMaterialProps_TempDep(density_ref, bulk_modulus_ref, &` |
| SUBROUTINE | `PH_Elem_AC3D4_Biot_Wave_Speed` | 1258 | `SUBROUTINE PH_Elem_AC3D4_Biot_Wave_Speed(porosity, tortuosity, fluid_density, &` |
| SUBROUTINE | `PH_Elem_AC3D4_Biot_Damping` | 1295 | `SUBROUTINE PH_Elem_AC3D4_Biot_Damping(permeability, fluid_viscosity, porosity, &` |
| SUBROUTINE | `PH_Elem_AC3D4_Biot_Stabilize_SlowWave` | 1314 | `SUBROUTINE PH_Elem_AC3D4_Biot_Stabilize_SlowWave(mesh_size, slow_wave_speed, &` |
| SUBROUTINE | `PH_Elem_AC3D4_Biot_Compute_Stab_Param` | 1339 | `SUBROUTINE PH_Elem_AC3D4_Biot_Compute_Stab_Param(coords, porosity, permeability, &` |
| SUBROUTINE | `PH_Elem_AC3D4_Sommerfeld_Radiation` | 1357 | `SUBROUTINE PH_Elem_AC3D4_Sommerfeld_Radiation(coords, face_nodes, sound_speed, &` |
| SUBROUTINE | `PH_Elem_AC3D4_PML_Absorbing_Boundary` | 1388 | `SUBROUTINE PH_Elem_AC3D4_PML_Absorbing_Boundary(coords, pml_region_flag, &` |
| SUBROUTINE | `PH_Elem_AC3D4_Newmark_Beta_Integrator` | 1415 | `SUBROUTINE PH_Elem_AC3D4_Newmark_Beta_Integrator(` |
| SUBROUTINE | `PH_Elem_AC3D4_HHT_Alpha_Integrator` | 1496 | `SUBROUTINE PH_Elem_AC3D4_HHT_Alpha_Integrator(` |
| SUBROUTINE | `PH_Elem_AC3D4_Compute_Local_Error` | 1574 | `SUBROUTINE PH_Elem_AC3D4_Compute_Local_Error(` |
| SUBROUTINE | `PH_Elem_AC3D4_Adaptive_TimeStep_Control` | 1605 | `SUBROUTINE PH_Elem_AC3D4_Adaptive_TimeStep_Control(` |
| SUBROUTINE | `PH_Elem_AC3D4_Save_State` | 1664 | `SUBROUTINE PH_Elem_AC3D4_Save_State(state_current, state_backup)` |
| SUBROUTINE | `PH_Elem_AC3D4_Restore_State` | 1717 | `SUBROUTINE PH_Elem_AC3D4_Restore_State(state_backup, state_current)` |
| SUBROUTINE | `UF_Elem_AC3D4_Calc` | 1772 | `SUBROUTINE UF_Elem_AC3D4_Calc(ElemType, Formul, Ctx, state_in, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
