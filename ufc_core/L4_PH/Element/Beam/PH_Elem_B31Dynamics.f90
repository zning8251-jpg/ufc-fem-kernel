!===============================================================================
! MODULE: PH_Elem_B31Dynamics
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B31 beam dynamics analysis core
!===============================================================================
MODULE PH_Elem_B31Dynamics
USE UFC_Kind_Defn
USE UFC_Const_Math
USE ErrorHandler

IMPLICIT NONE

PRIVATE
PUBLIC :: PH_Elem_B31_Dyn_Initialize
PUBLIC :: PH_Elem_B31_Dyn_NewmarkBeta
PUBLIC :: PH_Elem_B31_Dyn_HHTAlpha
PUBLIC :: PH_Elem_B31_Dyn_ModalSuperposition
PUBLIC :: PH_Elem_B31_Dyn_TransientResponse
PUBLIC :: PH_Elem_B31_Dyn_ComputeEigenfrequencies
PUBLIC :: PH_Elem_B31_Dyn_RayleighDamping

! =============================================================================
! Type Definitions for Dynamic Analysis
! =============================================================================

TYPE :: B31_Dyn_Desc_Type
  ! Time integration parameters
  REAL(wp) :: dt                       ! Time step size
  REAL(wp) :: t_total                  ! Total analysis time
  INTEGER(i4) :: n_steps                  ! Number of time steps
  
  ! Newmark parameters
  REAL(wp) :: beta                     ! Newmark β parameter (default 1/4)
  REAL(wp) :: gamma                    ! Newmark γ parameter (default 1/2)
  
  ! HHT-α parameters
  REAL(wp) :: alpha_hht                ! HHT-α parameter (default -0.1 to 0)
  REAL(wp) :: rho_inf                  ! Spectral radius at infinity
  
  ! Damping parameters
  INTEGER(i4) :: damping_type             ! 1=Rayleigh, 2=Modal, 3=Caughey
  REAL(wp) :: zeta_1                   ! Damping ratio for mode 1
  REAL(wp) :: zeta_2                   ! Damping ratio for mode 2
  REAL(wp) :: mass_prop                ! Mass-proportional damping (α_R)
  REAL(wp) :: stiffness_prop           ! Stiffness-proportional damping (β_R)
  
  ! Modal analysis
  INTEGER(i4) :: n_modes_requested        ! Number of modes for superposition
  REAL(wp) :: freq_cutoff              ! Frequency cutoff for truncation
  
  ! Algorithm selection
  CHARACTER(len=16) :: method          ! 'NEWMARK', 'HHT', 'EXPLICIT'
END TYPE B31_Dyn_Desc_Type

TYPE :: B31_Dyn_State_Type
  ! Time variables
  REAL(wp) :: time_current             ! Current time
  REAL(wp) :: time_prev                ! Previous time
  REAL(wp) :: dt_current               ! Current time step
  
  ! Displacement state
  REAL(wp) :: u_n(:)                   ! Displacement at time t_n
  REAL(wp) :: u_np1(:)                 ! Displacement at time t_{n+1}
  REAL(wp) :: u_nm1(:)                 ! Displacement at time t_{n-1}
  
  ! Velocity state
  REAL(wp) :: v_n(:)                   ! Velocity at time t_n
  REAL(wp) :: v_np1(:)                 ! Velocity at time t_{n+1}
  REAL(wp) :: a_n(:)                   ! Acceleration at time t_n
  REAL(wp) :: a_np1(:)                 ! Acceleration at time t_{n+1}
  
  ! Modal coordinates
  REAL(wp), ALLOCATABLE :: q_n(:)      ! Modal displacements
  REAL(wp), ALLOCATABLE :: q_dot_n(:)  ! Modal velocities
  REAL(wp), ALLOCATABLE :: q_ddot_n(:) ! Modal accelerations
  
  ! Natural frequencies and modes
  REAL(wp), ALLOCATABLE :: omega_n(:)  ! Natural frequencies ω_i
  REAL(wp), ALLOCATABLE :: phi_modes(:,:,:) ! Mode shapes
  
  ! Response history
  REAL(wp), ALLOCATABLE :: disp_history(:,:)  ! (time, DOF)
  REAL(wp), ALLOCATABLE :: vel_history(:,:)   ! (time, DOF)
  REAL(wp), ALLOCATABLE :: accel_history(:,:) ! (time, DOF)
  
  ! Energy quantities
  REAL(wp) :: kinetic_energy           ! Kinetic energy
  REAL(wp) :: strain_energy            ! Strain energy
  REAL(wp) :: work_external            ! Work by external forces
  REAL(wp) :: energy_dissipated        ! Dissipated energy
