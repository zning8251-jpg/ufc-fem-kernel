!===============================================================================
! MODULE: NM_Mtx_Core
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Core — CSR matrix types, assembly, MatVec, get/set operations
! BRIEF:  NM_Matrix_Index + NM_Matrix_Values and CSR core operations
!===============================================================================

MODULE NM_Mtx_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_Mtx_Vec, ONLY: NM_Vec_Dot, NM_Vec_Nrm2, NM_Vec_Axpy, NM_Vec_Scal, &
                         NM_Vec_Copy, NM_Vec_Fill, NM_Vec_Add, NM_Vec_Sub
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! Format Constants (merged from NM_Mtx_Def)
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: NM_MAT_FMT_CSR   = 1_i4
  INTEGER(i4), PARAMETER :: NM_MAT_FMT_COO   = 2_i4
  INTEGER(i4), PARAMETER :: NM_MAT_FMT_DENSE = 3_i4

  !---------------------------------------------------------------------------
  ! NM_Matrix_Index -
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Matrix_Index
    INTEGER(i4) :: n_rows = 0_i4
    INTEGER(i4) :: n_cols = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)   ! CSR: (n_rows+1), 1-based
    INTEGER(i4), ALLOCATABLE :: col_ind(:)   ! CSR: (nnz)
    INTEGER(i4) :: format = NM_MAT_FMT_CSR
    LOGICAL     :: is_symmetric = .FALSE.
    LOGICAL     :: finalized = .FALSE.
  END TYPE NM_Matrix_Index

  !---------------------------------------------------------------------------
  ! NM_Matrix_Values - index_id Index ? !---------------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Matrix_Values
    INTEGER(i4) :: index_id = 0_i4
    REAL(wp), ALLOCATABLE :: values(:)  ! (nnz)
  END TYPE NM_Matrix_Values

  !---------------------------------------------------------------------------
  ! NM_Matrix - Index + Values ? !---------------------------------------------------------------------------
  TYPE, PUBLIC :: NM_Matrix
    TYPE(NM_Matrix_Index)   :: index
    TYPE(NM_Matrix_Values)  :: data
  END TYPE NM_Matrix

  !---------------------------------------------------------------------------
  ! Public Interface (NM_Matrix)
  !---------------------------------------------------------------------------
  PUBLIC :: NM_MAT_FMT_CSR, NM_MAT_FMT_COO, NM_MAT_FMT_DENSE
  PUBLIC :: NM_Matrix_Init
  PUBLIC :: NM_Matrix_AddEntry
  PUBLIC :: NM_Matrix_Finalize
  PUBLIC :: NM_Matrix_Destroy
  PUBLIC :: NM_Matrix_MatVec
  PUBLIC :: NM_Matrix_GetValue
  PUBLIC :: NM_Matrix_SetValue
  PUBLIC :: NM_Matrix_IsValid

  !---------------------------------------------------------------------------
  ! UF_CSRMatrix / UF_COOEntry (merged from UF_SparseMatrix, backward compat)
  !---------------------------------------------------------------------------
  REAL(wp), PARAMETER :: CSR_ZERO = 0.0_wp
  REAL(wp), PARAMETER :: CSR_ONE = 1.0_wp
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CSR_SUCCESS = 0
  INTEGER(i4), PARAMETER, PUBLIC :: CSR_ERR_ALLOC = -1
  INTEGER(i4), PARAMETER, PUBLIC :: CSR_ERR_INDEX = -2
  INTEGER(i4), PARAMETER, PUBLIC :: CSR_ERR_NOT_FOUND = -3
  INTEGER(i4), PARAMETER, PUBLIC :: CSR_ERR_SIZE = -4

  TYPE, PUBLIC :: UF_COOEntry
    INTEGER(i4) :: row = 0
    INTEGER(i4) :: col = 0
    REAL(wp)    :: val = CSR_ZERO
  END TYPE UF_COOEntry

  TYPE, PUBLIC :: UF_CSRMatrix
    INTEGER(i4) :: nrows = 0
    INTEGER(i4) :: ncols = 0
    INTEGER(i4) :: nnz = 0
    REAL(wp), ALLOCATABLE :: val(:)
    INTEGER(i4), ALLOCATABLE :: col_ind(:)
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)
    LOGICAL :: is_symmetric = .FALSE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE :: init => csr_init
    PROCEDURE :: destroy => csr_destroy_method
    PROCEDURE :: get => csr_get_value_method
    PROCEDURE :: set => csr_set_value_method
    PROCEDURE :: add => csr_add_value_method
    PROCEDURE :: matvec => csr_matvec
    PROCEDURE :: matvec_trans => csr_matvec_trans
    PROCEDURE :: get_row_nnz => csr_get_row_nnz
    PROCEDURE :: print_info => csr_info_method
  END TYPE UF_CSRMatrix

  !---------------------------------------------------------------------------
  ! UF_CSR_Assembly_Map (merged from UF_CSR_Optimizer)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: UF_CSR_Assembly_Map
    INTEGER(i4) :: num_elements = 0
    INTEGER(i4) :: max_dof_per_elem = 0
    INTEGER(i4), ALLOCATABLE :: pos(:,:,:)
    INTEGER(i4), ALLOCATABLE :: pos_flat(:)
    INTEGER(i4), ALLOCATABLE :: elem_offset(:)
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: init => assembly_map_init
    PROCEDURE :: destroy => assembly_map_destroy
  END TYPE UF_CSR_Assembly_Map

  !---------------------------------------------------------------------------
  ! Public procedures (merged from UF_SparseMatrix, UF_CSR_Optimizer)
  !---------------------------------------------------------------------------
  PUBLIC :: csr_create, csr_destroy, csr_init_from_coo
  PUBLIC :: csr_get_value, csr_set_value, csr_add_value
  PUBLIC :: csr_clear, csr_scale, csr_copy
  PUBLIC :: csr_get_diagonal, csr_set_diagonal
  PUBLIC :: csr_add_scaled, csr_axpy
  PUBLIC :: csr_info, csr_print
  PUBLIC :: csr_zero_matrix, csr_deallocate
  PUBLIC :: sparse_matvec, sparse_matvec_trans, csr_matvec_direct
  PUBLIC :: sparse_lsolve, sparse_usolve, sparse_lsolve_msr, sparse_usolve_msr
  PUBLIC :: vec_dot, vec_axpy, vec_norm2, vec_scale, vec_copy
  PUBLIC :: vec_zero, vec_add, vec_sub
  PUBLIC :: csr_build_assembly_map, csr_fast_assemble_element, csr_batch_assemble
  PUBLIC :: csr_get_position, csr_analyze_bandwidth, csr_reorder_rcm

  !---------------------------------------------------------------------------
  ! NM_Mtx_* (merged from NM_Mtx_Core - dense BLAS/utilities)
  !---------------------------------------------------------------------------
  PUBLIC :: NM_Mtx_Gemv, NM_Mtx_Ger, NM_Mtx_Trmv, NM_Mtx_Symv
  PUBLIC :: NM_Mtx_Gemm, NM_Mtx_Trmm, NM_Mtx_Symm
  PUBLIC :: NM_Mtx_Add, NM_Mtx_Subtract, NM_Mtx_Transpose
  PUBLIC :: NM_Mtx_Trace, NM_Mtx_Det, NM_Mtx_Inv
  PUBLIC :: NM_Mtx_NormF, NM_Mtx_Norm1, NM_Mtx_NormInf
  PUBLIC :: NM_Mtx_Eye, NM_Mtx_Diag

