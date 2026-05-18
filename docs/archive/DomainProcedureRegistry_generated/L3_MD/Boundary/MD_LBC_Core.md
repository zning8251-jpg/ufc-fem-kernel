# `MD_LBC_Core.f90`

- **Source**: `L3_MD/Boundary/MD_LBC_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_LBC_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBC_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBC`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_LBC_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `md_lbc_amp_from_uf` | 45 | `FUNCTION md_lbc_amp_from_uf(model_amps, amp_id, time, md_layer) RESULT(fac)` |
| SUBROUTINE | `MD_LoadBC_SyncFromLegacy` | 125 | `SUBROUTINE MD_LoadBC_SyncFromLegacy(model_def, md_layer, status)` |
| SUBROUTINE | `UF_BCDef_To_MD_BC_Desc` | 199 | `SUBROUTINE UF_BCDef_To_MD_BC_Desc(uf_bc, step_ref, desc, md_layer)` |
| SUBROUTINE | `UF_CLoadDef_To_MD_Load_Desc` | 217 | `SUBROUTINE UF_CLoadDef_To_MD_Load_Desc(uf_cload, step_ref, desc, md_layer)` |
| SUBROUTINE | `UF_DLoadDef_To_MD_Load_Desc` | 234 | `SUBROUTINE UF_DLoadDef_To_MD_Load_Desc(uf_dload, step_ref, desc, md_layer)` |
| SUBROUTINE | `UF_BodyForceDef_To_MD_Load_Desc` | 251 | `SUBROUTINE UF_BodyForceDef_To_MD_Load_Desc(uf_bforce, step_ref, desc, md_layer)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
