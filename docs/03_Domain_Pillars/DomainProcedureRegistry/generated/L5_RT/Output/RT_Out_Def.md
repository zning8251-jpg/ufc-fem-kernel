# `RT_Out_Def.f90`

- **Source**: `L5_RT/Output/RT_Out_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Out_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Out_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Out`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Output/RT_Out_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Out_Desc` (lines 80–97)

```fortran
  TYPE, PUBLIC :: RT_Out_Desc
    INTEGER(i4) :: runtime_id = 0_i4           ! Runtime instance ID
    CHARACTER(LEN=64) :: output_label = ''     ! Output request label
    
    ! Reference to L3_MD descriptors
    TYPE(MD_Output_Registry), POINTER :: md_registry => NULL()
    TYPE(MD_FieldOut_Desc), POINTER :: field_req => NULL()
    TYPE(MD_HistOut_Desc), POINTER :: hist_req => NULL()
    
    ! Runtime caching
    INTEGER(i4) :: output_format = RT_OUT_FMT_VTK
    CHARACTER(LEN=256) :: output_directory = './output/'
    CHARACTER(LEN=64) :: file_prefix = 'UFC'
    
    ! Status flags
    LOGICAL :: is_active = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  END TYPE RT_Out_Desc
```

### `RT_Out_FieldState` (lines 104–131)

```fortran
  TYPE, PUBLIC :: RT_Out_FieldState
    ! Frame counters
    INTEGER(i4) :: n_frames_written = 0_i4     ! Total frames written
    INTEGER(i4) :: n_frames_current_step = 0_i4 ! Frames in current step
    INTEGER(i4) :: n_frames_max = 0_i4         ! Max frames (0=unlimited)
    
    ! Time tracking
    REAL(wp) :: time_last_written = 0.0_wp     ! Time of last frame
    REAL(wp) :: time_next_due = 0.0_wp         ! Next scheduled write time
    
    ! Increment tracking
    INTEGER(i4) :: inc_last_written = 0_i4
    INTEGER(i4) :: inc_interval = 1_i4         ! Write every N increments
    
    ! Buffer status
    LOGICAL :: buffer_active = .FALSE.
    INTEGER(i4) :: buffer_frame_count = 0_i4
    INTEGER(i4) :: buffer_max_frames = 10_i4
    
    ! Suppression flags
    LOGICAL :: suppress_this_inc = .FALSE.
    LOGICAL :: write_pending = .FALSE.
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reset
    PROCEDURE :: CheckTrigger
  END TYPE RT_Out_FieldState
```

### `RT_Out_HistState` (lines 137–160)

```fortran
  TYPE, PUBLIC :: RT_Out_HistState
    ! Point counters
    INTEGER(i4) :: n_points_written = 0_i4     ! Total data points
    INTEGER(i4) :: n_points_current_step = 0_i4
    
    ! Time tracking
    REAL(wp) :: time_last_written = 0.0_wp
    REAL(wp) :: time_next_due = 0.0_wp
    REAL(wp) :: time_interval = 0.0_wp         ! Write every Δt
    
    ! Variable tracking
    INTEGER(i4) :: n_variables = 0_i4
    REAL(wp), ALLOCATABLE :: data_buffer(:,:)  ! [time, values]
    
    ! Buffer status
    LOGICAL :: buffer_active = .FALSE.
    INTEGER(i4) :: buffer_point_count = 0_i4
    INTEGER(i4) :: buffer_max_points = 100_i4
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reset
    PROCEDURE :: AddPoint
  END TYPE RT_Out_HistState
