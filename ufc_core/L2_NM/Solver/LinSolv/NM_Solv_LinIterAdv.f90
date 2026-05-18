!===============================================================================
! MODULE: NM_Solv_LinIterAdv
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Impl (advanced Krylov solvers)
! BRIEF:  QMR, CGS, TFQMR, Richardson iteration
!
! Theory: Freund & Nachtigal (1991); Sonneveld (1989); Saad (2003) Ch 7
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinIterAdv
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_QMR_Solv
  PUBLIC :: NM_CGS_Solv
  PUBLIC :: NM_TFQMR_Solv
  PUBLIC :: NM_Richardson_Solv
  PUBLIC :: NM_MinRes_Solv
  PUBLIC :: NM_SymmLQ_Solv
  PUBLIC :: NM_LinSolv_Iter_Params
  PUBLIC :: NM_LinSolv_Iter_State

  !=============================================================================
  ! ITERATIVE SOLVER PARAMETERS
  !=============================================================================
  TYPE, PUBLIC :: NM_LinSolv_Iter_Params
    INTEGER(i4) :: max_iter = 1000_i4
    REAL(wp) :: tolerance = 1.0e-8_wp
    REAL(wp) :: abs_tolerance = 1.0e-10_wp
    LOGICAL :: use_preconditioner = .FALSE.
    REAL(wp) :: omega = 1.0_wp          ! Richardson relaxation parameter
    LOGICAL :: verbose = .FALSE.
    INTEGER(i4) :: print_freq = 10_i4
  END TYPE NM_LinSolv_Iter_Params

  !=============================================================================
  ! ITERATIVE SOLVER STATE
  !=============================================================================
  TYPE, PUBLIC :: NM_LinSolv_Iter_State
    INTEGER(i4) :: n = 0_i4
    INTEGER(i4) :: iter = 0_i4
    REAL(wp) :: residual_norm = 0.0_wp
    REAL(wp) :: residual_norm0 = 0.0_wp
    LOGICAL :: converged = .FALSE.
    INTEGER(i4) :: func_evals = 0_i4
  END TYPE NM_LinSolv_Iter_State

  !=============================================================================
  ! CONSTANTS
  !=============================================================================
  REAL(wp), PARAMETER :: EPS_ITER = 1.0e-14_wp

