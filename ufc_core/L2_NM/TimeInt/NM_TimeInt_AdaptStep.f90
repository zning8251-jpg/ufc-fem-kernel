!===============================================================================
! MODULE: NM_TimeInt_AdaptStep
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — Adaptive time-step control (HHT/Generalized-alpha/Newmark)
! BRIEF:  Step-size adjustment, error estimation, event-driven dispatch
!===============================================================================

MODULE NM_TimeInt_AdaptStep
!> Status: Production | Last verified: 2026-03-01
!> Theory: Adaptive time stepping | Ref: Hairer&Wanner(1996)
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, QUARTER, THIRD
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief time integration method type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TimeIntHHT = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TIMEINT_GENERALIZED_ALPHA = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TimeIntNewmark = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TIMEINT_BOSSAK = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TIMEINT_WILSON_THETA = 5

  !> @brief step control strategy enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_STEP_CTRL_FIXED = 0
  INTEGER(i4), PARAMETER, PUBLIC :: NM_STEP_CTRL_ADAPTIVE = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_STEP_CTRL_EVENT_DRIVEN = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_STEP_CTRL_PREDICTIVE = 3

  !> @brief step adjust state enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_STEP_ACCEPTED = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_STEP_REJECTED = 0
  INTEGER(i4), PARAMETER, PUBLIC :: NM_STEP_FAILED = -1

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief HHT-alpha method params
    TYPE, PUBLIC :: HHT_Params_Newmark
    REAL(DP) :: alpha = -0.05_DP           !< HHT alpha [-1/3, 0]
    REAL(DP) :: beta = 0.275625_DP         !< Newmark β = (1-α)²/4
    REAL(DP) :: gamma = 0.55_DP            !< Newmark γ = 1/2 - α
  END TYPE HHT_Params_Newmark

  TYPE, PUBLIC :: HHT_Params_Spectral
    REAL(DP) :: rho_infinity = 0.9_DP      !< high-freq dissipation factor
  END TYPE HHT_Params_Spectral

  TYPE, PUBLIC :: HHT_Params_Time
    REAL(DP) :: time_step = 0.01_DP        !< time step Δt [s]
    REAL(DP) :: total_time = 1.0_DP        !< total time[s]
  END TYPE HHT_Params_Time

  TYPE, PUBLIC :: HHT_Params
    TYPE(HHT_Params_Newmark)  :: newmark
    TYPE(HHT_Params_Spectral) :: spectral
    TYPE(HHT_Params_Time)     :: time
  END TYPE HHT_Params

  !> @brief Generalized-alpha method params
    TYPE, PUBLIC :: GenAlpha_Params_Coeff
    REAL(DP) :: alpha_m = 0.0_DP           !< mass alpha_m
    REAL(DP) :: alpha_f = 0.0_DP           !< force alpha_f
    REAL(DP) :: beta = 0.25_DP             !< Newmark beta
    REAL(DP) :: gamma = 0.5_DP             !< Newmark gamma
  END TYPE GenAlpha_Params_Coeff

  TYPE, PUBLIC :: GenAlpha_Params_Spectral
    REAL(DP) :: rho_infinity = 1.0_DP      !< high-freq dissipation factor ρ
  END TYPE GenAlpha_Params_Spectral

  TYPE, PUBLIC :: GenAlpha_Params_Time
    REAL(DP) :: time_step = 0.01_DP        !< time step Δt [s]
    REAL(DP) :: total_time = 1.0_DP        !< total time[s]
  END TYPE GenAlpha_Params_Time

  TYPE, PUBLIC :: GenAlpha_Params
    TYPE(GenAlpha_Params_Coeff)    :: coeff
    TYPE(GenAlpha_Params_Spectral) :: spectral
    TYPE(GenAlpha_Params_Time)     :: time
  END TYPE GenAlpha_Params

  !> @brief Newmark-beta method params
  TYPE, PUBLIC :: Newmark_Params
    REAL(DP) :: beta = 0.25_DP             !< Newmark beta
    REAL(DP) :: gamma = 0.5_DP             !< Newmark gamma
    REAL(DP) :: time_step = 0.01_DP        !< time step Δt [s]
    REAL(DP) :: total_time = 1.0_DP        !< total time[s]
    LOGICAL :: implicit = .TRUE.           !< implicit/explicit flag
  END TYPE Newmark_Params

  !> @brief adaptive step control params
  TYPE, PUBLIC :: AdaptiveStep_Params_Time
    REAL(DP) :: t_start = 0.0_DP           !< start time
    REAL(DP) :: t_end = 1.0_DP             !< end time
  END TYPE AdaptiveStep_Params_Time

  TYPE, PUBLIC :: AdaptiveStep_Params_Step
    REAL(DP) :: dt_init = 0.01_DP          !< initial step size
    REAL(DP) :: dt_min = 1.0E-10_DP        !< min step
    REAL(DP) :: dt_max = 0.1_DP            !< max step
  END TYPE AdaptiveStep_Params_Step

  TYPE, PUBLIC :: AdaptiveStep_Params_Tol
    REAL(DP) :: rtol = 1.0E-6_DP           !< relative tolerance
    REAL(DP) :: atol = 1.0E-8_DP           !< absolute tolerance
  END TYPE AdaptiveStep_Params_Tol

  TYPE, PUBLIC :: AdaptiveStep_Params_PI
    REAL(DP) :: safety_factor = 0.9_DP     !< safety factor
    REAL(DP) :: max_step_ratio = 5.0_DP    !< max step growth ratio
    REAL(DP) :: min_step_ratio = 0.2_DP    !< min step reduction ratio
    REAL(DP) :: pi_kp = 0.7_DP             !< PI controller Kp
    REAL(DP) :: pi_ki = 0.4_DP             !< PI controller Ki
  END TYPE AdaptiveStep_Params_PI

  TYPE, PUBLIC :: AdaptiveStep_Params_Ctrl
    INTEGER(i4) :: control_strategy = NM_STEP_CTRL_ADAPTIVE
    INTEGER(i4) :: max_rejections = 10_i4  !< max consecutive rejections
    INTEGER(i4) :: max_steps = 100000_i4   !< max time steps
  END TYPE AdaptiveStep_Params_Ctrl

  TYPE, PUBLIC :: AdaptiveStep_Params_Event
    LOGICAL :: enable_event_detection = .TRUE.
    REAL(DP) :: event_tolerance = 1.0E-8_DP
  END TYPE AdaptiveStep_Params_Event

  TYPE, PUBLIC :: AdaptiveStep_Params_IO
    LOGICAL :: verbose = .FALSE.
    INTEGER(i4) :: output_interval = 100_i4
  END TYPE AdaptiveStep_Params_IO

  TYPE, PUBLIC :: AdaptiveStep_Params
    TYPE(AdaptiveStep_Params_Time)  :: time
    TYPE(AdaptiveStep_Params_Step)  :: step
    TYPE(AdaptiveStep_Params_Tol)   :: tol
    TYPE(AdaptiveStep_Params_PI)    :: pi
    TYPE(AdaptiveStep_Params_Ctrl)  :: ctrl
    TYPE(AdaptiveStep_Params_Event) :: event
    TYPE(AdaptiveStep_Params_IO)    :: io
  END TYPE AdaptiveStep_Params

  !> @brief dynamics system state
  TYPE, PUBLIC :: Dynamic_State
    REAL(DP), ALLOCATABLE :: displacement(:)    !< displacement u(t) [m]
    REAL(DP), ALLOCATABLE :: velocity(:)        !< velocity v(t) [m/s]
    REAL(DP), ALLOCATABLE :: acceleration(:)    !< acceleration a(t) [m/s^2]
    REAL(DP) :: current_time = 0.0_DP           !< current time [s]
    INTEGER(i4) :: current_step = 0_i4          !< current step
    LOGICAL :: converged = .FALSE.              !< converged
  END TYPE Dynamic_State

  !> @brief adaptive time-step state
  TYPE, PUBLIC :: AdaptiveStep_State_Step
    REAL(DP) :: dt_current = 0.0_DP             !< current step size
    REAL(DP) :: dt_previous = 0.0_DP            !< previous step size
  END TYPE AdaptiveStep_State_Step

  TYPE, PUBLIC :: AdaptiveStep_State_Error
    REAL(DP) :: error_current = 0.0_DP          !< current error
    REAL(DP) :: error_previous = 0.0_DP         !< previous step error
  END TYPE AdaptiveStep_State_Error

  TYPE, PUBLIC :: AdaptiveStep_State_Stats
    INTEGER(i4) :: n_steps = 0_i4               !< total steps
    INTEGER(i4) :: n_accepted = 0_i4            !< accepted steps
    INTEGER(i4) :: n_rejected = 0_i4            !< rejected steps
    INTEGER(i4) :: n_consecutive_rejects = 0_i4 !< consecutive rejections
  END TYPE AdaptiveStep_State_Stats

  TYPE, PUBLIC :: AdaptiveStep_State_Event
    LOGICAL :: event_triggered = .FALSE.
    REAL(DP) :: event_time = 0.0_DP
    INTEGER(i4) :: event_type = 0_i4
  END TYPE AdaptiveStep_State_Event

  TYPE, PUBLIC :: AdaptiveStep_State_History
    REAL(DP), ALLOCATABLE :: error_history(:)
    REAL(DP), ALLOCATABLE :: dt_history(:)
    INTEGER(i4) :: history_size = 0_i4
    INTEGER(i4) :: history_pos = 0_i4
  END TYPE AdaptiveStep_State_History

  TYPE, PUBLIC :: AdaptiveStep_State
    TYPE(AdaptiveStep_State_Step)    :: step
    TYPE(AdaptiveStep_State_Error)   :: error
    TYPE(AdaptiveStep_State_Stats)   :: stats
    TYPE(AdaptiveStep_State_Event)   :: event
    TYPE(AdaptiveStep_State_History) :: history
  END TYPE AdaptiveStep_State

  !> @brief time integration result
  TYPE, PUBLIC :: TimeIntegration_Result
    REAL(DP), ALLOCATABLE :: displacement_history(:,:)
    REAL(DP), ALLOCATABLE :: velocity_history(:,:)
    REAL(DP), ALLOCATABLE :: acceleration_history(:,:)
    REAL(DP), ALLOCATABLE :: time_history(:)
    INTEGER(i4) :: n_saved_steps = 0_i4
  END TYPE TimeIntegration_Result

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main solve interface
  PUBLIC :: NM_Adaptive_HHT_Solv
  PUBLIC :: NM_Adaptive_GenAlpha_Solv
  PUBLIC :: NM_Adaptive_Newmark_Solv
  PUBLIC :: NM_Adaptive_TimeStep_Solv
  
  ! Initialize interface
  PUBLIC :: NM_HHT_Init_Params
  PUBLIC :: NM_GenAlpha_Init_Params
  PUBLIC :: NM_AdaptiveStep_Init_State
  
  ! step control interface
  PUBLIC :: NM_Calc_Adaptive_Step_Size
  PUBLIC :: NM_PI_Ctrl_Step_Size
  PUBLIC :: NM_Limit_Step_Size
  
  ! single-step integration interface
  PUBLIC :: NM_HHT_Single_Step_Adaptive
  PUBLIC :: NM_GenAlpha_Single_Step_Adaptive
  PUBLIC :: NM_Newmark_Single_Step_Adaptive
  
  ! utils
  PUBLIC :: NM_Update_Dynamic_State
  PUBLIC :: NM_Calc_Effective_Stiff
  PUBLIC :: NM_Calc_Effective_Force
  
  ! Extended Adaptive Step API (scope 2300-2399)
  PUBLIC :: NM_Adaptive_OptimizeStrategy, NM_Adaptive_GetStepStatistics
  PUBLIC :: NM_Adaptive_GetControlStatistics
  ! NM_Adaptive_EstimateOptimalStep: TODO stub

  !=============================================================================
  ! CONSTANTS
  !=============================================================================
  REAL(DP), PARAMETER :: EPS_TIME = 1.0E-14_DP
  REAL(DP), PARAMETER :: MAX_ERROR_GROWTH = 10.0_DP

