!===============================================================================
! MODULE: MD_Mat_Acou_Brg
! LAYER:  L3_MD
! DOMAIN: Material / Acoustic
!===============================================================================
MODULE MD_Mat_Acou_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Acou_Def, ONLY: MD_Mat_Acou_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_ACOU_SUB_LINEAR, &
                               MD_MAT_ACOU_SUB_ABSORB
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Acou_Route_L4

CONTAINS

  SUBROUTINE MD_Mat_Acou_Route_L4(desc, status)
    TYPE(MD_Mat_Acou_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)

    SELECT CASE (desc%sub_type)
      CASE (MD_MAT_ACOU_SUB_LINEAR)
        CONTINUE
      CASE (MD_MAT_ACOU_SUB_ABSORB)
        CONTINUE
      CASE DEFAULT
        status%status_code = 1
    END SELECT
  END SUBROUTINE MD_Mat_Acou_Route_L4

END MODULE MD_Mat_Acou_Brg