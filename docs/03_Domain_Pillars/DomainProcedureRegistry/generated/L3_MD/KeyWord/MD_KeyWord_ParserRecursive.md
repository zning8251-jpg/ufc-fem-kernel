# `MD_KeyWord_ParserRecursive.f90`

- **Source**: `L3_MD/KeyWord/MD_KeyWord_ParserRecursive.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KeyWord_ParserRecursive`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KeyWord_ParserRecursive`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KeyWord_ParserRecursive`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KeyWord_ParserRecursive.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Initialize_KeyWord_Rules` | 35 | `SUBROUTINE MD_Initialize_KeyWord_Rules(status)` |
| SUBROUTINE | `MD_Parse_Line` | 113 | `SUBROUTINE MD_Parse_Line(line, is_keyword, keyword, params, status)` |
| SUBROUTINE | `MD_Parse_Parameters` | 169 | `SUBROUTINE MD_Parse_Parameters(line, params, n_params, status)` |
| SUBROUTINE | `MD_Parse_KeyWord_Block` | 217 | `RECURSIVE SUBROUTINE MD_Parse_KeyWord_Block(inp_unit, parent_keyword, &` |
| SUBROUTINE | `MD_Validate_KeyWord_Tree` | 385 | `SUBROUTINE MD_Validate_KeyWord_Tree(root_node, status)` |
| SUBROUTINE | `validate_node_recursive` | 398 | `RECURSIVE SUBROUTINE validate_node_recursive(node, parent_keyword, status)` |
| SUBROUTINE | `MD_Map_KeyWord_Tree_To_Model` | 487 | `SUBROUTINE MD_Map_KeyWord_Tree_To_Model(root_node, status)` |
| SUBROUTINE | `map_keyword_node` | 513 | `RECURSIVE SUBROUTINE map_keyword_node(node, status)` |
| SUBROUTINE | `map_part_keyword` | 616 | `SUBROUTINE map_part_keyword(node, status)` |
| SUBROUTINE | `map_node_keyword` | 638 | `SUBROUTINE map_node_keyword(node, status)` |
| SUBROUTINE | `map_element_keyword` | 664 | `SUBROUTINE map_element_keyword(node, status)` |
| SUBROUTINE | `map_material_keyword` | 695 | `SUBROUTINE map_material_keyword(node, status)` |
| SUBROUTINE | `map_elastic_keyword` | 716 | `SUBROUTINE map_elastic_keyword(node, status)` |
| SUBROUTINE | `map_step_keyword` | 733 | `SUBROUTINE map_step_keyword(node, status)` |
| SUBROUTINE | `map_static_keyword` | 754 | `SUBROUTINE map_static_keyword(node, status)` |
| SUBROUTINE | `map_boundary_keyword` | 765 | `SUBROUTINE map_boundary_keyword(node, status)` |
| SUBROUTINE | `map_load_keyword` | 779 | `SUBROUTINE map_load_keyword(node, status)` |
| SUBROUTINE | `map_section_keyword` | 793 | `SUBROUTINE map_section_keyword(node, status)` |
| FUNCTION | `is_child_keyword` | 808 | `FUNCTION is_child_keyword(keyword, parent_keyword) RESULT(is_child)` |
| FUNCTION | `keyword_has_data_block` | 836 | `FUNCTION keyword_has_data_block(keyword) RESULT(has_data)` |
| SUBROUTINE | `parse_data_block_to_matrix` | 851 | `SUBROUTINE parse_data_block_to_matrix(data_lines, n_rows, matrix, status)` |
| SUBROUTINE | `find_rule_by_keyword` | 874 | `SUBROUTINE find_rule_by_keyword(keyword, rule_idx, status)` |
| SUBROUTINE | `map_assembly_keyword` | 899 | `SUBROUTINE map_assembly_keyword(node, status)` |
| SUBROUTINE | `map_instance_keyword` | 920 | `SUBROUTINE map_instance_keyword(node, status)` |
| SUBROUTINE | `map_contact_pair_keyword` | 945 | `SUBROUTINE map_contact_pair_keyword(node, status)` |
| SUBROUTINE | `map_surface_interaction_keyword` | 973 | `SUBROUTINE map_surface_interaction_keyword(node, status)` |
| SUBROUTINE | `map_friction_keyword` | 995 | `SUBROUTINE map_friction_keyword(node, status)` |
| SUBROUTINE | `map_amplitude_keyword` | 1012 | `SUBROUTINE map_amplitude_keyword(node, status)` |
| SUBROUTINE | `map_orientation_keyword` | 1037 | `SUBROUTINE map_orientation_keyword(node, status)` |
| SUBROUTINE | `map_property_keyword` | 1066 | `SUBROUTINE map_property_keyword(node, status)` |
| SUBROUTINE | `map_restart_keyword` | 1091 | `SUBROUTINE map_restart_keyword(node, status)` |
| SUBROUTINE | `map_output_keyword` | 1117 | `SUBROUTINE map_output_keyword(node, status)` |
| SUBROUTINE | `map_fieldoutput_keyword` | 1142 | `SUBROUTINE map_fieldoutput_keyword(node, status)` |
| SUBROUTINE | `map_nodeoutput_keyword` | 1167 | `SUBROUTINE map_nodeoutput_keyword(node, status)` |
| SUBROUTINE | `map_elementoutput_keyword` | 1189 | `SUBROUTINE map_elementoutput_keyword(node, status)` |
| SUBROUTINE | `map_print_keyword` | 1211 | `SUBROUTINE map_print_keyword(node, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
