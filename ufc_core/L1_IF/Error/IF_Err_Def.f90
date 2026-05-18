!===============================================================================
! MODULE: IF_Err_Def
! LAYER:  L1_IF
! DOMAIN: Error
! ROLE:   _Def
! BRIEF:  Error/logging type definitions and severity/category/code constants.
!===============================================================================
!
! Theory:  status = IF_Err_Status_State, code in Z, severity in {0..4},
!          category in {0..9}, log entry = (timestamp, level, category, message).
!
! TYPE Four-Type Mapping (Phase1A canonical names applied):
!   IF_Err_Status_State      [State]  (was: ErrorStatusType)
!   IF_Log_Entry_State       [State]  (was: LogEntry)
!   IF_Log_Buffer_State      [State]  (was: LogBuffer)
!   IF_Log_Stats_State       [State]  (was: LogStatistics)
!   IF_Log_Logger_Ctx        [Ctx]    (was: LoggerType)
!   IF_Err_Stack_State       [State]  (was: GlobalErrorStackType)
!   IF_Err_CallStack_Desc    [Desc]   (was: CallStackEntry)
!   IF_Err_Context_Ctx       [Ctx]    (was: ErrorContextType)
!   IF_Err_Recovery_Desc     [Desc]   (was: ErrorRecoveryHandler)
!   IF_Err_RecoveryReg_State [State]  (was: ErrorRecoveryRegistry)
!   IF_Err_Locale_Desc       [Desc]   (was: MessageLocale)
!   IF_Err_MsgTemplate_Desc  [Desc]   (was: ErrorMessageTemplate)
!   IF_Err_MsgCatalog_State  [State]  (was: MessageCatalog)
!
! Constants: IF_ERROR_SEVERITY_*, IF_ERROR_CATEGORY_*, IF_ERROR_CODE_*,
!            IF_LOG_LEVEL_*, IF_LOG_CATEGORY_*, IF_RECOVERY_ACTION_*
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE IF_Err_Def
  ! Use built-in types to avoid circular dependency with IF_Prec
  IMPLICIT NONE
  PRIVATE
  
  ! Type parameters (using built-in types, not IF_Prec)
  ! Export these for use by IF_Err_Brg and other modules
  INTEGER, PARAMETER, PUBLIC :: i4 = SELECTED_INT_KIND(9)   ! 32-bit integer
  INTEGER, PARAMETER, PUBLIC :: i8 = SELECTED_INT_KIND(18)  ! 64-bit integer
  INTEGER, PARAMETER, PUBLIC :: wp = SELECTED_REAL_KIND(15, 307)  ! Double precision

  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_SEVERITY_INFO     = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_SEVERITY_WARNING  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_SEVERITY_ERROR    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_SEVERITY_CRITICAL = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_SEVERITY_FATAL    = 4_i4

  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CATEGORY_OK       = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CATEGORY_INVALID  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CATEGORY_MEM      = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CATEGORY_IO       = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CATEGORY_MATH     = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CATEGORY_ALLOC    = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CATEGORY_BOUNDS   = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CATEGORY_USER    = 9_i4
  
  ! Note: Layer-specific error categories are defined in respective layer modules:
  !   L2_NM: IF_ERROR_CATEGORY_CONVERGE, IF_ERROR_CATEGORY_SOLVE
  !   L3_MD: IF_ERROR_CATEGORY_PARSE, IF_ERROR_CATEGORY_MATERIAL
  !   L4_PH: IF_ERROR_CATEGORY_ELEMENT, IF_ERROR_CATEGORY_CONTACT, IF_ERROR_CATEGORY_CONSTRAINT, IF_ERROR_CATEGORY_THERMAL
  !   L5_RT: IF_ERROR_CATEGORY_DYNAMIC
  !   L6_AP: IF_ERROR_CATEGORY_NETWORK, IF_ERROR_CATEGORY_MULTIPHYSICS
  
  ! Error code ranges (task200-249)
  ! Base error codes: 1000-1999 (General errors)
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_BASE = 1000_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_MEMORY_ALLOCATION = 1001_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_MEMORY_DEALLOCATION = 1002_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_FILE_NOT_FOUND = 1003_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_FILE_READ_ERROR = 1004_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_FILE_WRITE_ERROR = 1005_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_INVALID_PARAMETER = 1006_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_OUT_OF_BOUNDS = 1007_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_DIVISION_BY_ZERO = 1008_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_NAN_DETECTED = 1009_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_INF_DETECTED = 1010_i4
  
  ! Math errors: 2000-2999
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_MATH_BASE = 2000_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_MATH_SINGULAR_MATRIX = 2001_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_MATH_ILL_CONDITIONED = 2002_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_MATH_CONVERGENCE_FAILED = 2003_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_ERROR_CODE_MATH_EIGENVALUE_FAILED = 2004_i4
  
  ! Note: Layer-specific error codes are defined in respective layer modules:
  !   L2_NM: IF_ERROR_CODE_SOLVER_* (3000-3999)
  !   L3_MD: IF_ERROR_CODE_MATERIAL_* (4000-4999)
  !   L4_PH: IF_ERROR_CODE_ELEMENT_* (5000-5999)
  !   L5_RT: IF_ERROR_CODE_RT_* (6000-6999)
  !   L6_AP: IF_ERROR_CODE_AP_* (7000-7999)

  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_LEVEL_TRACE  = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_LEVEL_DEBUG = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_LEVEL_INFO  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_LEVEL_WARNING = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_LEVEL_ERROR  = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_LEVEL_FATAL = 5_i4

  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_GENERAL = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_MEMORY = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_IO     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_SOLVER = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_FIELD  = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_DOF   = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_MESH   = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_MPI   = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_GPU   = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_CATEGORY_PERF  = 9_i4

  ! Descriptor for IF_Err_Core_Init / IF_Error_Core_Finalize (reserved for future config).
  TYPE, PUBLIC :: IF_Error_Desc
    INTEGER(i4) :: version = 1_i4
  END TYPE IF_Error_Desc

  !=============================================================================
  ! TYPE: ErrorStatusType  [State]  (canonical: IF_Err_Status_State)
  ! Mutable error status containing code, severity, category, message, context.
  !=============================================================================
  TYPE, PUBLIC :: IF_Err_Status_State  ! XREF: 跨层引用待Phase1其他Task同步
  ! Legacy alias: ErrorStatusType
    INTEGER(i4) :: status_code = IF_ERROR_CATEGORY_OK        ! code ??
    INTEGER(i4) :: severity = IF_ERROR_SEVERITY_INFO         ! sev ?{0,1,2,3,4}
    INTEGER(i4) :: category = IF_ERROR_CATEGORY_OK           ! cat ?{0,1,...,19}
    CHARACTER(len=512) :: message = ""                    ! msg ?{string}
    CHARACTER(len=64)  :: source = ""                      ! src ?{string}
    INTEGER(i4) :: line_number = 0                         ! n_line ??^+
    LOGICAL :: has_error = .FALSE.
    INTEGER(i8) :: error_id = 0                           ! id_err ??^+
    INTEGER(i4) :: error_count = 0                        ! n_err ??^+
    INTEGER(i4) :: thread_id = 0                          ! id_thread ??^+
    INTEGER(i4) :: scene_id = 0                           ! id_scene ??^+
    LOGICAL :: enable_stack = .TRUE.
    INTEGER(i4) :: io_stat = 0                            ! STAT/IOSTAT from ALLOCATE/DEALLOCATE/OPEN
  END TYPE IF_Err_Status_State

  !=============================================================================
  ! TYPE: LogEntry  [State]  (canonical: IF_Log_Entry_State)
  ! Log entry state: timestamp, level, category, source, message.
  !=============================================================================
  TYPE, PUBLIC :: IF_Log_Entry_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: timestamp = 0_i8                      ! t_stamp ??^+
    INTEGER(i4) :: level = 0_i4                           ! level ?{0,1,2,3,4,5}
    INTEGER(i4) :: category = 0_i4                        ! cat ?{0,1,...,9}
    CHARACTER(len=256) :: source = ""                     ! src ?{string}
    CHARACTER(len=512) :: message = ""                     ! msg ?{string}
    INTEGER(i4) :: line_number = 0                         ! n_line ??^+
    INTEGER(i4) :: thread_id = 0                          ! id_thread ??^+
    INTEGER(i4) :: scene_id = 0                           ! id_scene ??^+
  END TYPE IF_Log_Entry_State

  !=============================================================================
  ! TYPE: LogBuffer  [State]  (canonical: IF_Log_Buffer_State)
  ! Buffered log entries for batch write.
  !=============================================================================
  TYPE, PUBLIC :: IF_Log_Buffer_State  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Log_Entry_State), ALLOCATABLE :: entries(:)             ! entry_i ?LogEntry^(n_entries)
    INTEGER(i4) :: max_entries = 1000                     ! n_max ??^+
    INTEGER(i4) :: n_entries = 0                          ! n_entries ??^+
    LOGICAL :: init = .FALSE.
  END TYPE IF_Log_Buffer_State

  !=============================================================================
  ! TYPE: LogStatistics  [State]  (canonical: IF_Log_Stats_State)
  ! Log statistics: counts for different log levels.
  !=============================================================================
  TYPE, PUBLIC :: IF_Log_Stats_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: total_entries = 0_i8                   ! n_total ??^+
    INTEGER(i8) :: trace_count = 0_i8                     ! n_trace ??^+
    INTEGER(i8) :: debug_count = 0_i8                      ! n_debug ??^+
    INTEGER(i8) :: info_count = 0_i8                       ! n_info ??^+
    INTEGER(i8) :: warning_count = 0_i8                    ! n_warn ??^+
    INTEGER(i8) :: error_count = 0_i8                      ! n_err ??^+
    INTEGER(i8) :: fatal_count = 0_i8                      ! n_fatal ??^+
    REAL(wp) :: last_interval = 0.0_wp                     ! ?t_last ??^+ (seconds)
  END TYPE IF_Log_Stats_State

  !=============================================================================
  ! TYPE: LoggerType  [Ctx]  (canonical: IF_Log_Logger_Ctx)
  ! Logger context aggregating buffer, statistics, and config.
  !=============================================================================
  TYPE, PUBLIC :: IF_Log_Logger_Ctx  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Log_Buffer_State) :: buffer                    ! State reference
    TYPE(IF_Log_Stats_State) :: stats                          ! State reference
    INTEGER(i4) :: min_level = IF_LOG_LEVEL_INFO             ! level_min ?{0,1,2,3,4,5}
    LOGICAL :: enable_console = .TRUE.
    LOGICAL :: init = .FALSE.
  END TYPE IF_Log_Logger_Ctx

  TYPE, PUBLIC, EXTENDS(IF_Log_Logger_Ctx) :: IF_Log_DebugLogger_Ctx  ! XREF: 跨层引用待Phase1其他Task同步
  END TYPE IF_Log_DebugLogger_Ctx

  TYPE, PUBLIC, EXTENDS(IF_Log_Logger_Ctx) :: IF_Log_PerfLogger_Ctx  ! XREF: 跨层引用待Phase1其他Task同步
  END TYPE IF_Log_PerfLogger_Ctx

  TYPE, PUBLIC :: IF_Log_DebugScope_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i4) :: id = 0_i4
  END TYPE IF_Log_DebugScope_Desc

  TYPE, PUBLIC :: IF_Log_DebugTrace_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i4) :: id = 0_i4
  END TYPE IF_Log_DebugTrace_Desc

  TYPE, PUBLIC :: IF_Mon_PerfTimer_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: start_ticks = 0_i8
  END TYPE IF_Mon_PerfTimer_State

  TYPE, PUBLIC :: IF_Mon_PerfCounter_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: count = 0_i8
  END TYPE IF_Mon_PerfCounter_State

  TYPE, PUBLIC :: IF_Mon_PerfStats_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: total_entries = 0_i8
  END TYPE IF_Mon_PerfStats_State

  !-----------------------------------------------------------------------------
  ! TYPE: GlobalErrorStackType  [State]  (canonical: IF_Err_Stack_State)
  !-----------------------------------------------------------------------------
  
  TYPE, PUBLIC :: IF_Err_Stack_State  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Err_Status_State), ALLOCATABLE :: errors(:)
    INTEGER(i4) :: stack_size = 0
    INTEGER(i4) :: max_size = 1024
    LOGICAL :: has_error = .FALSE.
    LOGICAL :: init = .FALSE.
  END TYPE IF_Err_Stack_State
  ! ==========================================================================
  ! ERROR CONTEXT TYPES
  ! ==========================================================================
  
  !-----------------------------------------------------------------------------
  ! TYPE: CallStackEntry  [Desc]  (canonical: IF_Err_CallStack_Desc)
  !-----------------------------------------------------------------------------
  ! Call stack entry
  TYPE, PUBLIC :: IF_Err_CallStack_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    CHARACTER(len=256) :: function_name = ""
    CHARACTER(len=256) :: file_name = ""
    INTEGER(i4) :: line_number = 0
    INTEGER(i4) :: thread_id = 0
  END TYPE IF_Err_CallStack_Desc
  
  !-----------------------------------------------------------------------------
  ! TYPE: ErrorContextType  [Ctx]  (canonical: IF_Err_Context_Ctx)
  !-----------------------------------------------------------------------------
  ! Error context with call stack and variable values
  TYPE, PUBLIC, EXTENDS(IF_Err_Status_State) :: IF_Err_Context_Ctx  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Err_CallStack_Desc), ALLOCATABLE :: call_stack(:)
    INTEGER(i4) :: stack_depth = 0
    INTEGER(i4) :: max_stack_depth = 32
    CHARACTER(len=512), ALLOCATABLE :: variable_values(:)
    INTEGER(i4) :: num_variables = 0
    CHARACTER(len=32) :: locale = "en_US"  ! Internationalization locale
  CONTAINS
    PROCEDURE :: Init => ErrCtx_Init
    PROCEDURE :: Finalize => ErrCtx_Finalize
  END TYPE IF_Err_Context_Ctx
  
  ! ==========================================================================
  ! ERROR RECOVERY TYPES
  ! ==========================================================================
  
  ! Recovery action constants: IF_RECOVERY_ACTION_*
  INTEGER(i4), PARAMETER, PUBLIC :: IF_RECOVERY_ACTION_NONE = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_RECOVERY_ACTION_RETRY = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_RECOVERY_ACTION_SKIP = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_RECOVERY_ACTION_FALLBACK = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_RECOVERY_ACTION_ABORT = 4_i4
  
  !-----------------------------------------------------------------------------
  ! TYPE: ErrorRecoveryHandler  [Desc]  (canonical: IF_Err_Recovery_Desc)
  !-----------------------------------------------------------------------------
  ! Error recovery handler
  TYPE, PUBLIC :: IF_Err_Recovery_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i4) :: error_code = 0
    INTEGER(i4) :: recovery_action = IF_RECOVERY_ACTION_NONE
    LOGICAL :: can_recover = .FALSE.
    CHARACTER(len=512) :: recovery_message = ""
    PROCEDURE(RecoveryFunction), POINTER, NOPASS :: recovery_function => NULL()
  END TYPE IF_Err_Recovery_Desc
  
  ABSTRACT INTERFACE
    LOGICAL FUNCTION RecoveryFunction(error_status) RESULT(success)
      IMPORT :: IF_Err_Status_State
      TYPE(IF_Err_Status_State), INTENT(IN) :: error_status
    END FUNCTION RecoveryFunction
  END INTERFACE
  
  !-----------------------------------------------------------------------------
  ! TYPE: ErrorRecoveryRegistry  [State]  (canonical: IF_Err_RecoveryReg_State)
  !-----------------------------------------------------------------------------
  ! Error recovery registry
  TYPE, PUBLIC :: IF_Err_RecoveryReg_State  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Err_Recovery_Desc), ALLOCATABLE :: handlers(:)
    INTEGER(i4) :: num_handlers = 0
    INTEGER(i4) :: max_handlers = 100
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => ErrReg_Init
    PROCEDURE :: Finalize => ErrReg_Finalize
  END TYPE IF_Err_RecoveryReg_State
  
  ! ==========================================================================
  ! ERROR MESSAGE INTERNATIONALIZATION TYPES
  ! ==========================================================================
  
  !-----------------------------------------------------------------------------
  ! TYPE: MessageLocale  [Desc]  (canonical: IF_Err_Locale_Desc)
  !-----------------------------------------------------------------------------
  ! Message locale
  TYPE, PUBLIC :: IF_Err_Locale_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    CHARACTER(len=32) :: locale_code = "en_US"
    CHARACTER(len=256) :: language = "English"
    CHARACTER(len=256) :: country = "United States"
  END TYPE IF_Err_Locale_Desc
  
  !-----------------------------------------------------------------------------
  ! TYPE: ErrorMessageTemplate  [Desc]  (canonical: IF_Err_MsgTemplate_Desc)
  !-----------------------------------------------------------------------------
  ! Error message template
  TYPE, PUBLIC :: IF_Err_MsgTemplate_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i4) :: error_code = 0
    CHARACTER(len=512) :: message_template = ""
    CHARACTER(len=32) :: locale = "en_US"
  END TYPE IF_Err_MsgTemplate_Desc
  
  !-----------------------------------------------------------------------------
  ! TYPE: MessageCatalog  [State]  (canonical: IF_Err_MsgCatalog_State)
  !-----------------------------------------------------------------------------
  ! Message catalog
  TYPE, PUBLIC :: IF_Err_MsgCatalog_State  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Err_MsgTemplate_Desc), ALLOCATABLE :: messages(:)
    INTEGER(i4) :: num_messages = 0
    INTEGER(i4) :: max_messages = 1000
    CHARACTER(len=32) :: default_locale = "en_US"
    LOGICAL :: init = .FALSE.
  END TYPE IF_Err_MsgCatalog_State

