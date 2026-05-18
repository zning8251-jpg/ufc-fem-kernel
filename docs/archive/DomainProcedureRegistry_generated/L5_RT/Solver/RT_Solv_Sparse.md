# `RT_Solv_Sparse.f90`

- **Source**: `L5_RT/Solver/RT_Solv_Sparse.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Solv_Sparse`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_Sparse`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv_Sparse`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_Sparse.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_LUHandle` (lines 56–60)

```fortran
  type, public :: RT_LUHandle
    type(RT_CSRMatrix) :: A_L3
    type(UF_LUFactor)  :: LU
    logical            :: isInitd = .false.
  end type RT_LUHandle
```

### `RT_BlockCSRMatrix` (lines 62–66)

```fortran
  type, public :: RT_BlockCSRMatrix
    integer(i4) :: nFields = 0_i4
    integer(i4), allocatable :: fieldEqCount(:)
    type(RT_CSRMatrix), allocatable :: blocks(:,:)
  end type RT_BlockCSRMatrix
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `csr_init_from_coo` | 77 | `subroutine csr_init_from_coo(A, nRows, nCols, coo, nEntries, ierr)` |
| SUBROUTINE | `RT_Triplet_Init` | 136 | `subroutine RT_Triplet_Init(list, capacity)` |
| SUBROUTINE | `RT_Triplet_Add` | 191 | `subroutine RT_Triplet_Add(list, i, j, v)` |
| SUBROUTINE | `extendTriplet` | 212 | `subroutine extendTriplet(lst, newCap)` |
| SUBROUTINE | `RT_Triplet_Free` | 294 | `subroutine RT_Triplet_Free(list)` |
| SUBROUTINE | `RT_CSR_FromTriplet` | 305 | `subroutine RT_CSR_FromTriplet(list, nRows, nCols, A)` |
| SUBROUTINE | `RT_CSR_FromTripletMerged` | 336 | `subroutine RT_CSR_FromTripletMerged(list, nRows, nCols, A, ierr)` |
| SUBROUTINE | `triplet_sift_down` | 415 | `subroutine triplet_sift_down(lst, idx, nheap, root0)` |
| SUBROUTINE | `RT_CSR_AddToValue` | 450 | `subroutine RT_CSR_AddToValue(A, row, col, val)` |
| SUBROUTINE | `RT_CSR_SpMV` | 468 | `subroutine RT_CSR_SpMV(A, x, y)` |
| SUBROUTINE | `RT_BlockCSR_FromTriplet` | 476 | `subroutine RT_BlockCSR_FromTriplet(list, dofMap, blockMat)` |
| SUBROUTINE | `RT_BlockCSR_Free` | 550 | `subroutine RT_BlockCSR_Free(blockMat)` |
| SUBROUTINE | `RT_LU_Setup_FromCSR` | 572 | `subroutine RT_LU_Setup_FromCSR(A, handle, info)` |
| SUBROUTINE | `RT_LU_Solv` | 608 | `subroutine RT_LU_Solv(handle, b, x, info)` |
| SUBROUTINE | `RT_LU_Destroy` | 623 | `subroutine RT_LU_Destroy(handle)` |
| SUBROUTINE | `RT_LinearSolve_Direct` | 632 | `subroutine RT_LinearSolve_Direct(A, b, x, converged, info)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
