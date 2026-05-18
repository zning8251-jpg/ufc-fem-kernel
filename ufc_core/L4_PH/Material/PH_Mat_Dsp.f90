!===============================================================================
! MODULE: PH_Mat_Dsp
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Dsp — family-level dispatch guard for PH_Mat_Core S2 / RT stress routing
! BRIEF:  Validates **PH_MAT_*** family markers before hot-path kernel work.
!
! History: Renamed from PH_Mat_Dispatch (2026-05-11) per domain naming convention.
! Purpose: Guard PH_MAT_* family markers before PH_Mat_Core S2 / RT stress routing.
! Theory: SELECT CASE on mat_type only; no constitutive integration (delegated to kernels).
! Status: ACTIVE
!===============================================================================
MODULE PH_Mat_Dsp
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Enum, ONLY: &
    PH_MAT_UNKNOWN, PH_MAT_ELASTIC, PH_MAT_ELASTO_PLASTIC, PH_MAT_HYPERELASTIC, &
    PH_MAT_VISCOELASTIC, PH_MAT_CREEP, PH_MAT_DAMAGE, PH_MAT_GEOTECH, &
    PH_MAT_COMPOSITE, PH_MAT_THERMAL, PH_MAT_ACOUSTIC, PH_MAT_USER, PH_MAT_USER_VUMAT
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Mat_Dispatch_Stress, PH_Mat_Dispatch_Tangent

CONTAINS

  SUBROUTINE PH_Mat_Dispatch_Stress(mat_type, status)
    INTEGER(i4), INTENT(IN) :: mat_type
    TYPE(ErrorStatusType), INTENT(INOUT) :: status

    CALL init_error_status(status)
    SELECT CASE (mat_type)
    CASE (PH_MAT_ELASTIC, PH_MAT_ELASTO_PLASTIC, PH_MAT_HYPERELASTIC, &
          PH_MAT_VISCOELASTIC, PH_MAT_CREEP, PH_MAT_DAMAGE, PH_MAT_GEOTECH, &
          PH_MAT_COMPOSITE, PH_MAT_THERMAL, PH_MAT_ACOUSTIC, PH_MAT_USER, PH_MAT_USER_VUMAT)
      status%status_code = IF_STATUS_OK
    CASE DEFAULT
      IF (mat_type == PH_MAT_UNKNOWN) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[PH_Mat_Dsp]: PH_MAT_UNKNOWN"
      ELSE
        status%status_code = IF_STATUS_OK
      END IF
    END SELECT
  END SUBROUTINE PH_Mat_Dispatch_Stress

  SUBROUTINE PH_Mat_Dispatch_Tangent(mat_type, status)
    INTEGER(i4), INTENT(IN) :: mat_type
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    CALL PH_Mat_Dispatch_Stress(mat_type, status)
  END SUBROUTINE PH_Mat_Dispatch_Tangent

END MODULE PH_Mat_Dsp
