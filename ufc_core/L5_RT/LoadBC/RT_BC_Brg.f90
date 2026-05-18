!===============================================================================
! MODULE:  RT_BC_Brg
! LAYER:   L5_RT
! DOMAIN:  BC
! ROLE:    Brg
! BRIEF:   Cross-layer bridge for the split BC implementation family.
!===============================================================================
MODULE RT_BC_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_BC_Impl_Def, ONLY: RT_BC_Impl_Desc, RT_BC_Impl_State, RT_BC_Impl_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_BC_Brg_FromL3
  PUBLIC :: RT_BC_Brg_ToL4
  PUBLIC :: RT_BC_Brg_WriteBack

CONTAINS

  SUBROUTINE RT_BC_Brg_FromL3(n_bcs, l4_slot_index, desc, status)
    INTEGER(i4),          INTENT(IN)    :: n_bcs, l4_slot_index
    TYPE(RT_BC_Impl_Desc), INTENT(INOUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    desc%n_bcs = n_bcs
    desc%l4_slot_index = l4_slot_index
    desc%is_active = (n_bcs > 0_i4)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_BC_Brg_FromL3

  SUBROUTINE RT_BC_Brg_ToL4(ctx, state, amp_factor, status)
    TYPE(RT_BC_Impl_Ctx),   INTENT(IN)  :: ctx
    TYPE(RT_BC_Impl_State), INTENT(IN)  :: state
    REAL(wp),               INTENT(OUT) :: amp_factor
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)
    amp_factor = state%current_amp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_BC_Brg_ToL4

  SUBROUTINE RT_BC_Brg_WriteBack(state, total_ext_work, max_reaction, status)
    TYPE(RT_BC_Impl_State), INTENT(IN)  :: state
    REAL(wp),               INTENT(OUT) :: total_ext_work, max_reaction
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)
    total_ext_work = state%accumulated_work
    max_reaction = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_BC_Brg_WriteBack

END MODULE RT_BC_Brg
