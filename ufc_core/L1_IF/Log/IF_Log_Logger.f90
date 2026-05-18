!===============================================================================
! MODULE: IF_Log_Logger
! LAYER:  L1_IF
! DOMAIN: Log
! ROLE:   _Logger (impl)
! BRIEF:  Logging system core - multi-level, multi-target, buffered logger.
!===============================================================================
!
! Theory:  Log entry = (timestamp, level, category, message),
!          level in {0..5}, buffer = [entry_i]_{i=1}^{n_entries}.
!
! TYPE Four-Type Mapping:
!   IF_LogConfig             [Desc]  -> canonical: IF_Log_Config_Desc
!   IF_Logger                [Ctx]   -> canonical: IF_Log_Logger_Ctx
!   IF_Logger_Init_In/Out    [Arg]   Structured I/O for Init
!   IF_Logger_Log_In/Out     [Arg]   Structured I/O for Log
!
! Contents (A-Z):
!   Global API:
!     IF_Log_Init            [P0] Initialize global logger
!     IF_Log_Trace/Debug/Info/Warning/Error/Fatal [P3] Log messages
!     IF_Log_Flush           [P3] Flush global logger buffer
!     IF_Log_GetStats        [P3] Get global logger statistics
!   Instance API:
!     IF_Logger_Init         [P0] Initialize logger instance
!     IF_Logger_Finalize     [P0] Finalize logger instance
!     IF_Logger_SetLevel     [P0] Set minimum log level
!     IF_Logger_Log          [P3] Log message with level
!     IF_Logger_Flush        [P3] Flush logger buffer
!     IF_Logger_GetStats     [P3] Get logger statistics
!
! Constants: IF_LOG_OUTPUT_STDOUT, IF_LOG_OUTPUT_FILE, IF_LOG_OUTPUT_BOTH,
!            IF_LOG_OUTPUT_BUFFER
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE IF_Log_Logger
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Err_Def, ONLY: IF_LOG_LEVEL_TRACE, IF_LOG_LEVEL_DEBUG, IF_LOG_LEVEL_INFO, &
                          IF_LOG_LEVEL_WARNING, IF_LOG_LEVEL_ERROR, IF_LOG_LEVEL_FATAL, &
                          IF_Log_Entry_State, IF_Log_Buffer_State, IF_Log_Stats_State
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Log Output Target Constants
  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_OUTPUT_STDOUT = 1_i4  ! Console output
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_OUTPUT_FILE   = 2_i4  ! File output
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_OUTPUT_BOTH   = 3_i4  ! Both stdout and file
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_OUTPUT_BUFFER = 4_i4  ! In-memory buffer only

  !=============================================================================
  ! TYPE: IF_LogConfig  [Desc]  (canonical: IF_Log_Config_Desc)
  ! Logger configuration descriptor: level, output target, formatting.
  !=============================================================================
  TYPE, PUBLIC :: IF_LogConfig
    INTEGER(i4) :: min_level = IF_LOG_LEVEL_INFO          ! level_min ?{0,1,2,3,4,5}
    INTEGER(i4) :: output_target = IF_LOG_OUTPUT_STDOUT
    CHARACTER(LEN=512) :: log_file = "ufc.log"         ! path ?{string}
    LOGICAL :: append_mode = .FALSE.
    LOGICAL :: include_timestamp = .TRUE.
    LOGICAL :: include_module = .TRUE.
    LOGICAL :: include_line = .FALSE.
    INTEGER(i4) :: buffer_size = 1000                  ! n_buf ??^+
    LOGICAL :: auto_flush = .TRUE.
  END TYPE IF_LogConfig

  !=============================================================================
  ! TYPE: IF_Logger  [Ctx]  (canonical: IF_Log_Logger_Ctx)
  ! Logger context aggregating config, buffer, statistics, file I/O state.
  !=============================================================================
  TYPE, PUBLIC :: IF_Logger
    TYPE(IF_LogConfig) :: config                         ! Desc reference
    TYPE(IF_Log_Buffer_State) :: buffer                  ! State reference
    TYPE(IF_Log_Stats_State) :: stats                    ! State reference
    INTEGER(i4) :: file_unit = -1                        ! n_unit ??
    LOGICAL :: is_open = .FALSE.
    LOGICAL :: is_init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => IF_Logger_Init
    PROCEDURE, PUBLIC :: Finalize => IF_Logger_Finalize
    PROCEDURE, PUBLIC :: SetLevel => IF_Logger_SetLevel
    PROCEDURE, PUBLIC :: Log => IF_Logger_Log
    PROCEDURE, PUBLIC :: Trace => IF_Logger_Trace
    PROCEDURE, PUBLIC :: Debug => IF_Logger_Debug
    PROCEDURE, PUBLIC :: Info => IF_Logger_Info
    PROCEDURE, PUBLIC :: Warning => IF_Logger_Warning
    PROCEDURE, PUBLIC :: Error => IF_Logger_Error
    PROCEDURE, PUBLIC :: Fatal => IF_Logger_Fatal
    PROCEDURE, PUBLIC :: Flush => IF_Logger_Flush
    PROCEDURE, PUBLIC :: GetStats => IF_Logger_GetStats
  END TYPE IF_Logger

  ! Global logger instance
  TYPE(IF_Logger), SAVE, PUBLIC :: g_if_logger

  ! Public API
  PUBLIC :: IF_Log_Init
  PUBLIC :: IF_Log_Trace
  PUBLIC :: IF_Log_Debug
  PUBLIC :: IF_Log_Info
  PUBLIC :: IF_Log_Warning
  PUBLIC :: IF_Log_Error
  PUBLIC :: IF_Log_Fatal
  PUBLIC :: IF_Log_Flush
  PUBLIC :: IF_Log_GetStats
  
  !=============================================================================
  ! TYPE: IF_Logger_Init_In  [Arg]
  ! Structured input for logger initialization.
  !=============================================================================
  !> @brief Input structure for logger initialization
  !   has_config=.TRUE. => use config; else use default
  TYPE, PUBLIC :: IF_Logger_Init_In
    LOGICAL :: has_config = .FALSE.           ! If true, use config
    TYPE(IF_LogConfig) :: config             ! Logger configuration (when has_config)
  END TYPE IF_Logger_Init_In
  
  !=============================================================================
  ! TYPE: IF_Logger_Init_Out  [Arg]
  ! Structured output for logger initialization.
  !=============================================================================
  !> @brief Output structure for logger initialization
  TYPE, PUBLIC :: IF_Logger_Init_Out
    TYPE(IF_Logger) :: logger                ! Initialized logger (Ctx)
    TYPE(ErrorStatusType) :: status          ! Error status
  END TYPE IF_Logger_Init_Out
  
  !=============================================================================
  ! TYPE: IF_Logger_Log_In  [Arg]
  ! Structured input for logger log operation.
  !=============================================================================
  !> @brief Input structure for logger log operation
  !   module_name="" and line_num<0 => not provided
  TYPE, PUBLIC :: IF_Logger_Log_In
    TYPE(IF_Logger) :: logger                ! Logger (Ctx)
    INTEGER(i4) :: level                     ! level in {0,1,2,3,4,5}
    CHARACTER(LEN=512) :: message            ! msg
    CHARACTER(LEN=64) :: module_name = ""   ! Module name (empty = not provided)
    INTEGER(i4) :: line_num = -1_i4          ! Line number (-1 = not provided)
  END TYPE IF_Logger_Log_In
  
  !=============================================================================
  ! TYPE: IF_Logger_Log_Out  [Arg]
  ! Structured output for logger log operation.
  !=============================================================================
  !> @brief Output structure for logger log operation
  TYPE, PUBLIC :: IF_Logger_Log_Out
    TYPE(IF_Logger) :: logger                ! Updated logger (Ctx)
    TYPE(ErrorStatusType) :: status          ! Error status
  END TYPE IF_Logger_Log_Out

