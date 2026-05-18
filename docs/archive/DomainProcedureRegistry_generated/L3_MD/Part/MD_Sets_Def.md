# `MD_Sets_Def.f90`

- **Source**: `L3_MD/Part/MD_Sets_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Sets_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sets_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sets`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Part`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Part/MD_Sets_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_SurfFacet` (lines 53–59)

```fortran
  type, public :: MD_SurfFacet
    integer(i4) :: element_id = 0      ! Element ID  ? ?
    integer(i4) :: face_id = 0         ! Face ID  ? ?
    real(wp) :: area = 0.0_wp          ! Facet area A  ? ?
    real(wp) :: normal(3) = 0.0_wp     ! Normal vector n  ?? ?
    real(wp) :: centroid(3) = 0.0_wp  ! Centroid x_c  ?? ?
  end type MD_SurfFacet
```

### `MD_SetStatistics` (lines 166–173)

```fortran
  type, public :: MD_SetStatistics
    integer(i4) :: count = 0_i4          ! Count n  ? ?
    integer(i4) :: min_id = 0_i4         ! Minimum ID  ? ?
    integer(i4) :: max_id = 0_i4         ! Maximum ID  ? ?
    integer(i4) :: unique_count = 0_i4   ! Unique count  ? ?
    real(wp) :: mean_id = 0.0_wp         ! Mean ID ?  ? ?
    real(wp) :: std_dev = 0.0_wp         ! Standard deviation ?  ? ?
  end type MD_SetStatistics
```

### `MD_SetBoundingBox` (lines 180–185)

```fortran
  type, public :: MD_SetBoundingBox
    real(wp) :: min_coord(3) = 0.0_wp   ! Minimum coordinates x_min  ?? ?
    real(wp) :: max_coord(3) = 0.0_wp   ! Maximum coordinates x_max  ?? ?
    real(wp) :: center(3) = 0.0_wp      ! Center x_c  ?? ?
    real(wp) :: dimensions(3) = 0.0_wp  ! Dimensions d  ?? ?
  end type MD_SetBoundingBox
```

### `MD_SetDistanceResult` (lines 192–198)

```fortran
  type, public :: MD_SetDistanceResult
    real(wp) :: min_distance = 0.0_wp    ! Minimum distance d_min  ? ?
    real(wp) :: max_distance = 0.0_wp    ! Maximum distance d_max  ? ?
    real(wp) :: mean_distance = 0.0_wp  ! Mean distance d_mean  ? ?
    integer(i4) :: closest_pair(2) = 0   ! Closest pair indices  ?? ?
    integer(i4) :: farthest_pair(2) = 0  ! Farthest pair indices  ?? ?
  end type MD_SetDistanceResult
```

### `MD_SetOverlapResult` (lines 205–211)

```fortran
  type, public :: MD_SetOverlapResult
    logical :: is_overlapping = .false.  ! Overlap flag
    real(wp) :: overlap_volume = 0.0_wp ! Overlap volume V_overlap  ? ?
    real(wp) :: overlap_area = 0.0_wp   ! Overlap area A_overlap  ? ?
    integer(i4), allocatable :: overlap_nodes(:)  ! Overlapping node IDs  ??^n
    integer(i4), allocatable :: overlap_elems(:)  ! Overlapping element IDs  ??^m
  end type MD_SetOverlapResult
```

### `MD_SetSymmetryResult` (lines 218–223)

```fortran
  type, public :: MD_SetSymmetryResult
    logical :: has_symmetry = .false.    ! Symmetry flag
    integer(i4) :: symmetry_type = 0     ! Symmetry type  ? ?(1=x, 2=y, 3=z)
    real(wp) :: symmetry_plane(4) = 0.0_wp  ! Plane eq [n_x, n_y, n_z, d]
    real(wp) :: tolerance = 1.0e-6_wp    ! Tolerance ?  ? ?
  end type MD_SetSymmetryResult
```

### `MD_SetGenerationCriteria` (lines 230–241)

