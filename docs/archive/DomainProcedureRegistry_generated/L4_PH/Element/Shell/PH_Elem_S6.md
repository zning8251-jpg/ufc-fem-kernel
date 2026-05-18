# `PH_Elem_S6.f90`

- **Source**: `L4_PH/Element/Shell/PH_Elem_S6.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_S6`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_S6`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_S6`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shell`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shell/PH_Elem_S6.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Shell_Args` (lines 80–116)

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
| SUBROUTINE | `PH_Elem_S6_ConsMass` | 121 | `SUBROUTINE PH_Elem_S6_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_S6_DefInit` | 136 | `SUBROUTINE PH_Elem_S6_DefInit()` |
| SUBROUTINE | `PH_Elem_S6_FormIntForce` | 139 | `SUBROUTINE PH_Elem_S6_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_S6_FormStiffMatrix` | 156 | `SUBROUTINE PH_Elem_S6_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_S6_LumpMass` | 171 | `SUBROUTINE PH_Elem_S6_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_S6_NL_TL` | 185 | `SUBROUTINE PH_Elem_S6_NL_TL(coords_ref, u_elem, mat_prop, mat_state, thickness, n_layers, &` |
| SUBROUTINE | `Invert2x2` | 305 | `SUBROUTINE Invert2x2(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_S6_NL_UL` | 314 | `SUBROUTINE PH_Elem_S6_NL_UL(coords_prev, u_incr, mat_prop, mat_state, thickness, n_layers, &` |
| SUBROUTINE | `Invert2x2` | 426 | `SUBROUTINE Invert2x2(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_S6_ThermStrainVector` | 434 | `SUBROUTINE PH_Elem_S6_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_ELEM_S6_AreaInt` | 443 | `SUBROUTINE PH_ELEM_S6_AreaInt(coords, area)` |
| SUBROUTINE | `UF_Elem_S6_Calc` | 458 | `SUBROUTINE UF_Elem_S6_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PH_Elem_S6_GetArea` | 554 | `SUBROUTINE PH_Elem_S6_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_S6_GetCentroid` | 560 | `SUBROUTINE PH_Elem_S6_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_S6_GetSectProps` | 588 | `SUBROUTINE PH_Elem_S6_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_S6_ApplyConstraint` | 596 | `SUBROUTINE PH_Elem_S6_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S6_ApplyMPC` | 609 | `SUBROUTINE PH_Elem_S6_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_ELEM_S6_CrossProduct` | 624 | `SUBROUTINE PH_ELEM_S6_CrossProduct(a, b, c)` |
| SUBROUTINE | `PH_Elem_S6_FormContactContrib` | 632 | `SUBROUTINE PH_Elem_S6_FormContactContrib(coords, gap_field, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S6_FormContactEdgeCtr` | 646 | `SUBROUTINE PH_Elem_S6_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S6_FormBodyForce` | 678 | `SUBROUTINE PH_Elem_S6_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_S6_FormEdgePressure` | 699 | `SUBROUTINE PH_Elem_S6_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S6_FormNodalForce` | 729 | `SUBROUTINE PH_Elem_S6_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S6_CollectIPVars` | 743 | `SUBROUTINE PH_Elem_S6_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_S6_EvalVonMises` | 758 | `SUBROUTINE PH_Elem_S6_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_S6_GetExtrapMat` | 771 | `SUBROUTINE PH_Elem_S6_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_S6_MapToNode` | 786 | `SUBROUTINE PH_Elem_S6_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_S6_Material_Update_Membrane_Routed` | 801 | `SUBROUTINE PH_Elem_S6_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
