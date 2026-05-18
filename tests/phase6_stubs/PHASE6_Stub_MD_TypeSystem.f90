! Harness-only MD_TypeSystem subset.
MODULE MD_TypeSystem
  USE IF_Prec_Core, ONLY: i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: State_Model

  TYPE :: State_Model
    INTEGER(i4) :: nStepsTotal = 1_i4
  END TYPE State_Model

END MODULE MD_TypeSystem
