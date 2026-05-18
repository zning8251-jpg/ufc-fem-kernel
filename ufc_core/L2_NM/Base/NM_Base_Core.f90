!===============================================================================
! MODULE: NM_Base_Core
! LAYER:  L2_NM
! DOMAIN: Base
! ROLE:   Core — domain container lifecycle and operations
! BRIEF:  Base domain container — Init/Finalize/SetVerbose/GetErrorCodeDesc/
!         GetSummary with SIO-compliant Arg bundles.
!
! Theory chain:
!   L2_NM error codes defined in: NM_Base_ErrCodes
!   Constants defined in: NM_Base_Def
!   Norms defined in: NM_Base_Norms
!   Utils defined in: NM_Base_Utils
!
! Logic chain:
!   All L2 domains USE NM_Base for domain lifecycle
!   L1_IF provides base ErrorStatusType
!
! Data chain:
!   Container path: g_ufc_global%nm_layer%base
!   Lifecycle: Process-level (configuration only)
!
! SIO Compliance:
!   All subroutines follow Principle #14: unified *_Arg bundles with
!   [IN]/[OUT] comments. No inp/out pairs.
!
! Contents:
!   Types:
!     NM_Base_Domain           — Domain container (State-like)
!   Arg Bundles:
!     NM_Base_Finalize_Arg     — P0 Finalize arguments
!     NM_Base_Init_Arg         — P0 Init arguments
!     NM_Base_SetVerbose_Arg   — P0 SetVerbose arguments
!     NM_Base_GetErrDesc_Arg   — P3 GetErrorCodeDesc arguments
!     NM_Base_GetSummary_Arg   — P3 GetSummary arguments
!   Subroutines (A-Z):
!     NM_Base_Finalize          — P0
!     NM_Base_GetErrorCodeDesc  — P3
!     NM_Base_GetSummary        — P3
!     NM_Base_Init              — P0
!     NM_Base_SetVerbose        — P0
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_Base_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                       IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_Base_ErrCodes, ONLY: &
      NM_ERR_SOLVER_BASE, NM_ERR_NOT_CONVERGED, NM_ERR_MAX_ITER, &
      NM_ERR_SINGULAR, NM_ERR_ILL_CONDITIONED, NM_ERR_DIVERGED, &
      NM_ERR_LINALG_SINGULAR, NM_ERR_LINALG_RANK_DEF, &
      NM_ERR_ITER_STAGNATION, NM_ERR_TIMEINT_STEP_SMALL, NM_ERR_TIMEINT_UNSTABLE
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! NM_Base_Domain — Domain container (State-like)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Base_Domain
    INTEGER(i4) :: verboseLevel = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  CONTAINS
    PROCEDURE :: Init              => NM_Base_Init
    PROCEDURE :: Finalize          => NM_Base_Finalize
    PROCEDURE :: SetVerboseLevel   => NM_Base_SetVerbose
    PROCEDURE :: GetErrorCodeDesc  => NM_Base_GetErrorCodeDesc
    PROCEDURE :: GetSummary        => NM_Base_GetSummary
  END TYPE NM_Base_Domain

  !====================================================================
  ! Arg Bundle Structures (four-type: *_Arg suffix, SIO Principle #14)
  !====================================================================

  !--------------------------------------------------------------------
  ! NM_Base_Finalize_Arg: Arguments for NM_Base_Finalize
  !--------------------------------------------------------------------
  TYPE :: NM_Base_Finalize_Arg
    ! [IN] this     - Domain instance to finalize
    CLASS(NM_Base_Domain), POINTER :: this
  END TYPE NM_Base_Finalize_Arg

  !--------------------------------------------------------------------
  ! NM_Base_Init_Arg: Arguments for NM_Base_Init
  !--------------------------------------------------------------------
  TYPE :: NM_Base_Init_Arg
    ! [IN]  this     - Domain instance to initialize
    ! [OUT] status   - Error status (IF_STATUS_OK on success)
    CLASS(NM_Base_Domain), POINTER :: this
    TYPE(ErrorStatusType)         :: status
  END TYPE NM_Base_Init_Arg

  !--------------------------------------------------------------------
  ! NM_Base_SetVerbose_Arg: Arguments for NM_Base_SetVerbose
  !--------------------------------------------------------------------
  TYPE :: NM_Base_SetVerbose_Arg
    ! [IN]  this   - Domain instance
    ! [IN]  level  - Verbose level (0-3)
    ! [OUT] status - Error status
    CLASS(NM_Base_Domain), POINTER :: this
    INTEGER(i4) :: level
    TYPE(ErrorStatusType) :: status
  END TYPE NM_Base_SetVerbose_Arg

  !--------------------------------------------------------------------
  ! NM_Base_GetErrDesc_Arg: Arguments for NM_Base_GetErrorCodeDesc
  !--------------------------------------------------------------------
  TYPE :: NM_Base_GetErrDesc_Arg
    ! [IN]  this        - Domain instance
    ! [IN]  errorCode   - Error code to describe
    ! [OUT] description - Description string (LEN=128)
    CLASS(NM_Base_Domain), POINTER :: this
    INTEGER(i4)                  :: errorCode
    CHARACTER(LEN=128)           :: description
  END TYPE NM_Base_GetErrDesc_Arg

  !--------------------------------------------------------------------
  ! NM_Base_GetSummary_Arg: Arguments for NM_Base_GetSummary
  !--------------------------------------------------------------------
  TYPE :: NM_Base_GetSummary_Arg
    ! [IN]  this     - Domain instance
    ! [OUT] summary  - Summary string (LEN=512)
    ! [OUT] status   - Error status
    CLASS(NM_Base_Domain), POINTER :: this
    CHARACTER(LEN=512)           :: summary
    TYPE(ErrorStatusType)       :: status
  END TYPE NM_Base_GetSummary_Arg

CONTAINS

  !====================================================================
  ! NM_Base_Finalize — P0 Finalize NM_Base domain
  !====================================================================
  SUBROUTINE NM_Base_Finalize(this)
    !> [INOUT] this  - Domain instance to finalize
    CLASS(NM_Base_Domain), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN
    this%verboseLevel = 0_i4
    this%initialized  = .FALSE.
  END SUBROUTINE NM_Base_Finalize

  !====================================================================
  ! NM_Base_Finalize_Proc — P0 Arg-bundle wrapper (SIO compliant)
  !====================================================================
  SUBROUTINE NM_Base_Finalize_Proc(arg)
    !> [INOUT] arg - Arg bundle
    TYPE(NM_Base_Finalize_Arg), INTENT(INOUT) :: arg

    IF (.NOT. arg%this%initialized) RETURN
    arg%this%verboseLevel = 0_i4
    arg%this%initialized  = .FALSE.
  END SUBROUTINE NM_Base_Finalize_Proc

  !====================================================================
  ! NM_Base_Init — P0 Initialize NM_Base domain
  !====================================================================
  SUBROUTINE NM_Base_Init(this, status)
    !> [INOUT] this   - Domain instance to initialize
    !> [OUT]   status - Error status (IF_STATUS_OK on success)
    CLASS(NM_Base_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%initialized  = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Base_Init

  !====================================================================
  ! NM_Base_Init_Proc — P0 Arg-bundle wrapper (SIO compliant)
  !====================================================================
  SUBROUTINE NM_Base_Init_Proc(arg)
    !> [INOUT] arg - Arg bundle (this[INOUT], status[OUT])
    TYPE(NM_Base_Init_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)
    IF (arg%this%initialized) CALL arg%this%Finalize()
    arg%this%initialized  = .TRUE.
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Base_Init_Proc

  !====================================================================
  ! NM_Base_SetVerbose — P0 Set verbose level
  !====================================================================
  SUBROUTINE NM_Base_SetVerbose(this, level, status)
    !> [INOUT] this   - Domain instance
    !> [IN]    level  - Verbose level (0-3)
    !> [OUT]   status - Error status
    CLASS(NM_Base_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: level
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! Validate level (0-3)
    IF (level < 0_i4 .OR. level > 3_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Verbose level must be in range [0, 3]"
      RETURN
    END IF

    this%verboseLevel = level
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Base_SetVerbose

  !====================================================================
  ! NM_Base_SetVerbose_Proc — P0 Arg-bundle wrapper (SIO compliant)
  !====================================================================
  SUBROUTINE NM_Base_SetVerbose_Proc(arg)
    !> [INOUT] arg - Arg bundle (this[INOUT], level[IN], status[OUT])
    TYPE(NM_Base_SetVerbose_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)

    ! Validate level (0-3)
    IF (arg%level < 0_i4 .OR. arg%level > 3_i4) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Verbose level must be in range [0, 3]"
      RETURN
    END IF

    arg%this%verboseLevel = arg%level
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Base_SetVerbose_Proc

  !====================================================================
  ! NM_Base_GetErrorCodeDesc — P3 Get error code description
  !====================================================================
  FUNCTION NM_Base_GetErrorCodeDesc(this, errorCode) RESULT(description)
    !> [IN]    this       - Domain instance
    !> [IN]    errorCode  - Error code to describe
    !> [OUT]   description - Description string
    CLASS(NM_Base_Domain), INTENT(IN) :: this
    INTEGER(i4),           INTENT(IN) :: errorCode
    CHARACTER(LEN=128) :: description

    SELECT CASE(errorCode)
    CASE(NM_ERR_SOLVER_BASE)
      description = "Base solver error"
    CASE(NM_ERR_NOT_CONVERGED)
      description = "Solver did not converge"
    CASE(NM_ERR_MAX_ITER)
      description = "Maximum iterations reached"
    CASE(NM_ERR_SINGULAR)
      description = "Singular matrix detected"
    CASE(NM_ERR_ILL_CONDITIONED)
      description = "Ill-conditioned matrix"
    CASE(NM_ERR_DIVERGED)
      description = "Solver diverged"
    CASE(NM_ERR_LINALG_SINGULAR)
      description = "Linear algebra: singular matrix"
    CASE(NM_ERR_LINALG_RANK_DEF)
      description = "Linear algebra: rank deficient matrix"
    CASE(NM_ERR_ITER_STAGNATION)
      description = "Iteration stagnation detected"
    CASE(NM_ERR_TIMEINT_STEP_SMALL)
      description = "Time step too small"
    CASE(NM_ERR_TIMEINT_UNSTABLE)
      description = "Time integration unstable"
    CASE DEFAULT
      description = "Unknown error code"
    END SELECT
  END FUNCTION NM_Base_GetErrorCodeDesc

  !====================================================================
  ! NM_Base_GetErrorCodeDesc_Proc — P3 Arg-bundle wrapper
  !====================================================================
  SUBROUTINE NM_Base_GetErrorCodeDesc_Proc(arg)
    !> [INOUT] arg - Arg bundle (this[IN], errorCode[IN], description[OUT])
    TYPE(NM_Base_GetErrDesc_Arg), INTENT(INOUT) :: arg

    SELECT CASE(arg%errorCode)
    CASE(NM_ERR_SOLVER_BASE)
      arg%description = "Base solver error"
    CASE(NM_ERR_NOT_CONVERGED)
      arg%description = "Solver did not converge"
    CASE(NM_ERR_MAX_ITER)
      arg%description = "Maximum iterations reached"
    CASE(NM_ERR_SINGULAR)
      arg%description = "Singular matrix detected"
    CASE(NM_ERR_ILL_CONDITIONED)
      arg%description = "Ill-conditioned matrix"
    CASE(NM_ERR_DIVERGED)
      arg%description = "Solver diverged"
    CASE(NM_ERR_LINALG_SINGULAR)
      arg%description = "Linear algebra: singular matrix"
    CASE(NM_ERR_LINALG_RANK_DEF)
      arg%description = "Linear algebra: rank deficient matrix"
    CASE(NM_ERR_ITER_STAGNATION)
      arg%description = "Iteration stagnation detected"
    CASE(NM_ERR_TIMEINT_STEP_SMALL)
      arg%description = "Time step too small"
    CASE(NM_ERR_TIMEINT_UNSTABLE)
      arg%description = "Time integration unstable"
    CASE DEFAULT
      arg%description = "Unknown error code"
    END SELECT
  END SUBROUTINE NM_Base_GetErrorCodeDesc_Proc

  !====================================================================
  ! NM_Base_GetSummary — P3 Get summary string
  !====================================================================
  SUBROUTINE NM_Base_GetSummary(this, summary, status)
    !> [IN]    this     - Domain instance
    !> [OUT]   summary  - Summary string
    !> [OUT]   status   - Error status
    CLASS(NM_Base_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),    INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Base domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,L1)') &
      "Base Summary: VerboseLevel=", this%verboseLevel, &
      ", Initialized=", this%initialized

    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Base_GetSummary

  !====================================================================
  ! NM_Base_GetSummary_Proc — P3 Arg-bundle wrapper
  !====================================================================
  SUBROUTINE NM_Base_GetSummary_Proc(arg)
    !> [INOUT] arg - Arg bundle (this[IN], summary[OUT], status[OUT])
    TYPE(NM_Base_GetSummary_Arg), INTENT(INOUT) :: arg

    CALL init_error_status(arg%status)

    IF (.NOT. arg%this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "Base domain not initialized"
      RETURN
    END IF

    WRITE(arg%summary, '(A,I0,A,L1)') &
      "Base Summary: VerboseLevel=", arg%this%verboseLevel, &
      ", Initialized=", arg%this%initialized

    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Base_GetSummary_Proc

END MODULE NM_Base_Core