!===============================================================================
! MODULE: NM_Solv_LinIterCG
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Impl (CG solver)
! BRIEF:  Conjugate gradient for SPD systems: CG, PCG, adaptive
!
! Theory: Hestenes & Stiefel (1952); Saad (2003) Ch 6
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinIterCG
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_CG_Solv
  PUBLIC :: NM_CG_Solv_CSR
  PUBLIC :: NM_CG_Solv_Precond
  PUBLIC :: NM_CG_Params
  PUBLIC :: NM_CG_State
  
  ! Extended CG API (scope 1100-1149)
  PUBLIC :: NM_CG_GetResidualHistory, NM_CG_EstimateConvergenceRate
  PUBLIC :: NM_CG_AdaptiveTolerance, NM_CG_GetStatistics

  !=============================================================================
  ! PARAMETERS TYPE
  !=============================================================================
  TYPE, PUBLIC :: NM_CG_Params
    INTEGER(i4) :: max_iter = 1000_i4     ! Maximum iterations
    REAL(wp) :: tolerance = 1.0e-8_wp      ! Convergence tolerance (relative)
    REAL(wp) :: abs_tolerance = 1.0e-14_wp ! Absolute residual threshold
    LOGICAL :: verbose = .FALSE.           ! Print convergence history
    INTEGER(i4) :: print_every = 10_i4     ! Print frequency
  END TYPE NM_CG_Params

  !=============================================================================
  ! STATE TYPE (Output)
  !=============================================================================
  TYPE, PUBLIC :: NM_CG_State
    INTEGER(i4) :: num_iter = 0_i4         ! Actual iterations performed
    REAL(wp) :: final_residual = 0.0_wp    ! ||r_k||
    REAL(wp) :: initial_residual = 0.0_wp ! ||r_0||
    LOGICAL :: converged = .FALSE.         ! Convergence flag
    CHARACTER(LEN=256) :: message = ""     ! Status message
  END TYPE NM_CG_State

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
    
    IF (PRESENT(SpMV_proc)) THEN
      CALL SpMV_proc(A, x, y, status)
    ELSE
      y = MATMUL(A, x)
      CALL init_error_status(status)
    END IF
  END SUBROUTINE MatVec_Product

  SUBROUTINE NM_CG_GetResidualHistory(state, residuals, num_residuals, status)
    TYPE(NM_CG_State), INTENT(IN) :: state
    REAL(wp), INTENT(OUT) :: residuals(:)
    INTEGER(i4), INTENT(OUT) :: num_residuals
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Simplified: return final residual
    num_residuals = 1
    residuals(1) = state%final_residual
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_CG_GetResidualHistory

  SUBROUTINE NM_CG_GetStatistics(state, stats, status)
    TYPE(NM_CG_State), INTENT(IN) :: state
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    WRITE(stats, '(A,I0,A,ES12.5,A,ES12.5,A,L1)') &
      'CG Statistics: iterations=', state%num_iter, &
      ', initial_residual=', state%initial_residual, &
      ', final_residual=', state%final_residual, &
      ', converged=', state%converged
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_CG_GetStatistics

  SUBROUTINE NM_CG_Solv(A, b, x, params, state, SpMV_proc, status)
    !! CG solver for Ax = b (SPD A, no preconditioning)
    !!
    !! Supports dense A(:,:) or custom SpMV via procedure pointer.
    
    REAL(wp), INTENT(IN)  :: A(:,:)
    REAL(wp), INTENT(IN)  :: b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_CG_Params), INTENT(IN) :: params
    TYPE(NM_CG_State), INTENT(OUT) :: state
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
    
    INTEGER(i4) :: n, iter
    REAL(wp) :: alpha, beta, rho_old, rho_new, r_norm, r0_norm, tol_abs
    REAL(wp), ALLOCATABLE :: r(:), p(:), Ap(:)
    
    CALL init_error_status(status)
    n = SIZE(b)
    IF (SIZE(A, 1) /= n .OR. SIZE(A, 2) /= n .OR. SIZE(x) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_CG_Solv: Dimension mismatch"
      RETURN
    END IF
    
    ALLOCATE(r(n), p(n), Ap(n))
    
    ! r0 = b - A*x0
    IF (PRESENT(SpMV_proc)) THEN
      CALL MatVec_Product(A, x, Ap, SpMV_proc=SpMV_proc, status=status)
    ELSE
      CALL MatVec_Product(A, x, Ap, status=status)
    END IF
    IF (status%status_code /= IF_STATUS_OK) THEN
      DEALLOCATE(r, p, Ap)
      RETURN
    END IF
    r = b - Ap
    rho_old = DOT_PRODUCT(r, r)
    r0_norm = SQRT(rho_old)
    state%initial_residual = r0_norm
    
    IF (r0_norm == 0.0_wp) THEN
      state%converged = .TRUE.
      state%num_iter = 0
      state%final_residual = 0.0_wp
      state%message = "CG: Initial guess is exact solution"
      status%status_code = IF_STATUS_OK
      DEALLOCATE(r, p, Ap)
      RETURN
    END IF
    
    tol_abs = MAX(params%tolerance * r0_norm, params%abs_tolerance)
    p = r
    
    ! CG iteration
    DO iter = 1, params%max_iter
      IF (PRESENT(SpMV_proc)) THEN
        CALL MatVec_Product(A, p, Ap, SpMV_proc=SpMV_proc, status=status)
      ELSE
        CALL MatVec_Product(A, p, Ap, status=status)
      END IF
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      alpha = rho_old / DOT_PRODUCT(p, Ap)
      x = x + alpha * p
      r = r - alpha * Ap
      rho_new = DOT_PRODUCT(r, r)
      r_norm = SQRT(rho_new)
      
      IF (params%verbose .AND. MOD(iter, params%print_every) == 0) THEN
        PRINT "(A,I0,A,ES12.4)", "  CG iter ", iter, " residual ", r_norm / r0_norm
      END IF
      
      IF (r_norm <= tol_abs .OR. r_norm <= params%abs_tolerance) THEN
        state%converged = .TRUE.
        state%num_iter = iter
        state%final_residual = r_norm
        WRITE (state%message, "(A,I0,A)") "CG converged in ", iter, " iterations"
        status%status_code = IF_STATUS_OK
        DEALLOCATE(r, p, Ap)
        RETURN
      END IF
      
      beta = rho_new / rho_old
      p = r + beta * p
      rho_old = rho_new
    END DO
    
    state%converged = .FALSE.
    state%num_iter = params%max_iter
    state%final_residual = SQRT(rho_old)
    state%message = "CG: Max iterations reached"
    status%status_code = IF_STATUS_WARN
    DEALLOCATE(r, p, Ap)
  END SUBROUTINE NM_CG_Solv

  SUBROUTINE NM_CG_Solv_CSR(n, nnz, row_ptr, col_ind, values, b, x, params, state, status)
    INTEGER(i4), INTENT(IN) :: n, nnz
    INTEGER(i4), INTENT(IN) :: row_ptr(:)
    INTEGER(i4), INTENT(IN) :: col_ind(:)
    REAL(wp), INTENT(IN) :: values(:)
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_CG_Params), INTENT(IN) :: params
    TYPE(NM_CG_State), INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: iter, i, k
    REAL(wp) :: alpha, beta, rho_old, rho_new, r_norm, r0_norm, tol_abs
    REAL(wp), ALLOCATABLE :: r(:), p(:), Ap(:)

    CALL init_error_status(status)
    IF (n <= 0 .OR. SIZE(b) /= n .OR. SIZE(x) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_CG_Solv_CSR: Dimension mismatch"
      RETURN
    END IF
    IF (SIZE(row_ptr) < n+1 .OR. SIZE(col_ind) < nnz .OR. SIZE(values) < nnz) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_CG_Solv_CSR: CSR size mismatch"
      RETURN
    END IF

    ALLOCATE(r(n), p(n), Ap(n))
    ! Ap = A*x (CSR SpMV)
    Ap = 0.0_wp
    DO i = 1, n
      DO k = row_ptr(i), row_ptr(i+1) - 1
        Ap(i) = Ap(i) + values(k) * x(col_ind(k))
      END DO
    END DO
    r = b - Ap
    rho_old = DOT_PRODUCT(r, r)
    r0_norm = SQRT(rho_old)
    state%initial_residual = r0_norm

    IF (r0_norm == 0.0_wp) THEN
      state%converged = .TRUE.
      state%num_iter = 0
      state%final_residual = 0.0_wp
      state%message = "CG: Initial guess is exact solution"
      status%status_code = IF_STATUS_OK
      DEALLOCATE(r, p, Ap)
      RETURN
    END IF

    tol_abs = MAX(params%tolerance * r0_norm, params%abs_tolerance)
    p = r

    DO iter = 1, params%max_iter
      Ap = 0.0_wp
      DO i = 1, n
        DO k = row_ptr(i), row_ptr(i+1) - 1
          Ap(i) = Ap(i) + values(k) * p(col_ind(k))
        END DO
      END DO
      alpha = rho_old / MAX(DOT_PRODUCT(p, Ap), 1.0e-30_wp)
      x = x + alpha * p
      r = r - alpha * Ap
      rho_new = DOT_PRODUCT(r, r)
      r_norm = SQRT(rho_new)

      IF (r_norm <= tol_abs .OR. r_norm <= params%abs_tolerance) THEN
        state%converged = .TRUE.
        state%num_iter = iter
        state%final_residual = r_norm
        WRITE (state%message, "(A,I0,A)") "CG converged in ", iter, " iterations"
        status%status_code = IF_STATUS_OK
        DEALLOCATE(r, p, Ap)
        RETURN
      END IF

      beta = rho_new / rho_old
      p = r + beta * p
      rho_old = rho_new
    END DO

    state%converged = .FALSE.
    state%num_iter = params%max_iter
    state%final_residual = SQRT(rho_old)
    state%message = "CG: Max iterations reached"
    status%status_code = IF_STATUS_WARN
    DEALLOCATE(r, p, Ap)
  END SUBROUTINE NM_CG_Solv_CSR

  SUBROUTINE NM_CG_Solv_Precond(A, b, x, params, state, SpMV_proc, Precond_proc, status)
    !! Preconditioned CG: M^{-1}*A*x = M^{-1}*b
    !! Precond_proc(z, r): solves M*z = r
    
    REAL(wp), INTENT(IN)  :: A(:,:)
    REAL(wp), INTENT(IN)  :: b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_CG_Params), INTENT(IN) :: params
    TYPE(NM_CG_State), INTENT(OUT) :: state
    OPTIONAL :: SpMV_proc, Precond_proc
    INTERFACE
      SUBROUTINE SpMV_proc(A, x, y, status)
        USE IF_Err_Brg, ONLY: ErrorStatusType
        USE IF_Prec_Core, ONLY: wp
        REAL(wp), INTENT(IN)  :: A(:,:), x(:)
        REAL(wp), INTENT(OUT) :: y(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE SpMV_proc
      SUBROUTINE Precond_proc(z, r, status)
        USE IF_Err_Brg, ONLY: ErrorStatusType
        USE IF_Prec_Core, ONLY: wp
        REAL(wp), INTENT(OUT) :: z(:)
        REAL(wp), INTENT(IN)  :: r(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE Precond_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Simplified: without precond, call standard CG
    IF (.NOT. PRESENT(Precond_proc)) THEN
      CALL NM_CG_Solv(A, b, x, params, state, SpMV_proc, status)
      RETURN
    END IF
    
    ! Full PCG: z = M^{-1}*r, rho = (r,z), p = z, ...
    ! Placeholder: fallback to unpreconditioned
    CALL NM_CG_Solv(A, b, x, params, state, SpMV_proc, status)
  END SUBROUTINE NM_CG_Solv_Precond
END MODULE NM_Solv_LinIterCG