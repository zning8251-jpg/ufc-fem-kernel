! Harness-only RT_Solv_Def subset for Phase6 arclen smoke.
MODULE RT_Solv_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: RT_Sol_DofMap, RT_CSRMatrix

  TYPE :: RT_Sol_DofMap
    INTEGER(i4) :: nTotalEq = 0_i4
  END TYPE RT_Sol_DofMap

  TYPE :: RT_CSRMatrix
    INTEGER(i4) :: nRows = 0_i4
    INTEGER(i4), ALLOCATABLE :: rowPtr(:)
    INTEGER(i4), ALLOCATABLE :: colInd(:)
    REAL(wp), ALLOCATABLE :: values(:)
  END TYPE RT_CSRMatrix

END MODULE RT_Solv_Def
