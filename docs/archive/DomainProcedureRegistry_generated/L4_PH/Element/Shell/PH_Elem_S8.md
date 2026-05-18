# `PH_Elem_S8.f90`

- **Source**: `L4_PH/Element/Shell/PH_Elem_S8.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_S8`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_S8`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_S8`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shell`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shell/PH_Elem_S8.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_S8_StiffMatrix_Arg` (lines 66–68)

```fortran
  TYPE, PUBLIC :: PH_Elem_S8_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_S8_StiffMatrix_Arg
```

### `PH_Elem_S8_IntForce_Arg` (lines 72–74)

```fortran
  TYPE, PUBLIC :: PH_Elem_S8_IntForce_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_S8_IntForce_Arg
```

### `PH_Elem_S8_NL_TL_Arg` (lines 78–83)

```fortran
  TYPE, PUBLIC :: PH_Elem_S8_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    REAL(wp) :: thickness                   ! [IN]
    INTEGER(i4) :: n_layers                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_S8_NL_TL_Arg
```

### `PH_Elem_S8_NL_UL_Arg` (lines 87–92)

```fortran
  TYPE, PUBLIC :: PH_Elem_S8_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop                   ! [IN]
    REAL(wp) :: thickness                   ! [IN]
    INTEGER(i4) :: n_layers                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_S8_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_S8_ConsMass` | 100 | `SUBROUTINE PH_Elem_S8_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_S8_DefInit` | 115 | `SUBROUTINE PH_Elem_S8_DefInit()` |
| SUBROUTINE | `PH_Elem_S8_FormIntForce_Legacy` | 118 | `SUBROUTINE PH_Elem_S8_FormIntForce_Legacy(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_S8_FormIntForce` | 133 | `SUBROUTINE PH_Elem_S8_FormIntForce(arg)` |
| SUBROUTINE | `PH_Elem_S8_FormStiffMatrix_Legacy` | 149 | `SUBROUTINE PH_Elem_S8_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_S8_FormStiffMatrix` | 162 | `SUBROUTINE PH_Elem_S8_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_S8_LumpMass` | 177 | `SUBROUTINE PH_Elem_S8_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_S8_NL_TL` | 191 | `SUBROUTINE PH_Elem_S8_NL_TL(arg)` |
| SUBROUTINE | `Invert2x2` | 307 | `SUBROUTINE Invert2x2(A, A_inv, det, stat)` |
| SUBROUTINE | `PH_Elem_S8_NL_UL` | 326 | `SUBROUTINE PH_Elem_S8_NL_UL(arg)` |
| SUBROUTINE | `Invert2x2` | 452 | `SUBROUTINE Invert2x2(A, A_inv, det, stat)` |
| SUBROUTINE | `PH_Elem_S8_ThermStrainVector` | 471 | `SUBROUTINE PH_Elem_S8_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_ELEM_S8_AreaInt` | 480 | `SUBROUTINE PH_ELEM_S8_AreaInt(coords, area)` |
| SUBROUTINE | `UF_Elem_S8_Calc` | 495 | `SUBROUTINE UF_Elem_S8_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |
| SUBROUTINE | `PH_Elem_S8_GetArea` | 570 | `SUBROUTINE PH_Elem_S8_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_S8_GetCentroid` | 576 | `SUBROUTINE PH_Elem_S8_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_S8_GetSectProps` | 604 | `SUBROUTINE PH_Elem_S8_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_S8_ApplyConstraint` | 615 | `SUBROUTINE PH_Elem_S8_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S8_ApplyMPC` | 628 | `SUBROUTINE PH_Elem_S8_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S8_FormContactContrib` | 646 | `SUBROUTINE PH_Elem_S8_FormContactContrib(edge_id, xi, eta, N, n, gap, penalty, edge_len, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S8_FormContactEdgeCtr` | 681 | `SUBROUTINE PH_Elem_S8_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S8_FormBodyForce` | 720 | `SUBROUTINE PH_Elem_S8_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_S8_FormEdgePressure` | 741 | `SUBROUTINE PH_Elem_S8_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S8_FormNodalForce` | 771 | `SUBROUTINE PH_Elem_S8_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S8_CollectIPVars` | 788 | `SUBROUTINE PH_Elem_S8_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_S8_EvalVonMises` | 803 | `SUBROUTINE PH_Elem_S8_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_S8_GetExtrapMat` | 816 | `SUBROUTINE PH_Elem_S8_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_S8_MapToNode` | 831 | `SUBROUTINE PH_Elem_S8_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_S8_Material_Update_Membrane_Routed` | 846 | `SUBROUTINE PH_Elem_S8_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
