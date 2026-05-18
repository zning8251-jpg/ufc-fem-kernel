# `AP_InpScript_UFC.f90`

- **Source**: `L6_AP/Input/Script/AP_InpScript_UFC.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_InpScript_UFC`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_InpScript_UFC`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_InpScript_UFC`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Script`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Script/AP_InpScript_UFC.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Cmd_UFC_RegAll` | 80 | `subroutine UF_Cmd_UFC_RegAll(status)` |
| SUBROUTINE | `Cmd_Init` | 332 | `subroutine Cmd_Init(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Tangent` | 355 | `subroutine Cmd_Tangent(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Form` | 383 | `subroutine Cmd_Form(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Solv` | 416 | `subroutine Cmd_Solv(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Iterate` | 454 | `subroutine Cmd_Iterate(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Displacement` | 483 | `subroutine Cmd_Displacement(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Plot` | 510 | `subroutine Cmd_Plot(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Step` | 537 | `subroutine Cmd_Step(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Increment` | 614 | `subroutine Cmd_Increment(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Part` | 643 | `subroutine Cmd_Part(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Mat` | 733 | `subroutine Cmd_Mat(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Load` | 859 | `subroutine Cmd_Load(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_BC` | 886 | `subroutine Cmd_BC(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Run` | 913 | `subroutine Cmd_Run(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Stop` | 982 | `subroutine Cmd_Stop(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Jump` | 1000 | `subroutine Cmd_Jump(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Break` | 1047 | `subroutine Cmd_Break(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Continue` | 1073 | `subroutine Cmd_Continue(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_History` | 1099 | `subroutine Cmd_History(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Help` | 1142 | `subroutine Cmd_Help(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Debug` | 1173 | `subroutine Cmd_Debug(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Label` | 1212 | `subroutine Cmd_Label(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Echo` | 1245 | `subroutine Cmd_Echo(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Set` | 1270 | `subroutine Cmd_Set(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Alias` | 1311 | `subroutine Cmd_Alias(cmd, ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
