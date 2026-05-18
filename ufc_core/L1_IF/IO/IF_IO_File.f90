!===============================================================================
! MODULE: IF_IO_File
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Impl — core file I/O operations (open/close/read/write/copy/delete)
! BRIEF:  Wraps Fortran intrinsic I/O with error handling. Text/binary modes,
!         file positioning, unit management, directory creation.
!===============================================================================
! Theory:  File I/O: Open(file, mode) ??handle, Read(handle, data) ??status,
!          Write(handle, data) ??status, file size: size ???^+ (bytes),
!          file position: pos ???^+ (bytes), where handle ??IF_FileHandle.
! Status:  CORE | Last verified: 2026-03-03
!
! Contents (A-Z):
!   Types:
!     - IF_FileHandle (State): File handle state
!     - IF_FileHandle_Open_In/Out: Structured interface for file open
!     - IF_FileHandle_Close_In/Out: Structured interface for file close
!     - IF_FileHandle_ReadTextLine_In/Out: Structured interface for read text line
!     - IF_FileHandle_WriteTextLine_In/Out: Structured interface for write text line
!   Subroutines:
!     - IF_FileHandle_Open: Open file
!     - IF_FileHandle_Close: Close file
!     - IF_FileHandle_ReadTextLine: Read text line
!     - IF_FileHandle_WriteTextLine: Write text line
!     - IF_FileHandle_ReadBinary: Read binary data
!     - IF_FileHandle_WriteBinary: Write binary data
!     - IF_FileHandle_Rewind: Rewind file
!     - IF_FileHandle_SetPosition: Set file position
!     - IF_FileHandle_Flush: Flush file buffer
!     - IF_FileHandle_Copy: Copy file
!     - IF_FileHandle_Delete: Delete file
!     - IF_FileHandle_CreateDirectory: Create directory
!   Functions:
!     - IF_FileHandle_GetPosition: Get file position
!     - IF_FileHandle_IsOpen: Check if file is open
!     - IF_FileHandle_Exists: Check if file exists
!     - IF_FileHandle_GetSize: Get file size
!===============================================================================
MODULE IF_IO_File
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! FILE ACCESS MODE CONSTANTS
    ! ==========================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_MODE_UNSPECIFIED = 0_i4  ! Use default (G-08 sentinel)
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_MODE_READ      = 1_i4  ! Read only
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_MODE_WRITE     = 2_i4  ! Write/replace
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_MODE_APPEND    = 3_i4  ! Append
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_MODE_READWRITE = 4_i4  ! Read+Write

    ! ==========================================================================
    ! FILE FORMAT CONSTANTS
    ! ==========================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_FORMAT_UNSPECIFIED = 0_i4  ! Use default (G-08 sentinel)
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_FORMAT_TEXT   = 1_i4  ! Formatted text
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_FORMAT_BINARY = 2_i4  ! Unformatted binary
    INTEGER(i4), PARAMETER, PUBLIC :: IF_IO_FORMAT_STREAM = 3_i4  ! Stream access

    ! ==========================================================================
    ! FILE HANDLE TYPE (must precede structured types that use it)
    ! Category: State (State - read/write runtime data)
    ! Purpose: File handle state containing file unit, path, access mode, format,
    !          and position information.
    ! ==========================================================================
    TYPE, PUBLIC :: IF_FileHandle
        INTEGER(i4) :: unit = -1                              ! n_unit
        CHARACTER(LEN=512) :: filename = ""                   ! path
        INTEGER(i4) :: mode = IF_IO_MODE_READ
        INTEGER(i4) :: format = IF_IO_FORMAT_TEXT
        LOGICAL :: is_open = .FALSE.
        INTEGER(i8) :: position = 0_i8                        ! pos (bytes)
        INTEGER(i8) :: file_size = 0_i8                       ! size (bytes)
    CONTAINS
        PROCEDURE :: Open
        PROCEDURE :: Close
        PROCEDURE :: ReadTextLine
        PROCEDURE :: WriteTextLine
        PROCEDURE :: ReadBinary
        PROCEDURE :: WriteBinary
        PROCEDURE :: Rewind
        PROCEDURE :: SetPosition
        PROCEDURE :: Flush
        PROCEDURE :: GetPosition
        PROCEDURE :: IsOpen
    END TYPE IF_FileHandle

    ! ==========================================================================
    ! STRUCTURED INTERFACE TYPES (public via TYPE, PUBLIC)
    ! ==========================================================================
    !> @brief Input structure for file open operation (G-08: sentinel for optional)
    TYPE, PUBLIC :: IF_FileHandle_Open_In
        CHARACTER(LEN=512) :: filename                        ! path
        INTEGER(i4) :: mode = IF_IO_MODE_UNSPECIFIED             ! Access mode; 0=default
        INTEGER(i4) :: format = IF_IO_FORMAT_UNSPECIFIED         ! Format type; 0=default
    END TYPE IF_FileHandle_Open_In

    !> @brief Output structure for file open operation
    TYPE, PUBLIC :: IF_FileHandle_Open_Out
        TYPE(IF_FileHandle) :: handle                         ! File handle
        TYPE(ErrorStatusType) :: status                       ! Error status
    END TYPE IF_FileHandle_Open_Out

    !> @brief Input structure for file close operation
    TYPE, PUBLIC :: IF_FileHandle_Close_In
        TYPE(IF_FileHandle) :: handle                         ! File handle
    END TYPE IF_FileHandle_Close_In

    !> @brief Output structure for file close operation
    TYPE, PUBLIC :: IF_FileHandle_Close_Out
        TYPE(IF_FileHandle) :: handle                         ! Closed file handle
        TYPE(ErrorStatusType) :: status                       ! Error status
    END TYPE IF_FileHandle_Close_Out

    !> @brief Input structure for read text line operation
    TYPE, PUBLIC :: IF_FileHandle_ReadTextLine_In
        TYPE(IF_FileHandle) :: handle                         ! File handle
    END TYPE IF_FileHandle_ReadTextLine_In

    !> @brief Output structure for read text line operation
    TYPE, PUBLIC :: IF_FileHandle_ReadTextLine_Out
        CHARACTER(LEN=512) :: line                            ! Read line
        TYPE(IF_FileHandle) :: handle                         ! Updated file handle
        TYPE(ErrorStatusType) :: status                       ! Error status
    END TYPE IF_FileHandle_ReadTextLine_Out

    !> @brief Input structure for write text line operation
    TYPE, PUBLIC :: IF_FileHandle_WriteTextLine_In
        TYPE(IF_FileHandle) :: handle                         ! File handle
        CHARACTER(LEN=512) :: line                            ! Line to write (fixed len for derived type)
    END TYPE IF_FileHandle_WriteTextLine_In

    !> @brief Output structure for write text line operation
    TYPE, PUBLIC :: IF_FileHandle_WriteTextLine_Out
        TYPE(IF_FileHandle) :: handle                         ! Updated file handle
        TYPE(ErrorStatusType) :: status                       ! Error status
    END TYPE IF_FileHandle_WriteTextLine_Out

    ! ==========================================================================
    ! PUBLIC INTERFACE
    ! ==========================================================================
    PUBLIC :: IF_FileHandle_Exists
    PUBLIC :: IF_FileHandle_GetSize
    PUBLIC :: IF_FileHandle_Delete
    PUBLIC :: IF_FileHandle_Copy
    PUBLIC :: IF_FileHandle_CreateDirectory

