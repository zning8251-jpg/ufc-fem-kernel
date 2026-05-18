!===============================================================================
! MODULE: PH_Elem_AcousticTransientSolv
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Proc
! BRIEF:  Newmark-beta time integration for transient acoustic
!===============================================================================
MODULE PH_Elem_AcousticTransientSolv
  USE IF_Prec_Core, ONLY: wp, i4
  USE UFC_Base_Types
  USE UFC_Error_Handler
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: PH_Acoustic_NewmarkBeta_SolveStep
  PUBLIC :: PH_Acoustic_NewmarkBeta_Init
  PUBLIC :: PH_Acoustic_NewmarkBeta_Parameters
  PUBLIC :: PH_Acoustic_Update_Speed_of_Sound      ! P5-1
  PUBLIC :: PH_Acoustic_Setup_Thermo_Coupling      ! P5-1
  PUBLIC :: PH_Acoustic_Frequency_Domain_Solve     ! P6-2
  PUBLIC :: GAUSSIAN_ELIMINATION                   ! Solver helper
  PUBLIC :: Solve_Linear_System_LAPACK            ! LAPACK wrapper
  PUBLIC :: sprintf                                  ! String formatting utility
  
  !===========================================================================
  ! CONSTANTS: Newmark-β parameters
  !===========================================================================
  REAL(wp), PARAMETER, PUBLIC :: PH_NEWMARK_BETA_DEFAULT_GAMMA = 0.5_wp      ! γ = 1/2 (average acceleration)
  REAL(wp), PARAMETER, PUBLIC :: PH_NEWMARK_BETA_DEFAULT_BETA  = 0.25_wp     ! β = 1/4 (unconditionally stable)
  REAL(wp), PARAMETER, PUBLIC :: PH_NEWMARK_BETA_EXPLICIT_GAMMA = 0.5_wp     ! γ = 1/2
  REAL(wp), PARAMETER, PUBLIC :: PH_NEWMARK_BETA_EXPLICIT_BETA  = 0.25_wp    ! β = 1/4
  
  !===========================================================================
  ! TYPE: PH_Acoustic_Newmark_Ctx
  !===========================================================================
  TYPE, PUBLIC :: PH_Acoustic_Newmark_Ctx
    !! Context type for Newmark-β transient solver
    !! Stores time integration parameters and state
    
    !-- Time stepping parameters
    REAL(wp) :: dt           ! Time step size [s]
    REAL(wp) :: dt_min       ! Minimum allowed time step [s]
    REAL(wp) :: dt_max       ! Maximum allowed time step [s]
    REAL(wp) :: t_current    ! Current time [s]
    REAL(wp) :: t_end        ! End time [s]
    INTEGER(i4) :: n_steps   ! Number of time steps
    
    !-- Newmark parameters
    REAL(wp) :: gamma        ! γ parameter (default: 0.5)
    REAL(wp) :: beta         ! β parameter (default: 0.25)
    
    !-- Integration constants (pre-computed for efficiency)
    REAL(wp) :: c0, c1, c2, c3, c4, c5  ! Newmark constants
    
    !-- Adaptive time stepping control (P3-9)
    LOGICAL :: adaptive      ! .TRUE. for adaptive time stepping
    REAL(wp) :: tol_local    ! Local error tolerance (default: 1.0e-3)
    REAL(wp) :: safety       ! Safety factor (default: 0.9)
    REAL(wp) :: beta_adapt   ! Step size adjustment exponent (default: 0.2)
    REAL(wp) :: eta_max      ! Max step size ratio (default: 5.0)
    REAL(wp) :: eta_min      ! Min step size ratio (default: 0.2)
    
    !-- Rollback control (P3-12)
    INTEGER(i4) :: max_rollback   ! Max consecutive rejections (default: 5)
    REAL(wp) :: dt_emergency    ! Emergency minimum dt (fallback)
    
    !-- HHT-α parameters (P3-14)
    LOGICAL :: use_hht          ! .TRUE. to enable HHT-α method
    REAL(wp) :: alpha_hht       ! α parameter for HHT (default: 0.0 = Newmark)
    REAL(wp) :: rho_inf         ! Spectral radius at infinity (controls high-freq dissipation)
    
    !-- Thermo-acoustic coupling (P5-1)
    LOGICAL :: use_thermo_coupling  ! .TRUE. to enable temperature-dependent acoustics
    REAL(wp) :: T_ref             ! Reference temperature T₀ [K]
    REAL(wp) :: c0_ref            ! Reference sound speed c₀ at T₀ [m/s]
    REAL(wp), POINTER :: T_field(:) ! Pointer to temperature field [K] (from thermal solver)
    
    !-- Convergence control
    REAL(wp) :: tol_nr       ! Newton-Raphson tolerance
    INTEGER(i4) :: max_iter_nr ! Max NR iterations
    
  END TYPE PH_Acoustic_Newmark_Ctx
  
  !===========================================================================
  ! TYPE: PH_Acoustic_Transient_State
  !===========================================================================
  TYPE, PUBLIC :: PH_Acoustic_Transient_State
    !! State variables for transient analysis
    
    !-- Solution vectors at current time step
    REAL(wp), ALLOCATABLE :: p(:)      ! Pressure [Pa]
    REAL(wp), ALLOCATABLE :: dp(:)     ! Velocity ṗ [Pa/s]
    REAL(wp), ALLOCATABLE :: ddp(:)    ! Acceleration p̈ [Pa/s²]
    
    !-- Solution vectors at next time step (n+1)
    REAL(wp), ALLOCATABLE :: p_np1(:)
    REAL(wp), ALLOCATABLE :: dp_np1(:)
    REAL(wp), ALLOCATABLE :: ddp_np1(:)
    
    !-- Predictors (for predictor-corrector scheme)
    REAL(wp), ALLOCATABLE :: p_pred(:)
    REAL(wp), ALLOCATABLE :: dp_pred(:)
    
    !-- Error estimation vectors (P3-9 adaptive time stepping)
    REAL(wp), ALLOCATABLE :: p_low_order(:)   ! Lower order solution (for error est.)
    REAL(wp), ALLOCATABLE :: local_error(:)   ! Local truncation error estimate
    
    !-- Rollback state (P3-12 for rejected step handling)
    REAL(wp), ALLOCATABLE :: p_old(:)         ! Saved state at t_n
    REAL(wp), ALLOCATABLE :: dp_old(:)        ! Saved velocity at t_n
    REAL(wp), ALLOCATABLE :: ddp_old(:)       ! Saved acceleration at t_n
    INTEGER(i4) :: rollback_count = 0_i4      ! Consecutive rejection counter
    
    !-- Residual and tangent
    REAL(wp), ALLOCATABLE :: residual(:)
    REAL(wp), ALLOCATABLE :: tangent(:,:)
    
    !-- External force
    REAL(wp), ALLOCATABLE :: F_ext(:)
    
    !-- Status
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: current_step = 0_i4
    REAL(wp) :: current_time = 0.0_wp
    REAL(wp) :: last_error_norm = 0.0_wp  ! Error norm from previous step
    
  END TYPE PH_Acoustic_Transient_State
  
