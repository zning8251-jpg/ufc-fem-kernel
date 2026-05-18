!===============================================================================
! MODULE: RT_Mat_Visco_Core
! LAYER:  L5_RT
! DOMAIN: Material / Visco
! ROLE:   Core
! BRIEF:  Unified dispatch for viscoelastic material family.
!         SIO: uses RT_Mat_Visco_Dispatch_Arg bundle.
!===============================================================================
MODULE RT_Mat_Visco_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Mat_Visco_Def, ONLY: RT_Mat_Visco_Desc, RT_Mat_Visco_State, &
                               RT_Mat_Visco_Algo, RT_Mat_Visco_Ctx, &
                               RT_Mat_Visco_Dispatch_Arg
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_Visco_Dispatch_Run
  PUBLIC :: RT_Mat_Visco_Commit_State
  PUBLIC :: RT_Mat_Visco_Rollback_State

CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_Mat_Visco_Dispatch_Run
  ! Spatial: IP | Temporal: Incr | Action: Dispatch
  ! 5-parameter form: (desc, state, algo, ctx, args, status)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Mat_Visco_Dispatch_Run(desc, state, algo, ctx, args, status)
    TYPE(RT_Mat_Visco_Desc),        INTENT(IN)    :: desc
    TYPE(RT_Mat_Visco_State),       INTENT(INOUT) :: state
    TYPE(RT_Mat_Visco_Algo),        INTENT(IN)    :: algo
    TYPE(RT_Mat_Visco_Ctx),         INTENT(INOUT) :: ctx
    TYPE(RT_Mat_Visco_Dispatch_Arg), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),          INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. desc%is_active) THEN
      status%status_code = -1; status%message = "Inactive material"; RETURN
    END IF

    ! Return L4 slot index for caller to invoke PH_Mat_Visco_IP_Incr_Eval
    args%status_code = desc%l4_slot_index

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Visco_Dispatch_Run

  SUBROUTINE RT_Mat_Visco_Commit_State(state, status)
    TYPE(RT_Mat_Visco_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    state%state_committed = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Visco_Commit_State

  SUBROUTINE RT_Mat_Visco_Rollback_State(state, status)
    TYPE(RT_Mat_Visco_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    state%state_committed = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Visco_Rollback_State

END MODULE RT_Mat_Visco_Core
