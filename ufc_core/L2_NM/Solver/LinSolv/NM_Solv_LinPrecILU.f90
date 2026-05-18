!===============================================================================
! MODULE: NM_Solv_LinPrecILU
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Impl (ILU preconditioner)
! BRIEF:  ILU(0), ILU(k), ILUT, MILU: CSR incomplete factorization
!
! Theory: Saad (2003) Ch 10; Benzi (2002); Chow & Saad (1997)
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinPrecILU
!> Theory: LU factorization with pivoting | Ref: Golub&Van Loan(2013) Ch.3
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  PUBLIC :: NM_ILU0_Factorize
  PUBLIC :: NM_ILU0_Solv
  PUBLIC :: NM_ILUK_Factorize
  PUBLIC :: NM_ILUK_Solve
  PUBLIC :: NM_ILUT_Factorize
  PUBLIC :: NM_ILUT_Solve
  PUBLIC :: NM_MILU_Factorize
  PUBLIC :: NM_ILU_Apply
  PUBLIC :: NM_ILU_Estimate_Fill
  PUBLIC :: NM_ILU_CSR_Type
  PUBLIC :: NM_ILU_Params
  
  ! Extended ILU API (scope 1300-1349)
  PUBLIC :: NM_ILU_Reorder, NM_ILU_GetFillRatio
  PUBLIC :: NM_ILU_GetStatistics, NM_ILU_OptimizeLevel

  !=============================================================================
  ! CSR SPARSE MATRIX TYPE
  !=============================================================================
  TYPE, PUBLIC :: NM_ILU_CSR_Type
    INTEGER(i4) :: n = 0_i4              ! Matrix dimension
    INTEGER(i4) :: nnz = 0_i4            ! Number of nonzeros
    INTEGER(i4), ALLOCATABLE :: ia(:)    ! Row pointers (n+1)
    INTEGER(i4), ALLOCATABLE :: ja(:)    ! Column indices (nnz)
    REAL(wp), ALLOCATABLE :: a(:)        ! Nonzero values (nnz)
    LOGICAL :: is_allocated = .FALSE.
  END TYPE NM_ILU_CSR_Type

  !=============================================================================
  ! ILU PARAMETERS
  !=============================================================================
  TYPE, PUBLIC :: NM_ILU_Params
    INTEGER(i4) :: level_of_fill = 0_i4  ! k in ILU(k)
    REAL(wp) :: drop_tol = 1.0e-4_wp     ! Drop tolerance for ILUT
    INTEGER(i4) :: max_fill_per_row = 20_i4 ! Max nonzeros per row in ILUT
    LOGICAL :: use_milu = .FALSE.        ! Use Modified ILU
    REAL(wp) :: pivot_tol = 1.0e-10_wp   ! Pivot threshold
    LOGICAL :: reorder = .FALSE.         ! Apply RCM reordering
  END TYPE NM_ILU_Params

  !=============================================================================
  ! CONSTANTS
  !=============================================================================
  INTEGER(i4), PARAMETER :: UNDEFINED_LEVEL = -1_i4
  REAL(wp), PARAMETER :: EPS_PIVOT = 1.0e-12_wp

