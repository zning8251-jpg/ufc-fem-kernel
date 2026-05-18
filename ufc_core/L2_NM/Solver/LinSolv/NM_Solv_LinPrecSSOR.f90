!===============================================================================
! MODULE: NM_Solv_LinPrecSSOR
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Impl (SSOR preconditioner)
! BRIEF:  SSOR/SOR/Jacobi/Gauss-Seidel smoothers and preconditioners
!
! Theory: Young (1971); Saad (2003) Ch 4.1-4.2; Axelsson (1996) Ch 5
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinPrecSSOR
!> Theory: Symmetric SOR preconditioner | Ref: Young(1971)
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_SSOR_Apply
  PUBLIC :: NM_SSOR_Solv
  PUBLIC :: NM_SOR_Forward
  PUBLIC :: NM_SOR_Backward
  PUBLIC :: NM_Jacobi_Apply
  PUBLIC :: NM_GaussSeidel_Apply
  PUBLIC :: NM_Block_Jacobi
  PUBLIC :: NM_SSOR_Optimal_Omega
  PUBLIC :: NM_SSOR_Params
  
  ! Extended SSOR API (scope 1400-1449)
  PUBLIC :: NM_SSOR_AdaptiveOmega, NM_SSOR_GetConvergenceRate
  PUBLIC :: NM_SSOR_GetStatistics, NM_SSOR_EstimateSpectralRadius

  !=============================================================================
  ! SSOR PARAMETERS
  !=============================================================================
  TYPE, PUBLIC :: NM_SSOR_Params
    REAL(wp) :: omega = 1.0_wp           ! Relaxation parameter (1 ω < 2)
    INTEGER(i4) :: num_sweeps = 1_i4     ! Number of SSOR sweeps
    LOGICAL :: symmetric = .TRUE.        ! Use SSOR (vs SOR)
    INTEGER(i4) :: sweep_dir = 0_i4      ! 0=forward+backward, 1=forward, 2=backward
    INTEGER(i4) :: block_size = 1_i4     ! Block size for BSOR/BJacobi
    LOGICAL :: use_diagonal_scaling = .FALSE.  ! Pre-scale by D^{-1}
  END TYPE NM_SSOR_Params

  !=============================================================================
  ! CONSTANTS
  !=============================================================================
  REAL(wp), PARAMETER :: EPS_SSOR = 1.0e-14_wp
  REAL(wp), PARAMETER :: OMEGA_MIN = 0.5_wp
  REAL(wp), PARAMETER :: OMEGA_MAX = 1.95_wp

