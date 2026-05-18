# `AP_Inp_Param.f90`

- **Source**: `L6_AP/Input/Parser/AP_Inp_Param.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Inp_Param`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Inp_Param`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Inp_Param`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Parser`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Parser/AP_Inp_Param.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ParseArray` | 32 | `subroutine ParseArray(param_str, values, num_values, max_values)` |
| SUBROUTINE | `ParseKeyValue` | 82 | `subroutine ParseKeyValue(param_str, key, value_str, found)` |
| SUBROUTINE | `ParseKeyValueInt` | 119 | `subroutine ParseKeyValueInt(param_str, key, value, found, default_val)` |
| SUBROUTINE | `PARSEKEYVALUERE` | 151 | `subroutine PARSEKEYVALUERE(param_str, key, value, found, default_val)` |
| SUBROUTINE | `ParseKeyValueStr` | 193 | `subroutine ParseKeyValueStr(param_str, key, value, found, default_val)` |
| SUBROUTINE | `ParseQuotedString` | 208 | `subroutine ParseQuotedString(str, quoted_str, found)` |
| SUBROUTINE | `SplitString` | 240 | `subroutine SplitString(str, delimiter, tokens, num_tokens, max_tokens)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
