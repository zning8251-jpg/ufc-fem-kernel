# `PH_Elem_S3.f90`

- **Source**: `L4_PH/Element/Shell/PH_Elem_S3.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_S3`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_S3`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_S3`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Shell`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Shell/PH_Elem_S3.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_S3_StiffMatrix_Arg` (lines 95–97)

```fortran
  TYPE, PUBLIC :: PH_Elem_S3_StiffMatrix_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S3_StiffMatrix_Arg
```

### `PH_Elem_S3_IntForce_Arg` (lines 103–105)

```fortran
  TYPE, PUBLIC :: PH_Elem_S3_IntForce_Arg
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S3_IntForce_Arg
```

### `PH_Elem_S3_NL_TL_Arg` (lines 111–116)

```fortran
  TYPE, PUBLIC :: PH_Elem_S3_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    REAL(wp) :: thickness  ! Shell thickness (Desc)                   ! [IN]
    INTEGER(i4) :: n_layers  ! Number of through-thickness integration layers (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S3_NL_TL_Arg
```

### `PH_Elem_S3_NL_UL_Arg` (lines 122–127)

```fortran
  TYPE, PUBLIC :: PH_Elem_S3_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    REAL(wp) :: thickness  ! Shell thickness (Desc)                   ! [IN]
    INTEGER(i4) :: n_layers  ! Number of through-thickness integration layers (Algo)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_S3_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_S3_ConsMass` | 132 | `SUBROUTINE PH_Elem_S3_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_S3_DefInit` | 147 | `SUBROUTINE PH_Elem_S3_DefInit()` |
| SUBROUTINE | `PH_Elem_S3_FormIntForce` | 150 | `SUBROUTINE PH_Elem_S3_FormIntForce(arg)` |
| SUBROUTINE | `PH_Elem_S3_FormIntForce_Legacy` | 177 | `SUBROUTINE PH_Elem_S3_FormIntForce_Legacy(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_S3_FormStiffMatrix` | 192 | `SUBROUTINE PH_Elem_S3_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_S3_FormStiffMatrix_Legacy` | 216 | `SUBROUTINE PH_Elem_S3_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_S3_LumpMass` | 229 | `SUBROUTINE PH_Elem_S3_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_S3_NL_TL` | 243 | `SUBROUTINE PH_Elem_S3_NL_TL(arg)` |
| SUBROUTINE | `Invert2x2` | 393 | `SUBROUTINE Invert2x2(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_S3_NL_TL_Legacy` | 408 | `SUBROUTINE PH_Elem_S3_NL_TL_Legacy(coords_ref, u_elem, mat_prop, mat_state, thickness, n_layers, &` |
| SUBROUTINE | `PH_Elem_S3_NL_UL` | 437 | `SUBROUTINE PH_Elem_S3_NL_UL(arg)` |
| SUBROUTINE | `Invert2x2` | 602 | `SUBROUTINE Invert2x2(A, A_inv, det)` |
| SUBROUTINE | `PH_Elem_S3_NL_UL_Legacy` | 617 | `SUBROUTINE PH_Elem_S3_NL_UL_Legacy(coords_prev, u_incr, mat_prop, mat_state, thickness, n_layers, &` |
| SUBROUTINE | `PH_Elem_S3_ThermStrainVector` | 644 | `SUBROUTINE PH_Elem_S3_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_ELEM_S3_AreaInt` | 653 | `SUBROUTINE PH_ELEM_S3_AreaInt(coords, area)` |
| SUBROUTINE | `UF_Elem_S3_Calc` | 668 | `SUBROUTINE UF_Elem_S3_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PH_Elem_S3_GetArea` | 765 | `SUBROUTINE PH_Elem_S3_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_S3_GetCentroid` | 771 | `SUBROUTINE PH_Elem_S3_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_S3_GetSectProps` | 799 | `SUBROUTINE PH_Elem_S3_GetSectProps(coords, density_in, area, mass)` |
| SUBROUTINE | `PH_Elem_S3_ApplyConstraint` | 810 | `SUBROUTINE PH_Elem_S3_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S3_ApplyMPC` | 823 | `SUBROUTINE PH_Elem_S3_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_ELEM_S3_CrossProduct` | 841 | `SUBROUTINE PH_ELEM_S3_CrossProduct(a, b, c)` |
| SUBROUTINE | `PH_Elem_S3_FormContactContrib` | 849 | `SUBROUTINE PH_Elem_S3_FormContactContrib(coords, gap_field, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S3_FormContactEdgeCtr` | 863 | `SUBROUTINE PH_Elem_S3_FormContactEdgeCtr(edge_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_S3_FormBodyForce` | 898 | `SUBROUTINE PH_Elem_S3_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_S3_FormEdgePressure` | 919 | `SUBROUTINE PH_Elem_S3_FormEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S3_FormNodalForce` | 949 | `SUBROUTINE PH_Elem_S3_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_S3_CollectIPVars` | 966 | `SUBROUTINE PH_Elem_S3_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_S3_EvalVonMises` | 981 | `SUBROUTINE PH_Elem_S3_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_S3_GetExtrapMat` | 994 | `SUBROUTINE PH_Elem_S3_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_S3_MapToNode` | 1009 | `SUBROUTINE PH_Elem_S3_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_S3_Material_Update_Membrane_Routed` | 1024 | `SUBROUTINE PH_Elem_S3_Material_Update_Membrane_Routed(rt_ctx, mat_slot, dstrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
