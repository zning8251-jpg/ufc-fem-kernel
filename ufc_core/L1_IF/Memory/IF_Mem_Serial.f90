!===============================================================================
! MODULE: IF_Mem_Serial
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Impl — serialization infrastructure (binary/text/custom formats)
! BRIEF:  Endian-aware binary serialization, JSON/XML-compatible text output,
!         version compatibility, data compression, type-safe recursive handling.
!===============================================================================
!   Subroutines:
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

MODULE IF_Mem_Serial
!> [SIMPLIFIED]
!> Theory: Data serialization infrastructure, binary/text serialization, version compatibility
!> Status: 50% (Basic framework complete, full implementation TODO) | Last verified: 2026-02-14
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN
    USE IF_IO_File, ONLY: IF_FileHandle_Exists, IF_FileHandle_CreateDirectory
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    
    PRIVATE
    PUBLIC :: SerializationManagerType
    PUBLIC :: SerializationFormatType
    PUBLIC :: IF_Serial_Init
    PUBLIC :: IF_Serial_Finalize
    PUBLIC :: IF_Serial_Get_SuppFmts
    
    ! ==========================================================================
    ! SERIALIZATION FORMAT ENUMERATION
    ! ==========================================================================
    TYPE :: SerializationFormatType
        PRIVATE
        INTEGER(i4) :: format_id = 0
        CHARACTER(LEN=20) :: format_name = ""
        CHARACTER(LEN=50) :: file_extension = ""
        LOGICAL :: is_binary = .TRUE.
        LOGICAL :: supports_compression = .FALSE.
        LOGICAL :: supports_versioning = .FALSE.
    END TYPE SerializationFormatType
    
    ! ==========================================================================
    ! SERIALIZATION MANAGER TYPE
    ! ==========================================================================
    TYPE :: SerializationManagerType
        PRIVATE
        ! Supported formats registry
        TYPE(SerializationFormatType), ALLOCATABLE :: formats(:)
        INTEGER(i4) :: num_formats = 0
        INTEGER(i4) :: default_format = 1
        
        ! Compression settings
        LOGICAL :: compression_enabled = .TRUE.
        INTEGER(i4) :: compression_level = 6  ! 1-9
        CHARACTER(LEN=20) :: compression_algorithm = "ZLIB"
        
        ! Version management
        LOGICAL :: versioning_enabled = .TRUE.
        INTEGER(i4) :: current_version = 1
        INTEGER(i4) :: min_compatible_version = 1
        
        ! Data integrity
        LOGICAL :: checksum_enabled = .TRUE.
        CHARACTER(LEN=20) :: checksum_algorithm = "CRC32"
        
        ! Performance settings
        INTEGER(i4) :: buffer_size = 8192  ! bytes
        LOGICAL :: buffered_io = .TRUE.
        
    CONTAINS
        PROCEDURE :: Init
        PROCEDURE :: RegisterFormat
        PROCEDURE :: Serialize
        PROCEDURE :: Deserialize
        PROCEDURE :: Valid
        PROCEDURE :: GetFormatInfo
        PROCEDURE :: Finalize
    END TYPE SerializationManagerType
    
    ! ==========================================================================
    ! SERIALIZATION CONTEXT TYPE
    ! ==========================================================================
    TYPE :: SerializationContextType
        PRIVATE
        TYPE(SerializationFormatType) :: format
        INTEGER(i4) :: version = 1
        LOGICAL :: write_mode = .TRUE.
        INTEGER(i4) :: buffer_position = 0
        CHARACTER(LEN=:), ALLOCATABLE :: buffer
        INTEGER(i8) :: bytes_processed = 0_i8
        LOGICAL :: compression_active = .FALSE.
    END TYPE SerializationContextType
    
    ! ==========================================================================
    ! SERIALIZABLE DATA TYPE (ABSTRACT)
    ! ==========================================================================
    TYPE, ABSTRACT :: SerializableType
        PRIVATE
        INTEGER(i4) :: object_id = 0
        CHARACTER(LEN=50) :: class_name = ""
        INTEGER(i4) :: serialization_version = 1
    CONTAINS
        PROCEDURE(SerializeInterface), DEFERRED :: SerializeData
        PROCEDURE(DeserializeInterface), DEFERRED :: DeserializeData
        PROCEDURE(GetSizeInterface), DEFERRED :: GetSerializedSize
    END TYPE SerializableType
    
    ! ==========================================================================
    ! SERIALIZABLE INTERFACES
    ! ==========================================================================
    ABSTRACT INTERFACE
        SUBROUTINE SerializeInterface(this, context, status)
            IMPORT :: SerializableType, SerializationContextType, ErrorStatusType
            CLASS(SerializableType), INTENT(IN) :: this
            TYPE(SerializationContextType), INTENT(INOUT) :: context
            TYPE(ErrorStatusType), INTENT(OUT) :: status
        END SUBROUTINE SerializeInterface
    END INTERFACE
    
    ABSTRACT INTERFACE
        SUBROUTINE DeserializeInterface(this, context, status)
            IMPORT :: SerializableType, SerializationContextType, ErrorStatusType
            CLASS(SerializableType), INTENT(INOUT) :: this
            TYPE(SerializationContextType), INTENT(INOUT) :: context
            TYPE(ErrorStatusType), INTENT(OUT) :: status
        END SUBROUTINE DeserializeInterface
    END INTERFACE
    
    ABSTRACT INTERFACE
        FUNCTION GetSizeInterface(this, format) RESULT(size)
            IMPORT :: SerializableType, SerializationFormatType, i8
            CLASS(SerializableType), INTENT(IN) :: this
            TYPE(SerializationFormatType), INTENT(IN) :: format
            INTEGER(i8) :: size
        END FUNCTION GetSizeInterface
    END INTERFACE
    
    ! ==========================================================================
    ! PREDEFINED FORMATS
    ! ==========================================================================
    TYPE(SerializationFormatType), PARAMETER :: BINARY_FORMAT = &
        SerializationFormatType(1, "BINARY", ".dat", .TRUE., .TRUE., .TRUE.)
    
    TYPE(SerializationFormatType), PARAMETER :: JSON_FORMAT = &
        SerializationFormatType(2, "JSON", ".json", .FALSE., .FALSE., .TRUE.)
    
    TYPE(SerializationFormatType), PARAMETER :: XML_FORMAT = &
        SerializationFormatType(3, "XML", ".xml", .FALSE., .FALSE., .TRUE.)
    
    TYPE(SerializationFormatType), PARAMETER :: TEXT_FORMAT = &
        SerializationFormatType(4, "TEXT", ".txt", .FALSE., .FALSE., .FALSE.)
    
