!===============================================================================
! MODULE: PH_Mat_Elas_Eval
! LAYER:  L4_PH
! DOMAIN: Material / Elas
! ROLE:   Eval
! BRIEF:  Evaluation entry point for elastic material family.
!         SIO: 5-parameter canonical form (desc, state, algo, ctx, args).
!         3D procedure naming: spatial=IP, temporal=Incr, action=Eval/Update.
!
!         Hot path procedures:
!           PH_Mat_Elas_IP_Incr_Eval     -- IP-level increment evaluation
!           PH_Mat_Elas_IP_Incr_Update   -- IP-level increment state update
!           PH_Mat_Elas_Eval_With_Args   -- SIO adapter (args bundle)
!===============================================================================
MODULE PH_Mat_Elas_Eval
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Elas_Def, ONLY: PH_Mat_Elas_Desc, PH_Mat_Elas_State, &
                              PH_Mat_Elas_Algo, PH_Mat_Elas_Ctx, &
                              PH_Mat_Elas_Eval_Arg
  USE PH_Mat_Elas_Core, ONLY: PH_Mat_Elas_Build_Stiffness, &
                               PH_Mat_Elas_Compute_Stress, &
                               PH_Mat_Elas_Compute_Tangent, &
                               PH_Mat_Elas_Update_State
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Elas_IP_Incr_Eval
  PUBLIC :: PH_Mat_Elas_IP_Incr_Update
  PUBLIC :: PH_Mat_Elas_Eval_With_Args

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Elas_IP_Incr_Eval
  ! Spatial: IP (integration point)
  ! Temporal: Incr (increment)
  ! Action: Eval (evaluate stress and tangent)
  ! 5-parameter canonical form: (desc, state, algo, ctx, args, status)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_IP_Incr_Eval(desc, state, algo, ctx, args, status)
    TYPE(PH_Mat_Elas_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Mat_Elas_State),  INTENT(INOUT) :: state
    TYPE(PH_Mat_Elas_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Mat_Elas_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Mat_Elas_Eval_Arg), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    REAL(wp) :: total_strain(6)
    REAL(wp) :: stress_out(6), ddsdde_out(6,6)

    CALL init_error_status(status)

    ! Copy args into context for hot-path access
    ctx%inc%temperature = args%temperature
    ctx%inc%field_var   = args%field_var
    ctx%inc%strain_inc  = args%dstrain

    ! Total strain = previous strain + increment
    total_strain = state%strain + args%dstrain

    ! Build stiffness matrix if not cached
    IF (.NOT. ctx%D_el_cached) THEN
      CALL PH_Mat_Elas_Build_Stiffness(desc, ctx, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    ! Compute stress
    CALL PH_Mat_Elas_Compute_Stress(ctx, total_strain, stress_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Compute tangent
    CALL PH_Mat_Elas_Compute_Tangent(ctx, ddsdde_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Update state
    CALL PH_Mat_Elas_Update_State(state, stress_out, total_strain, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Write results back to args (SIO [OUT])
    args%stress  = stress_out
    args%ddsdde  = ddsdde_out
    args%status_code = 0
  END SUBROUTINE PH_Mat_Elas_IP_Incr_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Elas_IP_Incr_Update
  ! Spatial: IP (integration point)
  ! Temporal: Incr (increment)
  ! Action: Update (state update only, no tangent)
  ! 5-parameter canonical form: (desc, state, algo, ctx, args, status)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_IP_Incr_Update(desc, state, algo, ctx, args, status)
    TYPE(PH_Mat_Elas_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Mat_Elas_State),  INTENT(INOUT) :: state
    TYPE(PH_Mat_Elas_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Mat_Elas_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Mat_Elas_Eval_Arg), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    REAL(wp) :: total_strain(6)
    REAL(wp) :: stress_out(6)

    CALL init_error_status(status)

    total_strain = state%strain + args%dstrain

    ! Quick stress computation (reuse cached stiffness if available)
    IF (.NOT. ctx%D_el_cached) THEN
      CALL PH_Mat_Elas_Build_Stiffness(desc, ctx, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    CALL PH_Mat_Elas_Compute_Stress(ctx, total_strain, stress_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Update state only
    CALL PH_Mat_Elas_Update_State(state, stress_out, total_strain, status)

    args%stress  = stress_out
    args%ddsdde  = ctx%D_el
    args%status_code = 0
  END SUBROUTINE PH_Mat_Elas_IP_Incr_Update

  !-----------------------------------------------------------------------------
  ! PH_Mat_Elas_Eval_With_Args
  ! SIO adapter: wraps IP_Incr_Eval with full Args interface.
  ! 5-parameter canonical form: (desc, state, algo, ctx, args)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Elas_Eval_With_Args(desc, state, algo, ctx, args)
    TYPE(PH_Mat_Elas_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Mat_Elas_State),  INTENT(INOUT) :: state
    TYPE(PH_Mat_Elas_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Mat_Elas_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Mat_Elas_Eval_Arg), INTENT(INOUT) :: args

    TYPE(ErrorStatusType) :: status

    CALL PH_Mat_Elas_IP_Incr_Eval(desc, state, algo, ctx, args, status)
    args%status_code = status%status_code
    IF (status%status_code /= 0) THEN
      args%message = TRIM(status%message)
    END IF
  END SUBROUTINE PH_Mat_Elas_Eval_With_Args

END MODULE PH_Mat_Elas_Eval