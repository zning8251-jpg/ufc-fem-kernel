# `PH_Elem_AC3D10.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC3D10.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_AC3D10`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC3D10`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC3D10`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC3D10.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_AC3D10_UEL_Args` (lines 135–157)

```fortran
  TYPE, PUBLIC :: PH_AC3D10_UEL_Args
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
  END TYPE PH_AC3D10_UEL_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AC3D10_GaussPoints` | 172 | `SUBROUTINE AC3D10_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `AC3D10_ShapeFunc` | 192 | `SUBROUTINE AC3D10_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `AC3D10_Jacobian` | 259 | `SUBROUTINE AC3D10_Jacobian(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `AC3D10_B_Matrix` | 281 | `SUBROUTINE AC3D10_B_Matrix(dNdxi, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_AC3D10_GetVolume` | 311 | `SUBROUTINE PH_Elem_AC3D10_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_AC3D10_GetArea` | 326 | `SUBROUTINE PH_Elem_AC3D10_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_AC3D10_GetCentroid` | 332 | `SUBROUTINE PH_Elem_AC3D10_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_AC3D10_GetSectProps` | 338 | `SUBROUTINE PH_Elem_AC3D10_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormStiffMatrix` | 350 | `SUBROUTINE PH_Elem_AC3D10_FormStiffMatrix(coords, rho, c_sound, Ke, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormIntForce` | 376 | `SUBROUTINE PH_Elem_AC3D10_FormIntForce(coords, p, rho, c_sound, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_ConsMass` | 388 | `SUBROUTINE PH_Elem_AC3D10_ConsMass(coords, rho, Me, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_LumpMass` | 415 | `SUBROUTINE PH_Elem_AC3D10_LumpMass(coords, rho, M_lumped, method, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormDampingMatrix` | 455 | `SUBROUTINE PH_Elem_AC3D10_FormDampingMatrix(alpha_M, beta_K, Me, Ke, Ce, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_ApplyEssentialBC` | 466 | `SUBROUTINE PH_Elem_AC3D10_ApplyEssentialBC(idof, val, K_el, F_el, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_ApplyPenaltyBC` | 479 | `SUBROUTINE PH_Elem_AC3D10_ApplyPenaltyBC(idof, penalty, val, K_el, F_el, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormConstraintMatrix` | 490 | `SUBROUTINE PH_Elem_AC3D10_FormConstraintMatrix(c, val, penalty, K_el, F_el, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormAcousticImpedance` | 504 | `SUBROUTINE PH_Elem_AC3D10_FormAcousticImpedance(coords, Zc, rho, C_imp, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormRadiationCondition` | 528 | `SUBROUTINE PH_Elem_AC3D10_FormRadiationCondition(coords, face_normal, sound_speed, frequency, C_rad, K_rad, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormStructureCoupling` | 559 | `SUBROUTINE PH_Elem_AC3D10_FormStructureCoupling(coords, coupling_matrix, structure_dof_indices, acoustic_dof_indices, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormPressureLoad` | 589 | `SUBROUTINE PH_Elem_AC3D10_FormPressureLoad(coords, pressure, F_load, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormBodyForce` | 611 | `SUBROUTINE PH_Elem_AC3D10_FormBodyForce(coords, bx, by, bz, F_eq, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_FormSurfaceTraction` | 634 | `SUBROUTINE PH_Elem_AC3D10_FormSurfaceTraction(coords, t1, t2, F_traction, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_CalcPressure` | 645 | `SUBROUTINE PH_Elem_AC3D10_CalcPressure(coords, p, rho, c_sound, p_ip, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_CalcAcousticIntensity` | 659 | `SUBROUTINE PH_Elem_AC3D10_CalcAcousticIntensity(p, v, I_avg, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_CalcEnergy` | 667 | `SUBROUTINE PH_Elem_AC3D10_CalcEnergy(coords, p, rho, c_sound, E_acoustic, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_CalcEnergy_FromDesc` | 676 | `SUBROUTINE PH_Elem_AC3D10_CalcEnergy_FromDesc(MD_Desc, E_acoustic, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_OutputResults` | 684 | `SUBROUTINE PH_Elem_AC3D10_OutputResults(coords, p, svars, output, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_GetMaterialProps` | 695 | `SUBROUTINE PH_Elem_AC3D10_GetMaterialProps(coords, Mat_Algo, rho, c_sound, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_GetMaterialProps_FromDesc` | 705 | `SUBROUTINE PH_Elem_AC3D10_GetMaterialProps_FromDesc(MD_Desc, rho, c_sound, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_GetAcousticProps` | 714 | `SUBROUTINE PH_Elem_AC3D10_GetAcousticProps(rho, c_sound, Zc, K_bulk, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_SetSectionProps` | 723 | `SUBROUTINE PH_Elem_AC3D10_SetSectionProps(Sect_Registry, props, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_SetSectionProps_FromDesc` | 731 | `SUBROUTINE PH_Elem_AC3D10_SetSectionProps_FromDesc(MD_Desc, props, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_Temperature_Dependent_Speed` | 742 | `SUBROUTINE PH_Elem_AC3D10_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_Thermal_Expansion_Source` | 758 | `SUBROUTINE PH_Elem_AC3D10_Thermal_Expansion_Source(F_thermal, coords, temperature_field, MD_Desc, MD_Algo, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_UpdateMaterialProps_TempDep` | 788 | `SUBROUTINE PH_Elem_AC3D10_UpdateMaterialProps_TempDep(rho, c_sound, temperature, T_ref, alpha_rho, alpha_c, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_Biot_Wave_Speed` | 802 | `SUBROUTINE PH_Elem_AC3D10_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_Biot_Damping` | 827 | `SUBROUTINE PH_Elem_AC3D10_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_Biot_Stabilize_SlowWave` | 851 | `SUBROUTINE PH_Elem_AC3D10_Biot_Stabilize_SlowWave(tau_supg, coords, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_Biot_Compute_Stab_Param` | 873 | `SUBROUTINE PH_Elem_AC3D10_Biot_Compute_Stab_Param(h_char, omega, c_fast, c_slow, stab_param, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_Sommerfeld_Radiation` | 893 | `SUBROUTINE PH_Elem_AC3D10_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_Infinite_Element_Map` | 906 | `SUBROUTINE PH_Elem_AC3D10_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_PML_Update_State` | 922 | `SUBROUTINE PH_Elem_AC3D10_PML_Update_State(pml_state, pml_params, time_step, pressure, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_PML_Absorbing_Boundary` | 929 | `SUBROUTINE PH_Elem_AC3D10_PML_Absorbing_Boundary(K_pml, C_pml, pml_region_mask, pml_params, coords, sound_speed, density, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_DefInit` | 962 | `SUBROUTINE PH_Elem_AC3D10_DefInit()` |
| SUBROUTINE | `PH_Elem_AC3D10_ThermStrainVector` | 965 | `SUBROUTINE PH_Elem_AC3D10_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_AC3D10_NL_TL` | 971 | `SUBROUTINE PH_Elem_AC3D10_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D10_NL_UL` | 984 | `SUBROUTINE PH_Elem_AC3D10_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `UF_Elem_AC3D10_Calc` | 1002 | `SUBROUTINE UF_Elem_AC3D10_Calc(ElemType, Formul, Ctx, state_in, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
