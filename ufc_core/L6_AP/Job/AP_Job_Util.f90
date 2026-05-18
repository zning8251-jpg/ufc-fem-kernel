!===============================================================================
! MODULE: AP_Job_Util
! LAYER:  L6_AP
! DOMAIN: Job
! ROLE:   Util — unified utilities
! BRIEF:  Unified Job domain utilities (command, error, file I/O).
!===============================================================================

MODULE AP_Job_Util
    USE AP_Inp_Script, ONLY: Cmd_Reg, Cmd_FormatError
    USE AP_Inp_Def, ONLY: Cmd, CmdCtx
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_IO_ERROR
    USE IF_IO_File, ONLY: IF_FileHandle, IF_FileHandle_Exists, &
                          IO_MODE_READ, IO_MODE_WRITE, IO_FORMAT_TEXT
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    !=============================================================================
    ! ERROR CATEGORIES (from AP_Job_Util_Err)
    !=============================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CATEGORY_NETWORK  = 10_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CATEGORY_MULTIPHYSICS = 19_i4

    !=============================================================================
    ! ERROR CODES: 7000-7999 (Application Layer)
    !=============================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_JOB_BASE = 7000_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_JOB_EXECUTION_FAILED = 7001_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_JOB_INITIALIZATION_FAILED = 7002_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_INPUT_BASE = 7100_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_INPUT_FILE_NOT_FOUND = 7101_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_INPUT_PARSE_ERROR = 7102_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_OUTPUT_BASE = 7200_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_OUTPUT_WRITE_FAILED = 7201_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_OUTPUT_FORMAT_ERROR = 7202_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_MULTIPHYSICS_BASE = 7300_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_MULTIPHYSICS_COUPLING_FAILED = 7301_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_NETWORK_BASE = 7400_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_NETWORK_CONNECTION_FAILED = 7401_i4
    INTEGER(i4), PARAMETER, PUBLIC :: AP_ERROR_CODE_NETWORK_TIMEOUT = 7402_i4

    !=============================================================================
    ! PUBLIC INTERFACES - Command (from AP_Job_Util_Cmd)
    !=============================================================================
    PUBLIC :: AP_Cmd_ValidateCommand
    PUBLIC :: AP_Cmd_ParseParameters
    PUBLIC :: AP_Cmd_ExtractName
    PUBLIC :: AP_Cmd_ExtractOption
    PUBLIC :: AP_Cmd_ExtractNumericParams
    PUBLIC :: AP_Cmd_ExtractStringParams
    PUBLIC :: AP_Cmd_FormatCommand
    PUBLIC :: AP_CmdUtils_Unified_Execute
    PUBLIC :: AP_CmdUtils_Unified_Cfg

    !=============================================================================
    ! PUBLIC INTERFACES - File (from AP_Job_Util_File)
    !=============================================================================
    PUBLIC :: AP_File_ReadLines
    PUBLIC :: AP_File_WriteLines
    PUBLIC :: AP_File_GetBasename
    PUBLIC :: AP_File_GetExtension
    PUBLIC :: AP_File_JoinPath
    PUBLIC :: AP_File_NormalizePath
    PUBLIC :: AP_File_IsAbsolutePath
    PUBLIC :: AP_File_Unified_Execute
    PUBLIC :: AP_File_Unified_Cfg

