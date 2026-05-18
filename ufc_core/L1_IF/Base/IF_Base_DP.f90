!===============================================================================
! MODULE: IF_Base_DP
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Core — unified data platform (structured / unstructured access)
! BRIEF:  Single entry-point for higher-level data access, hiding
!         Struct/Unstruct + SymbolTable + FileManager details.
! Status: Draft | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Base_DP
    USE, INTRINSIC :: ISO_C_BINDING, ONLY: C_PTR, C_F_POINTER, C_NULL_PTR
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_error, log_warn, log_info, log_debug, log_fatal, &
        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN, IF_STATUS_MEM_ERROR, &
        IF_STATUS_INVALID, IF_STATUS_UNSUPPORTED, IF_STATUS_IO_ERROR, IF_STATUS_NOT_FOUND, IF_STATUS_EXISTS, IF_STATUS_FATAL, &
        IF_LEVEL_DEBUG, IF_LEVEL_INFO, IF_LEVEL_WARN, IF_LEVEL_ERROR, IF_LEVEL_FATAL, &
        IF_MAX_MESSAGE_LEN

    USE IF_Base_SymTbl, ONLY: &
        symbol_table_exists, get_variable_data_id, register_variable, find_variable, &
        IF_STORAGE_TYPE_STRUCTURED, IF_STORAGE_TYPE_UNSTRUCTURED, &
        IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR, &
        IF_DATA_TYPE_STRUCT, IF_DATA_TYPE_CLASS

    USE IF_Base_StructMeta_Def, ONLY: &
        StructMetaType, struct_meta_query, struct_meta_validate, struct_meta_update, &
        struct_meta_create, INT_TO_STR, INT_ARR_TO_STR, IF_STATUS_META_NOT_FOUND, struct_meta_try_query

    USE IF_Base_UnstructMeta_Def, ONLY: &
        UnstructMetaType, UnstructAttrType, &
        UNSTRUCT_TYPE_HASH, UNSTRUCT_TYPE_LINKED_LIST, UNSTRUCT_TYPE_ADJACENCY, &
        UNSTRUCT_TYPE_SKIP_LIST, UNSTRUCT_TYPE_GRAPH, UNSTRUCT_TYPE_QUEUE, &
        IF_DEFAULT_HASH_BUCKETS, &
        unstruct_meta_create, unstruct_meta_query, unstruct_meta_validate, unstruct_meta_update, &
        IF_STATUS_UNSMETA_EXISTS, IF_STATUS_UNSMETA_NOT_FOUND, unstruct_meta_try_query

    USE IF_Mem_StructPool

    USE IF_Mem_UnStructPool, ONLY: &
        init_unstruct_mem_pool, destroy_unstruct_mem_pool, &
        get_unstruct_data_info, unstruct_data_exists, delete_unstruct_data, &
        create_queue, queue_enqueue, queue_dequeue, get_queue_size, &
        create_graph, graph_add_node, graph_add_edge, get_graph_size, &
        create_adjacency_list, get_adjacency_list_size, adjacency_list_add_edge, &
        create_hash_table, get_hash_table_size, hash_table_insert, hash_table_get, &
        create_linked_list, get_linked_list_size, linked_list_insert, linked_list_get_values, &
        create_skip_list, get_skip_list_size, skip_list_insert, skip_list_get_all, &
        graph_bfs, graph_dfs

    USE IF_IO_StructFile, ONLY: &
        SFM_FORMAT_BINARY => IF_FORMAT_BINARY, &
        SFM_FORMAT_TXT    => IF_FORMAT_TXT, &
        FileHandleType, DataBlockType, &
        sfm_open_file, sfm_close_file, sfm_write_data, sfm_read_data, &
        IF_STATUS_SFILE_OK

    USE IF_StructFormat_API, ONLY: &
        sfm_write_struct_dat, sfm_read_struct_dat, &
        sfm_write_struct_inp, sfm_read_struct_inp, &
        sfm_write_struct_csv, sfm_read_struct_csv

    USE IF_UnstructFile_Mgr, ONLY: &
        UFM_FORMAT_BINARY  => IF_FORMAT_BINARY, &
        UFM_FORMAT_TXT     => IF_FORMAT_TXT, &
        ufm_write_unstruct_data, ufm_load_unstruct_data

    USE IF_UnstructFormat_API, ONLY: &
        ufm_write_unstruct_dat, ufm_load_unstruct_dat, &
        ufm_write_unstruct_inp, ufm_load_unstruct_inp, &
        ufm_write_unstruct_csv, ufm_load_unstruct_csv

    USE IF_IO_Backup, ONLY: &
        backup_data, restore_data

    USE IF_Mem_Chunk, ONLY: &
        GenericChunkMetaType, gcm_get_chunks

    IMPLICIT NONE

    PRIVATE

    ! Generic field description types for structured and class types
    TYPE :: StructFieldDesc
        CHARACTER(LEN=64) :: field_name = ""
        INTEGER(i4) :: data_type  = 0
        INTEGER(i4) :: offset_bytes = 0
        INTEGER(i4) :: elem_len   = 0
        INTEGER(i4) :: rank       = 0
        INTEGER(i4) :: dims(4)    = [1,1,1,1]
    END TYPE StructFieldDesc

    TYPE :: ClassFieldDesc
        CHARACTER(LEN=64) :: field_name = ""
        INTEGER(i4) :: data_type  = 0
        INTEGER(i4) :: offset_bytes = 0
        INTEGER(i4) :: elem_len   = 0
        INTEGER(i4) :: rank       = 0
        INTEGER(i4) :: dims(4)    = [1,1,1,1]
        LOGICAL           :: is_inherited = .FALSE.
    END TYPE ClassFieldDesc

    INTEGER(i4), PARAMETER :: IF_MAX_STRUCT_TYPES = 64
    INTEGER(i4), PARAMETER :: IF_MAX_CLASS_TYPES  = 64

    TYPE :: StructTypeRegistryEntry
        CHARACTER(LEN=64) :: type_name = ""
        INTEGER(i4) :: num_fields = 0
        TYPE(StructFieldDesc), ALLOCATABLE :: fields(:)
        INTEGER(KIND=8)   :: elem_size = 0_8
        LOGICAL           :: is_used = .FALSE.
    END TYPE StructTypeRegistryEntry

    TYPE :: ClassTypeRegistryEntry
        CHARACTER(LEN=64) :: type_name = ""
        CHARACTER(LEN=64) :: parent_type_name = ""
        INTEGER(i4) :: num_fields = 0
        TYPE(ClassFieldDesc), ALLOCATABLE :: fields(:)
        INTEGER(KIND=8)   :: elem_size = 0_8
        LOGICAL           :: is_used = .FALSE.
    END TYPE ClassTypeRegistryEntry

    TYPE(StructTypeRegistryEntry), SAVE :: struct_type_registry(IF_MAX_STRUCT_TYPES)
    TYPE(ClassTypeRegistryEntry),  SAVE :: class_type_registry(IF_MAX_CLASS_TYPES)

    ! High-level variable view catalog for semantic queries
    TYPE :: DP_VarView
        CHARACTER(LEN=32) :: category   = ""   ! e.g. 'STATE', 'HISTORY', 'CONTROL'
        CHARACTER(LEN=32) :: scope      = ""   ! e.g. 'MODEL', 'NODE', 'ELEM', 'SOLVER'
        CHARACTER(LEN=64) :: var_name   = ""   ! DataPlatform variable name
        INTEGER(i4) :: storage_type = 0   ! IF_STORAGE_TYPE_STRUCTURED / UNSTRUCTURED
        INTEGER(i4) :: data_type     = 0   ! IF_DATA_TYPE_INT / DP / STRUCT / CLASS
    END TYPE DP_VarView

    INTEGER(i4), PARAMETER :: IF_MAX_VAR_VIEWS = 256
    TYPE(DP_VarView), SAVE :: dp_var_views(IF_MAX_VAR_VIEWS)
    INTEGER, SAVE :: dp_var_view_count = 0

    ! DataPlatform-level logging and error statistics state
    INTEGER, SAVE :: dp_log_level = IF_LEVEL_INFO
    TYPE(ErrorStatusType), SAVE :: dp_last_error
    INTEGER, SAVE :: dp_error_count = 0
    INTEGER, SAVE :: dp_warn_count  = 0


    TYPE :: ShardMovePlan
        CHARACTER(LEN=64)  :: logical_id  = ""
        CHARACTER(LEN=256) :: file_path   = ""
        INTEGER(i4) :: chunk_id    = 0
        INTEGER(i4) :: from_node   = 0
        INTEGER(i4) :: to_node     = 0
    END TYPE ShardMovePlan

    INTEGER(i4), PARAMETER :: IF_DP_FORMAT_BINARY = 1
    INTEGER(i4), PARAMETER :: IF_DP_FORMAT_TXT    = 2
    PUBLIC :: IF_DP_FORMAT_BINARY, IF_DP_FORMAT_TXT

    ! ------------------------------------------------------------------------
    ! Public API
    ! ------------------------------------------------------------------------
    PUBLIC :: dp_init
    PUBLIC :: dp_shutdown
    PUBLIC :: dp_set_log_level
    PUBLIC :: dp_get_log_level
    PUBLIC :: dp_get_last_error
    PUBLIC :: dp_get_error_stats
    PUBLIC :: dp_reset_error_stats

    PUBLIC :: dp_register_struct_array
    PUBLIC :: dp_register_unstruct
    PUBLIC :: dp_ensure_unstruct
    PUBLIC :: dp_register_struct_type
    PUBLIC :: dp_register_class_type
    PUBLIC :: StructFieldDesc
    PUBLIC :: ClassFieldDesc
    PUBLIC :: IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR

    PUBLIC :: dp_save
    PUBLIC :: dp_load

    PUBLIC :: dp_backup
    PUBLIC :: dp_restore

    PUBLIC :: dp_get_meta
    PUBLIC :: dp_validate

    PUBLIC :: dp_get_struct_handle
    PUBLIC :: dp_get_unstruct_handle
    PUBLIC :: dp_get_struct_ptr
    PUBLIC :: dp_get_class_ptr
    PUBLIC :: dp_get_struct_element_ptr
    PUBLIC :: dp_get_struct_element_cptr
    PUBLIC :: dp_get_class_element_ptr
    PUBLIC :: DP_VarView
    PUBLIC :: dp_register_var_view
    PUBLIC :: dp_list_var_views


    ! High-level structured array creation APIs (unified memory based)
    PUBLIC :: dp_create_int_array1d, dp_create_int_array2d
    PUBLIC :: dp_create_dp_array1d, dp_create_dp_array2d
    PUBLIC :: dp_create_int_array3d, dp_create_int_array4d
    PUBLIC :: dp_create_dp_array3d, dp_create_dp_array4d
    PUBLIC :: dp_create_char_array1d, dp_create_char_array2d
    PUBLIC :: dp_create_char_array3d, dp_create_char_array4d
    PUBLIC :: dp_create_struct_array, dp_create_class_array

    ! High-level unstructured queue / graph / adjacency / container APIs
    PUBLIC :: dp_ensure_queue
    PUBLIC :: dp_create_queue
    PUBLIC :: dp_queue_enqueue
    PUBLIC :: dp_queue_dequeue
    PUBLIC :: dp_queue_get_size

    PUBLIC :: dp_create_graph
    PUBLIC :: dp_graph_add_node
    PUBLIC :: dp_graph_add_edge
    PUBLIC :: dp_get_graph_size
    PUBLIC :: dp_graph_bfs
    PUBLIC :: dp_graph_dfs

    PUBLIC :: dp_create_adjacency_list
    PUBLIC :: dp_adjacency_add_edge
    PUBLIC :: dp_get_adjacency_list_size

    PUBLIC :: dp_create_hash_table
    PUBLIC :: dp_get_hash_table_size
    PUBLIC :: dp_hash_insert
    PUBLIC :: dp_hash_get

    PUBLIC :: dp_create_linked_list
    PUBLIC :: dp_get_linked_list_size
    PUBLIC :: dp_list_push_back
    PUBLIC :: dp_list_get_values

    PUBLIC :: dp_create_skip_list
    PUBLIC :: dp_get_skip_list_size
    PUBLIC :: dp_skip_insert
    PUBLIC :: dp_skip_get_all

    PUBLIC :: dp_dump_debug
    PUBLIC :: dp_get_shards
    PUBLIC :: dp_get_shards_by_node
    PUBLIC :: dp_get_shards_for_file
    PUBLIC :: ShardMovePlan
    PUBLIC :: dp_plan_rebalance

    LOGICAL, SAVE :: dp_initialized = .FALSE.

