!===============================================================================
! MODULE: NM_Solv_Mgr
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Mgr (solver domain container - linear/nonlinear solver control)
! BRIEF:  Domain container for solver type enums, ctrl types, init/finalize
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================
MODULE NM_Solv_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Linear solver type enumerations
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_CG           = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_GMRES        = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_BICGSTAB     = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_DIRECT_LU    = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_CHOLESKY     = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINSOL_MULTIFRONTAL = 12_i4

  !--------------------------------------------------------------------
  ! Preconditioner type enumerations
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_NONE   = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_JACOBI = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_SSOR   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_ILU0   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_ILUT   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREC_AMG    = 5_i4

  !--------------------------------------------------------------------
  ! Nonlinear solver type enumerations
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_NLSOL_NEWTON      = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_NLSOL_MODIFIED_NR = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_NLSOL_BFGS        = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_NLSOL_ARCLENGTH   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_NLSOL_TRUST       = 5_i4

  !--------------------------------------------------------------------
  ! NM_LinSolvCtrl ?Linear solver control parameters
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_LinSolvCtrl
    INTEGER(i4) :: solvType  = NM_LINSOL_CG
    INTEGER(i4) :: precType  = NM_PREC_ILU0
    INTEGER(i4) :: maxIter   = 1000_i4
    REAL(wp)    :: relTol    = 1.0e-8_wp
    REAL(wp)    :: absTol    = 1.0e-12_wp
    LOGICAL     :: enReorder = .TRUE.
    LOGICAL     :: enGPU     = .FALSE.
  END TYPE NM_LinSolvCtrl

  !--------------------------------------------------------------------
  ! NM_NLSolvCtrl ?Nonlinear solver control parameters
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_NLSolvCtrl
    INTEGER(i4) :: solvType    = NM_NLSOL_NEWTON
    INTEGER(i4) :: maxNRIter   = 16_i4
    REAL(wp)    :: resConvTol  = 1.0e-6_wp
    REAL(wp)    :: dispConvTol = 1.0e-6_wp
    REAL(wp)    :: energyTol   = 1.0e-8_wp
    REAL(wp)    :: arcLenParam = 0.01_wp
    LOGICAL     :: enLineSearch = .FALSE.
    LOGICAL     :: enEnergyConv = .FALSE.
  END TYPE NM_NLSolvCtrl

  !--------------------------------------------------------------------
  ! NM_Solver_Domain ?Domain container
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Solver_Domain
    TYPE(NM_LinSolvCtrl) :: linCtrl
    TYPE(NM_NLSolvCtrl)  :: nlCtrl
    LOGICAL              :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init                => NM_Solv_Init
    PROCEDURE :: Finalize            => NM_Solv_Finalize
    PROCEDURE :: SetLinearSolver     => NM_Solv_SetLin
    PROCEDURE :: SetNonlinearSolver  => NM_Solv_SetNonlin
    PROCEDURE :: GetSummary          => NM_Solv_GetSummary
  END TYPE NM_Solver_Domain

