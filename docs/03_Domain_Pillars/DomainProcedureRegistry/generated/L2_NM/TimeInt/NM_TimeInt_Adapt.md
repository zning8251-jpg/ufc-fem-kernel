# `NM_TimeInt_Adapt.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_Adapt.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_TimeInt_Adapt`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_Adapt`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt_Adapt`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_Adapt.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Alpha_Method_Params_Coeff` (lines 40–45)

```fortran
    TYPE, PUBLIC :: Alpha_Method_Params_Coeff
    REAL(DP) :: alpha_m             ! Mass matrix parameter
    REAL(DP) :: alpha_f             ! Force/stiffness parameter
    REAL(DP) :: beta                ! Newmark beta
    REAL(DP) :: gamma               ! Newmark gamma
  END TYPE Alpha_Method_Params_Coeff
```

### `Alpha_Method_Params_Spectral` (lines 47–50)

```fortran
  TYPE, PUBLIC :: Alpha_Method_Params_Spectral
    REAL(DP) :: spectral_radius      ! Target spectral radius (rho_inf)
    LOGICAL :: optimal_parameters   ! Auto-compute from spectral radius
  END TYPE Alpha_Method_Params_Spectral
```

### `Alpha_Method_Params_Ctrl` (lines 52–54)

```fortran
  TYPE, PUBLIC :: Alpha_Method_Params_Ctrl
    INTEGER(i4) :: method_type          ! HHT, Generalized-alpha, etc.
  END TYPE Alpha_Method_Params_Ctrl
```

### `Alpha_Method_Parameters` (lines 56–60)

```fortran
  TYPE, PUBLIC :: Alpha_Method_Parameters
    TYPE(Alpha_Method_Params_Coeff)     :: coeff
    TYPE(Alpha_Method_Params_Spectral)  :: spectral
    TYPE(Alpha_Method_Params_Ctrl)      :: ctrl
  END TYPE Alpha_Method_Parameters
```

### `Adaptive_Step_Parameters` (lines 65–77)

```fortran
  TYPE, PUBLIC :: Adaptive_Step_Parameters
    REAL(DP) :: dt_initial          ! Initial time step
    REAL(DP) :: dt_min              ! Minimum allowed time step
    REAL(DP) :: dt_max              ! Maximum allowed time step
    REAL(DP) :: tolerance           ! Error tolerance
    REAL(DP) :: safety_factor       ! Safety factor for step size
    INTEGER(i4) :: max_iterations       ! Max nonlinear iterations
    INTEGER(i4) :: min_iterations       ! Min nonlinear iterations
    INTEGER(i4) :: step_control_type    ! Error/iteration/hybrid
    LOGICAL :: allow_step_increase  ! Allow increasing step size
    REAL(DP) :: growth_rate         ! Maximum growth factor
    REAL(DP) :: shrink_rate         ! Shrink factor
  END TYPE Adaptive_Step_Parameters
```

### `Adaptive_Time_Step_State` (lines 82–94)

```fortran
  TYPE, PUBLIC :: Adaptive_Time_Step_State
    REAL(DP) :: t_current           ! Current time
    REAL(DP) :: dt_current          ! Current time step
    REAL(DP) :: dt_previous         ! Previous time step
    INTEGER(i4) :: step_number          ! Current step number
    INTEGER(i4) :: n_rejected_steps     ! Count of rejected steps
    INTEGER(i4) :: n_accepted_steps     ! Count of accepted steps
    REAL(DP) :: estimated_error     ! Last error estimate
    REAL(DP) :: optimal_dt          ! Suggested next step size
    LOGICAL :: step_accepted        ! Last step accepted?
    LOGICAL :: converged            ! Nonlinear convergence
    INTEGER(i4) :: n_iterations         ! Nonlinear iterations used
  END TYPE Adaptive_Time_Step_State
```

### `Adaptive_Integration_State` (lines 99–110)

```fortran
  TYPE, PUBLIC :: Adaptive_Integration_State
    REAL(DP), ALLOCATABLE :: u(:)   ! Displacement
    REAL(DP), ALLOCATABLE :: v(:)   ! Velocity
    REAL(DP), ALLOCATABLE :: a(:)   ! Acceleration
    REAL(DP), ALLOCATABLE :: u_old(:)
    REAL(DP), ALLOCATABLE :: v_old(:)
    REAL(DP), ALLOCATABLE :: a_old(:)
    REAL(DP), ALLOCATABLE :: u_pred(:)  ! Predicted displacement
    REAL(DP), ALLOCATABLE :: v_pred(:)  ! Predicted velocity
    REAL(DP), ALLOCATABLE :: a_pred(:)  ! Predicted acceleration
    INTEGER(i4) :: n_dof
  END TYPE Adaptive_Integration_State
```

