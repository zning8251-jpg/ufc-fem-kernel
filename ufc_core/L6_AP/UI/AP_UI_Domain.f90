!===============================================================================
! MODULE: AP_UI_Domain
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Domain ?UI command registration and dispatch
! BRIEF:  User interface command registration, dispatch and lifecycle.
!===============================================================================
MODULE AP_UI_Domain
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_UI_Def, ONLY: CommandHistoryEntry, UITreeNodeEntry, &
                         AP_UI_HISTORY_ID_INVALID, AP_UI_NODE_ID_INVALID
  USE AP_InpScript_Brg,  ONLY: UF_Cmd_ExecString
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: UI_DOMAIN_INIT_CAP = 64_i4

  ! --- UI mode enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_UI_BATCH       = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_UI_INTERACTIVE  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_UI_SCRIPT       = 3_i4

  INTEGER(i4), PARAMETER, PUBLIC :: AP_CMD_MAX_REGISTERED = 256_i4

  TYPE, PUBLIC :: AP_UI_State
    INTEGER(i4) :: mode              = AP_UI_BATCH
    INTEGER(i4) :: nRegisteredCmds   = 0_i4
    INTEGER(i4) :: nExecutedCmds     = 0_i4
    INTEGER(i4) :: nFailedCmds       = 0_i4
    LOGICAL     :: sessionActive     = .FALSE.
  END TYPE AP_UI_State

  TYPE, PUBLIC :: AP_UI_Ctrl
    INTEGER(i4) :: defaultMode    = AP_UI_BATCH
    LOGICAL     :: echoCommands   = .FALSE.
    LOGICAL     :: colorOutput    = .FALSE.
    LOGICAL     :: progressBar    = .TRUE.
    INTEGER(i4) :: historySize    = 100_i4
  END TYPE AP_UI_Ctrl

  ! --- Arg types (Phase B) ---
  TYPE, PUBLIC :: AP_UI_RegisterCommand_Arg
    CHARACTER(LEN=128)    :: cmdName = ""  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_UI_RegisterCommand_Arg

  TYPE, PUBLIC :: AP_UI_ExecuteCommand_Arg
    CHARACTER(LEN=512)    :: cmdLine = ""  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_UI_ExecuteCommand_Arg

  TYPE, PUBLIC :: AP_UI_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_UI_GetSummary_Arg

  TYPE, PUBLIC :: AP_UIDomain
    TYPE(AP_UI_State) :: state
    TYPE(AP_UI_Ctrl)  :: ctrl
    ! Flat domain storage (index tree + flat)
    TYPE(CommandHistoryEntry), ALLOCATABLE :: command_history(:)
    TYPE(UITreeNodeEntry),     ALLOCATABLE :: ui_tree_nodes(:)
    INTEGER(i4) :: n_history = 0_i4
    INTEGER(i4) :: n_nodes   = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterCommand
    PROCEDURE :: ExecuteCommand
    PROCEDURE :: GetSummary
    PROCEDURE :: AddCommandHistory
    PROCEDURE :: AddTreeNode
    PROCEDURE :: GetHistoryById
    PROCEDURE :: GetNodeById
  END TYPE AP_UIDomain

