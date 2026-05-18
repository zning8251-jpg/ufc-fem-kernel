!===============================================================================
! MODULE: IF_Base_UnstructMeta_Def
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Def — unstructured metadata descriptors (hash/linked-list/adj-list)
! BRIEF:  Metadata for unstructured data: type attributes, dynamic
!         element statistics, serialization format.
! Status: Draft | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Base_UnstructMeta_Def
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_info, log_warn, log_error, log_debug, &
        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_MEM_ERROR, IF_STATUS_EXISTS, IF_STATUS_NOT_FOUND
    ! Identification Layer: Symbol Table Module (depends on base layer) - import 
    ! variable identification linking components
    USE IF_Base_SymTbl, ONLY: &
        symbol_table_exists, get_variable_data_id, &
        IF_STORAGE_TYPE_UNSTRUCTURED, &
        IF_DATA_TYPE_HASH, IF_DATA_TYPE_LINKED_LIST, IF_DATA_TYPE_ADJACENCY, &
        IF_DATA_TYPE_SKIP_LIST, IF_DATA_TYPE_GRAPH, IF_DATA_TYPE_QUEUE, &
        IF_STATUS_TABLE_NOT_INIT

    IMPLICIT NONE

    ! --------------------------------------------------------------------------
    ! Authoritative unstructured type codes (mapped to SymbolTable IF_DATA_TYPE_*)
    ! --------------------------------------------------------------------------
    PUBLIC :: UNSTRUCT_TYPE_HASH, UNSTRUCT_TYPE_LINKED_LIST, UNSTRUCT_TYPE_ADJACENCY
    PUBLIC :: UNSTRUCT_TYPE_SKIP_LIST, UNSTRUCT_TYPE_GRAPH, UNSTRUCT_TYPE_QUEUE
    INTEGER(i4), PARAMETER :: UNSTRUCT_TYPE_HASH        = IF_DATA_TYPE_HASH
    INTEGER(i4), PARAMETER :: UNSTRUCT_TYPE_LINKED_LIST = IF_DATA_TYPE_LINKED_LIST
    INTEGER(i4), PARAMETER :: UNSTRUCT_TYPE_ADJACENCY   = IF_DATA_TYPE_ADJACENCY
    INTEGER(i4), PARAMETER :: UNSTRUCT_TYPE_SKIP_LIST   = IF_DATA_TYPE_SKIP_LIST
    INTEGER(i4), PARAMETER :: UNSTRUCT_TYPE_GRAPH       = IF_DATA_TYPE_GRAPH
    INTEGER(i4), PARAMETER :: UNSTRUCT_TYPE_QUEUE       = IF_DATA_TYPE_QUEUE

    ! ==========================================================================
    ! 1. Unstructured Metadata-Specific Error Codes (Defined within this module, 
    !    range 211-220, isolated from structured metadata errors)
    ! ==========================================================================
    PUBLIC :: IF_STATUS_UNSMETA_EXISTS, IF_STATUS_UNSMETA_NOT_FOUND, IF_STATUS_UNSMETA_TYPE_INVALID
    PUBLIC :: IF_STATUS_UNSMETA_NO_SYM_LINK, IF_STATUS_UNSMETA_NOT_INIT, IF_STATUS_UNSMETA_ATTR_INVALID
    PUBLIC :: IF_STATUS_UNSMETA_SERIAL_ERR, IF_STATUS_UNSMETA_UPDATE_DENY, unstruct_meta_exists
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSMETA_EXISTS = 211    ! Unstructured metadata exists (duplicate data ID)
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSMETA_NOT_FOUND = 212  ! Unstructured metadata not found
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSMETA_TYPE_INVALID = 213 ! Invalid unstructured type (not supported)
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSMETA_NO_SYM_LINK = 214 ! Metadata not linked to symbol table variable
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSMETA_NOT_INIT = 215    ! Unstructured metadata module not initialized
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSMETA_ATTR_INVALID = 216 ! Invalid unstructured type-specific attribute (e.g., negative hash buckets)
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSMETA_SERIAL_ERR = 217  ! Unstructured metadata serialization/deserialization failed
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSMETA_UPDATE_DENY = 218 ! Update denied for identification fields (data ID/var name/type)

    ! ==========================================================================
    ! 2. Core Constants for Unstructured Metadata (Defined within this module, 
    !    adapted to unstructured data characteristics)
    ! ==========================================================================
    PUBLIC :: IF_MAX_DATA_ID_LEN, IF_MAX_VAR_NAME_LEN, IF_MAX_SERIAL_FMT_LEN, IF_MAX_ATTR_DESC_LEN
    PUBLIC :: IF_MIN_ELEMENT_COUNT, IF_DEFAULT_HASH_BUCKETS, IF_DEFAULT_QUEUE_CAPACITY
    INTEGER(i4), PARAMETER :: IF_MAX_DATA_ID_LEN = 64        ! Max data ID length (aligned with symbol table)
    INTEGER(i4), PARAMETER :: IF_MAX_VAR_NAME_LEN = 64       ! Max variable name length (aligned with symbol table)
    INTEGER(i4), PARAMETER :: IF_MAX_SERIAL_FMT_LEN = 64    ! Max serialization format length (e.g., 'BINARY'/'JSON')
    INTEGER(i4), PARAMETER :: IF_MAX_ATTR_DESC_LEN = 128    ! Max length for type-specific attribute description
    INTEGER(KIND=8), PARAMETER :: IF_MIN_ELEMENT_COUNT = 0 ! Min element count (unstructured data supports empty init)
    INTEGER(i4), PARAMETER :: IF_DEFAULT_HASH_BUCKETS = 100 ! Default hash table bucket count
    INTEGER(i4), PARAMETER :: IF_DEFAULT_QUEUE_CAPACITY = 100 ! Default queue capacity

    ! ==========================================================================
    ! 3. Core Data Types for Unstructured Metadata (Defined within this module, 
    !    including type-specific attributes)
    ! ==========================================================================
    PUBLIC :: UnstructAttrType, UnstructMetaType, UnstructMetaManagerType

    ! Unstructured Type-Specific Attributes: Stores unique attributes for different 
    ! unstructured data types (avoids redundancy)
    TYPE :: UnstructAttrType
        ! Hash table-specific attributes
        INTEGER(i4) :: hash_bucket_count = IF_DEFAULT_HASH_BUCKETS ! Hash bucket count
        REAL :: hash_load_factor = 0.0                    ! Hash load factor (element_count/bucket_count)
        CHARACTER(LEN=32) :: hash_collision = "CHAINING"   ! Collision resolution (CHAINING/OPEN_ADDR)
        ! Linked list-specific attributes
        LOGICAL :: list_is_circular = .FALSE.             ! Whether circular linked list
        LOGICAL :: list_is_double = .TRUE.                ! Whether double-linked list
        ! Graph/adjacency list-specific attributes
        INTEGER(KIND=8) :: graph_vertex_count = 0         ! Number of graph vertices
        INTEGER(KIND=8) :: graph_edge_count = 0           ! Number of graph edges
        LOGICAL :: graph_is_directed = .FALSE.            ! Whether directed graph
        ! Queue-specific attributes
        INTEGER(KIND=8) :: queue_capacity = IF_DEFAULT_QUEUE_CAPACITY ! Queue capacity
        LOGICAL :: queue_is_dynamic = .TRUE.              ! Whether queue supports dynamic expansion
    END TYPE UnstructAttrType

    ! Unstructured Metadata Entry Type: Stores metadata for a single unstructured data item
    TYPE :: UnstructMetaType
        ! Identification linking (aligned with symbol table, non-modifiable)
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""        ! Unique data ID (linked to symbol table)
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: var_name = ""      ! Linked variable name (from symbol table)
        INTEGER(i4) :: storage_type = IF_STORAGE_TYPE_UNSTRUCTURED  ! Storage type (fixed as unstructured)
        INTEGER(i4) :: unstruct_type = 0                        ! Unstructured type (IF_DATA_TYPE_HASH/...)
        
        ! Core attributes (common to unstructured data)
        INTEGER(KIND=8) :: element_count = 0               ! Current number of elements
        TYPE(UnstructAttrType) :: type_attr = UnstructAttrType()  ! Explicit init for nested type
        CHARACTER(LEN=IF_MAX_SERIAL_FMT_LEN) :: serial_format = "BINARY" ! Serialization format
        INTEGER(KIND=8) :: total_size = 0                 ! Total memory size (bytes)
        
        ! Integrity and lifecycle
        INTEGER(i4) :: crc32 = 0                              ! Data checksum (ensures integrity)
        CHARACTER(LEN=20) :: create_time = ""             ! Creation time (YYYY-MM-DD HH:MM:SS)
        CHARACTER(LEN=20) :: update_time = ""             ! Last update time
        LOGICAL :: is_valid = .FALSE.                    ! Metadata validity (logical deletion flag)
        LOGICAL :: is_frozen = .FALSE.                   ! Whether frozen (attribute updates denied)
    END TYPE UnstructMetaType

    ! Unstructured Metadata Manager Type: Manages all unstructured metadata entries
    TYPE :: UnstructMetaManagerType
        LOGICAL :: initialized = .FALSE.                  ! Whether manager is initialized
        INTEGER(i4) :: max_meta_count = 0                     ! Max number of supported metadata entries
        INTEGER(i4) :: current_meta_count = 0                 ! Current number of valid metadata entries
        TYPE(UnstructMetaType), ALLOCATABLE :: meta_list(:) ! Array of metadata entries
    END TYPE UnstructMetaManagerType

    ! ==========================================================================
    ! 4. Module Global Instance (PRIVATE+SAVE: Fortran2003 Standard, ensures 
    !    persistence and no direct external access)
    ! ==========================================================================
    TYPE(UnstructMetaManagerType), PRIVATE, SAVE :: global_unstruct_meta_mgr

    ! ==========================================================================
    ! 5. Public Interface Export (Minimal Exposure Principle: Only export types 
    !    and subroutines needed externally)
    ! ==========================================================================
    PRIVATE
    PUBLIC :: init_unstruct_meta_mgr, destroy_unstruct_meta_mgr
    PUBLIC :: unstruct_meta_create, unstruct_meta_query, unstruct_meta_update, unstruct_meta_delete
    PUBLIC :: unstruct_meta_try_query
    PUBLIC :: unstruct_meta_validate, get_unstruct_meta_count

