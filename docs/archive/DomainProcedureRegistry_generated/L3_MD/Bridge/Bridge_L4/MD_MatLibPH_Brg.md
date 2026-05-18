# `MD_MatLibPH_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L4/MD_MatLibPH_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_MatLibPH_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_MatLibPH_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_MatLibPH`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L4`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L4/MD_MatLibPH_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `MD_PH_GetMaterialType` | 149 | `FUNCTION MD_PH_GetMaterialType(mat_def) RESULT(mat_type)` |
| FUNCTION | `MD_PH_GetMaterialType_FromDesc` | 174 | `FUNCTION MD_PH_GetMaterialType_FromDesc(desc) RESULT(mat_type)` |
| SUBROUTINE | `MD_PH_RouteToConstitutive` | 204 | `SUBROUTINE MD_PH_RouteToConstitutive(mat_def, mat_ctx, status)` |
| SUBROUTINE | `MD_PH_RouteToConstitutive_Idx` | 319 | `SUBROUTINE MD_PH_RouteToConstitutive_Idx(mat_idx, mat_ctx, status)` |
| SUBROUTINE | `MD_PH_TransferModelDef` | 380 | `SUBROUTINE MD_PH_TransferModelDef(ph_model_ctx, md_model_ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
