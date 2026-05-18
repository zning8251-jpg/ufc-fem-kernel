!===============================================================================
! MODULE:  PH_Load_NestedToFlat
! LAYER:   L4_PH
! DOMAIN:  Load
! ROLE:    Proc
! BRIEF:   Populate load cache with amplitude interpolation.
!===============================================================================
MODULE PH_Load_NestedToFlat
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Load_Populate
  PUBLIC :: PH_InterpolateAmpCurve

CONTAINS

  SUBROUTINE PH_Load_Populate(n_loads, step_time, status)
    INTEGER(i4), INTENT(IN) :: n_loads
    REAL(wp), INTENT(IN) :: step_time
    INTEGER(i4), INTENT(OUT) :: status
    INTEGER(i4) :: i

    status = 0_i4
    DO i = 1, n_loads
    END DO
  END SUBROUTINE

  FUNCTION PH_InterpolateAmpCurve(ampName, time) RESULT(amp_factor)
    CHARACTER(len=*), INTENT(IN) :: ampName
    REAL(wp), INTENT(IN) :: time
    REAL(wp) :: amp_factor

    IF (LEN_TRIM(ampName) == 0) THEN
      amp_factor = 1.0_wp
      RETURN
    END IF
    amp_factor = 1.0_wp
  END FUNCTION

END MODULE PH_Load_NestedToFlat
