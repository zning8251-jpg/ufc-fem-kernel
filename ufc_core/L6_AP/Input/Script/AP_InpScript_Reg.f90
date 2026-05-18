!===============================================================================
! MODULE: AP_InpScript_Reg
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl ?command registry
! BRIEF:  Command registry - register, find, and dispatch command handlers.
!
! Process phases:
!   P0: Cmd_Reg / Cmd_RegHandler
!   P2: Cmd_Dispatch / Cmd_Find
!===============================================================================

module AP_InpScript_Reg
  USE AP_Inp_Def,   only: Cmd, CmdCtx, CmdHandler, CommandDesc, CmdHandlerProc
  USE AP_Inp_Domain, only: AP_Cmd_Domain
  USE AP_InpScript_Alias, only: CmdAliasMgr
  USE IF_Err_Brg,        only: ErrorStatusType, init_error_status, &
                               IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core,           only: i4, wp

  implicit none
  private

  !===============================================================================
  ! Constants
  !===============================================================================
  integer(i4), parameter :: MAX_REGISTRY = 200

  !===============================================================================
  ! CmdReg type - legacy registry context (thin wrapper over AP_Cmd_Domain)
  !===============================================================================
  TYPE, public :: CmdReg
    TYPE(CmdHandler), ALLOCATABLE :: handlers(:)
    INTEGER(i4) :: num_cmds = 0
    INTEGER(i4) :: max_cmds = MAX_REGISTRY
    INTEGER(i4) :: next_id  = 1
    LOGICAL     :: init     = .false.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reg
    PROCEDURE :: Find
    PROCEDURE :: Exec
  END TYPE CmdReg

  !===============================================================================
  ! I/O Types
  !===============================================================================
  type, public :: Cmd_Init_In
    integer(i4), optional :: max_commands
  end type Cmd_Init_In

  type, public :: Cmd_Init_Out
    type(ErrorStatusType) :: status
  end type Cmd_Init_Out

  type, public :: Cmd_Reg_In
    character(len=16) :: name
    procedure(CmdHandlerProc), pointer :: handler
    character(len=128), optional :: description
  end type Cmd_Reg_In

  type, public :: Cmd_Reg_Out
    type(ErrorStatusType) :: status
  end type Cmd_Reg_Out

  type, public :: Cmd_Find_In
    character(len=16) :: name
  end type Cmd_Find_In

  type, public :: Cmd_Find_Out
    integer(i4) :: idx
    type(ErrorStatusType) :: status
  end type Cmd_Find_Out

  type, public :: Cmd_RegisterDesc_In
    type(CommandDesc) :: desc
    procedure(CmdHandlerProc), pointer :: handler
  end type Cmd_RegisterDesc_In

  type, public :: Cmd_RegisterDesc_Out
    type(ErrorStatusType) :: status
  end type Cmd_RegisterDesc_Out

  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: Cmd_Init
  public :: Cmd_Reg
  public :: Cmd_Find
  public :: Cmd_RegisterDesc
  public :: Cmd_Init_Structured
  public :: Cmd_Reg_Structured
  public :: Cmd_Find_Structured
  public :: Cmd_RegisterDesc_Structured

