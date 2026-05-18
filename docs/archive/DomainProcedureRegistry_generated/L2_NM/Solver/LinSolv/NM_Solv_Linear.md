# `NM_Solv_Linear.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_Linear.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_Linear`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Linear`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Linear`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_Linear.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_LinSolParams` (lines 53–67)

```fortran
    TYPE, PUBLIC :: UF_LinSolParams
        INTEGER(i4) :: solver_type = NM_SOLVER_AUTO
        ! Iterative solver parameters
        INTEGER(i4) :: max_iter = 1000
        REAL(wp) :: tol = 1.0E-10_wp
        INTEGER(i4) :: restart = 30           ! GMRES restart
        ! Preconditioner parameters
        INTEGER(i4) :: precond_type = NM_PRECOND_ILU0
        INTEGER(i4) :: lfil = 10              ! ILUT fill level
        REAL(wp) :: droptol = 1.0E-4_wp   ! ILUT drop tolerance
        ! Auto-selection thresholds
        INTEGER(i4) :: size_threshold = 5000  ! Use direct if n < threshold
        LOGICAL :: is_symmetric = .FALSE. ! Use PCG for symmetric
        LOGICAL :: verbose = .FALSE.
    END TYPE UF_LinSolParams
```

### `UF_LinSolResult` (lines 72–78)

```fortran
    TYPE, PUBLIC :: UF_LinSolResult
        INTEGER(i4) :: solver_used = 0
        INTEGER(i4) :: iterations = 0
        REAL(wp) :: residual = 0.0_wp
        REAL(wp) :: solve_time = 0.0_wp
        INTEGER(i4) :: status = 0             ! 0=success, <0=error
    END TYPE UF_LinSolResult
```

### `UF_LinSolContext` (lines 83–90)

```fortran
    TYPE, PUBLIC :: UF_LinSolContext
        LOGICAL :: initialized = .FALSE.
        TYPE(UF_Precond) :: precond
        INTEGER(i4) :: solver_type = NM_SOLVER_AUTO
        ! Direct solver factors (if used)
        REAL(wp), ALLOCATABLE :: LU_val(:)
        INTEGER, ALLOCATABLE :: LU_col(:), LU_row(:)
    END TYPE UF_LinSolContext
```

### `UF_LinearSolverWorkspace` (lines 93–96)

```fortran
    TYPE, PUBLIC :: UF_LinearSolverWorkspace
        TYPE(UF_MemoryPool_t) :: vecPool
        TYPE(UF_MatrixPool_t) :: matPool
    END TYPE UF_LinearSolverWorkspace
```

### `AGMG_Level` (lines 109–117)

```fortran
    TYPE :: AGMG_Level


        TYPE(UF_CSRMatrix) :: A_coarse    ! Coarse level matrix
        INTEGER, ALLOCATABLE :: agg(:)     ! Aggregation mapping
        INTEGER(i4) :: n_fine, n_coarse        ! Level sizes
        REAL(wp), ALLOCATABLE :: P(:,:)    ! Prolongation (if needed)
        LOGICAL :: is_coarsest = .FALSE.
    END TYPE AGMG_Level
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_LS_ResetIterStats` | 124 | `SUBROUTINE UF_LS_ResetIterStats()` |
| SUBROUTINE | `UF_LS_GetIterStats` | 129 | `SUBROUTINE UF_LS_GetIterStats(totalIter, maxIter)` |
| SUBROUTINE | `UF_LS_InitWorkspace` | 144 | `SUBROUTINE UF_LS_InitWorkspace(ws, n_init)` |
| SUBROUTINE | `UF_LS_FinalizeWorkspace` | 157 | `SUBROUTINE UF_LS_FinalizeWorkspace(ws)` |
| SUBROUTINE | `UF_LS_ConfigureWorkspace` | 164 | `SUBROUTINE UF_LS_ConfigureWorkspace(ws, A, params, solver_type)` |
| SUBROUTINE | `lin_solve` | 238 | `SUBROUTINE lin_solve(A, b, x, params, result, ierr, ws)` |
| FUNCTION | `select_solver` | 322 | `FUNCTION select_solver(A, params) RESULT(solver_type)` |
| SUBROUTINE | `lin_solve_direct` | 351 | `SUBROUTINE lin_solve_direct(A, b, x, result, ierr)` |
| SUBROUTINE | `lin_solve_pcg` | 482 | `SUBROUTINE lin_solve_pcg(A, b, x, params, result, ierr, ws)` |
| SUBROUTINE | `lin_solve_bicgstab` | 537 | `SUBROUTINE lin_solve_bicgstab(A, b, x, params, result, ierr, ws)` |
| SUBROUTINE | `lin_solve_gmres` | 588 | `SUBROUTINE lin_solve_gmres(A, b, x, params, result, ierr, ws)` |
| SUBROUTINE | `lin_solve_init` | 644 | `SUBROUTINE lin_solve_init(ctx, A, params, ierr)` |
| SUBROUTINE | `lin_solve_destroy` | 671 | `SUBROUTINE lin_solve_destroy(ctx)` |
| SUBROUTINE | `lin_solve_iterative` | 688 | `SUBROUTINE lin_solve_iterative(A, b, x, ctx, params, result, ierr, ws)` |
| SUBROUTINE | `lin_solve_cg` | 758 | `SUBROUTINE lin_solve_cg(A, b, x, params, result, ierr)` |
| SUBROUTINE | `lin_solve_iccg` | 793 | `SUBROUTINE lin_solve_iccg(A, b, x, params, result, ierr)` |
| SUBROUTINE | `lin_solve_agmg` | 829 | `SUBROUTINE lin_solve_agmg(A, b, x, params, result, ierr)` |
| SUBROUTINE | `agmg_setup` | 925 | `SUBROUTINE agmg_setup(A, levels, max_levels, ierr)` |
| SUBROUTINE | `agmg_build_coarse_matrix` | 1045 | `SUBROUTINE agmg_build_coarse_matrix(A, agg, n, nc, Ac)` |
| SUBROUTINE | `agmg_vcycle` | 1112 | `RECURSIVE SUBROUTINE agmg_vcycle(levels, nlev, r, x)` |
| SUBROUTINE | `agmg_smooth` | 1160 | `SUBROUTINE agmg_smooth(A, b, x, niter)` |
| SUBROUTINE | `agmg_restrict` | 1202 | `SUBROUTINE agmg_restrict(r_fine, agg, n, nc, r_coarse)` |
| SUBROUTINE | `agmg_prolongate` | 1226 | `SUBROUTINE agmg_prolongate(x_coarse, agg, n, nc, x_fine)` |
| FUNCTION | `agmg_matvec` | 1242 | `FUNCTION agmg_matvec(A, x) RESULT(y)` |
| SUBROUTINE | `agmg_cleanup` | 1262 | `SUBROUTINE agmg_cleanup(levels)` |
| SUBROUTINE | `lin_solve_sparsepak` | 1285 | `SUBROUTINE lin_solve_sparsepak(A, b, x, params, result, ierr)` |
| SUBROUTINE | `lin_solve_sparsepak_reuse` | 1345 | `SUBROUTINE lin_solve_sparsepak_reuse(A, b, x, handle, is_first, params, result, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
