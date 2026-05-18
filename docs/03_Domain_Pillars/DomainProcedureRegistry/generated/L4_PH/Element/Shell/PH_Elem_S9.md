# `PH_Elem_S9.f90`

- **Source**: `L4_PH/Element/Shell/PH_Elem_S9.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_S9`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_S9`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_S9`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shell`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shell/PH_Elem_S9.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Shell_Args` (lines 61–97)

```fortran
  TYPE :: PH_Elem_Shell_Args
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
  END TYPE PH_Elem_Shell_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_S9_BMatrix` | 105 | `SUBROUTINE PH_Elem_S9_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_S9_ConsMass` | 118 | `SUBROUTINE PH_Elem_S9_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_S9_ConstMatrix` | 147 | `SUBROUTINE PH_Elem_S9_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_S9_DefInit` | 163 | `SUBROUTINE PH_Elem_S9_DefInit()` |
| SUBROUTINE | `PH_Elem_S9_FormIntForce` | 166 | `SUBROUTINE PH_Elem_S9_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_S9_FormStiffMatrix` | 202 | `SUBROUTINE PH_Elem_S9_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_S9_GaussPoints` | 234 | `SUBROUTINE PH_Elem_S9_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_S9_Jac` | 244 | `SUBROUTINE PH_Elem_S9_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_ELEM_S9_Invert2x2` | 260 | `SUBROUTINE PH_ELEM_S9_Invert2x2(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_S9_LumpMass` | 270 | `SUBROUTINE PH_Elem_S9_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_S9_NL_TL` | 288 | `SUBROUTINE PH_Elem_S9_NL_TL(coords_ref, u_elem, mat_prop, mat_state, thickness, n_layers, &` |
| SUBROUTINE | `PH_Elem_S9_NL_UL` | 415 | `SUBROUTINE PH_Elem_S9_NL_UL(coords_prev, u_incr, mat_prop, mat_state, thickness, n_layers, &` |
| SUBROUTINE | `PH_Elem_S9_ShapeFunc` | 550 | `SUBROUTINE PH_Elem_S9_ShapeFunc(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_S9_ThermStrainVector` | 597 | `SUBROUTINE PH_Elem_S9_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_ELEM_S9_AreaInt` | 608 | `SUBROUTINE PH_ELEM_S9_AreaInt(coords, area)` |
| SUBROUTINE | `UF_Elem_S9_Calc` | 623 | `SUBROUTINE UF_Elem_S9_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `PH_Elem_S9_GetArea` | 698 | `SUBROUTINE PH_Elem_S9_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_S9_GetCentroid` | 704 | `SUBROUTINE PH_Elem_S9_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_S9_GetSectProps` | 732 | `SUBROUTINE PH_Elem_S9_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_S9_ApplyConstraint` | 743 | `SUBROUTINE PH_Elem_S9_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S9_ApplyMPC` | 756 | `SUBROUTINE PH_Elem_S9_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S9_FormContactContrib` | 774 | `SUBROUTINE PH_Elem_S9_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S9_FormContactEdgeCtr` | 809 | `SUBROUTINE PH_Elem_S9_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S9_FormBodyForce` | 848 | `SUBROUTINE PH_Elem_S9_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_S9_FormEdgePressure` | 869 | `SUBROUTINE PH_Elem_S9_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S9_FormNodalForce` | 899 | `SUBROUTINE PH_Elem_S9_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S9_CollectIPVars` | 916 | `SUBROUTINE PH_Elem_S9_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_S9_EvalVonMises` | 931 | `SUBROUTINE PH_Elem_S9_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_S9_GetExtrapMat` | 944 | `SUBROUTINE PH_Elem_S9_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_S9_MapToNode` | 959 | `SUBROUTINE PH_Elem_S9_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_S9_Material_Update_Membrane_Routed` | 974 | `SUBROUTINE PH_Elem_S9_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
