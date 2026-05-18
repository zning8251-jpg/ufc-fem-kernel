!===============================================================================
! MODULE: IF_StructFormat_API
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Brg — format adapter for structured data (DAT / INP / CSV)
! BRIEF:  Higher-level text views built on StructFileManager core BINARY/TXT.
!===============================================================================
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

MODULE IF_StructFormat_API
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_info, log_warn, log_error, &
        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
    USE IF_IO_StructFile, ONLY: &
        FileHandleType, DataBlockType, &
        sfm_open_file, sfm_close_file, sfm_write_data, sfm_read_data, &
        IF_STATUS_SFILE_OK, IF_SFM_CHAR_RECORD_LEN
    USE IF_Mem_StructPool, ONLY: &
        get_unified_subarray_id_by_data_id, &
        get_struct_subarray_ptr_1d_int, get_struct_subarray_ptr_2d_int, &
        get_struct_subarray_ptr_1d_dp,  get_struct_subarray_ptr_2d_dp,  &
        get_struct_subarray_ptr_1d_char, get_struct_subarray_ptr_2d_char
    USE IF_Base_StructMeta_Def, ONLY: &
        StructMetaType, struct_meta_try_query, INT_TO_STR
    USE IF_Base_SymTbl, ONLY: &
        symbol_table_exists, get_variable_data_id, &
        IF_STORAGE_TYPE_STRUCTURED, &
        IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR, &
        IF_DATA_TYPE_STRUCT, IF_DATA_TYPE_CLASS

    IMPLICIT NONE
    PRIVATE

    ! Public APIs for structured-format adapters
    PUBLIC :: sfm_write_struct_dat
    PUBLIC :: sfm_read_struct_dat
    PUBLIC :: sfm_write_struct_inp
    PUBLIC :: sfm_read_struct_inp
    PUBLIC :: sfm_write_struct_csv
    PUBLIC :: sfm_read_struct_csv