CONTAINS

  SUBROUTINE Check_Events(state, params, adaptive_state)
    TYPE(Dynamic_State), INTENT(IN) :: state
    TYPE(AdaptiveStep_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_State), INTENT(INOUT) :: adaptive_state

    ! simplified: velocity direction change as event
    ! actual impl should detect contact/separation/buckling
    adaptive_state%event%event_triggered = .FALSE.

  END SUBROUTINE Check_Events

  SUBROUTINE Cleanup_Adaptive_State(state)
    TYPE(AdaptiveStep_State), INTENT(INOUT) :: state

    IF (ALLOCATED(state%history%error_history)) DEALLOCATE(state%history%error_history)
    IF (ALLOCATED(state%history%dt_history)) DEALLOCATE(state%history%dt_history)

  END SUBROUTINE Cleanup_Adaptive_State

  SUBROUTINE Handle_Event(state, adaptive_state)
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    TYPE(AdaptiveStep_State), INTENT(INOUT) :: adaptive_state

    ! simplified impl
    adaptive_state%event%event_triggered = .FALSE.

  END SUBROUTINE Handle_Event

  SUBROUTINE Init_Res_Storage(result, n_dof, max_steps)
    TYPE(TimeIntegration_Result), INTENT(OUT) :: result
    INTEGER(i4), INTENT(IN) :: n_dof, max_steps

    ALLOCATE(result%displacement_history(n_dof, max_steps))
    ALLOCATE(result%velocity_history(n_dof, max_steps))
    ALLOCATE(result%acceleration_history(n_dof, max_steps))
    ALLOCATE(result%time_history(max_steps))

    result%displacement_history = ZERO
    result%velocity_history = ZERO
    result%acceleration_history = ZERO
    result%time_history = ZERO
    result%n_saved_steps = 0_i4

  END SUBROUTINE Init_Res_Storage

  SUBROUTINE NM_Adaptive_GetControlStatistics(adaptive_state, params, stats, status)
    TYPE(AdaptiveStep_State), INTENT(IN) :: adaptive_state
    TYPE(AdaptiveStep_Params), INTENT(IN) :: params
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=16) :: strategy_name
    REAL(DP) :: efficiency
    
    CALL init_error_status(status)
    
    SELECT CASE (params%ctrl%control_strategy)
    CASE (NM_STEP_CTRL_FIXED)
      strategy_name = "Fixed"
    CASE (NM_STEP_CTRL_ADAPTIVE)
      strategy_name = "Adaptive"
    CASE (NM_STEP_CTRL_EVENT_DRIVEN)
      strategy_name = "EventDriven"
    CASE (NM_STEP_CTRL_PREDICTIVE)
      strategy_name = "Predictive"
    CASE DEFAULT
      strategy_name = "Unknown"
    END SELECT
    
    IF (adaptive_state%stats%n_steps > 0) THEN
      efficiency = REAL(adaptive_state%stats%n_accepted, DP) / REAL(adaptive_state%stats%n_steps, DP)
    ELSE
      efficiency = 0.0_DP
    END IF
    
    WRITE(stats, '(A,A,A,F6.2,A,ES10.3,A,ES10.3)') &
      'Ctrl Statistics (', TRIM(strategy_name), &
      '): efficiency=', efficiency * 100.0_DP, &
      '%, current_dt=', adaptive_state%step%dt_current, &
      ', current_error=', adaptive_state%error%error_current
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_Adaptive_GetControlStatistics

  SUBROUTINE NM_Adaptive_GetStepStatistics(adaptive_state, stats, status)
    TYPE(AdaptiveStep_State), INTENT(IN) :: adaptive_state
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(DP) :: acceptance_rate
    
    CALL init_error_status(status)
    
    IF (adaptive_state%stats%n_steps > 0) THEN
      acceptance_rate = REAL(adaptive_state%stats%n_accepted, DP) / REAL(adaptive_state%stats%n_steps, DP)
    ELSE
      acceptance_rate = 0.0_DP
    END IF
    
    WRITE(stats, '(A,I0,A,I0,A,I0,A,ES10.3,A,ES10.3)') &
      'Adaptive Step Statistics: total_steps=', adaptive_state%stats%n_steps, &
      ', accepted=', adaptive_state%stats%n_accepted, &
      ', rejected=', adaptive_state%stats%n_rejected, &
      ', acceptance_rate=', acceptance_rate, &
      ', current_dt=', adaptive_state%step%dt_current
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_Adaptive_GetStepStatistics

  SUBROUTINE NM_Adaptive_GenAlpha_Solv(params, adaptive_params, M, C, K, F, &
                                         state, result, status)
    TYPE(GenAlpha_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_Params), INTENT(IN) :: adaptive_params
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:), K(:,:), F(:,:)
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    TYPE(TimeIntegration_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(AdaptiveStep_State) :: adaptive_state
    REAL(DP), ALLOCATABLE :: K_eff(:,:), F_eff(:), du(:)
    REAL(DP), ALLOCATABLE :: F_n(:), F_n1(:)
    REAL(DP) :: dt, t, error_est
    INTEGER(i4) :: n_dof, max_steps, step
    LOGICAL :: step_accepted, finished

    CALL init_error_status(status)

    n_dof = SIZE(state%displacement)
    max_steps = adaptive_params%ctrl%max_steps

    ! Initialize adaptive state
    CALL NM_AdaptiveStep_Init_State(adaptive_params, n_dof, adaptive_state)
    adaptive_state%step%dt_current = adaptive_params%step%dt_init
    dt = adaptive_params%step%dt_init
    t = adaptive_params%time%t_start

    ! allocate work arrays
    ALLOCATE(K_eff(n_dof, n_dof), F_eff(n_dof), du(n_dof))
    ALLOCATE(F_n(n_dof), F_n1(n_dof))

    ! Initialize result storage
    CALL Init_Res_Storage(result, n_dof, max_steps)
    CALL Save_State_To_Res(state, result, 1)

    step = 0
    finished = .FALSE.

    ! main time-stepping loop
    DO WHILE (.NOT. finished .AND. step < max_steps)
      step = step + 1
      state%current_step = step

      IF (t >= adaptive_params%time%t_end - EPS_TIME) THEN
        finished = .TRUE.
        EXIT
      END IF

      IF (t + dt > adaptive_params%time%t_end) THEN
        dt = adaptive_params%time%t_end - t
      END IF

      F_n1 = F(:, MIN(step, SIZE(F, 2)))
      IF (step > 1) THEN
        F_n = F(:, MIN(step-1, SIZE(F, 2)))
      ELSE
        F_n = ZERO
      END IF

      ! Generalized-alpha adaptive single step
      CALL NM_GenAlpha_Single_Step_Adaptive(params, adaptive_params, M, C, K, &
                                             F_n, F_n1, dt, state, K_eff, F_eff, du, &
                                             error_est, step_accepted, status)

      IF (status%status_code /= IF_STATUS_OK) THEN
        IF (adaptive_state%stats%n_consecutive_rejects < adaptive_params%ctrl%max_rejections) THEN
          dt = dt * 0.5_DP
          dt = MAX(dt, adaptive_params%step%dt_min)
          step = step - 1
          adaptive_state%stats%n_consecutive_rejects = adaptive_state%stats%n_consecutive_rejects + 1
          CYCLE
        ELSE
          status%status_code = IF_STATUS_ERROR
          status%message = "GenAlpha adaptive solve failed: max rejections exceeded"
          EXIT
        END IF
      END IF

      IF (step_accepted) THEN
        t = t + dt
        state%current_time = t
        adaptive_state%stats%n_accepted = adaptive_state%stats%n_accepted + 1
        adaptive_state%stats%n_consecutive_rejects = 0

        IF (MOD(step, adaptive_params%io%output_interval) == 0) THEN
          CALL Save_State_To_Res(state, result, &
               adaptive_state%stats%n_accepted / adaptive_params%io%output_interval + 1)
        END IF

        adaptive_state%error%error_current = error_est
        CALL NM_Calc_Adaptive_Step_Size(adaptive_params, adaptive_state, dt)
        adaptive_state%step%dt_previous = adaptive_state%step%dt_current
        adaptive_state%step%dt_current = dt
        adaptive_state%error%error_previous = error_est

        IF (adaptive_params%io%verbose .AND. MOD(step, adaptive_params%io%output_interval) == 0) THEN
          PRINT '(A,I8,A,F12.6,A,ES12.4,A,ES12.4)', &
                "GenAlpha Step ", step, ": t=", t, &
                " dt=", dt, " err=", error_est
        END IF
      ELSE
        adaptive_state%stats%n_rejected = adaptive_state%stats%n_rejected + 1
        adaptive_state%stats%n_consecutive_rejects = adaptive_state%stats%n_consecutive_rejects + 1

        dt = dt * 0.5_DP
        dt = MAX(dt, adaptive_params%step%dt_min)
        step = step - 1

        IF (adaptive_params%io%verbose) THEN
          PRINT '(A,I8,A,ES12.4)', "GenAlpha Step rejected: ", step, &
                ", new dt=", dt
        END IF
      END IF

      adaptive_state%stats%n_steps = step
    END DO

    result%n_saved_steps = adaptive_state%stats%n_accepted / adaptive_params%io%output_interval + 1

    IF (adaptive_params%io%verbose) THEN
      PRINT '(A,I8,A,I8,A,I8)', "GenAlpha Adaptive Solve completed: ", &
            adaptive_state%stats%n_accepted, " accepted, ", &
            adaptive_state%stats%n_rejected, " rejected"
    END IF

    DEALLOCATE(K_eff, F_eff, du, F_n, F_n1)
    CALL Cleanup_Adaptive_State(adaptive_state)

    IF (status%status_code == IF_STATUS_OK .AND. .NOT. finished) THEN
      status%status_code = IF_STATUS_WARN
      status%message = "GenAlpha adaptive solve: max steps reached"
    END IF

  END SUBROUTINE NM_Adaptive_GenAlpha_Solv

  SUBROUTINE NM_Adaptive_HHT_Solv(params, adaptive_params, M, C, K, F, &
                                    state, result, status)
    TYPE(HHT_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_Params), INTENT(IN) :: adaptive_params
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:), K(:,:), F(:,:)
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    TYPE(TimeIntegration_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(AdaptiveStep_State) :: adaptive_state
    REAL(DP), ALLOCATABLE :: K_eff(:,:), F_eff(:), du(:)
    REAL(DP), ALLOCATABLE :: F_n(:), F_n1(:)
    REAL(DP) :: dt, t, error_est
    INTEGER(i4) :: n_dof, max_steps, step
    LOGICAL :: step_accepted, finished

    CALL init_error_status(status)

    n_dof = SIZE(state%displacement)
    max_steps = adaptive_params%ctrl%max_steps

    ! Initialize adaptive state
    CALL NM_AdaptiveStep_Init_State(adaptive_params, n_dof, adaptive_state)
    adaptive_state%step%dt_current = adaptive_params%step%dt_init
    dt = adaptive_params%step%dt_init
    t = adaptive_params%time%t_start

    ! allocate work arrays
    ALLOCATE(K_eff(n_dof, n_dof), F_eff(n_dof), du(n_dof))
    ALLOCATE(F_n(n_dof), F_n1(n_dof))

    ! Initialize result storage
    CALL Init_Res_Storage(result, n_dof, max_steps)
    CALL Save_State_To_Res(state, result, 1)

    step = 0
    finished = .FALSE.

    ! main time-stepping loop
    DO WHILE (.NOT. finished .AND. step < max_steps)
      step = step + 1
      state%current_step = step

      ! check if reached end time
      IF (t >= adaptive_params%time%t_end - EPS_TIME) THEN
        finished = .TRUE.
        EXIT
      END IF

      ! adjust last step size
      IF (t + dt > adaptive_params%time%t_end) THEN
        dt = adaptive_params%time%t_end - t
      END IF

      ! get current and previous external load
      F_n1 = F(:, MIN(step, SIZE(F, 2)))
      IF (step > 1) THEN
        F_n = F(:, MIN(step-1, SIZE(F, 2)))
      ELSE
        F_n = ZERO
      END IF

      ! HHT adaptive single step
      CALL NM_HHT_Single_Step_Adaptive(params, adaptive_params, M, C, K, &
                                        F_n, F_n1, dt, state, K_eff, F_eff, du, &
                                        error_est, step_accepted, status)

      IF (status%status_code /= IF_STATUS_OK) THEN
        ! solve failed, try smaller step
        IF (adaptive_state%stats%n_consecutive_rejects < adaptive_params%ctrl%max_rejections) THEN
          dt = dt * 0.5_DP
          dt = MAX(dt, adaptive_params%step%dt_min)
          step = step - 1
          adaptive_state%stats%n_consecutive_rejects = adaptive_state%stats%n_consecutive_rejects + 1
          CYCLE
        ELSE
          status%status_code = IF_STATUS_ERROR
          status%message = "HHT adaptive solve failed: max rejections exceeded"
          EXIT
        END IF
      END IF

      ! step accept/reject decision
      IF (step_accepted) THEN
        ! accept step, update state
        t = t + dt
        state%current_time = t
        adaptive_state%stats%n_accepted = adaptive_state%stats%n_accepted + 1
        adaptive_state%stats%n_consecutive_rejects = 0

        ! save result
        IF (MOD(step, adaptive_params%io%output_interval) == 0) THEN
          CALL Save_State_To_Res(state, result, &
               adaptive_state%stats%n_accepted / adaptive_params%io%output_interval + 1)
        END IF

        ! compute next step size
        adaptive_state%error%error_current = error_est
        CALL NM_Calc_Adaptive_Step_Size(adaptive_params, adaptive_state, dt)
        adaptive_state%step%dt_previous = adaptive_state%step%dt_current
        adaptive_state%step%dt_current = dt
        adaptive_state%error%error_previous = error_est

        IF (adaptive_params%io%verbose .AND. MOD(step, adaptive_params%io%output_interval) == 0) THEN
          PRINT '(A,I8,A,F12.6,A,ES12.4,A,ES12.4)', &
                "HHT Step ", step, ": t=", t, &
                " dt=", dt, " err=", error_est
        END IF
      ELSE
        ! reject step, reduce and retry
        adaptive_state%stats%n_rejected = adaptive_state%stats%n_rejected + 1
        adaptive_state%stats%n_consecutive_rejects = adaptive_state%stats%n_consecutive_rejects + 1

        dt = dt * 0.5_DP
        dt = MAX(dt, adaptive_params%step%dt_min)
        step = step - 1

        IF (adaptive_params%io%verbose) THEN
          PRINT '(A,I8,A,ES12.4)', "HHT Step rejected: ", step, &
                ", new dt=", dt
        END IF
      END IF

      ! check events
      IF (adaptive_params%event%enable_event_detection) THEN
        CALL Check_Events(state, adaptive_params, adaptive_state)
        IF (adaptive_state%event%event_triggered) THEN
          CALL Handle_Event(state, adaptive_state)
        END IF
      END IF

      adaptive_state%stats%n_steps = step
    END DO

    ! finalize statistics
    result%n_saved_steps = adaptive_state%stats%n_accepted / adaptive_params%io%output_interval + 1

    IF (adaptive_params%io%verbose) THEN
      PRINT '(A,I8,A,I8,A,I8)', "HHT Adaptive Solve completed: ", &
            adaptive_state%stats%n_accepted, " accepted, ", &
            adaptive_state%stats%n_rejected, " rejected"
    END IF

    ! cleanup
    DEALLOCATE(K_eff, F_eff, du, F_n, F_n1)
    CALL Cleanup_Adaptive_State(adaptive_state)

    IF (status%status_code == IF_STATUS_OK .AND. .NOT. finished) THEN
      status%status_code = IF_STATUS_WARN
      status%message = "HHT adaptive solve: max steps reached"
    END IF

  END SUBROUTINE NM_Adaptive_HHT_Solv

  SUBROUTINE NM_Adaptive_Newmark_Solv(params, adaptive_params, M, C, K, F, &
                                        state, result, status)
    TYPE(Newmark_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_Params), INTENT(IN) :: adaptive_params
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:), K(:,:), F(:,:)
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    TYPE(TimeIntegration_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(AdaptiveStep_State) :: adaptive_state
    REAL(DP), ALLOCATABLE :: K_eff(:,:), F_eff(:), du(:)
    REAL(DP) :: dt, t, error_est
    INTEGER(i4) :: n_dof, max_steps, step
    LOGICAL :: step_accepted, finished

    CALL init_error_status(status)

    n_dof = SIZE(state%displacement)
    max_steps = adaptive_params%ctrl%max_steps

    CALL NM_AdaptiveStep_Init_State(adaptive_params, n_dof, adaptive_state)
    adaptive_state%step%dt_current = adaptive_params%step%dt_init
    dt = adaptive_params%step%dt_init
    t = adaptive_params%time%t_start

    ALLOCATE(K_eff(n_dof, n_dof), F_eff(n_dof), du(n_dof))

    CALL Init_Res_Storage(result, n_dof, max_steps)
    CALL Save_State_To_Res(state, result, 1)

    step = 0
    finished = .FALSE.

    DO WHILE (.NOT. finished .AND. step < max_steps)
      step = step + 1
      state%current_step = step

      IF (t >= adaptive_params%time%t_end - EPS_TIME) THEN
        finished = .TRUE.
        EXIT
      END IF

      IF (t + dt > adaptive_params%time%t_end) THEN
        dt = adaptive_params%time%t_end - t
      END IF

      CALL NM_Newmark_Single_Step_Adaptive(params, adaptive_params, M, C, K, &
                                            F(:, MIN(step, SIZE(F, 2))), dt, state, &
                                            K_eff, F_eff, du, error_est, step_accepted, status)

      IF (status%status_code /= IF_STATUS_OK) THEN
        IF (adaptive_state%stats%n_consecutive_rejects < adaptive_params%ctrl%max_rejections) THEN
          dt = dt * 0.5_DP
          dt = MAX(dt, adaptive_params%step%dt_min)
          step = step - 1
          adaptive_state%stats%n_consecutive_rejects = adaptive_state%stats%n_consecutive_rejects + 1
          CYCLE
        ELSE
          status%status_code = IF_STATUS_ERROR
          status%message = "Newmark adaptive solve failed"
          EXIT
        END IF
      END IF

      IF (step_accepted) THEN
        t = t + dt
        state%current_time = t
        adaptive_state%stats%n_accepted = adaptive_state%stats%n_accepted + 1
        adaptive_state%stats%n_consecutive_rejects = 0

        IF (MOD(step, adaptive_params%io%output_interval) == 0) THEN
          CALL Save_State_To_Res(state, result, &
               adaptive_state%stats%n_accepted / adaptive_params%io%output_interval + 1)
        END IF

        adaptive_state%error%error_current = error_est
        CALL NM_Calc_Adaptive_Step_Size(adaptive_params, adaptive_state, dt)
        adaptive_state%step%dt_previous = adaptive_state%step%dt_current
        adaptive_state%step%dt_current = dt
        adaptive_state%error%error_previous = error_est
      ELSE
        adaptive_state%stats%n_rejected = adaptive_state%stats%n_rejected + 1
        adaptive_state%stats%n_consecutive_rejects = adaptive_state%stats%n_consecutive_rejects + 1
        dt = dt * 0.5_DP
        dt = MAX(dt, adaptive_params%step%dt_min)
        step = step - 1
      END IF

      adaptive_state%stats%n_steps = step
    END DO

    result%n_saved_steps = adaptive_state%stats%n_accepted / adaptive_params%io%output_interval + 1

    DEALLOCATE(K_eff, F_eff, du)
    CALL Cleanup_Adaptive_State(adaptive_state)

  END SUBROUTINE NM_Adaptive_Newmark_Solv

  SUBROUTINE NM_Adaptive_OptimizeStrategy(error_history, step_history, num_steps, &
                                          optimal_strategy, status)
    REAL(DP), INTENT(IN) :: error_history(:), step_history(:)
    INTEGER(i4), INTENT(IN) :: num_steps
    INTEGER(i4), INTENT(OUT) :: optimal_strategy
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(DP) :: avg_error, error_variance, step_variance
    
    CALL init_error_status(status)
    
    IF (num_steps < 2) THEN
      optimal_strategy = NM_STEP_CTRL_ADAPTIVE
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Compute statistics
    avg_error = SUM(error_history(1:num_steps)) / REAL(num_steps, DP)
    error_variance = SUM((error_history(1:num_steps) - avg_error)**2) / REAL(num_steps, DP)
    step_variance = SUM((step_history(1:num_steps) - SUM(step_history(1:num_steps))/REAL(num_steps,DP))**2) / REAL(num_steps, DP)
    
    ! Heuristic strategy selection
    IF (error_variance > avg_error * 0.5_DP) THEN
      ! High error variance: use adaptive control
      optimal_strategy = NM_STEP_CTRL_ADAPTIVE
    ELSE IF (step_variance > 0.1_DP) THEN
      ! High step size variance: use predictive control
      optimal_strategy = NM_STEP_CTRL_PREDICTIVE
    ELSE
      ! Stable: use fixed or adaptive
      optimal_strategy = NM_STEP_CTRL_ADAPTIVE
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_Adaptive_OptimizeStrategy

  SUBROUTINE NM_Adaptive_TimeStep_Solv(method_type, method_params, adaptive_params, &
                                         M, C, K, F, state, result, status)
    INTEGER(i4), INTENT(IN) :: method_type
    CLASS(*), INTENT(IN) :: method_params
    TYPE(AdaptiveStep_Params), INTENT(IN) :: adaptive_params
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:), K(:,:), F(:,:)
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    TYPE(TimeIntegration_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (method_type)
    CASE (NM_TimeIntHHT)
      SELECT TYPE (params => method_params)
      TYPE IS (HHT_Params)
        CALL NM_Adaptive_HHT_Solv(params, adaptive_params, M, C, K, F, &
                                    state, result, status)
      CLASS DEFAULT
        status%status_code = IF_STATUS_INVALID
        status%message = "Invalid HHT params type"
      END SELECT

    CASE (NM_TIMEINT_GENERALIZED_ALPHA)
      SELECT TYPE (params => method_params)
      TYPE IS (GenAlpha_Params)
        CALL NM_Adaptive_GenAlpha_Solv(params, adaptive_params, M, C, K, F, &
                                         state, result, status)
      CLASS DEFAULT
        status%status_code = IF_STATUS_INVALID
        status%message = "Invalid GenAlpha params type"
      END SELECT

    CASE (NM_TimeIntNewmark)
      SELECT TYPE (params => method_params)
      TYPE IS (Newmark_Params)
        CALL NM_Adaptive_Newmark_Solv(params, adaptive_params, M, C, K, F, &
                                        state, result, status)
      CLASS DEFAULT
        status%status_code = IF_STATUS_INVALID
        status%message = "Invalid Newmark params type"
      END SELECT

    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = "Unknown time integration method"
    END SELECT

  END SUBROUTINE NM_Adaptive_TimeStep_Solv

  SUBROUTINE NM_AdaptiveStep_Init_State(params, n_dof, state)
    TYPE(AdaptiveStep_Params), INTENT(IN) :: params
    INTEGER(i4), INTENT(IN) :: n_dof
    TYPE(AdaptiveStep_State), INTENT(OUT) :: state

    state%dt_current = params%step%dt_init
    state%dt_previous = params%step%dt_init
    state%error_current = ZERO
    state%error_previous = ZERO
    state%n_steps = 0_i4
    state%n_accepted = 0_i4
    state%n_rejected = 0_i4
    state%n_consecutive_rejects = 0_i4
    state%event_triggered = .FALSE.
    state%event_time = ZERO
    state%event_type = 0_i4

    ! allocate history arrays
    state%history_size = 10_i4
    ALLOCATE(state%history%error_history(state%history_size))
    ALLOCATE(state%history%dt_history(state%history_size))
    state%history%error_history = ZERO
    state%history%dt_history = ZERO
    state%history_pos = 0_i4

  END SUBROUTINE NM_AdaptiveStep_Init_State

  SUBROUTINE NM_Calc_Adaptive_Step_Size(params, state, dt_new)
    TYPE(AdaptiveStep_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(OUT) :: dt_new

    SELECT CASE (params%ctrl%control_strategy)
    CASE (NM_STEP_CTRL_FIXED)
      dt_new = params%step%dt_init
    CASE (NM_STEP_CTRL_ADAPTIVE)
      CALL NM_PI_Ctrl_Step_Size(params, state, dt_new)
    CASE (NM_STEP_CTRL_PREDICTIVE)
      CALL NM_Predictive_Step_Size(params, state, dt_new)
    CASE DEFAULT
      CALL NM_PI_Ctrl_Step_Size(params, state, dt_new)
    END SELECT

    ! apply step limits
    CALL NM_Limit_Step_Size(params, dt_new)

  END SUBROUTINE NM_Calc_Adaptive_Step_Size

  SUBROUTINE NM_Calc_Effective_Force(M, C, F, state, dt, beta, gamma, F_eff)
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:), F(:)
    TYPE(Dynamic_State), INTENT(IN) :: state
    REAL(DP), INTENT(IN) :: dt, beta, gamma
    REAL(DP), INTENT(OUT) :: F_eff(:)

    REAL(DP) :: a0, a2, a3
    REAL(DP), ALLOCATABLE :: term_M(:), term_C(:)

    a0 = ONE / (beta * dt * dt)
    a2 = ONE / (beta * dt)
    a3 = ONE / (TWO * beta) - ONE

    ALLOCATE(term_M(SIZE(F)), term_C(SIZE(F)))

    term_M = MATMUL(M, a0 * state%displacement + a2 * state%velocity + &
                    a3 * state%acceleration)
    term_C = MATMUL(C, (gamma/(beta*dt)) * state%displacement + &
                    (gamma/beta - ONE) * state%velocity + &
                    (gamma/(TWO*beta) - ONE) * dt * state%acceleration)

    F_eff = F + term_M + term_C

    DEALLOCATE(term_M, term_C)

  END SUBROUTINE NM_Calc_Effective_Force

  SUBROUTINE NM_Calc_Effective_Stiff(K, M, C, dt, beta, gamma, K_eff)
    REAL(DP), INTENT(IN) :: K(:,:), M(:,:), C(:,:)
    REAL(DP), INTENT(IN) :: dt, beta, gamma
    REAL(DP), INTENT(OUT) :: K_eff(:,:)

    REAL(DP) :: a0, a1

    a0 = ONE / (beta * dt * dt)
    a1 = gamma / (beta * dt)

    K_eff = K + a0 * M + a1 * C

  END SUBROUTINE NM_Calc_Effective_Stiff

  SUBROUTINE NM_GenAlpha_Single_Step_Adaptive(params, adaptive_params, M, C, K, &
                                               F_n, F_n1, dt, state, K_eff, F_eff, du, &
                                               error_est, step_accepted, status)
    TYPE(GenAlpha_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_Params), INTENT(IN) :: adaptive_params
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:), K(:,:), F_n(:), F_n1(:)
    REAL(DP), INTENT(IN) :: dt
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(OUT) :: K_eff(:,:), F_eff(:), du(:)
    REAL(DP), INTENT(OUT) :: error_est
    LOGICAL, INTENT(OUT) :: step_accepted
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: alpha_m, alpha_f, beta, gamma, a0, a1
    REAL(DP), ALLOCATABLE :: F_alpha(:), term_M(:), term_C(:), term_K(:)
    REAL(DP), ALLOCATABLE :: u_temp(:), v_temp(:), a_temp(:), u_low(:)
    INTEGER(i4) :: n_dof
    REAL(DP) :: tol

    CALL init_error_status(status)

    n_dof = SIZE(du)
    ALLOCATE(F_alpha(n_dof), term_M(n_dof), term_C(n_dof), term_K(n_dof))
    ALLOCATE(u_temp(n_dof), v_temp(n_dof), a_temp(n_dof), u_low(n_dof))

    alpha_m = params%coeff%alpha_m
    alpha_f = params%coeff%alpha_f
    beta = params%coeff%beta
    gamma = params%coeff%gamma

    ! Generalized-alpha coefficients
    a0 = (ONE - alpha_m) / (beta * dt * dt)
    a1 = (ONE - alpha_f) * gamma / (beta * dt)

    ! 1. effective stiffness
    K_eff = (ONE - alpha_f) * K + a0 * M + a1 * C

    ! 2. interpolated load F_{n+1-alpha_f} = (1-α_f)·F_{n+1} + α_f·F_n
    F_alpha = (ONE - alpha_f) * F_n1 + alpha_f * F_n

    ! 3. mass (alpha_m interpolated)
    term_M = MATMUL(M, a0 * state%displacement + &
                       (ONE - alpha_m) / (beta * dt) * state%velocity + &
                       ((ONE - alpha_m) / (TWO * beta) - ONE) * state%acceleration)

    ! 4. damping (alpha_f interpolated)
    term_C = MATMUL(C, a1 * state%displacement + &
                       (ONE - alpha_f) * (gamma / beta - ONE) * state%velocity + &
                       (ONE - alpha_f) * ((gamma / (TWO * beta) - ONE) * dt) * state%acceleration)

    ! 5. stiffness (alpha_f interpolated)
    term_K = MATMUL(K, alpha_f * state%displacement)

    ! 6. effective load
    F_eff = F_alpha + term_M + term_C - term_K

    ! 7. solve for increment
    CALL Solv_Lin_System(K_eff, F_eff, du, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      step_accepted = .FALSE.
      error_est = HUGE(ONE)
      DEALLOCATE(F_alpha, term_M, term_C, term_K, u_temp, v_temp, a_temp, u_low)
      RETURN
    END IF

    ! 8. update state
    CALL Update_State_GenAlpha(params, state, dt, du, u_temp, v_temp, a_temp)

    ! 9. error estimate
    u_low = state%displacement + dt * state%velocity
    error_est = SQRT(SUM((u_temp - u_low)**2) / n_dof)

    ! 10. normalized error
    tol = adaptive_params%tol%atol + adaptive_params%tol%rtol * &
          MAX(SQRT(SUM(u_temp**2)), SQRT(SUM(state%displacement**2)))
    error_est = error_est / tol

    ! 11. step accept decision
    step_accepted = (error_est <= ONE) .OR. (dt <= adaptive_params%step%dt_min)

    ! 12. if accept, update state
    IF (step_accepted) THEN
      state%displacement = u_temp
      state%velocity = v_temp
      state%acceleration = a_temp
    END IF

    DEALLOCATE(F_alpha, term_M, term_C, term_K, u_temp, v_temp, a_temp, u_low)

  END SUBROUTINE NM_GenAlpha_Single_Step_Adaptive

  SUBROUTINE NM_GenAlpha_Init_Params(rho_infinity, params)
    REAL(DP), INTENT(IN) :: rho_infinity
    TYPE(GenAlpha_Params), INTENT(INOUT) :: params

    REAL(DP) :: rho

    rho = MAX(ZERO, MIN(ONE, rho_infinity))
    params%spectral%rho_infinity = rho

    params%coeff%alpha_m = (TWO * rho - ONE) / (rho + ONE)
    params%coeff%alpha_f = rho / (rho + ONE)
    params%coeff%beta = (ONE - params%coeff%alpha_m + params%coeff%alpha_f)**2 / 4.0_DP
    params%coeff%gamma = HALF - params%coeff%alpha_m + params%coeff%alpha_f

  END SUBROUTINE NM_GenAlpha_Init_Params

  SUBROUTINE NM_HHT_Init_Params(alpha, params)
    REAL(DP), INTENT(IN) :: alpha
    TYPE(HHT_Params), INTENT(INOUT) :: params

    params%newmark%alpha = alpha
    params%newmark%beta = (ONE - alpha)**2 / 4.0_DP
    params%newmark%gamma = HALF - alpha

  END SUBROUTINE NM_HHT_Init_Params

  SUBROUTINE NM_HHT_Single_Step_Adaptive(params, adaptive_params, M, C, K, &
                                          F_n, F_n1, dt, state, K_eff, F_eff, du, &
                                          error_est, step_accepted, status)
    TYPE(HHT_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_Params), INTENT(IN) :: adaptive_params
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:), K(:,:), F_n(:), F_n1(:)
    REAL(DP), INTENT(IN) :: dt
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(OUT) :: K_eff(:,:), F_eff(:), du(:)
    REAL(DP), INTENT(OUT) :: error_est
    LOGICAL, INTENT(OUT) :: step_accepted
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: alpha, beta, gamma, a0, a1, alpha1
    REAL(DP), ALLOCATABLE :: F_alpha(:), term_M(:), term_C(:), term_K(:)
    REAL(DP), ALLOCATABLE :: u_temp(:), v_temp(:), a_temp(:)
    REAL(DP), ALLOCATABLE :: u_low(:)  ! low-order solution for error estimate
    INTEGER(i4) :: n_dof
    REAL(DP) :: tol

    CALL init_error_status(status)

    n_dof = SIZE(du)
    ALLOCATE(F_alpha(n_dof), term_M(n_dof), term_C(n_dof), term_K(n_dof))
    ALLOCATE(u_temp(n_dof), v_temp(n_dof), a_temp(n_dof), u_low(n_dof))

    alpha = params%newmark%alpha
    beta = params%newmark%beta
    gamma = params%newmark%gamma
    alpha1 = ONE + alpha

    ! HHT coefficients
    a0 = ONE / (beta * dt * dt)
    a1 = gamma / (beta * dt)

    ! 1. assemble effective stiffness
    K_eff = K + a0 * M + a1 * C

    ! 2. assemble interpolated load F_{n+1+alpha} = (1+α)·F_{n+1} - α·F_n
    F_alpha = alpha1 * F_n1 - alpha * F_n

    ! 3. mass term contribution
    term_M = MATMUL(M, a0 * state%displacement + &
                       (ONE/(beta*dt)) * state%velocity + &
                       (ONE/(TWO*beta) - ONE) * state%acceleration)

    ! 4. damping term (HHT correction)
    term_C = MATMUL(C, alpha1 * (a1 * state%displacement + &
                                 (gamma/beta - ONE) * state%velocity + &
                                 ((gamma/(TWO*beta) - ONE) * dt) * state%acceleration) - &
                      alpha * state%velocity)

    ! 5. stiffness term (HHT correction)
    term_K = MATMUL(K, -alpha * state%displacement)

    ! 6. assemble effective load
    F_eff = F_alpha + term_M + term_C + term_K

    ! 7. solve for increment
    CALL Solv_Lin_System(K_eff, F_eff, du, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      step_accepted = .FALSE.
      error_est = HUGE(ONE)
      DEALLOCATE(F_alpha, term_M, term_C, term_K, u_temp, v_temp, a_temp, u_low)
      RETURN
    END IF

    ! 8. update state (high-order)
    CALL Update_State_HHT(params, state, dt, du, u_temp, v_temp, a_temp)

    ! 9. error estimate (low-order ref)
    ! use explicit Euler as low-order ref
    u_low = state%displacement + dt * state%velocity
    error_est = SQRT(SUM((u_temp - u_low)**2) / n_dof)

    ! 10. normalized error
    tol = adaptive_params%tol%atol + adaptive_params%tol%rtol * &
          MAX(SQRT(SUM(u_temp**2)), SQRT(SUM(state%displacement**2)))
    error_est = error_est / tol

    ! 11. step accept decision
    step_accepted = (error_est <= ONE) .OR. (dt <= adaptive_params%step%dt_min)

    ! 12. if accept, update state
    IF (step_accepted) THEN
      state%displacement = u_temp
      state%velocity = v_temp
      state%acceleration = a_temp
    END IF

    DEALLOCATE(F_alpha, term_M, term_C, term_K, u_temp, v_temp, a_temp, u_low)

  END SUBROUTINE NM_HHT_Single_Step_Adaptive

  SUBROUTINE NM_Limit_Step_Size(params, dt)
    TYPE(AdaptiveStep_Params), INTENT(IN) :: params
    REAL(DP), INTENT(INOUT) :: dt

    dt = MAX(params%step%dt_min, MIN(params%step%dt_max, dt))

  END SUBROUTINE NM_Limit_Step_Size

  SUBROUTINE NM_Newmark_Single_Step_Adaptive(params, adaptive_params, M, C, K, &
                                              F, dt, state, K_eff, F_eff, du, &
                                              error_est, step_accepted, status)
    TYPE(Newmark_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_Params), INTENT(IN) :: adaptive_params
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:), K(:,:), F(:)
    REAL(DP), INTENT(IN) :: dt
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(OUT) :: K_eff(:,:), F_eff(:), du(:)
    REAL(DP), INTENT(OUT) :: error_est
    LOGICAL, INTENT(OUT) :: step_accepted
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: beta, gamma, a0, a1, a2, a3
    REAL(DP), ALLOCATABLE :: term_M(:), term_C(:), u_temp(:), u_low(:)
    INTEGER(i4) :: n_dof
    REAL(DP) :: tol

    CALL init_error_status(status)

    n_dof = SIZE(du)
    ALLOCATE(term_M(n_dof), term_C(n_dof), u_temp(n_dof), u_low(n_dof))

    beta = params%beta
    gamma = params%gamma

    a0 = ONE / (beta * dt * dt)
    a1 = gamma / (beta * dt)
    a2 = ONE / (beta * dt)
    a3 = ONE / (TWO * beta) - ONE

    ! effective stiffness
    K_eff = K + a0 * M + a1 * C

    ! effective load
    term_M = MATMUL(M, a0 * state%displacement + a2 * state%velocity + a3 * state%acceleration)
    term_C = MATMUL(C, a1 * state%displacement + (gamma/beta - ONE) * state%velocity + &
                    (gamma/(TWO*beta) - ONE) * dt * state%acceleration)
    F_eff = F + term_M + term_C

    ! solve
    CALL Solv_Lin_System(K_eff, F_eff, du, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      step_accepted = .FALSE.
      error_est = HUGE(ONE)
      DEALLOCATE(term_M, term_C, u_temp, u_low)
      RETURN
    END IF

    ! update
    u_temp = state%displacement + du
    u_low = state%displacement + dt * state%velocity

    ! error estimate
    error_est = SQRT(SUM((u_temp - u_low)**2) / n_dof)
    tol = adaptive_params%tol%atol + adaptive_params%tol%rtol * MAX(SQRT(SUM(u_temp**2)), &
          SQRT(SUM(state%displacement**2)))
    error_est = error_est / tol

    step_accepted = (error_est <= ONE) .OR. (dt <= adaptive_params%step%dt_min)

    IF (step_accepted) THEN
      CALL Update_State_Newmark(params, state, dt, du)
    END IF

    DEALLOCATE(term_M, term_C, u_temp, u_low)

  END SUBROUTINE NM_Newmark_Single_Step_Adaptive

  SUBROUTINE NM_PI_Ctrl_Step_Size(params, state, dt_new)
    TYPE(AdaptiveStep_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_State), INTENT(IN) :: state
    REAL(DP), INTENT(OUT) :: dt_new

    REAL(DP) :: factor, err_ratio, err_change
    REAL(DP) :: kP, kI, safety

    kP = params%pi%pi_kp
    kI = params%pi%pi_ki
    safety = params%pi%safety_factor

    ! avoid division by zero
    IF (state%error_current < EPS_TIME) THEN
      dt_new = state%dt_current * params%pi%max_step_ratio
      RETURN
    END IF

    ! error ratio
    err_ratio = ONE / state%error_current

    ! PI control factor
    factor = safety * (err_ratio ** kP)

    ! integral term (if history)
    IF (state%error_previous > EPS_TIME) THEN
      err_change = state%error_previous / state%error_current
      factor = factor * (err_change ** kI)
    END IF

    ! apply growth limit
    factor = MAX(params%pi%min_step_ratio, MIN(params%pi%max_step_ratio, factor))

    dt_new = state%dt_current * factor

  END SUBROUTINE NM_PI_Ctrl_Step_Size

  SUBROUTINE NM_Predictive_Step_Size(params, state, dt_new)
    TYPE(AdaptiveStep_Params), INTENT(IN) :: params
    TYPE(AdaptiveStep_State), INTENT(IN) :: state
    REAL(DP), INTENT(OUT) :: dt_new

    REAL(DP) :: trend, predicted_error

    ! simple linear prediction
    IF (state%error_previous > EPS_TIME) THEN
      trend = (state%error_current - state%error_previous) / state%error_previous
      predicted_error = state%error_current * (ONE + trend)
      predicted_error = MAX(predicted_error, EPS_TIME)
    ELSE
      predicted_error = state%error_current
    END IF

    dt_new = state%dt_current * params%pi%safety_factor * (ONE / predicted_error) ** 0.2_DP

  END SUBROUTINE NM_Predictive_Step_Size

  SUBROUTINE NM_Update_Dynamic_State(state, dt, du, beta, gamma)
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(IN) :: dt, du(:), beta, gamma

    REAL(DP) :: a0, a2, a3, a6, a7
    REAL(DP), ALLOCATABLE :: a_new(:)

    a0 = ONE / (beta * dt * dt)
    a2 = ONE / (beta * dt)
    a3 = ONE / (TWO * beta) - ONE
    a6 = dt * (ONE - gamma)
    a7 = gamma * dt

    ALLOCATE(a_new(SIZE(du)))

    state%displacement = state%displacement + du
    a_new = a0 * du - a2 * state%velocity - a3 * state%acceleration
    state%velocity = state%velocity + a6 * state%acceleration + a7 * a_new
    state%acceleration = a_new

    DEALLOCATE(a_new)

  END SUBROUTINE NM_Update_Dynamic_State

  SUBROUTINE Save_State_To_Res(state, result, idx)
    TYPE(Dynamic_State), INTENT(IN) :: state
    TYPE(TimeIntegration_Result), INTENT(INOUT) :: result
    INTEGER(i4), INTENT(IN) :: idx

    IF (idx > SIZE(result%time_history)) RETURN

    result%displacement_history(:, idx) = state%displacement
    result%velocity_history(:, idx) = state%velocity
    result%acceleration_history(:, idx) = state%acceleration
    result%time_history(idx) = state%current_time

  END SUBROUTINE Save_State_To_Res

  SUBROUTINE Solv_Lin_System(A, b, x, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(OUT) :: x(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n, info
    REAL(DP), ALLOCATABLE :: A_copy(:,:), b_copy(:)
    INTEGER, ALLOCATABLE :: ipiv(:)

    CALL init_error_status(status)

    n = SIZE(b)
    ALLOCATE(A_copy(n,n), b_copy(n), ipiv(n))

    A_copy = A
    b_copy = b

    ! use LAPACK DGESV (LU decomposition)
    CALL DGESV(n, 1, A_copy, n, ipiv, b_copy, n, info)

    IF (info == 0) THEN
      x = b_copy
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_ERROR
      status%message = "Linear solver failed"
      x = ZERO
    END IF

    DEALLOCATE(A_copy, b_copy, ipiv)

  END SUBROUTINE Solv_Lin_System

  SUBROUTINE Update_State_GenAlpha(params, state, dt, du, u_new, v_new, a_new)
    TYPE(GenAlpha_Params), INTENT(IN) :: params
    TYPE(Dynamic_State), INTENT(IN) :: state
    REAL(DP), INTENT(IN) :: dt, du(:)
    REAL(DP), INTENT(OUT) :: u_new(:), v_new(:), a_new(:)

    REAL(DP) :: beta, gamma, a0, a2, a3, a6, a7

    beta = params%coeff%beta
    gamma = params%coeff%gamma

    a0 = ONE / (beta * dt * dt)
    a2 = ONE / (beta * dt)
    a3 = ONE / (TWO * beta) - ONE
    a6 = dt * (ONE - gamma)
    a7 = gamma * dt

    u_new = state%displacement + du
    a_new = a0 * du - a2 * state%velocity - a3 * state%acceleration
    v_new = state%velocity + a6 * state%acceleration + a7 * a_new

  END SUBROUTINE Update_State_GenAlpha

  SUBROUTINE Update_State_HHT(params, state, dt, du, u_new, v_new, a_new)
    TYPE(HHT_Params), INTENT(IN) :: params
    TYPE(Dynamic_State), INTENT(IN) :: state
    REAL(DP), INTENT(IN) :: dt, du(:)
    REAL(DP), INTENT(OUT) :: u_new(:), v_new(:), a_new(:)

    REAL(DP) :: beta, gamma, a0, a2, a3, a6, a7

    beta = params%newmark%beta
    gamma = params%newmark%gamma

    a0 = ONE / (beta * dt * dt)
    a2 = ONE / (beta * dt)
    a3 = ONE / (TWO * beta) - ONE
    a6 = dt * (ONE - gamma)
    a7 = gamma * dt

    u_new = state%displacement + du
    a_new = a0 * du - a2 * state%velocity - a3 * state%acceleration
    v_new = state%velocity + a6 * state%acceleration + a7 * a_new

  END SUBROUTINE Update_State_HHT

  SUBROUTINE Update_State_Newmark(params, state, dt, du)
    TYPE(Newmark_Params), INTENT(IN) :: params
    TYPE(Dynamic_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(IN) :: dt, du(:)

    REAL(DP) :: beta, gamma, a0, a2, a3, a6, a7
    REAL(DP), ALLOCATABLE :: a_new(:)

    beta = params%beta
    gamma = params%gamma

    a0 = ONE / (beta * dt * dt)
    a2 = ONE / (beta * dt)
    a3 = ONE / (TWO * beta) - ONE
    a6 = dt * (ONE - gamma)
    a7 = gamma * dt

    ALLOCATE(a_new(SIZE(du)))

    state%displacement = state%displacement + du
    a_new = a0 * du - a2 * state%velocity - a3 * state%acceleration
    state%velocity = state%velocity + a6 * state%acceleration + a7 * a_new
    state%acceleration = a_new

    DEALLOCATE(a_new)

  END SUBROUTINE Update_State_Newmark
END MODULE NM_TimeInt_AdaptStep