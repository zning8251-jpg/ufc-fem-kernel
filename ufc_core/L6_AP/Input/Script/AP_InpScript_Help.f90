!===============================================================================
! MODULE: AP_InpScript_Help
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl — command help display and search
! BRIEF:  Command help display and search functionality.
!
! Process phases:
!   P3: Cmd_HelpShow / Cmd_HelpSearch
!===============================================================================

module AP_InpScript_Help
  USE AP_Inp_Def,    only: Cmd, CommandDesc
  USE AP_Inp_Domain,  only: AP_Cmd_Domain
  USE IF_Err_Brg,         only: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core,            only: i4, wp

  implicit none
  private

  !===============================================================================
  ! I/O Types
  !===============================================================================
  type, public :: Cmd_HelpShow_In
    character(len=16), optional :: cmd_name  ! Command name (optional, shows all if absent)
  end type Cmd_HelpShow_In

  type, public :: Cmd_HelpShow_Out
    type(ErrorStatusType) :: status
  end type Cmd_HelpShow_Out

  type, public :: Cmd_HelpSearch_In
    character(len=64) :: keyword  ! Search keyword
  end type Cmd_HelpSearch_In

  type, public :: Cmd_HelpSearch_Out
    type(ErrorStatusType) :: status
  end type Cmd_HelpSearch_Out

  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: Cmd_HelpShow
  public :: Cmd_HelpSearch
  public :: Cmd_HelpShow_Structured
  public :: Cmd_HelpSearch_Structured

contains

  !===============================================================================
  ! Cmd_HelpShow_Structured
  !===============================================================================
  subroutine Cmd_HelpShow_Structured(domain, in, out)
    !! Show command help
    !!
    !! Theory:
    !!   Shows help information for a command or all commands.
    !!   Process: HelpShow(cmd_name) -> help_text, where cmd_name = {string|optional}
    !!
    !! Input:
    !!   domain: Command domain (in, for registered descriptions)
    !!   in%cmd_name: Command name (optional, shows all if not present)
    !!
    !! Output:
    !!   out%status: Error status

    type(AP_Cmd_Domain), intent(in)    :: domain
    type(Cmd_HelpShow_In),  intent(in)    :: in
    type(Cmd_HelpShow_Out), intent(out)   :: out

    call init_error_status(out%status)
    ! TODO: Implement actual help display logic using domain%GetHandlerByName
    out%status%status_code = IF_STATUS_OK
  end subroutine Cmd_HelpShow_Structured

  !===============================================================================
  ! Cmd_HelpSearch_Structured
  !===============================================================================
  subroutine Cmd_HelpSearch_Structured(domain, in, out)
    !! Search command help
    !!
    !! Theory:
    !!   Searches command help descriptions by keyword.
    !!   Process: HelpSearch(keyword) -> results, where keyword = {string}
    !!
    !! Input:
    !!   domain: Command domain (in)
    !!   in%keyword: Search keyword
    !!
    !! Output:
    !!   out%status: Error status

    type(AP_Cmd_Domain), intent(in)      :: domain
    type(Cmd_HelpSearch_In),  intent(in)    :: in
    type(Cmd_HelpSearch_Out), intent(out)   :: out

    call init_error_status(out%status)
    ! TODO: Implement actual help search logic using domain handler descriptions
    out%status%status_code = IF_STATUS_OK
  end subroutine Cmd_HelpSearch_Structured

  !===============================================================================
  ! Legacy wrappers (@deprecated)
  !===============================================================================
  !> @deprecated Use Cmd_HelpShow_Structured instead
  subroutine Cmd_HelpShow(cmd_name, status)
    character(len=*), intent(in), optional  :: cmd_name
    type(ErrorStatusType), intent(out), optional :: status

    type(AP_Cmd_Domain) :: dummy_domain
    type(Cmd_HelpShow_In)  :: in
    type(Cmd_HelpShow_Out) :: out

    if (present(cmd_name)) in%cmd_name = cmd_name
    call Cmd_HelpShow_Structured(dummy_domain, in, out)
    if (present(status)) status = out%status
  end subroutine Cmd_HelpShow

  !> @deprecated Use Cmd_HelpSearch_Structured instead
  subroutine Cmd_HelpSearch(keyword, status)
    character(len=*), intent(in)                 :: keyword
    type(ErrorStatusType), intent(out), optional :: status

    type(AP_Cmd_Domain) :: dummy_domain
    type(Cmd_HelpSearch_In)  :: in
    type(Cmd_HelpSearch_Out) :: out

    in%keyword = keyword
    call Cmd_HelpSearch_Structured(dummy_domain, in, out)
    if (present(status)) status = out%status
  end subroutine Cmd_HelpSearch

end module AP_InpScript_Help