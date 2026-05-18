!===============================================================================
! MODULE: IF_IO_Backup
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Impl — unified backup/restore for structured and unstructured data
! BRIEF:  Backup/restore layer migrated from ufc_infra/14_BackupManager.
!===============================================================================

MODULE IF_IO_Backup
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_info, log_warn, log_error, &
        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_IO_ERROR, IF_STATUS_NOT_FOUND, IF_STATUS_MEM_ERROR
    USE IF_IO_StructFile, ONLY: &
        FileHandleType, DataBlockType, &
        sfm_open_file, sfm_close_file, sfm_write_data, sfm_read_data, &
        SFM_FORMAT_BINARY => IF_FORMAT_BINARY, SFM_FORMAT_TXT => IF_FORMAT_TXT, &
        IF_STATUS_SFILE_OK, IF_SFM_CHAR_RECORD_LEN
    USE IF_Mem_StructPool, ONLY: &
        get_unified_subarray_id_by_data_id, &
        get_struct_subarray_ptr_1d_int, get_struct_subarray_ptr_2d_int, &
        get_struct_subarray_ptr_3d_int, get_struct_subarray_ptr_4d_int, &
        get_struct_subarray_ptr_1d_dp,  get_struct_subarray_ptr_2d_dp,  &
        get_struct_subarray_ptr_3d_dp,  get_struct_subarray_ptr_4d_dp,  &
        get_struct_subarray_ptr_1d_char, get_struct_subarray_ptr_2d_char, &
        get_struct_subarray_ptr_3d_char, get_struct_subarray_ptr_4d_char
    USE IF_Base_StructMeta_Def, ONLY: &
        StructMetaType, struct_meta_query, struct_meta_update, &
        IF_STATUS_META_NOT_FOUND, struct_meta_try_query
    USE IF_Base_SymTbl, ONLY: &
        symbol_table_exists, get_variable_data_id, &
        IF_STORAGE_TYPE_STRUCTURED, IF_STORAGE_TYPE_UNSTRUCTURED, &
        IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR, &
        IF_DATA_TYPE_STRUCT, IF_DATA_TYPE_CLASS, &
        IF_DATA_TYPE_HASH, IF_DATA_TYPE_LINKED_LIST, IF_DATA_TYPE_ADJACENCY, &
        IF_DATA_TYPE_SKIP_LIST, IF_DATA_TYPE_GRAPH, IF_DATA_TYPE_QUEUE
    USE IF_UnstructFile_Mgr, ONLY: &
        ufm_write_unstruct_data, ufm_load_unstruct_data, &
        UFM_FORMAT_BINARY => IF_FORMAT_BINARY, UFM_FORMAT_TXT => IF_FORMAT_TXT
    USE IF_Mem_UnStructPool, ONLY: &
        delete_unstruct_data, unstruct_data_exists
    USE IF_Base_UnstructMeta_Def, ONLY: &
        UnstructMetaType, unstruct_meta_query, unstruct_meta_update, &
        IF_STATUS_UNSMETA_NOT_FOUND, unstruct_meta_try_query

    IMPLICIT NONE

    PRIVATE

    PUBLIC :: backup_data
    PUBLIC :: restore_data
    PUBLIC :: bm_get_meta, bm_backup_struct, bm_backup_unstruct
    PUBLIC :: bm_restore_struct, bm_restore_unstruct, bm_calculate_file_crc32

