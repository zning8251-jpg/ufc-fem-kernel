!======================================================================
! Module: MD_VisPronyVol
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Viscoelastic / Volumetric Prony Series (mat_id=502)
! Purpose: L3_MD descriptor for volumetric Prony series viscoelastic model.
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**502**）；**L4 粘弹槽**。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Visco_PronyVol
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_PronyVol_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 4_i4   ! K_inf, n_prony, alpha_i, tau_i

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_PronyVol_Desc
    INTEGER(i4) :: n_prony = 0_i4  ! Number of Prony terms
    REAL(wp) :: K_inf = 0.0_wp     ! Instantaneous bulk modulus [Pa]
    REAL(wp), ALLOCATABLE :: K_i(:)   ! Prony coefficients [Pa]
    REAL(wp), ALLOCATABLE :: tau_i(:)  ! Relaxation times [s]
    REAL(wp) :: K_0 = 0.0_wp      ! Long-term bulk modulus [Pa]

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_PronyVol_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_PronyVol_Desc), INTENT(IN)  :: self
    INTEGER(i4),                 INTENT(IN)  :: nprops
    REAL(wp),                  INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),      INTENT(OUT) :: st

    INTEGER(i4) :: n_prony, required

    CALL init_error_status(st)

    IF (nprops < 2) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_VisPronyVol]: nprops must be >= 2"
      RETURN
    END IF

    n_prony = INT(NINT(props(1)), KIND=i4)
    required = 1 + 2 * n_prony

    IF (nprops < required) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_VisPronyVol]: nprops insufficient for n_prony terms"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_PronyVol_Desc), INTENT(INOUT) :: self
    INTEGER(i4),                 INTENT(IN)    :: nprops
    REAL(wp),                  INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),      INTENT(OUT)   :: st

    INTEGER(i4) :: i, n_prony

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%n_prony = INT(NINT(props(1)), KIND=i4)
    n_prony = self%n_prony

    self%K_inf = props(2)

    IF (ALLOCATED(self%K_i)) DEALLOCATE(self%K_i)
    IF (ALLOCATED(self%tau_i)) DEALLOCATE(self%tau_i)
    ALLOCATE(self%K_i(n_prony), self%tau_i(n_prony))

    DO i = 1, n_prony
      self%K_i(i) = props(2 + i)
      self%tau_i(i) = props(2 + n_prony + i)
    END DO

    self%K_0 = self%K_inf + SUM(self%K_i)

    self%cfg%matId = 502_i4; self%class_id = 5_i4
    self%cfg%behavior = "Volumetric Prony Series Viscoelastic"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Visco_PronyVol