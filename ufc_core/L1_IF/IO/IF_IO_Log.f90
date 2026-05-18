!===============================================================================
! MODULE: IF_IO_Log
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Brg — simplified single-argument log API
! BRIEF:  IF_Log_Core_Init / Debug / Info / Warning / Error / Fatal wrappers.
!         Delegates to IF_Log; use when caller does not need status return.
!===============================================================================

MODULE IF_IO_Log
  USE IF_Log_Logger, ONLY: IF_LogConfig, IF_Logger, g_if_logger, &
                          IF_LOG_OUTPUT_BOTH, IF_Log_Flush
  USE IF_Prec_Core, ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Err_Def, ONLY: IF_LOG_LEVEL_DEBUG, IF_LOG_LEVEL_INFO, IF_LOG_LEVEL_WARNING, &
                          IF_LOG_LEVEL_ERROR, IF_LOG_LEVEL_FATAL
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: IF_Log_Core_Init
  PUBLIC :: IF_Log_Core_Shutdown
  PUBLIC :: IF_Log_Core_SetLevel
  PUBLIC :: IF_Log_Core_Debug
  PUBLIC :: IF_Log_Core_Info
  PUBLIC :: IF_Log_Core_Warning
  PUBLIC :: IF_Log_Core_Error
  PUBLIC :: IF_Log_Core_Fatal
  PUBLIC :: IF_LOG_LEVEL_DEBUG, IF_LOG_LEVEL_INFO, IF_LOG_LEVEL_WARNING, IF_LOG_LEVEL_ERROR, IF_LOG_LEVEL_FATAL

CONTAINS

  SUBROUTINE IF_Log_Core_Init(log_file_path, log_level, success)
    CHARACTER(LEN=*), INTENT(IN) :: log_file_path
    INTEGER(i4), INTENT(IN) :: log_level
    LOGICAL, INTENT(OUT) :: success
    TYPE(IF_LogConfig) :: config
    TYPE(ErrorStatusType) :: status

    CALL init_error_status(status)
    ! Map legacy level 0-4 (DEBUG..FATAL) to IF_Err_Def 1-5
    config%min_level = MAX(IF_LOG_LEVEL_DEBUG, MIN(IF_LOG_LEVEL_FATAL, log_level + 1))
    config%output_target = IF_LOG_OUTPUT_BOTH
    config%log_file = TRIM(log_file_path)
    config%append_mode = .FALSE.
    config%include_timestamp = .TRUE.
    config%include_module = .TRUE.
    config%buffer_size = 1000
    config%auto_flush = .TRUE.

    CALL g_if_logger%Init(config, status)
    success = (status%status_code == IF_STATUS_OK)
  END SUBROUTINE IF_Log_Core_Init

  SUBROUTINE IF_Log_Core_Shutdown()
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    CALL g_if_logger%Finalize(status)
  END SUBROUTINE IF_Log_Core_Shutdown

  SUBROUTINE IF_Log_Core_SetLevel(log_level)
    INTEGER(i4), INTENT(IN) :: log_level
    INTEGER(i4) :: level
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    level = MAX(IF_LOG_LEVEL_DEBUG, MIN(IF_LOG_LEVEL_FATAL, log_level + 1))
    CALL g_if_logger%SetLevel(level, status)
  END SUBROUTINE IF_Log_Core_SetLevel

  SUBROUTINE IF_Log_Core_Debug(message)
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    CALL g_if_logger%Debug(message, status=status)
  END SUBROUTINE IF_Log_Core_Debug

  SUBROUTINE IF_Log_Core_Info(message)
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    CALL g_if_logger%Info(message, status=status)
  END SUBROUTINE IF_Log_Core_Info

  SUBROUTINE IF_Log_Core_Warning(message)
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    CALL g_if_logger%Warning(message, status=status)
  END SUBROUTINE IF_Log_Core_Warning

  SUBROUTINE IF_Log_Core_Error(message)
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    CALL g_if_logger%Error(message, status=status)
  END SUBROUTINE IF_Log_Core_Error

  SUBROUTINE IF_Log_Core_Fatal(message)
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    CALL g_if_logger%Fatal(message, status=status)
  END SUBROUTINE IF_Log_Core_Fatal

END MODULE IF_IO_Log