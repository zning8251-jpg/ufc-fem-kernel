!===============================================================================
! MODULE: NM_Solv_LinIterBiCGSTAB
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Impl (BiCGSTAB solver)
! BRIEF:  BiCGSTAB for nonsymmetric systems: stabilized Bi-CG convergence
!
! Theory: van der Vorst (1992); Saad (2003) Ch 7.4
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinIterBiCGSTAB
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_BiCGSTAB_Solv
  PUBLIC :: NM_BiCGSTAB_Solv_Precond
  PUBLIC :: NM_BiCGSTAB_Params
  PUBLIC :: NM_BiCGSTAB_State
  
  ! Extended BiCGSTAB API (scope 1200-1249)
  PUBLIC :: NM_BiCGSTAB_RecoverFromBreakdown, NM_BiCGSTAB_GetResidualHistory
  PUBLIC :: NM_BiCGSTAB_AdaptiveParameters, NM_BiCGSTAB_GetStatistics

  !=============================================================================
  ! PARAMETERS TYPE
  !=============================================================================
  TYPE, PUBLIC :: NM_BiCGSTAB_Params
    INTEGER(i4) :: max_iter = 1000_i4     ! Maximum iterations
    REAL(wp) :: tolerance = 1.0e-8_wp     ! Convergence tolerance
    REAL(wp) :: breakdown_tol = 1.0e-30_wp ! Breakdown detection threshold
    LOGICAL :: verbose = .FALSE.          ! Print convergence history
    INTEGER(i4) :: print_every = 10_i4    ! Print frequency
  END TYPE NM_BiCGSTAB_Params

  !=============================================================================
  ! STATE TYPE (Output)
  !=============================================================================
  TYPE, PUBLIC :: NM_BiCGSTAB_State
    INTEGER(i4) :: num_iter = 0_i4        ! Actual iterations performed
    REAL(wp) :: final_residual = 0.0_wp   ! ||r_k|| / ||r_0||
    REAL(wp) :: initial_residual = 0.0_wp ! ||r_0||
    LOGICAL :: converged = .FALSE.        ! Convergence flag
    LOGICAL :: breakdown = .FALSE.        ! Breakdown detected
    CHARACTER(LEN=256) :: message = ""    ! Status message
  END TYPE NM_BiCGSTAB_State

