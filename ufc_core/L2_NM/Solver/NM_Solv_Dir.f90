!===============================================================================
! MODULE: NM_Solv_Dir
! LAYER:  L2_NM
! DOMAIN: Solver
! ROLE:   Proc (direct solver procedures)
! BRIEF:  Dense direct solvers - LU / Cholesky (LAPACK wrappers)
!===============================================================================
MODULE NM_Solv_Dir

  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Mtx_Def
  USE NM_Solv_Def
  IMPLICIT NONE

  PRIVATE
  PUBLIC :: Solve_Direct_LU, Solve_Direct_Cholesky

  INTERFACE
    SUBROUTINE DGETRF(M, N, A, LDA, IPIV, INFO) BIND(C, NAME='dgetrf')
      IMPORT :: i4, wp
      INTEGER(i4), VALUE :: m, n, lda
      REAL(wp), INTENT(INOUT) :: a(lda, *)
      INTEGER(i4), INTENT(OUT) :: ipiv(*)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DGETRF

    SUBROUTINE DGETRS(TRANS, N, NRHS, A, LDA, IPIV, B, LDB, INFO) &
        BIND(C, NAME='dgetrs')
      IMPORT :: i4, wp
      CHARACTER(len=1), VALUE :: trans
      INTEGER(i4), VALUE :: n, nrhs, lda, ldb
      REAL(wp), INTENT(IN) :: a(lda, *)
      INTEGER(i4), INTENT(IN) :: ipiv(*)
      REAL(wp), INTENT(INOUT) :: b(ldb, *)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DGETRS

    SUBROUTINE DPOTRF(UPLO, N, A, LDA, INFO) BIND(C, NAME='dpotrf')
      IMPORT :: i4, wp
      CHARACTER(len=1), VALUE :: uplo
      INTEGER(i4), VALUE :: n, lda
      REAL(wp), INTENT(INOUT) :: a(lda, *)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DPOTRF

    SUBROUTINE DPOTRS(UPLO, N, NRHS, A, LDA, B, LDB, INFO) &
        BIND(C, NAME='dpotrs')
      IMPORT :: i4, wp
      CHARACTER(len=1), VALUE :: uplo
      INTEGER(i4), VALUE :: n, nrhs, lda, ldb
      REAL(wp), INTENT(IN) :: a(lda, *)
      REAL(wp), INTENT(INOUT) :: b(ldb, *)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DPOTRS
  END INTERFACE

