!===============================================================================
! MODULE: PH_Cont_Core
! LAYER:  L4_PH
! DOMAIN: Contact
! ROLE:   Core
! BRIEF:  Contact gap/penetration detection, forces, stiffness (four-type signatures)
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Cont_Core
  !> LEGACY alias: PH_Contact_Core (renamed to match filename)
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Cont_Def, ONLY: PH_Cont_Desc, PH_Cont_State, &
                            PH_Cont_Algo, PH_Cont_Ctx,    &
                            PH_CONT_OPEN, PH_CONT_CLOSED,        &
                            PH_CONT_STICK, PH_CONT_SLIP
  IMPLICIT NONE
  PRIVATE

  ! ===========================================================================
  ! Naming convention
  !   Types:        PH_Cont_* (canonical, matches module/file name)
  !   Procedures:   PH_Contact_* (legacy, retained for stability)
  !   Aliases:      PH_Cont_Core_* → PH_Contact_Core_* (canonical bridge, see bottom)
  ! ===========================================================================

  ! -- Legacy PH_Contact_* procedures (primary implementations)
  PUBLIC :: PH_Contact_Core_Init
  PUBLIC :: PH_Contact_Core_Finalize
  PUBLIC :: PH_Contact_Compute_Gap
  PUBLIC :: PH_Contact_Compute_Normal_Force
  PUBLIC :: PH_Contact_Compute_Friction_Force
  PUBLIC :: PH_Contact_Compute_Stiffness
  PUBLIC :: PH_Contact_Penalty_Param
  PUBLIC :: PH_Contact_Check_Status

  ! -- Canonical PH_Cont_Core_* alias wrappers
  PUBLIC :: PH_Cont_Core_Init
  PUBLIC :: PH_Cont_Core_Finalize

