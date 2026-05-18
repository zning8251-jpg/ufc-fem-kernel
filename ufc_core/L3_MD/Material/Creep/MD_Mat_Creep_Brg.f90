!===============================================================================
! MODULE: MD_Mat_Creep_Brg
! LAYER:  L3_MD
! DOMAIN: Material / Creep
! ROLE:   Brg
! BRIEF:  L4 routing bridge for Creep family.
!         Updated for Phase 3 Stage 1: Unified template with sub_type routing.
!===============================================================================
MODULE MD_Mat_Creep_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Creep_Def, ONLY: MD_Mat_Creep_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_CREEP_SUB_POWER, &
                               MD_MAT_CREEP_SUB_USER, &
                               MD_MAT_CREEP_SUB_TWO_LAYER, &
                               MD_MAT_CREEP_SUB_ANNEAL, &
                               MD_MAT_CREEP_SUB_GAROFALO, &
                               MD_MAT_CREEP_SUB_PERZYNA, &
                               MD_MAT_CREEP_SUB_DUVAUT, &
                               MD_MAT_CREEP_SUB_BODNER
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Creep_Route_L4

CONTAINS

  !-----------------------------------------------------------------------------
  ! [IN] desc: Material descriptor
  ! [OUT] status: Error status from routing
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Creep_Route_L4(desc, status)
    TYPE(MD_Mat_Creep_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (desc%sub_type)
      CASE (MD_MAT_CREEP_SUB_POWER)
        ! Route to L4 Power-Law Creep
        CONTINUE
      CASE (MD_MAT_CREEP_SUB_GAROFALO)
        ! Route to L4 Garofalo Creep
        CONTINUE
      CASE (MD_MAT_CREEP_SUB_PERZYNA)
        ! Route to L4 Perzyna Viscoplasticity
        CONTINUE
      CASE (MD_MAT_CREEP_SUB_BODNER)
        ! Route to L4 Bodner-Partom
        CONTINUE
      CASE (MD_MAT_CREEP_SUB_TWO_LAYER)
        ! Route to L4 Two-Layer Viscoplasticity
        CONTINUE
      CASE (MD_MAT_CREEP_SUB_ANNEAL)
        ! Route to L4 Annealing
        CONTINUE
      CASE (MD_MAT_CREEP_SUB_DUVAUT)
        ! Route to L4 Duvaut-Lions
        CONTINUE
      CASE (MD_MAT_CREEP_SUB_USER)
        ! Route to L4 User Creep
        CONTINUE
      CASE DEFAULT
        status%status_code = 1
        status%message = "MD_Mat_Creep_Brg: Invalid sub_type for routing"
    END SELECT

  END SUBROUTINE MD_Mat_Creep_Route_L4

END MODULE MD_Mat_Creep_Brg
