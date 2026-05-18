# `MD_Mesh_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L5/MD_Mesh_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mesh_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L5`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L5/MD_Mesh_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Mesh_IDMap` (lines 48–57)

```fortran
  TYPE, PUBLIC :: RT_Mesh_IDMap
    INTEGER(i4) :: modelId = 0_i4
    INTEGER(i4) :: runtimeId = 0_i4
    LOGICAL :: valid = .FALSE.
    CHARACTER(len=32) :: name = ""
  CONTAINS
    PROCEDURE :: Init => RT_Mesh_IDMapInit
    PROCEDURE :: Set => RT_Mesh_IDMapSet
    PROCEDURE :: Valid => RT_Mesh_IDMapValid
  END TYPE RT_Mesh_IDMap
```

### `MD_Mesh_Brg_Counts` (lines 64–69)

```fortran
  TYPE, PUBLIC :: MD_Mesh_Brg_Counts
    INTEGER(i4) :: nElems = 0_i4
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4) :: nMats = 0_i4
    INTEGER(i4) :: nSects = 0_i4
  END TYPE MD_Mesh_Brg_Counts
```

### `MD_Mesh_Brg_IDMaps` (lines 71–76)

```fortran
  TYPE, PUBLIC :: MD_Mesh_Brg_IDMaps
    INTEGER(i4), ALLOCATABLE :: elemIdMap(:)
    INTEGER(i4), ALLOCATABLE :: matIdMap(:)
    INTEGER(i4), ALLOCATABLE :: sectIdMap(:)
    INTEGER(i4), ALLOCATABLE :: nodeIdMap(:)
  END TYPE MD_Mesh_Brg_IDMaps
```

### `MD_Mesh_Brg_Mappings` (lines 78–83)

```fortran
  TYPE, PUBLIC :: MD_Mesh_Brg_Mappings
    TYPE(RT_Mesh_IDMap), ALLOCATABLE :: elemMappings(:)
    TYPE(RT_Mesh_IDMap), ALLOCATABLE :: matMapping(:)
    TYPE(RT_Mesh_IDMap), ALLOCATABLE :: sectMappings(:)
    TYPE(RT_Mesh_IDMap), ALLOCATABLE :: nodeMappings(:)
  END TYPE MD_Mesh_Brg_Mappings
```

### `MD_Mesh_Brg` (lines 85–99)

```fortran
  TYPE, PUBLIC :: MD_Mesh_Brg
    TYPE(MD_Mesh_Brg_Counts) :: counts
    LOGICAL :: inited = .FALSE.
    TYPE(MD_Mesh_Brg_IDMaps) :: idmaps
    TYPE(MD_Mesh_Brg_Mappings) :: mappings
  CONTAINS
    PROCEDURE :: Clean => MD_Mesh_BrgCleanType
    PROCEDURE :: GetElemCnt => MD_Mesh_BrgGetElemCntType
    PROCEDURE :: GetNodeCnt => MD_Mesh_BrgGetNodeCntType
    PROCEDURE :: Init => MD_Mesh_BrgInitType
    PROCEDURE :: MapElem => MD_Mesh_BrgMapElemType
    PROCEDURE :: MapMat => MD_Mesh_BrgMapMatType
    PROCEDURE :: MapNode => MD_Mesh_BrgMapNodeType
    PROCEDURE :: MapSect => MD_Mesh_BrgMapSectType
  END TYPE MD_Mesh_Brg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mesh_BrgClean` | 105 | `SUBROUTINE MD_Mesh_BrgClean()` |
| SUBROUTINE | `MD_Mesh_BrgCleanType` | 109 | `SUBROUTINE MD_Mesh_BrgCleanType(this)` |
| FUNCTION | `MD_Mesh_BrgGetElemCnt` | 130 | `function MD_Mesh_BrgGetElemCnt() result(count)` |
| FUNCTION | `MD_Mesh_BrgGetElemCntType` | 135 | `function MD_Mesh_BrgGetElemCntType(this) result(count)` |
| FUNCTION | `MD_Mesh_BrgGetNodeCnt` | 141 | `function MD_Mesh_BrgGetNodeCnt() result(count)` |
| FUNCTION | `MD_Mesh_BrgGetNodeCntType` | 146 | `function MD_Mesh_BrgGetNodeCntType(this) result(count)` |
| SUBROUTINE | `MD_Mesh_BrgInit` | 152 | `subroutine MD_Mesh_BrgInit(nElems, nNodes, nMats, nSects, status)` |
| SUBROUTINE | `MD_Mesh_BrgInitElems` | 191 | `subroutine MD_Mesh_BrgInitElems(nElems, status)` |
| SUBROUTINE | `MD_Mesh_BrgInitMats` | 212 | `subroutine MD_Mesh_BrgInitMats(nMats, status)` |
| SUBROUTINE | `MD_Mesh_BrgInitSects` | 233 | `subroutine MD_Mesh_BrgInitSects(nSects, status)` |
| SUBROUTINE | `MD_Mesh_BrgInitType` | 254 | `subroutine MD_Mesh_BrgInitType(this, nElems, nNodes, nMats, nSects, status)` |
| SUBROUTINE | `MD_Mesh_BrgMapElemId` | 293 | `subroutine MD_Mesh_BrgMapElemId(modelId, runtimeId, status)` |
| SUBROUTINE | `MD_Mesh_BrgMapElemType` | 311 | `subroutine MD_Mesh_BrgMapElemType(this, modelId, runtimeId)` |
| SUBROUTINE | `MD_Mesh_BrgMapMatId` | 323 | `subroutine MD_Mesh_BrgMapMatId(modelId, runtimeId, status)` |
| SUBROUTINE | `MD_Mesh_BrgMapMatType` | 341 | `subroutine MD_Mesh_BrgMapMatType(this, modelId, runtimeId)` |
| SUBROUTINE | `MD_Mesh_BrgMapNodeId` | 353 | `subroutine MD_Mesh_BrgMapNodeId(modelId, runtimeId, status)` |
| SUBROUTINE | `MD_Mesh_BrgMapNodeType` | 371 | `subroutine MD_Mesh_BrgMapNodeType(this, modelId, runtimeId)` |
| SUBROUTINE | `MD_Mesh_BrgMapSectId` | 383 | `subroutine MD_Mesh_BrgMapSectId(modelId, runtimeId, status)` |
| SUBROUTINE | `MD_Mesh_BrgMapSectType` | 401 | `subroutine MD_Mesh_BrgMapSectType(this, modelId, runtimeId)` |
| SUBROUTINE | `RT_Mesh_IDMapInit` | 413 | `subroutine RT_Mesh_IDMapInit(this, modelId, name)` |
| SUBROUTINE | `RT_Mesh_IDMapSet` | 424 | `subroutine RT_Mesh_IDMapSet(this, runtimeId)` |
| FUNCTION | `RT_Mesh_IDMapValid` | 432 | `function RT_Mesh_IDMapValid(this) result(valid)` |
| SUBROUTINE | `MD_Mesh_Brg_GetNodeCoords_Idx` | 444 | `subroutine MD_Mesh_Brg_GetNodeCoords_Idx(node_idx, arg, status)` |
| SUBROUTINE | `MD_Mesh_Brg_GetElemConnect_Idx` | 456 | `subroutine MD_Mesh_Brg_GetElemConnect_Idx(elem_idx, arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
