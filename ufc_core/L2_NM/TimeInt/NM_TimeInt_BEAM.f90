!===============================================================================
! MODULE: NM_TimeInt_BEAM
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — Time integration for BEAM elements (Wilson-θ/Newmark/HHT)
! BRIEF:  Wilson-theta, Newmark, HHT-alpha methods for beam dynamics
!===============================================================================
MODULE NM_TimeInt_BEAM
USE IF_Prec_Core, ONLY: wp, i4
USE L2_NM_Base
USE ErrorHandler

IMPLICIT NONE

! Module constants
REAL(wp), PARAMETER :: ONE   = 1.0_wp
REAL(wp), PARAMETER :: TWO   = 2.0_wp
REAL(wp), PARAMETER :: THREE = 3.0_wp
REAL(wp), PARAMETER :: FOUR  = 4.0_wp
REAL(wp), PARAMETER :: SIX   = 6.0_wp

! Method identifiers (ADINAM IOPE convention)
INTEGER(i4), PARAMETER :: METHOD_WILSON   = 1
INTEGER(i4), PARAMETER :: METHOD_NEWMARK  = 2
INTEGER(i4), PARAMETER :: METHOD_CD       = 3  ! Central Difference
INTEGER(i4), PARAMETER :: METHOD_HHT      = 4

! Public interfaces
PUBLIC :: L2_NM_TimeInt_BEAM_Init
PUBLIC :: L2_NM_TimeInt_BEAM_Predict
PUBLIC :: L2_NM_TimeInt_BEAM_Correct
PUBLIC :: L2_NM_TimeInt_BEAM_GetAcceleration
PUBLIC :: L2_NM_TimeInt_BEAM_GetVelocity
PUBLIC :: L2_NM_TimeInt_BEAM_ComputeEffectiveStiffness

! Type definitions
TYPE :: TimeInt_BEAM_Desc_Type
    ! Method selection (ADINAM IOPE)
    INTEGER(i4) :: method                 ! 1=Wilson, 2=Newmark, 3=CD, 4=HHT
    
    ! Time step parameters
    REAL(wp) :: dt                     ! Time step size
    REAL(wp) :: dt_initial            ! Initial time step
    REAL(wp) :: t_current             ! Current time
    REAL(wp) :: t_end                 ! End time
    INTEGER(i4) :: step_number           ! Current step number
    INTEGER(i4) :: max_steps             ! Maximum number of steps
    
    ! Wilson-θ parameters
    REAL(wp) :: theta                  ! Wilson parameter (default 1.4)
    
    ! Newmark parameters
    REAL(wp) :: beta                   ! Newmark β parameter
    REAL(wp) :: gamma                 ! Newmark γ parameter
    
    ! HHT-α parameters
    REAL(wp) :: alpha                 ! HHT α parameter (-1/3 <= α <= 0)
    
    ! Rayleigh damping
    REAL(wp) :: alpha_R               ! Mass-proportional damping α
    REAL(wp) :: beta_R                ! Stiffness-proportional damping β
    
    ! Convergence control
    INTEGER(i4) :: max_iterations
    REAL(wp) :: tolerance
    LOGICAL  :: adaptive_dt           ! Adaptive time stepping
END TYPE TimeInt_BEAM_Desc_Type

