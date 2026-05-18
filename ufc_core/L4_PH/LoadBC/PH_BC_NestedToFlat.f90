!===============================================================================
! MODULE:  PH_BC_NestedToFlat
! LAYER:   L4_PH
! DOMAIN:  BC
! ROLE:    Proc
! BRIEF:   Populate BC cache with amplitude interpolation.
!===============================================================================
MODULE PH_BC_NestedToFlat
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_BC_Populate
  PUBLIC :: PH_BC_InterpolateAmpCurve

CONTAINS

  SUBROUTINE PH_BC_Populate(n_bcs, step_time, status)
    INTEGER(i4), INTENT(IN) :: n_bcs
    REAL(wp), INTENT(IN) :: step_time
    INTEGER(i4), INTENT(OUT) :: status
    INTEGER(i4) :: i

    status = 0_i4
    DO i = 1, n_bcs
    END DO
  END SUBROUTINE

  FUNCTION PH_BC_InterpolateAmpCurve(ampName, time) RESULT(amp_factor)
    CHARACTER(len=*), INTENT(IN) :: ampName
    REAL(wp), INTENT(IN) :: time
    REAL(wp) :: amp_factor

    IF (LEN_TRIM(ampName) == 0) THEN
      amp_factor = 1.0_wp
      RETURN
    END IF
    amp_factor = 1.0_wp
  END FUNCTION

END MODULE PH_BC_NestedToFlat
