!===============================================================================
! MODULE: NM_Solv_Precond
! LAYER:  L2_NM
! DOMAIN: Solver
! ROLE:   Proc (preconditioner construction)
! BRIEF:  CSR Jacobi / ILU(0) / SSOR preconditioner construction
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!
! Status: SIO-REFACTORED | Last verified: 2026-04-18
!===============================================================================
MODULE NM_Solv_Precond

  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Mtx_Def
  USE NM_Solv_Def
  IMPLICIT NONE

  PRIVATE
  PUBLIC :: Construct_Jacobi_Precond, Construct_ILU0_Precond
  PUBLIC :: Construct_SSOR_Precond

CONTAINS

  SUBROUTINE Precond_Free_CSR(precond)
    !> [INOUT] precond - Preconditioner to free
    TYPE(NM_Precond_State), INTENT(INOUT) :: precond
    IF (ALLOCATED(precond%pc_row_ptr)) DEALLOCATE(precond%pc_row_ptr)
    IF (ALLOCATED(precond%pc_col_idx)) DEALLOCATE(precond%pc_col_idx)
    IF (ALLOCATED(precond%pc_mat_vals)) DEALLOCATE(precond%pc_mat_vals)
    IF (ALLOCATED(precond%pc_lu_vals)) DEALLOCATE(precond%pc_lu_vals)
    precond%pc_nnz = 0_i8
  END SUBROUTINE Precond_Free_CSR

  SUBROUTINE CSR_ILU0_Factor(n, row_ptr, col_idx, alu)
    !> [IN]    n       - Matrix dimension
    !> [IN]    row_ptr - CSR row pointer array
    !> [IN]    col_idx - CSR column index array
    !> [INOUT] alu     - Matrix values (modified in-place)
    INTEGER(i4), INTENT(IN) :: n
    INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
    REAL(wp), INTENT(INOUT) :: alu(:)
    INTEGER(i4) :: k, i, j, kk, ik, kj, ij
    REAL(wp) :: pivot, lik

    DO k = 1, n - 1
      kk = CSR_Find_Pattern(n, row_ptr, col_idx, k, k)
      IF (kk == 0_i4) CYCLE
      pivot = alu(kk)
      IF (ABS(pivot) < 1.0E-30_wp) CYCLE

      DO i = k + 1, n
        ik = CSR_Find_Pattern(n, row_ptr, col_idx, i, k)
        IF (ik == 0_i4) CYCLE
        lik = alu(ik) / pivot
        alu(ik) = lik
        DO j = k + 1, n
          kj = CSR_Find_Pattern(n, row_ptr, col_idx, k, j)
          IF (kj == 0_i4) CYCLE
          ij = CSR_Find_Pattern(n, row_ptr, col_idx, i, j)
          IF (ij == 0_i4) CYCLE
          alu(ij) = alu(ij) - lik * alu(kj)
        END DO
      END DO
    END DO
  END SUBROUTINE CSR_ILU0_Factor

  PURE FUNCTION CSR_Find_Pattern(n, row_ptr, col_idx, i, j) RESULT(p)
    !> [IN] n       - Matrix dimension
    !> [IN] row_ptr - CSR row pointer array
    !> [IN] col_idx - CSR column index array
    !> [IN] i       - Row index (1-based)
    !> [IN] j       - Column index (1-based)
    !> [OUT] p      - Position in array (0 if not found)
    INTEGER(i4), INTENT(IN) :: n, i, j
    INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
    INTEGER(i4) :: p, jj
    p = 0_i4
    IF (i < 1 .OR. i > n .OR. j < 1 .OR. j > n) RETURN
    IF (SIZE(row_ptr) < i + 1) RETURN
    DO jj = row_ptr(i), row_ptr(i + 1) - 1
      IF (col_idx(jj) == j) THEN
        p = jj
        RETURN
      END IF
    END DO
  END FUNCTION CSR_Find_Pattern

  SUBROUTINE Construct_Jacobi_Precond(A_csr, precond)
    !> [IN]    A_csr   - Input CSR matrix
    !> [INOUT] precond - Preconditioner to construct
    TYPE(SparseMatrix_CSR), INTENT(IN) :: A_csr
    TYPE(NM_Precond_State), INTENT(INOUT) :: precond
    INTEGER(i4) :: i, row_start, row_end, jj, col_idx

    IF (.NOT. A_csr%is_allocated) THEN
      ERROR STOP "Construct_Jacobi_Precond: CSR matrix not allocated"
    END IF
    IF (A_csr%nrows /= A_csr%ncols) THEN
      ERROR STOP "Construct_Jacobi_Precond: Square matrix required"
    END IF

    CALL Precond_Free_CSR(precond)
    precond%n = A_csr%nrows
    precond%precond_type = NM_SOLV_PREC_JACOBI

    IF (ALLOCATED(precond%diag)) DEALLOCATE(precond%diag)
    ALLOCATE(precond%diag(precond%n))
    precond%diag = 0.0_wp

    DO i = 1, precond%n
      row_start = A_csr%row_ptr(i)
      row_end = A_csr%row_ptr(i + 1) - 1
      DO jj = row_start, row_end
        col_idx = A_csr%col_idx(jj)
        IF (col_idx == i) THEN
          precond%diag(i) = A_csr%values(jj)
          EXIT
        END IF
      END DO
      IF (ABS(precond%diag(i)) < 1.0E-14_wp) THEN
        ERROR STOP "Construct_Jacobi_Precond: Zero diagonal"
      END IF
      precond%diag(i) = 1.0_wp / precond%diag(i)
    END DO

    precond%is_constructed = .TRUE.
  END SUBROUTINE Construct_Jacobi_Precond

  SUBROUTINE Construct_ILU0_Precond(A_csr, precond)
    !> [IN]    A_csr   - Input CSR matrix
    !> [INOUT] precond - Preconditioner to construct
    TYPE(SparseMatrix_CSR), INTENT(IN) :: A_csr
    TYPE(NM_Precond_State), INTENT(INOUT) :: precond
    INTEGER(i4) :: n, nnz

    IF (.NOT. A_csr%is_allocated) THEN
      ERROR STOP "Construct_ILU0_Precond: CSR matrix not allocated"
    END IF
    IF (A_csr%nrows /= A_csr%ncols) THEN
      ERROR STOP "Construct_ILU0_Precond: Square matrix required"
    END IF

    n = A_csr%nrows
    IF (.NOT. ALLOCATED(A_csr%values) .OR. .NOT. ALLOCATED(A_csr%row_ptr) &
        .OR. .NOT. ALLOCATED(A_csr%col_idx)) THEN
      ERROR STOP "Construct_ILU0_Precond: Incomplete CSR arrays"
    END IF

    CALL Precond_Free_CSR(precond)
    IF (ALLOCATED(precond%diag)) DEALLOCATE(precond%diag)

    precond%n = n
    precond%precond_type = NM_SOLV_PREC_ILU0
    nnz = A_csr%row_ptr(n + 1) - A_csr%row_ptr(1)
    IF (nnz < 1) THEN
      ERROR STOP "Construct_ILU0_Precond: empty CSR pattern"
    END IF
    IF (nnz > SIZE(A_csr%col_idx) .OR. nnz > SIZE(A_csr%values)) THEN
      ERROR STOP "Construct_ILU0_Precond: CSR nnz exceeds array bounds"
    END IF

    ALLOCATE(precond%pc_row_ptr(n + 1), precond%pc_col_idx(nnz), precond%pc_lu_vals(nnz))
    precond%pc_row_ptr = A_csr%row_ptr(1:n + 1)
    precond%pc_col_idx(1:nnz) = A_csr%col_idx(1:nnz)
    precond%pc_lu_vals(1:nnz) = A_csr%values(1:nnz)
    precond%pc_nnz = INT(nnz, i8)

    CALL CSR_ILU0_Factor(n, precond%pc_row_ptr, precond%pc_col_idx, precond%pc_lu_vals)

    precond%is_constructed = .TRUE.
  END SUBROUTINE Construct_ILU0_Precond

  SUBROUTINE Construct_SSOR_Precond(A_csr, precond, omega)
    !> [IN]    A_csr   - Input CSR matrix
    !> [INOUT] precond - Preconditioner to construct
    !> [IN]    omega   - Relaxation parameter (optional, default 1.75)
    TYPE(SparseMatrix_CSR), INTENT(IN) :: A_csr
    TYPE(NM_Precond_State), INTENT(INOUT) :: precond
    REAL(wp), INTENT(IN), OPTIONAL :: omega
    REAL(wp) :: w
    INTEGER(i4) :: n, nnz

    w = 1.75_wp
    IF (PRESENT(omega)) w = omega
    IF (w <= 0.0_wp .OR. w > 2.0_wp) THEN
      ERROR STOP "Construct_SSOR_Precond: Omega should be in (0,2]"
    END IF

    IF (.NOT. A_csr%is_allocated) THEN
      ERROR STOP "Construct_SSOR_Precond: CSR matrix not allocated"
    END IF
    IF (A_csr%nrows /= A_csr%ncols) THEN
      ERROR STOP "Construct_SSOR_Precond: Square matrix required"
    END IF

    n = A_csr%nrows
    nnz = A_csr%row_ptr(n + 1) - A_csr%row_ptr(1)
    IF (nnz < 1) THEN
      ERROR STOP "Construct_SSOR_Precond: empty CSR pattern"
    END IF
    IF (nnz > SIZE(A_csr%col_idx) .OR. nnz > SIZE(A_csr%values)) THEN
      ERROR STOP "Construct_SSOR_Precond: CSR nnz exceeds array bounds"
    END IF

    CALL Precond_Free_CSR(precond)
    IF (ALLOCATED(precond%diag)) DEALLOCATE(precond%diag)

    precond%n = n
    precond%precond_type = NM_SOLV_PREC_SSOR
    precond%ssor_omega = w

    ALLOCATE(precond%pc_row_ptr(n + 1), precond%pc_col_idx(nnz), precond%pc_mat_vals(nnz))
    precond%pc_row_ptr = A_csr%row_ptr(1:n + 1)
    precond%pc_col_idx(1:nnz) = A_csr%col_idx(1:nnz)
    precond%pc_mat_vals(1:nnz) = A_csr%values(1:nnz)
    precond%pc_nnz = INT(nnz, i8)

    precond%is_constructed = .TRUE.
  END SUBROUTINE Construct_SSOR_Precond

END MODULE NM_Solv_Precond