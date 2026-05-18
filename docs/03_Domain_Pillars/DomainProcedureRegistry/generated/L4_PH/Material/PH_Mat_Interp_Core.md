# `PH_Mat_Interp_Core.f90`

- **Source**: `L4_PH/Material/PH_Mat_Interp_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Interp_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Interp_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Interp`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/PH_Mat_Interp_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Interp_Ctx` (lines 39–58)

```fortran
  TYPE, PUBLIC :: PH_Mat_Interp_Ctx
    ! Interpolation method
    INTEGER(i4) :: interp_method = PH_MAT_INTERP_LINEAR

    ! Cache (avoid repeated interpolation)
    INTEGER(i4) :: last_interval = -1
    REAL(wp) :: last_temperature = -999.0_wp
    ! TYPE-003: cache buffers are POINTER targets (Init allocates; no ALLOCATABLE in *Ctx)
    REAL(wp), DIMENSION(:), POINTER :: last_props => NULL()

    ! Spline interpolation coefficients (if using spline)
    REAL(wp), DIMENSION(:, :), POINTER :: spline_coeffs => NULL()

    ! Statistics
    INTEGER(i4) :: num_interpolations = 0
    INTEGER(i4) :: num_cache_hits = 0

    ! Initialization flag
    LOGICAL :: initialized = .FALSE.
  END TYPE PH_Mat_Interp_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Interp_Init` | 74 | `SUBROUTINE PH_Mat_Interp_Init(ctx, num_props, interp_method, status)` |
| SUBROUTINE | `PH_Mat_Interp_Finalize` | 114 | `SUBROUTINE PH_Mat_Interp_Finalize(ctx, status)` |
| SUBROUTINE | `PH_Mat_Interpolate_Props` | 140 | `SUBROUTINE PH_Mat_Interpolate_Props(props_table, temp_points, temperature, &` |
| SUBROUTINE | `Find_Interval` | 242 | `SUBROUTINE Find_Interval(temp_points, temperature, i_low, i_high, status)` |
| SUBROUTINE | `PH_Mat_Interp_Get_Stats` | 299 | `SUBROUTINE PH_Mat_Interp_Get_Stats(ctx, num_interps, num_hits, hit_rate)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
