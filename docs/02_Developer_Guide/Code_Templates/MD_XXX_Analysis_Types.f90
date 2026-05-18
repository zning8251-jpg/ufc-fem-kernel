!===============================================================================
! Module: MD_XXX_Analysis_Types                                   [Template v2.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Analysis Control — Aggregates Step/Solver/Amplitude domains
!
! Purpose:
!   Defines the four-category TYPE system (Desc/State/Algo/Ctx) for
!   analysis-level control at the MD_ layer. This is the top-level
!   aggregator that coordinates Step, Solver, and Amplitude domains.
!
!   Abaqus subroutines covered:
!     - UEXTERNALDB   : External database management
!     - UAMP / VUAMP  : User-defined amplitude
!     - UVARM         : User-defined output variables
!     - UPRINT        : Custom print output
!     - URDFIL        : Results file reading
!
! Type roles:
!   MD_Analy_Desc   — Analysis configuration (step sequence, solver chain)
!   MD_Analy_State  — Global analysis progress
!   MD_Analy_Algo   — Analysis-wide algorithms (co-simulation, restart)
!   MD_Analy_Ctx    — Hot path context for event-driven calls
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!   USE MD_Step_Types  (MD_Step_Desc, MD_Step_State)
!   USE MD_Solver_Types (MD_Solver_Desc, MD_Solver_State)
!   USE MD_Amplitude_Types (MD_Amp_Desc, MD_Amp_State)
!===============================================================================
MODULE MD_XXX_Analysis_Types
  USE IF_Prec_Core,              ONLY: wp, i4
  USE IF_Err_Brg,           ONLY: ErrorStatusType, init_error_status, &
                                   IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Step_Types,        ONLY: MD_Step_Desc, MD_Step_State
  USE MD_Solver_Types,      ONLY: MD_Solver_Desc, MD_Solver_State
  USE MD_Amplitude_Types,   ONLY: MD_Amp_Desc, MD_Amp_State
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: MD_Analy_Desc
  PUBLIC :: MD_Analy_State
  PUBLIC :: MD_Analy_Algo
  PUBLIC :: MD_Analy_Ctx
  PUBLIC :: MD_Analy_UAMP_Desc
  PUBLIC :: MD_Analy_UVARM_Desc
  
  !-- Analysis control subroutine type enum
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_SUBRT_UEXTERNALDB  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_SUBRT_UAMP         = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_SUBRT_VUAMP        = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_SUBRT_UVARM        = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_SUBRT_UPRINT       = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: ANALY_SUBRT_URDFIL       = 6_i4
  
  !-- UEXTERNALDB event type (LOP parameter)
  INTEGER(i4), PARAMETER, PUBLIC :: UEVTDB_LOP_START        = 0_i4  ! Start of analysis
  INTEGER(i4), PARAMETER, PUBLIC :: UEVTDB_LOP_INCR         = 1_i4  ! Start of increment
  INTEGER(i4), PARAMETER, PUBLIC :: UEVTDB_LOP_END          = 2_i4  ! End of analysis
  INTEGER(i4), PARAMETER, PUBLIC :: UEVTDB_LOP_STEP         = 3_i4  ! Start of new step
  INTEGER(i4), PARAMETER, PUBLIC :: UEVTDB_LOP_RECOV        = 4_i4  ! Restart recovery
  
  !-----------------------------------------------------------------------------
  ! MD_Analy_Desc — Analysis configuration (cold, write-once)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_Desc
    !-- Identity & metadata
    CHARACTER(LEN=64) :: analy_name = ''
    INTEGER(i4) :: analy_id = 0_i4
    LOGICAL :: is_initialized = .FALSE.
    
    !-- Analysis type flags
    INTEGER(i4) :: analysis_proc = 1_i4    ! 1=Static, 2=Dynamic, 3=Thermal
    LOGICAL :: is_restart = .FALSE.        ! Restart analysis
    LOGICAL :: is_coupled = .FALSE.        ! Coupled field (CFD/structural)
    LOGICAL :: nlgeom = .FALSE.            ! Large deformation
    
    !-- Step sequence reference
    INTEGER(i4) :: n_steps = 0_i4
    INTEGER(i4), POINTER :: step_ids(:) => NULL()
    
    !-- Solver chain reference
    INTEGER(i4) :: n_solvers = 0_i4
    INTEGER(i4), POINTER :: solver_config_ids(:) => NULL()
    
    !-- Amplitude set reference
    INTEGER(i4) :: n_amplitudes = 0_i4
    INTEGER(i4), POINTER :: amplitude_ids(:) => NULL()
    
    !-- External database configuration
    CHARACTER(LEN=256) :: ext_db_path = ''
    INTEGER(i4) :: ext_db_unit = 0_i4
    
    !-- Output frequency
    INTEGER(i4) :: output_freq = 1_i4      ! Output every N increments
    INTEGER(i4) :: print_level = 1_i4      ! 0=None, 1=Summary, 2=Full
  END TYPE MD_Analy_Desc
  
  !-----------------------------------------------------------------------------
  ! MD_Analy_State — Analysis progress state (warm, frequent updates)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_State
    !-- Analysis progress
    INTEGER(i4) :: current_step_idx = 0_i4
    INTEGER(i4) :: current_inc = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
    REAL(wp) :: current_time = 0.0_wp
    REAL(wp) :: total_time = 0.0_wp
    
    !-- Event tracking
    INTEGER(i4) :: current_event = UEVTDB_LOP_START
    INTEGER(i4) :: n_events_processed = 0_i4
    
    !-- CPU time tracking
    REAL(wp) :: cpu_time_used = 0.0_wp
    REAL(wp) :: cpu_time_start = 0.0_wp
    
    !-- Convergence bookkeeping
    LOGICAL :: global_converged = .FALSE.
    INTEGER(i4) :: failed_steps = 0_i4
    INTEGER(i4) :: total_cutbacks = 0_i4
    
    !-- External database state
    LOGICAL :: ext_db_open = .FALSE.
    INTEGER(i4) :: ext_db_ncall = 0_i4
    
    !-- Status
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Analy_State
  
  !-----------------------------------------------------------------------------
  ! MD_Analy_Algo — Analysis algorithm parameters (optional, cold)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_Algo
    !-- Solver configuration
    INTEGER(i4) :: solver_type = 1_i4      ! 1=Direct, 2=Iterative
    INTEGER(i4) :: max_iter_global = 100_i4
    REAL(wp) :: tol_residual = 1.0e-5_wp
    REAL(wp) :: tol_energy = 1.0e-4_wp
    
    !-- Time integration control
    REAL(wp) :: dt_initial = 0.01_wp
    REAL(wp) :: dt_min = 1.0e-8_wp
    REAL(wp) :: dt_max = 1.0_wp
    LOGICAL :: auto_time_stepping = .TRUE.
    
    !-- Restart control
    LOGICAL :: restart_write = .FALSE.
    INTEGER(i4) :: restart_freq = 0_i4     ! 0=No restart
    CHARACTER(LEN=256) :: restart_file = ''
    
    !-- Co-simulation control
    LOGICAL :: use_co_simulation = .FALSE.
    REAL(wp) :: co_sim_tolerance = 1.0e-6_wp
    INTEGER(i4) :: co_sim_max_iter = 10_i4
    
    !-- Debug options
    LOGICAL :: debug_print = .FALSE.
    LOGICAL :: debug_timing = .FALSE.
  END TYPE MD_Analy_Algo
  
  !-----------------------------------------------------------------------------
  ! MD_Analy_Ctx — Hot path context (temporary, no allocation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_Ctx
    !-- Current event context
    INTEGER(i4) :: event_type = 0_i4
    REAL(wp) :: event_time = 0.0_wp
    REAL(wp) :: event_dtime = 0.0_wp
    INTEGER(i4) :: event_kstep = 0_i4
    INTEGER(i4) :: event_kinc = 0_i4
    
    !-- Amplitude evaluation context
    REAL(wp) :: amp_time = 0.0_wp
    REAL(wp) :: amp_value = 0.0_wp
    REAL(wp) :: amp_rate = 0.0_wp
    
    !-- UVARM evaluation context
    REAL(wp) :: uvarm_coords(3) = 0.0_wp
    REAL(wp) :: uvarm_stress(6) = 0.0_wp
    REAL(wp) :: uvarm_stran(6) = 0.0_wp
    INTEGER(i4) :: uvarm_block = 0_i4
    
    !-- Work variables (禁止 ALLOCATABLE)
    REAL(wp) :: temp_scalar = 0.0_wp
    REAL(wp) :: work_array(10) = 0.0_wp
    INTEGER(i4) :: work_ints(5) = 0_i4
    
    !-- Cached pointers (reference to global pool)
    REAL(wp), POINTER :: u_trial(:) => NULL()
    REAL(wp), POINTER :: f_ext(:) => NULL()
  END TYPE MD_Analy_Ctx
  
  !-----------------------------------------------------------------------------
  ! UAMP/VUAMP-specific Desc: amplitude definition
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_UAMP_Desc
    CHARACTER(LEN=80) :: amp_name = ''
    INTEGER(i4) :: amp_type = 1_i4       ! 1=Smooth, 2=Tabular, 3=Equation
    REAL(wp) :: amp_ref = 1.0_wp
    INTEGER(i4) :: nprops = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    LOGICAL :: is_explicit = .FALSE.     ! .TRUE. for VUAMP
    
    !-- Tabular amplitude data
    INTEGER(i4) :: n_table_pts = 0_i4
    REAL(wp), ALLOCATABLE :: t_table(:)
    REAL(wp), ALLOCATABLE :: a_table(:)
    
    !-- Equation-based amplitude
    CHARACTER(LEN=256) :: equation = ''
  END TYPE MD_Analy_UAMP_Desc
  
  !-----------------------------------------------------------------------------
  ! UVARM-specific Desc: user-defined output variables
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_UVARM_Desc
    INTEGER(i4) :: nuvarm = 0_i4
    CHARACTER(LEN=80), ALLOCATABLE :: var_names(:)
    INTEGER(i4) :: output_type = 1_i4    ! 1=Scalar, 2=Vector, 3=Tensor
    CHARACTER(LEN=80) :: cmname = ''
    LOGICAL :: depends_on_state = .FALSE.
    INTEGER(i4) :: nstatev = 0_i4
  END TYPE MD_Analy_UVARM_Desc
  
  !-----------------------------------------------------------------------------
  ! Standalone procedures for MD_Analy_Desc manipulation (cold path)
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Analy_Desc_Init
  PUBLIC :: MD_Analy_Desc_AddStep
  PUBLIC :: MD_Analy_Desc_AddSolver
  PUBLIC :: MD_Analy_Desc_Finalize
  PUBLIC :: MD_Analy_WriteBack
  
CONTAINS
  
  SUBROUTINE MD_Analy_Desc_Init(desc, st)
    TYPE(MD_Analy_Desc), INTENT(OUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Analy_Desc_Init
  
  SUBROUTINE MD_Analy_Desc_AddStep(desc, step_id, st)
    TYPE(MD_Analy_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: step_id
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! Add step reference to analysis descriptor
    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Analy_Desc_AddStep
  
  SUBROUTINE MD_Analy_Desc_AddSolver(desc, solver_config_id, st)
    TYPE(MD_Analy_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: solver_config_id
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    ! Add solver config reference
    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Analy_Desc_AddSolver
  
  SUBROUTINE MD_Analy_Desc_Finalize(desc, st)
    TYPE(MD_Analy_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    CALL init_error_status(st)
    ! Clean up if needed
    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Analy_Desc_Finalize
  
  SUBROUTINE MD_Analy_WriteBack(state, event, time, kstep, kinc, cpu_time, st)
    TYPE(MD_Analy_State), INTENT(INOUT) :: state
    INTEGER(i4), INTENT(IN) :: event
    REAL(wp), INTENT(IN) :: time
    INTEGER(i4), INTENT(IN) :: kstep, kinc
    REAL(wp), INTENT(IN), OPTIONAL :: cpu_time
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    
    CALL init_error_status(st)
    state%current_event = event
    state%current_time = time
    state%current_kstep = kstep
    state%current_kinc = kinc
    IF (PRESENT(cpu_time)) state%cpu_time_used = cpu_time
    state%n_events_processed = state%n_events_processed + 1_i4
    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Analy_WriteBack
  
END MODULE MD_XXX_Analysis_Types