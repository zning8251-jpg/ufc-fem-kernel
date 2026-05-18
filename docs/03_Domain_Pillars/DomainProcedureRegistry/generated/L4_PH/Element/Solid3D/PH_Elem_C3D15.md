# `PH_Elem_C3D15.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_C3D15.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_C3D15`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D15`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D15`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_C3D15.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Sld3D_Args` (lines 69–105)

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
| SUBROUTINE | `PH_Elem_C3D15_FormStiffMatrix` | 111 | `SUBROUTINE PH_Elem_C3D15_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D15_FormStiffMatrixFromD` | 128 | `SUBROUTINE PH_Elem_C3D15_FormStiffMatrixFromD(coords, D6, Ke)` |
| SUBROUTINE | `PH_Elem_C3D15_ThermStrainVector` | 144 | `SUBROUTINE PH_Elem_C3D15_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_C3D15_BMatrix` | 151 | `SUBROUTINE PH_Elem_C3D15_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_C3D15_ConsMass` | 170 | `SUBROUTINE PH_Elem_C3D15_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_C3D15_ConstMatrix` | 196 | `SUBROUTINE PH_Elem_C3D15_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_C3D15_DefInit` | 217 | `SUBROUTINE PH_Elem_C3D15_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D15_FormIntForce` | 220 | `SUBROUTINE PH_Elem_C3D15_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D15_FormIntForceFromStress` | 230 | `SUBROUTINE PH_Elem_C3D15_FormIntForceFromStress(coords, sigma6, R_int)` |
| SUBROUTINE | `PH_Elem_C3D15_GaussPoints` | 248 | `SUBROUTINE PH_Elem_C3D15_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D15_GetVolumeInt` | 291 | `SUBROUTINE PH_Elem_C3D15_GetVolumeInt(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D15_Jac` | 306 | `SUBROUTINE PH_Elem_C3D15_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_C3D15_JacB` | 323 | `SUBROUTINE PH_Elem_C3D15_JacB(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_C3D15_LumpMass` | 357 | `SUBROUTINE PH_Elem_C3D15_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D15_NL_TL` | 372 | `SUBROUTINE PH_Elem_C3D15_NL_TL(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 439 | `SUBROUTINE Invert3x3(A, A_inv, det_val)` |
| SUBROUTINE | `PH_Elem_C3D15_NL_UL` | 456 | `SUBROUTINE PH_Elem_C3D15_NL_UL(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 523 | `SUBROUTINE Invert3x3(A, A_inv, det_val)` |
| SUBROUTINE | `PH_Elem_C3D15_ShapeFunc` | 540 | `SUBROUTINE PH_Elem_C3D15_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_C3D15_Strain` | 619 | `SUBROUTINE PH_Elem_C3D15_Strain(B, u, strain)` |
| SUBROUTINE | `PH_Elem_C3D15_Stress` | 626 | `SUBROUTINE PH_Elem_C3D15_Stress(epsilon, D, sigma)` |
| SUBROUTINE | `PH_Elem_C3D15_GetCentroid` | 634 | `SUBROUTINE PH_Elem_C3D15_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D15_GetInertiaOrig` | 658 | `SUBROUTINE PH_Elem_C3D15_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_C3D15_GetSectProps` | 688 | `SUBROUTINE PH_Elem_C3D15_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D15_GetVolume` | 697 | `SUBROUTINE PH_Elem_C3D15_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D15_ApplyConstraint` | 713 | `SUBROUTINE PH_Elem_C3D15_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D15_ApplyMPC` | 726 | `SUBROUTINE PH_Elem_C3D15_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D15_FormContactContrib` | 742 | `SUBROUTINE PH_Elem_C3D15_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D15_FormContactFaceCtr` | 771 | `SUBROUTINE PH_Elem_C3D15_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D15_FormFacePressure` | 805 | `SUBROUTINE PH_Elem_C3D15_FormFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D15_FormBodyForce` | 843 | `SUBROUTINE PH_Elem_C3D15_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D15_FormNodalForce` | 864 | `SUBROUTINE PH_Elem_C3D15_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D15_EvalPrincStress` | 879 | `SUBROUTINE PH_Elem_C3D15_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_C3D15_EvalStrainInvar` | 925 | `SUBROUTINE PH_Elem_C3D15_EvalStrainInvar(strain, I1e, J2e)` |
| SUBROUTINE | `PH_Elem_C3D15_EvalStressInvar` | 936 | `SUBROUTINE PH_Elem_C3D15_EvalStressInvar(sigma, I1, J2, J3)` |
| SUBROUTINE | `PH_Elem_C3D15_EvalTriaxiality` | 957 | `SUBROUTINE PH_Elem_C3D15_EvalTriaxiality(sigma, triax)` |
| SUBROUTINE | `PH_Elem_C3D15_CollectIPVars` | 967 | `SUBROUTINE PH_Elem_C3D15_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_C3D15_EvalVonMises` | 981 | `SUBROUTINE PH_Elem_C3D15_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_C3D15_GetExtrapMat` | 993 | `SUBROUTINE PH_Elem_C3D15_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_C3D15_MapToNode` | 1002 | `SUBROUTINE PH_Elem_C3D15_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_C3D15_Material_Update_Routed` | 1015 | `SUBROUTINE PH_Elem_C3D15_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
