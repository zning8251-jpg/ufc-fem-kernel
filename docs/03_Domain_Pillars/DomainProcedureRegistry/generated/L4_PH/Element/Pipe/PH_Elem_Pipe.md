# `PH_Elem_Pipe.f90`

- **Source**: `L4_PH/Element/Pipe/PH_Elem_Pipe.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_Pipe`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Pipe`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Pipe`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Pipe`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Pipe/PH_Elem_Pipe.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Pipe_Args` (lines 72–114)

```fortran
  TYPE :: PH_Elem_Pipe_Args
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
  REAL(wp)              :: k_therm     = 0.0_wp  ! thermal conductivity scale
  REAL(wp)              :: rho_cp      = 0.0_wp  ! density times heat capacity
  REAL(wp), POINTER     :: T_elem(:)   => NULL()  ! element temperature vector ptr
  REAL(wp), POINTER     :: Ktherm(:,:) => NULL()  ! thermal-thermal block ptr
  REAL(wp), POINTER     :: F_heat(:)   => NULL()  ! thermal force / heat flux load ptr
  REAL(wp), POINTER     :: ip_temp(:)  => NULL()  ! IP temperature ptr
  END TYPE PH_Elem_Pipe_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Pipe_CopyCoords12` | 120 | `PURE SUBROUTINE Pipe_CopyCoords12(coords, c12, ok)` |
