# `NM_DirMUMPS_Brg.f90`

- **Source**: `L2_NM/Bridge/NM_DirMUMPS_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_DirMUMPS_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_DirMUMPS_Brg`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_DirMUMPS`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Bridge/NM_DirMUMPS_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_MUMPS_Context_Mumps` (lines 72–74)

```fortran
  TYPE, PUBLIC :: NM_MUMPS_Context_Mumps
    TYPE(DMUMPS_STRUC_C) :: mumps_par
  END TYPE NM_MUMPS_Context_Mumps
```

### `NM_MUMPS_Context_Status` (lines 76–80)

```fortran
  TYPE, PUBLIC :: NM_MUMPS_Context_Status
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_analyzed = .FALSE.
    LOGICAL :: is_factorized = .FALSE.
  END TYPE NM_MUMPS_Context_Status
```

### `NM_MUMPS_Context_Matrix` (lines 82–85)

```fortran
  TYPE, PUBLIC :: NM_MUMPS_Context_Matrix
    INTEGER(i4) :: n = 0_i4
    INTEGER(i4) :: nz = 0_i4
  END TYPE NM_MUMPS_Context_Matrix
```

### `NM_MUMPS_Context_Data` (lines 87–91)

```fortran
  TYPE, PUBLIC :: NM_MUMPS_Context_Data
    INTEGER(C_INT), POINTER :: irn(:) => NULL()  ! Row indices
    INTEGER(C_INT), POINTER :: jcn(:) => NULL()  ! Column indices
    REAL(C_DOUBLE), POINTER :: a(:) => NULL()    ! Values
  END TYPE NM_MUMPS_Context_Data
```

### `NM_MUMPS_Context` (lines 93–98)

```fortran
  TYPE, PUBLIC :: NM_MUMPS_Context
    TYPE(NM_MUMPS_Context_Mumps) :: mumps
    TYPE(NM_MUMPS_Context_Status) :: status
    TYPE(NM_MUMPS_Context_Matrix) :: matrix
    TYPE(NM_MUMPS_Context_Data) :: data
  END TYPE NM_MUMPS_Context
```

### `NM_SuperLU_Context_Factors` (lines 103–106)

```fortran
  TYPE, PUBLIC :: NM_SuperLU_Context_Factors
    TYPE(C_PTR) :: L = C_NULL_PTR        ! Lower triangular factor
    TYPE(C_PTR) :: U = C_NULL_PTR        ! Upper triangular factor
  END TYPE NM_SuperLU_Context_Factors
```

### `NM_SuperLU_Context_Perm` (lines 108–111)

```fortran
  TYPE, PUBLIC :: NM_SuperLU_Context_Perm
    TYPE(C_PTR) :: perm_r = C_NULL_PTR   ! Row permutations
    TYPE(C_PTR) :: perm_c = C_NULL_PTR   ! Column permutations
  END TYPE NM_SuperLU_Context_Perm
```

### `NM_SuperLU_Context_Config` (lines 113–116)

```fortran
  TYPE, PUBLIC :: NM_SuperLU_Context_Config
    TYPE(C_PTR) :: options = C_NULL_PTR  ! Solver options
    TYPE(C_PTR) :: stat = C_NULL_PTR     ! Statistics
  END TYPE NM_SuperLU_Context_Config
```

### `NM_SuperLU_Context_Status` (lines 118–121)

```fortran
  TYPE, PUBLIC :: NM_SuperLU_Context_Status
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_factorized = .FALSE.
  END TYPE NM_SuperLU_Context_Status
```

### `NM_SuperLU_Context_Matrix` (lines 123–126)

```fortran
  TYPE, PUBLIC :: NM_SuperLU_Context_Matrix
    INTEGER(i4) :: n = 0_i4
    INTEGER(i4) :: nnz = 0_i4
  END TYPE NM_SuperLU_Context_Matrix
```

### `NM_SuperLU_Context` (lines 128–134)

```fortran
  TYPE, PUBLIC :: NM_SuperLU_Context
    TYPE(NM_SuperLU_Context_Factors) :: factors
    TYPE(NM_SuperLU_Context_Perm) :: perm
    TYPE(NM_SuperLU_Context_Config) :: config
    TYPE(NM_SuperLU_Context_Status) :: status
    TYPE(NM_SuperLU_Context_Matrix) :: matrix
  END TYPE NM_SuperLU_Context
```

### `NM_DirectSolver_Params_General` (lines 139–142)

