# `RT_Mat_Aux_Def.f90`

- **Source**: `L5_RT/Material/RT_Mat_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Mat_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Mat_Aux_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Mat_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Material/RT_Mat_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mat_Stp_Ctl_Algo` (lines 38–60)

```fortran
  TYPE, PUBLIC :: RT_Mat_Stp_Ctl_Algo
    ! --- Dispatch strategy ---
    INTEGER(i4) :: dispatch_mode = RT_MAT_DISPATCH_DIRECT
    LOGICAL     :: error_on_dispatch_failure = .TRUE.   ! FATAL on route not found
    LOGICAL     :: elastic_fallback_on_failure = .FALSE. ! Use elastic as fallback

    ! --- NaN detection ---
    LOGICAL     :: nan_check_enabled = .TRUE.    ! Check NaN after material computation
    INTEGER(i4) :: nan_policy = RT_MAT_NAN_TRUNCATE_WARN  ! What to do on NaN

    ! --- Sub-incrementation control (L5 dispatch level) ---
    LOGICAL     :: sub_increment_enabled = .FALSE.  ! Enable L5-level sub-incrementation
    INTEGER(i4) :: max_sub_increments = 10_i4       ! Max sub-increments per IP
    REAL(wp)    :: sub_increment_tolerance = 1.0e-6_wp  ! Convergence tolerance

    ! --- Retry / divergence handling ---
    LOGICAL     :: retry_on_divergence = .FALSE.  ! Retry on divergent material
    INTEGER(i4) :: max_retries = 3_i4             ! Max retries per IP

    ! --- Override ---
    LOGICAL     :: force_dispatch = .FALSE.        ! Force dispatch even if route missing
    LOGICAL     :: suppress_material_update = .FALSE. ! Suppress all updates (debug)
  END TYPE RT_Mat_Stp_Ctl_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