CONTAINS

  SUBROUTINE MatVec_Product(A, x, y, SpMV_proc, status)
    REAL(wp), INTENT(IN)  :: A(:,:), x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    OPTIONAL :: SpMV_proc
    INTERFACE
      SUBROUTINE SpMV_proc(A, x, y, status)
        USE IF_Err_Brg, ONLY: ErrorStatusType
        USE IF_Prec_Core, ONLY: wp
        REAL(wp), INTENT(IN)  :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE SpMV_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (PRESENT(SpMV_proc)) THEN
      CALL SpMV_proc(A, x, y, status)
    ELSE
      ! Dense matrix-vector product
      y = MATMUL(A, x)
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE MatVec_Product

  SUBROUTINE NM_Bi_GetResidualHistory(state, residuals, num_residuals, status)
    TYPE(NM_BiCGSTAB_State), INTENT(IN) :: state
    REAL(wp), INTENT(OUT) :: residuals(:)
    INTEGER(i4), INTENT(OUT) :: num_residuals
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Simplified: return final residual
    num_residuals = 1
    residuals(1) = state%final_residual
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_BiCGSTAB_GetResidualHistory

  SUBROUTINE NM_Bi_RecoverFromBreakdown(r, r0_tilde, status)
    REAL(wp), INTENT(INOUT) :: r(:)
    REAL(wp), INTENT(INOUT) :: r0_tilde(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Recovery strategy: use current residual as new shadow residual
    r0_tilde = r
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_BiCGSTAB_RecoverFromBreakdown

  SUBROUTINE NM_BiCGSTAB_GetStatistics(state, stats, status)
    TYPE(NM_BiCGSTAB_State), INTENT(IN) :: state
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    WRITE(stats, '(A,I0,A,ES12.5,A,ES12.5,A,L1,A,L1)') &
      'BiCGSTAB Statistics: iterations=', state%num_iter, &
      ', initial_residual=', state%initial_residual, &
      ', final_residual=', state%final_residual, &
      ', converged=', state%converged, &
      ', breakdown=', state%breakdown
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_BiCGSTAB_GetStatistics

  SUBROUTINE NM_BiCGSTAB_Solv(A, b, x, params, state, SpMV_proc, status)
    !! BiCGSTAB solver for Ax = b (no preconditioning)
    !!
    !! Algorithm:
    !!   r0 = b - A*x0;  r0_tilde = r0;  rho0 = 1;  alpha = 1;  omega0 = 1;  p0 = 0;  v0 = 0
    !!   For k = 1, 2, ...
    !!     rho_k = <r0_tilde, r_{k-1}>
    !!     beta = (rho_k / rho_{k-1}) * (alpha / omega_{k-1})
    !!     p_k = r_{k-1} + beta * (p_{k-1} - omega_{k-1} * v_{k-1})
    !!     v_k = A * p_k
    !!     alpha = rho_k / <r0_tilde, v_k>
    !!     s = r_{k-1} - alpha * v_k
    !!     If ||s|| < tol: x_k = x_{k-1} + alpha * p_k; break
    !!     t = A * s
    !!     omega_k = <t, s> / <t, t>
    !!     x_k = x_{k-1} + alpha * p_k + omega_k * s
    !!     r_k = s - omega_k * t
    !!     Check: if |rho_k| < eps or |omega_k| < eps: breakdown
    
    REAL(wp), INTENT(IN)  :: A(:,:)         ! Coefficient matrix (dense for now)
    REAL(wp), INTENT(IN)  :: b(:)           ! Right-hand side
    REAL(wp), INTENT(INOUT) :: x(:)         ! Solution (initial guess on input)
    TYPE(NM_BiCGSTAB_Params), INTENT(IN) :: params
    TYPE(NM_BiCGSTAB_State), INTENT(OUT) :: state
    OPTIONAL :: SpMV_proc                   ! Optional sparse matvec procedure
    INTERFACE
      SUBROUTINE SpMV_proc(A, x, y, status)
        USE IF_Err_Brg, ONLY: ErrorStatusType
        USE IF_Prec_Core, ONLY: wp
        REAL(wp), INTENT(IN)  :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE SpMV_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, iter
    REAL(wp) :: rho, rho_old, alpha, beta, omega, omega_old
    REAL(wp) :: r_norm, r0_norm, s_norm, tol_abs
    REAL(wp) :: dot_r0v, dot_ts, dot_tt
    REAL(wp), ALLOCATABLE :: r(:), r0_tilde(:), p(:), v(:), s(:), t(:)
    LOGICAL :: breakdown_flag
    
    CALL init_error_status(status)
    
    ! Dimension checks
    n = SIZE(b)
    IF (SIZE(A, 1) /= n .OR. SIZE(A, 2) /= n .OR. SIZE(x) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_BiCGSTAB_Solv: Dimension mismatch"
      RETURN
    END IF
    
    ! Allocate workspace
    ALLOCATE(r(n), r0_tilde(n), p(n), v(n), s(n), t(n))
    
    ! Init vectors
    ! r0 = b - A*x0
    CALL MatVec_Product(A, x, r, SpMV_proc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    r = b - r
    
    r0_norm = SQRT(DOT_PRODUCT(r, r))
    state%initial_residual = r0_norm
    
    IF (r0_norm == 0.0_wp) THEN
      state%converged = .TRUE.
      state%num_iter = 0
      state%final_residual = 0.0_wp
      state%message = "BiCGSTAB: Initial guess is exact solution"
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! r0_tilde = r0 (shadow residual, arbitrary choice)
    r0_tilde = r
    
    ! Init scalars
    rho_old = 1.0_wp
    alpha = 1.0_wp
    omega_old = 1.0_wp
    
    ! Init vectors
    p = 0.0_wp
    v = 0.0_wp
    
    tol_abs = params%tolerance * r0_norm
    breakdown_flag = .FALSE.
    
    ! BiCGSTAB iteration loop
    DO iter = 1, params%max_iter
      ! rho_k = <r0_tilde, r_{k-1}>
      rho = DOT_PRODUCT(r0_tilde, r)
      
      ! Check breakdown: rho too small
      IF (ABS(rho) < params%breakdown_tol) THEN
        breakdown_flag = .TRUE.
        state%message = "BiCGSTAB: Breakdown (rho = 0)"
        EXIT
      END IF
      
      ! beta = (rho_k / rho_{k-1}) * (alpha / omega_{k-1})
      beta = (rho / rho_old) * (alpha / omega_old)
      
      ! p_k = r_{k-1} + beta * (p_{k-1} - omega_{k-1} * v_{k-1})
      p = r + beta * (p - omega_old * v)
      
      ! v_k = A * p_k
      CALL MatVec_Product(A, p, v, SpMV_proc, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      ! alpha = rho_k / <r0_tilde, v_k>
      dot_r0v = DOT_PRODUCT(r0_tilde, v)
      IF (ABS(dot_r0v) < params%breakdown_tol) THEN
        breakdown_flag = .TRUE.
        state%message = "BiCGSTAB: Breakdown (dot_r0v = 0)"
        EXIT
      END IF
      alpha = rho / dot_r0v
      
      ! s = r_{k-1} - alpha * v_k
      s = r - alpha * v
      
      ! Check early convergence: ||s|| < tol
      s_norm = SQRT(DOT_PRODUCT(s, s))
      IF (s_norm < tol_abs) THEN
        x = x + alpha * p
        r = s
        state%converged = .TRUE.
        state%message = "BiCGSTAB: Converged (s-convergence)"
        EXIT
      END IF
      
      ! t = A * s
      CALL MatVec_Product(A, s, t, SpMV_proc, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      ! omega_k = <t, s> / <t, t>
      dot_ts = DOT_PRODUCT(t, s)
      dot_tt = DOT_PRODUCT(t, t)
      IF (ABS(dot_tt) < params%breakdown_tol) THEN
        breakdown_flag = .TRUE.
        state%message = "BiCGSTAB: Breakdown (dot_tt = 0)"
        EXIT
      END IF
      omega = dot_ts / dot_tt
      
      ! Check breakdown: omega too small
      IF (ABS(omega) < params%breakdown_tol) THEN
        breakdown_flag = .TRUE.
        state%message = "BiCGSTAB: Breakdown (omega = 0)"
        EXIT
      END IF
      
      ! x_k = x_{k-1} + alpha * p_k + omega_k * s
      x = x + alpha * p + omega * s
      
      ! r_k = s - omega_k * t
      r = s - omega * t
      
      ! Check convergence
      r_norm = SQRT(DOT_PRODUCT(r, r))
      
      IF (params%verbose .AND. MOD(iter, params%print_every) == 0) THEN
        PRINT '(A,I6,A,ES12.4)', "BiCGSTAB iter=", iter, " residual=", r_norm/r0_norm
      END IF
      
      IF (r_norm < tol_abs) THEN
        state%converged = .TRUE.
        state%message = "BiCGSTAB: Converged"
        EXIT
      END IF
      
      ! Update for next iteration
      rho_old = rho
      omega_old = omega
    END DO
    
    ! Finalize state
    state%num_iter = iter
    state%final_residual = r_norm / r0_norm
    state%breakdown = breakdown_flag
    
    IF (.NOT. state%converged .AND. .NOT. breakdown_flag) THEN
      state%message = "BiCGSTAB: Maximum iterations reached without convergence"
      status%status_code = IF_STATUS_WARN
    ELSE IF (breakdown_flag) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
    DEALLOCATE(r, r0_tilde, p, v, s, t)
    
  END SUBROUTINE NM_BiCGSTAB_Solv

  SUBROUTINE NM_BiCGSTAB_Solv_Precond(A, M, b, x, params, state, SpMV_proc, Prec_proc, status)
    !! Preconditioned BiCGSTAB: Solves M^{-1}*A*x = M^{-1}*b
    !!
    !! Modified algorithm with left preconditioning:
    !!   - Replace r with M^{-1}*r at each step
    !!   - Requires preconditioner solve: M*z = r z
    
    REAL(wp), INTENT(IN)  :: A(:,:)  ! Coefficient matrix
    REAL(wp), INTENT(IN)  :: M(:,:)  ! Preconditioner matrix (or factors)
    REAL(wp), INTENT(IN)  :: b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_BiCGSTAB_Params), INTENT(IN) :: params
    TYPE(NM_BiCGSTAB_State), INTENT(OUT) :: state
    OPTIONAL :: SpMV_proc, Prec_proc
    INTERFACE
      SUBROUTINE SpMV_proc(A, x, y, status)
        USE IF_Err_Brg, ONLY: ErrorStatusType
        USE IF_Prec_Core, ONLY: wp
        REAL(wp), INTENT(IN)  :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE SpMV_proc
      SUBROUTINE Prec_proc(M, r, z, status)
        USE IF_Err_Brg, ONLY: ErrorStatusType
        USE IF_Prec_Core, ONLY: wp
        REAL(wp), INTENT(IN)  :: M(:,:), r(:)
        REAL(wp), INTENT(OUT) :: z(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Prec_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, iter
    REAL(wp) :: rho, rho_old, alpha, beta, omega, omega_old
    REAL(wp) :: r_norm, r0_norm, s_norm, tol_abs
    REAL(wp) :: dot_r0v, dot_ts, dot_tt
    REAL(wp), ALLOCATABLE :: r(:), r0_tilde(:), p(:), v(:), s(:), t(:)
    REAL(wp), ALLOCATABLE :: z(:), y(:)
    LOGICAL :: breakdown_flag
    
    CALL init_error_status(status)
    
    n = SIZE(b)
    ALLOCATE(r(n), r0_tilde(n), p(n), v(n), s(n), t(n), z(n), y(n))
    
    ! r0 = b - A*x0
    CALL MatVec_Product(A, x, r, SpMV_proc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    r = b - r
    
    r0_norm = SQRT(DOT_PRODUCT(r, r))
    state%initial_residual = r0_norm
    
    IF (r0_norm == 0.0_wp) THEN
      state%converged = .TRUE.
      state%num_iter = 0
      state%final_residual = 0.0_wp
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! r0_tilde = M^{-1} * r0
    CALL Precond_Solv(M, r, r0_tilde, Prec_proc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    rho_old = 1.0_wp
    alpha = 1.0_wp
    omega_old = 1.0_wp
    p = 0.0_wp
    v = 0.0_wp
    
    tol_abs = params%tolerance * r0_norm
    breakdown_flag = .FALSE.
    
    ! Preconditioned BiCGSTAB loop
    DO iter = 1, params%max_iter
      ! z = M^{-1} * r
      CALL Precond_Solv(M, r, z, Prec_proc, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      rho = DOT_PRODUCT(r0_tilde, z)
      
      IF (ABS(rho) < params%breakdown_tol) THEN
        breakdown_flag = .TRUE.
        EXIT
      END IF
      
      beta = (rho / rho_old) * (alpha / omega_old)
      p = z + beta * (p - omega_old * v)
      
      ! v = A * p
      CALL MatVec_Product(A, p, v, SpMV_proc, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      dot_r0v = DOT_PRODUCT(r0_tilde, v)
      IF (ABS(dot_r0v) < params%breakdown_tol) THEN
        breakdown_flag = .TRUE.
        EXIT
      END IF
      alpha = rho / dot_r0v
      
      s = r - alpha * v
      s_norm = SQRT(DOT_PRODUCT(s, s))
      
      IF (s_norm < tol_abs) THEN
        x = x + alpha * p
        r = s
        state%converged = .TRUE.
        EXIT
      END IF
      
      ! y = M^{-1} * s
      CALL Precond_Solv(M, s, y, Prec_proc, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      ! t = A * y
      CALL MatVec_Product(A, y, t, SpMV_proc, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      dot_ts = DOT_PRODUCT(t, y)
      dot_tt = DOT_PRODUCT(t, t)
      IF (ABS(dot_tt) < params%breakdown_tol) THEN
        breakdown_flag = .TRUE.
        EXIT
      END IF
      omega = dot_ts / dot_tt
      
      IF (ABS(omega) < params%breakdown_tol) THEN
        breakdown_flag = .TRUE.
        EXIT
      END IF
      
      x = x + alpha * p + omega * y
      r = s - omega * t
      
      r_norm = SQRT(DOT_PRODUCT(r, r))
      
      IF (params%verbose .AND. MOD(iter, params%print_every) == 0) THEN
        PRINT '(A,I6,A,ES12.4)', "Precond BiCGSTAB iter=", iter, " residual=", r_norm/r0_norm
      END IF
      
      IF (r_norm < tol_abs) THEN
        state%converged = .TRUE.
        EXIT
      END IF
      
      rho_old = rho
      omega_old = omega
    END DO
    
    state%num_iter = iter
    state%final_residual = r_norm / r0_norm
    state%breakdown = breakdown_flag
    
    IF (.NOT. state%converged .AND. .NOT. breakdown_flag) THEN
      status%status_code = IF_STATUS_WARN
    ELSE IF (breakdown_flag) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
    DEALLOCATE(r, r0_tilde, p, v, s, t, z, y)
    
  END SUBROUTINE NM_BiCGSTAB_Solv_Precond

  SUBROUTINE Precond_Solv(M, r, z, Prec_proc, status)
    REAL(wp), INTENT(IN)  :: M(:,:), r(:)
    REAL(wp), INTENT(OUT) :: z(:)
    OPTIONAL :: Prec_proc
    INTERFACE
      SUBROUTINE Prec_proc(M, r, z, status)
        USE IF_Err_Brg, ONLY: ErrorStatusType
        USE IF_Prec_Core, ONLY: wp
        REAL(wp), INTENT(IN)  :: M(:,:), r(:)
        REAL(wp), INTENT(OUT) :: z(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Prec_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    IF (PRESENT(Prec_proc)) THEN
      CALL Prec_proc(M, r, z, status)
    ELSE
      ! No preconditioning: z = r
      z = r
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE Precond_Solv
END MODULE NM_Solv_LinIterBiCGSTAB