# `PH_Elem_CPS8.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_CPS8.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_CPS8`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CPS8`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CPS8`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_CPS8.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_CPS8_ShapeFunc_Arg` (lines 40–42)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_ShapeFunc_Arg
```

### `PH_Elem_CPS8_Jac_Arg` (lines 46–49)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_Jac_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_Jac_Arg
```

### `PH_Elem_CPS8_BMatrix_Arg` (lines 53–55)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_BMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_BMatrix_Arg
```

### `PH_Elem_CPS8_JacB_Arg` (lines 59–62)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_JacB_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_JacB_Arg
```

### `PH_Elem_CPS8_Strain_Arg` (lines 66–68)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_Strain_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_Strain_Arg
```

### `PH_Elem_CPS8_Stress_Arg` (lines 72–74)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_Stress_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_Stress_Arg
```

### `PH_Elem_CPS8_StiffMatrix_Arg` (lines 78–80)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_StiffMatrix_Arg
```

### `PH_Elem_CPS8_NL_TL_Arg` (lines 84–87)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_NL_TL_Arg
```

### `PH_Elem_CPS8_NL_UL_Arg` (lines 91–94)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS8_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS8_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CPS8_ShapeFunc_Legacy` | 196 | `SUBROUTINE PH_Elem_CPS8_ShapeFunc_Legacy(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPS8_Jac_Legacy` | 209 | `SUBROUTINE PH_Elem_CPS8_Jac_Legacy(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPS8_JacB_Legacy` | 223 | `SUBROUTINE PH_Elem_CPS8_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_CPS8_Strain_Legacy` | 244 | `SUBROUTINE PH_Elem_CPS8_Strain_Legacy(B, u, strain)` |
| SUBROUTINE | `PH_Elem_CPS8_Stress_Legacy` | 256 | `SUBROUTINE PH_Elem_CPS8_Stress_Legacy(epsilon, D, sigma)` |
| SUBROUTINE | `PH_Elem_CPS8_ShapeFunc_3D` | 269 | `SUBROUTINE PH_Elem_CPS8_ShapeFunc_3D(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPS8_Jac_3D` | 279 | `SUBROUTINE PH_Elem_CPS8_Jac_3D(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPS8_JacB_3D` | 291 | `SUBROUTINE PH_Elem_CPS8_JacB_3D(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_CPS8_BMatrix_3D` | 308 | `SUBROUTINE PH_Elem_CPS8_BMatrix_3D(dNdx, B)` |
| SUBROUTINE | `PH_ELEM_CPS8_AreaInt` | 321 | `SUBROUTINE PH_ELEM_CPS8_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_CPS8_ThermStrainVector` | 336 | `SUBROUTINE PH_Elem_CPS8_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_CPS8_BMatrix` | 346 | `SUBROUTINE PH_Elem_CPS8_BMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_ConsMass` | 360 | `SUBROUTINE PH_Elem_CPS8_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CPS8_ConstMatrix` | 382 | `SUBROUTINE PH_Elem_CPS8_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_CPS8_DefInit` | 395 | `SUBROUTINE PH_Elem_CPS8_DefInit()` |
| SUBROUTINE | `PH_Elem_CPS8_FormIntForce` | 398 | `SUBROUTINE PH_Elem_CPS8_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_CPS8_FormIntForceFromStress` | 418 | `SUBROUTINE PH_Elem_CPS8_FormIntForceFromStress(coords, sigma3, R_int)` |
| SUBROUTINE | `PH_Elem_CPS8_FormStiffMatrix` | 434 | `SUBROUTINE PH_Elem_CPS8_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_GaussPoints_2D` | 456 | `SUBROUTINE PH_Elem_CPS8_GaussPoints_2D(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CPS8_GaussPoints_3D` | 490 | `SUBROUTINE PH_Elem_CPS8_GaussPoints_3D(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_CPS8_Jac_InOut` | 496 | `SUBROUTINE PH_Elem_CPS8_Jac_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_JacB_InOut` | 511 | `SUBROUTINE PH_Elem_CPS8_JacB_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_LumpMass` | 562 | `SUBROUTINE PH_Elem_CPS8_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CPS8_ShapeFunc_InOut` | 576 | `SUBROUTINE PH_Elem_CPS8_ShapeFunc_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_Strain_InOut` | 610 | `SUBROUTINE PH_Elem_CPS8_Strain_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_Stress_InOut` | 623 | `SUBROUTINE PH_Elem_CPS8_Stress_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_NL_TL_Legacy` | 639 | `SUBROUTINE PH_Elem_CPS8_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPS8_NL_UL_Legacy` | 733 | `SUBROUTINE PH_Elem_CPS8_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPS8_NL_TL_Structured` | 835 | `SUBROUTINE PH_Elem_CPS8_NL_TL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_NL_UL_Structured` | 852 | `SUBROUTINE PH_Elem_CPS8_NL_UL_Structured(arg)` |
| SUBROUTINE | `PH_Elem_CPS8_GetArea` | 872 | `SUBROUTINE PH_Elem_CPS8_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CPS8_GetCentroid` | 878 | `SUBROUTINE PH_Elem_CPS8_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CPS8_GetSectProps` | 905 | `SUBROUTINE PH_Elem_CPS8_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_CPS8_ApplyConstraint` | 917 | `SUBROUTINE PH_Elem_CPS8_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS8_ApplyMPC` | 930 | `SUBROUTINE PH_Elem_CPS8_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS8_FormContactContrib` | 948 | `SUBROUTINE PH_Elem_CPS8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS8_FormContactEdgeCtr` | 980 | `SUBROUTINE PH_Elem_CPS8_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS8_FormEdgePressure` | 1022 | `SUBROUTINE PH_Elem_CPS8_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPS8_FormBodyForce` | 1053 | `SUBROUTINE PH_Elem_CPS8_FormBodyForce(coords, bx, by, F_eq)` |
| SUBROUTINE | `PH_Elem_CPS8_FormNodalForce` | 1073 | `SUBROUTINE PH_Elem_CPS8_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `invert_8x8` | 1090 | `SUBROUTINE invert_8x8(A, info)` |
| SUBROUTINE | `PH_Elem_CPS8_CollectIPVars` | 1119 | `SUBROUTINE PH_Elem_CPS8_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CPS8_EvalPrincStress` | 1141 | `SUBROUTINE PH_Elem_CPS8_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CPS8_EvalStressInvar` | 1154 | `SUBROUTINE PH_Elem_CPS8_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CPS8_EvalVonMises` | 1165 | `SUBROUTINE PH_Elem_CPS8_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CPS8_GetExtrapMat` | 1175 | `SUBROUTINE PH_Elem_CPS8_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CPS8_MapToNode` | 1199 | `SUBROUTINE PH_Elem_CPS8_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_CPS8_Material_Update_Routed` | 1217 | `SUBROUTINE PH_Elem_CPS8_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 147–151 | `INTERFACE PH_Elem_CPS8_ShapeFunc` |
| 152–156 | `INTERFACE PH_Elem_CPS8_Jac` |
| 157–160 | `INTERFACE PH_Elem_CPS8_GaussPoints` |
| 161–165 | `INTERFACE PH_Elem_CPS8_JacB` |
| 166–169 | `INTERFACE PH_Elem_CPS8_BMatrix` |
| 171–174 | `INTERFACE PH_Elem_CPS8_Strain` |
| 176–179 | `INTERFACE PH_Elem_CPS8_Stress` |
| 181–184 | `INTERFACE PH_Elem_CPS8_NL_TL` |
| 186–189 | `INTERFACE PH_Elem_CPS8_NL_UL` |