```

### `RT_Out` (lines 169–197)

```fortran
  TYPE, PUBLIC :: RT_Out
    !-- P1 sub-Algo composition --
    TYPE(RT_Out_Stp_Ctl_Algo) :: stp_ctl    ! [Phase:Stp|Verb:Ctl] frequency/trigger
    TYPE(RT_Out_Itr_Algo)     :: itr_algo   ! [Phase:Itr|Verb:Com] buffer/compression/IO

    !-- Legacy flat fields (use stp_ctl / itr_algo for new code) --
    INTEGER(i4) :: field_freq_incr = 1_i4      ! (legacy, use stp_ctl%field_freq_incr)
    INTEGER(i4) :: hist_freq_incr = 1_i4       ! (legacy, use stp_ctl%hist_freq_incr)
    REAL(wp) :: field_freq_time = 0.0_wp       ! (legacy, use stp_ctl%field_freq_time)
    REAL(wp) :: hist_freq_time = 0.0_wp        ! (legacy, use stp_ctl%hist_freq_time)
    INTEGER(i4) :: trigger_type = RT_OUT_TRIG_INCREMENT  ! (legacy, use stp_ctl%trigger_type)
    LOGICAL :: trigger_at_step_end = .TRUE.     ! (legacy, use stp_ctl%trigger_at_step_end)
    LOGICAL :: trigger_at_analysis_end = .TRUE. ! (legacy, use stp_ctl%trigger_at_analysis_end)
    LOGICAL :: use_field_buffer = .TRUE.        ! (legacy, use itr_algo%use_field_buffer)
    LOGICAL :: use_hist_buffer = .TRUE.         ! (legacy, use itr_algo%use_hist_buffer)
    INTEGER(i4) :: field_buffer_size = 10_i4   ! (legacy, use itr_algo%field_buffer_size)
    INTEGER(i4) :: hist_buffer_size = 100_i4   ! (legacy, use itr_algo%hist_buffer_size)
    INTEGER(i4) :: flush_frequency = 5_i4      ! (legacy, use itr_algo%flush_frequency)
    LOGICAL :: compress_output = .FALSE.        ! (legacy, use itr_algo%compress_output)
    LOGICAL :: split_by_step = .FALSE.         ! (legacy, use itr_algo%split_by_step)
    INTEGER(i4) :: max_file_size_mb = 0_i4     ! (legacy, use itr_algo%max_file_size_mb)
    LOGICAL :: use_parallel_io = .FALSE.        ! (legacy, use itr_algo%use_parallel_io)
    INTEGER(i4) :: io_comm_rank = 0_i4         ! (legacy, use itr_algo%io_comm_rank)
    INTEGER(i4) :: io_comm_size = 1_i4         ! (legacy, use itr_algo%io_comm_size)

  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetFrequency
  END TYPE RT_Out
```

### `RT_Out_Algo` (lines 207–209)

```fortran
  TYPE, PUBLIC :: RT_Out_Algo
    TYPE(RT_Out), POINTER :: inner => NULL()
  END TYPE RT_Out_Algo
```

### `RT_Out_Ctx` (lines 215–245)

```fortran
  TYPE, PUBLIC :: RT_Out_Ctx
    ! Current analysis state
    INTEGER(i4) :: step_id = 0_i4
    INTEGER(i4) :: incr_id = 0_i4
    INTEGER(i4) :: iter_id = 0_i4
    
    ! Time quantities
    REAL(wp) :: step_time = 0.0_wp
    REAL(wp) :: total_time = 0.0_wp
    REAL(wp) :: time_increment = 0.0_wp
    
    ! Step boundaries
    LOGICAL :: is_first_incr = .FALSE.
    LOGICAL :: is_last_incr = .FALSE.
    LOGICAL :: is_step_end = .FALSE.
    LOGICAL :: is_analysis_end = .FALSE.
    
    ! Mesh state references
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_dofs = 0_i4
    
    ! Force flags
    LOGICAL :: force_field_write = .FALSE.     ! Override frequency check
    LOGICAL :: force_hist_write = .FALSE.
    LOGICAL :: suppress_all_output = .FALSE.
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Update
  END TYPE RT_Out_Ctx
