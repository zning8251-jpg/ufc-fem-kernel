# `NM_Conv_Accel.f90`

- **Source**: `L2_NM/Solver/Conv/NM_Conv_Accel.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Conv_Accel`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Conv_Accel`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Conv_Accel`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Conv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Conv/NM_Conv_Accel.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Accel_Params_Ctrl` (lines 38–41)

```fortran
    TYPE, PUBLIC :: Accel_Params_Ctrl
    INTEGER(i4) :: method = NM_ACCEL_AITKEN
    INTEGER(i4) :: max_iterations = 100_i4
  END TYPE Accel_Params_Ctrl
```

### `Accel_Params_Tol` (lines 43–45)

```fortran
  TYPE, PUBLIC :: Accel_Params_Tol
    REAL(DP) :: tolerance = 1.0E-10_DP
  END TYPE Accel_Params_Tol
```

### `Accel_Params_Order` (lines 47–51)

```fortran
  TYPE, PUBLIC :: Accel_Params_Order
    INTEGER(i4) :: shanks_order = 2_i4       !< Shanksorder
    INTEGER(i4) :: epsilon_order = 6_i4      !< epsilon algorithm order
    INTEGER(i4) :: richardson_order = 4_i4   !< Richardson extrapolation order
  END TYPE Accel_Params_Order
```

### `Accel_Params_Flags` (lines 53–55)

```fortran
  TYPE, PUBLIC :: Accel_Params_Flags
    LOGICAL :: adaptive = .TRUE.             !< adaptive method selection
  END TYPE Accel_Params_Flags
```

### `Accel_Params` (lines 57–62)

```fortran
  TYPE, PUBLIC :: Accel_Params
    TYPE(Accel_Params_Ctrl)  :: ctrl
    TYPE(Accel_Params_Tol)   :: tol
    TYPE(Accel_Params_Order) :: order
    TYPE(Accel_Params_Flags) :: flags
  END TYPE Accel_Params
```

### `Seq_Storage` (lines 65–71)

```fortran
  TYPE, PUBLIC :: Seq_Storage
    REAL(DP), ALLOCATABLE :: values(:)       !< scalar seq
    REAL(DP), ALLOCATABLE :: vectors(:,:)    !< vector seq
    INTEGER(i4) :: n_terms = 0_i4            !< current terms
    INTEGER(i4) :: max_terms = 0_i4          !< max terms
    INTEGER(i4) :: dimension = 1_i4          !< dim (1=scalar)
  END TYPE Seq_Storage
```

### `Eps_Table` (lines 74–77)

```fortran
  TYPE, PUBLIC :: Eps_Table
    REAL(DP), ALLOCATABLE :: table(:,:)      !< epsilon table
    INTEGER(i4) :: order = 0_i4              !< current order
  END TYPE Eps_Table
```

### `Vec_Eps_Table` (lines 80–83)

```fortran
  TYPE, PUBLIC :: Vec_Eps_Table
    REAL(DP), ALLOCATABLE :: table(:,:,:)    !< vector eps table
    INTEGER(i4) :: order = 0_i4
  END TYPE Vec_Eps_Table
```

### `Accel_Result_Sol` (lines 86–89)

```fortran
    TYPE, PUBLIC :: Accel_Result_Sol
    REAL(DP) :: value = ZERO                 !< scalar result
    REAL(DP), ALLOCATABLE :: vector(:)       !< vector result
  END TYPE Accel_Result_Sol
```

### `Accel_Result_Error` (lines 91–93)

```fortran
  TYPE, PUBLIC :: Accel_Result_Error
    REAL(DP) :: error_estimate = ZERO        !< error est
  END TYPE Accel_Result_Error
```

### `Accel_Result_Stats` (lines 95–97)

```fortran
  TYPE, PUBLIC :: Accel_Result_Stats
    INTEGER(i4) :: n_iterations = 0_i4       !< iter count
  END TYPE Accel_Result_Stats
```

### `Accel_Result_Flags` (lines 99–101)

```fortran
  TYPE, PUBLIC :: Accel_Result_Flags
    LOGICAL :: converged = .FALSE.           !< converged
  END TYPE Accel_Result_Flags
```

### `Accel_Result_Meta` (lines 103–105)

```fortran
  TYPE, PUBLIC :: Accel_Result_Meta
    CHARACTER(LEN=128) :: message = ""       !< message
  END TYPE Accel_Result_Meta
```

### `Accel_Result` (lines 107–113)

```fortran
  TYPE, PUBLIC :: Accel_Result
    TYPE(Accel_Result_Sol)   :: sol
    TYPE(Accel_Result_Error) :: error
    TYPE(Accel_Result_Stats) :: stats
    TYPE(Accel_Result_Flags) :: flags
    TYPE(Accel_Result_Meta)  :: meta
  END TYPE Accel_Result
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Accel_Seq` | 149 | `SUBROUTINE NM_Accel_Seq(params, sequence, result, status)` |
| SUBROUTINE | `NM_Accel_VecSeq` | 180 | `SUBROUTINE NM_Accel_VecSeq(params, sequence, result, status)` |
| SUBROUTINE | `NM_Aitken_D2` | 211 | `SUBROUTINE NM_Aitken_D2(sequence, result, status)` |
| SUBROUTINE | `NM_Aitken_Iter` | 245 | `SUBROUTINE NM_Aitken_Iter(x0, fixed_point_func, tol, max_iter, &` |
| FUNCTION | `fixed_point_func` | 249 | `FUNCTION fixed_point_func(x) RESULT(fx)` |
| FUNCTION | `NM_Aitken_Val` | 307 | `FUNCTION NM_Aitken_Val(x0, x1, x2) RESULT(x_accel)` |
| SUBROUTINE | `NM_Build_Epsilon_Table` | 325 | `SUBROUTINE NM_Build_Epsilon_Table(sequence, eps_table, status)` |
| SUBROUTINE | `NM_Eps_Algo` | 371 | `SUBROUTINE NM_Eps_Algo(sequence, result, status)` |
| SUBROUTINE | `NM_Eps_Extrap` | 391 | `SUBROUTINE NM_Eps_Extrap(eps_table, result)` |
| FUNCTION | `NM_Err_Est` | 420 | `FUNCTION NM_Err_Est(sequence) RESULT(error)` |
| SUBROUTINE | `NM_Rich_Extrap` | 435 | `SUBROUTINE NM_Rich_Extrap(sequence, order, result, status)` |
| FUNCTION | `NM_Select_Method` | 481 | `FUNCTION NM_Select_Method(sequence) RESULT(best_method)` |
| SUBROUTINE | `NM_Shanks_Tf` | 499 | `SUBROUTINE NM_Shanks_Tf(sequence, result, status)` |
| SUBROUTINE | `NM_Shanks_Tf_Ord` | 510 | `SUBROUTINE NM_Shanks_Tf_Ord(sequence, order, result, status)` |
| SUBROUTINE | `NM_Store_SeqTerm` | 564 | `SUBROUTINE NM_Store_SeqTerm(storage, value, vector)` |
| SUBROUTINE | `NM_Vec_Aitken` | 594 | `SUBROUTINE NM_Vec_Aitken(sequence, result, status)` |
| SUBROUTINE | `NM_Vec_Eps_Algo` | 631 | `SUBROUTINE NM_Vec_Eps_Algo(sequence, result, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 248–254 | `INTERFACE` |
