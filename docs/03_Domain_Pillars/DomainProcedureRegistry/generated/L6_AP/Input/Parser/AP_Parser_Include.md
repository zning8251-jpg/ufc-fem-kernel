# `AP_Parser_Include.f90`

- **Source**: `L6_AP/Input/Parser/AP_Parser_Include.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Parser_Include`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Parser_Include`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Parser_Include`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Input/Parser`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Input/Parser/AP_Parser_Include.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IncludeProperties` (lines 33–35)

```fortran
    TYPE, PUBLIC :: IncludeProperties
        TYPE(AP_Parser_Include_Props) :: inner
    END TYPE IncludeProperties
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Parser_Include_Init` | 55 | `SUBROUTINE AP_Parser_Include_Init(this, inputFile, status)` |
| SUBROUTINE | `AP_Parser_Include_Valid` | 63 | `SUBROUTINE AP_Parser_Include_Valid(this, status)` |
| SUBROUTINE | `AP_Parser_Include_Clear` | 72 | `SUBROUTINE AP_Parser_Include_Clear(this)` |
| SUBROUTINE | `AP_Parser_Include_Parse` | 80 | `SUBROUTINE AP_Parser_Include_Parse(ast_node, include_prop, status)` |
| SUBROUTINE | `get_param_value` | 90 | `SUBROUTINE get_param_value(ast_node, param_name, param_value)` |
| SUBROUTINE | `Parse_INCLUDE_Keyword` | 107 | `SUBROUTINE Parse_INCLUDE_Keyword(ast_node, include_prop, status)` |
| SUBROUTINE | `AP_Parser_UnifiedParse` | 114 | `SUBROUTINE AP_Parser_UnifiedParse(keyword_type, ast_node, include_prop, status)` |
| SUBROUTINE | `AP_Parser_Unified_Parse` | 129 | `SUBROUTINE AP_Parser_Unified_Parse(keyword_type, ast_node, include_prop, status)` |
| SUBROUTINE | `AP_Parser_UnifiedCfg` | 137 | `SUBROUTINE AP_Parser_UnifiedCfg(operation, status)` |
| SUBROUTINE | `AP_Parser_Unified_Cfg` | 151 | `SUBROUTINE AP_Parser_Unified_Cfg(operation, status)` |
| SUBROUTINE | `AP_Parser_Include_ValidKw` | 160 | `SUBROUTINE AP_Parser_Include_ValidKw(include_prop, status)` |
| SUBROUTINE | `Valid_INCLUDE_Keyword` | 168 | `SUBROUTINE Valid_INCLUDE_Keyword(include_prop, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
