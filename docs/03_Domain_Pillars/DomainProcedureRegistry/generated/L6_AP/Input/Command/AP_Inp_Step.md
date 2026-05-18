# `AP_Inp_Step.f90`

- **Source**: `L6_AP/Input/Command/AP_Inp_Step.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Inp_Step`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Step`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_Step`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Command`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Command/AP_Inp_Step.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_Buckling` | 41 | `subroutine Cmd_Buckling(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_CoupledTempDisp` | 54 | `subroutine Cmd_CoupledTempDisp(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Dynamic` | 156 | `subroutine Cmd_Dynamic(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Explicit` | 179 | `subroutine Cmd_Explicit(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Frequency` | 242 | `subroutine Cmd_Frequency(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_HeatTransfer` | 255 | `subroutine Cmd_HeatTransfer(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Modal` | 315 | `subroutine Cmd_Modal(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Static` | 337 | `subroutine Cmd_Static(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Step` | 350 | `subroutine Cmd_Step(cmd, ctx, status)` |
| SUBROUTINE | `UF_Cmd_Step_RegAll` | 513 | `subroutine UF_Cmd_Step_RegAll(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
