!===============================================================================
! Module: RT_WriteBack_Types                                     [Template v1.0]
! Layer:  L5_RT — Runtime Layer
! Domain: WriteBack — Result write-back to model data layer types
!
! Purpose:
!   Defines types for writing computed results (displacements, stresses,
!   strains, reactions) back to the L3_MD model data containers.
!   Manages buffering and coordinate transformations if needed.
!
! Type catalogue (3 TYPEs - no Algo):
!   RT_WriteBack_Desc  – Write-back configuration (optional)
!   RT_WriteBack_State – Write progress tracking (warm)
!   RT_WriteBack_Ctx   – Temporary buffers (hot path)
!
! Note: No Algo TYPE needed - pure data operation without algorithm strategy.
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!   USE IF_Err_Brg (ErrorStatusType, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE RT_WriteBack_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_WriteBack_Desc
  PUBLIC :: RT_WriteBack_State
  PUBLIC :: RT_WriteBack_Ctx
  
  !-- Output field constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_FIELD_U         = 1_i4  ! Displacement  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_FIELD_V         = 2_i4  ! Velocity  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_FIELD_A         = 3_i4  ! Acceleration  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_FIELD_S         = 4_i4  ! Stress  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_FIELD_E         = 5_i4  ! Strain  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_FIELD_RF        = 6_i4  ! Reaction force  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_FIELD_CF        = 7_i4  ! Contact force  ! migrated
  
  !-- Write frequency constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WRITE_WRITE_EVERY_INC     = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WRITE_WRITE_STEP_END      = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_WRITE_WRITE_USER_DEFINED  = 3_i4  ! migrated
  
  !-----------------------------------------------------------------------------
  ! RT_WriteBack_Desc — Write-back configuration (optional, cold)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WriteBack_Desc
    !-- Write frequency
    INTEGER(i4) :: write_frequency = 1_i4  ! Write every N increments
    INTEGER(i4) :: write_trigger = WRITE_EVERY_INC
    
    !-- Output content flags
    LOGICAL     :: write_displacement = .TRUE.
    LOGICAL     :: write_velocity = .FALSE.      ! Dynamic analysis only
    LOGICAL     :: write_acceleration = .FALSE.  ! Dynamic analysis only
    LOGICAL     :: write_stress = .TRUE.
    LOGICAL     :: write_strain = .TRUE.
    LOGICAL     :: write_reaction = .TRUE.
    LOGICAL     :: write_contact_force = .FALSE.
    
    !-- Output scope
    INTEGER(i4) :: output_scope = 1_i4  ! 1=All/2=Subset
    INTEGER(i4), POINTER :: output_node_ids(:) => NULL()
    INTEGER(i4), POINTER :: output_element_ids(:) => NULL()
    
    !-- Coordinate transformation
    LOGICAL     :: use_local_coords = .FALSE.
    INTEGER(i4) :: local_coord_sys_id = 0
    
  CONTAINS
    PROCEDURE :: Init => WriteBack_Desc_Init
    PROCEDURE :: SetOutputFields => WriteBack_Desc_SetOutputFields
    PROCEDURE :: SetScope => WriteBack_Desc_SetScope
  END TYPE RT_WriteBack_Desc
  
  !-----------------------------------------------------------------------------
  ! RT_WriteBack_State — Write-back progress state (warm)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WriteBack_State
    !-- Write progress
    INTEGER(i4) :: last_write_step = 0
    INTEGER(i4) :: last_write_increment = 0
    INTEGER(i4) :: total_writes = 0
    INTEGER(i4) :: current_write_count = 0
    
    !-- Data statistics
    INTEGER(i4) :: n_nodes_written = 0
    INTEGER(i4) :: n_elements_written = 0
    INTEGER(i4) :: n_gp_written = 0
    INTEGER(i4) :: n_total_dofs = 0
    
    !-- Timing information
    REAL(wp)    :: last_write_time = 0.0_wp
    REAL(wp)    :: write_elapsed = 0.0_wp
    REAL(wp)    :: avg_write_time = 0.0_wp
    
    !-- Success/failure tracking
    LOGICAL     :: last_write_successful = .TRUE.
    INTEGER(i4) :: n_write_failures = 0
    TYPE(ErrorStatusType) :: last_error_status
    
  CONTAINS
    PROCEDURE :: Reset => WriteBack_State_Reset
    PROCEDURE :: UpdateProgress => WriteBack_State_UpdateProgress
    PROCEDURE :: RecordWriteTime => WriteBack_State_RecordWriteTime
    PROCEDURE :: AggregateStatistics => WriteBack_State_AggregateStats
  END TYPE RT_WriteBack_State
  
  !-----------------------------------------------------------------------------
  ! RT_WriteBack_Ctx — Hot path context (temporary buffers)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_WriteBack_Ctx
    !-- Temporary buffers (reference to pre-allocated arrays)
    REAL(wp), POINTER :: u_buffer(:) => NULL()      ! Displacement buffer
    REAL(wp), POINTER :: v_buffer(:) => NULL()      ! Velocity buffer
    REAL(wp), POINTER :: a_buffer(:) => NULL()      ! Acceleration buffer
    REAL(wp), POINTER :: stress_buffer(:) => NULL() ! Stress buffer (n_elem * 6)
    REAL(wp), POINTER :: strain_buffer(:) => NULL() ! Strain buffer (n_elem * 6)
    REAL(wp), POINTER :: rf_buffer(:) => NULL()     ! Reaction force buffer
    
    !-- Coordinate transformation matrix (if needed)
    REAL(wp)    :: rot_matrix(3,3) = 0.0_wp
    REAL(wp)    :: inv_rot_matrix(3,3) = 0.0_wp
    
    !-- Element/state pointers
    REAL(wp), POINTER :: elem_stress(:) => NULL()   ! Current element stress (6)
    REAL(wp), POINTER :: elem_strain(:) => NULL()   ! Current element strain (6)
    INTEGER(i4) :: current_elem_id = 0
    INTEGER(i4) :: current_gp_id = 0
    
    !-- Node/state pointers
    REAL(wp), POINTER :: node_disp(:) => NULL()     ! Current node displacement (3)
    REAL(wp), POINTER :: node_react(:) => NULL()    ! Current node reaction (3)
    INTEGER(i4) :: current_node_id = 0
    
    !-- Work arrays (pre-allocated, 禁止 ALLOCATABLE)
    REAL(wp), POINTER :: work_array(:) => NULL()
    REAL(wp), POINTER :: temp_vector(:) => NULL()
    
    !-- Buffer management
    INTEGER(i4) :: buffer_size = 0
    INTEGER(i4) :: buffer_offset = 0
    LOGICAL     :: buffer_needs_flush = .FALSE.
    
  CONTAINS
    PROCEDURE :: AttachBuffers => WriteBack_Ctx_AttachBuffers
    PROCEDURE :: ClearBuffers => WriteBack_Ctx_ClearBuffers
    PROCEDURE :: FlushBuffer => WriteBack_Ctx_FlushBuffer
    PROCEDURE :: Detach => WriteBack_Ctx_Detach
  END TYPE RT_WriteBack_Ctx
  
END MODULE RT_WriteBack_Types
