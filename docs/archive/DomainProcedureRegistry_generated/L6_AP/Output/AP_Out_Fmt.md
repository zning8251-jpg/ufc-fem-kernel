# `AP_Out_Fmt.f90`

- **Source**: `L6_AP/Output/AP_Out_Fmt.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Out_Fmt`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Out_Fmt`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Out_Fmt`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Output/AP_Out_Fmt.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `FormatProperties` (lines 38–40)

```fortran
    TYPE, PUBLIC :: FormatProperties
        TYPE(AP_Output_Format_Props) :: inner
    END TYPE FormatProperties
```

### `NodeFileProperties` (lines 53–55)

```fortran
    TYPE, PUBLIC :: NodeFileProperties
        TYPE(AP_Output_NodeFile_Props) :: inner
    END TYPE NodeFileProperties
```

### `ElFileProperties` (lines 68–70)

```fortran
    TYPE, PUBLIC :: ElFileProperties
        TYPE(AP_Output_ElFile_Props) :: inner
    END TYPE ElFileProperties
```

### `PreprintProperties` (lines 84–86)

```fortran
    TYPE, PUBLIC :: PreprintProperties
        TYPE(AP_Output_Preprint_Props) :: inner
    END TYPE PreprintProperties
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Valid_USER_OUTPUT_Keyword` | 115 | `SUBROUTINE Valid_USER_OUTPUT_Keyword(userOutput, status)` |
| SUBROUTINE | `AP_Output_Format_Init` | 125 | `SUBROUTINE AP_Output_Format_Init(this, formatType, status)` |
| SUBROUTINE | `AP_Output_Format_Valid` | 133 | `SUBROUTINE AP_Output_Format_Valid(this, status)` |
| SUBROUTINE | `AP_Output_Format_Clear` | 139 | `SUBROUTINE AP_Output_Format_Clear(this)` |
| SUBROUTINE | `AP_Output_Format_Parse` | 144 | `SUBROUTINE AP_Output_Format_Parse(ast_node, format_prop, status)` |
| SUBROUTINE | `Parse_FILE_FORMAT_Keyword` | 152 | `SUBROUTINE Parse_FILE_FORMAT_Keyword(ast_node, format_prop, status)` |
| SUBROUTINE | `AP_Output_Format_UnifiedParse` | 159 | `SUBROUTINE AP_Output_Format_UnifiedParse(output_type, ast_node, format_prop, status)` |
| SUBROUTINE | `AP_Output_Format_Unified_Parse` | 173 | `SUBROUTINE AP_Output_Format_Unified_Parse(output_type, ast_node, format_prop, status)` |
| SUBROUTINE | `AP_Out_Format_UnifiedCfg_Impl` | 182 | `SUBROUTINE AP_Out_Format_UnifiedCfg_Impl(operation, status)` |
| SUBROUTINE | `AP_Output_Format_UnifiedCfg` | 194 | `SUBROUTINE AP_Output_Format_UnifiedCfg(operation, status)` |
| SUBROUTINE | `AP_Output_Format_Unified_Cfg` | 200 | `SUBROUTINE AP_Output_Format_Unified_Cfg(operation, status)` |
| SUBROUTINE | `AP_Output_Format_ValidKw` | 206 | `SUBROUTINE AP_Output_Format_ValidKw(format_prop, status)` |
| SUBROUTINE | `Valid_FILE_FORMAT_Keyword` | 213 | `SUBROUTINE Valid_FILE_FORMAT_Keyword(format_prop, status)` |
| SUBROUTINE | `AP_Output_NodeFile_Init` | 222 | `SUBROUTINE AP_Output_NodeFile_Init(this, fileName, status)` |
| SUBROUTINE | `AP_Output_NodeFile_Valid` | 230 | `SUBROUTINE AP_Output_NodeFile_Valid(this, status)` |
| SUBROUTINE | `AP_Output_NodeFile_Clear` | 236 | `SUBROUTINE AP_Output_NodeFile_Clear(this)` |
| SUBROUTINE | `AP_Output_NodeFile_Parse` | 241 | `SUBROUTINE AP_Output_NodeFile_Parse(ast_node, nodeFile, status)` |
| SUBROUTINE | `Parse_NODE_FILE_Keyword` | 249 | `SUBROUTINE Parse_NODE_FILE_Keyword(ast_node, nodeFile, status)` |
| SUBROUTINE | `AP_Output_NodeFile_UnifiedParse` | 256 | `SUBROUTINE AP_Output_NodeFile_UnifiedParse(output_type, ast_node, nodeFile, status)` |
| SUBROUTINE | `AP_Output_NodeFile_Unified_Parse` | 270 | `SUBROUTINE AP_Output_NodeFile_Unified_Parse(output_type, ast_node, nodeFile, status)` |
| SUBROUTINE | `AP_Output_NodeFile_UnifiedCfg` | 278 | `SUBROUTINE AP_Output_NodeFile_UnifiedCfg(operation, status)` |
| SUBROUTINE | `AP_Output_NodeFile_Unified_Configure` | 284 | `SUBROUTINE AP_Output_NodeFile_Unified_Configure(operation, status)` |
| SUBROUTINE | `AP_Output_NodeFile_ValidKw` | 290 | `SUBROUTINE AP_Output_NodeFile_ValidKw(nodeFile, status)` |
| SUBROUTINE | `Valid_NODE_FILE_Keyword` | 297 | `SUBROUTINE Valid_NODE_FILE_Keyword(nodeFile, status)` |
| SUBROUTINE | `AP_Output_ElFile_Init` | 306 | `SUBROUTINE AP_Output_ElFile_Init(this, fileName, status)` |
| SUBROUTINE | `AP_Output_ElFile_Valid` | 314 | `SUBROUTINE AP_Output_ElFile_Valid(this, status)` |
| SUBROUTINE | `AP_Output_ElFile_Clear` | 320 | `SUBROUTINE AP_Output_ElFile_Clear(this)` |
| SUBROUTINE | `AP_Output_ElFile_Parse` | 325 | `SUBROUTINE AP_Output_ElFile_Parse(ast_node, elFile, status)` |
| SUBROUTINE | `Parse_EL_FILE_Keyword` | 333 | `SUBROUTINE Parse_EL_FILE_Keyword(ast_node, elFile, status)` |
| SUBROUTINE | `AP_Output_ElFile_UnifiedParse` | 340 | `SUBROUTINE AP_Output_ElFile_UnifiedParse(output_type, ast_node, elFile, status)` |
| SUBROUTINE | `AP_Output_Unified_Parse` | 354 | `SUBROUTINE AP_Output_Unified_Parse(output_type, ast_node, elFile, status)` |
| SUBROUTINE | `AP_Output_ElFile_UnifiedCfg` | 362 | `SUBROUTINE AP_Output_ElFile_UnifiedCfg(operation, status)` |
| SUBROUTINE | `AP_Output_Unified_Cfg` | 368 | `SUBROUTINE AP_Output_Unified_Cfg(operation, status)` |
| SUBROUTINE | `AP_Output_ElFile_ValidKw` | 374 | `SUBROUTINE AP_Output_ElFile_ValidKw(elFile, status)` |
| SUBROUTINE | `Valid_EL_FILE_Keyword` | 381 | `SUBROUTINE Valid_EL_FILE_Keyword(elFile, status)` |
| SUBROUTINE | `AP_Output_Preprint_Init` | 390 | `SUBROUTINE AP_Output_Preprint_Init(this, echo, model, status)` |
| SUBROUTINE | `AP_Output_Preprint_Valid` | 399 | `SUBROUTINE AP_Output_Preprint_Valid(this, status)` |
| SUBROUTINE | `AP_Output_Preprint_Clear` | 405 | `SUBROUTINE AP_Output_Preprint_Clear(this)` |
| SUBROUTINE | `get_param_value` | 411 | `SUBROUTINE get_param_value(ast_node, param_name, param_value)` |
| SUBROUTINE | `AP_Output_Preprint_Parse` | 427 | `SUBROUTINE AP_Output_Preprint_Parse(ast_node, preprint, status)` |
| SUBROUTINE | `Parse_PREPRINT_Keyword` | 447 | `SUBROUTINE Parse_PREPRINT_Keyword(ast_node, preprint, status)` |
| SUBROUTINE | `AP_Output_Preprint_UnifiedParse` | 454 | `SUBROUTINE AP_Output_Preprint_UnifiedParse(output_type, ast_node, preprint, status)` |
| SUBROUTINE | `AP_Output_Preprint_Unified_Parse` | 468 | `SUBROUTINE AP_Output_Preprint_Unified_Parse(output_type, ast_node, preprint, status)` |
| SUBROUTINE | `AP_Output_Preprint_UnifiedCfg` | 476 | `SUBROUTINE AP_Output_Preprint_UnifiedCfg(operation, status)` |
| SUBROUTINE | `AP_Output_Preprint_Unified_Configure` | 482 | `SUBROUTINE AP_Output_Preprint_Unified_Configure(operation, status)` |
| SUBROUTINE | `AP_Output_Preprint_ValidKw` | 488 | `SUBROUTINE AP_Output_Preprint_ValidKw(preprint, status)` |
| SUBROUTINE | `Valid_PREPRINT_Keyword` | 495 | `SUBROUTINE Valid_PREPRINT_Keyword(preprint, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
