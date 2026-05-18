!===============================================================================
! Module: MD_CrpGarofalo
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Creep / Garofalo (Hyperbolic Sine)
! mat_id: 605
!
! PURPOSE:
!   L3_MD descriptor for Garofalo creep model.
!   d-eps_cr/dt = A*[sinh(alpha*sigma)]^n * exp(-Q/RT)
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **`desc%props`**（**605**）。
!===============================================================================
MODULE MD_Mat_Creep_Garofalo
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Garofalo_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 5_i4   ! A, alpha, n, Q, T_ref

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Garofalo_Desc
    REAL(wp) :: A = 0.0_wp      ! Pre-exponential factor [1/s]
    REAL(wp) :: alpha = 0.0_wp  ! Stress modifier [1/Pa]
    REAL(wp) :: n = 0.0_wp      ! Stress exponent [-]
    REAL(wp) :: Q = 0.0_wp      ! Activation energy [J/mol]
    REAL(wp) :: R = 8.314_wp    ! Gas constant [J/(mol*K)]
    REAL(wp) :: T_ref = 0.0_wp  ! Reference temperature [K]

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_Garofalo_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_Garofalo_Desc), INTENT(IN)  :: self
    INTEGER(i4),                INTENT(IN)  :: nprops
    REAL(wp),                 INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),     INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_CrpGarofalo]: nprops must be >= 5"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_CrpGarofalo]: A must be > 0"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_Garofalo_Desc), INTENT(INOUT) :: self
    INTEGER(i4),                INTENT(IN)    :: nprops
    REAL(wp),                 INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),     INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%A = props(1)
    self%alpha = props(2)
    self%n = props(3)
    self%Q = props(4)
    self%T_ref = props(5)

    self%cfg%matId = 605_i4; self%class_id = 6_i4
    self%cfg%behavior = "Garofalo (Hyperbolic Sine) Creep"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Creep_Garofalo