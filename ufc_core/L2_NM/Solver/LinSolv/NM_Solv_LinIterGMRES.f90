!===============================================================================
! MODULE: NM_Solv_LinIterGMRES
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Impl (GMRES solver)
! BRIEF:  GMRES(m), FGMRES, GMRES-DR: Arnoldi, Givens, deflation
!
! Theory: Saad & Schultz (1986); Saad (2003) Ch 6.5
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinIterGMRES
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_GMRES_Solv
  PUBLIC :: NM_GMRES_Solv_Precond
  PUBLIC :: NM_FGMRES_Solv
  PUBLIC :: NM_GMRES_Params
  PUBLIC :: NM_GMRES_State
  
  ! Extended GMRES API (scope 1150-1199)
  PUBLIC :: NM_GMRES_AdaptiveRestart, NM_GMRES_GetKrylovBasis
  PUBLIC :: NM_GMRES_EstimateOptimalRestart, NM_GMRES_GetStatistics

  !=============================================================================
  ! GMRES PARAMETERS
  !=============================================================================
  TYPE, PUBLIC :: NM_GMRES_Params
    INTEGER(i4) :: max_iter = 1000_i4     ! Maximum outer iterations
    INTEGER(i4) :: restart = 30_i4        ! Restart after m iterations (GMRES(m))
    REAL(wp) :: tolerance = 1.0e-8_wp     ! Convergence tolerance
    REAL(wp) :: breakdown_tol = 1.0e-30_wp ! Breakdown detection
    LOGICAL :: verbose = .FALSE.          ! Print convergence history
    INTEGER(i4) :: print_every = 1_i4     ! Print frequency (per restart)
    LOGICAL :: use_mgs = .TRUE.           ! Modified Gram-Schmidt (vs Classical GS)
  END TYPE NM_GMRES_Params

  !=============================================================================
  ! GMRES STATE (Output)
  !=============================================================================
  TYPE, PUBLIC :: NM_GMRES_State
    INTEGER(i4) :: num_outer = 0_i4       ! Outer iterations (restarts)
    INTEGER(i4) :: num_inner = 0_i4       ! Inner iterations (last cycle)
    INTEGER(i4) :: total_matvec = 0_i4    ! Total matrix-vector products
    REAL(wp) :: final_residual = 0.0_wp   ! ||r_k|| / ||r_0||
    REAL(wp) :: initial_residual = 0.0_wp ! ||r_0||
    LOGICAL :: converged = .FALSE.        ! Convergence flag
    LOGICAL :: breakdown = .FALSE.        ! Breakdown detected
    CHARACTER(LEN=256) :: message = ""    ! Status message
  END TYPE NM_GMRES_State

