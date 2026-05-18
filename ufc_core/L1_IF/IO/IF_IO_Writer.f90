!===============================================================================
! MODULE: IF_IO_Writer
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Impl — output writer for structured result files (VTK/HDF5/CSV/ODB)
! BRIEF:  Format-specific write operations for FE analysis results.
!===============================================================================
MODULE IF_IO_Writer
    USE IF_IO_File, ONLY: IF_FileHandle, IF_IO_MODE_WRITE, IF_IO_FORMAT_TEXT
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACE (IF_WriterHandle is public via TYPE, PUBLIC)
    ! ==========================================================================
    PUBLIC :: IF_Writer_WriteVTK
    PUBLIC :: IF_Writer_WriteHDF5
    PUBLIC :: IF_Writer_WriteCSV

    ! ==========================================================================
    ! WRITER HANDLE TYPE
    ! Category: State (State - writer runtime data)
    ! Purpose: Writer handle state containing file handle and output format.
    ! Members:
    !   file_handle: File handle for output file
    !   format: Output format (VTK, HDF5, CSV, ODB)
    ! ==========================================================================
    TYPE, PUBLIC :: IF_WriterHandle
        TYPE(IF_FileHandle) :: file_handle
        CHARACTER(LEN=32) :: format = ""
    END TYPE IF_WriterHandle

CONTAINS

    !> @brief Write VTK format
    !! @param[in] handle Writer handle
    !! @param[in] coords Node coordinates
    !! @param[in] connectivity Element connectivity
    !! @param[in] field_data Field data
    !! @param[in] field_name Field name
    !! @param[out] status Error status
    SUBROUTINE IF_Writer_WriteVTK(handle, coords, connectivity, &
                                   field_data, field_name, status)
        TYPE(IF_WriterHandle), INTENT(IN) :: handle
        REAL(wp), INTENT(IN) :: coords(:,:)
        INTEGER(i4), INTENT(IN) :: connectivity(:,:)
        REAL(wp), INTENT(IN) :: field_data(:)
        CHARACTER(LEN=*), INTENT(IN) :: field_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: nNodes, nElems, i
        CHARACTER(LEN=512) :: line
        TYPE(IF_FileHandle) :: file_hdl

        CALL init_error_status(status)

        file_hdl = handle%file_handle

        IF (.NOT. file_hdl%IsOpen()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        nNodes = SIZE(coords, 2)
        nElems = SIZE(connectivity, 2)

        ! VTK Header
        CALL file_hdl%WriteTextLine('# vtk DataFile Version 3.0', status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        CALL file_hdl%WriteTextLine('UFC FEA Output', status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        CALL file_hdl%WriteTextLine('ASCII', status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        CALL file_hdl%WriteTextLine('DATASET UNSTRUCTURED_GRID', status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Write node coordinates header
        WRITE(line, '(A,I0,A)') 'POINTS ', nNodes, ' double'
        CALL file_hdl%WriteTextLine(TRIM(line), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Write node coordinates
        DO i = 1, nNodes
            WRITE(line, '(3E16.8)') coords(:,i)
            CALL file_hdl%WriteTextLine(TRIM(line), status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        ! Write field data header
        WRITE(line, '(A,I0)') 'POINT_DATA ', nNodes
        CALL file_hdl%WriteTextLine(TRIM(line), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        WRITE(line, '(A,A,A)') 'SCALARS ', TRIM(field_name), ' double'
        CALL file_hdl%WriteTextLine(TRIM(line), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        CALL file_hdl%WriteTextLine('LOOKUP_TABLE default', status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Write field data
        DO i = 1, nNodes
            WRITE(line, '(E16.8)') field_data(i)
            CALL file_hdl%WriteTextLine(TRIM(line), status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Writer_WriteVTK

    !> @brief Write HDF5 format
    !! @param[in] handle Writer handle
    !! @param[in] dataset_name Dataset name
    !! @param[in] data Data array
    !! @param[out] status Error status
    SUBROUTINE IF_Writer_WriteHDF5(handle, dataset_name, data, status)
        TYPE(IF_WriterHandle), INTENT(IN) :: handle
        CHARACTER(LEN=*), INTENT(IN) :: dataset_name
        REAL(wp), INTENT(IN) :: data(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i
        CHARACTER(LEN=512) :: line
        TYPE(IF_FileHandle) :: file_hdl

        CALL init_error_status(status)

        file_hdl = handle%file_handle

        IF (.NOT. file_hdl%IsOpen()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        ! Note: This is a simplified implementation (text-based)
        ! Full HDF5 implementation would use HDF5 library
        WRITE(line, '(A,A)') 'DATASET: ', TRIM(dataset_name)
        CALL file_hdl%WriteTextLine(TRIM(line), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        DO i = 1, SIZE(data)
            WRITE(line, '(E16.8)') data(i)
            CALL file_hdl%WriteTextLine(TRIM(line), status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Writer_WriteHDF5

    !> @brief Write CSV format
    !! @param[in] handle Writer handle
    !! @param[in] header Column headers
    !! @param[in] data Data matrix
    !! @param[out] status Error status
    SUBROUTINE IF_Writer_WriteCSV(handle, header, data, status)
        TYPE(IF_WriterHandle), INTENT(IN) :: handle
        CHARACTER(LEN=*), INTENT(IN) :: header(:)
        REAL(wp), INTENT(IN) :: data(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: nCols, nRows, i, j
        CHARACTER(LEN=1024) :: line
        TYPE(IF_FileHandle) :: file_hdl

        CALL init_error_status(status)

        file_hdl = handle%file_handle

        IF (.NOT. file_hdl%IsOpen()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        nCols = SIZE(data, 1)
        nRows = SIZE(data, 2)

        ! Write header
        line = ""
        DO i = 1, SIZE(header)
            line = TRIM(line) // TRIM(header(i))
            IF (i < SIZE(header)) line = TRIM(line) // ","
        END DO
        CALL file_hdl%WriteTextLine(TRIM(line), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Write data
        DO j = 1, nRows
            line = ""
            DO i = 1, nCols
                WRITE(line(LEN_TRIM(line)+1:), '(E16.8)') data(i,j)
                IF (i < nCols) line = TRIM(line) // ","
            END DO
            CALL file_hdl%WriteTextLine(TRIM(line), status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_Writer_WriteCSV

END MODULE IF_IO_Writer