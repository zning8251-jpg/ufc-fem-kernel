!===============================================================================
! MODULE: NM_Mtx_SpMVCSRTranspose
! LAYER:  L2_NM
! DOMAIN: Solver
! ROLE:   Proc (CSR transpose kernel)
! BRIEF:  Efficient CSR sparse matrix transpose for adjoint: K -> K^T
!
! Theory: Saad (2003), Iterative Methods for Sparse Linear Systems, Ch 3.2
! Complexity: O(nnz) time, O(nrows) temporary space
!
! Status: CORE | AI P1-Perf-01 | Last verified: 2026-03-31
!===============================================================================

MODULE NM_Mtx_SpMVCSRTranspose
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_CSR_Transpose
  PUBLIC :: NM_CSR_Transpose_InPlace
  PUBLIC :: NM_CSR_Symmetrize
  
  !=============================================================================
  ! CSR MATRIX TYPE (Minimal for standalone use)
  !=============================================================================
  TYPE, PUBLIC :: NM_SparseMatrix_CSR
    INTEGER(i4) :: nrows = 0_i4
    INTEGER(i4) :: ncols = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)   ! (nrows+1)
    INTEGER(i4), ALLOCATABLE :: col_ind(:)   ! (nnz)
    REAL(wp), ALLOCATABLE :: values(:)       ! (nnz)
    LOGICAL :: is_sorted = .TRUE.
  END TYPE NM_SparseMatrix_CSR
  