CONTAINS
  
  !=============================================================================
  ! UTILITY: sprintf - Format string like C printf (Fortran 2003)
  !=============================================================================
  FUNCTION sprintf(fmt, var1, var2, var3, var4, var5) RESULT(str)
    CHARACTER(len=*), INTENT(IN) :: fmt
    REAL(wp), INTENT(IN), OPTIONAL :: var1, var2, var3, var4, var5
    CHARACTER(len=500) :: str
    CHARACTER(len=50) :: token
    INTEGER(i4) :: i, n
    REAL(wp) :: rvals(5)
    INTEGER(i4) :: idx
    rvals = [0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp]
    str = ''
    i = 1
    n = LEN_TRIM(fmt)
    idx = 1
    IF (PRESENT(var1)) rvals(1) = var1
    IF (PRESENT(var2)) rvals(2) = var2
    IF (PRESENT(var3)) rvals(3) = var3
    IF (PRESENT(var4)) rvals(4) = var4
    IF (PRESENT(var5)) rvals(5) = var5
    DO WHILE (i <= n)
      IF (fmt(i:i) == '%' .AND. i < n) THEN
        SELECT CASE (fmt(i+1:i+1))
        CASE ('g', 'G', 'f', 'F', 'e', 'E')
          WRITE(token, '(ES12.5)') rvals(idx)
          str = TRIM(str) // TRIM(ADJUSTL(token))
          idx = idx + 1
          i = i + 2
        CASE ('%')
          str = TRIM(str) // '%'
          i = i + 2
        CASE DEFAULT
          str = TRIM(str) // fmt(i:i)
          i = i + 1
        END SELECT
      ELSE
        str = TRIM(str) // fmt(i:i)
        i = i + 1
      END IF
    END DO
  END FUNCTION sprintf
  
  !=============================================================================
  ! SOLVER: GAUSSIAN_ELIMINATION (Standalone - P3 Critical)
  !=============================================================================
  SUBROUTINE GAUSSIAN_ELIMINATION(A, b, x, info)
    !! Simple Gaussian elimination with partial pivoting
    REAL(wp), INTENT(INOUT) :: A(:,:)
    REAL(wp), INTENT(INOUT) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(OUT) :: info
    INTEGER(i4) :: n, i, j, k
    REAL(wp) :: factor, pivot, temp
    n = SIZE(b)
    info = 0
    x = b
    DO k = 1, n-1
      pivot = ABS(A(k,k))
      DO i = k+1, n
        IF (ABS(A(i,k)) > pivot) THEN
          pivot = ABS(A(i,k))
          DO j = k, n
            temp = A(k,j); A(k,j) = A(i,j); A(i,j) = temp
          END DO
          temp = b(k); b(k) = b(i); b(i) = temp
          temp = x(k); x(k) = x(i); x(i) = temp
        END IF
      END DO
      IF (ABS(A(k,k)) < 1.0e-12_wp) THEN
        info = k
        RETURN
      END IF
      DO i = k+1, n
        factor = A(i,k) / A(k,k)
        DO j = k+1, n
          A(i,j) = A(i,j) - factor * A(k,j)
        END DO
        b(i) = b(i) - factor * b(k)
        x(i) = x(i) - factor * x(k)
      END DO
    END DO
    DO i = n, 1, -1
      temp = b(i)
      DO j = i+1, n
        temp = temp - A(i,j) * x(j)
      END DO
      x(i) = temp / A(i,i)
    END DO
  END SUBROUTINE GAUSSIAN_ELIMINATION
  
  !=============================================================================
  ! SOLVER: Solve_Linear_System_LAPACK (Production-ready - P3 Critical)
  !=============================================================================
  SUBROUTINE Solve_Linear_System_LAPACK(A, b, x, status)
    !! Solve A·x = b using LAPACK DGESV
    REAL(wp), INTENT(IN) :: A(:,:)
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: n, info, lda, ldb, nrhs
    INTEGER(i4), ALLOCATABLE :: ipiv(:)
    REAL(wp), ALLOCATABLE :: A_work(:,:), b_work(:)
    n = SIZE(b)
    lda = n; ldb = n; nrhs = 1
    ALLOCATE(ipiv(n))
    ALLOCATE(A_work(n,n), source=A)
    ALLOCATE(b_work(n), source=b)
    CALL DGESV(n, nrhs, A_work, lda, ipiv, b_work, ldb, info)
    IF (info == 0) THEN
      x = b_work
      CALL init_error_status(status, IF_STATUS_OK)
    ELSE
      x = 0.0_wp
      CALL init_error_status(status, STATUS_ERROR, &
           'LAPACK DGESV failed: info='//CHAR(48+MOD(info,10)))
    END IF
    DEALLOCATE(ipiv, A_work, b_work)
  END SUBROUTINE Solve_Linear_System_LAPACK
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_NewmarkBeta_Init
  !===========================================================================
  SUBROUTINE PH_Acoustic_NewmarkBeta_Init(ctx, dt, t_end, gamma_in, beta_in, &
       tol_nr_in, max_iter_nr_in, status)
    !! Initialize Newmark-β solver with parameters
    !!
    !! Theory: Pre-compute integration constants for efficiency
    !!   c0 = 1/(β·dt²)
    !!   c1 = γ/(β·dt)
    !!   c2 = 1/(β·dt)
    !!   c3 = 1/(2β) - 1
    !!   c4 = γ/β - 1
    !!   c5 = dt·(γ/(2β) - 1)
    
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(OUT) :: ctx
    REAL(wp), INTENT(IN) :: dt           ! Time step [s]
    REAL(wp), INTENT(IN) :: t_end        ! End time [s]
    REAL(wp), INTENT(IN), OPTIONAL :: gamma_in ! γ parameter
    REAL(wp), INTENT(IN), OPTIONAL :: beta_in  ! β parameter
    REAL(wp), INTENT(IN), OPTIONAL :: tol_nr_in ! NR tolerance
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_iter_nr_in ! Max NR iterations
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: gamma_val, beta_val
    
    !-- Default values
    gamma_val = PH_NEWMARK_BETA_DEFAULT_GAMMA
    beta_val  = PH_NEWMARK_BETA_DEFAULT_BETA
    
    IF (PRESENT(gamma_in)) gamma_val = gamma_in
    IF (PRESENT(beta_in))  beta_val  = beta_in
    
    !-- Validate parameters
    IF (dt <= 0.0_wp) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='PH_Acoustic_NewmarkBeta_Init: dt must be positive')
      RETURN
    END IF
    
    IF (beta_val <= 0.0_wp .OR. beta_val > 0.5_wp) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='PH_Acoustic_NewmarkBeta_Init: beta must be in [0, 0.5]')
      RETURN
    END IF
    
    IF (gamma_val < 0.5_wp .OR. gamma_val > 1.0_wp) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='PH_Acoustic_NewmarkBeta_Init: gamma must be in [0.5, 1.0]')
      RETURN
    END IF
    
    !-- Fill context
    ctx%dt         = dt
    ctx%t_current  = 0.0_wp
    ctx%t_end      = t_end
    ctx%n_steps    = INT(t_end / dt) + 1_i4
    ctx%gamma      = gamma_val
    ctx%beta       = beta_val
    ctx%tol_nr     = 1.0e-6_wp
    ctx%max_iter_nr = 100_i4
    
    IF (PRESENT(tol_nr_in)) ctx%tol_nr = tol_nr_in
    IF (PRESENT(max_iter_nr_in)) ctx%max_iter_nr = max_iter_nr_in
    
    !-- Adaptive time stepping defaults (P3-9)
    ctx%adaptive = .FALSE.
    ctx%tol_local = 1.0e-3_wp
    ctx%safety = 0.9_wp
    ctx%beta_adapt = 0.2_wp
    ctx%eta_max = 5.0_wp
    ctx%eta_min = 0.2_wp
    ctx%dt_min = dt / 100.0_wp
    ctx%dt_max = dt * 10.0_wp
    
    !-- Rollback control defaults (P3-12)
    ctx%max_rollback = 5_i4
    ctx%dt_emergency = ctx%dt_min / 10.0_wp
    
    !-- HHT-α defaults (P3-14)
    ctx%use_hht = .FALSE.
    ctx%alpha_hht = 0.0_wp
    ctx%rho_inf = 1.0_wp  ! No high-frequency dissipation by default
    
    !-- Pre-compute Newmark integration constants
    ctx%c0 = 1.0_wp / (ctx%beta * dt**2)
    ctx%c1 = ctx%gamma / (ctx%beta * dt)
    ctx%c2 = 1.0_wp / (ctx%beta * dt)
    ctx%c3 = 1.0_wp / (2.0_wp * ctx%beta) - 1.0_wp
    ctx%c4 = ctx%gamma / ctx%beta - 1.0_wp
    ctx%c5 = dt * (ctx%gamma / (2.0_wp * ctx%beta) - 1.0_wp)
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  END SUBROUTINE PH_Acoustic_NewmarkBeta_Init
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Transient_State_Init
  !===========================================================================
  SUBROUTINE PH_Acoustic_Transient_State_Init(state, n_dof, status)
    !! Allocate and initialize transient state vectors
    
    TYPE(PH_Acoustic_Transient_State), INTENT(OUT) :: state
    INTEGER(i4), INTENT(IN) :: n_dof       ! Number of DOFs
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    IF (n_dof <= 0) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='PH_Acoustic_Transient_State_Init: n_dof must be positive')
      RETURN
    END IF
    
    !-- Allocate all vectors
    ALLOCATE(state%p(n_dof), source=0.0_wp)
    ALLOCATE(state%dp(n_dof), source=0.0_wp)
    ALLOCATE(state%ddp(n_dof), source=0.0_wp)
    ALLOCATE(state%p_np1(n_dof), source=0.0_wp)
    ALLOCATE(state%dp_np1(n_dof), source=0.0_wp)
    ALLOCATE(state%ddp_np1(n_dof), source=0.0_wp)
    ALLOCATE(state%p_pred(n_dof), source=0.0_wp)
    ALLOCATE(state%dp_pred(n_dof), source=0.0_wp)
    ALLOCATE(state%p_low_order(n_dof), source=0.0_wp)  ! P3-9
    ALLOCATE(state%local_error(n_dof), source=0.0_wp)   ! P3-9
    ALLOCATE(state%p_old(n_dof), source=0.0_wp)         ! P3-12 rollback
    ALLOCATE(state%dp_old(n_dof), source=0.0_wp)        ! P3-12
    ALLOCATE(state%ddp_old(n_dof), source=0.0_wp)       ! P3-12
    ALLOCATE(state%residual(n_dof), source=0.0_wp)
    ALLOCATE(state%tangent(n_dof, n_dof), source=0.0_wp)
    ALLOCATE(state%F_ext(n_dof), source=0.0_wp)
    
    state%initialized = .TRUE.
    state%current_step = 0_i4
    state%current_time = 0.0_wp
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  END SUBROUTINE PH_Acoustic_Transient_State_Init
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_NewmarkBeta_SolveStep
  !===========================================================================
  SUBROUTINE PH_Acoustic_NewmarkBeta_SolveStep(ctx, state, Mass, Damping, Stiffness, &
       F_ext_np1, converged, status)
    !! Perform one time step using Newmark-β method (or HHT-α extension)
    !!
    !! Algorithm (Newmark):
    !!   1. Predictors: p* = p_n + dt·v_n + dt²·(1/2-β)·a_n
    !!                  v* = v_n + dt·(1-γ)·a_n
    !!   2. Solve effective system: K_eff · Δp = R_eff
    !!   3. Correctors: p_{n+1} = p* + Δp
    !!                  a_{n+1} = c0·(p_{n+1}-p*) - a_n
    !!                  v_{n+1} = v* + dt·γ·a_{n+1}
    !!
    !! Algorithm (HHT-α):
    !!   Modified momentum equation: (1-α)·a_{n+1} + α·a_n
    !!   Effective stiffness: K_eff = c0·M + c1·C + (1+α)·K
    !!   Residual: R_eff = (1+α)·F_{n+1} - α·F_n - C·v* - K·[(1+α)·p* - α·p_n]
    
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(INOUT) :: ctx
    TYPE(PH_Acoustic_Transient_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: Mass(:,:)        ! Mass matrix [n_dof,n_dof]
    REAL(wp), INTENT(IN) :: Damping(:,:)     ! Damping matrix [n_dof,n_dof]
    REAL(wp), INTENT(IN) :: Stiffness(:,:)   ! Stiffness matrix [n_dof,n_dof]
    REAL(wp), INTENT(IN) :: F_ext_np1(:)     ! External force at t_{n+1}
    LOGICAL, INTENT(OUT) :: converged        ! Convergence flag
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n_dof, iter
    REAL(wp) :: norm_res, norm_dp
    REAL(wp) :: alpha_hht, one_plus_alpha
    REAL(wp), ALLOCATABLE :: K_eff(:,:), R_eff(:)
    REAL(wp), ALLOCATABLE :: dp_corr(:)
    REAL(wp), ALLOCATABLE :: F_ext_n(:)  ! For HHT (force at t_n)
    
    !-- Check initialization
    IF (.NOT. state%initialized) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='PH_Acoustic_NewmarkBeta_SolveStep: state not initialized')
      converged = .FALSE.
      RETURN
    END IF
    
    n_dof = SIZE(state%p)
    converged = .FALSE.
    
    !-- Check dimensions
    IF (SIZE(Mass,1) /= n_dof .OR. SIZE(Damping,1) /= n_dof .OR. &
        SIZE(Stiffness,1) /= n_dof) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='PH_Acoustic_NewmarkBeta_SolveStep: dimension mismatch')
      RETURN
    END IF
    
    !=========================================================================
    ! STEP 0: SAVE STATE FOR ROLLBACK (P3-12)
    !=========================================================================
    CALL PH_Acoustic_Save_State(state)
    
    !=========================================================================
    ! HHT-α PARAMETER SETUP (P3-14)
    !=========================================================================
    IF (ctx%use_hht) THEN
      alpha_hht = ctx%alpha_hht
      one_plus_alpha = 1.0_wp + alpha_hht
      
      ! Allocate previous force for HHT
      ALLOCATE(F_ext_n(n_dof))
      F_ext_n = state%F_ext  ! Saved from previous step
    ELSE
      alpha_hht = 0.0_wp
      one_plus_alpha = 1.0_wp
    END IF
    
    !=========================================================================
    ! STEP 1: PREDICTORS (Newmark prediction formulas)
    !=========================================================================
    ! p* = p_n + dt·v_n + dt²·(1/2-β)·a_n
    ! v* = v_n + dt·(1-γ)·a_n
    
    state%p_pred = state%p + ctx%dt * state%dp + &
                   ctx%c5 * state%ddp
    
    state%dp_pred = state%dp + ctx%c4 * ctx%dt * state%ddp
    
    !=========================================================================
    ! STEP 2: EFFECTIVE STIFFNESS MATRIX
    !=========================================================================
    ! Newmark: K_eff = c0·M + c1·C + K
    ! HHT-α:   K_eff = c0·M + c1·C + (1+α)·K
    
    ALLOCATE(K_eff(n_dof, n_dof))
    K_eff = ctx%c0 * Mass + ctx%c1 * Damping + one_plus_alpha * Stiffness
    
    !=========================================================================
    ! STEP 3: EFFECTIVE RESIDUAL VECTOR
    !=========================================================================
    ! Newmark: R_eff = F_ext(t_{n+1}) - C·v* - K·p*
    ! HHT-α:   R_eff = (1+α)·F_{n+1} - α·F_n - C·v* - K·[(1+α)·p* - α·p_n]
    
    ALLOCATE(R_eff(n_dof))
    
    IF (ctx%use_hht) THEN
      ! HHT-α residual with weighted force and displacement
      R_eff = one_plus_alpha * F_ext_np1 - alpha_hht * F_ext_n &
              - MATMUL(Damping, state%dp_pred) &
              - MATMUL(Stiffness, one_plus_alpha * state%p_pred - alpha_hht * state%p)
    ELSE
      ! Standard Newmark residual
      R_eff = F_ext_np1 - MATMUL(Damping, state%dp_pred) &
                        - MATMUL(Stiffness, state%p_pred)
    END IF
    
    !=========================================================================
    ! STEP 4: SOLVE LINEAR SYSTEM
    !=========================================================================
    ! K_eff · Δp = R_eff
    
    ALLOCATE(dp_corr(n_dof))
    CALL SOLVE_LINEAR_SYSTEM(K_eff, R_eff, dp_corr, status)
    
    IF (status%status_code /= IF_STATUS_OK) THEN
      converged = .FALSE.
      RETURN
    END IF
    
    !=========================================================================
    ! STEP 5: CORRECTORS (Newmark correction formulas)
    !=========================================================================
    ! p_{n+1} = p* + Δp
    ! a_{n+1} = c0·(p_{n+1} - p*) - a_n
    ! v_{n+1} = v* + dt·γ·a_{n+1}
    
    state%p_np1 = state%p_pred + dp_corr
    state%ddp_np1 = ctx%c0 * dp_corr - state%ddp
    state%dp_np1 = state%dp_pred + ctx%dt * ctx%gamma * state%ddp_np1
    
    !=========================================================================
    ! STEP 6: UPDATE STATE
    !=========================================================================
    state%p = state%p_np1
    state%dp = state%dp_np1
    state%ddp = state%ddp_np1
    state%current_step = state%current_step + 1_i4
    state%current_time = state%current_time + ctx%dt
    
    ! Save current force for next step (HHT-α needs F_n)
    state%F_ext = F_ext_np1
    
    ! Check convergence (simple residual check)
    norm_res = SQRT(SUM(R_eff**2))
    converged = (norm_res < ctx%tol_nr)
    
    ! Reset rollback counter on successful step (P3-13)
    IF (converged) THEN
      CALL PH_Acoustic_Reset_Rollback_Counter(state)
    END IF
    
    ! Cleanup
    DEALLOCATE(K_eff, R_eff, dp_corr)
    IF (ctx%use_hht) THEN
      DEALLOCATE(F_ext_n)
    END IF
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  END SUBROUTINE PH_Acoustic_NewmarkBeta_SolveStep
  
  !=============================================================================
  ! SOLVER: SOLVE_LINEAR_SYSTEM (Wrapper)
  !=============================================================================
  SUBROUTINE SOLVE_LINEAR_SYSTEM(A, b, x, status)
    !! Solve A·x = b using Gaussian elimination (or LAPACK)
    REAL(wp), INTENT(IN) :: A(:,:)
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: n, info
    REAL(wp), ALLOCATABLE :: A_copy(:,:), b_copy(:)
    n = SIZE(b)
    IF (SIZE(A,1) /= n .OR. SIZE(A,2) /= n) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='SOLVE_LINEAR_SYSTEM: dimension mismatch')
      x = 0.0_wp
      RETURN
    END IF
    ALLOCATE(A_copy(n,n), source=A)
    ALLOCATE(b_copy(n), source=b)
    CALL GAUSSIAN_ELIMINATION(A_copy, b_copy, x, info)
    IF (info /= 0) THEN
      CALL init_error_status(status, STATUS_ERROR, &
           message='SOLVE_LINEAR_SYSTEM: singular matrix')
      x = 0.0_wp
      RETURN
    END IF
    CALL init_error_status(status, IF_STATUS_OK)
  END SUBROUTINE SOLVE_LINEAR_SYSTEM
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Compute_Local_Error (P3-9)
  !===========================================================================
  SUBROUTINE PH_Acoustic_Compute_Local_Error(state, ctx, error_norm, eta)
    !! Compute local truncation error estimate using embedded Newmark formulas
    !!
    !! Theory: Compare two solutions of different orders:
    !!   e_{n+1} = p_{n+1}^{high} - p_{n+1}^{low}
    !!   η = ||e||_2 / (tol · √n_dof)
    !!
    !! For acoustic systems:
    !!   - High order: standard Newmark-β (2nd order accurate)
    !!   - Low order: backward Euler (1st order accurate)
    !!   - Error estimator: e = p_{Newmark} - p_{Euler}
    
    TYPE(PH_Acoustic_Transient_State), INTENT(INOUT) :: state
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(IN) :: ctx
    REAL(wp), INTENT(OUT) :: error_norm
    REAL(wp), INTENT(OUT) :: eta  ! Normalized error indicator
    
    INTEGER(i4) :: n_dof, i
    REAL(wp) :: dt_sub, tol_scaled
    
    n_dof = SIZE(state%p)
    
    ! Allocate error vectors if not already done
    IF (.NOT. ALLOCATED(state%p_low_order)) THEN
      ALLOCATE(state%p_low_order(n_dof))
      ALLOCATE(state%local_error(n_dof))
    END IF
    
    !-------------------------------------------------------------------------
    ! Step 1: Compute lower-order solution (Backward Euler)
    !-------------------------------------------------------------------------
    !! Backward Euler: p_{n+1} = p_n + dt · v_{n+1}
    !! Approximate v_{n+1} ≈ v_n + dt · a_{n+1}
    !! So: p_{n+1}^{BE} = p_n + dt · (v_n + dt · a_{n+1})
    
    state%p_low_order = state%p + ctx%dt * (state%dp + ctx%dt * state%ddp_np1)
    
    !-------------------------------------------------------------------------
    ! Step 2: Compute local error estimate
    !-------------------------------------------------------------------------
    !! e = p_{Newmark} - p_{Backward Euler}
    
    DO i = 1, n_dof
      state%local_error(i) = state%p_np1(i) - state%p_low_order(i)
    END DO
    
    !-------------------------------------------------------------------------
    ! Step 3: Compute error norm
    !-------------------------------------------------------------------------
    error_norm = SQRT(SUM(state%local_error**2))
    
    ! Scale by tolerance and DOF count
    tol_scaled = ctx%tol_local * SQRT(REAL(n_dof, wp))
    
    ! Normalized error indicator
    IF (tol_scaled > 1.0e-12_wp) THEN
      eta = error_norm / tol_scaled
    ELSE
      eta = error_norm * 1.0e12_wp
    END IF
    
  END SUBROUTINE PH_Acoustic_Compute_Local_Error
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Adapt_Time_Step (P3-10)
  !===========================================================================
  SUBROUTINE PH_Acoustic_Adapt_Time_Step(ctx, eta, accepted, dt_new, status)
    !! Adaptive time step controller based on local error estimate
    !!
    !! Algorithm:
    !!   If η ≤ 1 (error acceptable):
    !!     dt_{new} = dt_{old} · min(η_max, max(η_min, safety · η^{-β}))
    !!     Accept step
    !!   Else (error too large):
    !!     dt_{new} = dt_{old} · max(η_min, safety · η^{-β})
    !!     Reject step, retry with smaller dt
    !!
    !! Parameters:
    !!   safety ∈ [0.8, 0.9] - Safety factor to avoid marginal steps
    !!   β ∈ [0.1, 0.25] - Adjustment exponent (smaller = smoother changes)
    !!   η_min, η_max - Limits on step size ratio (prevent drastic changes)
    
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: eta           ! Error indicator from current step
    LOGICAL, INTENT(OUT) :: accepted      ! .TRUE. if step is accepted
    REAL(wp), INTENT(OUT) :: dt_new       ! Suggested new time step
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: ratio, factor
    
    ! Default values
    IF (ctx%safety <= 0.0_wp .OR. ctx%safety > 1.0_wp) &
         ctx%safety = 0.9_wp
    IF (ctx%beta_adapt <= 0.0_wp .OR. ctx%beta_adapt > 0.5_wp) &
         ctx%beta_adapt = 0.2_wp
    IF (ctx%eta_max < 1.0_wp) ctx%eta_max = 5.0_wp
    IF (ctx%eta_min <= 0.0_wp .OR. ctx%eta_min >= 1.0_wp) &
         ctx%eta_min = 0.2_wp
    
    !-------------------------------------------------------------------------
    ! Case 1: Error acceptable (η ≤ 1)
    !-------------------------------------------------------------------------
    IF (eta <= 1.0_wp) THEN
      accepted = .TRUE.
      
      ! Compute optimal step size ratio
      ! dt_{opt} = dt_{current} · safety · η^{-β}
      IF (eta > 1.0e-12_wp) THEN
        factor = ctx%safety * eta**(-ctx%beta_adapt)
      ELSE
        ! Error essentially zero - can increase step aggressively
        factor = ctx%eta_max
      END IF
      
      ! Limit rate of change
      ratio = MAX(ctx%eta_min, MIN(ctx%eta_max, factor))
      
      dt_new = ctx%dt * ratio
      
    !-------------------------------------------------------------------------
    ! Case 2: Error too large (η > 1) - reject step
    !-------------------------------------------------------------------------
    ELSE
      accepted = .FALSE.
      
      ! Reduce step size
      ! dt_{new} = dt_{current} · safety · η^{-β}
      factor = ctx%safety * eta**(-ctx%beta_adapt)
      
      ! Limit reduction
      ratio = MAX(ctx%eta_min, factor)
      
      dt_new = ctx%dt * ratio
      
    END IF
    
    ! Enforce absolute bounds
    dt_new = MAX(ctx%dt_min, MIN(ctx%dt_max, dt_new))
    
    CALL init_error_status(status, IF_STATUS_OK)
    
  END SUBROUTINE PH_Acoustic_Adapt_Time_Step
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Save_State (P3-12)
  !===========================================================================
  SUBROUTINE PH_Acoustic_Save_State(state)
    !! Save current state for potential rollback
    !! Called at beginning of each time step
    
    TYPE(PH_Acoustic_Transient_State), INTENT(INOUT) :: state
    
    INTEGER(i4) :: n_dof
    
    n_dof = SIZE(state%p)
    
    ! Allocate rollback vectors if not already done
    IF (.NOT. ALLOCATED(state%p_old)) THEN
      ALLOCATE(state%p_old(n_dof))
      ALLOCATE(state%dp_old(n_dof))
      ALLOCATE(state%ddp_old(n_dof))
    END IF
    
    ! Save current state (at t_n)
    state%p_old = state%p
    state%dp_old = state%dp
    state%ddp_old = state%ddp
    
  END SUBROUTINE PH_Acoustic_Save_State
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Rollback_State (P3-12)
  !===========================================================================
  SUBROUTINE PH_Acoustic_Rollback_State(state, ctx, status)
    !! Rollback to saved state when step is rejected
    !! Restore p, dp, ddp to values at t_n
    
    TYPE(PH_Acoustic_Transient_State), INTENT(INOUT) :: state
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(IN) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    IF (.NOT. ALLOCATED(state%p_old)) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, "Rollback failed: no saved state")
      RETURN
    END IF
    
    ! Increment rollback counter
    state%rollback_count = state%rollback_count + 1_i4
    
    ! Check for excessive rollbacks
    IF (state%rollback_count > ctx%max_rollback) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           "Excessive rollbacks: exceeded max_rollback limit")
      RETURN
    END IF
    
    ! Restore state (rollback to t_n)
    state%p = state%p_old
    state%dp = state%dp_old
    state%ddp = state%ddp_old
    
    ! Reset predictors (will be recomputed with new dt)
    state%p_pred = 0.0_wp
    state%dp_pred = 0.0_wp
    
    CALL init_error_status(status, IF_STATUS_WARNING, &
         "Step rejected - rolled back to t_n")
    
  END SUBROUTINE PH_Acoustic_Rollback_State
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Reset_Rollback_Counter (P3-13)
  !===========================================================================
  SUBROUTINE PH_Acoustic_Reset_Rollback_Counter(state)
    !! Reset rollback counter after successful step
    
    TYPE(PH_Acoustic_Transient_State), INTENT(INOUT) :: state
    
    state%rollback_count = 0_i4
    
  END SUBROUTINE PH_Acoustic_Reset_Rollback_Counter
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_HHT_Parameters (P3-14)
  !===========================================================================
  SUBROUTINE PH_Acoustic_HHT_Parameters(ctx, rho_inf_in)
    !! Set HHT-α parameters based on spectral radius ρ_∞
    !!
    !! Theory: Hilber-Hughes-Taylor (1977) generalized α method
    !! Also known as: Generalized-α (Chung & Hulbert, 1993)
    !!
    !! Parameters:
    !!   ρ_∞ ∈ [0, 1] : Spectral radius at infinite frequency
    !!     - ρ_∞ = 1 : No numerical damping (Newmark-β)
    !!     - ρ_∞ = 0 : Maximum high-frequency dissipation
    !!     - Typical: ρ_∞ = 0.5-0.8
    !!
    !! Formulas (optimal high-frequency dissipation):
    !!   α = (ρ_∞ - 1) / (ρ_∞ + 1)
    !!   γ = 1/2 - α
    !!   β = (1 - α)² / 4
    !!
    !! Modified Newmark equations:
    !!   (1-α)·a_{n+1} + α·a_n appears in momentum equation
    !!   Displacement: u_{n+1} = u_n + dt·v_n + dt²·[(1/2-β)·a_n + β·a_{n+1}]
    
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: rho_inf_in  ! Spectral radius at ∞ (0 ≤ ρ_∞ ≤ 1)
    
    REAL(wp) :: alpha_opt
    
    ! Clamp ρ_∞ to valid range
    ctx%rho_inf = MAX(0.0_wp, MIN(1.0_wp, rho_inf_in))
    
    ! Optimal parameters for high-frequency dissipation
    alpha_opt = (ctx%rho_inf - 1.0_wp) / (ctx%rho_inf + 1.0_wp)
    
    ctx%alpha_hht = alpha_opt
    ctx%gamma = 0.5_wp - alpha_opt
    ctx%beta = (1.0_wp - alpha_opt)**2 / 4.0_wp
    
    ! Ensure stability limits
    ! γ ≥ 0.5, β ≥ (1/4)(γ + 1/2)²
    ctx%gamma = MAX(ctx%gamma, 0.5_wp)
    ctx%beta = MAX(ctx%beta, 0.25_wp * (ctx%gamma + 0.5_wp)**2)
    
    ctx%use_hht = .TRUE.
    
  END SUBROUTINE PH_Acoustic_HHT_Parameters
  
  !===========================================================================
  ! FUNCTION: Get_HHT_Alpha (P3-14)
  !===========================================================================
  PURE FUNCTION Get_HHT_Alpha(ctx) RESULT(alpha_eff)
    !! Get effective α for current step
    !! Returns α for weighted acceleration in momentum balance
    
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(IN) :: ctx
    REAL(wp) :: alpha_eff
    
    IF (ctx%use_hht) THEN
      alpha_eff = ctx%alpha_hht
    ELSE
      alpha_eff = 0.0_wp  ! Standard Newmark (no HHT modification)
    END IF
    
  END FUNCTION Get_HHT_Alpha
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Update_Speed_of_Sound (P5-1)
  !===========================================================================
  SUBROUTINE PH_Acoustic_Update_Speed_of_Sound(ctx, bulk_modulus, density, c_current, status)
    !! Update sound speed based on current temperature field
    !!
    !! Theory: For ideal gases and many fluids:
    !!   c(T) = c₀ · √(T/T₀)
    !! where:
    !!   c₀ = reference sound speed at T₀
    !!   T = current absolute temperature
    !!
    !! Applications:
    !!   - Thermo-acoustic engines
    !!   - High-intensity ultrasound (heating effects)
    !!   - Atmospheric/ocean acoustics with temperature gradients
    !!
    !! Status: P5-1 Thermo-acoustic coupling in transient solver
    
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: bulk_modulus   ! K [Pa]
    REAL(wp), INTENT(IN) :: density        ! ρ [kg/m³]
    REAL(wp), INTENT(OUT) :: c_current     ! Updated sound speed [m/s]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: T_avg, temp_ratio, c_adiabatic
    
    ! Default: no thermo-coupling, use adiabatic sound speed
    c_adiabatic = SQRT(bulk_modulus / density)
    
    IF (.NOT. ctx%use_thermo_coupling) THEN
      c_current = c_adiabatic
      CALL init_error_status(status, IF_STATUS_OK)
      RETURN
    END IF
    
    ! Check if temperature field is provided
    IF (.NOT. ASSOCIATED(ctx%T_field)) THEN
      ! Fallback to adiabatic sound speed
      c_current = c_adiabatic
      CALL init_error_status(status, IF_STATUS_WARNING, &
           "Thermo-coupling enabled but no temperature field - using adiabatic c")
      RETURN
    END IF
    
    ! Compute average temperature over domain
    T_avg = SUM(ctx%T_field) / REAL(SIZE(ctx%T_field), wp)
    
    ! Validate temperature (must be positive Kelvin)
    IF (T_avg <= 0.0_wp .OR. ctx%T_ref <= 0.0_wp) THEN
      c_current = c_adiabatic
      CALL init_error_status(status, IF_STATUS_WARNING, &
           "Invalid temperature - using adiabatic c")
      RETURN
    END IF
    
    ! Temperature-dependent sound speed: c(T) = c₀·√(T/T₀)
    temp_ratio = T_avg / ctx%T_ref
    c_current = ctx%c0_ref * SQRT(temp_ratio)
    
    ! Ensure physical bounds
    c_current = MAX(c_current, 0.1_wp * c_adiabatic)
    c_current = MIN(c_current, 10.0_wp * c_adiabatic)
    
    CALL init_error_status(status, IF_STATUS_OK, &
         sprintf("Updated c = %g m/s (T = %g K)", c_current, T_avg))
    
  END SUBROUTINE PH_Acoustic_Update_Speed_of_Sound
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Setup_Thermo_Coupling (P5-1)
  !===========================================================================
  SUBROUTINE PH_Acoustic_Setup_Thermo_Coupling(ctx, c0_ref_in, T_ref_in, T_field_ptr, status)
    !! Setup thermo-acoustic coupling parameters
    !!
    !! Usage:
    !!   CALL PH_Acoustic_Setup_Thermo_Coupling(ctx, c0=343.0_wp, T0=293.15_wp, &
    !!        T_field=thermal_solver%temperature, status)
    !!
    !! Parameters:
    !!   c0_ref = reference sound speed at T_ref [m/s]
    !!   T_ref = reference temperature [K]
    !!   T_field_ptr = pointer to temperature field array [K]
    !!
    !! Status: P5-1 Integration interface for thermal-acoustic coupling
    
    TYPE(PH_Acoustic_Newmark_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: c0_ref_in
    REAL(wp), INTENT(IN) :: T_ref_in
    REAL(wp), POINTER, INTENT(IN) :: T_field_ptr(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Validate inputs
    IF (c0_ref_in <= 0.0_wp) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           "Reference sound speed must be positive")
      RETURN
    END IF
    
    IF (T_ref_in <= 0.0_wp) THEN
      CALL init_error_status(status, IF_STATUS_ERROR, &
           "Reference temperature must be positive (Kelvin)")
      RETURN
    END IF
    
    ! Setup parameters
    ctx%use_thermo_coupling = .TRUE.
    ctx%c0_ref = c0_ref_in
    ctx%T_ref = T_ref_in
    ctx%T_field => T_field_ptr
    
    CALL init_error_status(status, IF_STATUS_OK, &
         sprintf("Thermo-coupling setup: c₀=%g m/s at T₀=%g K", c0_ref_in, T_ref_in))
    
  END SUBROUTINE PH_Acoustic_Setup_Thermo_Coupling
  
  !=============================================================================
  ! P6-2: UNIFIED FREQUENCY/TIME DOMAIN INTERFACE
  !=============================================================================
  
  TYPE, PUBLIC :: PH_Acoustic_Unified_Analysis_Ctx
    !! Unified context for both frequency and time domain acoustic analysis
    !!
    !! Design: Single interface for dual physics (P6-2)
    !!   - Frequency domain: Helmholtz equation (-ω²M + iωC + K)p = F
    !!   - Time domain: M·p̈ + C·ṗ + K·p = F(t)
    !!
    !! Shared data:
    !!   - Mass, Damping, Stiffness matrices
    !!   - Material properties (density, bulk modulus)
    !!   - Boundary conditions
    !!   - Thermo-acoustic coupling parameters
    !!
    !! Analysis-specific:
    !!   - Frequency: ω, n_freqs, complex arithmetic
    !!   - Time: dt, t_end, Newmark/HHT parameters
    
    !-- Common acoustic properties
    REAL(wp) :: density           ! ρ [kg/m³]
    REAL(wp) :: bulk_modulus      ! K [Pa]
    REAL(wp) :: sound_speed       ! c = √(K/ρ) [m/s]
    
    !-- Analysis type selector
    LOGICAL :: is_frequency_domain = .FALSE.  ! .TRUE.=freq, .FALSE.=time
    
    !-- Frequency domain parameters
    REAL(wp) :: omega             ! Angular frequency ω [rad/s]
    REAL(wp) :: frequency         ! Frequency f [Hz]
    INTEGER(i4) :: n_frequencies  ! Number of freq points for sweep
    REAL(wp), POINTER :: freq_array(:) => NULL() ! Frequency array [n_freqs]
    
    !-- Time domain parameters (embedded Newmark ctx)
    REAL(wp) :: dt                ! Time step [s]
    REAL(wp) :: t_end             ! End time [s]
    REAL(wp) :: gamma             ! Newmark γ
    REAL(wp) :: beta              ! Newmark β
    LOGICAL :: use_hht            ! HHT-α flag
    REAL(wp) :: rho_inf           ! Spectral radius
    
    !-- Thermo-acoustic coupling (shared)
    LOGICAL :: use_thermo_coupling
    REAL(wp) :: T_ref             ! Reference temperature [K]
    REAL(wp) :: c0_ref            ! Reference sound speed [m/s]
    REAL(wp), POINTER :: T_field(:) ! Temperature field [K]
    
    !-- Porous media (Biot theory) - shared
    LOGICAL :: use_porous_media
    REAL(wp) :: porosity          ! φ [0-1]
    REAL(wp) :: permeability      ! κ [m²]
    REAL(wp) :: tortuosity        ! τ
    
    !-- Absorbing boundary (PML/Sommerfeld) - shared
    LOGICAL :: use_pml            ! Perfectly Matched Layer
    LOGICAL :: use_sommerfeld     ! Sommerfeld radiation condition
    REAL(wp) :: pml_thickness     ! PML layer thickness [m]
    
  END TYPE PH_Acoustic_Unified_Analysis_Ctx
  
  !===========================================================================
  ! SUBROUTINE: PH_Acoustic_Frequency_Domain_Solve (P6-2)
  !===========================================================================
  SUBROUTINE PH_Acoustic_Frequency_Domain_Solve(ctx, Mass, Damping, Stiffness, &
       F_harmonic, omega, p_solution, status)
    !! Solve Helmholtz equation in frequency domain
    !!
    !! Theory: Harmonic assumption p(x,t) = p̂(x)·e^(iωt)
    !!   Wave equation becomes: (-ω²M + iωC + K)p̂ = F̂
    !! where:
    !!   M = mass matrix (1/K factor)
    !!   C = damping matrix (impedance)
    !!   K = stiffness matrix (gradient operator)
    !!   ω = angular frequency [rad/s]
    !!
    !! Applications:
    !!   - Steady-state harmonic response
    !!   - Frequency response functions (FRF)
    !!   - Modal analysis (undamped eigenvalue problem)
    !!   - Acoustic transfer vectors
    !!
    !! Status: P6-2 Unified frequency/time domain interface
    
    TYPE(PH_Acoustic_Unified_Analysis_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: Mass(:,:)        ! [n,n] Mass matrix
    REAL(wp), INTENT(IN) :: Damping(:,:)     ! [n,n] Damping matrix
    REAL(wp), INTENT(IN) :: Stiffness(:,:)   ! [n,n] Stiffness matrix
    COMPLEX(wp), INTENT(IN) :: F_harmonic(:) ! [n] Complex force vector
    REAL(wp), INTENT(IN) :: omega            ! Angular frequency [rad/s]
    COMPLEX(wp), INTENT(OUT) :: p_solution(:) ! [n] Complex pressure
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n_dof
    COMPLEX(wp) :: K_eff(:,:), R_eff(:)
    COMPLEX(wp) :: i_unit
    REAL(wp) :: omega_sq
    
    n_dof = SIZE(Mass, 1)
    i_unit = CMPLX(0.0_wp, 1.0_wp, wp)
    omega_sq = omega * omega
    
    ! Allocate effective system matrices
    ALLOCATE(K_eff(n_dof, n_dof))
    ALLOCATE(R_eff(n_dof))
    
    ! Helmholtz operator: H = -ω²M + iωC + K
    ! Note: For numerical stability, solve as:
    !   (K - ω²M + iωC) p̂ = F̂
    K_eff = Stiffness - omega_sq * Mass + i_unit * omega * Damping
    
    ! Right-hand side (harmonic force amplitude)
    R_eff = F_harmonic
    
    ! Solve complex linear system using LAPACK ZGESV (P6-2 Critical)
    CALL Solve_Complex_System_LAPACK(K_eff, R_eff, p_solution, n_dof, status)
    
    ! Update context with solution frequency
    ctx%omega = omega
    ctx%frequency = omega / (2.0_wp * PI)
    
    DEALLOCATE(K_eff, R_eff)
    
  END SUBROUTINE PH_Acoustic_Frequency_Domain_Solve
  
  !=============================================================================
  ! SOLVER: Solve_Complex_System_LAPACK (P6-2 Critical)
  !=============================================================================
  SUBROUTINE Solve_Complex_System_LAPACK(A, b, x, n, status)
    !! Solve complex linear system A·x = b using LAPACK ZGESV
    COMPLEX(wp), INTENT(INOUT) :: A(:,:)
    COMPLEX(wp), INTENT(IN) :: b(:)
    COMPLEX(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(IN) :: n
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: info, lda, ldb, nrhs
    INTEGER(i4), ALLOCATABLE :: ipiv(:)
    COMPLEX(wp), ALLOCATABLE :: A_work(:,:), b_work(:)
    lda = n; ldb = n; nrhs = 1
    ALLOCATE(ipiv(n))
    ALLOCATE(A_work(n,n), source=A)
    ALLOCATE(b_work(n), source=b)
    ! ZGESV: solves complex general linear system
    ! CALL ZGESV(N, NRHS, A, LDA, IPIV, B, LDB, INFO)
    CALL ZGESV(n, nrhs, A_work, lda, ipiv, b_work, ldb, info)
    IF (info == 0) THEN
      x = b_work
      CALL init_error_status(status, IF_STATUS_OK)
    ELSE
      x = CMPLX(0.0_wp, 0.0_wp, wp)
      CALL init_error_status(status, STATUS_ERROR, &
           'LAPACK ZGESV failed: info='//CHAR(48+MOD(info,10)))
    END IF
    DEALLOCATE(ipiv, A_work, b_work)
  END SUBROUTINE Solve_Complex_System_LAPACK
  
END MODULE PH_Elem_AcousticTransientSolv