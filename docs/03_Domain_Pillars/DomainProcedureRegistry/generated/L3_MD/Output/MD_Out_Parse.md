# `MD_Out_Parse.f90`

- **Source**: `L3_MD/Output/MD_Out_Parse.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Out_Parse`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_Parse`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out`
- **第四段角色（四段式）**: `_Parse`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_Parse.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `md_out_get_param_value` | 137 | `SUBROUTINE md_out_get_param_value(ast_node, param_name, param_value)` |
| SUBROUTINE | `OutRequestProperties_Init` | 156 | `SUBROUTINE OutRequestProperties_Init(this, name, status)` |
| FUNCTION | `OutRequestProperties_Valid_Fn` | 167 | `FUNCTION OutRequestProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `OutRequestProperties_Clear` | 173 | `SUBROUTINE OutRequestProperties_Clear(this)` |
| SUBROUTINE | `UF_FieldOutput_GetStatistics` | 181 | `SUBROUTINE UF_FieldOutput_GetStatistics(output_req, stats, status)` |
| SUBROUTINE | `UF_FieldOutput_ShouldOutput` | 192 | `SUBROUTINE UF_FieldOutput_ShouldOutput(output_req, current_time, time_step, should_output, status)` |
| SUBROUTINE | `UF_HistoryOutput_GetStatistics` | 206 | `SUBROUTINE UF_HistoryOutput_GetStatistics(output_req, stats, status)` |
| SUBROUTINE | `UF_HistoryOutput_ShouldOutput` | 217 | `SUBROUTINE UF_HistoryOutput_ShouldOutput(output_req, current_time, time_step, should_output, status)` |
| SUBROUTINE | `MD_Output_OutputRequest_Unified_Configure` | 231 | `SUBROUTINE MD_Output_OutputRequest_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Output_OutputRequest_Unified_Parse` | 243 | `SUBROUTINE MD_Output_OutputRequest_Unified_Parse(out_type, ast_node, outputRequest, context_name, status)` |
| SUBROUTINE | `Parse_OUTPUT_REQUEST_Keyword` | 258 | `SUBROUTINE Parse_OUTPUT_REQUEST_Keyword(ast_node, outputRequest, name, status)` |
| SUBROUTINE | `OutVariableProperties_Init` | 274 | `SUBROUTINE OutVariableProperties_Init(this, name, status)` |
| FUNCTION | `OutVariableProperties_Valid_Fn` | 283 | `FUNCTION OutVariableProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `OutVariableProperties_Clear` | 289 | `SUBROUTINE OutVariableProperties_Clear(this)` |
| SUBROUTINE | `MD_Output_OutputVariable_Unified_Configure` | 296 | `SUBROUTINE MD_Output_OutputVariable_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Output_OutputVariable_Unified_Parse` | 308 | `SUBROUTINE MD_Output_OutputVariable_Unified_Parse(out_type, ast_node, outputVariable, context_name, status)` |
| SUBROUTINE | `Parse_OUTPUT_VARIABLE_Keyword` | 323 | `SUBROUTINE Parse_OUTPUT_VARIABLE_Keyword(ast_node, outputVariable, name, status)` |
| SUBROUTINE | `OutFrequencyProperties_Init` | 339 | `SUBROUTINE OutFrequencyProperties_Init(this, name, status)` |
| FUNCTION | `OutFrequencyProperties_Valid_Fn` | 349 | `FUNCTION OutFrequencyProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `OutFrequencyProperties_Clear` | 357 | `SUBROUTINE OutFrequencyProperties_Clear(this)` |
| SUBROUTINE | `MD_Output_OutputFrequency_Unified_Configure` | 364 | `SUBROUTINE MD_Output_OutputFrequency_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Output_OutputFrequency_Unified_Parse` | 376 | `SUBROUTINE MD_Output_OutputFrequency_Unified_Parse(out_type, ast_node, outputFrequency, context_name, status)` |
| SUBROUTINE | `Parse_OUTPUT_FREQUENCY_Keyword` | 391 | `SUBROUTINE Parse_OUTPUT_FREQUENCY_Keyword(ast_node, outputFrequency, name, status)` |
| SUBROUTINE | `Validate_OUTPUT_FREQUENCY_Keyword` | 408 | `SUBROUTINE Validate_OUTPUT_FREQUENCY_Keyword(outputFrequency, status)` |
| SUBROUTINE | `OutFormatProperties_Init` | 421 | `SUBROUTINE OutFormatProperties_Init(this, name, status)` |
| FUNCTION | `OutFormatProperties_Valid_Fn` | 441 | `FUNCTION OutFormatProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `OutFormatProperties_Clear` | 449 | `SUBROUTINE OutFormatProperties_Clear(this)` |
| FUNCTION | `OutFormatProperties_GetFileExtension` | 466 | `FUNCTION OutFormatProperties_GetFileExtension(this) RESULT(ext)` |
| SUBROUTINE | `MD_Output_OutputFormat_Unified_Configure` | 480 | `SUBROUTINE MD_Output_OutputFormat_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Output_OutputFormat_Unified_Parse` | 492 | `SUBROUTINE MD_Output_OutputFormat_Unified_Parse(out_type, ast_node, outputFormat, context_name, status)` |
| SUBROUTINE | `Parse_OUTPUT_FORMAT_Keyword` | 508 | `SUBROUTINE Parse_OUTPUT_FORMAT_Keyword(ast_node, outputFormat, name, status)` |
| SUBROUTINE | `Valid_OUTPUT_FORMAT_Keyword` | 548 | `SUBROUTINE Valid_OUTPUT_FORMAT_Keyword(outputFormat, status)` |
| SUBROUTINE | `OutFilterProperties_Init` | 561 | `SUBROUTINE OutFilterProperties_Init(this, name, status)` |
| FUNCTION | `OutFilterProperties_Valid_Fn` | 581 | `FUNCTION OutFilterProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `OutFilterProperties_Clear` | 592 | `SUBROUTINE OutFilterProperties_Clear(this)` |
| SUBROUTINE | `OutFilterProperties_AddVariable` | 609 | `SUBROUTINE OutFilterProperties_AddVariable(this, variableName, status)` |
| SUBROUTINE | `OutFilterProperties_AddNodeSet` | 632 | `SUBROUTINE OutFilterProperties_AddNodeSet(this, nodeSetName, status)` |
| SUBROUTINE | `OutFilterProperties_AddElementSet` | 655 | `SUBROUTINE OutFilterProperties_AddElementSet(this, elementSetName, status)` |
| SUBROUTINE | `OutFilterProperties_AddSurface` | 678 | `SUBROUTINE OutFilterProperties_AddSurface(this, surfaceName, status)` |
| FUNCTION | `OutFilterProperties_MatchesVariable` | 701 | `FUNCTION OutFilterProperties_MatchesVariable(this, variableName) RESULT(matches)` |
| FUNCTION | `OutFilterProperties_MatchesRegion` | 721 | `FUNCTION OutFilterProperties_MatchesRegion(this, nodeSetName, elementSetName, surfaceName) RESULT(matches)` |
| FUNCTION | `OutFilterProperties_MatchesValue` | 754 | `FUNCTION OutFilterProperties_MatchesValue(this, value) RESULT(matches)` |
| SUBROUTINE | `MD_Output_OutputFilter_Unified_Configure` | 772 | `SUBROUTINE MD_Output_OutputFilter_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Output_OutputFilter_Unified_Parse` | 784 | `SUBROUTINE MD_Output_OutputFilter_Unified_Parse(out_type, ast_node, outputFilter, context_name, status)` |
| SUBROUTINE | `Parse_OUTPUT_FILTER_Keyword` | 799 | `SUBROUTINE Parse_OUTPUT_FILTER_Keyword(ast_node, outputFilter, name, status)` |
| SUBROUTINE | `parse_region_list` | 842 | `SUBROUTINE parse_region_list(ast_node, outputFilter, status)` |
| SUBROUTINE | `parse_threshold` | 867 | `SUBROUTINE parse_threshold(ast_node, outputFilter, status)` |
| SUBROUTINE | `parse_variable_list` | 888 | `SUBROUTINE parse_variable_list(ast_node, outputFilter, status)` |
| SUBROUTINE | `Valid_OUTPUT_FILTER_Keyword` | 910 | `SUBROUTINE Valid_OUTPUT_FILTER_Keyword(outputFilter, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
