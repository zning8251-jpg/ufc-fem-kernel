!===============================================================================
! MODULE: NM_Solv_SparseInterface
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Brg (unified CSR/COO interface to sparse solvers: PARDISO/MUMPS/CG/GMRES)
! BRIEF:  Sparse linear solver interface for K_t * du = R
!
! Status: STUB | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_SparseInterface
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_Solv_LinDir, ONLY: CSR_Matrix
  USE NM_Mtx_Core, ONLY: UF_CSRMatrix
  ! NM_LinearSolver not used here to avoid L2 build-order dependency; local types + stub Solve_UF
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: NM_SparseSolver_Init
  PUBLIC :: NM_SparseSolver_Factorize
  PUBLIC :: NM_SparseSolver_Solve
  PUBLIC :: NM_SparseSolver_Solve_UF
  PUBLIC :: NM_SparseSolver_Finalize
  PUBLIC :: SparseSolver_Config
  ! UF_LinSolParams, UF_LinSolResult are TYPE, PUBLIC above

  !-----------------------------------------------------------------------------
  ! Local types for UF path (match NM_LinearSolver for API compatibility; stub Solve_UF)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: UF_LinSolParams
    INTEGER(i4) :: solver_type = 0
    INTEGER(i4) :: max_iter = 1000
    REAL(wp) :: tol = 1.0E-10_wp
    INTEGER(i4) :: restart = 30
    INTEGER(i4) :: precond_type = 2
    INTEGER(i4) :: lfil = 10
    REAL(wp) :: droptol = 1.0E-4_wp
    INTEGER(i4) :: size_threshold = 5000
    LOGICAL :: is_symmetric = .FALSE.
    LOGICAL :: verbose = .FALSE.
  END TYPE UF_LinSolParams

  TYPE, PUBLIC :: UF_LinSolResult
    INTEGER(i4) :: solver_used = 0
    INTEGER(i4) :: iterations = 0
    REAL(wp) :: residual = 0.0_wp
    REAL(wp) :: solve_time = 0.0_wp
    INTEGER(i4) :: status = 0
  END TYPE UF_LinSolResult

  !-----------------------------------------------------------------------------
  ! Type: SparseSolver_Config
  ! Purpose: Configuration for sparse solver
  !-----------------------------------------------------------------------------
  TYPE :: SparseSolver_Config
    CHARACTER(LEN=32) :: solver_type = "CG"          ! "CG", "GMRES", "PARDISO", "MUMPS"
    CHARACTER(LEN=32) :: precond_type = "ILU0"       ! "ILU0", "Jacobi", "SSOR", "NONE"
    INTEGER(i4) :: max_iter = 1000
    REAL(wp) :: tol_rel = 1.0e-8_wp
    REAL(wp) :: tol_abs = 1.0e-10_wp
    LOGICAL :: use_gpu = .FALSE.
    LOGICAL :: verbose = .FALSE.
  END TYPE SparseSolver_Config

  !-----------------------------------------------------------------------------
  ! Type: SparseSolver_Context
  ! Purpose: Internal state for solver (factorization, preconditioner)
  !-----------------------------------------------------------------------------
  TYPE :: SparseSolver_Context
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_factorized = .FALSE.
    TYPE(SparseSolver_Config) :: config
    ! TODO: Add solver-specific state (e.g., PARDISO handle, CG workspace)
  END TYPE SparseSolver_Context

