!===============================================================================
! Module: MD_CmpHashin
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Composite / Hashin Failure Criteria
! mat_id: 802
!
! PURPOSE:
!   L3_MD descriptor for Hashin 3D failure criteria.
!   Fiber tension/compression, matrix tension/compression modes.
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；L4 Hashin/损伤路由 **`desc%props`**（**802**）。
!===============================================================================
MODULE MD_Mat_Comp_Hashin
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Hashin_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 9_i4

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Hashin_Desc
    !-- Fiber properties
    REAL(wp) :: Xt = 0.0_wp    ! Fiber tension strength
    REAL(wp) :: Xc = 0.0_wp    ! Fiber compression strength
    REAL(wp) :: FL_t = 0.0_wp  ! Longitudinal tensile
    REAL(wp) :: FL_c = 0.0_wp  ! Longitudinal compressive

    !-- Matrix properties
    REAL(wp) :: Yt = 0.0_wp    ! Matrix tension strength
    REAL(wp) :: Yc = 0.0_wp    ! Matrix compression strength
    REAL(wp) :: FT_t = 0.0_wp  ! Transverse tensile
    REAL(wp) :: FT_c = 0.0_wp  ! Transverse compressive

    !-- Shear properties
    REAL(wp) :: S12 = 0.0_wp   ! In-plane shear
    REAL(wp) :: S13 = 0.0_wp   ! Out-of-plane shear

    !-- Elastic (transversely isotropic)
    REAL(wp) :: E1 = 0.0_wp, E2 = 0.0_wp
    REAL(wp) :: G12 = 0.0_wp, nu12 = 0.0_wp

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_Hashin_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_Hashin_Desc), INTENT(IN)  :: self
    INTEGER(i4),              INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_Hashin_Desc), INTENT(INOUT) :: self
    INTEGER(i4),              INTENT(IN)    :: nprops
    REAL(wp),               INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    self%E1 = props(1); self%E2 = props(2)
    self%nu12 = props(3); self%G12 = props(4)
    self%Xt = props(5); self%Xc = props(6)
    self%Yt = props(7); self%Yc = props(8)
    self%S12 = props(9)
    IF (nprops >= 10) self%S13 = props(10)
    IF (nprops >= 11) self%FL_t = props(11)
    IF (nprops >= 12) self%FL_c = props(12)

    self%cfg%matId = 802_i4; self%class_id = 8_i4
    self%cfg%behavior = "Hashin Failure Criteria"
    self%is_initialized = .TRUE.
    st%status_code = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Comp_Hashin