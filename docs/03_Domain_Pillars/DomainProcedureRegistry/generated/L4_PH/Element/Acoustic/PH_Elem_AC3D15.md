# `PH_Elem_AC3D15.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC3D15.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_AC3D15`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC3D15`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC3D15`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC3D15.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_AC3D15_UEL_Args` (lines 162–184)

```fortran
  TYPE, PUBLIC :: PH_AC3D15_UEL_Args
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
  END TYPE PH_AC3D15_UEL_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AC3D15_GaussPoints` | 199 | `SUBROUTINE AC3D15_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `AC3D15_ShapeFunc` | 227 | `SUBROUTINE AC3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `AC3D15_Jacobian` | 320 | `SUBROUTINE AC3D15_Jacobian(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `AC3D15_B_Matrix` | 340 | `SUBROUTINE AC3D15_B_Matrix(dNdxi, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_AC3D15_ApplyConstraint` | 365 | `SUBROUTINE PH_Elem_AC3D15_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D15_ApplyMPC` | 378 | `SUBROUTINE PH_Elem_AC3D15_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormContactContrib` | 393 | `SUBROUTINE PH_Elem_AC3D15_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormContactEdgeCtr` | 403 | `SUBROUTINE PH_Elem_AC3D15_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormBodyForce` | 413 | `SUBROUTINE PH_Elem_AC3D15_FormBodyForce(coords, bx, by, bz, F_eq, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormNodalForce` | 442 | `SUBROUTINE PH_Elem_AC3D15_FormNodalForce(load_type, coords, val, edge_id, F_eq, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_CollectIPVars` | 474 | `SUBROUTINE PH_Elem_AC3D15_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_EvalVonMises` | 493 | `SUBROUTINE PH_Elem_AC3D15_EvalVonMises(sigma, seq, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_GetExtrapMat` | 510 | `SUBROUTINE PH_Elem_AC3D15_GetExtrapMat(E, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_MapToNode` | 532 | `SUBROUTINE PH_Elem_AC3D15_MapToNode(ip_vars, weights, node_vars, status)` |
| SUBROUTINE | `PH_ELEM_AC3D15_VolumeInt` | 552 | `SUBROUTINE PH_ELEM_AC3D15_VolumeInt(coords, volume)` |
| SUBROUTINE | `PH_Elem_AC3D15_GetVolume` | 570 | `SUBROUTINE PH_Elem_AC3D15_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_AC3D15_GetArea` | 585 | `SUBROUTINE PH_Elem_AC3D15_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_AC3D15_GetCentroid` | 591 | `SUBROUTINE PH_Elem_AC3D15_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_AC3D15_GetSectProps` | 597 | `SUBROUTINE PH_Elem_AC3D15_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormStiffMatrix` | 611 | `SUBROUTINE PH_Elem_AC3D15_FormStiffMatrix(coords, rho, c_sound, Ke, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormIntForce` | 637 | `SUBROUTINE PH_Elem_AC3D15_FormIntForce(coords, p, rho, c_sound, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_ConsMass` | 649 | `SUBROUTINE PH_Elem_AC3D15_ConsMass(coords, rho, Me, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_LumpMass` | 676 | `SUBROUTINE PH_Elem_AC3D15_LumpMass(coords, rho, M_lumped, method, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormDampingMatrix` | 716 | `SUBROUTINE PH_Elem_AC3D15_FormDampingMatrix(alpha_M, beta_K, Me, Ke, Ce, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_NL_TL` | 726 | `SUBROUTINE PH_Elem_AC3D15_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_NL_UL` | 745 | `SUBROUTINE PH_Elem_AC3D15_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_ApplyEssentialBC` | 767 | `SUBROUTINE PH_Elem_AC3D15_ApplyEssentialBC(idof, val, K_el, F_el, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_ApplyPenaltyBC` | 780 | `SUBROUTINE PH_Elem_AC3D15_ApplyPenaltyBC(idof, penalty, val, K_el, F_el, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormConstraintMatrix` | 791 | `SUBROUTINE PH_Elem_AC3D15_FormConstraintMatrix(c, val, penalty, K_el, F_el, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormAcousticImpedance` | 808 | `SUBROUTINE PH_Elem_AC3D15_FormAcousticImpedance(coords, Zc, rho, C_imp, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormRadiationCondition` | 832 | `SUBROUTINE PH_Elem_AC3D15_FormRadiationCondition(coords, face_normal, sound_speed, frequency, C_rad, K_rad, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormStructureCoupling` | 860 | `SUBROUTINE PH_Elem_AC3D15_FormStructureCoupling(coords, coupling_matrix, structure_dof_indices, acoustic_dof_indices, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormPressureLoad` | 886 | `SUBROUTINE PH_Elem_AC3D15_FormPressureLoad(coords, pressure, F_load, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormBodyForce` | 906 | `SUBROUTINE PH_Elem_AC3D15_FormBodyForce(coords, bx, by, bz, F_eq, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_FormSurfaceTraction` | 928 | `SUBROUTINE PH_Elem_AC3D15_FormSurfaceTraction(coords, t1, t2, F_traction, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_CalcPressure` | 972 | `SUBROUTINE PH_Elem_AC3D15_CalcPressure(coords, p, rho, c_sound, p_ip, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_CalcAcousticIntensity` | 987 | `SUBROUTINE PH_Elem_AC3D15_CalcAcousticIntensity(p, v, I_avg, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_CalcEnergy` | 995 | `SUBROUTINE PH_Elem_AC3D15_CalcEnergy(coords, p, rho, c_sound, E_acoustic, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_CalcEnergy_FromDesc` | 1004 | `SUBROUTINE PH_Elem_AC3D15_CalcEnergy_FromDesc(MD_Desc, p_elem, coords, E_acoustic, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_OutputResults` | 1046 | `SUBROUTINE PH_Elem_AC3D15_OutputResults(coords, p, svars, output, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_GetMaterialProps` | 1064 | `SUBROUTINE PH_Elem_AC3D15_GetMaterialProps(coords, Mat_Algo, rho, c_sound, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_GetMaterialProps_FromDesc` | 1096 | `SUBROUTINE PH_Elem_AC3D15_GetMaterialProps_FromDesc(MD_Desc, rho, c_sound, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_GetAcousticProps` | 1116 | `SUBROUTINE PH_Elem_AC3D15_GetAcousticProps(rho, c_sound, Zc, K_bulk, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_SetSectionProps` | 1135 | `SUBROUTINE PH_Elem_AC3D15_SetSectionProps(Sect_Registry, props, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_SetSectionProps_FromDesc` | 1155 | `SUBROUTINE PH_Elem_AC3D15_SetSectionProps_FromDesc(MD_Desc, props, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_ThermStrainVector` | 1181 | `SUBROUTINE PH_Elem_AC3D15_ThermStrainVector(coords, alpha_T, deltaT, eps_th, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_Temperature_Dependent_Speed` | 1205 | `SUBROUTINE PH_Elem_AC3D15_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_Thermal_Expansion_Source` | 1238 | `SUBROUTINE PH_Elem_AC3D15_Thermal_Expansion_Source(F_thermal, coords, temperature_field, MD_Desc, MD_Algo, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_UpdateMaterialProps_TempDep` | 1267 | `SUBROUTINE PH_Elem_AC3D15_UpdateMaterialProps_TempDep(rho, c_sound, temperature, T_ref, alpha_rho, alpha_c, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_Biot_Wave_Speed` | 1281 | `SUBROUTINE PH_Elem_AC3D15_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_Biot_Damping` | 1301 | `SUBROUTINE PH_Elem_AC3D15_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_Biot_Stabilize_SlowWave` | 1326 | `SUBROUTINE PH_Elem_AC3D15_Biot_Stabilize_SlowWave(C_stab, v_p2, rho_f, frequency, coords, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_Biot_Compute_Stab_Param` | 1351 | `SUBROUTINE PH_Elem_AC3D15_Biot_Compute_Stab_Param(tau_supg, element_size, v_p2, rho_f, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_Sommerfeld_Radiation` | 1365 | `SUBROUTINE PH_Elem_AC3D15_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_Infinite_Element_Map` | 1378 | `SUBROUTINE PH_Elem_AC3D15_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_PML_Update_State` | 1394 | `SUBROUTINE PH_Elem_AC3D15_PML_Update_State(pml_state, pml_params, time_step, pressure, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_PML_Absorbing_Boundary` | 1439 | `SUBROUTINE PH_Elem_AC3D15_PML_Absorbing_Boundary(coords, pml_thickness, sigma_max, C_pml, K_pml, status)` |
| SUBROUTINE | `PH_Elem_AC3D15_DefInit` | 1468 | `SUBROUTINE PH_Elem_AC3D15_DefInit()` |
| SUBROUTINE | `UF_Elem_AC3D15_Calc` | 1489 | `SUBROUTINE UF_Elem_AC3D15_Calc(ElemType, Formul, Ctx, state_in, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
