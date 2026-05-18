!===============================================================================
! MODULE: AP_InpScript_Parser
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl — command parsing engine
! BRIEF:  Command parsing - line/file/string to Cmd/CmdList structures.
!
! Process phases:
!   P1: Cmd_ParseLine / Cmd_ParseFile / Cmd_ParseString
!===============================================================================

module AP_InpScript_Parser
  USE AP_Inp_Def,   only: Cmd, CmdList
  USE AP_Inp_Domain, only: AP_Cmd_Domain
  USE IF_Err_Brg,        only: ErrorStatusType, init_error_status, &
                               IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_IO_ERROR, IF_STATUS_ERROR
  USE IF_Prec_Core,           only: i4, wp
  USE, INTRINSIC :: IEEE_ARITHMETIC, only: IEEE_IS_NAN, IEEE_IS_FINITE

  implicit none
  private

  !===============================================================================
  ! Constants
  !===============================================================================
  integer(i4), parameter :: MAX_LINE_LEN = 512
  integer(i4), parameter :: MAX_TOKENS   = 20

  !===============================================================================
  ! CmdParser type
  !===============================================================================
  TYPE, public :: CmdParser
    LOGICAL               :: case_sensitive = .false.
    LOGICAL               :: strip_comments = .true.
    CHARACTER(len=1)      :: comment_char   = '!'
    LOGICAL               :: init           = .false.
  END TYPE CmdParser

  !===============================================================================
  ! I/O Types
  !===============================================================================
  type, public :: Cmd_ParseLine_In
    character(len=MAX_LINE_LEN) :: line
  end type Cmd_ParseLine_In

  type, public :: Cmd_ParseLine_Out
    type(Cmd) :: cmd
    type(ErrorStatusType) :: status
  end type Cmd_ParseLine_Out

  type, public :: Cmd_ParseFile_In
    character(len=256) :: filename
  end type Cmd_ParseFile_In

  type, public :: Cmd_ParseFile_Out
    type(CmdList) :: cmd_list
    type(ErrorStatusType) :: status
  end type Cmd_ParseFile_Out

  type, public :: Cmd_ParseString_In
    character(len=MAX_LINE_LEN) :: str
  end type Cmd_ParseString_In

  type, public :: Cmd_ParseString_Out
    type(CmdList) :: cmd_list
    type(ErrorStatusType) :: status
  end type Cmd_ParseString_Out

  !===============================================================================
  ! Module-level parser state (per-module singleton, package-visible)
  !===============================================================================
  TYPE(CmdParser), SAVE :: g_parser

  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: Cmd_ParseLine
  public :: Cmd_ParseFile
  public :: Cmd_ParseString
  public :: Cmd_ParseLine_Structured
  public :: Cmd_ParseFile_Structured
  public :: Cmd_ParseString_Structured
  public :: Cmd_ExpandMacros
  public :: Cmd_ParseKeyValue
  public :: Cmd_ParseArray
  public :: g_parser

