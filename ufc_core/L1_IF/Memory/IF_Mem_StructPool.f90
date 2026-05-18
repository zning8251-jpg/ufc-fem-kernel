!===============================================================================
! MODULE: IF_Mem_StructPool
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Impl — structured memory pool (managed blocks + unified memory)
! BRIEF:  Create/query/update/delete subarrays; symbol table + metadata
!         integration; device memory check. Merged from UF_StructMemPool.
!===============================================================================

MODULE IF_Mem_StructPool
    ! One-way hierarchical dependency: Only import minimal necessary components from lower-level modules,
    ! strictly avoid circular dependencies.
    
    ! Import ISO_C_BINDING for C pointer operations
    USE, INTRINSIC :: ISO_C_BINDING
    
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType,          &  ! Error status type
        init_error_status,        &  ! Initialize error status
        log_debug, log_info, log_error, log_warn, &  ! Logging functions
        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_MEM_ERROR, &  ! Basic error codes
        IF_STATUS_NOT_FOUND, IF_STATUS_INVALID, IF_STATUS_EXISTS, &
        IF_STATUS_FATAL, IF_STATUS_UNSUPPORTED
    
    USE IF_Base_SymTbl, ONLY: &
        register_variable,        &  ! Register variable to symbol table
        unregister_variable,      &  ! Unregister variable from symbol table
        find_variable,            &  ! Find variable
        get_variable_data_id,     &  ! Get variable data ID
        symbol_table_exists,      &  ! Check if variable exists in symbol table
        IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR, IF_DATA_TYPE_STRUCT, IF_DATA_TYPE_CLASS, &
        IF_STORAGE_TYPE_STRUCTURED, IF_STORAGE_TYPE_UNSTRUCTURED, &  ! Storage type constants
        IF_STATUS_VAR_NAME_INVALID, IF_STATUS_DATA_ID_EMPTY, IF_STATUS_TYPE_MISMATCH, &
        IF_STATUS_TABLE_FULL, IF_STATUS_TABLE_NOT_INIT
    
    USE IF_Base_StructMeta_Def, ONLY: &
        StructMetaType,           &  ! Structured metadata type
        init_struct_meta_mgr,     &  ! Initialize metadata manager
        destroy_struct_meta_mgr,  &  ! Destroy metadata manager
        struct_meta_create,       &  ! Create metadata
        struct_meta_query,        &  ! Query metadata
        struct_meta_update,       &  ! Update metadata
        struct_meta_delete,       &  ! Delete metadata
        struct_meta_validate,     &  ! Validate metadata
        IF_STATUS_META_EXISTS, IF_STATUS_META_NOT_FOUND, IF_STATUS_META_DIM_INVALID, &
        IF_STATUS_META_TYPE_MISMATCH, IF_STATUS_META_NO_SYM_LINK, IF_STATUS_META_NOT_INIT, &
        IF_MAX_DIMENSIONS, IF_MAX_DATA_ID_LEN, IF_MAX_VAR_NAME_LEN
    
    USE IF_Device_Mgr, ONLY: &
        DeviceInfoType,           &  ! Device information type
        init_device_mgr,          &  ! Initialize device manager
        destroy_device_mgr,       &  ! Destroy device manager
        register_device,          &  ! Register device
        unregister_device,       &  ! Unregister device
        query_device_memory,      &  ! Query device memory
        update_device_status,     &  ! Update device status
        get_device_info,          &  ! Get device information
        check_device_mem_suff        ! Check device memory sufficiency
    !     get_active_device_count,  &  ! Get active device count
    !     IF_STATUS_DEV_EXISTS, IF_STATUS_DEV_NOT_FOUND, IF_STATUS_DEV_TYPE_INVALID, &
    !     IF_STATUS_DEV_MEM_ERROR, IF_STATUS_DEV_NOT_INIT, IF_STATUS_DEV_OFFLINE, &
    !     IF_STATUS_DEV_PERM_DENY, IF_STATUS_DEV_MEM_INSUFF, IF_STATUS_DEV_META_ERR, &
    !     IF_MAX_DEVICE_COUNT, IF_DEV_TYPE_CPU, IF_DEV_TYPE_GPU
    
    IMPLICIT NONE
    
    ! Local definitions of DeviceManager constants (temporary workaround)
    INTEGER(i4), PARAMETER :: IF_MAX_DEVICE_COUNT = 8
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_TYPE_INVALID = 123
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_MEM_INSUFF = 124
    INTEGER(i4), PARAMETER :: IF_DEV_TYPE_CPU = 1
    INTEGER(i4), PARAMETER :: IF_DEV_TYPE_GPU = 2
    
    !--------------------------------------------------------------------------
    ! 1. Module-specific error codes (defined within this module, range 231-241)
    !    Avoid conflicts with other modules.
    !--------------------------------------------------------------------------
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_EXISTS = 231     ! "Structured memory block already exists (data_id duplicate)"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_NOT_FOUND = 232   ! "Structured memory block not found"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_DIM_MISMATCH = 233 ! "Dimension mismatch"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_MEM_INSUFF = 234  ! "Insufficient memory"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_NOT_INIT = 235    ! "Structured memory pool not initialized"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_ALIGN_ERR = 236   ! "Memory alignment error"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_DEV_MISMATCH = 237 ! "Device mismatch"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_LRU_ERR = 238     ! "LRU eviction error"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_PERM_DENY = 239   ! "Permission denied"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_UNIFIED_ERR = 240  ! "Unified memory error"
    INTEGER(i4), PARAMETER :: IF_STATUS_SMEM_STRUCT_ERR = 241   ! "Structure/class operation error"
    
    !--------------------------------------------------------------------------
    ! 2. Core constants for structured memory pool (defined within this module)
    !    Adapt to industrial-grade numerical computing scenarios.
    !--------------------------------------------------------------------------
    INTEGER(i4), PARAMETER :: IF_MAX_SMEM_BLOCKS = 1000        ! "Maximum number of memory blocks"
    INTEGER(KIND=8), PARAMETER :: IF_DEFAULT_SMEM_BLOCK_SIZE = 1024*1024  ! "Default block size (1MB)"
    INTEGER(KIND=8), PARAMETER :: IF_SMEM_ALIGN_SIZE = 64   ! "Memory alignment size (64 bytes)"
    INTEGER(KIND=8), PARAMETER :: IF_MIN_SMEM_SIZE = 1024   ! "Minimum memory pool size (1KB)"
    INTEGER(i4), PARAMETER :: IF_MAX_SMEM_DIMS = 4             ! "Maximum number of dimensions"
    INTEGER(i4), PARAMETER :: IF_SMEM_LRU_THRESHOLD = 80       ! "LRU eviction threshold (80%)"
    INTEGER(i4), PARAMETER :: IF_MAX_UNIFIED_SUBARRAYS = 100   ! "Maximum number of unified memory subarrays"
    INTEGER(KIND=8), PARAMETER :: IF_DEFAULT_UNIFIED_SIZE = 1024*1024*1024  ! "Default unified memory size (1GB)"
    INTEGER(i4), PARAMETER :: IF_SYNC_STATE_IN_SYNC        = 0   ! "Host and device buffers are in sync"
    INTEGER(i4), PARAMETER :: IF_SYNC_STATE_HOST_UPDATED   = 1   ! "Host has newer data than device"
    INTEGER(i4), PARAMETER :: IF_SYNC_STATE_DEVICE_UPDATED = 2   ! "Device has newer data than host"
    
    !--------------------------------------------------------------------------
    ! 3. Structured Memory Block Type: Stores attributes and status of a single 
    !    structured memory block (supports all data types + all dimensions + unified memory)
    !--------------------------------------------------------------------------
    TYPE :: StructMemBlockType
        CHARACTER(LEN=20) :: alloc_time = ""             ! "Allocation timestamp"
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: var_name = "" ! "Variable name"
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""   ! "Data ID"
        INTEGER(i4) :: data_type = IF_DATA_TYPE_INT             ! "Data type"
        INTEGER(i4) :: dims(IF_MAX_SMEM_DIMS) = [0,0,0,0]       ! "Dimension information"
        INTEGER(i4) :: char_len = 0                          ! "Character length (only for CHAR type)"
        INTEGER(i4) :: device_id = 1                         ! "Device ID"
        INTEGER(KIND=8) :: mem_addr = 0                  ! "Memory address"
        INTEGER(KIND=8) :: block_size = 0                ! "Block size (bytes)"
        INTEGER(KIND=8) :: used_size = 0                 ! "Used size (bytes)"
        LOGICAL :: is_used = .FALSE.                     ! "Whether in use"
        LOGICAL :: is_locked = .FALSE.                   ! "Whether locked (prevent LRU eviction)"
        LOGICAL :: is_unified = .FALSE.                  ! "Whether unified memory"
        INTEGER(i4) :: subarray_id = 0                       ! "Unified memory subarray ID"
        INTEGER(i4) :: struct_id = 0                         ! "Structure definition ID (0=none)"
        INTEGER(i4) :: class_id = 0                          ! "Class definition ID (0=none)"
        CHARACTER(LEN=20) :: last_access_time = ""       ! "Last access timestamp"
        INTEGER(i4) :: lru_count = 0                         ! "LRU counter"
    END TYPE StructMemBlockType
    
    ! Workaround for C_F_POINTER: FPTR shall not be polymorphic (F2018). Use
    ! non-polymorphic intermediate, then ptr=>intermediate for CLASS(*) output.
    TYPE, PRIVATE :: CptrStorageType
        SEQUENCE
        INTEGER(C_INT8_T) :: d(1)
    END TYPE CptrStorageType
    
    !--------------------------------------------------------------------------
    ! 4. Structure Member Type: Stores structure member information
    !--------------------------------------------------------------------------
    TYPE :: StructMemberType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: name = ""     ! "Member name"
        INTEGER(i4) :: data_type = IF_DATA_TYPE_INT             ! "Data type"
        INTEGER(i4) :: dims(IF_MAX_DIMENSIONS) = [0,0,0,0]      ! "Dimensions"
        INTEGER(i4) :: char_len = 0                          ! "Character length"
        INTEGER(KIND=8) :: offset = 0                    ! "Memory offset"
        LOGICAL :: is_public = .TRUE.                    ! "Whether public"
    END TYPE StructMemberType
    
    !--------------------------------------------------------------------------
    ! 5. Structure Definition Type: Complete structure metadata
    !--------------------------------------------------------------------------
    TYPE :: StructDefType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: name = ""     ! "Structure name"
        INTEGER(i4) :: struct_id = 0                         ! "Structure ID"
        INTEGER(i4) :: member_count = 0                      ! "Number of members"
        TYPE(StructMemberType), ALLOCATABLE :: members(:) ! "Member list"
        INTEGER(KIND=8) :: size = 0                      ! "Structure size (bytes)"
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: metadata = ""  ! "Metadata"
        LOGICAL :: is_complete = .FALSE.                 ! "Whether fully defined"
    END TYPE StructDefType
    
    !--------------------------------------------------------------------------
    ! 6. Class Definition Type: Complete class metadata
    !--------------------------------------------------------------------------
    TYPE :: ClassDefType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: name = ""     ! "Class name"
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: parent_name = "" ! "Parent class name"
        INTEGER(i4) :: class_id = 0                          ! "Class ID"
        INTEGER(i4) :: parent_id = 0                         ! "Parent class ID"
        INTEGER(i4) :: member_count = 0                      ! "Number of members"
        TYPE(StructMemberType), ALLOCATABLE :: members(:) ! "Member list"
        INTEGER(KIND=8) :: size = 0                      ! "Class size (bytes)"
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: metadata = ""  ! "Metadata"
        LOGICAL :: is_complete = .FALSE.                 ! "Whether fully defined"
    END TYPE ClassDefType
    
    !--------------------------------------------------------------------------
    ! 7. Unified Memory Subarray Type: Manages subarrays in unified memory
    !--------------------------------------------------------------------------
    TYPE :: UnifiedSubarrayType
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""   ! "Data ID"
        INTEGER(i4) :: data_type = IF_DATA_TYPE_INT             ! "Data type"
        INTEGER(i4) :: dims(IF_MAX_DIMENSIONS) = [0,0,0,0]      ! "Dimensions"
        INTEGER(i4) :: char_len = 0                          ! "Character length"
        INTEGER(KIND=8) :: offset = 0                    ! "Offset (bytes)"
        INTEGER(KIND=8) :: size = 0                      ! "Size (bytes)"
        LOGICAL :: is_used = .FALSE.                     ! "Whether in use"
    END TYPE UnifiedSubarrayType

    !--------------------------------------------------------------------------
    ! 7.x Block-Device buffer mapping type: maintains simulated device buffer view
    !--------------------------------------------------------------------------
    TYPE :: StructDeviceBufferMapType
        INTEGER(i4) :: block_id = 0                          ! "Mapped block ID"
        INTEGER(i4) :: device_id = 0                         ! "Target device ID"
        TYPE(C_PTR) :: device_ptr = C_NULL_PTR           ! "Opaque device buffer handle / pointer"
        INTEGER(KIND=8) :: size_bytes = 0_8              ! "Buffer size in bytes"
        INTEGER(i4) :: sync_state = 0                        ! "Synchronization state (host/device/in-sync)"
        LOGICAL :: is_used = .FALSE.                     ! "Whether this mapping slot is in use"
    END TYPE StructDeviceBufferMapType
    
    !--------------------------------------------------------------------------
    ! 8. Structured Memory Pool Type: Manages all structured memory blocks + unified memory,
    !    maintains statistical information.
    !--------------------------------------------------------------------------
    TYPE :: StructMemPoolType
        LOGICAL :: initialized = .FALSE.                 ! "Whether memory pool is initialized"
        INTEGER(i4) :: bound_device_id = 1                   ! "Bound device ID (pool memory only for this device)"
        INTEGER(i4) :: max_blocks = IF_MAX_SMEM_BLOCKS          ! "Maximum number of memory blocks"
        INTEGER(i4) :: used_blocks = 0                       ! "Number of used memory blocks"
        INTEGER(KIND=8) :: total_mem = 0                 ! "Total pool memory (bytes)"
        INTEGER(KIND=8) :: free_mem = 0                  ! "Free memory (bytes)"
        INTEGER(i4) :: alloc_count = 0                       ! "Allocation count"
        INTEGER(i4) :: free_count = 0                        ! "Free count"
        INTEGER(i4) :: lru_evict_count = 0                   ! "LRU eviction count"
        INTEGER(i4) :: expand_count = 0                      ! "Expansion count"
        INTEGER(i4) :: struct_count = 0                      ! "Number of structure definitions"
        INTEGER(i4) :: class_count = 0                       ! "Number of class definitions"
        TYPE(StructDefType), ALLOCATABLE :: struct_defs(:) ! "Structure definition list"
        TYPE(ClassDefType), ALLOCATABLE :: class_defs(:) ! "Class definition list"
        TYPE(StructMemBlockType), ALLOCATABLE :: mem_blocks(:) ! "Memory block list"
        TYPE(StructDeviceBufferMapType), ALLOCATABLE :: device_buffer_maps(:) ! "Block-device buffer mapping list"
        INTEGER(i4) :: device_buffer_map_count = 0           ! "Number of active device buffer mappings"
        ! Unified memory related
        LOGICAL :: unified_mem_enabled = .FALSE.         ! "Whether unified memory is enabled"
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: unified_mem_id = "" ! "Unified memory ID"
        INTEGER(KIND=8) :: unified_mem_size = 0          ! "Unified memory size (bytes)"
        INTEGER(KIND=8) :: unified_mem_used = 0          ! "Used unified memory (bytes)"
        TYPE(UnifiedSubarrayType), ALLOCATABLE :: unified_subarrays(:) ! "Unified memory subarrays"
    END TYPE StructMemPoolType
    
    !--------------------------------------------------------------------------
    ! 9. Backing buffers for structured memory pool (CPU memory only in Phase B)
    !--------------------------------------------------------------------------
    INTEGER(KIND=1), ALLOCATABLE, TARGET, PRIVATE, SAVE :: pool_buffer(:)
    INTEGER(KIND=1), ALLOCATABLE, TARGET, PRIVATE, SAVE :: unified_buffer(:)
    TYPE(C_PTR), PRIVATE, SAVE :: pool_base_cptr = C_NULL_PTR
    TYPE(C_PTR), PRIVATE, SAVE :: unified_base_cptr = C_NULL_PTR
    
    !--------------------------------------------------------------------------
    ! 10. Module global instance (PRIVATE+SAVE: Fortran2003 Standard, ensure persistence
    !     and no direct external access)
    !--------------------------------------------------------------------------
    TYPE(StructMemPoolType), PRIVATE, SAVE :: global_struct_mem_pool
    
    !--------------------------------------------------------------------------
    ! 11. Public interface export (Minimal exposure principle: Only export types
    !     and subroutines needed by external code)
    !--------------------------------------------------------------------------
    PRIVATE
    PUBLIC :: init_struct_mem_pool, destroy_struct_mem_pool
    ! Basic memory operations
    PUBLIC :: alloc_struct_mem, dealloc_struct_mem, query_struct_mem_block, &
              check_struct_block_device_mem, check_struct_block_device_mem_on_device
    PUBLIC :: get_struct_mem_pool_stats, lock_struct_mem, unlock_struct_mem
    PUBLIC :: get_struct_block_base_cptr
    ! All-type all-dimension dedicated allocation
    PUBLIC :: alloc_int1d, alloc_int2d, alloc_int3d, alloc_int4d
    PUBLIC :: alloc_dp1d, alloc_dp2d, alloc_dp3d, alloc_dp4d
    PUBLIC :: alloc_char1d, alloc_char2d, alloc_char3d, alloc_char4d
    PUBLIC :: alloc_struct, alloc_class
    PUBLIC :: alloc_struct_array, alloc_class_array
    ! Structure/class management
    PUBLIC :: register_struct_def, register_class_def
    PUBLIC :: add_struct_member, add_class_member
    PUBLIC :: finalize_struct_def, finalize_class_def
    PUBLIC :: verify_struct_layout, verify_class_layout
    ! All-dimension unified memory operations
    PUBLIC :: create_struct_unified_mem, register_struct_subarray
    PUBLIC :: get_unified_subarray_id_by_data_id
    PUBLIC :: get_struct_subarray_ptr_1d_int, get_struct_subarray_ptr_2d_int, &
              get_struct_subarray_ptr_3d_int, get_struct_subarray_ptr_4d_int
    PUBLIC :: get_struct_subarray_ptr_1d_dp, get_struct_subarray_ptr_2d_dp, &
              get_struct_subarray_ptr_3d_dp, get_struct_subarray_ptr_4d_dp
    PUBLIC :: get_struct_subarray_ptr_1d_char, get_struct_subarray_ptr_2d_char, &
              get_struct_subarray_ptr_3d_char, get_struct_subarray_ptr_4d_char
    ! All-dimension pointer retrieval
    PUBLIC :: get_int1d_ptr, get_int2d_ptr, get_int3d_ptr, get_int4d_ptr
    PUBLIC :: get_dp1d_ptr, get_dp2d_ptr, get_dp3d_ptr, get_dp4d_ptr
    PUBLIC :: get_char1d_ptr, get_char2d_ptr, get_char3d_ptr, get_char4d_ptr
    PUBLIC :: get_struct_ptr, get_class_ptr
    PUBLIC :: get_struct_element_ptr, get_struct_element_cptr, get_class_element_ptr
    PUBLIC :: get_struct_block_id_by_data_id, get_class_block_id_by_data_id
    ! Error code export
    PUBLIC :: IF_STATUS_SMEM_EXISTS, IF_STATUS_SMEM_NOT_FOUND, IF_STATUS_SMEM_DIM_MISMATCH
    PUBLIC :: IF_STATUS_SMEM_MEM_INSUFF, IF_STATUS_SMEM_NOT_INIT, IF_STATUS_SMEM_ALIGN_ERR
    PUBLIC :: IF_STATUS_SMEM_DEV_MISMATCH, IF_STATUS_SMEM_LRU_ERR, IF_STATUS_SMEM_PERM_DENY
    PUBLIC :: IF_STATUS_SMEM_UNIFIED_ERR, IF_STATUS_SMEM_STRUCT_ERR
    ! Constant export
    PUBLIC :: IF_MAX_SMEM_BLOCKS, IF_DEFAULT_SMEM_BLOCK_SIZE, IF_SMEM_ALIGN_SIZE
    PUBLIC :: IF_MIN_SMEM_SIZE, IF_MAX_SMEM_DIMS, IF_SMEM_LRU_THRESHOLD
    PUBLIC :: IF_MAX_UNIFIED_SUBARRAYS, IF_DEFAULT_UNIFIED_SIZE
	PUBLIC :: StructMemBlockType
    !  ???Phase B?CPU-only  check ))
    PUBLIC :: smem_map_block_to_device, smem_sync_block, smem_get_device_buffer
    INTEGER, PARAMETER, PUBLIC :: IF_SYNC_HOST_TO_DEVICE = 1
    INTEGER, PARAMETER, PUBLIC :: IF_SYNC_DEVICE_TO_HOST = 2
    
CONTAINS

