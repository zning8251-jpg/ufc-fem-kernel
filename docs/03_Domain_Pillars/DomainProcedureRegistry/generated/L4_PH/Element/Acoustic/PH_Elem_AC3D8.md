# `PH_Elem_AC3D8.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC3D8.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_AC3D8`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC3D8`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC3D8`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC3D8.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_AC3D8_UEL_Args` (lines 136–158)

```fortran
  TYPE, PUBLIC :: PH_AC3D8_UEL_Args
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
  END TYPE PH_AC3D8_UEL_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AC3D8_GaussPoints` | 165 | `SUBROUTINE AC3D8_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `AC3D8_ShapeFunc` | 181 | `SUBROUTINE AC3D8_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `AC3D8_Jacobian` | 229 | `SUBROUTINE AC3D8_Jacobian(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `AC3D8_B_Matrix` | 242 | `SUBROUTINE AC3D8_B_Matrix(dNdxi, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_AC3D8_GetVolume` | 265 | `SUBROUTINE PH_Elem_AC3D8_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_AC3D8_GetArea` | 280 | `SUBROUTINE PH_Elem_AC3D8_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_AC3D8_GetCentroid` | 286 | `SUBROUTINE PH_Elem_AC3D8_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_AC3D8_GetSectProps` | 292 | `SUBROUTINE PH_Elem_AC3D8_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormStiffMatrix` | 304 | `SUBROUTINE PH_Elem_AC3D8_FormStiffMatrix(coords, rho, c_sound, Ke)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormIntForce` | 328 | `SUBROUTINE PH_Elem_AC3D8_FormIntForce(coords, u, rho, c_sound, R_int)` |
| SUBROUTINE | `PH_Elem_AC3D8_ConsMass` | 339 | `SUBROUTINE PH_Elem_AC3D8_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_AC3D8_LumpMass` | 364 | `SUBROUTINE PH_Elem_AC3D8_LumpMass(coords, rho, M_lumped, method)` |
| SUBROUTINE | `PH_Elem_AC3D8_ApplyEssentialBC` | 402 | `SUBROUTINE PH_Elem_AC3D8_ApplyEssentialBC(idof, val, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D8_ApplyPenaltyBC` | 413 | `SUBROUTINE PH_Elem_AC3D8_ApplyPenaltyBC(idof, penalty, val, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormConstraintMatrix` | 422 | `SUBROUTINE PH_Elem_AC3D8_FormConstraintMatrix(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormAcousticImpedance` | 434 | `SUBROUTINE PH_Elem_AC3D8_FormAcousticImpedance(coords, Zc, C_imp)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormPressureLoad` | 459 | `SUBROUTINE PH_Elem_AC3D8_FormPressureLoad(coords, pressure, F_load)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormBodyForce` | 479 | `SUBROUTINE PH_Elem_AC3D8_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormSurfaceTraction` | 500 | `SUBROUTINE PH_Elem_AC3D8_FormSurfaceTraction(coords, t1, t2, F_traction)` |
| SUBROUTINE | `PH_Elem_AC3D8_CalcPressure` | 509 | `SUBROUTINE PH_Elem_AC3D8_CalcPressure(coords, u, p_ip)` |
| SUBROUTINE | `PH_Elem_AC3D8_CalcAcousticIntensity` | 515 | `SUBROUTINE PH_Elem_AC3D8_CalcAcousticIntensity(p, v, I_avg)` |
| SUBROUTINE | `PH_Elem_AC3D8_CalcEnergy` | 521 | `SUBROUTINE PH_Elem_AC3D8_CalcEnergy(coords, p, E_acoustic)` |
| SUBROUTINE | `PH_Elem_AC3D8_CalcEnergy_FromDesc` | 531 | `SUBROUTINE PH_Elem_AC3D8_CalcEnergy_FromDesc(MD_Desc, E_acoustic)` |
| SUBROUTINE | `PH_Elem_AC3D8_OutputResults` | 537 | `SUBROUTINE PH_Elem_AC3D8_OutputResults(coords, u, svars, output)` |
| SUBROUTINE | `PH_Elem_AC3D8_GetMaterialProps` | 546 | `SUBROUTINE PH_Elem_AC3D8_GetMaterialProps(coords, Mat_Algo, rho, c_sound)` |
| SUBROUTINE | `PH_Elem_AC3D8_GetMaterialProps_FromDesc` | 554 | `SUBROUTINE PH_Elem_AC3D8_GetMaterialProps_FromDesc(MD_Desc, rho, c_sound)` |
| SUBROUTINE | `PH_Elem_AC3D8_GetAcousticProps` | 561 | `SUBROUTINE PH_Elem_AC3D8_GetAcousticProps(rho, c_sound, Zc, K_bulk)` |
| SUBROUTINE | `PH_Elem_AC3D8_SetSectionProps` | 568 | `SUBROUTINE PH_Elem_AC3D8_SetSectionProps(Sect_Registry, props)` |
| SUBROUTINE | `PH_Elem_AC3D8_SetSectionProps_FromDesc` | 574 | `SUBROUTINE PH_Elem_AC3D8_SetSectionProps_FromDesc(MD_Desc, props)` |
| SUBROUTINE | `PH_Elem_AC3D8_Temperature_Dependent_Speed` | 583 | `SUBROUTINE PH_Elem_AC3D8_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_Thermal_Expansion_Source` | 605 | `SUBROUTINE PH_Elem_AC3D8_Thermal_Expansion_Source(F_thermal, coords, temperature_field, MD_Desc, MD_Algo, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_Biot_Wave_Speed` | 641 | `SUBROUTINE PH_Elem_AC3D8_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_Biot_Damping` | 678 | `SUBROUTINE PH_Elem_AC3D8_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_Biot_Stabilize_SlowWave` | 709 | `SUBROUTINE PH_Elem_AC3D8_Biot_Stabilize_SlowWave(tau_supg, coords, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_Biot_Compute_Stab_Param` | 734 | `SUBROUTINE PH_Elem_AC3D8_Biot_Compute_Stab_Param(h_char, omega, c_fast, c_slow, stab_param, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_Rayleigh_Damping` | 756 | `SUBROUTINE PH_Elem_AC3D8_Rayleigh_Damping(alpha_M, beta_K, Me, Ke, Ce, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_Sommerfeld_Radiation` | 772 | `SUBROUTINE PH_Elem_AC3D8_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_Infinite_Element_Map` | 785 | `SUBROUTINE PH_Elem_AC3D8_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_PML_Update_State` | 800 | `SUBROUTINE PH_Elem_AC3D8_PML_Update_State(pml_state, pml_params, time_step, pressure, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_PML_Absorbing_Boundary` | 807 | `SUBROUTINE PH_Elem_AC3D8_PML_Absorbing_Boundary(K_pml, C_pml, pml_region_mask, pml_params, coords, sound_speed, density, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_DefInit` | 839 | `SUBROUTINE PH_Elem_AC3D8_DefInit()` |
| SUBROUTINE | `PH_Elem_AC3D8_ThermStrainVector` | 842 | `SUBROUTINE PH_Elem_AC3D8_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_AC3D8_NL_TL` | 848 | `SUBROUTINE PH_Elem_AC3D8_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_NL_UL` | 861 | `SUBROUTINE PH_Elem_AC3D8_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormRadiationCondition` | 874 | `SUBROUTINE PH_Elem_AC3D8_FormRadiationCondition(coords, face_normal, sound_speed, frequency, C_rad, K_rad, status)` |
| SUBROUTINE | `PH_Elem_AC3D8_FormStructureCoupling` | 905 | `SUBROUTINE PH_Elem_AC3D8_FormStructureCoupling(coords, coupling_matrix, structure_dof_indices, acoustic_dof_indices, status)` |
| SUBROUTINE | `UF_Elem_AC3D8_Calc` | 936 | `SUBROUTINE UF_Elem_AC3D8_Calc(ElemType, Formul, Ctx, state_in, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