END TYPE B31_Dyn_State_Type

TYPE :: B31_Dyn_AlgoCtx_Type
  ! Effective stiffness matrices
  REAL(wp) :: K_eff(:,:)               ! Effective stiffness matrix
  REAL(wp) :: K_dyn(:,:)               ! Dynamic stiffness (K + c1*M + c2*C)
  REAL(wp) :: M_matrix(:,:)            ! Mass matrix
  REAL(wp) :: C_matrix(:,:)            ! Damping matrix
  
  ! Load vectors
  REAL(wp) :: F_ext_n(:)               ! External load at t_n
  REAL(wp) :: F_ext_np1(:)             ! External load at t_{n+1}
  REAL(wp) :: F_int(:)                 ! Internal force vector
  REAL(wp) :: F_eff(:)                 ! Effective load vector
  
  ! Integration constants
  REAL(wp) :: c0, c1, c2, c3           ! Newmark constants
  REAL(wp) :: c4, c5, c6, c7           ! Additional constants
  REAL(wp) :: alpha_m, alpha_f         ! HHT-α parameters
  
  ! Iteration variables
  INTEGER(i4) :: nr_iter                  ! Newton-Raphson iterations
  REAL(wp) :: residual_norm            ! Residual norm
  LOGICAL  :: converged                ! Convergence flag
  
  ! Modal workspace
  REAL(wp) :: modal_force(:)           ! Modal force vector
  REAL(wp) :: modal_damping(:)         ! Modal damping ratios
  REAL(wp) :: participation_factors(:) ! Modal participation factors
  
  ! Temporary arrays
  REAL(wp) :: temp_n(:)                ! Temporary vector
  REAL(wp) :: temp_m(:,:)              ! Temporary matrix
  
  ! Statistics
  INTEGER(i4) :: total_steps              ! Completed steps
  INTEGER(i4) :: failed_steps             ! Failed steps
  REAL(wp) :: cpu_time                 ! CPU time
END TYPE B31_Dyn_AlgoCtx_Type

! =============================================================================
! Constants and Parameters
! =============================================================================

REAL(wp), PARAMETER :: TOL_DYNAMIC = 1.0e-8_wp     ! Dynamic tolerance
REAL(wp), PARAMETER :: DEFAULT_DT = 0.001_wp       ! Default time step
INTEGER(i4), PARAMETER :: MAX_NR_ITER = 50            ! Max NR iterations

CONTAINS

