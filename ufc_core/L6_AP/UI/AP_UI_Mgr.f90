!===============================================================================
! MODULE: AP_UI_Mgr
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Mgr — CLI and progress display manager
! BRIEF:  Command-line interface, progress display and command dispatch for UFC.
!===============================================================================
MODULE AP_UI_Mgr
!> [CORE] User Interface for UFC (CLI and Progress Display)
!> Theory: Command Pattern, Progress Bar Pattern, Console I/O Abstraction
  USE IF_Base_Def, ONLY: ZERO, ONE, TRUE, FALSE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4

  IMPLICIT NONE
  PRIVATE

  ! UI Mode constants
  INTEGER(i4), PARAMETER, PUBLIC :: UI_MODE_INTERACTIVE = 1
  INTEGER(i4), PARAMETER, PUBLIC :: UI_MODE_BATCH = 2
  INTEGER(i4), PARAMETER, PUBLIC :: UI_MODE_SILENT = 3

  ! Color codes (ANSI)
  CHARACTER(len=*), PARAMETER, PUBLIC :: &
    UI_COLOR_RESET = CHAR(27) // '[0m', &
    UI_COLOR_RED = CHAR(27) // '[91m', &
    UI_COLOR_GREEN = CHAR(27) // '[92m', &
    UI_COLOR_YELLOW = CHAR(27) // '[93m', &
    UI_COLOR_BLUE = CHAR(27) // '[94m', &
    UI_COLOR_MAGENTA = CHAR(27) // '[95m', &
    UI_COLOR_CYAN = CHAR(27) // '[96m', &
    UI_COLOR_WHITE = CHAR(27) // '[97m'

  ! Progress bar characters
  CHARACTER(len=*), PARAMETER, PUBLIC :: &
    UI_PROGRESS_FILLED = '#', &
    UI_PROGRESS_EMPTY = '-', &
    UI_PROGRESS_ARROW = '>'

  ! Public types
  PUBLIC :: AP_UI_Ctrl_Type
  PUBLIC :: AP_UI_Progress_Type
  PUBLIC :: AP_UI_Command_Type

  ! Public subroutines
  PUBLIC :: AP_UI_Init
  PUBLIC :: AP_UI_Cleanup
  PUBLIC :: AP_UI_Print
  PUBLIC :: AP_UI_PrintInfo
  PUBLIC :: AP_UI_PrintWarning
  PUBLIC :: AP_UI_PrintError
  PUBLIC :: AP_UI_PrintSuccess
  PUBLIC :: AP_UI_Progress_Init
  PUBLIC :: AP_UI_Progress_Update
  PUBLIC :: AP_UI_Progress_Finish
  PUBLIC :: AP_UI_ReadLine
  PUBLIC :: AP_UI_Confirm
  PUBLIC :: AP_UI_PrintTable
  PUBLIC :: AP_UI_PrintHeader

  ! Public functions
  PUBLIC :: AP_UI_IsInteractive
  PUBLIC :: AP_UI_GetTerminalWidth
  PUBLIC :: AP_UI_GetMode
  
  !=============================================================================
  ! STRUCTURED INTERFACE TYPES
  !=============================================================================
  PUBLIC :: AP_UI_Init_In
  PUBLIC :: AP_UI_Init_Out
  PUBLIC :: AP_UI_Progress_Init_In
  PUBLIC :: AP_UI_Progress_Init_Out
  PUBLIC :: AP_UI_Progress_Update_In
  PUBLIC :: AP_UI_Progress_Update_Out
  PUBLIC :: AP_UI_Print_In
  PUBLIC :: AP_UI_Print_Out
  
  !> @brief Input structure for UI initialization
  TYPE, PUBLIC :: AP_UI_Init_In
    INTEGER(i4), OPTIONAL :: mode                    ! UI mode (UI_MODE_INTERACTIVE, UI_MODE_BATCH, UI_MODE_SILENT)
    LOGICAL, OPTIONAL :: use_color                    ! Use ANSI colors flag
  END TYPE AP_UI_Init_In
  
  !> @brief Output structure for UI initialization
  TYPE, PUBLIC :: AP_UI_Init_Out
    TYPE(AP_UI_Ctrl_Type) :: ctrl                    ! UI control context (Ctx)
    TYPE(ErrorStatusType) :: status                  ! Error status
  END TYPE AP_UI_Init_Out
  
  !> @brief Input structure for progress bar initialization
  TYPE, PUBLIC :: AP_UI_Progress_Init_In
    INTEGER(i4) :: total                             ! n_total  ?ℤ^+
    CHARACTER(len=256), OPTIONAL :: description      ! Progress description
    INTEGER(i4), OPTIONAL :: bar_width               ! w_bar  ?ℤ^+
  END TYPE AP_UI_Progress_Init_In
  
  !> @brief Output structure for progress bar initialization
  TYPE, PUBLIC :: AP_UI_Progress_Init_Out
    TYPE(AP_UI_Progress_Type) :: progress            ! Progress bar state (State)
    TYPE(ErrorStatusType) :: status                  ! Error status
  END TYPE AP_UI_Progress_Init_Out
  
  !> @brief Input structure for progress bar update
  TYPE, PUBLIC :: AP_UI_Progress_Update_In
    TYPE(AP_UI_Progress_Type) :: progress            ! Progress bar state (State)
    INTEGER(i4) :: current                           ! n_current  ?ℤ^+
  END TYPE AP_UI_Progress_Update_In
  
  !> @brief Output structure for progress bar update
  TYPE, PUBLIC :: AP_UI_Progress_Update_Out
    TYPE(AP_UI_Progress_Type) :: progress            ! Updated progress bar state (State)
    TYPE(ErrorStatusType) :: status                  ! Error status
  END TYPE AP_UI_Progress_Update_Out
  
  !> @brief Input structure for print message
  TYPE, PUBLIC :: AP_UI_Print_In
    CHARACTER(len=512) :: message                    ! msg  ?{string}
    INTEGER(i4), OPTIONAL :: level                   ! level  ? ?
  END TYPE AP_UI_Print_In
  
  !> @brief Output structure for print message
  TYPE, PUBLIC :: AP_UI_Print_Out
    TYPE(ErrorStatusType) :: status                  ! Error status
  END TYPE AP_UI_Print_Out

  ! Global UI state
  INTEGER(i4), SAVE :: g_ui_mode = UI_MODE_INTERACTIVE
  LOGICAL, SAVE :: g_ui_use_color = .TRUE.
  INTEGER(i4), SAVE :: g_ui_terminal_width = 80

  !=============================================================================
  ! UI CONTROL TYPE
  ! Category: Ctx (Context - aggregates references/embedding of Desc/State/Algo)
  ! Purpose: UI control context aggregating configuration, statistics, and state.
  ! Members:
  !   mode: UI mode (UI_MODE_INTERACTIVE, UI_MODE_BATCH, UI_MODE_SILENT)
  !   use_color: Use ANSI colors flag
  !   use_unicode: Use Unicode characters flag
  !   verbose: Verbose output flag
  !   terminal_width: Terminal width w_term ?ℤ^+
  !   num_messages: Total messages printed n_msg ?ℤ^+
  !   num_warnings: Warnings printed n_warn ?ℤ^+
  !   num_errors: Errors printed n_err ?ℤ^+
  !   is_initialized: Initialization flag
  !=============================================================================
  TYPE, PUBLIC :: AP_UI_Ctrl_Type_Cfg
      INTEGER(i4) :: mode = UI_MODE_INTERACTIVE
      LOGICAL :: use_color = .TRUE.
      LOGICAL :: use_unicode = .TRUE.
      LOGICAL :: verbose = .FALSE.
      INTEGER(i4) :: terminal_width = 80            ! w_term  ?ℤ^+
  END TYPE AP_UI_Ctrl_Type_Cfg

  TYPE, PUBLIC :: AP_UI_Ctrl_Type_Stats
      INTEGER(i4) :: num_messages = 0              ! n_msg  ?ℤ^+
      INTEGER(i4) :: num_warnings = 0              ! n_warn  ?ℤ^+
      INTEGER(i4) :: num_errors = 0                ! n_err  ?ℤ^+
  END TYPE AP_UI_Ctrl_Type_Stats

  TYPE, PUBLIC :: AP_UI_Ctrl_Type_State
      LOGICAL :: is_initialized = .FALSE.
  END TYPE AP_UI_Ctrl_Type_State

  TYPE, PUBLIC :: AP_UI_Ctrl_Type
      TYPE(AP_UI_Ctrl_Type_Cfg)   :: cfg
      TYPE(AP_UI_Ctrl_Type_Stats) :: stats
      TYPE(AP_UI_Ctrl_Type_State) :: state
  CONTAINS
      PROCEDURE, PUBLIC :: Init => AP_UI_Ctrl_Init
      PROCEDURE, PUBLIC :: Cleanup => AP_UI_Ctrl_Cleanup
      PROCEDURE, PUBLIC :: SetMode => AP_UI_Ctrl_SetMode
      PROCEDURE, PUBLIC :: SetVerbose => AP_UI_Ctrl_SetVerbose
  END TYPE AP_UI_Ctrl_Type

  !=============================================================================
  ! PROGRESS BAR TYPE
  ! Category: State (State - read/write runtime data)
  ! Purpose: Progress bar state containing progress information and display options.
  ! Members:
  !   current: Current progress n_current ?ℤ^+
  !   total: Total progress n_total ?ℤ^+
  !   percent: Percentage p = n_current / n_total ?[0,1]
  !   elapsed_time: Elapsed time t_elapsed ?ℝ^+ (seconds)
  !   eta: Estimated time remaining t_eta ?ℝ^+ (seconds)
  !   description: Progress description
  !   prefix: Prefix text
  !   suffix: Suffix text
  !   bar_width: Bar width in characters w_bar ?ℤ^+
  !   start_time: Start time t_start ? ?
  !   last_update: Last update time t_last ? ?
  !   is_active: Progress is active flag
  !   is_complete: Progress is complete flag
  !=============================================================================
  TYPE, PUBLIC :: AP_UI_Progress_Type_Progress
      INTEGER(i4) :: current = 0                    ! n_current  ?ℤ^+
      INTEGER(i4) :: total = 100                    ! n_total  ?ℤ^+
      REAL(wp) :: percent = 0.0_wp                  ! p  ?[0,1]
      REAL(wp) :: elapsed_time = 0.0_wp             ! t_elapsed  ?ℝ^+ (seconds)
      REAL(wp) :: eta = 0.0_wp                      ! t_eta  ?ℝ^+ (seconds)
  END TYPE AP_UI_Progress_Type_Progress

  TYPE, PUBLIC :: AP_UI_Progress_Type_Display
      CHARACTER(len=256) :: description = ''
      CHARACTER(len=256) :: prefix = ''
      CHARACTER(len=256) :: suffix = ''
      INTEGER(i4) :: bar_width = 50                 ! w_bar  ?ℤ^+
  END TYPE AP_UI_Progress_Type_Display

  TYPE, PUBLIC :: AP_UI_Progress_Type_Timing
      REAL(wp) :: start_time = 0.0_wp               ! t_start  ? ?
      REAL(wp) :: last_update = 0.0_wp               ! t_last  ? ?
  END TYPE AP_UI_Progress_Type_Timing

  TYPE, PUBLIC :: AP_UI_Progress_Type_State
      LOGICAL :: is_active = .FALSE.
      LOGICAL :: is_complete = .FALSE.
  END TYPE AP_UI_Progress_Type_State

  TYPE, PUBLIC :: AP_UI_Progress_Type
      TYPE(AP_UI_Progress_Type_Progress) :: progress
      TYPE(AP_UI_Progress_Type_Display)  :: display
      TYPE(AP_UI_Progress_Type_Timing)   :: timing
      TYPE(AP_UI_Progress_Type_State)    :: state
  CONTAINS
      PROCEDURE, PUBLIC :: Init => AP_UI_Progress_Init
      PROCEDURE, PUBLIC :: Update => AP_UI_Progress_Update
      PROCEDURE, PUBLIC :: Finish => AP_UI_Progress_Finish
      PROCEDURE, PUBLIC :: SetDescription => AP_UI_Progress_SetDescription
  END TYPE AP_UI_Progress_Type

  !=============================================================================
  ! COMMAND TYPE (for CLI)
  ! Category: Desc (Descriptor - read-only configuration)
  ! Purpose: Command descriptor containing command information, arguments, and callback.
  ! Members:
  !   name: Command name identifier
  !   description: Command description
  !   usage: Usage string
  !   num_args: Number of arguments n_args ?ℤ^+
  !   arg_names: Argument names a_i ?{string}^(n_args)
  !   arg_values: Argument values v_i ?{string}^(n_args)
  !   callback: Command callback procedure pointer
  !   is_valid: Command is valid flag
  !=============================================================================
  TYPE, PUBLIC :: AP_UI_Command_Type_Info
      CHARACTER(len=64) :: name = ''
      CHARACTER(len=256) :: description = ''
      CHARACTER(len=256) :: usage = ''
  END TYPE AP_UI_Command_Type_Info

  TYPE, PUBLIC :: AP_UI_Command_Type_Args
      INTEGER(i4) :: num_args = 0                  ! n_args  ?ℤ^+
      CHARACTER(len=64), ALLOCATABLE :: arg_names(:)    ! a_i  ?{string}^(n_args)
      CHARACTER(len=256), ALLOCATABLE :: arg_values(:)  ! v_i  ?{string}^(n_args)
  END TYPE AP_UI_Command_Type_Args

  TYPE, PUBLIC :: AP_UI_Command_Type_Callback
      PROCEDURE(cmd_callback), NOPASS, POINTER :: callback => NULL()
  END TYPE AP_UI_Command_Type_Callback

  TYPE, PUBLIC :: AP_UI_Command_Type_State
      LOGICAL :: is_valid = .FALSE.
  END TYPE AP_UI_Command_Type_State

  TYPE, PUBLIC :: AP_UI_Command_Type
      TYPE(AP_UI_Command_Type_Info)     :: info
      TYPE(AP_UI_Command_Type_Args)     :: args
      TYPE(AP_UI_Command_Type_Callback) :: cb
      TYPE(AP_UI_Command_Type_State)    :: state
  CONTAINS
      PROCEDURE, PUBLIC :: Init => AP_UI_Command_Init
      PROCEDURE, PUBLIC :: Cleanup => AP_UI_Command_Cleanup
      PROCEDURE, PUBLIC :: AddArg => AP_UI_Command_AddArg
      PROCEDURE, PUBLIC :: Execute => AP_UI_Command_Execute
  END TYPE AP_UI_Command_Type

  ! Callback interface
  ABSTRACT INTERFACE
    SUBROUTINE cmd_callback(cmd, args, status)
      IMPORT :: i4, ErrorStatusType
      TYPE(AP_UI_Command_Type), INTENT(IN) :: cmd
      CHARACTER(len=*), INTENT(IN) :: args(:)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
    END SUBROUTINE cmd_callback
  END INTERFACE

