# `MD_Mesh_Def.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mesh_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mesh_NodeSetEntry_Desc` (lines 28–33)

```fortran
  TYPE, PUBLIC :: MD_Mesh_NodeSetEntry_Desc
    INTEGER(i4) :: set_id  = 0                               ! [in] set ID
    INTEGER(i4) :: n_nodes = 0                               ! [in] node count
    INTEGER(i4) :: node_ids(MD_MESH_MAX_SET_LEN) = 0         ! [in] node ID array
    LOGICAL     :: valid   = .FALSE.                         ! [in] entry validity
  END TYPE MD_Mesh_NodeSetEntry_Desc
```

### `MD_Mesh_ElemSetEntry_Desc` (lines 41–46)

```fortran
  TYPE, PUBLIC :: MD_Mesh_ElemSetEntry_Desc
    INTEGER(i4) :: set_id  = 0                               ! [in] set ID
    INTEGER(i4) :: n_elems = 0                               ! [in] element count
    INTEGER(i4) :: elem_ids(MD_MESH_MAX_SET_LEN) = 0         ! [in] element ID array
    LOGICAL     :: valid   = .FALSE.                         ! [in] entry validity
  END TYPE MD_Mesh_ElemSetEntry_Desc
```

### `MD_Mesh_FaceDesc` (lines 54–63)

```fortran
  TYPE, PUBLIC :: MD_Mesh_FaceDesc
    INTEGER(i4) :: face_id       = 0                         ! [in] global face ID
    INTEGER(i4) :: elem_id       = 0                         ! [in] parent element ID
    INTEGER(i4) :: local_face_id = 0                         ! [in] local face index
    INTEGER(i4) :: n_face_nodes  = 0                         ! [in] number of face nodes
    INTEGER(i4) :: face_nodes(MD_MESH_MAX_FACE_NODES) = 0    ! [in] face node IDs
    REAL(wp)    :: normal(3)     = 0.0_wp                    ! [out] outward normal
    REAL(wp)    :: area          = 0.0_wp                    ! [out] face area
    LOGICAL     :: is_boundary   = .FALSE.                   ! [out] boundary flag
  END TYPE MD_Mesh_FaceDesc
```

### `MD_Mesh_NodeDesc` (lines 71–74)

```fortran
  TYPE, PUBLIC :: MD_Mesh_NodeDesc
    INTEGER(i4) :: node_id = 0                               ! [in] node ID
    REAL(wp)    :: coords(3) = 0.0_wp                        ! [in] nodal coordinates
  END TYPE MD_Mesh_NodeDesc
```

### `MD_Mesh_ElemDesc` (lines 82–87)

```fortran
  TYPE, PUBLIC :: MD_Mesh_ElemDesc
    INTEGER(i4) :: elem_id   = 0                             ! [in] element ID
    INTEGER(i4) :: elem_type = 0                             ! [in] element type code
    INTEGER(i4) :: n_nodes   = 0                             ! [in] number of nodes
    INTEGER(i4), ALLOCATABLE :: node_conn(:)                 ! [in] connectivity array
  END TYPE MD_Mesh_ElemDesc
```

### `MD_Mesh_Desc` (lines 95–115)

```fortran
  TYPE, PUBLIC :: MD_Mesh_Desc
    INTEGER(i4) :: n_nodes    = 0                            ! [in] total node count
    INTEGER(i4) :: n_elements = 0                            ! [in] total element count
    INTEGER(i4) :: ndim       = 3                            ! [in] spatial dimension
    INTEGER(i4) :: max_nn     = 8                            ! [in] max nodes per element
    REAL(wp), POINTER    :: coords(:,:)   => NULL()          ! [in] (ndim, n_nodes)
    INTEGER(i4), POINTER :: conn(:,:)     => NULL()          ! [in] (max_nn, n_elements)
    INTEGER(i4), POINTER :: elem_type(:)  => NULL()          ! [in] (n_elements)
    ! --- Topology adjacency (populated by MD_Mesh_Topo) ---
    INTEGER(i4), POINTER :: node_to_elem_ptr(:) => NULL()    ! [out] CSR row pointer
    INTEGER(i4), POINTER :: node_to_elem_col(:) => NULL()    ! [out] CSR column indices
    LOGICAL :: topo_built = .FALSE.                          ! [out] adjacency built flag
    ! --- Face table ---
    INTEGER(i4) :: n_faces = 0                               ! [out] face count
    TYPE(MD_Mesh_FaceDesc), ALLOCATABLE :: faces(:)          ! [out] face array
    ! --- Sets ---
    INTEGER(i4) :: n_nodesets = 0                            ! [in] node set count
    INTEGER(i4) :: n_elemsets = 0                            ! [in] element set count
    TYPE(MD_Mesh_NodeSetEntry_Desc) :: nodesets(MD_MESH_MAX_SETS) ! [in] node sets
    TYPE(MD_Mesh_ElemSetEntry_Desc) :: elemsets(MD_MESH_MAX_SETS) ! [in] element sets
  END TYPE MD_Mesh_Desc
```

### `MD_Mesh_State` (lines 123–137)

```fortran
  TYPE, PUBLIC :: MD_Mesh_State
    LOGICAL     :: nodes_loaded     = .FALSE.                ! [inout] nodes loaded
    LOGICAL     :: conn_loaded      = .FALSE.                ! [inout] connectivity loaded
    LOGICAL     :: topo_built       = .FALSE.                ! [inout] topology built
    LOGICAL     :: faces_built      = .FALSE.                ! [inout] face table built
    LOGICAL     :: validated        = .FALSE.                ! [inout] mesh validated
    INTEGER(i4) :: n_orphan_nodes   = 0                      ! [out]   orphan node count
    INTEGER(i4) :: n_degenerate     = 0                      ! [out]   degenerate element count
    INTEGER(i4) :: n_boundary_faces = 0                      ! [out]   boundary face count
    INTEGER(i4) :: modification_gen = 0                      ! [inout] modification generation
    ! Kinematic state tracking (for WriteBack)
    LOGICAL     :: disp_loaded      = .FALSE.                ! [inout] displacement loaded
    LOGICAL     :: vel_loaded       = .FALSE.                ! [inout] velocity loaded
    LOGICAL     :: acc_loaded       = .FALSE.                ! [inout] acceleration loaded
  END TYPE MD_Mesh_State
```

### `MD_Mesh_Get_Node_Arg` (lines 144–156)

```fortran
TYPE, PUBLIC :: MD_Mesh_Get_Node_Arg
  ! [IN] mesh state
  TYPE(MD_Mesh_Desc) :: desc             ! [IN]  mesh descriptor
  TYPE(MD_Mesh_State) :: state           ! [INOUT] mesh state

  ! [IN] query parameters
  INTEGER(i4) :: node_id                 ! [IN]  node ID to query

  ! [OUT] node data
  REAL(wp) :: coords(3)                  ! [OUT] node coordinates
  INTEGER(i4) :: status_code             ! [OUT] query status
  CHARACTER(len=256) :: message          ! [OUT] status message
END TYPE MD_Mesh_Get_Node_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
