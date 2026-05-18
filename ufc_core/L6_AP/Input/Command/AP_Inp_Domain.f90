!===============================================================================
! MODULE: AP_Inp_Domain
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Domain ?flat domain storage for command system
! BRIEF:  Index-tree + flat storage for commands, handlers, and history.
!
! Process phases:
!   P0: AP_Cmd_Domain_Init / AP_Cmd_Domain_Finalize
!   P1: AP_Cmd_Domain_AddCommand / AP_Cmd_Domain_AddHandler / AP_Cmd_Domain_AddHistory
!   P3: AP_Cmd_Domain_GetCommandById / AP_Cmd_Domain_GetHandlerById / AP_Cmd_Domain_GetHistoryById
!===============================================================================
MODULE AP_Inp_Domain
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Inp_Def, ONLY: Cmd, CmdHandler, HistoryEntry
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: CMD_DOMAIN_INIT_CAP = 64_i4
  INTEGER(i4), PARAMETER :: CMD_DOMAIN_INVALID_ID = 0_i4

  TYPE, PUBLIC :: AP_Cmd_Domain
    TYPE(Cmd), ALLOCATABLE           :: commands(:)
    TYPE(CmdHandler), ALLOCATABLE     :: handlers(:)
    TYPE(HistoryEntry), ALLOCATABLE   :: history(:)
    INTEGER(i4) :: n_commands = 0_i4
    INTEGER(i4) :: n_handlers = 0_i4
    INTEGER(i4) :: n_history  = 0_i4
    INTEGER(i4) :: next_handler_id = 1_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddCommand
    PROCEDURE :: AddHandler
    PROCEDURE :: AddHistory
    PROCEDURE :: GetCommandById
    PROCEDURE :: GetHandlerById
    PROCEDURE :: GetHandlerByName
    PROCEDURE :: GetHandlerIndexByName
    PROCEDURE :: GetHistoryById
    PROCEDURE :: ClearHistory
    PROCEDURE :: ClearCommands
  END TYPE AP_Cmd_Domain

