# `PH_Cont_SelfContact.f90`

- **Source**: `L4_PH/Contact/Self/PH_Cont_SelfContact.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Cont_SelfContact`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_SelfContact`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_SelfContact`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Self`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Self/PH_Cont_SelfContact.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_ContSC_Surface` (lines 47–56)

```fortran
  TYPE :: PH_ContSC_Surface
    ! Self-contact surface definition
    INTEGER(i4) :: surf_id
    INTEGER(i4) :: n_nodes
    INTEGER(i4) :: n_segments
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4), ALLOCATABLE :: seg_conn(:,:)  ! (nodes_per_seg, n_segs)
    REAL(wp), ALLOCATABLE :: coords(:,:)      ! (3, n_nodes)
    LOGICAL :: is_initialized = .FALSE.
  END TYPE PH_ContSC_Surface
```

### `PH_ContSC_NeighborList` (lines 58–64)

```fortran
  TYPE :: PH_ContSC_NeighborList
    ! Neighbor exclusion list for each node
    INTEGER(i4) :: n_nodes
    INTEGER(i4), ALLOCATABLE :: n_neighbors(:)        ! Count per node
    INTEGER(i4), ALLOCATABLE :: neighbors(:,:)        ! (max_neighbors, n_nodes)
    REAL(wp), ALLOCATABLE :: exclusion_dist(:)        ! Exclusion radius per node
  END TYPE PH_ContSC_NeighborList
```

### `PH_ContSC_SelfPair` (lines 66–75)

```fortran
  TYPE :: PH_ContSC_SelfPair
    ! Self-contact pair
    INTEGER(i4) :: node_i          ! Slave node index
    INTEGER(i4) :: segment_j       ! Master segment index
    REAL(wp) :: gap                ! Signed gap
    REAL(wp) :: normal(3)          ! Contact normal
    REAL(wp) :: force(3)           ! Contact force
    LOGICAL :: is_active           ! Active contact flag
    REAL(wp) :: penalty            ! Penalty stiffness
  END TYPE PH_ContSC_SelfPair
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ContSC_InitSurface` | 83 | `SUBROUTINE PH_ContSC_InitSurface(surf, surf_id, n_nodes, n_segments, &` |
| SUBROUTINE | `PH_ContSC_BuildExclusion` | 133 | `SUBROUTINE PH_ContSC_BuildExclusion(surf, neighbors, status)` |
| SUBROUTINE | `PH_ContSC_DetectSelfContact` | 193 | `SUBROUTINE PH_ContSC_DetectSelfContact(surf, neighbors, bvh_root, &` |
| SUBROUTINE | `PH_ContSC_ComputeSelfForce` | 257 | `SUBROUTINE PH_ContSC_ComputeSelfForce(pairs, n_pairs, coords, F_self, &` |
| FUNCTION | `PH_ContSC_IsExcluded` | 309 | `FUNCTION PH_ContSC_IsExcluded(neighbors, node_i, node_j) RESULT(is_excluded)` |
| SUBROUTINE | `AddNeighbor` | 341 | `SUBROUTINE AddNeighbor(neighbors, node_i, node_j)` |
| FUNCTION | `EstimateElementSize` | 358 | `FUNCTION EstimateElementSize(surf, node_i) RESULT(h_elem)` |
| SUBROUTINE | `ComputeGapAndNormal` | 368 | `SUBROUTINE ComputeGapAndNormal(surf, node_i, seg_j, gap, normal)` |
| SUBROUTINE | `PH_ContSC_Filter` | 420 | `SUBROUTINE PH_ContSC_Filter(surf, neighbors, candidate_pairs, n_candidates, &` |
| FUNCTION | `PH_ContSC_NRingExcluded` | 466 | `FUNCTION PH_ContSC_NRingExcluded(neighbors, surf, node_i, seg_j, n_ring) &` |
| FUNCTION | `PH_ContSC_BackfaceExcluded` | 511 | `FUNCTION PH_ContSC_BackfaceExcluded(surf, node_i, seg_j, angle_threshold) &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
