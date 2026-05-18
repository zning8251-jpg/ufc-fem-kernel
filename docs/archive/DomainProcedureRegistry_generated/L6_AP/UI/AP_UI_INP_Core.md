# `AP_UI_INP_Core.f90`

- **Source**: `L6_AP/UI/AP_UI_INP_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_UI_INP_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_UI_INP_Core`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_UI_INP`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `UI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/UI/AP_UI_INP_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IN_GenerateFieldOutput` | 70 | `subroutine IN_GenerateFieldOutput(this, field_req)` |
| SUBROUTINE | `IN_GenerateHistoryOutput` | 151 | `subroutine IN_GenerateHistoryOutput(this, hist_req)` |
| SUBROUTINE | `IN_GenerateInteract` | 205 | `subroutine IN_GenerateInteract(this, interaction, status)` |
| FUNCTION | `real_to_string` | 255 | `function real_to_string(r) result(str)` |
| SUBROUTINE | `IN_GenerateOutputRequests` | 263 | `subroutine IN_GenerateOutputRequests(this, step)` |
| SUBROUTINE | `INPGenerator_Generate` | 332 | `subroutine INPGenerator_Generate(this, model_tree, output_file, status)` |
| SUBROUTINE | `INPGenerator_GenerateLoadBC` | 441 | `subroutine INPGenerator_GenerateLoadBC(this, loadbc, status)` |
| SUBROUTINE | `INPGenerator_GenerateMat` | 515 | `subroutine INPGenerator_GenerateMat(this, Mat, status)` |
| SUBROUTINE | `INPGenerator_GeneratePart` | 622 | `subroutine INPGenerator_GeneratePart(this, part, status)` |
| FUNCTION | `GetElementTypeString` | 757 | `function GetElementTypeString(typeId) result(typeStr)` |
| SUBROUTINE | `INPGenerator_GenerateSection` | 781 | `subroutine INPGenerator_GenerateSection(this, section, status)` |
| SUBROUTINE | `INPGenerator_GenerateStep` | 842 | `subroutine INPGenerator_GenerateStep(this, step, status)` |
| FUNCTION | `itoa` | 974 | `function itoa(i) result(str)` |
| FUNCTION | `INPGenerator_GetIndent` | 982 | `function INPGenerator_GetIndent(this) result(indent_str)` |
| FUNCTION | `INPGenerator_Valid` | 994 | `function INPGenerator_Valid(this, inp_file) result(is_valid)` |
| SUBROUTINE | `INPGenerator_WriteComment` | 1031 | `subroutine INPGenerator_WriteComment(this, comment)` |
| SUBROUTINE | `INPGenerator_WriteData` | 1048 | `subroutine INPGenerator_WriteData(this, data_line)` |
| SUBROUTINE | `INPGenerator_WriteKeyword` | 1067 | `subroutine INPGenerator_WriteKeyword(this, keyword)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
