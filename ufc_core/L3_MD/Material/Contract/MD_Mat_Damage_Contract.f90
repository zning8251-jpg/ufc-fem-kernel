!===============================================================================
! MODULE: MD_MatDMG_Def
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Damage family Desc/State/Ctx/Algo types.
!         Models: DuctileDmg, ThermalDmg, CreepDmg, CDP, Hashin,
!         DiffuseCrack, Puck, BrittleCrack, ProgressiveDmg.
!         **W1**：**MD_Mat_Desc** 子类 + **InitFromProps** ↔ **`props`** 布局；**Populate** 写入后映
!         L4 槽 **`desc%props`** / **PH_MAT_* 损伤族**（本模块仅类型合同）。
!===============================================================================

MODULE MD_Mat_Damage_Contract

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, MD_MAT_CATEGORY_DA, &
      MD_MAT_CATEGORY_CONCRETE, MD_MAT_CATEGORY_COMPOSITE

  IMPLICIT NONE
  PRIVATE

  !> @brief Ductile Damage material descriptor (Desc category)
  !! Johnson-Cook damage model
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: DuctileDmg_MatDesc
    REAL(wp) :: E = 0.0_wp                 ! Young's modulus
    REAL(wp) :: nu = 0.0_wp                ! Poisson's ratio
    REAL(wp) :: sigma_y = 0.0_wp          ! Yield strength
    REAL(wp) :: D1 = 0.0_wp               ! Damage parameter D1
    REAL(wp) :: D2 = 0.0_wp               ! Damage parameter D2
    REAL(wp) :: D3 = 0.0_wp               ! Damage parameter D3
    REAL(wp) :: D4 = 0.0_wp               ! Damage parameter D4
    REAL(wp) :: D5 = 0.0_wp               ! Damage parameter D5
    REAL(wp) :: eps_f0 = 0.0_wp          ! Reference failure strain
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => DuctileDmg_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => DuctileDmg_MatDesc_Valid
  END TYPE DuctileDmg_MatDesc

  !> @brief Ductile Damage material state (State category)
  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: DuctileDmg_MatState
    REAL(wp) :: damage_variable = 0.0_wp   ! Damage variable (0=no damage, 1=failure)
    REAL(wp) :: eps_p_eqv = 0.0_wp        ! Equivalent plastic strain
    REAL(wp) :: eps_f = 0.0_wp            ! Failure strain
    REAL(wp), ALLOCATABLE :: eps_p(:)     ! Plastic strain tensor (Voigt: 6 components)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => DuctileDmg_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => DuctileDmg_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => DuctileDmg_MatState_InitFromInputs
  END TYPE DuctileDmg_MatState

  !> @brief Ductile Damage material context (Ctx category)
  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: DuctileDmg_MatCtx
    INTEGER(i4) :: ndir = 3
    INTEGER(i4) :: nshr = 3
    INTEGER(i4) :: ntens = 6
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: strain_rate = 0.0_wp     ! Strain rate
    REAL(wp) :: dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0
    INTEGER(i4) :: kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => DuctileDmg_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => DuctileDmg_MatCtx_InitDefaults
  END TYPE DuctileDmg_MatCtx

  !> @brief Ductile Damage material algorithm (Algo category)
  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: DuctileDmg_MatAlgo
    INTEGER(i4) :: damage_evolution_method = 1  ! 1=Johnson-Cook
    REAL(wp) :: damage_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => DuctileDmg_MatAlgo_InitDefaults
  END TYPE DuctileDmg_MatAlgo

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: ThermalDmg_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: T_ref = 0.0_wp, T_crit = 0.0_wp
    REAL(wp) :: alpha = 0.0_wp, beta = 0.0_wp, alpha_T = 0.0_wp
    LOGICAL :: temp_history = .FALSE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => ThermalDmg_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => ThermalDmg_MatDesc_Valid
  END TYPE ThermalDmg_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: ThermalDmg_MatState
    REAL(wp) :: damage_variable = 0.0_wp
    REAL(wp) :: T_max = 0.0_wp, T_prev = 0.0_wp
    REAL(wp) :: T_rate = 0.0_wp, T_integral = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => ThermalDmg_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => ThermalDmg_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => ThermalDmg_MatState_InitFromInputs
  END TYPE ThermalDmg_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: ThermalDmg_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtemp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => ThermalDmg_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => ThermalDmg_MatCtx_InitDefaults
  END TYPE ThermalDmg_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: ThermalDmg_MatAlgo
    INTEGER(i4) :: damage_evolution_method = 1
    REAL(wp) :: damage_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => ThermalDmg_MatAlgo_InitDefaults
  END TYPE ThermalDmg_MatAlgo

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: CreepDmg_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, A = 0.0_wp, n = 0.0_wp, m = 0.0_wp, chi = 0.0_wp, sigma_ref = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => CreepDmg_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => CreepDmg_MatDesc_Valid
  END TYPE CreepDmg_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: CreepDmg_MatState
    REAL(wp) :: damage_variable = 0.0_wp, eps_c_eqv = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => CreepDmg_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => CreepDmg_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => CreepDmg_MatState_InitFromInputs
  END TYPE CreepDmg_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: CreepDmg_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => CreepDmg_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => CreepDmg_MatCtx_InitDefaults
  END TYPE CreepDmg_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: CreepDmg_MatAlgo
    INTEGER(i4) :: damage_evolution_method = 1
    REAL(wp) :: damage_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => CreepDmg_MatAlgo_InitDefaults
  END TYPE CreepDmg_MatAlgo

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: CDP_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, fb0_fc0 = 1.16_wp, Kc = 0.667_wp
    REAL(wp) :: mu_visc = 0.0_wp, dilation = 30.0_wp, eccentricity = 0.1_wp, Gf = 0.0_wp
    INTEGER(i4) :: n_comp = 0, n_tens = 0
    REAL(wp), ALLOCATABLE :: stress_c(:), eps_c_in(:), stress_t(:), eps_t_ck(:)
    LOGICAL :: tension_stiffening = .FALSE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => CDP_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => CDP_MatDesc_Valid
  END TYPE CDP_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: CDP_MatState
    REAL(wp) :: d_t = 0.0_wp, d_c = 0.0_wp
    REAL(wp) :: eps_t_ck_eqv = 0.0_wp, eps_c_in_eqv = 0.0_wp
    REAL(wp), ALLOCATABLE :: eps_p(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => CDP_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => CDP_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => CDP_MatState_InitFromInputs
  END TYPE CDP_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: CDP_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => CDP_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => CDP_MatCtx_InitDefaults
  END TYPE CDP_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: CDP_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => CDP_MatAlgo_InitDefaults
  END TYPE CDP_MatAlgo

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Hashin_MatDesc
    REAL(wp) :: E1 = 0.0_wp, E2 = 0.0_wp, nu12 = 0.0_wp, G12 = 0.0_wp
    REAL(wp) :: X_T = 0.0_wp, X_C = 0.0_wp, Y_T = 0.0_wp, Y_C = 0.0_wp, S_L = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Hashin_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Hashin_MatDesc_Valid
  END TYPE Hashin_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Hashin_MatState
    REAL(wp) :: damage_fiber_t = 0.0_wp, damage_fiber_c = 0.0_wp
    REAL(wp) :: damage_matrix_t = 0.0_wp, damage_matrix_c = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Hashin_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Hashin_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Hashin_MatState_InitFromInputs
  END TYPE Hashin_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Hashin_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Hashin_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Hashin_MatCtx_InitDefaults
  END TYPE Hashin_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Hashin_MatAlgo
    INTEGER(i4) :: failure_criterion = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Hashin_MatAlgo_InitDefaults
  END TYPE Hashin_MatAlgo

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: DiffuseCrack_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, ft = 0.0_wp, Gf = 0.0_wp
    REAL(wp) :: beta_shear = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => DiffuseCrack_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => DiffuseCrack_MatDesc_Valid
  END TYPE DiffuseCrack_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: DiffuseCrack_MatState
    REAL(wp) :: crack_strain(6) = 0.0_wp
    INTEGER(i4) :: n_cracks = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => DiffuseCrack_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => DiffuseCrack_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => DiffuseCrack_MatState_InitFromInputs
  END TYPE DiffuseCrack_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: DiffuseCrack_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => DiffuseCrack_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => DiffuseCrack_MatCtx_InitDefaults
  END TYPE DiffuseCrack_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: DiffuseCrack_MatAlgo
    INTEGER(i4) :: crack_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => DiffuseCrack_MatAlgo_InitDefaults
  END TYPE DiffuseCrack_MatAlgo

  !=============================================================================

  ! Puck Failure (Composite)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Puck_MatDesc
    REAL(wp) :: E1 = 0.0_wp, E2 = 0.0_wp, nu12 = 0.0_wp, G12 = 0.0_wp
    REAL(wp) :: R_para_t = 0.0_wp, R_para_c = 0.0_wp, R_perp_t = 0.0_wp, R_perp_c = 0.0_wp, R_perp_s = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Puck_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Puck_MatDesc_Valid
  END TYPE Puck_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Puck_MatState
    REAL(wp) :: damage_IFF = 0.0_wp, damage_FF = 0.0_wp, theta_fp = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Puck_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Puck_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Puck_MatState_InitFromInputs
  END TYPE Puck_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Puck_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Puck_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Puck_MatCtx_InitDefaults
  END TYPE Puck_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Puck_MatAlgo
    INTEGER(i4) :: failure_criterion = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Puck_MatAlgo_InitDefaults
  END TYPE Puck_MatAlgo

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: BrittleCrack_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, ft = 0.0_wp, Gf = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => BrittleCrack_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => BrittleCrack_MatDesc_Valid
  END TYPE BrittleCrack_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: BrittleCrack_MatState
    REAL(wp) :: crack_opening = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => BrittleCrack_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => BrittleCrack_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => BrittleCrack_MatState_InitFromInputs
  END TYPE BrittleCrack_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: BrittleCrack_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => BrittleCrack_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => BrittleCrack_MatCtx_InitDefaults
  END TYPE BrittleCrack_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: BrittleCrack_MatAlgo
    INTEGER(i4) :: crack_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => BrittleCrack_MatAlgo_InitDefaults
  END TYPE BrittleCrack_MatAlgo

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: ProgressiveDmg_MatDesc
    REAL(wp) :: E1 = 0.0_wp, E2 = 0.0_wp, nu12 = 0.0_wp, G12 = 0.0_wp
    REAL(wp) :: X_T = 0.0_wp, X_C = 0.0_wp, Y_T = 0.0_wp, Y_C = 0.0_wp, S_L = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => ProgressiveDmg_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => ProgressiveDmg_MatDesc_Valid
  END TYPE ProgressiveDmg_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: ProgressiveDmg_MatState
    REAL(wp) :: damage_fiber = 0.0_wp, damage_matrix = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => ProgressiveDmg_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => ProgressiveDmg_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => ProgressiveDmg_MatState_InitFromInputs
  END TYPE ProgressiveDmg_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: ProgressiveDmg_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => ProgressiveDmg_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => ProgressiveDmg_MatCtx_InitDefaults
  END TYPE ProgressiveDmg_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: ProgressiveDmg_MatAlgo
    INTEGER(i4) :: damage_evolution_law = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => ProgressiveDmg_MatAlgo_InitDefaults
  END TYPE ProgressiveDmg_MatAlgo

CONTAINS

  !=============================================================================
  ! DuctileDmg Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE DuctileDmg_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(DuctileDmg_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    CALL init_error_status(status)

    IF (nprops < 8) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "DuctileDmg_MatDesc: Insufficient properties (need at least 8)"
      RETURN
    END IF

    this%E = props(1)
    this%nu = props(2)
    this%sigma_y = props(3)
    this%D1 = props(4)
    this%D2 = props(5)
    this%D3 = props(6)
    this%D4 = props(7)
    this%D5 = props(8)

    IF (nprops >= 9) THEN
      this%eps_f0 = props(9)
    ELSE
      this%eps_f0 = 0.0_wp
    END IF

    ! Set base class fields
    this%cfg%id = 501_i4  ! MD_MAT_DUCTILE_DAMAGE
    this%name = "Ductile Damage (Johnson-Cook)"
    this%cfg%class_id = MD_MAT_CATEGORY_DA
    this%pop%nProps = nprops
    this%pop%nStateV = 9  ! damage(1) + eps_p_eqv(1) + eps_f(1) + eps_p(6)

    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props

    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE DuctileDmg_MatDesc_InitFromProps

  FUNCTION DuctileDmg_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(DuctileDmg_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid

    REAL(wp), PARAMETER :: ZERO = 0.0_wp

    is_valid = .TRUE.

    IF (.NOT. this%is_initialized) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    IF (this%E <= ZERO .OR. this%sigma_y <= ZERO) THEN
      is_valid = .FALSE.
      RETURN
    END IF

  END FUNCTION DuctileDmg_MatDesc_Valid

  !=============================================================================
  ! DuctileDmg_MatState Type-Bound Procedures
  !=============================================================================

  SUBROUTINE DuctileDmg_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(DuctileDmg_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p, offset

    IF (.NOT. this%is_initialized) RETURN

    offset = 0

    ! Store damage variable
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_variable
      offset = offset + 1
    END IF

    ! Store equivalent plastic strain
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_p_eqv
      offset = offset + 1
    END IF

    ! Store failure strain
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_f
      offset = offset + 1
    END IF

    ! Store plastic strain components
    n_eps_p = MIN(6, SIZE(this%eps_p, 1))
    DO i = 1, MIN(n_eps_p, nstatev - offset)
      statev(offset + i) = this%eps_p(i)
    END DO

  END SUBROUTINE DuctileDmg_MatState_SyncToStateV

  SUBROUTINE DuctileDmg_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(DuctileDmg_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev

    INTEGER(i4) :: i, n_eps_p, offset

    offset = 0

    IF (nstatev >= offset + 1) THEN
      this%damage_variable = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_variable = 0.0_wp
    END IF

    IF (nstatev >= offset + 1) THEN
      this%eps_p_eqv = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_p_eqv = 0.0_wp
    END IF

    IF (nstatev >= offset + 1) THEN
      this%eps_f = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_f = 0.0_wp
    END IF

    n_eps_p = MIN(6, nstatev - offset)

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF

    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(offset + i)
    END DO

    this%is_initialized = .TRUE.

  END SUBROUTINE DuctileDmg_MatState_SyncFromStateV

  SUBROUTINE DuctileDmg_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(DuctileDmg_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr

    INTEGER(i4) :: ntens

    ntens = ndir + nshr

    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(ntens))
      this%eps_p = 0.0_wp
    END IF

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

    this%damage_variable = 0.0_wp
    this%eps_p_eqv = 0.0_wp
    this%eps_f = 0.0_wp
    this%is_initialized = .TRUE.

  END SUBROUTINE DuctileDmg_MatState_InitFromInputs

  !=============================================================================
  ! DuctileDmg_MatCtx Type-Bound Procedures
  !=============================================================================

  SUBROUTINE DuctileDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, strain_rate, dtime, kstep, kinc)
    CLASS(DuctileDmg_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, strain_rate, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc

    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr

    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(strain_rate)) this%strain_rate = strain_rate
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc

    this%is_initialized = .TRUE.

  END SUBROUTINE DuctileDmg_MatCtx_InitFromInputs

  SUBROUTINE DuctileDmg_MatCtx_InitDefaults(this)
    CLASS(DuctileDmg_MatCtx), INTENT(INOUT) :: this

    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%strain_rate = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.

  END SUBROUTINE DuctileDmg_MatCtx_InitDefaults

  !=============================================================================
  ! DuctileDmg_MatAlgo Type-Bound Procedures
  !=============================================================================

  SUBROUTINE DuctileDmg_MatAlgo_InitDefaults(this)
    CLASS(DuctileDmg_MatAlgo), INTENT(INOUT) :: this

    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%damage_evolution_method = 1  ! Johnson-Cook
    this%damage_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.

  END SUBROUTINE DuctileDmg_MatAlgo_InitDefaults

  !=============================================================================
  ! ThermalDmg Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE ThermalDmg_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(ThermalDmg_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 6) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "ThermalDmg_MatDesc: Insufficient properties (need at least 6)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%T_ref = props(3)
    this%T_crit = props(4)
    this%alpha = props(5)
    this%beta = props(6)
    IF (nprops >= 7) this%alpha_T = props(7)
    IF (nprops >= 8) this%temp_history = (props(8) > 0.5_wp)
    this%cfg%id = 551_i4
    this%name = "Thermal Damage"
    this%cfg%class_id = MD_MAT_CATEGORY_DA
    this%pop%nProps = nprops
    this%pop%nStateV = 5
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE ThermalDmg_MatDesc_InitFromProps

  FUNCTION ThermalDmg_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(ThermalDmg_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%T_crit > this%T_ref
  END FUNCTION ThermalDmg_MatDesc_Valid

  SUBROUTINE ThermalDmg_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(ThermalDmg_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_variable
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%T_max
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%T_prev
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%T_rate
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%T_integral
    END IF
  END SUBROUTINE ThermalDmg_MatState_SyncToStateV

  SUBROUTINE ThermalDmg_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(ThermalDmg_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%damage_variable = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_variable = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%T_max = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%T_max = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%T_prev = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%T_prev = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%T_rate = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%T_rate = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%T_integral = statev(offset + 1)
    ELSE
      this%T_integral = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermalDmg_MatState_SyncFromStateV

  SUBROUTINE ThermalDmg_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(ThermalDmg_MatState), INTENT(INOUT) :: this
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
    this%damage_variable = 0.0_wp
    this%T_max = 0.0_wp
    this%T_prev = 0.0_wp
    this%T_rate = 0.0_wp
    this%T_integral = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermalDmg_MatState_InitFromInputs

  SUBROUTINE ThermalDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtemp, dtime, kstep, kinc)
    CLASS(ThermalDmg_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtemp, dtime
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtemp)) this%dtemp = dtemp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermalDmg_MatCtx_InitFromInputs

  SUBROUTINE ThermalDmg_MatCtx_InitDefaults(this)
    CLASS(ThermalDmg_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtemp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermalDmg_MatCtx_InitDefaults

  SUBROUTINE ThermalDmg_MatAlgo_InitDefaults(this)
    CLASS(ThermalDmg_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%damage_evolution_method = 1
    this%damage_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermalDmg_MatAlgo_InitDefaults

  !=============================================================================
  ! CreepDmg Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE CreepDmg_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(CreepDmg_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 6) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "CreepDmg_MatDesc: Insufficient properties (need at least 6)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%A = props(3)
    this%n = props(4)
    this%m = props(5)
    this%chi = props(6)
    IF (nprops >= 7) this%sigma_ref = props(7)
    this%cfg%id = 541_i4
    this%name = "Creep Damage (Kachanov-Rabotnov)"
    this%cfg%class_id = MD_MAT_CATEGORY_DA
    this%pop%nProps = nprops
    this%pop%nStateV = 2
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE CreepDmg_MatDesc_InitFromProps

  FUNCTION CreepDmg_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(CreepDmg_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%A > ZERO .AND. this%n > ZERO
  END FUNCTION CreepDmg_MatDesc_Valid

  SUBROUTINE CreepDmg_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(CreepDmg_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_variable
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_c_eqv
    END IF
  END SUBROUTINE CreepDmg_MatState_SyncToStateV

  SUBROUTINE CreepDmg_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(CreepDmg_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%damage_variable = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_variable = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%eps_c_eqv = statev(offset + 1)
    ELSE
      this%eps_c_eqv = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE CreepDmg_MatState_SyncFromStateV

  SUBROUTINE CreepDmg_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(CreepDmg_MatState), INTENT(INOUT) :: this
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
    this%damage_variable = 0.0_wp
    this%eps_c_eqv = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE CreepDmg_MatState_InitFromInputs

  SUBROUTINE CreepDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(CreepDmg_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE CreepDmg_MatCtx_InitFromInputs

  SUBROUTINE CreepDmg_MatCtx_InitDefaults(this)
    CLASS(CreepDmg_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE CreepDmg_MatCtx_InitDefaults

  SUBROUTINE CreepDmg_MatAlgo_InitDefaults(this)
    CLASS(CreepDmg_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%damage_evolution_method = 1
    this%damage_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE CreepDmg_MatAlgo_InitDefaults

  !=============================================================================
  ! CDP Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE CDP_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(CDP_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 7) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "CDP_MatDesc: Insufficient properties (need at least 7)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%fb0_fc0 = props(3)
    this%Kc = props(4)
    this%mu_visc = props(5)
    this%dilation = props(6)
    this%eccentricity = props(7)
    IF (nprops >= 8) this%Gf = props(8)
    this%cfg%id = 700_i4
    this%name = "Concrete Damaged Plasticity"
    this%cfg%class_id = MD_MAT_CATEGORY_CONCRETE
    this%pop%nProps = nprops
    this%pop%nStateV = 10
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE CDP_MatDesc_InitFromProps

  FUNCTION CDP_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(CDP_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%Kc > 0.5_wp .AND. this%Kc < 1.0_wp
  END FUNCTION CDP_MatDesc_Valid

  SUBROUTINE CDP_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(CDP_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_p, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%d_t
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%d_c
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_t_ck_eqv
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_c_in_eqv
      offset = offset + 1
    END IF
    n_eps_p = MIN(6, SIZE(this%eps_p, 1))
    DO i = 1, MIN(n_eps_p, nstatev - offset)
      statev(offset + i) = this%eps_p(i)
    END DO
  END SUBROUTINE CDP_MatState_SyncToStateV

  SUBROUTINE CDP_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(CDP_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_p, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%d_t = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%d_t = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%d_c = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%d_c = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%eps_t_ck_eqv = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_t_ck_eqv = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%eps_c_in_eqv = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_c_in_eqv = 0.0_wp
    END IF
    n_eps_p = MIN(6, nstatev - offset)
    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF
    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(offset + i)
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE CDP_MatState_SyncFromStateV

  SUBROUTINE CDP_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(CDP_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(ntens))
      this%eps_p = 0.0_wp
    END IF
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
    this%d_t = 0.0_wp
    this%d_c = 0.0_wp
    this%eps_t_ck_eqv = 0.0_wp
    this%eps_c_in_eqv = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE CDP_MatState_InitFromInputs

  SUBROUTINE CDP_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(CDP_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE CDP_MatCtx_InitFromInputs

  SUBROUTINE CDP_MatCtx_InitDefaults(this)
    CLASS(CDP_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE CDP_MatCtx_InitDefaults

  SUBROUTINE CDP_MatAlgo_InitDefaults(this)
    CLASS(CDP_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE CDP_MatAlgo_InitDefaults

  !=============================================================================
  ! Hashin Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Hashin_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Hashin_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 9) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Hashin_MatDesc: Insufficient properties (need at least 9)"
      RETURN
    END IF
    this%E1 = props(1)
    this%E2 = props(2)
    this%nu12 = props(3)
    this%G12 = props(4)
    this%X_T = props(5)
    this%X_C = props(6)
    this%Y_T = props(7)
    this%Y_C = props(8)
    this%S_L = props(9)
    this%cfg%id = 904_i4
    this%name = "Hashin Progressive Failure"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 4
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Hashin_MatDesc_InitFromProps

  FUNCTION Hashin_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Hashin_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E1 > ZERO .AND. this%E2 > ZERO .AND. &
               this%X_T > ZERO .AND. this%Y_T > ZERO .AND. this%S_L > ZERO
  END FUNCTION Hashin_MatDesc_Valid

  SUBROUTINE Hashin_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Hashin_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_fiber_t
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_fiber_c
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_matrix_t
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_matrix_c
    END IF
  END SUBROUTINE Hashin_MatState_SyncToStateV

  SUBROUTINE Hashin_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Hashin_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%damage_fiber_t = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_fiber_t = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%damage_fiber_c = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_fiber_c = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%damage_matrix_t = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_matrix_t = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%damage_matrix_c = statev(offset + 1)
    ELSE
      this%damage_matrix_c = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE Hashin_MatState_SyncFromStateV

  SUBROUTINE Hashin_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Hashin_MatState), INTENT(INOUT) :: this
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
    this%damage_fiber_t = 0.0_wp
    this%damage_fiber_c = 0.0_wp
    this%damage_matrix_t = 0.0_wp
    this%damage_matrix_c = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE Hashin_MatState_InitFromInputs

  SUBROUTINE Hashin_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Hashin_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Hashin_MatCtx_InitFromInputs

  SUBROUTINE Hashin_MatCtx_InitDefaults(this)
    CLASS(Hashin_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Hashin_MatCtx_InitDefaults

  SUBROUTINE Hashin_MatAlgo_InitDefaults(this)
    CLASS(Hashin_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%failure_criterion = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Hashin_MatAlgo_InitDefaults

  !=============================================================================
  ! DiffuseCrack Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE DiffuseCrack_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(DiffuseCrack_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "DiffuseCrack_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%ft = props(3)
    this%Gf = props(4)
    IF (nprops >= 5) this%beta_shear = props(5)
    this%cfg%id = 701_i4
    this%name = "Diffuse Smeared Cracking"
    this%cfg%class_id = MD_MAT_CATEGORY_CONCRETE
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE DiffuseCrack_MatDesc_InitFromProps

  FUNCTION DiffuseCrack_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(DiffuseCrack_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%ft > ZERO .AND. this%Gf > ZERO
  END FUNCTION DiffuseCrack_MatDesc_Valid

  SUBROUTINE DiffuseCrack_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(DiffuseCrack_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = REAL(this%n_cracks, wp)
      offset = offset + 1
    END IF
    DO i = 1, MIN(6, SIZE(this%crack_strain, 1), nstatev - offset)
      statev(offset + i) = this%crack_strain(i)
    END DO
  END SUBROUTINE DiffuseCrack_MatState_SyncToStateV

  SUBROUTINE DiffuseCrack_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(DiffuseCrack_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%n_cracks = INT(statev(offset + 1))
      offset = offset + 1
    ELSE
      this%n_cracks = 0
    END IF
    DO i = 1, MIN(6, SIZE(this%crack_strain, 1), nstatev - offset)
      this%crack_strain(i) = statev(offset + i)
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE DiffuseCrack_MatState_SyncFromStateV

  SUBROUTINE DiffuseCrack_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(DiffuseCrack_MatState), INTENT(INOUT) :: this
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
    this%crack_strain = 0.0_wp
    this%n_cracks = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE DiffuseCrack_MatState_InitFromInputs

  SUBROUTINE DiffuseCrack_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(DiffuseCrack_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE DiffuseCrack_MatCtx_InitFromInputs

  SUBROUTINE DiffuseCrack_MatCtx_InitDefaults(this)
    CLASS(DiffuseCrack_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE DiffuseCrack_MatCtx_InitDefaults

  SUBROUTINE DiffuseCrack_MatAlgo_InitDefaults(this)
    CLASS(DiffuseCrack_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%crack_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE DiffuseCrack_MatAlgo_InitDefaults

  !=============================================================================
  ! Puck Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Puck_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Puck_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 9) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Puck_MatDesc: Insufficient properties (need at least 9)"
      RETURN
    END IF
    this%E1 = props(1)
    this%E2 = props(2)
    this%nu12 = props(3)
    this%G12 = props(4)
    this%R_para_t = props(5)
    this%R_para_c = props(6)
    this%R_perp_t = props(7)
    this%R_perp_c = props(8)
    this%R_perp_s = props(9)
    this%cfg%id = 905_i4
    this%name = "Puck Progressive Failure"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 3
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Puck_MatDesc_InitFromProps

  FUNCTION Puck_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Puck_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E1 > ZERO .AND. this%E2 > ZERO .AND. &
               this%R_para_t > ZERO .AND. this%R_perp_t > ZERO
  END FUNCTION Puck_MatDesc_Valid

  SUBROUTINE Puck_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Puck_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_IFF
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_FF
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%theta_fp
    END IF
  END SUBROUTINE Puck_MatState_SyncToStateV

  SUBROUTINE Puck_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Puck_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%damage_IFF = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_IFF = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%damage_FF = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_FF = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%theta_fp = statev(offset + 1)
    ELSE
      this%theta_fp = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE Puck_MatState_SyncFromStateV

  SUBROUTINE Puck_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Puck_MatState), INTENT(INOUT) :: this
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
    this%damage_IFF = 0.0_wp
    this%damage_FF = 0.0_wp
    this%theta_fp = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE Puck_MatState_InitFromInputs

  SUBROUTINE Puck_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Puck_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Puck_MatCtx_InitFromInputs

  SUBROUTINE Puck_MatCtx_InitDefaults(this)
    CLASS(Puck_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Puck_MatCtx_InitDefaults

  SUBROUTINE Puck_MatAlgo_InitDefaults(this)
    CLASS(Puck_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%failure_criterion = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Puck_MatAlgo_InitDefaults

  !=============================================================================
  ! BrittleCrack Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE BrittleCrack_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(BrittleCrack_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "BrittleCrack_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%ft = props(3)
    this%Gf = props(4)
    this%cfg%id = 702_i4
    this%name = "Brittle Cracking"
    this%cfg%class_id = MD_MAT_CATEGORY_CONCRETE
    this%pop%nProps = nprops
    this%pop%nStateV = 1
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE BrittleCrack_MatDesc_InitFromProps

  FUNCTION BrittleCrack_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(BrittleCrack_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%ft > ZERO .AND. this%Gf > ZERO
  END FUNCTION BrittleCrack_MatDesc_Valid

  SUBROUTINE BrittleCrack_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(BrittleCrack_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (this%is_initialized .AND. nstatev >= 1) statev(1) = this%crack_opening
  END SUBROUTINE BrittleCrack_MatState_SyncToStateV

  SUBROUTINE BrittleCrack_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(BrittleCrack_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (nstatev >= 1) THEN
      this%crack_opening = statev(1)
    ELSE
      this%crack_opening = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE BrittleCrack_MatState_SyncFromStateV

  SUBROUTINE BrittleCrack_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(BrittleCrack_MatState), INTENT(INOUT) :: this
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
    this%crack_opening = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE BrittleCrack_MatState_InitFromInputs

  SUBROUTINE BrittleCrack_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(BrittleCrack_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE BrittleCrack_MatCtx_InitFromInputs

  SUBROUTINE BrittleCrack_MatCtx_InitDefaults(this)
    CLASS(BrittleCrack_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE BrittleCrack_MatCtx_InitDefaults

  SUBROUTINE BrittleCrack_MatAlgo_InitDefaults(this)
    CLASS(BrittleCrack_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%crack_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE BrittleCrack_MatAlgo_InitDefaults

  !=============================================================================
  ! ProgressiveDmg Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE ProgressiveDmg_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(ProgressiveDmg_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 9) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "ProgressiveDmg_MatDesc: Insufficient properties (need at least 9)"
      RETURN
    END IF
    this%E1 = props(1)
    this%E2 = props(2)
    this%nu12 = props(3)
    this%G12 = props(4)
    this%X_T = props(5)
    this%X_C = props(6)
    this%Y_T = props(7)
    this%Y_C = props(8)
    this%S_L = props(9)
    this%cfg%id = 908_i4
    this%name = "Progressive Damage Model"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 2
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE ProgressiveDmg_MatDesc_InitFromProps

  FUNCTION ProgressiveDmg_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(ProgressiveDmg_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E1 > ZERO .AND. this%E2 > ZERO .AND. &
               this%X_T > ZERO .AND. this%Y_T > ZERO .AND. this%S_L > ZERO
  END FUNCTION ProgressiveDmg_MatDesc_Valid

  SUBROUTINE ProgressiveDmg_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(ProgressiveDmg_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_fiber
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_matrix
    END IF
  END SUBROUTINE ProgressiveDmg_MatState_SyncToStateV

  SUBROUTINE ProgressiveDmg_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(ProgressiveDmg_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%damage_fiber = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_fiber = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%damage_matrix = statev(offset + 1)
    ELSE
      this%damage_matrix = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE ProgressiveDmg_MatState_SyncFromStateV

  SUBROUTINE ProgressiveDmg_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(ProgressiveDmg_MatState), INTENT(INOUT) :: this
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
    this%damage_fiber = 0.0_wp
    this%damage_matrix = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE ProgressiveDmg_MatState_InitFromInputs

  SUBROUTINE ProgressiveDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(ProgressiveDmg_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE ProgressiveDmg_MatCtx_InitFromInputs

  SUBROUTINE ProgressiveDmg_MatCtx_InitDefaults(this)
    CLASS(ProgressiveDmg_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE ProgressiveDmg_MatCtx_InitDefaults

  SUBROUTINE ProgressiveDmg_MatAlgo_InitDefaults(this)
    CLASS(ProgressiveDmg_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%damage_evolution_law = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE ProgressiveDmg_MatAlgo_InitDefaults

END MODULE MD_Mat_Damage_Contract
