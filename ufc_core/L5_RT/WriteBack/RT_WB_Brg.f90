!===============================================================================
! MODULE: RT_WB_Brg
! LAYER:  L5_RT
! DOMAIN: WriteBack
! ROLE:   Brg — cross-layer bridge (FromL5 / ToL4 / ToL3)
! BRIEF:  L5→L4 physics dispatch, L5→L3 model update for write-back.
!===============================================================================
MODULE RT_WB_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_WB_Def,  ONLY: RT_WB_Desc, RT_WB_ProgressState, &
                          RT_WB_Ctx, RT_WB_TARGET_NODE_DISP, &
                          RT_WB_TARGET_ELEM_STRESS
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_WriteBack_Brg_FromL5
  PUBLIC :: RT_WriteBack_Brg_ToL4
  PUBLIC :: RT_WriteBack_Brg_ToL3

CONTAINS

  !---------------------------------------------------------------------------
  ! RT_WriteBack_Brg_FromL5: Prepare write-back data from L5 solver state
  !   Validates solver results and prepares them for write-back dispatch.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_Brg_FromL5(n_nodes, n_elements, desc, progress, status)
    INTEGER(i4),              INTENT(IN)    :: n_nodes
    INTEGER(i4),              INTENT(IN)    :: n_elements
    TYPE(RT_WB_Desc),    INTENT(IN)    :: desc
    TYPE(RT_WB_ProgressState),INTENT(INOUT) :: progress
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. desc%is_active) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (n_nodes <= 0 .AND. desc%write_displacement) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (n_elements <= 0 .AND. desc%write_stress) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Brg_FromL5

  !---------------------------------------------------------------------------
  ! RT_WriteBack_Brg_ToL4: Dispatch write-back through L4 physics layer
  !   Routes data through PH_WB for coordinate/tensor transforms.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_Brg_ToL4(target_type, n_items, ctx, status)
    INTEGER(i4),           INTENT(IN)    :: target_type
    INTEGER(i4),           INTENT(IN)    :: n_items
    TYPE(RT_WB_Ctx),       INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (n_items <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ctx%operation_type = target_type
    ctx%n_items_to_write = n_items

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Brg_ToL4

  !---------------------------------------------------------------------------
  ! RT_WriteBack_Brg_ToL3: Push write-back results to L3 model data
  !   Final step: updates L3 model via MD_WB_Brg whitelist gateway.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_WriteBack_Brg_ToL3(step_id, incr_id, progress, status)
    INTEGER(i4),              INTENT(IN)    :: step_id
    INTEGER(i4),              INTENT(IN)    :: incr_id
    TYPE(RT_WB_ProgressState),INTENT(INOUT) :: progress
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)

    CALL progress%UpdateProgress(step_id, incr_id)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_WriteBack_Brg_ToL3

END MODULE RT_WB_Brg
