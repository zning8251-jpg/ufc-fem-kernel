!===============================================================================
! MODULE: RT_WB_Def
! LAYER:  L5_RT
! DOMAIN: WriteBack
! ROLE:   Def �?AUTHORITY four-type definitions
! BRIEF:  RT_WB_Desc/ProgressState/BufferState/Algo/Ctx/TransformCtx + constants.
!===============================================================================
!   3. Four-Type System: Desc/State/Algo/Ctx separation for clarity
!   4. Performance: Pre-allocated buffers, no dynamic allocation in hot path
!
! Type Catalogue:
!   - RT_WB_Desc: Runtime write-back descriptor
!   - RT_WB_ProgressState: Write-back progress state
!   - RT_WB_BufferState: Buffer management state
!   - RT_WB_Algo: Write-back algorithm parameters
!   - RT_WB_Ctx: Per-call write-back context
!   - RT_WB_TransformCtx: Coordinate transformation context
!
! Layer Dependency:
!   USE IF_Prec              (wp, i4)
!   USE IF_Err_Brg           (ErrorStatusType)
!   USE MD_WB_Brg     (L3_MD write-back API)
!===============================================================================
MODULE RT_WB_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE MD_WB_Brg, ONLY: MD_WB_Mesh_NodePos, MD_WB_Mesh_NodeDisp
  USE RT_WB_Aux_Def, ONLY: RT_WB_Stp_Ctl_Algo, RT_WB_Itr_Algo
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_WB_Desc
  PUBLIC :: RT_WB_ProgressState
  PUBLIC :: RT_WB_BufferState
  PUBLIC :: RT_WB_Algo
  PUBLIC :: RT_WB_Ctx
  PUBLIC :: RT_WB_TransformCtx
  PUBLIC :: RT_WB_State
  
  !-- WriteBack target type constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_NODE_COORD = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_NODE_DISP = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_ELEM_STRESS = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_ELEM_STRAIN = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_TARGET_NODE_REACT = 5_i4
  
  !-- Field type constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_FIELD_U = 1_i4  ! Displacement
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_FIELD_V = 2_i4  ! Velocity
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_FIELD_A = 3_i4  ! Acceleration
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_FIELD_S = 4_i4  ! Stress
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_FIELD_E = 5_i4  ! Strain
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_FIELD_RF = 6_i4 ! Reaction force
  
  !-- Write frequency constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_WRITE_EVERY_INC = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_WRITE_STEP_END = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_WRITE_USER_DEFINED = 3_i4
  
  !-- Output scope constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_SCOPE_ALL = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WB_SCOPE_SUBSET = 2_i4
  
  !-----------------------------------------------------------------------------
  ! RT_WB_Desc — Runtime WriteBack Descriptor (R-09 canonical name)
  !   Configuration for result write-back operations
  !   Replaces RT_WB_Base_Desc (R-09).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_Desc
    INTEGER(i4) :: runtime_id = 0_i4           ! Runtime instance ID
    CHARACTER(LEN=64) :: wb_label = ''         ! Write-back configuration label
    
    ! Write frequency
    INTEGER(i4) :: write_frequency = 1_i4      ! Write every N increments
    INTEGER(i4) :: write_trigger = RT_WB_WRITE_EVERY_INC
    
    ! Output content flags
    LOGICAL :: write_displacement = .TRUE.
    LOGICAL :: write_velocity = .FALSE.        ! Dynamic analysis only
    LOGICAL :: write_acceleration = .FALSE.    ! Dynamic analysis only
    LOGICAL :: write_stress = .TRUE.
    LOGICAL :: write_strain = .TRUE.
    LOGICAL :: write_reaction = .TRUE.
    LOGICAL :: write_contact_force = .FALSE.
    
    ! Output scope
    INTEGER(i4) :: output_scope = RT_WB_SCOPE_ALL
    INTEGER(i4), POINTER :: output_node_ids(:) => NULL()
    INTEGER(i4), POINTER :: output_element_ids(:) => NULL()
    
    ! Coordinate transformation
    LOGICAL :: use_local_coords = .FALSE.
    INTEGER(i4) :: local_coord_sys_id = 0_i4
    
    ! Status flags
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_active = .TRUE.
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetOutputFields
    PROCEDURE :: SetScope
  END TYPE RT_WB_Desc

  
  !-----------------------------------------------------------------------------
  ! RT_WB_ProgressState �?Write-back Progress State
  !   Tracks write-back execution progress and statistics
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_ProgressState
    ! Write progress counters
    INTEGER(i4) :: last_write_step = 0_i4
    INTEGER(i4) :: last_write_increment = 0_i4
    INTEGER(i4) :: total_writes = 0_i4
    INTEGER(i4) :: current_write_count = 0_i4
    
    ! Data statistics
    INTEGER(i4) :: n_nodes_written = 0_i4
    INTEGER(i4) :: n_elements_written = 0_i4
    INTEGER(i4) :: n_gp_written = 0_i4
    INTEGER(i4) :: n_total_dofs = 0_i4
    
    ! Timing information
    REAL(wp) :: last_write_time = 0.0_wp
    REAL(wp) :: write_elapsed = 0.0_wp
    REAL(wp) :: avg_write_time = 0.0_wp
    
    ! Success/failure tracking
    LOGICAL :: last_write_successful = .TRUE.
    INTEGER(i4) :: n_write_failures = 0_i4
    TYPE(ErrorStatusType) :: last_error_status
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reset
    PROCEDURE :: UpdateProgress
    PROCEDURE :: RecordWriteTime
  END TYPE RT_WB_ProgressState
  
  !-----------------------------------------------------------------------------
  ! RT_WB_BufferState �?Buffer Management State
  !   Manages pre-allocated buffers for efficient write-back
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_BufferState
    ! Buffer sizes
    INTEGER(i4) :: node_buffer_size = 0_i4
    INTEGER(i4) :: elem_buffer_size = 0_i4
    INTEGER(i4) :: gp_buffer_size = 0_i4
    
    ! Buffer usage tracking
    INTEGER(i4) :: nodes_in_buffer = 0_i4
    INTEGER(i4) :: elements_in_buffer = 0_i4
    INTEGER(i4) :: gps_in_buffer = 0_i4
    
    ! Flush control
    LOGICAL :: buffer_needs_flush = .FALSE.
    INTEGER(i4) :: flush_threshold = 1000_i4   ! Flush when buffer reaches this count
    
    ! Memory management
    INTEGER(i4) :: total_allocations = 0_i4
    INTEGER(i4) :: total_deallocations = 0_i4
    INTEGER(i4) :: active_buffers = 0_i4
    
    ! Status
    LOGICAL :: buffers_allocated = .FALSE.
    TYPE(ErrorStatusType) :: status
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reset
    PROCEDURE :: CheckFlush
  END TYPE RT_WB_BufferState
  
  !-----------------------------------------------------------------------------
  ! RT_WB_Algo — WriteBack Algorithm Parameters (P2 refactored)
  !   Now embeds RT_WB_Stp_Ctl_Algo (trigger/strategy/validation) +
  !   RT_WB_Itr_Algo (buffer/compression/audit) + legacy flat fields.
  !   New code should use %stp_ctl and %itr_algo; legacy fields retained
  !   for backward compatibility.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_Algo
    !-- P2 sub-Algo composition --
    TYPE(RT_WB_Stp_Ctl_Algo) :: stp_ctl    ! [Phase:Stp|Verb:Ctl] trigger/strategy/validation
    TYPE(RT_WB_Itr_Algo)     :: itr_algo   ! [Phase:Itr|Verb:Com] buffer/compression/audit

    !-- Legacy flat fields (use stp_ctl / itr_algo for new code) --
    LOGICAL :: use_node_buffering = .TRUE.        ! (legacy, use itr_algo%use_node_buffering)
    LOGICAL :: use_elem_buffering = .TRUE.        ! (legacy, use itr_algo%use_elem_buffering)
    INTEGER(i4) :: node_buffer_capacity = 10000_i4  ! (legacy, use itr_algo%node_buffer_capacity)
    INTEGER(i4) :: elem_buffer_capacity = 5000_i4   ! (legacy, use itr_algo%elem_buffer_capacity)
    LOGICAL :: compress_output = .FALSE.        ! (legacy, use itr_algo%compress_output)
    INTEGER(i4) :: compression_level = 6_i4       ! (legacy, use itr_algo%compression_level)
    LOGICAL :: use_parallel_write = .FALSE.      ! (legacy, use itr_algo%use_parallel_write)
    INTEGER(i4) :: n_write_threads = 1_i4         ! (legacy, use itr_algo%n_write_threads)
    LOGICAL :: batch_small_writes = .TRUE.       ! (legacy, use itr_algo%batch_small_writes)
    INTEGER(i4) :: batch_threshold = 100_i4       ! (legacy, use itr_algo%batch_threshold)
    LOGICAL :: save_checkpoint_on_write = .FALSE.  ! (legacy, use stp_ctl%save_checkpoint_on_write)
    INTEGER(i4) :: checkpoint_interval = 10_i4     ! (legacy, use stp_ctl%checkpoint_interval)
    LOGICAL :: validate_before_write = .TRUE.    ! (legacy, use stp_ctl%validate_before_write)
    LOGICAL :: checksum_enabled = .FALSE.        ! (legacy, use stp_ctl%checksum_enabled)

  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetBufferStrategy
  END TYPE RT_WB_Algo
  
  !-----------------------------------------------------------------------------
  ! RT_WB_Ctx �?Per-call WriteBack Context
  !   Hot path context with temporary buffers (no dynamic allocation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_Ctx
    ! Temporary buffers (POINTER to pre-allocated arrays)
    REAL(wp), POINTER :: u_buffer(:) => NULL()      ! Displacement buffer
    REAL(wp), POINTER :: v_buffer(:) => NULL()      ! Velocity buffer
    REAL(wp), POINTER :: a_buffer(:) => NULL()      ! Acceleration buffer
    REAL(wp), POINTER :: stress_buffer(:) => NULL() ! Stress buffer [n_elem*6]
    REAL(wp), POINTER :: strain_buffer(:) => NULL() ! Strain buffer [n_elem*6]
    REAL(wp), POINTER :: rf_buffer(:) => NULL()     ! Reaction force buffer
    
    ! Work arrays (pre-allocated, 禁止 ALLOCATABLE)
    REAL(wp), POINTER :: work_array(:) => NULL()
    REAL(wp), POINTER :: temp_vector(:) => NULL()
    
    ! Current element/state pointers
    REAL(wp), POINTER :: elem_stress(:) => NULL()   ! Current element stress [6]
    REAL(wp), POINTER :: elem_strain(:) => NULL()   ! Current element strain [6]
    INTEGER(i4) :: current_elem_id = 0_i4
    INTEGER(i4) :: current_gp_id = 0_i4
    
    ! Current node/state pointers
    REAL(wp), POINTER :: node_disp(:) => NULL()     ! Current node displacement [3]
    REAL(wp), POINTER :: node_react(:) => NULL()    ! Current node reaction [3]
    INTEGER(i4) :: current_node_id = 0_i4
    
    ! Buffer management
    INTEGER(i4) :: buffer_size = 0_i4
    INTEGER(i4) :: buffer_offset = 0_i4
    LOGICAL :: buffer_needs_flush = .FALSE.
    
    ! Operation metadata
    INTEGER(i4) :: operation_type = 0_i4           ! RT_WB_TARGET_XXX
    INTEGER(i4) :: field_type = 0_i4               ! RT_WB_FIELD_XXX
    INTEGER(i4) :: n_items_to_write = 0_i4
    
  CONTAINS
    PROCEDURE :: AttachBuffers
    PROCEDURE :: ClearBuffers
    PROCEDURE :: FlushBuffer
    PROCEDURE :: Detach
  END TYPE RT_WB_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_WB_TransformCtx �?Coordinate Transformation Context
  !   Manages coordinate system transformations for write-back
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_TransformCtx
    ! Transformation matrices
    REAL(wp) :: rot_matrix(3,3) = 0.0_wp           ! Global �?Local
    REAL(wp) :: inv_rot_matrix(3,3) = 0.0_wp       ! Local �?Global
    LOGICAL :: rotation_available = .FALSE.
    
    ! Coordinate system info
    INTEGER(i4) :: coord_sys_type = 0_i4           ! 0=Cartesian, 1=Cylindrical, 2=Spherical
    INTEGER(i4) :: coord_sys_id = 0_i4
    
    ! Node-specific transformation
    INTEGER(i4) :: n_transform_nodes = 0_i4
    INTEGER(i4), POINTER :: transform_node_ids(:) => NULL()
    
    ! Temporary storage for transformed data
    REAL(wp) :: temp_global(3) = 0.0_wp
    REAL(wp) :: temp_local(3) = 0.0_wp
    
    ! Status
    LOGICAL :: transformation_active = .FALSE.
    TYPE(ErrorStatusType) :: status
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetRotation
    PROCEDURE :: TransformVector
    PROCEDURE :: Reset
  END TYPE RT_WB_TransformCtx
  
CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_WB_Desc Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE WB_Desc_Init(self)
    CLASS(RT_WB_Desc), INTENT(INOUT) :: self
    
    self%write_frequency = 1_i4
    self%write_trigger = RT_WB_WRITE_EVERY_INC
    self%write_displacement = .TRUE.
    self%write_stress = .TRUE.
    self%write_strain = .TRUE.
    self%output_scope = RT_WB_SCOPE_ALL
    self%use_local_coords = .FALSE.
    self%is_initialized = .TRUE.
    
  END SUBROUTINE WB_Desc_Init
  
  SUBROUTINE WB_Desc_SetOutputFields(self, u, v, a, s, e, rf)
    CLASS(RT_WB_Desc), INTENT(INOUT) :: self
    LOGICAL, INTENT(IN), OPTIONAL :: u, v, a, s, e, rf
    
    IF (PRESENT(u)) self%write_displacement = u
    IF (PRESENT(v)) self%write_velocity = v
    IF (PRESENT(a)) self%write_acceleration = a
    IF (PRESENT(s)) self%write_stress = s
    IF (PRESENT(e)) self%write_strain = e
    IF (PRESENT(rf)) self%write_reaction = rf
    
  END SUBROUTINE WB_Desc_SetOutputFields
  
  SUBROUTINE WB_Desc_SetScope(self, scope, node_ids, elem_ids)
    CLASS(RT_WB_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: scope
    INTEGER(i4), INTENT(IN), OPTIONAL, TARGET :: node_ids(:)
    INTEGER(i4), INTENT(IN), OPTIONAL, TARGET :: elem_ids(:)
    
    self%output_scope = scope
    
    IF (scope == RT_WB_SCOPE_SUBSET) THEN
      IF (PRESENT(node_ids)) self%output_node_ids => node_ids
      IF (PRESENT(elem_ids)) self%output_element_ids => elem_ids
    END IF
    
  END SUBROUTINE WB_Desc_SetScope
  
  !-----------------------------------------------------------------------------
  ! RT_WB_ProgressState Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE WBProgress_Init(self)
    CLASS(RT_WB_ProgressState), INTENT(INOUT) :: self
    
    self%last_write_step = 0_i4
    self%last_write_increment = 0_i4
    self%total_writes = 0_i4
    self%n_nodes_written = 0_i4
    self%n_elements_written = 0_i4
    self%last_write_time = 0.0_wp
    self%last_write_successful = .TRUE.
    
  END SUBROUTINE WBProgress_Init
  
  SUBROUTINE WBProgress_Reset(self)
    CLASS(RT_WB_ProgressState), INTENT(INOUT) :: self
    
    self%current_write_count = 0_i4
    self%write_elapsed = 0.0_wp
    self%avg_write_time = 0.0_wp
    
  END SUBROUTINE WBProgress_Reset
  
  SUBROUTINE WBProgress_UpdateProgress(self, step, incr, n_nodes, n_elems)
    CLASS(RT_WB_ProgressState), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: step, incr
    INTEGER(i4), INTENT(IN), OPTIONAL :: n_nodes, n_elems
    
    self%last_write_step = step
    self%last_write_increment = incr
    self%total_writes = self%total_writes + 1
    self%current_write_count = self%current_write_count + 1
    
    IF (PRESENT(n_nodes)) self%n_nodes_written = self%n_nodes_written + n_nodes
    IF (PRESENT(n_elems)) self%n_elements_written = self%n_elements_written + n_elems
    
  END SUBROUTINE WBProgress_UpdateProgress
  
  SUBROUTINE WBProgress_RecordWriteTime(self, elapsed_sec, success)
    CLASS(RT_WB_ProgressState), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: elapsed_sec
    LOGICAL, INTENT(IN) :: success
    
    self%last_write_time = elapsed_sec
    self%write_elapsed = elapsed_sec
    self%last_write_successful = success
    
    IF (.NOT. success) THEN
      self%n_write_failures = self%n_write_failures + 1
    END IF
    
    ! Update average
    IF (self%total_writes > 0) THEN
      self%avg_write_time = (self%avg_write_time * (self%total_writes - 1) + elapsed_sec) / &
                            REAL(self%total_writes, wp)
    END IF
    
  END SUBROUTINE WBProgress_RecordWriteTime
  
  !-----------------------------------------------------------------------------
  ! RT_WB_BufferState Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE WBBuffer_Init(self, node_cap, elem_cap)
    CLASS(RT_WB_BufferState), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: node_cap, elem_cap
    
    IF (PRESENT(node_cap)) self%node_buffer_size = node_cap
    IF (PRESENT(elem_cap)) self%elem_buffer_size = elem_cap
    
    self%nodes_in_buffer = 0_i4
    self%elements_in_buffer = 0_i4
    self%buffer_needs_flush = .FALSE.
    self%buffers_allocated = .TRUE.
    
  END SUBROUTINE WBBuffer_Init
  
  SUBROUTINE WBBuffer_Reset(self)
    CLASS(RT_WB_BufferState), INTENT(INOUT) :: self
    
    self%nodes_in_buffer = 0_i4
    self%elements_in_buffer = 0_i4
    self%buffer_needs_flush = .FALSE.
    
  END SUBROUTINE WBBuffer_Reset
  
  FUNCTION WBBuffer_CheckFlush(self) RESULT(needs_flush)
    CLASS(RT_WB_BufferState), INTENT(IN) :: self
    LOGICAL :: needs_flush
    
    needs_flush = .FALSE.
    
    IF (self%nodes_in_buffer >= self%flush_threshold) THEN
      needs_flush = .TRUE.
    END IF
    
    IF (self%elements_in_buffer >= self%flush_threshold) THEN
      needs_flush = .TRUE.
    END IF
    
  END FUNCTION WBBuffer_CheckFlush
  
  !-----------------------------------------------------------------------------
  ! RT_WB_Algo Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE WBAlgo_Init(self)
    CLASS(RT_WB_Algo), INTENT(INOUT) :: self
    
    self%use_node_buffering = .TRUE.
    self%use_elem_buffering = .TRUE.
    self%node_buffer_capacity = 10000_i4
    self%elem_buffer_capacity = 5000_i4
    self%compress_output = .FALSE.
    self%use_parallel_write = .FALSE.
    self%batch_small_writes = .TRUE.
    self%validate_before_write = .TRUE.
    
  END SUBROUTINE WBAlgo_Init
  
  SUBROUTINE WBAlgo_SetBufferStrategy(self, use_node_buf, use_elem_buf, node_cap, elem_cap)
    CLASS(RT_WB_Algo), INTENT(INOUT) :: self
    LOGICAL, INTENT(IN), OPTIONAL :: use_node_buf, use_elem_buf
    INTEGER(i4), INTENT(IN), OPTIONAL :: node_cap, elem_cap
    
    IF (PRESENT(use_node_buf)) self%use_node_buffering = use_node_buf
    IF (PRESENT(use_elem_buf)) self%use_elem_buffering = use_elem_buf
    IF (PRESENT(node_cap)) self%node_buffer_capacity = node_cap
    IF (PRESENT(elem_cap)) self%elem_buffer_capacity = elem_cap
    
  END SUBROUTINE WBAlgo_SetBufferStrategy
  
  !-----------------------------------------------------------------------------
  ! RT_WB_Ctx Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE WBCtx_AttachBuffers(self, u_buf, v_buf, a_buf, s_buf, e_buf, rf_buf)
    CLASS(RT_WB_Ctx), INTENT(INOUT) :: self
    REAL(wp), INTENT(INOUT), TARGET, OPTIONAL :: u_buf(:), v_buf(:), a_buf(:)
    REAL(wp), INTENT(INOUT), TARGET, OPTIONAL :: s_buf(:), e_buf(:), rf_buf(:)
    
    IF (PRESENT(u_buf)) self%u_buffer => u_buf
    IF (PRESENT(v_buf)) self%v_buffer => v_buf
    IF (PRESENT(a_buf)) self%a_buffer => a_buf
    IF (PRESENT(s_buf)) self%stress_buffer => s_buf
    IF (PRESENT(e_buf)) self%strain_buffer => e_buf
    IF (PRESENT(rf_buf)) self%rf_buffer => rf_buf
    
  END SUBROUTINE WBCtx_AttachBuffers
  
  SUBROUTINE WBCtx_ClearBuffers(self)
    CLASS(RT_WB_Ctx), INTENT(INOUT) :: self
    
    self%buffer_offset = 0_i4
    self%buffer_needs_flush = .FALSE.
    self%n_items_to_write = 0_i4
    
  END SUBROUTINE WBCtx_ClearBuffers
  
  SUBROUTINE WBCtx_FlushBuffer(self)
    CLASS(RT_WB_Ctx), INTENT(INOUT) :: self
    ! Placeholder: Actual flush implemented in RT_WBImpl
    self%buffer_offset = 0_i4
    self%buffer_needs_flush = .FALSE.
    
  END SUBROUTINE WBCtx_FlushBuffer
  
  SUBROUTINE WBCtx_Detach(self)
    CLASS(RT_WB_Ctx), INTENT(INOUT) :: self
    
    self%u_buffer => NULL()
    self%v_buffer => NULL()
    self%a_buffer => NULL()
    self%stress_buffer => NULL()
    self%strain_buffer => NULL()
    self%rf_buffer => NULL()
    self%work_array => NULL()
    self%temp_vector => NULL()
    
  END SUBROUTINE WBCtx_Detach
  
  !-----------------------------------------------------------------------------
  ! RT_WB_TransformCtx Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE WBTransform_Init(self)
    CLASS(RT_WB_TransformCtx), INTENT(INOUT) :: self
    
    self%rot_matrix = 0.0_wp
    self%inv_rot_matrix = 0.0_wp
    self%rotation_available = .FALSE.
    self%coord_sys_type = 0_i4
    self%transformation_active = .FALSE.
    
  END SUBROUTINE WBTransform_Init
  
  SUBROUTINE WBTransform_SetRotation(self, rot_mat)
    CLASS(RT_WB_TransformCtx), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: rot_mat(3,3)
    
    self%rot_matrix = rot_mat
    ! Compute inverse (transpose for orthogonal rotation matrices)
    self%inv_rot_matrix = TRANSPOSE(rot_mat)
    self%rotation_available = .TRUE.
    
  END SUBROUTINE WBTransform_SetRotation
  
  SUBROUTINE WBTransform_TransformVector(self, global_vec, local_vec)
    CLASS(RT_WB_TransformCtx), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: global_vec(3)
    REAL(wp), INTENT(OUT) :: local_vec(3)
    
    IF (self%rotation_available) THEN
      local_vec = MATMUL(self%rot_matrix, global_vec)
    ELSE
      local_vec = global_vec
    END IF
    
  END SUBROUTINE WBTransform_TransformVector
  
  SUBROUTINE WBTransform_Reset(self)
    CLASS(RT_WB_TransformCtx), INTENT(INOUT) :: self
    
    CALL self%Init()
    
  END SUBROUTINE WBTransform_Reset
  
  !-----------------------------------------------------------------------------
  ! Canonical 4-type alias
  ! RT_WB_State — wraps RT_WB_ProgressState for SIO unified Arg types.
  !   Keeps RT_WB_ProgressState as the primary name; RT_WB_State is the
  !   canonical 4-type "State" that aligns with Desc/State/Algo/Ctx convention.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WB_State
    TYPE(RT_WB_ProgressState) :: progress
  END TYPE RT_WB_State

END MODULE RT_WB_Def