CONTAINS
    ! ==========================================================================
    ! Subroutine: Initialize Unstructured Metadata Manager
    ! Function: Allocate metadata array, initialize status, relies on error module 
    ! to record initialization failures
    ! ==========================================================================
    SUBROUTINE init_unstruct_meta_mgr(status, max_meta_count)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER, INTENT(IN), OPTIONAL :: max_meta_count  ! Optional: Custom max metadata entry count
        INTEGER(i4) :: local_max_count
        CHARACTER(LEN=20) :: init_time

        CALL init_error_status(status)

        ! Pre-check: Whether manager is already initialized (base error code: IF_STATUS_EXISTS)
        IF (global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Unstructured metadata manager already initialized"
            CALL log_info("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Handle max metadata entry count (default: 500, adapted to unstructured scenarios)
        local_max_count = 500
        IF (PRESENT(max_meta_count)) THEN
            IF (max_meta_count <= 0) THEN
                status%status_code = IF_STATUS_ERROR
                status%message = "Max meta count must be positive integer"
                CALL log_error("UnstructMetaData", TRIM(status%message))
                RETURN
            END IF
            local_max_count = max_meta_count
        END IF

        ! Allocate metadata array (base error code: IF_STATUS_MEM_ERROR)
        ALLOCATE(global_unstruct_meta_mgr%meta_list(local_max_count), STAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0)') "Allocate unstruct meta list failed (stat=", status%io_stat
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Initialize manager status
        global_unstruct_meta_mgr%max_meta_count = local_max_count
        global_unstruct_meta_mgr%current_meta_count = 0
        global_unstruct_meta_mgr%initialized = .TRUE.
        CALL get_timestamp(init_time)  ! Get initialization time

        CALL log_info("UnstructMetaData", "Initialized unstructured metadata manager (max meta count="//&
            TRIM(INT_TO_STR(local_max_count))//", init time="//TRIM(init_time)//")")
    END SUBROUTINE init_unstruct_meta_mgr

    ! ==========================================================================
    ! Subroutine: Destroy Unstructured Metadata Manager
    ! Function: Deallocate metadata array, reset status, relies on error module 
    ! to record destruction failures
    ! ==========================================================================
    SUBROUTINE destroy_unstruct_meta_mgr(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Pre-check: Whether manager is uninitialized (module-specific error code: IF_STATUS_UNSMETA_NOT_INIT)
        IF (.NOT. global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_INIT
            status%message = "Unstructured metadata manager not initialized"
            CALL log_warn("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Deallocate metadata array (base error code: IF_STATUS_MEM_ERROR)
        IF (ALLOCATED(global_unstruct_meta_mgr%meta_list)) THEN
            DEALLOCATE(global_unstruct_meta_mgr%meta_list, STAT=status%io_stat)
            IF (status%io_stat /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                WRITE(status%message, '(A,I0)') "Deallocate unstruct meta list failed (stat=", status%io_stat
                CALL log_error("UnstructMetaData", TRIM(status%message))
            END IF
        END IF

        ! Reset manager status
        global_unstruct_meta_mgr%initialized = .FALSE.
        global_unstruct_meta_mgr%max_meta_count = 0
        global_unstruct_meta_mgr%current_meta_count = 0

        CALL log_info("UnstructMetaData", "Destroyed unstructured metadata manager")
    END SUBROUTINE destroy_unstruct_meta_mgr

    ! ==========================================================================
    ! Subroutine: Create Unstructured Metadata (Links to symbol table variable, 
    ! initializes type-specific attributes)
    ! ==========================================================================
    SUBROUTINE unstruct_meta_create(var_name, unstruct_type, init_attr, meta, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name          ! Linked variable name (from symbol table)
        INTEGER(i4), INTENT(IN) :: unstruct_type              ! Unstructured type (IF_DATA_TYPE_HASH/...)
        TYPE(UnstructAttrType), INTENT(IN) :: init_attr   ! Initial type-specific attributes
        TYPE(UnstructMetaType), INTENT(OUT) :: meta       ! Output created metadata
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id
        INTEGER(i4) :: free_idx
        CHARACTER(LEN=20) :: create_time
        LOGICAL :: sym_exists

        CALL init_error_status(status)
        meta = UnstructMetaType()  ! Initialize metadata to default values

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_UNSMETA_NOT_INIT)
        IF (.NOT. global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_INIT
            status%message = "Unstructured metadata manager not initialized"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Whether variable is registered in symbol table (depends on identification layer)
        sym_exists = symbol_table_exists(var_name, status)
        IF (status%status_code == IF_STATUS_TABLE_NOT_INIT) THEN
            status%status_code = IF_STATUS_UNSMETA_NO_SYM_LINK
            status%message = "Symbol table not initialized, cannot link variable"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF
        IF (.NOT. sym_exists) THEN
            status%status_code = IF_STATUS_UNSMETA_NO_SYM_LINK
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' not registered in symbol table"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 3: Get data ID linked to variable (depends on identification layer)
        CALL get_variable_data_id(var_name, data_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            status%status_code = IF_STATUS_UNSMETA_NO_SYM_LINK
            status%message = "Failed to get data ID from symbol table: "//TRIM(status%message)
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 4: Whether metadata already exists (specific error code: IF_STATUS_UNSMETA_EXISTS)
        IF (unstruct_meta_exists(data_id, status)) THEN
            status%status_code = IF_STATUS_UNSMETA_EXISTS
            WRITE(status%message, '(A,A,A)') "Unstructured metadata for data ID '", TRIM(data_id), "' already exists"
            CALL log_info("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 5: Validity of unstructured type and its attributes
        IF (.NOT. validate_unstruct_params(unstruct_type, init_attr, status)) THEN
            CALL log_error("UnstructMetaData", "Invalid unstructured params: "//TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 6: Whether manager is full (base error code: IF_STATUS_MEM_ERROR)
        free_idx = find_free_unstruct_entry(status)
        IF (free_idx == 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A,I0)') "Unstructured metadata manager full (max ", &
                global_unstruct_meta_mgr%max_meta_count, ", current ", global_unstruct_meta_mgr%current_meta_count, ")" 
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Populate core unstructured metadata info
        CALL get_timestamp(create_time)
        meta%data_id = TRIM(data_id)
        meta%var_name = TRIM(var_name)
        meta%unstruct_type = unstruct_type
        meta%type_attr = init_attr  ! Assign type-specific attributes
        meta%create_time = TRIM(create_time)
        meta%update_time = TRIM(create_time)
        meta%is_valid = .TRUE.

        ! Calculate total memory size (simplified: estimated by type; extendable to precise calc for industrial use)
        meta%total_size = calc_unstruct_size(unstruct_type, init_attr, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructMetaData", "Failed to calculate unstructured size: "//TRIM(status%message))
            RETURN
        END IF

        ! Save metadata to manager
        global_unstruct_meta_mgr%meta_list(free_idx) = meta
        global_unstruct_meta_mgr%current_meta_count = global_unstruct_meta_mgr%current_meta_count + 1

        ! Log successful creation (include key attributes)
        CALL log_info("UnstructMetaData", "Created unstructured metadata: var_name='"//TRIM(var_name)//&
                      "', data_id='"//TRIM(data_id)//"', type="//TRIM(unstruct_type_to_str(unstruct_type))//&
                      ", elements="//TRIM(INT8_TO_STR(meta%element_count))//"'")
    END SUBROUTINE unstruct_meta_create

    ! ==========================================================================
    ! Subroutine: Query Unstructured Metadata (Supports query by data ID/variable name)
    ! ==========================================================================
    SUBROUTINE unstruct_meta_query(query_key, query_type, meta, status)
        CHARACTER(LEN=*), INTENT(IN) :: query_key  ! Query key (data ID or variable name)
        INTEGER(i4), INTENT(IN) :: query_type          ! Query type: 1=data ID, 2=variable name
        TYPE(UnstructMetaType), INTENT(OUT) :: meta ! Output queried metadata
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id
        INTEGER(i4) :: i

        CALL init_error_status(status)
        meta = UnstructMetaType()  ! Initialize metadata to default values

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_UNSMETA_NOT_INIT)
        IF (.NOT. global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_INIT
            status%message = "Unstructured metadata manager not initialized"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Validity of query type
        IF (query_type /= 1 .AND. query_type /= 2) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Query type must be 1(data ID) or 2(variable name)"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Process by query type
        SELECT CASE (query_type)
            CASE (1)  ! Query by data ID
                DO i = 1, global_unstruct_meta_mgr%max_meta_count
                    IF (global_unstruct_meta_mgr%meta_list(i)%is_valid .AND. &
                        TRIM(global_unstruct_meta_mgr%meta_list(i)%data_id) == TRIM(query_key)) THEN
                        meta = global_unstruct_meta_mgr%meta_list(i)
                        status%status_code = IF_STATUS_OK
                        CALL log_debug("UnstructMetaData", "Queried unstructured metadata by data ID: '"//&
                            TRIM(query_key)//"'")
                        RETURN
                    END IF
                END DO

            CASE (2)  ! Query by variable name (get data ID first)
                CALL get_variable_data_id(query_key, data_id, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    status%status_code = IF_STATUS_UNSMETA_NO_SYM_LINK
                    status%message = "Failed to get data ID for variable: "//TRIM(status%message)
                    CALL log_error("UnstructMetaData", TRIM(status%message))
                    RETURN
                END IF
                ! Reuse data ID query logic
                DO i = 1, global_unstruct_meta_mgr%max_meta_count
                    IF (global_unstruct_meta_mgr%meta_list(i)%is_valid .AND. &
                        TRIM(global_unstruct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                        meta = global_unstruct_meta_mgr%meta_list(i)
                        status%status_code = IF_STATUS_OK
                        CALL log_debug("UnstructMetaData", "Queried unstructured metadata by var name: "//&
                            TRIM(query_key))
                        RETURN
                    END IF
                END DO
        END SELECT

        ! Metadata not found (specific error code: IF_STATUS_UNSMETA_NOT_FOUND)
        status%status_code = IF_STATUS_UNSMETA_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Unstructured metadata for '", TRIM(query_key), "' not found"
        CALL log_error("UnstructMetaData", TRIM(status%message))
    END SUBROUTINE unstruct_meta_query

    SUBROUTINE unstruct_meta_try_query(query_key, query_type, meta, found, status)
        CHARACTER(LEN=*), INTENT(IN) :: query_key
        INTEGER(i4), INTENT(IN) :: query_type
        TYPE(UnstructMetaType), INTENT(OUT) :: meta
        LOGICAL, INTENT(OUT) :: found
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id
        INTEGER(i4) :: i

        CALL init_error_status(status)
        found = .FALSE.
        meta = UnstructMetaType()

        IF (.NOT. global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_INIT
            status%message = "Unstructured metadata manager not initialized"
            RETURN
        END IF

        IF (query_type /= 1 .AND. query_type /= 2) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Query type must be 1(data ID) or 2(variable name)"
            RETURN
        END IF

        SELECT CASE (query_type)
            CASE (1)
                DO i = 1, global_unstruct_meta_mgr%max_meta_count
                    IF (global_unstruct_meta_mgr%meta_list(i)%is_valid .AND. &
                        TRIM(global_unstruct_meta_mgr%meta_list(i)%data_id) == TRIM(query_key)) THEN
                        meta = global_unstruct_meta_mgr%meta_list(i)
                        status%status_code = IF_STATUS_OK
                        found = .TRUE.
                        RETURN
                    END IF
                END DO

            CASE (2)
                CALL get_variable_data_id(query_key, data_id, status)
                IF (status%status_code /= IF_STATUS_OK) THEN
                    status%status_code = IF_STATUS_UNSMETA_NO_SYM_LINK
                    status%message = "Failed to get data ID for variable: "//TRIM(status%message)
                    RETURN
                END IF

                DO i = 1, global_unstruct_meta_mgr%max_meta_count
                    IF (global_unstruct_meta_mgr%meta_list(i)%is_valid .AND. &
                        TRIM(global_unstruct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                        meta = global_unstruct_meta_mgr%meta_list(i)
                        status%status_code = IF_STATUS_OK
                        found = .TRUE.
                        RETURN
                    END IF
                END DO
        END SELECT

        status%status_code = IF_STATUS_UNSMETA_NOT_FOUND
    END SUBROUTINE unstruct_meta_try_query

    ! ==========================================================================
    ! Subroutine: Update Unstructured Metadata (Only non-identification fields allowed)
    ! ==========================================================================
    SUBROUTINE unstruct_meta_update(data_id, update_field, new_value, new_attr, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id          ! Data ID (unique identifier)
        INTEGER(i4), INTENT(IN) :: update_field              ! Update field: 1=element count, 2=hash attrs, 3=graph edges, 4=CRC32
        INTEGER(KIND=8), INTENT(IN) :: new_value         ! New value (for numeric types)
        TYPE(UnstructAttrType), INTENT(IN), OPTIONAL :: new_attr  ! New attributes (for complex types)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        CHARACTER(LEN=20) :: update_time
        TYPE(UnstructMetaType) :: temp_meta

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_UNSMETA_NOT_INIT)
        IF (.NOT. global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_INIT
            status%message = "Unstructured metadata manager not initialized"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Whether metadata exists and is not frozen
        DO i = 1, global_unstruct_meta_mgr%max_meta_count
            IF (global_unstruct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_unstruct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                ! Check if frozen (updates denied)
                IF (global_unstruct_meta_mgr%meta_list(i)%is_frozen) THEN
                    status%status_code = IF_STATUS_UNSMETA_UPDATE_DENY
                    status%message = "Unstructured metadata is frozen, cannot update"
                    CALL log_error("UnstructMetaData", TRIM(status%message))
                    RETURN
                END IF
                temp_meta = global_unstruct_meta_mgr%meta_list(i)
                EXIT
            END IF
        END DO
        IF (.NOT. temp_meta%is_valid) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_FOUND
            WRITE(status%message, '(A,A,A)') "Unstructured metadata for data ID '", TRIM(data_id), "' not found"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Update by field (only non-identification fields allowed)
        SELECT CASE (update_field)
            CASE (1)  ! Update element count
                IF (new_value < IF_MIN_ELEMENT_COUNT) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Element count cannot be negative"
                    CALL log_error("UnstructMetaData", TRIM(status%message))
                    RETURN
                END IF
                temp_meta%element_count = new_value
                ! Sync hash load factor if hash table
                IF (temp_meta%unstruct_type == IF_DATA_TYPE_HASH) THEN
                    temp_meta%type_attr%hash_load_factor = REAL(new_value) / REAL(temp_meta%type_attr%hash_bucket_count)
                END IF
                CALL log_debug("UnstructMetaData", "Updated element count for data ID '"//&
                    TRIM(data_id)//"' to "//TRIM(INT8_TO_STR(new_value))//"'")

            CASE (2)  ! Update hash table-specific attributes (buckets/load factor)
                IF (temp_meta%unstruct_type /= IF_DATA_TYPE_HASH) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Only hash table supports bucket count update"
                    CALL log_error("UnstructMetaData", TRIM(status%message))
                    RETURN
                END IF
                IF (.NOT. PRESENT(new_attr)) THEN
                    status%status_code = IF_STATUS_ERROR
                    status%message = "New hash attributes not provided"
                    CALL log_error("UnstructMetaData", TRIM(status%message))
                    RETURN
                END IF
                temp_meta%type_attr%hash_bucket_count = new_attr%hash_bucket_count
                temp_meta%type_attr%hash_load_factor = new_attr%hash_load_factor
                CALL log_debug("UnstructMetaData", "Updated hash table attrs for data ID '"//&
                    TRIM(data_id)//"' (buckets="//TRIM(INT_TO_STR(new_attr%hash_bucket_count))//")")

            CASE (3)  ! Update graph edge count
                IF (temp_meta%unstruct_type /= IF_DATA_TYPE_GRAPH .AND. temp_meta%unstruct_type /= IF_DATA_TYPE_ADJACENCY) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Only graph/adjacency list supports edge count update"
                    CALL log_error("UnstructMetaData", TRIM(status%message))
                    RETURN
                END IF
                IF (new_value < 0) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Edge count cannot be negative"
                    CALL log_error("UnstructMetaData", TRIM(status%message))
                    RETURN
                END IF
                temp_meta%type_attr%graph_edge_count = new_value
                CALL log_debug("UnstructMetaData", "Updated edge count for data ID '"//&
                    TRIM(data_id)//"' to "//TRIM(INT8_TO_STR(new_value))//"'")

            CASE (4)  ! Update CRC32 checksum
                IF (new_value < 0_8) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "CRC32 value cannot be negative"
                    CALL log_error("UnstructMetaData", TRIM(status%message))
                    RETURN
                END IF
                temp_meta%crc32 = INT(new_value)
                CALL log_debug("UnstructMetaData", "Updated CRC32 for data ID '"//TRIM(data_id)//&
                    "' to "//TRIM(INT8_TO_STR(new_value))//"")

            CASE DEFAULT
                status%status_code = IF_STATUS_ERROR
                status%message = "Invalid update field (1=element count, 2=hash attrs, 3=graph edges, 4=CRC32)"
                CALL log_error("UnstructMetaData", TRIM(status%message))
                RETURN
        END SELECT

        ! Update timestamp and save
        CALL get_timestamp(update_time)
        temp_meta%update_time = TRIM(update_time)
        DO i = 1, global_unstruct_meta_mgr%max_meta_count
            IF (TRIM(global_unstruct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                global_unstruct_meta_mgr%meta_list(i) = temp_meta
                EXIT
            END IF
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE unstruct_meta_update

    ! ==========================================================================
    ! Subroutine: Delete Unstructured Metadata (Logical deletion, release dynamic resources)
    ! ==========================================================================
    SUBROUTINE unstruct_meta_delete(data_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id  ! Data ID (unique identifier)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_UNSMETA_NOT_INIT)
        IF (.NOT. global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_INIT
            status%message = "Unstructured metadata manager not initialized"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        ! Find metadata and mark as invalid
        DO i = 1, global_unstruct_meta_mgr%max_meta_count
            IF (global_unstruct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_unstruct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                ! Logical deletion: mark as invalid
                global_unstruct_meta_mgr%meta_list(i)%is_valid = .FALSE.
                global_unstruct_meta_mgr%current_meta_count = global_unstruct_meta_mgr%current_meta_count - 1

                CALL log_info("UnstructMetaData", "Deleted unstructured metadata: data ID='"//TRIM(data_id)//"'")
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO

        ! Metadata not found (specific error code: IF_STATUS_UNSMETA_NOT_FOUND)
        status%status_code = IF_STATUS_UNSMETA_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Unstructured metadata for data ID '", TRIM(data_id), "' not found"
        CALL log_error("UnstructMetaData", TRIM(status%message))
    END SUBROUTINE unstruct_meta_delete

    ! ==========================================================================
    ! Subroutine: Validate Unstructured Metadata Integrity (Checksum Match)
    ! ==========================================================================
    SUBROUTINE unstruct_meta_validate(data_id, current_crc32, is_valid, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id      ! Data ID
        INTEGER(i4), INTENT(IN) :: current_crc32        ! Current data checksum
        LOGICAL, INTENT(OUT) :: is_valid           ! Validation result (.TRUE.=match)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(UnstructMetaType) :: meta

        CALL init_error_status(status)
        is_valid = .FALSE.

        ! Query metadata
        CALL unstruct_meta_query(data_id, 1, meta, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Checksum match check (skip if metadata checksum is 0)
        IF (meta%crc32 == 0) THEN
            status%status_code = IF_STATUS_OK
            is_valid = .TRUE.
            CALL log_warn("UnstructMetaData", "CRC32 not set for data ID '"//TRIM(data_id)//"', skip validation")
            RETURN
        END IF

        IF (meta%crc32 == current_crc32) THEN
            is_valid = .TRUE.
            CALL log_debug("UnstructMetaData", "Unstructured metadata validation passed for data ID '"//TRIM(data_id)//"'")
        ELSE
            status%status_code = IF_STATUS_UNSMETA_SERIAL_ERR
            WRITE(status%message, '(A,I0,A,I0)') "CRC32 mismatch (meta: ", meta%crc32, ", current: ", current_crc32, ")" 
            CALL log_error("UnstructMetaData", TRIM(status%message))
        END IF
    END SUBROUTINE unstruct_meta_validate

    ! ==========================================================================
    ! Subroutine: Get Total Count of Current Unstructured Metadata Entries
    ! ==========================================================================
    SUBROUTINE get_unstruct_meta_count(count, status)
        INTEGER(i4), INTENT(OUT) :: count  ! Output current number of valid metadata entries
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        count = 0

        ! Pre-check: Whether manager is initialized (specific error code: IF_STATUS_UNSMETA_NOT_INIT)
        IF (.NOT. global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_INIT
            status%message = "Unstructured metadata manager not initialized"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        count = global_unstruct_meta_mgr%current_meta_count
        status%status_code = IF_STATUS_OK
        CALL log_debug("UnstructMetaData", "Current unstructured metadata count: "//TRIM(INT_TO_STR(count)))
    END SUBROUTINE get_unstruct_meta_count

    ! ==========================================================================
    ! Utility Function: Check if Unstructured Metadata Exists (Internal Use)
    ! ==========================================================================
    LOGICAL FUNCTION unstruct_meta_exists(data_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        unstruct_meta_exists = .FALSE.

        IF (.NOT. global_unstruct_meta_mgr%initialized) THEN
            status%status_code = IF_STATUS_UNSMETA_NOT_INIT
            status%message = "Unstructured metadata manager not initialized"
            CALL log_error("UnstructMetaData", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, global_unstruct_meta_mgr%max_meta_count
            IF (global_unstruct_meta_mgr%meta_list(i)%is_valid .AND. &
                TRIM(global_unstruct_meta_mgr%meta_list(i)%data_id) == TRIM(data_id)) THEN
                unstruct_meta_exists = .TRUE.
                RETURN
            END IF
        END DO

        status%status_code = IF_STATUS_UNSMETA_NOT_FOUND
    END FUNCTION unstruct_meta_exists

    ! ==========================================================================
    ! Utility Function: Find Index of Free Unstructured Metadata Entry (Internal Use)
    ! ==========================================================================
    INTEGER FUNCTION find_free_unstruct_entry(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        find_free_unstruct_entry = 0

        ! Iterate to find first invalid entry (reuse first to avoid fragmentation)
        DO i = 1, global_unstruct_meta_mgr%max_meta_count
            IF (.NOT. global_unstruct_meta_mgr%meta_list(i)%is_valid) THEN
                find_free_unstruct_entry = i
                RETURN
            END IF
        END DO

        ! No free entry (return 0; external logic judges manager as full)
        status%status_code = IF_STATUS_MEM_ERROR
    END FUNCTION find_free_unstruct_entry

    ! ==========================================================================
    ! Utility Function: Validate Unstructured Metadata Parameters (Internal Use)
    ! ==========================================================================
    LOGICAL FUNCTION validate_unstruct_params(unstruct_type, attr, status)
        INTEGER(i4), INTENT(IN) :: unstruct_type
        TYPE(UnstructAttrType), INTENT(IN) :: attr
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(KIND=8) :: max_edges

        CALL init_error_status(status)
        validate_unstruct_params = .FALSE.

        ! Check 1: Valid unstructured type
        IF (.NOT. (unstruct_type == UNSTRUCT_TYPE_HASH .OR. unstruct_type == UNSTRUCT_TYPE_LINKED_LIST .OR. &
                  unstruct_type == UNSTRUCT_TYPE_ADJACENCY .OR. unstruct_type == UNSTRUCT_TYPE_SKIP_LIST .OR. &
                  unstruct_type == UNSTRUCT_TYPE_GRAPH .OR. unstruct_type == UNSTRUCT_TYPE_QUEUE)) THEN
            status%status_code = IF_STATUS_UNSMETA_TYPE_INVALID
            status%message = "Unsupported unstructured type (must be hash/linked-list/adjacency/skip-list/graph/queue)"  
            RETURN
        END IF

        ! Check 2: Validity of type-specific attributes
        SELECT CASE (unstruct_type)
            CASE (UNSTRUCT_TYPE_HASH)
                IF (attr%hash_bucket_count <= 0) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Hash bucket count must be positive"
                    RETURN
                END IF
                IF (.NOT. (attr%hash_collision == "CHAINING" .OR. attr%hash_collision == "OPEN_ADDR")) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Hash collision method must be CHAINING or OPEN_ADDR"  
                    RETURN
                END IF

            CASE (UNSTRUCT_TYPE_LINKED_LIST)
                ! Circular linked list must be double-linked (business constraint)
                IF (attr%list_is_circular .AND. .NOT. attr%list_is_double) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Circular linked list must be double-linked"
                    RETURN
                END IF

            CASE (UNSTRUCT_TYPE_GRAPH, UNSTRUCT_TYPE_ADJACENCY)
                IF (attr%graph_edge_count < 0) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Graph edge count cannot be negative"
                    RETURN
                END IF
                ! Edge count cannot exceed maximum possible (undirected: n*(n-1)/2, directed: n*n)
                IF (attr%graph_vertex_count > 0) THEN
                    max_edges = MERGE(attr%graph_vertex_count * attr%graph_vertex_count, &
                                     attr%graph_vertex_count * (attr%graph_vertex_count - 1) / 2, &
                                     attr%graph_is_directed)
                    IF (attr%graph_edge_count > max_edges) THEN
                        status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                        WRITE(status%message, '(A,I0,A,I0)') "Edge count exceeds max ("//&
                            TRIM(INT8_TO_STR(max_edges))//"), got ", attr%graph_edge_count
                        RETURN
                    END IF
                END IF

            CASE (UNSTRUCT_TYPE_QUEUE)
                IF (attr%queue_capacity <= 0 .AND. .NOT. attr%queue_is_dynamic) THEN
                    status%status_code = IF_STATUS_UNSMETA_ATTR_INVALID
                    status%message = "Fixed-capacity queue must have positive capacity"
                    RETURN
                END IF
        END SELECT

        ! All parameters passed validation
        validate_unstruct_params = .TRUE.
    END FUNCTION validate_unstruct_params

    ! ==========================================================================
    ! Utility Function: Estimate Unstructured Data Total Memory Size (Internal Use, 
    ! extendable to precise calculation for industrial use)
    ! ==========================================================================
    INTEGER(KIND=8) FUNCTION calc_unstruct_size(unstruct_type, attr, status)
        INTEGER(i4), INTENT(IN) :: unstruct_type
        TYPE(UnstructAttrType), INTENT(IN) :: attr
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(KIND=8) :: elem_size

        CALL init_error_status(status)
        calc_unstruct_size = 0

        ! Estimate single element size by type (bytes)
        SELECT CASE (unstruct_type)
            CASE (UNSTRUCT_TYPE_HASH)
            elem_size = 336! Hash node: key(64)+value(256)+pointer(8), aligned to 336 bytes
            CASE (UNSTRUCT_TYPE_LINKED_LIST)
            elem_size = 272! Linked list node: data(256)+double pointers(16), aligned to 272 bytes
            CASE (UNSTRUCT_TYPE_ADJACENCY)
            elem_size = 24! Adjacency node: vertex(4)+weight(8)+pointer(8), aligned to 24 bytes
            CASE (UNSTRUCT_TYPE_SKIP_LIST)
            elem_size = 352! Skip list node: key(64)+value(256)+4-level pointers(32), aligned to 352 bytes
            CASE (UNSTRUCT_TYPE_GRAPH)
            elem_size = 64! Graph vertex: attributes(48)+adjacency pointer(8), aligned to 64 bytes
            CASE (UNSTRUCT_TYPE_QUEUE)
            elem_size = 64! Queue element: general data (64 bytes)
            CASE DEFAULT
                status%status_code = IF_STATUS_UNSMETA_TYPE_INVALID
                status%message = "Unsupported type for size calculation"
                RETURN
        END SELECT

        ! Calculate total size (element count × element size; estimate by default capacity if no elements)
        IF (attr%queue_capacity > 0 .AND. unstruct_type == UNSTRUCT_TYPE_QUEUE) THEN
            calc_unstruct_size = attr%queue_capacity * elem_size
        ELSE IF (attr%hash_bucket_count > 0 .AND. unstruct_type == UNSTRUCT_TYPE_HASH) THEN
            calc_unstruct_size = attr%hash_bucket_count * elem_size
        ELSE
            calc_unstruct_size = 10 * elem_size  ! Default estimate for 10 elements
        END IF
    END FUNCTION calc_unstruct_size

    ! ==========================================================================
    ! Utility Function: Convert Unstructured Type to String (For Logging, Internal Use)
    ! ==========================================================================
    FUNCTION unstruct_type_to_str(type_code) RESULT(type_str)
        INTEGER(i4), INTENT(IN) :: type_code
        CHARACTER(LEN=32) :: type_str

        SELECT CASE (type_code)
            CASE (UNSTRUCT_TYPE_HASH)
            type_str = "HashTable"
            CASE (UNSTRUCT_TYPE_LINKED_LIST)
            type_str = "LinkedList"
            CASE (UNSTRUCT_TYPE_ADJACENCY)
            type_str = "AdjacencyList"
            CASE (UNSTRUCT_TYPE_SKIP_LIST)
            type_str = "SkipList"
            CASE (UNSTRUCT_TYPE_GRAPH)
            type_str = "Graph"
            CASE (UNSTRUCT_TYPE_QUEUE)
            type_str = "Queue"
            CASE DEFAULT
            type_str = "UnknownType"
        END SELECT
    END FUNCTION unstruct_type_to_str

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
    FUNCTION INT8_TO_STR(i8) RESULT(str)
        INTEGER(KIND=8), INTENT(IN) :: i8
        CHARACTER(LEN=30) :: str

        WRITE(str, '(I0)') i8
        str = TRIM(ADJUSTL(str))
    END FUNCTION INT8_TO_STR

END MODULE IF_Base_UnstructMeta_Def