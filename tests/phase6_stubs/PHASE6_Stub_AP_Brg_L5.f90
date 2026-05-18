! Harness-only AP_Brg_L5: L5 StepRunner bridge for Phase6 PR1b smoke.
MODULE AP_Brg_L5
  USE IF_Prec_Core, ONLY: i4
  USE MD_Model_Lib_Core, ONLY: UF_ModelDef
  USE MD_TypeSystem, ONLY: State_Model
  USE AP_Job_Mgr, ONLY: JobCtx, JobOpts, AP_JOB_RT_FULL_JOB_DONE
  USE AP_Job_Def, ONLY: AP_Job_Desc
  USE RT_Drv_Ctx_Mod, ONLY: RT_Drv_Ctx
  USE RT_Driver_Core, ONLY: RT_RunModel_Ctx
  USE RT_Step_WS, ONLY: UF_Model
  USE RT_Shared_Def, ONLY: RT_Sol_Cfg
  IMPLICIT NONE
  PRIVATE
  TYPE(RT_Drv_Ctx), POINTER, SAVE :: g_brg_rt_ctx => NULL()
  PUBLIC :: Brg_AP_SetRTDrvCtx, Brg_AP_SetRTDrvModelDef, Brg_AP_StepRunner_RT
  PUBLIC :: Brg_AP_WireStepRunner_JobCtx

CONTAINS

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

  SUBROUTINE Brg_AP_SetRTDrvModelDef(model_def)
    TYPE(UF_ModelDef), TARGET, INTENT(IN) :: model_def
    IF (.NOT. ASSOCIATED(g_brg_rt_ctx)) RETURN
    CALL g_brg_rt_ctx%SetModelDef(model_def=model_def)
  END SUBROUTINE Brg_AP_SetRTDrvModelDef

  SUBROUTINE Brg_AP_WireStepRunner_JobCtx(ctxJob)
    TYPE(JobCtx), INTENT(INOUT) :: ctxJob
    ! Harness: StepRunner wiring documented; direct call used in test instead.
  END SUBROUTINE Brg_AP_WireStepRunner_JobCtx

  SUBROUTINE Brg_AP_StepRunner_RT(descJob, stateModel, stepIndex, opts, ierr)
    TYPE(AP_Job_Desc), INTENT(IN) :: descJob
    TYPE(State_Model), INTENT(INOUT) :: stateModel
    INTEGER(i4), INTENT(IN) :: stepIndex
    TYPE(JobOpts), INTENT(IN) :: opts
    INTEGER(i4), INTENT(OUT) :: ierr

    ierr = 0_i4
    IF (.NOT. ASSOCIATED(g_brg_rt_ctx)) THEN
      ierr = -1_i4
      RETURN
    END IF
    IF (.NOT. ASSOCIATED(g_brg_rt_ctx%model)) THEN
      ierr = -1_i4
      RETURN
    END IF
    IF (stepIndex /= 1_i4) THEN
      ierr = -1_i4
      RETURN
    END IF
    CALL RT_RunModel_Ctx(g_brg_rt_ctx)
    IF (g_brg_rt_ctx%success) THEN
      ierr = AP_JOB_RT_FULL_JOB_DONE
    ELSE
      ierr = -1_i4
    END IF
  END SUBROUTINE Brg_AP_StepRunner_RT

END MODULE AP_Brg_L5
