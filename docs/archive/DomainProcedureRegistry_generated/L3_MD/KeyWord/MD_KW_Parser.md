# `MD_KW_Parser.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Parser.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_KW_Parser`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Parser`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW_Parser`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Parser.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `kw_parser_init` | 33 | `SUBROUTINE kw_parser_init(state, max_nodes)` |
| SUBROUTINE | `kw_parser_parse_file` | 66 | `SUBROUTINE kw_parser_parse_file(state, filename, success)` |
| SUBROUTINE | `parse_keyword` | 112 | `SUBROUTINE parse_keyword(state, keyword_token)` |
| SUBROUTINE | `parse_parameters` | 173 | `SUBROUTINE parse_parameters(state, node)` |
| SUBROUTINE | `add_parameter` | 239 | `SUBROUTINE add_parameter(node, name, value)` |
| SUBROUTINE | `parse_data_lines` | 263 | `SUBROUTINE parse_data_lines(state, node, metadata)` |
| SUBROUTINE | `parse_data_lines_unknown` | 351 | `SUBROUTINE parse_data_lines_unknown(state, node)` |
| SUBROUTINE | `convert_data_value` | 369 | `SUBROUTINE convert_data_value(str, int_val, real_val)` |
| SUBROUTINE | `handle_end_keyword` | 387 | `SUBROUTINE handle_end_keyword(state, kw_name, line_num)` |
| SUBROUTINE | `push_context` | 407 | `SUBROUTINE push_context(state, kw_name, node_id)` |
| SUBROUTINE | `pop_context` | 426 | `SUBROUTINE pop_context(state, base_name, line_num)` |
| SUBROUTINE | `set_parent_context` | 456 | `SUBROUTINE set_parent_context(state, node, node_id)` |
| SUBROUTINE | `add_node` | 488 | `SUBROUTINE add_node(state, node, node_id)` |
| SUBROUTINE | `add_child_to_node` | 510 | `SUBROUTINE add_child_to_node(state, parent_id, child_id)` |
| SUBROUTINE | `add_error` | 530 | `SUBROUTINE add_error(state, line_num, message)` |
| SUBROUTINE | `add_warning` | 544 | `SUBROUTINE add_warning(state, line_num, message)` |
| SUBROUTINE | `kw_parser_get_ast` | 558 | `SUBROUTINE kw_parser_get_ast(state, nodes, count)` |
| FUNCTION | `kw_parser_get_node` | 575 | `FUNCTION kw_parser_get_node(state, node_id) RESULT(node_ptr)` |
| SUBROUTINE | `kw_parser_get_root_nodes` | 591 | `SUBROUTINE kw_parser_get_root_nodes(state, node_ids, count)` |
| FUNCTION | `kw_parser_get_errors` | 619 | `FUNCTION kw_parser_get_errors(state) RESULT(count)` |
| SUBROUTINE | `kw_parser_find_nodes_by_keyword` | 630 | `SUBROUTINE kw_parser_find_nodes_by_keyword(state, keyword_name, node_ids, count)` |
| SUBROUTINE | `kw_parser_cleanup` | 662 | `SUBROUTINE kw_parser_cleanup(state)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
