# `NM_TimeInt_StepCtrl.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_StepCtrl.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_TimeInt_StepCtrl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_StepCtrl`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt_StepCtrl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_StepCtrl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PI_Controller_Params_Gain` (lines 41–45)

```fortran
    TYPE, PUBLIC :: PI_Controller_Params_Gain
    REAL(DP) :: k_P = 0.7_DP               !< proportional gain
    REAL(DP) :: k_I = 0.4_DP               !< integral gain
    REAL(DP) :: k_D = 0.0_DP               !< derivative gain (PID)
  END TYPE PI_Controller_Params_Gain
```

### `PI_Controller_Params_Factor` (lines 47–51)

```fortran
  TYPE, PUBLIC :: PI_Controller_Params_Factor
    REAL(DP) :: safety_factor = 0.9_DP     !< safety factor
    REAL(DP) :: max_factor = 5.0_DP        !< max growth factor
    REAL(DP) :: min_factor = 0.2_DP        !< min reduction factor
  END TYPE PI_Controller_Params_Factor
```

### `PI_Controller_Params_Ctrl` (lines 53–55)

```fortran
  TYPE, PUBLIC :: PI_Controller_Params_Ctrl
    INTEGER(i4) :: history_length = 5_i4   !< history length
  END TYPE PI_Controller_Params_Ctrl
```

### `PI_Controller_Params` (lines 57–61)

```fortran
  TYPE, PUBLIC :: PI_Controller_Params
    TYPE(PI_Controller_Params_Gain)   :: gain
    TYPE(PI_Controller_Params_Factor) :: factor
    TYPE(PI_Controller_Params_Ctrl)   :: ctrl
  END TYPE PI_Controller_Params
```

### `Predictive_Controller_Params` (lines 64–69)

```fortran
  TYPE, PUBLIC :: Predictive_Controller_Params
    INTEGER(i4) :: prediction_order = 2_i4 !< prediction order
    REAL(DP) :: trend_weight = 0.5_DP      !< trend weight
    REAL(DP) :: acceleration_weight = 0.3_DP !< acceleration weight
    LOGICAL :: use_error_model = .TRUE.    !< use error model
  END TYPE Predictive_Controller_Params
```

### `AdaptiveGain_Params` (lines 72–77)

```fortran
  TYPE, PUBLIC :: AdaptiveGain_Params
    REAL(DP) :: k_min = 0.1_DP             !< min gain
    REAL(DP) :: k_max = 2.0_DP             !< max gain
    REAL(DP) :: adapt_rate = 0.1_DP        !< adaptation rate
    REAL(DP) :: target_error = 0.5_DP      !< target error level
  END TYPE AdaptiveGain_Params
```

### `StepController_Config_Ctrl` (lines 80–83)

```fortran
    TYPE, PUBLIC :: StepController_Config_Ctrl
    INTEGER(i4) :: controller_type = NM_CTRL_PI
    INTEGER(i4) :: adjustment_strategy = NM_ADJUST_STANDARD
  END TYPE StepController_Config_Ctrl
```

### `StepController_Config_DT` (lines 85–89)

```fortran
  TYPE, PUBLIC :: StepController_Config_DT
    REAL(DP) :: dt_min = 1.0E-10_DP        !< min step
    REAL(DP) :: dt_max = 0.1_DP            !< max step
    REAL(DP) :: dt_init = 0.01_DP          !< initial step size
  END TYPE StepController_Config_DT
```

### `StepController_Config_Reject` (lines 91–93)

```fortran
  TYPE, PUBLIC :: StepController_Config_Reject
    INTEGER(i4) :: max_rejections = 10_i4  !< max consecutive rejections
  END TYPE StepController_Config_Reject
```

### `StepController_Config_Smooth` (lines 95–98)

```fortran
  TYPE, PUBLIC :: StepController_Config_Smooth
    LOGICAL :: enable_smoothing = .TRUE.   !< enable step smoothing
    REAL(DP) :: smoothing_factor = 0.7_DP  !< smoothing factor
  END TYPE StepController_Config_Smooth
```

### `StepController_Config` (lines 100–105)

```fortran
  TYPE, PUBLIC :: StepController_Config
    TYPE(StepController_Config_Ctrl)    :: ctrl
    TYPE(StepController_Config_DT)      :: dt
    TYPE(StepController_Config_Reject)  :: reject
    TYPE(StepController_Config_Smooth)  :: smooth
  END TYPE StepController_Config
```

### `StepController_State_Step` (lines 108–112)

```fortran
  TYPE, PUBLIC :: StepController_State_Step
    REAL(DP) :: dt_current = 0.0_DP        !< current step size
    REAL(DP) :: dt_previous = 0.0_DP       !< previous step size
    REAL(DP) :: dt_proposed = 0.0_DP       !< proposed step size
  END TYPE StepController_State_Step
```

### `StepController_State_Error` (lines 114–119)

