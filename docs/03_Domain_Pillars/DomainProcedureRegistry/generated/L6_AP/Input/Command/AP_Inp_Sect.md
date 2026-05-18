# `AP_Inp_Sect.f90`

- **Source**: `L6_AP/Input/Command/AP_Inp_Sect.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Inp_Sect`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Sect`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_Sect`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Command`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Command/AP_Inp_Sect.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cmd_CohesiveSection` | 36 | `subroutine Cmd_CohesiveSection(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Layer` | 145 | `subroutine Cmd_Layer(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_MembraneSection` | 206 | `subroutine Cmd_MembraneSection(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_Section` | 309 | `subroutine Cmd_Section(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_SectionAssign` | 546 | `subroutine Cmd_SectionAssign(cmd, ctx, status)` |
| SUBROUTINE | `Cmd_SectionControls` | 618 | `subroutine Cmd_SectionControls(cmd, ctx, status)` |
| SUBROUTINE | `UF_Cmd_Sect_RegAll` | 678 | `subroutine UF_Cmd_Sect_RegAll(status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
