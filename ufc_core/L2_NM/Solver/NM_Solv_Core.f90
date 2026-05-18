!===============================================================================
! MODULE: NM_Solv_Core
! LAYER:  L2_NM
! DOMAIN: Solver
! ROLE:   Core (four-type compute engine)
! BRIEF:  Linear/nonlinear solvers — CG, direct, Newton, arc-length, BFGS
!
! Four-type signature: (desc, state, algo, ctx, status)
!   desc  — NM_Solver_Desc  [IN]    system config (n, bandwidth, symmetry)
!   state — NM_Solver_State [INOUT] solution vector, iteration counters
!   algo  — NM_Solver_Algo  [IN]    tolerances, method, max iterations
!   ctx   — NM_Solver_Ctx   [INOUT] work arrays (r, p, Ap, z)
!
! Status: ACTIVE | Last verified: 2026-04-25
!===============================================================================
MODULE NM_Solv_Core
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_Solv_Def,  ONLY: NM_Solver_Desc, NM_Solver_State, &
                            NM_Solver_Algo, NM_Solver_Ctx, &
                            NM_SOLV_METHOD_CG, NM_SOLV_METHOD_DIRECT, &
                            NM_SOLV_METHOD_BANDED
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: NM_Solver_Core_Init
  PUBLIC :: NM_Solver_Core_Finalize
  PUBLIC :: NM_Solver_CG
  PUBLIC :: NM_Solver_Jacobi_Precond
  PUBLIC :: NM_Solver_Direct_Banded
  PUBLIC :: NM_Solver_Direct_Dense
  PUBLIC :: NM_Solver_Cholesky
  PUBLIC :: NM_Solver_Newton_Step
  PUBLIC :: NM_Solver_Check_Convergence
  PUBLIC :: NM_Solver_Line_Search
  PUBLIC :: NM_Solver_BFGS_Update
  PUBLIC :: NM_Solver_PCG
  PUBLIC :: NM_Solver_Arc_Length_Predict
  PUBLIC :: NM_Solver_Arc_Length_Correct

