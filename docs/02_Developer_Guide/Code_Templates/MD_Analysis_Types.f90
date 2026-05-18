!===============================================================================
! Module: MD_Analysis_Types                                      [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Analysis Control — Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc / State / Algo three-type system for analysis control
!   at the MD_ (model-description) layer.
!
!   Abaqus subroutines covered:
!     - UEXTERNALDB   : External database management (called at analysis events)
!     - UAMP / VUAMP  : User-defined amplitude (Standard/Explicit)
!     - UVARM         : User-defined output variables
!     - UPRINT        : User-defined print output
!     - URDFIL        : User-defined results file reading
!
!   Design notes:
!     - UEXTERNALDB is called at key analysis events (start, end, step)
!       for external database coupling (e.g. FIRE, CFD, Python co-simulation)
!     - UAMP/VUAMP define time-history amplitude functions for loads/BCs
!     - UVARM defines custom output variables computed from state variables
!
! Type roles:
!   MD_Analy_Base_Desc  – Analysis control parameters (loaded from INP)
!   MD_Analy_Base_State – Analysis state at increment start
!   MD_Analy_Base_Algo  – Analysis configuration
!   MD_Analy_UAMP_Desc  – UAMP/VUAMP-specific: amplitude definition
!   MD_Analy_UVARM_Desc – UVARM-specific: output variable definition
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Analysis_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Analy_Base_Desc
  PUBLIC :: MD_Analy_Base_State
  PUBLIC :: MD_Analy_Base_Algo
  PUBLIC :: MD_Analy_UAMP_Desc
  PUBLIC :: MD_Analy_UVARM_Desc
  PUBLIC :: MD_Analy_UEXTERNALDB_Desc

  !-- Analysis control subroutine type enum
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ANALY_ANALY_SUBRT_UEXTERNALDB = 1_i4  ! UEXTERNALDB
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ANALY_ANALY_SUBRT_UAMP        = 2_i4  ! UAMP  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ANALY_ANALY_SUBRT_VUAMP       = 3_i4  ! VUAMP (Explicit)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ANALY_ANALY_SUBRT_UVARM       = 4_i4  ! UVARM  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ANALY_ANALY_SUBRT_UPRINT      = 5_i4  ! UPRINT  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_ANALY_ANALY_SUBRT_URDFIL      = 6_i4  ! URDFIL  ! migrated

  !-- UEXTERNALDB event type (LOP parameter)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_UEXTDB_UEXTDB_LOP_START  = 0_i4  ! LOP=0: start of analysis  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_UEXTDB_UEXTDB_LOP_INCR   = 1_i4  ! LOP=1: start of increment  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_UEXTDB_UEXTDB_LOP_END    = 2_i4  ! LOP=2: end of analysis  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_UEXTDB_UEXTDB_LOP_STEP   = 3_i4  ! LOP=3: start of new step  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_UEXTDB_UEXTDB_LOP_RECOV  = 4_i4  ! LOP=4: restart recovery  ! migrated

  !-----------------------------------------------------------------------------
  ! DESC — Analysis Control Descriptor
  !    Analysis-wide settings and configuration.
  !    UEXTERNALDB signature: LOP, LRESTART, TIME(2), DTIME, KSTEP, KINC
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_Base_Desc
    !-- Identity & metadata
    INTEGER(i4)       :: analy_id    = 0_i4   ! Analysis control set ID
    INTEGER(i4)       :: subrt_type  = MD_ANALY_ANALY_SUBRT_UEXTERNALDB
    CHARACTER(LEN=64) :: analy_name  = ''     ! Human-readable label
    LOGICAL           :: is_initialized = .FALSE.
    !-- Analysis type flags
    INTEGER(i4) :: analysis_proc   = 1_i4    ! 1=static, 2=dynamic, 3=thermal
    LOGICAL     :: is_restart      = .FALSE. ! Restart analysis
    LOGICAL     :: is_coupled      = .FALSE. ! Coupled field analysis
    !-- External database configuration (UEXTERNALDB)
    CHARACTER(LEN=256) :: ext_db_path = '' ! External DB file path
    INTEGER(i4) :: ext_db_unit       = 0_i4 ! Fortran unit number for ext DB
    !-- Output frequency
    INTEGER(i4) :: output_freq      = 1_i4   ! Output every N increments
  CONTAINS
    PROCEDURE :: Init  => Analy_Desc_Init
  END TYPE MD_Analy_Base_Desc

  !-----------------------------------------------------------------------------
  ! STATE — Analysis State at Increment Start
  !    Analysis progress and external database state.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_Base_State
    !-- Analysis progress
    INTEGER(i4) :: lop           = 0_i4   ! Current LOP flag (UEXTERNALDB event)
    INTEGER(i4) :: lrestart      = 0_i4   ! Restart flag
    REAL(wp)    :: cpu_time_used = 0.0_wp ! CPU time consumed [s]
    !-- External database state
    LOGICAL     :: ext_db_open   = .FALSE. ! External DB is open
    INTEGER(i4) :: ext_db_ncall  = 0_i4   ! Number of UEXTERNALDB calls
    !-- Convergence bookkeeping
    LOGICAL     :: converged     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Analy_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Analysis Configuration
  !    Solver configuration and output options.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_Base_Algo
    !-- Solver type
    INTEGER(i4) :: solver_type   = 1_i4   ! 1=direct, 2=iterative
    INTEGER(i4) :: max_iter_glob = 100_i4 ! Global Newton iterations
    REAL(wp)    :: tol_res       = 1.0e-3_wp ! Residual convergence tolerance
    !-- Time integration
    REAL(wp)    :: dt_initial    = 0.01_wp  ! Initial time increment
    REAL(wp)    :: dt_min        = 1.0e-8_wp ! Minimum time increment
    REAL(wp)    :: dt_max        = 1.0_wp    ! Maximum time increment
    !-- External coupling
    LOGICAL     :: use_co_sim    = .FALSE.  ! Co-simulation active
    !-- Output
    LOGICAL :: print_debug       = .FALSE.
  END TYPE MD_Analy_Base_Algo

  !-----------------------------------------------------------------------------
  ! UAMP/VUAMP-specific Desc: amplitude definition
  !   UAMP/VUAMP: user-defined amplitude for time-dependent loads/BCs
  !   UAMP signature: AMPNAME, TIME(2), AMPVALUEOLD, dAMPValue, LFLAGS(5), NPROPS, PROPS
  !   Returns: AMPVALUE (amplitude value at current time)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_UAMP_Desc
    CHARACTER(LEN=80) :: amp_name   = ''      ! Amplitude name (AMPNAME)
    INTEGER(i4) :: amp_type          = 1_i4   ! 1=smooth step, 2=tabular, 3=equation
    REAL(wp)    :: amp_ref           = 1.0_wp  ! Reference amplitude value
    INTEGER(i4) :: nprops            = 0_i4   ! Number of amplitude properties
    REAL(wp), ALLOCATABLE :: props(:)          ! PROPS array
    LOGICAL     :: is_explicit       = .FALSE. ! .TRUE. for VUAMP (Explicit)
    !-- Tabular amplitude data (if amp_type=2)
    INTEGER(i4) :: n_table_pts       = 0_i4   ! Points in tabular amplitude
    REAL(wp), ALLOCATABLE :: t_table(:)        ! Time values [s]
    REAL(wp), ALLOCATABLE :: a_table(:)        ! Amplitude values
  END TYPE MD_Analy_UAMP_Desc

  !-----------------------------------------------------------------------------
  ! UVARM-specific Desc: user-defined output variables
  !   UVARM: computes UVAR(NUVARM) at each material point for output
  !   Signature: UVAR(NUVARM), FIELD(NFIELD), PG(NBLOCK), etc.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_UVARM_Desc
    INTEGER(i4) :: nuvarm      = 0_i4    ! Number of user output variables
    CHARACTER(LEN=80), ALLOCATABLE :: var_names(:) ! Variable names [nuvarm]
    INTEGER(i4) :: output_type = 1_i4    ! 1=scalar, 2=vector, 3=tensor
    CHARACTER(LEN=80) :: cmname = ''     ! Material name for dispatch
  END TYPE MD_Analy_UVARM_Desc

  !-----------------------------------------------------------------------------
  ! UEXTERNALDB-specific Desc: external database coupling
  !   Called at key analysis events (start, end, step, increment)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Analy_UEXTERNALDB_Desc
    CHARACTER(LEN=256) :: db_path  = ' '
    LOGICAL            :: write_at_end = .TRUE.
    LOGICAL            :: write_at_restart = .FALSE.
    LOGICAL            :: is_active = .FALSE.
  END TYPE MD_Analy_UEXTERNALDB_Desc

CONTAINS

  SUBROUTINE Analy_Desc_Init(self)
    CLASS(MD_Analy_Base_Desc), INTENT(INOUT) :: self
    self%is_initialized = .TRUE.
  END SUBROUTINE Analy_Desc_Init

END MODULE MD_Analysis_Types
