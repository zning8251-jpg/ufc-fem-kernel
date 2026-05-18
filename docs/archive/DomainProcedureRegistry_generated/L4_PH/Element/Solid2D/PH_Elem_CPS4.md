# `PH_Elem_CPS4.f90`

- **Source**: `L4_PH/Element/Solid2D/PH_Elem_CPS4.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_CPS4`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CPS4`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CPS4`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2D/PH_Elem_CPS4.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_CPS4_ShapeFunc_Arg` (lines 39–45)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_ShapeFunc_Arg
    REAL(wp) :: xi                   ! [IN]
    REAL(wp) :: eta                  ! [IN]
    REAL(wp) :: N(4)                 ! [OUT]
    REAL(wp) :: dNdxi(2, 4)          ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_ShapeFunc_Arg
```

### `PH_Elem_CPS4_Jac_Arg` (lines 47–53)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_Jac_Arg
    REAL(wp) :: dNdxi(2, 4)          ! [IN]
    REAL(wp) :: coords(2, 4)         ! [IN]
    REAL(wp) :: J(2, 2)              ! [OUT]
    REAL(wp) :: detJ                 ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_Jac_Arg
```

### `PH_Elem_CPS4_BMatrix_Arg` (lines 55–59)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_BMatrix_Arg
    REAL(wp) :: dNdx(2, 4)           ! [IN]
    REAL(wp) :: B(3, 8)              ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_BMatrix_Arg
```

### `PH_Elem_CPS4_JacB_Arg` (lines 61–71)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_JacB_Arg
    REAL(wp) :: coords(2, 4)         ! [IN]
    REAL(wp) :: xi                   ! [IN]
    REAL(wp) :: eta                  ! [IN]
    REAL(wp) :: N(4)                 ! [OUT]
    REAL(wp) :: dNdx(2, 4)           ! [OUT]
    REAL(wp) :: J(2, 2)              ! [OUT]
    REAL(wp) :: detJ                 ! [OUT]
    REAL(wp) :: B(3, 8)              ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_JacB_Arg
```

### `PH_Elem_CPS4_Strain_Arg` (lines 73–78)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_Strain_Arg
    REAL(wp) :: B(3, 8)              ! [IN]
    REAL(wp) :: u(8)                 ! [IN]
    REAL(wp) :: strain(3)            ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_Strain_Arg
```

