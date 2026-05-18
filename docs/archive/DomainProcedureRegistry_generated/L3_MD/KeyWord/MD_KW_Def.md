# `MD_KW_Def.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_KW_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_KeyWordEntry` (lines 111–119)

```fortran
  TYPE, PUBLIC :: MD_KeyWordEntry
    CHARACTER(LEN=64) :: name           = ""       ! [in]  Keyword name (e.g. "NODE")
    INTEGER(i4)       :: category       = 0_i4     ! [in]  KW_CAT_* category
    INTEGER(i4)       :: priority       = 0_i4     ! [in]  P0/P1/P2
    INTEGER(i4)       :: n_params       = 0_i4     ! [in]  Number of parameters
    LOGICAL           :: has_data_lines = .FALSE.  ! [in]  Expects data lines
    LOGICAL           :: valid          = .FALSE.  ! [out] Registration flag
    LOGICAL           :: is_valid       = .FALSE.  ! [out] Alias
  END TYPE MD_KeyWordEntry
```

### `KW_TokenType` (lines 127–133)

```fortran
  TYPE :: KW_TokenType
    INTEGER(i4)                        :: token_type = TOKEN_INVALID  ! [out] Token type code
    CHARACTER(LEN=KW_MAX_VALUE_LEN)    :: value      = ""            ! [out] Token string value
    INTEGER(i4)                        :: line_num   = 0             ! [out] Source line number
    INTEGER(i4)                        :: col_num    = 0             ! [out] Source column number
    LOGICAL                            :: is_quoted  = .FALSE.       ! [out] Was value in quotes?
  END TYPE KW_TokenType
```

### `KW_ParamDefType` (lines 141–148)

```fortran
  TYPE :: KW_ParamDefType
    CHARACTER(LEN=KW_MAX_NAME_LEN)  :: name          = ""           ! [in] Parameter name
    INTEGER(i4)                     :: param_type    = PARAM_TYPE_STRING  ! [in] Expected type
    LOGICAL                         :: is_required   = .FALSE.      ! [in] Mandatory?
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: default_value = ""           ! [in] Default value
    CHARACTER(LEN=KW_MAX_DESC_LEN)  :: description   = ""           ! [in] Description
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: enum_values   = ""           ! [in] Valid enum values
  END TYPE KW_ParamDefType
```

### `KW_ParamValueType` (lines 156–162)

```fortran
  TYPE :: KW_ParamValueType
    CHARACTER(LEN=KW_MAX_NAME_LEN)  :: name       = ""              ! [out] Parameter name
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: value      = ""              ! [out] Parameter value
    INTEGER(i4)                     :: int_value  = 0               ! [out] Converted integer
    REAL(wp)                        :: real_value = 0.0_wp          ! [out] Converted real
    LOGICAL                         :: is_set     = .FALSE.         ! [out] Explicitly set?
  END TYPE KW_ParamValueType
```

### `KW_MetadataType` (lines 170–195)

```fortran
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
```

### `KW_DataLineType` (lines 203–210)

```fortran
  TYPE :: KW_DataLineType
    INTEGER(i4) :: line_num   = 0                                   ! [out] Source line number
    INTEGER(i4) :: col_count  = 0                                   ! [out] Number of columns
    INTEGER(i4) :: real_count = 0                                   ! [out] Parsed real count
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: values(KW_MAX_DATA_COLS) = ""  ! [out] String values
    REAL(wp)    :: real_values(KW_MAX_DATA_COLS) = 0.0_wp           ! [out] Converted reals
    INTEGER(i4) :: int_values(KW_MAX_DATA_COLS)  = 0                ! [out] Converted integers
  END TYPE KW_DataLineType
```

### `KW_ASTNodeType` (lines 218–241)

```fortran
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
```

### `KW_LexerStateType` (lines 249–274)

```fortran
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
```

### `KW_ParserStateType` (lines 282–306)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `kw_category_name` | 315 | `FUNCTION kw_category_name(category) RESULT(name)` |
| SUBROUTINE | `kw_init_ast_node` | 342 | `SUBROUTINE kw_init_ast_node(node)` |
| SUBROUTINE | `kw_init_param_value` | 369 | `SUBROUTINE kw_init_param_value(param)` |
| SUBROUTINE | `kw_init_token` | 384 | `SUBROUTINE kw_init_token(token)` |
| FUNCTION | `kw_to_upper` | 399 | `FUNCTION kw_to_upper(str) RESULT(upper_str)` |
| FUNCTION | `kw_token_type_name` | 418 | `FUNCTION kw_token_type_name(token_type) RESULT(name)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
