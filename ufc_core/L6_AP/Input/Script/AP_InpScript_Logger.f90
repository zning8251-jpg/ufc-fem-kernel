!===============================================================================
! MODULE: AP_InpScript_Logger
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl â€?command system logger
! BRIEF:  Command system logger - log levels, message logging, level control.
!
! Process phases:
!   P3: Cmd_Log / Cmd_LogError / Cmd_SetLogLevel
!===============================================================================
MODULE AP_InpScript_Logger
  USE IF_Prec_Core,    ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  !===============================================================================
  ! Constants
  !===============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: LOG_NONE  = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOG_ERROR = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOG_WARN  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOG_INFO  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOG_DEBUG = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: LOG_TRACE = 5_i4

  !===============================================================================
  ! Structured I/O Types
  !===============================================================================
  TYPE, PUBLIC :: Cmd_Log_In
    INTEGER(i4) :: level
    CHARACTER(LEN=256) :: message
  END TYPE Cmd_Log_In

  TYPE, PUBLIC :: Cmd_Log_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_Log_Out

  TYPE, PUBLIC :: Cmd_LogError_In
    CHARACTER(LEN=256) :: message
  END TYPE Cmd_LogError_In

  TYPE, PUBLIC :: Cmd_LogError_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_LogError_Out

  TYPE, PUBLIC :: Cmd_SetLogLevel_In
    INTEGER(i4) :: level
  END TYPE Cmd_SetLogLevel_In

  TYPE, PUBLIC :: Cmd_SetLogLevel_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_SetLogLevel_Out

  !===============================================================================
  ! Logger Type
  !===============================================================================
  TYPE, PUBLIC :: CmdLogger
    INTEGER(i4) :: level = LOG_INFO
    INTEGER(i4) :: unit = 6  ! stdout
    LOGICAL :: to_file = .FALSE.
    CHARACTER(LEN=256) :: filename = ''
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Log
    PROCEDURE :: LogError
    PROCEDURE :: SetLevel
  END TYPE CmdLogger

  !===============================================================================
  ! Global Instance
  !===============================================================================
  TYPE(CmdLogger), SAVE, PUBLIC :: g_logger

  !===============================================================================
  ! Public Interface
  !===============================================================================
  PUBLIC :: Cmd_Log_Structured
  PUBLIC :: Cmd_LogError_Structured
  PUBLIC :: Cmd_SetLogLevel_Structured
  PUBLIC :: Cmd_Log
  PUBLIC :: Cmd_LogError
  PUBLIC :: Cmd_SetLogLevel

CONTAINS

  !-----------------------------------------------------------------------------
  ! Type-bound procedures
  !-----------------------------------------------------------------------------
  SUBROUTINE Log_Init(this, level, log_file, status)
    CLASS(CmdLogger), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: level
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: log_file
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(level)) this%level = level
    IF (PRESENT(log_file)) THEN
      this%filename = log_file
      this%to_file = .TRUE.
    END IF
    this%init = .TRUE.
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Log_Init

  SUBROUTINE Log_Log(this, level, message, status)
    CLASS(CmdLogger), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: level
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Log_Log

  SUBROUTINE Log_LogError(this, message, status)
    CLASS(CmdLogger), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Log_LogError

  SUBROUTINE Log_SetLevel(this, level, status)
    CLASS(CmdLogger), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: level
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    this%level = level
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Log_SetLevel

  !-----------------------------------------------------------------------------
  ! Structured interface
  !-----------------------------------------------------------------------------
  SUBROUTINE Cmd_Log_Structured(in, out)
    TYPE(Cmd_Log_In), INTENT(IN) :: in
    TYPE(Cmd_Log_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_logger%Log(in%level, in%message, out%status)
  END SUBROUTINE Cmd_Log_Structured

  SUBROUTINE Cmd_LogError_Structured(in, out)
    TYPE(Cmd_LogError_In), INTENT(IN) :: in
    TYPE(Cmd_LogError_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_logger%LogError(in%message, out%status)
  END SUBROUTINE Cmd_LogError_Structured

  SUBROUTINE Cmd_SetLogLevel_Structured(in, out)
    TYPE(Cmd_SetLogLevel_In), INTENT(IN) :: in
    TYPE(Cmd_SetLogLevel_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_logger%SetLevel(in%level, out%status)
  END SUBROUTINE Cmd_SetLogLevel_Structured

  !-----------------------------------------------------------------------------
  ! Legacy scalar interface (wrappers)
  !-----------------------------------------------------------------------------
  SUBROUTINE Cmd_Log(level, message, status)
    INTEGER(i4), INTENT(IN) :: level
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_Log_In) :: in
    TYPE(Cmd_Log_Out) :: out

    in%level = level
    in%message = message
    CALL Cmd_Log_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_Log

  SUBROUTINE Cmd_LogError(message, status)
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_LogError_In) :: in
    TYPE(Cmd_LogError_Out) :: out

    in%message = message
    CALL Cmd_LogError_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_LogError

  SUBROUTINE Cmd_SetLogLevel(level, status)
    INTEGER(i4), INTENT(IN) :: level
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_SetLogLevel_In) :: in
    TYPE(Cmd_SetLogLevel_Out) :: out

    in%level = level
    CALL Cmd_SetLogLevel_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_SetLogLevel

END MODULE AP_InpScript_Logger