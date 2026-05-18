# `PH_Elem_CPE3.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_CPE3.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_CPE3`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CPE3`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CPE3`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_CPE3.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Sld2D_Args` (lines 75–111)

```fortran
  TYPE :: PH_Elem_Sld2D_Args
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
  END TYPE PH_Elem_Sld2D_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ELEM_CPE3_AreaInt` | 119 | `SUBROUTINE PH_ELEM_CPE3_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE3_ThermStrainVector` | 134 | `SUBROUTINE PH_Elem_CPE3_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_CPE3_BMatrix` | 144 | `SUBROUTINE PH_Elem_CPE3_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_CPE3_ConsMass` | 157 | `SUBROUTINE PH_Elem_CPE3_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CPE3_ConstMatrix` | 179 | `SUBROUTINE PH_Elem_CPE3_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_CPE3_DefInit` | 192 | `SUBROUTINE PH_Elem_CPE3_DefInit()` |
| SUBROUTINE | `PH_Elem_CPE3_FormIntForce` | 195 | `SUBROUTINE PH_Elem_CPE3_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_CPE3_FormIntForceFromStress` | 215 | `SUBROUTINE PH_Elem_CPE3_FormIntForceFromStress(coords, sigma3, R_int)` |
| SUBROUTINE | `PH_Elem_CPE3_FormStiffMatrix` | 231 | `SUBROUTINE PH_Elem_CPE3_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_CPE3_FormStiffMatrixFromD` | 248 | `SUBROUTINE PH_Elem_CPE3_FormStiffMatrixFromD(coords, D_matrix, Ke)` |
| SUBROUTINE | `PH_Elem_CPE3_GaussPoints` | 264 | `SUBROUTINE PH_Elem_CPE3_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CPE3_Jac` | 278 | `SUBROUTINE PH_Elem_CPE3_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPE3_JacB` | 294 | `SUBROUTINE PH_Elem_CPE3_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_CPE3_LumpMass` | 321 | `SUBROUTINE PH_Elem_CPE3_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CPE3_ShapeFunc` | 335 | `SUBROUTINE PH_Elem_CPE3_ShapeFunc(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPE3_Strain` | 350 | `SUBROUTINE PH_Elem_CPE3_Strain(B, u, strain)` |
| SUBROUTINE | `PH_Elem_CPE3_Stress` | 357 | `SUBROUTINE PH_Elem_CPE3_Stress(epsilon, D, sigma)` |
| SUBROUTINE | `PH_Elem_CPE3_GetArea` | 369 | `SUBROUTINE PH_Elem_CPE3_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE3_GetCentroid` | 375 | `SUBROUTINE PH_Elem_CPE3_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CPE3_GetSectProps` | 402 | `SUBROUTINE PH_Elem_CPE3_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_CPE3_ApplyConstraint` | 414 | `SUBROUTINE PH_Elem_CPE3_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE3_ApplyMPC` | 427 | `SUBROUTINE PH_Elem_CPE3_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE3_FormContactContrib` | 445 | `SUBROUTINE PH_Elem_CPE3_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE3_FormContactEdgeCtr` | 477 | `SUBROUTINE PH_Elem_CPE3_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE3_FormEdgePressure` | 516 | `SUBROUTINE PH_Elem_CPE3_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE3_FormBodyForce` | 539 | `SUBROUTINE PH_Elem_CPE3_FormBodyForce(coords, bx, by, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE3_FormNodalForce` | 559 | `SUBROUTINE PH_Elem_CPE3_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `invert_3x3` | 576 | `SUBROUTINE invert_3x3(A, info)` |
| SUBROUTINE | `PH_Elem_CPE3_CollectIPVars` | 605 | `SUBROUTINE PH_Elem_CPE3_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CPE3_EvalPrincStress` | 627 | `SUBROUTINE PH_Elem_CPE3_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CPE3_EvalStressInvar` | 640 | `SUBROUTINE PH_Elem_CPE3_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CPE3_EvalVonMises` | 651 | `SUBROUTINE PH_Elem_CPE3_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CPE3_GetExtrapMat` | 661 | `SUBROUTINE PH_Elem_CPE3_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CPE3_MapToNode` | 680 | `SUBROUTINE PH_Elem_CPE3_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_CPE3_NL_TL` | 701 | `SUBROUTINE PH_Elem_CPE3_NL_TL(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPE3_NL_UL` | 767 | `SUBROUTINE PH_Elem_CPE3_NL_UL(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPE3_Material_Update_Routed` | 833 | `SUBROUTINE PH_Elem_CPE3_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