contains

  !===============================================================================
  ! Cmd_Init_Structured
  !===============================================================================
  subroutine Cmd_Init_Structured(domain, in, out)
    !! Initialize command registry (via domain)

    type(AP_Cmd_Domain), intent(inout) :: domain
    type(Cmd_Init_In),   intent(in)   :: in
    type(Cmd_Init_Out),  intent(out)  :: out

    call init_error_status(out%status)
    call domain%Init(out%status)
  end subroutine Cmd_Init_Structured

  !===============================================================================
  ! Cmd_Reg_Structured
  !===============================================================================
  subroutine Cmd_Reg_Structured(domain, in, out)
    !! Register command handler

    type(AP_Cmd_Domain), intent(inout) :: domain
    type(Cmd_Reg_In),    intent(in)   :: in
    type(Cmd_Reg_Out),   intent(out)  :: out

    type(CmdHandler) :: h
    integer(i4)      :: hid

    call init_error_status(out%status)
    h%name    = in%name
    h%handler => in%handler
    h%desc    = 'No description'
    if (len_trim(in%cfg%description) > 0) h%desc = in%cfg%description
    call domain%AddHandler(h, hid, out%status)
  end subroutine Cmd_Reg_Structured

  !===============================================================================
  ! Cmd_Find_Structured
  !===============================================================================
  subroutine Cmd_Find_Structured(domain, in, out)
    !! Find command by name, return handler index

    type(AP_Cmd_Domain), intent(in)   :: domain
    type(Cmd_Find_In),   intent(in)   :: in
    type(Cmd_Find_Out),  intent(out)  :: out

    logical :: found

    call init_error_status(out%status)
    call domain%GetHandlerIndexByName(in%name, out%idx, found)
    if (.not. found) out%idx = 0
    out%status%status_code = IF_STATUS_OK
  end subroutine Cmd_Find_Structured

  !===============================================================================
  ! Cmd_RegisterDesc_Structured
  !===============================================================================
  subroutine Cmd_RegisterDesc_Structured(domain, in, out)
    !! Register command with full CommandDesc

    type(AP_Cmd_Domain),       intent(inout) :: domain
    type(Cmd_RegisterDesc_In), intent(in)   :: in
    type(Cmd_RegisterDesc_Out), intent(out) :: out

    type(Cmd_Reg_In)  :: reg_in
    type(Cmd_Reg_Out) :: reg_out

    call init_error_status(out%status)
    reg_in%name        = in%desc%name
    reg_in%handler    => in%handler
    reg_in%cfg%description = in%desc%cfg%description
    call Cmd_Reg_Structured(domain, reg_in, reg_out)
    out%status = reg_out%status
  end subroutine Cmd_RegisterDesc_Structured

  !===============================================================================
  ! CmdReg bound methods (legacy internal registry, not domain-based)
  !===============================================================================
  subroutine Reg_Init(this, max_commands, status)
    class(CmdReg), intent(inout) :: this
    integer(i4),   intent(in), optional :: max_commands
    type(ErrorStatusType), intent(out), optional :: status

    integer(i4) :: max_cmd, ios

    if (present(status)) call init_error_status(status)
    max_cmd = MAX_REGISTRY
    if (present(max_commands)) max_cmd = max_commands

    if (allocated(this%handlers)) deallocate(this%handlers)
    allocate(this%handlers(max_cmd), stat=ios)
    if (ios /= 0) then
      if (present(status)) then
        status%status_code = IF_STATUS_ERROR
        write(status%message, '(A,I0,A)') 'Failed to allocate handlers (size=', max_cmd, ')'
      end if
      return
    end if
    this%max_cmds = max_cmd
    this%num_cmds = 0
    this%next_id  = 1
    this%init     = .true.
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine Reg_Init

  subroutine Reg_Reg(this, name, handler, description, status)
    class(CmdReg), intent(inout) :: this
    character(len=*), intent(in) :: name
    procedure(CmdHandlerProc)    :: handler
    character(len=*), intent(in), optional :: description
    type(ErrorStatusType), intent(out), optional :: status

    integer(i4) :: i, idx
    character(len=16) :: cmd_name

    if (present(status)) call init_error_status(status)
    if (.not. this%init) then
      call this%Init(status=status)
      if (present(status) .and. status%status_code /= IF_STATUS_OK) return
    end if

    idx = this%Find(name)
    if (idx > 0) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        write(status%message, '(A,A,A)') 'Command "', trim(name), '" already registered'
      end if
      return
    end if

    idx = 0
    do i = 1, this%num_cmds
      if (.not. this%handlers(i)%registered) then
        idx = i
        exit
      end if
    end do

    if (idx == 0) then
      if (this%num_cmds >= this%max_cmds) then
        if (present(status)) then
          status%status_code = IF_STATUS_INVALID
          write(status%message, '(A,I0,A)') 'Maximum commands (', this%max_cmds, ') reached'
        end if
        return
      end if
      this%num_cmds = this%num_cmds + 1
      idx = this%num_cmds
    end if

    cmd_name = name
    this%handlers(idx)%name    = cmd_name
    this%handlers(idx)%handler => handler
    this%handlers(idx)%cfg%id      = this%next_id
    this%next_id               = this%next_id + 1
    if (present(description)) then
      this%handlers(idx)%desc  = description
    else
      this%handlers(idx)%desc  = 'No description'
    end if
    this%handlers(idx)%registered = .true.
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine Reg_Reg

  function Reg_Find(this, name) result(idx)
    class(CmdReg), intent(in) :: this
    character(len=*), intent(in) :: name
    integer(i4) :: idx
    integer(i4) :: i
    character(len=16) :: cmd_name, reg_name

    idx      = 0
    cmd_name = name
    do i = 1, this%num_cmds
      if (this%handlers(i)%registered) then
        reg_name = this%handlers(i)%name
        if (cmd_name == reg_name) then
          idx = i
          return
        end if
      end if
    end do
  end function Reg_Find

  subroutine Reg_Exec(this, cmd, ctx, alias_mgr, status)
    class(CmdReg),   intent(in)    :: this
    type(Cmd),       intent(in)    :: cmd
    type(CmdCtx),    intent(inout) :: ctx
    type(CmdAliasMgr), intent(inout) :: alias_mgr
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: idx
    type(Cmd)   :: resolved_cmd
    logical     :: alias_found

    call init_error_status(status)

    call alias_mgr%Resolve(cmd%name, resolved_cmd, alias_found, status)
    if (alias_found) then
      resolved_cmd%line = cmd%line
      if (len_trim(cmd%opt) > 0) resolved_cmd%opt = cmd%opt
      if (any(abs(cmd%params) > 1.0e-30_wp)) resolved_cmd%params = cmd%params
      if (len_trim(cmd%param_str) > 0) resolved_cmd%param_str = cmd%param_str
    else
      resolved_cmd = cmd
    end if

    idx = this%Find(resolved_cmd%name)
    if (idx == 0) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A,A,A)') 'Unknown command: "', trim(resolved_cmd%name), '"'
      return
    end if
    call this%handlers(idx)%handler(resolved_cmd, ctx, status)
  end subroutine Reg_Exec

  !===============================================================================
  ! Legacy wrappers (@deprecated)
  !===============================================================================
  !> @deprecated Use Cmd_Init_Structured instead
  subroutine Cmd_Init(domain, max_commands, status)
    type(AP_Cmd_Domain), intent(inout) :: domain
    integer(i4), intent(in), optional  :: max_commands
    type(ErrorStatusType), intent(out), optional :: status
    type(Cmd_Init_In)  :: in
    type(Cmd_Init_Out) :: out
    if (present(max_commands)) in%max_commands = max_commands
    call Cmd_Init_Structured(domain, in, out)
    if (present(status)) status = out%status
  end subroutine Cmd_Init

  !> @deprecated Use Cmd_Reg_Structured instead
  subroutine Cmd_Reg(domain, name, handler, description, status)
    type(AP_Cmd_Domain), intent(inout) :: domain
    character(len=*),   intent(in)    :: name
    procedure(CmdHandlerProc)          :: handler
    character(len=*), intent(in), optional :: description
    type(ErrorStatusType), intent(out), optional :: status
    type(Cmd_Reg_In)  :: in
    type(Cmd_Reg_Out) :: out
    in%name     = name
    in%handler => handler
    if (present(description)) in%cfg%description = description
    call Cmd_Reg_Structured(domain, in, out)
    if (present(status)) status = out%status
  end subroutine Cmd_Reg

  !> @deprecated Use Cmd_Find_Structured instead
  function Cmd_Find(domain, name) result(idx)
    type(AP_Cmd_Domain), intent(in) :: domain
    character(len=*),    intent(in) :: name
    integer(i4) :: idx
    type(Cmd_Find_In)  :: in
    type(Cmd_Find_Out) :: out
    in%name = name
    call Cmd_Find_Structured(domain, in, out)
    idx = out%idx
  end function Cmd_Find

  !> @deprecated Use Cmd_RegisterDesc_Structured instead
  subroutine Cmd_RegisterDesc(domain, desc, handler, status)
    type(AP_Cmd_Domain), intent(inout) :: domain
    type(CommandDesc),   intent(in)   :: desc
    procedure(CmdHandlerProc)          :: handler
    type(ErrorStatusType), intent(out), optional :: status
    type(Cmd_RegisterDesc_In)  :: in
    type(Cmd_RegisterDesc_Out) :: out
    in%desc    = desc
    in%handler => handler
    call Cmd_RegisterDesc_Structured(domain, in, out)
    if (present(status)) status = out%status
  end subroutine Cmd_RegisterDesc

end module AP_InpScript_Reg