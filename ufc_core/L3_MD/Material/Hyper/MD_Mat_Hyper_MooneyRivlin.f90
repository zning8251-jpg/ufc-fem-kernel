!======================================================================
! Module: MD_HypMooneyRivlin
! Layer:  L3_MD - Model Description Layer
! Domain: Material / HyperElastic / Mooney-Rivlin (mat_id=402)
! Purpose: L3_MD descriptor for Mooney-Rivlin hyperelastic model.
!          W = C10*(I1-3) + C01*(I2-3) + 1/D1*(J-1)^2
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **超弹** / **`desc%props`**（**402**，与 **MR2** 同号分流）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Hyper_MooneyRivlin
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_MR_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 3_i4   ! C10, C01, D1

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_MR_Desc
    REAL(wp) :: C10 = 0.0_wp    ! First invariant coefficient [Pa]
    REAL(wp) :: C01 = 0.0_wp    ! Second invariant coefficient [Pa]
    REAL(wp) :: D1 = 0.0_wp     ! Compressibility [1/Pa]

    !-- Derived
    REAL(wp) :: G = 0.0_wp      ! Shear modulus
    REAL(wp) :: K = 0.0_wp      ! Bulk modulus

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_MR_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_MR_Desc), INTENT(IN)  :: self
    INTEGER(i4),          INTENT(IN)  :: nprops
    REAL(wp),           INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    IF (props(3) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_MR_Desc), INTENT(INOUT) :: self
    INTEGER(i4),          INTENT(IN)    :: nprops
    REAL(wp),           INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%C10 = props(1)
    self%C01 = props(2)
    self%D1 = props(3)

    !-- Derived
    self%G = 2.0_wp * (self%C10 + self%C01)
    self%K = 2.0_wp / self%D1

    self%cfg%matId = 402_i4; self%class_id = 4_i4
    self%cfg%behavior = "Mooney-Rivlin Hyperelastic"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Hyper_MooneyRivlin