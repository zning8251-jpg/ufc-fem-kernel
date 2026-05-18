!===============================================================================
! MODULE: MD_MatHYP_Def
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Hyperelastic family Desc/State/Ctx/Algo types.
!         Models: Hyperfoam, Mullins, NeoHookean, MooneyRivlin, Ogden,
!         Yeoh, ArrudaBoyce, DielectricElast.
!         **W1**：各 **`*_MatDesc`** + **InitFromProps**；**props** 经 **Populate**→L4 **`desc%props`**（**PH_MAT_HYPERELASTIC**）。
!===============================================================================

MODULE MD_Mat_Hyper_Contract

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MAT_CATEGORY_HY, MD_MAT_CATEGORY_MULTIPHYS

  IMPLICIT NONE
  PRIVATE

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Hyperfoam_MatDesc
    INTEGER(i4) :: nTerms = 1
    REAL(wp) :: poisson = 0.0_wp
    REAL(wp), ALLOCATABLE :: mu_i(:), alpha_i(:), nu_i(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Hyperfoam_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Hyperfoam_MatDesc_Valid
  END TYPE Hyperfoam_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Hyperfoam_MatState
    REAL(wp) :: strain_energy = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Hyperfoam_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Hyperfoam_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Hyperfoam_MatState_InitFromInputs
  END TYPE Hyperfoam_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Hyperfoam_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Hyperfoam_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Hyperfoam_MatCtx_InitDefaults
  END TYPE Hyperfoam_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Hyperfoam_MatAlgo
    INTEGER(i4) :: moduliType = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Hyperfoam_MatAlgo_InitDefaults
  END TYPE Hyperfoam_MatAlgo

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Mullins_MatDesc
    REAL(wp) :: r_param = 0.0_wp, m_param = 0.0_wp, beta_perm = 0.0_wp
    INTEGER(i4) :: base_model = 301_i4
    REAL(wp), ALLOCATABLE :: base_props(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Mullins_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Mullins_MatDesc_Valid
  END TYPE Mullins_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Mullins_MatState
    REAL(wp) :: eta = 1.0_wp, eta_min = 1.0_wp, W_max = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Mullins_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Mullins_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Mullins_MatState_InitFromInputs
  END TYPE Mullins_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Mullins_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Mullins_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Mullins_MatCtx_InitDefaults
  END TYPE Mullins_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Mullins_MatAlgo
    INTEGER(i4) :: mullins_method = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Mullins_MatAlgo_InitDefaults
  END TYPE Mullins_MatAlgo

  !=============================================================================

  ! Neo-Hookean (HyperElastic)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: NeoHookean_MatDesc
    REAL(wp) :: C10 = 0.0_wp, D1 = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => NeoHookean_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => NeoHookean_MatDesc_Valid
  END TYPE NeoHookean_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: NeoHookean_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => NeoHookean_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => NeoHookean_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => NeoHookean_MatState_InitFromInputs
  END TYPE NeoHookean_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: NeoHookean_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => NeoHookean_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => NeoHookean_MatCtx_InitDefaults
  END TYPE NeoHookean_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: NeoHookean_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => NeoHookean_MatAlgo_InitDefaults
  END TYPE NeoHookean_MatAlgo

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MooneyRivlin_MatDesc
    REAL(wp) :: C10 = 0.0_wp, C01 = 0.0_wp, D1 = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => MooneyRivlin_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => MooneyRivlin_MatDesc_Valid
  END TYPE MooneyRivlin_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: MooneyRivlin_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => MooneyRivlin_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => MooneyRivlin_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => MooneyRivlin_MatState_InitFromInputs
  END TYPE MooneyRivlin_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: MooneyRivlin_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => MooneyRivlin_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => MooneyRivlin_MatCtx_InitDefaults
  END TYPE MooneyRivlin_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: MooneyRivlin_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => MooneyRivlin_MatAlgo_InitDefaults
  END TYPE MooneyRivlin_MatAlgo

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Ogden_MatDesc
    INTEGER(i4) :: n_terms = 3
    REAL(wp), ALLOCATABLE :: mu(:), alpha(:)
    REAL(wp) :: D1 = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Ogden_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Ogden_MatDesc_Valid
  END TYPE Ogden_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Ogden_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Ogden_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Ogden_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Ogden_MatState_InitFromInputs
  END TYPE Ogden_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Ogden_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Ogden_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Ogden_MatCtx_InitDefaults
  END TYPE Ogden_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Ogden_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Ogden_MatAlgo_InitDefaults
  END TYPE Ogden_MatAlgo

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Yeoh_MatDesc
    REAL(wp) :: C10 = 0.0_wp, C20 = 0.0_wp, C30 = 0.0_wp, D1 = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Yeoh_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Yeoh_MatDesc_Valid
  END TYPE Yeoh_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Yeoh_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Yeoh_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Yeoh_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Yeoh_MatState_InitFromInputs
  END TYPE Yeoh_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Yeoh_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Yeoh_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Yeoh_MatCtx_InitDefaults
  END TYPE Yeoh_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Yeoh_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Yeoh_MatAlgo_InitDefaults
  END TYPE Yeoh_MatAlgo

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: ArrudaBoyce_MatDesc
    REAL(wp) :: mu = 0.0_wp, lambda_m = 0.0_wp, D1 = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => ArrudaBoyce_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => ArrudaBoyce_MatDesc_Valid
  END TYPE ArrudaBoyce_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: ArrudaBoyce_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => ArrudaBoyce_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => ArrudaBoyce_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => ArrudaBoyce_MatState_InitFromInputs
  END TYPE ArrudaBoyce_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: ArrudaBoyce_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => ArrudaBoyce_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => ArrudaBoyce_MatCtx_InitDefaults
  END TYPE ArrudaBoyce_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: ArrudaBoyce_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => ArrudaBoyce_MatAlgo_InitDefaults
  END TYPE ArrudaBoyce_MatAlgo

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: DielectricElast_MatDesc
    REAL(wp) :: mu = 0.0_wp, lambda = 0.0_wp, epsilon_r = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => DielectricElast_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => DielectricElast_MatDesc_Valid
  END TYPE DielectricElast_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: DielectricElast_MatState
    REAL(wp) :: electric_displacement(3) = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => DielectricElast_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => DielectricElast_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => DielectricElast_MatState_InitFromInputs
  END TYPE DielectricElast_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: DielectricElast_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    REAL(wp) :: electric_field(3) = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => DielectricElast_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => DielectricElast_MatCtx_InitDefaults
  END TYPE DielectricElast_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: DielectricElast_MatAlgo
    INTEGER(i4) :: analysis_type = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => DielectricElast_MatAlgo_InitDefaults
  END TYPE DielectricElast_MatAlgo

CONTAINS

  !=============================================================================
  ! Hyperfoam Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Hyperfoam_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Hyperfoam_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, n_terms
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Hyperfoam_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%nTerms = MAX(1_i4, MIN(6_i4, INT(props(1))))
    this%poisson = props(2)
    n_terms = this%nTerms
    IF (.NOT. ALLOCATED(this%mu_i)) THEN
      ALLOCATE(this%mu_i(n_terms), this%alpha_i(n_terms), this%nu_i(n_terms))
    END IF
    DO i = 1, n_terms
      IF (nprops >= 2 + 3*i) THEN
        this%mu_i(i) = props(2 + 3*(i-1) + 1)
        this%alpha_i(i) = props(2 + 3*(i-1) + 2)
        this%nu_i(i) = props(2 + 3*(i-1) + 3)
      END IF
    END DO
    this%cfg%id = 451_i4
    this%name = "Hyperfoam"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 1
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Hyperfoam_MatDesc_InitFromProps

  FUNCTION Hyperfoam_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Hyperfoam_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%nTerms > 0
    IF (ALLOCATED(this%mu_i)) THEN
      is_valid = is_valid .AND. ALL(this%mu_i > ZERO)
    END IF
  END FUNCTION Hyperfoam_MatDesc_Valid

  SUBROUTINE Hyperfoam_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Hyperfoam_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (this%is_initialized .AND. nstatev >= 1) statev(1) = this%strain_energy
  END SUBROUTINE Hyperfoam_MatState_SyncToStateV

  SUBROUTINE Hyperfoam_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Hyperfoam_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (nstatev >= 1) THEN
      this%strain_energy = statev(1)
    ELSE
      this%strain_energy = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE Hyperfoam_MatState_SyncFromStateV

  SUBROUTINE Hyperfoam_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Hyperfoam_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF
    this%strain_energy = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE Hyperfoam_MatState_InitFromInputs

  SUBROUTINE Hyperfoam_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Hyperfoam_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE Hyperfoam_MatCtx_InitFromInputs

  SUBROUTINE Hyperfoam_MatCtx_InitDefaults(this)
    CLASS(Hyperfoam_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Hyperfoam_MatCtx_InitDefaults

  SUBROUTINE Hyperfoam_MatAlgo_InitDefaults(this)
    CLASS(Hyperfoam_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%moduliType = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Hyperfoam_MatAlgo_InitDefaults

  !=============================================================================
  ! Mullins Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Mullins_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Mullins_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Mullins_MatDesc: Insufficient properties (need at least 3)"
      RETURN
    END IF
    this%r_param = props(1)
    this%m_param = props(2)
    this%beta_perm = props(3)
    IF (nprops >= 4) this%base_model = INT(props(4))
    this%cfg%id = 451_i4
    this%name = "Mullins Effect"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 3
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Mullins_MatDesc_InitFromProps

  FUNCTION Mullins_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Mullins_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%r_param > ZERO .AND. this%m_param > ZERO
  END FUNCTION Mullins_MatDesc_Valid

  SUBROUTINE Mullins_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Mullins_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eta
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eta_min
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%W_max
    END IF
  END SUBROUTINE Mullins_MatState_SyncToStateV

  SUBROUTINE Mullins_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Mullins_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%eta = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eta = 1.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%eta_min = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eta_min = 1.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%W_max = statev(offset + 1)
    ELSE
      this%W_max = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE Mullins_MatState_SyncFromStateV

  SUBROUTINE Mullins_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Mullins_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF
    this%eta = 1.0_wp
    this%eta_min = 1.0_wp
    this%W_max = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE Mullins_MatState_InitFromInputs

  SUBROUTINE Mullins_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Mullins_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE Mullins_MatCtx_InitFromInputs

  SUBROUTINE Mullins_MatCtx_InitDefaults(this)
    CLASS(Mullins_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Mullins_MatCtx_InitDefaults

  SUBROUTINE Mullins_MatAlgo_InitDefaults(this)
    CLASS(Mullins_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%mullins_method = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Mullins_MatAlgo_InitDefaults

  !=============================================================================
  ! NeoHookean Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE NeoHookean_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(NeoHookean_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 2) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "NeoHookean_MatDesc: Insufficient properties (need at least 2)"
      RETURN
    END IF
    this%C10 = props(1)
    this%D1 = props(2)
    this%cfg%id = 301_i4
    this%name = "Neo-Hookean"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE NeoHookean_MatDesc_InitFromProps

  FUNCTION NeoHookean_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(NeoHookean_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%C10 > ZERO .AND. this%D1 > ZERO
  END FUNCTION NeoHookean_MatDesc_Valid

  SUBROUTINE NeoHookean_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(NeoHookean_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE NeoHookean_MatState_SyncToStateV

  SUBROUTINE NeoHookean_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(NeoHookean_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE NeoHookean_MatState_SyncFromStateV

  SUBROUTINE NeoHookean_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(NeoHookean_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE NeoHookean_MatState_InitFromInputs

  SUBROUTINE NeoHookean_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(NeoHookean_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE NeoHookean_MatCtx_InitFromInputs

  SUBROUTINE NeoHookean_MatCtx_InitDefaults(this)
    CLASS(NeoHookean_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE NeoHookean_MatCtx_InitDefaults

  SUBROUTINE NeoHookean_MatAlgo_InitDefaults(this)
    CLASS(NeoHookean_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE NeoHookean_MatAlgo_InitDefaults

  !=============================================================================
  ! MooneyRivlin Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE MooneyRivlin_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(MooneyRivlin_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MooneyRivlin_MatDesc: Insufficient properties (need at least 3)"
      RETURN
    END IF
    this%C10 = props(1)
    this%C01 = props(2)
    this%D1 = props(3)
    this%cfg%id = 302_i4
    this%name = "Mooney-Rivlin"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MooneyRivlin_MatDesc_InitFromProps

  FUNCTION MooneyRivlin_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(MooneyRivlin_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%C10 > ZERO .AND. this%D1 > ZERO
  END FUNCTION MooneyRivlin_MatDesc_Valid

  SUBROUTINE MooneyRivlin_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(MooneyRivlin_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE MooneyRivlin_MatState_SyncToStateV

  SUBROUTINE MooneyRivlin_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(MooneyRivlin_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE MooneyRivlin_MatState_SyncFromStateV

  SUBROUTINE MooneyRivlin_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(MooneyRivlin_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE MooneyRivlin_MatState_InitFromInputs

  SUBROUTINE MooneyRivlin_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(MooneyRivlin_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE MooneyRivlin_MatCtx_InitFromInputs

  SUBROUTINE MooneyRivlin_MatCtx_InitDefaults(this)
    CLASS(MooneyRivlin_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE MooneyRivlin_MatCtx_InitDefaults

  SUBROUTINE MooneyRivlin_MatAlgo_InitDefaults(this)
    CLASS(MooneyRivlin_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE MooneyRivlin_MatAlgo_InitDefaults

  !=============================================================================
  ! Ogden Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Ogden_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Ogden_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, n_terms
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 2) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Ogden_MatDesc: Insufficient properties (need at least 2)"
      RETURN
    END IF
    n_terms = MAX(1_i4, MIN(3_i4, INT(props(1))))
    this%n_terms = n_terms
    IF (.NOT. ALLOCATED(this%mu)) THEN
      ALLOCATE(this%mu(n_terms), this%alpha(n_terms))
    END IF
    DO i = 1, n_terms
      IF (nprops >= 1 + 2*i) THEN
        this%mu(i) = props(1 + 2*i - 1)
        this%alpha(i) = props(1 + 2*i)
      ELSE
        this%mu(i) = 0.0_wp
        this%alpha(i) = 0.0_wp
      END IF
    END DO
    IF (nprops >= 1 + 2*n_terms + 1) this%D1 = props(1 + 2*n_terms + 1)
    this%cfg%id = 303_i4
    this%name = "Ogden"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Ogden_MatDesc_InitFromProps

  FUNCTION Ogden_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Ogden_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized
    IF (ALLOCATED(this%mu)) THEN
      DO i = 1, SIZE(this%mu)
        IF (this%mu(i) <= ZERO) THEN
          is_valid = .FALSE.
          RETURN
        END IF
      END DO
    END IF
  END FUNCTION Ogden_MatDesc_Valid

  SUBROUTINE Ogden_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Ogden_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE Ogden_MatState_SyncToStateV

  SUBROUTINE Ogden_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Ogden_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE Ogden_MatState_SyncFromStateV

  SUBROUTINE Ogden_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Ogden_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE Ogden_MatState_InitFromInputs

  SUBROUTINE Ogden_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Ogden_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE Ogden_MatCtx_InitFromInputs

  SUBROUTINE Ogden_MatCtx_InitDefaults(this)
    CLASS(Ogden_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Ogden_MatCtx_InitDefaults

  SUBROUTINE Ogden_MatAlgo_InitDefaults(this)
    CLASS(Ogden_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Ogden_MatAlgo_InitDefaults

  !=============================================================================
  ! Yeoh Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Yeoh_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Yeoh_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Yeoh_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%C10 = props(1)
    this%C20 = props(2)
    this%C30 = props(3)
    this%D1 = props(4)
    this%cfg%id = 304_i4
    this%name = "Yeoh"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Yeoh_MatDesc_InitFromProps

  FUNCTION Yeoh_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Yeoh_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%C10 > ZERO .AND. this%D1 > ZERO
  END FUNCTION Yeoh_MatDesc_Valid

  SUBROUTINE Yeoh_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Yeoh_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE Yeoh_MatState_SyncToStateV

  SUBROUTINE Yeoh_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Yeoh_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE Yeoh_MatState_SyncFromStateV

  SUBROUTINE Yeoh_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Yeoh_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE Yeoh_MatState_InitFromInputs

  SUBROUTINE Yeoh_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Yeoh_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE Yeoh_MatCtx_InitFromInputs

  SUBROUTINE Yeoh_MatCtx_InitDefaults(this)
    CLASS(Yeoh_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Yeoh_MatCtx_InitDefaults

  SUBROUTINE Yeoh_MatAlgo_InitDefaults(this)
    CLASS(Yeoh_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Yeoh_MatAlgo_InitDefaults

  !=============================================================================
  ! ArrudaBoyce Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE ArrudaBoyce_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(ArrudaBoyce_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "ArrudaBoyce_MatDesc: Insufficient properties (need at least 3)"
      RETURN
    END IF
    this%mu = props(1)
    this%lambda_m = props(2)
    this%D1 = props(3)
    this%cfg%id = 305_i4
    this%name = "Arruda-Boyce"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE ArrudaBoyce_MatDesc_InitFromProps

  FUNCTION ArrudaBoyce_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(ArrudaBoyce_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%mu > ZERO .AND. this%lambda_m > ZERO .AND. this%D1 > ZERO
  END FUNCTION ArrudaBoyce_MatDesc_Valid

  SUBROUTINE ArrudaBoyce_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(ArrudaBoyce_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE ArrudaBoyce_MatState_SyncToStateV

  SUBROUTINE ArrudaBoyce_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(ArrudaBoyce_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE ArrudaBoyce_MatState_SyncFromStateV

  SUBROUTINE ArrudaBoyce_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(ArrudaBoyce_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE ArrudaBoyce_MatState_InitFromInputs

  SUBROUTINE ArrudaBoyce_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(ArrudaBoyce_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE ArrudaBoyce_MatCtx_InitFromInputs

  SUBROUTINE ArrudaBoyce_MatCtx_InitDefaults(this)
    CLASS(ArrudaBoyce_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE ArrudaBoyce_MatCtx_InitDefaults

  SUBROUTINE ArrudaBoyce_MatAlgo_InitDefaults(this)
    CLASS(ArrudaBoyce_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE ArrudaBoyce_MatAlgo_InitDefaults

  !=============================================================================
  ! DielectricElast Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE DielectricElast_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(DielectricElast_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "DielectricElast_MatDesc: Insufficient properties (need at least 3)"
      RETURN
    END IF
    this%mu = props(1)
    this%lambda = props(2)
    this%epsilon_r = props(3)
    this%cfg%id = 1002_i4
    this%name = "Dielectric Elastomer"
    this%cfg%class_id = MD_MAT_CATEGORY_MULTIPHYS
    this%pop%nProps = nprops
    this%pop%nStateV = 3
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE DielectricElast_MatDesc_InitFromProps

  FUNCTION DielectricElast_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(DielectricElast_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%mu > ZERO .AND. this%epsilon_r > ZERO
  END FUNCTION DielectricElast_MatDesc_Valid

  SUBROUTINE DielectricElast_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(DielectricElast_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    DO i = 1, MIN(3, SIZE(this%electric_displacement, 1), nstatev - offset)
      statev(offset + i) = this%electric_displacement(i)
      offset = offset + 1
    END DO
  END SUBROUTINE DielectricElast_MatState_SyncToStateV

  SUBROUTINE DielectricElast_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(DielectricElast_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    DO i = 1, MIN(3, SIZE(this%electric_displacement, 1), nstatev - offset)
      this%electric_displacement(i) = statev(offset + i)
      offset = offset + 1
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE DielectricElast_MatState_SyncFromStateV

  SUBROUTINE DielectricElast_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(DielectricElast_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (ALLOCATED(this%stress)) THEN
      IF (SIZE(this%stress) /= ntens) THEN
        DEALLOCATE(this%stress)
        ALLOCATE(this%stress(ntens))
        this%stress = 0.0_wp
      END IF
    ELSE
      ALLOCATE(this%stress(ntens))
      this%stress = 0.0_wp
    END IF
    this%electric_displacement = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE DielectricElast_MatState_InitFromInputs

  SUBROUTINE DielectricElast_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, electric_field, kstep, kinc)
    CLASS(DielectricElast_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime, electric_field(3)
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(electric_field)) this%electric_field = electric_field
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE DielectricElast_MatCtx_InitFromInputs

  SUBROUTINE DielectricElast_MatCtx_InitDefaults(this)
    CLASS(DielectricElast_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%electric_field = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE DielectricElast_MatCtx_InitDefaults

  SUBROUTINE DielectricElast_MatAlgo_InitDefaults(this)
    CLASS(DielectricElast_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%analysis_type = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE DielectricElast_MatAlgo_InitDefaults

END MODULE MD_Mat_Hyper_Contract
