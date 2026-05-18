# `MD_Mesh_Domain.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Domain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mesh_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Domain`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MeshAlgo` (lines 115–120)

```fortran
  TYPE, PUBLIC :: MeshAlgo
    INTEGER(i4) :: integration_order = 2_i4  !! Gauss integration order
    INTEGER(i4) :: elem_formulation  = 1_i4  !! 1=full, 2=reduced integration
    LOGICAL     :: nlgeom      = .FALSE.      !! Large displacement flag
    LOGICAL     :: large_strain = .FALSE.     !! Large strain flag (WriteBack enabled)
  END TYPE MeshAlgo
```

### `MD_Mesh_Domain` (lines 129–161)

```fortran
  TYPE, PUBLIC :: MD_Mesh_Domain
    !--- Desc (Write-Once, Read-Many) ---
    TYPE(MeshDesc)                       :: desc         !! Mesh descriptor
    TYPE(MeshNodeDesc),      ALLOCATABLE :: node_desc(:) !! Node descriptors (nNodes)
    TYPE(MeshElemDesc),      ALLOCATABLE :: elem_desc(:) !! Element descriptors (nElems)
    TYPE(MeshGlobalNum)                  :: global_num   !! Global DOF numbering table
    !--- State (Analysis-level; WriteBack target for large-deform) ---
    TYPE(MeshState)                      :: state        !! Mesh state (isActive/nAssembled)
    TYPE(MeshNodeState),     ALLOCATABLE :: node_state(:)!! Per-node state (currentCoords)
    TYPE(MeshElemState),     ALLOCATABLE :: elem_state(:)!! Per-element state (IP cache)
    !--- Algo (Solve-phase read-only) ---
    TYPE(MeshAlgo)                       :: algo         !! Algorithm parameters
    !--- Internal raw storage (encapsulates g_mesh_manager data) ---
    TYPE(MeshData)                       :: raw_data     !! Raw coords + connectivity
    !--- Control ---
    LOGICAL                              :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: GetNodeCoords
    PROCEDURE :: GetElemConnect
    PROCEDURE :: GetElemSection
    PROCEDURE :: GetDofMap
    PROCEDURE :: GetSurfaceByName
    PROCEDURE :: GetNodeByName
    PROCEDURE :: GetSummary
    PROCEDURE :: WriteBack_NodePos => MD_Mesh_WriteBack_NodePos
    PROCEDURE :: WriteBack_NodeDisp => MD_Mesh_WriteBack_NodeDisp
    PROCEDURE :: WriteBack_NodeVel => MD_Mesh_WriteBack_NodeVel
    PROCEDURE :: WriteBack_NodeAcc => MD_Mesh_WriteBack_NodeAcc
    PROCEDURE :: WriteBack_ElemStress => MD_Mesh_WriteBack_ElemStress
    PROCEDURE :: WriteBack_State   => MD_Mesh_WriteBack_State
  END TYPE MD_Mesh_Domain
```

### `MD_Mesh_GetNodeCoords_Arg` (lines 168–170)

```fortran
  TYPE, PUBLIC :: MD_Mesh_GetNodeCoords_Arg
    REAL(wp) :: coords(3) = 0.0_wp
  END TYPE MD_Mesh_GetNodeCoords_Arg
```

### `MD_Mesh_GetElemConnect_Arg` (lines 176–179)

```fortran
  TYPE, PUBLIC :: MD_Mesh_GetElemConnect_Arg
    INTEGER(i8) :: connect(MD_MESH_MAX_NODES_PER_ELEM) = 0_i8  ! Valid entries: 1:npe
    INTEGER(i4) :: npe = 0_i4
  END TYPE MD_Mesh_GetElemConnect_Arg
```

### `MD_Mesh_GetDofMap_Arg` (lines 185–188)

```fortran
  TYPE, PUBLIC :: MD_Mesh_GetDofMap_Arg
    INTEGER(i4) :: global_dof_start = 0_i4
    INTEGER(i4) :: n_dof = 0_i4
  END TYPE MD_Mesh_GetDofMap_Arg
```

### `MD_Mesh_GetElemSection_Arg` (lines 194–196)

```fortran
  TYPE, PUBLIC :: MD_Mesh_GetElemSection_Arg
    INTEGER(i4) :: section_idx = 0_i4  ! 0 = not assigned
  END TYPE MD_Mesh_GetElemSection_Arg
```

### `MD_Mesh_GetSummary_Arg` (lines 198–201)

```fortran
  TYPE, PUBLIC :: MD_Mesh_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mesh_GetSummary_Arg
```

### `MD_Mesh_WriteBack_NodePos_Arg` (lines 204–206)

```fortran
  TYPE, PUBLIC :: MD_Mesh_WriteBack_NodePos_Arg
    REAL(wp) :: new_coords(3) = 0.0_wp
  END TYPE MD_Mesh_WriteBack_NodePos_Arg
```

