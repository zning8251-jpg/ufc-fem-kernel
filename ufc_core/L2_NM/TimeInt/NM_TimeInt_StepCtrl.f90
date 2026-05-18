!===============================================================================
! MODULE: NM_TimeInt_StepCtrl
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — Time step controller (PI/PID/predictive/event-driven)
! BRIEF:  Adaptive step-size control with PI controller and event detection
!===============================================================================

MODULE NM_TimeInt_StepCtrl
!> Status: Production | Last verified: 2026-03-01
!> Theory: Adaptive time stepping | Ref: Hairer&Wanner(1996)
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief controller type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CTRL_PI = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CTRL_PID = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CTRL_PREDICTIVE = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CTRL_DEADBEAT = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CTRL_ADAPTIVE_GAIN = 5

  !> @brief step adjust strategy enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ADJUST_STANDARD = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ADJUST_AGGRESSIVE = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ADJUST_CONSERVATIVE = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_ADJUST_EVENT_DRIVEN = 4

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief PI controller params
    TYPE, PUBLIC :: PI_Controller_Params_Gain
    REAL(DP) :: k_P = 0.7_DP               !< proportional gain
    REAL(DP) :: k_I = 0.4_DP               !< integral gain
    REAL(DP) :: k_D = 0.0_DP               !< derivative gain (PID)
  END TYPE PI_Controller_Params_Gain

  TYPE, PUBLIC :: PI_Controller_Params_Factor
    REAL(DP) :: safety_factor = 0.9_DP     !< safety factor
    REAL(DP) :: max_factor = 5.0_DP        !< max growth factor
    REAL(DP) :: min_factor = 0.2_DP        !< min reduction factor
  END TYPE PI_Controller_Params_Factor

  TYPE, PUBLIC :: PI_Controller_Params_Ctrl
    INTEGER(i4) :: history_length = 5_i4   !< history length
  END TYPE PI_Controller_Params_Ctrl

  TYPE, PUBLIC :: PI_Controller_Params
    TYPE(PI_Controller_Params_Gain)   :: gain
    TYPE(PI_Controller_Params_Factor) :: factor
    TYPE(PI_Controller_Params_Ctrl)   :: ctrl
  END TYPE PI_Controller_Params

  !> @brief predictive controller params
  TYPE, PUBLIC :: Predictive_Controller_Params
    INTEGER(i4) :: prediction_order = 2_i4 !< prediction order
    REAL(DP) :: trend_weight = 0.5_DP      !< trend weight
    REAL(DP) :: acceleration_weight = 0.3_DP !< acceleration weight
    LOGICAL :: use_error_model = .TRUE.    !< use error model
  END TYPE Predictive_Controller_Params

  !> @brief adaptive gain controller params
  TYPE, PUBLIC :: AdaptiveGain_Params
    REAL(DP) :: k_min = 0.1_DP             !< min gain
    REAL(DP) :: k_max = 2.0_DP             !< max gain
    REAL(DP) :: adapt_rate = 0.1_DP        !< adaptation rate
    REAL(DP) :: target_error = 0.5_DP      !< target error level
  END TYPE AdaptiveGain_Params

  !> @brief step controller config
    TYPE, PUBLIC :: StepController_Config_Ctrl
    INTEGER(i4) :: controller_type = NM_CTRL_PI
    INTEGER(i4) :: adjustment_strategy = NM_ADJUST_STANDARD
  END TYPE StepController_Config_Ctrl

  TYPE, PUBLIC :: StepController_Config_DT
    REAL(DP) :: dt_min = 1.0E-10_DP        !< min step
    REAL(DP) :: dt_max = 0.1_DP            !< max step
    REAL(DP) :: dt_init = 0.01_DP          !< initial step size
  END TYPE StepController_Config_DT

  TYPE, PUBLIC :: StepController_Config_Reject
    INTEGER(i4) :: max_rejections = 10_i4  !< max consecutive rejections
  END TYPE StepController_Config_Reject

  TYPE, PUBLIC :: StepController_Config_Smooth
    LOGICAL :: enable_smoothing = .TRUE.   !< enable step smoothing
    REAL(DP) :: smoothing_factor = 0.7_DP  !< smoothing factor
  END TYPE StepController_Config_Smooth

  TYPE, PUBLIC :: StepController_Config
    TYPE(StepController_Config_Ctrl)    :: ctrl
    TYPE(StepController_Config_DT)      :: dt
    TYPE(StepController_Config_Reject)  :: reject
    TYPE(StepController_Config_Smooth)  :: smooth
  END TYPE StepController_Config

  !> @brief controller state
  TYPE, PUBLIC :: StepController_State_Step
    REAL(DP) :: dt_current = 0.0_DP        !< current step size
    REAL(DP) :: dt_previous = 0.0_DP       !< previous step size
    REAL(DP) :: dt_proposed = 0.0_DP       !< proposed step size
  END TYPE StepController_State_Step

  TYPE, PUBLIC :: StepController_State_Error
    REAL(DP) :: error_current = 0.0_DP     !< current error
    REAL(DP) :: error_previous = 0.0_DP    !< previous step error
    REAL(DP) :: error_integral = 0.0_DP    !< error integral
    REAL(DP) :: error_derivative = 0.0_DP  !< error derivative
  END TYPE StepController_State_Error

  TYPE, PUBLIC :: StepController_State_Stats
    INTEGER(i4) :: n_steps = 0_i4          !< total steps
    INTEGER(i4) :: n_rejected = 0_i4       !< rejection count
    INTEGER(i4) :: n_consecutive_rejects = 0_i4 !< consecutive rejections
  END TYPE StepController_State_Stats

  TYPE, PUBLIC :: StepController_State_History
    REAL(DP), ALLOCATABLE :: error_history(:) !< error history
    REAL(DP), ALLOCATABLE :: dt_history(:)    !< step history
    INTEGER(i4) :: history_pos = 0_i4      !< history position
  END TYPE StepController_State_History

  TYPE, PUBLIC :: StepController_State
    TYPE(StepController_State_Step)    :: step
    TYPE(StepController_State_Error)   :: error
    TYPE(StepController_State_Stats)   :: stats
    TYPE(StepController_State_History) :: history
  END TYPE StepController_State

  !> @brief step control result
  TYPE, PUBLIC :: StepControl_Result
    REAL(DP) :: dt_new = 0.0_DP            !< new step size
    LOGICAL :: accept_step = .TRUE.        !< accept current step or not
    REAL(DP) :: growth_factor = 1.0_DP     !< growth factor
    INTEGER(i4) :: control_action = 0_i4   !< control action
    CHARACTER(LEN=128) :: message = ""     !< control message
  END TYPE StepControl_Result

  !> @brief event definition
  TYPE, PUBLIC :: TimeStep_Event
    INTEGER(i4) :: event_type = 0_i4       !< event type
    REAL(DP) :: event_time = 0.0_DP        !< event time
    REAL(DP) :: event_value = 0.0_DP       !< event value
    LOGICAL :: is_triggered = .FALSE.      !< triggered or not
  END TYPE TimeStep_Event

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main control interface
  PUBLIC :: NM_StepController_Init
  PUBLIC :: NM_StepController_Calc_Step
  PUBLIC :: NM_StepController_Update
  
  ! PI control
  PUBLIC :: NM_PI_Ctrl_Step
  PUBLIC :: NM_PID_Ctrl_Step
  
  ! predictive control
  PUBLIC :: NM_Predictive_Ctrl_Step
  PUBLIC :: NM_Predict_Error_Trend
  
  ! adaptive gain
  PUBLIC :: NM_AdaptiveGain_Ctrl_Step
  
  ! step limits
  PUBLIC :: NM_Limit_Step_Size_Advanced
  PUBLIC :: NM_Smooth_Step_Change
  
  ! event handling
  PUBLIC :: NM_Check_Step_Events
  PUBLIC :: NM_Handle_Step_Event
  
  ! utils
  PUBLIC :: NM_Calc_Growth_Factor
  PUBLIC :: NM_Eval_Ctrl_Strategy

