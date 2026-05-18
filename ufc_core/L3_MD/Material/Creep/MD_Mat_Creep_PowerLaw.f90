!===============================================================================
! Module: MD_CrpPowerLaw
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Creep / Power Law Creep
! mat_id: 601
!
! PURPOSE:
!   L3_MD descriptor for power-law creep (Norton's law).
!   eps_dot = A * sigma^n * t^m * exp(-Q/RT)
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **`desc%props`**（**601**）。
!===============================================================================
MODULE MD_Mat_Creep_PowerLaw
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_PowerLaw_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 5_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_PowerLaw_Desc
    !-- Power law parameters
    REAL(wp) :: A = 0.0_wp      ! Creep coefficient
    REAL(wp) :: n = 0.0_wp      ! Stress exponent
    REAL(wp) :: m = 0.0_wp      ! Time exponent
    REAL(wp) :: Q = 0.0_wp      ! Activation energy [J/mol]
    REAL(wp) :: R = 8.314_wp    ! Gas constant [J/(mol*K)]

    !-- Temperature
    REAL(wp) :: T_ref = 293.0_wp ! Reference temperature [K]

    !-- Coupled elastic parameters
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp

    !-- Derived
    REAL(wp) :: G = 0.0_wp, K = 0.0_wp

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_PowerLaw_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_PowerLaw_Desc), INTENT(IN)  :: self
    INTEGER(i4),             INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(:)
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

    IF (props(2) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_PowerLaw_Desc), INTENT(INOUT) :: self
    INTEGER(i4),             INTENT(IN)    :: nprops
    REAL(wp),              INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%A = props(1); self%n = props(2); self%m = props(3)
    self%Q = props(4); self%R = 8.314_wp

    IF (nprops >= 6) THEN
      self%E = props(5); self%nu = props(6)
    ELSE
      self%E = props(5); self%nu = 0.3_wp
    END IF

    IF (nprops >= 7) self%T_ref = props(7)

    self%G = self%E / (2.0_wp * (1.0_wp + self%nu))
    self%K = self%E / (3.0_wp * (1.0_wp - 2.0_wp * self%nu))

    self%cfg%matId = 601_i4; self%class_id = 6_i4
    self%cfg%behavior = "Power Law Creep (Norton)"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Creep_PowerLaw