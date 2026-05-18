!===============================================================================
! MODULE: MD_Mat_Comp_Brg
! LAYER:  L3_MD
! DOMAIN: Material / Composite
!===============================================================================
MODULE MD_Mat_Comp_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Comp_Def, ONLY: MD_Mat_Comp_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_COMP_SUB_CLT, &
                               MD_MAT_COMP_SUB_HASHIN, &
                               MD_MAT_COMP_SUB_FABRIC, &
                               MD_MAT_COMP_SUB_JOINTED, &
                               MD_MAT_COMP_SUB_FOAM_VE
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: MD_Mat_Comp_Route_L4

CONTAINS

  SUBROUTINE MD_Mat_Comp_Route_L4(desc, status)
    TYPE(MD_Mat_Comp_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    CALL init_error_status(status)

    SELECT CASE (desc%sub_type)
      CASE (MD_MAT_COMP_SUB_CLT)
        CONTINUE
      CASE (MD_MAT_COMP_SUB_HASHIN)
        CONTINUE
      CASE (MD_MAT_COMP_SUB_FABRIC)
        CONTINUE
      CASE (MD_MAT_COMP_SUB_JOINTED)
        CONTINUE
      CASE (MD_MAT_COMP_SUB_FOAM_VE)
        CONTINUE
      CASE DEFAULT
        status%status_code = 1
    END SELECT
  END SUBROUTINE MD_Mat_Comp_Route_L4

END MODULE MD_Mat_Comp_Brg