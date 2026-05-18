# `NM_AI_AdjointAlgo.f90`

- **Source**: `L2_NM/Solver/AI/NM_AI_AdjointAlgo.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_AI_AdjointAlgo`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_AI_AdjointAlgo`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_AI_AdjointAlgo`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/AI/NM_AI_AdjointAlgo.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_AI_Adjoint_Type` (lines 31–58)

```fortran
  TYPE, PUBLIC :: NM_AI_Adjoint_Type
    !-------------------------------------------------------------------------
    ! Algorithm configuration (冷数据，Write-Once, offline only)
    !-------------------------------------------------------------------------
    INTEGER(i4) :: adjoint_method = 0     ! 0=direct, 1=iterative, 2=AI-surrogate
    LOGICAL     :: use_transpose_solve = .TRUE. ! Use Kᵀ·λ = b instead of LU reuse
    
    ! Direct solver parameters (PARDISO/MUMPS)
    INTEGER(i4) :: direct_solver_type = 0 ! 0=PARDISO, 1=MUMPS
    INTEGER(i4) :: iparm(64) = 0          ! PARDISO parameters
    ! IPARM(12)=1 for transpose solve
    
    ! Iterative solver parameters (GMRES/CG)
    INTEGER(i4) :: krylov_subspace_dim = 30 ! GMRES restart dimension
    REAL(wp)    :: tolerance = 1e-8_wp      ! Convergence tolerance
    INTEGER(i4) :: max_iterations = 1000    ! Maximum iterations
    
    ! AI surrogate model (for fast gradient prediction)
    LOGICAL     :: use_ai_surrogate = .FALSE. ! Enable AI surrogate model
    INTEGER(i4) :: surrogate_type = 0       ! 0=NN, 1=GPR, 2=Polynomial Chaos
    REAL(wp), ALLOCATABLE :: surrogate_weights(:) ! Surrogate model weights
    
    ! Performance metrics (offline scenarios)
    REAL(wp)    :: setup_time = 0.0_wp      ! Setup time (seconds)
    REAL(wp)    :: solve_time = 0.0_wp      ! Solve time per sensitivity
    INTEGER(i4) :: num_sensitivities = 0    ! Number of computed sensitivities
    
  END TYPE NM_AI_Adjoint_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_AI_Adjoint_Init` | 66 | `SUBROUTINE NM_AI_Adjoint_Init(adjoint, stiffness_matrix, method, status)` |
| SUBROUTINE | `NM_AI_Adjoint_Finalize` | 98 | `SUBROUTINE NM_AI_Adjoint_Finalize(adjoint, status)` |
| SUBROUTINE | `NM_AI_Adjoint_Solve` | 116 | `SUBROUTINE NM_AI_Adjoint_Solve(adjoint, stiffness_matrix, objective_gradient, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
