# `MD_Mat_Plast_JohnsonCook.f90`

- **Source**: `L3_MD/Material/Plast/MD_Mat_Plast_JohnsonCook.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Plast_JohnsonCook`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_JohnsonCook`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast_JohnsonCook`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Plast/MD_Mat_Plast_JohnsonCook.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_MAT_JC_MatDesc_InitFromProps` | 132 | `SUBROUTINE MD_MAT_JC_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `MD_MAT_JC_MatDesc_Valid` | 193 | `FUNCTION MD_MAT_JC_MatDesc_Valid(this) RESULT(is_valid)` |
| SUBROUTINE | `MD_MAT_JC_MatState_SyncToStateV` | 218 | `SUBROUTINE MD_MAT_JC_MatState_SyncToStateV(this, statev, nstatev)` |
| SUBROUTINE | `MD_MAT_JC_MatState_SyncFromStateV` | 251 | `SUBROUTINE MD_MAT_JC_MatState_SyncFromStateV(this, statev, nstatev)` |
| SUBROUTINE | `MD_MAT_JC_MatState_InitFromInputs` | 291 | `SUBROUTINE MD_MAT_JC_MatState_InitFromInputs(this, ndir, nshr)` |
| SUBROUTINE | `MD_MAT_JC_MatCtx_InitFromInputs` | 326 | `SUBROUTINE MD_MAT_JC_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtemp, dtime, kstep, kinc)` |
| SUBROUTINE | `MD_MAT_JC_MatCtx_InitDefaults` | 346 | `SUBROUTINE MD_MAT_JC_MatCtx_InitDefaults(this)` |
| SUBROUTINE | `MD_MAT_JC_MatAlgo_InitDefaults` | 365 | `SUBROUTINE MD_MAT_JC_MatAlgo_InitDefaults(this)` |
| SUBROUTINE | `UF_JohnsonCook_ValidateProps` | 380 | `SUBROUTINE UF_JohnsonCook_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `JCProperties_Init_Base` | 468 | `SUBROUTINE JCProperties_Init_Base(this)` |
| SUBROUTINE | `JCProperties_Init` | 474 | `SUBROUTINE JCProperties_Init(this, materialName, status)` |
| FUNCTION | `JCProperties_Valid_Fn` | 488 | `FUNCTION JCProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `JCProperties_Clear` | 494 | `SUBROUTINE JCProperties_Clear(this)` |
| SUBROUTINE | `MD_Mat_JohnsonCook_Unified_Configure` | 504 | `SUBROUTINE MD_Mat_JohnsonCook_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Mat_JohnsonCook_Unified_Parse` | 517 | `SUBROUTINE MD_Mat_JohnsonCook_Unified_Parse(material_type, ast_node, johnsonCook, material_name, status)` |
| SUBROUTINE | `Parse_JOHNSON_COOK_Keyword` | 532 | `SUBROUTINE Parse_JOHNSON_COOK_Keyword(ast_node, johnsonCook, materialName, status)` |
| SUBROUTINE | `Valid_JOHNSON_COOK_Keyword` | 554 | `SUBROUTINE Valid_JOHNSON_COOK_Keyword(johnsonCook, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
