!===============================================================================
! MODULE: AP_InpScript_Valid
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl — command validation and error formatting
! BRIEF:  Command validation and error formatting.
!
! Process phases:
!   P0: Cmd_Validate / Cmd_FormatError
!===============================================================================

module AP_InpScript_Valid
  USE AP_Inp_Def, only: Cmd
  USE IF_Err_Brg,      only: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core,         only: i4, wp

  implicit none
  private

  !===============================================================================
  ! I/O Types
  !===============================================================================
  type, public :: Cmd_Valid_In
    type(Cmd) :: cmd    ! Command to validate
    type(*) :: spec     ! Validation specification (placeholder, assumed-shape)
  end type Cmd_Valid_In

  type, public :: Cmd_Valid_Out
    type(ErrorStatusType) :: status
  end type Cmd_Valid_Out

  type, public :: Cmd_FormatError_In
    type(Cmd) :: cmd                      ! Command that caused error
    character(len=256) :: base_message    ! Base error message
  end type Cmd_FormatError_In

  type, public :: Cmd_FormatError_Out
    character(len=512) :: formatted_message  ! Formatted error message
  end type Cmd_FormatError_Out

  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: Cmd_Valid
  public :: Cmd_FormatError
  public :: Cmd_Valid_Structured
  public :: Cmd_FormatError_Structured

contains

  !===============================================================================
  ! Cmd_Valid_Structured
  !===============================================================================
  subroutine Cmd_Valid_Structured(in, out)
    !! Validate command
    !!
    !! Theory:
    !!   Validates a command against a specification.
    !!   Process: Valid(cmd, spec) -> status, where cmd = {Cmd}, spec = {specification}
    !!
    !! Input:
    !!   in%cmd: Command to validate
    !!   in%spec: Validation specification (placeholder)
    !!
    !! Output:
    !!   out%status: Error status

    type(Cmd_Valid_In),  intent(in)  :: in
    type(Cmd_Valid_Out), intent(out) :: out

    call init_error_status(out%status)
    ! TODO: Implement actual validation logic (cmd name, param count, param ranges)
    out%status%status_code = IF_STATUS_OK
  end subroutine Cmd_Valid_Structured

  !===============================================================================
  ! Cmd_FormatError_Structured
  !===============================================================================
  subroutine Cmd_FormatError_Structured(in, out)
    !! Format error message with command context
    !!
    !! Theory:
    !!   Formats an error message with command context information.
    !!   Process: FormatError(cmd, base_message) -> formatted_message
    !!   where formatted_message = "[Line L] base_message (Command: name)"
    !!
    !! Input:
    !!   in%cmd: Command that caused error
    !!   in%base_message: Base error message
    !!
    !! Output:
    !!   out%formatted_message: Formatted error message

    type(Cmd_FormatError_In),  intent(in)  :: in
    type(Cmd_FormatError_Out), intent(out) :: out

    write(out%formatted_message, '(A,I0,A,A,A,A,A)') &
      '[Line ', in%cmd%line, '] ', trim(in%base_message), &
      ' (Command: ', trim(in%cmd%name), ')'
  end subroutine Cmd_FormatError_Structured

  !===============================================================================
  ! Legacy wrappers (@deprecated)
  !===============================================================================
  !> @deprecated Use Cmd_Valid_Structured instead
  subroutine Cmd_Valid(cmd, spec, status)
    type(Cmd),  intent(in)  :: cmd
    type(*) :: spec                           ! Placeholder
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    status%status_code = IF_STATUS_OK
  end subroutine Cmd_Valid

  !> @deprecated Use Cmd_FormatError_Structured instead
  subroutine Cmd_FormatError(cmd, base_message, formatted_messa)
    type(Cmd),            intent(in)  :: cmd
    character(len=*),     intent(in)  :: base_message
    character(len=*),     intent(out) :: formatted_messa

    type(Cmd_FormatError_In)  :: in
    type(Cmd_FormatError_Out) :: out

    in%cmd          = cmd
    in%base_message = base_message
    call Cmd_FormatError_Structured(in, out)
    formatted_messa = out%formatted_message
  end subroutine Cmd_FormatError

end module AP_InpScript_Valid