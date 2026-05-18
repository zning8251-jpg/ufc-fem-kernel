! Harness-only RT_Step_WS subset for Phase6 driver smoke.
MODULE RT_Step_WS
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Model_Lib_Core, ONLY: UF_Model
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: UF_Model, JobWS

  TYPE :: JobWS
    INTEGER(i4) :: placeholder = 0_i4
  END TYPE JobWS

END MODULE RT_Step_WS
