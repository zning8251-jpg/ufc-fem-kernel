# `PH_ContSearch_Adv.f90`

- **Source**: `L4_PH/Contact/Search/PH_ContSearch_Adv.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_ContSearch_Adv`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_ContSearch_Adv`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_ContSearch_Adv`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Search`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Search/PH_ContSearch_Adv.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Cont_SearchStrategy` (lines 49–54)

```fortran
  type :: RT_Cont_SearchStrategy
    logical :: use_global_sear = .true.
    logical :: use_candidate_c = .false.
    real(wp) :: cache_valid_rad = 0.0_wp
    integer(i4) :: max_cached_pair = 0
  end type RT_Cont_SearchStrategy
```

### `RT_Cont_SpatHashGrid` (lines 59–68)

```fortran
  type :: RT_Cont_SpatHashGrid
    integer(i4) :: nx, ny, nz              ! Grid dimensions
    real(wp) :: cell_size(3)                ! Cell size in each direction
    real(wp) :: bbox_min(3), bbox_max(3)   ! Bounding box
    integer(i4), allocatable :: cell_indices(:,:,:)  ! Cell index array
    integer(i4), allocatable :: cell_lists(:)        ! Flat list of node indices
    integer(i4), allocatable :: cell_starts(:)       ! Start index for each cell
    integer(i4), allocatable :: cell_counts(:)       ! Count per cell
    integer(i4) :: max_nodes_per_c               ! Maximum nodes per cell
  end type RT_Cont_SpatHashGrid
```

### `RT_Cont_OctreeNode` (lines 70–77)

```fortran
  type :: RT_Cont_OctreeNode
    real(wp) :: center(3)                   ! Node center
    real(wp) :: half_size(3)                ! Half size of bounding box
    integer(i4) :: node_count               ! Number of nodes in this node
    integer(i4), allocatable :: node_indices(:)  ! Indices of nodes
    type(RT_Cont_OctreeNode), pointer :: children(2,2,2) => null()  ! 8 children
    logical :: is_leaf                      ! Leaf node flag
  end type RT_Cont_OctreeNode
```

### `RT_Cont_BVHNode` (lines 79–85)

```fortran
  type :: RT_Cont_BVHNode
    real(wp) :: bbox_min(3), bbox_max(3)   ! Bounding box
    integer(i4) :: left_child              ! Left child index (-1 if leaf)
    integer(i4) :: right_child             ! Right child index (-1 if leaf)
    integer(i4) :: node_count              ! Number of nodes in this node
    integer(i4), allocatable :: node_indices(:)  ! Indices of nodes (if leaf)
  end type RT_Cont_BVHNode
```

### `RT_Cont_BVHTree` (lines 87–91)

```fortran
  type :: RT_Cont_BVHTree
    type(RT_Cont_BVHNode), allocatable :: nodes(:)
    integer(i4) :: root_index
    integer(i4) :: node_count
  end type RT_Cont_BVHTree
```

### `RT_Cont_Search_Core_Args` (lines 96–123)

```fortran
  TYPE :: RT_Cont_Search_Core_Args
  ! Purpose: ����
  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Cont_Search_Core_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `barycentric_triangle` | 128 | `subroutine barycentric_triangle(a, b, c, p, xi, eta, status)` |
| SUBROUTINE | `BuildOctreeRecursive` | 153 | `recursive subroutine BuildOctreeRecursive(node, coords, max_nodes_per_l, status)` |
| SUBROUTINE | `BVHBuildRecursive` | 234 | `recursive subroutine BVHBuildRecursive(bvh_tree, coords, indices, start, end_idx, bmin, bmax, max_leaf, status)` |
| SUBROUTINE | `BVHSearchRecursive` | 296 | `recursive subroutine BVHSearchRecursive(bvh_tree, node_idx, coords, &` |
| SUBROUTINE | `OctreeSearchRecursive` | 356 | `recursive subroutine OctreeSearchRecursive(node, coords, search_radius_s, &` |
| SUBROUTINE | `swap_int` | 419 | `subroutine swap_int(a, b)` |
| SUBROUTINE | `RT_Cont_InitSpatHashFromSea` | 427 | `subroutine RT_Cont_InitSpatHashFromSea(coords, search_radius, &` |
| SUBROUTINE | `RT_Cont_ProjectPointToSeg_Impl` | 498 | `subroutine RT_Cont_ProjectPointToSeg_Impl(p, seg_a, seg_b, proj, t, dist_sq, status)` |
| SUBROUTINE | `RT_Cont_ProjectPointToTri_Impl` | 526 | `subroutine RT_Cont_ProjectPointToTri_Impl(p, tri_a, tri_b, tri_c, proj, xi, eta, dist_sq, normal, status)` |
| SUBROUTINE | `RT_Cont_SpatHashSlavePartition` | 572 | `subroutine RT_Cont_SpatHashSlavePartition(grid, coords, search_radius, &` |
| SUBROUTINE | `RT_Cont_FilterSameNode` | 635 | `subroutine RT_Cont_FilterSameNode(candidates, filtered, status)` |
| SUBROUTINE | `RT_Cont_FilterSameSurface` | 659 | `subroutine RT_Cont_FilterSameSurface(candidates, node_surf_id, seg_surf_id, filtered, status)` |
| SUBROUTINE | `RT_Cont_GapAndNormal` | 693 | `subroutine RT_Cont_GapAndNormal(slave_pt, master_pts, n_master, master_type, gap, normal, status)` |
| SUBROUTINE | `RT_Cont_InitSpatHash` | 731 | `subroutine RT_Cont_InitSpatHash(coords, cell_size_facto, grid, status)` |
| SUBROUTINE | `RT_Cont_MergeCandidates` | 816 | `subroutine RT_Cont_MergeCandidates(cand_all, part_counts, n_parts, merged, status)` |
| SUBROUTINE | `RT_Cont_Search_NarrowPhase` | 842 | `subroutine RT_Cont_Search_NarrowPhase(coords, candidates, search_radius, &` |
| SUBROUTINE | `RT_Cont_Search_Octree` | 892 | `subroutine RT_Cont_Search_Octree(octree_root, coords, search_radius, &` |
| SUBROUTINE | `RT_Cont_Search_SpatHash` | 935 | `subroutine RT_Cont_Search_SpatHash(grid, coords, search_radius, &` |
| SUBROUTINE | `RT_Cont_Search_WithStrategy` | 1035 | `subroutine RT_Cont_Search_WithStrategy(grid, coords, search_radius, strategy, &` |
| SUBROUTINE | `RT_Cont_BuildBVH` | 1076 | `subroutine RT_Cont_BuildBVH(coords, max_leaf_size, bvh_tree, status)` |
| SUBROUTINE | `RT_Cont_InitOctree` | 1108 | `subroutine RT_Cont_InitOctree(coords, max_nodes_per_l, &` |
| SUBROUTINE | `RT_Cont_Search_BroadPhase` | 1152 | `subroutine RT_Cont_Search_BroadPhase(coords, bbox_min, bbox_max, &` |
| SUBROUTINE | `RT_Cont_Search_BVH` | 1193 | `subroutine RT_Cont_Search_BVH(bvh_tree, coords, search_radius, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
