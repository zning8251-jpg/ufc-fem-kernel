!===============================================================================
! MODULE: AP_Inp_Param
! LAYER:  L6_AP
! DOMAIN: Input/Parser
! ROLE:   Util — parameter parsing utilities
! BRIEF:  Enhanced parameter parsing utilities (key=value, arrays, quoted strings).
!
! Process phases:
!   P1: ParseKeyValue / ParseKeyValueStr / ParseKeyValueInt / ParseKeyValueRe / ParseArray
!===============================================================================
module AP_Inp_Param
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: i4, wp
  USE, INTRINSIC :: IEEE_ARITHMETIC, only: IEEE_IS_NAN, IEEE_IS_FINITE
  
  implicit none
  private
  
  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: ParseKeyValue
  public :: PARSEKEYVALUERE
  public :: ParseKeyValueInt
  public :: ParseKeyValueStr
  public :: ParseArray
  public :: ParseQuotedString
  public :: SplitString
  
contains

  subroutine ParseArray(param_str, values, num_values, max_values)
    character(len=*), intent(in) :: param_str
    real(wp), intent(out) :: values(:)
    integer(i4), intent(out) :: num_values
    integer(i4), intent(in) :: max_values
    
    character(len=512) :: work_str
    integer(i4) :: i, j, start_pos, comma_pos, bracket_pos
    integer(i4) :: ios
    
    num_values = 0
    values = 0.0_wp
    work_str = adjustl(param_str)
    
    ! Remove brackets if present
    bracket_pos = index(work_str, '[')
    if (bracket_pos > 0) then
      work_str = work_str(bracket_pos+1:)
      bracket_pos = index(work_str, ']')
      if (bracket_pos > 0) then
        work_str = work_str(1:bracket_pos-1)
      end if
    end if
    
    ! Parse comma-separated values
    start_pos = 1
    do i = 1, max_values
      comma_pos = index(work_str(start_pos:), ',')
      if (comma_pos == 0) then
        ! Last value
        read(work_str(start_pos:), *, iostat=ios) values(i)
        if (ios == 0) then
          if (.not. IEEE_IS_NAN(values(i)) .and. IEEE_IS_FINITE(values(i))) then
            num_values = i
          end if
        end if
        exit
      else
        read(work_str(start_pos:start_pos+comma_pos-2), *, iostat=ios) values(i)
        if (ios == 0) then
          if (.not. IEEE_IS_NAN(values(i)) .and. IEEE_IS_FINITE(values(i))) then
            num_values = i
          end if
        end if
        start_pos = start_pos + comma_pos
      end if
    end do
    
  end subroutine ParseArray

  subroutine ParseKeyValue(param_str, key, value_str, found)
    character(len=*), intent(in) :: param_str
    character(len=*), intent(in) :: key
    character(len=*), intent(out) :: value_str
    logical, intent(out) :: found
    
    integer(i4) :: i, eq_pos, comma_pos, space_pos, end_pos
    character(len=256) :: search_key
    
    found = .false.
    value_str = ''
    
    ! Search for key=
    search_key = trim(key) // '='
    i = index(param_str, trim(search_key))
    if (i == 0) return
    
    ! Find equals sign
    eq_pos = i + len_trim(search_key) - 1
    
    ! Find value end (comma or end of string)
    comma_pos = index(param_str(eq_pos+1:), ',')
    space_pos = index(param_str(eq_pos+1:), ' ')
    
    end_pos = len(param_str) + 1
    if (comma_pos > 0) end_pos = min(end_pos, eq_pos + comma_pos)
    if (space_pos > 0) end_pos = min(end_pos, eq_pos + space_pos)
    
    ! Extract value
    if (end_pos > eq_pos + 1) then
      value_str = param_str(eq_pos+1:end_pos-1)
      value_str = adjustl(value_str)
      found = .true.
    end if
    
  end subroutine ParseKeyValue

  subroutine ParseKeyValueInt(param_str, key, value, found, default_val)
    character(len=*), intent(in) :: param_str
    character(len=*), intent(in) :: key
    integer(i4), intent(out) :: value
    logical, intent(out) :: found
    integer(i4), intent(in), optional :: default_val
    
    character(len=64) :: value_str
    integer(i4) :: ios
    
    call ParseKeyValue(param_str, key, value_str, found)
    
    if (found) then
      read(value_str, *, iostat=ios) value
      if (ios /= 0) then
        found = .false.
        if (present(default_val)) then
          value = default_val
        else
          value = 0
        end if
      end if
    else
      if (present(default_val)) then
        value = default_val
      else
        value = 0
      end if
    end if
    
  end subroutine ParseKeyValueInt

  subroutine PARSEKEYVALUERE(param_str, key, value, found, default_val)
    character(len=*), intent(in) :: param_str
    character(len=*), intent(in) :: key
    real(wp), intent(out) :: value
    logical, intent(out) :: found
    real(wp), intent(in), optional :: default_val
    
    character(len=64) :: value_str
    integer(i4) :: ios
    
    call ParseKeyValue(param_str, key, value_str, found)
    
    if (found) then
      read(value_str, *, iostat=ios) value
      if (ios /= 0) then
        found = .false.
        if (present(default_val)) then
          value = default_val
        else
          value = 0.0_wp
        end if
      else
        ! Check for NaN or Inf
        if (IEEE_IS_NAN(value) .or. .not. IEEE_IS_FINITE(value)) then
          found = .false.
          if (present(default_val)) then
            value = default_val
          else
            value = 0.0_wp
          end if
        end if
      end if
    else
      if (present(default_val)) then
        value = default_val
      else
        value = 0.0_wp
      end if
    end if
    
  end subroutine PARSEKEYVALUERE

  subroutine ParseKeyValueStr(param_str, key, value, found, default_val)
    character(len=*), intent(in) :: param_str
    character(len=*), intent(in) :: key
    character(len=*), intent(out) :: value
    logical, intent(out) :: found
    character(len=*), intent(in), optional :: default_val
    
    call ParseKeyValue(param_str, key, value, found)
    
    if (.not. found .and. present(default_val)) then
      value = default_val
    end if
    
  end subroutine ParseKeyValueStr

  subroutine ParseQuotedString(str, quoted_str, found)
    character(len=*), intent(in) :: str
    character(len=*), intent(out) :: quoted_str
    logical, intent(out) :: found
    
    integer(i4) :: quote1_pos, quote2_pos
    
    found = .false.
    quoted_str = ''
    
    ! Find first quote
    quote1_pos = index(str, '"')
    if (quote1_pos == 0) then
      quote1_pos = index(str, '''')
    end if
    
    if (quote1_pos == 0) return
    
    ! Find second quote
    quote2_pos = index(str(quote1_pos+1:), str(quote1_pos:quote1_pos))
    if (quote2_pos == 0) return
    
    quote2_pos = quote1_pos + quote2_pos
    
    ! Extract quoted string
    if (quote2_pos > quote1_pos + 1) then
      quoted_str = str(quote1_pos+1:quote2_pos-1)
      found = .true.
    end if
    
  end subroutine ParseQuotedString

  subroutine SplitString(str, delimiter, tokens, num_tokens, max_tokens)
    character(len=*), intent(in) :: str
    character(len=1), intent(in) :: delimiter
    character(len=*), intent(out) :: tokens(:)
    integer(i4), intent(out) :: num_tokens
    integer(i4), intent(in) :: max_tokens
    
    integer(i4) :: i, start_pos, delim_pos
    character(len=512) :: work_str
    
    num_tokens = 0
    tokens = ''
    work_str = adjustl(str)
    start_pos = 1
    
    do i = 1, max_tokens
      delim_pos = index(work_str(start_pos:), delimiter)
      if (delim_pos == 0) then
        ! Last token
        if (len_trim(work_str(start_pos:)) > 0) then
          tokens(i) = adjustl(work_str(start_pos:))
          num_tokens = i
        end if
        exit
      else
        tokens(i) = adjustl(work_str(start_pos:start_pos+delim_pos-2))
        num_tokens = i
        start_pos = start_pos + delim_pos
      end if
    end do
    
  end subroutine SplitString
end module AP_Inp_Param