!===============================================================================
! Module: RT_XXX_StepDriver_Types                                  [Template v1.0]
! Layer:  L5_RT — Runtime Layer
! Domain: StepDriver — Analysis step execution control
!
! Purpose:
!   Defines types for analysis step driver with automatic time stepping (ATS),
!   Newton-Raphson iteration, and cutback logic. Supports Static/Implicit/Explicit
!   analysis categories.
!
! Type catalogue (4 TYPEs):
!   RT_SD_Desc    – Step configuration (time params, category, solver ID)
!   RT_SD_State   – Step progress (current inc/iter, time, load factor, converged)
!   RT_SD_Algo    – ATS/NR parameters (tolerances, max_iter, cutback strategy)
!   RT_SD_Ctx     – Hot path context (work arrays, physics feedback pnewdt)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!   USE IF_Err_Brg (ErrorStatusType, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE RT_XXX_StepDriver_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_SD_Desc
  PUBLIC :: RT_SD_State
  PUBLIC :: RT_SD_Algo
  PUBLIC :: RT_SD_Ctx
  PUBLIC :: RT_SD_Result
  
  !-- Step category constants
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_CAT_STD  = 1_i4  ! Static/General
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_CAT_IMPL = 2_i4  ! Implicit Dynamics
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_CAT_EXPL = 3_i4  ! Explicit Dynamics
  
  !-- Convergence mode constants
  INTEGER(i4), PARAMETER, PUBLIC :: CONV_MODE_RESIDUAL  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: CONV_MODE_DISPL     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: CONV_MODE_ENERGY    = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: CONV_MODE_COMBINED  = 4_i4
  
  !-- Cutback reason constants
  INTEGER(i4), PARAMETER, PUBLIC :: CUTBACK_NONE       = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: CUTBACK_NONCONV    = 1_i4  ! Non-convergence
  INTEGER(i4), PARAMETER, PUBLIC :: CUTBACK_PHYSICS    = 2_i4  ! Physics signal
  INTEGER(i4), PARAMETER, PUBLIC :: CUTBACK_USER       = 3_i4  ! User request
  
  !-----------------------------------------------------------------------------
  ! RT_SD_Desc — Step configuration (cold, read-only)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_SD_Desc
    !-- Identity & metadata
    INTEGER(i4) :: step_idx = 0_i4           ! Step index in analysis
    INTEGER(i4) :: step_id = 0_i4            ! Unique step ID
    INTEGER(i4) :: category = STEP_CAT_STD   ! Step category
    CHARACTER(LEN=64) :: name = ''           ! Human-readable label
    
    !-- Time configuration
    REAL(wp) :: t_start = 0.0_wp             ! Step start time [s]
    REAL(wp) :: t_end = 1.0_wp               ! Step end time [s]
    REAL(wp) :: dt_init = 0.1_wp             ! Initial time increment [s]
    REAL(wp) :: dt_min = 1.0e-20_wp          ! Minimum time increment [s]
    REAL(wp) :: dt_max = 1.0_wp              ! Maximum time increment [s]
    
    !-- Target iterations (for ATS optimization)
    INTEGER(i4) :: target_iter = 6_i4        ! Optimal NR iterations per inc
    
    !-- Reference to solver configuration
    INTEGER(i4) :: solver_config_id = 0_i4   ! Links to RT_Solver_Types
    
    !-- Flags
    LOGICAL :: nlgeom = .FALSE.              ! Include geometric nonlinearity
    LOGICAL :: use_line_search = .FALSE.     ! Enable line search
  END TYPE RT_SD_Desc
  
  !-----------------------------------------------------------------------------
  ! RT_SD_State — Step progress (warm, frequent updates)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_SD_State
    !-- Current position
    INTEGER(i4) :: current_inc = 0_i4        ! Current increment number
    INTEGER(i4) :: current_iter = 0_i4       ! Current NR iteration
    REAL(wp) :: current_time = 0.0_wp        ! Current time [s]
    REAL(wp) :: current_load_factor = 0.0_wp ! Load proportioning factor
    
    !-- Statistics this step
    INTEGER(i4) :: total_increments = 0_i4   ! Completed increments
    INTEGER(i4) :: total_iterations = 0_i4   ! Total NR iterations
    INTEGER(i4) :: total_cutbacks = 0_i4     ! Cutbacks this step
    
    !-- Convergence status
    LOGICAL :: converged = .FALSE.           ! Current increment converged
    LOGICAL :: step_complete = .FALSE.       ! Step finished
    
    !-- Last successful state (for cutback restart)
    REAL(wp) :: last_successful_time = 0.0_wp
    INTEGER(i4) :: last_successful_inc = 0_i4
  END TYPE RT_SD_State
  
  !-----------------------------------------------------------------------------
  ! RT_SD_Algo — Algorithm parameters (optional, cold)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_SD_Algo
    !-- Convergence tolerances
    REAL(wp) :: tol_residual = 1.0e-5_wp     ! Residual convergence tolerance
    REAL(wp) :: tol_displ = 1.0e-3_wp        ! Displacement convergence tolerance
    REAL(wp) :: energy_tol = 1.0e-4_wp       ! Energy convergence tolerance
    
    !-- Iteration limits
    INTEGER(i4) :: max_iter = 100_i4         ! Maximum NR iterations
    INTEGER(i4) :: min_iter = 2_i4           ! Minimum before checking conv
    
    !-- Convergence criterion
    INTEGER(i4) :: conv_mode = CONV_MODE_COMBINED
    
    !-- Automatic time stepping (ATS)
    LOGICAL :: auto_dt = .TRUE.              ! Enable ATS
    REAL(wp) :: grow_factor = 1.5_wp         ! Δt expansion factor (n_iter < target)
    REAL(wp) :: cutback_factor = 0.25_wp     ! Δt reduction factor (non-convergence)
    
    !-- Line search
    INTEGER(i4) :: max_ls_iter = 10_i4       ! Max line search iterations
    REAL(wp) :: ls_tolerance = 1.0e-4_wp     ! Line search tolerance
    
    !-- Stabilization
    LOGICAL :: use_stabilization = .FALSE.   ! Numerical damping
    REAL(wp) :: stabilization_param = 0.0_wp ! Damping parameter
  END TYPE RT_SD_Algo
  
  !-----------------------------------------------------------------------------
  ! RT_SD_Ctx — Hot path context (temporary, no dynamic allocation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_SD_Ctx
    !-- Vector/matrix pointers (reference to global memory pool)
    REAL(wp), POINTER :: u_trial(:) => NULL()    ! Trial solution vector
    REAL(wp), POINTER :: rhs(:) => NULL()        ! Global RHS vector
    REAL(wp), POINTER :: du(:) => NULL()         ! Displacement increment
    
    !-- Work arrays (pre-allocated, 禁止 ALLOCATABLE)
    REAL(wp), POINTER :: temp_vec1(:) => NULL()
    REAL(wp), POINTER :: temp_vec2(:) => NULL()
    
    !-- Current increment data
    REAL(wp) :: dt_current = 0.0_wp              ! Current time increment
    REAL(wp) :: dt_proposed = 0.0_wp             ! Proposed next increment
    
    !-- Physics feedback from domains
    REAL(wp) :: pnewdt_physics = 1.0_wp          ! Min pnewdt from Mat/Elem/Field
    INTEGER(i4) :: cutback_reason = CUTBACK_NONE
    
    !-- Iteration output
    LOGICAL :: iteration_success = .TRUE.
    INTEGER(i4) :: conv_result = 0_i4            ! 0=NO, 1=YES, 2=CUTBACK
    
    !-- Timing
    REAL(wp) :: cpu_time_start = 0.0_wp
    REAL(wp) :: cpu_time_elapsed = 0.0_wp
  END TYPE RT_SD_Ctx
  
  !-----------------------------------------------------------------------------
  ! RT_SD_Result — Output summary (not part of four-type system)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_SD_Result
    LOGICAL :: success = .FALSE.
    LOGICAL :: converged = .FALSE.
    INTEGER(i4) :: total_increments = 0_i4
    INTEGER(i4) :: total_iterations = 0_i4
    INTEGER(i4) :: total_cutbacks = 0_i4
    REAL(wp) :: final_time = 0.0_wp
    REAL(wp) :: final_load_factor = 0.0_wp
    REAL(wp) :: cpu_time = 0.0_wp
    CHARACTER(LEN=512) :: message = ''
  END TYPE RT_SD_Result
  
  !-----------------------------------------------------------------------------
  ! Standalone procedures for RT_SD_Desc manipulation (cold path)
  !-----------------------------------------------------------------------------
  PUBLIC :: RT_SD_Desc_Init
  PUBLIC :: RT_SD_Desc_SetTimeParams
  PUBLIC :: RT_SD_Desc_SetCategory
  PUBLIC :: RT_SD_Desc_Finalize
  
CONTAINS
  
  SUBROUTINE RT_SD_Desc_Init(desc, st)
    TYPE(RT_SD_Desc), INTENT(OUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! Initialize descriptor with default values
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_SD_Desc_Init
  
  SUBROUTINE RT_SD_Desc_SetTimeParams(desc, t_start, t_end, dt_init, dt_min, dt_max, st)
    TYPE(RT_SD_Desc), INTENT(INOUT) :: desc
    REAL(wp), INTENT(IN) :: t_start, t_end, dt_init, dt_min, dt_max
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    desc%t_start = t_start
    desc%t_end = t_end
    desc%dt_init = dt_init
    desc%dt_min = dt_min
    desc%dt_max = dt_max
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_SD_Desc_SetTimeParams
  
  SUBROUTINE RT_SD_Desc_SetCategory(desc, category, st)
    TYPE(RT_SD_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: category
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    desc%category = category
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_SD_Desc_SetCategory
  
  SUBROUTINE RT_SD_Desc_Finalize(desc, st)
    TYPE(RT_SD_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! Mark descriptor as ready for step execution
    st%status_code = IF_STATUS_OK
  END SUBROUTINE RT_SD_Desc_Finalize
  
END MODULE RT_XXX_StepDriver_Types