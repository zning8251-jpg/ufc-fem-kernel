# `AP_Inp_KWBrg.f90`

- **Source**: `L6_AP/Input/Parser/AP_Inp_KWBrg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Inp_KW_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_KWBrg`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_KWBrg`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Parser`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Parser/AP_Inp_KWBrg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Cmd_KWBrg_Init` | 53 | `subroutine UF_Cmd_KWBrg_Init(status)` |
| SUBROUTINE | `UF_Cmd_KWBrg_RegAddMetadata` | 72 | `subroutine UF_Cmd_KWBrg_RegAddMetadata(proc)` |
| SUBROUTINE | `UF_Cmd_KWBrg_Sync` | 80 | `subroutine UF_Cmd_KWBrg_Sync(status)` |
| FUNCTION | `UF_Cmd_KWBrg_ConvKw2CmdName` | 154 | `function UF_Cmd_KWBrg_ConvKw2CmdName(kw_name) result(cmd_name)` |
| SUBROUTINE | `UF_Cmd_KWBrg_BldSyntax` | 324 | `subroutine UF_Cmd_KWBrg_BldSyntax(kw, syntax_str)` |
| SUBROUTINE | `UF_Cmd_KWBrg_BldParams` | 358 | `subroutine UF_Cmd_KWBrg_BldParams(kw, params_str)` |
| SUBROUTINE | `UF_Cmd_KWBrg_BldExample` | 424 | `subroutine UF_Cmd_KWBrg_BldExample(kw, cmd_name, example_str)` |
| FUNCTION | `UF_Cmd_KWBrg_GetCmdName` | 480 | `function UF_Cmd_KWBrg_GetCmdName(kw_name) result(cmd_name)` |
| SUBROUTINE | `UF_Cmd_KWBrg_ConvKw` | 501 | `subroutine UF_Cmd_KWBrg_ConvKw(kw_name, cmd, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
