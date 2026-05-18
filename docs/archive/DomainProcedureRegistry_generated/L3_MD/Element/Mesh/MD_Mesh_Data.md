# `MD_Mesh_Data.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Data.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mesh_Data`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Data`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh_Data`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Data.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MeshData` (lines 49–71)

```fortran
  type, public :: MeshData
    integer(i8)                          :: nNodes        = 0_i8
    integer(i8)                          :: nElems        = 0_i8
    integer(i4)                          :: spatial_dim   = 3_i4
    real(wp),              allocatable   :: node_coords(:,:)
    integer(i8),           allocatable   :: element_connect(:,:)
    ! Per-element UFC code MD_MESH_ELEM_* (MD_Elem_Algo); consumed by PH_L4_Populate_Element -> elem_type_cache
    integer(i4),           allocatable   :: element_types(:)
    ! 1-based index into L3 section_db / section%desc_array; filled by Mesh_Sync_PopulateElemSectionRef
    integer(i4),           allocatable   :: elem_section_ref(:)
    integer(i8),           allocatable   :: node_sets(:,:)
    integer(i8),           allocatable   :: element_sets(:,:)
    LOGICAL :: initialized = .false.
  contains
    procedure :: Init
    procedure :: Clean
    procedure :: GetNodeCoords
    procedure :: SetNodeCoords
    procedure :: GetElementConnectivity
    procedure :: SetElementConnectivity
    procedure :: GetElementNodes
    procedure :: Valid
  end type MeshData
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init` | 122 | `subroutine Init(this, nNodes, nElems, spatial_dim, status, max_nodes_per_elem)` |
| SUBROUTINE | `Clean` | 159 | `subroutine Clean(this)` |
| SUBROUTINE | `GetNodeCoords` | 175 | `subroutine GetNodeCoords(this, node_id, coords, status)` |
| SUBROUTINE | `SetNodeCoords` | 193 | `subroutine SetNodeCoords(this, node_id, coords, status)` |
| SUBROUTINE | `GetElementConnectivity` | 211 | `subroutine GetElementConnectivity(this, element_id, conn, status)` |
| SUBROUTINE | `SetElementConnectivity` | 236 | `subroutine SetElementConnectivity(this, element_id, conn, status)` |
| SUBROUTINE | `GetElementNodes` | 258 | `subroutine GetElementNodes(this, element_id, node_coords, status)` |
| SUBROUTINE | `Valid` | 294 | `subroutine Valid(this, status)` |
| SUBROUTINE | `MeshDesc_Init` | 330 | `SUBROUTINE MeshDesc_Init(this)` |
| SUBROUTINE | `MeshDesc_RegLayout` | 336 | `SUBROUTINE MeshDesc_RegLayout(this)` |
| SUBROUTINE | `MeshDesc_Ensure` | 372 | `SUBROUTINE MeshDesc_Ensure(this)` |
| SUBROUTINE | `MeshState_Init` | 388 | `SUBROUTINE MeshState_Init(this, n)` |
| SUBROUTINE | `MeshState_RegLayout` | 395 | `SUBROUTINE MeshState_RegLayout(this)` |
| SUBROUTINE | `MeshState_Ensure` | 409 | `SUBROUTINE MeshState_Ensure(this)` |
| SUBROUTINE | `MeshCtx_Init` | 421 | `SUBROUTINE MeshCtx_Init(this)` |
| SUBROUTINE | `MeshCtx_RegLayout` | 427 | `SUBROUTINE MeshCtx_RegLayout(this)` |
| SUBROUTINE | `MeshCtx_Ensure` | 442 | `SUBROUTINE MeshCtx_Ensure(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