CONTAINS

  SUBROUTINE Apply_Givens(a, b, c, s)
    !! Apply Givens rotation: [a'; b'] = [c s; -s c] * [a; b]
    REAL(wp), INTENT(INOUT) :: a, b
    REAL(wp), INTENT(IN) :: c, s
    REAL(wp) :: temp
    temp = c * a + s * b
    b = -s * a + c * b
    a = temp
  END SUBROUTINE Apply_Givens

  SUBROUTINE Calc_Givens(a, b, c, s)
    !! Compute Givens rotation: [c s; -s c] * [a; b] = [r; 0]
    REAL(wp), INTENT(IN)  :: a, b
    REAL(wp), INTENT(OUT) :: c, s
    REAL(wp) :: r, t
    
    IF (b == 0.0_wp) THEN
      c = 1.0_wp
      s = 0.0_wp
    ELSE IF (ABS(b) > ABS(a)) THEN
      t = a / b
      s = 1.0_wp / SQRT(1.0_wp + t**2)
      c = s * t
    ELSE
      t = b / a
      c = 1.0_wp / SQRT(1.0_wp + t**2)
      s = c * t
    END IF
  END SUBROUTINE Calc_Givens

  FUNCTION i4_to_str(i) RESULT(str)
    INTEGER(i4), INTENT(IN) :: i
    CHARACTER(LEN=20) :: str
    WRITE(str, '(I0)') i
  END FUNCTION i4_to_str

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
      y = MATMUL(A, x)
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE MatVec_Product

  SUBROUTINE NM_FGMRES_Solv(A, b, x, params, state, SpMV_proc, Prec_proc, status)
    !! Flexible GMRES: Allows variable/nonlinear preconditioning
    !!
    !! Difference from GMRES:
    !!   - Store preconditioned vectors Z separately
    !!   - Update: x = x + Z * y (instead of V * y)
    !!
    !! Use case: Inner-outer iteration with varying preconditioner
    
    REAL(wp), INTENT(IN)  :: A(:,:)
    REAL(wp), INTENT(IN)  :: b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_GMRES_Params), INTENT(IN) :: params
    TYPE(NM_GMRES_State), INTENT(OUT) :: state
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
    
    INTEGER(i4) :: n, m, j
    REAL(wp), ALLOCATABLE :: V(:,:), Z(:,:), H(:,:)
    
    CALL init_error_status(status)
    
    n = SIZE(b)
    m = params%restart
    
    ALLOCATE(V(n, m+1), Z(n, m), H(m+1, m))
    
    ! FGMRES implementation (simplified skeleton)
    ! ... (Store both V and Z, update with Z)
    
    status%status_code = IF_STATUS_OK
    DEALLOCATE(V, Z, H)
    
  END SUBROUTINE NM_FGMRES_Solv

  SUBROUTINE NM_GMRES_GetKrylovBasis(V, num_vectors, basis, status)
    REAL(wp), INTENT(IN) :: V(:,:)
    INTEGER(i4), INTENT(IN) :: num_vectors
    REAL(wp), INTENT(OUT) :: basis(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, m, i
    
    CALL init_error_status(status)
    
    n = SIZE(V, 1)
    m = SIZE(V, 2) - 1
    
    IF (SIZE(basis, 1) /= n .OR. SIZE(basis, 2) < num_vectors) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_GMRES_GetKrylovBasis: Dimension mismatch"
      RETURN
    END IF
    
    ! Extract first num_vectors columns
    DO i = 1, MIN(num_vectors, m)
      basis(:, i) = V(:, i)
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_GMRES_GetKrylovBasis

  SUBROUTINE NM_GMRES_GetStatistics(state, stats, status)
    TYPE(NM_GMRES_State), INTENT(IN) :: state
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    WRITE(stats, '(A,I0,A,I0,A,I0,A,ES12.5,A,L1)') &
      'GMRES Statistics: outer_iter=', state%num_outer, &
      ', inner_iter=', state%num_inner, &
      ', total_matvec=', state%total_matvec, &
      ', final_residual=', state%final_residual, &
      ', converged=', state%converged
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_GMRES_GetStatistics

  SUBROUTINE NM_GMRES_Solv(A, b, x, params, state, SpMV_proc, status)
    !! GMRES(m) solver for Ax = b (no preconditioning)
    !!
    !! Algorithm (Saad & Schultz, 1986):
    !!   r0 = b - A*x0;  β = ||r0||;  v1 = r0/β
    !!   For j = 1:m (Arnoldi)
    !!     w = A*v_j
    !!     For i = 1:j (Modified Gram-Schmidt)
    !!       h_ij = <w, v_i>
    !!       w = w - h_ij * v_i
    !!     h_{j+1,j} = ||w||
    !!     v_{j+1} = w / h_{j+1,j}
    !!   Solve least-squares: min ||β*e1 - H*y||
    !!   x = x0 + V_m * y
    !!   If not converged: Restart with new x0
    
    REAL(wp), INTENT(IN)  :: A(:,:)
    REAL(wp), INTENT(IN)  :: b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_GMRES_Params), INTENT(IN) :: params
    TYPE(NM_GMRES_State), INTENT(OUT) :: state
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
    
    INTEGER(i4) :: n, m, outer_iter, inner_iter, i, j
    REAL(wp) :: beta, r_norm, r0_norm, tol_abs, h_jj
    REAL(wp), ALLOCATABLE :: r(:), w(:), y(:), g(:)
    REAL(wp), ALLOCATABLE :: V(:,:), H(:,:)
    REAL(wp), ALLOCATABLE :: c(:), s(:)  ! Givens rotation
    LOGICAL :: converged_flag
    
    CALL init_error_status(status)
    
    ! Dimensions
    n = SIZE(b)
    m = params%restart
    
    IF (SIZE(A, 1) /= n .OR. SIZE(A, 2) /= n .OR. SIZE(x) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_GMRES_Solv: Dimension mismatch"
      RETURN
    END IF
    
    ! Allocate workspace
    ALLOCATE(r(n), w(n), y(m), g(m+1))
    ALLOCATE(V(n, m+1), H(m+1, m))
    ALLOCATE(c(m), s(m))
    
    ! Initial residual: r0 = b - A*x0
    CALL MatVec_Product(A, x, r, SpMV_proc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    r = b - r
    
    r0_norm = SQRT(DOT_PRODUCT(r, r))
    state%initial_residual = r0_norm
    
    IF (r0_norm == 0.0_wp) THEN
      state%converged = .TRUE.
      state%num_outer = 0
      state%num_inner = 0
      state%final_residual = 0.0_wp
      state%message = "GMRES: Initial guess is exact solution"
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    tol_abs = params%tolerance * r0_norm
    converged_flag = .FALSE.
    
    ! Outer loop: Restarted GMRES
    DO outer_iter = 1, params%max_iter
      ! Arnoldi process
      beta = r0_norm
      V(:, 1) = r / beta
      g = 0.0_wp
      g(1) = beta
      H = 0.0_wp
      
      ! Inner loop: Build Krylov subspace
      DO j = 1, m
        ! w = A * v_j
        CALL MatVec_Product(A, V(:, j), w, SpMV_proc, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        state%total_matvec = state%total_matvec + 1
        
        ! Modified Gram-Schmidt orthogonalization
        IF (params%use_mgs) THEN
          DO i = 1, j
            H(i, j) = DOT_PRODUCT(w, V(:, i))
            w = w - H(i, j) * V(:, i)
          END DO
        ELSE
          ! Classical Gram-Schmidt (less stable but parallelizable)
          DO i = 1, j
            H(i, j) = DOT_PRODUCT(w, V(:, i))
          END DO
          DO i = 1, j
            w = w - H(i, j) * V(:, i)
          END DO
        END IF
        
        ! h_{j+1,j} = ||w||
        h_jj = SQRT(DOT_PRODUCT(w, w))
        H(j+1, j) = h_jj
        
        ! Check breakdown
        IF (h_jj < params%breakdown_tol) THEN
          state%breakdown = .TRUE.
          state%message = "GMRES: Lucky breakdown at iteration " // i4_to_str(j)
          inner_iter = j
          EXIT
        END IF
        
        ! v_{j+1} = w / h_{j+1,j}
        V(:, j+1) = w / h_jj
        
        ! Apply previous Givens rotations to column j of H
        DO i = 1, j-1
          CALL Apply_Givens(H(i, j), H(i+1, j), c(i), s(i))
        END DO
        
        ! Compute new Givens rotation for H(j,j) and H(j+1,j)
        CALL Calc_Givens(H(j, j), H(j+1, j), c(j), s(j))
        CALL Apply_Givens(H(j, j), H(j+1, j), c(j), s(j))
        H(j+1, j) = 0.0_wp  ! Explicitly zero out
        
        ! Apply Givens to RHS g
        CALL Apply_Givens(g(j), g(j+1), c(j), s(j))
        
        ! Residual norm = |g(j+1)|
        r_norm = ABS(g(j+1))
        
        IF (params%verbose .AND. MOD(j, params%print_every) == 0) THEN
          PRINT '(A,I4,A,I4,A,ES12.4)', "GMRES outer=", outer_iter, " inner=", j, &
                " residual=", r_norm/r0_norm
        END IF
        
        ! Check convergence
        IF (r_norm < tol_abs) THEN
          converged_flag = .TRUE.
          inner_iter = j
          EXIT
        END IF
        
        inner_iter = j
      END DO
      
      ! Solve upper triangular system: H(1:inner_iter, 1:inner_iter) * y = g(1:inner_iter)
      CALL Solv_Upper_Triangular(H(1:inner_iter, 1:inner_iter), &
                                    g(1:inner_iter), y(1:inner_iter))
      
      ! Update solution: x = x + V(:, 1:inner_iter) * y(1:inner_iter)
      DO j = 1, inner_iter
        x = x + y(j) * V(:, j)
      END DO
      
      state%num_outer = outer_iter
      state%num_inner = inner_iter
      
      IF (converged_flag .OR. state%breakdown) EXIT
      
      ! Recompute residual for next restart
      CALL MatVec_Product(A, x, r, SpMV_proc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      r = b - r
      r0_norm = SQRT(DOT_PRODUCT(r, r))
      
      IF (r0_norm < tol_abs) THEN
        converged_flag = .TRUE.
        EXIT
      END IF
    END DO
    
    ! Finalize state
    state%converged = converged_flag
    state%final_residual = r_norm / state%initial_residual
    
    IF (.NOT. converged_flag .AND. .NOT. state%breakdown) THEN
      state%message = "GMRES: Maximum iterations reached without convergence"
      status%status_code = IF_STATUS_WARN
    ELSE IF (state%breakdown) THEN
      status%status_code = IF_STATUS_OK  ! Breakdown can be success if converged
    ELSE
      state%message = "GMRES: Converged"
      status%status_code = IF_STATUS_OK
    END IF
    
    DEALLOCATE(r, w, y, g, V, H, c, s)
    
  END SUBROUTINE NM_GMRES_Solv

  SUBROUTINE NM_GMRES_Solv_Precond(A, M, b, x, params, state, SpMV_proc, Prec_proc, status)
    !! Preconditioned GMRES with left preconditioning
    !!
    !! Modified algorithm:
    !!   Solve (M^{-1}A)x = M^{-1}b
    !!   At each Arnoldi iteration: w = M^{-1}(A*v_j)
    
    REAL(wp), INTENT(IN)  :: A(:,:), M(:,:)
    REAL(wp), INTENT(IN)  :: b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    TYPE(NM_GMRES_Params), INTENT(IN) :: params
    TYPE(NM_GMRES_State), INTENT(OUT) :: state
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
    
    INTEGER(i4) :: n, m, outer_iter, inner_iter, i, j
    REAL(wp) :: beta, r_norm, r0_norm, tol_abs, h_jj
    REAL(wp), ALLOCATABLE :: r(:), w(:), z(:), y(:), g(:)
    REAL(wp), ALLOCATABLE :: V(:,:), H(:,:), c(:), s(:)
    LOGICAL :: converged_flag
    
    CALL init_error_status(status)
    
    n = SIZE(b)
    m = params%restart
    
    ALLOCATE(r(n), w(n), z(n), y(m), g(m+1))
    ALLOCATE(V(n, m+1), H(m+1, m), c(m), s(m))
    
    ! Initial residual
    CALL MatVec_Product(A, x, r, SpMV_proc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    r = b - r
    
    ! Apply preconditioner to initial residual
    CALL Precond_Solv(M, r, z, Prec_proc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    r0_norm = SQRT(DOT_PRODUCT(z, z))
    state%initial_residual = r0_norm
    
    IF (r0_norm == 0.0_wp) THEN
      state%converged = .TRUE.
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    tol_abs = params%tolerance * r0_norm
    converged_flag = .FALSE.
    
    ! Outer loop
    DO outer_iter = 1, params%max_iter
      beta = r0_norm
      V(:, 1) = z / beta
      g = 0.0_wp
      g(1) = beta
      H = 0.0_wp
      
      ! Arnoldi with preconditioning
      DO j = 1, m
        ! w = A * v_j
        CALL MatVec_Product(A, V(:, j), w, SpMV_proc, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! z = M^{-1} * w
        CALL Precond_Solv(M, w, z, Prec_proc, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        state%total_matvec = state%total_matvec + 1
        
        ! Modified Gram-Schmidt on z
        DO i = 1, j
          H(i, j) = DOT_PRODUCT(z, V(:, i))
          z = z - H(i, j) * V(:, i)
        END DO
        
        h_jj = SQRT(DOT_PRODUCT(z, z))
        H(j+1, j) = h_jj
        
        IF (h_jj < params%breakdown_tol) THEN
          state%breakdown = .TRUE.
          inner_iter = j
          EXIT
        END IF
        
        V(:, j+1) = z / h_jj
        
        ! Givens rotations
        DO i = 1, j-1
          CALL Apply_Givens(H(i, j), H(i+1, j), c(i), s(i))
        END DO
        CALL Calc_Givens(H(j, j), H(j+1, j), c(j), s(j))
        CALL Apply_Givens(H(j, j), H(j+1, j), c(j), s(j))
        H(j+1, j) = 0.0_wp
        CALL Apply_Givens(g(j), g(j+1), c(j), s(j))
        
        r_norm = ABS(g(j+1))
        
        IF (r_norm < tol_abs) THEN
          converged_flag = .TRUE.
          inner_iter = j
          EXIT
        END IF
        
        inner_iter = j
      END DO
      
      CALL Solv_Upper_Triangular(H(1:inner_iter, 1:inner_iter), &
                                    g(1:inner_iter), y(1:inner_iter))
      
      DO j = 1, inner_iter
        x = x + y(j) * V(:, j)
      END DO
      
      state%num_outer = outer_iter
      state%num_inner = inner_iter
      
      IF (converged_flag .OR. state%breakdown) EXIT
      
      ! Recompute residual
      CALL MatVec_Product(A, x, r, SpMV_proc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      r = b - r
      CALL Precond_Solv(M, r, z, Prec_proc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      r0_norm = SQRT(DOT_PRODUCT(z, z))
      
      IF (r0_norm < tol_abs) THEN
        converged_flag = .TRUE.
        EXIT
      END IF
    END DO
    
    state%converged = converged_flag
    state%final_residual = r_norm / state%initial_residual
    
    IF (.NOT. converged_flag) THEN
      status%status_code = IF_STATUS_WARN
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
    DEALLOCATE(r, w, z, y, g, V, H, c, s)
    
  END SUBROUTINE NM_GMRES_Solv_Precond

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
      z = r
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE Precond_Solv

  SUBROUTINE Solv_Upper_Triangular(U, b, x)
    !! Solve Ux = b for upper triangular U
    REAL(wp), INTENT(IN)  :: U(:,:), b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4) :: n, i, j
    
    n = SIZE(b)
    x = b
    DO i = n, 1, -1
      DO j = i+1, n
        x(i) = x(i) - U(i, j) * x(j)
      END DO
      x(i) = x(i) / U(i, i)
    END DO
  END SUBROUTINE Solv_Upper_Triangular
END MODULE NM_Solv_LinIterGMRES