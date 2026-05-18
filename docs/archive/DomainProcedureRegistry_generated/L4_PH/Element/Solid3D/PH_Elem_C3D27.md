# `PH_Elem_C3D27.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_C3D27.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_C3D27`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D27`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D27`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_C3D27.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Sld3D_Args` (lines 116–152)

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
| SUBROUTINE | `PH_ELEM_C3D27_BEnhanced` | 157 | `SUBROUTINE PH_ELEM_C3D27_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)` |
| SUBROUTINE | `PH_ELEM_C3D27_IncompatibleShapeFunc` | 179 | `SUBROUTINE PH_ELEM_C3D27_IncompatibleShapeFunc(xi, eta, zeta, N_enh, dN_xi, dN_eta, dN_zeta)` |
| SUBROUTINE | `PH_ELEM_C3D27_Inv3x3` | 200 | `SUBROUTINE PH_ELEM_C3D27_Inv3x3(A, Ainv, detA)` |
| SUBROUTINE | `PH_ELEM_C3D27_Volume_8pt` | 230 | `SUBROUTINE PH_ELEM_C3D27_Volume_8pt(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D27_FormIntForceByVariant` | 245 | `SUBROUTINE PH_Elem_C3D27_FormIntForceByVariant(coords, u, E_young, nu, variant, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_FormStiffMatrix` | 255 | `SUBROUTINE PH_Elem_C3D27_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_FormStiffMatrixFromD` | 263 | `SUBROUTINE PH_Elem_C3D27_FormStiffMatrixFromD(coords, D6, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_FormStiffMatrixByVariant` | 270 | `SUBROUTINE PH_Elem_C3D27_FormStiffMatrixByVariant(coords, E_young, nu, variant, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_IntForceByVariant` | 279 | `SUBROUTINE PH_Elem_C3D27_IntForceByVariant(coords, u, E_young, nu, variant, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_IntForceIncompatible` | 299 | `SUBROUTINE PH_Elem_C3D27_IntForceIncompatible(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_IntForceReduced` | 310 | `SUBROUTINE PH_Elem_C3D27_IntForceReduced(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_IntForceSelective` | 350 | `SUBROUTINE PH_Elem_C3D27_IntForceSelective(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_LumpMassReduced` | 394 | `SUBROUTINE PH_Elem_C3D27_LumpMassReduced(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D27_StiffMatrixByVariant` | 412 | `SUBROUTINE PH_Elem_C3D27_StiffMatrixByVariant(coords, E_young, nu, variant, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_StiffMatrixIncompatible` | 431 | `SUBROUTINE PH_Elem_C3D27_StiffMatrixIncompatible(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_StiffMatrixReduced` | 478 | `SUBROUTINE PH_Elem_C3D27_StiffMatrixReduced(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_StiffMatrixSelective` | 512 | `SUBROUTINE PH_Elem_C3D27_StiffMatrixSelective(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_ThermStrainVector` | 554 | `SUBROUTINE PH_Elem_C3D27_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_C3D27_BMatrix` | 562 | `SUBROUTINE PH_Elem_C3D27_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_C3D27_ConsMass` | 583 | `SUBROUTINE PH_Elem_C3D27_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_C3D27_ConstMatrix` | 611 | `SUBROUTINE PH_Elem_C3D27_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_C3D27_DefInit` | 635 | `SUBROUTINE PH_Elem_C3D27_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D27_FormGeomStiff` | 639 | `SUBROUTINE PH_Elem_C3D27_FormGeomStiff(coords, sigma, Kg)` |
| SUBROUTINE | `PH_Elem_C3D27_FormIntForce` | 685 | `SUBROUTINE PH_Elem_C3D27_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_FormIntForceFromStress` | 695 | `SUBROUTINE PH_Elem_C3D27_FormIntForceFromStress(coords, sigma6, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_GaussPoints` | 715 | `SUBROUTINE PH_Elem_C3D27_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D27_GaussPoints27` | 732 | `SUBROUTINE PH_Elem_C3D27_GaussPoints27(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D27_IntForce` | 749 | `SUBROUTINE PH_Elem_C3D27_IntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_IntForce27` | 774 | `SUBROUTINE PH_Elem_C3D27_IntForce27(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D27_Jac` | 797 | `SUBROUTINE PH_Elem_C3D27_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_C3D27_JacB` | 818 | `SUBROUTINE PH_Elem_C3D27_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_C3D27_LumpMass` | 860 | `SUBROUTINE PH_Elem_C3D27_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D27_LumpMass27` | 885 | `SUBROUTINE PH_Elem_C3D27_LumpMass27(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D27_NL_TL` | 908 | `SUBROUTINE PH_Elem_C3D27_NL_TL(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 1018 | `SUBROUTINE Invert3x3(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_C3D27_NL_UL` | 1033 | `SUBROUTINE PH_Elem_C3D27_NL_UL(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 1167 | `SUBROUTINE Invert3x3(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_C3D27_ShapeFunc` | 1182 | `SUBROUTINE PH_Elem_C3D27_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_C3D27_StiffMatrix` | 1224 | `SUBROUTINE PH_Elem_C3D27_StiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_StiffMatrixFromD` | 1249 | `SUBROUTINE PH_Elem_C3D27_StiffMatrixFromD(coords, D6, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_StiffMatrix27` | 1270 | `SUBROUTINE PH_Elem_C3D27_StiffMatrix27(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D27_Strain` | 1291 | `SUBROUTINE PH_Elem_C3D27_Strain(B, u, strain)` |
| SUBROUTINE | `PH_Elem_C3D27_Stress` | 1304 | `SUBROUTINE PH_Elem_C3D27_Stress(epsilon, D, sigma)` |
| SUBROUTINE | `PH_Elem_C3D27_Volume27` | 1318 | `SUBROUTINE PH_Elem_C3D27_Volume27(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D27_GetCentroid` | 1334 | `SUBROUTINE PH_Elem_C3D27_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D27_GetInertiaOrig` | 1362 | `SUBROUTINE PH_Elem_C3D27_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_C3D27_GetSectProps` | 1394 | `SUBROUTINE PH_Elem_C3D27_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D27_GetVolume` | 1403 | `SUBROUTINE PH_Elem_C3D27_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D27_ApplyConstraint` | 1419 | `SUBROUTINE PH_Elem_C3D27_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D27_ApplyMPC` | 1432 | `SUBROUTINE PH_Elem_C3D27_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D27_FormContactContrib` | 1448 | `SUBROUTINE PH_Elem_C3D27_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D27_FormContactFaceCtr` | 1486 | `SUBROUTINE PH_Elem_C3D27_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D27_FormFacePressure` | 1623 | `SUBROUTINE PH_Elem_C3D27_FormFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D27_FormBodyForce` | 1803 | `SUBROUTINE PH_Elem_C3D27_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D27_FormNodalForce` | 1824 | `SUBROUTINE PH_Elem_C3D27_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `invert_27x27` | 1839 | `SUBROUTINE invert_27x27(A, info)` |
| SUBROUTINE | `PH_Elem_C3D27_EvalPrincStress` | 1868 | `SUBROUTINE PH_Elem_C3D27_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_C3D27_EvalStrainInvar` | 1922 | `SUBROUTINE PH_Elem_C3D27_EvalStrainInvar(strain, I1e, J2e)` |
| SUBROUTINE | `PH_Elem_C3D27_EvalStressInvar` | 1934 | `SUBROUTINE PH_Elem_C3D27_EvalStressInvar(sigma, I1, J2, J3)` |
| SUBROUTINE | `PH_Elem_C3D27_EvalTriaxiality` | 1958 | `SUBROUTINE PH_Elem_C3D27_EvalTriaxiality(sigma, triax)` |
| SUBROUTINE | `PH_Elem_C3D27_CollectIPVars` | 1972 | `SUBROUTINE PH_Elem_C3D27_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_C3D27_EvalVonMises` | 1994 | `SUBROUTINE PH_Elem_C3D27_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_C3D27_GetExtrapMat` | 2007 | `SUBROUTINE PH_Elem_C3D27_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_C3D27_MapToNode` | 2028 | `SUBROUTINE PH_Elem_C3D27_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_C3D27_Material_Update_Routed` | 2047 | `SUBROUTINE PH_Elem_C3D27_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