TYPE :: TimeInt_BEAM_State_Type
    ! Displacement, velocity, acceleration at time t
    REAL(wp) :: u_t(12)               ! Displacement
    REAL(wp) :: v_t(12)               ! Velocity
    REAL(wp) :: a_t(12)               ! Acceleration
    
    ! Quantities at time t+dt
    REAL(wp) :: u_tdt(12)             ! Displacement
    REAL(wp) :: v_tdt(12)             ! Velocity
    REAL(wp) :: a_tdt(12)             ! Acceleration
    
    ! Effective quantities for solving
    REAL(wp) :: u_eff(12)             ! Effective displacement
    REAL(wp) :: v_eff(12)             ! Effective velocity
    REAL(wp) :: a_eff(12)             ! Effective acceleration
    
    ! Residual quantities
    REAL(wp) :: R_ext(12)             ! External force
    REAL(wp) :: R_int(12)             ! Internal force
    REAL(wp) :: R_damp(12)            ! Damping force
    REAL(wp) :: R_inertia(12)         ! Inertia force
    REAL(wp) :: R_residual(12)        ! Total residual
    
    ! Energy metrics
    REAL(wp) :: kinetic_energy
    REAL(wp) :: potential_energy
    REAL(wp) :: total_energy
END TYPE TimeInt_BEAM_State_Type

TYPE :: TimeInt_BEAM_Algo_Type
    ! Integration constants (computed from dt and method parameters)
    ! Wilson-θ constants
    REAL(wp) :: a₀, a₁, a₂, a₃, a₄, a₅, a₆, a₇, a₈
    
    ! Newmark constants
    REAL(wp) :: b₀, b₁, b₂, b₃, b₄, b₅, b₆, b₇
    
    ! HHT constants
    REAL(wp) :: h₀, h₁, h₂, h₃, h₄
    
    ! Mass matrix related
    REAL(wp) :: mass_eff(12, 12)      ! Effective mass for solution
    LOGICAL  :: mass_lumped            ! Use lumped mass
    
    ! Damping matrix related
    REAL(wp) :: alpha_damp             ! Rayleigh α coefficient
    REAL(wp) :: beta_damp              ! Rayleigh β coefficient
    
    ! Iteration state
    INTEGER(i4) :: iteration
    LOGICAL  :: converged
    REAL(wp) :: residual_norm
END TYPE TimeInt_BEAM_Algo_Type

! Module-level state
TYPE(TimeInt_BEAM_Desc_Type),  SAVE :: g_desc
TYPE(TimeInt_BEAM_State_Type), SAVE :: g_state
TYPE(TimeInt_BEAM_Algo_Type),  SAVE :: g_algo

CONTAINS

