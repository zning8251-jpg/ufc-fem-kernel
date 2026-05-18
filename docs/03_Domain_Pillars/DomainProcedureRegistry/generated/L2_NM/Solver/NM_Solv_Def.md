# `NM_Solv_Def.f90`

- **Source**: `L2_NM/Solver/NM_Solv_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Def`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NM_Solv_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_Precond_Apply_Arg` (lines 55–60)

```fortran
  TYPE, PUBLIC :: NM_Precond_Apply_Arg
    INTEGER(i4) :: n = 0                       ! [IN]  vector dimension
    REAL(wp), POINTER :: v_in(:)  => NULL()    ! [IN]  input vector
    REAL(wp), POINTER :: v_out(:) => NULL()    ! [OUT] preconditioned output
    TYPE(ErrorStatusType) :: status             ! [OUT]
  END TYPE NM_Precond_Apply_Arg
```

### `NM_Solver_Desc` (lines 76–81)

```fortran
  TYPE :: NM_Solver_Desc
    INTEGER(i4) :: n            = 0_i4     ! System dimension
    INTEGER(i4) :: bandwidth    = 0_i4     ! Half-bandwidth (banded only)
    LOGICAL     :: is_symmetric = .FALSE.  ! Symmetry flag
    LOGICAL     :: is_spd       = .FALSE.  ! Symmetric positive-definite
  END TYPE NM_Solver_Desc
```

### `NM_Solver_Algo` (lines 86–100)

```fortran
  TYPE :: NM_Solver_Algo
    INTEGER(i4) :: method       = NM_SOLV_METHOD_DIRECT  ! Solver method
    INTEGER(i4) :: precond_type = NM_SOLV_PREC_NONE      ! Preconditioner
    INTEGER(i4) :: max_iter     = 1000_i4                ! Max iterations
    REAL(wp)    :: tolerance    = 1.0E-8_wp              ! Convergence tol
    REAL(wp)    :: relaxation   = 1.0_wp                 ! Relaxation (SSOR)
    LOGICAL     :: use_restart  = .TRUE.                 ! GMRES restart
    INTEGER(i4) :: restart_freq = 50_i4                  ! GMRES restart freq
    LOGICAL     :: verbose      = .FALSE.                ! Verbose output
  CONTAINS
    PROCEDURE, PASS :: SetTolerance => NM_Solver_Algo_SetTol
    PROCEDURE, PASS :: SetMaxIter   => NM_Solver_Algo_SetMaxIter
    GENERIC :: SET_TOL      => SetTolerance
    GENERIC :: SET_MAX_ITER => SetMaxIter
  END TYPE NM_Solver_Algo
```

### `NM_Solver_State` (lines 105–117)

```fortran
  TYPE :: NM_Solver_State
    INTEGER(i4) :: niter            = 0_i4         ! Current iteration count
    REAL(wp)    :: rnorm            = 0.0_wp       ! Current residual norm
    REAL(wp)    :: dunorm           = 0.0_wp       ! Displacement increment norm
    LOGICAL     :: converged        = .FALSE.      ! Convergence flag
    REAL(wp)    :: initial_residual = 0.0_wp       ! Initial residual norm
    REAL(wp)    :: solve_time       = 0.0_wp       ! Wall-clock solve time
    INTEGER(i4) :: convergence_flag = 0_i4         ! 0=OK,2=max-iter,3=singular,...
    REAL(wp), ALLOCATABLE :: residual_history(:)   ! Per-iteration residual history
    REAL(wp), POINTER :: x(:)     => NULL() ! Solution vector
    REAL(wp), POINTER :: b(:)     => NULL() ! RHS vector
    REAL(wp), POINTER :: H_inv(:,:) => NULL() ! Inverse Hessian approx
  END TYPE NM_Solver_State
```

### `NM_Solver_Ctx` (lines 122–132)

```fortran
  TYPE :: NM_Solver_Ctx
    REAL(wp)    :: alpha  = 0.0_wp          ! Line-search step
    REAL(wp), POINTER :: r(:)     => NULL() ! Residual
    REAL(wp), POINTER :: p(:)     => NULL() ! Search direction
    REAL(wp), POINTER :: Ap(:)    => NULL() ! Matrix-vector product
    REAL(wp), POINTER :: z(:)     => NULL() ! Preconditioned residual
    REAL(wp), POINTER :: du(:)    => NULL() ! Increment
    REAL(wp), POINTER :: neg_R(:) => NULL() ! Negative residual
    REAL(wp), POINTER :: diag(:)  => NULL() ! Diagonal
    REAL(wp), POINTER :: K_band(:,:) => NULL() ! Banded stiffness
  END TYPE NM_Solver_Ctx
