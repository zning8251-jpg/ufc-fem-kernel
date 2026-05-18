# `MD_Model_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L5/MD_Model_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Model_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Model_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Model`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L5`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L5/MD_Model_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_BindModelRuntime_ToDataPlatform` | 103 | `SUBROUTINE UF_BindModelRuntime_ToDataPlatform(modelDef, mv_ctx, ierr)` |
| SUBROUTINE | `UF_BuildContMesh_FromUFModel` | 146 | `SUBROUTINE UF_BuildContMesh_FromUFModel(modelDef, mdlCtx, contMesh, matId)` |
| SUBROUTINE | `UF_BuildStepBC_ForNewCore` | 211 | `SUBROUTINE UF_BuildStepBC_ForNewCore(modelDef, step_index, stepLoad)` |
| SUBROUTINE | `UF_BuildStepLoad_ForNewCore` | 404 | `SUBROUTINE UF_BuildStepLoad_ForNewCore(modelDef, step_index, stepLoad)` |
| SUBROUTINE | `UF_ProjectSectionsToModelCtx` | 503 | `SUBROUTINE UF_ProjectSectionsToModelCtx(modelDef, mdlCtx)` |
| SUBROUTINE | `UF_register_model_in_dataplatform` | 550 | `SUBROUTINE UF_register_model_in_dataplatform(model, ierr)` |
| SUBROUTINE | `UF_UpdateStepLoadAmplitudes_ForNewCore` | 779 | `SUBROUTINE UF_UpdateStepLoadAmplitudes_ForNewCore(modelDef, time, stepLoad)` |
| SUBROUTINE | `register_materials` | 796 | `SUBROUTINE register_materials(model, ierr)` |
| SUBROUTINE | `register_sections` | 829 | `SUBROUTINE register_sections(model, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