CONTAINS

  SUBROUTINE AP_UI_Domain_Finalize(this)
    CLASS(AP_UIDomain), INTENT(INOUT) :: this
    INTEGER(i4) :: i
    IF (.NOT. this%initialized) RETURN
    this%state = AP_UI_State()
    IF (ALLOCATED(this%command_history)) DEALLOCATE(this%command_history)
    IF (ALLOCATED(this%ui_tree_nodes)) THEN
      DO i = 1, SIZE(this%ui_tree_nodes)
        IF (ALLOCATED(this%ui_tree_nodes(i)%child_ids)) &
             DEALLOCATE(this%ui_tree_nodes(i)%child_ids)
      END DO
      DEALLOCATE(this%ui_tree_nodes)
    END IF
    this%n_history = 0_i4
    this%n_nodes   = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE AP_UI_Domain_Finalize

  SUBROUTINE AP_UI_Domain_Init(this, status)
    CLASS(AP_UIDomain),   INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctrl = AP_UI_Ctrl()
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Domain_Init

  !====================================================================
  ! AP_UI_Domain_RegisterCommand  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_UI_Domain_RegisterCommand(this, arg)
    CLASS(AP_UIDomain),             INTENT(INOUT) :: this
    TYPE(AP_UI_RegisterCommand_Arg), INTENT(INOUT) :: arg
    CALL AP_UI_RegisterCommand_Impl(this, arg%cmdName, arg%status)
  END SUBROUTINE AP_UI_Domain_RegisterCommand

  SUBROUTINE AP_UI_RegisterCommand_Impl(this, cmdName, status)
    CLASS(AP_UIDomain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),    INTENT(IN)    :: cmdName
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "UI domain not initialized"
      RETURN
    END IF

    IF (this%state%nRegisteredCmds >= AP_CMD_MAX_REGISTERED) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Maximum command capacity exceeded"
      RETURN
    END IF

    IF (LEN_TRIM(cmdName) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Command name is empty"
      RETURN
    END IF

    this%state%nRegisteredCmds = this%state%nRegisteredCmds + 1_i4
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_UI_RegisterCommand_Impl

  !====================================================================
  ! AP_UI_Domain_ExecuteCommand  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_UI_Domain_ExecuteCommand(this, arg)
    CLASS(AP_UIDomain),            INTENT(INOUT) :: this
    TYPE(AP_UI_ExecuteCommand_Arg), INTENT(INOUT) :: arg
    CALL AP_UI_ExecuteCommand_Impl(this, arg%cmdLine, arg%status)
  END SUBROUTINE AP_UI_Domain_ExecuteCommand

  SUBROUTINE AP_UI_ExecuteCommand_Impl(this, cmdLine, status)
    CLASS(AP_UIDomain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),    INTENT(IN)    :: cmdLine
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(CommandHistoryEntry) :: hist_entry
    TYPE(ErrorStatusType) :: add_status
    INTEGER(i4) :: hist_id

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "UI domain not initialized"
      RETURN
    END IF

    IF (LEN_TRIM(cmdLine) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Command line is empty"
      RETURN
    END IF

    CALL UF_Cmd_ExecString(TRIM(cmdLine), status=status)

    this%state%nExecutedCmds = this%state%nExecutedCmds + 1_i4
    IF (status%status_code /= IF_STATUS_OK) this%state%nFailedCmds = this%state%nFailedCmds + 1_i4
    this%state%sessionActive = .TRUE.

    hist_entry%cmd_id     = 0_i4
    hist_entry%cmd_line   = TRIM(cmdLine)
    hist_entry%succeeded  = (status%status_code == IF_STATUS_OK)
    hist_entry%timestamp  = 0.0_wp
    hist_entry%line_number = 0_i4
    CALL this%AddCommandHistory(hist_entry, hist_id, add_status)

  END SUBROUTINE AP_UI_ExecuteCommand_Impl

  !====================================================================
  ! AP_UI_Domain_GetSummary  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_UI_Domain_GetSummary(this, arg)
    CLASS(AP_UIDomain),        INTENT(IN)    :: this
    TYPE(AP_UI_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL AP_UI_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE AP_UI_Domain_GetSummary

  SUBROUTINE AP_UI_GetSummary_Impl(this, summary, status)
    CLASS(AP_UIDomain), INTENT(IN)  :: this
    CHARACTER(LEN=512),  INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "UI domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,L1,A,L1,A,I0,A,I0)') &
      "UI Summary: Mode=", this%state%mode, &
      ", RegisteredCmds=", this%state%nRegisteredCmds, &
      ", ExecutedCmds=", this%state%nExecutedCmds, &
      ", FailedCmds=", this%state%nFailedCmds, &
      ", SessionActive=", this%state%sessionActive, &
      ", EchoCmds=", this%ctrl%echoCommands, &
      ", History=", this%n_history, ", Nodes=", this%n_nodes

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_UI_GetSummary_Impl

  !====================================================================
  ! AP_UI_Domain_AddCommandHistory
  ! Add command history entry to flat domain
  !====================================================================
  SUBROUTINE AP_UI_Domain_AddCommandHistory(this, entry, history_id, status)
    CLASS(AP_UIDomain),       INTENT(INOUT) :: this
    TYPE(CommandHistoryEntry), INTENT(IN)    :: entry
    INTEGER(i4),              INTENT(OUT)   :: history_id
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    TYPE(CommandHistoryEntry), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, cap

    CALL init_error_status(status)
    history_id = AP_UI_HISTORY_ID_INVALID
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "UI domain not initialized"
      RETURN
    END IF

    n = this%n_history + 1_i4
    IF (.NOT. ALLOCATED(this%command_history)) THEN
      cap = MAX(UI_DOMAIN_INIT_CAP, n)
      ALLOCATE(this%command_history(cap))
    ELSE IF (n > SIZE(this%command_history)) THEN
      cap = SIZE(this%command_history) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_history) = this%command_history(1:this%n_history)
      CALL MOVE_ALLOC(tmp, this%command_history)
    END IF

    this%command_history(n) = entry
    this%command_history(n)%history_id = n
    this%n_history = n
    history_id = n
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Domain_AddCommandHistory

  !====================================================================
  ! AP_UI_Domain_AddTreeNode
  ! Add UI tree node to flat domain
  !====================================================================
  SUBROUTINE AP_UI_Domain_AddTreeNode(this, entry, node_id, status)
    CLASS(AP_UIDomain),     INTENT(INOUT) :: this
    TYPE(UITreeNodeEntry),  INTENT(IN)    :: entry
    INTEGER(i4),            INTENT(OUT)   :: node_id
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    TYPE(UITreeNodeEntry), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, cap

    CALL init_error_status(status)
    node_id = AP_UI_NODE_ID_INVALID
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "UI domain not initialized"
      RETURN
    END IF

    n = this%n_nodes + 1_i4
    IF (.NOT. ALLOCATED(this%ui_tree_nodes)) THEN
      cap = MAX(UI_DOMAIN_INIT_CAP, n)
      ALLOCATE(this%ui_tree_nodes(cap))
    ELSE IF (n > SIZE(this%ui_tree_nodes)) THEN
      cap = SIZE(this%ui_tree_nodes) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_nodes) = this%ui_tree_nodes(1:this%n_nodes)
      CALL MOVE_ALLOC(tmp, this%ui_tree_nodes)
    END IF

    this%ui_tree_nodes(n) = entry
    this%ui_tree_nodes(n)%node_id = n
    this%n_nodes = n
    node_id = n
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Domain_AddTreeNode

  !====================================================================
  ! AP_UI_Domain_GetHistoryById
  ! Get command history entry by id
  !====================================================================
  SUBROUTINE AP_UI_Domain_GetHistoryById(this, idx, entry, found)
    CLASS(AP_UIDomain),       INTENT(IN)  :: this
    INTEGER(i4),              INTENT(IN)  :: idx
    TYPE(CommandHistoryEntry), INTENT(OUT) :: entry
    LOGICAL,                   INTENT(OUT) :: found

    found = .FALSE.
    IF (idx < 1_i4 .OR. idx > this%n_history) RETURN
    IF (.NOT. ALLOCATED(this%command_history)) RETURN
    entry = this%command_history(idx)
    found = .TRUE.
  END SUBROUTINE AP_UI_Domain_GetHistoryById

  !====================================================================
  ! AP_UI_Domain_GetNodeById
  ! Get UI tree node by id
  !====================================================================
  SUBROUTINE AP_UI_Domain_GetNodeById(this, idx, entry, found)
    CLASS(AP_UIDomain),    INTENT(IN)  :: this
    INTEGER(i4),           INTENT(IN)  :: idx
    TYPE(UITreeNodeEntry), INTENT(OUT) :: entry
    LOGICAL,               INTENT(OUT) :: found

    found = .FALSE.
    IF (idx < 1_i4 .OR. idx > this%n_nodes) RETURN
    IF (.NOT. ALLOCATED(this%ui_tree_nodes)) RETURN
    entry = this%ui_tree_nodes(idx)
    found = .TRUE.
  END SUBROUTINE AP_UI_Domain_GetNodeById

END MODULE AP_UI_Domain