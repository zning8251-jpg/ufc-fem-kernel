# `AP_UI_Mgr.f90`

- **Source**: `L6_AP/UI/AP_UI_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_UI_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_UI_Mgr`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_UI`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `UI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/UI/AP_UI_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_UI_Init_In` (lines 79–82)

```fortran
  TYPE, PUBLIC :: AP_UI_Init_In
    INTEGER(i4), OPTIONAL :: mode                    ! UI mode (UI_MODE_INTERACTIVE, UI_MODE_BATCH, UI_MODE_SILENT)
    LOGICAL, OPTIONAL :: use_color                    ! Use ANSI colors flag
  END TYPE AP_UI_Init_In
```

### `AP_UI_Init_Out` (lines 85–88)

```fortran
  TYPE, PUBLIC :: AP_UI_Init_Out
    TYPE(AP_UI_Ctrl_Type) :: ctrl                    ! UI control context (Ctx)
    TYPE(ErrorStatusType) :: status                  ! Error status
  END TYPE AP_UI_Init_Out
```

### `AP_UI_Progress_Init_In` (lines 91–95)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Init_In
    INTEGER(i4) :: total                             ! n_total  ?ℤ^+
    CHARACTER(len=256), OPTIONAL :: description      ! Progress description
    INTEGER(i4), OPTIONAL :: bar_width               ! w_bar  ?ℤ^+
  END TYPE AP_UI_Progress_Init_In
```

### `AP_UI_Progress_Init_Out` (lines 98–101)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Init_Out
    TYPE(AP_UI_Progress_Type) :: progress            ! Progress bar state (State)
    TYPE(ErrorStatusType) :: status                  ! Error status
  END TYPE AP_UI_Progress_Init_Out
```

### `AP_UI_Progress_Update_In` (lines 104–107)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Update_In
    TYPE(AP_UI_Progress_Type) :: progress            ! Progress bar state (State)
    INTEGER(i4) :: current                           ! n_current  ?ℤ^+
  END TYPE AP_UI_Progress_Update_In
```

### `AP_UI_Progress_Update_Out` (lines 110–113)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Update_Out
    TYPE(AP_UI_Progress_Type) :: progress            ! Updated progress bar state (State)
    TYPE(ErrorStatusType) :: status                  ! Error status
  END TYPE AP_UI_Progress_Update_Out
```

### `AP_UI_Print_In` (lines 116–119)

```fortran
  TYPE, PUBLIC :: AP_UI_Print_In
    CHARACTER(len=512) :: message                    ! msg  ?{string}
    INTEGER(i4), OPTIONAL :: level                   ! level  ? ?
  END TYPE AP_UI_Print_In
```

### `AP_UI_Print_Out` (lines 122–124)

```fortran
  TYPE, PUBLIC :: AP_UI_Print_Out
    TYPE(ErrorStatusType) :: status                  ! Error status
  END TYPE AP_UI_Print_Out
```

### `AP_UI_Ctrl_Type_Cfg` (lines 146–152)

```fortran
  TYPE, PUBLIC :: AP_UI_Ctrl_Type_Cfg
      INTEGER(i4) :: mode = UI_MODE_INTERACTIVE
      LOGICAL :: use_color = .TRUE.
      LOGICAL :: use_unicode = .TRUE.
      LOGICAL :: verbose = .FALSE.
      INTEGER(i4) :: terminal_width = 80            ! w_term  ?ℤ^+
  END TYPE AP_UI_Ctrl_Type_Cfg
```

### `AP_UI_Ctrl_Type_Stats` (lines 154–158)

```fortran
  TYPE, PUBLIC :: AP_UI_Ctrl_Type_Stats
      INTEGER(i4) :: num_messages = 0              ! n_msg  ?ℤ^+
      INTEGER(i4) :: num_warnings = 0              ! n_warn  ?ℤ^+
      INTEGER(i4) :: num_errors = 0                ! n_err  ?ℤ^+
  END TYPE AP_UI_Ctrl_Type_Stats
```

### `AP_UI_Ctrl_Type_State` (lines 160–162)

```fortran
  TYPE, PUBLIC :: AP_UI_Ctrl_Type_State
      LOGICAL :: is_initialized = .FALSE.
  END TYPE AP_UI_Ctrl_Type_State
```

### `AP_UI_Ctrl_Type` (lines 164–173)

```fortran
  TYPE, PUBLIC :: AP_UI_Ctrl_Type
      TYPE(AP_UI_Ctrl_Type_Cfg)   :: cfg
      TYPE(AP_UI_Ctrl_Type_Stats) :: stats
      TYPE(AP_UI_Ctrl_Type_State) :: state
  CONTAINS
      PROCEDURE, PUBLIC :: Init => AP_UI_Ctrl_Init
      PROCEDURE, PUBLIC :: Cleanup => AP_UI_Ctrl_Cleanup
      PROCEDURE, PUBLIC :: SetMode => AP_UI_Ctrl_SetMode
      PROCEDURE, PUBLIC :: SetVerbose => AP_UI_Ctrl_SetVerbose
  END TYPE AP_UI_Ctrl_Type
