!===============================================================================
! MODULE: MD_Mat_Elas_Compat
! LAYER:  L3_MD
! DOMAIN: Material / Elas
! ROLE:   Compat (Compatibility Layer)
! BRIEF:  Compatibility layer for legacy elastic material interfaces.
!         Provides adapters from old API to new unified architecture.
!         This module allows existing code to continue working while
!         gradually migrating to the new architecture.
!
!         Legacy interfaces supported:
!         - MD_Ela_Iso (MD_Mat_Iso_Desc)
!         - MD_Ela_Ortho (MD_Mat_Ortho_Desc)
!         - MD_Ela_Aniso (MD_Mat_Aniso_Desc)
!         - MD_Mat_Elas_Isotropic (IsoElastic_MatDesc)
!         - MD_Mat_Elas_Orthotropic (OrthoElastic_MatDesc)
!         - MD_Mat_Elas_TransIsotropic (TransIsoElastic_MatDesc)
!         - MD_Mat_Elas_Anisotropic (AnisoElastic_MatDesc)
!         - MD_Mat_Elas_Porous (PorousElastic_MatDesc)
!         - MD_Mat_Elas_Hypoelastic (HypoElastic_MatDesc)
!
!         Migration path:
!         Old code: CALL UF_IsoElas_L3_InitFromProps(old_desc, ...)
!         New code: CALL MD_Mat_Elas_Create_Isotropic(new_desc, ...)
!===============================================================================
MODULE MD_Mat_Elas_Compat
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE MD_Mat_Elas_Def, ONLY: MD_Mat_Elas_Desc
  USE MD_Mat_Elas_Core, ONLY: MD_Mat_Elas_Create_Isotropic, &
                               MD_Mat_Elas_Create_Orthotropic, &
                               MD_Mat_Elas_Create_Anisotropic, &
                               MD_Mat_Elas_Create_From_Props
  USE MD_Mat_Family_Def, ONLY: MD_MAT_ELAS_SUB_ISO, &
                                MD_MAT_ELAS_SUB_ORTHO, &
                                MD_MAT_ELAS_SUB_TRANSISO, &
                                MD_MAT_ELAS_SUB_ANISO, &
                                MD_MAT_ELAS_SUB_POROUS, &
                                MD_MAT_ELAS_SUB_HYPO
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Legacy TYPE wrappers (for backward compatibility)
  !-----------------------------------------------------------------------------

  ! Wrapper for MD_Ela_Iso::MD_Mat_Iso_Desc
  TYPE, PUBLIC :: MD_Mat_Iso_Desc_Compat
    TYPE(MD_Mat_Elas_Desc) :: new_desc  ! Internal: new architecture descriptor
    REAL(wp) :: E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: rho = 0.0_wp
    REAL(wp) :: G = 0.0_wp
    REAL(wp) :: K = 0.0_wp
    REAL(wp) :: lambda = 0.0_wp
  END TYPE MD_Mat_Iso_Desc_Compat

  ! Wrapper for MD_Mat_Elas_Isotropic::IsoElastic_MatDesc
  TYPE, PUBLIC :: IsoElastic_MatDesc_Compat
    TYPE(MD_Mat_Elas_Desc) :: new_desc
    REAL(wp) :: E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: lambda = 0.0_wp
    REAL(wp) :: mu = 0.0_wp
    REAL(wp) :: K = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  END TYPE IsoElastic_MatDesc_Compat

  !-----------------------------------------------------------------------------
  ! Public compatibility interfaces
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Iso_Desc_Compat
  PUBLIC :: IsoElastic_MatDesc_Compat

  ! Legacy function adapters
  PUBLIC :: MD_Ela_Iso_InitFromProps_Compat
  PUBLIC :: UF_IsoElas_L3_InitFromProps_Compat
  PUBLIC :: MD_Ela_Iso_ValidateProps_Compat
  PUBLIC :: UF_IsoElas_L3_ValidateProps_Compat