| SUBROUTINE | `Pipe_ResolveAreaOpt` | 133 | `PURE SUBROUTINE Pipe_ResolveAreaOpt(area_opt, aout)` |
| SUBROUTINE | `UF_Elem_Pipe_Calc` | 145 | `SUBROUTINE UF_Elem_Pipe_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `UPPER_CASE` | 189 | `SUBROUTINE UPPER_CASE(str)` |
| SUBROUTINE | `PH_Elem_PIPE21_DefInit` | 201 | `SUBROUTINE PH_Elem_PIPE21_DefInit()` |
| SUBROUTINE | `PH_Elem_PIPE21_FormStiffMatrix` | 204 | `SUBROUTINE PH_Elem_PIPE21_FormStiffMatrix(coords, E_young, nu, Ke, area)` |
| SUBROUTINE | `PH_Elem_PIPE21_ThermStrainVector` | 219 | `SUBROUTINE PH_Elem_PIPE21_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_PIPE21_ConsMass` | 228 | `SUBROUTINE PH_Elem_PIPE21_ConsMass(coords, rho, Me, area)` |
| SUBROUTINE | `PH_Elem_PIPE21_FormIntForce` | 243 | `SUBROUTINE PH_Elem_PIPE21_FormIntForce(coords, u, E_young, nu, R_int, area)` |
| SUBROUTINE | `PH_Elem_PIPE21_LumpMass` | 259 | `SUBROUTINE PH_Elem_PIPE21_LumpMass(coords, rho, M_lumped, area)` |
| SUBROUTINE | `PH_Elem_PIPE21_NL_TL` | 274 | `SUBROUTINE PH_Elem_PIPE21_NL_TL(coords_ref, u_elem, D, area, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_PIPE21_NL_UL` | 360 | `SUBROUTINE PH_Elem_PIPE21_NL_UL(coords_prev, u_incr, D, area, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_PIPE22_DefInit` | 449 | `SUBROUTINE PH_Elem_PIPE22_DefInit()` |
| SUBROUTINE | `PH_Elem_PIPE22_FormStiffMatrix` | 452 | `SUBROUTINE PH_Elem_PIPE22_FormStiffMatrix(coords, E_young, nu, Ke, area)` |
| SUBROUTINE | `PH_Elem_PIPE22_ThermStrainVector` | 460 | `SUBROUTINE PH_Elem_PIPE22_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_PIPE22_ConsMass` | 466 | `SUBROUTINE PH_Elem_PIPE22_ConsMass(coords, rho, Me, area)` |
| SUBROUTINE | `PH_Elem_PIPE22_FormIntForce` | 474 | `SUBROUTINE PH_Elem_PIPE22_FormIntForce(coords, u, E_young, nu, R_int, area)` |
| SUBROUTINE | `PH_Elem_PIPE22_LumpMass` | 483 | `SUBROUTINE PH_Elem_PIPE22_LumpMass(coords, rho, M_lumped, area)` |
| SUBROUTINE | `PH_Elem_PIPE22_NL_TL` | 491 | `SUBROUTINE PH_Elem_PIPE22_NL_TL(coords_ref, u_elem, D, area, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_PIPE22_NL_UL` | 501 | `SUBROUTINE PH_Elem_PIPE22_NL_UL(coords_prev, u_incr, D, area, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_PIPE21_GetArea` | 514 | `SUBROUTINE PH_Elem_PIPE21_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_PIPE21_GetCentroid` | 525 | `SUBROUTINE PH_Elem_PIPE21_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_PIPE21_GetSectProps` | 536 | `SUBROUTINE PH_Elem_PIPE21_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_PIPE22_GetArea` | 553 | `SUBROUTINE PH_Elem_PIPE22_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_PIPE22_GetCentroid` | 559 | `SUBROUTINE PH_Elem_PIPE22_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_PIPE22_GetSectProps` | 565 | `SUBROUTINE PH_Elem_PIPE22_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_PIPE21_ApplyConstraint` | 575 | `SUBROUTINE PH_Elem_PIPE21_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_PIPE21_ApplyMPC` | 588 | `SUBROUTINE PH_Elem_PIPE21_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_PIPE22_ApplyConstraint` | 606 | `SUBROUTINE PH_Elem_PIPE22_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_PIPE22_ApplyMPC` | 619 | `SUBROUTINE PH_Elem_PIPE22_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_PIPE21_FormContactContrib` | 637 | `SUBROUTINE PH_Elem_PIPE21_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_PIPE21_FormContactEdgeCtr` | 647 | `SUBROUTINE PH_Elem_PIPE21_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_PIPE22_FormContactContrib` | 660 | `SUBROUTINE PH_Elem_PIPE22_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_PIPE22_FormContactEdgeCtr` | 670 | `SUBROUTINE PH_Elem_PIPE22_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_PIPE21_FormNodalForce` | 683 | `SUBROUTINE PH_Elem_PIPE21_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_PIPE21_FormBodyForce` | 697 | `SUBROUTINE PH_Elem_PIPE21_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_PIPE22_FormNodalForce` | 712 | `SUBROUTINE PH_Elem_PIPE22_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_PIPE22_FormBodyForce` | 721 | `SUBROUTINE PH_Elem_PIPE22_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_PIPE21_CollectIPVars` | 731 | `SUBROUTINE PH_Elem_PIPE21_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_PIPE21_EvalVonMises` | 740 | `SUBROUTINE PH_Elem_PIPE21_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_PIPE21_EvalPipeStress` | 750 | `SUBROUTINE PH_Elem_PIPE21_EvalPipeStress(sigma, seq)` |
| SUBROUTINE | `PH_Elem_PIPE21_GetExtrapMat` | 756 | `SUBROUTINE PH_Elem_PIPE21_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_PIPE21_MapToNode` | 769 | `SUBROUTINE PH_Elem_PIPE21_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_PIPE22_CollectIPVars` | 779 | `SUBROUTINE PH_Elem_PIPE22_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_PIPE22_EvalVonMises` | 788 | `SUBROUTINE PH_Elem_PIPE22_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_PIPE22_EvalPipeStress` | 794 | `SUBROUTINE PH_Elem_PIPE22_EvalPipeStress(sigma, seq)` |
| SUBROUTINE | `PH_Elem_PIPE22_GetExtrapMat` | 800 | `SUBROUTINE PH_Elem_PIPE22_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_PIPE22_MapToNode` | 805 | `SUBROUTINE PH_Elem_PIPE22_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `UF_Elem_PIPE21_Calc` | 815 | `SUBROUTINE UF_Elem_PIPE21_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `UF_Elem_PIPE22_Calc` | 948 | `SUBROUTINE UF_Elem_PIPE22_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PH_Elem_PIPE21_Material_Update_Routed` | 1078 | `SUBROUTINE PH_Elem_PIPE21_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &` |
| SUBROUTINE | `PH_Elem_PIPE22_Material_Update_Routed` | 1096 | `SUBROUTINE PH_Elem_PIPE22_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