```

### `AP_UI_Progress_Type_Progress` (lines 194–200)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Type_Progress
      INTEGER(i4) :: current = 0                    ! n_current  ?ℤ^+
      INTEGER(i4) :: total = 100                    ! n_total  ?ℤ^+
      REAL(wp) :: percent = 0.0_wp                  ! p  ?[0,1]
      REAL(wp) :: elapsed_time = 0.0_wp             ! t_elapsed  ?ℝ^+ (seconds)
      REAL(wp) :: eta = 0.0_wp                      ! t_eta  ?ℝ^+ (seconds)
  END TYPE AP_UI_Progress_Type_Progress
```

### `AP_UI_Progress_Type_Display` (lines 202–207)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Type_Display
      CHARACTER(len=256) :: description = ''
      CHARACTER(len=256) :: prefix = ''
      CHARACTER(len=256) :: suffix = ''
      INTEGER(i4) :: bar_width = 50                 ! w_bar  ?ℤ^+
  END TYPE AP_UI_Progress_Type_Display
```

### `AP_UI_Progress_Type_Timing` (lines 209–212)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Type_Timing
      REAL(wp) :: start_time = 0.0_wp               ! t_start  ? ?
      REAL(wp) :: last_update = 0.0_wp               ! t_last  ? ?
  END TYPE AP_UI_Progress_Type_Timing
```

### `AP_UI_Progress_Type_State` (lines 214–217)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Type_State
      LOGICAL :: is_active = .FALSE.
      LOGICAL :: is_complete = .FALSE.
  END TYPE AP_UI_Progress_Type_State
```

### `AP_UI_Progress_Type` (lines 219–229)

```fortran
  TYPE, PUBLIC :: AP_UI_Progress_Type
      TYPE(AP_UI_Progress_Type_Progress) :: progress
      TYPE(AP_UI_Progress_Type_Display)  :: display
      TYPE(AP_UI_Progress_Type_Timing)   :: timing
      TYPE(AP_UI_Progress_Type_State)    :: state
  CONTAINS
      PROCEDURE, PUBLIC :: Init => AP_UI_Progress_Init
      PROCEDURE, PUBLIC :: Update => AP_UI_Progress_Update
      PROCEDURE, PUBLIC :: Finish => AP_UI_Progress_Finish
      PROCEDURE, PUBLIC :: SetDescription => AP_UI_Progress_SetDescription
  END TYPE AP_UI_Progress_Type
```

### `AP_UI_Command_Type_Info` (lines 245–249)

```fortran
  TYPE, PUBLIC :: AP_UI_Command_Type_Info
      CHARACTER(len=64) :: name = ''
      CHARACTER(len=256) :: description = ''
      CHARACTER(len=256) :: usage = ''
  END TYPE AP_UI_Command_Type_Info
```

### `AP_UI_Command_Type_Args` (lines 251–255)

```fortran
  TYPE, PUBLIC :: AP_UI_Command_Type_Args
      INTEGER(i4) :: num_args = 0                  ! n_args  ?ℤ^+
      CHARACTER(len=64), ALLOCATABLE :: arg_names(:)    ! a_i  ?{string}^(n_args)
      CHARACTER(len=256), ALLOCATABLE :: arg_values(:)  ! v_i  ?{string}^(n_args)
  END TYPE AP_UI_Command_Type_Args
```

### `AP_UI_Command_Type_Callback` (lines 257–259)

```fortran
  TYPE, PUBLIC :: AP_UI_Command_Type_Callback
      PROCEDURE(cmd_callback), NOPASS, POINTER :: callback => NULL()
  END TYPE AP_UI_Command_Type_Callback
```

### `AP_UI_Command_Type_State` (lines 261–263)

```fortran
  TYPE, PUBLIC :: AP_UI_Command_Type_State
      LOGICAL :: is_valid = .FALSE.
  END TYPE AP_UI_Command_Type_State
```

### `AP_UI_Command_Type` (lines 265–275)

```fortran
  TYPE, PUBLIC :: AP_UI_Command_Type
      TYPE(AP_UI_Command_Type_Info)     :: info
      TYPE(AP_UI_Command_Type_Args)     :: args
      TYPE(AP_UI_Command_Type_Callback) :: cb
      TYPE(AP_UI_Command_Type_State)    :: state
  CONTAINS
      PROCEDURE, PUBLIC :: Init => AP_UI_Command_Init
      PROCEDURE, PUBLIC :: Cleanup => AP_UI_Command_Cleanup
      PROCEDURE, PUBLIC :: AddArg => AP_UI_Command_AddArg
      PROCEDURE, PUBLIC :: Execute => AP_UI_Command_Execute
  END TYPE AP_UI_Command_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `cmd_callback` | 279 | `SUBROUTINE cmd_callback(cmd, args, status)` |
