!===============================================================================
! MODULE: AP_Inp_Script
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Facade — re-exports all command system sub-modules
! BRIEF:  Facade - re-exports all command system sub-modules.
!===============================================================================
module AP_Inp_Script
  USE AP_Inp_Def,   only: Cmd, CmdCtx, Proc, CmdList, CommandDesc, CommandLogEntry, &
                               CmdHandler, HistoryEntry
  USE AP_Inp_Domain, only: AP_Cmd_Domain

  ! Phase 1-6 sub-modules
  USE AP_InpScript_Logger,  only: CmdLogger, g_logger, Cmd_Log, Cmd_LogError, Cmd_SetLogLevel, &
       Cmd_Log_In, Cmd_Log_Out, Cmd_LogError_In, Cmd_LogError_Out, &
       Cmd_SetLogLevel_In, Cmd_SetLogLevel_Out, &
       Cmd_Log_Structured, Cmd_LogError_Structured, Cmd_SetLogLevel_Structured, &
       LOG_NONE, LOG_ERROR, LOG_WARN, LOG_INFO, LOG_DEBUG, LOG_TRACE
  USE AP_InpScript_Debug,   only: CmdDebugger, g_debugger, Cmd_DebugSetBrk, Cmd_DebugShowVars, &
       Cmd_DebugSetBrk_In, Cmd_DebugSetBrk_Out, Cmd_DebugShowVars_In, Cmd_DebugShowVars_Out, &
       Cmd_DebugSetBrk_Structured, Cmd_DebugShowVars_Structured
  USE AP_InpScript_History, only: CmdHistory
  USE AP_InpScript_Alias,   only: CmdAliasMgr, g_alias_mgr, AliasEntry, &
       Cmd_AliasDefine, Cmd_AliasResolve, Cmd_AliasDefine_In, Cmd_AliasDefine_Out, &
       Cmd_AliasResolve_In, Cmd_AliasResolve_Out, &
       Cmd_AliasDefine_Structured, Cmd_AliasResolve_Structured
  USE AP_InpScript_Label,   only: CmdLabelMgr, g_label_mgr, LabelEntry

  ! Phase 7-8 sub-modules
  USE AP_InpScript_Help,     only: Cmd_HelpShow, Cmd_HelpSearch, &
       Cmd_HelpShow_In, Cmd_HelpShow_Out, &
       Cmd_HelpSearch_In, Cmd_HelpSearch_Out, &
       Cmd_HelpShow_Structured, Cmd_HelpSearch_Structured
  USE AP_InpScript_Valid,    only: Cmd_Valid, Cmd_FormatError, &
       Cmd_Valid_In, Cmd_Valid_Out, &
       Cmd_FormatError_In, Cmd_FormatError_Out, &
       Cmd_Valid_Structured, Cmd_FormatError_Structured
  USE AP_InpScript_Subst,    only: Cmd_Subst, Cmd_SetVar, Cmd_GetVar, &
       Cmd_Subst_In, Cmd_Subst_Out, &
       Cmd_SetVar_In, Cmd_SetVar_Out, &
       Cmd_GetVar_In, Cmd_GetVar_Out, &
       Cmd_Subst_Structured, Cmd_SetVar_Structured, Cmd_GetVar_Structured
  USE AP_InpScript_Parser,   only: CmdParser, g_parser, &
       Cmd_ParseLine, Cmd_ParseFile, Cmd_ParseString, Cmd_ExpandMacros, &
       Cmd_ParseLine_In, Cmd_ParseLine_Out, &
       Cmd_ParseFile_In, Cmd_ParseFile_Out, &
       Cmd_ParseString_In, Cmd_ParseString_Out, &
       Cmd_ParseLine_Structured, Cmd_ParseFile_Structured, Cmd_ParseString_Structured, &
       Cmd_ParseKeyValue, Cmd_ParseArray
  USE AP_InpScript_Reg, only: CmdReg, &
       Cmd_Init, Cmd_Reg, Cmd_Find, Cmd_RegisterDesc, &
       Cmd_Init_In, Cmd_Init_Out, &
       Cmd_Reg_In, Cmd_Reg_Out, &
       Cmd_Find_In, Cmd_Find_Out, &
       Cmd_RegisterDesc_In, Cmd_RegisterDesc_Out, &
       Cmd_Init_Structured, Cmd_Reg_Structured, Cmd_Find_Structured, &
       Cmd_RegisterDesc_Structured
  USE AP_InpScript_Executor, only: CmdExec, &
       Cmd_ExecList, Cmd_InitStacks, CmdList_GetCmd, EvaluateCondition

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_IO_ERROR, IF_STATUS_ERROR
  USE IF_Prec_Core,    only: i4, wp

  implicit none
  private

  !===============================================================================
  ! Public Interface - re-export everything from sub-modules
  !===============================================================================
  ! Parser
  public :: CmdParser
  public :: Cmd_ParseLine,  Cmd_ParseFile,  Cmd_ParseString
  public :: Cmd_ParseLine_In, Cmd_ParseLine_Out
  public :: Cmd_ParseFile_In, Cmd_ParseFile_Out
  public :: Cmd_ParseString_In, Cmd_ParseString_Out
  public :: Cmd_ParseLine_Structured, Cmd_ParseFile_Structured, Cmd_ParseString_Structured
  public :: Cmd_ExpandMacros
  public :: Cmd_ParseKeyValue, Cmd_ParseArray

  ! Registry
  public :: CmdReg
  public :: Cmd_Init,  Cmd_Reg,  Cmd_Find,  Cmd_RegisterDesc
  public :: Cmd_Init_In, Cmd_Init_Out
  public :: Cmd_Reg_In,  Cmd_Reg_Out
  public :: Cmd_Find_In, Cmd_Find_Out
  public :: Cmd_RegisterDesc_In, Cmd_RegisterDesc_Out
  public :: Cmd_Init_Structured, Cmd_Reg_Structured, Cmd_Find_Structured
  public :: Cmd_RegisterDesc_Structured
  public :: Cmd_Exec

  ! Executor
  public :: CmdExec
  public :: Cmd_ExecList, Cmd_InitStacks, CmdList_GetCmd

  ! Parameter Substitution
  public :: Cmd_Subst, Cmd_SetVar, Cmd_GetVar
  public :: Cmd_Subst_In, Cmd_Subst_Out
  public :: Cmd_SetVar_In, Cmd_SetVar_Out
  public :: Cmd_GetVar_In, Cmd_GetVar_Out
  public :: Cmd_Subst_Structured, Cmd_SetVar_Structured, Cmd_GetVar_Structured

  ! Validator
  public :: Cmd_Valid, Cmd_FormatError
  public :: Cmd_Valid_In, Cmd_Valid_Out
  public :: Cmd_FormatError_In, Cmd_FormatError_Out
  public :: Cmd_Valid_Structured, Cmd_FormatError_Structured

  ! History
  public :: CmdHistory
  public :: Cmd_HistoryInit, Cmd_HistoryAdd, Cmd_HistoryAddEntry
  public :: Cmd_HistoryGet,  Cmd_HistoryClear
  public :: Cmd_HistoryAdd_In, Cmd_HistoryAdd_Out
  public :: Cmd_HistoryGet_In, Cmd_HistoryGet_Out
  public :: Cmd_HistoryClear_Out
  public :: Cmd_HistoryInit_In, Cmd_HistoryInit_Out
  public :: g_cmd_domain

  ! Help
  public :: Cmd_HelpShow, Cmd_HelpSearch
  public :: Cmd_HelpShow_In, Cmd_HelpShow_Out
  public :: Cmd_HelpSearch_In, Cmd_HelpSearch_Out
  public :: Cmd_HelpShow_Structured, Cmd_HelpSearch_Structured

  ! Debug
  public :: CmdDebugger, Cmd_DebugSetBrk, Cmd_DebugShowVars

  ! Logger
  public :: CmdLogger, Cmd_Log, Cmd_LogError, Cmd_SetLogLevel
  public :: LOG_NONE, LOG_ERROR, LOG_WARN, LOG_INFO, LOG_DEBUG, LOG_TRACE

  ! Alias
  public :: CmdAliasMgr, Cmd_AliasDefine, Cmd_AliasResolve

  ! Label
  public :: CmdLabelMgr, Cmd_LabelRegister, Cmd_LabelResolve
  public :: g_label_mgr

  !===============================================================================
  ! History I/O types (defined locally - History module only exposes CmdHistory)
  !===============================================================================
  type, public :: Cmd_HistoryAdd_In
    type(Cmd)                   :: cmd
    character(len=256), optional :: source
  end type Cmd_HistoryAdd_In
  type, public :: Cmd_HistoryAdd_Out
    type(ErrorStatusType) :: status
  end type Cmd_HistoryAdd_Out

  type, public :: Cmd_HistoryGet_In
    integer(i4) :: index
  end type Cmd_HistoryGet_In
  type, public :: Cmd_HistoryGet_Out
    type(Cmd) :: cmd
    type(ErrorStatusType) :: status
  end type Cmd_HistoryGet_Out

  type, public :: Cmd_HistoryClear_Out
    type(ErrorStatusType) :: status
  end type Cmd_HistoryClear_Out

  type, public :: Cmd_HistoryInit_In
    integer(i4), optional :: max_entries
  end type Cmd_HistoryInit_In
  type, public :: Cmd_HistoryInit_Out
    type(ErrorStatusType) :: status
  end type Cmd_HistoryInit_Out

  ! Cmd_LabelRegister / Cmd_LabelResolve I/O types
  type, public :: Cmd_LabelRegister_In
    type(CmdList) :: cmd_list
  end type Cmd_LabelRegister_In
  type, public :: Cmd_LabelRegister_Out
    type(ErrorStatusType) :: status
  end type Cmd_LabelRegister_Out
  type, public :: Cmd_LabelResolve_In
    character(len=32) :: name
  end type Cmd_LabelResolve_In
  type, public :: Cmd_LabelResolve_Out
    integer(i4) :: idx
    type(ErrorStatusType) :: status
  end type Cmd_LabelResolve_Out

  ! Cmd_Exec I/O types
  type, public :: Cmd_Exec_In
    type(Cmd) :: cmd
  end type Cmd_Exec_In
  type, public :: Cmd_Exec_Out
    type(ErrorStatusType) :: status
  end type Cmd_Exec_Out

  !===============================================================================
  ! Global Instances (index tree + flat domain, Phase C)
  !===============================================================================
  TYPE(AP_Cmd_Domain), SAVE :: g_cmd_domain
  ! g_parser      from AP_InpScriptParser
  ! g_debugger    from AP_InpScriptDebug
  ! g_logger      from AP_InpScriptLogger
  ! g_alias_mgr   from AP_InpScriptAlias
  ! g_label_mgr   from AP_InpScriptLabel

