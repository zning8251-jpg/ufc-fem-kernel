!===============================================================================
! MODULE: AP_Brg_L5
! LAYER:  L6_AP
! DOMAIN: Bridge
! ROLE:   Brg — L6→L5 bridge
! BRIEF:  Bridge for user input to solver/runtime configuration conversion.
!===============================================================================
! P0: Brg_AP_Configure_Solver, Brg_AP_SetJobCtx_InContainer, Brg_AP_SetRTDrvCtx
! P2: Brg_AP_StepRunner_RT
! P3: Brg_AP_Get_Job_Status, Brg_AP_Query_Runtime_State
!===============================================================================

MODULE AP_Brg_L5
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Drv_Ctx_Mod, ONLY: RT_Drv_Ctx
  USE RT_Shared_Def, ONLY: UF_RT_JobStatus, UF_JobStatus_Success, RT_Sol_Cfg, &
                             RT_SOL_LINSOL_I, RT_SOL_LINSOL_D, RT_SOL_LINSOL_A
  USE RT_Types, ONLY: RT_FieldState_Type, RT_Elem_State, RT_Glob_State
  USE RT_Step_Type, ONLY: RT_Step_Ctx
  USE RT_Step_WS, ONLY: UF_Model
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE AP_Job_Mgr, ONLY: JobCtx, JobOpts, AP_JOB_RT_FULL_JOB_DONE
  USE AP_Job_Def, ONLY: JobDesc => AP_Job_Desc
  USE MD_TypeSystem, ONLY: State_Model
  USE MD_Model_Lib_Core, ONLY: UF_ModelDef
  
  ! RT_Driver_Core
  USE RT_Driver_Core, ONLY: RT_RunModel_Ctx
  
  ! RT_Drv_Ctx (already imported above, but need to PUBLIC export)
  
  IMPLICIT NONE
  PRIVATE

  ! Stored RT_Drv_Ctx for StepRunner bridge (set by Brg_AP_SetRTDrvCtx after model build)
  TYPE(RT_Drv_Ctx), POINTER, SAVE :: g_brg_rt_ctx => NULL()

  PUBLIC :: Brg_AP_Configure_Solver
  PUBLIC :: Brg_AP_SetJobCtx_InContainer
  PUBLIC :: Brg_AP_SetRTDrvCtx
  PUBLIC :: Brg_AP_SetRTDrvModelDef
  PUBLIC :: Brg_AP_WireStepRunner_JobCtx
  PUBLIC :: Brg_AP_StepRunner_RT
  PUBLIC :: Brg_AP_Configure_Solver_ToCtx
  PUBLIC :: Brg_AP_Get_Job_Status
  PUBLIC :: Brg_AP_Get_Job_Status_FromCtx
  PUBLIC :: Brg_AP_Query_Runtime_State
  PUBLIC :: Brg_AP_Query_Runtime_State_FromField
  
  ! Re-export RT_Step_Type and RT_Solv_Def for L6_AP use
  PUBLIC :: RT_Step_Ctx
  PUBLIC :: RT_Sol_Cfg, RT_SOL_LINSOL_D, RT_SOL_LINSOL_I
  
  ! Re-export RT_Base_Core
  PUBLIC :: UF_Model
  
  ! Re-export RT_Ctx_API
  PUBLIC :: UF_RT_JobStatus, UF_JobStatus_Success
  
  ! Re-export RT_Driver_Core
  PUBLIC :: RT_RunModel_Ctx
  
  ! Re-export RT_Drv_Ctx
  PUBLIC :: RT_Drv_Ctx

