# `MD_LBC_Query.f90`

- **Source**: `L3_MD/Boundary/MD_LBC_Query.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_LBC_Query`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBC_Query`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBC_Query`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_LBC_Query.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Ldbc_FlatMap_NodeSet` | 32 | `SUBROUTINE Ldbc_FlatMap_NodeSet(model, flatId, iPart, jSet, ok)` |
| SUBROUTINE | `Ldbc_FlatMap_ElemSet` | 66 | `SUBROUTINE Ldbc_FlatMap_ElemSet(model, flatId, iPart, jSet, ok)` |
| SUBROUTINE | `Ldbc_FlatMap_SurfSet` | 100 | `SUBROUTINE Ldbc_FlatMap_SurfSet(model, flatId, iPart, jSet, ok)` |
| SUBROUTINE | `Ldbc_FindElementIndexById` | 134 | `SUBROUTINE Ldbc_FindElementIndexById(model, elemId, iPart, iElem, found)` |
| SUBROUTINE | `Ldbc_GetSurfaceElemFaceArrays` | 157 | `SUBROUTINE Ldbc_GetSurfaceElemFaceArrays(model, flatSurfId, elems, faces)` |
| SUBROUTINE | `Ldbc_GetNodeSetNodes` | 213 | `SUBROUTINE Ldbc_GetNodeSetNodes(model, nodeSetId, nodeList)` |
| SUBROUTINE | `Ldbc_GetElemSetElements` | 245 | `SUBROUTINE Ldbc_GetElemSetElements(model, elemSet, elemList)` |
| SUBROUTINE | `Ldbc_GetElementNodes` | 273 | `SUBROUTINE Ldbc_GetElementNodes(model, elemId, elemNodes)` |
| SUBROUTINE | `Ldbc_GetFaceNodes` | 292 | `SUBROUTINE Ldbc_GetFaceNodes(model, elemId, faceId, faceNodes, ownerPart)` |
| SUBROUTINE | `Ldbc_NodeCoordsForMeshIndex` | 333 | `SUBROUTINE Ldbc_NodeCoordsForMeshIndex(model, iPart, meshIdx, coords, ok)` |
| FUNCTION | `Ldbc_FindNodeSetId` | 347 | `FUNCTION Ldbc_FindNodeSetId(model, regionName) RESULT(setId)` |
| FUNCTION | `Ldbc_FindSurfaceSetId` | 389 | `FUNCTION Ldbc_FindSurfaceSetId(model, surfaceName) RESULT(setId)` |
| FUNCTION | `Ldbc_FindElementSetId` | 423 | `FUNCTION Ldbc_FindElementSetId(model, elemSetName) RESULT(setId)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
