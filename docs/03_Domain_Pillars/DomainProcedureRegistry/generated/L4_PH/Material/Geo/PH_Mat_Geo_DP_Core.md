# `PH_Mat_Geo_DP_Core.f90`

- **Source**: `L4_PH/Material/Geo/PH_Mat_Geo_DP_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Geo_DP_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Geo_DP_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Geo_DP`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Geo`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Geo/PH_Mat_Geo_DP_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_DP_Init_Arg` (lines 56–58)

```fortran
  TYPE, PUBLIC :: PH_Mat_DP_Init_Arg
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_DP_Init_Arg
```

### `PH_Mat_DP_Update_Arg` (lines 60–64)

```fortran
  TYPE, PUBLIC :: PH_Mat_DP_Update_Arg
    LOGICAL :: request_consistent_tangent = .TRUE.
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: local_iters = 0_i4
  END TYPE PH_Mat_DP_Update_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Geo_DP_Core_Init` | 68 | `SUBROUTINE PH_Mat_Geo_DP_Core_Init(desc, state, algo, ctx, args)` |
| SUBROUTINE | `PH_Mat_Geo_DP_Core_Update` | 100 | `SUBROUTINE PH_Mat_Geo_DP_Core_Update(desc, state, algo, ctx, args)` |
| SUBROUTINE | `PLM_DP_Build_D_el` | 183 | `SUBROUTINE PLM_DP_Build_D_el(E, nu, D)` |
| SUBROUTINE | `PLM_DP_Deviator_q_p` | 208 | `PURE SUBROUTINE PLM_DP_Deviator_q_p(sig, ntens, s_dev, q_out, p_comp)` |
| FUNCTION | `PLM_DP_Yield_value` | 234 | `PURE FUNCTION PLM_DP_Yield_value(q, p_comp, d_c, tan_beta) RESULT(f)` |
| SUBROUTINE | `PLM_DP_Potential_grad` | 241 | `PURE SUBROUTINE PLM_DP_Potential_grad(s_dev, q, tan_ang, ntens, grad)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
