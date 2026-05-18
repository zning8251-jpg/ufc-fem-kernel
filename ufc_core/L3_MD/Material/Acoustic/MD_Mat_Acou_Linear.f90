!===============================================================================
! Module: MD_AcoLinear
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Acoustic / Linear Acoustic
! mat_id: 1001
!
! PURPOSE:
!   L3_MD descriptor for linear acoustic material.
!   Wave equation: c = sqrt(K/rho)
! **W1**：**props** 与 **Populate** / **`MD_Mat_Desc%props`** 一致；L4
!   **MD_Mat_Acous_Desc** / 槽 **`desc%props`** 为体积模量、密度等真源。
!===============================================================================
MODULE MD_Mat_Acou_Linear
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_AcoLinear_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 2_i4   ! K, rho

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_AcoLinear_Desc
    REAL(wp) :: K = 0.0_wp     ! Bulk modulus [Pa]
    REAL(wp) :: rho = 0.0_wp   ! Density [kg/m³]

    !-- Optional
    REAL(wp) :: c = 0.0_wp     ! Wave speed [m/s]
    REAL(wp) :: Z = 0.0_wp     ! Acoustic impedance

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_AcoLinear_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_AcoLinear_Desc), INTENT(IN)  :: self
    INTEGER(i4),                 INTENT(IN)  :: nprops
    REAL(wp),                INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),    INTENT(OUT) :: st

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
    CLASS(MD_Mat_AcoLinear_Desc), INTENT(INOUT) :: self
    INTEGER(i4),                 INTENT(IN)    :: nprops
    REAL(wp),                INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),    INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%K = props(1); self%rho = props(2)

    !-- Derived
    self%c = SQRT(self%K / self%rho)
    self%Z = self%rho * self%c

    self%cfg%matId = 1001_i4; self%class_id = 10_i4
    self%cfg%behavior = "Linear Acoustic Material"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Acou_Linear