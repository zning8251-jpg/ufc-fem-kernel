# `IF_Log_Core.f90`

- **Source**: `L1_IF/Log/IF_Log_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Log_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Log_Core`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Log`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Log`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Log/IF_Log_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Log_Domain` (lines 54–71)

```fortran
  TYPE, PUBLIC :: IF_Log_Domain
    TYPE(IF_Logger)      :: logger
    INTEGER(i4)          :: minLevel      = IF_LOG_INFO
    LOGICAL              :: enConsole     = .TRUE.
    LOGICAL              :: enFileOutput  = .FALSE.
    CHARACTER(LEN=256)   :: logFilePath   = ""
    LOGICAL              :: initialized   = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Info
    PROCEDURE :: Warning
    PROCEDURE :: Error
    PROCEDURE :: Trace
    PROCEDURE :: Debug
    PROCEDURE :: Fatal
    PROCEDURE :: Flush
  END TYPE IF_Log_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 78 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Init` | 91 | `SUBROUTINE Init(this, minLevel, enConsole, status)` |
| SUBROUTINE | `Info` | 117 | `SUBROUTINE Info(this, message, status)` |
| SUBROUTINE | `Warning` | 127 | `SUBROUTINE Warning(this, message, status)` |
| SUBROUTINE | `Error` | 137 | `SUBROUTINE Error(this, message, status)` |
| SUBROUTINE | `Trace` | 147 | `SUBROUTINE Trace(this, message, status)` |
| SUBROUTINE | `Debug` | 157 | `SUBROUTINE Debug(this, message, status)` |
| SUBROUTINE | `Fatal` | 167 | `SUBROUTINE Fatal(this, message, status)` |
| SUBROUTINE | `Flush` | 177 | `SUBROUTINE Flush(this, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
