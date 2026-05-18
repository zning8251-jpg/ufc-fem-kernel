!===============================================================================
! MODULE: MD_WB_Core
! LAYER:  L3_MD
! DOMAIN: WriteBack
! ROLE:   Core — Write-back mapping management
! BRIEF:  Register/query/validate source→target field maps, execute write-back.
!===============================================================================
!
! Procedures:
!   [P0] MD_WriteBack_Core_Init / MD_WriteBack_Core_Finalize
!   [P0] MD_WriteBack_Register_Map  (Register)
!   [P0] MD_WriteBack_Get_Map / MD_WriteBack_Get_Count  (Query)
!   [P0] MD_WriteBack_Validate
!   [P3] MD_WriteBack_Execute       (WriteBack)
!
! Status: FOUR-TYPE | ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE MD_WB_Core
  USE IF_Prec_Core,            ONLY: wp, i4
  USE IF_Err_Brg,         ONLY: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_WB_Def,   ONLY: MD_WriteBack_Desc, MD_WriteBack_State, &
                                MD_WriteBack_Ctx, MD_WBMapEntry, &
                                MD_WB_MAX_MAPS
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_WriteBack_Core_Init
  PUBLIC :: MD_WriteBack_Core_Finalize
  PUBLIC :: MD_WriteBack_Register_Map
  PUBLIC :: MD_WriteBack_Get_Map
  PUBLIC :: MD_WriteBack_Get_Count
  PUBLIC :: MD_WriteBack_Validate
  PUBLIC :: MD_WriteBack_Execute

CONTAINS

  SUBROUTINE MD_WriteBack_Core_Init(desc, state, ctx, status)
    TYPE(MD_WriteBack_Desc),  INTENT(INOUT) :: desc
    TYPE(MD_WriteBack_State), INTENT(OUT)   :: state
    TYPE(MD_WriteBack_Ctx),   INTENT(OUT)   :: ctx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status
    CALL init_error_status(status)
    desc%n_maps        = 0
    state%active       = .FALSE.
    state%n_completed  = 0
    state%n_failed     = 0
    state%current_step = 0
    ctx%step_idx       = 0_i4
    ctx%incr_idx       = 0_i4
    ctx%in_progress    = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Core_Init

  SUBROUTINE MD_WriteBack_Core_Finalize(desc, state, ctx, status)
    TYPE(MD_WriteBack_Desc),  INTENT(INOUT) :: desc
    TYPE(MD_WriteBack_State), INTENT(INOUT) :: state
    TYPE(MD_WriteBack_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status
    CALL init_error_status(status)
    desc%n_maps        = 0
    state%active       = .FALSE.
    state%n_completed  = 0
    state%n_failed     = 0
    state%current_step = 0
    ctx%step_idx       = 0_i4
    ctx%incr_idx       = 0_i4
    ctx%in_progress    = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Core_Finalize

  SUBROUTINE MD_WriteBack_Register_Map(desc, source_id, target_id, &
                                       map_type, status)
    TYPE(MD_WriteBack_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),             INTENT(IN)    :: source_id
    INTEGER(i4),             INTENT(IN)    :: target_id
    INTEGER(i4),             INTENT(IN)    :: map_type
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    IF (desc%n_maps >= MD_WB_MAX_MAPS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_WriteBack_Register_Map]: max maps exceeded"
      RETURN
    END IF

    desc%n_maps = desc%n_maps + 1
    idx = desc%n_maps

    desc%maps(idx)%source_field_id = source_id
    desc%maps(idx)%target_field_id = target_id
    desc%maps(idx)%map_type        = map_type
    desc%maps(idx)%valid           = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Register_Map

  SUBROUTINE MD_WriteBack_Get_Map(desc, idx, map, status)
    TYPE(MD_WriteBack_Desc), INTENT(IN)  :: desc
    INTEGER(i4),             INTENT(IN)  :: idx
    TYPE(MD_WBMapEntry),     INTENT(OUT) :: map
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (idx < 1 .OR. idx > desc%n_maps) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_WriteBack_Get_Map]: index out of range"
      RETURN
    END IF
    map = desc%maps(idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Get_Map

  FUNCTION MD_WriteBack_Get_Count(desc) RESULT(n)
    TYPE(MD_WriteBack_Desc), INTENT(IN) :: desc
    INTEGER(i4) :: n
    n = desc%n_maps
  END FUNCTION MD_WriteBack_Get_Count

  SUBROUTINE MD_WriteBack_Execute(desc, state, ctx, step_idx, incr_idx, status)
    TYPE(MD_WriteBack_Desc),  INTENT(IN)    :: desc
    TYPE(MD_WriteBack_State), INTENT(INOUT) :: state
    TYPE(MD_WriteBack_Ctx),   INTENT(INOUT) :: ctx
    INTEGER(i4),              INTENT(IN)    :: step_idx
    INTEGER(i4),              INTENT(IN)    :: incr_idx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    ctx%step_idx    = step_idx
    ctx%incr_idx    = incr_idx
    ctx%in_progress = .TRUE.
    state%active    = .TRUE.

    DO i = 1, desc%n_maps
      IF (.NOT. desc%maps(i)%valid) CYCLE
      IF (desc%maps(i)%source_field_id < 1 .OR. &
          desc%maps(i)%target_field_id < 1) THEN
        state%n_failed = state%n_failed + 1
        CYCLE
      END IF
      state%n_completed = state%n_completed + 1
    END DO

    ctx%in_progress   = .FALSE.
    state%current_step = step_idx
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Execute

  SUBROUTINE MD_WriteBack_Validate(desc, status)
    TYPE(MD_WriteBack_Desc), INTENT(IN)  :: desc
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    DO i = 1, desc%n_maps
      IF (desc%maps(i)%valid .AND. &
          (desc%maps(i)%source_field_id < 1 .OR. &
           desc%maps(i)%target_field_id < 1)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[MD_WriteBack_Validate]: invalid source/target ID"
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Validate

END MODULE MD_WB_Core
