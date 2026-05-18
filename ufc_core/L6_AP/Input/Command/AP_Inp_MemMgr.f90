!===============================================================================
! MODULE: AP_Inp_MemMgr
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Mgr — command domain memory manager
! BRIEF:  Command domain memory manager (delegates to L5/L6).
!
! Process phases:
!   P0: AP_Cmd_MemMgr_Init / AP_Cmd_MemMgr_Shutdown
!   P2: AP_Cmd_MemMgr_Alloc / AP_Cmd_MemMgr_Free
!===============================================================================
MODULE AP_Inp_MemMgr
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Mem_Mgr, ONLY: &
    MEM_LAYER_L5, &
  USE IF_Prec_Core, ONLY: i4, i8
    layer_pool_alloc, layer_pool_free, layer_pool_init, layer_pool_shutdown, &
    layer_pool_stats
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: AP_Cmd_MemMgr_Init, AP_Cmd_MemMgr_Shutdown, AP_Cmd_MemMgr_Alloc, &
            AP_Cmd_MemMgr_Free, AP_Cmd_MemMgr_Stats
  ! Backward compatibility
  PUBLIC :: cmd_pool_init, cmd_pool_shutdown, cmd_pool_alloc, cmd_pool_free, cmd_pool_stats

  INTEGER(i4), PARAMETER :: DEFAULT_LAYER = MEM_LAYER_L5
  LOGICAL, SAVE :: cmdPoolInited = .FALSE.

CONTAINS

  SUBROUTINE AP_Cmd_MemMgr_Init(capacity_bytes, status)
    INTEGER(i8), INTENT(IN), OPTIONAL :: capacity_bytes
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i8) :: cap
    CALL init_error_status(status)
    cap = 10_i8 * 1024_i8 * 1024_i8
    IF (PRESENT(capacity_bytes)) cap = capacity_bytes
    CALL layer_pool_init(MEM_LAYER_L5, cap, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    cmdPoolInited = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Cmd_MemMgr_Init

  SUBROUTINE AP_Cmd_MemMgr_Shutdown(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. cmdPoolInited) RETURN
    CALL layer_pool_shutdown(MEM_LAYER_L5, status)
    cmdPoolInited = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Cmd_MemMgr_Shutdown

  SUBROUTINE AP_Cmd_MemMgr_Alloc(size_bytes, name, block_id, status)
    INTEGER(i8), INTENT(IN) :: size_bytes
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL layer_pool_alloc(DEFAULT_LAYER, size_bytes, name, block_id, status)
  END SUBROUTINE AP_Cmd_MemMgr_Alloc

  SUBROUTINE AP_Cmd_MemMgr_Free(block_id, status)
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL layer_pool_free(DEFAULT_LAYER, block_id, status)
  END SUBROUTINE AP_Cmd_MemMgr_Free

  SUBROUTINE AP_Cmd_MemMgr_Stats(used_bytes, n_blocks, status)
    INTEGER(i8), INTENT(OUT) :: used_bytes
    INTEGER(i4), INTENT(OUT) :: n_blocks
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL layer_pool_stats(DEFAULT_LAYER, used_bytes, n_blocks, status)
  END SUBROUTINE AP_Cmd_MemMgr_Stats

  ! Backward compatibility wrappers
  SUBROUTINE cmd_pool_init(capacity_bytes, status)
    INTEGER(i8), INTENT(IN), OPTIONAL :: capacity_bytes
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL AP_Cmd_MemMgr_Init(capacity_bytes, status)
  END SUBROUTINE cmd_pool_init

  SUBROUTINE cmd_pool_shutdown(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL AP_Cmd_MemMgr_Shutdown(status)
  END SUBROUTINE cmd_pool_shutdown

  SUBROUTINE cmd_pool_alloc(size_bytes, name, block_id, status)
    INTEGER(i8), INTENT(IN) :: size_bytes
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL AP_Cmd_MemMgr_Alloc(size_bytes, name, block_id, status)
  END SUBROUTINE cmd_pool_alloc

  SUBROUTINE cmd_pool_free(block_id, status)
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL AP_Cmd_MemMgr_Free(block_id, status)
  END SUBROUTINE cmd_pool_free

  SUBROUTINE cmd_pool_stats(used_bytes, n_blocks, status)
    INTEGER(i8), INTENT(OUT) :: used_bytes
    INTEGER(i4), INTENT(OUT) :: n_blocks
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL AP_Cmd_MemMgr_Stats(used_bytes, n_blocks, status)
  END SUBROUTINE cmd_pool_stats

END MODULE AP_Inp_MemMgr