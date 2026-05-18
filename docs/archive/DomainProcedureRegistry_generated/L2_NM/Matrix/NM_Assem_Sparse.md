# `NM_Assem_Sparse.f90`

- **Source**: `L2_NM/Matrix/NM_Assem_Sparse.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Assem_Sparse`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Assem_Sparse`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Assem_Sparse`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_Assem_Sparse.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_COOEntry` (lines 27–31)

```fortran
  type, public :: RT_COOEntry
    integer(i4) :: row = 0_i4
    integer(i4) :: col = 0_i4
    real(wp) :: val = 0.0_wp
  end type RT_COOEntry
```

### `RT_TripletList` (lines 33–43)

```fortran
  type, public :: RT_TripletList
    integer(i4) :: capacity = 0_i4
    integer(i4) :: nnz      = 0_i4
    integer(i4), allocatable :: row(:)
    integer(i4), allocatable :: col(:)
    real(wp),    allocatable :: val(:)
    logical :: use_mem_pool = .false.
    logical :: row_from_pool = .false.
    logical :: col_from_pool = .false.
    logical :: val_from_pool = .false.
  end type RT_TripletList
```

### `RT_CSRMatrix` (lines 45–56)

```fortran
  type, public :: RT_CSRMatrix
    integer(i4) :: nRows = 0_i4
    integer(i4) :: nCols = 0_i4
    integer(i4) :: nnz = 0_i4
    integer(i4), allocatable :: rowPtr(:)
    integer(i4), allocatable :: colInd(:)
    real(wp), allocatable :: values(:)
    logical :: is_symmetric = .false.
    logical :: init = .false.
  contains
    procedure :: matvec => RT_CSRMatrix_matvec
  end type RT_CSRMatrix
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Triplet_Init` | 60 | `subroutine RT_Triplet_Init(list, capacity)` |
| SUBROUTINE | `RT_Triplet_Add` | 72 | `subroutine RT_Triplet_Add(list, i, j, v)` |
| SUBROUTINE | `RT_Triplet_Free` | 100 | `subroutine RT_Triplet_Free(list)` |
| SUBROUTINE | `csr_init_from_coo` | 109 | `subroutine csr_init_from_coo(A, nRows, nCols, coo, nEntries, ierr)` |
| SUBROUTINE | `RT_CSR_FromTriplet` | 158 | `subroutine RT_CSR_FromTriplet(list, nRows, nCols, A)` |
| SUBROUTINE | `RT_CSR_Free` | 181 | `subroutine RT_CSR_Free(A)` |
| SUBROUTINE | `RT_CSR_SpMV` | 192 | `subroutine RT_CSR_SpMV(A, x, y)` |
| SUBROUTINE | `RT_CSRMatrix_matvec` | 199 | `subroutine RT_CSRMatrix_matvec(this, x, y)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
