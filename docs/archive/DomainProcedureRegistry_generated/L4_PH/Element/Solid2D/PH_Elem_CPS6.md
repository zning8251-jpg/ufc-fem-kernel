# `PH_Elem_CPS6.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_CPS6.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_CPS6`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CPS6`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CPS6`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_CPS6.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_CPS6_ShapeFunc_Arg` (lines 40–42)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS6_ShapeFunc_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_ShapeFunc_Arg
```

### `PH_Elem_CPS6_Jac_Arg` (lines 46–49)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS6_Jac_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_Jac_Arg
```

### `PH_Elem_CPS6_BMatrix_Arg` (lines 53–55)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS6_BMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_BMatrix_Arg
```

### `PH_Elem_CPS6_JacB_Arg` (lines 59–62)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS6_JacB_Arg
    REAL(wp) :: detJ                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_JacB_Arg
```

### `PH_Elem_CPS6_Strain_Arg` (lines 66–68)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS6_Strain_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_Strain_Arg
```

### `PH_Elem_CPS6_Stress_Arg` (lines 72–74)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS6_Stress_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS6_Stress_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CPS6_ShapeFunc_Legacy` | 163 | `SUBROUTINE PH_Elem_CPS6_ShapeFunc_Legacy(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPS6_Jac_Legacy` | 176 | `SUBROUTINE PH_Elem_CPS6_Jac_Legacy(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPS6_JacB_Legacy` | 190 | `SUBROUTINE PH_Elem_CPS6_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_CPS6_Strain_Legacy` | 211 | `SUBROUTINE PH_Elem_CPS6_Strain_Legacy(B, u, strain)` |
| SUBROUTINE | `PH_Elem_CPS6_Stress_Legacy` | 223 | `SUBROUTINE PH_Elem_CPS6_Stress_Legacy(epsilon, D, sigma)` |
| SUBROUTINE | `PH_ELEM_CPS6_AreaInt` | 238 | `SUBROUTINE PH_ELEM_CPS6_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_CPS6_ThermStrainVector` | 253 | `SUBROUTINE PH_Elem_CPS6_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_CPS6_BMatrix` | 263 | `SUBROUTINE PH_Elem_CPS6_BMatrix(dNdx, B)` |
| SUBROUTINE | `PH_Elem_CPS6_ConstMatrix` | 276 | `SUBROUTINE PH_Elem_CPS6_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_CPS6_DefInit` | 289 | `SUBROUTINE PH_Elem_CPS6_DefInit()` |
| SUBROUTINE | `PH_Elem_CPS6_FormIntForce` | 292 | `SUBROUTINE PH_Elem_CPS6_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_CPS6_FormIntForceFromStress` | 312 | `SUBROUTINE PH_Elem_CPS6_FormIntForceFromStress(coords, sigma3, R_int)` |
| SUBROUTINE | `PH_Elem_CPS6_FormStiffMatrix` | 328 | `SUBROUTINE PH_Elem_CPS6_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_CPS6_FormStiffMatrixFromD` | 345 | `SUBROUTINE PH_Elem_CPS6_FormStiffMatrixFromD(coords, D3, Ke)` |
| SUBROUTINE | `PH_Elem_CPS6_GaussPoints` | 361 | `SUBROUTINE PH_Elem_CPS6_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CPS6_ShapeFunc_InOut` | 377 | `SUBROUTINE PH_Elem_CPS6_ShapeFunc_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS6_Jac_InOut` | 411 | `SUBROUTINE PH_Elem_CPS6_Jac_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS6_JacB_InOut` | 426 | `SUBROUTINE PH_Elem_CPS6_JacB_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS6_Strain_InOut` | 470 | `SUBROUTINE PH_Elem_CPS6_Strain_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS6_Stress_InOut` | 483 | `SUBROUTINE PH_Elem_CPS6_Stress_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS6_ConsMass` | 496 | `SUBROUTINE PH_Elem_CPS6_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CPS6_LumpMass` | 518 | `SUBROUTINE PH_Elem_CPS6_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CPS6_NL_TL_Legacy` | 535 | `SUBROUTINE PH_Elem_CPS6_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPS6_NL_UL_Legacy` | 629 | `SUBROUTINE PH_Elem_CPS6_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPS6_GetArea` | 734 | `SUBROUTINE PH_Elem_CPS6_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CPS6_GetCentroid` | 740 | `SUBROUTINE PH_Elem_CPS6_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CPS6_GetSectProps` | 767 | `SUBROUTINE PH_Elem_CPS6_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_CPS6_ApplyConstraint` | 779 | `SUBROUTINE PH_Elem_CPS6_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS6_ApplyMPC` | 792 | `SUBROUTINE PH_Elem_CPS6_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS6_FormContactContrib` | 810 | `SUBROUTINE PH_Elem_CPS6_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS6_FormContactEdgeCtr` | 842 | `SUBROUTINE PH_Elem_CPS6_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS6_FormEdgePressure` | 881 | `SUBROUTINE PH_Elem_CPS6_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPS6_FormBodyForce` | 912 | `SUBROUTINE PH_Elem_CPS6_FormBodyForce(coords, bx, by, F_eq)` |
| SUBROUTINE | `PH_Elem_CPS6_FormNodalForce` | 932 | `SUBROUTINE PH_Elem_CPS6_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `invert_3x3` | 949 | `SUBROUTINE invert_3x3(A, info)` |
| SUBROUTINE | `PH_Elem_CPS6_CollectIPVars` | 978 | `SUBROUTINE PH_Elem_CPS6_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CPS6_EvalPrincStress` | 1000 | `SUBROUTINE PH_Elem_CPS6_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CPS6_EvalStressInvar` | 1013 | `SUBROUTINE PH_Elem_CPS6_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CPS6_EvalVonMises` | 1024 | `SUBROUTINE PH_Elem_CPS6_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CPS6_GetExtrapMat` | 1034 | `SUBROUTINE PH_Elem_CPS6_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CPS6_MapToNode` | 1064 | `SUBROUTINE PH_Elem_CPS6_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_CPS6_Material_Update_Routed` | 1082 | `SUBROUTINE PH_Elem_CPS6_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 125–128 | `INTERFACE PH_Elem_CPS6_ShapeFunc` |
| 130–133 | `INTERFACE PH_Elem_CPS6_Jac` |
| 135–138 | `INTERFACE PH_Elem_CPS6_JacB` |
| 140–143 | `INTERFACE PH_Elem_CPS6_Strain` |
| 145–148 | `INTERFACE PH_Elem_CPS6_Stress` |
| 150–152 | `INTERFACE PH_Elem_CPS6_NL_TL` |
| 154–156 | `INTERFACE PH_Elem_CPS6_NL_UL` |
