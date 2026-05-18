!===============================================================================
! MODULE: NM_Mtx_Inversion
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Proc — Matrix inversion via LU/Cholesky/Gauss-Jordan
! BRIEF:  Dense matrix inversion routines
!===============================================================================
MODULE NM_Mtx_Inversion
  
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Mtx_Def
  USE NM_Mtx_Factorization
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: NM_Invert_LU, NM_Invert_Cholesky
  PUBLIC :: NM_Invert_GaussJordan
  
CONTAINS
  
  !===========================================================================
  ! 矩阵求�?- LU 方法
  !===========================================================================
  
  SUBROUTINE NM_Invert_LU(A, Ainv, info)
    ! 伪代码：求解 A*Ainv = I
    ! 优化：对单位矩阵的每一列调�?LU 回代（避免显式构造逆矩阵公式）
    TYPE(DenseMatrix), INTENT(INOUT) :: A
    TYPE(DenseMatrix), INTENT(OUT) :: Ainv
    INTEGER(i4), INTENT(OUT) :: info
    
    INTEGER(i4), ALLOCATABLE :: ipiv(:)
    REAL(wp), ALLOCATABLE :: rhs(:,:), inv(:,:)
    INTEGER(i4) :: n, i
    
    ! 检查是否为方阵
    IF (.NOT. A%IsSquare()) THEN
      ERROR STOP "NM_Invert_LU: Matrix must be square"
    END IF
    
    n = A%nrows
    
    ! 1. LU 分解
    CALL NM_LU_Decompose(A, ipiv, info)
    
    IF (info /= 0) THEN
      ! 分解失败（奇异矩阵）
      RETURN
    END IF
    
    ! 2. 构造右端项（单位矩阵）
    ALLOCATE(rhs(n, n))
    rhs = 0.0_wp
    DO i = 1, n
      rhs(i,i) = 1.0_wp
    END DO
    
    ! 3. 对每一列求�?AX = e_i
    CALL NM_LU_Solve(A, ipiv, rhs, inv)
    
    ! 4. 复制结果�?Ainv
    IF (ALLOCATED(Ainv%data)) DEALLOCATE(Ainv%data)
    CALL NM_Matrix_Allocate(Ainv, n, n)
    Ainv%data = inv
    Ainv%is_symmetric = .FALSE.
    
    ! 清理
    DEALLOCATE(ipiv, rhs, inv)
  END SUBROUTINE NM_Invert_LU
  
  !===========================================================================
  ! 矩阵求�?- Cholesky 方法（对称正定矩阵）
  !===========================================================================
  
  SUBROUTINE NM_Invert_Cholesky(A, Ainv, uplo, info)
    ! 伪代码：对对称正定矩阵，使用 Cholesky 分解求�?
    ! 优化：只访问一半矩阵元素，减少计算�?
    TYPE(DenseMatrix), INTENT(INOUT) :: A
    TYPE(DenseMatrix), INTENT(OUT) :: Ainv
    CHARACTER(len=1), INTENT(IN), OPTIONAL :: uplo
    INTEGER(i4), INTENT(OUT) :: info
    
    CHARACTER(len=1) :: ul
    INTEGER(i4) :: n, i
    REAL(wp), ALLOCATABLE :: rhs(:,:), inv(:,:)
    
    ! 检查是否为对称方阵
    IF (.NOT. A%IsSquare() .OR. .NOT. A%is_symmetric) THEN
      ERROR STOP "NM_Invert_Cholesky: Matrix must be symmetric"
    END IF
    
    ul = 'L'
    IF (PRESENT(uplo)) ul = uplo
    
    n = A%nrows
    
    ! 1. Cholesky 分解
    CALL NM_Cholesky_Decompose(A, ul, info)
    
    IF (info /= 0) THEN
      ! 分解失败（不正定�?
      RETURN
    END IF
    
    ! 2. 构造右端项（单位矩阵）
    ALLOCATE(rhs(n, n))
    rhs = 0.0_wp
    DO i = 1, n
      rhs(i,i) = 1.0_wp
    END DO
    
    ! 3. 对每一列求�?AX = e_i
    CALL NM_Cholesky_Solve(A, ul, rhs, inv)
    
    ! 4. 复制结果�?Ainv
    IF (ALLOCATED(Ainv%data)) DEALLOCATE(Ainv%data)
    CALL NM_Matrix_Allocate(Ainv, n, n)
    Ainv%data = inv
    Ainv%is_symmetric = .TRUE.
    Ainv%norm_fro = 0.0_wp  ! 强制重新计算
    
    ! 清理
    DEALLOCATE(rhs, inv)
  END SUBROUTINE NM_Invert_Cholesky
  
  !===========================================================================
  ! 矩阵求�?- Gauss-Jordan 消元法（教学用途）
  !===========================================================================
  
  SUBROUTINE NM_Invert_GaussJordan(A, Ainv, info)
    ! 伪代码：[A|I] -> [I|A^(-1)] (Gauss-Jordan 消元)
    ! 注意：数值稳定性不�?LU 方法，不推荐用于大规模问�?
    TYPE(DenseMatrix), INTENT(INOUT) :: A
    TYPE(DenseMatrix), INTENT(OUT) :: Ainv
    INTEGER(i4), INTENT(OUT) :: info
    
    REAL(wp), ALLOCATABLE :: aug(:,:)
    REAL(wp), ALLOCATABLE :: tmp_row(:)
    INTEGER(i4) :: n, i, j, k, i_swap
    REAL(wp) :: pivot, factor
    
    ! 检查是否为方阵
    IF (.NOT. A%IsSquare()) THEN
      ERROR STOP "NM_Invert_GaussJordan: Matrix must be square"
    END IF
    
    n = A%nrows
    info = 0
    
    ! 1. 构造增广矩�?[A|I]
    ALLOCATE(aug(n, 2*n), tmp_row(2*n))
    aug(:, 1:n) = A%data
    aug(:, n+1:2*n) = 0.0_wp
    DO i = 1, n
      aug(i, n+i) = 1.0_wp
    END DO
    
    ! 2. Gauss-Jordan 消元
    DO k = 1, n
      ! 选主�?
      pivot = ABS(aug(k,k))
      i_swap = k
      DO i = k+1, n
        IF (ABS(aug(i,k)) > pivot) THEN
          pivot = ABS(aug(i,k))
          i_swap = i
        END IF
      END DO
      IF (i_swap /= k) THEN
        tmp_row(:) = aug(k, :)
        aug(k, :) = aug(i_swap, :)
        aug(i_swap, :) = tmp_row(:)
      END IF
      
      ! 检查是否奇�?
      IF (ABS(aug(k,k)) < 1.0E-12_wp) THEN
        info = k  ! �?k 个主元为 0
        DEALLOCATE(aug, tmp_row)
        RETURN
      END IF
      
      ! 归一化第 k �?
      factor = aug(k,k)
      aug(k, :) = aug(k, :) / factor
      
      ! 消去其他行的�?k �?
      DO i = 1, n
        IF (i /= k) THEN
          factor = aug(i,k)
          aug(i, :) = aug(i, :) - factor * aug(k, :)
        END IF
      END DO
    END DO
    
    ! 3. 提取逆矩阵（右半部分�?
    IF (ALLOCATED(Ainv%data)) DEALLOCATE(Ainv%data)
    CALL NM_Matrix_Allocate(Ainv, n, n)
    Ainv%data = aug(:, n+1:2*n)
    Ainv%is_symmetric = .FALSE.
    
    DEALLOCATE(aug, tmp_row)
  END SUBROUTINE NM_Invert_GaussJordan
  
END MODULE NM_Mtx_Inversion