!===============================================================================
! MODULE: AP_Job_Domain
! LAYER:  L6_AP
! DOMAIN: Job
! ROLE:   Domain â€?job domain aggregate
! BRIEF:  Job context, run control, monitoring, rollback, resource metering.
!===============================================================================
! Status: Phase B (Arg-wrapped) | Last verified: 2026-03-11
!
! Logic Chain (Mermaid):
! ```mermaid
! stateDiagram-v2
!     [*] --> Init: InitJobCtx
!     Init --> Running: RunJob
!     Running --> Paused: PauseJob
#     Paused --> Running: ResumeJob
!     Running --> Completed: Success
!     Running --> Failed: Error
!     Failed --> [*]: Cleanup
!     Completed --> [*]: Cleanup
! ```
!===============================================================================

MODULE AP_Job_Domain
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  ! --- Job status enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: JOB_STATUS_INIT      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: JOB_STATUS_RUNNING   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: JOB_STATUS_PAUSED    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: JOB_STATUS_COMPLETED = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: JOB_STATUS_FAILED    = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: JOB_STATUS_ABORTED   = 5_i4

  TYPE, PUBLIC :: AP_Job_Metrics
    REAL(wp)    :: cpuTime            = 0.0_wp
    REAL(wp)    :: wallTime           = 0.0_wp
    INTEGER(i8) :: memoryUsed      = 0_i8
    INTEGER(i8) :: memoryPeak      = 0_i8
    INTEGER(i8) :: diskIO          = 0_i8
    INTEGER(i4) :: nStepsCompleted    = 0_i4
    INTEGER(i4) :: nIncrementsCompleted = 0_i4
    INTEGER(i4) :: nIterationsTotal   = 0_i4
    INTEGER(i4) :: nRollbacks         = 0_i4
  END TYPE AP_Job_Metrics

  TYPE, PUBLIC :: AP_Job_State
    INTEGER(i8) :: jobId        = 0_i8
    CHARACTER(LEN=256) :: jobName  = ''
    INTEGER(i4)    :: status       = JOB_STATUS_INIT
    INTEGER(i4)    :: totalSteps   = 0_i4
    INTEGER(i4)    :: currentStep  = 0_i4   ! step_idx
    INTEGER(i4)    :: currentIncrIdx = 0_i4 ! incr_idx [??? L3?L6]
    REAL(wp)       :: progress     = 0.0_wp
    TYPE(AP_Job_Metrics) :: metrics
  END TYPE AP_Job_State

  TYPE, PUBLIC :: AP_Job_Ctrl
    REAL(wp)    :: maxCpuTime   = 0.0_wp     ! 0 = unlimited
    INTEGER(i8) :: maxMemory = 0_i8    ! 0 = unlimited
    LOGICAL     :: limitsSet    = .FALSE.
  END TYPE AP_Job_Ctrl

  ! --- Arg types (Phase B) ---
  TYPE, PUBLIC :: AP_Job_Run_Arg
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_Run_Arg

  TYPE, PUBLIC :: AP_Job_Pause_Arg
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_Pause_Arg

  TYPE, PUBLIC :: AP_Job_Abort_Arg
    CHARACTER(LEN=256)    :: reason = ''  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_Abort_Arg

  TYPE, PUBLIC :: AP_Job_RollbackToStep_Arg
    INTEGER(i4)           :: stepId = 0_i4  ! (IN) step_idx for rollback
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_RollbackToStep_Arg

  TYPE, PUBLIC :: AP_Job_RecordResource_Arg
    REAL(wp)       :: cpuTime    = 0.0_wp    ! (IN)
    INTEGER(i8) :: memoryUsed = 0_i8   ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_RecordResource_Arg

  TYPE, PUBLIC :: AP_Job_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ''  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_GetSummary_Arg

  TYPE, PUBLIC :: AP_JobDomain
    TYPE(AP_Job_State)  :: state
    TYPE(AP_Job_Ctrl)   :: ctrl
    LOGICAL             :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Run
    PROCEDURE :: Pause
    PROCEDURE :: Abort
    PROCEDURE :: RollbackToStep
    PROCEDURE :: RecordResource
    PROCEDURE :: GetSummary
  END TYPE AP_JobDomain

