# `AP_Inp_ParserUtil.f90`

- **Source**: `L6_AP/Input/Parser/AP_Inp_ParserUtil.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Inp_ParserUtil`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_ParserUtil`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_ParserUtil`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Parser`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Parser/AP_Inp_ParserUtil.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Pa_Un_Execute` | 33 | `SUBROUTINE AP_Pa_Un_Execute(operation, line, result_line, status)` |
| SUBROUTINE | `AP_Parse_ExtractQuotedString` | 55 | `SUBROUTINE AP_Parse_ExtractQuotedString(line, quote_char, quoted_str, found)` |
| FUNCTION | `AP_Parse_NormalizeLine` | 84 | `FUNCTION AP_Parse_NormalizeLine(line) RESULT(normalized_line)` |
| FUNCTION | `AP_Parse_RemoveComments` | 92 | `FUNCTION AP_Parse_RemoveComments(line, comment_char) RESULT(clean_line)` |
| SUBROUTINE | `AP_Parse_SplitTokens` | 114 | `SUBROUTINE AP_Parse_SplitTokens(line, tokens, num_tokens, status)` |
| FUNCTION | `AP_Parse_TrimWhitespace` | 153 | `FUNCTION AP_Parse_TrimWhitespace(line) RESULT(trimmed_line)` |
| SUBROUTINE | `AP_ParserUtils_Unified_Cfg` | 160 | `SUBROUTINE AP_ParserUtils_Unified_Cfg(operation, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
