!===============================================================================
! PROGRAM: test_RT_RunModel_Ctx_model_def
! PURPOSE: Phase6 PR1a — RT_RunModel_Ctx forwards model_def to RT_StepDriver_Execute.
! Build: tools/phase6_fortran_run.py --test rt_drv (harness stubs + production driver).
!===============================================================================
PROGRAM test_RT_RunModel_Ctx_model_def
  USE IF_Prec_Core, ONLY: i4
  USE MD_Model_Lib_Core, ONLY: UF_ModelDef
  USE RT_Drv_Ctx_Mod, ONLY: RT_Drv_Ctx
  USE RT_Driver_Core, ONLY: RT_RunModel_Ctx
  USE RT_Step_Exec, ONLY: PHASE6_step_exec_saw_model_def
  USE RT_Step_WS, ONLY: UF_Model
  IMPLICIT NONE
  TYPE(RT_Drv_Ctx) :: ctx
  TYPE(UF_Model), TARGET :: model
  TYPE(UF_ModelDef), TARGET :: model_def

  CALL ctx%Init()
  model_def%name = 'phase6_smoke'
  model_def%nMaterials = 1_i4
  model%model_def => model_def
  ctx%model => model
  CALL ctx%SetModelDef(model_def=model_def)

  CALL RT_RunModel_Ctx(ctx)

  IF (.NOT. PHASE6_step_exec_saw_model_def) THEN
    WRITE(*, '(A)') '[rt_drv] FAIL: StepDriver did not receive model_def'
    STOP 1
  END IF
  IF (.NOT. ctx%success) THEN
    WRITE(*, '(A)') '[rt_drv] FAIL: ctx%success expected .TRUE. when model_def set'
    STOP 1
  END IF
  WRITE(*, '(A)') '[rt_drv] RT_RunModel_Ctx model_def smoke OK'
  STOP 0
END PROGRAM test_RT_RunModel_Ctx_model_def
