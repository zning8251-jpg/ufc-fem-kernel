# `PH_Elem_CPE8.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_CPE8.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_CPE8`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CPE8`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CPE8`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_CPE8.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_CPE8_ShapeFunc_Arg` (lines 41–43)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_ShapeFunc_Arg
```

### `PH_Elem_CPE8_Jac_Arg` (lines 47–50)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_Jac_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_Jac_Arg
```

### `PH_Elem_CPE8_BMatrix_Arg` (lines 54–56)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_BMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_BMatrix_Arg
```

### `PH_Elem_CPE8_JacB_Arg` (lines 60–63)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_JacB_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_JacB_Arg
```

### `PH_Elem_CPE8_Strain_Arg` (lines 67–69)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_Strain_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_Strain_Arg
```

### `PH_Elem_CPE8_Stress_Arg` (lines 73–75)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_Stress_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_Stress_Arg
```

### `PH_Elem_CPE8_StiffMatrix_Arg` (lines 79–81)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_StiffMatrix_Arg
```

### `PH_Elem_CPE8_NL_TL_Arg` (lines 85–88)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_NL_TL_Arg
```

### `PH_Elem_CPE8_NL_UL_Arg` (lines 92–95)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE8_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE8_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CPE8_ShapeFunc_Legacy` | 188 | `SUBROUTINE PH_Elem_CPE8_ShapeFunc_Legacy(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPE8_Jac_Legacy` | 201 | `SUBROUTINE PH_Elem_CPE8_Jac_Legacy(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPE8_JacB_Legacy` | 215 | `SUBROUTINE PH_Elem_CPE8_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_CPE8_Strain_Legacy` | 236 | `SUBROUTINE PH_Elem_CPE8_Strain_Legacy(B, u, strain)` |
| SUBROUTINE | `PH_Elem_CPE8_Stress_Legacy` | 248 | `SUBROUTINE PH_Elem_CPE8_Stress_Legacy(epsilon, D, sigma)` |
| SUBROUTINE | `PH_ELEM_CPE8_AreaInt` | 263 | `SUBROUTINE PH_ELEM_CPE8_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE8_ThermStrainVector` | 278 | `SUBROUTINE PH_Elem_CPE8_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_CPE8_BMatrix` | 288 | `SUBROUTINE PH_Elem_CPE8_BMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_ConsMass` | 302 | `SUBROUTINE PH_Elem_CPE8_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CPE8_ConstMatrix` | 324 | `SUBROUTINE PH_Elem_CPE8_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_CPE8_DefInit` | 337 | `SUBROUTINE PH_Elem_CPE8_DefInit()` |
| SUBROUTINE | `PH_Elem_CPE8_FormIntForce` | 340 | `SUBROUTINE PH_Elem_CPE8_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_CPE8_FormIntForceFromStress` | 360 | `SUBROUTINE PH_Elem_CPE8_FormIntForceFromStress(coords, sigma3, R_int)` |
| SUBROUTINE | `PH_Elem_CPE8_FormStiffMatrix` | 376 | `SUBROUTINE PH_Elem_CPE8_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_GaussPoints` | 398 | `SUBROUTINE PH_Elem_CPE8_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CPE8_Jac_InOut` | 432 | `SUBROUTINE PH_Elem_CPE8_Jac_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_JacB_InOut` | 447 | `SUBROUTINE PH_Elem_CPE8_JacB_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_LumpMass` | 498 | `SUBROUTINE PH_Elem_CPE8_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CPE8_ShapeFunc_InOut` | 512 | `SUBROUTINE PH_Elem_CPE8_ShapeFunc_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_Strain_InOut` | 546 | `SUBROUTINE PH_Elem_CPE8_Strain_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_Stress_InOut` | 559 | `SUBROUTINE PH_Elem_CPE8_Stress_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_NL_TL_Legacy` | 575 | `SUBROUTINE PH_Elem_CPE8_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPE8_NL_UL_Legacy` | 669 | `SUBROUTINE PH_Elem_CPE8_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPE8_NL_TL_Structured` | 772 | `SUBROUTINE PH_Elem_CPE8_NL_TL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_NL_UL_Structured` | 789 | `SUBROUTINE PH_Elem_CPE8_NL_UL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CPE8_GetArea` | 809 | `SUBROUTINE PH_Elem_CPE8_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE8_GetCentroid` | 815 | `SUBROUTINE PH_Elem_CPE8_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CPE8_GetSectProps` | 842 | `SUBROUTINE PH_Elem_CPE8_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_CPE8_ApplyConstraint` | 854 | `SUBROUTINE PH_Elem_CPE8_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE8_ApplyMPC` | 867 | `SUBROUTINE PH_Elem_CPE8_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE8_FormContactContrib` | 885 | `SUBROUTINE PH_Elem_CPE8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE8_FormContactEdgeCtr` | 917 | `SUBROUTINE PH_Elem_CPE8_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE8_FormEdgePressure` | 959 | `SUBROUTINE PH_Elem_CPE8_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE8_FormBodyForce` | 990 | `SUBROUTINE PH_Elem_CPE8_FormBodyForce(coords, bx, by, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE8_FormNodalForce` | 1010 | `SUBROUTINE PH_Elem_CPE8_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `invert_8x8` | 1027 | `SUBROUTINE invert_8x8(A, info)` |
| SUBROUTINE | `PH_Elem_CPE8_CollectIPVars` | 1056 | `SUBROUTINE PH_Elem_CPE8_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CPE8_EvalPrincStress` | 1078 | `SUBROUTINE PH_Elem_CPE8_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CPE8_EvalStressInvar` | 1091 | `SUBROUTINE PH_Elem_CPE8_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CPE8_EvalVonMises` | 1102 | `SUBROUTINE PH_Elem_CPE8_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CPE8_GetExtrapMat` | 1112 | `SUBROUTINE PH_Elem_CPE8_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CPE8_MapToNode` | 1136 | `SUBROUTINE PH_Elem_CPE8_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_CPE8_Material_Update_Routed` | 1154 | `SUBROUTINE PH_Elem_CPE8_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 148–151 | `INTERFACE PH_Elem_CPE8_ShapeFunc` |
| 153–156 | `INTERFACE PH_Elem_CPE8_Jac` |
| 158–161 | `INTERFACE PH_Elem_CPE8_JacB` |
| 163–166 | `INTERFACE PH_Elem_CPE8_Strain` |
| 168–171 | `INTERFACE PH_Elem_CPE8_Stress` |
| 173–176 | `INTERFACE PH_Elem_CPE8_NL_TL` |
| 178–181 | `INTERFACE PH_Elem_CPE8_NL_UL` |
