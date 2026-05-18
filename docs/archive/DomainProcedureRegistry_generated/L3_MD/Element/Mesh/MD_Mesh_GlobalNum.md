# `MD_Mesh_GlobalNum.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_GlobalNum.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mesh_GlobalNum`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_GlobalNum`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh_GlobalNum`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_GlobalNum.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NodeGlobalMapEntry` (lines 40–47)

```fortran
  type, public :: NodeGlobalMapEntry
    integer(i4)                          :: globalNodeId        = 0_i4
    integer(i4)                          :: partIndex           = 0_i4
    integer(i4)                          :: instanceIndex       = 0_i4
    integer(i4)                          :: localNodeId         = 0_i4
    integer(i4)                          :: dofStartIndex       = 0_i4
    integer(i4)                          :: nDof                = 0_i4
  end type NodeGlobalMapEntry
```

### `ElemGlobalMapEntry` (lines 49–55)

```fortran
  type, public :: ElemGlobalMapEntry
    integer(i4)                          :: globalElemId        = 0_i4
    integer(i4)                          :: partIndex           = 0_i4
    integer(i4)                          :: instanceIndex       = 0_i4
    integer(i4)                          :: localElemId         = 0_i4
    integer(i4),           allocatable   :: connGlobalNodes(:)
  end type ElemGlobalMapEntry
```

### `MeshGlobalNum` (lines 57–66)

```fortran
  type, public :: MeshGlobalNum
    integer(i4)                          :: nGlobalNodes        = 0_i4
    integer(i4)                          :: nGlobalElems        = 0_i4
    integer(i4)                          :: nTotalEq            = 0_i4
    type(NodeGlobalMapEntry), allocatable :: nodeMap(:)
    type(ElemGlobalMapEntry), allocatable :: elemMap(:)
    integer(i4),           allocatable   :: instancenodeoff(:)
    integer(i4),           allocatable   :: INSTANCELEMOFFS(:)
    type(MD_DOFMap)                       :: dof_sys
  end type MeshGlobalNum
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `GlobalNum_BuildFromFlat` | 79 | `subroutine GlobalNum_BuildFromFlat(nNodes, nElems, conn, numbering, nDofPerNode, status)` |
| SUBROUTINE | `GlobalNum_Build` | 182 | `subroutine GlobalNum_Build(model, numbering, ierr)` |
| SUBROUTINE | `GlobalNum_GetDofIndices` | 338 | `subroutine GlobalNum_GetDofIndices(numbering, elemIndex, dofIndices, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
