!===============================================================================
! Module: MD_Solver_XXX                                  [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Solver — Instance-level solver configuration descriptor
!
! HOW TO USE:
!   1. Copy to L3_MD/Solver/[Family]/
!   2. Rename: MD_Solv_[Family]_[Type].f90
!              (e.g., MD_Solv_NR_Static.f90, MD_Solv_Dyn_Implicit.f90)
!   3. Replace XXX_XXX -> [Family]_[Type]  (e.g., NR_Static)
!   4. Replace XXX     -> [Type abbrev]    (e.g., NR)
!   5. Fill in: solver_type_id, required parameters
!   6. Implement: MD_XXX_Solv_Validate, MD_XXX_Solv_Init
!
! Naming Convention (layer prefix rule):
!   Module:    MD_Solv_[Family]_[Type]       → MD_Solv_NR_Static
!   Desc type: MD_XXX_Solv_Desc              → MD_Solv_NR_Desc  (MD-owned)
!   Validate:  MD_XXX_Solv_Validate          → MD_Solv_NR_Validate
!   Init:      MD_XXX_Solv_Init              → MD_Solv_NR_Init
!
! Design notes (UFC Solver domain):
!   - Newton-Raphson: Implicit static/dynamic with NR iteration
!   - Direct solve:   Linear static with direct solver
!   - Eigenvalue:     Natural frequency extraction
!   - MD_Solv_Base_Desc carries: solver_id, solver_type, n_increments,
!     is_initialized. This Desc extends it with solver-family specific
!     parameters (tolerances, iteration limits, time integration params, etc.).
!   - Purely static / configuration: set ONCE at model load.
!   - NEVER carry per-increment iteration state here
!     (those belong in PH_Solv_Base_State / RT_Solv_State).
!===============================================================================
MODULE MD_Solver_XXX
  USE IF_Prec_Core,             ONLY: wp, i4
  USE IF_Err_Brg,          ONLY: ErrorStatusType, init_error_status, &
                                 IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Solver_Types,     ONLY: MD_Solv_Base_Desc, &
                                 MD_SOLV_TYPE_IMPLICIT, &
                                 MD_SOLV_TYPE_EXPLICIT
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public exports: Desc type + two standard MD-layer interfaces
  ! Prefix MD_XXX_ signals these subroutines belong to L3_MD layer.
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_XXX_Solv_Desc            ! L3_MD solver descriptor (MD-owned)
  PUBLIC :: MD_XXX_Solv_Validate        ! Validate solver parameters
  PUBLIC :: MD_XXX_Solv_Init            ! Initialize from input

  !-----------------------------------------------------------------------------
  ! Constants — solver family invariants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: SOLV_NPARAMS_MIN = 3_i4   ! Minimum parameters count
  !
  ! Params layout (document ALL slots for THIS solver family):
  !   params(1) = tolerance       : Convergence tolerance [-]
  !   params(2) = max_iter        : Maximum iterations [count]
  !   params(3) = time_period     : Step time period [s]
  !   params(4) = initial_dt      : Initial time increment [s]
  !   ...
  !

  !-----------------------------------------------------------------------------
  ! DESC type: EXTENDS MD_Solv_Base_Desc, adds solver-family parameters.
  !
  !   MD_Solv_Base_Desc provides:
  !     solver_id     — solver set ID
  !     solver_type   — type enum (IMPLICIT/EXPLICIT/EIGEN/...)
  !     solver_name   — human-readable label (CHARACTER(LEN=64))
  !     n_increments  — number of increments
  !     is_initialized — .TRUE. after Init succeeds
  !
  !   Add solver-family-specific Desc fields below.
  !   For Newton-Raphson: add tolerance, max_iter, line_search_flag
  !   For Direct:       add solver_method, sparse_format
  !   For Dyn-Implicit: add alpha, beta, gamma (Newmark/HHT params)
  !-----------------------------------------------------------------------------
  !> L3 descriptor for [Solver Family / Type Name].
  TYPE, PUBLIC, EXTENDS(MD_Solv_Base_Desc) :: MD_XXX_Solv_Desc
    !-- Solver family type identifier
    INTEGER(i4) :: solver_family = MD_SOLV_TYPE_IMPLICIT

    !-- Solver-family-specific parameters
    !   For Newton-Raphson:
    REAL(wp)    :: tolerance      = 1.0e-8_wp   ! Convergence tolerance [-]
    REAL(wp)    :: abs_tolerance  = 1.0e-12_wp  ! Absolute tolerance floor
    INTEGER(i4) :: max_iter       = 100_i4      ! Max Newton iterations
    LOGICAL     :: use_line_search = .FALSE.    ! Enable line search
    
    !   For Dynamic-Implicit (Newmark/HHT):
    REAL(wp)    :: alpha_param    = 0.0_wp      ! HHT alpha parameter
    REAL(wp)    :: beta_param     = 0.25_wp     ! Newmark beta parameter
    REAL(wp)    :: gamma_param    = 0.5_wp      ! Newmark gamma parameter
    
    !   For stabilization:
    LOGICAL     :: use_stabilization = .FALSE.  ! Numerical damping
    REAL(wp)    :: stabilization_factor = 0.0_wp ! Damping factor
    
    !-- Time stepping parameters
    REAL(wp)    :: time_period    = 1.0_wp      ! Total step time [s]
    REAL(wp)    :: initial_dt     = 0.1_wp      ! Initial time increment [s]
    REAL(wp)    :: min_dt         = 1.0e-20_wp  ! Minimum time increment [s]
    REAL(wp)    :: max_dt         = 1.0_wp      ! Maximum time increment [s]
    
    !-- Derived / pre-computed constants
    REAL(wp)    :: inv_tolerance  = 0.0_wp      ! 1/tolerance (avoid division)
    
  CONTAINS
    !-- No TBP bindings (removed per UFC template optimization)
  END TYPE MD_XXX_Solv_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  !> MD_XXX_Solv_Validate
  !>   Validates solver parameters for [Solver Family / Type].
  !>   Returns structured status with %status_code = IF_STATUS_INVALID on any
  !>   constraint violation.
  !>
  !>   nparams — number of real parameters
  !>   params  — real parameters array
  !>   st      — structured status object (%status_code == IF_STATUS_OK on success)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Solv_Validate(nparams, params, st)
    INTEGER(i4),           INTENT(IN)  :: nparams
    REAL(wp),              INTENT(IN)  :: params(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    !-- Minimum count check
    IF (nparams < SOLV_NPARAMS_MIN) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Solv]: need >= SOLV_NPARAMS_MIN params"
      RETURN
    END IF

    !-- Per-slot physical constraints
    !   params(1) = tolerance must be positive
    IF (nparams >= 1) THEN
      IF (params(1) <= 0.0_wp) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Solv]: params(1) (tolerance) must be > 0"
        RETURN
      END IF
    END IF
    
    !   params(2) = max_iter must be positive integer
    IF (nparams >= 2) THEN
      IF (INT(params(2), i4) <= 0_i4) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Solv]: params(2) (max_iter) must be > 0"
        RETURN
      END IF
    END IF
    
    !   params(3) = time_period must be positive
    IF (nparams >= 3) THEN
      IF (params(3) <= 0.0_wp) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Solv]: params(3) (time_period) must be > 0"
        RETURN
      END IF
    END IF

    !-- TODO: add further solver-type-specific validation here

    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Solv_Validate

  !-----------------------------------------------------------------------------
  !> MD_XXX_Solv_Init
  !>   Unpacks nparams/params into MD_XXX_Solv_Desc.
  !>   Computes all derived constants (inv_tolerance, etc.).
  !>   Called ONCE at model load.
  !>
  !>   desc   — output Desc (populated by this subroutine)
  !>   nparams — number of real parameters
  !>   params  — real parameter array
  !>   st      — structured status object (%status_code == IF_STATUS_OK on success)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Solv_Init(desc, nparams, params, st)
    TYPE(MD_XXX_Solv_Desc), INTENT(OUT) :: desc
    INTEGER(i4),            INTENT(IN)  :: nparams
    REAL(wp),               INTENT(IN)  :: params(:)
    TYPE(ErrorStatusType),  INTENT(OUT) :: st

    CALL init_error_status(st)

    !-- Step 1: validate before unpacking
    CALL MD_XXX_Solv_Validate(nparams, params, st)
    IF (st%status_code /= IF_STATUS_OK) RETURN

    !-- Step 2: populate base fields (inherited from MD_Solv_Base_Desc)
    desc%solver_type   = MD_SOLV_TYPE_IMPLICIT   ! ← replace with actual type
    desc%n_increments  = 100_i4                   ! default value

    !-- Step 3: unpack real params
    IF (nparams >= 1) desc%tolerance      = params(1)
    IF (nparams >= 2) desc%max_iter       = INT(params(2), i4)
    IF (nparams >= 3) desc%time_period    = params(3)
    IF (nparams >= 4) desc%initial_dt     = params(4)
    IF (nparams >= 5) desc%min_dt         = params(5)
    IF (nparams >= 6) desc%max_dt         = params(6)
    !-- TODO: unpack further solver-family-specific params slots

    !-- Step 4: compute derived constants
    IF (desc%tolerance > 0.0_wp) THEN
      desc%inv_tolerance = 1.0_wp / desc%tolerance
    ELSE
      desc%inv_tolerance = 0.0_wp
    END IF

    !-- Step 5: allocate base params array for compatibility
    desc%nparams = nparams
    IF (.NOT. ALLOCATED(desc%params)) ALLOCATE(desc%params(nparams))
    desc%params(1:nparams) = params(1:nparams)

    !-- Step 6: mark initialized
    desc%is_initialized = .TRUE.
    st%status_code      = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Solv_Init

END MODULE MD_Solver_XXX
