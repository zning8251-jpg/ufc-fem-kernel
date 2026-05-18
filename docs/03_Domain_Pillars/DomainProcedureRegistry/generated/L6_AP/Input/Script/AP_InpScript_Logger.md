# `AP_InpScript_Logger.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Logger.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_Logger`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Logger`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript_Logger`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Logger.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Cmd_Log_In` (lines 30–33)

```fortran
  TYPE, PUBLIC :: Cmd_Log_In
    INTEGER(i4) :: level
    CHARACTER(LEN=256) :: message
  END TYPE Cmd_Log_In
```

### `Cmd_Log_Out` (lines 35–37)

```fortran
  TYPE, PUBLIC :: Cmd_Log_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_Log_Out
```

### `Cmd_LogError_In` (lines 39–41)

```fortran
  TYPE, PUBLIC :: Cmd_LogError_In
    CHARACTER(LEN=256) :: message
  END TYPE Cmd_LogError_In
```

### `Cmd_LogError_Out` (lines 43–45)

```fortran
  TYPE, PUBLIC :: Cmd_LogError_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_LogError_Out
```

### `Cmd_SetLogLevel_In` (lines 47–49)

```fortran
  TYPE, PUBLIC :: Cmd_SetLogLevel_In
    INTEGER(i4) :: level
  END TYPE Cmd_SetLogLevel_In
```

### `Cmd_SetLogLevel_Out` (lines 51–53)

```fortran
  TYPE, PUBLIC :: Cmd_SetLogLevel_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_SetLogLevel_Out
```

### `CmdLogger` (lines 58–69)

```fortran
  TYPE, PUBLIC :: CmdLogger
    INTEGER(i4) :: level = LOG_INFO
    INTEGER(i4) :: unit = 6  ! stdout
    LOGICAL :: to_file = .FALSE.
    CHARACTER(LEN=256) :: filename = ''
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Log
    PROCEDURE :: LogError
    PROCEDURE :: SetLevel
  END TYPE CmdLogger
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Log_Init` | 91 | `SUBROUTINE Log_Init(this, level, log_file, status)` |
| SUBROUTINE | `Log_Log` | 107 | `SUBROUTINE Log_Log(this, level, message, status)` |
| SUBROUTINE | `Log_LogError` | 117 | `SUBROUTINE Log_LogError(this, message, status)` |
| SUBROUTINE | `Log_SetLevel` | 126 | `SUBROUTINE Log_SetLevel(this, level, status)` |
| SUBROUTINE | `Cmd_Log_Structured` | 139 | `SUBROUTINE Cmd_Log_Structured(in, out)` |
| SUBROUTINE | `Cmd_LogError_Structured` | 147 | `SUBROUTINE Cmd_LogError_Structured(in, out)` |
| SUBROUTINE | `Cmd_SetLogLevel_Structured` | 155 | `SUBROUTINE Cmd_SetLogLevel_Structured(in, out)` |
| SUBROUTINE | `Cmd_Log` | 166 | `SUBROUTINE Cmd_Log(level, message, status)` |
| SUBROUTINE | `Cmd_LogError` | 180 | `SUBROUTINE Cmd_LogError(message, status)` |
| SUBROUTINE | `Cmd_SetLogLevel` | 192 | `SUBROUTINE Cmd_SetLogLevel(level, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
