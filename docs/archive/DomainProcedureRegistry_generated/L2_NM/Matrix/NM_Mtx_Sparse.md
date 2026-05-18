# `NM_Mtx_Sparse.f90`

- **Source**: `L2_NM/Matrix/NM_Mtx_Sparse.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Mtx_Sparse`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Mtx_Sparse`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Mtx_Sparse`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_Mtx_Sparse.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_CSR_Type` (lines 66–74)

```fortran
  TYPE, PUBLIC :: NM_CSR_Type
    INTEGER(i4) :: n = 0_i4              ! Rows
    INTEGER(i4) :: m = 0_i4              ! Columns
    INTEGER(i4) :: nnz = 0_i4            ! Nonzeros
    INTEGER(i4), ALLOCATABLE :: ia(:)    ! Row pointers (n+1)
    INTEGER(i4), ALLOCATABLE :: ja(:)    ! Column indices (nnz)
    REAL(wp), ALLOCATABLE :: a(:)        ! Values (nnz)
    LOGICAL :: is_allocated = .FALSE.
  END TYPE NM_CSR_Type
```

### `NM_COO_Type` (lines 76–84)

```fortran
  TYPE, PUBLIC :: NM_COO_Type
    INTEGER(i4) :: n = 0_i4
    INTEGER(i4) :: m = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4), ALLOCATABLE :: row(:)   ! Row indices
    INTEGER(i4), ALLOCATABLE :: col(:)   ! Column indices
    REAL(wp), ALLOCATABLE :: val(:)      ! Values
    LOGICAL :: is_allocated = .FALSE.
  END TYPE NM_COO_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `BFS_Levels` | 88 | `SUBROUTINE BFS_Levels(A, start, visited, queue, level, level_start, n)` |
| SUBROUTINE | `Mark_Distance2_Colors` | 131 | `SUBROUTINE Mark_Distance2_Colors(A, j, coloring, forbidden)` |
| SUBROUTINE | `NM_AMD_Ordering` | 146 | `SUBROUTINE NM_AMD_Ordering(A, perm, status)` |
| SUBROUTINE | `NM_COO_to_CSR` | 164 | `SUBROUTINE NM_COO_to_CSR(A_coo, A_csr, status)` |
| SUBROUTINE | `NM_CSC_to_CSR` | 224 | `SUBROUTINE NM_CSC_to_CSR(A_csc, A_csr, status)` |
| SUBROUTINE | `NM_CSR_GetStatistics` | 236 | `SUBROUTINE NM_CSR_GetStatistics(A, stats, status)` |
| SUBROUTINE | `NM_CSR_MatMult_Optimized` | 272 | `SUBROUTINE NM_CSR_MatMult_Optimized(A, B, C, status)` |
| SUBROUTINE | `NM_CSR_MatVec_Optimized` | 341 | `SUBROUTINE NM_CSR_MatVec_Optimized(A, x, y, status)` |
| SUBROUTINE | `NM_CSR_MatMult` | 368 | `SUBROUTINE NM_CSR_MatMult(A, x, y, status)` |
| SUBROUTINE | `NM_CSR_OptimizeStorage` | 381 | `SUBROUTINE NM_CSR_OptimizeStorage(A, status)` |
| SUBROUTINE | `NM_CSR_to_COO` | 435 | `SUBROUTINE NM_CSR_to_COO(A_csr, A_coo, status)` |
| SUBROUTINE | `NM_CSR_to_CSC` | 469 | `SUBROUTINE NM_CSR_to_CSC(A_csr, A_csc, status)` |
| SUBROUTINE | `NM_Graph_Coloring` | 535 | `SUBROUTINE NM_Graph_Coloring(A, coloring, num_colors, distance, status)` |
| SUBROUTINE | `NM_Mtx_Bandwidth` | 604 | `SUBROUTINE NM_Mtx_Bandwidth(A, bandwidth, status)` |
| SUBROUTINE | `NM_Mtx_Profile` | 630 | `SUBROUTINE NM_Mtx_Profile(A, profile, status)` |
| SUBROUTINE | `NM_ND_Ordering` | 655 | `SUBROUTINE NM_ND_Ordering(A, perm, status)` |
| SUBROUTINE | `NM_Permute_Mtx` | 672 | `SUBROUTINE NM_Permute_Mtx(A, perm, A_perm, status)` |
| SUBROUTINE | `NM_RCM_Ordering` | 747 | `SUBROUTINE NM_RCM_Ordering(A, perm, status)` |
| SUBROUTINE | `NM_Transpose_CSR` | 805 | `SUBROUTINE NM_Transpose_CSR(A, AT, status)` |
| SUBROUTINE | `Sort_CSR_Rows` | 817 | `SUBROUTINE Sort_CSR_Rows(A)` |
| SUBROUTINE | `Sort_Levels_By_Degree` | 843 | `SUBROUTINE Sort_Levels_By_Degree(queue, level, level_start, degree, n)` |
| SUBROUTINE | `NM_COO_Init` | 870 | `SUBROUTINE NM_COO_Init(A_coo, n, m, nnz_estimate, status)` |
| SUBROUTINE | `NM_COO_AddEntry` | 896 | `SUBROUTINE NM_COO_AddEntry(A_coo, i, j, value, status)` |
| SUBROUTINE | `NM_COO_AddElementMatrix` | 953 | `SUBROUTINE NM_COO_AddElementMatrix(A_coo, K_elem, elem_dofs, status)` |
| SUBROUTINE | `NM_COO_Finalize` | 998 | `SUBROUTINE NM_COO_Finalize(A_coo, A_csr, status)` |
| SUBROUTINE | `NM_CSR_AssembleFromElements` | 1044 | `SUBROUTINE NM_CSR_AssembleFromElements(K_csr, elem_K, elem_dofs, n_dof, nnz_estimate, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