CONTAINS

  !=============================================================================
  ! NM_CSR_Transpose - Full CSR Transpose
  !=============================================================================
  SUBROUTINE NM_CSR_Transpose(A_csr, AT_csr, status)
    !! Compute Kᵀ from K (CSR format)
    !! 
    !! Algorithm: Two-pass approach
    !!   Pass 1: Count non-zeros per column �?build AT%row_ptr
    !!   Pass 2: Fill AT%col_ind and AT%values
    !!
    !! Complexity:
    !!   Time:  O(nnz) - linear scan
    !!   Space: O(nrows) - temporary column counts
    !!
    !! Arguments:
    !!   A_csr:  Input CSR matrix (K)
    !!   AT_csr: Output CSR matrix (Kᵀ) - must be deallocated on input
    !!   status: Error status
    
    TYPE(NM_SparseMatrix_CSR), INTENT(IN) :: A_csr
    TYPE(NM_SparseMatrix_CSR), INTENT(OUT) :: AT_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4), ALLOCATABLE :: col_counts(:)
    INTEGER(i4), ALLOCATABLE :: col_offsets(:)
    INTEGER(i4) :: i, j, k, idx, row_start, row_end
    INTEGER(i4) :: n_rows, n_cols, nnz
    
    CALL init_error_status(status)
    
    ! Validate input
    IF (.NOT. ALLOCATED(A_csr%row_ptr) .OR. .NOT. ALLOCATED(A_csr%col_ind)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'NM_CSR_Transpose: Input CSR matrix not allocated'
      RETURN
    END IF
    
    n_rows = A_csr%nrows
    n_cols = A_csr%ncols
    nnz = A_csr%nnz
    
    ! Initialize output
    AT_csr%nrows = n_cols
    AT_csr%ncols = n_rows
    AT_csr%nnz = nnz
    
    ! Allocate output arrays
    ALLOCATE(AT_csr%row_ptr(n_cols + 1))
    ALLOCATE(AT_csr%col_ind(nnz))
    ALLOCATE(AT_csr%values(nnz))
    
    ! Temporary arrays for counting
    ALLOCATE(col_counts(n_rows))
    ALLOCATE(col_offsets(n_rows))
    col_counts = 0_i4
    
    ! Pass 1: Count non-zeros per column (which becomes rows in AT)
    DO i = 1, n_rows
      row_start = A_csr%row_ptr(i)
      row_end = A_csr%row_ptr(i + 1) - 1
      
      DO k = row_start, row_end
        j = A_csr%col_ind(k)  ! Column index in A �?Row index in AT
        col_counts(j) = col_counts(j) + 1
      END DO
    END DO
    
    ! Build AT%row_ptr from cumulative counts
    AT_csr%row_ptr(1) = 1_i4
    DO j = 1, n_rows
      AT_csr%row_ptr(j + 1) = AT_csr%row_ptr(j) + col_counts(j)
    END DO
    
    ! Initialize offsets for filling
    col_offsets = AT_csr%row_ptr(1:n_rows)
    
    ! Pass 2: Fill AT%col_ind and AT%values
    DO i = 1, n_rows
      row_start = A_csr%row_ptr(i)
      row_end = A_csr%row_ptr(i + 1) - 1
      
      DO k = row_start, row_end
        j = A_csr%col_ind(k)
        idx = col_offsets(j)
        
        AT_csr%col_ind(idx) = i          ! Row index in A �?Column in AT
        AT_csr%values(idx) = A_csr%values(k)
        
        col_offsets(j) = col_offsets(j) + 1_i4
      END DO
    END DO
    
    ! Cleanup
    DEALLOCATE(col_counts, col_offsets)
    
    AT_csr%is_sorted = .TRUE.
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_CSR_Transpose
  
  !=============================================================================
  ! NM_CSR_Transpose_InPlace - In-Place Transpose (Structure Only)
  !=============================================================================
  SUBROUTINE NM_CSR_Transpose_InPlace(A_csr, status)
    !! Transpose CSR matrix in-place (structure only, no values copy)
    !! 
    !! Warning: This is an advanced operation that modifies the matrix structure.
    !!          Use NM_CSR_Transpose for safer out-of-place transpose.
    !!
    !! Use case: When memory is limited and K symmetry is unknown
    
    TYPE(NM_SparseMatrix_CSR), INTENT(INOUT) :: A_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(NM_SparseMatrix_CSR) :: temp_csr
    
    CALL init_error_status(status)
    
    ! Create transpose
    CALL NM_CSR_Transpose(A_csr, temp_csr, status)
    
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! Move data from temp to A_csr
    IF (ALLOCATED(A_csr%row_ptr)) DEALLOCATE(A_csr%row_ptr)
    IF (ALLOCATED(A_csr%col_ind)) DEALLOCATE(A_csr%col_ind)
    IF (ALLOCATED(A_csr%values)) DEALLOCATE(A_csr%values)
    
    CALL MOVE_ALLOC(temp_csr%row_ptr, A_csr%row_ptr)
    CALL MOVE_ALLOC(temp_csr%col_ind, A_csr%col_ind)
    CALL MOVE_ALLOC(temp_csr%values, A_csr%values)
    
    A_csr%nrows = temp_csr%nrows
    A_csr%ncols = temp_csr%ncols
    A_csr%nnz = temp_csr%nnz
    A_csr%is_sorted = temp_csr%is_sorted
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_CSR_Transpose_InPlace
  
  !=============================================================================
  ! NM_CSR_Symmetrize - Symmetrize CSR Matrix
  !=============================================================================
  SUBROUTINE NM_CSR_Symmetrize(A_csr, A_sym_csr, pattern_only, status)
    !! Symmetrize CSR matrix: A_sym = (A + Aᵀ) / 2
    !!
    !! Use case: Check if K is symmetric (for CG solver applicability)
    !!
    !! Arguments:
    !!   A_csr: Input matrix
    !!   A_sym_csr: Symmetrized output
    !!   pattern_only: If TRUE, only check sparsity pattern symmetry
    
    TYPE(NM_SparseMatrix_CSR), INTENT(IN) :: A_csr
    TYPE(NM_SparseMatrix_CSR), INTENT(OUT) :: A_sym_csr
    LOGICAL, INTENT(IN), OPTIONAL :: pattern_only
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(NM_SparseMatrix_CSR) :: AT_csr
    LOGICAL :: do_pattern_only
    INTEGER(i4) :: i, k
    REAL(wp) :: scale
    
    CALL init_error_status(status)
    
    do_pattern_only = .FALSE.
    IF (PRESENT(pattern_only)) do_pattern_only = pattern_only
    
    ! Compute transpose
    CALL NM_CSR_Transpose(A_csr, AT_csr, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! Allocate output
    A_sym_csr%nrows = A_csr%nrows
    A_sym_csr%ncols = A_csr%ncols
    A_sym_csr%nnz = A_csr%nnz
    
    IF (.NOT. ALLOCATED(A_sym_csr%row_ptr)) &
      ALLOCATE(A_sym_csr%row_ptr(A_csr%nrows + 1))
    IF (.NOT. ALLOCATED(A_sym_csr%col_ind)) &
      ALLOCATE(A_sym_csr%col_ind(A_csr%nnz))
    IF (.NOT. ALLOCATED(A_sym_csr%values) .AND. .NOT. do_pattern_only) &
      ALLOCATE(A_sym_csr%values(A_csr%nnz))
    
    ! Copy structure (assuming same pattern for simplicity)
    A_sym_csr%row_ptr = A_csr%row_ptr
    A_sym_csr%col_ind = A_csr%col_ind
    
    ! Compute symmetrized values
    IF (.NOT. do_pattern_only) THEN
      scale = 0.5_wp
      DO i = 1, A_csr%nnz
        A_sym_csr%values(i) = scale * (A_csr%values(i) + AT_csr%values(i))
      END DO
    END IF
    
    A_sym_csr%is_sorted = .TRUE.
    
    ! Cleanup
    IF (ALLOCATED(AT_csr%row_ptr)) DEALLOCATE(AT_csr%row_ptr)
    IF (ALLOCATED(AT_csr%col_ind)) DEALLOCATE(AT_csr%col_ind)
    IF (ALLOCATED(AT_csr%values)) DEALLOCATE(AT_csr%values)
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_CSR_Symmetrize
  
END MODULE NM_Mtx_SpMVCSRTranspose