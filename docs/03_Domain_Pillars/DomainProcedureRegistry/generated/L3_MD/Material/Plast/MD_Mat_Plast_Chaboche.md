# `MD_Mat_Plast_Chaboche.f90`

- **Source**: `L3_MD/Material/Plast/MD_Mat_Plast_Chaboche.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Plast_Chaboche`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_Chaboche`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast_Chaboche`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Plast/MD_Mat_Plast_Chaboche.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Chab_MatDesc_InitFromProps` | 139 | `SUBROUTINE Chab_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `Chab_MatDesc_Valid` | 199 | `FUNCTION Chab_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `Chab_MatState_SyncToStateV` | 224 | `SUBROUTINE Chab_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `Chab_MatState_SyncFromStateV` | 275 | `SUBROUTINE Chab_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `Chab_MatState_InitFromInputs` | 332 | `SUBROUTINE Chab_MatState_InitFromInputs(this, ndir, nshr, n_components)` |
| SUBROUTINE | `Chab_MatCtx_InitFromInputs` | 381 | `SUBROUTINE Chab_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)` |
| SUBROUTINE | `Chab_MatCtx_InitDefaults` | 400 | `SUBROUTINE Chab_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `Chab_MatAlgo_InitDefaults` | 418 | `SUBROUTINE Chab_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `UF_Chaboche_ValidateProps` | 432 | `SUBROUTINE UF_Chaboche_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `ChabProperties_Init_Base` | 498 | `SUBROUTINE ChabProperties_Init_Base(this)` |
| SUBROUTINE | `ChabProperties_Init` | 504 | `SUBROUTINE ChabProperties_Init(this, materialName, status)` |
| FUNCTION | `ChabProperties_Valid_Fn` | 519 | `FUNCTION ChabProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ChabProperties_Clear` | 525 | `SUBROUTINE ChabProperties_Clear(this)` |
| SUBROUTINE | `MD_Mat_Chaboche_Unified_Parse` | 536 | `SUBROUTINE MD_Mat_Chaboche_Unified_Parse(material_type, ast_node, chaboche, material_name, status)` |
| SUBROUTINE | `MD_Mat_Chaboche_Unified_Cfg` | 551 | `SUBROUTINE MD_Mat_Chaboche_Unified_Cfg(operation, status)` |
| SUBROUTINE | `Parse_CHABOCHE_Keyword` | 564 | `SUBROUTINE Parse_CHABOCHE_Keyword(ast_node, chaboche, materialName, status)` |
| SUBROUTINE | `Valid_CHABOCHE_Keyword` | 587 | `SUBROUTINE Valid_CHABOCHE_Keyword(chaboche, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
