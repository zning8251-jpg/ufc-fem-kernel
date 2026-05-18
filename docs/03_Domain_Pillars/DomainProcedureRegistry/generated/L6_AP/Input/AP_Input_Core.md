# `AP_Input_Core.f90`

- **Source**: `L6_AP/Input/AP_Input_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Input_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Input_Core`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Input`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Input`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/AP_Input_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Input_Core_Init` | 41 | `SUBROUTINE AP_Input_Core_Init(desc, state, status)` |
| SUBROUTINE | `AP_Input_Core_Finalize` | 53 | `SUBROUTINE AP_Input_Core_Finalize(desc, state, status)` |
| SUBROUTINE | `AP_Input_Read_File` | 68 | `SUBROUTINE AP_Input_Read_File(desc, state, status)` |
| SUBROUTINE | `AP_Input_Process_Keywords` | 112 | `SUBROUTINE AP_Input_Process_Keywords(desc, state, status)` |
| SUBROUTINE | `Extract_Keyword` | 159 | `SUBROUTINE Extract_Keyword(line, keyword)` |
| SUBROUTINE | `AP_Input_Validate` | 179 | `SUBROUTINE AP_Input_Validate(desc, state, status)` |
| FUNCTION | `AP_Input_Get_Line_Count` | 193 | `FUNCTION AP_Input_Get_Line_Count(state) RESULT(n)` |
| FUNCTION | `AP_Input_Get_Error_Count` | 199 | `FUNCTION AP_Input_Get_Error_Count(state) RESULT(n)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