```

### `NM_Precond_Desc` (lines 137–140)

```fortran
  TYPE :: NM_Precond_Desc
    INTEGER(i4) :: precond_type = NM_SOLV_PREC_NONE
    REAL(wp)    :: ssor_omega   = 1.75_wp
  END TYPE NM_Precond_Desc
```

### `NM_Precond_State` (lines 145–166)

```fortran
  TYPE :: NM_Precond_State
    INTEGER(i4)              :: precond_type   = NM_SOLV_PREC_NONE
    REAL(wp), ALLOCATABLE    :: diag(:)
    REAL(wp), ALLOCATABLE    :: L_data(:)
    REAL(wp), ALLOCATABLE    :: U_data(:)
    INTEGER(i4), ALLOCATABLE :: L_col(:)
    INTEGER(i4), ALLOCATABLE :: U_row(:)
    INTEGER(i4)              :: n              = 0_i4
    LOGICAL                  :: is_constructed = .FALSE.
    INTEGER(i4), ALLOCATABLE :: pc_row_ptr(:)
    INTEGER(i4), ALLOCATABLE :: pc_col_idx(:)
    REAL(wp), ALLOCATABLE    :: pc_mat_vals(:)
    REAL(wp), ALLOCATABLE    :: pc_lu_vals(:)
    INTEGER(i8)              :: pc_nnz         = 0_i8
    REAL(wp)                 :: ssor_omega     = 1.75_wp
    ! --- Phase 6B: Procedure-as-Parameter preconditioner strategy pointer ---
    PROCEDURE(NM_Precond_Strategy_Ifc), POINTER, NOPASS :: precond_strategy => NULL()
  CONTAINS
    PROCEDURE, PASS :: Construct_Jacobi => NM_Precond_Construct_Jacobi
    PROCEDURE, PASS :: Apply_Left       => NM_Precond_Apply_Left
    PROCEDURE, PASS :: Apply_Right      => NM_Precond_Apply_Right
  END TYPE NM_Precond_State
```

### `NM_Solv_Iter_Arg` (lines 173–177)

```fortran
  TYPE :: NM_Solv_Iter_Arg
    TYPE(SparseMatrix_CSR), POINTER :: A => NULL()     ! [IN]    Sparse matrix (CSR)
    REAL(wp), POINTER               :: b(:) => NULL()  ! [IN]    Right-hand side vector
    REAL(wp), POINTER               :: x(:) => NULL()  ! [INOUT] Initial guess / solution
  END TYPE NM_Solv_Iter_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Precond_Strategy_Ifc` | 66 | `SUBROUTINE NM_Precond_Strategy_Ifc(arg, status)` |
| SUBROUTINE | `NM_Solver_Algo_SetTol` | 187 | `SUBROUTINE NM_Solver_Algo_SetTol(self, tol)` |
| SUBROUTINE | `NM_Solver_Algo_SetMaxIter` | 198 | `SUBROUTINE NM_Solver_Algo_SetMaxIter(self, max_iter)` |
| SUBROUTINE | `NM_Precond_Construct_Jacobi` | 212 | `SUBROUTINE NM_Precond_Construct_Jacobi(self, A_diag)` |
| SUBROUTINE | `NM_Precond_Apply_Left` | 240 | `SUBROUTINE NM_Precond_Apply_Left(self, v, w)` |
| SUBROUTINE | `NM_Precond_Apply_Right` | 278 | `SUBROUTINE NM_Precond_Apply_Right(self, v, w)` |
| SUBROUTINE | `NM_Precond_Apply_ILU0_Internal` | 289 | `SUBROUTINE NM_Precond_Apply_ILU0_Internal(n, rp, ci, lu, v, w)` |
| SUBROUTINE | `NM_Precond_Apply_SSOR_Internal` | 328 | `SUBROUTINE NM_Precond_Apply_SSOR_Internal(n, rp, ci, av, omega, v, w)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