```

### `RT_Out_Frame` (lines 251–291)

```fortran
  TYPE, PUBLIC :: RT_Out_Frame
    ! Metadata
    INTEGER(i4) :: step_id = 0_i4
    INTEGER(i4) :: incr_id = 0_i4
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: dt = 0.0_wp
    
    ! Mesh topology
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    
    ! Nodal data (continuous memory layout)
    REAL(wp), ALLOCATABLE :: node_coords(:,:)  ! [3, n_nodes]
    REAL(wp), ALLOCATABLE :: node_displ(:,:)   ! [3, n_nodes]
    REAL(wp), ALLOCATABLE :: node_velocity(:,:)! [3, n_nodes]
    REAL(wp), ALLOCATABLE :: node_accel(:,:)   ! [3, n_nodes]
    REAL(wp), ALLOCATABLE :: node_temp(:)      ! [n_nodes]
    REAL(wp), ALLOCATABLE :: node_reaction(:,:)! [6, n_nodes]
    
    ! Element data
    INTEGER(i4), ALLOCATABLE :: elem_conn(:,:) ! [max_nodes, n_elems]
    REAL(wp), ALLOCATABLE :: elem_stress(:,:)  ! [6, n_elems]
    REAL(wp), ALLOCATABLE :: elem_strain(:,:)  ! [6, n_elems]
    REAL(wp), ALLOCATABLE :: elem_energy(:)    ! [n_elems]
    REAL(wp), ALLOCATABLE :: elem_statev(:,:)  ! [n_statev, n_elems]
    
    ! Field variables (generic)
    INTEGER(i4) :: n_field_vars = 0_i4
    CHARACTER(LEN=64), ALLOCATABLE :: field_var_names(:)
    REAL(wp), ALLOCATABLE :: field_var_data(:,:)
    
    ! Status
    LOGICAL :: is_valid = .FALSE.
    LOGICAL :: coords_updated = .FALSE.
    LOGICAL :: displ_updated = .FALSE.
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Allocate
    PROCEDURE :: Clear
  END TYPE RT_Out_Frame
```

### `RT_Out_Buffer` (lines 297–315)

```fortran
  TYPE, PUBLIC :: RT_Out_Buffer
    INTEGER(i4) :: capacity = 0_i4
    INTEGER(i4) :: size = 0_i4
    INTEGER(i4) :: head = 0_i4
    INTEGER(i4) :: tail = 0_i4
    
    REAL(wp), ALLOCATABLE :: data(:)
    INTEGER(i4), ALLOCATABLE :: indices(:)
    
    LOGICAL :: is_full = .FALSE.
    LOGICAL :: needs_flush = .FALSE.
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Push
    PROCEDURE :: Pop
    PROCEDURE :: Flush
    PROCEDURE :: Clear
  END TYPE RT_Out_Buffer
```

### `RT_Out_TriggerCtx` (lines 321–368)

```fortran
  TYPE, PUBLIC :: RT_Out_TriggerCtx
    INTEGER(i4) :: trigger_type = RT_OUT_TRIG_INCREMENT
    
    ! Current state
    INTEGER(i4) :: curr_incr = 0_i4
    REAL(wp) :: curr_time = 0.0_wp
    
    ! Last trigger state
    INTEGER(i4) :: last_triggered_incr = 0_i4
    REAL(wp) :: last_triggered_time = 0.0_wp
    
    ! Configuration
    INTEGER(i4) :: incr_interval = 1_i4
    REAL(wp) :: time_interval = 0.0_wp
    
  CONTAINS
    FUNCTION ShouldTrigger(self) RESULT(trigger)
      LOGICAL :: trigger
      CLASS(RT_Out_TriggerCtx), INTENT(INOUT) :: self
      
      trigger = .FALSE.
      
      SELECT CASE (self%trigger_type)
      CASE (RT_OUT_TRIG_INCREMENT)
        IF (MOD(self%curr_incr, self%incr_interval) == 0) THEN
          trigger = .TRUE.
        END IF
        
      CASE (RT_OUT_TRIG_TIME)
        IF (self%time_interval > 0.0_wp) THEN
          IF (self%curr_time >= self%last_triggered_time + self%time_interval) THEN
            trigger = .TRUE.
          END IF
        END IF
        
      CASE (RT_OUT_TRIG_STEP_END)
        trigger = .TRUE.  ! Evaluated externally
        
      CASE DEFAULT
        trigger = .FALSE.
      END SELECT
      
      IF (trigger) THEN
        self%last_triggered_incr = self%curr_incr
        self%last_triggered_time = self%curr_time
      END IF
    END FUNCTION ShouldTrigger
  END TYPE RT_Out_TriggerCtx
