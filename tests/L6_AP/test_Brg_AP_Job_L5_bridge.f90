!===============================================================================
! PROGRAM: test_Brg_AP_Job_L5_bridge
! PURPOSE: Phase6 PR1b — Brg_AP_StepRunner_RT invokes RT_RunModel_Ctx with model_def.
!===============================================================================
PROGRAM test_Brg_AP_Job_L5_bridge
  USE IF_Prec_Core, ONLY: i4
  USE AP_Job_Def, ONLY: AP_Job_Desc
  USE AP_Job_Mgr, ONLY: JobOpts, AP_JOB_RT_FULL_JOB_DONE
  USE AP_Brg_L5, ONLY: Brg_AP_SetRTDrvCtx, Brg_AP_StepRunner_RT
  USE MD_Model_Lib_Core, ONLY: UF_ModelDef
  USE MD_TypeSystem, ONLY: State_Model
  USE RT_Drv_Ctx_Mod, ONLY: RT_Drv_Ctx
  USE RT_Step_Exec, ONLY: PHASE6_step_exec_saw_model_def
  USE RT_Step_WS, ONLY: UF_Model
  IMPLICIT NONE
  TYPE(RT_Drv_Ctx), TARGET :: ctx
  TYPE(RT_Drv_Ctx), POINTER :: ctxPtr => NULL()
  TYPE(UF_Model), TARGET :: model
  TYPE(UF_ModelDef), TARGET :: model_def
  TYPE(AP_Job_Desc) :: descJob
  TYPE(State_Model) :: stateModel
  TYPE(JobOpts) :: opts
  INTEGER(i4) :: ierr

  CALL ctx%Init()
  model_def%name = 'l6_bridge'
  model%model_def => model_def
  ctx%model => model
  ctxPtr => ctx
  CALL Brg_AP_SetRTDrvCtx(ctxPtr, model_def=model_def)

  ierr = 0_i4
  CALL Brg_AP_StepRunner_RT(descJob, stateModel, 1_i4, opts, ierr)

  IF (ierr /= AP_JOB_RT_FULL_JOB_DONE) THEN
    WRITE(*, '(A,I0)') '[l6-bridge] FAIL: ierr=', ierr
    STOP 1
  END IF
  IF (.NOT. PHASE6_step_exec_saw_model_def) THEN
    WRITE(*, '(A)') '[l6-bridge] FAIL: model_def not seen by StepDriver'
    STOP 1
  END IF
  WRITE(*, '(A)') '[l6-bridge] Brg_AP_StepRunner_RT smoke OK'
  STOP 0
END PROGRAM test_Brg_AP_Job_L5_bridge
