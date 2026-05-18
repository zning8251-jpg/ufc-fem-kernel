!===============================================================================
! MODULE: AP_InpScript_Subst
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl — parameter substitution engine
! BRIEF:  Parameter substitution - replace $var references with values.
!
! Process phases:
!   P1: Cmd_Subst / Cmd_SetVar / Cmd_GetVar
!===============================================================================

module AP_InpScript_Subst
  USE AP_Inp_Def, only: Cmd, CmdCtx
  USE IF_Err_Brg,      only: ErrorStatusType, init_error_status, &
                             IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Mem_Mgr,      only: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, MEM_DOMAIN_CMD
  USE IF_Prec_Core,         only: i4, wp

  implicit none
  private

  !===============================================================================
  ! I/O Types
  !===============================================================================
  type, public :: Cmd_Subst_In
    type(Cmd) :: cmd_in   ! Input command
  end type Cmd_Subst_In

  type, public :: Cmd_Subst_Out
    type(Cmd) :: cmd_out  ! Output command with substituted variables
    type(ErrorStatusType) :: status
  end type Cmd_Subst_Out

  type, public :: Cmd_SetVar_In
    character(len=32) :: var_name   ! Variable name
    real(wp)          :: var_value  ! Variable value
  end type Cmd_SetVar_In

  type, public :: Cmd_SetVar_Out
    type(ErrorStatusType) :: status
  end type Cmd_SetVar_Out

  type, public :: Cmd_GetVar_In
    character(len=32) :: var_name  ! Variable name
  end type Cmd_GetVar_In

  type, public :: Cmd_GetVar_Out
    real(wp)             :: var_value  ! Variable value
    logical              :: found      ! Whether variable was found
    type(ErrorStatusType) :: status
  end type Cmd_GetVar_Out

  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: Cmd_Subst
  public :: Cmd_SetVar
  public :: Cmd_GetVar
  public :: Cmd_Subst_Structured
  public :: Cmd_SetVar_Structured
  public :: Cmd_GetVar_Structured