| SUBROUTINE | `AP_UI_Init_Structured` | 294 | `SUBROUTINE AP_UI_Init_Structured(in, out)` |
| SUBROUTINE | `AP_UI_Progress_Init_Structured` | 302 | `SUBROUTINE AP_UI_Progress_Init_Structured(in, out)` |
| SUBROUTINE | `AP_UI_Progress_Update_Structured` | 310 | `SUBROUTINE AP_UI_Progress_Update_Structured(in, out)` |
| SUBROUTINE | `AP_UI_Print_Structured` | 319 | `SUBROUTINE AP_UI_Print_Structured(in, out)` |
| SUBROUTINE | `AP_UI_Ctrl_Init` | 336 | `SUBROUTINE AP_UI_Ctrl_Init(this, mode, use_color, status)` |
| SUBROUTINE | `AP_UI_Ctrl_Cleanup` | 373 | `SUBROUTINE AP_UI_Ctrl_Cleanup(this)` |
| SUBROUTINE | `AP_UI_Ctrl_SetMode` | 380 | `SUBROUTINE AP_UI_Ctrl_SetMode(this, mode, status)` |
| SUBROUTINE | `AP_UI_Ctrl_SetVerbose` | 403 | `SUBROUTINE AP_UI_Ctrl_SetVerbose(this, verbose, status)` |
| SUBROUTINE | `AP_UI_Progress_Init` | 420 | `SUBROUTINE AP_UI_Progress_Init(this, total, description, bar_width, status)` |
| SUBROUTINE | `AP_UI_Progress_Update` | 470 | `SUBROUTINE AP_UI_Progress_Update(this, current, status)` |
| SUBROUTINE | `AP_UI_Progress_Finish` | 549 | `SUBROUTINE AP_UI_Progress_Finish(this, message, status)` |
| SUBROUTINE | `AP_UI_Progress_SetDescription` | 571 | `SUBROUTINE AP_UI_Progress_SetDescription(this, description, status)` |
| SUBROUTINE | `AP_UI_Command_Init` | 587 | `SUBROUTINE AP_UI_Command_Init(this, name, description, callback, status)` |
| SUBROUTINE | `AP_UI_Command_Cleanup` | 611 | `SUBROUTINE AP_UI_Command_Cleanup(this)` |
| SUBROUTINE | `AP_UI_Command_AddArg` | 622 | `SUBROUTINE AP_UI_Command_AddArg(this, name, value, status)` |
| SUBROUTINE | `AP_UI_Command_Execute` | 658 | `SUBROUTINE AP_UI_Command_Execute(this, args, status)` |
| SUBROUTINE | `AP_UI_Init` | 692 | `SUBROUTINE AP_UI_Init(mode, use_color, status)` |
| SUBROUTINE | `AP_UI_Cleanup` | 706 | `SUBROUTINE AP_UI_Cleanup()` |
| SUBROUTINE | `AP_UI_Print` | 712 | `SUBROUTINE AP_UI_Print(message, level, status)` |
| SUBROUTINE | `AP_UI_PrintInfo` | 733 | `SUBROUTINE AP_UI_PrintInfo(message, status)` |
| SUBROUTINE | `AP_UI_PrintWarning` | 749 | `SUBROUTINE AP_UI_PrintWarning(message, status)` |
| SUBROUTINE | `AP_UI_PrintError` | 765 | `SUBROUTINE AP_UI_PrintError(message, status)` |
| SUBROUTINE | `AP_UI_PrintSuccess` | 781 | `SUBROUTINE AP_UI_PrintSuccess(message, status)` |
| SUBROUTINE | `AP_UI_PrintHeader` | 797 | `SUBROUTINE AP_UI_PrintHeader(title, status)` |
| SUBROUTINE | `AP_UI_PrintTable` | 820 | `SUBROUTINE AP_UI_PrintTable(headers, data, n_rows, n_cols, status)` |
| SUBROUTINE | `AP_UI_ReadLine` | 887 | `SUBROUTINE AP_UI_ReadLine(prompt, line, status)` |
| FUNCTION | `AP_UI_Confirm` | 918 | `FUNCTION AP_UI_Confirm(prompt, default_yes, status) RESULT(confirmed)` |
| FUNCTION | `AP_UI_IsInteractive` | 972 | `FUNCTION AP_UI_IsInteractive() RESULT(is_interactive)` |
| FUNCTION | `AP_UI_GetTerminalWidth` | 978 | `FUNCTION AP_UI_GetTerminalWidth() RESULT(width)` |
| FUNCTION | `AP_UI_GetMode` | 989 | `FUNCTION AP_UI_GetMode() RESULT(mode)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
