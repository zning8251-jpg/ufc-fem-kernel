!===============================================================================
! MODULE: PH_Mat_Plast_Eval
! LAYER:  L4_PH
! DOMAIN: Material / Plast
! ROLE:   Eval
! BRIEF:  Evaluation entry point for plastic material family.
!         SIO: 5-parameter canonical form (desc, state, algo, ctx, args).
!         3D naming: spatial=IP, temporal=Incr, action=Eval.
!===============================================================================
MODULE PH_Mat_Plast_Eval
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Plast_Def, ONLY: PH_Mat_Plast_Desc, &
                               PH_Mat_Plast_State, &
                               PH_Mat_Plast_Algo, &
                               PH_Mat_Plast_Ctx, &
                               PH_Mat_Plast_Eval_Arg
  USE PH_Mat_Plast_Core, ONLY: PH_Mat_Plast_Return_Mapping, &
                                PH_Mat_Plast_Update_State
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Plast_IP_Incr_Eval
  PUBLIC :: PH_Mat_Plast_Eval_With_Args

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Plast_IP_Incr_Eval
  ! Spatial: IP | Temporal: Incr | Action: Eval
  ! 5-parameter SIO form: (desc, state, algo, ctx, args, status)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Plast_IP_Incr_Eval(desc, state, algo, ctx, args, status)
    TYPE(PH_Mat_Plast_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Mat_Plast_State),  INTENT(INOUT) :: state
    TYPE(PH_Mat_Plast_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Mat_Plast_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Mat_Plast_Eval_Arg), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    REAL(wp) :: total_strain(6), stress_out(6), ddsdde_out(6,6)

    CALL init_error_status(status)

    ! Total strain = previous strain + increment
    total_strain = state%strain + args%dstrain

    ! Return mapping algorithm
    CALL PH_Mat_Plast_Return_Mapping(desc, state, algo, ctx, &
                                      total_strain, stress_out, ddsdde_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Update state
    CALL PH_Mat_Plast_Update_State(state, stress_out, total_strain, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Write results to args (SIO [OUT])
    args%stress  = stress_out
    args%ddsdde  = ddsdde_out
    args%status_code = 0
  END SUBROUTINE PH_Mat_Plast_IP_Incr_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Plast_Eval_With_Args
  ! SIO adapter: wraps IP_Incr_Eval with full Args interface.
  ! 5-parameter form: (desc, state, algo, ctx, args)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Plast_Eval_With_Args(desc, state, algo, ctx, args)
    TYPE(PH_Mat_Plast_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Mat_Plast_State),  INTENT(INOUT) :: state
    TYPE(PH_Mat_Plast_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Mat_Plast_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Mat_Plast_Eval_Arg), INTENT(INOUT) :: args

    TYPE(ErrorStatusType) :: status
    CALL PH_Mat_Plast_IP_Incr_Eval(desc, state, algo, ctx, args, status)
    args%status_code = status%status_code
    IF (status%status_code /= 0) args%message = TRIM(status%message)
  END SUBROUTINE PH_Mat_Plast_Eval_With_Args

END MODULE PH_Mat_Plast_Eval