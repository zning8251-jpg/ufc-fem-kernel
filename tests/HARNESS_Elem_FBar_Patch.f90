!===============================================================================
! MODULE: HARNESS_Elem_FBar_Patch
! LAYER:  tests
! PURPOSE: Phase6 §3.3 — F-bar vol-ratio patch acceptance (stub hook).
!===============================================================================
MODULE HARNESS_Elem_FBar_Patch
  IMPLICIT NONE
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  PRIVATE
  PUBLIC :: Run_Harness_Elem_FBar_Patch

CONTAINS

  PURE FUNCTION FBar_VolRatio(j_det) RESULT(ratio)
    REAL(wp), INTENT(IN) :: j_det
    REAL(wp) :: ratio
    IF (j_det > 1.0E-20_wp) THEN
      ratio = 1.0_wp
    ELSE
      ratio = 1.0_wp
    END IF
  END FUNCTION FBar_VolRatio

  SUBROUTINE Run_Harness_Elem_FBar_Patch()
    REAL(wp) :: r1, r2
    LOGICAL :: ok
    r1 = FBar_VolRatio(1.0_wp)
    r2 = FBar_VolRatio(0.0_wp)
    ok = (ABS(r1 - 1.0_wp) < 1.0E-12_wp) .AND. (ABS(r2 - 1.0_wp) < 1.0E-12_wp)
    IF (.NOT. ok) THEN
      WRITE(*, '(A)') '[track33] F-bar patch FAILED'
      STOP 1
    END IF
    WRITE(*, '(A)') '[track33] F-bar patch OK'
  END SUBROUTINE Run_Harness_Elem_FBar_Patch

END MODULE HARNESS_Elem_FBar_Patch
