# `PH_Elem_AC3D6.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC3D6.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_AC3D6`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC3D6`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC3D6`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC3D6.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_AC3D6_UEL_Args` (lines 607–633)

```fortran
  TYPE, PUBLIC :: PH_AC3D6_UEL_Args
    ! Purpose: Unified argument bundle for AC3D6 element computations
    ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
    ! Status: SIO-01 compliant (unified *_Arg bundle with [IN]/[OUT] comments)
    
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
    
    !-- [OUT] Status and diagnostics
    TYPE(ErrorStatusType) :: status      ! Error status (required by SIO-03)
    LOGICAL               :: success      = .FALSE.  ! Overall step success flag
    REAL(wp)              :: pnewdt       = 1.0_wp   ! Suggested time step change ratio
    REAL(wp)              :: strain_energy = 0.0_wp  ! Element strain energy (acoustic potential)
    INTEGER(i4)           :: ip_failed    = 0_i4     ! IP index where failure occurred
    REAL(wp)              :: total_mass   = 0.0_wp  ! Total element mass (P3 diagnostic)
  END TYPE PH_AC3D6_UEL_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_AC3D6_Temperature_Dependent_Speed` | 106 | `SUBROUTINE PH_Elem_AC3D6_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_Thermal_Expansion_Source` | 142 | `SUBROUTINE PH_Elem_AC3D6_Thermal_Expansion_Source(F_thermal, coords, MD_Desc, MD_Algo, temperature_field, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_Biot_Wave_Speed` | 196 | `SUBROUTINE PH_Elem_AC3D6_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_Biot_Damping` | 252 | `SUBROUTINE PH_Elem_AC3D6_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_Biot_Stabilize_SlowWave` | 301 | `SUBROUTINE PH_Elem_AC3D6_Biot_Stabilize_SlowWave(tau_supg, coords, MD_Algo, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_Biot_Compute_Stab_Param` | 363 | `SUBROUTINE PH_Elem_AC3D6_Biot_Compute_Stab_Param(h_char, omega, c_fast, c_slow, stab_param, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_Sommerfeld_Radiation` | 402 | `SUBROUTINE PH_Elem_AC3D6_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, coords, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_Infinite_Element_Map` | 445 | `SUBROUTINE PH_Elem_AC3D6_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_PML_Update_State` | 485 | `SUBROUTINE PH_Elem_AC3D6_PML_Update_State(pml_state, pml_params, time_step, coords, pressure, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_PML_Absorbing_Boundary` | 532 | `SUBROUTINE PH_Elem_AC3D6_PML_Absorbing_Boundary(K_pml, C_pml, pml_region_mask, pml_params, coords, sound_speed, density, status)` |
