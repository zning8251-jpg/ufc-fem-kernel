# `PH_Elem_C3D10.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_C3D10.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_C3D10`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D10`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D10`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_C3D10.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Sld3D_Args` (lines 74–110)

```fortran
  TYPE :: PH_Elem_Sld3D_Args
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
  END TYPE PH_Elem_Sld3D_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_C3D10_ThermStrainVector` | 115 | `SUBROUTINE PH_Elem_C3D10_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_C3D10_BMatrix` | 122 | `SUBROUTINE PH_Elem_C3D10_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_C3D10_ConsMass` | 141 | `SUBROUTINE PH_Elem_C3D10_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_C3D10_ConstMatrix` | 167 | `SUBROUTINE PH_Elem_C3D10_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_C3D10_DefInit` | 188 | `SUBROUTINE PH_Elem_C3D10_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D10_FormIntForce` | 191 | `SUBROUTINE PH_Elem_C3D10_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D10_FormIntForceFromStress` | 201 | `SUBROUTINE PH_Elem_C3D10_FormIntForceFromStress(coords, sigma6, R_int)` |
| SUBROUTINE | `PH_Elem_C3D10_FormStiffMatrix` | 219 | `SUBROUTINE PH_Elem_C3D10_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D10_FormStiffMatrixFromD` | 236 | `SUBROUTINE PH_Elem_C3D10_FormStiffMatrixFromD(coords, D6, Ke)` |
| SUBROUTINE | `PH_Elem_C3D10_GaussPoints` | 252 | `SUBROUTINE PH_Elem_C3D10_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D10_GetVolumeInt` | 269 | `SUBROUTINE PH_Elem_C3D10_GetVolumeInt(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D10_Jac` | 284 | `SUBROUTINE PH_Elem_C3D10_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_C3D10_JacB` | 301 | `SUBROUTINE PH_Elem_C3D10_JacB(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_C3D10_LumpMass` | 335 | `SUBROUTINE PH_Elem_C3D10_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D10_NL_TL` | 350 | `SUBROUTINE PH_Elem_C3D10_NL_TL(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 471 | `SUBROUTINE Invert3x3(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_C3D10_NL_UL` | 487 | `SUBROUTINE PH_Elem_C3D10_NL_UL(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 611 | `SUBROUTINE Invert3x3(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_C3D10_Material_Update_Routed` | 627 | `SUBROUTINE PH_Elem_C3D10_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |
| SUBROUTINE | `PH_Elem_C3D10_ShapeFunc` | 645 | `SUBROUTINE PH_Elem_C3D10_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_C3D10_Strain` | 696 | `SUBROUTINE PH_Elem_C3D10_Strain(B, u, strain)` |
| SUBROUTINE | `PH_Elem_C3D10_Stress` | 703 | `SUBROUTINE PH_Elem_C3D10_Stress(epsilon, D, sigma)` |
| SUBROUTINE | `PH_Elem_C3D10_GetCentroid` | 711 | `SUBROUTINE PH_Elem_C3D10_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D10_GetInertiaOrig` | 735 | `SUBROUTINE PH_Elem_C3D10_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_C3D10_GetSectProps` | 765 | `SUBROUTINE PH_Elem_C3D10_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D10_GetVolume` | 774 | `SUBROUTINE PH_Elem_C3D10_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D10_ApplyConstraint` | 790 | `SUBROUTINE PH_Elem_C3D10_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D10_ApplyMPC` | 803 | `SUBROUTINE PH_Elem_C3D10_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D10_FormContactContrib` | 819 | `SUBROUTINE PH_Elem_C3D10_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D10_FormContactFaceCtr` | 848 | `SUBROUTINE PH_Elem_C3D10_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D10_FormFacePressure` | 882 | `SUBROUTINE PH_Elem_C3D10_FormFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D10_FormBodyForce` | 904 | `SUBROUTINE PH_Elem_C3D10_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D10_FormNodalForce` | 925 | `SUBROUTINE PH_Elem_C3D10_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D10_CollectIPVars` | 940 | `SUBROUTINE PH_Elem_C3D10_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_C3D10_EvalPrincStress` | 955 | `SUBROUTINE PH_Elem_C3D10_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_C3D10_EvalStrainInvar` | 1001 | `SUBROUTINE PH_Elem_C3D10_EvalStrainInvar(strain, I1e, J2e)` |
| SUBROUTINE | `PH_Elem_C3D10_EvalStressInvar` | 1012 | `SUBROUTINE PH_Elem_C3D10_EvalStressInvar(sigma, I1, J2, J3)` |
| SUBROUTINE | `PH_Elem_C3D10_EvalTriaxiality` | 1033 | `SUBROUTINE PH_Elem_C3D10_EvalTriaxiality(sigma, triax)` |
| SUBROUTINE | `PH_Elem_C3D10_EvalVonMises` | 1043 | `SUBROUTINE PH_Elem_C3D10_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_C3D10_GetExtrapMat` | 1055 | `SUBROUTINE PH_Elem_C3D10_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_C3D10_MapToNode` | 1064 | `SUBROUTINE PH_Elem_C3D10_MapToNode(ip_vars, weights, node_vars)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