CONTAINS

  !-----------------------------------------------------------------------------
  ! MD_Ela_Iso_InitFromProps_Compat
  ! Adapter for MD_Ela_Iso::InitFromProps
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Ela_Iso_InitFromProps_Compat(compat_desc, nprops, props, status)
    TYPE(MD_Mat_Iso_Desc_Compat), INTENT(OUT) :: compat_desc
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Validate input
    IF (nprops < 2) THEN
      status%status_code = 1
      status%message = "Isotropic elastic requires at least 2 properties (E, nu)"
      RETURN
    END IF

    ! Extract parameters
    compat_desc%E = props(1)
    compat_desc%nu = props(2)
    IF (nprops >= 3) compat_desc%rho = props(3)

    ! Create new architecture descriptor
    CALL MD_Mat_Elas_Create_Isotropic(compat_desc%new_desc, &
                                       compat_desc%E, compat_desc%nu, status)
    IF (status%status_code /= 0) RETURN

    ! Copy derived parameters back to compat structure
    compat_desc%G = compat_desc%new_desc%G
    compat_desc%K = compat_desc%new_desc%K
    compat_desc%lambda = compat_desc%new_desc%lambda

    status%status_code = 0
  END SUBROUTINE MD_Ela_Iso_InitFromProps_Compat

  !-----------------------------------------------------------------------------
  ! UF_IsoElas_L3_InitFromProps_Compat
  ! Adapter for MD_Mat_Elas_Isotropic::UF_IsoElas_L3_InitFromProps
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_IsoElas_L3_InitFromProps_Compat(compat_desc, nprops, props, status)
    TYPE(IsoElastic_MatDesc_Compat), INTENT(OUT) :: compat_desc
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Validate input
    IF (nprops < 2) THEN
      status%status_code = 1
      status%message = "Isotropic elastic requires at least 2 properties (E, nu)"
      RETURN
    END IF

    ! Extract parameters
    compat_desc%E = props(1)
    compat_desc%nu = props(2)

    ! Create new architecture descriptor
    CALL MD_Mat_Elas_Create_Isotropic(compat_desc%new_desc, &
                                       compat_desc%E, compat_desc%nu, status)
    IF (status%status_code /= 0) RETURN

    ! Copy derived parameters
    compat_desc%lambda = compat_desc%new_desc%lambda
    compat_desc%mu = compat_desc%new_desc%mu
    compat_desc%K = compat_desc%new_desc%K
    compat_desc%is_initialized = .TRUE.

    status%status_code = 0
  END SUBROUTINE UF_IsoElas_L3_InitFromProps_Compat

  !-----------------------------------------------------------------------------
  ! MD_Ela_Iso_ValidateProps_Compat
  ! Adapter for MD_Ela_Iso::ValidateProps
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Ela_Iso_ValidateProps_Compat(nprops, props, status)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Basic validation
    IF (nprops < 2) THEN
      status%status_code = 1
      status%message = "Isotropic elastic requires at least 2 properties"
      RETURN
    END IF

    IF (props(1) <= 0.0_wp) THEN
      status%status_code = 2
      status%message = "Young's modulus must be positive"
      RETURN
    END IF

    IF (props(2) < -1.0_wp .OR. props(2) >= 0.5_wp) THEN
      status%status_code = 3
      status%message = "Poisson's ratio must be in [-1, 0.5)"
      RETURN
    END IF

    status%status_code = 0
  END SUBROUTINE MD_Ela_Iso_ValidateProps_Compat

  !-----------------------------------------------------------------------------
  ! UF_IsoElas_L3_ValidateProps_Compat
  ! Adapter for MD_Mat_Elas_Isotropic::UF_IsoElas_L3_ValidateProps
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_IsoElas_L3_ValidateProps_Compat(nprops, props, status)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Delegate to common validation
    CALL MD_Ela_Iso_ValidateProps_Compat(nprops, props, status)
  END SUBROUTINE UF_IsoElas_L3_ValidateProps_Compat

  !-----------------------------------------------------------------------------
  ! Helper: Get new descriptor from compat wrapper
  !-----------------------------------------------------------------------------
  FUNCTION Get_New_Desc_From_Iso_Compat(compat_desc) RESULT(new_desc)
    TYPE(MD_Mat_Iso_Desc_Compat), INTENT(IN) :: compat_desc
    TYPE(MD_Mat_Elas_Desc) :: new_desc
    new_desc = compat_desc%new_desc
  END FUNCTION Get_New_Desc_From_Iso_Compat

  FUNCTION Get_New_Desc_From_IsoElastic_Compat(compat_desc) RESULT(new_desc)
    TYPE(IsoElastic_MatDesc_Compat), INTENT(IN) :: compat_desc
    TYPE(MD_Mat_Elas_Desc) :: new_desc
    new_desc = compat_desc%new_desc
  END FUNCTION Get_New_Desc_From_IsoElastic_Compat

END MODULE MD_Mat_Elas_Compat