```fortran
  type, public :: MD_SetGenerationCriteria
    real(wp) :: box_min(3) = 0.0_wp      ! Box minimum x_min  ?? ?
    real(wp) :: box_max(3) = 0.0_wp      ! Box maximum x_max  ?? ?
    real(wp) :: sphere_center(3) = 0.0_wp  ! Sphere center x_c  ?? ?
    real(wp) :: sphere_radius = 0.0_wp   ! Sphere radius r  ? ?
    real(wp) :: cylinder_center(3) = 0.0_wp  ! Cylinder center x_c  ?? ?
    real(wp) :: cylinder_axis(3) = 0.0_wp    ! Cylinder axis direction n  ?? ?
    real(wp) :: cylinder_radius = 0.0_wp ! Cylinder radius r  ? ?
    real(wp) :: cylinder_height = 0.0_wp ! Cylinder height h  ? ?
    real(wp) :: plane_point(3) = 0.0_wp  ! Plane point x_p  ?? ?
    real(wp) :: plane_normal(3) = 0.0_wp ! Plane normal n  ?? ?
  end type MD_SetGenerationCriteria
```

### `MD_SetExportFormat` (lines 248–251)

```fortran
  type, public :: MD_SetExportFormat
    character(len=256) :: filename = ""  ! Output filename
    logical :: include_metadata = .true. ! Include metadata flag
  end type MD_SetExportFormat
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AddElem` | 258 | `subroutine AddElem(this, element_id, status)` |
| SUBROUTINE | `AddElems` | 285 | `subroutine AddElems(this, element_ids, count, status)` |
| SUBROUTINE | `AddFacet` | 317 | `subroutine AddFacet(this, facet, status)` |
| SUBROUTINE | `AddFacets` | 345 | `subroutine AddFacets(this, facets, count, status)` |
| SUBROUTINE | `AddNode` | 386 | `subroutine AddNode(this, node_id, status)` |
| SUBROUTINE | `AddNodes` | 413 | `subroutine AddNodes(this, node_ids, count, status)` |
| SUBROUTINE | `Clear` | 445 | `subroutine Clear(this, status)` |
| SUBROUTINE | `Clear` | 462 | `subroutine Clear(this, status)` |
| SUBROUTINE | `Clear` | 479 | `subroutine Clear(this, status)` |
| SUBROUTINE | `ComputeCentroid` | 498 | `subroutine ComputeCentroid(this, status)` |
| FUNCTION | `Contains` | 528 | `function Contains(this, node_id) result(found)` |
| FUNCTION | `Contains` | 546 | `function Contains(this, element_id) result(found)` |
| SUBROUTINE | `Difference` | 564 | `subroutine Difference(this, other, result, status)` |
| SUBROUTINE | `Difference` | 593 | `subroutine Difference(this, other, result, status)` |
| FUNCTION | `Equals` | 622 | `function Equals(this, other) result(equals)` |
| FUNCTION | `Equals` | 642 | `function Equals(this, other) result(equals)` |
| SUBROUTINE | `Finalize` | 662 | `subroutine Finalize(this, status)` |
| SUBROUTINE | `Finalize` | 676 | `subroutine Finalize(this, status)` |
| SUBROUTINE | `Finalize` | 690 | `subroutine Finalize(this, status)` |
| FUNCTION | `FindElem` | 706 | `function FindElem(this, element_id) result(index)` |
| FUNCTION | `FindFacet` | 724 | `function FindFacet(this, element_id, face_id) result(index)` |
| FUNCTION | `FindNode` | 750 | `function FindNode(this, node_id) result(index)` |
| FUNCTION | `GetCentroid` | 768 | `function GetCentroid(this) result(centroid)` |
| FUNCTION | `GetElemAt` | 779 | `function GetElemAt(this, index) result(element_id)` |
| FUNCTION | `GetElemIds` | 792 | `function GetElemIds(this) result(element_ids)` |
| FUNCTION | `GetFacet` | 803 | `function GetFacet(this, index) result(facet)` |
| FUNCTION | `GetNodeAt` | 816 | `function GetNodeAt(this, index) result(node_id)` |
| FUNCTION | `GetNodeIds` | 829 | `function GetNodeIds(this) result(node_ids)` |
| FUNCTION | `GetNormal` | 840 | `function GetNormal(this, index) result(normal)` |
| FUNCTION | `GetSize` | 853 | `function GetSize(this) result(size)` |
| FUNCTION | `GetSize` | 864 | `function GetSize(this) result(size)` |
| FUNCTION | `GetSize` | 875 | `function GetSize(this) result(size)` |
| SUBROUTINE | `GetStatistics` | 886 | `subroutine GetStatistics(this, stats, status)` |
| SUBROUTINE | `GetStatistics` | 931 | `subroutine GetStatistics(this, stats, status)` |
| SUBROUTINE | `GetStatistics` | 976 | `subroutine GetStatistics(this, stats, status)` |
| FUNCTION | `GetTotalArea` | 1021 | `function GetTotalArea(this) result(area)` |
| SUBROUTINE | `Init` | 1032 | `subroutine Init(this, set_id, name, capacity, status)` |
| SUBROUTINE | `Init` | 1061 | `subroutine Init(this, set_id, name, capacity, status)` |
| SUBROUTINE | `Init` | 1090 | `subroutine Init(this, surface_id, name, surface_type, capacity, status)` |
| SUBROUTINE | `Intersect` | 1123 | `subroutine Intersect(this, other, result, status)` |
| SUBROUTINE | `Intersect` | 1152 | `subroutine Intersect(this, other, result, status)` |
| FUNCTION | `IsSubset` | 1181 | `function IsSubset(this, other) result(is_subset)` |
| FUNCTION | `IsSubset` | 1200 | `function IsSubset(this, other) result(is_subset)` |
| SUBROUTINE | `MD_SetBoundingBox_Calc` | 1229 | `subroutine MD_SetBoundingBox_Calc(nodeset, coords, bbox, status)` |
| SUBROUTINE | `MD_SetDistance_Calc` | 1284 | `subroutine MD_SetDistance_Calc(set1, set2, coords, result, status)` |
| SUBROUTINE | `MD_SetExport` | 1347 | `subroutine MD_SetExport(nodeset, coords, export_format, status)` |
| SUBROUTINE | `MD_SetGenerateByBox` | 1389 | `subroutine MD_SetGenerateByBox(all_nodes, coords, criteria, result, status)` |
| SUBROUTINE | `MD_SetGenerateByCylinder` | 1419 | `subroutine MD_SetGenerateByCylinder(all_nodes, coords, criteria, result, status)` |
| SUBROUTINE | `MD_SetGenerateByPlane` | 1458 | `subroutine MD_SetGenerateByPlane(all_nodes, coords, criteria, result, status)` |
| SUBROUTINE | `MD_SetGenerateBySphere` | 1490 | `subroutine MD_SetGenerateBySphere(all_nodes, coords, criteria, result, status)` |
| SUBROUTINE | `MD_SetGenerateBySurface` | 1519 | `subroutine MD_SetGenerateBySurface(surface, coords, result, status)` |
| SUBROUTINE | `MD_SetImport` | 1548 | `subroutine MD_SetImport(filename, result, status)` |
| SUBROUTINE | `MD_SetOverlap_Check` | 1592 | `subroutine MD_SetOverlap_Check(set1, set2, coords, result, status)` |
| FUNCTION | `MD_SetSymmetry_CheckMirrored` | 1639 | `function MD_SetSymmetry_CheckMirrored(nodeset, coords, mirrored_coord, tolerance) result(found)` |
| SUBROUTINE | `MD_SetSymmetry_Detect` | 1663 | `subroutine MD_SetSymmetry_Detect(nodeset, coords, result, status)` |
| SUBROUTINE | `RemoveElem` | 1728 | `subroutine RemoveElem(this, element_id, status)` |
| SUBROUTINE | `RemoveFacet` | 1758 | `subroutine RemoveFacet(this, index, status)` |
| SUBROUTINE | `RemoveNode` | 1790 | `subroutine RemoveNode(this, node_id, status)` |
| SUBROUTINE | `Sort` | 1820 | `subroutine Sort(this, status)` |
| SUBROUTINE | `Sort` | 1839 | `subroutine Sort(this, status)` |
| SUBROUTINE | `Union` | 1858 | `subroutine Union(this, other, result, status)` |
| SUBROUTINE | `Union` | 1892 | `subroutine Union(this, other, result, status)` |
| SUBROUTINE | `Unique` | 1926 | `subroutine Unique(this, status)` |
| SUBROUTINE | `Unique` | 1949 | `subroutine Unique(this, status)` |
| SUBROUTINE | `Valid` | 1972 | `subroutine Valid(this, status)` |
| SUBROUTINE | `Valid` | 1999 | `subroutine Valid(this, status)` |
| SUBROUTINE | `Valid` | 2026 | `subroutine Valid(this, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
