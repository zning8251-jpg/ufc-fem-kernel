!===============================================================================
! MODULE: NM_Solv_LinIter
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Proc (iterative solver dispatcher)
! BRIEF:  Krylov iterative solvers: CG, GMRES, BiCGSTAB, Arnoldi/Lanczos
!
! Theory: Saad (2003); Barrett et al. (1994)
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinIter
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !> @brief iterationSolver type 
  INTEGER, PARAMETER, PUBLIC :: NM_ITER_CG = 1          !<  
  INTEGER, PARAMETER, PUBLIC :: NM_ITER_GMRES = 2       !< GMRES
  INTEGER, PARAMETER, PUBLIC :: NM_ITER_BICGSTAB = 3    !< BiCGStab
  INTEGER, PARAMETER, PUBLIC :: NM_ITER_MINRES = 4      !< MINRES

  !> @brief iterationSolver parameters
  TYPE, PUBLIC :: Iterative_Solver_Params
    INTEGER(i4) :: solver_type               !< Solver type
    INTEGER(i4) :: max_iterations            !< max iterations
    INTEGER(i4) :: restart_size              !< GMRES 
    REAL(DP) :: tolerance                 !< convergence tolerance
    REAL(DP) :: rel_tolerance             !< relative tolerance
    LOGICAL  :: use_preconditioning       !<  
  END TYPE

  !> @brief iteration 
  TYPE, PUBLIC :: Iterative_Solver_State
    INTEGER(i4) :: iterations_performed      !<  iter count
    REAL(DP) :: final_residual            !<  
    REAL(DP) :: convergence_rate          !< convergence
    LOGICAL  :: converged                 !< converged
    REAL(DP), ALLOCATABLE :: residual_history(:) !<  
  END TYPE

  ! Public interfaces
  PUBLIC :: NM_LinSolv_Iter_CG_Solv
  PUBLIC :: NM_LinSolv_Iter_GMRES_Solv
  PUBLIC :: NM_LinSolv_Iter_BiCGStab_Solv
  PUBLIC :: NM_LinSolv_Iter_SpMV
  PUBLIC :: NM_LinSolv_Iter_Check_Conv
  
  ! Extended Krylov methods API (scope 1250-1299)
  PUBLIC :: NM_LinSolv_Iter_Arnoldi_Process, NM_LinSolv_Iter_Lanczos_Process
  PUBLIC :: NM_LinSolv_Iter_BuildKrylovSubspace
  ! NM_LinSolv_Iter_GetKrylovDimension: TODO stub

