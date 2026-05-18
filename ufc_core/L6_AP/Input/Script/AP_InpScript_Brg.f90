!===============================================================================
! MODULE: AP_InpScript_Brg
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Brg — main API interface for UFC command system
! BRIEF:  Main API interface for UFC Command System.
!===============================================================================

module AP_InpScript_Brg
!> Theory: Command parsing and execution API | Ref: UFC Command Interface
  USE AP_Inp_Script, only: Cmd_Init, Cmd_ParseFile, Cmd_ParseString, &
                          Cmd_ExecList, Cmd_InitStacks, &
                          Cmd_HistoryInit, Cmd_LabelRegister, &
                          g_cmd_domain, g_debugger, g_alias_mgr, g_logger, g_label_mgr
  USE AP_Inp_Def, only: Cmd, CmdCtx, CmdList
  USE AP_InpScript_UFC, only: UF_Cmd_UFC_RegAll
  
  implicit none
  private
  
  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: UF_Cmd_Init
  public :: UF_Cmd_ExecFile
  public :: UF_Cmd_ExecString
  public :: UF_Cmd_SetCtx
  public :: UF_Cmd_GetCtx
  
  ! Backward compatibility (now delegates directly to CmdCtx-based API)
  public :: UF_CmdSys_Init
  public :: UF_CmdSys_ExecFile
  public :: UF_CmdSys_ExecStr
  public :: UF_CmdSys_SetCtx
  public :: UF_CmdSys_GetCtx
  ! Extended API (task13100-13199)
  public :: AP_Cmd_Unified_Execute
  public :: AP_Cmd_Unified_Cfg
  ! Application facade (task13900-13999)
  public :: AP_App_Unified_Run
  public :: AP_App_Unified_Cfg
  
  !===============================================================================
  ! Global Context
  !===============================================================================
  TYPE(CmdCtx), SAVE :: g_ctx
  ! [REMOVED] g_context (UF_CommandCtx) — migrated to CmdCtx
  
