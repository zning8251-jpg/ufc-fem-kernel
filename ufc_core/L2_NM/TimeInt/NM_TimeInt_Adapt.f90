!===============================================================================
! MODULE: NM_TimeInt_Adapt
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — Adaptive time integration (Alpha/Newmark/HHT/Generalized-alpha)
! BRIEF:  Advanced time integration with adaptive step size control
!===============================================================================

MODULE NM_TimeInt_Adapt
!> Status: Production | Last verified: 2026-03-01
!> Theory: Numerical method implementation | Ref: Saad(2003) Iterative Methods
  USE, INTRINSIC :: ISO_C_BINDING, ONLY: C_DOUBLE, C_INT, C_BOOL
  USE IF_Prec_Core, ONLY: wp
  USE NM_TimeInt_Scheme, ONLY: NM_TimeInt_Ctrl_Ctx, NM_TimeInt_State
  INTEGER(i4), PARAMETER :: DP = wp
  
  IMPLICIT NONE
  
  PRIVATE
  
  !-----------------------------------------------------------------------------
  ! Integration Method Types
  !-----------------------------------------------------------------------------
  INTEGER, PARAMETER, PUBLIC :: NM_INTEGRATION_NEWMARK = 1
  INTEGER, PARAMETER, PUBLIC :: NM_INTEGRATION_HHT = 2
  INTEGER, PARAMETER, PUBLIC :: NM_INTEGRATION_GENERALIZED_ALPHA = 3
  INTEGER, PARAMETER, PUBLIC :: NM_INTEGRATION_BOSSAK = 4
  
  !-----------------------------------------------------------------------------
  ! Time Step Ctrl Strategies
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: NM_STEP_CONTROL_FIXED = 0
  INTEGER(i4), PARAMETER :: NM_STEP_CONTROL_ERROR = 1
  INTEGER(i4), PARAMETER :: NM_STEP_CONTROL_ITERATION = 2
  INTEGER(i4), PARAMETER :: NM_STEP_CONTROL_HYBRID = 3
  
  !-----------------------------------------------------------------------------
  ! Alpha-Method Parameters (HHT)
  !-----------------------------------------------------------------------------
    TYPE, PUBLIC :: Alpha_Method_Params_Coeff
    REAL(DP) :: alpha_m             ! Mass matrix parameter
    REAL(DP) :: alpha_f             ! Force/stiffness parameter
    REAL(DP) :: beta                ! Newmark beta
    REAL(DP) :: gamma               ! Newmark gamma
  END TYPE Alpha_Method_Params_Coeff

  TYPE, PUBLIC :: Alpha_Method_Params_Spectral
    REAL(DP) :: spectral_radius      ! Target spectral radius (rho_inf)
    LOGICAL :: optimal_parameters   ! Auto-compute from spectral radius
  END TYPE Alpha_Method_Params_Spectral

  TYPE, PUBLIC :: Alpha_Method_Params_Ctrl
    INTEGER(i4) :: method_type          ! HHT, Generalized-alpha, etc.
  END TYPE Alpha_Method_Params_Ctrl

  TYPE, PUBLIC :: Alpha_Method_Parameters
    TYPE(Alpha_Method_Params_Coeff)     :: coeff
    TYPE(Alpha_Method_Params_Spectral)  :: spectral
    TYPE(Alpha_Method_Params_Ctrl)      :: ctrl
  END TYPE Alpha_Method_Parameters
  
  !-----------------------------------------------------------------------------
  ! Adaptive Time Step Parameters
  !-----------------------------------------------------------------------------
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
  
  !-----------------------------------------------------------------------------
  ! Time Step State
  !-----------------------------------------------------------------------------
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
  
  !-----------------------------------------------------------------------------
  ! Integration Solution State
  !-----------------------------------------------------------------------------
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
  
  !-----------------------------------------------------------------------------
  ! Error Estimation Data
  !-----------------------------------------------------------------------------
    TYPE, PUBLIC :: Error_Estimate_Disp
    REAL(DP) :: displacement_error
  END TYPE Error_Estimate_Disp

  TYPE, PUBLIC :: Error_Estimate_Vel
    REAL(DP) :: velocity_error
  END TYPE Error_Estimate_Vel

  TYPE, PUBLIC :: Error_Estimate_Accel
    REAL(DP) :: acceleration_error
  END TYPE Error_Estimate_Accel

  TYPE, PUBLIC :: Error_Estimate_Total
    REAL(DP) :: total_error
    REAL(DP) :: relative_error
  END TYPE Error_Estimate_Total

  TYPE, PUBLIC :: Error_Estimate_Flags
    LOGICAL :: is_accurate
  END TYPE Error_Estimate_Flags

  TYPE, PUBLIC :: Error_Estimate
    TYPE(Error_Estimate_Disp)  :: disp
    TYPE(Error_Estimate_Vel)   :: vel
    TYPE(Error_Estimate_Accel) :: accel
    TYPE(Error_Estimate_Total) :: total
    TYPE(Error_Estimate_Flags) :: flags
  END TYPE Error_Estimate
  
  !-----------------------------------------------------------------------------
  ! Public Interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: NM_Alpha_Method_Parameters_Default
  PUBLIC :: NM_Alpha_Method_Parameters_Optimal
  PUBLIC :: NM_Adaptive_Step_Parameters_Default
  PUBLIC :: NM_Adaptive_Integ_Init
  PUBLIC :: NM_Alpha_Method_Predictor
  PUBLIC :: NM_Alpha_Method_Corrector
  PUBLIC :: NM_Adaptive_Step_Size_Update
  PUBLIC :: NM_Error_Estimate_Embedded
  PUBLIC :: NM_Time_Step_Accept
  PUBLIC :: NM_HHT_Effective_Stiff
  PUBLIC :: NM_HHT_Effective_Force
  PUBLIC :: NM_Generalized_Alpha_Effective_Stiffness
  PUBLIC :: NM_Generalized_Alpha_Effective_Force
  
