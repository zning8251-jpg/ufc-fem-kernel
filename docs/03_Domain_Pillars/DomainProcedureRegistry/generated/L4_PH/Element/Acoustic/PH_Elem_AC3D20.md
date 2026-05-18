# `PH_Elem_AC3D20.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC3D20.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_AC3D20`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC3D20`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC3D20`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC3D20.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Acoustic_Args` (lines 151–187)

```fortran
  TYPE :: PH_Elem_Acoustic_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Acoustic_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_AC3D20_GetArea` | 192 | `SUBROUTINE PH_Elem_AC3D20_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_AC3D20_GetCentroid` | 198 | `SUBROUTINE PH_Elem_AC3D20_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_AC3D20_GetSectProps` | 209 | `SUBROUTINE PH_Elem_AC3D20_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_AC3D20_ApplyConstraint` | 217 | `SUBROUTINE PH_Elem_AC3D20_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D20_ApplyMPC` | 230 | `SUBROUTINE PH_Elem_AC3D20_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormContactContrib` | 245 | `SUBROUTINE PH_Elem_AC3D20_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormContactEdgeCtr` | 255 | `SUBROUTINE PH_Elem_AC3D20_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormBodyForce` | 265 | `SUBROUTINE PH_Elem_AC3D20_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormNodalForce` | 272 | `SUBROUTINE PH_Elem_AC3D20_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_AC3D20_CollectIPVars` | 281 | `SUBROUTINE PH_Elem_AC3D20_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_AC3D20_EvalVonMises` | 290 | `SUBROUTINE PH_Elem_AC3D20_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_AC3D20_GetExtrapMat` | 296 | `SUBROUTINE PH_Elem_AC3D20_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_AC3D20_MapToNode` | 301 | `SUBROUTINE PH_Elem_AC3D20_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_ELEM_AC3D20_VolumeInt` | 308 | `SUBROUTINE PH_ELEM_AC3D20_VolumeInt(coords, volume)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormStiffMatrix` | 323 | `SUBROUTINE PH_Elem_AC3D20_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_AC3D20_ThermStrainVector` | 347 | `SUBROUTINE PH_Elem_AC3D20_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_AC3D20_ConsMass` | 353 | `SUBROUTINE PH_Elem_AC3D20_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_AC3D20_DefInit` | 376 | `SUBROUTINE PH_Elem_AC3D20_DefInit()` |