CONTAINS

  SUBROUTINE Solve_Direct_LU(A, b, x, stats)
    TYPE(DenseMatrix), INTENT(INOUT) :: A
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: x(:)
    TYPE(NM_Solver_State), INTENT(OUT) :: stats

    INTEGER(i4) :: n, lda, info
    INTEGER(i4), ALLOCATABLE :: ipiv(:)
    REAL(wp), ALLOCATABLE :: bx(:, :)
    REAL(wp), ALLOCATABLE :: res(:)
    REAL(wp), ALLOCATABLE :: a_orig(:, :)

    stats%niter = 0
    stats%rnorm = 0.0_wp
    stats%initial_residual = 0.0_wp
    stats%convergence_flag = 0
    stats%solve_time = 0.0_wp

    IF (.NOT. A%is_allocated) THEN
      stats%convergence_flag = 5
      RETURN
    END IF
    IF (.NOT. A%IsSquare()) THEN
      ERROR STOP "Solve_Direct_LU: Matrix must be square"
    END IF

    n = A%nrows
    lda = MAX(1, n)
    IF (SIZE(b) /= n) THEN
      ERROR STOP "Solve_Direct_LU: b dimension mismatch"
    END IF

    ALLOCATE(x(n), bx(n, 1), ipiv(n), a_orig(n, n))
    a_orig = A%data
    bx(:, 1) = b

    CALL DGETRF(n, n, A%data, lda, ipiv, info)
    IF (info < 0) THEN
      ERROR STOP "Solve_Direct_LU: Illegal argument to DGETRF"
    ELSE IF (info > 0) THEN
      stats%convergence_flag = 3
      stats%rnorm = HUGE(1.0_wp)
      stats%initial_residual = Norm_L2(b)
      x = 0.0_wp
      DEALLOCATE(ipiv, bx, a_orig)
      RETURN
    END IF

    CALL DGETRS('N', n, 1, A%data, lda, ipiv, bx, n, info)
    IF (info /= 0) THEN
      ERROR STOP "Solve_Direct_LU: DGETRS failed"
    END IF
    x = bx(:, 1)

    ALLOCATE(res(n))
    res = MATMUL(a_orig, x) - b
    stats%niter = 1
    stats%initial_residual = Norm_L2(b)
    stats%rnorm = Norm_L2(res)
    stats%convergence_flag = 0
    DEALLOCATE(ipiv, bx, res, a_orig)
  END SUBROUTINE Solve_Direct_LU

  SUBROUTINE Solve_Direct_Cholesky(A, b, x, uplo, stats)
    TYPE(DenseMatrix), INTENT(INOUT) :: A
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: x(:)
    CHARACTER(len=1), INTENT(IN), OPTIONAL :: uplo
    TYPE(NM_Solver_State), INTENT(OUT) :: stats

    CHARACTER(len=1) :: ul
    INTEGER(i4) :: n, lda, info
    REAL(wp), ALLOCATABLE :: bx(:, :)
    REAL(wp), ALLOCATABLE :: res(:)
    REAL(wp), ALLOCATABLE :: a_orig(:, :)

    stats%niter = 0
    stats%rnorm = 0.0_wp
    stats%initial_residual = 0.0_wp
    stats%convergence_flag = 0

    IF (.NOT. A%is_allocated) THEN
      stats%convergence_flag = 5
      RETURN
    END IF
    IF (.NOT. A%IsSquare() .OR. .NOT. A%is_symmetric) THEN
      ERROR STOP "Solve_Direct_Cholesky: Symmetric square matrix required"
    END IF

    ul = 'L'
    IF (PRESENT(uplo)) ul = uplo

    n = A%nrows
    lda = MAX(1, n)
    IF (SIZE(b) /= n) THEN
      ERROR STOP "Solve_Direct_Cholesky: b dimension mismatch"
    END IF

    ALLOCATE(x(n), bx(n, 1), a_orig(n, n))
    a_orig = A%data
    bx(:, 1) = b

    CALL DPOTRF(ul, n, A%data, lda, info)
    IF (info < 0) THEN
      ERROR STOP "Solve_Direct_Cholesky: Illegal argument to DPOTRF"
    ELSE IF (info > 0) THEN
      stats%convergence_flag = 4
      stats%rnorm = HUGE(1.0_wp)
      stats%initial_residual = Norm_L2(b)
      x = 0.0_wp
      DEALLOCATE(bx, a_orig)
      RETURN
    END IF

    CALL DPOTRS(ul, n, 1, A%data, lda, bx, n, info)
    IF (info /= 0) THEN
      ERROR STOP "Solve_Direct_Cholesky: DPOTRS failed"
    END IF
    x = bx(:, 1)

    ALLOCATE(res(n))
    res = MATMUL(a_orig, x) - b
    stats%niter = 1
    stats%initial_residual = Norm_L2(b)
    stats%rnorm = Norm_L2(res)
    stats%convergence_flag = 0
    DEALLOCATE(bx, res, a_orig)
  END SUBROUTINE Solve_Direct_Cholesky

  PURE FUNCTION Norm_L2(vec) RESULT(norm_val)
    REAL(wp), INTENT(IN) :: vec(:)
    REAL(wp) :: norm_val
    norm_val = SQRT(DOT_PRODUCT(vec, vec))
  END FUNCTION Norm_L2

END MODULE NM_Solv_Dir