!===============================================================================
! MODULE: NM_LinAlg_Domain
! LAYER:  L2_NM
! DOMAIN: Matrix
! ROLE:   Domain — LinearAlgebra domain container aggregating sparse/dense types
! BRIEF:  Domain container for CSR matrix, vector ops, LAPACK wrappers
!===============================================================================
MODULE NM_LinAlg_Domain
  USE IF_Prec_Core,             ONLY: wp, i4
  USE IF_Err_Brg,          ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_Mtx_Sparse, ONLY: NM_CSR_Type
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Matrix format constants
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_FMT_CSR   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_FMT_COO   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_FMT_DENSE = 3_i4

  !--------------------------------------------------------------------
  ! NM_SparseConfig ?Sparse matrix configuration
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_SparseConfig
    INTEGER(i4) :: defaultFmt  = NM_FMT_CSR
    LOGICAL     :: enSymStore  = .FALSE.    ! Symmetric half-storage
    LOGICAL     :: enReorder   = .TRUE.     ! AMD/RCM reordering
  END TYPE NM_SparseConfig

  !--------------------------------------------------------------------
  ! NM_LinAlg_Domain ?Domain container
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_LinAlg_Domain
    TYPE(NM_SparseConfig) :: sparseConfig
    LOGICAL               :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init        => NM_Mtx_LinAlg_Init
    PROCEDURE :: Finalize    => NM_Mtx_LinAlg_Finalize
    PROCEDURE :: SetFormat   => NM_Mtx_LinAlg_SetFormat
    PROCEDURE :: MatVec      => NM_LinAlg_Domain_MatVec
    PROCEDURE :: GetSummary  => NM_Mtx_LinAlg_GetSummary
  END TYPE NM_LinAlg_Domain

CONTAINS

  SUBROUTINE NM_Mtx_LinAlg_Finalize(this)
    CLASS(NM_LinAlg_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%sparseConfig%defaultFmt = NM_FMT_CSR
    this%sparseConfig%enSymStore = .FALSE.
    this%sparseConfig%enReorder  = .TRUE.
    this%initialized = .FALSE.
  END SUBROUTINE NM_Mtx_LinAlg_Finalize

  SUBROUTINE NM_Mtx_LinAlg_Init(this, status)
    CLASS(NM_LinAlg_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%initialized  = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_Mtx_LinAlg_Init

  !====================================================================
  ! NM_Mtx_LinAlg_SetFormat
  ! Set default matrix format
  !====================================================================
  SUBROUTINE NM_Mtx_LinAlg_SetFormat(this, format, status)
    CLASS(NM_LinAlg_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: format
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! Validate format
    IF (format < NM_FMT_CSR .OR. format > NM_FMT_DENSE) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid format (must be 1=CSR, 2=COO, 3=DENSE)"
      RETURN
    END IF

    this%sparseConfig%defaultFmt = format
    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_Mtx_LinAlg_SetFormat

  !====================================================================
  ! NM_LinAlg_Domain_MatVec
  ! Matrix-vector multiplication: y = A x
  !====================================================================
  SUBROUTINE NM_LinAlg_Domain_MatVec(this, A, x, y, status)
    CLASS(NM_LinAlg_Domain), INTENT(INOUT) :: this
    TYPE(NM_CSR_Type),       INTENT(IN)    :: A
    REAL(wp),                INTENT(IN)    :: x(:)
    REAL(wp),                INTENT(OUT)   :: y(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)

    ! Validate dimensions: y = A*x => x has m cols, y has n rows
    IF (.NOT. A%is_allocated .OR. SIZE(x) /= A%m .OR. SIZE(y) /= A%n) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Dimension mismatch in MatVec"
      RETURN
    END IF

    ! CSR matrix-vector multiplication: y = A x
    y = 0.0_wp
    DO i = 1, A%n
      DO j = A%ia(i), A%ia(i+1) - 1
        y(i) = y(i) + A%a(j) * x(A%ja(j))
      END DO
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_LinAlg_Domain_MatVec

  !====================================================================
  ! NM_Mtx_LinAlg_GetSummary
  ! Get summary string of linear algebra domain
  !====================================================================
  SUBROUTINE NM_Mtx_LinAlg_GetSummary(this, summary, status)
    CLASS(NM_LinAlg_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CHARACTER(LEN=16) :: fmtName

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "LinearAlgebra domain not initialized"
      RETURN
    END IF

    ! Get format name
    SELECT CASE(this%sparseConfig%defaultFmt)
    CASE(NM_FMT_CSR)
      fmtName = "CSR"
    CASE(NM_FMT_COO)
      fmtName = "COO"
    CASE(NM_FMT_DENSE)
      fmtName = "DENSE"
    CASE DEFAULT
      fmtName = "Unknown"
    END SELECT

    WRITE(summary, '(A,A,A,L1,A,L1)') &
      "LinAlg Summary: Format=", TRIM(fmtName), &
      ", SymStore=", this%sparseConfig%enSymStore, &
      ", Reorder=", this%sparseConfig%enReorder

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_Mtx_LinAlg_GetSummary

END MODULE NM_LinAlg_Domain