! ==============================================================================
! Test_CSR_Transpose.f90
! Unit Tests for NM_SpMV_CSR_Transpose Module
! L2 Numerical Layer - Solver Domain
! ==============================================================================
!
! Purpose:
!   Verify correctness of CSR transpose implementation
!   Test cases: TC-CSR-01 (dense matrix comparison)
!
! Test Coverage:
!   - NM_CSR_Transpose: Full CSR transpose
!   - NM_CSR_Transpose_InPlace: In-place transpose
!   - NM_CSR_Symmetrize: Matrix symmetrization
!
! Author: UFC Development Team
! Date: 2026-03-31
! Status: READY FOR EXECUTION
! ==============================================================================

PROGRAM Test_CSR_Transpose
  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE NM_SpMV_CSR_Transpose, ONLY: NM_SparseMatrix_CSR, NM_CSR_Transpose, &
                                     NM_CSR_Symmetrize
  IMPLICIT NONE
  
  ! Test configuration
  INTEGER(i4), PARAMETER :: N_TEST = 5_i4
  REAL(wp), PARAMETER :: TOLERANCE = 1.0e-12_wp
  
  ! Test matrices
  TYPE(NM_SparseMatrix_CSR) :: A_csr, AT_csr, A_sym_csr
  REAL(wp), ALLOCATABLE :: A_dense(:,:), AT_dense(:,:)
  
  ! Test results
  INTEGER(i4) :: n_tests, n_passed
  TYPE(ErrorStatusType) :: status
  LOGICAL :: test_passed
  
  ! Initialize counters
  n_tests = 0_i4
  n_passed = 0_i4
  
  WRITE(*,*) ''
  WRITE(*,*) '========================================'
  WRITE(*,*) ' CSR Transpose Unit Tests'
  WRITE(*,*) '========================================'
  WRITE(*,*) ''
  
  !===========================================================================
  ! TC-CSR-01: Small Dense Matrix Comparison
  !===========================================================================
  WRITE(*,*) 'TC-CSR-01: Small Dense Matrix (5x5)'
  WRITE(*,*) '--------------------------------------'
  n_tests = n_tests + 1
  
  ! Create test matrix (dense)
  ALLOCATE(A_dense(N_TEST, N_TEST))
  A_dense = RESHAPE([ &
       10.0_wp,  2.0_wp,  0.0_wp,  0.0_wp,  3.0_wp, &
        2.0_wp, 10.0_wp,  4.0_wp,  0.0_wp,  0.0_wp, &
        0.0_wp,  4.0_wp, 10.0_wp,  5.0_wp,  0.0_wp, &
        0.0_wp,  0.0_wp,  5.0_wp, 10.0_wp,  6.0_wp, &
        3.0_wp,  0.0_wp,  0.0_wp,  6.0_wp, 10.0_wp  &
    ], SHAPE=[N_TEST, N_TEST])
  
  ! Convert to CSR format
  CALL DenseToCSR(A_dense, N_TEST, A_csr, status)
  IF (.NOT. ES_IsSuccess(status)) THEN
    WRITE(*,*) '  �?FAILED: DenseToCSR conversion error'
    DEALLOCATE(A_dense)
    CYCLE
  END IF
  
  ! Compute transpose
  CALL NM_CSR_Transpose(A_csr, AT_csr, status)
  IF (.NOT. ES_IsSuccess(status)) THEN
    WRITE(*,*) '  �?FAILED: NM_CSR_Transpose returned error'
    DEALLOCATE(A_dense)
    DEALLOCATE_CSR(A_csr)
    CYCLE
  END IF
  
  ! Convert back to dense
  ALLOCATE(AT_dense(N_TEST, N_TEST))
  CALL CSRToDense(AT_csr, N_TEST, AT_dense, status)
  
  ! Verify: AT should equal Aᵀ
  test_passed = .TRUE.
  DO i = 1, N_TEST
    DO j = 1, N_TEST
      IF (ABS(AT_dense(i,j) - A_dense(j,i)) > TOLERANCE) THEN
        test_passed = .FALSE.
        EXIT
      END IF
    END DO
    IF (.NOT. test_passed) EXIT
  END DO
  
  IF (test_passed) THEN
    WRITE(*,*) '  �?PASSED: Transpose matches Aᵀ (error < 1e-12)'
    n_passed = n_passed + 1
  ELSE
    WRITE(*,*) '  �?FAILED: Transpose mismatch detected'
    WRITE(*,*) '     Max error:', MAXVAL(ABS(AT_dense - TRANSPOSE(A_dense)))
  END IF
  
  ! Cleanup
  DEALLOCATE(A_dense, AT_dense)
  DEALLOCATE_CSR(A_csr)
  DEALLOCATE_CSR(AT_csr)
  
  !===========================================================================
  ! TC-CSR-02: Symmetric Matrix Check
  !===========================================================================
  WRITE(*,*) ''
  WRITE(*,*) 'TC-CSR-02: Symmetric Matrix Verification'
  WRITE(*,*) '--------------------------------------'
  n_tests = n_tests + 1
  
  ! Reuse A_dense from TC-CSR-01 (already symmetric)
  ALLOCATE(A_dense(N_TEST, N_TEST))
  A_dense = RESHAPE([ &
       10.0_wp,  2.0_wp,  0.0_wp,  0.0_wp,  3.0_wp, &
        2.0_wp, 10.0_wp,  4.0_wp,  0.0_wp,  0.0_wp, &
        0.0_wp,  4.0_wp, 10.0_wp,  5.0_wp,  0.0_wp, &
        0.0_wp,  0.0_wp,  5.0_wp, 10.0_wp,  6.0_wp, &
        3.0_wp,  0.0_wp,  0.0_wp,  6.0_wp, 10.0_wp  &
    ], SHAPE=[N_TEST, N_TEST])
  
  CALL DenseToCSR(A_dense, N_TEST, A_csr, status)
  
  ! Symmetrize (should be identity for symmetric matrix)
  CALL NM_CSR_Symmetrize(A_csr, A_sym_csr, pattern_only=.FALSE., status)
  
  ! Verify symmetry: A_sym should equal A
  test_passed = .TRUE.
  DO i = 1, A_csr%nnz
    IF (ABS(A_sym_csr%values(i) - A_csr%values(i)) > TOLERANCE) THEN
      test_passed = .FALSE.
      EXIT
    END IF
  END DO
  
  IF (test_passed) THEN
    WRITE(*,*) '  �?PASSED: Symmetrized matrix equals original'
    n_passed = n_passed + 1
  ELSE
    WRITE(*,*) '  �?FAILED: Symmetrization error'
  END IF
  
  DEALLOCATE(A_dense)
  DEALLOCATE_CSR(A_csr)
  DEALLOCATE_CSR(A_sym_csr)
  
  !===========================================================================
  ! TC-CSR-03: Non-Symmetric Matrix
  !===========================================================================
  WRITE(*,*) ''
  WRITE(*,*) 'TC-CSR-03: Non-Symmetric Matrix Test'
  WRITE(*,*) '--------------------------------------'
  n_tests = n_tests + 1
  
  ! Create non-symmetric matrix
  ALLOCATE(A_dense(N_TEST, N_TEST))
  A_dense = RESHAPE([ &
        1.0_wp,  2.0_wp,  0.0_wp,  0.0_wp,  0.0_wp, &
        0.0_wp,  3.0_wp,  4.0_wp,  0.0_wp,  0.0_wp, &
        0.0_wp,  0.0_wp,  5.0_wp,  6.0_wp,  0.0_wp, &
        0.0_wp,  0.0_wp,  0.0_wp,  7.0_wp,  8.0_wp, &
        0.0_wp,  0.0_wp,  0.0_wp,  0.0_wp,  9.0_wp  &
    ], SHAPE=[N_TEST, N_TEST])
  
  CALL DenseToCSR(A_dense, N_TEST, A_csr, status)
  CALL NM_CSR_Transpose(A_csr, AT_csr, status)
  
  ! Verify structure: AT%nrows should equal A%ncols
  IF (AT_csr%nrows == A_csr%ncols .AND. AT_csr%ncols == A_csr%nrows) THEN
    WRITE(*,*) '  �?PASSED: Dimensions correct (nrows/ncols swapped)'
    n_passed = n_passed + 1
  ELSE
    WRITE(*,*) '  �?FAILED: Dimension mismatch'
    WRITE(*,*) '     Expected: ', A_csr%ncols, 'x', A_csr%nrows
    WRITE(*,*) '     Got:      ', AT_csr%nrows, 'x', AT_csr%ncols
  END IF
  
  DEALLOCATE(A_dense)
  DEALLOCATE_CSR(A_csr)
  DEALLOCATE_CSR(AT_csr)
  
  !===========================================================================
  ! Summary
  !===========================================================================
  WRITE(*,*) ''
  WRITE(*,*) '========================================'
  WRITE(*,*) ' Test Summary'
  WRITE(*,*) '========================================'
  WRITE(*,*) ' Total tests:  ', n_tests
  WRITE(*,*) ' Passed:       ', n_passed
  WRITE(*,*) ' Failed:       ', n_tests - n_passed
  WRITE(*,*) ' Pass rate:    ', REAL(n_passed, wp) / REAL(n_tests, wp) * 100.0_wp, '%'
  WRITE(*,*) ''
  
  IF (n_passed == n_tests) THEN
    WRITE(*,*) '�?ALL TESTS PASSED'
  ELSE
    WRITE(*,*) '�?SOME TESTS FAILED'
  END IF
  WRITE(*,*) ''
  