CONTAINS
  
  !=============================================================================
  ! Default Alpha Method Parameters
  !=============================================================================
  SUBROUTINE NM_Al_Me_Pa_Default(params, method_type)
    TYPE(Alpha_Method_Parameters), INTENT(OUT) :: params
    INTEGER(i4), INTENT(IN) :: method_type
    
    params%ctrl%method_type = method_type
    params%spectral%optimal_parameters = .TRUE.
    params%spectral%spectral_radius = 0.9_DP
    
    SELECT CASE (method_type)
    CASE (NM_INTEGRATION_NEWMARK)
      ! Standard Newmark (average acceleration)
      params%coeff%beta = 0.25_DP
      params%coeff%gamma = 0.5_DP
      params%coeff%alpha_m = 0.0_DP
      params%coeff%alpha_f = 0.0_DP
      
    CASE (NM_INTEGRATION_HHT)
      ! Hilber-Hughes-Taylor (alpha = -0.05 typical)
      params%coeff%alpha_f = -0.05_DP
      params%coeff%alpha_m = 0.0_DP
      params%coeff%beta = (1.0_DP - params%coeff%alpha_f)**2 / 4.0_DP
      params%coeff%gamma = 0.5_DP - params%coeff%alpha_f
      
    CASE (NM_INTEGRATION_GENERALIZED_ALPHA)
      ! Generalized-alpha with optimal parameters
      CALL NM_Alpha_Method_Parameters_Optimal(params%spectral%spectral_radius, params)
      
    CASE (NM_INTEGRATION_BOSSAK)
      ! Bossak method
      params%coeff%alpha_m = -0.05_DP
      params%coeff%alpha_f = 0.0_DP
      params%coeff%beta = (1.0_DP - params%coeff%alpha_m)**2 / 4.0_DP
      params%coeff%gamma = 0.5_DP - params%coeff%alpha_m
      
    END SELECT
    
  END SUBROUTINE NM_Alpha_Method_Parameters_Default
  
  !=============================================================================
  ! Optimal Alpha Parameters from Spectral Radius
  !=============================================================================
  SUBROUTINE NM_Al_Me_Pa_Optimal(rho_inf, params)
    REAL(DP), INTENT(IN) :: rho_inf
    TYPE(Alpha_Method_Parameters), INTENT(OUT) :: params
    
    REAL(DP) :: rho
    
    rho = MAX(0.0_DP, MIN(1.0_DP, rho_inf))
    
    ! Optimal parameters for second-order accuracy and unconditional stability
    params%spectral%spectral_radius = rho
    params%coeff%alpha_m = (2.0_DP - rho) / (1.0_DP + rho)
    params%coeff%alpha_f = 1.0_DP / (1.0_DP + rho)
    params%coeff%gamma = 0.5_DP + params%coeff%alpha_m - params%coeff%alpha_f
    params%coeff%beta = 0.25_DP * (1.0_DP + params%coeff%alpha_m - params%coeff%alpha_f)**2
    params%ctrl%method_type = NM_INTEGRATION_GENERALIZED_ALPHA
    params%spectral%optimal_parameters = .TRUE.
    
  END SUBROUTINE NM_Alpha_Method_Parameters_Optimal
  
  !=============================================================================
  ! Default Adaptive Step Parameters
  !=============================================================================
  SUBROUTINE NM_Ad_St_Pa_Default(params)
    TYPE(Adaptive_Step_Parameters), INTENT(OUT) :: params
    
    params%dt_initial = 0.01_DP
    params%dt_min = 1.0e-10_DP
    params%dt_max = 1.0_DP
    params%tolerance = 1.0e-4_DP
    params%safety_factor = 0.9_DP
    params%max_iterations = 10
    params%min_iterations = 2
    params%step_control_type = NM_STEP_CONTROL_HYBRID
    params%allow_step_increase = .TRUE.
    params%growth_rate = 2.0_DP
    params%shrink_rate = 0.5_DP
    
  END SUBROUTINE NM_Adaptive_Step_Parameters_Default
  
  !=============================================================================
  ! Init Adaptive Integration
  !=============================================================================
  SUBROUTINE NM_Adaptive_Integ_Init(state, n_dof, u0, v0, a0, success)
    TYPE(Adaptive_Integration_State), INTENT(OUT) :: state
    INTEGER(i4), INTENT(IN) :: n_dof
    REAL(DP), INTENT(IN) :: u0(:), v0(:), a0(:)
    LOGICAL, INTENT(OUT) :: success
    
    success = .FALSE.
    
    state%pop%n_dof = n_dof
    
    ALLOCATE(state%u(n_dof))
    ALLOCATE(state%v(n_dof))
    ALLOCATE(state%a(n_dof))
    ALLOCATE(state%u_old(n_dof))
    ALLOCATE(state%v_old(n_dof))
    ALLOCATE(state%a_old(n_dof))
    ALLOCATE(state%u_pred(n_dof))
    ALLOCATE(state%v_pred(n_dof))
    ALLOCATE(state%a_pred(n_dof))
    
    state%u = u0
    state%v = v0
    state%a = a0
    state%u_old = u0
    state%v_old = v0
    state%a_old = a0
    state%u_pred = u0
    state%v_pred = v0
    state%a_pred = a0
    
    success = .TRUE.
  END SUBROUTINE NM_Adaptive_Integ_Init
  
  !=============================================================================
  ! Alpha Method Predictor Step
  !=============================================================================
  SUBROUTINE NM_Alpha_Method_Predictor(state, alpha_params, dt, success)
    TYPE(Adaptive_Integration_State), INTENT(INOUT) :: state
    TYPE(Alpha_Method_Parameters), INTENT(IN) :: alpha_params
    REAL(DP), INTENT(IN) :: dt
    LOGICAL, INTENT(OUT) :: success
    
    REAL(DP) :: beta, gamma
    
    success = .FALSE.
    
    beta = alpha_params%coeff%beta
    gamma = alpha_params%coeff%gamma
    
    ! Store old values
    state%u_old = state%u
    state%v_old = state%v
    state%a_old = state%a
    
    ! Predictor (constant acceleration)
    state%a_pred = state%a
    state%v_pred = state%v + dt * (1.0_DP - gamma) * state%a
    state%u_pred = state%u + dt * state%v + 0.5_DP * dt**2 * (1.0_DP - 2.0_DP * beta) * state%a
    
    ! Init corrector
    state%u = state%u_pred
    state%v = state%v_pred
    state%a = state%a_pred
    
    success = .TRUE.
  END SUBROUTINE NM_Alpha_Method_Predictor
  
  !=============================================================================
  ! Alpha Method Corrector Step
  !=============================================================================
  SUBROUTINE NM_Alpha_Method_Corrector(state, alpha_params, dt, &
                                       delta_u, converged, success)
    TYPE(Adaptive_Integration_State), INTENT(INOUT) :: state
    TYPE(Alpha_Method_Parameters), INTENT(IN) :: alpha_params
    REAL(DP), INTENT(IN) :: dt
    REAL(DP), INTENT(IN) :: delta_u(:)
    LOGICAL, INTENT(IN) :: converged
    LOGICAL, INTENT(OUT) :: success
    
    REAL(DP) :: beta, gamma
    
    success = .FALSE.
    
    IF (.NOT. converged) THEN
      success = .TRUE.
      RETURN
    END IF
    
    beta = alpha_params%coeff%beta
    gamma = alpha_params%coeff%gamma
    
    ! Update displacement
    state%u = state%u + delta_u
    
    ! Update acceleration and velocity
    state%a = (state%u - state%u_pred) / (beta * dt**2)
    state%v = state%v_pred + gamma * dt * state%a
    
    success = .TRUE.
  END SUBROUTINE NM_Alpha_Method_Corrector
  
  !=============================================================================
  ! HHT Effective Stiffness Matrix
  !=============================================================================
  FUNCTION NM_HHT_Effective_Stiff(K, M, C, alpha_params, dt) RESULT(K_eff)
    REAL(DP), INTENT(IN) :: K(:,:), M(:,:), C(:,:)
    TYPE(Alpha_Method_Parameters), INTENT(IN) :: alpha_params
    REAL(DP), INTENT(IN) :: dt
    REAL(DP), ALLOCATABLE :: K_eff(:,:)
    
    REAL(DP) :: beta, gamma, alpha_f
    REAL(DP) :: factor_k, factor_c, factor_m
    INTEGER(i4) :: n
    
    n = SIZE(K, 1)
    ALLOCATE(K_eff(n, n))
    
    beta = alpha_params%coeff%beta
    gamma = alpha_params%coeff%gamma
    alpha_f = alpha_params%coeff%alpha_f
    
    ! Effective stiffness for HHT
    factor_k = 1.0_DP + alpha_f
    factor_c = gamma * (1.0_DP + alpha_f) / (beta * dt)
    factor_m = 1.0_DP / (beta * dt**2)
    
    K_eff = factor_k * K + factor_c * C + factor_m * M
    
  END FUNCTION NM_HHT_Effective_Stiff
  
  !=============================================================================
  ! HHT Effective Force Vector
  !=============================================================================
  FUNCTION NM_HHT_Effective_Force(F_ext, F_int, M, C, state, alpha_params, dt) &
           RESULT(F_eff)
    REAL(DP), INTENT(IN) :: F_ext(:), F_int(:)
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:)
    TYPE(Adaptive_Integration_State), INTENT(IN) :: state
    TYPE(Alpha_Method_Parameters), INTENT(IN) :: alpha_params
    REAL(DP), INTENT(IN) :: dt
    REAL(DP), ALLOCATABLE :: F_eff(:)
    
    REAL(DP) :: beta, gamma, alpha_f
    REAL(DP), ALLOCATABLE :: temp(:)
    INTEGER(i4) :: n
    
    n = SIZE(F_ext)
    ALLOCATE(F_eff(n))
    ALLOCATE(temp(n))
    
    beta = alpha_params%coeff%beta
    gamma = alpha_params%coeff%gamma
    alpha_f = alpha_params%coeff%alpha_f
    
    ! Effective force
    temp = state%u_pred / (beta * dt**2) + &
           state%v_pred * gamma / (beta * dt) + &
           state%a_pred * (gamma / beta - 1.0_DP)
    
    F_eff = F_ext - (1.0_DP + alpha_f) * F_int + &
            MATMUL(M, temp) + &
            MATMUL(C, state%v_pred + (gamma / (beta * dt)) * (state%u_pred - state%u))
    
    DEALLOCATE(temp)
    
  END FUNCTION NM_HHT_Effective_Force
  
  !=============================================================================
  ! Generalized Alpha Effective Stiffness
  !=============================================================================
  FUNCTION NM_Generalized_Alpha_Effective_Stiffness(K, M, C, alpha_params, dt) &
           RESULT(K_eff)
    REAL(DP), INTENT(IN) :: K(:,:), M(:,:), C(:,:)
    TYPE(Alpha_Method_Parameters), INTENT(IN) :: alpha_params
    REAL(DP), INTENT(IN) :: dt
    REAL(DP), ALLOCATABLE :: K_eff(:,:)
    
    REAL(DP) :: beta, gamma, alpha_m, alpha_f
    REAL(DP) :: factor_k, factor_c, factor_m
    INTEGER(i4) :: n
    
    n = SIZE(K, 1)
    ALLOCATE(K_eff(n, n))
    
    beta = alpha_params%coeff%beta
    gamma = alpha_params%coeff%gamma
    alpha_m = alpha_params%coeff%alpha_m
    alpha_f = alpha_params%coeff%alpha_f
    
    ! Effective stiffness for Generalized-alpha
    factor_k = 1.0_DP - alpha_f
    factor_c = (1.0_DP - alpha_f) * gamma / (beta * dt)
    factor_m = (1.0_DP - alpha_m) / (beta * dt**2)
    
    K_eff = factor_k * K + factor_c * C + factor_m * M
    
  END FUNCTION NM_Generalized_Alpha_Effective_Stiffness
  
  !=============================================================================
  ! Generalized Alpha Effective Force
  !=============================================================================
  FUNCTION NM_Generalized_Alpha_Effective_Force(F_ext, F_int, M, C, state, &
                                                alpha_params, dt) RESULT(F_eff)
    REAL(DP), INTENT(IN) :: F_ext(:), F_int(:)
    REAL(DP), INTENT(IN) :: M(:,:), C(:,:)
    TYPE(Adaptive_Integration_State), INTENT(IN) :: state
    TYPE(Alpha_Method_Parameters), INTENT(IN) :: alpha_params
    REAL(DP), INTENT(IN) :: dt
    REAL(DP), ALLOCATABLE :: F_eff(:)
    
    REAL(DP) :: beta, gamma, alpha_m, alpha_f
    REAL(DP), ALLOCATABLE :: a_temp(:), v_temp(:)
    INTEGER(i4) :: n
    
    n = SIZE(F_ext)
    ALLOCATE(F_eff(n))
    ALLOCATE(a_temp(n))
    ALLOCATE(v_temp(n))
    
    beta = alpha_params%coeff%beta
    gamma = alpha_params%coeff%gamma
    alpha_m = alpha_params%coeff%alpha_m
    alpha_f = alpha_params%coeff%alpha_f
    
    ! Predicted acceleration and velocity
    a_temp = (state%u_pred - state%u_old) / (beta * dt**2) - &
             state%v_old / (beta * dt) - state%a_old * (1.0_DP / (2.0_DP * beta) - 1.0_DP)
    
    v_temp = state%v_old + dt * ((1.0_DP - gamma) * state%a_old + gamma * a_temp)
    
    ! Effective force
    F_eff = (1.0_DP - alpha_f) * F_ext + alpha_f * F_int - &
            MATMUL(M, (1.0_DP - alpha_m) * a_temp + alpha_m * state%a_old) - &
            MATMUL(C, (1.0_DP - alpha_f) * v_temp + alpha_f * state%v_old)
    
    DEALLOCATE(a_temp)
    DEALLOCATE(v_temp)
    
  END FUNCTION NM_Generalized_Alpha_Effective_Force
  
  !=============================================================================
  ! Embedded Error Estimation
  !=============================================================================
  SUBROUTINE NM_Error_Estimate_Embedded(state, state_low_order, error, success)
    TYPE(Adaptive_Integration_State), INTENT(IN) :: state
    TYPE(Adaptive_Integration_State), INTENT(IN) :: state_low_order
    TYPE(Error_Estimate), INTENT(OUT) :: error
    LOGICAL, INTENT(OUT) :: success
    
    REAL(DP) :: u_diff, v_diff, a_diff
    REAL(DP) :: u_norm, v_norm, a_norm
    
    success = .FALSE.
    
    ! Difference between high and low order solutions
    u_diff = SQRT(DOT_PRODUCT(state%u - state_low_order%u, state%u - state_low_order%u))
    v_diff = SQRT(DOT_PRODUCT(state%v - state_low_order%v, state%v - state_low_order%v))
    a_diff = SQRT(DOT_PRODUCT(state%a - state_low_order%a, state%a - state_low_order%a))
    
    ! Norms of solution
    u_norm = SQRT(DOT_PRODUCT(state%u, state%u)) + 1.0e-30_DP
    v_norm = SQRT(DOT_PRODUCT(state%v, state%v)) + 1.0e-30_DP
    a_norm = SQRT(DOT_PRODUCT(state%a, state%a)) + 1.0e-30_DP
    
    ! Error estimates
    error%displacement_error = u_diff
    error%velocity_error = v_diff
    error%acceleration_error = a_diff
    error%total_error = SQRT((u_diff/u_norm)**2 + (v_diff/v_norm)**2 + (a_diff/a_norm)**2)
    error%relative_error = error%total_error
    
    success = .TRUE.
  END SUBROUTINE NM_Error_Estimate_Embedded
  
  !=============================================================================
  ! Adaptive Step Size Update
  !=============================================================================
  SUBROUTINE NM_Adaptive_Step_Size_Update(step_state, step_params, error, &
                                          converged, n_iterations, success)
    TYPE(Adaptive_Time_Step_State), INTENT(INOUT) :: step_state
    TYPE(Adaptive_Step_Parameters), INTENT(IN) :: step_params
    TYPE(Error_Estimate), INTENT(IN) :: error
    LOGICAL, INTENT(IN) :: converged
    INTEGER(i4), INTENT(IN) :: n_iterations
    LOGICAL, INTENT(OUT) :: success
    
    REAL(DP) :: dt_new, dt_old
    REAL(DP) :: error_ratio
    REAL(DP) :: iteration_factor
    
    success = .FALSE.
    
    dt_old = step_state%dt_current
    step_state%n_iterations = n_iterations
    step_state%converged = converged
    step_state%estimated_error = error%total_error
    
    ! Check convergence
    IF (.NOT. converged) THEN
      ! Reduce step size and retry
      dt_new = dt_old * step_params%shrink_rate
      step_state%step_accepted = .FALSE.
      step_state%n_rejected_steps = step_state%n_rejected_steps + 1
      
      ! Enforce minimum
      IF (dt_new < step_params%dt_min) THEN
        dt_new = step_params%dt_min
      END IF
      
      step_state%optimal_dt = dt_new
      success = .TRUE.
      RETURN
    END IF
    
    ! Step converged - check error
    step_state%n_accepted_steps = step_state%n_accepted_steps + 1
    
    SELECT CASE (step_params%step_control_type)
    CASE (NM_STEP_CONTROL_ERROR)
      ! Error-based control
      IF (error%total_error > step_params%tolerance) THEN
        ! Error too large - reject step
        error_ratio = error%total_error / step_params%tolerance
        dt_new = dt_old * step_params%safety_factor / error_ratio**(1.0_DP/3.0_DP)
        step_state%step_accepted = .FALSE.
        step_state%n_rejected_steps = step_state%n_rejected_steps + 1
      ELSE
        ! Error acceptable - accept and suggest next step
        step_state%step_accepted = .TRUE.
        
        IF (step_params%allow_step_increase) THEN
          error_ratio = error%total_error / step_params%tolerance
          dt_new = dt_old * step_params%safety_factor / error_ratio**(1.0_DP/3.0_DP)
          dt_new = MIN(dt_new, dt_old * step_params%growth_rate)
        ELSE
          dt_new = dt_old
        END IF
      END IF
      
    CASE (NM_STEP_CONTROL_ITERATION)
      ! Iteration-based control
      IF (n_iterations > step_params%max_iterations) THEN
        dt_new = dt_old * step_params%shrink_rate
        step_state%step_accepted = .FALSE.
        step_state%n_rejected_steps = step_state%n_rejected_steps + 1
      ELSE IF (n_iterations < step_params%min_iterations) THEN
        step_state%step_accepted = .TRUE.
        IF (step_params%allow_step_increase) THEN
          iteration_factor = REAL(step_params%min_iterations, DP) / REAL(MAX(n_iterations, 1), DP)
          dt_new = dt_old * MIN(iteration_factor, step_params%growth_rate)
        ELSE
          dt_new = dt_old
        END IF
      ELSE
        step_state%step_accepted = .TRUE.
        dt_new = dt_old
      END IF
      
    CASE (NM_STEP_CONTROL_HYBRID)
      ! Hybrid control (error and iteration)
      IF (error%total_error > step_params%tolerance .OR. &
          n_iterations > step_params%max_iterations) THEN
        ! Reduce step
        dt_new = dt_old * step_params%shrink_rate
        step_state%step_accepted = .FALSE.
        step_state%n_rejected_steps = step_state%n_rejected_steps + 1
      ELSE
        step_state%step_accepted = .TRUE.
        
        IF (step_params%allow_step_increase .AND. &
            error%total_error < 0.5_DP * step_params%tolerance .AND. &
            n_iterations < step_params%min_iterations) THEN
          ! Increase step
          error_ratio = error%total_error / (0.5_DP * step_params%tolerance)
          iteration_factor = REAL(step_params%min_iterations, DP) / REAL(MAX(n_iterations, 1), DP)
          dt_new = dt_old * step_params%safety_factor * MIN(iteration_factor, &
                   step_params%growth_rate) / error_ratio**(1.0_DP/3.0_DP)
        ELSE
          dt_new = dt_old
        END IF
      END IF
      
    CASE DEFAULT
      ! Fixed step
      step_state%step_accepted = .TRUE.
      dt_new = dt_old
    END SELECT
    
    ! Enforce bounds
    dt_new = MAX(step_params%dt_min, MIN(step_params%dt_max, dt_new))
    
    step_state%optimal_dt = dt_new
    step_state%dt_previous = dt_old
    
    success = .TRUE.
  END SUBROUTINE NM_Adaptive_Step_Size_Update
  
  !=============================================================================
  ! Accept Time Step
  !=============================================================================
  SUBROUTINE NM_Time_Step_Accept(step_state, state, success)
    TYPE(Adaptive_Time_Step_State), INTENT(INOUT) :: step_state
    TYPE(Adaptive_Integration_State), INTENT(INOUT) :: state
    LOGICAL, INTENT(OUT) :: success
    
    success = .FALSE.
    
    IF (.NOT. step_state%step_accepted) THEN
      ! Retry with new step size
      step_state%dt_current = step_state%optimal_dt
      RETURN
    END IF
    
    ! Advance time
    step_state%t_current = step_state%t_current + step_state%dt_current
    step_state%step_number = step_state%step_number + 1
    step_state%dt_current = step_state%optimal_dt
    
    ! Update old values
    state%u_old = state%u
    state%v_old = state%v
    state%a_old = state%a
    
    success = .TRUE.
  END SUBROUTINE NM_Time_Step_Accept
  
END MODULE NM_TimeInt_Adapt