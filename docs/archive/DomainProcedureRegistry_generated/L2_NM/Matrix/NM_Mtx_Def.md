# `NM_Mtx_Def.f90`

- **Source**: `L2_NM/Matrix/NM_Mtx_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Mtx_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Mtx_Def`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Mtx`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_Mtx_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `DenseMatrix` (lines 47–59)

```fortran
  TYPE :: DenseMatrix
    REAL(wp), ALLOCATABLE :: data(:,:)    ! 二维数组（列主序�?
    INTEGER(i4) :: nrows = 0_i4           ! 行数
    INTEGER(i4) :: ncols = 0_i4           ! 列数
    LOGICAL :: is_allocated = .FALSE.     ! 是否已分�?
    LOGICAL :: is_symmetric = .FALSE.     ! 是否对称
    REAL(wp) :: norm_fro = 0.0_wp         ! Frobenius 范数（缓存）
  CONTAINS
    PROCEDURE, PASS :: GetShape => DenseMatrix_GetShape
    PROCEDURE, PASS :: GetNorm => DenseMatrix_GetNorm
    PROCEDURE, PASS :: IsSquare => DenseMatrix_IsSquare
    GENERIC :: SHAPE => GetShape
  END TYPE DenseMatrix
```

### `SparseMatrix_CSR` (lines 64–77)

```fortran
  TYPE :: SparseMatrix_CSR
    REAL(wp), ALLOCATABLE :: values(:)      ! 非零元值（按行压缩�?
    INTEGER(i4), ALLOCATABLE :: col_idx(:)  ! 列索引（与非零元一一对应�?
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)  ! 行指针（长度�?nrows+1�?
    INTEGER(i4) :: nrows = 0_i4             ! 行数
    INTEGER(i4) :: ncols = 0_i4             ! 列数
    INTEGER(i8) :: nnz = 0_i8               ! 非零元个�?
    LOGICAL :: is_allocated = .FALSE.       ! 是否已分�?
    LOGICAL :: is_symmetric = .FALSE.       ! 是否对称
    ! 优化提示：CSR 格式适合快速行访问（SpMV �?stride-1 遍历 values�?
  CONTAINS
    PROCEDURE, PASS :: GetNNZ => SparseMatrix_CSR_GetNNZ
    PROCEDURE, PASS :: GetRowRange => SparseMatrix_CSR_GetRowRange
  END TYPE SparseMatrix_CSR
```

### `SparseMatrix_CSC` (lines 82–91)

```fortran
  TYPE :: SparseMatrix_CSC
    REAL(wp), ALLOCATABLE :: values(:)      ! 非零元值（按列压缩�?
    INTEGER(i4), ALLOCATABLE :: row_idx(:)  ! 行索引（与非零元一一对应�?
    INTEGER(i4), ALLOCATABLE :: col_ptr(:)  ! 列指针（长度�?ncols+1�?
    INTEGER(i4) :: nrows = 0_i4             ! 行数
    INTEGER(i4) :: ncols = 0_i4             ! 列数
    INTEGER(i8) :: nnz = 0_i8               ! 非零元个�?
    LOGICAL :: is_allocated = .FALSE.       ! 是否已分�?
    ! 优化提示：CSC 格式适合快速列访问（适合某些迭代法）
  END TYPE SparseMatrix_CSC
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `DenseMatrix_GetShape` | 99 | `FUNCTION DenseMatrix_GetShape(self) RESULT(shape)` |
| FUNCTION | `DenseMatrix_GetNorm` | 107 | `FUNCTION DenseMatrix_GetNorm(self, norm_type) RESULT(norm_val)` |
| FUNCTION | `DenseMatrix_IsSquare` | 142 | `FUNCTION DenseMatrix_IsSquare(self) RESULT(is_sq)` |
| FUNCTION | `SparseMatrix_CSR_GetNNZ` | 153 | `FUNCTION SparseMatrix_CSR_GetNNZ(self) RESULT(nnz_val)` |
| SUBROUTINE | `SparseMatrix_CSR_GetRowRange` | 160 | `SUBROUTINE SparseMatrix_CSR_GetRowRange(self, row_idx, start_pos, end_pos)` |
| SUBROUTINE | `NM_Matrix_Allocate` | 192 | `SUBROUTINE NM_Matrix_Allocate(matrix, nrows, ncols, matrix_type, sym)` |
| SUBROUTINE | `NM_Matrix_Deallocate` | 232 | `SUBROUTINE NM_Matrix_Deallocate(matrix)` |
| SUBROUTINE | `NM_Matrix_Init` | 267 | `SUBROUTINE NM_Matrix_Init(matrix, value)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
