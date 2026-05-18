!===============================================================================
! Module: MD_PlsBarlat
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Plastic / Barlat Yld2000-2d Anisotropic Yield
! mat_id: 211
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **`desc%props`** / **`UF_Plastic_Eval_Dispatch_FromDesc`**（**211**）。
!
! PURPOSE:
!   L3_MD descriptor for Barlat Yld2000-2d orthotropic yield function.
!   16-parameter plane stress anisotropic yield criterion.
!===============================================================================
MODULE MD_Mat_Plast_Barlat
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Barlat_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 18_i4   ! E, nu, sy0, 16 Barlat params

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Barlat_Desc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: sigma_y0 = 0.0_wp, H_iso = 0.0_wp

    !-- Barlat 2000-2d parameters
    REAL(wp) :: alpha(8) = 0.0_wp   ! Linear combination coefficients

    !-- Derived
    REAL(wp) :: G = 0.0_wp, K = 0.0_wp

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_Barlat_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_Barlat_Desc), INTENT(IN)  :: self
    INTEGER(i4),              INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_PlsBarlat]: nprops must be >= 18"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_Barlat_Desc), INTENT(INOUT) :: self
    INTEGER(i4),              INTENT(IN)    :: nprops
    REAL(wp),               INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: st

    INTEGER(i4) :: i

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%E = props(1); self%nu = props(2)
    self%sigma_y0 = props(3); self%H_iso = props(4)

    DO i = 1, 8
      self%alpha(i) = props(4 + i)
    END DO

    self%G = self%E / (2.0_wp * (1.0_wp + self%nu))
    self%K = self%E / (3.0_wp * (1.0_wp - 2.0_wp * self%nu))

    self%cfg%matId = 211_i4; self%class_id = 2_i4
    self%cfg%behavior = "Barlat Yld2000-2d Anisotropic Yield"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Plast_Barlat