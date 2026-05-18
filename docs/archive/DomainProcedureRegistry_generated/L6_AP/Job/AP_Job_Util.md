# `AP_Job_Util.f90`

- **Source**: `L6_AP/Job/AP_Job_Util.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Job_Util`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Job_Util`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Job`
- **第四段角色（四段式）**: `_Util`
- **源码子路径（层下目录，不含文件名）**: `Job`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Job/AP_Job_Util.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `AP_Cmd_ExtractName` | 76 | `FUNCTION AP_Cmd_ExtractName(cmd_str) RESULT(name)` |
| SUBROUTINE | `AP_Cmd_ExtractNumericParams` | 89 | `SUBROUTINE AP_Cmd_ExtractNumericParams(cmd, params, num_params)` |
| FUNCTION | `AP_Cmd_ExtractOption` | 104 | `FUNCTION AP_Cmd_ExtractOption(cmd_str) RESULT(option)` |
| FUNCTION | `AP_Cmd_ExtractStringParams` | 120 | `FUNCTION AP_Cmd_ExtractStringParams(cmd) RESULT(param_str)` |
| FUNCTION | `AP_Cmd_FormatCommand` | 126 | `FUNCTION AP_Cmd_FormatCommand(cmd) RESULT(cmd_str)` |
| SUBROUTINE | `AP_Cmd_ParseParameters` | 144 | `SUBROUTINE AP_Cmd_ParseParameters(param_str, key_values, num_pairs, status)` |
| SUBROUTINE | `AP_Cmd_ValidateCommand` | 174 | `SUBROUTINE AP_Cmd_ValidateCommand(cmd, is_valid, status)` |
| SUBROUTINE | `AP_CmdUtils_Unified_Cfg` | 201 | `SUBROUTINE AP_CmdUtils_Unified_Cfg(operation, status)` |
| SUBROUTINE | `AP_CmdUtils_Unified_Execute` | 214 | `SUBROUTINE AP_CmdUtils_Unified_Execute(operation, cmd, is_valid, status)` |
| FUNCTION | `AP_File_GetBasename` | 234 | `FUNCTION AP_File_GetBasename(filepath) RESULT(basename)` |
| FUNCTION | `AP_File_GetExtension` | 247 | `FUNCTION AP_File_GetExtension(filepath) RESULT(ext)` |
| FUNCTION | `AP_File_JoinPath` | 260 | `FUNCTION AP_File_JoinPath(path1, path2) RESULT(joined_path)` |
| FUNCTION | `AP_File_NormalizePath` | 280 | `FUNCTION AP_File_NormalizePath(filepath) RESULT(normalized_path)` |
| FUNCTION | `AP_File_IsAbsolutePath` | 300 | `FUNCTION AP_File_IsAbsolutePath(filepath) RESULT(is_abs)` |
| SUBROUTINE | `AP_File_ReadLines` | 325 | `SUBROUTINE AP_File_ReadLines(filename, lines, num_lines, status)` |
| SUBROUTINE | `AP_File_WriteLines` | 358 | `SUBROUTINE AP_File_WriteLines(filename, lines, num_lines, status)` |
| SUBROUTINE | `AP_File_Unified_Cfg` | 384 | `SUBROUTINE AP_File_Unified_Cfg(operation, status)` |
| SUBROUTINE | `AP_File_Unified_Execute` | 397 | `SUBROUTINE AP_File_Unified_Execute(operation, filename, lines, num_lines, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
