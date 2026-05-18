!======================================================================
! Module: MD_HypFoam
! Layer:  L3_MD - Model Description Layer
! Domain: Material / HyperElastic / Foam Rubber (mat_id=408)
! Purpose: L3_MD descriptor for hyperelastic foam rubber model.
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **超弹** / **`desc%props`**（**408**）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Hyper_Foam
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Foam_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 4_i4   ! C10, C01, D1, beta

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Foam_Desc
    REAL(wp) :: C10 = 0.0_wp    ! Shear parameter [Pa]
    REAL(wp) :: C01 = 0.0_wp    ! Secondary parameter [Pa]
    REAL(wp) :: D1 = 0.0_wp     ! Compressibility [1/Pa]
    REAL(wp) :: beta = 0.0_wp   ! Volumetric coupling exponent [-]
    REAL(wp) :: G = 0.0_wp      ! Shear modulus [Pa]
    REAL(wp) :: K = 0.0_wp      ! Bulk modulus [Pa]

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_Foam_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_Foam_Desc), INTENT(IN)  :: self
    INTEGER(i4),             INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_HypFoam]: nprops must be >= 4"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_HypFoam]: C10 must be > 0"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_Foam_Desc), INTENT(INOUT) :: self
    INTEGER(i4),             INTENT(IN)    :: nprops
    REAL(wp),              INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%C10 = props(1)
    self%C01 = props(2)
    self%D1 = props(3)
    self%beta = props(4)

    self%G = 2.0_wp * (self%C10 + self%C01)
    self%K = 2.0_wp / self%D1

    self%cfg%matId = 408_i4; self%class_id = 4_i4
    self%cfg%behavior = "Foam Rubber Hyperelastic"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Hyper_Foam