### `MD_Mesh_GetSurfaceByName_Arg` (lines 209–212)

```fortran
  TYPE, PUBLIC :: MD_Mesh_GetSurfaceByName_Arg
    LOGICAL :: found = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mesh_GetSurfaceByName_Arg
```

### `MD_Mesh_GetNodeByName_Arg` (lines 215–219)

```fortran
  TYPE, PUBLIC :: MD_Mesh_GetNodeByName_Arg
    INTEGER(i4) :: node_idx = 0_i4
    LOGICAL :: found = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mesh_GetNodeByName_Arg
```

### `MD_Mesh_WriteBack_ElemStress_Arg` (lines 222–225)

```fortran
  TYPE, PUBLIC :: MD_Mesh_WriteBack_ElemStress_Arg
    INTEGER(i4) :: ip_idx = 0_i4
    REAL(wp) :: sigma(6) = 0.0_wp
  END TYPE MD_Mesh_WriteBack_ElemStress_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 243 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `GetDofMap` | 260 | `SUBROUTINE GetDofMap(this, local_node_id, global_dof_start, nDof, status)` |
| SUBROUTINE | `GetElemConnect` | 281 | `SUBROUTINE GetElemConnect(this, elem_id, connect, npe, status)` |
| SUBROUTINE | `GetElemSection` | 310 | `SUBROUTINE GetElemSection(this, elem_id, section_ref, status)` |
| SUBROUTINE | `MD_Mesh_GetElemSection_Idx` | 337 | `SUBROUTINE MD_Mesh_GetElemSection_Idx(elem_idx, arg, status)` |
| SUBROUTINE | `GetNodeCoords` | 366 | `SUBROUTINE GetNodeCoords(this, local_id, coords, status)` |
| SUBROUTINE | `MD_Mesh_GetNodeCoords_Idx` | 386 | `SUBROUTINE MD_Mesh_GetNodeCoords_Idx(node_idx, arg, status)` |
| SUBROUTINE | `MD_Mesh_GetElemConnect_Idx` | 413 | `SUBROUTINE MD_Mesh_GetElemConnect_Idx(elem_idx, arg, status)` |
| SUBROUTINE | `MD_Mesh_GetDofMap_Idx` | 449 | `SUBROUTINE MD_Mesh_GetDofMap_Idx(node_idx, arg, status)` |
| SUBROUTINE | `MD_Mesh_WriteBack_NodePos_Idx` | 485 | `SUBROUTINE MD_Mesh_WriteBack_NodePos_Idx(node_idx, arg, status)` |
| SUBROUTINE | `Init` | 511 | `SUBROUTINE Init(this, nNodes, nElems, spatial_dim, status, max_nodes_per_elem)` |
| SUBROUTINE | `MD_Mesh_WriteBack_NodePos` | 543 | `SUBROUTINE MD_Mesh_WriteBack_NodePos(this, node_id, new_coords, status)` |
| SUBROUTINE | `MD_Mesh_WriteBack_NodeDisp` | 563 | `SUBROUTINE MD_Mesh_WriteBack_NodeDisp(this, node_id, new_disp, status)` |
| SUBROUTINE | `MD_Mesh_WriteBack_NodeVel` | 581 | `SUBROUTINE MD_Mesh_WriteBack_NodeVel(this, node_id, new_vel, status)` |
| SUBROUTINE | `MD_Mesh_WriteBack_NodeAcc` | 599 | `SUBROUTINE MD_Mesh_WriteBack_NodeAcc(this, node_id, new_acc, status)` |
| SUBROUTINE | `MD_Mesh_WriteBack_ElemStress_Idx` | 617 | `SUBROUTINE MD_Mesh_WriteBack_ElemStress_Idx(elem_idx, arg, status)` |
| SUBROUTINE | `MD_Mesh_WriteBack_ElemStress` | 658 | `SUBROUTINE MD_Mesh_WriteBack_ElemStress(this, elem_id, ip_id, sigma, status)` |
| SUBROUTINE | `MD_Mesh_WriteBack_State` | 689 | `SUBROUTINE MD_Mesh_WriteBack_State(this, n_assembled, status)` |
| SUBROUTINE | `GetSurfaceByName` | 708 | `SUBROUTINE GetSurfaceByName(this, surface_name, found, status)` |
| SUBROUTINE | `MD_Mesh_GetSurfaceByName_Idx` | 760 | `SUBROUTINE MD_Mesh_GetSurfaceByName_Idx(surface_name, arg, status)` |
| SUBROUTINE | `GetNodeByName` | 809 | `SUBROUTINE GetNodeByName(this, name, node_idx, found, status)` |
| SUBROUTINE | `MD_Mesh_GetNodeByName_Idx` | 849 | `SUBROUTINE MD_Mesh_GetNodeByName_Idx(name, arg, status)` |
| SUBROUTINE | `GetSummary` | 881 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `MD_Mesh_GetSummary_Impl` | 887 | `SUBROUTINE MD_Mesh_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
