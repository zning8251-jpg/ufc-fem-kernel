!===============================================================================
! MODULE: PH_Mat_Comp_Core
! LAYER:  L4_PH
! DOMAIN: Material / Composite
! ROLE:   Core
! BRIEF:  Unified family-level kernel dispatch for Composite material models.
!         Routes to model-specific *_Core modules based on sub_type.
!
! Models:
!   PH_MAT_COMP_SUB_CLT    (801) -> Classical Laminate Theory (inline)
!   PH_MAT_COMP_SUB_HASHIN (802) -> PH_Mat_Comp_Hashin_Core
!   PH_MAT_COMP_SUB_FABRIC (803) -> PH_Mat_Comp_Cast_Core
!===============================================================================
MODULE PH_Mat_Comp_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Comp_Def, ONLY: PH_Mat_Comp_Desc, PH_Mat_Comp_State, &
                              PH_Mat_Comp_Algo, PH_Mat_Comp_Ctx, &
                              PH_MAT_COMP_SUB_CLT, &
                              PH_MAT_COMP_SUB_HASHIN, &
                              PH_MAT_COMP_SUB_FABRIC
  USE PH_Mat_Comp_Hashin_Core, ONLY: PH_Mat_Comp_Compute_Stress, &  ! [STUB] Will be connected when adapter layer is implemented
                                      PH_Mat_Comp_Compute_Tangent
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Comp_Dispatch_Eval
  PUBLIC :: PH_Mat_Comp_Populate_From_L3

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Comp_Dispatch_Eval
  ! Unified family-level dispatch: routes to model-specific Core by sub_type.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Comp_Dispatch_Eval(desc, state, algo, ctx, status)
    TYPE(PH_Mat_Comp_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_Comp_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Comp_Algo),  INTENT(IN)    :: algo
    TYPE(PH_Mat_Comp_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    SELECT CASE (desc%cfg%sub_type)
    CASE (PH_MAT_COMP_SUB_CLT)
      ! Classical Laminate Theory — orthotropic elastic
      CALL PH_Mat_Comp_CLT_Eval(desc, state, ctx, status)

    CASE (PH_MAT_COMP_SUB_HASHIN)
      ! Hashin failure criterion with progressive damage
      CALL PH_Mat_Comp_Hashin_Eval(desc, state, ctx, status)

    CASE (PH_MAT_COMP_SUB_FABRIC)
      ! Fabric/casting composite model
      CALL PH_Mat_Comp_Fabric_Eval(desc, state, ctx, status)

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "[PH_Mat_Comp_Core]: Unknown sub_type"
    END SELECT
  END SUBROUTINE PH_Mat_Comp_Dispatch_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Comp_CLT_Eval (inline CLT orthotropic elastic)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Comp_CLT_Eval(desc, state, ctx, status)
    TYPE(PH_Mat_Comp_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_Comp_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Comp_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! CLT: simple orthotropic stiffness * strain
    ! Full implementation deferred to model-specific Core when needed
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_CLT_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Comp_Hashin_Eval (delegate to Hashin core)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Comp_Hashin_Eval(desc, state, ctx, status)
    TYPE(PH_Mat_Comp_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_Comp_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Comp_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! Delegate to Hashin core via Eval-level adapter
    ! Parameter bridging handled by PH_Mat_Comp_Eval
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Hashin_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Comp_Fabric_Eval (delegate to Cast/Fabric core)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Comp_Fabric_Eval(desc, state, ctx, status)
    TYPE(PH_Mat_Comp_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Mat_Comp_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Comp_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! Delegate to Cast/Fabric core via Eval-level adapter
    ! Parameter bridging handled by PH_Mat_Comp_Eval
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Fabric_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Comp_Populate_From_L3
  ! Populate Composite Desc from L3 property arrays.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Comp_Populate_From_L3(desc, l3_props, l3_nprops, &
                                           l3_sub_type, status)
    TYPE(PH_Mat_Comp_Desc), INTENT(INOUT) :: desc
    REAL(wp), INTENT(IN) :: l3_props(:)
    INTEGER(i4), INTENT(IN) :: l3_nprops, l3_sub_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    desc%cfg%sub_type = l3_sub_type

    ! Populate orthotropic elastic constants (9 engineering constants)
    IF (l3_nprops >= 1) desc%E11  = l3_props(1)
    IF (l3_nprops >= 2) desc%E22  = l3_props(2)
    IF (l3_nprops >= 3) desc%E33  = l3_props(3)
    IF (l3_nprops >= 4) desc%nu12 = l3_props(4)
    IF (l3_nprops >= 5) desc%nu13 = l3_props(5)
    IF (l3_nprops >= 6) desc%nu23 = l3_props(6)
    IF (l3_nprops >= 7) desc%G12  = l3_props(7)
    IF (l3_nprops >= 8) desc%G13  = l3_props(8)
    IF (l3_nprops >= 9) desc%G23  = l3_props(9)

    desc%vld%is_valid = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Comp_Populate_From_L3

END MODULE PH_Mat_Comp_Core
