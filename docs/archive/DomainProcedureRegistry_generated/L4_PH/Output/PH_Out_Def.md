# `PH_Out_Def.f90`

- **Source**: `L4_PH/Output/PH_Out_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Out_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Out_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Out`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Output/PH_Out_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Out_Desc` (lines 55–64)

```fortran
  TYPE, PUBLIC :: PH_Out_Desc
    INTEGER(i4) :: output_format    = PH_OUT_VTK     ! VTK/HDF5/ODB/BINARY
    INTEGER(i4) :: n_field_vars     = 0_i4           ! Number of active field variables
    INTEGER(i4) :: n_history_vars   = 0_i4           ! Number of active history vars
    INTEGER(i4) :: write_frequency  = 1_i4           ! Every N increments
    LOGICAL     :: output_at_end    = .TRUE.         ! Force output at step end
    LOGICAL     :: output_initial    = .FALSE.        ! Write initial state
    CHARACTER(LEN=64) :: coordinate_system = "GLOBAL" ! GLOBAL/LOCAL/CYLINDRICAL
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_Desc
```

### `PH_Out_State` (lines 71–78)

```fortran
  TYPE, PUBLIC :: PH_Out_State
    INTEGER(i4) :: last_write_step  = 0_i4           ! Step of last write
    INTEGER(i4) :: last_write_inc   = 0_i4           ! Increment of last write
    INTEGER(i4) :: frame_count      = 0_i4           ! Total frames written
    REAL(wp)    :: last_write_time  = 0.0_wp         ! Time of last write
    LOGICAL     :: buffer_dirty     = .FALSE.        ! Buffer contains unwritten data
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_State
```

### `PH_Out_Algo` (lines 85–91)

```fortran
  TYPE, PUBLIC :: PH_Out_Algo
    INTEGER(i4) :: transform_method    = 1_i4        ! 1=direct, 2=rotation_matrix
    INTEGER(i4) :: interpolation_order  = 1_i4       ! 1=linear, 2=quadratic
    LOGICAL     :: extrapolate_boundary = .FALSE.    ! Extrapolate at boundaries
    REAL(wp)    :: extrapolation_limit  = 0.1_wp     ! Max extrapolation fraction
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_Algo
```

### `PH_Out_Ctx` (lines 98–105)

```fortran
  TYPE, PUBLIC :: PH_Out_Ctx
    INTEGER(i4) :: current_frame_id   = 0_i4
    INTEGER(i4) :: current_step_id    = 0_i4
    INTEGER(i4) :: current_inc_id     = 0_i4
    REAL(wp)    :: current_time       = 0.0_wp
    LOGICAL     :: is_triggered       = .FALSE.      ! Output triggered at this inc
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_Ctx
```

### `PH_Out_Arg` (lines 111–119)

```fortran
  TYPE, PUBLIC :: PH_Out_Arg
    TYPE(PH_Out_Desc)  :: desc     ! [IN]  output configuration
    TYPE(PH_Out_State) :: state    ! [INOUT] output state
    TYPE(PH_Out_Algo)  :: algo     ! [IN]  algorithm strategy
    TYPE(PH_Out_Ctx)   :: ctx      ! [IN]  current context
    INTEGER(i4)        :: n_values = 0_i4     ! [IN]  number of values to process
    REAL(wp), ALLOCATABLE :: buffer(:)        ! [OUT] output data buffer
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Out_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
