!===============================================================================
! MODULE: AP_Solv_Core
! LAYER:  L6_AP
! DOMAIN: Solver
! ROLE:   Core — solver configuration and step execution
! BRIEF:  Application-level solver configuration, step execution.
!===============================================================================
! Signature: (desc, algo, status)
! P0: Init, Finalize, Configure
! P2: Run_Step, Run_All_Steps
!===============================================================================
MODULE AP_Solv_Core
  USE IF_Prec_Core,         ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Solv_Def,   ONLY: AP_Solver_Desc, AP_Solver_Algo, &
                             AP_SOLVER_IMPLICIT, AP_SOLVER_EXPLICIT
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Solver_Core_Init
  PUBLIC :: AP_Solver_Core_Finalize
  PUBLIC :: AP_Solver_Configure
  PUBLIC :: AP_Solver_Get_Type
  PUBLIC :: AP_Solver_Run_Step
  PUBLIC :: AP_Solver_Run_All_Steps

CONTAINS

  SUBROUTINE AP_Solver_Core_Init(desc, algo, status)
    TYPE(AP_Solver_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Solver_Algo),  INTENT(IN)  :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Solver_Core_Init

  SUBROUTINE AP_Solver_Core_Finalize(desc, algo, status)
    TYPE(AP_Solver_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Solver_Algo),  INTENT(IN)  :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Solver_Core_Finalize

  !---------------------------------------------------------------------------
  ! Configure solver parameters
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Solver_Configure(desc, algo, solver_type, tol, max_iter, status)
    TYPE(AP_Solver_Desc),  INTENT(INOUT) :: desc
    TYPE(AP_Solver_Algo),  INTENT(INOUT) :: algo
    INTEGER(i4),           INTENT(IN)    :: solver_type
    REAL(wp),              INTENT(IN)    :: tol
    INTEGER(i4),           INTENT(IN)    :: max_iter
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (solver_type /= AP_SOLVER_IMPLICIT .AND. &
        solver_type /= AP_SOLVER_EXPLICIT) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Solver_Configure]: unknown solver type"
      RETURN
    END IF
    IF (tol <= 0.0_wp .OR. max_iter <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Solver_Configure]: invalid tol or max_iter"
      RETURN
    END IF

    algo%solver_type = solver_type
    algo%tolerance   = tol
    algo%max_iter    = max_iter
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Solver_Configure

  FUNCTION AP_Solver_Get_Type(algo) RESULT(t)
    TYPE(AP_Solver_Algo), INTENT(IN) :: algo
    INTEGER(i4) :: t
    t = algo%solver_type
  END FUNCTION AP_Solver_Get_Type

  !---------------------------------------------------------------------------
  ! Run a single analysis step (placeholder)
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Solver_Run_Step(desc, algo, step_id, status)
    TYPE(AP_Solver_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Solver_Algo),  INTENT(IN)  :: algo
    INTEGER(i4),           INTENT(IN)  :: step_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (step_id <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Solver_Run_Step]: invalid step_id"
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Solver_Run_Step

  !---------------------------------------------------------------------------
  ! Run all analysis steps (placeholder)
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Solver_Run_All_Steps(desc, algo, n_steps, status)
    TYPE(AP_Solver_Desc),  INTENT(IN)  :: desc
    TYPE(AP_Solver_Algo),  INTENT(IN)  :: algo
    INTEGER(i4),           INTENT(IN)  :: n_steps
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    IF (n_steps <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Solver_Run_All_Steps]: n_steps <= 0"
      RETURN
    END IF

    DO i = 1, n_steps
      CALL AP_Solver_Run_Step(desc, algo, i, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Solver_Run_All_Steps

END MODULE AP_Solv_Core
