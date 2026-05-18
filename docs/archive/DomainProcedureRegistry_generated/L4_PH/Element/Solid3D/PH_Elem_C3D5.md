# `PH_Elem_C3D5.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_C3D5.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_C3D5`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D5`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D5`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_C3D5.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Sld3D_Args` (lines 72–108)

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
| SUBROUTINE | `PH_Elem_C3D5_ThermStrainVector` | 113 | `SUBROUTINE PH_Elem_C3D5_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_C3D5_BMatrix` | 120 | `SUBROUTINE PH_Elem_C3D5_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_C3D5_ConsMass` | 139 | `SUBROUTINE PH_Elem_C3D5_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_C3D5_ConstMatrix` | 165 | `SUBROUTINE PH_Elem_C3D5_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_C3D5_DefInit` | 186 | `SUBROUTINE PH_Elem_C3D5_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D5_FormIntForce` | 189 | `SUBROUTINE PH_Elem_C3D5_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D5_FormIntForceFromStress` | 199 | `SUBROUTINE PH_Elem_C3D5_FormIntForceFromStress(coords, sigma6, R_int)` |
| SUBROUTINE | `PH_Elem_C3D5_FormStiffMatrix` | 217 | `SUBROUTINE PH_Elem_C3D5_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D5_FormStiffMatrixFromD` | 234 | `SUBROUTINE PH_Elem_C3D5_FormStiffMatrixFromD(coords, D6, Ke)` |
| SUBROUTINE | `PH_Elem_C3D5_GaussPoints` | 250 | `SUBROUTINE PH_Elem_C3D5_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D5_GetVolumeInt` | 275 | `SUBROUTINE PH_Elem_C3D5_GetVolumeInt(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D5_Jac` | 290 | `SUBROUTINE PH_Elem_C3D5_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_C3D5_JacB` | 307 | `SUBROUTINE PH_Elem_C3D5_JacB(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_C3D5_LumpMass` | 341 | `SUBROUTINE PH_Elem_C3D5_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D5_NL_TL` | 356 | `SUBROUTINE PH_Elem_C3D5_NL_TL(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 482 | `SUBROUTINE Invert3x3(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_C3D5_NL_UL` | 498 | `SUBROUTINE PH_Elem_C3D5_NL_UL(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 627 | `SUBROUTINE Invert3x3(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_C3D5_ShapeFunc` | 643 | `SUBROUTINE PH_Elem_C3D5_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_C3D5_Strain` | 673 | `SUBROUTINE PH_Elem_C3D5_Strain(B, u, strain)` |
| SUBROUTINE | `PH_Elem_C3D5_Stress` | 680 | `SUBROUTINE PH_Elem_C3D5_Stress(epsilon, D, sigma)` |
| SUBROUTINE | `PH_Elem_C3D5_GetCentroid` | 688 | `SUBROUTINE PH_Elem_C3D5_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D5_GetInertiaOrig` | 712 | `SUBROUTINE PH_Elem_C3D5_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_C3D5_GetSectProps` | 742 | `SUBROUTINE PH_Elem_C3D5_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D5_GetVolume` | 751 | `SUBROUTINE PH_Elem_C3D5_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D5_ApplyConstraint` | 767 | `SUBROUTINE PH_Elem_C3D5_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D5_ApplyMPC` | 780 | `SUBROUTINE PH_Elem_C3D5_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D5_FormContactContrib` | 796 | `SUBROUTINE PH_Elem_C3D5_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D5_FormContactFaceCtr` | 825 | `SUBROUTINE PH_Elem_C3D5_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D5_FormFacePressure` | 861 | `SUBROUTINE PH_Elem_C3D5_FormFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D5_FormBodyForce` | 899 | `SUBROUTINE PH_Elem_C3D5_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D5_FormNodalForce` | 920 | `SUBROUTINE PH_Elem_C3D5_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D5_CollectIPVars` | 935 | `SUBROUTINE PH_Elem_C3D5_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_C3D5_EvalPrincStress` | 950 | `SUBROUTINE PH_Elem_C3D5_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_C3D5_EvalStrainInvar` | 996 | `SUBROUTINE PH_Elem_C3D5_EvalStrainInvar(strain, I1e, J2e)` |
| SUBROUTINE | `PH_Elem_C3D5_EvalStressInvar` | 1007 | `SUBROUTINE PH_Elem_C3D5_EvalStressInvar(sigma, I1, J2, J3)` |
| SUBROUTINE | `PH_Elem_C3D5_EvalTriaxiality` | 1028 | `SUBROUTINE PH_Elem_C3D5_EvalTriaxiality(sigma, triax)` |
| SUBROUTINE | `PH_Elem_C3D5_EvalVonMises` | 1038 | `SUBROUTINE PH_Elem_C3D5_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_C3D5_GetExtrapMat` | 1050 | `SUBROUTINE PH_Elem_C3D5_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_C3D5_MapToNode` | 1061 | `SUBROUTINE PH_Elem_C3D5_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_C3D5_Material_Update_Routed` | 1075 | `SUBROUTINE PH_Elem_C3D5_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