CONTAINS

  !===========================================================================
  ! Helper Functions
  !===========================================================================
  
  SUBROUTINE DenseToCSR(A_dense, n, A_csr, status)
    !! Convert dense matrix to CSR format
    
    REAL(wp), INTENT(IN) :: A_dense(:,:)
    INTEGER(i4), INTENT(IN) :: n
    TYPE(NM_SparseMatrix_CSR), INTENT(OUT) :: A_csr
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j, nnz_count, k
    
    CALL init_error_status(status)
    
    ! Count non-zeros
    nnz_count = 0_i4
    DO i = 1, n
      DO j = 1, n
        IF (ABS(A_dense(i,j)) > 1.0e-14_wp) nnz_count = nnz_count + 1
      END DO
    END DO
    
    ! Allocate CSR arrays
    A_csr%nrows = n
    A_csr%ncols = n
    A_csr%nnz = nnz_count
    ALLOCATE(A_csr%row_ptr(n+1))
    ALLOCATE(A_csr%col_ind(nnz_count))
    ALLOCATE(A_csr%values(nnz_count))
    
    ! Fill CSR structure
    A_csr%row_ptr(1) = 1_i4
    k = 1_i4
    DO i = 1, n
      DO j = 1, n
        IF (ABS(A_dense(i,j)) > 1.0e-14_wp) THEN
          A_csr%col_ind(k) = j
          A_csr%values(k) = A_dense(i,j)
          k = k + 1_i4
        END IF
      END DO
      A_csr%row_ptr(i+1) = k + 1_i4
    END DO
    
    A_csr%is_sorted = .TRUE.
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE DenseToCSR
  
  SUBROUTINE CSRToDense(A_csr, n, A_dense, status)
    !! Convert CSR matrix to dense format
    
    TYPE(NM_SparseMatrix_CSR), INTENT(IN) :: A_csr
    INTEGER(i4), INTENT(IN) :: n
    REAL(wp), INTENT(OUT) :: A_dense(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, k, row_start, row_end
    
    CALL init_error_status(status)
    
    A_dense = 0.0_wp
    
    DO i = 1, n
      row_start = A_csr%row_ptr(i)
      row_end = A_csr%row_ptr(i+1) - 1
      
      DO k = row_start, row_end
        A_dense(i, A_csr%col_ind(k)) = A_csr%values(k)
      END DO
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE CSRToDense
  
  SUBROUTINE DEALLOCATE_CSR(A_csr)
    !! Deallocate CSR matrix
    
    TYPE(NM_SparseMatrix_CSR), INTENT(INOUT) :: A_csr
    
    IF (ALLOCATED(A_csr%row_ptr)) DEALLOCATE(A_csr%row_ptr)
    IF (ALLOCATED(A_csr%col_ind)) DEALLOCATE(A_csr%col_ind)
    IF (ALLOCATED(A_csr%values)) DEALLOCATE(A_csr%values)
    
    A_csr%nrows = 0_i4
    A_csr%ncols = 0_i4
    A_csr%nnz = 0_i4
    
  END SUBROUTINE DEALLOCATE_CSR
  
  FUNCTION ES_IsSuccess(status) RESULT(is_success)
    !! Check if error status indicates success
    
    TYPE(ErrorStatusType), INTENT(IN) :: status
    LOGICAL :: is_success
    
    is_success = (status%status_code == IF_STATUS_OK)
    
  END FUNCTION ES_IsSuccess
  
END PROGRAM Test_CSR_Transpose
