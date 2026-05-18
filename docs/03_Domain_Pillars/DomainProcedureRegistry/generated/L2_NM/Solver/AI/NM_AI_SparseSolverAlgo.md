# `NM_AI_SparseSolverAlgo.f90`

- **Source**: `L2_NM/Solver/AI/NM_AI_SparseSolverAlgo.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_AI_SparseSolverAlgo`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_AI_SparseSolverAlgo`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_AI_SparseSolverAlgo`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/AI/NM_AI_SparseSolverAlgo.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_AI_SparseSolver_Type` (lines 30–58)

```fortran
  TYPE, PUBLIC :: NM_AI_SparseSolver_Type
    !-------------------------------------------------------------------------
    ! Solver configuration (冷数据，Write-Once)
    !-------------------------------------------------------------------------
    INTEGER(i4) :: solver_type = 0           ! 0=GMRES, 1=CG, 2=BiCGSTAB, 3=AI-GMRES
    INTEGER(i4) :: preconditioner_type = 0   ! 0=None, 1=ILU, 2=AMG, 3=AI-PC
    
    ! Matrix characteristics
    INTEGER(i4) :: matrix_symmetry = 0      ! 0=unsymmetric, 1=symmetric, 2=SPD
    INTEGER(i4) :: matrix_size = 0          ! Dimension n
    INTEGER(i4) :: nnz = 0                  ! Number of non-zeros
    
    ! AI model for solver optimization
    LOGICAL     :: use_ai_optimization = .FALSE. ! Enable AI-based optimization
    INTEGER(i4) :: ai_model_type = 0        ! 0=NN, 1=GPR, 2=Transformer
    REAL(wp), ALLOCATABLE :: ai_model_weights(:) ! Model weights
    
    ! Krylov subspace parameters (AI-optimized)
    INTEGER(i4) :: krylov_dimension = 30    ! GMRES(m) restart dimension
    REAL(wp)    :: tolerance = 1e-6_wp      ! Convergence tolerance
    INTEGER(i4) :: max_iterations = 1000    ! Maximum iterations
    
    ! Performance metrics
    REAL(wp)    :: setup_time = 0.0_wp      ! Setup time (seconds)
    REAL(wp)    :: solve_time = 0.0_wp     ! Solve time
    REAL(wp)    :: convergence_rate = 0.0_wp ! Average convergence rate
    INTEGER(i4) :: total_solves = 0        ! Total number of solves
    
  END TYPE NM_AI_SparseSolver_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_AI_SparseSolver_Init` | 66 | `SUBROUTINE NM_AI_SparseSolver_Init(solv_algo, solver_type, matrix_size, nnz, status)` |
| SUBROUTINE | `NM_AI_SparseSolver_Finalize` | 98 | `SUBROUTINE NM_AI_SparseSolver_Finalize(solv_algo, status)` |
| SUBROUTINE | `NM_AI_SparseSolver_Optimize` | 116 | `SUBROUTINE NM_AI_SparseSolver_Optimize(solv_algo, krylov_params, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
