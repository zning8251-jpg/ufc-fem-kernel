!===============================================================================
! Module: MD_ElaIso
! Layer:  L3_MD - Model Description Layer
! Domain: Material / Elastic / Isotropic Linear Elasticity
! mat_id: 101
!
! PURPOSE:
!   L3_MD descriptor for isotropic linear elastic material.
!   Constitutive law: sigma = lambda*tr(eps)*I + 2*G*eps
! **W1**：**props** ↔ **Populate** / **`MD_Mat_Desc%props`**；**UF_Elastic_*** / **`desc%props`**（**101**）。
!===============================================================================
MODULE MD_Mat_Elas_Iso
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          STATUS_OK, STATUS_INVALID
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Elas_Iso_Desc

  INTEGER(i4), PARAMETER :: MD_NPROPS_MIN = 2_i4   ! E, nu

  !> L3 descriptor for isotropic linear elastic material.
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_Elas_Iso_Desc
    !-- Primary material parameters
    REAL(wp) :: E = 0.0_wp      ! Young's modulus [Pa]
    REAL(wp) :: nu = 0.0_wp     ! Poisson's ratio [-]

    !-- Optional: density for dynamic analysis
    REAL(wp) :: rho = 0.0_wp    ! Mass density [kg/m3]

    !-- Derived elastic constants
    REAL(wp) :: G = 0.0_wp      ! Shear modulus [Pa]
    REAL(wp) :: K = 0.0_wp      ! Bulk modulus [Pa]
    REAL(wp) :: lambda = 0.0_wp ! Lame's first parameter [Pa]

  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_Elas_Iso_Desc

CONTAINS

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_Elas_Iso_Desc), INTENT(IN)  :: self
    INTEGER(i4),            INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT) :: st

    CALL init_error_status(st)

    IF (nprops < MD_NPROPS_MIN) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_ElaIso]: nprops must be >= 2 (E, nu)"
      RETURN
    END IF

    !-- E must be positive
    IF (props(1) <= 0.0_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_ElaIso]: E (props(1)) must be > 0"
      RETURN
    END IF

    !-- nu must be in (-1, 0.5) for stability
    IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      st%status_code = STATUS_INVALID
      st%message = "[MD_ElaIso]: nu (props(2)) must be in (-1, 0.5)"
      RETURN
    END IF

    st%status_code = STATUS_OK
  END SUBROUTINE ValidateProps

  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_Elas_Iso_Desc), INTENT(INOUT) :: self
    INTEGER(i4),            INTENT(IN)    :: nprops
    REAL(wp),               INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: st

    REAL(wp) :: E, nu

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code /= STATUS_OK) RETURN

    !-- Primary parameters
    E  = props(1)
    nu = props(2)
    self%E  = E
    self%nu = nu

    !-- Optional: density (props(3))
    IF (nprops >= 3) self%rho = props(3)

    !-- Derived elastic constants
    self%G      = E / (2.0_wp * (1.0_wp + nu))
    self%K      = E / (3.0_wp * (1.0_wp - 2.0_wp * nu))
    self%lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))

    !-- Identification (via MD_Mat_Desc inherited fields)
    self%cfg%matId      = 101_i4
    self%class_id       = 1_i4   ! MD_MAT_CATEGORY_EL
    self%cfg%behavior   = "Isotropic Linear Elastic"
    self%is_initialized = .TRUE.
    st%status_code   = STATUS_OK
  END SUBROUTINE InitFromProps

END MODULE MD_Mat_Elas_Iso