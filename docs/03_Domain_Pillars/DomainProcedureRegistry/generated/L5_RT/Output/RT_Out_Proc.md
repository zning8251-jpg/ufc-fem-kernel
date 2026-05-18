# `RT_Out_Proc.f90`

- **Source**: `L5_RT/Output/RT_Out_Proc.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Out_Proc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Out_Proc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Out`
- **第四段角色（四段式）**: `_Proc`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Output/RT_Out_Proc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Out_Init_In` (lines 53–73)

```fortran
  TYPE, PUBLIC :: RT_Out_Init_In
    ! Output descriptor (passed separately per six-parameter rule)
    ! TYPE(RT_Out_Desc), POINTER :: desc => NULL()
    
    ! Algorithm parameters (passed separately per six-parameter rule)
    ! TYPE(RT_Out), POINTER :: algo => NULL()
    
    ! Mesh information
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_dofs = 0_i4
    
    ! Options
    LOGICAL :: validate_requests = .TRUE.
    LOGICAL :: preallocate_buffers = .TRUE.
    
    ! Parallel context
    INTEGER(i4) :: n_threads = 1_i4
    INTEGER(i4) :: comm_rank = 0_i4
    INTEGER(i4) :: comm_size = 1_i4
  END TYPE RT_Out_Init_In
```

### `RT_Out_Init_Out` (lines 78–88)

```fortran
  TYPE, PUBLIC :: RT_Out_Init_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Diagnostics
    LOGICAL :: initialized = .FALSE.
    CHARACTER(LEN=256) :: message = ''
    INTEGER(i4) :: n_field_requests = 0_i4
    INTEGER(i4) :: n_hist_requests = 0_i4
    INTEGER(i4) :: buffer_memory_mb = 0_i4
  END TYPE RT_Out_Init_Out
```

### `RT_Out_Collect_In` (lines 95–114)

```fortran
  TYPE, PUBLIC :: RT_Out_Collect_In
    ! Output frame (modified in-place; passed separately)
    ! TYPE(RT_Out_Frame), POINTER :: frame => NULL()
    
    ! Context (passed separately)
    ! TYPE(RT_Out_Ctx), POINTER :: ctx => NULL()
    
    ! Solver state references (NON_OWNING_PTR)
    REAL(wp), POINTER :: node_coords(:,:) => NULL()   ! [3, n_nodes]
    REAL(wp), POINTER :: node_displ(:,:) => NULL()    ! [3, n_nodes]
    REAL(wp), POINTER :: node_velocity(:,:) => NULL() ! [3, n_nodes]
    REAL(wp), POINTER :: elem_stress(:,:) => NULL()   ! [6, n_elems]
    REAL(wp), POINTER :: elem_strain(:,:) => NULL()   ! [6, n_elems]
    INTEGER(i4), POINTER :: elem_conn(:,:) => NULL()  ! Connectivity
    
    ! Options
    LOGICAL :: collect_nodal = .TRUE.
    LOGICAL :: collect_elemental = .TRUE.
    LOGICAL :: collect_reactions = .FALSE.
  END TYPE RT_Out_Collect_In
```

### `RT_Out_Collect_Out` (lines 119–129)

```fortran
  TYPE, PUBLIC :: RT_Out_Collect_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Collection statistics
    INTEGER(i4) :: n_nodes_collected = 0_i4
    INTEGER(i4) :: n_elements_collected = 0_i4
    INTEGER(i4) :: n_variables_collected = 0_i4
    LOGICAL :: collection_complete = .FALSE.
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Out_Collect_Out
```

### `RT_Out_Write_In` (lines 136–161)

```fortran
  TYPE, PUBLIC :: RT_Out_Write_In
    ! Output state (modified in-place; passed separately)
    ! TYPE(RT_Out_FieldState), POINTER :: field_state => NULL()
    ! TYPE(RT_Out_HistState), POINTER :: hist_state => NULL()
    
    ! Output frame (passed separately)
    ! TYPE(RT_Out_Frame), POINTER :: frame => NULL()
    
    ! Context (passed separately)
    ! TYPE(RT_Out_Ctx), POINTER :: ctx => NULL()
    
    ! Descriptor (passed separately)
    ! TYPE(RT_Out_Desc), POINTER :: desc => NULL()
    
    ! Algorithm (passed separately)
    ! TYPE(RT_Out), POINTER :: algo => NULL()
    
    ! Options
    LOGICAL :: write_field = .TRUE.
    LOGICAL :: write_history = .FALSE.
    LOGICAL :: flush_buffer = .TRUE.
    
    ! File handles (if using external writers)
    INTEGER(i4) :: hdf5_file_id = -1_i4
    INTEGER(i4) :: odb_file_id = -1_i4
  END TYPE RT_Out_Write_In
