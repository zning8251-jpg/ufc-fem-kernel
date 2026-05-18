!===============================================================================
! MODULE: NM_Solv_SVD
! LAYER:  L2_NM
! DOMAIN: Solver
! ROLE:   Proc (SVD decomposition)
! BRIEF:  LAPACK DGESDD wrapper for SVD: A = U * Sigma * V^T
!
! Theory: Golub & Van Loan (2013), "Matrix Computations", 4th ed., Ch 5.4
!
! Status: CORE | Last verified: 2026-03-24
!===============================================================================

MODULE NM_Solv_SVD
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                       IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  ! Public interfaces
  PUBLIC :: SVD_Compute_Full
  PUBLIC :: SVD_Compute_Thin
  PUBLIC :: SVD_Compute_Partial
  PUBLIC :: SVD_Condition_Number
  PUBLIC :: SVD_Rank

  ! Constants
  INTEGER(i4), PARAMETER :: NM_SVD_JOB_ALL = 1     ! Compute all singular vectors
  INTEGER(i4), PARAMETER :: NM_SVD_JOB_OVERWRITE = 2 ! Compute only singular values (A overwritten)
  INTEGER(i4), PARAMETER :: NM_SVD_JOB_SOME = 3     ! Compute partial SVD
  INTEGER(i4), PARAMETER :: NM_SVD_JOB_NO = 4       ! No singular vectors

CONTAINS

