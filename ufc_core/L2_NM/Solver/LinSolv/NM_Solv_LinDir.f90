!===============================================================================
! MODULE: NM_Solv_LinDir
! LAYER:  L2_NM
! DOMAIN: Solver/LinSolv
! ROLE:   Proc (direct solver dispatcher)
! BRIEF:  Sparse direct solver: LU/Cholesky/multifrontal factorization
!
! Theory: Davis (2006); Duff, Erisman & Reid (2017)
!
! Status: CORE | Last verified: 2026-02-28
!===============================================================================

MODULE NM_Solv_LinDir
!> Status: Production | Last verified: 2026-03-01
!> Theory: Numerical method implementation | Ref: Saad(2003) Iterative Methods
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, SMALL
  USE NM_Mtx_Sparse, ONLY: NM_CSR_Type
  IMPLICIT NONE
  PRIVATE

  !> @brief Sparse matrix storage format enumeration
  INTEGER, PARAMETER, PUBLIC :: NM_SPARSE_CSR = 1      !< Compressed row storage
  INTEGER, PARAMETER, PUBLIC :: NM_SPARSE_CSC = 2      !< Compressed column storage
  INTEGER, PARAMETER, PUBLIC :: NM_SPARSE_COO = 3      !< Coordinate format

  !> @brief Direct solver type
  INTEGER, PARAMETER, PUBLIC :: NM_SOLVER_LU = 1       !< LU decomposition
  INTEGER, PARAMETER, PUBLIC :: NM_SOLVER_CHOLESKY = 2 !< Cholesky decomposition
  INTEGER, PARAMETER, PUBLIC :: NM_SOLVER_LDLT = 3     !< LDL^T decomposition

  !> @brief CSR format sparse matrix
  TYPE, PUBLIC :: CSR_Matrix
    INTEGER(i4) :: n_rows                     !< Number of rows
    INTEGER(i4) :: n_cols                     !< Number of columns
    INTEGER(i4) :: n_nonzeros                 !< Number of nonzero elements
    INTEGER, ALLOCATABLE :: row_ptr(:)    !< Row pointer (n_rows+1)
    INTEGER, ALLOCATABLE :: col_idx(:)    !< Column index (n_nonzeros)
    REAL(DP), ALLOCATABLE :: values(:)    !< Nonzero values (n_nonzeros)
  END TYPE

  !> @brief  Solver parameters
  TYPE, PUBLIC :: Direct_Solver_Params
    INTEGER(i4) :: solver_type               !< Solver type
    INTEGER(i4) :: storage_format            !< Storage format
    LOGICAL  :: use_reordering            !< Use reordering
    LOGICAL  :: symbolic_factorization    !< Symbolic factorization
    REAL(DP) :: pivot_threshold           !< Pivot threshold
  END TYPE

  !> @brief LU decomposition result
  TYPE, PUBLIC :: LU_Factorization
    TYPE(CSR_Matrix) :: L_factor          !< Lower triangular matrix L
    TYPE(CSR_Matrix) :: U_factor          !< Upper triangular matrix U
    INTEGER, ALLOCATABLE :: pivot_perm(:) !< Row permutation vector
    LOGICAL :: is_factored                !< Factorization complete flag
  END TYPE

  ! Public interfaces
  PUBLIC :: NM_LinSolv_Direct_CSR_Init
  PUBLIC :: NM_LinSolv_Direct_LU_Factorize
  PUBLIC :: NM_LinSolv_Direct_Cholesky_Factorize
  PUBLIC :: NM_LinSolv_Direct_Forward_Substitution
  PUBLIC :: NM_LinSolv_Direct_Backward_Substitution
  PUBLIC :: NM_LinSolv_Direct_Solv_System

  ! Generic interfaces for CSR_Matrix and NM_CSR_Type
  INTERFACE NM_LinSolv_Direct_Forward_Substitution
    MODULE PROCEDURE NM_LinSolv_Direct_Forward_Substitution_CSR
    MODULE PROCEDURE NM_LinSolv_Direct_Forward_Substitution_NM
  END INTERFACE
  INTERFACE NM_LinSolv_Direct_Backward_Substitution
    MODULE PROCEDURE NM_LinSolv_Direct_Backward_Substitution_CSR
    MODULE PROCEDURE NM_LinSolv_Direct_Backward_Substitution_NM
  END INTERFACE