CONTAINS

  !=============================================================================
  ! CONTROLLER INITIALIZATION
  !=============================================================================

  !> @brief Initialize step controller
  !! @param[in] config controller config
  !! @param[out] state controller state
  !! @param[out] status error status
  SUBROUTINE NM_StepController_Init(config, state, status)
    TYPE(StepController_Config), INTENT(IN) :: config
    TYPE(StepController_State), INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: history_len

    CALL init_error_status(status)

    ! Initialize basic state
    state%step%dt_current = config%dt%dt_init
    state%step%dt_previous = config%dt%dt_init
    state%step%dt_proposed = config%dt%dt_init
    state%error%error_current = ZERO
    state%error%error_previous = ZERO
    state%error%error_integral = ZERO
    state%error%error_derivative = ZERO
    state%stats%n_steps = 0_i4
    state%stats%n_rejected = 0_i4
    state%stats%n_consecutive_rejects = 0_i4
    state%history%history_pos = 0_i4

    ! allocate history array
    history_len = 10_i4
    ALLOCATE(state%history%error_history(history_len))
    ALLOCATE(state%history%dt_history(history_len))
    state%history%error_history = ZERO
    state%history%dt_history = config%dt%dt_init

  END SUBROUTINE NM_StepController_Init

  !=============================================================================
  ! MAIN CONTROL INTERFACE
  !=============================================================================

  !> @brief compute new step (main interface)
  !! @details select control strategy and compute new step
  !! @param[in] config controller config
  !! @param[inout] state controller state
  !! @param[in] error_current current error
  !! @param[out] result control result
  !! @param[out] status error status
  SUBROUTINE NM_StepController_Calc_Step(config, state, error_current, &
                                             result, status)
    TYPE(StepController_Config), INTENT(IN) :: config
    TYPE(StepController_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(IN) :: error_current
    TYPE(StepControl_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(PI_Controller_Params) :: pi_params
    TYPE(Predictive_Controller_Params) :: pred_params
    TYPE(AdaptiveGain_Params) :: ag_params

    CALL init_error_status(status)

    ! update current error
    state%error%error_current = error_current

    ! select algorithm by controller type
    SELECT CASE (config%ctrl%controller_type)
    CASE (NM_CTRL_PI)
      pi_params%gain%k_P = 0.7_DP
      pi_params%gain%k_I = 0.4_DP
      CALL NM_PI_Ctrl_Step(config, pi_params, state, result, status)

    CASE (NM_CTRL_PID)
      pi_params%gain%k_P = 0.7_DP
      pi_params%gain%k_I = 0.4_DP
      pi_params%gain%k_D = 0.1_DP
      CALL NM_PID_Ctrl_Step(config, pi_params, state, result, status)

    CASE (NM_CTRL_PREDICTIVE)
      pred_params%prediction_order = 2_i4
      pred_params%trend_weight = 0.5_DP
      CALL NM_Predictive_Ctrl_Step(config, pred_params, state, result, status)

    CASE (NM_CTRL_ADAPTIVE_GAIN)
      ag_params%k_min = 0.1_DP
      ag_params%k_max = 2.0_DP
      ag_params%adapt_rate = 0.1_DP
      ag_params%target_error = 0.5_DP
      CALL NM_AdaptiveGain_Ctrl_Step(config, ag_params, state, result, status)

    CASE DEFAULT
      ! default: use PI control
      pi_params%gain%k_P = 0.7_DP
      pi_params%gain%k_I = 0.4_DP
      CALL NM_PI_Ctrl_Step(config, pi_params, state, result, status)
    END SELECT

    ! apply step limits
    CALL NM_Limit_Step_Size_Advanced(config, result%dt_new)

    ! step smoothing
    IF (config%smooth%enable_smoothing) THEN
      CALL NM_Smooth_Step_Change(config%smooth%smoothing_factor, state%step%dt_current, &
                                  result%dt_new)
    END IF

    ! update state
    state%step%dt_proposed = result%dt_new

  END SUBROUTINE NM_StepController_Calc_Step

  !> @brief update controller state
  !! @param[in] config controller config
  !! @param[inout] state controller state
  !! @param[in] step_accepted step accepted or not
  !! @param[in] dt_used actual step used
  SUBROUTINE NM_StepController_Update(config, state, step_accepted, dt_used)
    TYPE(StepController_Config), INTENT(IN) :: config
    TYPE(StepController_State), INTENT(INOUT) :: state
    LOGICAL, INTENT(IN) :: step_accepted
    REAL(DP), INTENT(IN) :: dt_used

    ! update history
    state%step%dt_previous = state%step%dt_current
    state%step%dt_current = dt_used
    state%error%error_previous = state%error%error_current

    ! update history array
    state%history%history_pos = state%history%history_pos + 1
    IF (state%history%history_pos > SIZE(state%history%error_history)) THEN
      state%history%history_pos = 1_i4
    END IF
    state%history%error_history(state%history%history_pos) = state%error%error_current
    state%history%dt_history(state%history%history_pos) = dt_used

    ! update statistics
    state%stats%n_steps = state%stats%n_steps + 1_i4
    IF (step_accepted) THEN
      state%stats%n_consecutive_rejects = 0_i4
    ELSE
      state%stats%n_rejected = state%stats%n_rejected + 1_i4
      state%stats%n_consecutive_rejects = state%stats%n_consecutive_rejects + 1_i4
    END IF

  END SUBROUTINE NM_StepController_Update

  !=============================================================================
  ! PI CONTROLLER
  !=============================================================================

  !> @brief PI controller step computation
  !! @details PI control formula:
  !!   factor = safety * (TOL/err)^kP * (err_old/err)^kI
  !!   dt_new = dt * factor
  !! @param[in] config controller config
  !! @param[in] pi_params PIparam
  !! @param[inout] state controller state
  !! @param[out] result control result
  !! @param[out] status error status
  SUBROUTINE NM_PI_Ctrl_Step(config, pi_params, state, result, status)
    TYPE(StepController_Config), INTENT(IN) :: config
    TYPE(PI_Controller_Params), INTENT(IN) :: pi_params
    TYPE(StepController_State), INTENT(INOUT) :: state
    TYPE(StepControl_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: factor, err_ratio, err_change
    REAL(DP) :: kP, kI, safety

    CALL init_error_status(status)

    kP = pi_params%gain%k_P
    kI = pi_params%gain%k_I
    safety = pi_params%safety_factor

    ! avoid division by zero
    IF (state%error%error_current < 1.0E-14_DP) THEN
      factor = pi_params%max_factor
      result%dt_new = state%step%dt_current * factor
      result%growth_factor = factor
      result%accept_step = .TRUE.
      result%control_action = 1_i4
      result%message = "PI: Zero error, max growth"
      RETURN
    END IF

    ! proportional (TOL/err)^kP
    err_ratio = ONE / state%error%error_current
    factor = safety * (err_ratio ** kP)

    ! integral (err_old/err)^kI
    IF (state%error%error_previous > 1.0E-14_DP) THEN
      err_change = state%error%error_previous / state%error%error_current
      factor = factor * (err_change ** kI)
    END IF

    ! update error integral
    state%error%error_integral = state%error%error_integral + state%error%error_current

    ! apply limits
    factor = MAX(pi_params%min_factor, MIN(pi_params%max_factor, factor))

    ! compute new step
    result%dt_new = state%step%dt_current * factor
    result%growth_factor = factor

    ! step accept decision
    result%accept_step = (state%error%error_current <= ONE) .OR. &
                         (state%step%dt_current <= config%dt_min * 1.1_DP)

    result%control_action = 1_i4
    WRITE(result%message, '(A,F8.4,A,F8.4)') &
          "PI: factor=", factor, ", err=", state%error%error_current

  END SUBROUTINE NM_PI_Ctrl_Step

  !> @brief PID controller step computation
  !! @details PID control formula:
  !!   factor = safety * (TOL/err)^kP * (err_old/err)^kI * (d_err/dt)^kD
  SUBROUTINE NM_PID_Ctrl_Step(config, pid_params, state, result, status)
    TYPE(StepController_Config), INTENT(IN) :: config
    TYPE(PI_Controller_Params), INTENT(IN) :: pid_params
    TYPE(StepController_State), INTENT(INOUT) :: state
    TYPE(StepControl_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: factor, err_ratio, err_change, err_derivative
    REAL(DP) :: kP, kI, kD, safety

    CALL init_error_status(status)

    kP = pid_params%k_P
    kI = pid_params%k_I
    kD = pid_params%k_D
    safety = pid_params%safety_factor

    IF (state%error%error_current < 1.0E-14_DP) THEN
      factor = pid_params%max_factor
      result%dt_new = state%step%dt_current * factor
      result%growth_factor = factor
      result%accept_step = .TRUE.
      RETURN
    END IF

    ! proportional
    err_ratio = ONE / state%error%error_current
    factor = safety * (err_ratio ** kP)

    ! integral
    IF (state%error%error_previous > 1.0E-14_DP) THEN
      err_change = state%error%error_previous / state%error%error_current
      factor = factor * (err_change ** kI)
    END IF

    ! derivative
    IF (state%step%dt_current > 1.0E-14_DP) THEN
      err_derivative = (state%error%error_current - state%error%error_previous) / state%step%dt_current
      factor = factor * (ABS(err_derivative) ** kD)
    END IF

    ! apply limits
    factor = MAX(pid_params%min_factor, MIN(pid_params%max_factor, factor))

    result%dt_new = state%step%dt_current * factor
    result%growth_factor = factor
    result%accept_step = (state%error%error_current <= ONE)
    result%control_action = 2_i4

  END SUBROUTINE NM_PID_Ctrl_Step

  !=============================================================================
  ! PREDICTIVE CONTROLLER
  !=============================================================================

  !> @brief predictive controller step computation
  !! @details predict next error from trend, adjust step in advance
  !! @param[in] config controller config
  !! @param[in] pred_params prediction params
  !! @param[inout] state controller state
  !! @param[out] result control result
  !! @param[out] status error status
  SUBROUTINE NM_Predictive_Ctrl_Step(config, pred_params, state, result, status)
    TYPE(StepController_Config), INTENT(IN) :: config
    TYPE(Predictive_Controller_Params), INTENT(IN) :: pred_params
    TYPE(StepController_State), INTENT(INOUT) :: state
    TYPE(StepControl_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: predicted_error, trend, acceleration
    REAL(DP) :: factor, safety

    CALL init_error_status(status)

    safety = 0.9_DP

    ! predict error trend
    CALL NM_Predict_Error_Trend(state, pred_params%prediction_order, &
                                 predicted_error, trend, acceleration)

    ! compute step factor from predicted error
    IF (predicted_error > 1.0E-14_DP) THEN
      factor = safety * (ONE / predicted_error) ** 0.2_DP
    ELSE
      factor = 2.0_DP
    END IF

    ! trend-based adjustment
    IF (trend > ZERO) THEN
      ! error growing, more conservative
      factor = factor * (ONE - pred_params%trend_weight * MIN(ONE, trend))
    ELSE
      ! error decreasing, more aggressive
      factor = factor * (ONE + pred_params%trend_weight * MIN(ONE, ABS(trend)))
    END IF

    ! apply limits
    factor = MAX(0.2_DP, MIN(5.0_DP, factor))

    result%dt_new = state%step%dt_current * factor
    result%growth_factor = factor
    result%accept_step = (state%error%error_current <= ONE)
    result%control_action = 3_i4
    WRITE(result%message, '(A,F8.4,A,F8.4)') &
          "Predictive: factor=", factor, ", pred_err=", predicted_error

  END SUBROUTINE NM_Predictive_Ctrl_Step

  !> @brief predict error trend
  !! @details fit error trend from history
  !! @param[in] state controller state
  !! @param[in] order prediction order
  !! @param[out] predicted_error predicted error
  !! @param[out] trend error trend
  !! @param[out] acceleration error acceleration
  SUBROUTINE NM_Predict_Error_Trend(state, order, predicted_error, trend, acceleration)
    TYPE(StepController_State), INTENT(IN) :: state
    INTEGER(i4), INTENT(IN) :: order
    REAL(DP), INTENT(OUT) :: predicted_error, trend, acceleration

    REAL(DP) :: e_curr, e_prev, e_prev2

    e_curr = state%error%error_current
    e_prev = state%error%error_previous

    ! compute first-order trend
    IF (state%step%dt_current > 1.0E-14_DP) THEN
      trend = (e_curr - e_prev) / state%step%dt_current
    ELSE
      trend = ZERO
    END IF

    ! compute second-order trend (acceleration)
    IF (order >= 2 .AND. state%step%dt_previous > 1.0E-14_DP) THEN
      e_prev2 = state%history%error_history(MOD(state%history%history_pos - 2 + &
             SIZE(state%history%error_history), SIZE(state%history%error_history)) + 1)
      acceleration = ((e_curr - e_prev) / state%step%dt_current - &
                     (e_prev - e_prev2) / state%step%dt_previous) / &
                     (HALF * (state%step%dt_current + state%step%dt_previous))
    ELSE
      acceleration = ZERO
    END IF

    ! predict next error (linear or quadratic)
    IF (order >= 2) THEN
      predicted_error = e_curr + trend * state%step%dt_current + &
                        HALF * acceleration * state%step%dt_current**2
    ELSE
      predicted_error = e_curr + trend * state%step%dt_current
    END IF

    ! ensure predicted error positive
    predicted_error = MAX(predicted_error, 1.0E-10_DP)

  END SUBROUTINE NM_Predict_Error_Trend

  !=============================================================================
  ! ADAPTIVE GAIN CONTROLLER
  !=============================================================================

  !> @brief adaptive gain control
  !! @details dynamically adjust gain from error level
  !! @param[in] config controller config
  !! @param[in] ag_params adaptive gain params
  !! @param[inout] state controller state
  !! @param[out] result control result
  !! @param[out] status error status
  SUBROUTINE NM_AdaptiveGain_Ctrl_Step(config, ag_params, state, result, status)
    TYPE(StepController_Config), INTENT(IN) :: config
    TYPE(AdaptiveGain_Params), INTENT(IN) :: ag_params
    TYPE(StepController_State), INTENT(INOUT) :: state
    TYPE(StepControl_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: k_current, error_deviation, adapt_factor
    REAL(DP) :: factor, safety

    CALL init_error_status(status)

    ! compute deviation from target error
    error_deviation = state%error%error_current - ag_params%target_error

    ! adaptive gain adjustment
    IF (state%stats%n_steps == 0_i4) THEN
      k_current = ONE
    ELSE
      adapt_factor = ONE - ag_params%adapt_rate * error_deviation
      k_current = MAX(ag_params%k_min, MIN(ag_params%k_max, &
                    state%error%error_integral * adapt_factor))
    END IF

    ! compute step factor with adaptive gain
    safety = 0.9_DP
    IF (state%error%error_current > 1.0E-14_DP) THEN
      factor = safety * (ONE / state%error%error_current) ** k_current
    ELSE
      factor = 2.0_DP
    END IF

    ! apply limits
    factor = MAX(0.2_DP, MIN(5.0_DP, factor))

    result%dt_new = state%step%dt_current * factor
    result%growth_factor = factor
    result%accept_step = (state%error%error_current <= ONE)
    result%control_action = 5_i4

  END SUBROUTINE NM_AdaptiveGain_Ctrl_Step

  !=============================================================================
  ! STEP SIZE LIMITING AND SMOOTHING
  !=============================================================================

  !> @brief advanced step limit
  !! @details apply max step limit and adjust strategy
  !! @param[in] config controller config
  !! @param[inout] dt step size
  SUBROUTINE NM_Limit_Step_Size_Advanced(config, dt)
    TYPE(StepController_Config), INTENT(IN) :: config
    REAL(DP), INTENT(INOUT) :: dt

    REAL(DP) :: dt_limited

    ! basic limits
    dt_limited = MAX(config%dt_min, MIN(config%dt_max, dt))

    ! apply extra limits by strategy
    SELECT CASE (config%adjustment_strategy)
    CASE (NM_ADJUST_AGGRESSIVE)
      ! aggressive: allow larger change
      dt = dt_limited
    CASE (NM_ADJUST_CONSERVATIVE)
      ! conservative: limit change magnitude
      dt = dt_limited
    CASE (NM_ADJUST_EVENT_DRIVEN)
      ! event-driven: small step near events
      dt = dt_limited
    CASE DEFAULT
      ! standard strategy
      dt = dt_limited
    END SELECT

  END SUBROUTINE NM_Limit_Step_Size_Advanced

  !> @brief step smoothing
  !! @details exponential smoothing to reduce step oscillation
  !!   dt_smooth = alpha * dt_new + (1-alpha) * dt_old
  !! @param[in] alpha smoothing factor
  !! @param[in] dt_old old step
  !! @param[inout] dt_new new step
  SUBROUTINE NM_Smooth_Step_Change(alpha, dt_old, dt_new)
    REAL(DP), INTENT(IN) :: alpha, dt_old
    REAL(DP), INTENT(INOUT) :: dt_new

    dt_new = alpha * dt_new + (ONE - alpha) * dt_old

  END SUBROUTINE NM_Smooth_Step_Change

  !=============================================================================
  ! EVENT HANDLING
  !=============================================================================

  !> @brief check step events
  !! @details detect events that require step adjustment
  !! @param[in] state dynamics state
  !! @param[in] config controller config
  !! @param[out] event detected event
  !! @param[out] status error status
  SUBROUTINE NM_Check_Step_Events(state, config, event, status)
    USE NM_TimeInt_AdaptStep, ONLY: Dynamic_State
    TYPE(Dynamic_State), INTENT(IN) :: state
    TYPE(StepController_Config), INTENT(IN) :: config
    TYPE(TimeStep_Event), INTENT(OUT) :: event
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Initialize event
    event%event_type = 0_i4
    event%event_time = ZERO
    event%event_value = ZERO
    event%is_triggered = .FALSE.

    ! detect velocity direction change (contact/separation)
    ! actual impl should detect more event types

  END SUBROUTINE NM_Check_Step_Events

  !> @brief handle step event
  !! @details adjust step by event type
  !! @param[inout] event  
  !! @param[inout] result control 
  !! @param[out] status error status
  SUBROUTINE NM_Handle_Step_Event(event, result, status)
    TYPE(TimeStep_Event), INTENT(INOUT) :: event
    TYPE(StepControl_Result), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. event%is_triggered) RETURN

    ! adjust by event type
    SELECT CASE (event%event_type)
    CASE (1)  ! contact event
      result%dt_new = result%dt_new * 0.5_DP
      result%message = "Event: Contact detected, reducing step"
    CASE (2)  ! separation event
      result%dt_new = result%dt_new * 0.5_DP
      result%message = "Event: Separation detected, reducing step"
    CASE (3)  ! buckling event
      result%dt_new = result%dt_new * 0.25_DP
      result%message = "Event: Buckling detected, significantly reducing step"
    END SELECT

  END SUBROUTINE NM_Handle_Step_Event

  !=============================================================================
  ! UTILITY FUNCTIONS
  !=============================================================================

  !> @brief compute growth factor
  !! @details standard growth factor from error and order
  !!   factor = safety * (TOL/err)^(1/(order+1))
  !! @param[in] error current error
  !! @param[in] order method order
  !! @param[in] safety safety factor
  !! @return growth factor
  FUNCTION NM_Calc_Growth_Factor(error, order, safety) RESULT(factor)
    REAL(DP), INTENT(IN) :: error, safety
    INTEGER(i4), INTENT(IN) :: order
    REAL(DP) :: factor

    IF (error > 1.0E-14_DP) THEN
      factor = safety * (ONE / error) ** (ONE / (order + 1))
    ELSE
      factor = 5.0_DP
    END IF

  END FUNCTION NM_Calc_Growth_Factor

  !> @brief evaluate control strategy
  !! @details evaluate and possibly adjust strategy from state
  !! @param[in] state controller state
  !! @param[inout] config controller config
  !! @param[out] status error status
  SUBROUTINE NM_Eval_Ctrl_Strategy(state, config, status)
    TYPE(StepController_State), INTENT(IN) :: state
    TYPE(StepController_Config), INTENT(INOUT) :: config
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! if too many rejects, switch to conservative
    IF (state%stats%n_consecutive_rejects > 5_i4) THEN
      config%adjustment_strategy = NM_ADJUST_CONSERVATIVE
    ELSE IF (state%stats%n_consecutive_rejects == 0_i4 .AND. &
             state%stats%n_steps > 100_i4) THEN
      ! if stable long, try more aggressive
      config%adjustment_strategy = NM_ADJUST_STANDARD
    END IF

  END SUBROUTINE NM_Eval_Ctrl_Strategy

END MODULE NM_TimeInt_StepCtrl