### `Error_Estimate_Disp` (lines 115–117)

```fortran
    TYPE, PUBLIC :: Error_Estimate_Disp
    REAL(DP) :: displacement_error
  END TYPE Error_Estimate_Disp
```

### `Error_Estimate_Vel` (lines 119–121)

```fortran
  TYPE, PUBLIC :: Error_Estimate_Vel
    REAL(DP) :: velocity_error
  END TYPE Error_Estimate_Vel
```

### `Error_Estimate_Accel` (lines 123–125)

```fortran
  TYPE, PUBLIC :: Error_Estimate_Accel
    REAL(DP) :: acceleration_error
  END TYPE Error_Estimate_Accel
```

### `Error_Estimate_Total` (lines 127–130)

```fortran
  TYPE, PUBLIC :: Error_Estimate_Total
    REAL(DP) :: total_error
    REAL(DP) :: relative_error
  END TYPE Error_Estimate_Total
```

### `Error_Estimate_Flags` (lines 132–134)

```fortran
  TYPE, PUBLIC :: Error_Estimate_Flags
    LOGICAL :: is_accurate
  END TYPE Error_Estimate_Flags
```

### `Error_Estimate` (lines 136–142)

```fortran
  TYPE, PUBLIC :: Error_Estimate
    TYPE(Error_Estimate_Disp)  :: disp
    TYPE(Error_Estimate_Vel)   :: vel
    TYPE(Error_Estimate_Accel) :: accel
    TYPE(Error_Estimate_Total) :: total
    TYPE(Error_Estimate_Flags) :: flags
  END TYPE Error_Estimate
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Al_Me_Pa_Default` | 166 | `SUBROUTINE NM_Al_Me_Pa_Default(params, method_type)` |
| SUBROUTINE | `NM_Al_Me_Pa_Optimal` | 207 | `SUBROUTINE NM_Al_Me_Pa_Optimal(rho_inf, params)` |
| SUBROUTINE | `NM_Ad_St_Pa_Default` | 229 | `SUBROUTINE NM_Ad_St_Pa_Default(params)` |
| SUBROUTINE | `NM_Adaptive_Integ_Init` | 249 | `SUBROUTINE NM_Adaptive_Integ_Init(state, n_dof, u0, v0, a0, success)` |
| SUBROUTINE | `NM_Alpha_Method_Predictor` | 285 | `SUBROUTINE NM_Alpha_Method_Predictor(state, alpha_params, dt, success)` |
| SUBROUTINE | `NM_Alpha_Method_Corrector` | 319 | `SUBROUTINE NM_Alpha_Method_Corrector(state, alpha_params, dt, &` |
| FUNCTION | `NM_HHT_Effective_Stiff` | 353 | `FUNCTION NM_HHT_Effective_Stiff(K, M, C, alpha_params, dt) RESULT(K_eff)` |
| FUNCTION | `NM_HHT_Effective_Force` | 382 | `FUNCTION NM_HHT_Effective_Force(F_ext, F_int, M, C, state, alpha_params, dt) &` |
| FUNCTION | `NM_Generalized_Alpha_Effective_Stiffness` | 419 | `FUNCTION NM_Generalized_Alpha_Effective_Stiffness(K, M, C, alpha_params, dt) &` |
| FUNCTION | `NM_Generalized_Alpha_Effective_Force` | 450 | `FUNCTION NM_Generalized_Alpha_Effective_Force(F_ext, F_int, M, C, state, &` |
| SUBROUTINE | `NM_Error_Estimate_Embedded` | 492 | `SUBROUTINE NM_Error_Estimate_Embedded(state, state_low_order, error, success)` |
| SUBROUTINE | `NM_Adaptive_Step_Size_Update` | 526 | `SUBROUTINE NM_Adaptive_Step_Size_Update(step_state, step_params, error, &` |
| SUBROUTINE | `NM_Time_Step_Accept` | 649 | `SUBROUTINE NM_Time_Step_Accept(step_state, state, success)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
