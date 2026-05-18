!===============================================================================
! MODULE: NM_LAPACK_Brg
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Brg — Fortran 90+ wrappers for LAPACK routines (DGESV/DGETRF/DGETRI)
! BRIEF:  LAPACK bridge with modern error handling and workspace management
!===============================================================================

MODULE NM_LAPACK_Brg
!> [CORE] LAPACK wrappers with Fortran 90+ style error handling
!> Theory: LAPACK 3.x interface wrappers bridging ModuleLapack
!> Status: Production (DGESV/DGETRF/DGETRI) | Partial STUB (DSYEV/DGESVD) | Last verified: 2026-03-01
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE ModuleLapack, ONLY: DGESV, DGETRF, DGETRI
  
  IMPLICIT NONE
  PRIVATE
  
  ! ==========================================================================
  ! PUBLIC STRUCTURED INTERFACE TYPES
  ! ==========================================================================
  
  !> @brief Input for symmetric eigenvalue solve (DSYEV)
  TYPE, PUBLIC :: NM_LAPACK_EigenSolve_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Symmetric matrix A (n×n)
    LOGICAL :: compute_vectors = .TRUE.     !< Compute eigenvectors (V) or eigenvalues only (N)
    CHARACTER(LEN=1) :: uplo = 'U'          !< Upper ('U') or lower ('L') triangle stored
  END TYPE NM_LAPACK_EigenSolve_In
  
  !> @brief Output for symmetric eigenvalue solve
  TYPE, PUBLIC :: NM_LAPACK_EigenSolve_Out
    REAL(wp), ALLOCATABLE :: eigenvalues(:)    !< Eigenvalues in ascending order
    REAL(wp), ALLOCATABLE :: eigenvectors(:,:) !< Eigenvectors (n×n), column-wise
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_EigenSolve_Out
  
  !> @brief Input for SVD (DGESVD)
  TYPE, PUBLIC :: NM_LAPACK_SVD_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Input matrix A (m×n)
    CHARACTER(LEN=1) :: jobu = 'A'          !< 'A'=all U, 'S'=min(m,n) cols, 'O'=overwrite, 'N'=none
    CHARACTER(LEN=1) :: jobvt = 'A'         !< Same options for V^T
  END TYPE NM_LAPACK_SVD_In
  
  !> @brief Output for SVD
  TYPE, PUBLIC :: NM_LAPACK_SVD_Out
    REAL(wp), ALLOCATABLE :: U(:,:)         !< Left singular vectors (m×m or m×min(m,n))
    REAL(wp), ALLOCATABLE :: Sigma(:)       !< Singular values in descending order
    REAL(wp), ALLOCATABLE :: VT(:,:)        !< Right singular vectors transposed (n×n or min(m,n)×n)
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_SVD_Out
  
  !> @brief Input for LU factorization (DGETRF)
  TYPE, PUBLIC :: NM_LAPACK_LUFactor_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Input matrix A (m×n)
  END TYPE NM_LAPACK_LUFactor_In
  
  !> @brief Output for LU factorization
  TYPE, PUBLIC :: NM_LAPACK_LUFactor_Out
    REAL(wp), ALLOCATABLE :: LU(:,:)        !< L and U stored together (m×n)
    INTEGER(i4), ALLOCATABLE :: pivot(:)    !< Pivot indices (min(m,n))
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_LUFactor_Out
  
  !> @brief Input for matrix inverse (DGETRI)
  TYPE, PUBLIC :: NM_LAPACK_Inverse_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Input matrix A (n×n)
  END TYPE NM_LAPACK_Inverse_In
  
  !> @brief Output for matrix inverse
  TYPE, PUBLIC :: NM_LAPACK_Inverse_Out
    REAL(wp), ALLOCATABLE :: inverse(:,:)   !< Inverse matrix A^{-1} (n×n)
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_Inverse_Out
  
  !> @brief Input for linear system solve (DGESV)
  TYPE, PUBLIC :: NM_LAPACK_LinearSolve_In
    REAL(wp), ALLOCATABLE :: matrix(:,:)    !< Coefficient matrix A (n×n)
    REAL(wp), ALLOCATABLE :: rhs(:,:)       !< Right-hand side B (n×nrhs)
    LOGICAL :: preserve_inputs = .FALSE.    !< Preserve A and B (make internal copies)
  END TYPE NM_LAPACK_LinearSolve_In
  
  !> @brief Output for linear system solve
  TYPE, PUBLIC :: NM_LAPACK_LinearSolve_Out
    REAL(wp), ALLOCATABLE :: solution(:,:)  !< Solution X (n×nrhs)
    INTEGER(i4), ALLOCATABLE :: pivot(:)    !< Pivot indices (n)
    TYPE(ErrorStatusType) :: status
  END TYPE NM_LAPACK_LinearSolve_Out
  
  ! ==========================================================================
  ! PUBLIC INTERFACES
  ! ==========================================================================
  PUBLIC :: NM_LAPACK_EigenSolve
  PUBLIC :: NM_LAPACK_SVD
  PUBLIC :: NM_LAPACK_LUFactor
  PUBLIC :: NM_LAPACK_Inverse
  PUBLIC :: NM_LAPACK_LinearSolve
  