```fortran
  TYPE, PUBLIC :: StepController_State_Error
    REAL(DP) :: error_current = 0.0_DP     !< current error
    REAL(DP) :: error_previous = 0.0_DP    !< previous step error
    REAL(DP) :: error_integral = 0.0_DP    !< error integral
    REAL(DP) :: error_derivative = 0.0_DP  !< error derivative
  END TYPE StepController_State_Error
```

### `StepController_State_Stats` (lines 121–125)

```fortran
  TYPE, PUBLIC :: StepController_State_Stats
    INTEGER(i4) :: n_steps = 0_i4          !< total steps
    INTEGER(i4) :: n_rejected = 0_i4       !< rejection count
    INTEGER(i4) :: n_consecutive_rejects = 0_i4 !< consecutive rejections
  END TYPE StepController_State_Stats
```

### `StepController_State_History` (lines 127–131)

```fortran
  TYPE, PUBLIC :: StepController_State_History
    REAL(DP), ALLOCATABLE :: error_history(:) !< error history
    REAL(DP), ALLOCATABLE :: dt_history(:)    !< step history
    INTEGER(i4) :: history_pos = 0_i4      !< history position
  END TYPE StepController_State_History
```

### `StepController_State` (lines 133–138)

```fortran
  TYPE, PUBLIC :: StepController_State
    TYPE(StepController_State_Step)    :: step
    TYPE(StepController_State_Error)   :: error
    TYPE(StepController_State_Stats)   :: stats
    TYPE(StepController_State_History) :: history
  END TYPE StepController_State
```

### `StepControl_Result` (lines 141–147)

```fortran
  TYPE, PUBLIC :: StepControl_Result
    REAL(DP) :: dt_new = 0.0_DP            !< new step size
    LOGICAL :: accept_step = .TRUE.        !< accept current step or not
    REAL(DP) :: growth_factor = 1.0_DP     !< growth factor
    INTEGER(i4) :: control_action = 0_i4   !< control action
    CHARACTER(LEN=128) :: message = ""     !< control message
  END TYPE StepControl_Result
```

### `TimeStep_Event` (lines 150–155)

```fortran
  TYPE, PUBLIC :: TimeStep_Event
    INTEGER(i4) :: event_type = 0_i4       !< event type
    REAL(DP) :: event_time = 0.0_DP        !< event time
    REAL(DP) :: event_value = 0.0_DP       !< event value
    LOGICAL :: is_triggered = .FALSE.      !< triggered or not
  END TYPE TimeStep_Event
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_StepController_Init` | 199 | `SUBROUTINE NM_StepController_Init(config, state, status)` |
| SUBROUTINE | `NM_StepController_Calc_Step` | 241 | `SUBROUTINE NM_StepController_Calc_Step(config, state, error_current, &` |
| SUBROUTINE | `NM_StepController_Update` | 309 | `SUBROUTINE NM_StepController_Update(config, state, step_accepted, dt_used)` |
| SUBROUTINE | `NM_PI_Ctrl_Step` | 352 | `SUBROUTINE NM_PI_Ctrl_Step(config, pi_params, state, result, status)` |
| SUBROUTINE | `NM_PID_Ctrl_Step` | 412 | `SUBROUTINE NM_PID_Ctrl_Step(config, pid_params, state, result, status)` |
| SUBROUTINE | `NM_Predictive_Ctrl_Step` | 474 | `SUBROUTINE NM_Predictive_Ctrl_Step(config, pred_params, state, result, status)` |
| SUBROUTINE | `NM_Predict_Error_Trend` | 527 | `SUBROUTINE NM_Predict_Error_Trend(state, order, predicted_error, trend, acceleration)` |
| SUBROUTINE | `NM_AdaptiveGain_Ctrl_Step` | 579 | `SUBROUTINE NM_AdaptiveGain_Ctrl_Step(config, ag_params, state, result, status)` |
| SUBROUTINE | `NM_Limit_Step_Size_Advanced` | 629 | `SUBROUTINE NM_Limit_Step_Size_Advanced(config, dt)` |
| SUBROUTINE | `NM_Smooth_Step_Change` | 662 | `SUBROUTINE NM_Smooth_Step_Change(alpha, dt_old, dt_new)` |
| SUBROUTINE | `NM_Check_Step_Events` | 680 | `SUBROUTINE NM_Check_Step_Events(state, config, event, status)` |
| SUBROUTINE | `NM_Handle_Step_Event` | 705 | `SUBROUTINE NM_Handle_Step_Event(event, result, status)` |
| FUNCTION | `NM_Calc_Growth_Factor` | 740 | `FUNCTION NM_Calc_Growth_Factor(error, order, safety) RESULT(factor)` |
| SUBROUTINE | `NM_Eval_Ctrl_Strategy` | 758 | `SUBROUTINE NM_Eval_Ctrl_Strategy(state, config, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