### `PH_Elem_CPS4_Stress_Arg` (lines 80–85)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_Stress_Arg
    REAL(wp) :: epsilon(3)           ! [IN]
    REAL(wp) :: D(3, 3)              ! [IN]
    REAL(wp) :: sigma(3)             ! [OUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_Stress_Arg
```

### `PH_Elem_CPS4_StiffMatrix_Arg` (lines 87–92)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_StiffMatrix_Arg
    REAL(wp) :: coords(2, 4)         ! [IN]
    REAL(wp) :: D_matrix(3, 3)       ! [IN]
    REAL(wp) :: Ke(8, 8)             ! [INOUT]
    TYPE(ErrorStatusType) :: status  ! [OUT]
  END TYPE PH_Elem_CPS4_StiffMatrix_Arg
```

### `PH_Elem_CPS4_NL_TL_Arg` (lines 96–99)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS4_NL_TL_Arg
```

### `PH_Elem_CPS4_NL_UL_Arg` (lines 103–106)

```fortran
  TYPE, PUBLIC :: PH_Elem_CPS4_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_CPS4_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CPS4_ShapeFunc_Legacy` | 198 | `SUBROUTINE PH_Elem_CPS4_ShapeFunc_Legacy(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CPS4_Jac_Legacy` | 210 | `SUBROUTINE PH_Elem_CPS4_Jac_Legacy(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CPS4_JacB_Legacy` | 223 | `SUBROUTINE PH_Elem_CPS4_JacB_Legacy(coords, xi_pt, eta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_CPS4_Strain_Legacy` | 243 | `SUBROUTINE PH_Elem_CPS4_Strain_Legacy(B, u, strain)` |
| SUBROUTINE | `PH_Elem_CPS4_Stress_Legacy` | 254 | `SUBROUTINE PH_Elem_CPS4_Stress_Legacy(epsilon, D, sigma)` |
| SUBROUTINE | `PH_ELEM_CPS4_AreaInt` | 268 | `SUBROUTINE PH_ELEM_CPS4_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_CPS4_ThermStrainVector` | 283 | `SUBROUTINE PH_Elem_CPS4_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_CPS4_BMatrix` | 293 | `SUBROUTINE PH_Elem_CPS4_BMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CPS4_ConsMass` | 307 | `SUBROUTINE PH_Elem_CPS4_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CPS4_ConstMatrix` | 331 | `SUBROUTINE PH_Elem_CPS4_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_CPS4_DefInit` | 344 | `SUBROUTINE PH_Elem_CPS4_DefInit()` |
| SUBROUTINE | `PH_Elem_CPS4_FormIntForce` | 347 | `SUBROUTINE PH_Elem_CPS4_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_CPS4_FormIntForceFromStress` | 367 | `SUBROUTINE PH_Elem_CPS4_FormIntForceFromStress(coords, sigma3, R_int)` |
| SUBROUTINE | `PH_Elem_CPS4_FormStiffMatrix` | 383 | `SUBROUTINE PH_Elem_CPS4_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_CPS4_GaussPoints` | 405 | `SUBROUTINE PH_Elem_CPS4_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CPS4_Jac_InOut` | 423 | `SUBROUTINE PH_Elem_CPS4_Jac_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS4_JacB_InOut` | 438 | `SUBROUTINE PH_Elem_CPS4_JacB_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS4_LumpMass` | 489 | `SUBROUTINE PH_Elem_CPS4_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CPS4_ShapeFunc_InOut` | 503 | `SUBROUTINE PH_Elem_CPS4_ShapeFunc_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS4_Strain_InOut` | 521 | `SUBROUTINE PH_Elem_CPS4_Strain_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS4_Stress_InOut` | 534 | `SUBROUTINE PH_Elem_CPS4_Stress_InOut(arg)` |
| SUBROUTINE | `PH_Elem_CPS4_NL_TL_Legacy` | 550 | `SUBROUTINE PH_Elem_CPS4_NL_TL_Legacy(coords_ref, u_elem, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPS4_NL_UL_Legacy` | 653 | `SUBROUTINE PH_Elem_CPS4_NL_UL_Legacy(coords_prev, u_incr, D, Ke_mat, Ke_geo, R_int, status)` |
| SUBROUTINE | `PH_Elem_CPS4_NL_TL_Structured` | 764 | `SUBROUTINE PH_Elem_CPS4_NL_TL_Structured(elem_cfg, elem_state, elem_ctx, mat_cfg, status)` |
| SUBROUTINE | `PH_Elem_CPS4_Material_Update_Routed` | 894 | `SUBROUTINE PH_Elem_CPS4_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |
| SUBROUTINE | `PH_Elem_CPS4_GetArea` | 915 | `SUBROUTINE PH_Elem_CPS4_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CPS4_GetCentroid` | 921 | `SUBROUTINE PH_Elem_CPS4_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CPS4_GetSectProps` | 948 | `SUBROUTINE PH_Elem_CPS4_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_CPS4_ApplyConstraint` | 960 | `SUBROUTINE PH_Elem_CPS4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS4_ApplyMPC` | 973 | `SUBROUTINE PH_Elem_CPS4_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS4_FormContactContrib` | 991 | `SUBROUTINE PH_Elem_CPS4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS4_FormContactEdgeCtr` | 1023 | `SUBROUTINE PH_Elem_CPS4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_CPS4_FormEdgePressure` | 1065 | `SUBROUTINE PH_Elem_CPS4_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CPS4_FormBodyForce` | 1088 | `SUBROUTINE PH_Elem_CPS4_FormBodyForce(coords, bx, by, F_eq)` |
| SUBROUTINE | `PH_Elem_CPS4_FormNodalForce` | 1108 | `SUBROUTINE PH_Elem_CPS4_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `invert_4x4` | 1125 | `SUBROUTINE invert_4x4(A, info)` |
| SUBROUTINE | `PH_Elem_CPS4_CollectIPVars` | 1154 | `SUBROUTINE PH_Elem_CPS4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_CPS4_EvalPrincStress` | 1176 | `SUBROUTINE PH_Elem_CPS4_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_CPS4_EvalStressInvar` | 1189 | `SUBROUTINE PH_Elem_CPS4_EvalStressInvar(sigma, I1, J2)` |
| SUBROUTINE | `PH_Elem_CPS4_EvalVonMises` | 1200 | `SUBROUTINE PH_Elem_CPS4_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_CPS4_GetExtrapMat` | 1210 | `SUBROUTINE PH_Elem_CPS4_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_CPS4_MapToNode` | 1230 | `SUBROUTINE PH_Elem_CPS4_MapToNode(ip_vars, weights, node_vars)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 159–162 | `INTERFACE PH_Elem_CPS4_ShapeFunc` |
| 164–167 | `INTERFACE PH_Elem_CPS4_Jac` |
| 169–172 | `INTERFACE PH_Elem_CPS4_JacB` |
| 174–177 | `INTERFACE PH_Elem_CPS4_Strain` |
| 179–182 | `INTERFACE PH_Elem_CPS4_Stress` |
| 184–187 | `INTERFACE PH_Elem_CPS4_NL_TL` |
| 189–191 | `INTERFACE PH_Elem_CPS4_NL_UL` |
