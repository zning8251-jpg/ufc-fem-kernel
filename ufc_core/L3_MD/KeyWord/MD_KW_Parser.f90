!===================================================================
! MODULE:  MD_KW_Parser
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Impl
! BRIEF:   Syntax analyzer / AST builder for Abaqus INP files.
!          Parses tokenized content into hierarchical AST.
!===================================================================
MODULE MD_KW_Parser
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_KW_Lexer
  USE MD_KW_Reg
  USE MD_KW_Def
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: kw_parser_init
  PUBLIC :: kw_parser_parse_file
  PUBLIC :: kw_parser_get_ast
  PUBLIC :: kw_parser_get_node
  PUBLIC :: kw_parser_get_root_nodes
  PUBLIC :: kw_parser_get_errors
  PUBLIC :: kw_parser_cleanup
  PUBLIC :: kw_parser_find_nodes_by_keyword

CONTAINS

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_parser_init
  ! PHASE:      P0
  ! PURPOSE:    Initialize parser state and allocate AST storage
  !-----------------------------------------------------------------
  SUBROUTINE kw_parser_init(state, max_nodes)
    TYPE(KW_ParserStateType), INTENT(OUT) :: state              ! [out]
    INTEGER(i4), INTENT(IN), OPTIONAL     :: max_nodes          ! [in]

    CALL kw_lexer_init(state%lexer)

    IF (PRESENT(max_nodes)) THEN
      state%max_nodes = max_nodes
    ELSE
      state%max_nodes = 10000
    END IF

    IF (ALLOCATED(state%nodes)) DEALLOCATE(state%nodes)
    ALLOCATE(state%nodes(state%max_nodes))

    state%node_count          = 0
    state%current_parent_id   = 0
    state%current_step_id     = 0
    state%current_material_id = 0
    state%current_part_id     = 0
    state%error_count         = 0
    state%warning_count       = 0
    state%stop_on_error       = .FALSE.
    state%validate_keywords   = .TRUE.
    state%validate_params     = .TRUE.
    state%validate_hierarchy  = .TRUE.
  END SUBROUTINE kw_parser_init

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_parser_parse_file
  ! PHASE:      P1
  ! PURPOSE:    Parse entire INP file into AST
  !-----------------------------------------------------------------
  SUBROUTINE kw_parser_parse_file(state, filename, success)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    CHARACTER(LEN=*), INTENT(IN)            :: filename         ! [in]
    LOGICAL, INTENT(OUT)                    :: success          ! [out]

    TYPE(KW_TokenType) :: token
    LOGICAL            :: open_success

    success = .FALSE.

    IF (.NOT. kw_is_initialized()) CALL kw_registry_init()

    CALL kw_lexer_open_file(state%lexer, filename, open_success)
    IF (.NOT. open_success) THEN
      CALL add_error(state, 0, "Cannot open file: " // TRIM(filename))
      RETURN
    END IF

    DO
      CALL kw_lexer_next_token(state%lexer, token)

      SELECT CASE (token%token_type)
      CASE (TOKEN_EOF)
        EXIT
      CASE (TOKEN_KEYWORD)
        CALL parse_keyword(state, token)
        IF (state%stop_on_error .AND. state%error_count > 0) EXIT
      CASE (TOKEN_COMMENT)
        CYCLE
      CASE (TOKEN_NEWLINE)
        CYCLE
      CASE DEFAULT
        CALL add_error(state, token%line_num, &
          "Unexpected token at line start: " // TRIM(token%value))
      END SELECT
    END DO

    CALL kw_lexer_close(state%lexer)
    success = (state%error_count == 0)
  END SUBROUTINE kw_parser_parse_file

  !-----------------------------------------------------------------
  ! SUBROUTINE: parse_keyword  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Parse a keyword and its content (params + data)
  !-----------------------------------------------------------------
  SUBROUTINE parse_keyword(state, keyword_token)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    TYPE(KW_TokenType), INTENT(IN)          :: keyword_token    ! [in]

    TYPE(KW_MetadataType), POINTER :: metadata
    TYPE(KW_ASTNodeType) :: node
    INTEGER(i4) :: node_id
    LOGICAL     :: is_end_keyword
    CHARACTER(LEN=KW_MAX_NAME_LEN) :: kw_name

    kw_name = TRIM(keyword_token%value)

    is_end_keyword = (kw_name(1:3) == "END" .OR. kw_name(1:4) == "END ")
    IF (is_end_keyword) THEN
      CALL handle_end_keyword(state, kw_name, keyword_token%line_num)
      RETURN
    END IF

    CALL kw_init_ast_node(node)
    node%keyword_name = kw_name
    node%start_line   = keyword_token%line_num

    metadata => kw_registry_find(kw_name)
    IF (ASSOCIATED(metadata)) THEN
      node%category = metadata%category
    ELSE
      IF (state%validate_keywords) THEN
        CALL add_warning(state, keyword_token%line_num, &
          "Unknown keyword: *" // TRIM(kw_name))
      END IF
      node%category = KW_CAT_OTHER
    END IF

    CALL parse_parameters(state, node)

    IF (ASSOCIATED(metadata)) THEN
      IF (metadata%has_data_lines) THEN
        CALL parse_data_lines(state, node, metadata)
      END IF
    ELSE
      CALL parse_data_lines_unknown(state, node)
    END IF

    node%end_line = kw_lexer_get_line_num(state%lexer)

    CALL add_node(state, node, node_id)

    IF (ASSOCIATED(metadata)) THEN
      IF (metadata%requires_end) THEN
        CALL push_context(state, kw_name, node_id)
      END IF
    END IF

    CALL set_parent_context(state, node, node_id)
  END SUBROUTINE parse_keyword

  !-----------------------------------------------------------------
  ! SUBROUTINE: parse_parameters  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Parse parameters from keyword line
  !-----------------------------------------------------------------
  SUBROUTINE parse_parameters(state, node)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    TYPE(KW_ASTNodeType), INTENT(INOUT)     :: node             ! [inout]

    TYPE(KW_TokenType) :: token
    CHARACTER(LEN=KW_MAX_NAME_LEN)  :: param_name
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: param_value
    LOGICAL :: expect_value

    param_name   = ""
    param_value  = ""
    expect_value = .FALSE.

    DO
      CALL kw_lexer_next_token(state%lexer, token)

      SELECT CASE (token%token_type)
      CASE (TOKEN_EOF, TOKEN_NEWLINE, TOKEN_KEYWORD)
        IF (token%token_type == TOKEN_KEYWORD) THEN
          CALL kw_lexer_push_back(state%lexer, token)
        END IF
        IF (LEN_TRIM(param_name) > 0 .AND. expect_value) THEN
          CALL add_parameter(node, param_name, "YES")
        ELSE IF (LEN_TRIM(param_name) > 0) THEN
          CALL add_parameter(node, param_name, param_value)
        END IF
        EXIT

      CASE (TOKEN_COMMA)
        IF (LEN_TRIM(param_name) > 0 .AND. .NOT. expect_value) THEN
          CALL add_parameter(node, param_name, param_value)
        ELSE IF (LEN_TRIM(param_name) > 0) THEN
          CALL add_parameter(node, param_name, "YES")
        END IF
        param_name   = ""
        param_value  = ""
        expect_value = .FALSE.

      CASE (TOKEN_EQUALS)
        expect_value = .TRUE.

      CASE (TOKEN_DATA)
        IF (LEN_TRIM(param_name) == 0) THEN
          param_name = kw_to_upper(TRIM(token%value))
        ELSE IF (expect_value) THEN
          param_value = TRIM(token%value)
          CALL add_parameter(node, param_name, param_value)
          param_name   = ""
          param_value  = ""
          expect_value = .FALSE.
        ELSE
          CALL add_parameter(node, param_name, "YES")
          param_name = kw_to_upper(TRIM(token%value))
        END IF

      CASE DEFAULT
        CYCLE
      END SELECT
    END DO
  END SUBROUTINE parse_parameters

  !-----------------------------------------------------------------
  ! SUBROUTINE: add_parameter  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Add parameter name/value pair to AST node
  !-----------------------------------------------------------------
  SUBROUTINE add_parameter(node, name, value)
    TYPE(KW_ASTNodeType), INTENT(INOUT) :: node                 ! [inout]
    CHARACTER(LEN=*), INTENT(IN)        :: name, value          ! [in]

    INTEGER(i4) :: idx, ios

    IF (node%param_count >= KW_MAX_PARAMS) RETURN

    idx = node%param_count + 1
    node%param_count = idx

    node%params(idx)%name   = TRIM(name)
    node%params(idx)%value  = TRIM(value)
    node%params(idx)%is_set = .TRUE.

    READ(value, *, IOSTAT=ios) node%params(idx)%int_value
    READ(value, *, IOSTAT=ios) node%params(idx)%real_value
  END SUBROUTINE add_parameter

  !-----------------------------------------------------------------
  ! SUBROUTINE: parse_data_lines  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Parse data lines following a keyword
  !-----------------------------------------------------------------
  SUBROUTINE parse_data_lines(state, node, metadata)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    TYPE(KW_ASTNodeType), INTENT(INOUT)     :: node             ! [inout]
    TYPE(KW_MetadataType), INTENT(IN)       :: metadata         ! [in]

    TYPE(KW_TokenType)    :: token
    TYPE(KW_DataLineType), ALLOCATABLE :: temp_lines(:)
    TYPE(KW_DataLineType) :: current_line
    INTEGER(i4) :: line_count, max_lines, col_idx
    INTEGER(i4) :: ios
    REAL(wp)    :: tmp_real
    LOGICAL     :: in_data_line

    line_count   = 0
    max_lines    = 1000
    ALLOCATE(temp_lines(max_lines))
    in_data_line = .FALSE.
    col_idx      = 0

    DO
      CALL kw_lexer_next_token(state%lexer, token)

      SELECT CASE (token%token_type)
      CASE (TOKEN_EOF)
        EXIT
      CASE (TOKEN_KEYWORD)
        IF (in_data_line .AND. col_idx > 0) THEN
          current_line%col_count = col_idx
          line_count = line_count + 1
          IF (line_count <= max_lines) temp_lines(line_count) = current_line
        END IF
        CALL kw_lexer_push_back(state%lexer, token)
        EXIT
      CASE (TOKEN_COMMENT)
        CYCLE
      CASE (TOKEN_NEWLINE)
        IF (in_data_line .AND. col_idx > 0) THEN
          current_line%col_count = col_idx
          line_count = line_count + 1
          IF (line_count <= max_lines) temp_lines(line_count) = current_line
        END IF
        in_data_line = .FALSE.
        col_idx = 0
      CASE (TOKEN_COMMA)
        CYCLE
      CASE (TOKEN_DATA)
        IF (.NOT. in_data_line) THEN
          in_data_line           = .TRUE.
          current_line%line_num  = token%line_num
          current_line%col_count = 0
          current_line%real_count = 0
          current_line%values     = ""
          current_line%real_values = 0.0_wp
          current_line%int_values  = 0
          col_idx = 0
        END IF

        col_idx = col_idx + 1
        IF (col_idx <= KW_MAX_DATA_COLS) THEN
          current_line%values(col_idx) = TRIM(token%value)
          tmp_real = 0.0_wp
          READ(token%value, *, IOSTAT=ios) tmp_real
          IF (ios == 0) THEN
            current_line%real_count = current_line%real_count + 1
          END IF
          CALL convert_data_value(token%value, &
            current_line%int_values(col_idx), &
            current_line%real_values(col_idx))
        END IF
      CASE DEFAULT
        CYCLE
      END SELECT
    END DO

    IF (line_count > 0) THEN
      node%data_line_count = line_count
      ALLOCATE(node%data_lines(line_count))
      node%data_lines(1:line_count) = temp_lines(1:line_count)
    END IF

    DEALLOCATE(temp_lines)
  END SUBROUTINE parse_data_lines

  !-----------------------------------------------------------------
  ! SUBROUTINE: parse_data_lines_unknown  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Parse data lines for unknown keyword
  !-----------------------------------------------------------------
  SUBROUTINE parse_data_lines_unknown(state, node)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    TYPE(KW_ASTNodeType), INTENT(INOUT)     :: node             ! [inout]

    TYPE(KW_MetadataType) :: dummy_meta

    dummy_meta%has_data_lines    = .TRUE.
    dummy_meta%min_data_lines    = 0
    dummy_meta%max_data_lines    = 0
    dummy_meta%data_cols_per_line = 0
    CALL parse_data_lines(state, node, dummy_meta)
  END SUBROUTINE parse_data_lines_unknown

  !-----------------------------------------------------------------
  ! SUBROUTINE: convert_data_value  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Convert string value to integer and real
  !-----------------------------------------------------------------
  SUBROUTINE convert_data_value(str, int_val, real_val)
    CHARACTER(LEN=*), INTENT(IN)  :: str                        ! [in]
    INTEGER(i4), INTENT(OUT)      :: int_val                    ! [out]
    REAL(wp), INTENT(OUT)         :: real_val                   ! [out]

    INTEGER(i4) :: ios

    int_val  = 0
    real_val = 0.0_wp
    READ(str, *, IOSTAT=ios) real_val
    IF (ios == 0) int_val = NINT(real_val)
  END SUBROUTINE convert_data_value

  !-----------------------------------------------------------------
  ! SUBROUTINE: handle_end_keyword  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Handle END keyword (pop context)
  !-----------------------------------------------------------------
  SUBROUTINE handle_end_keyword(state, kw_name, line_num)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    CHARACTER(LEN=*), INTENT(IN)            :: kw_name          ! [in]
    INTEGER(i4), INTENT(IN)                 :: line_num         ! [in]

    CHARACTER(LEN=KW_MAX_NAME_LEN) :: base_name

    IF (LEN_TRIM(kw_name) > 4) THEN
      base_name = ADJUSTL(kw_name(4:))
    ELSE
      base_name = ""
    END IF
    CALL pop_context(state, base_name, line_num)
  END SUBROUTINE handle_end_keyword

  !-----------------------------------------------------------------
  ! SUBROUTINE: push_context  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Push context for nested block keywords
  !-----------------------------------------------------------------
  SUBROUTINE push_context(state, kw_name, node_id)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    CHARACTER(LEN=*), INTENT(IN)            :: kw_name          ! [in]
    INTEGER(i4), INTENT(IN)                 :: node_id          ! [in]

    SELECT CASE (TRIM(kw_name))
    CASE ("STEP");     state%current_step_id     = node_id
    CASE ("MATERIAL"); state%current_material_id = node_id
    CASE ("PART");     state%current_part_id     = node_id
    CASE ("ASSEMBLY"); state%current_parent_id   = node_id
    CASE ("INSTANCE"); state%current_parent_id   = node_id
    END SELECT
  END SUBROUTINE push_context

  !-----------------------------------------------------------------
  ! SUBROUTINE: pop_context  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Pop context for END keywords
  !-----------------------------------------------------------------
  SUBROUTINE pop_context(state, base_name, line_num)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    CHARACTER(LEN=*), INTENT(IN)            :: base_name        ! [in]
    INTEGER(i4), INTENT(IN)                 :: line_num         ! [in]

    SELECT CASE (TRIM(base_name))
    CASE ("STEP")
      IF (state%current_step_id == 0) THEN
        CALL add_error(state, line_num, "END STEP without matching STEP")
      END IF
      state%current_step_id = 0
    CASE ("MATERIAL")
      state%current_material_id = 0
    CASE ("PART")
      IF (state%current_part_id == 0) THEN
        CALL add_error(state, line_num, "END PART without matching PART")
      END IF
      state%current_part_id = 0
    CASE ("ASSEMBLY")
      state%current_parent_id = 0
    CASE ("INSTANCE")
      state%current_parent_id = 0
    END SELECT
  END SUBROUTINE pop_context

  !-----------------------------------------------------------------
  ! SUBROUTINE: set_parent_context  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Set parent-child relationship for AST node
  !-----------------------------------------------------------------
  SUBROUTINE set_parent_context(state, node, node_id)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    TYPE(KW_ASTNodeType), INTENT(INOUT)     :: node             ! [inout]
    INTEGER(i4), INTENT(IN)                 :: node_id          ! [in]

    INTEGER(i4) :: parent_id

    parent_id = 0
    SELECT CASE (node%category)
    CASE (KW_CAT_MATERIAL)
      IF (TRIM(node%keyword_name) /= "MATERIAL") THEN
        parent_id = state%current_material_id
      END IF
    CASE (KW_CAT_STEP)
      IF (TRIM(node%keyword_name) /= "STEP") THEN
        parent_id = state%current_step_id
      END IF
    CASE (KW_CAT_LOAD, KW_CAT_CONSTRAINT, KW_CAT_OUTPUT)
      parent_id = state%current_step_id
    END SELECT

    IF (parent_id > 0 .AND. parent_id <= state%node_count) THEN
      state%nodes(node_id)%parent_id = parent_id
      CALL add_child_to_node(state, parent_id, node_id)
    END IF
  END SUBROUTINE set_parent_context

  !-----------------------------------------------------------------
  ! SUBROUTINE: add_node  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Add node to AST storage
  !-----------------------------------------------------------------
  SUBROUTINE add_node(state, node, node_id)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    TYPE(KW_ASTNodeType), INTENT(IN)        :: node             ! [in]
    INTEGER(i4), INTENT(OUT)                :: node_id          ! [out]

    IF (state%node_count >= state%max_nodes) THEN
      CALL add_error(state, node%start_line, "AST node limit exceeded")
      node_id = 0
      RETURN
    END IF

    state%node_count = state%node_count + 1
    node_id = state%node_count
    state%nodes(node_id) = node
    state%nodes(node_id)%node_id = node_id
  END SUBROUTINE add_node

  !-----------------------------------------------------------------
  ! SUBROUTINE: add_child_to_node  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Add child ID to parent node
  !-----------------------------------------------------------------
  SUBROUTINE add_child_to_node(state, parent_id, child_id)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    INTEGER(i4), INTENT(IN)                 :: parent_id        ! [in]
    INTEGER(i4), INTENT(IN)                 :: child_id         ! [in]

    INTEGER(i4) :: idx

    IF (parent_id <= 0 .OR. parent_id > state%node_count) RETURN
    IF (state%nodes(parent_id)%child_count >= KW_MAX_CHILDREN) RETURN

    idx = state%nodes(parent_id)%child_count + 1
    state%nodes(parent_id)%child_count = idx
    state%nodes(parent_id)%child_ids(idx) = child_id
  END SUBROUTINE add_child_to_node

  !-----------------------------------------------------------------
  ! SUBROUTINE: add_error  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Record parse error
  !-----------------------------------------------------------------
  SUBROUTINE add_error(state, line_num, message)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    INTEGER(i4), INTENT(IN)                 :: line_num         ! [in]
    CHARACTER(LEN=*), INTENT(IN)            :: message          ! [in]

    state%error_count = state%error_count + 1
    WRITE(*, '(A,I0,A,A)') "ERROR at line ", line_num, ": ", TRIM(message)
  END SUBROUTINE add_error

  !-----------------------------------------------------------------
  ! SUBROUTINE: add_warning  (PRIVATE)
  ! PHASE:      P1
  ! PURPOSE:    Record parse warning
  !-----------------------------------------------------------------
  SUBROUTINE add_warning(state, line_num, message)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    INTEGER(i4), INTENT(IN)                 :: line_num         ! [in]
    CHARACTER(LEN=*), INTENT(IN)            :: message          ! [in]

    state%warning_count = state%warning_count + 1
    WRITE(*, '(A,I0,A,A)') "WARNING at line ", line_num, ": ", TRIM(message)
  END SUBROUTINE add_warning

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_parser_get_ast
  ! PHASE:      P0
  ! PURPOSE:    Get copy of all parsed AST nodes
  !-----------------------------------------------------------------
  SUBROUTINE kw_parser_get_ast(state, nodes, count)
    TYPE(KW_ParserStateType), INTENT(IN)           :: state     ! [in]
    TYPE(KW_ASTNodeType), ALLOCATABLE, INTENT(OUT) :: nodes(:)  ! [out]
    INTEGER(i4), INTENT(OUT)                       :: count     ! [out]

    count = state%node_count
    IF (count > 0) THEN
      ALLOCATE(nodes(count))
      nodes = state%nodes(1:count)
    END IF
  END SUBROUTINE kw_parser_get_ast

  !-----------------------------------------------------------------
  ! FUNCTION:  kw_parser_get_node
  ! PHASE:     P0
  ! PURPOSE:   Get pointer to AST node by ID
  !-----------------------------------------------------------------
  FUNCTION kw_parser_get_node(state, node_id) RESULT(node_ptr)
    TYPE(KW_ParserStateType), INTENT(IN), TARGET :: state       ! [in]
    INTEGER(i4), INTENT(IN)                      :: node_id     ! [in]
    TYPE(KW_ASTNodeType), POINTER :: node_ptr

    NULLIFY(node_ptr)
    IF (node_id > 0 .AND. node_id <= state%node_count) THEN
      node_ptr => state%nodes(node_id)
    END IF
  END FUNCTION kw_parser_get_node

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_parser_get_root_nodes
  ! PHASE:      P0
  ! PURPOSE:    Get all root-level node IDs (no parent)
  !-----------------------------------------------------------------
  SUBROUTINE kw_parser_get_root_nodes(state, node_ids, count)
    TYPE(KW_ParserStateType), INTENT(IN)          :: state      ! [in]
    INTEGER(i4), ALLOCATABLE, INTENT(OUT)         :: node_ids(:)  ! [out]
    INTEGER(i4), INTENT(OUT)                      :: count      ! [out]

    INTEGER(i4) :: i, n
    INTEGER(i4) :: temp_ids(10000)

    n = 0
    DO i = 1, state%node_count
      IF (state%nodes(i)%parent_id == 0) THEN
        n = n + 1
        temp_ids(n) = i
      END IF
    END DO

    count = n
    IF (n > 0) THEN
      ALLOCATE(node_ids(n))
      node_ids = temp_ids(1:n)
    END IF
  END SUBROUTINE kw_parser_get_root_nodes

  !-----------------------------------------------------------------
  ! FUNCTION:  kw_parser_get_errors
  ! PHASE:     P0
  ! PURPOSE:   Get total error count
  !-----------------------------------------------------------------
  FUNCTION kw_parser_get_errors(state) RESULT(count)
    TYPE(KW_ParserStateType), INTENT(IN) :: state               ! [in]
    INTEGER(i4) :: count
    count = state%error_count
  END FUNCTION kw_parser_get_errors

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_parser_find_nodes_by_keyword
  ! PHASE:      P0
  ! PURPOSE:    Find all AST nodes matching a keyword name
  !-----------------------------------------------------------------
  SUBROUTINE kw_parser_find_nodes_by_keyword(state, keyword_name, node_ids, count)
    TYPE(KW_ParserStateType), INTENT(IN)  :: state              ! [in]
    CHARACTER(LEN=*), INTENT(IN)          :: keyword_name       ! [in]
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: node_ids(:)        ! [out]
    INTEGER(i4), INTENT(OUT)              :: count              ! [out]

    INTEGER(i4) :: i, n
    INTEGER(i4) :: temp_ids(10000)
    CHARACTER(LEN=KW_MAX_NAME_LEN) :: upper_name

    upper_name = kw_to_upper(TRIM(keyword_name))
    n = 0

    DO i = 1, state%node_count
      IF (TRIM(state%nodes(i)%keyword_name) == TRIM(upper_name)) THEN
        n = n + 1
        temp_ids(n) = i
      END IF
    END DO

    count = n
    IF (n > 0) THEN
      ALLOCATE(node_ids(n))
      node_ids = temp_ids(1:n)
    END IF
  END SUBROUTINE kw_parser_find_nodes_by_keyword

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_parser_cleanup
  ! PHASE:      P0
  ! PURPOSE:    Release parser resources
  !-----------------------------------------------------------------
  SUBROUTINE kw_parser_cleanup(state)
    TYPE(KW_ParserStateType), INTENT(INOUT) :: state            ! [inout]
    INTEGER(i4) :: i

    CALL kw_lexer_close(state%lexer)

    IF (ALLOCATED(state%nodes)) THEN
      DO i = 1, state%node_count
        IF (ALLOCATED(state%nodes(i)%data_lines)) THEN
          DEALLOCATE(state%nodes(i)%data_lines)
        END IF
      END DO
      DEALLOCATE(state%nodes)
    END IF

    state%node_count = 0
  END SUBROUTINE kw_parser_cleanup

END MODULE MD_KW_Parser
