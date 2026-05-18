! Harness-only RT_Step_Def subset for Phase6 driver smoke.
MODULE RT_Step_Def
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: RT_StepDriver_Result, RT_StepDriver_Config

  TYPE :: RT_StepDriver_Result
    LOGICAL :: success = .FALSE.
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_StepDriver_Result

  TYPE :: RT_StepDriver_Config
    INTEGER(i4) :: placeholder = 0_i4
  END TYPE RT_StepDriver_Config

END MODULE RT_Step_Def