CONTAINS

    SUBROUTINE dp_log(level, source, message)
        INTEGER(i4), INTENT(IN) :: level
        CHARACTER(LEN=*), INTENT(IN) :: source
        CHARACTER(LEN=*), INTENT(IN) :: message

        CHARACTER(LEN=IF_MAX_MESSAGE_LEN) :: local_msg

        local_msg = TRIM(message)

        SELECT CASE (level)
        CASE (IF_LEVEL_DEBUG)
            IF (level < dp_log_level) RETURN
            CALL log_debug(source, TRIM(local_msg))
        CASE (IF_LEVEL_INFO)
            IF (level < dp_log_level) RETURN
            CALL log_info(source, TRIM(local_msg))
        CASE (IF_LEVEL_WARN)
            IF (level < dp_log_level) RETURN
            CALL log_warn(source, TRIM(local_msg))
            dp_warn_count = dp_warn_count + 1
        CASE (IF_LEVEL_ERROR)
            IF (level < dp_log_level) RETURN
            CALL log_error(source, TRIM(local_msg))
            CALL init_error_status(dp_last_error)
            dp_last_error%status_code = IF_STATUS_ERROR
            dp_last_error%message = TRIM(local_msg)
            dp_error_count = dp_error_count + 1
        CASE (IF_LEVEL_FATAL)
            CALL log_fatal(source, TRIM(local_msg))
            CALL init_error_status(dp_last_error)
            dp_last_error%status_code = IF_STATUS_FATAL
            dp_last_error%message = TRIM(local_msg)
            dp_error_count = dp_error_count + 1
        CASE DEFAULT
            IF (IF_LEVEL_INFO >= dp_log_level) THEN
                CALL log_info(source, TRIM(local_msg))
            END IF
        END SELECT
    END SUBROUTINE dp_log

    SUBROUTINE dp_set_log_level(level, status)
        INTEGER(i4), INTENT(IN) :: level
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (level < IF_LEVEL_DEBUG .OR. level > IF_LEVEL_FATAL) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_set_log_level: invalid level"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dp_log_level = level
        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "dp_set_log_level: new level="//TRIM(INT_TO_STR(level)))
    END SUBROUTINE dp_set_log_level

    SUBROUTINE dp_get_log_level(level, status)
        INTEGER(i4), INTENT(OUT) :: level
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        level = dp_log_level
        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_log_level

    SUBROUTINE dp_get_last_error(error)
        TYPE(ErrorStatusType), INTENT(OUT) :: error

        error = dp_last_error
    END SUBROUTINE dp_get_last_error

    SUBROUTINE dp_get_error_stats(total_errors, total_warnings)
        INTEGER(i4), INTENT(OUT) :: total_errors
        INTEGER(i4), INTENT(OUT) :: total_warnings

        total_errors   = dp_error_count
        total_warnings = dp_warn_count
    END SUBROUTINE dp_get_error_stats

    SUBROUTINE dp_reset_error_stats(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        dp_error_count = 0
        dp_warn_count  = 0
        CALL init_error_status(dp_last_error)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_reset_error_stats

    SUBROUTINE dp_sync_class_type_to_structmempool(type_name, parent_type_name, field_descs, num_fields, status)
        CHARACTER(LEN=*), INTENT(IN) :: type_name
        CHARACTER(LEN=*), INTENT(IN) :: parent_type_name
        TYPE(ClassFieldDesc), INTENT(IN) :: field_descs(:)
        INTEGER(i4), INTENT(IN) :: num_fields
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: class_id, i
        INTEGER(i4) :: dims3(3)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: has_parent

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_sync_class_type_to_structmempool"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        has_parent = .FALSE.

        CALL register_class_def(TRIM(type_name), metadata="", class_id=class_id, status=local_status)
        IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_SMEM_EXISTS) THEN
            status = local_status
            RETURN
        END IF

        IF (local_status%status_code == IF_STATUS_SMEM_EXISTS) THEN
            status%status_code = IF_STATUS_OK
            status%message = "Class already exists in StructMemPool, skip resync"
            RETURN
        END IF

        DO i = 1, num_fields

            dims3 = [1, 0, 0]
            IF (field_descs(i)%rank >= 1) THEN
                dims3(1) = field_descs(i)%dims(1)
            END IF
            IF (field_descs(i)%rank >= 2) THEN
                dims3(2) = field_descs(i)%dims(2)
            END IF
            IF (field_descs(i)%rank >= 3) THEN
                dims3(3) = field_descs(i)%dims(3)
            END IF

            IF (field_descs(i)%data_type == IF_DATA_TYPE_CHAR) THEN
                CALL add_class_member(class_id, TRIM(field_descs(i)%field_name), field_descs(i)%data_type, &
                    dims3, char_len=field_descs(i)%elem_len, status=local_status)
            ELSE
                CALL add_class_member(class_id, TRIM(field_descs(i)%field_name), field_descs(i)%data_type, &
                    dims3, status=local_status)
            END IF

            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                RETURN
            END IF
        END DO

        CALL finalize_class_def(class_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        status%message = "Class type synchronized to StructMemPool successfully"
    END SUBROUTINE dp_sync_class_type_to_structmempool

    FUNCTION INT8_TO_STR(i8) RESULT(str)
        INTEGER(KIND=8), INTENT(IN) :: i8
        CHARACTER(LEN=30) :: str

        WRITE(str, '(I0)') i8
        str = TRIM(ADJUSTL(str))
    END FUNCTION INT8_TO_STR

    FUNCTION WRITE_INT(value) RESULT(str)
        INTEGER(i4), INTENT(IN) :: value
        CHARACTER(LEN=32) :: str

        WRITE(str, '(I0)') value
        str = TRIM(ADJUSTL(str))
    END FUNCTION WRITE_INT

    SUBROUTINE dp_init(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(KIND=8), PARAMETER :: IF_DP_TOTAL_MEM_BYTES   = 256*1024*1024
        INTEGER(KIND=8), PARAMETER :: IF_DP_UNIFIED_MEM_BYTES = 256*1024*1024

        CALL init_error_status(status)
        CALL init_error_status(dp_last_error)
        dp_error_count = 0
        dp_warn_count  = 0

        IF (dp_initialized) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL init_struct_mem_pool(status, max_blocks=256, total_mem=IF_DP_TOTAL_MEM_BYTES, unified_mem_size=IF_DP_UNIFIED_MEM_BYTES)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("DataPlatform", &
                "init_struct_mem_pool failed: "//TRIM(status%message))
            RETURN
        END IF

        CALL init_unstruct_mem_pool(status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("DataPlatform", &
                "init_unstruct_mem_pool failed: "//TRIM(status%message))
            RETURN
        END IF

        dp_initialized = .TRUE.
        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", "Data platform initialized")
    END SUBROUTINE dp_init

    SUBROUTINE dp_shutdown(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL destroy_unstruct_mem_pool(status)
        CALL destroy_struct_mem_pool(status)

        dp_initialized = .FALSE.
        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", "Data platform shutdown")
    END SUBROUTINE dp_shutdown

    SUBROUTINE dp_register_struct_array(var_name, dims, data_type, type_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dims(4)
        INTEGER(i4), INTENT(IN) :: data_type
        CHARACTER(LEN=*), INTENT(IN) :: type_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: dim_count, i
        INTEGER(i4) :: dims_local(4)
        LOGICAL :: is_struct_type, is_class_type
        LOGICAL :: type_found

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured array cannot be empty in dp_register_struct_array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

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
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_register_struct_array: dims must describe a 1-4D array with positive leading dimensions"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, dim_count
            IF (dims_local(i) <= 0) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "dp_register_struct_array: all active dimensions must be positive"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF
        END DO

        is_struct_type = (data_type == IF_DATA_TYPE_STRUCT)
        is_class_type  = (data_type == IF_DATA_TYPE_CLASS)

        IF ((is_struct_type .OR. is_class_type) .AND. LEN_TRIM(type_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_register_struct_array: type_name must be provided for STRUCT/CLASS arrays"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            elem_size = 4_8
        CASE (IF_DATA_TYPE_DP)
            elem_size = 8_8
        CASE (IF_DATA_TYPE_STRUCT)
            type_found = .FALSE.
            elem_size = 0_8
            DO i = 1, IF_MAX_STRUCT_TYPES
                IF (struct_type_registry(i)%is_used .AND. &
                    TRIM(struct_type_registry(i)%type_name) == TRIM(type_name)) THEN
                    elem_size = struct_type_registry(i)%elem_size
                    type_found = .TRUE.
                    EXIT
                END IF
            END DO
            IF (.NOT. type_found .OR. elem_size <= 0_8) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "dp_register_struct_array: STRUCT type not registered or has invalid elem_size"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF
        CASE (IF_DATA_TYPE_CLASS)
            type_found = .FALSE.
            elem_size = 0_8
            DO i = 1, IF_MAX_CLASS_TYPES
                IF (class_type_registry(i)%is_used .AND. &
                    TRIM(class_type_registry(i)%type_name) == TRIM(type_name)) THEN
                    elem_size = class_type_registry(i)%elem_size
                    type_found = .TRUE.
                    EXIT
                END IF
            END DO
            IF (.NOT. type_found .OR. elem_size <= 0_8) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "dp_register_struct_array: CLASS type not registered or has invalid elem_size"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF
        CASE DEFAULT
            status%status_code = IF_STATUS_UNSUPPORTED
            status%message = "dp_register_struct_array: data_type not supported in current implementation"
            CALL log_warn("DataPlatform", TRIM(status%message))
            RETURN
        END SELECT

        ! Ensure symbol table entry exists and is consistent
        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_NOT_FOUND) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_register_struct_array: "//TRIM(status%message))
            RETURN
        END IF

        IF (exists_in_sym) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists in symbol table"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(var_name)
        CALL register_variable(TRIM(var_name), TRIM(data_id), data_type, &
                               IF_STORAGE_TYPE_STRUCTURED, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_variable failed in dp_register_struct_array for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL struct_meta_create(TRIM(var_name), data_type, dims_local, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_register_struct_array for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Registered structured array via DataPlatform: var='"//TRIM(var_name)//"', data_type="//TRIM(INT_TO_STR(data_type))// &
            ", dims="//TRIM(INT_ARR_TO_STR(dims_local(1:dim_count)))// &
            ", elem_size="//TRIM(INT8_TO_STR(elem_size)))
    END SUBROUTINE dp_register_struct_array

    SUBROUTINE dp_register_unstruct(var_name, unstruct_type, attr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: unstruct_type
        TYPE(UnstructAttrType), INTENT(IN) :: attr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: sym_exists
        CHARACTER(LEN=64) :: data_id
        TYPE(UnstructMetaType) :: meta

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_register_unstruct"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for unstructured object cannot be empty in dp_register_unstruct"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        sym_exists = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "symbol_table_exists failed in dp_register_unstruct for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (sym_exists) THEN
            CALL get_variable_data_id(TRIM(var_name), data_id, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "get_variable_data_id failed in dp_register_unstruct for var='"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF
        ELSE
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), unstruct_type, &
                                   IF_STORAGE_TYPE_UNSTRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_register_unstruct for var='"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF
        END IF

        meta = UnstructMetaType()
        CALL unstruct_meta_create(TRIM(var_name), unstruct_type, attr, meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_UNSMETA_EXISTS) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "unstruct_meta_create failed in dp_register_unstruct for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Registered unstructured variable via DataPlatform: var='"//TRIM(var_name)// &
            "', unstruct_type="//TRIM(INT_TO_STR(unstruct_type)))
    END SUBROUTINE dp_register_unstruct

    SUBROUTINE dp_ensure_unstruct(var_name, unstruct_type, attr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: unstruct_type
        TYPE(UnstructAttrType), INTENT(IN) :: attr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: sym_exists
        CHARACTER(LEN=64) :: data_id
        INTEGER(i4) :: existing_data_type, existing_storage_type
        TYPE(UnstructMetaType) :: meta

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_ensure_unstruct"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for unstructured object cannot be empty in dp_ensure_unstruct"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        sym_exists = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "symbol_table_exists failed in dp_ensure_unstruct for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (sym_exists) THEN
            CALL find_variable(TRIM(var_name), data_id, existing_data_type, existing_storage_type, local_status, .FALSE.)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "find_variable failed in dp_ensure_unstruct for var='"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            IF (existing_storage_type /= IF_STORAGE_TYPE_UNSTRUCTURED) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "dp_ensure_unstruct: variable '"//TRIM(var_name)//"' exists with non-unstructured storage type"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF

            IF (existing_data_type /= unstruct_type) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "dp_ensure_unstruct: variable '"//TRIM(var_name)//"' exists with different unstructured type"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF

            meta = UnstructMetaType()
            CALL unstruct_meta_create(TRIM(var_name), unstruct_type, attr, meta, local_status)
            IF (local_status%status_code /= IF_STATUS_OK .AND. &
                local_status%status_code /= IF_STATUS_UNSMETA_EXISTS) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "unstruct_meta_create failed in dp_ensure_unstruct for var='"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "dp_ensure_unstruct: variable '"//TRIM(var_name)//"' already registered as unstructured type="// &
                TRIM(INT_TO_STR(unstruct_type))//", data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        CALL dp_register_unstruct(var_name, unstruct_type, attr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            ! dp_register_unstruct ???????????????????
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "dp_ensure_unstruct: registered new unstructured variable '"//TRIM(var_name)// &
            "' with unstructured type="//TRIM(INT_TO_STR(unstruct_type)))
    END SUBROUTINE dp_ensure_unstruct

    SUBROUTINE dp_register_struct_type(type_name, field_descs, num_fields, status)
        CHARACTER(LEN=*), INTENT(IN) :: type_name
        TYPE(StructFieldDesc), INTENT(IN) :: field_descs(:)
        INTEGER(i4), INTENT(IN) :: num_fields
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, target_idx
        LOGICAL :: found

        CALL init_error_status(status)

        IF (num_fields <= 0 .OR. num_fields > SIZE(field_descs)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_register_struct_type: num_fields out of range"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        found = .FALSE.
        target_idx = 0

        DO i = 1, IF_MAX_STRUCT_TYPES
            IF (struct_type_registry(i)%is_used .AND. &
                TRIM(struct_type_registry(i)%type_name) == TRIM(type_name)) THEN
                target_idx = i
                found = .TRUE.
                EXIT
            END IF
        END DO

        IF (.NOT. found) THEN
            DO i = 1, IF_MAX_STRUCT_TYPES
                IF (.NOT. struct_type_registry(i)%is_used) THEN
                    target_idx = i
                    EXIT
                END IF
            END DO
        END IF

        IF (target_idx == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_register_struct_type: registry capacity exceeded"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        struct_type_registry(target_idx)%type_name = ADJUSTL(type_name)
        struct_type_registry(target_idx)%num_fields = num_fields

        IF (ALLOCATED(struct_type_registry(target_idx)%fields)) THEN
            DEALLOCATE(struct_type_registry(target_idx)%fields)
        END IF
        ALLOCATE(struct_type_registry(target_idx)%fields(num_fields))
        struct_type_registry(target_idx)%fields(:) = field_descs(1:num_fields)

        ! Compute element size from field descriptors (record length in bytes)
        struct_type_registry(target_idx)%elem_size = 0_8
        DO i = 1, num_fields
            SELECT CASE (field_descs(i)%data_type)
            CASE (IF_DATA_TYPE_INT)
                struct_type_registry(target_idx)%elem_size = MAX(struct_type_registry(target_idx)%elem_size, &
                    INT(field_descs(i)%offset_bytes, KIND=8) + 4_8)
            CASE (IF_DATA_TYPE_DP)
                struct_type_registry(target_idx)%elem_size = MAX(struct_type_registry(target_idx)%elem_size, &
                    INT(field_descs(i)%offset_bytes, KIND=8) + 8_8)
            CASE (IF_DATA_TYPE_CHAR)
                struct_type_registry(target_idx)%elem_size = MAX(struct_type_registry(target_idx)%elem_size, &
                    INT(field_descs(i)%offset_bytes, KIND=8) + INT(field_descs(i)%elem_len, KIND=8))
            CASE DEFAULT
                struct_type_registry(target_idx)%elem_size = MAX(struct_type_registry(target_idx)%elem_size, &
                    INT(field_descs(i)%offset_bytes, KIND=8) + INT(field_descs(i)%elem_len, KIND=8))
            END SELECT
        END DO

        struct_type_registry(target_idx)%is_used = .TRUE.

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Registered struct type '"//TRIM(type_name)//"' with "//&
            TRIM(INT_TO_STR(num_fields))//" fields")
    END SUBROUTINE dp_register_struct_type

    SUBROUTINE dp_register_class_type(type_name, parent_type_name, field_descs, num_fields, status)
        CHARACTER(LEN=*), INTENT(IN) :: type_name
        CHARACTER(LEN=*), INTENT(IN) :: parent_type_name
        TYPE(ClassFieldDesc), INTENT(IN) :: field_descs(:)
        INTEGER(i4), INTENT(IN) :: num_fields
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, target_idx
        LOGICAL :: found

        CALL init_error_status(status)

        IF (num_fields <= 0 .OR. num_fields > SIZE(field_descs)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_register_class_type: num_fields out of range"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        found = .FALSE.
        target_idx = 0

        DO i = 1, IF_MAX_CLASS_TYPES
            IF (class_type_registry(i)%is_used .AND. &
                TRIM(class_type_registry(i)%type_name) == TRIM(type_name)) THEN
                target_idx = i
                found = .TRUE.
                EXIT
            END IF
        END DO

        IF (.NOT. found) THEN
            DO i = 1, IF_MAX_CLASS_TYPES
                IF (.NOT. class_type_registry(i)%is_used) THEN
                    target_idx = i
                    EXIT
                END IF
            END DO
        END IF

        IF (target_idx == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_register_class_type: registry capacity exceeded"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        class_type_registry(target_idx)%type_name = ADJUSTL(type_name)
        class_type_registry(target_idx)%parent_type_name = ADJUSTL(parent_type_name)
        class_type_registry(target_idx)%num_fields = num_fields

        IF (ALLOCATED(class_type_registry(target_idx)%fields)) THEN
            DEALLOCATE(class_type_registry(target_idx)%fields)
        END IF
        ALLOCATE(class_type_registry(target_idx)%fields(num_fields))
        class_type_registry(target_idx)%fields(:) = field_descs(1:num_fields)

        ! Compute element size from field descriptors (record length in bytes)
        class_type_registry(target_idx)%elem_size = 0_8
        DO i = 1, num_fields
            SELECT CASE (field_descs(i)%data_type)
            CASE (IF_DATA_TYPE_INT)
                class_type_registry(target_idx)%elem_size = MAX(class_type_registry(target_idx)%elem_size, &
                    INT(field_descs(i)%offset_bytes, KIND=8) + 4_8)
            CASE (IF_DATA_TYPE_DP)
                class_type_registry(target_idx)%elem_size = MAX(class_type_registry(target_idx)%elem_size, &
                    INT(field_descs(i)%offset_bytes, KIND=8) + 8_8)
            CASE (IF_DATA_TYPE_CHAR)
                class_type_registry(target_idx)%elem_size = MAX(class_type_registry(target_idx)%elem_size, &
                    INT(field_descs(i)%offset_bytes, KIND=8) + INT(field_descs(i)%elem_len, KIND=8))
            CASE DEFAULT
                class_type_registry(target_idx)%elem_size = MAX(class_type_registry(target_idx)%elem_size, &
                    INT(field_descs(i)%offset_bytes, KIND=8) + INT(field_descs(i)%elem_len, KIND=8))
            END SELECT
        END DO

        class_type_registry(target_idx)%is_used = .TRUE.

        ! Synchronize class definition to StructMemPool so that alloc_class/alloc_class_array can find it
        CALL dp_sync_class_type_to_structmempool(type_name, parent_type_name, field_descs, num_fields, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("DataPlatform", &
                "dp_sync_class_type_to_structmempool failed for class '"//TRIM(type_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Registered class type '"//TRIM(type_name)//"' (parent='"//TRIM(parent_type_name)//"') with "//&
            TRIM(INT_TO_STR(num_fields))//" fields and synchronized to StructMemPool")
    END SUBROUTINE dp_register_class_type

    ! Internal helper: pack CLASS array into binary records based on StructMetaType and memory pool block
    SUBROUTINE dp_internal_pack_class_array_to_records(var_name, struct_meta, data_id, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(StructMetaType), INTENT(IN) :: struct_meta
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: block_id
        TYPE(StructMemBlockType) :: mem_block
        TYPE(C_PTR) :: base_cptr
        INTEGER(KIND=8) :: total_bytes, elem_size_8, offset_8
        INTEGER(KIND=8) :: i8
        INTEGER(i4) :: elem_count, i
        CHARACTER(LEN=1), POINTER :: raw_bytes(:)
        CHARACTER(LEN=256) :: log_msg
        CHARACTER(LEN=32) :: elem_size_str
        INTEGER(i4) :: unit_id

        CALL init_error_status(status)

        ! Only support 1D CLASS array here as a first-step sketch
        IF (struct_meta%valid_dim_count /= 1) THEN
            status%status_code = IF_STATUS_UNSUPPORTED
            status%message = "dp_internal_pack_class_array_to_records: only 1D CLASS arrays are supported in sketch implementation"
            CALL log_warn("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        elem_count = struct_meta%dimensions(1)
        IF (elem_count <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_internal_pack_class_array_to_records: element count must be positive"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        ! Locate CLASS memory block in StructMemPool by data_id
        CALL get_class_block_id_by_data_id(TRIM(data_id), block_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_class_block_id_by_data_id failed in dp_internal_pack_class_array_to_records for var='"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL query_struct_mem_block(block_id, mem_block, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "query_struct_mem_block failed in dp_internal_pack_class_array_to_records for block_id="// &
                TRIM(INT_TO_STR(block_id))//": "//TRIM(status%message))
            RETURN
        END IF

        total_bytes = struct_meta%total_size
        IF (total_bytes <= 0_8) THEN
            status%status_code = IF_STATUS_SMEM_STRUCT_ERR
            status%message = "dp_internal_pack_class_array_to_records: total_size must be positive"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (MOD(total_bytes, INT(elem_count, KIND=8)) /= 0_8) THEN
            status%status_code = IF_STATUS_SMEM_STRUCT_ERR
            WRITE(status%message, '(A,I0,A,I0)') &
                "dp_internal_pack_class_array_to_records: total_size (bytes)=", INT(total_bytes), &
                " is not divisible by element count=", elem_count
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        elem_size_8 = struct_meta%element_size

        ! Map backing buffer to a 1D CHARACTER(1) array for raw byte access
        CALL get_struct_block_base_cptr(block_id, base_cptr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_block_base_cptr failed in dp_internal_pack_class_array_to_records for block_id="// &
                TRIM(INT_TO_STR(block_id))//": "//TRIM(status%message))
            RETURN
        END IF

        CALL C_F_POINTER(base_cptr, raw_bytes, [INT(total_bytes)])

        ! Open target file as unformatted binary and write element by element
        ! Each record here is the raw in-memory layout of a single CLASS element.
        ! To align exactly with pack_testclass_array's layout, you can instead map fields
        ! using ClassFieldDesc and pack into a fixed-length record (e.g. IF_SFM_CHAR_RECORD_LEN).

        unit_id = 99
        OPEN(UNIT=unit_id, FILE=TRIM(file_path), STATUS='REPLACE', ACCESS='SEQUENTIAL', FORM='UNFORMATTED', ACTION='WRITE')

        DO i = 1, elem_count
            offset_8 = (INT(i, KIND=8) - 1_8) * elem_size_8
            WRITE(unit_id) raw_bytes(INT(offset_8)+1 : INT(offset_8+elem_size_8))
        END DO

        CLOSE(unit_id)

        WRITE(elem_size_str, '(I0)') INT(elem_size_8)
        WRITE(log_msg, '(A,A,A,I0,A)') &
            "dp_internal_pack_class_array_to_records: wrote CLASS array '", TRIM(var_name), &
            "' as ", elem_count, " binary records of size "//TRIM(elem_size_str)//" bytes"
        CALL log_info("DataPlatform", TRIM(log_msg))

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_internal_pack_class_array_to_records

    SUBROUTINE dp_plan_rebalance(logical_id, target_nodes, plan, num_moves, status)
        CHARACTER(LEN=*), INTENT(IN) :: logical_id
        INTEGER(i4), INTENT(IN) :: target_nodes(:)
        TYPE(ShardMovePlan), ALLOCATABLE, INTENT(OUT) :: plan(:)
        INTEGER(i4), INTENT(OUT) :: num_moves
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(GenericChunkMetaType), ALLOCATABLE :: chunks(:)
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: shard_count, i, num_targets, desired_index, alloc_status
        INTEGER(i4) :: desired_node

        CALL init_error_status(status)
        num_moves = 0
        IF (ALLOCATED(plan)) DEALLOCATE(plan)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_plan_rebalance"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (SIZE(target_nodes) <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_plan_rebalance: target_nodes must have at least one entry"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL dp_get_shards(TRIM(logical_id), chunks, shard_count, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
            RETURN
        END IF

        IF (shard_count <= 0) THEN
            IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        num_targets = SIZE(target_nodes)
        num_moves = 0

        DO i = 1, shard_count
            desired_index = MOD(i-1, num_targets) + 1
            desired_node = target_nodes(desired_index)
            IF (chunks(i)%node_id /= desired_node) THEN
                num_moves = num_moves + 1
            END IF
        END DO

        IF (num_moves <= 0) THEN
            IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(plan(num_moves), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Allocation failed in dp_plan_rebalance"
            CALL log_error("DataPlatform", TRIM(status%message))
            IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
            RETURN
        END IF

        num_moves = 0
        DO i = 1, shard_count
            desired_index = MOD(i-1, num_targets) + 1
            desired_node = target_nodes(desired_index)

            IF (chunks(i)%node_id /= desired_node) THEN
                num_moves = num_moves + 1
                plan(num_moves)%logical_id = TRIM(chunks(i)%logical_id)
                plan(num_moves)%file_path  = TRIM(chunks(i)%file_path)
                plan(num_moves)%chunk_id   = chunks(i)%chunk_id
                plan(num_moves)%from_node  = chunks(i)%node_id
                plan(num_moves)%to_node    = desired_node
            END IF
        END DO

        IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_plan_rebalance

    SUBROUTINE dp_save(var_name, file_path, format, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(IN) :: format
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType)   :: struct_meta
        TYPE(UnstructMetaType) :: unstruct_meta
        LOGICAL :: has_struct_meta, has_unstruct_meta
        INTEGER(i4) :: crc32_value
        INTEGER(KIND=8) :: crc32_value_8
        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        TYPE(FileHandleType) :: file_handle
        TYPE(DataBlockType) :: data_block
        CHARACTER(LEN=256) :: path_trim
        CHARACTER(LEN=16)  :: file_ext
        INTEGER(i4) :: last_dot, path_len

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL dp_get_meta(var_name, struct_meta, unstruct_meta, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("DataPlatform", &
                "dp_get_meta failed in dp_save: "//TRIM(status%message))
            RETURN
        END IF

        has_struct_meta   = struct_meta%is_valid
        has_unstruct_meta = unstruct_meta%is_valid

        IF (.NOT. has_struct_meta .AND. .NOT. has_unstruct_meta) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Metadata for variable '"//TRIM(var_name)//"' is not valid"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (has_struct_meta) THEN
            data_id = TRIM(struct_meta%data_id)

            ! Special handling: CLASS-type structured arrays can be packed to binary records
            IF (struct_meta%data_type == IF_DATA_TYPE_CLASS .AND. &
                (format == IF_DP_FORMAT_BINARY)) THEN
                CALL dp_internal_pack_class_array_to_records(TRIM(var_name), struct_meta, TRIM(data_id), &
                    TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "dp_internal_pack_class_array_to_records failed in dp_save for variable '"// &
                        TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF

                CALL dp_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "CRC calculation failed in dp_save for CLASS variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF

                CALL struct_meta_update(TRIM(data_id), 1, INT(crc32_value, KIND=8), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "struct_meta_update(CRC32) failed in dp_save for CLASS data_id='"// &
                        TRIM(data_id)//"': "//TRIM(status%message))
                    RETURN
                END IF

                status%status_code = IF_STATUS_OK
                CALL log_info("DataPlatform", &
                    "Saved CLASS structured variable '"//TRIM(var_name)//"' to file '"// &
                    TRIM(file_path)//"' via internal pack helper")
                RETURN
            END IF

            ! Determine file extension for structured path routing
            path_trim = TRIM(file_path)
            path_len = LEN_TRIM(path_trim)
            file_ext = ""
            last_dot = INDEX(path_trim(1:path_len), ".", .TRUE.)
            IF (last_dot > 0 .AND. last_dot < path_len) THEN
                file_ext = path_trim(last_dot+1:path_len)
            END IF

            ! Route based on extension: .dat/.inp/.csv -> StructFormatAdapters,
            ! otherwise keep existing .bin/.txt behavior.
            IF (file_ext == "dat" .OR. file_ext == "DAT") THEN
                CALL sfm_write_struct_dat(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_write_struct_dat failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE IF (file_ext == "inp" .OR. file_ext == "INP") THEN
                CALL sfm_write_struct_inp(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_write_struct_inp failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE IF (file_ext == "csv" .OR. file_ext == "CSV") THEN
                CALL sfm_write_struct_csv(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_write_struct_csv failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE
                CALL sfm_open_file(TRIM(file_path), "WRITE", &
                    MERGE("FORMATTED  ", "UNFORMATTED", format == IF_DP_FORMAT_TXT), file_handle, local_status)
                IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_open_file failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF

                data_block%data_id = data_id
                data_block%data_type = struct_meta%data_type
                data_block%dimensions = struct_meta%dimensions
                data_block%mem_size = struct_meta%total_size

                CALL sfm_write_data(file_handle, data_block, local_status, var_name=TRIM(var_name))
                CALL sfm_close_file(file_handle, local_status)

                IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_write_data/sfm_close_file failed in dp_save for variable '"// &
                        TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            END IF

            CALL dp_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "CRC calculation failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            CALL struct_meta_update(TRIM(data_id), 1, INT(crc32_value, KIND=8), local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "struct_meta_update(CRC32) failed in dp_save for data_id='"//TRIM(data_id)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Saved structured variable '"//TRIM(var_name)//"' to file '"//TRIM(file_path)//&
                "' and updated CRC32 in metadata")
            RETURN
        END IF

        IF (has_unstruct_meta) THEN
            data_id = TRIM(unstruct_meta%data_id)

            path_trim = TRIM(file_path)
            path_len  = LEN_TRIM(path_trim)
            file_ext  = ""
            last_dot  = INDEX(path_trim(1:path_len), ".", .TRUE.)
            IF (last_dot > 0 .AND. last_dot < path_len) THEN
                file_ext = path_trim(last_dot+1:path_len)
            END IF

            IF (file_ext == "dat" .OR. file_ext == "DAT") THEN
                CALL ufm_write_unstruct_dat(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "ufm_write_unstruct_dat failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE IF (file_ext == "inp" .OR. file_ext == "INP") THEN
                CALL ufm_write_unstruct_inp(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "ufm_write_unstruct_inp failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE IF (file_ext == "csv" .OR. file_ext == "CSV") THEN
                CALL ufm_write_unstruct_csv(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "ufm_write_unstruct_csv failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE
                CALL ufm_write_unstruct_data(TRIM(data_id), TRIM(file_path), format, local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "ufm_write_unstruct_data failed in dp_save for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            END IF

            CALL dp_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "CRC calculation failed in dp_save for unstructured variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            crc32_value_8 = ABS(INT(crc32_value, KIND=8))
            CALL unstruct_meta_update(TRIM(data_id), 4, crc32_value_8, status=local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "unstruct_meta_update(CRC32) failed in dp_save for data_id='"//TRIM(data_id)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Saved unstructured variable '"//TRIM(var_name)//"' to file '"//TRIM(file_path)//&
                "' and updated CRC32 in metadata")
            RETURN
        END IF
    END SUBROUTINE dp_save

    SUBROUTINE dp_load(var_name, file_path, format, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(IN) :: format
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType)   :: struct_meta
        TYPE(UnstructMetaType) :: unstruct_meta
        LOGICAL :: has_struct_meta, has_unstruct_meta
        CHARACTER(LEN=64) :: data_id, loaded_id
        TYPE(ErrorStatusType) :: local_status
        TYPE(FileHandleType) :: file_handle
        TYPE(DataBlockType) :: data_block
        INTEGER(i4) :: crc32_value
        INTEGER(KIND=8) :: crc32_value_8
        CHARACTER(LEN=256) :: path_trim
        CHARACTER(LEN=16)  :: file_ext
        INTEGER(i4) :: last_dot, path_len

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL dp_get_meta(var_name, struct_meta, unstruct_meta, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            ! If metadata is missing, try to rebuild unstructured object and metadata from file
            IF (status%status_code == IF_STATUS_INVALID .AND. dp_initialized) THEN
                CALL dp_rebuild_unstruct_from_file(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code == IF_STATUS_OK) THEN
                    status = local_status
                    RETURN
                END IF
                status = local_status
            END IF

            CALL log_error("DataPlatform", &
                "dp_get_meta failed in dp_load: "//TRIM(status%message))
            RETURN
        END IF

        has_struct_meta   = struct_meta%is_valid
        has_unstruct_meta = unstruct_meta%is_valid

        IF (.NOT. has_struct_meta .AND. .NOT. has_unstruct_meta) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Metadata for variable '"//TRIM(var_name)//"' is not valid"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (has_struct_meta) THEN
            data_id = TRIM(struct_meta%data_id)

            ! Special handling: CLASS-type structured arrays can be packed to binary records
            IF (struct_meta%data_type == IF_DATA_TYPE_CLASS .AND. &
                (format == IF_DP_FORMAT_BINARY)) THEN
                CALL dp_internal_pack_class_array_to_records(TRIM(var_name), struct_meta, TRIM(data_id), &
                    TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "dp_internal_pack_class_array_to_records failed in dp_save for variable '"// &
                        TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF

                CALL dp_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "CRC calculation failed in dp_save for CLASS variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF

                CALL struct_meta_update(TRIM(data_id), 1, INT(crc32_value, KIND=8), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "struct_meta_update(CRC32) failed in dp_save for CLASS data_id='"// &
                        TRIM(data_id)//"': "//TRIM(status%message))
                    RETURN
                END IF

                status%status_code = IF_STATUS_OK
                CALL log_info("DataPlatform", &
                    "Saved CLASS structured variable '"//TRIM(var_name)//"' to file '"// &
                    TRIM(file_path)//"' via internal pack helper")
                RETURN
            END IF

            ! Determine file extension for structured path routing
            path_trim = TRIM(file_path)
            path_len = LEN_TRIM(path_trim)
            file_ext = ""
            last_dot = INDEX(path_trim(1:path_len), ".", .TRUE.)
            IF (last_dot > 0 .AND. last_dot < path_len) THEN
                file_ext = path_trim(last_dot+1:path_len)
            END IF

            ! Route based on extension: .dat/.inp/.csv -> StructFormatAdapters,
            ! otherwise keep existing .bin/.txt behavior.
            IF (file_ext == "dat" .OR. file_ext == "DAT") THEN
                CALL sfm_read_struct_dat(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_read_struct_dat failed in dp_load for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE IF (file_ext == "inp" .OR. file_ext == "INP") THEN
                CALL sfm_read_struct_inp(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_read_struct_inp failed in dp_load for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE IF (file_ext == "csv" .OR. file_ext == "CSV") THEN
                CALL sfm_read_struct_csv(TRIM(var_name), TRIM(file_path), local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_read_struct_csv failed in dp_load for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            ELSE
                CALL sfm_open_file(TRIM(file_path), "READ", &
                    MERGE("FORMATTED  ", "UNFORMATTED", format == IF_DP_FORMAT_TXT), file_handle, local_status)
                IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_open_file failed in dp_load for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF

                CALL sfm_read_data(var_name=TRIM(var_name), file_handle=file_handle, &
                    data_block=data_block, error=local_status)
                CALL sfm_close_file(file_handle, local_status)

                IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "sfm_read_data/sfm_close_file failed in dp_load for variable '"// &
                        TRIM(var_name)//"': "//TRIM(status%message))
                    RETURN
                END IF
            END IF

            CALL dp_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "CRC calculation failed in dp_load for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            CALL struct_meta_update(TRIM(data_id), 1, INT(crc32_value, KIND=8), local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "struct_meta_update(CRC32) failed in dp_load for data_id='"//TRIM(data_id)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Loaded structured variable '"//TRIM(var_name)//"' from file '"//TRIM(file_path)//&
                "' and refreshed CRC32 in metadata")
            RETURN
        END IF

        IF (has_unstruct_meta) THEN
            data_id = TRIM(unstruct_meta%data_id)

            path_trim = TRIM(file_path)
            path_len = LEN_TRIM(path_trim)
            file_ext = ""
            last_dot = INDEX(path_trim(1:path_len), ".", .TRUE.)
            IF (last_dot > 0 .AND. last_dot < path_len) THEN
                file_ext = path_trim(last_dot+1:path_len)
            END IF

            IF (file_ext == "dat" .OR. file_ext == "DAT") THEN
                CALL ufm_load_unstruct_dat(TRIM(var_name), TRIM(file_path), local_status, loaded_id)
            ELSE IF (file_ext == "inp" .OR. file_ext == "INP") THEN
                CALL ufm_load_unstruct_inp(TRIM(var_name), TRIM(file_path), local_status, loaded_id)
            ELSE IF (file_ext == "csv" .OR. file_ext == "CSV") THEN
                CALL ufm_load_unstruct_csv(TRIM(var_name), TRIM(file_path), local_status, loaded_id)
            ELSE
                CALL ufm_load_unstruct_data(TRIM(file_path), loaded_id, local_status)
            END IF

            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "Unstructured load failed in dp_load for file '"//TRIM(file_path)//"': "//TRIM(status%message))
                RETURN
            END IF

            IF (TRIM(loaded_id) /= TRIM(data_id)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Data ID mismatch in dp_load for unstructured variable '"//TRIM(var_name)//"'"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF

            CALL dp_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "CRC calculation failed in dp_load for unstructured variable '"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            crc32_value_8 = ABS(INT(crc32_value, KIND=8))
            CALL unstruct_meta_update(TRIM(data_id), 4, crc32_value_8, status=local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "unstruct_meta_update(CRC32) failed in dp_load for data_id='"//TRIM(data_id)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Loaded unstructured variable '"//TRIM(var_name)//"' from file '"//TRIM(file_path)//&
                "' and refreshed CRC32 in metadata")
            RETURN
        END IF
    END SUBROUTINE dp_load

    SUBROUTINE dp_get_shards(logical_id, chunks, count, status)
        CHARACTER(LEN=*), INTENT(IN) :: logical_id
        TYPE(GenericChunkMetaType), ALLOCATABLE, INTENT(OUT) :: chunks(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: gstatus

        CALL init_error_status(status)
        count = 0
        IF (ALLOCATED(chunks)) DEALLOCATE(chunks)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_get_shards"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL gcm_get_chunks(TRIM(logical_id), chunks, count, gstatus)

        IF (gstatus%status_code /= IF_STATUS_OK) THEN
            IF (gstatus%status_code == IF_STATUS_NOT_FOUND) THEN
                status%status_code = IF_STATUS_OK
                count = 0
                IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
                RETURN
            ELSE
                status = gstatus
                CALL log_error("DataPlatform", &
                    "gcm_get_chunks failed in dp_get_shards: "//TRIM(gstatus%message))
                IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
                RETURN
            END IF
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_shards

    SUBROUTINE dp_get_shards_by_node(logical_id, node_id, chunks, count, status)
        CHARACTER(LEN=*), INTENT(IN) :: logical_id
        INTEGER(i4), INTENT(IN) :: node_id
        TYPE(GenericChunkMetaType), ALLOCATABLE, INTENT(OUT) :: chunks(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(GenericChunkMetaType), ALLOCATABLE :: all_chunks(:)
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: i, match_count, alloc_status

        CALL init_error_status(status)
        count = 0
        IF (ALLOCATED(chunks)) DEALLOCATE(chunks)

        CALL dp_get_shards(TRIM(logical_id), all_chunks, match_count, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
            RETURN
        END IF

        IF (match_count <= 0) THEN
            IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        count = 0
        DO i = 1, match_count
            IF (all_chunks(i)%node_id == node_id) THEN
                count = count + 1
            END IF
        END DO

        IF (count <= 0) THEN
            IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(chunks(count), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Allocation failed in dp_get_shards_by_node"
            CALL log_error("DataPlatform", TRIM(status%message))
            IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
            RETURN
        END IF

        count = 0
        DO i = 1, match_count
            IF (all_chunks(i)%node_id == node_id) THEN
                count = count + 1
                chunks(count) = all_chunks(i)
            END IF
        END DO

        IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_shards_by_node

    SUBROUTINE dp_get_shards_for_file(logical_id, file_path, chunks, count, status)
        CHARACTER(LEN=*), INTENT(IN) :: logical_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(GenericChunkMetaType), ALLOCATABLE, INTENT(OUT) :: chunks(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(GenericChunkMetaType), ALLOCATABLE :: all_chunks(:)
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: i, match_count, alloc_status

        CALL init_error_status(status)
        count = 0
        IF (ALLOCATED(chunks)) DEALLOCATE(chunks)

        CALL dp_get_shards(TRIM(logical_id), all_chunks, match_count, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
            RETURN
        END IF

        IF (match_count <= 0) THEN
            IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        count = 0
        DO i = 1, match_count
            IF (TRIM(all_chunks(i)%file_path) == TRIM(file_path)) THEN
                count = count + 1
            END IF
        END DO

        IF (count <= 0) THEN
            IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(chunks(count), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Allocation failed in dp_get_shards_for_file"
            CALL log_error("DataPlatform", TRIM(status%message))
            IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
            RETURN
        END IF

        count = 0
        DO i = 1, match_count
            IF (TRIM(all_chunks(i)%file_path) == TRIM(file_path)) THEN
                count = count + 1
                chunks(count) = all_chunks(i)
            END IF
        END DO

        IF (ALLOCATED(all_chunks)) DEALLOCATE(all_chunks)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_shards_for_file

    SUBROUTINE dp_rebuild_unstruct_from_file(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        CHARACTER(LEN=64) :: loaded_id
        CHARACTER(LEN=256) :: path_trim
        CHARACTER(LEN=16)  :: file_ext
        INTEGER(i4) :: last_dot, path_len
        INTEGER(i4) :: unstruct_type, device_id
        INTEGER(KIND=8) :: mem_size
        LOGICAL :: sym_exists
        CHARACTER(LEN=64) :: existing_id
        TYPE(UnstructAttrType) :: init_attr
        TYPE(UnstructMetaType) :: meta
        INTEGER(i4) :: crc32_value
        INTEGER(KIND=8) :: crc32_value_8

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_rebuild_unstruct_from_file"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        path_trim = TRIM(file_path)
        path_len = LEN_TRIM(path_trim)
        file_ext = ""
        last_dot = INDEX(path_trim(1:path_len), ".", .TRUE.)
        IF (last_dot > 0 .AND. last_dot < path_len) THEN
            file_ext = path_trim(last_dot+1:path_len)
        END IF

        IF (file_ext == "dat" .OR. file_ext == "DAT") THEN
            CALL ufm_load_unstruct_dat(TRIM(var_name), TRIM(file_path), local_status, loaded_id)
        ELSE IF (file_ext == "inp" .OR. file_ext == "INP") THEN
            CALL ufm_load_unstruct_inp(TRIM(var_name), TRIM(file_path), local_status, loaded_id)
        ELSE IF (file_ext == "csv" .OR. file_ext == "CSV") THEN
            CALL ufm_load_unstruct_csv(TRIM(var_name), TRIM(file_path), local_status, loaded_id)
        ELSE
            CALL ufm_load_unstruct_data(TRIM(file_path), loaded_id, local_status)
        END IF

        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_rebuild_unstruct_from_file: load failed for file '"//TRIM(file_path)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_unstruct_data_info(TRIM(loaded_id), unstruct_type, device_id, mem_size, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_rebuild_unstruct_from_file: get_unstruct_data_info failed for data_id='"// &
                TRIM(loaded_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        sym_exists = symbol_table_exists(TRIM(var_name), local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_rebuild_unstruct_from_file: symbol_table_exists failed for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. sym_exists) THEN
            CALL register_variable(TRIM(var_name), TRIM(loaded_id), unstruct_type, &
                                   IF_STORAGE_TYPE_UNSTRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "dp_rebuild_unstruct_from_file: register_variable failed for var='"// &
                    TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF
        ELSE
            CALL get_variable_data_id(TRIM(var_name), existing_id, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "dp_rebuild_unstruct_from_file: get_variable_data_id failed for var='"// &
                    TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            IF (TRIM(existing_id) /= TRIM(loaded_id)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "dp_rebuild_unstruct_from_file: data_id mismatch for existing variable '"//TRIM(var_name)//"'"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF
        END IF

        init_attr = UnstructAttrType()
        CALL unstruct_meta_create(TRIM(var_name), unstruct_type, init_attr, meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_UNSMETA_EXISTS) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_rebuild_unstruct_from_file: unstruct_meta_create failed for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL dp_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_rebuild_unstruct_from_file: CRC calculation failed for file '"//TRIM(file_path)//"': "//TRIM(status%message))
            RETURN
        END IF

        crc32_value_8 = ABS(INT(crc32_value, KIND=8))
        CALL unstruct_meta_update(TRIM(loaded_id), 4, crc32_value_8, status=local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_rebuild_unstruct_from_file: unstruct_meta_update(CRC32) failed for data_id='"// &
                TRIM(loaded_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Rebuilt unstructured variable '"//TRIM(var_name)//"' from file '"//TRIM(file_path)//"' and recreated metadata")
    END SUBROUTINE dp_rebuild_unstruct_from_file

    SUBROUTINE dp_get_meta(var_name, struct_meta, unstruct_meta, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        TYPE(StructMetaType),   INTENT(OUT) :: struct_meta
        TYPE(UnstructMetaType), INTENT(OUT) :: unstruct_meta
        TYPE(ErrorStatusType),  INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType)   :: local_struct_meta
        TYPE(UnstructMetaType) :: local_unstruct_meta
        LOGICAL :: has_struct_meta, has_unstruct_meta

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_get_meta: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' not registered in symbol table"
            CALL log_warn("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Failed to get data ID for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL struct_meta_try_query(TRIM(data_id), 1, local_struct_meta, has_struct_meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_META_NOT_FOUND) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_try_query failed in dp_get_meta for var '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (has_struct_meta) THEN
            struct_meta = local_struct_meta

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Got structured metadata for variable '"//TRIM(var_name)//"'")
            RETURN
        END IF

        CALL unstruct_meta_try_query(TRIM(data_id), 1, local_unstruct_meta, has_unstruct_meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_UNSMETA_NOT_FOUND) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "unstruct_meta_try_query failed in dp_get_meta for var '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (has_unstruct_meta) THEN
            unstruct_meta = local_unstruct_meta
            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Got unstructured metadata for variable '"//TRIM(var_name)//"'")
            RETURN
        END IF

        status%status_code = IF_STATUS_INVALID
        status%message = "No structured or unstructured metadata found for variable '"//TRIM(var_name)//"'"
        CALL log_error("DataPlatform", TRIM(status%message))
    END SUBROUTINE dp_get_meta

    SUBROUTINE dp_validate(var_name, status, current_crc32, file_path)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER, INTENT(IN), OPTIONAL :: current_crc32
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: file_path

        INTEGER(i4) :: file_crc32

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        ! --------------------------------------------------------------------
        ! Path 1: ???????CRC????????
        ! --------------------------------------------------------------------
        IF (PRESENT(current_crc32)) THEN
            CALL dp_validate_crc(var_name, current_crc32, status)
            RETURN
        END IF

        ! --------------------------------------------------------------------
        ! Path 2: ?????????DataPlatform ?????CRC ???
        ! --------------------------------------------------------------------
        IF (PRESENT(file_path)) THEN
            CALL dp_calculate_file_crc32(TRIM(file_path), file_crc32, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("DataPlatform", &
                    "File CRC calculation failed in dp_validate: "//TRIM(status%message))
                RETURN
            END IF

            CALL dp_validate_crc(var_name, file_crc32, status)
            RETURN
        END IF

        ! --------------------------------------------------------------------
        ! Path 3: ????????????????????
        ! --------------------------------------------------------------------
        CALL dp_validate_crc(var_name, -1, status)
    END SUBROUTINE dp_validate

    SUBROUTINE dp_get_struct_handle(var_name, data_id, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        CHARACTER(LEN=*), INTENT(OUT) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        TYPE(StructMetaType) :: struct_meta

        CALL init_error_status(status)
        data_id = ""

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_get_struct_handle: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' not registered in symbol table"
            CALL log_warn("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Failed to get data ID for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL struct_meta_query(TRIM(var_name), 2, struct_meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Structured metadata not found or invalid for variable '"//TRIM(var_name)//"'"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Resolved structured handle for variable '"//TRIM(var_name)//"' (data_id='"//TRIM(data_id)//"')")
    END SUBROUTINE dp_get_struct_handle

    SUBROUTINE dp_get_struct_ptr(var_name, ptr, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        CLASS(*), POINTER, INTENT(OUT) :: ptr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: block_id

        CALL init_error_status(status)
        NULLIFY(ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL dp_get_struct_handle(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_get_struct_handle failed in dp_get_struct_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_block_id_by_data_id(TRIM(data_id), block_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_block_id_by_data_id failed in dp_get_struct_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_ptr(block_id, ptr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_ptr failed in dp_get_struct_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Resolved STRUCT pointer for variable '"//TRIM(var_name)//"' (data_id='"//TRIM(data_id)//&
            "', block_id="//TRIM(INT_TO_STR(block_id))//")")
    END SUBROUTINE dp_get_struct_ptr

    SUBROUTINE dp_get_class_ptr(var_name, ptr, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        CLASS(*), POINTER, INTENT(OUT) :: ptr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: block_id

        CALL init_error_status(status)
        NULLIFY(ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL dp_get_struct_handle(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_get_struct_handle failed in dp_get_class_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_class_block_id_by_data_id(TRIM(data_id), block_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_class_block_id_by_data_id failed in dp_get_class_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_class_ptr(block_id, ptr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_class_ptr failed in dp_get_class_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Resolved CLASS pointer for variable '"//TRIM(var_name)//"' (data_id='"//TRIM(data_id)//&
            "', block_id="//TRIM(INT_TO_STR(block_id))//")")
    END SUBROUTINE dp_get_class_ptr

    SUBROUTINE dp_get_struct_element_ptr(var_name, elem_index, ptr, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        INTEGER(i4), INTENT(IN) :: elem_index
        CLASS(*), POINTER, INTENT(OUT) :: ptr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: block_id

        CALL init_error_status(status)
        NULLIFY(ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (elem_index <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Element index must be positive in dp_get_struct_element_ptr"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL dp_get_struct_handle(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_get_struct_handle failed in dp_get_struct_element_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_block_id_by_data_id(TRIM(data_id), block_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_block_id_by_data_id failed in dp_get_struct_element_ptr for var='"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_element_ptr(block_id, elem_index, ptr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_element_ptr failed in dp_get_struct_element_ptr for var='"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Resolved STRUCT element pointer for var='"//TRIM(var_name)//"', idx="//TRIM(INT_TO_STR(elem_index))// &
            " (data_id='"//TRIM(data_id)//"', block_id="//TRIM(INT_TO_STR(block_id))//")")
    END SUBROUTINE dp_get_struct_element_ptr

    SUBROUTINE dp_get_struct_element_cptr(var_name, elem_index, cptr, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        INTEGER(i4), INTENT(IN) :: elem_index
        TYPE(C_PTR),      INTENT(OUT) :: cptr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: block_id

        CALL init_error_status(status)
        cptr = C_NULL_PTR

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (elem_index <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Element index must be positive in dp_get_struct_element_cptr"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL dp_get_struct_handle(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_get_struct_handle failed in dp_get_struct_element_cptr for var='"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_block_id_by_data_id(TRIM(data_id), block_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_block_id_by_data_id failed in dp_get_struct_element_cptr for var='"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_element_cptr(block_id, elem_index, cptr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_element_cptr failed in dp_get_struct_element_cptr for var='"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Resolved STRUCT element C_PTR for var='"//TRIM(var_name)//"', idx="//TRIM(INT_TO_STR(elem_index))// &
            " (data_id='"//TRIM(data_id)//"', block_id="//TRIM(INT_TO_STR(block_id))//")")
    END SUBROUTINE dp_get_struct_element_cptr

    SUBROUTINE dp_get_class_element_ptr(var_name, elem_index, ptr, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        INTEGER(i4), INTENT(IN) :: elem_index
        CLASS(*), POINTER, INTENT(OUT) :: ptr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: block_id

        CALL init_error_status(status)
        NULLIFY(ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (elem_index <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Element index must be positive in dp_get_class_element_ptr"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL dp_get_struct_handle(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_get_struct_handle failed in dp_get_class_element_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_class_block_id_by_data_id(TRIM(data_id), block_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_class_block_id_by_data_id failed in dp_get_class_element_ptr for var='"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_class_element_ptr(block_id, elem_index, ptr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_class_element_ptr failed in dp_get_class_element_ptr for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Resolved CLASS element pointer for var='"//TRIM(var_name)//"', idx="//TRIM(INT_TO_STR(elem_index))// &
            " (data_id='"//TRIM(data_id)//"', block_id="//TRIM(INT_TO_STR(block_id))//")")
    END SUBROUTINE dp_get_class_element_ptr

    SUBROUTINE dp_get_unstruct_handle(var_name, data_id, unstruct_type, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        CHARACTER(LEN=*), INTENT(OUT) :: data_id
        INTEGER(i4), INTENT(OUT) :: unstruct_type
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        INTEGER(i4) :: device_id
        INTEGER(KIND=8) :: mem_size

        CALL init_error_status(status)
        data_id = ""
        unstruct_type = 0

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_get_unstruct_handle: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' not registered in symbol table"
            CALL log_warn("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Failed to get data ID for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_unstruct_data_info(TRIM(data_id), unstruct_type, device_id, mem_size, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured data not found or invalid for data ID '"//TRIM(data_id)//"'"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Resolved unstructured handle for variable '"//TRIM(var_name)//"' (data_id='"//TRIM(data_id)//"')")
    END SUBROUTINE dp_get_unstruct_handle

    SUBROUTINE dp_dump_debug(var_name, unit, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: unit
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: meta_status
        TYPE(StructMetaType)   :: struct_meta
        TYPE(UnstructMetaType) :: unstruct_meta
        LOGICAL :: has_struct, has_unstruct
        CHARACTER(LEN=64) :: data_id
        INTEGER(i4) :: dims(4)
        CHARACTER(LEN=32) :: dtype_str
        CHARACTER(LEN=32) :: utype_str
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: unstruct_type, device_id
        INTEGER(KIND=8) :: mem_size

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_dump_debug"
            CALL log_error("DataPlatform", TRIM(status%message))
            WRITE(unit, '(A)') "dp_dump_debug: Data platform not initialized"
            RETURN
        END IF

        CALL dp_get_meta(var_name, struct_meta, unstruct_meta, meta_status)
        IF (meta_status%status_code /= IF_STATUS_OK) THEN
            status = meta_status
            WRITE(unit, '(A,A)') "dp_dump_debug: dp_get_meta failed: ", TRIM(status%message)
            RETURN
        END IF

        has_struct   = struct_meta%is_valid
        has_unstruct = unstruct_meta%is_valid

        WRITE(unit, '(A)') "==== DataPlatform Debug Dump ===="
        WRITE(unit, '(A,A)') "Variable: ", TRIM(var_name)

        IF (has_struct) THEN
            data_id = TRIM(struct_meta%data_id)
            dims = struct_meta%dimensions

            SELECT CASE (struct_meta%data_type)
            CASE (IF_DATA_TYPE_INT)
                dtype_str = "INT"
            CASE (IF_DATA_TYPE_DP)
                dtype_str = "DP"
            CASE (IF_DATA_TYPE_CHAR)
                dtype_str = "CHAR"
            CASE (IF_DATA_TYPE_STRUCT)
                dtype_str = "STRUCT"
            CASE (IF_DATA_TYPE_CLASS)
                dtype_str = "CLASS"
            CASE DEFAULT
                dtype_str = "UNKNOWN"
            END SELECT

            WRITE(unit, '(A)') "Kind: STRUCTURED"
            WRITE(unit, '(A,A)') "  data_id: ", TRIM(data_id)
            WRITE(unit, '(A,A)') "  var_name: ", TRIM(struct_meta%var_name)
            WRITE(unit, '(A,A)') "  data_type: ", TRIM(dtype_str)
            WRITE(unit, '(A,4(I0,1X))') "  dims: ", dims(1), dims(2), dims(3), dims(4)
            WRITE(unit, '(A,I0)') "  total_elements: ", struct_meta%total_elements
            WRITE(unit, '(A,I0)') "  total_size(bytes): ", struct_meta%total_size
            WRITE(unit, '(A,I0)') "  crc32: ", struct_meta%crc32
            WRITE(unit, '(A,A)') "  create_time: ", TRIM(struct_meta%create_time)
            WRITE(unit, '(A,A)') "  update_time: ", TRIM(struct_meta%update_time)

        ELSE IF (has_unstruct) THEN
            data_id = TRIM(unstruct_meta%data_id)

            SELECT CASE (unstruct_meta%unstruct_type)
            CASE (UNSTRUCT_TYPE_HASH)
                utype_str = "HashTable"
            CASE (UNSTRUCT_TYPE_LINKED_LIST)
                utype_str = "LinkedList"
            CASE (UNSTRUCT_TYPE_ADJACENCY)
                utype_str = "AdjacencyList"
            CASE (UNSTRUCT_TYPE_SKIP_LIST)
                utype_str = "SkipList"
            CASE (UNSTRUCT_TYPE_GRAPH)
                utype_str = "Graph"
            CASE (UNSTRUCT_TYPE_QUEUE)
                utype_str = "Queue"
            CASE DEFAULT
                utype_str = "Unknown"
            END SELECT

            WRITE(unit, '(A)') "Kind: UNSTRUCTURED"
            WRITE(unit, '(A,A)') "  data_id: ", TRIM(data_id)
            WRITE(unit, '(A,A)') "  var_name: ", TRIM(unstruct_meta%var_name)
            WRITE(unit, '(A,A)') "  unstruct_type: ", TRIM(utype_str)
            WRITE(unit, '(A,I0)') "  element_count: ", unstruct_meta%element_count
            WRITE(unit, '(A,I0)') "  total_size(bytes): ", unstruct_meta%total_size
            WRITE(unit, '(A,I0)') "  crc32: ", unstruct_meta%crc32
            WRITE(unit, '(A,A)') "  create_time: ", TRIM(unstruct_meta%create_time)
            WRITE(unit, '(A,A)') "  update_time: ", TRIM(unstruct_meta%update_time)

            CALL get_unstruct_data_info(TRIM(data_id), unstruct_type, device_id, mem_size, local_status)
            IF (local_status%status_code == IF_STATUS_OK) THEN
                WRITE(unit, '(A,I0)') "  device_id: ", device_id
                WRITE(unit, '(A,I0)') "  mem_size(bytes): ", mem_size
            END IF

        ELSE
            WRITE(unit, '(A)') "dp_dump_debug: no valid metadata found for variable"
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_dump_debug

    ! ------------------------------------------------------------------------
    ! High-level structured array creation APIs (Struct side, unified memory)
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_create_int_array1d(var_name, dim1, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1
        INTEGER,          POINTER, INTENT(OUT) :: array_ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured INT1D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dimension dim1 must be positive for INT1D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, 0, 0, 0]
        elem_size = INT(4, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_int_array1d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_INT, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_int_array1d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_INT, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_int_array1d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_INT, dims, 0, &
            "INT1D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_int_array1d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_1d_int(subarray_id, array_ptr, dim1_out, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_1d_int failed in dp_create_int_array1d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created INT1D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dim1="//TRIM(INT_TO_STR(dim1)))
    END SUBROUTINE dp_create_int_array1d

    SUBROUTINE dp_create_int_array2d(var_name, dim1, dim2, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2
        INTEGER,          POINTER, INTENT(OUT) :: array_ptr(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured INT2D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dimensions dim1 and dim2 must be positive for INT2D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, 0, 0]
        elem_size = INT(4, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_int_array2d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_INT, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_int_array2d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_INT, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_int_array2d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_INT, dims, 0, &
            "INT2D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_int_array2d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_2d_int(subarray_id, array_ptr, dim1_out, dim2_out, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_2d_int failed in dp_create_int_array2d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created INT2D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//")")
    END SUBROUTINE dp_create_int_array2d

    SUBROUTINE dp_create_dp_array1d(var_name, dim1, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1
        DOUBLE PRECISION, POINTER, INTENT(OUT) :: array_ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured DP1D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dimension dim1 must be positive for DP1D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, 0, 0, 0]
        elem_size = INT(8, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_dp_array1d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_DP, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_dp_array1d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_DP, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_dp_array1d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_DP, dims, 0, &
            "DP1D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_dp_array1d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_1d_dp(subarray_id, array_ptr, dim1_out, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_1d_dp failed in dp_create_dp_array1d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created DP1D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dim1="//TRIM(INT_TO_STR(dim1)))
    END SUBROUTINE dp_create_dp_array1d

    SUBROUTINE dp_create_dp_array2d(var_name, dim1, dim2, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2
        DOUBLE PRECISION, POINTER, INTENT(OUT) :: array_ptr(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured DP2D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dimensions dim1 and dim2 must be positive for DP2D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, 0, 0]
        elem_size = INT(8, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_dp_array2d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_DP, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_dp_array2d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_DP, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_dp_array2d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_DP, dims, 0, &
            "DP2D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_dp_array2d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_2d_dp(subarray_id, array_ptr, dim1_out, dim2_out, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_2d_dp failed in dp_create_dp_array2d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created DP2D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//")")
    END SUBROUTINE dp_create_dp_array2d

    SUBROUTINE dp_create_int_array3d(var_name, dim1, dim2, dim3, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3
        INTEGER,          POINTER, INTENT(OUT) :: array_ptr(:,:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out, dim3_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured INT3D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dimensions dim1, dim2 and dim3 must be positive for INT3D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, dim3, 0]
        elem_size = INT(4, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_int_array3d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_INT, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_int_array3d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_INT, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_int_array3d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_INT, dims, 0, &
            "INT3D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_int_array3d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_3d_int(subarray_id, array_ptr, dim1_out, dim2_out, dim3_out, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_3d_int failed in dp_create_int_array3d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created INT3D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//","//TRIM(INT_TO_STR(dim3))//")")
    END SUBROUTINE dp_create_int_array3d

    SUBROUTINE dp_create_int_array4d(var_name, dim1, dim2, dim3, dim4, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3, dim4
        INTEGER,          POINTER, INTENT(OUT) :: array_ptr(:,:,:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out, dim3_out, dim4_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured INT4D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0 .OR. dim4 <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dimensions dim1, dim2, dim3 and dim4 must be positive for INT4D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, dim3, dim4]
        elem_size = INT(4, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_int_array4d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_INT, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_int_array4d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_INT, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_int_array4d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_INT, dims, 0, &
            "INT4D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_int_array4d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_4d_int(subarray_id, array_ptr, dim1_out, dim2_out, dim3_out, dim4_out, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_4d_int failed in dp_create_int_array4d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created INT4D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//","// &
                TRIM(INT_TO_STR(dim3))//","//TRIM(INT_TO_STR(dim4))//")")
    END SUBROUTINE dp_create_int_array4d

    SUBROUTINE dp_create_dp_array3d(var_name, dim1, dim2, dim3, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3
        DOUBLE PRECISION, POINTER, INTENT(OUT) :: array_ptr(:,:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out, dim3_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured DP3D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dimensions dim1, dim2 and dim3 must be positive for DP3D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, dim3, 0]
        elem_size = INT(8, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_dp_array3d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_DP, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_dp_array3d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_DP, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_dp_array3d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_DP, dims, 0, &
            "DP3D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_dp_array3d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_3d_dp(subarray_id, array_ptr, dim1_out, dim2_out, dim3_out, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_3d_dp failed in dp_create_dp_array3d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created DP3D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//","//TRIM(INT_TO_STR(dim3))//")")
    END SUBROUTINE dp_create_dp_array3d

    SUBROUTINE dp_create_dp_array4d(var_name, dim1, dim2, dim3, dim4, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3, dim4
        DOUBLE PRECISION, POINTER, INTENT(OUT) :: array_ptr(:,:,:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out, dim3_out, dim4_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured DP4D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0 .OR. dim4 <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dimensions dim1, dim2, dim3 and dim4 must be positive for DP4D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, dim3, dim4]
        elem_size = INT(8, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_dp_array4d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_DP, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_dp_array4d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_DP, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_dp_array4d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_DP, dims, 0, &
            "DP4D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_dp_array4d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_4d_dp(subarray_id, array_ptr, dim1_out, dim2_out, dim3_out, dim4_out, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_4d_dp failed in dp_create_dp_array4d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created DP4D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//","// &
                TRIM(INT_TO_STR(dim3))//","//TRIM(INT_TO_STR(dim4))//")")
    END SUBROUTINE dp_create_dp_array4d

    SUBROUTINE dp_create_char_array1d(var_name, dim1, char_len, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, char_len
        CHARACTER(LEN=*), POINTER, INTENT(OUT) :: array_ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured CHAR1D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. char_len <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dim1 and char_len must be positive for CHAR1D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, 0, 0, 0]
        elem_size = INT(char_len, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_char_array1d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_CHAR, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_char_array1d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_CHAR, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_char_array1d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_CHAR, dims, char_len, &
            "CHAR1D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_char_array1d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_1d_char(subarray_id, array_ptr, dim1_out, local_char_len, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_1d_char failed in dp_create_char_array1d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created CHAR1D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dim1="//TRIM(INT_TO_STR(dim1)))
    END SUBROUTINE dp_create_char_array1d

    SUBROUTINE dp_create_char_array2d(var_name, dim1, dim2, char_len, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2, char_len
        CHARACTER(LEN=*), POINTER, INTENT(OUT) :: array_ptr(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured CHAR2D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0 .OR. char_len <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dim1, dim2 and char_len must be positive for CHAR2D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, 0, 0]
        elem_size = INT(char_len, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_char_array2d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_CHAR, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_char_array2d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_CHAR, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_char_array2d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_CHAR, dims, char_len, &
            "CHAR2D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_char_array2d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_2d_char(subarray_id, array_ptr, dim1_out, dim2_out, local_char_len, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_2d_char failed in dp_create_char_array2d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created CHAR2D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//")")
    END SUBROUTINE dp_create_char_array2d

    SUBROUTINE dp_create_char_array3d(var_name, dim1, dim2, dim3, char_len, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3, char_len
        CHARACTER(LEN=*), POINTER, INTENT(OUT) :: array_ptr(:,:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out, dim3_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured CHAR3D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0 .OR. char_len <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dim1, dim2, dim3 and char_len must be positive for CHAR3D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, dim3, 0]
        elem_size = INT(char_len, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_char_array3d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_CHAR, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_char_array3d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_CHAR, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_char_array3d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_CHAR, dims, char_len, &
            "CHAR3D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_char_array3d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_3d_char(subarray_id, array_ptr, dim1_out, dim2_out, dim3_out, local_char_len, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_3d_char failed in dp_create_char_array3d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created CHAR3D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//","//TRIM(INT_TO_STR(dim3))//")")
    END SUBROUTINE dp_create_char_array3d

    SUBROUTINE dp_create_char_array4d(var_name, dim1, dim2, dim3, dim4, char_len, array_ptr, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dim1, dim2, dim3, dim4, char_len
        CHARACTER(LEN=*), POINTER, INTENT(OUT) :: array_ptr(:,:,:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: dims(4)
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym
        CHARACTER(LEN=64) :: data_id
        TYPE(StructMetaType) :: meta
        INTEGER(i4) :: subarray_id
        INTEGER(i4) :: dim1_out, dim2_out, dim3_out, dim4_out
        INTEGER(KIND=8) :: elem_size
        INTEGER(i4) :: local_char_len

        CALL init_error_status(status)
        NULLIFY(array_ptr)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured CHAR4D array cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (dim1 <= 0 .OR. dim2 <= 0 .OR. dim3 <= 0 .OR. dim4 <= 0 .OR. char_len <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dim1, dim2, dim3, dim4 and char_len must be positive for CHAR4D array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dims = [dim1, dim2, dim3, dim4]
        elem_size = INT(char_len, KIND=8)

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_char_array4d: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            data_id = TRIM(var_name)
            CALL register_variable(TRIM(var_name), TRIM(data_id), IF_DATA_TYPE_CHAR, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_char_array4d: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL struct_meta_create(TRIM(var_name), IF_DATA_TYPE_CHAR, dims, elem_size, .FALSE., meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "struct_meta_create failed in dp_create_char_array4d: "//TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)

        CALL register_struct_subarray(TRIM(data_id), IF_DATA_TYPE_CHAR, dims, char_len, &
            "CHAR4D unified array for '"//TRIM(var_name)//"'", subarray_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "register_struct_subarray failed in dp_create_char_array4d: "//TRIM(status%message))
            RETURN
        END IF

        CALL get_struct_subarray_ptr_4d_char(subarray_id, array_ptr, dim1_out, dim2_out, dim3_out, dim4_out, &
            local_char_len, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_struct_subarray_ptr_4d_char failed in dp_create_char_array4d: "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created CHAR4D structured array via DataPlatform: var='"//TRIM(var_name)// &
            "', dims=("//TRIM(INT_TO_STR(dim1))//","//TRIM(INT_TO_STR(dim2))//","// &
                TRIM(INT_TO_STR(dim3))//","//TRIM(INT_TO_STR(dim4))//")")
    END SUBROUTINE dp_create_char_array4d

    SUBROUTINE dp_create_struct_array(var_name, dims, struct_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dims(4)
        CHARACTER(LEN=*), INTENT(IN) :: struct_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym, type_exists_in_sym
        CHARACTER(LEN=64) :: data_id_struct
        INTEGER(i4) :: block_id
        LOGICAL :: is_scalar

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured STRUCT instance cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(struct_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Struct type name cannot be empty in dp_create_struct_array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        is_scalar = (dims(1) == 1 .AND. dims(2) == 0 .AND. dims(3) == 0 .AND. dims(4) == 0)

        ! ????????????????????
        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_struct_array: "//TRIM(status%message))
            RETURN
        END IF

        IF (exists_in_sym) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists in symbol table"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (is_scalar) THEN
            ! ???????????????????????var_name ???????
            type_exists_in_sym = symbol_table_exists(struct_name, local_status)
            IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_NOT_FOUND) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "Symbol table check for struct type failed in dp_create_struct_array: "//TRIM(status%message))
                RETURN
            END IF

            IF (.NOT. type_exists_in_sym) THEN
                data_id_struct = TRIM(struct_name)
                CALL register_variable(TRIM(struct_name), TRIM(data_id_struct), IF_DATA_TYPE_STRUCT, &
                                       IF_STORAGE_TYPE_STRUCTURED, local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "register_variable failed for struct type in dp_create_struct_array: "//TRIM(status%message))
                    RETURN
                END IF
            END IF

            CALL alloc_struct(TRIM(struct_name), block_id, local_status, use_unified=.TRUE.)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "alloc_struct failed in dp_create_struct_array: "//TRIM(status%message))
                RETURN
            END IF

            CALL get_variable_data_id(struct_name, data_id_struct, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "get_variable_data_id failed for struct type in dp_create_struct_array: "//TRIM(status%message))
                RETURN
            END IF

            CALL register_variable(TRIM(var_name), TRIM(data_id_struct), IF_DATA_TYPE_STRUCT, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_struct_array for var='"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Created STRUCT instance via DataPlatform: var='"//TRIM(var_name)//"', struct_type='"//TRIM(struct_name)//"'")
        ELSE
            ! ?????????????alloc_struct_array???1-4 ???
            CALL alloc_struct_array(TRIM(var_name), TRIM(struct_name), dims, block_id, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "alloc_struct_array failed in dp_create_struct_array for var='"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Created STRUCT array via DataPlatform: var='"//TRIM(var_name)//"', struct_type='"//TRIM(struct_name)//"'")
        END IF
    END SUBROUTINE dp_create_struct_array

    SUBROUTINE dp_create_class_array(var_name, dims, class_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: dims(4)
        CHARACTER(LEN=*), INTENT(IN) :: class_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: exists_in_sym, type_exists_in_sym
        CHARACTER(LEN=64) :: data_id_class
        INTEGER(i4) :: block_id
        LOGICAL :: is_scalar

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for structured CLASS instance cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(class_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Class type name cannot be empty in dp_create_class_array"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        is_scalar = (dims(1) == 1 .AND. dims(2) == 0 .AND. dims(3) == 0 .AND. dims(4) == 0)

        ! ??????????
        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "Symbol table check failed in dp_create_class_array: "//TRIM(status%message))
            RETURN
        END IF

        IF (exists_in_sym) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' already exists in symbol table"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (is_scalar) THEN
            ! ???????????????????????var_name ???????
            type_exists_in_sym = symbol_table_exists(class_name, local_status)
            IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_NOT_FOUND) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "Symbol table check for class type failed in dp_create_class_array: "//TRIM(status%message))
                RETURN
            END IF

            IF (.NOT. type_exists_in_sym) THEN
                data_id_class = TRIM(class_name)
                CALL register_variable(TRIM(class_name), TRIM(data_id_class), IF_DATA_TYPE_CLASS, &
                                       IF_STORAGE_TYPE_STRUCTURED, local_status)
                IF (local_status%status_code /= IF_STATUS_OK) THEN
                    status = local_status
                    CALL log_error("DataPlatform", &
                        "register_variable failed for class type in dp_create_class_array: "//TRIM(status%message))
                    RETURN
                END IF
            END IF

            CALL alloc_class(TRIM(class_name), block_id, local_status, use_unified=.TRUE.)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "alloc_class failed in dp_create_class_array: "//TRIM(status%message))
                RETURN
            END IF

            CALL get_variable_data_id(class_name, data_id_class, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "get_variable_data_id failed for class type in dp_create_class_array: "//TRIM(status%message))
                RETURN
            END IF

            CALL register_variable(TRIM(var_name), TRIM(data_id_class), IF_DATA_TYPE_CLASS, &
                                   IF_STORAGE_TYPE_STRUCTURED, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "register_variable failed in dp_create_class_array for var='"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Created CLASS instance via DataPlatform: var='"//TRIM(var_name)//"', class_type='"//TRIM(class_name)//"'")
        ELSE
            ! ?????????????alloc_class_array???1-4 ???
            CALL alloc_class_array(TRIM(var_name), TRIM(class_name), dims, block_id, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status = local_status
                CALL log_error("DataPlatform", &
                    "alloc_class_array failed in dp_create_class_array for var='"//TRIM(var_name)//"': "//TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Created CLASS array via DataPlatform: var='"//TRIM(var_name)//"', class_type='"//TRIM(class_name)//"'")
        END IF
    END SUBROUTINE dp_create_class_array

    ! ------------------------------------------------------------------------
    ! High-level unstructured queue APIs
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_ensure_queue(var_name, capacity, is_circular, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: capacity
        LOGICAL,          INTENT(IN), OPTIONAL :: is_circular
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        TYPE(UnstructAttrType) :: attr
        TYPE(UnstructMetaType) :: meta
        LOGICAL :: circ
        LOGICAL :: meta_found
        CHARACTER(LEN=64) :: data_id
        CHARACTER(LEN=32) :: capacity_str

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_ensure_queue"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for queue cannot be empty in dp_ensure_queue"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (capacity < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Queue capacity must be positive in dp_ensure_queue"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        circ = .TRUE.
        IF (PRESENT(is_circular)) circ = is_circular

        attr = UnstructAttrType()
        attr%queue_capacity = capacity
        attr%queue_is_dynamic = .FALSE.

        CALL dp_ensure_unstruct(var_name, UNSTRUCT_TYPE_QUEUE, attr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        CALL unstruct_meta_try_query(TRIM(var_name), 2, meta, meta_found, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "unstruct_meta_try_query failed in dp_ensure_queue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. meta_found) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_ensure_queue: metadata not found after dp_ensure_unstruct for var='"//TRIM(var_name)//"'"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (meta%unstruct_type /= UNSTRUCT_TYPE_QUEUE) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_ensure_queue: variable '"//TRIM(var_name)//"' exists with non-queue unstructured type"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (meta%type_attr%queue_capacity < INT(capacity, KIND=8)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_ensure_queue: requested capacity exceeds existing queue capacity for var='"//TRIM(var_name)//"'"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        data_id = TRIM(meta%data_id)
        IF (LEN_TRIM(data_id) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_ensure_queue: empty data_id in metadata for var='"//TRIM(var_name)//"'"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (unstruct_data_exists(TRIM(data_id))) THEN
            status%status_code = IF_STATUS_OK
            WRITE(capacity_str, '(I0)') capacity
            CALL log_info("DataPlatform", &
                "dp_ensure_queue: reusing existing queue var='"//TRIM(var_name)//"', capacity="//TRIM(ADJUSTL(capacity_str)))
            RETURN
        END IF

        CALL create_queue(TRIM(data_id), TRIM(var_name), capacity, local_status, &
                          is_circular=circ)
        IF (local_status%status_code /= IF_STATUS_OK .AND. &
            local_status%status_code /= IF_STATUS_EXISTS) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "create_queue failed in dp_ensure_queue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        WRITE(capacity_str, '(I0)') capacity
        CALL log_info("DataPlatform", &
            "dp_ensure_queue: ensured queue var='"//TRIM(var_name)//"', capacity="//TRIM(ADJUSTL(capacity_str)))
    END SUBROUTINE dp_ensure_queue

    SUBROUTINE dp_create_queue(var_name, capacity, is_circular, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: capacity
        LOGICAL,          INTENT(IN), OPTIONAL :: is_circular
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: circ
        CHARACTER(LEN=32) :: capacity_str
        TYPE(UnstructAttrType) :: attr

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for queue cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (capacity < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Queue capacity must be positive in dp_create_queue"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        circ = .TRUE.
        IF (PRESENT(is_circular)) circ = is_circular

        attr = UnstructAttrType()
        attr%queue_capacity = capacity
        attr%queue_is_dynamic = .FALSE.

        CALL dp_register_unstruct(var_name, UNSTRUCT_TYPE_QUEUE, attr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_register_unstruct failed in dp_create_queue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_create_queue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL create_queue(TRIM(data_id), TRIM(var_name), capacity, local_status, &
                          is_circular=circ)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (local_status%status_code == IF_STATUS_EXISTS) THEN
                CALL log_warn("DataPlatform", &
                    "create_queue failed in dp_create_queue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            ELSE
                CALL log_error("DataPlatform", &
                    "create_queue failed in dp_create_queue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            END IF
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        WRITE(capacity_str, '(I0)') capacity
        CALL log_info("DataPlatform", &
            "Created queue via DataPlatform: var='"//TRIM(var_name)//"', capacity="//TRIM(ADJUSTL(capacity_str)))
    END SUBROUTINE dp_create_queue

    SUBROUTINE dp_queue_enqueue(var_name, data_type, int_data, real_data, char_data, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: data_type
        INTEGER,          INTENT(IN), OPTIONAL :: int_data
        REAL,             INTENT(IN), OPTIONAL :: real_data
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: char_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: int_val
        REAL :: real_val
        CHARACTER(LEN=64) :: char_val

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_queue_enqueue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        int_val = 0
        real_val = 0.0
        char_val = ""

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            IF (.NOT. PRESENT(int_data)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "INT data_type requires int_data in dp_queue_enqueue"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF
            int_val = int_data
        CASE (IF_DATA_TYPE_DP)
            IF (.NOT. PRESENT(real_data)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "DP data_type requires real_data in dp_queue_enqueue"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF
            real_val = real_data
        CASE (IF_DATA_TYPE_CHAR)
            IF (.NOT. PRESENT(char_data)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "CHAR data_type requires char_data in dp_queue_enqueue"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF
            char_val = TRIM(char_data)
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported data_type in dp_queue_enqueue (only INT/DP/CHAR allowed)"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END SELECT

        CALL queue_enqueue(TRIM(data_id), data_type, int_val, real_val, char_val, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "queue_enqueue failed in dp_queue_enqueue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_queue_enqueue

    SUBROUTINE dp_queue_dequeue(var_name, data_type, int_data, real_data, char_data, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(OUT) :: data_type
        INTEGER(i4), INTENT(OUT) :: int_data
        REAL,             INTENT(OUT) :: real_data
        CHARACTER(LEN=*), INTENT(OUT) :: char_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        data_type = 0
        int_data  = 0
        real_data = 0.0
        char_data = ""

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_queue_dequeue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL queue_dequeue(TRIM(data_id), data_type, int_data, real_data, char_data, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "queue_dequeue failed in dp_queue_dequeue for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_queue_dequeue

    SUBROUTINE dp_queue_get_size(var_name, size, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(OUT) :: size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        size = 0

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_queue_get_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_queue_size(TRIM(data_id), size, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_queue_size failed in dp_queue_get_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_queue_get_size

    ! ------------------------------------------------------------------------
    ! High-level unstructured hash table APIs
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_create_hash_table(var_name, initial_capacity, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER,          INTENT(IN), OPTIONAL :: initial_capacity
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: cap
        TYPE(UnstructAttrType) :: attr

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for hash table cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        cap = IF_DEFAULT_HASH_BUCKETS
        IF (PRESENT(initial_capacity)) cap = initial_capacity
        IF (cap <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Initial capacity must be positive in dp_create_hash_table"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        attr = UnstructAttrType()
        attr%hash_bucket_count = cap

        CALL dp_register_unstruct(var_name, UNSTRUCT_TYPE_HASH, attr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_register_unstruct failed in dp_create_hash_table for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_create_hash_table for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL create_hash_table(TRIM(data_id), TRIM(var_name), initial_capacity, status=local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (local_status%status_code == IF_STATUS_EXISTS) THEN
                CALL log_warn("DataPlatform", &
                    "create_hash_table failed in dp_create_hash_table for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            ELSE
                CALL log_error("DataPlatform", &
                    "create_hash_table failed in dp_create_hash_table for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            END IF
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created hash table via DataPlatform: var='"//TRIM(var_name)//"'")
    END SUBROUTINE dp_create_hash_table

    SUBROUTINE dp_get_hash_table_size(var_name, entry_count, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        INTEGER(i4), INTENT(OUT) :: entry_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        entry_count = 0

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_get_hash_table_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_hash_table_size(TRIM(data_id), entry_count, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_hash_table_size failed in dp_get_hash_table_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_hash_table_size

    SUBROUTINE dp_hash_insert(var_name, key, value, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: key
        INTEGER(i4), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_hash_insert for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL hash_table_insert(TRIM(data_id), key, value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "hash_table_insert failed in dp_hash_insert for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_hash_insert

    SUBROUTINE dp_hash_get(var_name, key, found, value, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: key
        LOGICAL,          INTENT(OUT) :: found
        INTEGER(i4), INTENT(OUT) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        found = .FALSE.
        value = 0

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_hash_get for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL hash_table_get(TRIM(data_id), key, found, value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "hash_table_get failed in dp_hash_get for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_hash_get

    ! ------------------------------------------------------------------------
    ! High-level unstructured graph APIs
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_create_graph(var_name, num_nodes, is_directed, is_weighted, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: num_nodes
        LOGICAL,          INTENT(IN), OPTIONAL :: is_directed, is_weighted
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: gdir, gwei
        TYPE(UnstructAttrType) :: attr

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for graph cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (num_nodes < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "num_nodes must be non-negative in dp_create_graph"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        gdir = .FALSE.
        IF (PRESENT(is_directed)) gdir = is_directed
        gwei = .TRUE.
        IF (PRESENT(is_weighted)) gwei = is_weighted

        attr = UnstructAttrType()
        attr%graph_vertex_count = num_nodes
        attr%graph_edge_count = 0_8
        attr%graph_is_directed = gdir

        CALL dp_register_unstruct(var_name, UNSTRUCT_TYPE_GRAPH, attr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_register_unstruct failed in dp_create_graph for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_create_graph for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL create_graph(TRIM(data_id), TRIM(var_name), num_nodes, local_status, &
                          is_directed=gdir, is_weighted=gwei)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (local_status%status_code == IF_STATUS_EXISTS) THEN
                CALL log_warn("DataPlatform", &
                    "create_graph failed in dp_create_graph for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            ELSE
                CALL log_error("DataPlatform", &
                    "create_graph failed in dp_create_graph for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            END IF
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created graph via DataPlatform: var='"//TRIM(var_name)//"', nodes="//TRIM(WRITE_INT(num_nodes)))
    END SUBROUTINE dp_create_graph

    SUBROUTINE dp_graph_add_node(var_name, node_id, data_type, int_data, real_data, char_data, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name, char_data
        INTEGER(i4), INTENT(IN) :: node_id, data_type, int_data
        REAL,             INTENT(IN) :: real_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_graph_add_node for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL graph_add_node(TRIM(data_id), node_id, data_type, int_data, real_data, char_data, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "graph_add_node failed in dp_graph_add_node for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_graph_add_node

    SUBROUTINE dp_graph_add_edge(var_name, from_node, to_node, weight, label, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name, label
        INTEGER(i4), INTENT(IN) :: from_node, to_node
        REAL,             INTENT(IN) :: weight
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_graph_add_edge for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL graph_add_edge(TRIM(data_id), from_node, to_node, weight, label, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "graph_add_edge failed in dp_graph_add_edge for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_graph_add_edge

    SUBROUTINE dp_get_graph_size(var_name, num_nodes, num_edges, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        INTEGER(i4), INTENT(OUT) :: num_nodes
        INTEGER(i4), INTENT(OUT) :: num_edges
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        num_nodes = 0
        num_edges = 0

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_get_graph_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_graph_size(TRIM(data_id), num_nodes, num_edges, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_graph_size failed in dp_get_graph_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_graph_size

    SUBROUTINE dp_graph_bfs(var_name, start_node, visited, distances, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: start_node
        LOGICAL, ALLOCATABLE, INTENT(OUT) :: visited(:)
        INTEGER, ALLOCATABLE, INTENT(OUT) :: distances(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        IF (ALLOCATED(visited))   DEALLOCATE(visited)
        IF (ALLOCATED(distances)) DEALLOCATE(distances)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_graph_bfs for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL graph_bfs(TRIM(data_id), start_node, visited, distances, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "graph_bfs failed in dp_graph_bfs for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_graph_bfs

    SUBROUTINE dp_graph_dfs(var_name, start_node, visited, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: start_node
        LOGICAL, ALLOCATABLE, INTENT(OUT) :: visited(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        IF (ALLOCATED(visited)) DEALLOCATE(visited)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_graph_dfs for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL graph_dfs(TRIM(data_id), start_node, visited, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "graph_dfs failed in dp_graph_dfs for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_graph_dfs

    ! ------------------------------------------------------------------------
    ! High-level unstructured adjacency list APIs
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_create_adjacency_list(var_name, num_nodes, is_directed, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: num_nodes
        LOGICAL,          INTENT(IN) :: is_directed
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        TYPE(UnstructAttrType) :: attr

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for adjacency list cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (num_nodes < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "num_nodes must be non-negative in dp_create_adjacency_list"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        attr = UnstructAttrType()
        attr%graph_vertex_count = num_nodes
        attr%graph_edge_count = 0_8
        attr%graph_is_directed = is_directed

        CALL dp_register_unstruct(var_name, UNSTRUCT_TYPE_ADJACENCY, attr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_register_unstruct failed in dp_create_adjacency_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_create_adjacency_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL create_adjacency_list(TRIM(data_id), TRIM(var_name), num_nodes, is_directed, status=local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (local_status%status_code == IF_STATUS_EXISTS) THEN
                CALL log_warn("DataPlatform", &
                    "create_adjacency_list failed in dp_create_adjacency_list for var='"// &
                    TRIM(var_name)//"': "//TRIM(status%message))
            ELSE
                CALL log_error("DataPlatform", &
                    "create_adjacency_list failed in dp_create_adjacency_list for var='"// &
                    TRIM(var_name)//"': "//TRIM(status%message))
            END IF
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created adjacency list via DataPlatform: var='"//TRIM(var_name)//"', nodes="//TRIM(WRITE_INT(num_nodes)))
    END SUBROUTINE dp_create_adjacency_list

    SUBROUTINE dp_adjacency_add_edge(var_name, from_node, to_node, weight, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: from_node, to_node
        REAL,             INTENT(IN) :: weight
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_adjacency_add_edge for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL adjacency_list_add_edge(TRIM(data_id), from_node, to_node, weight, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "adjacency_list_add_edge failed in dp_adjacency_add_edge for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_adjacency_add_edge

    SUBROUTINE dp_get_adjacency_list_size(var_name, num_nodes, edge_count, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        INTEGER(i4), INTENT(OUT) :: num_nodes
        INTEGER(i4), INTENT(OUT) :: edge_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        num_nodes = 0
        edge_count = 0

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_get_adjacency_list_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_adjacency_list_size(TRIM(data_id), num_nodes, edge_count, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_adjacency_list_size failed in dp_get_adjacency_list_size for var='"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_adjacency_list_size

    ! ------------------------------------------------------------------------
    ! High-level unstructured linked list APIs
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_create_linked_list(var_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        TYPE(UnstructAttrType) :: attr

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for linked list cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        attr = UnstructAttrType()

        CALL dp_register_unstruct(var_name, UNSTRUCT_TYPE_LINKED_LIST, attr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_register_unstruct failed in dp_create_linked_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_create_linked_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL create_linked_list(TRIM(data_id), TRIM(var_name), status=local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (local_status%status_code == IF_STATUS_EXISTS) THEN
                CALL log_warn("DataPlatform", &
                    "create_linked_list failed in dp_create_linked_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            ELSE
                CALL log_error("DataPlatform", &
                    "create_linked_list failed in dp_create_linked_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            END IF
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created linked list via DataPlatform: var='"//TRIM(var_name)//"'")
    END SUBROUTINE dp_create_linked_list

    SUBROUTINE dp_get_linked_list_size(var_name, list_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        INTEGER(i4), INTENT(OUT) :: list_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        list_size = 0

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_get_linked_list_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_linked_list_size(TRIM(data_id), list_size, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_linked_list_size failed in dp_get_linked_list_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_linked_list_size

    SUBROUTINE dp_list_push_back(var_name, value, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_list_push_back for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL linked_list_insert(TRIM(data_id), value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "linked_list_insert failed in dp_list_push_back for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_list_push_back

    SUBROUTINE dp_list_get_values(var_name, values, list_size, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: values(:)
        INTEGER(i4), INTENT(OUT) :: list_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        list_size = 0
        IF (ALLOCATED(values)) DEALLOCATE(values)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_list_get_values for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_linked_list_size(TRIM(data_id), list_size, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_linked_list_size failed in dp_list_get_values for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (list_size <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(values(list_size))
        CALL linked_list_get_values(TRIM(data_id), values, list_size, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "linked_list_get_values failed in dp_list_get_values for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_list_get_values

    ! ------------------------------------------------------------------------
    ! High-level unstructured skip list APIs
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_create_skip_list(var_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status
        TYPE(UnstructAttrType) :: attr

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name for skip list cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        attr = UnstructAttrType()

        CALL dp_register_unstruct(var_name, UNSTRUCT_TYPE_SKIP_LIST, attr, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "dp_register_unstruct failed in dp_create_skip_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_create_skip_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL create_skip_list(TRIM(data_id), TRIM(var_name), status=local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            IF (local_status%status_code == IF_STATUS_EXISTS) THEN
                CALL log_warn("DataPlatform", &
                    "create_skip_list failed in dp_create_skip_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            ELSE
                CALL log_error("DataPlatform", &
                    "create_skip_list failed in dp_create_skip_list for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            END IF
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("DataPlatform", &
            "Created skip list via DataPlatform: var='"//TRIM(var_name)//"'")
    END SUBROUTINE dp_create_skip_list

    SUBROUTINE dp_get_skip_list_size(var_name, list_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        INTEGER(i4), INTENT(OUT) :: list_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        list_size = 0

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_get_skip_list_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL get_skip_list_size(TRIM(data_id), list_size, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_skip_list_size failed in dp_get_skip_list_size for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_get_skip_list_size

    SUBROUTINE dp_skip_insert(var_name, key, value_type, int_value, real_value, char_value, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name, char_value
        INTEGER(i4), INTENT(IN) :: key, value_type, int_value
        REAL,             INTENT(IN) :: real_value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_skip_insert for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL skip_list_insert(TRIM(data_id), key, value_type, int_value, real_value, char_value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "skip_list_insert failed in dp_skip_insert for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_skip_insert

    SUBROUTINE dp_skip_get_all(var_name, keys, value_types, int_values, real_values, char_values, count, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: keys(:)
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: value_types(:)
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: int_values(:)
        REAL,             ALLOCATABLE, INTENT(OUT) :: real_values(:)
        CHARACTER(LEN=*), ALLOCATABLE, INTENT(OUT) :: char_values(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: data_id
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)
        count = 0
        IF (ALLOCATED(keys))        DEALLOCATE(keys)
        IF (ALLOCATED(value_types)) DEALLOCATE(value_types)
        IF (ALLOCATED(int_values))  DEALLOCATE(int_values)
        IF (ALLOCATED(real_values)) DEALLOCATE(real_values)
        IF (ALLOCATED(char_values)) DEALLOCATE(char_values)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "get_variable_data_id failed in dp_skip_get_all for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL skip_list_get_all(TRIM(data_id), keys, value_types, int_values, real_values, char_values, count, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("DataPlatform", &
                "skip_list_get_all failed in dp_skip_get_all for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_skip_get_all

    ! ------------------------------------------------------------------------
    ! Internal helper: CRC-based validation using given CRC value
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_validate_crc(var_name, crc_value, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: crc_value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType)   :: struct_meta
        TYPE(UnstructMetaType) :: unstruct_meta
        LOGICAL :: has_struct_meta, has_unstruct_meta
        LOGICAL :: crc_is_valid

        CALL init_error_status(status)

        CALL dp_get_meta(var_name, struct_meta, unstruct_meta, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("DataPlatform", &
                "dp_get_meta failed in dp_validate_crc: "//TRIM(status%message))
            RETURN
        END IF

        has_struct_meta   = struct_meta%is_valid
        has_unstruct_meta = unstruct_meta%is_valid

        ! Metadata-only path (legacy behavior) when crc_value < 0
        IF (crc_value < 0) THEN
            IF (.NOT. has_struct_meta .AND. .NOT. has_unstruct_meta) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Metadata for variable '"//TRIM(var_name)//"' is not valid"
                CALL log_error("DataPlatform", TRIM(status%message))
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "Validated metadata presence for variable '"//TRIM(var_name)//"'")
            RETURN
        END IF

        IF (has_struct_meta) THEN
            CALL struct_meta_validate(TRIM(struct_meta%data_id), crc_value, crc_is_valid, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                RETURN
            END IF

            IF (.NOT. crc_is_valid) THEN
                CALL log_error("DataPlatform", &
                    "CRC validation failed for structured variable '"//TRIM(var_name)//"'")
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "CRC validation passed for structured variable '"//TRIM(var_name)//"'")
            RETURN
        ELSE IF (has_unstruct_meta) THEN
            CALL unstruct_meta_validate(TRIM(unstruct_meta%data_id), crc_value, crc_is_valid, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                RETURN
            END IF

            IF (.NOT. crc_is_valid) THEN
                CALL log_error("DataPlatform", &
                    "CRC validation failed for unstructured variable '"//TRIM(var_name)//"'")
                RETURN
            END IF

            status%status_code = IF_STATUS_OK
            CALL log_info("DataPlatform", &
                "CRC validation passed for unstructured variable '"//TRIM(var_name)//"'")
            RETURN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = "Metadata for variable '"//TRIM(var_name)//"' is not valid"
            CALL log_error("DataPlatform", TRIM(status%message))
        END IF
    END SUBROUTINE dp_validate_crc

    ! ------------------------------------------------------------------------
    ! High-level backup and restore helpers (struct + unstruct unified)
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_backup(var_name, backup_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: backup_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL backup_data(var_name, backup_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("DataPlatform", &
                "dp_backup failed for variable '"//TRIM(var_name)//"' with backup_id '"// &
                TRIM(backup_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL log_info("DataPlatform", &
            "Backup completed for variable '"//TRIM(var_name)//"' with backup_id '"//TRIM(backup_id)//"'")
    END SUBROUTINE dp_backup

    SUBROUTINE dp_restore(var_name, backup_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: backup_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        CALL restore_data(var_name, backup_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("DataPlatform", &
                "dp_restore failed for variable '"//TRIM(var_name)//"' with backup_id '"// &
                TRIM(backup_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL log_info("DataPlatform", &
            "Restore completed for variable '"//TRIM(var_name)//"' with backup_id '"//TRIM(backup_id)//"'")
    END SUBROUTINE dp_restore

    ! ------------------------------------------------------------------------
    ! High-level variable view catalog helpers
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_register_var_view(category, scope, var_name, storage_type, data_type, status)
        CHARACTER(LEN=*), INTENT(IN) :: category
        CHARACTER(LEN=*), INTENT(IN) :: scope
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: storage_type
        INTEGER(i4), INTENT(IN) :: data_type
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i

        CALL init_error_status(status)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_register_var_view"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_register_var_view: var_name cannot be empty"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        ! If already registered with same (category,scope,var_name), do nothing
        DO i = 1, dp_var_view_count
            IF (TRIM(dp_var_views(i)%category) == TRIM(category) .AND. &
                TRIM(dp_var_views(i)%scope)    == TRIM(scope)    .AND. &
                TRIM(dp_var_views(i)%var_name) == TRIM(var_name)) THEN
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO

        IF (dp_var_view_count >= IF_MAX_VAR_VIEWS) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "dp_register_var_view: catalog capacity exceeded"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        dp_var_view_count = dp_var_view_count + 1
        dp_var_views(dp_var_view_count)%category     = ADJUSTL(category)
        dp_var_views(dp_var_view_count)%scope        = ADJUSTL(scope)
        dp_var_views(dp_var_view_count)%var_name     = ADJUSTL(var_name)
        dp_var_views(dp_var_view_count)%storage_type = storage_type
        dp_var_views(dp_var_view_count)%data_type    = data_type

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_register_var_view


    SUBROUTINE dp_list_var_views(category, scope, views, nViews, status)
        CHARACTER(LEN=*), INTENT(IN)  :: category
        CHARACTER(LEN=*), INTENT(IN)  :: scope
        TYPE(DP_VarView), ALLOCATABLE, INTENT(OUT) :: views(:)
        INTEGER(i4), INTENT(OUT) :: nViews
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, count
        LOGICAL :: match_cat, match_scope

        CALL init_error_status(status)
        nViews = 0
        IF (ALLOCATED(views)) DEALLOCATE(views)

        IF (.NOT. dp_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data platform not initialized in dp_list_var_views"
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        ! First pass: count matches
        count = 0
        DO i = 1, dp_var_view_count
            match_cat   = (LEN_TRIM(category) == 0) .OR. &
                          (TRIM(dp_var_views(i)%category) == TRIM(category))
            match_scope = (LEN_TRIM(scope) == 0) .OR. &
                          (TRIM(dp_var_views(i)%scope) == TRIM(scope))
            IF (match_cat .AND. match_scope) THEN
                count = count + 1
            END IF
        END DO

        IF (count <= 0) THEN
            nViews = 0
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(views(count))
        nViews = 0
        DO i = 1, dp_var_view_count
            match_cat   = (LEN_TRIM(category) == 0) .OR. &
                          (TRIM(dp_var_views(i)%category) == TRIM(category))
            match_scope = (LEN_TRIM(scope) == 0) .OR. &
                          (TRIM(dp_var_views(i)%scope) == TRIM(scope))
            IF (match_cat .AND. match_scope) THEN
                nViews = nViews + 1
                views(nViews) = dp_var_views(i)
            END IF
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_list_var_views


    ! ------------------------------------------------------------------------
    ! Internal helper: Calculate CRC32 from file (binary stream)
    ! ------------------------------------------------------------------------
    SUBROUTINE dp_calculate_file_crc32(file_path, crc32, status)

        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(OUT) :: crc32
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: unit, ierr, i, j, byte
        INTEGER(i4), PARAMETER :: CRC32_POLY = Z'04C11DB7'
        INTEGER(i4) :: crc_table(256)
        INTEGER(i4) :: crc

        CALL init_error_status(status)
        crc32 = 0

        ! Create CRC32 lookup table
        DO i = 0, 255
            crc = i
            DO j = 0, 7
                IF (MOD(crc, 2) == 1) THEN
                    crc = IEOR(SHIFTR(crc, 1), CRC32_POLY)
                ELSE
                    crc = SHIFTR(crc, 1)
                END IF
            END DO
            crc_table(i+1) = crc
        END DO

        ! Open file as binary stream
        OPEN(NEWUNIT=unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', &
             FORM='UNFORMATTED', ACCESS='STREAM', IOSTAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A,A)') "Failed to open file for CRC32 (stat=", ierr, "): ", TRIM(file_path)
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        ! Calculate CRC32 over file bytes
        crc = NOT(0)
        DO WHILE (.TRUE.)
            READ(unit, IOSTAT=ierr) byte
            IF (ierr /= 0) EXIT
            crc = IEOR(SHIFTR(crc, 8), crc_table(IAND(IEOR(crc, byte), 255) + 1))
        END DO
        crc = NOT(crc)

        CLOSE(unit)

        IF (ierr > 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A,A)') "Error reading file for CRC32 (stat=", ierr, "): ", TRIM(file_path)
            CALL log_error("DataPlatform", TRIM(status%message))
            RETURN
        END IF

        crc32 = crc
        status%status_code = IF_STATUS_OK
    END SUBROUTINE dp_calculate_file_crc32

END MODULE IF_Base_DP