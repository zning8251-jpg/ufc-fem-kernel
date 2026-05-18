# `RT_Out_Aux_Def.f90`

- **Source**: `L5_RT/Output/RT_Out_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Out_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Out_Aux_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Out_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Output/RT_Out_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Out_Stp_Ctl_Algo` (lines 26–44)

```fortran
  TYPE, PUBLIC :: RT_Out_Stp_Ctl_Algo
    ! --- Field frequency ---
    INTEGER(i4) :: field_freq_incr = 1_i4      ! Field output every N increments
    REAL(wp)    :: field_freq_time = 0.0_wp     ! Field output time interval (0=off)

    ! --- History frequency ---
    INTEGER(i4) :: hist_freq_incr  = 1_i4       ! History output every N increments
    REAL(wp)    :: hist_freq_time  = 0.0_wp     ! History output time interval

    ! --- Trigger configuration ---
    INTEGER(i4) :: trigger_type          = RT_OUT_TRIG_INCREMENT
    LOGICAL     :: trigger_at_step_end   = .TRUE.    ! Always write at step end
    LOGICAL     :: trigger_at_analysis_end = .TRUE.  ! Always write at analysis end

    ! --- Last-chance / override ---
    LOGICAL     :: force_field_write     = .FALSE.   ! Override frequency check
    LOGICAL     :: force_hist_write      = .FALSE.   ! Override frequency check
    LOGICAL     :: suppress_all_output   = .FALSE.   ! Suppress all output
  END TYPE RT_Out_Stp_Ctl_Algo
```

### `RT_Out_Itr_Algo` (lines 54–71)

```fortran
  TYPE, PUBLIC :: RT_Out_Itr_Algo
    ! --- Buffer control ---
    LOGICAL     :: use_field_buffer   = .TRUE.     ! Enable field buffering
    LOGICAL     :: use_hist_buffer    = .TRUE.     ! Enable history buffering
    INTEGER(i4) :: field_buffer_size  = 10_i4      ! Max frames in field buffer
    INTEGER(i4) :: hist_buffer_size   = 100_i4     ! Max points in history buffer
    INTEGER(i4) :: flush_frequency    = 5_i4       ! Flush buffer every N writes

    ! --- File management ---
    LOGICAL     :: compress_output    = .FALSE.    ! Compress output files
    LOGICAL     :: split_by_step      = .FALSE.    ! Separate file per step
    INTEGER(i4) :: max_file_size_mb   = 0_i4       ! 0 = unlimited

    ! --- Parallel I/O ---
    LOGICAL     :: use_parallel_io    = .FALSE.    ! Enable parallel I/O
    INTEGER(i4) :: io_comm_rank       = 0_i4       ! MPI rank for I/O
    INTEGER(i4) :: io_comm_size       = 1_i4       ! MPI communicator size
  END TYPE RT_Out_Itr_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
