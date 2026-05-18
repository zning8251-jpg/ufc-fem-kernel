# `AP_Inp_Mgr.f90`

- **Source**: `L6_AP/Input/Parser/AP_Inp_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Inp_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Mgr`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Input/Parser`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Parser/AP_Inp_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Input_State` (lines 29–38)

```fortran
  TYPE, PUBLIC :: AP_Input_State
    INTEGER(i4) :: parseStatus     = AP_PARSE_NOT_STARTED
    INTEGER(i4) :: totalKeywords   = 0_i4
    INTEGER(i4) :: parsedKeywords  = 0_i4
    INTEGER(i4) :: nParseErrors    = 0_i4
    INTEGER(i4) :: nParseWarnings  = 0_i4
    INTEGER(i4) :: totalDataLines  = 0_i4
    INTEGER(i4) :: currentLine     = 0_i4
    REAL(wp)    :: parseTime       = 0.0_wp  ! wall-clock for parsing
  END TYPE AP_Input_State
```

### `AP_Input_Ctrl` (lines 40–47)

```fortran
  TYPE, PUBLIC :: AP_Input_Ctrl
    CHARACTER(LEN=512) :: inputFilePath  = ' '
    CHARACTER(LEN=256) :: jobName        = ' '
    INTEGER(i4)        :: validationLevel = 2_i4  ! 0=none, 1=basic, 2=full
    LOGICAL            :: echoInput      = .FALSE.  ! echo parsed input
    LOGICAL            :: strictMode     = .FALSE.  ! fail on warnings
    LOGICAL            :: continueOnError = .FALSE. ! skip bad keywords
  END TYPE AP_Input_Ctrl
```

### `AP_Input_Domain` (lines 49–68)

```fortran
  TYPE, PUBLIC :: AP_Input_Domain
    TYPE(AP_Input_State) :: state
    TYPE(AP_Input_Ctrl)  :: ctrl
    ! Flat domain storage (index tree + flat)
    TYPE(ParsedKeywordEntry), ALLOCATABLE :: parsed_keywords(:)
    TYPE(ParsedCommandEntry),  ALLOCATABLE :: parsed_commands(:)
    INTEGER(i4) :: n_keywords = 0_i4
    INTEGER(i4) :: n_commands = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: ParseKeyword
    PROCEDURE :: ValidateSyntax
    PROCEDURE :: GetSummary
    PROCEDURE :: AddParsedKeyword
    PROCEDURE :: AddParsedCommand
    PROCEDURE :: GetKeywordById
    PROCEDURE :: GetCmdById
  END TYPE AP_Input_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Input_Domain_Finalize` | 72 | `SUBROUTINE AP_Input_Domain_Finalize(this)` |
| SUBROUTINE | `AP_Input_Domain_Init` | 83 | `SUBROUTINE AP_Input_Domain_Init(this, status)` |
| SUBROUTINE | `AP_Input_Domain_ParseKeyword` | 99 | `SUBROUTINE AP_Input_Domain_ParseKeyword(this, keyword, status)` |
| SUBROUTINE | `AP_Input_Domain_ValidateSyntax` | 131 | `SUBROUTINE AP_Input_Domain_ValidateSyntax(this, isValid, status)` |
| SUBROUTINE | `AP_Input_Domain_GetSummary` | 162 | `SUBROUTINE AP_Input_Domain_GetSummary(this, summary, status)` |
| SUBROUTINE | `AP_Input_Domain_AddParsedKeyword` | 193 | `SUBROUTINE AP_Input_Domain_AddParsedKeyword(this, arg, status)` |
| SUBROUTINE | `AP_Input_Domain_AddParsedCommand` | 235 | `SUBROUTINE AP_Input_Domain_AddParsedCommand(this, arg, status)` |
| SUBROUTINE | `AP_Input_Domain_GetKeywordById` | 279 | `SUBROUTINE AP_Input_Domain_GetKeywordById(this, idx, entry, found)` |
| SUBROUTINE | `AP_Input_Domain_GetCmdById` | 299 | `SUBROUTINE AP_Input_Domain_GetCmdById(this, idx, entry, found)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
