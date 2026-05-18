!===============================================================================
! MODULE: IF_Base_SymTbl
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Mgr — symbol table manager (name→ID registry)
! BRIEF:  Full variable lifecycle: registration, query, existence check,
!         batch operations for resource name→data-ID mapping.
! Status: Draft | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Base_SymTbl
    ! Import project-standard precision parameters
    USE IF_Prec_Core, ONLY: wp, i4
    
    ! Only import base error components from ErrorLogBaseModule: error status type, 
    ! initialization function, logging functions, base error codes.
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_info, log_warn, log_error, log_debug, &
        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN, IF_STATUS_MEM_ERROR, IF_STATUS_IO_ERROR, &
        IF_STATUS_NOT_FOUND, IF_STATUS_INVALID, IF_STATUS_EXISTS, IF_STATUS_FATAL, IF_STATUS_UNSUPPORTED
    IMPLICIT NONE
    
    ! --------------------------------------------------------------------------
    ! 1. Symbol Table-Specific Error Codes (defined within this module, no external dependency)
    ! --------------------------------------------------------------------------
    PUBLIC :: IF_STATUS_VAR_NAME_INVALID, IF_STATUS_DATA_ID_EMPTY, IF_STATUS_TYPE_MISMATCH
    PUBLIC :: IF_STATUS_TABLE_FULL, IF_STATUS_TABLE_NOT_INIT
    PUBLIC :: IF_STATUS_SUCCESS, IF_STATUS_INIT_ERROR, IF_STATUS_REGISTER_ERROR
      PUBLIC :: IF_STATUS_UNREGISTER_ERROR, IF_STATUS_NOT_IMPLEMENTED, IF_STATUS_FILE_ERROR
      INTEGER(i4), PARAMETER :: IF_STATUS_VAR_NAME_INVALID = 101  ! Invalid variable name (char rule/keyword conflict)
      INTEGER(i4), PARAMETER :: IF_STATUS_DATA_ID_EMPTY = 102    ! Data ID cannot be empty string
      INTEGER(i4), PARAMETER :: IF_STATUS_TYPE_MISMATCH = 103   ! Data type mismatch with stored type
      INTEGER(i4), PARAMETER :: IF_STATUS_TABLE_FULL = 104      ! Symbol table full; cannot add new entries
      INTEGER(i4), PARAMETER :: IF_STATUS_TABLE_NOT_INIT = 105  ! Symbol table not initialized; cannot perform operations
      INTEGER(i4), PARAMETER :: IF_STATUS_FILE_ERROR = 106      ! File operation error
      INTEGER(i4), PARAMETER :: IF_STATUS_SUCCESS = 0           ! Operation successful
      INTEGER(i4), PARAMETER :: IF_STATUS_INIT_ERROR = -1       ! Initialization error
      INTEGER(i4), PARAMETER :: IF_STATUS_REGISTER_ERROR = -2   ! Registration error
      INTEGER(i4), PARAMETER :: IF_STATUS_UNREGISTER_ERROR = -3 ! Unregistration error
      INTEGER(i4), PARAMETER :: IF_STATUS_NOT_IMPLEMENTED = -4  ! Feature not implemented
    
    ! --------------------------------------------------------------------------
    ! 2. Core Configuration Constants (symbol table-specific, no external dependency)
    ! --------------------------------------------------------------------------
    PUBLIC :: IF_STORAGE_TYPE_STRUCTURED, IF_STORAGE_TYPE_UNSTRUCTURED
    PUBLIC :: IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR, IF_DATA_TYPE_STRUCT, IF_DATA_TYPE_CLASS
    PUBLIC :: IF_DATA_TYPE_HASH, IF_DATA_TYPE_LINKED_LIST, IF_DATA_TYPE_ADJACENCY, IF_DATA_TYPE_SKIP_LIST
    PUBLIC :: IF_DATA_TYPE_GRAPH, IF_DATA_TYPE_QUEUE
    ! Data storage types: Distinguish structured/unstructured for external registration
    INTEGER(i4), PARAMETER :: IF_STORAGE_TYPE_STRUCTURED = 1    ! Structured data (array/struct/class)
    INTEGER(i4), PARAMETER :: IF_STORAGE_TYPE_UNSTRUCTURED = 2  ! Unstructured data (hash table/linked list, etc.)
    ! Data types: Cover all structured/unstructured scenarios, defined within this module
    ! Structured data types
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_INT = 1     ! Integer type
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_DP = 2      ! Double precision type
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_CHAR = 3    ! Character type
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_STRUCT = 4  ! Structure type
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_CLASS = 5   ! Class type
    ! Unstructured data types
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_HASH = 10   ! Hash table
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_LINKED_LIST = 11  ! Linked list
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_ADJACENCY = 12    ! Adjacency list
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_SKIP_LIST = 13    ! Skip list
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_GRAPH = 14       ! Graph structure
    INTEGER(i4), PARAMETER :: IF_DATA_TYPE_QUEUE = 15       ! Queue
    ! Symbol table capacity and string length limits
    INTEGER(i4), PARAMETER :: IF_MAX_VAR_NAME_LEN = 64    ! Max variable name length (characters)
    INTEGER(i4), PARAMETER :: IF_MAX_DATA_ID_LEN = 64    ! Max data ID length (characters)
    INTEGER(i4), PARAMETER :: IF_DEFAULT_MAX_ENTRIES = 1000  ! Default max number of entries
    INTEGER(i4), PARAMETER :: IF_KEYWORD_COUNT = 33     ! Number of Fortran keywords (simplified version)
    INTEGER(i4), PARAMETER :: IF_MAX_VERSIONS = 10      ! Maximum number of versions to keep
    
    ! Fortran keyword list: Prevent variable name conflicts (all padded to len 20 for F90)
    CHARACTER(LEN=20), PARAMETER :: FORTRAN_KEYWORDS(IF_KEYWORD_COUNT) = [ &
        "PROGRAM             ", "MODULE              ", "SUBROUTINE          ", &
        "FUNCTION            ", "TYPE                ", "LOGICAL             ", &
        "INTEGER             ", "REAL                ", "DOUBLE              ", &
        "CHARACTER           ", "COMPLEX             ", "IF                  ", &
        "THEN                ", "ELSE                ", "ELSE IF             ", &
        "END IF              ", "DO                  ", "END DO              ", &
        "DOUBLE PRECISION    ", "REAL*8              ", "INTEGER*4           ", &
        "INTEGER*8           ", "ALLOCATE            ", "DEALLOCATE          ", &
        "ASSOCIATED          ", "NULLIFY             ", "SELECT              ", &
        "CASE                ", "RETURN              ", "STOP                ", &
        "GOTO                ", "CYCLE               ", "EXIT                " ] 
    
    ! --------------------------------------------------------------------------
      ! 3. Hash Table Data Structure (defined within this module, no external dependency)
      ! --------------------------------------------------------------------------
      PUBLIC :: HashTableEntryType, HashTableType
      ! Hash table entry type: Stores key-value pair with linked list for collisions
      TYPE :: HashTableEntryType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: key = ""  ! Key (variable name)
        INTEGER(i4) :: value_index = 0                  ! Value (index in symbol table entries)
        TYPE(HashTableEntryType), POINTER :: next => NULL()  ! Next entry in collision chain
    END TYPE HashTableEntryType
    
    ! Hash table type: Manages hash buckets and collision chains
    TYPE :: HashTableType
        LOGICAL :: initialized = .FALSE.             ! Initialization flag
        INTEGER(i4) :: size = 0                          ! Number of buckets
        INTEGER(i4) :: count = 0                         ! Number of entries
        TYPE(HashTableEntryType), ALLOCATABLE :: buckets(:)  ! Buckets array
    END TYPE HashTableType
    
    ! --------------------------------------------------------------------------
    ! 4. Symbol Table Core Data Types (defined within this module, no external dependency)
    ! --------------------------------------------------------------------------
    PUBLIC :: SymTableEntryType, SymbolTableType
    ! Symbol table entry type: Stores single variable-data ID mapping
    TYPE :: SymTableEntryType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: variable_name = ""  ! Variable name (unique identifier)
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""        ! Associated data ID (points to metadata)
        INTEGER(i4) :: data_type = 0                            ! Data type (IF_DATA_TYPE_*)
        INTEGER(i4) :: storage_type = 0                         ! Storage type (IF_STORAGE_TYPE_*)
        LOGICAL :: is_valid = .FALSE.                      ! Entry validity (logical deletion flag)
        INTEGER(i4) :: next_free = 0                            ! Index of next free entry (for free list)
        ! Usage statistics fields
        INTEGER(i4) :: access_count = 0                         ! Number of times the variable was accessed
        INTEGER(i4) :: update_count = 0                         ! Number of times the variable was updated
        REAL :: last_access_time = 0.0                      ! Last access timestamp (seconds since initialization)
        REAL :: creation_time = 0.0                         ! Creation timestamp (seconds since initialization)
        ! LRU cache fields
        INTEGER(i4) :: prev = 0                                 ! Previous entry in LRU list
        INTEGER(i4) :: next = 0                                 ! Next entry in LRU list
        
        ! Version control fields
        INTEGER(i4) :: current_version = 0                      ! Current version number
        INTEGER(i4) :: version_count = 0                        ! Number of versions stored
        INTEGER(i4) :: version_history(IF_MAX_VERSIONS)            ! Array to store version data IDs
        REAL(wp) :: version_timestamps(IF_MAX_VERSIONS)  ! Timestamps for each version
    END TYPE SymTableEntryType
    
    ! Variable migration data structure: Used for transferring variables between nodes
    TYPE :: VariableMigrationType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: variable_name = ""  ! Variable name
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""        ! Data ID
        INTEGER(i4) :: data_type = 0                            ! Data type
        INTEGER(i4) :: storage_type = 0                         ! Storage type
    END TYPE VariableMigrationType
    
    ! Symbol table type: Manages all entries, maintains capacity and count, uses hash table for fast lookups
    TYPE :: SymbolTableType
        LOGICAL :: initialized = .FALSE.    ! Whether symbol table is initialized
        INTEGER(i4) :: max_entries = 0          ! Max number of supported entries
        INTEGER(i4) :: entry_count = 0          ! Current number of valid entries
        TYPE(SymTableEntryType), ALLOCATABLE :: entries(:)  ! Entry array
        TYPE(HashTableType) :: hash_table   ! Hash table for fast variable name lookups
        INTEGER(i4) :: free_list_head = 0       ! Head of the free entry list
        INTEGER(i4) :: resize_threshold = 0     ! Threshold for table resizing
        REAL :: init_time = 0.0             ! Symbol table initialization time (seconds)
        ! LRU cache fields
        INTEGER(i4) :: lru_head = 0             ! Head of LRU cache list (most recently used)
        INTEGER(i4) :: lru_tail = 0             ! Tail of LRU cache list (least recently used)
        INTEGER(i4) :: lru_max_size = 100       ! Maximum size of LRU cache (default: 100 entries)
    END TYPE SymbolTableType
    
    ! Symbol Table Status Structure - Used for reporting
    TYPE :: SymbolTableStatusType
        LOGICAL :: initialized = .FALSE.
        INTEGER(i4) :: entry_count = 0
        INTEGER(i4) :: max_entries = 0
        INTEGER(i4) :: free_entries = 0
        REAL(wp) :: initialization_time = 0.0
        INTEGER(i4) :: lru_cache_size = 0
        INTEGER(i4) :: lru_max_size = 0
        REAL(wp) :: memory_usage = 0.0  ! Estimated memory usage in KB
    END TYPE SymbolTableStatusType
    
    ! --------------------------------------------------------------------------
    ! --------------------------------------------------------------------------
    ! Module Global Instance (SAVE attribute: Fortran2003 Standard, ensures persistence)
    ! --------------------------------------------------------------------------
    TYPE(SymbolTableType), PRIVATE, SAVE :: global_sym_table

    ! -------------------------------------------------------------------
    ! Public Interface Export (Minimal Exposure Principle: Only export entities needed externally)
    ! --------------------------------------------------------------------------
    PRIVATE  ! Private by default; explicitly export public interfaces
    PUBLIC :: init_sym_table, destroy_sym_table
    PUBLIC :: register_variable, register_variable_batch, register_temp_variable, register_simple_temp_variable
    PUBLIC :: unregister_variable, find_variable, get_variable_data_id
    PUBLIC :: symbol_table_exists, get_variable_count
    
    ! Module Public Migration Interfaces
    PUBLIC :: export_variable_for_migration, import_variable_from_migration, migrate_variable_between_nodes
    ! Module Public Usage Statistics Interfaces
    PUBLIC :: update_variable_access_stats, update_variable_update_stats, get_variable_usage_stats
    
    ! Module Public Persistence Interfaces
    PUBLIC :: save_symbol_table_to_file, load_symbol_table_from_file
    
    ! Module Public LRU Cache Interfaces
    PUBLIC :: update_lru_cache, configure_lru_cache_size
    
    ! Module Public Version Control Interfaces
    PUBLIC :: save_variable_version, rollback_to_version
    
    ! Module Public Version Query Interfaces
    PUBLIC :: get_variable_version_history, get_variable_current_version
    
    ! Module Public Status Report Interfaces
    PUBLIC :: get_symbol_table_status, generate_symbol_table_report