CONTAINS

    !=============================================================================
    ! COMMAND UTILITIES
    !=============================================================================

    FUNCTION AP_Cmd_ExtractName(cmd_str) RESULT(name)
        CHARACTER(len=*), INTENT(IN) :: cmd_str
        CHARACTER(len=16) :: name
        INTEGER(i4) :: space_pos
        name = ""
        space_pos = INDEX(cmd_str, ' ')
        IF (space_pos > 0) THEN
            name = cmd_str(1:MIN(space_pos-1, 16))
        ELSE
            name = cmd_str(1:MIN(LEN_TRIM(cmd_str), 16))
        END IF
    END FUNCTION AP_Cmd_ExtractName

    SUBROUTINE AP_Cmd_ExtractNumericParams(cmd, params, num_params)
        TYPE(Cmd), INTENT(IN) :: cmd
        REAL(wp), INTENT(OUT) :: params(:)
        INTEGER(i4), INTENT(OUT) :: num_params
        INTEGER(i4) :: i, max_params
        max_params = MIN(SIZE(params), 3)
        num_params = 0
        DO i = 1, max_params
            IF (cmd%params(i) /= 0.0_wp) THEN
                num_params = num_params + 1
                params(num_params) = cmd%params(i)
            END IF
        END DO
    END SUBROUTINE AP_Cmd_ExtractNumericParams

    FUNCTION AP_Cmd_ExtractOption(cmd_str) RESULT(option)
        CHARACTER(len=*), INTENT(IN) :: cmd_str
        CHARACTER(len=64) :: option
        INTEGER(i4) :: first_space, second_space
        option = ""
        first_space = INDEX(cmd_str, ' ')
        IF (first_space > 0) THEN
            second_space = INDEX(cmd_str(first_space+1:), ' ')
            IF (second_space > 0) THEN
                option = cmd_str(first_space+1:first_space+second_space-1)
            ELSE
                option = cmd_str(first_space+1:)
            END IF
        END IF
    END FUNCTION AP_Cmd_ExtractOption

    FUNCTION AP_Cmd_ExtractStringParams(cmd) RESULT(param_str)
        TYPE(Cmd), INTENT(IN) :: cmd
        CHARACTER(len=256) :: param_str
        param_str = cmd%param_str
    END FUNCTION AP_Cmd_ExtractStringParams

    FUNCTION AP_Cmd_FormatCommand(cmd) RESULT(cmd_str)
        TYPE(Cmd), INTENT(IN) :: cmd
        CHARACTER(len=512) :: cmd_str
        INTEGER(i4) :: i
        cmd_str = TRIM(cmd%name)
        IF (LEN_TRIM(cmd%opt) > 0) THEN
            cmd_str = TRIM(cmd_str) // ' ' // TRIM(cmd%opt)
        END IF
        DO i = 1, 3
            IF (cmd%params(i) /= 0.0_wp) THEN
                WRITE(cmd_str, '(A,1X,ES15.8)') TRIM(cmd_str), cmd%params(i)
            END IF
        END DO
        IF (LEN_TRIM(cmd%param_str) > 0) THEN
            cmd_str = TRIM(cmd_str) // ' ' // TRIM(cmd%param_str)
        END IF
    END FUNCTION AP_Cmd_FormatCommand

    SUBROUTINE AP_Cmd_ParseParameters(param_str, key_values, num_pairs, status)
        CHARACTER(len=*), INTENT(IN) :: param_str
        CHARACTER(len=64), INTENT(OUT) :: key_values(:,:)
        INTEGER(i4), INTENT(OUT) :: num_pairs
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, eq_pos, comma_pos, start_pos, max_pairs
        CHARACTER(len=256) :: remaining_str
        CALL init_error_status(status)
        max_pairs = SIZE(key_values, 2)
        num_pairs = 0
        remaining_str = TRIM(param_str)
        start_pos = 1
        DO WHILE (start_pos <= LEN_TRIM(remaining_str) .AND. num_pairs < max_pairs)
            eq_pos = INDEX(remaining_str(start_pos:), '=')
            IF (eq_pos == 0) EXIT
            eq_pos = eq_pos + start_pos - 1
            comma_pos = INDEX(remaining_str(eq_pos:), ',')
            IF (comma_pos == 0) THEN
                comma_pos = LEN_TRIM(remaining_str) + 1
            ELSE
                comma_pos = comma_pos + eq_pos - 1
            END IF
            num_pairs = num_pairs + 1
            key_values(1, num_pairs) = TRIM(remaining_str(start_pos:eq_pos-1))
            key_values(2, num_pairs) = TRIM(remaining_str(eq_pos+1:comma_pos-1))
            start_pos = comma_pos + 1
        END DO
        status%status_code = IF_STATUS_OK
    END SUBROUTINE AP_Cmd_ParseParameters

    SUBROUTINE AP_Cmd_ValidateCommand(cmd, is_valid, status)
        TYPE(Cmd), INTENT(IN) :: cmd
        LOGICAL, INTENT(OUT) :: is_valid
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        is_valid = .TRUE.
        IF (LEN_TRIM(cmd%name) == 0) THEN
            is_valid = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Cmd_ValidateCommand: Empty command name'
            RETURN
        END IF
        IF (LEN_TRIM(cmd%name) > 16) THEN
            is_valid = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Cmd_ValidateCommand: Command name too long'
            RETURN
        END IF
        IF (cmd%line < 0) THEN
            is_valid = .FALSE.
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Cmd_ValidateCommand: Invalid line number'
            RETURN
        END IF
        status%status_code = IF_STATUS_OK
    END SUBROUTINE AP_Cmd_ValidateCommand

    SUBROUTINE AP_CmdUtils_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_CmdUtils_Unified_Cfg: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE AP_CmdUtils_Unified_Cfg

    SUBROUTINE AP_CmdUtils_Unified_Execute(operation, cmd, is_valid, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(Cmd), INTENT(IN) :: cmd
        LOGICAL, INTENT(OUT), OPTIONAL :: is_valid
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        LOGICAL :: valid
        CALL init_error_status(status)
        IF (TRIM(operation) == 'VALIDATE' .OR. TRIM(operation) == 'validate') THEN
            CALL AP_Cmd_ValidateCommand(cmd, valid, status)
            IF (PRESENT(is_valid)) is_valid = valid
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_CmdUtils_Unified_Execute: unsupported operation ' // TRIM(operation)
        END IF
    END SUBROUTINE AP_CmdUtils_Unified_Execute

    !=============================================================================
    ! FILE UTILITIES
    !=============================================================================

    FUNCTION AP_File_GetBasename(filepath) RESULT(basename)
        CHARACTER(len=*), INTENT(IN) :: filepath
        CHARACTER(len=LEN(filepath)) :: basename
        INTEGER(i4) :: slash_pos
        slash_pos = MAX(INDEX(filepath, '/', BACK=.TRUE.), &
                       INDEX(filepath, '\', BACK=.TRUE.))
        IF (slash_pos > 0) THEN
            basename = filepath(slash_pos+1:)
        ELSE
            basename = filepath
        END IF
    END FUNCTION AP_File_GetBasename

    FUNCTION AP_File_GetExtension(filepath) RESULT(ext)
        CHARACTER(len=*), INTENT(IN) :: filepath
        CHARACTER(len=16) :: ext
        INTEGER(i4) :: dot_pos
        CHARACTER(len=LEN(filepath)) :: basename
        ext = ""
        basename = AP_File_GetBasename(filepath)
        dot_pos = INDEX(basename, '.', BACK=.TRUE.)
        IF (dot_pos > 0) THEN
            ext = basename(dot_pos+1:)
        END IF
    END FUNCTION AP_File_GetExtension

    FUNCTION AP_File_JoinPath(path1, path2) RESULT(joined_path)
        CHARACTER(len=*), INTENT(IN) :: path1, path2
        CHARACTER(len=LEN(path1)+LEN(path2)+1) :: joined_path
        CHARACTER(len=1) :: separator
        IF (INDEX(path1, '/') > 0) THEN
            separator = '/'
        ELSE
            separator = '\'
        END IF
        IF (LEN_TRIM(path1) > 0) THEN
            IF (path1(LEN_TRIM(path1):LEN_TRIM(path1)) == separator) THEN
                joined_path = TRIM(path1) // TRIM(path2)
            ELSE
                joined_path = TRIM(path1) // separator // TRIM(path2)
            END IF
        ELSE
            joined_path = TRIM(path2)
        END IF
    END FUNCTION AP_File_JoinPath

    FUNCTION AP_File_NormalizePath(filepath) RESULT(normalized_path)
        CHARACTER(len=*), INTENT(IN) :: filepath
        CHARACTER(len=LEN(filepath)) :: normalized_path
        INTEGER(i4) :: i, pos
        normalized_path = filepath
        DO i = 1, LEN_TRIM(normalized_path)
            IF (normalized_path(i:i) == '\') THEN
                normalized_path(i:i) = '/'
            END IF
        END DO
        DO WHILE (INDEX(normalized_path, '//') > 0)
            pos = INDEX(normalized_path, '//')
            IF (pos > 0) THEN
                normalized_path = normalized_path(1:pos) // normalized_path(pos+2:)
            ELSE
                EXIT
            END IF
        END DO
    END FUNCTION AP_File_NormalizePath

    FUNCTION AP_File_IsAbsolutePath(filepath) RESULT(is_abs)
        !! Returns .TRUE. if path is absolute (Unix: /, Windows: \ or X:).
        CHARACTER(len=*), INTENT(IN) :: filepath
        LOGICAL :: is_abs
        INTEGER(i4) :: len_trimmed
        len_trimmed = LEN_TRIM(filepath)
        is_abs = .FALSE.
        IF (len_trimmed < 1) RETURN
        ! Unix: starts with /
        IF (filepath(1:1) == '/') THEN
            is_abs = .TRUE.
            RETURN
        END IF
        ! Windows: starts with \ or X:\
        IF (filepath(1:1) == '\') THEN
            is_abs = .TRUE.
            RETURN
        END IF
        IF (len_trimmed >= 3) THEN
            IF (filepath(2:2) == ':' .AND. filepath(3:3) == '\') THEN
                is_abs = .TRUE.
            END IF
        END IF
    END FUNCTION AP_File_IsAbsolutePath

    SUBROUTINE AP_File_ReadLines(filename, lines, num_lines, status)
        CHARACTER(len=*), INTENT(IN) :: filename
        CHARACTER(len=*), INTENT(OUT) :: lines(:)
        INTEGER(i4), INTENT(OUT) :: num_lines
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: unit, iostat_val, max_lines
        CHARACTER(len=LEN(lines(1))) :: line_buffer
        CALL init_error_status(status)
        max_lines = SIZE(lines)
        num_lines = 0
        OPEN(NEWUNIT=unit, FILE=filename, STATUS='OLD', ACTION='READ', IOSTAT=iostat_val)
        IF (iostat_val /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = 'AP_File_ReadLines: Failed to open file: ' // TRIM(filename)
            RETURN
        END IF
        DO
            READ(unit, '(A)', IOSTAT=iostat_val) line_buffer
            IF (iostat_val /= 0) EXIT
            IF (num_lines < max_lines) THEN
                num_lines = num_lines + 1
                lines(num_lines) = line_buffer
            ELSE
                status%status_code = IF_STATUS_INVALID
                status%message = 'AP_File_ReadLines: Too many lines'
                CLOSE(unit)
                RETURN
            END IF
        END DO
        CLOSE(unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE AP_File_ReadLines

    SUBROUTINE AP_File_WriteLines(filename, lines, num_lines, status)
        CHARACTER(len=*), INTENT(IN) :: filename
        CHARACTER(len=*), INTENT(IN) :: lines(:)
        INTEGER(i4), INTENT(IN) :: num_lines
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: unit, iostat_val, i
        CALL init_error_status(status)
        OPEN(NEWUNIT=unit, FILE=filename, STATUS='REPLACE', ACTION='WRITE', IOSTAT=iostat_val)
        IF (iostat_val /= 0) THEN
            status%status_code = IF_STATUS_IO_ERROR
            status%message = 'AP_File_WriteLines: Failed to open file: ' // TRIM(filename)
            RETURN
        END IF
        DO i = 1, num_lines
            WRITE(unit, '(A)', IOSTAT=iostat_val) TRIM(lines(i))
            IF (iostat_val /= 0) THEN
                status%status_code = IF_STATUS_IO_ERROR
                status%message = 'AP_File_WriteLines: Write error'
                CLOSE(unit)
                RETURN
            END IF
        END DO
        CLOSE(unit)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE AP_File_WriteLines

    SUBROUTINE AP_File_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_File_Unified_Cfg: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE AP_File_Unified_Cfg

    SUBROUTINE AP_File_Unified_Execute(operation, filename, lines, num_lines, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        CHARACTER(LEN=*), INTENT(IN) :: filename
        CHARACTER(LEN=*), INTENT(INOUT), OPTIONAL :: lines(:)
        INTEGER(i4), INTENT(INOUT), OPTIONAL :: num_lines
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'READ' .OR. TRIM(operation) == 'read') THEN
            IF (.NOT. PRESENT(lines) .OR. .NOT. PRESENT(num_lines)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'AP_File_Unified_Execute: READ requires lines and num_lines'
                RETURN
            END IF
            CALL AP_File_ReadLines(filename, lines, num_lines, status)
        ELSE IF (TRIM(operation) == 'WRITE' .OR. TRIM(operation) == 'write') THEN
            IF (.NOT. PRESENT(lines) .OR. .NOT. PRESENT(num_lines)) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'AP_File_Unified_Execute: WRITE requires lines and num_lines'
                RETURN
            END IF
            CALL AP_File_WriteLines(filename, lines, num_lines, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_File_Unified_Execute: unsupported operation ' // TRIM(operation)
        END IF
    END SUBROUTINE AP_File_Unified_Execute

END MODULE AP_Job_Util