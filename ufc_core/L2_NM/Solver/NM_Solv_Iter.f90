!===============================================================================
! MODULE: NM_Solv_Iter
! LAYER:  L2_NM
! DOMAIN: Solver
! ROLE:   Proc (iterative solver procedures)
! BRIEF:  CSR GMRES(m), CG, BiCGSTAB iterative solvers with preconditioning
!
! SIO Compliance (Principle #14):
!   All subroutines use NM_Solv_Iter_Arg bundle for coupling params (A, b, x).
!   Four-type params (Algo/State/Precond) remain as independent arguments.
!
! Status: SIO-REFACTORED | Last verified: 2026-04-29
!===============================================================================
MODULE NM_Solv_Iter

  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Mtx_MatMul, ONLY: NM_SpMV_CSR
  USE NM_Mtx_Def
  USE NM_Solv_Def
  IMPLICIT NONE

  PRIVATE
  PUBLIC :: GMRES_Solve, CG_Solve, BiCGSTAB_Solve
  PUBLIC :: Check_Convergence

CONTAINS

  !====================================================================
  ! GMRES_Solve: Restarted GMRES(m) with optional left preconditioning
  !   Signature: (solver[Algo], stats[State], arg[Arg], precond[State])
  !====================================================================
  SUBROUTINE GMRES_Solve(solver, stats, arg, precond)
    !> [IN]    solver  - Solver algorithm parameters (Algo)
    !> [OUT]   stats   - Solver statistics (State)
    !> [INOUT] arg     - SIO Arg bundle: A[IN], b[IN], x[INOUT]
    !> [IN]    precond - Preconditioner (optional, State)
    TYPE(NM_Solver_Algo), INTENT(IN) :: solver
    TYPE(NM_Solver_State), INTENT(OUT) :: stats
    TYPE(NM_Solv_Iter_Arg), INTENT(INOUT) :: arg
    TYPE(NM_Precond_State), INTENT(IN), OPTIONAL :: precond

    INTEGER(i4) :: n, m, iter, i, j, max_outer, jmax, itotal
    REAL(wp) :: tol, beta, norm_r, rot_t, bnrm
    LOGICAL :: krylov_breakdown
    REAL(wp), ALLOCATABLE :: r(:), v(:, :), h(:, :)
    REAL(wp), ALLOCATABLE :: cs(:), sn(:), g(:), y(:)
    REAL(wp), ALLOCATABLE :: temp(:), av(:)

    IF (.NOT. arg%A%is_allocated) THEN
      ERROR STOP "GMRES_Solve: CSR matrix not allocated"
    END IF
    n = arg%A%nrows
    IF (n /= arg%A%ncols .OR. SIZE(arg%b) /= n .OR. SIZE(arg%x) /= n) THEN
      ERROR STOP "GMRES_Solve: Dimension mismatch"
    END IF

    m = MAX(1, solver%restart_freq)
    tol = solver%tolerance
    max_outer = MAX(1, (solver%max_iter + m - 1) / m)
    bnrm = Norm_L2(arg%b)

    ALLOCATE(r(n), v(n, m + 1), h(m + 1, m))
    ALLOCATE(cs(m), sn(m), g(m + 1), y(m))
    ALLOCATE(temp(n), av(n))

    stats%niter = 0
    stats%convergence_flag = 2
    stats%initial_residual = 0.0_wp
    stats%rnorm = Norm_L2(arg%b)

    CALL NM_SpMV_CSR(arg%A, arg%x, temp)
    r = arg%b - temp
    IF (PRESENT(precond)) CALL precond%Apply_Left(r, r)
    norm_r = Norm_L2(r)
    stats%initial_residual = norm_r

    IF (norm_r <= tol * MAX(bnrm, 1.0_wp)) THEN
      stats%rnorm = norm_r
      stats%convergence_flag = 0
      stats%niter = 0
      DEALLOCATE(r, v, h, cs, sn, g, y, temp, av)
      RETURN
    END IF

    itotal = 0
    outer: DO iter = 1, max_outer
      beta = norm_r
      v(:, 1) = r / beta
      g = 0.0_wp
      g(1) = beta
      krylov_breakdown = .FALSE.

      inner: DO j = 1, m
        CALL NM_SpMV_CSR(arg%A, v(:, j), temp)
        IF (PRESENT(precond)) THEN
          CALL precond%Apply_Left(temp, av)
        ELSE
          av = temp
        END IF

        DO i = 1, j
          h(i, j) = DOT_PRODUCT(av, v(:, i))
          av = av - h(i, j) * v(:, i)
        END DO

        h(j + 1, j) = Norm_L2(av)
        IF (ABS(h(j + 1, j)) < 1.0E-30_wp) THEN
          jmax = j - 1
          krylov_breakdown = .TRUE.
          EXIT inner
        END IF
        v(:, j + 1) = av / h(j + 1, j)

        DO i = 1, j - 1
          rot_t = h(i, j)
          h(i, j) = cs(i) * rot_t + sn(i) * h(i + 1, j)
          h(i + 1, j) = -sn(i) * rot_t + cs(i) * h(i + 1, j)
        END DO

        CALL Compute_Givens(h(j, j), h(j + 1, j), cs(j), sn(j))
        h(j, j) = cs(j) * h(j, j) + sn(j) * h(j + 1, j)
        h(j + 1, j) = 0.0_wp

        g(j + 1) = -sn(j) * g(j)
        g(j) = cs(j) * g(j)

        IF (ABS(g(j + 1)) <= tol * MAX(bnrm, 1.0_wp)) THEN
          CALL Solve_Upper_Triangular(h(1:j, 1:j), g(1:j), y(1:j))
          DO i = 1, n
            arg%x(i) = arg%x(i) + DOT_PRODUCT(v(i, 1:j), y(1:j))
          END DO
          itotal = itotal + j
          stats%niter = itotal
          stats%rnorm = ABS(g(j + 1))
          stats%convergence_flag = 0
          DEALLOCATE(r, v, h, cs, sn, g, y, temp, av)
          RETURN
        END IF
      END DO inner

      IF (.NOT. krylov_breakdown) jmax = m

      IF (jmax >= 1) THEN
        CALL Solve_Upper_Triangular(h(1:jmax, 1:jmax), g(1:jmax), y(1:jmax))
        DO i = 1, n
          arg%x(i) = arg%x(i) + DOT_PRODUCT(v(i, 1:jmax), y(1:jmax))
        END DO
        itotal = itotal + jmax
      END IF

      CALL NM_SpMV_CSR(arg%A, arg%x, temp)
      r = arg%b - temp
      IF (PRESENT(precond)) CALL precond%Apply_Left(r, r)
      norm_r = Norm_L2(r)

      IF (solver%verbose) THEN
        WRITE (*, '(A,I8,A,E12.4)') 'GMRES restart ', iter, ' |prec res|: ', norm_r
      END IF

      IF (norm_r <= tol * MAX(bnrm, 1.0_wp)) THEN
        stats%niter = itotal
        stats%rnorm = norm_r
        stats%convergence_flag = 0
        DEALLOCATE(r, v, h, cs, sn, g, y, temp, av)
        RETURN
      END IF
    END DO outer

    stats%niter = itotal
    stats%rnorm = norm_r
    stats%convergence_flag = 2
    DEALLOCATE(r, v, h, cs, sn, g, y, temp, av)
  END SUBROUTINE GMRES_Solve

  !====================================================================
  ! CG_Solve: Preconditioned Conjugate Gradient
  !   Signature: (solver[Algo], stats[State], arg[Arg], precond[State])
  !====================================================================
  SUBROUTINE CG_Solve(solver, stats, arg, precond)
    !> [IN]    solver  - Solver algorithm parameters (Algo)
    !> [OUT]   stats   - Solver statistics (State)
    !> [INOUT] arg     - SIO Arg bundle: A[IN], b[IN], x[INOUT]
    !> [IN]    precond - Preconditioner (optional, State)
    TYPE(NM_Solver_Algo), INTENT(IN) :: solver
    TYPE(NM_Solver_State), INTENT(OUT) :: stats
    TYPE(NM_Solv_Iter_Arg), INTENT(INOUT) :: arg
    TYPE(NM_Precond_State), INTENT(IN), OPTIONAL :: precond

    INTEGER(i4) :: n, iter
    REAL(wp) :: tol, alpha, beta, rho, rho_old
    REAL(wp), ALLOCATABLE :: r(:), z(:), p(:), Ap(:)
    REAL(wp) :: norm_r, norm_b, denom

    IF (.NOT. arg%A%is_allocated) THEN
      ERROR STOP "CG_Solve: CSR matrix not allocated"
    END IF
    n = arg%A%nrows
    IF (n /= arg%A%ncols .OR. SIZE(arg%b) /= n .OR. SIZE(arg%x) /= n) THEN
      ERROR STOP "CG_Solve: Dimension mismatch"
    END IF

    tol = solver%tolerance
    ALLOCATE(r(n), z(n), p(n), Ap(n))

    stats%niter = 0
    stats%convergence_flag = 2

    CALL NM_SpMV_CSR(arg%A, arg%x, Ap)
    r = arg%b - Ap
    norm_r = Norm_L2(r)
    norm_b = Norm_L2(arg%b)
    stats%initial_residual = norm_r

    IF (norm_r <= tol * MAX(norm_b, 1.0_wp)) THEN
      stats%rnorm = norm_r
      stats%convergence_flag = 0
      DEALLOCATE(r, z, p, Ap)
      RETURN
    END IF

    IF (PRESENT(precond)) THEN
      CALL precond%Apply_Left(r, z)
    ELSE
      z = r
    END IF

    rho = DOT_PRODUCT(r, z)
    p = z

    DO iter = 1, solver%max_iter
      CALL NM_SpMV_CSR(arg%A, p, Ap)
      denom = DOT_PRODUCT(p, Ap)
      IF (ABS(denom) < 1.0E-30_wp) EXIT
      alpha = rho / denom
      arg%x = arg%x + alpha * p
      r = r - alpha * Ap
      norm_r = Norm_L2(r)
      IF (norm_r <= tol * MAX(norm_b, 1.0_wp)) THEN
        stats%niter = iter
        stats%rnorm = norm_r
        stats%convergence_flag = 0
        DEALLOCATE(r, z, p, Ap)
        RETURN
      END IF

      IF (PRESENT(precond)) THEN
        CALL precond%Apply_Left(r, z)
      ELSE
        z = r
      END IF

      rho_old = rho
      rho = DOT_PRODUCT(r, z)
      IF (ABS(rho_old) < 1.0E-30_wp) EXIT
      beta = rho / rho_old
      p = z + beta * p

      IF (solver%verbose .AND. MOD(iter, 10) == 0) THEN
        WRITE (*, '(A,I8,A,E12.4)') 'CG iter ', iter, ' |r|: ', norm_r
      END IF
    END DO

    stats%niter = solver%max_iter
    stats%rnorm = norm_r
    stats%convergence_flag = 2
    DEALLOCATE(r, z, p, Ap)
  END SUBROUTINE CG_Solve

  !====================================================================
  ! BiCGSTAB_Solve: Bi-Conjugate Gradient Stabilized
  !   Signature: (solver[Algo], stats[State], arg[Arg], precond[State])
  !====================================================================
  SUBROUTINE BiCGSTAB_Solve(solver, stats, arg, precond)
    !> [IN]    solver  - Solver algorithm parameters (Algo)
    !> [OUT]   stats   - Solver statistics (State)
    !> [INOUT] arg     - SIO Arg bundle: A[IN], b[IN], x[INOUT]
    !> [IN]    precond - Preconditioner (optional, State)
    TYPE(NM_Solver_Algo), INTENT(IN) :: solver
    TYPE(NM_Solver_State), INTENT(OUT) :: stats
    TYPE(NM_Solv_Iter_Arg), INTENT(INOUT) :: arg
    TYPE(NM_Precond_State), INTENT(IN), OPTIONAL :: precond

    INTEGER(i4) :: n, iter
    REAL(wp) :: rho, rho_old, alpha, beta, omega, norm_r, norm_b, tol
    REAL(wp), ALLOCATABLE :: r(:), r0h(:), p(:), ph(:), v(:), s(:), sh(:), t(:), temp(:)

    IF (.NOT. arg%A%is_allocated) THEN
      ERROR STOP "BiCGSTAB_Solve: CSR matrix not allocated"
    END IF
    n = arg%A%nrows
    IF (n /= arg%A%ncols .OR. SIZE(arg%b) /= n .OR. SIZE(arg%x) /= n) THEN
      ERROR STOP "BiCGSTAB_Solve: Dimension mismatch"
    END IF

    tol = solver%tolerance
    ALLOCATE(r(n), r0h(n), p(n), ph(n), v(n), s(n), sh(n), t(n), temp(n))

    stats%convergence_flag = 2
    stats%niter = 0

    CALL NM_SpMV_CSR(arg%A, arg%x, temp)
    r = arg%b - temp
    r0h = r
    norm_b = Norm_L2(arg%b)
    stats%initial_residual = Norm_L2(r)

    IF (stats%initial_residual <= tol * MAX(norm_b, 1.0_wp)) THEN
      stats%rnorm = stats%initial_residual
      stats%convergence_flag = 0
      DEALLOCATE(r, r0h, p, ph, v, s, sh, t, temp)
      RETURN
    END IF

    rho = 1.0_wp
    alpha = 1.0_wp
    omega = 1.0_wp
    v = 0.0_wp
    p = 0.0_wp

    DO iter = 1, solver%max_iter
      rho_old = rho
      rho = DOT_PRODUCT(r0h, r)
      IF (ABS(rho) < 1.0E-30_wp) EXIT
      beta = (rho / rho_old) * (alpha / omega)
      p = r + beta * (p - omega * v)

      IF (PRESENT(precond)) THEN
        CALL precond%Apply_Left(p, ph)
      ELSE
        ph = p
      END IF

      CALL NM_SpMV_CSR(arg%A, ph, v)
      alpha = rho / DOT_PRODUCT(r0h, v)
      s = r - alpha * v
      norm_r = Norm_L2(s)
      IF (norm_r <= tol * MAX(norm_b, 1.0_wp)) THEN
        arg%x = arg%x + alpha * ph
        stats%niter = iter
        stats%rnorm = norm_r
        stats%convergence_flag = 0
        DEALLOCATE(r, r0h, p, ph, v, s, sh, t, temp)
        RETURN
      END IF

      IF (PRESENT(precond)) THEN
        CALL precond%Apply_Left(s, sh)
      ELSE
        sh = s
      END IF

      CALL NM_SpMV_CSR(arg%A, sh, t)
      omega = DOT_PRODUCT(t, s) / MAX(DOT_PRODUCT(t, t), 1.0E-30_wp)
      arg%x = arg%x + alpha * ph + omega * sh
      r = s - omega * t

      norm_r = Norm_L2(r)
      IF (norm_r <= tol * MAX(norm_b, 1.0_wp)) THEN
        stats%niter = iter
        stats%rnorm = norm_r
        stats%convergence_flag = 0
        DEALLOCATE(r, r0h, p, ph, v, s, sh, t, temp)
        RETURN
      END IF

      IF (solver%verbose .AND. MOD(iter, 10) == 0) THEN
        WRITE (*, '(A,I8,A,E12.4)') 'BiCGSTAB iter ', iter, ' |r|: ', norm_r
      END IF
    END DO

    stats%niter = solver%max_iter
    stats%rnorm = norm_r
    stats%convergence_flag = 2
    DEALLOCATE(r, r0h, p, ph, v, s, sh, t, temp)
  END SUBROUTINE BiCGSTAB_Solve

  FUNCTION Check_Convergence(residual, tol, norm_type) RESULT(converged)
    REAL(wp), INTENT(IN) :: residual(:)
    REAL(wp), INTENT(IN) :: tol
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: norm_type
    LOGICAL :: converged
    REAL(wp) :: norm_val

    IF (PRESENT(norm_type)) THEN
      IF (norm_type == '2' .OR. norm_type == 'L2') THEN
        norm_val = Norm_L2(residual)
      ELSE
        norm_val = Norm_L2(residual)
      END IF
    ELSE
      norm_val = Norm_L2(residual)
    END IF
    converged = (norm_val < tol)
  END FUNCTION Check_Convergence

  SUBROUTINE Compute_Givens(a, b, cs, sn)
    REAL(wp), INTENT(IN) :: a, b
    REAL(wp), INTENT(OUT) :: cs, sn
    REAL(wp) :: r

    r = SQRT(a * a + b * b)
    IF (r < 1.0E-30_wp) THEN
      cs = 1.0_wp
      sn = 0.0_wp
    ELSE
      cs = a / r
      sn = b / r
    END IF
  END SUBROUTINE Compute_Givens

  SUBROUTINE Solve_Upper_Triangular(U, b, x)
    REAL(wp), INTENT(IN) :: U(:, :), b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4) :: n, i, j
    REAL(wp) :: sumv

    n = SIZE(b)
    DO i = n, 1, -1
      sumv = b(i)
      DO j = i + 1, n
        sumv = sumv - U(i, j) * x(j)
      END DO
      IF (ABS(U(i, i)) < 1.0E-30_wp) THEN
        x(i) = 0.0_wp
      ELSE
        x(i) = sumv / U(i, i)
      END IF
    END DO
  END SUBROUTINE Solve_Upper_Triangular

  PURE FUNCTION Norm_L2(vec) RESULT(norm_val)
    REAL(wp), INTENT(IN) :: vec(:)
    REAL(wp) :: norm_val
    norm_val = SQRT(DOT_PRODUCT(vec, vec))
  END FUNCTION Norm_L2

END MODULE NM_Solv_Iter