CONTAINS

  SUBROUTINE NM_Solv_Finalize(this)
    CLASS(NM_Solver_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%linCtrl = NM_LinSolvCtrl()
    this%nlCtrl  = NM_NLSolvCtrl()
    this%initialized = .FALSE.
  END SUBROUTINE NM_Solv_Finalize

  SUBROUTINE NM_Solv_Init(this, status)
    CLASS(NM_Solver_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%initialized  = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solv_Init

  !====================================================================
  ! NM_Solv_SetLin
  ! Set linear solver parameters
  !====================================================================
  SUBROUTINE NM_Solv_SetLin(this, solvType, precType, maxIter, tol, status)
    CLASS(NM_Solver_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: solvType, precType, maxIter
    REAL(wp),                INTENT(IN)    :: tol
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! Validate solver type
    IF (solvType < NM_LINSOL_CG .OR. solvType > NM_LINSOL_MULTIFRONTAL) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid linear solver type"
      RETURN
    END IF

    ! Validate preconditioner type
    IF (precType < NM_PREC_NONE .OR. precType > NM_PREC_AMG) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid preconditioner type"
      RETURN
    END IF

    this%linCtrl%solvType = solvType
    this%linCtrl%precType = precType
    this%linCtrl%maxIter = maxIter
    this%linCtrl%relTol = tol
    this%linCtrl%absTol = tol * 1.0e-4_wp

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_Solv_SetLin

  !====================================================================
  ! NM_Solv_SetNonlin
  ! Set nonlinear solver parameters
  !====================================================================
  SUBROUTINE NM_Solv_SetNonlin(this, solvType, maxNRIter, tol, status)
    CLASS(NM_Solver_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: solvType, maxNRIter
    REAL(wp),                INTENT(IN)    :: tol
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! Validate solver type
    IF (solvType < NM_NLSOL_NEWTON .OR. solvType > NM_NLSOL_TRUST) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid nonlinear solver type"
      RETURN
    END IF

    this%nlCtrl%solvType = solvType
    this%nlCtrl%maxNRIter = maxNRIter
    this%nlCtrl%resConvTol = tol
    this%nlCtrl%dispConvTol = tol
    this%nlCtrl%energyTol = tol * 1.0e-2_wp

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_Solv_SetNonlin

  !====================================================================
  ! NM_Solv_GetSummary
  ! Get summary string of solver domain
  !====================================================================
  SUBROUTINE NM_Solv_GetSummary(this, summary, status)
    CLASS(NM_Solver_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CHARACTER(LEN=32) :: linSolvName, nlSolvName, precName

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Solver domain not initialized"
      RETURN
    END IF

    ! Get linear solver name
    SELECT CASE(this%linCtrl%solvType)
    CASE(NM_LINSOL_CG)
      linSolvName = "CG"
    CASE(NM_LINSOL_GMRES)
      linSolvName = "GMRES"
    CASE(NM_LINSOL_BICGSTAB)
      linSolvName = "BiCGSTAB"
    CASE(NM_LINSOL_DIRECT_LU)
      linSolvName = "Direct LU"
    CASE(NM_LINSOL_CHOLESKY)
      linSolvName = "Cholesky"
    CASE(NM_LINSOL_MULTIFRONTAL)
      linSolvName = "Multifrontal"
    CASE DEFAULT
      linSolvName = "Unknown"
    END SELECT

    ! Get nonlinear solver name
    SELECT CASE(this%nlCtrl%solvType)
    CASE(NM_NLSOL_NEWTON)
      nlSolvName = "Newton-Raphson"
    CASE(NM_NLSOL_MODIFIED_NR)
      nlSolvName = "Modified NR"
    CASE(NM_NLSOL_BFGS)
      nlSolvName = "BFGS"
    CASE(NM_NLSOL_ARCLENGTH)
      nlSolvName = "Arc-Length"
    CASE(NM_NLSOL_TRUST)
      nlSolvName = "Trust-Region"
    CASE DEFAULT
      nlSolvName = "Unknown"
    END SELECT

    ! Get preconditioner name
    SELECT CASE(this%linCtrl%precType)
    CASE(NM_PREC_NONE)
      precName = "None"
    CASE(NM_PREC_JACOBI)
      precName = "Jacobi"
    CASE(NM_PREC_SSOR)
      precName = "SSOR"
    CASE(NM_PREC_ILU0)
      precName = "ILU0"
    CASE(NM_PREC_ILUT)
      precName = "ILUT"
    CASE(NM_PREC_AMG)
      precName = "AMG"
    CASE DEFAULT
      precName = "Unknown"
    END SELECT

    WRITE(summary, '(A,A,A,A,A,I0,A,ES10.3,A,I0,A,A,A,I0,A,ES10.3)') &
      "Solver Summary: LinSolv=", TRIM(linSolvName), &
      ", Prec=", TRIM(precName), &
      ", MaxIter=", this%linCtrl%maxIter, &
      ", Tol=", this%linCtrl%relTol, &
      ", NLSolv=", TRIM(nlSolvName), &
      ", MaxNRIter=", this%nlCtrl%maxNRIter, &
      ", Tol=", this%nlCtrl%resConvTol

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_Solv_GetSummary

END MODULE NM_Solv_Mgr