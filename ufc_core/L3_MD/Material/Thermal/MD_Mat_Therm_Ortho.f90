!===============================================================================
! Module: MD_ThmOrtho
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Thermal / Orthotropic
! mat_id: 902
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **`desc%props`**（**902**）。
!
! PURPOSE:
!   L3_MD descriptor for orthotropic thermal material.
!   q_i = -k_i * grad_i(T) (no sum on i)
!===============================================================================
MODULE MD_Mat_Therm_Ortho
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_ThmOrtho_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 5_i4   ! k1, k2, k3, Cp, rho

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_ThmOrtho_Desc
    !-- Thermal conductivity (principal directions)
    REAL(wp) :: k1 = 0.0_wp   ! x-direction [W/(m*K)]
    REAL(wp) :: k2 = 0.0_wp   ! y-direction [W/(m*K)]
    REAL(wp) :: k3 = 0.0_wp   ! z-direction [W/(m*K)]

    !-- Common properties
    REAL(wp) :: Cp = 0.0_wp   ! Specific heat [J/(kg*K)]
    REAL(wp) :: rho = 0.0_wp  ! Density [kg/m³]

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_ThmOrtho_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_ThmOrtho_Desc), INTENT(IN)  :: self
    INTEGER(i4),                INTENT(IN)  :: nprops
    REAL(wp),                 INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),    INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    IF (props(1) <= 0.0_wp .OR. props(2) <= 0.0_wp .OR. props(3) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_ThmOrtho_Desc), INTENT(INOUT) :: self
    INTEGER(i4),                INTENT(IN)    :: nprops
    REAL(wp),                 INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),    INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%k1 = props(1); self%k2 = props(2); self%k3 = props(3)
    self%Cp = props(4); self%rho = props(5)

    self%cfg%matId = 902_i4; self%class_id = 9_i4
    self%cfg%behavior = "Orthotropic Thermal Material"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Therm_Ortho