contains

  !===============================================================================
  ! Cmd_Subst_Structured
  !===============================================================================
  subroutine Cmd_Subst_Structured(ctx, in, out)
    !! Substitute variables in command
    !!
    !! Theory:
    !!   Substitutes variable references in command parameters with actual values.
    !!   Supports: $var_name, ${var_name}, $1, $2, $3 (positional parameters)
    !!   Process: cmd_in -> find $var -> lookup value -> replace -> cmd_out
    !!   where var = {string}, value = real

    type(CmdCtx),      intent(in)  :: ctx
    type(Cmd_Subst_In), intent(in)  :: in
    type(Cmd_Subst_Out), intent(out) :: out

    character(len=512) :: work_str, var_name, var_value_str
    integer(i4) :: i, j, var_start, var_end, ic
    real(wp)    :: var_value
    logical     :: found

    call init_error_status(out%status)

    ! Copy command
    out%cmd_out = in%cmd_in
    work_str = in%cmd_in%param_str

    ! Process param_str for variable substitution
    i = 1
    do while (i <= len_trim(work_str))
      if (work_str(i:i) == '$') then
        var_start = i + 1

        ! Check for ${var_name} format
        if (var_start <= len_trim(work_str) .and. work_str(var_start:var_start) == '{') then
          var_start = var_start + 1
          var_end   = var_start
          do while (var_end <= len_trim(work_str))
            if (work_str(var_end:var_end) == '}') exit
            var_end = var_end + 1
          end do
          if (var_end > len_trim(work_str)) then
            i = i + 1
            cycle
          end if
          var_name = work_str(var_start:var_end-1)
        else
          ! Regular $var format
          var_end = var_start
          do while (var_end <= len_trim(work_str))
            ic = ichar(work_str(var_end:var_end))
            if ((ic >= ichar('a') .and. ic <= ichar('z')) .or. &
                (ic >= ichar('A') .and. ic <= ichar('Z')) .or. &
                (ic >= ichar('0') .and. ic <= ichar('9')) .or. &
                ic == ichar('_')) then
              var_end = var_end + 1
            else
              exit
            end if
          end do
          if (var_end == var_start) then
            if (var_start <= len_trim(work_str)) then
              ic = ichar(work_str(var_start:var_start))
              if (ic >= ichar('1') .and. ic <= ichar('3')) then
                var_name = work_str(var_start:var_start)
                var_end  = var_start + 1
              else
                i = i + 1
                cycle
              end if
            else
              i = i + 1
              cycle
            end if
          else
            var_name = work_str(var_start:var_end-1)
          end if
        end if

        ! Get variable value
        if (len_trim(var_name) == 1 .and. var_name(1:1) >= '1' .and. var_name(1:1) <= '3') then
          read(var_name, *) j
          if (j >= 1 .and. j <= 3) then
            var_value = in%cmd_in%params(j)
            write(var_value_str, '(ES15.8)') var_value
          else
            var_value_str = ''
          end if
        else
          var_value = Cmd_GetVar(ctx, var_name, found)
          if (found) then
            write(var_value_str, '(ES15.8)') var_value
          else
            i = var_end
            cycle
          end if
        end if

        ! Replace $var with value
        if (work_str(i:i) == '$' .and. var_start > i + 1 .and. &
            work_str(var_start-1:var_start-1) == '{') then
          ! ${var} format
          work_str = work_str(1:i-1) // trim(var_value_str) // work_str(var_end+1:)
          i = i + len_trim(var_value_str)
        else
          ! $var format
          work_str = work_str(1:i-1) // trim(var_value_str) // work_str(var_end:)
          i = i + len_trim(var_value_str)
        end if
      else
        i = i + 1
      end if
    end do

    out%cmd_out%param_str = work_str
    out%status%status_code = IF_STATUS_OK
  end subroutine Cmd_Subst_Structured

  !===============================================================================
  ! Cmd_SetVar_Structured
  !===============================================================================
  subroutine Cmd_SetVar_Structured(ctx, in, out)
    !! Set variable value in command context
    !!
    !! Theory:
    !!   Sets a variable value in the command context.
    !!   Process: SetVar(var_name, var_value) -> ctx%vars

    type(CmdCtx),      intent(inout) :: ctx
    type(Cmd_SetVar_In), intent(in)   :: in
    type(Cmd_SetVar_Out), intent(out) :: out

    integer(i4) :: i, n_vars, idx, new_size, ios
    character(len=32), allocatable :: temp_names(:)
    real(wp), pointer :: temp_values(:)
    integer(i4) :: temp_values_id
    type(ErrorStatusType) :: st

    call init_error_status(out%status)
    nullify(temp_values)

    ! Find existing variable
    idx = 0
    if (allocated(ctx%var_names)) then
      do i = 1, size(ctx%var_names)
        if (trim(ctx%var_names(i)) == trim(in%var_name)) then
          idx = i
          exit
        end if
      end do
    end if

    if (idx > 0) then
      if (associated(ctx%vars) .and. idx <= size(ctx%vars)) then
        ctx%vars(idx) = in%var_value
      end if
    else
      ! Add new variable
      if (.not. allocated(ctx%var_names)) then
        allocate(ctx%var_names(10), stat=ios)
        if (ios /= 0) then
          out%status%status_code = IF_STATUS_ERROR
          write(out%status%message, '(A)') 'Failed to allocate variable names'
          return
        end if
        call UF_Mem_AllocReal1D(MEM_DOMAIN_CMD, 0, 10, 'CmdCtx_vars', ctx%vars, ctx%vars_id, st)
        if (st%status_code /= IF_STATUS_OK) then
          deallocate(ctx%var_names)
          out%status = st
          return
        end if
        ctx%num_vars = 0
      end if

      n_vars = ctx%num_vars
      if (n_vars >= size(ctx%var_names)) then
        ! Expand arrays
        new_size = size(ctx%var_names) * 2
        allocate(temp_names(new_size), stat=ios)
        if (ios /= 0) then
          out%status%status_code = IF_STATUS_ERROR
          write(out%status%message, '(A)') 'Failed to expand variable names'
          return
        end if
        temp_names(1:n_vars) = ctx%var_names(1:n_vars)
        call move_alloc(temp_names, ctx%var_names)

        call UF_Mem_AllocReal1D(MEM_DOMAIN_CMD, 0, new_size, 'CmdCtx_vars_temp', temp_values, temp_values_id, st)
        if (st%status_code /= IF_STATUS_OK) then
          out%status = st
          return
        end if
        temp_values(1:n_vars) = ctx%vars(1:n_vars)
        call UF_Mem_FreeReal1D(ctx%vars_id, st)
        ctx%vars    => temp_values
        ctx%vars_id  = temp_values_id
        nullify(temp_values)
      end if

      ctx%num_vars              = ctx%num_vars + 1
      ctx%var_names(ctx%num_vars) = trim(in%var_name)
      ctx%vars(ctx%num_vars)    = in%var_value
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine Cmd_SetVar_Structured

  !===============================================================================
  ! Cmd_GetVar_Structured
  !===============================================================================
  subroutine Cmd_GetVar_Structured(ctx, in, out)
    !! Get variable value from command context
    !!
    !! Theory:
    !!   Gets a variable value from the command context.
    !!   Process: GetVar(var_name) -> var_value

    type(CmdCtx),      intent(in)  :: ctx
    type(Cmd_GetVar_In), intent(in)  :: in
    type(Cmd_GetVar_Out), intent(out) :: out

    integer(i4) :: i

    call init_error_status(out%status)
    out%found     = .false.
    out%var_value = 0.0_wp

    if (allocated(ctx%var_names) .and. associated(ctx%vars)) then
      do i = 1, ctx%num_vars
        if (trim(ctx%var_names(i)) == trim(in%var_name)) then
          out%var_value = ctx%vars(i)
          out%found     = .true.
          out%status%status_code = IF_STATUS_OK
          return
        end if
      end do
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine Cmd_GetVar_Structured

  !===============================================================================
  ! Legacy wrappers (@deprecated)
  !===============================================================================
  !> @deprecated Use Cmd_Subst_Structured instead
  subroutine Cmd_Subst(cmd_in, ctx, cmd_out, status)
    type(Cmd),  intent(in)  :: cmd_in
    type(CmdCtx), intent(in) :: ctx
    type(Cmd),  intent(out) :: cmd_out
    type(ErrorStatusType), intent(out) :: status

    type(Cmd_Subst_In)  :: in
    type(Cmd_Subst_Out) :: out

    in%cmd_in = cmd_in
    call Cmd_Subst_Structured(ctx, in, out)
    cmd_out = out%cmd_out
    status  = out%status
  end subroutine Cmd_Subst

  !> @deprecated Use Cmd_SetVar_Structured instead
  subroutine Cmd_SetVar(ctx, var_name, var_value, status)
    type(CmdCtx),     intent(inout)          :: ctx
    character(len=*), intent(in)             :: var_name
    real(wp),         intent(in)             :: var_value
    type(ErrorStatusType), intent(out), optional :: status

    type(Cmd_SetVar_In)  :: in
    type(Cmd_SetVar_Out) :: out

    in%var_name  = var_name
    in%var_value = var_value
    call Cmd_SetVar_Structured(ctx, in, out)
    if (present(status)) status = out%status
  end subroutine Cmd_SetVar

  !> @deprecated Use Cmd_GetVar_Structured instead
  function Cmd_GetVar(ctx, var_name, found) result(var_value)
    type(CmdCtx),     intent(in)            :: ctx
    character(len=*), intent(in)            :: var_name
    logical,          intent(out), optional :: found
    real(wp) :: var_value

    type(Cmd_GetVar_In)  :: in
    type(Cmd_GetVar_Out) :: out

    in%var_name = var_name
    call Cmd_GetVar_Structured(ctx, in, out)
    var_value = out%var_value
    if (present(found)) found = out%found
  end function Cmd_GetVar

end module AP_InpScript_Subst