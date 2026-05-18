!===============================================================================
! MODULE: MD_Mat_Visco_Brg
! LAYER:  L3_MD
! DOMAIN: Material / Viscoelastic
! ROLE:   Brg
! BRIEF:  L4 routing bridge for Viscoelastic family.
!         Updated for Phase 3 Stage 1: Unified template with sub_type routing.
!===============================================================================
MODULE MD_Mat_Visco_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Visco_Def, ONLY: MD_Mat_Visco_Desc
  USE MD_Mat_Family_Def, ONLY: MD_MAT_VE_SUB_PRONY_DEV, &
                               MD_MAT_VE_SUB_PRONY_VOL, &
                               MD_MAT_VE_SUB_KELVIN, &
                               MD_MAT_VE_SUB_WLF_SHIFT
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Visco_Route_L4

CONTAINS

  !-----------------------------------------------------------------------------
  ! [IN] desc: Material descriptor
  ! [OUT] status: Error status from routing
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_Visco_Route_L4(desc, status)
    TYPE(MD_Mat_Visco_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (desc%sub_type)
      CASE (MD_MAT_VE_SUB_PRONY_DEV)
        ! Route to L4 Prony deviatoric
        CONTINUE
      CASE (MD_MAT_VE_SUB_PRONY_VOL)
        ! Route to L4 Prony volumetric
        CONTINUE
      CASE (MD_MAT_VE_SUB_KELVIN)
        ! Route to L4 Kelvin-Voigt
        CONTINUE
      CASE (MD_MAT_VE_SUB_WLF_SHIFT)
        ! Route to L4 WLF shift
        CONTINUE
      CASE DEFAULT
        status%status_code = 1
        status%message = "MD_Mat_Visco_Brg: Invalid sub_type for routing"
    END SELECT

  END SUBROUTINE MD_Mat_Visco_Route_L4

END MODULE MD_Mat_Visco_Brg