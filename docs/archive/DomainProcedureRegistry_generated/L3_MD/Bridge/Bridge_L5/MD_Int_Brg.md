# `MD_Int_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L5/MD_Int_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Int_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L5`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L5/MD_Int_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Contact_Brg_BuildStepPairs` | 64 | `SUBROUTINE MD_Contact_Brg_BuildStepPairs(ctx)` |
| SUBROUTINE | `MD_Contact_Brg_ConvertProperty` | 107 | `SUBROUTINE MD_Contact_Brg_ConvertProperty(ctx)` |
| SUBROUTINE | `Brg_AddSurfaceFromPart` | 120 | `SUBROUTINE Brg_AddSurfaceFromPart(part, localSurfId, globalSurfId, &` |
| SUBROUTINE | `Brg_BuildGlobalCoordinates_FromMesh` | 157 | `SUBROUTINE Brg_BuildGlobalCoordinates_FromMesh(X, Y, Z, maxNodeId, ierr)` |
| SUBROUTINE | `Brg_BuildGlobalCoordinates` | 201 | `SUBROUTINE Brg_BuildGlobalCoordinates(model, X, Y, Z, maxNodeId, ierr)` |
| SUBROUTINE | `Brg_BuildGlobalDofMap` | 296 | `SUBROUTINE Brg_BuildGlobalDofMap(dofMap, ierr)` |
| SUBROUTINE | `Brg_CollectSurfaceNodes` | 357 | `SUBROUTINE Brg_CollectSurfaceNodes(part, surfId, nodeIds, nUnique)` |
| SUBROUTINE | `Brg_DecodeGlobalSurfId` | 452 | `SUBROUTINE Brg_DecodeGlobalSurfId(model, globalId, partIndex, localSurfId)` |
| SUBROUTINE | `Brg_Estimate_Eref_FromModel` | 527 | `SUBROUTINE Brg_Estimate_Eref_FromModel(model)` |
| SUBROUTINE | `UF_ContBrg_GetPropForInteract` | 560 | `SUBROUTINE UF_ContBrg_GetPropForInteract(model, propertyId, mu_s, mu_k, penalty_scale)` |
| SUBROUTINE | `Brg_GetPropFromDomain` | 582 | `SUBROUTINE Brg_GetPropFromDomain(prop_name, mu_s, mu_k, penalty_scale)` |
| SUBROUTINE | `Brg_Estimate_Eref_FromDomain` | 608 | `SUBROUTINE Brg_Estimate_Eref_FromDomain()` |
| SUBROUTINE | `UF_ContBrg_IncrInit` | 627 | `subroutine UF_ContBrg_IncrInit(nodeStates, dofMap, ierr)` |
| SUBROUTINE | `UF_ContBrg_InitFromMD` | 757 | `subroutine UF_ContBrg_InitFromMD(model, contact_dim, ierr)` |
| SUBROUTINE | `UF_ContBrg_IterationInit` | 952 | `subroutine UF_ContBrg_IterationInit(nodeStates, dofMap, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
