! Harness-only RT_Driver_Core (mirrors production model_def forward).
MODULE RT_Driver_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Drv_Ctx_Mod, ONLY: RT_Drv_Ctx
  USE RT_Shared_Def, ONLY: UF_RT_JobStatus, UF_JobStatus_Success
  USE RT_Step_WS, ONLY: UF_Model, JobWS
  USE MD_Step_Proc, ONLY: AnalysisStep
  USE RT_Step_Exec, ONLY: RT_StepDriver_Execute
  USE RT_Step_Def, ONLY: RT_StepDriver_Result, RT_StepDriver_Config
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: RT_RunModel_Ctx

CONTAINS

  SUBROUTINE RT_RunModel_Ctx(ctx)
    TYPE(RT_Drv_Ctx), INTENT(INOUT) :: ctx
    TYPE(JobWS) :: workspace
    TYPE(AnalysisStep) :: step
    TYPE(RT_StepDriver_Result) :: result
    TYPE(ErrorStatusType) :: status

    CALL init_error_status(status)
    ctx%success = .FALSE.
    IF (.NOT. ASSOCIATED(ctx%model)) THEN
      IF (ASSOCIATED(ctx%rt_status)) THEN
        ctx%rt_status%message = 'RT_RunModel_Ctx: model not bound'
      END IF
      RETURN
    END IF

    step%time_period = 1.0_wp
    step%name = TRIM(ctx%job_name)

    IF (ASSOCIATED(ctx%model_def)) THEN
      CALL RT_StepDriver_Execute(ctx%model, step, workspace, result=result, status=status, &
           model_def=ctx%model_def)
    ELSE
      CALL RT_StepDriver_Execute(ctx%model, step, workspace, result=result, status=status)
    END IF

    ctx%success = result%success
    IF (ASSOCIATED(ctx%rt_status)) THEN
      IF (ctx%success) THEN
        ctx%rt_status%code = UF_JobStatus_Success
        ctx%rt_status%message = TRIM(result%message)
      ELSE
        ctx%rt_status%message = TRIM(status%message)
      END IF
    END IF
  END SUBROUTINE RT_RunModel_Ctx

END MODULE RT_Driver_Core
