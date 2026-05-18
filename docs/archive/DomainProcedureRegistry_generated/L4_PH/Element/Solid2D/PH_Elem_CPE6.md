# `PH_Elem_CPE6.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_CPE6.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_CPE6`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CPE6`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CPE6`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_CPE6.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_CPE6_ShapeFunc_Arg` (lines 41–43)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_ShapeFunc_Arg
```

### `PH_Elem_CPE6_Jac_Arg` (lines 47–50)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_Jac_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_Jac_Arg
```

### `PH_Elem_CPE6_BMatrix_Arg` (lines 54–56)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_BMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_BMatrix_Arg
```

### `PH_Elem_CPE6_JacB_Arg` (lines 60–63)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_JacB_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_JacB_Arg
```

### `PH_Elem_CPE6_Strain_Arg` (lines 67–69)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_Strain_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_Strain_Arg
```

### `PH_Elem_CPE6_Stress_Arg` (lines 73–75)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_Stress_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_Stress_Arg
```

### `PH_Elem_CPE6_StiffMatrix_Arg` (lines 79–81)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_StiffMatrix_Arg
```

### `PH_Elem_CPE6_NL_TL_Arg` (lines 85–88)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_NL_TL_Arg
```

### `PH_Elem_CPE6_NL_UL_Arg` (lines 92–95)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE6_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE6_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CPE6_ShapeFunc_Legacy` | 198 | `SUBROUTINE PH_Elem_CPE6_ShapeFunc_Legacy(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPE6_Jac_Legacy` | 211 | `SUBROUTINE PH_Elem_CPE6_Jac_Legacy(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPE6_JacB_Legacy` | 225 | `SUBROUTINE PH_Elem_CPE6_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_CPE6_Strain_Legacy` | 246 | `SUBROUTINE PH_Elem_CPE6_Strain_Legacy(B, u, strain)` |
| SUBROUTINE | `PH_Elem_CPE6_Stress_Legacy` | 258 | `SUBROUTINE PH_Elem_CPE6_Stress_Legacy(epsilon, D, sigma)` |
| SUBROUTINE | `PH_ELEM_CPE6_AreaInt` | 273 | `SUBROUTINE PH_ELEM_CPE6_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE6_ThermStrainVector` | 288 | `SUBROUTINE PH_Elem_CPE6_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_CPE6_BMatrix_Legacy` | 298 | `SUBROUTINE PH_Elem_CPE6_BMatrix_Legacy(dNdx, B)` |
| SUBROUTINE | `PH_Elem_CPE6_BMatrix_InOut` | 308 | `SUBROUTINE PH_Elem_CPE6_BMatrix_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_ConsMass` | 322 | `SUBROUTINE PH_Elem_CPE6_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CPE6_ConstMatrix` | 346 | `SUBROUTINE PH_Elem_CPE6_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_CPE6_DefInit` | 359 | `SUBROUTINE PH_Elem_CPE6_DefInit()` |
| SUBROUTINE | `PH_Elem_CPE6_FormIntForce` | 362 | `SUBROUTINE PH_Elem_CPE6_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_CPE6_FormIntForceFromStress` | 382 | `SUBROUTINE PH_Elem_CPE6_FormIntForceFromStress(coords, sigma3, R_int)` |
| SUBROUTINE | `PH_Elem_CPE6_FormStiffMatrix_Legacy` | 398 | `SUBROUTINE PH_Elem_CPE6_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_CPE6_FormStiffMatrix_InOut` | 411 | `SUBROUTINE PH_Elem_CPE6_FormStiffMatrix_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_GaussPoints` | 433 | `SUBROUTINE PH_Elem_CPE6_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CPE6_Jac_InOut` | 449 | `SUBROUTINE PH_Elem_CPE6_Jac_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_JacB_InOut` | 464 | `SUBROUTINE PH_Elem_CPE6_JacB_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_LumpMass` | 515 | `SUBROUTINE PH_Elem_CPE6_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CPE6_ShapeFunc_InOut` | 529 | `SUBROUTINE PH_Elem_CPE6_ShapeFunc_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_Strain_InOut` | 563 | `SUBROUTINE PH_Elem_CPE6_Strain_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_Stress_InOut` | 571 | `SUBROUTINE PH_Elem_CPE6_Stress_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_NL_TL_Legacy` | 587 | `SUBROUTINE PH_Elem_CPE6_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPE6_NL_UL_Legacy` | 681 | `SUBROUTINE PH_Elem_CPE6_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPE6_NL_TL_Structured` | 784 | `SUBROUTINE PH_Elem_CPE6_NL_TL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_NL_UL_Structured` | 801 | `SUBROUTINE PH_Elem_CPE6_NL_UL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CPE6_GetArea` | 821 | `SUBROUTINE PH_Elem_CPE6_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE6_GetCentroid` | 827 | `SUBROUTINE PH_Elem_CPE6_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CPE6_GetSectProps` | 854 | `SUBROUTINE PH_Elem_CPE6_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_CPE6_ApplyConstraint` | 866 | `SUBROUTINE PH_Elem_CPE6_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE6_ApplyMPC` | 879 | `SUBROUTINE PH_Elem_CPE6_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE6_FormContactContrib` | 897 | `SUBROUTINE PH_Elem_CPE6_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE6_FormContactEdgeCtr` | 929 | `SUBROUTINE PH_Elem_CPE6_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE6_FormEdgePressure` | 968 | `SUBROUTINE PH_Elem_CPE6_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE6_FormBodyForce` | 998 | `SUBROUTINE PH_Elem_CPE6_FormBodyForce(coords, bx, by, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE6_FormNodalForce` | 1018 | `SUBROUTINE PH_Elem_CPE6_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `invert_3x3` | 1035 | `SUBROUTINE invert_3x3(A, info)` |
| SUBROUTINE | `PH_Elem_CPE6_CollectIPVars` | 1064 | `SUBROUTINE PH_Elem_CPE6_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CPE6_EvalPrincStress` | 1086 | `SUBROUTINE PH_Elem_CPE6_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CPE6_EvalStressInvar` | 1099 | `SUBROUTINE PH_Elem_CPE6_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CPE6_EvalVonMises` | 1110 | `SUBROUTINE PH_Elem_CPE6_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CPE6_GetExtrapMat` | 1120 | `SUBROUTINE PH_Elem_CPE6_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CPE6_MapToNode` | 1150 | `SUBROUTINE PH_Elem_CPE6_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_CPE6_Material_Update_Routed` | 1168 | `SUBROUTINE PH_Elem_CPE6_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 148–151 | `INTERFACE PH_Elem_CPE6_FormStiffMatrix` |
| 153–156 | `INTERFACE PH_Elem_CPE6_BMatrix` |
| 158–161 | `INTERFACE PH_Elem_CPE6_ShapeFunc` |
| 163–166 | `INTERFACE PH_Elem_CPE6_Jac` |
| 168–171 | `INTERFACE PH_Elem_CPE6_JacB` |
| 173–176 | `INTERFACE PH_Elem_CPE6_Strain` |
| 178–181 | `INTERFACE PH_Elem_CPE6_Stress` |
| 183–186 | `INTERFACE PH_Elem_CPE6_NL_TL` |
| 188–191 | `INTERFACE PH_Elem_CPE6_NL_UL` |
