# `MD_KW_Reg_Ext.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Reg_Ext.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KW_Reg_Ext`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Reg_Ext`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW_Reg_Ext`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Reg_Ext.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `register_extended_keywords` | 27 | `SUBROUTINE register_extended_keywords()` |
| SUBROUTINE | `register_connector_ext` | 40 | `SUBROUTINE register_connector_ext()` |
| SUBROUTINE | `register_material_ext` | 72 | `SUBROUTINE register_material_ext()` |
| SUBROUTINE | `register_section_ext` | 127 | `SUBROUTINE register_section_ext()` |
| SUBROUTINE | `register_constraint_ext` | 161 | `SUBROUTINE register_constraint_ext()` |
| SUBROUTINE | `register_step_ext` | 176 | `SUBROUTINE register_step_ext()` |
| SUBROUTINE | `register_contact_ext` | 203 | `SUBROUTINE register_contact_ext()` |
| SUBROUTINE | `register_load_ext` | 218 | `SUBROUTINE register_load_ext()` |
| SUBROUTINE | `register_mesh_ext` | 234 | `SUBROUTINE register_mesh_ext()` |
| SUBROUTINE | `register_ic_ext` | 255 | `SUBROUTINE register_ic_ext()` |
| SUBROUTINE | `register_special_ext` | 265 | `SUBROUTINE register_special_ext()` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
