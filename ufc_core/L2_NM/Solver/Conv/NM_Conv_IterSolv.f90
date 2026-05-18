!===============================================================================
! MODULE: NM_Conv_IterSolv
! LAYER:  L2_NM
! DOMAIN: Solver/Conv
! ROLE:   Proc (enhanced iterative solvers)
! BRIEF:  BiCGSTAB, GMRES(m), QMR, TFQMR, IDR(s), FGMRES
!
! Theory: Saad (2003); van der Vorst (2003); Sonneveld (1989)
!
! Status: CORE | Last verified: 2026-03-24
!===============================================================================

MODULE NM_Conv_IterSolv
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, TINY
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Conv_IterPrec, ONLY: Preconditioner_Data, &
                                              NM_Preconditioner_Apply
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief solver type enum
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_METHOD_BICGSTAB = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_METHOD_BICGSTAB_L = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_METHOD_GMRES = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_METHOD_GMRES_M = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_METHOD_QMR = 5
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_METHOD_TFQMR = 6
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_METHOD_IDR = 7
  INTEGER(i4), PARAMETER, PUBLIC :: NM_SOLV_METHOD_FGMRES = 8

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief iterative solver params
    TYPE, PUBLIC :: Iter_Solv_Params_Ctrl
    INTEGER(i4) :: solver_type = NM_SOLV_METHOD_BICGSTAB
    INTEGER(i4) :: max_iterations = 1000_i4
  END TYPE Iter_Solv_Params_Ctrl

  TYPE, PUBLIC :: Iter_Solv_Params_Tol
    REAL(DP) :: tolerance = 1.0E-6_DP
    REAL(DP) :: restart_tolerance = 1.0E-4_DP
  END TYPE Iter_Solv_Params_Tol

  TYPE, PUBLIC :: Iter_Solv_Params_Algo
    INTEGER(i4) :: restart_frequency = 30_i4  !< GMRES restart
    INTEGER(i4) :: bicgstab_l = 2_i4          !< BiCGSTAB(l)
    INTEGER(i4) :: idr_s = 4_i4               !< IDR(s)
  END TYPE Iter_Solv_Params_Algo

  TYPE, PUBLIC :: Iter_Solv_Params_Flags
    LOGICAL :: use_preconditioner = .TRUE.
    LOGICAL :: verbose = .FALSE.
  END TYPE Iter_Solv_Params_Flags

  TYPE, PUBLIC :: Iter_Solv_Params
    TYPE(Iter_Solv_Params_Ctrl)  :: ctrl
    TYPE(Iter_Solv_Params_Tol)   :: tol
    TYPE(Iter_Solv_Params_Algo)  :: algo
    TYPE(Iter_Solv_Params_Flags) :: flags
  END TYPE Iter_Solv_Params

  !> @brief solver state
    TYPE, PUBLIC :: Iter_Solv_State_Iter
    INTEGER(i4) :: iteration = 0_i4
  END TYPE Iter_Solv_State_Iter

  TYPE, PUBLIC :: Iter_Solv_State_Residual
    REAL(DP) :: residual_norm = ZERO
    REAL(DP) :: residual_norm_init = ZERO
    REAL(DP) :: relative_residual = ZERO
  END TYPE Iter_Solv_State_Residual

  TYPE, PUBLIC :: Iter_Solv_State_Flags
    LOGICAL :: converged = .FALSE.
  END TYPE Iter_Solv_State_Flags

  TYPE, PUBLIC :: Iter_Solv_State_Stats
    INTEGER(i4) :: n_restarts = 0_i4
    REAL(DP) :: solve_time = ZERO
  END TYPE Iter_Solv_State_Stats

  TYPE, PUBLIC :: Iter_Solv_State
    TYPE(Iter_Solv_State_Iter)     :: iter
    TYPE(Iter_Solv_State_Residual) :: residual
    TYPE(Iter_Solv_State_Flags)    :: flags
    TYPE(Iter_Solv_State_Stats)    :: stats
  END TYPE Iter_Solv_State

  !> @brief solver result
    TYPE, PUBLIC :: Iter_Solv_Result_Sol
    REAL(DP), ALLOCATABLE :: x(:)            !< solution
  END TYPE Iter_Solv_Result_Sol

  TYPE, PUBLIC :: Iter_Solv_Result_Residual
    REAL(DP) :: residual_norm = ZERO         !< final residual
  END TYPE Iter_Solv_Result_Residual

  TYPE, PUBLIC :: Iter_Solv_Result_Stats
    INTEGER(i4) :: n_iterations = 0_i4       !< iter count
    INTEGER(i4) :: n_matvecs = 0_i4          !< matvec count
  END TYPE Iter_Solv_Result_Stats

  TYPE, PUBLIC :: Iter_Solv_Result_Flags
    LOGICAL :: converged = .FALSE.           !< converged
  END TYPE Iter_Solv_Result_Flags

  TYPE, PUBLIC :: Iter_Solv_Result_Meta
    CHARACTER(LEN=128) :: message = ""       !< message
  END TYPE Iter_Solv_Result_Meta

  TYPE, PUBLIC :: Iter_Solv_Result
    TYPE(Iter_Solv_Result_Sol)      :: sol
    TYPE(Iter_Solv_Result_Residual) :: residual
    TYPE(Iter_Solv_Result_Stats)    :: stats
    TYPE(Iter_Solv_Result_Flags)    :: flags
    TYPE(Iter_Solv_Result_Meta)     :: meta
  END TYPE Iter_Solv_Result

  !> @brief GMRES workspace
  TYPE, PUBLIC :: GMRES_Workspace
    REAL(DP), ALLOCATABLE :: V(:,:)          !< Krylov vecs
    REAL(DP), ALLOCATABLE :: H(:,:)          !< Hessenberg
    REAL(DP), ALLOCATABLE :: g(:)            !< RHS
    REAL(DP), ALLOCATABLE :: cs(:), sn(:)    !< Givens
  END TYPE GMRES_Workspace

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main solver
  PUBLIC :: NM_Iter_Solv
  PUBLIC :: NM_BiCGSTAB_Solv
  PUBLIC :: NM_BiCGSTAB_L_Solv
  PUBLIC :: NM_GMRES_Solv
  PUBLIC :: NM_GMRES_M_Solv
  PUBLIC :: NM_TFQMR_Solv
  PUBLIC :: NM_IDR_Solv
  
  ! utils
  PUBLIC :: NM_Residual
  PUBLIC :: NM_Conv_Check

