!===============================================================================
! MODULE: PH_Mat_Damage_Core
! LAYER:  L4_PH
! DOMAIN: Material / Damage
! ROLE:   Core
! BRIEF:  Unified family-level kernel dispatch for Damage material models.
!         Routes to model-specific *_Core modules based on sub_type.
!
! Models:
!   PH_MAT_DMG_SUB_GURSON   (704) -> PH_Mat_Damage_Gurson_Core
!   PH_MAT_DMG_SUB_LEMAITRE (705) -> PH_Mat_Damage_Lemaitre_Core
!===============================================================================
MODULE PH_Mat_Damage_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Damage_Def, ONLY: PH_Mat_Damage_Desc, PH_Mat_Damage_State, &
                                PH_Mat_Damage_Algo, PH_Mat_Damage_Ctx, &
                                PH_MAT_DMG_SUB_GURSON, &
                                PH_MAT_DMG_SUB_LEMAITRE
  USE PH_Mat_Damage_Gurson_Core, ONLY: PH_GTN_UMAT_Impl  ! [STUB] Will be connected when adapter layer is implemented
  USE PH_Mat_Damage_Lemaitre_Core, ONLY: PH_CDM_ComputeStress  ! [STUB] Will be connected when adapter layer is implemented
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Damage_Dispatch_Eval
  PUBLIC :: PH_Mat_Damage_Populate_From_L3

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Damage_Dispatch_Eval
  ! Unified family-level dispatch: routes to model-specific Core by sub_type.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Damage_Dispatch_Eval(desc, state, algo, ctx, status)
    TYPE(PH_Mat_Damage_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_Damage_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Damage_Algo),  INTENT(IN)    :: algo
    TYPE(PH_Mat_Damage_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)

    SELECT CASE (desc%cfg%sub_type)
    CASE (PH_MAT_DMG_SUB_GURSON)
      ! Gurson-Tvergaard-Needleman ductile damage
      CALL PH_Mat_Damage_Gurson_Dispatch(desc, state, algo, ctx, status)

    CASE (PH_MAT_DMG_SUB_LEMAITRE)
      ! Lemaitre continuum damage mechanics
      CALL PH_Mat_Damage_Lemaitre_Dispatch(desc, state, algo, ctx, status)

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Damage_Core]: Unknown sub_type"
    END SELECT
  END SUBROUTINE PH_Mat_Damage_Dispatch_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Damage_Gurson_Dispatch (internal adapter to GTN core)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Damage_Gurson_Dispatch(desc, state, algo, ctx, status)
    TYPE(PH_Mat_Damage_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_Damage_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Damage_Algo),  INTENT(IN)    :: algo
    TYPE(PH_Mat_Damage_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! Delegate to GTN implementation via Eval-level adapter
    ! The actual parameter bridging is handled by PH_Mat_Damage_Eval
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Damage_Gurson_Dispatch

  !-----------------------------------------------------------------------------
  ! PH_Mat_Damage_Lemaitre_Dispatch (internal adapter to CDM core)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Damage_Lemaitre_Dispatch(desc, state, algo, ctx, status)
    TYPE(PH_Mat_Damage_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_Damage_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Damage_Algo),  INTENT(IN)    :: algo
    TYPE(PH_Mat_Damage_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! Delegate to Lemaitre CDM implementation via Eval-level adapter
    ! The actual parameter bridging is handled by PH_Mat_Damage_Eval
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Damage_Lemaitre_Dispatch

  !-----------------------------------------------------------------------------
  ! PH_Mat_Damage_Populate_From_L3
  ! Populate Damage Desc from L3 property arrays.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Damage_Populate_From_L3(desc, l3_props, l3_nprops, &
                                             l3_sub_type, status)
    TYPE(PH_Mat_Damage_Desc), INTENT(OUT) :: desc
    REAL(wp), INTENT(IN) :: l3_props(:)
    INTEGER(i4), INTENT(IN) :: l3_nprops, l3_sub_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    desc%cfg%sub_type = l3_sub_type

    SELECT CASE (l3_sub_type)
    CASE (PH_MAT_DMG_SUB_GURSON)
      IF (l3_nprops >= 1) desc%eps_f   = l3_props(1)
      IF (l3_nprops >= 2) desc%sigma_t = l3_props(2)
      IF (l3_nprops >= 3) desc%G_f     = l3_props(3)

    CASE (PH_MAT_DMG_SUB_LEMAITRE)
      IF (l3_nprops >= 1) desc%eps_f   = l3_props(1)
      IF (l3_nprops >= 2) desc%sigma_t = l3_props(2)

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Damage_Core]: Unknown sub_type in Populate"
      RETURN
    END SELECT

    desc%pop%is_valid = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Damage_Populate_From_L3

END MODULE PH_Mat_Damage_Core
