!======================================================================
! Module: MD_VisPronyDev
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Viscoelastic / Prony Series Deviatoric (mat_id=501)
! Purpose: L3_MD descriptor for Prony series viscoelastic model.
!          G(t) = G_0 * (1 - sum_i alpha_i * (1 - exp(-t/tau_i)))
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**501**）；**L4 `PH_Mat_Visco_*` / Prony**。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Visco_PronyDev
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_PronyDev_Desc

  INTEGER(i4), PARAMETER :: MD_MAT_MAX_PRONY_TERMS = 10_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_PronyDev_Desc
    !-- Instantaneous elastic parameters
    REAL(wp) :: G0 = 0.0_wp    ! Instantaneous shear modulus [Pa]
    REAL(wp) :: K0 = 0.0_wp    ! Instantaneous bulk modulus [Pa]

    !-- Prony series data
    INTEGER(i4) :: n_terms = 0_i4
    REAL(wp) :: alpha(MD_MAT_MAX_PRONY_TERMS) = 0.0_wp   ! Normalized moduli
    REAL(wp) :: tau(MD_MAT_MAX_PRONY_TERMS) = 0.0_wp      ! Relaxation times [s]

    !-- Derived
    REAL(wp) :: G_inf = 0.0_wp   ! Long-term shear modulus

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_PronyDev_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_PronyDev_Desc), INTENT(IN)  :: self
    INTEGER(i4),                 INTENT(IN)  :: nprops
    REAL(wp),                  INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),      INTENT(OUT) :: st

    INTEGER(i4) :: n_terms, required, i

    CALL init_error_status(st)

    IF (nprops < 4) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_VisPronyDev]: nprops must be >= 4"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    n_terms = INT(NINT(props(3)), KIND=i4)
    IF (n_terms < 1 .OR. n_terms > MD_MAT_MAX_PRONY_TERMS) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    required = 3 + 2 * n_terms
    IF (nprops < required) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_PronyDev_Desc), INTENT(INOUT) :: self
    INTEGER(i4),                 INTENT(IN)    :: nprops
    REAL(wp),                  INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),      INTENT(OUT)   :: st

    INTEGER(i4) :: i, n_terms

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%G0 = props(1)
    self%K0 = props(2)
    n_terms = INT(NINT(props(3)), KIND=i4)
    self%n_terms = n_terms

    DO i = 1, n_terms
      self%alpha(i) = props(3 + i)
      self%tau(i) = props(3 + n_terms + i)
    END DO

    !-- Long-term modulus
    self%G_inf = self%G0 * (1.0_wp - SUM(self%alpha(1:n_terms)))

    self%cfg%matId = 501_i4; self%class_id = 5_i4
    self%cfg%behavior = "Prony Series Viscoelastic (Deviatoric)"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Visco_PronyDev