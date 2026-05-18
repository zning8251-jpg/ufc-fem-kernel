!===================================================================
! MODULE:  MD_KW_Def
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Def
! BRIEF:   Core type definitions and constants for keyword parsing.
!          Re-exports four-type (Desc/State/Algo/Ctx) from
!          MD_KeyWord_Def. Defines token, AST, lexer, parser types.
!===================================================================
MODULE MD_KW_Def
  USE IF_Err_Brg,     ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core,   ONLY: wp, i4, i8
  USE MD_KeyWord_Def, ONLY: MD_KW_Desc, MD_KW_State, &
                             MD_KW_Algo, MD_KW_Ctx
  IMPLICIT NONE
  PRIVATE

  ! Re-export four-type definitions from MD_KeyWord_Def
  PUBLIC :: MD_KW_Desc, MD_KW_State, MD_KW_Algo, MD_KW_Ctx

  !-----------------------------------------------------------------
  ! Constants - String length limits
  !-----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: KW_MAX_NAME_LEN  = 64      ! Keyword name max length
  INTEGER(i4), PARAMETER, PUBLIC :: KW_MAX_VALUE_LEN = 256     ! Parameter value max length
  INTEGER(i4), PARAMETER, PUBLIC :: KW_MAX_LINE_LEN  = 8192    ! Max line (with continuation)
  INTEGER(i4), PARAMETER, PUBLIC :: KW_MAX_DESC_LEN  = 512     ! Description max length
  INTEGER(i4), PARAMETER, PUBLIC :: KW_MAX_PARAMS    = 32      ! Max params per keyword
  INTEGER(i4), PARAMETER, PUBLIC :: KW_MAX_CHILDREN  = 64      ! Max child keywords
  INTEGER(i4), PARAMETER, PUBLIC :: KW_MAX_DATA_COLS = 32      ! Max data columns per line

  !-----------------------------------------------------------------
  ! Constants - Token types
  !-----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_EOF          = 0      ! End of file
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_KEYWORD      = 1      ! *KEYWORD
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_PARAM_NAME   = 2      ! Parameter name
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_PARAM_VALUE  = 3      ! Parameter value
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_DATA         = 4      ! Data line value
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_COMMENT      = 5      ! ** comment
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_COMMA        = 6      ! Separator
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_EQUALS       = 7      ! =
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_NEWLINE      = 8      ! End of logical line
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_CONTINUATION = 9      ! Line continuation
  INTEGER(i4), PARAMETER, PUBLIC :: TOKEN_INVALID      = -1     ! Invalid token

  !-----------------------------------------------------------------
  ! Constants - Keyword categories
  !-----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_MODEL      = 1      ! Model definition
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_PART       = 2      ! Part/Instance
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_MESH       = 3      ! Mesh (NODE, ELEMENT, SET)
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_MATERIAL   = 4      ! Material properties
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_SECTION    = 5      ! Section assignment
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_CONSTRAINT = 6      ! Constraints (BC, TIE)
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_LOAD       = 7      ! Loads (CLOAD, DLOAD)
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_CONTACT    = 8      ! Contact definitions
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_STEP       = 9      ! Step control
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_OUTPUT     = 10     ! Output requests
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_AMPLITUDE  = 11     ! Amplitude definitions
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_SPECIAL    = 12     ! Special (INCLUDE, PARAM)
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_END        = 13     ! End keywords
  INTEGER(i4), PARAMETER, PUBLIC :: KW_CAT_OTHER      = 99     ! Other / Unknown

  !-----------------------------------------------------------------
  ! Constants - Core domain parameters
  !-----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_MAX_KEYWORDS = 512_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_NAME_LEN    = 64_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_LINE_LEN    = 8192_i4

  !-----------------------------------------------------------------
  ! Constants - Parameter types
  !-----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PARAM_TYPE_STRING   = 1    ! String value
  INTEGER(i4), PARAMETER, PUBLIC :: PARAM_TYPE_INTEGER  = 2    ! Integer value
  INTEGER(i4), PARAMETER, PUBLIC :: PARAM_TYPE_REAL     = 3    ! Real value
  INTEGER(i4), PARAMETER, PUBLIC :: PARAM_TYPE_ENUM     = 4    ! Enumeration
  INTEGER(i4), PARAMETER, PUBLIC :: PARAM_TYPE_LOGICAL  = 5    ! Logical (flag)
  INTEGER(i4), PARAMETER, PUBLIC :: PARAM_TYPE_NAME_REF = 6    ! Name reference

  !-----------------------------------------------------------------
  ! Public Types
  !-----------------------------------------------------------------
  PUBLIC :: KW_TokenType
  PUBLIC :: KW_ParamDefType
  PUBLIC :: KW_ParamValueType
  PUBLIC :: KW_MetadataType
  PUBLIC :: KW_DataLineType
  PUBLIC :: KW_ASTNodeType
  PUBLIC :: KW_LexerStateType
  PUBLIC :: KW_ParserStateType
  PUBLIC :: MD_KeyWordEntry

  !-----------------------------------------------------------------
  ! Public Utility Functions
  !-----------------------------------------------------------------
  PUBLIC :: kw_token_type_name
  PUBLIC :: kw_category_name
  PUBLIC :: kw_init_token
  PUBLIC :: kw_init_param_value
  PUBLIC :: kw_init_ast_node
  PUBLIC :: kw_to_upper


  !-----------------------------------------------------------------
  ! TYPE:  MD_KeyWordEntry
  ! KIND:  Desc
  ! DESC:  Entry in the keyword registry (used by MD_KW_Core)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KeyWordEntry
    CHARACTER(LEN=64) :: name           = ""       ! [in]  Keyword name (e.g. "NODE")
    INTEGER(i4)       :: category       = 0_i4     ! [in]  KW_CAT_* category
    INTEGER(i4)       :: priority       = 0_i4     ! [in]  P0/P1/P2
    INTEGER(i4)       :: n_params       = 0_i4     ! [in]  Number of parameters
    LOGICAL           :: has_data_lines = .FALSE.  ! [in]  Expects data lines
    LOGICAL           :: valid          = .FALSE.  ! [out] Registration flag
    LOGICAL           :: is_valid       = .FALSE.  ! [out] Alias
  END TYPE MD_KeyWordEntry


  !-----------------------------------------------------------------
  ! TYPE:  KW_TokenType
  ! KIND:  Desc
  ! DESC:  Result of lexical analysis - one token
  !-----------------------------------------------------------------
  TYPE :: KW_TokenType
    INTEGER(i4)                        :: token_type = TOKEN_INVALID  ! [out] Token type code
    CHARACTER(LEN=KW_MAX_VALUE_LEN)    :: value      = ""            ! [out] Token string value
    INTEGER(i4)                        :: line_num   = 0             ! [out] Source line number
    INTEGER(i4)                        :: col_num    = 0             ! [out] Source column number
    LOGICAL                            :: is_quoted  = .FALSE.       ! [out] Was value in quotes?
  END TYPE KW_TokenType


  !-----------------------------------------------------------------
  ! TYPE:  KW_ParamDefType
  ! KIND:  Desc
  ! DESC:  Parameter specification for a keyword
  !-----------------------------------------------------------------
  TYPE :: KW_ParamDefType
    CHARACTER(LEN=KW_MAX_NAME_LEN)  :: name          = ""           ! [in] Parameter name
    INTEGER(i4)                     :: param_type    = PARAM_TYPE_STRING  ! [in] Expected type
    LOGICAL                         :: is_required   = .FALSE.      ! [in] Mandatory?
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: default_value = ""           ! [in] Default value
    CHARACTER(LEN=KW_MAX_DESC_LEN)  :: description   = ""           ! [in] Description
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: enum_values   = ""           ! [in] Valid enum values
  END TYPE KW_ParamDefType


  !-----------------------------------------------------------------
  ! TYPE:  KW_ParamValueType
  ! KIND:  Desc
  ! DESC:  Parsed parameter value from INP file
  !-----------------------------------------------------------------
  TYPE :: KW_ParamValueType
    CHARACTER(LEN=KW_MAX_NAME_LEN)  :: name       = ""              ! [out] Parameter name
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: value      = ""              ! [out] Parameter value
    INTEGER(i4)                     :: int_value  = 0               ! [out] Converted integer
    REAL(wp)                        :: real_value = 0.0_wp          ! [out] Converted real
    LOGICAL                         :: is_set     = .FALSE.         ! [out] Explicitly set?
  END TYPE KW_ParamValueType


  !-----------------------------------------------------------------
  ! TYPE:  KW_MetadataType
  ! KIND:  Desc
  ! DESC:  Complete keyword specification / metadata
  !-----------------------------------------------------------------
  TYPE :: KW_MetadataType
    CHARACTER(LEN=KW_MAX_NAME_LEN)  :: keyword_name = ""            ! [in] Keyword name (no *)
    INTEGER(i4)                     :: category = KW_CAT_OTHER      ! [in] Category
    INTEGER(i4)                     :: keyword_level = 0            ! [in] Nesting level
    CHARACTER(LEN=KW_MAX_DESC_LEN)  :: description = ""             ! [in] Description

    ! Parameter specifications
    INTEGER(i4)            :: param_count = 0                       ! [in] Defined param count
    TYPE(KW_ParamDefType)  :: params(KW_MAX_PARAMS)                 ! [in] Param definitions

    ! Data line specifications
    LOGICAL     :: has_data_lines    = .FALSE.                      ! [in] Expects data lines?
    INTEGER(i4) :: min_data_lines    = 0                            ! [in] Min data lines
    INTEGER(i4) :: max_data_lines    = 0                            ! [in] Max (0=unlimited)
    INTEGER(i4) :: data_cols_per_line = 0                           ! [in] Columns per line

    ! Hierarchy specifications
    LOGICAL     :: requires_end      = .FALSE.                      ! [in] Needs *END?
    CHARACTER(LEN=KW_MAX_NAME_LEN) :: end_keyword = ""              ! [in] End keyword name
    INTEGER(i4) :: valid_parent_count = 0                           ! [in] Valid parent count
    CHARACTER(LEN=KW_MAX_NAME_LEN) :: valid_parents(KW_MAX_CHILDREN) = ""

    ! Flags
    LOGICAL     :: is_deprecated = .FALSE.                          ! [in] Deprecated?
    LOGICAL     :: is_registered = .FALSE.                          ! [out] Registered?
  END TYPE KW_MetadataType


  !-----------------------------------------------------------------
  ! TYPE:  KW_DataLineType
  ! KIND:  Desc
  ! DESC:  Parsed data line from INP file
  !-----------------------------------------------------------------
  TYPE :: KW_DataLineType
    INTEGER(i4) :: line_num   = 0                                   ! [out] Source line number
    INTEGER(i4) :: col_count  = 0                                   ! [out] Number of columns
    INTEGER(i4) :: real_count = 0                                   ! [out] Parsed real count
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: values(KW_MAX_DATA_COLS) = ""  ! [out] String values
    REAL(wp)    :: real_values(KW_MAX_DATA_COLS) = 0.0_wp           ! [out] Converted reals
    INTEGER(i4) :: int_values(KW_MAX_DATA_COLS)  = 0                ! [out] Converted integers
  END TYPE KW_DataLineType


  !-----------------------------------------------------------------
  ! TYPE:  KW_ASTNodeType
  ! KIND:  Desc
  ! DESC:  Abstract Syntax Tree node for parsed keyword
  !-----------------------------------------------------------------
  TYPE :: KW_ASTNodeType
    INTEGER(i4)                     :: node_id      = 0             ! [out] Unique node ID
    CHARACTER(LEN=KW_MAX_NAME_LEN)  :: keyword_name = ""            ! [out] Keyword name (no *)
    INTEGER(i4)                     :: category = KW_CAT_OTHER      ! [out] Category
    INTEGER(i4)                     :: start_line   = 0             ! [out] Start line
    INTEGER(i4)                     :: end_line     = 0             ! [out] End line

    ! Parameters
    INTEGER(i4)            :: param_count = 0                       ! [out] Param count
    TYPE(KW_ParamValueType) :: params(KW_MAX_PARAMS)                ! [out] Param values

    ! Data lines
    INTEGER(i4)                      :: data_line_count = 0         ! [out] Data line count
    TYPE(KW_DataLineType), ALLOCATABLE :: data_lines(:)             ! [out] Data lines

    ! Tree structure (index-based)
    INTEGER(i4) :: parent_id   = 0                                  ! [out] Parent (0=root)
    INTEGER(i4) :: child_count = 0                                  ! [out] Child count
    INTEGER(i4) :: child_ids(KW_MAX_CHILDREN) = 0                   ! [out] Child node IDs

    ! Validation
    LOGICAL     :: is_valid    = .TRUE.                             ! [out] Passed validation?
    CHARACTER(LEN=KW_MAX_DESC_LEN) :: error_msg = ""                ! [out] Error message
  END TYPE KW_ASTNodeType


  !-----------------------------------------------------------------
  ! TYPE:  KW_LexerStateType
  ! KIND:  State
  ! DESC:  Lexical analyzer runtime state
  !-----------------------------------------------------------------
  TYPE :: KW_LexerStateType
    ! File handling
    INTEGER(i4)        :: file_unit    = 0                          ! [inout] File unit
    CHARACTER(LEN=512) :: filename     = ""                         ! [in]    Input filename
    LOGICAL            :: file_open    = .FALSE.                    ! [inout] File open?

    ! Current position
    INTEGER(i4)        :: current_line = 0                          ! [inout] Current line
    INTEGER(i4)        :: current_col  = 1                          ! [inout] Current column
    CHARACTER(LEN=KW_MAX_LINE_LEN) :: line_buffer = ""              ! [inout] Line content
    INTEGER(i4)        :: buffer_len   = 0                          ! [inout] Buffer length
    INTEGER(i4)        :: buffer_pos   = 1                          ! [inout] Buffer position

    ! State flags
    LOGICAL            :: at_eof          = .FALSE.                 ! [inout] At EOF?
    LOGICAL            :: in_continuation = .FALSE.                 ! [inout] Continuation?
    LOGICAL            :: case_sensitive  = .FALSE.                 ! [in]    Case-sensitive?

    ! Token pushback
    TYPE(KW_TokenType) :: pushed_token                              ! [inout] Pushed token
    LOGICAL            :: has_pushed_token = .FALSE.                ! [inout] Has pushed?

    ! Statistics
    INTEGER(i4)        :: total_lines  = 0                          ! [out] Total lines read
    INTEGER(i4)        :: total_tokens = 0                          ! [out] Total tokens
  END TYPE KW_LexerStateType


  !-----------------------------------------------------------------
  ! TYPE:  KW_ParserStateType
  ! KIND:  State
  ! DESC:  Syntax analyzer runtime state
  !-----------------------------------------------------------------
  TYPE :: KW_ParserStateType
    ! Lexer reference
    TYPE(KW_LexerStateType) :: lexer                                ! [inout] Lexer state

    ! AST storage
    INTEGER(i4) :: node_count = 0                                   ! [out] AST node count
    INTEGER(i4) :: max_nodes  = 1000000                             ! [in]  Max capacity
    TYPE(KW_ASTNodeType), ALLOCATABLE :: nodes(:)                   ! [out] AST nodes

    ! Parse context
    INTEGER(i4) :: current_parent_id   = 0                          ! [inout] Current parent
    INTEGER(i4) :: current_step_id     = 0                          ! [inout] Current *STEP
    INTEGER(i4) :: current_material_id = 0                          ! [inout] Current *MATERIAL
    INTEGER(i4) :: current_part_id     = 0                          ! [inout] Current *PART

    ! Error tracking
    INTEGER(i4) :: error_count   = 0                                ! [out] Parse errors
    INTEGER(i4) :: warning_count = 0                                ! [out] Warnings
    LOGICAL     :: stop_on_error = .FALSE.                          ! [in]  Stop on error?

    ! Options
    LOGICAL     :: validate_keywords  = .TRUE.                      ! [in] Validate keywords?
    LOGICAL     :: validate_params    = .TRUE.                      ! [in] Validate params?
    LOGICAL     :: validate_hierarchy = .TRUE.                      ! [in] Validate hierarchy?
  END TYPE KW_ParserStateType

