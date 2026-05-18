# `MD_Sect_Sync.f90`

- **Source**: `L3_MD/Section/MD_Sect_Sync.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Sect_Sync`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_Sync`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect`
- **第四段角色（四段式）**: `_Sync`
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_Sync.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `MapSectionType` | 45 | `FUNCTION MapSectionType(legacy_type) RESULT(sect_type)` |
| FUNCTION | `MdSectType_To_UFSectionType` | 68 | `PURE FUNCTION MdSectType_To_UFSectionType(md_ty) RESULT(uf_ty)` |
| SUBROUTINE | `UF_SectionDef_To_MD_Sect_Desc` | 102 | `SUBROUTINE UF_SectionDef_To_MD_Sect_Desc(legacy_def, mat_ref, sect_desc)` |
| SUBROUTINE | `MD_Section_SyncFromLegacy` | 146 | `SUBROUTINE MD_Section_SyncFromLegacy(model_def, md_layer, status)` |
| SUBROUTINE | `MD_Section_PopulateLegacyFromDomain` | 206 | `SUBROUTINE MD_Section_PopulateLegacyFromDomain(md_layer, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