contains
  
  !===============================================================================
  ! Init Command System
  !===============================================================================
  subroutine UF_Cmd_Init(ctx, status)
    type(CmdCtx), intent(in), optional :: ctx
    type(ErrorStatusType), intent(out), optional :: status
    
    type(ErrorStatusType) :: local_status
    
    ! Init registry
    call Cmd_Init(status=local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg UFC commands
    call UF_Cmd_UFC_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Init history
    call Cmd_HistoryInit(status=local_status)
    
    ! Init label manager
    call g_label_mgr%Init(status=local_status)
    
    ! Init debugger (disabled by default)
    call g_debugger%Init(enabled=.false., verbose=.true., status=local_status)
    
    ! Init alias manager
    call g_alias_mgr%Init(status=local_status)
    
    ! Init logger
    call g_logger%Init(level=3, status=local_status)  ! LOG_INFO
    
    ! Set context
    if (present(ctx)) then
      g_ctx = ctx
    end if
    
    ! Init stacks
    call Cmd_InitStacks(g_ctx, local_status)
    
    if (present(status)) status = local_status
    
  end subroutine UF_Cmd_Init
  
  !===============================================================================
  ! Execute Command File
  !===============================================================================
  subroutine UF_Cmd_ExecFile(filename, ctx, status)
    character(len=*), intent(in) :: filename
    type(CmdCtx), intent(inout), optional :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(CmdList) :: cmd_list
    type(CmdCtx) :: exec_ctx
    
    call init_error_status(status)
    
    ! Parse file
    call Cmd_ParseFile(filename, cmd_list, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Reg labels
    call Cmd_LabelRegister(cmd_list, status)
    if (status%status_code /= IF_STATUS_OK) then
      ! Non-fatal - continue execution
      status%status_code = IF_STATUS_OK
    end if
    
    ! Set context
    if (present(ctx)) then
      exec_ctx = ctx
    else
      exec_ctx = g_ctx
    end if
    
    ! Init stacks
    call Cmd_InitStacks(exec_ctx, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Execute commands
    call Cmd_ExecList(cmd_list, exec_ctx, status)
    
    ! Update context
    if (present(ctx)) then
      ctx = exec_ctx
    else
      g_ctx = exec_ctx
    end if
    
    ! Cleanup
    if (allocated(cmd_list%cmd_ids)) deallocate(cmd_list%cmd_ids)
    
  end subroutine UF_Cmd_ExecFile
  
  !===============================================================================
  ! Execute Command String
  !===============================================================================
  subroutine UF_Cmd_ExecString(cmd_string, ctx, status)
    character(len=*), intent(in) :: cmd_string
    type(CmdCtx), intent(inout), optional :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(CmdList) :: cmd_list
    type(CmdCtx) :: exec_ctx
    
    call init_error_status(status)
    
    ! Parse string
    call Cmd_ParseString(cmd_string, cmd_list, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Reg labels
    call Cmd_LabelRegister(cmd_list, status)
    if (status%status_code /= IF_STATUS_OK) then
      ! Non-fatal - continue execution
      status%status_code = IF_STATUS_OK
    end if
    
    ! Set context
    if (present(ctx)) then
      exec_ctx = ctx
    else
      exec_ctx = g_ctx
    end if
    
    ! Init stacks
    call Cmd_InitStacks(exec_ctx, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    ! Execute commands
    call Cmd_ExecList(cmd_list, exec_ctx, status)
    
    ! Update context
    if (present(ctx)) then
      ctx = exec_ctx
    else
      g_ctx = exec_ctx
    end if
    
    ! Cleanup
    if (allocated(cmd_list%cmd_ids)) deallocate(cmd_list%cmd_ids)
    
  end subroutine UF_Cmd_ExecString
  
  !===============================================================================
  ! Set Context
  !===============================================================================
  subroutine UF_Cmd_SetCtx(ctx, status)
    type(CmdCtx), intent(in) :: ctx
    type(ErrorStatusType), intent(out), optional :: status
    
    g_ctx = ctx
    if (present(status)) call init_error_status(status)
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine UF_Cmd_SetCtx
  
  !===============================================================================
  ! Get Context
  !===============================================================================
  subroutine UF_Cmd_GetCtx(ctx, status)
    type(CmdCtx), intent(out) :: ctx
    type(ErrorStatusType), intent(out), optional :: status
    
    ctx = g_ctx
    if (present(status)) call init_error_status(status)
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine UF_Cmd_GetCtx
  
  !===============================================================================
  ! Backward Compatibility Interface (simplified: UF_CommandCtx → CmdCtx)
  !===============================================================================
  
  !===============================================================================
  ! Init Command System (Backward Compatibility)
  !===============================================================================
  subroutine UF_CmdSys_Init(ctx, status)
    type(CmdCtx), intent(in), optional :: ctx
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(ctx)) then
      call UF_Cmd_Init(ctx, status)
    else
      call UF_Cmd_Init(status=status)
    end if
    
  end subroutine UF_CmdSys_Init
  
  !===============================================================================
  ! Execute Command File (Backward Compatibility)
  !===============================================================================
  subroutine UF_CmdSys_ExecFile(filename, ctx, status)
    character(len=*), intent(in) :: filename
    type(CmdCtx), intent(inout), optional :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call UF_Cmd_ExecFile(filename, ctx, status)
    
  end subroutine UF_CmdSys_ExecFile
  
  !===============================================================================
  ! Execute Command String (Backward Compatibility)
  !===============================================================================
  subroutine UF_CmdSys_ExecStr(cmd_string, ctx, status)
    character(len=*), intent(in) :: cmd_string
    type(CmdCtx), intent(inout), optional :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call UF_Cmd_ExecString(cmd_string, ctx, status)
    
  end subroutine UF_CmdSys_ExecStr
  
  !===============================================================================
  ! Set Context (Backward Compatibility)
  !===============================================================================
  subroutine UF_CmdSys_SetCtx(ctx, status)
    type(CmdCtx), intent(in) :: ctx
    type(ErrorStatusType), intent(out), optional :: status
    
    call UF_Cmd_SetCtx(ctx, status)
    
  end subroutine UF_CmdSys_SetCtx
  
  !===============================================================================
  ! Get Context (Backward Compatibility)
  !===============================================================================
  subroutine UF_CmdSys_GetCtx(ctx)
    type(CmdCtx), intent(out) :: ctx
    
    type(ErrorStatusType) :: status
    
    call UF_Cmd_GetCtx(ctx, status)
    
  end subroutine UF_CmdSys_GetCtx

  !=============================================================================
  ! Extended Command API (task13100-13199)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! task13100-13149?
  !-----------------------------------------------------------------------------
  subroutine AP_Cmd_Unified_Execute(source_type, source, ctx, status)
    !! Unified command execution interface
    !!  
    !!
    !! Input:
    !!   source_type - 'file' or 'string'
    !!   source      - File path or command string
    !!   ctx         - Optional context
    !!
    !! Output:
    !!   status      - Error status
    !!
    !! Task: 13100-13149
    character(len=*), intent(in) :: source_type
    character(len=*), intent(in) :: source
    type(CmdCtx), intent(inout), optional :: ctx
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (present(ctx)) call UF_Cmd_SetCtx(ctx, local_status)

    select case (trim(source_type))
    case ('file', 'FILE', 'File')
      call UF_Cmd_ExecFile(trim(source), ctx=ctx, status=local_status)
    case ('string', 'STRING', 'String', 'str')
      call UF_Cmd_ExecString(trim(source), ctx=ctx, status=local_status)
    case default
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'AP_Cmd_Unified_Execute: source_type must be "file" or "string"'
    end select

    if (present(status)) status = local_status

  end subroutine AP_Cmd_Unified_Execute

  !-----------------------------------------------------------------------------
  ! task13150-13199?
  !-----------------------------------------------------------------------------
  subroutine AP_Cmd_Unified_Cfg(operation, ctx, status)
    !! Unified command system configuration interface
    !!  
    !!
    !! Input:
    !!   operation - 'init', 'set_context', 'get_context'
    !!   ctx       - Context (for set_context)
    !!
    !! Output:
    !!   ctx       - Context (for get_context)
    !!   status    - Error status
    !!
    !! Task: 13150-13199
    character(len=*), intent(in) :: operation
    type(CmdCtx), intent(inout), optional :: ctx
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    select case (trim(operation))
    case ('init', 'INIT', 'Init')
      call UF_Cmd_Init(status=local_status)
    case ('set_context', 'SET_CONTEXT')
      if (present(ctx)) then
        call UF_Cmd_SetCtx(ctx, local_status)
      else
        local_status%status_code = IF_STATUS_INVALID
        local_status%message = 'AP_Cmd_Unified_Cfg: ctx required for set_context'
      end if
    case ('get_context', 'GET_CONTEXT')
      if (present(ctx)) then
        call UF_Cmd_GetCtx(ctx, local_status)
      else
        local_status%status_code = IF_STATUS_INVALID
        local_status%message = 'AP_Cmd_Unified_Cfg: ctx required for get_context'
      end if
    case default
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'AP_Cmd_Unified_Cfg: Unknown operation - ' // trim(operation)
    end select

    if (present(status)) status = local_status

  end subroutine AP_Cmd_Unified_Cfg

  !=============================================================================
  ! Application facade (task13900-13999)
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! task13900-13949?
  !-----------------------------------------------------------------------------
  subroutine AP_App_Unified_Run(operation, status, filename, cmd_string)
    !! Application-level unified run: INIT, EXEC_FILE, EXEC_STRING.
    !! Task: 13900-13949
    character(len=*), intent(in) :: operation
    type(ErrorStatusType), intent(out), optional :: status
    character(len=*), intent(in), optional :: filename
    character(len=*), intent(in), optional :: cmd_string

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    select case (trim(operation))
    case ('INIT', 'init', 'Init')
      call UF_Cmd_Init(status=local_status)
    case ('EXEC_FILE', 'exec_file', 'ExecFile')
      if (.not. present(filename)) then
        local_status%status_code = IF_STATUS_INVALID
        local_status%message = 'AP_App_Unified_Run: EXEC_FILE requires filename'
      else
        call UF_Cmd_ExecFile(trim(filename), status=local_status)
      end if
    case ('EXEC_STRING', 'exec_string', 'ExecString')
      if (.not. present(cmd_string)) then
        local_status%status_code = IF_STATUS_INVALID
        local_status%message = 'AP_App_Unified_Run: EXEC_STRING requires cmd_string'
      else
        call UF_Cmd_ExecString(trim(cmd_string), status=local_status)
      end if
    case default
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'AP_App_Unified_Run: unknown operation - ' // trim(operation)
    end select

    if (present(status)) status = local_status

  end subroutine AP_App_Unified_Run

  !-----------------------------------------------------------------------------
  ! task13950-13999?
  !-----------------------------------------------------------------------------
  subroutine AP_App_Unified_Cfg(operation, ctx, status)
    !! Application-level unified configure (delegate to command configure).
    !! Task: 13950-13999
    character(len=*), intent(in) :: operation
    type(CmdCtx), intent(inout), optional :: ctx
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)
    call AP_Cmd_Unified_Cfg(operation, ctx, local_status)
    if (present(status)) status = local_status

  end subroutine AP_App_Unified_Cfg
  
end module AP_InpScript_Brg