CONTAINS

    SUBROUTINE backup_data(var_name, backup_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: backup_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType)   :: struct_meta
        TYPE(UnstructMetaType) :: unstruct_meta
        TYPE(ErrorStatusType)  :: local_status
        LOGICAL :: has_struct_meta, has_unstruct_meta
        CHARACTER(LEN=512) :: backup_path

        CALL init_error_status(status)

        ! Query metadata to decide structured/unstructured path
        CALL bm_get_meta(var_name, struct_meta, unstruct_meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        has_struct_meta   = struct_meta%is_valid
        has_unstruct_meta = unstruct_meta%is_valid

        IF (.NOT. has_struct_meta .AND. .NOT. has_unstruct_meta) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Metadata for variable '"//TRIM(var_name)//"' is not valid in backup_data"
            CALL log_error("BackupManager", TRIM(status%message))
            RETURN
        END IF

        backup_path = TRIM(backup_id)//"_"//TRIM(var_name)//".bin"

        IF (has_struct_meta) THEN
            CALL bm_backup_struct(var_name, struct_meta, backup_path, local_status)
        ELSE
            CALL bm_backup_unstruct(var_name, unstruct_meta, backup_path, local_status)
        END IF

        status = local_status
    END SUBROUTINE backup_data

    SUBROUTINE bm_backup_struct(var_name, struct_meta, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(StructMetaType), INTENT(IN) :: struct_meta
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        TYPE(FileHandleType) :: file_handle
        TYPE(DataBlockType) :: data_block
        INTEGER(i4) :: crc32_value
        INTEGER(i4) :: subarray_id, dim1, dim2, dim3, dim4
        INTEGER(i4) :: dims(4)
        LOGICAL :: is_struct_or_class
        INTEGER, POINTER :: int_ptr(:)
        INTEGER, POINTER :: int_ptr_2d(:,:)
        INTEGER, POINTER :: int_ptr_3d(:,:,:)
        INTEGER, POINTER :: int_ptr_4d(:,:,:,:)
        DOUBLE PRECISION, POINTER :: dp_ptr_1d(:)
        DOUBLE PRECISION, POINTER :: dp_ptr_2d(:,:)
        DOUBLE PRECISION, POINTER :: dp_ptr_3d(:,:,:)
        DOUBLE PRECISION, POINTER :: dp_ptr_4d(:,:,:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: char_ptr_1d(:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: char_ptr_2d(:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: char_ptr_3d(:,:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: char_ptr_4d(:,:,:,:)
        INTEGER(i4) :: char_len

        CALL init_error_status(status)
        data_block%is_allocated = .FALSE.

        dims = struct_meta%dimensions
        is_struct_or_class = (struct_meta%data_type == IF_DATA_TYPE_STRUCT .OR. &
                              struct_meta%data_type == IF_DATA_TYPE_CLASS)

        ! Locate unified subarray for array-like structured variables
        IF (.NOT. is_struct_or_class) THEN
            CALL get_unified_subarray_id_by_data_id(TRIM(struct_meta%data_id), subarray_id, local_status)
            IF (local_status%status_code /= IF_STATUS_OK .OR. subarray_id <= 0) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Unified subarray for variable '"//TRIM(var_name)//"' not found in bm_backup_struct"
                CALL log_error("BackupManager", TRIM(status%message))
                RETURN
            END IF
        END IF

        ! Populate DataBlockType payload from unified memory for supported shapes
        SELECT CASE (struct_meta%data_type)
        CASE (IF_DATA_TYPE_INT)
            ! INT1D: dims = [N,0,0,0]
            IF (dims(2) == 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_1d_int(subarray_id, int_ptr, dim1, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(int_ptr)) THEN
                    ALLOCATE(data_block%int_data(dim1,1,1,1))
                    data_block%int_data(1:dim1,1,1,1) = int_ptr(1:dim1)
                    data_block%is_allocated = .TRUE.
                END IF
            ! INT2D: dims = [N1,N2,0,0]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_2d_int(subarray_id, int_ptr_2d, dim1, dim2, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(int_ptr_2d)) THEN
                    ALLOCATE(data_block%int_data(dim1,dim2,1,1))
                    data_block%int_data(1:dim1,1:dim2,1,1) = int_ptr_2d(1:dim1,1:dim2)
                    data_block%is_allocated = .TRUE.
                END IF
            ! INT3D: dims = [N1,N2,N3,0]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_3d_int(subarray_id, int_ptr_3d, dim1, dim2, dim3, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(int_ptr_3d)) THEN
                    ALLOCATE(data_block%int_data(dim1,dim2,dim3,1))
                    data_block%int_data(1:dim1,1:dim2,1:dim3,1) = int_ptr_3d(1:dim1,1:dim2,1:dim3)
                    data_block%is_allocated = .TRUE.
                END IF
            ! INT4D: dims = [N1,N2,N3,N4]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) > 0) THEN
                CALL get_struct_subarray_ptr_4d_int(subarray_id, int_ptr_4d, dim1, dim2, dim3, dim4, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(int_ptr_4d)) THEN
                    ALLOCATE(data_block%int_data(dim1,dim2,dim3,dim4))
                    data_block%int_data(1:dim1,1:dim2,1:dim3,1:dim4) = int_ptr_4d(1:dim1,1:dim2,1:dim3,1:dim4)
                    data_block%is_allocated = .TRUE.
                END IF
            END IF
        CASE (IF_DATA_TYPE_DP)
            ! DP1D: dims = [N,0,0,0]
            IF (dims(2) == 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_1d_dp(subarray_id, dp_ptr_1d, dim1, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(dp_ptr_1d)) THEN
                    ALLOCATE(data_block%real_data(dim1,1,1,1))
                    data_block%real_data(1:dim1,1,1,1) = dp_ptr_1d(1:dim1)
                    data_block%is_allocated = .TRUE.
                END IF
            ! DP2D: dims = [N1,N2,0,0]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_2d_dp(subarray_id, dp_ptr_2d, dim1, dim2, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(dp_ptr_2d)) THEN
                    ALLOCATE(data_block%real_data(dim1,dim2,1,1))
                    data_block%real_data(1:dim1,1:dim2,1,1) = dp_ptr_2d(1:dim1,1:dim2)
                    data_block%is_allocated = .TRUE.
                END IF
            ! DP3D: dims = [N1,N2,N3,0]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_3d_dp(subarray_id, dp_ptr_3d, dim1, dim2, dim3, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(dp_ptr_3d)) THEN
                    ALLOCATE(data_block%real_data(dim1,dim2,dim3,1))
                    data_block%real_data(1:dim1,1:dim2,1:dim3,1) = dp_ptr_3d(1:dim1,1:dim2,1:dim3)
                    data_block%is_allocated = .TRUE.
                END IF
            ! DP4D: dims = [N1,N2,N3,N4]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) > 0) THEN
                CALL get_struct_subarray_ptr_4d_dp(subarray_id, dp_ptr_4d, dim1, dim2, dim3, dim4, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(dp_ptr_4d)) THEN
                    ALLOCATE(data_block%real_data(dim1,dim2,dim3,dim4))
                    data_block%real_data(1:dim1,1:dim2,1:dim3,1:dim4) = dp_ptr_4d(1:dim1,1:dim2,1:dim3,1:dim4)
                    data_block%is_allocated = .TRUE.
                END IF
            END IF
        CASE (IF_DATA_TYPE_CHAR)
            ! CHAR1D: dims = [N,0,0,0]
            IF (dims(2) == 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_1d_char(subarray_id, char_ptr_1d, dim1, char_len, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(char_ptr_1d)) THEN
                    ALLOCATE(data_block%char_data(dim1,1,1,1))
                    data_block%char_data(1:dim1,1,1,1) = char_ptr_1d(1:dim1)
                    data_block%is_allocated = .TRUE.
                END IF
            ! CHAR2D: dims = [N1,N2,0,0]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_2d_char(subarray_id, char_ptr_2d, dim1, dim2, char_len, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(char_ptr_2d)) THEN
                    ALLOCATE(data_block%char_data(dim1,dim2,1,1))
                    data_block%char_data(1:dim1,1:dim2,1,1) = char_ptr_2d(1:dim1,1:dim2)
                    data_block%is_allocated = .TRUE.
                END IF
            ! CHAR3D: dims = [N1,N2,N3,0]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) == 0) THEN
                CALL get_struct_subarray_ptr_3d_char(subarray_id, char_ptr_3d, dim1, dim2, dim3, char_len, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(char_ptr_3d)) THEN
                    ALLOCATE(data_block%char_data(dim1,dim2,dim3,1))
                    data_block%char_data(1:dim1,1:dim2,1:dim3,1) = char_ptr_3d(1:dim1,1:dim2,1:dim3)
                    data_block%is_allocated = .TRUE.
                END IF
            ! CHAR4D: dims = [N1,N2,N3,N4]
            ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) > 0) THEN
                CALL get_struct_subarray_ptr_4d_char(subarray_id, char_ptr_4d, dim1, dim2, dim3, dim4, char_len, local_status)
                IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(char_ptr_4d)) THEN
                    ALLOCATE(data_block%char_data(dim1,dim2,dim3,dim4))
                    data_block%char_data(1:dim1,1:dim2,1:dim3,1:dim4) = char_ptr_4d(1:dim1,1:dim2,1:dim3,1:dim4)
                    data_block%is_allocated = .TRUE.
                END IF
            END IF
        END SELECT

        ! If payload is still not allocated for array-like types, treat as unsupported
        IF (.NOT. data_block%is_allocated .AND. .NOT. is_struct_or_class) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported structured backup type or dimensions in "// &
                "bm_backup_struct for variable '"//TRIM(var_name)//"'"
            CALL log_error("BackupManager", TRIM(status%message))
            RETURN
        END IF

        CALL sfm_open_file(TRIM(file_path), "WRITE", &
            "UNFORMATTED", file_handle, local_status)
        IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "sfm_open_file failed in bm_backup_struct for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        data_block%data_id    = TRIM(struct_meta%data_id)
        data_block%data_type  = struct_meta%data_type
        data_block%dimensions = struct_meta%dimensions
        data_block%mem_size   = struct_meta%total_size
        data_block%node_id    = 1

        CALL sfm_write_data(file_handle, data_block, local_status, var_name=TRIM(var_name))
        CALL sfm_close_file(file_handle, local_status)

        IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "sfm_write_data/sfm_close_file failed in bm_backup_struct for variable '"// &
                TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL bm_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "CRC calculation failed in bm_backup_struct for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL struct_meta_update(TRIM(struct_meta%data_id), 1, INT(crc32_value, KIND=8), local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "struct_meta_update(CRC32) failed in bm_backup_struct for data_id='"// &
                TRIM(struct_meta%data_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("BackupManager", &
            "Backed up structured variable '"//TRIM(var_name)//"' to file '"//TRIM(file_path)//"'")
    END SUBROUTINE bm_backup_struct

    SUBROUTINE bm_backup_unstruct(var_name, unstruct_meta, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(UnstructMetaType), INTENT(IN) :: unstruct_meta
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: crc32_value
        INTEGER(KIND=8) :: crc32_value_8
        CHARACTER(LEN=64) :: data_id

        CALL init_error_status(status)

        data_id = TRIM(unstruct_meta%data_id)

        CALL ufm_write_unstruct_data(TRIM(data_id), TRIM(file_path), UFM_FORMAT_BINARY, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "ufm_write_unstruct_data failed in bm_backup_unstruct for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL bm_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "CRC calculation failed in bm_backup_unstruct for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        crc32_value_8 = ABS(INT(crc32_value, KIND=8))
        CALL unstruct_meta_update(TRIM(data_id), 4, crc32_value_8, status=local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "unstruct_meta_update(CRC32) failed in bm_backup_unstruct for data_id='"// &
                TRIM(data_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("BackupManager", &
            "Backed up unstructured variable '"//TRIM(var_name)//"' to file '"//TRIM(file_path)//"'")
    END SUBROUTINE bm_backup_unstruct

    SUBROUTINE bm_calculate_file_crc32(file_path, crc32, status)
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        INTEGER(i4), INTENT(OUT) :: crc32
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: unit, ierr, i, j, byte
        INTEGER(i4), PARAMETER :: CRC32_POLY = Z'04C11DB7'
        INTEGER(i4) :: crc_table(256)
        INTEGER(i4) :: crc

        CALL init_error_status(status)
        crc32 = 0

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

        OPEN(NEWUNIT=unit, FILE=TRIM(file_path), STATUS='OLD', ACTION='READ', &
             FORM='UNFORMATTED', ACCESS='STREAM', IOSTAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            WRITE(status%message, '(A,I0,A,A)') &
                "Failed to open file for CRC32 (stat=", ierr, "): ", TRIM(file_path)
            CALL log_error("BackupManager", TRIM(status%message))
            RETURN
        END IF

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
            WRITE(status%message, '(A,I0,A,A)') &
                "Error reading file for CRC32 (stat=", ierr, "): ", TRIM(file_path)
            CALL log_error("BackupManager", TRIM(status%message))
            RETURN
        END IF

        crc32 = crc
        status%status_code = IF_STATUS_OK
    END SUBROUTINE bm_calculate_file_crc32

    SUBROUTINE bm_get_meta(var_name, struct_meta, unstruct_meta, status)
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
        struct_meta%is_valid   = .FALSE.
        unstruct_meta%is_valid = .FALSE.

        exists_in_sym = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "Symbol table check failed in bm_get_meta: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists_in_sym) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,A,A)') "Variable '", TRIM(var_name), "' not registered in symbol table"
            CALL log_error("BackupManager", TRIM(status%message))
            RETURN
        END IF

        CALL get_variable_data_id(var_name, data_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "Failed to get data ID for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL struct_meta_try_query(TRIM(data_id), 1, local_struct_meta, has_struct_meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_META_NOT_FOUND) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "struct_meta_try_query failed in bm_get_meta for var '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (has_struct_meta) THEN
            struct_meta = local_struct_meta
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CALL unstruct_meta_try_query(TRIM(data_id), 1, local_unstruct_meta, has_unstruct_meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .AND. local_status%status_code /= IF_STATUS_UNSMETA_NOT_FOUND) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "unstruct_meta_try_query failed in bm_get_meta for var '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (has_unstruct_meta) THEN
            unstruct_meta = local_unstruct_meta
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        status%status_code = IF_STATUS_INVALID
        status%message = "No structured or unstructured metadata found for variable '"//TRIM(var_name)//"'"
        CALL log_error("BackupManager", TRIM(status%message))
    END SUBROUTINE bm_get_meta

    SUBROUTINE bm_restore_struct(var_name, struct_meta, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(StructMetaType), INTENT(IN) :: struct_meta
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        TYPE(FileHandleType) :: file_handle
        TYPE(DataBlockType) :: data_block
        INTEGER(i4) :: crc32_value
        INTEGER(i4) :: subarray_id, dim1, dim2, dim3, dim4
        INTEGER(i4) :: dims(4)
        LOGICAL :: is_struct_or_class
        INTEGER, POINTER :: int_ptr(:)
        INTEGER, POINTER :: int_ptr_2d(:,:)
        INTEGER, POINTER :: int_ptr_3d(:,:,:)
        INTEGER, POINTER :: int_ptr_4d(:,:,:,:)
        DOUBLE PRECISION, POINTER :: dp_ptr_1d(:)
        DOUBLE PRECISION, POINTER :: dp_ptr_2d(:,:)
        DOUBLE PRECISION, POINTER :: dp_ptr_3d(:,:,:)
        DOUBLE PRECISION, POINTER :: dp_ptr_4d(:,:,:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: char_ptr_1d(:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: char_ptr_2d(:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: char_ptr_3d(:,:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: char_ptr_4d(:,:,:,:)
        INTEGER(i4) :: char_len

        CALL init_error_status(status)

        CALL sfm_open_file(TRIM(file_path), "READ", &
            "UNFORMATTED", file_handle, local_status)
        IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "sfm_open_file failed in bm_restore_struct for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL sfm_read_data(var_name=TRIM(var_name), file_handle=file_handle, &
            data_block=data_block, error=local_status)
        CALL sfm_close_file(file_handle, local_status)

        IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
            CALL log_warn("BackupManager", &
                "sfm_read_data/sfm_close_file reported error in bm_restore_struct, "// &
                "continuing with best-effort payload restore and CRC refresh")
        END IF

        ! Attempt to restore payload back into StructMemPool for array-like structured variables
        dims = struct_meta%dimensions
        is_struct_or_class = (struct_meta%data_type == IF_DATA_TYPE_STRUCT .OR. &
                              struct_meta%data_type == IF_DATA_TYPE_CLASS)

        IF (.NOT. is_struct_or_class) THEN
            CALL get_unified_subarray_id_by_data_id(TRIM(struct_meta%data_id), subarray_id, local_status)
            IF (local_status%status_code /= IF_STATUS_OK .OR. subarray_id <= 0) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Unified subarray for variable '"//TRIM(var_name)//"' not found in bm_restore_struct"
                CALL log_error("BackupManager", TRIM(status%message))
                RETURN
            END IF

            SELECT CASE (struct_meta%data_type)
            CASE (IF_DATA_TYPE_INT)
                IF (ALLOCATED(data_block%int_data)) THEN
                    ! INT1D: dims = [N,0,0,0]
                    IF (dims(2) == 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_1d_int(subarray_id, int_ptr, dim1, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(int_ptr)) THEN
                            IF (SIZE(data_block%int_data,1) >= dim1) THEN
                                int_ptr(1:dim1) = data_block%int_data(1:dim1,1,1,1)
                            END IF
                        END IF
                    ! INT2D: dims = [N1,N2,0,0]
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_2d_int(subarray_id, int_ptr_2d, dim1, dim2, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(int_ptr_2d)) THEN
                            IF (SIZE(data_block%int_data,1) >= dim1 .AND. SIZE(data_block%int_data,2) >= dim2) THEN
                                int_ptr_2d(1:dim1,1:dim2) = data_block%int_data(1:dim1,1:dim2,1,1)
                            END IF
                        END IF
                    ! INT3D: dims = [N1,N2,N3,0]
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_3d_int(subarray_id, int_ptr_3d, dim1, dim2, dim3, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(int_ptr_3d)) THEN
                            IF (SIZE(data_block%int_data,1) >= dim1 .AND. SIZE(data_block%int_data,2) >= dim2 .AND. &
                                SIZE(data_block%int_data,3) >= dim3) THEN
                                int_ptr_3d(1:dim1,1:dim2,1:dim3) = data_block%int_data(1:dim1,1:dim2,1:dim3,1)
                            END IF
                        END IF
                    ! INT4D: dims = [N1,N2,N3,N4]
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) > 0) THEN
                        CALL get_struct_subarray_ptr_4d_int(subarray_id, int_ptr_4d, dim1, dim2, dim3, dim4, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(int_ptr_4d)) THEN
                            IF (SIZE(data_block%int_data,1) >= dim1 .AND. SIZE(data_block%int_data,2) >= dim2 .AND. &
                                SIZE(data_block%int_data,3) >= dim3 .AND. SIZE(data_block%int_data,4) >= dim4) THEN
                                int_ptr_4d(1:dim1,1:dim2,1:dim3,1:dim4) = &
                                    data_block%int_data(1:dim1,1:dim2,1:dim3,1:dim4)
                            END IF
                        END IF
                    END IF
                END IF
            CASE (IF_DATA_TYPE_DP)
                IF (ALLOCATED(data_block%real_data)) THEN
                    ! DP1D
                    IF (dims(2) == 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_1d_dp(subarray_id, dp_ptr_1d, dim1, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(dp_ptr_1d)) THEN
                            IF (SIZE(data_block%real_data,1) >= dim1) THEN
                                dp_ptr_1d(1:dim1) = data_block%real_data(1:dim1,1,1,1)
                            END IF
                        END IF
                    ! DP2D
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_2d_dp(subarray_id, dp_ptr_2d, dim1, dim2, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(dp_ptr_2d)) THEN
                            IF (SIZE(data_block%real_data,1) >= dim1 .AND. SIZE(data_block%real_data,2) >= dim2) THEN
                                dp_ptr_2d(1:dim1,1:dim2) = data_block%real_data(1:dim1,1:dim2,1,1)
                            END IF
                        END IF
                    ! DP3D
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_3d_dp(subarray_id, dp_ptr_3d, dim1, dim2, dim3, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(dp_ptr_3d)) THEN
                            IF (SIZE(data_block%real_data,1) >= dim1 .AND. SIZE(data_block%real_data,2) >= dim2 .AND. &
                                SIZE(data_block%real_data,3) >= dim3) THEN
                                dp_ptr_3d(1:dim1,1:dim2,1:dim3) = &
                                    data_block%real_data(1:dim1,1:dim2,1:dim3,1)
                            END IF
                        END IF
                    ! DP4D
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) > 0) THEN
                        CALL get_struct_subarray_ptr_4d_dp(subarray_id, dp_ptr_4d, dim1, dim2, dim3, dim4, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(dp_ptr_4d)) THEN
                            IF (SIZE(data_block%real_data,1) >= dim1 .AND. SIZE(data_block%real_data,2) >= dim2 .AND. &
                                SIZE(data_block%real_data,3) >= dim3 .AND. SIZE(data_block%real_data,4) >= dim4) THEN
                                dp_ptr_4d(1:dim1,1:dim2,1:dim3,1:dim4) = &
                                    data_block%real_data(1:dim1,1:dim2,1:dim3,1:dim4)
                            END IF
                        END IF
                    END IF
                END IF
            CASE (IF_DATA_TYPE_CHAR)
                IF (ALLOCATED(data_block%char_data)) THEN
                    ! CHAR1D
                    IF (dims(2) == 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_1d_char(subarray_id, char_ptr_1d, dim1, char_len, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(char_ptr_1d)) THEN
                            IF (SIZE(data_block%char_data,1) >= dim1) THEN
                                char_ptr_1d(1:dim1) = data_block%char_data(1:dim1,1,1,1)
                            END IF
                        END IF
                    ! CHAR2D
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) == 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_2d_char(subarray_id, char_ptr_2d, dim1, dim2, char_len, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(char_ptr_2d)) THEN
                            IF (SIZE(data_block%char_data,1) >= dim1 .AND. SIZE(data_block%char_data,2) >= dim2) THEN
                                char_ptr_2d(1:dim1,1:dim2) = data_block%char_data(1:dim1,1:dim2,1,1)
                            END IF
                        END IF
                    ! CHAR3D
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) == 0) THEN
                        CALL get_struct_subarray_ptr_3d_char(subarray_id, char_ptr_3d, dim1, dim2, dim3, char_len, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(char_ptr_3d)) THEN
                            IF (SIZE(data_block%char_data,1) >= dim1 .AND. SIZE(data_block%char_data,2) >= dim2 .AND. &
                                SIZE(data_block%char_data,3) >= dim3) THEN
                                char_ptr_3d(1:dim1,1:dim2,1:dim3) = &
                                    data_block%char_data(1:dim1,1:dim2,1:dim3,1)
                            END IF
                        END IF
                    ! CHAR4D
                    ELSE IF (dims(1) > 0 .AND. dims(2) > 0 .AND. dims(3) > 0 .AND. dims(4) > 0) THEN
                        CALL get_struct_subarray_ptr_4d_char(subarray_id, char_ptr_4d, dim1, dim2, dim3, dim4, &
                            char_len, local_status)
                        IF (local_status%status_code == IF_STATUS_OK .AND. ASSOCIATED(char_ptr_4d)) THEN
                            IF (SIZE(data_block%char_data,1) >= dim1 .AND. SIZE(data_block%char_data,2) >= dim2 .AND. &
                                SIZE(data_block%char_data,3) >= dim3 .AND. SIZE(data_block%char_data,4) >= dim4) THEN
                                char_ptr_4d(1:dim1,1:dim2,1:dim3,1:dim4) = &
                                    data_block%char_data(1:dim1,1:dim2,1:dim3,1:dim4)
                            END IF
                        END IF
                    END IF
                END IF
            END SELECT
        END IF

        CALL bm_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "CRC calculation failed in bm_restore_struct for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        CALL struct_meta_update(TRIM(struct_meta%data_id), 1, INT(crc32_value, KIND=8), local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "struct_meta_update(CRC32) failed in bm_restore_struct for data_id='"// &
                TRIM(struct_meta%data_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("BackupManager", &
            "Restored structured variable '"//TRIM(var_name)//"' from file '"//TRIM(file_path)//"'")
    END SUBROUTINE bm_restore_struct

    SUBROUTINE bm_restore_unstruct(var_name, unstruct_meta, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(UnstructMetaType), INTENT(IN) :: unstruct_meta
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        CHARACTER(LEN=64) :: data_id, loaded_id
        INTEGER(i4) :: crc32_value
        INTEGER(KIND=8) :: crc32_value_8
        LOGICAL :: exists

        CALL init_error_status(status)

        data_id = TRIM(unstruct_meta%data_id)

        exists = unstruct_data_exists(TRIM(data_id))
        IF (exists) THEN
            CALL delete_unstruct_data(TRIM(data_id), local_status)
            IF (local_status%status_code /= IF_STATUS_OK .AND. &
                local_status%status_code /= IF_STATUS_NOT_FOUND) THEN
                status = local_status
                CALL log_error("BackupManager", &
                    "delete_unstruct_data failed in bm_restore_unstruct for data_id='"//TRIM(data_id)//"': "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL ufm_load_unstruct_data(TRIM(file_path), loaded_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "ufm_load_unstruct_data failed in bm_restore_unstruct for file '"//TRIM(file_path)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (TRIM(loaded_id) /= TRIM(data_id)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Data ID mismatch in bm_restore_unstruct for variable '"//TRIM(var_name)//"'"
            CALL log_error("BackupManager", TRIM(status%message))
            RETURN
        END IF

        CALL bm_calculate_file_crc32(TRIM(file_path), crc32_value, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "CRC calculation failed in bm_restore_unstruct for variable '"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        crc32_value_8 = ABS(INT(crc32_value, KIND=8))
        CALL unstruct_meta_update(TRIM(data_id), 4, crc32_value_8, status=local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("BackupManager", &
                "unstruct_meta_update(CRC32) failed in bm_restore_unstruct for data_id='"// &
                TRIM(data_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("BackupManager", &
            "Restored unstructured variable '"//TRIM(var_name)//"' from file '"//TRIM(file_path)//"'")
    END SUBROUTINE bm_restore_unstruct

    SUBROUTINE restore_data(var_name, backup_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: backup_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType)   :: struct_meta
        TYPE(UnstructMetaType) :: unstruct_meta
        TYPE(ErrorStatusType)  :: local_status
        LOGICAL :: has_struct_meta, has_unstruct_meta
        CHARACTER(LEN=512) :: backup_path

        CALL init_error_status(status)

        CALL bm_get_meta(var_name, struct_meta, unstruct_meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        has_struct_meta   = struct_meta%is_valid
        has_unstruct_meta = unstruct_meta%is_valid

        IF (.NOT. has_struct_meta .AND. .NOT. has_unstruct_meta) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Metadata for variable '"//TRIM(var_name)//"' is not valid in restore_data"
            CALL log_error("BackupManager", TRIM(status%message))
            RETURN
        END IF

        backup_path = TRIM(backup_id)//"_"//TRIM(var_name)//".bin"

        IF (has_struct_meta) THEN
            CALL bm_restore_struct(var_name, struct_meta, backup_path, local_status)
        ELSE
            CALL bm_restore_unstruct(var_name, unstruct_meta, backup_path, local_status)
        END IF

        status = local_status
    END SUBROUTINE restore_data
END MODULE IF_IO_Backup