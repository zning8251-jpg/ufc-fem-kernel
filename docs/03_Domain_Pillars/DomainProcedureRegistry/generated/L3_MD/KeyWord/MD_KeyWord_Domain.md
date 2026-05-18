# `MD_KeyWord_Domain.f90`

- **Source**: `L3_MD/KeyWord/MD_KeyWord_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KeyWord_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KeyWord_Domain`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KeyWord_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KeyWord_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_KW_KeywordDef_Desc` (lines 32–39)

```fortran
  TYPE, PUBLIC :: MD_KW_KeywordDef_Desc
    CHARACTER(LEN=KW_MAX_NAME_LEN) :: name = ""                 ! [in] Keyword name
    INTEGER(i4)                    :: category = 0_i4           ! [in] KW_CAT_*
    INTEGER(i4)                    :: priority = 0_i4           ! [in] P0/P1/P2
    INTEGER(i4)                    :: n_params = 0_i4           ! [in] Param count
    LOGICAL                        :: has_data_lines = .FALSE.  ! [in] Data lines?
    CHARACTER(LEN=64)              :: target_domain = ""        ! [in] Target domain
  END TYPE MD_KW_KeywordDef_Desc
```

### `MD_KW_DomainAlgo` (lines 48–54)

```fortran
  TYPE, PUBLIC :: MD_KW_DomainAlgo
    LOGICAL     :: strict_mode    = .TRUE.                      ! [in] Stop on first error
    LOGICAL     :: case_sensitive = .FALSE.                     ! [in] Case sensitivity
    INTEGER(i4) :: max_errors     = 100_i4                      ! [in] Max errors
    LOGICAL     :: audit_coverage = .TRUE.                      ! [in] Enable coverage audit
    INTEGER(i4) :: parse_priority = 0_i4                        ! [in] Current priority
  END TYPE MD_KW_DomainAlgo
```

### `MD_KW_DomainCtx` (lines 63–72)

```fortran
  TYPE, PUBLIC :: MD_KW_DomainCtx
    INTEGER(i4)   :: current_line_num  = 0_i4                   ! [inout] Current line
    INTEGER(i4)   :: current_col_num   = 0_i4                   ! [inout] Current column
    INTEGER(i4)   :: tokens_parsed     = 0_i4                   ! [out]   Tokens parsed
    INTEGER(i4)   :: keywords_parsed   = 0_i4                   ! [out]   Keywords parsed
    INTEGER(i4)   :: ast_nodes_created = 0_i4                   ! [out]   AST nodes
    CHARACTER(LEN=64) :: current_keyword = ""                   ! [inout] Current keyword
    LOGICAL       :: in_data_block     = .FALSE.                ! [inout] In data block
    INTEGER(i4)   :: last_error_line   = 0_i4                   ! [out]   Last error line
  END TYPE MD_KW_DomainCtx
```

### `MD_KW_ParseState` (lines 81–88)

```fortran
  TYPE, PUBLIC :: MD_KW_ParseState
    INTEGER(i4) :: n_keywords_parsed = 0_i4                     ! [out] Keywords parsed
    INTEGER(i4) :: n_ast_nodes       = 0_i4                     ! [out] AST node count
    INTEGER(i4) :: n_errors          = 0_i4                     ! [out] Error count
    INTEGER(i4) :: n_warnings        = 0_i4                     ! [out] Warning count
    LOGICAL     :: parse_complete    = .FALSE.                  ! [out] Parse done?
    TYPE(KW_Coverage_Report) :: coverage                        ! [out] Coverage report
  END TYPE MD_KW_ParseState
```

### `MD_KeyWord_Domain` (lines 97–128)

```fortran
  TYPE, PUBLIC :: MD_KeyWord_Domain
    ! Desc (Write-Once after parse)
    TYPE(MD_KW_KeywordDef_Desc), ALLOCATABLE   :: keywords(:)            ! [out]
    TYPE(KW_ASTNodeType), ALLOCATABLE :: ast_nodes(:)           ! [out]
    INTEGER(i4)                       :: n_keywords  = 0_i4     ! [out]
    INTEGER(i4)                       :: n_ast_nodes = 0_i4     ! [out]
    INTEGER(i4)                       :: root_node_idx = 0_i4   ! [out]

    ! State (Parse phase only)
    TYPE(MD_KW_ParseState)               :: state                  ! [inout]

    ! Algo (Parse configuration)
    TYPE(MD_KW_DomainAlgo)                      :: algo                   ! [in]

    ! Ctx (transient, not stored)
    TYPE(KW_LexerStateType)           :: lexer                  ! [inout]
    TYPE(KW_ParserStateType)          :: parser                 ! [inout]

    ! Internal
    LOGICAL                           :: initialized  = .FALSE. ! [out]
    LOGICAL                           :: parse_frozen = .FALSE. ! [out]
  CONTAINS
    PROCEDURE :: Init            => MD_KW_Domain_Init
    PROCEDURE :: Finalize        => MD_KW_Domain_Finalize
    PROCEDURE :: RegisterKeyword => MD_KW_Domain_RegisterKW
    PROCEDURE :: Parse           => MD_KW_Domain_Parse
    PROCEDURE :: GetKeyword      => MD_KW_Domain_GetKW
    PROCEDURE :: GetKeywordByName => MD_KW_Domain_GetKWByName
    PROCEDURE :: GetASTRoot      => MD_KW_Domain_GetASTRoot
    PROCEDURE :: AuditCoverage   => MD_KW_Domain_AuditCoverage
    PROCEDURE :: GetSummary      => MD_KW_Domain_GetSummary
  END TYPE MD_KeyWord_Domain
```

### `MD_KW_GetSummary_Arg` (lines 136–139)

```fortran
  TYPE, PUBLIC :: MD_KW_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""                       ! [out]
    TYPE(ErrorStatusType) :: status                             ! [out]
  END TYPE MD_KW_GetSummary_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_KW_Domain_Init` | 149 | `SUBROUTINE MD_KW_Domain_Init(this, max_keywords, max_ast_nodes, status)` |
| SUBROUTINE | `MD_KW_Domain_Finalize` | 179 | `SUBROUTINE MD_KW_Domain_Finalize(this)` |
| SUBROUTINE | `MD_KW_Domain_RegisterKW` | 199 | `SUBROUTINE MD_KW_Domain_RegisterKW(this, kw_def, status)` |
| SUBROUTINE | `MD_KW_Domain_Parse` | 233 | `SUBROUTINE MD_KW_Domain_Parse(this, inp_lines, n_lines, status)` |
| SUBROUTINE | `MD_KW_Domain_GetKW` | 276 | `SUBROUTINE MD_KW_Domain_GetKW(this, name, kw_def, found, status)` |
| SUBROUTINE | `MD_KW_Domain_GetASTRoot` | 310 | `SUBROUTINE MD_KW_Domain_GetASTRoot(this, root_idx, status)` |
| SUBROUTINE | `MD_KW_Domain_AuditCoverage` | 338 | `SUBROUTINE MD_KW_Domain_AuditCoverage(this, covered_keywords, status)` |
| SUBROUTINE | `MD_KW_Domain_GetKWByName` | 363 | `SUBROUTINE MD_KW_Domain_GetKWByName(this, name, kw_def, found, status)` |
| SUBROUTINE | `MD_KW_Domain_GetSummary` | 403 | `SUBROUTINE MD_KW_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `MD_KW_GetSummary_Impl` | 409 | `SUBROUTINE MD_KW_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
