!===============================================================================
! MODULE: IF_Err_Brg
! LAYER:  L1_IF
! DOMAIN: Error
! ROLE:   _Brg
! BRIEF:  Core error handling API - status init/set/clear/check + log compat.
!===============================================================================
!
! Theory:  status = ErrorStatusType, init_error_status(status) -> status,
!          error_set(code, msg) -> status, error_clear(status) -> status,
!          error_has_error(status) -> {TRUE, FALSE}.
!
! Contents (A-Z):
!   Subroutines:
!     error_clear          [P0] Clear error status
!     error_set            [P0] Set error status
!     init_error_status    [P0] Initialize error status
!     log_debug/info/warn/error/fatal  [P3] Log compatibility wrappers
!     set_console_output   [P0] Enable/disable console output
!     set_log_level        [P0] Set minimum log level
!     uf_set_error_status   [P0] UF compat: set error status in-place
!     uf_set_error_log      [P0] UF compat: log error with source
!     warn_deprecated      [P3] Log deprecation warning (G-05)
!   Functions:
!     error_has_error      [P2] Check if status has error
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE IF_Err_Brg
    USE IF_Err_Def, ONLY: IF_Err_Status_State, ErrorStatusType => IF_Err_Status_State, &
                            IF_ERROR_SEVERITY_INFO, IF_ERROR_SEVERITY_WARNING, IF_ERROR_SEVERITY_ERROR, &
                            IF_ERROR_SEVERITY_CRITICAL, IF_ERROR_SEVERITY_FATAL, &
                            IF_ERROR_CATEGORY_OK, IF_ERROR_CATEGORY_INVALID, IF_ERROR_CATEGORY_MEM, &
                            IF_ERROR_CATEGORY_IO, IF_ERROR_CATEGORY_MATH, IF_ERROR_CATEGORY_ALLOC, &
                            IF_ERROR_CATEGORY_BOUNDS, IF_ERROR_CATEGORY_USER, &
                            IF_ERROR_CODE_BASE, IF_ERROR_CODE_MEMORY_ALLOCATION, IF_ERROR_CODE_MEMORY_DEALLOCATION, &
                            IF_ERROR_CODE_FILE_NOT_FOUND, IF_ERROR_CODE_FILE_READ_ERROR, IF_ERROR_CODE_FILE_WRITE_ERROR, &
                            IF_ERROR_CODE_INVALID_PARAMETER, IF_ERROR_CODE_OUT_OF_BOUNDS, IF_ERROR_CODE_DIVISION_BY_ZERO, &
                            IF_ERROR_CODE_NAN_DETECTED, IF_ERROR_CODE_INF_DETECTED, &
                            IF_ERROR_CODE_MATH_BASE, IF_ERROR_CODE_MATH_SINGULAR_MATRIX, IF_ERROR_CODE_MATH_ILL_CONDITIONED, &
                            IF_ERROR_CODE_MATH_CONVERGENCE_FAILED, IF_ERROR_CODE_MATH_EIGENVALUE_FAILED, &
                            i4, i8, wp
    IMPLICIT NONE
    PRIVATE

    !=============================================================================
    ! PUBLIC INTERFACE
    !=============================================================================
    
    ! Types (from IF_Err_Def) — canonical + legacy alias
    PUBLIC :: IF_Err_Status_State
    ! XREF: 跨层引用待Phase1其他Task同步 — legacy re-export for L3-L6 compat
    PUBLIC :: ErrorStatusType
    
    ! Error severity constants
    PUBLIC :: IF_ERROR_SEVERITY_INFO, IF_ERROR_SEVERITY_WARNING, IF_ERROR_SEVERITY_ERROR, &
              IF_ERROR_SEVERITY_CRITICAL, IF_ERROR_SEVERITY_FATAL
    
    ! Base error category constants (0-9 only, layer-specific categories in respective layers)
    PUBLIC :: IF_ERROR_CATEGORY_OK, IF_ERROR_CATEGORY_INVALID, IF_ERROR_CATEGORY_MEM, &
              IF_ERROR_CATEGORY_IO, IF_ERROR_CATEGORY_MATH, IF_ERROR_CATEGORY_ALLOC, &
              IF_ERROR_CATEGORY_BOUNDS, IF_ERROR_CATEGORY_USER
    
    ! Base error code constants (1000-2999 only, layer-specific codes in respective layers)
    PUBLIC :: IF_ERROR_CODE_BASE, IF_ERROR_CODE_MEMORY_ALLOCATION, IF_ERROR_CODE_MEMORY_DEALLOCATION, &
              IF_ERROR_CODE_FILE_NOT_FOUND, IF_ERROR_CODE_FILE_READ_ERROR, IF_ERROR_CODE_FILE_WRITE_ERROR, &
              IF_ERROR_CODE_INVALID_PARAMETER, IF_ERROR_CODE_OUT_OF_BOUNDS, IF_ERROR_CODE_DIVISION_BY_ZERO, &
              IF_ERROR_CODE_NAN_DETECTED, IF_ERROR_CODE_INF_DETECTED, &
              IF_ERROR_CODE_MATH_BASE, IF_ERROR_CODE_MATH_SINGULAR_MATRIX, IF_ERROR_CODE_MATH_ILL_CONDITIONED, &
              IF_ERROR_CODE_MATH_CONVERGENCE_FAILED, IF_ERROR_CODE_MATH_EIGENVALUE_FAILED
    
    ! KEEP: Compatibility status constants — widely used across L4_PH/L5_RT/L6_AP
    ! Compatibility status constants (for L4_PH/L5_RT compatibility)
    PUBLIC :: IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_SUCCESS, IF_STATUS_ERROR, IF_STATUS_CONVERGED, &
              IF_STATUS_NOT_CONVERGED, IF_STATUS_NOT_FOUND
    ! L3_MD material layer — ErrorStatusType%status_code (distinct band vs IF_STATUS_*)
    PUBLIC :: MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_ERROR, MD_MAT_STATUS_WARN
    ! UF_ErrorBaseManager compatibility
    PUBLIC :: IF_STATUS_WARN, IF_STATUS_MEM_ERROR, IF_STATUS_IO_ERROR, IF_STATUS_EXISTS, IF_STATUS_FATAL, IF_STATUS_UNSUPPORTED
    
    ! Core error handling (implemented bodies below; canonical IF_Err_* names deferred)
    PUBLIC :: init_error_status, error_set, error_clear, error_has_error
    PUBLIC :: uf_set_error_status, uf_set_error_log
    PUBLIC :: warn_deprecated
    PUBLIC :: log_debug, log_info, log_warn, log_error, log_fatal
    PUBLIC :: IF_LEVEL_DEBUG, IF_LEVEL_INFO, IF_LEVEL_WARN, IF_LEVEL_ERROR, IF_LEVEL_FATAL
    PUBLIC :: IF_MAX_MESSAGE_LEN, IF_MAX_TIMESTAMP_LEN
    PUBLIC :: set_log_level, set_console_output

    !=============================================================================
    ! COMPATIBILITY CONSTANTS (from IF_ErrorHandling)
    !=============================================================================
    
    INTEGER(i4), PARAMETER :: IF_STATUS_OK        = IF_ERROR_CATEGORY_OK
    INTEGER(i4), PARAMETER :: IF_STATUS_INVALID   = IF_ERROR_CATEGORY_INVALID
    INTEGER(i4), PARAMETER :: IF_STATUS_SUCCESS   = IF_ERROR_CATEGORY_OK
    INTEGER(i4), PARAMETER :: IF_STATUS_ERROR     = 2_i4   ! Runtime error (distinct from IF_STATUS_INVALID=1)
    INTEGER(i4), PARAMETER :: IF_STATUS_CONVERGED = 3_i4   ! Compatibility constant
    INTEGER(i4), PARAMETER :: IF_STATUS_NOT_CONVERGED = 4_i4
    INTEGER(i4), PARAMETER :: IF_STATUS_NOT_FOUND = 5_i4   ! Compatibility (UF_ErrorBaseManager)
    
    ! UF_ErrorBaseManager compatibility
    INTEGER(i4), PARAMETER :: IF_STATUS_WARN        = 6_i4
    INTEGER(i4), PARAMETER :: IF_STATUS_MEM_ERROR   = 7_i4
    INTEGER(i4), PARAMETER :: IF_STATUS_IO_ERROR    = 8_i4
    INTEGER(i4), PARAMETER :: IF_STATUS_EXISTS      = 9_i4
    INTEGER(i4), PARAMETER :: IF_STATUS_FATAL       = 10_i4
    INTEGER(i4), PARAMETER :: IF_STATUS_UNSUPPORTED = 11_i4
    
    ! Material contract status codes (L3_MD; band 6100+ avoids IF_STATUS_* 0–11)
    INTEGER(i4), PARAMETER :: MD_MAT_STATUS_OK = 6100_i4
    INTEGER(i4), PARAMETER :: MD_MAT_STATUS_INVALID = 6101_i4
    INTEGER(i4), PARAMETER :: MD_MAT_STATUS_NOT_FOUND = 6102_i4
    INTEGER(i4), PARAMETER :: MD_MAT_STATUS_ERROR = 6103_i4
    INTEGER(i4), PARAMETER :: MD_MAT_STATUS_WARN = 6104_i4
    
    ! Log level constants (UF_ErrorBaseManager compatibility)
    INTEGER(i4), PARAMETER :: IF_LEVEL_DEBUG = 1_i4
    INTEGER(i4), PARAMETER :: IF_LEVEL_INFO  = 2_i4
    INTEGER(i4), PARAMETER :: IF_LEVEL_WARN  = 3_i4
    INTEGER(i4), PARAMETER :: IF_LEVEL_ERROR = 4_i4
    INTEGER(i4), PARAMETER :: IF_LEVEL_FATAL = 5_i4
    INTEGER(i4), PARAMETER :: IF_MAX_MESSAGE_LEN  = 1024
    INTEGER(i4), PARAMETER :: IF_MAX_TIMESTAMP_LEN = 24

    ! Log compatibility (from UF_ErrorBaseManager - simple stdout, no IF_Log dep)
    TYPE, PRIVATE :: LogConfigType
        INTEGER(i4) :: log_level = IF_LEVEL_INFO
        LOGICAL :: console_output = .TRUE.
    END TYPE LogConfigType
    TYPE(LogConfigType), PRIVATE, SAVE :: log_config


