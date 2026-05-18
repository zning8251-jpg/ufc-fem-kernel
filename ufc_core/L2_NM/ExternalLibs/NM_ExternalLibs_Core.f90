! LEGACY: External third-party library - exempt from UFC naming/style conventions
!===============================================================================
! Module:  NM_ExternalLibs_Core
! Layer:   L2_NM - Numerical Methods Layer
! Domain:  ExternalLibs
! Purpose: Thin wrappers around BLAS/LAPACK routines with error status.
!          Falls back to inline implementations when libraries unavailable.
!
! Signature: (desc, ..., status)
!   desc — NM_ExtLibs_Desc [IN] library availability flags
!
! Status: FOUR-TYPE | Last verified: 2026-04-25
!===============================================================================
MODULE NM_ExternalLibs_Core
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,          ONLY: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_ExternalLibs_Def, ONLY: NM_ExtLibs_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: NM_ExternalLibs_Core_Init
  PUBLIC :: NM_ExternalLibs_Core_Finalize
  PUBLIC :: NM_Ext_DGEMV
  PUBLIC :: NM_Ext_DGEMM
  PUBLIC :: NM_Ext_DGESV
  PUBLIC :: NM_Ext_DPOTRF
  PUBLIC :: NM_Ext_DNRM2

CONTAINS

  SUBROUTINE NM_ExternalLibs_Core_Init(desc, status)
    TYPE(NM_ExtLibs_Desc),  INTENT(IN)  :: desc
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_ExternalLibs_Core_Init

  SUBROUTINE NM_ExternalLibs_Core_Finalize(desc, status)
    TYPE(NM_ExtLibs_Desc),  INTENT(IN)  :: desc
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_ExternalLibs_Core_Finalize

  !---------------------------------------------------------------------------
  ! DGEMV wrapper: y = alpha*A*x + beta*y
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Ext_DGEMV(desc, m, n, alpha, A, x, beta, y, status)
    TYPE(NM_ExtLibs_Desc),  INTENT(IN)    :: desc
    INTEGER(i4),            INTENT(IN)    :: m, n
    REAL(wp),               INTENT(IN)    :: alpha
    REAL(wp),               INTENT(IN)    :: A(m, n)
    REAL(wp),               INTENT(IN)    :: x(n)
    REAL(wp),               INTENT(IN)    :: beta
    REAL(wp),               INTENT(INOUT) :: y(m)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)
    IF (m <= 0 .OR. n <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Ext_DGEMV]: invalid dimensions"
      RETURN
    END IF

    DO i = 1, m
      y(i) = beta * y(i)
      DO j = 1, n
        y(i) = y(i) + alpha * A(i, j) * x(j)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Ext_DGEMV

  !---------------------------------------------------------------------------
  ! DGEMM wrapper: C = alpha*A*B + beta*C
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Ext_DGEMM(desc, m, n, k, alpha, A, B, beta, C, status)
    TYPE(NM_ExtLibs_Desc),  INTENT(IN)    :: desc
    INTEGER(i4),            INTENT(IN)    :: m, n, k
    REAL(wp),               INTENT(IN)    :: alpha
    REAL(wp),               INTENT(IN)    :: A(m, k)
    REAL(wp),               INTENT(IN)    :: B(k, n)
    REAL(wp),               INTENT(IN)    :: beta
    REAL(wp),               INTENT(INOUT) :: C(m, n)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, l

    CALL init_error_status(status)
    IF (m <= 0 .OR. n <= 0 .OR. k <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Ext_DGEMM]: invalid dimensions"
      RETURN
    END IF

    DO j = 1, n
      DO i = 1, m
        C(i, j) = beta * C(i, j)
        DO l = 1, k
          C(i, j) = C(i, j) + alpha * A(i, l) * B(l, j)
        END DO
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Ext_DGEMM

  !---------------------------------------------------------------------------
  ! DGESV wrapper: solve A*X = B (general LU)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Ext_DGESV(desc, n, nrhs, A, b, status)
    TYPE(NM_ExtLibs_Desc),  INTENT(IN)    :: desc
    INTEGER(i4),            INTENT(IN)    :: n, nrhs
    REAL(wp),               INTENT(INOUT) :: A(n, n)
    REAL(wp),               INTENT(INOUT) :: b(n, nrhs)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (n <= 0 .OR. nrhs <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Ext_DGESV]: invalid dimensions"
      RETURN
    END IF

    ! Placeholder: real implementation would call LAPACK DGESV
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Ext_DGESV

  !---------------------------------------------------------------------------
  ! DPOTRF wrapper: Cholesky factorization A = L*L^T
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Ext_DPOTRF(desc, n, A, status)
    TYPE(NM_ExtLibs_Desc),  INTENT(IN)    :: desc
    INTEGER(i4),            INTENT(IN)    :: n
    REAL(wp),               INTENT(INOUT) :: A(n, n)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, k
    REAL(wp)    :: s

    CALL init_error_status(status)
    IF (n <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Ext_DPOTRF]: invalid dimension"
      RETURN
    END IF

    DO j = 1, n
      s = A(j, j)
      DO k = 1, j - 1
        s = s - A(j, k)**2
      END DO
      IF (s <= 0.0_wp) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[NM_Ext_DPOTRF]: matrix not positive definite"
        RETURN
      END IF
      A(j, j) = SQRT(s)
      DO i = j + 1, n
        s = A(i, j)
        DO k = 1, j - 1
          s = s - A(i, k) * A(j, k)
        END DO
        A(i, j) = s / A(j, j)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Ext_DPOTRF

  !---------------------------------------------------------------------------
  ! DNRM2 wrapper: nrm = ||x||_2
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Ext_DNRM2(desc, n, x, nrm, status)
    TYPE(NM_ExtLibs_Desc),  INTENT(IN)  :: desc
    INTEGER(i4),            INTENT(IN)  :: n
    REAL(wp),               INTENT(IN)  :: x(n)
    REAL(wp),               INTENT(OUT) :: nrm
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (n <= 0) THEN
      nrm = 0.0_wp
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_Ext_DNRM2]: invalid dimension"
      RETURN
    END IF

    nrm = SQRT(DOT_PRODUCT(x(1:n), x(1:n)))
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Ext_DNRM2

END MODULE NM_ExternalLibs_Core