!================================================================================
! SVD_Compute_Full: Compute full SVD (all singular vectors)
!================================================================================
  SUBROUTINE SVD_Compute_Full(A, U, Sigma, VT, status, job)
    !> Compute full SVD: A = U * Σ * VT
    !> All singular vectors are computed
    REAL(wp), INTENT(IN)  :: A(:,:)
    REAL(wp), INTENT(OUT) :: U(:,:), Sigma(:), VT(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: job

    INTEGER(i4) :: m, n, lda, ldu, ldvt, info, lwork, liwork
    INTEGER(i4), ALLOCATABLE :: iwork(:)
    REAL(wp), ALLOCATABLE :: work(:), a_copy(:,:)
    EXTERNAL :: DGESDD
    CHARACTER(1) :: jobz

    ! Initialize error status
    CALL init_error_status(status)

    ! Get matrix dimensions
    m = SIZE(A, 1)
    n = SIZE(A, 2)
    lda = m
    ldu = m
    ldvt = n

    ! Validate dimensions
    IF (SIZE(U, 1) /= m .OR. SIZE(U, 2) /= m) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "SVD_Compute_Full: Invalid U dimension"
      RETURN
    END IF

    IF (SIZE(Sigma) /= MIN(m, n)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "SVD_Compute_Full: Invalid Sigma dimension"
      RETURN
    END IF

    IF (SIZE(VT, 1) /= n .OR. SIZE(VT, 2) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "SVD_Compute_Full: Invalid VT dimension"
      RETURN
    END IF

    ALLOCATE(iwork(8 * MIN(m, n)))
    ! Copy input matrix (DGESDD overwrites A)
    ALLOCATE(a_copy(m, n))
    a_copy = A

    ! Determine job type
    IF (PRESENT(job)) THEN
      SELECT CASE (job)
      CASE (NM_SVD_JOB_ALL)
        jobz = 'A'
      CASE (NM_SVD_JOB_OVERWRITE)
        jobz = 'N'
      CASE (NM_SVD_JOB_NO)
        jobz = 'N'
      CASE DEFAULT
        jobz = 'A'
      END SELECT
    ELSE
      jobz = 'A'
    END IF

    ! Query workspace size
    lwork = -1
    liwork = -1
    a_copy = A
    ALLOCATE(work(1))

    ! Call DGESDD to get optimal workspace sizes
    CALL DGESDD(jobz, m, n, a_copy, lda, Sigma, U, ldu, VT, ldvt, &
                work, lwork, iwork, liwork, info)

    lwork = INT(work(1))
    liwork = iwork(1)
    DEALLOCATE(work)
    ALLOCATE(work(lwork))

    ! Compute SVD
    a_copy = A  ! Restore original matrix
    CALL DGESDD(jobz, m, n, a_copy, lda, Sigma, U, ldu, VT, ldvt, &
                work, lwork, iwork, liwork, info)

    ! Check for errors
    IF (info < 0) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "SVD_Compute_Full: DGESDD failed, argument " // &
                       TRIM(ADJUSTL(TO_STRING(-info))) // " has illegal value"
      IF (ALLOCATED(work)) DEALLOCATE(work)
      IF (ALLOCATED(a_copy)) DEALLOCATE(a_copy)
      IF (ALLOCATED(iwork)) DEALLOCATE(iwork)
      RETURN
    ELSE IF (info > 0) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "SVD_Compute_Full: DGESDD failed, " // &
                       TRIM(ADJUSTL(TO_STRING(info))) // " off-diagonal elements did not converge"
      IF (ALLOCATED(work)) DEALLOCATE(work)
      IF (ALLOCATED(a_copy)) DEALLOCATE(a_copy)
      IF (ALLOCATED(iwork)) DEALLOCATE(iwork)
      RETURN
    END IF

    DEALLOCATE(work, a_copy, iwork)
    status%status_code = IF_STATUS_OK

  CONTAINS
    CHARACTER(20) FUNCTION TO_STRING(i)
      INTEGER(i4), INTENT(IN) :: i
      WRITE(TO_STRING, '(I20)') i
      TO_STRING = TRIM(ADJUSTL(TO_STRING))
    END FUNCTION TO_STRING

  END SUBROUTINE SVD_Compute_Full

!================================================================================
! SVD_Compute_Thin: Compute thin SVD (compact form)
!================================================================================
  SUBROUTINE SVD_Compute_Thin(A, U, Sigma, VT, status)
    !> Compute thin SVD: A = U * Σ * VT
    !> Only compute k = min(m,n) singular vectors (memory efficient)
    REAL(wp), INTENT(IN)  :: A(:,:)
    REAL(wp), INTENT(OUT) :: U(:,:), Sigma(:), VT(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: m, n, k, lda, ldu, ldvt, info, lwork, liwork
    INTEGER(i4), ALLOCATABLE :: iwork(:)
    REAL(wp), ALLOCATABLE :: work(:), a_copy(:,:)
    EXTERNAL :: DGESDD

    CALL init_error_status(status)

    m = SIZE(A, 1)
    n = SIZE(A, 2)
    k = MIN(m, n)
    lda = m
    ldu = m
    ldvt = n

    ! Validate dimensions
    IF (SIZE(U, 1) /= m .OR. SIZE(U, 2) /= k) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "SVD_Compute_Thin: Invalid U dimension"
      RETURN
    END IF

    IF (SIZE(Sigma) /= k) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "SVD_Compute_Thin: Invalid Sigma dimension"
      RETURN
    END IF

    IF (SIZE(VT, 1) /= k .OR. SIZE(VT, 2) /= n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "SVD_Compute_Thin: Invalid VT dimension"
      RETURN
    END IF

    ALLOCATE(iwork(8 * k))
    ! Allocate workspace
    ALLOCATE(a_copy(m, n))
    a_copy = A
    lwork = -1
    liwork = -1
    ALLOCATE(work(1))

    ! Query optimal workspace
    CALL DGESDD('S', m, n, a_copy, lda, Sigma, U, ldu, VT, ldvt, &
                work, lwork, iwork, liwork, info)

    lwork = INT(work(1))
    liwork = iwork(1)
    DEALLOCATE(work)
    ALLOCATE(work(lwork))

    ! Compute thin SVD
    a_copy = A
    CALL DGESDD('S', m, n, a_copy, lda, Sigma, U, ldu, VT, ldvt, &
                work, lwork, iwork, liwork, info)

    IF (info /= 0) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "SVD_Compute_Thin: DGESDD failed with info = " // TRIM(ADJUSTL(TO_STRING(info)))
    ELSE
      status%status_code = IF_STATUS_OK
    END IF

    IF (ALLOCATED(work)) DEALLOCATE(work)
    IF (ALLOCATED(a_copy)) DEALLOCATE(a_copy)
    IF (ALLOCATED(iwork)) DEALLOCATE(iwork)

  CONTAINS
    CHARACTER(20) FUNCTION TO_STRING(i)
      INTEGER(i4), INTENT(IN) :: i
      WRITE(TO_STRING, '(I20)') i
      TO_STRING = TRIM(ADJUSTL(TO_STRING))
    END FUNCTION TO_STRING

  END SUBROUTINE SVD_Compute_Thin

!================================================================================
! SVD_Compute_Partial: Compute partial SVD (top k singular values)
!================================================================================
  SUBROUTINE SVD_Compute_Partial(A, k, U, Sigma, VT, status)
    !> Compute partial SVD: only the top k singular values/vectors
    !> More efficient for large matrices when only dominant modes needed
    REAL(wp), INTENT(IN)  :: A(:,:)
    INTEGER(i4), INTENT(IN) :: k
    REAL(wp), INTENT(OUT) :: U(:,:), Sigma(:), VT(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: m, n
    REAL(wp), ALLOCATABLE :: U_full(:,:), Sigma_full(:), VT_full(:,:)

    CALL init_error_status(status)

    m = SIZE(A, 1)
    n = SIZE(A, 2)

    ! Validate k
    IF (k < 1 .OR. k > MIN(m, n)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "SVD_Compute_Partial: Invalid k value"
      RETURN
    END IF

    ! Compute full thin SVD first
    ALLOCATE(U_full(m, MIN(m,n)), Sigma_full(MIN(m,n)), VT_full(MIN(m,n), n))

    CALL SVD_Compute_Thin(A, U_full, Sigma_full, VT_full, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      DEALLOCATE(U_full, Sigma_full, VT_full)
      RETURN
    END IF

    ! Extract top k
    U(:, 1:k) = U_full(:, 1:k)
    Sigma(1:k) = Sigma_full(1:k)
    VT(1:k, :) = VT_full(1:k, :)

    DEALLOCATE(U_full, Sigma_full, VT_full)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE SVD_Compute_Partial

!================================================================================
! SVD_Condition_Number: Compute condition number (σ_max / σ_min)
!================================================================================
  FUNCTION SVD_Condition_Number(Sigma) RESULT(kappa)
    !> Compute condition number from singular values
    REAL(wp), INTENT(IN) :: Sigma(:)
    REAL(wp) :: kappa

    INTEGER(i4) :: n

    n = SIZE(Sigma)
    IF (n == 0) THEN
      kappa = 0.0_wp
      RETURN
    END IF

    ! Condition number = σ_max / σ_min (for 2-norm)
    IF (Sigma(n) > 0.0_wp) THEN
      kappa = Sigma(1) / Sigma(n)
    ELSE
      kappa = 0.0_wp
    END IF

  END FUNCTION SVD_Condition_Number

!================================================================================
! SVD_Rank: Compute matrix rank (count non-zero singular values)
!================================================================================
  FUNCTION SVD_Rank(Sigma, tol) RESULT(r)
    !> Compute rank from singular values
    REAL(wp), INTENT(IN) :: Sigma(:)
    REAL(wp), INTENT(IN), OPTIONAL :: tol
    INTEGER(i4) :: r

    REAL(wp) :: threshold
    INTEGER(i4) :: n, i

    n = SIZE(Sigma)
    IF (n == 0) THEN
      r = 0
      RETURN
    END IF

    ! Default tolerance: max(m,n) * ε * σ_max
    IF (PRESENT(tol)) THEN
      threshold = tol
    ELSE
      threshold = REAL(n, wp) * EPSILON(1.0_wp) * Sigma(1)
    END IF

    ! Count non-zero singular values
    r = 0
    DO i = 1, n
      IF (Sigma(i) > threshold) THEN
        r = r + 1
      END IF
    END DO

  END FUNCTION SVD_Rank

END MODULE NM_Solv_SVD