```fortran
  TYPE, PUBLIC :: NM_DirectSolver_Params_General
    INTEGER(i4) :: solver_type = 1_i4    ! 1=MUMPS, 2=SuperLU
    LOGICAL :: verbose = .FALSE.
  END TYPE NM_DirectSolver_Params_General
```

### `NM_DirectSolver_Params_Mumps` (lines 144–149)

```fortran
  TYPE, PUBLIC :: NM_DirectSolver_Params_Mumps
    INTEGER(i4) :: mumps_sym = 0_i4      ! 0=unsym, 1=SPD, 2=sym
    INTEGER(i4) :: ordering = 7_i4       ! 0=AMD, 5=METIS, 7=auto
    REAL(wp) :: pivot_threshold = 0.01_wp ! Partial pivoting threshold
    INTEGER(i4) :: icntl(60) = 0_i4      ! MUMPS control array
  END TYPE NM_DirectSolver_Params_Mumps
```

### `NM_DirectSolver_Params_SuperLU` (lines 151–155)

```fortran
  TYPE, PUBLIC :: NM_DirectSolver_Params_SuperLU
    INTEGER(i4) :: panel_size = 8_i4     ! Panel size for supernodes
    INTEGER(i4) :: relax = 8_i4          ! Supernode relaxation
    LOGICAL :: use_nat_ordering = .FALSE. ! Natural ordering vs COLAMD
  END TYPE NM_DirectSolver_Params_SuperLU
```

### `NM_DirectSolver_Params_Perf` (lines 157–160)

```fortran
  TYPE, PUBLIC :: NM_DirectSolver_Params_Perf
    INTEGER(i4) :: num_threads = 1_i4    ! OpenMP threads (SuperLU)
    LOGICAL :: use_mpi = .FALSE.         ! MPI parallelization (MUMPS)
  END TYPE NM_DirectSolver_Params_Perf
```

### `NM_DirectSolver_Params` (lines 162–167)

```fortran
  TYPE, PUBLIC :: NM_DirectSolver_Params
    TYPE(NM_DirectSolver_Params_General) :: general
    TYPE(NM_DirectSolver_Params_Mumps) :: mumps
    TYPE(NM_DirectSolver_Params_SuperLU) :: superlu
    TYPE(NM_DirectSolver_Params_Perf) :: perf
  END TYPE NM_DirectSolver_Params
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `dmumps_c` | 184 | `SUBROUTINE dmumps_c(mumps_par) BIND(C, NAME='dmumps_c')` |
| SUBROUTINE | `NM_MUMPS_Init` | 211 | `SUBROUTINE NM_MUMPS_Init(ctx, params, status)` |
| SUBROUTINE | `NM_MUMPS_Setup_FromCSR` | 266 | `SUBROUTINE NM_MUMPS_Setup_FromCSR(ctx, n, nnz, row_ptr, col_ind, values, status)` |
| SUBROUTINE | `NM_MUMPS_Analyze` | 334 | `SUBROUTINE NM_MUMPS_Analyze(ctx, status)` |
| SUBROUTINE | `NM_MUMPS_Factorize` | 382 | `SUBROUTINE NM_MUMPS_Factorize(ctx, status)` |
| SUBROUTINE | `NM_MUMPS_Solv` | 415 | `SUBROUTINE NM_MUMPS_Solv(ctx, b, x, status)` |
| SUBROUTINE | `NM_MUMPS_Finalize` | 465 | `SUBROUTINE NM_MUMPS_Finalize(ctx, status)` |
| SUBROUTINE | `NM_SuperLU_Init` | 498 | `SUBROUTINE NM_SuperLU_Init(ctx, params, status)` |
| SUBROUTINE | `NM_SuperLU_Factorize` | 519 | `SUBROUTINE NM_SuperLU_Factorize(ctx, A_csr, status)` |
| SUBROUTINE | `NM_SuperLU_Solv` | 559 | `SUBROUTINE NM_SuperLU_Solv(ctx, b, x, status)` |
| SUBROUTINE | `NM_SuperLU_Finalize` | 598 | `SUBROUTINE NM_SuperLU_Finalize(ctx, status)` |
| SUBROUTINE | `NM_DirectSolver_SyncThreads` | 626 | `SUBROUTINE NM_DirectSolver_SyncThreads(params, n_omp_threads)` |
| SUBROUTINE | `CSR_to_COO` | 641 | `SUBROUTINE CSR_to_COO(n, nnz, row_ptr, col_ind, values, irn, jcn, a, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 182–204 | `INTERFACE` |