```

### `RT_Out_Init_Arg` (lines 657–671)

```fortran
TYPE, PUBLIC :: RT_Out_Init_Arg
  ! [IN] configuration
  TYPE(RT_Out_Desc) :: desc              ! [IN]  output descriptor
  TYPE(RT_Out_FieldState) :: field_state ! [INOUT] field output state
  TYPE(RT_Out_HistState) :: hist_state   ! [INOUT] history output state
  TYPE(RT_Out_Ctx) :: ctx               ! [INOUT] output context

  ! [IN] initialization
  INTEGER(i4) :: output_type            ! [IN]  0=field, 1=history, 2=batch
  INTEGER(i4) :: max_buffer             ! [IN]  max buffer frames

  ! [OUT] init results
  INTEGER(i4) :: status_code            ! [OUT] init status
  CHARACTER(len=256) :: message         ! [OUT] status message
END TYPE RT_Out_Init_Arg
```

### `RT_Out_Write_Arg` (lines 676–692)

```fortran
TYPE, PUBLIC :: RT_Out_Write_Arg
  ! [IN] output state
  TYPE(RT_Out_Desc) :: desc              ! [IN]  output descriptor
  TYPE(RT_Out_FieldState) :: field_state ! [INOUT] field output state
  TYPE(RT_Out_HistState) :: hist_state   ! [INOUT] history output state
  TYPE(RT_Out_Ctx) :: ctx               ! [INOUT] output context

  ! [IN] data
  REAL(wp), ALLOCATABLE :: field_values(:,:) ! [IN]  field data to write
  REAL(wp), ALLOCATABLE :: hist_values(:)    ! [IN]  history data to write
  INTEGER(i4) :: n_saved               ! [OUT] number of values saved

  ! [OUT] write results
  INTEGER(i4) :: bytes_written          ! [OUT] bytes written
  INTEGER(i4) :: status_code            ! [OUT] write status
  CHARACTER(len=256) :: message         ! [OUT] status message
END TYPE RT_Out_Write_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `FieldState_Init` | 376 | `SUBROUTINE FieldState_Init(self, incr_interval, max_frames)` |
| SUBROUTINE | `FieldState_Reset` | 394 | `SUBROUTINE FieldState_Reset(self)` |
| FUNCTION | `FieldState_CheckTrigger` | 404 | `FUNCTION FieldState_CheckTrigger(self, curr_incr, curr_time) RESULT(trigger)` |
| SUBROUTINE | `HistState_Init` | 440 | `SUBROUTINE HistState_Init(self, n_vars, buffer_size)` |
| SUBROUTINE | `HistState_Reset` | 460 | `SUBROUTINE HistState_Reset(self)` |
| SUBROUTINE | `HistState_AddPoint` | 469 | `SUBROUTINE HistState_AddPoint(self, time, values)` |
| SUBROUTINE | `OutAlgo_Init` | 483 | `SUBROUTINE OutAlgo_Init(self)` |
| SUBROUTINE | `OutAlgo_SetFreq` | 496 | `SUBROUTINE OutAlgo_SetFreq(self, field_incr, hist_incr, field_time, hist_time)` |
| SUBROUTINE | `OutCtx_Init` | 511 | `SUBROUTINE OutCtx_Init(self)` |
| SUBROUTINE | `OutCtx_Update` | 524 | `SUBROUTINE OutCtx_Update(self, step, incr, time, dt)` |
| SUBROUTINE | `OutFrame_Init` | 542 | `SUBROUTINE OutFrame_Init(self)` |
| SUBROUTINE | `OutFrame_Allocate` | 547 | `SUBROUTINE OutFrame_Allocate(self, n_nodes, n_elements)` |
| SUBROUTINE | `OutFrame_Clear` | 565 | `SUBROUTINE OutFrame_Clear(self)` |
| SUBROUTINE | `OutBuffer_Init` | 580 | `SUBROUTINE OutBuffer_Init(self, capacity)` |
| SUBROUTINE | `OutBuffer_Push` | 595 | `SUBROUTINE OutBuffer_Push(self, value, index)` |
| FUNCTION | `OutBuffer_Pop` | 615 | `FUNCTION OutBuffer_Pop(self) RESULT(value)` |
| SUBROUTINE | `OutBuffer_Flush` | 631 | `SUBROUTINE OutBuffer_Flush(self)` |
| SUBROUTINE | `OutBuffer_Clear` | 641 | `SUBROUTINE OutBuffer_Clear(self)` |

## Procedures detected inside TYPE bodies

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `ShouldTrigger` | 337 | `FUNCTION ShouldTrigger(self) RESULT(trigger)` |

## INTERFACE blocks (outline)

*(none)*