CONTAINS

  !-----------------------------------------------------------------
  ! FUNCTION:  kw_category_name
  ! PHASE:     P0
  ! PURPOSE:   Convert category code to human-readable name
  !-----------------------------------------------------------------
  FUNCTION kw_category_name(category) RESULT(name)
    INTEGER(i4), INTENT(IN) :: category
    CHARACTER(LEN=16)       :: name

    SELECT CASE (category)
      CASE (KW_CAT_MODEL);      name = "MODEL"
      CASE (KW_CAT_PART);       name = "PART"
      CASE (KW_CAT_MESH);       name = "MESH"
      CASE (KW_CAT_MATERIAL);   name = "MATERIAL"
      CASE (KW_CAT_SECTION);    name = "SECTION"
      CASE (KW_CAT_CONSTRAINT); name = "CONSTRAINT"
      CASE (KW_CAT_LOAD);       name = "LOAD"
      CASE (KW_CAT_CONTACT);    name = "CONTACT"
      CASE (KW_CAT_STEP);       name = "STEP"
      CASE (KW_CAT_OUTPUT);     name = "OUTPUT"
      CASE (KW_CAT_AMPLITUDE);  name = "AMPLITUDE"
      CASE (KW_CAT_SPECIAL);    name = "SPECIAL"
      CASE (KW_CAT_END);        name = "END"
      CASE DEFAULT;              name = "OTHER"
    END SELECT
  END FUNCTION kw_category_name

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_init_ast_node
  ! PHASE:      P0
  ! PURPOSE:    Initialize an AST node to default state
  !-----------------------------------------------------------------
  SUBROUTINE kw_init_ast_node(node)
    TYPE(KW_ASTNodeType), INTENT(OUT) :: node
    INTEGER(i4) :: i

    node%node_id       = 0
    node%keyword_name  = ""
    node%category      = KW_CAT_OTHER
    node%start_line    = 0
    node%end_line      = 0
    node%param_count   = 0
    DO i = 1, KW_MAX_PARAMS
      CALL kw_init_param_value(node%params(i))
    END DO
    node%data_line_count = 0
    IF (ALLOCATED(node%data_lines)) DEALLOCATE(node%data_lines)
    node%parent_id   = 0
    node%child_count = 0
    node%child_ids   = 0
    node%is_valid    = .TRUE.
    node%error_msg   = ""
  END SUBROUTINE kw_init_ast_node

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_init_param_value
  ! PHASE:      P0
  ! PURPOSE:    Initialize a parameter value to default state
  !-----------------------------------------------------------------
  SUBROUTINE kw_init_param_value(param)
    TYPE(KW_ParamValueType), INTENT(OUT) :: param

    param%name       = ""
    param%value      = ""
    param%int_value  = 0
    param%real_value = 0.0_wp
    param%is_set     = .FALSE.
  END SUBROUTINE kw_init_param_value

  !-----------------------------------------------------------------
  ! SUBROUTINE: kw_init_token
  ! PHASE:      P0
  ! PURPOSE:    Initialize a token to default state
  !-----------------------------------------------------------------
  SUBROUTINE kw_init_token(token)
    TYPE(KW_TokenType), INTENT(OUT) :: token

    token%token_type = TOKEN_INVALID
    token%value      = ""
    token%line_num   = 0
    token%col_num    = 0
    token%is_quoted  = .FALSE.
  END SUBROUTINE kw_init_token

  !-----------------------------------------------------------------
  ! FUNCTION:  kw_to_upper
  ! PHASE:     P0
  ! PURPOSE:   Convert string to uppercase
  !-----------------------------------------------------------------
  FUNCTION kw_to_upper(str) RESULT(upper_str)
    CHARACTER(LEN=*), INTENT(IN) :: str
    CHARACTER(LEN=LEN(str))      :: upper_str
    INTEGER(i4) :: i, ic

    upper_str = str
    DO i = 1, LEN_TRIM(str)
      ic = ICHAR(str(i:i))
      IF (ic >= ICHAR('a') .AND. ic <= ICHAR('z')) THEN
        upper_str(i:i) = CHAR(ic - 32)
      END IF
    END DO
  END FUNCTION kw_to_upper

  !-----------------------------------------------------------------
  ! FUNCTION:  kw_token_type_name
  ! PHASE:     P0
  ! PURPOSE:   Convert token type code to human-readable name
  !-----------------------------------------------------------------
  FUNCTION kw_token_type_name(token_type) RESULT(name)
    INTEGER(i4), INTENT(IN) :: token_type
    CHARACTER(LEN=16)       :: name

    SELECT CASE (token_type)
      CASE (TOKEN_EOF);          name = "EOF"
      CASE (TOKEN_KEYWORD);      name = "KEYWORD"
      CASE (TOKEN_PARAM_NAME);   name = "PARAM_NAME"
      CASE (TOKEN_PARAM_VALUE);  name = "PARAM_VALUE"
      CASE (TOKEN_DATA);         name = "DATA"
      CASE (TOKEN_COMMENT);      name = "COMMENT"
      CASE (TOKEN_COMMA);        name = "COMMA"
      CASE (TOKEN_EQUALS);       name = "EQUALS"
      CASE (TOKEN_NEWLINE);      name = "NEWLINE"
      CASE (TOKEN_CONTINUATION); name = "CONTINUATION"
      CASE (TOKEN_INVALID);      name = "INVALID"
      CASE DEFAULT;              name = "UNKNOWN"
    END SELECT
  END FUNCTION kw_token_type_name

END MODULE MD_KW_Def
