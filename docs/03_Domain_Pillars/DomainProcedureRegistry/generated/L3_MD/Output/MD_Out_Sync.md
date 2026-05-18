# `MD_Out_Sync.f90`

- **Source**: `L3_MD/Output/MD_Out_Sync.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Out_Sync`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_Sync`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out`
- **第四段角色（四段式）**: `_Sync`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_Sync.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Output_SyncFromLegacy` | 39 | `SUBROUTINE MD_Output_SyncFromLegacy(model_def, md_layer, status)` |
| SUBROUTINE | `UF_FieldOutputDef_To_MD_OutputRequest_Desc` | 97 | `SUBROUTINE UF_FieldOutputDef_To_MD_OutputRequest_Desc(uf_fld, step_ref, desc)` |
| SUBROUTINE | `UF_HistoryOutputDef_To_MD_OutputRequest_Desc` | 118 | `SUBROUTINE UF_HistoryOutputDef_To_MD_OutputRequest_Desc(uf_hist, step_ref, desc)` |
| SUBROUTINE | `MD_OutCtrl_PopulateFromDomain` | 146 | `SUBROUTINE MD_OutCtrl_PopulateFromDomain(ctrl, output_domain, step_domain, status)` |
| SUBROUTINE | `MD_OutputRequest_Desc_To_MD_FieldOut_Type` | 192 | `SUBROUTINE MD_OutputRequest_Desc_To_MD_FieldOut_Type(desc, step_ref, fld_out)` |
| SUBROUTINE | `MD_OutputRequest_Desc_To_MD_HistOut_Type` | 216 | `SUBROUTINE MD_OutputRequest_Desc_To_MD_HistOut_Type(desc, step_ref, hist_out)` |
| FUNCTION | `VarIdToName` | 243 | `FUNCTION VarIdToName(var_id) RESULT(name)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