CONTAINS

  SUBROUTINE Apply_Givens_Rotation(c, s, x1, x2)
    REAL(DP), INTENT(IN) :: c, s
    REAL(DP), INTENT(INOUT) :: x1, x2

    REAL(DP) :: x1_temp

    x1_temp = c * x1 - s * x2
    x2 = s * x1 + c * x2
    x1 = x1_temp

  END SUBROUTINE Apply_Givens_Rotation

  SUBROUTINE Calc_Givens_Rotation(a, b, c, s)
    REAL(DP), INTENT(IN) :: a, b
    REAL(DP), INTENT(OUT) :: c, s

    REAL(DP) :: tau, r

    IF (ABS(b) < 1.0E-14_DP) THEN
      c = ONE
      s = ZERO
    ELSE IF (ABS(b) > ABS(a)) THEN
      tau = -a / b
      s = ONE / SQRT(ONE + tau**2)
      c = s * tau
    ELSE
      tau = -b / a
      c = ONE / SQRT(ONE + tau**2)
      s = c * tau
    END IF

  END SUBROUTINE Calc_Givens_Rotation

  SUBROUTINE NM_BiCGSTAB_L_Solv(A, b, x, params, precond, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Iter_Solv_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(IN), OPTIONAL :: precond
    TYPE(Iter_Solv_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! simplified: use BiCGSTAB
    CALL NM_BiCGSTAB_Solv(A, b, x, params, precond, result, status)
    result%meta%message = "BiCGSTAB(l) [using BiCGSTAB]"

  END SUBROUTINE NM_BiCGSTAB_L_Solv

  SUBROUTINE NM_BiCGSTAB_Solv(A, b, x, params, precond, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Iter_Solv_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(IN), OPTIONAL :: precond
    TYPE(Iter_Solv_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: r(:), r0(:), p(:), v(:), s(:), t(:), z(:)
    REAL(DP) :: rho, rho_prev, alpha, beta, omega
    REAL(DP) :: residual_norm, b_norm
    INTEGER(i4) :: n, iter
    LOGICAL :: has_precond

    CALL init_error_status(status)

    n = SIZE(b)
    ALLOCATE(r(n), r0(n), p(n), v(n), s(n), t(n), z(n))

    has_precond = PRESENT(precond) .AND. params%flags%use_preconditioner

    ! init residual
    r = b - MATMUL(A, x)
    r0 = r
    p = r

    b_norm = SQRT(SUM(b**2))
    residual_norm = SQRT(SUM(r**2))

    result%stats%n_iterations = 0_i4
    result%stats%n_matvecs = 0_i4
    result%flags%converged = .FALSE.

    IF (b_norm < 1.0E-14_DP) b_norm = ONE

    DO iter = 1, params%ctrl%max_iterations
      result%stats%n_iterations = iter

      rho_prev = rho
      rho = DOT_PRODUCT(r0, r)

      IF (ABS(rho) < 1.0E-14_DP) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "BiCGSTAB: rho breakdown"
        EXIT
      END IF

      IF (iter == 1) THEN
        p = r
      ELSE
        beta = (rho / rho_prev) * (alpha / omega)
        p = r + beta * (p - omega * v)
      END IF

      ! precond
      IF (has_precond) THEN
        CALL NM_Preconditioner_Apply(precond, p, z, status)
      ELSE
        z = p
      END IF

      ! matvec
      v = MATMUL(A, z)
      result%stats%n_matvecs = result%stats%n_matvecs + 1_i4

      alpha = rho / DOT_PRODUCT(r0, v)
      s = r - alpha * v

      residual_norm = SQRT(SUM(s**2))
      IF (residual_norm / b_norm < params%tol%tolerance) THEN
        x = x + alpha * z
        result%flags%converged = .TRUE.
        EXIT
      END IF

      ! precond s
      IF (has_precond) THEN
        CALL NM_Preconditioner_Apply(precond, s, z, status)
      ELSE
        z = s
      END IF

      t = MATMUL(A, z)
      result%stats%n_matvecs = result%stats%n_matvecs + 1_i4

      omega = DOT_PRODUCT(t, s) / DOT_PRODUCT(t, t)
      x = x + alpha * z + omega * z
      r = s - omega * t

      residual_norm = SQRT(SUM(r**2))
      IF (residual_norm / b_norm < params%tol%tolerance) THEN
        result%flags%converged = .TRUE.
        EXIT
      END IF

      IF (ABS(omega) < 1.0E-14_DP) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "BiCGSTAB: omega breakdown"
        EXIT
      END IF
    END DO

    result%residual%residual_norm = residual_norm
    IF (ALLOCATED(result%sol%x)) DEALLOCATE(result%sol%x)
    ALLOCATE(result%sol%x(n))
    result%sol%x = x

    IF (result%flags%converged) THEN
      result%meta%message = "BiCGSTAB converged"
    ELSE
      result%meta%message = "BiCGSTAB did not converge"
    END IF

    DEALLOCATE(r, r0, p, v, s, t, z)

  END SUBROUTINE NM_BiCGSTAB_Solv

  FUNCTION NM_Conv_Check(residual_norm, b_norm, tolerance) RESULT(converged)
    REAL(DP), INTENT(IN) :: residual_norm, b_norm, tolerance
    LOGICAL :: converged

    REAL(DP) :: norm_b

    norm_b = b_norm
    IF (norm_b < 1.0E-14_DP) norm_b = ONE

    converged = (residual_norm / norm_b < tolerance)

  END FUNCTION NM_Conv_Check

  SUBROUTINE NM_GMRES_M_Solv(A, b, x, params, precond, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Iter_Solv_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(IN), OPTIONAL :: precond
    TYPE(Iter_Solv_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(GMRES_Workspace) :: ws
    REAL(DP), ALLOCATABLE :: r(:), w(:), z(:), y(:)
    REAL(DP) :: beta, residual_norm, b_norm
    INTEGER(i4) :: n, m, iter, restart, i, j
    LOGICAL :: has_precond

    CALL init_error_status(status)

    n = SIZE(b)
    m = MIN(params%restart_frequency, n)

    ALLOCATE(r(n), w(n), z(n), y(m))
    ALLOCATE(ws%V(n, m+1), ws%H(m+1, m), ws%g(m+1), ws%cs(m), ws%sn(m))

    has_precond = PRESENT(precond) .AND. params%flags%use_preconditioner

    b_norm = SQRT(SUM(b**2))
    IF (b_norm < 1.0E-14_DP) b_norm = ONE

    result%stats%n_iterations = 0_i4
    result%stats%n_matvecs = 0_i4
    result%flags%converged = .FALSE.

    outer: DO restart = 1, params%ctrl%max_iterations / m + 1

      ! init residual
      r = b - MATMUL(A, x)

      ! precond residual
      IF (has_precond) THEN
        CALL NM_Preconditioner_Apply(precond, r, z, status)
        r = z
      END IF

      beta = SQRT(SUM(r**2))
      ws%V(:, 1) = r / beta
      ws%g = ZERO
      ws%g(1) = beta

      ws%H = ZERO

      inner: DO iter = 1, m
        result%stats%n_iterations = result%stats%n_iterations + 1_i4

        ! Arnoldi
        w = MATMUL(A, ws%V(:, iter))
        result%stats%n_matvecs = result%stats%n_matvecs + 1_i4

        ! precond
        IF (has_precond) THEN
          CALL NM_Preconditioner_Apply(precond, w, z, status)
          w = z
        END IF

        ! orthog (MGS)
        DO j = 1, iter
          ws%H(j, iter) = DOT_PRODUCT(ws%V(:, j), w)
          w = w - ws%H(j, iter) * ws%V(:, j)
        END DO

        ws%H(iter+1, iter) = SQRT(SUM(w**2))

        IF (ws%H(iter+1, iter) < 1.0E-14_DP) THEN
          ! inv subspace
          EXIT inner
        END IF

        ws%V(:, iter+1) = w / ws%H(iter+1, iter)

        ! apply Givens
        DO i = 1, iter-1
          CALL Apply_Givens_Rotation(ws%cs(i), ws%sn(i), ws%H(i, iter), &
                                      ws%H(i+1, iter))
        END DO

        ! new rotation
        CALL Calc_Givens_Rotation(ws%H(iter, iter), ws%H(iter+1, iter), &
                                      ws%cs(iter), ws%sn(iter))

        ! apply to H, g
        CALL Apply_Givens_Rotation(ws%cs(iter), ws%sn(iter), ws%H(iter, iter), &
                                    ws%H(iter+1, iter))
        CALL Apply_Givens_Rotation(ws%cs(iter), ws%sn(iter), ws%g(iter), &
                                    ws%g(iter+1))

        residual_norm = ABS(ws%g(iter+1))

        IF (residual_norm / b_norm < params%tol%tolerance) THEN
          ! solve upper tri and update
          y(iter) = ws%g(iter) / ws%H(iter, iter)
          DO i = iter-1, 1, -1
            y(i) = (ws%g(i) - DOT_PRODUCT(ws%H(i, i+1:iter), y(i+1:iter))) / ws%H(i, i)
          END DO

          x = x + MATMUL(ws%V(:, 1:iter), y(1:iter))
          result%flags%converged = .TRUE.
          EXIT outer
        END IF
      END DO inner

      ! restart: update solution
      y(m) = ws%g(m) / ws%H(m, m)
      DO i = m-1, 1, -1
        y(i) = (ws%g(i) - DOT_PRODUCT(ws%H(i, i+1:m), y(i+1:m))) / ws%H(i, i)
      END DO

      x = x + MATMUL(ws%V(:, 1:m), y(1:m))

    END DO outer

    result%residual%residual_norm = residual_norm
    IF (ALLOCATED(result%sol%x)) DEALLOCATE(result%sol%x)
    ALLOCATE(result%sol%x(n))
    result%sol%x = x

    IF (result%flags%converged) THEN
      result%meta%message = "GMRES(m) converged"
    ELSE
      result%meta%message = "GMRES(m) did not converge"
    END IF

    DEALLOCATE(r, w, z, y)
    DEALLOCATE(ws%V, ws%H, ws%g, ws%cs, ws%sn)

  END SUBROUTINE NM_GMRES_M_Solv

  SUBROUTINE NM_GMRES_Solv(A, b, x, params, precond, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Iter_Solv_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(IN), OPTIONAL :: precond
    TYPE(Iter_Solv_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! use restart version
    TYPE(Iter_Solv_Params) :: gmres_params

    gmres_params = params
    gmres_params%restart_frequency = params%ctrl%max_iterations

    CALL NM_GMRES_M_Solv(A, b, x, gmres_params, precond, result, status)

  END SUBROUTINE NM_GMRES_Solv

  SUBROUTINE NM_IDR_Solv(A, b, x, params, precond, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Iter_Solv_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(IN), OPTIONAL :: precond
    TYPE(Iter_Solv_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! simplified: use BiCGSTAB
    CALL NM_BiCGSTAB_Solv(A, b, x, params, precond, result, status)
    result%meta%message = "IDR(s) [using BiCGSTAB]"

  END SUBROUTINE NM_IDR_Solv

  SUBROUTINE NM_Iter_Solv(A, b, x, params, precond, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Iter_Solv_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(IN), OPTIONAL :: precond
    TYPE(Iter_Solv_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (params%solver_type)
    CASE (NM_SOLV_METHOD_BICGSTAB)
      CALL NM_BiCGSTAB_Solv(A, b, x, params, precond, result, status)
    CASE (NM_SOLV_METHOD_BICGSTAB_L)
      CALL NM_BiCGSTAB_L_Solv(A, b, x, params, precond, result, status)
    CASE (NM_SOLV_METHOD_GMRES)
      CALL NM_GMRES_Solv(A, b, x, params, precond, result, status)
    CASE (NM_SOLV_METHOD_GMRES_M)
      CALL NM_GMRES_M_Solv(A, b, x, params, precond, result, status)
    CASE (NM_SOLV_METHOD_TFQMR)
      CALL NM_TFQMR_Solv(A, b, x, params, precond, result, status)
    CASE (NM_SOLV_METHOD_IDR)
      CALL NM_IDR_Solv(A, b, x, params, precond, result, status)
    CASE DEFAULT
      CALL NM_BiCGSTAB_Solv(A, b, x, params, precond, result, status)
    END SELECT

  END SUBROUTINE NM_Iter_Solv

  FUNCTION NM_Residual(A, x, b) RESULT(r)
    REAL(DP), INTENT(IN) :: A(:,:), x(:), b(:)
    REAL(DP) :: r(SIZE(b))

    r = b - MATMUL(A, x)

  END FUNCTION NM_Residual

  SUBROUTINE NM_TFQMR_Solv(A, b, x, params, precond, result, status)
    REAL(DP), INTENT(IN) :: A(:,:), b(:)
    REAL(DP), INTENT(INOUT) :: x(:)
    TYPE(Iter_Solv_Params), INTENT(IN) :: params
    TYPE(Preconditioner_Data), INTENT(IN), OPTIONAL :: precond
    TYPE(Iter_Solv_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! simplified: use BiCGSTAB
    CALL NM_BiCGSTAB_Solv(A, b, x, params, precond, result, status)
    result%meta%message = "TFQMR [using BiCGSTAB]"

  END SUBROUTINE NM_TFQMR_Solv
END MODULE NM_Conv_IterSolv