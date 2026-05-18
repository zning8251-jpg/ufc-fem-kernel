# `AP_Input_Def.f90`

- **Source**: `L6_AP/Input/AP_Input_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Input_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Input_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Input`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Input`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/AP_Input_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Input_Desc` (lines 29–32)

```fortran
  TYPE :: AP_Input_Desc
    CHARACTER(LEN=256) :: file_path = ""     ! Input file path
    CHARACTER(LEN=32)  :: format    = "ABAQUS" ! File format tag
  END TYPE AP_Input_Desc
```

### `AP_Input_State` (lines 37–44)

```fortran
  TYPE :: AP_Input_State
    INTEGER(i4) :: lines_read   = 0          ! Total lines read
    INTEGER(i4) :: parse_errors = 0          ! Accumulated parse errors
    INTEGER(i4) :: n_keywords   = 0          ! Keywords recognised
    INTEGER(i4) :: n_tokens     = 0          ! Tokens produced by S1
    LOGICAL     :: is_complete  = .FALSE.    ! Parse finished flag
    LOGICAL     :: model_built  = .FALSE.    ! S4 BuildModel done flag
  END TYPE AP_Input_State
```

### `AP_Inp_Algo` (lines 49–55)

```fortran
  TYPE :: AP_Inp_Algo
    LOGICAL :: strict_mode    = .TRUE.       ! Abort on first error
    LOGICAL :: echo_keywords  = .FALSE.      ! Echo recognised keywords
    LOGICAL :: skip_comments  = .TRUE.       ! Skip ** comment lines
    INTEGER(i4) :: max_errors  = 100_i4      ! Error threshold before abort
    INTEGER(i4) :: verbosity   = 1_i4        ! 0=silent,1=normal,2=verbose
  END TYPE AP_Inp_Algo
```

### `AP_Inp_Arg` (lines 60–67)

```fortran
  TYPE :: AP_Inp_Arg
    INTEGER(i4) :: unit_id      = -1_i4      ! Fortran IO unit (set by S1)
    INTEGER(i4) :: current_line = 0_i4       ! Current line cursor
    INTEGER(i4) :: token_count  = 0_i4       ! Tokens produced by S1
    INTEGER(i4) :: kw_count     = 0_i4       ! Keywords parsed by S2
    CHARACTER(LEN=256) :: last_keyword = ''  ! Last keyword processed
    CHARACTER(LEN=512) :: diag_msg    = ''   ! Diagnostic message buffer
  END TYPE AP_Inp_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
