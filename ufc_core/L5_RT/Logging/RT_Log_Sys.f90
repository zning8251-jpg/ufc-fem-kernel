!===============================================================================
! MODULE: RT_Log_Sys
! LAYER:  L5_RT
! DOMAIN: Logging
! ROLE:   Sys — runtime logging API wrapper over IF_Log
! BRIEF:  RT_Log_Init/Debug/Info/Warn/Error/Fatal + unified log management.
!===============================================================================
!     - RT_Log_Init: Initialize runtime logger
!     - RT_Log_Debug: Log debug message
!     - RT_Log_Info: Log info message
!     - RT_Log_Warn: Log warning message
!     - RT_Log_Error: Log error message
!     - RT_Log_Fatal: Log fatal message
!     - RT_Log_Finalize: Finalize runtime logger
!     - RT_Log_Unified_Manage: Unified log message management
!     - RT_Log_Unified_Cfg: Unified logger configuration
!   Constants:
!     - LOG_LEVEL_DEBUG, LOG_LEVEL_INFO, LOG_LEVEL_WARNING, LOG_LEVEL_ERROR, LOG_LEVEL_FATAL
!     - LOG_LEVEL_OFF: Log level off constant
!     - LOG_OUTPUT_STDOUT, LOG_OUTPUT_FILE, LOG_OUTPUT_BUFFER, LOG_OUTPUT_BOTH
!===============================================================================
MODULE RT_Log_Sys
    USE IF_Log_Logger, ONLY: g_if_logger, IF_LogConfig, IF_Log_Init, &
                           IF_Log_Debug, IF_Log_Info, IF_Log_Warning, &
                           IF_Log_Error, IF_Log_Fatal
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
    USE IF_Err_Def, ONLY: LOG_LEVEL_DEBUG, LOG_LEVEL_INFO, LOG_LEVEL_WARNING, &
                           LOG_LEVEL_ERROR, LOG_LEVEL_FATAL
    USE IF_Prec_Core, ONLY: i4
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACE
    ! ==========================================================================
    PUBLIC :: RT_LogConfig, RT_Logger
    PUBLIC :: RT_Log_Init, RT_Log_Debug, RT_Log_Info, RT_Log_Warn, RT_Log_Error
    PUBLIC :: RT_Log_Fatal, RT_Log_Finalize, RT_Log_Unified_Manage, RT_Log_Unified_Cfg
    PUBLIC :: LOG_LEVEL_DEBUG, LOG_LEVEL_INFO, LOG_LEVEL_WARNING, LOG_LEVEL_ERROR, LOG_LEVEL_FATAL
    ! REMOVED: LOG_LEVEL_WARN alias — use LOG_LEVEL_WARNING
    PUBLIC :: LOG_LEVEL_OFF
    PUBLIC :: LOG_OUTPUT_STDOUT, LOG_OUTPUT_FILE, LOG_OUTPUT_BUFFER, LOG_OUTPUT_BOTH

    ! ==========================================================================
    ! LOG LEVEL CONSTANTS
    ! ==========================================================================
    ! REMOVED: LOG_LEVEL_WARN alias — use LOG_LEVEL_WARNING
    INTEGER(i4), PARAMETER, PUBLIC :: LOG_LEVEL_OFF  = 99_i4             ! Log level off

    ! ==========================================================================
    ! LOG OUTPUT TARGET CONSTANTS
    ! RT API: 1=STDOUT, 2=FILE, 3=BUFFER, 4=BOTH (mapped in map_output_target)
    ! ==========================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: LOG_OUTPUT_STDOUT = 1_i4  ! Console output
    INTEGER(i4), PARAMETER, PUBLIC :: LOG_OUTPUT_FILE   = 2_i4  ! File output
    INTEGER(i4), PARAMETER, PUBLIC :: LOG_OUTPUT_BUFFER = 3_i4  ! Buffer output
    INTEGER(i4), PARAMETER, PUBLIC :: LOG_OUTPUT_BOTH   = 4_i4  ! Both stdout and file

    ! ==========================================================================
    ! RUNTIME LOG CONFIGURATION TYPE
    ! Category: Desc (Descriptor - read-only configuration)
    ! Purpose: Runtime logger configuration descriptor containing log level, output target,
    !          and formatting options specific to runtime layer.
    ! Members:
    !   log_level: Minimum log level level_min ?{DEBUG, INFO, WARNING, ERROR, FATAL}
    !   output_target: Output target (LOG_OUTPUT_STDOUT, LOG_OUTPUT_FILE, LOG_OUTPUT_BUFFER, LOG_OUTPUT_BOTH)
    !   log_file: Log file path path ?{string}
    !   append_mode: Append to existing file flag
    !   include_timestamp: Include timestamp flag
    !   include_level: Include log level flag
    !   include_module: Include module name flag
    !   colorize_output: Colorize console output flag
    ! ==========================================================================
    TYPE, PUBLIC :: RT_LogConfig
        INTEGER(i4) :: log_level = LOG_LEVEL_INFO
        INTEGER(i4) :: output_target = LOG_OUTPUT_STDOUT
        CHARACTER(LEN=256) :: log_file = "ufc_run.log"
        LOGICAL :: append_mode = .FALSE.
        LOGICAL :: include_timestamp = .TRUE.
        LOGICAL :: include_level = .TRUE.
        LOGICAL :: include_module = .TRUE.
        LOGICAL :: colorize_output = .FALSE.
    END TYPE RT_LogConfig

    ! ==========================================================================
    ! RUNTIME LOGGER TYPE
    ! Category: Ctx (Context - aggregates references/embedding of Desc/State/Algo)
    ! Purpose: Runtime logger context aggregating runtime-specific configuration.
    ! Members:
    !   config: Runtime logger configuration (Desc reference)
    ! ==========================================================================
    TYPE, PUBLIC :: RT_Logger
        TYPE(RT_LogConfig) :: config
    END TYPE RT_Logger

