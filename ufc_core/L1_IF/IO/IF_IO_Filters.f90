!===============================================================================
! MODULE: IF_IO_Filters
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Impl — generic IO filter abstraction (compress / encrypt pipelines)
! BRIEF:  Filter interface, identity filter, XOR encryption read/write.
!===============================================================================
MODULE IF_IO_Filters
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: i4
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACE (IF_IO_Filter_Options is public via TYPE, PUBLIC)
    ! ==========================================================================
    PUBLIC :: IF_IO_Filter_Proc
    PUBLIC :: IF_IO_FILTER_FLAG_COMPRESS, IF_IO_FILTER_FLAG_ENCRYPT
    PUBLIC :: IF_IO_Filter_Init_Options
    PUBLIC :: IF_IO_Filter_Set_Default_Options
    PUBLIC :: IF_IO_Filter_Identity
    PUBLIC :: IF_IO_Filter_XOR_Write, IF_IO_Filter_XOR_Read

    ! ==========================================================================
    ! FILTER FLAGS
    ! ==========================================================================
    INTEGER(i4), PARAMETER :: IF_IO_FILTER_FLAG_COMPRESS = 1_i4
    INTEGER(i4), PARAMETER :: IF_IO_FILTER_FLAG_ENCRYPT  = 2_i4

    ! ==========================================================================
    ! FILTER OPTIONS TYPE
    ! ==========================================================================
    TYPE, PUBLIC :: IF_IO_Filter_Options
        INTEGER(i4) :: default_format_type   = 0_i4
        INTEGER(i4) :: default_compress_type = 0_i4
        INTEGER(i4) :: default_encrypt_type  = 0_i4
    END TYPE IF_IO_Filter_Options

    ! ==========================================================================
    ! FILTER PROCEDURE INTERFACE
    ! ==========================================================================
    ABSTRACT INTERFACE
        SUBROUTINE IF_IO_Filter_Proc(input, input_size, output, output_size, io_flags, status)
            USE IF_Err_Brg, ONLY: ErrorStatusType
            USE IF_Prec_Core, ONLY: i4
            CHARACTER(LEN=1), INTENT(IN)  :: input(:)
            INTEGER(i4),      INTENT(IN)  :: input_size
            CHARACTER(LEN=1), INTENT(OUT) :: output(:)
            INTEGER(i4),      INTENT(OUT) :: output_size
            INTEGER(i4),      INTENT(IN)  :: io_flags
            TYPE(ErrorStatusType), INTENT(OUT) :: status
        END SUBROUTINE IF_IO_Filter_Proc
    END INTERFACE