CONTAINS

  SUBROUTINE AP_Cmd_Domain_Finalize(this)
    CLASS(AP_Cmd_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%commands)) DEALLOCATE(this%commands)
    IF (ALLOCATED(this%handlers)) DEALLOCATE(this%handlers)
    IF (ALLOCATED(this%history))  DEALLOCATE(this%history)
    this%n_commands = 0_i4
    this%n_handlers = 0_i4
    this%n_history  = 0_i4
    this%next_handler_id = 1_i4
    this%initialized = .FALSE.
  END SUBROUTINE AP_Cmd_Domain_Finalize

  SUBROUTINE AP_Cmd_Domain_Init(this, status)
    CLASS(AP_Cmd_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%n_commands = 0_i4
    this%n_handlers = 0_i4
    this%n_history  = 0_i4
    this%next_handler_id = 1_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Cmd_Domain_Init

  !====================================================================
  ! AP_Cmd_Domain_AddCommand
  ! Add command to flat queue (index = slot id)
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_AddCommand(this, cmd, cmd_id, status)
    CLASS(AP_Cmd_Domain), INTENT(INOUT) :: this
    TYPE(Cmd),            INTENT(IN)    :: cmd
    INTEGER(i4),          INTENT(OUT)   :: cmd_id
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    TYPE(Cmd), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, cap

    CALL init_error_status(status)
    cmd_id = CMD_DOMAIN_INVALID_ID
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Command domain not initialized"
      RETURN
    END IF

    n = this%n_commands + 1_i4
    IF (.NOT. ALLOCATED(this%commands)) THEN
      cap = MAX(CMD_DOMAIN_INIT_CAP, n)
      ALLOCATE(this%commands(cap))
    ELSE IF (n > SIZE(this%commands)) THEN
      cap = SIZE(this%commands) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_commands) = this%commands(1:this%n_commands)
      CALL MOVE_ALLOC(tmp, this%commands)
    END IF

    this%commands(n) = cmd
    this%commands(n)%cfg%id = n
    this%n_commands = n
    cmd_id = n
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Cmd_Domain_AddCommand

  !====================================================================
  ! AP_Cmd_Domain_AddHandler
  ! Add handler to flat registry (index = handler_id).
  ! Accepts CmdHandler type to avoid procedure pointer ABI across modules.
  ! Returns IF_STATUS_INVALID if name already registered.
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_AddHandler(this, h, handler_id, status)
    CLASS(AP_Cmd_Domain), INTENT(INOUT) :: this
    TYPE(CmdHandler),    INTENT(IN)    :: h
    INTEGER(i4),         INTENT(OUT)   :: handler_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(CmdHandler), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, cap, i

    CALL init_error_status(status)
    handler_id = CMD_DOMAIN_INVALID_ID
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Command domain not initialized"
      RETURN
    END IF

    ! Check if already registered (match Reg_Reg behavior)
    IF (ALLOCATED(this%handlers)) THEN
      DO i = 1, this%n_handlers
        IF (this%handlers(i)%registered .AND. this%handlers(i)%name == h%name(1:MIN(16, LEN_TRIM(h%name)))) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "Command already registered: " // TRIM(h%name)
          RETURN
        END IF
      END DO
    END IF

    n = this%n_handlers + 1_i4
    IF (.NOT. ALLOCATED(this%handlers)) THEN
      cap = MAX(CMD_DOMAIN_INIT_CAP, n)
      ALLOCATE(this%handlers(cap))
    ELSE IF (n > SIZE(this%handlers)) THEN
      cap = SIZE(this%handlers) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_handlers) = this%handlers(1:this%n_handlers)
      CALL MOVE_ALLOC(tmp, this%handlers)
    END IF

    this%handlers(n) = h
    this%handlers(n)%cfg%id = this%next_handler_id
    this%handlers(n)%registered = .TRUE.
    this%n_handlers = n
    handler_id = this%next_handler_id
    this%next_handler_id = this%next_handler_id + 1_i4
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Cmd_Domain_AddHandler

  !====================================================================
  ! AP_Cmd_Domain_AddHistory
  ! Add history entry
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_AddHistory(this, cmd, source, timestamp, status)
    CLASS(AP_Cmd_Domain), INTENT(INOUT) :: this
    TYPE(Cmd),            INTENT(IN)    :: cmd
    CHARACTER(LEN=*),     INTENT(IN)    :: source
    INTEGER(i4),         INTENT(IN), OPTIONAL :: timestamp
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    TYPE(HistoryEntry), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, cap

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Command domain not initialized"
      RETURN
    END IF

    n = this%n_history + 1_i4
    IF (.NOT. ALLOCATED(this%history)) THEN
      cap = MAX(CMD_DOMAIN_INIT_CAP, n)
      ALLOCATE(this%history(cap))
    ELSE IF (n > SIZE(this%history)) THEN
      cap = SIZE(this%history) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_history) = this%history(1:this%n_history)
      CALL MOVE_ALLOC(tmp, this%history)
    END IF

    this%history(n)%cmd = cmd
    this%history(n)%source = source(1:MIN(256, LEN_TRIM(source)))
    this%history(n)%timestamp = 0_i4
    IF (PRESENT(timestamp)) this%history(n)%timestamp = timestamp
    this%n_history = n
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Cmd_Domain_AddHistory

  !====================================================================
  ! AP_Cmd_Domain_GetCommandById
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_GetCommandById(this, idx, cmd, found)
    CLASS(AP_Cmd_Domain), INTENT(IN)  :: this
    INTEGER(i4),          INTENT(IN)  :: idx
    TYPE(Cmd),           INTENT(OUT) :: cmd
    LOGICAL,             INTENT(OUT) :: found

    found = .FALSE.
    IF (.NOT. this%initialized) RETURN
    IF (idx < 1) RETURN
    IF (.NOT. ALLOCATED(this%commands)) RETURN
    IF (idx > this%n_commands) RETURN
    cmd = this%commands(idx)
    found = .TRUE.
  END SUBROUTINE AP_Cmd_Domain_GetCommandById

  !====================================================================
  ! AP_Cmd_Domain_GetHandlerById
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_GetHandlerById(this, idx, h, found)
    CLASS(AP_Cmd_Domain), INTENT(IN)  :: this
    INTEGER(i4),          INTENT(IN)  :: idx
    TYPE(CmdHandler),     INTENT(OUT) :: h
    LOGICAL,              INTENT(OUT) :: found

    INTEGER(i4) :: i

    found = .FALSE.
    IF (.NOT. this%initialized) RETURN
    IF (.NOT. ALLOCATED(this%handlers)) RETURN
    h = CmdHandler()
    IF (idx >= 1 .AND. idx <= this%n_handlers) THEN
      h = this%handlers(idx)
      found = h%registered
      RETURN
    END IF
    ! Also search by handler.id
    DO i = 1, this%n_handlers
      IF (this%handlers(i)%cfg%id == idx) THEN
        h = this%handlers(i)
        found = .TRUE.
        RETURN
      END IF
    END DO
  END SUBROUTINE AP_Cmd_Domain_GetHandlerById

  !====================================================================
  ! AP_Cmd_Domain_GetHandlerByName
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_GetHandlerByName(this, name, h, found)
    CLASS(AP_Cmd_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),     INTENT(IN)  :: name
    TYPE(CmdHandler),     INTENT(OUT) :: h
    LOGICAL,              INTENT(OUT) :: found

    INTEGER(i4) :: i
    CHARACTER(LEN=16) :: name_trim

    found = .FALSE.
    h = CmdHandler()
    IF (.NOT. this%initialized) RETURN
    IF (.NOT. ALLOCATED(this%handlers)) RETURN
    name_trim = name(1:MIN(16, LEN_TRIM(name)))
    DO i = 1, this%n_handlers
      IF (this%handlers(i)%name == name_trim .AND. this%handlers(i)%registered) THEN
        h = this%handlers(i)
        found = .TRUE.
        RETURN
      END IF
    END DO
  END SUBROUTINE AP_Cmd_Domain_GetHandlerByName

  !====================================================================
  ! AP_Cmd_Domain_GetHistoryById
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_GetHistoryById(this, idx, entry, found)
    CLASS(AP_Cmd_Domain), INTENT(IN)  :: this
    INTEGER(i4),          INTENT(IN)  :: idx
    TYPE(HistoryEntry),   INTENT(OUT) :: entry
    LOGICAL,              INTENT(OUT) :: found

    found = .FALSE.
    IF (.NOT. this%initialized) RETURN
    IF (idx < 1) RETURN
    IF (.NOT. ALLOCATED(this%history)) RETURN
    IF (idx > this%n_history) RETURN
    entry = this%history(idx)
    found = .TRUE.
  END SUBROUTINE AP_Cmd_Domain_GetHistoryById

  !====================================================================
  ! AP_Cmd_Domain_GetHandlerIndexByName
  ! Return 1-based slot index for Cmd_Find compatibility
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_GetHandlerIndexByName(this, name, idx, found)
    CLASS(AP_Cmd_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),     INTENT(IN)  :: name
    INTEGER(i4),         INTENT(OUT) :: idx
    LOGICAL,             INTENT(OUT) :: found

    INTEGER(i4) :: i
    CHARACTER(LEN=16) :: name_trim

    found = .FALSE.
    idx = 0_i4
    IF (.NOT. this%initialized) RETURN
    IF (.NOT. ALLOCATED(this%handlers)) RETURN
    name_trim = name(1:MIN(16, LEN_TRIM(name)))
    DO i = 1, this%n_handlers
      IF (this%handlers(i)%name == name_trim .AND. this%handlers(i)%registered) THEN
        idx = i
        found = .TRUE.
        RETURN
      END IF
    END DO
  END SUBROUTINE AP_Cmd_Domain_GetHandlerIndexByName

  !====================================================================
  ! AP_Cmd_Domain_ClearHistory
  ! Clear all history entries (for Cmd_HistoryClear)
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_ClearHistory(this)
    CLASS(AP_Cmd_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%n_history = 0_i4
    IF (ALLOCATED(this%history)) DEALLOCATE(this%history)
  END SUBROUTINE AP_Cmd_Domain_ClearHistory

  !====================================================================
  ! AP_Cmd_Domain_ClearCommands
  ! Clear command queue (handlers and history preserved)
  !====================================================================
  SUBROUTINE AP_Cmd_Domain_ClearCommands(this)
    CLASS(AP_Cmd_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%n_commands = 0_i4
    IF (ALLOCATED(this%commands)) DEALLOCATE(this%commands)
  END SUBROUTINE AP_Cmd_Domain_ClearCommands

END MODULE AP_Inp_Domain