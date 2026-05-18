!======================================================================
! Module: MD_VisKelvinVoigt
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Viscoelastic / Kelvin-Voigt (mat_id=503)
! Purpose: L3_MD descriptor for Kelvin-Voigt viscoelastic model.
!          Sigma = E*eps + eta*d-eps/dt (spring-dashpot in parallel)
! **W1**：**props** ↔ **Populate** / **`desc%props`**（**503**）；**L4 粘弹槽**。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Visco_KelvinVoigt
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_KV_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 3_i4   ! E, eta, nu

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_KV_Desc
    REAL(wp) :: E = 0.0_wp       ! Elastic modulus [Pa]
    REAL(wp) :: eta = 0.0_wp     ! Viscosity coefficient [Pa*s]
    REAL(wp) :: nu = 0.0_wp     ! Poisson's ratio [-]
    REAL(wp) :: G = 0.0_wp      ! Shear modulus [Pa]
    REAL(wp) :: K = 0.0_wp      ! Bulk modulus [Pa]

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_KV_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_KV_Desc), INTENT(IN)  :: self
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),            INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_Vis_KV]: nprops must be >= 3"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_Vis_KV]: E must be > 0"
      RETURN
    END IF

    IF (props(2) < 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_Vis_KV]: eta must be >= 0"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_KV_Desc), INTENT(INOUT) :: self
    INTEGER(i4),           INTENT(IN)    :: nprops
    REAL(wp),            INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%E = props(1)
    self%eta = props(2)
    self%nu = props(3)

    self%G = self%E / (2.0_wp * (1.0_wp + self%nu))
    self%K = self%E / (3.0_wp * (1.0_wp - 2.0_wp * self%nu))

    self%cfg%matId = 503_i4; self%class_id = 5_i4
    self%cfg%behavior = "Kelvin-Voigt Viscoelastic"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Visco_KelvinVoigt