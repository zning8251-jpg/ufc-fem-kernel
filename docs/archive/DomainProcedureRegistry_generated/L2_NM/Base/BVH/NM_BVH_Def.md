# `NM_BVH_Def.f90`

- **Source**: `L2_NM/Base/BVH/NM_BVH_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_BVH_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_BVH_Def`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_BVH`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base/BVH`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Base/BVH/NM_BVH_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `BVH_Node` (lines 30–44)

```fortran
  TYPE, PUBLIC :: BVH_Node
    ! Bounding box: min_corner(3), max_corner(3)
    REAL(wp) :: bounding_box(2, 3)
    INTEGER(i4) :: left_child = 0      ! Index of left child (0 if leaf)
    INTEGER(i4) :: right_child = 0     ! Index of right child (0 if leaf)
    INTEGER(i4) :: parent = 0         ! Index of parent node
    INTEGER(i4) :: object_index = 0   ! First object index (if leaf)
    INTEGER(i4) :: n_objects = 0      ! Number of objects in leaf
    LOGICAL :: is_leaf = .FALSE.
  CONTAINS
    PROCEDURE :: ComputeVolume => BVH_Node_ComputeVolume
    PROCEDURE :: ComputeSurfaceArea => BVH_Node_ComputeSurfaceArea
    PROCEDURE :: Overlaps => BVH_Node_Overlaps
    PROCEDURE :: ContainsPoint => BVH_Node_ContainsPoint
  END TYPE BVH_Node
```

### `BVH_Tree` (lines 47–67)

```fortran
  TYPE, PUBLIC :: BVH_Tree
    TYPE(BVH_Node), ALLOCATABLE :: nodes(:)
    INTEGER(i4) :: n_nodes = 0
    INTEGER(i4) :: n_objects = 0
    INTEGER(i4) :: split_strategy = BVH_MEDIAN
    INTEGER(i4) :: max_depth = 32
    INTEGER(i4) :: min_leaf_size = 1
    REAL(wp) :: build_cost = 1.0_wp      ! SAH parameter: cost of traversal
    REAL(wp) :: intersection_cost = 1.0_wp  ! SAH parameter: cost of intersection
    LOGICAL :: built = .FALSE.
    
    ! Statistics
    INTEGER(i4) :: n_leaves = 0
    INTEGER(i4) :: max_leaf_size = 0
    REAL(wp) :: avg_leaf_size = 0.0_wp
  CONTAINS
    PROCEDURE :: Initialize => BVH_Tree_Initialize
    PROCEDURE :: Destroy => BVH_Tree_Destroy
    PROCEDURE :: GetBoundingBox => BVH_Tree_GetBoundingBox
    PROCEDURE :: IsBuilt => BVH_Tree_IsBuilt
  END TYPE BVH_Tree
```

### `BVH_QueryResult` (lines 70–74)

```fortran
  TYPE, PUBLIC :: BVH_QueryResult
    INTEGER(i4) :: object_index = 0
    REAL(wp) :: distance = 0.0_wp
    REAL(wp) :: closest_point(3) = 0.0_wp
  END TYPE BVH_QueryResult
```

### `BVH_TraversalStack` (lines 77–87)

```fortran
  TYPE, PUBLIC :: BVH_TraversalStack
    INTEGER(i4), ALLOCATABLE :: node_indices(:)
    INTEGER(i4) :: top = 0
    INTEGER(i4) :: capacity = 0
  CONTAINS
    PROCEDURE :: Initialize => BVH_Stack_Initialize
    PROCEDURE :: Push => BVH_Stack_Push
    PROCEDURE :: Pop => BVH_Stack_Pop
    PROCEDURE :: IsEmpty => BVH_Stack_IsEmpty
    PROCEDURE :: Destroy => BVH_Stack_Destroy
  END TYPE BVH_TraversalStack
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `BVH_Node_ComputeVolume` | 95 | `FUNCTION BVH_Node_ComputeVolume(this) RESULT(volume)` |
| FUNCTION | `BVH_Node_ComputeSurfaceArea` | 105 | `FUNCTION BVH_Node_ComputeSurfaceArea(this) RESULT(sa)` |
| FUNCTION | `BVH_Node_Overlaps` | 115 | `FUNCTION BVH_Node_Overlaps(this, other) RESULT(overlap)` |
| FUNCTION | `BVH_Node_ContainsPoint` | 132 | `FUNCTION BVH_Node_ContainsPoint(this, point) RESULT(contains)` |
| SUBROUTINE | `BVH_Tree_Initialize` | 153 | `SUBROUTINE BVH_Tree_Initialize(this, n_objects, max_depth, min_leaf_size, &` |
| SUBROUTINE | `BVH_Tree_Destroy` | 191 | `SUBROUTINE BVH_Tree_Destroy(this)` |
| SUBROUTINE | `BVH_Tree_GetBoundingBox` | 201 | `SUBROUTINE BVH_Tree_GetBoundingBox(this, bb_min, bb_max, status)` |
| FUNCTION | `BVH_Tree_IsBuilt` | 219 | `FUNCTION BVH_Tree_IsBuilt(this) RESULT(built)` |
| SUBROUTINE | `BVH_Stack_Initialize` | 231 | `SUBROUTINE BVH_Stack_Initialize(this, capacity, status)` |
| SUBROUTINE | `BVH_Stack_Push` | 247 | `SUBROUTINE BVH_Stack_Push(this, node_index, status)` |
| SUBROUTINE | `BVH_Stack_Pop` | 264 | `SUBROUTINE BVH_Stack_Pop(this, node_index, status)` |
| FUNCTION | `BVH_Stack_IsEmpty` | 282 | `FUNCTION BVH_Stack_IsEmpty(this) RESULT(is_empty)` |
| SUBROUTINE | `BVH_Stack_Destroy` | 290 | `SUBROUTINE BVH_Stack_Destroy(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
