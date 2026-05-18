# `PH_Elem_S4.f90`

- **Source**: `L4_PH/Element/Shell/PH_Elem_S4.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_S4`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_S4`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_S4`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shell`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shell/PH_Elem_S4.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_S4_StiffMatrix_Arg` (lines 109–112)

```fortran
  TYPE, PUBLIC :: PH_Elem_S4_StiffMatrix_Arg
    INTEGER(i4) :: integration_scheme  ! Integration scheme: FULL or REDUCED (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S4_StiffMatrix_Arg
```

### `PH_Elem_S4_IntForce_Arg` (lines 118–121)

```fortran
  TYPE, PUBLIC :: PH_Elem_S4_IntForce_Arg
    INTEGER(i4) :: integration_scheme  ! Integration scheme: FULL or REDUCED (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S4_IntForce_Arg
```

### `PH_Elem_S4_NL_TL_Arg` (lines 127–132)

```fortran
  TYPE, PUBLIC :: PH_Elem_S4_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    REAL(wp) :: thickness  ! Shell thickness (Desc)                   ! [IN]
    INTEGER(i4) :: n_layers  ! Number of through-thickness layers (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S4_NL_TL_Arg
```

### `PH_Elem_S4_NL_UL_Arg` (lines 138–143)

```fortran
  TYPE, PUBLIC :: PH_Elem_S4_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    REAL(wp) :: thickness  ! Shell thickness (Desc)                   ! [IN]
    INTEGER(i4) :: n_layers  ! Number of through-thickness layers (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S4_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_El_S4_Fo_Unified` | 148 | `SUBROUTINE PH_El_S4_Fo_Unified(coords, E_young, nu, integration_scheme, Ke)` |
| SUBROUTINE | `PH_El_S4_Fo_Unified` | 211 | `SUBROUTINE PH_El_S4_Fo_Unified(coords, u, E_young, nu, integration_scheme, R_int)` |
| SUBROUTINE | `PH_El_S4_FormStiffMatrixWith` | 274 | `SUBROUTINE PH_El_S4_FormStiffMatrixWith(coords, E_young, nu, thickness, Ke)` |
| SUBROUTINE | `PH_Elem_S4_ConsMass` | 346 | `SUBROUTINE PH_Elem_S4_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_S4_DefInit` | 361 | `SUBROUTINE PH_Elem_S4_DefInit()` |
| SUBROUTINE | `PH_Elem_S4_FormIntForce` | 364 | `SUBROUTINE PH_Elem_S4_FormIntForce(arg)` |
| SUBROUTINE | `PH_Elem_S4_FormStiffMatrix` | 377 | `SUBROUTINE PH_Elem_S4_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_S4_LumpMass` | 390 | `SUBROUTINE PH_Elem_S4_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_S4_NL_TL` | 404 | `SUBROUTINE PH_Elem_S4_NL_TL(arg)` |
| SUBROUTINE | `Invert2x2` | 577 | `SUBROUTINE Invert2x2(A, A_inv, det_A, stat)` |
| SUBROUTINE | `PH_Elem_S4_ShapeFunc_2D` | 598 | `SUBROUTINE PH_Elem_S4_ShapeFunc_2D(xi, eta, N, dN_dxi)` |
| SUBROUTINE | `PH_El_CP_Ga_Single` | 617 | `SUBROUTINE PH_El_CP_Ga_Single(igp, xi, eta, wt)` |
| SUBROUTINE | `PH_Elem_S4_NL_UL` | 633 | `SUBROUTINE PH_Elem_S4_NL_UL(arg)` |
| SUBROUTINE | `Invert2x2` | 815 | `SUBROUTINE Invert2x2(A, A_inv, det_A, stat)` |
| SUBROUTINE | `PH_Elem_S4_ShapeFunc_2D` | 836 | `SUBROUTINE PH_Elem_S4_ShapeFunc_2D(xi, eta, N, dN_dxi)` |
| SUBROUTINE | `PH_El_CP_Ga_Single` | 855 | `SUBROUTINE PH_El_CP_Ga_Single(igp, xi, eta, wt)` |
| SUBROUTINE | `PH_Elem_S4_ThermStrainVector` | 871 | `SUBROUTINE PH_Elem_S4_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Shell_BuildGeomCtrl` | 880 | `SUBROUTINE PH_Shell_BuildGeomCtrl(Formul, formulation_typ, ctrl)` |
| SUBROUTINE | `PH_ELEM_S4_AreaInt` | 928 | `SUBROUTINE PH_ELEM_S4_AreaInt(coords, area)` |
| SUBROUTINE | `UF_Elem_S4_Calc` | 943 | `SUBROUTINE UF_Elem_S4_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PH_Elem_S4_GetArea` | 1169 | `SUBROUTINE PH_Elem_S4_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_S4_GetCentroid` | 1175 | `SUBROUTINE PH_Elem_S4_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_S4_GetSectProps` | 1203 | `SUBROUTINE PH_Elem_S4_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_S4_ApplyConstraint` | 1214 | `SUBROUTINE PH_Elem_S4_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S4_ApplyMPC` | 1227 | `SUBROUTINE PH_Elem_S4_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S4_FormContactContrib` | 1245 | `SUBROUTINE PH_Elem_S4_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S4_FormContactEdgeCtr` | 1280 | `SUBROUTINE PH_Elem_S4_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S4_FormBodyForce` | 1321 | `SUBROUTINE PH_Elem_S4_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_S4_FormEdgePressure` | 1342 | `SUBROUTINE PH_Elem_S4_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S4_FormNodalForce` | 1372 | `SUBROUTINE PH_Elem_S4_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_ELEM_S4_invert_4x4` | 1389 | `SUBROUTINE PH_ELEM_S4_invert_4x4(A, info)` |
| SUBROUTINE | `PH_Elem_S4_CollectIPVars` | 1418 | `SUBROUTINE PH_Elem_S4_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_S4_EvalVonMises` | 1433 | `SUBROUTINE PH_Elem_S4_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_S4_GetExtrapMat` | 1446 | `SUBROUTINE PH_Elem_S4_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_S4_MapToNode` | 1463 | `SUBROUTINE PH_Elem_S4_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_S4_Material_Update_Membrane_Routed` | 1476 | `SUBROUTINE PH_Elem_S4_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
