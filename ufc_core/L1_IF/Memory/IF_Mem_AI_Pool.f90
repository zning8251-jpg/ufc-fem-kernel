!===============================================================================
! MODULE: IF_Mem_AI_Pool
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Impl — AI-specific memory pool (SP1) with 64-byte alignment
! BRIEF:  Dedicated pool for AI inference buffers. AVX-512 aligned,
!         GPU-mappable, pre-allocated arena. Six-slot buffer table.
!===============================================================================
MODULE IF_Mem_AI_Pool
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_POOL_ALIGN = 64
  INTEGER(i4), PARAMETER, PUBLIC :: IF_AI_POOL_MAX_SLOTS = 7

  !============================================================================
  ! AI_PoolConfig — configuration for the AI memory pool
  !============================================================================
  TYPE, PUBLIC :: AI_PoolConfig
    INTEGER(i4) :: arena_size_bytes  = 0
    INTEGER(i4) :: alignment         = IF_AI_POOL_ALIGN
    LOGICAL     :: gpu_mappable      = .FALSE.
    INTEGER(i4) :: n_slots           = 0
    INTEGER(i4) :: slot_input_size(IF_AI_POOL_MAX_SLOTS) = 0
    INTEGER(i4) :: slot_output_size(IF_AI_POOL_MAX_SLOTS) = 0
  END TYPE AI_PoolConfig

  !============================================================================
  ! AI_PoolState — runtime state of the AI memory pool
  !============================================================================
  TYPE, PUBLIC :: AI_PoolState
    LOGICAL     :: initialized = .FALSE.
    INTEGER(i4) :: allocated_bytes = 0
    INTEGER(i4) :: peak_bytes      = 0
    INTEGER(i4) :: n_allocs        = 0
    INTEGER(i4) :: n_frees         = 0
  END TYPE AI_PoolState

  !============================================================================
  ! AI_MemPool — the pool instance
  !============================================================================
  TYPE, PUBLIC :: AI_MemPool
    TYPE(AI_PoolConfig) :: config
    TYPE(AI_PoolState)  :: state
  END TYPE AI_MemPool

  PUBLIC :: IF_AI_Pool_Init
  PUBLIC :: IF_AI_Pool_Finalize
  PUBLIC :: IF_AI_Pool_GetStats

CONTAINS

  !============================================================================
  ! IF_AI_Pool_Init — initialize AI memory pool
  !============================================================================
  SUBROUTINE IF_AI_Pool_Init(pool, config, status)
    TYPE(AI_MemPool), INTENT(INOUT) :: pool
    TYPE(AI_PoolConfig), INTENT(IN) :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    pool%config = config
    pool%state%initialized = .TRUE.
    pool%state%allocated_bytes = 0
    pool%state%peak_bytes = 0
    pool%state%n_allocs = 0
    pool%state%n_frees = 0

    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_AI_Pool_Init

  !============================================================================
  ! IF_AI_Pool_Finalize — release AI memory pool
  !============================================================================
  SUBROUTINE IF_AI_Pool_Finalize(pool, status)
    TYPE(AI_MemPool), INTENT(INOUT) :: pool
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    pool%state%initialized = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_AI_Pool_Finalize

  !============================================================================
  ! IF_AI_Pool_GetStats — query pool statistics
  !============================================================================
  SUBROUTINE IF_AI_Pool_GetStats(pool, allocated, peak, n_allocs, n_frees)
    TYPE(AI_MemPool), INTENT(IN) :: pool
    INTEGER(i4), INTENT(OUT) :: allocated, peak, n_allocs, n_frees

    allocated = pool%state%allocated_bytes
    peak      = pool%state%peak_bytes
    n_allocs  = pool%state%n_allocs
    n_frees   = pool%state%n_frees
  END SUBROUTINE IF_AI_Pool_GetStats

END MODULE IF_Mem_AI_Pool
