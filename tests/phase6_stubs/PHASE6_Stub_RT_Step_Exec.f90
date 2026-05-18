! Harness-only RT_Step_Exec: records model_def presence for Phase6 §1.3 smoke.
MODULE RT_Step_Exec
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Model_Lib_Core, ONLY: UF_Model, UF_ModelDef
  USE MD_Step_Proc, ONLY: AnalysisStep
  USE RT_Step_Def, ONLY: RT_StepDriver_Result, RT_StepDriver_Config
  USE RT_Step_WS, ONLY: JobWS
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: RT_StepDriver_Execute
  PUBLIC :: PHASE6_step_exec_saw_model_def

  LOGICAL, SAVE :: PHASE6_step_exec_saw_model_def = .FALSE.

CONTAINS

  SUBROUTINE RT_StepDriver_Execute(model, step, workspace, config, result, status, model_def)
    TYPE(UF_Model), INTENT(INOUT) :: model
    TYPE(AnalysisStep), INTENT(INOUT) :: step
    TYPE(JobWS), INTENT(INOUT) :: workspace
    TYPE(RT_StepDriver_Config), INTENT(IN), OPTIONAL :: config
    TYPE(RT_StepDriver_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(UF_ModelDef), INTENT(INOUT), OPTIONAL, TARGET :: model_def

    CALL init_error_status(status)
    PHASE6_step_exec_saw_model_def = PRESENT(model_def)
    IF (PRESENT(model_def)) THEN
      result%success = .TRUE.
      result%message = 'PHASE6 smoke: model_def forwarded'
      status%status_code = IF_STATUS_OK
    ELSE
      result%success = .FALSE.
      result%message = 'PHASE6 smoke: model_def missing'
      status%status_code = IF_STATUS_INVALID
    END IF
  END SUBROUTINE RT_StepDriver_Execute

END MODULE RT_Step_Exec
