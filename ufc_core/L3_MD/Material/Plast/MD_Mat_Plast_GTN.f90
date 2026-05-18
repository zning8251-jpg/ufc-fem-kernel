!===============================================================================
! Module: MD_PlsGTN
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Plastic / Gurson-Tvergaard-Needleman Damage
! mat_id: 207
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 **`desc%props`** / **`UF_Plastic_Eval_Dispatch_FromDesc`**（**207**）。
!
! PURPOSE:
!   L3_MD descriptor for GTN porous plastic damage model.
!   Yield: Phi = (q1*sig_vm/sigma_y)^2 + 2*q2*f*cosh(-q3*sigma_H/sigma_y) - (1+q2^2*f^2) = 0
!===============================================================================
MODULE MD_Mat_Plast_GTN
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_GTN_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 12_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_GTN_Desc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: sigma_y0 = 0.0_wp, H_iso = 0.0_wp

    !-- GTN parameters
    REAL(wp) :: q1 = 1.5_wp, q2 = 1.0_wp, q3 = 1.0_wp
    REAL(wp) :: f0 = 0.0_wp       ! Initial void volume fraction
    REAL(wp) :: fN = 0.0_wp       ! Nucleation void volume fraction
    REAL(wp) :: epsilonN = 0.1_wp  ! Mean nucleation strain
    REAL(wp) :: sN = 0.1_wp       ! Std deviation of nucleation
    REAL(wp) :: fc = 0.0_wp       ! Critical void volume fraction
    REAL(wp) :: fF = 0.0_wp       ! Failure void volume fraction

    !-- Derived
    REAL(wp) :: G = 0.0_wp, K = 0.0_wp

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_GTN_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_GTN_Desc), INTENT(IN)  :: self
    INTEGER(i4),              INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_PlsGTN]: nprops must be >= 12"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_GTN_Desc), INTENT(INOUT) :: self
    INTEGER(i4),              INTENT(IN)    :: nprops
    REAL(wp),               INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%E = props(1); self%nu = props(2)
    self%sigma_y0 = props(3); self%H_iso = props(4)
    self%q1 = props(5); self%q2 = props(6); self%q3 = props(7)
    self%f0 = props(8); self%fN = props(9)
    self%epsilonN = props(10); self%sN = props(11)
    self%fc = props(12)

    IF (nprops >= 13) self%fF = props(13)

    self%G = self%E / (2.0_wp * (1.0_wp + self%nu))
    self%K = self%E / (3.0_wp * (1.0_wp - 2.0_wp * self%nu))

    self%cfg%matId = 207_i4; self%class_id = 2_i4
    self%cfg%behavior = "GTN Porous Plastic Damage"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Plast_GTN