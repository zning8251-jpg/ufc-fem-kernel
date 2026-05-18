# `MD_Out_ReportPlot.f90`

- **Source**: `L3_MD/Output/MD_Out_ReportPlot.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Out_ReportPlot`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_ReportPlot`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out_ReportPlot`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_ReportPlot.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `rp_get_param_value` | 115 | `SUBROUTINE rp_get_param_value(ast_node, param_name, param_value)` |
| SUBROUTINE | `ReportProperties_Init_Base` | 134 | `SUBROUTINE ReportProperties_Init_Base(this)` |
| SUBROUTINE | `ReportProperties_Init` | 140 | `SUBROUTINE ReportProperties_Init(this, name, status)` |
| FUNCTION | `ReportProperties_Valid_Fn` | 152 | `FUNCTION ReportProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ReportProperties_Clear` | 158 | `SUBROUTINE ReportProperties_Clear(this)` |
| SUBROUTINE | `MD_Output_Report_Unified_Parse` | 167 | `SUBROUTINE MD_Output_Report_Unified_Parse(out_type, ast_node, report, context_name, status)` |
| SUBROUTINE | `MD_Output_Report_Unified_Cfg` | 182 | `SUBROUTINE MD_Output_Report_Unified_Cfg(operation, status)` |
| SUBROUTINE | `Parse_REPORT_Keyword` | 194 | `SUBROUTINE Parse_REPORT_Keyword(ast_node, report, name, status)` |
| SUBROUTINE | `Valid_REPORT_Keyword` | 209 | `SUBROUTINE Valid_REPORT_Keyword(report, status)` |
| SUBROUTINE | `PlotProperties_Init_Base` | 224 | `SUBROUTINE PlotProperties_Init_Base(this)` |
| SUBROUTINE | `PlotProperties_Init` | 230 | `SUBROUTINE PlotProperties_Init(this, name, status)` |
| FUNCTION | `PlotProperties_Valid_Fn` | 241 | `FUNCTION PlotProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `PlotProperties_Clear` | 247 | `SUBROUTINE PlotProperties_Clear(this)` |
| SUBROUTINE | `MD_Output_Plot_Unified_Parse` | 255 | `SUBROUTINE MD_Output_Plot_Unified_Parse(out_type, ast_node, plot, context_name, status)` |
| SUBROUTINE | `MD_Output_Plot_Unified_Cfg` | 270 | `SUBROUTINE MD_Output_Plot_Unified_Cfg(operation, status)` |
| SUBROUTINE | `Parse_PLOT_Keyword` | 282 | `SUBROUTINE Parse_PLOT_Keyword(ast_node, plot, name, status)` |
| SUBROUTINE | `Valid_PLOT_Keyword` | 297 | `SUBROUTINE Valid_PLOT_Keyword(plot, status)` |
| SUBROUTINE | `PostProcessingProperties_Init_Base` | 312 | `SUBROUTINE PostProcessingProperties_Init_Base(this)` |
| SUBROUTINE | `PostProcessingProperties_Init` | 318 | `SUBROUTINE PostProcessingProperties_Init(this, name, status)` |
| FUNCTION | `PostProcessingProperties_Valid_Fn` | 342 | `FUNCTION PostProcessingProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `PostProcessingProperties_Clear` | 353 | `SUBROUTINE PostProcessingProperties_Clear(this)` |
| FUNCTION | `PostProcessingProperties_GetImageExtension` | 373 | `FUNCTION PostProcessingProperties_GetImageExtension(this) RESULT(ext)` |
| SUBROUTINE | `MD_Output_PostProcessing_Unified_Configure` | 385 | `SUBROUTINE MD_Output_PostProcessing_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Output_PostProcessing_Unified_Parse` | 397 | `SUBROUTINE MD_Output_PostProcessing_Unified_Parse(out_type, ast_node, postProcessing, context_name, status)` |
| SUBROUTINE | `Parse_POST_PROCESSING_Keyword` | 412 | `SUBROUTINE Parse_POST_PROCESSING_Keyword(ast_node, postProcessing, name, status)` |
| SUBROUTINE | `Valid_POST_Proc_Keyword` | 466 | `SUBROUTINE Valid_POST_Proc_Keyword(postProcessing, status)` |
| SUBROUTINE | `AnimationProperties_Init_Base` | 481 | `SUBROUTINE AnimationProperties_Init_Base(this)` |
| SUBROUTINE | `AnimationProperties_Init` | 487 | `SUBROUTINE AnimationProperties_Init(this, name, status)` |
| FUNCTION | `AnimationProperties_Valid_Fn` | 499 | `FUNCTION AnimationProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `AnimationProperties_Clear` | 505 | `SUBROUTINE AnimationProperties_Clear(this)` |
| SUBROUTINE | `MD_Output_Animation_Unified_Parse` | 513 | `SUBROUTINE MD_Output_Animation_Unified_Parse(out_type, ast_node, animation, context_name, status)` |
| SUBROUTINE | `MD_Output_Animation_Unified_Configure` | 528 | `SUBROUTINE MD_Output_Animation_Unified_Configure(operation, status)` |
| SUBROUTINE | `Parse_ANIMATION_Keyword` | 540 | `SUBROUTINE Parse_ANIMATION_Keyword(ast_node, animation, name, status)` |
| SUBROUTINE | `Valid_ANIMATION_Keyword` | 559 | `SUBROUTINE Valid_ANIMATION_Keyword(animation, status)` |
| SUBROUTINE | `ExportProperties_Init_Base` | 574 | `SUBROUTINE ExportProperties_Init_Base(this)` |
| SUBROUTINE | `ExportProperties_Init` | 580 | `SUBROUTINE ExportProperties_Init(this, name, status)` |
| FUNCTION | `ExportProperties_Valid_Fn` | 592 | `FUNCTION ExportProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ExportProperties_Clear` | 598 | `SUBROUTINE ExportProperties_Clear(this)` |
| SUBROUTINE | `MD_Output_Export_Unified_Parse` | 606 | `SUBROUTINE MD_Output_Export_Unified_Parse(out_type, ast_node, export, context_name, status)` |
| SUBROUTINE | `MD_Output_Export_Unified_Cfg` | 621 | `SUBROUTINE MD_Output_Export_Unified_Cfg(operation, status)` |
| SUBROUTINE | `Parse_EXPORT_Keyword` | 633 | `SUBROUTINE Parse_EXPORT_Keyword(ast_node, export, name, status)` |
| SUBROUTINE | `Valid_EXPORT_Keyword` | 648 | `SUBROUTINE Valid_EXPORT_Keyword(export, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
