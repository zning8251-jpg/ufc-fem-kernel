# `MD_Mesh_Search.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Search.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mesh_Search`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Search`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh_Search`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Search.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mesh_BucketGrid` (lines 22–29)

```fortran
  TYPE, PUBLIC :: MD_Mesh_BucketGrid
    INTEGER(i4) :: nx = 0, ny = 0, nz = 0       ! Grid dimensions
    REAL(wp)    :: x_min = 0.0_wp, y_min = 0.0_wp, z_min = 0.0_wp
    REAL(wp)    :: dx = 1.0_wp, dy = 1.0_wp, dz = 1.0_wp
    INTEGER(i4), ALLOCATABLE :: cell_count(:,:,:)            ! (nx,ny,nz)
    INTEGER(i4), ALLOCATABLE :: cell_nodes(:,:,:,:)          ! (max_per_cell,nx,ny,nz)
    LOGICAL :: initialized = .FALSE.
  END TYPE MD_Mesh_BucketGrid
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mesh_Search_Build_Grid` | 43 | `SUBROUTINE MD_Mesh_Search_Build_Grid(desc, grid, n_buckets_per_dim, status)` |
| SUBROUTINE | `MD_Mesh_Search_Finalize` | 124 | `SUBROUTINE MD_Mesh_Search_Finalize(grid)` |
| SUBROUTINE | `MD_Mesh_Search_Find_Nearest` | 135 | `SUBROUTINE MD_Mesh_Search_Find_Nearest(desc, grid, query_pt, &` |
| SUBROUTINE | `MD_Mesh_Search_Find_In_Box` | 195 | `SUBROUTINE MD_Mesh_Search_Find_In_Box(desc, grid, box_min, box_max, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
