# `AP_Reg_Core.f90`

- **Source**: `L6_AP/Registry/AP_Reg_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Reg_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Reg_Core`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Reg`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Registry/AP_Reg_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Registry_Core_Init` | 36 | `SUBROUTINE AP_Registry_Core_Init(desc, state, status)` |
| SUBROUTINE | `AP_Registry_Core_Finalize` | 54 | `SUBROUTINE AP_Registry_Core_Finalize(desc, state, status)` |
| SUBROUTINE | `AP_Registry_Register_Element` | 67 | `SUBROUTINE AP_Registry_Register_Element(desc, state, name, type_id, status)` |
| SUBROUTINE | `AP_Registry_Register_Material` | 81 | `SUBROUTINE AP_Registry_Register_Material(desc, state, name, type_id, status)` |
| SUBROUTINE | `AP_Registry_Lookup_Element` | 95 | `SUBROUTINE AP_Registry_Lookup_Element(state, name, type_id, status)` |
| SUBROUTINE | `AP_Registry_Lookup_Material` | 108 | `SUBROUTINE AP_Registry_Lookup_Material(state, name, type_id, status)` |
| FUNCTION | `AP_Registry_Get_Count` | 118 | `FUNCTION AP_Registry_Get_Count(state) RESULT(n)` |
| SUBROUTINE | `AP_Registry_Print` | 127 | `SUBROUTINE AP_Registry_Print(desc, state, unit_num, status)` |
| SUBROUTINE | `register_entry` | 159 | `SUBROUTINE register_entry(state, name, type_id, category, status)` |
| SUBROUTINE | `lookup_entry` | 183 | `SUBROUTINE lookup_entry(state, name, category, type_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
