!======================================================================
! Module: MD_HypYeoh
! Layer:  L3_MD - Model Description Layer
! Domain: Material / HyperElastic / Yeoh (mat_id=403)
! Purpose: L3_MD descriptor for Yeoh hyperelastic model.
!          W = sum_i C_i0*(I1 - 3)^i + sum_j 1/Dj*(J - 1)^(2j)
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **超弹** / **`desc%props`**（**403**，与 **MR5** 同号分流）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Hyper_Yeoh
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Yeoh_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 4_i4   ! C10, C20, C30, D1

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Yeoh_Desc
    !-- Yeoh coefficients
    REAL(wp) :: C10 = 0.0_wp
    REAL(wp) :: C20 = 0.0_wp
    REAL(wp) :: C30 = 0.0_wp

    !-- Compressibility
    REAL(wp) :: D1 = 0.0_wp
    REAL(wp) :: D2 = 0.0_wp

    !-- Derived
    REAL(wp) :: G = 0.0_wp   ! Initial shear modulus = 2*C10
    REAL(wp) :: K = 0.0_wp  ! Bulk modulus

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_Yeoh_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_Yeoh_Desc), INTENT(IN)  :: self
    INTEGER(i4),            INTENT(IN)  :: nprops
    REAL(wp),             INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    IF (props(4) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_Yeoh_Desc), INTENT(INOUT) :: self
    INTEGER(i4),            INTENT(IN)    :: nprops
    REAL(wp),             INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%C10 = props(1); self%C20 = props(2); self%C30 = props(3)
    self%D1 = props(4)
    IF (nprops >= 5) self%D2 = props(5)

    !-- Derived
    self%G = 2.0_wp * self%C10
    self%K = 2.0_wp / self%D1

    self%cfg%matId = 403_i4; self%class_id = 4_i4
    self%cfg%behavior = "Yeoh Hyperelastic"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Hyper_Yeoh