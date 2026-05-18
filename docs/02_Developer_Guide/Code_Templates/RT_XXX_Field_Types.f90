!===============================================================================
! Module: RT_XXX_Field_Types                                       [Template v1.0]
! Layer:  L5_RT — Runtime Layer
! Domain: Field — Runtime types for field variable management
!
! Purpose:
!   Defines types for runtime field variable initialization, updating,
!   and solution-dependent state management. Supports USDFLD/SDVINI
!   field subroutine workflows.
!
! Type catalogue (4 TYPEs):
!   RT_Field_Desc   – Field configuration (active fields, dependencies)
!   RT_Field_State  – Field state (current values, history)
!   RT_Field_Algo   – Field algorithm (update strategy, smoothing)
!   RT_Field_Ctx    – Hot path context (field values at integration points)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!   USE IF_Err_Brg (ErrorStatusType, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE RT_XXX_Field_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Field_Desc
  PUBLIC :: RT_Field_State
  PUBLIC :: RT_Field_Algo
  PUBLIC :: RT_Field_Ctx
  
  !-- Field type constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_TYPE_SCALAR    = 1_i4  ! Scalar field
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_TYPE_VECTOR    = 2_i4  ! Vector field
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_TYPE_TENSOR    = 3_i4  ! Tensor field
  
  !-- Field source constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_SOURCE_USER    = 0_i4  ! User-defined (USDFLD)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_SOURCE_INITIAL = 1_i4  ! Initial condition (SDVINI)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_SOURCE_TABLE   = 2_i4  ! Table-based
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FIELD_SOURCE_ANALYTIC= 3_i4  ! Analytic function
  
  !-----------------------------------------------------------------------------
  ! RT_Field_Desc — Field configuration (cold, read-only)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Field_Desc
    !-- Identity & metadata
    INTEGER(i4) :: field_set_id = 0_i4
    CHARACTER(LEN=64) :: field_name = ''
    INTEGER(i4) :: field_type = RT_FIELD_TYPE_SCALAR
    INTEGER(i4) :: field_source = RT_FIELD_SOURCE_USER
    
    !-- Field declaration
    INTEGER(i4) :: nfields = 0_i4            ! Number of field variables
    INTEGER(i4) :: nstatev = 0_i4            ! Number of state variables
    
    !-- Active field set
    INTEGER(i4) :: n_active_fields = 0_i4
    INTEGER(i4), POINTER :: active_field_ids(:) => NULL()
    
    !-- Dependencies on other quantities
    LOGICAL :: depends_on_stress = .FALSE.   ! Field depends on stress
    LOGICAL :: depends_on_strain = .FALSE.   ! Field depends on strain
    LOGICAL :: depends_on_peeq = .FALSE.     ! Field depends on equivalent plastic strain
    LOGICAL :: depends_on_temp = .FALSE.     ! Field depends on temperature
    LOGICAL :: depends_on_time = .FALSE.     ! Field depends on time
    
    !-- Spatial distribution
    LOGICAL :: is_spatially_uniform = .TRUE. ! Uniform vs spatially varying
    LOGICAL :: requires_coords = .FALSE.     ! Needs spatial coordinates
    
    !-- Initial values
    REAL(wp), POINTER :: initial_values(:) => NULL()  ! [nfields]
  END TYPE RT_Field_Desc
  
  !-----------------------------------------------------------------------------
  ! RT_Field_State — Field state (warm, frequent updates)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Field_State
    !-- Current field values
    REAL(wp), POINTER :: field_values(:) => NULL()    ! [nfields] current values
    REAL(wp), POINTER :: field_values_old(:) => NULL() ! [nfields] previous increment
    
    !-- State variables (solution-dependent)
    REAL(wp), POINTER :: statev(:) => NULL()          ! [nstatev] state variables
    
    !-- Field rates (time derivatives)
    REAL(wp), POINTER :: field_rates(:) => NULL()     ! [nfields] d(field)/dt
    
    !-- Statistics
    REAL(wp) :: max_field_value = 0.0_wp
    REAL(wp) :: min_field_value = 0.0_wp
    REAL(wp) :: avg_field_value = 0.0_wp
    
    !-- Convergence tracking
    LOGICAL :: is_converged = .FALSE.      ! Field convergence flag
    REAL(wp) :: field_change_norm = 0.0_wp ! Norm of field change this increment
    
    !-- Update history
    INTEGER(i4) :: n_updates = 0_i4        ! Number of field updates
    REAL(wp) :: time_last_update = 0.0_wp  ! Last update time
  END TYPE RT_Field_State
  
  !-----------------------------------------------------------------------------
  ! RT_Field_Algo — Field algorithm (optional, cold)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Field_Algo
    !-- Update strategy
    INTEGER(i4) :: update_frequency = 1_i4  ! Update every N increments
    
    !-- Numerical stabilization
    LOGICAL :: use_smoothing = .FALSE.      ! Apply spatial smoothing
    REAL(wp) :: smoothing_radius = 0.0_wp   ! Smoothing radius [m]
    INTEGER(i4) :: smoothing_iterations = 1_i4
    
    !-- Rate limiting
    LOGICAL :: use_rate_limit = .FALSE.     ! Limit field rate of change
    REAL(wp) :: max_field_rate = 0.0_wp     ! Maximum d(field)/dt
    
    !-- Bounds enforcement
    LOGICAL :: enforce_bounds = .FALSE.     ! Enforce min/max bounds
    REAL(wp) :: field_min = -1.0e30_wp      ! Minimum allowed value
    REAL(wp) :: field_max =  1.0e30_wp      ! Maximum allowed value
    
    !-- Time integration
    INTEGER(i4) :: time_integration = 0_i4  ! 0=Explicit, 1=Implicit
    REAL(wp) :: numerical_damping = 0.0_wp  ! Damping for implicit schemes
    
    !-- Coupling with material
    LOGICAL :: update_material_state = .TRUE. ! Trigger material state update
    LOGICAL :: coupled_with_damage = .FALSE.  ! Coupled with damage evolution
  END TYPE RT_Field_Algo
  
  !-----------------------------------------------------------------------------
  ! RT_Field_Ctx — Hot path context (temporary, no dynamic allocation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Field_Ctx
    !-- Current increment data
    REAL(wp) :: time_current = 0.0_wp        ! Current time
    REAL(wp) :: time_increment = 0.0_wp      ! Time increment size
    INTEGER(i4) :: step_id = 0_i4            ! Current step number
    INTEGER(i4) :: inc_id = 0_i4             ! Current increment number
    
    !-- Integration point location
    REAL(wp) :: coords(3) = 0.0_wp           ! GP coordinates [m]
    INTEGER(i4) :: elem_id = 0_i4            ! Element number
    INTEGER(i4) :: gp_id = 0_i4              ! Gauss point number
    
    !-- Driving inputs (from solution)
    REAL(wp) :: stress(6) = 0.0_wp           ! Current stress [Pa]
    REAL(wp) :: stran(6) = 0.0_wp            ! Current strain
    REAL(wp) :: peeq = 0.0_wp                ! Equivalent plastic strain
    REAL(wp) :: temp = 0.0_wp                ! Temperature [K]
    
    !-- Material point state
    REAL(wp), POINTER :: statev(:) => NULL() ! State variables from material
    
    !-- Field output (to be computed)
    REAL(wp) :: field_output(10) = 0.0_wp    ! Computed field values (max 10)
    
    !-- GETVRM request flags (for USDFLD)
    LOGICAL :: req_stress = .FALSE.
    LOGICAL :: req_strain = .FALSE.
    LOGICAL :: req_peeq = .FALSE.
    LOGICAL :: req_triax = .FALSE.
    
    !-- Temporary work arrays (pre-allocated, 禁止 ALLOCATABLE)
    REAL(wp), POINTER :: temp_work1(:) => NULL()
    REAL(wp), POINTER :: temp_work2(:) => NULL()
  END TYPE RT_Field_Ctx
  
  !-----------------------------------------------------------------------------
  ! Standalone procedures for RT_Field_Desc manipulation (cold path)
  !-----------------------------------------------------------------------------
  PUBLIC :: RT_Field_Desc_Init
  PUBLIC :: RT_Field_Desc_SetActiveFields
  PUBLIC :: RT_Field_Desc_AddField
  PUBLIC :: RT_Field_Desc_Finalize
  
CONTAINS
  
  SUBROUTINE RT_Field_Desc_Init(desc, st)
    TYPE(RT_Field_Desc), INTENT(OUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! Initialize descriptor with default values
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Field_Desc_Init
  
  SUBROUTINE RT_Field_Desc_SetActiveFields(desc, n_active, active_ids, st)
    TYPE(RT_Field_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: n_active
    INTEGER(i4), INTENT(IN) :: active_ids(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    desc%n_active_fields = n_active
    ! TODO: implement active field set logic
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Field_Desc_SetActiveFields
  
  SUBROUTINE RT_Field_Desc_AddField(desc, field_id, initial_value, st)
    TYPE(RT_Field_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: field_id
    REAL(wp), INTENT(IN) :: initial_value
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! TODO: implement field addition logic
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Field_Desc_AddField
  
  SUBROUTINE RT_Field_Desc_Finalize(desc, st)
    TYPE(RT_Field_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! Mark descriptor as ready for field computation
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Field_Desc_Finalize
  
END MODULE RT_XXX_Field_Types