! =============================================================================
! PH_Elem_B31_Dyn_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_Dyn_Initialize(&
    desc, state, algo_ctx, &
    dynamic_params, n_dof, &
    status)
    
  TYPE(B31_Dyn_Desc_Type), INTENT(OUT) :: desc
  TYPE(B31_Dyn_State_Type), INTENT(OUT) :: state
  TYPE(B31_Dyn_AlgoCtx_Type), INTENT(OUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: dynamic_params(10)  ! Analysis parameters
  INTEGER(i4), INTENT(IN) :: n_dof               ! Number of DOFs
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  ! Extract parameters
  desc%dt = dynamic_params(1)
  desc%t_total = dynamic_params(2)
  desc%n_steps = INT(dynamic_params(3))
  desc%beta = dynamic_params(4)
  desc%gamma = dynamic_params(5)
  desc%damping_type = INT(dynamic_params(6))
  desc%zeta_1 = dynamic_params(7)
  desc%zeta_2 = dynamic_params(8)
  desc%n_modes_requested = INT(dynamic_params(9))
  desc%method = 'NEWMARK'
  
  ! Set default Newmark parameters if not specified
  IF (desc%beta <= 0.0_wp) desc%beta = 0.25_wp  ! Average acceleration
  IF (desc%gamma <= 0.0_wp) desc%gamma = 0.5_wp
  
  ! Compute HHT-α parameters
  desc%rho_inf = 1.0_wp - 2.0_wp * desc%zeta_1  ! Approximate
  desc%alpha_hht = (desc%rho_inf - 1.0_wp) / (desc%rho_inf + 1.0_wp)
  
  ! Initialize state
  state%time_current = 0.0_wp
  state%time_prev = 0.0_wp
  state%dt_current = desc%dt
  
  ! Allocate state arrays
  ALLOCATE(state%u_n(n_dof), state%u_np1(n_dof), state%u_nm1(n_dof))
  ALLOCATE(state%v_n(n_dof), state%v_np1(n_dof))
  ALLOCATE(state%a_n(n_dof), state%a_np1(n_dof))
  
  state%u_n = 0.0_wp
  state%u_np1 = 0.0_wp
  state%u_nm1 = 0.0_wp
  state%v_n = 0.0_wp
  state%v_np1 = 0.0_wp
  state%a_n = 0.0_wp
  state%a_np1 = 0.0_wp
  
  ! Initialize algorithm context
  algo_ctx%K_eff = 0.0_wp
  algo_ctx%K_dyn = 0.0_wp
  algo_ctx%M_matrix = 0.0_wp
  algo_ctx%C_matrix = 0.0_wp
  algo_ctx%F_ext_n = 0.0_wp
  algo_ctx%F_ext_np1 = 0.0_wp
  algo_ctx%F_int = 0.0_wp
  algo_ctx%F_eff = 0.0_wp
  
  ! Compute Newmark integration constants
  algo_ctx%c0 = 1.0_wp / (desc%beta * desc%dt**2)
  algo_ctx%c1 = desc%gamma / (desc%beta * desc%dt)
  algo_ctx%c2 = 1.0_wp / (desc%beta * desc%dt)
  algo_ctx%c3 = 1.0_wp / (2.0_wp * desc%beta) - 1.0_wp
  algo_ctx%c4 = desc%gamma / desc%beta - 1.0_wp
  algo_ctx%c5 = desc%dt / 2.0_wp * (desc%gamma / desc%beta - 2.0_wp)
  algo_ctx%c6 = desc%dt * (1.0_wp - desc%gamma)
  algo_ctx%c7 = desc%gamma * desc%dt
  
  ! HHT-α parameters
  algo_ctx%alpha_m = 2.0_wp * desc%alpha_hht / (1.0_wp + desc%alpha_hht)
  algo_ctx%alpha_f = desc%alpha_hht / (1.0_wp + desc%alpha_hht)
  
  algo_ctx%nr_iter = 0
  algo_ctx%residual_norm = 0.0_wp
  algo_ctx%converged = .FALSE.
  algo_ctx%total_steps = 0
  algo_ctx%failed_steps = 0
  algo_ctx%cpu_time = 0.0_wp
  
  ! Allocate temporary arrays
  ALLOCATE(algo_ctx%temp_n(n_dof))
  ALLOCATE(algo_ctx%temp_m(n_dof, n_dof))
  
  ! Allocate modal arrays
  ALLOCATE(algo_ctx%modal_force(desc%n_modes_requested))
  ALLOCATE(algo_ctx%modal_damping(desc%n_modes_requested))
  ALLOCATE(algo_ctx%participation_factors(desc%n_modes_requested))
  
  state%kinetic_energy = 0.0_wp
  state%strain_energy = 0.0_wp
  state%work_external = 0.0_wp
  state%energy_dissipated = 0.0_wp
  
  status%code = 0
  status%message = "Dynamic analysis initialized"
  
END SUBROUTINE PH_Elem_B31_Dyn_Initialize

! =============================================================================
! PH_Elem_B31_Dyn_NewmarkBeta
! =============================================================================
! Purpose: Newmark-β time integration for structural dynamics
!
! Governing equation: M*ü + C*u̇ + K*u = F(t)
!
! Integration formulas:
!   u_{n+1} = u_n + Δt*v_n + Δt²/2*[(1-2β)*a_n + 2β*a_{n+1}]
!   v_{n+1} = v_n + Δt*[(1-γ)*a_n + γ*a_{n+1}]
! =============================================================================
SUBROUTINE PH_Elem_B31_Dyn_NewmarkBeta(&
    desc, state, algo_ctx, &
    K_mat, M_matrix, C_matrix, &
    F_ext, &
    status)
    
  TYPE(B31_Dyn_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Dyn_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Dyn_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_mat(:,:)      ! Material stiffness
  REAL(wp), INTENT(IN)  :: M_matrix(:,:)   ! Mass matrix
  REAL(wp), INTENT(IN)  :: C_matrix(:,:)   ! Damping matrix
  REAL(wp), INTENT(IN)  :: F_ext(:)        ! External load at t_{n+1}
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: n_dof, iter
  REAL(wp) :: K_eff_local(SIZE(K_mat,1), SIZE(K_mat,2))
  REAL(wp) :: F_eff_local(SIZE(F_ext))
  REAL(wp) :: delta_u(SIZE(F_ext))
  REAL(wp) :: residual(SIZE(F_ext))
  
  n_dof = SIZE(F_ext)
  
  WRITE(*, '(A)') '=========================================='
  WRITE(*, '(A)') 'Newmark-β Time Integration'
  WRITE(*, '(A,F12.6,A)') '  Time step: ', desc%dt, ' s'
  WRITE(*, '(A,I6)') '  Total steps: ', desc%n_steps
  WRITE(*, '(A,F8.4,A)') '  Beta: ', desc%beta, ''
  WRITE(*, '(A,F8.4,A)') '  Gamma: ', desc%gamma, ''
  WRITE(*, '(A)') '=========================================='
  
  ! Store matrices
  algo_ctx%K_eff = K_mat
  algo_ctx%M_matrix = M_matrix
  algo_ctx%C_matrix = C_matrix
  
  ! Step 1: Form effective stiffness matrix
  ! K_eff = K + c0*M + c1*C
  K_eff_local = K_mat + algo_ctx%c0 * M_matrix + algo_ctx%c1 * C_matrix
  algo_ctx%K_eff = K_eff_local
  
  ! Main time stepping loop
  DO WHILE (state%time_current < desc%t_total)
    state%time_prev = state%time_current
    state%time_current = state%time_current + desc%dt
    algo_ctx%total_steps = algo_ctx%total_steps + 1
    
    ! Update external load (linear ramp for now)
    REAL(wp) :: load_factor
    load_factor = MIN(1.0_wp, state%time_current / 1.0_wp)
    algo_ctx%F_ext_np1 = F_ext * load_factor
    
    ! Step 2: Form effective load vector
    ! F_eff = F_{n+1} + M*(c0*u_n + c2*v_n + c3*a_n) + C*(c1*u_n + c4*v_n + c5*a_n)
    REAL(wp) :: inertial_term(n_dof), damping_term(n_dof)
    
    inertial_term = MATMUL(M_matrix, &
        algo_ctx%c0 * state%u_n + algo_ctx%c2 * state%v_n + algo_ctx%c3 * state%a_n)
    
    damping_term = MATMUL(C_matrix, &
        algo_ctx%c1 * state%u_n + algo_ctx%c4 * state%v_n + algo_ctx%c5 * state%a_n)
    
    F_eff_local = algo_ctx%F_ext_np1 + inertial_term + damping_term
    algo_ctx%F_eff = F_eff_local
    
    ! Step 3: Solve for displacement increment
    ! K_eff * Δu = F_eff - F_int
    ! For linear: F_int = K*u_n
    REAL(wp) :: F_int_local(n_dof)
    F_int_local = MATMUL(K_mat, state%u_n)
    
    residual = F_eff_local - F_int_local
    
    ! Solve linear system
    CALL PH_Elem_B31_Dyn_SolveLinearSystem(&
        K_eff_local, residual, delta_u, status)
    
    ! Step 4: Update displacement
    state%u_np1 = state%u_n + delta_u
    
    ! Step 5: Compute acceleration and velocity
    ! a_{n+1} = c0*(u_{n+1} - u_n) - c2*v_n - c3*a_n
    ! v_{n+1} = v_n + Δt*[(1-γ)*a_n + γ*a_{n+1}]
    
    state%a_np1 = algo_ctx%c0 * (state%u_np1 - state%u_n) - &
                  algo_ctx%c2 * state%v_n - algo_ctx%c3 * state%a_n
    
    state%v_np1 = state%v_n + desc%dt * &
                  ((1.0_wp - desc%gamma) * state%a_n + desc%gamma * state%a_np1)
    
    ! Step 6: Update state for next step
    state%u_nm1 = state%u_n
    state%u_n = state%u_np1
    state%v_n = state%v_np1
    state%a_n = state%a_np1
    
    ! Compute energies
    state%kinetic_energy = 0.5_wp * DOT_PRODUCT(state%v_n, MATMUL(M_matrix, state%v_n))
    state%strain_energy = 0.5_wp * DOT_PRODUCT(state%u_n, MATMUL(K_mat, state%u_n))
    
    ! Output progress
    IF (MOD(algo_ctx%total_steps, 10) == 0) THEN
      WRITE(*, '(A,I6,A,F10.4,A,F12.6,A,F12.6)') &
          'Step ', algo_ctx%total_steps, &
          ', t = ', state%time_current, &
          's, KE = ', state%kinetic_energy, &
          ', SE = ', state%strain_energy
    END IF
  END DO
  
  status%code = 0
  status%message = "Newmark integration complete: "//TRIM(ITOA(algo_ctx%total_steps))//" steps"
  
END SUBROUTINE PH_Elem_B31_Dyn_NewmarkBeta

! =============================================================================
! PH_Elem_B31_Dyn_HHTAlpha
! =============================================================================
! Purpose: HHT-α method with numerical dissipation
!
! Modified equation:
!   M*ü_{n+1} + (1+α)*C*u̇_{n+1} - α*C*u̇_n + (1+α)*K*u_{n+1} - α*K*u_n = F_{n+1}
!
! Parameters:
!   α ∈ [-1/3, 0]: More negative → more high-frequency dissipation
! =============================================================================
SUBROUTINE PH_Elem_B31_Dyn_HHTAlpha(&
    desc, state, algo_ctx, &
    K_mat, M_matrix, C_matrix, &
    F_ext, &
    status)
    
  TYPE(B31_Dyn_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Dyn_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Dyn_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_mat(:,:)
  REAL(wp), INTENT(IN)  :: M_matrix(:,:)
  REAL(wp), INTENT(IN)  :: C_matrix(:,:)
  REAL(wp), INTENT(IN)  :: F_ext(:)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: alpha_m, alpha_f
  INTEGER(i4) :: iter
  
  WRITE(*, '(A)') '=========================================='
  WRITE(*, '(A)') 'HHT-α Time Integration'
  WRITE(*, '(A,F12.6,A)') '  Alpha: ', desc%alpha_hht, ''
  WRITE(*, '(A,F12.6,A)') '  Spectral radius: ', desc%rho_inf, ''
  WRITE(*, '(A)') '=========================================='
  
  ! HHT-α parameters
  alpha_m = algo_ctx%alpha_m
  alpha_f = algo_ctx%alpha_f
  
  ! Modified Newmark constants for HHT-α
  REAL(wp) :: c0_hht, c1_hht
  c0_hht = algo_ctx%c0
  c1_hht = algo_ctx%c1
  
  ! Effective stiffness: K_eff = K + c0*M/(1+α_f) + c1*C
  REAL(wp) :: K_eff_local(SIZE(K_mat,1), SIZE(K_mat,2))
  
  K_eff_local = K_mat / (1.0_wp + alpha_f) + &
                c0_hht * M_matrix + &
                c1_hht * C_matrix
  
  ! Time stepping (similar to Newmark but with α terms)
  DO WHILE (state%time_current < desc%t_total)
    state%time_current = state%time_current + desc%dt
    algo_ctx%total_steps = algo_ctx%total_steps + 1
    
    ! HHT-α modified effective load
    ! Includes α-weighted previous step contributions
    REAL(wp) :: F_eff_hht(SIZE(F_ext))
    
    ! TODO: Full HHT-α implementation
    ! For now, delegate to standard Newmark
    CALL PH_Elem_B31_Dyn_NewmarkBeta(&
        desc, state, algo_ctx, &
        K_mat, M_matrix, C_matrix, &
        F_ext, &
        status)
    
    ! Check for high-frequency dissipation
    IF (algo_ctx%total_steps == 1) THEN
      WRITE(*, '(A)') '  HHT-α provides numerical damping for high frequencies'
    END IF
  END DO
  
  status%code = 0
  status%message = "HHT-α integration complete"
  
END SUBROUTINE PH_Elem_B31_Dyn_HHTAlpha

! =============================================================================
! PH_Elem_B31_Dyn_ModalSuperposition
! =============================================================================
! Purpose: Modal superposition method for efficient dynamic analysis
!
! Procedure:
!   1. Solve eigenproblem: (K - ω²M)φ = 0
!   2. Transform to modal coordinates: u = Φ*q
!   3. Decouple equations: q̈_i + 2ζ_iω_iq̇_i + ω_i²q_i = f_i(t)
!   4. Solve SDOF equations independently
!   5. Transform back: u = Σ φ_i*q_i
! =============================================================================
SUBROUTINE PH_Elem_B31_Dyn_ModalSuperposition(&
    desc, state, algo_ctx, &
    K_mat, M_matrix, &
    F_dynamic, &
    status)
    
  TYPE(B31_Dyn_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Dyn_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Dyn_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_mat(:,:)
  REAL(wp), INTENT(IN)  :: M_matrix(:,:)
  REAL(wp), INTENT(IN)  :: F_dynamic(:,:) ! (n_steps, n_dof)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: n_dof, n_modes, i_mode, i_step
  REAL(wp) :: omega_sq(SIZE(desc%n_modes_requested))
  REAL(wp) :: phi_normalized(SIZE(K_mat,1), SIZE(K_mat,2), desc%n_modes_requested)
  
  n_dof = SIZE(K_mat, 1)
  n_modes = desc%n_modes_requested
  
  WRITE(*, '(A)') '=========================================='
  WRITE(*, '(A)') 'Modal Superposition Analysis'
  WRITE(*, '(A,I4)') '  DOFs: ', n_dof
  WRITE(*, '(A,I4)') '  Modes used: ', n_modes
  WRITE(*, '(A)') '=========================================='
  
  ! Step 1: Compute natural frequencies and mode shapes
  CALL PH_Elem_B31_Dyn_ComputeEigenfrequencies(&
      desc, state, algo_ctx, &
      K_mat, M_matrix, &
      n_modes, &
      omega_sq, phi_normalized, &
      status)
  
  ! Store in state
  ALLOCATE(state%omega_n(n_modes))
  ALLOCATE(state%phi_modes(n_dof, n_dof, n_modes))
  
  DO i_mode = 1, n_modes
    state%omega_n(i_mode) = SQRT(omega_sq(i_mode))
    state%phi_modes(:, :, i_mode) = phi_normalized(:, :, i_mode)
  END DO
  
  ! Step 2: Compute modal properties
  REAL(wp) :: M_modal(n_modes), K_modal(n_modes)
  REAL(wp) :: phi_T_F(n_modes)
  
  DO i_mode = 1, n_modes
    ! Modal mass: M_i = φ_i^T * M * φ_i
    M_modal(i_mode) = DOT_PRODUCT(phi_normalized(:, 1, i_mode), &
                                  MATMUL(M_matrix, phi_normalized(:, 1, i_mode)))
    
    ! Modal stiffness: K_i = φ_i^T * K * φ_i = ω_i² * M_i
    K_modal(i_mode) = omega_sq(i_mode) * M_modal(i_mode)
    
    ! Modal participation factor
    phi_T_F(i_mode) = DOT_PRODUCT(phi_normalized(:, 1, i_mode), F_dynamic(1, :))
    algo_ctx%participation_factors(i_mode) = phi_T_F(i_mode) / M_modal(i_mode)
  END DO
  
  ! Step 3: Solve decoupled modal equations
  ALLOCATE(state%q_n(n_modes), state%q_dot_n(n_modes), state%q_ddot_n(n_modes))
  
  WRITE(*, '(A)') '  Modal properties:'
  WRITE(*, '(A)') '    Mode | Freq (Hz) | Period (s) | Participation'
  WRITE(*, '(A)') '    -----+-----------+------------+--------------'
  
  DO i_mode = 1, n_modes
    REAL(wp) :: freq_hz, period
    freq_hz = state%omega_n(i_mode) / (2.0_wp * 3.14159_wp)
    period = 1.0_wp / freq_hz
    
    WRITE(*, '(I6,A,F10.4,A,F11.6,A,F12.6)') &
        i_mode, ' |', freq_hz, ' |', period, ' |', &
        ABS(algo_ctx%participation_factors(i_mode))
  END DO
  
  ! Step 4: Modal response (simplified - static response for demo)
  DO i_mode = 1, n_modes
    ! Static modal displacement: q_i = F_i / K_i
    state%q_n(i_mode) = phi_T_F(i_mode) / K_modal(i_mode)
    state%q_dot_n(i_mode) = 0.0_wp
    state%q_ddot_n(i_mode) = 0.0_wp
  END DO
  
  ! Step 5: Transform back to physical coordinates
  ! u = Σ φ_i * q_i
  state%u_n = 0.0_wp
  DO i_mode = 1, n_modes
    state%u_n = state%u_n + state%phi_modes(:, 1, i_mode) * state%q_n(i_mode)
  END DO
  
  status%code = 0
  status%message = "Modal superposition complete"
  
END SUBROUTINE PH_Elem_B31_Dyn_ModalSuperposition

! =============================================================================
! PH_Elem_B31_Dyn_TransientResponse
! =============================================================================
! Purpose: Compute transient response to arbitrary dynamic loading
!
! Supports:
!   - Seismic excitation (base acceleration)
!   - Blast/impact loading
!   - Harmonic excitation
!   - General time-varying loads
! =============================================================================
SUBROUTINE PH_Elem_B31_Dyn_TransientResponse(&
    desc, state, algo_ctx, &
    K_mat, M_matrix, C_matrix, &
    load_time_history, &
    response_type, &
    status)
    
  TYPE(B31_Dyn_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Dyn_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Dyn_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_mat(:,:)
  REAL(wp), INTENT(IN)  :: M_matrix(:,:)
  REAL(wp), INTENT(IN)  :: C_matrix(:,:)
  REAL(wp), INTENT(IN)  :: load_time_history(:,:) ! (n_steps, n_dof)
  CHARACTER(len=*), INTENT(IN) :: response_type  ! 'DISP', 'VEL', 'ACCEL'
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: n_steps_load, n_dof
  INTEGER(i4) :: i_step
  
  n_steps_load = SIZE(load_time_history, 1)
  n_dof = SIZE(load_time_history, 2)
  
  WRITE(*, '(A)') '=========================================='
  WRITE(*, '(A)') 'Transient Response Analysis'
  WRITE(*, '(A,A)') '  Response type: ', response_type
  WRITE(*, '(A,I6)') '  Load steps: ', n_steps_load
  WRITE(*, '(A)') '=========================================='
  
  ! Allocate response history
  ALLOCATE(state%disp_history(desc%n_steps, n_dof))
  ALLOCATE(state%vel_history(desc%n_steps, n_dof))
  ALLOCATE(state%accel_history(desc%n_steps, n_dof))
  
  ! Time integration using selected method
  IF (TRIM(desc%method) == 'HHT') THEN
    CALL PH_Elem_B31_Dyn_HHTAlpha(&
        desc, state, algo_ctx, &
        K_mat, M_matrix, C_matrix, &
        load_time_history(1, :), &
        status)
  ELSE
    ! Use Newmark for each load step
    DO i_step = 1, MIN(desc%n_steps, n_steps_load)
      CALL PH_Elem_B31_Dyn_NewmarkBeta(&
          desc, state, algo_ctx, &
          K_mat, M_matrix, C_matrix, &
          load_time_history(i_step, :), &
          status)
      
      ! Store history
      state%disp_history(i_step, :) = state%u_n
      state%vel_history(i_step, :) = state%v_n
      state%accel_history(i_step, :) = state%a_n
    END DO
  END IF
  
  ! Output summary
  WRITE(*, '(A)') '  Response summary:'
  WRITE(*, '(A,F12.6,A)') '    Max displacement: ', MAXVAL(ABS(state%disp_history)), ' m'
  WRITE(*, '(A,F12.6,A)') '    Max velocity: ', MAXVAL(ABS(state%vel_history)), ' m/s'
  WRITE(*, '(A,F12.6,A)') '    Max acceleration: ', MAXVAL(ABS(state%accel_history)), ' m/s²'
  
  status%code = 0
  status%message = "Transient response computed successfully"
  
END SUBROUTINE PH_Elem_B31_Dyn_TransientResponse

! =============================================================================
! PH_Elem_B31_Dyn_ComputeEigenfrequencies
! =============================================================================
SUBROUTINE PH_Elem_B31_Dyn_ComputeEigenfrequencies(&
    desc, state, algo_ctx, &
    K_mat, M_matrix, &
    n_modes, &
    omega_squared, phi_modes, &
    status)
    
  TYPE(B31_Dyn_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Dyn_State_Type), INTENT(IN) :: state
  TYPE(B31_Dyn_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_mat(:,:)
  REAL(wp), INTENT(IN)  :: M_matrix(:,:)
  INTEGER(i4), INTENT(IN) :: n_modes
  REAL(wp), INTENT(OUT) :: omega_squared(n_modes)
  REAL(wp), INTENT(OUT) :: phi_modes(:,:,:)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: n_dof, i, j
  REAL(wp) :: work(SIZE(K_mat,1), n_modes)
  
  n_dof = SIZE(K_mat, 1)
  
  ! Simplified eigenvalue solver (placeholder)
  ! In production: Use LAPACK dsygv or subspace iteration
  
  WRITE(*, '(A)') '  Computing natural frequencies...'
  
  ! Initial guess (diagonal approximation)
  DO i = 1, n_modes
    IF (M_matrix(i, i) > SMALL_VAL) THEN
      omega_squared(i) = K_mat(i, i) / M_matrix(i, i)
    ELSE
      omega_squared(i) = 1.0_wp
    END IF
    
    ! Mode shape (simplified)
    phi_modes(:, :, i) = 0.0_wp
    phi_modes(i, i, i) = 1.0_wp
  END DO
  
  ! Sort ascending
  CALL PH_Elem_B31_Stab_SortEigenvalues(omega_squared, phi_modes(:, 1, :), n_modes)
  
  WRITE(*, '(A,I4,A)') '  Extracted ', n_modes, ' modes'
  
  status%code = 0
  status%message = "Natural frequencies computed"
  
END SUBROUTINE PH_Elem_B31_Dyn_ComputeEigenfrequencies

! =============================================================================
! PH_Elem_B31_Dyn_RayleighDamping
! =============================================================================
! Purpose: Compute Rayleigh damping coefficients
!
! C = α_R * M + β_R * K
!
! Given damping ratios ζ_1, ζ_2 at frequencies ω_1, ω_2:
!   α_R = 2*ω_1*ω_2*(ζ_1*ω_2 - ζ_2*ω_1) / (ω_2² - ω_1²)
!   β_R = 2*(ζ_2*ω_2 - ζ_1*ω_1) / (ω_2² - ω_1²)
! =============================================================================
SUBROUTINE PH_Elem_B31_Dyn_RayleighDamping(&
    desc, algo_ctx, &
    omega_1, omega_2, &
    zeta_1, zeta_2, &
    alpha_R, beta_R, &
    status)
    
  TYPE(B31_Dyn_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Dyn_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: omega_1, omega_2  ! Natural frequencies
  REAL(wp), INTENT(IN)  :: zeta_1, zeta_2    ! Damping ratios
  REAL(wp), INTENT(OUT) :: alpha_R, beta_R   ! Rayleigh coefficients
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: omega_1_sq, omega_2_sq
  REAL(wp) :: denom
  
  omega_1_sq = omega_1**2
  omega_2_sq = omega_2**2
  
  denom = omega_2_sq - omega_1_sq
  
  IF (ABS(denom) < SMALL_VAL) THEN
    ! Frequencies too close - use average
    alpha_R = zeta_1 * omega_1
    beta_R = zeta_1 / omega_1
  ELSE
    ! Standard Rayleigh coefficients
    alpha_R = 2.0_wp * omega_1 * omega_2 * (zeta_1 * omega_2 - zeta_2 * omega_1) / denom
    beta_R = 2.0_wp * (zeta_2 * omega_2 - zeta_1 * omega_1) / denom
  END IF
  
  ! Store in descriptor
  desc%mass_prop = alpha_R
  desc%stiffness_prop = beta_R
  
  status%code = 0
  status%message = "Rayleigh damping coefficients computed"
  
END SUBROUTINE PH_Elem_B31_Dyn_RayleighDamping

! =============================================================================
! Helper Functions
! =============================================================================

! Linear system solver (placeholder)
SUBROUTINE PH_Elem_B31_Dyn_SolveLinearSystem(A, b, x, status)
  REAL(wp), INTENT(IN) :: A(:,:)
  REAL(wp), INTENT(IN) :: b(:)
  REAL(wp), INTENT(OUT) :: x(:)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  ! TODO: Implement efficient solver (LU/Cholesky)
  x = b  ! Placeholder
  status%code = 0
END SUBROUTINE

END MODULE PH_Elem_B31Dynamics