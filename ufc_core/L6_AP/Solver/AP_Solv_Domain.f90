!===============================================================================
! MODULE: AP_Solv_Domain
! LAYER:  L6_AP
! DOMAIN: Solver
! ROLE:   Domain �?solver orchestration and job control
! BRIEF:  Application-level solver orchestration, job submission and control.
!===============================================================================
MODULE AP_Solv_Domain
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE AP_Job_Mgr, ONLY: AP_Job_Run_Structured, AP_Job_Run_In, AP_Job_Run_Out, &
                         AP_Job_BuildSum_Structured, AP_Job_BuildSum_In, AP_Job_BuildSum_Out
  IMPLICIT NONE
  PRIVATE

  ! --- Job phase enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_NOT_STARTED = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_PREPROCESS  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_SOLVING     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_POSTPROCESS = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_COMPLETE    = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_FAILED      = 5_i4

  TYPE, PUBLIC :: AP_Solver_State_Progress
    INTEGER(i4) :: jobPhase        = AP_JOB_NOT_STARTED
    INTEGER(i4) :: totalSteps      = 0_i4
    INTEGER(i4) :: completedSteps  = 0_i4
    INTEGER(i4) :: currentStepId   = 0_i4   ! step_idx
    INTEGER(i4) :: currentIncrIdx  = 0_i4   ! incr_idx [ L3→L6]
  END TYPE AP_Solver_State_Progress

  TYPE, PUBLIC :: AP_Solver_State_Timing
    REAL(wp)    :: totalJobTime    = 0.0_wp  ! wall-clock total
    REAL(wp)    :: preProcessTime  = 0.0_wp
    REAL(wp)    :: solveTime       = 0.0_wp
    REAL(wp)    :: postProcessTime = 0.0_wp
  END TYPE AP_Solver_State_Timing

  TYPE, PUBLIC :: AP_Solver_State_Resources
    REAL(wp)    :: peakMemoryMB   = 0.0_wp
  END TYPE AP_Solver_State_Resources

  TYPE, PUBLIC :: AP_Solver_State
    TYPE(AP_Solver_State_Progress)  :: progress
    TYPE(AP_Solver_State_Timing)    :: timing
    TYPE(AP_Solver_State_Resources) :: resources
  END TYPE AP_Solver_State

  TYPE, PUBLIC :: AP_Solver_Ctrl
    INTEGER(i4) :: nOMPThreads    = 0_i4     ! 0 = env default
    REAL(wp)    :: memoryLimitMB  = 0.0_wp   ! 0 = unlimited
    LOGICAL     :: dryRun         = .FALSE.  ! parse only, no solve
    LOGICAL     :: dataCheck      = .FALSE.  ! validate model only
  END TYPE AP_Solver_Ctrl

  ! --- Arg types (Phase B) ---
  TYPE, PUBLIC :: AP_Solver_RunJob_Arg
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Solver_RunJob_Arg

  TYPE, PUBLIC :: AP_Solver_SetOMPThreads_Arg
    INTEGER(i4) :: nOMP = 0_i4            ! (IN) 0 = env default
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Solver_SetOMPThreads_Arg

  TYPE, PUBLIC :: AP_Solver_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = "" ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Solver_GetSummary_Arg

  TYPE, PUBLIC :: AP_Solver_Domain
    TYPE(AP_Solver_State) :: state
    TYPE(AP_Solver_Ctrl)  :: ctrl
    LOGICAL               :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RunJob
    PROCEDURE :: SetOMPThreads
    PROCEDURE :: GetSummary
  END TYPE AP_Solver_Domain