```

### `RT_Out_Write_Out` (lines 166–180)

```fortran
  TYPE, PUBLIC :: RT_Out_Write_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Write statistics
    INTEGER(i4) :: n_frames_written = 0_i4
    INTEGER(i4) :: n_points_written = 0_i4
    INTEGER(i4) :: bytes_written = 0_i4
    REAL(wp) :: io_time_sec = 0.0_wp
    
    ! Diagnostics
    LOGICAL :: write_successful = .FALSE.
    CHARACTER(LEN=256) :: message = ''
    CHARACTER(LEN=256) :: output_file_path = ''
  END TYPE RT_Out_Write_Out
```

### `RT_Out_CheckFreq_In` (lines 187–201)

```fortran
  TYPE, PUBLIC :: RT_Out_CheckFreq_In
    ! State (modified in-place; passed separately)
    ! TYPE(RT_Out_FieldState), POINTER :: field_state => NULL()
    ! TYPE(RT_Out_HistState), POINTER :: hist_state => NULL()
    
    ! Algorithm (passed separately)
    ! TYPE(RT_Out), POINTER :: algo => NULL()
    
    ! Context (passed separately)
    ! TYPE(RT_Out_Ctx), POINTER :: ctx => NULL()
    
    ! Force flags
    LOGICAL :: force_field = .FALSE.
    LOGICAL :: force_hist = .FALSE.
  END TYPE RT_Out_CheckFreq_In
```

### `RT_Out_CheckFreq_Out` (lines 206–223)

```fortran
  TYPE, PUBLIC :: RT_Out_CheckFreq_Out
    ! Trigger results
    LOGICAL :: should_write_field = .FALSE.
    LOGICAL :: should_write_hist = .FALSE.
    
    ! Reason codes
    INTEGER(i4) :: field_trigger_reason = 0_i4  ! 0=None, 1=Incr, 2=Time, 3=StepEnd
    INTEGER(i4) :: hist_trigger_reason = 0_i4
    
    ! Next trigger prediction
    INTEGER(i4) :: next_field_incr = 0_i4
    REAL(wp) :: next_field_time = 0.0_wp
    INTEGER(i4) :: next_hist_incr = 0_i4
    REAL(wp) :: next_hist_time = 0.0_wp
    
    ! Status
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Out_CheckFreq_Out
```

### `RT_Out_Finalize_In` (lines 230–245)

```fortran
  TYPE, PUBLIC :: RT_Out_Finalize_In
    ! State (modified in-place; passed separately)
    ! TYPE(RT_Out_FieldState), POINTER :: field_state => NULL()
    ! TYPE(RT_Out_HistState), POINTER :: hist_state => NULL()
    
    ! Descriptor (passed separately)
    ! TYPE(RT_Out_Desc), POINTER :: desc => NULL()
    
    ! Algorithm (passed separately)
    ! TYPE(RT_Out), POINTER :: algo => NULL()
    
    ! Options
    LOGICAL :: close_files = .TRUE.
    LOGICAL :: flush_buffers = .TRUE.
    LOGICAL :: write_summary = .TRUE.
  END TYPE RT_Out_Finalize_In
```

### `RT_Out_Finalize_Out` (lines 250–264)

```fortran
  TYPE, PUBLIC :: RT_Out_Finalize_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Summary statistics
    INTEGER(i4) :: total_frames_written = 0_i4
    INTEGER(i4) :: total_points_written = 0_i4
    INTEGER(i4) :: total_bytes_written = 0_i4
    REAL(wp) :: total_io_time_sec = 0.0_wp
    
    ! Diagnostics
    LOGICAL :: finalized = .FALSE.
    CHARACTER(LEN=256) :: summary_message = ''
    CHARACTER(LEN=256) :: final_output_path = ''
  END TYPE RT_Out_Finalize_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Out_Init` | 271 | `SUBROUTINE RT_Out_Init(input, output)` |
| SUBROUTINE | `RT_Out_Collect` | 279 | `SUBROUTINE RT_Out_Collect(input, output)` |
| SUBROUTINE | `RT_Out_Write` | 287 | `SUBROUTINE RT_Out_Write(input, output)` |
| SUBROUTINE | `RT_Out_CheckFreq` | 295 | `SUBROUTINE RT_Out_CheckFreq(input, output)` |
| SUBROUTINE | `RT_Out_Finalize` | 303 | `SUBROUTINE RT_Out_Finalize(input, output)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
