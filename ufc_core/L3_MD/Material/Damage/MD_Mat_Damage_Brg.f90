!===============================================================================
! MODULE: MD_Mat_Damage_Brg
! LAYER:  L3_MD
! DOMAIN: Material / Damage
! ROLE:   Brg
! BRIEF:  L4 routing bridge for Damage family.
!         Updated for Phase 3 Stage 1: Unified template with sub_type routing.
!===============================================================================
MODULE MD_Mat_Damage_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Damage_Def, ONLY: MD_Mat_Damage_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_DMG_SUB_DUCTILE, &
                               MD_MAT_DMG_SUB_SHEAR, &
                               MD_MAT_DMG_SUB_BRITTLE, &
                               MD_MAT_DMG_SUB_FLD, &
                               MD_MAT_DMG_SUB_CZM, &
                               MD_MAT_DMG_SUB_CONCRETE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Damage_Route_L4

CONTAINS

  !-----------------------------------------------------------------------------
  ! [IN] desc: Material descriptor
  ! [OUT] status: Error status from routing
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Damage_Route_L4(desc, status)
    TYPE(MD_Mat_Damage_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (desc%sub_type)
      CASE (MD_MAT_DMG_SUB_DUCTILE)
        ! Route to L4 Ductile damage
        CONTINUE
      CASE (MD_MAT_DMG_SUB_SHEAR)
        ! Route to L4 Shear damage
        CONTINUE
      CASE (MD_MAT_DMG_SUB_BRITTLE)
        ! Route to L4 Brittle fracture
        CONTINUE
      CASE (MD_MAT_DMG_SUB_FLD)
        ! Route to L4 Forming limit diagram
        CONTINUE
      CASE (MD_MAT_DMG_SUB_CZM)
        ! Route to L4 Cohesive zone model
        CONTINUE
      CASE (MD_MAT_DMG_SUB_CONCRETE)
        ! Route to L4 Concrete damage (CDP)
        CONTINUE
      CASE DEFAULT
        status%status_code = 1
        status%message = "MD_Mat_Damage_Brg: Invalid sub_type for routing"
    END SELECT

  END SUBROUTINE MD_Mat_Damage_Route_L4

END MODULE MD_Mat_Damage_Brg