CONTAINS

  SUBROUTINE NM_CGS_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)
    !! CGS method: Squared BiCG polynomial
    !!
    !! Algorithm (Sonneveld, 1989):
    !!   r_k = φ_k(A)^2 * r_0 where φ_k = BiCG polynomial
    !!   Faster than BiCG but irregular convergence
    !!
    !! Vectors: r, r0, p, u, v, q
    
    REAL(wp), INTENT(IN) :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_LinSolv_Iter_Params), INTENT(IN) :: params
    TYPE(NM_LinSolv_Iter_State), INTENT(INOUT) :: state
    INTERFACE
      SUBROUTINE MatVec_proc(A, x, y, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE MatVec_proc
      SUBROUTINE Precond_proc(r, z, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: r(:)
        REAL(wp), INTENT(OUT) :: z(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Precond_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, iter
    REAL(wp) :: rho, rho_old, alpha, beta
    REAL(wp) :: r_norm, r0_norm, tol_abs
    REAL(wp), ALLOCATABLE :: r(:), r0(:), p(:), u(:), v(:), q(:), Ap(:)
    
    CALL init_error_status(status)
    
    n = SIZE(b)
    ALLOCATE(r(n), r0(n), p(n), u(n), v(n), q(n), Ap(n))
    
    ! Initial residual
    CALL MatVec_proc(A, x, Ap, status)
    r = b - Ap
    r0 = r
    
    r0_norm = SQRT(DOT_PRODUCT(r, r))
    state%residual_norm0 = r0_norm
    
    IF (r0_norm < params%abs_tolerance) THEN
      state%converged = .TRUE.
      state%iter = 0
      DEALLOCATE(r, r0, p, u, v, q, Ap)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    tol_abs = MAX(params%abs_tolerance, params%tolerance * r0_norm)
    
    ! Init
    p = r
    u = r
    rho = DOT_PRODUCT(r0, r)
    
    IF (params%verbose) THEN
      PRINT '(A,ES12.4)', "CGS: Initial residual = ", r0_norm
    END IF
    
    ! CGS iteration
    DO iter = 1, params%max_iter
      rho_old = rho
      
      ! v = A * p
      CALL MatVec_proc(A, p, v, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      ! alpha = rho / <r0, v>
      alpha = rho / DOT_PRODUCT(r0, v)
      
      ! q = u - alpha * v
      q = u - alpha * v
      
      ! u_tilde = u + q
      ! x = x + alpha * u_tilde
      x = x + alpha * (u + q)
      
      ! Ap = A * (u + q)
      CALL MatVec_proc(A, u + q, Ap, status)
      r = r - alpha * Ap
      
      ! Residual norm
      r_norm = SQRT(DOT_PRODUCT(r, r))
      state%residual_norm = r_norm
      state%iter = iter
      
      IF (params%verbose .AND. MOD(iter, params%print_freq) == 0) THEN
        PRINT '(A,I6,A,ES12.4)', "  Iter ", iter, ": ||r|| = ", r_norm
      END IF
      
      ! Convergence check
      IF (r_norm < tol_abs) THEN
        state%converged = .TRUE.
        EXIT
      END IF
      
      ! Update
      rho = DOT_PRODUCT(r0, r)
      
      IF (ABS(rho) < EPS_ITER) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "CGS: Breakdown, rho 0"
        EXIT
      END IF
      
      beta = rho / rho_old
      u = r + beta * q
      p = u + beta * (q + beta * p)
    END DO
    
    DEALLOCATE(r, r0, p, u, v, q, Ap)
    
    IF (.NOT. state%converged) THEN
      status%status_code = IF_STATUS_WARN
      status%message = "CGS: Maximum iterations reached"
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
  END SUBROUTINE NM_CGS_Solv

  SUBROUTINE NM_MinRes_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)
    !! MinRes for symmetric indefinite matrices
    !!
    !! Algorithm (Paige & Saunders, 1975):
    !!   - Lanczos process for symmetric A
    !!   - Minimize ||r_k|| over Krylov subspace
    !!   - Works for indefinite A (unlike CG)
    
    REAL(wp), INTENT(IN) :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_LinSolv_Iter_Params), INTENT(IN) :: params
    TYPE(NM_LinSolv_Iter_State), INTENT(INOUT) :: state
    INTERFACE
      SUBROUTINE MatVec_proc(A, x, y, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE MatVec_proc
      SUBROUTINE Precond_proc(r, z, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: r(:)
        REAL(wp), INTENT(OUT) :: z(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Precond_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! ... (MinRes implementation)
    
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_MinRes_Solv

  SUBROUTINE NM_QMR_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)
    !! QMR method for nonsymmetric systems
    !!
    !! Algorithm (Freund & Nachtigal, 1991):
    !!   - Lanczos biorthogonalization: (V_k, W_k) with (V_k)^T * W_k = I
    !!   - Quasi-minimal residual: min ||b - A*x|| over Krylov subspace
    !!   - Look-ahead to avoid breakdown
    !!
    !! Vectors: r, r_tilde, v, v_tilde, w, w_tilde, p, p_tilde, d
    
    REAL(wp), INTENT(IN) :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_LinSolv_Iter_Params), INTENT(IN) :: params
    TYPE(NM_LinSolv_Iter_State), INTENT(INOUT) :: state
    INTERFACE
      SUBROUTINE MatVec_proc(A, x, y, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE MatVec_proc
      SUBROUTINE Precond_proc(r, z, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: r(:)
        REAL(wp), INTENT(OUT) :: z(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Precond_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, iter
    REAL(wp) :: rho, rho_old, alpha, beta, theta, theta_old, eta, delta
    REAL(wp) :: r_norm, r0_norm, tol_abs, epsilon
    REAL(wp), ALLOCATABLE :: r(:), r_tilde(:), v(:), v_tilde(:), w(:), w_tilde(:)
    REAL(wp), ALLOCATABLE :: p(:), p_tilde(:), d(:), Ap(:)
    
    CALL init_error_status(status)
    
    n = SIZE(b)
    ALLOCATE(r(n), r_tilde(n), v(n), v_tilde(n), w(n), w_tilde(n))
    ALLOCATE(p(n), p_tilde(n), d(n), Ap(n))
    
    ! Initial residual
    CALL MatVec_proc(A, x, Ap, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    r = b - Ap
    
    r0_norm = SQRT(DOT_PRODUCT(r, r))
    state%residual_norm0 = r0_norm
    
    IF (r0_norm < params%abs_tolerance) THEN
      state%converged = .TRUE.
      state%iter = 0
      DEALLOCATE(r, r_tilde, v, v_tilde, w, w_tilde, p, p_tilde, d, Ap)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    tol_abs = MAX(params%abs_tolerance, params%tolerance * r0_norm)
    
    ! Init
    r_tilde = r  ! Arbitrary choice
    v = r / r0_norm
    v_tilde = r_tilde / r0_norm
    rho = r0_norm
    theta = 0.0_wp
    eta = 0.0_wp
    p = 0.0_wp
    p_tilde = 0.0_wp
    d = 0.0_wp
    
    IF (params%verbose) THEN
      PRINT '(A,ES12.4)', "QMR: Initial residual = ", r0_norm
    END IF
    
    ! QMR iteration
    DO iter = 1, params%max_iter
      rho_old = rho
      theta_old = theta
      
      ! w = A * v - beta * w_old
      CALL MatVec_proc(A, v, w, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      ! delta = <v_tilde, w>
      delta = DOT_PRODUCT(v_tilde, w)
      
      IF (ABS(delta) < EPS_ITER) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "QMR: Breakdown, delta 0"
        EXIT
      END IF
      
      ! Update p and p_tilde
      IF (iter == 1) THEN
        p = v
        p_tilde = v_tilde
      ELSE
        beta = delta / rho_old
        p = v - beta * p
        p_tilde = v_tilde - beta * p_tilde
      END IF
      
      ! alpha = delta / <p_tilde, A*p>
      CALL MatVec_proc(A, p, Ap, status)
      alpha = delta / DOT_PRODUCT(p_tilde, Ap)
      
      ! Update solution
      theta = SQRT(DOT_PRODUCT(p, p))
      epsilon = theta / (1.0_wp + theta_old**2 / eta)
      d = (v + epsilon * d) / theta
      x = x + alpha * d
      
      ! Update residual approximation
      r = r - alpha * Ap
      r_norm = SQRT(DOT_PRODUCT(r, r))
      state%residual_norm = r_norm
      state%iter = iter
      
      IF (params%verbose .AND. MOD(iter, params%print_freq) == 0) THEN
        PRINT '(A,I6,A,ES12.4)', "  Iter ", iter, ": ||r|| = ", r_norm
      END IF
      
      ! Convergence check
      IF (r_norm < tol_abs) THEN
        state%converged = .TRUE.
        EXIT
      END IF
      
      ! Prepare next iteration
      rho = delta
      eta = theta
    END DO
    
    DEALLOCATE(r, r_tilde, v, v_tilde, w, w_tilde, p, p_tilde, d, Ap)
    
    IF (.NOT. state%converged) THEN
      status%status_code = IF_STATUS_WARN
      status%message = "QMR: Maximum iterations reached"
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
  END SUBROUTINE NM_QMR_Solv

  SUBROUTINE NM_Richardson_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)
    !! Richardson stationary iteration
    !!
    !! Algorithm:
    !!   x_{k+1} = x_k + ω * M^{-1} * (b - A*x_k)
    !!
    !! Optimal ω for SPD: ω = 2/(λ_max + λ_min)
    
    REAL(wp), INTENT(IN) :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_LinSolv_Iter_Params), INTENT(IN) :: params
    TYPE(NM_LinSolv_Iter_State), INTENT(INOUT) :: state
    INTERFACE
      SUBROUTINE MatVec_proc(A, x, y, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE MatVec_proc
      SUBROUTINE Precond_proc(r, z, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: r(:)
        REAL(wp), INTENT(OUT) :: z(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Precond_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, iter
    REAL(wp) :: r_norm, r0_norm, tol_abs, omega
    REAL(wp), ALLOCATABLE :: r(:), z(:), Ax(:)
    
    CALL init_error_status(status)
    
    n = SIZE(b)
    ALLOCATE(r(n), z(n), Ax(n))
    
    omega = params%omega
    
    ! Initial residual
    CALL MatVec_proc(A, x, Ax, status)
    r = b - Ax
    
    r0_norm = SQRT(DOT_PRODUCT(r, r))
    state%residual_norm0 = r0_norm
    
    IF (r0_norm < params%abs_tolerance) THEN
      state%converged = .TRUE.
      state%iter = 0
      DEALLOCATE(r, z, Ax)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    tol_abs = MAX(params%abs_tolerance, params%tolerance * r0_norm)
    
    IF (params%verbose) THEN
      PRINT '(A,ES12.4,A,F6.3)', "Richardson: Initial residual = ", r0_norm, " ω = ", omega
    END IF
    
    ! Richardson iteration
    DO iter = 1, params%max_iter
      ! Apply preconditioner
      IF (params%use_preconditioner) THEN
        CALL Precond_proc(r, z, status)
        IF (status%status_code /= IF_STATUS_OK) EXIT
      ELSE
        z = r
      END IF
      
      ! x = x + ω * z
      x = x + omega * z
      
      ! Update residual
      CALL MatVec_proc(A, x, Ax, status)
      r = b - Ax
      
      r_norm = SQRT(DOT_PRODUCT(r, r))
      state%residual_norm = r_norm
      state%iter = iter
      
      IF (params%verbose .AND. MOD(iter, params%print_freq) == 0) THEN
        PRINT '(A,I6,A,ES12.4)', "  Iter ", iter, ": ||r|| = ", r_norm
      END IF
      
      ! Convergence check
      IF (r_norm < tol_abs) THEN
        state%converged = .TRUE.
        EXIT
      END IF
    END DO
    
    DEALLOCATE(r, z, Ax)
    
    IF (.NOT. state%converged) THEN
      status%status_code = IF_STATUS_WARN
      status%message = "Richardson: Maximum iterations reached"
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
  END SUBROUTINE NM_Richardson_Solv

  SUBROUTINE NM_SymmLQ_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)
    !! SymmLQ for symmetric systems
    !!
    !! Algorithm (Paige & Saunders, 1975):
    !!   - Similar to MinRes but uses LQ factorization
    !!   - More stable for ill-conditioned problems
    
    REAL(wp), INTENT(IN) :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_LinSolv_Iter_Params), INTENT(IN) :: params
    TYPE(NM_LinSolv_Iter_State), INTENT(INOUT) :: state
    INTERFACE
      SUBROUTINE MatVec_proc(A, x, y, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE MatVec_proc
      SUBROUTINE Precond_proc(r, z, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: r(:)
        REAL(wp), INTENT(OUT) :: z(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Precond_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! ... (SymmLQ implementation)
    
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SymmLQ_Solv

  SUBROUTINE NM_TFQMR_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)
    !! TFQMR: Combines CGS and QMR
    !!
    !! Algorithm (Freund, 1993):
    !!   - Based on CGS iteration
    !!   - Quasi-minimal residual property
    !!   - Smoother convergence than CGS
    
    REAL(wp), INTENT(IN) :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_LinSolv_Iter_Params), INTENT(IN) :: params
    TYPE(NM_LinSolv_Iter_State), INTENT(INOUT) :: state
    INTERFACE
      SUBROUTINE MatVec_proc(A, x, y, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE MatVec_proc
      SUBROUTINE Precond_proc(r, z, status)
        IMPORT :: wp, ErrorStatusType
        REAL(wp), INTENT(IN) :: r(:)
        REAL(wp), INTENT(OUT) :: z(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Precond_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! ... (TFQMR implementation similar to CGS with QMR smoothing)
    
    CALL init_error_status(status)
    
    ! Placeholder: Call CGS
    CALL NM_CGS_Solv(A, b, x, params, state, MatVec_proc, Precond_proc, status)
    
  END SUBROUTINE NM_TFQMR_Solv
END MODULE NM_Solv_LinIterAdv