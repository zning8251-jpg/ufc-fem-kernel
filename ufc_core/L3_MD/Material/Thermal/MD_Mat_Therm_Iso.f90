!===============================================================================
! Module: MD_ThmIso
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Thermal / Isotropic
! mat_id: 901
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **`desc%props`**（**901**）。
!
! PURPOSE:
!   L3_MD descriptor for isotropic thermal material.
!   Fourier's law: q = -k * grad(T)
!===============================================================================
MODULE MD_Mat_Therm_Iso
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_ThmIso_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 3_i4   ! k, Cp, rho

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_ThmIso_Desc
    !-- Thermal parameters
    REAL(wp) :: k = 0.0_wp       ! Thermal conductivity [W/(m*K)]
    REAL(wp) :: Cp = 0.0_wp      ! Specific heat [J/(kg*K)]
    REAL(wp) :: rho = 0.0_wp     ! Density [kg/m³]

    !-- Temperature dependence
    REAL(wp) :: alpha_k = 0.0_wp  ! Thermal conductivity temp coeff [/K]
    REAL(wp) :: alpha_Cp = 0.0_wp ! Specific heat temp coeff [/K]

    !-- Optional: reference temperature
    REAL(wp) :: T_ref = 293.15_wp ! Reference temperature [K]

    !-- Derived
    REAL(wp) :: alpha = 0.0_wp   ! Thermal diffusivity

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_ThmIso_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_ThmIso_Desc), INTENT(IN)  :: self
    INTEGER(i4),             INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_ThmIso]: nprops must be >= 3"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_ThmIso]: k must be > 0"
      RETURN
    END IF

    IF (props(2) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_ThmIso]: Cp must be > 0"
      RETURN
    END IF

    IF (props(3) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_ThmIso]: rho must be > 0"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_ThmIso_Desc), INTENT(INOUT) :: self
    INTEGER(i4),             INTENT(IN)    :: nprops
    REAL(wp),              INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%k = props(1)
    self%Cp = props(2)
    self%rho = props(3)

    IF (nprops >= 4) self%alpha_k = props(4)
    IF (nprops >= 5) self%alpha_Cp = props(5)
    IF (nprops >= 6) self%T_ref = props(6)

    !-- Thermal diffusivity
    self%alpha = self%k / (self%rho * self%Cp)

    self%cfg%matId = 901_i4; self%class_id = 9_i4
    self%cfg%behavior = "Isotropic Thermal Material"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Therm_Iso