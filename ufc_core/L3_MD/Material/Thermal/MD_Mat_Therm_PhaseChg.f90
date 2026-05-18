!===============================================================================
! Module: MD_ThmPhaseChg
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Thermal / Phase Change
! mat_id: 903
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **`desc%props`**（**903**）。
!
! PURPOSE:
!   L3_MD descriptor for phase change material (PCM).
!   Latent heat absorption/release during phase transition.
!===============================================================================
MODULE MD_Mat_Therm_PhaseChg
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_PhaseChg_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 8_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_PhaseChg_Desc
    !-- Solid properties
    REAL(wp) :: k_s = 0.0_wp      ! Solid thermal conductivity
    REAL(wp) :: Cp_s = 0.0_wp     ! Solid specific heat
    REAL(wp) :: rho_s = 0.0_wp    ! Solid density

    !-- Liquid properties
    REAL(wp) :: k_l = 0.0_wp      ! Liquid thermal conductivity
    REAL(wp) :: Cp_l = 0.0_wp     ! Liquid specific heat
    REAL(wp) :: rho_l = 0.0_wp    ! Liquid density

    !-- Phase change parameters
    REAL(wp) :: T_melt = 0.0_wp   ! Melting temperature [K]
    REAL(wp) :: L_latent = 0.0_wp ! Latent heat [J/kg]

    !-- Melt fraction curve
    REAL(wp) :: dT = 0.0_wp       ! Phase change temperature range

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_PhaseChg_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_PhaseChg_Desc), INTENT(IN)  :: self
    INTEGER(i4),                INTENT(IN)  :: nprops
    REAL(wp),                 INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),    INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    IF (props(7) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_PhaseChg_Desc), INTENT(INOUT) :: self
    INTEGER(i4),                INTENT(IN)    :: nprops
    REAL(wp),                 INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),    INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%k_s = props(1); self%Cp_s = props(2); self%rho_s = props(3)
    self%k_l = props(4); self%Cp_l = props(5); self%rho_l = props(6)
    self%T_melt = props(7); self%L_latent = props(8)
    IF (nprops >= 9) self%dT = props(9)

    self%cfg%matId = 903_i4; self%class_id = 9_i4
    self%cfg%behavior = "Phase Change Material"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Therm_PhaseChg