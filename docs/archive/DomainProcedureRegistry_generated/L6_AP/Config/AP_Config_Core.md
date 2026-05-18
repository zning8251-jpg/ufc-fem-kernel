# `AP_Config_Core.f90`

- **Source**: `L6_AP/Config/AP_Config_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Config_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Config_Core`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Config`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Config`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Config/AP_Config_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Config_Core_Init` | 35 | `SUBROUTINE AP_Config_Core_Init(desc, state, status)` |
| SUBROUTINE | `AP_Config_Core_Finalize` | 54 | `SUBROUTINE AP_Config_Core_Finalize(desc, state, status)` |
| FUNCTION | `find_entry` | 67 | `FUNCTION find_entry(state, key) RESULT(idx)` |
| SUBROUTINE | `AP_Config_Set_Int` | 86 | `SUBROUTINE AP_Config_Set_Int(state, key, value, status)` |
| SUBROUTINE | `AP_Config_Set_Real` | 114 | `SUBROUTINE AP_Config_Set_Real(state, key, value, status)` |
| SUBROUTINE | `AP_Config_Set_String` | 142 | `SUBROUTINE AP_Config_Set_String(state, key, value, status)` |
| SUBROUTINE | `AP_Config_Get_Int` | 170 | `SUBROUTINE AP_Config_Get_Int(state, key, value, status)` |
| SUBROUTINE | `AP_Config_Get_Real` | 193 | `SUBROUTINE AP_Config_Get_Real(state, key, value, status)` |
| SUBROUTINE | `AP_Config_Get_String` | 216 | `SUBROUTINE AP_Config_Get_String(state, key, value, status)` |
| SUBROUTINE | `AP_Config_Parse_CommandLine` | 239 | `SUBROUTINE AP_Config_Parse_CommandLine(state, status)` |
| SUBROUTINE | `AP_Config_Print` | 250 | `SUBROUTINE AP_Config_Print(desc, state, unit_num, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
