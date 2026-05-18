# `RT_Solv_Nonlin.f90`

- **Source**: `L5_RT/Solver/RT_Solv_Nonlin.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Solv_Nonlin`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_Nonlin`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv_Nonlin`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_Nonlin.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_NLSolver_Args` (lines 137–151)

```fortran
  TYPE :: RT_NLSolver_Args
    ! --- ---
    TYPE(MD_NonlinSolv)          :: solver           !< IN : max_iter, tol_force
    TYPE(MD_SolverState)         :: state            !< INOUT: u, R, lambda, du
    ! --- ---
    LOGICAL                      :: result = .FALSE. !< OUT :
    TYPE(ErrorStatusType)        :: status           !< OUT :
    ! --- OPTIONAL ---
    TYPE(UF_Model),    POINTER   :: model      => NULL()  !< OPTIONAL IN :
    TYPE(AnalysisStep),POINTER   :: step       => NULL()  !< OPTIONAL IN :
    TYPE(StepStateData),POINTER  :: step_state => NULL()  !< OPTIONAL IN :
    TYPE(RT_Sol_DofMap),POINTER  :: dofMap     => NULL()  !< OPTIONAL IN : DOF
    REAL(wp),          POINTER   :: F_ext(:)   => NULL()  !< OPTIONAL IN :
    TYPE(RT_CSRMatrix),POINTER   :: K_CSR      => NULL()  !< OPTIONAL INOUT:
  END TYPE RT_NLSolver_Args
```

### `RT_NLSolver_ArcLen_Args` (lines 158–164)

```fortran
  TYPE :: RT_NLSolver_ArcLen_Args
    TYPE(RT_NLSolver_Args) :: base  ! member `base`
    REAL(wp) :: arc_length_init = 0.01_wp        !< OPTIONAL IN :
    REAL(wp) :: arc_min        = 1.0e-4_wp       !< OPTIONAL IN :
    REAL(wp) :: arc_max        = 1.0_wp          !< OPTIONAL IN :
    REAL(wp) :: psi            = 1.0_wp          !< OPTIONAL IN : 1= 0=
  END TYPE RT_NLSolver_ArcLen_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_NLSolver_ArcLen` | 169 | `SUBROUTINE RT_NLSolver_ArcLen(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR, &` |
| SUBROUTINE | `RT_NLSolver_LineSearch` | 422 | `SUBROUTINE RT_NLSolver_LineSearch(solver, state, direction, result, status, &` |
| SUBROUTINE | `RT_NLSolver_ModifiedNewton` | 552 | `SUBROUTINE RT_NLSolver_ModifiedNewton(solver, state, tangent_update_freq, &` |
| SUBROUTINE | `RT_NLSolver_NewtonControl` | 685 | `SUBROUTINE RT_NLSolver_NewtonControl(solver, state, iteration, &` |
| SUBROUTINE | `RT_NLSolver_NewtonRaph` | 800 | `SUBROUTINE RT_NLSolver_NewtonRaph(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR, &` |
| SUBROUTINE | `RT_NLSolver_QuasiNewton` | 970 | `SUBROUTINE RT_NLSolver_QuasiNewton(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR, &` |
| SUBROUTINE | `RT_NLSolver_Solv_Unified` | 1103 | `SUBROUTINE RT_NLSolver_Solv_Unified(solver, state, result, status, model, step, step_state, dofMap, F_ext, K_CSR)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
