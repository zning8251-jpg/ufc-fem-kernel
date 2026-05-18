!===============================================================================
! MODULE: PH_Mat_Geo_Core
! LAYER:  L4_PH
! DOMAIN: Material / Geo
! ROLE:   Core
! BRIEF:  Unified family-level kernel dispatch for Geo material models.
!         Routes to model-specific *_Core modules based on sub_type.
!
! Models:
!   PH_MAT_GEO_SUB_DP_LINEAR (701) -> PH_Mat_Geo_DP_Core
!   PH_MAT_GEO_SUB_DP_CAP    (702) -> PH_Mat_Geo_DP_Core (cap extension)
!   PH_MAT_GEO_SUB_MC        (703) -> PH_Mat_Geo_MohrCoulomb_Core
!   PH_MAT_GEO_SUB_CAM_CLAY  (704) -> PH_Mat_Geo_CamClay_Core
!
! Note: PH_Mat_Geo_DP_Core.f90 (SIO modern) and
!       PH_Mat_Geo_DruckerPrager_Core.f90 (legacy UMAT facade)
!       are complementary — both retained.
!===============================================================================
MODULE PH_Mat_Geo_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Geo_Def, ONLY: PH_Mat_Geo_Desc, PH_Mat_Geo_State, &
                              PH_Mat_Geo_Algo, PH_Mat_Geo_Ctx, &
                              PH_MAT_GEO_SUB_DP_LINEAR, &
                              PH_MAT_GEO_SUB_DP_CAP, &
                              PH_MAT_GEO_SUB_MC, &
                              PH_MAT_GEO_SUB_CAM_CLAY, &
                              PH_MAT_GEO_SUB_HOEK_BROWN
  ! [STUB] Will be connected when adapter layer is implemented
  ! USE PH_Mat_Geo_DP_Core, ONLY: PH_Mat_Geo_DP_Core_Update
  ! USE PH_Mat_Geo_MohrCoulomb_Core, ONLY: PH_Mat_Geo_MC_Eval_Wrapper
  ! USE PH_Mat_Geo_CamClay_Core, ONLY: PH_Mat_Geo_CC_Eval_Wrapper
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Geo_Dispatch_Eval
  PUBLIC :: PH_Mat_Geo_Populate_From_L3

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Geo_Dispatch_Eval
  ! Unified family-level dispatch: routes to model-specific Core by sub_type.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Geo_Dispatch_Eval(desc, state, algo, ctx, status)
    TYPE(PH_Mat_Geo_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_Geo_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Geo_Algo),  INTENT(IN)    :: algo
    TYPE(PH_Mat_Geo_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    SELECT CASE (desc%cfg%sub_type)
    CASE (PH_MAT_GEO_SUB_DP_LINEAR, PH_MAT_GEO_SUB_DP_CAP)
      ! Drucker-Prager (linear / cap) -> SIO core
      ! TODO: Adapter layer needed:
      !   PH_Mat_Geo_Desc  -> MD_Mat_DP_Desc
      !   PH_Mat_Geo_State -> PH_Mat_PLM_DP_State
      !   PH_Mat_Geo_Algo  -> PH_Mat_PLM_DP_Algo
      !   PH_Mat_Geo_Ctx   -> PH_Mat_Krnl_Ctx
      !   ErrorStatusType  -> PH_Mat_DP_Update_Arg
      ! Then call: PH_Mat_Geo_DP_Core_Update(dp_desc, dp_state, dp_algo, krnl_ctx, dp_arg)
      status%status_code = IF_STATUS_OK

    CASE (PH_MAT_GEO_SUB_MC)
      ! Mohr-Coulomb -> wrapper from MC core
      ! TODO: Adapter layer needed:
      !   Signature requires 7 args: (desc, state, algo, strain, stress, ddsdde, status)
      !   Extract strain/stress/ddsdde from PH_Mat_Geo_Ctx before calling
      ! Then call: PH_Mat_Geo_MC_Eval_Wrapper(mc_desc, mc_state, mc_algo, strain, stress, ddsdde, status)
      status%status_code = IF_STATUS_OK

    CASE (PH_MAT_GEO_SUB_CAM_CLAY)
      ! Modified Cam-Clay -> wrapper from CC core
      ! TODO: Adapter layer needed:
      !   Signature requires 7 args: (desc, state, algo, strain_in, stress, ddsdde, status)
      !   Extract strain_in/stress/ddsdde from PH_Mat_Geo_Ctx before calling
      ! Then call: PH_Mat_Geo_CC_Eval_Wrapper(cc_desc, cc_state, cc_algo, strain_in, stress, ddsdde, status)
      status%status_code = IF_STATUS_OK

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Geo_Core]: Unknown sub_type"
    END SELECT
  END SUBROUTINE PH_Mat_Geo_Dispatch_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Geo_Populate_From_L3
  ! Populate Geo Desc from L3 property arrays.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Geo_Populate_From_L3(desc, l3_props, l3_nprops, &
                                          l3_sub_type, status)
    TYPE(PH_Mat_Geo_Desc), INTENT(OUT) :: desc
    REAL(wp), INTENT(IN) :: l3_props(:)
    INTEGER(i4), INTENT(IN) :: l3_nprops, l3_sub_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    desc%cfg%sub_type = l3_sub_type

    ! Populate common elastic properties
    IF (l3_nprops >= 2) THEN
      desc%E  = l3_props(1)
      desc%nu = l3_props(2)
    END IF

    ! Populate geo-specific properties based on sub_type
    SELECT CASE (l3_sub_type)
    CASE (PH_MAT_GEO_SUB_DP_LINEAR, PH_MAT_GEO_SUB_DP_CAP)
      IF (l3_nprops >= 3) desc%phi_friction = l3_props(3)
      IF (l3_nprops >= 4) desc%c_cohesion   = l3_props(4)
      IF (l3_nprops >= 5) desc%psi_dilation = l3_props(5)

    CASE (PH_MAT_GEO_SUB_MC)
      IF (l3_nprops >= 3) desc%phi_friction = l3_props(3)
      IF (l3_nprops >= 4) desc%c_cohesion   = l3_props(4)
      IF (l3_nprops >= 5) desc%psi_dilation = l3_props(5)

    CASE (PH_MAT_GEO_SUB_CAM_CLAY)
      IF (l3_nprops >= 3) desc%K0 = l3_props(3)

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Geo_Core]: Unknown sub_type in Populate"
      RETURN
    END SELECT

    desc%pop%is_valid = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Geo_Populate_From_L3

END MODULE PH_Mat_Geo_Core