CONTAINS
    ! ==========================================================================
    ! Function: Calculate Hash Value
    ! Function: Generates a hash value for a given key (variable name)
    ! ==========================================================================
    FUNCTION calculate_hash(key, size) RESULT(hash_value)
        CHARACTER(LEN=*), INTENT(IN) :: key
        INTEGER(i4), INTENT(IN) :: size
        INTEGER(i4) :: hash_value
        INTEGER(i4) :: i
        
        hash_value = 0
        
        ! Simple but effective string hashing algorithm
        DO i = 1, LEN_TRIM(key)
            ! Polynomial rolling hash function
            hash_value = MOD(hash_value * 31 + IACHAR(key(i:i)), size)
        END DO
        
        ! Ensure hash_value is positive and within bucket range
        IF (hash_value < 0) THEN
            hash_value = hash_value + size
        END IF
        
        ! Adjust to 1-based indexing for Fortran arrays
        hash_value = hash_value + 1
    END FUNCTION calculate_hash
    
    ! ==========================================================================
    ! Subroutine: Create Hash Table
    ! Function: Allocates and initializes a hash table with specified size
    ! ==========================================================================
    SUBROUTINE hash_table_create(table, size, status)
        TYPE(HashTableType), INTENT(INOUT), TARGET :: table
        INTEGER(i4), INTENT(IN) :: size
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, ierr
        
        CALL init_error_status(status)
        
        ! Validate input parameters
        IF (size <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Hash table size must be positive"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Check if already initialized
        IF (table%initialized) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Hash table already initialized"
            CALL log_info("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Allocate bucket array
        ALLOCATE(table%buckets(size), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0)') "Allocate hash table buckets failed (stat=", ierr
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize all bucket pointers to NULL
        DO i = 1, size
            NULLIFY(table%buckets(i)%next)
            table%buckets(i)%key = ""
            table%buckets(i)%value_index = 0
        END DO
        
        ! Set hash table properties
        table%size = size
        table%count = 0
        table%initialized = .TRUE.
        
        !CALL log_info("SymbolTableManager", "Created hash table with "//TRIM(INT_TO_STR(size))//" buckets")
    END SUBROUTINE hash_table_create
    
    ! ==========================================================================
    ! Subroutine: Destroy Hash Table
    ! Function: Deallocates all memory associated with a hash table
    ! ==========================================================================
    SUBROUTINE hash_table_destroy(table, status)
        TYPE(HashTableType), INTENT(INOUT), TARGET :: table
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, ierr
        TYPE(HashTableEntryType), POINTER :: current, next_entry
        
        CALL init_error_status(status)
        
        ! Check if not initialized
        IF (.NOT. table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Hash table not initialized"
            CALL log_warn("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Deallocate all collision chains
        IF (ALLOCATED(table%buckets)) THEN
            DO i = 1, table%size
                current => table%buckets(i)%next
                ! Traverse and deallocate linked list entries
                DO WHILE (ASSOCIATED(current))
                    next_entry => current%next
                    DEALLOCATE(current)
                    current => next_entry
                END DO
            END DO
            
            ! Deallocate the bucket array itself
            DEALLOCATE(table%buckets, STAT=ierr)
            IF (ierr /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                WRITE(status%message, '(A,I0)') "Deallocate hash table buckets failed (stat=", ierr
                CALL log_error("SymbolTableManager", TRIM(status%message))
            END IF
        END IF
        
        ! Reset hash table properties
        table%initialized = .FALSE.
        table%size = 0
        table%count = 0
        
        !CALL log_info("SymbolTableManager", "Destroyed hash table")
    END SUBROUTINE hash_table_destroy
    
    ! ==========================================================================
    ! Subroutine: Insert into Hash Table
    ! Function: Inserts a key-value pair into the hash table
    ! ==========================================================================
    SUBROUTINE hash_table_insert(table, key, value, status)
        TYPE(HashTableType), INTENT(INOUT), TARGET :: table
        CHARACTER(LEN=*), INTENT(IN) :: key
        INTEGER(i4), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: hash_value, found_index, ierr
        TYPE(HashTableEntryType), POINTER :: current, new_entry
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(status)
        
        ! Check if hash table is initialized
        IF (.NOT. table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Hash table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Check if key already exists
        found_index = hash_table_find(table, key, local_status)
        IF (found_index /= 0) THEN
            status%status_code = IF_STATUS_EXISTS
            WRITE(status%message, '(A,A,A)') "Key '", TRIM(key), "' already exists in hash table"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Calculate hash value
        hash_value = calculate_hash(key, table%size)
        
        ! Create new entry
        ALLOCATE(new_entry, STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0)') "Allocate hash table entry failed (stat=", ierr
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Set new entry values
        new_entry%key = TRIM(key)
        new_entry%value_index = value
        NULLIFY(new_entry%next)
        
        ! Insert at the beginning of the collision chain
        new_entry%next => table%buckets(hash_value)%next
        table%buckets(hash_value)%next => new_entry
        
        ! Update the bucket's key if it's empty (for faster lookups)
        IF (table%buckets(hash_value)%key == "") THEN
            table%buckets(hash_value)%key = TRIM(key)
            table%buckets(hash_value)%value_index = value
        END IF
        
        ! Increment entry count
        table%count = table%count + 1
        
        CALL log_debug("SymbolTableManager", "Inserted into hash table: key='"//TRIM(key)//&
            "', value="//TRIM(INT_TO_STR(value)))
    END SUBROUTINE hash_table_insert
    
    ! ==========================================================================
    ! Subroutine: Delete from Hash Table
    ! Function: Removes a key-value pair from the hash table
    ! ==========================================================================
    SUBROUTINE hash_table_delete(table, key, status)
        TYPE(HashTableType), INTENT(INOUT), TARGET :: table
        CHARACTER(LEN=*), INTENT(IN) :: key
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: hash_value
        TYPE(HashTableEntryType), POINTER :: current, prev
        
        CALL init_error_status(status)
        
        ! Check if hash table is initialized
        IF (.NOT. table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Hash table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Calculate hash value
        hash_value = calculate_hash(key, table%size)
        
        ! Special case: Check if the key is in the bucket itself
        IF (TRIM(table%buckets(hash_value)%key) == TRIM(key)) THEN
            ! If no collision chain, just clear the bucket
            IF (.NOT. ASSOCIATED(table%buckets(hash_value)%next)) THEN
                table%buckets(hash_value)%key = ""
                table%buckets(hash_value)%value_index = 0
            ELSE
                ! Move the next entry up to the bucket
                current => table%buckets(hash_value)%next
                table%buckets(hash_value)%key = TRIM(current%key)
                table%buckets(hash_value)%value_index = current%value_index
                table%buckets(hash_value)%next => current%next
                DEALLOCATE(current)
            END IF
            table%count = table%count - 1
            CALL log_debug("SymbolTableManager", "Deleted from hash table: key='"//TRIM(key)//"'")
            RETURN
        END IF
        
        ! Traverse the collision chain
        prev => table%buckets(hash_value)
        current => table%buckets(hash_value)%next
        
        DO WHILE (ASSOCIATED(current))
            IF (TRIM(current%key) == TRIM(key)) THEN
                ! Found the key, remove it from the chain
                prev%next => current%next
                DEALLOCATE(current)
                table%count = table%count - 1
                CALL log_debug("SymbolTableManager", "Deleted from hash table: key='"//TRIM(key)//"'")
                RETURN
            END IF
            prev => current
            current => current%next
        END DO
        
        ! Key not found
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Key '", TRIM(key), "' not found in hash table"
        CALL log_warn("SymbolTableManager", TRIM(status%message))
    END SUBROUTINE hash_table_delete
    
    ! ==========================================================================
    ! Function: Find in Hash Table
    ! Function: Finds a key in the hash table and returns its associated value
    ! ==========================================================================
    FUNCTION hash_table_find(table, key, status) RESULT(found_index)
        TYPE(HashTableType), INTENT(IN) :: table
        CHARACTER(LEN=*), INTENT(IN) :: key
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: found_index
        INTEGER(i4) :: hash_value
        TYPE(HashTableEntryType), POINTER :: current
        
        CALL init_error_status(status)
        found_index = 0  ! Default: not found
        
        ! Check if hash table is initialized
        IF (.NOT. table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Hash table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Calculate hash value
        hash_value = calculate_hash(key, table%size)
        
        ! Check if the key is in the bucket itself
        IF (TRIM(table%buckets(hash_value)%key) == TRIM(key)) THEN
            found_index = table%buckets(hash_value)%value_index
            RETURN
        END IF
        
        ! Traverse the collision chain
        current => table%buckets(hash_value)%next
        
        DO WHILE (ASSOCIATED(current))
            IF (TRIM(current%key) == TRIM(key)) THEN
                found_index = current%value_index
                RETURN
            END IF
            current => current%next
        END DO
        
        ! Key not found (no error, just return 0)
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Key '", TRIM(key), "' not found in hash table"
    END FUNCTION hash_table_find
    
    ! ==========================================================================
    ! Subroutine: Initialize Symbol Table
    ! Function: Allocate entry array, initialize status, relies on error module to record failures
    ! ==========================================================================
    SUBROUTINE init_sym_table(status, max_entries)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER, INTENT(IN), OPTIONAL :: max_entries  ! Optional: Custom max number of entries
        INTEGER(i4) :: local_max_entries, i, hash_table_size, ierr
        
        CALL init_error_status(status)  ! Call base error module to initialize error status
        
        ! Check if symbol table is already initialized (base error code: IF_STATUS_EXISTS)
        IF (global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Symbol table already initialized"
            CALL log_info("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Handle max entries parameter (use IF_DEFAULT_MAX_ENTRIES by default)
        local_max_entries = IF_DEFAULT_MAX_ENTRIES
        IF (PRESENT(max_entries)) THEN
            IF (max_entries <= 0) THEN
                status%status_code = IF_STATUS_INVALID  ! Base error code: Invalid parameter
                status%message = "Max entries must be positive integer"
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            local_max_entries = max_entries
        END IF
        
        ! Allocate entry array (base error code: IF_STATUS_MEM_ERROR)
        ALLOCATE(global_sym_table%entries(local_max_entries), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0)') "Allocate entries array failed (stat=", ierr
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize hash table with appropriate size (typically 20-30% larger than max entries)
        hash_table_size = INT(local_max_entries * 1.3)
        CALL hash_table_create(global_sym_table%hash_table, hash_table_size, status)
        IF (status%status_code /= IF_STATUS_SUCCESS) THEN
            ! Clean up already allocated resources
            IF (ALLOCATED(global_sym_table%entries)) THEN
                DEALLOCATE(global_sym_table%entries)
            END IF
            status%status_code = IF_STATUS_INIT_ERROR
            status%message = "Failed to initialize hash table: "//TRIM(status%message)
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Build free entry list (for efficient reuse of deleted entries)
        global_sym_table%free_list_head = 1
        DO i = 1, local_max_entries - 1
            global_sym_table%entries(i)%next_free = i + 1
        END DO
        global_sym_table%entries(local_max_entries)%next_free = 0  ! End of list
        
        ! Set resize threshold (80% of max entries)
        global_sym_table%resize_threshold = INT(local_max_entries * 0.8)
        
        ! Initialize core symbol table status
        global_sym_table%max_entries = local_max_entries
        global_sym_table%entry_count = 0
        global_sym_table%initialized = .TRUE.
        
        ! Set initialization time (using placeholder for actual time function)
        ! In a real implementation, use CALL CPU_TIME(global_sym_table%init_time)
        global_sym_table%init_time = 0.0
        
        ! Log successful initialization
        !CALL log_info("SymbolTableManager", "Initialized symbol table with hash indexing (max entries="//&
        !      TRIM(INT_TO_STR(local_max_entries))//", hash size="//TRIM(INT_TO_STR(hash_table_size))//")")
    END SUBROUTINE init_sym_table

    ! ==========================================================================
    ! Subroutine: Destroy Symbol Table
    ! Function: Deallocate entry array, reset status, relies on error module to record failures
    ! ==========================================================================
    SUBROUTINE destroy_sym_table(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(ErrorStatusType) :: local_status  ! For nested function calls
        INTEGER(i4) :: ierr
        
        CALL init_error_status(status)
        
        ! Check if symbol table is uninitialized (module-specific error code: IF_STATUS_TABLE_NOT_INIT)
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_warn("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Destroy hash table (base error code: IF_STATUS_MEM_ERROR)
        CALL hash_table_destroy(global_sym_table%hash_table, local_status)
        IF (local_status%status_code /= IF_STATUS_SUCCESS) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to destroy hash table: "//TRIM(local_status%message)
            CALL log_error("SymbolTableManager", TRIM(status%message))
            ! Continue execution to clean up other resources
        END IF
        
        ! Deallocate entry array (base error code: IF_STATUS_MEM_ERROR)
        IF (ALLOCATED(global_sym_table%entries)) THEN
            DEALLOCATE(global_sym_table%entries, STAT=ierr)
            IF (ierr /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                WRITE(status%message, '(A,I0)') "Deallocate entries array failed (stat=", ierr
                CALL log_error("SymbolTableManager", TRIM(status%message))
            END IF
        END IF
        
        ! Reset symbol table status
        global_sym_table%initialized = .FALSE.
        global_sym_table%max_entries = 0
        global_sym_table%entry_count = 0
        global_sym_table%free_list_head = 0
        global_sym_table%resize_threshold = 0
        
        !CALL log_info("SymbolTableManager", "Destroyed symbol table with hash indexing")
    END SUBROUTINE destroy_sym_table

    ! ==========================================================================
    ! Subroutine: Register Single Variable
    ! Function: Validate variable validity, add new mapping entry, relies on error module for failures
    ! ==========================================================================
    SUBROUTINE register_variable(variable_name, data_id, data_type, storage_type, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name  ! Variable name to register
        CHARACTER(LEN=*), INTENT(IN) :: data_id        ! Associated data ID
        INTEGER(i4), INTENT(IN) :: data_type              ! Data type (IF_DATA_TYPE_*)
        INTEGER(i4), INTENT(IN) :: storage_type           ! Storage type (IF_STORAGE_TYPE_*)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        LOGICAL :: valid_name, valid_type
        INTEGER(i4) :: free_idx
        
        CALL init_error_status(status)
        
        ! Pre-check 1: Symbol table initialization status (specific error code: IF_STATUS_TABLE_NOT_INIT)
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Pre-check 2: Variable name validity (specific error code: IF_STATUS_VAR_NAME_INVALID)
        valid_name = is_valid_var_name(variable_name, status)
        IF (.NOT. valid_name) THEN
            status%status_code = IF_STATUS_VAR_NAME_INVALID
            CALL log_error("SymbolTableManager", "Variable registration failed: "//TRIM(status%message))
            RETURN
        END IF
        
        ! Pre-check 3: Data ID not empty (specific error code: IF_STATUS_DATA_ID_EMPTY)
        IF (LEN_TRIM(data_id) == 0) THEN
            status%status_code = IF_STATUS_DATA_ID_EMPTY
            status%message = "Data ID cannot be empty" 
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Pre-check 4: Data type matches storage type (specific error code: IF_STATUS_TYPE_MISMATCH)
        valid_type = is_valid_type_match(data_type, storage_type, status)
        IF (.NOT. valid_type) THEN
            status%status_code = IF_STATUS_TYPE_MISMATCH
            CALL log_error("SymbolTableManager", "Variable registration failed: "//TRIM(status%message))  
            RETURN
        END IF
        
        ! Pre-check 5: Variable name already registered (base error code: IF_STATUS_EXISTS)
        ! Using hash table for O(1) lookup
        free_idx = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), status)
        IF (free_idx /= 0) THEN
            status%status_code = IF_STATUS_EXISTS
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(variable_name), "' already exists"
            CALL log_info("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Pre-check 6: Symbol table full (specific error code: IF_STATUS_TABLE_FULL)
        free_idx = find_free_entry(status)
        IF (free_idx == 0) THEN
            status%status_code = IF_STATUS_TABLE_FULL
            WRITE(status%message, '(A,I0,A,I0)') "Symbol table full (max ", global_sym_table%max_entries, &
				", current ", global_sym_table%entry_count, ")"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Execute registration: Populate entry information
        global_sym_table%entries(free_idx)%variable_name = TRIM(variable_name)
        global_sym_table%entries(free_idx)%data_id = TRIM(data_id)
        global_sym_table%entries(free_idx)%data_type = data_type
        global_sym_table%entries(free_idx)%storage_type = storage_type
        global_sym_table%entries(free_idx)%is_valid = .TRUE.
        global_sym_table%entry_count = global_sym_table%entry_count + 1
        
        ! Insert into hash table for future lookups
        CALL hash_table_insert(global_sym_table%hash_table, TRIM(variable_name), free_idx, status)
        IF (status%status_code /= IF_STATUS_SUCCESS) THEN
            ! Clean up partial registration
            global_sym_table%entries(free_idx)%is_valid = .FALSE.
            ! Return index to free list
            global_sym_table%entries(free_idx)%next_free = global_sym_table%free_list_head
            global_sym_table%free_list_head = free_idx
            global_sym_table%entry_count = global_sym_table%entry_count - 1
            
            status%status_code = IF_STATUS_REGISTER_ERROR
            status%message = "Failed to register variable in hash table: "//TRIM(status%message)
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Check resize threshold (for future implementation)
        IF (global_sym_table%entry_count >= global_sym_table%resize_threshold) THEN
            CALL log_warn("SymbolTableManager", "Symbol table approaching capacity ("//& 
                 TRIM(INT_TO_STR(global_sym_table%entry_count))//"/"//& 
                 TRIM(INT_TO_STR(global_sym_table%max_entries))//")")
        END IF
        
        ! Log successful registration
        !CALL log_info("SymbolTableManager", "Registered variable: '"//TRIM(variable_name)//&
        !    "' -> data_id='"//TRIM(data_id)//"'")
    END SUBROUTINE register_variable

    ! ==========================================================================
    ! Subroutine: Batch Register Variables
    ! Function: Adapt to batch mapping of array variables, reduce loop call overhead
    ! ==========================================================================
    SUBROUTINE register_variable_batch(var_names, data_ids, data_types, storage_types, count, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_names(:), data_ids(:)  ! Variable name array, data ID array
        INTEGER(i4), INTENT(IN) :: data_types(:), storage_types(:)     ! Data type array, storage type array
        INTEGER(i4), INTENT(IN) :: count                             ! Number of variables to batch register
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        LOGICAL :: valid_name
        
        CALL init_error_status(status)
        
        ! Pre-check 1: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Pre-check 2: Input array size consistency
        IF (SIZE(var_names) < count .OR. SIZE(data_ids) < count .OR. &
            SIZE(data_types) < count .OR. SIZE(storage_types) < count) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Input array size does not match variable count"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Pre-check 3: Symbol table remaining capacity
        IF (global_sym_table%entry_count + count > global_sym_table%max_entries) THEN
            status%status_code = IF_STATUS_TABLE_FULL
            WRITE(status%message, '(A,I0,A,I0)') "Insufficient space (need ", count, &
				", free ", global_sym_table%max_entries - global_sym_table%entry_count, ")"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Batch registration: Loop to call single registration logic to avoid code redundancy
        DO i = 1, count
            ! Validate current variable name
            valid_name = is_valid_var_name(TRIM(var_names(i)), status)
            IF (.NOT. valid_name) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                WRITE(status%message, '(A,I0,A,A)') "Batch failed at index ", i, ": "//TRIM(status%message)
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            
            ! Check if current variable is already registered
            IF (symbol_table_exists(TRIM(var_names(i)), status)) THEN
                status%status_code = IF_STATUS_EXISTS
                WRITE(status%message, '(A,I0,A,A,A)') "Batch failed at index ", i, ": Variable '", TRIM(var_names(i)), "' exists"
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            
            ! Register single variable
            CALL register_variable( &
                variable_name = TRIM(var_names(i)), &
                data_id = TRIM(data_ids(i)), &
                data_type = data_types(i), &
                storage_type = storage_types(i), &
                status = status &
            )
            IF (status%status_code /= IF_STATUS_OK) THEN
                WRITE(status%message, '(A,I0,A,A)') "Batch failed at index ", i, ": "//TRIM(status%message)
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
        END DO
        
        !CALL log_info("SymbolTableManager", "Batch registered "//TRIM(INT_TO_STR(count))//" variables")
    END SUBROUTINE register_variable_batch

    ! ==========================================================================
    ! Subroutine: Unregister Variable (Logical Deletion)
    ! Function: Mark entry as invalid, no memory deallocation to avoid fragmentation
    ! ==========================================================================
    SUBROUTINE unregister_variable(variable_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: entry_index
        
        CALL init_error_status(status)

        ! Skip unregister for internal cache variables ("__cache_" prefix)
        IF (LEN_TRIM(variable_name) >= 8) THEN
            IF (variable_name(1:8) == "__cache_") THEN
                status%status_code = IF_STATUS_OK
                status%message = "Internal cache variable ignored in unregister"
                RETURN
            END IF
        END IF

        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Find variable using hash table (O(1) operation)
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), status)
        IF (entry_index == 0) THEN
            ! Variable not found (base error code: IF_STATUS_NOT_FOUND)
            status%status_code = IF_STATUS_NOT_FOUND
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(variable_name), "' not found"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Verify entry is valid (sanity check)
        IF (.NOT. global_sym_table%entries(entry_index)%is_valid) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Internal error: Hash table references invalid entry"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Delete from hash table
        CALL hash_table_delete(global_sym_table%hash_table, TRIM(variable_name), status)
        IF (status%status_code /= IF_STATUS_SUCCESS) THEN
            status%status_code = IF_STATUS_UNREGISTER_ERROR
            status%message = "Failed to remove variable from hash table: "//TRIM(status%message)
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Mark entry as invalid and reset fields
        global_sym_table%entries(entry_index)%is_valid = .FALSE.
        global_sym_table%entries(entry_index)%variable_name = ""
        global_sym_table%entries(entry_index)%data_id = ""
        global_sym_table%entry_count = global_sym_table%entry_count - 1
        
        ! Return entry to free list for reuse (O(1) operation)
        global_sym_table%entries(entry_index)%next_free = global_sym_table%free_list_head
        global_sym_table%free_list_head = entry_index
        
        !CALL log_info("SymbolTableManager", "Unregistered variable: '"//TRIM(variable_name)//"'")
    END SUBROUTINE unregister_variable

    ! ==========================================================================
    ! Subroutine: Register Temporary Variable
    ! Function: Register temporary variables used in sharding/merging operations
    ! ==========================================================================
    SUBROUTINE register_temp_variable(temp_var_name, data_type, storage_type, status)
        CHARACTER(LEN=*), INTENT(IN) :: temp_var_name  ! Temporary variable name
        INTEGER(i4), INTENT(IN) :: data_type              ! Data type (IF_DATA_TYPE_*)
        INTEGER(i4), INTENT(IN) :: storage_type           ! Storage type (IF_STORAGE_TYPE_*)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: temp_data_id
        LOGICAL :: exists
        TYPE(ErrorStatusType) :: temp_status
        INTEGER(i4) :: i
        CHARACTER(LEN=20) :: timestamp_str
        CHARACTER(LEN=10) :: random_str
        INTEGER(i4) :: time_values(8)
        REAL :: rand_val
        INTEGER(i4) :: rand_int
        
        CALL init_error_status(status)
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Check if variable already exists
        exists = symbol_table_exists(temp_var_name, temp_status)
        IF (exists) THEN
            ! Variable already registered, return success
            status%status_code = IF_STATUS_OK
            CALL log_debug("SymbolTableManager", "Temporary variable already registered: '"//TRIM(temp_var_name)//"'")
            RETURN
        END IF
        
        ! Generate a temporary data ID
        CALL DATE_AND_TIME(VALUES=time_values)
        WRITE(timestamp_str, '(I4,2I2.2,2I2.2,3I2.2)') &
            time_values(1), time_values(2), time_values(3), &  ! Year, Month, Day
            time_values(5), time_values(6), time_values(7), &  ! Hour, Minute, Second
            time_values(8)/10  ! Milliseconds (truncated)
            
        ! Generate a random component
        CALL RANDOM_SEED()
        CALL RANDOM_NUMBER(rand_val)
        rand_int = INT(rand_val * 10000)
        WRITE(random_str, '(I10.10)') rand_int
        
        ! Construct the temporary data ID
        WRITE(temp_data_id, '("TEMP_",A,"_",A)') TRIM(temp_var_name), TRIM(timestamp_str)
        
        ! Register the temporary variable
        CALL register_variable(temp_var_name, temp_data_id, data_type, storage_type, status)
        IF (status%status_code == IF_STATUS_OK) THEN
    !        CALL log_info("SymbolTableManager", "Registered temporary variable: '"//&
				!TRIM(temp_var_name)//"' -> data_id='"//TRIM(temp_data_id)//"'")
        ELSE
            CALL log_warn("SymbolTableManager", "Failed to register temporary variable: '"//&
				TRIM(temp_var_name)//"': "//TRIM(status%message))
            ! Reset status to OK if registration fails but we can proceed
            ! This allows operations to continue even if temporary variable registration fails
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE register_temp_variable

    ! ==========================================================================    
    ! Subroutine: Find Variable (Return Full Mapping Information)
    ! ==========================================================================
    SUBROUTINE find_variable(variable_name, data_id, data_type, storage_type, status, log_error_flag)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        CHARACTER(LEN=*), INTENT(OUT) :: data_id
        INTEGER(i4), INTENT(OUT) :: data_type, storage_type
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        LOGICAL, OPTIONAL, INTENT(IN) :: log_error_flag
        INTEGER(i4) :: entry_index
        LOGICAL :: do_log_error
        
        CALL init_error_status(status)
        data_id = ""
        data_type = 0
        storage_type = 0
        
        ! Set default behavior: log error if variable not found
        do_log_error = .TRUE.
        IF (PRESENT(log_error_flag)) THEN
            do_log_error = log_error_flag
        END IF
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Find variable using hash table (O(1) operation)
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), status)
        IF (entry_index /= 0) THEN
            ! Verify entry is valid (sanity check)
            IF (.NOT. global_sym_table%entries(entry_index)%is_valid) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Internal error: Hash table references invalid entry"
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            
            ! Return variable information
            data_id = TRIM(global_sym_table%entries(entry_index)%data_id)
            data_type = global_sym_table%entries(entry_index)%data_type
            storage_type = global_sym_table%entries(entry_index)%storage_type
            status%status_code = IF_STATUS_OK
            CALL log_debug("SymbolTableManager", "Found variable '"//TRIM(variable_name)//& 
                "': data_id='"//TRIM(data_id)//", type="//TRIM(INT_TO_STR(data_type)))
            RETURN
        END IF
        
        ! Variable not found
        status%status_code = IF_STATUS_NOT_FOUND
        WRITE(status%message, '(A,A,A)') "Variable '", TRIM(variable_name), "' not found" 
        ! Only log informational message if requested
        IF (do_log_error) THEN
            !CALL log_info("SymbolTableManager", TRIM(status%message))
        END IF
    END SUBROUTINE find_variable

    ! ==========================================================================
    ! Subroutine: Simplified Interface (Return Only Data ID)
    ! ==========================================================================
    SUBROUTINE get_variable_data_id(variable_name, data_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        CHARACTER(LEN=*), INTENT(OUT) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: dummy_data_type, dummy_storage_type  ! Temporary variables, not output
        
        CALL init_error_status(status)
        data_id = ""
        
        ! Reuse find_variable logic to avoid code redundancy
        CALL find_variable(variable_name, data_id, dummy_data_type, dummy_storage_type, status, log_error_flag=.FALSE.)

        ! If variable is not found, this is not treated as a hard error here.
        ! Callers (such as StructFileManager cache preload) may legitimately probe
        ! for optional variables and fall back to internal IDs.
        IF (status%status_code == IF_STATUS_NOT_FOUND) THEN
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(variable_name), "' not found"
            !CALL log_info("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF

        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Validate data ID validity
        IF (LEN_TRIM(data_id) == 0) THEN
            status%status_code = IF_STATUS_DATA_ID_EMPTY
            WRITE(status%message, '(A,A,A)') "Invalid data ID for variable '", TRIM(variable_name), "'"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        CALL log_debug("SymbolTableManager", "Got data ID for '"//TRIM(variable_name)//"': "//TRIM(data_id))
    END SUBROUTINE get_variable_data_id

    ! ==========================================================================
    ! Function: Check Variable Existence (Existence Judgment)
    ! ==========================================================================
    LOGICAL FUNCTION symbol_table_exists(variable_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: dummy_data_id
        INTEGER(i4) :: dummy_data_type, dummy_storage_type
        
        CALL init_error_status(status)
        symbol_table_exists = .FALSE.
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Call find_variable to check existence, but don't log error if not found
        CALL find_variable(variable_name, dummy_data_id, dummy_data_type, dummy_storage_type, status, .FALSE.)
        IF (status%status_code == IF_STATUS_OK .AND. LEN_TRIM(dummy_data_id) > 0) THEN
            symbol_table_exists = .TRUE.
        END IF
        
        ! Existence check does not return error; reset status to OK
        status%status_code = IF_STATUS_OK
        status%message = ""
    END FUNCTION symbol_table_exists

    ! ==========================================================================
    ! Subroutine: Get Total Count of Registered Variables
    ! ==========================================================================
    SUBROUTINE get_variable_count(count, status)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        count = 0
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        count = global_sym_table%entry_count
        status%status_code = IF_STATUS_OK
        CALL log_debug("SymbolTableManager", "Current variable count: "//TRIM(INT_TO_STR(count)))
    END SUBROUTINE get_variable_count

    ! ==========================================================================
    ! Utility Function: Variable Name Validity Check (Character Rules + Keyword Conflict)
    ! ==========================================================================
    LOGICAL FUNCTION is_valid_var_name(variable_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, name_len
        CHARACTER :: first_char
        
        CALL init_error_status(status)
        is_valid_var_name = .FALSE.
        name_len = LEN_TRIM(variable_name)
        
        ! Check 1: Variable name not empty
        IF (name_len == 0) THEN
            status%message = "Variable name cannot be empty"
            RETURN
        END IF
        
        ! Check 2: Variable name length within limit
        IF (name_len > IF_MAX_VAR_NAME_LEN) THEN
            WRITE(status%message, '(A,I0,A,I0)') "Variable name too long (max ", IF_MAX_VAR_NAME_LEN, ", got ", name_len
            RETURN
        END IF
        
        ! Check 3: First character is letter or underscore
        first_char = variable_name(1:1)
        IF (.NOT. ( (first_char >= 'A' .AND. first_char <= 'Z') .OR. &
                   (first_char >= 'a' .AND. first_char <= 'z') .OR. &
                   first_char == '_' )) THEN
            WRITE(status%message, '(A,A,A)') "Variable name '", TRIM(variable_name), "' must start with letter or underscore"
            RETURN
        END IF
        
        ! Check 4: Subsequent characters are letter/digit/underscore
        DO i = 2, name_len
            IF (.NOT. ( (variable_name(i:i) >= 'A' .AND. variable_name(i:i) <= 'Z') .OR. &
                       (variable_name(i:i) >= 'a' .AND. variable_name(i:i) <= 'z') .OR. &
                       (variable_name(i:i) >= '0' .AND. variable_name(i:i) <= '9') .OR. &
                       variable_name(i:i) == '_' )) THEN
                WRITE(status%message, '(A,A,A,A,A)') "Variable name '", TRIM(variable_name), &
                    "' contains invalid character: '", variable_name(i:i), "'"
                RETURN
            END IF
        END DO
        
        ! Check 5: No conflict with Fortran keywords (case-insensitive)
        DO i = 1, IF_KEYWORD_COUNT
            IF (TRIM(ADJUSTL(LOWERCASE(variable_name))) == TRIM(LOWERCASE(FORTRAN_KEYWORDS(i)))) THEN
                WRITE(status%message, '(A,A,A,A,A)') "Variable name '", TRIM(variable_name), &
                    "' conflicts with Fortran keyword: '", TRIM(FORTRAN_KEYWORDS(i)), "'"
                RETURN
            END IF
        END DO
        
        ! All checks passed
        is_valid_var_name = .TRUE.
    END FUNCTION is_valid_var_name

    ! ==========================================================================
    ! Utility Function: Data Type and Storage Type Match Check
    ! ==========================================================================
    LOGICAL FUNCTION is_valid_type_match(data_type, storage_type, status)
        INTEGER(i4), INTENT(IN) :: data_type, storage_type
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        is_valid_type_match = .FALSE.
        
        ! Check 1: Valid storage type (only structured/unstructured supported)
        IF (storage_type /= IF_STORAGE_TYPE_STRUCTURED .AND. storage_type /= IF_STORAGE_TYPE_UNSTRUCTURED) THEN
            status%message = "Storage type must be 1(structured) or 2(unstructured)"
            RETURN
        END IF
        
        ! Check 2: Data type matches storage type
        SELECT CASE (storage_type)
            CASE (IF_STORAGE_TYPE_STRUCTURED)
                ! Structured storage supports: Integer/Double/Character/Struct/Class
                IF (.NOT. (data_type == IF_DATA_TYPE_INT .OR. data_type == IF_DATA_TYPE_DP .OR. &
                          data_type == IF_DATA_TYPE_CHAR .OR. data_type == IF_DATA_TYPE_STRUCT .OR. &
                          data_type == IF_DATA_TYPE_CLASS)) THEN
                    status%message = "Data type not supported for structured storage"
                    RETURN
                END IF
            CASE (IF_STORAGE_TYPE_UNSTRUCTURED)
                ! Unstructured storage supports: Hash/Linked List/Adjacency List/Skip List/Graph/Queue
                IF (.NOT. (data_type == IF_DATA_TYPE_HASH .OR. data_type == IF_DATA_TYPE_LINKED_LIST .OR. &
                          data_type == IF_DATA_TYPE_ADJACENCY .OR. data_type == IF_DATA_TYPE_SKIP_LIST .OR. &
                          data_type == IF_DATA_TYPE_GRAPH .OR. data_type == IF_DATA_TYPE_QUEUE)) THEN
                    status%message = "Data type not supported for unstructured storage"
                    RETURN
                END IF
        END SELECT
        
        ! Match check passed
        is_valid_type_match = .TRUE.
    END FUNCTION is_valid_type_match

    ! ==========================================================================
    ! Utility Function: Find Free Entry Index (Reuse invalid entries first to avoid fragmentation)
    ! ==========================================================================
    INTEGER FUNCTION find_free_entry(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: free_index
        
        CALL init_error_status(status)
        find_free_entry = 0
        
        ! Check if free list is empty (O(1) operation)
        IF (global_sym_table%free_list_head == 0) THEN
            ! No free entry (return 0; external logic judges as full)
            status%status_code = IF_STATUS_TABLE_FULL
            RETURN
        END IF
        
        ! Get index from free list head
        free_index = global_sym_table%free_list_head
        
        ! Update free list head to next free entry
        global_sym_table%free_list_head = global_sym_table%entries(free_index)%next_free
        
        ! Initialize the entry's next_free pointer to 0
        global_sym_table%entries(free_index)%next_free = 0
        
        find_free_entry = free_index
    END FUNCTION find_free_entry

    ! ==========================================================================    
    ! Utility Function: String to Lowercase (For keyword conflict check, case-insensitive)
    ! ==========================================================================
    FUNCTION LOWERCASE(str) RESULT(lower_str)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=LEN(str)) :: lower_str
        INTEGER(i4) :: i, char_code
        
        DO i = 1, LEN(str)
            char_code = ICHAR(str(i:i))
            ! ASCII: Uppercase A-Z (65-90) to lowercase (+32)
            IF (char_code >= ICHAR('A') .AND. char_code <= ICHAR('Z')) THEN
                lower_str(i:i) = ACHAR(char_code + 32)
            ELSE
                lower_str(i:i) = str(i:i)
            END IF
        END DO
    END FUNCTION LOWERCASE

    ! ==========================================================================
    ! Utility Function: Integer to String (Fortran2003 Compatible, No External Dependency)
    ! ==========================================================================
    FUNCTION INT_TO_STR(i) RESULT(str)
        INTEGER(i4), INTENT(IN) :: i
        CHARACTER(LEN=20) :: str  ! Sufficient length for 64-bit integer
        
        WRITE(str, '(I0)') i  ! I0: Auto-adapt to integer width, no extra spaces
        str = TRIM(ADJUSTL(str))  ! Remove leading spaces, trim trailing spaces
    END FUNCTION INT_TO_STR

    ! ==========================================================================
    ! Subroutine: Register Simple Temporary Variable
    ! Function: Register a temporary variable with auto-generated data ID (simplified version)
    ! ==========================================================================
    SUBROUTINE register_simple_temp_variable(variable_name, status)
            CHARACTER(LEN=*), INTENT(IN) :: variable_name  ! Temporary variable name
            TYPE(ErrorStatusType), INTENT(OUT) :: status
            CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: temp_data_id
            INTEGER(i4) :: temp_count
            LOGICAL :: valid_name
            INTEGER(i4) :: free_idx
            
            CALL init_error_status(status)
            
            ! Pre-check 1: Symbol table initialization status
            IF (.NOT. global_sym_table%initialized) THEN
                status%status_code = IF_STATUS_TABLE_NOT_INIT
                status%message = "Symbol table not initialized"
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            
            ! Pre-check 2: Variable name validity
            valid_name = is_valid_var_name(variable_name, status)
            IF (.NOT. valid_name) THEN
                status%status_code = IF_STATUS_VAR_NAME_INVALID
                CALL log_error("SymbolTableManager", "Temporary variable registration failed: "//TRIM(status%message))
                RETURN
            END IF
            
            ! Pre-check 3: Symbol table full
            free_idx = find_free_entry(status)
            IF (free_idx == 0) THEN
                status%status_code = IF_STATUS_TABLE_FULL
                status%message = "Symbol table full"
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            
            ! Generate temporary data ID
            temp_count = global_sym_table%entry_count + 1
            WRITE(temp_data_id, '("temp_", I0)') temp_count
            
        ! Execute registration
        global_sym_table%entries(free_idx)%variable_name = TRIM(variable_name)
        global_sym_table%entries(free_idx)%data_id = TRIM(temp_data_id)
        ! Use IF_DATA_TYPE_INT as default for temporary variables (most commonly supported)
        global_sym_table%entries(free_idx)%data_type = IF_DATA_TYPE_INT
        global_sym_table%entries(free_idx)%storage_type = IF_STORAGE_TYPE_STRUCTURED
        global_sym_table%entries(free_idx)%is_valid = .TRUE.
            global_sym_table%entry_count = global_sym_table%entry_count + 1
            
            !CALL log_info("SymbolTableManager", "Registered temporary variable: '"//TRIM(variable_name)//&
            !    "' -> data_id='"//TRIM(temp_data_id)//"'")
        END SUBROUTINE register_simple_temp_variable

    !-----------------------------------------------------------------------
    ! Variable Migration Functions
    !-----------------------------------------------------------------------
    ! Export a variable's information for migration
    FUNCTION export_variable_for_migration(variable_name, migration_data, status) RESULT(success)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        TYPE(VariableMigrationType), INTENT(OUT) :: migration_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        LOGICAL :: success
        INTEGER(i4) :: entry_index
        
        CALL init_error_status(status)
        success = .FALSE.
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Find the variable using hash table
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), status)
        IF (entry_index /= 0) THEN
            ! Verify entry is valid
            IF (.NOT. global_sym_table%entries(entry_index)%is_valid) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Internal error: Hash table references invalid entry"
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            
            ! Export the variable data
            migration_data%variable_name = TRIM(global_sym_table%entries(entry_index)%variable_name)
            migration_data%data_id = TRIM(global_sym_table%entries(entry_index)%data_id)
            migration_data%data_type = global_sym_table%entries(entry_index)%data_type
            migration_data%storage_type = global_sym_table%entries(entry_index)%storage_type
            
            success = .TRUE.
            status%status_code = IF_STATUS_OK
            !CALL log_info("SymbolTableManager", "Exported variable '"//TRIM(variable_name)//"' for migration")
        ELSE
            ! Variable not found
            status%status_code = IF_STATUS_NOT_FOUND
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(variable_name), "' not found for export"
            CALL log_error("SymbolTableManager", TRIM(status%message))
        END IF
    END FUNCTION export_variable_for_migration
    
    ! Import a variable from migration data
    FUNCTION import_variable_from_migration(migration_data, status) RESULT(success)
        TYPE(VariableMigrationType), INTENT(IN) :: migration_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        LOGICAL :: success
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: var_name
        INTEGER(i4) :: entry_index
        
        CALL init_error_status(status)
        success = .FALSE.
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Check if variable already exists
        var_name = TRIM(migration_data%variable_name)
        IF (symbol_table_exists(var_name, status)) THEN
            ! Variable exists - update it
            entry_index = hash_table_find(global_sym_table%hash_table, var_name, status)
            IF (entry_index /= 0) THEN
                ! Update existing entry
                global_sym_table%entries(entry_index)%data_id = TRIM(migration_data%data_id)
                global_sym_table%entries(entry_index)%data_type = migration_data%data_type
                global_sym_table%entries(entry_index)%storage_type = migration_data%storage_type
                
                success = .TRUE.
                status%status_code = IF_STATUS_OK
                !CALL log_info("SymbolTableManager", "Updated existing variable '"//TRIM(var_name)//"' during import")
            END IF
        ELSE
            ! Register new variable
            CALL register_variable(var_name, TRIM(migration_data%data_id), migration_data%data_type, &
                migration_data%storage_type, status)
            
            IF (status%status_code == IF_STATUS_OK) THEN
                success = .TRUE.
                !CALL log_info("SymbolTableManager", "Imported new variable '"//TRIM(var_name)//"' from migration data")
            ELSE
                CALL log_error("SymbolTableManager", "Failed to register variable during import: "//TRIM(status%message))
            END IF
        END IF
    END FUNCTION import_variable_from_migration
    
    ! Migrate a variable between nodes (high-level interface)
    SUBROUTINE migrate_variable_between_nodes(variable_name, source_node_id, target_node_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        CHARACTER(LEN=*), INTENT(IN) :: source_node_id
        CHARACTER(LEN=*), INTENT(IN) :: target_node_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(VariableMigrationType) :: migration_data
        LOGICAL :: success
        
        CALL init_error_status(status)
        
        !CALL log_info("SymbolTableManager", "Starting migration of variable '"//TRIM(variable_name)//"' from node '"//&
        !    TRIM(source_node_id)//"' to node '"//TRIM(target_node_id)//"'")
        
        ! Step 1: Check if we are the source node
        ! In a real distributed implementation, this would involve remote procedure calls
        ! Here we simulate the source side operation
        IF (TRIM(source_node_id) == "LOCAL") THEN
            ! Export variable from local symbol table
            success = export_variable_for_migration(variable_name, migration_data, status)
            IF (.NOT. success) THEN
                CALL log_error("SymbolTableManager", "Failed to export variable for migration: "//TRIM(status%message))
                RETURN
            END IF
            
            ! In a real implementation, send migration_data to target node
            !CALL log_info("SymbolTableManager", "Variable data prepared for migration to target node")
            
            ! If we are also the target node (local migration), import immediately
            IF (TRIM(target_node_id) == "LOCAL") THEN
                success = import_variable_from_migration(migration_data, status)
                IF (.NOT. success) THEN
                    CALL log_error("SymbolTableManager", "Failed to import variable during local migration: "//TRIM(status%message))
                    RETURN
                END IF
            END IF
            
        ELSE
            ! In a real implementation, this would receive data from the source node
            ! For simulation purposes, we'll mark this as not implemented
            status%status_code = IF_STATUS_NOT_IMPLEMENTED
            status%message = "Remote node migration simulation not fully implemented"
            CALL log_warn("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        status%status_code = IF_STATUS_OK
        !CALL log_info("SymbolTableManager", "Migration initiated for variable '"//TRIM(variable_name)//"'")
        
        ! Note: In a production distributed system, this would require:
        ! 1. Network communication layer
        ! 2. Authentication between nodes
        ! 3. Transaction-like behavior for consistency
        ! 4. Retry mechanisms for reliability
    END SUBROUTINE migrate_variable_between_nodes
    
    !-----------------------------------------------------------------------
    ! Usage Statistics Functions
    !-----------------------------------------------------------------------
    ! Helper function to get current time relative to symbol table initialization
    FUNCTION get_relative_time() RESULT(rel_time)
        REAL :: rel_time
        REAL :: current_time
        
        ! In a real implementation, use a system clock function
        ! Here we simulate with a simple increment for demonstration
        ! In Fortran, you would use: CALL CPU_TIME(current_time) or DATE_AND_TIME()
        current_time = 0.0  ! Placeholder for actual time function
        
        IF (global_sym_table%initialized) THEN
            rel_time = current_time - global_sym_table%init_time
        ELSE
            rel_time = 0.0
        END IF
    END FUNCTION get_relative_time
    
    ! Update variable access statistics
    SUBROUTINE update_variable_access_stats(variable_name)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        INTEGER(i4) :: entry_index
        TYPE(ErrorStatusType) :: dummy_status
        
        ! Skip if table not initialized
        IF (.NOT. global_sym_table%initialized) RETURN
        
        ! Find the variable using hash table
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), dummy_status)
        IF (entry_index /= 0) THEN
            ! Update access statistics
            global_sym_table%entries(entry_index)%access_count = global_sym_table%entries(entry_index)%access_count + 1
            global_sym_table%entries(entry_index)%last_access_time = get_relative_time()
        END IF
    END SUBROUTINE update_variable_access_stats
    
    ! Update variable update statistics
    SUBROUTINE update_variable_update_stats(variable_name)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        INTEGER(i4) :: entry_index
        TYPE(ErrorStatusType) :: dummy_status
        
        ! Skip if table not initialized
        IF (.NOT. global_sym_table%initialized) RETURN
        
        ! Find the variable using hash table
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), dummy_status)
        IF (entry_index /= 0) THEN
            ! Update update statistics
            global_sym_table%entries(entry_index)%update_count = global_sym_table%entries(entry_index)%update_count + 1
            global_sym_table%entries(entry_index)%last_access_time = get_relative_time()
        END IF
    END SUBROUTINE update_variable_update_stats
    
    ! Get variable usage statistics
    SUBROUTINE get_variable_usage_stats(variable_name, access_count, update_count, &
                                       last_access_time, creation_time, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        INTEGER(i4), INTENT(OUT) :: access_count, update_count
        REAL, INTENT(OUT) :: last_access_time, creation_time
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: entry_index
        
        CALL init_error_status(status)
        access_count = 0
        update_count = 0
        last_access_time = 0.0
        creation_time = 0.0
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Find the variable using hash table
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), status)
        IF (entry_index /= 0) THEN
            ! Return usage statistics
            access_count = global_sym_table%entries(entry_index)%access_count
            update_count = global_sym_table%entries(entry_index)%update_count
            last_access_time = global_sym_table%entries(entry_index)%last_access_time
            creation_time = global_sym_table%entries(entry_index)%creation_time
            status%status_code = IF_STATUS_OK
        ELSE
            ! Variable not found
            status%status_code = IF_STATUS_NOT_FOUND
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(variable_name), "' not found for statistics retrieval"
            CALL log_error("SymbolTableManager", TRIM(status%message))
        END IF
    END SUBROUTINE get_variable_usage_stats
    
    !---------------------------------------------------------------------------
    ! save_symbol_table_to_file: Saves the entire symbol table to a file
    !---------------------------------------------------------------------------
    SUBROUTINE save_symbol_table_to_file(file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: file_unit, i, status_code
        LOGICAL :: file_exists
        
        CALL init_error_status(status)
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Check if file exists to avoid overwriting
        INQUIRE(FILE=file_path, EXIST=file_exists)
        IF (file_exists) THEN
            status%status_code = IF_STATUS_EXISTS
            WRITE(status%message, '(A,A,A)') "File '", TRIM(file_path), "' already exists"
            CALL log_warn("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Open file for writing
        OPEN(NEWUNIT=file_unit, FILE=file_path, STATUS='NEW', ACTION='WRITE', &
             FORM='FORMATTED', IOSTAT=status_code)
        IF (status_code /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,A,I0)') "Failed to open file '", TRIM(file_path), "' with error code  ", status_code
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Write symbol table header
        WRITE(file_unit, '(A)') "! Symbol Table Persistence File"
        WRITE(file_unit, '(A)') "! Format: Version 1.0"
        
        ! Write core symbol table state
        WRITE(file_unit, '(A,I0)') "IF_MAX_ENTRIES=", global_sym_table%max_entries
        WRITE(file_unit, '(A,I0)') "ENTRY_COUNT=", global_sym_table%entry_count
        WRITE(file_unit, '(A,L1)') "INITIALIZED=", global_sym_table%initialized
        WRITE(file_unit, '(A,F12.6)') "INIT_TIME=", global_sym_table%init_time
        WRITE(file_unit, '(A,I0)') "FREE_LIST_HEAD=", global_sym_table%free_list_head
        WRITE(file_unit, '(A,I0)') "RESIZE_THRESHOLD=", global_sym_table%resize_threshold
        
        ! Write hash table information
        WRITE(file_unit, '(A)') "BEGIN_HASH_TABLE"
        WRITE(file_unit, '(A,I0)') "HASH_SIZE=", global_sym_table%hash_table%size
        WRITE(file_unit, '(A,I0)') "HASH_ENTRY_COUNT=", global_sym_table%hash_table%count
        ! Note: Full hash table entries are not written here as they'll be reconstructed
        ! from the symbol table entries during load
        WRITE(file_unit, '(A)') "END_HASH_TABLE"
        
        ! Write symbol table entries
        WRITE(file_unit, '(A)') "BEGIN_ENTRIES"
        DO i = 1, global_sym_table%max_entries
            IF (global_sym_table%entries(i)%is_valid) THEN
                ! Write valid entry marker
                WRITE(file_unit, '(A,I0)') "ENTRY_START=", i
                WRITE(file_unit, '(A,A)') "VAR_NAME=", TRIM(global_sym_table%entries(i)%variable_name)
                WRITE(file_unit, '(A,A)') "DATA_ID=", TRIM(global_sym_table%entries(i)%data_id)
                WRITE(file_unit, '(A,I0)') "DATA_TYPE=", global_sym_table%entries(i)%data_type
                WRITE(file_unit, '(A,I0)') "IF_STORAGE_TYPE=", global_sym_table%entries(i)%storage_type
                WRITE(file_unit, '(A,L1)') "IS_VALID=", global_sym_table%entries(i)%is_valid
                WRITE(file_unit, '(A,I0)') "NEXT_FREE=", global_sym_table%entries(i)%next_free
                WRITE(file_unit, '(A,I0)') "ACCESS_COUNT=", global_sym_table%entries(i)%access_count
                WRITE(file_unit, '(A,I0)') "UPDATE_COUNT=", global_sym_table%entries(i)%update_count
                WRITE(file_unit, '(A,F12.6)') "LAST_ACCESS_TIME=", global_sym_table%entries(i)%last_access_time
                WRITE(file_unit, '(A,F12.6)') "CREATION_TIME=", global_sym_table%entries(i)%creation_time
                WRITE(file_unit, '(A)') "ENTRY_END"
            END IF
        END DO
        WRITE(file_unit, '(A)') "END_ENTRIES"
        
        ! Close file
        CLOSE(file_unit)
        
        status%status_code = IF_STATUS_OK
        !CALL log_info("SymbolTableManager", "Successfully saved symbol table to file: "//TRIM(file_path))
    END SUBROUTINE save_symbol_table_to_file
    
    !---------------------------------------------------------------------------
    ! load_symbol_table_from_file: Loads symbol table from a file
    !---------------------------------------------------------------------------
    SUBROUTINE load_symbol_table_from_file(file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: file_unit, i, status_code, entry_index
        CHARACTER(LEN=100) :: line, key, value
        LOGICAL :: file_exists, eof_reached, entry_started
        INTEGER(i4) :: max_entries, entry_count, hash_size, hash_entry_count
        LOGICAL :: initialized
        REAL :: init_time
        INTEGER(i4) :: free_list_head, resize_threshold
        
        CALL init_error_status(status)
        
        ! Check if file exists
        INQUIRE(FILE=file_path, EXIST=file_exists)
        IF (.NOT. file_exists) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            WRITE(status%message, '(A,A,A)') "File '", TRIM(file_path), "' not found"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Open file for reading
        OPEN(NEWUNIT=file_unit, FILE=file_path, STATUS='OLD', ACTION='READ', &
             FORM='FORMATTED', IOSTAT=status_code)
        IF (status_code /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,A,I0)') "Failed to open file '", TRIM(file_path), "' with error code  ", status_code
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! If symbol table is already initialized, we need to destroy it first
        IF (global_sym_table%initialized) THEN
            CALL destroy_sym_table(status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CLOSE(file_unit)
                CALL log_error("SymbolTableManager", "Failed to destroy existing symbol table before loading")
                RETURN
            END IF
        END IF
        
        ! Initialize parsing variables
        eof_reached = .FALSE.
        entry_started = .FALSE.
        
        ! Read file header and metadata
        DO WHILE (.NOT. eof_reached)
            READ(file_unit, '(A)', IOSTAT=status_code) line
            IF (status_code < 0) THEN
                eof_reached = .TRUE.
                EXIT
            ELSE IF (status_code > 0) THEN
                CLOSE(file_unit)
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Error reading file header"
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            
            ! Skip comments and empty lines
            IF (INDEX(line, '!') == 1 .OR. TRIM(line) == '') CYCLE
            
            ! Parse key-value pairs
            i = INDEX(line, '=')
            IF (i > 0) THEN
                key = line(1:i-1)
                value = line(i+1:)
                
                SELECT CASE(TRIM(key))
                CASE('IF_MAX_ENTRIES')
                    READ(value, *) max_entries
                CASE('ENTRY_COUNT')
                    READ(value, *) entry_count
                CASE('INITIALIZED')
                    READ(value, *) initialized
                CASE('INIT_TIME')
                    READ(value, *) init_time
                CASE('FREE_LIST_HEAD')
                    READ(value, *) free_list_head
                CASE('RESIZE_THRESHOLD')
                    READ(value, *) resize_threshold
                CASE('HASH_SIZE')
                    READ(value, *) hash_size
                CASE('HASH_ENTRY_COUNT')
                    READ(value, *) hash_entry_count
                END SELECT
            END IF
            
            ! Check for BEGIN_ENTRIES marker
            IF (TRIM(line) == 'BEGIN_ENTRIES') EXIT
        END DO
        
        ! Initialize symbol table with loaded parameters
        CALL init_sym_table(status, max_entries)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CLOSE(file_unit)
            CALL log_error("SymbolTableManager", "Failed to initialize symbol table with loaded parameters")
            RETURN
        END IF
        
        ! Set loaded state values (overwriting init_sym_table defaults)
        global_sym_table%entry_count = 0  ! Will be incremented as we load entries
        global_sym_table%init_time = init_time
        global_sym_table%free_list_head = free_list_head
        global_sym_table%resize_threshold = resize_threshold
        
        ! Reset entry_started flag for entry parsing
        entry_started = .FALSE.
        
        ! Read and process entries
        DO WHILE (.NOT. eof_reached)
            READ(file_unit, '(A)', IOSTAT=status_code) line
            IF (status_code < 0) THEN
                eof_reached = .TRUE.
                EXIT
            ELSE IF (status_code > 0) THEN
                CLOSE(file_unit)
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Error reading entries section"
                CALL log_error("SymbolTableManager", TRIM(status%message))
                RETURN
            END IF
            
            ! Check for END_ENTRIES marker
            IF (TRIM(line) == 'END_ENTRIES') EXIT
            
            ! Check for entry start
            IF (INDEX(TRIM(line), 'ENTRY_START=') == 1) THEN
                READ(line(LEN('ENTRY_START=')+1:), *) entry_index
                entry_started = .TRUE.
                
                ! Initialize entry with defaults
                global_sym_table%entries(entry_index)%variable_name = ""
                global_sym_table%entries(entry_index)%data_id = ""
                global_sym_table%entries(entry_index)%data_type = 0
                global_sym_table%entries(entry_index)%storage_type = 0
                global_sym_table%entries(entry_index)%is_valid = .FALSE.
                global_sym_table%entries(entry_index)%next_free = 0
                global_sym_table%entries(entry_index)%access_count = 0
                global_sym_table%entries(entry_index)%update_count = 0
                global_sym_table%entries(entry_index)%last_access_time = 0.0
                global_sym_table%entries(entry_index)%creation_time = 0.0
                
            ELSE IF (entry_started .AND. TRIM(line) == 'ENTRY_END') THEN
                ! End of entry - add to hash table if valid
                IF (global_sym_table%entries(entry_index)%is_valid) THEN
                    ! Add to hash table
                    CALL hash_table_insert(global_sym_table%hash_table, &
                                          TRIM(global_sym_table%entries(entry_index)%variable_name), &
                                          entry_index, status)
                    IF (status%status_code /= IF_STATUS_OK) THEN
                        CLOSE(file_unit)
                        CALL log_error("SymbolTableManager", "Failed to insert entry into hash table during load")
                        RETURN
                    END IF
                    
                    ! Increment entry count
                    global_sym_table%entry_count = global_sym_table%entry_count + 1
                END IF
                entry_started = .FALSE.
            
            ELSE IF (entry_started) THEN
                ! Parse entry field
                i = INDEX(line, '=')
                IF (i > 0) THEN
                    key = line(1:i-1)
                    value = line(i+1:)
                    
                    SELECT CASE(TRIM(key))
                    CASE('VAR_NAME')
                        global_sym_table%entries(entry_index)%variable_name = TRIM(value)
                    CASE('DATA_ID')
                        global_sym_table%entries(entry_index)%data_id = TRIM(value)
                    CASE('DATA_TYPE')
                        READ(value, *) global_sym_table%entries(entry_index)%data_type
                    CASE('IF_STORAGE_TYPE')
                        READ(value, *) global_sym_table%entries(entry_index)%storage_type
                    CASE('IS_VALID')
                        READ(value, *) global_sym_table%entries(entry_index)%is_valid
                    CASE('NEXT_FREE')
                        READ(value, *) global_sym_table%entries(entry_index)%next_free
                    CASE('ACCESS_COUNT')
                        READ(value, *) global_sym_table%entries(entry_index)%access_count
                    CASE('UPDATE_COUNT')
                        READ(value, *) global_sym_table%entries(entry_index)%update_count
                    CASE('LAST_ACCESS_TIME')
                        READ(value, *) global_sym_table%entries(entry_index)%last_access_time
                    CASE('CREATION_TIME')
                        READ(value, *) global_sym_table%entries(entry_index)%creation_time
                    END SELECT
                END IF
            END IF
        END DO
        
        ! Close file
        CLOSE(file_unit)
        
        status%status_code = IF_STATUS_OK
        !CALL log_info("SymbolTableManager", "Successfully loaded symbol table from file: "//TRIM(file_path))
    END SUBROUTINE load_symbol_table_from_file
    
    !---------------------------------------------------------------------------
    ! update_lru_cache: Updates the LRU cache by moving the accessed entry to the head
    !---------------------------------------------------------------------------
    SUBROUTINE update_lru_cache(entry_index, status)
        INTEGER(i4), INTENT(IN) :: entry_index
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: prev_entry, next_entry
        
        CALL init_error_status(status)
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Pre-check: Valid entry index
        IF (entry_index < 1 .OR. entry_index > global_sym_table%max_entries) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0)') "Invalid entry index: ", entry_index
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Pre-check: Entry must be valid
        IF (.NOT. global_sym_table%entries(entry_index)%is_valid) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Entry is not valid"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! If entry is already at head, do nothing
        IF (entry_index == global_sym_table%lru_head .AND. global_sym_table%lru_head /= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF
        
        ! Case 1: Entry is already in LRU list but not at head
        prev_entry = global_sym_table%entries(entry_index)%prev
        next_entry = global_sym_table%entries(entry_index)%next
        
        IF (prev_entry /= 0 .OR. next_entry /= 0 .OR. entry_index == global_sym_table%lru_tail) THEN
            ! Remove entry from current position in list
            IF (prev_entry /= 0) THEN
                ! Update previous entry's next pointer
                global_sym_table%entries(prev_entry)%next = next_entry
            ELSE
                ! Entry was at head, update head
                global_sym_table%lru_head = next_entry
            END IF
            
            IF (next_entry /= 0) THEN
                ! Update next entry's previous pointer
                global_sym_table%entries(next_entry)%prev = prev_entry
            ELSE
                ! Entry was at tail, update tail
                global_sym_table%lru_tail = prev_entry
            END IF
            
            ! Clear entry's pointers
            global_sym_table%entries(entry_index)%prev = 0
            global_sym_table%entries(entry_index)%next = 0
        END IF
        
        ! Insert entry at head of LRU list
        IF (global_sym_table%lru_head /= 0) THEN
            ! List is not empty
            global_sym_table%entries(global_sym_table%lru_head)%prev = entry_index
            global_sym_table%entries(entry_index)%next = global_sym_table%lru_head
        ELSE
            ! List is empty, set tail to this entry too
            global_sym_table%lru_tail = entry_index
        END IF
        
        ! Update head to point to this entry
        global_sym_table%lru_head = entry_index
        
        ! Check if LRU cache exceeds maximum size
        ! For simplicity, we don't automatically evict entries here
        ! Eviction can be implemented in find_variable if needed
        
        status%status_code = IF_STATUS_OK
        CALL log_debug("SymbolTableManager", "Updated LRU cache, entry moved to head")
    END SUBROUTINE update_lru_cache
    
    !---------------------------------------------------------------------------
    ! configure_lru_cache_size: Configures the maximum size of the LRU cache
    !---------------------------------------------------------------------------
    SUBROUTINE configure_lru_cache_size(new_size, status)
        INTEGER(i4), INTENT(IN) :: new_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Validate new size
        IF (new_size <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0)') "Invalid LRU cache size: ", new_size
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Set new LRU cache size
        global_sym_table%lru_max_size = new_size
        
        ! If current entry count exceeds new size, we could implement eviction here
        ! For now, we just log a message
        IF (global_sym_table%entry_count > new_size) THEN
            CALL log_warn("SymbolTableManager", "LRU cache size reduced below current entry count")
        END IF
        
        status%status_code = IF_STATUS_OK
        WRITE(status%message, '(A,I0)') "LRU cache size configured to ", new_size
        !CALL log_info("SymbolTableManager", TRIM(status%message))
    END SUBROUTINE configure_lru_cache_size
    
    !---------------------------------------------------------------------------
    ! save_variable_version: Saves a new version of a variable
    !---------------------------------------------------------------------------
    SUBROUTINE save_variable_version(variable_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: entry_index
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id
        INTEGER(i4) :: data_type, storage_type
        REAL(wp) :: current_time
        INTEGER(i4) :: i
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(status)

        ! Skip unregister for internal cache variables ("__cache_" prefix)
        IF (LEN_TRIM(variable_name) >= 8) THEN
            IF (variable_name(1:8) == "__cache_") THEN
                status%status_code = IF_STATUS_OK
                status%message = "Internal cache variable ignored in unregister"
                RETURN
            END IF
        END IF

        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Find the variable index using hash_table_find
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), local_status)
        IF (entry_index == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Variable not found: "//TRIM(variable_name)
            CALL log_error("SymbolTableManager", "Failed to find variable for versioning: "//TRIM(variable_name))
            RETURN
        END IF
        
        ! Get current time
        CALL CPU_TIME(current_time)
        
        ! Increment version
        global_sym_table%entries(entry_index)%current_version = global_sym_table%entries(entry_index)%current_version + 1
        
        ! Shift versions if we've reached the maximum
        IF (global_sym_table%entries(entry_index)%version_count >= IF_MAX_VERSIONS) THEN
            ! Shift all versions down by one
            DO i = 1, IF_MAX_VERSIONS - 1
                global_sym_table%entries(entry_index)%version_history(i) = &
                    global_sym_table%entries(entry_index)%version_history(i+1)
                global_sym_table%entries(entry_index)%version_timestamps(i) = &
                    global_sym_table%entries(entry_index)%version_timestamps(i+1)
            END DO
            global_sym_table%entries(entry_index)%version_count = IF_MAX_VERSIONS - 1
        END IF
        
        ! Add new version to history (at the end of the list)
        global_sym_table%entries(entry_index)%version_count = global_sym_table%entries(entry_index)%version_count + 1
        global_sym_table%entries(entry_index)%version_history(global_sym_table%entries(entry_index)%version_count) = &
            global_sym_table%entries(entry_index)%current_version
        global_sym_table%entries(entry_index)%version_timestamps(global_sym_table%entries(entry_index)%version_count) = current_time
        
        status%status_code = IF_STATUS_OK
        WRITE(status%message, '(A,I0,A)') "Saved version ", global_sym_table%entries(entry_index)%current_version, &
            " of variable: "//TRIM(variable_name)
        !CALL log_info("SymbolTableManager", TRIM(status%message))
    END SUBROUTINE save_variable_version
    
    !---------------------------------------------------------------------------
    ! rollback_to_version: Rolls back a variable to a specific version
    !---------------------------------------------------------------------------
    SUBROUTINE rollback_to_version(variable_name, target_version, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        INTEGER(i4), INTENT(IN) :: target_version
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: entry_index
        INTEGER(i4) :: version_index
        REAL(wp) :: current_time
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(status)

        ! Skip unregister for internal cache variables ("__cache_" prefix)
        IF (LEN_TRIM(variable_name) >= 8) THEN
            IF (variable_name(1:8) == "__cache_") THEN
                status%status_code = IF_STATUS_OK
                status%message = "Internal cache variable ignored in unregister"
                RETURN
            END IF
        END IF

        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Find the variable index using hash_table_find
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), local_status)
        IF (entry_index == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Variable not found: "//TRIM(variable_name)
            CALL log_error("SymbolTableManager", "Failed to find variable for rollback: "//TRIM(variable_name))
            RETURN
        END IF
        
        ! Check if target version is valid
        IF (target_version <= 0 .OR. target_version > global_sym_table%entries(entry_index)%current_version) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0,A,I0)') "Invalid target version: ", target_version, &
                ", must be between 1 and ", global_sym_table%entries(entry_index)%current_version
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Calculate version index in history array
        version_index = global_sym_table%entries(entry_index)%current_version - target_version + 1
        
        ! Check if version is in history
        IF (version_index > global_sym_table%entries(entry_index)%version_count) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            WRITE(status%message, '(A,I0,A)') "Version ", target_version, " is not available in history"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Save current state as a new version before rolling back
        CALL CPU_TIME(current_time)
        
        ! Save the current data ID before replacing it
        IF (global_sym_table%entries(entry_index)%version_count < IF_MAX_VERSIONS) THEN
            global_sym_table%entries(entry_index)%version_count = global_sym_table%entries(entry_index)%version_count + 1
        ELSE
            ! Shift existing versions if we've reached the maximum
            DO version_index = 1, IF_MAX_VERSIONS - 1
                global_sym_table%entries(entry_index)%version_history(version_index) = &
				global_sym_table%entries(entry_index)%version_history(version_index+1)
                global_sym_table%entries(entry_index)%version_timestamps(version_index) = &
				global_sym_table%entries(entry_index)%version_timestamps(version_index+1)
            END DO
        END IF
        
        ! Store current version as a new version
        global_sym_table%entries(entry_index)%version_history(global_sym_table%entries(entry_index)%version_count) = &
            global_sym_table%entries(entry_index)%current_version
        global_sym_table%entries(entry_index)%version_timestamps(global_sym_table%entries(entry_index)%version_count) = current_time
        
        ! Rollback to target version - set current version to target
        ! Note: Version history now stores version numbers, not data IDs
        global_sym_table%entries(entry_index)%current_version = target_version
   !     CALL log_info("SymbolTableManager", "Rolled back variable '"//&
			!TRIM(variable_name)//"' to version "//TRIM(INT_TO_STR(target_version)))
        
        ! Update usage statistics
        global_sym_table%entries(entry_index)%access_count = global_sym_table%entries(entry_index)%access_count + 1
        global_sym_table%entries(entry_index)%last_access_time = current_time
        
        status%status_code = IF_STATUS_OK
        WRITE(status%message, '(A,I0,A)') "Rolled back variable '"//TRIM(variable_name)//"' to version ", target_version
        !CALL log_info("SymbolTableManager", TRIM(status%message))
    END SUBROUTINE rollback_to_version
    
    !---------------------------------------------------------------------------
    ! get_variable_version_history: Retrieves the version history of a variable
    !---------------------------------------------------------------------------
    SUBROUTINE get_variable_version_history(variable_name, versions, timestamps, version_count, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        INTEGER(i4), INTENT(OUT) :: versions(IF_MAX_VERSIONS)
        REAL(wp), INTENT(OUT) :: timestamps(IF_MAX_VERSIONS)
        INTEGER(i4), INTENT(OUT) :: version_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: entry_index
        INTEGER(i4) :: i
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(status)

        ! Skip unregister for internal cache variables ("__cache_" prefix)
        IF (LEN_TRIM(variable_name) >= 8) THEN
            IF (variable_name(1:8) == "__cache_") THEN
                status%status_code = IF_STATUS_OK
                status%message = "Internal cache variable ignored in unregister"
                RETURN
            END IF
        END IF

        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Find the variable index using hash_table_find
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), local_status)
        IF (entry_index == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Variable not found: "//TRIM(variable_name)
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Initialize output arrays
        versions = 0
        timestamps = 0.0
        version_count = global_sym_table%entries(entry_index)%version_count
        
        ! Copy version history
        DO i = 1, version_count
            versions(i) = global_sym_table%entries(entry_index)%version_history(i)
            timestamps(i) = global_sym_table%entries(entry_index)%version_timestamps(i)
        END DO
        
        status%status_code = IF_STATUS_OK
        WRITE(status%message, '(A,I0,A)') "Retrieved ", version_count, " versions for variable: "//TRIM(variable_name)
        !CALL log_info("SymbolTableManager", TRIM(status%message))
    END SUBROUTINE get_variable_version_history
    
    !---------------------------------------------------------------------------
    ! get_variable_current_version: Retrieves the current version of a variable
    !---------------------------------------------------------------------------
    SUBROUTINE get_variable_current_version(variable_name, current_version, status)
        CHARACTER(LEN=*), INTENT(IN) :: variable_name
        INTEGER(i4), INTENT(OUT) :: current_version
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: entry_index
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(status)

        ! Skip unregister for internal cache variables ("__cache_" prefix)
        IF (LEN_TRIM(variable_name) >= 8) THEN
            IF (variable_name(1:8) == "__cache_") THEN
                status%status_code = IF_STATUS_OK
                status%message = "Internal cache variable ignored in unregister"
                RETURN
            END IF
        END IF

        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Find the variable index using hash_table_find
        entry_index = hash_table_find(global_sym_table%hash_table, TRIM(variable_name), local_status)
        IF (entry_index == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Variable not found: "//TRIM(variable_name)
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Get current version
        current_version = global_sym_table%entries(entry_index)%current_version
        
        status%status_code = IF_STATUS_OK
        WRITE(status%message, '(A,I0,A)') "Current version of variable '"//TRIM(variable_name)//"' is ", current_version
        !CALL log_info("SymbolTableManager", TRIM(status%message))
    END SUBROUTINE get_variable_current_version
    
    !---------------------------------------------------------------------------
    ! get_symbol_table_status: Retrieves the current status of the symbol table
    !---------------------------------------------------------------------------
    SUBROUTINE get_symbol_table_status(status_data, status)
        TYPE(SymbolTableStatusType), INTENT(OUT) :: status_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        
        CALL init_error_status(status)
        
        ! Initialize status data
        status_data%initialized = global_sym_table%initialized
        
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            !CALL log_info("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Fill status data
        status_data%entry_count = global_sym_table%entry_count
        status_data%max_entries = global_sym_table%max_entries
        status_data%free_entries = global_sym_table%max_entries - global_sym_table%entry_count
        status_data%initialization_time = global_sym_table%init_time
        status_data%lru_cache_size = 0  ! Need to calculate actual LRU cache size
        status_data%lru_max_size = global_sym_table%lru_max_size
        
        ! Calculate LRU cache size by traversing the LRU list
        i = global_sym_table%lru_head
        DO WHILE (i /= 0)
            status_data%lru_cache_size = status_data%lru_cache_size + 1
            i = global_sym_table%entries(i)%next
        END DO
        
        ! Estimate memory usage (very rough estimate)
        ! Each entry: ~200 bytes (variable name, data ID, integers, etc.)
        ! Hash table: ~4 bytes per bucket (pointer)
        status_data%memory_usage = REAL(global_sym_table%max_entries * 200 + &
            SIZE(global_sym_table%hash_table%buckets) * 4, KIND=wp) / 1024.0
        
        status%status_code = IF_STATUS_OK
        status%message = "Retrieved symbol table status successfully"
        !CALL log_info("SymbolTableManager", TRIM(status%message))
    END SUBROUTINE get_symbol_table_status
    
    !---------------------------------------------------------------------------
    ! generate_symbol_table_report: Generates a comprehensive report of the symbol table
    !---------------------------------------------------------------------------
    SUBROUTINE generate_symbol_table_report(report_file, status)
        CHARACTER(LEN=*), INTENT(IN) :: report_file
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(SymbolTableStatusType) :: status_data
        INTEGER(i4) :: unit_num = 10
        INTEGER(i4) :: i
        REAL(wp) :: current_time
        
        CALL init_error_status(status)
        
        ! Pre-check: Symbol table initialization status
        IF (.NOT. global_sym_table%initialized) THEN
            status%status_code = IF_STATUS_TABLE_NOT_INIT
            status%message = "Symbol table not initialized"
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Get symbol table status
        CALL get_symbol_table_status(status_data, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("SymbolTableManager", "Failed to get symbol table status for report")
            RETURN
        END IF
        
        ! Open report file
        OPEN(UNIT=unit_num, FILE=report_file, STATUS='REPLACE', ACTION='WRITE', IOSTAT=i)
        IF (i /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,A)') "Failed to open report file: ", TRIM(report_file)
            CALL log_error("SymbolTableManager", TRIM(status%message))
            RETURN
        END IF
        
        ! Get current time
        CALL CPU_TIME(current_time)
        
        ! Write report header
        WRITE(unit_num, '(A)') "==========================================================="
        WRITE(unit_num, '(A)') "                SYMBOL TABLE STATUS REPORT                "
        WRITE(unit_num, '(A)') "==========================================================="
        WRITE(unit_num, '(A,F15.3,A)') "Report generated at: ", current_time, " seconds since initialization"
        WRITE(unit_num, '(A)') "-----------------------------------------------------------"
        
        ! Write general statistics
        WRITE(unit_num, '(A)') "General Statistics:"
        WRITE(unit_num, '(A,L1)') "  Initialized: ", status_data%initialized
        WRITE(unit_num, '(A,I10)') "  Entry Count: ", status_data%entry_count
        WRITE(unit_num, '(A,I10)') "  Max Entries: ", status_data%max_entries
        WRITE(unit_num, '(A,I10)') "  Free Entries:", status_data%free_entries
        WRITE(unit_num, '(A,F10.3,A)') "  Memory Usage:", status_data%memory_usage, " KB"
        WRITE(unit_num, '(A)') "-----------------------------------------------------------"
        
        ! Write LRU cache statistics
        WRITE(unit_num, '(A)') "LRU Cache Statistics:"
        WRITE(unit_num, '(A,I10)') "  Current Size:", status_data%lru_cache_size
        WRITE(unit_num, '(A,I10)') "  Max Size:    ", status_data%lru_max_size
        WRITE(unit_num, '(A,F8.2,A)') "  Utilization: ", &
            REAL(status_data%lru_cache_size)/REAL(status_data%lru_max_size)*100.0, "%"
        WRITE(unit_num, '(A)') "-----------------------------------------------------------"
        
        ! Write variable list (top 10 most accessed variables)
        WRITE(unit_num, '(A)') "Top 10 Most Accessed Variables:"
        WRITE(unit_num, '(A)') "  No.  | Variable Name        | Access Count | Update Count | Current Version"
        WRITE(unit_num, '(A)') "-------+----------------------+--------------+--------------+---------------"
        
        ! For simplicity, we'll just list the first 10 valid variables
        ! In a real implementation, we would sort by access_count
        i = 0
        DO WHILE (i < global_sym_table%max_entries .AND. i < 10)
            i = i + 1
            IF (global_sym_table%entries(i)%is_valid) THEN
                WRITE(unit_num, '(I6," | ",A20," | ",I12," | ",I12," | ",I15)') &
                    i, TRIM(global_sym_table%entries(i)%variable_name), &
                    global_sym_table%entries(i)%access_count, &
                    global_sym_table%entries(i)%update_count, &
                    global_sym_table%entries(i)%current_version
            END IF
        END DO
        
        WRITE(unit_num, '(A)') "==========================================================="
        
        ! Close report file
        CLOSE(UNIT=unit_num)
        
        status%status_code = IF_STATUS_OK
        WRITE(status%message, '(A,A)') "Generated symbol table report to file: ", TRIM(report_file)
        !CALL log_info("SymbolTableManager", TRIM(status%message))
    END SUBROUTINE generate_symbol_table_report

END MODULE IF_Base_SymTbl