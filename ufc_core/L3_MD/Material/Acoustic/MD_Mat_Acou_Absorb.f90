!===============================================================================
! Module: MD_AcoAbsorb
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Acoustic / Absorbing
! mat_id: 1002
!
! PURPOSE:
!   L3_MD descriptor for acoustic absorbing material.
!   Impedance: Z = rho * c * (1 + i*eta)
! **W1**：**props** 布局与 **Populate** / **`MD_Mat_Desc%props`** 一致；L4
!   **PH_Mat_Acoustic_Core** 经 **MD_Mat_Acous_Desc** / 槽 **`desc%props`** 取参。
!===============================================================================
MODULE MD_Mat_Acou_Absorb
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_AcoAbsorb_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 3_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_AcoAbsorb_Desc
    REAL(wp) :: K = 0.0_wp     ! Bulk modulus [Pa]
    REAL(wp) :: rho = 0.0_wp   ! Density [kg/m³]
    REAL(wp) :: eta = 0.0_wp   ! Loss factor (attenuation)

    !-- Derived
    REAL(wp) :: c = 0.0_wp     ! Wave speed
    REAL(wp) :: Z_re = 0.0_wp  ! Real impedance
    REAL(wp) :: Z_im = 0.0_wp  ! Imaginary impedance

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_AcoAbsorb_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_AcoAbsorb_Desc), INTENT(IN)  :: self
    INTEGER(i4),                  INTENT(IN)  :: nprops
    REAL(wp),                 INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),     INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    IF (props(1) <= 0.0_wp .OR. props(2) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_AcoAbsorb_Desc), INTENT(INOUT) :: self
    INTEGER(i4),                  INTENT(IN)    :: nprops
    REAL(wp),                 INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%K = props(1); self%rho = props(2); self%eta = props(3)

    self%c = SQRT(self%K / self%rho)
    self%Z_re = self%rho * self%c
    self%Z_im = self%rho * self%c * self%eta

    self%cfg%matId = 1002_i4; self%class_id = 10_i4
    self%cfg%behavior = "Acoustic Absorbing Material"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Acou_Absorb