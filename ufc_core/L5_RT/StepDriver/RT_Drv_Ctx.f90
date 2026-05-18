!===============================================================================
! MODULE: RT_Drv_Ctx_Mod
! LAYER:  L5_RT
! DOMAIN: StepDriver / Driver
! ROLE:   Runtime driver context (model + solver + optional L3 UF_ModelDef).
! BRIEF:  Phase6 P0 — model_def pointer for material rollback wiring to RT_Step_Exec.
! NOTE:   Module name RT_Drv_Ctx_Mod avoids gfortran 6.x module/type homonym (TYPE RT_Drv_Ctx).
!===============================================================================
MODULE RT_Drv_Ctx_Mod
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE RT_Shared_Def, ONLY: RT_Sol_Cfg, UF_RT_JobStatus, UF_JobStatus_Success
  USE RT_Step_WS, ONLY: UF_Model
  USE MD_Model_Lib_Core, ONLY: UF_ModelDef
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Drv_Ctx
  PUBLIC :: RT_Drv_Ctx_Init
  PUBLIC :: RT_Drv_Ctx_Bind
  PUBLIC :: RT_Drv_Ctx_SetModelDef
  PUBLIC :: RT_Drv_Ctx_IsOK
  PUBLIC :: RT_Drv_Ctx_GetStatus

  TYPE, PUBLIC :: RT_Drv_Ctx
    TYPE(UF_Model), POINTER :: model => NULL()
    TYPE(RT_Sol_Cfg), POINTER :: solver => NULL()
    TYPE(UF_ModelDef), POINTER :: model_def => NULL()
    TYPE(UF_RT_JobStatus), POINTER :: rt_status => NULL()
    CHARACTER(LEN=256) :: job_name = ''
    LOGICAL :: success = .FALSE.
  CONTAINS
    PROCEDURE :: IsOK => RT_Drv_Ctx_IsOK
    PROCEDURE :: GetStatus => RT_Drv_Ctx_GetStatus
    PROCEDURE :: Init => RT_Drv_Ctx_Init
    PROCEDURE :: Bind => RT_Drv_Ctx_Bind
    PROCEDURE :: SetModelDef => RT_Drv_Ctx_SetModelDef
  END TYPE RT_Drv_Ctx

CONTAINS

  SUBROUTINE RT_Drv_Ctx_Init(this)
    CLASS(RT_Drv_Ctx), INTENT(INOUT) :: this
    NULLIFY(this%model)
    NULLIFY(this%solver)
    NULLIFY(this%model_def)
    NULLIFY(this%rt_status)
    this%job_name = ''
    this%success = .FALSE.
  END SUBROUTINE RT_Drv_Ctx_Init

  SUBROUTINE RT_Drv_Ctx_Bind(this, model, solver, jobName, rt_status)
    CLASS(RT_Drv_Ctx), INTENT(INOUT) :: this
    TYPE(UF_Model), TARGET, INTENT(IN), OPTIONAL :: model
    TYPE(RT_Sol_Cfg), TARGET, INTENT(IN), OPTIONAL :: solver
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: jobName
    TYPE(UF_RT_JobStatus), TARGET, INTENT(INOUT), OPTIONAL :: rt_status
    IF (PRESENT(model)) THEN
      this%model => model
    ELSE
      NULLIFY(this%model)
    END IF
    IF (PRESENT(solver)) THEN
      this%solver => solver
    ELSE
      NULLIFY(this%solver)
    END IF
    IF (PRESENT(jobName)) this%job_name = TRIM(jobName)
    IF (PRESENT(rt_status)) THEN
      this%rt_status => rt_status
    ELSE
      NULLIFY(this%rt_status)
    END IF
  END SUBROUTINE RT_Drv_Ctx_Bind

  SUBROUTINE RT_Drv_Ctx_SetModelDef(this, model_def)
    CLASS(RT_Drv_Ctx), INTENT(INOUT) :: this
    TYPE(UF_ModelDef), TARGET, INTENT(IN), OPTIONAL :: model_def
    IF (PRESENT(model_def)) THEN
      this%model_def => model_def
    ELSE
      NULLIFY(this%model_def)
    END IF
  END SUBROUTINE RT_Drv_Ctx_SetModelDef

  LOGICAL FUNCTION RT_Drv_Ctx_IsOK(this) RESULT(ok)
    CLASS(RT_Drv_Ctx), INTENT(IN) :: this
    ok = this%success
    IF (ASSOCIATED(this%rt_status)) THEN
      ok = ok .AND. (this%rt_status%code == UF_JobStatus_Success)
    END IF
  END FUNCTION RT_Drv_Ctx_IsOK

  SUBROUTINE RT_Drv_Ctx_GetStatus(this, status)
    CLASS(RT_Drv_Ctx), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (this%success) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_ERROR
      IF (ASSOCIATED(this%rt_status)) status%message = TRIM(this%rt_status%message)
    END IF
  END SUBROUTINE RT_Drv_Ctx_GetStatus

END MODULE RT_Drv_Ctx_Mod
