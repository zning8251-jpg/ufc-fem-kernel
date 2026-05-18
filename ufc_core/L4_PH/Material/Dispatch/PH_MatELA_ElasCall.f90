!===============================================================================
! MODULE: PH_MatELA_ElasCall
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Dispatch
! BRIEF:  Elastic stress dispatch (mat_type -> mat_id -> Defn_Invoke_UMAT).
!   W1: **matType** is category-local enum for **PH_Mat_TypeToId**; Populate /
!   slot gold path carries family on **PH_Mat_Desc** via **PH_Mat_Desc_Effective_Model**.
! Purpose: Elastic branch dispatch helper for stress/tangent from matType + MatProperties.
! Theory: Category-local matType maps through PH_Mat_TypeToId; Populate/slot carries PH_Mat_Desc effective model.
! Status: ACTIVE
!===============================================================================

MODULE PH_MatELA_ElasCall
  USE IF_Base_Def, ONLY: ZERO
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatProperties
  USE PH_Mat_Defn_UMAT_Bridge, ONLY: Defn_Invoke_UMAT, Defn_Invoke_UMAT_Arg, PH_Mat_TypeToId, &
      PH_MAT_CAT_ELASTIC, PH_MAT_ID_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UF_Mat_Elastic_Calc
  PUBLIC :: UF_Mat_Elastic_Calc_Arg

  ! SIO bundle for UF_Mat_Elastic_Calc (INTF-001)
  TYPE, PUBLIC :: UF_Mat_Elastic_Calc_Arg
    INTEGER(i4) :: matType = 0_i4                    ! [IN] category-local type id
    TYPE(MatProperties) :: Mat                       ! [IN]
    REAL(wp) :: strain_in(6) = 0.0_wp                ! [IN]
    REAL(wp) :: stress_out(6) = 0.0_wp               ! [OUT]
    REAL(wp) :: tangent_out(6, 6) = 0.0_wp           ! [OUT] valid when want_tangent=.TRUE.
    LOGICAL :: want_tangent = .FALSE.                ! [IN] request tangent_out fill
    TYPE(ErrorStatusType) :: status                  ! [OUT]
  END TYPE UF_Mat_Elastic_Calc_Arg

CONTAINS

  SUBROUTINE UF_Mat_Elastic_Calc(arg)
    TYPE(UF_Mat_Elastic_Calc_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: mat_id
    TYPE(Defn_Invoke_UMAT_Arg) :: du

    CALL init_error_status(arg%status)
    arg%stress_out = ZERO
    arg%tangent_out = ZERO

    mat_id = PH_Mat_TypeToId(PH_MAT_CAT_ELASTIC, arg%matType)
    IF (mat_id == PH_MAT_ID_INVALID) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'UF_Mat_Elastic_Calc: Unknown or unsupported Mat type'
      RETURN
    END IF

    du%mat_id = mat_id
    ALLOCATE(du%mat, source=arg%Mat)
    du%strain_in = arg%strain_in
    du%want_tangent = arg%want_tangent
    CALL Defn_Invoke_UMAT(du)
    arg%stress_out = du%stress_out
    arg%tangent_out = du%tangent_out
    arg%status = du%status
    IF (ALLOCATED(du%mat)) DEALLOCATE(du%mat)

  END SUBROUTINE UF_Mat_Elastic_Calc

END MODULE PH_MatELA_ElasCall
