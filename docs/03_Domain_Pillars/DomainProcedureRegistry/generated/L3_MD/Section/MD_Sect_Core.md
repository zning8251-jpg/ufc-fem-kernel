# `MD_Sect_Core.f90`

- **Source**: `L3_MD/Section/MD_Sect_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Sect_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Section_Core_Init` | 31 | `SUBROUTINE MD_Section_Core_Init(desc, state, status)` |
| SUBROUTINE | `MD_Section_Core_Finalize` | 57 | `SUBROUTINE MD_Section_Core_Finalize(desc, state, status)` |
| SUBROUTINE | `MD_Section_Add` | 72 | `SUBROUTINE MD_Section_Add(desc, id, name, section_type, material_id, status)` |
| SUBROUTINE | `MD_Section_Get_By_ID` | 112 | `SUBROUTINE MD_Section_Get_By_ID(desc, id, section, status)` |
| SUBROUTINE | `MD_Section_Get_Material_ID` | 133 | `SUBROUTINE MD_Section_Get_Material_ID(desc, section_id, mat_id, status)` |
| SUBROUTINE | `MD_Section_Set_Thickness` | 155 | `SUBROUTINE MD_Section_Set_Thickness(desc, section_id, thickness, status)` |
| SUBROUTINE | `MD_Section_Validate` | 176 | `SUBROUTINE MD_Section_Validate(desc, status)` |
| SUBROUTINE | `MD_Section_Validate_Triple` | 201 | `SUBROUTINE MD_Section_Validate_Triple(sect_fam, mat_type, elem_fam, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
