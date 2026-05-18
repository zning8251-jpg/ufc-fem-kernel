# `AP_InpScript_Brg.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_Brg`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Cmd_Init` | 54 | `subroutine UF_Cmd_Init(ctx, status)` |
| SUBROUTINE | `UF_Cmd_ExecFile` | 104 | `subroutine UF_Cmd_ExecFile(filename, ctx, status)` |
| SUBROUTINE | `UF_Cmd_ExecString` | 154 | `subroutine UF_Cmd_ExecString(cmd_string, ctx, status)` |
| SUBROUTINE | `UF_Cmd_SetCtx` | 204 | `subroutine UF_Cmd_SetCtx(ctx, status)` |
| SUBROUTINE | `UF_Cmd_GetCtx` | 217 | `subroutine UF_Cmd_GetCtx(ctx, status)` |
| SUBROUTINE | `UF_CmdSys_Init` | 234 | `subroutine UF_CmdSys_Init(ctx, status)` |
| SUBROUTINE | `UF_CmdSys_ExecFile` | 249 | `subroutine UF_CmdSys_ExecFile(filename, ctx, status)` |
| SUBROUTINE | `UF_CmdSys_ExecStr` | 261 | `subroutine UF_CmdSys_ExecStr(cmd_string, ctx, status)` |
| SUBROUTINE | `UF_CmdSys_SetCtx` | 273 | `subroutine UF_CmdSys_SetCtx(ctx, status)` |
| SUBROUTINE | `UF_CmdSys_GetCtx` | 284 | `subroutine UF_CmdSys_GetCtx(ctx)` |
| SUBROUTINE | `AP_Cmd_Unified_Execute` | 300 | `subroutine AP_Cmd_Unified_Execute(source_type, source, ctx, status)` |
| SUBROUTINE | `AP_Cmd_Unified_Cfg` | 341 | `subroutine AP_Cmd_Unified_Cfg(operation, ctx, status)` |
| SUBROUTINE | `AP_App_Unified_Run` | 395 | `subroutine AP_App_Unified_Run(operation, status, filename, cmd_string)` |
| SUBROUTINE | `AP_App_Unified_Cfg` | 436 | `subroutine AP_App_Unified_Cfg(operation, ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
