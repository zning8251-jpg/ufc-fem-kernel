# `IF_Err_Def.f90`

- **Source**: `L1_IF/Error/IF_Err_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Err_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Err_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Err`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Error`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Error/IF_Err_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Error_Desc` (lines 113–115)

```fortran
  TYPE, PUBLIC :: IF_Error_Desc
    INTEGER(i4) :: version = 1_i4
  END TYPE IF_Error_Desc
```

### `IF_Err_Status_State` (lines 121–136)

```fortran
  TYPE, PUBLIC :: IF_Err_Status_State  ! XREF: 跨层引用待Phase1其他Task同步
  ! Legacy alias: ErrorStatusType
    INTEGER(i4) :: status_code = IF_ERROR_CATEGORY_OK        ! code ??
    INTEGER(i4) :: severity = IF_ERROR_SEVERITY_INFO         ! sev ?{0,1,2,3,4}
    INTEGER(i4) :: category = IF_ERROR_CATEGORY_OK           ! cat ?{0,1,...,19}
    CHARACTER(len=512) :: message = ""                    ! msg ?{string}
    CHARACTER(len=64)  :: source = ""                      ! src ?{string}
    INTEGER(i4) :: line_number = 0                         ! n_line ??^+
    LOGICAL :: has_error = .FALSE.
    INTEGER(i8) :: error_id = 0                           ! id_err ??^+
    INTEGER(i4) :: error_count = 0                        ! n_err ??^+
    INTEGER(i4) :: thread_id = 0                          ! id_thread ??^+
    INTEGER(i4) :: scene_id = 0                           ! id_scene ??^+
    LOGICAL :: enable_stack = .TRUE.
    INTEGER(i4) :: io_stat = 0                            ! STAT/IOSTAT from ALLOCATE/DEALLOCATE/OPEN
  END TYPE IF_Err_Status_State
```

### `IF_Log_Entry_State` (lines 142–151)

```fortran
  TYPE, PUBLIC :: IF_Log_Entry_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: timestamp = 0_i8                      ! t_stamp ??^+
    INTEGER(i4) :: level = 0_i4                           ! level ?{0,1,2,3,4,5}
    INTEGER(i4) :: category = 0_i4                        ! cat ?{0,1,...,9}
    CHARACTER(len=256) :: source = ""                     ! src ?{string}
    CHARACTER(len=512) :: message = ""                     ! msg ?{string}
    INTEGER(i4) :: line_number = 0                         ! n_line ??^+
    INTEGER(i4) :: thread_id = 0                          ! id_thread ??^+
    INTEGER(i4) :: scene_id = 0                           ! id_scene ??^+
  END TYPE IF_Log_Entry_State
```

### `IF_Log_Buffer_State` (lines 157–162)

```fortran
  TYPE, PUBLIC :: IF_Log_Buffer_State  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Log_Entry_State), ALLOCATABLE :: entries(:)             ! entry_i ?LogEntry^(n_entries)
    INTEGER(i4) :: max_entries = 1000                     ! n_max ??^+
    INTEGER(i4) :: n_entries = 0                          ! n_entries ??^+
    LOGICAL :: init = .FALSE.
  END TYPE IF_Log_Buffer_State
```

### `IF_Log_Stats_State` (lines 168–177)

```fortran
  TYPE, PUBLIC :: IF_Log_Stats_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: total_entries = 0_i8                   ! n_total ??^+
    INTEGER(i8) :: trace_count = 0_i8                     ! n_trace ??^+
    INTEGER(i8) :: debug_count = 0_i8                      ! n_debug ??^+
    INTEGER(i8) :: info_count = 0_i8                       ! n_info ??^+
    INTEGER(i8) :: warning_count = 0_i8                    ! n_warn ??^+
    INTEGER(i8) :: error_count = 0_i8                      ! n_err ??^+
    INTEGER(i8) :: fatal_count = 0_i8                      ! n_fatal ??^+
    REAL(wp) :: last_interval = 0.0_wp                     ! ?t_last ??^+ (seconds)
  END TYPE IF_Log_Stats_State
```

### `IF_Log_Logger_Ctx` (lines 183–189)

```fortran
  TYPE, PUBLIC :: IF_Log_Logger_Ctx  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Log_Buffer_State) :: buffer                    ! State reference
    TYPE(IF_Log_Stats_State) :: stats                          ! State reference
    INTEGER(i4) :: min_level = IF_LOG_LEVEL_INFO             ! level_min ?{0,1,2,3,4,5}
    LOGICAL :: enable_console = .TRUE.
    LOGICAL :: init = .FALSE.
  END TYPE IF_Log_Logger_Ctx
```

### `IF_Log_DebugScope_Desc` (lines 197–199)

```fortran
  TYPE, PUBLIC :: IF_Log_DebugScope_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i4) :: id = 0_i4
  END TYPE IF_Log_DebugScope_Desc
```