CONTAINS

  SUBROUTINE Brg_AP_Configure_Solver_ToCtx(ctx, solver_cfg, status)
    TYPE(RT_Drv_Ctx), INTENT(INOUT) :: ctx
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: solver_cfg
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(RT_Sol_Cfg), POINTER :: solver_ptr
    CHARACTER(LEN=80) :: cfg_lower
    INTEGER(i4) :: i

    IF (PRESENT(status)) CALL init_error_status(status)

    ! Ensure ctx has solver pointer
    IF (.NOT. ASSOCIATED(ctx%solver)) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    solver_ptr => ctx%solver

    !  set
    IF (PRESENT(solver_cfg) .AND. LEN_TRIM(solver_cfg) > 0) THEN
      cfg_lower = solver_cfg
      !  
      DO i = 1, LEN_TRIM(cfg_lower)
        IF (cfg_lower(i:i) >= 'A' .AND. cfg_lower(i:i) <= 'Z') THEN
          cfg_lower(i:i) = CHAR(ICHAR(cfg_lower(i:i)) + 32)
        END IF
      END DO

      !  
      IF (INDEX(cfg_lower, "static") > 0) THEN
        solver_ptr%isExplicit = .FALSE.
        solver_ptr%useHHT = .FALSE.
      ELSE IF (INDEX(cfg_lower, "dynamic") > 0 .OR. INDEX(cfg_lower, "transient") > 0) THEN
        solver_ptr%isExplicit = .FALSE.
        solver_ptr%useHHT = .TRUE.
        solver_ptr%alphaHHT = -0.1_wp
      ELSE IF (INDEX(cfg_lower, "explicit") > 0) THEN
        solver_ptr%isExplicit = .TRUE.
      END IF

      IF (INDEX(cfg_lower, "iterative") > 0) THEN
        solver_ptr%linSolvType = RT_SOL_LINSOL_I
      ELSE IF (INDEX(cfg_lower, "direct") > 0) THEN
        solver_ptr%linSolvType = RT_SOL_LINSOL_D
      ELSE IF (INDEX(cfg_lower, "auto") > 0) THEN
        solver_ptr%linSolvType = RT_SOL_LINSOL_A
      END IF

      ! setdefault 
      IF (LEN_TRIM(solver_ptr%name) == 0) THEN
        solver_ptr%name = TRIM(solver_cfg)
      END IF
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Brg_AP_Configure_Solver_ToCtx

  SUBROUTINE Brg_AP_Configure_Solver(solver_cfg, job_name, ierr)
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: solver_cfg
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: job_name
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    IF (PRESENT(ierr)) ierr = 0
    ! Base version: call Brg_AP_Configure_Solver_ToCtx when ctx needed
  END SUBROUTINE Brg_AP_Configure_Solver

  !------------------------------------------------------------------
  ! Brg_AP_SetJobCtx_InContainer - Inject JobCtx into L6 container
  !   Call this after building the model (e.g., from input parser or
  !   script runner) so that AP_Solver_RunJob_Impl can execute the job.
  !   The caller must provide a valid JobCtx with desc, stateModel,
  !   and StepRunner already bound (via AP_Job_BindCtx_Structured).
  !------------------------------------------------------------------
  SUBROUTINE Brg_AP_SetJobCtx_InContainer(ctx)
    TYPE(JobCtx), POINTER, INTENT(IN) :: ctx
    IF (.NOT. g_ufc_global%IsReady()) RETURN
    CALL g_ufc_global%ap_layer%SetJobCtx(ctx)
  END SUBROUTINE Brg_AP_SetJobCtx_InContainer

  !------------------------------------------------------------------
  ! Brg_AP_SetRTDrvCtx - Store RT_Drv_Ctx for StepRunner bridge
  !   Call after model build with ctx having model and solver bound; caller keeps ctx alive for RunJob.
  !   Optional model_def: forwarded to ctx%SetModelDef (same effect as Brg_AP_SetRTDrvModelDef after ctx is set).
  !------------------------------------------------------------------
  SUBROUTINE Brg_AP_SetRTDrvCtx(ctx, model_def)
    TYPE(RT_Drv_Ctx), POINTER, INTENT(IN) :: ctx
    TYPE(UF_ModelDef), TARGET, INTENT(IN), OPTIONAL :: model_def
    IF (ASSOCIATED(ctx)) THEN
      g_brg_rt_ctx => ctx
      IF (PRESENT(model_def)) CALL ctx%SetModelDef(model_def=model_def)
    ELSE
      NULLIFY(g_brg_rt_ctx)
    END IF
  END SUBROUTINE Brg_AP_SetRTDrvCtx

  !------------------------------------------------------------------
  ! Brg_AP_SetRTDrvModelDef - attach L3 UF_ModelDef for material rollback
  !------------------------------------------------------------------
  SUBROUTINE Brg_AP_SetRTDrvModelDef(model_def)
    TYPE(UF_ModelDef), TARGET, INTENT(IN) :: model_def
    IF (.NOT. ASSOCIATED(g_brg_rt_ctx)) RETURN
    CALL g_brg_rt_ctx%SetModelDef(model_def=model_def)
  END SUBROUTINE Brg_AP_SetRTDrvModelDef

  !------------------------------------------------------------------
  ! Brg_AP_WireStepRunner_JobCtx - bind L5_RT StepRunner on JobCtx
  !------------------------------------------------------------------
  SUBROUTINE Brg_AP_WireStepRunner_JobCtx(ctxJob)
    TYPE(JobCtx), INTENT(INOUT) :: ctxJob
    ctxJob%StepRunner => Brg_AP_StepRunner_RT
  END SUBROUTINE Brg_AP_WireStepRunner_JobCtx

  !------------------------------------------------------------------
  ! Brg_AP_StepRunner_RT - StepRunner callback bridging to L5_RT
  !   Conforms to UF_Job_StepRunner_Ifc. On stepIndex=1, runs RT_RunModel_Ctx
  !   (full job) using stored g_brg_rt_ctx; returns AP_JOB_RT_FULL_JOB_DONE.
  !   Requires Brg_AP_SetRTDrvCtx(ctx[, model_def]) before RunJob.
  !------------------------------------------------------------------
  SUBROUTINE Brg_AP_StepRunner_RT(descJob, stateModel, stepIndex, opts, ierr)
    TYPE(JobDesc),      INTENT(IN)    :: descJob
    TYPE(State_Model),  INTENT(INOUT) :: stateModel
    INTEGER(i4),       INTENT(IN)    :: stepIndex
    TYPE(JobOpts),     INTENT(IN)    :: opts
    INTEGER(i4),      INTENT(OUT)   :: ierr

    ierr = 0_i4
    IF (.NOT. ASSOCIATED(g_brg_rt_ctx)) THEN
      ierr = -1_i4
      RETURN
    END IF
    IF (.NOT. ASSOCIATED(g_brg_rt_ctx%model) .OR. .NOT. ASSOCIATED(g_brg_rt_ctx%solver)) THEN
      ierr = -1_i4
      RETURN
    END IF
    IF (stepIndex /= 1_i4) THEN
      ! Expect step 1 first; stepIndex>1 should not occur (job completes after step 1)
      ierr = -1_i4
      RETURN
    END IF

    ! Run full job via L5_RT
    CALL RT_RunModel_Ctx(g_brg_rt_ctx)
    IF (g_brg_rt_ctx%success) THEN
      ierr = AP_JOB_RT_FULL_JOB_DONE
    ELSE
      IF (ASSOCIATED(g_brg_rt_ctx%rt_status)) THEN
        ierr = g_brg_rt_ctx%rt_status%code
      ELSE
        ierr = -1_i4
      END IF
    END IF
  END SUBROUTINE Brg_AP_StepRunner_RT

  SUBROUTINE Brg_AP_Get_Job_Status_FromCtx(ctx, status_code, message, status)
    TYPE(RT_Drv_Ctx), INTENT(IN) :: ctx
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status_code
    CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    !   ctx getstatus
    IF (PRESENT(status_code)) THEN
      IF (ASSOCIATED(ctx%rt_status)) THEN
        status_code = ctx%rt_status%code
      ELSE
        status_code = 0
      END IF
    END IF

    IF (PRESENT(message)) THEN
      IF (ASSOCIATED(ctx%rt_status)) THEN
        message = ctx%rt_status%message
      ELSE
        message = ""
      END IF
    END IF

    IF (PRESENT(status)) THEN
      IF (ctx%IsOK()) THEN
        status%status_code = IF_STATUS_OK
      ELSE
        status = ctx%GetStatus()
      END IF
    END IF
  END SUBROUTINE Brg_AP_Get_Job_Status_FromCtx

  SUBROUTINE Brg_AP_Get_Job_Status(job_name, status_code, message, ierr)
    CHARACTER(LEN=*), INTENT(IN) :: job_name
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status_code
    CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: message
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    IF (PRESENT(status_code)) status_code = 0
    IF (PRESENT(message)) message = ""
    IF (PRESENT(ierr)) ierr = 0
    !   ctx   Brg_AP_Get_Job_Status_FromCtx
  END SUBROUTINE Brg_AP_Get_Job_Status

  SUBROUTINE Brg_AP_Query_Runtime_State_FromField(field_state, query_type, result, status)
    TYPE(RT_FieldState_Type), INTENT(IN) :: field_state
    CHARACTER(LEN=*), INTENT(IN) :: query_type
    REAL(wp), INTENT(OUT), ALLOCATABLE, OPTIONAL :: result(:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: n, i

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (PRESENT(result)) THEN
      IF (ALLOCATED(result)) DEALLOCATE(result)

      IF (query_type == "displacement" .OR. query_type == "u") THEN
        !  displacement
        IF (ALLOCATED(field_state%u)) THEN
          n = SIZE(field_state%u)
          ALLOCATE(result(n))
          DO i = 1, n
            result(i) = field_state%u(i)
          END DO
        ELSE
          ALLOCATE(result(0))
        END IF

      ELSE IF (query_type == "velocity" .OR. query_type == "v") THEN
        !  velocity
        IF (ALLOCATED(field_state%v)) THEN
          n = SIZE(field_state%v)
          ALLOCATE(result(n))
          DO i = 1, n
            result(i) = field_state%v(i)
          END DO
        ELSE
          ALLOCATE(result(0))
        END IF

      ELSE IF (query_type == "acceleration" .OR. query_type == "a") THEN
        !  velocity
        IF (ALLOCATED(field_state%a)) THEN
          n = SIZE(field_state%a)
          ALLOCATE(result(n))
          DO i = 1, n
            result(i) = field_state%a(i)
          END DO
        ELSE
          ALLOCATE(result(0))
        END IF

      ELSE IF (query_type == "temperature" .OR. query_type == "T") THEN
        !  temperature
        IF (ALLOCATED(field_state%T)) THEN
          n = SIZE(field_state%T)
          ALLOCATE(result(n))
          DO i = 1, n
            result(i) = field_state%T(i)
          END DO
        ELSE
          ALLOCATE(result(0))
        END IF

      ELSE
        !  
        ALLOCATE(result(0))
        IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Brg_AP_Query_Runtime_State_FromField

  SUBROUTINE Brg_AP_Query_Runtime_State(query_type, result, ierr)
    CHARACTER(LEN=*), INTENT(IN) :: query_type
    REAL(wp), INTENT(OUT), ALLOCATABLE, OPTIONAL :: result(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    IF (PRESENT(ierr)) ierr = 0
    !   field_state   Brg_AP_Query_Runtime_State_FromField
  END SUBROUTINE Brg_AP_Query_Runtime_State
END MODULE AP_Brg_L5