CONTAINS

  SUBROUTINE NM_LAPACK_EigenSolve(in, out)
    TYPE(NM_LAPACK_EigenSolve_In), INTENT(IN) :: in
    TYPE(NM_LAPACK_EigenSolve_Out), INTENT(OUT) :: out
    
    INTEGER(i4) :: n, i
    
    CALL init_error_status(out%status)
    
    IF (.NOT. ALLOCATED(in%matrix)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_EigenSolve: Input matrix not allocated'
      RETURN
    END IF
    
    n = SIZE(in%matrix, 1)
    
    ! STUB implementation: Return diagonal elements as rough eigenvalue estimates
    ! TODO: Replace with actual LAPACK DSYEV call when linking is configured
    ALLOCATE(out%eigenvalues(n))
    DO i = 1, n
      out%eigenvalues(i) = in%matrix(i, i)
    END DO
    
    IF (in%compute_vectors) THEN
      ALLOCATE(out%eigenvectors(n, n))
      out%eigenvectors = ZERO
      DO i = 1, n
        out%eigenvectors(i, i) = ONE  ! Identity as placeholder
      END DO
    END IF
    
    out%status%status_code = IF_STATUS_WARN
    out%status%message = 'NM_LAPACK_EigenSolve: STUB (diagonal only) - Use DGEEV for general eigenvalues'
    
  END SUBROUTINE NM_LAPACK_EigenSolve

  SUBROUTINE NM_LAPACK_Inverse(in, out)
    TYPE(NM_LAPACK_Inverse_In), INTENT(IN) :: in
    TYPE(NM_LAPACK_Inverse_Out), INTENT(OUT) :: out
    
    INTEGER(i4) :: n, info, lwork
    INTEGER(i4), ALLOCATABLE :: pivot(:)
    REAL(wp), ALLOCATABLE :: work(:)
    REAL(wp) :: work_query(1)
    
    CALL init_error_status(out%status)
    
    IF (.NOT. ALLOCATED(in%matrix)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_Inverse: Input matrix not allocated'
      RETURN
    END IF
    
    n = SIZE(in%matrix, 1)
    
    IF (SIZE(in%matrix, 2) /= n) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_Inverse: Matrix must be square'
      RETURN
    END IF
    
    ! Allocate output and working arrays
    ALLOCATE(out%inverse(n, n))
    ALLOCATE(pivot(n))
    
    ! Copy input matrix (DGETRF/DGETRI overwrite input)
    out%inverse = in%matrix
    
    ! Step 1: LU factorization A = P*L*U
    CALL DGETRF(n, n, out%inverse, n, pivot, info)
    
    IF (info /= 0) THEN
      IF (info < 0) THEN
        out%status%status_code = IF_STATUS_INVALID
        WRITE(out%status%message, '(A,I0)') 'DGETRF: Illegal argument at position ', -info
      ELSE
        out%status%status_code = IF_STATUS_INVALID
        WRITE(out%status%message, '(A,I0,A,I0,A)') 'Matrix singular at U(', info, ',', info, ')'
      END IF
      DEALLOCATE(pivot)
      RETURN
    END IF
    
    ! Step 2: Query optimal workspace for DGETRI
    CALL DGETRI(n, out%inverse, n, pivot, work_query, -1, info)
    lwork = INT(work_query(1))
    ALLOCATE(work(lwork))
    
    ! Step 3: Compute inverse via LU
    CALL DGETRI(n, out%inverse, n, pivot, work, lwork, info)
    
    ! Check result
    IF (info == 0) THEN
      out%status%status_code = IF_STATUS_OK
      out%status%message = 'Matrix inverse computed successfully'
    ELSE IF (info < 0) THEN
      out%status%status_code = IF_STATUS_INVALID
      WRITE(out%status%message, '(A,I0)') 'DGETRI: Illegal argument at position ', -info
    ELSE
      out%status%status_code = IF_STATUS_INVALID
      WRITE(out%status%message, '(A,I0,A,I0,A)') 'DGETRI: U(', info, ',', info, ') is singular'
    END IF
    
    DEALLOCATE(pivot, work)
    
  END SUBROUTINE NM_LAPACK_Inverse

  SUBROUTINE NM_LAPACK_LinearSolve(in, out)
    TYPE(NM_LAPACK_LinearSolve_In), INTENT(IN) :: in
    TYPE(NM_LAPACK_LinearSolve_Out), INTENT(OUT) :: out
    
    INTEGER(i4) :: n, nrhs, i, j, info
    REAL(wp), ALLOCATABLE :: A_work(:,:), B_work(:,:)
    
    CALL init_error_status(out%status)
    
    ! Input validation
    IF (.NOT. ALLOCATED(in%matrix)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_LinearSolve: Coefficient matrix not allocated'
      RETURN
    END IF
    
    IF (.NOT. ALLOCATED(in%rhs)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_LinearSolve: RHS not allocated'
      RETURN
    END IF
    
    n = SIZE(in%matrix, 1)
    nrhs = SIZE(in%rhs, 2)
    
    IF (SIZE(in%matrix, 2) /= n) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_LinearSolve: Matrix must be square'
      RETURN
    END IF
    
    IF (SIZE(in%rhs, 1) /= n) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_LinearSolve: RHS dimension mismatch'
      RETURN
    END IF
    
    ! Prepare working copies (DGESV overwrites inputs)
    ALLOCATE(A_work(n, n))
    ALLOCATE(B_work(n, nrhs))
    A_work = in%matrix
    B_work = in%rhs
    
    ALLOCATE(out%pivot(n))
    ALLOCATE(out%solution(n, nrhs))
    
    ! Call LAPACK DGESV: Solve A*X = B via LU factorization
    CALL DGESV(n, nrhs, A_work, n, out%pivot, B_work, n, info)
    
    ! Check result
    IF (info == 0) THEN
      out%solution = B_work
      out%status%status_code = IF_STATUS_OK
      out%status%message = 'Linear system solved successfully'
    ELSE IF (info < 0) THEN
      out%status%status_code = IF_STATUS_INVALID
      WRITE(out%status%message, '(A,I0)') 'DGESV: Illegal argument at position ', -info
    ELSE
      out%status%status_code = IF_STATUS_INVALID
      WRITE(out%status%message, '(A,I0,A,I0,A)') 'DGESV: Matrix singular at U(', info, ',', info, ')'
    END IF
    
    DEALLOCATE(A_work, B_work)
    
  END SUBROUTINE NM_LAPACK_LinearSolve

  SUBROUTINE NM_LAPACK_LUFactor(in, out)
    TYPE(NM_LAPACK_LUFactor_In), INTENT(IN) :: in
    TYPE(NM_LAPACK_LUFactor_Out), INTENT(OUT) :: out
    
    INTEGER(i4) :: m, n, k, info
    
    CALL init_error_status(out%status)
    
    IF (.NOT. ALLOCATED(in%matrix)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_LUFactor: Input matrix not allocated'
      RETURN
    END IF
    
    m = SIZE(in%matrix, 1)
    n = SIZE(in%matrix, 2)
    k = MIN(m, n)
    
    ! Allocate output arrays

    ALLOCATE(out%pivot(k))
    
    ! Copy input matrix (DGETRF overwrites input)
    out%LU = in%matrix
    
    ! Call LAPACK DGETRF: A = P*L*U
    CALL DGETRF(m, n, out%LU, m, out%pivot, info)
    
    ! Check result
    IF (info == 0) THEN
      out%status%status_code = IF_STATUS_OK
      out%status%message = 'LU factorization completed successfully'
    ELSE IF (info < 0) THEN
      out%status%status_code = IF_STATUS_INVALID
      WRITE(out%status%message, '(A,I0)') 'DGETRF: Illegal argument at position ', -info
    ELSE
      out%status%status_code = IF_STATUS_WARN
      WRITE(out%status%message, '(A,I0,A,I0,A)') 'DGETRF: U(', info, ',', info, ') is singular'
    END IF
    
  END SUBROUTINE NM_LAPACK_LUFactor

  SUBROUTINE NM_LAPACK_SVD(in, out)
    TYPE(NM_LAPACK_SVD_In), INTENT(IN) :: in
    TYPE(NM_LAPACK_SVD_Out), INTENT(OUT) :: out
    
    INTEGER(i4) :: m, n, k, i
    
    CALL init_error_status(out%status)
    
    IF (.NOT. ALLOCATED(in%matrix)) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'NM_LAPACK_SVD: Input matrix not allocated'
      RETURN
    END IF
    
    m = SIZE(in%matrix, 1)
    n = SIZE(in%matrix, 2)
    k = MIN(m, n)
    
    ! STUB implementation: Return diagonal absolute values as singular values
    ! TODO: Replace with actual LAPACK DGESVD call when linking is configured

    DO i = 1, k
      out%Sigma(i) = ABS(in%matrix(i, i))
    END DO
    
    IF (in%jobu /= 'N') THEN

      out%U = ZERO
      DO i = 1, m
        out%U(i, i) = ONE  ! Identity as placeholder
      END DO
    END IF
    
    IF (in%jobvt /= 'N') THEN
      ALLOCATE(out%VT(n, n))
      out%VT = ZERO
      DO i = 1, n
        out%VT(i, i) = ONE  ! Identity as placeholder
      END DO
    END IF
    
    out%status%status_code = IF_STATUS_WARN
    out%status%message = 'NM_LAPACK_SVD: STUB implementation (diagonal absolute values only)'
    
  END SUBROUTINE NM_LAPACK_SVD
END MODULE NM_LAPACK_Brg