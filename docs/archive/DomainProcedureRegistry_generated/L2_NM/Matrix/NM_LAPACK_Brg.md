# `NM_LAPACK_Brg.f90`

- **Source**: `L2_NM/Matrix/NM_LAPACK_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_LAPACK_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_LAPACK_Brg`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_LAPACK`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_LAPACK_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_LAPACK_EigenSolve_In` (lines 26–30)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_EigenSolve_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Symmetric matrix A (n×n)
    LOGICAL :: compute_vectors = .TRUE.     !< Compute eigenvectors (V) or eigenvalues only (N)
    CHARACTER(LEN=1) :: uplo = 'U'          !< Upper ('U') or lower ('L') triangle stored
  END TYPE NM_LAPACK_EigenSolve_In
```

### `NM_LAPACK_EigenSolve_Out` (lines 33–37)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_EigenSolve_Out
    REAL(wp), ALLOCATABLE :: eigenvalues(:)    !< Eigenvalues in ascending order
    REAL(wp), ALLOCATABLE :: eigenvectors(:,:) !< Eigenvectors (n×n), column-wise
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_EigenSolve_Out
```

### `NM_LAPACK_SVD_In` (lines 40–44)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_SVD_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Input matrix A (m×n)
    CHARACTER(LEN=1) :: jobu = 'A'          !< 'A'=all U, 'S'=min(m,n) cols, 'O'=overwrite, 'N'=none
    CHARACTER(LEN=1) :: jobvt = 'A'         !< Same options for V^T
  END TYPE NM_LAPACK_SVD_In
```

### `NM_LAPACK_SVD_Out` (lines 47–52)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_SVD_Out
    REAL(wp), ALLOCATABLE :: U(:,:)         !< Left singular vectors (m×m or m×min(m,n))
    REAL(wp), ALLOCATABLE :: Sigma(:)       !< Singular values in descending order
    REAL(wp), ALLOCATABLE :: VT(:,:)        !< Right singular vectors transposed (n×n or min(m,n)×n)
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_SVD_Out
```

### `NM_LAPACK_LUFactor_In` (lines 55–57)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_LUFactor_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Input matrix A (m×n)
  END TYPE NM_LAPACK_LUFactor_In
```

### `NM_LAPACK_LUFactor_Out` (lines 60–64)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_LUFactor_Out
    REAL(wp), ALLOCATABLE :: LU(:,:)        !< L and U stored together (m×n)
    INTEGER(i4), ALLOCATABLE :: pivot(:)    !< Pivot indices (min(m,n))
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_LUFactor_Out
```

### `NM_LAPACK_Inverse_In` (lines 67–69)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_Inverse_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Input matrix A (n×n)
  END TYPE NM_LAPACK_Inverse_In
```

### `NM_LAPACK_Inverse_Out` (lines 72–75)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_Inverse_Out
    REAL(wp), ALLOCATABLE :: inverse(:,:)   !< Inverse matrix A^{-1} (n×n)
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_Inverse_Out
```

### `NM_LAPACK_LinearSolve_In` (lines 78–82)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_LinearSolve_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Coefficient matrix A (n×n)
    REAL(wp), ALLOCATABLE :: rhs(:,:)       !< Right-hand side B (n×nrhs)
    LOGICAL :: preserve_inputs = .FALSE.    !< Preserve A and B (make internal copies)
  END TYPE NM_LAPACK_LinearSolve_In
```

### `NM_LAPACK_LinearSolve_Out` (lines 85–89)

```fortran
  TYPE, PUBLIC :: NM_LAPACK_LinearSolve_Out
    REAL(wp), ALLOCATABLE :: solution(:,:)  !< Solution X (n×nrhs)
    INTEGER(i4), ALLOCATABLE :: pivot(:)    !< Pivot indices (n)
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_LinearSolve_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_LAPACK_EigenSolve` | 102 | `SUBROUTINE NM_LAPACK_EigenSolve(in, out)` |
| SUBROUTINE | `NM_LAPACK_Inverse` | 138 | `SUBROUTINE NM_LAPACK_Inverse(in, out)` |
| SUBROUTINE | `NM_LAPACK_LinearSolve` | 209 | `SUBROUTINE NM_LAPACK_LinearSolve(in, out)` |
| SUBROUTINE | `NM_LAPACK_LUFactor` | 275 | `SUBROUTINE NM_LAPACK_LUFactor(in, out)` |
| SUBROUTINE | `NM_LAPACK_SVD` | 317 | `SUBROUTINE NM_LAPACK_SVD(in, out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
