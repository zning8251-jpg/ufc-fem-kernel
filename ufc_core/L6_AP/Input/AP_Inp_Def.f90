!===============================================================================
! MODULE: AP_Inp_Def
! LAYER:  L6_AP
! DOMAIN: Input
! ROLE:   Def
! BRIEF:  Type definitions for Input domain — Cmd/CmdCtx/Proc/CmdList + flat entries.
!
! Four-Type Catalogue:
!   ParsedKeywordEntry — parsed keyword slot (Desc-like, immutable after parse)
!   ParsedCommandEntry — parsed command slot (Desc-like, immutable after parse)
!   Cmd                — command value object  (Desc)
!   CmdCtx             — command runtime context (Ctx/State)
!   CmdMacroDef        — macro definition (Desc)
!   CmdMacroCtx        — macro execution context (Ctx)
!   CmdHandler         — handler metadata (Desc)
!   CommandDesc        — full command description (Desc)
!   CommandLogEntry    — audit log entry (Desc)
!   Proc               — procedure definition (Desc)
!   CmdList            — command list index (State)
!   HistoryEntry       — history slot (Desc)
!
! Arg Types:
!   AP_Inp_AddKW_Arg   — AddParsedKeyword input bundle (Arg)
!   AP_Inp_AddCmd_Arg  — AddParsedCommand input bundle (Arg)
!
! Constants: AP_INPUT_KEYWORD_ID_INVALID, AP_INPUT_CMD_ID_INVALID,
!            AP_INPUT_DOMAIN_KEYWORD, AP_INPUT_DOMAIN_CMD
!
! [REMOVED] Legacy aliases: UF_Command, UF_CommandCtx, UF_CommandList — migrated to Cmd/CmdCtx/CmdList
!
! Status: FOUR-TYPE | Last verified: 2026-04-29
!===============================================================================
MODULE AP_Inp_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Constants: AP_INP_*
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: AP_INPUT_KEYWORD_ID_INVALID = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_INPUT_CMD_ID_INVALID     = 0_i4

  !-----------------------------------------------------------------------------
  ! TYPE: ParsedKeywordEntry (Desc — immutable after parse)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: ParsedKeywordEntry
    INTEGER(i4) :: keyword_id    = 0_i4   ! Index into MD_KWReg or local id
    INTEGER(i4) :: line_number   = 0_i4
    CHARACTER(LEN=32) :: name    = ' '
    INTEGER(i4) :: category      = 0_i4   ! KW_CAT_* from L3
    LOGICAL     :: has_data      = .FALSE.
  END TYPE ParsedKeywordEntry

  !-----------------------------------------------------------------------------
  ! TYPE: ParsedCommandEntry (Desc — immutable after parse)
  !   id         <- formerly cmd_id
  !   line       <- formerly line_number
  !   keyword_idx: extra field (not in Cmd) for keyword context
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: ParsedCommandEntry
    INTEGER(i4) :: id            = 0_i4   ! = Cmd%cfg%id  (formerly cmd_id)
    INTEGER(i4) :: cmd_id        = 0_i4   ! @deprecated alias for id
    INTEGER(i4) :: keyword_idx   = 0_i4   ! Index into parsed_keywords(:)
    INTEGER(i4) :: line          = 0_i4   ! = Cmd%line (formerly line_number)
    INTEGER(i4) :: line_number   = 0_i4   ! @deprecated alias for line
    CHARACTER(LEN=16)  :: name     = ' '
    CHARACTER(LEN=64)  :: opt      = ' '
    REAL(wp)    :: params(3)      = 0.0_wp
    CHARACTER(LEN=256) :: param_str = ' '
  END TYPE ParsedCommandEntry

  !-----------------------------------------------------------------------------
  ! Constants: AP_INPUT_DOMAIN_*
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: AP_INPUT_DOMAIN_KEYWORD = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_INPUT_DOMAIN_CMD    = 2_i4

  !===============================================================================
  ! Public Types
  !===============================================================================
  PUBLIC :: Cmd
  PUBLIC :: CmdCtx
  PUBLIC :: CmdMacroDef
  PUBLIC :: CmdMacroCtx
  PUBLIC :: CommandDesc
  PUBLIC :: CommandLogEntry
  PUBLIC :: Proc
  PUBLIC :: CmdList
  PUBLIC :: CmdHandler
  PUBLIC :: HistoryEntry
  PUBLIC :: AP_Inp_AddKW_Arg
  PUBLIC :: AP_Inp_AddCmd_Arg

  ! [REMOVED] Legacy aliases UF_Command, UF_CommandCtx, UF_CommandList — migrated to Cmd/CmdCtx/CmdList

  !-----------------------------------------------------------------------------
  ! TYPE: AP_Inp_AddKW_Arg (Arg — AddParsedKeyword input bundle)
  !   Bundles >=6 params of AP_Input_Domain_AddParsedKeyword into a single Arg.
  !-----------------------------------------------------------------------------
  TYPE :: AP_Inp_AddKW_Arg
    INTEGER(i4)       :: keyword_id  = 0_i4
    INTEGER(i4)       :: line_number = 0_i4
    CHARACTER(LEN=32) :: name        = ' '
    INTEGER(i4)       :: category    = 0_i4
    LOGICAL           :: has_data    = .FALSE.
  END TYPE AP_Inp_AddKW_Arg

  !-----------------------------------------------------------------------------
  ! TYPE: AP_Inp_AddCmd_Arg (Arg — AddParsedCommand input bundle)
  !   Bundles >=6 params of AP_Input_Domain_AddParsedCommand into a single Arg.
  !-----------------------------------------------------------------------------
  TYPE :: AP_Inp_AddCmd_Arg
    INTEGER(i4)        :: cmd_id      = 0_i4
    INTEGER(i4)        :: keyword_idx = 0_i4
    INTEGER(i4)        :: line_number = 0_i4
    CHARACTER(LEN=16)  :: name        = ' '
    CHARACTER(LEN=64)  :: opt         = ' '
    REAL(wp)           :: params(3)   = 0.0_wp
    CHARACTER(LEN=256) :: param_str   = ' '
  END TYPE AP_Inp_AddCmd_Arg

  !-----------------------------------------------------------------------------
  ! TYPE: Cmd (Desc — command value object)
  !-----------------------------------------------------------------------------
  TYPE :: Cmd
    CHARACTER(len=16) :: name = ''        ! Command name
    INTEGER(i4)       :: id = 0           ! Command ID
    CHARACTER(len=64) :: opt = ''         ! Option string
    REAL(wp)          :: params(3) = 0.0_wp ! Numeric parameters
    CHARACTER(len=256):: param_str = ''   ! String parameters
    INTEGER(i4)       :: line = 0         ! Line number
  END TYPE Cmd

  ! [REMOVED] UF_Command type — use Cmd instead

  !-----------------------------------------------------------------------------
  ! TYPE: CmdMacroDef (Desc — macro definition, immutable)
  !-----------------------------------------------------------------------------
  TYPE :: CmdMacroDef
    CHARACTER(len=32)  :: name = ''
    INTEGER(i4)        :: num_params = 0
    CHARACTER(len=16)  :: param_names(8) = ''
    CHARACTER(len=256) :: body = ''          ! Raw macro body or reference key
    LOGICAL            :: defined = .false.
  END TYPE CmdMacroDef

  !-----------------------------------------------------------------------------
  ! TYPE: CmdMacroCtx (Ctx — macro execution context)
  !-----------------------------------------------------------------------------
  TYPE :: CmdMacroCtx
    INTEGER(i4) :: call_depth    = 0
    INTEGER(i4) :: max_depth     = 16
    INTEGER(i4) :: current_macro = 0
    INTEGER(i4) :: current_line  = 0
  END TYPE CmdMacroCtx

  !-----------------------------------------------------------------------------
  ! TYPE: CmdCtx (Ctx/State — command runtime context)
  !-----------------------------------------------------------------------------
  TYPE :: CmdCtx
    ! Model references (use generic pointer with deferred type)
    ! Note: Using CLASS(*) for polymorphic pointer requires ALLOCATABLE
    ! For now, use a simple workaround with generic storage
    INTEGER(i4) :: model_ptr = 0_i4  ! Placeholder for model reference ID
    INTEGER(i4) :: solver_ptr = 0_i4 ! Placeholder for solver reference ID
    INTEGER(i4) :: job_ptr = 0_i4    ! Placeholder for job reference ID
    INTEGER(i4) :: current_part_ptr = 0_i4 ! Placeholder for part reference ID

    ! State
    INTEGER(i4) :: step_id = 0
    INTEGER(i4) :: inc_id = 0
    INTEGER(i4) :: iter_id = 0

    ! Mode
    LOGICAL :: interactive = .false.
    LOGICAL :: verbose = .true.

    ! Ctrl flow stacks
    INTEGER(i4), ALLOCATABLE :: loop_stack(:)
    INTEGER(i4), ALLOCATABLE :: loop_max_stack(:)
    INTEGER(i4), ALLOCATABLE :: loop_start_stac(:)
    INTEGER(i4) :: loop_depth = 0
    INTEGER(i4), ALLOCATABLE :: if_stack(:)
    INTEGER(i4) :: if_depth = 0
    LOGICAL, ALLOCATABLE :: if_cond_stack(:)
    LOGICAL, ALLOCATABLE :: else_exec_stack(:)
    INTEGER(i4) :: break_level = 0
    INTEGER(i4) :: continue_level = 0
    INTEGER(i4) :: jump_target = 0

    ! Variables (unified memory: pointer + id)
    REAL(wp), POINTER :: vars(:) => null()
    INTEGER(i4) :: vars_id = -1
    CHARACTER(len=32), ALLOCATABLE :: var_names(:)

    ! Macro execution context (5.2 skeleton)
    TYPE(CmdMacroCtx) :: macro

    ! Error
    TYPE(ErrorStatusType) :: last_error
  END TYPE CmdCtx

  ! [REMOVED] UF_CommandCtx type — use CmdCtx instead

  !-----------------------------------------------------------------------------
  ! TYPE: CmdHandler (Desc — handler metadata)
  !-----------------------------------------------------------------------------
  TYPE :: CmdHandler
    CHARACTER(len=16) :: name = ''
    INTEGER(i4) :: id = 0
    CHARACTER(len=128) :: desc = ''
    LOGICAL :: registered = .false.
    ! Note: Actual handler procedure is stored in AP_Cmd_Domain%handlers
    ! and invoked via command ID lookup
  END TYPE CmdHandler

  !-----------------------------------------------------------------------------
  ! TYPE: HistoryEntry (Desc — history slot)
  !-----------------------------------------------------------------------------
  TYPE :: HistoryEntry
    TYPE(Cmd) :: cmd
    INTEGER(i4) :: timestamp = 0
    CHARACTER(len=256) :: source = ''
  END TYPE HistoryEntry

  !-----------------------------------------------------------------------------
  ! TYPE: CommandDesc (Desc — canonical command description)
  !-----------------------------------------------------------------------------
  TYPE :: CommandDesc
    CHARACTER(len=16)  :: name = ''
    CHARACTER(len=256) :: category = ''
    CHARACTER(len=256) :: description = ''
    CHARACTER(len=256) :: syntax = ''
    CHARACTER(len=256) :: params = ''         ! Short param summary (display)
    CHARACTER(len=512) :: parameters = ''    ! Full parameter specification
    CHARACTER(len=512) :: examples = ''     ! Usage examples
    LOGICAL            :: is_hidden       = .false.
    LOGICAL            :: is_experimental = .false.
  END TYPE CommandDesc

  !-----------------------------------------------------------------------------
  ! TYPE: CommandLogEntry (Desc — audit log entry)
  !-----------------------------------------------------------------------------
  TYPE :: CommandLogEntry
    TYPE(Cmd)          :: cmd
    CHARACTER(len=64)  :: source   = ''
    CHARACTER(len=64)  :: user     = ''
    INTEGER(i4)        :: timestamp = 0
  END TYPE CommandLogEntry

  !-----------------------------------------------------------------------------
  ! TYPE: Proc (Desc — procedure definition)
  !-----------------------------------------------------------------------------
  TYPE :: Proc
    CHARACTER(len=32) :: name = ''
    CHARACTER(len=16) :: params(3) = ''
    TYPE(Cmd), ALLOCATABLE :: cmds(:)
    INTEGER(i4) :: num_cmds = 0
    LOGICAL :: defined = .false.
  END TYPE Proc

  !-----------------------------------------------------------------------------
  ! TYPE: CmdList (State — command list index)
  !-----------------------------------------------------------------------------
  TYPE :: CmdList
    INTEGER(i4), ALLOCATABLE :: cmd_ids(:)   ! Indices into g_cmd_domain%commands
    INTEGER(i4) :: num_cmds = 0
    INTEGER(i4) :: idx = 0
    LOGICAL :: init = .false.
  END TYPE CmdList

  ! [REMOVED] UF_CommandList type — use CmdList instead

  !===============================================================================
  ! Abstract Interfaces — moved to AP_Inp_Handler_Interface
  !===============================================================================

END MODULE AP_Inp_Def
