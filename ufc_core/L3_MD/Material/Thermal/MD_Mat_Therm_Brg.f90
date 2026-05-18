!===============================================================================
! MODULE: MD_Mat_Therm_Brg
! LAYER:  L3_MD
! DOMAIN: Material / Thermal
!===============================================================================
MODULE MD_Mat_Therm_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Therm_Def, ONLY: MD_Mat_Therm_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_HEAT_SUB_ISO, &
                               MD_MAT_HEAT_SUB_ORTHO, &
                               MD_MAT_HEAT_SUB_PHASE_CHG
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Therm_Route_L4

CONTAINS

  SUBROUTINE MD_Mat_Therm_Route_L4(desc, status)
    TYPE(MD_Mat_Therm_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)

    SELECT CASE (desc%sub_type)
      CASE (MD_MAT_HEAT_SUB_ISO)
        CONTINUE
      CASE (MD_MAT_HEAT_SUB_ORTHO)
        CONTINUE
      CASE (MD_MAT_HEAT_SUB_PHASE_CHG)
        CONTINUE
      CASE DEFAULT
        status%status_code = 1
    END SELECT
  END SUBROUTINE MD_Mat_Therm_Route_L4

END MODULE MD_Mat_Therm_Brg