# `PH_Elem_Membrane.f90`

- **Source**: `L4_PH/Element/Membrane/PH_Elem_Membrane.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_Membrane`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_Membrane`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_Membrane`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Membrane`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Membrane/PH_Elem_Membrane.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Membrane_Args` (lines 51–87)

```fortran
  TYPE :: PH_Elem_Membrane_Args
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
  END TYPE PH_Elem_Membrane_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Memb_Q4_ShapesAndDerivs` | 92 | `PURE SUBROUTINE Memb_Q4_ShapesAndDerivs(xi, eta, N, dN1dxi, dN2dxi, dN3dxi, dN4dxi, &` |
| SUBROUTINE | `Memb_BuildPlaneFrame` | 111 | `SUBROUTINE Memb_BuildPlaneFrame(c4, e1, e2, e3, x0, ok)` |
| SUBROUTINE | `Memb_FillTransformT` | 145 | `SUBROUTINE Memb_FillTransformT(e1, e2, T)` |
| SUBROUTINE | `Memb_Q4_StiffMass` | 160 | `SUBROUTINE Memb_Q4_StiffMass(xl, yl, rho, want_mass, E, nu, t, Ke8, Me8, ok)` |
| SUBROUTINE | `Memb_AssembleGlobalK` | 246 | `SUBROUTINE Memb_AssembleGlobalK(Ke8, e1, e2, Ke12)` |
| SUBROUTINE | `Memb_AssembleGlobalM` | 255 | `SUBROUTINE Memb_AssembleGlobalM(Me8, e1, e2, Me12)` |
| SUBROUTINE | `Memb_M3D9R_LinearCore` | 264 | `SUBROUTINE Memb_M3D9R_LinearCore(coords, E_young, nu, thick, rho, want_mass, Ke12, Me12, &` |
| SUBROUTINE | `UF_Elem_Membrane_Calc` | 294 | `SUBROUTINE UF_Elem_Membrane_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `UPPER_CASE` | 335 | `SUBROUTINE UPPER_CASE(str)` |
| SUBROUTINE | `PH_Elem_M3D9R_DefInit` | 347 | `SUBROUTINE PH_Elem_M3D9R_DefInit()` |
| SUBROUTINE | `PH_Elem_M3D9R_FormStiffMatrix` | 350 | `SUBROUTINE PH_Elem_M3D9R_FormStiffMatrix(coords, E_young, nu, Ke, thickness)` |
| SUBROUTINE | `PH_Elem_M3D9R_ThermStrainVector` | 366 | `SUBROUTINE PH_Elem_M3D9R_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_M3D9R_ConsMass` | 378 | `SUBROUTINE PH_Elem_M3D9R_ConsMass(coords, rho, Me, thickness)` |
| SUBROUTINE | `PH_Elem_M3D9R_FormIntForce` | 394 | `SUBROUTINE PH_Elem_M3D9R_FormIntForce(coords, u, E_young, nu, R_int, thickness)` |
| SUBROUTINE | `PH_Elem_M3D9R_LumpMass` | 413 | `SUBROUTINE PH_Elem_M3D9R_LumpMass(coords, rho, M_lumped, thickness)` |
| SUBROUTINE | `PH_Elem_M3D9R_NL_TL` | 434 | `SUBROUTINE PH_Elem_M3D9R_NL_TL(coords_ref, u_elem, D, thickness, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_M3D9R_NL_UL` | 587 | `SUBROUTINE PH_Elem_M3D9R_NL_UL(coords_prev, u_incr, D, thickness, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `UF_Elem_M3D9R_Calc` | 731 | `SUBROUTINE UF_Elem_M3D9R_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PH_Elem_M3D9R_GetArea` | 859 | `SUBROUTINE PH_Elem_M3D9R_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_M3D9R_GetCentroid` | 877 | `SUBROUTINE PH_Elem_M3D9R_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_M3D9R_GetSectProps` | 888 | `SUBROUTINE PH_Elem_M3D9R_GetSectProps(coords, density_in, area, mass, thickness)` |
| SUBROUTINE | `PH_Elem_M3D9R_ApplyConstraint` | 905 | `SUBROUTINE PH_Elem_M3D9R_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_M3D9R_ApplyMPC` | 915 | `SUBROUTINE PH_Elem_M3D9R_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_M3D9R_FormContactContrib` | 931 | `SUBROUTINE PH_Elem_M3D9R_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_M3D9R_FormContactEdgeCtr` | 940 | `SUBROUTINE PH_Elem_M3D9R_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_M3D9R_FormBodyForce` | 952 | `SUBROUTINE PH_Elem_M3D9R_FormBodyForce(coords, bx, by, bz, F_eq, thickness)` |
| SUBROUTINE | `PH_Elem_M3D9R_FormNodalForce` | 982 | `SUBROUTINE PH_Elem_M3D9R_FormNodalForce(load_type, coords, val, edge_id, F_eq, thickness)` |
| SUBROUTINE | `PH_Elem_M3D9R_CollectIPVars` | 998 | `SUBROUTINE PH_Elem_M3D9R_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_M3D9R_EvalVonMises` | 1005 | `SUBROUTINE PH_Elem_M3D9R_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_M3D9R_EvalMembraneStress` | 1017 | `SUBROUTINE PH_Elem_M3D9R_EvalMembraneStress(sigma, seq)` |
| SUBROUTINE | `PH_Elem_M3D9R_GetExtrapMat` | 1023 | `SUBROUTINE PH_Elem_M3D9R_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_M3D9R_MapToNode` | 1032 | `SUBROUTINE PH_Elem_M3D9R_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_M3D9R_Material_Update_Routed` | 1038 | `SUBROUTINE PH_Elem_M3D9R_Material_Update_Routed(rt_ctx, mat_slot, dstrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
