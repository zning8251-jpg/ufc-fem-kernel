# `PH_Elem_CPE4.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_CPE4.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_CPE4`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CPE4`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CPE4`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_CPE4.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_CPE4_ShapeFunc_Arg` (lines 40–42)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_ShapeFunc_Arg
```

### `PH_Elem_CPE4_Jac_Arg` (lines 46–49)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_Jac_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_Jac_Arg
```

### `PH_Elem_CPE4_BMatrix_Arg` (lines 53–55)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_BMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_BMatrix_Arg
```

### `PH_Elem_CPE4_JacB_Arg` (lines 59–62)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_JacB_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_JacB_Arg
```

### `PH_Elem_CPE4_Strain_Arg` (lines 66–68)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_Strain_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_Strain_Arg
```

### `PH_Elem_CPE4_Stress_Arg` (lines 72–74)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_Stress_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_Stress_Arg
```

### `PH_Elem_CPE4_StiffMatrix_Arg` (lines 78–80)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_StiffMatrix_Arg
```

### `PH_Elem_CPE4_NL_TL_Arg` (lines 84–87)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_NL_TL_Arg
```

### `PH_Elem_CPE4_NL_UL_Arg` (lines 91–94)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPE4_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPE4_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CPE4_ShapeFunc_Legacy` | 189 | `SUBROUTINE PH_Elem_CPE4_ShapeFunc_Legacy(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPE4_Jac_Legacy` | 202 | `SUBROUTINE PH_Elem_CPE4_Jac_Legacy(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPE4_JacB_Legacy` | 216 | `SUBROUTINE PH_Elem_CPE4_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_CPE4_Strain_Legacy` | 237 | `SUBROUTINE PH_Elem_CPE4_Strain_Legacy(B, u, strain)` |
| SUBROUTINE | `PH_Elem_CPE4_Stress_Legacy` | 249 | `SUBROUTINE PH_Elem_CPE4_Stress_Legacy(epsilon, D, sigma)` |
| SUBROUTINE | `PH_ELEM_CPE4_AreaInt` | 264 | `SUBROUTINE PH_ELEM_CPE4_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE4_ThermStrainVector` | 279 | `SUBROUTINE PH_Elem_CPE4_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_CPE4_BMatrix` | 289 | `SUBROUTINE PH_Elem_CPE4_BMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_ConsMass` | 303 | `SUBROUTINE PH_Elem_CPE4_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CPE4_ConstMatrix` | 327 | `SUBROUTINE PH_Elem_CPE4_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_CPE4_DefInit` | 340 | `SUBROUTINE PH_Elem_CPE4_DefInit()` |
| SUBROUTINE | `PH_Elem_CPE4_FormIntForce` | 343 | `SUBROUTINE PH_Elem_CPE4_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_CPE4_FormIntForceFromStress` | 363 | `SUBROUTINE PH_Elem_CPE4_FormIntForceFromStress(coords, sigma3, R_int)` |
| SUBROUTINE | `PH_Elem_CPE4_FormStiffMatrix` | 379 | `SUBROUTINE PH_Elem_CPE4_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_GaussPoints` | 401 | `SUBROUTINE PH_Elem_CPE4_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CPE4_Jac_InOut` | 419 | `SUBROUTINE PH_Elem_CPE4_Jac_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_JacB_InOut` | 434 | `SUBROUTINE PH_Elem_CPE4_JacB_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_LumpMass` | 485 | `SUBROUTINE PH_Elem_CPE4_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CPE4_ShapeFunc_InOut` | 499 | `SUBROUTINE PH_Elem_CPE4_ShapeFunc_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_Strain_InOut` | 517 | `SUBROUTINE PH_Elem_CPE4_Strain_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_Stress_InOut` | 530 | `SUBROUTINE PH_Elem_CPE4_Stress_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_NL_TL_Structured` | 546 | `SUBROUTINE PH_Elem_CPE4_NL_TL_Structured(elem_cfg, elem_state, elem_ctx, mat_cfg, status)` |
| SUBROUTINE | `PH_Elem_CPE4_Material_Update_Routed` | 684 | `SUBROUTINE PH_Elem_CPE4_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |
| SUBROUTINE | `PH_Elem_CPE4_NL_TL_Legacy` | 702 | `SUBROUTINE PH_Elem_CPE4_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPE4_NL_UL_Legacy` | 805 | `SUBROUTINE PH_Elem_CPE4_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPE4_NL_TL_Structured` | 917 | `SUBROUTINE PH_Elem_CPE4_NL_TL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_NL_UL_Structured` | 934 | `SUBROUTINE PH_Elem_CPE4_NL_UL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CPE4_GetArea` | 954 | `SUBROUTINE PH_Elem_CPE4_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CPE4_GetCentroid` | 960 | `SUBROUTINE PH_Elem_CPE4_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CPE4_GetSectProps` | 987 | `SUBROUTINE PH_Elem_CPE4_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_CPE4_ApplyConstraint` | 999 | `SUBROUTINE PH_Elem_CPE4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE4_ApplyMPC` | 1012 | `SUBROUTINE PH_Elem_CPE4_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE4_FormContactContrib` | 1030 | `SUBROUTINE PH_Elem_CPE4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE4_FormContactEdgeCtr` | 1062 | `SUBROUTINE PH_Elem_CPE4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPE4_FormEdgePressure` | 1104 | `SUBROUTINE PH_Elem_CPE4_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE4_FormBodyForce` | 1127 | `SUBROUTINE PH_Elem_CPE4_FormBodyForce(coords, bx, by, F_eq)` |
| SUBROUTINE | `PH_Elem_CPE4_FormNodalForce` | 1147 | `SUBROUTINE PH_Elem_CPE4_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `invert_4x4` | 1164 | `SUBROUTINE invert_4x4(A, info)` |
| SUBROUTINE | `PH_Elem_CPE4_CollectIPVars` | 1193 | `SUBROUTINE PH_Elem_CPE4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CPE4_EvalPrincStress` | 1215 | `SUBROUTINE PH_Elem_CPE4_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CPE4_EvalStressInvar` | 1228 | `SUBROUTINE PH_Elem_CPE4_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CPE4_EvalVonMises` | 1239 | `SUBROUTINE PH_Elem_CPE4_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CPE4_GetExtrapMat` | 1249 | `SUBROUTINE PH_Elem_CPE4_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CPE4_MapToNode` | 1269 | `SUBROUTINE PH_Elem_CPE4_MapToNode(ip_vars, weights, node_vars)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 149–152 | `INTERFACE PH_Elem_CPE4_ShapeFunc` |
| 154–157 | `INTERFACE PH_Elem_CPE4_Jac` |
| 159–162 | `INTERFACE PH_Elem_CPE4_JacB` |
| 164–167 | `INTERFACE PH_Elem_CPE4_Strain` |
| 169–172 | `INTERFACE PH_Elem_CPE4_Stress` |
| 174–177 | `INTERFACE PH_Elem_CPE4_NL_TL` |
| 179–182 | `INTERFACE PH_Elem_CPE4_NL_UL` |
