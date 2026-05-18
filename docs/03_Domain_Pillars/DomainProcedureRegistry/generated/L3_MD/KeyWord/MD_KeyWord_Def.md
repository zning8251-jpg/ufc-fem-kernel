# `MD_KeyWord_Def.f90`

- **Source**: `L3_MD/KeyWord/MD_KeyWord_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KeyWord_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KeyWord_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KeyWord`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KeyWord_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_KW_DescEntry` (lines 32–46)

```fortran
  TYPE, PUBLIC :: MD_KW_DescEntry
    CHARACTER(LEN=64)  :: kw_name        = ""       ! [in] Keyword name (e.g. "*NODE")
    CHARACTER(LEN=64)  :: name           = ""       ! [in] Alias for kw_name (Core compat)
    INTEGER(i4)        :: kw_category    = 0_i4     ! [in] KW_CAT_* category
    INTEGER(i4)        :: priority       = 0_i4     ! [in] P0/P1/P2 priority level
    INTEGER(i4)        :: n_params       = 0_i4     ! [in] Number of parameters
    CHARACTER(LEN=256) :: description    = ""       ! [in] Human-readable description
    CHARACTER(LEN=64)  :: parse_module   = ""       ! [in] Module providing parser
    CHARACTER(LEN=64)  :: parse_proc     = ""       ! [in] Procedure for parsing
    LOGICAL            :: has_validate   = .FALSE.  ! [in] Has validator?
    LOGICAL            :: has_data_lines = .FALSE.  ! [in] Expects data lines
    CHARACTER(LEN=64)  :: validate_proc  = ""       ! [in] Validation procedure
    LOGICAL            :: is_registered  = .FALSE.  ! [out] Registration flag
    LOGICAL            :: valid          = .FALSE.  ! [out] Valid flag (alias)
  END TYPE MD_KW_DescEntry
```

### `MD_KW_Desc` (lines 55–60)

```fortran
  TYPE, PUBLIC :: MD_KW_Desc
    INTEGER(i4)           :: n_registered = 0_i4                       ! [out] Count of registered entries
    INTEGER(i4)           :: n_keywords   = 0_i4                       ! [out] Alias (Core compat)
    TYPE(MD_KW_DescEntry) :: entries(MD_KW_MAX_REGISTERED)             ! [out] Entry array
    TYPE(MD_KW_DescEntry) :: keywords(MD_KW_MAX_REGISTERED)            ! [out] Alias array (Core compat)
  END TYPE MD_KW_Desc
```

### `MD_KW_State` (lines 68–79)

```fortran
  TYPE, PUBLIC :: MD_KW_State
    CHARACTER(LEN=64) :: current_keyword  = ""       ! [inout] Currently parsing keyword
    INTEGER(i4)       :: current_line     = 0_i4     ! [inout] Current line number
    INTEGER(i4)       :: current_col      = 0_i4     ! [inout] Current column number
    INTEGER(i4)       :: error_count      = 0_i4     ! [inout] Accumulated error count
    INTEGER(i4)       :: parse_errors     = 0_i4     ! [inout] Alias for error_count
    INTEGER(i4)       :: warning_count    = 0_i4     ! [inout] Accumulated warning count
    INTEGER(i4)       :: keywords_parsed  = 0_i4     ! [inout] Total keywords parsed
    LOGICAL           :: is_parsing       = .FALSE.  ! [inout] Currently in parse session
    LOGICAL           :: in_data_block    = .FALSE.  ! [inout] Inside data block
    LOGICAL           :: has_fatal_error  = .FALSE.  ! [inout] Fatal error occurred
  END TYPE MD_KW_State
```

### `MD_KW_Algo` (lines 87–95)

```fortran
  TYPE, PUBLIC :: MD_KW_Algo
    LOGICAL     :: strict_mode     = .FALSE.  ! [in] Strict: unknown keywords = ERROR
    LOGICAL     :: case_sensitive  = .FALSE.  ! [in] Case-sensitive matching
    INTEGER(i4) :: error_limit     = 100_i4   ! [in] Max errors before abort
    INTEGER(i4) :: warning_limit   = 500_i4   ! [in] Max warnings before suppress
    LOGICAL     :: allow_unknown   = .TRUE.   ! [in] Allow unregistered keywords
    LOGICAL     :: validate_params = .TRUE.   ! [in] Validate parameter types/ranges
    LOGICAL     :: recursive_parse = .TRUE.   ! [in] Enable recursive block parsing
  END TYPE MD_KW_Algo
```

### `MD_KW_Ctx` (lines 103–112)

```fortran
  TYPE, PUBLIC :: MD_KW_Ctx
    INTEGER(i4) :: parse_stage    = 0_i4     ! [inout] 0=idle, 1=lex, 2=parse, 3=map
    INTEGER(i4) :: ast_root_id   = 0_i4     ! [inout] AST root node ID
    INTEGER(i4) :: current_depth = 0_i4     ! [inout] Recursive parse depth
    INTEGER(i4) :: file_unit     = 0_i4     ! [inout] Input file unit number
    INTEGER(i4) :: total_lines   = 0_i4     ! [inout] Total lines read
    LOGICAL     :: in_step_block = .FALSE.  ! [inout] Inside *STEP block
    LOGICAL     :: in_part_block = .FALSE.  ! [inout] Inside *PART block
    LOGICAL     :: eof_reached   = .FALSE.  ! [inout] End-of-file reached
  END TYPE MD_KW_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
