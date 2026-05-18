!===============================================================================
! MODULE: NM_Mtx_Def
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Def — matrix TYPE definitions (dense + sparse storage)
! BRIEF:  DenseMatrix, SparseMatrix_CSR, SparseMatrix_CSC types with
!         allocate/deallocate/init interfaces. Pure definitions, no solvers.
!
! Status: CORE
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_Mtx_Def
  
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: DenseMatrix, SparseMatrix_CSR, SparseMatrix_CSC
  PUBLIC :: NM_Matrix_Allocate, NM_Matrix_Deallocate
  PUBLIC :: NM_Matrix_Init
  
  !---------------------------------------------------------------------------
  ! Matrix type constants (NM_MTX_* naming)
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: NM_MTX_TYPE_DENSE      = 1_i4
  INTEGER(i4), PARAMETER :: NM_MTX_TYPE_SPARSE_CSR = 2_i4
  INTEGER(i4), PARAMETER :: NM_MTX_TYPE_SPARSE_CSC = 3_i4
  INTEGER(i4), PARAMETER :: NM_MTX_TYPE_SYMMETRIC  = 4_i4
  ! legacy aliases
  INTEGER(i4), PARAMETER :: NM_MATRIX_DENSE      = NM_MTX_TYPE_DENSE
  INTEGER(i4), PARAMETER :: NM_MATRIX_SPARSE_CSR = NM_MTX_TYPE_SPARSE_CSR
  INTEGER(i4), PARAMETER :: NM_MATRIX_SPARSE_CSC = NM_MTX_TYPE_SPARSE_CSC
  INTEGER(i4), PARAMETER :: NM_MATRIX_SYMMETRIC  = NM_MTX_TYPE_SYMMETRIC
  
  !---------------------------------------------------------------------------
  ! Storage order constants (NM_MTX_* naming)
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: NM_MTX_STORAGE_ROW_MAJOR = 1_i4
  INTEGER(i4), PARAMETER :: NM_MTX_STORAGE_COL_MAJOR = 2_i4
  ! legacy aliases
  INTEGER(i4), PARAMETER :: NM_STORAGE_ROW_MAJOR = NM_MTX_STORAGE_ROW_MAJOR
  INTEGER(i4), PARAMETER :: NM_STORAGE_COL_MAJOR = NM_MTX_STORAGE_COL_MAJOR
  
  !===========================================================================
  ! DenseMatrix - 稠密矩阵 TYPE
  !===========================================================================
  TYPE :: DenseMatrix
    REAL(wp), ALLOCATABLE :: data(:,:)    ! 二维数组（列主序�?
    INTEGER(i4) :: nrows = 0_i4           ! 行数
    INTEGER(i4) :: ncols = 0_i4           ! 列数
    LOGICAL :: is_allocated = .FALSE.     ! 是否已分�?
    LOGICAL :: is_symmetric = .FALSE.     ! 是否对称
    REAL(wp) :: norm_fro = 0.0_wp         ! Frobenius 范数（缓存）
  CONTAINS
    PROCEDURE, PASS :: GetShape => DenseMatrix_GetShape
    PROCEDURE, PASS :: GetNorm => DenseMatrix_GetNorm
    PROCEDURE, PASS :: IsSquare => DenseMatrix_IsSquare
    GENERIC :: SHAPE => GetShape
  END TYPE DenseMatrix
  
  !===========================================================================
  ! SparseMatrix_CSR - 稀疏矩�?CSR(Compressed Sparse Row) 格式
  !===========================================================================
  TYPE :: SparseMatrix_CSR
    REAL(wp), ALLOCATABLE :: values(:)      ! 非零元值（按行压缩�?
    INTEGER(i4), ALLOCATABLE :: col_idx(:)  ! 列索引（与非零元一一对应�?
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)  ! 行指针（长度�?nrows+1�?
    INTEGER(i4) :: nrows = 0_i4             ! 行数
    INTEGER(i4) :: ncols = 0_i4             ! 列数
    INTEGER(i8) :: nnz = 0_i8               ! 非零元个�?
    LOGICAL :: is_allocated = .FALSE.       ! 是否已分�?
    LOGICAL :: is_symmetric = .FALSE.       ! 是否对称
    ! 优化提示：CSR 格式适合快速行访问（SpMV �?stride-1 遍历 values�?
  CONTAINS
    PROCEDURE, PASS :: GetNNZ => SparseMatrix_CSR_GetNNZ
    PROCEDURE, PASS :: GetRowRange => SparseMatrix_CSR_GetRowRange
  END TYPE SparseMatrix_CSR
  
  !===========================================================================
  ! SparseMatrix_CSC - 稀疏矩�?CSC(Compressed Sparse Column) 格式
  !===========================================================================
  TYPE :: SparseMatrix_CSC
    REAL(wp), ALLOCATABLE :: values(:)      ! 非零元值（按列压缩�?
    INTEGER(i4), ALLOCATABLE :: row_idx(:)  ! 行索引（与非零元一一对应�?
    INTEGER(i4), ALLOCATABLE :: col_ptr(:)  ! 列指针（长度�?ncols+1�?
    INTEGER(i4) :: nrows = 0_i4             ! 行数
    INTEGER(i4) :: ncols = 0_i4             ! 列数
    INTEGER(i8) :: nnz = 0_i8               ! 非零元个�?
    LOGICAL :: is_allocated = .FALSE.       ! 是否已分�?
    ! 优化提示：CSC 格式适合快速列访问（适合某些迭代法）
  END TYPE SparseMatrix_CSC
  