CONTAINS

  SUBROUTINE NM_LinSolv_Iter_Arnoldi_Process(A, v1, m, V, H, status)
    USE NM_Solv_LinDir, ONLY: CSR_Matrix
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN) :: v1(:)
    INTEGER(i4), INTENT(IN) :: m
    REAL(DP), INTENT(OUT) :: V(:,:), H(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, j, k
    REAL(DP), ALLOCATABLE :: w(:)
    REAL(DP) :: h_jj, norm_v1
    
    CALL init_error_status(status)
    
    n = SIZE(v1)
    ALLOCATE(w(n))
    
    ! Init
    norm_v1 = SQRT(DOT_PRODUCT(v1, v1))
    IF (norm_v1 > SMALL) THEN
      V(:, 1) = v1 / norm_v1
    ELSE
      V(:, 1) = v1
    END IF
    
    H = ZERO
    
    ! Arnoldi iteration
    DO j = 1, m
      ! w = A * v_j
      CALL NM_LinSolv_Iter_SpMV(A, V(:, j), w)
      
      ! Modified Gram-Schmidt orthogonalization
      DO k = 1, j
        H(k, j) = DOT_PRODUCT(w, V(:, k))
        w = w - H(k, j) * V(:, k)
      END DO
      
      ! h_{j+1,j} = ||w||
      h_jj = SQRT(DOT_PRODUCT(w, w))
      H(j+1, j) = h_jj
      
      IF (h_jj > SMALL) THEN
        V(:, j+1) = w / h_jj
      ELSE
        ! Lucky breakdown
        EXIT
      END IF
    END DO
    
    DEALLOCATE(w)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_LinSolv_Iter_Arnoldi_Process

  SUBROUTINE NM_LinSolv_Iter_BiCGStab_Solv(A, b, x0, params, x, state)
    USE NM_Solv_LinDir, ONLY: CSR_Matrix
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN)  :: b(:), x0(:)
    TYPE(Iterative_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(OUT) :: x(:)
    TYPE(Iterative_Solver_State), INTENT(OUT) :: state

    REAL(DP), ALLOCATABLE :: r(:), r_hat(:), p(:), v(:), s(:), t(:)
    REAL(DP) :: rho_old, rho_new, alpha, beta, omega, norm_b, norm_r
    INTEGER(i4) :: n, iter

    n = SIZE(b)
    ALLOCATE(r(n), r_hat(n), p(n), v(n), s(n), t(n))

    ! Initialize
    x = x0
    CALL NM_LinSolv_Iter_SpMV(A, x, v)
    r = b - v
    r_hat = r  ! r̂0 = r0
    p = ZERO
    v = ZERO

    norm_b = SQRT(DOT_PRODUCT(b, b))
    rho_old = ONE
    alpha = ONE
    omega = ONE

    ALLOCATE(state%residual_history(params%max_iterations + 1))
    state%residual_history(1) = SQRT(DOT_PRODUCT(r, r))

    ! BiCGStabiteration
    DO iter = 1, params%max_iterations
      ! 1. ρ_i = (r̂0, r_{i-1})
      rho_new = DOT_PRODUCT(r_hat, r)

      IF (ABS(rho_new) < SMALL) THEN
        ! BiCGStab 
        EXIT
      END IF

      ! 2. β = (ρ_i/ρ_{i-1})·(α/ω_{i-1})
      beta = (rho_new / rho_old) * (alpha / omega)

      ! 3. p_i = r_{i-1} + β·(p_{i-1} - ω_{i-1}·v_{i-1})
      p = r + beta * (p - omega * v)

      ! 4. v_i = A·p_i
      CALL NM_LinSolv_Iter_SpMV(A, p, v)

      ! 5. α = ρ_i / (r̂0, v_i)
      alpha = rho_new / DOT_PRODUCT(r_hat, v)

      ! 6. s = r_{i-1} - α·v_i
      s = r - alpha * v

      ! check convergence( s)
      norm_r = SQRT(DOT_PRODUCT(s, s))
      IF (NM_LinSolv_Iter_Check_Conv(norm_r, norm_b, params)) THEN
        x = x + alpha * p
        state%converged = .TRUE.
        state%iterations_performed = iter
        state%final_residual = norm_r
        EXIT
      END IF

      ! 7. t = A·s
      CALL NM_LinSolv_Iter_SpMV(A, s, t)

      ! 8. ω_i = (t, s) / (t, t)
      omega = DOT_PRODUCT(t, s) / DOT_PRODUCT(t, t)

      ! 9. x_i = x_{i-1} + α·p_i + ω_i·s
      x = x + alpha * p + omega * s

      ! 10. r_i = s - ω_i·t
      r = s - omega * t

      !  
      norm_r = SQRT(DOT_PRODUCT(r, r))
      state%residual_history(iter + 1) = norm_r

      IF (NM_LinSolv_Iter_Check_Conv(norm_r, norm_b, params)) THEN
        state%converged = .TRUE.
        state%iterations_performed = iter
        state%final_residual = norm_r
        EXIT
      END IF

      rho_old = rho_new
    END DO

    !  
    IF (.NOT. state%converged) THEN
      state%iterations_performed = params%max_iterations
      state%final_residual = norm_r
    END IF

    DEALLOCATE(r, r_hat, p, v, s, t)

  END SUBROUTINE NM_LinSolv_Iter_BiCGStab_Solv

  SUBROUTINE NM_LinSolv_Iter_BuildKrylovSubspace(A, v, m, K, status)
    USE NM_Solv_LinDir, ONLY: CSR_Matrix
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN) :: v(:)
    INTEGER(i4), INTENT(IN) :: m
    REAL(DP), INTENT(OUT) :: K(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, j
    REAL(DP), ALLOCATABLE :: w(:)
    REAL(DP) :: norm_v
    
    CALL init_error_status(status)
    
    n = SIZE(v)
    ALLOCATE(w(n))
    
    ! Init first vector
    norm_v = SQRT(DOT_PRODUCT(v, v))
    IF (norm_v > SMALL) THEN
      K(:, 1) = v / norm_v
    ELSE
      K(:, 1) = v
    END IF
    
    ! Build Krylov vectors: K(:,j) = A^{j-1} * v
    DO j = 2, m
      CALL NM_LinSolv_Iter_SpMV(A, K(:, j-1), w)
      K(:, j) = w
    END DO
    
    DEALLOCATE(w)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_LinSolv_Iter_BuildKrylovSubspace

  SUBROUTINE NM_LinSolv_Iter_CG_Solv(A, b, x0, params, x, state)
    USE NM_Solv_LinDir, ONLY: CSR_Matrix
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN)  :: b(:), x0(:)
    TYPE(Iterative_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(OUT) :: x(:)
    TYPE(Iterative_Solver_State), INTENT(OUT) :: state

    REAL(DP), ALLOCATABLE :: r(:), p(:), Ap(:), z(:)
    REAL(DP) :: alpha, beta, rho_old, rho_new, norm_b, norm_r
    INTEGER(i4) :: n, iter

    n = SIZE(b)
    ALLOCATE(r(n), p(n), Ap(n), z(n))

    ! Initialize
    x = x0
    CALL NM_LinSolv_Iter_SpMV(A, x, Ap)  ! Ap = A·x0
    r = b - Ap                    ! r0 = b - A·x0
    p = r                         ! p0 = r0

    norm_b = SQRT(DOT_PRODUCT(b, b))
    rho_old = DOT_PRODUCT(r, r)

    !  
    ALLOCATE(state%residual_history(params%max_iterations + 1))
    state%residual_history(1) = SQRT(rho_old)

    ! CGiteration
    DO iter = 1, params%max_iterations
      ! 1. computation Ap = A·p_k
      CALL NM_LinSolv_Iter_SpMV(A, p, Ap)

      ! 2. α_k = (r_k, r_k) / (p_k, A·p_k)
      alpha = rho_old / DOT_PRODUCT(p, Ap)

      ! 3. x_{k+1} = x_k + α_k·p_k
      x = x + alpha * p

      ! 4. r_{k+1} = r_k - α_k·A·p_k
      r = r - alpha * Ap

      ! 5. check convergence
      rho_new = DOT_PRODUCT(r, r)
      norm_r = SQRT(rho_new)
      state%residual_history(iter + 1) = norm_r

      IF (NM_LinSolv_Iter_Check_Conv(norm_r, norm_b, params)) THEN
        state%converged = .TRUE.
        state%iterations_performed = iter
        state%final_residual = norm_r
        EXIT
      END IF

      ! 6. β_k = (r_{k+1}, r_{k+1}) / (r_k, r_k)
      beta = rho_new / rho_old

      ! 7. p_{k+1} = r_{k+1} + β_k·p_k
      p = r + beta * p

      rho_old = rho_new
    END DO

    !  
    IF (.NOT. state%converged) THEN
      state%iterations_performed = params%max_iterations
      state%final_residual = norm_r
    END IF

    ! computationconvergence
    IF (iter > 1) THEN
      state%convergence_rate = (state%residual_history(iter+1) / &
                                 state%residual_history(1))**(ONE/iter)
    END IF

    DEALLOCATE(r, p, Ap, z)

  END SUBROUTINE NM_LinSolv_Iter_CG_Solv

  FUNCTION NM_LinSolv_Iter_Check_Conv(residual_norm, rhs_norm, params) RESULT(converged)
    REAL(DP), INTENT(IN) :: residual_norm, rhs_norm
    TYPE(Iterative_Solver_Params), INTENT(IN) :: params
    LOGICAL :: converged

    REAL(DP) :: rel_residual

    converged = .FALSE.

    !  
    IF (residual_norm < params%tolerance) THEN
      converged = .TRUE.
      RETURN
    END IF

    !  
    IF (rhs_norm > SMALL) THEN
      rel_residual = residual_norm / rhs_norm
      IF (rel_residual < params%rel_tolerance) THEN
        converged = .TRUE.
    END IF
  END IF

END FUNCTION NM_LinSolv_Iter_Check_Conv

  SUBROUTINE NM_LinSolv_Iter_GMRES_Solv(A, b, x0, params, x, state)
    USE NM_Solv_LinDir, ONLY: CSR_Matrix
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN)  :: b(:), x0(:)
    TYPE(Iterative_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(OUT) :: x(:)
    TYPE(Iterative_Solver_State), INTENT(OUT) :: state

    INTEGER(i4) :: n, m, iter, j, k, restart_cycle
    REAL(DP), ALLOCATABLE :: V(:,:), H(:,:), w(:), r(:), y(:), c(:), s(:), g(:)
    REAL(DP) :: beta, norm_b, norm_r, h_jj, h_jj1, temp
    LOGICAL :: converged_flag

    n = SIZE(b)
    m = params%restart_size
    ALLOCATE(V(n, m+1), H(m+1, m), w(n), r(n), y(m), c(m), s(m), g(m+1))

    ! Initialize
    x = x0
    norm_b = SQRT(DOT_PRODUCT(b, b))
    ALLOCATE(state%residual_history(params%max_iterations + 1))

    converged_flag = .FALSE.
    iter = 0

    ! GMRES(m) 
    DO restart_cycle = 1, params%max_iterations / m + 1
      ! computationInitialize 
      CALL NM_LinSolv_Iter_SpMV(A, x, w)
      r = b - w
      beta = SQRT(DOT_PRODUCT(r, r))
      state%residual_history(iter + 1) = beta

      IF (NM_LinSolv_Iter_Check_Conv(beta, norm_b, params)) THEN
        converged_flag = .TRUE.
        EXIT
      END IF

      ! Initialize Arnoldivector
      V(:, 1) = r / beta
      g = ZERO
      g(1) = beta

      ! Arnoldiiteration
      DO j = 1, m
        iter = iter + 1
        IF (iter > params%max_iterations) EXIT

        ! w = A·v_j
        CALL NM_LinSolv_Iter_SpMV(A, V(:, j), w)

        ! Gram-Schmidt 
        DO k = 1, j
          H(k, j) = DOT_PRODUCT(w, V(:, k))
          w = w - H(k, j) * V(:, k)
        END DO

        H(j+1, j) = SQRT(DOT_PRODUCT(w, w))

        IF (H(j+1, j) > SMALL) THEN
          V(:, j+1) = w / H(j+1, j)
        ELSE
          !   (Lucky Breakdown)
          EXIT
        END IF

        !  Givens H j
        DO k = 1, j-1
          temp = c(k) * H(k, j) + s(k) * H(k+1, j)
          H(k+1, j) = -s(k) * H(k, j) + c(k) * H(k+1, j)
          H(k, j) = temp
        END DO

        ! computation Givens 
        h_jj = H(j, j)
        h_jj1 = H(j+1, j)
        temp = SQRT(h_jj**2 + h_jj1**2)
        c(j) = h_jj / temp
        s(j) = h_jj1 / temp

        ! updateH g
        H(j, j) = c(j) * h_jj + s(j) * h_jj1
        H(j+1, j) = ZERO
        g(j+1) = -s(j) * g(j)
        g(j) = c(j) * g(j)

        ! check convergence
        norm_r = ABS(g(j+1))
        state%residual_history(iter + 1) = norm_r

        IF (NM_LinSolv_Iter_Check_Conv(norm_r, norm_b, params)) THEN
          converged_flag = .TRUE.
          EXIT
        END IF
      END DO

      !   H·y = g ( 
      DO j = MIN(m, iter), 1, -1
        y(j) = g(j)
        DO k = j+1, MIN(m, iter)
          y(j) = y(j) - H(j, k) * y(k)
        END DO
        y(j) = y(j) / H(j, j)
      END DO

      ! update x = x0 + V_m·y
      DO j = 1, MIN(m, iter)
        x = x + y(j) * V(:, j)
      END DO

      IF (converged_flag) EXIT
    END DO

    !  
    state%converged = converged_flag
    state%iterations_performed = iter
    state%final_residual = norm_r

    DEALLOCATE(V, H, w, r, y, c, s, g)

  END SUBROUTINE NM_LinSolv_Iter_GMRES_Solv

  SUBROUTINE NM_LinSolv_Iter_Lanczos_Process(A, v1, m, V, alpha, beta, status)
    USE NM_Solv_LinDir, ONLY: CSR_Matrix
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN) :: v1(:)
    INTEGER(i4), INTENT(IN) :: m
    REAL(DP), INTENT(OUT) :: V(:,:), alpha(:), beta(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, j
    REAL(DP), ALLOCATABLE :: w(:)
    REAL(DP) :: beta_old, norm_v1
    
    CALL init_error_status(status)
    
    n = SIZE(v1)
    ALLOCATE(w(n))
    
    ! Init
    norm_v1 = SQRT(DOT_PRODUCT(v1, v1))
    IF (norm_v1 > SMALL) THEN
      V(:, 1) = v1 / norm_v1
    ELSE
      V(:, 1) = v1
    END IF
    
    beta_old = ZERO
    
    ! Lanczos iteration
    DO j = 1, m
      ! w = A * v_j
      CALL NM_LinSolv_Iter_SpMV(A, V(:, j), w)
      
      ! w = w - β_{j-1} * v_{j-1}
      IF (j > 1) THEN
        w = w - beta_old * V(:, j-1)
      END IF
      
      ! α_j = <w, v_j>
      alpha(j) = DOT_PRODUCT(w, V(:, j))
      
      ! w = w - α_j * v_j
      w = w - alpha(j) * V(:, j)
      
      ! β_j = ||w||
      beta(j) = SQRT(DOT_PRODUCT(w, w))
      
      IF (beta(j) > SMALL) THEN
        V(:, j+1) = w / beta(j)
      ELSE
        ! Breakdown
        EXIT
      END IF
      
      beta_old = beta(j)
    END DO
    
    DEALLOCATE(w)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_LinSolv_Iter_Lanczos_Process

  SUBROUTINE NM_LinSolv_Iter_SpMV(A, x, y)
    USE NM_Solv_LinDir, ONLY: CSR_Matrix
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN)  :: x(:)
    REAL(DP), INTENT(OUT) :: y(:)

    INTEGER(i4) :: i, j, k
    REAL(DP) :: sum_val

    y = ZERO

    ! y_i = Σ_j A(i,j)·x_j
    DO i = 1, A%n_rows
      sum_val = ZERO
      DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
        j = A%col_idx(k)
        sum_val = sum_val + A%values(k) * x(j)
      END DO
      y(i) = sum_val
    END DO

  END SUBROUTINE NM_LinSolv_Iter_SpMV
END MODULE NM_Solv_LinIter