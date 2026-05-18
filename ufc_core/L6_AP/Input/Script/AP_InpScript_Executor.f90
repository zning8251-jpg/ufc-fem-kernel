!===============================================================================
! MODULE: AP_InpScript_Executor
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl â€?command execution with control flow
! BRIEF:  Command execution with loop/if control flow support.
!
! Process phases:
!   P2: Cmd_Exec / Cmd_ExecList / Cmd_ExecLoop / Cmd_ExecIf
!===============================================================================

module AP_InpScript_Executor
  USE AP_Inp_Def,      only: Cmd, CmdCtx, CmdHandler, CmdList
  USE AP_Inp_Domain,    only: AP_Cmd_Domain
  USE AP_InpScript_Alias,  only: CmdAliasMgr, g_alias_mgr
  USE AP_InpScript_Subst,  only: Cmd_GetVar
  USE IF_Err_Brg,           only: ErrorStatusType, init_error_status, &
                                  IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Mem_Mgr,           only: UF_Mem_AllocInt1D, UF_Mem_FreeInt1D, MEM_DOMAIN_CMD
  USE IF_Prec_Core,              only: i4, wp

  implicit none
  private

  !===============================================================================
  ! Constants
  !===============================================================================
  integer(i4), parameter :: MAX_NEST_DEPTH = 20

  !===============================================================================
  ! CmdExec type
  !===============================================================================
  TYPE, public :: CmdExec
    TYPE(CmdCtx) :: ctx
    LOGICAL      :: init = .false.
  CONTAINS
    PROCEDURE :: Exec
    PROCEDURE :: ExecList
  END TYPE CmdExec

  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: Cmd_ExecList
  public :: Cmd_InitStacks
  public :: CmdList_GetCmd
  public :: EvaluateCondition