CONTAINS
  
  !===========================================================================
  ! DenseMatrix 方法实现
  !===========================================================================
  
  FUNCTION DenseMatrix_GetShape(self) RESULT(shape)
    CLASS(DenseMatrix), INTENT(IN) :: self
    INTEGER(i4) :: shape(2)
    
    shape(1) = self%nrows
    shape(2) = self%ncols
  END FUNCTION DenseMatrix_GetShape
  
  FUNCTION DenseMatrix_GetNorm(self, norm_type) RESULT(norm_val)
    CLASS(DenseMatrix), INTENT(IN) :: self
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: norm_type  ! 'F' (Frobenius), '1', 'I'
    REAL(wp) :: norm_val
    INTEGER(i4) :: i, j
    
    ! 默认 Frobenius；INTENT(IN) 下不可写�?norm_fro，故不做“正数缓存”捷径（避免零矩阵误判）
    IF (.NOT. self%is_allocated) THEN
      norm_val = 0.0_wp
      RETURN
    END IF
    
    IF (PRESENT(norm_type)) THEN
      IF (norm_type == 'I' .OR. norm_type == 'i') THEN
        norm_val = 0.0_wp
        DO i = 1, self%nrows
          norm_val = MAX(norm_val, SUM(ABS(self%data(i, 1:self%ncols))))
        END DO
        RETURN
      ELSE IF (norm_type == '1') THEN
        norm_val = 0.0_wp
        DO j = 1, self%ncols
          norm_val = MAX(norm_val, SUM(ABS(self%data(1:self%nrows, j))))
        END DO
        RETURN
      END IF
    END IF
    
    norm_val = 0.0_wp
    DO CONCURRENT (i = 1:self%nrows, j = 1:self%ncols)
      norm_val = norm_val + self%data(i,j)**2
    END DO
    norm_val = SQRT(norm_val)
  END FUNCTION DenseMatrix_GetNorm
  
  FUNCTION DenseMatrix_IsSquare(self) RESULT(is_sq)
    CLASS(DenseMatrix), INTENT(IN) :: self
    LOGICAL :: is_sq
    
    is_sq = (self%nrows == self%ncols)
  END FUNCTION DenseMatrix_IsSquare
  
  !===========================================================================
  ! SparseMatrix_CSR 方法实现
  !===========================================================================
  
  FUNCTION SparseMatrix_CSR_GetNNZ(self) RESULT(nnz_val)
    CLASS(SparseMatrix_CSR), INTENT(IN) :: self
    INTEGER(i8) :: nnz_val
    
    nnz_val = self%nnz
  END FUNCTION SparseMatrix_CSR_GetNNZ
  
  SUBROUTINE SparseMatrix_CSR_GetRowRange(self, row_idx, start_pos, end_pos)
    ! 获取�?row_idx 行的非零元范�?[start_pos, end_pos]（闭区间，与 row_ptr 1-based 约定一致）
    CLASS(SparseMatrix_CSR), INTENT(IN) :: self
    INTEGER(i4), INTENT(IN) :: row_idx
    INTEGER(i4), INTENT(OUT) :: start_pos, end_pos
    
    IF (.NOT. self%is_allocated) THEN
      start_pos = 1
      end_pos = 0
      RETURN
    END IF
    
    IF (row_idx < 1_i4 .OR. row_idx > self%nrows) THEN
      start_pos = 1
      end_pos = 0
      RETURN
    END IF
    
    IF (.NOT. ALLOCATED(self%row_ptr) .OR. SIZE(self%row_ptr) < self%nrows + 1) THEN
      start_pos = 1
      end_pos = 0
      RETURN
    END IF
    
    start_pos = self%row_ptr(row_idx)
    end_pos = self%row_ptr(row_idx + 1) - 1
  END SUBROUTINE SparseMatrix_CSR_GetRowRange
  
  !===========================================================================
  ! 矩阵分配/释放接口
  !===========================================================================
  
  SUBROUTINE NM_Matrix_Allocate(matrix, nrows, ncols, matrix_type, sym)
    ! 通用矩阵分配接口
    CLASS(*), INTENT(INOUT) :: matrix
    INTEGER(i4), INTENT(IN) :: nrows, ncols
    INTEGER(i4), INTENT(IN), OPTIONAL :: matrix_type
    LOGICAL, INTENT(IN), OPTIONAL :: sym
    
    SELECT TYPE(matrix)
    TYPE IS(DenseMatrix)
      matrix%nrows = nrows
      matrix%ncols = ncols
      ALLOCATE(matrix%data(nrows, ncols))
      matrix%data = 0.0_wp
      matrix%is_allocated = .TRUE.
      matrix%is_symmetric = PRESENT(sym) .AND. sym
      matrix%norm_fro = 0.0_wp
      
    TYPE IS(SparseMatrix_CSR)
      matrix%nrows = nrows
      matrix%ncols = ncols
      ! nnz 未知，先不分�?values/col_idx
      ALLOCATE(matrix%row_ptr(nrows + 1))
      matrix%row_ptr = 0
      matrix%nnz = 0_i8
      matrix%is_allocated = .TRUE.
      matrix%is_symmetric = PRESENT(sym) .AND. sym
      
    TYPE IS(SparseMatrix_CSC)
      matrix%nrows = nrows
      matrix%ncols = ncols
      ALLOCATE(matrix%col_ptr(ncols + 1))
      matrix%col_ptr = 0
      matrix%nnz = 0_i8
      matrix%is_allocated = .TRUE.
      
    CLASS DEFAULT
      ERROR STOP "NM_Matrix_Allocate: Unsupported matrix type"
    END SELECT
  END SUBROUTINE NM_Matrix_Allocate
  
  SUBROUTINE NM_Matrix_Deallocate(matrix)
    ! 通用矩阵释放接口
    CLASS(*), INTENT(INOUT) :: matrix
    
    SELECT TYPE(matrix)
    TYPE IS(DenseMatrix)
      IF (ALLOCATED(matrix%data)) DEALLOCATE(matrix%data)
      matrix%nrows = 0
      matrix%ncols = 0
      matrix%is_allocated = .FALSE.
      matrix%norm_fro = 0.0_wp
      
    TYPE IS(SparseMatrix_CSR)
      IF (ALLOCATED(matrix%values)) DEALLOCATE(matrix%values)
      IF (ALLOCATED(matrix%col_idx)) DEALLOCATE(matrix%col_idx)
      IF (ALLOCATED(matrix%row_ptr)) DEALLOCATE(matrix%row_ptr)
      matrix%nrows = 0
      matrix%ncols = 0
      matrix%nnz = 0_i8
      matrix%is_allocated = .FALSE.
      
    TYPE IS(SparseMatrix_CSC)
      IF (ALLOCATED(matrix%values)) DEALLOCATE(matrix%values)
      IF (ALLOCATED(matrix%row_idx)) DEALLOCATE(matrix%row_idx)
      IF (ALLOCATED(matrix%col_ptr)) DEALLOCATE(matrix%col_ptr)
      matrix%nrows = 0
      matrix%ncols = 0
      matrix%nnz = 0_i8
      matrix%is_allocated = .FALSE.
      
    CLASS DEFAULT
      ERROR STOP "NM_Matrix_Deallocate: Unsupported matrix type"
    END SELECT
  END SUBROUTINE NM_Matrix_Deallocate
  
  SUBROUTINE NM_Matrix_Init(matrix, value)
    ! 矩阵初始化（设为常数值）
    CLASS(*), INTENT(INOUT) :: matrix
    REAL(wp), INTENT(IN), OPTIONAL :: value
    
    REAL(wp) :: init_val
    INTEGER(i4) :: i, j
    INTEGER(i8) :: k
    
    init_val = 0.0_wp
    IF (PRESENT(value)) init_val = value
    
    SELECT TYPE(matrix)
    TYPE IS(DenseMatrix)
      IF (matrix%is_allocated) THEN
        matrix%data = init_val
        IF (init_val /= 0.0_wp) THEN
          ! 重新计算范数
          matrix%norm_fro = ABS(init_val) * SQRT(REAL(matrix%nrows * matrix%ncols, wp))
        ELSE
          matrix%norm_fro = 0.0_wp
        END IF
      END IF
      
    TYPE IS(SparseMatrix_CSR)
      IF (ALLOCATED(matrix%values)) THEN
        matrix%values = init_val
      END IF
      
    TYPE IS(SparseMatrix_CSC)
      IF (ALLOCATED(matrix%values)) THEN
        matrix%values = init_val
      END IF
      
    CLASS DEFAULT
      ERROR STOP "NM_Matrix_Init: Unsupported matrix type"
    END SELECT
  END SUBROUTINE NM_Matrix_Init
  
END MODULE NM_Mtx_Def
