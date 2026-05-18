!===============================================================================
! MODULE: NM_Mtx_MatMul
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Proc — Dense DGEMM wrapper + sparse SpMV (CSR)
! BRIEF:  Matrix multiplication for dense and sparse formats
!===============================================================================
MODULE NM_Mtx_MatMul
  
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Mtx_Def
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: NM_MatMul_Dense, NM_MatMul_Sparse_CSR
  PUBLIC :: NM_SpMV_CSR, NM_SpMV_Transpose_CSR
  PUBLIC :: NM_MatMul_Add

  INTERFACE
    SUBROUTINE DGEMM(TRANSA, TRANSB, M, N, K, ALPHA, A, LDA, B, LDB, BETA, C, LDC) &
        BIND(C, NAME='dgemm')
      IMPORT :: wp, i4
      CHARACTER(len=1), VALUE :: TRANSA, TRANSB
      INTEGER(i4), VALUE :: M, N, K, LDA, LDB, LDC
      REAL(wp), VALUE :: ALPHA, BETA
      REAL(wp), INTENT(IN) :: A(LDA, *), B(LDB, *)
      REAL(wp), INTENT(INOUT) :: C(LDC, *)
    END SUBROUTINE DGEMM
  END INTERFACE
  
CONTAINS
  
  !===========================================================================
  ! 稠密矩阵乘法 - DGEMM 封装
  !===========================================================================
  
  SUBROUTINE NM_MatMul_Dense(A, B, C, transa, transb, alpha, beta)
    ! 伪代码：C = alpha*op(A)*op(B) + beta*C
    ! 优化：调�?LAPACK DGEMM，利�?BLAS Level 3 高性能
    TYPE(DenseMatrix), INTENT(IN) :: A, B
    TYPE(DenseMatrix), INTENT(INOUT) :: C
    CHARACTER(len=1), INTENT(IN), OPTIONAL :: transa, transb
    REAL(wp), INTENT(IN), OPTIONAL :: alpha, beta
    
    CHARACTER(len=1) :: ta, tb
    REAL(wp) :: a, b
    INTEGER(i4) :: m, n, k, lda, ldb, ldc, kb
    
    ! 默认参数
    ta = 'N'
    tb = 'N'
    a = 1.0_wp
    b = 0.0_wp
    
    IF (PRESENT(transa)) ta = transa
    IF (PRESENT(transb)) tb = transb
    IF (PRESENT(alpha)) a = alpha
    IF (PRESENT(beta)) b = beta
    
    ! 维度检�?    IF (ta == 'N') THEN
      m = A%nrows
      k = A%ncols
      lda = MAX(1, A%nrows)
    ELSE
      m = A%ncols
      k = A%nrows
      lda = MAX(1, A%ncols)
    END IF
    
    IF (tb == 'N') THEN
      n = B%ncols
      ldb = MAX(1, B%nrows)
    ELSE
      n = B%nrows
      ldb = MAX(1, B%ncols)
    END IF
    
    ldc = MAX(1, C%nrows)
    
    IF (tb == 'N') THEN
      kb = B%nrows
    ELSE
      kb = B%ncols
    END IF
    
    IF (.NOT. A%is_allocated .OR. .NOT. B%is_allocated .OR. .NOT. C%is_allocated) THEN
      ERROR STOP "NM_MatMul_Dense: Matrix not allocated"
    END IF
    IF (k /= kb) THEN
      ERROR STOP "NM_MatMul_Dense: Inner dimension mismatch for op(A)*op(B)"
    END IF
    IF (C%nrows /= m .OR. C%ncols /= n) THEN
      ERROR STOP "NM_MatMul_Dense: C shape must match op(A)*op(B)"
    END IF
    
    ! 调用 DGEMM (BLAS)
    ! 接口：DGEMM(TRANSA, TRANSB, M, N, K, ALPHA, A, LDA, B, LDB, BETA, C, LDC)
    CALL DGEMM(ta, tb, m, n, k, a, A%data, lda, B%data, ldb, b, C%data, ldc)
    
    ! 更新 C 的范数缓�?    C%norm_fro = 0.0_wp  ! 强制重新计算
  END SUBROUTINE NM_MatMul_Dense
  
  !===========================================================================
  ! 矩阵乘法加法融合：C = A*B + D
  !===========================================================================
  
  SUBROUTINE NM_MatMul_Add(A, B, D, C, alpha)
    ! C = alpha*A*B + D，经 DGEMM（beta=1 累加到已拷贝�?D�?    TYPE(DenseMatrix), INTENT(IN) :: A, B, D
    TYPE(DenseMatrix), INTENT(OUT) :: C
    REAL(wp), INTENT(IN), OPTIONAL :: alpha
    
    REAL(wp) :: a
    
    a = 1.0_wp
    IF (PRESENT(alpha)) a = alpha
    
    IF (.NOT. A%is_allocated .OR. .NOT. B%is_allocated .OR. .NOT. D%is_allocated) THEN
      ERROR STOP "NM_MatMul_Add: Matrix not allocated"
    END IF
    IF (A%ncols /= B%nrows .OR. A%nrows /= D%nrows .OR. B%ncols /= D%ncols) THEN
      ERROR STOP "NM_MatMul_Add: Dimension mismatch"
    END IF
    
    CALL NM_Matrix_Allocate(C, A%nrows, B%ncols)
    C%data = D%data
    C%is_symmetric = .FALSE.
    C%norm_fro = 0.0_wp
    CALL NM_MatMul_Dense(A, B, C, alpha=a, beta=1.0_wp)
  END SUBROUTINE NM_MatMul_Add
  
  !===========================================================================
  ! 稀疏矩阵乘�?- CSR 格式
  !===========================================================================
  
  SUBROUTINE NM_MatMul_Sparse_CSR(A, B, C, alpha, beta)
    ! 稀疏矩阵乘法：C = alpha*A*B + beta*C
    ! A: CSR 格式，B: DenseMatrix, C: DenseMatrix
    TYPE(SparseMatrix_CSR), INTENT(IN) :: A
    TYPE(DenseMatrix), INTENT(IN) :: B
    TYPE(DenseMatrix), INTENT(INOUT) :: C
    REAL(wp), INTENT(IN), OPTIONAL :: alpha, beta
    
    REAL(wp) :: a, b
    INTEGER(i4) :: i, j, jj, row_start, row_end
    INTEGER(i4) :: col_idx
    REAL(wp) :: val
    
    a = 1.0_wp
    b = 0.0_wp
    IF (PRESENT(alpha)) a = alpha
    IF (PRESENT(beta)) b = beta
    
    ! 维度检�?    IF (A%nrows /= C%nrows .OR. A%ncols /= B%nrows .OR. B%ncols /= C%ncols) THEN
      ERROR STOP "NM_MatMul_Sparse_CSR: Dimension mismatch"
    END IF
    
    ! beta*C �?    IF (b /= 0.0_wp) THEN
      C%data = b * C%data
    ELSE
      C%data = 0.0_wp
    END IF
    
    ! SpMV 累加：C = C + alpha*A*B
    ! 优化：CSR 格式 stride-1 访问 values 数组
    DO i = 1, A%nrows
      row_start = A%row_ptr(i)
      row_end = A%row_ptr(i+1) - 1
      
      DO j = 1, C%ncols
        ! �?i 行第 j 列：sum_k(A_ik * B_kj)
        DO jj = row_start, row_end
          col_idx = A%col_idx(jj)
          val = A%values(jj)
          C%data(i,j) = C%data(i,j) + a * val * B%data(col_idx,j)
        END DO
      END DO
    END DO
  END SUBROUTINE NM_MatMul_Sparse_CSR
  
  !===========================================================================
  ! 稀疏矩�?- 向量乘法 (SpMV) - CSR 格式
  !===========================================================================
  
  SUBROUTINE NM_SpMV_CSR(A, x, y, alpha, beta)
    ! 伪代码：y = alpha*A*x + beta*y
    ! 优化�?    ! 1. CSR 格式 stride-1 遍历 values 数组（提�?cache 命中率）
    ! 2. DO CONCURRENT 并行化（编译器自动向量化�?    ! 3. 避免 gather/scatter 操作
    TYPE(SparseMatrix_CSR), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(INOUT) :: y(:)
    REAL(wp), INTENT(IN), OPTIONAL :: alpha, beta
    
    REAL(wp) :: a, b
    INTEGER(i4) :: i, jj, row_start, row_end
    INTEGER(i8) :: k
    
    a = 1.0_wp
    b = 0.0_wp
    IF (PRESENT(alpha)) a = alpha
    IF (PRESENT(beta)) b = beta
    
    ! 维度检�?    IF (SIZE(x) /= A%ncols .OR. SIZE(y) /= A%nrows) THEN
      ERROR STOP "NM_SpMV_CSR: Dimension mismatch"
    END IF
    
    ! beta*y �?    IF (b /= 0.0_wp) THEN
      y = b * y
    ELSE
      y = 0.0_wp
    END IF
    
    ! SpMV 核心：y = y + alpha*A*x
    ! 方法 1：按行计算（适合 DO CONCURRENT�?    DO i = 1, A%nrows
      row_start = A%row_ptr(i)
      row_end = A%row_ptr(i+1) - 1
      
      ! 计算�?i 行的点积
      IF (row_start <= row_end) THEN
        y(i) = y(i) + a * DOT_PRODUCT(A%values(row_start:row_end), &
                                      x(A%col_idx(row_start:row_end)))
      END IF
    END DO
    
    ! 方法 2：DO CONCURRENT 并行化（推荐编译器支持时�?    ! DO CONCURRENT (i = 1:A%nrows)
    !   row_start = A%row_ptr(i)
    !   row_end = A%row_ptr(i+1) - 1
    !   IF (row_start <= row_end) THEN
    !     y(i) = y(i) + a * DOT_PRODUCT(A%values(row_start:row_end), &
    !                                   x(A%col_idx(row_start:row_end)))
    !   END IF
    ! END DO
  END SUBROUTINE NM_SpMV_CSR
  
  SUBROUTINE NM_SpMV_Transpose_CSR(A, x, y, alpha, beta)
    ! 转置 SpMV: y = alpha*A^T*x + beta*y
    ! CSR 格式的转置需要按列访问（不适合 CSR，应转换�?CSC�?    TYPE(SparseMatrix_CSR), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(INOUT) :: y(:)
    REAL(wp), INTENT(IN), OPTIONAL :: alpha, beta
    
    REAL(wp) :: a, b
    INTEGER(i4) :: i, jj, row_start, row_end
    INTEGER(i4) :: col_idx
    REAL(wp) :: xi
    
    a = 1.0_wp
    b = 0.0_wp
    IF (PRESENT(alpha)) a = alpha
    IF (PRESENT(beta)) b = beta
    
    ! 维度检�?    IF (SIZE(x) /= A%nrows .OR. SIZE(y) /= A%ncols) THEN
      ERROR STOP "NM_SpMV_Transpose_CSR: Dimension mismatch"
    END IF
    
    ! beta*y �?    IF (b /= 0.0_wp) THEN
      y = b * y
    ELSE
      y = 0.0_wp
    END IF
    
    ! 转置 SpMV: y_j = sum_i(A_ij * x_i)
    ! CSR 格式：遍历每一行，将贡献累加到对应的列
    DO i = 1, A%nrows
      row_start = A%row_ptr(i)
      row_end = A%row_ptr(i+1) - 1
      xi = x(i)
      
      DO jj = row_start, row_end
        col_idx = A%col_idx(jj)
        y(col_idx) = y(col_idx) + a * A%values(jj) * xi
      END DO
    END DO
  END SUBROUTINE NM_SpMV_Transpose_CSR
  
END MODULE NM_Mtx_MatMul