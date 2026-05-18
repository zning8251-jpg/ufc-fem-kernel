!===============================================================================
! MODULE: IF_UnstructFile_Mgr
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Impl — unstructured file management (adjacency/list/hash persistence)
! BRIEF:  Mirrors StructFileManager for unstructured data. Binary + text output
!         for adjacency list / linked list / hash table.
!===============================================================================
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

MODULE IF_UnstructFile_Mgr
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, log_debug, log_info, &
        log_warn, log_error, IF_STATUS_OK, IF_STATUS_ERROR, &
        IF_STATUS_MEM_ERROR, IF_STATUS_IO_ERROR, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
    USE IF_Mem_Chunk, ONLY: GenericChunkMetaType, gcm_init, gcm_clear, gcm_register_chunk, gcm_get_chunks
    USE IF_IO_Filters, ONLY: IF_IO_Filter_Proc
    USE IF_Base_SymTbl, ONLY: &
        symbol_table_exists, get_variable_data_id, &
        IF_DATA_TYPE_ADJACENCY, IF_DATA_TYPE_LINKED_LIST, IF_DATA_TYPE_HASH, &
        IF_DATA_TYPE_SKIP_LIST, IF_DATA_TYPE_GRAPH, IF_DATA_TYPE_QUEUE, &
        IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
    USE IF_Mem_UnStructPool, ONLY: &
        EdgeDataType, &
        init_unstruct_mem_pool, destroy_unstruct_mem_pool, &
        create_adjacency_list, get_adjacency_list_size, adjacency_list_add_edge, adjacency_list_get_edges, &
        create_linked_list, get_linked_list_size, linked_list_insert, linked_list_get_values, &
        create_hash_table, get_hash_table_size, hash_table_insert, hash_table_get_all, &
        create_skip_list, get_skip_list_size, skip_list_insert, skip_list_get_all, &
        create_graph, get_graph_size, graph_add_node, graph_get_edges, graph_add_edge, &
        create_queue, get_queue_size, queue_get_all, queue_enqueue, &
        get_unstruct_data_info, unstruct_data_exists
    USE IF_Base_UnstructMeta_Def, ONLY: &
        UnstructMetaType, unstruct_meta_query, unstruct_meta_update, &
        IF_STATUS_UNSMETA_NOT_FOUND

    IMPLICIT NONE

    PRIVATE

    ! ----------------------------------------------------------------------
    ! Public constants and types
    ! ----------------------------------------------------------------------
    PUBLIC :: UnstructFileHandleType
    PUBLIC :: ChunkMetaType
    PUBLIC :: ufm_init, ufm_destroy, ufm_clear_cache
    PUBLIC :: ufm_write_unstruct_data, ufm_read_unstruct_data, ufm_get_cache_stats
    PUBLIC :: ufm_write_data_to_chunks, ufm_merge_chunks_to_file
    PUBLIC :: ufm_get_chunks
    PUBLIC :: ufm_register_data_file, ufm_find_data_file
    PUBLIC :: ufm_load_unstruct_data
    PUBLIC :: ufm_migrate_data_file, ufm_preload_data_list
    PUBLIC :: ufm_set_default_io_options
    PUBLIC :: ufm_register_io_filters
    PUBLIC :: IF_FORMAT_BINARY, IF_FORMAT_TXT, IF_FORMAT_CSV, IF_FORMAT_INP, IF_FORMAT_DAT

    INTEGER(i4), PARAMETER :: IF_FORMAT_BINARY = 1
    INTEGER(i4), PARAMETER :: IF_FORMAT_TXT    = 2
    INTEGER(i4), PARAMETER :: IF_FORMAT_CSV    = 3
    INTEGER(i4), PARAMETER :: IF_FORMAT_INP    = 4
    INTEGER(i4), PARAMETER :: IF_FORMAT_DAT    = 5


    ! Core file handle type for unstructured data.
    ! Core fields: path/unit, open state, basic format/mode.
    ! Plugin layers (compression/encryption/sharding) should build on top of this
    ! and not change the core BINARY/TXT protocol semantics.
    TYPE :: UnstructFileHandleType
        CHARACTER(LEN=256) :: file_path = ""
        INTEGER(i4) :: file_unit = -1
        LOGICAL :: is_open = .FALSE.
        INTEGER(i4) :: format_type = IF_FORMAT_BINARY
        CHARACTER(LEN=16) :: mode = ""  ! "READ" / "WRITE"
    END TYPE UnstructFileHandleType

    ! Chunk metadata type: part of the persistence/plugin layer that organizes
    ! how unstructured data is split across files. Core protocol consumers do not
    ! need to depend on this type directly.
    TYPE :: ChunkMetaType
        CHARACTER(LEN=256) :: file_path = ""
        CHARACTER(LEN=64)  :: data_id   = ""
        INTEGER(i4) :: chunk_id = 0
        INTEGER(KIND=8) :: file_offset = 0_8
        INTEGER(KIND=8) :: chunk_size  = 0_8
        INTEGER(i4) :: unstruct_type = 0
        LOGICAL :: is_valid = .FALSE.
    END TYPE ChunkMetaType

    INTEGER(i4), PARAMETER :: IF_MAX_CHUNKS = 1024

    TYPE(ChunkMetaType), SAVE :: chunk_table(IF_MAX_CHUNKS)
    INTEGER, SAVE :: chunk_count = 0

    ! Header cache: small LRU with statistics (plugin layer for performance);
    ! it should not change the on-disk BINARY/TXT protocol, only optimize access.
    INTEGER(i4), PARAMETER :: IF_HEADER_CACHE_CAPACITY = 8

    TYPE :: HeaderCacheEntryType
        CHARACTER(LEN=256) :: file_path = ""
        CHARACTER(LEN=64)  :: data_id   = ""
        INTEGER(i4) :: unstruct_type = 0
        INTEGER(KIND=8) :: mem_size = 0_8
        LOGICAL :: is_valid = .FALSE.
    END TYPE HeaderCacheEntryType

    TYPE(HeaderCacheEntryType), SAVE :: header_cache(IF_HEADER_CACHE_CAPACITY)
    INTEGER, SAVE :: header_cache_count = 0
    INTEGER(KIND=8), SAVE :: cache_hits = 0_8
    INTEGER(KIND=8), SAVE :: cache_misses = 0_8
    INTEGER(KIND=8), SAVE :: cache_requests = 0_8

    ! Recent data_id -> file_path map (small LRU)
    INTEGER(i4), PARAMETER :: IF_DATA_FILE_MAP_CAPACITY = 32

    TYPE :: DataFileMapEntryType
        CHARACTER(LEN=64)  :: data_id = ""
        CHARACTER(LEN=256) :: file_path = ""
        LOGICAL :: is_valid = .FALSE.
    END TYPE DataFileMapEntryType

    TYPE(DataFileMapEntryType), SAVE :: data_file_map(IF_DATA_FILE_MAP_CAPACITY)
    INTEGER, SAVE :: data_file_map_count = 0

    ! IO capability matrix for unstructured file manager (plugin layer descriptor)
    TYPE :: UnstructFileIOCapabilities
        LOGICAL :: supports_binary_format   = .TRUE.
        LOGICAL :: supports_text_format     = .TRUE.
        LOGICAL :: supports_cache           = .TRUE.
        LOGICAL :: supports_encryption      = .TRUE.
        LOGICAL :: supports_compression     = .TRUE.
        LOGICAL :: supports_sharding        = .FALSE.
        LOGICAL :: supports_distributed_io  = .FALSE.
    END TYPE UnstructFileIOCapabilities

    TYPE(UnstructFileIOCapabilities), SAVE :: ufm_capabilities = UnstructFileIOCapabilities()

    INTEGER(i4), PARAMETER :: IF_IO_FLAG_COMPRESS = 1
    INTEGER(i4), PARAMETER :: IF_IO_FLAG_ENCRYPT  = 2

    TYPE :: UfmIOOptionsType
        INTEGER(i4) :: default_format_type   = IF_FORMAT_BINARY
        INTEGER(i4) :: default_compress_type = 0
        INTEGER(i4) :: default_encrypt_type  = 0
    END TYPE UfmIOOptionsType

    TYPE(UfmIOOptionsType), SAVE :: ufm_io_options

    ! Use the generic IO filter interface so this module shares a common
    ! filter contract with other file managers (e.g. StructFileManager).
    PROCEDURE(IF_IO_Filter_Proc), POINTER, SAVE :: active_write_filter => NULL()
    PROCEDURE(IF_IO_Filter_Proc), POINTER, SAVE :: active_read_filter  => NULL()

    LOGICAL, SAVE :: ufm_initialized = .FALSE.

