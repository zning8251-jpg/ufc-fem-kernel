!===============================================================================
! MODULE: IF_Mem_Mgr
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Mgr — domain-tagged Alloc/Free, pool init, statistics, leak tracking
! BRIEF:  AllocReal1D/2D, AllocInt1D, FreeReal1D/2D, FreeInt1D;
!         IF_MEM_DOMAIN_* constants; legacy UF_Mem_* aliases.
!===============================================================================

MODULE IF_Mem_Mgr
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: i4, i8, wp
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: IF_MEM_DOMAIN_MAT   = 1
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MEM_DOMAIN_ELEM  = 2
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MEM_DOMAIN_SOLV  = 3
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MEM_DOMAIN_MESH  = 4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MEM_DOMAIN_CMD   = 5
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MEM_DOMAIN_LAYER = 0

  PUBLIC :: IF_Mem_AllocReal1D, IF_Mem_FreeReal1D
  PUBLIC :: IF_Mem_AllocReal2D, IF_Mem_FreeReal2D
  PUBLIC :: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D
  PUBLIC :: UF_Mem_AllocReal2D, UF_Mem_FreeReal2D
  
  ! Extended memory management API (task300-349)
  PUBLIC :: IF_Mem_GetStatistics, IF_Mem_CheckLeaks, IF_Mem_GetFragmentation
  PUBLIC :: IF_Mem_InitPool, IF_Mem_ShutdownPool, IF_Mem_AllocFromPool, IF_Mem_FreeToPool
  
  ! Legacy API for MD_BaseDataModMgr compatibility (MemPool = MemoryPool)
  ! MemoryPool is PUBLIC via TYPE, PUBLIC below (Intel: no duplicate PUBLIC attribute)
  PUBLIC :: g_mem_pool
  PUBLIC :: mem_init, mem_alloc, mem_alloc_array, mem_alloc_pointer
  PUBLIC :: mem_free, mem_associate_pointer, mem_is_pointer_associated, mem_disassociate_pointer
  
  !=============================================================================
  ! BASE TYPES (must precede structured types that use them)
  !=============================================================================
  INTEGER(i4), PARAMETER :: IF_MAX_PTR = 100000
  
  ! Memory Pool Structure
  TYPE, PUBLIC :: MemoryPool
    REAL(wp), ALLOCATABLE :: pool_data(:)
    INTEGER(i8) :: pool_size = 0_i8
    INTEGER(i8) :: used_size = 0_i8
    INTEGER(i4) :: num_blocks = 0
    INTEGER(i4) :: max_blocks = 1000
    INTEGER(i4), ALLOCATABLE :: block_sizes(:)
    INTEGER(i4), ALLOCATABLE :: block_offsets(:)
    LOGICAL, ALLOCATABLE :: block_allocated(:)
    LOGICAL :: init = .FALSE.
  END TYPE MemoryPool
  
  ! Memory Statistics Structure
    TYPE, PUBLIC :: MemoryStatistics_Alloc
    INTEGER(i8) :: total_allocated = 0_i8
    INTEGER(i8) :: total_freed = 0_i8
  END TYPE MemoryStatistics_Alloc

  TYPE, PUBLIC :: MemoryStatistics_Usage
    INTEGER(i8) :: peak_usage = 0_i8
    INTEGER(i8) :: current_usage = 0_i8
  END TYPE MemoryStatistics_Usage

  TYPE, PUBLIC :: MemoryStatistics_Count
    INTEGER(i4) :: allocation_count = 0
    INTEGER(i4) :: deallocation_count = 0
  END TYPE MemoryStatistics_Count

  TYPE, PUBLIC :: MemoryStatistics_Quality
    INTEGER(i4) :: leak_count = 0
    INTEGER(i4) :: fragmentation_ratio = 0
  END TYPE MemoryStatistics_Quality

  TYPE, PUBLIC :: MemoryStatistics
    TYPE(MemoryStatistics_Alloc)    :: alloc
    TYPE(MemoryStatistics_Usage)    :: usage
    TYPE(MemoryStatistics_Count)    :: count
    TYPE(MemoryStatistics_Quality)  :: quality
  END TYPE MemoryStatistics
  
  !=============================================================================
  ! STRUCTURED INTERFACE TYPES (public via TYPE, PUBLIC)
  !=============================================================================
  !> @brief Input structure for memory pool initialization
  TYPE, PUBLIC :: IF_Mem_InitPool_In
    INTEGER(i8) :: pool_size                                 ! M_pool ??^+ (bytes)
  END TYPE IF_Mem_InitPool_In
  
  !> @brief Output structure for memory pool initialization
  TYPE, PUBLIC :: IF_Mem_InitPool_Out
    TYPE(ErrorStatusType) :: status                          ! Error status
  END TYPE IF_Mem_InitPool_Out
  
  !> @brief Input structure for memory allocation from pool
  TYPE, PUBLIC :: IF_Mem_AllocFromPool_In
    INTEGER(i8) :: size_bytes                                ! size ??^+ (bytes)
  END TYPE IF_Mem_AllocFromPool_In
  
  !> @brief Output structure for memory allocation from pool
  TYPE, PUBLIC :: IF_Mem_AllocFromPool_Out
    INTEGER(i8) :: offset                                    ! offset ??^+ (bytes)
    INTEGER(i4) :: block_id                                 ! id_block ??^+
    TYPE(ErrorStatusType) :: status                          ! Error status
  END TYPE IF_Mem_AllocFromPool_Out
  
  !> @brief Input structure for memory deallocation to pool
  TYPE, PUBLIC :: IF_Mem_FreeToPool_In
    INTEGER(i4) :: block_id                                 ! id_block ??^+
  END TYPE IF_Mem_FreeToPool_In
  
  !> @brief Output structure for memory deallocation to pool
  TYPE, PUBLIC :: IF_Mem_FreeToPool_Out
    INTEGER(i8) :: freed_size                               ! M_freed ??^+ (bytes)
    TYPE(ErrorStatusType) :: status                         ! Error status
  END TYPE IF_Mem_FreeToPool_Out
  
  !> @brief Input structure for get memory statistics
  TYPE, PUBLIC :: IF_Mem_GetStatistics_In
    ! Empty - no input parameters
  END TYPE IF_Mem_GetStatistics_In
  
  !> @brief Output structure for get memory statistics
  TYPE, PUBLIC :: IF_Mem_GetStatistics_Out
    TYPE(MemoryStatistics) :: stats                         ! Statistics (State)
  END TYPE IF_Mem_GetStatistics_Out

  INTEGER(i4), SAVE :: next_id = 1
  INTEGER(i4), SAVE :: reg_count = 0
  INTEGER(i4), SAVE :: reg_id(IF_MAX_PTR) = -1
  LOGICAL, SAVE :: reg_is1d(IF_MAX_PTR) = .FALSE.
  
  TYPE(MemoryPool), SAVE :: g_mem_pool
  TYPE(MemoryStatistics), SAVE :: g_mem_stats

  ! Legacy pointer blocks for mem_alloc_pointer (int/logical types)
  INTEGER(i4), PARAMETER :: IF_LEGACY_BLOCK_OFFSET = 100000
  INTEGER(i4), PARAMETER :: IF_LEGACY_MAX_BLOCKS = 10000
  TYPE, PRIVATE :: LegacyPtrBlock
    INTEGER(i4) :: data_type = 0
    INTEGER(i4) :: dims(7) = 0
    REAL(wp), POINTER :: r(:) => null()
    INTEGER(i4), POINTER :: i(:) => null()
    LOGICAL, POINTER :: l(:) => null()
    LOGICAL :: ptr_associated = .FALSE.
  END TYPE LegacyPtrBlock
  TYPE(LegacyPtrBlock), ALLOCATABLE, SAVE :: legacy_ptr_blocks(:)
  INTEGER(i4), SAVE :: legacy_ptr_count = 0

