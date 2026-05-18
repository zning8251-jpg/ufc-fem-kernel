!===================================================================
! MODULE:  MD_KW_Lexer
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Impl
! BRIEF:   Lexical analyzer for Abaqus INP file tokenization.
!          Handles line continuation, keywords, params, data lines.
!===================================================================
MODULE MD_KW_Lexer
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_KW_Def
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: kw_lexer_init
  PUBLIC :: kw_lexer_open_file
  PUBLIC :: kw_lexer_close
  PUBLIC :: kw_lexer_next_token
  PUBLIC :: kw_lexer_peek_token
  PUBLIC :: kw_lexer_push_back
  PUBLIC :: kw_lexer_get_line_num
  PUBLIC :: kw_lexer_at_eof

CONTAINS

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_lexer_init
  ! PHASE:      P0
  ! PURPOSE:    Initialize lexer state to defaults
  !-----------------------------------------------------------------
  SUBROUTINE kw_lexer_init(state)
    TYPE(KW_LexerStateType), INTENT(OUT) :: state               ! [out]

    state%file_unit        = 0
    state%filename         = ""
    state%file_open        = .FALSE.
    state%current_line     = 0
    state%current_col      = 1
    state%line_buffer      = ""
    state%buffer_len       = 0
    state%buffer_pos       = 1
    state%at_eof           = .FALSE.
    state%in_continuation  = .FALSE.
    state%case_sensitive   = .FALSE.
    state%has_pushed_token = .FALSE.
    state%total_lines      = 0
    state%total_tokens     = 0
  END SUBROUTINE kw_lexer_init

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_lexer_open_file
  ! PHASE:      P1
  ! PURPOSE:    Open INP file for lexing
  !-----------------------------------------------------------------
  SUBROUTINE kw_lexer_open_file(state, filename, success)
    TYPE(KW_LexerStateType), INTENT(INOUT) :: state             ! [inout]
    CHARACTER(LEN=*), INTENT(IN)           :: filename          ! [in]
    LOGICAL, INTENT(OUT)                   :: success           ! [out]

    INTEGER(i4) :: ios, unit_num
    LOGICAL     :: file_exists

    success = .FALSE.

    INQUIRE(FILE=TRIM(filename), EXIST=file_exists)
    IF (.NOT. file_exists) RETURN

    unit_num = 100
    DO WHILE (unit_num < 1000)
      INQUIRE(UNIT=unit_num, OPENED=file_exists)
      IF (.NOT. file_exists) EXIT
      unit_num = unit_num + 1
    END DO
    IF (unit_num >= 1000) RETURN

    OPEN(UNIT=unit_num, FILE=TRIM(filename), STATUS='OLD', &
         ACTION='READ', IOSTAT=ios)
    IF (ios /= 0) RETURN

    state%file_unit    = unit_num
    state%filename     = TRIM(filename)
    state%file_open    = .TRUE.
    state%current_line = 0
    state%at_eof       = .FALSE.
    state%buffer_len   = 0
    state%buffer_pos   = 1
    success = .TRUE.
  END SUBROUTINE kw_lexer_open_file

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_lexer_close
  ! PHASE:      P0
  ! PURPOSE:    Close lexer and release file handle
  !-----------------------------------------------------------------
  SUBROUTINE kw_lexer_close(state)
    TYPE(KW_LexerStateType), INTENT(INOUT) :: state             ! [inout]

    IF (state%file_open) THEN
      CLOSE(state%file_unit)
      state%file_open = .FALSE.
    END IF
    state%file_unit = 0
  END SUBROUTINE kw_lexer_close

  !-----------------------------------------------------------------
  ! SUBROUTINE: read_next_line  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Read next logical line, handling continuations
  !-----------------------------------------------------------------
  SUBROUTINE read_next_line(state, success)
    TYPE(KW_LexerStateType), INTENT(INOUT) :: state             ! [inout]
    LOGICAL, INTENT(OUT)                   :: success           ! [out]

    CHARACTER(LEN=KW_MAX_LINE_LEN) :: raw_line
    INTEGER(i4) :: ios, trim_len
    LOGICAL     :: has_continuation

    success            = .FALSE.
    state%line_buffer  = ""
    state%buffer_len   = 0
    state%buffer_pos   = 1

    IF (.NOT. state%file_open .OR. state%at_eof) RETURN

    DO
      READ(state%file_unit, '(A)', IOSTAT=ios) raw_line
      IF (ios /= 0) THEN
        state%at_eof = .TRUE.
        IF (state%buffer_len > 0) success = .TRUE.
        RETURN
      END IF

      state%current_line = state%current_line + 1
      state%total_lines  = state%total_lines + 1

      trim_len = LEN_TRIM(raw_line)
      IF (trim_len == 0) THEN
        IF (.NOT. state%in_continuation) THEN
          state%buffer_len = 0
          success = .TRUE.
          RETURN
        END IF
        CYCLE
      END IF

      has_continuation = .FALSE.
      IF (trim_len > 0) THEN
        IF (raw_line(trim_len:trim_len) == ',') THEN
          has_continuation = .TRUE.
        END IF
      END IF

      IF (state%buffer_len + trim_len <= KW_MAX_LINE_LEN) THEN
        state%line_buffer = TRIM(state%line_buffer) // raw_line(1:trim_len)
        state%buffer_len  = LEN_TRIM(state%line_buffer)
      END IF

      state%in_continuation = has_continuation
      IF (.NOT. has_continuation) THEN
        success = .TRUE.
        RETURN
      END IF
    END DO
  END SUBROUTINE read_next_line

  !-----------------------------------------------------------------
  ! SUBROUTINE: skip_whitespace  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Advance buffer position past whitespace
  !-----------------------------------------------------------------
  SUBROUTINE skip_whitespace(state)
    TYPE(KW_LexerStateType), INTENT(INOUT) :: state             ! [inout]
    CHARACTER(LEN=1) :: ch

    DO WHILE (state%buffer_pos <= state%buffer_len)
      ch = state%line_buffer(state%buffer_pos:state%buffer_pos)
      IF (ch /= ' ' .AND. ch /= CHAR(9)) EXIT
      state%buffer_pos = state%buffer_pos + 1
    END DO
  END SUBROUTINE skip_whitespace

  !-----------------------------------------------------------------
  ! FUNCTION:  is_keyword_char  (PRIVATE)
  ! PHASE:     P1
  ! PURPOSE:   Check if character is valid in keyword name
  !-----------------------------------------------------------------
  FUNCTION is_keyword_char(ch) RESULT(is_valid)
    CHARACTER(LEN=1), INTENT(IN) :: ch                          ! [in]
    LOGICAL :: is_valid
    INTEGER(i4) :: ic

    ic = ICHAR(ch)
    is_valid = (ic >= ICHAR('A') .AND. ic <= ICHAR('Z')) .OR. &
               (ic >= ICHAR('a') .AND. ic <= ICHAR('z')) .OR. &
               (ic >= ICHAR('0') .AND. ic <= ICHAR('9')) .OR. &
               ch == '_' .OR. ch == ' ' .OR. ch == '-'
  END FUNCTION is_keyword_char

  !-----------------------------------------------------------------
  ! FUNCTION:  is_value_char  (PRIVATE)
  ! PHASE:     P1
  ! PURPOSE:   Check if character is valid in a data value
  !-----------------------------------------------------------------
  FUNCTION is_value_char(ch) RESULT(is_valid)
    CHARACTER(LEN=1), INTENT(IN) :: ch                          ! [in]
    LOGICAL :: is_valid

    is_valid = ch /= ',' .AND. ch /= '=' .AND. ch /= '*' .AND. &
               ch /= CHAR(10) .AND. ch /= CHAR(13)
  END FUNCTION is_value_char

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_lexer_next_token
  ! PHASE:      P1
  ! PURPOSE:    Get next token from input stream
  !-----------------------------------------------------------------
  SUBROUTINE kw_lexer_next_token(state, token)
    TYPE(KW_LexerStateType), INTENT(INOUT) :: state             ! [inout]
    TYPE(KW_TokenType), INTENT(OUT)        :: token             ! [out]

    CHARACTER(LEN=1) :: ch, next_ch
    INTEGER(i4)      :: start_pos, end_pos
    LOGICAL          :: success, in_quotes

    CALL kw_init_token(token)

    ! Return pushed token if available
    IF (state%has_pushed_token) THEN
      token = state%pushed_token
      state%has_pushed_token = .FALSE.
      RETURN
    END IF

    ! Check EOF
    IF (state%at_eof .AND. state%buffer_pos > state%buffer_len) THEN
      token%token_type = TOKEN_EOF
      RETURN
    END IF

    ! Need new line?
    IF (state%buffer_pos > state%buffer_len) THEN
      CALL read_next_line(state, success)
      IF (.NOT. success) THEN
        IF (state%at_eof) THEN
          token%token_type = TOKEN_EOF
        ELSE
          token%token_type = TOKEN_NEWLINE
        END IF
        RETURN
      END IF
      IF (state%buffer_len == 0) THEN
        token%token_type = TOKEN_NEWLINE
        token%line_num   = state%current_line
        RETURN
      END IF
    END IF

    CALL skip_whitespace(state)

    IF (state%buffer_pos > state%buffer_len) THEN
      token%token_type = TOKEN_NEWLINE
      token%line_num   = state%current_line
      RETURN
    END IF

    ch             = state%line_buffer(state%buffer_pos:state%buffer_pos)
    token%line_num = state%current_line
    token%col_num  = state%buffer_pos

    ! Comment starting with !
    IF (ch == '!') THEN
      token%token_type = TOKEN_COMMENT
      token%value      = TRIM(state%line_buffer(state%buffer_pos:state%buffer_len))
      state%buffer_pos = state%buffer_len + 1
      state%total_tokens = state%total_tokens + 1
      RETURN
    END IF

    ! Keyword or comment (starts with *)
    IF (ch == '*') THEN
      state%buffer_pos = state%buffer_pos + 1
      IF (state%buffer_pos <= state%buffer_len) THEN
        next_ch = state%line_buffer(state%buffer_pos:state%buffer_pos)
        IF (next_ch == '*') THEN
          token%token_type = TOKEN_COMMENT
          token%value      = TRIM(state%line_buffer(state%buffer_pos:state%buffer_len))
          state%buffer_pos = state%buffer_len + 1
          state%total_tokens = state%total_tokens + 1
          RETURN
        END IF
      END IF

      start_pos = state%buffer_pos
      DO WHILE (state%buffer_pos <= state%buffer_len)
        ch = state%line_buffer(state%buffer_pos:state%buffer_pos)
        IF (ch == ',' .OR. ch == '=') EXIT
        IF (.NOT. is_keyword_char(ch)) EXIT
        state%buffer_pos = state%buffer_pos + 1
      END DO

      token%token_type = TOKEN_KEYWORD
      token%value = kw_to_upper(TRIM(state%line_buffer(start_pos:state%buffer_pos-1)))
      CALL normalize_keyword_name(token%value)
      state%total_tokens = state%total_tokens + 1
      RETURN
    END IF

    ! Comma separator
    IF (ch == ',') THEN
      token%token_type   = TOKEN_COMMA
      token%value        = ","
      state%buffer_pos   = state%buffer_pos + 1
      state%total_tokens = state%total_tokens + 1
      RETURN
    END IF

    ! Equals sign
    IF (ch == '=') THEN
      token%token_type   = TOKEN_EQUALS
      token%value        = "="
      state%buffer_pos   = state%buffer_pos + 1
      state%total_tokens = state%total_tokens + 1
      RETURN
    END IF

    ! Value (parameter name, value, or data)
    start_pos = state%buffer_pos
    in_quotes = .FALSE.

    DO WHILE (state%buffer_pos <= state%buffer_len)
      ch = state%line_buffer(state%buffer_pos:state%buffer_pos)

      IF (ch == '"' .OR. ch == "'") THEN
        IF (in_quotes) THEN
          in_quotes       = .FALSE.
          token%is_quoted = .TRUE.
        ELSE
          in_quotes = .TRUE.
          IF (start_pos == state%buffer_pos) start_pos = start_pos + 1
        END IF
        state%buffer_pos = state%buffer_pos + 1
        CYCLE
      END IF

      IF (in_quotes) THEN
        state%buffer_pos = state%buffer_pos + 1
        CYCLE
      END IF

      IF (ch == ',' .OR. ch == '=') EXIT
      state%buffer_pos = state%buffer_pos + 1
    END DO

    end_pos = state%buffer_pos - 1
    IF (token%is_quoted .AND. end_pos > start_pos) THEN
      IF (state%line_buffer(end_pos:end_pos) == '"' .OR. &
          state%line_buffer(end_pos:end_pos) == "'") THEN
        end_pos = end_pos - 1
      END IF
    END IF

    token%value      = TRIM(ADJUSTL(state%line_buffer(start_pos:end_pos)))
    token%token_type = TOKEN_DATA
    state%total_tokens = state%total_tokens + 1
  END SUBROUTINE kw_lexer_next_token

  !-----------------------------------------------------------------
  ! SUBROUTINE: normalize_keyword_name  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Collapse multiple spaces to single space in name
  !-----------------------------------------------------------------
  SUBROUTINE normalize_keyword_name(name)
    CHARACTER(LEN=*), INTENT(INOUT) :: name                     ! [inout]
    CHARACTER(LEN=KW_MAX_NAME_LEN)  :: result
    INTEGER(i4) :: i, j, len_in
    LOGICAL     :: last_was_space

    len_in = LEN_TRIM(name)
    IF (len_in == 0) RETURN

    result = ""
    j = 0
    last_was_space = .FALSE.

    DO i = 1, len_in
      IF (name(i:i) == ' ') THEN
        IF (.NOT. last_was_space) THEN
          j = j + 1
          result(j:j) = ' '
          last_was_space = .TRUE.
        END IF
      ELSE
        j = j + 1
        result(j:j) = name(i:i)
        last_was_space = .FALSE.
      END IF
    END DO

    name = TRIM(ADJUSTL(result))
  END SUBROUTINE normalize_keyword_name

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_lexer_peek_token
  ! PHASE:      P1
  ! PURPOSE:    Peek at next token without consuming it
  !-----------------------------------------------------------------
  SUBROUTINE kw_lexer_peek_token(state, token)
    TYPE(KW_LexerStateType), INTENT(INOUT) :: state             ! [inout]
    TYPE(KW_TokenType), INTENT(OUT)        :: token             ! [out]

    CALL kw_lexer_next_token(state, token)
    CALL kw_lexer_push_back(state, token)
  END SUBROUTINE kw_lexer_peek_token

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_lexer_push_back
  ! PHASE:      P1
  ! PURPOSE:    Push back a token for re-reading
  !-----------------------------------------------------------------
  SUBROUTINE kw_lexer_push_back(state, token)
    TYPE(KW_LexerStateType), INTENT(INOUT) :: state             ! [inout]
    TYPE(KW_TokenType), INTENT(IN)         :: token             ! [in]

    state%pushed_token     = token
    state%has_pushed_token = .TRUE.
  END SUBROUTINE kw_lexer_push_back

  !-----------------------------------------------------------------
  ! FUNCTION:  kw_lexer_get_line_num
  ! PHASE:     P0
  ! PURPOSE:   Get current line number
  !-----------------------------------------------------------------
  FUNCTION kw_lexer_get_line_num(state) RESULT(line_num)
    TYPE(KW_LexerStateType), INTENT(IN) :: state                ! [in]
    INTEGER(i4) :: line_num
    line_num = state%current_line
  END FUNCTION kw_lexer_get_line_num

  !-----------------------------------------------------------------
  ! FUNCTION:  kw_lexer_at_eof
  ! PHASE:     P0
  ! PURPOSE:   Check if at end of file
  !-----------------------------------------------------------------
  FUNCTION kw_lexer_at_eof(state) RESULT(at_eof)
    TYPE(KW_LexerStateType), INTENT(IN) :: state                ! [in]
    LOGICAL :: at_eof
    at_eof = state%at_eof .AND. state%buffer_pos > state%buffer_len &
             .AND. .NOT. state%has_pushed_token
  END FUNCTION kw_lexer_at_eof

END MODULE MD_KW_Lexer