CONTAINS

  FUNCTION i4_to_str(i) RESULT(str)
    INTEGER(i4), INTENT(IN) :: i
    CHARACTER(LEN=20) :: str
    WRITE(str, '(I0)') i
  END FUNCTION i4_to_str

  SUBROUTINE NM_Block_Jacobi(A, r, z, block_size, status)
    !! Block Jacobi: Solve D_block * z_block = r_block for each block
    !!
    !! D_block: Diagonal blocks of size block_size x block_size
    
    REAL(wp), INTENT(IN)  :: A(:,:), r(:)
    REAL(wp), INTENT(OUT) :: z(:)
    INTEGER(i4), INTENT(IN) :: block_size
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, num_blocks, blk, i_start, i_end, size_blk, i, j
    REAL(wp), ALLOCATABLE :: D_blk(:,:), r_blk(:), z_blk(:)
    
    CALL init_error_status(status)
    
    n = SIZE(A, 1)
    num_blocks = (n + block_size - 1) / block_size
    
    z = 0.0_wp
    
    ! Process each diagonal block
    DO blk = 1, num_blocks
      i_start = (blk - 1) * block_size + 1
      i_end = MIN(blk * block_size, n)
      size_blk = i_end - i_start + 1
      
      ! Extract diagonal block
      ALLOCATE(D_blk(size_blk, size_blk), r_blk(size_blk), z_blk(size_blk))
      
      DO i = 1, size_blk
        DO j = 1, size_blk
          D_blk(i, j) = A(i_start+i-1, i_start+j-1)
        END DO
        r_blk(i) = r(i_start+i-1)
      END DO
      
      ! Solve D_blk * z_blk = r_blk (using Gauss elimination or factorization)
      CALL Solv_Dense_System(D_blk, r_blk, z_blk, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        DEALLOCATE(D_blk, r_blk, z_blk)
        RETURN
      END IF
      
      ! Store result
      DO i = 1, size_blk
        z(i_start+i-1) = z_blk(i)
      END DO
      
      DEALLOCATE(D_blk, r_blk, z_blk)
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_Block_Jacobi

  SUBROUTINE NM_GaussSeidel_Apply(A, r, z, symmetric, status)
    !! Gauss-Seidel: SSOR with ω=1
    
    REAL(wp), INTENT(IN)  :: A(:,:), r(:)
    REAL(wp), INTENT(OUT) :: z(:)
    LOGICAL, INTENT(IN)   :: symmetric  ! True=SGS, False=GS
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(NM_SSOR_Params) :: params
    
    params%omega = 1.0_wp
    params%num_sweeps = 1
    params%symmetric = symmetric
    
    CALL NM_SSOR_Apply(A, r, z, params, status)
    
  END SUBROUTINE NM_GaussSeidel_Apply

  SUBROUTINE NM_Jacobi_Apply(A, r, z, omega, status)
    !! Jacobi preconditioner: z = D^{-1} * r (or ω-Jacobi)
    !!
    !! Weighted Jacobi: z_i = ω * r_i / a_ii
    
    REAL(wp), INTENT(IN)  :: A(:,:), r(:)
    REAL(wp), INTENT(OUT) :: z(:)
    REAL(wp), INTENT(IN)  :: omega
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i
    REAL(wp) :: diag
    
    CALL init_error_status(status)
    
    n = SIZE(A, 1)
    
    DO i = 1, n
      diag = A(i, i)
      IF (ABS(diag) < EPS_SSOR) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "NM_Jacobi_Apply: Near-zero diagonal"
        z(i) = 0.0_wp
      ELSE
        z(i) = omega * r(i) / diag
      END IF
    END DO
    
    IF (status%status_code /= IF_STATUS_WARN) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_Jacobi_Apply

  SUBROUTINE NM_SOR_Backward(A, x, b, omega, status)
    !! SOR backward sweep (reverse ordering i=n:1)
    
    REAL(wp), INTENT(IN)    :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    REAL(wp), INTENT(IN)    :: omega
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j
    REAL(wp) :: sigma, diag, x_new
    
    CALL init_error_status(status)
    
    n = SIZE(A, 1)
    
    DO i = n, 1, -1  ! Backward order
      sigma = 0.0_wp
      diag = A(i, i)
      
      DO j = 1, n
        IF (j /= i) THEN
          sigma = sigma + A(i, j) * x(j)
        END IF
      END DO
      
      IF (ABS(diag) < EPS_SSOR) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "NM_SOR_Backward: Near-zero diagonal at row " // i4_to_str(i)
        diag = EPS_SSOR
      END IF
      
      x_new = (b(i) - sigma) / diag
      x(i) = (1.0_wp - omega) * x(i) + omega * x_new
    END DO
    
    IF (status%status_code /= IF_STATUS_WARN) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SOR_Backward

  SUBROUTINE NM_SOR_Forward(A, x, b, omega, status)
    !! SOR forward sweep (lexicographic ordering i=1:n)
    !!
    !! For i = 1:n
    !!   x_i = (1-ω)*x_i + ω/a_ii * (b_i - sum_{j<i} a_ij*x_j - sum_{j>i} a_ij*x_j)
    !!       = (1-ω)*x_i + ω/a_ii * (b_i - sum_{j≠i} a_ij*x_j + a_ii*x_i)
    
    REAL(wp), INTENT(IN)    :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    REAL(wp), INTENT(IN)    :: omega
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j
    REAL(wp) :: sigma, diag, x_new
    
    CALL init_error_status(status)
    
    n = SIZE(A, 1)
    
    DO i = 1, n
      sigma = 0.0_wp
      diag = A(i, i)
      
      ! Sum off-diagonal contributions: sum_{j≠i} a_ij * x_j
      DO j = 1, n
        IF (j /= i) THEN
          sigma = sigma + A(i, j) * x(j)
        END IF
      END DO
      
      ! Check diagonal
      IF (ABS(diag) < EPS_SSOR) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "NM_SOR_Forward: Near-zero diagonal at row " // i4_to_str(i)
        diag = EPS_SSOR
      END IF
      
      ! Update: x_i = (1-ω)*x_i + ω/a_ii * (b_i - sigma)
      x_new = (b(i) - sigma) / diag
      x(i) = (1.0_wp - omega) * x(i) + omega * x_new
    END DO
    
    IF (status%status_code /= IF_STATUS_WARN) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SOR_Forward

  SUBROUTINE NM_SSOR_Apply(A, r, z, params, status)
    !! Apply SSOR preconditioner: z = M_SSOR^{-1} * r
    !!
    !! Algorithm:
    !!   z = 0
    !!   For sweep = 1:num_sweeps
    !!     Forward:  (D + ωL) * z^{1/2} = ω*r + [ω*U + (1-ω)*D] * z
    !!     Backward: (D + ωU) * z       = ω*r + [ω*L + (1-ω)*D] * z^{1/2}
    !!   z = z * ω(2-ω) / scaling
    
    REAL(wp), INTENT(IN)  :: A(:,:)      ! Coefficient matrix
    REAL(wp), INTENT(IN)  :: r(:)        ! Residual
    REAL(wp), INTENT(OUT) :: z(:)        ! Preconditioned residual
    TYPE(NM_SSOR_Params), INTENT(IN) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, sweep
    REAL(wp) :: omega, scale
    
    CALL init_error_status(status)
    
    n = SIZE(A, 1)
    IF (SIZE(A, 2) /= n .OR. SIZE(r) /= n .OR. SIZE(z) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_SSOR_Apply: Dimension mismatch"
      RETURN
    END IF
    
    omega = params%omega
    
    ! Valid omega
    IF (omega < OMEGA_MIN .OR. omega > OMEGA_MAX) THEN
      status%status_code = IF_STATUS_WARN
      status%message = "NM_SSOR_Apply: omega out of recommended range [0.5, 1.95]"
      omega = MAX(OMEGA_MIN, MIN(omega, OMEGA_MAX))
    END IF
    
    ! Init z = 0
    z = 0.0_wp
    
    ! SSOR sweeps
    DO sweep = 1, params%num_sweeps
      IF (params%symmetric) THEN
        ! Forward sweep
        CALL NM_SOR_Forward(A, z, r, omega, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Backward sweep
        CALL NM_SOR_Backward(A, z, r, omega, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      ELSE
        ! SOR only (forward or backward)
        IF (params%sweep_dir == 2) THEN
          CALL NM_SOR_Backward(A, z, r, omega, status)
        ELSE
          CALL NM_SOR_Forward(A, z, r, omega, status)
        END IF
      END IF
    END DO
    
    ! Scale by ω(2-ω) for SSOR preconditioning
    IF (params%symmetric) THEN
      scale = omega * (2.0_wp - omega)
      z = z / scale
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SSOR_Apply

  SUBROUTINE NM_SSOR_GetStatistics(params, stats, status)
    TYPE(NM_SSOR_Params), INTENT(IN) :: params
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    WRITE(stats, '(A,F6.3,A,I0,A,L1)') &
      'SSOR Statistics: omega=', params%omega, &
      ', num_sweeps=', params%num_sweeps, &
      ', symmetric=', params%symmetric
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SSOR_GetStatistics

  SUBROUTINE NM_SSOR_Optimal_Omega(A, omega_opt, status)
    !! Estimate optimal omega for SOR
    !!
    !! For model problems (e.g., 2D Laplacian):
    !!   ρ_Jacobi = spectral radius of Jacobi iteration matrix
    !!   ω_opt = 2 / (1 + sqrt(1 - ρ_Jacobi^2))
    !!
    !! Heuristic for general A:
    !!   ω_opt 1.0 to 1.5 (default 1.2)
    
    REAL(wp), INTENT(IN)  :: A(:,:)
    REAL(wp), INTENT(OUT) :: omega_opt
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j
    REAL(wp) :: rho_jacobi, diag_sum, offdiag_sum, ratio
    
    CALL init_error_status(status)
    
    n = SIZE(A, 1)
    
    ! Simple heuristic: Estimate ρ_Jacobi from diagonal dominance
    diag_sum = 0.0_wp
    offdiag_sum = 0.0_wp
    
    DO i = 1, n
      diag_sum = diag_sum + ABS(A(i, i))
      DO j = 1, n
        IF (j /= i) THEN
          offdiag_sum = offdiag_sum + ABS(A(i, j))
        END IF
      END DO
    END DO
    
    IF (diag_sum < EPS_SSOR) THEN
      omega_opt = 1.0_wp
      status%status_code = IF_STATUS_WARN
      status%message = "NM_SSOR_Optimal_Omega: Cannot estimate, using default ω=1.0"
      RETURN
    END IF
    
    ratio = offdiag_sum / diag_sum
    rho_jacobi = MIN(ratio, 0.95_wp)  ! Cap at 0.95
    
    ! Young's formula
    omega_opt = 2.0_wp / (1.0_wp + SQRT(1.0_wp - rho_jacobi**2))
    
    ! Clamp to safe range
    omega_opt = MAX(OMEGA_MIN, MIN(omega_opt, OMEGA_MAX))
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_SSOR_Optimal_Omega

  SUBROUTINE NM_SSOR_Solv(A, b, x, max_iter, tol, params, converged, num_iter, status)
    !! SSOR as standalone iterative solver
    !!
    !! Iterates: x^{k+1} = x^k + M_SSOR^{-1} * (b - A*x^k)
    
    REAL(wp), INTENT(IN)    :: A(:,:), b(:)
    REAL(wp), INTENT(INOUT) :: x(:)
    INTEGER(i4), INTENT(IN) :: max_iter
    REAL(wp), INTENT(IN)    :: tol
    TYPE(NM_SSOR_Params), INTENT(IN) :: params
    LOGICAL, INTENT(OUT)    :: converged
    INTEGER(i4), INTENT(OUT) :: num_iter
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, iter
    REAL(wp) :: r_norm, r0_norm, tol_abs
    REAL(wp), ALLOCATABLE :: r(:)
    
    CALL init_error_status(status)
    
    n = SIZE(A, 1)
    ALLOCATE(r(n))
    
    ! Initial residual
    r = b - MATMUL(A, x)
    r0_norm = SQRT(DOT_PRODUCT(r, r))
    
    IF (r0_norm == 0.0_wp) THEN
      converged = .TRUE.
      num_iter = 0
      DEALLOCATE(r)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    tol_abs = tol * r0_norm
    converged = .FALSE.
    
    ! SSOR iterations
    DO iter = 1, max_iter
      ! x^{k+1} = SSOR_sweep(A, x^k, b)
      CALL NM_SSOR_Apply(A, b, x, params, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT
      
      ! Check convergence
      r = b - MATMUL(A, x)
      r_norm = SQRT(DOT_PRODUCT(r, r))
      
      IF (r_norm < tol_abs) THEN
        converged = .TRUE.
        num_iter = iter
        EXIT
      END IF
      
      num_iter = iter
    END DO
    
    DEALLOCATE(r)
    
    IF (.NOT. converged) THEN
      status%status_code = IF_STATUS_WARN
      status%message = "NM_SSOR_Solv: Maximum iterations reached"
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
  END SUBROUTINE NM_SSOR_Solv

  SUBROUTINE Solv_Dense_System(A, b, x, status)
    !! Solve small dense system Ax = b (Gaussian elimination)
    REAL(wp), INTENT(IN)  :: A(:,:), b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, k
    REAL(wp), ALLOCATABLE :: A_work(:,:), b_work(:)
    REAL(wp) :: factor
    
    CALL init_error_status(status)
    
    n = SIZE(A, 1)
    ALLOCATE(A_work(n, n), b_work(n))
    A_work = A
    b_work = b
    
    ! Forward elimination
    DO k = 1, n-1
      DO i = k+1, n
        IF (ABS(A_work(k, k)) < EPS_SSOR) CYCLE
        factor = A_work(i, k) / A_work(k, k)
        A_work(i, k:n) = A_work(i, k:n) - factor * A_work(k, k:n)
        b_work(i) = b_work(i) - factor * b_work(k)
      END DO
    END DO
    
    ! Back substitution
    DO i = n, 1, -1
      x(i) = b_work(i)
      DO j = i+1, n
        x(i) = x(i) - A_work(i, j) * x(j)
      END DO
      IF (ABS(A_work(i, i)) > EPS_SSOR) THEN
        x(i) = x(i) / A_work(i, i)
      ELSE
        x(i) = 0.0_wp
      END IF
    END DO
    
    DEALLOCATE(A_work, b_work)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE Solv_Dense_System
END MODULE NM_Solv_LinPrecSSOR