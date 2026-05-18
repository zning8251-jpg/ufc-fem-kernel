# `AP_Inp_MgrLegacy.f90`

- **Source**: `L6_AP/Input/AP_Inp_MgrLegacy.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Inp_MgrLegacy`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_MgrLegacy`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_MgrLegacy`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/AP_Inp_MgrLegacy.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Input_Mgr_Init` | 36 | `SUBROUTINE AP_Input_Mgr_Init(domain, status)` |
| SUBROUTINE | `AP_Input_Mgr_AddKeyword` | 42 | `SUBROUTINE AP_Input_Mgr_AddKeyword(domain, keyword_id, line_number, name, category, has_data, status)` |
| SUBROUTINE | `AP_Input_Mgr_AddCommand` | 53 | `SUBROUTINE AP_Input_Mgr_AddCommand(domain, cmd_id, keyword_idx, line_number, name, opt, params, param_str, status)` |
| SUBROUTINE | `AP_Input_Mgr_GetKeyword` | 74 | `SUBROUTINE AP_Input_Mgr_GetKeyword(domain, idx, entry, found)` |
| SUBROUTINE | `AP_Input_Mgr_GetCmd` | 82 | `SUBROUTINE AP_Input_Mgr_GetCmd(domain, idx, entry, found)` |
| FUNCTION | `AP_Input_Mgr_GetKeywordCount` | 90 | `FUNCTION AP_Input_Mgr_GetKeywordCount(domain) RESULT(n)` |
| FUNCTION | `AP_Input_Mgr_GetCmdCount` | 96 | `FUNCTION AP_Input_Mgr_GetCmdCount(domain) RESULT(n)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
