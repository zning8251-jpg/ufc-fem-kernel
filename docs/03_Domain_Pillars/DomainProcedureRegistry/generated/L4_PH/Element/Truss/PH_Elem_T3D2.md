# `PH_Elem_T3D2.f90`

- **Source**: `L4_PH/Element/Truss/PH_Elem_T3D2.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_T3D2`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_T3D2`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_T3D2`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Truss`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Truss/PH_Elem_T3D2.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Truss_Args` (lines 65–101)

```fortran
  TYPE :: PH_Elem_Truss_Args
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
  END TYPE PH_Elem_Truss_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_T3D2_ThermStrainVector` | 109 | `SUBROUTINE PH_Elem_T3D2_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_T3D2_BMatrix` | 115 | `SUBROUTINE PH_Elem_T3D2_BMatrix(coords, L, e_dir, B)` |
| SUBROUTINE | `PH_Elem_T3D2_ConsMass` | 135 | `SUBROUTINE PH_Elem_T3D2_ConsMass(coords, rho, area, Me)` |
| SUBROUTINE | `PH_Elem_T3D2_DefInit` | 155 | `SUBROUTINE PH_Elem_T3D2_DefInit()` |
| SUBROUTINE | `PH_Elem_T3D2_FormIntForce` | 158 | `SUBROUTINE PH_Elem_T3D2_FormIntForce(coords, u, E_young, area, R_int)` |
| SUBROUTINE | `PH_Elem_T3D2_FormStiffMatrix` | 178 | `SUBROUTINE PH_Elem_T3D2_FormStiffMatrix(coords, E_young, area, Ke)` |
| SUBROUTINE | `PH_Elem_T3D2_LumpMass` | 194 | `SUBROUTINE PH_Elem_T3D2_LumpMass(coords, rho, area, M_lumped)` |
| SUBROUTINE | `PH_Elem_T3D2_NL_TL` | 210 | `SUBROUTINE PH_Elem_T3D2_NL_TL(coords_ref, u_elem, E_young, area, &` |
| SUBROUTINE | `PH_Elem_T3D2_NL_UL` | 294 | `SUBROUTINE PH_Elem_T3D2_NL_UL(coords_prev, u_incr, E_young, area, &` |
| SUBROUTINE | `PH_Elem_T3D2_ShapeFunc` | 378 | `SUBROUTINE PH_Elem_T3D2_ShapeFunc(xi, N)` |
| SUBROUTINE | `UF_Elem_T3D2_Calc` | 385 | `SUBROUTINE UF_Elem_T3D2_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PH_Elem_T3D2_GetArea` | 599 | `SUBROUTINE PH_Elem_T3D2_GetArea(area_in, area)` |
| SUBROUTINE | `PH_Elem_T3D2_GetCentroid` | 605 | `SUBROUTINE PH_Elem_T3D2_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_T3D2_GetLength` | 613 | `SUBROUTINE PH_Elem_T3D2_GetLength(coords, length)` |
| SUBROUTINE | `PH_Elem_T3D2_GetSectProps` | 623 | `SUBROUTINE PH_Elem_T3D2_GetSectProps(coords, density_in, area_in, length, mass)` |
| SUBROUTINE | `PH_Elem_T3D2_ApplyConstraint` | 634 | `SUBROUTINE PH_Elem_T3D2_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_T3D2_ApplyMPC` | 647 | `SUBROUTINE PH_Elem_T3D2_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_T3D2_FormContactContrib` | 665 | `SUBROUTINE PH_Elem_T3D2_FormContactContrib(edge_id, xi, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_T3D2_FormContactEdgeCtr` | 675 | `SUBROUTINE PH_Elem_T3D2_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_T3D2_FormBodyForce` | 688 | `SUBROUTINE PH_Elem_T3D2_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_T3D2_FormNodalForce` | 714 | `SUBROUTINE PH_Elem_T3D2_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_T3D2_CollectIPVars` | 729 | `SUBROUTINE PH_Elem_T3D2_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_T3D2_EvalAxialStress` | 741 | `SUBROUTINE PH_Elem_T3D2_EvalAxialStress(strain, E_young, sigma)` |
| SUBROUTINE | `PH_Elem_T3D2_GetExtrapMat` | 748 | `SUBROUTINE PH_Elem_T3D2_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_T3D2_MapToNode` | 754 | `SUBROUTINE PH_Elem_T3D2_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_T3D2_Material_Update_Routed` | 765 | `SUBROUTINE PH_Elem_T3D2_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