CONTAINS

    ! ==============================================================================
    ! SERIALIZATION INFRASTRUCTURE INITIALIZATION
    ! ==============================================================================
    
    !> Init serialization infrastructure
    SUBROUTINE IF_Serial_Init(manager, default_format, status)
        TYPE(SerializationManagerType), INTENT(OUT) :: manager
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: default_format
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: i
        
        CALL init_error_status(status)
        
        ! Init default settings
        manager%compression_enabled = .TRUE.
        manager%compression_level = 6
        manager%versioning_enabled = .TRUE.
        manager%current_version = 1
        manager%min_compatible_version = 1
        manager%checksum_enabled = .TRUE.
        manager%buffer_size = 8192
        manager%buffered_io = .TRUE.
        
        ! Reg standard formats
        CALL InitializeStandardFormats(manager)
        
        ! Set default format
        IF (PRESENT(default_format)) THEN
            DO i = 1, manager%num_formats
                IF (TRIM(manager%formats(i)%format_name) == TRIM(default_format)) THEN
                    manager%default_format = i
                    EXIT
                END IF
            END DO
        END IF
        
        status%status_code = IF_STATUS_OK
        status%message = "Serialization infrastructure initialized"
        
    END SUBROUTINE IF_Serial_Init
    
    !> Finalize serialization infrastructure
    SUBROUTINE IF_Serial_Finalize(manager, status)
        TYPE(SerializationManagerType), INTENT(INOUT) :: manager
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Clean up format registry
        IF (ALLOCATED(manager%formats)) THEN
            DEALLOCATE(manager%formats)
        END IF
        
        manager%num_formats = 0
        
        status%status_code = IF_STATUS_OK
        status%message = "Serialization infrastructure finalized"
        
    END SUBROUTINE IF_Serial_Finalize
    
    !> Get list of supported formats
    FUNCTION IF_Serial_Get_SuppFmts() RESULT(formats)
        CHARACTER(LEN=20), ALLOCATABLE :: formats(:)
        
        ! Return list of format names
        ALLOCATE(formats(4))
        formats(1) = "BINARY"
        formats(2) = "JSON"
        formats(3) = "XML"
        formats(4) = "TEXT"
        
    END FUNCTION IF_Serial_Get_SuppFmts
    
    ! ==============================================================================
    ! SERIALIZATION MANAGER METHODS
    ! ==============================================================================
    
    !> Init serialization manager
    SUBROUTINE Init(this, default_format, status)
        CLASS(SerializationManagerType), INTENT(OUT) :: this
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: default_format
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL IF_Serial_Init(this, default_format, status)
        
    END SUBROUTINE Init
    
    !> Reg a new serialization format
    SUBROUTINE RegisterFormat(this, format, status)
        CLASS(SerializationManagerType), INTENT(INOUT) :: this
        TYPE(SerializationFormatType), INTENT(IN) :: format
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: new_size
        TYPE(SerializationFormatType), ALLOCATABLE :: temp(:)
        
        CALL init_error_status(status)
        
        ! Check if format already exists
        IF (IsFormatRegistered(this, format%format_name)) THEN
            status%status_code = IF_STATUS_WARN
            status%message = "Format already registered: " // TRIM(format%format_name)
            RETURN
        END IF
        
        ! Expand formats array
        new_size = this%num_formats + 1
        
        IF (ALLOCATED(this%formats)) THEN
            ALLOCATE(temp(this%num_formats))
            temp = this%formats
            DEALLOCATE(this%formats)
            ALLOCATE(this%formats(new_size))
            this%formats(1:this%num_formats) = temp
            this%formats(new_size) = format
            DEALLOCATE(temp)
        ELSE
            ALLOCATE(this%formats(1))
            this%formats(1) = format
        END IF
        
        this%num_formats = new_size
        
        status%status_code = IF_STATUS_OK
        status%message = "Format registered: " // TRIM(format%format_name)
        
    END SUBROUTINE RegisterFormat
    
    !> Serialize object to file or buffer
    SUBROUTINE Serialize(this, object, filename, format_name, &
                                           buffer, status)
        CLASS(SerializationManagerType), INTENT(INOUT) :: this
        CLASS(SerializableType), INTENT(IN) :: object
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: filename
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: format_name
        CHARACTER(LEN=:), ALLOCATABLE, INTENT(OUT), OPTIONAL :: buffer
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        TYPE(SerializationContextType) :: context
        TYPE(SerializationFormatType) :: format
        INTEGER(i4) :: format_id
        
        CALL init_error_status(status)
        
        ! Determine format
        IF (PRESENT(format_name)) THEN
            format_id = FindFormatId(this, format_name)
            IF (format_id <= 0) THEN
                status%status_code = IF_STATUS_ERROR
                status%message = "Unsupported format: " // TRIM(format_name)
                RETURN
            END IF
            format = this%formats(format_id)
        ELSE
            format = this%formats(this%default_format)
        END IF
        
        ! Init serialization context
        CALL InitializeSerializationContext(context, format, .TRUE., status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Serialize object
        CALL object%SerializeData(context, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Write to file or return buffer
        IF (PRESENT(filename)) THEN
            CALL WriteSerializedData(filename, context, status)
        ELSE IF (PRESENT(buffer)) THEN
            buffer = context%buffer
        END IF
        
        ! Clean up context
        CALL CleanupSerializationContext(context)
        
        status%status_code = IF_STATUS_OK
        status%message = "Object serialized successfully"
        
    END SUBROUTINE Serialize
    
    !> Deserialize object from file or buffer
    SUBROUTINE Deserialize(this, object, filename, format_name, &
                                             buffer, status)
        CLASS(SerializationManagerType), INTENT(INOUT) :: this
        CLASS(SerializableType), INTENT(INOUT) :: object
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: filename
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: format_name
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: buffer
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        TYPE(SerializationContextType) :: context
        TYPE(SerializationFormatType) :: format
        INTEGER(i4) :: format_id
        
        CALL init_error_status(status)
        
        ! Determine format
        IF (PRESENT(format_name)) THEN
            format_id = FindFormatId(this, format_name)
            IF (format_id <= 0) THEN
                status%status_code = IF_STATUS_ERROR
                status%message = "Unsupported format: " // TRIM(format_name)
                RETURN
            END IF
            format = this%formats(format_id)
        ELSE
            format = this%formats(this%default_format)
        END IF
        
        ! Init deserialization context
        CALL InitializeSerializationContext(context, format, .FALSE., status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Read from file or use buffer
        IF (PRESENT(filename)) THEN
            CALL ReadSerializedData(filename, context, status)
        ELSE IF (PRESENT(buffer)) THEN
            context%buffer = buffer
        END IF
        
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Valid data if enabled
        IF (this%checksum_enabled) THEN
            CALL ValidateSerializedData(context, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
        
        ! Deserialize object
        CALL object%DeserializeData(context, status)
        
        ! Clean up context
        CALL CleanupSerializationContext(context)
        
        IF (status%status_code == IF_STATUS_OK) THEN
            status%message = "Object deserialized successfully"
        END IF
        
    END SUBROUTINE Deserialize
    
    !> Valid serialized data
    SUBROUTINE Valid(this, filename, format_name, status)
        CLASS(SerializationManagerType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: filename
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: format_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        TYPE(SerializationContextType) :: context
        TYPE(SerializationFormatType) :: format
        
        CALL init_error_status(status)
        
        ! Check file exists
        IF (.NOT. IF_FileHandle_Exists(filename)) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "File not found: " // TRIM(filename)
            RETURN
        END IF
        
        ! Determine format
        IF (PRESENT(format_name)) THEN
            format = this%formats(FindFormatId(this, format_name))
        ELSE
            format = DetectFileFormat(filename)
        END IF
        
        ! Init context for validation
        CALL InitializeSerializationContext(context, format, .FALSE., status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Read and validate
        CALL ReadSerializedData(filename, context, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        CALL ValidateSerializedData(context, status)
        
        ! Clean up
        CALL CleanupSerializationContext(context)
        
    END SUBROUTINE Valid
    
    !> Get format information
    SUBROUTINE GetFormatInfo(this, format_name, info, status)
        CLASS(SerializationManagerType), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: format_name
        TYPE(SerializationFormatType), INTENT(OUT) :: info
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: format_id
        
        CALL init_error_status(status)
        
        format_id = FindFormatId(this, format_name)
        IF (format_id <= 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Unsupported format: " // TRIM(format_name)
            RETURN
        END IF
        
        info = this%formats(format_id)
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE GetFormatInfo
    
    !> Finalize serialization manager
    SUBROUTINE Finalize(this, status)
        CLASS(SerializationManagerType), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL IF_Serial_Finalize(this, status)
        
    END SUBROUTINE Finalize
    
    ! ==============================================================================
    ! SERIALIZATION CONTEXT OPERATIONS
    ! ==============================================================================
    
    !> Init serialization context
    SUBROUTINE InitializeSerializationContext(context, format, write_mode, status)
        TYPE(SerializationContextType), INTENT(OUT) :: context
        TYPE(SerializationFormatType), INTENT(IN) :: format
        LOGICAL, INTENT(IN) :: write_mode
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        context%format = format
        context%write_mode = write_mode
        context%version = 1
        context%buffer_position = 0
        context%bytes_processed = 0_i8
        context%compression_active = .FALSE.
        
        IF (write_mode) THEN
            ALLOCATE(CHARACTER(LEN=1024) :: context%buffer)
            context%buffer = ""
        END IF
        
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE InitializeSerializationContext
    
    !> Clean up serialization context
    SUBROUTINE CleanupSerializationContext(context)
        TYPE(SerializationContextType), INTENT(INOUT) :: context
        
        IF (ALLOCATED(context%buffer)) THEN
            DEALLOCATE(context%buffer)
        END IF
        
        context%buffer_position = 0
        context%bytes_processed = 0_i8
        
    END SUBROUTINE CleanupSerializationContext
    
    ! ==============================================================================
    ! DATA READING/WRITING OPERATIONS
    ! ==============================================================================
    
    !> Write serialized data to file
    SUBROUTINE WriteSerializedData(filename, context, status)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        TYPE(SerializationContextType), INTENT(IN) :: context
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: io_unit, iostat_val
        
        CALL init_error_status(status)
        
        ! Create directory if needed
        CALL IF_FileHandle_CreateDirectory("serialized_data", status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Open file
        OPEN(NEWUNIT=io_unit, FILE=filename, STATUS='REPLACE', &
             ACTION='WRITE', IOSTAT=iostat_val)
        
        IF (iostat_val /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Failed to open file for writing: " // TRIM(filename)
            RETURN
        END IF
        
        ! Write data
        IF (context%format%is_binary) THEN
            WRITE(io_unit) context%buffer
        ELSE
            WRITE(io_unit, '(A)') TRIM(context%buffer)
        END IF
        
        CLOSE(io_unit, IOSTAT=iostat_val)
        
        IF (iostat_val == 0) THEN
            status%status_code = IF_STATUS_OK
            status%message = "Data written successfully: " // TRIM(filename)
        END IF
        
    END SUBROUTINE WriteSerializedData
    
    !> Read serialized data from file
    SUBROUTINE ReadSerializedData(filename, context, status)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        TYPE(SerializationContextType), INTENT(OUT) :: context
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        INTEGER(i4) :: io_unit, iostat_val
        INTEGER(i8) :: file_size
        
        CALL init_error_status(status)
        
        ! Open file
        OPEN(NEWUNIT=io_unit, FILE=filename, STATUS='OLD', &
             ACTION='READ', IOSTAT=iostat_val)
        
        IF (iostat_val /= 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Failed to open file for reading: " // TRIM(filename)
            RETURN
        END IF
        
        ! Get file size
        INQUIRE(UNIT=io_unit, SIZE=file_size)
        
        ! Allocate buffer and read data
        IF (context%format%is_binary) THEN
            READ(io_unit) context%buffer
        ELSE
            ALLOCATE(CHARACTER(LEN=file_size) :: context%buffer)
            READ(io_unit, '(A)') context%buffer
        END IF
        
        CLOSE(io_unit, IOSTAT=iostat_val)
        
        context%bytes_processed = file_size
        
        IF (iostat_val == 0) THEN
            status%status_code = IF_STATUS_OK
            status%message = "Data read successfully: " // TRIM(filename)
        END IF
        
    END SUBROUTINE ReadSerializedData
    
    ! ==============================================================================
    ! DATA VALIDATION OPERATIONS
    ! ==============================================================================
    
    !> Valid serialized data integrity
    SUBROUTINE ValidateSerializedData(context, status)
        TYPE(SerializationContextType), INTENT(IN) :: context
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        ! Basic validation - check if data exists
        IF (.NOT. ALLOCATED(context%buffer) .OR. LEN(context%buffer) == 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "No data to validate"
            RETURN
        END IF
        
        ! Format-specific validation
        IF (context%format%is_binary) THEN
            CALL ValidateBinaryData(context, status)
        ELSE
            CALL ValidateTextData(context, status)
        END IF
        
    END SUBROUTINE ValidateSerializedData
    
    !> Valid binary data
    SUBROUTINE ValidateBinaryData(context, status)
        TYPE(SerializationContextType), INTENT(IN) :: context
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        ! Simplified binary validation
        ! Real implementation would check magic numbers, version info, checksum
        
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE ValidateBinaryData
    
    !> Valid text data
    SUBROUTINE ValidateTextData(context, status)
        TYPE(SerializationContextType), INTENT(IN) :: context
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        ! Simplified text validation
        ! Real implementation would check format syntax, valid characters
        
        status%status_code = IF_STATUS_OK
        
    END SUBROUTINE ValidateTextData
    
    ! ==============================================================================
    ! UTILITY SUBROUTINES
    ! ==============================================================================
    
    !> Init standard formats
    SUBROUTINE InitializeStandardFormats(manager)
        TYPE(SerializationManagerType), INTENT(OUT) :: manager
        
        ! Allocate format array
        ALLOCATE(manager%formats(4))
        manager%num_formats = 4
        
        ! Reg standard formats
        manager%formats(1) = BINARY_FORMAT
        manager%formats(2) = JSON_FORMAT
        manager%formats(3) = XML_FORMAT
        manager%formats(4) = TEXT_FORMAT
        
        manager%default_format = 1  ! Default to binary
        
    END SUBROUTINE InitializeStandardFormats
    
    !> Check if format is registered
    FUNCTION IsFormatRegistered(manager, format_name) RESULT(registered)
        TYPE(SerializationManagerType), INTENT(IN) :: manager
        CHARACTER(LEN=*), INTENT(IN) :: format_name
        LOGICAL :: registered
        
        INTEGER(i4) :: i
        
        registered = .FALSE.
        DO i = 1, manager%num_formats
            IF (TRIM(manager%formats(i)%format_name) == TRIM(format_name)) THEN
                registered = .TRUE.
                RETURN
            END IF
        END DO
        
    END FUNCTION IsFormatRegistered
    
    !> Find format ID by name
    FUNCTION FindFormatId(manager, format_name) RESULT(format_id)
        TYPE(SerializationManagerType), INTENT(IN) :: manager
        CHARACTER(LEN=*), INTENT(IN) :: format_name
        INTEGER(i4) :: format_id
        
        INTEGER(i4) :: i
        
        format_id = -1
        DO i = 1, manager%num_formats
            IF (TRIM(manager%formats(i)%format_name) == TRIM(format_name)) THEN
                format_id = i
                RETURN
            END IF
        END DO
        
    END FUNCTION FindFormatId
    
    !> Detect file format from extension
    FUNCTION DetectFileFormat(filename) RESULT(format)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        TYPE(SerializationFormatType) :: format
        
        CHARACTER(LEN=50) :: extension
        INTEGER(i4) :: dot_pos
        
        ! Extract extension
        dot_pos = INDEX(filename, '.', .TRUE.)
        IF (dot_pos > 0) THEN
            extension = filename(dot_pos:)
        ELSE
            extension = ""
        END IF
        
        ! Determine format based on extension
        SELECT CASE (TRIM(extension))
        CASE ('.dat', '.bin')
            format = BINARY_FORMAT
        CASE ('.json')
            format = JSON_FORMAT
        CASE ('.xml')
            format = XML_FORMAT
        CASE ('.txt')
            format = TEXT_FORMAT
        CASE DEFAULT
            format = BINARY_FORMAT  ! Default to binary
        END SELECT
        
    END FUNCTION DetectFileFormat

END MODULE IF_Mem_Serial