! =============================================================================
! L2_NM_TimeInt_BEAM_Init
! =============================================================================
! Purpose: Initialize time integration scheme
!
! Based on ADINAM ADINI.for *MASTER-TIM_CTR card:
!   IOPE: Integration method
!   OPVAR(1): θ (Wilson) or β (Newmark)
!   OPVAR(2): γ (Newmark) or α (HHT)
! =============================================================================
SUBROUTINE L2_NM_TimeInt_BEAM_Init(&
    desc, state, algo, &
    dt, method, &
    theta, beta, gamma, alpha, &
    alpha_R, beta_R, &
    max_iter, tolerance, &
    status)
    
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(OUT) :: desc
    TYPE(TimeInt_BEAM_State_Type), INTENT(OUT) :: state
    TYPE(TimeInt_BEAM_Algo_Type),  INTENT(OUT) :: algo
    REAL(wp),                      INTENT(IN)  :: dt
    INTEGER(i4), INTENT(IN) :: method
    REAL(wp), OPTIONAL,           INTENT(IN)  :: theta
    REAL(wp), OPTIONAL,           INTENT(IN)  :: beta
    REAL(wp), OPTIONAL,           INTENT(IN)  :: gamma
    REAL(wp), OPTIONAL,           INTENT(IN)  :: alpha
    REAL(wp), OPTIONAL,           INTENT(IN)  :: alpha_R
    REAL(wp), OPTIONAL,           INTENT(IN)  :: beta_R
    INTEGER,  OPTIONAL,           INTENT(IN)  :: max_iter
    REAL(wp), OPTIONAL,           INTENT(IN)  :: tolerance
    TYPE(ErrorStatusType),        INTENT(OUT) :: status
    
    ! Set method
    desc%method = method
    desc%dt = dt
    desc%dt_initial = dt
    desc%t_current = ZERO
    desc%step_number = 0
    desc%max_steps = 10000
    desc%adaptive_dt = .FALSE.
    
    ! Default parameters based on method
    SELECT CASE (method)
    CASE (METHOD_WILSON)
        ! Wilson-θ method (default θ = 1.4 for unconditional stability)
        IF (PRESENT(theta)) THEN
            desc%theta = theta
        ELSE
            desc%theta = 1.4_wp
        END IF
        ! ADINAM: θ=0 auto-sets to 1.4
        IF (desc%theta == ZERO) desc%theta = 1.4_wp
        
        desc%beta = ZERO
        desc%gamma = ZERO
        desc%alpha = ZERO
        
    CASE (METHOD_NEWMARK)
        ! Newmark method
        IF (PRESENT(beta)) THEN
            desc%beta = beta
        ELSE
            ! Default: Average acceleration (unconditionally stable)
            desc%beta = 0.25_wp
        END IF
        IF (PRESENT(gamma)) THEN
            desc%gamma = gamma
        ELSE
            desc%gamma = 0.5_wp
        END IF
        ! ADINAM: β=0 or γ=0 auto-sets to defaults
        IF (desc%beta == ZERO) desc%beta = 0.25_wp
        IF (desc%gamma == ZERO) desc%gamma = 0.5_wp
        
        desc%theta = ZERO
        desc%alpha = ZERO
        
    CASE (METHOD_HHT)
        ! HHT-α method (generalized α)
        IF (PRESENT(alpha)) THEN
            desc%alpha = alpha
        ELSE
            ! Default: minimal numerical damping
            desc%alpha = -0.05_wp
        END IF
        IF (PRESENT(beta)) THEN
            desc%beta = beta
        ELSE
            desc%beta = 0.25_wp
        END IF
        IF (PRESENT(gamma)) THEN
            desc%gamma = gamma
        ELSE
            desc%gamma = 0.5_wp
        END IF
        
        desc%theta = ZERO
        
    CASE DEFAULT
        status%code = 1
        status%message = "Unknown time integration method"
        RETURN
    END SELECT
    
    ! Rayleigh damping
    IF (PRESENT(alpha_R)) THEN
        desc%alpha_R = alpha_R
    ELSE
        desc%alpha_R = ZERO
    END IF
    IF (PRESENT(beta_R)) THEN
        desc%beta_R = beta_R
    ELSE
        desc%beta_R = ZERO
    END IF
    
    ! Convergence control
    IF (PRESENT(max_iter)) THEN
        desc%max_iterations = max_iter
    ELSE
        desc%max_iterations = 15
    END IF
    IF (PRESENT(tolerance)) THEN
        desc%tolerance = tolerance
    ELSE
        desc%tolerance = 1.0e-6_wp
    END IF
    
    ! Initialize state
    state%u_t = ZERO
    state%v_t = ZERO
    state%a_t = ZERO
    state%u_tdt = ZERO
    state%v_tdt = ZERO
    state%a_tdt = ZERO
    state%R_ext = ZERO
    state%evo%R_int = ZERO
    state%R_damp = ZERO
    state%R_inertia = ZERO
    state%R_residual = ZERO
    
    ! Initialize algorithm
    CALL L2_NM_TimeInt_BEAM_UpdateConstants(desc, algo, status)
    
    algo%iteration = 0
    algo%converged = .FALSE.
    algo%residual_norm = ZERO
    algo%mass_lumped = .FALSE.
    algo%alpha_damp = desc%alpha_R
    algo%beta_damp = desc%beta_R
    
    status%code = 0
    status%message = "Time integration initialized"
    
END SUBROUTINE L2_NM_TimeInt_BEAM_Init

