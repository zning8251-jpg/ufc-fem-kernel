# `PH_Elem_C3D8P.f90`

- **Source**: `L4_PH/Element/Porous/PH_Elem_C3D8P.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_C3D8P`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D8P`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D8P`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Porous`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Porous/PH_Elem_C3D8P.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Porous_Args` (lines 73–117)

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
| SUBROUTINE | `PH_Elem_C3D8P_FormStiffMatrix_MatAware` | 125 | `SUBROUTINE PH_Elem_C3D8P_FormStiffMatrix_MatAware(coords, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_C3D8P_FormIntForce_MatAware` | 183 | `SUBROUTINE PH_Elem_C3D8P_FormIntForce_MatAware(coords, u_struct, p_pore, mat_prop, &` |
| SUBROUTINE | `PH_Elem_C3D8P_FormStiffMatrix` | 222 | `SUBROUTINE PH_Elem_C3D8P_FormStiffMatrix(coords, D_struct, k_hyd, alpha_b, Ke)` |
| SUBROUTINE | `PH_Elem_C3D8P_BMatrix` | 246 | `SUBROUTINE PH_Elem_C3D8P_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_C3D8P_BpMatrix` | 252 | `SUBROUTINE PH_Elem_C3D8P_BpMatrix(dNdx, Bp)` |
| SUBROUTINE | `PH_Elem_C3D8P_DefInit` | 263 | `SUBROUTINE PH_Elem_C3D8P_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D8P_FormIntForce` | 266 | `SUBROUTINE PH_Elem_C3D8P_FormIntForce(coords, u_struct, p_pore, D_struct, &` |
| SUBROUTINE | `PH_Elem_C3D8P_GaussPoints` | 292 | `SUBROUTINE PH_Elem_C3D8P_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D8P_Jac` | 297 | `SUBROUTINE PH_Elem_C3D8P_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_C3D8P_JacB` | 305 | `SUBROUTINE PH_Elem_C3D8P_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B, Bp)` |
| SUBROUTINE | `PH_Elem_C3D8P_ShapeFunc` | 313 | `SUBROUTINE PH_Elem_C3D8P_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_C3D8P_NL_TL` | 321 | `SUBROUTINE PH_Elem_C3D8P_NL_TL(coords_ref, u_elem, D, k_hyd, alpha_b, &` |
| SUBROUTINE | `PH_Elem_C3D8P_NL_UL` | 353 | `SUBROUTINE PH_Elem_C3D8P_NL_UL(coords_prev, u_incr, D, k_hyd, alpha_b, &` |
| SUBROUTINE | `PH_Elem_C3D8P_GetCentroid` | 388 | `SUBROUTINE PH_Elem_C3D8P_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D8P_GetInertiaOrig` | 412 | `SUBROUTINE PH_Elem_C3D8P_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_C3D8P_GetSectProps` | 440 | `SUBROUTINE PH_Elem_C3D8P_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D8P_GetVolume` | 448 | `SUBROUTINE PH_Elem_C3D8P_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D8P_ApplyConstraint` | 466 | `SUBROUTINE PH_Elem_C3D8P_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D8P_ApplyMPC` | 479 | `SUBROUTINE PH_Elem_C3D8P_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D8P_FormContactContrib` | 497 | `SUBROUTINE PH_Elem_C3D8P_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D8P_FormContactFaceCtr` | 535 | `SUBROUTINE PH_Elem_C3D8P_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D8P_FormFacePressure` | 589 | `SUBROUTINE PH_Elem_C3D8P_FormFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8P_FormBodyForce` | 652 | `SUBROUTINE PH_Elem_C3D8P_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8P_FormNodalForce` | 673 | `SUBROUTINE PH_Elem_C3D8P_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8P_FormPoreSource` | 689 | `SUBROUTINE PH_Elem_C3D8P_FormPoreSource(coords, q_source, F_eq)` |
| SUBROUTINE | `invert_8x8` | 711 | `SUBROUTINE invert_8x8(A, info)` |
| SUBROUTINE | `PH_Elem_C3D8P_EvalPrincStress` | 740 | `SUBROUTINE PH_Elem_C3D8P_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_C3D8P_EvalStressInvar` | 769 | `SUBROUTINE PH_Elem_C3D8P_EvalStressInvar(sigma, I1, J2, J3)` |
| SUBROUTINE | `PH_Elem_C3D8P_CollectIPVars` | 784 | `SUBROUTINE PH_Elem_C3D8P_CollectIPVars(ip_stress, ip_strain, ip_pore, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_C3D8P_EvalVonMises` | 801 | `SUBROUTINE PH_Elem_C3D8P_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_C3D8P_GetExtrapMat` | 811 | `SUBROUTINE PH_Elem_C3D8P_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_C3D8P_MapToNode` | 830 | `SUBROUTINE PH_Elem_C3D8P_MapToNode(ip_vars, weights, node_vars)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