contains

  !===============================================================================
  ! Facade - Cmd_Exec: single-command dispatch via g_cmd_domain
  !===============================================================================
  !> @deprecated Use AP_InpScriptExecutor::Cmd_ExecList for list execution
  subroutine Cmd_Exec(cmd, ctx, status)
    type(Cmd),    intent(in)    :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status

    type(CmdHandler) :: h
    type(Cmd)        :: resolved_cmd
    logical          :: alias_found

    call init_error_status(status)
    call g_alias_mgr%Resolve(cmd%name, resolved_cmd, alias_found, status)
    if (alias_found) then
      resolved_cmd%line = cmd%line
      if (len_trim(cmd%opt) > 0) resolved_cmd%opt = cmd%opt
      if (any(abs(cmd%params) > 1.0e-30_wp)) resolved_cmd%params = cmd%params
      if (len_trim(cmd%param_str) > 0) resolved_cmd%param_str = cmd%param_str
    else
      resolved_cmd = cmd
    end if
    call g_cmd_domain%GetHandlerByName(resolved_cmd%name, h, alias_found)
    if (.not. alias_found) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A,A,A)') 'Unknown command: "', trim(resolved_cmd%name), '"'
      return
    end if
    call h%handler(resolved_cmd, ctx, status)
  end subroutine Cmd_Exec

  !===============================================================================
  ! History facade delegates to g_cmd_domain
  !===============================================================================
  subroutine Cmd_HistoryInit(max_entries, status)
    integer(i4), intent(in), optional  :: max_entries
    type(ErrorStatusType), intent(out), optional :: status
    if (present(status)) call init_error_status(status)
    ! History lives in g_cmd_domain; Init already done by Cmd_Init
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine Cmd_HistoryInit

  subroutine Cmd_HistoryAdd(cmd, source, status)
    type(Cmd), intent(in) :: cmd
    character(len=*), intent(in), optional :: source
    type(ErrorStatusType), intent(out), optional :: status
    character(len=64) :: src
    type(ErrorStatusType) :: st
    call init_error_status(st)
    src = 'interactive'
    if (present(source)) src = source
    call g_cmd_domain%AddHistory(cmd, src, status=st)
    if (present(status)) status = st
  end subroutine Cmd_HistoryAdd

  subroutine Cmd_HistoryAddEntry(entry, status)
    type(CommandLogEntry), intent(in) :: entry
    type(ErrorStatusType), intent(out), optional :: status
    call Cmd_HistoryAdd(entry%cmd, entry%source, status)
  end subroutine Cmd_HistoryAddEntry

  subroutine Cmd_HistoryGet(index, cmd, status)
    integer(i4), intent(in) :: index
    type(Cmd),   intent(out) :: cmd
    type(ErrorStatusType), intent(out), optional :: status
    type(HistoryEntry) :: entry
    logical            :: found
    type(ErrorStatusType) :: st
    call init_error_status(st)
    call g_cmd_domain%GetHistoryById(index, entry, found)
    if (.not. found) then
      st%status_code = IF_STATUS_INVALID
      write(st%message, '(A,I0,A,I0)') 'History index ', index, &
        ' out of range [1,', g_cmd_domain%n_history, ']'
    else
      cmd = entry%cmd
      st%status_code = IF_STATUS_OK
    end if
    if (present(status)) status = st
  end subroutine Cmd_HistoryGet

  subroutine Cmd_HistoryClear(status)
    type(ErrorStatusType), intent(out), optional :: status
    call g_cmd_domain%ClearHistory()
    if (present(status)) then
      call init_error_status(status)
      status%status_code = IF_STATUS_OK
    end if
  end subroutine Cmd_HistoryClear

  !===============================================================================
  ! Label facade delegates to g_label_mgr
  !===============================================================================
  subroutine Cmd_LabelRegister(cmd_list, status)
    type(CmdList), intent(in) :: cmd_list
    type(ErrorStatusType), intent(out), optional :: status
    type(ErrorStatusType) :: st
    call init_error_status(st)
    ! Note: CmdList_GetCmd from AP_InpScriptExecutor requires domain argument;
    ! Pass a lambda or use the g_cmd_domain inline callback here.
    call g_label_mgr%Reg(cmd_list, st, LabelGetCmd)
    if (present(status)) status = st
  end subroutine Cmd_LabelRegister

  function Cmd_LabelResolve(name) result(idx)
    character(len=*), intent(in) :: name
    integer(i4) :: idx
    idx = g_label_mgr%Resolve(name)
  end function Cmd_LabelResolve

  ! Internal callback used by Cmd_LabelRegister
  subroutine LabelGetCmd(cmd_list, i, cmd, found)
    type(CmdList), intent(in)  :: cmd_list
    integer(i4),   intent(in)  :: i
    type(Cmd),     intent(out) :: cmd
    logical,       intent(out) :: found
    integer(i4) :: cid
    found = .false.
    if (i < 1 .or. i > cmd_list%num_cmds) return
    if (.not. allocated(cmd_list%cmd_ids)) return
    if (i > size(cmd_list%cmd_ids)) return
    cid = cmd_list%cmd_ids(i)
    call g_cmd_domain%GetCommandById(cid, cmd, found)
  end subroutine LabelGetCmd

  ! Procedure delegation - from AP_Cmd_Proc
  ! Cmd_ProcDefine, Cmd_ProcLoad, Cmd_ProcSave, Cmd_ProcExec - see AP_Cmd_Proc

end module AP_Inp_Script