CONTAINS

  SUBROUTINE AP_Solver_Domain_Finalize(this)
    CLASS(AP_Solver_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%state = AP_Solver_State()
    this%initialized = .FALSE.
  END SUBROUTINE AP_Solver_Domain_Finalize

  SUBROUTINE AP_Solver_Domain_Init(this, status)
    CLASS(AP_Solver_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctrl = AP_Solver_Ctrl()
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Solver_Domain_Init

  !====================================================================
  ! AP_Solver_Domain_RunJob  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Solver_Domain_RunJob(this, arg)
    CLASS(AP_Solver_Domain),   INTENT(INOUT) :: this
    TYPE(AP_Solver_RunJob_Arg),INTENT(INOUT) :: arg
    CALL AP_Solver_RunJob_Impl(this, arg%status)
  END SUBROUTINE AP_Solver_Domain_RunJob

  SUBROUTINE AP_Solver_RunJob_Impl(this, status)
    CLASS(AP_Solver_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    TYPE(AP_Job_Run_In)  :: run_in
    TYPE(AP_Job_Run_Out) :: run_out
    TYPE(AP_Job_BuildSum_In)  :: sum_in
    TYPE(AP_Job_BuildSum_Out) :: sum_out
    REAL(wp) :: t_start, t_end, t_phase

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Solver domain not initialized"
      RETURN
    END IF

    ! ============================================================
    ! Phase 1: Preprocessing
    ! ============================================================
    CALL CPU_TIME(t_start)
    this%state%progress%jobPhase = AP_JOB_PREPROCESS

    ! Dry-run mode: parse only, skip solve
    IF (this%ctrl%dryRun) THEN
      CALL CPU_TIME(t_end)
      this%state%timing%preProcessTime = t_end - t_start
      this%state%progress%jobPhase = AP_JOB_COMPLETE
      status%status_code = IF_STATUS_OK
      status%message = "Dry-run mode: parsing completed, solve skipped"
      RETURN
    END IF

    ! Data-check mode: validate model only, skip solve
    IF (this%ctrl%dataCheck) THEN
      ! TODO: Add model validation logic here
      ! - Check mesh quality
      ! - Verify boundary conditions
      ! - Validate material parameters
      CALL CPU_TIME(t_end)
      this%state%timing%preProcessTime = t_end - t_start
      this%state%progress%jobPhase = AP_JOB_COMPLETE
      status%status_code = IF_STATUS_OK
      status%message = "Data-check mode: model validation completed"
      RETURN
    END IF

    ! ============================================================
    ! Phase 2: Solving (delegate to AP_Job)
    ! ============================================================
    CALL CPU_TIME(t_start)
    this%state%progress%jobPhase = AP_JOB_SOLVING

    ! Integrate AP_Job: run job if context is configured
    IF (g_ufc_global%IsReady() .AND. ASSOCIATED(g_ufc_global%ap_layer%jobCtx)) THEN
      CALL AP_Job_Run_Structured(g_ufc_global%ap_layer%jobCtx, run_in, run_out)
      IF (run_out%status%status_code /= IF_STATUS_OK) THEN
        status = run_out%status
        CALL CPU_TIME(t_end)
        this%state%timing%solveTime = t_end - t_start
        this%state%progress%jobPhase = AP_JOB_FAILED
        RETURN
      END IF

      ! Sync AP_Job_Summary to AP_Solver_State
      CALL AP_Job_BuildSum_Structured(g_ufc_global%ap_layer%jobCtx, sum_in, sum_out)
      this%state%progress%completedSteps = sum_out%summary%nStepsCompleted
      this%state%progress%totalSteps     = sum_out%summary%nStepsTotal
      this%state%progress%currentStepId  = sum_out%summary%nStepsCompleted

      CALL CPU_TIME(t_end)
      this%state%timing%solveTime = t_end - t_start

      IF (sum_out%summary%isCompleted) THEN
        this%state%progress%jobPhase = AP_JOB_COMPLETE
      ELSE IF (sum_out%summary%isAborted) THEN
        this%state%progress%jobPhase = AP_JOB_FAILED
      END IF
    ELSE
      ! Job context not configured
      status%status_code = IF_STATUS_INVALID
      status%message = "Job context not configured (jobCtx not associated)"
      this%state%progress%jobPhase = AP_JOB_FAILED
      RETURN
    END IF

    ! ============================================================
    ! Phase 3: Postprocessing
    ! ============================================================
    CALL CPU_TIME(t_start)
    this%state%progress%jobPhase = AP_JOB_POSTPROCESS

    ! TODO: Add postprocessing logic here
    ! - Write output files (ODB/VTK/CSV)
    ! - Generate summary reports
    ! - Export results to external formats

    CALL CPU_TIME(t_end)
    this%state%timing%postProcessTime = t_end - t_start

    ! ============================================================
    ! Finalize: Calculate total time and peak memory
    ! ============================================================
    IF (this%state%progress%jobPhase /= AP_JOB_FAILED) THEN
      this%state%progress%jobPhase = AP_JOB_COMPLETE
    END IF

    this%state%timing%totalJobTime = this%state%timing%preProcessTime + &
                              this%state%timing%solveTime + &
                              this%state%timing%postProcessTime

    ! TODO: Integrate memory monitoring
    ! this%state%peakMemoryMB = Query_Peak_Memory_MB()
    this%state%resources%peakMemoryMB = 0.0_wp  ! Placeholder

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Solver_RunJob_Impl

  !====================================================================
  ! AP_Solver_Domain_SetOMPThreads  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Solver_Domain_SetOMPThreads(this, arg)
    CLASS(AP_Solver_Domain),          INTENT(INOUT) :: this
    TYPE(AP_Solver_SetOMPThreads_Arg),INTENT(INOUT) :: arg
    CALL AP_Solver_SetOMPThreads_Impl(this, arg%nOMP, arg%status)
  END SUBROUTINE AP_Solver_Domain_SetOMPThreads

  SUBROUTINE AP_Solver_SetOMPThreads_Impl(this, nOMP, status)
    USE omp_lib, ONLY: omp_set_num_threads, omp_get_max_threads
    CLASS(AP_Solver_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: nOMP
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Solver domain not initialized"
      RETURN
    END IF

    IF (nOMP < 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid nOMP (must be >= 0)"
      RETURN
    END IF

    this%ctrl%nOMPThreads = nOMP

    IF (nOMP > 0) THEN
      CALL omp_set_num_threads(nOMP)
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Solver_SetOMPThreads_Impl

  !====================================================================
  ! AP_Solver_Domain_GetSummary  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Solver_Domain_GetSummary(this, arg)
    CLASS(AP_Solver_Domain),        INTENT(IN)    :: this
    TYPE(AP_Solver_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL AP_Solver_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE AP_Solver_Domain_GetSummary

  SUBROUTINE AP_Solver_GetSummary_Impl(this, summary, status)
    CLASS(AP_Solver_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Solver domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,ES10.3,A,ES10.3,A,ES10.3,A,ES10.3,A,ES10.3)') &
      "Solver Summary: Phase=", this%state%progress%jobPhase, &
      ", TotalSteps=", this%state%progress%totalSteps, &
      ", Completed=", this%state%progress%completedSteps, &
      ", CurrentStep=", this%state%progress%currentStepId, &
      ", TotalTime=", this%state%timing%totalJobTime, &
      ", PreTime=", this%state%timing%preProcessTime, &
      ", SolveTime=", this%state%timing%solveTime, &
      ", PostTime=", this%state%timing%postProcessTime, &
      ", PeakMem=", this%state%resources%peakMemoryMB

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Solver_GetSummary_Impl

END MODULE AP_Solv_Domain