SUBROUTINE add_class_member(class_id, member_name, member_type, dims, char_len, is_public, status)
    INTEGER(i4), INTENT(IN) :: class_id
    CHARACTER(LEN=*), INTENT(IN) :: member_name
    INTEGER(i4), INTENT(IN) :: member_type
    INTEGER(i4), INTENT(IN) :: dims(3)
    INTEGER, INTENT(IN), OPTIONAL :: char_len
    LOGICAL, INTENT(IN), OPTIONAL :: is_public
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, alloc_stat, local_char_len = 0
    LOGICAL :: local_is_public = .TRUE.
    TYPE(StructMemberType), ALLOCATABLE :: temp_members(:)
    
    CALL init_error_status(status)
    
    ! Precondition: Check if memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Validate class ID range
    IF (class_id <= 0 .OR. class_id > global_struct_mem_pool%class_count) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Invalid class ID (must be 1-", &
            global_struct_mem_pool%class_count, "), got ", class_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Handle optional parameters
    IF (PRESENT(char_len)) local_char_len = char_len
    IF (PRESENT(is_public)) local_is_public = is_public
    
    ! Check for duplicate member names in the class
    DO i = 1, global_struct_mem_pool%class_defs(class_id)%member_count
        IF (TRIM(global_struct_mem_pool%class_defs(class_id)%members(i)%name) == TRIM(member_name)) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Member name already exists in class"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END DO
    
    ! Allocate memory for members (expand if needed)
    IF (.NOT. ALLOCATED(global_struct_mem_pool%class_defs(class_id)%members)) THEN
        ! Allocate for first member
        ALLOCATE(global_struct_mem_pool%class_defs(class_id)%members(1), STAT=alloc_stat)
        IF (alloc_stat /= 0) THEN
            status%status_code = IF_STATUS_SMEM_MEM_INSUFF
            WRITE(status%message, '(A,I0)') "Failed to allocate class members array, STAT=", alloc_stat
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    ELSE
        ! Expand existing member array
        temp_members = global_struct_mem_pool%class_defs(class_id)%members
        DEALLOCATE(global_struct_mem_pool%class_defs(class_id)%members)
        ALLOCATE(global_struct_mem_pool%class_defs(class_id)%members( &
            global_struct_mem_pool%class_defs(class_id)%member_count + 1), STAT=alloc_stat)
        IF (alloc_stat /= 0) THEN
            status%status_code = IF_STATUS_SMEM_MEM_INSUFF
            WRITE(status%message, '(A,I0)') "Failed to allocate class members array, STAT=", alloc_stat
            CALL log_error("StructMemPool", TRIM(status%message))
            DEALLOCATE(temp_members)
            RETURN
        END IF
        
        ! Copy existing members to new array
        DO i = 1, SIZE(temp_members)
            global_struct_mem_pool%class_defs(class_id)%members(i) = temp_members(i)
        END DO
        DEALLOCATE(temp_members)
    END IF
    
    ! Set new member properties
    global_struct_mem_pool%class_defs(class_id)%member_count = &
        global_struct_mem_pool%class_defs(class_id)%member_count + 1
    i = global_struct_mem_pool%class_defs(class_id)%member_count
    
    global_struct_mem_pool%class_defs(class_id)%members(i)%name = TRIM(member_name)
    global_struct_mem_pool%class_defs(class_id)%members(i)%data_type = member_type
    ! Convert 3D dims to IF_MAX_DIMENSIONS dims
    global_struct_mem_pool%class_defs(class_id)%members(i)%dims = [dims(1), dims(2), dims(3), 0]
    global_struct_mem_pool%class_defs(class_id)%members(i)%char_len = local_char_len
    global_struct_mem_pool%class_defs(class_id)%members(i)%is_public = local_is_public
    
    CALL log_info("StructMemPool", &
        "Added class member: class ID="//TRIM(INT_TO_STR(class_id))//&
        ", member='"//TRIM(member_name)//"'")
    
    status%status_code = IF_STATUS_OK
    status%message = "Class member added successfully"
    
END SUBROUTINE add_class_member

SUBROUTINE add_struct_member(struct_id, member_name, member_type, dims, char_len, is_public, status)
    INTEGER(i4), INTENT(IN) :: struct_id
    CHARACTER(LEN=*), INTENT(IN) :: member_name
    INTEGER(i4), INTENT(IN) :: member_type
    INTEGER(i4), INTENT(IN) :: dims(3)
    INTEGER, INTENT(IN), OPTIONAL :: char_len
    LOGICAL, INTENT(IN), OPTIONAL :: is_public
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, alloc_stat, local_char_len = 0
    LOGICAL :: local_is_public = .TRUE.
    TYPE(StructMemberType), ALLOCATABLE :: temp_members(:)
    
    CALL init_error_status(status)
    
    ! Precondition: Check if memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Validate struct ID range
    IF (struct_id <= 0 .OR. struct_id > global_struct_mem_pool%struct_count) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Invalid struct ID (must be 1-", &
            global_struct_mem_pool%struct_count, "), got ", struct_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Handle optional parameters
    IF (PRESENT(char_len)) local_char_len = char_len
    IF (PRESENT(is_public)) local_is_public = is_public
    
    ! Check for duplicate member names in the struct
    DO i = 1, global_struct_mem_pool%struct_defs(struct_id)%member_count
        IF (TRIM(global_struct_mem_pool%struct_defs(struct_id)%members(i)%name) == TRIM(member_name)) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Member name already exists in struct"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END DO
    
    ! Allocate memory for members (expand if needed)
    IF (.NOT. ALLOCATED(global_struct_mem_pool%struct_defs(struct_id)%members)) THEN
        ! Allocate for first member
        ALLOCATE(global_struct_mem_pool%struct_defs(struct_id)%members(1), STAT=alloc_stat)
        IF (alloc_stat /= 0) THEN
            status%status_code = IF_STATUS_SMEM_MEM_INSUFF
            WRITE(status%message, '(A,I0)') "Failed to allocate struct members array, STAT=", alloc_stat
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    ELSE
        ! Expand existing member array
        temp_members = global_struct_mem_pool%struct_defs(struct_id)%members
        DEALLOCATE(global_struct_mem_pool%struct_defs(struct_id)%members)
        ALLOCATE(global_struct_mem_pool%struct_defs(struct_id)%members( &
            global_struct_mem_pool%struct_defs(struct_id)%member_count + 1), STAT=alloc_stat)
        IF (alloc_stat /= 0) THEN
            status%status_code = IF_STATUS_SMEM_MEM_INSUFF
            WRITE(status%message, '(A,I0)') "Failed to allocate struct members array, STAT=", alloc_stat
            CALL log_error("StructMemPool", TRIM(status%message))
            DEALLOCATE(temp_members)
            RETURN
        END IF
        
        ! Copy existing members to new array
        DO i = 1, SIZE(temp_members)
            global_struct_mem_pool%struct_defs(struct_id)%members(i) = temp_members(i)
        END DO
        DEALLOCATE(temp_members)
    END IF
    
    ! Set new member properties
    global_struct_mem_pool%struct_defs(struct_id)%member_count = &
        global_struct_mem_pool%struct_defs(struct_id)%member_count + 1
    i = global_struct_mem_pool%struct_defs(struct_id)%member_count
    
    global_struct_mem_pool%struct_defs(struct_id)%members(i)%name = TRIM(member_name)
    global_struct_mem_pool%struct_defs(struct_id)%members(i)%data_type = member_type
    ! Convert 3D dims to IF_MAX_DIMENSIONS dims
    global_struct_mem_pool%struct_defs(struct_id)%members(i)%dims = [dims(1), dims(2), dims(3), 0]
    global_struct_mem_pool%struct_defs(struct_id)%members(i)%char_len = local_char_len
    global_struct_mem_pool%struct_defs(struct_id)%members(i)%is_public = local_is_public
    
    CALL log_info("StructMemPool", &
        "Added struct member: struct ID="//TRIM(INT_TO_STR(struct_id))//&
        ", member='"//TRIM(member_name)//"'")
    
    status%status_code = IF_STATUS_OK
    status%message = "Struct member added successfully"
    
END SUBROUTINE add_struct_member

SUBROUTINE alloc_char1d(var_name, dim1, char_len, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1
    INTEGER(i4), INTENT(IN) :: char_len
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension & char length (both must be positive)
    IF (dim1 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0)') "1D dimension must be positive (dim1=", dim1, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (char_len <= 0) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0)') "Character length must be positive (len=", char_len, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (CHAR = char_len bytes per element)
    req_size = INT(dim1, KIND=8) * INT(char_len, KIND=8)
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_CHAR, [dim1,0,0,0], char_len, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_CHAR
        new_block%dims = [dim1, 0, 0, 0]
        new_block%char_len = char_len
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table
        CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_CHAR, IF_STORAGE_TYPE_STRUCTURED, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated CHAR1D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//", len="//TRIM(INT_TO_STR(char_len))//&
        "  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "CHAR1D array allocated successfully"
    
END SUBROUTINE alloc_char1d

SUBROUTINE alloc_char2d(var_name, dim1, dim2, char_len, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2
    INTEGER(i4), INTENT(IN) :: char_len
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension & char length (all must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0)') "2D dims must be positive (dim1=", &
            dim1, ", dim2=", dim2, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (char_len <= 0) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0)') "Character length must be positive (len=", char_len, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (CHAR = char_len bytes per element)
    req_size = INT(dim1 * dim2, KIND=8) * INT(char_len, KIND=8)
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_CHAR, [dim1,dim2,0,0], char_len, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_CHAR
        new_block%dims = [dim1, dim2, 0, 0]
        new_block%char_len = char_len
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table
        CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_CHAR, IF_STORAGE_TYPE_STRUCTURED, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated CHAR2D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//&
        ", len="//TRIM(INT_TO_STR(char_len))//"  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "CHAR2D array allocated successfully"
    
END SUBROUTINE alloc_char2d

SUBROUTINE alloc_char3d(var_name, dim1, dim2, dim3, char_len, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3
    INTEGER(i4), INTENT(IN) :: char_len
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension & char length (all must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "3D dims must be positive (dim1=", &
            dim1, ", dim2=", dim2, ", dim3=", dim3, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (char_len <= 0) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0)') "Character length must be positive (len=", char_len, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (CHAR = char_len bytes per element)
    req_size = INT(dim1 * dim2 * dim3, KIND=8) * INT(char_len, KIND=8)
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_CHAR, [dim1,dim2,dim3,0], char_len, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_CHAR
        new_block%dims = [dim1, dim2, dim3, 0]
        new_block%char_len = char_len
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table
        CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_CHAR, IF_STORAGE_TYPE_STRUCTURED, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated CHAR3D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//", len="//TRIM(INT_TO_STR(char_len))//&
        "  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "CHAR3D array allocated successfully"
    
END SUBROUTINE alloc_char3d

SUBROUTINE alloc_char4d(var_name, dim1, dim2, dim3, dim4, char_len, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3, dim4
    INTEGER(i4), INTENT(IN) :: char_len
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension & char length (all must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0 .OR. dim4 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0)') "4D dims must be positive (dim1=", &
            dim1, ", dim2=", dim2, ", dim3=", dim3, ", dim4=", dim4, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (char_len <= 0) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0)') "Character length must be positive (len=", char_len, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (CHAR = char_len bytes per element)
    req_size = INT(dim1 * dim2 * dim3 * dim4, KIND=8) * INT(char_len, KIND=8)
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_CHAR, [dim1,dim2,dim3,dim4], char_len, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_CHAR
        new_block%dims = [dim1, dim2, dim3, dim4]
        new_block%char_len = char_len
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table
        CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_CHAR, IF_STORAGE_TYPE_STRUCTURED, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated CHAR4D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//"x"//TRIM(INT_TO_STR(dim4))//&
        ", len="//TRIM(INT_TO_STR(char_len))//"  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "CHAR4D array allocated successfully"
    
END SUBROUTINE alloc_char4d

SUBROUTINE alloc_class(class_name, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: class_name
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    INTEGER(i4) :: i, j, class_id
    INTEGER(KIND=8) :: class_size
    LOGICAL :: use_unified_mem = .FALSE.
    TYPE(StructMetaType) :: class_meta
    TYPE(ErrorStatusType) :: class_meta_status
    INTEGER(i4) :: class_dims(IF_MAX_DIMENSIONS)
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Process optional parameters
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Find class definition
    class_id = 0
    DO i = 1, global_struct_mem_pool%class_count
        IF (TRIM(global_struct_mem_pool%class_defs(i)%name) == TRIM(class_name)) THEN
            class_id = i
            EXIT
        END IF
    END DO
    
    IF (class_id == 0) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Class '", TRIM(class_name), "' not found"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Check if class is fully defined
    IF (.NOT. global_struct_mem_pool%class_defs(class_id)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,A,A)') "Class '", TRIM(class_name), "' is not fully defined"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Calculate class size (including inherited members)
    class_size = global_struct_mem_pool%class_defs(class_id)%size
    
    ! Calculate class size including all inherited members
    ! This implementation handles inheritance by traversing the class hierarchy
    class_size = 0
    
    ! Start with the current class and traverse up to the root class
    i = class_id
    DO WHILE (i /= 0)
        class_size = class_size + global_struct_mem_pool%class_defs(i)%size
        
        ! Get parent class ID
        IF (global_struct_mem_pool%class_defs(i)%parent_id /= 0) THEN
            ! Find parent class index
            DO j = 1, global_struct_mem_pool%class_count
                IF (global_struct_mem_pool%class_defs(j)%class_id == global_struct_mem_pool%class_defs(i)%parent_id) THEN
                    i = j
                    EXIT
                END IF
            END DO
        ELSE
            ! Reached root class
            EXIT
        END IF
    END DO
    
    ! Allocate memory for the class instance
    ! Using alloc_char1d as a base allocation, then updating to class type
    CALL alloc_char1d(class_name, 1, INT(class_size, KIND=4), block_id, status, use_unified_mem)
    IF (status%status_code == IF_STATUS_OK) THEN
        ! Update memory block data type to class
        global_struct_mem_pool%mem_blocks(block_id)%data_type = IF_DATA_TYPE_CLASS
        global_struct_mem_pool%mem_blocks(block_id)%char_len = 0
        global_struct_mem_pool%mem_blocks(block_id)%class_id = class_id
        global_struct_mem_pool%mem_blocks(block_id)%struct_id = 0

        ! Create structured metadata entry for this class instance
        class_dims = [1, 0, 0, 0]
        CALL struct_meta_create(TRIM(class_name), IF_DATA_TYPE_CLASS, class_dims, class_size, &
                                .FALSE., class_meta, class_meta_status)
        IF (class_meta_status%status_code == IF_STATUS_OK) THEN
            global_struct_mem_pool%mem_blocks(block_id)%data_id = TRIM(class_meta%data_id)
        ELSE
            CALL log_warn("StructMemPool", "Failed to create class metadata: "//TRIM(class_meta_status%message))
            global_struct_mem_pool%mem_blocks(block_id)%data_id = TRIM(class_name)
        END IF

        ! Initialize class instance memory
        ! This would include: 1) Zero-initializing all members, 2) Setting vtable pointers for polymorphism
        ! For Fortran 2003 compatibility, we'll initialize the memory to zero
        CALL initialize_class_memory(block_id, class_id, status)
        
        CALL log_debug("StructMemPool", &
            "Allocated CLASS: '"//TRIM(class_name)//"' (size: "// &
            TRIM(INT_TO_STR8(class_size))//" bytes, block: "// &
            TRIM(INT_TO_STR(block_id))//")")
    END IF
    
END SUBROUTINE alloc_class

SUBROUTINE alloc_class_array(var_name, class_name, dims, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    CHARACTER(LEN=*), INTENT(IN) :: class_name
    INTEGER(i4), INTENT(IN) :: dims(4)
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL,          INTENT(IN), OPTIONAL :: use_unified

    INTEGER(i4) :: i, j, class_id, dim_count
    INTEGER(KIND=8) :: class_size, total_elems, total_size, aligned_size
    LOGICAL :: use_unified_mem = .FALSE.
    TYPE(StructMetaType) :: class_meta
    TYPE(ErrorStatusType) :: class_meta_status, local_status
    TYPE(StructMemBlockType) :: new_block
    INTEGER(i4) :: free_block_id
    CHARACTER(LEN=20) :: timestamp
    INTEGER(i4) :: dims_local(4)
    INTEGER(KIND=8) :: start_offset, end_offset, idx
    INTEGER(i4) :: current_index

    CALL init_error_status(status)
    block_id = 0

    ! Process optional parameters (currently CLASS arrays do not support unified memory, fallback to regular)
    IF (PRESENT(use_unified)) THEN
        IF (use_unified) THEN
            CALL log_warn("StructMemPool", "alloc_class_array: unified memory not supported yet, falling back to regular memory")
        END IF
    END IF

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate variable name
    IF (LEN_TRIM(var_name) == 0) THEN
        status%status_code = IF_STATUS_VAR_NAME_INVALID
        status%message = "Variable name for CLASS array cannot be empty"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Ensure variable name uniqueness (skip internal cache variables)
    IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
        IF (symbol_table_exists(var_name, local_status)) THEN
            IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_NOT_FOUND) THEN
                status = local_status
                CALL log_error("StructMemPool", &
                    "Symbol table check failed in alloc_class_array: "//TRIM(status%message))
                RETURN
            END IF
            IF (local_status%status_code == IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF

    ! Pre-check 3: Find class definition
    class_id = 0
    DO i = 1, global_struct_mem_pool%class_count
        IF (TRIM(global_struct_mem_pool%class_defs(i)%name) == TRIM(class_name)) THEN
            class_id = i
            EXIT
        END IF
    END DO

    IF (class_id == 0) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Class '", TRIM(class_name), "' not found"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%class_defs(class_id)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,A,A)') "Class '", TRIM(class_name), "' is not fully defined"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Validate dimensions (1-4D, all positive)
    dims_local = dims
    dim_count = 0
    DO i = 1, 4
        IF (dims_local(i) > 0) THEN
            dim_count = dim_count + 1
        ELSE
            EXIT
        END IF
    END DO

    IF (dim_count <= 0 .OR. dim_count > 4) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        status%message = "CLASS array must have 1-4 positive dimensions"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    DO i = 1, dim_count
        IF (dims_local(i) <= 0) THEN
            status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
            status%message = "CLASS array dimensions must be positive"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END DO

    ! Calculate class size including inherited members (same logic as alloc_class)
    class_size = 0_8
    current_index = class_id

    DO WHILE (current_index /= 0)
        class_size = class_size + global_struct_mem_pool%class_defs(current_index)%size

        IF (global_struct_mem_pool%class_defs(current_index)%parent_id /= 0) THEN
            j = 0
            DO i = 1, global_struct_mem_pool%class_count
                IF (global_struct_mem_pool%class_defs(i)%class_id == &
                    global_struct_mem_pool%class_defs(current_index)%parent_id) THEN
                    current_index = i
                    j = i
                    EXIT
                END IF
            END DO

            IF (j == 0) EXIT
        ELSE
            EXIT
        END IF
    END DO

    IF (class_size <= 0_8) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Class size is not positive for CLASS array"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    total_elems = PRODUCT(INT(dims_local(1:dim_count), KIND=8))
    IF (total_elems <= 0_8) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Total element count for CLASS array is not positive"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    total_size = total_elems * class_size
    aligned_size = ((total_size + IF_SMEM_ALIGN_SIZE - 1_8) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE

    ! Check regular memory sufficiency (evict via LRU if needed)
    IF (aligned_size > global_struct_mem_pool%free_mem) THEN
        CALL evict_lru_blocks(aligned_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%status_code = IF_STATUS_SMEM_MEM_INSUFF
            WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory for CLASS array (required ", &
                aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END IF

    ! Find a free block matching required size
    CALL find_free_block(aligned_size, free_block_id, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        CALL log_error("StructMemPool", "Failed to find free block in alloc_class_array: "//TRIM(status%message))
        RETURN
    END IF

    ! Initialize new memory block properties
    CALL get_timestamp(timestamp)
    new_block = StructMemBlockType()
    new_block%var_name = TRIM(var_name)
    new_block%data_type = IF_DATA_TYPE_CLASS
    new_block%dims = dims_local
    new_block%char_len = 0
    new_block%device_id = global_struct_mem_pool%bound_device_id
    new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
    new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
    new_block%used_size = aligned_size
    new_block%is_used = .TRUE.
    new_block%is_locked = .FALSE.
    new_block%is_unified = .FALSE.
    new_block%class_id = class_id
    new_block%struct_id = 0
    new_block%subarray_id = 0
    new_block%alloc_time = TRIM(timestamp)
    new_block%last_access_time = TRIM(timestamp)

    global_struct_mem_pool%mem_blocks(free_block_id) = new_block
    global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
    global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
    global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1

    block_id = free_block_id

    ! Register variable as CLASS in symbol table
    CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_CLASS, IF_STORAGE_TYPE_STRUCTURED, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        CALL log_error("StructMemPool", "Failed to register CLASS array variable: "//TRIM(status%message))
        RETURN
    END IF

    ! Create structured metadata entry for this CLASS array
    CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_CLASS, dims_local, class_size, &
                            .FALSE., class_meta, class_meta_status)
    IF (class_meta_status%status_code == IF_STATUS_OK) THEN
        global_struct_mem_pool%mem_blocks(block_id)%data_id = TRIM(class_meta%data_id)
    ELSE
        CALL log_warn("StructMemPool", "Failed to create class array metadata: "//TRIM(class_meta_status%message))
        global_struct_mem_pool%mem_blocks(block_id)%data_id = TRIM(var_name)
    END IF

    ! Zero-initialize the entire CLASS array memory region
    IF (aligned_size > 0_8) THEN
        start_offset = global_struct_mem_pool%mem_blocks(block_id)%mem_addr
        end_offset   = start_offset + aligned_size - 1_8

        IF (global_struct_mem_pool%mem_blocks(block_id)%is_unified) THEN
            IF (.NOT. ALLOCATED(unified_buffer)) THEN
                status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
                status%message = "Unified backing buffer not allocated for CLASS array"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF

            DO idx = start_offset + 1_8, end_offset + 1_8
                unified_buffer(idx) = 0
            END DO
        ELSE
            IF (.NOT. ALLOCATED(pool_buffer)) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Pool backing buffer not allocated for CLASS array"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF

            DO idx = start_offset + 1_8, end_offset + 1_8
                pool_buffer(idx) = 0
            END DO
        END IF
    END IF

    CALL log_info("StructMemPool", &
        "Allocated CLASS array: var='"//TRIM(var_name)//"', type='"//TRIM(class_name)//&
        "', dims="//TRIM(get_dims_string(dims_local))//", elem_size="//TRIM(INT_TO_STR8(class_size))//&
        " bytes, total_size="//TRIM(INT_TO_STR8(aligned_size))//" bytes")

    status%status_code = IF_STATUS_OK
    status%message = "CLASS array allocated successfully"

END SUBROUTINE alloc_class_array

SUBROUTINE alloc_dp1d(var_name, dim1, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension validity (dim1 must be positive)
    IF (dim1 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0)') "1D dimension must be positive (dim1=", dim1, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (DP = 8 bytes per element)
    req_size = INT(dim1, KIND=8) * 8
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_DP, [dim1,0,0,0], 0, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_DP
        new_block%dims = [dim1, 0, 0, 0]
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table (skip internal cache-only blocks)
        IF (LEN_TRIM(var_name) > 0) THEN
            IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
                CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_DP, IF_STORAGE_TYPE_STRUCTURED, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
                END IF
            END IF
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated DP1D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "DP1D array allocated successfully"
    
END SUBROUTINE alloc_dp1d

SUBROUTINE alloc_dp2d(var_name, dim1, dim2, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension validity (both dims must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0)') "2D dims must be positive (dim1=", &
            dim1, ", dim2=", dim2, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (DP = 8 bytes per element)
    req_size = INT(dim1 * dim2, KIND=8) * 8
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_DP, [dim1,dim2,0,0], 0, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_DP
        new_block%dims = [dim1, dim2, 0, 0]
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table (skip internal cache-only blocks)
        IF (LEN_TRIM(var_name) > 0) THEN
            IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
                CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_DP, IF_STORAGE_TYPE_STRUCTURED, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
                END IF
            END IF
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated DP2D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//&
        "  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "DP2D array allocated successfully"
    
END SUBROUTINE alloc_dp2d

SUBROUTINE alloc_dp3d(var_name, dim1, dim2, dim3, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension validity (all dims must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "3D dims must be positive (dim1=", &
            dim1, ", dim2=", dim2, ", dim3=", dim3, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (DP = 8 bytes per element)
    req_size = INT(dim1 * dim2 * dim3, KIND=8) * 8
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_DP, [dim1,dim2,dim3,0], 0, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_DP
        new_block%dims = [dim1, dim2, dim3, 0]
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table (skip internal cache-only blocks)
        IF (LEN_TRIM(var_name) > 0) THEN
            IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
                CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_DP, IF_STORAGE_TYPE_STRUCTURED, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
                END IF
            END IF
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated DP3D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//"  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "DP3D array allocated successfully"
    
END SUBROUTINE alloc_dp3d

SUBROUTINE alloc_dp4d(var_name, dim1, dim2, dim3, dim4, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3, dim4
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension validity (all dims must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0 .OR. dim4 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0)') "4D dims must be positive (dim1=", &
            dim1, ", dim2=", dim2, ", dim3=", dim3, ", dim4=", dim4, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (DP = 8 bytes per element)
    req_size = INT(dim1 * dim2 * dim3 * dim4, KIND=8) * 8
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_DP, [dim1,dim2,dim3,dim4], 0, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_DP
        new_block%dims = [dim1, dim2, dim3, dim4]
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table (skip internal cache-only blocks)
        IF (LEN_TRIM(var_name) > 0) THEN
            IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
                CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_DP, IF_STORAGE_TYPE_STRUCTURED, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
                END IF
            END IF
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated DP4D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//"x"//TRIM(INT_TO_STR(dim4))//"  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "DP4D array allocated successfully"
    
END SUBROUTINE alloc_dp4d

SUBROUTINE alloc_int1d(var_name, dim1, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Check 2: Validate dimension validity
    IF (dim1 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0)') "1D dimension must be positive (dim1=", dim1, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (INT = 4 bytes per element)
    req_size = INT(dim1, KIND=8) * 4
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_INT, [dim1,0,0,0], 0, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check if regular memory is sufficient (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching the required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_INT
        new_block%dims = [dim1, 0, 0, 0]
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table (skip if name is empty or internal cache-only blocks)
        IF (LEN_TRIM(var_name) > 0) THEN
            IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
                CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_INT, IF_STORAGE_TYPE_STRUCTURED, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
                END IF
            END IF
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated INT1D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "INT1D array allocated successfully"
    
END SUBROUTINE alloc_int1d

SUBROUTINE alloc_int2d(var_name, dim1, dim2, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Check 2: Validate dimension validity (both dims must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0)') "2D dims must be positive (dim1=", dim1, ", dim2=", dim2, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (INT = 4 bytes per element)
    req_size = INT(dim1 * dim2, KIND=8) * 4
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_INT, [dim1,dim2,0,0], 0, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check if regular memory is sufficient (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching the required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_INT
        new_block%dims = [dim1, dim2, 0, 0]
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table (skip if name is empty or internal cache-only blocks)
        IF (LEN_TRIM(var_name) > 0) THEN
            IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
                CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_INT, IF_STORAGE_TYPE_STRUCTURED, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
                END IF
            END IF
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated INT2D: var='"//TRIM(var_name)// &
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))// &
        "  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "INT2D array allocated successfully"
    
END SUBROUTINE alloc_int2d

SUBROUTINE alloc_int3d(var_name, dim1, dim2, dim3, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension validity (all dims must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "3D dims must be positive (dim1=", &
            dim1, ", dim2=", dim2, ", dim3=", dim3, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (INT = 4 bytes per element)
    req_size = INT(dim1 * dim2 * dim3, KIND=8) * 4
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_INT, [dim1,dim2,dim3,0], 0, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_INT
        new_block%dims = [dim1, dim2, dim3, 0]
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table (skip if name is empty or internal cache-only blocks)
        IF (LEN_TRIM(var_name) > 0) THEN
            IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
                CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_INT, IF_STORAGE_TYPE_STRUCTURED, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
                END IF
            END IF
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated INT3D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//"  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "INT3D array allocated successfully"
    
END SUBROUTINE alloc_int3d

SUBROUTINE alloc_int4d(var_name, dim1, dim2, dim3, dim4, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3, dim4
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(KIND=8) :: req_size, aligned_size
    INTEGER(i4) :: free_block_id, io_stat
    LOGICAL :: use_unified_mem = .FALSE.
    CHARACTER(LEN=20) :: timestamp
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate dimension validity (all dims must be positive)
    IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0 .OR. dim4 <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0)') "4D dims must be positive (dim1=", &
            dim1, ", dim2=", dim2, ", dim3=", dim3, ", dim4=", dim4, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Ensure variable name uniqueness (via symbol table)
    ! Skip strict uniqueness check for internal cache variables ("__cache_" prefix)
    IF (LEN_TRIM(var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
            IF (symbol_table_exists(var_name, status)) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF
    
    ! Process optional 'use_unified' parameter
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate memory size (INT = 4 bytes per element)
    req_size = INT(dim1 * dim2 * dim3 * dim4, KIND=8) * 4
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory availability (if enabled)
    IF (use_unified_mem .AND. global_struct_mem_pool%unified_mem_enabled) THEN
        IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
            CALL log_warn("StructMemPool", "Unified memory insufficient, falling back to regular memory")
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Attempt allocation via unified memory first
    IF (use_unified_mem) THEN
        CALL allocate_unified_memory(var_name, IF_DATA_TYPE_INT, [dim1,dim2,dim3,dim4], 0, &
                                    aligned_size, block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to allocate via unified memory: "//TRIM(status%message))
            use_unified_mem = .FALSE.
        END IF
    END IF
    
    ! Fall back to regular memory if unified memory fails/disabled
    IF (.NOT. use_unified_mem) THEN
        ! Check regular memory sufficiency (evict via LRU if needed)
        IF (aligned_size > global_struct_mem_pool%free_mem) THEN
            CALL evict_lru_blocks(aligned_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_SMEM_MEM_INSUFF
                WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory (required ", &
                    aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Find a free block matching required size
        CALL find_free_block(aligned_size, free_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMemPool", "Failed to find free block: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize new memory block properties
        CALL get_timestamp(timestamp)
        new_block = StructMemBlockType()
        new_block%var_name = TRIM(var_name)
        new_block%data_type = IF_DATA_TYPE_INT
        new_block%dims = [dim1, dim2, dim3, dim4]
        new_block%device_id = global_struct_mem_pool%bound_device_id
        ! mem_addr stores byte offset into pool_buffer for this block
        new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
        new_block%used_size = aligned_size
        new_block%is_used = .TRUE.
        new_block%is_locked = .FALSE.
        new_block%is_unified = .FALSE.
        new_block%alloc_time = TRIM(timestamp)
        new_block%last_access_time = TRIM(timestamp)
        
        ! Update memory pool state with new block
        global_struct_mem_pool%mem_blocks(free_block_id) = new_block
        global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
        global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
        global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
        
        block_id = free_block_id
        
        ! Register variable to symbol table (skip if name is empty or internal cache-only blocks)
        IF (LEN_TRIM(var_name) > 0) THEN
            IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
                CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_INT, IF_STORAGE_TYPE_STRUCTURED, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
                END IF
            END IF
        END IF
    END IF
    
    ! Log successful allocation
    CALL log_info("StructMemPool", &
        "Allocated INT4D: var='"//TRIM(var_name)//&
        "', dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//"x"//TRIM(INT_TO_STR(dim4))//"  ! "//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "INT4D array allocated successfully"
    
END SUBROUTINE alloc_int4d

SUBROUTINE alloc_struct(struct_name, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: struct_name
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    INTEGER(i4) :: i, struct_id, member_count
    INTEGER(KIND=8) :: struct_size
    LOGICAL :: use_unified_mem = .FALSE.
    TYPE(StructMetaType) :: struct_meta
    TYPE(ErrorStatusType) :: meta_status
    INTEGER(i4) :: dims(IF_MAX_DIMENSIONS)
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Process optional parameters
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Find structure definition
    struct_id = 0
    DO i = 1, global_struct_mem_pool%struct_count
        IF (TRIM(global_struct_mem_pool%struct_defs(i)%name) == TRIM(struct_name)) THEN
            struct_id = i
            EXIT
        END IF
    END DO
    
    IF (struct_id == 0) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structure '", TRIM(struct_name), "' not found"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Check if structure is fully defined
    IF (.NOT. global_struct_mem_pool%struct_defs(struct_id)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,A,A)') "Structure '", TRIM(struct_name), "' is not fully defined"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Calculate structure size based on members with proper alignment
    struct_size = calculate_struct_size(struct_id, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        RETURN
    END IF
    
    ! Allocate structure memory with proper alignment
    CALL alloc_char1d(struct_name, 1, INT(struct_size, KIND=4), block_id, status, use_unified_mem)
    IF (status%status_code == IF_STATUS_OK) THEN
        ! Update memory block data type to structure
        global_struct_mem_pool%mem_blocks(block_id)%data_type = IF_DATA_TYPE_STRUCT
        global_struct_mem_pool%mem_blocks(block_id)%char_len = 0
        global_struct_mem_pool%mem_blocks(block_id)%struct_id = struct_id
        global_struct_mem_pool%mem_blocks(block_id)%class_id = 0

        ! Create structured metadata entry for this struct instance
        dims = [1, 0, 0, 0]
        CALL struct_meta_create(TRIM(struct_name), IF_DATA_TYPE_STRUCT, dims, struct_size, &
                                .FALSE., struct_meta, meta_status)
        IF (meta_status%status_code == IF_STATUS_OK) THEN
            global_struct_mem_pool%mem_blocks(block_id)%data_id = TRIM(struct_meta%data_id)
        ELSE
            CALL log_warn("StructMemPool", "Failed to create struct metadata: "//TRIM(meta_status%message))
            global_struct_mem_pool%mem_blocks(block_id)%data_id = TRIM(struct_name)
        END IF

        ! Initialize structure members
        CALL initialize_struct_memory(block_id, struct_id, status)
        
        CALL log_debug("StructMemPool", &
            "Allocated STRUCT: '"//TRIM(struct_name)//"' (size: "// &
            TRIM(INT_TO_STR8(struct_size))//" bytes, block: "// &
            TRIM(INT_TO_STR(block_id))//")")
    END IF
    
END SUBROUTINE alloc_struct

SUBROUTINE alloc_struct_array(var_name, struct_name, dims, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    CHARACTER(LEN=*), INTENT(IN) :: struct_name
    INTEGER(i4), INTENT(IN) :: dims(4)
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL,          INTENT(IN), OPTIONAL :: use_unified

    INTEGER(i4) :: i, struct_id, dim_count
    INTEGER(KIND=8) :: struct_size, total_elems, total_size, aligned_size
    LOGICAL :: use_unified_mem = .FALSE.
    TYPE(StructMetaType) :: struct_meta
    TYPE(ErrorStatusType) :: meta_status, local_status
    TYPE(StructMemBlockType) :: new_block
    INTEGER(i4) :: free_block_id
    CHARACTER(LEN=20) :: timestamp
    INTEGER(i4) :: dims_local(4)
    INTEGER(KIND=8) :: start_offset, end_offset, idx

    CALL init_error_status(status)
    block_id = 0

    ! Process optional parameters (currently STRUCT arrays do not support unified memory, fallback to regular)
    IF (PRESENT(use_unified)) THEN
        IF (use_unified) THEN
            CALL log_warn("StructMemPool", "alloc_struct_array: unified memory not supported yet, falling back to regular memory")
        END IF
    END IF

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate variable name
    IF (LEN_TRIM(var_name) == 0) THEN
        status%status_code = IF_STATUS_VAR_NAME_INVALID
        status%message = "Variable name for STRUCT array cannot be empty"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Ensure variable name uniqueness (skip internal cache variables)
    IF (.NOT. (LEN_TRIM(var_name) >= 8 .AND. var_name(1:8) == "__cache_")) THEN
        IF (symbol_table_exists(var_name, local_status)) THEN
            IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_NOT_FOUND) THEN
                status = local_status
                CALL log_error("StructMemPool", &
                    "Symbol table check failed in alloc_struct_array: "//TRIM(status%message))
                RETURN
            END IF
            IF (local_status%status_code == IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
    END IF

    ! Pre-check 3: Find structure definition
    struct_id = 0
    DO i = 1, global_struct_mem_pool%struct_count
        IF (TRIM(global_struct_mem_pool%struct_defs(i)%name) == TRIM(struct_name)) THEN
            struct_id = i
            EXIT
        END IF
    END DO

    IF (struct_id == 0) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structure '", TRIM(struct_name), "' not found"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%struct_defs(struct_id)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,A,A)') "Structure '", TRIM(struct_name), "' is not fully defined"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Validate dimensions (1-4D, all positive)
    dims_local = dims
    dim_count = 0
    DO i = 1, 4
        IF (dims_local(i) > 0) THEN
            dim_count = dim_count + 1
        ELSE
            EXIT
        END IF
    END DO

    IF (dim_count <= 0 .OR. dim_count > 4) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        status%message = "STRUCT array must have 1-4 positive dimensions"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    DO i = 1, dim_count
        IF (dims_local(i) <= 0) THEN
            status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
            status%message = "STRUCT array dimensions must be positive"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END DO

    ! Calculate per-element structure size and total array size
    struct_size = calculate_struct_size(struct_id, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        RETURN
    END IF

    total_elems = PRODUCT(INT(dims_local(1:dim_count), KIND=8))
    IF (total_elems <= 0_8) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Total element count for STRUCT array is not positive"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    total_size = total_elems * struct_size
    aligned_size = ((total_size + IF_SMEM_ALIGN_SIZE - 1_8) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE

    ! Check regular memory sufficiency (evict via LRU if needed)
    IF (aligned_size > global_struct_mem_pool%free_mem) THEN
        CALL evict_lru_blocks(aligned_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%status_code = IF_STATUS_SMEM_MEM_INSUFF
            WRITE(status%message, '(A,I0,A,I0)') "Insufficient memory for STRUCT array (required ", &
                aligned_size, ", free ", global_struct_mem_pool%free_mem, ")"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END IF

    ! Find a free block matching required size
    CALL find_free_block(aligned_size, free_block_id, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        CALL log_error("StructMemPool", "Failed to find free block in alloc_struct_array: "//TRIM(status%message))
        RETURN
    END IF

    ! Initialize new memory block properties
    CALL get_timestamp(timestamp)
    new_block = StructMemBlockType()
    new_block%var_name = TRIM(var_name)
    new_block%data_type = IF_DATA_TYPE_STRUCT
    new_block%dims = dims_local
    new_block%char_len = 0
    new_block%device_id = global_struct_mem_pool%bound_device_id
    new_block%mem_addr = (free_block_id - 1) * global_struct_mem_pool%mem_blocks(free_block_id)%block_size
    new_block%block_size = global_struct_mem_pool%mem_blocks(free_block_id)%block_size
    new_block%used_size = aligned_size
    new_block%is_used = .TRUE.
    new_block%is_locked = .FALSE.
    new_block%is_unified = .FALSE.
    new_block%struct_id = struct_id
    new_block%class_id = 0
    new_block%subarray_id = 0
    new_block%alloc_time = TRIM(timestamp)
    new_block%last_access_time = TRIM(timestamp)

    global_struct_mem_pool%mem_blocks(free_block_id) = new_block
    global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
    global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
    global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1

    block_id = free_block_id

    ! Register variable as STRUCT in symbol table
    CALL register_variable(TRIM(var_name), TRIM(var_name), IF_DATA_TYPE_STRUCT, IF_STORAGE_TYPE_STRUCTURED, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        CALL log_error("StructMemPool", "Failed to register STRUCT array variable: "//TRIM(status%message))
        RETURN
    END IF

    ! Create structured metadata entry for this STRUCT array
    CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_STRUCT, dims_local, struct_size, &
                            .FALSE., struct_meta, meta_status)
    IF (meta_status%status_code == IF_STATUS_OK) THEN
        global_struct_mem_pool%mem_blocks(block_id)%data_id = TRIM(struct_meta%data_id)
    ELSE
        CALL log_warn("StructMemPool", "Failed to create struct array metadata: "//TRIM(meta_status%message))
        global_struct_mem_pool%mem_blocks(block_id)%data_id = TRIM(var_name)
    END IF

    ! Zero-initialize the entire STRUCT array memory region
    IF (aligned_size > 0_8) THEN
        start_offset = global_struct_mem_pool%mem_blocks(block_id)%mem_addr
        end_offset   = start_offset + aligned_size - 1_8

        IF (global_struct_mem_pool%mem_blocks(block_id)%is_unified) THEN
            IF (.NOT. ALLOCATED(unified_buffer)) THEN
                status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
                status%message = "Unified backing buffer not allocated for STRUCT array"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF

            DO idx = start_offset + 1_8, end_offset + 1_8
                unified_buffer(idx) = 0
            END DO
        ELSE
            IF (.NOT. ALLOCATED(pool_buffer)) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Pool backing buffer not allocated for STRUCT array"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF

            DO idx = start_offset + 1_8, end_offset + 1_8
                pool_buffer(idx) = 0
            END DO
        END IF
    END IF

    CALL log_info("StructMemPool", &
        "Allocated STRUCT array: var='"//TRIM(var_name)//"', type='"//TRIM(struct_name)//&
        "', dims="//TRIM(get_dims_string(dims_local))//", elem_size="//TRIM(INT_TO_STR8(struct_size))//&
        " bytes, total_size="//TRIM(INT_TO_STR8(aligned_size))//" bytes")

    status%status_code = IF_STATUS_OK
    status%message = "STRUCT array allocated successfully"

END SUBROUTINE alloc_struct_array

SUBROUTINE alloc_struct_mem(var_name, data_type, dims, char_len, block_id, status, use_unified)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: data_type
    INTEGER(i4), INTENT(IN) :: dims(4)
    INTEGER, INTENT(IN), OPTIONAL :: char_len
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: use_unified
    
    INTEGER(i4) :: dim_count, local_char_len = 0
    LOGICAL :: use_unified_mem = .FALSE.
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Process optional parameters
    IF (PRESENT(char_len)) local_char_len = char_len
    IF (PRESENT(use_unified)) use_unified_mem = use_unified
    
    ! Calculate dimension count
    dim_count = 0
    DO
        IF (dim_count >= 4) EXIT
        IF (dims(dim_count+1) <= 0) EXIT
        dim_count = dim_count + 1
    END DO
    
    ! Call corresponding allocation subroutine by data type and dimension count
    SELECT CASE(data_type)
        CASE(IF_DATA_TYPE_INT)
            SELECT CASE(dim_count)
                CASE(1)
                    CALL alloc_int1d(var_name, dims(1), block_id, status, use_unified_mem)
                CASE(2)
                    CALL alloc_int2d(var_name, dims(1), dims(2), block_id, status, use_unified_mem)
                CASE(3)
                    CALL alloc_int3d(var_name, dims(1), dims(2), dims(3), block_id, status, use_unified_mem)
                CASE(4)
                    CALL alloc_int4d(var_name, dims(1), dims(2), dims(3), dims(4), block_id, status, use_unified_mem)
                CASE DEFAULT
                    status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
                    status%message = "Unsupported dimension count for INT type"
                    CALL log_error("StructMemPool", TRIM(status%message))
            END SELECT
            
        CASE(IF_DATA_TYPE_DP)
            SELECT CASE(dim_count)
                CASE(1)
                    CALL alloc_dp1d(var_name, dims(1), block_id, status, use_unified_mem)
                CASE(2)
                    CALL alloc_dp2d(var_name, dims(1), dims(2), block_id, status, use_unified_mem)
                CASE(3)
                    CALL alloc_dp3d(var_name, dims(1), dims(2), dims(3), block_id, status, use_unified_mem)
                CASE(4)
                    CALL alloc_dp4d(var_name, dims(1), dims(2), dims(3), dims(4), block_id, status, use_unified_mem)
                CASE DEFAULT
                    status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
                    status%message = "Unsupported dimension count for DP type"
                    CALL log_error("StructMemPool", TRIM(status%message))
            END SELECT
            
        CASE(IF_DATA_TYPE_CHAR)
            IF (local_char_len <= 0) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Character length must be specified for CHAR type"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
            
            SELECT CASE(dim_count)
                CASE(1)
                    CALL alloc_char1d(var_name, dims(1), local_char_len, block_id, status, use_unified_mem)
                CASE(2)
                    CALL alloc_char2d(var_name, dims(1), dims(2), local_char_len, block_id, status, use_unified_mem)
                CASE(3)
                    CALL alloc_char3d(var_name, dims(1), dims(2), dims(3), local_char_len, block_id, status, use_unified_mem)
                CASE(4)
                    CALL alloc_char4d(var_name, dims(1), dims(2), dims(3), dims(4), &
                        local_char_len, block_id, status, use_unified_mem)
                CASE DEFAULT
                    status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
                    status%message = "Unsupported dimension count for CHAR type"
                    CALL log_error("StructMemPool", TRIM(status%message))
            END SELECT
            
        CASE DEFAULT
            status%status_code = IF_STATUS_TYPE_MISMATCH
            status%message = "Unsupported data type for structured memory allocation"
            CALL log_error("StructMemPool", TRIM(status%message))
    END SELECT
    
END SUBROUTINE alloc_struct_mem

SUBROUTINE allocate_unified_memory(var_name, data_type, dims, char_len, aligned_size, block_id, status)
    CHARACTER(LEN=*), INTENT(IN) :: var_name
    INTEGER(i4), INTENT(IN) :: data_type
    INTEGER(i4), INTENT(IN) :: dims(4)
    INTEGER(i4), INTENT(IN) :: char_len
    INTEGER(KIND=8), INTENT(IN) :: aligned_size
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: new_block
    INTEGER(i4) :: free_block_id, io_stat
    CHARACTER(LEN=20) :: timestamp
    CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id
    
    CALL init_error_status(status)
    block_id = 0
    
    ! Generate data ID
    WRITE(data_id, '(A,"_",I0)') TRIM(var_name), global_struct_mem_pool%alloc_count + 1
    
    ! Register unified memory subarray
    CALL register_struct_subarray(TRIM(data_id), data_type, dims, char_len, &
                                 "Unified memory allocation", free_block_id, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        RETURN
    END IF
    
    ! Find free block
    CALL find_free_block(aligned_size, block_id, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        RETURN
    END IF
    
    ! Initialize memory block
    CALL get_timestamp(timestamp)
    new_block = StructMemBlockType()
    new_block%var_name = TRIM(var_name)
    new_block%data_id = TRIM(data_id)
    new_block%data_type = data_type
    new_block%dims = dims
    new_block%char_len = char_len
    new_block%device_id = global_struct_mem_pool%bound_device_id
    ! mem_addr stores byte offset into unified_buffer for this subarray
    new_block%mem_addr = global_struct_mem_pool%unified_subarrays(free_block_id)%offset
    new_block%block_size = aligned_size
    new_block%used_size = aligned_size
    new_block%is_used = .TRUE.
    new_block%is_locked = .FALSE.
    new_block%is_unified = .TRUE.
    new_block%subarray_id = free_block_id
    new_block%alloc_time = TRIM(timestamp)
    new_block%last_access_time = TRIM(timestamp)
    
    ! Update memory block
    global_struct_mem_pool%mem_blocks(block_id) = new_block
    global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks + 1
    global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem - aligned_size
    global_struct_mem_pool%alloc_count = global_struct_mem_pool%alloc_count + 1
    
    ! Register variable to symbol table
    CALL register_variable(TRIM(var_name), TRIM(data_id), data_type, IF_STORAGE_TYPE_STRUCTURED, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        CALL log_warn("StructMemPool", "Failed to register variable: "//TRIM(status%message))
    END IF
    
    CALL log_info("StructMemPool", &
        "Allocated via unified memory: var='"//TRIM(var_name)//&
        "', dims="//TRIM(get_dims_string(dims))//"  ! "//&
        TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    
END SUBROUTINE allocate_unified_memory

FUNCTION calculate_struct_size(struct_id, status) RESULT(struct_size)
    INTEGER(i4), INTENT(IN) :: struct_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(KIND=8) :: struct_size
    
    INTEGER(i4) :: i
    INTEGER(KIND=8) :: member_size, current_offset
    
    CALL init_error_status(status)
    struct_size = 0
    current_offset = 0
    
    ! Calculate size based on all members with proper alignment
    DO i = 1, global_struct_mem_pool%struct_defs(struct_id)%member_count
        ! Calculate member size based on its type and dimensions
        SELECT CASE(global_struct_mem_pool%struct_defs(struct_id)%members(i)%data_type)
            CASE(IF_DATA_TYPE_INT)
                member_size = 4  ! 4 bytes for INTEGER
            CASE(IF_DATA_TYPE_DP)
                member_size = 8  ! 8 bytes for DOUBLE PRECISION
            CASE(IF_DATA_TYPE_CHAR)
                member_size = global_struct_mem_pool%struct_defs(struct_id)%members(i)%char_len
            CASE DEFAULT
                member_size = 1  ! Default to 1 byte for other types
        END SELECT
        
        ! Apply alignment (64 bytes)
        current_offset = ((current_offset + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
        
        ! Update member offset
        global_struct_mem_pool%struct_defs(struct_id)%members(i)%offset = current_offset
        
        ! Update current offset and total size
        current_offset = current_offset + member_size
        struct_size = current_offset
    END DO
    
    ! Apply final alignment to the entire structure
    struct_size = ((struct_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Update structure size in definition
    global_struct_mem_pool%struct_defs(struct_id)%size = struct_size
    
    CALL log_debug("StructMemPool", &
        "Calculated struct size: '"// &
        TRIM(global_struct_mem_pool%struct_defs(struct_id)%name)//"' = "// &
        TRIM(INT_TO_STR8(struct_size))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "Structure size calculated successfully"
    
END FUNCTION calculate_struct_size

SUBROUTINE check_struct_block_device_mem(block_id, is_sufficient, status)
    INTEGER(i4), INTENT(IN) :: block_id
    LOGICAL, INTENT(OUT) :: is_sufficient
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    TYPE(ErrorStatusType) :: dev_status
    INTEGER(i4) :: storage_type

    CALL init_error_status(status)
    is_sufficient = .FALSE.

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(block_id)

    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Require STRUCT/CLASS block with non-empty data_id
    IF (mem_block%struct_id == 0 .AND. mem_block%class_id == 0) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not STRUCT/CLASS block"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (LEN_TRIM(mem_block%data_id) == 0) THEN
        status%status_code = IF_STATUS_DATA_ID_EMPTY
        WRITE(status%message, '(A,I0,A)') "Data ID empty for memory block ", block_id, ""
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    storage_type = IF_STORAGE_TYPE_STRUCTURED

    CALL log_debug("StructMemPool", &
        "Checking device memory for block "//TRIM(INT_TO_STR(block_id))//&
        ", data_id='"//TRIM(mem_block%data_id)//"', device="//&
        TRIM(INT_TO_STR(global_struct_mem_pool%bound_device_id)))

    CALL check_device_mem_suff(global_struct_mem_pool%bound_device_id, &
        TRIM(mem_block%data_id), storage_type, is_sufficient, dev_status)

    IF (dev_status%status_code == IF_STATUS_OK .AND. is_sufficient) THEN
        status%status_code = IF_STATUS_OK
        status%message = "Device memory sufficient for structured block"
        CALL log_info("StructMemPool", &
            "Device memory sufficient for block "//TRIM(INT_TO_STR(block_id))//&
            " (data_id='"//TRIM(mem_block%data_id)//"') on device "//&
            TRIM(INT_TO_STR(global_struct_mem_pool%bound_device_id)))
    ELSE
        is_sufficient = .FALSE.
        status%status_code = IF_STATUS_SMEM_MEM_INSUFF
        status%message = "Device memory check failed for structured block"
        CALL log_warn("StructMemPool", &
            "Device memory check failed for block "//TRIM(INT_TO_STR(block_id))//&
            " (data_id='"//TRIM(mem_block%data_id)//"'): "//TRIM(dev_status%message))
    END IF

END SUBROUTINE check_struct_block_device_mem

SUBROUTINE check_struct_block_device_mem_on_device(block_id, device_id, is_sufficient, status)
    INTEGER(i4), INTENT(IN) :: block_id
    INTEGER(i4), INTENT(IN) :: device_id
    LOGICAL, INTENT(OUT) :: is_sufficient
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    TYPE(ErrorStatusType) :: dev_status
    INTEGER(i4) :: storage_type

    CALL init_error_status(status)
    is_sufficient = .FALSE.

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(block_id)

    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Require STRUCT/CLASS block with non-empty data_id
    IF (mem_block%struct_id == 0 .AND. mem_block%class_id == 0) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not STRUCT/CLASS block"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (LEN_TRIM(mem_block%data_id) == 0) THEN
        status%status_code = IF_STATUS_DATA_ID_EMPTY
        WRITE(status%message, '(A,I0,A)') "Data ID empty for memory block ", block_id, ""
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    storage_type = IF_STORAGE_TYPE_STRUCTURED

    CALL log_debug("StructMemPool", &
        "Checking device memory for block "//TRIM(INT_TO_STR(block_id))//&
        ", data_id='"//TRIM(mem_block%data_id)//"', device="//TRIM(INT_TO_STR(device_id)))

    CALL check_device_mem_suff(device_id, TRIM(mem_block%data_id), storage_type, is_sufficient, dev_status)

    IF (dev_status%status_code == IF_STATUS_OK .AND. is_sufficient) THEN
        status%status_code = IF_STATUS_OK
        status%message = "Device memory sufficient for structured block"
        CALL log_info("StructMemPool", &
            "Device memory sufficient for block "//TRIM(INT_TO_STR(block_id))//&
            " (data_id='"//TRIM(mem_block%data_id)//"') on device "//&
            TRIM(INT_TO_STR(device_id)))
    ELSE
        is_sufficient = .FALSE.
        status%status_code = IF_STATUS_SMEM_MEM_INSUFF
        status%message = "Device memory check failed for structured block"
        CALL log_warn("StructMemPool", &
            "Device memory check failed for block "//TRIM(INT_TO_STR(block_id))//&
            " (data_id='"//TRIM(mem_block%data_id)//"') on device "//&
            TRIM(INT_TO_STR(device_id))//": "//TRIM(dev_status%message))
    END IF

END SUBROUTINE check_struct_block_device_mem_on_device

    SUBROUTINE compute_member_size(member, elem_size, elem_count, total_size)
        TYPE(StructMemberType), INTENT(IN) :: member
        INTEGER(KIND=8), INTENT(OUT) :: elem_size, elem_count, total_size
        INTEGER(i4) :: k

        SELECT CASE(member%data_type)
            CASE (IF_DATA_TYPE_INT)
                elem_size = 4_8
            CASE (IF_DATA_TYPE_DP)
                elem_size = 8_8
            CASE (IF_DATA_TYPE_CHAR)
                elem_size = INT(member%char_len, KIND=8)
            CASE DEFAULT
                elem_size = 1_8
        END SELECT

        elem_count = 1_8
        DO k = 1, IF_MAX_DIMENSIONS
            IF (member%dims(k) > 0) THEN
                elem_count = elem_count * INT(member%dims(k), KIND=8)
            END IF
        END DO

        total_size = elem_size * elem_count
    END SUBROUTINE compute_member_size

SUBROUTINE create_struct_unified_mem(pool_name, pool_size, status)
    CHARACTER(LEN=*), INTENT(IN) :: pool_name
    INTEGER(KIND=8), INTENT(IN) :: pool_size
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(ErrorStatusType) :: dev_status
    INTEGER(i4) :: io_stat
    INTEGER(KIND=8) :: total_mem, used_mem, free_mem
    
    CALL init_error_status(status)
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Whether unified memory already exists
    IF (LEN_TRIM(global_struct_mem_pool%unified_mem_id) > 0) THEN
        status%status_code = IF_STATUS_EXISTS
        status%message = "Unified memory pool already exists"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Validate memory size
    IF (pool_size < IF_MIN_SMEM_SIZE) THEN
        status%status_code = IF_STATUS_MEM_ERROR
        WRITE(status%message, '(A,I0,A,I0)') "Unified memory too small (minimum ", &
            IF_MIN_SMEM_SIZE, " bytes), got ", pool_size
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Check device memory sufficiency
    CALL query_device_memory(global_struct_mem_pool%bound_device_id, total_mem, used_mem, free_mem, dev_status)
    IF (dev_status%status_code /= IF_STATUS_OK) THEN
        status%status_code = IF_STATUS_DEV_MEM_INSUFF
        status%message = "Failed to query device memory: "//TRIM(dev_status%message)
    ELSE IF (free_mem < pool_size) THEN
        status%status_code = IF_STATUS_DEV_MEM_INSUFF
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Device memory insufficient for unified memory: free=", &
            free_mem, " bytes, required=", pool_size, " bytes"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Simulate unified memory creation (actual needs device-specific API)
    global_struct_mem_pool%unified_mem_id = TRIM(pool_name)
    global_struct_mem_pool%unified_mem_size = pool_size
    global_struct_mem_pool%unified_mem_used = 0
    global_struct_mem_pool%unified_mem_enabled = .TRUE.
    
    ! Initialize unified subarrays array
    IF (ALLOCATED(global_struct_mem_pool%unified_subarrays)) THEN
        DEALLOCATE(global_struct_mem_pool%unified_subarrays, STAT=io_stat)
    END IF
    
    ALLOCATE(global_struct_mem_pool%unified_subarrays(IF_MAX_UNIFIED_SUBARRAYS), STAT=io_stat)
    IF (io_stat /= 0) THEN
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "Failed to allocate unified subarrays array"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    CALL log_info("StructMemPool", &
        "Created structured unified memory pool: '"//TRIM(pool_name)// & 
		"' ("//TRIM(INT_TO_STR(INT(pool_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "Structured unified memory created successfully"
    
END SUBROUTINE create_struct_unified_mem

SUBROUTINE dealloc_struct_mem(block_id, status)
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(ErrorStatusType) :: dev_status
    
    CALL init_error_status(status)
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. global_struct_mem_pool%mem_blocks(block_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Free unified memory subarray (if applicable)
    IF (global_struct_mem_pool%mem_blocks(block_id)%is_unified .AND. &
        global_struct_mem_pool%mem_blocks(block_id)%subarray_id > 0) THEN
        IF (global_struct_mem_pool%mem_blocks(block_id)%subarray_id <= IF_MAX_UNIFIED_SUBARRAYS) THEN
            global_struct_mem_pool%unified_subarrays(global_struct_mem_pool%mem_blocks(block_id)%subarray_id)%is_used = .FALSE.
            global_struct_mem_pool%unified_mem_used = global_struct_mem_pool%unified_mem_used - &
                                                       global_struct_mem_pool%mem_blocks(block_id)%used_size
        END IF
    END IF
    
    ! Unregister variable from symbol table
    IF (LEN_TRIM(global_struct_mem_pool%mem_blocks(block_id)%var_name) > 0) THEN
        IF (.NOT. (LEN_TRIM(global_struct_mem_pool%mem_blocks(block_id)%var_name) >= 8 .AND. &
                   global_struct_mem_pool%mem_blocks(block_id)%var_name(1:8) == "__cache_")) THEN
            CALL unregister_variable(TRIM(global_struct_mem_pool%mem_blocks(block_id)%var_name), dev_status)
            IF (dev_status%status_code /= IF_STATUS_OK .AND. dev_status%status_code /= IF_STATUS_NOT_FOUND) THEN
                CALL log_warn("StructMemPool", "Failed to unregister variable: "//&
                    TRIM(global_struct_mem_pool%mem_blocks(block_id)%var_name))
            END IF
        END IF
    END IF
    
    ! Delete metadata
    IF (LEN_TRIM(global_struct_mem_pool%mem_blocks(block_id)%data_id) > 0) THEN
        CALL struct_meta_delete(TRIM(global_struct_mem_pool%mem_blocks(block_id)%data_id), dev_status)
        IF (dev_status%status_code /= IF_STATUS_OK .AND. dev_status%status_code /= IF_STATUS_NOT_FOUND) THEN
            CALL log_warn("StructMemPool", "Failed to delete metadata: "//&
                TRIM(global_struct_mem_pool%mem_blocks(block_id)%data_id))
        END IF
    END IF
    
    ! Reset memory block state
    global_struct_mem_pool%free_mem = global_struct_mem_pool%free_mem + &
                                    global_struct_mem_pool%mem_blocks(block_id)%used_size
    global_struct_mem_pool%used_blocks = global_struct_mem_pool%used_blocks - 1
    global_struct_mem_pool%free_count = global_struct_mem_pool%free_count + 1
    
    global_struct_mem_pool%mem_blocks(block_id)%is_used = .FALSE.
    global_struct_mem_pool%mem_blocks(block_id)%is_locked = .FALSE.
    global_struct_mem_pool%mem_blocks(block_id)%is_unified = .FALSE.
    global_struct_mem_pool%mem_blocks(block_id)%subarray_id = 0
    global_struct_mem_pool%mem_blocks(block_id)%struct_id = 0
    global_struct_mem_pool%mem_blocks(block_id)%class_id = 0
    global_struct_mem_pool%mem_blocks(block_id)%var_name = ""
    global_struct_mem_pool%mem_blocks(block_id)%data_id = ""
    global_struct_mem_pool%mem_blocks(block_id)%mem_addr = 0
    global_struct_mem_pool%mem_blocks(block_id)%lru_count = 0
    
    CALL log_info("StructMemPool", &
        "Freed memory block "//TRIM(INT_TO_STR(block_id))//&
        " (size: "//TRIM(INT_TO_STR8(global_struct_mem_pool%mem_blocks(block_id)%used_size))//" bytes)")
    
    status%status_code = IF_STATUS_OK
    status%message = "Structured memory freed successfully"
    
END SUBROUTINE dealloc_struct_mem

    SUBROUTINE destroy_struct_mem_pool(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: i, io_stat
        TYPE(ErrorStatusType) :: dev_status
        
        CALL init_error_status(status)
        
        ! Check if not initialized
        IF (.NOT. global_struct_mem_pool%initialized) THEN
            status%status_code = IF_STATUS_SMEM_NOT_INIT
            status%message = "Structured memory pool not initialized"
            CALL log_warn("StructMemPool", TRIM(status%message))
            RETURN
        END IF
        
        ! Free all used memory blocks (simulation: actual needs device memory free interface)
        DO i = 1, global_struct_mem_pool%max_blocks
            IF (global_struct_mem_pool%mem_blocks(i)%is_used) THEN
                ! Free unified memory subarray (if needed)
                IF (global_struct_mem_pool%mem_blocks(i)%is_unified .AND. &
                    global_struct_mem_pool%mem_blocks(i)%subarray_id > 0) THEN
                    global_struct_mem_pool%unified_subarrays(global_struct_mem_pool%mem_blocks(i)%subarray_id)%is_used = .FALSE.
                    global_struct_mem_pool%unified_mem_used = global_struct_mem_pool%unified_mem_used - &
                                                               global_struct_mem_pool%mem_blocks(i)%used_size
                END IF
                
                ! Unregister variable from symbol table
                IF (LEN_TRIM(global_struct_mem_pool%mem_blocks(i)%var_name) > 0) THEN
                    CALL unregister_variable(TRIM(global_struct_mem_pool%mem_blocks(i)%var_name), dev_status)
                    IF (dev_status%status_code /= IF_STATUS_OK .AND. dev_status%status_code /= IF_STATUS_NOT_FOUND) THEN
                        CALL log_warn("StructMemPool", "Failed to unregister variable: "//&
                            TRIM(global_struct_mem_pool%mem_blocks(i)%var_name))
                    END IF
                END IF
                
                ! Reset memory block status
                global_struct_mem_pool%mem_blocks(i)%mem_addr = 0
            END IF
        END DO

        ! Free backing buffers
        IF (ALLOCATED(pool_buffer)) THEN
            DEALLOCATE(pool_buffer, STAT=io_stat)
            pool_base_cptr = C_NULL_PTR
        END IF
        IF (ALLOCATED(unified_buffer)) THEN
            DEALLOCATE(unified_buffer, STAT=io_stat)
            unified_base_cptr = C_NULL_PTR
        END IF

        ! Free definition arrays and unified subarrays
        IF (ALLOCATED(global_struct_mem_pool%unified_subarrays)) THEN
            DEALLOCATE(global_struct_mem_pool%unified_subarrays, STAT=io_stat)
        END IF
        IF (ALLOCATED(global_struct_mem_pool%class_defs)) THEN
            DEALLOCATE(global_struct_mem_pool%class_defs, STAT=io_stat)
        END IF
        IF (ALLOCATED(global_struct_mem_pool%struct_defs)) THEN
            DEALLOCATE(global_struct_mem_pool%struct_defs, STAT=io_stat)
        END IF
        IF (ALLOCATED(global_struct_mem_pool%mem_blocks)) THEN
            DEALLOCATE(global_struct_mem_pool%mem_blocks, STAT=io_stat)
        END IF
        IF (ALLOCATED(global_struct_mem_pool%device_buffer_maps)) THEN
            DEALLOCATE(global_struct_mem_pool%device_buffer_maps, STAT=io_stat)
        END IF

        ! Reset pool state
        global_struct_mem_pool%initialized = .FALSE.
        global_struct_mem_pool%bound_device_id = 1
        global_struct_mem_pool%max_blocks = 0
        global_struct_mem_pool%used_blocks = 0
        global_struct_mem_pool%total_mem = 0_8
        global_struct_mem_pool%free_mem = 0_8
        global_struct_mem_pool%alloc_count = 0
        global_struct_mem_pool%free_count = 0
        global_struct_mem_pool%lru_evict_count = 0
        global_struct_mem_pool%expand_count = 0
        global_struct_mem_pool%struct_count = 0
        global_struct_mem_pool%class_count = 0
        global_struct_mem_pool%unified_mem_enabled = .FALSE.
        global_struct_mem_pool%unified_mem_id = ""
        global_struct_mem_pool%unified_mem_size = 0_8
        global_struct_mem_pool%unified_mem_used = 0_8

        CALL log_info("StructMemPool", "Destroyed structured memory pool")
        status%status_code = IF_STATUS_OK
        status%message = "Structured memory pool destroyed successfully"

    END SUBROUTINE destroy_struct_mem_pool

SUBROUTINE evict_lru_blocks(required_size, status)
    INTEGER(KIND=8), INTENT(IN) :: required_size
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, evict_block_id, evict_count
    INTEGER(KIND=8) :: evict_mem, total_evicted
    INTEGER, ALLOCATABLE :: lru_list(:)
    
    CALL init_error_status(status)
    
    ! Count evictable blocks (used + not locked)
    evict_count = 0
    DO i = 1, global_struct_mem_pool%max_blocks
        IF (global_struct_mem_pool%mem_blocks(i)%is_used .AND. .NOT. &
            global_struct_mem_pool%mem_blocks(i)%is_locked) THEN
            evict_count = evict_count + 1
        END IF
    END DO
    
    IF (evict_count == 0) THEN
        status%status_code = IF_STATUS_SMEM_LRU_ERR
        status%message = "No evictable blocks available (all are locked)"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Allocate LRU list
    ALLOCATE(lru_list(evict_count), STAT=i)
    IF (i /= 0) THEN
        status%status_code = IF_STATUS_MEM_ERROR
        status%message = "Failed to allocate LRU list"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Populate LRU list (used + not locked blocks)
    evict_count = 0
    DO i = 1, global_struct_mem_pool%max_blocks
        IF (global_struct_mem_pool%mem_blocks(i)%is_used .AND. .NOT. &
            global_struct_mem_pool%mem_blocks(i)%is_locked) THEN
            evict_count = evict_count + 1
            lru_list(evict_count) = i
        END IF
    END DO
    
    ! Sort LRU list (ascending by lru_count)
    CALL sort_lru_list(lru_list, evict_count)
    
    ! Execute eviction
    total_evicted = 0
    DO i = 1, evict_count
        evict_block_id = lru_list(i)
        evict_mem = global_struct_mem_pool%mem_blocks(evict_block_id)%used_size
        
        ! Free memory block
        CALL dealloc_struct_mem(evict_block_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            DEALLOCATE(lru_list)
            RETURN
        END IF
        
        total_evicted = total_evicted + evict_mem
        global_struct_mem_pool%lru_evict_count = global_struct_mem_pool%lru_evict_count + 1
        
        ! Check if required memory is satisfied
        IF (total_evicted >= required_size) THEN
            EXIT
        END IF
    END DO
    
    DEALLOCATE(lru_list)
    
    IF (total_evicted < required_size) THEN
        status%status_code = IF_STATUS_SMEM_MEM_INSUFF
        WRITE(status%message, '(A,I0,A,I0)') "LRU eviction insufficient (evicted ", &
            total_evicted, ", required ", required_size, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    CALL log_info("StructMemPool", &
        "LRU evicted "//TRIM(INT_TO_STR(i))//" blocks, freed "//&
        TRIM(INT_TO_STR8(total_evicted))//" bytes")
    
    status%status_code = IF_STATUS_OK
    
END SUBROUTINE evict_lru_blocks

SUBROUTINE finalize_class_def(class_id, status)
    INTEGER(i4), INTENT(IN) :: class_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i
    INTEGER(KIND=8) :: class_size, member_size, current_offset

    CALL init_error_status(status)

    ! Pre-check: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Validate class ID range
    IF (class_id <= 0 .OR. class_id > global_struct_mem_pool%class_count) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Invalid class ID (must be 1-", &
            global_struct_mem_pool%class_count, "), got ", class_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Require at least one member before finalizing
    IF (global_struct_mem_pool%class_defs(class_id)%member_count <= 0) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Cannot finalize class without members"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    class_size = 0_8
    current_offset = 0_8

    ! Calculate size based on all members with proper alignment (same as struct)
    DO i = 1, global_struct_mem_pool%class_defs(class_id)%member_count
        SELECT CASE(global_struct_mem_pool%class_defs(class_id)%members(i)%data_type)
            CASE(IF_DATA_TYPE_INT)
                member_size = 4
            CASE(IF_DATA_TYPE_DP)
                member_size = 8
            CASE(IF_DATA_TYPE_CHAR)
                member_size = global_struct_mem_pool%class_defs(class_id)%members(i)%char_len
            CASE DEFAULT
                member_size = 1
        END SELECT

        current_offset = ((current_offset + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE

        global_struct_mem_pool%class_defs(class_id)%members(i)%offset = current_offset

        current_offset = current_offset + member_size
        class_size = current_offset
    END DO

    class_size = ((class_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE

    global_struct_mem_pool%class_defs(class_id)%size = class_size
    global_struct_mem_pool%class_defs(class_id)%is_complete = .TRUE.

    CALL log_info("StructMemPool", &
        "Finalized class definition: '"//TRIM(global_struct_mem_pool%class_defs(class_id)%name)// &
        "' (ID="//TRIM(INT_TO_STR(class_id))//", size="//TRIM(INT_TO_STR8(class_size))//" bytes)")

    status%status_code = IF_STATUS_OK
    status%message = "Class definition finalized successfully"

END SUBROUTINE finalize_class_def

SUBROUTINE finalize_struct_def(struct_id, status)
    INTEGER(i4), INTENT(IN) :: struct_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(KIND=8) :: struct_size

    CALL init_error_status(status)

    ! Pre-check: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Validate struct ID range
    IF (struct_id <= 0 .OR. struct_id > global_struct_mem_pool%struct_count) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Invalid struct ID (must be 1-", &
            global_struct_mem_pool%struct_count, "), got ", struct_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Require at least one member before finalizing
    IF (global_struct_mem_pool%struct_defs(struct_id)%member_count <= 0) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Cannot finalize struct without members"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Calculate structure size and member offsets
    struct_size = calculate_struct_size(struct_id, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
        RETURN
    END IF

    global_struct_mem_pool%struct_defs(struct_id)%is_complete = .TRUE.

    CALL log_info("StructMemPool", &
        "Finalized struct definition: '"//TRIM(global_struct_mem_pool%struct_defs(struct_id)%name)// &
        "' (ID="//TRIM(INT_TO_STR(struct_id))//", size="//TRIM(INT_TO_STR8(struct_size))//" bytes)")

    status%status_code = IF_STATUS_OK
    status%message = "Struct definition finalized successfully"

END SUBROUTINE finalize_struct_def

SUBROUTINE find_free_block(required_size, block_id, status)
    INTEGER(KIND=8), INTENT(IN) :: required_size
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    INTEGER(KIND=8) :: min_size, curr_diff
    
    CALL init_error_status(status)
    block_id = 0
    min_size = HUGE(required_size)
    
    ! Find first suitable free block (first-fit algorithm)
    DO i = 1, global_struct_mem_pool%max_blocks
        IF (.NOT. global_struct_mem_pool%mem_blocks(i)%is_used) THEN
            ! Uninitialized block (block_size=0): Set to required size directly
            IF (global_struct_mem_pool%mem_blocks(i)%block_size == 0) THEN
                global_struct_mem_pool%mem_blocks(i)%block_size = required_size
            END IF
            
            IF (global_struct_mem_pool%mem_blocks(i)%block_size >= required_size) THEN
                block_id = i
                EXIT
            END IF
        END IF
    END DO
    
    ! If first-fit fails: Try best-fit algorithm
    IF (block_id == 0) THEN
        DO i = 1, global_struct_mem_pool%max_blocks
            IF (.NOT. global_struct_mem_pool%mem_blocks(i)%is_used) THEN
                IF (global_struct_mem_pool%mem_blocks(i)%block_size == 0) THEN
                    global_struct_mem_pool%mem_blocks(i)%block_size = required_size
                END IF
                
                IF (global_struct_mem_pool%mem_blocks(i)%block_size >= required_size) THEN
                    curr_diff = global_struct_mem_pool%mem_blocks(i)%block_size - required_size
                    IF (curr_diff < min_size) THEN
                        min_size = curr_diff
                        block_id = i
                    END IF
                END IF
            END IF
        END DO
    END IF
    
    IF (block_id == 0) THEN
        status%status_code = IF_STATUS_SMEM_MEM_INSUFF
        status%message = "No suitable free block found"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    status%status_code = IF_STATUS_OK
    
END SUBROUTINE find_free_block

SUBROUTINE get_char1d_ptr(mem_block_id, ptr, dim1, char_len, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    CHARACTER(LEN=*), POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: dim1, char_len
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    char_len = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_CHAR) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected CHAR, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) /= 0 .OR. &
        target_block%dims(3) /= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A)') "Dimension mismatch: expected 1D, got ", target_block%dims(1)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1])
    char_len = target_block%char_len
    
    CALL log_debug("StructMemPool", &
        "Retrieved CHAR1D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//", len="//TRIM(INT_TO_STR(char_len)))
    
    status%status_code = IF_STATUS_OK
    status%message = "CHAR1D pointer retrieved successfully"
    
END SUBROUTINE get_char1d_ptr

SUBROUTINE get_char2d_ptr(mem_block_id, ptr, dim1, dim2, char_len, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    CHARACTER(LEN=*), POINTER, INTENT(OUT) :: ptr(:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, char_len
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    char_len = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_CHAR) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected CHAR, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) /= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A)') "Dimension mismatch: expected 2D, got ", &
            target_block%dims(1), "x", target_block%dims(2)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2])
    char_len = target_block%char_len
    
    CALL log_debug("StructMemPool", &
        "Retrieved CHAR2D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//&
        ", len="//TRIM(INT_TO_STR(char_len)))
    
    status%status_code = IF_STATUS_OK
    status%message = "CHAR2D pointer retrieved successfully"
    
END SUBROUTINE get_char2d_ptr

SUBROUTINE get_char3d_ptr(mem_block_id, ptr, dim1, dim2, dim3, char_len, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    CHARACTER(LEN=*), POINTER, INTENT(OUT) :: ptr(:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3, char_len
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    char_len = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_CHAR) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected CHAR, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) <= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A)') "Dimension mismatch: expected 3D, got ", &
            target_block%dims(1), "x", target_block%dims(2), "x", target_block%dims(3)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    dim3 = target_block%dims(3)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3])
    char_len = target_block%char_len
    
    CALL log_debug("StructMemPool", &
        "Retrieved CHAR3D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//", len="//TRIM(INT_TO_STR(char_len)))
    
    status%status_code = IF_STATUS_OK
    status%message = "CHAR3D pointer retrieved successfully"
    
END SUBROUTINE get_char3d_ptr

SUBROUTINE get_char4d_ptr(mem_block_id, ptr, dim1, dim2, dim3, dim4, char_len, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    CHARACTER(LEN=*), POINTER, INTENT(OUT) :: ptr(:,:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3, dim4, char_len
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    dim4 = 0
    char_len = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_CHAR) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected CHAR, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) <= 0 .OR. target_block%dims(4) <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0,A)') "Dimension mismatch: expected 4D, got ", &
            target_block%dims(1), "x", target_block%dims(2), "x", target_block%dims(3), "x", &
            target_block%dims(4)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    dim3 = target_block%dims(3)
    dim4 = target_block%dims(4)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3, dim4])
    char_len = target_block%char_len
    
    CALL log_debug("StructMemPool", &
        "Retrieved CHAR4D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//"x"//TRIM(INT_TO_STR(dim4))//&
        ", len="//TRIM(INT_TO_STR(char_len)))
    
    status%status_code = IF_STATUS_OK
    status%message = "CHAR4D pointer retrieved successfully"
    
END SUBROUTINE get_char4d_ptr

SUBROUTINE get_class_block_id_by_data_id(data_id, block_id, status)
    CHARACTER(LEN=*), INTENT(IN) :: data_id
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    block_id = 0

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Data ID cannot be empty
    IF (LEN_TRIM(data_id) == 0) THEN
        status%status_code = IF_STATUS_DATA_ID_EMPTY
        status%message = "Data ID cannot be empty in get_class_block_id_by_data_id"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Linear scan over memory blocks to find matching CLASS block
    DO i = 1, global_struct_mem_pool%max_blocks
        IF (.NOT. global_struct_mem_pool%mem_blocks(i)%is_used) CYCLE
        IF (global_struct_mem_pool%mem_blocks(i)%data_type /= IF_DATA_TYPE_CLASS) CYCLE
        IF (TRIM(global_struct_mem_pool%mem_blocks(i)%data_id) /= TRIM(data_id)) CYCLE

        block_id = i
        CALL log_debug("StructMemPool", &
            "Resolved CLASS block by data_id='"//TRIM(data_id)//"': block_id="//TRIM(INT_TO_STR(block_id)))
        status%status_code = IF_STATUS_OK
        RETURN
    END DO

    status%status_code = IF_STATUS_SMEM_NOT_FOUND
    WRITE(status%message, '(A,A,A)') "CLASS block for data ID '", TRIM(data_id), "' not found"
    CALL log_warn("StructMemPool", TRIM(status%message))
END SUBROUTINE get_class_block_id_by_data_id

SUBROUTINE get_class_element_ptr(mem_block_id, elem_index, ptr, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    INTEGER(i4), INTENT(IN) :: elem_index
    CLASS(*), POINTER, INTENT(OUT) :: ptr
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    TYPE(C_PTR) :: elem_cptr
    INTEGER(KIND=8) :: base_offset, elem_offset
    INTEGER(i4) :: class_id_local, i, j, current_index, dim_count
    INTEGER(KIND=8) :: class_size, total_elems
    CHARACTER(LEN=20) :: access_time

    CALL init_error_status(status)
    NULLIFY(ptr)

    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (elem_index <= 0) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Element index must be positive in get_class_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(mem_block_id)

    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (mem_block%data_type /= IF_DATA_TYPE_CLASS) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected CLASS block in get_class_element_ptr"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    class_id_local = mem_block%class_id
    IF (class_id_local <= 0 .OR. class_id_local > global_struct_mem_pool%class_count) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Invalid class ID stored in memory block in get_class_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%class_defs(class_id_local)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,I0,A)') "Class definition for ID ", class_id_local, &
            " is not complete in get_class_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    class_size = 0_8
    current_index = class_id_local

    DO WHILE (current_index /= 0)
        class_size = class_size + global_struct_mem_pool%class_defs(current_index)%size

        IF (global_struct_mem_pool%class_defs(current_index)%parent_id /= 0) THEN
            j = 0
            DO i = 1, global_struct_mem_pool%class_count
                IF (global_struct_mem_pool%class_defs(i)%class_id == &
                    global_struct_mem_pool%class_defs(current_index)%parent_id) THEN
                    current_index = i
                    j = i
                    EXIT
                END IF
            END DO

            IF (j == 0) EXIT
        ELSE
            EXIT
        END IF
    END DO

    IF (class_size <= 0_8) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Class size is not positive in get_class_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    dim_count = 0
    total_elems = 1_8
    DO i = 1, 4
        IF (mem_block%dims(i) > 0) THEN
            dim_count = dim_count + 1
            total_elems = total_elems * INT(mem_block%dims(i), KIND=8)
        END IF
    END DO

    IF (total_elems <= 0_8) THEN
        total_elems = 1_8
    END IF

    IF (INT(elem_index, KIND=8) > total_elems) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0)') &
            "Element index out of range in get_class_element_ptr: idx=", elem_index, &
            ", total_elems=", total_elems
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    elem_offset = (INT(elem_index, KIND=8) - 1_8) * class_size
    IF (elem_offset + class_size > mem_block%used_size) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Element offset exceeds used_size in get_class_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_offset = mem_block%mem_addr + elem_offset

    IF (mem_block%is_unified) THEN
        IF (.NOT. ALLOCATED(unified_buffer)) THEN
            status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
            status%message = "Unified backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        elem_cptr = C_LOC(unified_buffer(base_offset + 1_8))
    ELSE
        IF (.NOT. ALLOCATED(pool_buffer)) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Pool backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        elem_cptr = C_LOC(pool_buffer(base_offset + 1_8))
    END IF

    BLOCK
        TYPE(CptrStorageType), POINTER :: tmp
        CALL C_F_POINTER(elem_cptr, tmp)
        ptr => tmp
    END BLOCK

    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = access_time
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1

    status%status_code = IF_STATUS_OK
    status%message = "CLASS element pointer retrieved successfully"

END SUBROUTINE get_class_element_ptr

SUBROUTINE get_class_ptr(mem_block_id, ptr, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    CLASS(*), POINTER, INTENT(OUT) :: ptr
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    INTEGER(i4) :: class_id_local, i, j, current_index
    INTEGER(KIND=8) :: class_size
    CHARACTER(LEN=20) :: access_time

    CALL init_error_status(status)
    NULLIFY(ptr)

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(mem_block_id)

    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Validate data type is CLASS
    IF (mem_block%data_type /= IF_DATA_TYPE_CLASS) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected CLASS block"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 5: Validate class ID stored in block
    class_id_local = mem_block%class_id
    IF (class_id_local <= 0 .OR. class_id_local > global_struct_mem_pool%class_count) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Invalid class ID stored in memory block"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%class_defs(class_id_local)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,I0,A)') "Class definition for ID ", class_id_local, " is not complete"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Recompute total class size including all inherited members (same logic as initialization)
    class_size = 0_8
    current_index = class_id_local

    DO WHILE (current_index /= 0)
        class_size = class_size + global_struct_mem_pool%class_defs(current_index)%size

        IF (global_struct_mem_pool%class_defs(current_index)%parent_id /= 0) THEN
            j = 0
            DO i = 1, global_struct_mem_pool%class_count
                IF (global_struct_mem_pool%class_defs(i)%class_id == &
                    global_struct_mem_pool%class_defs(current_index)%parent_id) THEN
                    current_index = i
                    j = i
                    EXIT
                END IF
            END DO

            IF (j == 0) EXIT
        ELSE
            EXIT
        END IF
    END DO

    IF (class_size <= 0_8) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Class size is not positive"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (mem_block%block_size < class_size) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Memory block size is smaller than class definition size"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_offset = mem_block%mem_addr

    IF (mem_block%is_unified) THEN
        IF (.NOT. ALLOCATED(unified_buffer)) THEN
            status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
            status%message = "Unified backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        base_cptr = C_LOC(unified_buffer(base_offset + 1_8))
    ELSE
        IF (.NOT. ALLOCATED(pool_buffer)) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Pool backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        base_cptr = C_LOC(pool_buffer(base_offset + 1_8))
    END IF

    ! Map backing buffer bytes to unlimited polymorphic pointer (C_F_POINTER workaround)
    BLOCK
        TYPE(CptrStorageType), POINTER :: tmp
        CALL C_F_POINTER(base_cptr, tmp)
        ptr => tmp
    END BLOCK

    ! Update access statistics
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = access_time
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1

    status%status_code = IF_STATUS_OK
    status%message = "CLASS pointer retrieved successfully from backing buffer"

END SUBROUTINE get_class_ptr

FUNCTION get_dims_string(dims) RESULT(dims_str)
    INTEGER(i4), INTENT(IN) :: dims(4)
    CHARACTER(LEN=30) :: dims_str
    CHARACTER(LEN=20) :: temp
    
    dims_str = ""
    IF (dims(1) > 0) THEN
        WRITE(temp, '(I0)') dims(1)
        dims_str = TRIM(temp)
        IF (dims(2) > 0) THEN
            WRITE(temp, '(A,I0)') "x", dims(2)
            dims_str = TRIM(dims_str)//TRIM(temp)
            IF (dims(3) > 0) THEN
                WRITE(temp, '(A,I0)') "x", dims(3)
                dims_str = TRIM(dims_str)//TRIM(temp)
                IF (dims(4) > 0) THEN
                    WRITE(temp, '(A,I0)') "x", dims(4)
                    dims_str = TRIM(dims_str)//TRIM(temp)
                END IF
            END IF
        END IF
    END IF
    
    IF (LEN_TRIM(dims_str) == 0) THEN
        dims_str = "0"
    END IF
    
END FUNCTION get_dims_string

SUBROUTINE get_dp1d_ptr(mem_block_id, ptr, dim1, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    DOUBLE PRECISION, POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: dim1
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_DP) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected DP, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) /= 0 .OR. &
        target_block%dims(3) /= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A)') "Dimension mismatch: expected 1D, got ", target_block%dims(1)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1])
    
    CALL log_debug("StructMemPool", &
        "Retrieved DP1D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1)))
    
    status%status_code = IF_STATUS_OK
    status%message = "DP1D pointer retrieved successfully"
    
END SUBROUTINE get_dp1d_ptr

SUBROUTINE get_dp2d_ptr(mem_block_id, ptr, dim1, dim2, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    DOUBLE PRECISION, POINTER, INTENT(OUT) :: ptr(:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_DP) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected DP, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) /= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A)') "Dimension mismatch: expected 2D, got ", &
            target_block%dims(1), "x", target_block%dims(2)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2])
    
    CALL log_debug("StructMemPool", &
        "Retrieved DP2D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2)))
    
    status%status_code = IF_STATUS_OK
    status%message = "DP2D pointer retrieved successfully"
    
END SUBROUTINE get_dp2d_ptr

SUBROUTINE get_dp3d_ptr(mem_block_id, ptr, dim1, dim2, dim3, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    DOUBLE PRECISION, POINTER, INTENT(OUT) :: ptr(:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_DP) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected DP, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) <= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A)') "Dimension mismatch: expected 3D, got ", &
            target_block%dims(1), "x", target_block%dims(2), "x", target_block%dims(3)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    dim3 = target_block%dims(3)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3])
    
    CALL log_debug("StructMemPool", &
        "Retrieved DP3D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3)))
    
    status%status_code = IF_STATUS_OK
    status%message = "DP3D pointer retrieved successfully"
    
END SUBROUTINE get_dp3d_ptr

SUBROUTINE get_dp4d_ptr(mem_block_id, ptr, dim1, dim2, dim3, dim4, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    DOUBLE PRECISION, POINTER, INTENT(OUT) :: ptr(:,:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3, dim4
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    dim4 = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_DP) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected DP, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) <= 0 .OR. target_block%dims(4) <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0,A)') "Dimension mismatch: expected 4D, got ", &
            target_block%dims(1), "x", target_block%dims(2), "x", target_block%dims(3), "x", &
            target_block%dims(4)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    dim3 = target_block%dims(3)
    dim4 = target_block%dims(4)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3, dim4])
    
    CALL log_debug("StructMemPool", &
        "Retrieved DP4D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//"x"//TRIM(INT_TO_STR(dim4)))
    
    status%status_code = IF_STATUS_OK
    status%message = "DP4D pointer retrieved successfully"
    
END SUBROUTINE get_dp4d_ptr

SUBROUTINE get_int1d_ptr(mem_block_id, ptr, dim1, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    INTEGER, POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: dim1
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset

    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)

    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_INT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected INT, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) /= 0 .OR. &
        target_block%dims(3) /= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A)') "Dimension mismatch: expected 1D, got ", target_block%dims(1)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1

    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1])

    CALL log_debug("StructMemPool", &
        "Retrieved INT1D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1)))

    status%status_code = IF_STATUS_OK
    status%message = "INT1D pointer retrieved successfully"

END SUBROUTINE get_int1d_ptr

SUBROUTINE get_int2d_ptr(mem_block_id, ptr, dim1, dim2, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    INTEGER, POINTER, INTENT(OUT) :: ptr(:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_INT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected INT, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) /= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A)') "Dimension mismatch: expected 2D, got ", &
            target_block%dims(1), "x", target_block%dims(2)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2])
    
    CALL log_debug("StructMemPool", &
        "Retrieved INT2D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2)))
    
    status%status_code = IF_STATUS_OK
    status%message = "INT2D pointer retrieved successfully"
    
END SUBROUTINE get_int2d_ptr

SUBROUTINE get_int3d_ptr(mem_block_id, ptr, dim1, dim2, dim3, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    INTEGER, POINTER, INTENT(OUT) :: ptr(:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_INT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected INT, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) <= 0 .OR. target_block%dims(4) /= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A)') "Dimension mismatch: expected 3D, got ", &
            target_block%dims(1), "x", target_block%dims(2), "x", target_block%dims(3)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    dim3 = target_block%dims(3)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3])
    
    CALL log_debug("StructMemPool", &
        "Retrieved INT3D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3)))
    
    status%status_code = IF_STATUS_OK
    status%message = "INT3D pointer retrieved successfully"
    
END SUBROUTINE get_int3d_ptr

SUBROUTINE get_int4d_ptr(mem_block_id, ptr, dim1, dim2, dim3, dim4, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    INTEGER, POINTER, INTENT(OUT) :: ptr(:,:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3, dim4
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(StructMemBlockType) :: target_block
    CHARACTER(LEN=20) :: access_time
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    dim4 = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    target_block = global_struct_mem_pool%mem_blocks(mem_block_id)
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. target_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Validate data type match
    IF (target_block%data_type /= IF_DATA_TYPE_INT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected INT, got other type"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate dimension match
    IF (target_block%dims(1) <= 0 .OR. target_block%dims(2) <= 0 .OR. &
        target_block%dims(3) <= 0 .OR. target_block%dims(4) <= 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0,A)') "Dimension mismatch: expected 4D, got ", &
            target_block%dims(1), "x", target_block%dims(2), "x", target_block%dims(3), "x", &
            target_block%dims(4)
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Update access time and LRU counter
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = TRIM(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1
    
    ! Real pointer retrieval using CPU backing buffer
    dim1 = target_block%dims(1)
    dim2 = target_block%dims(2)
    dim3 = target_block%dims(3)
    dim4 = target_block%dims(4)
    base_offset = target_block%mem_addr

    IF (target_block%is_unified) THEN
        base_cptr = C_LOC(unified_buffer(base_offset + 1))
    ELSE
        base_cptr = C_LOC(pool_buffer(base_offset + 1))
    END IF

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3, dim4])
    
    CALL log_debug("StructMemPool", &
        "Retrieved INT4D pointer: block "//TRIM(INT_TO_STR(mem_block_id))//&
        ", dims="//TRIM(INT_TO_STR(dim1))//"x"//TRIM(INT_TO_STR(dim2))//"x"//&
        TRIM(INT_TO_STR(dim3))//"x"//TRIM(INT_TO_STR(dim4)))
    
    status%status_code = IF_STATUS_OK
    status%message = "INT4D pointer retrieved successfully"
    
END SUBROUTINE get_int4d_ptr

SUBROUTINE get_struct_block_base_cptr(block_id, base_cptr, status)
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(C_PTR), INTENT(OUT) :: base_cptr
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    INTEGER(KIND=8) :: base_offset

    CALL init_error_status(status)
    base_cptr = C_NULL_PTR

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized in get_struct_block_base_cptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(block_id)

    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not in use in get_struct_block_base_cptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_offset = mem_block%mem_addr

    IF (mem_block%is_unified) THEN
        IF (.NOT. ALLOCATED(unified_buffer)) THEN
            status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
            status%message = "Unified backing buffer not allocated in get_struct_block_base_cptr"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
        base_cptr = C_LOC(unified_buffer(base_offset + 1_8))
    ELSE
        IF (.NOT. ALLOCATED(pool_buffer)) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Pool backing buffer not allocated in get_struct_block_base_cptr"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
        base_cptr = C_LOC(pool_buffer(base_offset + 1_8))
    END IF

    status%status_code = IF_STATUS_OK
    status%message = "Base C_PTR for structured/class block retrieved successfully"
END SUBROUTINE get_struct_block_base_cptr

SUBROUTINE get_struct_block_id_by_data_id(data_id, block_id, status)
    CHARACTER(LEN=*), INTENT(IN) :: data_id
    INTEGER(i4), INTENT(OUT) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    block_id = 0

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Data ID cannot be empty
    IF (LEN_TRIM(data_id) == 0) THEN
        status%status_code = IF_STATUS_DATA_ID_EMPTY
        status%message = "Data ID cannot be empty in get_struct_block_id_by_data_id"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Linear scan over memory blocks to find matching STRUCT block
    DO i = 1, global_struct_mem_pool%max_blocks
        IF (.NOT. global_struct_mem_pool%mem_blocks(i)%is_used) CYCLE
        IF (global_struct_mem_pool%mem_blocks(i)%data_type /= IF_DATA_TYPE_STRUCT) CYCLE
        IF (TRIM(global_struct_mem_pool%mem_blocks(i)%data_id) /= TRIM(data_id)) CYCLE

        block_id = i
        CALL log_debug("StructMemPool", &
            "Resolved STRUCT block by data_id='"//TRIM(data_id)//"': block_id="//TRIM(INT_TO_STR(block_id)))
        status%status_code = IF_STATUS_OK
        RETURN
    END DO

    status%status_code = IF_STATUS_SMEM_NOT_FOUND
    WRITE(status%message, '(A,A,A)') "STRUCT block for data ID '", TRIM(data_id), "' not found"
    CALL log_warn("StructMemPool", TRIM(status%message))
END SUBROUTINE get_struct_block_id_by_data_id

SUBROUTINE get_struct_element_cptr(mem_block_id, elem_index, cptr, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    INTEGER(i4), INTENT(IN) :: elem_index
    TYPE(C_PTR), INTENT(OUT) :: cptr
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    INTEGER(KIND=8) :: base_offset, elem_offset
    INTEGER(i4) :: struct_id_local, i, dim_count
    INTEGER(KIND=8) :: struct_size, total_elems
    CHARACTER(LEN=20) :: access_time

    CALL init_error_status(status)
    cptr = C_NULL_PTR

    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (elem_index <= 0) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Element index must be positive in get_struct_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(mem_block_id)

    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (mem_block%data_type /= IF_DATA_TYPE_STRUCT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected STRUCT block in get_struct_element_ptr"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    struct_id_local = mem_block%struct_id
    IF (struct_id_local <= 0 .OR. struct_id_local > global_struct_mem_pool%struct_count) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Invalid struct ID stored in memory block in get_struct_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%struct_defs(struct_id_local)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,I0,A)') "Structure definition for ID ", struct_id_local, &
            " is not complete in get_struct_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    struct_size = global_struct_mem_pool%struct_defs(struct_id_local)%size
    IF (struct_size <= 0_8) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Structure size is not positive in get_struct_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    dim_count = 0
    total_elems = 1_8
    DO i = 1, 4
        IF (mem_block%dims(i) > 0) THEN
            dim_count = dim_count + 1
            total_elems = total_elems * INT(mem_block%dims(i), KIND=8)
        END IF
    END DO

    IF (total_elems <= 0_8) THEN
        total_elems = 1_8
    END IF

    IF (INT(elem_index, KIND=8) > total_elems) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0)') &
            "Element index out of range in get_struct_element_ptr: idx=", elem_index, &
            ", total_elems=", total_elems
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    elem_offset = (INT(elem_index, KIND=8) - 1_8) * struct_size
    IF (elem_offset + struct_size > mem_block%used_size) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Element offset exceeds used_size in get_struct_element_ptr"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_offset = mem_block%mem_addr + elem_offset

    IF (mem_block%is_unified) THEN
        IF (.NOT. ALLOCATED(unified_buffer)) THEN
            status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
            status%message = "Unified backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        cptr = C_LOC(unified_buffer(base_offset + 1_8))
    ELSE
        IF (.NOT. ALLOCATED(pool_buffer)) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Pool backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        cptr = C_LOC(pool_buffer(base_offset + 1_8))
    END IF

    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = access_time
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1

    status%status_code = IF_STATUS_OK
    status%message = "STRUCT element C_PTR retrieved successfully"

END SUBROUTINE get_struct_element_cptr

SUBROUTINE get_struct_element_ptr(mem_block_id, elem_index, ptr, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    INTEGER(i4), INTENT(IN) :: elem_index
    CLASS(*), POINTER, INTENT(OUT) :: ptr
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(C_PTR) :: elem_cptr
    TYPE(ErrorStatusType) :: local_status

    CALL init_error_status(status)
    NULLIFY(ptr)

    CALL get_struct_element_cptr(mem_block_id, elem_index, elem_cptr, local_status)
    IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        RETURN
    END IF

    BLOCK
        TYPE(CptrStorageType), POINTER :: tmp
        CALL C_F_POINTER(elem_cptr, tmp)
        ptr => tmp
    END BLOCK

    status%status_code = IF_STATUS_OK
    status%message = "STRUCT element pointer retrieved successfully"
END SUBROUTINE get_struct_element_ptr

SUBROUTINE get_struct_mem_pool_stats(stats, status)
    TYPE(StructMemPoolType), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Pre-check: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Return statistics (protective copy)
    stats = global_struct_mem_pool
    
    CALL log_debug("StructMemPool", "Retrieved memory pool statistics")
    
    status%status_code = IF_STATUS_OK
    status%message = "Memory pool statistics retrieved successfully"
    
END SUBROUTINE get_struct_mem_pool_stats

SUBROUTINE get_struct_ptr(mem_block_id, ptr, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    CLASS(*), POINTER, INTENT(OUT) :: ptr
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    INTEGER(i4) :: struct_id_local
    INTEGER(KIND=8) :: struct_size
    CHARACTER(LEN=20) :: access_time

    CALL init_error_status(status)
    NULLIFY(ptr)

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate memory block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(mem_block_id)

    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Validate data type is STRUCT
    IF (mem_block%data_type /= IF_DATA_TYPE_STRUCT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected STRUCT block"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 5: Validate struct ID stored in block
    struct_id_local = mem_block%struct_id
    IF (struct_id_local <= 0 .OR. struct_id_local > global_struct_mem_pool%struct_count) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Invalid struct ID stored in memory block"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%struct_defs(struct_id_local)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,I0,A)') "Structure definition for ID ", struct_id_local, " is not complete"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    struct_size = global_struct_mem_pool%struct_defs(struct_id_local)%size
    IF (struct_size <= 0_8) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Structure size is not positive"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (mem_block%block_size < struct_size) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Memory block size is smaller than structure definition size"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_offset = mem_block%mem_addr

    IF (mem_block%is_unified) THEN
        IF (.NOT. ALLOCATED(unified_buffer)) THEN
            status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
            status%message = "Unified backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        base_cptr = C_LOC(unified_buffer(base_offset + 1_8))
    ELSE
        IF (.NOT. ALLOCATED(pool_buffer)) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Pool backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        base_cptr = C_LOC(pool_buffer(base_offset + 1_8))
    END IF

    ! Map backing buffer bytes to unlimited polymorphic pointer (C_F_POINTER workaround)
    BLOCK
        TYPE(CptrStorageType), POINTER :: tmp
        CALL C_F_POINTER(base_cptr, tmp)
        ptr => tmp
    END BLOCK

    ! Update access statistics
    CALL get_timestamp(access_time)
    global_struct_mem_pool%mem_blocks(mem_block_id)%last_access_time = access_time
    global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count = &
        global_struct_mem_pool%mem_blocks(mem_block_id)%lru_count + 1

    status%status_code = IF_STATUS_OK
    status%message = "STRUCT pointer retrieved successfully from backing buffer"

END SUBROUTINE get_struct_ptr

SUBROUTINE get_struct_subarray_ptr_1d_char(subarray_id, ptr, dim1, char_len, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    CHARACTER(LEN=*), POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: dim1, char_len
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    char_len = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_CHAR) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimension information
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    char_len = global_struct_mem_pool%unified_subarrays(subarray_id)%char_len
    
    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset
    
    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    base_cptr = C_LOC(unified_buffer(base_offset + 1))
    
    CALL C_F_POINTER(base_cptr, ptr, [dim1])
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified CHAR1D subarray pointer retrieved successfully"
    
END SUBROUTINE get_struct_subarray_ptr_1d_char

SUBROUTINE get_struct_subarray_ptr_1d_dp(subarray_id, ptr, dim1, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    DOUBLE PRECISION, POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: dim1
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_DP) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    
    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset
    
    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    base_cptr = C_LOC(unified_buffer(base_offset + 1))
    
    CALL C_F_POINTER(base_cptr, ptr, [dim1])
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified DP1D subarray pointer retrieved successfully"
    
END SUBROUTINE get_struct_subarray_ptr_1d_dp

SUBROUTINE get_struct_subarray_ptr_1d_int(subarray_id, ptr, dim1, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    INTEGER, POINTER, INTENT(OUT) :: ptr(:)
    INTEGER(i4), INTENT(OUT) :: dim1
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_INT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)

    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset

    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_cptr = C_LOC(unified_buffer(base_offset + 1))

    CALL C_F_POINTER(base_cptr, ptr, [dim1])

    status%status_code = IF_STATUS_OK
    status%message = "Unified INT1D subarray pointer retrieved successfully"

END SUBROUTINE get_struct_subarray_ptr_1d_int

SUBROUTINE get_struct_subarray_ptr_2d_char(subarray_id, ptr, dim1, dim2, char_len, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    CHARACTER(LEN=*), POINTER, INTENT(OUT) :: ptr(:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, char_len
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    char_len = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_CHAR) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimension information
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)
    char_len = global_struct_mem_pool%unified_subarrays(subarray_id)%char_len
    
    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset
    
    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    base_cptr = C_LOC(unified_buffer(base_offset + 1))
    
    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2])
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified CHAR2D subarray pointer retrieved successfully"
    
END SUBROUTINE get_struct_subarray_ptr_2d_char

SUBROUTINE get_struct_subarray_ptr_2d_dp(subarray_id, ptr, dim1, dim2, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    DOUBLE PRECISION, POINTER, INTENT(OUT) :: ptr(:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_DP) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)
    
    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset
    
    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    base_cptr = C_LOC(unified_buffer(base_offset + 1))
    
    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2])
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified DP2D subarray pointer retrieved successfully"
    
END SUBROUTINE get_struct_subarray_ptr_2d_dp

SUBROUTINE get_struct_subarray_ptr_2d_int(subarray_id, ptr, dim1, dim2, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    INTEGER, POINTER, INTENT(OUT) :: ptr(:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_INT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)

    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset

    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_cptr = C_LOC(unified_buffer(base_offset + 1))

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2])

    status%status_code = IF_STATUS_OK
    status%message = "Unified INT2D subarray pointer retrieved successfully"

END SUBROUTINE get_struct_subarray_ptr_2d_int

SUBROUTINE get_struct_subarray_ptr_3d_char(subarray_id, ptr, dim1, dim2, dim3, char_len, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    CHARACTER(LEN=*), POINTER, INTENT(OUT) :: ptr(:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3, char_len
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    char_len = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_CHAR) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions and character length
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)
    dim3 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(3)
    char_len = global_struct_mem_pool%unified_subarrays(subarray_id)%char_len
    
    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset
    
    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    base_cptr = C_LOC(unified_buffer(base_offset + 1))
    
    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3])
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified CHAR3D subarray pointer retrieved successfully"
    
END SUBROUTINE get_struct_subarray_ptr_3d_char

SUBROUTINE get_struct_subarray_ptr_3d_dp(subarray_id, ptr, dim1, dim2, dim3, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    DOUBLE PRECISION, POINTER, INTENT(OUT) :: ptr(:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_DP) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)
    dim3 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(3)
    
    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset
    
    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    base_cptr = C_LOC(unified_buffer(base_offset + 1))
    
    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3])
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified DP3D subarray pointer retrieved successfully"
    
END SUBROUTINE get_struct_subarray_ptr_3d_dp

SUBROUTINE get_struct_subarray_ptr_3d_int(subarray_id, ptr, dim1, dim2, dim3, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    INTEGER, POINTER, INTENT(OUT) :: ptr(:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_INT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)
    dim3 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(3)

    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset

    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_cptr = C_LOC(unified_buffer(base_offset + 1))

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3])

    status%status_code = IF_STATUS_OK
    status%message = "Unified INT3D subarray pointer retrieved successfully"

END SUBROUTINE get_struct_subarray_ptr_3d_int

SUBROUTINE get_struct_subarray_ptr_4d_char(subarray_id, ptr, dim1, dim2, dim3, dim4, char_len, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    CHARACTER(LEN=*), POINTER, INTENT(OUT) :: ptr(:,:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3, dim4, char_len
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    dim4 = 0
    char_len = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_CHAR) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions and character length
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)
    dim3 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(3)
    dim4 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(4)
    char_len = global_struct_mem_pool%unified_subarrays(subarray_id)%char_len
    
    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset
    
    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    base_cptr = C_LOC(unified_buffer(base_offset + 1))
    
    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3, dim4])
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified CHAR4D subarray pointer retrieved successfully"
    
END SUBROUTINE get_struct_subarray_ptr_4d_char

SUBROUTINE get_struct_subarray_ptr_4d_dp(subarray_id, ptr, dim1, dim2, dim3, dim4, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    DOUBLE PRECISION, POINTER, INTENT(OUT) :: ptr(:,:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3, dim4
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    dim4 = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_DP) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)
    dim3 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(3)
    dim4 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(4)
    
    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset
    
    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    base_cptr = C_LOC(unified_buffer(base_offset + 1))
    
    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3, dim4])
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified DP4D subarray pointer retrieved successfully"
    
END SUBROUTINE get_struct_subarray_ptr_4d_dp

SUBROUTINE get_struct_subarray_ptr_4d_int(subarray_id, ptr, dim1, dim2, dim3, dim4, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    INTEGER, POINTER, INTENT(OUT) :: ptr(:,:,:,:)
    INTEGER(i4), INTENT(OUT) :: dim1, dim2, dim3, dim4
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(C_PTR) :: base_cptr
    INTEGER(KIND=8) :: base_offset
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dim2 = 0
    dim3 = 0
    dim4 = 0
    
    ! Pre-checks
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= IF_DATA_TYPE_INT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch for unified subarray"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimensions
    dim1 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(1)
    dim2 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(2)
    dim3 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(3)
    dim4 = global_struct_mem_pool%unified_subarrays(subarray_id)%dims(4)

    base_offset = global_struct_mem_pool%unified_subarrays(subarray_id)%offset

    IF (.NOT. ALLOCATED(unified_buffer)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified backing buffer not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    base_cptr = C_LOC(unified_buffer(base_offset + 1))

    CALL C_F_POINTER(base_cptr, ptr, [dim1, dim2, dim3, dim4])

    status%status_code = IF_STATUS_OK
    status%message = "Unified INT4D subarray pointer retrieved successfully"

END SUBROUTINE get_struct_subarray_ptr_4d_int

SUBROUTINE get_timestamp(timestamp)
    CHARACTER(LEN=*), INTENT(OUT) :: timestamp
    
    INTEGER(i4) :: values(8)
    
    CALL DATE_AND_TIME(VALUES=values)
    WRITE(timestamp, '(I4,2("-",I2.2),1X,I2.2,2(":",I2.2))') &
        values(1), values(2), values(3), values(5), values(6), values(7)
    
END SUBROUTINE get_timestamp

FUNCTION get_type_string(data_type) RESULT(type_str)
    INTEGER(i4), INTENT(IN) :: data_type
    CHARACTER(LEN=10) :: type_str
    
    SELECT CASE(data_type)
        CASE(IF_DATA_TYPE_INT)
            type_str = "INT"
        CASE(IF_DATA_TYPE_DP)
            type_str = "DP"
        CASE(IF_DATA_TYPE_CHAR)
            type_str = "CHAR"
        CASE(IF_DATA_TYPE_STRUCT)
            type_str = "STRUCT"
        CASE(IF_DATA_TYPE_CLASS)
            type_str = "CLASS"
        CASE DEFAULT
            type_str = "UNKNOWN"
    END SELECT
    
END FUNCTION get_type_string

SUBROUTINE get_unified_subarray_id_by_data_id(data_id, subarray_id, status)
    CHARACTER(LEN=*), INTENT(IN) :: data_id
    INTEGER(i4), INTENT(OUT) :: subarray_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)
    subarray_id = 0

    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. ALLOCATED(global_struct_mem_pool%unified_subarrays)) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified subarray table not allocated"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    DO i = 1, IF_MAX_UNIFIED_SUBARRAYS
        IF (global_struct_mem_pool%unified_subarrays(i)%is_used .AND. &
            TRIM(global_struct_mem_pool%unified_subarrays(i)%data_id) == TRIM(data_id)) THEN
            subarray_id = i
            status%status_code = IF_STATUS_OK
            RETURN
        END IF
    END DO

    status%status_code = IF_STATUS_SMEM_NOT_FOUND
    WRITE(status%message, '(A,A,A)') "Unified subarray for data_id '", TRIM(data_id), "' not found"
    CALL log_warn("StructMemPool", TRIM(status%message))
END SUBROUTINE get_unified_subarray_id_by_data_id

SUBROUTINE get_unified_subarray_ptr_generic(subarray_id, expected_type, expected_dims, dims_out, ptr, dim1, status)
    INTEGER(i4), INTENT(IN) :: subarray_id
    INTEGER(i4), INTENT(IN) :: expected_type
    INTEGER(i4), INTENT(IN) :: expected_dims
    INTEGER(i4), INTENT(OUT) :: dims_out(4)
    ! Use specific type pointer instead of CLASS(*) to avoid polymorphism issues
    ! This is a workaround - in a real implementation, you'd use C_F_POINTER for proper casting
    INTEGER, POINTER, INTENT(OUT) :: ptr
    INTEGER(i4), INTENT(OUT) :: dim1
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(LEN=20) :: access_time
    INTEGER(i4) :: i, dim_count
    
    CALL init_error_status(status)
    NULLIFY(ptr)
    dim1 = 0
    dims_out = [0,0,0,0]
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Whether unified memory is enabled
    IF (.NOT. global_struct_mem_pool%unified_mem_enabled .OR. &
        LEN_TRIM(global_struct_mem_pool%unified_mem_id) == 0) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified memory not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Validate subarray ID
    IF (subarray_id <= 0 .OR. subarray_id > IF_MAX_UNIFIED_SUBARRAYS) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Subarray ID must be 1-", &
            IF_MAX_UNIFIED_SUBARRAYS, ", got ", subarray_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 4: Whether subarray is in use
    IF (.NOT. global_struct_mem_pool%unified_subarrays(subarray_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Unified subarray ", subarray_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 5: Validate data type match
    IF (global_struct_mem_pool%unified_subarrays(subarray_id)%data_type /= expected_type) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        WRITE(status%message, '(A,A,A,A)') "Data type mismatch: expected ", &
            TRIM(get_type_string(expected_type)), ", got ", &
            TRIM(get_type_string(global_struct_mem_pool%unified_subarrays(subarray_id)%data_type))
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 6: Validate dimension count match
    dim_count = 0
    DO i = 1, 4
        IF (global_struct_mem_pool%unified_subarrays(subarray_id)%dims(i) > 0) THEN
            dim_count = dim_count + 1
        ELSE
            EXIT
        END IF
    END DO
    
    IF (dim_count /= expected_dims) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        WRITE(status%message, '(A,I0,A,I0)') "Dimension count mismatch: expected ", &
            expected_dims, "D, got ", dim_count, "D"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Get dimension information
    dims_out = global_struct_mem_pool%unified_subarrays(subarray_id)%dims
    dim1 = dims_out(1)
    
    ! Simulate pointer retrieval (actual needs device-specific API)
    ! In real project: Create appropriate pointer based on data type and dimensions
    
    CALL log_debug("StructMemPool", &
        "Retrieved unified subarray pointer: ID="//TRIM(INT_TO_STR(subarray_id))//&
        ", type="//TRIM(get_type_string(expected_type))//&
        ", dims="//TRIM(get_dims_string(dims_out)))
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified subarray pointer retrieved successfully"
    
END SUBROUTINE get_unified_subarray_ptr_generic

    SUBROUTINE init_struct_mem_pool(status, bound_device_id, max_blocks, total_mem, unified_mem_size)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER, INTENT(IN), OPTIONAL :: bound_device_id  ! "Optional: Bound device ID (default 1=CPU)"
        INTEGER, INTENT(IN), OPTIONAL :: max_blocks       ! "Optional: Max memory blocks (default IF_MAX_SMEM_BLOCKS)"
        INTEGER(KIND=8), INTENT(IN), OPTIONAL :: total_mem ! "Optional: Total memory (default IF_MAX_SMEM_BLOCKS*IF_DEFAULT_SMEM_BLOCK_SIZE)"
        INTEGER(KIND=8), INTENT(IN), OPTIONAL :: unified_mem_size ! "Optional: Unified mem size (default IF_DEFAULT_UNIFIED_SIZE)"
        
        INTEGER(i4) :: local_max_blocks, local_bound_device_id, io_stat
        INTEGER(KIND=8) :: local_total_mem, local_unified_size
        INTEGER(i4) :: i
        TYPE(ErrorStatusType) :: dev_status
        
        CALL init_error_status(status)
        
        ! Check if already initialized
        IF (global_struct_mem_pool%initialized) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Structured memory pool already initialized"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
        
        ! Handle bound device ID
        local_bound_device_id = 1
        IF (PRESENT(bound_device_id)) THEN
            local_bound_device_id = bound_device_id
            ! Validate device ID validity
            IF (local_bound_device_id < 1 .OR. local_bound_device_id > IF_MAX_DEVICE_COUNT) THEN
                status%status_code = IF_STATUS_DEV_TYPE_INVALID
                WRITE(status%message, '(A,I0,A,I0,A,I0)') "Invalid device ID (must be 1-", &
                    IF_MAX_DEVICE_COUNT, "), got ", local_bound_device_id
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Handle max blocks
        local_max_blocks = IF_MAX_SMEM_BLOCKS
        IF (PRESENT(max_blocks)) THEN
            local_max_blocks = max_blocks
            IF (local_max_blocks <= 0 .OR. local_max_blocks > IF_MAX_SMEM_BLOCKS) THEN
                status%status_code = IF_STATUS_INVALID
                WRITE(status%message, '(A,I0,A,I0,A,I0)') "Max blocks must be 1-", &
                    IF_MAX_SMEM_BLOCKS, ", got ", local_max_blocks
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Handle total memory
        local_total_mem = INT(local_max_blocks, KIND=8) * IF_DEFAULT_SMEM_BLOCK_SIZE
        IF (PRESENT(total_mem)) THEN
            local_total_mem = total_mem
            IF (local_total_mem < IF_MIN_SMEM_SIZE * local_max_blocks) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                WRITE(status%message, '(A,I0,A,I0)') "Total memory too small (minimum ", &
                    IF_MIN_SMEM_SIZE * local_max_blocks, " bytes), got ", local_total_mem
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Handle unified memory size
        local_unified_size = IF_DEFAULT_UNIFIED_SIZE
        IF (PRESENT(unified_mem_size)) THEN
            local_unified_size = unified_mem_size
            IF (local_unified_size < IF_MIN_SMEM_SIZE) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                WRITE(status%message, '(A,I0,A,I0)') "Unified memory too small (minimum ", &
                    IF_MIN_SMEM_SIZE, " bytes), got ", local_unified_size
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF
        
        ! Allocate memory blocks array
        ALLOCATE(global_struct_mem_pool%mem_blocks(local_max_blocks), STAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate memory blocks array"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
        
        ! Allocate structure/class definition arrays
        ALLOCATE(global_struct_mem_pool%struct_defs(10), STAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate struct definitions array"
            CALL log_error("StructMemPool", TRIM(status%message))
            DEALLOCATE(global_struct_mem_pool%mem_blocks)
            RETURN
        END IF
        
        ALLOCATE(global_struct_mem_pool%class_defs(10), STAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate class definitions array"
            CALL log_error("StructMemPool", TRIM(status%message))
            DEALLOCATE(global_struct_mem_pool%struct_defs)
            DEALLOCATE(global_struct_mem_pool%mem_blocks)
            RETURN
        END IF
        
        ! Allocate unified memory subarrays
        ALLOCATE(global_struct_mem_pool%unified_subarrays(IF_MAX_UNIFIED_SUBARRAYS), STAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate unified subarrays array"
            CALL log_error("StructMemPool", TRIM(status%message))
            DEALLOCATE(global_struct_mem_pool%class_defs)
            DEALLOCATE(global_struct_mem_pool%struct_defs)
            DEALLOCATE(global_struct_mem_pool%mem_blocks)
            RETURN
        END IF

        ! Allocate block-device buffer mapping table (one slot per block-device combination)
        ALLOCATE(global_struct_mem_pool%device_buffer_maps(local_max_blocks * IF_MAX_DEVICE_COUNT), STAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate device buffer mapping table"
            CALL log_error("StructMemPool", TRIM(status%message))
            DEALLOCATE(global_struct_mem_pool%unified_subarrays)
            DEALLOCATE(global_struct_mem_pool%class_defs)
            DEALLOCATE(global_struct_mem_pool%struct_defs)
            DEALLOCATE(global_struct_mem_pool%mem_blocks)
            RETURN
        END IF
        global_struct_mem_pool%device_buffer_map_count = 0

        ! Allocate backing buffers for structured and unified memory (CPU only)
        ALLOCATE(pool_buffer(local_total_mem), STAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate pool backing buffer"
            CALL log_error("StructMemPool", TRIM(status%message))
            DEALLOCATE(global_struct_mem_pool%unified_subarrays)
            DEALLOCATE(global_struct_mem_pool%class_defs)
            DEALLOCATE(global_struct_mem_pool%struct_defs)
            DEALLOCATE(global_struct_mem_pool%mem_blocks)
            RETURN
        END IF
        pool_base_cptr = C_LOC(pool_buffer(1))
        
        ALLOCATE(unified_buffer(local_unified_size), STAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate unified backing buffer"
            CALL log_error("StructMemPool", TRIM(status%message))
            DEALLOCATE(pool_buffer)
            DEALLOCATE(global_struct_mem_pool%unified_subarrays)
            DEALLOCATE(global_struct_mem_pool%class_defs)
            DEALLOCATE(global_struct_mem_pool%struct_defs)
            DEALLOCATE(global_struct_mem_pool%mem_blocks)
            RETURN
        END IF
        unified_base_cptr = C_LOC(unified_buffer(1))
        
        ! Initialize memory blocks
        DO i = 1, local_max_blocks
            global_struct_mem_pool%mem_blocks(i) = StructMemBlockType()
            global_struct_mem_pool%mem_blocks(i)%device_id = local_bound_device_id
            global_struct_mem_pool%mem_blocks(i)%block_size = local_total_mem / local_max_blocks
        END DO
        
        ! Initialize unified memory
        global_struct_mem_pool%unified_mem_enabled = .TRUE.
        global_struct_mem_pool%unified_mem_size = local_unified_size
        global_struct_mem_pool%unified_mem_used = 0
        global_struct_mem_pool%unified_mem_id = "IF_DEFAULT_UNIFIED_MEM"
        
        ! Initialize statistical information
        global_struct_mem_pool%initialized = .TRUE.
        global_struct_mem_pool%bound_device_id = local_bound_device_id
        global_struct_mem_pool%max_blocks = local_max_blocks
        global_struct_mem_pool%total_mem = local_total_mem
        global_struct_mem_pool%free_mem = local_total_mem
        global_struct_mem_pool%used_blocks = 0
        global_struct_mem_pool%alloc_count = 0
        global_struct_mem_pool%free_count = 0
        global_struct_mem_pool%lru_evict_count = 0
        global_struct_mem_pool%expand_count = 0
        global_struct_mem_pool%struct_count = 0
        global_struct_mem_pool%class_count = 0
        
        CALL log_info("StructMemPool", &
            "Initialized structured memory pool (bound device: "//TRIM(INT_TO_STR(local_bound_device_id))//&
            ", blocks: "//TRIM(INT_TO_STR(local_max_blocks))//&
            ", total mem: "//TRIM(INT_TO_STR(INT(local_total_mem, KIND=4)))//" bytes")
        
        status%status_code = IF_STATUS_OK
        status%message = "Structured memory pool initialized successfully"
        
    END SUBROUTINE init_struct_mem_pool

SUBROUTINE initialize_class_memory(block_id, class_id, status)
    INTEGER(i4), INTENT(IN) :: block_id
    INTEGER(i4), INTENT(IN) :: class_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    INTEGER(KIND=8) :: class_size
    INTEGER(KIND=8) :: start_offset, end_offset, i8
    INTEGER(i4) :: i, j, current_index

    CALL init_error_status(status)

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(block_id)

    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Validate data type is CLASS
    IF (mem_block%data_type /= IF_DATA_TYPE_CLASS) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected CLASS block"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 5: Validate class ID
    IF (class_id <= 0 .OR. class_id > global_struct_mem_pool%class_count) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Invalid class ID (must be 1-", &
            global_struct_mem_pool%class_count, "), got ", class_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%class_defs(class_id)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,A,A)') "Class '", &
            TRIM(global_struct_mem_pool%class_defs(class_id)%name), "' is not fully defined"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Recompute total class size including all inherited members (same logic as alloc_class)
    class_size = 0_8
    current_index = class_id

    DO WHILE (current_index /= 0)
        class_size = class_size + global_struct_mem_pool%class_defs(current_index)%size

        IF (global_struct_mem_pool%class_defs(current_index)%parent_id /= 0) THEN
            ! Find parent class index by class_id
            j = 0
            DO i = 1, global_struct_mem_pool%class_count
                IF (global_struct_mem_pool%class_defs(i)%class_id == &
                    global_struct_mem_pool%class_defs(current_index)%parent_id) THEN
                    current_index = i
                    j = i
                    EXIT
                END IF
            END DO

            IF (j == 0) EXIT  ! Parent definition not found; stop accumulation
        ELSE
            EXIT
        END IF
    END DO

    IF (class_size <= 0_8) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Class size is not positive"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    start_offset = mem_block%mem_addr
    end_offset   = start_offset + class_size - 1_8

    IF (mem_block%is_unified) THEN
        IF (.NOT. ALLOCATED(unified_buffer)) THEN
            status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
            status%message = "Unified backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i8 = start_offset + 1_8, end_offset + 1_8
            unified_buffer(i8) = 0
        END DO
    ELSE
        IF (.NOT. ALLOCATED(pool_buffer)) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Pool backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i8 = start_offset + 1_8, end_offset + 1_8
            pool_buffer(i8) = 0
        END DO
    END IF

    CALL log_debug("StructMemPool", &
        "Initialized CLASS memory: block="//TRIM(INT_TO_STR(block_id))//&
        ", class_id="//TRIM(INT_TO_STR(class_id))//&
        ", size="//TRIM(INT_TO_STR8(class_size))//" bytes")

    status%status_code = IF_STATUS_OK
    status%message = "Class memory initialized successfully (zeroed)"

END SUBROUTINE initialize_class_memory

SUBROUTINE initialize_struct_memory(block_id, struct_id, status)
    INTEGER(i4), INTENT(IN) :: block_id
    INTEGER(i4), INTENT(IN) :: struct_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    INTEGER(KIND=8) :: struct_size
    INTEGER(KIND=8) :: start_offset, end_offset, i8

    CALL init_error_status(status)

    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(block_id)

    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 4: Validate data type is STRUCT
    IF (mem_block%data_type /= IF_DATA_TYPE_STRUCT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "Data type mismatch: expected STRUCT block"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Pre-check 5: Validate struct ID
    IF (struct_id <= 0 .OR. struct_id > global_struct_mem_pool%struct_count) THEN
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Invalid struct ID (must be 1-", &
            global_struct_mem_pool%struct_count, "), got ", struct_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%struct_defs(struct_id)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,A,A)') "Structure '", &
            TRIM(global_struct_mem_pool%struct_defs(struct_id)%name), "' is not fully defined"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    struct_size = global_struct_mem_pool%struct_defs(struct_id)%size
    IF (struct_size <= 0) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Structure size is not positive"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    start_offset = mem_block%mem_addr
    end_offset   = start_offset + struct_size - 1_8

    IF (mem_block%is_unified) THEN
        IF (.NOT. ALLOCATED(unified_buffer)) THEN
            status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
            status%message = "Unified backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i8 = start_offset + 1_8, end_offset + 1_8
            unified_buffer(i8) = 0
        END DO
    ELSE
        IF (.NOT. ALLOCATED(pool_buffer)) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Pool backing buffer not allocated"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i8 = start_offset + 1_8, end_offset + 1_8
            pool_buffer(i8) = 0
        END DO
    END IF

    CALL log_debug("StructMemPool", &
        "Initialized STRUCT memory: block="//TRIM(INT_TO_STR(block_id))//&
        ", struct_id="//TRIM(INT_TO_STR(struct_id))//&
        ", size="//TRIM(INT_TO_STR8(struct_size))//" bytes")

    status%status_code = IF_STATUS_OK
    status%message = "Structure memory initialized successfully (zeroed)"

END SUBROUTINE initialize_struct_memory

FUNCTION INT_TO_STR(i) RESULT(str)
    INTEGER(i4), INTENT(IN) :: i
    CHARACTER(LEN=20) :: str
    
    WRITE(str, '(I0)') i
    str = ADJUSTL(str)
    
END FUNCTION INT_TO_STR

FUNCTION INT_TO_STR8(i) RESULT(str)
    INTEGER(KIND=8), INTENT(IN) :: i
    CHARACTER(LEN=20) :: str
    
    WRITE(str, '(I0)') i
    str = ADJUSTL(str)
    
END FUNCTION INT_TO_STR8

SUBROUTINE lock_struct_mem(block_id, status)
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. global_struct_mem_pool%mem_blocks(block_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Lock memory block
    global_struct_mem_pool%mem_blocks(block_id)%is_locked = .TRUE.
    
    CALL log_info("StructMemPool", "Locked memory block "//TRIM(INT_TO_STR(block_id)))
    
    status%status_code = IF_STATUS_OK
    status%message = "Memory block locked successfully"
    
END SUBROUTINE lock_struct_mem

SUBROUTINE query_struct_mem_block(block_id, mem_block_info, status)
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(StructMemBlockType), INTENT(OUT) :: mem_block_info
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Return memory block info (protective copy)
    mem_block_info = global_struct_mem_pool%mem_blocks(block_id)
    
    CALL log_debug("StructMemPool", "Queried memory block "//TRIM(INT_TO_STR(block_id)))
    
    status%status_code = IF_STATUS_OK
    status%message = "Memory block information retrieved successfully"
    
END SUBROUTINE query_struct_mem_block

SUBROUTINE register_class_def(class_name, parent_name, metadata, class_id, status)
    CHARACTER(LEN=*), INTENT(IN) :: class_name
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: parent_name
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: metadata
    INTEGER(i4), INTENT(OUT) :: class_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(ErrorStatusType) :: dev_status
    INTEGER(i4) :: new_size, io_stat, i, j, parent_id
    CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: local_parent = ""
    CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: local_metadata = ""
    TYPE(ClassDefType), ALLOCATABLE :: tmp_classes(:)
    
    CALL init_error_status(status)
    class_id = 0
    parent_id = 0
    
    ! Pre-check: Whether the memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Check if class name already exists
    DO i = 1, global_struct_mem_pool%class_count
        IF (TRIM(global_struct_mem_pool%class_defs(i)%name) == TRIM(class_name)) THEN
            status%status_code = IF_STATUS_SMEM_EXISTS
            WRITE(status%message, '(A,A,A)') "Class '", TRIM(class_name), "' already exists"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END DO
    
    ! Handle parent class parameter
    IF (PRESENT(parent_name)) THEN
        local_parent = TRIM(parent_name)
        ! Find parent class ID
        DO j = 1, global_struct_mem_pool%class_count
            IF (TRIM(global_struct_mem_pool%class_defs(j)%name) == TRIM(local_parent)) THEN
                parent_id = global_struct_mem_pool%class_defs(j)%class_id
                EXIT
            END IF
        END DO
        ! Check if parent class exists (if parent name is provided)
        IF (parent_id == 0 .AND. LEN_TRIM(local_parent) > 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            WRITE(status%message, '(A,A,A)') "Parent class '", TRIM(local_parent), "' not found"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END IF
    
    ! Handle metadata parameter
    IF (PRESENT(metadata)) THEN
        local_metadata = TRIM(metadata)
    END IF
    
    ! Expand class definitions array if current size is insufficient
    IF (global_struct_mem_pool%class_count >= SIZE(global_struct_mem_pool%class_defs)) THEN
        new_size = SIZE(global_struct_mem_pool%class_defs) * 2
        ALLOCATE(tmp_classes(new_size), STAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to expand class definitions array"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
        
        ! Copy existing class definitions to new array
        DO i = 1, global_struct_mem_pool%class_count
            tmp_classes(i) = global_struct_mem_pool%class_defs(i)
        END DO
        
        DEALLOCATE(global_struct_mem_pool%class_defs)
        CALL MOVE_ALLOC(tmp_classes, global_struct_mem_pool%class_defs)
    END IF
    
    ! Register class metadata
    ! Note: Using a simplified approach since we're just registering metadata, not actual variables
    ! This might need to be adjusted based on the actual requirements
    class_id = global_struct_mem_pool%class_count + 1
    status%status_code = IF_STATUS_OK
    
    ! Save class definition to memory pool
    global_struct_mem_pool%class_count = global_struct_mem_pool%class_count + 1
    global_struct_mem_pool%class_defs(global_struct_mem_pool%class_count)%name = TRIM(class_name)
    global_struct_mem_pool%class_defs(global_struct_mem_pool%class_count)%parent_name = TRIM(local_parent)
    global_struct_mem_pool%class_defs(global_struct_mem_pool%class_count)%class_id = class_id
    global_struct_mem_pool%class_defs(global_struct_mem_pool%class_count)%parent_id = parent_id
    global_struct_mem_pool%class_defs(global_struct_mem_pool%class_count)%metadata = TRIM(local_metadata)
    global_struct_mem_pool%class_defs(global_struct_mem_pool%class_count)%is_complete = .FALSE.
    
    CALL log_info("StructMemPool", &
        "Registered class: '"//TRIM(class_name)//"' (ID: "//TRIM(INT_TO_STR(class_id))//")")
    
    status%status_code = IF_STATUS_OK
    status%message = "Class registered successfully"
    
END SUBROUTINE register_class_def

    SUBROUTINE register_struct_def(struct_name, metadata, struct_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: struct_name
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: metadata
        INTEGER(i4), INTENT(OUT) :: struct_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        TYPE(ErrorStatusType) :: dev_status
        INTEGER(i4) :: new_size, io_stat, i
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: local_metadata = ""
        TYPE(StructDefType), ALLOCATABLE :: tmp_structs(:)
        
        CALL init_error_status(status)
        struct_id = 0
        
        ! Pre-check: Whether the memory pool is initialized
        IF (.NOT. global_struct_mem_pool%initialized) THEN
            status%status_code = IF_STATUS_SMEM_NOT_INIT
            status%message = "Structured memory pool not initialized"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
        
        ! Check if struct name already exists
        DO i = 1, global_struct_mem_pool%struct_count
            IF (TRIM(global_struct_mem_pool%struct_defs(i)%name) == TRIM(struct_name)) THEN
                status%status_code = IF_STATUS_SMEM_EXISTS
                WRITE(status%message, '(A,A,A)') "Structure '", TRIM(struct_name), "' already exists"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END DO
        
        ! Process metadata parameter
        IF (PRESENT(metadata)) THEN
            local_metadata = TRIM(metadata)
        END IF
        
        ! Expand struct definitions array if needed
        IF (global_struct_mem_pool%struct_count >= SIZE(global_struct_mem_pool%struct_defs)) THEN
            new_size = SIZE(global_struct_mem_pool%struct_defs) * 2
            ALLOCATE(tmp_structs(new_size), STAT=io_stat)
            IF (io_stat /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to expand struct definitions array"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
            
            ! Copy existing struct definitions to new array
            DO i = 1, global_struct_mem_pool%struct_count
                tmp_structs(i) = global_struct_mem_pool%struct_defs(i)
            END DO
            
            DEALLOCATE(global_struct_mem_pool%struct_defs)
            CALL MOVE_ALLOC(tmp_structs, global_struct_mem_pool%struct_defs)
        END IF
        
        ! Register struct with StructMetaData
        ! Note: Using a simplified approach since we're just registering metadata, not actual variables
        ! This might need to be adjusted based on the actual requirements
        struct_id = global_struct_mem_pool%struct_count + 1
        status%status_code = IF_STATUS_OK
        
        ! Save structure definition
        global_struct_mem_pool%struct_count = global_struct_mem_pool%struct_count + 1
        global_struct_mem_pool%struct_defs(global_struct_mem_pool%struct_count)%name = TRIM(struct_name)
        global_struct_mem_pool%struct_defs(global_struct_mem_pool%struct_count)%struct_id = struct_id
        global_struct_mem_pool%struct_defs(global_struct_mem_pool%struct_count)%metadata = TRIM(local_metadata)
        global_struct_mem_pool%struct_defs(global_struct_mem_pool%struct_count)%is_complete = .FALSE.
        
        CALL log_info("StructMemPool", &
            "Registered struct: '"//TRIM(struct_name)//"' (ID: "//TRIM(INT_TO_STR(struct_id))//")")
        
        status%status_code = IF_STATUS_OK
        status%message = "Struct registered successfully"
        
    END SUBROUTINE register_struct_def

SUBROUTINE register_struct_subarray(data_id, data_type, dims, char_len, metadata, subarray_id, status, struct_class_name)
    CHARACTER(LEN=*), INTENT(IN) :: data_id
    INTEGER(i4), INTENT(IN) :: data_type
    INTEGER(i4), INTENT(IN) :: dims(4)
    INTEGER(i4), INTENT(IN) :: char_len
    CHARACTER(LEN=*), INTENT(IN) :: metadata
    INTEGER(i4), INTENT(OUT) :: subarray_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: struct_class_name
    
    TYPE(ErrorStatusType) :: dev_status
    INTEGER(i4) :: i, dim_count
    INTEGER(KIND=8) :: req_size, aligned_size
    CHARACTER(LEN=64) :: local_struct_class = ""
    
    CALL init_error_status(status)
    subarray_id = 0
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Whether unified memory is enabled
    IF (.NOT. global_struct_mem_pool%unified_mem_enabled .OR. &
        LEN_TRIM(global_struct_mem_pool%unified_mem_id) == 0) THEN
        status%status_code = IF_STATUS_SMEM_UNIFIED_ERR
        status%message = "Unified memory not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Whether data ID is unique
    DO i = 1, IF_MAX_UNIFIED_SUBARRAYS
        IF (TRIM(global_struct_mem_pool%unified_subarrays(i)%data_id) == TRIM(data_id) .AND. &
            global_struct_mem_pool%unified_subarrays(i)%is_used) THEN
            status%status_code = IF_STATUS_SMEM_EXISTS
            WRITE(status%message, '(A,A,A)') "Subarray ID '", TRIM(data_id), "' already exists"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END DO
    
    ! Process optional parameters
    IF (PRESENT(struct_class_name)) THEN
        local_struct_class = TRIM(struct_class_name)
    END IF
    
    ! Calculate dimension count and memory size
    dim_count = 0
    DO i = 1, 4
        IF (dims(i) > 0) THEN
            dim_count = dim_count + 1
        ELSE
            EXIT
        END IF
    END DO
    
    IF (dim_count == 0) THEN
        status%status_code = IF_STATUS_SMEM_DIM_MISMATCH
        status%message = "At least one dimension must be positive"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Calculate memory size
    req_size = 1
    DO i = 1, dim_count
        req_size = req_size * dims(i)
    END DO
    
    SELECT CASE(data_type)
        CASE(IF_DATA_TYPE_INT)
            req_size = req_size * 4
        CASE(IF_DATA_TYPE_DP)
            req_size = req_size * 8
        CASE(IF_DATA_TYPE_CHAR)
            req_size = req_size * char_len
        CASE DEFAULT
            status%status_code = IF_STATUS_TYPE_MISMATCH
            status%message = "Unsupported data type for unified subarray"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
    END SELECT
    
    aligned_size = ((req_size + IF_SMEM_ALIGN_SIZE - 1) / IF_SMEM_ALIGN_SIZE) * IF_SMEM_ALIGN_SIZE
    
    ! Check unified memory sufficiency
    IF (aligned_size > (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used)) THEN
        status%status_code = IF_STATUS_SMEM_MEM_INSUFF
        WRITE(status%message, '(A,I0,A,I0)') "Unified memory insufficient (required ", &
            aligned_size, ", free ", (global_struct_mem_pool%unified_mem_size - global_struct_mem_pool%unified_mem_used), ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Find free subarray slot
    DO i = 1, IF_MAX_UNIFIED_SUBARRAYS
        IF (.NOT. global_struct_mem_pool%unified_subarrays(i)%is_used) THEN
            subarray_id = i
            EXIT
        END IF
    END DO
    
    IF (subarray_id == 0) THEN
        status%status_code = IF_STATUS_TABLE_FULL
        WRITE(status%message, '(A,I0,A)') "Max unified subarrays reached (", &
            IF_MAX_UNIFIED_SUBARRAYS, ")"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Allocate subarray
    global_struct_mem_pool%unified_subarrays(subarray_id)%data_id = TRIM(data_id)
    global_struct_mem_pool%unified_subarrays(subarray_id)%data_type = data_type
    global_struct_mem_pool%unified_subarrays(subarray_id)%dims = dims
    global_struct_mem_pool%unified_subarrays(subarray_id)%char_len = char_len
    global_struct_mem_pool%unified_subarrays(subarray_id)%offset = global_struct_mem_pool%unified_mem_used
    global_struct_mem_pool%unified_subarrays(subarray_id)%size = aligned_size
    global_struct_mem_pool%unified_subarrays(subarray_id)%is_used = .TRUE.
    
    ! Update unified memory usage
    global_struct_mem_pool%unified_mem_used = global_struct_mem_pool%unified_mem_used + aligned_size
    
    ! Metadata is stored in UnifiedSubarrayType
    
    CALL log_info("StructMemPool", &
        "Registered unified subarray: ID='"//TRIM(data_id)//&
        "', type="//TRIM(get_type_string(data_type))//&
        ", dims="//TRIM(get_dims_string(dims))//&
        ", size="//TRIM(INT_TO_STR(INT(aligned_size, KIND=4)))//" bytes")
    
    status%status_code = IF_STATUS_OK
    status%message = "Unified subarray registered successfully"
    
END SUBROUTINE register_struct_subarray

    SUBROUTINE smem_get_device_buffer(block_id, device_id, dev_ptr, size_bytes, status)
        INTEGER(i4), INTENT(IN) :: block_id
        INTEGER(i4), INTENT(IN) :: device_id
        TYPE(C_PTR), INTENT(OUT) :: dev_ptr
        INTEGER(KIND=8), INTENT(OUT) :: size_bytes
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, map_index

        CALL init_error_status(status)
        dev_ptr = C_NULL_PTR
        size_bytes = 0_8
        map_index = 0

        IF (.NOT. global_struct_mem_pool%initialized) THEN
            status%status_code = IF_STATUS_SMEM_NOT_INIT
            status%message = "Structured memory pool not initialized (smem_get_device_buffer)"
            CALL log_warn("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (block_id < 1 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
            status%status_code = IF_STATUS_SMEM_NOT_FOUND
            status%message = "Invalid block_id in smem_get_device_buffer"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. global_struct_mem_pool%mem_blocks(block_id)%is_used) THEN
            status%status_code = IF_STATUS_SMEM_NOT_FOUND
            status%message = "Memory block not in use in smem_get_device_buffer"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. ALLOCATED(global_struct_mem_pool%device_buffer_maps)) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Device buffer mapping table not allocated in smem_get_device_buffer"
            CALL log_warn("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, SIZE(global_struct_mem_pool%device_buffer_maps)
            IF (global_struct_mem_pool%device_buffer_maps(i)%is_used) THEN
                IF (global_struct_mem_pool%device_buffer_maps(i)%block_id == block_id .AND. &
                    global_struct_mem_pool%device_buffer_maps(i)%device_id == device_id) THEN
                    map_index = i
                    EXIT
                END IF
            END IF
        END DO

        IF (map_index == 0) THEN
            status%status_code = IF_STATUS_SMEM_NOT_FOUND
            status%message = "Device buffer mapping not found in smem_get_device_buffer"
            CALL log_warn("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        dev_ptr = global_struct_mem_pool%device_buffer_maps(map_index)%device_ptr
        size_bytes = global_struct_mem_pool%device_buffer_maps(map_index)%size_bytes

        IF (size_bytes <= 0_8) THEN
            size_bytes = global_struct_mem_pool%mem_blocks(block_id)%block_size
        END IF

        CALL log_info("StructMemPool", &
            "smem_get_device_buffer: found mapping for block="//TRIM(INT_TO_STR(block_id))//&
            ", device="//TRIM(INT_TO_STR(device_id))//" (simulation mode)" )

        status%status_code = IF_STATUS_OK
        status%message = "smem_get_device_buffer executed: mapping found in simulation mode"
    END SUBROUTINE smem_get_device_buffer

    SUBROUTINE smem_map_block_to_device(block_id, device_id, status)
        INTEGER(i4), INTENT(IN) :: block_id
        INTEGER(i4), INTENT(IN) :: device_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i
        INTEGER(i4) :: existing_index, free_index

        CALL init_error_status(status)
        existing_index = 0
        free_index     = 0

        IF (.NOT. global_struct_mem_pool%initialized) THEN
            status%status_code = IF_STATUS_SMEM_NOT_INIT
            status%message = "Structured memory pool not initialized (smem_map_block_to_device)"
            CALL log_warn("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (block_id < 1 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
            status%status_code = IF_STATUS_SMEM_NOT_FOUND
            status%message = "Invalid block_id in smem_map_block_to_device"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. global_struct_mem_pool%mem_blocks(block_id)%is_used) THEN
            status%status_code = IF_STATUS_SMEM_NOT_FOUND
            status%message = "Memory block not in use in smem_map_block_to_device"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. ALLOCATED(global_struct_mem_pool%device_buffer_maps)) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Device buffer mapping table not allocated in smem_map_block_to_device"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, SIZE(global_struct_mem_pool%device_buffer_maps)
            IF (global_struct_mem_pool%device_buffer_maps(i)%is_used) THEN
                IF (global_struct_mem_pool%device_buffer_maps(i)%block_id == block_id .AND. &
                    global_struct_mem_pool%device_buffer_maps(i)%device_id == device_id) THEN
                    existing_index = i
                    EXIT
                END IF
            END IF
        END DO

        IF (existing_index > 0) THEN
            IF (global_struct_mem_pool%device_buffer_maps(existing_index)%size_bytes <= 0_8) THEN
                global_struct_mem_pool%device_buffer_maps(existing_index)%size_bytes = &
                    global_struct_mem_pool%mem_blocks(block_id)%used_size
                IF (global_struct_mem_pool%device_buffer_maps(existing_index)%size_bytes <= 0_8) THEN
                    global_struct_mem_pool%device_buffer_maps(existing_index)%size_bytes = &
                        global_struct_mem_pool%mem_blocks(block_id)%block_size
                END IF
            END IF

            CALL log_info("StructMemPool", &
                "smem_map_block_to_device: reuse existing mapping for block="// &
                TRIM(INT_TO_STR(block_id))//", device="//TRIM(INT_TO_STR(device_id)))

            status%status_code = IF_STATUS_OK
            status%message = "Block already mapped to device (reuse existing mapping entry)"
            RETURN
        END IF

        DO i = 1, SIZE(global_struct_mem_pool%device_buffer_maps)
            IF (.NOT. global_struct_mem_pool%device_buffer_maps(i)%is_used) THEN
                free_index = i
                EXIT
            END IF
        END DO

        IF (free_index == 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "No free slot in device buffer mapping table"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_struct_mem_pool%device_buffer_maps(free_index)%block_id = block_id
        global_struct_mem_pool%device_buffer_maps(free_index)%device_id = device_id
        global_struct_mem_pool%device_buffer_maps(free_index)%device_ptr = C_NULL_PTR
        global_struct_mem_pool%device_buffer_maps(free_index)%size_bytes = &
            global_struct_mem_pool%mem_blocks(block_id)%used_size

        IF (global_struct_mem_pool%device_buffer_maps(free_index)%size_bytes <= 0_8) THEN
            global_struct_mem_pool%device_buffer_maps(free_index)%size_bytes = &
                global_struct_mem_pool%mem_blocks(block_id)%block_size
        END IF

        global_struct_mem_pool%device_buffer_maps(free_index)%sync_state = IF_SYNC_STATE_IN_SYNC
        global_struct_mem_pool%device_buffer_maps(free_index)%is_used = .TRUE.

        global_struct_mem_pool%device_buffer_map_count = &
            global_struct_mem_pool%device_buffer_map_count + 1

        CALL log_info("StructMemPool", &
            "smem_map_block_to_device: mapped block="//TRIM(INT_TO_STR(block_id))//&
            ", device="//TRIM(INT_TO_STR(device_id))//" (simulated device buffer)" )

        status%status_code = IF_STATUS_OK
        status%message = "smem_map_block_to_device executed: mapping recorded for simulated device buffer"
    END SUBROUTINE smem_map_block_to_device

    SUBROUTINE smem_sync_block(block_id, device_id, direction, status)
        INTEGER(i4), INTENT(IN) :: block_id
        INTEGER(i4), INTENT(IN) :: device_id
        INTEGER(i4), INTENT(IN) :: direction
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, map_index

        CALL init_error_status(status)
        map_index = 0

        IF (.NOT. global_struct_mem_pool%initialized) THEN
            status%status_code = IF_STATUS_SMEM_NOT_INIT
            status%message = "Structured memory pool not initialized (smem_sync_block)"
            CALL log_warn("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (block_id < 1 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
            status%status_code = IF_STATUS_SMEM_NOT_FOUND
            status%message = "Invalid block_id in smem_sync_block"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. global_struct_mem_pool%mem_blocks(block_id)%is_used) THEN
            status%status_code = IF_STATUS_SMEM_NOT_FOUND
            status%message = "Memory block not in use in smem_sync_block"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (direction /= IF_SYNC_HOST_TO_DEVICE .AND. direction /= IF_SYNC_DEVICE_TO_HOST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid direction in smem_sync_block"
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. ALLOCATED(global_struct_mem_pool%device_buffer_maps)) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Device buffer mapping table not allocated in smem_sync_block"
            CALL log_warn("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, SIZE(global_struct_mem_pool%device_buffer_maps)
            IF (global_struct_mem_pool%device_buffer_maps(i)%is_used) THEN
                IF (global_struct_mem_pool%device_buffer_maps(i)%block_id == block_id .AND. &
                    global_struct_mem_pool%device_buffer_maps(i)%device_id == device_id) THEN
                    map_index = i
                    EXIT
                END IF
            END IF
        END DO

        IF (map_index == 0) THEN
            status%status_code = IF_STATUS_SMEM_NOT_FOUND
            status%message = "Device buffer mapping not found in smem_sync_block"
            CALL log_warn("StructMemPool", TRIM(status%message))
            RETURN
        END IF

        SELECT CASE (direction)
            CASE (IF_SYNC_HOST_TO_DEVICE)
                global_struct_mem_pool%device_buffer_maps(map_index)%sync_state = IF_SYNC_STATE_IN_SYNC
                CALL log_info("StructMemPool", &
                    "smem_sync_block: HOST->DEVICE sync (simulated) for block="//&
                    TRIM(INT_TO_STR(block_id))//", device="//TRIM(INT_TO_STR(device_id)))
            CASE (IF_SYNC_DEVICE_TO_HOST)
                global_struct_mem_pool%device_buffer_maps(map_index)%sync_state = IF_SYNC_STATE_IN_SYNC
                CALL log_info("StructMemPool", &
                    "smem_sync_block: DEVICE->HOST sync (simulated) for block="//&
                    TRIM(INT_TO_STR(block_id))//", device="//TRIM(INT_TO_STR(device_id)))
        END SELECT

        status%status_code = IF_STATUS_OK
        status%message = "smem_sync_block executed in CPU-only mode (sync_state updated)"
    END SUBROUTINE smem_sync_block

SUBROUTINE sort_lru_list(lru_list, count)
    INTEGER(i4), INTENT(INOUT) :: lru_list(:)
    INTEGER(i4), INTENT(IN) :: count
    
    INTEGER(i4) :: i, j, temp
    INTEGER(i4) :: count_i, count_j
    
    ! Simple bubble sort (ascending by lru_count)
    DO i = 1, count-1
        DO j = i+1, count
            count_i = global_struct_mem_pool%mem_blocks(lru_list(i))%lru_count
            count_j = global_struct_mem_pool%mem_blocks(lru_list(j))%lru_count
            
            IF (count_i > count_j) THEN
                temp = lru_list(i)
                lru_list(i) = lru_list(j)
                lru_list(j) = temp
            END IF
        END DO
    END DO
    
END SUBROUTINE sort_lru_list

SUBROUTINE unlock_struct_mem(block_id, status)
    INTEGER(i4), INTENT(IN) :: block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Pre-check 1: Whether memory pool is initialized
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 2: Validate memory block ID
    IF (block_id <= 0 .OR. block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check 3: Whether memory block is in use
    IF (.NOT. global_struct_mem_pool%mem_blocks(block_id)%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF
    
    ! Unlock memory block
    global_struct_mem_pool%mem_blocks(block_id)%is_locked = .FALSE.
    
    CALL log_info("StructMemPool", "Unlocked memory block "//TRIM(INT_TO_STR(block_id)))
    
    status%status_code = IF_STATUS_OK
    status%message = "Memory block unlocked successfully"
    
END SUBROUTINE unlock_struct_mem

SUBROUTINE verify_class_layout(mem_block_id, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    INTEGER(i4) :: class_id_local, i, j, member_count
    INTEGER(KIND=8) :: block_size, start_i, end_i, start_j, end_j
    INTEGER(KIND=8) :: elem_size, elem_count, member_size

    CALL init_error_status(status)

    ! Check pool initialization
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Validate block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(mem_block_id)

    ! Block must be in use and of CLASS type
    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (mem_block%data_type /= IF_DATA_TYPE_CLASS) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "verify_class_layout expects CLASS block"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    class_id_local = mem_block%class_id
    IF (class_id_local <= 0 .OR. class_id_local > global_struct_mem_pool%class_count) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Invalid class ID stored in memory block for layout verification"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%class_defs(class_id_local)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,I0,A)') "Class definition for ID ", class_id_local, " is not complete"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    member_count = global_struct_mem_pool%class_defs(class_id_local)%member_count
    block_size = mem_block%block_size

    ! Bounds check for each member range
    DO i = 1, member_count
        CALL compute_member_size(global_struct_mem_pool%class_defs(class_id_local)%members(i), &
                                 elem_size, elem_count, member_size)

        start_i = global_struct_mem_pool%class_defs(class_id_local)%members(i)%offset
        end_i   = start_i + member_size - 1_8

        IF (start_i < 0_8 .OR. end_i >= block_size) THEN
            status%status_code = IF_STATUS_SMEM_STRUCT_ERR
            WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0)') &
                "Class member ", i, " out of block bounds: [", start_i, ",", end_i, &
                "] vs block_size=", block_size
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END DO

    ! Simple overlap check between members
    DO i = 1, member_count
        CALL compute_member_size(global_struct_mem_pool%class_defs(class_id_local)%members(i), &
                                 elem_size, elem_count, member_size)
        start_i = global_struct_mem_pool%class_defs(class_id_local)%members(i)%offset
        end_i   = start_i + member_size - 1_8

        DO j = i+1, member_count
            CALL compute_member_size(global_struct_mem_pool%class_defs(class_id_local)%members(j), &
                                     elem_size, elem_count, member_size)
            start_j = global_struct_mem_pool%class_defs(class_id_local)%members(j)%offset
            end_j   = start_j + member_size - 1_8

            IF (start_i <= end_j .AND. start_j <= end_i) THEN
                status%status_code = IF_STATUS_SMEM_STRUCT_ERR
                WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0,A,I0,A,I0)') &
                    "Class members ", i, " and ", j, " overlap: [", start_i, ",", end_i, &
                    "] vs [", start_j, ",", end_j, "]"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END DO
    END DO

    CALL log_info("StructMemPool", &
        "Class layout verified successfully for block="//TRIM(INT_TO_STR(mem_block_id))// &
        ", class_id="//TRIM(INT_TO_STR(class_id_local)))

    status%status_code = IF_STATUS_OK
    status%message = "Class layout verified successfully"

END SUBROUTINE verify_class_layout

SUBROUTINE verify_struct_layout(mem_block_id, status)
    INTEGER(i4), INTENT(IN) :: mem_block_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(StructMemBlockType) :: mem_block
    INTEGER(i4) :: struct_id_local, i, j, member_count
    INTEGER(KIND=8) :: block_size, start_i, end_i, start_j, end_j
    INTEGER(KIND=8) :: elem_size, elem_count, member_size

    CALL init_error_status(status)

    ! Check pool initialization
    IF (.NOT. global_struct_mem_pool%initialized) THEN
        status%status_code = IF_STATUS_SMEM_NOT_INIT
        status%message = "Structured memory pool not initialized"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    ! Validate block ID
    IF (mem_block_id <= 0 .OR. mem_block_id > global_struct_mem_pool%max_blocks) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0,A,I0)') "Mem block ID must be 1-", &
            global_struct_mem_pool%max_blocks, ", got ", mem_block_id
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    mem_block = global_struct_mem_pool%mem_blocks(mem_block_id)

    ! Block must be in use and of STRUCT type
    IF (.NOT. mem_block%is_used) THEN
        status%status_code = IF_STATUS_SMEM_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Memory block ", mem_block_id, " is not in use"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (mem_block%data_type /= IF_DATA_TYPE_STRUCT) THEN
        status%status_code = IF_STATUS_TYPE_MISMATCH
        status%message = "verify_struct_layout expects STRUCT block"
        CALL log_warn("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    struct_id_local = mem_block%struct_id
    IF (struct_id_local <= 0 .OR. struct_id_local > global_struct_mem_pool%struct_count) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        status%message = "Invalid struct ID stored in memory block for layout verification"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    IF (.NOT. global_struct_mem_pool%struct_defs(struct_id_local)%is_complete) THEN
        status%status_code = IF_STATUS_SMEM_STRUCT_ERR
        WRITE(status%message, '(A,I0,A)') "Struct definition for ID ", struct_id_local, " is not complete"
        CALL log_error("StructMemPool", TRIM(status%message))
        RETURN
    END IF

    member_count = global_struct_mem_pool%struct_defs(struct_id_local)%member_count
    block_size = mem_block%block_size

    ! Bounds check for each member range
    DO i = 1, member_count
        CALL compute_member_size(global_struct_mem_pool%struct_defs(struct_id_local)%members(i), &
                                 elem_size, elem_count, member_size)

        start_i = global_struct_mem_pool%struct_defs(struct_id_local)%members(i)%offset
        end_i   = start_i + member_size - 1_8

        IF (start_i < 0_8 .OR. end_i >= block_size) THEN
            status%status_code = IF_STATUS_SMEM_STRUCT_ERR
            WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0)') &
                "Struct member ", i, " out of block bounds: [", start_i, ",", end_i, &
                "] vs block_size=", block_size
            CALL log_error("StructMemPool", TRIM(status%message))
            RETURN
        END IF
    END DO

    ! Simple overlap check between members (O(n^2), acceptable for debug)
    DO i = 1, member_count
        CALL compute_member_size(global_struct_mem_pool%struct_defs(struct_id_local)%members(i), &
                                 elem_size, elem_count, member_size)
        start_i = global_struct_mem_pool%struct_defs(struct_id_local)%members(i)%offset
        end_i   = start_i + member_size - 1_8

        DO j = i+1, member_count
            CALL compute_member_size(global_struct_mem_pool%struct_defs(struct_id_local)%members(j), &
                                     elem_size, elem_count, member_size)
            start_j = global_struct_mem_pool%struct_defs(struct_id_local)%members(j)%offset
            end_j   = start_j + member_size - 1_8

            IF (start_i <= end_j .AND. start_j <= end_i) THEN
                status%status_code = IF_STATUS_SMEM_STRUCT_ERR
                WRITE(status%message, '(A,I0,A,I0,A,I0,A,I0,A,I0,A,I0)') &
                    "Struct members ", i, " and ", j, " overlap: [", start_i, ",", end_i, &
                    "] vs [", start_j, ",", end_j, "]"
                CALL log_error("StructMemPool", TRIM(status%message))
                RETURN
            END IF
        END DO
    END DO

    CALL log_info("StructMemPool", &
        "Struct layout verified successfully for block="//TRIM(INT_TO_STR(mem_block_id))// &
        ", struct_id="//TRIM(INT_TO_STR(struct_id_local)))

    status%status_code = IF_STATUS_OK
    status%message = "Struct layout verified successfully"

END SUBROUTINE verify_struct_layout
END MODULE IF_Mem_StructPool