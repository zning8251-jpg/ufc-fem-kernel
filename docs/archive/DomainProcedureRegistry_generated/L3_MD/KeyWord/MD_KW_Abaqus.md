# `MD_KW_Abaqus.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Abaqus.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_KW_Abaqus`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Abaqus`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW_Abaqus`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Abaqus.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `kw_get_supported_keywords` | 54 | `SUBROUTINE kw_get_supported_keywords(keywords, count)` |
| SUBROUTINE | `kw_init_keyword_system` | 72 | `SUBROUTINE kw_init_keyword_system()` |
| SUBROUTINE | `kw_map_ast_to_model` | 79 | `SUBROUTINE kw_map_ast_to_model(parser, model, success)` |
| SUBROUTINE | `kw_parse_inp_file` | 91 | `SUBROUTINE kw_parse_inp_file(filename, model, success, verbose)` |
| SUBROUTINE | `kw_parse_inp_to_ast` | 167 | `SUBROUTINE kw_parse_inp_to_ast(filename, parser, success)` |
| SUBROUTINE | `kw_print_statistics` | 177 | `SUBROUTINE kw_print_statistics(parser, mapper)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
