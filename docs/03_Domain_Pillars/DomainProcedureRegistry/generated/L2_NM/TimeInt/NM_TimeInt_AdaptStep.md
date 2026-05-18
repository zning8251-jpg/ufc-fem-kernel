# `NM_TimeInt_AdaptStep.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_AdaptStep.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_TimeInt_AdaptStep`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_AdaptStep`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt_AdaptStep`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_AdaptStep.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `HHT_Params_Newmark` (lines 46–50)

```fortran
    TYPE, PUBLIC :: HHT_Params_Newmark
    REAL(DP) :: alpha = -0.05_DP           !< HHT alpha [-1/3, 0]
    REAL(DP) :: beta = 0.275625_DP         !< Newmark β = (1-α)²/4
    REAL(DP) :: gamma = 0.55_DP            !< Newmark γ = 1/2 - α
  END TYPE HHT_Params_Newmark
```

### `HHT_Params_Spectral` (lines 52–54)

```fortran
  TYPE, PUBLIC :: HHT_Params_Spectral
    REAL(DP) :: rho_infinity = 0.9_DP      !< high-freq dissipation factor
  END TYPE HHT_Params_Spectral
```

### `HHT_Params_Time` (lines 56–59)

```fortran
  TYPE, PUBLIC :: HHT_Params_Time
    REAL(DP) :: time_step = 0.01_DP        !< time step Δt [s]
    REAL(DP) :: total_time = 1.0_DP        !< total time[s]
  END TYPE HHT_Params_Time
```

### `HHT_Params` (lines 61–65)

```fortran
  TYPE, PUBLIC :: HHT_Params
    TYPE(HHT_Params_Newmark)  :: newmark
    TYPE(HHT_Params_Spectral) :: spectral
    TYPE(HHT_Params_Time)     :: time
  END TYPE HHT_Params
```

### `GenAlpha_Params_Coeff` (lines 68–73)

```fortran
    TYPE, PUBLIC :: GenAlpha_Params_Coeff
    REAL(DP) :: alpha_m = 0.0_DP           !< mass alpha_m
    REAL(DP) :: alpha_f = 0.0_DP           !< force alpha_f
    REAL(DP) :: beta = 0.25_DP             !< Newmark beta
    REAL(DP) :: gamma = 0.5_DP             !< Newmark gamma
  END TYPE GenAlpha_Params_Coeff
```

### `GenAlpha_Params_Spectral` (lines 75–77)

```fortran
  TYPE, PUBLIC :: GenAlpha_Params_Spectral
    REAL(DP) :: rho_infinity = 1.0_DP      !< high-freq dissipation factor ρ
  END TYPE GenAlpha_Params_Spectral
```

### `GenAlpha_Params_Time` (lines 79–82)

```fortran
  TYPE, PUBLIC :: GenAlpha_Params_Time
    REAL(DP) :: time_step = 0.01_DP        !< time step Δt [s]
    REAL(DP) :: total_time = 1.0_DP        !< total time[s]
  END TYPE GenAlpha_Params_Time
```

### `GenAlpha_Params` (lines 84–88)

```fortran
  TYPE, PUBLIC :: GenAlpha_Params
    TYPE(GenAlpha_Params_Coeff)    :: coeff
    TYPE(GenAlpha_Params_Spectral) :: spectral
    TYPE(GenAlpha_Params_Time)     :: time
  END TYPE GenAlpha_Params
```

### `Newmark_Params` (lines 91–97)

```fortran
  TYPE, PUBLIC :: Newmark_Params
    REAL(DP) :: beta = 0.25_DP             !< Newmark beta
    REAL(DP) :: gamma = 0.5_DP             !< Newmark gamma
    REAL(DP) :: time_step = 0.01_DP        !< time step Δt [s]
    REAL(DP) :: total_time = 1.0_DP        !< total time[s]
    LOGICAL :: implicit = .TRUE.           !< implicit/explicit flag
  END TYPE Newmark_Params
```