! =============================================================================
! L2_NM_TimeInt_BEAM_UpdateConstants
! =============================================================================
! Purpose: Update integration constants when dt or parameters change
! =============================================================================
SUBROUTINE L2_NM_TimeInt_BEAM_UpdateConstants(&
    desc, algo, status)
    
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(IN)  :: desc
    TYPE(TimeInt_BEAM_Algo_Type), INTENT(OUT) :: algo
    TYPE(ErrorStatusType),        INTENT(OUT) :: status
    
    REAL(wp) :: dt, dt2, dt3
    
    dt = desc%dt
    dt2 = dt * dt
    dt3 = dt2 * dt
    
    SELECT CASE (desc%method)
    
    CASE (METHOD_WILSON)
        ! Wilson-θ integration constants
        algo%a₀ = SIX / (desc%theta * desc%theta * dt2)
        algo%a₁ = THREE / (desc%theta * dt)
        algo%a₂ = TWO * algo%a₁
        algo%a₃ = desc%theta * dt / TWO
        algo%a₄ = algo%a₀ / desc%theta
        algo%a₅ = -algo%a₂
        algo%a₆ = ONE - THREE / desc%theta
        algo%a₇ = dt / TWO
        algo%a₈ = dt2 / TWO
        
    CASE (METHOD_NEWMARK)
        ! Newmark integration constants
        ! u_{t+dt} = u_t + dt*v_t + dt²*(β*a_{t+dt} + (0.5-β)*a_t)
        ! v_{t+dt} = v_t + dt*((1-γ)*a_t + γ*a_{t+dt})
        algo%b₀ = ONE / (desc%beta * dt2)
        algo%b₁ = desc%gamma / (desc%beta * dt)
        algo%b₂ = ONE / (desc%beta * dt)
        algo%b₃ = ONE / (TWO * desc%beta) - ONE
        algo%b₄ = desc%gamma / desc%beta - ONE
        algo%b₅ = dt * (desc%gamma / (TWO * desc%beta) - ONE)
        algo%b₆ = dt * (ONE - desc%gamma)
        algo%b₇ = desc%gamma * dt
        
    CASE (METHOD_HHT)
        ! HHT-α integration constants
        ! Modified equilibrium: R_{t+αdt} = (1-α)*R_{t+dt} + α*R_t - M*a - C*v
        algo%h₀ = ONE / (desc%beta * dt2)
        algo%h₁ = desc%gamma / (desc%beta * dt)
        algo%h₂ = desc%alpha
        algo%h₃ = ONE - desc%alpha
        algo%h₄ = (ONE - desc%alpha) * algo%h₀
        
    END SELECT
    
    status%code = 0
    
END SUBROUTINE L2_NM_TimeInt_BEAM_UpdateConstants

! =============================================================================
! L2_NM_TimeInt_BEAM_Predict
! =============================================================================
! Purpose: Predict displacement/velocity at new time step
!
! For implicit methods, predict initial values for Newton iteration
! =============================================================================
SUBROUTINE L2_NM_TimeInt_BEAM_Predict(&
    desc, state, algo, &
    u_predict, v_predict, &
    status)
    
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(IN)  :: desc
    TYPE(TimeInt_BEAM_State_Type),  INTENT(IN)  :: state
    TYPE(TimeInt_BEAM_Algo_Type),   INTENT(IN)  :: algo
    REAL(wp),                      INTENT(OUT) :: u_predict(12)
    REAL(wp),                      INTENT(OUT) :: v_predict(12)
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    
    REAL(wp) :: dt
    
    dt = desc%dt
    
    SELECT CASE (desc%method)
    
    CASE (METHOD_WILSON)
        ! Wilson-θ: Predict using current velocity and acceleration
        ! u* = u_t + dt*v_t + dt²/2 * a_t
        u_predict = state%u_t + dt * state%v_t + (dt*dt/TWO) * state%a_t
        ! v* = v_t + dt/2 * a_t
        v_predict = state%v_t + (dt/TWO) * state%a_t
        
    CASE (METHOD_NEWMARK)
        ! Newmark: Predict using constant average acceleration
        ! For average acceleration (β=0.25, γ=0.5): same as Wilson with θ=1
        u_predict = state%u_t + dt * state%v_t + (dt*dt/FOUR) * state%a_t
        v_predict = state%v_t + (dt/TWO) * state%a_t
        
    CASE (METHOD_HHT)
        ! HHT-α: Similar prediction
        u_predict = state%u_t + dt * state%v_t + (dt*dt/TWO) * state%a_t
        v_predict = state%v_t + dt * state%a_t
        
    END SELECT
    
    status%code = 0
    
