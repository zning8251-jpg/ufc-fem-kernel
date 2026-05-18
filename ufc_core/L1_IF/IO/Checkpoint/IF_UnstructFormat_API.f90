!===============================================================================
! MODULE: IF_UnstructFormat_API
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Brg — format adapter for unstructured data (DAT / INP / CSV)
! BRIEF:  Placeholder implementations reporting IF_STATUS_UNSUPPORTED.
!===============================================================================

MODULE IF_UnstructFormat_API
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_info, log_warn, log_error, &
        IF_STATUS_OK, IF_STATUS_UNSUPPORTED, IF_STATUS_INVALID
    USE IF_UnstructFile_Mgr, ONLY: &
        ufm_write_unstruct_data, ufm_load_unstruct_data, &
        IF_FORMAT_DAT, IF_FORMAT_CSV, IF_FORMAT_INP
    USE IF_Base_UnstructMeta_Def, ONLY: &
        UnstructMetaType, unstruct_meta_query, &
        IF_STATUS_UNSMETA_NOT_FOUND

    IMPLICIT NONE
    PRIVATE

    ! Public APIs for unstructured-format adapters
    PUBLIC :: ufm_write_unstruct_dat
    PUBLIC :: ufm_load_unstruct_dat
    PUBLIC :: ufm_write_unstruct_inp
    PUBLIC :: ufm_load_unstruct_inp
    PUBLIC :: ufm_write_unstruct_csv
    PUBLIC :: ufm_load_unstruct_csv

CONTAINS

    SUBROUTINE ufa_get_unstruct_meta_by_var(var_name, meta, status)
        CHARACTER(LEN=*), INTENT(IN)  :: var_name
        TYPE(UnstructMetaType), INTENT(OUT) :: meta
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        meta = UnstructMetaType()

        CALL unstruct_meta_query(TRIM(var_name), 2, meta, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (status%status_code == IF_STATUS_UNSMETA_NOT_FOUND) THEN
                CALL log_error("UnstructFormatAdapters", &
                    "Unstructured variable metadata not found for var='"//TRIM(var_name)//"'")
            ELSE
                CALL log_error("UnstructFormatAdapters", &
                    "unstruct_meta_query failed for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            END IF
        END IF
    END SUBROUTINE ufa_get_unstruct_meta_by_var

    SUBROUTINE ufm_load_unstruct_csv(var_name, file_path, status, loaded_id_opt)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: loaded_id_opt

        TYPE(UnstructMetaType) :: meta
        TYPE(ErrorStatusType)  :: local_status
        CHARACTER(LEN=64) :: loaded_id

        CALL init_error_status(status)

        CALL ufm_load_unstruct_data(TRIM(file_path), loaded_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "ufm_load_unstruct_data(CSV) failed for file='"//TRIM(file_path)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (PRESENT(loaded_id_opt)) THEN
            loaded_id_opt = TRIM(loaded_id)
        END IF

        CALL unstruct_meta_query(TRIM(loaded_id), 1, meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "unstruct_meta_query failed after CSV load for data_id='"//TRIM(loaded_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("UnstructFormatAdapters", &
            "Unstructured data_id '"//TRIM(loaded_id)//"' loaded from CSV file '"//TRIM(file_path)//&
            "' (requested var='"//TRIM(var_name)//"')")
    END SUBROUTINE ufm_load_unstruct_csv

    SUBROUTINE ufm_load_unstruct_dat(var_name, file_path, status, loaded_id_opt)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: loaded_id_opt

        TYPE(UnstructMetaType) :: meta
        TYPE(ErrorStatusType)  :: local_status
        CHARACTER(LEN=64) :: loaded_id

        CALL init_error_status(status)

        CALL ufm_load_unstruct_data(TRIM(file_path), loaded_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "ufm_load_unstruct_data(DAT) failed for file='"//TRIM(file_path)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (PRESENT(loaded_id_opt)) THEN
            loaded_id_opt = TRIM(loaded_id)
        END IF

        CALL unstruct_meta_query(TRIM(loaded_id), 1, meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "unstruct_meta_query failed after DAT load for data_id='"//TRIM(loaded_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("UnstructFormatAdapters", &
            "Unstructured data_id '"//TRIM(loaded_id)//"' loaded from DAT file '"//TRIM(file_path)//&
            "' (requested var='"//TRIM(var_name)//"')")
    END SUBROUTINE ufm_load_unstruct_dat

    SUBROUTINE ufm_load_unstruct_inp(var_name, file_path, status, loaded_id_opt)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: loaded_id_opt

        TYPE(UnstructMetaType) :: meta
        TYPE(ErrorStatusType)  :: local_status
        CHARACTER(LEN=64) :: loaded_id

        CALL init_error_status(status)

        CALL ufm_load_unstruct_data(TRIM(file_path), loaded_id, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "ufm_load_unstruct_data(INP) failed for file='"//TRIM(file_path)//"': "//TRIM(status%message))
            RETURN
        END IF

        IF (PRESENT(loaded_id_opt)) THEN
            loaded_id_opt = TRIM(loaded_id)
        END IF

        CALL unstruct_meta_query(TRIM(loaded_id), 1, meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "unstruct_meta_query failed after INP load for data_id='"//TRIM(loaded_id)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("UnstructFormatAdapters", &
            "Unstructured data_id '"//TRIM(loaded_id)//"' loaded from INP file '"//TRIM(file_path)//&
            "' (requested var='"//TRIM(var_name)//"')")
    END SUBROUTINE ufm_load_unstruct_inp

    SUBROUTINE ufm_write_unstruct_csv(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(UnstructMetaType) :: meta
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        CALL ufa_get_unstruct_meta_by_var(TRIM(var_name), meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        CALL ufm_write_unstruct_data(TRIM(meta%data_id), TRIM(file_path), IF_FORMAT_CSV, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "ufm_write_unstruct_data(CSV) failed for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("UnstructFormatAdapters", &
            "Unstructured variable '"//TRIM(var_name)//"' written as CSV to file '"//TRIM(file_path)//"'")
    END SUBROUTINE ufm_write_unstruct_csv

    SUBROUTINE ufm_write_unstruct_dat(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(UnstructMetaType) :: meta
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        CALL ufa_get_unstruct_meta_by_var(TRIM(var_name), meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        CALL ufm_write_unstruct_data(TRIM(meta%data_id), TRIM(file_path), IF_FORMAT_DAT, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "ufm_write_unstruct_data(DAT) failed for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("UnstructFormatAdapters", &
            "Unstructured variable '"//TRIM(var_name)//"' written as DAT to file '"//TRIM(file_path)//"'")
    END SUBROUTINE ufm_write_unstruct_dat

    SUBROUTINE ufm_write_unstruct_inp(var_name, file_path, status)
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(UnstructMetaType) :: meta
        TYPE(ErrorStatusType) :: local_status

        CALL init_error_status(status)

        CALL ufa_get_unstruct_meta_by_var(TRIM(var_name), meta, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            RETURN
        END IF

        CALL ufm_write_unstruct_data(TRIM(meta%data_id), TRIM(file_path), IF_FORMAT_INP, local_status)
        IF (local_status%status_code /= IF_STATUS_OK) THEN
            status = local_status
            CALL log_error("UnstructFormatAdapters", &
                "ufm_write_unstruct_data(INP) failed for var='"//TRIM(var_name)//"': "//TRIM(status%message))
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("UnstructFormatAdapters", &
            "Unstructured variable '"//TRIM(var_name)//"' written as INP to file '"//TRIM(file_path)//"'")
    END SUBROUTINE ufm_write_unstruct_inp
END MODULE IF_UnstructFormat_API