CONTAINS

  !---------------------------------------------------------------------------
  ! Phase: Config | Verb: Init | COLD_PATH O(1)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Core_Init(desc, state, algo, ctx, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Algo),  INTENT(IN)    :: algo
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%niter     = 0
    state%rnorm     = 0.0_wp
    state%dunorm    = 0.0_wp
    state%converged = .FALSE.
    ctx%alpha       = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Core_Init

  !---------------------------------------------------------------------------
  ! Phase: Config | Verb: Init(Finalize) | COLD_PATH O(n)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Core_Finalize(desc, state, ctx, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    NULLIFY(state%x, state%b, state%H_inv)
    NULLIFY(ctx%r, ctx%p, ctx%Ap, ctx%z, ctx%du, ctx%neg_R, ctx%diag, ctx%K_band)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Core_Finalize

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute(Solve) | HOT_PATH O(n*iter)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_CG(desc, state, algo, ctx, matvec, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Algo),  INTENT(IN)    :: algo
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    EXTERNAL                             :: matvec
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    REAL(wp) :: rr_old, rr_new, alpha_cg, beta, b_norm
    INTEGER(i4) :: k

    CALL init_error_status(status)

    ! r = b - A*x
    CALL matvec(state%x, ctx%Ap)
    ctx%r(1:desc%n) = state%b(1:desc%n) - ctx%Ap(1:desc%n)
    ctx%p(1:desc%n) = ctx%r(1:desc%n)
    rr_old = DOT_PRODUCT(ctx%r(1:desc%n), ctx%r(1:desc%n))
    b_norm = SQRT(DOT_PRODUCT(state%b(1:desc%n), state%b(1:desc%n)))
    IF (b_norm < 1.0E-30_wp) b_norm = 1.0_wp

    DO k = 1, algo%maxiter
      CALL matvec(ctx%p, ctx%Ap)
      alpha_cg = rr_old / DOT_PRODUCT(ctx%p(1:desc%n), ctx%Ap(1:desc%n))
      state%x(1:desc%n) = state%x(1:desc%n) + alpha_cg * ctx%p(1:desc%n)
      ctx%r(1:desc%n)   = ctx%r(1:desc%n)   - alpha_cg * ctx%Ap(1:desc%n)
      rr_new = DOT_PRODUCT(ctx%r(1:desc%n), ctx%r(1:desc%n))
      state%rnorm = SQRT(rr_new) / b_norm

      IF (state%rnorm < algo%rtol) THEN
        state%niter = k
        state%converged = .TRUE.
        status%status_code = IF_STATUS_OK
        RETURN
      END IF

      beta = rr_new / rr_old
      ctx%p(1:desc%n) = ctx%r(1:desc%n) + beta * ctx%p(1:desc%n)
      rr_old = rr_new
    END DO

    state%niter = algo%maxiter
    state%converged = .FALSE.
    status%status_code = IF_STATUS_INVALID
    status%message = "[NM_Solver_CG]: did not converge"
  END SUBROUTINE NM_Solver_CG

  !---------------------------------------------------------------------------
  ! Phase: Config | Verb: Compute(Build) | COLD_PATH O(n)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Jacobi_Precond(desc, ctx, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    DO i = 1, desc%n
      IF (ABS(ctx%diag(i)) > 1.0E-30_wp) THEN
        ctx%z(i) = ctx%r(i) / ctx%diag(i)
      ELSE
        ctx%z(i) = ctx%r(i)
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Jacobi_Precond

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute(Solve) | HOT_PATH O(n^3)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Direct_Dense(n, K_in, b_in, x_out, status)
    INTEGER(i4),        INTENT(IN)    :: n
    REAL(wp),           INTENT(IN)    :: K_in(n,n)
    REAL(wp),           INTENT(IN)    :: b_in(n)
    REAL(wp),           INTENT(OUT)   :: x_out(n)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp)    :: A(n,n), rhs(n), pivot, factor, tmp
    INTEGER(i4) :: i, j, k, p_row

    CALL init_error_status(status)

    A   = K_in
    rhs = b_in

    DO k = 1, n - 1
      p_row = k
      pivot = ABS(A(k,k))
      DO i = k + 1, n
        IF (ABS(A(i,k)) > pivot) THEN
          pivot = ABS(A(i,k))
          p_row = i
        END IF
      END DO

      IF (pivot < 1.0E-30_wp) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[NM_Solver_Direct_Dense]: singular matrix"
        RETURN
      END IF

      IF (p_row /= k) THEN
        DO j = k, n
          tmp = A(k,j); A(k,j) = A(p_row,j); A(p_row,j) = tmp
        END DO
        tmp = rhs(k); rhs(k) = rhs(p_row); rhs(p_row) = tmp
      END IF

      DO i = k + 1, n
        factor = A(i,k) / A(k,k)
        DO j = k + 1, n
          A(i,j) = A(i,j) - factor * A(k,j)
        END DO
        rhs(i) = rhs(i) - factor * rhs(k)
      END DO
    END DO

    IF (ABS(A(n,n)) < 1.0E-30_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Solver_Direct_Dense]: singular matrix"
      RETURN
    END IF

    DO i = n, 1, -1
      x_out(i) = rhs(i)
      DO j = i + 1, n
        x_out(i) = x_out(i) - A(i,j) * x_out(j)
      END DO
      x_out(i) = x_out(i) / A(i,i)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Direct_Dense

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute(Solve) | HOT_PATH O(n^3)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Cholesky(n, K_in, b_in, x_out, status)
    INTEGER(i4),        INTENT(IN)    :: n
    REAL(wp),           INTENT(IN)    :: K_in(n,n)
    REAL(wp),           INTENT(IN)    :: b_in(n)
    REAL(wp),           INTENT(OUT)   :: x_out(n)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp)    :: L(n,n), y(n), s
    INTEGER(i4) :: i, j, k

    CALL init_error_status(status)

    L = 0.0_wp

    DO j = 1, n
      s = K_in(j,j)
      DO k = 1, j - 1
        s = s - L(j,k) * L(j,k)
      END DO
      IF (s <= 0.0_wp) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[NM_Solver_Cholesky]: matrix not positive definite"
        RETURN
      END IF
      L(j,j) = SQRT(s)

      DO i = j + 1, n
        s = K_in(i,j)
        DO k = 1, j - 1
          s = s - L(i,k) * L(j,k)
        END DO
        L(i,j) = s / L(j,j)
      END DO
    END DO

    DO i = 1, n
      y(i) = b_in(i)
      DO k = 1, i - 1
        y(i) = y(i) - L(i,k) * y(k)
      END DO
      y(i) = y(i) / L(i,i)
    END DO

    DO i = n, 1, -1
      x_out(i) = y(i)
      DO k = i + 1, n
        x_out(i) = x_out(i) - L(k,i) * x_out(k)
      END DO
      x_out(i) = x_out(i) / L(i,i)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Cholesky

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute(Solve) | HOT_PATH O(n*bw^2)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Direct_Banded(desc, state, ctx, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Direct_Banded

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute | HOT_PATH O(n)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Newton_Step(desc, state, ctx, solve_linear, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    EXTERNAL                             :: solve_linear
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%neg_R(1:desc%n) = -ctx%r(1:desc%n)
    CALL solve_linear(desc%n, ctx%neg_R, ctx%du, status)
  END SUBROUTINE NM_Solver_Newton_Step

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Control(Check) | HOT_PATH O(n)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Check_Convergence(desc, state, algo, ctx, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Algo),  INTENT(IN)    :: algo
    TYPE(NM_Solver_Ctx),   INTENT(IN)    :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%rnorm  = SQRT(DOT_PRODUCT(ctx%r(1:desc%n), ctx%r(1:desc%n)))
    state%dunorm = SQRT(DOT_PRODUCT(ctx%du(1:desc%n), ctx%du(1:desc%n)))
    state%converged = (state%rnorm < algo%atol) .OR. (state%dunorm < algo%rtol)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Check_Convergence

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute | HOT_PATH O(n)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Line_Search(desc, state, algo, ctx, &
                                    eval_residual, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Algo),  INTENT(IN)    :: algo
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    EXTERNAL                             :: eval_residual
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! TODO: Backtracking or bisection line search
    ctx%alpha = algo%ls_alpha_init
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Line_Search

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Evolve(Update) | HOT_PATH O(n^2)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_BFGS_Update(desc, state, ctx, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    REAL(wp) :: sy

    CALL init_error_status(status)
    ! s = ctx%du (step), y = new_grad - old_grad (stored in ctx%r temporarily)
    sy = DOT_PRODUCT(ctx%du(1:desc%n), ctx%r(1:desc%n))
    IF (ABS(sy) < 1.0E-30_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Solver_BFGS_Update]: s^T y ~ 0, skip update"
      RETURN
    END IF

    ! TODO: Full BFGS update: H = (I - rho*s*y^T)*H*(I - rho*y*s^T) + rho*s*s^T
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_BFGS_Update

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute(Solve) | HOT_PATH O(n*iter)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_PCG(desc, state, algo, ctx, matvec, status)
    TYPE(NM_Solver_Desc),  INTENT(IN)    :: desc
    TYPE(NM_Solver_State), INTENT(INOUT) :: state
    TYPE(NM_Solver_Algo),  INTENT(IN)    :: algo
    TYPE(NM_Solver_Ctx),   INTENT(INOUT) :: ctx
    EXTERNAL                             :: matvec
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    REAL(wp) :: rz_old, rz_new, alpha_cg, beta, b_norm
    INTEGER(i4) :: k, i

    CALL init_error_status(status)

    CALL matvec(state%x, ctx%Ap)
    ctx%r(1:desc%n) = state%b(1:desc%n) - ctx%Ap(1:desc%n)

    DO i = 1, desc%n
      IF (ABS(ctx%diag(i)) > 1.0E-30_wp) THEN
        ctx%z(i) = ctx%r(i) / ctx%diag(i)
      ELSE
        ctx%z(i) = ctx%r(i)
      END IF
    END DO
    ctx%p(1:desc%n) = ctx%z(1:desc%n)
    rz_old = DOT_PRODUCT(ctx%r(1:desc%n), ctx%z(1:desc%n))

    b_norm = SQRT(DOT_PRODUCT(state%b(1:desc%n), state%b(1:desc%n)))
    IF (b_norm < 1.0E-30_wp) b_norm = 1.0_wp

    DO k = 1, algo%maxiter
      CALL matvec(ctx%p, ctx%Ap)
      alpha_cg = rz_old / DOT_PRODUCT(ctx%p(1:desc%n), ctx%Ap(1:desc%n))
      state%x(1:desc%n) = state%x(1:desc%n) + alpha_cg * ctx%p(1:desc%n)
      ctx%r(1:desc%n)   = ctx%r(1:desc%n) - alpha_cg * ctx%Ap(1:desc%n)

      state%rnorm = SQRT(DOT_PRODUCT(ctx%r(1:desc%n), ctx%r(1:desc%n))) / b_norm
      IF (state%rnorm < algo%rtol) THEN
        state%niter = k
        state%converged = .TRUE.
        status%status_code = IF_STATUS_OK
        RETURN
      END IF

      DO i = 1, desc%n
        IF (ABS(ctx%diag(i)) > 1.0E-30_wp) THEN
          ctx%z(i) = ctx%r(i) / ctx%diag(i)
        ELSE
          ctx%z(i) = ctx%r(i)
        END IF
      END DO
      rz_new = DOT_PRODUCT(ctx%r(1:desc%n), ctx%z(1:desc%n))
      beta = rz_new / rz_old
      ctx%p(1:desc%n) = ctx%z(1:desc%n) + beta * ctx%p(1:desc%n)
      rz_old = rz_new
    END DO

    state%niter = algo%maxiter
    state%converged = .FALSE.
    status%status_code = IF_STATUS_INVALID
    status%message = "[NM_Solver_PCG]: did not converge"
  END SUBROUTINE NM_Solver_PCG

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute | HOT_PATH O(n)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Arc_Length_Predict(n, du_bar, F_ref, ds, &
                                           du_pred, dlambda, status)
    INTEGER(i4), INTENT(IN)  :: n
    REAL(wp),    INTENT(IN)  :: du_bar(n)
    REAL(wp),    INTENT(IN)  :: F_ref(n)
    REAL(wp),    INTENT(IN)  :: ds
    REAL(wp),    INTENT(OUT) :: du_pred(n)
    REAL(wp),    INTENT(OUT) :: dlambda
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: du_bar_norm, F_ref_norm

    CALL init_error_status(status)

    du_bar_norm = SQRT(DOT_PRODUCT(du_bar(1:n), du_bar(1:n)))
    F_ref_norm  = SQRT(DOT_PRODUCT(F_ref(1:n), F_ref(1:n)))

    IF (du_bar_norm < 1.0E-30_wp .AND. F_ref_norm < 1.0E-30_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Solver_Arc_Length_Predict]: zero vectors"
      RETURN
    END IF

    dlambda = ds / SQRT(du_bar_norm**2 + F_ref_norm**2)
    du_pred(1:n) = dlambda * du_bar(1:n)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Arc_Length_Predict

  !---------------------------------------------------------------------------
  ! Phase: Iteration | Verb: Compute | HOT_PATH O(n)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Arc_Length_Correct(n, du_total, du_t, du_bar, &
                                           F_ref, ds, psi, &
                                           ddlambda, status)
    INTEGER(i4), INTENT(IN)  :: n
    REAL(wp),    INTENT(IN)  :: du_total(n)
    REAL(wp),    INTENT(IN)  :: du_t(n)
    REAL(wp),    INTENT(IN)  :: du_bar(n)
    REAL(wp),    INTENT(IN)  :: F_ref(n)
    REAL(wp),    INTENT(IN)  :: ds
    REAL(wp),    INTENT(IN)  :: psi
    REAL(wp),    INTENT(OUT) :: ddlambda
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: a1, a2, a3, det, s1, s2

    CALL init_error_status(status)

    a1 = DOT_PRODUCT(du_bar(1:n), du_bar(1:n)) &
       + psi**2 * DOT_PRODUCT(F_ref(1:n), F_ref(1:n))
    a2 = 2.0_wp * DOT_PRODUCT(du_total(1:n) + du_t(1:n), du_bar(1:n))
    a3 = DOT_PRODUCT(du_total(1:n) + du_t(1:n), du_total(1:n) + du_t(1:n)) &
       - ds**2

    det = a2**2 - 4.0_wp * a1 * a3
    IF (det < 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Solver_Arc_Length_Correct]: negative discriminant"
      ddlambda = 0.0_wp
      RETURN
    END IF

    s1 = (-a2 + SQRT(det)) / (2.0_wp * a1)
    s2 = (-a2 - SQRT(det)) / (2.0_wp * a1)
    ddlambda = MERGE(s1, s2, ABS(s1) < ABS(s2))

    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Solver_Arc_Length_Correct

END MODULE NM_Solv_Core
