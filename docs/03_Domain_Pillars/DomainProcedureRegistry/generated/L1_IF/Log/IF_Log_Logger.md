# `IF_Log_Logger.f90`

- **Source**: `L1_IF/Log/IF_Log_Logger.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Log_Logger`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Log_Logger`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Log_Logger`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Log`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Log/IF_Log_Logger.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_LogConfig` (lines 59–69)

```fortran
  TYPE, PUBLIC :: IF_LogConfig
    INTEGER(i4) :: min_level = IF_LOG_LEVEL_INFO          ! level_min ?{0,1,2,3,4,5}
    INTEGER(i4) :: output_target = IF_LOG_OUTPUT_STDOUT
    CHARACTER(LEN=512) :: log_file = "ufc.log"         ! path ?{string}
    LOGICAL :: append_mode = .FALSE.
    LOGICAL :: include_timestamp = .TRUE.
    LOGICAL :: include_module = .TRUE.
    LOGICAL :: include_line = .FALSE.
    INTEGER(i4) :: buffer_size = 1000                  ! n_buf ??^+
    LOGICAL :: auto_flush = .TRUE.
  END TYPE IF_LogConfig
```

### `IF_Logger` (lines 75–95)

```fortran
  TYPE, PUBLIC :: IF_Logger
    TYPE(IF_LogConfig) :: config                         ! Desc reference
    TYPE(IF_Log_Buffer_State) :: buffer                  ! State reference
    TYPE(IF_Log_Stats_State) :: stats                    ! State reference
    INTEGER(i4) :: file_unit = -1                        ! n_unit ??
    LOGICAL :: is_open = .FALSE.
    LOGICAL :: is_init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => IF_Logger_Init
    PROCEDURE, PUBLIC :: Finalize => IF_Logger_Finalize
    PROCEDURE, PUBLIC :: SetLevel => IF_Logger_SetLevel
    PROCEDURE, PUBLIC :: Log => IF_Logger_Log
    PROCEDURE, PUBLIC :: Trace => IF_Logger_Trace
    PROCEDURE, PUBLIC :: Debug => IF_Logger_Debug
    PROCEDURE, PUBLIC :: Info => IF_Logger_Info
    PROCEDURE, PUBLIC :: Warning => IF_Logger_Warning
    PROCEDURE, PUBLIC :: Error => IF_Logger_Error
    PROCEDURE, PUBLIC :: Fatal => IF_Logger_Fatal
    PROCEDURE, PUBLIC :: Flush => IF_Logger_Flush
    PROCEDURE, PUBLIC :: GetStats => IF_Logger_GetStats
  END TYPE IF_Logger
```

### `IF_Logger_Init_In` (lines 117–120)

```fortran
  TYPE, PUBLIC :: IF_Logger_Init_In
    LOGICAL :: has_config = .FALSE.           ! If true, use config
    TYPE(IF_LogConfig) :: config             ! Logger configuration (when has_config)
  END TYPE IF_Logger_Init_In
```

### `IF_Logger_Init_Out` (lines 127–130)

```fortran
  TYPE, PUBLIC :: IF_Logger_Init_Out
    TYPE(IF_Logger) :: logger                ! Initialized logger (Ctx)
    TYPE(ErrorStatusType) :: status          ! Error status
  END TYPE IF_Logger_Init_Out
```

### `IF_Logger_Log_In` (lines 138–144)

```fortran
  TYPE, PUBLIC :: IF_Logger_Log_In
    TYPE(IF_Logger) :: logger                ! Logger (Ctx)
    INTEGER(i4) :: level                     ! level in {0,1,2,3,4,5}
    CHARACTER(LEN=512) :: message            ! msg
    CHARACTER(LEN=64) :: module_name = ""   ! Module name (empty = not provided)
    INTEGER(i4) :: line_num = -1_i4          ! Line number (-1 = not provided)
  END TYPE IF_Logger_Log_In
```

### `IF_Logger_Log_Out` (lines 151–154)

```fortran
  TYPE, PUBLIC :: IF_Logger_Log_Out
    TYPE(IF_Logger) :: logger                ! Updated logger (Ctx)
    TYPE(ErrorStatusType) :: status          ! Error status
  END TYPE IF_Logger_Log_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Logger_Init_Structured` | 163 | `SUBROUTINE IF_Logger_Init_Structured(in, out)` |
| SUBROUTINE | `IF_Logger_Log_Structured` | 175 | `SUBROUTINE IF_Logger_Log_Structured(in, out)` |
| SUBROUTINE | `IF_Logger_Init` | 200 | `SUBROUTINE IF_Logger_Init(this, config, status)` |
| SUBROUTINE | `IF_Logger_Finalize` | 268 | `SUBROUTINE IF_Logger_Finalize(this, status)` |
| SUBROUTINE | `IF_Logger_SetLevel` | 312 | `SUBROUTINE IF_Logger_SetLevel(this, min_level, status)` |
| SUBROUTINE | `IF_Logger_Log` | 329 | `SUBROUTINE IF_Logger_Log(this, level, message, module_name, line_num, status)` |
| SUBROUTINE | `IF_Logger_Trace` | 421 | `SUBROUTINE IF_Logger_Trace(this, message, module_name, status)` |
| SUBROUTINE | `IF_Logger_Debug` | 430 | `SUBROUTINE IF_Logger_Debug(this, message, module_name, status)` |
| SUBROUTINE | `IF_Logger_Info` | 439 | `SUBROUTINE IF_Logger_Info(this, message, module_name, status)` |
| SUBROUTINE | `IF_Logger_Warning` | 448 | `SUBROUTINE IF_Logger_Warning(this, message, module_name, status)` |
| SUBROUTINE | `IF_Logger_Error` | 457 | `SUBROUTINE IF_Logger_Error(this, message, module_name, status)` |
| SUBROUTINE | `IF_Logger_Fatal` | 466 | `SUBROUTINE IF_Logger_Fatal(this, message, module_name, status)` |
| SUBROUTINE | `IF_Logger_Flush` | 479 | `SUBROUTINE IF_Logger_Flush(this, status)` |
| SUBROUTINE | `IF_Logger_GetStats` | 492 | `SUBROUTINE IF_Logger_GetStats(this, stats)` |
| SUBROUTINE | `FormatLogEntry` | 503 | `SUBROUTINE FormatLogEntry(logger, entry, formatted_msg)` |
| SUBROUTINE | `IF_Log_Init` | 555 | `SUBROUTINE IF_Log_Init(config, status)` |
| SUBROUTINE | `IF_Log_Trace` | 563 | `SUBROUTINE IF_Log_Trace(message, module_name, status)` |
| SUBROUTINE | `IF_Log_Debug` | 571 | `SUBROUTINE IF_Log_Debug(message, module_name, status)` |
| SUBROUTINE | `IF_Log_Info` | 580 | `SUBROUTINE IF_Log_Info(message, module_name, status)` |
| SUBROUTINE | `IF_Log_Warning` | 589 | `SUBROUTINE IF_Log_Warning(message, module_name, status)` |
| SUBROUTINE | `IF_Log_Error` | 598 | `SUBROUTINE IF_Log_Error(message, module_name, status)` |
| SUBROUTINE | `IF_Log_Fatal` | 607 | `SUBROUTINE IF_Log_Fatal(message, module_name, status)` |
| SUBROUTINE | `IF_Log_Flush` | 616 | `SUBROUTINE IF_Log_Flush(status)` |
| SUBROUTINE | `IF_Log_GetStats` | 623 | `SUBROUTINE IF_Log_GetStats(stats)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