CONTAINS

    ! ==========================================================================
    ! INTERNAL HELPER FUNCTIONS
    ! ==========================================================================

    !> @brief Map RT output target to IF_Log output target
    !! @param[in] rt_out RT output target constant
    !! @return IF_Log output target constant
    PURE FUNCTION map_output_target(rt_out) RESULT(if_out)
        INTEGER(i4), INTENT(IN) :: rt_out
        INTEGER(i4) :: if_out

        ! Maps RT API (1=STDOUT,2=FILE,3=BUFFER,4=BOTH) to IF_Log (1=STDOUT,2=FILE,3=BOTH,4=BUFFER)
        SELECT CASE (rt_out)
            CASE (1)
                if_out = 1_i4  ! STDOUT
            CASE (2)
                if_out = 2_i4  ! FILE
            CASE (3)
                if_out = 4_i4  ! BUFFER
            CASE (4)
                if_out = 3_i4  ! BOTH
            CASE DEFAULT
                if_out = 1_i4
        END SELECT
    END FUNCTION map_output_target

    !> @brief Convert RT log configuration to IF_Log configuration
    !! @param[in] rt_cfg RT log configuration
    !! @param[out] if_cfg IF_Log configuration
    SUBROUTINE rt_config_to_if_config(rt_cfg, if_cfg)
        TYPE(RT_LogConfig), INTENT(IN) :: rt_cfg
        TYPE(IF_LogConfig), INTENT(OUT) :: if_cfg

        if_cfg%min_level = rt_cfg%log_level
        if_cfg%output_target = map_output_target(rt_cfg%output_target)
        if_cfg%log_file = rt_cfg%log_file
        if_cfg%append_mode = rt_cfg%append_mode
        if_cfg%include_timestamp = rt_cfg%include_timestamp
        if_cfg%include_module = rt_cfg%include_module
    END SUBROUTINE rt_config_to_if_config

    ! ==========================================================================
    ! PUBLIC INTERFACE PROCEDURES
    ! ==========================================================================

    !> @brief Initialize runtime logger
    !! @param[in] config Runtime log configuration (optional)
    !! @param[out] status Error status (optional)
    SUBROUTINE RT_Log_Init(config, status)
        TYPE(RT_LogConfig), INTENT(IN), OPTIONAL :: config
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        TYPE(ErrorStatusType) :: loc_status
        TYPE(IF_LogConfig) :: cfg

        IF (PRESENT(config)) THEN
            CALL rt_config_to_if_config(config, cfg)
            CALL IF_Log_Init(cfg, loc_status)
        ELSE
            CALL IF_Log_Init(status=loc_status)
        END IF

        IF (PRESENT(status)) status = loc_status
    END SUBROUTINE RT_Log_Init

    !> @brief Log debug message
    !! @param[in] message Log message
    !! @param[in] module_name Module name (optional)
    !! @param[in] function_name Function name (optional)
    SUBROUTINE RT_Log_Debug(message, module_name, function_name)
        CHARACTER(LEN=*), INTENT(IN) :: message
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name, function_name
        TYPE(ErrorStatusType) :: loc_status

        CALL g_if_logger%Debug(message, module_name, loc_status)
    END SUBROUTINE RT_Log_Debug

    !> @brief Log info message
    !! @param[in] message Log message
    !! @param[in] module_name Module name (optional)
    !! @param[in] function_name Function name (optional)
    SUBROUTINE RT_Log_Info(message, module_name, function_name)
        CHARACTER(LEN=*), INTENT(IN) :: message
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name, function_name
        TYPE(ErrorStatusType) :: loc_status

        CALL g_if_logger%Info(message, module_name, loc_status)
    END SUBROUTINE RT_Log_Info

    !> @brief Log warning message
    !! @param[in] message Log message
    !! @param[in] module_name Module name (optional)
    !! @param[in] function_name Function name (optional)
    SUBROUTINE RT_Log_Warn(message, module_name, function_name)
        CHARACTER(LEN=*), INTENT(IN) :: message
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name, function_name
        TYPE(ErrorStatusType) :: loc_status

        CALL g_if_logger%Warning(message, module_name, loc_status)
    END SUBROUTINE RT_Log_Warn

    !> @brief Log error message
    !! @param[in] message Log message
    !! @param[in] module_name Module name (optional)
    !! @param[in] function_name Function name (optional)
    SUBROUTINE RT_Log_Error(message, module_name, function_name)
        CHARACTER(LEN=*), INTENT(IN) :: message
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name, function_name
        TYPE(ErrorStatusType) :: loc_status

        CALL g_if_logger%Error(message, module_name, loc_status)
    END SUBROUTINE RT_Log_Error

    !> @brief Log fatal message
    !! @param[in] message Log message
    !! @param[in] module_name Module name (optional)
    !! @param[in] function_name Function name (optional)
    SUBROUTINE RT_Log_Fatal(message, module_name, function_name)
        CHARACTER(LEN=*), INTENT(IN) :: message
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name, function_name
        TYPE(ErrorStatusType) :: loc_status

        CALL g_if_logger%Fatal(message, module_name, loc_status)
    END SUBROUTINE RT_Log_Fatal

    !> @brief Finalize runtime logger
    SUBROUTINE RT_Log_Finalize()
        TYPE(ErrorStatusType) :: loc_status

        CALL g_if_logger%Finalize(loc_status)
    END SUBROUTINE RT_Log_Finalize

    !> @brief Unified log message management
    !! @param[inout] logger Runtime logger
    !! @param[in] level Log level
    !! @param[in] message Log message
    !! @param[in] module_name Module name (optional)
    !! @param[out] status Error status (optional)
    SUBROUTINE RT_Log_Unified_Manage(logger, level, message, module_name, status)
        TYPE(RT_Logger), INTENT(INOUT) :: logger
        INTEGER(i4), INTENT(IN) :: level
        CHARACTER(LEN=*), INTENT(IN) :: message
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        TYPE(ErrorStatusType) :: loc_status

        CALL init_error_status(loc_status)
        loc_status%status_code = IF_STATUS_OK

        SELECT CASE (level)
            CASE (LOG_LEVEL_DEBUG)
                IF (PRESENT(module_name)) THEN
                    CALL RT_Log_Debug(message, module_name)
                ELSE
                    CALL RT_Log_Debug(message)
                END IF
            CASE (LOG_LEVEL_INFO)
                IF (PRESENT(module_name)) THEN
                    CALL RT_Log_Info(message, module_name)
                ELSE
                    CALL RT_Log_Info(message)
                END IF
            CASE (LOG_LEVEL_WARNING)
                IF (PRESENT(module_name)) THEN
                    CALL RT_Log_Warn(message, module_name)
                ELSE
                    CALL RT_Log_Warn(message)
                END IF
            CASE (LOG_LEVEL_ERROR)
                IF (PRESENT(module_name)) THEN
                    CALL RT_Log_Error(message, module_name)
                ELSE
                    CALL RT_Log_Error(message)
                END IF
            CASE (LOG_LEVEL_FATAL)
                IF (PRESENT(module_name)) THEN
                    CALL RT_Log_Fatal(message, module_name)
                ELSE
                    CALL RT_Log_Fatal(message)
                END IF
            CASE DEFAULT
                loc_status%status_code = IF_STATUS_ERROR
                loc_status%message = 'RT_Log_Unified_Manage: Invalid log level'
        END SELECT

        IF (PRESENT(status)) status = loc_status
    END SUBROUTINE RT_Log_Unified_Manage

    !> @brief Unified logger configuration
    !! @param[in] log_level Log level
    !! @param[in] output_target Output target
    !! @param[in] log_file Log file path (optional)
    !! @param[out] logger Runtime logger
    !! @param[out] status Error status (optional)
    SUBROUTINE RT_Log_Unified_Cfg(log_level, output_target, log_file, logger, status)
        INTEGER(i4), INTENT(IN) :: log_level
        INTEGER(i4), INTENT(IN) :: output_target
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: log_file
        TYPE(RT_Logger), INTENT(OUT) :: logger
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

        TYPE(ErrorStatusType) :: loc_status

        CALL init_error_status(loc_status)

        logger%config%log_level = log_level
        logger%config%output_target = output_target
        IF (PRESENT(log_file)) logger%config%log_file = log_file

        CALL RT_Log_Init(config=logger%config, status=loc_status)
        IF (loc_status%status_code /= IF_STATUS_OK) THEN
            IF (PRESENT(status)) status = loc_status
            RETURN
        END IF

        loc_status%status_code = IF_STATUS_OK
        loc_status%message = 'RT_Log_Unified_Cfg: Logging configuration completed successfully'
        IF (PRESENT(status)) status = loc_status
    END SUBROUTINE RT_Log_Unified_Cfg

END MODULE RT_Log_Sys