CONTAINS

  SUBROUTINE AP_Job_Domain_Finalize(this)
    CLASS(AP_JobDomain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%state = AP_Job_State()
    this%initialized = .FALSE.
  END SUBROUTINE AP_Job_Domain_Finalize

  SUBROUTINE AP_Job_Domain_Init(this, jobName, totalSteps, status)
    CLASS(AP_JobDomain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),     INTENT(IN), OPTIONAL :: jobName
    INTEGER(i4),          INTENT(IN), OPTIONAL :: totalSteps
    TYPE(ErrorStatusType),INTENT(OUT)   :: status

    INTEGER(i8) :: count

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctrl = AP_Job_Ctrl()
    this%state%jobName    = ''
    this%state%totalSteps = 0_i4
    IF (PRESENT(jobName)) this%state%jobName = TRIM(jobName)
    IF (PRESENT(totalSteps)) this%state%totalSteps = totalSteps
    this%state%status     = JOB_STATUS_INIT
    CALL SYSTEM_CLOCK(count)
    this%state%jobId      = count
    this%initialized      = .TRUE.
    status%status_code    = IF_STATUS_OK
  END SUBROUTINE AP_Job_Domain_Init

  !====================================================================
  ! AP_Job_Domain_Run  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Job_Domain_Run(this, arg)
    CLASS(AP_JobDomain),  INTENT(INOUT) :: this
    TYPE(AP_Job_Run_Arg),  INTENT(INOUT) :: arg
    CALL AP_Job_Run_Impl(this, arg%status)
  END SUBROUTINE AP_Job_Domain_Run

  SUBROUTINE AP_Job_Run_Impl(this, status)
    CLASS(AP_JobDomain),  INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Job domain not initialized'
      RETURN
    END IF
    IF (this%state%status == JOB_STATUS_PAUSED .OR. &
        this%state%status == JOB_STATUS_INIT) THEN
      this%state%status = JOB_STATUS_RUNNING
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = 'Job not in runnable state'
    END IF
  END SUBROUTINE AP_Job_Run_Impl

  !====================================================================
  ! AP_Job_Domain_Pause  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Job_Domain_Pause(this, arg)
    CLASS(AP_JobDomain),   INTENT(INOUT) :: this
    TYPE(AP_Job_Pause_Arg), INTENT(INOUT) :: arg
    CALL AP_Job_Pause_Impl(this, arg%status)
  END SUBROUTINE AP_Job_Domain_Pause

  SUBROUTINE AP_Job_Pause_Impl(this, status)
    CLASS(AP_JobDomain),  INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Job domain not initialized'
      RETURN
    END IF
    IF (this%state%status == JOB_STATUS_RUNNING) THEN
      this%state%status = JOB_STATUS_PAUSED
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = 'Job not running'
    END IF
  END SUBROUTINE AP_Job_Pause_Impl

  !====================================================================
  ! AP_Job_Domain_Abort  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Job_Domain_Abort(this, arg)
    CLASS(AP_JobDomain),   INTENT(INOUT) :: this
    TYPE(AP_Job_Abort_Arg), INTENT(INOUT) :: arg
    CALL AP_Job_Abort_Impl(this, arg%reason, arg%status)
  END SUBROUTINE AP_Job_Domain_Abort

  SUBROUTINE AP_Job_Abort_Impl(this, reason, status)
    CLASS(AP_JobDomain),  INTENT(INOUT) :: this
    CHARACTER(LEN=*),      INTENT(IN)    :: reason
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Job domain not initialized'
      RETURN
    END IF
    this%state%status = JOB_STATUS_ABORTED
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_Abort_Impl

  !====================================================================
  ! AP_Job_Domain_RollbackToStep  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Job_Domain_RollbackToStep(this, arg)
    CLASS(AP_JobDomain),          INTENT(INOUT) :: this
    TYPE(AP_Job_RollbackToStep_Arg),INTENT(INOUT) :: arg
    CALL AP_Job_RollbackToStep_Impl(this, arg%stepId, arg%status)
  END SUBROUTINE AP_Job_Domain_RollbackToStep

  SUBROUTINE AP_Job_RollbackToStep_Impl(this, stepId, status)
    CLASS(AP_JobDomain),  INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: stepId
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Job domain not initialized'
      RETURN
    END IF
    IF (stepId < 0 .OR. stepId > this%state%currentStep) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Invalid step ID for rollback'
      RETURN
    END IF
    this%state%currentStep = stepId
    this%state%metrics%nRollbacks = this%state%metrics%nRollbacks + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_RollbackToStep_Impl

  !====================================================================
  ! AP_Job_Domain_RecordResource  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Job_Domain_RecordResource(this, arg)
    CLASS(AP_JobDomain),          INTENT(INOUT) :: this
    TYPE(AP_Job_RecordResource_Arg),INTENT(INOUT) :: arg
    CALL AP_Job_RecordResource_Impl(this, arg%cpuTime, arg%memoryUsed, arg%status)
  END SUBROUTINE AP_Job_Domain_RecordResource

  SUBROUTINE AP_Job_RecordResource_Impl(this, cpuTime, memoryUsed, status)
    CLASS(AP_JobDomain),  INTENT(INOUT) :: this
    REAL(wp),              INTENT(IN)    :: cpuTime
    INTEGER(i8),        INTENT(IN)    :: memoryUsed
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Job domain not initialized'
      RETURN
    END IF
    this%state%metrics%cpuTime    = cpuTime
    this%state%metrics%memoryUsed = memoryUsed
    IF (memoryUsed > this%state%metrics%memoryPeak) &
      this%state%metrics%memoryPeak = memoryUsed
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_RecordResource_Impl

  !====================================================================
  ! AP_Job_Domain_GetSummary  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Job_Domain_GetSummary(this, arg)
    CLASS(AP_JobDomain),       INTENT(IN)    :: this
    TYPE(AP_Job_GetSummary_Arg),INTENT(INOUT) :: arg
    CALL AP_Job_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE AP_Job_Domain_GetSummary

  SUBROUTINE AP_Job_GetSummary_Impl(this, summary, status)
    CLASS(AP_JobDomain),  INTENT(IN)  :: this
    CHARACTER(LEN=512),    INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Job domain not initialized'
      RETURN
    END IF
    WRITE(summary, '(A,A,A,I0,A,I0,A,I0,A,ES10.3,A,I0)') &
      'Job Summary: Name=', TRIM(this%state%jobName), &
      ', Status=', this%state%status, &
      ', Step=', this%state%currentStep, &
      ', TotalSteps=', this%state%totalSteps, &
      ', CPUTime=', this%state%metrics%cpuTime, &
      ', Rollbacks=', this%state%metrics%nRollbacks
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Job_GetSummary_Impl

END MODULE AP_Job_Domain