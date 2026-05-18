!======================================================================
! Module: MD_HypAB
! Layer:  L3_MD - Model Description Layer
! Domain: Material / HyperElastic / Arruda-Boyce (mat_id=406)
! Purpose: L3_MD descriptor for Arruda-Boyce hyperelastic model.
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **超弹** / **`desc%props`**（**406**）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Hyper_ArrudaBoyce
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_AB_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 3_i4   ! mu, N, D

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_AB_Desc
    REAL(wp) :: mu = 0.0_wp     ! Initial shear modulus [Pa]
    REAL(wp) :: N = 0.0_wp      ! Number of chain segments [-]
    REAL(wp) :: D = 0.0_wp      ! Compressibility parameter [1/Pa]
    REAL(wp) :: G = 0.0_wp      ! Shear modulus [Pa]
    REAL(wp) :: K = 0.0_wp      ! Bulk modulus [Pa]

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_AB_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_AB_Desc), INTENT(IN)  :: self
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),            INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_HypAB]: nprops must be >= 3"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_HypAB]: mu must be > 0"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_AB_Desc), INTENT(INOUT) :: self
    INTEGER(i4),           INTENT(IN)    :: nprops
    REAL(wp),            INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%mu = props(1)
    self%N = props(2)
    self%D = props(3)

    self%G = self%mu
    self%K = 2.0_wp / self%D

    self%cfg%matId = 406_i4; self%class_id = 4_i4
    self%cfg%behavior = "Arruda-Boyce Hyperelastic"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Hyper_ArrudaBoyce