CONTAINS

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_SparseSolver_Init
  ! Purpose: Initialize sparse solver with configuration
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparseSolver_Init(config, ctx, status)
    TYPE(SparseSolver_Config), INTENT(IN) :: config
    TYPE(SparseSolver_Context), INTENT(OUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = IF_STATUS_OK

    ctx%config = config
    ctx%is_initialized = .TRUE.
    ctx%is_factorized = .FALSE.

    IF (config%verbose) THEN
      PRINT *, "[NM_SparseSolver] Initialized with solver_type=", TRIM(config%solver_type)
    END IF

  END SUBROUTINE NM_SparseSolver_Init

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_SparseSolver_Factorize
  ! Purpose: Factorize K matrix (for direct solvers)
  ! Note: For iterative solvers, this builds preconditioner
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparseSolver_Factorize(K, ctx, status)
    TYPE(CSR_Matrix), INTENT(IN) :: K
    TYPE(SparseSolver_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = IF_STATUS_OK

    IF (.NOT. ctx%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "Solver not initialized"
      RETURN
    END IF

    SELECT CASE (TRIM(ctx%config%solver_type))

      CASE ("PARDISO")
        ! TODO: call PARDISO symbolic+numeric factorization
        status%status_code = IF_STATUS_ERROR
        status%message = "PARDISO factorization not yet implemented"
        RETURN

      CASE ("MUMPS")
        ! TODO: call MUMPS factorization
        status%status_code = IF_STATUS_ERROR
        status%message = "MUMPS factorization not yet implemented"
        RETURN

      CASE ("CG", "GMRES")
        ! Iterative solver: build preconditioner
        IF (TRIM(ctx%config%precond_type) == "ILU0") THEN
          ! TODO: compute ILU(0) factorization
          status%status_code = IF_STATUS_ERROR
          status%message = "ILU0 preconditioner not yet implemented"
          RETURN
        END IF

      CASE DEFAULT
        status%status_code = IF_STATUS_ERROR
        status%message = "Unknown solver type"
        RETURN

    END SELECT

    ctx%is_factorized = .TRUE.

    IF (ctx%config%verbose) THEN
      PRINT *, "[NM_SparseSolver] Factorization completed"
    END IF

  END SUBROUTINE NM_SparseSolver_Factorize

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_SparseSolver_Solve
  ! Purpose: Solve K · x = b
  ! Input:
  !   K       : CSR stiffness matrix
  !   b       : Right-hand side vector
  !   x_init  : Initial guess (for iterative solvers)
  ! Output:
  !   x       : Solution vector
  !   n_iter  : Number of iterations (iterative only)
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparseSolver_Solve(K, b, x_init, ctx, x, n_iter, status)
    TYPE(CSR_Matrix), INTENT(IN) :: K
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(IN), OPTIONAL :: x_init(:)
    TYPE(SparseSolver_Context), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(OUT) :: n_iter
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: residual_norm, tol
    INTEGER(i4) :: n

    status%status_code = IF_STATUS_OK
    n_iter = 0
    n = SIZE(b)

    IF (.NOT. ctx%is_initialized) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "Solver not initialized"
      RETURN
    END IF

    IF (SIZE(x) /= n) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "Dimension mismatch: x and b"
      RETURN
    END IF

    SELECT CASE (TRIM(ctx%config%solver_type))

      CASE ("PARDISO")
        ! TODO: call PARDISO solve
        status%status_code = IF_STATUS_ERROR
        status%message = "PARDISO solve not yet implemented"
        RETURN

      CASE ("MUMPS")
        ! TODO: call MUMPS solve
        status%status_code = IF_STATUS_ERROR
        status%message = "MUMPS solve not yet implemented"
        RETURN

      CASE ("CG")
        ! Conjugate Gradient (symmetric positive-definite only)
        CALL NM_Solve_CG(K, b, x_init, ctx, x, n_iter, residual_norm, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        IF (ctx%config%verbose) THEN
          PRINT *, "[NM_SparseSolver] CG converged in ", n_iter, " iterations, ||r||=", residual_norm
        END IF

      CASE ("GMRES")
        ! TODO: GMRES implementation
        status%status_code = IF_STATUS_ERROR
        status%message = "GMRES not yet implemented"
        RETURN

      CASE DEFAULT
        status%status_code = IF_STATUS_ERROR
        status%message = "Unknown solver type"
        RETURN

    END SELECT

  END SUBROUTINE NM_SparseSolver_Solve

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_SparseSolver_Solve_UF
  ! Purpose: Solve A·x = b using UF_CSRMatrix. Stub when NM_LinearSolver not linked.
  !          Full implementation would call lin_solve from NM_LinearSolver.
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparseSolver_Solve_UF(A, b, x, params, result, ierr)
    TYPE(UF_CSRMatrix), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    TYPE(UF_LinSolParams), INTENT(IN) :: params
    TYPE(UF_LinSolResult), INTENT(OUT) :: result
    INTEGER(i4), INTENT(OUT) :: ierr

    x = 0.0_wp
    result%solver_used = 0
    result%iterations = 0
    result%residual = -1.0_wp
    result%solve_time = 0.0_wp
    result%status = -1
    ierr = -1
  END SUBROUTINE NM_SparseSolver_Solve_UF

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_Solve_CG (Internal)
  ! Purpose: Conjugate Gradient iterative solver
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_Solve_CG(K, b, x_init, ctx, x, n_iter, residual_norm, status)
    TYPE(CSR_Matrix), INTENT(IN) :: K
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(IN), OPTIONAL :: x_init(:)
    TYPE(SparseSolver_Context), INTENT(IN) :: ctx
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4), INTENT(OUT) :: n_iter
    REAL(wp), INTENT(OUT) :: residual_norm
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: r(:), p(:), Ap(:), z(:)
    REAL(wp) :: alpha, beta, rz_old, rz_new, pAp
    INTEGER(i4) :: n, iter

    status%status_code = IF_STATUS_OK
    n = SIZE(b)

    ALLOCATE(r(n), p(n), Ap(n), z(n))

    ! Initialize x
    IF (PRESENT(x_init)) THEN
      x = x_init
    ELSE
      x = 0.0_wp
    END IF

    ! r = b - K·x
    CALL CSR_MatVec(K, x, Ap)
    r = b - Ap

    ! Precondition z = M^{-1}*r
    z = r  ! Stub: no preconditioner (Jacobi: z = r/diag(K))

    p = z
    rz_old = DOT_PRODUCT(r, z)

    DO iter = 1, ctx%config%max_iter
      ! Ap = K·p
      CALL CSR_MatVec(K, p, Ap)

      pAp = DOT_PRODUCT(p, Ap)
      IF (ABS(pAp) < 1.0e-30_wp) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "CG breakdown: pAp = 0"
        DEALLOCATE(r, p, Ap, z)
        RETURN
      END IF

      alpha = rz_old / pAp

      x = x + alpha * p
      r = r - alpha * Ap

      residual_norm = SQRT(DOT_PRODUCT(r, r))
      IF (residual_norm < ctx%config%tol_abs) EXIT

      z = r  ! Precondition (stub)
      rz_new = DOT_PRODUCT(r, z)
      beta = rz_new / rz_old
      p = z + beta * p

      rz_old = rz_new
    END DO

    n_iter = iter
    DEALLOCATE(r, p, Ap, z)

  END SUBROUTINE NM_Solve_CG

  !-----------------------------------------------------------------------------
  ! Subroutine: CSR_MatVec (Internal)
  ! Purpose: Sparse matrix-vector product y = A·x (CSR format)
  !-----------------------------------------------------------------------------
  SUBROUTINE CSR_MatVec(A, x, y)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)

    INTEGER(i4) :: i, j, k

    y = 0.0_wp

    DO i = 1, A%n_rows
      DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
        j = A%col_idx(k)
        y(i) = y(i) + A%values(k) * x(j)
      END DO
    END DO

  END SUBROUTINE CSR_MatVec

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_SparseSolver_Finalize
  ! Purpose: Clean up solver resources
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_SparseSolver_Finalize(ctx, status)
    TYPE(SparseSolver_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    status%status_code = IF_STATUS_OK

    ! TODO: release solver-specific resources (PARDISO/MUMPS handles)

    ctx%is_initialized = .FALSE.
    ctx%is_factorized = .FALSE.

  END SUBROUTINE NM_SparseSolver_Finalize

END MODULE NM_Solv_SparseInterface