CONTAINS

  !---------------------------------------------------------------------------
  ! NM_Matrix_Init -
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Matrix_Init(A, n_rows, n_cols, max_nnz, status)
    TYPE(NM_Matrix), INTENT(OUT) :: A
    INTEGER(i4), INTENT(IN) :: n_rows, n_cols, max_nnz
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (n_rows < 0 .OR. n_cols < 0 .OR. max_nnz < 0) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    A%index%n_rows = n_rows
    A%index%n_cols = n_cols
    A%index%nnz = 0_i4
    A%index%format = NM_MAT_FMT_CSR
    A%index%finalized = .FALSE.

    IF (n_rows > 0 .AND. max_nnz > 0) THEN
      ALLOCATE(A%index%row_ptr(n_rows + 1))
      ALLOCATE(A%index%col_ind(max_nnz))
      ALLOCATE(A%data%values(max_nnz))
      A%index%row_ptr = 0_i4
      A%index%col_ind = 0_i4
      A%data%values = 0.0_wp
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Matrix_Init

  !---------------------------------------------------------------------------
  ! NM_Matrix_AddEntry - (row, col, value)
  !   row, col ?1-based
  ! CSR AddEntry row
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Matrix_AddEntry(A, row, col, value, status)
    TYPE(NM_Matrix), INTENT(INOUT) :: A
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: value
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: max_nnz

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (A%index%finalized) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (row < 1 .OR. row > A%index%n_rows .OR. col < 1 .OR. col > A%index%n_cols) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    max_nnz = SIZE(A%index%col_ind)
    A%index%nnz = A%index%nnz + 1_i4

    IF (A%index%nnz <= max_nnz) THEN
      A%index%col_ind(A%index%nnz) = col
      A%data%values(A%index%nnz) = value
      A%index%row_ptr(row + 1) = A%index%row_ptr(row + 1) + 1_i4
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Matrix_AddEntry

  !---------------------------------------------------------------------------
  ! NM_Matrix_Finalize - row_ptr 1-based CSR ? !---------------------------------------------------------------------------
  SUBROUTINE NM_Matrix_Finalize(A, status)
    TYPE(NM_Matrix), INTENT(INOUT) :: A
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, cumsum, temp

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (A%index%finalized) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (.NOT. ALLOCATED(A%index%row_ptr)) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ! row_ptr(i+1) ?row i 1-based
    cumsum = 1_i4
    DO i = 1, A%index%n_rows + 1
      temp = A%index%row_ptr(i)
      A%index%row_ptr(i) = cumsum
      cumsum = cumsum + temp
    END DO

    A%index%finalized = .TRUE.
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Matrix_Finalize

  !---------------------------------------------------------------------------
  ! NM_Matrix_Destroy -
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Matrix_Destroy(A)
    TYPE(NM_Matrix), INTENT(INOUT) :: A

    IF (ALLOCATED(A%index%row_ptr)) DEALLOCATE(A%index%row_ptr)
    IF (ALLOCATED(A%index%col_ind)) DEALLOCATE(A%index%col_ind)
    IF (ALLOCATED(A%data%values)) DEALLOCATE(A%data%values)
    A%index%n_rows = 0_i4
    A%index%n_cols = 0_i4
    A%index%nnz = 0_i4
    A%index%finalized = .FALSE.
  END SUBROUTINE NM_Matrix_Destroy

  !---------------------------------------------------------------------------
  ! NM_Matrix_MatVec - y = A·x
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Matrix_MatVec(A, x, y, status)
    TYPE(NM_Matrix), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, p, j

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. A%index%finalized) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (SIZE(x) < A%index%n_cols .OR. SIZE(y) < A%index%n_rows) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO i = 1, A%index%n_rows
      y(i) = 0.0_wp
      DO p = A%index%row_ptr(i), A%index%row_ptr(i + 1) - 1
        j = A%index%col_ind(p)
        y(i) = y(i) + A%data%values(p) * x(j)
      END DO
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Matrix_MatVec

  !---------------------------------------------------------------------------
  ! NM_Matrix_GetValue - (row,col) finalized
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Matrix_GetValue(A, row, col, value, found, status)
    TYPE(NM_Matrix), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(OUT) :: value
    LOGICAL, INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: p

    IF (PRESENT(status)) CALL init_error_status(status)
    value = 0.0_wp
    found = .FALSE.

    IF (.NOT. A%index%finalized) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (row < 1 .OR. row > A%index%n_rows .OR. col < 1 .OR. col > A%index%n_cols) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO p = A%index%row_ptr(row), A%index%row_ptr(row + 1) - 1
      IF (A%index%col_ind(p) == col) THEN
        value = A%data%values(p)
        found = .TRUE.
        EXIT
      END IF
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Matrix_GetValue

  !---------------------------------------------------------------------------
  ! NM_Matrix_SetValue - (row,col)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Matrix_SetValue(A, row, col, value, status)
    TYPE(NM_Matrix), INTENT(INOUT) :: A
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: value
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: p

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. A%index%finalized) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (row < 1 .OR. row > A%index%n_rows .OR. col < 1 .OR. col > A%index%n_cols) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO p = A%index%row_ptr(row), A%index%row_ptr(row + 1) - 1
      IF (A%index%col_ind(p) == col) THEN
        A%data%values(p) = value
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    ! ? IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
  END SUBROUTINE NM_Matrix_SetValue

  !---------------------------------------------------------------------------
  ! NM_Matrix_IsValid - ? !---------------------------------------------------------------------------
  LOGICAL FUNCTION NM_Matrix_IsValid(A)
    TYPE(NM_Matrix), INTENT(IN) :: A

    NM_Matrix_IsValid = A%index%finalized .AND. A%index%nnz > 0_i4 &
        .AND. ALLOCATED(A%index%row_ptr) .AND. ALLOCATED(A%index%col_ind) &
        .AND. ALLOCATED(A%data%values) &
        .AND. SIZE(A%data%values) >= A%index%nnz
  END FUNCTION NM_Matrix_IsValid

  !===========================================================================
  ! NM_Mtx_* (merged from NM_Mtx_Core)
  !===========================================================================
  SUBROUTINE NM_Mtx_Add(A, B, C, status)
    REAL(wp), INTENT(IN) :: A(:,:), B(:,:)
    REAL(wp), INTENT(OUT) :: C(:,:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: m, n
    IF (PRESENT(status)) CALL init_error_status(status)
    m = SIZE(A, 1)
    n = SIZE(A, 2)
    IF (SIZE(B, 1) /= m .OR. SIZE(B, 2) /= n .OR. &
        SIZE(C, 1) /= m .OR. SIZE(C, 2) /= n) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    C = A + B
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Add

  SUBROUTINE NM_Mtx_Subtract(A, B, C, status)
    REAL(wp), INTENT(IN) :: A(:,:), B(:,:)
    REAL(wp), INTENT(OUT) :: C(:,:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: m, n
    IF (PRESENT(status)) CALL init_error_status(status)
    m = SIZE(A, 1)
    n = SIZE(A, 2)
    IF (SIZE(B, 1) /= m .OR. SIZE(B, 2) /= n .OR. &
        SIZE(C, 1) /= m .OR. SIZE(C, 2) /= n) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    C = A - B
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Subtract

  FUNCTION NM_Mtx_Det(n, A) RESULT(det)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: A(n,n)
    REAL(wp) :: det
    IF (n == 1) THEN
      det = A(1,1)
    ELSE IF (n == 2) THEN
      det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
    ELSE IF (n == 3) THEN
      det = A(1,1)*(A(2,2)*A(3,3) - A(2,3)*A(3,2)) - &
            A(1,2)*(A(2,1)*A(3,3) - A(2,3)*A(3,1)) + &
            A(1,3)*(A(2,1)*A(3,2) - A(2,2)*A(3,1))
    ELSE
      det = 0.0_wp
    END IF
  END FUNCTION NM_Mtx_Det

  SUBROUTINE NM_Mtx_Diag(n, d, A, status)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: d(n)
    REAL(wp), INTENT(OUT) :: A(n,n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: i
    A = 0.0_wp
    DO i = 1, n
      A(i,i) = d(i)
    END DO
    IF (PRESENT(status)) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE NM_Mtx_Diag

  SUBROUTINE NM_Mtx_Eye(n, Id, status)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(OUT) :: Id(n,n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: ii
    Id = 0.0_wp
    DO ii = 1, n
      Id(ii,ii) = 1.0_wp
    END DO
    IF (PRESENT(status)) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE NM_Mtx_Eye

  SUBROUTINE NM_Mtx_Gemm(transa, transb, m, n, k, alpha, A, B, beta, C, status)
    CHARACTER(LEN=1), INTENT(IN) :: transa, transb
    INTEGER(i4), INTENT(IN) :: m, n, k
    REAL(wp), INTENT(IN) :: alpha, beta
    REAL(wp), INTENT(IN) :: A(:,:), B(:,:)
    REAL(wp), INTENT(INOUT) :: C(m,n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: i, j, l
    REAL(wp), ALLOCATABLE :: temp(:,:)
    IF (PRESENT(status)) CALL init_error_status(status)
    ALLOCATE(temp(m,n))
    temp = 0.0_wp
    IF ((transa == 'N' .OR. transa == 'n') .AND. (transb == 'N' .OR. transb == 'n')) THEN
      DO j = 1, n
        DO l = 1, k
          DO i = 1, m
            temp(i,j) = temp(i,j) + A(i,l) * B(l,j)
          END DO
        END DO
      END DO
    ELSE IF ((transa == 'T' .OR. transa == 't') .AND. (transb == 'N' .OR. transb == 'n')) THEN
      DO j = 1, n
        DO l = 1, k
          DO i = 1, m
            temp(i,j) = temp(i,j) + A(l,i) * B(l,j)
          END DO
        END DO
      END DO
    ELSE IF ((transa == 'N' .OR. transa == 'n') .AND. (transb == 'T' .OR. transb == 't')) THEN
      DO j = 1, n
        DO l = 1, k
          DO i = 1, m
            temp(i,j) = temp(i,j) + A(i,l) * B(j,l)
          END DO
        END DO
      END DO
    ELSE
      DO j = 1, n
        DO l = 1, k
          DO i = 1, m
            temp(i,j) = temp(i,j) + A(l,i) * B(j,l)
          END DO
        END DO
      END DO
    END IF
    C = alpha * temp + beta * C
    DEALLOCATE(temp)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Gemm

  SUBROUTINE NM_Mtx_Gemv(trans, m, n, alpha, A, x, beta, y, status)
    CHARACTER(LEN=1), INTENT(IN) :: trans
    INTEGER(i4), INTENT(IN) :: m, n
    REAL(wp), INTENT(IN) :: alpha, beta
    REAL(wp), INTENT(IN) :: A(m,n), x(*)
    REAL(wp), INTENT(INOUT) :: y(*)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: i, j
    REAL(wp), ALLOCATABLE :: temp(:)
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (trans == 'N' .OR. trans == 'n') THEN
      ALLOCATE(temp(m))
      temp = 0.0_wp
      DO j = 1, n
        DO i = 1, m
          temp(i) = temp(i) + A(i,j) * x(j)
        END DO
      END DO
      y(1:m) = alpha * temp + beta * y(1:m)
      DEALLOCATE(temp)
    ELSE IF (trans == 'T' .OR. trans == 't') THEN
      ALLOCATE(temp(n))
      temp = 0.0_wp
      DO i = 1, m
        DO j = 1, n
          temp(j) = temp(j) + A(i,j) * x(i)
        END DO
      END DO
      y(1:n) = alpha * temp + beta * y(1:n)
      DEALLOCATE(temp)
    END IF
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Gemv

  SUBROUTINE NM_Mtx_Ger(m, n, alpha, x, y, A, status)
    INTEGER(i4), INTENT(IN) :: m, n
    REAL(wp), INTENT(IN) :: alpha
    REAL(wp), INTENT(IN) :: x(m), y(n)
    REAL(wp), INTENT(INOUT) :: A(m,n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: i, j
    IF (PRESENT(status)) CALL init_error_status(status)
    DO j = 1, n
      DO i = 1, m
        A(i,j) = A(i,j) + alpha * x(i) * y(j)
      END DO
    END DO
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Ger

  SUBROUTINE NM_Mtx_Inv(n, A, Ainv, status)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: A(n,n)
    REAL(wp), INTENT(OUT) :: Ainv(n,n)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: det
    CALL init_error_status(status)
    IF (n == 2) THEN
      det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(det) < EPSILON(1.0_wp)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Matrix is singular"
        RETURN
      END IF
      Ainv(1,1) =  A(2,2) / det
      Ainv(1,2) = -A(1,2) / det
      Ainv(2,1) = -A(2,1) / det
      Ainv(2,2) =  A(1,1) / det
    ELSE
      status%status_code = IF_STATUS_INVALID
      status%message = "Inverse only implemented for 2x2 matrices"
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Inv

  FUNCTION NM_Mtx_Norm1(m, n, A) RESULT(norm_1)
    INTEGER(i4), INTENT(IN) :: m, n
    REAL(wp), INTENT(IN) :: A(m,n)
    REAL(wp) :: norm_1
    INTEGER(i4) :: j
    norm_1 = 0.0_wp
    DO j = 1, n
      norm_1 = MAX(norm_1, SUM(ABS(A(:,j))))
    END DO
  END FUNCTION NM_Mtx_Norm1

  FUNCTION NM_Mtx_NormF(m, n, A) RESULT(norm_F)
    INTEGER(i4), INTENT(IN) :: m, n
    REAL(wp), INTENT(IN) :: A(m,n)
    REAL(wp) :: norm_F
    norm_F = SQRT(SUM(A**2))
  END FUNCTION NM_Mtx_NormF

  FUNCTION NM_Mtx_NormInf(m, n, A) RESULT(norm_inf)
    INTEGER(i4), INTENT(IN) :: m, n
    REAL(wp), INTENT(IN) :: A(m,n)
    REAL(wp) :: norm_inf
    INTEGER(i4) :: i
    norm_inf = 0.0_wp
    DO i = 1, m
      norm_inf = MAX(norm_inf, SUM(ABS(A(i,:))))
    END DO
  END FUNCTION NM_Mtx_NormInf

  SUBROUTINE NM_Mtx_Symm(side, uplo, m, n, alpha, A, B, beta, C, status)
    CHARACTER(LEN=1), INTENT(IN) :: side, uplo
    INTEGER(i4), INTENT(IN) :: m, n
    REAL(wp), INTENT(IN) :: alpha, beta
    REAL(wp), INTENT(IN) :: A(:,:), B(m,n)
    REAL(wp), INTENT(INOUT) :: C(m,n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (side == 'L' .OR. side == 'l') THEN
      C = alpha * MATMUL(A(1:m,1:m), B) + beta * C
    ELSE
      C = alpha * MATMUL(B, A(1:n,1:n)) + beta * C
    END IF
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Symm

  SUBROUTINE NM_Mtx_Symv(uplo, n, alpha, A, x, beta, y, status)
    CHARACTER(LEN=1), INTENT(IN) :: uplo
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: alpha, beta
    REAL(wp), INTENT(IN) :: A(n,n), x(n)
    REAL(wp), INTENT(INOUT) :: y(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: i, j
    REAL(wp) :: temp(n)
    LOGICAL :: is_upper
    IF (PRESENT(status)) CALL init_error_status(status)
    is_upper = (uplo == 'U' .OR. uplo == 'u')
    temp = 0.0_wp
    IF (is_upper) THEN
      DO i = 1, n
        DO j = i, n
          temp(i) = temp(i) + A(i,j) * x(j)
          IF (i /= j) temp(j) = temp(j) + A(i,j) * x(i)
        END DO
      END DO
    ELSE
      DO i = 1, n
        DO j = 1, i
          temp(i) = temp(i) + A(i,j) * x(j)
          IF (i /= j) temp(j) = temp(j) + A(i,j) * x(i)
        END DO
      END DO
    END IF
    y = alpha * temp + beta * y
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Symv

  FUNCTION NM_Mtx_Trace(n, A) RESULT(trace)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: A(n,n)
    REAL(wp) :: trace
    INTEGER(i4) :: i
    trace = 0.0_wp
    DO i = 1, n
      trace = trace + A(i,i)
    END DO
  END FUNCTION NM_Mtx_Trace

  SUBROUTINE NM_Mtx_Transpose(m, n, A, AT, status)
    INTEGER(i4), INTENT(IN) :: m, n
    REAL(wp), INTENT(IN) :: A(m,n)
    REAL(wp), INTENT(OUT) :: AT(n,m)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    AT = TRANSPOSE(A)
    IF (PRESENT(status)) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_OK
    END IF
  END SUBROUTINE NM_Mtx_Transpose

  SUBROUTINE NM_Mtx_Trmm(side, uplo, transa, diag, m, n, alpha, A, B, status)
    CHARACTER(LEN=1), INTENT(IN) :: side, uplo, transa, diag
    INTEGER(i4), INTENT(IN) :: m, n
    REAL(wp), INTENT(IN) :: alpha
    REAL(wp), INTENT(IN) :: A(:,:)
    REAL(wp), INTENT(INOUT) :: B(m,n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (side == 'L' .OR. side == 'l') THEN
      B = alpha * MATMUL(A(1:m,1:m), B)
    ELSE
      B = alpha * MATMUL(B, A(1:n,1:n))
    END IF
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Trmm

  SUBROUTINE NM_Mtx_Trmv(uplo, trans, diag, n, A, x, status)
    CHARACTER(LEN=1), INTENT(IN) :: uplo, trans, diag
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: A(n,n)
    REAL(wp), INTENT(INOUT) :: x(n)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: i, j
    REAL(wp) :: temp(n)
    LOGICAL :: is_upper, is_unit
    IF (PRESENT(status)) CALL init_error_status(status)
    is_upper = (uplo == 'U' .OR. uplo == 'u')
    is_unit = (diag == 'U' .OR. diag == 'u')
    temp = x
    IF (is_upper) THEN
      DO i = 1, n
        x(i) = 0.0_wp
        DO j = i, n
          IF (i == j .AND. is_unit) THEN
            x(i) = x(i) + temp(j)
          ELSE
            x(i) = x(i) + A(i,j) * temp(j)
          END IF
        END DO
      END DO
    ELSE
      DO i = 1, n
        x(i) = 0.0_wp
        DO j = 1, i
          IF (i == j .AND. is_unit) THEN
            x(i) = x(i) + temp(j)
          ELSE
            x(i) = x(i) + A(i,j) * temp(j)
          END IF
        END DO
      END DO
    END IF
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_Trmv

  !===========================================================================
  ! CSR / UF_CSRMatrix (merged from UF_SparseMatrix)
  !===========================================================================
  SUBROUTINE csr_create(mat, nrows, ncols, nnz_estimate, ierr)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    INTEGER(i4), INTENT(IN) :: nrows, ncols
    INTEGER(i4), INTENT(IN), OPTIONAL :: nnz_estimate
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: nnz_est, istat
    IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
    CALL csr_destroy(mat)
    mat%nrows = nrows
    mat%ncols = ncols
    IF (PRESENT(nnz_estimate)) THEN
      nnz_est = nnz_estimate
    ELSE
      nnz_est = MAX(10 * nrows, 100)
    END IF
    ALLOCATE(mat%row_ptr(nrows + 1), STAT=istat)
    IF (istat /= 0) THEN
      IF (PRESENT(ierr)) ierr = CSR_ERR_ALLOC
      RETURN
    END IF
    ALLOCATE(mat%col_ind(nnz_est), STAT=istat)
    IF (istat /= 0) THEN
      IF (PRESENT(ierr)) ierr = CSR_ERR_ALLOC
      RETURN
    END IF
    ALLOCATE(mat%val(nnz_est), STAT=istat)
    IF (istat /= 0) THEN
      IF (PRESENT(ierr)) ierr = CSR_ERR_ALLOC
      RETURN
    END IF
    mat%row_ptr = 1
    mat%col_ind = 0
    mat%val = CSR_ZERO
    mat%nnz = 0
    mat%is_initialized = .TRUE.
  END SUBROUTINE csr_create

  SUBROUTINE csr_destroy(mat)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    IF (ALLOCATED(mat%val)) DEALLOCATE(mat%val)
    IF (ALLOCATED(mat%col_ind)) DEALLOCATE(mat%col_ind)
    IF (ALLOCATED(mat%row_ptr)) DEALLOCATE(mat%row_ptr)
    mat%nrows = 0
    mat%ncols = 0
    mat%nnz = 0
    mat%is_symmetric = .FALSE.
    mat%is_initialized = .FALSE.
  END SUBROUTINE csr_destroy

  SUBROUTINE csr_destroy_method(this)
    CLASS(UF_CSRMatrix), INTENT(INOUT) :: this
    CALL csr_destroy(this)
  END SUBROUTINE csr_destroy_method

  SUBROUTINE csr_init_from_coo(mat, nrows, ncols, coo_entries, n_entries, ierr)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    INTEGER(i4), INTENT(IN) :: nrows, ncols, n_entries
    TYPE(UF_COOEntry), INTENT(IN) :: coo_entries(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: i, row, istat
    INTEGER(i4), ALLOCATABLE :: row_count(:), row_current(:)
    IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
    CALL csr_destroy(mat)
    mat%nrows = nrows
    mat%ncols = ncols
    mat%nnz = n_entries
    ALLOCATE(row_count(nrows), row_current(nrows), STAT=istat)
    IF (istat /= 0) THEN
      IF (PRESENT(ierr)) ierr = CSR_ERR_ALLOC
      RETURN
    END IF
    row_count = 0
    DO i = 1, n_entries
      row = coo_entries(i)%row
      IF (row >= 1 .AND. row <= nrows) row_count(row) = row_count(row) + 1
    END DO
    ALLOCATE(mat%row_ptr(nrows + 1), mat%col_ind(n_entries), mat%val(n_entries), STAT=istat)
    IF (istat /= 0) THEN
      IF (PRESENT(ierr)) ierr = CSR_ERR_ALLOC
      RETURN
    END IF
    mat%row_ptr(1) = 1
    DO i = 1, nrows
      mat%row_ptr(i + 1) = mat%row_ptr(i) + row_count(i)
    END DO
    row_current = mat%row_ptr(1:nrows)
    DO i = 1, n_entries
      row = coo_entries(i)%row
      IF (row >= 1 .AND. row <= nrows) THEN
        mat%col_ind(row_current(row)) = coo_entries(i)%col
        mat%val(row_current(row)) = coo_entries(i)%val
        row_current(row) = row_current(row) + 1
      END IF
    END DO
    DEALLOCATE(row_count, row_current)
    mat%is_initialized = .TRUE.
  END SUBROUTINE csr_init_from_coo

  SUBROUTINE csr_init(this, nrows, ncols, nnz, ierr)
    CLASS(UF_CSRMatrix), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: nrows, ncols, nnz
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    CALL csr_create(this, nrows, ncols, nnz, ierr)
  END SUBROUTINE csr_init

  FUNCTION csr_get_value(mat, row, col) RESULT(val)
    TYPE(UF_CSRMatrix), INTENT(IN) :: mat
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp) :: val
    INTEGER(i4) :: k
    val = CSR_ZERO
    IF (row < 1 .OR. row > mat%nrows) RETURN
    IF (col < 1 .OR. col > mat%ncols) RETURN
    DO k = mat%row_ptr(row), mat%row_ptr(row + 1) - 1
      IF (mat%col_ind(k) == col) THEN
        val = mat%val(k)
        RETURN
      END IF
    END DO
  END FUNCTION csr_get_value

  FUNCTION csr_get_value_method(this, row, col) RESULT(val)
    CLASS(UF_CSRMatrix), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp) :: val
    val = csr_get_value(this, row, col)
  END FUNCTION csr_get_value_method

  SUBROUTINE csr_set_value(mat, row, col, val, ierr)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: val
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: k
    IF (PRESENT(ierr)) ierr = CSR_ERR_NOT_FOUND
    IF (row < 1 .OR. row > mat%nrows) RETURN
    IF (col < 1 .OR. col > mat%ncols) RETURN
    DO k = mat%row_ptr(row), mat%row_ptr(row + 1) - 1
      IF (mat%col_ind(k) == col) THEN
        mat%val(k) = val
        IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
        RETURN
      END IF
    END DO
  END SUBROUTINE csr_set_value

  SUBROUTINE csr_set_value_method(this, row, col, val, ierr)
    CLASS(UF_CSRMatrix), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: val
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    CALL csr_set_value(this, row, col, val, ierr)
  END SUBROUTINE csr_set_value_method

  SUBROUTINE csr_add_value(mat, row, col, val, ierr)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: val
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: k
    IF (PRESENT(ierr)) ierr = CSR_ERR_NOT_FOUND
    IF (row < 1 .OR. row > mat%nrows) RETURN
    IF (col < 1 .OR. col > mat%ncols) RETURN
    DO k = mat%row_ptr(row), mat%row_ptr(row + 1) - 1
      IF (mat%col_ind(k) == col) THEN
        mat%val(k) = mat%val(k) + val
        IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
        RETURN
      END IF
    END DO
  END SUBROUTINE csr_add_value

  SUBROUTINE csr_add_value_method(this, row, col, val, ierr)
    CLASS(UF_CSRMatrix), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: row, col
    REAL(wp), INTENT(IN) :: val
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    CALL csr_add_value(this, row, col, val, ierr)
  END SUBROUTINE csr_add_value_method

  SUBROUTINE csr_clear(mat)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    IF (ALLOCATED(mat%val)) mat%val = CSR_ZERO
  END SUBROUTINE csr_clear

  SUBROUTINE csr_zero_matrix(mat)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    CALL csr_clear(mat)
  END SUBROUTINE csr_zero_matrix

  SUBROUTINE csr_deallocate(mat)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    CALL csr_destroy(mat)
  END SUBROUTINE csr_deallocate

  SUBROUTINE csr_scale(mat, alpha)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    REAL(wp), INTENT(IN) :: alpha
    IF (ALLOCATED(mat%val)) mat%val = alpha * mat%val
  END SUBROUTINE csr_scale

  SUBROUTINE csr_copy(src, dst, ierr)
    TYPE(UF_CSRMatrix), INTENT(IN) :: src
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: dst
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: istat
    IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
    CALL csr_destroy(dst)
    dst%nrows = src%nrows
    dst%ncols = src%ncols
    dst%nnz = src%nnz
    dst%is_symmetric = src%is_symmetric
    ALLOCATE(dst%row_ptr(src%nrows + 1), dst%col_ind(src%nnz), dst%val(src%nnz), STAT=istat)
    IF (istat /= 0) THEN
      IF (PRESENT(ierr)) ierr = CSR_ERR_ALLOC
      RETURN
    END IF
    dst%row_ptr = src%row_ptr
    dst%col_ind = src%col_ind(1:src%nnz)
    dst%val = src%val(1:src%nnz)
    dst%is_initialized = .TRUE.
  END SUBROUTINE csr_copy

  SUBROUTINE csr_add_scaled(A, B, alpha, ierr)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: A
    TYPE(UF_CSRMatrix), INTENT(IN) :: B
    REAL(wp), INTENT(IN) :: alpha
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: i
    IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
    IF (A%nrows /= B%nrows .OR. A%ncols /= B%ncols) THEN
      IF (PRESENT(ierr)) ierr = CSR_ERR_SIZE
      RETURN
    END IF
    IF (A%nnz == B%nnz) THEN
      DO i = 1, A%nnz
        A%val(i) = A%val(i) + alpha * B%val(i)
      END DO
    ELSE
      IF (PRESENT(ierr)) ierr = CSR_ERR_SIZE
    END IF
  END SUBROUTINE csr_add_scaled

  SUBROUTINE csr_axpy(A, B, alpha, beta, ierr)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: A
    TYPE(UF_CSRMatrix), INTENT(IN) :: B
    REAL(wp), INTENT(IN) :: alpha, beta
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: i
    IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
    IF (A%nrows /= B%nrows .OR. A%ncols /= B%ncols .OR. A%nnz /= B%nnz) THEN
      IF (PRESENT(ierr)) ierr = CSR_ERR_SIZE
      RETURN
    END IF
    DO i = 1, A%nnz
      A%val(i) = alpha * A%val(i) + beta * B%val(i)
    END DO
  END SUBROUTINE csr_axpy

  SUBROUTINE csr_get_diagonal(mat, diag, ierr)
    TYPE(UF_CSRMatrix), INTENT(IN) :: mat
    REAL(wp), INTENT(OUT) :: diag(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: i, k, n
    IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
    n = MIN(mat%nrows, mat%ncols, SIZE(diag))
    diag(1:n) = CSR_ZERO
    DO i = 1, n
      DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
        IF (mat%col_ind(k) == i) THEN
          diag(i) = mat%val(k)
          EXIT
        END IF
      END DO
    END DO
  END SUBROUTINE csr_get_diagonal

  SUBROUTINE csr_set_diagonal(mat, diag, ierr)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: mat
    REAL(wp), INTENT(IN) :: diag(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
    INTEGER(i4) :: i, k, n
    IF (PRESENT(ierr)) ierr = NM_CSR_SUCCESS
    n = MIN(mat%nrows, mat%ncols, SIZE(diag))
    DO i = 1, n
      DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
        IF (mat%col_ind(k) == i) THEN
          mat%val(k) = diag(i)
          EXIT
        END IF
      END DO
    END DO
  END SUBROUTINE csr_set_diagonal

  SUBROUTINE csr_matvec(this, x, y)
    CLASS(UF_CSRMatrix), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    INTEGER(i4) :: i, k
    REAL(wp) :: t
    DO i = 1, this%nrows
      t = CSR_ZERO
      DO k = this%row_ptr(i), this%row_ptr(i + 1) - 1
        t = t + this%val(k) * x(this%col_ind(k))
      END DO
      y(i) = t
    END DO
  END SUBROUTINE csr_matvec

  SUBROUTINE csr_matvec_trans(this, x, y)
    CLASS(UF_CSRMatrix), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    INTEGER(i4) :: i, k
    y(1:this%ncols) = CSR_ZERO
    DO i = 1, this%nrows
      DO k = this%row_ptr(i), this%row_ptr(i + 1) - 1
        y(this%col_ind(k)) = y(this%col_ind(k)) + x(i) * this%val(k)
      END DO
    END DO
  END SUBROUTINE csr_matvec_trans

  FUNCTION csr_get_row_nnz(this, row) RESULT(nnz)
    CLASS(UF_CSRMatrix), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: row
    INTEGER(i4) :: nnz
    IF (row < 1 .OR. row > this%nrows) THEN
      nnz = 0
    ELSE
      nnz = this%row_ptr(row + 1) - this%row_ptr(row)
    END IF
  END FUNCTION csr_get_row_nnz

  SUBROUTINE csr_info(mat)
    TYPE(UF_CSRMatrix), INTENT(IN) :: mat
    WRITE(*,'(A)') '=== CSR Matrix Info ==='
    WRITE(*,'(A,I10)')   '  Rows:     ', mat%nrows
    WRITE(*,'(A,I10)')   '  Columns:  ', mat%ncols
    WRITE(*,'(A,I10)')   '  Non-zeros:', mat%nnz
    IF (mat%nrows > 0 .AND. mat%ncols > 0) THEN
      WRITE(*,'(A,F10.4,A)') '  Density:  ', &
        100.0_wp * REAL(mat%nnz, wp) / REAL(mat%nrows * mat%ncols, wp), ' %'
    END IF
    WRITE(*,'(A,L1)')    '  Symmetric:', mat%is_symmetric
  END SUBROUTINE csr_info

  SUBROUTINE csr_info_method(this)
    CLASS(UF_CSRMatrix), INTENT(IN) :: this
    CALL csr_info(this)
  END SUBROUTINE csr_info_method

  SUBROUTINE csr_print(mat, max_rows, max_cols, unit_num)
    TYPE(UF_CSRMatrix), INTENT(IN) :: mat
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_rows, max_cols, unit_num
    INTEGER(i4) :: i, k, nr, nc, iu
    nr = MIN(mat%nrows, 20)
    nc = MIN(mat%ncols, 20)
    iu = 6
    IF (PRESENT(max_rows)) nr = MIN(mat%nrows, max_rows)
    IF (PRESENT(max_cols)) nc = MIN(mat%ncols, max_cols)
    IF (PRESENT(unit_num)) iu = unit_num
    WRITE(iu,'(A)') '=== CSR Matrix ==='
    DO i = 1, nr
      DO k = mat%row_ptr(i), mat%row_ptr(i + 1) - 1
        IF (mat%col_ind(k) <= nc) THEN
          WRITE(iu,'(A,I6,A,I6,A,ES15.7)') '  (',i,',',mat%col_ind(k),') = ',mat%val(k)
        END IF
      END DO
    END DO
  END SUBROUTINE csr_print

  SUBROUTINE csr_matvec_direct(A, x, y)
    TYPE(UF_CSRMatrix), INTENT(IN) :: A
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    INTEGER(i4) :: i, k
    REAL(wp) :: t
    DO i = 1, A%nrows
      t = CSR_ZERO
      DO k = A%row_ptr(i), A%row_ptr(i + 1) - 1
        t = t + A%val(k) * x(A%col_ind(k))
      END DO
      y(i) = t
    END DO
  END SUBROUTINE csr_matvec_direct

  SUBROUTINE sparse_lsolve(n, val, col_ind, row_ptr, b, x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: val(:)
    INTEGER(i4), INTENT(IN) :: col_ind(:), row_ptr(:)
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4) :: i, k
    REAL(wp) :: t
    x(1) = b(1)
    DO i = 2, n
      t = b(i)
      DO k = row_ptr(i), row_ptr(i + 1) - 1
        IF (col_ind(k) < i) t = t - val(k) * x(col_ind(k))
      END DO
      x(i) = t
    END DO
  END SUBROUTINE sparse_lsolve

  SUBROUTINE sparse_lsolve_msr(n, alu, jlu, ju, b, x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: alu(:)
    INTEGER(i4), INTENT(IN) :: jlu(:), ju(:)
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4) :: i, k
    REAL(wp) :: t
    x(1) = b(1) * alu(1)
    DO i = 2, n
      t = b(i)
      DO k = jlu(i), ju(i) - 1
        t = t - alu(k) * x(jlu(k))
      END DO
      x(i) = t * alu(i)
    END DO
  END SUBROUTINE sparse_lsolve_msr

  SUBROUTINE sparse_matvec(n, val, col_ind, row_ptr, x, y)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: val(:)
    INTEGER(i4), INTENT(IN) :: col_ind(:), row_ptr(:)
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    INTEGER(i4) :: i, k
    REAL(wp) :: t
    DO i = 1, n
      t = CSR_ZERO
      DO k = row_ptr(i), row_ptr(i + 1) - 1
        t = t + val(k) * x(col_ind(k))
      END DO
      y(i) = t
    END DO
  END SUBROUTINE sparse_matvec

  SUBROUTINE sparse_matvec_trans(n, ncol, val, col_ind, row_ptr, x, y)
    INTEGER(i4), INTENT(IN) :: n, ncol
    REAL(wp), INTENT(IN) :: val(:)
    INTEGER(i4), INTENT(IN) :: col_ind(:), row_ptr(:)
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    INTEGER(i4) :: i, k
    y(1:ncol) = CSR_ZERO
    DO i = 1, n
      DO k = row_ptr(i), row_ptr(i + 1) - 1
        y(col_ind(k)) = y(col_ind(k)) + x(i) * val(k)
      END DO
    END DO
  END SUBROUTINE sparse_matvec_trans

  SUBROUTINE sparse_usolve(n, val, col_ind, row_ptr, b, x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: val(:)
    INTEGER(i4), INTENT(IN) :: col_ind(:), row_ptr(:)
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4) :: i, k
    REAL(wp) :: t
    x(n) = b(n)
    DO i = n - 1, 1, -1
      t = b(i)
      DO k = row_ptr(i), row_ptr(i + 1) - 1
        IF (col_ind(k) > i) t = t - val(k) * x(col_ind(k))
      END DO
      x(i) = t
    END DO
  END SUBROUTINE sparse_usolve

  SUBROUTINE sparse_usolve_msr(n, alu, jlu, ju, b, x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: alu(:)
    INTEGER(i4), INTENT(IN) :: jlu(:), ju(:)
    REAL(wp), INTENT(IN) :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    INTEGER(i4) :: i, k
    REAL(wp) :: t
    x(n) = b(n) * alu(n)
    DO i = n - 1, 1, -1
      t = b(i)
      DO k = ju(i), jlu(i + 1) - 1
        t = t - alu(k) * x(jlu(k))
      END DO
      x(i) = t * alu(i)
    END DO
  END SUBROUTINE sparse_usolve_msr

  SUBROUTINE vec_add(n, x, y, z)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(:), y(:)
    REAL(wp), INTENT(OUT) :: z(:)
    CALL NM_Vec_Add(n, x, y, z)
  END SUBROUTINE vec_add

  SUBROUTINE vec_axpy(n, alpha, x, y)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: alpha
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(INOUT) :: y(:)
    IF (alpha == CSR_ZERO) RETURN
    CALL NM_Vec_Axpy(n, alpha, x, y)
  END SUBROUTINE vec_axpy

  SUBROUTINE vec_copy(n, x, y)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp), INTENT(OUT) :: y(:)
    CALL NM_Vec_Copy(n, x, y)
  END SUBROUTINE vec_copy

  FUNCTION vec_dot(n, x, y) RESULT(dot)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(:), y(:)
    REAL(wp) :: dot
    dot = NM_Vec_Dot(n, x, y)
  END FUNCTION vec_dot

  FUNCTION vec_norm2(n, x) RESULT(nrm)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(:)
    REAL(wp) :: nrm
    nrm = NM_Vec_Nrm2(n, x)
  END FUNCTION vec_norm2

  SUBROUTINE vec_scale(n, alpha, x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: alpha
    REAL(wp), INTENT(INOUT) :: x(:)
    CALL NM_Vec_Scal(n, alpha, x)
  END SUBROUTINE vec_scale

  SUBROUTINE vec_sub(n, x, y, z)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(IN) :: x(:), y(:)
    REAL(wp), INTENT(OUT) :: z(:)
    CALL NM_Vec_Sub(n, x, y, z)
  END SUBROUTINE vec_sub

  SUBROUTINE vec_zero(n, x)
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(OUT) :: x(:)
    CALL NM_Vec_Fill(n, CSR_ZERO, x)
  END SUBROUTINE vec_zero

  !===========================================================================
  ! UF_CSR_Optimizer (merged)
  !===========================================================================
  SUBROUTINE assembly_map_init(this, num_elements, max_dof)
    CLASS(UF_CSR_Assembly_Map), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: num_elements, max_dof
    this%num_elements = num_elements
    this%max_dof_per_elem = max_dof
    ALLOCATE(this%pos(max_dof, max_dof, num_elements))
    this%pos = -1
    this%initialized = .TRUE.
  END SUBROUTINE assembly_map_init

  SUBROUTINE assembly_map_destroy(this)
    CLASS(UF_CSR_Assembly_Map), INTENT(INOUT) :: this
    IF (ALLOCATED(this%pos)) DEALLOCATE(this%pos)
    IF (ALLOCATED(this%pos_flat)) DEALLOCATE(this%pos_flat)
    IF (ALLOCATED(this%elem_offset)) DEALLOCATE(this%elem_offset)
    this%initialized = .FALSE.
  END SUBROUTINE assembly_map_destroy

  SUBROUTINE csr_build_assembly_map(K, elem_dof, elem_ndof, num_elements, amap, ierr)
    TYPE(UF_CSRMatrix), INTENT(IN) :: K
    INTEGER(i4), INTENT(IN) :: elem_dof(:,:), elem_ndof(:)
    INTEGER(i4), INTENT(IN) :: num_elements
    TYPE(UF_CSR_Assembly_Map), INTENT(INOUT) :: amap
    INTEGER(i4), INTENT(OUT) :: ierr
    INTEGER(i4) :: ie, i, j, gi, gj, ndof, max_dof, pos
    ierr = 0
    max_dof = SIZE(elem_dof, 1)
    CALL amap%init(num_elements, max_dof)
    DO ie = 1, num_elements
      ndof = elem_ndof(ie)
      IF (ndof == 0) ndof = max_dof
      DO i = 1, ndof
        gi = elem_dof(i, ie)
        IF (gi <= 0 .OR. gi > K%nrows) CYCLE
        DO j = 1, ndof
          gj = elem_dof(j, ie)
          IF (gj <= 0 .OR. gj > K%ncols) CYCLE
          pos = csr_get_position(K, gi, gj)
          amap%pos(i, j, ie) = pos
        END DO
      END DO
    END DO
  END SUBROUTINE csr_build_assembly_map

  FUNCTION csr_get_position(K, row, col) RESULT(pos)
    TYPE(UF_CSRMatrix), INTENT(IN) :: K
    INTEGER(i4), INTENT(IN) :: row, col
    INTEGER(i4) :: pos
    INTEGER(i4) :: lo, hi, mid
    pos = -1
    IF (row < 1 .OR. row > K%nrows) RETURN
    IF (col < 1 .OR. col > K%ncols) RETURN
    lo = K%row_ptr(row)
    hi = K%row_ptr(row + 1) - 1
    DO WHILE (lo <= hi)
      mid = (lo + hi) / 2
      IF (K%col_ind(mid) == col) THEN
        pos = mid
        RETURN
      ELSE IF (K%col_ind(mid) < col) THEN
        lo = mid + 1
      ELSE
        hi = mid - 1
      END IF
    END DO
  END FUNCTION csr_get_position

  SUBROUTINE csr_fast_assemble_element(K, Ke, amap, ie, ndof)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(IN) :: Ke(:,:)
    TYPE(UF_CSR_Assembly_Map), INTENT(IN) :: amap
    INTEGER(i4), INTENT(IN) :: ie, ndof
    INTEGER(i4) :: i, j, pos
    DO i = 1, ndof
      DO j = 1, ndof
        pos = amap%pos(i, j, ie)
        IF (pos > 0) K%val(pos) = K%val(pos) + Ke(i, j)
      END DO
    END DO
  END SUBROUTINE csr_fast_assemble_element

  SUBROUTINE csr_batch_assemble(K, Ke_batch, amap, elem_list, num_batch, ndof)
    TYPE(UF_CSRMatrix), INTENT(INOUT) :: K
    REAL(wp), INTENT(IN) :: Ke_batch(:,:,:)
    TYPE(UF_CSR_Assembly_Map), INTENT(IN) :: amap
    INTEGER(i4), INTENT(IN) :: elem_list(:), num_batch, ndof
    INTEGER(i4) :: b, i, j, ie, pos
    DO b = 1, num_batch
      ie = elem_list(b)
      DO i = 1, ndof
        DO j = 1, ndof
          pos = amap%pos(i, j, ie)
          IF (pos > 0) K%val(pos) = K%val(pos) + Ke_batch(i, j, b)
        END DO
      END DO
    END DO
  END SUBROUTINE csr_batch_assemble

  SUBROUTINE csr_analyze_bandwidth(K, bandwidth, profile, avg_row_width)
    TYPE(UF_CSRMatrix), INTENT(IN) :: K
    INTEGER(i4), INTENT(OUT) :: bandwidth, profile
    REAL(wp), INTENT(OUT) :: avg_row_width
    INTEGER(i4) :: i, min_col, max_col, row_width, local_bw
    bandwidth = 0
    profile = 0
    avg_row_width = 0.0_wp
    DO i = 1, K%nrows
      row_width = K%row_ptr(i+1) - K%row_ptr(i)
      IF (row_width == 0) CYCLE
      min_col = K%col_ind(K%row_ptr(i))
      max_col = K%col_ind(K%row_ptr(i+1) - 1)
      local_bw = MAX(ABS(i - min_col), ABS(i - max_col))
      IF (local_bw > bandwidth) bandwidth = local_bw
      profile = profile + (max_col - min_col + 1)
    END DO
    avg_row_width = REAL(K%nnz, wp) / REAL(K%nrows, wp)
  END SUBROUTINE csr_analyze_bandwidth

  SUBROUTINE csr_reorder_rcm(K, perm, inv_perm)
    TYPE(UF_CSRMatrix), INTENT(IN) :: K
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: perm(:), inv_perm(:)
    INTEGER(i4) :: n, i, j, start_node, current, next_idx
    INTEGER(i4), ALLOCATABLE :: degree(:), level(:), queue(:)
    LOGICAL, ALLOCATABLE :: visited(:)
    INTEGER(i4) :: front, back, min_degree, min_deg_node
    n = K%nrows
    ALLOCATE(perm(n), inv_perm(n), degree(n), level(n), queue(n), visited(n))
    DO i = 1, n
      degree(i) = K%row_ptr(i+1) - K%row_ptr(i)
    END DO
    min_degree = n + 1
    start_node = 1
    DO i = 1, n
      IF (degree(i) > 0 .AND. degree(i) < min_degree) THEN
        min_degree = degree(i)
        start_node = i
      END IF
    END DO
    visited = .FALSE.
    level = 0
    front = 1
    back = 0
    next_idx = 0
    back = back + 1
    queue(back) = start_node
    visited(start_node) = .TRUE.
    DO WHILE (front <= back)
      current = queue(front)
      front = front + 1
      next_idx = next_idx + 1
      perm(next_idx) = current
      CALL add_neighbors_sorted(K, current, degree, visited, queue, back)
    END DO
    DO i = 1, n
      IF (.NOT. visited(i)) THEN
        next_idx = next_idx + 1
        perm(next_idx) = i
      END IF
    END DO
    DO i = 1, n / 2
      j = perm(i)
      perm(i) = perm(n - i + 1)
      perm(n - i + 1) = j
    END DO
    DO i = 1, n
      inv_perm(perm(i)) = i
    END DO
    DEALLOCATE(degree, level, queue, visited)
  CONTAINS
    SUBROUTINE add_neighbors_sorted(K, node, degree, visited, queue, back)
      TYPE(UF_CSRMatrix), INTENT(IN) :: K
      INTEGER(i4), INTENT(IN) :: node
      INTEGER(i4), INTENT(IN) :: degree(:)
      LOGICAL, INTENT(INOUT) :: visited(:)
      INTEGER(i4), INTENT(INOUT) :: queue(:)
      INTEGER(i4), INTENT(INOUT) :: back
      INTEGER(i4) :: idx, neighbor, count
      INTEGER(i4), ALLOCATABLE :: neighbors(:), neighbor_deg(:)
      count = K%row_ptr(node+1) - K%row_ptr(node)
      IF (count == 0) RETURN
      ALLOCATE(neighbors(count), neighbor_deg(count))
      count = 0
      DO idx = K%row_ptr(node), K%row_ptr(node+1) - 1
        neighbor = K%col_ind(idx)
        IF (.NOT. visited(neighbor)) THEN
          count = count + 1
          neighbors(count) = neighbor
          neighbor_deg(count) = degree(neighbor)
        END IF
      END DO
      CALL sort_by_key(neighbors, neighbor_deg, count)
      DO idx = 1, count
        neighbor = neighbors(idx)
        IF (.NOT. visited(neighbor)) THEN
          back = back + 1
          queue(back) = neighbor
          visited(neighbor) = .TRUE.
        END IF
      END DO
      DEALLOCATE(neighbors, neighbor_deg)
    END SUBROUTINE add_neighbors_sorted
    SUBROUTINE sort_by_key(arr, key, n)
      INTEGER(i4), INTENT(INOUT) :: arr(:), key(:)
      INTEGER(i4), INTENT(IN) :: n
      INTEGER(i4) :: i, j, temp_a, temp_k
      DO i = 2, n
        temp_a = arr(i)
        temp_k = key(i)
        j = i - 1
        DO WHILE (j >= 1 .AND. key(j) > temp_k)
          arr(j+1) = arr(j)
          key(j+1) = key(j)
          j = j - 1
        END DO
        arr(j+1) = temp_a
        key(j+1) = temp_k
      END DO
    END SUBROUTINE sort_by_key
  END SUBROUTINE csr_reorder_rcm

END MODULE NM_Mtx_Core
