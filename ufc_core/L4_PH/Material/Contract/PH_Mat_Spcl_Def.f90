!===============================================================================
! MODULE: PH_Mat_Spcl_Def
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Special material contract — unified Calc interface (mat_id 604,704-708).
!   W1: legacy UMAT invoke surface; align slot **desc** with **PH_Mat_Reg** entry when wiring new calls.
!===============================================================================

MODULE PH_Mat_Spcl_Def
  !! UniField-Core Special Mat Definition Module (UMAT single-track)
  !!   LAYER: L4 (Element Library)
  !!   DOMAIN: Mat/Special
  !!   KIND: Defn (unified interface for mat_id 604, 704-708)
  !!
  !! This module provides the main special Mat interface:
  !!   - UF_Mat_Special_Calc: Unified interface for special materials
  !!   - Routes via Defn_Invoke_UMAT(mat_id) for mat_type 1-5.
  !!
  !! Design Principles:
  !!   - UMAT single-track: Defn -> TypeToId -> Defn_Invoke_UMAT -> Reg
  !! ===================================================================

  USE IF_Base_Def, ONLY: ZERO
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MatProperties
  USE PH_Mat_Defn_UMAT_Bridge, ONLY: Defn_Invoke_UMAT, Defn_Invoke_UMAT_Arg, PH_Mat_TypeToId, &
      PH_MAT_CAT_SPCL, PH_MAT_ID_INVALID

  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: UF_Mat_Special_Calc
  PUBLIC :: UF_Mat_Special_Calc_Arg

  ! Mat type constants
  INTEGER(i4), PARAMETER :: PH_MAT_SPECIAL_4D_PRINTING = 1
  INTEGER(i4), PARAMETER :: PH_MAT_SPECIAL_PIEZOELECTRIC = 2
  INTEGER(i4), PARAMETER :: PH_MAT_SPECIAL_MAGNETOSTRICTIVE = 3
  INTEGER(i4), PARAMETER :: PH_MAT_SPECIAL_MAGNETORHEOLOGICAL = 4
  INTEGER(i4), PARAMETER :: PH_MAT_SPECIAL_ELECTRORHEOLOGICAL = 5

  ! SIO bundle for UF_Mat_Special_Calc (INTF-001)
  TYPE, PUBLIC :: UF_Mat_Special_Calc_Arg
    INTEGER(i4) :: matType = 0_i4                    ! [IN] category-local type id
    TYPE(MatProperties) :: Mat                       ! [IN]
    REAL(wp) :: strain_in(6) = 0.0_wp                ! [IN]
    REAL(wp) :: stress_out(6) = 0.0_wp               ! [OUT]
    REAL(wp) :: tangent_out(6, 6) = 0.0_wp           ! [OUT] valid when want_tangent=.TRUE.
    LOGICAL :: want_tangent = .FALSE.                ! [IN] request tangent_out fill
    TYPE(ErrorStatusType) :: status                  ! [OUT]
  END TYPE UF_Mat_Special_Calc_Arg

CONTAINS

  SUBROUTINE UF_Mat_Special_Calc(arg)
    TYPE(UF_Mat_Special_Calc_Arg), INTENT(INOUT) :: arg
    INTEGER(i4) :: mat_id
    TYPE(Defn_Invoke_UMAT_Arg) :: du

    CALL init_error_status(arg%status)
    arg%stress_out = ZERO
    arg%tangent_out = ZERO

    mat_id = PH_Mat_TypeToId(PH_MAT_CAT_SPCL, arg%matType)
    IF (mat_id == PH_MAT_ID_INVALID) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'UF_Mat_Special_Calc: Unknown or unsupported Mat type'
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

  END SUBROUTINE UF_Mat_Special_Calc

END MODULE PH_Mat_Spcl_Def
