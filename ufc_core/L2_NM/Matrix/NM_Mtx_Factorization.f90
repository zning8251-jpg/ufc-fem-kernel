!===============================================================================
! MODULE: NM_Mtx_Factorization
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Proc — LU/Cholesky/QR decomposition and determinant computation
! BRIEF:  Matrix factorization routines wrapping LAPACK (DGETRF/DPOTRF)
!===============================================================================
MODULE NM_Mtx_Factorization
  
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Mtx_Def
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: NM_LU_Decompose, NM_LU_Solve
  PUBLIC :: NM_Cholesky_Decompose, NM_Cholesky_Solve
  PUBLIC :: NM_Determinant_LU, NM_Determinant_Cholesky
  PUBLIC :: NM_QR_Decompose
  
  ! LAPACK接口声明
  INTERFACE
    ! LU 分解：DGETRF
    SUBROUTINE DGETRF(M, N, A, LDA, IPIV, INFO) BIND(C, NAME='dgetrf')
      IMPORT :: i4, wp
      INTEGER(i4), VALUE :: m, n, lda
      REAL(wp), INTENT(INOUT) :: a(lda,*)
      INTEGER(i4), INTENT(OUT) :: ipiv(*)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DGETRF
    
    ! LU 回代：DGETRS
    SUBROUTINE DGETRS(TRANS, N, NRHS, A, LDA, IPIV, B, LDB, INFO) &
         BIND(C, NAME='dgetrs')
      IMPORT :: i4, wp
      CHARACTER(len=1), VALUE :: trans
      INTEGER(i4), VALUE :: n, nrhs, lda, ldb
      REAL(wp), INTENT(IN) :: a(lda,*)
      INTEGER(i4), INTENT(IN) :: ipiv(*)
      REAL(wp), INTENT(INOUT) :: b(ldb,*)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DGETRS
    
    ! Cholesky 分解：DPOTRF
    SUBROUTINE DPOTRF(UPLO, N, A, LDA, INFO) BIND(C, NAME='dpotrf')
      IMPORT :: i4, wp
      CHARACTER(len=1), VALUE :: uplo
      INTEGER(i4), VALUE :: n, lda
      REAL(wp), INTENT(INOUT) :: a(lda,*)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DPOTRF
    
    ! Cholesky 回代：DPOTRS
    SUBROUTINE DPOTRS(UPLO, N, NRHS, A, LDA, B, LDB, INFO) &
         BIND(C, NAME='dpotrs')
      IMPORT :: i4, wp
      CHARACTER(len=1), VALUE :: uplo
      INTEGER(i4), VALUE :: n, nrhs, lda, ldb
      REAL(wp), INTENT(IN) :: a(lda,*)
      REAL(wp), INTENT(INOUT) :: b(ldb,*)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DPOTRS

    SUBROUTINE DGEQRF(M, N, A, LDA, TAU, WORK, LWORK, INFO) BIND(C, NAME='dgeqrf')
      IMPORT :: i4, wp
      INTEGER(i4), VALUE :: m, n, lda, lwork
      REAL(wp), INTENT(INOUT) :: a(lda,*)
      REAL(wp), INTENT(OUT) :: tau(*)
      REAL(wp), INTENT(INOUT) :: work(*)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DGEQRF

    SUBROUTINE DORGQR(M, N, K, A, LDA, TAU, WORK, LWORK, INFO) BIND(C, NAME='dorgqr')
      IMPORT :: i4, wp
      INTEGER(i4), VALUE :: m, n, k, lda, lwork
      REAL(wp), INTENT(INOUT) :: a(lda,*)
      REAL(wp), INTENT(IN) :: tau(*)
      REAL(wp), INTENT(INOUT) :: work(*)
      INTEGER(i4), INTENT(OUT) :: info
    END SUBROUTINE DORGQR
  END INTERFACE
  
