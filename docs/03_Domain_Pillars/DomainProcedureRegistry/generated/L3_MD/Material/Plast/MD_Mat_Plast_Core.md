# `MD_Mat_Plast_Core.f90`

- **Source**: `L3_MD/Material/Plast/MD_Mat_Plast_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Plast_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Plast/MD_Mat_Plast_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mat_Plast_Create_From_Props` | 56 | `SUBROUTINE MD_Mat_Plast_Create_From_Props(desc, sub_type, nprops, props, &` |
| SUBROUTINE | `MD_Mat_Plast_Create_J2_Isotropic` | 157 | `SUBROUTINE MD_Mat_Plast_Create_J2_Isotropic(desc, E, nu, sigma_y, H_iso, status)` |
| SUBROUTINE | `MD_Mat_Plast_Create_Hill` | 175 | `SUBROUTINE MD_Mat_Plast_Create_Hill(desc, E, nu, sigma_y, &` |
| SUBROUTINE | `MD_Mat_Plast_Create_Johnson_Cook` | 201 | `SUBROUTINE MD_Mat_Plast_Create_Johnson_Cook(desc, E, nu, A, B, n, C, m, status)` |
| SUBROUTINE | `MD_Mat_Plast_Parse_ABAQUS_Keyword` | 222 | `SUBROUTINE MD_Mat_Plast_Parse_ABAQUS_Keyword(desc, hardening_type, &` |
| SUBROUTINE | `MD_Mat_Plast_Register` | 264 | `SUBROUTINE MD_Mat_Plast_Register(desc, mat_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
