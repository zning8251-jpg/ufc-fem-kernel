!===============================================================================
! Module: MD_Step_Types                                          [Template v1.1]
! Layer:  L3_MD — Model Description Layer
! Domain: Step — Analysis step / increment / time-control descriptors
!
! Purpose:
!   Defines Desc and Algo types for the Step domain at the MD layer.
!   A "step" corresponds to one *STEP block in an Abaqus input deck.
!   Each step carries a procedure family (STATIC/DYNAMIC/HEAT_TRANSFER/etc.),
!   time-period, increment parameters, and tolerances.
!
! v1.1 (template QA): MD_STEP_* / MD_STEP_NLGEOM_* (no RT_* or bare STEP_PROC_*);
!   IF_STATUS_OK/IF_STATUS_INVALID; MD_Step_Registry%steps ALLOCATABLE for F2003.
!   Structured-status baseline: comments now reference init_error_status,
!   IF_STATUS_*, IF_ERROR_CODE_*, and %status_code.
!
! Type catalogue (5 TYPEs):
!   MD_Step_Base_Desc    – Core step descriptor (period, proc family, nlgeom)
!   MD_Step_Inc_Desc     – Increment control parameters (initial/min/max dt)
!   MD_Step_Static_Desc  – Static-procedure extension (stabilise, nlgeom)
!   MD_Step_Dynamic_Desc – Implicit-dynamic extension (alpha, beta, gamma)
!   MD_Step_Registry     – Ordered container of steps for the full analysis
!
! Step procedure family constants (MD_STEP_PROC_*), numeric ids 1..8:
!   MD_STEP_PROC_STATIC … MD_STEP_PROC_MODAL (see PARAMETER block below).
! Nlgeom flag: MD_STEP_NLGEOM_OFF / MD_STEP_NLGEOM_ON
!
! Layer dependency:
!   USE IF_Prec     (wp, i4)
!   USE IF_Err_Brg  (ErrorStatusType + standard bridge vocabulary:
!                   init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Step_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Step_Base_Desc
  PUBLIC :: MD_Step_Inc_Desc
  PUBLIC :: MD_Step_Static_Desc
  PUBLIC :: MD_Step_Dynamic_Desc
  PUBLIC :: MD_Step_Registry

  !-- Step procedure family (L3_MD; align with MD_Step_Domain_Types)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_STATIC       = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_DYNAMIC_IMP  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_DYNAMIC_EXP  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_HEAT_XFER    = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_COUPLED_TE    = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_GEOSTATIC    = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_SOILS        = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_MODAL        = 8_i4

  !-- Nlgeom flag (integer code on MD_Step_Base_Desc%nlgeom)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_NLGEOM_OFF = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_NLGEOM_ON  = 1_i4

  !-----------------------------------------------------------------------------
  ! MD_Step_Base_Desc — Core step descriptor
  !   Corresponds to the *STEP / *STATIC / *DYNAMIC header.
  !   Immutable during execution; read from INP at model-data load time.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Base_Desc
    !-- Identification
    INTEGER(i4)       :: step_id       = 0     ! Sequential step number (≥1)
    CHARACTER(LEN=80) :: step_name     = ''    ! User-supplied label

    !-- Procedure family
    INTEGER(i4) :: proc_family   = MD_STEP_PROC_STATIC
    INTEGER(i4) :: nlgeom        = MD_STEP_NLGEOM_OFF

    !-- Time domain
    REAL(wp) :: time_period      = 1.0_wp   ! Total step time [s or user units]
    REAL(wp) :: time_start       = 0.0_wp   ! Accumulated time at step start

    !-- Restart / continuation flags
    LOGICAL :: is_perturbation   = .FALSE.  ! Perturbation step (linear)
    LOGICAL :: is_restart        = .FALSE.  ! Step restored from restart file

    !-- Convergence controls
    REAL(wp) :: max_creep_strain_inc = 1.0e-3_wp  ! Max creep strain per increment
    REAL(wp) :: cetol              = 0.0_wp        ! Creep strain error tolerance

    !-- Initialization guard
    LOGICAL :: is_initialized = .FALSE.

  CONTAINS
    PROCEDURE :: Init     => Step_Base_Init
    PROCEDURE :: Validate => Step_Base_Validate
  END TYPE MD_Step_Base_Desc

  !-----------------------------------------------------------------------------
  ! MD_Step_Inc_Desc — Increment control parameters
  !   Corresponds to the *STATIC / *DYNAMIC time-increment data lines.
  !   Controls the automatic-increment (AI) algorithm in L5_RT.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Inc_Desc
    REAL(wp) :: dt_init   = 0.01_wp    ! Initial time increment [step-time units]
    REAL(wp) :: dt_min    = 1.0e-8_wp  ! Minimum allowable increment
    REAL(wp) :: dt_max    = 1.0_wp     ! Maximum allowable increment
    INTEGER(i4) :: max_incs = 100_i4   ! Max number of increments

    !-- Cutback parameters
    INTEGER(i4) :: max_cutbacks    = 5_i4    ! Max cut-backs per increment
    REAL(wp)    :: cutback_factor  = 0.25_wp ! dt multiplier on cutback

    !-- Expansion factor (pnewdt > 1 amplification cap)
    REAL(wp) :: expand_factor = 1.5_wp  ! Max multiplier when pnewdt > 1

    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Step_Inc_Desc

  !-----------------------------------------------------------------------------
  ! MD_Step_Static_Desc — Static-procedure extension fields
  !   Extends MD_Step_Base_Desc semantically for *STATIC procedures.
  !   Carries stabilisation and arc-length parameters.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Static_Desc
    !-- Stabilisation (*STATIC, STABILIZE=)
    LOGICAL  :: use_stabilize       = .FALSE.
    REAL(wp) :: stabilize_factor    = 2.0e-4_wp  ! Default Abaqus stabilisation
    LOGICAL  :: adaptive_stab       = .FALSE.     ! Adaptive stabilisation

    !-- Arc-length (Riks) control
    LOGICAL  :: use_riks            = .FALSE.
    REAL(wp) :: max_arc_inc         = 0.1_wp   ! Max arc-length increment
    REAL(wp) :: total_arc           = 1.0_wp   ! Target total arc length

    !-- Unsymmetric solver
    LOGICAL :: unsymm_solver = .FALSE.
  END TYPE MD_Step_Static_Desc

  !-----------------------------------------------------------------------------
  ! MD_Step_Dynamic_Desc — Implicit-dynamic extension
  !   For *DYNAMIC,IMPLICIT: Hilber-Hughes-Taylor (HHT) parameters.
  !   For *DYNAMIC,EXPLICIT: mass-scaling and bulk-viscosity are in MD_Elem_*.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Dynamic_Desc
    !-- HHT parameters (alpha-method)
    REAL(wp) :: alpha   = -0.05_wp   ! Numerical damping (-1/3 ≤ α ≤ 0)
    REAL(wp) :: beta    =  0.2756_wp ! Newmark beta (implicit)
    REAL(wp) :: gamma   =  0.5500_wp ! Newmark gamma

    !-- Initial conditions
    LOGICAL :: apply_initial_conditions = .TRUE.

    !-- Application (implicit vs explicit flag already in base proc_family)
    LOGICAL :: is_quasi_static = .FALSE.  ! Quasi-static dynamic simulation
  END TYPE MD_Step_Dynamic_Desc

  !-----------------------------------------------------------------------------
  ! MD_Step_Registry — Ordered collection of steps for the full analysis
  !   Stores base descriptors in step order; increment descriptors stored
  !   externally (1-to-1 mapping by step_id index).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Step_Registry
    TYPE(MD_Step_Base_Desc), ALLOCATABLE :: steps(:)
    INTEGER(i4) :: nsteps   = 0
    INTEGER(i4) :: capacity = 0

  CONTAINS
    PROCEDURE :: Init        => StepReg_Init
    PROCEDURE :: AddStep     => StepReg_Add
    PROCEDURE :: GetStepIdx  => StepReg_GetIdx
    PROCEDURE :: Clear       => StepReg_Clear
  END TYPE MD_Step_Registry

CONTAINS

  !=============================================================================
  ! MD_Step_Base_Desc procedures
  !=============================================================================

  SUBROUTINE Step_Base_Init(self, id, name, proc, period)
    CLASS(MD_Step_Base_Desc), INTENT(INOUT) :: self
    INTEGER(i4),       INTENT(IN) :: id
    CHARACTER(LEN=*),  INTENT(IN) :: name
    INTEGER(i4),       INTENT(IN) :: proc
    REAL(wp),          INTENT(IN) :: period

    self%step_id       = id
    self%step_name     = TRIM(name)
    self%proc_family   = proc
    self%time_period   = period
    self%is_initialized = .TRUE.
  END SUBROUTINE Step_Base_Init

  SUBROUTINE Step_Base_Validate(self, st)
    CLASS(MD_Step_Base_Desc), INTENT(IN)  :: self
    TYPE(ErrorStatusType),    INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (self%step_id <= 0) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "step_id must be >= 1"
      RETURN
    END IF
    IF (self%time_period <= 0.0_wp) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "time_period must be > 0"
      RETURN
    END IF
    IF (self%proc_family < MD_STEP_PROC_STATIC .OR. &
        self%proc_family > MD_STEP_PROC_MODAL) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "proc_family out of valid range [1..8]"
      RETURN
    END IF

    st%status_code = IF_STATUS_OK
  END SUBROUTINE Step_Base_Validate

  !=============================================================================
  ! MD_Step_Registry procedures
  !=============================================================================

  SUBROUTINE StepReg_Init(self, est)
    CLASS(MD_Step_Registry), INTENT(INOUT) :: self
    INTEGER(i4),             INTENT(IN)    :: est

    INTEGER(i4) :: cap
    cap = MAX(8_i4, est)
    IF (ALLOCATED(self%steps)) CALL self%Clear()
    ALLOCATE(self%steps(cap))
    self%capacity = cap
    self%nsteps   = 0
  END SUBROUTINE StepReg_Init

  SUBROUTINE StepReg_Add(self, step)
    CLASS(MD_Step_Registry),  INTENT(INOUT) :: self
    TYPE(MD_Step_Base_Desc),  INTENT(IN)    :: step

    TYPE(MD_Step_Base_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, new_cap

    n = self%nsteps
    IF (self%capacity > 0) THEN
      IF (n >= self%capacity) THEN
        new_cap = self%capacity * 2_i4
        ALLOCATE(tmp(new_cap))
        tmp(1:n) = self%steps(1:n)
        CALL MOVE_ALLOC(tmp, self%steps)
        self%capacity = new_cap
      END IF
      self%steps(n+1) = step
    ELSE
      ALLOCATE(tmp(n+1))
      IF (n > 0) tmp(1:n) = self%steps(1:n)
      tmp(n+1) = step
      CALL MOVE_ALLOC(tmp, self%steps)
    END IF
    self%nsteps = n + 1
  END SUBROUTINE StepReg_Add

  FUNCTION StepReg_GetIdx(self, id) RESULT(idx)
    CLASS(MD_Step_Registry), INTENT(IN) :: self
    INTEGER(i4),             INTENT(IN) :: id
    INTEGER(i4) :: idx

    INTEGER(i4) :: i
    idx = 0
    DO i = 1, self%nsteps
      IF (self%steps(i)%step_id == id) THEN
        idx = i
        RETURN
      END IF
    END DO
  END FUNCTION StepReg_GetIdx

  SUBROUTINE StepReg_Clear(self)
    CLASS(MD_Step_Registry), INTENT(INOUT) :: self
    IF (ALLOCATED(self%steps)) DEALLOCATE(self%steps)
    self%nsteps   = 0
    self%capacity = 0
  END SUBROUTINE StepReg_Clear

END MODULE MD_Step_Types


!===============================================================================
! MODULE MD_Step_Domain_Types                                   [Template v1.1]
! Layer:  L3_MD — Model Description Layer
! Domain: Step — Flat-storage independent domain container
!
! PURPOSE: Provides MD_Step_Desc / MD_Step_State / MD_Step_Algo / MD_Step_Ctx
! and the MD_Step_Domain container (Layer 2 in the three-layer architecture).
!
! DESIGN RULE: Step domain is flat ALLOCATABLE array storage.
!   - One MD_Step_Desc per *STEP block (write-once after parse)
!   - One MD_Step_State per step (updated via WriteBack during RT)
!   - MD_Step_Algo holds convergence tolerances (read-only during solve)
!   - MD_Step_Ctx is hot-path context (no ALLOCATABLE; reset each call)
!
! v1.1: Extended MD_STEP_PROC_* to 1..8 to match MD_Step_Types.
!===============================================================================
MODULE MD_Step_Domain_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Step_Desc
  PUBLIC :: MD_Step_State
  PUBLIC :: MD_Step_Algo
  PUBLIC :: MD_Step_Ctx
  PUBLIC :: MD_Step_Domain
  PUBLIC :: MD_Step_Domain_Init
  PUBLIC :: MD_Step_Domain_Finalize
  PUBLIC :: MD_Step_WriteBack

  !-- Step procedure constants (same numeric ids as MD_Step_Types)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_STATIC       = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_DYNAMIC_IMP  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_DYNAMIC_EXP  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_HEAT_XFER    = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_COUPLED_TE   = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_GEOSTATIC    = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_SOILS       = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_STEP_PROC_MODAL       = 8_i4

  !=============================================================================
  ! Desc — Write-once step configuration (frozen after parse)
  !=============================================================================
  TYPE, PUBLIC :: MD_Step_Desc
    CHARACTER(LEN=80) :: step_name      = ''         ! Step name from *STEP,NAME=
    INTEGER(i4)       :: step_id        = 0_i4       ! 1-based index
    INTEGER(i4)       :: procedure      = MD_STEP_PROC_STATIC  ! Procedure type
    LOGICAL           :: nlgeom         = .FALSE.    ! Large-deformation flag
    REAL(wp)          :: time_period    = 1.0_wp     ! Step duration
    REAL(wp)          :: dt_initial     = 0.01_wp   ! Initial increment
    REAL(wp)          :: dt_min         = 1.0e-8_wp ! Minimum increment
    REAL(wp)          :: dt_max         = 1.0_wp    ! Maximum increment
    INTEGER(i4)       :: max_increments = 100_i4    ! Maximum increments
    !-- Dynamic extension (only used when procedure = DYNAMIC_IMP) --
    REAL(wp)          :: alpha          = -0.05_wp  ! HHT-alpha parameter
    REAL(wp)          :: beta           = 0.2756_wp ! Newmark beta
    REAL(wp)          :: gamma          = 0.5500_wp ! Newmark gamma
  END TYPE MD_Step_Desc

  !=============================================================================
  ! State — Runtime state (WriteBack whitelist gated)
  !=============================================================================
  TYPE, PUBLIC :: MD_Step_State
    REAL(wp)    :: current_time       = 0.0_wp  ! Time at end of current increment
    REAL(wp)    :: current_dt         = 0.0_wp  ! Current increment size
    INTEGER(i4) :: current_increment  = 0_i4    ! Completed increment count
    INTEGER(i4) :: current_iteration  = 0_i4    ! Newton iteration count
    LOGICAL     :: is_complete        = .FALSE.  ! Step is finished
    LOGICAL     :: is_active          = .FALSE.  ! Currently executing
  END TYPE MD_Step_State

  !=============================================================================
  ! Algo — Algorithm parameters (read-only during solve)
  !=============================================================================
  TYPE, PUBLIC :: MD_Step_Algo
    REAL(wp)    :: residual_tol       = 5.0e-3_wp  ! Residual force tolerance
    REAL(wp)    :: displacement_tol   = 1.0e-2_wp  ! Displacement correction tol
    INTEGER(i4) :: max_cutbacks       = 5_i4        ! Max cut-back per increment
    REAL(wp)    :: cutback_factor     = 0.25_wp     ! Cut-back reduction factor
  END TYPE MD_Step_Algo

  !=============================================================================
  ! Ctx — Hot-path context (NO ALLOCATABLE; reset each call)
  !=============================================================================
  TYPE, PUBLIC :: MD_Step_Ctx
    INTEGER(i4) :: active_step_idx    = 0_i4    ! Active step index in domain array
    INTEGER(i4) :: caller_incr_idx    = 0_i4    ! Increment index from L5_RT
    LOGICAL     :: is_last_increment  = .FALSE. ! Last increment flag
    REAL(wp)    :: time_fraction      = 0.0_wp  ! t/T_period
  END TYPE MD_Step_Ctx

  !=============================================================================
  ! MD_Step_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Step_Domain
    TYPE(MD_Step_Desc),  ALLOCATABLE :: desc(:)
    TYPE(MD_Step_State), ALLOCATABLE :: state(:)
    TYPE(MD_Step_Algo),  ALLOCATABLE :: algo(:)
    INTEGER(i4) :: n_steps     = 0_i4
    INTEGER(i4) :: max_steps   = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen      = .FALSE.
  CONTAINS
    PROCEDURE :: Init      => MD_Step_Domain_Init
    PROCEDURE :: Finalize  => MD_Step_Domain_Finalize
    PROCEDURE :: WriteBack => MD_Step_WriteBack
  END TYPE MD_Step_Domain

CONTAINS

  SUBROUTINE MD_Step_Domain_Init(this, cap_steps, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: cap_steps
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Step_Domain_Finalize(this)
    IF (cap_steps < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Step_Domain_Init: cap_steps must be >= 1'
      RETURN
    END IF
    ALLOCATE(this%desc(cap_steps))
    ALLOCATE(this%state(cap_steps))
    ALLOCATE(this%algo(cap_steps))
    this%n_steps       = 0_i4
    this%max_steps     = cap_steps
    this%initialized   = .TRUE.
    this%frozen        = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Step_Domain_Init

  SUBROUTINE MD_Step_Domain_Finalize(this)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%desc))  DEALLOCATE(this%desc)
    IF (ALLOCATED(this%state)) DEALLOCATE(this%state)
    IF (ALLOCATED(this%algo))  DEALLOCATE(this%algo)
    this%n_steps     = 0_i4
    this%max_steps   = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_Step_Domain_Finalize

  SUBROUTINE MD_Step_WriteBack(this, step_id, new_state, status)
    CLASS(MD_Step_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: step_id
    TYPE(MD_Step_State),   INTENT(IN)    :: new_state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. step_id < 1_i4 .OR. step_id > this%n_steps) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'MD_Step_WriteBack: invalid step_id=', step_id
      RETURN
    END IF
    this%state(step_id) = new_state
    status%status_code  = IF_STATUS_OK
  END SUBROUTINE MD_Step_WriteBack

END MODULE MD_Step_Domain_Types
