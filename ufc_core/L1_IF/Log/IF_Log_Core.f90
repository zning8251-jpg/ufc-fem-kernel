!===============================================================================
! MODULE: IF_Log_Core
! LAYER:  L1_IF
! DOMAIN: Log
! ROLE:   _Core
! BRIEF:  Log domain container - aggregates global logger, buffer, statistics.
!===============================================================================
!
! Data chain:
!   Container path: g_ufc_global%if_layer%log
!   Services: LoggerType (buffer + stats + config)
!   Lifecycle: Process-level (Job-scoped)
!
! Contents:
!   Types:
!     IF_Log_Domain            [Ctx]  Domain container
!   Subroutines (A-Z):
!     IF_Log_Domain_Debug      [P3]   Log debug message
!     IF_Log_Domain_Error      [P3]   Log error message
!     IF_Log_Domain_Fatal      [P3]   Log fatal message
!     IF_Log_Domain_Finalize   [P0]   Flush buffer, reset state
!     IF_Log_Domain_Flush      [P3]   Flush log buffer
!     IF_Log_Domain_Info       [P3]   Log info message
!     IF_Log_Domain_Init       [P0]   Initialize logger
!     IF_Log_Domain_Trace      [P3]   Log trace message
!     IF_Log_Domain_Warning    [P3]   Log warning message
!
! Status: Phase A | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Log_Core
  USE IF_Prec_Core,      ONLY: wp, i4, i8
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Def,   ONLY: IF_LOG_LEVEL_INFO, IF_LOG_LEVEL_TRACE, IF_LOG_LEVEL_DEBUG, &
                           IF_LOG_LEVEL_WARNING, IF_LOG_LEVEL_ERROR, IF_LOG_LEVEL_FATAL
  USE IF_Log_Logger,   ONLY: IF_Logger, IF_LogConfig, IF_LOG_OUTPUT_STDOUT
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Log level constants
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_TRACE = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_DEBUG = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_INFO  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_WARN  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_ERROR = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_FATAL = 5_i4

  !--------------------------------------------------------------------
  ! TYPE: IF_Log_Domain  [Ctx]  (canonical: IF_Log_Domain_Ctx)
  ! Log domain container aggregating logger, level config, output mode.
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Log_Domain
    TYPE(IF_Logger)      :: logger
    INTEGER(i4)          :: minLevel      = IF_LOG_INFO
    LOGICAL              :: enConsole     = .TRUE.
    LOGICAL              :: enFileOutput  = .FALSE.
    CHARACTER(LEN=256)   :: logFilePath   = ""
    LOGICAL              :: initialized   = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Info
    PROCEDURE :: Warning
    PROCEDURE :: Error
    PROCEDURE :: Trace
    PROCEDURE :: Debug
    PROCEDURE :: Fatal
    PROCEDURE :: Flush
  END TYPE IF_Log_Domain

CONTAINS

  !====================================================================
  ! [P0] IF_Log_Domain_Finalize - Flush buffer, reset logger state
  !====================================================================
  SUBROUTINE Finalize(this)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: loc_status

    IF (.NOT. this%initialized) RETURN
    CALL this%logger%Finalize(loc_status)
    this%initialized = .FALSE.

  END SUBROUTINE Finalize

  !====================================================================
  ! [P0] IF_Log_Domain_Init - Initialize logger via IF_Logger
  !====================================================================
  SUBROUTINE Init(this, minLevel, enConsole, status)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    INTEGER(i4),          INTENT(IN)    :: minLevel
    LOGICAL,              INTENT(IN)    :: enConsole
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    TYPE(IF_LogConfig) :: cfg

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    this%minLevel  = minLevel
    this%enConsole = enConsole
    cfg%min_level = minLevel
    cfg%output_target = IF_LOG_OUTPUT_STDOUT
    cfg%log_file = "ufc.log"
    IF (LEN_TRIM(this%logFilePath) > 0) cfg%log_file = TRIM(this%logFilePath)
    CALL this%logger%Init(config=cfg, status=status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    this%initialized = .TRUE.

  END SUBROUTINE Init

  !====================================================================
  ! [P3] Log methods - delegate to IF_Logger
  !====================================================================
  SUBROUTINE Info(this, message, status)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: loc_status
    IF (.NOT. this%initialized) RETURN
    CALL this%logger%Info(message, status=loc_status)
    IF (PRESENT(status)) status = loc_status
  END SUBROUTINE Info

  SUBROUTINE Warning(this, message, status)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: loc_status
    IF (.NOT. this%initialized) RETURN
    CALL this%logger%Warning(message, status=loc_status)
    IF (PRESENT(status)) status = loc_status
  END SUBROUTINE Warning

  SUBROUTINE Error(this, message, status)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: loc_status
    IF (.NOT. this%initialized) RETURN
    CALL this%logger%Error(message, status=loc_status)
    IF (PRESENT(status)) status = loc_status
  END SUBROUTINE Error

  SUBROUTINE Trace(this, message, status)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: loc_status
    IF (.NOT. this%initialized) RETURN
    CALL this%logger%Trace(message, status=loc_status)
    IF (PRESENT(status)) status = loc_status
  END SUBROUTINE Trace

  SUBROUTINE Debug(this, message, status)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: loc_status
    IF (.NOT. this%initialized) RETURN
    CALL this%logger%Debug(message, status=loc_status)
    IF (PRESENT(status)) status = loc_status
  END SUBROUTINE Debug

  SUBROUTINE Fatal(this, message, status)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: loc_status
    IF (.NOT. this%initialized) RETURN
    CALL this%logger%Fatal(message, status=loc_status)
    IF (PRESENT(status)) status = loc_status
  END SUBROUTINE Fatal

  SUBROUTINE Flush(this, status)
    CLASS(IF_Log_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: loc_status
    IF (.NOT. this%initialized) RETURN
    CALL this%logger%Flush(loc_status)
    IF (PRESENT(status)) status = loc_status
  END SUBROUTINE Flush

END MODULE IF_Log_Core