CONTAINS
  
  !===========================================================================
  ! LU 分解 (DGETRF 封装)
  !===========================================================================
  
  SUBROUTINE NM_LU_Decompose(A, ipiv, info)
    ! 伪代码：A = P*L*U (部分主元 LU 分解)
    ! 优化：调�?LAPACK DGETRF，采用分块算法提�?cache 命中�?
    TYPE(DenseMatrix), INTENT(INOUT) :: A
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: ipiv(:)
    INTEGER(i4), INTENT(OUT) :: info
    
    INTEGER(i4) :: n, lda
    
    ! 检查是否为方阵
    IF (.NOT. A%IsSquare()) THEN
      ERROR STOP "NM_LU_Decompose: Matrix must be square"
    END IF
    
    n = A%nrows
    lda = MAX(1, n)
    
    ! 分配主元数组
    ALLOCATE(ipiv(n))
    
    ! 调用 DGETRF
    CALL DGETRF(n, n, A%data, lda, ipiv, info)
    
    ! 检查分解是否成�?
    IF (info < 0) THEN
      ERROR STOP "NM_LU_Decompose: Illegal argument to DGETRF"
    ELSE IF (info > 0) THEN
      ! U(i,i) = 0，矩阵奇�?
      ! 可以继续，但求解时会失败
    END IF
  END SUBROUTINE NM_LU_Decompose
  
  SUBROUTINE NM_LU_Solve(A, ipiv, B, X, trans)
    ! 使用 LU 分解结果求解线性方程组 AX = B
    ! 伪代码：X = A^(-1)*B
    TYPE(DenseMatrix), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: ipiv(:)
    REAL(wp), INTENT(IN) :: B(:,:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: X(:,:)
    CHARACTER(len=1), INTENT(IN), OPTIONAL :: trans
    
    CHARACTER(len=1) :: t
    INTEGER(i4) :: n, nrhs, lda, ldb, info
    
    t = 'N'
    IF (PRESENT(trans)) t = trans
    
    n = A%nrows
    nrhs = SIZE(B, 2)
    lda = MAX(1, n)
    ldb = MAX(1, n)
    
    ! 分配解空间并复制右端�?
    ALLOCATE(X(n, nrhs))
    X = B
    
    ! 调用 DGETRS 回代
    CALL DGETRS(t, n, nrhs, A%data, lda, ipiv, X, ldb, info)
    
    IF (info /= 0) THEN
      ERROR STOP "NM_LU_Solve: DGETRS failed"
    END IF
  END SUBROUTINE NM_LU_Solve
  
  !===========================================================================
  ! Cholesky 分解 (DPOTRF 封装)
  !===========================================================================
  
  SUBROUTINE NM_Cholesky_Decompose(A, uplo, info)
    ! 伪代码：A = L*L^T (对称正定矩阵)
    ! 优化：调�?LAPACK DPOTRF，只访问下三角或上三角（减少一半内存访问）
    TYPE(DenseMatrix), INTENT(INOUT) :: A
    CHARACTER(len=1), INTENT(IN), OPTIONAL :: uplo
    INTEGER(i4), INTENT(OUT) :: info
    
    CHARACTER(len=1) :: ul
    INTEGER(i4) :: n, lda
    
    ! 检查是否为对称方阵
    IF (.NOT. A%IsSquare() .OR. .NOT. A%is_symmetric) THEN
      ERROR STOP "NM_Cholesky_Decompose: Matrix must be symmetric"
    END IF
    
    ul = 'L'  ! 默认使用下三�?
    IF (PRESENT(uplo)) ul = uplo
    
    n = A%nrows
    lda = MAX(1, n)
    
    ! 调用 DPOTRF
    CALL DPOTRF(ul, n, A%data, lda, info)
    
    ! 检查分解是否成�?
    IF (info < 0) THEN
      ERROR STOP "NM_Cholesky_Decompose: Illegal argument to DPOTRF"
    ELSE IF (info > 0) THEN
      ! 矩阵不正定，无法完成 Cholesky 分解
      ERROR STOP "NM_Cholesky_Decompose: Matrix is not positive definite"
    END IF
    
    ! 更新范数缓存（可选）
    ! A%norm_fro = ...
  END SUBROUTINE NM_Cholesky_Decompose
  
  SUBROUTINE NM_Cholesky_Solve(A, uplo, B, X)
    ! 使用 Cholesky 分解结果求解对称正定方程�?AX = B
    ! 伪代码：X = A^(-1)*B
    TYPE(DenseMatrix), INTENT(IN) :: A
    CHARACTER(len=1), INTENT(IN), OPTIONAL :: uplo
    REAL(wp), INTENT(IN) :: B(:,:)
    REAL(wp), ALLOCATABLE, INTENT(OUT) :: X(:,:)
    
    CHARACTER(len=1) :: ul
    INTEGER(i4) :: n, nrhs, lda, ldb, info
    
    ul = 'L'
    IF (PRESENT(uplo)) ul = uplo
    
    n = A%nrows
    nrhs = SIZE(B, 2)
    lda = MAX(1, n)
    ldb = MAX(1, n)
    
    ! 分配解空间并复制右端�?
    ALLOCATE(X(n, nrhs))
    X = B
    
    ! 调用 DPOTRS 回代
    CALL DPOTRS(ul, n, nrhs, A%data, lda, X, ldb, info)
    
    IF (info /= 0) THEN
      ERROR STOP "NM_Cholesky_Solve: DPOTRS failed"
    END IF
  END SUBROUTINE NM_Cholesky_Solve
  
  !===========================================================================
  ! 行列式计�?(基于 LU 分解)
  !===========================================================================
  
  FUNCTION NM_Determinant_LU(A, ipiv) RESULT(det)
    ! det(A) �?det(P) * prod(U_ii)；DGETRF �?U 的对角在 A 上三角�?
    ! 此处�?ipiv(i)/=i 统计的符号为教学用启发式；严格置换奇偶需完整分解 P�?
    TYPE(DenseMatrix), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: ipiv(:)
    REAL(wp) :: det
    INTEGER(i4) :: n, i, sign
    
    IF (.NOT. A%IsSquare()) THEN
      ERROR STOP "NM_Determinant_LU: Matrix must be square"
    END IF
    
    n = A%nrows
    det = 1.0_wp
    sign = 1
    
    DO i = 1, n
      det = det * A%data(i,i)
    END DO
    
    DO i = 1, n
      IF (ipiv(i) /= i) sign = -sign
    END DO
    
    det = REAL(sign, wp) * det
  END FUNCTION NM_Determinant_LU
  
  FUNCTION NM_Determinant_Cholesky(A, uplo) RESULT(det)
    ! 基于 Cholesky 分解：det(A) = det(L)*det(L^T) = prod(L_ii)^2
    TYPE(DenseMatrix), INTENT(IN) :: A
    CHARACTER(len=1), INTENT(IN), OPTIONAL :: uplo
    REAL(wp) :: det
    INTEGER(i4) :: n, i
    CHARACTER(len=1) :: ul
    
    IF (.NOT. A%IsSquare()) THEN
      ERROR STOP "NM_Determinant_Cholesky: Matrix must be square"
    END IF
    
    n = A%nrows
    ul = 'L'
    IF (PRESENT(uplo)) ul = uplo
    
    det = 1.0_wp
    DO i = 1, n
      IF (ul == 'L') THEN
        det = det * A%data(i,i)**2
      ELSE
        det = det * A%data(i,i)**2
      END IF
    END DO
  END FUNCTION NM_Determinant_Cholesky
  
  !===========================================================================
  ! QR 分解 (预留接口)
  !===========================================================================
  
  SUBROUTINE NM_QR_Decompose(A, Q, R, info)
    ! 经济�?QR：A(m×n), m>=n �?Q(m×n) 列正交，R(n×n) 上三角，A �?Q*R�?
    ! 不修改入�?A；依�?LAPACK DGEQRF / DORGQR�?
    TYPE(DenseMatrix), INTENT(IN) :: A
    TYPE(DenseMatrix), INTENT(OUT) :: Q
    TYPE(DenseMatrix), INTENT(OUT) :: R
    INTEGER(i4), INTENT(OUT) :: info
    
    INTEGER(i4) :: m, n, lda, lwork, mn, i, j
    REAL(wp), ALLOCATABLE :: tau(:), work(:), ac(:,:)
    REAL(wp) :: wq(1)
    
    info = 0
    IF (.NOT. A%is_allocated) THEN
      info = -10
      RETURN
    END IF
    
    m = A%nrows
    n = A%ncols
    IF (n <= 0) THEN
      info = -12
      RETURN
    END IF
    IF (m < n) THEN
      info = -11
      RETURN
    END IF
    
    mn = MIN(m, n)
    lda = MAX(1, m)
    ALLOCATE(ac(m, n), tau(mn))
    ac = A%data
    
    CALL DGEQRF(m, n, ac, lda, tau, wq, -1_i4, info)
    IF (info /= 0) RETURN
    lwork = INT(wq(1), i4)
    ALLOCATE(work(MAX(1, lwork)))
    CALL DGEQRF(m, n, ac, lda, tau, work, lwork, info)
    IF (info /= 0) RETURN
    
    CALL NM_Matrix_Allocate(R, n, n)
    R%data = 0.0_wp
    DO j = 1, n
      DO i = 1, MIN(m, j)
        R%data(i, j) = ac(i, j)
      END DO
    END DO
    
    CALL DORGQR(m, n, n, ac, lda, tau, wq, -1_i4, info)
    IF (info /= 0) RETURN
    lwork = INT(wq(1), i4)
    IF (SIZE(work) < lwork) THEN
      DEALLOCATE(work)
      ALLOCATE(work(MAX(1, lwork)))
    END IF
    CALL DORGQR(m, n, n, ac, lda, tau, work, lwork, info)
    IF (info /= 0) RETURN
    
    CALL NM_Matrix_Allocate(Q, m, n)
    Q%data(:, :) = ac(:, 1:n)
    Q%is_symmetric = .FALSE.
    Q%norm_fro = 0.0_wp
    
    DEALLOCATE(ac, tau, work)
  END SUBROUTINE NM_QR_Decompose
  
END MODULE NM_Mtx_Factorization