CONTAINS

    !=============================================================================
    ! CORE ERROR HANDLING FUNCTIONS
    !=============================================================================
    
    !> @brief Initialize error status
    !! @param[out] status Error status to initialize
    !! @param[in] status_code Optional status code
    !! @param[in] message Optional error message
    !! @param[in] source Optional error source
    !! @param[in] line_number Optional line number
    !! @param[in] thread_id Optional thread ID
    !! @param[in] scene_id Optional scene ID
    !! @param[in] enable_stack Optional enable stack flag
    SUBROUTINE init_error_status(status, status_code, message, source, line_number, thread_id, scene_id, enable_stack)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4), INTENT(IN), OPTIONAL :: status_code
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: message, source
        INTEGER(i4), INTENT(IN), OPTIONAL :: line_number, thread_id, scene_id
        LOGICAL, INTENT(IN), OPTIONAL :: enable_stack
        
        ! Initialize with default values
        status%status_code = IF_ERROR_CATEGORY_OK
        status%severity    = IF_ERROR_SEVERITY_INFO
        status%category    = IF_ERROR_CATEGORY_OK
        status%message     = ""
        status%source      = ""
        status%line_number  = 0
        status%has_error    = .FALSE.
        status%error_id     = 0_i8
        status%error_count  = 0
        status%thread_id    = 0
        status%scene_id     = 0
        status%enable_stack = .TRUE.
        
        ! Apply optional parameters
        IF (PRESENT(status_code)) THEN
            status%status_code = status_code
            status%category    = status_code
            IF (status_code /= IF_ERROR_CATEGORY_OK) THEN
                status%has_error   = .TRUE.
                status%error_count = 1
                status%severity    = IF_ERROR_SEVERITY_ERROR
            END IF
        END IF
        IF (PRESENT(message))     status%message     = message
        IF (PRESENT(source))      status%source      = source
        IF (PRESENT(line_number)) status%line_number = line_number
        IF (PRESENT(thread_id))   status%thread_id   = thread_id
        IF (PRESENT(scene_id))    status%scene_id    = scene_id
        IF (PRESENT(enable_stack)) status%enable_stack = enable_stack
    END SUBROUTINE init_error_status
    
    !> @brief Set error status
    !! @param[in] code Error code
    !! @param[in] message Error message
    !! @param[in] source Optional error source
    !! @param[out] status Optional error status
    SUBROUTINE error_set(code, message, source, status)
        INTEGER(i4), INTENT(IN) :: code
        CHARACTER(len=*), INTENT(IN) :: message
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: source
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        IF (PRESENT(status)) THEN
            IF (PRESENT(source)) THEN
                CALL init_error_status(status, status_code=code, message=message, source=source)
            ELSE
                CALL init_error_status(status, status_code=code, message=message)
            END IF
        END IF
    END SUBROUTINE error_set
    
    !> @brief Clear error status
    !! @param[inout] status Error status to clear
    SUBROUTINE error_clear(status)
        TYPE(ErrorStatusType), INTENT(INOUT) :: status
        CALL init_error_status(status)
    END SUBROUTINE error_clear
    
    !> @brief Check if error status has error
    !! @param[in] status Error status to check
    !! @return .TRUE. if has error, .FALSE. otherwise
    LOGICAL FUNCTION error_has_error(status) RESULT(has_error)
        TYPE(ErrorStatusType), INTENT(IN) :: status
        has_error = (status%status_code /= IF_ERROR_CATEGORY_OK) .OR. status%has_error
    END FUNCTION error_has_error

    !=============================================================================
    ! LOG COMPATIBILITY (from UF_ErrorBaseManager - simple stdout, no IF_Log dep)
    !=============================================================================
    SUBROUTINE err_api_write_log(level, module_name, message)
        INTEGER(i4), INTENT(IN) :: level
        CHARACTER(LEN=*), INTENT(IN) :: module_name, message
        CHARACTER(LEN=IF_MAX_TIMESTAMP_LEN) :: timestamp
        CHARACTER(LEN=8) :: level_str
        INTEGER(i4) :: values(8)
        IF (level < log_config%log_level) RETURN
        CALL DATE_AND_TIME(VALUES=values)
        WRITE(timestamp, '(I4,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2,":",I2.2,".",I3.3)') &
            values(1), values(2), values(3), values(5), values(6), values(7), values(8)
        SELECT CASE (level)
            CASE (IF_LEVEL_DEBUG); level_str = "DEBUG"
            CASE (IF_LEVEL_INFO);  level_str = "INFO"
            CASE (IF_LEVEL_WARN);  level_str = "WARN"
            CASE (IF_LEVEL_ERROR); level_str = "ERROR"
            CASE (IF_LEVEL_FATAL); level_str = "FATAL"
            CASE DEFAULT;       level_str = "UNKNOWN"
        END SELECT
        IF (log_config%console_output) THEN
            WRITE(*, '(A," [",A,"] [",A,"] ",A)') TRIM(timestamp), TRIM(level_str), TRIM(module_name), TRIM(message)
            FLUSH(6)
        END IF
    END SUBROUTINE err_api_write_log

    SUBROUTINE log_debug(module_name, message)
        CHARACTER(LEN=*), INTENT(IN) :: module_name, message
        CALL err_api_write_log(IF_LEVEL_DEBUG, module_name, message)
    END SUBROUTINE log_debug

    SUBROUTINE log_info(module_name, message)
        CHARACTER(LEN=*), INTENT(IN) :: module_name, message
        CALL err_api_write_log(IF_LEVEL_INFO, module_name, message)
    END SUBROUTINE log_info

    SUBROUTINE log_warn(module_name, message)
        CHARACTER(LEN=*), INTENT(IN) :: module_name, message
        CALL err_api_write_log(IF_LEVEL_WARN, module_name, message)
    END SUBROUTINE log_warn

    SUBROUTINE log_error(module_name, message)
        CHARACTER(LEN=*), INTENT(IN) :: module_name, message
        CALL err_api_write_log(IF_LEVEL_ERROR, module_name, message)
    END SUBROUTINE log_error

    SUBROUTINE log_fatal(module_name, message)
        CHARACTER(LEN=*), INTENT(IN) :: module_name, message
        CALL err_api_write_log(IF_LEVEL_FATAL, module_name, message)
        STOP
    END SUBROUTINE log_fatal

    SUBROUTINE set_log_level(level)
        INTEGER(i4), INTENT(IN) :: level
        SELECT CASE (level)
            CASE (IF_LEVEL_DEBUG, IF_LEVEL_INFO, IF_LEVEL_WARN, IF_LEVEL_ERROR, IF_LEVEL_FATAL)
                log_config%log_level = level
            CASE DEFAULT
                log_config%log_level = IF_LEVEL_INFO
        END SELECT
    END SUBROUTINE set_log_level

    SUBROUTINE set_console_output(enable)
        LOGICAL, INTENT(IN) :: enable
        log_config%console_output = enable
    END SUBROUTINE set_console_output

    !=============================================================================
    ! uf_set_error_status / uf_set_error_log - UF compatibility (direct procedures)
    !=============================================================================
    !> (status, code, message): set status in-place
    SUBROUTINE uf_set_error_status(status, code, message)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4), INTENT(IN) :: code
        CHARACTER(LEN=*), INTENT(IN) :: message
        CALL init_error_status(status, status_code=code, message=message)
    END SUBROUTINE uf_set_error_status
    !> (code, message, source): log error (source = module/context name)
    SUBROUTINE uf_set_error_log(code, message, source)
        INTEGER(i4), INTENT(IN) :: code
        CHARACTER(LEN=*), INTENT(IN) :: message, source
        CHARACTER(LEN=IF_MAX_MESSAGE_LEN) :: msg
        WRITE(msg, '(A,A,A,A)') '[', TRIM(source), '] ', TRIM(message)
        CALL log_error(TRIM(source), TRIM(msg))
    END SUBROUTINE uf_set_error_log

    !=============================================================================
    ! warn_deprecated - Log deprecation warning (G-05, D4)
    !=============================================================================
    SUBROUTINE warn_deprecated(old_name, new_name, module_name)
        CHARACTER(LEN=*), INTENT(IN) :: old_name, new_name, module_name
        CHARACTER(LEN=512) :: msg
        WRITE(msg, '(A,A,A,A,A)') 'DEPRECATED: ', TRIM(old_name), ' -> use ', TRIM(new_name), ' instead'
        CALL log_warn(TRIM(module_name), TRIM(msg))
    END SUBROUTINE warn_deprecated

END MODULE IF_Err_Brg
