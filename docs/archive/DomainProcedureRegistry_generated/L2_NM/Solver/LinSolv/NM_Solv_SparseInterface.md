# `NM_Solv_SparseInterface.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_SparseInterface.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_SparseInterface`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_SparseInterface`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_SparseInterface`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_SparseInterface.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_LinSolParams` (lines 31–42)

```fortran
  TYPE, PUBLIC :: UF_LinSolParams
    INTEGER(i4) :: solver_type = 0
    INTEGER(i4) :: max_iter = 1000
    REAL(wp) :: tol = 1.0E-10_wp
    INTEGER(i4) :: restart = 30
    INTEGER(i4) :: precond_type = 2
    INTEGER(i4) :: lfil = 10
    REAL(wp) :: droptol = 1.0E-4_wp
    INTEGER(i4) :: size_threshold = 5000
    LOGICAL :: is_symmetric = .FALSE.
    LOGICAL :: verbose = .FALSE.
  END TYPE UF_LinSolParams
```

### `UF_LinSolResult` (lines 44–50)

```fortran
  TYPE, PUBLIC :: UF_LinSolResult
    INTEGER(i4) :: solver_used = 0
    INTEGER(i4) :: iterations = 0
    REAL(wp) :: residual = 0.0_wp
    REAL(wp) :: solve_time = 0.0_wp
    INTEGER(i4) :: status = 0
  END TYPE UF_LinSolResult
```

### `SparseSolver_Config` (lines 56–64)

```fortran
  TYPE :: SparseSolver_Config
    CHARACTER(LEN=32) :: solver_type = "CG"          ! "CG", "GMRES", "PARDISO", "MUMPS"
    CHARACTER(LEN=32) :: precond_type = "ILU0"       ! "ILU0", "Jacobi", "SSOR", "NONE"
    INTEGER(i4) :: max_iter = 1000
    REAL(wp) :: tol_rel = 1.0e-8_wp
    REAL(wp) :: tol_abs = 1.0e-10_wp
    LOGICAL :: use_gpu = .FALSE.
    LOGICAL :: verbose = .FALSE.
  END TYPE SparseSolver_Config
```

### `SparseSolver_Context` (lines 70–75)

```fortran
  TYPE :: SparseSolver_Context
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_factorized = .FALSE.
    TYPE(SparseSolver_Config) :: config
    ! TODO: Add solver-specific state (e.g., PARDISO handle, CG workspace)
  END TYPE SparseSolver_Context
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_SparseSolver_Init` | 83 | `SUBROUTINE NM_SparseSolver_Init(config, ctx, status)` |
| SUBROUTINE | `NM_SparseSolver_Factorize` | 105 | `SUBROUTINE NM_SparseSolver_Factorize(K, ctx, status)` |
| SUBROUTINE | `NM_SparseSolver_Solve` | 167 | `SUBROUTINE NM_SparseSolver_Solve(K, b, x_init, ctx, x, n_iter, status)` |
| SUBROUTINE | `NM_SparseSolver_Solve_UF` | 238 | `SUBROUTINE NM_SparseSolver_Solve_UF(A, b, x, params, result, ierr)` |
| SUBROUTINE | `NM_Solve_CG` | 259 | `SUBROUTINE NM_Solve_CG(K, b, x_init, ctx, x, n_iter, residual_norm, status)` |
| SUBROUTINE | `CSR_MatVec` | 332 | `SUBROUTINE CSR_MatVec(A, x, y)` |
| SUBROUTINE | `NM_SparseSolver_Finalize` | 354 | `SUBROUTINE NM_SparseSolver_Finalize(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