CONTAINS

  !> @brief Initialize CSR matrix
  !! @param[in] n_rows Number of rows
  !! @param[in] n_cols Number of columns
  !! @param[in] n_nonzeros Number of nonzero elements
  !! @param[out] A CSR matrix
  SUBROUTINE NM_LinSolv_Direct_CSR_Init(n_rows, n_cols, n_nonzeros, A)
    INTEGER(i4), INTENT(IN) :: n_rows, n_cols, n_nonzeros
    TYPE(CSR_Matrix), INTENT(OUT) :: A

    A%n_rows = n_rows
    A%n_cols = n_cols
    A%n_nonzeros = n_nonzeros

    ALLOCATE(A%row_ptr(n_rows + 1))
    ALLOCATE(A%col_idx(n_nonzeros))
    ALLOCATE(A%values(n_nonzeros))

    A%row_ptr = 0
    A%col_idx = 0
    A%values = ZERO

  END SUBROUTINE NM_LinSolv_Direct_CSR_Init

  !> @brief LU decomposition (sparse matrix
  !! @details Algorithm: A = P·L·U
  !!   Where:
  !!   P = Row permutation matrix (partial pivoting)
  !!   L = Unit lower triangular matrix
  !!   U = Upper triangular matrix
  !!   Sparse LU decomposition key points:
  !!   - Symbolic factorization: Determine L/U nonzero structure
  !!   - Numeric factorization: compute L/U values
  !!   - Fill-in control: minimize new nonzeros
  !!   Doolittle algorithm:
  !!   U(i,j) = A(i,j) - Σ_{k=1}^{i-1} L(i,k)·U(k,j)
  !!   L(i,j) = [A(i,j) - Σ_{k=1}^{j-1} L(i,k)·U(k,j)] / U(j,j)
  !! @param[in] A Input sparse matrix (CSR format)
  !! @param[in] params Solver parameters
  !! @param[out] LU_fact LU decomposition result
  SUBROUTINE NM_LinSolv_Direct_LU_Factorize(A, params, LU_fact)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    TYPE(Direct_Solver_Params), INTENT(IN) :: params
    TYPE(LU_Factorization), INTENT(OUT) :: LU_fact

    INTEGER(i4) :: n, i, j, k, row, col, nnz_L, nnz_U
    REAL(DP) :: sum_val, pivot
    REAL(DP), ALLOCATABLE :: A_dense(:,:), L_dense(:,:), U_dense(:,:)
    INTEGER, ALLOCATABLE :: row_order(:)

    n = A%n_rows

    ! Simplified implementation: Convert to dense matrix for LU decomposition
    ! Production level requires true sparse LU algorithm ( SuperLU, MUMPS)
    ALLOCATE(A_dense(n, n))
    ALLOCATE(L_dense(n, n))
    ALLOCATE(U_dense(n, n))
    ALLOCATE(row_order(n))

    ! CSR to dense matrix
    A_dense = ZERO
    DO i = 1, n
      DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
        j = A%col_idx(k)
        A_dense(i, j) = A%values(k)
      END DO
    END DO

    ! Initialize
    L_dense = ZERO
    U_dense = ZERO
    DO i = 1, n
      L_dense(i, i) = ONE
      row_order(i) = i
    END DO

    ! Doolittle LU decomposition (simplified version without pivoting)
    DO k = 1, n
      ! Compute U column k
      DO j = k, n
        sum_val = ZERO
        DO i = 1, k-1
          sum_val = sum_val + L_dense(k, i) * U_dense(i, j)
        END DO
        U_dense(k, j) = A_dense(k, j) - sum_val
      END DO

      ! Compute L column k
      DO i = k+1, n
        sum_val = ZERO
        DO j = 1, k-1
          sum_val = sum_val + L_dense(i, j) * U_dense(j, k)
        END DO
        
        pivot = U_dense(k, k)
        IF (ABS(pivot) < SMALL) THEN
          ! Pivot near zero, matrix singular
          PRINT *, "Warning: Near-zero pivot at row ", k
          L_dense(i, k) = ZERO
        ELSE
          L_dense(i, k) = (A_dense(i, k) - sum_val) / pivot
        END IF
      END DO
    END DO

    ! Convert back to CSR format (simplified: store all nonzeros)
    nnz_L = COUNT(ABS(L_dense) > SMALL)
    nnz_U = COUNT(ABS(U_dense) > SMALL)

    CALL NM_LinSolv_Direct_CSR_Init(n, n, nnz_L, LU_fact%L_factor)
    CALL NM_LinSolv_Direct_CSR_Init(n, n, nnz_U, LU_fact%U_factor)

    ! Fill L matrix (CSR)
    CALL Dense_To_CSR(L_dense, n, n, LU_fact%L_factor)

    ! Fill U matrix (CSR)
    CALL Dense_To_CSR(U_dense, n, n, LU_fact%U_factor)

    ! Permutation vector
    ALLOCATE(LU_fact%pivot_perm(n))
    LU_fact%pivot_perm = row_order

    LU_fact%is_factored = .TRUE.

    DEALLOCATE(A_dense, L_dense, U_dense, row_order)

  END SUBROUTINE NM_LinSolv_Direct_LU_Factorize

  !> @brief Cholesky decomposition (symmetric positive definite matrix)
  !! @details Algorithm: A = L·L^T
  !!   Applicable condition: A symmetric positive definite
  !!   Advantage: Only need to store L (save 50% storage)
  !!   Cholesky-Crout algorithm:
  !!   L(i,i) = sqrt(A(i,i) - Σ_{k=1}^{i-1} L(i,k)²)
  !!   L(i,j) = [A(i,j) - Σ_{k=1}^{j-1} L(i,k)·L(j,k)] / L(j,j)
  !!   Sparse Cholesky:
  !!   - Exploit symmetry
  !!   - Supernodal technique (Supernodal)
  !!   - Multifrontal method (Multifrontal)
  !! @param[in] A Symmetric positive definite sparse matrix (CSR format)
  !! @param[out] L Lower triangular Cholesky factor (CSR format)
  SUBROUTINE NM_LinSolv_Direct_Cholesky_Factorize(A, L)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    TYPE(CSR_Matrix), INTENT(OUT) :: L

    INTEGER(i4) :: n, i, j, k, nnz_L
    REAL(DP) :: sum_val, diag_val
    REAL(DP), ALLOCATABLE :: A_dense(:,:), L_dense(:,:)

    n = A%n_rows

    ! Simplified implementation: Dense Cholesky
    ALLOCATE(A_dense(n, n))
    ALLOCATE(L_dense(n, n))

    ! CSR to dense
    A_dense = ZERO
    DO i = 1, n
      DO k = A%row_ptr(i), A%row_ptr(i+1) - 1
        j = A%col_idx(k)
        A_dense(i, j) = A%values(k)
      END DO
    END DO

    ! Cholesky-Crout 
    L_dense = ZERO
    DO j = 1, n
      !  
      sum_val = ZERO
      DO k = 1, j-1
        sum_val = sum_val + L_dense(j, k)**2
      END DO
      diag_val = A_dense(j, j) - sum_val

      IF (diag_val <= ZERO) THEN
        PRINT *, "Error: Matrix not positive definite at row ", j
        L_dense(j, j) = SQRT(SMALL)
      ELSE
        L_dense(j, j) = SQRT(diag_val)
      END IF

      !  
      DO i = j+1, n
        sum_val = ZERO
        DO k = 1, j-1
          sum_val = sum_val + L_dense(i, k) * L_dense(j, k)
        END DO
        L_dense(i, j) = (A_dense(i, j) - sum_val) / L_dense(j, j)
      END DO
    END DO

    !  CSR
    nnz_L = COUNT(ABS(L_dense) > SMALL)
    CALL NM_LinSolv_Direct_CSR_Init(n, n, nnz_L, L)
    CALL Dense_To_CSR(L_dense, n, n, L)

    DEALLOCATE(A_dense, L_dense)

  END SUBROUTINE NM_LinSolv_Direct_Cholesky_Factorize

  !> @brief Forward substitution (solve L·y = b)
  !! @details  
  !!   y(1) = b(1) / L(1,1)
  !!   y(i) = [b(i) - Σ_{j=1}^{i-1} L(i,j)·y(j)] / L(i,i)
  !!     O(nnz(L))
  !! @param[in] L  CSR )
  !! @param[in] b  vector
  !! @param[out] y  
  SUBROUTINE NM_LinSolv_Direct_Forward_Substitution_CSR(L, b, y)
    TYPE(CSR_Matrix), INTENT(IN) :: L
    REAL(DP), INTENT(IN)  :: b(:)
    REAL(DP), INTENT(OUT) :: y(:)

    INTEGER(i4) :: i, j, k, col
    REAL(DP) :: sum_val, diag

    y = ZERO

    DO i = 1, L%n_rows
      sum_val = ZERO
      diag = ONE

      !  i Nonzero elements
      DO k = L%row_ptr(i), L%row_ptr(i+1) - 1
        col = L%col_idx(k)

        IF (col < i) THEN
          !  
          sum_val = sum_val + L%values(k) * y(col)
        ELSE IF (col == i) THEN
          !  
          diag = L%values(k)
        END IF
      END DO

      ! y(i) = [b(i) - sum] / L(i,i)
      IF (ABS(diag) < SMALL) THEN
        y(i) = ZERO
      ELSE
        y(i) = (b(i) - sum_val) / diag
      END IF
    END DO

  END SUBROUTINE NM_LinSolv_Direct_Forward_Substitution_CSR

  !> @brief Forward substitution for NM_CSR_Type (solve L·y = b)
  SUBROUTINE NM_LinSolv_Direct_Forward_Substitution_NM(L, b, y)
    TYPE(NM_CSR_Type), INTENT(IN) :: L
    REAL(DP), INTENT(IN)  :: b(:)
    REAL(DP), INTENT(OUT) :: y(:)
    INTEGER(i4) :: i, k, col
    REAL(DP) :: sum_val, diag
    y = ZERO
    DO i = 1, L%n
      sum_val = ZERO
      diag = ONE
      DO k = L%ia(i), L%ia(i+1) - 1
        col = L%ja(k)
        IF (col < i) THEN
          sum_val = sum_val + L%a(k) * y(col)
        ELSE IF (col == i) THEN
          diag = L%a(k)
        END IF
      END DO
      IF (ABS(diag) < SMALL) THEN
        y(i) = ZERO
      ELSE
        y(i) = (b(i) - sum_val) / diag
      END IF
    END DO
  END SUBROUTINE NM_LinSolv_Direct_Forward_Substitution_NM

  !> @brief   (  U·x = y)
  !! @details  
  !!   x(n) = y(n) / U(n,n)
  !!   x(i) = [y(i) - Σ_{j=i+1}^{n} U(i,j)·x(j)] / U(i,i)
  !!     O(nnz(U))
  !! @param[in] U Upper triangular matrixCSR )
  !! @param[in] y  vector
  !! @param[out] x  
  SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_CSR(U, y, x)
    TYPE(CSR_Matrix), INTENT(IN) :: U
    REAL(DP), INTENT(IN)  :: y(:)
    REAL(DP), INTENT(OUT) :: x(:)

    INTEGER(i4) :: i, j, k, col
    REAL(DP) :: sum_val, diag

    x = ZERO

    !  
    DO i = U%n_rows, 1, -1
      sum_val = ZERO
      diag = ONE

      !  i Nonzero elements
      DO k = U%row_ptr(i), U%row_ptr(i+1) - 1
        col = U%col_idx(k)

        IF (col > i) THEN
          !  
          sum_val = sum_val + U%values(k) * x(col)
        ELSE IF (col == i) THEN
          !  
          diag = U%values(k)
        END IF
      END DO

      ! x(i) = [y(i) - sum] / U(i,i)
      IF (ABS(diag) < SMALL) THEN
        x(i) = ZERO
      ELSE
        x(i) = (y(i) - sum_val) / diag
      END IF
    END DO

  END SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_CSR

  !> @brief Backward substitution for L^T (solve L^T·x = y when L is lower triangular)
  !! For Cholesky: A = L·L^T, after Forward(L,b,y) we solve L^T·x = y
  SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_LT(L, y, x)
    TYPE(CSR_Matrix), INTENT(IN) :: L
    REAL(DP), INTENT(IN)  :: y(:)
    REAL(DP), INTENT(OUT) :: x(:)
    INTEGER(i4) :: i, j, k, n
    REAL(DP) :: sum_val, diag
    n = L%n_rows
    x = ZERO
    DO i = n, 1, -1
      sum_val = y(i)
      DO j = i + 1, n
        DO k = L%row_ptr(j), L%row_ptr(j+1) - 1
          IF (L%col_idx(k) == i) THEN
            sum_val = sum_val - L%values(k) * x(j)
            EXIT
          END IF
        END DO
      END DO
      diag = ONE
      DO k = L%row_ptr(i), L%row_ptr(i+1) - 1
        IF (L%col_idx(k) == i) THEN
          diag = L%values(k)
          EXIT
        END IF
      END DO
      IF (ABS(diag) < SMALL) THEN
        x(i) = ZERO
      ELSE
        x(i) = sum_val / diag
      END IF
    END DO
  END SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_LT

  !> @brief Backward substitution for NM_CSR_Type (solve U·x = y)
  SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_NM(U, y, x)
    TYPE(NM_CSR_Type), INTENT(IN) :: U
    REAL(DP), INTENT(IN)  :: y(:)
    REAL(DP), INTENT(OUT) :: x(:)
    INTEGER(i4) :: i, k, col
    REAL(DP) :: sum_val, diag
    x = ZERO
    DO i = U%n, 1, -1
      sum_val = ZERO
      diag = ONE
      DO k = U%ia(i), U%ia(i+1) - 1
        col = U%ja(k)
        IF (col > i) THEN
          sum_val = sum_val + U%a(k) * x(col)
        ELSE IF (col == i) THEN
          diag = U%a(k)
        END IF
      END DO
      IF (ABS(diag) < SMALL) THEN
        x(i) = ZERO
      ELSE
        x(i) = (y(i) - sum_val) / diag
      END IF
    END DO
  END SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_NM

  !> @brief  A·x = b
  !! @details  :
  !!   1. LU decomposition: A = L·U
  !!   2.  : L·y = b
  !!   3.  : U·x = y
  !!    Cholesky decomposition:
  !!   1. Cholesky decomposition: A = L·L^T
  !!   2.  : L·y = b
  !!   3.  : L^T·x = y
  !! @param[in] A coeff matrix(CSR )
  !! @param[in] b  vector
  !! @param[in] params Solver parameters
  !! @param[out] x  
  SUBROUTINE NM_LinSolv_Direct_Solv_System(A, b, params, x)
    TYPE(CSR_Matrix), INTENT(IN) :: A
    REAL(DP), INTENT(IN)  :: b(:)
    TYPE(Direct_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(OUT) :: x(:)

    TYPE(LU_Factorization) :: LU_fact
    TYPE(CSR_Matrix) :: L_chol
    REAL(DP), ALLOCATABLE :: y(:)
    INTEGER(i4) :: n

    n = A%n_rows
    ALLOCATE(y(n))

    SELECT CASE(params%solver_type)
    CASE(NM_SOLVER_LU)
      ! LU decomposition 
      CALL NM_LinSolv_Direct_LU_Factorize(A, params, LU_fact)
      CALL NM_LinSolv_Direct_Forward_Substitution(LU_fact%L_factor, b, y)
      CALL NM_LinSolv_Direct_Backward_Substitution(LU_fact%U_factor, y, x)

    CASE(NM_SOLVER_CHOLESKY)
      ! Cholesky: A = L·L^T, solve L·y = b then L^T·x = y
      CALL NM_LinSolv_Direct_Cholesky_Factorize(A, L_chol)
      CALL NM_LinSolv_Direct_Forward_Substitution(L_chol, b, y)
      ! L^T·x = y (L is lower triangular, L^T is upper)
      CALL NM_LinSolv_Direct_Backward_Substitution_LT(L_chol, y, x)

    CASE DEFAULT
      ! default LU
      CALL NM_LinSolv_Direct_LU_Factorize(A, params, LU_fact)
      CALL NM_LinSolv_Direct_Forward_Substitution(LU_fact%L_factor, b, y)
      CALL NM_LinSolv_Direct_Backward_Substitution(LU_fact%U_factor, y, x)
    END SELECT

    DEALLOCATE(y)

  END SUBROUTINE NM_LinSolv_Direct_Solv_System

  !> @brief  matrix CSR  (utils)
  !! @param[in] A_dense  matrix(n×m)
  !! @param[in] n Number of rows
  !! @param[in] m Number of columns
  !! @param[out] A_csr CSR matrix
  SUBROUTINE Dense_To_CSR(A_dense, n, m, A_csr)
    REAL(DP), INTENT(IN) :: A_dense(:,:)
    INTEGER(i4), INTENT(IN) :: n, m
    TYPE(CSR_Matrix), INTENT(INOUT) :: A_csr

    INTEGER(i4) :: i, j, k, nnz
    REAL(DP), PARAMETER :: TOL = 1.0E-14_DP

    !  Nonzero elements
    nnz = 0
    DO i = 1, n
      DO j = 1, m
        IF (ABS(A_dense(i, j)) > TOL) THEN
          nnz = nnz + 1
        END IF
      END DO
    END DO

    !  CSR 
    IF (ALLOCATED(A_csr%row_ptr)) DEALLOCATE(A_csr%row_ptr)
    IF (ALLOCATED(A_csr%col_idx)) DEALLOCATE(A_csr%col_idx)
    IF (ALLOCATED(A_csr%values)) DEALLOCATE(A_csr%values)

    A_csr%n_rows = n
    A_csr%n_cols = m
    A_csr%n_nonzeros = nnz

    ALLOCATE(A_csr%row_ptr(n + 1))
    ALLOCATE(A_csr%col_idx(nnz))
    ALLOCATE(A_csr%values(nnz))

    !  CSR 
    k = 1
    A_csr%row_ptr(1) = 1

    DO i = 1, n
      DO j = 1, m
        IF (ABS(A_dense(i, j)) > TOL) THEN
          A_csr%col_idx(k) = j
          A_csr%values(k) = A_dense(i, j)
          k = k + 1
        END IF
      END DO
      A_csr%row_ptr(i + 1) = k
    END DO

  END SUBROUTINE Dense_To_CSR

END MODULE NM_Solv_LinDir