CONTAINS
  
  !=============================================================================
  ! STRUCTURED INTERFACE PROCEDURES
  !=============================================================================
  
  !> @brief Initialize UI (structured interface)
  SUBROUTINE AP_UI_Init_Structured(in, out)
    TYPE(AP_UI_Init_In), INTENT(IN) :: in
    TYPE(AP_UI_Init_Out), INTENT(OUT) :: out
    
    CALL out%ctrl%Init(in%mode, in%use_color, out%status)
  END SUBROUTINE AP_UI_Init_Structured
  
  !> @brief Initialize progress bar (structured interface)
  SUBROUTINE AP_UI_Progress_Init_Structured(in, out)
    TYPE(AP_UI_Progress_Init_In), INTENT(IN) :: in
    TYPE(AP_UI_Progress_Init_Out), INTENT(OUT) :: out
    
    CALL out%progress%Init(in%total, in%cfg%description, in%bar_width, out%status)
  END SUBROUTINE AP_UI_Progress_Init_Structured
  
  !> @brief Update progress bar (structured interface)
  SUBROUTINE AP_UI_Progress_Update_Structured(in, out)
    TYPE(AP_UI_Progress_Update_In), INTENT(IN) :: in
    TYPE(AP_UI_Progress_Update_Out), INTENT(OUT) :: out
    
    out%progress = in%progress
    CALL out%progress%Update(in%current, out%status)
  END SUBROUTINE AP_UI_Progress_Update_Structured
  
  !> @brief Print message (structured interface)
  SUBROUTINE AP_UI_Print_Structured(in, out)
    TYPE(AP_UI_Print_In), INTENT(IN) :: in
    TYPE(AP_UI_Print_Out), INTENT(OUT) :: out
    
    CALL AP_UI_Print(in%message, in%level, out%status)
  END SUBROUTINE AP_UI_Print_Structured
  
  !=============================================================================
  ! LEGACY INTERFACE PROCEDURES (for backward compatibility)
  ! NOTE: These are legacy interfaces. Use structured interfaces (_In/_Out) instead.
  !=============================================================================
  
  !=============================================================================
  ! AP_UI_Ctrl_Type METHODS
  !=============================================================================
  
  !> @brief Initialize UI control (legacy interface)
  SUBROUTINE AP_UI_Ctrl_Init(this, mode, use_color, status)
    CLASS(AP_UI_Ctrl_Type), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: mode
    LOGICAL, INTENT(IN), OPTIONAL :: use_color
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    ! Set defaults
    this%cfg%mode = UI_MODE_INTERACTIVE
    this%cfg%use_color = .TRUE.
    this%cfg%use_unicode = .TRUE.
    this%cfg%verbose = .FALSE.
    this%cfg%terminal_width = 80
    this%stats%num_messages = 0
    this%stats%num_warnings = 0
    this%stats%num_errors = 0
    this%state%is_initialized = .FALSE.

    ! Override with optional arguments
    IF (PRESENT(mode)) this%cfg%mode = mode
    IF (PRESENT(use_color)) this%cfg%use_color = use_color

    ! Detect terminal width
    this%cfg%terminal_width = AP_UI_GetTerminalWidth()

    ! Set global state
    g_ui_mode = this%cfg%mode
    g_ui_use_color = this%cfg%use_color
    g_ui_terminal_width = this%cfg%terminal_width

    this%state%is_initialized = .TRUE.

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Ctrl_Init

  !> @brief Cleanup UI control (legacy interface)
  SUBROUTINE AP_UI_Ctrl_Cleanup(this)
    CLASS(AP_UI_Ctrl_Type), INTENT(INOUT) :: this

    this%state%is_initialized = .FALSE.
  END SUBROUTINE AP_UI_Ctrl_Cleanup

  !> @brief Set UI mode (legacy interface)
  SUBROUTINE AP_UI_Ctrl_SetMode(this, mode, status)
    CLASS(AP_UI_Ctrl_Type), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: mode
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    SELECT CASE (mode)
    CASE (UI_MODE_INTERACTIVE, UI_MODE_BATCH, UI_MODE_SILENT)
      this%cfg%mode = mode
      g_ui_mode = mode
    CASE DEFAULT
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'AP_UI_Ctrl_SetMode: Invalid mode'
      END IF
      RETURN
    END SELECT

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Ctrl_SetMode

  !> @brief Set verbose mode (legacy interface)
  SUBROUTINE AP_UI_Ctrl_SetVerbose(this, verbose, status)
    CLASS(AP_UI_Ctrl_Type), INTENT(INOUT) :: this
    LOGICAL, INTENT(IN) :: verbose
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    this%cfg%verbose = verbose

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Ctrl_SetVerbose

  !=============================================================================
  ! AP_UI_Progress_Type METHODS
  !=============================================================================
  
  !> @brief Initialize progress bar (legacy interface)
  SUBROUTINE AP_UI_Progress_Init(this, total, description, bar_width, status)
    CLASS(AP_UI_Progress_Type), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: total
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: description
    INTEGER(i4), INTENT(IN), OPTIONAL :: bar_width
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (total <= 0) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'AP_UI_Progress_Init: total must be positive'
      END IF
      RETURN
    END IF

    this%progress%current = 0
    this%progress%total = total
    this%progress%percent = 0.0_wp
    this%progress%elapsed_time = 0.0_wp
    this%progress%eta = 0.0_wp
    this%display%description = ''
    this%display%prefix = ''
    this%display%suffix = ''
    this%display%bar_width = 50
    this%timing%start_time = 0.0_wp
    this%timing%last_update = 0.0_wp
    this%state%is_active = .FALSE.
    this%state%is_complete = .FALSE.

    ! Set optional parameters
    IF (PRESENT(description)) this%display%description = description
    IF (PRESENT(bar_width)) this%display%bar_width = bar_width

    ! Get start time
    CALL CPU_TIME(this%timing%start_time)
    this%timing%last_update = this%timing%start_time

    this%state%is_active = .TRUE.

    ! Print initial message
    IF (g_ui_mode /= UI_MODE_SILENT) THEN
      WRITE(*, '(A)', ADVANCE='NO') TRIM(this%display%description) // ': '
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Progress_Init

  !> @brief Update progress bar (legacy interface)
  SUBROUTINE AP_UI_Progress_Update(this, current, status)
    CLASS(AP_UI_Progress_Type), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: current
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    REAL(wp) :: current_time, time_per_step
    INTEGER(i4) :: bar_filled, bar_empty, i
    CHARACTER(len=256) :: bar_str
    CHARACTER(len=16) :: percent_str

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%state%is_active) RETURN

    this%progress%current = current
    this%progress%percent = REAL(current, wp) / REAL(this%progress%total, wp) * 100.0_wp

    ! Get current time
    CALL CPU_TIME(current_time)
    this%progress%elapsed_time = current_time - this%timing%start_time

    ! Calculate ETA
    IF (current > 0) THEN
      time_per_step = this%progress%elapsed_time / REAL(current, wp)
      this%progress%eta = time_per_step * REAL(this%progress%total - current, wp)
    END IF

    ! Only update if enough time has passed (avoid flickering)
    IF (current_time - this%timing%last_update < 0.1_wp .AND. current < this%progress%total) THEN
      RETURN
    END IF
    this%timing%last_update = current_time

    ! Skip if in silent mode
    IF (g_ui_mode == UI_MODE_SILENT) RETURN

    ! Build progress bar
    bar_filled = INT(this%progress%percent / 100.0_wp * REAL(this%display%bar_width))
    bar_filled = MIN(bar_filled, this%display%bar_width)
    bar_empty = this%display%bar_width - bar_filled

    bar_str = '['
    DO i = 1, bar_filled
      bar_str = TRIM(bar_str) // UI_PROGRESS_FILLED
    END DO
    IF (bar_empty > 0 .AND. current < this%progress%total) THEN
      bar_str = TRIM(bar_str) // UI_PROGRESS_ARROW
      bar_empty = bar_empty - 1
    END IF
    DO i = 1, bar_empty
      bar_str = TRIM(bar_str) // UI_PROGRESS_EMPTY
    END DO
    bar_str = TRIM(bar_str) // ']'

    ! Format percentage
    WRITE(percent_str, '(F6.1)') this%progress%percent

    ! Print progress
    WRITE(*, '(A,A,A,F8.1,A,F8.1,A,F8.1,A)', ADVANCE='NO') &
      TRIM(bar_str), ' ', TRIM(percent_str), '%, ', &
      'ETA: ', this%progress%eta, 's, ', &
      'Elapsed: ', this%progress%elapsed_time, 's'

    ! Move cursor to beginning of line
    WRITE(*, '(A)', ADVANCE='NO') CHAR(13)

    ! Flush output
    FLUSH(UNIT=6)

    ! Check if complete
    IF (current >= this%progress%total) THEN
      this%state%is_complete = .TRUE.
      this%state%is_active = .FALSE.
      WRITE(*, '(A)')  ! New line
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Progress_Update

  SUBROUTINE AP_UI_Progress_Finish(this, message, status)
    CLASS(AP_UI_Progress_Type), INTENT(INOUT) :: this
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%state%is_active .AND. .NOT. this%state%is_complete) RETURN

    this%state%is_complete = .TRUE.
    this%state%is_active = .FALSE.

    ! Print completion message
    IF (PRESENT(message)) THEN
      WRITE(*, '(A)') TRIM(message)
    ELSE
      WRITE(*, '(A)') 'Done.'
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Progress_Finish

  SUBROUTINE AP_UI_Progress_SetDescription(this, description, status)
    CLASS(AP_UI_Progress_Type), INTENT(INOUT) :: this
    CHARACTER(len=*), INTENT(IN) :: description
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    this%display%description = description

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Progress_SetDescription

  !=============================================================================
  ! AP_UI_Command_Type METHODS
  !=============================================================================

  SUBROUTINE AP_UI_Command_Init(this, name, description, callback, status)
    CLASS(AP_UI_Command_Type), INTENT(INOUT) :: this
    CHARACTER(len=*), INTENT(IN) :: name
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: description
    PROCEDURE(cmd_callback), OPTIONAL, POINTER :: callback
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    this%info%name = name
    this%info%description = ''
    this%info%usage = ''
    this%args%num_args = 0
    this%cb%callback => NULL()
    this%state%is_valid = .FALSE.

    IF (PRESENT(description)) this%info%description = description
    IF (PRESENT(callback)) this%cb%callback => callback

    this%state%is_valid = .TRUE.

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Command_Init

  SUBROUTINE AP_UI_Command_Cleanup(this)
    CLASS(AP_UI_Command_Type), INTENT(INOUT) :: this

    IF (ALLOCATED(this%args%arg_names)) DEALLOCATE(this%args%arg_names)
    IF (ALLOCATED(this%args%arg_values)) DEALLOCATE(this%args%arg_values)

    this%args%num_args = 0
    this%cb%callback => NULL()
    this%state%is_valid = .FALSE.
  END SUBROUTINE AP_UI_Command_Cleanup

  SUBROUTINE AP_UI_Command_AddArg(this, name, value, status)
    CLASS(AP_UI_Command_Type), INTENT(INOUT) :: this
    CHARACTER(len=*), INTENT(IN) :: name
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: value
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i
    CHARACTER(len=256), ALLOCATABLE :: temp_names(:)
    CHARACTER(len=256), ALLOCATABLE :: temp_values(:)

    IF (PRESENT(status)) CALL init_error_status(status)

    ! Resize arrays
    ALLOCATE(temp_names(this%args%num_args + 1))
    ALLOCATE(temp_values(this%args%num_args + 1))

    IF (this%args%num_args > 0) THEN
      temp_names(1:this%args%num_args) = this%args%arg_names
      temp_values(1:this%args%num_args) = this%args%arg_values
      DEALLOCATE(this%args%arg_names, this%args%arg_values)
    END IF

    temp_names(this%args%num_args + 1) = name
    IF (PRESENT(value)) THEN
      temp_values(this%args%num_args + 1) = value
    ELSE
      temp_values(this%args%num_args + 1) = ''
    END IF

    CALL MOVE_ALLOC(temp_names, this%args%arg_names)
    CALL MOVE_ALLOC(temp_values, this%args%arg_values)
    this%args%num_args = this%args%num_args + 1

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Command_AddArg

  SUBROUTINE AP_UI_Command_Execute(this, args, status)
    CLASS(AP_UI_Command_Type), INTENT(IN) :: this
    CHARACTER(len=*), INTENT(IN) :: args(:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%state%is_valid) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'AP_UI_Command_Execute: Command not initialized'
      END IF
      RETURN
    END IF

    IF (.NOT. ASSOCIATED(this%cb%callback)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'AP_UI_Command_Execute: No callback associated'
      END IF
      RETURN
    END IF

    ! Execute callback
    CALL this%cb%callback(this, args, status)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Command_Execute

  !=============================================================================
  ! UI OUTPUT FUNCTIONS
  !=============================================================================

  !> @brief Initialize UI (legacy interface)
  SUBROUTINE AP_UI_Init(mode, use_color, status)
    INTEGER(i4), INTENT(IN), OPTIONAL :: mode
    LOGICAL, INTENT(IN), OPTIONAL :: use_color
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(AP_UI_Ctrl_Type) :: ctrl

    IF (PRESENT(status)) CALL init_error_status(status)

    CALL ctrl%Init(mode=mode, use_color=use_color, status=status)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Init

  SUBROUTINE AP_UI_Cleanup()
    g_ui_mode = UI_MODE_INTERACTIVE
    g_ui_use_color = .TRUE.
  END SUBROUTINE AP_UI_Cleanup

  !> @brief Print message (legacy interface)
  SUBROUTINE AP_UI_Print(message, level, status)
    CHARACTER(len=*), INTENT(IN) :: message
    INTEGER(i4), INTENT(IN), OPTIONAL :: level
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    ! Skip if silent mode
    IF (g_ui_mode == UI_MODE_SILENT) RETURN

    ! Skip if verbose and not in verbose mode
    IF (PRESENT(level) .AND. level == 1 .AND. .NOT. g_ui_use_color) THEN
      RETURN
    END IF

    WRITE(*, '(A)') TRIM(message)
    FLUSH(UNIT=6)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Print

  SUBROUTINE AP_UI_PrintInfo(message, status)
    CHARACTER(len=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (g_ui_mode == UI_MODE_SILENT) RETURN

    IF (g_ui_use_color) THEN
      WRITE(*, '(A,A,A)') UI_COLOR_BLUE, 'INFO: ' // TRIM(message), UI_COLOR_RESET
    ELSE
      WRITE(*, '(A)') 'INFO: ' // TRIM(message)
    END IF
    FLUSH(UNIT=6)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_PrintInfo

  SUBROUTINE AP_UI_PrintWarning(message, status)
    CHARACTER(len=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (g_ui_mode == UI_MODE_SILENT) RETURN

    IF (g_ui_use_color) THEN
      WRITE(*, '(A,A,A)') UI_COLOR_YELLOW, 'WARNING: ' // TRIM(message), UI_COLOR_RESET
    ELSE
      WRITE(*, '(A)') 'WARNING: ' // TRIM(message)
    END IF
    FLUSH(UNIT=6)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_PrintWarning

  SUBROUTINE AP_UI_PrintError(message, status)
    CHARACTER(len=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (g_ui_mode == UI_MODE_SILENT) RETURN

    IF (g_ui_use_color) THEN
      WRITE(*, '(A,A,A)') UI_COLOR_RED, 'ERROR: ' // TRIM(message), UI_COLOR_RESET
    ELSE
      WRITE(*, '(A)') 'ERROR: ' // TRIM(message)
    END IF
    FLUSH(UNIT=6)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_PrintError

  SUBROUTINE AP_UI_PrintSuccess(message, status)
    CHARACTER(len=*), INTENT(IN) :: message
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (g_ui_mode == UI_MODE_SILENT) RETURN

    IF (g_ui_use_color) THEN
      WRITE(*, '(A,A,A)') UI_COLOR_GREEN, 'SUCCESS: ' // TRIM(message), UI_COLOR_RESET
    ELSE
      WRITE(*, '(A)') 'SUCCESS: ' // TRIM(message)
    END IF
    FLUSH(UNIT=6)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_PrintSuccess

  SUBROUTINE AP_UI_PrintHeader(title, status)
    CHARACTER(len=*), INTENT(IN) :: title
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, len_title
    CHARACTER(len=256) :: line

    IF (g_ui_mode == UI_MODE_SILENT) RETURN

    len_title = LEN_TRIM(title)
    line = ''
    DO i = 1, len_title + 4
      line = TRIM(line) // '='
    END DO

    WRITE(*, '(A)') TRIM(line)
    WRITE(*, '(A,A,A)') '| ', TRIM(title), ' |'
    WRITE(*, '(A)') TRIM(line)
    FLUSH(UNIT=6)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_PrintHeader

  SUBROUTINE AP_UI_PrintTable(headers, data, n_rows, n_cols, status)
    CHARACTER(len=*), INTENT(IN) :: headers(:)
    CHARACTER(len=*), INTENT(IN) :: data(:,:)
    INTEGER(i4), INTENT(IN) :: n_rows
    INTEGER(i4), INTENT(IN) :: n_cols
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, j, col_width(10)
    INTEGER(i4) :: width

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (g_ui_mode == UI_MODE_SILENT) RETURN

    ! Calculate column widths (simplified - max 10 columns)
    DO j = 1, MIN(n_cols, 10)
      col_width(j) = LEN_TRIM(headers(j))
      DO i = 1, n_rows
        width = LEN_TRIM(data(i,j))
        IF (width > col_width(j)) col_width(j) = width
      END DO
      col_width(j) = MIN(col_width(j) + 2, 30)  ! Max width 30
    END DO

    ! Print header
    WRITE(*, '(A)', ADVANCE='NO') '|'
    DO j = 1, MIN(n_cols, 10)
      WRITE(*, '(A)', ADVANCE='NO') ' ' // TRIM(headers(j))
      DO i = 1, col_width(j) - LEN_TRIM(headers(j)) - 1
        WRITE(*, '(A)', ADVANCE='NO') ' '
      END DO
      WRITE(*, '(A)', ADVANCE='NO') '|'
    END DO
    WRITE(*, '(A)') ''

    ! Print separator
    WRITE(*, '(A)', ADVANCE='NO') '|'
    DO j = 1, MIN(n_cols, 10)
      DO i = 1, col_width(j) + 1
        WRITE(*, '(A)', ADVANCE='NO') '-'
      END DO
      WRITE(*, '(A)', ADVANCE='NO') '|'
    END DO
    WRITE(*, '(A)') ''

    ! Print data rows
    DO i = 1, n_rows
      WRITE(*, '(A)', ADVANCE='NO') '|'
      DO j = 1, MIN(n_cols, 10)
        WRITE(*, '(A)', ADVANCE='NO') ' ' // TRIM(data(i,j))
        DO k = 1, col_width(j) - LEN_TRIM(data(i,j)) - 1
          WRITE(*, '(A)', ADVANCE='NO') ' '
        END DO
        WRITE(*, '(A)', ADVANCE='NO') '|'
      END DO
      WRITE(*, '(A)') ''
    END DO

    FLUSH(UNIT=6)

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_PrintTable

  !=============================================================================
  ! UI INPUT FUNCTIONS
  !=============================================================================

  SUBROUTINE AP_UI_ReadLine(prompt, line, status)
    CHARACTER(len=*), INTENT(IN) :: prompt
    CHARACTER(len=*), INTENT(OUT) :: line
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: ios

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (g_ui_mode == UI_MODE_SILENT) THEN
      line = ''
      RETURN
    END IF

    WRITE(*, '(A)', ADVANCE='NO') TRIM(prompt) // ': '
    FLUSH(UNIT=6)

    READ(UNIT=5, FMT='(A)', IOSTAT=ios) line

    IF (ios /= 0) THEN
      line = ''
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'AP_UI_ReadLine: Read error'
      END IF
      RETURN
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_ReadLine

  FUNCTION AP_UI_Confirm(prompt, default_yes, status) RESULT(confirmed)
    CHARACTER(len=*), INTENT(IN) :: prompt
    LOGICAL, INTENT(IN), OPTIONAL :: default_yes
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    LOGICAL :: confirmed

    CHARACTER(len=16) :: response
    LOGICAL :: def_yes
    INTEGER(i4) :: ios

    IF (PRESENT(status)) CALL init_error_status(status)
    confirmed = .FALSE.

    IF (g_ui_mode == UI_MODE_SILENT) THEN
      RETURN
    END IF

    def_yes = .TRUE.
    IF (PRESENT(default_yes)) def_yes = default_yes

    IF (def_yes) THEN
      WRITE(*, '(A)', ADVANCE='NO') TRIM(prompt) // ' [Y/n]: '
    ELSE
      WRITE(*, '(A)', ADVANCE='NO') TRIM(prompt) // ' [y/N]: '
    END IF
    FLUSH(UNIT=6)

    READ(UNIT=5, FMT='(A)', IOSTAT=ios) response

    IF (ios /= 0) THEN
      confirmed = def_yes
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF

    response = ADJUSTL(response)
    response = response(1:1)

    SELECT CASE (response)
    CASE ('y', 'Y')
      confirmed = .TRUE.
    CASE ('n', 'N')
      confirmed = .FALSE.
    CASE DEFAULT
      confirmed = def_yes
    END SELECT

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END FUNCTION AP_UI_Confirm

  !=============================================================================
  ! UTILITY FUNCTIONS
  !=============================================================================

  FUNCTION AP_UI_IsInteractive() RESULT(is_interactive)
    LOGICAL :: is_interactive

    is_interactive = (g_ui_mode == UI_MODE_INTERACTIVE)
  END FUNCTION AP_UI_IsInteractive

  FUNCTION AP_UI_GetTerminalWidth() RESULT(width)
    INTEGER(i4) :: width

    ! Try to get terminal width (platform-specific)
    ! For now, return default
    width = 80

    ! On Unix/Linux, could use: ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws)
    ! On Windows, could use: GetConsoleScreenBufferInfo
  END FUNCTION AP_UI_GetTerminalWidth

  FUNCTION AP_UI_GetMode() RESULT(mode)
    INTEGER(i4) :: mode

    mode = g_ui_mode
  END FUNCTION AP_UI_GetMode

END MODULE AP_UI_Mgr