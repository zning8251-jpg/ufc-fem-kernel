# `AP_Inp_Domain.f90`

- **Source**: `L6_AP/Input/Command/AP_Inp_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Inp_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Domain`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Command`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Command/AP_Inp_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Cmd_Domain` (lines 24–46)

```fortran
  TYPE, PUBLIC :: AP_Cmd_Domain
    TYPE(Cmd), ALLOCATABLE           :: commands(:)
    TYPE(CmdHandler), ALLOCATABLE     :: handlers(:)
    TYPE(HistoryEntry), ALLOCATABLE   :: history(:)
    INTEGER(i4) :: n_commands = 0_i4
    INTEGER(i4) :: n_handlers = 0_i4
    INTEGER(i4) :: n_history  = 0_i4
    INTEGER(i4) :: next_handler_id = 1_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddCommand
    PROCEDURE :: AddHandler
    PROCEDURE :: AddHistory
    PROCEDURE :: GetCommandById
    PROCEDURE :: GetHandlerById
    PROCEDURE :: GetHandlerByName
    PROCEDURE :: GetHandlerIndexByName
    PROCEDURE :: GetHistoryById
    PROCEDURE :: ClearHistory
    PROCEDURE :: ClearCommands
  END TYPE AP_Cmd_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Cmd_Domain_Finalize` | 50 | `SUBROUTINE AP_Cmd_Domain_Finalize(this)` |
| SUBROUTINE | `AP_Cmd_Domain_Init` | 63 | `SUBROUTINE AP_Cmd_Domain_Init(this, status)` |
| SUBROUTINE | `AP_Cmd_Domain_AddCommand` | 81 | `SUBROUTINE AP_Cmd_Domain_AddCommand(this, cmd, cmd_id, status)` |
| SUBROUTINE | `AP_Cmd_Domain_AddHandler` | 122 | `SUBROUTINE AP_Cmd_Domain_AddHandler(this, h, handler_id, status)` |
| SUBROUTINE | `AP_Cmd_Domain_AddHistory` | 174 | `SUBROUTINE AP_Cmd_Domain_AddHistory(this, cmd, source, timestamp, status)` |
| SUBROUTINE | `AP_Cmd_Domain_GetCommandById` | 213 | `SUBROUTINE AP_Cmd_Domain_GetCommandById(this, idx, cmd, found)` |
| SUBROUTINE | `AP_Cmd_Domain_GetHandlerById` | 231 | `SUBROUTINE AP_Cmd_Domain_GetHandlerById(this, idx, h, found)` |
| SUBROUTINE | `AP_Cmd_Domain_GetHandlerByName` | 261 | `SUBROUTINE AP_Cmd_Domain_GetHandlerByName(this, name, h, found)` |
| SUBROUTINE | `AP_Cmd_Domain_GetHistoryById` | 287 | `SUBROUTINE AP_Cmd_Domain_GetHistoryById(this, idx, entry, found)` |
| SUBROUTINE | `AP_Cmd_Domain_GetHandlerIndexByName` | 306 | `SUBROUTINE AP_Cmd_Domain_GetHandlerIndexByName(this, name, idx, found)` |
| SUBROUTINE | `AP_Cmd_Domain_ClearHistory` | 333 | `SUBROUTINE AP_Cmd_Domain_ClearHistory(this)` |
| SUBROUTINE | `AP_Cmd_Domain_ClearCommands` | 344 | `SUBROUTINE AP_Cmd_Domain_ClearCommands(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
