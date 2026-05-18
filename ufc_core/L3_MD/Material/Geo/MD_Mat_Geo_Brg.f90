!===============================================================================
! MODULE: MD_Mat_Geo_Brg
! LAYER:  L3_MD
! DOMAIN: Material / Geo
!===============================================================================
MODULE MD_Mat_Geo_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Geo_Def, ONLY: MD_Mat_Geo_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_GEO_SUB_DP_LINEAR, &
                               MD_MAT_GEO_SUB_DP_CAP, &
                               MD_MAT_GEO_SUB_MC, &
                               MD_MAT_GEO_SUB_CC_CRIT, &
                               MD_MAT_GEO_SUB_CONCRETE, &
                               MD_MAT_GEO_SUB_FOAM_CRUSH, &
                               MD_MAT_GEO_SUB_CAM_CLAY, &
                               MD_MAT_GEO_SUB_HOEK_BROWN
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Geo_Route_L4

CONTAINS

  SUBROUTINE MD_Mat_Geo_Route_L4(desc, status)
    TYPE(MD_Mat_Geo_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)

    SELECT CASE (desc%sub_type)
      CASE (MD_MAT_GEO_SUB_DP_LINEAR)
        CONTINUE
      CASE (MD_MAT_GEO_SUB_DP_CAP)
        CONTINUE
      CASE (MD_MAT_GEO_SUB_MC)
        CONTINUE
      CASE (MD_MAT_GEO_SUB_CC_CRIT)
        CONTINUE
      CASE (MD_MAT_GEO_SUB_CONCRETE)
        CONTINUE
      CASE (MD_MAT_GEO_SUB_FOAM_CRUSH)
        CONTINUE
      CASE (MD_MAT_GEO_SUB_CAM_CLAY)
        CONTINUE
      CASE (MD_MAT_GEO_SUB_HOEK_BROWN)
        CONTINUE
      CASE DEFAULT
        status%status_code = 1
    END SELECT
  END SUBROUTINE MD_Mat_Geo_Route_L4

END MODULE MD_Mat_Geo_Brg