| SUBROUTINE | `AC3D6_ShapeFunc` | 642 | `SUBROUTINE AC3D6_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `AC3D6_Jacobian` | 671 | `SUBROUTINE AC3D6_Jacobian(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `AC3D6_B_Matrix` | 695 | `SUBROUTINE AC3D6_B_Matrix(dNdxi, coords, B)` |
| SUBROUTINE | `PH_ELEM_AC3D6_VolumeInt` | 738 | `SUBROUTINE PH_ELEM_AC3D6_VolumeInt(coords, volume)` |
| SUBROUTINE | `PH_Elem_AC3D6_UEDL` | 757 | `SUBROUTINE PH_Elem_AC3D6_UEDL(args, MD_Desc, MD_State, MD_Algo, PH_Ctx, RT_Ctx, RT_Algo)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormStiffMatrix` | 814 | `SUBROUTINE PH_Elem_AC3D6_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormStiffMatrix_Impl` | 826 | `SUBROUTINE PH_Elem_AC3D6_FormStiffMatrix_Impl(coords, MD_Desc, MD_Algo, Ke, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormIntForce` | 888 | `SUBROUTINE PH_Elem_AC3D6_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormIntForce_Impl` | 901 | `SUBROUTINE PH_Elem_AC3D6_FormIntForce_Impl(coords, pressure, MD_Desc, MD_Algo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_ConsMass` | 930 | `SUBROUTINE PH_Elem_AC3D6_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_AC3D6_ConsMass_Impl` | 942 | `SUBROUTINE PH_Elem_AC3D6_ConsMass_Impl(coords, MD_Desc, MD_Algo, Me, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_LumpMass` | 992 | `SUBROUTINE PH_Elem_AC3D6_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_AC3D6_LumpMass_Impl` | 1004 | `SUBROUTINE PH_Elem_AC3D6_LumpMass_Impl(coords, MD_Desc, MD_Algo, M_lumped, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_ThermStrainVector` | 1040 | `SUBROUTINE PH_Elem_AC3D6_ThermStrainVector(coords, alpha_T, deltaT, eps_th, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_ApplyEssentialBC` | 1063 | `SUBROUTINE PH_Elem_AC3D6_ApplyEssentialBC(p_elem, prescribed_value, node_index, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_ApplyPenaltyBC` | 1082 | `SUBROUTINE PH_Elem_AC3D6_ApplyPenaltyBC(Ke, F_int, penalty, prescribed_value, node_index, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormConstraintMatrix` | 1106 | `SUBROUTINE PH_Elem_AC3D6_FormConstraintMatrix(C, constraint_type, dof_indices, coefficients, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormAcousticImpedance` | 1156 | `SUBROUTINE PH_Elem_AC3D6_FormAcousticImpedance(Ke, F_int, impedance, face_id, coords, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormRadiationCondition` | 1228 | `SUBROUTINE PH_Elem_AC3D6_FormRadiationCondition(Ke, F_int, sound_speed, face_id, coords, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormStructureCoupling` | 1307 | `SUBROUTINE PH_Elem_AC3D6_FormStructureCoupling(Ke, F_int, coupling_matrix, interface_dofs, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormPressureLoad` | 1357 | `SUBROUTINE PH_Elem_AC3D6_FormPressureLoad(F_ext, pressure_load, face_id, coords, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormBodyForce` | 1391 | `SUBROUTINE PH_Elem_AC3D6_FormBodyForce(F_ext, body_force, coords, density, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_FormSurfaceTraction` | 1433 | `SUBROUTINE PH_Elem_AC3D6_FormSurfaceTraction(F_ext, traction, surface_id, coords, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_CalcPressure` | 1535 | `SUBROUTINE PH_Elem_AC3D6_CalcPressure(p_elem, coords, pressure_ip, ip_index, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_CalcAcousticIntensity` | 1562 | `SUBROUTINE PH_Elem_AC3D6_CalcAcousticIntensity(p_elem, coords, density, sound_speed, intensity, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_CalcEnergy` | 1603 | `SUBROUTINE PH_Elem_AC3D6_CalcEnergy(p_elem, coords, density, sound_speed, energy_density, total_energy, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_CalcEnergy_FromDesc` | 1666 | `SUBROUTINE PH_Elem_AC3D6_CalcEnergy_FromDesc(MD_Desc, MD_State, MD_Algo, energy_density, total_energy, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_OutputResults` | 1689 | `SUBROUTINE PH_Elem_AC3D6_OutputResults(MD_State, p_elem, coords, svars, output_vars, step_time, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_Rayleigh_Damping` | 1789 | `SUBROUTINE PH_Elem_AC3D6_Rayleigh_Damping(alpha_M, beta_K, Me, Ke, Ce, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_NL_TL` | 1807 | `SUBROUTINE PH_Elem_AC3D6_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D6_NL_UL` | 1887 | `SUBROUTINE PH_Elem_AC3D6_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `UF_Elem_AC3D6_Calc` | 1967 | `SUBROUTINE UF_Elem_AC3D6_Calc(ElemType, Formul, Ctx, state_in, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
