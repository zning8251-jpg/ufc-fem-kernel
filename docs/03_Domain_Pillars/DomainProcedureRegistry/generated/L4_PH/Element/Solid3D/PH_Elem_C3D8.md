# `PH_Elem_C3D8.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_C3D8.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_C3D8`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D8`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D8`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_C3D8.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_C3D8_ShapeFunc_Arg` (lines 141–143)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_ShapeFunc_Arg
```

### `PH_Elem_C3D8_Jac_Arg` (lines 149–152)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_Jac_Arg
    REAL(wp) :: detJ  ! Jacobian determinant |J| (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_Jac_Arg
```

### `PH_Elem_C3D8_BMatrix_Arg` (lines 158–160)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_BMatrix_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_BMatrix_Arg
```

### `PH_Elem_C3D8_JacB_Arg` (lines 166–169)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_JacB_Arg
    REAL(wp) :: detJ  ! Jacobian determinant (State)                   ! [OUT]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_JacB_Arg
```

### `PH_Elem_C3D8_Strain_Arg` (lines 175–177)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_Strain_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_Strain_Arg
```

### `PH_Elem_C3D8_Stress_Arg` (lines 183–185)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_Stress_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_Stress_Arg
```

### `PH_Elem_C3D8_StiffMatrix_Arg` (lines 191–193)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_StiffMatrix_Arg
```

### `PH_Elem_C3D8_NL_TL_Arg` (lines 199–203)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    INTEGER(i4), OPTIONAL :: variant  ! Element variant (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_NL_TL_Arg
```

