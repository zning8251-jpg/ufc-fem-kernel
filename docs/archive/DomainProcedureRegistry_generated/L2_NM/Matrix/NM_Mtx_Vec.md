# `NM_Mtx_Vec.f90`

- **Source**: `L2_NM/Matrix/NM_Mtx_Vec.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Mtx_Vec`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Mtx_Vec`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Mtx_Vec`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_Mtx_Vec.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Vec_Add_Arg` (lines 59–70)

```fortran
  TYPE :: Vec_Add_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - First input vector
    !> [IN]  y   - Second input vector
    !> [OUT] z   - Output vector (x + y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    REAL(wp), ALLOCATABLE   :: z(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Add_Arg
```

### `Vec_Axpy_Arg` (lines 75–86)

```fortran
  TYPE :: Vec_Axpy_Arg
    !> [IN]  n     - Vector dimension
    !> [IN]  alpha - Scalar multiplier
    !> [IN]  x     - Input vector
    !> [INOUT] y   - Output vector (alpha*x + y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp)                :: alpha
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Axpy_Arg
```

### `Vec_Copy_Arg` (lines 91–100)

```fortran
  TYPE :: Vec_Copy_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - Input vector
    !> [OUT] y   - Output vector (copy of x)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Copy_Arg
```

### `Vec_Div_Arg` (lines 105–116)

```fortran
  TYPE :: Vec_Div_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - Numerator vector
    !> [IN]  y   - Denominator vector
    !> [OUT] z   - Output vector (x / y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    REAL(wp), ALLOCATABLE   :: z(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Div_Arg
```

### `Vec_Fill_Arg` (lines 121–130)

```fortran
  TYPE :: Vec_Fill_Arg
    !> [IN]  n     - Vector dimension
    !> [IN]  value - Fill value
    !> [OUT] x     - Output vector
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp)                :: value
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Fill_Arg
```

### `Vec_Scal_Arg` (lines 135–144)

```fortran
  TYPE :: Vec_Scal_Arg
    !> [IN]  n     - Vector dimension
    !> [IN]  alpha - Scalar multiplier
    !> [INOUT] x   - Input/output vector
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp)                :: alpha
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Scal_Arg
```

### `Vec_Sub_Arg` (lines 149–160)

```fortran
  TYPE :: Vec_Sub_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - First input vector
    !> [IN]  y   - Second input vector
    !> [OUT] z   - Output vector (x - y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    REAL(wp), ALLOCATABLE   :: z(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Sub_Arg
```

### `Vec_Swap_Arg` (lines 165–174)

```fortran
  TYPE :: Vec_Swap_Arg
    !> [IN]  n   - Vector dimension
    !> [INOUT] x  - First vector (swapped with y)
    !> [INOUT] y  - Second vector (swapped with x)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Swap_Arg
```

### `Vec_Normalize_Arg` (lines 179–186)

```fortran
  TYPE :: Vec_Normalize_Arg
    !> [IN]  n   - Vector dimension
    !> [INOUT] x - Input/output vector
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Normalize_Arg
```

### `Vec_Invert_Arg` (lines 191–198)

```fortran
  TYPE :: Vec_Invert_Arg
    !> [IN]  n   - Vector dimension
    !> [INOUT] x - Input/output vector
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Invert_Arg
```

### `Vec_Zero_Arg` (lines 203–210)

```fortran
  TYPE :: Vec_Zero_Arg
    !> [IN]  n   - Vector dimension
    !> [OUT] x   - Output vector (zeroed)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Zero_Arg
```

### `Vec_Linspace_Arg` (lines 215–226)

```fortran
  TYPE :: Vec_Linspace_Arg
    !> [IN]  n       - Vector dimension
    !> [IN]  x_start - Start value
    !> [IN]  x_end   - End value
    !> [OUT] x       - Output vector
    !> [OUT] status  - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp)                :: x_start
    REAL(wp)                :: x_end
    REAL(wp), ALLOCATABLE   :: x(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Linspace_Arg
```

### `Vec_Mul_Arg` (lines 231–242)

```fortran
  TYPE :: Vec_Mul_Arg
    !> [IN]  n   - Vector dimension
    !> [IN]  x   - First input vector
    !> [IN]  y   - Second input vector
    !> [OUT] z   - Output vector (x * y)
    !> [OUT] status - Error status (optional)
    INTEGER(i4)            :: n
    REAL(wp), ALLOCATABLE   :: x(:)
    REAL(wp), ALLOCATABLE   :: y(:)
    REAL(wp), ALLOCATABLE   :: z(:)
    TYPE(ErrorStatusType)   :: status
  END TYPE Vec_Mul_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Vec_Add_Proc` | 253 | `SUBROUTINE NM_Vec_Add_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Axpy_Proc` | 263 | `SUBROUTINE NM_Vec_Axpy_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Copy_Proc` | 273 | `SUBROUTINE NM_Vec_Copy_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Div_Proc` | 283 | `SUBROUTINE NM_Vec_Div_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Fill_Proc` | 301 | `SUBROUTINE NM_Vec_Fill_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Scal_Proc` | 311 | `SUBROUTINE NM_Vec_Scal_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Sub_Proc` | 321 | `SUBROUTINE NM_Vec_Sub_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Swap_Proc` | 331 | `SUBROUTINE NM_Vec_Swap_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Normalize_Proc` | 346 | `SUBROUTINE NM_Vec_Normalize_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Invert_Proc` | 363 | `SUBROUTINE NM_Vec_Invert_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Zero_Proc` | 373 | `SUBROUTINE NM_Vec_Zero_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Linspace_Proc` | 383 | `SUBROUTINE NM_Vec_Linspace_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Mul_Proc` | 407 | `SUBROUTINE NM_Vec_Mul_Proc(arg)` |
| SUBROUTINE | `NM_Vec_Add` | 418 | `SUBROUTINE NM_Vec_Add(n, x, y, z, status)` |
| FUNCTION | `NM_Vec_Asum` | 434 | `FUNCTION NM_Vec_Asum(n, x) RESULT(asum)` |
| SUBROUTINE | `NM_Vec_Axpy` | 445 | `SUBROUTINE NM_Vec_Axpy(n, alpha, x, y, status)` |
| SUBROUTINE | `NM_Vec_Copy` | 462 | `SUBROUTINE NM_Vec_Copy(n, x, y, status)` |
| SUBROUTINE | `NM_Vec_Div` | 477 | `SUBROUTINE NM_Vec_Div(n, x, y, z, status)` |
| FUNCTION | `NM_Vec_Dot` | 506 | `FUNCTION NM_Vec_Dot(n, x, y) RESULT(res)` |
| FUNCTION | `NM_Vec_CrossProduct` | 517 | `FUNCTION NM_Vec_CrossProduct(a, b) RESULT(cross)` |
| FUNCTION | `NM_Vec_Diff` | 528 | `FUNCTION NM_Vec_Diff(n, x, y) RESULT(diff)` |
| SUBROUTINE | `NM_Vec_Fill` | 543 | `SUBROUTINE NM_Vec_Fill(n, value, x, status)` |
| FUNCTION | `NM_Vec_Iamax` | 558 | `FUNCTION NM_Vec_Iamax(n, x) RESULT(imax)` |
| SUBROUTINE | `NM_Vec_Invert` | 569 | `SUBROUTINE NM_Vec_Invert(n, x, status)` |
| SUBROUTINE | `NM_Vec_Linspace` | 581 | `SUBROUTINE NM_Vec_Linspace(n, x_start, x_end, x, status)` |
| FUNCTION | `NM_Vec_Max` | 617 | `FUNCTION NM_Vec_Max(n, x) RESULT(max_val)` |
| FUNCTION | `NM_Vec_Mean` | 628 | `FUNCTION NM_Vec_Mean(n, x) RESULT(mean_val)` |
| FUNCTION | `NM_Vec_Min` | 643 | `FUNCTION NM_Vec_Min(n, x) RESULT(min_val)` |
| SUBROUTINE | `NM_Vec_Mul` | 654 | `SUBROUTINE NM_Vec_Mul(n, x, y, z, status)` |
| SUBROUTINE | `NM_Vec_Normalize` | 670 | `SUBROUTINE NM_Vec_Normalize(n, x, status)` |
| FUNCTION | `NM_Vec_NormInf` | 696 | `FUNCTION NM_Vec_NormInf(n, x) RESULT(norm_inf)` |
| FUNCTION | `NM_Vec_Nrm2` | 707 | `FUNCTION NM_Vec_Nrm2(n, x) RESULT(norm2)` |
| SUBROUTINE | `NM_Vec_Scal` | 718 | `SUBROUTINE NM_Vec_Scal(n, alpha, x, status)` |
| SUBROUTINE | `NM_Vec_Sub` | 733 | `SUBROUTINE NM_Vec_Sub(n, x, y, z, status)` |
| FUNCTION | `NM_Vec_Sum` | 749 | `FUNCTION NM_Vec_Sum(n, x) RESULT(sum_val)` |
| SUBROUTINE | `NM_Vec_Swap` | 760 | `SUBROUTINE NM_Vec_Swap(n, x, y, status)` |
| SUBROUTINE | `NM_Vec_Zero` | 778 | `SUBROUTINE NM_Vec_Zero(n, x, status)` |
| FUNCTION | `NM_Vec_Variance` | 790 | `FUNCTION NM_Vec_Variance(n, x) RESULT(variance)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