CONTAINS

    !> @brief Identity filter (no-op)
    !! @param[in] input Input data
    !! @param[in] input_size Input size
    !! @param[out] output Output data
    !! @param[out] output_size Output size
    !! @param[in] io_flags I/O flags
    !! @param[out] status Error status
    SUBROUTINE IF_IO_Filter_Identity(input, input_size, output, output_size, io_flags, status)
        CHARACTER(LEN=1), INTENT(IN)  :: input(:)
        INTEGER(i4),      INTENT(IN)  :: input_size
        CHARACTER(LEN=1), INTENT(OUT) :: output(:)
        INTEGER(i4),      INTENT(OUT) :: output_size
        INTEGER(i4),      INTENT(IN)  :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: n

        CALL init_error_status(status)

        IF (input_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "IF_IO_Filter_Identity: negative input_size"
            RETURN
        END IF

        n = input_size
        IF (n > SIZE(output)) n = SIZE(output)
        IF (n > SIZE(input))  n = SIZE(input)

        IF (n > 0) output(1:n) = input(1:n)
        output_size = n
    END SUBROUTINE IF_IO_Filter_Identity

    !> @brief Initialize filter options
    !! @param[out] options Filter options
    SUBROUTINE IF_IO_Filter_Init_Options(options)
        TYPE(IF_IO_Filter_Options), INTENT(OUT) :: options

        options%default_format_type   = 0_i4
        options%default_compress_type = 0_i4
        options%default_encrypt_type  = 0_i4
    END SUBROUTINE IF_IO_Filter_Init_Options

    !> @brief Set default filter options
    !! @param[inout] options Filter options
    !! @param[in] format_type Format type (optional)
    !! @param[in] compress_type Compress type (optional)
    !! @param[in] encrypt_type Encrypt type (optional)
    !! @param[out] status Error status
    SUBROUTINE IF_IO_Filter_Set_Default_Options(options, format_type, compress_type, encrypt_type, status)
        TYPE(IF_IO_Filter_Options), INTENT(INOUT) :: options
        INTEGER(i4), INTENT(IN), OPTIONAL :: format_type
        INTEGER(i4), INTENT(IN), OPTIONAL :: compress_type
        INTEGER(i4), INTENT(IN), OPTIONAL :: encrypt_type
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (PRESENT(format_type))   options%default_format_type   = format_type
        IF (PRESENT(compress_type)) options%default_compress_type = compress_type
        IF (PRESENT(encrypt_type))  options%default_encrypt_type  = encrypt_type

        status%status_code = IF_STATUS_OK
    END SUBROUTINE IF_IO_Filter_Set_Default_Options

    !> @brief XOR decryption filter (read)
    !! @param[in] input Input data
    !! @param[in] input_size Input size
    !! @param[out] output Output data
    !! @param[out] output_size Output size
    !! @param[in] io_flags I/O flags
    !! @param[out] status Error status
    SUBROUTINE IF_IO_Filter_XOR_Read(input, input_size, output, output_size, io_flags, status)
        CHARACTER(LEN=1), INTENT(IN)  :: input(:)
        INTEGER(i4),      INTENT(IN)  :: input_size
        CHARACTER(LEN=1), INTENT(OUT) :: output(:)
        INTEGER(i4),      INTENT(OUT) :: output_size
        INTEGER(i4),      INTENT(IN)  :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4), PARAMETER :: IF_KEY = 123_i4
        INTEGER(i4) :: i, ich

        CALL init_error_status(status)

        IF (input_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "IF_IO_Filter_XOR_Read: negative input_size"
            RETURN
        END IF

        IF (input_size > SIZE(input) .OR. input_size > SIZE(output)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "IF_IO_Filter_XOR_Read: input_size larger than buffer"
            RETURN
        END IF

        DO i = 1, input_size
            ich = IACHAR(input(i))
            ich = IEOR(ich, IF_KEY)
            output(i) = ACHAR(ich)
        END DO

        output_size = input_size
    END SUBROUTINE IF_IO_Filter_XOR_Read

    !> @brief XOR encryption filter (write)
    !! @param[in] input Input data
    !! @param[in] input_size Input size
    !! @param[out] output Output data
    !! @param[out] output_size Output size
    !! @param[in] io_flags I/O flags
    !! @param[out] status Error status
    SUBROUTINE IF_IO_Filter_XOR_Write(input, input_size, output, output_size, io_flags, status)
        CHARACTER(LEN=1), INTENT(IN)  :: input(:)
        INTEGER(i4),      INTENT(IN)  :: input_size
        CHARACTER(LEN=1), INTENT(OUT) :: output(:)
        INTEGER(i4),      INTENT(OUT) :: output_size
        INTEGER(i4),      INTENT(IN)  :: io_flags
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4), PARAMETER :: IF_KEY = 123_i4
        INTEGER(i4) :: i, ich

        CALL init_error_status(status)

        IF (input_size < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "IF_IO_Filter_XOR_Write: negative input_size"
            RETURN
        END IF

        IF (input_size > SIZE(input) .OR. input_size > SIZE(output)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "IF_IO_Filter_XOR_Write: input_size larger than buffer"
            RETURN
        END IF

        DO i = 1, input_size
            ich = IACHAR(input(i))
            ich = IEOR(ich, IF_KEY)
            output(i) = ACHAR(ich)
        END DO

        output_size = input_size
    END SUBROUTINE IF_IO_Filter_XOR_Write

END MODULE IF_IO_Filters