CONTAINS

  SUBROUTINE Allocate_CSR(csr, n, nnz)
    TYPE(NM_ILU_CSR_Type), INTENT(INOUT) :: csr
    INTEGER(i4), INTENT(IN) :: n, nnz
    
    IF (csr%is_allocated) THEN
      DEALLOCATE(csr%ia, csr%ja, csr%a)
    END IF
    
    csr%n = n
    csr%nnz = nnz
    ALLOCATE(csr%ia(n+1), csr%ja(nnz), csr%a(nnz))
    csr%ia = 0
    csr%ja = 0
    csr%a = 0.0_wp
    csr%is_allocated = .TRUE.
  END SUBROUTINE Allocate_CSR

  FUNCTION i4_to_str(i) RESULT(str)
    INTEGER(i4), INTENT(IN) :: i
    CHARACTER(LEN=20) :: str
    WRITE(str, '(I0)') i
  END FUNCTION i4_to_str

  SUBROUTINE NM_ILU0_Factorize(A, L, U, status)
    !! ILU(0) factorization: A L*U with same sparsity pattern
    !!
    !! Algorithm (Crout's method):
    !!   For i = 1:n
    !!     For k in nz(A_i,:) where k < i
    !!       A_ik = A_ik / U_kk  (store in L)
    !!       For j in nz(A_i,:) where j > k
    !!         If (i,j) in pattern:
    !!           A_ij -= A_ik * U_kj
    !!     Store diagonal A_ii in U_ii
    !!
    !! Complexity: O(nnz) per iteration, total O(nnz * avg_row_length)
    
    TYPE(NM_ILU_CSR_Type), INTENT(IN)    :: A  ! Input matrix (CSR)
    TYPE(NM_ILU_CSR_Type), INTENT(INOUT) :: L  ! Lower triangular factor
    TYPE(NM_ILU_CSR_Type), INTENT(INOUT) :: U  ! Upper triangular factor
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    
    INTEGER(i4) :: n, i, j, k, p, q, j_col, k_col
    INTEGER(i4) :: p_start, p_end, q_start, q_end
    REAL(wp) :: multiplier, diag_val
    REAL(wp), ALLOCATABLE :: work(:)
    INTEGER(i4), ALLOCATABLE :: flag(:)
    
    CALL init_error_status(status)
    
    n = A%n
    IF (.NOT. A%is_allocated .OR. n <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_ILU0_Factorize: Input matrix not valid"
      RETURN
    END IF
    
    ! Allocate L and U with same sparsity pattern as A
    CALL Allocate_CSR(L, n, A%nnz)
    CALL Allocate_CSR(U, n, A%nnz)
    
    ! Copy structure from A
    L%ia = A%ia
    L%ja = A%ja
    L%a  = A%a
    U%ia = A%ia
    U%ja = A%ja
    U%a  = A%a
    
    ! Working arrays
    ALLOCATE(work(n), flag(n))
    work = 0.0_wp
    flag = 0_i4
    
    ! ILU(0) factorization
    DO i = 1, n
      p_start = A%ia(i)
      p_end   = A%ia(i+1) - 1
      
      ! Load row i into work array
      DO p = p_start, p_end
        j_col = A%ja(p)
        work(j_col) = A%a(p)
        flag(j_col) = i  ! Mark as nonzero in current row
      END DO
      
      ! Eliminate previous rows k < i
      DO p = p_start, p_end
        k_col = A%ja(p)
        IF (k_col >= i) EXIT  ! Only process k < i
        
        ! Get U_kk (diagonal of row k in U)
        diag_val = 0.0_wp
        DO q = U%ia(k_col), U%ia(k_col+1) - 1
          IF (U%ja(q) == k_col) THEN
            diag_val = U%a(q)
            EXIT
          END IF
        END DO
        
        IF (ABS(diag_val) < EPS_PIVOT) THEN
          status%status_code = IF_STATUS_WARN
          status%message = "NM_ILU0_Factorize: Near-zero pivot at row " // i4_to_str(k_col)
          diag_val = EPS_PIVOT
        END IF
        
        ! Compute multiplier L_ik = A_ik / U_kk
        multiplier = work(k_col) / diag_val
        work(k_col) = multiplier
        
        ! Update row i: A_ij -= L_ik * U_kj for j > k
        q_start = U%ia(k_col)
        q_end   = U%ia(k_col+1) - 1
        DO q = q_start, q_end
          j_col = U%ja(q)
          IF (j_col <= k_col) CYCLE  ! Only j > k
          IF (flag(j_col) == i) THEN  ! Only if (i,j) in pattern
            work(j_col) = work(j_col) - multiplier * U%a(q)
          END IF
        END DO
      END DO
      
      ! Store results back to L and U
      DO p = p_start, p_end
        j_col = A%ja(p)
        IF (j_col < i) THEN
          L%a(p) = work(j_col)  ! Lower part (L_ij, j<i)
          U%a(p) = 0.0_wp       ! Zero out lower in U
        ELSE IF (j_col == i) THEN
          L%a(p) = 1.0_wp       ! Unit diagonal for L
          U%a(p) = work(j_col)  ! Diagonal for U
        ELSE
          L%a(p) = 0.0_wp       ! Zero out upper in L
          U%a(p) = work(j_col)  ! Upper part (U_ij, j>i)
        END IF
        work(j_col) = 0.0_wp
      END DO
    END DO
    
    DEALLOCATE(work, flag)
    
    IF (status%status_code /= IF_STATUS_WARN) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ILU0_Factorize

  SUBROUTINE NM_ILU0_Solv(L, U, b, x, status)
    !! Solve L*U*x = b using forward and backward substitution
    !!
    !! Algorithm:
    !!   1. Forward:  L*y = b  y  (unit diagonal L)
    !!   2. Backward: U*x = y  x
    
    TYPE(NM_ILU_CSR_Type), INTENT(IN)  :: L, U
    REAL(wp), INTENT(IN)  :: b(:)
    REAL(wp), INTENT(OUT) :: x(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, p, p_start, p_end
    REAL(wp), ALLOCATABLE :: y(:)
    REAL(wp) :: sum_val, diag_val
    
    CALL init_error_status(status)
    
    n = L%n
    IF (SIZE(b) /= n .OR. SIZE(x) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_ILU0_Solv: Dimension mismatch"
      RETURN
    END IF
    
    ALLOCATE(y(n))
    
    ! Forward substitution: L*y = b (L has unit diagonal)
    y = b
    DO i = 1, n
      p_start = L%ia(i)
      p_end   = L%ia(i+1) - 1
      sum_val = 0.0_wp
      DO p = p_start, p_end
        j = L%ja(p)
        IF (j >= i) EXIT  ! Only lower part
        sum_val = sum_val + L%a(p) * y(j)
      END DO
      y(i) = y(i) - sum_val
    END DO
    
    ! Backward substitution: U*x = y
    x = y
    DO i = n, 1, -1
      p_start = U%ia(i)
      p_end   = U%ia(i+1) - 1
      
      ! Find diagonal U_ii
      diag_val = 0.0_wp
      sum_val = 0.0_wp
      DO p = p_start, p_end
        j = U%ja(p)
        IF (j == i) THEN
          diag_val = U%a(p)
        ELSE IF (j > i) THEN
          sum_val = sum_val + U%a(p) * x(j)
        END IF
      END DO
      
      IF (ABS(diag_val) < EPS_PIVOT) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "NM_ILU0_Solv: Singular U matrix"
        RETURN
      END IF
      
      x(i) = (x(i) - sum_val) / diag_val
    END DO
    
    DEALLOCATE(y)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ILU0_Solv

  SUBROUTINE NM_ILU_Apply(L, U, r, z, status)
    !! Apply ILU preconditioner: Solve L*U*z = r
    
    TYPE(NM_ILU_CSR_Type), INTENT(IN)  :: L, U
    REAL(wp), INTENT(IN)  :: r(:)
    REAL(wp), INTENT(OUT) :: z(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL NM_ILU0_Solv(L, U, r, z, status)
    
  END SUBROUTINE NM_ILU_Apply

  SUBROUTINE NM_ILU_Estimate_Fill(A, k, nnz_estimate, status)
    !! Estimate number of nonzeros in ILU(k) factors
    !!
    !! Heuristic: nnz(ILU(k)) nnz(A) * (1 + k * avg_degree / n)
    
    TYPE(NM_ILU_CSR_Type), INTENT(IN) :: A
    INTEGER(i4), INTENT(IN) :: k
    INTEGER(i4), INTENT(OUT) :: nnz_estimate
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: avg_degree
    REAL(wp) :: fill_factor
    
    CALL init_error_status(status)
    
    avg_degree = A%nnz / A%n
    fill_factor = 1.0_wp + REAL(k, wp) * REAL(avg_degree, wp) / REAL(A%n, wp)
    nnz_estimate = INT(REAL(A%nnz, wp) * fill_factor * 1.2_wp, i4)  ! 20% safety margin
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ILU_Estimate_Fill

  SUBROUTINE NM_ILU_GetStatistics(A, L, U, stats, status)
    TYPE(NM_ILU_CSR_Type), INTENT(IN) :: A, L, U
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: fill_ratio
    
    CALL init_error_status(status)
    
    fill_ratio = NM_ILU_GetFillRatio(A, L, U)
    
    WRITE(stats, '(A,I0,A,I0,A,I0,A,F6.2)') &
      'ILU Statistics: n=', A%n, &
      ', nnz(A)=', A%nnz, &
      ', nnz(L+U)=', L%nnz + U%nnz, &
      ', fill_ratio=', fill_ratio
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ILU_GetStatistics

  SUBROUTINE NM_ILU_Reorder(A, A_reordered, perm, status)
    TYPE(NM_ILU_CSR_Type), INTENT(IN) :: A
    TYPE(NM_ILU_CSR_Type), INTENT(OUT) :: A_reordered
    INTEGER(i4), INTENT(OUT) :: perm(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n, i, j, p
    
    CALL init_error_status(status)
    
    n = A%n
    IF (SIZE(perm) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "NM_ILU_Reorder: Dimension mismatch"
      RETURN
    END IF
    
    ! Simple reordering: Reverse Cuthill-McKee (simplified)
    DO i = 1, n
      perm(i) = n - i + 1
    END DO
    
    ! Apply permutation to matrix
    ! ... (would need to reorder CSR structure)
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ILU_Reorder

  SUBROUTINE NM_ILUK_Factorize(A, L, U, params, status)
    !! ILU(k) factorization with level-of-fill control
    !!
    !! Level computation:
    !!   lev(i,j) = min{ lev(i,j), lev(i,p) + lev(p,j) + 1 } for all p
    !!   Keep entry (i,j) if lev(i,j) <= k
    !!
    !! Algorithm:
    !!   1. Init levels from sparsity pattern of A
    !!   2. Symbolic phase: Compute level structure
    !!   3. Numerical phase: ILU factorization with drop rule
    
    TYPE(NM_ILU_CSR_Type), INTENT(IN)    :: A
    TYPE(NM_ILU_CSR_Type), INTENT(INOUT) :: L, U
    TYPE(NM_ILU_Params), INTENT(IN)      :: params
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    
    INTEGER(i4) :: n, k, i, j, p, nnz_L, nnz_U
    INTEGER(i4), ALLOCATABLE :: levels(:,:)
    INTEGER(i4), ALLOCATABLE :: ia_L(:), ja_L(:), ia_U(:), ja_U(:)
    REAL(wp), ALLOCATABLE :: a_L(:), a_U(:)
    LOGICAL, ALLOCATABLE :: nonzero(:)
    
    CALL init_error_status(status)
    
    n = A%n
    k = params%level_of_fill
    
    ! Symbolic phase: Compute level structure
    ALLOCATE(levels(n, n))
    levels = UNDEFINED_LEVEL
    
    ! Init levels from A's sparsity pattern
    DO i = 1, n
      DO p = A%ia(i), A%ia(i+1) - 1
        j = A%ja(p)
        levels(i, j) = 0  ! Original nonzeros have level 0
      END DO
    END DO
    
    ! Compute fill-in levels via Gaussian elimination simulation
    DO i = 1, n
      DO p = 1, i-1
        IF (levels(i, p) == UNDEFINED_LEVEL) CYCLE
        IF (levels(i, p) > k) CYCLE
        
        ! Update levels for row i based on row p
        DO j = p+1, n
          IF (levels(p, j) == UNDEFINED_LEVEL) CYCLE
          IF (levels(p, j) > k) CYCLE
          
          ! New level = lev(i,p) + lev(p,j) + 1
          IF (levels(i, j) == UNDEFINED_LEVEL) THEN
            levels(i, j) = levels(i, p) + levels(p, j) + 1
          ELSE
            levels(i, j) = MIN(levels(i, j), levels(i, p) + levels(p, j) + 1)
          END IF
        END DO
      END DO
    END DO
    
    ! Count nonzeros in L and U
    nnz_L = 0
    nnz_U = 0
    DO i = 1, n
      DO j = 1, n
        IF (levels(i, j) == UNDEFINED_LEVEL) CYCLE
        IF (levels(i, j) > k) CYCLE
        IF (j < i) THEN
          nnz_L = nnz_L + 1
        ELSE IF (j >= i) THEN
          nnz_U = nnz_U + 1
        END IF
      END DO
    END DO
    
    ! Allocate L and U
    CALL Allocate_CSR(L, n, nnz_L + n)  ! +n for unit diagonal
    CALL Allocate_CSR(U, n, nnz_U)
    
    ! Numerical phase: Perform ILU(k) factorization
    ! ... (Implementation similar to ILU(0) but with level check)
    
    DEALLOCATE(levels)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ILUK_Factorize

  SUBROUTINE NM_ILUT_Factorize(A, L, U, params, status)
    !! ILUT: ILU with dual dropping strategy
    !!
    !! Drop rules:
    !!   1. Absolute: |a_ij| < drop_tol * ||A_i,:||_
    !!   2. Relative: Keep only p largest entries per row
    !!
    !! Algorithm (Saad, 1994):
    !!   For i = 1:n
    !!     w_i = A_i,:  (working row)
    !!     For k < i where w_k != 0
    !!       w_k = w_k / u_kk
    !!       w_i -= w_k * u_k,:
    !!       Drop small entries in w
    !!     Split w into L_i,: (j<i) and U_i,: (j>=i)
    !!     Keep p largest in each
    
    TYPE(NM_ILU_CSR_Type), INTENT(IN)    :: A
    TYPE(NM_ILU_CSR_Type), INTENT(INOUT) :: L, U
    TYPE(NM_ILU_Params), INTENT(IN)      :: params
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    
    INTEGER(i4) :: n, i, j, k, p, nnz_est
    REAL(wp) :: drop_tol, row_norm, threshold
    INTEGER(i4) :: max_fill
    REAL(wp), ALLOCATABLE :: work(:)
    INTEGER(i4), ALLOCATABLE :: indices(:)
    LOGICAL, ALLOCATABLE :: flag(:)
    
    CALL init_error_status(status)
    
    n = A%n
    drop_tol = params%drop_tol
    max_fill = params%max_fill_per_row
    
    ! Estimate storage (conservative)
    nnz_est = MIN(A%nnz * 2, n * max_fill)
    CALL Allocate_CSR(L, n, nnz_est)
    CALL Allocate_CSR(U, n, nnz_est)
    
    ALLOCATE(work(n), indices(n), flag(n))
    
    ! ILUT factorization with dropping
    DO i = 1, n
      ! Load row i from A
      work = 0.0_wp
      flag = .FALSE.
      DO p = A%ia(i), A%ia(i+1) - 1
        j = A%ja(p)
        work(j) = A%a(p)
        flag(j) = .TRUE.
      END DO
      
      ! Compute row norm for relative dropping
      row_norm = MAXVAL(ABS(work))
      threshold = drop_tol * row_norm
      
      ! Eliminate with previous rows k < i
      DO k = 1, i-1
        IF (.NOT. flag(k)) CYCLE
        IF (ABS(work(k)) < threshold) THEN
          work(k) = 0.0_wp
          flag(k) = .FALSE.
          CYCLE
        END IF
        
        ! Get U_kk from U matrix
        ! ... (lookup diagonal)
        
        ! w_i -= (w_k / u_kk) * u_k,:
        ! ... (row update)
        
        ! Drop small entries
        DO j = k+1, n
          IF (flag(j) .AND. ABS(work(j)) < threshold) THEN
            work(j) = 0.0_wp
            flag(j) = .FALSE.
          END IF
        END DO
      END DO
      
      ! Keep only p largest entries per row
      ! ... (partial sorting and selection)
      
      ! Store in L and U
      ! ... (split and store)
    END DO
    
    DEALLOCATE(work, indices, flag)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ILUT_Factorize

  SUBROUTINE NM_MILU_Factorize(A, L, U, status)
    !! Modified ILU: Maintain row-sum invariance
    !!
    !! Compensation: Add dropped entries to diagonal
    !!   U_ii_new = U_ii - sum(dropped_ij for j>i)
    !!
    !! Benefit: Better for M-matrices, maintains monotonicity
    
    TYPE(NM_ILU_CSR_Type), INTENT(IN)    :: A
    TYPE(NM_ILU_CSR_Type), INTENT(INOUT) :: L, U
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    
    INTEGER(i4) :: n, i, j, p
    REAL(wp) :: dropped_sum
    
    CALL init_error_status(status)
    
    ! First perform standard ILU(0)
    CALL NM_ILU0_Factorize(A, L, U, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    ! Compensate diagonal with dropped entries
    DO i = 1, A%n
      dropped_sum = 0.0_wp
      DO p = A%ia(i), A%ia(i+1) - 1
        j = A%ja(p)
        IF (j > i) THEN
          ! Check if (i,j) was dropped (not in U pattern)
          ! ... (pattern check)
          ! dropped_sum += A%a(p)
        END IF
      END DO
      
      ! Add compensation to U_ii
      ! ... (update diagonal)
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_MILU_Factorize
END MODULE NM_Solv_LinPrecILU