CONTAINS

    SUBROUTINE ufm_init(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (ufm_initialized) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL clear_chunk_table()
        CALL ufm_clear_cache(status)
        CALL clear_data_file_map()
        CALL gcm_init(status)

        ufm_io_options%default_format_type   = IF_FORMAT_BINARY
        ufm_io_options%default_compress_type = 0
        ufm_io_options%default_encrypt_type  = 0

        ufm_initialized = .TRUE.
        CALL log_info("UnstructFileManager", "Initialized unstructured file manager")
    END SUBROUTINE ufm_init

    ! ----------------------------------------------------------------------
    ! Configure default IO options for unstructured data persistence.
    !
    ! Notes:
    ! - default_format_type controls the on-disk format (binary/text variants).
    ! - default_compress_type and default_encrypt_type are *policy flags* only;
    !   ufm_write_unstruct_data will translate them into the io_flags bitmask
    !   (IF_IO_FLAG_COMPRESS / IF_IO_FLAG_ENCRYPT) written to the file header.
    ! - Actual compression/encryption behavior depends on the currently
    !   registered IO filters via ufm_register_io_filters; if no filters are
    !   registered, non-zero io_flags are ignored at payload level.
    ! ----------------------------------------------------------------------
    SUBROUTINE ufm_set_default_io_options(format_type, compress_type, encrypt_type, status)
        INTEGER, INTENT(IN), OPTIONAL :: format_type
        INTEGER, INTENT(IN), OPTIONAL :: compress_type
        INTEGER, INTENT(IN), OPTIONAL :: encrypt_type
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (PRESENT(format_type)) THEN
            ufm_io_options%default_format_type = format_type
        END IF

        IF (PRESENT(compress_type)) THEN
            ufm_io_options%default_compress_type = compress_type
        END IF

        IF (PRESENT(encrypt_type)) THEN
            ufm_io_options%default_encrypt_type = encrypt_type
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ufm_set_default_io_options

    SUBROUTINE ufm_register_io_filters(write_filter, read_filter, status)
        PROCEDURE(IF_IO_Filter_Proc) :: write_filter
        PROCEDURE(IF_IO_Filter_Proc) :: read_filter
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        active_write_filter => write_filter
        active_read_filter  => read_filter

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ufm_register_io_filters

    SUBROUTINE ufm_destroy(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        CALL clear_chunk_table()
        CALL ufm_clear_cache(status)
        CALL clear_data_file_map()
        CALL gcm_clear(status)

        ufm_initialized = .FALSE.
        CALL log_info("UnstructFileManager", "Destroyed unstructured file manager")
    END SUBROUTINE ufm_destroy

    ! Core on-disk header protocol for unstructured data files:
    !   - Header is written at the beginning of every file, before payload
    !   - The same field order is used for both binary (STREAM/UNFORMATTED)
    !     and text (FORMATTED) modes; only the encoding differs.
    !   - Fields (in order):
    !       1) data_id        : CHARACTER(*) from SymbolTable/UnstructMetaData
    !       2) unstruct_type  : INTEGER, IF_DATA_TYPE_* from SymbolTableManager
    !       3) device_id      : INTEGER, producing device (from UnstructMemPool)
    !       4) mem_size       : INTEGER(KIND=8), total bytes in memory
    !       5) format_version : INTEGER, currently fixed to 1
    !       6) io_flags       : INTEGER bitmask (IF_IO_FLAG_COMPRESS / IF_IO_FLAG_ENCRYPT)
    !   - Payload immediately follows the header and is encoded per-type and
    !     per-format in write_*_payload_* helpers.
    SUBROUTINE ufm_write_unstruct_data(data_id, file_path, format_type, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER, INTENT(IN), OPTIONAL :: format_type
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: fmt, unit, ios
        INTEGER(i4) :: unstruct_type, device_id
        INTEGER(KIND=8) :: mem_size
        INTEGER(i4) :: format_version, io_flags
        CHARACTER(LEN=256) :: header_id
        TYPE(ErrorStatusType) :: map_status

        CALL init_error_status(status)

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. unstruct_data_exists(data_id)) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Unstructured data not found: "//TRIM(data_id)
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        fmt = ufm_io_options%default_format_type
        IF (PRESENT(format_type)) fmt = format_type

        CALL get_unstruct_data_info(data_id, unstruct_type, device_id, mem_size, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        unit = 50

        IF (fmt == IF_FORMAT_BINARY) THEN
            OPEN(UNIT=unit, FILE=TRIM(file_path), STATUS='REPLACE', &
                 ACCESS='STREAM', ACTION='WRITE', FORM='UNFORMATTED', IOSTAT=ios)
        ELSE
            OPEN(UNIT=unit, FILE=TRIM(file_path), STATUS='REPLACE', &
                 ACTION='WRITE', FORM='FORMATTED', IOSTAT=ios)
        END IF

        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to open file for write (iostat=", ios, ")"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        format_version = 1
        io_flags       = 0

        IF (ufm_io_options%default_compress_type /= 0) THEN
            io_flags = io_flags + IF_IO_FLAG_COMPRESS
        END IF

        IF (ufm_io_options%default_encrypt_type /= 0) THEN
            io_flags = io_flags + IF_IO_FLAG_ENCRYPT
        END IF

        IF (fmt == IF_FORMAT_BINARY) THEN
            header_id = ""
            header_id = TRIM(data_id)
            WRITE(unit) header_id
            WRITE(unit) unstruct_type
            WRITE(unit) device_id
            WRITE(unit) mem_size
            WRITE(unit) format_version
            WRITE(unit) io_flags
        ELSE
            WRITE(unit, '(A)') TRIM(data_id)
            WRITE(unit, '(I0)') unstruct_type
            WRITE(unit, '(I0)') device_id
            WRITE(unit, '(I0)') mem_size
            WRITE(unit, '(I0)') format_version
            WRITE(unit, '(I0)') io_flags
        END IF

        SELECT CASE (unstruct_type)
        CASE (IF_DATA_TYPE_ADJACENCY)
            SELECT CASE (fmt)
            CASE (IF_FORMAT_BINARY)
                IF (io_flags /= 0 .AND. ASSOCIATED(active_write_filter)) THEN
                    CALL write_adjacency_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL write_adjacency_payload_binary(unit, data_id, status)
                END IF
            CASE (IF_FORMAT_TXT, IF_FORMAT_CSV, IF_FORMAT_INP, IF_FORMAT_DAT)
                CALL write_adjacency_payload_text(unit, data_id, fmt, status)
            END SELECT

        CASE (IF_DATA_TYPE_LINKED_LIST)
            SELECT CASE (fmt)
            CASE (IF_FORMAT_BINARY)
                IF (io_flags /= 0 .AND. ASSOCIATED(active_write_filter)) THEN
                    CALL write_linked_list_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL write_linked_list_payload_binary(unit, data_id, status)
                END IF
            CASE (IF_FORMAT_TXT, IF_FORMAT_CSV, IF_FORMAT_INP, IF_FORMAT_DAT)
                CALL write_linked_list_payload_text(unit, data_id, fmt, status)
            END SELECT

        CASE (IF_DATA_TYPE_HASH)
            SELECT CASE (fmt)
            CASE (IF_FORMAT_BINARY)
                IF (io_flags /= 0 .AND. ASSOCIATED(active_write_filter)) THEN
                    CALL write_hash_table_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL write_hash_table_payload_binary(unit, data_id, status)
                END IF
            CASE (IF_FORMAT_TXT, IF_FORMAT_CSV, IF_FORMAT_INP, IF_FORMAT_DAT)
                CALL write_hash_table_payload_text(unit, data_id, fmt, status)
            END SELECT

        CASE (IF_DATA_TYPE_SKIP_LIST)
            SELECT CASE (fmt)
            CASE (IF_FORMAT_BINARY)
                IF (io_flags /= 0 .AND. ASSOCIATED(active_write_filter)) THEN
                    CALL write_skip_list_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL write_skip_list_payload_binary(unit, data_id, status)
                END IF
            CASE (IF_FORMAT_TXT, IF_FORMAT_CSV, IF_FORMAT_INP, IF_FORMAT_DAT)
                CALL write_skip_list_payload_text(unit, data_id, fmt, status)
            END SELECT

        CASE (IF_DATA_TYPE_GRAPH)
            SELECT CASE (fmt)
            CASE (IF_FORMAT_BINARY)
                IF (io_flags /= 0 .AND. ASSOCIATED(active_write_filter)) THEN
                    CALL write_graph_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL write_graph_payload_binary(unit, data_id, status)
                END IF
            CASE (IF_FORMAT_TXT, IF_FORMAT_CSV, IF_FORMAT_INP, IF_FORMAT_DAT)
                CALL write_graph_payload_text(unit, data_id, fmt, status)
            END SELECT

        CASE (IF_DATA_TYPE_QUEUE)
            SELECT CASE (fmt)
            CASE (IF_FORMAT_BINARY)
                IF (io_flags /= 0 .AND. ASSOCIATED(active_write_filter)) THEN
                    CALL write_queue_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL write_queue_payload_binary(unit, data_id, status)
                END IF
            CASE (IF_FORMAT_TXT, IF_FORMAT_CSV, IF_FORMAT_INP, IF_FORMAT_DAT)
                CALL write_queue_payload_text(unit, data_id, fmt, status)
            END SELECT
        END SELECT

        IF (status%status_code /= IF_STATUS_OK) THEN
            CLOSE(unit)
            RETURN
        END IF

        CLOSE(unit)

        CALL ufm_register_data_file(data_id, file_path, map_status)

        CALL log_info("UnstructFileManager", &
            "Wrote unstructured data header for data_id='"//TRIM(data_id)//"' to "//TRIM(file_path))
    END SUBROUTINE ufm_write_unstruct_data

    SUBROUTINE ufm_read_unstruct_data(file_path, data_id, unstruct_type, mem_size, status)
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        CHARACTER(LEN=*), INTENT(OUT) :: data_id
        INTEGER(i4), INTENT(OUT) :: unstruct_type
        INTEGER(KIND=8), INTENT(OUT) :: mem_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: unit, ios
        INTEGER(i4) :: device_id
        INTEGER(i4) :: format_version, io_flags
        CHARACTER(LEN=256) :: header_id
        TYPE(HeaderCacheEntryType) :: tmp_entry
        INTEGER(i4) :: i, hit_index

        CALL init_error_status(status)
        data_id = ""
        unstruct_type = 0
        mem_size = 0_8

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        cache_requests = cache_requests + 1_8
        hit_index = 0
        DO i = 1, header_cache_count
            IF (header_cache(i)%is_valid) THEN
                IF (TRIM(header_cache(i)%file_path) == TRIM(file_path)) THEN
                    hit_index = i
                    EXIT
                END IF
            END IF
        END DO

        IF (hit_index > 0) THEN
            cache_hits = cache_hits + 1_8

            tmp_entry = header_cache(hit_index)
            IF (hit_index > 1) THEN
                DO i = hit_index, 2, -1
                    header_cache(i) = header_cache(i-1)
                END DO
                header_cache(1) = tmp_entry
            END IF

            data_id       = TRIM(header_cache(1)%data_id)
            unstruct_type = header_cache(1)%unstruct_type
            mem_size      = header_cache(1)%mem_size

            CALL log_info("UnstructFileManager", &
                "Read unstructured header from "//TRIM(file_path)//&
                " (cache hit): data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        cache_misses = cache_misses + 1_8

        unit = 51
        OPEN(UNIT=unit, FILE=TRIM(file_path), STATUS='OLD', &
             ACCESS='STREAM', FORM='UNFORMATTED', ACTION='READ', IOSTAT=ios)

        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to open file for read (iostat=", ios, ")"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) header_id
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read data_id from file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) unstruct_type
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read unstruct_type from file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) device_id
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read device_id from file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) mem_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read mem_size from file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) format_version
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read format_version from file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) io_flags
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read io_flags from file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        data_id = TRIM(header_id)

        CLOSE(unit)

        IF (header_cache_count < IF_HEADER_CACHE_CAPACITY) THEN
            header_cache_count = header_cache_count + 1
        END IF

        DO i = header_cache_count, 2, -1
            header_cache(i) = header_cache(i-1)
        END DO

        header_cache(1)%file_path     = ""
        header_cache(1)%file_path     = TRIM(file_path)
        header_cache(1)%data_id       = ""
        header_cache(1)%data_id       = TRIM(data_id)
        header_cache(1)%unstruct_type = unstruct_type
        header_cache(1)%mem_size      = mem_size
        header_cache(1)%is_valid      = .TRUE.

        CALL log_info("UnstructFileManager", &
            "Read unstructured header from "//TRIM(file_path)//&
            ": data_id='"//TRIM(data_id)//"'")
    END SUBROUTINE ufm_read_unstruct_data

    INTEGER FUNCTION ufm_detect_file_format(file_path) RESULT(fmt)
        CHARACTER(LEN=*), INTENT(IN) :: file_path

        CHARACTER(LEN=256) :: extension
        INTEGER(i4) :: ext_pos, i, char_code

        fmt = IF_FORMAT_BINARY

        ext_pos = INDEX(file_path, ".", .TRUE.)
        IF (ext_pos > 0) THEN
            extension = file_path(ext_pos+1:)

            DO i = 1, LEN_TRIM(extension)
                char_code = ICHAR(extension(i:i))
                IF (char_code >= ICHAR('a') .AND. char_code <= ICHAR('z')) THEN
                    extension(i:i) = ACHAR(char_code - 32)
                END IF
            END DO

            SELECT CASE (TRIM(extension))
            CASE ("TXT", "DAT", "CSV", "INP")
                fmt = IF_FORMAT_TXT
            CASE ("BIN", "BINARY")
                fmt = IF_FORMAT_BINARY
            END SELECT
        END IF
    END FUNCTION ufm_detect_file_format

    SUBROUTINE ufm_load_unstruct_data(file_path, data_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        CHARACTER(LEN=*), INTENT(OUT) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: unit, ios
        INTEGER(i4) :: unstruct_type, device_id
        INTEGER(i4) :: format_version, io_flags
        INTEGER(KIND=8) :: mem_size
        CHARACTER(LEN=256) :: header_id
        INTEGER(i4) :: fmt

        CALL init_error_status(status)
        data_id = ""

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in ufm_load_unstruct_data"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        fmt = ufm_detect_file_format(TRIM(file_path))

        unit = 52
        IF (fmt == IF_FORMAT_BINARY) THEN
            OPEN(UNIT=unit, FILE=TRIM(file_path), STATUS='OLD', &
                 ACCESS='STREAM', FORM='UNFORMATTED', ACTION='READ', IOSTAT=ios)
        ELSE
            OPEN(UNIT=unit, FILE=TRIM(file_path), STATUS='OLD', &
                 ACTION='READ', FORM='FORMATTED', IOSTAT=ios)
        END IF
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to open file for load (iostat=", ios, ")"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (fmt == IF_FORMAT_BINARY) THEN
            READ(unit, IOSTAT=ios) header_id
        ELSE
            READ(unit, '(A)', IOSTAT=ios) header_id
        END IF
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read data_id in ufm_load_unstruct_data"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        IF (fmt == IF_FORMAT_BINARY) THEN
            READ(unit, IOSTAT=ios) unstruct_type
            READ(unit, IOSTAT=ios) device_id
            READ(unit, IOSTAT=ios) mem_size
            READ(unit, IOSTAT=ios) format_version
            READ(unit, IOSTAT=ios) io_flags
        ELSE
            READ(unit, *, IOSTAT=ios) unstruct_type
            READ(unit, *, IOSTAT=ios) device_id
            READ(unit, *, IOSTAT=ios) mem_size
            READ(unit, *, IOSTAT=ios) format_version
            READ(unit, *, IOSTAT=ios) io_flags
        END IF
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read header fields in ufm_load_unstruct_data"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        IF (format_version /= 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported format_version in ufm_load_unstruct_data"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        data_id = TRIM(header_id)

        IF (unstruct_data_exists(data_id)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured data already exists for data_id='"//TRIM(data_id)//"'"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit)
            RETURN
        END IF

        SELECT CASE (unstruct_type)
        CASE (IF_DATA_TYPE_ADJACENCY)
            IF (fmt == IF_FORMAT_BINARY) THEN
                IF (io_flags /= 0 .AND. ASSOCIATED(active_read_filter)) THEN
                    CALL load_adjacency_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL load_adjacency_payload_binary(unit, data_id, status)
                END IF
            ELSE
                CALL load_adjacency_payload_text(unit, data_id, status)
            END IF
        CASE (IF_DATA_TYPE_LINKED_LIST)
            IF (fmt == IF_FORMAT_BINARY) THEN
                IF (io_flags /= 0 .AND. ASSOCIATED(active_read_filter)) THEN
                    CALL load_linked_list_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL load_linked_list_payload_binary(unit, data_id, status)
                END IF
            ELSE
                CALL load_linked_list_payload_text(unit, data_id, status)
            END IF
        CASE (IF_DATA_TYPE_HASH)
            IF (fmt == IF_FORMAT_BINARY) THEN
                IF (io_flags /= 0 .AND. ASSOCIATED(active_read_filter)) THEN
                    CALL load_hash_table_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL load_hash_table_payload_binary(unit, data_id, status)
                END IF
            ELSE
                CALL load_hash_table_payload_text(unit, data_id, status)
            END IF
        CASE (IF_DATA_TYPE_SKIP_LIST)
            IF (fmt == IF_FORMAT_BINARY) THEN
                IF (io_flags /= 0 .AND. ASSOCIATED(active_read_filter)) THEN
                    CALL load_skip_list_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL load_skip_list_payload_binary(unit, data_id, status)
                END IF
            ELSE
                CALL load_skip_list_payload_text(unit, data_id, status)
            END IF
        CASE (IF_DATA_TYPE_GRAPH)
            IF (fmt == IF_FORMAT_BINARY) THEN
                IF (io_flags /= 0 .AND. ASSOCIATED(active_read_filter)) THEN
                    CALL load_graph_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL load_graph_payload_binary(unit, data_id, status)
                END IF
            ELSE
                CALL load_graph_payload_text(unit, data_id, status)
            END IF
        CASE (IF_DATA_TYPE_QUEUE)
            IF (fmt == IF_FORMAT_BINARY) THEN
                IF (io_flags /= 0 .AND. ASSOCIATED(active_read_filter)) THEN
                    CALL load_queue_payload_with_filter(unit, data_id, io_flags, status)
                ELSE
                    CALL load_queue_payload_binary(unit, data_id, status)
                END IF
            ELSE
                CALL load_queue_payload_text(unit, data_id, status)
            END IF
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported unstructured type in ufm_load_unstruct_data"
            CALL log_error("UnstructFileManager", TRIM(status%message))
        END SELECT

        CLOSE(unit)
    END SUBROUTINE ufm_load_unstruct_data

    SUBROUTINE ufm_write_data_to_chunks(data_id, base_filename, status, chunk_size)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: base_filename
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(KIND=8), INTENT(IN), OPTIONAL :: chunk_size

        INTEGER(i4) :: unstruct_type, device_id, ios
        INTEGER(KIND=8) :: mem_size, actual_chunk_size
        INTEGER(KIND=8) :: file_size
        CHARACTER(LEN=256) :: full_file_path
        CHARACTER(LEN=256) :: chunk_file_path
        CHARACTER(LEN=32)  :: idx_str
        INTEGER(i4) :: unit_in, unit_out
        INTEGER(KIND=8) :: bytes_remaining, this_chunk_size
        INTEGER(KIND=8) :: chunk_bytes_remaining, chunk_total_size
        INTEGER(i4), PARAMETER :: IF_BUFFER_BYTES = 65536
        CHARACTER(LEN=1) :: buffer(IF_BUFFER_BYTES)
        INTEGER(i4) :: read_count
        INTEGER(i4) :: chunk_index

        CALL init_error_status(status)

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in ufm_write_data_to_chunks"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. unstruct_data_exists(data_id)) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Unstructured data not found in ufm_write_data_to_chunks: "//TRIM(data_id)
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL get_unstruct_data_info(data_id, unstruct_type, device_id, mem_size, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        actual_chunk_size = 1024_8*1024_8
        IF (PRESENT(chunk_size)) actual_chunk_size = chunk_size

        IF (actual_chunk_size < 1024_8) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Chunk size too small (minimum 1KB) in ufm_write_data_to_chunks"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        full_file_path = TRIM(base_filename)//".bin"
        CALL ufm_write_unstruct_data(data_id, full_file_path, IF_FORMAT_BINARY, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        INQUIRE(FILE=TRIM(full_file_path), SIZE=file_size)
        IF (file_size <= 0_8) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to get file size in ufm_write_data_to_chunks"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        unit_in = 60
        OPEN(UNIT=unit_in, FILE=TRIM(full_file_path), STATUS='OLD', &
             ACCESS='STREAM', FORM='UNFORMATTED', ACTION='READ', IOSTAT=ios)
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to open source file for chunking (iostat=", ios, ")"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        bytes_remaining = file_size
        chunk_index = 0

        DO WHILE (bytes_remaining > 0)
            chunk_index = chunk_index + 1

            this_chunk_size = actual_chunk_size
            IF (this_chunk_size > bytes_remaining) this_chunk_size = bytes_remaining

            chunk_total_size     = this_chunk_size
            chunk_bytes_remaining = this_chunk_size

            WRITE(idx_str, '(I0)') chunk_index
            chunk_file_path = TRIM(base_filename)//".chunk"//TRIM(idx_str)

            unit_out = 70
            OPEN(UNIT=unit_out, FILE=TRIM(chunk_file_path), STATUS='REPLACE', &
                 ACCESS='STREAM', ACTION='WRITE', FORM='UNFORMATTED', IOSTAT=ios)
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                WRITE(status%message, '(A,I0,A)') &
                    "Failed to open chunk file for write (iostat=", ios, ")"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                CLOSE(unit_in)
                RETURN
            END IF

            DO WHILE (chunk_bytes_remaining > 0_8)
                IF (chunk_bytes_remaining < INT(IF_BUFFER_BYTES, KIND=8)) THEN
                    read_count = INT(chunk_bytes_remaining)
                ELSE
                    read_count = IF_BUFFER_BYTES
                END IF

                READ(unit_in, IOSTAT=ios) buffer(1:read_count)
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Error reading from source file in ufm_write_data_to_chunks"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    CLOSE(unit_in)
                    CLOSE(unit_out)
                    RETURN
                END IF

                WRITE(unit_out, IOSTAT=ios) buffer(1:read_count)
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Error writing to chunk file in ufm_write_data_to_chunks"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    CLOSE(unit_in)
                    CLOSE(unit_out)
                    RETURN
                END IF

                chunk_bytes_remaining = chunk_bytes_remaining - INT(read_count, KIND=8)
                bytes_remaining      = bytes_remaining      - INT(read_count, KIND=8)
            END DO

            CLOSE(unit_out)

            CALL register_single_chunk(data_id, chunk_file_path, unstruct_type, &
                                       chunk_total_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "Failed to register chunk metadata in ufm_write_data_to_chunks")
                CLOSE(unit_in)
                RETURN
            END IF
        END DO

        CLOSE(unit_in)

        CALL log_info("UnstructFileManager", &
            "Completed ufm_write_data_to_chunks for data_id='"//TRIM(data_id)//"'")
    END SUBROUTINE ufm_write_data_to_chunks

    SUBROUTINE ufm_merge_chunks_to_file(data_id, base_filename, output_filename, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: base_filename
        CHARACTER(LEN=*), INTENT(IN) :: output_filename
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ChunkMetaType), ALLOCATABLE :: chunks(:)
        INTEGER(i4) :: count, i, ios
        INTEGER(i4) :: unit_in, unit_out
        INTEGER(i4), PARAMETER :: IF_BUFFER_BYTES = 65536
        CHARACTER(LEN=1) :: buffer(IF_BUFFER_BYTES)
        INTEGER(i4) :: read_count
        INTEGER(KIND=8) :: chunk_file_size
        INTEGER(KIND=8) :: bytes_remaining

        CALL init_error_status(status)

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in ufm_merge_chunks_to_file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL ufm_get_chunks(data_id, chunks, count, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        IF (count <= 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "No chunks found for data_id in ufm_merge_chunks_to_file: "//TRIM(data_id)
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        unit_out = 80
        OPEN(UNIT=unit_out, FILE=TRIM(output_filename), STATUS='REPLACE', &
             ACCESS='STREAM', FORM='UNFORMATTED', ACTION='WRITE', IOSTAT=ios)
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to open output file in ufm_merge_chunks_to_file (iostat=", ios, ")"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
            RETURN
        END IF

        DO i = 1, count
            unit_in = 90
            OPEN(UNIT=unit_in, FILE=TRIM(chunks(i)%file_path), STATUS='OLD', &
                 ACCESS='STREAM', FORM='UNFORMATTED', ACTION='READ', IOSTAT=ios)
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                WRITE(status%message, '(A,I0,A)') &
                    "Failed to open chunk file in ufm_merge_chunks_to_file (iostat=", ios, ")"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                CLOSE(unit_out)
                IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
                RETURN
            END IF

            INQUIRE(FILE=TRIM(chunks(i)%file_path), SIZE=chunk_file_size)
            IF (chunk_file_size < 0_8) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to get chunk file size in ufm_merge_chunks_to_file"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                CLOSE(unit_in)
                CLOSE(unit_out)
                IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
                RETURN
            END IF

            bytes_remaining = chunk_file_size

            DO WHILE (bytes_remaining > 0_8)
                IF (bytes_remaining < INT(IF_BUFFER_BYTES, KIND=8)) THEN
                    read_count = INT(bytes_remaining)
                ELSE
                    read_count = IF_BUFFER_BYTES
                END IF

                READ(unit_in, IOSTAT=ios) buffer(1:read_count)
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Error reading chunk file in ufm_merge_chunks_to_file"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    CLOSE(unit_in)
                    CLOSE(unit_out)
                    IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
                    RETURN
                END IF

                WRITE(unit_out, IOSTAT=ios) buffer(1:read_count)
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Error writing merged file in ufm_merge_chunks_to_file"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    CLOSE(unit_in)
                    CLOSE(unit_out)
                    IF (ALLOCATED(chunks)) DEALLOCATE(chunks)
                    RETURN
                END IF

                bytes_remaining = bytes_remaining - INT(read_count, KIND=8)
            END DO

            CLOSE(unit_in)
        END DO

        CLOSE(unit_out)

        IF (ALLOCATED(chunks)) DEALLOCATE(chunks)

        CALL log_info("UnstructFileManager", &
            "Completed ufm_merge_chunks_to_file for data_id='"//TRIM(data_id)//"'")
    END SUBROUTINE ufm_merge_chunks_to_file

    SUBROUTINE write_adjacency_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, total_edges
        INTEGER(i4) :: node_id, edge_count, j
        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)

        CALL init_error_status(status)

        CALL get_adjacency_list_size(data_id, num_nodes, total_edges, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_adjacency_list_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit) num_nodes
        WRITE(unit) total_edges

        DO node_id = 1, num_nodes
            CALL adjacency_list_get_edges(data_id, node_id, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "adjacency_list_get_edges failed for node="//TRIM(WRITE_INT(node_id)))
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                RETURN
            END IF

            DO j = 1, edge_count
                WRITE(unit) node_id
                WRITE(unit) edges(j)%to_node
                WRITE(unit) edges(j)%weight
            END DO

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_adjacency_payload_binary

    SUBROUTINE write_adjacency_payload_text(unit, data_id, fmt, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: fmt
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, total_edges
        INTEGER(i4) :: node_id, edge_count, j
        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)

        CALL init_error_status(status)

        CALL get_adjacency_list_size(data_id, num_nodes, total_edges, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_adjacency_list_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit, '(A,I0)') "# num_nodes = ", num_nodes
        WRITE(unit, '(A,I0)') "# total_edges = ", total_edges

        DO node_id = 1, num_nodes
            CALL adjacency_list_get_edges(data_id, node_id, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "adjacency_list_get_edges failed for node="//TRIM(WRITE_INT(node_id)))
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                RETURN
            END IF

            DO j = 1, edge_count
                WRITE(unit, '(I0,1X,I0,1X,ES14.6)') node_id, edges(j)%to_node, edges(j)%weight
            END DO

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_adjacency_payload_text

    SUBROUTINE write_linked_list_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: list_size
        INTEGER, ALLOCATABLE :: values(:)
        INTEGER(i4) :: i

        CALL init_error_status(status)

        CALL get_linked_list_size(data_id, list_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_linked_list_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit) list_size

        IF (list_size <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL linked_list_get_values(data_id, values, list_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "linked_list_get_values failed for data_id='"//TRIM(data_id)//"'")
            IF (ALLOCATED(values)) DEALLOCATE(values)
            RETURN
        END IF

        DO i = 1, list_size
            WRITE(unit) values(i)
        END DO

        IF (ALLOCATED(values)) DEALLOCATE(values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_linked_list_payload_binary

    SUBROUTINE write_linked_list_payload_text(unit, data_id, fmt, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: fmt
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: list_size
        INTEGER, ALLOCATABLE :: values(:)
        INTEGER(i4) :: i

        CALL init_error_status(status)

        CALL get_linked_list_size(data_id, list_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_linked_list_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit, '(A,I0)') "# list_size = ", list_size

        IF (list_size <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL linked_list_get_values(data_id, values, list_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "linked_list_get_values failed for data_id='"//TRIM(data_id)//"'")
            IF (ALLOCATED(values)) DEALLOCATE(values)
            RETURN
        END IF

        DO i = 1, list_size
            WRITE(unit, '(I0)') values(i)
        END DO

        IF (ALLOCATED(values)) DEALLOCATE(values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_linked_list_payload_text

    SUBROUTINE serialize_linked_list_to_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), ALLOCATABLE, INTENT(OUT) :: buffer(:)
        INTEGER(i4), INTENT(OUT) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: list_size
        INTEGER, ALLOCATABLE :: values(:)
        INTEGER(i4) :: i, int_bytes, alloc_status
        INTEGER(i4) :: offset
        CHARACTER(LEN=32) :: tmp_str

        CALL init_error_status(status)
        payload_size = 0

        CALL get_linked_list_size(data_id, list_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_linked_list_size failed in serialize_linked_list_to_buffer for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(list_size) / 8

        IF (list_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative list_size in serialize_linked_list_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        payload_size = int_bytes * (1 + list_size)

        IF (payload_size <= 0) THEN
            ALLOCATE(buffer(0), STAT=alloc_status)
            IF (alloc_status /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to allocate empty buffer in serialize_linked_list_to_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
            END IF
            RETURN
        END IF

        ALLOCATE(buffer(payload_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate buffer in serialize_linked_list_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        ! Pack list_size
        tmp_str = TRANSFER(list_size, tmp_str)
        DO i = 1, int_bytes
            buffer(i) = tmp_str(i:i)
        END DO

        IF (list_size > 0) THEN
            ALLOCATE(values(list_size), STAT=alloc_status)
            IF (alloc_status /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to allocate values in serialize_linked_list_to_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            CALL linked_list_get_values(data_id, values, list_size, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "linked_list_get_values failed in serialize_linked_list_to_buffer for data_id='"//TRIM(data_id)//"'")
                IF (ALLOCATED(values)) DEALLOCATE(values)
                RETURN
            END IF

            offset = int_bytes
            DO i = 1, list_size
                tmp_str = TRANSFER(values(i), tmp_str)
                DO alloc_status = 1, int_bytes
                    buffer(offset + alloc_status) = tmp_str(alloc_status:alloc_status)
                END DO
                offset = offset + int_bytes
            END DO

            IF (ALLOCATED(values)) DEALLOCATE(values)
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE serialize_linked_list_to_buffer

    SUBROUTINE deserialize_linked_list_from_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), INTENT(IN)  :: buffer(:)
        INTEGER(i4), INTENT(IN) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: list_size
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: offset
        INTEGER(i4) :: i
        CHARACTER(LEN=32) :: tmp_str
        INTEGER(i4) :: value

        CALL init_error_status(status)

        IF (payload_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative payload_size in deserialize_linked_list_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (payload_size == 0) THEN
            CALL create_linked_list(data_id, "var_"//TRIM(data_id), status=status)
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(list_size) / 8

        IF (payload_size < int_bytes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small in deserialize_linked_list_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, int_bytes
            tmp_str(i:i) = buffer(i)
        END DO
        list_size = TRANSFER(tmp_str, list_size)

        IF (list_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative list_size in deserialize_linked_list_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (payload_size < int_bytes * (1 + list_size)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small for list contents in deserialize_linked_list_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_linked_list(data_id, "var_"//TRIM(data_id), status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        offset = int_bytes
        DO i = 1, list_size
            DO int_bytes = 1, STORAGE_SIZE(value)/8
                tmp_str(int_bytes:int_bytes) = buffer(offset + int_bytes)
            END DO
            value = TRANSFER(tmp_str, value)

            CALL linked_list_insert(data_id, value, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN

            offset = offset + STORAGE_SIZE(value)/8
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE deserialize_linked_list_from_buffer

    SUBROUTINE write_linked_list_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: processed_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_write_filter) .OR. io_flags == 0) THEN
            CALL write_linked_list_payload_binary(unit, data_id, status)
            RETURN
        END IF

        CALL serialize_linked_list_to_buffer(data_id, plain_buffer, plain_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        IF (plain_size <= 0) THEN
            WRITE(unit) 0
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(processed_buffer(plain_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in write_linked_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL active_write_filter(plain_buffer, plain_size, processed_buffer, processed_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        WRITE(unit) processed_size
        IF (processed_size > 0) THEN
            WRITE(unit) processed_buffer(1:processed_size)
        END IF

        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_linked_list_payload_with_filter

    SUBROUTINE load_linked_list_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: processed_size
        INTEGER(i4) :: ios
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_read_filter) .OR. io_flags == 0) THEN
            CALL load_linked_list_payload_binary(unit, data_id, status)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_size in load_linked_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative processed_size in load_linked_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size == 0) THEN
            CALL create_linked_list(data_id, "var_"//TRIM(data_id), status=status)
            RETURN
        END IF

        ALLOCATE(processed_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in load_linked_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_buffer
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_buffer in load_linked_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        ALLOCATE(plain_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate plain_buffer in load_linked_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        CALL active_read_filter(processed_buffer, processed_size, plain_buffer, plain_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL deserialize_linked_list_from_buffer(data_id, plain_buffer, plain_size, status)

        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
    END SUBROUTINE load_linked_list_payload_with_filter

    SUBROUTINE write_hash_table_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: entry_count
        CHARACTER(LEN=64), ALLOCATABLE :: keys(:)
        INTEGER,          ALLOCATABLE :: values(:)
        INTEGER(i4) :: i

        CALL init_error_status(status)

        CALL get_hash_table_size(data_id, entry_count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_hash_table_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit) entry_count

        IF (entry_count <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL hash_table_get_all(data_id, keys, values, entry_count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "hash_table_get_all failed for data_id='"//TRIM(data_id)//"'")
            IF (ALLOCATED(keys))   DEALLOCATE(keys)
            IF (ALLOCATED(values)) DEALLOCATE(values)
            RETURN
        END IF

        DO i = 1, entry_count
            WRITE(unit) keys(i)
            WRITE(unit) values(i)
        END DO

        IF (ALLOCATED(keys))   DEALLOCATE(keys)
        IF (ALLOCATED(values)) DEALLOCATE(values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_hash_table_payload_binary

    SUBROUTINE write_skip_list_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: count, i
        INTEGER,          ALLOCATABLE :: keys(:)
        INTEGER,          ALLOCATABLE :: value_types(:)
        INTEGER,          ALLOCATABLE :: int_values(:)
        REAL,             ALLOCATABLE :: real_values(:)
        CHARACTER(LEN=64), ALLOCATABLE :: char_values(:)

        CALL init_error_status(status)

        CALL get_skip_list_size(data_id, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_skip_list_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit) count
        IF (count <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL skip_list_get_all(data_id, keys, value_types, int_values, real_values, char_values, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "skip_list_get_all failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        DO i = 1, count
            WRITE(unit) keys(i)
            WRITE(unit) value_types(i)
            WRITE(unit) int_values(i)
            WRITE(unit) real_values(i)
            WRITE(unit) char_values(i)
        END DO

        IF (ALLOCATED(keys))        DEALLOCATE(keys)
        IF (ALLOCATED(value_types)) DEALLOCATE(value_types)
        IF (ALLOCATED(int_values))  DEALLOCATE(int_values)
        IF (ALLOCATED(real_values)) DEALLOCATE(real_values)
        IF (ALLOCATED(char_values)) DEALLOCATE(char_values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_skip_list_payload_binary

    SUBROUTINE write_skip_list_payload_text(unit, data_id, fmt, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: fmt
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: count, i
        INTEGER,          ALLOCATABLE :: keys(:)
        INTEGER,          ALLOCATABLE :: value_types(:)
        INTEGER,          ALLOCATABLE :: int_values(:)
        REAL,             ALLOCATABLE :: real_values(:)
        CHARACTER(LEN=64), ALLOCATABLE :: char_values(:)

        CALL init_error_status(status)

        CALL get_skip_list_size(data_id, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_skip_list_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit, '(A,I0)') "# skip_list_size = ", count
        IF (count <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL skip_list_get_all(data_id, keys, value_types, int_values, real_values, char_values, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "skip_list_get_all failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        DO i = 1, count
            WRITE(unit, '(I0,1X,I0,1X,I0,1X,ES14.6,1X,A)') &
                keys(i), value_types(i), int_values(i), real_values(i), TRIM(char_values(i))
        END DO

        IF (ALLOCATED(keys))        DEALLOCATE(keys)
        IF (ALLOCATED(value_types)) DEALLOCATE(value_types)
        IF (ALLOCATED(int_values))  DEALLOCATE(int_values)
        IF (ALLOCATED(real_values)) DEALLOCATE(real_values)
        IF (ALLOCATED(char_values)) DEALLOCATE(char_values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_skip_list_payload_text

    SUBROUTINE write_hash_table_payload_text(unit, data_id, fmt, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: fmt
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: entry_count
        CHARACTER(LEN=64), ALLOCATABLE :: keys(:)
        INTEGER,          ALLOCATABLE :: values(:)
        INTEGER(i4) :: i

        CALL init_error_status(status)

        CALL get_hash_table_size(data_id, entry_count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_hash_table_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit, '(A,I0)') "# hash_entries = ", entry_count

        IF (entry_count <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL hash_table_get_all(data_id, keys, values, entry_count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "hash_table_get_all failed for data_id='"//TRIM(data_id)//"'")
            IF (ALLOCATED(keys))   DEALLOCATE(keys)
            IF (ALLOCATED(values)) DEALLOCATE(values)
            RETURN
        END IF

        DO i = 1, entry_count
            WRITE(unit, '(A,1X,I0)') TRIM(keys(i)), values(i)
        END DO

        IF (ALLOCATED(keys))   DEALLOCATE(keys)
        IF (ALLOCATED(values)) DEALLOCATE(values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_hash_table_payload_text

    SUBROUTINE serialize_hash_table_to_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), ALLOCATABLE, INTENT(OUT) :: buffer(:)
        INTEGER(i4), INTENT(OUT) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: entry_count
        CHARACTER(LEN=64), ALLOCATABLE :: keys(:)
        INTEGER,          ALLOCATABLE :: values(:)
        INTEGER(i4) :: int_bytes, key_len
        INTEGER(i4) :: i, j, alloc_status
        INTEGER(i4) :: offset
        CHARACTER(LEN=64) :: key_tmp
        CHARACTER(LEN=32) :: int_tmp

        CALL init_error_status(status)
        payload_size = 0

        CALL get_hash_table_size(data_id, entry_count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_hash_table_size failed in serialize_hash_table_to_buffer for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(entry_count) / 8
        key_len   = 64

        IF (entry_count < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative entry_count in serialize_hash_table_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        payload_size = int_bytes + entry_count * (key_len + int_bytes)

        IF (payload_size <= 0) THEN
            ALLOCATE(buffer(0), STAT=alloc_status)
            IF (alloc_status /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to allocate empty buffer in serialize_hash_table_to_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
            END IF
            RETURN
        END IF

        ALLOCATE(buffer(payload_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate buffer in serialize_hash_table_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        ! Pack entry_count
        int_tmp = TRANSFER(entry_count, int_tmp)
        DO i = 1, int_bytes
            buffer(i) = int_tmp(i:i)
        END DO

        IF (entry_count > 0) THEN
            ALLOCATE(keys(entry_count), STAT=alloc_status)
            IF (alloc_status /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to allocate keys in serialize_hash_table_to_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            ALLOCATE(values(entry_count), STAT=alloc_status)
            IF (alloc_status /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to allocate values in serialize_hash_table_to_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                IF (ALLOCATED(keys)) DEALLOCATE(keys)
                RETURN
            END IF

            CALL hash_table_get_all(data_id, keys, values, entry_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "hash_table_get_all failed in serialize_hash_table_to_buffer for data_id='"//TRIM(data_id)//"'")
                IF (ALLOCATED(keys))   DEALLOCATE(keys)
                IF (ALLOCATED(values)) DEALLOCATE(values)
                RETURN
            END IF

            offset = int_bytes
            DO i = 1, entry_count
                key_tmp = keys(i)
                DO j = 1, key_len
                    buffer(offset + j) = key_tmp(j:j)
                END DO
                offset = offset + key_len

                int_tmp = TRANSFER(values(i), int_tmp)
                DO j = 1, int_bytes
                    buffer(offset + j) = int_tmp(j:j)
                END DO
                offset = offset + int_bytes
            END DO

            IF (ALLOCATED(keys))   DEALLOCATE(keys)
            IF (ALLOCATED(values)) DEALLOCATE(values)
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE serialize_hash_table_to_buffer

    SUBROUTINE deserialize_hash_table_from_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), INTENT(IN)  :: buffer(:)
        INTEGER(i4), INTENT(IN) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: entry_count
        INTEGER(i4) :: int_bytes, key_len
        INTEGER(i4) :: offset
        INTEGER(i4) :: i, j
        CHARACTER(LEN=64) :: key_tmp
        CHARACTER(LEN=32) :: int_tmp
        INTEGER(i4) :: value
        INTEGER(i4) :: initial_capacity

        CALL init_error_status(status)

        IF (payload_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative payload_size in deserialize_hash_table_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(entry_count) / 8
        key_len   = 64

        IF (payload_size < int_bytes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small in deserialize_hash_table_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        ! Unpack entry_count
        DO i = 1, int_bytes
            int_tmp(i:i) = buffer(i)
        END DO
        entry_count = TRANSFER(int_tmp, entry_count)

        IF (entry_count < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative entry_count in deserialize_hash_table_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (payload_size < int_bytes + entry_count * (key_len + int_bytes)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small for hash entries in deserialize_hash_table_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        initial_capacity = MAX(16, entry_count*2)
        CALL create_hash_table(data_id, "var_"//TRIM(data_id), initial_capacity=initial_capacity, status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        offset = int_bytes
        DO i = 1, entry_count
            ! unpack key
            DO j = 1, key_len
                key_tmp(j:j) = buffer(offset + j)
            END DO
            offset = offset + key_len

            ! unpack value
            DO j = 1, int_bytes
                int_tmp(j:j) = buffer(offset + j)
            END DO
            value = TRANSFER(int_tmp, value)
            offset = offset + int_bytes

            CALL hash_table_insert(data_id, TRIM(key_tmp), value, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE deserialize_hash_table_from_buffer

    SUBROUTINE write_hash_table_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: processed_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_write_filter) .OR. io_flags == 0) THEN
            CALL write_hash_table_payload_binary(unit, data_id, status)
            RETURN
        END IF

        CALL serialize_hash_table_to_buffer(data_id, plain_buffer, plain_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        IF (plain_size <= 0) THEN
            WRITE(unit) 0
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(processed_buffer(plain_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in write_hash_table_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL active_write_filter(plain_buffer, plain_size, processed_buffer, processed_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        WRITE(unit) processed_size
        IF (processed_size > 0) THEN
            WRITE(unit) processed_buffer(1:processed_size)
        END IF

        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_hash_table_payload_with_filter

    SUBROUTINE load_hash_table_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: processed_size
        INTEGER(i4) :: ios
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_read_filter) .OR. io_flags == 0) THEN
            CALL load_hash_table_payload_binary(unit, data_id, status)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_size in load_hash_table_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative processed_size in load_hash_table_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size == 0) THEN
            CALL create_hash_table(data_id, "var_"//TRIM(data_id), initial_capacity=16, status=status)
            RETURN
        END IF

        ALLOCATE(processed_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in load_hash_table_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_buffer
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_buffer in load_hash_table_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        ALLOCATE(plain_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate plain_buffer in load_hash_table_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        CALL active_read_filter(processed_buffer, processed_size, plain_buffer, plain_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL deserialize_hash_table_from_buffer(data_id, plain_buffer, plain_size, status)

        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
    END SUBROUTINE load_hash_table_payload_with_filter

    SUBROUTINE write_skip_list_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: processed_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_write_filter) .OR. io_flags == 0) THEN
            CALL write_skip_list_payload_binary(unit, data_id, status)
            RETURN
        END IF

        CALL serialize_skip_list_to_buffer(data_id, plain_buffer, plain_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        IF (plain_size <= 0) THEN
            WRITE(unit) 0
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(processed_buffer(plain_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in write_skip_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL active_write_filter(plain_buffer, plain_size, processed_buffer, processed_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        WRITE(unit) processed_size
        IF (processed_size > 0) THEN
            WRITE(unit) processed_buffer(1:processed_size)
        END IF

        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_skip_list_payload_with_filter

    SUBROUTINE load_skip_list_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: processed_size
        INTEGER(i4) :: ios
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_read_filter) .OR. io_flags == 0) THEN
            CALL load_skip_list_payload_binary(unit, data_id, status)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_size in load_skip_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative processed_size in load_skip_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size == 0) THEN
            CALL create_skip_list(data_id, "var_"//TRIM(data_id), status)
            RETURN
        END IF

        ALLOCATE(processed_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in load_skip_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_buffer
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_buffer in load_skip_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        ALLOCATE(plain_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate plain_buffer in load_skip_list_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        CALL active_read_filter(processed_buffer, processed_size, plain_buffer, plain_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL deserialize_skip_list_from_buffer(data_id, plain_buffer, plain_size, status)

        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
    END SUBROUTINE load_skip_list_payload_with_filter

    SUBROUTINE write_adjacency_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: processed_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_write_filter) .OR. io_flags == 0) THEN
            CALL write_adjacency_payload_binary(unit, data_id, status)
            RETURN
        END IF

        CALL serialize_adjacency_to_buffer(data_id, plain_buffer, plain_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        IF (plain_size <= 0) THEN
            WRITE(unit) 0
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(processed_buffer(plain_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in write_adjacency_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL active_write_filter(plain_buffer, plain_size, processed_buffer, processed_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        WRITE(unit) processed_size
        IF (processed_size > 0) THEN
            WRITE(unit) processed_buffer(1:processed_size)
        END IF

        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_adjacency_payload_with_filter

    SUBROUTINE load_adjacency_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: processed_size
        INTEGER(i4) :: ios
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_read_filter) .OR. io_flags == 0) THEN
            CALL load_adjacency_payload_binary(unit, data_id, status)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_size in load_adjacency_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Non-positive processed_size in load_adjacency_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        ALLOCATE(processed_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in load_adjacency_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_buffer
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_buffer in load_adjacency_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        ALLOCATE(plain_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate plain_buffer in load_adjacency_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        CALL active_read_filter(processed_buffer, processed_size, plain_buffer, plain_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL deserialize_adjacency_from_buffer(data_id, plain_buffer, plain_size, status)

        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)

    END SUBROUTINE load_adjacency_payload_with_filter

    SUBROUTINE write_graph_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: processed_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_write_filter) .OR. io_flags == 0) THEN
            CALL write_graph_payload_binary(unit, data_id, status)
            RETURN
        END IF

        CALL serialize_graph_to_buffer(data_id, plain_buffer, plain_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        IF (plain_size <= 0) THEN
            WRITE(unit) 0
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(processed_buffer(plain_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in write_graph_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL active_write_filter(plain_buffer, plain_size, processed_buffer, processed_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        WRITE(unit) processed_size
        IF (processed_size > 0) THEN
            WRITE(unit) processed_buffer(1:processed_size)
        END IF

        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_graph_payload_with_filter

    SUBROUTINE load_graph_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: processed_size
        INTEGER(i4) :: ios
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_read_filter) .OR. io_flags == 0) THEN
            CALL load_graph_payload_binary(unit, data_id, status)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_size in load_graph_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Non-positive processed_size in load_graph_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        ALLOCATE(processed_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in load_graph_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_buffer
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_buffer in load_graph_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        ALLOCATE(plain_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate plain_buffer in load_graph_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        CALL active_read_filter(processed_buffer, processed_size, plain_buffer, plain_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL deserialize_graph_from_buffer(data_id, plain_buffer, plain_size, status)

        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
    END SUBROUTINE load_graph_payload_with_filter

    SUBROUTINE write_graph_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, num_edges
        INTEGER(i4) :: node_id, edge_count, j
        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)

        CALL init_error_status(status)

        CALL get_graph_size(data_id, num_nodes, num_edges, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_graph_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit) num_nodes
        WRITE(unit) num_edges

        DO node_id = 1, num_nodes
            CALL graph_get_edges(data_id, node_id, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "graph_get_edges failed for node="//TRIM(WRITE_INT(node_id)))
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                RETURN
            END IF

            WRITE(unit) edge_count
            DO j = 1, edge_count
                WRITE(unit) node_id
                WRITE(unit) edges(j)%to_node
                WRITE(unit) edges(j)%weight
            END DO

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_graph_payload_binary

    SUBROUTINE write_graph_payload_text(unit, data_id, fmt, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: fmt
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, num_edges
        INTEGER(i4) :: node_id, edge_count, j
        INTEGER(i4) :: total_edge_count
        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)

        CALL init_error_status(status)

        CALL get_graph_size(data_id, num_nodes, num_edges, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_graph_size failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        total_edge_count = 0
        DO node_id = 1, num_nodes
            CALL graph_get_edges(data_id, node_id, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "graph_get_edges failed for node="//TRIM(WRITE_INT(node_id)))
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                RETURN
            END IF

            total_edge_count = total_edge_count + edge_count

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        WRITE(unit, '(A,I0)') "# num_nodes = ", num_nodes
        WRITE(unit, '(A,I0)') "# num_edges = ", total_edge_count

        DO node_id = 1, num_nodes
            CALL graph_get_edges(data_id, node_id, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "graph_get_edges failed for node="//TRIM(WRITE_INT(node_id)))
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                RETURN
            END IF

            DO j = 1, edge_count
                WRITE(unit, '(I0,1X,I0,1X,ES14.6)') node_id, edges(j)%to_node, edges(j)%weight
            END DO

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_graph_payload_text

    SUBROUTINE write_queue_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: processed_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_write_filter) .OR. io_flags == 0) THEN
            CALL write_queue_payload_binary(unit, data_id, status)
            RETURN
        END IF

        CALL serialize_queue_to_buffer(data_id, plain_buffer, plain_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        IF (plain_size <= 0) THEN
            WRITE(unit) 0
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(processed_buffer(plain_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in write_queue_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL active_write_filter(plain_buffer, plain_size, processed_buffer, processed_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        WRITE(unit) processed_size
        IF (processed_size > 0) THEN
            WRITE(unit) processed_buffer(1:processed_size)
        END IF

        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_queue_payload_with_filter

    SUBROUTINE write_queue_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: data_type, count, i
        INTEGER,          ALLOCATABLE :: int_values(:)
        REAL,             ALLOCATABLE :: real_values(:)
        CHARACTER(LEN=64), ALLOCATABLE :: char_values(:)

        CALL init_error_status(status)

        CALL queue_get_all(data_id, data_type, int_values, real_values, char_values, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "queue_get_all failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit) data_type
        WRITE(unit) count
        IF (count <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            DO i = 1, count
                WRITE(unit) int_values(i)
            END DO
        CASE (IF_DATA_TYPE_DP)
            DO i = 1, count
                WRITE(unit) real_values(i)
            END DO
        CASE (IF_DATA_TYPE_CHAR)
            DO i = 1, count
                WRITE(unit) char_values(i)
            END DO
        END SELECT

        IF (ALLOCATED(int_values))  DEALLOCATE(int_values)
        IF (ALLOCATED(real_values)) DEALLOCATE(real_values)
        IF (ALLOCATED(char_values)) DEALLOCATE(char_values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_queue_payload_binary

    SUBROUTINE write_queue_payload_text(unit, data_id, fmt, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: fmt
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: data_type, count, i
        INTEGER,          ALLOCATABLE :: int_values(:)
        REAL,             ALLOCATABLE :: real_values(:)
        CHARACTER(LEN=64), ALLOCATABLE :: char_values(:)

        CALL init_error_status(status)

        CALL queue_get_all(data_id, data_type, int_values, real_values, char_values, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "queue_get_all failed for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        WRITE(unit, '(A,I0)') "# queue_size = ", count
        WRITE(unit, '(A,I0)') "# queue_type = ", data_type
        IF (count <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            DO i = 1, count
                WRITE(unit, '(I0)') int_values(i)
            END DO
        CASE (IF_DATA_TYPE_DP)
            DO i = 1, count
                WRITE(unit, '(ES14.6)') real_values(i)
            END DO
        CASE (IF_DATA_TYPE_CHAR)
            DO i = 1, count
                WRITE(unit, '(A)') TRIM(char_values(i))
            END DO
        END SELECT

        IF (ALLOCATED(int_values))  DEALLOCATE(int_values)
        IF (ALLOCATED(real_values)) DEALLOCATE(real_values)
        IF (ALLOCATED(char_values)) DEALLOCATE(char_values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE write_queue_payload_text

    SUBROUTINE serialize_queue_to_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), ALLOCATABLE, INTENT(OUT) :: buffer(:)
        INTEGER(i4), INTENT(OUT) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: data_type, count, queue_size
        INTEGER,          ALLOCATABLE :: int_values(:)
        REAL,             ALLOCATABLE :: real_values(:)
        CHARACTER(LEN=64), ALLOCATABLE :: char_values(:)
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: real_bytes
        INTEGER(i4) :: char_len
        INTEGER(i4) :: alloc_status
        INTEGER(i4) :: i, j
        INTEGER(i4) :: offset
        CHARACTER(LEN=32) :: tmp_bytes

        CALL init_error_status(status)
        payload_size = 0

        CALL get_queue_size(data_id, queue_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_queue_size failed in serialize_queue_to_buffer for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        CALL queue_get_all(data_id, data_type, int_values, real_values, char_values, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "queue_get_all failed in serialize_queue_to_buffer for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(count) / 8
        real_bytes = STORAGE_SIZE(real_values(1)) / 8
        char_len   = 64

        IF (count < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative count in serialize_queue_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            payload_size = 2*int_bytes + count*int_bytes
        CASE (IF_DATA_TYPE_DP)
            payload_size = 2*int_bytes + count*real_bytes
        CASE (IF_DATA_TYPE_CHAR)
            payload_size = 2*int_bytes + count*char_len
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported data_type in serialize_queue_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END SELECT

        IF (payload_size <= 0) THEN
            ALLOCATE(buffer(0), STAT=alloc_status)
            IF (alloc_status /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to allocate empty buffer in serialize_queue_to_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
            END IF
            RETURN
        END IF

        ALLOCATE(buffer(payload_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate buffer in serialize_queue_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        tmp_bytes = TRANSFER(data_type, tmp_bytes)
        DO i = 1, int_bytes
            buffer(i) = tmp_bytes(i:i)
        END DO

        tmp_bytes = TRANSFER(count, tmp_bytes)
        DO i = 1, int_bytes
            buffer(int_bytes + i) = tmp_bytes(i:i)
        END DO

        offset = 2*int_bytes

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            DO i = 1, count
                tmp_bytes = TRANSFER(int_values(i), tmp_bytes)
                DO j = 1, int_bytes
                    buffer(offset + j) = tmp_bytes(j:j)
                END DO
                offset = offset + int_bytes
            END DO
        CASE (IF_DATA_TYPE_DP)
            DO i = 1, count
                tmp_bytes = TRANSFER(real_values(i), tmp_bytes)
                DO j = 1, real_bytes
                    buffer(offset + j) = tmp_bytes(j:j)
                END DO
                offset = offset + real_bytes
            END DO
        CASE (IF_DATA_TYPE_CHAR)
            DO i = 1, count
                DO j = 1, char_len
                    buffer(offset + j) = char_values(i)(j:j)
                END DO
                offset = offset + char_len
            END DO
        END SELECT

        IF (ALLOCATED(int_values))  DEALLOCATE(int_values)
        IF (ALLOCATED(real_values)) DEALLOCATE(real_values)
        IF (ALLOCATED(char_values)) DEALLOCATE(char_values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE serialize_queue_to_buffer

    SUBROUTINE deserialize_queue_from_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), INTENT(IN)  :: buffer(:)
        INTEGER(i4), INTENT(IN) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: data_type
        INTEGER(i4) :: count
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: real_bytes
        INTEGER(i4) :: char_len
        INTEGER(i4) :: offset
        INTEGER(i4) :: i
        INTEGER(i4) :: ios
        CHARACTER(LEN=32) :: tmp_bytes
        INTEGER(i4) :: int_value
        REAL    :: real_value
        CHARACTER(LEN=64) :: char_value
        INTEGER(i4) :: capacity

        CALL init_error_status(status)

        IF (payload_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative payload_size in deserialize_queue_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(count) / 8
        real_bytes = STORAGE_SIZE(real_value) / 8
        char_len   = 64

        IF (payload_size < 2*int_bytes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small in deserialize_queue_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, int_bytes
            tmp_bytes(i:i) = buffer(i)
        END DO
        data_type = TRANSFER(tmp_bytes, data_type)

        DO i = 1, int_bytes
            tmp_bytes(i:i) = buffer(int_bytes + i)
        END DO
        count = TRANSFER(tmp_bytes, count)

        IF (count < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative count in deserialize_queue_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            IF (payload_size < 2*int_bytes + count*int_bytes) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Payload too small for int queue in deserialize_queue_from_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF
        CASE (IF_DATA_TYPE_DP)
            IF (payload_size < 2*int_bytes + count*real_bytes) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Payload too small for real queue in deserialize_queue_from_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF
        CASE (IF_DATA_TYPE_CHAR)
            IF (payload_size < 2*int_bytes + count*char_len) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Payload too small for char queue in deserialize_queue_from_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported data_type in deserialize_queue_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END SELECT

        capacity = MAX(1, count)
        CALL create_queue(data_id, "var_"//TRIM(data_id), capacity, status, is_circular=.TRUE.)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        offset = 2*int_bytes

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            DO i = 1, count
                DO ios = 1, int_bytes
                    tmp_bytes(ios:ios) = buffer(offset + ios)
                END DO
                int_value = TRANSFER(tmp_bytes, int_value)
                offset = offset + int_bytes

                CALL queue_enqueue(data_id, IF_DATA_TYPE_INT, int_value, 0.0, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        CASE (IF_DATA_TYPE_DP)
            DO i = 1, count
                DO ios = 1, real_bytes
                    tmp_bytes(ios:ios) = buffer(offset + ios)
                END DO
                real_value = TRANSFER(tmp_bytes, real_value)
                offset = offset + real_bytes

                CALL queue_enqueue(data_id, IF_DATA_TYPE_DP, 0, real_value, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        CASE (IF_DATA_TYPE_CHAR)
            DO i = 1, count
                DO ios = 1, char_len
                    char_value(ios:ios) = buffer(offset + ios)
                END DO
                offset = offset + char_len

                CALL queue_enqueue(data_id, IF_DATA_TYPE_CHAR, 0, 0.0, TRIM(char_value), status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE deserialize_queue_from_buffer

    SUBROUTINE serialize_skip_list_to_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), ALLOCATABLE, INTENT(OUT) :: buffer(:)
        INTEGER(i4), INTENT(OUT) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: count
        INTEGER,          ALLOCATABLE :: keys(:)
        INTEGER,          ALLOCATABLE :: value_types(:)
        INTEGER,          ALLOCATABLE :: int_values(:)
        REAL,             ALLOCATABLE :: real_values(:)
        CHARACTER(LEN=64), ALLOCATABLE :: char_values(:)
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: key_bytes
        INTEGER(i4) :: real_bytes
        INTEGER(i4) :: char_len
        INTEGER(i4) :: alloc_status
        INTEGER(i4) :: i, j
        INTEGER(i4) :: num_int, num_real, num_char
        INTEGER(i4) :: offset
        CHARACTER(LEN=32) :: tmp_bytes

        CALL init_error_status(status)
        payload_size = 0

        CALL get_skip_list_size(data_id, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_skip_list_size failed in serialize_skip_list_to_buffer for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        IF (count < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative count in serialize_skip_list_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(count) / 8
        key_bytes = STORAGE_SIZE(count) / 8
        real_bytes = STORAGE_SIZE(real_values(1)) / 8
        char_len   = 64

        IF (count == 0) THEN
            payload_size = int_bytes
            ALLOCATE(buffer(payload_size), STAT=alloc_status)
            IF (alloc_status /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to allocate buffer in serialize_skip_list_to_buffer (empty)"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            tmp_bytes = TRANSFER(count, tmp_bytes)
            DO i = 1, int_bytes
                buffer(i) = tmp_bytes(i:i)
            END DO

            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL skip_list_get_all(data_id, keys, value_types, int_values, real_values, char_values, count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "skip_list_get_all failed in serialize_skip_list_to_buffer for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        num_int  = 0
        num_real = 0
        num_char = 0
        DO i = 1, count
            SELECT CASE (value_types(i))
            CASE (IF_DATA_TYPE_INT)
                num_int = num_int + 1
            CASE (IF_DATA_TYPE_DP)
                num_real = num_real + 1
            CASE (IF_DATA_TYPE_CHAR)
                num_char = num_char + 1
            END SELECT
        END DO

        payload_size = int_bytes + count*(key_bytes + int_bytes) + &
                       num_int*int_bytes + num_real*real_bytes + num_char*char_len

        ALLOCATE(buffer(payload_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate buffer in serialize_skip_list_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        tmp_bytes = TRANSFER(count, tmp_bytes)
        DO i = 1, int_bytes
            buffer(i) = tmp_bytes(i:i)
        END DO

        offset = int_bytes

        DO i = 1, count
            tmp_bytes = TRANSFER(keys(i), tmp_bytes)
            DO j = 1, key_bytes
                buffer(offset + j) = tmp_bytes(j:j)
            END DO
            offset = offset + key_bytes

            tmp_bytes = TRANSFER(value_types(i), tmp_bytes)
            DO j = 1, int_bytes
                buffer(offset + j) = tmp_bytes(j:j)
            END DO
            offset = offset + int_bytes

            SELECT CASE (value_types(i))
            CASE (IF_DATA_TYPE_INT)
                tmp_bytes = TRANSFER(int_values(i), tmp_bytes)
                DO j = 1, int_bytes
                    buffer(offset + j) = tmp_bytes(j:j)
                END DO
                offset = offset + int_bytes
            CASE (IF_DATA_TYPE_DP)
                tmp_bytes = TRANSFER(real_values(i), tmp_bytes)
                DO j = 1, real_bytes
                    buffer(offset + j) = tmp_bytes(j:j)
                END DO
                offset = offset + real_bytes
            CASE (IF_DATA_TYPE_CHAR)
                DO j = 1, char_len
                    buffer(offset + j) = char_values(i)(j:j)
                END DO
                offset = offset + char_len
            END SELECT
        END DO

        IF (ALLOCATED(keys))        DEALLOCATE(keys)
        IF (ALLOCATED(value_types)) DEALLOCATE(value_types)
        IF (ALLOCATED(int_values))  DEALLOCATE(int_values)
        IF (ALLOCATED(real_values)) DEALLOCATE(real_values)
        IF (ALLOCATED(char_values)) DEALLOCATE(char_values)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE serialize_skip_list_to_buffer

    SUBROUTINE deserialize_skip_list_from_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), INTENT(IN)  :: buffer(:)
        INTEGER(i4), INTENT(IN) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: count
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: key_bytes
        INTEGER(i4) :: real_bytes
        INTEGER(i4) :: char_len
        INTEGER(i4) :: offset
        INTEGER(i4) :: i, j
        CHARACTER(LEN=32) :: tmp_bytes
        INTEGER(i4) :: key
        INTEGER(i4) :: value_type
        INTEGER(i4) :: int_value
        REAL    :: real_value
        CHARACTER(LEN=64) :: char_value

        CALL init_error_status(status)

        IF (payload_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative payload_size in deserialize_skip_list_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(count) / 8
        key_bytes = STORAGE_SIZE(count) / 8
        real_bytes = STORAGE_SIZE(real_value) / 8
        char_len   = 64

        IF (payload_size < int_bytes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small in deserialize_skip_list_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, int_bytes
            tmp_bytes(i:i) = buffer(i)
        END DO
        count = TRANSFER(tmp_bytes, count)

        IF (count < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative count in deserialize_skip_list_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        offset = int_bytes

        CALL create_skip_list(data_id, "var_"//TRIM(data_id), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, count
            IF (offset + key_bytes + int_bytes - 1 > payload_size) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Payload too small for skip list entry in deserialize_skip_list_from_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            DO j = 1, key_bytes
                tmp_bytes(j:j) = buffer(offset + j)
            END DO
            key = TRANSFER(tmp_bytes, key)
            offset = offset + key_bytes

            DO j = 1, int_bytes
                tmp_bytes(j:j) = buffer(offset + j)
            END DO
            value_type = TRANSFER(tmp_bytes, value_type)
            offset = offset + int_bytes

            SELECT CASE (value_type)
            CASE (IF_DATA_TYPE_INT)
                IF (offset + int_bytes - 1 > payload_size) THEN
                    status%status_code = IF_STATUS_INVALID
                    status%message = "Payload too small for int value in deserialize_skip_list_from_buffer"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF
                DO j = 1, int_bytes
                    tmp_bytes(j:j) = buffer(offset + j)
                END DO
                int_value = TRANSFER(tmp_bytes, int_value)
                offset = offset + int_bytes

                CALL skip_list_insert(data_id, key, IF_DATA_TYPE_INT, int_value, 0.0, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            CASE (IF_DATA_TYPE_DP)
                IF (offset + real_bytes - 1 > payload_size) THEN
                    status%status_code = IF_STATUS_INVALID
                    status%message = "Payload too small for real value in deserialize_skip_list_from_buffer"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF
                DO j = 1, real_bytes
                    tmp_bytes(j:j) = buffer(offset + j)
                END DO
                real_value = TRANSFER(tmp_bytes, real_value)
                offset = offset + real_bytes

                CALL skip_list_insert(data_id, key, IF_DATA_TYPE_DP, 0, real_value, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            CASE (IF_DATA_TYPE_CHAR)
                IF (offset + char_len - 1 > payload_size) THEN
                    status%status_code = IF_STATUS_INVALID
                    status%message = "Payload too small for char value in deserialize_skip_list_from_buffer"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF
                DO j = 1, char_len
                    char_value(j:j) = buffer(offset + j)
                END DO
                offset = offset + char_len

                CALL skip_list_insert(data_id, key, IF_DATA_TYPE_CHAR, 0, 0.0, TRIM(char_value), status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            CASE DEFAULT
                status%status_code = IF_STATUS_INVALID
                status%message = "Unsupported value_type in deserialize_skip_list_from_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END SELECT
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE deserialize_skip_list_from_buffer

    SUBROUTINE serialize_graph_to_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), ALLOCATABLE, INTENT(OUT) :: buffer(:)
        INTEGER(i4), INTENT(OUT) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, num_edges
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: real_bytes
        INTEGER(i4) :: node_id, edge_count, i
        INTEGER(i4) :: alloc_status
        INTEGER(i4) :: offset
        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)
        CHARACTER(LEN=32) :: tmp_bytes
        REAL :: weight_tmp

        CALL init_error_status(status)
        payload_size = 0

        CALL get_graph_size(data_id, num_nodes, num_edges, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_graph_size failed in serialize_graph_to_buffer for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(num_nodes) / 8
        weight_tmp = 0.0
        real_bytes = STORAGE_SIZE(weight_tmp) / 8

        payload_size = 2*int_bytes

        DO node_id = 1, num_nodes
            CALL graph_get_edges(data_id, node_id, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "graph_get_edges failed in serialize_graph_to_buffer for node="//TRIM(WRITE_INT(node_id)))
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                RETURN
            END IF

            payload_size = payload_size + int_bytes + edge_count*(2*int_bytes + real_bytes)

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        ALLOCATE(buffer(payload_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate buffer in serialize_graph_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        tmp_bytes = TRANSFER(num_nodes, tmp_bytes)
        DO i = 1, int_bytes
            buffer(i) = tmp_bytes(i:i)
        END DO

        tmp_bytes = TRANSFER(num_edges, tmp_bytes)
        DO i = 1, int_bytes
            buffer(int_bytes + i) = tmp_bytes(i:i)
        END DO

        offset = 2*int_bytes

        DO node_id = 1, num_nodes
            CALL graph_get_edges(data_id, node_id, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "graph_get_edges failed in serialize_graph_to_buffer (second pass) for node="//TRIM(WRITE_INT(node_id)))
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                RETURN
            END IF

            tmp_bytes = TRANSFER(edge_count, tmp_bytes)
            DO i = 1, int_bytes
                buffer(offset + i) = tmp_bytes(i:i)
            END DO
            offset = offset + int_bytes

            DO i = 1, edge_count
                tmp_bytes = TRANSFER(node_id, tmp_bytes)
                CALL copy_int_bytes_to_buffer(tmp_bytes, int_bytes, buffer, offset)
                offset = offset + int_bytes

                tmp_bytes = TRANSFER(edges(i)%to_node, tmp_bytes)
                CALL copy_int_bytes_to_buffer(tmp_bytes, int_bytes, buffer, offset)
                offset = offset + int_bytes

                tmp_bytes = TRANSFER(edges(i)%weight, tmp_bytes)
                CALL copy_real_bytes_to_buffer(tmp_bytes, real_bytes, buffer, offset)
                offset = offset + real_bytes
            END DO

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE serialize_graph_to_buffer

    SUBROUTINE deserialize_graph_from_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), INTENT(IN)  :: buffer(:)
        INTEGER(i4), INTENT(IN) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, num_edges
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: real_bytes
        INTEGER(i4) :: offset
        INTEGER(i4) :: i, j
        CHARACTER(LEN=32) :: tmp_bytes
        INTEGER(i4) :: node_loop
        INTEGER(i4) :: edge_count
        INTEGER(i4) :: from_node, to_node
        REAL    :: weight

        CALL init_error_status(status)

        IF (payload_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative payload_size in deserialize_graph_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(num_nodes) / 8
        real_bytes = STORAGE_SIZE(weight) / 8

        IF (payload_size < 2*int_bytes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small in deserialize_graph_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, int_bytes
            tmp_bytes(i:i) = buffer(i)
        END DO
        num_nodes = TRANSFER(tmp_bytes, num_nodes)

        DO i = 1, int_bytes
            tmp_bytes(i:i) = buffer(int_bytes + i)
        END DO
        num_edges = TRANSFER(tmp_bytes, num_edges)

        IF (num_nodes < 0 .OR. num_edges < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative num_nodes or num_edges in deserialize_graph_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_graph(data_id, "var_"//TRIM(data_id), num_nodes, status, &
                          is_directed=.FALSE., is_weighted=.TRUE.)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO node_loop = 1, num_nodes
            CALL graph_add_node(data_id, node_loop, IF_DATA_TYPE_INT, node_loop*10, 0.0, " ", status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        offset = 2*int_bytes

        DO node_loop = 1, num_nodes
            IF (offset + int_bytes - 1 > payload_size) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Payload too small for edge_count in deserialize_graph_from_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            DO i = 1, int_bytes
                tmp_bytes(i:i) = buffer(offset + i)
            END DO
            edge_count = TRANSFER(tmp_bytes, edge_count)
            offset = offset + int_bytes

            DO i = 1, edge_count
                IF (offset + 2*int_bytes + real_bytes - 1 > payload_size) THEN
                    status%status_code = IF_STATUS_INVALID
                    status%message = "Payload too small for edge data in deserialize_graph_from_buffer"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF

                DO j = 1, int_bytes
                    tmp_bytes(j:j) = buffer(offset + j)
                END DO
                from_node = TRANSFER(tmp_bytes, from_node)
                offset = offset + int_bytes

                DO j = 1, int_bytes
                    tmp_bytes(j:j) = buffer(offset + j)
                END DO
                to_node = TRANSFER(tmp_bytes, to_node)
                offset = offset + int_bytes

                DO j = 1, real_bytes
                    tmp_bytes(j:j) = buffer(offset + j)
                END DO
                weight = TRANSFER(tmp_bytes, weight)
                offset = offset + real_bytes

                IF (from_node <= to_node) THEN
                    CALL graph_add_edge(data_id, from_node, to_node, weight, " ", status)
                    IF (status%status_code /= IF_STATUS_OK) RETURN
                END IF
            END DO
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE deserialize_graph_from_buffer

    SUBROUTINE serialize_adjacency_to_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), ALLOCATABLE, INTENT(OUT) :: buffer(:)
        INTEGER(i4), INTENT(OUT) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, total_edges
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: real_bytes
        INTEGER(i4) :: node_id, edge_count, i
        INTEGER(i4) :: alloc_status
        INTEGER(i4) :: offset
        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)
        CHARACTER(LEN=32) :: tmp_bytes
        REAL :: weight_tmp

        CALL init_error_status(status)
        payload_size = 0

        CALL get_adjacency_list_size(data_id, num_nodes, total_edges, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "get_adjacency_list_size failed in serialize_adjacency_to_buffer for data_id='"//TRIM(data_id)//"'")
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(num_nodes) / 8
        weight_tmp = 0.0
        real_bytes = STORAGE_SIZE(weight_tmp) / 8

        IF (num_nodes < 0 .OR. total_edges < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative num_nodes or total_edges in serialize_adjacency_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        payload_size = 2*int_bytes + total_edges * (2*int_bytes + real_bytes)

        IF (payload_size <= 0) THEN
            ALLOCATE(buffer(0), STAT=alloc_status)
            IF (alloc_status /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Failed to allocate empty buffer in serialize_adjacency_to_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
            END IF
            RETURN
        END IF

        ALLOCATE(buffer(payload_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate buffer in serialize_adjacency_to_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        tmp_bytes = TRANSFER(num_nodes, tmp_bytes)
        DO i = 1, int_bytes
            buffer(i) = tmp_bytes(i:i)
        END DO

        tmp_bytes = TRANSFER(total_edges, tmp_bytes)
        DO i = 1, int_bytes
            buffer(int_bytes + i) = tmp_bytes(i:i)
        END DO

        offset = 2*int_bytes

        DO node_id = 1, num_nodes
            CALL adjacency_list_get_edges(data_id, node_id, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructFileManager", &
                    "adjacency_list_get_edges failed in serialize_adjacency_to_buffer for node="//TRIM(WRITE_INT(node_id)))
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                RETURN
            END IF

            DO i = 1, edge_count
                tmp_bytes = TRANSFER(node_id, tmp_bytes)
                CALL copy_int_bytes_to_buffer(tmp_bytes, int_bytes, buffer, offset)
                offset = offset + int_bytes

                tmp_bytes = TRANSFER(edges(i)%to_node, tmp_bytes)
                CALL copy_int_bytes_to_buffer(tmp_bytes, int_bytes, buffer, offset)
                offset = offset + int_bytes

                tmp_bytes = TRANSFER(edges(i)%weight, tmp_bytes)
                CALL copy_real_bytes_to_buffer(tmp_bytes, real_bytes, buffer, offset)
                offset = offset + real_bytes
            END DO

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE serialize_adjacency_to_buffer

    SUBROUTINE deserialize_adjacency_from_buffer(data_id, buffer, payload_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=1), INTENT(IN)  :: buffer(:)
        INTEGER(i4), INTENT(IN) :: payload_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, total_edges
        INTEGER(i4) :: int_bytes
        INTEGER(i4) :: real_bytes
        INTEGER(i4) :: offset
        INTEGER(i4) :: i
        CHARACTER(LEN=32) :: tmp_bytes
        INTEGER(i4) :: from_node, to_node
        REAL    :: weight
        INTEGER(i4) :: edge_index

        CALL init_error_status(status)

        IF (payload_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative payload_size in deserialize_adjacency_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        int_bytes = STORAGE_SIZE(num_nodes) / 8
        real_bytes = STORAGE_SIZE(weight) / 8

        IF (payload_size < 2*int_bytes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small in deserialize_adjacency_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, int_bytes
            tmp_bytes(i:i) = buffer(i)
        END DO
        num_nodes = TRANSFER(tmp_bytes, num_nodes)

        DO i = 1, int_bytes
            tmp_bytes(i:i) = buffer(int_bytes + i)
        END DO
        total_edges = TRANSFER(tmp_bytes, total_edges)

        IF (num_nodes < 0 .OR. total_edges < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative num_nodes or total_edges in deserialize_adjacency_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (payload_size < 2*int_bytes + total_edges*(2*int_bytes + real_bytes)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Payload too small for adjacency entries in deserialize_adjacency_from_buffer"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_adjacency_list(data_id, "var_"//TRIM(data_id), num_nodes, .TRUE., status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        offset = 2*int_bytes

        DO edge_index = 1, total_edges
            IF (offset + 2*int_bytes + real_bytes - 1 > payload_size) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Payload too small for adjacency entry in deserialize_adjacency_from_buffer"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            DO i = 1, int_bytes
                tmp_bytes(i:i) = buffer(offset + i)
            END DO
            from_node = TRANSFER(tmp_bytes, from_node)
            offset = offset + int_bytes

            DO i = 1, int_bytes
                tmp_bytes(i:i) = buffer(offset + i)
            END DO
            to_node = TRANSFER(tmp_bytes, to_node)
            offset = offset + int_bytes

            DO i = 1, real_bytes
                tmp_bytes(i:i) = buffer(offset + i)
            END DO
            weight = TRANSFER(tmp_bytes, weight)
            offset = offset + real_bytes

            CALL adjacency_list_add_edge(data_id, from_node, to_node, weight, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE deserialize_adjacency_from_buffer

    SUBROUTINE copy_int_bytes_to_buffer(src_bytes, num_bytes, dest_buffer, offset)
        CHARACTER(LEN=*), INTENT(IN)  :: src_bytes
        INTEGER(i4), INTENT(IN) :: num_bytes
        CHARACTER(LEN=1), INTENT(INOUT) :: dest_buffer(:)
        INTEGER(i4), INTENT(IN) :: offset

        INTEGER(i4) :: j

        DO j = 1, num_bytes
            dest_buffer(offset + j) = src_bytes(j:j)
        END DO
    END SUBROUTINE copy_int_bytes_to_buffer

    SUBROUTINE copy_real_bytes_to_buffer(src_bytes, num_bytes, dest_buffer, offset)
        CHARACTER(LEN=*), INTENT(IN)  :: src_bytes
        INTEGER(i4), INTENT(IN) :: num_bytes
        CHARACTER(LEN=1), INTENT(INOUT) :: dest_buffer(:)
        INTEGER(i4), INTENT(IN) :: offset

        INTEGER(i4) :: j

        DO j = 1, num_bytes
            dest_buffer(offset + j) = src_bytes(j:j)
        END DO
    END SUBROUTINE copy_real_bytes_to_buffer

    SUBROUTINE clear_chunk_table()
        INTEGER(i4) :: i

        chunk_count = 0
        DO i = 1, IF_MAX_CHUNKS
            chunk_table(i)%is_valid = .FALSE.
        END DO
    END SUBROUTINE clear_chunk_table

    SUBROUTINE register_single_chunk(data_id, file_path, unstruct_type, mem_size, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(IN) :: unstruct_type
        INTEGER(KIND=8),  INTENT(IN) :: mem_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx

        CALL init_error_status(status)

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in register_single_chunk"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (chunk_count >= IF_MAX_CHUNKS) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Chunk metadata table is full"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        chunk_count = chunk_count + 1
        idx = chunk_count

        chunk_table(idx)%file_path = ""
        chunk_table(idx)%file_path = TRIM(file_path)
        chunk_table(idx)%data_id   = ""
        chunk_table(idx)%data_id   = TRIM(data_id)
        chunk_table(idx)%chunk_id  = 1
        chunk_table(idx)%file_offset = 0_8
        chunk_table(idx)%chunk_size  = mem_size
        chunk_table(idx)%unstruct_type = unstruct_type
        chunk_table(idx)%is_valid = .TRUE.

        ! Also register into the generic chunk manager so that higher-level
        ! components can query chunk layout via a shared abstraction.
        CALL register_chunk_in_generic_mgr(data_id, file_path, mem_size, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_error("UnstructFileManager", &
                "gcm_register_chunk failed in register_single_chunk")
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE register_single_chunk

    SUBROUTINE register_chunk_in_generic_mgr(data_id, file_path, mem_size, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(KIND=8),  INTENT(IN) :: mem_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(GenericChunkMetaType) :: meta

        CALL init_error_status(status)

        meta%logical_id  = ""
        meta%logical_id  = TRIM(data_id)
        meta%file_path   = ""
        meta%file_path   = TRIM(file_path)
        meta%chunk_id    = 1
        meta%file_offset = 0_8
        meta%chunk_size  = mem_size
        meta%node_id     = 0
        meta%is_valid    = .TRUE.

        CALL gcm_register_chunk(meta, status)
    END SUBROUTINE register_chunk_in_generic_mgr

    SUBROUTINE ufm_get_chunks(data_id, chunks, count, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ChunkMetaType), ALLOCATABLE, INTENT(OUT) :: chunks(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(GenericChunkMetaType), ALLOCATABLE :: gchunks(:)
        TYPE(ErrorStatusType) :: gstatus
        INTEGER(i4) :: i, alloc_status

        CALL init_error_status(status)
        count = 0
        IF (ALLOCATED(chunks)) DEALLOCATE(chunks)

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in ufm_get_chunks"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        ! Delegate lookup to GenericChunkManager. Preserve original semantics:
        ! if no chunks are found, return IF_STATUS_OK with count=0.
        CALL gcm_get_chunks(TRIM(data_id), gchunks, count, gstatus)

        IF (gstatus%status_code /= IF_STATUS_OK) THEN
            IF (gstatus%status_code == IF_STATUS_NOT_FOUND) THEN
                status%status_code = IF_STATUS_OK
                count = 0
                IF (ALLOCATED(gchunks)) DEALLOCATE(gchunks)
                RETURN
            ELSE
                status = gstatus
                CALL log_error("UnstructFileManager", &
                    "gcm_get_chunks failed in ufm_get_chunks: "//TRIM(gstatus%message))
                IF (ALLOCATED(gchunks)) DEALLOCATE(gchunks)
                RETURN
            END IF
        END IF

        IF (count <= 0) THEN
            IF (ALLOCATED(gchunks)) DEALLOCATE(gchunks)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(chunks(count), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate chunks array in ufm_get_chunks"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(gchunks)) DEALLOCATE(gchunks)
            RETURN
        END IF

        DO i = 1, count
            chunks(i)%file_path   = gchunks(i)%file_path
            chunks(i)%data_id     = gchunks(i)%logical_id
            chunks(i)%chunk_id    = gchunks(i)%chunk_id
            chunks(i)%file_offset = gchunks(i)%file_offset
            chunks(i)%chunk_size  = gchunks(i)%chunk_size
            chunks(i)%unstruct_type = 0
            chunks(i)%is_valid    = gchunks(i)%is_valid
        END DO

        IF (ALLOCATED(gchunks)) DEALLOCATE(gchunks)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE ufm_get_chunks

    SUBROUTINE ufm_clear_cache(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        header_cache_count = 0
        DO i = 1, IF_HEADER_CACHE_CAPACITY
            header_cache(i)%file_path     = ""
            header_cache(i)%data_id       = ""
            header_cache(i)%unstruct_type = 0
            header_cache(i)%mem_size      = 0_8
            header_cache(i)%is_valid      = .FALSE.
        END DO

        cache_hits     = 0_8
        cache_misses   = 0_8
        cache_requests = 0_8
    END SUBROUTINE ufm_clear_cache

    SUBROUTINE ufm_get_cache_stats(hits, misses, requests, status)
        INTEGER(KIND=8), INTENT(OUT) :: hits
        INTEGER(KIND=8), INTENT(OUT) :: misses
        INTEGER(KIND=8), INTENT(OUT) :: requests
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        hits     = cache_hits
        misses   = cache_misses
        requests = cache_requests
    END SUBROUTINE ufm_get_cache_stats

    SUBROUTINE clear_data_file_map()
        INTEGER(i4) :: i

        data_file_map_count = 0
        DO i = 1, IF_DATA_FILE_MAP_CAPACITY
            data_file_map(i)%data_id   = ""
            data_file_map(i)%file_path = ""
            data_file_map(i)%is_valid  = .FALSE.
        END DO
    END SUBROUTINE clear_data_file_map

    SUBROUTINE ufm_register_data_file(data_id, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64)  :: did
        CHARACTER(LEN=256) :: fpath
        INTEGER(i4) :: i, found_index
        TYPE(DataFileMapEntryType) :: tmp_entry

        CALL init_error_status(status)

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in ufm_register_data_file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        did = ""
        did = TRIM(data_id)
        fpath = ""
        fpath = TRIM(file_path)

        IF (LEN_TRIM(did) == 0 .OR. LEN_TRIM(fpath) == 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        found_index = 0
        DO i = 1, data_file_map_count
            IF (data_file_map(i)%is_valid) THEN
                IF (TRIM(data_file_map(i)%data_id) == did) THEN
                    found_index = i
                    EXIT
                END IF
            END IF
        END DO

        IF (found_index > 0) THEN
            data_file_map(found_index)%file_path = fpath

            tmp_entry = data_file_map(found_index)
            IF (found_index > 1) THEN
                DO i = found_index, 2, -1
                    data_file_map(i) = data_file_map(i-1)
                END DO
                data_file_map(1) = tmp_entry
            END IF

            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        IF (data_file_map_count < IF_DATA_FILE_MAP_CAPACITY) THEN
            data_file_map_count = data_file_map_count + 1
        END IF

        DO i = data_file_map_count, 2, -1
            data_file_map(i) = data_file_map(i-1)
        END DO

        data_file_map(1)%data_id   = did
        data_file_map(1)%file_path = fpath
        data_file_map(1)%is_valid  = .TRUE.

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ufm_register_data_file

    SUBROUTINE ufm_find_data_file(data_id, file_path, found, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(OUT) :: file_path
        LOGICAL, INTENT(OUT) :: found
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=64) :: did
        INTEGER(i4) :: i, hit_index
        TYPE(DataFileMapEntryType) :: tmp_entry

        CALL init_error_status(status)
        file_path = ""
        found = .FALSE.

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in ufm_find_data_file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        did = ""
        did = TRIM(data_id)
        IF (LEN_TRIM(did) == 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        hit_index = 0
        DO i = 1, data_file_map_count
            IF (data_file_map(i)%is_valid) THEN
                IF (TRIM(data_file_map(i)%data_id) == did) THEN
                    hit_index = i
                    EXIT
                END IF
            END IF
        END DO

        IF (hit_index <= 0) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        tmp_entry = data_file_map(hit_index)
        IF (hit_index > 1) THEN
            DO i = hit_index, 2, -1
                data_file_map(i) = data_file_map(i-1)
            END DO
            data_file_map(1) = tmp_entry
        END IF

        file_path = data_file_map(1)%file_path
        found = .TRUE.

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ufm_find_data_file

    SUBROUTINE load_adjacency_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, total_edges
        INTEGER(i4) :: i, from_node, to_node
        REAL :: weight
        INTEGER(i4) :: ios

        CALL init_error_status(status)

        READ(unit, IOSTAT=ios) num_nodes
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read num_nodes in load_adjacency_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) total_edges
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read total_edges in load_adjacency_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_adjacency_list(data_id, "var_"//TRIM(data_id), num_nodes, .TRUE., status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, total_edges
            READ(unit, IOSTAT=ios) from_node
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read from_node in load_adjacency_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            READ(unit, IOSTAT=ios) to_node
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read to_node in load_adjacency_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            READ(unit, IOSTAT=ios) weight
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read weight in load_adjacency_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            CALL adjacency_list_add_edge(data_id, from_node, to_node, weight, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_adjacency_payload_binary

    SUBROUTINE load_linked_list_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: list_size
        INTEGER(i4) :: i, value
        INTEGER(i4) :: ios

        CALL init_error_status(status)

        READ(unit, IOSTAT=ios) list_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read list_size in load_linked_list_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_linked_list(data_id, "var_"//TRIM(data_id), status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, list_size
            READ(unit, IOSTAT=ios) value
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read value in load_linked_list_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            CALL linked_list_insert(data_id, value, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_linked_list_payload_binary

    SUBROUTINE load_hash_table_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: entry_count
        INTEGER(i4) :: i, value
        CHARACTER(LEN=64) :: key
        INTEGER(i4) :: ios
        INTEGER(i4) :: initial_capacity

        CALL init_error_status(status)

        READ(unit, IOSTAT=ios) entry_count
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read entry_count in load_hash_table_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        initial_capacity = MAX(16, entry_count*2)
        CALL create_hash_table(data_id, "var_"//TRIM(data_id), initial_capacity=initial_capacity, status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, entry_count
            READ(unit, IOSTAT=ios) key
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read key in load_hash_table_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            READ(unit, IOSTAT=ios) value
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read value in load_hash_table_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            CALL hash_table_insert(data_id, TRIM(key), value, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_hash_table_payload_binary

    SUBROUTINE load_skip_list_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: count
        INTEGER(i4) :: i
        INTEGER(i4) :: key
        INTEGER(i4) :: value_type
        INTEGER(i4) :: int_value
        REAL :: real_value
        CHARACTER(LEN=64) :: char_value
        INTEGER(i4) :: ios

        CALL init_error_status(status)

        READ(unit, IOSTAT=ios) count
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read count in load_skip_list_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_skip_list(data_id, "var_"//TRIM(data_id), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, count
            READ(unit, IOSTAT=ios) key
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read key in load_skip_list_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            READ(unit, IOSTAT=ios) value_type
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read value_type in load_skip_list_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            READ(unit, IOSTAT=ios) int_value
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read int_value in load_skip_list_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            READ(unit, IOSTAT=ios) real_value
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read real_value in load_skip_list_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            READ(unit, IOSTAT=ios) char_value
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read char_value in load_skip_list_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            CALL skip_list_insert(data_id, key, value_type, int_value, real_value, TRIM(char_value), status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_skip_list_payload_binary

    SUBROUTINE load_graph_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, num_edges
        INTEGER(i4) :: node_loop
        INTEGER(i4) :: edge_count, i
        INTEGER(i4) :: from_node, to_node
        REAL :: weight
        INTEGER(i4) :: ios

        CALL init_error_status(status)

        READ(unit, IOSTAT=ios) num_nodes
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read num_nodes in load_graph_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) num_edges
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read num_edges in load_graph_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_graph(data_id, "var_"//TRIM(data_id), num_nodes, status, &
                          is_directed=.FALSE., is_weighted=.TRUE.)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO node_loop = 1, num_nodes
            CALL graph_add_node(data_id, node_loop, IF_DATA_TYPE_INT, node_loop*10, 0.0, " ", status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        DO node_loop = 1, num_nodes
            READ(unit, IOSTAT=ios) edge_count
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read edge_count in load_graph_payload_binary"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            DO i = 1, edge_count
                READ(unit, IOSTAT=ios) from_node
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read from_node in load_graph_payload_binary"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF

                READ(unit, IOSTAT=ios) to_node
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read to_node in load_graph_payload_binary"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF

                READ(unit, IOSTAT=ios) weight
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read weight in load_graph_payload_binary"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF

                !  ?write  ?? from_node <= to_node  ??
                !   num_edges  ??
                IF (from_node <= to_node) THEN
                    CALL graph_add_edge(data_id, from_node, to_node, weight, " ", status)
                    IF (status%status_code /= IF_STATUS_OK) RETURN
                END IF
            END DO
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_graph_payload_binary

    SUBROUTINE load_queue_payload_with_filter(unit, data_id, io_flags, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: processed_size
        INTEGER(i4) :: ios
        CHARACTER(LEN=1), ALLOCATABLE :: processed_buffer(:)
        CHARACTER(LEN=1), ALLOCATABLE :: plain_buffer(:)
        INTEGER(i4) :: plain_size
        INTEGER(i4) :: alloc_status
        TYPE(ErrorStatusType) :: filter_status

        CALL init_error_status(status)

        IF (.NOT. ASSOCIATED(active_read_filter) .OR. io_flags == 0) THEN
            CALL load_queue_payload_binary(unit, data_id, status)
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_size in load_queue_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Negative processed_size in load_queue_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        IF (processed_size == 0) THEN
            CALL create_queue(data_id, "var_"//TRIM(data_id), 1, status, is_circular=.TRUE.)
            RETURN
        END IF

        ALLOCATE(processed_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate processed_buffer in load_queue_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) processed_buffer
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read processed_buffer in load_queue_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        ALLOCATE(plain_buffer(processed_size), STAT=alloc_status)
        IF (alloc_status /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            status%message = "Failed to allocate plain_buffer in load_queue_payload_with_filter"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            RETURN
        END IF

        CALL active_read_filter(processed_buffer, processed_size, plain_buffer, plain_size, io_flags, filter_status)
        IF (filter_status%status_code /= IF_STATUS_OK) THEN
            status = filter_status
            IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
            IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
            RETURN
        END IF

        CALL deserialize_queue_from_buffer(data_id, plain_buffer, plain_size, status)

        IF (ALLOCATED(processed_buffer)) DEALLOCATE(processed_buffer)
        IF (ALLOCATED(plain_buffer)) DEALLOCATE(plain_buffer)
    END SUBROUTINE load_queue_payload_with_filter

    SUBROUTINE load_queue_payload_binary(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: data_type
        INTEGER(i4) :: count
        INTEGER(i4) :: ios
        INTEGER(i4) :: i
        INTEGER(i4) :: int_value
        REAL :: real_value
        CHARACTER(LEN=64) :: char_value
        INTEGER(i4) :: capacity

        CALL init_error_status(status)

        READ(unit, IOSTAT=ios) data_type
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read data_type in load_queue_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, IOSTAT=ios) count
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read count in load_queue_payload_binary"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        capacity = MAX(1, count)
        CALL create_queue(data_id, "var_"//TRIM(data_id), capacity, status, is_circular=.TRUE.)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            DO i = 1, count
                READ(unit, IOSTAT=ios) int_value
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read int_value in load_queue_payload_binary"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF

                CALL queue_enqueue(data_id, data_type, int_value, 0.0, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        CASE (IF_DATA_TYPE_DP)
            DO i = 1, count
                READ(unit, IOSTAT=ios) real_value
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read real_value in load_queue_payload_binary"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF

                CALL queue_enqueue(data_id, data_type, 0, real_value, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        CASE (IF_DATA_TYPE_CHAR)
            DO i = 1, count
                READ(unit, IOSTAT=ios) char_value
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read char_value in load_queue_payload_binary"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF

                CALL queue_enqueue(data_id, data_type, 0, 0.0, TRIM(char_value), status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_queue_payload_binary

    SUBROUTINE load_adjacency_payload_text(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, total_edges
        INTEGER(i4) :: from_node, to_node
        REAL :: weight
        INTEGER(i4) :: ios, edge_count
        CHARACTER(LEN=256) :: line
        INTEGER(i4) :: eq_pos

        CALL init_error_status(status)

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read num_nodes line in load_adjacency_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid num_nodes line format in load_adjacency_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) num_nodes
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse num_nodes in load_adjacency_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read total_edges line in load_adjacency_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid total_edges line format in load_adjacency_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) total_edges
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse total_edges in load_adjacency_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_adjacency_list(data_id, "var_"//TRIM(data_id), num_nodes, .TRUE., status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        edge_count = 0
        DO edge_count = 1, total_edges
            READ(unit, *, IOSTAT=ios) from_node, to_node, weight
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read edge line in load_adjacency_payload_text"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF
            CALL adjacency_list_add_edge(data_id, from_node, to_node, weight, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_adjacency_payload_text

    SUBROUTINE load_linked_list_payload_text(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: list_size, i, value
        INTEGER(i4) :: ios, eq_pos
        CHARACTER(LEN=256) :: line

        CALL init_error_status(status)

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read list_size line in load_linked_list_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid list_size line format in load_linked_list_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) list_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse list_size in load_linked_list_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_linked_list(data_id, "var_"//TRIM(data_id), status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, list_size
            READ(unit, *, IOSTAT=ios) value
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read list element in load_linked_list_payload_text"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF
            CALL linked_list_insert(data_id, value, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_linked_list_payload_text

    SUBROUTINE load_hash_table_payload_text(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: entry_count, i, value, ios, eq_pos, initial_capacity
        CHARACTER(LEN=64) :: key
        CHARACTER(LEN=256) :: line

        CALL init_error_status(status)

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read hash_entries line in load_hash_table_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid hash_entries line format in load_hash_table_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) entry_count
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse hash_entries in load_hash_table_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        initial_capacity = MAX(16, entry_count*2)
        CALL create_hash_table(data_id, "var_"//TRIM(data_id), initial_capacity=initial_capacity, status=status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, entry_count
            READ(unit, *, IOSTAT=ios) key, value
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read hash entry line in load_hash_table_payload_text"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF
            CALL hash_table_insert(data_id, TRIM(key), value, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_hash_table_payload_text

    SUBROUTINE load_skip_list_payload_text(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: count, i, ios, ios_line, eq_pos
        INTEGER(i4) :: key, value_type, int_value
        REAL :: real_value
        CHARACTER(LEN=64) :: char_value
        CHARACTER(LEN=256) :: line

        CALL init_error_status(status)

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read skip_list_size line in load_skip_list_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid skip_list_size line format in load_skip_list_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) count
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse skip_list_size in load_skip_list_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_skip_list(data_id, "var_"//TRIM(data_id), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, count
            READ(unit, '(A)', IOSTAT=ios) line
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read skip_list data line in load_skip_list_payload_text"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            char_value = ""
            READ(line, *, IOSTAT=ios) key, value_type, int_value, real_value, char_value
            IF (ios /= 0) THEN
                char_value = ""
                READ(line, *, IOSTAT=ios_line) key, value_type, int_value, real_value
                IF (ios_line /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to parse skip_list data line in load_skip_list_payload_text"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF
            END IF

            CALL skip_list_insert(data_id, key, value_type, int_value, real_value, TRIM(char_value), status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_skip_list_payload_text

    SUBROUTINE load_graph_payload_text(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: num_nodes, num_edges
        INTEGER(i4) :: from_node, to_node, edge_index
        REAL :: weight
        INTEGER(i4) :: ios, eq_pos
        CHARACTER(LEN=256) :: line

        CALL init_error_status(status)

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read num_nodes line in load_graph_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid num_nodes line format in load_graph_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) num_nodes
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse num_nodes in load_graph_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read num_edges line in load_graph_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid num_edges line format in load_graph_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) num_edges
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse num_edges in load_graph_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL create_graph(data_id, "var_"//TRIM(data_id), num_nodes, status, &
                          is_directed=.FALSE., is_weighted=.TRUE.)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO from_node = 1, num_nodes
            CALL graph_add_node(data_id, from_node, IF_DATA_TYPE_INT, from_node*10, 0.0, " ", status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        DO edge_index = 1, num_edges
            READ(unit, *, IOSTAT=ios) from_node, to_node, weight
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Failed to read edge line in load_graph_payload_text"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            IF (from_node <= to_node) THEN
                CALL graph_add_edge(data_id, from_node, to_node, weight, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END IF
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_graph_payload_text

    SUBROUTINE load_queue_payload_text(unit, data_id, status)
        INTEGER(i4), INTENT(IN) :: unit
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: queue_size, data_type, i, ios, eq_pos, capacity
        INTEGER(i4) :: int_value
        REAL :: real_value
        CHARACTER(LEN=64) :: char_value
        CHARACTER(LEN=256) :: line

        CALL init_error_status(status)

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read queue_size line in load_queue_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid queue_size line format in load_queue_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) queue_size
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse queue_size in load_queue_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to read queue_type line in load_queue_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        eq_pos = INDEX(line, "=")
        IF (eq_pos <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid queue_type line format in load_queue_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF
        READ(line(eq_pos+1:), *, IOSTAT=ios) data_type
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to parse queue_type in load_queue_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        capacity = MAX(1, queue_size)
        CALL create_queue(data_id, "var_"//TRIM(data_id), capacity, status, is_circular=.TRUE.)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        SELECT CASE (data_type)
        CASE (IF_DATA_TYPE_INT)
            DO i = 1, queue_size
                READ(unit, *, IOSTAT=ios) int_value
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read int queue element in load_queue_payload_text"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF
                CALL queue_enqueue(data_id, data_type, int_value, 0.0, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        CASE (IF_DATA_TYPE_DP)
            DO i = 1, queue_size
                READ(unit, *, IOSTAT=ios) real_value
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read real queue element in load_queue_payload_text"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF
                CALL queue_enqueue(data_id, data_type, 0, real_value, " ", status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        CASE (IF_DATA_TYPE_CHAR)
            DO i = 1, queue_size
                READ(unit, *, IOSTAT=ios) char_value
                IF (ios /= 0) THEN
                    status%status_code = IF_STATUS_IO_ERROR
                    status%message = "Failed to read char queue element in load_queue_payload_text"
                    CALL log_error("UnstructFileManager", TRIM(status%message))
                    RETURN
                END IF
                CALL queue_enqueue(data_id, data_type, 0, 0.0, TRIM(char_value), status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END DO
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported data_type in load_queue_payload_text"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE load_queue_payload_text

    FUNCTION WRITE_INT(value) RESULT(str)
        INTEGER(i4), INTENT(IN) :: value
        CHARACTER(LEN=32) :: str
        WRITE(str, '(I0)') value
    END FUNCTION WRITE_INT

    SUBROUTINE ufm_migrate_data_file(data_id, new_file_path, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=*), INTENT(IN)  :: new_file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=256) :: old_file_path
        LOGICAL :: found
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: unit_in, unit_out, ios
        INTEGER(KIND=8) :: file_size, bytes_remaining
        INTEGER(i4), PARAMETER :: IF_BUFFER_BYTES = 65536
        CHARACTER(LEN=1) :: buffer(IF_BUFFER_BYTES)
        INTEGER(i4) :: read_count

        CALL init_error_status(status)

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in ufm_migrate_data_file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        CALL ufm_find_data_file(data_id, old_file_path, found, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        IF (.NOT. found) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Data file not found for data_id='"//TRIM(data_id)//"' in ufm_migrate_data_file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        INQUIRE(FILE=TRIM(old_file_path), SIZE=file_size, IOSTAT=ios)
        IF (ios /= 0 .OR. file_size < 0_8) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = "Failed to get source file size in ufm_migrate_data_file"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        unit_in = 101
        OPEN(UNIT=unit_in, FILE=TRIM(old_file_path), STATUS='OLD', &
             ACCESS='STREAM', FORM='UNFORMATTED', ACTION='READ', IOSTAT=ios)
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to open source file in ufm_migrate_data_file (iostat=", ios, ")"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        unit_out = 102
        OPEN(UNIT=unit_out, FILE=TRIM(new_file_path), STATUS='REPLACE', &
             ACCESS='STREAM', FORM='UNFORMATTED', ACTION='WRITE', IOSTAT=ios)
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to open destination file in ufm_migrate_data_file (iostat=", ios, ")"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            CLOSE(unit_in)
            RETURN
        END IF

        bytes_remaining = file_size

        DO WHILE (bytes_remaining > 0_8)
            IF (bytes_remaining < INT(IF_BUFFER_BYTES, KIND=8)) THEN
                read_count = INT(bytes_remaining)
            ELSE
                read_count = IF_BUFFER_BYTES
            END IF

            READ(unit_in, IOSTAT=ios) buffer(1:read_count)
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Error reading source file in ufm_migrate_data_file"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                CLOSE(unit_in)
                CLOSE(unit_out)
                RETURN
            END IF

            WRITE(unit_out, IOSTAT=ios) buffer(1:read_count)
            IF (ios /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = "Error writing destination file in ufm_migrate_data_file"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                CLOSE(unit_in)
                CLOSE(unit_out)
                RETURN
            END IF

            bytes_remaining = bytes_remaining - INT(read_count, KIND=8)
        END DO

        CLOSE(unit_in)
        CLOSE(unit_out)

        CALL ufm_register_data_file(data_id, new_file_path, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        CALL log_info("UnstructFileManager", &
            "Migrated data file for data_id='"//TRIM(data_id)//"' to "//TRIM(new_file_path))

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ufm_migrate_data_file

    SUBROUTINE ufm_preload_data_list(data_ids, num_ids, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_ids(:)
        INTEGER(i4), INTENT(IN) :: num_ids
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i
        CHARACTER(LEN=256) :: file_path
        LOGICAL :: found
        TYPE(ErrorStatusType) :: local_status
        CHARACTER(LEN=64) :: loaded_id

        CALL init_error_status(status)

        IF (.NOT. ufm_initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured file manager not initialized in ufm_preload_data_list"
            CALL log_error("UnstructFileManager", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, num_ids
            CALL ufm_find_data_file(data_ids(i), file_path, found, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status%status_code = local_status%status_code
                status%message = "ufm_find_data_file failed in ufm_preload_data_list for data_id='"//TRIM(data_ids(i))//"'"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF

            IF (.NOT. found) CYCLE

            CALL ufm_load_unstruct_data(TRIM(file_path), loaded_id, local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                status%status_code = local_status%status_code
                status%message = "ufm_load_unstruct_data failed in ufm_preload_data_list for file='"//TRIM(file_path)//"'"
                CALL log_error("UnstructFileManager", TRIM(status%message))
                RETURN
            END IF
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ufm_preload_data_list

END MODULE IF_UnstructFile_Mgr