CONTAINS

  !---------------------------------------------------------------------------
  SUBROUTINE PH_Contact_Core_Init(desc, state, algo, ctx, status)
    TYPE(PH_Cont_Desc),  INTENT(IN)  :: desc
    TYPE(PH_Cont_State), INTENT(OUT) :: state
    TYPE(PH_Cont_Algo),  INTENT(IN)  :: algo
    TYPE(PH_Cont_Ctx),   INTENT(OUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)

    state%itr_quick%gap            = 0.0_wp
    state%itr_quick%f_normal       = 0.0_wp
    state%itr_quick%f_friction     = 0.0_wp
    state%itr_quick%contact_status = PH_CONT_OPEN
    state%itr_quick%slip           = 0.0_wp

    ctx%lcl_pos%x_slave   = 0.0_wp
    ctx%lcl_pos%x_master  = 0.0_wp
    ctx%lcl_normal%normal    = 0.0_wp
    ctx%lcl_stiff%K_contact = 0.0_wp

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Contact_Core_Init

  !---------------------------------------------------------------------------
  SUBROUTINE PH_Contact_Core_Finalize(state, ctx, status)
    TYPE(PH_Cont_State), INTENT(INOUT) :: state
    TYPE(PH_Cont_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    state%itr_quick%gap            = 0.0_wp
    state%itr_quick%f_normal       = 0.0_wp
    state%itr_quick%f_friction     = 0.0_wp
    state%itr_quick%contact_status = PH_CONT_OPEN
    state%itr_quick%slip           = 0.0_wp

    ctx%lcl_pos%x_slave   = 0.0_wp
    ctx%lcl_pos%x_master  = 0.0_wp
    ctx%lcl_normal%normal    = 0.0_wp
    ctx%lcl_stiff%K_contact = 0.0_wp

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Contact_Core_Finalize

  !---------------------------------------------------------------------------
  ! gap = dot(x_slave - x_master, normal)
  ! gap > 0 : open,  gap < 0 : penetration
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Contact_Compute_Gap(desc, state, ctx, status)
    TYPE(PH_Cont_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Cont_State), INTENT(INOUT) :: state
    TYPE(PH_Cont_Ctx),   INTENT(IN)    :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    REAL(wp) :: dx(3)

    CALL init_error_status(status)
    dx = ctx%lcl_pos%x_slave - ctx%lcl_pos%x_master
    state%itr_quick%gap = DOT_PRODUCT(dx, ctx%lcl_normal%normal)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Contact_Compute_Gap

  !---------------------------------------------------------------------------
  ! Penalty normal force: f_n = -penalty * gap  (if penetrating)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Contact_Compute_Normal_Force(desc, state, status)
    TYPE(PH_Cont_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Cont_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (state%itr_quick%gap < 0.0_wp) THEN
      state%itr_quick%f_normal = -desc%cfg_penalty%penalty_normal * state%itr_quick%gap
    ELSE
      state%itr_quick%f_normal = 0.0_wp
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Contact_Compute_Normal_Force

  !---------------------------------------------------------------------------
  ! Coulomb friction: f_trial = penalty_t * |slip|,  f_limit = mu * f_n
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Contact_Compute_Friction_Force(desc, state, status)
    TYPE(PH_Cont_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Cont_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    REAL(wp) :: f_trial, f_limit

    CALL init_error_status(status)

    IF (state%itr_quick%f_normal <= 0.0_wp) THEN
      state%itr_quick%f_friction     = 0.0_wp
      state%itr_quick%contact_status = PH_CONT_OPEN
      status%status_code   = IF_STATUS_OK
      RETURN
    END IF

    f_trial = desc%cfg_penalty%penalty_tangent * ABS(state%itr_quick%slip)
    f_limit = desc%cfg_tol%mu_friction * state%itr_quick%f_normal

    IF (f_trial <= f_limit) THEN
      state%itr_quick%f_friction     = f_trial * SIGN(1.0_wp, state%itr_quick%slip)
      state%itr_quick%contact_status = PH_CONT_STICK
    ELSE
      state%itr_quick%f_friction     = f_limit * SIGN(1.0_wp, state%itr_quick%slip)
      state%itr_quick%contact_status = PH_CONT_SLIP
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Contact_Compute_Friction_Force

  !---------------------------------------------------------------------------
  ! Contact stiffness:  K_ij = penalty * n_i * n_j  (i,j=1..3, if gap<0)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Contact_Compute_Stiffness(desc, state, ctx, status)
    TYPE(PH_Cont_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Cont_State), INTENT(IN)    :: state
    TYPE(PH_Cont_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i, j
    REAL(wp)    :: normal(3)
    REAL(wp)    :: pn

    CALL init_error_status(status)
    ctx%lcl_stiff%K_contact = 0.0_wp

    IF (state%itr_quick%gap < 0.0_wp) THEN
      normal = ctx%lcl_normal%normal
      pn = desc%cfg_penalty%penalty_normal
      DO j = 1, 3
        DO i = 1, 3
          ctx%lcl_stiff%K_contact(i, j) = pn * normal(i) * normal(j)
        END DO
      END DO
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Contact_Compute_Stiffness

  !---------------------------------------------------------------------------
  ! Penalty parameter from material stiffness (pure helper, no type needed)
  !---------------------------------------------------------------------------
  FUNCTION PH_Contact_Penalty_Param(E, h_elem, scale) RESULT(penalty)
    REAL(wp), INTENT(IN) :: E, h_elem, scale
    REAL(wp) :: penalty
    penalty = scale * E / h_elem
  END FUNCTION PH_Contact_Penalty_Param

  !---------------------------------------------------------------------------
  ! Check contact status: gap vs tolerance
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Contact_Check_Status(desc, state, status)
    TYPE(PH_Cont_Desc),  INTENT(IN)    :: desc
    TYPE(PH_Cont_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (state%itr_quick%gap > desc%cfg_tol%gap_tolerance) THEN
      state%itr_quick%contact_status = PH_CONT_OPEN
    ELSE
      state%itr_quick%contact_status = PH_CONT_CLOSED
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Contact_Check_Status

  !---------------------------------------------------------------------------
  ! Canonical alias wrapper: PH_Cont_Core_Init
  ! Delegates to PH_Contact_Core_Init (the canonical implementation).
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_Core_Init(desc, status)
    TYPE(PH_Cont_Desc),  INTENT(IN)  :: desc
    TYPE(ErrorStatusType),  INTENT(OUT) :: status
    TYPE(PH_Cont_State) :: state
    TYPE(PH_Cont_Algo)  :: algo
    TYPE(PH_Cont_Ctx)   :: ctx
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
  END SUBROUTINE PH_Cont_Core_Init

  !---------------------------------------------------------------------------
  ! Canonical alias wrapper: PH_Cont_Core_Finalize
  ! Delegates to PH_Contact_Core_Finalize (the canonical implementation).
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_Core_Finalize(status)
    TYPE(ErrorStatusType),  INTENT(OUT) :: status
    TYPE(PH_Cont_State) :: state
    TYPE(PH_Cont_Ctx)   :: ctx
    CALL PH_Contact_Core_Finalize(state, ctx, status)
  END SUBROUTINE PH_Cont_Core_Finalize

END MODULE PH_Cont_Core