CONTAINS

  !=============================================================================
  ! [P0] STRUCTURED INTERFACE PROCEDURES
  !=============================================================================
  
  !> @brief Initialize logger (structured interface)
  SUBROUTINE IF_Logger_Init_Structured(in, out)
    TYPE(IF_Logger_Init_In), INTENT(IN) :: in
    TYPE(IF_Logger_Init_Out), INTENT(OUT) :: out
    
    IF (in%has_config) THEN
      CALL out%logger%Init(in%config, out%status)
    ELSE
      CALL out%logger%Init(status=out%status)
    END IF
  END SUBROUTINE IF_Logger_Init_Structured
  
  !> @brief Log message (structured interface)
  SUBROUTINE IF_Logger_Log_Structured(in, out)
    TYPE(IF_Logger_Log_In), INTENT(IN) :: in
    TYPE(IF_Logger_Log_Out), INTENT(OUT) :: out
    
    out%logger = in%logger
    IF (LEN_TRIM(in%module_name) > 0 .AND. in%line_num >= 0) THEN
      CALL out%logger%Log(in%level, in%message, module_name=in%module_name, line_num=in%line_num, status=out%status)
    ELSE IF (LEN_TRIM(in%module_name) > 0) THEN
      CALL out%logger%Log(in%level, in%message, module_name=in%module_name, status=out%status)
    ELSE IF (in%line_num >= 0) THEN
      CALL out%logger%Log(in%level, in%message, line_num=in%line_num, status=out%status)
    ELSE
      CALL out%logger%Log(in%level, in%message, status=out%status)
    END IF
  END SUBROUTINE IF_Logger_Log_Structured
  
  !=============================================================================
  ! [P0] LEGACY INTERFACE PROCEDURES (backward compatibility)
  !=============================================================================
  
  !=============================================================================
  ! Logger Initialization
  !=============================================================================

  !> [P0] Initialize logger (legacy interface)
  SUBROUTINE IF_Logger_Init(this, config, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    TYPE(IF_LogConfig), INTENT(IN), OPTIONAL :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: iostat
    CHARACTER(LEN=20) :: open_status
    
    CALL init_error_status(status)
    
    ! Set configuration
    IF (PRESENT(config)) THEN
      this%config = config
    ELSE
      ! Use default configuration
      this%config%min_level = IF_LOG_LEVEL_INFO
      this%config%output_target = IF_LOG_OUTPUT_STDOUT
      this%config%log_file = "ufc.log"
      this%config%append_mode = .FALSE.
      this%config%buffer_size = 1000
    END IF
    
    ! Initialize buffer
    IF (.NOT. ALLOCATED(this%buffer%entries)) THEN
      ALLOCATE(this%buffer%entries(this%config%buffer_size))
      this%buffer%max_entries = this%config%buffer_size
      this%buffer%n_entries = 0
      this%buffer%init = .TRUE.
    END IF
    
    ! Initialize statistics
    this%stats%total_entries = 0_i8
    this%stats%trace_count = 0_i8
    this%stats%debug_count = 0_i8
    this%stats%info_count = 0_i8
    this%stats%warning_count = 0_i8
    this%stats%error_count = 0_i8
    this%stats%fatal_count = 0_i8
    
    ! Open log file if needed
    IF (this%config%output_target == IF_LOG_OUTPUT_FILE .OR. &
        this%config%output_target == IF_LOG_OUTPUT_BOTH) THEN
      
      IF (this%config%append_mode) THEN
        open_status = 'OLD'
      ELSE
        open_status = 'REPLACE'
      END IF
      
      OPEN(NEWUNIT=this%file_unit, FILE=TRIM(this%config%log_file), &
           STATUS=TRIM(open_status), ACTION='WRITE', &
           POSITION='APPEND', IOSTAT=iostat)
      
      IF (iostat /= 0) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,A,A,I0)') &
          "Failed to open log file: ", TRIM(this%config%log_file), &
          ", IOSTAT=", iostat
        RETURN
      END IF
      
      this%is_open = .TRUE.
    END IF
    
    this%is_init = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Logger_Init

  SUBROUTINE IF_Logger_Finalize(this, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: iostat
    
    CALL init_error_status(status)
    
    IF (.NOT. this%is_init) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Flush remaining buffer
    CALL this%Flush(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! Close log file
    IF (this%is_open) THEN
      CLOSE(UNIT=this%file_unit, IOSTAT=iostat)
      
      IF (iostat /= 0) THEN
        status%status_code = IF_STATUS_ERROR
        WRITE(status%message, '(A,I0)') "Failed to close log file, IOSTAT=", iostat
        RETURN
      END IF
      
      this%is_open = .FALSE.
    END IF
    
    ! Deallocate buffer
    IF (ALLOCATED(this%buffer%entries)) THEN
      DEALLOCATE(this%buffer%entries)
      this%buffer%init = .FALSE.
    END IF
    
    this%is_init = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Logger_Finalize

  !=============================================================================
  ! [P3] Logging Methods
  !=============================================================================

  SUBROUTINE IF_Logger_SetLevel(this, min_level, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: min_level
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (min_level < IF_LOG_LEVEL_TRACE .OR. min_level > IF_LOG_LEVEL_FATAL) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid log level"
      RETURN
    END IF
    
    this%config%min_level = min_level
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Logger_SetLevel

  SUBROUTINE IF_Logger_Log(this, level, message, module_name, line_num, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: level
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    INTEGER(i4), INTENT(IN), OPTIONAL :: line_num
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(IF_Log_Entry_State) :: entry
    CHARACTER(LEN=1024) :: formatted_msg
    INTEGER(i4) :: iostat
    
    CALL init_error_status(status)
    
    ! Check if this level should be logged
    IF (level < this%config%min_level) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Create log entry
    ! Note: timestamp set to 0 (system time API not yet available in IF layer)
    entry%timestamp = 0_i8
    entry%level = level
    entry%message = TRIM(message)
    
    IF (PRESENT(module_name)) THEN
      entry%source = TRIM(module_name)
    ELSE
      entry%source = ""
    END IF
    
    IF (PRESENT(line_num)) THEN
      entry%line_number = line_num
    ELSE
      entry%line_number = 0
    END IF
    
    ! Format message
    CALL FormatLogEntry(this, entry, formatted_msg)
    
    ! Output to stdout
    IF (this%config%output_target == IF_LOG_OUTPUT_STDOUT .OR. &
        this%config%output_target == IF_LOG_OUTPUT_BOTH) THEN
      WRITE(*, '(A)') TRIM(formatted_msg)
    END IF
    
    ! Output to file
    IF (this%is_open .AND. &
        (this%config%output_target == IF_LOG_OUTPUT_FILE .OR. &
         this%config%output_target == IF_LOG_OUTPUT_BOTH)) THEN
      WRITE(this%file_unit, '(A)', IOSTAT=iostat) TRIM(formatted_msg)
      
      IF (iostat /= 0) THEN
        ! Non-fatal error, just print to stderr
        WRITE(*, '(A,I0)') "Warning: Failed to write to log file, IOSTAT=", iostat
      END IF
      
      IF (this%config%auto_flush) THEN
        FLUSH(this%file_unit)
      END IF
    END IF
    
    ! Add to buffer
    IF (this%config%output_target == IF_LOG_OUTPUT_BUFFER .OR. &
        this%buffer%n_entries < this%buffer%max_entries) THEN
      this%buffer%n_entries = this%buffer%n_entries + 1
      this%buffer%entries(this%buffer%n_entries) = entry
    END IF
    
    ! Update statistics
    this%stats%total_entries = this%stats%total_entries + 1_i8
    
    SELECT CASE (level)
      CASE (IF_LOG_LEVEL_TRACE)
        this%stats%trace_count = this%stats%trace_count + 1_i8
      CASE (IF_LOG_LEVEL_DEBUG)
        this%stats%debug_count = this%stats%debug_count + 1_i8
      CASE (IF_LOG_LEVEL_INFO)
        this%stats%info_count = this%stats%info_count + 1_i8
      CASE (IF_LOG_LEVEL_WARNING)
        this%stats%warning_count = this%stats%warning_count + 1_i8
      CASE (IF_LOG_LEVEL_ERROR)
        this%stats%error_count = this%stats%error_count + 1_i8
      CASE (IF_LOG_LEVEL_FATAL)
        this%stats%fatal_count = this%stats%fatal_count + 1_i8
    END SELECT
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Logger_Log

  ! Convenience wrappers for each log level
  SUBROUTINE IF_Logger_Trace(this, message, module_name, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL this%Log(IF_LOG_LEVEL_TRACE, message, module_name, status=status)
  END SUBROUTINE IF_Logger_Trace

  SUBROUTINE IF_Logger_Debug(this, message, module_name, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL this%Log(IF_LOG_LEVEL_DEBUG, message, module_name, status=status)
  END SUBROUTINE IF_Logger_Debug

  SUBROUTINE IF_Logger_Info(this, message, module_name, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL this%Log(IF_LOG_LEVEL_INFO, message, module_name, status=status)
  END SUBROUTINE IF_Logger_Info

  SUBROUTINE IF_Logger_Warning(this, message, module_name, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL this%Log(IF_LOG_LEVEL_WARNING, message, module_name, status=status)
  END SUBROUTINE IF_Logger_Warning

  SUBROUTINE IF_Logger_Error(this, message, module_name, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL this%Log(IF_LOG_LEVEL_ERROR, message, module_name, status=status)
  END SUBROUTINE IF_Logger_Error

  SUBROUTINE IF_Logger_Fatal(this, message, module_name, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL this%Log(IF_LOG_LEVEL_FATAL, message, module_name, status=status)
  END SUBROUTINE IF_Logger_Fatal

  !=============================================================================
  ! [P3] Utility Methods
  !=============================================================================

  SUBROUTINE IF_Logger_Flush(this, status)
    CLASS(IF_Logger), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (this%is_open) THEN
      FLUSH(this%file_unit)
    END IF
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Logger_Flush

  SUBROUTINE IF_Logger_GetStats(this, stats)
    CLASS(IF_Logger), INTENT(IN) :: this
    TYPE(IF_Log_Stats_State), INTENT(OUT) :: stats
    
    stats = this%stats
  END SUBROUTINE IF_Logger_GetStats

  !=============================================================================
  ! Internal Helper Functions
  !=============================================================================

  SUBROUTINE FormatLogEntry(logger, entry, formatted_msg)
    TYPE(IF_Logger), INTENT(IN) :: logger
    TYPE(IF_Log_Entry_State), INTENT(IN) :: entry
    CHARACTER(LEN=*), INTENT(OUT) :: formatted_msg
    
    CHARACTER(LEN=32) :: level_str, timestamp_str
    
    ! Level string
    SELECT CASE (entry%level)
      CASE (IF_LOG_LEVEL_TRACE)
        level_str = "[TRACE]"
      CASE (IF_LOG_LEVEL_DEBUG)
        level_str = "[DEBUG]"
      CASE (IF_LOG_LEVEL_INFO)
        level_str = "[INFO] "
      CASE (IF_LOG_LEVEL_WARNING)
        level_str = "[WARN] "
      CASE (IF_LOG_LEVEL_ERROR)
        level_str = "[ERROR]"
      CASE (IF_LOG_LEVEL_FATAL)
        level_str = "[FATAL]"
      CASE DEFAULT
        level_str = "[?????]"
    END SELECT
    
    ! Build formatted message
    formatted_msg = ""
    
    IF (logger%config%include_timestamp) THEN
      ! Format timestamp (placeholder until IF_Time module available)
      IF (entry%timestamp > 0_i8) THEN
        WRITE(timestamp_str, '(A,I0,A)') "[T=", entry%timestamp, "] "
      ELSE
        timestamp_str = "[T=0] "  ! Placeholder for system time
      END IF
      formatted_msg = TRIM(formatted_msg) // TRIM(timestamp_str)
    END IF
    
    formatted_msg = TRIM(formatted_msg) // TRIM(level_str) // " "
    
    IF (logger%config%include_module .AND. LEN_TRIM(entry%source) > 0) THEN
      formatted_msg = TRIM(formatted_msg) // "[" // TRIM(entry%source) // "] "
    END IF
    
    formatted_msg = TRIM(formatted_msg) // TRIM(entry%message)
  END SUBROUTINE FormatLogEntry

  !=============================================================================
  ! [P3] Global Logger API
  !=============================================================================

  !> [P0] Initialize global logger (legacy interface)
  SUBROUTINE IF_Log_Init(config, status)
    TYPE(IF_LogConfig), INTENT(IN), OPTIONAL :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL g_if_logger%Init(config, status)
  END SUBROUTINE IF_Log_Init

  !> @brief Log trace message (legacy interface)
  SUBROUTINE IF_Log_Trace(message, module_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL g_if_logger%Trace(message, module_name, status)
  END SUBROUTINE IF_Log_Trace

  SUBROUTINE IF_Log_Debug(message, module_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL g_if_logger%Debug(message, module_name, status)
  END SUBROUTINE IF_Log_Debug

  !> @brief Log info message (legacy interface)
  SUBROUTINE IF_Log_Info(message, module_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL g_if_logger%Info(message, module_name, status)
  END SUBROUTINE IF_Log_Info

  !> @brief Log warning message (legacy interface)
  SUBROUTINE IF_Log_Warning(message, module_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL g_if_logger%Warning(message, module_name, status)
  END SUBROUTINE IF_Log_Warning

  !> @brief Log error message (legacy interface)
  SUBROUTINE IF_Log_Error(message, module_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL g_if_logger%Error(message, module_name, status)
  END SUBROUTINE IF_Log_Error

  !> @brief Log fatal message (legacy interface)
  SUBROUTINE IF_Log_Fatal(message, module_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: message
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: module_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL g_if_logger%Fatal(message, module_name, status)
  END SUBROUTINE IF_Log_Fatal

  !> @brief Flush logger buffer (legacy interface)
  SUBROUTINE IF_Log_Flush(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL g_if_logger%Flush(status)
  END SUBROUTINE IF_Log_Flush

  !> @brief Get logger statistics (legacy interface)
  SUBROUTINE IF_Log_GetStats(stats)
    TYPE(IF_Log_Stats_State), INTENT(OUT) :: stats
    
    CALL g_if_logger%GetStats(stats)
  END SUBROUTINE IF_Log_GetStats

END MODULE IF_Log_Logger