CONTAINS

    SUBROUTINE sfa_get_struct_meta_by_var(var_name, meta, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        TYPE(StructMetaType), INTENT(OUT) :: meta
        TYPE(ErrorStatusType),  INTENT(OUT) :: status

        TYPE(ErrorStatusType) :: local_status
        LOGICAL :: found, exists

        CALL init_error_status(status)

        IF (LEN_TRIM(var_name) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable name cannot be empty in StructFormatAdapters"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        exists = symbol_table_exists(var_name, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("StructFormatAdapters", &
                "symbol_table_exists failed in sfa_get_struct_meta_by_var: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. exists) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Variable not found in symbol table in StructFormatAdapters: '"//TRIM(var_name)//"'"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        CALL struct_meta_try_query(TRIM(var_name), 2, meta, found, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("StructFormatAdapters", &
                "struct_meta_try_query failed in sfa_get_struct_meta_by_var for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. found .OR. .NOT. meta%is_valid) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Structured metadata not found or invalid for variable '"//TRIM(var_name)//"'"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        IF (meta%storage_type /= IF_STORAGE_TYPE_STRUCTURED) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Variable is not stored as structured data in StructFormatAdapters"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        SELECT CASE (meta%data_type)
        CASE (IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR, IF_DATA_TYPE_STRUCT, IF_DATA_TYPE_CLASS)
            ! Supported structured types for adapters (same 5 core types as StructMemPool)
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported structured data type in StructFormatAdapters"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE sfa_get_struct_meta_by_var

    SUBROUTINE sfa_read_struct_txt_like(var_name, file_path, caller_tag, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        CHARACTER(LEN=*), INTENT(IN) :: caller_tag
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType) :: meta
        TYPE(ErrorStatusType) :: local_status
        TYPE(FileHandleType) :: file_handle
        TYPE(DataBlockType) :: data_block

        CALL init_error_status(status)

        ! 1) Ensure metadata exists and is structured
        CALL sfa_get_struct_meta_by_var(TRIM(var_name), meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        ! 2) Open file in formatted mode
        CALL sfm_open_file(TRIM(file_path), "READ", "FORMATTED", file_handle, local_status)
        IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "sfm_open_file failed in StructFormatAdapters read ("//TRIM(caller_tag)//")"
            CALL log_error("StructFormatAdapters", TRIM(status%message)//": "//TRIM(local_status%message))
            RETURN
        END IF

        CALL sfm_read_data(var_name=TRIM(var_name), file_handle=file_handle, &
            data_block=data_block, error=local_status)
        CALL sfm_close_file(file_handle, local_status)

        IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "sfm_read_data/sfm_close_file failed in StructFormatAdapters read ("//TRIM(caller_tag)//")"
            CALL log_error("StructFormatAdapters", TRIM(status%message)//": "//TRIM(local_status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("StructFormatAdapters", &
            "Structured variable '"//TRIM(var_name)//"' loaded as "//TRIM(caller_tag)//&
            " using TXT core layout from file '"//TRIM(file_path)//"'")
    END SUBROUTINE sfa_read_struct_txt_like

    SUBROUTINE sfa_write_struct_csv(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType) :: meta
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: dims(4)
        INTEGER(i4) :: n1, n2, rank
        INTEGER(i4) :: unit, ios, i, j, k
        INTEGER(i4) :: sub_id
        INTEGER, POINTER :: int1d(:)
        INTEGER, POINTER :: int2d(:,:)
        DOUBLE PRECISION, POINTER :: dp1d(:)
        DOUBLE PRECISION, POINTER :: dp2d(:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: ch1d(:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: ch2d(:,:)
        INTEGER(i4) :: char_len
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN) :: tmp_char

        CALL init_error_status(status)

        ! 1)  ?
        CALL sfa_get_struct_meta_by_var(TRIM(var_name), meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        dims = meta%dimensions
        rank = 0
        DO i = 1, 4
            IF (dims(i) > 0) rank = rank + 1
        END DO

        IF (rank <= 0 .OR. rank > 2) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "CSV adapter only supports 1D/2D structured arrays currently"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        n1 = dims(1)
        IF (rank == 1) THEN
            n2 = 1
        ELSE
            n2 = dims(2)
        END IF

        ! 2)  ?INT/DP/CHAR  base type
        SELECT CASE (meta%data_type)
        CASE (IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR)
            ! ok
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "CSV adapter only supports INT/DP/CHAR types currently"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END SELECT

        ! 3)   data_id   unified  ?ID
        CALL get_unified_subarray_id_by_data_id(TRIM(meta%data_id), sub_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .OR. sub_id <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unified subarray not found for CSV write: data_id='"//TRIM(meta%data_id)//"'"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        ! 4)   CSV  ???
        OPEN(NEWUNIT=unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', &
             FORM='FORMATTED', IOSTAT=ios)
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0,A)') "Failed to open CSV file (stat=", ios, ")"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        SELECT CASE (meta%data_type)
        CASE (IF_DATA_TYPE_INT)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_int(sub_id, int1d, n1, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(int1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_int failed in CSV writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(I0)', IOSTAT=ios) int1d(i)
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_int(sub_id, int2d, n1, n2, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(int2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_int failed in CSV writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(I0)', ADVANCE='NO', IOSTAT=ios) int2d(i,1)
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        WRITE(unit, '(",",I0)', ADVANCE='NO', IOSTAT=ios) int2d(i,j)
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF

        CASE (IF_DATA_TYPE_DP)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_dp(sub_id, dp1d, n1, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(dp1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_dp failed in CSV writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(ES24.15)', IOSTAT=ios) dp1d(i)
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_dp(sub_id, dp2d, n1, n2, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(dp2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_dp failed in CSV writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(ES24.15)', ADVANCE='NO', IOSTAT=ios) dp2d(i,1)
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        WRITE(unit, '(",",ES24.15)', ADVANCE='NO', IOSTAT=ios) dp2d(i,j)
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF

        CASE (IF_DATA_TYPE_CHAR)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_char(sub_id, ch1d, n1, char_len, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(ch1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_char failed in CSV writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(A)', IOSTAT=ios) CHAR(34)//TRIM(ch1d(i))//CHAR(34)
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_char(sub_id, ch2d, n1, n2, char_len, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(ch2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_char failed in CSV writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(A)', ADVANCE='NO', IOSTAT=ios) CHAR(34)//TRIM(ch2d(i,1))//CHAR(34)
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        WRITE(unit, '(A)', ADVANCE='NO', IOSTAT=ios) ','//CHAR(34)//TRIM(ch2d(i,j))//CHAR(34)
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF
        END SELECT

        CLOSE(unit)

        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0,A)') "Error writing CSV file (stat=", ios, ")"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("StructFormatAdapters", &
            "Structured variable '"//TRIM(var_name)//"' written as CSV ("//&
            TRIM(INT_TO_STR(dims(1)))//"x"//TRIM(INT_TO_STR(MAX(dims(2),1)))//") to file '"//TRIM(file_path)//"'")
    END SUBROUTINE sfa_write_struct_csv

    SUBROUTINE sfa_write_struct_dat(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType) :: meta
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: dims(4)
        INTEGER(i4) :: n1, n2, rank
        INTEGER(i4) :: unit, ios, i, j, k
        INTEGER(i4) :: sub_id
        INTEGER, POINTER :: int1d(:)
        INTEGER, POINTER :: int2d(:,:)
        DOUBLE PRECISION, POINTER :: dp1d(:)
        DOUBLE PRECISION, POINTER :: dp2d(:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: ch1d(:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: ch2d(:,:)
        INTEGER(i4) :: char_len
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN) :: tmp_char

        CALL init_error_status(status)

        ! 1)  ?
        CALL sfa_get_struct_meta_by_var(TRIM(var_name), meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        dims = meta%dimensions
        rank = 0
        DO i = 1, 4
            IF (dims(i) > 0) rank = rank + 1
        END DO

        IF (rank <= 0 .OR. rank > 2) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "DAT adapter only supports 1D/2D structured arrays currently"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        n1 = dims(1)
        IF (rank == 1) THEN
            n2 = 1
        ELSE
            n2 = dims(2)
        END IF

        ! 2)  ?INT/DP/CHAR  base type
        SELECT CASE (meta%data_type)
        CASE (IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR)
            ! ok
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "DAT adapter only supports INT/DP/CHAR types currently"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END SELECT

        ! 3)   data_id   unified  ?ID
        CALL get_unified_subarray_id_by_data_id(TRIM(meta%data_id), sub_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .OR. sub_id <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unified subarray not found for DAT write: data_id='"//TRIM(meta%data_id)//"'"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        ! 4)   DAT  matrix ?
        OPEN(NEWUNIT=unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', &
             FORM='FORMATTED', IOSTAT=ios)
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0,A)') "Failed to open DAT file (stat=", ios, ")"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        SELECT CASE (meta%data_type)
        CASE (IF_DATA_TYPE_INT)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_int(sub_id, int1d, n1, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(int1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_int failed in DAT writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(I12)', IOSTAT=ios) int1d(i)
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_int(sub_id, int2d, n1, n2, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(int2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_int failed in DAT writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(I12)', ADVANCE='NO', IOSTAT=ios) int2d(i,1)
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        WRITE(unit, '(1X,I12)', ADVANCE='NO', IOSTAT=ios) int2d(i,j)
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF

        CASE (IF_DATA_TYPE_DP)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_dp(sub_id, dp1d, n1, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(dp1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_dp failed in DAT writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(ES24.15)', IOSTAT=ios) dp1d(i)
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_dp(sub_id, dp2d, n1, n2, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(dp2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_dp failed in DAT writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(ES24.15)', ADVANCE='NO', IOSTAT=ios) dp2d(i,1)
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        WRITE(unit, '(1X,ES24.15)', ADVANCE='NO', IOSTAT=ios) dp2d(i,j)
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF

        CASE (IF_DATA_TYPE_CHAR)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_char(sub_id, ch1d, n1, char_len, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(ch1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_char failed in DAT writer")
                    RETURN
                END IF

                DO i = 1, n1
                    tmp_char = ch1d(i)
                    DO k = 1, char_len
                        IF (ICHAR(tmp_char(k:k)) == 0) tmp_char(k:k) = ' '
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) TRIM(tmp_char(1:char_len))
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_char(sub_id, ch2d, n1, n2, char_len, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(ch2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_char failed in DAT writer")
                    RETURN
                END IF

                DO i = 1, n1
                    tmp_char = ch2d(i,1)
                    DO k = 1, char_len
                        IF (ICHAR(tmp_char(k:k)) == 0) tmp_char(k:k) = ' '
                    END DO
                    WRITE(unit, '(A)', ADVANCE='NO', IOSTAT=ios) TRIM(tmp_char(1:char_len))
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        tmp_char = ch2d(i,j)
                        DO k = 1, char_len
                            IF (ICHAR(tmp_char(k:k)) == 0) tmp_char(k:k) = ' '
                        END DO
                        WRITE(unit, '(1X,A)', ADVANCE='NO', IOSTAT=ios) TRIM(tmp_char(1:char_len))
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF
        END SELECT

        CLOSE(unit)

        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0,A)') "Error writing DAT file (stat=", ios, ")"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("StructFormatAdapters", &
            "Structured variable '"//TRIM(var_name)//"' written as DAT ("//&
            TRIM(INT_TO_STR(dims(1)))//"x"//TRIM(INT_TO_STR(MAX(dims(2),1)))//") to file '"//TRIM(file_path)//"'")
    END SUBROUTINE sfa_write_struct_dat

    SUBROUTINE sfa_write_struct_inp(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType) :: meta
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: dims(4)
        INTEGER(i4) :: n1, n2, rank
        INTEGER(i4) :: unit, ios, i, j, k
        INTEGER(i4) :: sub_id
        INTEGER, POINTER :: int1d(:)
        INTEGER, POINTER :: int2d(:,:)
        DOUBLE PRECISION, POINTER :: dp1d(:)
        DOUBLE PRECISION, POINTER :: dp2d(:,:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: ch1d(:)
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), POINTER :: ch2d(:,:)
        INTEGER(i4) :: char_len
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN) :: tmp_char
        CHARACTER(LEN=16) :: type_name

        CALL init_error_status(status)

        ! 1)  ?
        CALL sfa_get_struct_meta_by_var(TRIM(var_name), meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        dims = meta%dimensions
        rank = 0
        DO i = 1, 4
            IF (dims(i) > 0) rank = rank + 1
        END DO

        IF (rank <= 0 .OR. rank > 2) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "INP adapter only supports 1D/2D structured arrays currently"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        n1 = dims(1)
        IF (rank == 1) THEN
            n2 = 1
        ELSE
            n2 = dims(2)
        END IF

        ! 2)  ?INT/DP/CHAR  base type
        SELECT CASE (meta%data_type)
        CASE (IF_DATA_TYPE_INT)
            type_name = "INT"
        CASE (IF_DATA_TYPE_DP)
            type_name = "DP"
        CASE (IF_DATA_TYPE_CHAR)
            type_name = "CHAR"
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "INP adapter only supports INT/DP/CHAR types currently"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END SELECT

        ! 3)   data_id   unified  ?ID
        CALL get_unified_subarray_id_by_data_id(TRIM(meta%data_id), sub_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK .OR. sub_id <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unified subarray not found for INP write: data_id='"//TRIM(meta%data_id)//"'"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        ! 4)   INP  ?section/title ?
        OPEN(NEWUNIT=unit, FILE=TRIM(file_path), STATUS='REPLACE', ACTION='WRITE', &
             FORM='FORMATTED', IOSTAT=ios)
        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0,A)') "Failed to open INP file (stat=", ios, ")"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        WRITE(unit, '(A)') "*INP"
        WRITE(unit, '(A)') "*VAR, NAME="//TRIM(var_name)
        WRITE(unit, '(A)') "*TYPE, VALUE="//TRIM(type_name)
        WRITE(unit, '(A)') "*RANK, VALUE="//TRIM(INT_TO_STR(rank))
        IF (rank == 1) THEN
            WRITE(unit, '(A)') "*DIMS, VALUE="//TRIM(INT_TO_STR(n1))
        ELSE
            WRITE(unit, '(A)') "*DIMS, VALUE="//TRIM(INT_TO_STR(n1))//","//TRIM(INT_TO_STR(n2))
        END IF
        WRITE(unit, '(A)') "*DATA"

        ! 5)  ?+  ?? INP  ?
        SELECT CASE (meta%data_type)
        CASE (IF_DATA_TYPE_INT)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_int(sub_id, int1d, n1, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(int1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_int failed in INP writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(I12)', IOSTAT=ios) int1d(i)
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_int(sub_id, int2d, n1, n2, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(int2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_int failed in INP writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(I12)', ADVANCE='NO', IOSTAT=ios) int2d(i,1)
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        WRITE(unit, '(1X,I12)', ADVANCE='NO', IOSTAT=ios) int2d(i,j)
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF

        CASE (IF_DATA_TYPE_DP)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_dp(sub_id, dp1d, n1, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(dp1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_dp failed in INP writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(ES24.15)', IOSTAT=ios) dp1d(i)
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_dp(sub_id, dp2d, n1, n2, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(dp2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_dp failed in INP writer")
                    RETURN
                END IF

                DO i = 1, n1
                    WRITE(unit, '(ES24.15)', ADVANCE='NO', IOSTAT=ios) dp2d(i,1)
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        WRITE(unit, '(1X,ES24.15)', ADVANCE='NO', IOSTAT=ios) dp2d(i,j)
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF

        CASE (IF_DATA_TYPE_CHAR)
            IF (rank == 1) THEN
                CALL get_struct_subarray_ptr_1d_char(sub_id, ch1d, n1, char_len, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(ch1d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_1d_char failed in INP writer")
                    RETURN
                END IF

                DO i = 1, n1
                    tmp_char = ch1d(i)
                    DO k = 1, char_len
                        IF (ICHAR(tmp_char(k:k)) == 0) tmp_char(k:k) = ' '
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) TRIM(tmp_char(1:char_len))
                    IF (ios /= 0) EXIT
                END DO
            ELSE
                CALL get_struct_subarray_ptr_2d_char(sub_id, ch2d, n1, n2, char_len, local_status)
                IF (local_status%status_code /= IF_STATUS_OK .OR. .NOT. ASSOCIATED(ch2d)) THEN
                    status = local_status
                    CLOSE(unit)
                    CALL log_error("StructFormatAdapters", "get_struct_subarray_ptr_2d_char failed in INP writer")
                    RETURN
                END IF

                DO i = 1, n1
                    tmp_char = ch2d(i,1)
                    DO k = 1, char_len
                        IF (ICHAR(tmp_char(k:k)) == 0) tmp_char(k:k) = ' '
                    END DO
                    WRITE(unit, '(A)', ADVANCE='NO', IOSTAT=ios) TRIM(tmp_char(1:char_len))
                    IF (ios /= 0) EXIT
                    DO j = 2, n2
                        tmp_char = ch2d(i,j)
                        DO k = 1, char_len
                            IF (ICHAR(tmp_char(k:k)) == 0) tmp_char(k:k) = ' '
                        END DO
                        WRITE(unit, '(1X,A)', ADVANCE='NO', IOSTAT=ios) TRIM(tmp_char(1:char_len))
                        IF (ios /= 0) EXIT
                    END DO
                    WRITE(unit, '(A)', IOSTAT=ios) ""
                    IF (ios /= 0) EXIT
                END DO
            END IF
        END SELECT

        WRITE(unit, '(A)') "*END"
        CLOSE(unit)

        IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            WRITE(status%message, '(A,I0,A)') "Error writing INP file (stat=", ios, ")"
            CALL log_error("StructFormatAdapters", TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("StructFormatAdapters", &
            "Structured variable '"//TRIM(var_name)//"' written as INP ("//&
            TRIM(INT_TO_STR(dims(1)))//"x"//TRIM(INT_TO_STR(MAX(dims(2),1)))//") to file '"//TRIM(file_path)//"'")
    END SUBROUTINE sfa_write_struct_inp

    SUBROUTINE sfa_write_struct_txt_like(var_name, file_path, caller_tag, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        CHARACTER(LEN=*), INTENT(IN) :: caller_tag  ! e.g. 'DAT'/'INP'/'CSV'
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(StructMetaType) :: meta
        TYPE(ErrorStatusType) :: local_status
        TYPE(FileHandleType) :: file_handle
        TYPE(DataBlockType) :: data_block

        CALL init_error_status(status)

        ! 1) Fetch structured metadata (ensures var_name is structured)
        CALL sfa_get_struct_meta_by_var(TRIM(var_name), meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        ! 2) Open file in formatted mode (TXT layout)
        CALL sfm_open_file(TRIM(file_path), "WRITE", "FORMATTED", file_handle, local_status)
        IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "sfm_open_file failed in StructFormatAdapters ("//TRIM(caller_tag)//")"
            CALL log_error("StructFormatAdapters", TRIM(status%message)//": "//TRIM(local_status%message))
            RETURN
        END IF

        ! 3) Lightweight DataBlock: rely on StructFileManager internals to locate
        !    and stream data based on metadata/symbol table.
        data_block%data_id    = TRIM(meta%data_id)
        data_block%data_type  = meta%data_type
        data_block%dimensions = meta%dimensions
        data_block%mem_size   = meta%total_size
        data_block%is_allocated = .FALSE.
        data_block%node_id    = 1

        CALL sfm_write_data(file_handle, data_block, local_status, var_name=TRIM(var_name))
        CALL sfm_close_file(file_handle, local_status)

        IF (local_status%status_code /= IF_STATUS_SFILE_OK) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "sfm_write_data/sfm_close_file failed in StructFormatAdapters ("//TRIM(caller_tag)//")"
            CALL log_error("StructFormatAdapters", TRIM(status%message)//": "//TRIM(local_status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("StructFormatAdapters", &
            "Structured variable '"//TRIM(var_name)//"' written as "//TRIM(caller_tag)//&
            " using TXT core layout to file '"//TRIM(file_path)//"'")
    END SUBROUTINE sfa_write_struct_txt_like

    SUBROUTINE sfm_read_struct_csv(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        ! CSV  ?TXT  ? CSV
        CALL sfa_read_struct_txt_like(var_name, file_path, "CSV", status)
    END SUBROUTINE sfm_read_struct_csv

    SUBROUTINE sfm_read_struct_dat(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL sfa_read_struct_txt_like(var_name, file_path, "DAT", status)
    END SUBROUTINE sfm_read_struct_dat

    SUBROUTINE sfm_read_struct_inp(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        !  ?TXT  ? INP
        CALL sfa_read_struct_txt_like(var_name, file_path, "INP", status)
    END SUBROUTINE sfm_read_struct_inp

    SUBROUTINE sfm_write_struct_csv(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL sfa_write_struct_csv(var_name, file_path, status)
    END SUBROUTINE sfm_write_struct_csv

    SUBROUTINE sfm_write_struct_dat(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL sfa_write_struct_dat(var_name, file_path, status)
    END SUBROUTINE sfm_write_struct_dat

    SUBROUTINE sfm_write_struct_inp(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL sfa_write_struct_inp(var_name, file_path, status)
    END SUBROUTINE sfm_write_struct_inp
END MODULE IF_StructFormat_API