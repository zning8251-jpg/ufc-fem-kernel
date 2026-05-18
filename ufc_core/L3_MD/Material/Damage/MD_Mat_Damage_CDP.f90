!======================================================================
! Module: MD_DmgCDP
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Damage / Concrete Damage Plasticity (mat_id=706)
! Purpose: L3_MD descriptor for Concrete Damage Plasticity model.
!          Combines Drucker-Prager plasticity with isotropic damage.
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **`desc%props`**（**706** CDP）。
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE MD_Mat_Damage_CDP
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_CDP_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 8_i4   ! E, nu, fc, ft, Ec, Et, Gf_c, Gf_t

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_CDP_Desc
    REAL(wp) :: E = 0.0_wp        ! Elastic modulus [Pa]
    REAL(wp) :: nu = 0.0_wp       ! Poisson's ratio [-]
    REAL(wp) :: fc = 0.0_wp       ! Compressive strength [Pa]
    REAL(wp) :: ft = 0.0_wp       ! Tensile strength [Pa]
    REAL(wp) :: Ec = 0.0_wp       ! Plastic hardening modulus (compression) [Pa]
    REAL(wp) :: Et = 0.0_wp       ! Plastic hardening modulus (tension) [Pa]
    REAL(wp) :: Gf_c = 0.0_wp     ! Fracture energy in compression [J/m2]
    REAL(wp) :: Gf_t = 0.0_wp     ! Fracture energy in tension [J/m2]
    REAL(wp) :: psi = 0.0_wp     ! Dilation angle [deg]
    REAL(wp) :: ecc = 0.0_wp     ! Eccentricity [-]

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_CDP_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_CDP_Desc), INTENT(IN)  :: self
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),            INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_DmgCDP]: nprops must be >= 8"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_DmgCDP]: E must be > 0"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_CDP_Desc), INTENT(INOUT) :: self
    INTEGER(i4),           INTENT(IN)    :: nprops
    REAL(wp),            INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%E = props(1); self%nu = props(2)
    self%fc = props(3); self%ft = props(4)
    self%Ec = props(5); self%Et = props(6)
    self%Gf_c = props(7); self%Gf_t = props(8)

    IF (nprops >= 9) self%psi = props(9)
    IF (nprops >= 10) self%ecc = props(10)

    self%cfg%matId = 706_i4; self%class_id = 7_i4
    self%cfg%behavior = "Concrete Damage Plasticity"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Damage_CDP