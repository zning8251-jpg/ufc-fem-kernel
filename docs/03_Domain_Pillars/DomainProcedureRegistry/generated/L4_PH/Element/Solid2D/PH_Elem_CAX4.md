# `PH_Elem_CAX4.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_CAX4.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_CAX4`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CAX4`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CAX4`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_CAX4.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_CAX4_ShapeFunc_Arg` (lines 42–44)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_ShapeFunc_Arg
```

### `PH_Elem_CAX4_Jac_Arg` (lines 48–51)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_Jac_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_Jac_Arg
```

### `PH_Elem_CAX4_BMatrix_Arg` (lines 55–58)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_BMatrix_Arg
    REAL(wp) :: r_pt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_BMatrix_Arg
```

### `PH_Elem_CAX4_JacB_Arg` (lines 62–66)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_JacB_Arg
    REAL(wp) :: detJ                   ! [OUT]
    REAL(wp) :: r_pt                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_JacB_Arg
```

### `PH_Elem_CAX4_Strain_Arg` (lines 70–72)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_Strain_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_Strain_Arg
```

### `PH_Elem_CAX4_Stress_Arg` (lines 76–78)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_Stress_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_Stress_Arg
```

### `PH_Elem_CAX4_StiffMatrix_Arg` (lines 82–84)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_StiffMatrix_Arg
```

### `PH_Elem_CAX4_NL_TL_Arg` (lines 88–91)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_NL_TL_Arg
```

### `PH_Elem_CAX4_NL_UL_Arg` (lines 95–98)

```fortran
  TYPE, PUBLIC :: PH_Elem_CAX4_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CAX4_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CAX4_ShapeFunc_Legacy` | 192 | `SUBROUTINE PH_Elem_CAX4_ShapeFunc_Legacy(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CAX4_Jac_Legacy` | 205 | `SUBROUTINE PH_Elem_CAX4_Jac_Legacy(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CAX4_JacB_Legacy` | 219 | `SUBROUTINE PH_Elem_CAX4_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, r_pt, B)` |
| SUBROUTINE | `PH_Elem_CAX4_Strain_Legacy` | 242 | `SUBROUTINE PH_Elem_CAX4_Strain_Legacy(B, u, strain)` |
| SUBROUTINE | `PH_Elem_CAX4_Stress_Legacy` | 254 | `SUBROUTINE PH_Elem_CAX4_Stress_Legacy(epsilon, D, sigma)` |
| SUBROUTINE | `PH_ELEM_CAX4_VolInt` | 269 | `SUBROUTINE PH_ELEM_CAX4_VolInt(coords, area_r)` |
| SUBROUTINE | `PH_Elem_CAX4_ThermStrainVector` | 285 | `SUBROUTINE PH_Elem_CAX4_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_CAX4_BMatrix` | 296 | `SUBROUTINE PH_Elem_CAX4_BMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_ConsMass` | 314 | `SUBROUTINE PH_Elem_CAX4_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CAX4_ConstMatrix` | 337 | `SUBROUTINE PH_Elem_CAX4_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_CAX4_DefInit` | 357 | `SUBROUTINE PH_Elem_CAX4_DefInit()` |
| SUBROUTINE | `PH_Elem_CAX4_FormIntForce` | 360 | `SUBROUTINE PH_Elem_CAX4_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_CAX4_FormIntForceFromStress` | 380 | `SUBROUTINE PH_Elem_CAX4_FormIntForceFromStress(coords, sigma4, R_int)` |
| SUBROUTINE | `PH_Elem_CAX4_FormStiffMatrix` | 396 | `SUBROUTINE PH_Elem_CAX4_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_GaussPoints` | 419 | `SUBROUTINE PH_Elem_CAX4_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CAX4_Jac_InOut` | 437 | `SUBROUTINE PH_Elem_CAX4_Jac_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_JacB_InOut` | 452 | `SUBROUTINE PH_Elem_CAX4_JacB_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_LumpMass` | 509 | `SUBROUTINE PH_Elem_CAX4_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CAX4_ShapeFunc_InOut` | 523 | `SUBROUTINE PH_Elem_CAX4_ShapeFunc_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_Strain_InOut` | 541 | `SUBROUTINE PH_Elem_CAX4_Strain_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_Stress_InOut` | 555 | `SUBROUTINE PH_Elem_CAX4_Stress_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_NL_TL_Legacy` | 572 | `SUBROUTINE PH_Elem_CAX4_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CAX4_NL_UL_Legacy` | 682 | `SUBROUTINE PH_Elem_CAX4_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CAX4_NL_TL_Structured` | 801 | `SUBROUTINE PH_Elem_CAX4_NL_TL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_NL_UL_Structured` | 819 | `SUBROUTINE PH_Elem_CAX4_NL_UL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CAX4_GetArea` | 840 | `SUBROUTINE PH_Elem_CAX4_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CAX4_GetVolume` | 855 | `SUBROUTINE PH_Elem_CAX4_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_CAX4_GetCentroid` | 863 | `SUBROUTINE PH_Elem_CAX4_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CAX4_GetSectProps` | 891 | `SUBROUTINE PH_Elem_CAX4_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_CAX4_ApplyConstraint` | 903 | `SUBROUTINE PH_Elem_CAX4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CAX4_ApplyMPC` | 916 | `SUBROUTINE PH_Elem_CAX4_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CAX4_FormContactContrib` | 934 | `SUBROUTINE PH_Elem_CAX4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, r_edge, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CAX4_FormContactEdgeCtr` | 967 | `SUBROUTINE PH_Elem_CAX4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CAX4_FormEdgePressure` | 1002 | `SUBROUTINE PH_Elem_CAX4_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CAX4_FormBodyForce` | 1026 | `SUBROUTINE PH_Elem_CAX4_FormBodyForce(coords, br, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_CAX4_FormNodalForce` | 1047 | `SUBROUTINE PH_Elem_CAX4_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `invert_4x4` | 1064 | `SUBROUTINE invert_4x4(A, info)` |
| SUBROUTINE | `PH_Elem_CAX4_CollectIPVars` | 1093 | `SUBROUTINE PH_Elem_CAX4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CAX4_EvalPrincStress` | 1109 | `SUBROUTINE PH_Elem_CAX4_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CAX4_EvalStressInvar` | 1124 | `SUBROUTINE PH_Elem_CAX4_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CAX4_EvalVonMises` | 1136 | `SUBROUTINE PH_Elem_CAX4_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CAX4_GetExtrapMat` | 1147 | `SUBROUTINE PH_Elem_CAX4_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CAX4_MapToNode` | 1166 | `SUBROUTINE PH_Elem_CAX4_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_CAX4_Material_Update_Routed` | 1184 | `SUBROUTINE PH_Elem_CAX4_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 152–155 | `INTERFACE PH_Elem_CAX4_ShapeFunc` |
| 157–160 | `INTERFACE PH_Elem_CAX4_Jac` |
| 162–165 | `INTERFACE PH_Elem_CAX4_JacB` |
| 167–170 | `INTERFACE PH_Elem_CAX4_Strain` |
| 172–175 | `INTERFACE PH_Elem_CAX4_Stress` |
| 177–180 | `INTERFACE PH_Elem_CAX4_NL_TL` |
| 182–185 | `INTERFACE PH_Elem_CAX4_NL_UL` |