### `AdaptiveStep_Params_Time` (lines 100–103)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_Params_Time
    REAL(DP) :: t_start = 0.0_DP           !< start time
    REAL(DP) :: t_end = 1.0_DP             !< end time
  END TYPE AdaptiveStep_Params_Time
```

### `AdaptiveStep_Params_Step` (lines 105–109)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_Params_Step
    REAL(DP) :: dt_init = 0.01_DP          !< initial step size
    REAL(DP) :: dt_min = 1.0E-10_DP        !< min step
    REAL(DP) :: dt_max = 0.1_DP            !< max step
  END TYPE AdaptiveStep_Params_Step
```

### `AdaptiveStep_Params_Tol` (lines 111–114)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_Params_Tol
    REAL(DP) :: rtol = 1.0E-6_DP           !< relative tolerance
    REAL(DP) :: atol = 1.0E-8_DP           !< absolute tolerance
  END TYPE AdaptiveStep_Params_Tol
```

### `AdaptiveStep_Params_PI` (lines 116–122)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_Params_PI
    REAL(DP) :: safety_factor = 0.9_DP     !< safety factor
    REAL(DP) :: max_step_ratio = 5.0_DP    !< max step growth ratio
    REAL(DP) :: min_step_ratio = 0.2_DP    !< min step reduction ratio
    REAL(DP) :: pi_kp = 0.7_DP             !< PI controller Kp
    REAL(DP) :: pi_ki = 0.4_DP             !< PI controller Ki
  END TYPE AdaptiveStep_Params_PI
```

### `AdaptiveStep_Params_Ctrl` (lines 124–128)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_Params_Ctrl
    INTEGER(i4) :: control_strategy = NM_STEP_CTRL_ADAPTIVE
    INTEGER(i4) :: max_rejections = 10_i4  !< max consecutive rejections
    INTEGER(i4) :: max_steps = 100000_i4   !< max time steps
  END TYPE AdaptiveStep_Params_Ctrl
```

### `AdaptiveStep_Params_Event` (lines 130–133)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_Params_Event
    LOGICAL :: enable_event_detection = .TRUE.
    REAL(DP) :: event_tolerance = 1.0E-8_DP
  END TYPE AdaptiveStep_Params_Event
```

### `AdaptiveStep_Params_IO` (lines 135–138)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_Params_IO
    LOGICAL :: verbose = .FALSE.
    INTEGER(i4) :: output_interval = 100_i4
  END TYPE AdaptiveStep_Params_IO
```

### `AdaptiveStep_Params` (lines 140–148)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_Params
    TYPE(AdaptiveStep_Params_Time)  :: time
    TYPE(AdaptiveStep_Params_Step)  :: step
    TYPE(AdaptiveStep_Params_Tol)   :: tol
    TYPE(AdaptiveStep_Params_PI)    :: pi
    TYPE(AdaptiveStep_Params_Ctrl)  :: ctrl
    TYPE(AdaptiveStep_Params_Event) :: event
    TYPE(AdaptiveStep_Params_IO)    :: io
  END TYPE AdaptiveStep_Params
```

### `Dynamic_State` (lines 151–158)

```fortran
  TYPE, PUBLIC :: Dynamic_State
    REAL(DP), ALLOCATABLE :: displacement(:)    !< displacement u(t) [m]
    REAL(DP), ALLOCATABLE :: velocity(:)        !< velocity v(t) [m/s]
    REAL(DP), ALLOCATABLE :: acceleration(:)    !< acceleration a(t) [m/s^2]
    REAL(DP) :: current_time = 0.0_DP           !< current time [s]
    INTEGER(i4) :: current_step = 0_i4          !< current step
    LOGICAL :: converged = .FALSE.              !< converged
  END TYPE Dynamic_State
```