### `IF_Log_DebugTrace_Desc` (lines 201–203)

```fortran
  TYPE, PUBLIC :: IF_Log_DebugTrace_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i4) :: id = 0_i4
  END TYPE IF_Log_DebugTrace_Desc
```

### `IF_Mon_PerfTimer_State` (lines 205–207)

```fortran
  TYPE, PUBLIC :: IF_Mon_PerfTimer_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: start_ticks = 0_i8
  END TYPE IF_Mon_PerfTimer_State
```

### `IF_Mon_PerfCounter_State` (lines 209–211)

```fortran
  TYPE, PUBLIC :: IF_Mon_PerfCounter_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: count = 0_i8
  END TYPE IF_Mon_PerfCounter_State
```

### `IF_Mon_PerfStats_State` (lines 213–215)

```fortran
  TYPE, PUBLIC :: IF_Mon_PerfStats_State  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i8) :: total_entries = 0_i8
  END TYPE IF_Mon_PerfStats_State
```

### `IF_Err_Stack_State` (lines 221–227)

```fortran
  TYPE, PUBLIC :: IF_Err_Stack_State  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Err_Status_State), ALLOCATABLE :: errors(:)
    INTEGER(i4) :: stack_size = 0
    INTEGER(i4) :: max_size = 1024
    LOGICAL :: has_error = .FALSE.
    LOGICAL :: init = .FALSE.
  END TYPE IF_Err_Stack_State
```

### `IF_Err_CallStack_Desc` (lines 236–241)

```fortran
  TYPE, PUBLIC :: IF_Err_CallStack_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    CHARACTER(len=256) :: function_name = ""
    CHARACTER(len=256) :: file_name = ""
    INTEGER(i4) :: line_number = 0
    INTEGER(i4) :: thread_id = 0
  END TYPE IF_Err_CallStack_Desc
```

### `IF_Err_Recovery_Desc` (lines 274–280)

```fortran
  TYPE, PUBLIC :: IF_Err_Recovery_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i4) :: error_code = 0
    INTEGER(i4) :: recovery_action = IF_RECOVERY_ACTION_NONE
    LOGICAL :: can_recover = .FALSE.
    CHARACTER(len=512) :: recovery_message = ""
    PROCEDURE(RecoveryFunction), POINTER, NOPASS :: recovery_function => NULL()
  END TYPE IF_Err_Recovery_Desc
```

### `IF_Err_RecoveryReg_State` (lines 293–301)

```fortran
  TYPE, PUBLIC :: IF_Err_RecoveryReg_State  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Err_Recovery_Desc), ALLOCATABLE :: handlers(:)
    INTEGER(i4) :: num_handlers = 0
    INTEGER(i4) :: max_handlers = 100
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => ErrReg_Init
    PROCEDURE :: Finalize => ErrReg_Finalize
  END TYPE IF_Err_RecoveryReg_State
```

### `IF_Err_Locale_Desc` (lines 311–315)

```fortran
  TYPE, PUBLIC :: IF_Err_Locale_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    CHARACTER(len=32) :: locale_code = "en_US"
    CHARACTER(len=256) :: language = "English"
    CHARACTER(len=256) :: country = "United States"
  END TYPE IF_Err_Locale_Desc
```

### `IF_Err_MsgTemplate_Desc` (lines 321–325)

```fortran
  TYPE, PUBLIC :: IF_Err_MsgTemplate_Desc  ! XREF: 跨层引用待Phase1其他Task同步
    INTEGER(i4) :: error_code = 0
    CHARACTER(len=512) :: message_template = ""
    CHARACTER(len=32) :: locale = "en_US"
  END TYPE IF_Err_MsgTemplate_Desc
```

### `IF_Err_MsgCatalog_State` (lines 331–337)

```fortran
  TYPE, PUBLIC :: IF_Err_MsgCatalog_State  ! XREF: 跨层引用待Phase1其他Task同步
    TYPE(IF_Err_MsgTemplate_Desc), ALLOCATABLE :: messages(:)
    INTEGER(i4) :: num_messages = 0
    INTEGER(i4) :: max_messages = 1000
    CHARACTER(len=32) :: default_locale = "en_US"
    LOGICAL :: init = .FALSE.
  END TYPE IF_Err_MsgCatalog_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ErrCtx_Init` | 344 | `SUBROUTINE ErrCtx_Init(this)` |
| SUBROUTINE | `ErrCtx_Finalize` | 357 | `SUBROUTINE ErrCtx_Finalize(this)` |
| SUBROUTINE | `ErrReg_Init` | 368 | `SUBROUTINE ErrReg_Init(this)` |
| SUBROUTINE | `ErrReg_Finalize` | 379 | `SUBROUTINE ErrReg_Finalize(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
