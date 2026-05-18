# `MD_KW_Reg.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Reg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KW_Reg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Reg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW`
- **第四段角色（四段式）**: `_Reg`
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Reg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `hash_string` | 78 | `FUNCTION hash_string(str) RESULT(hash)` |
| SUBROUTINE | `MD_KW_Registry_Initialize` | 97 | `SUBROUTINE MD_KW_Registry_Initialize(this, max_capacity, status)` |
| SUBROUTINE | `MD_KW_Registry_Cleanup` | 185 | `SUBROUTINE MD_KW_Registry_Cleanup(this, status)` |
| SUBROUTINE | `MD_KW_Registry_Register` | 202 | `SUBROUTINE MD_KW_Registry_Register(this, name, item, status)` |
| SUBROUTINE | `MD_KW_Registry_Unregister` | 219 | `SUBROUTINE MD_KW_Registry_Unregister(this, name, status)` |
| FUNCTION | `MD_KW_Registry_Lookup` | 257 | `FUNCTION MD_KW_Registry_Lookup(this, name) RESULT(found)` |
| FUNCTION | `MD_KW_Registry_Exists` | 271 | `FUNCTION MD_KW_Registry_Exists(this, name) RESULT(exists)` |
| FUNCTION | `MD_KW_Registry_GetRegisteredCount` | 280 | `FUNCTION MD_KW_Registry_GetRegisteredCount(this) RESULT(count)` |
| SUBROUTINE | `MD_KW_Registry_ListRegistered` | 287 | `SUBROUTINE MD_KW_Registry_ListRegistered(this, names, count, status)` |
| FUNCTION | `MD_KW_Registry_FindKeywordIndex` | 316 | `FUNCTION MD_KW_Registry_FindKeywordIndex(this, name) RESULT(idx)` |
| FUNCTION | `MD_KW_Registry_FindKeyword` | 335 | `FUNCTION MD_KW_Registry_FindKeyword(this, name) RESULT(ptr)` |
| SUBROUTINE | `MD_KW_Registry_RegisterKeyword` | 366 | `SUBROUTINE MD_KW_Registry_RegisterKeyword(this, keyword_name, category, description, status)` |
| SUBROUTINE | `MD_KW_Registry_RemoveFromHashTable` | 422 | `SUBROUTINE MD_KW_Registry_RemoveFromHashTable(this, name)` |
| FUNCTION | `kw_is_initialized` | 451 | `FUNCTION kw_is_initialized() RESULT(is_init)` |
| SUBROUTINE | `kw_registry_init` | 456 | `SUBROUTINE kw_registry_init()` |
| SUBROUTINE | `kw_registry_register` | 464 | `SUBROUTINE kw_registry_register(keyword_name, category, description, success)` |
| FUNCTION | `kw_registry_find` | 483 | `FUNCTION kw_registry_find(keyword_name) RESULT(metadata_ptr)` |
| FUNCTION | `kw_registry_exists` | 497 | `FUNCTION kw_registry_exists(keyword_name) RESULT(exists)` |
| FUNCTION | `kw_registry_get_count` | 509 | `FUNCTION kw_registry_get_count() RESULT(count)` |
| SUBROUTINE | `kw_registry_get_all` | 517 | `SUBROUTINE kw_registry_get_all(keywords, count)` |
| SUBROUTINE | `kw_registry_add_param` | 533 | `SUBROUTINE kw_registry_add_param(keyword_name, param_name, param_type, &` |
| SUBROUTINE | `kw_registry_set_data_spec` | 568 | `SUBROUTINE kw_registry_set_data_spec(keyword_name, has_data, min_lines, max_lines, cols)` |
| SUBROUTINE | `kw_registry_set_hierarchy` | 587 | `SUBROUTINE kw_registry_set_hierarchy(keyword_name, requires_end, end_keyword, &` |
| SUBROUTINE | `register_model_keywords` | 614 | `SUBROUTINE register_model_keywords(registry)` |
| SUBROUTINE | `register_mesh_keywords` | 639 | `SUBROUTINE register_mesh_keywords(registry)` |
| SUBROUTINE | `register_part_keywords` | 726 | `SUBROUTINE register_part_keywords()` |
| SUBROUTINE | `register_material_keywords` | 770 | `SUBROUTINE register_material_keywords()` |
| SUBROUTINE | `register_section_keywords` | 889 | `SUBROUTINE register_section_keywords()` |
| SUBROUTINE | `register_constraint_keywords` | 938 | `SUBROUTINE register_constraint_keywords()` |
| SUBROUTINE | `register_load_keywords` | 998 | `SUBROUTINE register_load_keywords()` |
| SUBROUTINE | `register_contact_keywords` | 1064 | `SUBROUTINE register_contact_keywords()` |
| SUBROUTINE | `register_step_keywords` | 1127 | `SUBROUTINE register_step_keywords()` |
| SUBROUTINE | `register_output_keywords` | 1267 | `SUBROUTINE register_output_keywords()` |
| SUBROUTINE | `register_amplitude_keywords` | 1343 | `SUBROUTINE register_amplitude_keywords()` |
| SUBROUTINE | `register_special_keywords` | 1358 | `SUBROUTINE register_special_keywords()` |
| SUBROUTINE | `register_advanced_material_keywords` | 1440 | `SUBROUTINE register_advanced_material_keywords()` |
| SUBROUTINE | `register_porous_media_keywords` | 1541 | `SUBROUTINE register_porous_media_keywords()` |
| SUBROUTINE | `register_advanced_contact_keywords` | 1603 | `SUBROUTINE register_advanced_contact_keywords()` |
| SUBROUTINE | `register_advanced_step_keywords` | 1660 | `SUBROUTINE register_advanced_step_keywords()` |
| SUBROUTINE | `register_multiphysics_keywords` | 1718 | `SUBROUTINE register_multiphysics_keywords()` |
| SUBROUTINE | `register_predefined_field_keywords` | 1794 | `SUBROUTINE register_predefined_field_keywords()` |
| SUBROUTINE | `register_connector_keywords` | 1877 | `SUBROUTINE register_connector_keywords()` |
| SUBROUTINE | `register_cohesive_keywords` | 1941 | `SUBROUTINE register_cohesive_keywords()` |
| SUBROUTINE | `register_output_control_keywords` | 1990 | `SUBROUTINE register_output_control_keywords()` |
| SUBROUTINE | `register_optimization_keywords` | 2051 | `SUBROUTINE register_optimization_keywords()` |
| SUBROUTINE | `register_explicit_keywords` | 2094 | `SUBROUTINE register_explicit_keywords()` |
| SUBROUTINE | `register_miscellaneous_keywords` | 2147 | `SUBROUTINE register_miscellaneous_keywords()` |
| SUBROUTINE | `register_constraint_advanced_keywords` | 2240 | `SUBROUTINE register_constraint_advanced_keywords(registry)` |
| SUBROUTINE | `register_interaction_keywords` | 2294 | `SUBROUTINE register_interaction_keywords(registry)` |
| SUBROUTINE | `register_initial_condition_advanced_keywords` | 2343 | `SUBROUTINE register_initial_condition_advanced_keywords(registry)` |
| SUBROUTINE | `register_restart_keywords` | 2388 | `SUBROUTINE register_restart_keywords(registry)` |
| SUBROUTINE | `register_material_tier2_keywords` | 2428 | `SUBROUTINE register_material_tier2_keywords(registry)` |
| SUBROUTINE | `register_section_tier2_keywords` | 2492 | `SUBROUTINE register_section_tier2_keywords(registry)` |
| SUBROUTINE | `register_output_tier2_keywords` | 2536 | `SUBROUTINE register_output_tier2_keywords(registry)` |
| SUBROUTINE | `register_load_tier2_keywords` | 2578 | `SUBROUTINE register_load_tier2_keywords(registry)` |
| SUBROUTINE | `register_analysis_tier3_keywords` | 2618 | `SUBROUTINE register_analysis_tier3_keywords(registry)` |
| SUBROUTINE | `register_constraint_tier3_keywords` | 2671 | `SUBROUTINE register_constraint_tier3_keywords(registry)` |
| SUBROUTINE | `register_load_tier3_keywords` | 2724 | `SUBROUTINE register_load_tier3_keywords(registry)` |
| SUBROUTINE | `register_step_tier3_keywords` | 2783 | `SUBROUTINE register_step_tier3_keywords(registry)` |
| SUBROUTINE | `register_special_tier3_keywords` | 2839 | `SUBROUTINE register_special_tier3_keywords(registry)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
