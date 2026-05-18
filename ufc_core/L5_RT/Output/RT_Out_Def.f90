!======================================================================
! Module: RT_Out_Def
! Layer:  L5_RT - Runtime Layer
! Domain: Output / Type Definitions
! Purpose: Four-type system (Desc/State/Algo/Ctx) for output runtime.
!          AUTHORITY for L5 Output four-type definitions.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: ACTIVE | AUTHORITY | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output
!   L3: MD_Output (output request schema definer)
!   L4: PH_Out (physics-level coordinate/tensor transforms)
!   L5: RT_Output (runtime output orchestration) -- THIS MODULE is the AUTHORITY
!   LEGACY wrapper: RT_Output_Def.f90 (minimal legacy types, do not extend)
!   Golden Path:    RT_Out.f90 (production orchestration module)
!======================================================================
!   3. Four-Type System: Desc/State/Algo/Ctx separation for clarity
!   4. Performance: Buffer-based I/O for efficiency
!
! Type Catalogue:
!   - RT_Out_Desc: Runtime output descriptor
!   - RT_Out_FieldState: Field output execution state
!   - RT_Out_HistState: History output execution state
!   - RT_Out: Output algorithm control parameters
!   - RT_Out_Ctx: Per-call output context
!   - RT_Out_Frame: Output frame buffer for one increment
!   - RT_Out_Buffer: Circular buffer for batched writes
!
! Layer Dependency:
!   USE IF_Prec              (wp, i4)
!   USE MD_Out_Def      (L3_MD output requests)
!   USE MD_Step_Def        (L3_MD step definitions)
!===============================================================================
MODULE RT_Out_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Out_Def, ONLY: MD_Output_Registry, MD_FieldOut_Desc, MD_HistOut_Desc
  USE RT_Out_Aux_Def, ONLY: RT_Out_Stp_Ctl_Algo, RT_Out_Itr_Algo
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Out_Desc
  PUBLIC :: RT_Out_FieldState
  PUBLIC :: RT_Out_HistState
  PUBLIC :: RT_Out
  PUBLIC :: RT_Out_Algo
  PUBLIC :: RT_Out_Ctx
  PUBLIC :: RT_Out_Frame
  PUBLIC :: RT_Out_Buffer
  PUBLIC :: RT_Out_TriggerCtx
  PUBLIC :: RT_Out_Init_Arg
  PUBLIC :: RT_Out_Write_Arg
  
  !-- Output format constants (synchronized with RT_Writer_XXX)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_FMT_VTK = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_FMT_HDF5 = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_FMT_ODB = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_FMT_ASCII = 4_i4
  
  !-- Trigger type constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_INCREMENT = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_TIME = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_STEP_END = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_ANALYSIS_END = 3_i4
  
  !-- Variable position constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_POS_INTEGRATION_PT = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_POS_NODE = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_POS_ELEMENT = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_POS_WHOLE_MODEL = 4_i4
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Desc — Runtime Output Descriptor (R-09 canonical name)
  !   Aggregates L3_MD output requests with runtime metadata
  !   Replaces RT_Out_Base_Desc (R-09).
  !-----------------------------------------------------------------------------
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

  
  !-----------------------------------------------------------------------------
  ! RT_Out_FieldState ?Field Output Execution State
  !   Tracks field output (frame-based) write progress
  !-----------------------------------------------------------------------------
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
  
  !-----------------------------------------------------------------------------
  ! RT_Out_HistState ?History Output Execution State
  !   Tracks history output (xy-data) accumulation
  !-----------------------------------------------------------------------------
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
  
  !-----------------------------------------------------------------------------
  ! RT_Out ?Output Algorithm Control Parameters (P1 refactored)
  !   Now embeds RT_Out_Stp_Ctl_Algo (frequency/trigger) +
  !   RT_Out_Itr_Algo (buffer/compression/parallel IO) + legacy flat fields.
  !   New code should use %stp_ctl and %itr_algo; legacy fields retained
  !   for backward compatibility.
  !-----------------------------------------------------------------------------
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

  !-----------------------------------------------------------------------------
  ! RT_Out_Algo — Canonical Algo-type alias
  !   Alias added per naming convention: the Algo TYPE should be named
  !   RT_Out_Algo (not RT_Out). The pointer wrapper avoids renaming the widely
  !   used RT_Out type, which would break existing references throughout L5_RT.
  !   New code should use RT_Out_Algo where the "Algo" semantics are intended;
  !   access the underlying RT_Out via %inner.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Out_Algo
    TYPE(RT_Out), POINTER :: inner => NULL()
  END TYPE RT_Out_Algo

  !-----------------------------------------------------------------------------
  ! RT_Out_Ctx ?Per-call Output Context
  !   Transient context passed to output dispatch routines
  !-----------------------------------------------------------------------------
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
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Frame ?Output Frame Container (One Increment)
  !   Aggregates all output variables for one increment
  !-----------------------------------------------------------------------------
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
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Buffer ?Circular Buffer for Batched I/O
  !   Manages circular buffer for efficient write operations
  !-----------------------------------------------------------------------------
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
  
  !-----------------------------------------------------------------------------
  ! RT_Out_TriggerCtx ?Output Trigger Evaluation Context
  !   Encapsulates logic for evaluating output triggers
  !-----------------------------------------------------------------------------
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
  
CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_Out_FieldState Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE FieldState_Init(self, incr_interval, max_frames)
    CLASS(RT_Out_FieldState), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: incr_interval
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_frames
    
    self%n_frames_written = 0_i4
    self%n_frames_current_step = 0_i4
    self%time_last_written = 0.0_wp
    self%time_next_due = 0.0_wp
    self%inc_last_written = 0_i4
    
    IF (PRESENT(incr_interval)) self%inc_interval = incr_interval
    IF (PRESENT(max_frames)) self%n_frames_max = max_frames
    
    self%buffer_active = .FALSE.
    self%suppress_this_inc = .FALSE.
  END SUBROUTINE FieldState_Init
  
  SUBROUTINE FieldState_Reset(self)
    CLASS(RT_Out_FieldState), INTENT(INOUT) :: self
    
    self%n_frames_written = 0_i4
    self%n_frames_current_step = 0_i4
    self%time_last_written = 0.0_wp
    self%inc_last_written = 0_i4
    self%buffer_active = .FALSE.
  END SUBROUTINE FieldState_Reset
  
  FUNCTION FieldState_CheckTrigger(self, curr_incr, curr_time) RESULT(trigger)
    CLASS(RT_Out_FieldState), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: curr_incr
    REAL(wp), INTENT(IN) :: curr_time
    LOGICAL :: trigger
    
    trigger = .FALSE.
    
    ! Check increment-based trigger
    IF (self%inc_interval > 0) THEN
      IF (MOD(curr_incr, self%inc_interval) == 0) THEN
        trigger = .TRUE.
      END IF
    END IF
    
    ! Check time-based trigger
    IF (.NOT. trigger .AND. self%time_next_due > 0.0_wp) THEN
      IF (curr_time >= self%time_next_due) THEN
        trigger = .TRUE.
        self%time_next_due = curr_time + self%time_next_due
      END IF
    END IF
    
    ! Respect max frames limit
    IF (trigger .AND. self%n_frames_max > 0) THEN
      IF (self%n_frames_written >= self%n_frames_max) THEN
        trigger = .FALSE.
      END IF
    END IF
    
  END FUNCTION FieldState_CheckTrigger
  
  !-----------------------------------------------------------------------------
  ! RT_Out_HistState Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE HistState_Init(self, n_vars, buffer_size)
    CLASS(RT_Out_HistState), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_vars
    INTEGER(i4), INTENT(IN), OPTIONAL :: buffer_size
    
    self%n_points_written = 0_i4
    self%time_last_written = 0.0_wp
    self%n_variables = 0_i4
    
    IF (PRESENT(n_vars)) THEN
      self%n_variables = n_vars
      IF (ALLOCATED(self%data_buffer)) DEALLOCATE(self%data_buffer)
      ALLOCATE(self%data_buffer(buffer_size, n_vars + 1))  ! +1 for time
    END IF
    
    IF (PRESENT(buffer_size)) self%buffer_max_points = buffer_size
    
    self%buffer_active = .FALSE.
  END SUBROUTINE HistState_Init
  
  SUBROUTINE HistState_Reset(self)
    CLASS(RT_Out_HistState), INTENT(INOUT) :: self
    
    self%n_points_written = 0_i4
    self%time_last_written = 0.0_wp
    self%buffer_point_count = 0_i4
    self%buffer_active = .FALSE.
  END SUBROUTINE HistState_Reset
  
  SUBROUTINE HistState_AddPoint(self, time, values)
    CLASS(RT_Out_HistState), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(IN) :: values(:)
    
    ! TODO: Implement circular buffer push
    self%n_points_written = self%n_points_written + 1
    
  END SUBROUTINE HistState_AddPoint
  
  !-----------------------------------------------------------------------------
  ! RT_Out Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE OutAlgo_Init(self)
    CLASS(RT_Out), INTENT(INOUT) :: self
    
    self%field_freq_incr = 1_i4
    self%hist_freq_incr = 1_i4
    self%field_freq_time = 0.0_wp
    self%hist_freq_time = 0.0_wp
    self%trigger_type = RT_OUT_TRIG_INCREMENT
    self%use_field_buffer = .TRUE.
    self%use_hist_buffer = .TRUE.
    self%compress_output = .FALSE.
  END SUBROUTINE OutAlgo_Init
  
  SUBROUTINE OutAlgo_SetFreq(self, field_incr, hist_incr, field_time, hist_time)
    CLASS(RT_Out), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: field_incr, hist_incr
    REAL(wp), INTENT(IN), OPTIONAL :: field_time, hist_time
    
    IF (PRESENT(field_incr)) self%field_freq_incr = field_incr
    IF (PRESENT(hist_incr)) self%hist_freq_incr = hist_incr
    IF (PRESENT(field_time)) self%field_freq_time = field_time
    IF (PRESENT(hist_time)) self%hist_freq_time = hist_time
  END SUBROUTINE OutAlgo_SetFreq
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Ctx Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE OutCtx_Init(self)
    CLASS(RT_Out_Ctx), INTENT(INOUT) :: self
    
    self%step_id = 0_i4
    self%incr_id = 0_i4
    self%step_time = 0.0_wp
    self%total_time = 0.0_wp
    self%time_increment = 0.0_wp
    self%is_first_incr = .FALSE.
    self%is_last_incr = .FALSE.
    self%force_field_write = .FALSE.
  END SUBROUTINE OutCtx_Init
  
  SUBROUTINE OutCtx_Update(self, step, incr, time, dt)
    CLASS(RT_Out_Ctx), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: step, incr
    REAL(wp), INTENT(IN) :: time, dt
    
    self%step_id = step
    self%incr_id = incr
    self%step_time = time
    self%total_time = time
    self%time_increment = dt
    self%is_first_incr = (incr == 1)
    
  END SUBROUTINE OutCtx_Update
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Frame Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE OutFrame_Init(self)
    CLASS(RT_Out_Frame), INTENT(INOUT) :: self
    self%is_valid = .FALSE.
  END SUBROUTINE OutFrame_Init
  
  SUBROUTINE OutFrame_Allocate(self, n_nodes, n_elements)
    CLASS(RT_Out_Frame), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: n_nodes, n_elements
    
    self%pop%n_nodes = n_nodes
    self%pop%n_elements = n_elements
    
    ! Allocate nodal data
    IF (.NOT. ALLOCATED(self%node_coords)) ALLOCATE(self%node_coords(3, n_nodes))
    IF (.NOT. ALLOCATED(self%node_displ)) ALLOCATE(self%node_displ(3, n_nodes))
    
    ! Allocate element data
    IF (.NOT. ALLOCATED(self%elem_stress)) ALLOCATE(self%elem_stress(6, n_elements))
    
    self%is_valid = .TRUE.
    
  END SUBROUTINE OutFrame_Allocate
  
  SUBROUTINE OutFrame_Clear(self)
    CLASS(RT_Out_Frame), INTENT(INOUT) :: self
    
    IF (ALLOCATED(self%node_coords)) DEALLOCATE(self%node_coords)
    IF (ALLOCATED(self%node_displ)) DEALLOCATE(self%node_displ)
    IF (ALLOCATED(self%elem_stress)) DEALLOCATE(self%elem_stress)
    
    self%is_valid = .FALSE.
    
  END SUBROUTINE OutFrame_Clear
  
  !-----------------------------------------------------------------------------
  ! RT_Out_Buffer Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE OutBuffer_Init(self, capacity)
    CLASS(RT_Out_Buffer), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: capacity
    
    self%capacity = capacity
    self%size = 0_i4
    self%head = 0_i4
    self%tail = 0_i4
    self%is_full = .FALSE.
    
    IF (ALLOCATED(self%data)) DEALLOCATE(self%data)
    ALLOCATE(self%data(capacity))
    
  END SUBROUTINE OutBuffer_Init
  
  SUBROUTINE OutBuffer_Push(self, value, index)
    CLASS(RT_Out_Buffer), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: value
    INTEGER(i4), INTENT(IN) :: index
    
    IF (self%is_full) THEN
      ! Buffer full, needs flush
      self%needs_flush = .TRUE.
      RETURN
    END IF
    
    self%data(self%head + 1) = value
    self%indices(self%head + 1) = index
    self%head = MOD(self%head + 1, self%capacity)
    self%size = self%size + 1
    
    IF (self%head == self%tail) self%is_full = .TRUE.
    
  END SUBROUTINE OutBuffer_Push
  
  FUNCTION OutBuffer_Pop(self) RESULT(value)
    CLASS(RT_Out_Buffer), INTENT(INOUT) :: self
    REAL(wp) :: value
    
    IF (self%size == 0) THEN
      value = 0.0_wp
      RETURN
    END IF
    
    value = self%data(self%tail + 1)
    self%tail = MOD(self%tail + 1, self%capacity)
    self%size = self%size - 1
    self%is_full = .FALSE.
    
  END FUNCTION OutBuffer_Pop
  
  SUBROUTINE OutBuffer_Flush(self)
    CLASS(RT_Out_Buffer), INTENT(INOUT) :: self
    ! TODO: Implement actual flush to disk
    self%size = 0_i4
    self%head = 0_i4
    self%tail = 0_i4
    self%is_full = .FALSE.
    self%needs_flush = .FALSE.
  END SUBROUTINE OutBuffer_Flush
  
  SUBROUTINE OutBuffer_Clear(self)
    CLASS(RT_Out_Buffer), INTENT(INOUT) :: self
    CALL self%Flush()
    IF (ALLOCATED(self%data)) DEALLOCATE(self%data)
    IF (ALLOCATED(self%indices)) DEALLOCATE(self%indices)
  END SUBROUTINE OutBuffer_Clear
  
!===============================================================================
! SIO unified Arg types for Output domain
!   These replace the *_In / *_Out pair pattern used in RT_Out_Proc.f90.
!   Per Principle #14: unified *_Arg bundles with [IN]/[OUT] comments.
!===============================================================================

!-----------------------------------------------------------------------------
! RT_Out_Init_Arg — Unified init bundle
!-----------------------------------------------------------------------------
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

!-----------------------------------------------------------------------------
! RT_Out_Write_Arg — Unified write bundle
!-----------------------------------------------------------------------------
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

END MODULE RT_Out_Def
