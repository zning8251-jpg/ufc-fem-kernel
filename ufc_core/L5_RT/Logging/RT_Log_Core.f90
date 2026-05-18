!===============================================================================
! MODULE: RT_Log_Core
! LAYER:  L5_RT
! DOMAIN: Logging
! ROLE:   Core — Init/Finalize and step/increment/iteration logging
! BRIEF:  Core logging lifecycle, step headers, convergence, error messages.
!===============================================================================
MODULE RT_Log_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Log_Def, ONLY: RT_Log_Desc, RT_Log_Ctx, RT_Logging_State
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Logging_Core_Init
  PUBLIC :: RT_Logging_Core_Finalize
  PUBLIC :: RT_Logging_Step_Header
  PUBLIC :: RT_Logging_Inc_Summary
  PUBLIC :: RT_Logging_Iteration_Info
  PUBLIC :: RT_Logging_Convergence
  PUBLIC :: RT_Logging_Error_Message
  PUBLIC :: RT_Logging_Cutback_Info

CONTAINS

  SUBROUTINE RT_Logging_Core_Init(desc, state, ctx, status)
    TYPE(RT_Log_Desc),      INTENT(IN)    :: desc
    TYPE(RT_Logging_State), INTENT(OUT)   :: state
    TYPE(RT_Log_Ctx),       INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%line_buffer = ''
    ctx%step_id     = 0
    ctx%inc_num     = 0
    state%active     = .TRUE.
    state%n_messages = 0
    state%n_warnings = 0
    state%n_errors   = 0
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Logging_Core_Init

  SUBROUTINE RT_Logging_Core_Finalize(state, ctx, status)
    TYPE(RT_Logging_State), INTENT(INOUT) :: state
    TYPE(RT_Log_Ctx),       INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%line_buffer = ''
    ctx%step_id     = 0
    ctx%inc_num     = 0
    state%active     = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Logging_Core_Finalize

  SUBROUTINE RT_Logging_Step_Header(desc, ctx, step_id, t_start, t_end, status)
    TYPE(RT_Log_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Log_Ctx),     INTENT(INOUT) :: ctx
    INTEGER(i4),          INTENT(IN)    :: step_id
    REAL(wp),             INTENT(IN)    :: t_start
    REAL(wp),             INTENT(IN)    :: t_end
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%step_id = step_id

    IF (desc%log_level >= 1) THEN
      WRITE(desc%log_unit, '(A)') &
        '========================================================'
      WRITE(desc%log_unit, '(A,A,A,I6)') &
        TRIM(desc%prefix), ' STEP ', '', step_id
      WRITE(desc%log_unit, '(A,A,ES12.5,A,ES12.5)') &
        TRIM(desc%prefix), ' Time: ', t_start, ' -> ', t_end
      WRITE(desc%log_unit, '(A)') &
        '========================================================'
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Logging_Step_Header

  SUBROUTINE RT_Logging_Inc_Summary(desc, ctx, inc_num, dt, time, niter, status)
    TYPE(RT_Log_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Log_Ctx),     INTENT(INOUT) :: ctx
    INTEGER(i4),          INTENT(IN)    :: inc_num
    REAL(wp),             INTENT(IN)    :: dt
    REAL(wp),             INTENT(IN)    :: time
    INTEGER(i4),          INTENT(IN)    :: niter
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%inc_num = inc_num

    IF (desc%log_level >= 1) THEN
      WRITE(desc%log_unit, '(A,A,I6,A,ES10.3,A,ES10.3,A,I4)') &
        TRIM(desc%prefix), ' Inc ', inc_num, &
        '  dt=', dt, '  t=', time, '  iters=', niter
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Logging_Inc_Summary

  SUBROUTINE RT_Logging_Iteration_Info(desc, ctx, iter, rnorm, dunorm, status)
    TYPE(RT_Log_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Log_Ctx),     INTENT(INOUT) :: ctx
    INTEGER(i4),          INTENT(IN)    :: iter
    REAL(wp),             INTENT(IN)    :: rnorm
    REAL(wp),             INTENT(IN)    :: dunorm
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (desc%log_level >= 2) THEN
      WRITE(desc%log_unit, '(A,A,I4,A,ES10.3,A,ES10.3)') &
        TRIM(desc%prefix), '   iter=', iter, &
        '  |R|=', rnorm, '  |du|=', dunorm
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Logging_Iteration_Info

  SUBROUTINE RT_Logging_Convergence(desc, ctx, converged, rnorm, status)
    TYPE(RT_Log_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Log_Ctx),     INTENT(INOUT) :: ctx
    LOGICAL,              INTENT(IN)    :: converged
    REAL(wp),             INTENT(IN)    :: rnorm
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (desc%log_level >= 1) THEN
      IF (converged) THEN
        WRITE(desc%log_unit, '(A,A,ES10.3)') &
          TRIM(desc%prefix), ' ** CONVERGED  |R|=', rnorm
      ELSE
        WRITE(desc%log_unit, '(A,A,ES10.3)') &
          TRIM(desc%prefix), ' ** NOT CONVERGED  |R|=', rnorm
      END IF
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Logging_Convergence

  SUBROUTINE RT_Logging_Error_Message(desc, ctx, message, status)
    TYPE(RT_Log_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Log_Ctx),     INTENT(INOUT) :: ctx
    CHARACTER(LEN=*),     INTENT(IN)    :: message
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (desc%log_level >= 0) THEN
      WRITE(desc%log_unit, '(A,A,A)') &
        TRIM(desc%prefix), ' ERROR: ', TRIM(message)
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Logging_Error_Message

  SUBROUTINE RT_Logging_Cutback_Info(desc, ctx, n_cutbacks, new_dt, status)
    TYPE(RT_Log_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Log_Ctx),     INTENT(INOUT) :: ctx
    INTEGER(i4),          INTENT(IN)    :: n_cutbacks
    REAL(wp),             INTENT(IN)    :: new_dt
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (desc%log_level >= 1) THEN
      WRITE(desc%log_unit, '(A,A,I4,A,ES10.3)') &
        TRIM(desc%prefix), ' CUTBACK #', n_cutbacks, &
        '  new_dt=', new_dt
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Logging_Cutback_Info

END MODULE RT_Log_Core
