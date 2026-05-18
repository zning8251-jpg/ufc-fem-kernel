# `MD_Out_FieldExport.f90`

- **Source**: `L3_MD/Output/MD_Out_FieldExport.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Out_FieldExport`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_FieldExport`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out_FieldExport`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_FieldExport.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Out_ExportField` | 58 | `subroutine MD_Out_ExportField(model, var_id, region_type, region_name, &` |
| SUBROUTINE | `MD_Out_GetElemConnectivity` | 406 | `subroutine MD_Out_GetElemConnectivity(model, region_type, region_name, &` |
| SUBROUTINE | `MD_Out_GetNodeCoords` | 518 | `subroutine MD_Out_GetNodeCoords(model, region_type, region_name, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
