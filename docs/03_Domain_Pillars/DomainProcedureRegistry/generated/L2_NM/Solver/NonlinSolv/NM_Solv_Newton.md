# `NM_Solv_Newton.f90`

- **Source**: `L2_NM/Solver/NonlinSolv/NM_Solv_Newton.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_Newton`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Newton`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Newton`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/NonlinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NonlinSolv/NM_Solv_Newton.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Newton_Solver_Params_Solver` (lines 45–48)

```fortran
  TYPE, PUBLIC :: Newton_Solver_Params_Solver
    INTEGER(i4) :: solver_type                 !< Solver type
    INTEGER(i4) :: convergence_criterion       !< convergence 
  END TYPE Newton_Solver_Params_Solver
```

### `Newton_Solver_Params_Iter` (lines 50–52)

```fortran
  TYPE, PUBLIC :: Newton_Solver_Params_Iter
    INTEGER(i4) :: max_iterations              !< max iterations
  END TYPE Newton_Solver_Params_Iter
```

### `Newton_Solver_Params_Tolerance` (lines 54–58)

```fortran
  TYPE, PUBLIC :: Newton_Solver_Params_Tolerance
    REAL(DP) :: force_tolerance             !< force 
    REAL(DP) :: energy_tolerance            !<  
    REAL(DP) :: displacement_tolerance      !< displacement 
  END TYPE Newton_Solver_Params_Tolerance
```

### `Newton_Solver_Params_LineSearch` (lines 60–63)

```fortran
  TYPE, PUBLIC :: Newton_Solver_Params_LineSearch
    LOGICAL  :: use_line_search             !<  
    LOGICAL  :: update_tangent_each_iter    !<  iteration 
  END TYPE Newton_Solver_Params_LineSearch
```

### `Newton_Solver_Params_TrustRegion` (lines 65–70)

```fortran
  TYPE, PUBLIC :: Newton_Solver_Params_TrustRegion
    REAL(DP) :: trust_delta_init            !< Initialize 
    REAL(DP) :: trust_delta_max             !<  radius
    REAL(DP) :: trust_eta1                  !<  
    REAL(DP) :: trust_eta2                  !<  
  END TYPE Newton_Solver_Params_TrustRegion
```

### `Newton_Solver_Params_Callback` (lines 72–75)

```fortran
  TYPE, PUBLIC :: Newton_Solver_Params_Callback
    ! Internal-force callback for residual = F_ext - F_internal (physics from L4_PH)
    PROCEDURE(FInternalProc), POINTER, NOPASS :: f_internal_proc => NULL()
  END TYPE Newton_Solver_Params_Callback
```

### `Newton_Solver_Params` (lines 77–84)

```fortran
  TYPE, PUBLIC :: Newton_Solver_Params
    TYPE(Newton_Solver_Params_Solver) :: solver
    TYPE(Newton_Solver_Params_Iter) :: iter
    TYPE(Newton_Solver_Params_Tolerance) :: tolerance
    TYPE(Newton_Solver_Params_LineSearch) :: linesearch
    TYPE(Newton_Solver_Params_TrustRegion) :: trustregion
    TYPE(Newton_Solver_Params_Callback) :: callback
  END TYPE Newton_Solver_Params
```

### `Newton_Iteration_State_Iter` (lines 87–90)

```fortran
  TYPE, PUBLIC :: Newton_Iteration_State_Iter
    INTEGER(i4) :: current_iteration           !<  iter count
    LOGICAL  :: converged                   !< converged
  END TYPE Newton_Iteration_State_Iter
```

### `Newton_Iteration_State_Residual` (lines 92–96)

```fortran
  TYPE, PUBLIC :: Newton_Iteration_State_Residual
    REAL(DP) :: force_residual_norm         !< force 
    REAL(DP) :: energy_residual             !<  
    REAL(DP) :: displacement_increment_norm !< displacement 
  END TYPE Newton_Iteration_State_Residual
```

### `Newton_Iteration_State_LS` (lines 98–100)

```fortran
  TYPE, PUBLIC :: Newton_Iteration_State_LS
    REAL(DP) :: line_search_factor          !<  ??
  END TYPE Newton_Iteration_State_LS
```

### `Newton_Iteration_State` (lines 102–106)

```fortran
  TYPE, PUBLIC :: Newton_Iteration_State
    TYPE(Newton_Iteration_State_Iter) :: iter
    TYPE(Newton_Iteration_State_Residual) :: residual
    TYPE(Newton_Iteration_State_LS) :: ls
  END TYPE Newton_Iteration_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `FInternalProc` | 37 | `SUBROUTINE FInternalProc(u, f_internal)` |
