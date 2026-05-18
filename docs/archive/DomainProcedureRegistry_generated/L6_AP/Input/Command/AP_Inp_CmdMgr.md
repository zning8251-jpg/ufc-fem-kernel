# `AP_Inp_CmdMgr.f90`

- **Source**: `L6_AP/Input/Command/AP_Inp_CmdMgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Inp_CmdMgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_CmdMgr`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_CmdMgr`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Command`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Command/AP_Inp_CmdMgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Cmd_Mgr_Init` | 40 | `SUBROUTINE AP_Cmd_Mgr_Init(domain, status)` |
| SUBROUTINE | `AP_Cmd_Mgr_Finalize` | 46 | `SUBROUTINE AP_Cmd_Mgr_Finalize(domain)` |
| SUBROUTINE | `AP_Cmd_Mgr_AddCommand` | 51 | `SUBROUTINE AP_Cmd_Mgr_AddCommand(domain, cmd, cmd_id, status)` |
| SUBROUTINE | `AP_Cmd_Mgr_AddHandler` | 59 | `SUBROUTINE AP_Cmd_Mgr_AddHandler(domain, h, handler_id, status)` |
| SUBROUTINE | `AP_Cmd_Mgr_AddHistory` | 67 | `SUBROUTINE AP_Cmd_Mgr_AddHistory(domain, cmd, source, timestamp, status)` |
| SUBROUTINE | `AP_Cmd_Mgr_GetCommand` | 76 | `SUBROUTINE AP_Cmd_Mgr_GetCommand(domain, idx, cmd, found)` |
| SUBROUTINE | `AP_Cmd_Mgr_GetHandler` | 84 | `SUBROUTINE AP_Cmd_Mgr_GetHandler(domain, idx, h, found)` |
| SUBROUTINE | `AP_Cmd_Mgr_GetHandlerByName` | 92 | `SUBROUTINE AP_Cmd_Mgr_GetHandlerByName(domain, name, h, found)` |
| SUBROUTINE | `AP_Cmd_Mgr_GetHistory` | 100 | `SUBROUTINE AP_Cmd_Mgr_GetHistory(domain, idx, entry, found)` |
| FUNCTION | `AP_Cmd_Mgr_GetCommandCount` | 108 | `FUNCTION AP_Cmd_Mgr_GetCommandCount(domain) RESULT(n)` |
| FUNCTION | `AP_Cmd_Mgr_GetHandlerCount` | 114 | `FUNCTION AP_Cmd_Mgr_GetHandlerCount(domain) RESULT(n)` |
| FUNCTION | `AP_Cmd_Mgr_GetHistoryCount` | 120 | `FUNCTION AP_Cmd_Mgr_GetHistoryCount(domain) RESULT(n)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
