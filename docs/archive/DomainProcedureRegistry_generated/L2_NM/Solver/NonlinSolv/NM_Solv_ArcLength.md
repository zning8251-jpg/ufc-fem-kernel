# `NM_Solv_ArcLength.f90`

- **Source**: `L2_NM/Solver/NonlinSolv/NM_Solv_ArcLength.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_ArcLength`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_ArcLength`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_ArcLength`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/NonlinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NonlinSolv/NM_Solv_ArcLength.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ArcLength_Params_Method` (lines 32–35)

```fortran
  TYPE, PUBLIC :: ArcLength_Params_Method
    INTEGER(i4) :: method_type                 !<  
    INTEGER(i4) :: constraint_type             !<  
  END TYPE ArcLength_Params_Method
```

### `ArcLength_Params_Iter` (lines 37–40)

```fortran
  TYPE, PUBLIC :: ArcLength_Params_Iter
    INTEGER(i4) :: max_iterations              !< max iterations
    REAL(DP) :: tolerance                   !< convergence tolerance
  END TYPE ArcLength_Params_Iter
```

### `ArcLength_Params_Step` (lines 42–46)

```fortran
  TYPE, PUBLIC :: ArcLength_Params_Step
    REAL(DP) :: initial_arc_length          !< Initialize  Δl0
    REAL(DP) :: min_arc_length              !<  
    REAL(DP) :: max_arc_length              !<  
  END TYPE ArcLength_Params_Step
```

### `ArcLength_Params_Load` (lines 48–51)

```fortran
  TYPE, PUBLIC :: ArcLength_Params_Load
    REAL(DP) :: psi                         !< load  ψ
    LOGICAL  :: adaptive_arc_length         !<  
  END TYPE ArcLength_Params_Load
```

### `ArcLength_Params` (lines 53–58)

```fortran
  TYPE, PUBLIC :: ArcLength_Params
    TYPE(ArcLength_Params_Method) :: method
    TYPE(ArcLength_Params_Iter) :: iter
    TYPE(ArcLength_Params_Step) :: step
    TYPE(ArcLength_Params_Load) :: load
  END TYPE ArcLength_Params
```

### `ArcLength_State_Step` (lines 61–64)

```fortran
  TYPE, PUBLIC :: ArcLength_State_Step
    INTEGER(i4) :: current_step                !<  
    INTEGER(i4) :: current_iteration           !<  iter count
  END TYPE ArcLength_State_Step
```

### `ArcLength_State_Load` (lines 66–70)

```fortran
  TYPE, PUBLIC :: ArcLength_State_Load
    REAL(DP) :: arc_length                  !< current arc length Δl
    REAL(DP) :: load_factor                 !< load  λ
    REAL(DP) :: load_factor_increment       !< load factor increment Δλ
  END TYPE ArcLength_State_Load
```

### `ArcLength_State_Status` (lines 72–76)

```fortran
  TYPE, PUBLIC :: ArcLength_State_Status
    REAL(DP) :: constraint_residual         !<  
    LOGICAL  :: snap_through_detected       !<  
    LOGICAL  :: limit_point_detected        !<  
  END TYPE ArcLength_State_Status
```

### `ArcLength_State` (lines 78–82)

```fortran
  TYPE, PUBLIC :: ArcLength_State
    TYPE(ArcLength_State_Step) :: step
    TYPE(ArcLength_State_Load) :: load
    TYPE(ArcLength_State_Status) :: status
  END TYPE ArcLength_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_ArcLength_AdaptiveStepSize` | 98 | `SUBROUTINE NM_ArcLength_AdaptiveStepSize(params, state, convergence_rate, new_step_size, status)` |
| SUBROUTINE | `NM_ArcLength_Constraint_Equation` | 131 | `SUBROUTINE NM_ArcLength_Constraint_Equation(params, du, delta_lambda, state, phi)` |
| SUBROUTINE | `NM_ArcLength_GetPathFollowing` | 164 | `SUBROUTINE NM_ArcLength_GetPathFollowing(state, load_history, displacement_history, &` |
| SUBROUTINE | `NM_ArcLength_Update_Load_Factor` | 198 | `SUBROUTINE NM_ArcLength_Update_Load_Factor(params, state, converged)` |
| SUBROUTINE | `NM_ArcLength_Adaptive_Ctrl` | 221 | `SUBROUTINE NM_ArcLength_Adaptive_Ctrl(params, state, converged)` |
| SUBROUTINE | `NM_ArcLength_Crisfield_Step` | 249 | `SUBROUTINE NM_ArcLength_Crisfield_Step(params, u, f_ref, K_tangent, state, du)` |
| SUBROUTINE | `NM_ArcLength_GetStatistics` | 293 | `SUBROUTINE NM_ArcLength_GetStatistics(state, params, stats, status)` |
| SUBROUTINE | `NM_ArcLength_Riks_Step` | 325 | `SUBROUTINE NM_ArcLength_Riks_Step(params, u, f_ref, K_tangent, state, du)` |
| SUBROUTINE | `NM_ArcLength_Solv` | 374 | `SUBROUTINE NM_ArcLength_Solv(params, u, f_ref, K_tangent, state)` |
| SUBROUTINE | `Solv_Lin_System` | 423 | `SUBROUTINE Solv_Lin_System(A, b, x)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
