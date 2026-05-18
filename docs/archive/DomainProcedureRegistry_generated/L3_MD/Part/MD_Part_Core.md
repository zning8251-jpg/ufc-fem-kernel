# `MD_Part_Core.f90`

- **Source**: `L3_MD/Part/MD_Part_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Part_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Part_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Part`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Part`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Part/MD_Part_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Part_Core_Init` | 37 | `SUBROUTINE MD_Part_Core_Init(desc, state, status)` |
| SUBROUTINE | `MD_Part_Core_Finalize` | 66 | `SUBROUTINE MD_Part_Core_Finalize(desc, state, status)` |
| SUBROUTINE | `MD_Part_Add` | 84 | `SUBROUTINE MD_Part_Add(desc, id, name, status)` |
| SUBROUTINE | `MD_Part_Get_By_ID` | 125 | `SUBROUTINE MD_Part_Get_By_ID(desc, id, part, status)` |
| SUBROUTINE | `MD_Part_Assign_Section` | 151 | `SUBROUTINE MD_Part_Assign_Section(desc, part_id, section_id, status)` |
| SUBROUTINE | `MD_Part_Validate` | 177 | `SUBROUTINE MD_Part_Validate(desc, status)` |
| SUBROUTINE | `MD_Part_Get_By_Name` | 200 | `SUBROUTINE MD_Part_Get_By_Name(desc, name, part, part_idx, status)` |
| SUBROUTINE | `MD_Part_Clone` | 231 | `SUBROUTINE MD_Part_Clone(desc, src_id, new_id, new_name, status)` |
| SUBROUTINE | `MD_Part_Transform` | 299 | `SUBROUTINE MD_Part_Transform(desc, part_id, translation, rotation, status)` |
| SUBROUTINE | `MD_Part_Append_To_Domain` | 327 | `SUBROUTINE MD_Part_Append_To_Domain(domain, id, name, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