END SUBROUTINE L2_NM_TimeInt_BEAM_Predict

! =============================================================================
! L2_NM_TimeInt_BEAM_Correct
! =============================================================================
! Purpose: Correct acceleration/velocity based on new displacement
!
! After solving for u_{t+dt}, compute v_{t+dt} and a_{t+dt}
! =============================================================================
SUBROUTINE L2_NM_TimeInt_BEAM_Correct(&
    desc, state, algo, &
    u_new, &
    a_new, v_new, &
    status)
    
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(IN)  :: desc
    TYPE(TimeInt_BEAM_State_Type),  INTENT(IN)  :: state
    TYPE(TimeInt_BEAM_Algo_Type),   INTENT(IN)  :: algo
    REAL(wp),                      INTENT(IN)  :: u_new(12)
    REAL(wp),                      INTENT(OUT) :: a_new(12)
    REAL(wp),                      INTENT(OUT) :: v_new(12)
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    
    REAL(wp) :: dt, dt2
    REAL(wp) :: u_t, v_t, a_t
    REAL(wp) :: du
    INTEGER(i4) :: i
    
    dt = desc%dt
    dt2 = dt * dt
    
    DO i = 1, 12
        u_t = state%u_t(i)
        v_t = state%v_t(i)
        a_t = state%a_t(i)
        du = u_new(i) - u_t
        
        SELECT CASE (desc%method)
        
        CASE (METHOD_WILSON)
            ! Correct acceleration from displacement increment
            ! a_{t+dt} = a₀ * (u_{t+dt} - u_t) - a₂*v_t - a₆*a_t
            a_new(i) = algo%a₀ * du - algo%a₂ * v_t - algo%a₆ * a_t
            
            ! Velocity from acceleration
            ! v_{t+dt} = v_t + a₇*(a_t + a_{t+dt})
            v_new(i) = v_t + algo%a₇ * (a_t + a_new(i))
            
        CASE (METHOD_NEWMARK)
            ! Correct acceleration
            ! a_{t+dt} = b₀*(u_{t+dt} - u_t) - b₂*v_t - b₃*a_t
            a_new(i) = algo%b₀ * du - algo%b₂ * v_t - algo%b₃ * a_t
            
            ! Velocity from acceleration
            ! v_{t+dt} = v_t + b₆*a_t + b₇*a_{t+dt}
            v_new(i) = v_t + algo%b₆ * a_t + algo%b₇ * a_new(i)
            
        CASE (METHOD_HHT)
            ! HHT-α correction
            a_new(i) = algo%h₀ * du - algo%h₁ * v_t - algo%h₃ * a_t
            v_new(i) = v_t + dt * ((ONE - algo%h₂) * a_new(i) + algo%h₂ * a_t)
            
        END SELECT
    END DO
    
    status%code = 0
    
END SUBROUTINE L2_NM_TimeInt_BEAM_Correct