CONTAINS

    ! ==========================================================================
    ! TYPE-BOUND PROCEDURES
    ! ==========================================================================

    !> @brief Open file
    !! @param[inout] this File handle
    !! @param[in] filename File path
    !! @param[in] mode Access mode (optional)
    !! @param[in] format Format type (optional)
    !! @param[out] status Error status
    SUBROUTINE Open(this, filename, mode, format, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: filename
        INTEGER(i4), INTENT(IN), OPTIONAL :: mode
        INTEGER(i4), INTENT(IN), OPTIONAL :: format
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CHARACTER(LEN=20) :: action_str, form_str, status_str, access_str
        INTEGER(i4) :: iostat

        CALL init_error_status(status)

        ! Close if already open
        IF (this%is_open) THEN
            CALL this%Close(status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF

        ! Set mode and format
        IF (PRESENT(mode)) THEN
            this%mode = mode
        ELSE
            this%mode = IF_IO_MODE_READ
        END IF

        IF (PRESENT(format)) THEN
            this%format = format
        ELSE
            this%format = IF_IO_FORMAT_TEXT
        END IF

        ! Determine ACTION parameter
        SELECT CASE (this%mode)
            CASE (IF_IO_MODE_READ)
                action_str = 'READ'
                status_str = 'OLD'
            CASE (IF_IO_MODE_WRITE)
                action_str = 'WRITE'
                status_str = 'REPLACE'
            CASE (IF_IO_MODE_APPEND)
                action_str = 'WRITE'
                status_str = 'OLD'
            CASE (IF_IO_MODE_READWRITE)
                action_str = 'READWRITE'
                status_str = 'OLD'
            CASE DEFAULT
                status%status_code = IF_STATUS_INVALID
                status%message = "Invalid file mode"
                RETURN
        END SELECT

        ! Determine FORM parameter
        SELECT CASE (this%format)
            CASE (IF_IO_FORMAT_TEXT)
                form_str = 'FORMATTED'
                access_str = 'SEQUENTIAL'
            CASE (IF_IO_FORMAT_BINARY)
                form_str = 'UNFORMATTED'
                access_str = 'SEQUENTIAL'
            CASE (IF_IO_FORMAT_STREAM)
                form_str = 'UNFORMATTED'
                access_str = 'STREAM'
            CASE DEFAULT
                status%status_code = IF_STATUS_INVALID
                status%message = "Invalid file format"
                RETURN
        END SELECT

        ! Open file
        OPEN(NEWUNIT=this%unit, FILE=TRIM(filename), &
             ACTION=TRIM(action_str), FORM=TRIM(form_str), &
             ACCESS=TRIM(access_str), STATUS=TRIM(status_str), &
             IOSTAT=iostat)

        IF (iostat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,A,A,I0)') &
                "Failed to open file: ", TRIM(filename), ", IOSTAT=", iostat
            RETURN
        END IF

        this%filename = TRIM(filename)
        this%is_open = .TRUE.
        this%position = 0_i8

        ! Get file size
        IF (this%mode == IF_IO_MODE_READ .OR. this%mode == IF_IO_MODE_READWRITE) THEN
            INQUIRE(UNIT=this%unit, SIZE=this%file_size, IOSTAT=iostat)
            IF (iostat /= 0) this%file_size = -1_i8
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE Open

    !> @brief Close file
    !! @param[inout] this File handle
    !! @param[out] status Error status
    SUBROUTINE Close(this, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: iostat

        CALL init_error_status(status)

        IF (.NOT. this%is_open) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        CLOSE(UNIT=this%unit, IOSTAT=iostat)

        IF (iostat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to close file, IOSTAT=", iostat
            RETURN
        END IF

        this%unit = -1
        this%is_open = .FALSE.
        this%position = 0_i8

        status%status_code = IF_STATUS_OK
    END SUBROUTINE Close

    !> @brief Read text line
    !! @param[inout] this File handle
    !! @param[out] line Read line
    !! @param[out] status Error status
    SUBROUTINE ReadTextLine(this, line, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(OUT) :: line
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: iostat

        CALL init_error_status(status)

        IF (.NOT. this%is_open) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        IF (this%format /= IF_IO_FORMAT_TEXT) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not opened in text mode"
            RETURN
        END IF

        READ(this%unit, '(A)', IOSTAT=iostat) line

        IF (iostat < 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "End of file reached"
            RETURN
        ELSE IF (iostat > 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Read error, IOSTAT=", iostat
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ReadTextLine

    !> @brief Write text line
    !! @param[inout] this File handle
    !! @param[in] line Line to write
    !! @param[out] status Error status
    SUBROUTINE WriteTextLine(this, line, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: line
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: iostat

        CALL init_error_status(status)

        IF (.NOT. this%is_open) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        IF (this%format /= IF_IO_FORMAT_TEXT) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not opened in text mode"
            RETURN
        END IF

        WRITE(this%unit, '(A)', IOSTAT=iostat) TRIM(line)

        IF (iostat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Write error, IOSTAT=", iostat
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE WriteTextLine

    !> @brief Read binary data
    !! @param[inout] this File handle
    !! @param[out] buffer Output buffer
    !! @param[in] n_bytes Number of bytes to read
    !! @param[out] status Error status
    SUBROUTINE ReadBinary(this, buffer, n_bytes, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(OUT) :: buffer(*)
        INTEGER(i8), INTENT(IN) :: n_bytes
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: iostat
        INTEGER(i8) :: n_words

        CALL init_error_status(status)

        IF (.NOT. this%is_open) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        IF (this%format == IF_IO_FORMAT_TEXT) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not opened in binary mode"
            RETURN
        END IF

        n_words = (n_bytes + 3_i8) / 4_i8  ! Round up to word boundary

        READ(this%unit, IOSTAT=iostat) buffer(1:n_words)

        IF (iostat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Binary read error, IOSTAT=", iostat
            RETURN
        END IF

        this%position = this%position + n_bytes
        status%status_code = IF_STATUS_OK
    END SUBROUTINE ReadBinary

    !> @brief Write binary data
    !! @param[inout] this File handle
    !! @param[in] buffer Input buffer
    !! @param[in] n_bytes Number of bytes to write
    !! @param[out] status Error status
    SUBROUTINE WriteBinary(this, buffer, n_bytes, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: buffer(*)
        INTEGER(i8), INTENT(IN) :: n_bytes
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: iostat
        INTEGER(i8) :: n_words

        CALL init_error_status(status)

        IF (.NOT. this%is_open) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        IF (this%format == IF_IO_FORMAT_TEXT) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not opened in binary mode"
            RETURN
        END IF

        n_words = (n_bytes + 3_i8) / 4_i8  ! Round up to word boundary

        WRITE(this%unit, IOSTAT=iostat) buffer(1:n_words)

        IF (iostat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Binary write error, IOSTAT=", iostat
            RETURN
        END IF

        this%position = this%position + n_bytes
        status%status_code = IF_STATUS_OK
    END SUBROUTINE WriteBinary

    !> @brief Rewind file
    !! @param[inout] this File handle
    !! @param[out] status Error status
    SUBROUTINE Rewind(this, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: iostat

        CALL init_error_status(status)

        IF (.NOT. this%is_open) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        REWIND(UNIT=this%unit, IOSTAT=iostat)

        IF (iostat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0)') "Failed to rewind file, IOSTAT=", iostat
            RETURN
        END IF

        this%position = 0_i8
        status%status_code = IF_STATUS_OK
    END SUBROUTINE Rewind

    !> @brief Set file position
    !! @param[inout] this File handle
    !! @param[in] position File position
    !! @param[out] status Error status
    SUBROUTINE SetPosition(this, position, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        INTEGER(i8), INTENT(IN) :: position
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (.NOT. this%is_open) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        ! Stream access supports positioning
        IF (this%format == IF_IO_FORMAT_STREAM) THEN
            READ(this%unit, POS=position)
            this%position = position
            status%status_code = IF_STATUS_OK
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = "Position setting only supported for stream access"
        END IF
    END SUBROUTINE SetPosition

    !> @brief Flush file buffer
    !! @param[inout] this File handle
    !! @param[out] status Error status
    SUBROUTINE Flush(this, status)
        CLASS(IF_FileHandle), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (.NOT. this%is_open) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF

        FLUSH(this%unit)

        status%status_code = IF_STATUS_OK
    END SUBROUTINE Flush

    !> @brief Get file position
    !! @param[in] this File handle
    !! @return File position
    FUNCTION GetPosition(this) RESULT(position)
        CLASS(IF_FileHandle), INTENT(IN) :: this
        INTEGER(i8) :: position

        position = this%position
    END FUNCTION GetPosition

    !> @brief Check if file is open
    !! @param[in] this File handle
    !! @return .TRUE. if file is open, .FALSE. otherwise
    FUNCTION IsOpen(this) RESULT(is_open)
        CLASS(IF_FileHandle), INTENT(IN) :: this
        LOGICAL :: is_open

        is_open = this%is_open
    END FUNCTION IsOpen

    ! ==========================================================================
    ! STANDALONE PROCEDURES
    ! ==========================================================================

    !> @brief Check if file exists
    !! @param[in] filename File path
    !! @return .TRUE. if file exists, .FALSE. otherwise
    FUNCTION IF_FileHandle_Exists(filename) RESULT(exists)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        LOGICAL :: exists

        INQUIRE(FILE=TRIM(filename), EXIST=exists)
    END FUNCTION IF_FileHandle_Exists

    !> @brief Get file size
    !! @param[in] filename File path
    !! @return File size in bytes, or -1 if error
    FUNCTION IF_FileHandle_GetSize(filename) RESULT(file_size)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        INTEGER(i8) :: file_size

        INTEGER(i4) :: iostat

        INQUIRE(FILE=TRIM(filename), SIZE=file_size, IOSTAT=iostat)

        IF (iostat /= 0) file_size = -1_i8
    END FUNCTION IF_FileHandle_GetSize

    !> @brief Delete file
    !! @param[in] filename File path
    !! @param[out] status Error status
    SUBROUTINE IF_FileHandle_Delete(filename, status)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: unit, iostat

        CALL init_error_status(status)

        IF (.NOT. IF_FileHandle_Exists(filename)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "File does not exist"
            RETURN
        END IF

        OPEN(NEWUNIT=unit, FILE=TRIM(filename), STATUS='OLD', IOSTAT=iostat)
        IF (iostat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Failed to open file for deletion"
            RETURN
        END IF

        CLOSE(UNIT=unit, STATUS='DELETE', IOSTAT=iostat)

        IF (iostat /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Failed to delete file"
            RETURN
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_FileHandle_Delete

    !> @brief Copy file
    !! @param[in] src_filename Source file path
    !! @param[in] dst_filename Destination file path
    !! @param[out] status Error status
    SUBROUTINE IF_FileHandle_Copy(src_filename, dst_filename, status)
        CHARACTER(LEN=*), INTENT(IN) :: src_filename
        CHARACTER(LEN=*), INTENT(IN) :: dst_filename
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(IF_FileHandle) :: src_hdl, dst_hdl
        INTEGER(i4), ALLOCATABLE :: buf(:)
        INTEGER(i8) :: file_sz, bytes_rd, bytes_to_read
        INTEGER(i4) :: buf_sz, n_words
        TYPE(ErrorStatusType) :: tmp_status

        CALL init_error_status(status)

        ! Open source file
        CALL src_hdl%Open(src_filename, IF_IO_MODE_READ, IF_IO_FORMAT_BINARY, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Open destination file
        CALL dst_hdl%Open(dst_filename, IF_IO_MODE_WRITE, IF_IO_FORMAT_BINARY, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL src_hdl%Close(tmp_status)
            RETURN
        END IF

        ! Copy file in chunks
        buf_sz = 1024 * 1024  ! 1MB buffer
        ALLOCATE(buf(buf_sz))

        file_sz = src_hdl%file_size
        bytes_rd = 0_i8

        DO WHILE (bytes_rd < file_sz)
            bytes_to_read = MIN(INT(buf_sz * 4, KIND=i8), file_sz - bytes_rd)
            n_words = INT((bytes_to_read + 3_i8) / 4_i8, KIND=i4)
            
            ! Read binary data
            CALL src_hdl%ReadBinary(buf, bytes_to_read, status)
            IF (status%status_code /= IF_STATUS_OK) EXIT
            
            ! Write binary data
            CALL dst_hdl%WriteBinary(buf, bytes_to_read, status)
            IF (status%status_code /= IF_STATUS_OK) EXIT
            
            bytes_rd = bytes_rd + bytes_to_read
        END DO

        DEALLOCATE(buf)

        CALL src_hdl%Close(tmp_status)
        CALL dst_hdl%Close(tmp_status)

        IF (status%status_code == IF_STATUS_OK) THEN
            status%status_code = IF_STATUS_OK
        END IF
    END SUBROUTINE IF_FileHandle_Copy

    !> @brief Create directory
    !! @param[in] path Directory path
    !! @param[out] status Error status
    SUBROUTINE IF_FileHandle_CreateDirectory(path, status)
        CHARACTER(LEN=*), INTENT(IN) :: path
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        ! TODO: Implement directory creation (platform-specific)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_FileHandle_CreateDirectory

    ! ==========================================================================
    ! STRUCTURED INTERFACE PROCEDURES
    ! ==========================================================================

    !> @brief Open file (structured interface)
    !! @param[in] in Input structure
    !! @param[out] out Output structure
    SUBROUTINE IF_FileHandle_Open_Structured(in, out)
        TYPE(IF_FileHandle_Open_In), INTENT(IN) :: in
        TYPE(IF_FileHandle_Open_Out), INTENT(OUT) :: out

        ! G-08: Guard optional args with sentinel (mode/format=0 => use default)
        IF (in%mode /= IF_IO_MODE_UNSPECIFIED .AND. in%format /= IF_IO_FORMAT_UNSPECIFIED) THEN
            CALL out%handle%Open(in%filename, mode=in%mode, format=in%format, status=out%status)
        ELSE IF (in%mode /= IF_IO_MODE_UNSPECIFIED) THEN
            CALL out%handle%Open(in%filename, mode=in%mode, status=out%status)
        ELSE IF (in%format /= IF_IO_FORMAT_UNSPECIFIED) THEN
            CALL out%handle%Open(in%filename, format=in%format, status=out%status)
        ELSE
            CALL out%handle%Open(in%filename, status=out%status)
        END IF
    END SUBROUTINE IF_FileHandle_Open_Structured

    !> @brief Close file (structured interface)
    !! @param[in] in Input structure
    !! @param[out] out Output structure
    SUBROUTINE IF_FileHandle_Close_Structured(in, out)
        TYPE(IF_FileHandle_Close_In), INTENT(IN) :: in
        TYPE(IF_FileHandle_Close_Out), INTENT(OUT) :: out

        out%handle = in%handle
        CALL out%handle%Close(out%status)
    END SUBROUTINE IF_FileHandle_Close_Structured

    !> @brief Read text line (structured interface)
    !! @param[in] in Input structure
    !! @param[out] out Output structure
    SUBROUTINE IF_FileHandle_ReadTextLine_Structured(in, out)
        TYPE(IF_FileHandle_ReadTextLine_In), INTENT(IN) :: in
        TYPE(IF_FileHandle_ReadTextLine_Out), INTENT(OUT) :: out

        out%handle = in%handle
        CALL out%handle%ReadTextLine(out%line, out%status)
    END SUBROUTINE IF_FileHandle_ReadTextLine_Structured

    !> @brief Write text line (structured interface)
    !! @param[in] in Input structure
    !! @param[out] out Output structure
    SUBROUTINE IF_FileHandle_WriteTextLine_Structured(in, out)
        TYPE(IF_FileHandle_WriteTextLine_In), INTENT(IN) :: in
        TYPE(IF_FileHandle_WriteTextLine_Out), INTENT(OUT) :: out

        out%handle = in%handle
        CALL out%handle%WriteTextLine(in%line, out%status)
    END SUBROUTINE IF_FileHandle_WriteTextLine_Structured

END MODULE IF_IO_File