| SUBROUTINE | `Apply_Line_Search` | 139 | `SUBROUTINE Apply_Line_Search(u, du, residual, alpha)` |
| SUBROUTINE | `Calc_Identity_Stiff` | 164 | `SUBROUTINE Calc_Identity_Stiff(n, scale, K)` |
| SUBROUTINE | `Invoke_TrustRegion_Solv` | 178 | `SUBROUTINE Invoke_TrustRegion_Solv(params, u, f_ext, K_tangent, state)` |
| SUBROUTINE | `NM_BFGS_Solv` | 212 | `SUBROUTINE NM_BFGS_Solv(params, u, f_ext, H_inverse, state, status)` |
| SUBROUTINE | `NM_BFGS_Update_Mtx` | 287 | `SUBROUTINE NM_BFGS_Update_Mtx(H_inv, s, y)` |
| SUBROUTINE | `NM_LBFGS_Solv` | 315 | `SUBROUTINE NM_LBFGS_Solv(params, u, f_ext, m, state, status)` |
| SUBROUTINE | `NM_LBFGS_Update` | 398 | `SUBROUTINE NM_LBFGS_Update(H_inverse, s_history, y_history, m, status)` |
| SUBROUTINE | `NM_ModifiedNewton_GetStatistics` | 439 | `SUBROUTINE NM_ModifiedNewton_GetStatistics(state, update_frequency, stats, status)` |
| SUBROUTINE | `NM_ModifiedNewton_Solv` | 456 | `SUBROUTINE NM_ModifiedNewton_Solv(params, u, f_ext, K_tangent, update_frequency, state, status)` |
| SUBROUTINE | `NM_Newton_ComputeTangentStiffness` | 528 | `SUBROUTINE NM_Newton_ComputeTangentStiffness(u, material_params, K_tangent, status)` |
| SUBROUTINE | `NM_Newton_BFGS_Update` | 556 | `SUBROUTINE NM_Newton_BFGS_Update(H_inverse, residual, du, u_prev)` |
| SUBROUTINE | `NM_Newton_Calc_Residual` | 593 | `SUBROUTINE NM_Newton_Calc_Residual(u, f_ext, f_internal, residual, f_internal_proc)` |
| SUBROUTINE | `NM_Newton_Check_Conv` | 610 | `SUBROUTINE NM_Newton_Check_Conv(params, residual, du, state, converged)` |
| SUBROUTINE | `NM_Newton_GetStatistics` | 650 | `SUBROUTINE NM_Newton_GetStatistics(state, stats, status)` |
| SUBROUTINE | `NM_Newton_Modified_Iteration` | 667 | `SUBROUTINE NM_Newton_Modified_Iteration(K_tangent, residual, du)` |
| SUBROUTINE | `NM_Newton_Solv` | 676 | `SUBROUTINE NM_Newton_Solv(params, u, f_ext, K_tangent, state)` |
| SUBROUTINE | `NM_Newton_Standard_Iteration` | 745 | `SUBROUTINE NM_Newton_Standard_Iteration(K_tangent, residual, du)` |
| SUBROUTINE | `NM_QuasiNewton_GetStatistics` | 775 | `SUBROUTINE NM_QuasiNewton_GetStatistics(state, method_type, stats, status)` |
| SUBROUTINE | `NM_Theory_ExportList` | 800 | `SUBROUTINE NM_Theory_ExportList(unit, status)` |
| SUBROUTINE | `NM_Theory_GetNumModules` | 818 | `SUBROUTINE NM_Theory_GetNumModules(num_modules)` |
| SUBROUTINE | `NM_Theory_QueryByIndex` | 825 | `SUBROUTINE NM_Theory_QueryByIndex(index, theory_name, description, status)` |
| SUBROUTINE | `NM_Theory_Unified_Describe` | 841 | `SUBROUTINE NM_Theory_Unified_Describe(module_id, description, status)` |
| SUBROUTINE | `NM_Theory_Unified_Query` | 867 | `SUBROUTINE NM_Theory_Unified_Query(module_id, theory_name, layer, status)` |
| FUNCTION | `OUTER_PRODUCT` | 895 | `FUNCTION OUTER_PRODUCT(a, b) RESULT(C)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
