!===============================================================================
! MODULE: RT_Mat_Hyper_Core
! LAYER:  L5_RT
! DOMAIN: Material / Hyper
! ROLE:   Core
! BRIEF:  Core routing and dispatch for hyperelastic material family.
!         SIO: uses RT_Mat_Hyper_Dispatch_Arg bundle.
!===============================================================================
MODULE RT_Mat_Hyper_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_Mat_Hyper_Def, ONLY: RT_Mat_Hyper_Desc, RT_Mat_Hyper_State, &
                               RT_Mat_Hyper_Algo, RT_Mat_Hyper_Ctx, &
                               RT_Mat_Hyper_Dispatch_Arg
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Mat_Hyper_Dispatch_Run

CONTAINS

  SUBROUTINE RT_Mat_Hyper_Dispatch_Run(desc, state, algo, ctx, args, status)
    TYPE(RT_Mat_Hyper_Desc),        INTENT(IN)    :: desc
    TYPE(RT_Mat_Hyper_State),       INTENT(INOUT) :: state
    TYPE(RT_Mat_Hyper_Algo),        INTENT(IN)    :: algo
    TYPE(RT_Mat_Hyper_Ctx),         INTENT(INOUT) :: ctx
    TYPE(RT_Mat_Hyper_Dispatch_Arg), INTENT(INOUT) :: args
    TYPE(ErrorStatusType),         INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. desc%is_active) THEN
      status%status_code = -1; RETURN
    END IF
    args%status_code = desc%l4_slot_index
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Mat_Hyper_Dispatch_Run

END MODULE RT_Mat_Hyper_Core