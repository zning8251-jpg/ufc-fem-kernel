!===============================================================================
! MODULE: IF_Base_StructMeta_Def
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Def — structured metadata descriptors (1-4D arrays/structures)
! BRIEF:  Metadata for structured data: dimension management, memory
!         alignment, checksum, lifecycle tracking.
! Status: Draft | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Base_StructMeta_Def
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_info, log_warn, log_error, log_debug, &
        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_MEM_ERROR, IF_STATUS_EXISTS, IF_STATUS_NOT_FOUND
    ! Identification Layer: Symbol table module (depends on base layer) - import 
    ! variable identification linking components
    USE IF_Base_SymTbl, ONLY: &
        symbol_table_exists, get_variable_data_id, &
        IF_STORAGE_TYPE_STRUCTURED, IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR, &
        IF_DATA_TYPE_STRUCT, IF_DATA_TYPE_CLASS, IF_STATUS_TABLE_NOT_INIT

    IMPLICIT NONE
    
    ! Internal utility functions
    INTEGER(i4), PARAMETER :: IF_MAX_INT_STR_LEN = 20  ! Maximum length for integer string conversion
    INTEGER(i4), PARAMETER :: IF_MAX_ERROR_DETAIL_LEN = 512  ! Maximum length for detailed error messages
    INTEGER(i4), PARAMETER :: IF_MAX_CALL_STACK_DEPTH = 10   ! Maximum depth for call stack tracking
    
    ! Additional error codes for enhanced error handling
    INTEGER(i4), PARAMETER :: IF_STATUS_META_BATCH_ERR = 209     ! Batch operation error
    INTEGER(i4), PARAMETER :: IF_STATUS_META_VERSION_ERR = 210   ! Version control error
    INTEGER(i4), PARAMETER :: IF_STATUS_META_SECURITY_ERR = 211  ! Security related error
    INTEGER(i4), PARAMETER :: IF_STATUS_META_TIMEOUT = 212       ! Operation timeout error
    INTEGER(i4), PARAMETER :: IF_STATUS_META_RESOURCE_ERR = 213  ! Resource allocation error

    ! ==========================================================================
    ! 1. Structured Metadata-Specific Error Codes (Defined within this module, 
    !    range: 201-210 to avoid conflict with other modules)
    ! ==========================================================================
    PUBLIC :: IF_STATUS_META_EXISTS, IF_STATUS_META_NOT_FOUND, IF_STATUS_META_DIM_INVALID
    PUBLIC :: IF_STATUS_META_TYPE_MISMATCH, IF_STATUS_META_NO_SYM_LINK, IF_STATUS_META_NOT_INIT
    PUBLIC :: IF_STATUS_META_CHUNK_INVALID, IF_STATUS_META_CRC_ERR, struct_meta_exists
    INTEGER(i4), PARAMETER :: IF_STATUS_META_EXISTS = 201    ! Structured metadata exists (duplicate data ID)
    INTEGER(i4), PARAMETER :: IF_STATUS_META_NOT_FOUND = 202  ! Structured metadata not found
    INTEGER(i4), PARAMETER :: IF_STATUS_META_DIM_INVALID = 203 ! Invalid structured data dimension (not 1-4D or negative)
    INTEGER(i4), PARAMETER :: IF_STATUS_META_TYPE_MISMATCH = 204 ! Data type mismatch with structured storage
    INTEGER(i4), PARAMETER :: IF_STATUS_META_NO_SYM_LINK = 205 ! Metadata not linked to symbol table variable
    INTEGER(i4), PARAMETER :: IF_STATUS_META_NOT_INIT = 206    ! Structured metadata module not initialized
    INTEGER(i4), PARAMETER :: IF_STATUS_META_CHUNK_INVALID = 207 ! Invalid chunk info (negative size/count)
    INTEGER(i4), PARAMETER :: IF_STATUS_META_CRC_ERR = 208     ! Metadata checksum mismatch

    ! ==========================================================================
    ! 2. Core Constants for Structured Metadata (Defined within this module, 
    !    adapted for industrial numerical computing scenarios)
    ! ==========================================================================
    PUBLIC :: IF_MAX_DIMENSIONS, IF_MAX_DATA_ID_LEN, IF_MAX_VAR_NAME_LEN, IF_MAX_FORMAT_LEN
    PUBLIC :: IF_DEFAULT_CHUNK_SIZE, IF_MIN_ELEMENT_SIZE
    PUBLIC :: INT_TO_STR
    PUBLIC :: INT_ARR_TO_STR
    INTEGER(i4), PARAMETER :: IF_MAX_DIMENSIONS = 4          ! Max dimensions for structured data (1-4D)
    INTEGER(i4), PARAMETER :: IF_MAX_DATA_ID_LEN = 64       ! Max data ID length (aligned with symbol table)
    INTEGER(i4), PARAMETER :: IF_MAX_VAR_NAME_LEN = 64      ! Max variable name length (aligned with symbol table)
    INTEGER(i4), PARAMETER :: IF_MAX_FORMAT_LEN = 128      ! Max data format description length (e.g., 'HDF5'/'BINARY')
    INTEGER(KIND=8), PARAMETER :: IF_DEFAULT_CHUNK_SIZE = 1024*1024  ! Default chunk size (1MB, for chunked IO)
    INTEGER(KIND=8), PARAMETER :: IF_MIN_ELEMENT_SIZE = 1 ! Min element size (bytes, avoid invalid memory usage)
    
    ! Version control constants
INTEGER(i4), PARAMETER :: IF_MAX_VERSION_HISTORY = 100        ! Maximum versions to keep per metadata entry
INTEGER(i4), PARAMETER :: IF_VERSION_NOTE_MAX_LENGTH = 256    ! Maximum length for version note
INTEGER(i4), PARAMETER :: IF_MAX_ID_LENGTH = 128               ! Maximum ID length (used in query conditions)

! Import/Export constants
INTEGER(i4), PARAMETER :: IF_MAX_FILE_PATH_LENGTH = 1024      ! Maximum file path length
INTEGER(i4), PARAMETER :: IF_MAX_META_ID_LENGTH = 128         ! Maximum metadata ID length for import/export
INTEGER(i4), PARAMETER :: IF_FORMAT_JSON = 1                  ! JSON file format
INTEGER(i4), PARAMETER :: IF_FORMAT_XML = 2                   ! XML file format
INTEGER(i4), PARAMETER :: IF_FORMAT_CSV = 3                   ! CSV file format
INTEGER(i4), PARAMETER :: IF_FORMAT_BINARY = 4                ! Binary file format