### `AdaptiveStep_State_Step` (lines 161–164)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_State_Step
    REAL(DP) :: dt_current = 0.0_DP             !< current step size
    REAL(DP) :: dt_previous = 0.0_DP            !< previous step size
  END TYPE AdaptiveStep_State_Step
```

### `AdaptiveStep_State_Error` (lines 166–169)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_State_Error
    REAL(DP) :: error_current = 0.0_DP          !< current error
    REAL(DP) :: error_previous = 0.0_DP         !< previous step error
  END TYPE AdaptiveStep_State_Error
```

### `AdaptiveStep_State_Stats` (lines 171–176)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_State_Stats
    INTEGER(i4) :: n_steps = 0_i4               !< total steps
    INTEGER(i4) :: n_accepted = 0_i4            !< accepted steps
    INTEGER(i4) :: n_rejected = 0_i4            !< rejected steps
    INTEGER(i4) :: n_consecutive_rejects = 0_i4 !< consecutive rejections
  END TYPE AdaptiveStep_State_Stats
```

### `AdaptiveStep_State_Event` (lines 178–182)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_State_Event
    LOGICAL :: event_triggered = .FALSE.
    REAL(DP) :: event_time = 0.0_DP
    INTEGER(i4) :: event_type = 0_i4
  END TYPE AdaptiveStep_State_Event
```

### `AdaptiveStep_State_History` (lines 184–189)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_State_History
    REAL(DP), ALLOCATABLE :: error_history(:)
    REAL(DP), ALLOCATABLE :: dt_history(:)
    INTEGER(i4) :: history_size = 0_i4
    INTEGER(i4) :: history_pos = 0_i4
  END TYPE AdaptiveStep_State_History
```

### `AdaptiveStep_State` (lines 191–197)

```fortran
  TYPE, PUBLIC :: AdaptiveStep_State
    TYPE(AdaptiveStep_State_Step)    :: step
    TYPE(AdaptiveStep_State_Error)   :: error
    TYPE(AdaptiveStep_State_Stats)   :: stats
    TYPE(AdaptiveStep_State_Event)   :: event
    TYPE(AdaptiveStep_State_History) :: history
  END TYPE AdaptiveStep_State
