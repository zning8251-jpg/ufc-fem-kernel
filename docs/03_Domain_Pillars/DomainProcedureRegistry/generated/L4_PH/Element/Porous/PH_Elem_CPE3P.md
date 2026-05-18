# `PH_Elem_CPE3P.f90`

- **Source**: `L4_PH/Element/Porous/PH_Elem_CPE3P.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_CPE3P`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CPE3P`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CPE3P`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Porous`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Porous/PH_Elem_CPE3P.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Porous_Args` (lines 57–101)

```fortran
  TYPE :: PH_Elem_Porous_Args
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
  REAL(wp)              :: k_hyd       = 0.0_wp  ! hydraulic permeability scale
  REAL(wp)              :: alpha_b     = 1.0_wp ! Biot
  REAL(wp), POINTER     :: u_struct(:) => NULL()  ! packed structural displacement ptr
  REAL(wp), POINTER     :: p_pore(:)   => NULL()  ! nodal pore pressure ptr
  REAL(wp), POINTER     :: Kuu(:,:)    => NULL()  ! displacement-displacement block ptr
  REAL(wp), POINTER     :: Kpp(:,:)    => NULL()  ! pressure-pressure block ptr
  REAL(wp), POINTER     :: Kup(:,:)    => NULL()  ! displacement-pressure coupling block ptr
  REAL(wp), POINTER     :: ip_pore(:)  => NULL()  ! IP pore pressure ptr
  END TYPE PH_Elem_Porous_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CPE3P_BpMatrix` | 106 | `SUBROUTINE PH_Elem_CPE3P_BpMatrix(dNdx, Bp)` |
| SUBROUTINE | `PH_Elem_CPE3P_BMatrix` | 116 | `SUBROUTINE PH_Elem_CPE3P_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_CPE3P_DefInit` | 129 | `SUBROUTINE PH_Elem_CPE3P_DefInit()` |
| SUBROUTINE | `PH_Elem_CPE3P_GaussPoints` | 132 | `SUBROUTINE PH_Elem_CPE3P_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CPE3P_ShapeFunc` | 139 | `SUBROUTINE PH_Elem_CPE3P_ShapeFunc(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPE3P_Jac` | 146 | `SUBROUTINE PH_Elem_CPE3P_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPE3P_JacB` | 154 | `SUBROUTINE PH_Elem_CPE3P_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B, Bp)` |
| SUBROUTINE | `PH_Elem_CPE3P_FormStiffMatrix` | 165 | `SUBROUTINE PH_Elem_CPE3P_FormStiffMatrix(coords, D_struct, k_hyd, alpha_b, Ke)` |
| SUBROUTINE | `PH_Elem_CPE3P_FormIntForce` | 202 | `SUBROUTINE PH_Elem_CPE3P_FormIntForce(coords, u_struct, p_pore, D_struct, k_hyd, alpha_b, R_int)` |
| SUBROUTINE | `PH_Elem_CPE3P_NL_TL` | 232 | `SUBROUTINE PH_Elem_CPE3P_NL_TL(coords_ref, u_elem, D, k_hyd, alpha_b, &` |
| SUBROUTINE | `PH_Elem_CPE3P_NL_UL` | 249 | `SUBROUTINE PH_Elem_CPE3P_NL_UL(coords_prev, u_incr, D, k_hyd, alpha_b, &` |
| SUBROUTINE | `PH_Elem_CPE3P_GetCentroid` | 266 | `SUBROUTINE PH_Elem_CPE3P_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CPE3P_GetInertiaOrig` | 290 | `SUBROUTINE PH_Elem_CPE3P_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_CPE3P_GetSectProps` | 318 | `SUBROUTINE PH_Elem_CPE3P_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_CPE3P_GetArea` | 326 | `SUBROUTINE PH_Elem_CPE3P_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE3P_ApplyConstraint` | 341 | `SUBROUTINE PH_Elem_CPE3P_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE3P_ApplyMPC` | 354 | `SUBROUTINE PH_Elem_CPE3P_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE3P_FormContactContrib` | 369 | `SUBROUTINE PH_Elem_CPE3P_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE3P_FormContactEdgeCtr` | 401 | `SUBROUTINE PH_Elem_CPE3P_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE3P_FormFacePressure` | 431 | `SUBROUTINE PH_Elem_CPE3P_FormFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE3P_FormBodyForce` | 454 | `SUBROUTINE PH_Elem_CPE3P_FormBodyForce(coords, bx, by, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE3P_FormPoreSource` | 474 | `SUBROUTINE PH_Elem_CPE3P_FormPoreSource(coords, q_source, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE3P_FormNodalForce` | 493 | `SUBROUTINE PH_Elem_CPE3P_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE3P_EvalPrincStress` | 509 | `SUBROUTINE PH_Elem_CPE3P_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CPE3P_EvalStressInvar` | 522 | `SUBROUTINE PH_Elem_CPE3P_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CPE3P_CollectIPVars` | 533 | `SUBROUTINE PH_Elem_CPE3P_CollectIPVars(ip_stress, ip_strain, ip_pore, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CPE3P_EvalVonMises` | 550 | `SUBROUTINE PH_Elem_CPE3P_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CPE3P_GetExtrapMat` | 560 | `SUBROUTINE PH_Elem_CPE3P_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CPE3P_MapToNode` | 565 | `SUBROUTINE PH_Elem_CPE3P_MapToNode(ip_vars, weights, node_vars)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