! =============================================================================
! L2_NM_TimeInt_BEAM_ComputeEffectiveStiffness
! =============================================================================
! Purpose: Compute effective stiffness for implicit time integration
!
! K_eff = K + a₀*M + a₁*C  (for Wilson-θ)
! K_eff = K + b₀*M + b₁*C  (for Newmark)
! =============================================================================
SUBROUTINE L2_NM_TimeInt_BEAM_ComputeEffectiveStiffness(&
    desc, algo, &
    K_matrix, M_matrix, C_matrix, &
    K_eff, status)
    
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(IN)  :: desc
    TYPE(TimeInt_BEAM_Algo_Type),  INTENT(IN)  :: algo
    REAL(wp),                      INTENT(IN)  :: K_matrix(12, 12)
    REAL(wp),                      INTENT(IN)  :: M_matrix(12, 12)
    REAL(wp),                      INTENT(IN)  :: C_matrix(12, 12)
    REAL(wp),                      INTENT(OUT) :: K_eff(12, 12)
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    
    REAL(wp) :: a₀, a₁
    
    SELECT CASE (desc%method)
    
    CASE (METHOD_WILSON)
        a₀ = algo%a₀
        a₁ = algo%a₁
        ! K_eff = K + a₀*M + a₁*C
        K_eff = K_matrix + a₀ * M_matrix + a₁ * C_matrix
        
    CASE (METHOD_NEWMARK)
        a₀ = algo%b₀
        a₁ = algo%b₁
        ! K_eff = K + b₀*M + b₁*C
        K_eff = K_matrix + a₀ * M_matrix + a₁ * C_matrix
        
    CASE (METHOD_HHT)
        ! K_eff = (1-α)*K + h₀*M + h₁*C
        K_eff = (ONE - algo%h₂) * K_matrix + algo%h₀ * M_matrix + &
                algo%h₁ * C_matrix
        
    END SELECT
    
    status%code = 0
    
END SUBROUTINE L2_NM_TimeInt_BEAM_ComputeEffectiveStiffness

! =============================================================================
! L2_NM_TimeInt_BEAM_GetAcceleration
! =============================================================================
! Purpose: Compute acceleration from displacement increment (Wilson)
!
! For Wilson-θ method:
!   a_{t+θdt} = a₀ * (u_{t+θdt} - u_t) - a₂*v_t - a₆*a_t
! =============================================================================
SUBROUTINE L2_NM_TimeInt_BEAM_GetAcceleration(&
    desc, algo, state, &
    u_at_t, u_at_theta, &
    a_at_theta, status)
    
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(IN)  :: desc
    TYPE(TimeInt_BEAM_Algo_Type),  INTENT(IN)  :: algo
    TYPE(TimeInt_BEAM_State_Type),  INTENT(IN)  :: state
    REAL(wp),                      INTENT(IN)  :: u_at_t(12)
    REAL(wp),                      INTENT(IN)  :: u_at_theta(12)
    REAL(wp),                      INTENT(OUT) :: a_at_theta(12)
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    
    REAL(wp) :: dt, theta, a₀, a₂, a₆
    REAL(wp) :: du
    INTEGER(i4) :: i
    
    IF (desc%method /= METHOD_WILSON) THEN
        status%code = 1
        status%message = "GetAcceleration only valid for Wilson-θ method"
        RETURN
    END IF
    
    dt = desc%dt
    theta = desc%theta
    a₀ = algo%a₀
    a₂ = algo%a₂
    a₆ = algo%a₆
    
    DO i = 1, 12
        du = u_at_theta(i) - u_at_t(i)
        ! a_θ = a₀ * Δu_θ - a₂*v_t - a₆*a_t
        a_at_theta(i) = a₀ * du - a₂ * state%v_t(i) - a₆ * state%a_t(i)
    END DO
    
    status%code = 0
    
END SUBROUTINE L2_NM_TimeInt_BEAM_GetAcceleration

