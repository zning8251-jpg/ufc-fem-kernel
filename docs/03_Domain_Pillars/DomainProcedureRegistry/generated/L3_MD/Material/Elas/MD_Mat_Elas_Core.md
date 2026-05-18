# `MD_Mat_Elas_Core.f90`

- **Source**: `L3_MD/Material/Elas/MD_Mat_Elas_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Elas_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Elas_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Elas`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Elas`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Elas/MD_Mat_Elas_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mat_Elas_Create_From_Props` | 45 | `SUBROUTINE MD_Mat_Elas_Create_From_Props(desc, sub_type, nprops, props, &` |
| SUBROUTINE | `MD_Mat_Elas_Create_Isotropic` | 82 | `SUBROUTINE MD_Mat_Elas_Create_Isotropic(desc, E, nu, status)` |
| SUBROUTINE | `MD_Mat_Elas_Create_Orthotropic` | 97 | `SUBROUTINE MD_Mat_Elas_Create_Orthotropic(desc, E11, E22, E33, &` |
| SUBROUTINE | `MD_Mat_Elas_Create_Anisotropic` | 115 | `SUBROUTINE MD_Mat_Elas_Create_Anisotropic(desc, C_props, status)` |
| SUBROUTINE | `MD_Mat_Elas_Parse_ABAQUS_Keyword` | 127 | `SUBROUTINE MD_Mat_Elas_Parse_ABAQUS_Keyword(desc, keyword_params, &` |
| SUBROUTINE | `MD_Mat_Elas_Register` | 165 | `SUBROUTINE MD_Mat_Elas_Register(desc, mat_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
