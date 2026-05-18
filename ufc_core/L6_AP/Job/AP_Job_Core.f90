!===============================================================================
! MODULE: AP_Job_Core
! LAYER:  L6_AP
! DOMAIN: Job
! ROLE:   Core — job creation and execution control
! BRIEF:  Job creation, execution control, abort, and summary output.
!===============================================================================
! Signature: (desc, state, status)
! P0: Init, Finalize, Create
! P2: Run, Abort
! P3: Summary
!===============================================================================
MODULE AP_Job_Core
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Job_Def,   ONLY: AP_Job_Desc, AP_Job_State, &
                          AP_JOB_IDLE, AP_JOB_RUNNING, &
                          AP_JOB_DONE, AP_JOB_FAILED
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Job_Core_Init
  PUBLIC :: AP_Job_Core_Finalize
  PUBLIC :: AP_Job_Create
  PUBLIC :: AP_Job_Run
  PUBLIC :: AP_Job_Get_Status
  PUBLIC :: AP_Job_Abort
  PUBLIC :: AP_Job_Summary

CONTAINS

  SUBROUTINE AP_Job_Core_Init(desc, state, status)
    TYPE(AP_Job_Desc),     INTENT(IN)  :: desc
    TYPE(AP_Job_State),    INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    state%job_status   = AP_JOB_IDLE
    state%elapsed_time = 0.0_wp
    state%current_step = 0
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_Core_Init

  SUBROUTINE AP_Job_Core_Finalize(desc, state, status)
    TYPE(AP_Job_Desc),     INTENT(IN)    :: desc
    TYPE(AP_Job_State),    INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%job_status   = AP_JOB_IDLE
    state%elapsed_time = 0.0_wp
    state%current_step = 0
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_Core_Finalize

  !---------------------------------------------------------------------------
  ! Create job: populate desc fields
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Job_Create(desc, job_name, input_file, job_type, status)
    TYPE(AP_Job_Desc),     INTENT(INOUT) :: desc
    CHARACTER(LEN=*),      INTENT(IN)    :: job_name
    CHARACTER(LEN=*),      INTENT(IN)    :: input_file
    INTEGER(i4),           INTENT(IN)    :: job_type
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (LEN_TRIM(job_name) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Job_Create]: empty job name"
      RETURN
    END IF

    desc%job_name   = job_name
    desc%input_file = input_file
    desc%job_type   = job_type
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_Create

  !---------------------------------------------------------------------------
  ! Run job: transition to RUNNING
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Job_Run(desc, state, status)
    TYPE(AP_Job_Desc),     INTENT(IN)    :: desc
    TYPE(AP_Job_State),    INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (state%job_status /= AP_JOB_IDLE) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Job_Run]: job not in IDLE state"
      RETURN
    END IF

    state%job_status = AP_JOB_RUNNING
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_Run

  FUNCTION AP_Job_Get_Status(state) RESULT(s)
    TYPE(AP_Job_State), INTENT(IN) :: state
    INTEGER(i4) :: s
    s = state%job_status
  END FUNCTION AP_Job_Get_Status

  !---------------------------------------------------------------------------
  ! Abort job: transition to FAILED
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Job_Abort(state, status)
    TYPE(AP_Job_State),    INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%job_status = AP_JOB_FAILED
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_Abort

  !---------------------------------------------------------------------------
  ! Write job summary to a Fortran unit
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Job_Summary(desc, state, unit_num, status)
    TYPE(AP_Job_Desc),     INTENT(IN)  :: desc
    TYPE(AP_Job_State),    INTENT(IN)  :: state
    INTEGER(i4),           INTENT(IN)  :: unit_num
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    WRITE(unit_num, '(A)')       "===== JOB SUMMARY ====="
    WRITE(unit_num, '(A,A)')     "  Job name  : ", TRIM(desc%job_name)
    WRITE(unit_num, '(A,A)')     "  Input file: ", TRIM(desc%input_file)
    WRITE(unit_num, '(A,I0)')    "  Job type  : ", desc%job_type
    WRITE(unit_num, '(A,I0)')    "  Status    : ", state%job_status
    WRITE(unit_num, '(A,ES12.4)')"  Elapsed   : ", state%elapsed_time
    WRITE(unit_num, '(A,I0)')    "  Step      : ", state%current_step
    WRITE(unit_num, '(A)')       "======================="
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_Summary

END MODULE AP_Job_Core