contains

  !===============================================================================
  ! CmdList_GetCmd
  !===============================================================================
  subroutine CmdList_GetCmd(cmd_list, domain, i, cmd, found)
    !! Resolve command by list index via domain (index tree + flat)

    type(CmdList),       intent(in)  :: cmd_list
    type(AP_Cmd_Domain), intent(in)  :: domain
    integer(i4),         intent(in)  :: i
    type(Cmd),           intent(out) :: cmd
    logical,             intent(out) :: found

    integer(i4) :: cid

    found = .false.
    if (i < 1 .or. i > cmd_list%num_cmds) return
    if (.not. allocated(cmd_list%cmd_ids)) return
    if (i > size(cmd_list%cmd_ids)) return
    cid = cmd_list%cmd_ids(i)
    call domain%GetCommandById(cid, cmd, found)
  end subroutine CmdList_GetCmd

  !===============================================================================
  ! Cmd_InitStacks
  !===============================================================================
  subroutine Cmd_InitStacks(ctx, status)
    !! Initialize loop and if control stacks in ctx

    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out), optional :: status

    integer(i4) :: ios

    if (present(status)) call init_error_status(status)

    if (.not. allocated(ctx%loop_stack)) then
      allocate(ctx%loop_stack(MAX_NEST_DEPTH), stat=ios)
      if (ios /= 0) then
        if (present(status)) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'Failed to allocate loop_stack'
        end if
        return
      end if
      allocate(ctx%loop_max_stack(MAX_NEST_DEPTH), stat=ios)
      if (ios /= 0) then
        deallocate(ctx%loop_stack)
        if (present(status)) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'Failed to allocate loop_max_stack'
        end if
        return
      end if
      allocate(ctx%loop_start_stac(MAX_NEST_DEPTH), stat=ios)
      if (ios /= 0) then
        deallocate(ctx%loop_stack, ctx%loop_max_stack)
        if (present(status)) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'Failed to allocate loop_start_stac'
        end if
        return
      end if
    end if
    ctx%loop_stack     = 0
    ctx%loop_max_stack = 0
    ctx%loop_start_stac = 0
    ctx%loop_depth     = 0

    if (.not. allocated(ctx%if_stack)) then
      allocate(ctx%if_stack(MAX_NEST_DEPTH), stat=ios)
      if (ios /= 0) then
        if (present(status)) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'Failed to allocate if_stack'
        end if
        return
      end if
      allocate(ctx%if_cond_stack(MAX_NEST_DEPTH), stat=ios)
      if (ios /= 0) then
        deallocate(ctx%if_stack)
        if (present(status)) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'Failed to allocate if_cond_stack'
        end if
        return
      end if
      allocate(ctx%else_exec_stack(MAX_NEST_DEPTH), stat=ios)
      if (ios /= 0) then
        deallocate(ctx%if_stack, ctx%if_cond_stack)
        if (present(status)) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'Failed to allocate else_exec_stack'
        end if
        return
      end if
    end if
    ctx%if_stack        = 0
    ctx%if_cond_stack   = .false.
    ctx%else_exec_stack = .false.
    ctx%if_depth        = 0

    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine Cmd_InitStacks

  !===============================================================================
  ! EvaluateCondition
  !===============================================================================
  subroutine EvaluateCondition(cmd, ctx, result, status)
    !! Evaluate if-condition from a command's opt/params/param_str fields

    type(Cmd),   intent(in)  :: cmd
    type(CmdCtx), intent(in) :: ctx
    logical,     intent(out) :: result
    type(ErrorStatusType), intent(out) :: status

    real(wp)          :: left_val, right_val
    character(len=64) :: op, left_var, right_var
    logical           :: found
    integer(i4)       :: ios

    call init_error_status(status)
    result = .false.

    left_var = ''
    if (len_trim(cmd%opt) > 0) left_var = cmd%opt

    op = 'eq'
    right_var = ''
    if (len_trim(cmd%param_str) > 0) then
      read(cmd%param_str, *, iostat=ios) op, right_var
      if (ios /= 0) op = trim(cmd%param_str)
    end if

    if (len_trim(left_var) > 0) then
      left_val = Cmd_GetVar(ctx, left_var, found)
      if (.not. found) left_val = cmd%params(1)
    else
      left_val = cmd%params(1)
    end if

    if (len_trim(right_var) > 0) then
      right_val = Cmd_GetVar(ctx, right_var, found)
      if (.not. found) right_val = cmd%params(2)
    else
      right_val = cmd%params(2)
    end if

    select case (trim(op))
    case ('eq', '==', '=')
      result = (abs(left_val - right_val) < 1.0e-10_wp)
    case ('ne', '!=', '<>')
      result = (abs(left_val - right_val) >= 1.0e-10_wp)
    case ('gt', '>')
      result = (left_val > right_val)
    case ('ge', '>=')
      result = (left_val >= right_val)
    case ('lt', '<')
      result = (left_val < right_val)
    case ('le', '<=')
      result = (left_val <= right_val)
    case default
      result = .false.
    end select

    status%status_code = IF_STATUS_OK
  end subroutine EvaluateCondition

  !===============================================================================
  ! Cmd_ExecList
  !===============================================================================
  subroutine Cmd_ExecList(cmd_list, domain, ctx, status)
    !! Execute a command list with loop/if/break/continue/jump control flow

    type(CmdList),       intent(in)    :: cmd_list
    type(AP_Cmd_Domain), intent(in)    :: domain
    type(CmdCtx),        intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status

    integer(i4)           :: i, j, depth, ios
    type(Cmd)             :: cmd
    logical               :: should_execute, break_flag, continue_flag, found
    integer(i4), pointer  :: loop_start(:), loop_end(:)
    integer(i4), pointer  :: loop_count(:), loop_max(:)
    integer(i4), pointer  :: if_start(:), if_end(:)
    logical, allocatable  :: if_condition(:), else_executed(:)
    integer(i4)           :: max_depth
    integer(i4)           :: loop_start_id, loop_end_id
    integer(i4)           :: loop_count_id, loop_max_id, if_start_id, if_end_id
    type(Cmd)             :: resolved_cmd
    type(CmdHandler)      :: h
    logical               :: alias_found
    type(ErrorStatusType) :: st

    call init_error_status(status)

    call Cmd_InitStacks(ctx, status)
    if (status%status_code /= IF_STATUS_OK) return

    if (.not. cmd_list%init .or. cmd_list%num_cmds == 0) then
      status%status_code = IF_STATUS_OK
      return
    end if

    max_depth = MAX_NEST_DEPTH
    nullify(loop_start, loop_end, loop_count, loop_max, if_start, if_end)

    call UF_Mem_AllocInt1D(MEM_DOMAIN_CMD, 0, max_depth, 'CmdExec_loop_start', &
      loop_start, loop_start_id, status)
    if (status%status_code /= IF_STATUS_OK) then
      status%message = 'Failed to allocate loop_start stack'; return
    end if
    call UF_Mem_AllocInt1D(MEM_DOMAIN_CMD, 0, max_depth, 'CmdExec_loop_end', &
      loop_end, loop_end_id, status)
    if (status%status_code /= IF_STATUS_OK) then
      call UF_Mem_FreeInt1D(loop_start_id, st)
      status%message = 'Failed to allocate loop_end stack'; return
    end if
    call UF_Mem_AllocInt1D(MEM_DOMAIN_CMD, 0, max_depth, 'CmdExec_loop_count', &
      loop_count, loop_count_id, status)
    if (status%status_code /= IF_STATUS_OK) then
      call UF_Mem_FreeInt1D(loop_start_id, st); call UF_Mem_FreeInt1D(loop_end_id, st)
      nullify(loop_start, loop_end)
      status%message = 'Failed to allocate loop_count stack'; return
    end if
    call UF_Mem_AllocInt1D(MEM_DOMAIN_CMD, 0, max_depth, 'CmdExec_loop_max', &
      loop_max, loop_max_id, status)
    if (status%status_code /= IF_STATUS_OK) then
      call UF_Mem_FreeInt1D(loop_start_id, st); call UF_Mem_FreeInt1D(loop_end_id, st)
      call UF_Mem_FreeInt1D(loop_count_id, st)
      nullify(loop_start, loop_end, loop_count)
      status%message = 'Failed to allocate loop_max stack'; return
    end if
    call UF_Mem_AllocInt1D(MEM_DOMAIN_CMD, 0, max_depth, 'CmdExec_if_start', &
      if_start, if_start_id, status)
    if (status%status_code /= IF_STATUS_OK) then
      call UF_Mem_FreeInt1D(loop_start_id, st); call UF_Mem_FreeInt1D(loop_end_id, st)
      call UF_Mem_FreeInt1D(loop_count_id, st); call UF_Mem_FreeInt1D(loop_max_id, st)
      nullify(loop_start, loop_end, loop_count, loop_max)
      status%message = 'Failed to allocate if_start stack'; return
    end if
    call UF_Mem_AllocInt1D(MEM_DOMAIN_CMD, 0, max_depth, 'CmdExec_if_end', &
      if_end, if_end_id, status)
    if (status%status_code /= IF_STATUS_OK) then
      call UF_Mem_FreeInt1D(loop_start_id, st); call UF_Mem_FreeInt1D(loop_end_id, st)
      call UF_Mem_FreeInt1D(loop_count_id, st); call UF_Mem_FreeInt1D(loop_max_id, st)
      call UF_Mem_FreeInt1D(if_start_id, st)
      nullify(loop_start, loop_end, loop_count, loop_max, if_start)
      status%message = 'Failed to allocate if_end stack'; return
    end if
    allocate(if_condition(max_depth), stat=ios)
    if (ios /= 0) then
      call UF_Mem_FreeInt1D(loop_start_id, st); call UF_Mem_FreeInt1D(loop_end_id, st)
      call UF_Mem_FreeInt1D(loop_count_id, st); call UF_Mem_FreeInt1D(loop_max_id, st)
      call UF_Mem_FreeInt1D(if_start_id, st);   call UF_Mem_FreeInt1D(if_end_id, st)
      nullify(loop_start, loop_end, loop_count, loop_max, if_start, if_end)
      status%status_code = IF_STATUS_ERROR
      write(status%message, '(A)') 'Failed to allocate if_condition stack'; return
    end if
    allocate(else_executed(max_depth), stat=ios)
    if (ios /= 0) then
      call UF_Mem_FreeInt1D(loop_start_id, st); call UF_Mem_FreeInt1D(loop_end_id, st)
      call UF_Mem_FreeInt1D(loop_count_id, st); call UF_Mem_FreeInt1D(loop_max_id, st)
      call UF_Mem_FreeInt1D(if_start_id, st);   call UF_Mem_FreeInt1D(if_end_id, st)
      nullify(loop_start, loop_end, loop_count, loop_max, if_start, if_end)
      deallocate(if_condition)
      status%status_code = IF_STATUS_ERROR
      write(status%message, '(A)') 'Failed to allocate else_executed stack'; return
    end if

    loop_start     = 0;  loop_end       = 0
    loop_count     = 0;  loop_max       = 0
    if_start       = 0;  if_end         = 0
    if_condition   = .false.
    else_executed  = .false.
    depth = 0
    i     = 1

    do while (i <= cmd_list%num_cmds)
      call CmdList_GetCmd(cmd_list, domain, i, cmd, found)
      if (.not. found) goto 999

      break_flag    = .false.
      continue_flag = .false.
      should_execute = .true.

      if (ctx%break_level > 0) then
        break_flag    = .true.
        ctx%break_level = 0
      end if
      if (ctx%continue_level > 0) then
        continue_flag     = .true.
        ctx%continue_level = 0
      end if
      if (ctx%jump_target > 0) then
        i = ctx%jump_target
        ctx%jump_target = 0
        cycle
      end if

      if (cmd%name == 'loop') then
        depth = depth + 1
        if (depth > max_depth) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A,I0,A)') 'Maximum nesting depth (', max_depth, ') exceeded'
          goto 999
        end if
        loop_start(depth) = i + 1
        loop_count(depth) = 0
        loop_max(depth)   = merge(int(cmd%params(1), i4), 1_i4, cmd%params(1) > 0.0_wp)
        j = i + 1
        do while (j <= cmd_list%num_cmds)
          call CmdList_GetCmd(cmd_list, domain, j, cmd, found)
          if (found .and. cmd%name == 'next') then
            loop_end(depth) = j
            exit
          end if
          j = j + 1
        end do
        if (loop_end(depth) == 0) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'LOOP without matching NEXT'
          goto 999
        end if
        i = loop_start(depth)
        should_execute = .false.

      else if (cmd%name == 'next') then
        if (depth == 0 .or. loop_start(depth) == 0) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'NEXT without matching LOOP'
          goto 999
        end if
        loop_count(depth) = loop_count(depth) + 1
        if (break_flag) then
          i = loop_end(depth) + 1
          loop_start(depth) = 0; loop_end(depth) = 0
          depth = depth - 1
          should_execute = .false.
        else if (continue_flag .or. loop_count(depth) < loop_max(depth)) then
          i = loop_start(depth)
          should_execute = .false.
        else
          i = loop_end(depth) + 1
          loop_start(depth) = 0; loop_end(depth) = 0
          depth = depth - 1
          should_execute = .false.
        end if

      else if (cmd%name == 'if') then
        depth = depth + 1
        if (depth > max_depth) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A,I0,A)') 'Maximum nesting depth (', max_depth, ') exceeded'
          goto 999
        end if
        if_start(depth) = i + 1
        call EvaluateCondition(cmd, ctx, if_condition(depth), status)
        if (status%status_code /= IF_STATUS_OK) goto 999
        else_executed(depth) = .false.
        j = i + 1
        do while (j <= cmd_list%num_cmds)
          call CmdList_GetCmd(cmd_list, domain, j, cmd, found)
          if (found .and. (cmd%name == 'else' .or. cmd%name == 'endi')) then
            if_end(depth) = j
            exit
          end if
          j = j + 1
        end do
        if (if_end(depth) == 0) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'IF without matching ENDI'
          goto 999
        end if
        i = merge(i + 1, if_end(depth) + 1, if_condition(depth))
        should_execute = .false.

      else if (cmd%name == 'else') then
        if (depth == 0 .or. if_start(depth) == 0) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'ELSE without matching IF'
          goto 999
        end if
        if (if_condition(depth) .or. else_executed(depth)) then
          j = i + 1
          do while (j <= cmd_list%num_cmds)
            call CmdList_GetCmd(cmd_list, domain, j, cmd, found)
            if (found .and. cmd%name == 'endi') then
              i = j + 1; exit
            end if
            j = j + 1
          end do
        else
          else_executed(depth) = .true.
          i = i + 1
        end if
        should_execute = .false.

      else if (cmd%name == 'endi') then
        if (depth == 0 .or. if_start(depth) == 0) then
          status%status_code = IF_STATUS_ERROR
          write(status%message, '(A)') 'ENDI without matching IF'
          goto 999
        end if
        if_start(depth) = 0; if_end(depth) = 0
        depth = depth - 1
        should_execute = .false.
        i = i + 1

      else if (should_execute) then
        ! Resolve alias
        call g_alias_mgr%Resolve(cmd%name, resolved_cmd, alias_found, status)
        if (alias_found) then
          resolved_cmd%line = cmd%line
          if (len_trim(cmd%opt) > 0) resolved_cmd%opt = cmd%opt
          if (any(abs(cmd%params) > 1.0e-30_wp)) resolved_cmd%params = cmd%params
          if (len_trim(cmd%param_str) > 0) resolved_cmd%param_str = cmd%param_str
        else
          resolved_cmd = cmd
        end if
        ! Dispatch
        call domain%GetHandlerByName(resolved_cmd%name, h, alias_found)
        if (.not. alias_found) then
          status%status_code = IF_STATUS_INVALID
          write(status%message, '(A,A,A)') 'Unknown command: "', trim(resolved_cmd%name), '"'
          goto 999
        end if
        call h%handler(resolved_cmd, ctx, status)
        if (status%status_code /= IF_STATUS_OK) goto 999
        i = i + 1
      else
        i = i + 1
      end if
    end do

    999 continue
    call UF_Mem_FreeInt1D(loop_start_id, st); call UF_Mem_FreeInt1D(loop_end_id, st)
    call UF_Mem_FreeInt1D(loop_count_id, st); call UF_Mem_FreeInt1D(loop_max_id, st)
    call UF_Mem_FreeInt1D(if_start_id, st);   call UF_Mem_FreeInt1D(if_end_id, st)
    nullify(loop_start, loop_end, loop_count, loop_max, if_start, if_end)
    deallocate(if_condition, else_executed)
  end subroutine Cmd_ExecList

  !===============================================================================
  ! CmdExec bound methods
  !===============================================================================
  subroutine Exec_Exec(this, domain, cmd, status)
    class(CmdExec),      intent(inout) :: this
    type(AP_Cmd_Domain), intent(in)    :: domain
    type(Cmd),           intent(in)    :: cmd
    type(ErrorStatusType), intent(out) :: status

    type(CmdHandler) :: h
    logical          :: found

    call init_error_status(status)
    call domain%GetHandlerByName(cmd%name, h, found)
    if (.not. found) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A,A,A)') 'Unknown command: "', trim(cmd%name), '"'
      return
    end if
    call h%handler(cmd, this%ctx, status)
  end subroutine Exec_Exec

  subroutine Exec_ExecList(this, domain, cmd_list, status)
    class(CmdExec),      intent(inout) :: this
    type(AP_Cmd_Domain), intent(in)    :: domain
    type(CmdList),       intent(in)    :: cmd_list
    type(ErrorStatusType), intent(out) :: status
    call Cmd_ExecList(cmd_list, domain, this%ctx, status)
  end subroutine Exec_ExecList

end module AP_InpScript_Executor