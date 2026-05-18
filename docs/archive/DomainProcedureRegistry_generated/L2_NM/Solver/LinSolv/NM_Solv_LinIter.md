# `NM_Solv_LinIter.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinIter.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_LinIter`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinIter`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinIter`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinIter.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Iterative_Solver_Params` (lines 26–33)

```fortran
  TYPE, PUBLIC :: Iterative_Solver_Params
    INTEGER(i4) :: solver_type               !< Solver type
    INTEGER(i4) :: max_iterations            !< max iterations
    INTEGER(i4) :: restart_size              !< GMRES 
    REAL(DP) :: tolerance                 !< convergence tolerance
    REAL(DP) :: rel_tolerance             !< relative tolerance
    LOGICAL  :: use_preconditioning       !<  
  END TYPE
```

### `Iterative_Solver_State` (lines 36–42)

```fortran
  TYPE, PUBLIC :: Iterative_Solver_State
    INTEGER(i4) :: iterations_performed      !<  iter count
    REAL(DP) :: final_residual            !<  
    REAL(DP) :: convergence_rate          !< convergence
    LOGICAL  :: converged                 !< converged
    REAL(DP), ALLOCATABLE :: residual_history(:) !<  
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_LinSolv_Iter_Arnoldi_Process` | 58 | `SUBROUTINE NM_LinSolv_Iter_Arnoldi_Process(A, v1, m, V, H, status)` |
| SUBROUTINE | `NM_LinSolv_Iter_BiCGStab_Solv` | 113 | `SUBROUTINE NM_LinSolv_Iter_BiCGStab_Solv(A, b, x0, params, x, state)` |
| SUBROUTINE | `NM_LinSolv_Iter_BuildKrylovSubspace` | 215 | `SUBROUTINE NM_LinSolv_Iter_BuildKrylovSubspace(A, v, m, K, status)` |
| SUBROUTINE | `NM_LinSolv_Iter_CG_Solv` | 251 | `SUBROUTINE NM_LinSolv_Iter_CG_Solv(A, b, x0, params, x, state)` |
| FUNCTION | `NM_LinSolv_Iter_Check_Conv` | 330 | `FUNCTION NM_LinSolv_Iter_Check_Conv(residual_norm, rhs_norm, params) RESULT(converged)` |
| SUBROUTINE | `NM_LinSolv_Iter_GMRES_Solv` | 355 | `SUBROUTINE NM_LinSolv_Iter_GMRES_Solv(A, b, x0, params, x, state)` |
| SUBROUTINE | `NM_LinSolv_Iter_Lanczos_Process` | 477 | `SUBROUTINE NM_LinSolv_Iter_Lanczos_Process(A, v1, m, V, alpha, beta, status)` |
| SUBROUTINE | `NM_LinSolv_Iter_SpMV` | 538 | `SUBROUTINE NM_LinSolv_Iter_SpMV(A, x, y)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