### `PH_Elem_C3D8_NL_UL_Arg` (lines 209–213)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D8_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    INTEGER(i4), OPTIONAL :: variant  ! Element variant (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_C3D8_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ELEM_C3D8_BEnhanced` | 218 | `SUBROUTINE PH_ELEM_C3D8_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)` |
| SUBROUTINE | `PH_ELEM_C3D8_IncompatibleShapeFunc` | 240 | `SUBROUTINE PH_ELEM_C3D8_IncompatibleShapeFunc(xi, eta, zeta, N_enh, dN_xi, dN_eta, dN_zeta)` |
| SUBROUTINE | `PH_ELEM_C3D8_Inv3x3` | 261 | `SUBROUTINE PH_ELEM_C3D8_Inv3x3(A, Ainv, detA)` |
| SUBROUTINE | `PH_ELEM_C3D8_Volume_8pt` | 291 | `SUBROUTINE PH_ELEM_C3D8_Volume_8pt(coords, volume)` |
| SUBROUTINE | `PH_El_C3_FormIntForceByVaria` | 306 | `SUBROUTINE PH_El_C3_FormIntForceByVaria(coords, u, E_young, nu, variant, R_int)` |
| SUBROUTINE | `PH_El_C3_FormStiffMatrixByVa` | 316 | `SUBROUTINE PH_El_C3_FormStiffMatrixByVa(coords, E_young, nu, variant, Ke)` |
| SUBROUTINE | `PH_El_C3_IntForceByVariant` | 325 | `SUBROUTINE PH_El_C3_IntForceByVariant(coords, u, E_young, nu, variant, R_int)` |
| SUBROUTINE | `PH_El_C3_IntForceIncompatibl` | 345 | `SUBROUTINE PH_El_C3_IntForceIncompatibl(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_El_C3_IntForceSelective` | 356 | `SUBROUTINE PH_El_C3_IntForceSelective(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_El_C3_StiffMatrixByVarian` | 400 | `SUBROUTINE PH_El_C3_StiffMatrixByVarian(coords, E_young, nu, variant, Ke)` |
| SUBROUTINE | `PH_El_C3_StiffMatrixIncompat` | 419 | `SUBROUTINE PH_El_C3_StiffMatrixIncompat(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_El_C3_StiffMatrixReduced` | 466 | `SUBROUTINE PH_El_C3_StiffMatrixReduced(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_El_C3_StiffMatrixSelectiv` | 500 | `SUBROUTINE PH_El_C3_StiffMatrixSelectiv(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_El_C3_ThermStrainVector` | 542 | `SUBROUTINE PH_El_C3_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_C3D8_BMatrix` | 550 | `SUBROUTINE PH_Elem_C3D8_BMatrix(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_ConsMass` | 575 | `SUBROUTINE PH_Elem_C3D8_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_C3D8_ConstMatrix` | 603 | `SUBROUTINE PH_Elem_C3D8_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_C3D8_DefInit` | 627 | `SUBROUTINE PH_Elem_C3D8_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D8_FormGeomStiff` | 631 | `SUBROUTINE PH_Elem_C3D8_FormGeomStiff(coords, sigma, Kg)` |
| SUBROUTINE | `PH_Elem_C3D8_FormIntForce` | 677 | `SUBROUTINE PH_Elem_C3D8_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D8_FormStiffMatrix` | 686 | `SUBROUTINE PH_Elem_C3D8_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D8_GaussPoints` | 694 | `SUBROUTINE PH_Elem_C3D8_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D8_GaussPoints27` | 717 | `SUBROUTINE PH_Elem_C3D8_GaussPoints27(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D8_IntForce` | 734 | `SUBROUTINE PH_Elem_C3D8_IntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D8_FormIntForceFromStress` | 759 | `SUBROUTINE PH_Elem_C3D8_FormIntForceFromStress(coords, sigma6, R_int)` |
| SUBROUTINE | `PH_Elem_C3D8_IntForce27` | 777 | `SUBROUTINE PH_Elem_C3D8_IntForce27(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D8_IntForceReduced` | 800 | `SUBROUTINE PH_Elem_C3D8_IntForceReduced(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D8_Jac` | 840 | `SUBROUTINE PH_Elem_C3D8_Jac(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_JacB` | 864 | `SUBROUTINE PH_Elem_C3D8_JacB(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_LumpMass` | 942 | `SUBROUTINE PH_Elem_C3D8_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D8_LumpMass27` | 967 | `SUBROUTINE PH_Elem_C3D8_LumpMass27(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D8_LumpMassReduced` | 990 | `SUBROUTINE PH_Elem_C3D8_LumpMassReduced(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D8_NL_TL` | 1008 | `SUBROUTINE PH_Elem_C3D8_NL_TL(arg)` |
| SUBROUTINE | `PH_ELEM_C3D8_NL_TL_Reduced` | 1216 | `SUBROUTINE PH_ELEM_C3D8_NL_TL_Reduced(coords_ref, coords_curr, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 1316 | `SUBROUTINE Invert3x3(A, A_inv, det_A, stat)` |
| SUBROUTINE | `PH_Elem_C3D8_ShapeFuncDeriv` | 1347 | `SUBROUTINE PH_Elem_C3D8_ShapeFuncDeriv(xi, eta, zeta, dN_dxi)` |
| SUBROUTINE | `PH_Elem_C3D8_NL_TL_Legacy` | 1367 | `SUBROUTINE PH_Elem_C3D8_NL_TL_Legacy(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status, variant)` |
| SUBROUTINE | `PH_Elem_C3D8_NL_UL` | 1398 | `SUBROUTINE PH_Elem_C3D8_NL_UL(arg)` |
| SUBROUTINE | `PH_ELEM_C3D8_NL_UL_Reduced` | 1607 | `SUBROUTINE PH_ELEM_C3D8_NL_UL_Reduced(coords_prev, coords_curr, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `Invert3x3` | 1707 | `SUBROUTINE Invert3x3(A, A_inv, det_A, stat)` |
| SUBROUTINE | `PH_Elem_C3D8_ShapeFuncDeriv` | 1738 | `SUBROUTINE PH_Elem_C3D8_ShapeFuncDeriv(xi, eta, zeta, dN_dxi)` |
| SUBROUTINE | `PH_Elem_C3D8_NL_UL_Legacy` | 1757 | `SUBROUTINE PH_Elem_C3D8_NL_UL_Legacy(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status, variant)` |
| SUBROUTINE | `PH_Elem_C3D8_NL_TL_FromD` | 1793 | `SUBROUTINE PH_Elem_C3D8_NL_TL_FromD(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status, variant)` |
| SUBROUTINE | `PH_Elem_C3D8_NL_UL_FromD` | 1846 | `SUBROUTINE PH_Elem_C3D8_NL_UL_FromD(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status, variant)` |
| SUBROUTINE | `PH_Elem_C3D8_ShapeFunc` | 1899 | `SUBROUTINE PH_Elem_C3D8_ShapeFunc(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_StiffMatrix` | 1923 | `SUBROUTINE PH_Elem_C3D8_StiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_StiffMatrix27` | 1953 | `SUBROUTINE PH_Elem_C3D8_StiffMatrix27(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D8_Strain` | 1974 | `SUBROUTINE PH_Elem_C3D8_Strain(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_Stress` | 1992 | `SUBROUTINE PH_Elem_C3D8_Stress(arg)` |
| SUBROUTINE | `PH_Elem_C3D8_Volume27` | 2010 | `SUBROUTINE PH_Elem_C3D8_Volume27(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D8_GetCentroid` | 2028 | `SUBROUTINE PH_Elem_C3D8_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D8_GetInertiaOrig` | 2058 | `SUBROUTINE PH_Elem_C3D8_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_C3D8_GetVolume` | 2092 | `SUBROUTINE PH_Elem_C3D8_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D8_GetSectProps` | 2109 | `SUBROUTINE PH_Elem_C3D8_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D8_ApplyConstraint` | 2122 | `SUBROUTINE PH_Elem_C3D8_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D8_ApplyMPC` | 2136 | `SUBROUTINE PH_Elem_C3D8_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D8_FormContactContrib` | 2155 | `SUBROUTINE PH_Elem_C3D8_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D8_FormContactFaceCtr` | 2196 | `SUBROUTINE PH_Elem_C3D8_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D8_FormFacePressure` | 2337 | `SUBROUTINE PH_Elem_C3D8_FormFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8_FormBodyForce` | 2520 | `SUBROUTINE PH_Elem_C3D8_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8_FormGravity` | 2541 | `SUBROUTINE PH_Elem_C3D8_FormGravity(coords, rho, g_dir, g_mag, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8_FormNodalForce` | 2554 | `SUBROUTINE PH_Elem_C3D8_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `invert_8x8` | 2579 | `SUBROUTINE invert_8x8(A, info)` |
| SUBROUTINE | `PH_Elem_C3D8_CollectIPVars` | 2610 | `SUBROUTINE PH_Elem_C3D8_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_C3D8_EvalPrincStress` | 2636 | `SUBROUTINE PH_Elem_C3D8_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_C3D8_EvalStrainInvar` | 2692 | `SUBROUTINE PH_Elem_C3D8_EvalStrainInvar(strain, I1e, J2e)` |
| SUBROUTINE | `PH_Elem_C3D8_EvalStressInvar` | 2705 | `SUBROUTINE PH_Elem_C3D8_EvalStressInvar(sigma, I1, J2, J3)` |
| SUBROUTINE | `PH_Elem_C3D8_EvalTriaxiality` | 2730 | `SUBROUTINE PH_Elem_C3D8_EvalTriaxiality(sigma, triax)` |
| SUBROUTINE | `PH_Elem_C3D8_EvalVonMises` | 2745 | `SUBROUTINE PH_Elem_C3D8_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_C3D8_GetExtrapMat` | 2759 | `SUBROUTINE PH_Elem_C3D8_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_C3D8_MapToNode` | 2782 | `SUBROUTINE PH_Elem_C3D8_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_C3D8_NL_TL_Structured` | 2803 | `SUBROUTINE PH_Elem_C3D8_NL_TL_Structured(elem_cfg, elem_state, elem_ctx, mat_cfg, status)` |
| SUBROUTINE | `PH_Elem_C3D8_Material_Update_Routed` | 2980 | `SUBROUTINE PH_Elem_C3D8_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