```

### `TimeIntegration_Result` (lines 200–206)

```fortran
  TYPE, PUBLIC :: TimeIntegration_Result
    REAL(DP), ALLOCATABLE :: displacement_history(:,:)
    REAL(DP), ALLOCATABLE :: velocity_history(:,:)
    REAL(DP), ALLOCATABLE :: acceleration_history(:,:)
    REAL(DP), ALLOCATABLE :: time_history(:)
    INTEGER(i4) :: n_saved_steps = 0_i4
  END TYPE TimeIntegration_Result
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Check_Events` | 251 | `SUBROUTINE Check_Events(state, params, adaptive_state)` |
| SUBROUTINE | `Cleanup_Adaptive_State` | 262 | `SUBROUTINE Cleanup_Adaptive_State(state)` |
| SUBROUTINE | `Handle_Event` | 270 | `SUBROUTINE Handle_Event(state, adaptive_state)` |
| SUBROUTINE | `Init_Res_Storage` | 279 | `SUBROUTINE Init_Res_Storage(result, n_dof, max_steps)` |
| SUBROUTINE | `NM_Adaptive_GetControlStatistics` | 296 | `SUBROUTINE NM_Adaptive_GetControlStatistics(adaptive_state, params, stats, status)` |
| SUBROUTINE | `NM_Adaptive_GetStepStatistics` | 336 | `SUBROUTINE NM_Adaptive_GetStepStatistics(adaptive_state, stats, status)` |
| SUBROUTINE | `NM_Adaptive_GenAlpha_Solv` | 362 | `SUBROUTINE NM_Adaptive_GenAlpha_Solv(params, adaptive_params, M, C, K, F, &` |
| SUBROUTINE | `NM_Adaptive_HHT_Solv` | 497 | `SUBROUTINE NM_Adaptive_HHT_Solv(params, adaptive_params, M, C, K, F, &` |
| SUBROUTINE | `NM_Adaptive_Newmark_Solv` | 651 | `SUBROUTINE NM_Adaptive_Newmark_Solv(params, adaptive_params, M, C, K, F, &` |
| SUBROUTINE | `NM_Adaptive_OptimizeStrategy` | 749 | `SUBROUTINE NM_Adaptive_OptimizeStrategy(error_history, step_history, num_steps, &` |
| SUBROUTINE | `NM_Adaptive_TimeStep_Solv` | 787 | `SUBROUTINE NM_Adaptive_TimeStep_Solv(method_type, method_params, adaptive_params, &` |
| SUBROUTINE | `NM_AdaptiveStep_Init_State` | 837 | `SUBROUTINE NM_AdaptiveStep_Init_State(params, n_dof, state)` |
| SUBROUTINE | `NM_Calc_Adaptive_Step_Size` | 864 | `SUBROUTINE NM_Calc_Adaptive_Step_Size(params, state, dt_new)` |
| SUBROUTINE | `NM_Calc_Effective_Force` | 885 | `SUBROUTINE NM_Calc_Effective_Force(M, C, F, state, dt, beta, gamma, F_eff)` |
| SUBROUTINE | `NM_Calc_Effective_Stiff` | 912 | `SUBROUTINE NM_Calc_Effective_Stiff(K, M, C, dt, beta, gamma, K_eff)` |
| SUBROUTINE | `NM_GenAlpha_Single_Step_Adaptive` | 926 | `SUBROUTINE NM_GenAlpha_Single_Step_Adaptive(params, adaptive_params, M, C, K, &` |
| SUBROUTINE | `NM_GenAlpha_Init_Params` | 1017 | `SUBROUTINE NM_GenAlpha_Init_Params(rho_infinity, params)` |
| SUBROUTINE | `NM_HHT_Init_Params` | 1033 | `SUBROUTINE NM_HHT_Init_Params(alpha, params)` |
| SUBROUTINE | `NM_HHT_Single_Step_Adaptive` | 1043 | `SUBROUTINE NM_HHT_Single_Step_Adaptive(params, adaptive_params, M, C, K, &` |
| SUBROUTINE | `NM_Limit_Step_Size` | 1137 | `SUBROUTINE NM_Limit_Step_Size(params, dt)` |
| SUBROUTINE | `NM_Newmark_Single_Step_Adaptive` | 1145 | `SUBROUTINE NM_Newmark_Single_Step_Adaptive(params, adaptive_params, M, C, K, &` |
| SUBROUTINE | `NM_PI_Ctrl_Step_Size` | 1214 | `SUBROUTINE NM_PI_Ctrl_Step_Size(params, state, dt_new)` |
| SUBROUTINE | `NM_Predictive_Step_Size` | 1251 | `SUBROUTINE NM_Predictive_Step_Size(params, state, dt_new)` |
| SUBROUTINE | `NM_Update_Dynamic_State` | 1271 | `SUBROUTINE NM_Update_Dynamic_State(state, dt, du, beta, gamma)` |
| SUBROUTINE | `Save_State_To_Res` | 1295 | `SUBROUTINE Save_State_To_Res(state, result, idx)` |
| SUBROUTINE | `Solv_Lin_System` | 1309 | `SUBROUTINE Solv_Lin_System(A, b, x, status)` |
| SUBROUTINE | `Update_State_GenAlpha` | 1342 | `SUBROUTINE Update_State_GenAlpha(params, state, dt, du, u_new, v_new, a_new)` |
| SUBROUTINE | `Update_State_HHT` | 1365 | `SUBROUTINE Update_State_HHT(params, state, dt, du, u_new, v_new, a_new)` |
| SUBROUTINE | `Update_State_Newmark` | 1388 | `SUBROUTINE Update_State_Newmark(params, state, dt, du)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