CONTAINS

  !--------------------------------------------------------------------
  ! [P0] ErrorContext_Init - allocate call_stack and variable_values
  !--------------------------------------------------------------------
  SUBROUTINE ErrCtx_Init(this)
    CLASS(IF_Err_Context_Ctx), INTENT(INOUT) :: this
    IF (ALLOCATED(this%call_stack)) DEALLOCATE(this%call_stack)
    IF (ALLOCATED(this%variable_values)) DEALLOCATE(this%variable_values)
    ALLOCATE(this%call_stack(this%max_stack_depth))
    ALLOCATE(this%variable_values(this%max_stack_depth))
    this%stack_depth = 0
    this%num_variables = 0
  END SUBROUTINE ErrCtx_Init

  !--------------------------------------------------------------------
  ! [P0] ErrorContext_Finalize - deallocate ALLOCATABLE fields
  !--------------------------------------------------------------------
  SUBROUTINE ErrCtx_Finalize(this)
    CLASS(IF_Err_Context_Ctx), INTENT(INOUT) :: this
    IF (ALLOCATED(this%call_stack)) DEALLOCATE(this%call_stack)
    IF (ALLOCATED(this%variable_values)) DEALLOCATE(this%variable_values)
    this%stack_depth = 0
    this%num_variables = 0
  END SUBROUTINE ErrCtx_Finalize

  !--------------------------------------------------------------------
  ! [P0] ErrorRecoveryRegistry_Init - allocate handlers array
  !--------------------------------------------------------------------
  SUBROUTINE ErrReg_Init(this)
    CLASS(IF_Err_RecoveryReg_State), INTENT(INOUT) :: this
    IF (this%is_initialized) CALL this%Finalize()
    IF (.NOT. ALLOCATED(this%handlers)) ALLOCATE(this%handlers(this%max_handlers))
    this%num_handlers = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE ErrReg_Init

  !--------------------------------------------------------------------
  ! [P0] ErrorRecoveryRegistry_Finalize - deallocate handlers
  !--------------------------------------------------------------------
  SUBROUTINE ErrReg_Finalize(this)
    CLASS(IF_Err_RecoveryReg_State), INTENT(INOUT) :: this
    IF (.NOT. this%is_initialized) RETURN
    IF (ALLOCATED(this%handlers)) DEALLOCATE(this%handlers)
    this%num_handlers = 0
    this%is_initialized = .FALSE.
  END SUBROUTINE ErrReg_Finalize

END MODULE IF_Err_Def