! =============================================================================
! L2_NM_TimeInt_BEAM_GetVelocity
! =============================================================================
! Purpose: Compute velocity from acceleration (Wilson)
!
! For Wilson-θ method:
!   v_{t+dt} = v_t + dt/2 * (a_t + a_{t+dt})
! =============================================================================
FUNCTION L2_NM_TimeInt_BEAM_GetVelocity(desc, algo, state, a_new) RESULT(v_new)
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(IN) :: desc
    TYPE(TimeInt_BEAM_Algo_Type),  INTENT(IN) :: algo
    TYPE(TimeInt_BEAM_State_Type), INTENT(IN) :: state
    REAL(wp),                      INTENT(IN) :: a_new(12)
    REAL(wp) :: v_new(12)
    
    REAL(wp) :: dt, a₇
    INTEGER(i4) :: i
    
    SELECT CASE (desc%method)
    CASE (METHOD_WILSON)
        dt = desc%dt
        a₇ = algo%a₇
        DO i = 1, 12
            v_new(i) = state%v_t(i) + a₇ * (state%a_t(i) + a_new(i))
        END DO
        
    CASE (METHOD_NEWMARK)
        dt = desc%dt
        DO i = 1, 12
            v_new(i) = state%v_t(i) + algo%b₆ * state%a_t(i) + algo%b₇ * a_new(i)
        END DO
        
    CASE DEFAULT
        v_new = state%v_t + desc%dt * state%a_t
    END SELECT
    
END FUNCTION L2_NM_TimeInt_BEAM_GetVelocity

! =============================================================================
! L2_NM_TimeInt_BEAM_ComputeDampingForce
! =============================================================================
! Purpose: Compute Rayleigh damping force vector
!
! C = α*M + β*K
! R_damp = C * v = α*M*v + β*K*v
! =============================================================================
SUBROUTINE L2_NM_TimeInt_BEAM_ComputeDampingForce(&
    desc, algo, &
    M_matrix, K_matrix, &
    velocity, &
    R_damp, status)
    
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(IN)  :: desc
    TYPE(TimeInt_BEAM_Algo_Type),  INTENT(IN)  :: algo
    REAL(wp),                      INTENT(IN)  :: M_matrix(12, 12)
    REAL(wp),                      INTENT(IN)  :: K_matrix(12, 12)
    REAL(wp),                      INTENT(IN)  :: velocity(12)
    REAL(wp),                      INTENT(OUT) :: R_damp(12)
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    
    ! R_damp = C * v = α*M*v + β*K*v
    R_damp = algo%alpha_damp * MATMUL(M_matrix, velocity) + &
             algo%beta_damp  * MATMUL(K_matrix, velocity)
    
    status%code = 0
    
END SUBROUTINE L2_NM_TimeInt_BEAM_ComputeDampingForce

! =============================================================================
! L2_NM_TimeInt_BEAM_Advance
! =============================================================================
! Purpose: Advance one time step
! =============================================================================
SUBROUTINE L2_NM_TimeInt_BEAM_Advance(&
    desc, state, algo, &
    dt_new, status)
    
    TYPE(TimeInt_BEAM_Desc_Type),  INTENT(INOUT) :: desc
    TYPE(TimeInt_BEAM_State_Type), INTENT(INOUT) :: state
    TYPE(TimeInt_BEAM_Algo_Type),  INTENT(INOUT) :: algo
    REAL(wp), OPTIONAL,            INTENT(IN)  :: dt_new
    TYPE(ErrorStatusType),          INTENT(OUT) :: status
    
    ! Update time
    IF (PRESENT(dt_new)) THEN
        IF (dt_new /= desc%dt) THEN
            desc%dt = dt_new
            CALL L2_NM_TimeInt_BEAM_UpdateConstants(desc, algo, status)
        END IF
    END IF
    
    desc%step_number = desc%step_number + 1
    desc%t_current = desc%t_current + desc%dt
    
    ! Shift state vectors
    state%u_t = state%u_tdt
    state%v_t = state%v_tdt
    state%a_t = state%a_tdt
    
    ! Reset iteration state
    algo%iteration = 0
    algo%converged = .FALSE.
    
    status%code = 0
    
END SUBROUTINE L2_NM_TimeInt_BEAM_Advance

END MODULE NM_TimeInt_BEAM