| SUBROUTINE | `PH_Elem_AC3D20_FormIntForce` | 379 | `SUBROUTINE PH_Elem_AC3D20_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_AC3D20_LumpMass` | 389 | `SUBROUTINE PH_Elem_AC3D20_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_AC3D20_NL_TL` | 402 | `SUBROUTINE PH_Elem_AC3D20_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_NL_UL` | 421 | `SUBROUTINE PH_Elem_AC3D20_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_Temperature_Dependent_Speed` | 444 | `SUBROUTINE PH_Elem_AC3D20_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_Thermal_Expansion_Source` | 477 | `SUBROUTINE PH_Elem_AC3D20_Thermal_Expansion_Source(F_thermal, coords, MD_Desc, MD_Algo, temperature_field, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_UpdateMaterialProps_TempDep` | 516 | `SUBROUTINE PH_Elem_AC3D20_UpdateMaterialProps_TempDep(coords, Mat_Algo, temperature, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_Biot_Wave_Speed` | 548 | `SUBROUTINE PH_Elem_AC3D20_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_Biot_Damping` | 596 | `SUBROUTINE PH_Elem_AC3D20_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_Biot_Stabilize_SlowWave` | 634 | `SUBROUTINE PH_Elem_AC3D20_Biot_Stabilize_SlowWave(tau_supg, coords, MD_Algo, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_Biot_Compute_Stab_Param` | 678 | `SUBROUTINE PH_Elem_AC3D20_Biot_Compute_Stab_Param(h_char, omega, c_fast, c_slow, stab_param, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_Sommerfeld_Radiation` | 713 | `SUBROUTINE PH_Elem_AC3D20_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, coords, status)` |
| SUBROUTINE | `GAUSS_3X3` | 755 | `SUBROUTINE GAUSS_3X3(xi, eta, w)` |
| SUBROUTINE | `PH_Elem_AC3D20_Infinite_Element_Map` | 772 | `SUBROUTINE PH_Elem_AC3D20_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_PML_Update_State` | 800 | `SUBROUTINE PH_Elem_AC3D20_PML_Update_State(pml_state, pml_params, time_step, pressure, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_PML_Absorbing_Boundary` | 836 | `SUBROUTINE PH_Elem_AC3D20_PML_Absorbing_Boundary(coords, pml_thickness, sigma_max, C_pml, K_pml, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormDampingMatrix` | 877 | `SUBROUTINE PH_Elem_AC3D20_FormDampingMatrix(coords, rho, alpha_r, beta_r, C_rayleigh, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_Rayleigh_Damping` | 906 | `SUBROUTINE PH_Elem_AC3D20_Rayleigh_Damping(C_rayleigh, M, K, alpha_r, beta_r, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_ApplyEssentialBC` | 922 | `SUBROUTINE PH_Elem_AC3D20_ApplyEssentialBC(p_elem, prescribed_value, node_index, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_ApplyPenaltyBC` | 940 | `SUBROUTINE PH_Elem_AC3D20_ApplyPenaltyBC(Ke, F_int, penalty, prescribed_value, node_index, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormConstraintMatrix` | 962 | `SUBROUTINE PH_Elem_AC3D20_FormConstraintMatrix(C, constraint_type, dof_indices, coefficients, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormAcousticImpedance` | 988 | `SUBROUTINE PH_Elem_AC3D20_FormAcousticImpedance(C_imp, K_imp, face_normal, sound_speed, density, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormRadiationCondition` | 1017 | `SUBROUTINE PH_Elem_AC3D20_FormRadiationCondition(C_rad, K_rad, coords, face_normal, sound_speed, frequency, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormStructureCoupling` | 1029 | `SUBROUTINE PH_Elem_AC3D20_FormStructureCoupling(K_fs, C_fs, F_fs, coords, face_normal, struct_stiffness, fluid_density, sound_speed, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormPressureLoad` | 1055 | `SUBROUTINE PH_Elem_AC3D20_FormPressureLoad(F_press, coords, face_id, pressure, status)` |
| SUBROUTINE | `GAUSS_3X3` | 1086 | `SUBROUTINE GAUSS_3X3(xi, eta, w)` |
| SUBROUTINE | `PH_Elem_AC3D20_FormSurfaceTraction` | 1103 | `SUBROUTINE PH_Elem_AC3D20_FormSurfaceTraction(F_traction, coords, traction, status)` |
| SUBROUTINE | `GAUSS_3X3` | 1138 | `SUBROUTINE GAUSS_3X3(xi, eta, w)` |
| SUBROUTINE | `PH_Elem_AC3D20_CalcPressure` | 1159 | `SUBROUTINE PH_Elem_AC3D20_CalcPressure(p_elem, p_nodes, p_ip, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_CalcAcousticIntensity` | 1182 | `SUBROUTINE PH_Elem_AC3D20_CalcAcousticIntensity(I_acoustic, p_elem, coords, density, sound_speed, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_CalcEnergy` | 1222 | `SUBROUTINE PH_Elem_AC3D20_CalcEnergy(E_acoustic, p_elem, coords, density, sound_speed, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_CalcEnergy_FromDesc` | 1265 | `SUBROUTINE PH_Elem_AC3D20_CalcEnergy_FromDesc(MD_Desc, p_elem, coords, E_acoustic, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_OutputResults` | 1288 | `SUBROUTINE PH_Elem_AC3D20_OutputResults(filename, p_elem, coords, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_GetMaterialProps` | 1304 | `SUBROUTINE PH_Elem_AC3D20_GetMaterialProps(coords, Mat_Algo, rho, c_sound, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_GetMaterialProps_FromDesc` | 1333 | `SUBROUTINE PH_Elem_AC3D20_GetMaterialProps_FromDesc(MD_Desc, rho, c_sound, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_GetAcousticProps` | 1350 | `SUBROUTINE PH_Elem_AC3D20_GetAcousticProps(rho, c_sound, Zc, K_bulk, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_SetSectionProps` | 1364 | `SUBROUTINE PH_Elem_AC3D20_SetSectionProps(Sect_Registry, props, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_SetSectionProps_FromDesc` | 1382 | `SUBROUTINE PH_Elem_AC3D20_SetSectionProps_FromDesc(MD_Desc, props, status)` |
| SUBROUTINE | `PH_Elem_AC3D20_GetVolume` | 1399 | `SUBROUTINE PH_Elem_AC3D20_GetVolume(volume, status)` |
| SUBROUTINE | `UF_Elem_AC3D20_Calc` | 1414 | `SUBROUTINE UF_Elem_AC3D20_Calc(ElemType, Formul, Ctx, state_in, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
