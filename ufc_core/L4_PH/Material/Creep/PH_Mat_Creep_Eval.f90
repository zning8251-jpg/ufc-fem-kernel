!===============================================================================
! MODULE: PH_Mat_Creep_Eval
! LAYER:  L4_PH
! DOMAIN: Material / Creep
! ROLE:   Eval
! BRIEF:  Evaluation entry point for creep material family.
!         SIO: 5-parameter form (desc, state, algo, ctx, args, status).
!         3D naming: spatial=IP, temporal=Incr, action=Eval.
!===============================================================================
MODULE PH_Mat_Creep_Eval
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Creep_Def, ONLY: PH_Mat_Creep_Desc, PH_Mat_Creep_State, &
                               PH_Mat_Creep_Algo, PH_Mat_Creep_Ctx, &
                               PH_Mat_Creep_Eval_Arg
  USE PH_Mat_Creep_Core, ONLY: PH_Mat_Creep_Compute_Stress, &
                                PH_Mat_Creep_Compute_Tangent, &
                                PH_Mat_Creep_Update_State, &
                                PH_Mat_Creep_Validate_Params, &
                                PH_Mat_Creep_Init, &
                                PH_Creep_Props, PH_Creep_State, &
                                PH_CREEP_NORTON, PH_CREEP_NABARRO
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Creep_IP_Incr_Eval
  PUBLIC :: PH_Mat_Creep_Eval_With_Args

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Creep_IP_Incr_Eval
  ! Spatial: IP | Temporal: Incr | Action: Eval
  ! 5-parameter SIO form: (desc, state, algo, ctx, args, status)
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Creep_IP_Incr_Eval(desc, state, algo, ctx, args, status)
    TYPE(PH_Mat_Creep_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Mat_Creep_State),  INTENT(INOUT) :: state
    TYPE(PH_Mat_Creep_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Mat_Creep_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Mat_Creep_Eval_Arg), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    TYPE(PH_Creep_Props) :: core_props
    TYPE(PH_Creep_State) :: core_state
    REAL(wp) :: stress_out(6), ddsdde_out(6,6)
    REAL(wp) :: pnewdt
    INTEGER(i4) :: j

    CALL init_error_status(status)

    ! Build core props from L4 Desc
    core_props%creep_type = PH_CREEP_NORTON
    core_props%E = 0.0_wp; core_props%nu = 0.0_wp
    IF (ALLOCATED(desc%props) .AND. SIZE(desc%props) >= 2) THEN
      core_props%E = desc%props(1)
      core_props%nu = desc%props(2)
    ELSE
      core_props%E = 1.0e9_wp; core_props%nu = 0.3_wp
    END IF
    core_props%A_cr = desc%A
    core_props%n_cr = desc%n
    core_props%Q_act = desc%Q_act
    core_props%m = desc%m
    core_props%R = 8.314_wp

    ! Build core state
    core_state%stress = 0.0_wp
    core_state%creep_strain = state%creep_strain
    core_state%equiv_creep_strain = state%equiv_creep_strain

    CALL PH_Mat_Creep_Compute_Stress(core_props, core_state, args%dt, &
                                      args%strain, stress_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_Creep_Compute_Tangent(core_props, core_state, &
                                       ddsdde_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL PH_Mat_Creep_Update_State(state, stress_out, args%strain, status)

    args%stress  = stress_out
    args%ddsdde  = ddsdde_out
    args%status_code = 0
  END SUBROUTINE PH_Mat_Creep_IP_Incr_Eval

  !-----------------------------------------------------------------------------
  ! PH_Mat_Creep_Eval_With_Args
  ! SIO adapter.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Creep_Eval_With_Args(desc, state, algo, ctx, args)
    TYPE(PH_Mat_Creep_Desc),   INTENT(IN)    :: desc
    TYPE(PH_Mat_Creep_State),  INTENT(INOUT) :: state
    TYPE(PH_Mat_Creep_Algo),   INTENT(IN)    :: algo
    TYPE(PH_Mat_Creep_Ctx),    INTENT(INOUT) :: ctx
    TYPE(PH_Mat_Creep_Eval_Arg), INTENT(INOUT) :: args

    TYPE(ErrorStatusType) :: status
    CALL PH_Mat_Creep_IP_Incr_Eval(desc, state, algo, ctx, args, status)
    args%status_code = status%status_code
    IF (status%status_code /= 0) args%message = TRIM(status%message)
  END SUBROUTINE PH_Mat_Creep_Eval_With_Args

END MODULE PH_Mat_Creep_Eval