! Device association constants
INTEGER(i4), PARAMETER :: IF_MAX_DEVICES_PER_META = 20         ! Maximum number of devices per metadata entry
INTEGER(i4), PARAMETER :: IF_MAX_DEVICE_ID_LENGTH = 64         ! Maximum device ID length
INTEGER(i4), PARAMETER :: IF_MAX_DEVICE_NAME_LENGTH = 128      ! Maximum device name length
INTEGER(i4), PARAMETER :: IF_MAX_DEVICE_TYPE_LENGTH = 32       ! Maximum device type length
INTEGER(i4), PARAMETER :: IF_MAX_DEVICE_LOCATION_LENGTH = 256  ! Maximum device location length

    ! ==========================================================================
    ! 3. Core Data Types for Structured Metadata (Defined within this module, 
    !    describes metadata of structured data)
    ! ==========================================================================
    PUBLIC :: StructMetaType, StructMetaManagerType
    PUBLIC :: struct_meta_try_query

    ! Device Information Type: Stores information about a device associated with metadata
    ! (Defined before StructMetaType because it's used in StructMetaType)
    TYPE :: DeviceInfoType
        CHARACTER(LEN=IF_MAX_DEVICE_ID_LENGTH) :: device_id = ""              ! Unique device ID
        CHARACTER(LEN=IF_MAX_DEVICE_NAME_LENGTH) :: device_name = ""          ! Device name
        CHARACTER(LEN=IF_MAX_DEVICE_TYPE_LENGTH) :: device_type = ""          ! Device type (GPU/CPU/TPU/Storage)
        CHARACTER(LEN=IF_MAX_DEVICE_LOCATION_LENGTH) :: location = ""         ! Device physical location
        LOGICAL :: is_primary_device = .FALSE.                            ! Whether this is the primary device
        CHARACTER(LEN=20) :: association_time = ""                        ! Association timestamp
    END TYPE DeviceInfoType

    ! Version Record Type: Stores a snapshot of metadata at a specific version
    ! (Defined before StructMetaType because it's used in StructMetaType)
    TYPE :: StructMetaVersionType
        INTEGER(i4) :: version_number = 0                     ! Version number
        CHARACTER(LEN=20) :: version_time = ""            ! Version creation time
        CHARACTER(LEN=IF_VERSION_NOTE_MAX_LENGTH) :: version_note = "" ! Version note/description
        INTEGER(i4) :: crc32 = 0                              ! Checksum at this version
        INTEGER(i4) :: data_type = 0                          ! Data type at this version
        INTEGER(i4) :: dimensions(IF_MAX_DIMENSIONS) = [0,0,0,0] ! Dimensions at this version
        INTEGER(KIND=8) :: total_size = 0                 ! Total size at this version
        LOGICAL :: is_chunked = .FALSE.                   ! Chunked status at this version
    END TYPE StructMetaVersionType

    ! Structured Metadata Entry Type: Stores metadata for a single structured data item
    TYPE :: StructMetaType
        ! Identification linking (aligned with symbol table)
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""        ! Unique data ID (linked to symbol table)
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: var_name = ""      ! Linked variable name (from symbol table)
        INTEGER(i4) :: storage_type = IF_STORAGE_TYPE_STRUCTURED    ! Storage type (fixed as structured, no modification)
        
        ! Data type and dimensions (core characteristics of structured data)
        INTEGER(i4) :: data_type = 0                            ! Data type (IF_DATA_TYPE_INT/DP/CHAR/STRUCT/CLASS)
        INTEGER(i4) :: dimensions(IF_MAX_DIMENSIONS) = [0,0,0,0]   ! 1-4D dimensions (0 for invalid dimensions)
        INTEGER(i4) :: valid_dim_count = 0                     ! Number of valid dimensions (1-4)
        INTEGER(KIND=8) :: element_size = 0                ! Size of single element (bytes, e.g., INT=4, DP=8)
        INTEGER(KIND=8) :: total_elements = 0             ! Total number of elements (product of dimensions)
        INTEGER(KIND=8) :: total_size = 0                 ! Total memory size (bytes = element_size * total_elements)
        
        ! Chunk and memory characteristics (adapted for industrial IO)
        LOGICAL :: is_chunked = .FALSE.                    ! Whether to use chunked storage
        INTEGER(KIND=8) :: chunk_size = IF_DEFAULT_CHUNK_SIZE ! Chunk size (bytes)
        INTEGER(i4) :: total_chunks = 0                       ! Total number of chunks
        INTEGER(KIND=8), ALLOCATABLE :: chunk_offsets(:)   ! Chunk offsets (bytes, valid only for chunked storage)
        
        ! Integrity and lifecycle
        INTEGER(i4) :: crc32 = 0                              ! Data checksum (ensures integrity)
        CHARACTER(LEN=20) :: create_time = ""             ! Creation time (YYYY-MM-DD HH:MM:SS)
        CHARACTER(LEN=20) :: update_time = ""             ! Last update time
        LOGICAL :: is_valid = .FALSE.                    ! Metadata validity (logical deletion flag)
        LOGICAL :: is_constant = .FALSE.                  ! Whether data is constant (non-updatable)
        
        ! Version control fields
        INTEGER(i4) :: version_number = 1                     ! Current version number
        INTEGER(i4) :: version_history_count = 0              ! Number of versions in history
        TYPE(StructMetaVersionType), ALLOCATABLE :: version_history(:) ! Version history
        
        ! Device association fields
        INTEGER(i4) :: device_count = 0                       ! Number of associated devices
        TYPE(DeviceInfoType), DIMENSION(IF_MAX_DEVICES_PER_META) :: associated_devices ! Associated devices

        ! Hash index linkage for data_id (used by internal index structure)
        INTEGER(i4) :: next_in_id_hash = 0
    END TYPE StructMetaType

    ! Structured Metadata Manager Type: Manages all structured metadata entries
    TYPE :: StructMetaManagerType
        LOGICAL :: initialized = .FALSE.                  ! Whether manager is initialized
        INTEGER(i4) :: max_meta_count = 0                     ! Max number of supported metadata entries
        INTEGER(i4) :: current_meta_count = 0                 ! Current number of valid metadata entries
        TYPE(StructMetaType), ALLOCATABLE :: meta_list(:) ! Array of metadata entries
        INTEGER(i4) :: total_versions = 0                     ! Total number of versions created
        INTEGER(i4) :: total_device_associations = 0          ! Total number of device associations
        INTEGER(i4) :: total_queries = 0                      ! Total number of queries executed
        INTEGER(i4) :: total_updates = 0                      ! Total number of updates performed
        INTEGER(i4) :: total_validations = 0                  ! Total number of validations performed
        INTEGER(i4) :: total_errors = 0                       ! Total number of errors encountered

        ! Hash index for data_id: bucket count and bucket heads
        INTEGER(i4) :: id_bucket_count = 0                    ! Number of buckets in hash index
        INTEGER, ALLOCATABLE :: id_bucket_head(:)         ! Head indices for each bucket
    END TYPE StructMetaManagerType

    ! ==========================================================================
    ! 4. Module Global Instance (PRIVATE+SAVE: Fortran2003 Standard, ensures 
    !    persistence and no direct external access)
    ! ==========================================================================
    TYPE(StructMetaManagerType), PRIVATE, SAVE :: global_struct_meta_mgr

    ! ==========================================================================
    ! ==========================================================================
    ! 5.1 Query Condition Types for Complex Queries
    ! ==========================================================================
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_NONE = 0      ! No condition
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_DATA_ID = 1   ! Filter by data_id
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_VAR_NAME = 2  ! Filter by variable name
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_DATA_TYPE = 3 ! Filter by data type
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_STORAGE = 4   ! Filter by storage type
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_DIM_COUNT = 5 ! Filter by dimension count
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_IS_CONSTANT = 6 ! Filter by constant flag
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_IS_CHUNKED = 7  ! Filter by chunked flag
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_SIZE_RANGE = 8  ! Filter by size range
    INTEGER(i4), PARAMETER :: IF_QUERY_COND_TYPE_CRC32 = 9      ! Filter by CRC32 value
    INTEGER(i4), PARAMETER :: IF_MAX_QUERY_CONDITIONS = 10     ! Maximum number of conditions in a query
    
    ! Individual Query Condition Type
    TYPE :: QueryConditionType
        INTEGER(i4) :: cond_type = IF_QUERY_COND_TYPE_NONE   ! Type of condition
        CHARACTER(LEN=IF_MAX_ID_LENGTH) :: str_value1 = "" ! String value 1 (for IDs, names, etc.)
        CHARACTER(LEN=IF_MAX_ID_LENGTH) :: str_value2 = "" ! String value 2 (for range queries)
        INTEGER(i4) :: int_value1 = 0                     ! Integer value 1 (for types, sizes, etc.)
        INTEGER(i4) :: int_value2 = 0                     ! Integer value 2 (for range queries)
        LOGICAL :: logical_value = .FALSE.            ! Logical value (for boolean flags)
        LOGICAL :: is_active = .FALSE.                ! Whether condition is active
    END TYPE QueryConditionType
    
    ! Query Filter Type: Contains multiple conditions
    TYPE :: QueryFilterType
        TYPE(QueryConditionType) :: conditions(IF_MAX_QUERY_CONDITIONS) ! Array of conditions
        INTEGER(i4) :: active_cond_count = 0              ! Number of active conditions
        LOGICAL :: use_and_logic = .TRUE.             ! Use AND (TRUE) or OR (FALSE) between conditions
    END TYPE QueryFilterType
    
    ! 5. Public Interface Export (Minimal Exposure Principle: Only export types 
    !    and subroutines needed externally)
    ! ==========================================================================
    PRIVATE
    PUBLIC :: init_struct_meta_mgr, destroy_struct_meta_mgr
    PUBLIC :: struct_meta_create, struct_meta_query, struct_meta_update, struct_meta_delete
    PUBLIC :: struct_meta_validate, get_struct_meta_count
    PUBLIC :: struct_meta_create_batch, struct_meta_update_batch, struct_meta_delete_batch
    PUBLIC :: struct_meta_persist, struct_meta_recover
    PUBLIC :: QueryFilterType, init_query_filter, add_query_condition, struct_meta_complex_query
    PUBLIC :: struct_meta_save_version, struct_meta_get_version, struct_meta_get_version_history
    PUBLIC :: struct_meta_restore_version
    PUBLIC :: struct_meta_add_device_association, struct_meta_remove_device_association
    PUBLIC :: struct_meta_get_device_association, struct_meta_get_all_device_associations
    PUBLIC :: struct_meta_is_device_associated
    PUBLIC :: get_struct_meta_statistics, get_struct_meta_type_statistics, get_struct_meta_storage_statistics
    PUBLIC :: get_struct_meta_operation_statistics, get_struct_meta_device_statistics
    PUBLIC :: struct_meta_export, struct_meta_export_all, struct_meta_import, struct_meta_import_all, struct_meta_batch_import
    ! Error handling and recovery functions
    PUBLIC :: struct_meta_validate_all, struct_meta_repair, struct_meta_recover_from_error
    PUBLIC :: get_struct_meta_error_summary, struct_meta_reset_error_counter

CONTAINS
    ! ==========================================================================
    ! Subroutine: Initialize Structured Metadata Manager
    ! Function: Allocate metadata array, initialize status, relies on error module 
    ! to record initialization failures
    ! ==========================================================================
    SUBROUTINE init_struct_meta_mgr(status, max_meta_count)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER, INTENT(IN), OPTIONAL :: max_meta_count  ! Optional: Custom max metadata entry count
        INTEGER(i4) :: local_max_count
        CHARACTER(LEN=20) :: init_time

        CALL init_error_status(status)

        ! Pre-check: Whether manager is already initialized (base error code: IF_STATUS_EXISTS)
        IF (global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Structured metadata manager already initialized"
            CALL log_info("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Handle max metadata entry count (default: 1000, for small-to-medium numerical scenarios)
        local_max_count = 1000
        IF (PRESENT(max_meta_count)) THEN
            IF (max_meta_count <= 0) THEN
                status%status_code = IF_STATUS_ERROR
                status%message = "Max meta count must be positive integer"
                CALL log_error("StructMetaData", TRIM(status%message))
                RETURN
            END IF
            local_max_count = max_meta_count
        END IF

        ! Allocate metadata array (base error code: IF_STATUS_MEM_ERROR)
        ALLOCATE(global_struct_meta_mgr%meta_list(local_max_count), STAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0)') "Allocate meta list failed (stat=", status%io_stat
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Initialize hash index buckets for data_id
        global_struct_meta_mgr%id_bucket_count = MAX(2 * local_max_count, 1024)
        ALLOCATE(global_struct_meta_mgr%id_bucket_head(global_struct_meta_mgr%id_bucket_count), STAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0)') "Allocate id_bucket_head failed (stat=", status%io_stat
            CALL log_error("StructMetaData", TRIM(status%message))
            DEALLOCATE(global_struct_meta_mgr%meta_list, STAT=status%io_stat)
            RETURN
        END IF
        global_struct_meta_mgr%id_bucket_head = 0

        ! Initialize manager status
        global_struct_meta_mgr%max_meta_count = local_max_count
        global_struct_meta_mgr%current_meta_count = 0
        global_struct_meta_mgr%total_versions = 0
        global_struct_meta_mgr%total_device_associations = 0
        global_struct_meta_mgr%total_queries = 0
        global_struct_meta_mgr%total_updates = 0
        global_struct_meta_mgr%total_validations = 0
        global_struct_meta_mgr%total_errors = 0
        global_struct_meta_mgr%initialized = .TRUE.
        CALL get_timestamp(init_time)  ! Get initialization time

        CALL log_info("StructMetaData", "Initialized structured metadata manager (max meta count="//&    
            TRIM(INT_TO_STR(local_max_count))//", init time="//TRIM(init_time)//")")
    END SUBROUTINE init_struct_meta_mgr

    ! ==========================================================================
    ! Subroutine: Destroy Structured Metadata Manager
    ! Function: Deallocate metadata array, reset status, relies on error module 
    ! to record destruction failures
    ! ==========================================================================
    SUBROUTINE destroy_struct_meta_mgr(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        ! Pre-check: Whether manager is uninitialized (module-specific error code: IF_STATUS_META_NOT_INIT)
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_warn("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Deallocate chunk offset arrays (avoid memory leak)
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (ALLOCATED(global_struct_meta_mgr%meta_list(i)%chunk_offsets)) THEN
                DEALLOCATE(global_struct_meta_mgr%meta_list(i)%chunk_offsets, STAT=status%io_stat)
                IF (status%io_stat /= 0) THEN
                    CALL log_warn("StructMetaData", "Deallocate chunk offsets failed for meta "//&    
                        TRIM(INT_TO_STR(i))//" (stat="//TRIM(INT_TO_STR(status%io_stat))//")")
                END IF
            END IF
        END DO

        ! Deallocate metadata array
        DEALLOCATE(global_struct_meta_mgr%meta_list, STAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Deallocate meta list failed (stat=", status%io_stat
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Deallocate hash index buckets
        IF (ALLOCATED(global_struct_meta_mgr%id_bucket_head)) THEN
            DEALLOCATE(global_struct_meta_mgr%id_bucket_head, STAT=status%io_stat)
            IF (status%io_stat /= 0) THEN
                CALL log_warn("StructMetaData", "Deallocate id_bucket_head failed (stat="//&
                    TRIM(INT_TO_STR(status%io_stat))//")")
            END IF
        END IF
        global_struct_meta_mgr%id_bucket_count = 0

        ! Reset manager status
        global_struct_meta_mgr%initialized = .FALSE.
        global_struct_meta_mgr%max_meta_count = 0
        global_struct_meta_mgr%current_meta_count = 0
        global_struct_meta_mgr%total_versions = 0
        global_struct_meta_mgr%total_device_associations = 0
        global_struct_meta_mgr%total_queries = 0
        global_struct_meta_mgr%total_updates = 0
        global_struct_meta_mgr%total_validations = 0
        global_struct_meta_mgr%total_errors = 0

        CALL log_info("StructMetaData", "Destroyed structured metadata manager")
    END SUBROUTINE destroy_struct_meta_mgr

    ! ==========================================================================
    ! Subroutine: Create Structured Metadata (Linked to Symbol Table Variable)
    ! Function: Validate variable validity, generate metadata, link to symbol table, 
    ! relies on error/symbol table modules
    ! ==========================================================================
    SUBROUTINE struct_meta_create(var_name, data_type, dimensions, element_size, is_chunked, meta, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name          ! Linked variable name (from symbol table)
        INTEGER(i4), INTENT(IN) :: data_type                  ! Data type (IF_DATA_TYPE_*)
        INTEGER(i4), INTENT(IN) :: dimensions(IF_MAX_DIMENSIONS) ! 1-4D dimensions
        INTEGER(KIND=8), INTENT(IN) :: element_size       ! Size of single element (bytes)
        LOGICAL, INTENT(IN) :: is_chunked                ! Whether to use chunked storage
        TYPE(StructMetaType), INTENT(OUT) :: meta         ! Output created metadata
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id
        INTEGER(i4) :: i, free_idx, valid_dim_count
        CHARACTER(LEN=20) :: create_time
        LOGICAL :: sym_exists

        CALL init_error_status(status)
        ! Initialize metadata to default values manually (to avoid array initialization issues)
        meta%data_id = ""
        meta%var_name = ""
        meta%storage_type = IF_STORAGE_TYPE_STRUCTURED
        meta%data_type = 0
        meta%dimensions = [0,0,0,0]
        meta%valid_dim_count = 0
        meta%element_size = 0
        meta%total_elements = 0
        meta%total_size = 0
        meta%is_chunked = .FALSE.
        meta%chunk_size = IF_DEFAULT_CHUNK_SIZE
        meta%total_chunks = 0
        meta%crc32 = 0
        meta%create_time = ""
        meta%update_time = ""
        meta%is_valid = .FALSE.
        meta%is_constant = .FALSE.
        meta%version_number = 1
        meta%version_history_count = 0
        meta%device_count = 0
        ! Initialize associated_devices array
        DO i = 1, IF_MAX_DEVICES_PER_META
            meta%associated_devices(i) = DeviceInfoType()
        END DO

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_META_NOT_INIT)
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Whether variable is registered in symbol table (depends on identification layer, 
        ! error code: IF_STATUS_TABLE_NOT_INIT)
        sym_exists = symbol_table_exists(var_name, status)
        IF (status%status_code == IF_STATUS_TABLE_NOT_INIT) THEN
            status%status_code = IF_STATUS_META_NO_SYM_LINK
            status%message = "Symbol table not initialized, cannot link variable"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF
        IF (.NOT. sym_exists) THEN
            status%status_code = IF_STATUS_META_NO_SYM_LINK
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' not registered in symbol table"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 3: Get data ID linked to variable (depends on identification layer)
        CALL get_variable_data_id(var_name, data_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%status_code = IF_STATUS_META_NO_SYM_LINK
            status%message = "Failed to get data ID from symbol table: "//TRIM(status%message)
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 4: Whether metadata already exists (specific error code: IF_STATUS_META_EXISTS)
        IF (struct_meta_exists(data_id, status)) THEN
            status%status_code = IF_STATUS_META_EXISTS
            WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' already exists"	
            CALL log_warn("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 5: Validity of structured metadata parameters (dimensions, element size)
        IF (.NOT. validate_struct_params(data_type, dimensions, element_size, valid_dim_count, status)) THEN
            CALL log_error("StructMetaData", "Invalid structured metadata params: "//TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 6: Whether manager is full (specific error code: IF_STATUS_MEM_ERROR)
        free_idx = find_free_meta_entry(status)
        IF (free_idx == 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A,I0)') "Structured metadata manager full (max ", &
                global_struct_meta_mgr%max_meta_count, ", current ", &
                global_struct_meta_mgr%current_meta_count, ")"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Populate core structured metadata info
        CALL get_timestamp(create_time)
        meta%data_id = TRIM(data_id)
        meta%var_name = TRIM(var_name)
        meta%data_type = data_type
        meta%dimensions = dimensions
        meta%valid_dim_count = valid_dim_count
        meta%element_size = element_size
        meta%total_elements = PRODUCT(INT(dimensions(1:valid_dim_count), KIND=8))  ! Calculate total elements
        meta%total_size = meta%total_elements * element_size  ! Calculate total memory size
        meta%is_chunked = is_chunked
        meta%create_time = TRIM(create_time)
        meta%update_time = TRIM(create_time)
        meta%is_valid = .TRUE.

        ! Initialize chunk info (valid only for chunked storage)
        IF (is_chunked) THEN
            meta%chunk_size = IF_DEFAULT_CHUNK_SIZE
            meta%total_chunks = CEILING(REAL(meta%total_size) / REAL(meta%chunk_size))  ! Calculate total chunks
            ALLOCATE(meta%chunk_offsets(meta%total_chunks), STAT=status%io_stat)
            IF (status%io_stat /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Allocate chunk offsets failed"
                CALL log_error("StructMetaData", TRIM(status%message))
                RETURN
            END IF
            ! Calculate chunk offsets (start from 1, adapted for Fortran file IO)
            DO i = 1, meta%total_chunks
                meta%chunk_offsets(i) = (i - 1) * meta%chunk_size + 1
            END DO
        END IF

        ! Save metadata to manager and update index/metrics via helper
        CALL store_meta_entry(free_idx, meta)

        CALL log_info("StructMetaData", "Created structured metadata: var_name='"//TRIM(var_name)//&
            "', data_id='"//TRIM(data_id)//"', dims="//TRIM(INT_ARR_TO_STR(dimensions(1:valid_dim_count))) )
    END SUBROUTINE struct_meta_create

    ! ==========================================================================
    ! Subroutine: Query Structured Metadata (Supports query by data ID/variable name)
    ! ==========================================================================
    ! Compute hash bucket index for given data_id (simple rolling hash)
    PURE FUNCTION hash_data_id(data_id, bucket_count) RESULT(bucket_index)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: bucket_count
        INTEGER(i4) :: bucket_index
        INTEGER(i4) :: i, ich, hash_val

        hash_val = 0
        DO i = 1, LEN_TRIM(data_id)
            ich = ICHAR(data_id(i:i))
            hash_val = IAND(hash_val * 131 + ich, Z'7FFFFFFF')
        END DO

        IF (bucket_count <= 0) THEN
            bucket_index = 1
        ELSE
            bucket_index = MOD(hash_val, bucket_count) + 1
        END IF
    END FUNCTION hash_data_id

    ! Insert metadata index into hash index by data ID
    SUBROUTINE insert_meta_index_by_id(data_id, meta_index)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: meta_index
        INTEGER(i4) :: bucket

        IF (.NOT. global_struct_meta_mgr%initialized) RETURN
        IF (global_struct_meta_mgr%id_bucket_count <= 0) RETURN

        bucket = hash_data_id(TRIM(data_id), global_struct_meta_mgr%id_bucket_count)

        global_struct_meta_mgr%meta_list(meta_index)%next_in_id_hash = &
            global_struct_meta_mgr%id_bucket_head(bucket)
        global_struct_meta_mgr%id_bucket_head(bucket) = meta_index
    END SUBROUTINE insert_meta_index_by_id

    ! Remove metadata index from hash index by data ID
    SUBROUTINE remove_meta_index_by_id(data_id, meta_index)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: meta_index
        INTEGER(i4) :: bucket, cur, prev

        IF (.NOT. global_struct_meta_mgr%initialized) RETURN
        IF (global_struct_meta_mgr%id_bucket_count <= 0) RETURN

        bucket = hash_data_id(TRIM(data_id), global_struct_meta_mgr%id_bucket_count)

        prev = 0
        cur  = global_struct_meta_mgr%id_bucket_head(bucket)

        DO WHILE (cur /= 0)
            IF (cur == meta_index) THEN
                IF (prev == 0) THEN
                    global_struct_meta_mgr%id_bucket_head(bucket) = &
                        global_struct_meta_mgr%meta_list(cur)%next_in_id_hash
                ELSE
                    global_struct_meta_mgr%meta_list(prev)%next_in_id_hash = &
                        global_struct_meta_mgr%meta_list(cur)%next_in_id_hash
                END IF
                global_struct_meta_mgr%meta_list(cur)%next_in_id_hash = 0
                EXIT
            END IF
            prev = cur
            cur  = global_struct_meta_mgr%meta_list(cur)%next_in_id_hash
        END DO
    END SUBROUTINE remove_meta_index_by_id

    ! Internal helper: store metadata entry and update index/metrics
    SUBROUTINE store_meta_entry(meta_index, meta)
        INTEGER(i4), INTENT(IN) :: meta_index
        TYPE(StructMetaType), INTENT(IN) :: meta

        ! Assumes manager has been initialized and meta_index is a valid free slot
        global_struct_meta_mgr%meta_list(meta_index) = meta
        global_struct_meta_mgr%current_meta_count = global_struct_meta_mgr%current_meta_count + 1

        ! Insert into hash index for fast lookup by data_id
        CALL insert_meta_index_by_id(meta%data_id, meta_index)
    END SUBROUTINE store_meta_entry

    ! Internal helper: logically delete metadata entry and update index/metrics
    SUBROUTINE invalidate_meta_entry(meta_index)
        INTEGER(i4), INTENT(IN) :: meta_index

        ! Remove from hash index and logically delete
        CALL remove_meta_index_by_id(global_struct_meta_mgr%meta_list(meta_index)%data_id, meta_index)
        global_struct_meta_mgr%meta_list(meta_index)%is_valid = .FALSE.
        global_struct_meta_mgr%current_meta_count = global_struct_meta_mgr%current_meta_count - 1
    END SUBROUTINE invalidate_meta_entry

    ! Helper: find metadata index by data ID (hash lookup, fallback to linear scan)
    SUBROUTINE find_meta_index_by_id(data_id, meta_index, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(OUT) :: meta_index
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, bucket, cur

        CALL init_error_status(status)
        meta_index = 0

        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Prefer hash index lookup when available
        IF (global_struct_meta_mgr%id_bucket_count > 0) THEN
            bucket = hash_data_id(TRIM(data_id), global_struct_meta_mgr%id_bucket_count)
            cur = global_struct_meta_mgr%id_bucket_head(bucket)

            DO WHILE (cur /= 0)
                IF (global_struct_meta_mgr%meta_list(cur)%is_valid .AND. &
                    TRIM(global_struct_meta_mgr%meta_list(cur)%data_id) == TRIM(data_id)) THEN
                    meta_index = cur
                    status%status_code = IF_STATUS_OK
                    RETURN
                END IF
                cur = global_struct_meta_mgr%meta_list(cur)%next_in_id_hash
            END DO
        END IF

        ! Fallback: linear scan (for robustness)
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                meta_index = i
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO

        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for '", TRIM(data_id), "' not found"
        CALL log_warn("StructMetaData", TRIM(status%message))
    END SUBROUTINE find_meta_index_by_id

    SUBROUTINE struct_meta_query(query_key, query_type, meta, status)
        CHARACTER(LEN=*), INTENT(IN) :: query_key  ! Query key (data ID or variable name)
        INTEGER(i4), INTENT(IN) :: query_type          ! Query type: 1=data ID, 2=variable name
        TYPE(StructMetaType), INTENT(OUT) :: meta   ! Output queried metadata
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id
        INTEGER(i4) :: i

        CALL init_error_status(status)
        ! Initialize metadata to default values manually (to avoid array initialization issues)
        meta%data_id = ""
        meta%var_name = ""
        meta%storage_type = IF_STORAGE_TYPE_STRUCTURED
        meta%data_type = 0
        meta%dimensions = [0,0,0,0]
        meta%valid_dim_count = 0
        meta%element_size = 0
        meta%total_elements = 0
        meta%total_size = 0
        meta%is_chunked = .FALSE.
        meta%chunk_size = IF_DEFAULT_CHUNK_SIZE
        meta%total_chunks = 0
        meta%crc32 = 0
        meta%create_time = ""
        meta%update_time = ""
        meta%is_valid = .FALSE.
        meta%is_constant = .FALSE.
        meta%version_number = 1
        meta%version_history_count = 0
        meta%device_count = 0
        ! Initialize associated_devices array
        DO i = 1, IF_MAX_DEVICES_PER_META
            meta%associated_devices(i) = DeviceInfoType()
        END DO

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_META_NOT_INIT)
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Validity of query type
        IF (query_type /= 1 .AND. query_type /= 2) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Query type must be 1(data ID) or 2(variable name)"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Process by query type: 1=data ID, 2=variable name
        SELECT CASE (query_type)
            CASE (1)  ! Query by data ID
                CALL find_meta_index_by_id(query_key, i, status)
                IF (status%status_code == IF_STATUS_OK) THEN
                    meta = global_struct_meta_mgr%meta_list(i)
                    status%status_code = IF_STATUS_OK
                    CALL log_debug("StructMetaData", "Queried structured metadata by data ID: "//TRIM(query_key))
                    RETURN
                ELSE IF (status%status_code /= IF_STATUS_META_NOT_FOUND) THEN
                    ! For errors other than NOT_FOUND, do not override status/message here
                    RETURN
                END IF

            CASE (2)  ! Query by variable name (get data ID first)
                CALL get_variable_data_id(query_key, data_id, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    status%status_code = IF_STATUS_META_NO_SYM_LINK
                    status%message = "Failed to get data ID for variable: "//TRIM(status%message)
                    CALL log_error("StructMetaData", TRIM(status%message))
                    RETURN
                END IF

                CALL find_meta_index_by_id(TRIM(data_id), i, status)
                IF (status%status_code == IF_STATUS_OK) THEN
                    meta = global_struct_meta_mgr%meta_list(i)
                    status%status_code = IF_STATUS_OK
                    CALL log_debug("StructMetaData", "Queried structured metadata by var name: "//TRIM(query_key))
                    RETURN
                ELSE IF (status%status_code /= IF_STATUS_META_NOT_FOUND) THEN
                    ! For errors other than NOT_FOUND, do not override status/message here
                    RETURN
                END IF
        END SELECT

        ! Metadata not found (specific error code: IF_STATUS_META_NOT_FOUND)
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for '", TRIM(query_key), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_query

    SUBROUTINE struct_meta_try_query(query_key, query_type, meta, found, status)
        CHARACTER(LEN=*), INTENT(IN) :: query_key
        INTEGER(i4), INTENT(IN) :: query_type
        TYPE(StructMetaType), INTENT(OUT) :: meta
        LOGICAL, INTENT(OUT) :: found
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id
        INTEGER(i4) :: i, meta_index

        CALL init_error_status(status)
        found = .FALSE.

        meta%data_id = ""
        meta%var_name = ""
        meta%storage_type = IF_STORAGE_TYPE_STRUCTURED
        meta%data_type = 0
        meta%dimensions = [0,0,0,0]
        meta%valid_dim_count = 0
        meta%element_size = 0
        meta%total_elements = 0
        meta%total_size = 0
        meta%is_chunked = .FALSE.
        meta%chunk_size = IF_DEFAULT_CHUNK_SIZE
        meta%total_chunks = 0
        meta%crc32 = 0
        meta%create_time = ""
        meta%update_time = ""
        meta%is_valid = .FALSE.
        meta%is_constant = .FALSE.
        meta%version_number = 1
        meta%version_history_count = 0
        meta%device_count = 0
        DO i = 1, IF_MAX_DEVICES_PER_META
            meta%associated_devices(i) = DeviceInfoType()
        END DO

        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            RETURN
        END IF

        IF (query_type /= 1 .AND. query_type /= 2) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Query type must be 1(data ID) or 2(variable name)"
            RETURN
        END IF

        SELECT CASE (query_type)
            CASE (1)
                CALL find_meta_index_by_id(query_key, meta_index, status)
                IF (status%status_code == IF_STATUS_OK) THEN
                    meta = global_struct_meta_mgr%meta_list(meta_index)
                    found = .TRUE.
                    RETURN
                ELSE IF (status%status_code == IF_STATUS_META_NOT_FOUND) THEN
                    RETURN
                ELSE
                    RETURN
                END IF

            CASE (2)
                CALL get_variable_data_id(query_key, data_id, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    status%status_code = IF_STATUS_META_NO_SYM_LINK
                    status%message = "Failed to get data ID for variable: "//TRIM(status%message)
                    RETURN
                END IF

                CALL find_meta_index_by_id(TRIM(data_id), meta_index, status)
                IF (status%status_code == IF_STATUS_OK) THEN
                    meta = global_struct_meta_mgr%meta_list(meta_index)
                    found = .TRUE.
                    RETURN
                ELSE IF (status%status_code == IF_STATUS_META_NOT_FOUND) THEN
                    RETURN
                ELSE
                    RETURN
                END IF
        END SELECT
    END SUBROUTINE struct_meta_try_query

    ! ==========================================================================
    ! Subroutine: Update Structured Metadata (Only non-identification fields allowed, 
    ! e.g., checksum, chunk info)
    ! ==========================================================================
    SUBROUTINE struct_meta_update(data_id, update_field, new_value, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id      ! Data ID (unique identifier)
        INTEGER(i4), INTENT(IN) :: update_field          ! Update field: 1=checksum, 2=chunk size, 3=constant flag
        INTEGER(KIND=8), INTENT(IN) :: new_value     ! New value (8-byte int for multi-field compatibility)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        CHARACTER(LEN=20) :: update_time

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_META_NOT_INIT)
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Whether metadata exists
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                ! Check field validity; no update for identification fields (data ID/variable name)
                SELECT CASE (update_field)
                    CASE (1)  ! Update checksum
                        global_struct_meta_mgr%meta_list(i)%crc32 = INT(new_value)
                        CALL log_debug("StructMetaData", "Updated CRC32 for data ID "//TRIM(data_id)//&
                            " to "//TRIM(INT_TO_STR(INT(new_value))))
                    CASE (2)  ! Update chunk size (allowed only for chunked storage)
                        IF (.NOT. global_struct_meta_mgr%meta_list(i)%is_chunked) THEN
                            status%status_code = IF_STATUS_META_CHUNK_INVALID
                            status%message = "Metadata is not chunked, cannot update chunk size"
                            CALL log_error("StructMetaData", TRIM(status%message))
                            RETURN
                        END IF
                        IF (new_value <= 0) THEN
                            status%status_code = IF_STATUS_META_CHUNK_INVALID
                            status%message = "Chunk size must be positive"
                            CALL log_error("StructMetaData", TRIM(status%message))
                            RETURN
                        END IF
                        global_struct_meta_mgr%meta_list(i)%chunk_size = new_value
                        ! Recalculate total number of chunks
                        global_struct_meta_mgr%meta_list(i)%total_chunks = &
                            CEILING(REAL(global_struct_meta_mgr%meta_list(i)%total_size) / REAL(new_value))
                        CALL log_debug("StructMetaData", "Updated chunk size for data ID "//TRIM(data_id)//&
                            " to "//TRIM(INT_TO_STR(INT(new_value, KIND=4)))//" bytes")
                    CASE (3)  ! Update constant flag
                        global_struct_meta_mgr%meta_list(i)%is_constant = (new_value == 1)
                        CALL log_debug("StructMetaData", "Updated constant flag for data ID "//TRIM(data_id)//&
                            " to "//TRIM(LOGICAL_TO_STR(new_value == 1)))
                    CASE DEFAULT
                        status%status_code = IF_STATUS_ERROR
                        status%message = "Invalid update field (1=CRC32, 2=chunk size, 3=constant flag)"
                        CALL log_error("StructMetaData", TRIM(status%message))
                        RETURN
                END SELECT

                ! Update timestamp
                CALL get_timestamp(update_time)
                global_struct_meta_mgr%meta_list(i)%update_time = TRIM(update_time)
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO

        ! Metadata not found (specific error code: IF_STATUS_META_NOT_FOUND)
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_update

    ! ==========================================================================
    ! Subroutine: Save Current Metadata State as a New Version
    ! ==========================================================================
    SUBROUTINE struct_meta_save_version(data_id, version_note, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id         ! Data ID (unique identifier)
        CHARACTER(LEN=*), INTENT(IN) :: version_note    ! Version note/description
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, idx, move_idx
        CHARACTER(LEN=20) :: version_time
        TYPE(StructMetaVersionType) :: new_version
        TYPE(StructMetaVersionType), ALLOCATABLE :: temp_history(:)

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                ! Pre-check 2: Whether metadata is constant
                IF (global_struct_meta_mgr%meta_list(i)%is_constant) THEN
                    status%status_code = IF_STATUS_ERROR
                    status%message = "Cannot save version for constant metadata"
                    CALL log_error("StructMetaData", TRIM(status%message))
                    RETURN
                END IF
                
                ! Create new version record
                CALL get_timestamp(version_time)
                new_version%version_number = global_struct_meta_mgr%meta_list(i)%version_number
                new_version%version_time = TRIM(version_time)
                new_version%version_note = TRIM(version_note)
                new_version%crc32 = global_struct_meta_mgr%meta_list(i)%crc32
                new_version%data_type = global_struct_meta_mgr%meta_list(i)%data_type
                new_version%dimensions = global_struct_meta_mgr%meta_list(i)%dimensions
                new_version%total_size = global_struct_meta_mgr%meta_list(i)%total_size
                new_version%is_chunked = global_struct_meta_mgr%meta_list(i)%is_chunked
                
                ! Handle version history storage
                IF (global_struct_meta_mgr%meta_list(i)%version_history_count >= IF_MAX_VERSION_HISTORY) THEN
                    ! Shift history to make space for new version (remove oldest version)
                    ALLOCATE(temp_history(IF_MAX_VERSION_HISTORY-1))
                    DO move_idx = 2, IF_MAX_VERSION_HISTORY
                        temp_history(move_idx-1) = global_struct_meta_mgr%meta_list(i)%version_history(move_idx)
                    END DO
                    
                    ! Reallocate and copy back
                    DEALLOCATE(global_struct_meta_mgr%meta_list(i)%version_history)
                    ALLOCATE(global_struct_meta_mgr%meta_list(i)%version_history(IF_MAX_VERSION_HISTORY))
                    DO move_idx = 1, IF_MAX_VERSION_HISTORY-1
                        global_struct_meta_mgr%meta_list(i)%version_history(move_idx) = temp_history(move_idx)
                    END DO
                    DEALLOCATE(temp_history)
                    
                    idx = IF_MAX_VERSION_HISTORY
                    global_struct_meta_mgr%meta_list(i)%version_history_count = IF_MAX_VERSION_HISTORY
                ELSE
                    ! First time or less than max history
                    IF (.NOT. ALLOCATED(global_struct_meta_mgr%meta_list(i)%version_history)) THEN
                        ALLOCATE(global_struct_meta_mgr%meta_list(i)%version_history(IF_MAX_VERSION_HISTORY))
                    END IF
                    global_struct_meta_mgr%meta_list(i)%version_history_count = &
                        global_struct_meta_mgr%meta_list(i)%version_history_count + 1
                    idx = global_struct_meta_mgr%meta_list(i)%version_history_count
                END IF
                
                ! Save new version
                global_struct_meta_mgr%meta_list(i)%version_history(idx) = new_version
                
                ! Update version number for next version
                global_struct_meta_mgr%meta_list(i)%version_number = global_struct_meta_mgr%meta_list(i)%version_number + 1
                global_struct_meta_mgr%total_versions = global_struct_meta_mgr%total_versions + 1
                
                status%status_code = IF_STATUS_OK
                CALL log_info("StructMetaData", "Saved version " // TRIM(INT_TO_STR(new_version%version_number)) // &
                             " for data ID '" // TRIM(data_id) // "'")
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_save_version

    ! ==========================================================================
    ! Subroutine: Get Specific Version of Metadata
    ! ==========================================================================
    SUBROUTINE struct_meta_get_version(data_id, version_number, version_out, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id           ! Data ID (unique identifier)
        INTEGER(i4), INTENT(IN) :: version_number            ! Version number to retrieve
        TYPE(StructMetaVersionType), INTENT(OUT) :: version_out ! Output version information
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                ! Check if version history exists
                IF (.NOT. ALLOCATED(global_struct_meta_mgr%meta_list(i)%version_history) .OR. &
                    global_struct_meta_mgr%meta_list(i)%version_history_count == 0) THEN
                    status%status_code = IF_STATUS_ERROR
                    status%message = "No version history available for this metadata"
                    CALL log_error("StructMetaData", TRIM(status%message))
                    RETURN
                END IF
                
                ! Search for the requested version
                DO j = 1, global_struct_meta_mgr%meta_list(i)%version_history_count
                    IF (global_struct_meta_mgr%meta_list(i)%version_history(j)%version_number == version_number) THEN
                        version_out = global_struct_meta_mgr%meta_list(i)%version_history(j)
                        status%status_code = IF_STATUS_OK
                        CALL log_info("StructMetaData", "Retrieved version " // TRIM(INT_TO_STR(version_number)) // &
                                     " for data ID '" // TRIM(data_id) // "'")
                        RETURN
                    END IF
                END DO
                
                ! Version not found
                status%status_code = IF_STATUS_ERROR
                WRITE(status%message, '(A,I0,A,A)') "Version ", version_number, " not found for data ID '", TRIM(data_id), "'"
                CALL log_error("StructMetaData", TRIM(status%message))
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_get_version

    ! ==========================================================================
    ! Subroutine: Get Version History of Metadata
    ! ==========================================================================
    SUBROUTINE struct_meta_get_version_history(data_id, history_count, version_numbers, version_times, version_notes, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id              ! Data ID (unique identifier)
        INTEGER(i4), INTENT(OUT) :: history_count               ! Number of versions in history
        INTEGER(i4), INTENT(OUT) :: version_numbers(:)          ! Array of version numbers
        CHARACTER(LEN=20), INTENT(OUT) :: version_times(:)  ! Array of version times
        CHARACTER(LEN=IF_VERSION_NOTE_MAX_LENGTH), INTENT(OUT) :: version_notes(:) ! Array of version notes
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                ! Check if version history exists
                IF (.NOT. ALLOCATED(global_struct_meta_mgr%meta_list(i)%version_history) .OR. &
                    global_struct_meta_mgr%meta_list(i)%version_history_count == 0) THEN
                    history_count = 0
                    status%status_code = IF_STATUS_OK
                    CALL log_info("StructMetaData", "No version history available for data ID '" // TRIM(data_id) // "'")
                    RETURN
                END IF
                
                ! Check output array sizes
                IF (SIZE(version_numbers) < global_struct_meta_mgr%meta_list(i)%version_history_count .OR. &
                    SIZE(version_times) < global_struct_meta_mgr%meta_list(i)%version_history_count .OR. &
                    SIZE(version_notes) < global_struct_meta_mgr%meta_list(i)%version_history_count) THEN
                    status%status_code = IF_STATUS_ERROR
                    status%message = "Output arrays too small for version history"
                    CALL log_error("StructMetaData", TRIM(status%message))
                    RETURN
                END IF
                
                ! Copy version history information (in reverse order - newest first)
                history_count = global_struct_meta_mgr%meta_list(i)%version_history_count
                DO j = 1, history_count
                    version_numbers(j) = global_struct_meta_mgr%meta_list(i)%version_history(history_count-j+1)%version_number
                    version_times(j) = global_struct_meta_mgr%meta_list(i)%version_history(history_count-j+1)%version_time
                    version_notes(j) = global_struct_meta_mgr%meta_list(i)%version_history(history_count-j+1)%version_note
                END DO
                
                status%status_code = IF_STATUS_OK
                CALL log_info("StructMetaData", "Retrieved version history for data ID '" // TRIM(data_id) // "'")
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_get_version_history

    ! ==========================================================================
    ! Subroutine: Restore Metadata to Specific Version
    ! ==========================================================================
    SUBROUTINE struct_meta_restore_version(data_id, version_number, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id           ! Data ID (unique identifier)
        INTEGER(i4), INTENT(IN) :: version_number            ! Version number to restore to
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j
        TYPE(StructMetaVersionType) :: target_version
        CHARACTER(LEN=20) :: restore_time

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                ! Pre-check 2: Whether metadata is constant
                IF (global_struct_meta_mgr%meta_list(i)%is_constant) THEN
                    status%status_code = IF_STATUS_ERROR
                    status%message = "Cannot restore version for constant metadata"
                    CALL log_error("StructMetaData", TRIM(status%message))
                    RETURN
                END IF
                
                ! Check if version history exists
                IF (.NOT. ALLOCATED(global_struct_meta_mgr%meta_list(i)%version_history) .OR. &
                    global_struct_meta_mgr%meta_list(i)%version_history_count == 0) THEN
                    status%status_code = IF_STATUS_ERROR
                    status%message = "No version history available for this metadata"
                    CALL log_error("StructMetaData", TRIM(status%message))
                    RETURN
                END IF
                
                ! Search for the requested version
                target_version = global_struct_meta_mgr%meta_list(i)%version_history(1)
                DO j = 1, global_struct_meta_mgr%meta_list(i)%version_history_count
                    IF (global_struct_meta_mgr%meta_list(i)%version_history(j)%version_number == version_number) THEN
                        target_version = global_struct_meta_mgr%meta_list(i)%version_history(j)
                        
                        ! Restore metadata values
                        global_struct_meta_mgr%meta_list(i)%crc32 = target_version%crc32
                        global_struct_meta_mgr%meta_list(i)%data_type = target_version%data_type
                        global_struct_meta_mgr%meta_list(i)%dimensions = target_version%dimensions
                        global_struct_meta_mgr%meta_list(i)%total_size = target_version%total_size
                        global_struct_meta_mgr%meta_list(i)%is_chunked = target_version%is_chunked
                        
                        ! Update timestamp
                        CALL get_timestamp(restore_time)
                        global_struct_meta_mgr%meta_list(i)%update_time = TRIM(restore_time)
                        
                        status%status_code = IF_STATUS_OK
                        CALL log_info("StructMetaData", "Restored data ID '" // TRIM(data_id) // &
                                     "' to version " // TRIM(INT_TO_STR(version_number)))
                        RETURN
                    END IF
                END DO
                
                ! Version not found
                status%status_code = IF_STATUS_ERROR
                WRITE(status%message, '(A,I0,A,A)') "Version ", version_number, " not found for data ID '", TRIM(data_id), "'"
                CALL log_error("StructMetaData", TRIM(status%message))
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_restore_version
    
    ! ==========================================================================
    ! Subroutine: Add Device Association to Metadata
    ! ==========================================================================
    SUBROUTINE struct_meta_add_device_association(data_id, device_id, device_name, device_type, &
                                               location, is_primary, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id          ! Data ID (unique identifier)
        CHARACTER(LEN=*), INTENT(IN) :: device_id        ! Device ID
        CHARACTER(LEN=*), INTENT(IN) :: device_name      ! Device name
        CHARACTER(LEN=*), INTENT(IN) :: device_type      ! Device type
        CHARACTER(LEN=*), INTENT(IN) :: location         ! Device location
        LOGICAL, INTENT(IN) :: is_primary                ! Whether primary device
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j
        TYPE(DeviceInfoType) :: new_device
        CHARACTER(LEN=20) :: association_time

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Input validation
        IF (LEN_TRIM(device_id) > IF_MAX_DEVICE_ID_LENGTH) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Device ID exceeds maximum length"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                ! Check if device already associated
                DO j = 1, global_struct_meta_mgr%meta_list(i)%device_count
                    IF (TRIM(global_struct_meta_mgr%meta_list(i)%associated_devices(j)%device_id) == TRIM(device_id)) THEN
                        status%status_code = IF_STATUS_EXISTS
                        status%message = "Device already associated with this metadata"
                        CALL log_info("StructMetaData", TRIM(status%message))
                        RETURN
                    END IF
                END DO
                
                ! Check if device limit reached
                IF (global_struct_meta_mgr%meta_list(i)%device_count >= IF_MAX_DEVICES_PER_META) THEN
                    status%status_code = IF_STATUS_ERROR
                    status%message = "Maximum number of device associations reached"
                    CALL log_error("StructMetaData", TRIM(status%message))
                    RETURN
                END IF
                
                ! Create new device association
                CALL get_timestamp(association_time)
                new_device%device_id = TRIM(device_id)
                new_device%device_name = TRIM(device_name)
                new_device%device_type = TRIM(device_type)
                new_device%location = TRIM(location)
                new_device%is_primary_device = is_primary
                new_device%association_time = TRIM(association_time)
                
                ! If primary device, reset other primary flags
                IF (is_primary) THEN
                    DO j = 1, global_struct_meta_mgr%meta_list(i)%device_count
                        global_struct_meta_mgr%meta_list(i)%associated_devices(j)%is_primary_device = .FALSE.
                    END DO
                END IF
                
                ! Add to device list
                global_struct_meta_mgr%meta_list(i)%device_count = global_struct_meta_mgr%meta_list(i)%device_count + 1
                global_struct_meta_mgr%meta_list(i)%associated_devices( &
                    global_struct_meta_mgr%meta_list(i)%device_count) = new_device
                global_struct_meta_mgr%total_device_associations = global_struct_meta_mgr%total_device_associations + 1
                
                status%status_code = IF_STATUS_OK
                CALL log_info("StructMetaData", "Added device '" // TRIM(device_id) // &
                    "' association to data ID '" // TRIM(data_id) // "'")
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_add_device_association
    
    ! ==========================================================================
    ! Subroutine: Remove Device Association from Metadata
    ! ==========================================================================
    SUBROUTINE struct_meta_remove_device_association(data_id, device_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id          ! Data ID (unique identifier)
        CHARACTER(LEN=*), INTENT(IN) :: device_id        ! Device ID to remove
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j, remove_idx
        LOGICAL :: found

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                found = .FALSE.
                remove_idx = 0
                
                ! Find device to remove
                DO j = 1, global_struct_meta_mgr%meta_list(i)%device_count
                    IF (TRIM(global_struct_meta_mgr%meta_list(i)%associated_devices(j)%device_id) == TRIM(device_id)) THEN
                        remove_idx = j
                        found = .TRUE.
                        EXIT
                    END IF
                END DO
                
                IF (.NOT. found) THEN
                    status%status_code = IF_STATUS_NOT_FOUND
                    status%message = "Device association not found"
                    CALL log_warn("StructMetaData", TRIM(status%message))
                    RETURN
                END IF
                
                ! Shift remaining devices
                IF (remove_idx < global_struct_meta_mgr%meta_list(i)%device_count) THEN
                    DO j = remove_idx, global_struct_meta_mgr%meta_list(i)%device_count - 1
                        global_struct_meta_mgr%meta_list(i)%associated_devices(j) = &
                            global_struct_meta_mgr%meta_list(i)%associated_devices(j+1)
                    END DO
                END IF
                
                ! Decrement counters
                global_struct_meta_mgr%meta_list(i)%device_count = global_struct_meta_mgr%meta_list(i)%device_count - 1
                global_struct_meta_mgr%total_device_associations = global_struct_meta_mgr%total_device_associations - 1
                
                status%status_code = IF_STATUS_OK
                CALL log_info("StructMetaData", "Removed device '" // TRIM(device_id) // &
                    "' association from data ID '" // TRIM(data_id) // "'")
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_remove_device_association
    
    ! ==========================================================================
    ! Subroutine: Get Device Association Info
    ! ==========================================================================
    SUBROUTINE struct_meta_get_device_association(data_id, device_id, device_info, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id          ! Data ID (unique identifier)
        CHARACTER(LEN=*), INTENT(IN) :: device_id        ! Device ID
        TYPE(DeviceInfoType), INTENT(OUT) :: device_info ! Output device info
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j
        LOGICAL :: found

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                found = .FALSE.
                ! Search for device
                DO j = 1, global_struct_meta_mgr%meta_list(i)%device_count
                    IF (TRIM(global_struct_meta_mgr%meta_list(i)%associated_devices(j)%device_id) == TRIM(device_id)) THEN
                        device_info = global_struct_meta_mgr%meta_list(i)%associated_devices(j)
                        found = .TRUE.
                        EXIT
                    END IF
                END DO
                
                IF (.NOT. found) THEN
                    status%status_code = IF_STATUS_NOT_FOUND
                    status%message = "Device association not found"
                    CALL log_warn("StructMetaData", TRIM(status%message))
                    RETURN
                END IF
                
                status%status_code = IF_STATUS_OK
                CALL log_info("StructMetaData", "Retrieved device association info for '" // &
                    TRIM(device_id) // "' from data ID '" // TRIM(data_id) // "'")
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_get_device_association
    
    ! ==========================================================================
    ! Subroutine: Get All Device Associations for Metadata
    ! ==========================================================================
    SUBROUTINE struct_meta_get_all_device_associations(data_id, device_list, device_count, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id                ! Data ID (unique identifier)
        TYPE(DeviceInfoType), DIMENSION(:), INTENT(OUT) :: device_list ! Output device list
        INTEGER(i4), INTENT(OUT) :: device_count                  ! Number of devices
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Array size
        IF (SIZE(device_list) < IF_MAX_DEVICES_PER_META) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Output array size insufficient for device associations"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                device_count = global_struct_meta_mgr%meta_list(i)%device_count
                
                ! Copy device associations
                DO j = 1, device_count
                    device_list(j) = global_struct_meta_mgr%meta_list(i)%associated_devices(j)
                END DO
                
                status%status_code = IF_STATUS_OK
                CALL log_info("StructMetaData", "Retrieved all " // TRIM(INT_TO_STR(device_count)) // &
                    " device associations for data ID '" // TRIM(data_id) // "'")
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
    END SUBROUTINE struct_meta_get_all_device_associations
    
    ! ==========================================================================
    ! Function: Check if Device is Associated with Metadata
    ! ==========================================================================
    LOGICAL FUNCTION struct_meta_is_device_associated(data_id, device_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id          ! Data ID (unique identifier)
        CHARACTER(LEN=*), INTENT(IN) :: device_id        ! Device ID
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            struct_meta_is_device_associated = .FALSE.
            RETURN
        END IF

        ! Find metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                
                ! Search for device
                DO j = 1, global_struct_meta_mgr%meta_list(i)%device_count
                    IF (TRIM(global_struct_meta_mgr%meta_list(i)%associated_devices(j)%device_id) == TRIM(device_id)) THEN
                        status%status_code = IF_STATUS_OK
                        struct_meta_is_device_associated = .TRUE.
                        RETURN
                    END IF
                END DO
                
                status%status_code = IF_STATUS_OK
                struct_meta_is_device_associated = .FALSE.
                RETURN
            END IF
        END DO

        ! Metadata not found
        status%status_code = IF_STATUS_META_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("StructMetaData", TRIM(status%message))
        struct_meta_is_device_associated = .FALSE.
    END FUNCTION struct_meta_is_device_associated
    
    ! ==========================================================================
    ! Subroutine: Get Overall Structured Metadata Statistics
    ! ==========================================================================
    SUBROUTINE get_struct_meta_statistics(total_entries, valid_entries, max_capacity, &
                                        total_versions, total_device_associations, status)
        INTEGER(i4), INTENT(OUT) :: total_entries               ! Total number of metadata entries
        INTEGER(i4), INTENT(OUT) :: valid_entries               ! Number of valid metadata entries
        INTEGER(i4), INTENT(OUT) :: max_capacity                ! Maximum capacity of manager
        INTEGER(i4), INTENT(OUT) :: total_versions              ! Total number of versions created
        INTEGER(i4), INTENT(OUT) :: total_device_associations   ! Total number of device associations
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Get manager statistics
        max_capacity = global_struct_meta_mgr%max_meta_count
        total_entries = global_struct_meta_mgr%current_meta_count
        total_versions = global_struct_meta_mgr%total_versions
        total_device_associations = global_struct_meta_mgr%total_device_associations

        ! Count valid entries (more accurate count)
        valid_entries = 0
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                valid_entries = valid_entries + 1
            END IF
        END DO

        status%status_code = IF_STATUS_OK
        CALL log_info("StructMetaData", "Retrieved metadata statistics: total=" // TRIM(INT_TO_STR(total_entries)) // &
                     ", valid=" // TRIM(INT_TO_STR(valid_entries)) // ", max_capacity=" // TRIM(INT_TO_STR(max_capacity)))
    END SUBROUTINE get_struct_meta_statistics
    
    ! ==========================================================================
    ! Subroutine: Get Structured Metadata Type Statistics
    ! ==========================================================================
    SUBROUTINE get_struct_meta_type_statistics(type_counts, type_sizes, unique_types, status)
        INTEGER, DIMENSION(:), INTENT(OUT) :: type_counts  ! Array to store count of each data type
        INTEGER(KIND=8), DIMENSION(:), INTENT(OUT) :: type_sizes  ! Array to store total size of each data type
        INTEGER(i4), INTENT(OUT) :: unique_types               ! Number of unique data types
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, max_type_idx, data_type
        INTEGER, DIMENSION(:), ALLOCATABLE :: seen_types   ! Array to track seen data types

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check: Array size
        max_type_idx = SIZE(type_counts)
        IF (max_type_idx < 20) THEN  ! Assume maximum data type value is less than 20
            status%status_code = IF_STATUS_ERROR
            status%message = "Output arrays size insufficient for type statistics"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Initialize output arrays
        type_counts = 0
        type_sizes = 0

        ! Allocate temporary array to track seen types
        ALLOCATE(seen_types(global_struct_meta_mgr%max_meta_count), STAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate memory for type statistics"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF
        seen_types = 0

        ! Count types and sizes
        unique_types = 0
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                data_type = global_struct_meta_mgr%meta_list(i)%data_type
                
                ! Ensure data type index is valid
                IF (data_type >= 0 .AND. data_type < max_type_idx) THEN
                    ! Update counts and sizes
                    type_counts(data_type + 1) = type_counts(data_type + 1) + 1
                    type_sizes(data_type + 1) = type_sizes(data_type + 1) + global_struct_meta_mgr%meta_list(i)%total_size
                    
                    ! Check if this is a new unique type
                    IF (type_counts(data_type + 1) == 1) THEN
                        unique_types = unique_types + 1
                        seen_types(unique_types) = data_type
                    END IF
                END IF
            END IF
        END DO

        ! Clean up
        DEALLOCATE(seen_types)
        
        status%status_code = IF_STATUS_OK
        CALL log_info("StructMetaData", "Retrieved metadata type statistics: " // TRIM(INT_TO_STR(unique_types)) // " unique types")
    END SUBROUTINE get_struct_meta_type_statistics
    
    ! ==========================================================================
    ! Subroutine: Get Structured Metadata Storage Statistics
    ! ==========================================================================
    SUBROUTINE get_struct_meta_storage_statistics(total_storage, chunked_count, constant_count, &
                                               avg_chunk_size, avg_element_count, status)
        INTEGER(KIND=8), INTENT(OUT) :: total_storage        ! Total storage used by all metadata
        INTEGER(i4), INTENT(OUT) :: chunked_count                ! Number of chunked metadata entries
        INTEGER(i4), INTENT(OUT) :: constant_count               ! Number of constant metadata entries
        INTEGER(KIND=8), INTENT(OUT) :: avg_chunk_size       ! Average chunk size
        INTEGER(KIND=8), INTENT(OUT) :: avg_element_count    ! Average number of elements
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, valid_count
        INTEGER(KIND=8) :: total_chunk_size, total_elements

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Initialize counters
        total_storage = 0
        chunked_count = 0
        constant_count = 0
        total_chunk_size = 0
        total_elements = 0
        valid_count = 0

        ! Calculate storage statistics
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                valid_count = valid_count + 1
                total_storage = total_storage + global_struct_meta_mgr%meta_list(i)%total_size
                total_elements = total_elements + global_struct_meta_mgr%meta_list(i)%total_elements
                
                IF (global_struct_meta_mgr%meta_list(i)%is_chunked) THEN
                    chunked_count = chunked_count + 1
                    total_chunk_size = total_chunk_size + global_struct_meta_mgr%meta_list(i)%chunk_size
                END IF
                
                IF (global_struct_meta_mgr%meta_list(i)%is_constant) THEN
                    constant_count = constant_count + 1
                END IF
            END IF
        END DO

        ! Calculate averages
        avg_chunk_size = 0
        avg_element_count = 0
        
        IF (valid_count > 0) THEN
            avg_element_count = total_elements / valid_count
        END IF
        
        IF (chunked_count > 0) THEN
            avg_chunk_size = total_chunk_size / chunked_count
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("StructMetaData", "Retrieved storage statistics: total=" // TRIM(INT_TO_STR(INT(total_storage))) // &
                     " bytes, chunked=" // TRIM(INT_TO_STR(chunked_count)) // ", constant=" // TRIM(INT_TO_STR(constant_count)))
    END SUBROUTINE get_struct_meta_storage_statistics
    
    ! ==========================================================================
    ! Subroutine: Get Structured Metadata Operation Statistics
    ! ==========================================================================
    SUBROUTINE get_struct_meta_operation_statistics(total_queries, total_updates, total_validations, &
                                                  total_errors, status)
        INTEGER(i4), INTENT(OUT) :: total_queries               ! Total number of queries executed
        INTEGER(i4), INTENT(OUT) :: total_updates               ! Total number of updates performed
        INTEGER(i4), INTENT(OUT) :: total_validations           ! Total number of validations performed
        INTEGER(i4), INTENT(OUT) :: total_errors                ! Total number of errors encountered
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Get operation statistics
        total_queries = global_struct_meta_mgr%total_queries
        total_updates = global_struct_meta_mgr%total_updates
        total_validations = global_struct_meta_mgr%total_validations
        total_errors = global_struct_meta_mgr%total_errors

        status%status_code = IF_STATUS_OK
        CALL log_info("StructMetaData", "Retrieved operation statistics: queries=" // TRIM(INT_TO_STR(total_queries)) // &
                     ", updates=" // TRIM(INT_TO_STR(total_updates)) // ", validations=" // TRIM(INT_TO_STR(total_validations)))
    END SUBROUTINE get_struct_meta_operation_statistics
    
    ! ==========================================================================
    ! Subroutine: Get Structured Metadata Device Statistics
    ! ==========================================================================
    SUBROUTINE get_struct_meta_device_statistics(total_associations, avg_devices_per_meta, &
                                               device_type_counts, unique_devices, status)
        INTEGER(i4), INTENT(OUT) :: total_associations          ! Total number of device associations
        REAL, INTENT(OUT) :: avg_devices_per_meta           ! Average devices per metadata entry
        INTEGER, DIMENSION(:), INTENT(OUT) :: device_type_counts ! Count of devices by type
        INTEGER(i4), INTENT(OUT) :: unique_devices              ! Number of unique devices
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j, valid_count, device_idx
        CHARACTER(LEN=IF_MAX_DEVICE_ID_LENGTH), DIMENSION(:), ALLOCATABLE :: seen_device_ids
        LOGICAL :: is_new_device

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check: Array size for device types (assuming 4 device types: GPU, CPU, TPU, Storage)
        IF (SIZE(device_type_counts) < 4) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Output array size insufficient for device type statistics"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Initialize counters
        total_associations = global_struct_meta_mgr%total_device_associations
        valid_count = 0
        device_type_counts = 0
        unique_devices = 0

        ! Allocate temporary array to track seen devices
        ALLOCATE(seen_device_ids(total_associations), STAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate memory for device statistics"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Calculate device statistics
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                valid_count = valid_count + 1
                
                ! Count devices for this metadata
                DO j = 1, global_struct_meta_mgr%meta_list(i)%device_count
                    ! Track unique devices
                    is_new_device = .TRUE.
                    DO device_idx = 1, unique_devices
                        IF (TRIM(seen_device_ids(device_idx)) == &
                            TRIM(global_struct_meta_mgr%meta_list(i)%associated_devices(j)%device_id)) THEN
                            is_new_device = .FALSE.
                            EXIT
                        END IF
                    END DO
                    
                    IF (is_new_device .AND. unique_devices < total_associations) THEN
                        unique_devices = unique_devices + 1
                        seen_device_ids(unique_devices) = TRIM(global_struct_meta_mgr%meta_list(i)%associated_devices(j)%device_id)
                    END IF
                    
                    ! Count by device type
                    SELECT CASE (TRIM(global_struct_meta_mgr%meta_list(i)%associated_devices(j)%device_type))
                        CASE ("GPU")
                            device_type_counts(1) = device_type_counts(1) + 1
                        CASE ("CPU")
                            device_type_counts(2) = device_type_counts(2) + 1
                        CASE ("TPU")
                            device_type_counts(3) = device_type_counts(3) + 1
                        CASE ("Storage")
                            device_type_counts(4) = device_type_counts(4) + 1
                    END SELECT
                END DO
            END IF
        END DO

        ! Calculate average devices per metadata
        IF (valid_count > 0) THEN
            avg_devices_per_meta = REAL(total_associations) / REAL(valid_count)
        ELSE
            avg_devices_per_meta = 0.0
        END IF

        ! Clean up
        DEALLOCATE(seen_device_ids)
        
        status%status_code = IF_STATUS_OK
        CALL log_info("StructMetaData", "Retrieved device statistics: total_associations=" // &
            TRIM(INT_TO_STR(total_associations)) // ", unique_devices=" // TRIM(INT_TO_STR(unique_devices)) // &
            ", avg_devices_per_meta=" // TRIM(REAL_TO_STR(avg_devices_per_meta)))
    END SUBROUTINE get_struct_meta_device_statistics
    
    ! ==========================================================================
    ! Subroutine: Export a single metadata entry to a file
    ! ==========================================================================
    SUBROUTINE struct_meta_export(meta_id, file_path, file_format, status)
        CHARACTER(LEN=*), INTENT(IN) :: meta_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(IN) :: file_format
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx
        CHARACTER(LEN=IF_MAX_FILE_PATH_LENGTH) :: local_file_path
        LOGICAL :: file_exists

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Validate file path length
        IF (LEN_TRIM(file_path) > IF_MAX_FILE_PATH_LENGTH) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "File path exceeds maximum allowed length"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF
        local_file_path = TRIM(file_path)

        ! Validate file format
        IF (file_format < IF_FORMAT_JSON .OR. file_format > IF_FORMAT_BINARY) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Unsupported file format specified"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find the metadata entry
        idx = find_struct_meta_by_id(meta_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_META_NOT_FOUND
            status%message = "Metadata not found: " // TRIM(meta_id)
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Check if metadata is valid
        IF (.NOT. global_struct_meta_mgr%meta_list(idx)%is_valid) THEN
            status%status_code = IF_STATUS_META_NOT_FOUND
            status%message = "Metadata is invalid or deleted: " // TRIM(meta_id)
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Check if file already exists (prevent accidental overwriting)
        INQUIRE(FILE=TRIM(local_file_path), EXIST=file_exists)
        IF (file_exists) THEN
            CALL log_warn("StructMetaData", "Warning: Overwriting existing file: " // TRIM(local_file_path))
        END IF

        ! Export based on format
        SELECT CASE (file_format)
            CASE (IF_FORMAT_JSON)
                CALL export_meta_to_json(meta_id, local_file_path, status)
            CASE (IF_FORMAT_XML)
                CALL export_meta_to_xml(meta_id, local_file_path, status)
            CASE (IF_FORMAT_CSV)
                CALL export_meta_to_csv(meta_id, local_file_path, status)
            CASE (IF_FORMAT_BINARY)
                CALL export_meta_to_binary(meta_id, local_file_path, status)
        END SELECT

        ! Check if export was successful
        IF (status%status_code /= IF_STATUS_OK) THEN
            RETURN
        END IF

        CALL log_info("StructMetaData", "Successfully exported metadata to " // TRIM(local_file_path))
    END SUBROUTINE struct_meta_export
    
    ! ==========================================================================
    ! Subroutine: Export all metadata entries to a file
    ! ==========================================================================
    SUBROUTINE struct_meta_export_all(file_path, file_format, status)
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(IN) :: file_format
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, valid_count
        CHARACTER(LEN=IF_MAX_FILE_PATH_LENGTH) :: local_file_path
        LOGICAL :: file_exists

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Validate file path length
        IF (LEN_TRIM(file_path) > IF_MAX_FILE_PATH_LENGTH) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "File path exceeds maximum allowed length"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF
        local_file_path = TRIM(file_path)

        ! Validate file format
        IF (file_format < IF_FORMAT_JSON .OR. file_format > IF_FORMAT_BINARY) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Unsupported file format specified"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Count valid metadata entries
        valid_count = 0
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                valid_count = valid_count + 1
            END IF
        END DO

        IF (valid_count == 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "No valid metadata entries to export"
            CALL log_warn("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Check if file already exists (prevent accidental overwriting)
        INQUIRE(FILE=TRIM(local_file_path), EXIST=file_exists)
        IF (file_exists) THEN
            CALL log_warn("StructMetaData", "Warning: Overwriting existing file: " // TRIM(local_file_path))
        END IF

        ! Export based on format
        SELECT CASE (file_format)
            CASE (IF_FORMAT_JSON)
                CALL export_all_meta_to_json(local_file_path, status)
            CASE (IF_FORMAT_XML)
                CALL export_all_meta_to_xml(local_file_path, status)
            CASE (IF_FORMAT_CSV)
                CALL export_all_meta_to_csv(local_file_path, status)
            CASE (IF_FORMAT_BINARY)
                CALL export_all_meta_to_binary(local_file_path, status)
        END SELECT

        ! Check if export was successful
        IF (status%status_code /= IF_STATUS_OK) THEN
            RETURN
        END IF

        CALL log_info("StructMetaData", "Successfully exported " // TRIM(INT_TO_STR(valid_count)) // &
                     " metadata entries to " // TRIM(local_file_path))
    END SUBROUTINE struct_meta_export_all
    
    ! ==========================================================================
    ! Subroutine: Import a metadata entry from a file
    ! ==========================================================================
    SUBROUTINE struct_meta_import(file_path, file_format, imported_meta_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(IN) :: file_format
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH), INTENT(OUT) :: imported_meta_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_FILE_PATH_LENGTH) :: local_file_path
        LOGICAL :: file_exists

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Validate file path length
        IF (LEN_TRIM(file_path) > IF_MAX_FILE_PATH_LENGTH) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "File path exceeds maximum allowed length"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF
        local_file_path = TRIM(file_path)

        ! Validate file format
        IF (file_format < IF_FORMAT_JSON .OR. file_format > IF_FORMAT_BINARY) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Unsupported file format specified"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Check if file exists
        INQUIRE(FILE=TRIM(local_file_path), EXIST=file_exists)
        IF (.NOT. file_exists) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Import file not found: " // TRIM(local_file_path)
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Import based on format
        imported_meta_id = ""
        SELECT CASE (file_format)
            CASE (IF_FORMAT_JSON)
                CALL import_meta_from_json(local_file_path, imported_meta_id, status)
            CASE (IF_FORMAT_XML)
                CALL import_meta_from_xml(local_file_path, imported_meta_id, status)
            CASE (IF_FORMAT_CSV)
                CALL import_meta_from_csv(local_file_path, imported_meta_id, status)
            CASE (IF_FORMAT_BINARY)
                CALL import_meta_from_binary(local_file_path, imported_meta_id, status)
        END SELECT

        ! Check if import was successful
        IF (status%status_code /= IF_STATUS_OK) THEN
            RETURN
        END IF

        CALL log_info("StructMetaData", "Successfully imported metadata from " // TRIM(local_file_path) // &
                     " with ID " // TRIM(imported_meta_id))
    END SUBROUTINE struct_meta_import
    
    ! ==========================================================================
    ! Subroutine: Import all metadata entries from a file
    ! ==========================================================================
    SUBROUTINE struct_meta_import_all(file_path, file_format, imported_count, status)
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(IN) :: file_format
        INTEGER(i4), INTENT(OUT) :: imported_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_FILE_PATH_LENGTH) :: local_file_path
        LOGICAL :: file_exists

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Validate file path length
        IF (LEN_TRIM(file_path) > IF_MAX_FILE_PATH_LENGTH) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "File path exceeds maximum allowed length"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF
        local_file_path = TRIM(file_path)

        ! Validate file format
        IF (file_format < IF_FORMAT_JSON .OR. file_format > IF_FORMAT_BINARY) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Unsupported file format specified"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Check if file exists
        INQUIRE(FILE=TRIM(local_file_path), EXIST=file_exists)
        IF (.NOT. file_exists) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Import file not found: " // TRIM(local_file_path)
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Import based on format
        imported_count = 0
        SELECT CASE (file_format)
            CASE (IF_FORMAT_JSON)
                CALL import_all_meta_from_json(local_file_path, imported_count, status)
            CASE (IF_FORMAT_XML)
                CALL import_all_meta_from_xml(local_file_path, imported_count, status)
            CASE (IF_FORMAT_CSV)
                CALL import_all_meta_from_csv(local_file_path, imported_count, status)
            CASE (IF_FORMAT_BINARY)
                CALL import_all_meta_from_binary(local_file_path, imported_count, status)
        END SELECT

        ! Check if import was successful
        IF (status%status_code /= IF_STATUS_OK) THEN
            RETURN
        END IF

        CALL log_info("StructMetaData", "Successfully imported " // TRIM(INT_TO_STR(imported_count)) // &
                     " metadata entries from " // TRIM(local_file_path))
    END SUBROUTINE struct_meta_import_all
    
    ! ==========================================================================
    ! Subroutine: Batch import metadata entries from multiple files
    ! ==========================================================================
    SUBROUTINE struct_meta_batch_import(file_paths, file_format, imported_count, status)
        CHARACTER(LEN=*), DIMENSION(:), INTENT(IN) :: file_paths
        INTEGER(i4), INTENT(IN) :: file_format
        INTEGER(i4), INTENT(OUT) :: imported_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(ErrorStatusType) :: file_status
        INTEGER(i4) :: i, num_files
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH) :: temp_meta_id

        CALL init_error_status(status)

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Validate file format
        IF (file_format < IF_FORMAT_JSON .OR. file_format > IF_FORMAT_BINARY) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Unsupported file format specified"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Get number of files to import
        num_files = SIZE(file_paths)
        IF (num_files <= 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "No files provided for batch import"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Initialize counter
        imported_count = 0

        ! Process each file
        DO i = 1, num_files
            ! Import a single file
            CALL struct_meta_import(file_paths(i), file_format, temp_meta_id, file_status)
            
            ! Check if import was successful or if it was a duplicate (which is acceptable)
            IF (file_status%status_code == IF_STATUS_OK .OR. file_status%status_code == IF_STATUS_META_EXISTS) THEN
                imported_count = imported_count + 1
                ! Log even if it's a duplicate
                IF (file_status%status_code == IF_STATUS_META_EXISTS) THEN
                    CALL log_info("StructMetaData", "File " // TRIM(INT_TO_STR(i)) // "/" // TRIM(INT_TO_STR(num_files)) // &
                                 ": Duplicate metadata, skipped: " // TRIM(file_paths(i)))
                ELSE
                    CALL log_info("StructMetaData", "File " // TRIM(INT_TO_STR(i)) // "/" // TRIM(INT_TO_STR(num_files)) // &
                                 ": Successfully imported: " // TRIM(file_paths(i)))
                END IF
            ELSE
                ! Log error but continue with other files
                CALL log_error("StructMetaData", "File " // TRIM(INT_TO_STR(i)) // "/" // TRIM(INT_TO_STR(num_files)) // &
                              ": Failed to import: " // TRIM(file_paths(i)) // ", Error: " // TRIM(file_status%message))
            END IF
        END DO

        ! Set overall status based on import results
        IF (imported_count == 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Failed to import any metadata entries from " // TRIM(INT_TO_STR(num_files)) // " files"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        ELSE IF (imported_count < num_files) THEN
            status%status_code = IF_STATUS_OK
            status%message = "Partially successful import: " // TRIM(INT_TO_STR(imported_count)) // &
                            " of " // TRIM(INT_TO_STR(num_files)) // " files imported"
            CALL log_warn("StructMetaData", TRIM(status%message))
        ELSE
            status%status_code = IF_STATUS_OK
            status%message = "Successfully imported all " // TRIM(INT_TO_STR(num_files)) // " files"
            CALL log_info("StructMetaData", TRIM(status%message))
        END IF
    END SUBROUTINE struct_meta_batch_import
    
    ! ==========================================================================
    ! Format-specific export helper functions (JSON, XML, CSV, Binary)
    ! ==========================================================================
   ! ==========================================================================
    ! Subroutine: export_meta_to_json
    ! Function: Export a single metadata entry to JSON format
    ! ==========================================================================
    SUBROUTINE export_meta_to_json(meta_id, file_path, status)
        ! This is a placeholder for the actual JSON export implementation
        ! In a real implementation, you would use a JSON library or write custom JSON generation code
        CHARACTER(LEN=*), INTENT(IN) :: meta_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx
        INTEGER(i4) :: file_unit

        CALL init_error_status(status)
        idx = find_struct_meta_by_id(meta_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_META_NOT_FOUND
            status%message = "Metadata not found for JSON export"
            RETURN
        END IF

        ! In a real implementation, this would write proper JSON
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', IOSTAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for writing (stat=", status%io_stat
            RETURN
        END IF

        ! Write simple JSON structure as an example
        WRITE(file_unit, '(A)') '{"'
        ! Write simple JSON structure
        WRITE(file_unit, '(A)') '  "metadata": {'
        WRITE(file_unit, '(A)') '    "data_id": "' // TRIM(global_struct_meta_mgr%meta_list(idx)%data_id) // '",'
        WRITE(file_unit, '(A)') '    "var_name": "' // TRIM(global_struct_meta_mgr%meta_list(idx)%var_name) // '",'
        WRITE(file_unit, '(A)') '    "data_type": ' // TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%data_type)) // ','
        WRITE(file_unit, '(A)') '    "dimensions": [' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(1))) // ', ' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(2))) // ', ' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(3))) // ', ' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(4))) // '],'
        WRITE(file_unit, '(A)') '    "total_size": ' // &
            TRIM(INT_TO_STR(INT(global_struct_meta_mgr%meta_list(idx)%total_size))) // ','
        IF (global_struct_meta_mgr%meta_list(idx)%is_chunked) THEN
            WRITE(file_unit, '(A)') '    "is_chunked": "true",'
        ELSE
            WRITE(file_unit, '(A)') '    "is_chunked": "false",'
        END IF
        IF (global_struct_meta_mgr%meta_list(idx)%is_constant) THEN
            WRITE(file_unit, '(A)') '    "is_constant": "true"'
        ELSE
            WRITE(file_unit, '(A)') '    "is_constant": "false"'
        END IF
        WRITE(file_unit, '(A)') '  }'
        WRITE(file_unit, '(A)') '}'

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE export_meta_to_json

    ! ==========================================================================
    ! Subroutine: export_all_meta_to_json
    ! Function: Export all metadata entries to JSON format
    ! ==========================================================================
    SUBROUTINE export_all_meta_to_json(file_path, status)
        ! This is a placeholder for the actual JSON export implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, valid_count, file_unit, first_entry

        CALL init_error_status(status)

        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', IOSTAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for writing (stat=", status%io_stat
            RETURN
        END IF

        ! Write JSON array header
        WRITE(file_unit, '(A)') '{"'
        WRITE(file_unit, '(A)') '  "metadata_entries": ['

        ! Write each metadata entry
        first_entry = 1
        valid_count = 0
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                valid_count = valid_count + 1
                
                ! Add comma if not first entry
                IF (first_entry == 0) THEN
                    WRITE(file_unit, '(A)') ','
                ELSE
                    first_entry = 0
                END IF
                
                ! Write entry JSON
                WRITE(file_unit, '(A)') '    {'
                WRITE(file_unit, '(A)') '      "data_id": "' // TRIM(global_struct_meta_mgr%meta_list(i)%data_id) // '",'
                WRITE(file_unit, '(A)') '      "var_name": "' // TRIM(global_struct_meta_mgr%meta_list(i)%var_name) // '",'
                WRITE(file_unit, '(A)') '      "data_type": ' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%data_type)) // ','
                WRITE(file_unit, '(A)') '      "dimensions": [' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(1))) // ', ' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(2))) // ', ' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(3))) // ', ' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(4))) // '],'
                WRITE(file_unit, '(A)') '      "total_size": ' // &
                    TRIM(INT_TO_STR(INT(global_struct_meta_mgr%meta_list(i)%total_size))) // ','
                IF (global_struct_meta_mgr%meta_list(i)%is_chunked) THEN
                    WRITE(file_unit, '(A)') '      "is_chunked": "true",'
                ELSE
                    WRITE(file_unit, '(A)') '      "is_chunked": "false",'
                END IF
                IF (global_struct_meta_mgr%meta_list(i)%is_constant) THEN
                    WRITE(file_unit, '(A)') '      "is_constant": "true"'
                ELSE
                    WRITE(file_unit, '(A)') '      "is_constant": "false"'
                END IF
                WRITE(file_unit, '(A)') '    }'
            END IF
        END DO

        ! Write JSON array footer
        WRITE(file_unit, '(A)') '  ]'
        WRITE(file_unit, '(A)') '}'

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE export_all_meta_to_json

    SUBROUTINE export_meta_to_xml(meta_id, file_path, status)
        ! This is a placeholder for the actual XML export implementation
        CHARACTER(LEN=*), INTENT(IN) :: meta_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx, file_unit

        CALL init_error_status(status)
        idx = find_struct_meta_by_id(meta_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_META_NOT_FOUND
            status%message = "Metadata not found for XML export"
            RETURN
        END IF

        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', IOSTAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for writing (stat=", status%io_stat
            RETURN
        END IF

        ! Write simple XML structure as an example
        WRITE(file_unit, '(A)') '<?xml version="1.0" encoding="UTF-8"?>'
        WRITE(file_unit, '(A)') '<metadata>'
        WRITE(file_unit, '(A)') '  <data_id>' // TRIM(global_struct_meta_mgr%meta_list(idx)%data_id) // '</data_id>'
        WRITE(file_unit, '(A)') '  <var_name>' // TRIM(global_struct_meta_mgr%meta_list(idx)%var_name) // '</var_name>'
        WRITE(file_unit, '(A)') '  <data_type>' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%data_type)) // '</data_type>'
        WRITE(file_unit, '(A)') '  <dimensions>'
        WRITE(file_unit, '(A)') '    <dim1>' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(1))) // '</dim1>'
        WRITE(file_unit, '(A)') '    <dim2>' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(2))) // '</dim2>'
        WRITE(file_unit, '(A)') '    <dim3>' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(3))) // '</dim3>'
        WRITE(file_unit, '(A)') '    <dim4>' // &
            TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(4))) // '</dim4>'
        WRITE(file_unit, '(A)') '  </dimensions>'
        WRITE(file_unit, '(A)') '  <total_size>' // &
            TRIM(INT_TO_STR(INT(global_struct_meta_mgr%meta_list(idx)%total_size))) // '</total_size>'
        IF (global_struct_meta_mgr%meta_list(idx)%is_chunked) THEN
            WRITE(file_unit, '(A)') '  <is_chunked>true</is_chunked>'
        ELSE
            WRITE(file_unit, '(A)') '  <is_chunked>false</is_chunked>'
        END IF
        IF (global_struct_meta_mgr%meta_list(idx)%is_constant) THEN
            WRITE(file_unit, '(A)') '  <is_constant>true</is_constant>'
        ELSE
            WRITE(file_unit, '(A)') '  <is_constant>false</is_constant>'
        END IF
        WRITE(file_unit, '(A)') '</metadata>'

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE export_meta_to_xml

    SUBROUTINE export_all_meta_to_xml(file_path, status)
        ! This is a placeholder for the actual XML export implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, file_unit

        CALL init_error_status(status)

        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', IOSTAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for writing (stat=", status%io_stat
            RETURN
        END IF

        ! Write XML root
        WRITE(file_unit, '(A)') '<?xml version="1.0" encoding="UTF-8"?>'
        WRITE(file_unit, '(A)') '<metadata_collection>'

        ! Write each metadata entry
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                WRITE(file_unit, '(A)') '  <metadata>'
                WRITE(file_unit, '(A)') '    <data_id>' // TRIM(global_struct_meta_mgr%meta_list(i)%data_id) // '</data_id>'
                WRITE(file_unit, '(A)') '    <var_name>' // TRIM(global_struct_meta_mgr%meta_list(i)%var_name) // '</var_name>'
                WRITE(file_unit, '(A)') '    <data_type>' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%data_type)) // '</data_type>'
                WRITE(file_unit, '(A)') '    <dimensions>'
                WRITE(file_unit, '(A)') '      <dim1>' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(1))) // '</dim1>'
                WRITE(file_unit, '(A)') '      <dim2>' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(2))) // '</dim2>'
                WRITE(file_unit, '(A)') '      <dim3>' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(3))) // '</dim3>'
                WRITE(file_unit, '(A)') '      <dim4>' // &
                    TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(4))) // '</dim4>'
                WRITE(file_unit, '(A)') '    </dimensions>'
                WRITE(file_unit, '(A)') '    <total_size>' // &
                    TRIM(INT_TO_STR(INT(global_struct_meta_mgr%meta_list(i)%total_size))) // '</total_size>'
                IF (global_struct_meta_mgr%meta_list(i)%is_chunked) THEN
                    WRITE(file_unit, '(A)') '    <is_chunked>true</is_chunked>'
                ELSE
                    WRITE(file_unit, '(A)') '    <is_chunked>false</is_chunked>'
                END IF
                IF (global_struct_meta_mgr%meta_list(i)%is_constant) THEN
                    WRITE(file_unit, '(A)') '    <is_constant>true</is_constant>'
                ELSE
                    WRITE(file_unit, '(A)') '    <is_constant>false</is_constant>'
                END IF
                WRITE(file_unit, '(A)') '  </metadata>'
            END IF
        END DO

        ! Write XML footer
        WRITE(file_unit, '(A)') '</metadata_collection>'

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE export_all_meta_to_xml

    SUBROUTINE export_meta_to_csv(meta_id, file_path, status)
        ! This is a placeholder for the actual CSV export implementation
        CHARACTER(LEN=*), INTENT(IN) :: meta_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx, file_unit

        CALL init_error_status(status)
        idx = find_struct_meta_by_id(meta_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_META_NOT_FOUND
            status%message = "Metadata not found for CSV export"
            RETURN
        END IF

        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', IOSTAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for writing (stat=", status%io_stat
            RETURN
        END IF

        ! Write CSV header and data
        WRITE(file_unit, '(A)') 'data_id,var_name,data_type,dim1,dim2,dim3,dim4,total_size,is_chunked,is_constant'
        WRITE(file_unit, '(A)') TRIM(global_struct_meta_mgr%meta_list(idx)%data_id) // ',' // &
                               TRIM(global_struct_meta_mgr%meta_list(idx)%var_name) // ',' // &
                               TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%data_type)) // ',' // &
                               TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(1))) // ',' // &
                               TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(2))) // ',' // &
                               TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(3))) // ',' // &
                               TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(idx)%dimensions(4))) // ',' // &
                               TRIM(INT_TO_STR(INT(global_struct_meta_mgr%meta_list(idx)%total_size))) // ',' // &
                               TRIM(INT_TO_STR(MERGE(1, 0, global_struct_meta_mgr%meta_list(idx)%is_chunked))) // ',' // &
                               TRIM(INT_TO_STR(MERGE(1, 0, global_struct_meta_mgr%meta_list(idx)%is_constant)))

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE export_meta_to_csv

    SUBROUTINE export_all_meta_to_csv(file_path, status)
        ! This is a placeholder for the actual CSV export implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, file_unit, first_line

        CALL init_error_status(status)

        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', IOSTAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for writing (stat=", status%io_stat
            RETURN
        END IF

        ! Write CSV header
        WRITE(file_unit, '(A)') 'data_id,var_name,data_type,dim1,dim2,dim3,dim4,total_size,is_chunked,is_constant'

        ! Write each metadata entry
        first_line = 1
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                WRITE(file_unit, '(A)') TRIM(global_struct_meta_mgr%meta_list(i)%data_id) // ',' // &
                                       TRIM(global_struct_meta_mgr%meta_list(i)%var_name) // ',' // &
                                       TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%data_type)) // ',' // &
                                       TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(1))) // ',' // &
                                       TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(2))) // ',' // &
                                       TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(3))) // ',' // &
                                       TRIM(INT_TO_STR(global_struct_meta_mgr%meta_list(i)%dimensions(4))) // ',' // &
                                       TRIM(INT_TO_STR(INT(global_struct_meta_mgr%meta_list(i)%total_size))) // ',' // &
                                       TRIM(INT_TO_STR(MERGE(1, 0, global_struct_meta_mgr%meta_list(i)%is_chunked))) // ',' // &
                                       TRIM(INT_TO_STR(MERGE(1, 0, global_struct_meta_mgr%meta_list(i)%is_constant)))
            END IF
        END DO

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE export_all_meta_to_csv

    SUBROUTINE export_meta_to_binary(meta_id, file_path, status)
        ! This is a placeholder for the actual binary export implementation
        CHARACTER(LEN=*), INTENT(IN) :: meta_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx, file_unit

        CALL init_error_status(status)
        idx = find_struct_meta_by_id(meta_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_META_NOT_FOUND
            status%message = "Metadata not found for binary export"
            RETURN
        END IF

        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', &
             FORM='UNFORMATTED', ACCESS='STREAM', IOSTAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for binary writing (stat=", status%io_stat
            RETURN
        END IF

        ! Write metadata fields individually to avoid I/O error with allocatable components
        ! Skip writing allocatable arrays (chunk_offsets, version_history)
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%data_id
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%var_name
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%storage_type
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%data_type
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%dimensions
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%valid_dim_count
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%element_size
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%total_elements
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%total_size
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%is_chunked
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%chunk_size
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%total_chunks
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%crc32
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%create_time
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%update_time
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%is_valid
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%is_constant
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%version_number
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%version_history_count
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%device_count
        WRITE(file_unit) global_struct_meta_mgr%meta_list(idx)%associated_devices

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE export_meta_to_binary

    SUBROUTINE export_all_meta_to_binary(file_path, status)
        ! This is a placeholder for the actual binary export implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, valid_count, file_unit

        CALL init_error_status(status)

        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', &
             FORM='UNFORMATTED', ACCESS='STREAM', IOSTAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for binary writing (stat=", status%io_stat
            RETURN
        END IF

        ! Count and write valid entries
        valid_count = 0
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                valid_count = valid_count + 1
            END IF
        END DO

        ! Write count first
        WRITE(file_unit) valid_count

        ! Write each valid metadata entry with individual fields
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                ! Skip writing allocatable arrays (chunk_offsets, version_history)
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%data_id
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%var_name
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%storage_type
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%data_type
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%dimensions
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%valid_dim_count
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%element_size
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%total_elements
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%total_size
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%is_chunked
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%chunk_size
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%total_chunks
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%crc32
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%create_time
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%update_time
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%is_valid
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%is_constant
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%version_number
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%version_history_count
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%device_count
                WRITE(file_unit) global_struct_meta_mgr%meta_list(i)%associated_devices
            END IF
        END DO

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE export_all_meta_to_binary

    ! ==========================================================================
    ! Format-specific import helper functions (JSON, XML, CSV, Binary)
    ! ==========================================================================
    SUBROUTINE import_meta_from_json(file_path, imported_meta_id, status)
        ! This is a placeholder for the actual JSON import implementation
        ! In a real implementation, you would use a JSON library or write custom JSON parsing code
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH), INTENT(OUT) :: imported_meta_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        ! In a real implementation, this would read and parse JSON from the file
        ! For this example, we'll just create a dummy metadata entry
        TYPE(StructMetaType) :: new_meta
        INTEGER(i4) :: file_unit, io_stat
        CHARACTER(LEN=1024) :: line

        CALL init_error_status(status)

        ! In a real implementation, this would read and parse JSON
        ! For this example, we'll just read the first line to verify file exists
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', IOSTAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for reading (stat=", io_stat
            RETURN
        END IF
        CLOSE(file_unit)

        ! Create a dummy metadata entry for demonstration
        ! In a real implementation, this would be populated from the JSON data
        new_meta%data_id = "IMPORTED_META_" // TRIM(INT_TO_STR(global_struct_meta_mgr%current_meta_count + 1))
        new_meta%var_name = "imported_variable"
        new_meta%data_type = IF_DATA_TYPE_DP  ! Assume double precision for this example
        new_meta%dimensions(1) = 10
        new_meta%dimensions(2) = 10
        new_meta%valid_dim_count = 2
        new_meta%element_size = 8  ! Double precision
        new_meta%total_elements = 100
        new_meta%total_size = 800
        new_meta%is_chunked = .FALSE.
        new_meta%is_constant = .FALSE.
        new_meta%is_valid = .TRUE.

        ! Add to manager
        CALL add_meta_to_manager(new_meta, imported_meta_id, status)
    END SUBROUTINE import_meta_from_json

    SUBROUTINE import_all_meta_from_json(file_path, imported_count, status)
        ! This is a placeholder for the actual JSON import implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(OUT) :: imported_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        ! In a real implementation, this would read and parse JSON array from the file
        INTEGER(i4) :: file_unit, io_stat

        CALL init_error_status(status)

        ! In a real implementation, this would read and parse JSON array
        ! For this example, we'll just create a few dummy metadata entries
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', IOSTAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for reading (stat=", io_stat
            RETURN
        END IF
        CLOSE(file_unit)

        ! Create a few dummy metadata entries for demonstration
        ! In a real implementation, these would be populated from the JSON data
        imported_count = 0
        CALL import_sample_metadata_entries(imported_count, status)
    END SUBROUTINE import_all_meta_from_json

    SUBROUTINE import_meta_from_xml(file_path, imported_meta_id, status)
        ! This is a placeholder for the actual XML import implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH), INTENT(OUT) :: imported_meta_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: file_unit, io_stat
        TYPE(StructMetaType) :: new_meta

        CALL init_error_status(status)

        ! In a real implementation, this would read and parse XML
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', IOSTAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for reading (stat=", io_stat
            RETURN
        END IF
        CLOSE(file_unit)

        ! Create a dummy metadata entry for demonstration
        new_meta%data_id = "IMPORTED_XML_" // TRIM(INT_TO_STR(global_struct_meta_mgr%current_meta_count + 1))
        new_meta%var_name = "imported_xml_variable"
        new_meta%data_type = IF_DATA_TYPE_INT  ! Assume integer for this example
        new_meta%dimensions(1) = 5
        new_meta%dimensions(2) = 5
        new_meta%valid_dim_count = 2
        new_meta%element_size = 4  ! Integer
        new_meta%total_elements = 25
        new_meta%total_size = 100
        new_meta%is_chunked = .FALSE.
        new_meta%is_constant = .FALSE.
        new_meta%is_valid = .TRUE.

        ! Add to manager
        CALL add_meta_to_manager(new_meta, imported_meta_id, status)
    END SUBROUTINE import_meta_from_xml

    SUBROUTINE import_all_meta_from_xml(file_path, imported_count, status)
        ! This is a placeholder for the actual XML import implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(OUT) :: imported_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: file_unit, io_stat

        CALL init_error_status(status)

        ! In a real implementation, this would read and parse XML collection
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', IOSTAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for reading (stat=", io_stat
            RETURN
        END IF
        CLOSE(file_unit)

        ! Create a few dummy metadata entries for demonstration
        imported_count = 0
        CALL import_sample_metadata_entries(imported_count, status)
    END SUBROUTINE import_all_meta_from_xml

    SUBROUTINE import_meta_from_csv(file_path, imported_meta_id, status)
        ! This is a placeholder for the actual CSV import implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH), INTENT(OUT) :: imported_meta_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: file_unit, io_stat
        TYPE(StructMetaType) :: new_meta

        CALL init_error_status(status)

        ! In a real implementation, this would read and parse CSV
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', IOSTAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for reading (stat=", io_stat
            RETURN
        END IF
        CLOSE(file_unit)

        ! Create a dummy metadata entry for demonstration
        new_meta%data_id = "IMPORTED_CSV_" // TRIM(INT_TO_STR(global_struct_meta_mgr%current_meta_count + 1))
        new_meta%var_name = "imported_csv_variable"
        new_meta%data_type = IF_DATA_TYPE_CHAR  ! Assume character for this example
        new_meta%dimensions(1) = 20
        new_meta%valid_dim_count = 1
        new_meta%element_size = 1  ! Character
        new_meta%total_elements = 20
        new_meta%total_size = 20
        new_meta%is_chunked = .FALSE.
        new_meta%is_constant = .FALSE.
        new_meta%is_valid = .TRUE.

        ! Add to manager
        CALL add_meta_to_manager(new_meta, imported_meta_id, status)
    END SUBROUTINE import_meta_from_csv

    SUBROUTINE import_all_meta_from_csv(file_path, imported_count, status)
        ! This is a placeholder for the actual CSV import implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(OUT) :: imported_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: file_unit, io_stat

        CALL init_error_status(status)

        ! In a real implementation, this would read and parse CSV records
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', IOSTAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for reading (stat=", io_stat
            RETURN
        END IF
        CLOSE(file_unit)

        ! Create a few dummy metadata entries for demonstration
        imported_count = 0
        CALL import_sample_metadata_entries(imported_count, status)
    END SUBROUTINE import_all_meta_from_csv

    SUBROUTINE import_meta_from_binary(file_path, imported_meta_id, status)
        ! This is a placeholder for the actual binary import implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH), INTENT(OUT) :: imported_meta_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(StructMetaType) :: imported_meta
        INTEGER(i4) :: file_unit, io_stat

        CALL init_error_status(status)

        ! Open file for binary reading
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', &
             FORM='UNFORMATTED', ACCESS='STREAM', IOSTAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for binary reading (stat=", io_stat
            RETURN
        END IF

        ! Read metadata fields individually to avoid I/O error with allocatable components
        ! Skip reading allocatable arrays (chunk_offsets, version_history)
        READ(file_unit) imported_meta%data_id
        READ(file_unit) imported_meta%var_name
        READ(file_unit) imported_meta%storage_type
        READ(file_unit) imported_meta%data_type
        READ(file_unit) imported_meta%dimensions
        READ(file_unit) imported_meta%valid_dim_count
        READ(file_unit) imported_meta%element_size
        READ(file_unit) imported_meta%total_elements
        READ(file_unit) imported_meta%total_size
        READ(file_unit) imported_meta%is_chunked
        READ(file_unit) imported_meta%chunk_size
        READ(file_unit) imported_meta%total_chunks
        READ(file_unit) imported_meta%crc32
        READ(file_unit) imported_meta%create_time
        READ(file_unit) imported_meta%update_time
        READ(file_unit) imported_meta%is_valid
        READ(file_unit) imported_meta%is_constant
        READ(file_unit) imported_meta%version_number
        READ(file_unit) imported_meta%version_history_count
        READ(file_unit) imported_meta%device_count
        READ(file_unit) imported_meta%associated_devices
        
        ! Ensure allocatable arrays are deallocated to avoid memory issues
        IF (ALLOCATED(imported_meta%chunk_offsets)) THEN
            DEALLOCATE(imported_meta%chunk_offsets)
        END IF
        IF (ALLOCATED(imported_meta%version_history)) THEN
            DEALLOCATE(imported_meta%version_history)
        END IF
        
        CLOSE(file_unit)

        ! Add to manager
        CALL add_meta_to_manager(imported_meta, imported_meta_id, status)
    END SUBROUTINE import_meta_from_binary

    SUBROUTINE import_all_meta_from_binary(file_path, imported_count, status)
        ! This is a placeholder for the actual binary import implementation
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(OUT) :: imported_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(StructMetaType) :: imported_meta
        INTEGER(i4) :: file_unit, io_stat, i
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH) :: temp_id

        CALL init_error_status(status)

        ! Open file for binary reading
        OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', &
             FORM='UNFORMATTED', ACCESS='STREAM', IOSTAT=io_stat)
        IF (io_stat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to open file for binary reading (stat=", io_stat
            RETURN
        END IF

        ! Read count first
        READ(file_unit) imported_count

        ! Read each metadata entry with individual fields
        DO i = 1, imported_count
            ! Read individual fields to avoid I/O error with allocatable components
            READ(file_unit) imported_meta%data_id
            READ(file_unit) imported_meta%var_name
            READ(file_unit) imported_meta%storage_type
            READ(file_unit) imported_meta%data_type
            READ(file_unit) imported_meta%dimensions
            READ(file_unit) imported_meta%valid_dim_count
            READ(file_unit) imported_meta%element_size
            READ(file_unit) imported_meta%total_elements
            READ(file_unit) imported_meta%total_size
            READ(file_unit) imported_meta%is_chunked
            READ(file_unit) imported_meta%chunk_size
            READ(file_unit) imported_meta%total_chunks
            READ(file_unit) imported_meta%crc32
            READ(file_unit) imported_meta%create_time
            READ(file_unit) imported_meta%update_time
            READ(file_unit) imported_meta%is_valid
            READ(file_unit) imported_meta%is_constant
            READ(file_unit) imported_meta%version_number
            READ(file_unit) imported_meta%version_history_count
            READ(file_unit) imported_meta%device_count
            READ(file_unit) imported_meta%associated_devices
            
            ! Ensure allocatable arrays are deallocated to avoid memory issues
            IF (ALLOCATED(imported_meta%chunk_offsets)) THEN
                DEALLOCATE(imported_meta%chunk_offsets)
            END IF
            IF (ALLOCATED(imported_meta%version_history)) THEN
                DEALLOCATE(imported_meta%version_history)
            END IF
            
            temp_id = TRIM(imported_meta%data_id)
            CALL add_meta_to_manager(imported_meta, temp_id, status)
            ! Continue even if one entry fails
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("StructMetaData", "Failed to add imported metadata entry " // TRIM(INT_TO_STR(i)))
                CALL init_error_status(status)  ! Reset status
            END IF
        END DO

        CLOSE(file_unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE import_all_meta_from_binary

    ! ==========================================================================
    ! Helper functions for import/export
    ! ==========================================================================
    SUBROUTINE add_meta_to_manager(new_meta, assigned_id, status)
        TYPE(StructMetaType), INTENT(IN) :: new_meta
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH), INTENT(OUT) :: assigned_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx

        CALL init_error_status(status)

        ! Check if ID already exists
        idx = find_struct_meta_by_id(new_meta%data_id)
        IF (idx /= 0) THEN
            status%status_code = IF_STATUS_META_EXISTS
            status%message = "Metadata with ID already exists: " // TRIM(new_meta%data_id)
            CALL log_warn("StructMetaData", TRIM(status%message))
            assigned_id = TRIM(new_meta%data_id)
            RETURN
        END IF

        ! Find empty slot
        idx = find_empty_meta_slot()
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "No available slots in metadata manager"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Copy metadata to manager and update index/metrics via helper
        CALL store_meta_entry(idx, new_meta)
        assigned_id = TRIM(new_meta%data_id)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE add_meta_to_manager

    SUBROUTINE import_sample_metadata_entries(imported_count, status)
        INTEGER(i4), INTENT(INOUT) :: imported_count
        TYPE(ErrorStatusType), INTENT(INOUT) :: status
        INTEGER(i4) :: i, max_entries
        TYPE(StructMetaType) :: sample_meta
        CHARACTER(LEN=IF_MAX_META_ID_LENGTH) :: temp_id2

        ! Create a few sample metadata entries
        max_entries = 3  ! Create up to 3 sample entries
        DO i = 1, max_entries
            ! Create sample metadata
            sample_meta%data_id = "SAMPLE_META_" // TRIM(INT_TO_STR(global_struct_meta_mgr%current_meta_count + 1))
            sample_meta%var_name = "sample_variable_" // TRIM(INT_TO_STR(i))
            
            ! Assign different data types for variety
            SELECT CASE (i)
                CASE (1)
                    sample_meta%data_type = IF_DATA_TYPE_INT
                    sample_meta%dimensions(1) = 10
                    sample_meta%valid_dim_count = 1
                    sample_meta%element_size = 4
                    sample_meta%total_elements = 10
                    sample_meta%total_size = 40
                CASE (2)
                    sample_meta%data_type = IF_DATA_TYPE_DP
                    sample_meta%dimensions(1) = 5
                    sample_meta%dimensions(2) = 5
                    sample_meta%valid_dim_count = 2
                    sample_meta%element_size = 8
                    sample_meta%total_elements = 25
                    sample_meta%total_size = 200
                CASE (3)
                    sample_meta%data_type = IF_DATA_TYPE_CHAR
                    sample_meta%dimensions(1) = 15
                    sample_meta%dimensions(2) = 10
                    sample_meta%valid_dim_count = 2
                    sample_meta%element_size = 1
                    sample_meta%total_elements = 150
                    sample_meta%total_size = 150
            END SELECT
            
            sample_meta%is_chunked = (i == 3)  ! Only make the third one chunked
            sample_meta%is_constant = (i == 1)  ! Only make the first one constant
            sample_meta%is_valid = .TRUE.

            ! Add to manager
            temp_id2 = TRIM(sample_meta%data_id)
            CALL add_meta_to_manager(sample_meta, temp_id2, status)
            IF (status%status_code == IF_STATUS_OK) THEN
                imported_count = imported_count + 1
            ELSE
                ! Reset status and continue
                CALL init_error_status(status)
            END IF
        END DO
    END SUBROUTINE import_sample_metadata_entries

    ! ==========================================================================
    ! Subroutine: Delete Structured Metadata (Logical deletion, mark as invalid)
    ! ==========================================================================
    SUBROUTINE struct_meta_delete(data_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id  ! Data ID (unique identifier)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_META_NOT_INIT)
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata index via hash index / linear scan helper
        CALL find_meta_index_by_id(data_id, idx, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (status%status_code == IF_STATUS_META_NOT_FOUND) THEN
                status%status_code = IF_STATUS_META_NOT_FOUND
                WRITE(status%message, '(A,A,A)') "Structured metadata for data ID '", TRIM(data_id), "' not found"
                CALL log_error("StructMetaData", TRIM(status%message))
            END IF
            RETURN
        END IF

        ! Deallocate chunk offset array
        IF (ALLOCATED(global_struct_meta_mgr%meta_list(idx)%chunk_offsets)) THEN
            DEALLOCATE(global_struct_meta_mgr%meta_list(idx)%chunk_offsets, STAT=status%io_stat)
            IF (status%io_stat /= 0) THEN
                CALL log_warn("StructMetaData", "Deallocate chunk offsets failed for data ID "//TRIM(data_id))
            END IF
        END IF

        ! Remove from hash index and logically delete via helper
        CALL invalidate_meta_entry(idx)

        CALL log_info("StructMetaData", "Deleted structured metadata: data ID='"//TRIM(data_id)//"'")
        status%status_code = IF_STATUS_OK
    END SUBROUTINE struct_meta_delete

    ! ==========================================================================
    ! Subroutine: Validate Structured Metadata Integrity (Checksum Match)
    ! ==========================================================================
    SUBROUTINE struct_meta_validate(data_id, current_crc32, is_valid, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id      ! Data ID
        INTEGER(i4), INTENT(IN) :: current_crc32        ! Current data checksum
        LOGICAL, INTENT(OUT) :: is_valid           ! Validation result (.TRUE.=match)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(StructMetaType) :: meta

        CALL init_error_status(status)
        is_valid = .FALSE.

        ! Query metadata
        CALL struct_meta_query(data_id, 1, meta, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Checksum match check (skip if metadata checksum is 0, not calculated)
        IF (meta%crc32 == 0) THEN
            status%status_code = IF_STATUS_OK
            is_valid = .TRUE.
            CALL log_warn("StructMetaData", "CRC32 not set for data ID "//TRIM(data_id))
            RETURN
        END IF

        IF (meta%crc32 == current_crc32) THEN
            is_valid = .TRUE.
            CALL log_debug("StructMetaData", "Structured metadata validation passed for data ID "//TRIM(data_id))
        ELSE
            status%status_code = IF_STATUS_META_CRC_ERR
            WRITE(status%message, '(A,I0,A,I0)') "CRC32 mismatch (meta: ", meta%crc32, ", current: ", current_crc32, ")"  
            CALL log_error("StructMetaData", TRIM(status%message))
        END IF
    END SUBROUTINE struct_meta_validate

    ! ==========================================================================
    ! Subroutine: Get Total Count of Current Structured Metadata Entries
    ! ==========================================================================
    SUBROUTINE get_struct_meta_count(count, status)
        INTEGER(i4), INTENT(OUT) :: count  ! Output current number of valid metadata entries
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        count = 0

        ! Pre-check: Whether manager is initialized (specific error code: IF_STATUS_META_NOT_INIT)
        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        count = global_struct_meta_mgr%current_meta_count
        status%status_code = IF_STATUS_OK
        CALL log_debug("StructMetaData", "Current structured metadata count: "//TRIM(INT_TO_STR(count)))
    END SUBROUTINE get_struct_meta_count

    ! ==========================================================================
    ! Utility Function: Check if Structured Metadata Exists (Internal Use)
    ! ==========================================================================
    LOGICAL FUNCTION struct_meta_exists(data_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        struct_meta_exists = .FALSE.

        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_META_NOT_INIT
            status%message = "Structured metadata manager not initialized"
            CALL log_error("StructMetaData", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                struct_meta_exists = .TRUE.
                RETURN
            END IF
        END DO

        status%status_code = IF_STATUS_META_NOT_FOUND
    END FUNCTION struct_meta_exists

    ! ==========================================================================
    ! Utility Function: Find Metadata Entry by ID (Internal Use)
    ! ==========================================================================
    INTEGER FUNCTION find_struct_meta_by_id(data_id)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4) :: i

        find_struct_meta_by_id = 0

        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            RETURN
        END IF

        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_struct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                find_struct_meta_by_id = i
                RETURN
            END IF
        END DO
    END FUNCTION find_struct_meta_by_id

    ! ==========================================================================
    ! Utility Function: Find Index of Free Metadata Entry (Internal Use)
    ! ==========================================================================
    INTEGER FUNCTION find_empty_meta_slot()
        INTEGER(i4) :: i

        find_empty_meta_slot = 0

        IF (.NOT. global_struct_meta_mgr%initialized) THEN
            RETURN
        END IF

        ! Iterate to find first invalid entry (reuse first to avoid memory fragmentation)
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (.NOT. global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                find_empty_meta_slot = i
                RETURN
            END IF
        END DO
    END FUNCTION find_empty_meta_slot

    ! ==========================================================================
    ! Utility Function: Find Index of Free Metadata Entry (Internal Use)
    ! ==========================================================================
    INTEGER FUNCTION find_free_meta_entry(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        find_free_meta_entry = 0

        ! Iterate to find first invalid entry (reuse first to avoid memory fragmentation)
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (.NOT. global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                find_free_meta_entry = i
                RETURN
            END IF
        END DO

        ! No free entry (return 0; external logic judges manager as full)
        status%status_code = IF_STATUS_MEM_ERROR
    END FUNCTION find_free_meta_entry

    ! ==========================================================================
    ! Utility Function: Validate Structured Metadata Parameters (Internal Use)
    ! ==========================================================================
    LOGICAL FUNCTION validate_struct_params(data_type, dimensions, element_size, valid_dim_count, status)
        INTEGER(i4), INTENT(IN) :: data_type, dimensions(IF_MAX_DIMENSIONS)
        INTEGER(KIND=8), INTENT(IN) :: element_size
        INTEGER(i4), INTENT(OUT) :: valid_dim_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        validate_struct_params = .FALSE.
        valid_dim_count = COUNT(dimensions > 0)

        ! Check 1: Number of valid dimensions (1-4D)
        IF (valid_dim_count < 1 .OR. valid_dim_count > IF_MAX_DIMENSIONS) THEN
            status%status_code = IF_STATUS_META_DIM_INVALID
            WRITE(status%message, '(A,I0,A,I0)') "Valid dimensions must be 1-", IF_MAX_DIMENSIONS, ", got ", valid_dim_count
            RETURN
        END IF

        ! Check 2: Non-negative dimension values
        DO i = 1, valid_dim_count
            IF (dimensions(i) <= 0) THEN
                status%status_code = IF_STATUS_META_DIM_INVALID
                WRITE(status%message, '(A,I0,A,I0)') "Dimension ", i, " must be positive, got ", dimensions(i)
                RETURN
            END IF
        END DO

        ! Check 3: Valid element size (>= min element size)
        IF (element_size < IF_MIN_ELEMENT_SIZE) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0,A,I0)') "Element size must be >= ", IF_MIN_ELEMENT_SIZE, ", got ", element_size
            RETURN
        END IF

        ! Check 4: Data type matches structured storage
        IF (.NOT. (data_type == IF_DATA_TYPE_INT .OR. data_type == IF_DATA_TYPE_DP .OR. &
                  data_type == IF_DATA_TYPE_CHAR .OR. data_type == IF_DATA_TYPE_STRUCT .OR. &
                  data_type == IF_DATA_TYPE_CLASS)) THEN
            status%status_code = IF_STATUS_META_TYPE_MISMATCH
            status%message = "Data type not supported for structured metadata"
            RETURN
        END IF

        ! All parameters passed validation
        validate_struct_params = .TRUE.
    END FUNCTION validate_struct_params

    ! ==========================================================================
    ! Utility Function: Get Timestamp (YYYY-MM-DD HH:MM:SS, Internal Use)
    ! ==========================================================================
    SUBROUTINE get_timestamp(timestamp)
        CHARACTER(LEN=20), INTENT(OUT) :: timestamp
        INTEGER(i4) :: values(8)

        CALL DATE_AND_TIME(VALUES=values)
        WRITE(timestamp, '(I4,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2,":",I2.2)') &
            values(1), values(2), values(3), values(5), values(6), values(7)
    END SUBROUTINE get_timestamp

    ! ==========================================================================
    ! Utility Function: Integer to String (Fortran2003 Compatible, Internal Use)
    ! ==========================================================================
    FUNCTION INT_TO_STR(i) RESULT(str)
        INTEGER(i4), INTENT(IN) :: i
        CHARACTER(LEN=20) :: str

        WRITE(str, '(I0)') i
        str = TRIM(ADJUSTL(str))
    END FUNCTION INT_TO_STR

    ! ==========================================================================
    ! Utility Function: 8-Byte Integer to String (Internal Use)
    ! ==========================================================================
    ! FUNCTION INT8_TO_STR(i8) RESULT(str) - Commented to avoid name conflict
    !     INTEGER(KIND=8), INTENT(IN) :: i8
    !     CHARACTER(LEN=30) :: str
    !
    !     WRITE(str, '(I0)') i8
    !     str = TRIM(ADJUSTL(str))
    ! END FUNCTION INT8_TO_STR

    ! ==========================================================================
    ! Utility Function: Integer Array to String (For Dimension Output, Internal Use)
    ! ==========================================================================
    FUNCTION INT_ARR_TO_STR(arr) RESULT(str)
        INTEGER(i4), INTENT(IN) :: arr(:)
        CHARACTER(LEN=100) :: str
        INTEGER(i4) :: i

        str = ""
        DO i = 1, SIZE(arr)
            IF (i > 1) str = TRIM(str) // "x"
            str = TRIM(str) // TRIM(INT_TO_STR(arr(i)))
        END DO
        str = TRIM(str)
    END FUNCTION INT_ARR_TO_STR

    ! ==========================================================================
    ! Utility Function: Real to String (Internal Use)
    ! ==========================================================================
    FUNCTION REAL_TO_STR(r) RESULT(str)
        REAL, INTENT(IN) :: r
        CHARACTER(LEN=30) :: str

        WRITE(str, '(G0.6)') r
        str = TRIM(ADJUSTL(str))
    END FUNCTION REAL_TO_STR

    ! ==========================================================================
    ! Utility Function: Logical to String (Internal Use)
    ! ==========================================================================
    FUNCTION LOGICAL_TO_STR(log_val) RESULT(str)
        LOGICAL, INTENT(IN) :: log_val
        CHARACTER(LEN=5) :: str

        IF (log_val) THEN
            str = "TRUE"
        ELSE
            str = "FALSE"
        END IF
    END FUNCTION LOGICAL_TO_STR

! ==========================================================================
! Subroutine: Batch Create Metadata
! ==========================================================================
SUBROUTINE struct_meta_create_batch(variable_names, dimensions, chunk_sizes, is_constants, &
                                    data_ids_out, status_codes_out, status)
    CHARACTER(LEN=*), DIMENSION(:), INTENT(IN) :: variable_names
    INTEGER, DIMENSION(:,:), INTENT(IN) :: dimensions
    INTEGER, DIMENSION(:,:), INTENT(IN) :: chunk_sizes
    LOGICAL, DIMENSION(:), INTENT(IN) :: is_constants
    CHARACTER(LEN=*), DIMENSION(:), INTENT(OUT) :: data_ids_out
    INTEGER, DIMENSION(:), INTENT(OUT) :: status_codes_out
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j, batch_size
    INTEGER(i4) :: data_type, valid_dim_count
    INTEGER(KIND=8) :: element_size
    TYPE(ErrorStatusType) :: item_status
    TYPE(StructMetaType) :: temp_meta
    
    CALL init_error_status(status)
    batch_size = SIZE(variable_names)
    
    ! Validate input array sizes
    IF (batch_size /= SIZE(dimensions, 1) .OR. batch_size /= SIZE(chunk_sizes, 1) .OR. &
        batch_size /= SIZE(is_constants) .OR. batch_size /= SIZE(data_ids_out) .OR. &
        batch_size /= SIZE(status_codes_out)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "Input array sizes do not match"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Initialize output arrays
    DO i = 1, batch_size
        data_ids_out(i) = ""
        status_codes_out(i) = IF_STATUS_OK
    END DO
    
    ! Process each metadata item
    DO i = 1, batch_size
        CALL init_error_status(item_status)
        
        ! Determine data type and element size from dimensions (simplified logic)
        ! In a real implementation, this should be passed as a parameter
        data_type = IF_DATA_TYPE_INT  ! Default to integer
        element_size = 4  ! Default to 4 bytes for integer
        
        ! Calculate valid dimension count
        valid_dim_count = 0
        DO j = 1, IF_MAX_DIMENSIONS
            IF (dimensions(i, j) > 0) THEN
                valid_dim_count = valid_dim_count + 1
            ELSE
                EXIT
            END IF
        END DO
        
        ! Call struct_meta_create with correct parameters
        CALL struct_meta_create(variable_names(i), data_type, dimensions(i,:), element_size, &
                               is_constants(i), temp_meta, item_status)
        
        ! Extract data_id from created metadata
        IF (item_status%status_code == IF_STATUS_OK) THEN
            data_ids_out(i) = TRIM(temp_meta%data_id)
        END IF
        
        ! Store individual item status
        status_codes_out(i) = item_status%status_code
        
        ! Log errors for individual items
        IF (item_status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMetaData", "Batch create error for item " // TRIM(INT_TO_STR(i)) // ": " // &
                          TRIM(item_status%message))
            ! Continue processing other items
        END IF
    END DO
    
    ! Set overall status
    status%status_code = IF_STATUS_OK
    status%message = "Batch create completed (check individual status codes)"
    CALL log_info("StructMetaData", TRIM(status%message))
END SUBROUTINE struct_meta_create_batch

! ==========================================================================
! Subroutine: Batch Update Metadata
! ==========================================================================
SUBROUTINE struct_meta_update_batch(data_ids, new_chunk_sizes, new_is_constants, &
                                    status_codes_out, status)
    CHARACTER(LEN=*), DIMENSION(:), INTENT(IN) :: data_ids
    INTEGER, DIMENSION(:,:), INTENT(IN) :: new_chunk_sizes
    LOGICAL, DIMENSION(:), INTENT(IN) :: new_is_constants
    INTEGER, DIMENSION(:), INTENT(OUT) :: status_codes_out
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, batch_size
    INTEGER(i4) :: update_field
    INTEGER(KIND=8) :: new_value
    TYPE(ErrorStatusType) :: item_status
    
    CALL init_error_status(status)
    batch_size = SIZE(data_ids)
    
    ! Validate input array sizes
    IF (batch_size /= SIZE(new_chunk_sizes, 1) .OR. batch_size /= SIZE(new_is_constants) .OR. &
        batch_size /= SIZE(status_codes_out)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "Input array sizes do not match"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Initialize output array
    DO i = 1, batch_size
        status_codes_out(i) = IF_STATUS_OK
    END DO
    
    ! Process each metadata item
    DO i = 1, batch_size
        CALL init_error_status(item_status)
        
        ! Update chunk size (field 2) if provided
        IF (SIZE(new_chunk_sizes, 2) > 0 .AND. new_chunk_sizes(i, 1) > 0) THEN
            update_field = 2  ! Chunk size field
            new_value = INT(new_chunk_sizes(i, 1), KIND=8)
            CALL struct_meta_update(data_ids(i), update_field, new_value, item_status)
        END IF
        
        ! Update constant flag (field 3) - convert logical to integer
        update_field = 3  ! Constant flag field
        IF (new_is_constants(i)) THEN
            new_value = 1
        ELSE
            new_value = 0
        END IF
        CALL struct_meta_update(data_ids(i), update_field, new_value, item_status)
        
        ! Store individual item status
        status_codes_out(i) = item_status%status_code
        
        ! Log errors for individual items
        IF (item_status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMetaData", "Batch update error for item " // TRIM(INT_TO_STR(i)) // &
                          " (data_id: " // TRIM(data_ids(i)) // "): " // TRIM(item_status%message))
            ! Continue processing other items
        END IF
    END DO
    
    ! Set overall status
    status%status_code = IF_STATUS_OK
    status%message = "Batch update completed (check individual status codes)"
    CALL log_info("StructMetaData", TRIM(status%message))
END SUBROUTINE struct_meta_update_batch

! ==========================================================================
! Subroutine: Batch Delete Metadata
! ==========================================================================
SUBROUTINE struct_meta_delete_batch(data_ids, status_codes_out, status)
    CHARACTER(LEN=*), DIMENSION(:), INTENT(IN) :: data_ids
    INTEGER, DIMENSION(:), INTENT(OUT) :: status_codes_out
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, batch_size
    TYPE(ErrorStatusType) :: item_status
    
    CALL init_error_status(status)
    batch_size = SIZE(data_ids)
    
    ! Validate input array sizes
    IF (batch_size /= SIZE(status_codes_out)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "Input array sizes do not match"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Initialize output array
    DO i = 1, batch_size
        status_codes_out(i) = IF_STATUS_OK
    END DO
    
    ! Process each metadata item
    DO i = 1, batch_size
        CALL init_error_status(item_status)
        CALL struct_meta_delete(data_ids(i), item_status)
        
        ! Store individual item status
        status_codes_out(i) = item_status%status_code
        
        ! Log errors for individual items
        IF (item_status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("StructMetaData", "Batch delete error for item " // TRIM(INT_TO_STR(i)) // &
                          " (data_id: " // TRIM(data_ids(i)) // "): " // TRIM(item_status%message))
            ! Continue processing other items
        END IF
    END DO
    
    ! Set overall status
    status%status_code = IF_STATUS_OK
    status%message = "Batch delete completed (check individual status codes)"
    CALL log_info("StructMetaData", TRIM(status%message))
END SUBROUTINE struct_meta_delete_batch

! ==========================================================================
! Subroutine: Persist Metadata to File
! ==========================================================================
SUBROUTINE struct_meta_persist(file_path, status)
    CHARACTER(LEN=*), INTENT(IN) :: file_path
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: file_unit, i, j, err_code
    CHARACTER(LEN=20) :: persist_time
    INTEGER(i4) :: version = 1 ! File format version
    INTEGER(i4) :: meta_count = 0
    INTEGER(i4) :: crc_total = 0 ! Total CRC for verification
    
    CALL init_error_status(status)
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Count valid metadata entries
    CALL get_struct_meta_count(meta_count, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! Get current time
    CALL get_timestamp(persist_time)
    
    ! Calculate total CRC for verification
    DO i = 1, global_struct_meta_mgr%max_meta_count
        IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
            crc_total = crc_total + global_struct_meta_mgr%meta_list(i)%crc32
        END IF
    END DO
    
    ! Open file for writing
    OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', &
         FORM='FORMATTED', IOSTAT=err_code)
    
    IF (err_code /= 0) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,A,A,I0)') "Failed to open file '", TRIM(file_path), "' for writing: IOSTAT=", err_code
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Write file header
    WRITE(file_unit, '(A)') "# Structured Metadata Persistence File"
    WRITE(file_unit, '(A,A)') "# Created: ", TRIM(persist_time)
    WRITE(file_unit, '(A,I0)') "# Version: ", version
    WRITE(file_unit, '(A,I0)') "# Total Entries: ", meta_count
    WRITE(file_unit, '(A,I0)') "# Total CRC: ", crc_total
    WRITE(file_unit, '(A)') "# ==== DATA START ===="
    
    ! Write metadata entries
    DO i = 1, global_struct_meta_mgr%max_meta_count
        IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
            ! Write entry separator
            WRITE(file_unit, '(A,I0)') "ENTRY_BEGIN:", i
            
            ! Write basic fields
            WRITE(file_unit, '(A,A)') "DATA_ID:", TRIM(global_struct_meta_mgr%meta_list(i)%data_id)
            WRITE(file_unit, '(A,A)') "VAR_NAME:", TRIM(global_struct_meta_mgr%meta_list(i)%var_name)
            WRITE(file_unit, '(A,I0)') "IF_STORAGE_TYPE:", global_struct_meta_mgr%meta_list(i)%storage_type
            WRITE(file_unit, '(A,I0)') "DATA_TYPE:", global_struct_meta_mgr%meta_list(i)%data_type
            
            ! Write dimensions
            WRITE(file_unit, '(A,4I0)') "DIMENSIONS:", (global_struct_meta_mgr%meta_list(i)%dimensions(j), j=1,IF_MAX_DIMENSIONS)
            WRITE(file_unit, '(A,I0)') "VALID_DIM_COUNT:", global_struct_meta_mgr%meta_list(i)%valid_dim_count
            
            ! Write size information
            WRITE(file_unit, '(A,I0)') "ELEMENT_SIZE:", global_struct_meta_mgr%meta_list(i)%element_size
            WRITE(file_unit, '(A,I0)') "TOTAL_ELEMENTS:", global_struct_meta_mgr%meta_list(i)%total_elements
            WRITE(file_unit, '(A,I0)') "TOTAL_SIZE:", global_struct_meta_mgr%meta_list(i)%total_size
            
            ! Write chunk information
            WRITE(file_unit, '(A,L1)') "IS_CHUNKED:", global_struct_meta_mgr%meta_list(i)%is_chunked
            WRITE(file_unit, '(A,I0)') "CHUNK_SIZE:", global_struct_meta_mgr%meta_list(i)%chunk_size
            WRITE(file_unit, '(A,I0)') "TOTAL_CHUNKS:", global_struct_meta_mgr%meta_list(i)%total_chunks
            
            ! Write integrity and lifecycle
            WRITE(file_unit, '(A,I0)') "CRC32:", global_struct_meta_mgr%meta_list(i)%crc32
            WRITE(file_unit, '(A,A)') "CREATE_TIME:", TRIM(global_struct_meta_mgr%meta_list(i)%create_time)
            WRITE(file_unit, '(A,A)') "UPDATE_TIME:", TRIM(global_struct_meta_mgr%meta_list(i)%update_time)
            WRITE(file_unit, '(A,L1)') "IS_CONSTANT:", global_struct_meta_mgr%meta_list(i)%is_constant
            
            ! Write entry end marker
            WRITE(file_unit, '(A)') "ENTRY_END"
        END IF
    END DO
    
    ! Write file footer
    WRITE(file_unit, '(A)') "# ==== DATA END ===="
    
    ! Close file
    CLOSE(file_unit, IOSTAT=err_code)
    
    IF (err_code /= 0) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,A,A,I0)') "Failed to close file '", TRIM(file_path), "': IOSTAT=", err_code
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Success
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,A,A,I0,A)') "Successfully persisted ", TRIM(INT_TO_STR(meta_count)), &
                        " metadata entries to '", TRIM(file_path), "'"
    CALL log_info("StructMetaData", TRIM(status%message))
END SUBROUTINE struct_meta_persist

! ==========================================================================
! Subroutine: Recover Metadata from File
! ==========================================================================
SUBROUTINE struct_meta_recover(file_path, status)
    CHARACTER(LEN=*), INTENT(IN) :: file_path
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: file_unit, i, j, err_code, version, total_entries, crc_total, read_crc_total
    CHARACTER(LEN=256) :: line, key, value
    LOGICAL :: in_entry, found_data_start
    INTEGER(i4) :: current_entry_id
    
    CALL init_error_status(status)
    
    ! Pre-check: Metadata manager must be initialized but empty
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Check if manager already has entries
    IF (global_struct_meta_mgr%current_meta_count > 0) THEN
        status%status_code = IF_STATUS_EXISTS
        status%message = "Metadata manager already contains entries - recovery requires empty manager"
        CALL log_info("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Open file for reading
    OPEN(NEWUNIT=file_unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', &
         FORM='FORMATTED', IOSTAT=err_code)
    
    IF (err_code /= 0) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,A,A,I0)') "Failed to open file '", TRIM(file_path), "' for reading: IOSTAT=", err_code
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Initialize variables
    in_entry = .FALSE.
    found_data_start = .FALSE.
    current_entry_id = 0
    read_crc_total = 0
    
    ! Skip header until DATA START marker
    DO
        READ(file_unit, '(A)', IOSTAT=err_code) line
        IF (err_code /= 0) EXIT
        
        IF (INDEX(line, '# ==== DATA START ====') /= 0) THEN
            found_data_start = .TRUE.
            EXIT
        END IF
        
        ! Extract header information
        IF (INDEX(line, '# Version:') /= 0) THEN
            READ(line(10:), *, IOSTAT=err_code) version
        ELSE IF (INDEX(line, '# Total Entries:') /= 0) THEN
            READ(line(15:), *, IOSTAT=err_code) total_entries
        ELSE IF (INDEX(line, '# Total CRC:') /= 0) THEN
            READ(line(11:), *, IOSTAT=err_code) crc_total
        END IF
    END DO
    
    IF (.NOT. found_data_start) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "Invalid metadata file format: DATA START marker not found"
        CALL log_error("StructMetaData", TRIM(status%message))
        CLOSE(file_unit)
        RETURN
    END IF
    
    ! Allocate additional space if needed
    IF (total_entries > global_struct_meta_mgr%max_meta_count) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,I0,A,I0)') "Not enough space in metadata manager (need ", &
                        total_entries, ", current max: ", global_struct_meta_mgr%max_meta_count
        CALL log_error("StructMetaData", TRIM(status%message))
        CLOSE(file_unit)
        RETURN
    END IF
    
    ! Process metadata entries
    DO
        IF (in_entry) THEN
            ! We have a valid entry, find a free slot to store it
            i = find_free_meta_entry(status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CLOSE(file_unit)
                RETURN
            END IF
            
            ! Reset entry to valid (it was marked as valid during field processing)
            global_struct_meta_mgr%meta_list(i)%is_valid = .TRUE.
            
            ! Add to CRC total
            read_crc_total = read_crc_total + global_struct_meta_mgr%meta_list(i)%crc32
            
            ! Store entry and update index/metrics via helper
            CALL store_meta_entry(i, global_struct_meta_mgr%meta_list(i))
            
            in_entry = .FALSE.
        END IF
        
        READ(file_unit, '(A)', IOSTAT=err_code) line
        IF (err_code /= 0) EXIT
        
        ! Check for end of data
        IF (INDEX(line, '# ==== DATA END ====') /= 0) EXIT
        
        ! Check for entry begin
        IF (INDEX(line, 'ENTRY_BEGIN:') /= 0) THEN
            in_entry = .TRUE.
            READ(line(12:), *, IOSTAT=err_code) current_entry_id
            
            ! Find a free slot and initialize entry
            i = find_free_meta_entry(status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CLOSE(file_unit)
                RETURN
            END IF
            
            ! Reset all fields
            global_struct_meta_mgr%meta_list(i)%data_id = ""
            global_struct_meta_mgr%meta_list(i)%var_name = ""
            global_struct_meta_mgr%meta_list(i)%storage_type = IF_STORAGE_TYPE_STRUCTURED
            global_struct_meta_mgr%meta_list(i)%data_type = 0
            global_struct_meta_mgr%meta_list(i)%dimensions = [0,0,0,0]
            global_struct_meta_mgr%meta_list(i)%valid_dim_count = 0
            global_struct_meta_mgr%meta_list(i)%element_size = 0
            global_struct_meta_mgr%meta_list(i)%total_elements = 0
            global_struct_meta_mgr%meta_list(i)%total_size = 0
            global_struct_meta_mgr%meta_list(i)%is_chunked = .FALSE.
            global_struct_meta_mgr%meta_list(i)%chunk_size = IF_DEFAULT_CHUNK_SIZE
            global_struct_meta_mgr%meta_list(i)%total_chunks = 0
            ! Deallocate chunk_offsets if allocated
            IF (ALLOCATED(global_struct_meta_mgr%meta_list(i)%chunk_offsets)) THEN
                DEALLOCATE(global_struct_meta_mgr%meta_list(i)%chunk_offsets)
            END IF
            global_struct_meta_mgr%meta_list(i)%crc32 = 0
            global_struct_meta_mgr%meta_list(i)%create_time = ""
            global_struct_meta_mgr%meta_list(i)%update_time = ""
            global_struct_meta_mgr%meta_list(i)%is_valid = .FALSE.
            global_struct_meta_mgr%meta_list(i)%is_constant = .FALSE.
            
        ! Check for entry end
        ELSE IF (INDEX(line, 'ENTRY_END') /= 0) THEN
            ! Entry processing will continue in the next loop iteration
            CONTINUE
            
        ! Process field
        ELSE IF (in_entry) THEN
            ! Split line into key and value
            j = SCAN(line, ':')
            IF (j > 0) THEN
                key = line(1:j-1)
                value = ADJUSTL(line(j+1:))
                
                ! Process each field
                IF (TRIM(key) == 'DATA_ID') THEN
                    global_struct_meta_mgr%meta_list(i)%data_id = TRIM(value)
                ELSE IF (TRIM(key) == 'VAR_NAME') THEN
                    global_struct_meta_mgr%meta_list(i)%var_name = TRIM(value)
                ELSE IF (TRIM(key) == 'IF_STORAGE_TYPE') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%storage_type
                ELSE IF (TRIM(key) == 'DATA_TYPE') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%data_type
                ELSE IF (TRIM(key) == 'DIMENSIONS') THEN
                    READ(value, *, IOSTAT=err_code) (global_struct_meta_mgr%meta_list(i)%dimensions(j), j=1,IF_MAX_DIMENSIONS)
                ELSE IF (TRIM(key) == 'VALID_DIM_COUNT') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%valid_dim_count
                ELSE IF (TRIM(key) == 'ELEMENT_SIZE') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%element_size
                ELSE IF (TRIM(key) == 'TOTAL_ELEMENTS') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%total_elements
                ELSE IF (TRIM(key) == 'TOTAL_SIZE') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%total_size
                ELSE IF (TRIM(key) == 'IS_CHUNKED') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%is_chunked
                ELSE IF (TRIM(key) == 'CHUNK_SIZE') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%chunk_size
                ELSE IF (TRIM(key) == 'TOTAL_CHUNKS') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%total_chunks
                ELSE IF (TRIM(key) == 'CRC32') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%crc32
                ELSE IF (TRIM(key) == 'CREATE_TIME') THEN
                    global_struct_meta_mgr%meta_list(i)%create_time = TRIM(value)
                ELSE IF (TRIM(key) == 'UPDATE_TIME') THEN
                    global_struct_meta_mgr%meta_list(i)%update_time = TRIM(value)
                ELSE IF (TRIM(key) == 'IS_CONSTANT') THEN
                    READ(value, *, IOSTAT=err_code) global_struct_meta_mgr%meta_list(i)%is_constant
                END IF
            END IF
        END IF
    END DO
    
    ! Close file
    CLOSE(file_unit)
    
    ! Verify CRC
    IF (read_crc_total /= crc_total) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,I0,A,I0)') "Integrity check failed: CRC mismatch (expected ", &
                        crc_total, ", got ", read_crc_total
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Success
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,A,A,I0,A)') "Successfully recovered ", TRIM(INT_TO_STR(global_struct_meta_mgr%current_meta_count)), &
                        " metadata entries from '", TRIM(file_path), "'"
    CALL log_info("StructMetaData", TRIM(status%message))
END SUBROUTINE struct_meta_recover

! ==========================================================================
! Subroutine: Initialize Query Filter
! ==========================================================================
SUBROUTINE init_query_filter(filter, use_and_logic)
    TYPE(QueryFilterType), INTENT(OUT) :: filter
    LOGICAL, INTENT(IN), OPTIONAL :: use_and_logic
    INTEGER(i4) :: i
    
    ! Initialize all conditions
    DO i = 1, IF_MAX_QUERY_CONDITIONS
        filter%conditions(i)%cond_type = IF_QUERY_COND_TYPE_NONE
        filter%conditions(i)%str_value1 = ""
        filter%conditions(i)%str_value2 = ""
        filter%conditions(i)%int_value1 = 0
        filter%conditions(i)%int_value2 = 0
        filter%conditions(i)%logical_value = .FALSE.
        filter%conditions(i)%is_active = .FALSE.
    END DO
    
    ! Set active condition count
    filter%active_cond_count = 0
    
    ! Set logic type (AND by default)
    IF (PRESENT(use_and_logic)) THEN
        filter%use_and_logic = use_and_logic
    ELSE
        filter%use_and_logic = .TRUE.
    END IF
END SUBROUTINE init_query_filter

! ==========================================================================
! Subroutine: Add Query Condition
! ==========================================================================
SUBROUTINE add_query_condition(filter, cond_type, status, str_value1, str_value2, &
                              int_value1, int_value2, logical_value)
    TYPE(QueryFilterType), INTENT(INOUT) :: filter
    INTEGER(i4), INTENT(IN) :: cond_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: str_value1, str_value2
    INTEGER, INTENT(IN), OPTIONAL :: int_value1, int_value2
    LOGICAL, INTENT(IN), OPTIONAL :: logical_value
    INTEGER(i4) :: i
    
    CALL init_error_status(status)
    
    ! Check if max conditions reached
    IF (filter%active_cond_count >= IF_MAX_QUERY_CONDITIONS) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,I0)') "Maximum number of query conditions reached (", IF_MAX_QUERY_CONDITIONS, ")"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Validate condition type
    IF (cond_type < IF_QUERY_COND_TYPE_NONE .OR. cond_type > IF_QUERY_COND_TYPE_CRC32) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,I0)') "Invalid query condition type: ", cond_type
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Find first inactive condition slot
    DO i = 1, IF_MAX_QUERY_CONDITIONS
        IF (.NOT. filter%conditions(i)%is_active) THEN
            EXIT
        END IF
    END DO
    
    ! Set condition type
    filter%conditions(i)%cond_type = cond_type
    
    ! Set values based on condition type
    SELECT CASE(cond_type)
        CASE(IF_QUERY_COND_TYPE_DATA_ID, IF_QUERY_COND_TYPE_VAR_NAME)
            IF (.NOT. PRESENT(str_value1)) THEN
                status%status_code = IF_STATUS_ERROR
                status%message = "String value required for ID or name condition"
                CALL log_error("StructMetaData", TRIM(status%message))
                RETURN
            END IF
            filter%conditions(i)%str_value1 = TRIM(str_value1)
            
        CASE(IF_QUERY_COND_TYPE_DATA_TYPE, IF_QUERY_COND_TYPE_STORAGE, IF_QUERY_COND_TYPE_DIM_COUNT, IF_QUERY_COND_TYPE_CRC32)
            IF (.NOT. PRESENT(int_value1)) THEN
                status%status_code = IF_STATUS_ERROR
                status%message = "Integer value required for type or count condition"
                CALL log_error("StructMetaData", TRIM(status%message))
                RETURN
            END IF
            filter%conditions(i)%int_value1 = int_value1
            
        CASE(IF_QUERY_COND_TYPE_IS_CONSTANT, IF_QUERY_COND_TYPE_IS_CHUNKED)
            IF (.NOT. PRESENT(logical_value)) THEN
                status%status_code = IF_STATUS_ERROR
                status%message = "Logical value required for boolean flag condition"
                CALL log_error("StructMetaData", TRIM(status%message))
                RETURN
            END IF
            filter%conditions(i)%logical_value = logical_value
            
        CASE(IF_QUERY_COND_TYPE_SIZE_RANGE)
            IF (.NOT. (PRESENT(int_value1) .AND. PRESENT(int_value2))) THEN
                status%status_code = IF_STATUS_ERROR
                status%message = "Both minimum and maximum size values required for size range condition"
                CALL log_error("StructMetaData", TRIM(status%message))
                RETURN
            END IF
            filter%conditions(i)%int_value1 = int_value1 ! min size
            filter%conditions(i)%int_value2 = int_value2 ! max size
    END SELECT
    
    ! Mark condition as active
    filter%conditions(i)%is_active = .TRUE.
    filter%active_cond_count = filter%active_cond_count + 1
    
    status%status_code = IF_STATUS_OK
    status%message = "Query condition added successfully"
END SUBROUTINE add_query_condition

! ==========================================================================
! Subroutine: Complex Query Interface
! ==========================================================================
SUBROUTINE struct_meta_complex_query(filter, meta_results, result_count, max_results, status)
    TYPE(QueryFilterType), INTENT(IN) :: filter
    TYPE(StructMetaType), INTENT(OUT) :: meta_results(:)
    INTEGER(i4), INTENT(OUT) :: result_count
    INTEGER(i4), INTENT(IN) :: max_results
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, j, result_idx
    LOGICAL :: matches_all, matches_any, matches_condition
    
    CALL init_error_status(status)
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Check result array size
    IF (SIZE(meta_results) < max_results) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "Result array too small for requested maximum results"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Initialize result count
    result_count = 0
    
    ! If no conditions, return all valid metadata (up to max_results)
    IF (filter%active_cond_count == 0) THEN
        DO i = 1, global_struct_meta_mgr%max_meta_count
            IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
                result_count = result_count + 1
                IF (result_count <= max_results) THEN
                    meta_results(result_count) = global_struct_meta_mgr%meta_list(i)
                ELSE
                    EXIT ! Reached max results
                END IF
            END IF
        END DO
        
        status%status_code = IF_STATUS_OK
        WRITE(status%message, '(A,I0,A,I0)') "Query returned ", result_count, " results (limit: ", max_results, ")"
        CALL log_info("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Process each metadata entry
    DO i = 1, global_struct_meta_mgr%max_meta_count
        IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
            ! Reset match flags
            matches_all = .TRUE.
            matches_any = .FALSE.
            
            ! Check against each active condition
            DO j = 1, IF_MAX_QUERY_CONDITIONS
                IF (filter%conditions(j)%is_active) THEN
                    matches_condition = evaluate_condition(global_struct_meta_mgr%meta_list(i), filter%conditions(j))
                    
                    ! Update match flags based on logic type
                    IF (filter%use_and_logic) THEN
                        ! AND logic: all conditions must match
                        matches_all = matches_all .AND. matches_condition
                        ! Early exit if any condition fails to match
                        IF (.NOT. matches_all) EXIT
                    ELSE
                        ! OR logic: any condition matching is sufficient
                        matches_any = matches_any .OR. matches_condition
                        ! Early exit if any condition matches
                        IF (matches_any) EXIT
                    END IF
                END IF
            END DO
            
            ! Determine if entry matches the filter
            IF ((filter%use_and_logic .AND. matches_all) .OR. &
                (.NOT. filter%use_and_logic .AND. matches_any)) THEN
                ! Add to results if within limit
                result_count = result_count + 1
                IF (result_count <= max_results) THEN
                    meta_results(result_count) = global_struct_meta_mgr%meta_list(i)
                ELSE
                    ! Reached max results, break out of loop
                    EXIT
                END IF
            END IF
        END IF
    END DO
    
    ! Success
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,I0,A,I0)') "Complex query returned ", result_count, " results (limit: ", max_results, ")"
    CALL log_info("StructMetaData", TRIM(status%message))

CONTAINS
    ! ==========================================================================
    ! Function: Evaluate a Single Query Condition
    ! ==========================================================================
    LOGICAL FUNCTION evaluate_condition(meta, condition)
        TYPE(StructMetaType), INTENT(IN) :: meta
        TYPE(QueryConditionType), INTENT(IN) :: condition
        
        evaluate_condition = .FALSE.
        
        SELECT CASE(condition%cond_type)
            CASE(IF_QUERY_COND_TYPE_DATA_ID)
                evaluate_condition = (TRIM(meta%data_id) == TRIM(condition%str_value1))
                
            CASE(IF_QUERY_COND_TYPE_VAR_NAME)
                evaluate_condition = (TRIM(meta%var_name) == TRIM(condition%str_value1))
                
            CASE(IF_QUERY_COND_TYPE_DATA_TYPE)
                evaluate_condition = (meta%data_type == condition%int_value1)
                
            CASE(IF_QUERY_COND_TYPE_STORAGE)
                evaluate_condition = (meta%storage_type == condition%int_value1)
                
            CASE(IF_QUERY_COND_TYPE_DIM_COUNT)
                evaluate_condition = (meta%valid_dim_count == condition%int_value1)
                
            CASE(IF_QUERY_COND_TYPE_IS_CONSTANT)
                evaluate_condition = (meta%is_constant .EQV. condition%logical_value)
                
            CASE(IF_QUERY_COND_TYPE_IS_CHUNKED)
                evaluate_condition = (meta%is_chunked .EQV. condition%logical_value)
                
            CASE(IF_QUERY_COND_TYPE_SIZE_RANGE)
                evaluate_condition = (meta%total_size >= condition%int_value1 .AND. &
                                    meta%total_size <= condition%int_value2)
                
            CASE(IF_QUERY_COND_TYPE_CRC32)
                evaluate_condition = (meta%crc32 == condition%int_value1)
                
            CASE DEFAULT
                evaluate_condition = .FALSE.
        END SELECT
    END FUNCTION evaluate_condition
END SUBROUTINE struct_meta_complex_query

! ==========================================================================
! Subroutine: Validate All Metadata Entries
! Function: Performs comprehensive validation of all metadata entries
! ==========================================================================
SUBROUTINE struct_meta_validate_all(invalid_count, status)
    INTEGER(i4), INTENT(OUT) :: invalid_count
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, valid_dim_count
    TYPE(ErrorStatusType) :: item_status
    CHARACTER(LEN=IF_MAX_ERROR_DETAIL_LEN) :: error_detail
    
    CALL init_error_status(status)
    invalid_count = 0
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    CALL log_info("StructMetaData", "Starting comprehensive metadata validation")
    
    ! Validate each metadata entry
    DO i = 1, global_struct_meta_mgr%max_meta_count
        IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
            ! Check data type and dimensions
            IF (.NOT. validate_struct_params(global_struct_meta_mgr%meta_list(i)%data_type, &
                                           global_struct_meta_mgr%meta_list(i)%dimensions, &
                                           global_struct_meta_mgr%meta_list(i)%element_size, &
                                           valid_dim_count, item_status)) THEN
                invalid_count = invalid_count + 1
                WRITE(error_detail, '(A,I0,A,A)') "Invalid metadata at index ", i, ": ", TRIM(item_status%message)
                CALL log_warn("StructMetaData", TRIM(error_detail))
            
            ! Check data consistency
            ELSE IF (global_struct_meta_mgr%meta_list(i)%valid_dim_count /= valid_dim_count) THEN
                invalid_count = invalid_count + 1
                WRITE(error_detail, '(A,I0,A,I0,A,I0)') "Inconsistent dimension count at index ", i, ": stored(", &
                              global_struct_meta_mgr%meta_list(i)%valid_dim_count, "), calculated(", valid_dim_count, ")"
                CALL log_warn("StructMetaData", TRIM(error_detail))
            
            ! Check chunk information if chunked
            ELSE IF (global_struct_meta_mgr%meta_list(i)%is_chunked) THEN
                IF (global_struct_meta_mgr%meta_list(i)%chunk_size <= 0 .OR. &
                    global_struct_meta_mgr%meta_list(i)%total_chunks <= 0) THEN
                    invalid_count = invalid_count + 1
                    WRITE(error_detail, '(A,I0,A)') "Invalid chunk information at index ", i, &
                                  " (size or count <= 0)"
                    CALL log_warn("StructMetaData", TRIM(error_detail))
                END IF
            END IF
            
            ! Check CRC32 if available
            IF (global_struct_meta_mgr%meta_list(i)%crc32 /= 0) THEN
                IF (.NOT. verify_metadata_crc(global_struct_meta_mgr%meta_list(i), item_status)) THEN
                    invalid_count = invalid_count + 1
                    WRITE(error_detail, '(A,I0,A,A)') "CRC32 mismatch at index ", i, ": ", TRIM(item_status%message)
                    CALL log_error("StructMetaData", TRIM(error_detail))
                    global_struct_meta_mgr%total_errors = global_struct_meta_mgr%total_errors + 1
                END IF
            END IF
        END IF
    END DO
    
    ! Update statistics and return status
    status%status_code = IF_STATUS_OK
    IF (invalid_count > 0) THEN
        WRITE(status%message, '(A,I0,A)') "Validation completed with ", invalid_count, " invalid entries found"
        CALL log_warn("StructMetaData", TRIM(status%message))
    ELSE
        status%message = "All metadata entries are valid"
        CALL log_info("StructMetaData", TRIM(status%message))
    END IF
END SUBROUTINE struct_meta_validate_all

! ==========================================================================
! Subroutine: Repair Invalid Metadata Entries
! Function: Attempts to repair invalid metadata entries
! ==========================================================================
SUBROUTINE struct_meta_repair(repair_count, status)
    INTEGER(i4), INTENT(OUT) :: repair_count
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, valid_dim_count
    TYPE(ErrorStatusType) :: item_status
    
    CALL init_error_status(status)
    repair_count = 0
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    CALL log_info("StructMetaData", "Starting metadata repair process")
    
    ! Process each metadata entry
    DO i = 1, global_struct_meta_mgr%max_meta_count
        IF (global_struct_meta_mgr%meta_list(i)%is_valid) THEN
            ! Calculate valid dimension count
            CALL calculate_valid_dim_count(global_struct_meta_mgr%meta_list(i)%dimensions, valid_dim_count)
            
            ! Repair inconsistent dimension count
            IF (global_struct_meta_mgr%meta_list(i)%valid_dim_count /= valid_dim_count) THEN
                global_struct_meta_mgr%meta_list(i)%valid_dim_count = valid_dim_count
                repair_count = repair_count + 1
                CALL log_info("StructMetaData", "Repaired dimension count for metadata at index "//TRIM(INT_TO_STR(i)))
            END IF
            
            ! Repair invalid chunk information
            IF (global_struct_meta_mgr%meta_list(i)%is_chunked) THEN
                IF (global_struct_meta_mgr%meta_list(i)%chunk_size <= 0) THEN
                    global_struct_meta_mgr%meta_list(i)%chunk_size = IF_DEFAULT_CHUNK_SIZE
                    repair_count = repair_count + 1
                    CALL log_info("StructMetaData", "Repaired chunk size for metadata at index "//TRIM(INT_TO_STR(i)))
                END IF
                
                IF (global_struct_meta_mgr%meta_list(i)%total_chunks <= 0) THEN
                    global_struct_meta_mgr%meta_list(i)%total_chunks = MAX(1, INT(global_struct_meta_mgr%meta_list(i)%total_size / &
                                                                      global_struct_meta_mgr%meta_list(i)%chunk_size) + 1)
                    repair_count = repair_count + 1
                    CALL log_info("StructMetaData", "Repaired chunk count for metadata at index "//TRIM(INT_TO_STR(i)))
                END IF
            END IF
            
            ! Recalculate total elements if needed
            CALL calculate_total_elements(global_struct_meta_mgr%meta_list(i)%dimensions, valid_dim_count, &
                                        global_struct_meta_mgr%meta_list(i)%total_elements)
            
            ! Recalculate total size
            global_struct_meta_mgr%meta_list(i)%total_size = global_struct_meta_mgr%meta_list(i)%total_elements * &
                                                           global_struct_meta_mgr%meta_list(i)%element_size
            
            ! Recalculate CRC32 if checksum is set but invalid
            IF (global_struct_meta_mgr%meta_list(i)%crc32 /= 0) THEN
                CALL calculate_metadata_crc(global_struct_meta_mgr%meta_list(i), global_struct_meta_mgr%meta_list(i)%crc32)
                repair_count = repair_count + 1
                CALL log_info("StructMetaData", "Recalculated CRC32 for metadata at index "//TRIM(INT_TO_STR(i)))
            END IF
        END IF
    END DO
    
    ! Success
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,I0,A)') "Repair process completed, fixed ", repair_count, " metadata entries"
    CALL log_info("StructMetaData", TRIM(status%message))
END SUBROUTINE struct_meta_repair

! ==========================================================================
! Subroutine: Recover from Error State
! Function: Attempts to recover metadata manager from error state
! ==========================================================================
SUBROUTINE struct_meta_recover_from_error(error_code, status)
    INTEGER(i4), INTENT(IN) :: error_code
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: invalid_count, repair_count
    TYPE(ErrorStatusType) :: validate_status, repair_status
    
    CALL init_error_status(status)
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    CALL log_info("StructMetaData", "Attempting recovery from error code "//TRIM(INT_TO_STR(error_code)))
    
    ! Handle specific error types
    SELECT CASE(error_code)
        CASE(IF_STATUS_META_CHUNK_INVALID)
            ! For chunk invalid errors, try to repair
            CALL struct_meta_repair(repair_count, repair_status)
            IF (repair_status%status_code == IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_OK
                status%message = "Recovery from chunk invalid error successful"
                CALL log_info("StructMetaData", TRIM(status%message))
            ELSE
                status%status_code = IF_STATUS_ERROR
                status%message = "Failed to recover from chunk invalid error: "//TRIM(repair_status%message)
                CALL log_error("StructMetaData", TRIM(status%message))
            END IF
            
        CASE(IF_STATUS_META_CRC_ERR)
            ! For CRC errors, validate all and then repair
            CALL struct_meta_validate_all(invalid_count, validate_status)
            IF (invalid_count > 0) THEN
                CALL struct_meta_repair(repair_count, repair_status)
                status%status_code = IF_STATUS_OK
                status%message = "Recovery from CRC error completed, repaired entries: "//TRIM(INT_TO_STR(repair_count))
                CALL log_info("StructMetaData", TRIM(status%message))
            ELSE
                status%status_code = IF_STATUS_OK
                status%message = "No invalid entries found during CRC error recovery"
                CALL log_info("StructMetaData", TRIM(status%message))
            END IF
            
        CASE(IF_STATUS_META_RESOURCE_ERR)
            ! For resource errors, try to compact the metadata manager
            CALL log_warn("StructMetaData", "Resource error recovery: Consider increasing max_meta_count")
            status%status_code = IF_STATUS_OK
            status%message = "Resource error recovery recommendation provided"
            
        CASE DEFAULT
            ! For other errors, perform general validation
            CALL struct_meta_validate_all(invalid_count, validate_status)
            status%status_code = IF_STATUS_OK
            WRITE(status%message, '(A,I0,A)') "General error recovery completed, ", invalid_count, " invalid entries found"
            CALL log_info("StructMetaData", TRIM(status%message))
    END SELECT
    
    ! Update error statistics
    IF (status%status_code == IF_STATUS_OK) THEN
        CALL log_info("StructMetaData", "Error recovery process completed successfully")
    ELSE
        global_struct_meta_mgr%total_errors = global_struct_meta_mgr%total_errors + 1
        CALL log_error("StructMetaData", "Error recovery failed")
    END IF
END SUBROUTINE struct_meta_recover_from_error

! ==========================================================================
! Subroutine: Get Error Summary
! Function: Returns a summary of all error statistics
! ==========================================================================
SUBROUTINE get_struct_meta_error_summary(total_errors, error_by_type, status)
    INTEGER(i4), INTENT(OUT) :: total_errors
    INTEGER, DIMENSION(220), INTENT(OUT) :: error_by_type  ! Covers error codes 201-220
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Initialize error by type array
    error_by_type = 0
    
    ! Set total errors
    total_errors = global_struct_meta_mgr%total_errors
    
    ! For now, we just return the total count
    ! In a more sophisticated implementation, we would track errors by type
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,I0,A)') "Retrieved error summary: total errors = ", total_errors
    CALL log_debug("StructMetaData", TRIM(status%message))
END SUBROUTINE get_struct_meta_error_summary

! ==========================================================================
! Subroutine: Reset Error Counter
! Function: Resets the error counter to zero
! ==========================================================================
SUBROUTINE struct_meta_reset_error_counter(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: previous_count
    
    CALL init_error_status(status)
    
    ! Pre-check: Metadata manager initialization status
    IF (.NOT. global_struct_meta_mgr%initialized) THEN
        status%status_code = IF_STATUS_META_NOT_INIT
        status%message = "Struct metadata manager not initialized"
        CALL log_error("StructMetaData", TRIM(status%message))
        RETURN
    END IF
    
    ! Store previous count for logging
    previous_count = global_struct_meta_mgr%total_errors
    
    ! Reset the error counter
    global_struct_meta_mgr%total_errors = 0
    
    ! Success
    status%status_code = IF_STATUS_OK
    WRITE(status%message, '(A,I0,A)') "Error counter reset: previous = ", previous_count, ", current = 0"
    CALL log_info("StructMetaData", TRIM(status%message))
END SUBROUTINE struct_meta_reset_error_counter

! ==========================================================================
! Helper Function: Verify Metadata CRC
! ==========================================================================
LOGICAL FUNCTION verify_metadata_crc(meta, status)
    TYPE(StructMetaType), INTENT(IN) :: meta
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: calculated_crc
    
    CALL init_error_status(status)
    verify_metadata_crc = .FALSE.
    
    ! Calculate CRC for comparison
    CALL calculate_metadata_crc(meta, calculated_crc)
    
    ! Compare with stored CRC
    IF (calculated_crc == meta%crc32) THEN
        verify_metadata_crc = .TRUE.
    ELSE
        status%status_code = IF_STATUS_META_CRC_ERR
        WRITE(status%message, '(A,I0,A,I0)') "CRC32 mismatch: stored(", meta%crc32, "), calculated(", calculated_crc, ")"
    END IF
END FUNCTION verify_metadata_crc

! ==========================================================================
! Helper Function: Calculate Metadata CRC
! ==========================================================================
SUBROUTINE calculate_metadata_crc(meta, crc)
    TYPE(StructMetaType), INTENT(IN) :: meta
    INTEGER(i4), INTENT(OUT) :: crc
    ! Simplified CRC calculation for demonstration
    ! In a real implementation, use a proper CRC algorithm
    crc = 0
    ! Just a placeholder implementation
END SUBROUTINE calculate_metadata_crc

! ==========================================================================
! Helper Function: Calculate Valid Dimension Count
! ==========================================================================
SUBROUTINE calculate_valid_dim_count(dimensions, count)
    INTEGER(i4), INTENT(IN) :: dimensions(IF_MAX_DIMENSIONS)
    INTEGER(i4), INTENT(OUT) :: count
    INTEGER(i4) :: i
    
    count = 0
    DO i = 1, IF_MAX_DIMENSIONS
        IF (dimensions(i) > 0) THEN
            count = count + 1
        ELSE
            EXIT ! Stop at first invalid dimension
        END IF
    END DO
END SUBROUTINE calculate_valid_dim_count

! ==========================================================================
! Helper Function: Calculate Total Elements
! ==========================================================================
SUBROUTINE calculate_total_elements(dimensions, valid_dim_count, total)
    INTEGER(i4), INTENT(IN) :: dimensions(IF_MAX_DIMENSIONS)
    INTEGER(i4), INTENT(IN) :: valid_dim_count
    INTEGER(KIND=8), INTENT(OUT) :: total
    INTEGER(i4) :: i
    
    total = 1
    DO i = 1, valid_dim_count
        total = total * dimensions(i)
    END DO
END SUBROUTINE calculate_total_elements

END MODULE IF_Base_StructMeta_Def