CONTAINS

  !=============================================================================
  ! STRUCTURED INTERFACE PROCEDURES
  !=============================================================================
  
  !> @brief Initialize memory pool (structured interface)
  SUBROUTINE IF_Mem_InitPool_Structured(in, out)
    TYPE(IF_Mem_InitPool_In), INTENT(IN) :: in
    TYPE(IF_Mem_InitPool_Out), INTENT(OUT) :: out
    
    CALL IF_Mem_InitPool(in%pool_size, out%status)
  END SUBROUTINE IF_Mem_InitPool_Structured
  
  !> @brief Allocate memory from pool (structured interface)
  SUBROUTINE IF_Mem_AllocFromPool_Structured(in, out)
    TYPE(IF_Mem_AllocFromPool_In), INTENT(IN) :: in
    TYPE(IF_Mem_AllocFromPool_Out), INTENT(OUT) :: out
    
    CALL IF_Mem_AllocFromPool(in%size_bytes, out%offset, out%block_id, out%status)
  END SUBROUTINE IF_Mem_AllocFromPool_Structured
  
  !> @brief Free memory to pool (structured interface)
  SUBROUTINE IF_Mem_FreeToPool_Structured(in, out)
    TYPE(IF_Mem_FreeToPool_In), INTENT(IN) :: in
    TYPE(IF_Mem_FreeToPool_Out), INTENT(OUT) :: out
    
    INTEGER(i8) :: freed_size
    CALL IF_Mem_FreeToPool(in%block_id, out%status)
    out%freed_size = freed_size
  END SUBROUTINE IF_Mem_FreeToPool_Structured
  
  !> @brief Get memory statistics (structured interface)
  SUBROUTINE IF_Mem_GetStatistics_Structured(in, out)
    TYPE(IF_Mem_GetStatistics_In), INTENT(IN) :: in
    TYPE(IF_Mem_GetStatistics_Out), INTENT(OUT) :: out
    
    CALL IF_Mem_GetStatistics(out%stats)
  END SUBROUTINE IF_Mem_GetStatistics_Structured
  
  !=============================================================================
  ! LEGACY INTERFACE PROCEDURES (for backward compatibility)
  ! NOTE: These are legacy interfaces. Use structured interfaces (_In/_Out) instead.
  !=============================================================================
  
  !> @brief Allocate memory from pool (legacy interface)
  SUBROUTINE IF_Mem_AllocFromPool(size_bytes, offset, block_id, status)
    INTEGER(i8), INTENT(IN) :: size_bytes
    INTEGER(i8), INTENT(OUT) :: offset
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, block_size_words
    INTEGER(i8) :: current_offset
    
    CALL init_error_status(status)
    
    IF (.NOT. g_mem_pool%init) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Mem_AllocFromPool: Pool not initialized'
      RETURN
    END IF
    
    IF (g_mem_pool%num_blocks >= g_mem_pool%max_blocks) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Mem_AllocFromPool: Maximum blocks reached'
      RETURN
    END IF
    
    block_size_words = INT(size_bytes / KIND(1.0_wp), KIND=i4)
    current_offset = 0_i8
    
    ! Find free space (simplified first-fit algorithm)
    DO i = 1, g_mem_pool%num_blocks
      IF (.NOT. g_mem_pool%block_allocated(i)) THEN
        IF (g_mem_pool%block_sizes(i) >= block_size_words) THEN
          ! Reuse this block
          offset = INT(g_mem_pool%block_offsets(i), KIND=i8)
          block_id = i
          g_mem_pool%block_allocated(i) = .TRUE.
          g_mem_pool%used_size = g_mem_pool%used_size + size_bytes
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END IF
      current_offset = current_offset + INT(g_mem_pool%block_sizes(i), KIND=i8)
    END DO
    
    ! Allocate new block at end
    IF (current_offset + block_size_words <= SIZE(g_mem_pool%pool_data)) THEN
      g_mem_pool%num_blocks = g_mem_pool%num_blocks + 1
      block_id = g_mem_pool%num_blocks
      g_mem_pool%block_offsets(block_id) = INT(current_offset, KIND=i4)
      g_mem_pool%block_sizes(block_id) = block_size_words
      g_mem_pool%block_allocated(block_id) = .TRUE.
      offset = current_offset
      g_mem_pool%used_size = g_mem_pool%used_size + size_bytes
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Mem_AllocFromPool: Pool out of memory'
    END IF
  END SUBROUTINE IF_Mem_AllocFromPool

  SUBROUTINE IF_Mem_CheckLeaks(leak_count, status)
    INTEGER(i4), INTENT(OUT) :: leak_count
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    leak_count = g_mem_stats%count%allocation_count - g_mem_stats%count%deallocation_count
    g_mem_stats%quality%leak_count = leak_count
    
    IF (leak_count > 0) THEN
      status%message = 'IF_Mem_CheckLeaks: ' // TRIM(INT_TO_STRING(leak_count)) // ' leaks detected'
    END IF
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_CheckLeaks

  SUBROUTINE IF_Mem_FreeToPool(block_id, status)
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i8) :: freed_size
    
    CALL init_error_status(status)
    
    IF (.NOT. g_mem_pool%init) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Mem_FreeToPool: Pool not initialized'
      RETURN
    END IF
    
    IF (block_id < 1 .OR. block_id > g_mem_pool%num_blocks) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Mem_FreeToPool: Invalid block ID'
      RETURN
    END IF
    
    IF (.NOT. g_mem_pool%block_allocated(block_id)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'IF_Mem_FreeToPool: Block already freed'
      RETURN
    END IF
    
    freed_size = INT(g_mem_pool%block_sizes(block_id), KIND=i8) * KIND(1.0_wp)
    g_mem_pool%block_allocated(block_id) = .FALSE.
    g_mem_pool%used_size = g_mem_pool%used_size - freed_size
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_FreeToPool

  SUBROUTINE IF_Mem_GetFragmentation(fragmentation_ratio, status)
    INTEGER(i4), INTENT(OUT) :: fragmentation_ratio
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, free_blocks, total_free_size
    INTEGER(i8) :: largest_free_block
    
    CALL init_error_status(status)
    
    IF (.NOT. g_mem_pool%init) THEN
      fragmentation_ratio = 0
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    free_blocks = 0
    total_free_size = 0
    largest_free_block = 0_i8
    
    DO i = 1, g_mem_pool%num_blocks
      IF (.NOT. g_mem_pool%block_allocated(i)) THEN
        free_blocks = free_blocks + 1
        total_free_size = total_free_size + g_mem_pool%block_sizes(i)
        largest_free_block = MAX(largest_free_block, INT(g_mem_pool%block_sizes(i), KIND=i8))
      END IF
    END DO
    
    ! Fragmentation ratio: percentage of free space that cannot be used for largest allocation
    IF (total_free_size > 0) THEN
      fragmentation_ratio = INT(100_i8 * (1_i8 - largest_free_block * KIND(1.0_wp) / &
                          INT(total_free_size, KIND=i8) * KIND(1.0_wp)), KIND=i4)
    ELSE
      fragmentation_ratio = 0
    END IF
    
    g_mem_stats%quality%fragmentation_ratio = fragmentation_ratio
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_GetFragmentation

  !> @brief Get memory statistics (legacy interface)
  SUBROUTINE IF_Mem_GetStatistics(stats)
    TYPE(MemoryStatistics), INTENT(OUT) :: stats
    stats = g_mem_stats
  END SUBROUTINE IF_Mem_GetStatistics

  !> @brief Initialize memory pool (legacy interface)
  SUBROUTINE IF_Mem_InitPool(pool_size, status)
    INTEGER(i8), INTENT(IN) :: pool_size
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (g_mem_pool%init) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    g_mem_pool%pool_size = pool_size
    g_mem_pool%used_size = 0_i8
    g_mem_pool%num_blocks = 0
    
    ALLOCATE(g_mem_pool%pool_data(INT(pool_size / KIND(1.0_wp), KIND=i4)))
    ALLOCATE(g_mem_pool%block_sizes(g_mem_pool%max_blocks))
    ALLOCATE(g_mem_pool%block_offsets(g_mem_pool%max_blocks))
    ALLOCATE(g_mem_pool%block_allocated(g_mem_pool%max_blocks))
    
    g_mem_pool%block_sizes = 0
    g_mem_pool%block_offsets = 0
    g_mem_pool%block_allocated = .FALSE.
    g_mem_pool%init = .TRUE.
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_InitPool

  SUBROUTINE IF_Mem_ShutdownPool(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (.NOT. g_mem_pool%init) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    IF (ALLOCATED(g_mem_pool%pool_data)) DEALLOCATE(g_mem_pool%pool_data)
    IF (ALLOCATED(g_mem_pool%block_sizes)) DEALLOCATE(g_mem_pool%block_sizes)
    IF (ALLOCATED(g_mem_pool%block_offsets)) DEALLOCATE(g_mem_pool%block_offsets)
    IF (ALLOCATED(g_mem_pool%block_allocated)) DEALLOCATE(g_mem_pool%block_allocated)
    
    g_mem_pool%init = .FALSE.
    g_mem_pool%pool_size = 0_i8
    g_mem_pool%used_size = 0_i8
    g_mem_pool%num_blocks = 0
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_ShutdownPool

  !=============================================================================
  ! LEGACY mem_* API (for MD_BaseDataModMgr)
  !=============================================================================
  SUBROUTINE mem_init(pool, memory_capacity, status)
    TYPE(MemoryPool), INTENT(INOUT) :: pool
    INTEGER(i8), INTENT(IN) :: memory_capacity
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL IF_Mem_InitPool(memory_capacity, status)
  END SUBROUTINE mem_init

  SUBROUTINE mem_alloc(pool, size_bytes, type_id, module_id, name, block_id, status)
    TYPE(MemoryPool), INTENT(INOUT) :: pool
    INTEGER(i8), INTENT(IN) :: size_bytes
    INTEGER(i4), INTENT(IN) :: type_id, module_id
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i8) :: offset
    CALL IF_Mem_AllocFromPool(size_bytes, offset, block_id, status)
  END SUBROUTINE mem_alloc

  SUBROUTINE mem_alloc_array(pool, size_bytes, min_val, max_val, name, block_id, status)
    TYPE(MemoryPool), INTENT(INOUT) :: pool
    INTEGER(i8), INTENT(IN) :: size_bytes
    INTEGER(i4), INTENT(IN) :: min_val, max_val
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i8) :: offset
    CALL IF_Mem_AllocFromPool(size_bytes, offset, block_id, status)
  END SUBROUTINE mem_alloc_array

  SUBROUTINE mem_free(pool, block_id, status)
    TYPE(MemoryPool), INTENT(INOUT) :: pool
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: idx
    IF (block_id >= IF_LEGACY_BLOCK_OFFSET) THEN
      idx = block_id - IF_LEGACY_BLOCK_OFFSET
      IF (idx >= 1 .AND. idx <= legacy_ptr_count .AND. ALLOCATED(legacy_ptr_blocks)) THEN
        IF (ASSOCIATED(legacy_ptr_blocks(idx)%r)) DEALLOCATE(legacy_ptr_blocks(idx)%r)
        IF (ASSOCIATED(legacy_ptr_blocks(idx)%i)) DEALLOCATE(legacy_ptr_blocks(idx)%i)
        IF (ASSOCIATED(legacy_ptr_blocks(idx)%l)) DEALLOCATE(legacy_ptr_blocks(idx)%l)
        legacy_ptr_blocks(idx)%ptr_associated = .FALSE.
      END IF
      status%status_code = IF_STATUS_OK
    ELSE
      CALL IF_Mem_FreeToPool(block_id, status)
    END IF
  END SUBROUTINE mem_free

  SUBROUTINE mem_alloc_pointer(pool, data_type, rank, dims, type_id, module_id, name, block_id, status)
    TYPE(MemoryPool), INTENT(INOUT) :: pool
    INTEGER(i4), INTENT(IN) :: data_type, rank, dims(*), type_id, module_id
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: n, i
    CALL init_error_status(status)
    n = 1
    DO i = 1, MIN(rank, 7)
      n = n * MAX(1, dims(i))
    END DO
    IF (.NOT. ALLOCATED(legacy_ptr_blocks)) THEN
      ALLOCATE(legacy_ptr_blocks(IF_LEGACY_MAX_BLOCKS))
      legacy_ptr_count = 0
    END IF
    legacy_ptr_count = legacy_ptr_count + 1
    IF (legacy_ptr_count > IF_LEGACY_MAX_BLOCKS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'mem_alloc_pointer: legacy block limit exceeded'
      RETURN
    END IF
    block_id = IF_LEGACY_BLOCK_OFFSET + legacy_ptr_count
    legacy_ptr_blocks(legacy_ptr_count)%data_type = data_type
    legacy_ptr_blocks(legacy_ptr_count)%dims(1:7) = 0
    legacy_ptr_blocks(legacy_ptr_count)%dims(1) = n
    IF (data_type == 2) THEN
      ALLOCATE(legacy_ptr_blocks(legacy_ptr_count)%i(n))
      legacy_ptr_blocks(legacy_ptr_count)%i = 0
    ELSE IF (data_type == 3) THEN
      ALLOCATE(legacy_ptr_blocks(legacy_ptr_count)%l(n))
      legacy_ptr_blocks(legacy_ptr_count)%l = .FALSE.
    ELSE
      ALLOCATE(legacy_ptr_blocks(legacy_ptr_count)%r(n))
      legacy_ptr_blocks(legacy_ptr_count)%r = 0.0_wp
    END IF
    legacy_ptr_blocks(legacy_ptr_count)%ptr_associated = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE mem_alloc_pointer

  SUBROUTINE mem_associate_pointer(pool, block_id, ptr_real, ptr_int, ptr_logical, status)
    TYPE(MemoryPool), INTENT(INOUT) :: pool
    INTEGER(i4), INTENT(IN) :: block_id
    REAL(wp), POINTER, INTENT(OUT), OPTIONAL :: ptr_real(:)
    INTEGER(i4), POINTER, INTENT(OUT), OPTIONAL :: ptr_int(:)
    LOGICAL, POINTER, INTENT(OUT), OPTIONAL :: ptr_logical(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: idx, n
    CALL init_error_status(status)
    IF (block_id >= IF_LEGACY_BLOCK_OFFSET) THEN
      idx = block_id - IF_LEGACY_BLOCK_OFFSET
      IF (idx < 1 .OR. idx > legacy_ptr_count .OR. .NOT. ALLOCATED(legacy_ptr_blocks)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'mem_associate_pointer: invalid legacy block_id'
        RETURN
      END IF
      n = legacy_ptr_blocks(idx)%dims(1)
      legacy_ptr_blocks(idx)%ptr_associated = .TRUE.
      IF (PRESENT(ptr_real) .AND. ASSOCIATED(legacy_ptr_blocks(idx)%r)) &
        ptr_real => legacy_ptr_blocks(idx)%r(1:n)
      IF (PRESENT(ptr_int) .AND. ASSOCIATED(legacy_ptr_blocks(idx)%i)) &
        ptr_int => legacy_ptr_blocks(idx)%i(1:n)
      IF (PRESENT(ptr_logical) .AND. ASSOCIATED(legacy_ptr_blocks(idx)%l)) &
        ptr_logical => legacy_ptr_blocks(idx)%l(1:n)
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = 'mem_associate_pointer: pool blocks not supported for pointer association'
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE mem_associate_pointer

  FUNCTION mem_is_pointer_associated(pool, block_id) RESULT(ok)
    TYPE(MemoryPool), INTENT(IN) :: pool
    INTEGER(i4), INTENT(IN) :: block_id
    LOGICAL :: ok
    INTEGER(i4) :: idx
    IF (block_id >= IF_LEGACY_BLOCK_OFFSET) THEN
      idx = block_id - IF_LEGACY_BLOCK_OFFSET
      ok = (idx >= 1 .AND. idx <= legacy_ptr_count .AND. ALLOCATED(legacy_ptr_blocks) .AND. &
            legacy_ptr_blocks(idx)%ptr_associated)
    ELSE
      ok = (block_id >= 1 .AND. block_id <= pool%num_blocks .AND. pool%block_allocated(block_id))
    END IF
  END FUNCTION mem_is_pointer_associated

  SUBROUTINE mem_disassociate_pointer(pool, block_id, status)
    TYPE(MemoryPool), INTENT(INOUT) :: pool
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: idx
    CALL init_error_status(status)
    IF (block_id >= IF_LEGACY_BLOCK_OFFSET) THEN
      idx = block_id - IF_LEGACY_BLOCK_OFFSET
      IF (idx >= 1 .AND. idx <= legacy_ptr_count .AND. ALLOCATED(legacy_ptr_blocks)) &
        legacy_ptr_blocks(idx)%ptr_associated = .FALSE.
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE mem_disassociate_pointer

  FUNCTION INT_TO_STRING(val) RESULT(str)
    INTEGER(i4), INTENT(IN) :: val
    CHARACTER(len=32) :: str
    WRITE(str, '(I0)') val
  END FUNCTION INT_TO_STRING

  SUBROUTINE IF_Mem_AllocReal1D(domain, layer, n, name, ptr, pointer_id, status)
    INTEGER(i4), INTENT(IN) :: domain, layer
    INTEGER(i4), INTENT(IN) :: n
    CHARACTER(len=*), INTENT(IN) :: name
    REAL(wp), POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    NULLIFY(ptr)
    pointer_id = -1
    IF (n <= 0) RETURN
    ALLOCATE(ptr(n), stat=status%status_code)
    IF (status%status_code /= 0) THEN
      status%message = 'IF_Mem_AllocReal1D failed: ' // TRIM(name)
      status%has_error = .TRUE.
      RETURN
    END IF
    pointer_id = next_id
    next_id = next_id + 1
    IF (next_id > 2147483647) next_id = 1
    reg_count = MIN(reg_count + 1, IF_MAX_PTR)
    reg_id(reg_count) = pointer_id
    reg_is1d(reg_count) = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_AllocReal1D

  SUBROUTINE UF_Mem_AllocReal1D(domain, layer, n, name, ptr, pointer_id, status)
    INTEGER(i4), INTENT(IN) :: domain, layer
    INTEGER(i4), INTENT(IN) :: n
    CHARACTER(len=*), INTENT(IN) :: name
    REAL(wp), POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL IF_Mem_AllocReal1D(domain, layer, n, name, ptr, pointer_id, status)
  END SUBROUTINE UF_Mem_AllocReal1D

  SUBROUTINE IF_Mem_AllocReal2D(domain, layer, n1, n2, name, ptr, pointer_id, status)
    INTEGER(i4), INTENT(IN) :: domain, layer
    INTEGER(i4), INTENT(IN) :: n1, n2
    CHARACTER(len=*), INTENT(IN) :: name
    REAL(wp), POINTER, INTENT(OUT) :: ptr(:,:)
    INTEGER(i4), INTENT(OUT) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    NULLIFY(ptr)
    pointer_id = -1
    IF (n1 <= 0 .OR. n2 <= 0) RETURN
    ALLOCATE(ptr(n1, n2), stat=status%status_code)
    IF (status%status_code /= 0) THEN
      status%message = 'IF_Mem_AllocReal2D failed: ' // TRIM(name)
      status%has_error = .TRUE.
      RETURN
    END IF
    pointer_id = next_id
    next_id = next_id + 1
    IF (next_id > 2147483647) next_id = 1
    reg_count = MIN(reg_count + 1, IF_MAX_PTR)
    reg_id(reg_count) = pointer_id
    reg_is1d(reg_count) = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_AllocReal2D

  SUBROUTINE UF_Mem_AllocReal2D(domain, layer, n1, n2, name, ptr, pointer_id, status)
    INTEGER(i4), INTENT(IN) :: domain, layer
    INTEGER(i4), INTENT(IN) :: n1, n2
    CHARACTER(len=*), INTENT(IN) :: name
    REAL(wp), POINTER, INTENT(OUT) :: ptr(:,:)
    INTEGER(i4), INTENT(OUT) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL IF_Mem_AllocReal2D(domain, layer, n1, n2, name, ptr, pointer_id, status)
  END SUBROUTINE UF_Mem_AllocReal2D

  SUBROUTINE IF_Mem_FreeReal1D(pointer_id, status)
    INTEGER(i4), INTENT(IN) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_FreeReal1D

  SUBROUTINE UF_Mem_FreeReal1D(pointer_id, status)
    INTEGER(i4), INTENT(IN) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL IF_Mem_FreeReal1D(pointer_id, status)
  END SUBROUTINE UF_Mem_FreeReal1D

  SUBROUTINE IF_Mem_FreeReal2D(pointer_id, status)
    INTEGER(i4), INTENT(IN) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Mem_FreeReal2D

  SUBROUTINE UF_Mem_FreeReal2D(pointer_id, status)
    INTEGER(i4), INTENT(IN) :: pointer_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL IF_Mem_FreeReal2D(pointer_id, status)
  END SUBROUTINE UF_Mem_FreeReal2D
END MODULE IF_Mem_Mgr