contains

  !===============================================================================
  ! Cmd_ParseLine_Structured
  !===============================================================================
  subroutine Cmd_ParseLine_Structured(in, out)
    !! Parse command line
    !!
    !! Theory:
    !!   Parses a command line string into a Cmd structure.
    !!   Process: line -> strip comments -> convert case -> tokenize -> parse tokens -> cmd

    type(Cmd_ParseLine_In),  intent(in)  :: in
    type(Cmd_ParseLine_Out), intent(out) :: out

    character(len=MAX_LINE_LEN) :: work_line
    integer(i4)                 :: i, j, k, n_tokens, len_line
    character(len=MAX_TOKENS*16) :: tokens(MAX_TOKENS)
    logical                     :: in_quotes

    call init_error_status(out%status)

    out%cmd%name      = ''
    out%cmd%opt       = ''
    out%cmd%params    = 0.0_wp
    out%cmd%param_str = ''
    out%cmd%cfg%id        = 0
    out%cmd%line      = 0

    work_line = in%line
    len_line  = len_trim(work_line)

    ! Strip comments
    if (g_parser%strip_comments) then
      do i = 1, len_line
        if (work_line(i:i) == g_parser%comment_char) then
          work_line(i:) = ' '
          exit
        end if
      end do
    end if

    ! Convert to lowercase if not case sensitive
    if (.not. g_parser%case_sensitive) then
      do i = 1, len_line
        if (work_line(i:i) >= 'A' .and. work_line(i:i) <= 'Z') then
          work_line(i:i) = char(ichar(work_line(i:i)) + 32)
        end if
      end do
    end if

    ! Tokenize
    n_tokens  = 0
    i         = 1
    in_quotes = .false.

    do while (i <= len_line .and. n_tokens < MAX_TOKENS)
      do while (i <= len_line .and. (work_line(i:i) == ' ' .or. work_line(i:i) == char(9)))
        i = i + 1
      end do
      if (i > len_line) exit

      if (work_line(i:i) == '"' .or. work_line(i:i) == "'") then
        in_quotes = .true.
        j = i + 1
        do while (j <= len_line .and. work_line(j:j) /= work_line(i:i))
          j = j + 1
        end do
        if (j <= len_line) then
          n_tokens = n_tokens + 1
          tokens(n_tokens) = work_line(i+1:j-1)
          i = j + 1
        else
          i = len_line + 1
        end if
        in_quotes = .false.
      else
        j = i
        do while (j <= len_line .and. work_line(j:j) /= ' ' .and. work_line(j:j) /= char(9))
          j = j + 1
        end do
        if (j > i) then
          n_tokens = n_tokens + 1
          tokens(n_tokens) = work_line(i:j-1)
          i = j
        end if
      end if
    end do

    if (n_tokens == 0) then
      out%status%status_code = IF_STATUS_OK
      return
    end if

    out%cmd%name = tokens(1)
    if (len_trim(out%cmd%name) == 0) then
      out%status%status_code = IF_STATUS_INVALID
      write(out%status%message, '(A)') 'Empty command name'
      return
    end if
    if (len_trim(out%cmd%name) > 16) then
      out%status%status_code = IF_STATUS_INVALID
      write(out%status%message, '(A,I0,A)') 'Command name too long (max 16, got ', &
        len_trim(out%cmd%name), ')'
      return
    end if
    ! Check for invalid characters
    do i = 1, len_trim(out%cmd%name)
      j = ichar(out%cmd%name(i:i))
      if (.not. ((j >= ichar('a') .and. j <= ichar('z')) .or. &
                 (j >= ichar('A') .and. j <= ichar('Z')) .or. &
                 (j >= ichar('0') .and. j <= ichar('9')) .or. &
                 j == ichar('_') .or. j == ichar('-'))) then
        out%status%status_code = IF_STATUS_INVALID
        write(out%status%message, '(A,A,A)') 'Invalid character in command name: "', &
          out%cmd%name(i:i), '"'
        return
      end if
    end do

    if (n_tokens >= 2) out%cmd%opt = tokens(2)

    if (n_tokens >= 3) then
      do i = 3, min(n_tokens, 5)
        j = index(tokens(i), '=')
        if (j > 0) then
          if (len_trim(out%cmd%param_str) > 0) then
            out%cmd%param_str = trim(out%cmd%param_str) // ' ' // trim(tokens(i))
          else
            out%cmd%param_str = trim(tokens(i))
          end if
        else
          read(tokens(i), *, iostat=k) out%cmd%params(i-2)
          if (k /= 0) then
            if (len_trim(out%cmd%param_str) > 0) then
              out%cmd%param_str = trim(out%cmd%param_str) // ' ' // trim(tokens(i))
            else
              out%cmd%param_str = trim(tokens(i))
            end if
          else
            if (IEEE_IS_NAN(out%cmd%params(i-2)) .or. .not. IEEE_IS_FINITE(out%cmd%params(i-2))) then
              if (len_trim(out%cmd%param_str) > 0) then
                out%cmd%param_str = trim(out%cmd%param_str) // ' ' // trim(tokens(i))
              else
                out%cmd%param_str = trim(tokens(i))
              end if
              out%cmd%params(i-2) = 0.0_wp
            end if
          end if
        end if
      end do

      do i = 6, n_tokens
        if (len_trim(out%cmd%param_str) > 0) then
          out%cmd%param_str = trim(out%cmd%param_str) // ' ' // trim(tokens(i))
        else
          out%cmd%param_str = trim(tokens(i))
        end if
      end do
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine Cmd_ParseLine_Structured

  !===============================================================================
  ! Cmd_ParseFile_Structured
  !===============================================================================
  subroutine Cmd_ParseFile_Structured(domain, in, out)
    !! Parse command file -> CmdList (cmd ids stored in domain)

    type(AP_Cmd_Domain),    intent(inout) :: domain
    type(Cmd_ParseFile_In),  intent(in)   :: in
    type(Cmd_ParseFile_Out), intent(out)  :: out

    integer(i4) :: unit, ios, line_num, n_lines, i, cmd_id
    character(len=MAX_LINE_LEN) :: line
    type(Cmd) :: cmd
    integer(i4), allocatable :: temp_ids(:)
    type(Cmd_ParseLine_In)  :: parse_in
    type(Cmd_ParseLine_Out) :: parse_out

    call init_error_status(out%status)

    open(newunit=unit, file=in%filename, status='old', action='read', iostat=ios)
    if (ios /= 0) then
      out%status%status_code = IF_STATUS_IO_ERROR
      write(out%status%message, '(A,A)') 'Failed to open file: ', trim(in%filename)
      return
    end if

    ! Count lines
    n_lines = 0
    do
      read(unit, '(A)', iostat=ios) line
      if (ios /= 0) exit
      if (len_trim(line) > 0) n_lines = n_lines + 1
    end do
    rewind(unit)

    allocate(temp_ids(n_lines), stat=ios)
    if (ios /= 0) then
      out%status%status_code = IF_STATUS_ERROR
      write(out%status%message, '(A)') 'Failed to allocate memory for command list'
      close(unit)
      return
    end if

    line_num = 0
    out%cmd_list%num_cmds = 0
    do
      read(unit, '(A)', iostat=ios) line
      if (ios /= 0) exit
      line_num = line_num + 1
      if (len_trim(line) == 0) cycle

      parse_in%line = line
      call Cmd_ParseLine_Structured(parse_in, parse_out)
      if (parse_out%status%status_code /= IF_STATUS_OK) then
        write(out%status%message, '(A,I0,A,A)') '[Line ', line_num, '] ', &
          trim(parse_out%status%message)
        out%status = parse_out%status
        close(unit)
        deallocate(temp_ids)
        return
      end if
      cmd = parse_out%cmd
      if (len_trim(cmd%name) == 0) cycle

      cmd%line = line_num
      call domain%AddCommand(cmd, cmd_id, out%status)
      if (out%status%status_code /= IF_STATUS_OK) then
        close(unit)
        deallocate(temp_ids)
        return
      end if
      out%cmd_list%num_cmds = out%cmd_list%num_cmds + 1
      temp_ids(out%cmd_list%num_cmds) = cmd_id
    end do
    close(unit)

    if (out%cmd_list%num_cmds > 0) then
      allocate(out%cmd_list%cmd_ids(out%cmd_list%num_cmds), stat=ios)
      if (ios /= 0) then
        out%status%status_code = IF_STATUS_ERROR
        write(out%status%message, '(A)') 'Failed to allocate final command list'
        deallocate(temp_ids)
        return
      end if
      out%cmd_list%cmd_ids(1:out%cmd_list%num_cmds) = temp_ids(1:out%cmd_list%num_cmds)
      out%cmd_list%init = .true.
    end if
    deallocate(temp_ids)

    call Cmd_ExpandMacros(out%cmd_list, out%status)
  end subroutine Cmd_ParseFile_Structured

  !===============================================================================
  ! Cmd_ParseString_Structured
  !===============================================================================
  subroutine Cmd_ParseString_Structured(domain, in, out)
    !! Parse multi-line string -> CmdList

    type(AP_Cmd_Domain),       intent(inout) :: domain
    type(Cmd_ParseString_In),  intent(in)   :: in
    type(Cmd_ParseString_Out), intent(out)  :: out

    integer(i4) :: line_start, line_end, line_num, n_lines, i, ios, cmd_id
    character(len=MAX_LINE_LEN) :: line
    type(Cmd) :: cmd
    integer(i4), allocatable :: temp_ids(:)
    integer(i4) :: str_len
    type(Cmd_ParseLine_In)  :: parse_in
    type(Cmd_ParseLine_Out) :: parse_out

    call init_error_status(out%status)

    str_len = len(in%str)
    n_lines = 1
    do i = 1, str_len
      if (in%str(i:i) == char(10) .or. in%str(i:i) == char(13)) n_lines = n_lines + 1
    end do

    allocate(temp_ids(n_lines), stat=ios)
    if (ios /= 0) then
      out%status%status_code = IF_STATUS_ERROR
      write(out%status%message, '(A)') 'Failed to allocate memory for command list'
      return
    end if

    line_num  = 0
    out%cmd_list%num_cmds = 0
    line_start = 1

    do i = 1, str_len
      if (in%str(i:i) == char(10) .or. in%str(i:i) == char(13)) then
        line_end = i - 1
        if (line_end >= line_start) then
          line     = in%str(line_start:line_end)
          line_num = line_num + 1
          if (len_trim(line) == 0) then
            line_start = i + 1
            cycle
          end if
          parse_in%line = line
          call Cmd_ParseLine_Structured(parse_in, parse_out)
          if (parse_out%status%status_code /= IF_STATUS_OK) then
            write(out%status%message, '(A,I0,A,A)') '[Line ', line_num, '] ', &
              trim(parse_out%status%message)
            out%status = parse_out%status
            deallocate(temp_ids)
            return
          end if
          cmd = parse_out%cmd
          if (len_trim(cmd%name) == 0) then
            line_start = i + 1
            cycle
          end if
          cmd%line = line_num
          call domain%AddCommand(cmd, cmd_id, out%status)
          if (out%status%status_code /= IF_STATUS_OK) then
            deallocate(temp_ids)
            return
          end if
          out%cmd_list%num_cmds = out%cmd_list%num_cmds + 1
          temp_ids(out%cmd_list%num_cmds) = cmd_id
        end if
        line_start = i + 1
      end if
    end do

    ! Handle last line
    if (line_start <= str_len) then
      line = in%str(line_start:str_len)
      if (len_trim(line) > 0) then
        line_num = line_num + 1
        parse_in%line = line
        call Cmd_ParseLine_Structured(parse_in, parse_out)
        if (parse_out%status%status_code /= IF_STATUS_OK) then
          write(out%status%message, '(A,I0,A,A)') '[Line ', line_num, '] ', &
            trim(parse_out%status%message)
          out%status = parse_out%status
          deallocate(temp_ids)
          return
        end if
        cmd = parse_out%cmd
        if (len_trim(cmd%name) > 0) then
          cmd%line = line_num
          call domain%AddCommand(cmd, cmd_id, out%status)
          if (out%status%status_code /= IF_STATUS_OK) then
            deallocate(temp_ids)
            return
          end if
          out%cmd_list%num_cmds = out%cmd_list%num_cmds + 1
          temp_ids(out%cmd_list%num_cmds) = cmd_id
        end if
      end if
    end if

    if (out%cmd_list%num_cmds > 0) then
      allocate(out%cmd_list%cmd_ids(out%cmd_list%num_cmds), stat=ios)
      if (ios /= 0) then
        out%status%status_code = IF_STATUS_ERROR
        write(out%status%message, '(A)') 'Failed to allocate final command list'
        deallocate(temp_ids)
        return
      end if
      out%cmd_list%cmd_ids(1:out%cmd_list%num_cmds) = temp_ids(1:out%cmd_list%num_cmds)
      out%cmd_list%init = .true.
    end if
    deallocate(temp_ids)

    call Cmd_ExpandMacros(out%cmd_list, out%status)
  end subroutine Cmd_ParseString_Structured

  !===============================================================================
  ! Cmd_ExpandMacros - placeholder
  !===============================================================================
  subroutine Cmd_ExpandMacros(cmd_list, status)
    type(CmdList),        intent(inout) :: cmd_list
    type(ErrorStatusType), intent(inout) :: status
    ! Placeholder: macro expansion not yet implemented
    status%status_code = IF_STATUS_OK
  end subroutine Cmd_ExpandMacros

  !===============================================================================
  ! Cmd_ParseKeyValue
  !===============================================================================
  subroutine Cmd_ParseKeyValue(param_str, key, value, found, status)
    !! Parse Key=Value parameter string into (key, value)

    character(len=*), intent(in)  :: param_str
    character(len=32), intent(out) :: key
    character(len=256), intent(out) :: value
    logical,           intent(out) :: found
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: eq_pos, i

    call init_error_status(status)
    found = .false.
    key   = ''
    value = ''

    eq_pos = index(param_str, '=')
    if (eq_pos == 0) then
      status%status_code = IF_STATUS_OK
      return
    end if

    if (eq_pos > 1) then
      key = param_str(1:eq_pos-1)
      do i = len_trim(key), 1, -1
        if (key(i:i) == ' ') then
          key(i:) = ' '
        else
          exit
        end if
      end do
      key = adjustl(key)
    end if

    if (eq_pos < len_trim(param_str)) then
      value = adjustl(param_str(eq_pos+1:))
      do i = len_trim(value), 1, -1
        if (value(i:i) == ' ') then
          value(i:) = ' '
        else
          exit
        end if
      end do
    end if

    ! Remove quotes
    if (len_trim(value) >= 2) then
      if ((value(1:1) == '"'  .and. value(len_trim(value):len_trim(value)) == '"') .or. &
          (value(1:1) == "'" .and. value(len_trim(value):len_trim(value)) == "'")) then
        value = value(2:len_trim(value)-1)
      end if
    end if

    found = .true.
    status%status_code = IF_STATUS_OK
  end subroutine Cmd_ParseKeyValue

  !===============================================================================
  ! Cmd_ParseArray
  !===============================================================================
  subroutine Cmd_ParseArray(param_str, array, n_elements, status)
    !! Parse array parameter "[1,2,3]" -> real array

    character(len=*),      intent(in)  :: param_str
    real(wp), allocatable, intent(out) :: array(:)
    integer(i4),           intent(out) :: n_elements
    type(ErrorStatusType), intent(out) :: status

    character(len=512) :: work_str
    integer(i4) :: i, j, start_pos, end_pos, n_commas, ios
    character(len=64) :: elem_str
    real(wp) :: val

    call init_error_status(status)
    n_elements = 0

    if (len_trim(param_str) < 2) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Invalid array format: too short'
      return
    end if

    if (param_str(1:1) /= '[' .or. &
        param_str(len_trim(param_str):len_trim(param_str)) /= ']') then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Invalid array format: must start with [ and end with ]'
      return
    end if

    work_str = param_str(2:len_trim(param_str)-1)
    n_commas = 0
    do i = 1, len_trim(work_str)
      if (work_str(i:i) == ',') n_commas = n_commas + 1
    end do
    n_elements = n_commas + 1

    allocate(array(n_elements), stat=ios)
    if (ios /= 0) then
      status%status_code = IF_STATUS_ERROR
      write(status%message, '(A)') 'Failed to allocate array'
      return
    end if

    start_pos = 1
    j = 1
    do i = 1, len_trim(work_str)
      if (work_str(i:i) == ',' .or. i == len_trim(work_str)) then
        end_pos = merge(i, i-1, i == len_trim(work_str))
        if (end_pos >= start_pos) then
          elem_str = adjustl(work_str(start_pos:end_pos))
          read(elem_str, *, iostat=ios) val
          array(j) = merge(val, 0.0_wp, ios == 0)
          j = j + 1
        end if
        start_pos = i + 1
      end if
    end do
    n_elements = j - 1
    status%status_code = IF_STATUS_OK
  end subroutine Cmd_ParseArray

  !===============================================================================
  ! Legacy wrappers (@deprecated)
  !===============================================================================
  !> @deprecated Use Cmd_ParseLine_Structured instead
  subroutine Cmd_ParseLine(line, cmd, status)
    character(len=*),     intent(in)  :: line
    type(Cmd),            intent(out) :: cmd
    type(ErrorStatusType), intent(out) :: status
    type(Cmd_ParseLine_In)  :: in
    type(Cmd_ParseLine_Out) :: out
    in%line = line
    call Cmd_ParseLine_Structured(in, out)
    cmd    = out%cmd
    status = out%status
  end subroutine Cmd_ParseLine

  !> @deprecated Use Cmd_ParseFile_Structured instead
  subroutine Cmd_ParseFile(domain, filename, cmd_list, status)
    type(AP_Cmd_Domain), intent(inout) :: domain
    character(len=*),   intent(in)    :: filename
    type(CmdList),      intent(out)   :: cmd_list
    type(ErrorStatusType), intent(out) :: status
    type(Cmd_ParseFile_In)  :: in
    type(Cmd_ParseFile_Out) :: out
    in%filename = filename
    call Cmd_ParseFile_Structured(domain, in, out)
    cmd_list = out%cmd_list
    status   = out%status
  end subroutine Cmd_ParseFile

  !> @deprecated Use Cmd_ParseString_Structured instead
  subroutine Cmd_ParseString(domain, str, cmd_list, status)
    type(AP_Cmd_Domain), intent(inout) :: domain
    character(len=*),   intent(in)    :: str
    type(CmdList),      intent(out)   :: cmd_list
    type(ErrorStatusType), intent(out) :: status
    type(Cmd_ParseString_In)  :: in
    type(Cmd_ParseString_Out) :: out
    in%str = str
    call Cmd_ParseString_Structured(domain, in, out)
    cmd_list = out%cmd_list
    status   = out%status
  end subroutine Cmd_ParseString

end module AP_InpScript_Parser