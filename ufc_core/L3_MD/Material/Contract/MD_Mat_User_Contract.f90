!===============================================================================
! MODULE: MD_MatSPU_Def
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Special/User family Desc/State/Ctx/Algo types.
!         Models: Creep, Composite, MultiPhys, Foam, GeoMat, UMAT, etc.
!         **W1**：大类合同分包；各 **`*_MatDesc`** 仍循 **InitFromProps** / **`props`**→**Populate**→L4 **`desc%props`**。
!===============================================================================

MODULE MD_Mat_User_Contract

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatAlgo, &
    MD_MAT_CATEGORY_CR, MD_MAT_CATEGORY_CO, MD_MAT_CATEGORY_COMPOSITE, MD_MAT_CATEGORY_MULTIPHYS, MD_MAT_CATEGORY_FOAM, MD_MAT_CATEGORY_GEOMAT, &
    MD_MAT_CATEGORY_CONCRETE, MD_MAT_CATEGORY_VI, MD_MAT_CATEGORY_HY, MD_MAT_CATEGORY_DA

  IMPLICIT NONE
  PRIVATE

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: NortonCreep_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: A = 0.0_wp, n = 0.0_wp, Q = 0.0_wp
    REAL(wp) :: T_ref = 293.15_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => NortonCreep_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => NortonCreep_MatDesc_Valid
  END TYPE NortonCreep_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: NortonCreep_MatState
    REAL(wp) :: eps_c_eqv = 0.0_wp
    REAL(wp), ALLOCATABLE :: eps_c(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => NortonCreep_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => NortonCreep_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => NortonCreep_MatState_InitFromInputs
  END TYPE NortonCreep_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: NortonCreep_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => NortonCreep_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => NortonCreep_MatCtx_InitDefaults
  END TYPE NortonCreep_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: NortonCreep_MatAlgo
    INTEGER(i4) :: creep_method = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => NortonCreep_MatAlgo_InitDefaults
  END TYPE NortonCreep_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: GarofaloCreep_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, A = 0.0_wp, n = 0.0_wp, alpha = 0.0_wp, Q = 0.0_wp, T_ref = 293.15_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => GarofaloCreep_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => GarofaloCreep_MatDesc_Valid
  END TYPE GarofaloCreep_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: GarofaloCreep_MatState
    REAL(wp) :: eps_c_eqv = 0.0_wp
    REAL(wp), ALLOCATABLE :: eps_c(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => GarofaloCreep_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => GarofaloCreep_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => GarofaloCreep_MatState_InitFromInputs
  END TYPE GarofaloCreep_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: GarofaloCreep_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => GarofaloCreep_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => GarofaloCreep_MatCtx_InitDefaults
  END TYPE GarofaloCreep_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: GarofaloCreep_MatAlgo
    INTEGER(i4) :: creep_method = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => GarofaloCreep_MatAlgo_InitDefaults
  END TYPE GarofaloCreep_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: CompLamina_MatDesc
    REAL(wp) :: E1 = 0.0_wp, E2 = 0.0_wp, nu12 = 0.0_wp, G12 = 0.0_wp, G13 = 0.0_wp, G23 = 0.0_wp
    REAL(wp) :: Q(3,3) = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => CompLamina_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => CompLamina_MatDesc_Valid
  END TYPE CompLamina_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: CompLamina_MatState
    REAL(wp) :: strain_energy = 0.0_wp
    REAL(wp) :: damage_fiber = 0.0_wp, damage_matrix = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => CompLamina_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => CompLamina_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => CompLamina_MatState_InitFromInputs
  END TYPE CompLamina_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: CompLamina_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => CompLamina_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => CompLamina_MatCtx_InitDefaults
  END TYPE CompLamina_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: CompLamina_MatAlgo
    INTEGER(i4) :: failure_criterion = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => CompLamina_MatAlgo_InitDefaults
  END TYPE CompLamina_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MCC_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, kappa = 0.0_wp, lambda = 0.0_wp, M = 0.0_wp
    REAL(wp) :: e0 = 0.0_wp, p_c0 = 0.0_wp, beta_cap = 1.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => MCC_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => MCC_MatDesc_Valid
  END TYPE MCC_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: MCC_MatState
    REAL(wp) :: p_c = 0.0_wp, eps_v_eqv = 0.0_wp
    REAL(wp), ALLOCATABLE :: eps_p(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => MCC_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => MCC_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => MCC_MatState_InitFromInputs
  END TYPE MCC_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: MCC_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => MCC_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => MCC_MatCtx_InitDefaults
  END TYPE MCC_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: MCC_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_substepping = .TRUE.
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => MCC_MatAlgo_InitDefaults
  END TYPE MCC_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: SMA_MatDesc
    REAL(wp) :: MD_MAT_E_A = 0.0_wp, MD_MAT_E_M = 0.0_wp, nu_A = 0.0_wp, nu_M = 0.0_wp
    REAL(wp) :: H_sat = 0.0_wp, stress_s = 0.0_wp, stress_f = 0.0_wp
    REAL(wp) :: T_ref = 298.15_wp, beta_A = 0.0_wp, beta_M = 0.0_wp
    LOGICAL :: superelastic = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => SMA_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => SMA_MatDesc_Valid
  END TYPE SMA_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: SMA_MatState
    REAL(wp) :: xi = 0.0_wp
    REAL(wp), ALLOCATABLE :: eps_tr(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => SMA_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => SMA_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => SMA_MatState_InitFromInputs
  END TYPE SMA_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: SMA_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => SMA_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => SMA_MatCtx_InitDefaults
  END TYPE SMA_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: SMA_MatAlgo
    INTEGER(i4) :: transformation_method = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => SMA_MatAlgo_InitDefaults
  END TYPE SMA_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: CrushFoam_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, sigma_c0 = 0.0_wp, sigma_t0 = 0.0_wp, k_factor = 0.0_wp
    INTEGER(i4) :: n_hard = 0
    REAL(wp), ALLOCATABLE :: stress_c_hard(:), eps_vol_hard(:)
    LOGICAL :: use_kinematic_hardening = .FALSE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => CrushFoam_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => CrushFoam_MatDesc_Valid
  END TYPE CrushFoam_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: CrushFoam_MatState
    REAL(wp) :: eps_vol_pl = 0.0_wp
    REAL(wp), ALLOCATABLE :: eps_p(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => CrushFoam_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => CrushFoam_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => CrushFoam_MatState_InitFromInputs
  END TYPE CrushFoam_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: CrushFoam_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => CrushFoam_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => CrushFoam_MatCtx_InitDefaults
  END TYPE CrushFoam_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: CrushFoam_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => CrushFoam_MatAlgo_InitDefaults
  END TYPE CrushFoam_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Piezo_MatDesc
    REAL(wp) :: C_E(6,6) = 0.0_wp, e(3,6) = 0.0_wp, kappa_eps(3,3) = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Piezo_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Piezo_MatDesc_Valid
  END TYPE Piezo_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Piezo_MatState
    REAL(wp) :: electric_displacement(3) = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Piezo_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Piezo_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Piezo_MatState_InitFromInputs
  END TYPE Piezo_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Piezo_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    REAL(wp) :: electric_field(3) = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Piezo_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Piezo_MatCtx_InitDefaults
  END TYPE Piezo_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Piezo_MatAlgo
    INTEGER(i4) :: analysis_type = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Piezo_MatAlgo_InitDefaults
  END TYPE Piezo_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: RateFoam_MatDesc
    REAL(wp) :: MD_MAT_E_inf = 0.0_wp, nu_inf = 0.0_wp
    INTEGER(i4) :: n_prony = 0
    REAL(wp), ALLOCATABLE :: g_prony(:), tau_prony(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => RateFoam_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => RateFoam_MatDesc_Valid
  END TYPE RateFoam_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: RateFoam_MatState
    REAL(wp) :: eps_vol_pl = 0.0_wp
    REAL(wp), ALLOCATABLE :: eps_p(:), q_prony(:,:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => RateFoam_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => RateFoam_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => RateFoam_MatState_InitFromInputs
  END TYPE RateFoam_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: RateFoam_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => RateFoam_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => RateFoam_MatCtx_InitDefaults
  END TYPE RateFoam_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: RateFoam_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => RateFoam_MatAlgo_InitDefaults
  END TYPE RateFoam_MatAlgo


  !=============================================================================

  ! LaRC Failure (Composite)
  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: LaRC_MatDesc
    REAL(wp) :: E1 = 0.0_wp, E2 = 0.0_wp, nu12 = 0.0_wp, G12 = 0.0_wp
    REAL(wp) :: X_T = 0.0_wp, X_C = 0.0_wp, Y_T = 0.0_wp, Y_C = 0.0_wp, S_L = 0.0_wp
    REAL(wp) :: alpha_0 = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => LaRC_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => LaRC_MatDesc_Valid
  END TYPE LaRC_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: LaRC_MatState
    REAL(wp) :: damage_fiber = 0.0_wp, damage_matrix = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => LaRC_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => LaRC_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => LaRC_MatState_InitFromInputs
  END TYPE LaRC_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: LaRC_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => LaRC_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => LaRC_MatCtx_InitDefaults
  END TYPE LaRC_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: LaRC_MatAlgo
    INTEGER(i4) :: failure_criterion = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => LaRC_MatAlgo_InitDefaults
  END TYPE LaRC_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: SMP_MatDesc
    REAL(wp) :: MD_MAT_E_rubber = 0.0_wp, MD_MAT_E_glass = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: T_g = 0.0_wp, T_transition = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => SMP_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => SMP_MatDesc_Valid
  END TYPE SMP_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: SMP_MatState
    REAL(wp), ALLOCATABLE :: eps_p(:)
    REAL(wp) :: zeta = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => SMP_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => SMP_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => SMP_MatState_InitFromInputs
  END TYPE SMP_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: SMP_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => SMP_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => SMP_MatCtx_InitDefaults
  END TYPE SMP_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: SMP_MatAlgo
    INTEGER(i4) :: smp_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => SMP_MatAlgo_InitDefaults
  END TYPE SMP_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: NoTension_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => NoTension_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => NoTension_MatDesc_Valid
  END TYPE NoTension_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: NoTension_MatState
    REAL(wp) :: damage = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => NoTension_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => NoTension_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => NoTension_MatState_InitFromInputs
  END TYPE NoTension_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: NoTension_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => NoTension_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => NoTension_MatCtx_InitDefaults
  END TYPE NoTension_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: NoTension_MatAlgo
    INTEGER(i4) :: tension_cutoff_method = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => NoTension_MatAlgo_InitDefaults
  END TYPE NoTension_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: PQFiber_MatDesc
    REAL(wp) :: E1 = 0.0_wp, E2 = 0.0_wp, nu12 = 0.0_wp, G12 = 0.0_wp
    REAL(wp) :: sigma_y_fiber = 0.0_wp, H_fiber = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => PQFiber_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => PQFiber_MatDesc_Valid
  END TYPE PQFiber_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: PQFiber_MatState
    REAL(wp) :: eps_p_fiber = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => PQFiber_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => PQFiber_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => PQFiber_MatState_InitFromInputs
  END TYPE PQFiber_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: PQFiber_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => PQFiber_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => PQFiber_MatCtx_InitDefaults
  END TYPE PQFiber_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: PQFiber_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => PQFiber_MatAlgo_InitDefaults
  END TYPE PQFiber_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: CZM_MatDesc
    REAL(wp) :: K_n = 0.0_wp, K_s = 0.0_wp, sigma_max = 0.0_wp, tau_max = 0.0_wp
    REAL(wp) :: G_Ic = 0.0_wp, G_IIc = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => CZM_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => CZM_MatDesc_Valid
  END TYPE CZM_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: CZM_MatState
    REAL(wp) :: delta_n = 0.0_wp, delta_s = 0.0_wp, damage = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => CZM_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => CZM_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => CZM_MatState_InitFromInputs
  END TYPE CZM_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: CZM_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => CZM_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => CZM_MatCtx_InitDefaults
  END TYPE CZM_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: CZM_MatAlgo
    INTEGER(i4) :: czm_law = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => CZM_MatAlgo_InitDefaults
  END TYPE CZM_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Fabric_MatDesc
    REAL(wp) :: MD_MAT_E_warp = 0.0_wp, MD_MAT_E_fill = 0.0_wp, nu_wf = 0.0_wp, G_wf = 0.0_wp
    REAL(wp) :: X_T = 0.0_wp, X_C = 0.0_wp, Y_T = 0.0_wp, Y_C = 0.0_wp, S_L = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Fabric_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Fabric_MatDesc_Valid
  END TYPE Fabric_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Fabric_MatState
    REAL(wp) :: damage_warp = 0.0_wp, damage_fill = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Fabric_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Fabric_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Fabric_MatState_InitFromInputs
  END TYPE Fabric_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Fabric_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Fabric_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Fabric_MatCtx_InitDefaults
  END TYPE Fabric_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Fabric_MatAlgo
    INTEGER(i4) :: failure_criterion = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Fabric_MatAlgo_InitDefaults
  END TYPE Fabric_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: ThermoMech_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, alpha_T = 0.0_wp, k_thermal = 0.0_wp
    REAL(wp) :: rho = 0.0_wp, c_p = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => ThermoMech_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => ThermoMech_MatDesc_Valid
  END TYPE ThermoMech_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: ThermoMech_MatState
    REAL(wp), ALLOCATABLE :: eps_p(:)
    REAL(wp) :: T = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => ThermoMech_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => ThermoMech_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => ThermoMech_MatState_InitFromInputs
  END TYPE ThermoMech_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: ThermoMech_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => ThermoMech_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => ThermoMech_MatCtx_InitDefaults
  END TYPE ThermoMech_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: ThermoMech_MatAlgo
    INTEGER(i4) :: coupling_type = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => ThermoMech_MatAlgo_InitDefaults
  END TYPE ThermoMech_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MagnetoMech_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, mu_r = 0.0_wp
    REAL(wp) :: alpha_mag = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => MagnetoMech_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => MagnetoMech_MatDesc_Valid
  END TYPE MagnetoMech_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: MagnetoMech_MatState
    REAL(wp) :: B_field(3) = 0.0_wp, H_field(3) = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => MagnetoMech_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => MagnetoMech_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => MagnetoMech_MatState_InitFromInputs
  END TYPE MagnetoMech_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: MagnetoMech_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    REAL(wp) :: H_field_ext(3) = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => MagnetoMech_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => MagnetoMech_MatCtx_InitDefaults
  END TYPE MagnetoMech_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: MagnetoMech_MatAlgo
    INTEGER(i4) :: coupling_type = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => MagnetoMech_MatAlgo_InitDefaults
  END TYPE MagnetoMech_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: PoroFluid_MatDesc
    REAL(wp) :: MD_MAT_E_solid = 0.0_wp, nu_solid = 0.0_wp, k_perm = 0.0_wp
    REAL(wp) :: phi_porosity = 0.0_wp, K_f = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => PoroFluid_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => PoroFluid_MatDesc_Valid
  END TYPE PoroFluid_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: PoroFluid_MatState
    REAL(wp) :: p_pore = 0.0_wp, q_flux(3) = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => PoroFluid_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => PoroFluid_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => PoroFluid_MatState_InitFromInputs
  END TYPE PoroFluid_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: PoroFluid_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => PoroFluid_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => PoroFluid_MatCtx_InitDefaults
  END TYPE PoroFluid_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: PoroFluid_MatAlgo
    INTEGER(i4) :: biot_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => PoroFluid_MatAlgo_InitDefaults
  END TYPE PoroFluid_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: BioSoftTissue_MatDesc
    REAL(wp) :: mu = 0.0_wp, k1 = 0.0_wp, k2 = 0.0_wp
    REAL(wp) :: kappa = 0.0_wp, k = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => BioSoftTissue_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => BioSoftTissue_MatDesc_Valid
  END TYPE BioSoftTissue_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: BioSoftTissue_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => BioSoftTissue_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => BioSoftTissue_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => BioSoftTissue_MatState_InitFromInputs
  END TYPE BioSoftTissue_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: BioSoftTissue_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => BioSoftTissue_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => BioSoftTissue_MatCtx_InitDefaults
  END TYPE BioSoftTissue_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: BioSoftTissue_MatAlgo
    INTEGER(i4) :: tissue_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => BioSoftTissue_MatAlgo_InitDefaults
  END TYPE BioSoftTissue_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: NoCompression_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => NoCompression_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => NoCompression_MatDesc_Valid
  END TYPE NoCompression_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: NoCompression_MatState
    REAL(wp) :: damage = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => NoCompression_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => NoCompression_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => NoCompression_MatState_InitFromInputs
  END TYPE NoCompression_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: NoCompression_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => NoCompression_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => NoCompression_MatCtx_InitDefaults
  END TYPE NoCompression_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: NoCompression_MatAlgo
    INTEGER(i4) :: compression_cutoff_method = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => NoCompression_MatAlgo_InitDefaults
  END TYPE NoCompression_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Multiscale_MatDesc
    REAL(wp) :: MD_MAT_E_eff = 0.0_wp, nu_eff = 0.0_wp
    INTEGER(i4) :: rve_type = 1
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Multiscale_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Multiscale_MatDesc_Valid
  END TYPE Multiscale_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Multiscale_MatState
    REAL(wp), ALLOCATABLE :: eps_micro(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Multiscale_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Multiscale_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Multiscale_MatState_InitFromInputs
  END TYPE Multiscale_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Multiscale_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Multiscale_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Multiscale_MatCtx_InitDefaults
  END TYPE Multiscale_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Multiscale_MatAlgo
    INTEGER(i4) :: homogenization_method = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Multiscale_MatAlgo_InitDefaults
  END TYPE Multiscale_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: TempDependent_MatDesc
    REAL(wp) :: MD_MAT_E_ref = 0.0_wp, nu = 0.0_wp, alpha_T = 0.0_wp
    REAL(wp) :: T_ref = 293.15_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => TempDependent_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => TempDependent_MatDesc_Valid
  END TYPE TempDependent_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: TempDependent_MatState
    REAL(wp) :: T_current = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => TempDependent_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => TempDependent_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => TempDependent_MatState_InitFromInputs
  END TYPE TempDependent_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: TempDependent_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => TempDependent_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => TempDependent_MatCtx_InitDefaults
  END TYPE TempDependent_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: TempDependent_MatAlgo
    INTEGER(i4) :: temp_dependency_law = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => TempDependent_MatAlgo_InitDefaults
  END TYPE TempDependent_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MC_Geo_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, phi = 0.0_wp, c = 0.0_wp, psi = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => MC_Geo_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => MC_Geo_MatDesc_Valid
  END TYPE MC_Geo_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: MC_Geo_MatState
    REAL(wp), ALLOCATABLE :: eps_p(:)
    REAL(wp) :: alpha = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => MC_Geo_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => MC_Geo_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => MC_Geo_MatState_InitFromInputs
  END TYPE MC_Geo_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: MC_Geo_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => MC_Geo_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => MC_Geo_MatCtx_InitDefaults
  END TYPE MC_Geo_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: MC_Geo_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => MC_Geo_MatAlgo_InitDefaults
  END TYPE MC_Geo_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_MAT_DP_Geo_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, phi = 0.0_wp, c = 0.0_wp, beta = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => MD_MAT_DP_Geo_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => MD_MAT_DP_Geo_MatDesc_Valid
  END TYPE MD_MAT_DP_Geo_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: MD_MAT_DP_Geo_MatState
    REAL(wp), ALLOCATABLE :: eps_p(:)
    REAL(wp) :: alpha = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => MD_MAT_DP_Geo_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => MD_MAT_DP_Geo_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => MD_MAT_DP_Geo_MatState_InitFromInputs
  END TYPE MD_MAT_DP_Geo_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: MD_MAT_DP_Geo_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => MD_MAT_DP_Geo_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => MD_MAT_DP_Geo_MatCtx_InitDefaults
  END TYPE MD_MAT_DP_Geo_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: MD_MAT_DP_Geo_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => MD_MAT_DP_Geo_MatAlgo_InitDefaults
  END TYPE MD_MAT_DP_Geo_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: CappedDP_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, phi = 0.0_wp, c = 0.0_wp
    REAL(wp) :: beta = 0.0_wp, R = 0.0_wp, p_t = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => CappedDP_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => CappedDP_MatDesc_Valid
  END TYPE CappedDP_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: CappedDP_MatState
    REAL(wp), ALLOCATABLE :: eps_p(:)
    REAL(wp) :: eps_v_p = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => CappedDP_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => CappedDP_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => CappedDP_MatState_InitFromInputs
  END TYPE CappedDP_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: CappedDP_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => CappedDP_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => CappedDP_MatCtx_InitDefaults
  END TYPE CappedDP_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: CappedDP_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => CappedDP_MatAlgo_InitDefaults
  END TYPE CappedDP_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: JointedRock_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, phi_joint = 0.0_wp, c_joint = 0.0_wp
    REAL(wp) :: k_n_joint = 0.0_wp, k_s_joint = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => JointedRock_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => JointedRock_MatDesc_Valid
  END TYPE JointedRock_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: JointedRock_MatState
    REAL(wp) :: delta_joint_n = 0.0_wp, delta_joint_s = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => JointedRock_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => JointedRock_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => JointedRock_MatState_InitFromInputs
  END TYPE JointedRock_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: JointedRock_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => JointedRock_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => JointedRock_MatCtx_InitDefaults
  END TYPE JointedRock_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: JointedRock_MatAlgo
    INTEGER(i4) :: joint_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => JointedRock_MatAlgo_InitDefaults
  END TYPE JointedRock_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: GeoCreep_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, A_creep = 0.0_wp, n_creep = 0.0_wp
    REAL(wp) :: Q_creep = 0.0_wp, T_ref = 293.15_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => GeoCreep_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => GeoCreep_MatDesc_Valid
  END TYPE GeoCreep_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: GeoCreep_MatState
    REAL(wp), ALLOCATABLE :: eps_c(:)
    REAL(wp) :: eps_c_eqv = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => GeoCreep_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => GeoCreep_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => GeoCreep_MatState_InitFromInputs
  END TYPE GeoCreep_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: GeoCreep_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => GeoCreep_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => GeoCreep_MatCtx_InitDefaults
  END TYPE GeoCreep_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: GeoCreep_MatAlgo
    INTEGER(i4) :: creep_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => GeoCreep_MatAlgo_InitDefaults
  END TYPE GeoCreep_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: ExtDP_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, phi = 0.0_wp, c = 0.0_wp
    REAL(wp) :: beta = 0.0_wp, k = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => ExtDP_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => ExtDP_MatDesc_Valid
  END TYPE ExtDP_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: ExtDP_MatState
    REAL(wp), ALLOCATABLE :: eps_p(:)
    REAL(wp) :: alpha = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => ExtDP_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => ExtDP_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => ExtDP_MatState_InitFromInputs
  END TYPE ExtDP_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: ExtDP_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => ExtDP_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => ExtDP_MatCtx_InitDefaults
  END TYPE ExtDP_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: ExtDP_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => ExtDP_MatAlgo_InitDefaults
  END TYPE ExtDP_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Ortho3D_MatDesc
    REAL(wp) :: E1 = 0.0_wp, E2 = 0.0_wp, E3 = 0.0_wp
    REAL(wp) :: nu12 = 0.0_wp, nu13 = 0.0_wp, nu23 = 0.0_wp
    REAL(wp) :: G12 = 0.0_wp, G13 = 0.0_wp, G23 = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Ortho3D_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Ortho3D_MatDesc_Valid
  END TYPE Ortho3D_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Ortho3D_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Ortho3D_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Ortho3D_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Ortho3D_MatState_InitFromInputs
  END TYPE Ortho3D_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Ortho3D_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Ortho3D_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Ortho3D_MatCtx_InitDefaults
  END TYPE Ortho3D_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Ortho3D_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Ortho3D_MatAlgo_InitDefaults
  END TYPE Ortho3D_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Aniso21_MatDesc
    REAL(wp) :: C(6,6) = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Aniso21_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Aniso21_MatDesc_Valid
  END TYPE Aniso21_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Aniso21_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Aniso21_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Aniso21_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Aniso21_MatState_InitFromInputs
  END TYPE Aniso21_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Aniso21_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Aniso21_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Aniso21_MatCtx_InitDefaults
  END TYPE Aniso21_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Aniso21_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Aniso21_MatAlgo_InitDefaults
  END TYPE Aniso21_MatAlgo


  !=============================================================================
  ! Batch 4: HyperElastic Models (Yeoh, ArrudaBoyce, VDW, Marlow, Gent)


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: VDW_MatDesc
    REAL(wp) :: mu = 0.0_wp, lambda_m = 0.0_wp, a_global = 0.0_wp, beta_vdw = 0.0_wp
    REAL(wp) :: nu = 0.5_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => VDW_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => VDW_MatDesc_Valid
  END TYPE VDW_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: VDW_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => VDW_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => VDW_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => VDW_MatState_InitFromInputs
  END TYPE VDW_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: VDW_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => VDW_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => VDW_MatCtx_InitDefaults
  END TYPE VDW_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: VDW_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => VDW_MatAlgo_InitDefaults
  END TYPE VDW_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Marlow_MatDesc
    INTEGER(i4) :: n_data_points = 0
    REAL(wp), ALLOCATABLE :: strain_data(:), stress_data(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Marlow_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Marlow_MatDesc_Valid
  END TYPE Marlow_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Marlow_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Marlow_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Marlow_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Marlow_MatState_InitFromInputs
  END TYPE Marlow_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Marlow_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Marlow_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Marlow_MatCtx_InitDefaults
  END TYPE Marlow_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Marlow_MatAlgo
    INTEGER(i4) :: interpolation_method = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Marlow_MatAlgo_InitDefaults
  END TYPE Marlow_MatAlgo


  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: Gent_MatDesc
    REAL(wp) :: mu = 0.0_wp, J_m = 0.0_wp, D1 = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => Gent_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => Gent_MatDesc_Valid
  END TYPE Gent_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: Gent_MatState
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => Gent_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => Gent_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => Gent_MatState_InitFromInputs
  END TYPE Gent_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: Gent_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => Gent_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => Gent_MatCtx_InitDefaults
  END TYPE Gent_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: Gent_MatAlgo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => Gent_MatAlgo_InitDefaults
  END TYPE Gent_MatAlgo


  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MC_Concrete_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, phi = 0.0_wp, c = 0.0_wp, psi = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => MC_Concrete_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => MC_Concrete_MatDesc_Valid
  END TYPE MC_Concrete_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: MC_Concrete_MatState
    REAL(wp), ALLOCATABLE :: eps_p(:)
    REAL(wp) :: alpha = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => MC_Concrete_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => MC_Concrete_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => MC_Concrete_MatState_InitFromInputs
  END TYPE MC_Concrete_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: MC_Concrete_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => MC_Concrete_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => MC_Concrete_MatCtx_InitDefaults
  END TYPE MC_Concrete_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: MC_Concrete_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => MC_Concrete_MatAlgo_InitDefaults
  END TYPE MC_Concrete_MatAlgo

  !=============================================================================

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: NL_Visc_MatDesc
    REAL(wp) :: MD_MAT_E_inf = 0.0_wp, nu = 0.0_wp
    INTEGER(i4) :: n_prony = 0
    REAL(wp), ALLOCATABLE :: g_prony(:), tau_prony(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => NL_Visc_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => NL_Visc_MatDesc_Valid
  END TYPE NL_Visc_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: NL_Visc_MatState
    REAL(wp), ALLOCATABLE :: q_prony(:,:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => NL_Visc_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => NL_Visc_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => NL_Visc_MatState_InitFromInputs
  END TYPE NL_Visc_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: NL_Visc_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => NL_Visc_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => NL_Visc_MatCtx_InitDefaults
  END TYPE NL_Visc_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: NL_Visc_MatAlgo
    INTEGER(i4) :: visco_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => NL_Visc_MatAlgo_InitDefaults
  END TYPE NL_Visc_MatAlgo

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: PolymerCure_MatDesc
    REAL(wp) :: MD_MAT_E_uncured = 0.0_wp, MD_MAT_E_cured = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: A_cure = 0.0_wp, MD_MAT_E_a = 0.0_wp, n_cure = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => PolymerCure_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => PolymerCure_MatDesc_Valid
  END TYPE PolymerCure_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: PolymerCure_MatState
    REAL(wp) :: alpha_cure = 0.0_wp, T_cure = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => PolymerCure_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => PolymerCure_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => PolymerCure_MatState_InitFromInputs
  END TYPE PolymerCure_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: PolymerCure_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => PolymerCure_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => PolymerCure_MatCtx_InitDefaults
  END TYPE PolymerCure_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: PolymerCure_MatAlgo
    INTEGER(i4) :: cure_model = 1
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => PolymerCure_MatAlgo_InitDefaults
  END TYPE PolymerCure_MatAlgo

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: ViscPlastDmg_MatDesc
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, sigma_y = 0.0_wp
    REAL(wp) :: K_visc = 0.0_wp, n_visc = 0.0_wp, eps_f = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => ViscPlastDmg_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => ViscPlastDmg_MatDesc_Valid
  END TYPE ViscPlastDmg_MatDesc

  TYPE, PUBLIC, EXTENDS(MD_MatSta) :: ViscPlastDmg_MatState
    REAL(wp), ALLOCATABLE :: eps_p(:)
    REAL(wp) :: damage = 0.0_wp, eps_p_eqv = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: SyncToStateV => ViscPlastDmg_MatState_SyncToStateV
    PROCEDURE, PUBLIC :: SyncFromStateV => ViscPlastDmg_MatState_SyncFromStateV
    PROCEDURE, PUBLIC :: InitFromInputs => ViscPlastDmg_MatState_InitFromInputs
  END TYPE ViscPlastDmg_MatState

  TYPE, PUBLIC, EXTENDS(MD_MatCtx) :: ViscPlastDmg_MatCtx
    INTEGER(i4) :: ndir = 3, nshr = 3, ntens = 6
    REAL(wp) :: temp = 0.0_wp, dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0, kinc = 0
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromInputs => ViscPlastDmg_MatCtx_InitFromInputs
    PROCEDURE, PUBLIC :: InitDefaults => ViscPlastDmg_MatCtx_InitDefaults
  END TYPE ViscPlastDmg_MatCtx

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: ViscPlastDmg_MatAlgo
    INTEGER(i4) :: return_mapping_method = 1
    REAL(wp) :: yield_tolerance = 1.0e-6_wp
    LOGICAL :: use_consistent_tangent = .TRUE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitDefaults => ViscPlastDmg_MatAlgo_InitDefaults
  END TYPE ViscPlastDmg_MatAlgo

CONTAINS

  !=============================================================================
  ! NortonCreep Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE NortonCreep_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(NortonCreep_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "NortonCreep_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%A = props(3)
    this%n = props(4)
    IF (nprops >= 5) this%Q = props(5)
    IF (nprops >= 6) this%T_ref = props(6)
    this%cfg%id = 602_i4
    this%name = "Norton Creep"
    this%cfg%class_id = MD_MAT_CATEGORY_CR
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE NortonCreep_MatDesc_InitFromProps

  FUNCTION NortonCreep_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(NortonCreep_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%A > ZERO .AND. this%n > ZERO
  END FUNCTION NortonCreep_MatDesc_Valid

  SUBROUTINE NortonCreep_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(NortonCreep_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_c, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_c_eqv
      offset = offset + 1
    END IF
    n_eps_c = MIN(6, SIZE(this%eps_c, 1))
    DO i = 1, MIN(n_eps_c, nstatev - offset)
      statev(offset + i) = this%eps_c(i)
    END DO
  END SUBROUTINE NortonCreep_MatState_SyncToStateV

  SUBROUTINE NortonCreep_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(NortonCreep_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_c, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%eps_c_eqv = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_c_eqv = 0.0_wp
    END IF
    n_eps_c = MIN(6, nstatev - offset)
    IF (.NOT. ALLOCATED(this%eps_c)) THEN
      ALLOCATE(this%eps_c(6))
      this%eps_c = 0.0_wp
    END IF
    DO i = 1, MIN(n_eps_c, SIZE(this%eps_c, 1))
      this%eps_c(i) = statev(offset + i)
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE NortonCreep_MatState_SyncFromStateV

  SUBROUTINE NortonCreep_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(NortonCreep_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (.NOT. ALLOCATED(this%eps_c)) THEN
      ALLOCATE(this%eps_c(ntens))
      this%eps_c = 0.0_wp
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
    this%eps_c_eqv = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE NortonCreep_MatState_InitFromInputs

  SUBROUTINE NortonCreep_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(NortonCreep_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE NortonCreep_MatCtx_InitFromInputs

  SUBROUTINE NortonCreep_MatCtx_InitDefaults(this)
    CLASS(NortonCreep_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE NortonCreep_MatCtx_InitDefaults

  SUBROUTINE NortonCreep_MatAlgo_InitDefaults(this)
    CLASS(NortonCreep_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%creep_method = 1
    this%tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE NortonCreep_MatAlgo_InitDefaults

  !=============================================================================
  ! GarofaloCreep Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE GarofaloCreep_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(GarofaloCreep_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 5) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "GarofaloCreep_MatDesc: Insufficient properties (need at least 5)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%A = props(3)
    this%n = props(4)
    this%alpha = props(5)
    IF (nprops >= 6) this%Q = props(6)
    IF (nprops >= 7) this%T_ref = props(7)
    this%cfg%id = 603_i4
    this%name = "Garofalo Creep"
    this%cfg%class_id = MD_MAT_CATEGORY_CR
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE GarofaloCreep_MatDesc_InitFromProps

  FUNCTION GarofaloCreep_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(GarofaloCreep_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%A > ZERO .AND. this%n > ZERO
  END FUNCTION GarofaloCreep_MatDesc_Valid

  SUBROUTINE GarofaloCreep_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(GarofaloCreep_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_c, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_c_eqv
      offset = offset + 1
    END IF
    n_eps_c = MIN(6, SIZE(this%eps_c, 1))
    DO i = 1, MIN(n_eps_c, nstatev - offset)
      statev(offset + i) = this%eps_c(i)
    END DO
  END SUBROUTINE GarofaloCreep_MatState_SyncToStateV

  SUBROUTINE GarofaloCreep_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(GarofaloCreep_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_c, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%eps_c_eqv = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_c_eqv = 0.0_wp
    END IF
    n_eps_c = MIN(6, nstatev - offset)
    IF (.NOT. ALLOCATED(this%eps_c)) THEN
      ALLOCATE(this%eps_c(6))
      this%eps_c = 0.0_wp
    END IF
    DO i = 1, MIN(n_eps_c, SIZE(this%eps_c, 1))
      this%eps_c(i) = statev(offset + i)
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE GarofaloCreep_MatState_SyncFromStateV

  SUBROUTINE GarofaloCreep_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(GarofaloCreep_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (.NOT. ALLOCATED(this%eps_c)) THEN
      ALLOCATE(this%eps_c(ntens))
      this%eps_c = 0.0_wp
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
    this%eps_c_eqv = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE GarofaloCreep_MatState_InitFromInputs

  SUBROUTINE GarofaloCreep_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(GarofaloCreep_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE GarofaloCreep_MatCtx_InitFromInputs

  SUBROUTINE GarofaloCreep_MatCtx_InitDefaults(this)
    CLASS(GarofaloCreep_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE GarofaloCreep_MatCtx_InitDefaults

  SUBROUTINE GarofaloCreep_MatAlgo_InitDefaults(this)
    CLASS(GarofaloCreep_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%creep_method = 1
    this%tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE GarofaloCreep_MatAlgo_InitDefaults

  !=============================================================================
  ! CompLamina Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE CompLamina_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(CompLamina_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "CompLamina_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%E1 = props(1)
    this%E2 = props(2)
    this%nu12 = props(3)
    this%G12 = props(4)
    IF (nprops >= 5) this%G13 = props(5)
    IF (nprops >= 6) this%G23 = props(6)
    this%cfg%id = 900_i4
    this%name = "Composite Lamina"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 3
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE CompLamina_MatDesc_InitFromProps

  FUNCTION CompLamina_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(CompLamina_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E1 > ZERO .AND. this%E2 > ZERO .AND. this%G12 > ZERO
  END FUNCTION CompLamina_MatDesc_Valid

  SUBROUTINE CompLamina_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(CompLamina_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%strain_energy
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_fiber
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_matrix
    END IF
  END SUBROUTINE CompLamina_MatState_SyncToStateV

  SUBROUTINE CompLamina_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(CompLamina_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%strain_energy = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%strain_energy = 0.0_wp
    END IF
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
  END SUBROUTINE CompLamina_MatState_SyncFromStateV

  SUBROUTINE CompLamina_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(CompLamina_MatState), INTENT(INOUT) :: this
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
    this%damage_fiber = 0.0_wp
    this%damage_matrix = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE CompLamina_MatState_InitFromInputs

  SUBROUTINE CompLamina_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(CompLamina_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE CompLamina_MatCtx_InitFromInputs

  SUBROUTINE CompLamina_MatCtx_InitDefaults(this)
    CLASS(CompLamina_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE CompLamina_MatCtx_InitDefaults

  SUBROUTINE CompLamina_MatAlgo_InitDefaults(this)
    CLASS(CompLamina_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%failure_criterion = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE CompLamina_MatAlgo_InitDefaults

  !=============================================================================
  ! MCC Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE MCC_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(MCC_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 7) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MCC_MatDesc: Insufficient properties (need at least 7)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%kappa = props(3)
    this%lambda = props(4)
    this%M = props(5)
    this%e0 = props(6)
    this%p_c0 = props(7)
    IF (nprops >= 8) this%beta_cap = props(8)
    this%cfg%id = 804_i4
    this%name = "Modified Cam-Clay"
    this%cfg%class_id = MD_MAT_CATEGORY_GEOMAT
    this%pop%nProps = nprops
    this%pop%nStateV = 8
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MCC_MatDesc_InitFromProps

  FUNCTION MCC_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(MCC_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%lambda > this%kappa .AND. this%M > ZERO .AND. this%p_c0 > ZERO
  END FUNCTION MCC_MatDesc_Valid

  SUBROUTINE MCC_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(MCC_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_p, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%p_c
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_v_eqv
      offset = offset + 1
    END IF
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    n_eps_p = MIN(6, SIZE(this%eps_p, 1))
    DO i = 1, MIN(n_eps_p, nstatev - offset)
      statev(offset + i) = this%eps_p(i)
    END DO
  END SUBROUTINE MCC_MatState_SyncToStateV

  SUBROUTINE MCC_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(MCC_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_p, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%p_c = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%p_c = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%eps_v_eqv = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_v_eqv = 0.0_wp
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
  END SUBROUTINE MCC_MatState_SyncFromStateV

  SUBROUTINE MCC_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(MCC_MatState), INTENT(INOUT) :: this
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
    this%p_c = 0.0_wp
    this%eps_v_eqv = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE MCC_MatState_InitFromInputs

  SUBROUTINE MCC_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(MCC_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE MCC_MatCtx_InitFromInputs

  SUBROUTINE MCC_MatCtx_InitDefaults(this)
    CLASS(MCC_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE MCC_MatCtx_InitDefaults

  SUBROUTINE MCC_MatAlgo_InitDefaults(this)
    CLASS(MCC_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_substepping = .TRUE.
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE MCC_MatAlgo_InitDefaults

  !=============================================================================
  ! SMA Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE SMA_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(SMA_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 9) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "SMA_MatDesc: Insufficient properties (need at least 9)"
      RETURN
    END IF
    this%MD_MAT_E_A = props(1)
    this%MD_MAT_E_M = props(2)
    this%nu_A = props(3)
    this%nu_M = props(4)
    this%H_sat = props(5)
    this%stress_s = props(6)
    this%stress_f = props(7)
    this%T_ref = props(8)
    this%beta_A = props(9)
    IF (nprops >= 10) this%beta_M = props(10)
    IF (nprops >= 11) this%superelastic = (props(11) > 0.5_wp)
    this%cfg%id = 1003_i4
    this%name = "Shape Memory Alloy"
    this%cfg%class_id = MD_MAT_CATEGORY_MULTIPHYS
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE SMA_MatDesc_InitFromProps

  FUNCTION SMA_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(SMA_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_A > ZERO .AND. this%MD_MAT_E_M > ZERO .AND. this%H_sat > ZERO
  END FUNCTION SMA_MatDesc_Valid

  SUBROUTINE SMA_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(SMA_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_tr, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%xi
      offset = offset + 1
    END IF
    n_eps_tr = MIN(6, SIZE(this%eps_tr, 1))
    DO i = 1, MIN(n_eps_tr, nstatev - offset)
      statev(offset + i) = this%eps_tr(i)
    END DO
  END SUBROUTINE SMA_MatState_SyncToStateV

  SUBROUTINE SMA_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(SMA_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_tr, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%xi = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%xi = 0.0_wp
    END IF
    n_eps_tr = MIN(6, nstatev - offset)
    IF (.NOT. ALLOCATED(this%eps_tr)) THEN
      ALLOCATE(this%eps_tr(6))
      this%eps_tr = 0.0_wp
    END IF
    DO i = 1, MIN(n_eps_tr, SIZE(this%eps_tr, 1))
      this%eps_tr(i) = statev(offset + i)
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE SMA_MatState_SyncFromStateV

  SUBROUTINE SMA_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(SMA_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (.NOT. ALLOCATED(this%eps_tr)) THEN
      ALLOCATE(this%eps_tr(ntens))
      this%eps_tr = 0.0_wp
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
    this%xi = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE SMA_MatState_InitFromInputs

  SUBROUTINE SMA_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(SMA_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE SMA_MatCtx_InitFromInputs

  SUBROUTINE SMA_MatCtx_InitDefaults(this)
    CLASS(SMA_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE SMA_MatCtx_InitDefaults

  SUBROUTINE SMA_MatAlgo_InitDefaults(this)
    CLASS(SMA_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%transformation_method = 1
    this%tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE SMA_MatAlgo_InitDefaults

  !=============================================================================
  ! CrushFoam Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE CrushFoam_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(CrushFoam_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 5) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "CrushFoam_MatDesc: Insufficient properties (need at least 5)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%sigma_c0 = props(3)
    this%sigma_t0 = props(4)
    this%k_factor = props(5)
    this%cfg%id = 1100_i4
    this%name = "Crushable Foam"
    this%cfg%class_id = MD_MAT_CATEGORY_FOAM
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE CrushFoam_MatDesc_InitFromProps

  FUNCTION CrushFoam_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(CrushFoam_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%sigma_c0 > ZERO
  END FUNCTION CrushFoam_MatDesc_Valid

  SUBROUTINE CrushFoam_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(CrushFoam_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_p, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_vol_pl
      offset = offset + 1
    END IF
    n_eps_p = MIN(6, SIZE(this%eps_p, 1))
    DO i = 1, MIN(n_eps_p, nstatev - offset)
      statev(offset + i) = this%eps_p(i)
    END DO
  END SUBROUTINE CrushFoam_MatState_SyncToStateV

  SUBROUTINE CrushFoam_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(CrushFoam_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, n_eps_p, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%eps_vol_pl = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_vol_pl = 0.0_wp
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
  END SUBROUTINE CrushFoam_MatState_SyncFromStateV

  SUBROUTINE CrushFoam_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(CrushFoam_MatState), INTENT(INOUT) :: this
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
    this%eps_vol_pl = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE CrushFoam_MatState_InitFromInputs

  SUBROUTINE CrushFoam_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(CrushFoam_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE CrushFoam_MatCtx_InitFromInputs

  SUBROUTINE CrushFoam_MatCtx_InitDefaults(this)
    CLASS(CrushFoam_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE CrushFoam_MatCtx_InitDefaults

  SUBROUTINE CrushFoam_MatAlgo_InitDefaults(this)
    CLASS(CrushFoam_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE CrushFoam_MatAlgo_InitDefaults

  !=============================================================================
  ! Piezo Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Piezo_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Piezo_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, j, idx
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 21) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Piezo_MatDesc: Insufficient properties (need at least 21)"
      RETURN
    END IF
    idx = 1
    DO i = 1, 6
      DO j = i, 6
        this%C_E(i,j) = props(idx)
        IF (i /= j) this%C_E(j,i) = props(idx)
        idx = idx + 1
      END DO
    END DO
    DO i = 1, 3
      DO j = 1, 6
        this%e(i,j) = props(idx)
        idx = idx + 1
      END DO
    END DO
    DO i = 1, 3
      DO j = i, 3
        this%kappa_eps(i,j) = props(idx)
        IF (i /= j) this%kappa_eps(j,i) = props(idx)
        idx = idx + 1
      END DO
    END DO
    this%cfg%id = 1001_i4
    this%name = "Piezoelectric Material"
    this%cfg%class_id = MD_MAT_CATEGORY_MULTIPHYS
    this%pop%nProps = nprops
    this%pop%nStateV = 3
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Piezo_MatDesc_InitFromProps

  FUNCTION Piezo_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Piezo_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    is_valid = this%is_initialized
  END FUNCTION Piezo_MatDesc_Valid

  SUBROUTINE Piezo_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Piezo_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    DO i = 1, MIN(3, SIZE(this%electric_displacement, 1), nstatev - offset)
      statev(offset + i) = this%electric_displacement(i)
      offset = offset + 1
    END DO
  END SUBROUTINE Piezo_MatState_SyncToStateV

  SUBROUTINE Piezo_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Piezo_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    DO i = 1, MIN(3, SIZE(this%electric_displacement, 1), nstatev - offset)
      this%electric_displacement(i) = statev(offset + i)
      offset = offset + 1
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE Piezo_MatState_SyncFromStateV

  SUBROUTINE Piezo_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Piezo_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE Piezo_MatState_InitFromInputs

  SUBROUTINE Piezo_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, electric_field, kstep, kinc)
    CLASS(Piezo_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Piezo_MatCtx_InitFromInputs

  SUBROUTINE Piezo_MatCtx_InitDefaults(this)
    CLASS(Piezo_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%electric_field = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Piezo_MatCtx_InitDefaults

  SUBROUTINE Piezo_MatAlgo_InitDefaults(this)
    CLASS(Piezo_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%analysis_type = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Piezo_MatAlgo_InitDefaults

  !=============================================================================
  ! RateFoam Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE RateFoam_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(RateFoam_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 2) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "RateFoam_MatDesc: Insufficient properties (need at least 2)"
      RETURN
    END IF
    this%MD_MAT_E_inf = props(1)
    this%nu_inf = props(2)
    IF (nprops >= 3) this%n_prony = MAX(0_i4, MIN(10_i4, INT(props(3))))
    IF (this%n_prony > 0 .AND. nprops >= 3 + 2 * this%n_prony) THEN
      IF (.NOT. ALLOCATED(this%g_prony)) THEN
        ALLOCATE(this%g_prony(this%n_prony), this%tau_prony(this%n_prony))
      END IF
      DO i = 1, this%n_prony
        this%g_prony(i) = props(3 + i)
        this%tau_prony(i) = props(3 + this%n_prony + i)
      END DO
    END IF
    this%cfg%id = 1101_i4
    this%name = "Rate-Dependent Foam"
    this%cfg%class_id = MD_MAT_CATEGORY_FOAM
    this%pop%nProps = nprops
    this%pop%nStateV = 7 + 6 * this%n_prony
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE RateFoam_MatDesc_InitFromProps

  FUNCTION RateFoam_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(RateFoam_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_inf > ZERO
  END FUNCTION RateFoam_MatDesc_Valid

  SUBROUTINE RateFoam_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(RateFoam_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, j, n_eps_p, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_vol_pl
      offset = offset + 1
    END IF
    n_eps_p = MIN(6, SIZE(this%eps_p, 1))
    DO i = 1, MIN(n_eps_p, nstatev - offset)
      statev(offset + i) = this%eps_p(i)
    END DO
    offset = offset + n_eps_p
    IF (ALLOCATED(this%q_prony)) THEN
      DO i = 1, MIN(SIZE(this%q_prony, 1), nstatev - offset)
        DO j = 1, MIN(6, SIZE(this%q_prony, 2))
          statev(offset + (i-1)*6 + j) = this%q_prony(i, j)
        END DO
      END DO
    END IF
  END SUBROUTINE RateFoam_MatState_SyncToStateV

  SUBROUTINE RateFoam_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(RateFoam_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, j, n_eps_p, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%eps_vol_pl = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%eps_vol_pl = 0.0_wp
    END IF
    n_eps_p = MIN(6, nstatev - offset)
    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(6))
      this%eps_p = 0.0_wp
    END IF
    DO i = 1, MIN(n_eps_p, SIZE(this%eps_p, 1))
      this%eps_p(i) = statev(offset + i)
    END DO
    offset = offset + n_eps_p
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoam_MatState_SyncFromStateV

  SUBROUTINE RateFoam_MatState_InitFromInputs(this, ndir, nshr, n_prony)
    CLASS(RateFoam_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr, n_prony
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (.NOT. ALLOCATED(this%eps_p)) THEN
      ALLOCATE(this%eps_p(ntens))
      this%eps_p = 0.0_wp
    END IF
    IF (n_prony > 0) THEN
      IF (.NOT. ALLOCATED(this%q_prony)) THEN
        ALLOCATE(this%q_prony(n_prony, ntens))
        this%q_prony = 0.0_wp
      END IF
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
    this%eps_vol_pl = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoam_MatState_InitFromInputs

  SUBROUTINE RateFoam_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(RateFoam_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE RateFoam_MatCtx_InitFromInputs

  SUBROUTINE RateFoam_MatCtx_InitDefaults(this)
    CLASS(RateFoam_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoam_MatCtx_InitDefaults

  SUBROUTINE RateFoam_MatAlgo_InitDefaults(this)
    CLASS(RateFoam_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE RateFoam_MatAlgo_InitDefaults

  !=============================================================================
  ! LaRC Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE LaRC_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(LaRC_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 10) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "LaRC_MatDesc: Insufficient properties (need at least 10)"
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
    this%alpha_0 = props(10)
    this%cfg%id = 906_i4
    this%name = "LaRC04 Failure"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 2
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE LaRC_MatDesc_InitFromProps

  FUNCTION LaRC_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(LaRC_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E1 > ZERO .AND. this%E2 > ZERO .AND. &
               this%X_T > ZERO .AND. this%Y_T > ZERO .AND. this%S_L > ZERO
  END FUNCTION LaRC_MatDesc_Valid

  SUBROUTINE LaRC_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(LaRC_MatState), INTENT(IN) :: this
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
  END SUBROUTINE LaRC_MatState_SyncToStateV

  SUBROUTINE LaRC_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(LaRC_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE LaRC_MatState_SyncFromStateV

  SUBROUTINE LaRC_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(LaRC_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE LaRC_MatState_InitFromInputs

  SUBROUTINE LaRC_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(LaRC_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE LaRC_MatCtx_InitFromInputs

  SUBROUTINE LaRC_MatCtx_InitDefaults(this)
    CLASS(LaRC_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE LaRC_MatCtx_InitDefaults

  SUBROUTINE LaRC_MatAlgo_InitDefaults(this)
    CLASS(LaRC_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%failure_criterion = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE LaRC_MatAlgo_InitDefaults

  !=============================================================================
  ! SMP Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE SMP_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(SMP_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 5) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "SMP_MatDesc: Insufficient properties (need at least 5)"
      RETURN
    END IF
    this%MD_MAT_E_rubber = props(1)
    this%MD_MAT_E_glass = props(2)
    this%nu = props(3)
    this%T_g = props(4)
    this%T_transition = props(5)
    this%cfg%id = 1004_i4
    this%name = "Shape Memory Polymer"
    this%cfg%class_id = MD_MAT_CATEGORY_MULTIPHYS
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE SMP_MatDesc_InitFromProps

  FUNCTION SMP_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(SMP_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_rubber > ZERO .AND. this%MD_MAT_E_glass > ZERO .AND. &
               this%T_g > ZERO .AND. this%T_transition > ZERO
  END FUNCTION SMP_MatDesc_Valid

  SUBROUTINE SMP_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(SMP_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      statev(offset + i) = this%eps_p(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%zeta
    END IF
  END SUBROUTINE SMP_MatState_SyncToStateV

  SUBROUTINE SMP_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(SMP_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) ALLOCATE(this%eps_p(6))
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      this%eps_p(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%zeta = statev(offset + 1)
    ELSE
      this%zeta = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE SMP_MatState_SyncFromStateV

  SUBROUTINE SMP_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(SMP_MatState), INTENT(INOUT) :: this
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
    this%zeta = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE SMP_MatState_InitFromInputs

  SUBROUTINE SMP_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(SMP_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE SMP_MatCtx_InitFromInputs

  SUBROUTINE SMP_MatCtx_InitDefaults(this)
    CLASS(SMP_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE SMP_MatCtx_InitDefaults

  SUBROUTINE SMP_MatAlgo_InitDefaults(this)
    CLASS(SMP_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%smp_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE SMP_MatAlgo_InitDefaults

  !=============================================================================
  ! NoTension Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE NoTension_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(NoTension_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 2) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "NoTension_MatDesc: Insufficient properties (need at least 2)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%cfg%id = 1102_i4
    this%name = "No-Tension Material"
    this%cfg%class_id = MD_MAT_CATEGORY_FOAM
    this%pop%nProps = nprops
    this%pop%nStateV = 1
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE NoTension_MatDesc_InitFromProps

  FUNCTION NoTension_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(NoTension_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO
  END FUNCTION NoTension_MatDesc_Valid

  SUBROUTINE NoTension_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(NoTension_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (this%is_initialized .AND. nstatev >= 1) statev(1) = this%damage
  END SUBROUTINE NoTension_MatState_SyncToStateV

  SUBROUTINE NoTension_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(NoTension_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (nstatev >= 1) THEN
      this%damage = statev(1)
    ELSE
      this%damage = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE NoTension_MatState_SyncFromStateV

  SUBROUTINE NoTension_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(NoTension_MatState), INTENT(INOUT) :: this
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
    this%damage = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE NoTension_MatState_InitFromInputs

  SUBROUTINE NoTension_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(NoTension_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE NoTension_MatCtx_InitFromInputs

  SUBROUTINE NoTension_MatCtx_InitDefaults(this)
    CLASS(NoTension_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE NoTension_MatCtx_InitDefaults

  SUBROUTINE NoTension_MatAlgo_InitDefaults(this)
    CLASS(NoTension_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%tension_cutoff_method = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE NoTension_MatAlgo_InitDefaults

  !=============================================================================
  ! PQFiber Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE PQFiber_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(PQFiber_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 6) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "PQFiber_MatDesc: Insufficient properties (need at least 6)"
      RETURN
    END IF
    this%E1 = props(1)
    this%E2 = props(2)
    this%nu12 = props(3)
    this%G12 = props(4)
    this%sigma_y_fiber = props(5)
    this%H_fiber = props(6)
    this%cfg%id = 903_i4
    this%name = "PQFiber Plasticity"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 1
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE PQFiber_MatDesc_InitFromProps

  FUNCTION PQFiber_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(PQFiber_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E1 > ZERO .AND. this%E2 > ZERO .AND. this%sigma_y_fiber > ZERO
  END FUNCTION PQFiber_MatDesc_Valid

  SUBROUTINE PQFiber_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(PQFiber_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (this%is_initialized .AND. nstatev >= 1) statev(1) = this%eps_p_fiber
  END SUBROUTINE PQFiber_MatState_SyncToStateV

  SUBROUTINE PQFiber_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(PQFiber_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (nstatev >= 1) THEN
      this%eps_p_fiber = statev(1)
    ELSE
      this%eps_p_fiber = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE PQFiber_MatState_SyncFromStateV

  SUBROUTINE PQFiber_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(PQFiber_MatState), INTENT(INOUT) :: this
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
    this%eps_p_fiber = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE PQFiber_MatState_InitFromInputs

  SUBROUTINE PQFiber_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(PQFiber_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE PQFiber_MatCtx_InitFromInputs

  SUBROUTINE PQFiber_MatCtx_InitDefaults(this)
    CLASS(PQFiber_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE PQFiber_MatCtx_InitDefaults

  SUBROUTINE PQFiber_MatAlgo_InitDefaults(this)
    CLASS(PQFiber_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE PQFiber_MatAlgo_InitDefaults

  !=============================================================================
  ! CZM Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE CZM_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(CZM_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 6) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "CZM_MatDesc: Insufficient properties (need at least 6)"
      RETURN
    END IF
    this%K_n = props(1)
    this%K_s = props(2)
    this%sigma_max = props(3)
    this%tau_max = props(4)
    this%G_Ic = props(5)
    this%G_IIc = props(6)
    this%cfg%id = 907_i4
    this%name = "Traction-Separation CZM"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 3
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE CZM_MatDesc_InitFromProps

  FUNCTION CZM_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(CZM_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%K_n > ZERO .AND. this%K_s > ZERO .AND. &
               this%sigma_max > ZERO .AND. this%tau_max > ZERO
  END FUNCTION CZM_MatDesc_Valid

  SUBROUTINE CZM_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(CZM_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%delta_n
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%delta_s
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage
    END IF
  END SUBROUTINE CZM_MatState_SyncToStateV

  SUBROUTINE CZM_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(CZM_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%delta_n = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%delta_n = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%delta_s = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%delta_s = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%damage = statev(offset + 1)
    ELSE
      this%damage = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE CZM_MatState_SyncFromStateV

  SUBROUTINE CZM_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(CZM_MatState), INTENT(INOUT) :: this
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
    this%delta_n = 0.0_wp
    this%delta_s = 0.0_wp
    this%damage = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE CZM_MatState_InitFromInputs

  SUBROUTINE CZM_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(CZM_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE CZM_MatCtx_InitFromInputs

  SUBROUTINE CZM_MatCtx_InitDefaults(this)
    CLASS(CZM_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE CZM_MatCtx_InitDefaults

  SUBROUTINE CZM_MatAlgo_InitDefaults(this)
    CLASS(CZM_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%czm_law = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE CZM_MatAlgo_InitDefaults

  !=============================================================================
  ! Fabric Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Fabric_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Fabric_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 9) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Fabric_MatDesc: Insufficient properties (need at least 9)"
      RETURN
    END IF
    this%MD_MAT_E_warp = props(1)
    this%MD_MAT_E_fill = props(2)
    this%nu_wf = props(3)
    this%G_wf = props(4)
    this%X_T = props(5)
    this%X_C = props(6)
    this%Y_T = props(7)
    this%Y_C = props(8)
    this%S_L = props(9)
    this%cfg%id = 909_i4
    this%name = "Woven Fabric Composite"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 2
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Fabric_MatDesc_InitFromProps

  FUNCTION Fabric_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Fabric_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_warp > ZERO .AND. this%MD_MAT_E_fill > ZERO .AND. &
               this%X_T > ZERO .AND. this%Y_T > ZERO .AND. this%S_L > ZERO
  END FUNCTION Fabric_MatDesc_Valid

  SUBROUTINE Fabric_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Fabric_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_warp
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage_fill
    END IF
  END SUBROUTINE Fabric_MatState_SyncToStateV

  SUBROUTINE Fabric_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Fabric_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%damage_warp = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage_warp = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%damage_fill = statev(offset + 1)
    ELSE
      this%damage_fill = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE Fabric_MatState_SyncFromStateV

  SUBROUTINE Fabric_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Fabric_MatState), INTENT(INOUT) :: this
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
    this%damage_warp = 0.0_wp
    this%damage_fill = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE Fabric_MatState_InitFromInputs

  SUBROUTINE Fabric_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Fabric_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Fabric_MatCtx_InitFromInputs

  SUBROUTINE Fabric_MatCtx_InitDefaults(this)
    CLASS(Fabric_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Fabric_MatCtx_InitDefaults

  SUBROUTINE Fabric_MatAlgo_InitDefaults(this)
    CLASS(Fabric_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%failure_criterion = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Fabric_MatAlgo_InitDefaults

  !=============================================================================
  ! ThermoMech Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE ThermoMech_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(ThermoMech_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 6) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "ThermoMech_MatDesc: Insufficient properties (need at least 6)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%alpha_T = props(3)
    this%k_thermal = props(4)
    this%rho = props(5)
    this%c_p = props(6)
    this%cfg%id = 1000_i4
    this%name = "Thermo-Mechanical Coupled"
    this%cfg%class_id = MD_MAT_CATEGORY_MULTIPHYS
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE ThermoMech_MatDesc_InitFromProps

  FUNCTION ThermoMech_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(ThermoMech_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%k_thermal > ZERO .AND. &
               this%rho > ZERO .AND. this%c_p > ZERO
  END FUNCTION ThermoMech_MatDesc_Valid

  SUBROUTINE ThermoMech_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(ThermoMech_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      statev(offset + i) = this%eps_p(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%T
    END IF
  END SUBROUTINE ThermoMech_MatState_SyncToStateV

  SUBROUTINE ThermoMech_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(ThermoMech_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) ALLOCATE(this%eps_p(6))
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      this%eps_p(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%T = statev(offset + 1)
    ELSE
      this%T = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermoMech_MatState_SyncFromStateV

  SUBROUTINE ThermoMech_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(ThermoMech_MatState), INTENT(INOUT) :: this
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
    this%T = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermoMech_MatState_InitFromInputs

  SUBROUTINE ThermoMech_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(ThermoMech_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE ThermoMech_MatCtx_InitFromInputs

  SUBROUTINE ThermoMech_MatCtx_InitDefaults(this)
    CLASS(ThermoMech_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermoMech_MatCtx_InitDefaults

  SUBROUTINE ThermoMech_MatAlgo_InitDefaults(this)
    CLASS(ThermoMech_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%coupling_type = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE ThermoMech_MatAlgo_InitDefaults

  !=============================================================================
  ! MagnetoMech Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE MagnetoMech_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(MagnetoMech_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MagnetoMech_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%mu_r = props(3)
    this%alpha_mag = props(4)
    this%cfg%id = 1005_i4
    this%name = "Magneto-Mechanical"
    this%cfg%class_id = MD_MAT_CATEGORY_MULTIPHYS
    this%pop%nProps = nprops
    this%pop%nStateV = 6
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MagnetoMech_MatDesc_InitFromProps

  FUNCTION MagnetoMech_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(MagnetoMech_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%mu_r > ZERO
  END FUNCTION MagnetoMech_MatDesc_Valid

  SUBROUTINE MagnetoMech_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(MagnetoMech_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    DO i = 1, MIN(3, SIZE(this%B_field, 1), nstatev - offset)
      statev(offset + i) = this%B_field(i)
      offset = offset + 1
    END DO
    DO i = 1, MIN(3, SIZE(this%H_field, 1), nstatev - offset)
      statev(offset + i) = this%H_field(i)
      offset = offset + 1
    END DO
  END SUBROUTINE MagnetoMech_MatState_SyncToStateV

  SUBROUTINE MagnetoMech_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(MagnetoMech_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    DO i = 1, MIN(3, SIZE(this%B_field, 1), nstatev - offset)
      this%B_field(i) = statev(offset + i)
      offset = offset + 1
    END DO
    DO i = 1, MIN(3, SIZE(this%H_field, 1), nstatev - offset)
      this%H_field(i) = statev(offset + i)
      offset = offset + 1
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE MagnetoMech_MatState_SyncFromStateV

  SUBROUTINE MagnetoMech_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(MagnetoMech_MatState), INTENT(INOUT) :: this
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
    this%B_field = 0.0_wp
    this%H_field = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE MagnetoMech_MatState_InitFromInputs

  SUBROUTINE MagnetoMech_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, H_field_ext, kstep, kinc)
    CLASS(MagnetoMech_MatCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    REAL(wp), INTENT(IN), OPTIONAL :: temp, dtime, H_field_ext(3)
    INTEGER(i4), INTENT(IN), OPTIONAL :: kstep, kinc
    this%ndir = ndir
    this%nshr = nshr
    this%ntens = ndir + nshr
    IF (PRESENT(temp)) this%temp = temp
    IF (PRESENT(dtime)) this%dtime = dtime
    IF (PRESENT(H_field_ext)) this%H_field_ext = H_field_ext
    IF (PRESENT(kstep)) this%kstep = kstep
    IF (PRESENT(kinc)) this%kinc = kinc
    this%is_initialized = .TRUE.
  END SUBROUTINE MagnetoMech_MatCtx_InitFromInputs

  SUBROUTINE MagnetoMech_MatCtx_InitDefaults(this)
    CLASS(MagnetoMech_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%H_field_ext = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE MagnetoMech_MatCtx_InitDefaults

  SUBROUTINE MagnetoMech_MatAlgo_InitDefaults(this)
    CLASS(MagnetoMech_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%coupling_type = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE MagnetoMech_MatAlgo_InitDefaults

  !=============================================================================
  ! PoroFluid Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE PoroFluid_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(PoroFluid_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 5) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "PoroFluid_MatDesc: Insufficient properties (need at least 5)"
      RETURN
    END IF
    this%MD_MAT_E_solid = props(1)
    this%nu_solid = props(2)
    this%k_perm = props(3)
    this%phi_porosity = props(4)
    this%K_f = props(5)
    this%cfg%id = 1006_i4
    this%name = "Poro-Fluid-Structure (Biot)"
    this%cfg%class_id = MD_MAT_CATEGORY_MULTIPHYS
    this%pop%nProps = nprops
    this%pop%nStateV = 4
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE PoroFluid_MatDesc_InitFromProps

  FUNCTION PoroFluid_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(PoroFluid_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_solid > ZERO .AND. this%k_perm > ZERO .AND. &
               this%phi_porosity >= ZERO .AND. this%phi_porosity <= 1.0_wp .AND. this%K_f > ZERO
  END FUNCTION PoroFluid_MatDesc_Valid

  SUBROUTINE PoroFluid_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(PoroFluid_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%p_pore
      offset = offset + 1
    END IF
    DO i = 1, MIN(3, SIZE(this%q_flux, 1), nstatev - offset)
      statev(offset + i) = this%q_flux(i)
      offset = offset + 1
    END DO
  END SUBROUTINE PoroFluid_MatState_SyncToStateV

  SUBROUTINE PoroFluid_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(PoroFluid_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%p_pore = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%p_pore = 0.0_wp
    END IF
    DO i = 1, MIN(3, SIZE(this%q_flux, 1), nstatev - offset)
      this%q_flux(i) = statev(offset + i)
      offset = offset + 1
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE PoroFluid_MatState_SyncFromStateV

  SUBROUTINE PoroFluid_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(PoroFluid_MatState), INTENT(INOUT) :: this
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
    this%p_pore = 0.0_wp
    this%q_flux = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE PoroFluid_MatState_InitFromInputs

  SUBROUTINE PoroFluid_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(PoroFluid_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE PoroFluid_MatCtx_InitFromInputs

  SUBROUTINE PoroFluid_MatCtx_InitDefaults(this)
    CLASS(PoroFluid_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE PoroFluid_MatCtx_InitDefaults

  SUBROUTINE PoroFluid_MatAlgo_InitDefaults(this)
    CLASS(PoroFluid_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%biot_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE PoroFluid_MatAlgo_InitDefaults

  !=============================================================================
  ! BioSoftTissue Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE BioSoftTissue_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(BioSoftTissue_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 5) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "BioSoftTissue_MatDesc: Insufficient properties (need at least 5)"
      RETURN
    END IF
    this%mu = props(1)
    this%k1 = props(2)
    this%k2 = props(3)
    this%kappa = props(4)
    this%k = props(5)
    this%cfg%id = 1007_i4
    this%name = "Biological Soft Tissue (Holzapfel-Ogden)"
    this%cfg%class_id = MD_MAT_CATEGORY_MULTIPHYS
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE BioSoftTissue_MatDesc_InitFromProps

  FUNCTION BioSoftTissue_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(BioSoftTissue_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%mu > ZERO .AND. this%k1 > ZERO .AND. this%k2 > ZERO
  END FUNCTION BioSoftTissue_MatDesc_Valid

  SUBROUTINE BioSoftTissue_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(BioSoftTissue_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE BioSoftTissue_MatState_SyncToStateV

  SUBROUTINE BioSoftTissue_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(BioSoftTissue_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE BioSoftTissue_MatState_SyncFromStateV

  SUBROUTINE BioSoftTissue_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(BioSoftTissue_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE BioSoftTissue_MatState_InitFromInputs

  SUBROUTINE BioSoftTissue_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(BioSoftTissue_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE BioSoftTissue_MatCtx_InitFromInputs

  SUBROUTINE BioSoftTissue_MatCtx_InitDefaults(this)
    CLASS(BioSoftTissue_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE BioSoftTissue_MatCtx_InitDefaults

  SUBROUTINE BioSoftTissue_MatAlgo_InitDefaults(this)
    CLASS(BioSoftTissue_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%tissue_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE BioSoftTissue_MatAlgo_InitDefaults

  !=============================================================================
  ! NoCompression Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE NoCompression_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(NoCompression_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 2) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "NoCompression_MatDesc: Insufficient properties (need at least 2)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%cfg%id = 1103_i4
    this%name = "No-Compression Material"
    this%cfg%class_id = MD_MAT_CATEGORY_FOAM
    this%pop%nProps = nprops
    this%pop%nStateV = 1
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE NoCompression_MatDesc_InitFromProps

  FUNCTION NoCompression_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(NoCompression_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO
  END FUNCTION NoCompression_MatDesc_Valid

  SUBROUTINE NoCompression_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(NoCompression_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (this%is_initialized .AND. nstatev >= 1) statev(1) = this%damage
  END SUBROUTINE NoCompression_MatState_SyncToStateV

  SUBROUTINE NoCompression_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(NoCompression_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (nstatev >= 1) THEN
      this%damage = statev(1)
    ELSE
      this%damage = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE NoCompression_MatState_SyncFromStateV

  SUBROUTINE NoCompression_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(NoCompression_MatState), INTENT(INOUT) :: this
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
    this%damage = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE NoCompression_MatState_InitFromInputs

  SUBROUTINE NoCompression_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(NoCompression_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE NoCompression_MatCtx_InitFromInputs

  SUBROUTINE NoCompression_MatCtx_InitDefaults(this)
    CLASS(NoCompression_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE NoCompression_MatCtx_InitDefaults

  SUBROUTINE NoCompression_MatAlgo_InitDefaults(this)
    CLASS(NoCompression_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%compression_cutoff_method = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE NoCompression_MatAlgo_InitDefaults

  !=============================================================================
  ! Multiscale Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Multiscale_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Multiscale_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 2) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Multiscale_MatDesc: Insufficient properties (need at least 2)"
      RETURN
    END IF
    this%MD_MAT_E_eff = props(1)
    this%nu_eff = props(2)
    IF (nprops >= 3) this%rve_type = INT(props(3))
    this%cfg%id = 1104_i4
    this%name = "Multiscale RVE Material"
    this%cfg%class_id = MD_MAT_CATEGORY_FOAM
    this%pop%nProps = nprops
    this%pop%nStateV = 6
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Multiscale_MatDesc_InitFromProps

  FUNCTION Multiscale_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Multiscale_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_eff > ZERO
  END FUNCTION Multiscale_MatDesc_Valid

  SUBROUTINE Multiscale_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Multiscale_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_micro)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_micro, 1), nstatev - offset)
      statev(offset + i) = this%eps_micro(i)
      offset = offset + 1
    END DO
  END SUBROUTINE Multiscale_MatState_SyncToStateV

  SUBROUTINE Multiscale_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Multiscale_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_micro)) ALLOCATE(this%eps_micro(6))
    DO i = 1, MIN(6, SIZE(this%eps_micro, 1), nstatev - offset)
      this%eps_micro(i) = statev(offset + i)
      offset = offset + 1
    END DO
    this%is_initialized = .TRUE.
  END SUBROUTINE Multiscale_MatState_SyncFromStateV

  SUBROUTINE Multiscale_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Multiscale_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (.NOT. ALLOCATED(this%eps_micro)) THEN
      ALLOCATE(this%eps_micro(ntens))
      this%eps_micro = 0.0_wp
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
    this%is_initialized = .TRUE.
  END SUBROUTINE Multiscale_MatState_InitFromInputs

  SUBROUTINE Multiscale_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Multiscale_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Multiscale_MatCtx_InitFromInputs

  SUBROUTINE Multiscale_MatCtx_InitDefaults(this)
    CLASS(Multiscale_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Multiscale_MatCtx_InitDefaults

  SUBROUTINE Multiscale_MatAlgo_InitDefaults(this)
    CLASS(Multiscale_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%homogenization_method = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Multiscale_MatAlgo_InitDefaults

  !=============================================================================
  ! TempDependent Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE TempDependent_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(TempDependent_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "TempDependent_MatDesc: Insufficient properties (need at least 3)"
      RETURN
    END IF
    this%MD_MAT_E_ref = props(1)
    this%nu = props(2)
    this%alpha_T = props(3)
    IF (nprops >= 4) this%T_ref = props(4)
    this%cfg%id = 1105_i4
    this%name = "Temperature/Field-Dependent Generic"
    this%cfg%class_id = MD_MAT_CATEGORY_FOAM
    this%pop%nProps = nprops
    this%pop%nStateV = 1
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE TempDependent_MatDesc_InitFromProps

  FUNCTION TempDependent_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(TempDependent_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_ref > ZERO
  END FUNCTION TempDependent_MatDesc_Valid

  SUBROUTINE TempDependent_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(TempDependent_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (this%is_initialized .AND. nstatev >= 1) statev(1) = this%T_current
  END SUBROUTINE TempDependent_MatState_SyncToStateV

  SUBROUTINE TempDependent_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(TempDependent_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (nstatev >= 1) THEN
      this%T_current = statev(1)
    ELSE
      this%T_current = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE TempDependent_MatState_SyncFromStateV

  SUBROUTINE TempDependent_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(TempDependent_MatState), INTENT(INOUT) :: this
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
    this%T_current = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE TempDependent_MatState_InitFromInputs

  SUBROUTINE TempDependent_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(TempDependent_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE TempDependent_MatCtx_InitFromInputs

  SUBROUTINE TempDependent_MatCtx_InitDefaults(this)
    CLASS(TempDependent_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE TempDependent_MatCtx_InitDefaults

  SUBROUTINE TempDependent_MatAlgo_InitDefaults(this)
    CLASS(TempDependent_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%temp_dependency_law = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE TempDependent_MatAlgo_InitDefaults

  !=============================================================================
  ! MC_Geo Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE MC_Geo_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(MC_Geo_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MC_Geo_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%phi = props(3)
    this%c = props(4)
    IF (nprops >= 5) this%psi = props(5)
    this%cfg%id = 200_i4
    this%name = "Mohr-Coulomb Geotechnical"
    this%cfg%class_id = MD_MAT_CATEGORY_GEOMAT
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MC_Geo_MatDesc_InitFromProps

  FUNCTION MC_Geo_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(MC_Geo_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%phi > ZERO .AND. this%c >= ZERO
  END FUNCTION MC_Geo_MatDesc_Valid

  SUBROUTINE MC_Geo_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(MC_Geo_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      statev(offset + i) = this%eps_p(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%alpha
    END IF
  END SUBROUTINE MC_Geo_MatState_SyncToStateV

  SUBROUTINE MC_Geo_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(MC_Geo_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) ALLOCATE(this%eps_p(6))
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      this%eps_p(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%alpha = statev(offset + 1)
    ELSE
      this%alpha = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE MC_Geo_MatState_SyncFromStateV

  SUBROUTINE MC_Geo_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(MC_Geo_MatState), INTENT(INOUT) :: this
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
    this%alpha = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE MC_Geo_MatState_InitFromInputs

  SUBROUTINE MC_Geo_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(MC_Geo_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE MC_Geo_MatCtx_InitFromInputs

  SUBROUTINE MC_Geo_MatCtx_InitDefaults(this)
    CLASS(MC_Geo_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE MC_Geo_MatCtx_InitDefaults

  SUBROUTINE MC_Geo_MatAlgo_InitDefaults(this)
    CLASS(MC_Geo_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE MC_Geo_MatAlgo_InitDefaults

  !=============================================================================
  ! MD_MAT_DP_Geo Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE MD_MAT_DP_Geo_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(MD_MAT_DP_Geo_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MD_MAT_DP_Geo_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%phi = props(3)
    this%c = props(4)
    IF (nprops >= 5) this%beta = props(5)
    this%cfg%id = 801_i4
    this%name = "Drucker-Prager Geotechnical"
    this%cfg%class_id = MD_MAT_CATEGORY_GEOMAT
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_MAT_DP_Geo_MatDesc_InitFromProps

  FUNCTION MD_MAT_DP_Geo_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(MD_MAT_DP_Geo_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%phi > ZERO .AND. this%c >= ZERO
  END FUNCTION MD_MAT_DP_Geo_MatDesc_Valid

  SUBROUTINE MD_MAT_DP_Geo_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(MD_MAT_DP_Geo_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      statev(offset + i) = this%eps_p(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%alpha
    END IF
  END SUBROUTINE MD_MAT_DP_Geo_MatState_SyncToStateV

  SUBROUTINE MD_MAT_DP_Geo_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(MD_MAT_DP_Geo_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) ALLOCATE(this%eps_p(6))
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      this%eps_p(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%alpha = statev(offset + 1)
    ELSE
      this%alpha = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE MD_MAT_DP_Geo_MatState_SyncFromStateV

  SUBROUTINE MD_MAT_DP_Geo_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(MD_MAT_DP_Geo_MatState), INTENT(INOUT) :: this
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
    this%alpha = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE MD_MAT_DP_Geo_MatState_InitFromInputs

  SUBROUTINE MD_MAT_DP_Geo_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(MD_MAT_DP_Geo_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE MD_MAT_DP_Geo_MatCtx_InitFromInputs

  SUBROUTINE MD_MAT_DP_Geo_MatCtx_InitDefaults(this)
    CLASS(MD_MAT_DP_Geo_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE MD_MAT_DP_Geo_MatCtx_InitDefaults

  SUBROUTINE MD_MAT_DP_Geo_MatAlgo_InitDefaults(this)
    CLASS(MD_MAT_DP_Geo_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE MD_MAT_DP_Geo_MatAlgo_InitDefaults

  !=============================================================================
  ! CappedDP Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE CappedDP_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(CappedDP_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 7) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "CappedDP_MatDesc: Insufficient properties (need at least 7)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%phi = props(3)
    this%c = props(4)
    this%beta = props(5)
    this%R = props(6)
    this%p_t = props(7)
    this%cfg%id = 803_i4
    this%name = "Capped Drucker-Prager"
    this%cfg%class_id = MD_MAT_CATEGORY_GEOMAT
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE CappedDP_MatDesc_InitFromProps

  FUNCTION CappedDP_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(CappedDP_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%phi > ZERO .AND. this%c >= ZERO
  END FUNCTION CappedDP_MatDesc_Valid

  SUBROUTINE CappedDP_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(CappedDP_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      statev(offset + i) = this%eps_p(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_v_p
    END IF
  END SUBROUTINE CappedDP_MatState_SyncToStateV

  SUBROUTINE CappedDP_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(CappedDP_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) ALLOCATE(this%eps_p(6))
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      this%eps_p(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%eps_v_p = statev(offset + 1)
    ELSE
      this%eps_v_p = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE CappedDP_MatState_SyncFromStateV

  SUBROUTINE CappedDP_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(CappedDP_MatState), INTENT(INOUT) :: this
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
    this%eps_v_p = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE CappedDP_MatState_InitFromInputs

  SUBROUTINE CappedDP_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(CappedDP_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE CappedDP_MatCtx_InitFromInputs

  SUBROUTINE CappedDP_MatCtx_InitDefaults(this)
    CLASS(CappedDP_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE CappedDP_MatCtx_InitDefaults

  SUBROUTINE CappedDP_MatAlgo_InitDefaults(this)
    CLASS(CappedDP_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE CappedDP_MatAlgo_InitDefaults

  !=============================================================================
  ! JointedRock Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE JointedRock_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(JointedRock_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 6) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "JointedRock_MatDesc: Insufficient properties (need at least 6)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%phi_joint = props(3)
    this%c_joint = props(4)
    this%k_n_joint = props(5)
    this%k_s_joint = props(6)
    this%cfg%id = 805_i4
    this%name = "Jointed Rock"
    this%cfg%class_id = MD_MAT_CATEGORY_GEOMAT
    this%pop%nProps = nprops
    this%pop%nStateV = 2
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE JointedRock_MatDesc_InitFromProps

  FUNCTION JointedRock_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(JointedRock_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%phi_joint > ZERO .AND. &
               this%k_n_joint > ZERO .AND. this%k_s_joint > ZERO
  END FUNCTION JointedRock_MatDesc_Valid

  SUBROUTINE JointedRock_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(JointedRock_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%delta_joint_n
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%delta_joint_s
    END IF
  END SUBROUTINE JointedRock_MatState_SyncToStateV

  SUBROUTINE JointedRock_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(JointedRock_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%delta_joint_n = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%delta_joint_n = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%delta_joint_s = statev(offset + 1)
    ELSE
      this%delta_joint_s = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE JointedRock_MatState_SyncFromStateV

  SUBROUTINE JointedRock_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(JointedRock_MatState), INTENT(INOUT) :: this
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
    this%delta_joint_n = 0.0_wp
    this%delta_joint_s = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE JointedRock_MatState_InitFromInputs

  SUBROUTINE JointedRock_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(JointedRock_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE JointedRock_MatCtx_InitFromInputs

  SUBROUTINE JointedRock_MatCtx_InitDefaults(this)
    CLASS(JointedRock_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE JointedRock_MatCtx_InitDefaults

  SUBROUTINE JointedRock_MatAlgo_InitDefaults(this)
    CLASS(JointedRock_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%joint_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE JointedRock_MatAlgo_InitDefaults

  !=============================================================================
  ! GeoCreep Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE GeoCreep_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(GeoCreep_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 5) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "GeoCreep_MatDesc: Insufficient properties (need at least 5)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%A_creep = props(3)
    this%n_creep = props(4)
    this%Q_creep = props(5)
    IF (nprops >= 6) this%T_ref = props(6)
    this%cfg%id = 806_i4
    this%name = "Geotechnical Creep"
    this%cfg%class_id = MD_MAT_CATEGORY_GEOMAT
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE GeoCreep_MatDesc_InitFromProps

  FUNCTION GeoCreep_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(GeoCreep_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%A_creep > ZERO .AND. this%n_creep > ZERO
  END FUNCTION GeoCreep_MatDesc_Valid

  SUBROUTINE GeoCreep_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(GeoCreep_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_c)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_c, 1), nstatev - offset)
      statev(offset + i) = this%eps_c(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_c_eqv
    END IF
  END SUBROUTINE GeoCreep_MatState_SyncToStateV

  SUBROUTINE GeoCreep_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(GeoCreep_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_c)) ALLOCATE(this%eps_c(6))
    DO i = 1, MIN(6, SIZE(this%eps_c, 1), nstatev - offset)
      this%eps_c(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%eps_c_eqv = statev(offset + 1)
    ELSE
      this%eps_c_eqv = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE GeoCreep_MatState_SyncFromStateV

  SUBROUTINE GeoCreep_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(GeoCreep_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (.NOT. ALLOCATED(this%eps_c)) THEN
      ALLOCATE(this%eps_c(ntens))
      this%eps_c = 0.0_wp
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
    this%eps_c_eqv = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE GeoCreep_MatState_InitFromInputs

  SUBROUTINE GeoCreep_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(GeoCreep_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE GeoCreep_MatCtx_InitFromInputs

  SUBROUTINE GeoCreep_MatCtx_InitDefaults(this)
    CLASS(GeoCreep_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE GeoCreep_MatCtx_InitDefaults

  SUBROUTINE GeoCreep_MatAlgo_InitDefaults(this)
    CLASS(GeoCreep_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%creep_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE GeoCreep_MatAlgo_InitDefaults

  !=============================================================================
  ! ExtDP Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE ExtDP_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(ExtDP_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 5) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "ExtDP_MatDesc: Insufficient properties (need at least 5)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%phi = props(3)
    this%c = props(4)
    this%beta = props(5)
    IF (nprops >= 6) this%k = props(6)
    this%cfg%id = 801_i4
    this%name = "Extended Drucker-Prager"
    this%cfg%class_id = MD_MAT_CATEGORY_GEOMAT
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE ExtDP_MatDesc_InitFromProps

  FUNCTION ExtDP_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(ExtDP_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%phi > ZERO .AND. this%c >= ZERO
  END FUNCTION ExtDP_MatDesc_Valid

  SUBROUTINE ExtDP_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(ExtDP_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      statev(offset + i) = this%eps_p(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%alpha
    END IF
  END SUBROUTINE ExtDP_MatState_SyncToStateV

  SUBROUTINE ExtDP_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(ExtDP_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) ALLOCATE(this%eps_p(6))
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      this%eps_p(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%alpha = statev(offset + 1)
    ELSE
      this%alpha = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE ExtDP_MatState_SyncFromStateV

  SUBROUTINE ExtDP_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(ExtDP_MatState), INTENT(INOUT) :: this
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
    this%alpha = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE ExtDP_MatState_InitFromInputs

  SUBROUTINE ExtDP_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(ExtDP_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE ExtDP_MatCtx_InitFromInputs

  SUBROUTINE ExtDP_MatCtx_InitDefaults(this)
    CLASS(ExtDP_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE ExtDP_MatCtx_InitDefaults

  SUBROUTINE ExtDP_MatAlgo_InitDefaults(this)
    CLASS(ExtDP_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE ExtDP_MatAlgo_InitDefaults

  !=============================================================================
  ! Ortho3D Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Ortho3D_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Ortho3D_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 9) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Ortho3D_MatDesc: Insufficient properties (need at least 9)"
      RETURN
    END IF
    this%E1 = props(1)
    this%E2 = props(2)
    this%E3 = props(3)
    this%nu12 = props(4)
    this%nu13 = props(5)
    this%nu23 = props(6)
    this%G12 = props(7)
    this%G13 = props(8)
    this%G23 = props(9)
    this%cfg%id = 901_i4
    this%name = "3D Orthotropic Elastic"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Ortho3D_MatDesc_InitFromProps

  FUNCTION Ortho3D_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Ortho3D_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E1 > ZERO .AND. this%E2 > ZERO .AND. this%E3 > ZERO .AND. &
               this%G12 > ZERO .AND. this%G13 > ZERO .AND. this%G23 > ZERO
  END FUNCTION Ortho3D_MatDesc_Valid

  SUBROUTINE Ortho3D_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Ortho3D_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE Ortho3D_MatState_SyncToStateV

  SUBROUTINE Ortho3D_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Ortho3D_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE Ortho3D_MatState_SyncFromStateV

  SUBROUTINE Ortho3D_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Ortho3D_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE Ortho3D_MatState_InitFromInputs

  SUBROUTINE Ortho3D_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Ortho3D_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Ortho3D_MatCtx_InitFromInputs

  SUBROUTINE Ortho3D_MatCtx_InitDefaults(this)
    CLASS(Ortho3D_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Ortho3D_MatCtx_InitDefaults

  SUBROUTINE Ortho3D_MatAlgo_InitDefaults(this)
    CLASS(Ortho3D_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Ortho3D_MatAlgo_InitDefaults

  !=============================================================================
  ! Aniso21 Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Aniso21_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Aniso21_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, j, idx
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 21) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Aniso21_MatDesc: Insufficient properties (need at least 21)"
      RETURN
    END IF
    idx = 1
    DO i = 1, 6
      DO j = i, 6
        this%C(i,j) = props(idx)
        IF (i /= j) this%C(j,i) = props(idx)
        idx = idx + 1
      END DO
    END DO
    this%cfg%id = 902_i4
    this%name = "Full Anisotropic (21 constants)"
    this%cfg%class_id = MD_MAT_CATEGORY_COMPOSITE
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Aniso21_MatDesc_InitFromProps

  FUNCTION Aniso21_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Aniso21_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    is_valid = this%is_initialized
  END FUNCTION Aniso21_MatDesc_Valid

  SUBROUTINE Aniso21_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Aniso21_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE Aniso21_MatState_SyncToStateV

  SUBROUTINE Aniso21_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Aniso21_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE Aniso21_MatState_SyncFromStateV

  SUBROUTINE Aniso21_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Aniso21_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE Aniso21_MatState_InitFromInputs

  SUBROUTINE Aniso21_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Aniso21_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Aniso21_MatCtx_InitFromInputs

  SUBROUTINE Aniso21_MatCtx_InitDefaults(this)
    CLASS(Aniso21_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Aniso21_MatCtx_InitDefaults

  SUBROUTINE Aniso21_MatAlgo_InitDefaults(this)
    CLASS(Aniso21_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Aniso21_MatAlgo_InitDefaults

  !=============================================================================
  ! VDW Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE VDW_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(VDW_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "VDW_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%mu = props(1)
    this%lambda_m = props(2)
    this%a_global = props(3)
    this%beta_vdw = props(4)
    IF (nprops >= 5) this%nu = props(5)
    this%cfg%id = 452_i4
    this%name = "Van der Waals"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE VDW_MatDesc_InitFromProps

  FUNCTION VDW_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(VDW_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%mu > ZERO .AND. this%lambda_m > ZERO
  END FUNCTION VDW_MatDesc_Valid

  SUBROUTINE VDW_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(VDW_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE VDW_MatState_SyncToStateV

  SUBROUTINE VDW_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(VDW_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE VDW_MatState_SyncFromStateV

  SUBROUTINE VDW_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(VDW_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE VDW_MatState_InitFromInputs

  SUBROUTINE VDW_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(VDW_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE VDW_MatCtx_InitFromInputs

  SUBROUTINE VDW_MatCtx_InitDefaults(this)
    CLASS(VDW_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE VDW_MatCtx_InitDefaults

  SUBROUTINE VDW_MatAlgo_InitDefaults(this)
    CLASS(VDW_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE VDW_MatAlgo_InitDefaults

  !=============================================================================
  ! Marlow Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Marlow_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Marlow_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, n_data
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 2) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Marlow_MatDesc: Insufficient properties (need at least 2)"
      RETURN
    END IF
    this%n_data_points = MAX(1_i4, MIN(100_i4, INT(props(1))))
    n_data = this%n_data_points
    IF (.NOT. ALLOCATED(this%strain_data)) THEN
      ALLOCATE(this%strain_data(n_data), this%stress_data(n_data))
    END IF
    DO i = 1, MIN(n_data, (nprops - 1) / 2)
      IF (nprops >= 1 + 2*i) THEN
        this%strain_data(i) = props(1 + 2*i - 1)
        this%stress_data(i) = props(1 + 2*i)
      END IF
    END DO
    this%cfg%id = 453_i4
    this%name = "Marlow Data-Driven"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Marlow_MatDesc_InitFromProps

  FUNCTION Marlow_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Marlow_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    is_valid = this%is_initialized .AND. this%n_data_points > 0
    IF (ALLOCATED(this%strain_data) .AND. ALLOCATED(this%stress_data)) THEN
      is_valid = is_valid .AND. SIZE(this%strain_data) == this%n_data_points .AND. &
                 SIZE(this%stress_data) == this%n_data_points
    END IF
  END FUNCTION Marlow_MatDesc_Valid

  SUBROUTINE Marlow_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Marlow_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE Marlow_MatState_SyncToStateV

  SUBROUTINE Marlow_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Marlow_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE Marlow_MatState_SyncFromStateV

  SUBROUTINE Marlow_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Marlow_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE Marlow_MatState_InitFromInputs

  SUBROUTINE Marlow_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Marlow_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Marlow_MatCtx_InitFromInputs

  SUBROUTINE Marlow_MatCtx_InitDefaults(this)
    CLASS(Marlow_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Marlow_MatCtx_InitDefaults

  SUBROUTINE Marlow_MatAlgo_InitDefaults(this)
    CLASS(Marlow_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%interpolation_method = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Marlow_MatAlgo_InitDefaults

  !=============================================================================
  ! Gent Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE Gent_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(Gent_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Gent_MatDesc: Insufficient properties (need at least 3)"
      RETURN
    END IF
    this%mu = props(1)
    this%J_m = props(2)
    this%D1 = props(3)
    this%cfg%id = 306_i4
    this%name = "Gent"
    this%cfg%class_id = MD_MAT_CATEGORY_HY
    this%pop%nProps = nprops
    this%pop%nStateV = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Gent_MatDesc_InitFromProps

  FUNCTION Gent_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(Gent_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%mu > ZERO .AND. this%J_m > ZERO .AND. this%D1 > ZERO
  END FUNCTION Gent_MatDesc_Valid

  SUBROUTINE Gent_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(Gent_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    IF (.NOT. this%is_initialized) RETURN
  END SUBROUTINE Gent_MatState_SyncToStateV

  SUBROUTINE Gent_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(Gent_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    this%is_initialized = .TRUE.
  END SUBROUTINE Gent_MatState_SyncFromStateV

  SUBROUTINE Gent_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(Gent_MatState), INTENT(INOUT) :: this
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
  END SUBROUTINE Gent_MatState_InitFromInputs

  SUBROUTINE Gent_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(Gent_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE Gent_MatCtx_InitFromInputs

  SUBROUTINE Gent_MatCtx_InitDefaults(this)
    CLASS(Gent_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE Gent_MatCtx_InitDefaults

  SUBROUTINE Gent_MatAlgo_InitDefaults(this)
    CLASS(Gent_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%formulation = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE Gent_MatAlgo_InitDefaults

  !=============================================================================
  ! MC_Concrete Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE MC_Concrete_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(MC_Concrete_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MC_Concrete_MatDesc: Insufficient properties (need at least 4)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%phi = props(3)
    this%c = props(4)
    IF (nprops >= 5) this%psi = props(5)
    this%cfg%id = 703_i4
    this%name = "Mohr-Coulomb Elastoplastic Concrete"
    this%cfg%class_id = MD_MAT_CATEGORY_CONCRETE
    this%pop%nProps = nprops
    this%pop%nStateV = 7
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MC_Concrete_MatDesc_InitFromProps

  FUNCTION MC_Concrete_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(MC_Concrete_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%phi > ZERO .AND. this%c >= ZERO
  END FUNCTION MC_Concrete_MatDesc_Valid

  SUBROUTINE MC_Concrete_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(MC_Concrete_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      statev(offset + i) = this%eps_p(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%alpha
    END IF
  END SUBROUTINE MC_Concrete_MatState_SyncToStateV

  SUBROUTINE MC_Concrete_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(MC_Concrete_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) ALLOCATE(this%eps_p(6))
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      this%eps_p(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%alpha = statev(offset + 1)
    ELSE
      this%alpha = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE MC_Concrete_MatState_SyncFromStateV

  SUBROUTINE MC_Concrete_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(MC_Concrete_MatState), INTENT(INOUT) :: this
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
    this%alpha = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE MC_Concrete_MatState_InitFromInputs

  SUBROUTINE MC_Concrete_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(MC_Concrete_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE MC_Concrete_MatCtx_InitFromInputs

  SUBROUTINE MC_Concrete_MatCtx_InitDefaults(this)
    CLASS(MC_Concrete_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE MC_Concrete_MatCtx_InitDefaults

  SUBROUTINE MC_Concrete_MatAlgo_InitDefaults(this)
    CLASS(MC_Concrete_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE MC_Concrete_MatAlgo_InitDefaults

  !=============================================================================
  ! NL_Visc Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE NL_Visc_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(NL_Visc_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 2) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "NL_Visc_MatDesc: Insufficient properties (need at least 2)"
      RETURN
    END IF
    this%MD_MAT_E_inf = props(1)
    this%nu = props(2)
    IF (nprops >= 3) this%n_prony = MAX(0_i4, MIN(10_i4, INT(props(3))))
    IF (this%n_prony > 0 .AND. nprops >= 3 + 2 * this%n_prony) THEN
      IF (.NOT. ALLOCATED(this%g_prony)) THEN
        ALLOCATE(this%g_prony(this%n_prony), this%tau_prony(this%n_prony))
      END IF
      DO i = 1, this%n_prony
        this%g_prony(i) = props(3 + i)
        this%tau_prony(i) = props(3 + this%n_prony + i)
      END DO
    END IF
    this%cfg%id = 506_i4
    this%name = "Nonlinear Viscoelastic"
    this%cfg%class_id = MD_MAT_CATEGORY_VI
    this%pop%nProps = nprops
    this%pop%nStateV = 6 * this%n_prony
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE NL_Visc_MatDesc_InitFromProps

  FUNCTION NL_Visc_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(NL_Visc_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_inf > ZERO
  END FUNCTION NL_Visc_MatDesc_Valid

  SUBROUTINE NL_Visc_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(NL_Visc_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, j, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (ALLOCATED(this%q_prony)) THEN
      DO i = 1, MIN(SIZE(this%q_prony, 1), nstatev / 6)
        DO j = 1, MIN(6, SIZE(this%q_prony, 2))
          IF (offset + j <= nstatev) statev(offset + j) = this%q_prony(i, j)
        END DO
        offset = offset + 6
      END DO
    END IF
  END SUBROUTINE NL_Visc_MatState_SyncToStateV

  SUBROUTINE NL_Visc_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(NL_Visc_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, j, n_prony, offset
    n_prony = nstatev / 6
    IF (n_prony > 0) THEN
      IF (.NOT. ALLOCATED(this%q_prony)) THEN
        ALLOCATE(this%q_prony(n_prony, 6))
        this%q_prony = 0.0_wp
      END IF
      offset = 0
      DO i = 1, MIN(n_prony, SIZE(this%q_prony, 1))
        DO j = 1, MIN(6, SIZE(this%q_prony, 2))
          IF (offset + j <= nstatev) this%q_prony(i, j) = statev(offset + j)
        END DO
        offset = offset + 6
      END DO
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE NL_Visc_MatState_SyncFromStateV

  SUBROUTINE NL_Visc_MatState_InitFromInputs(this, ndir, nshr, n_prony)
    CLASS(NL_Visc_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: ndir, nshr, n_prony
    INTEGER(i4) :: ntens
    ntens = ndir + nshr
    IF (n_prony > 0) THEN
      IF (.NOT. ALLOCATED(this%q_prony)) THEN
        ALLOCATE(this%q_prony(n_prony, ntens))
        this%q_prony = 0.0_wp
      END IF
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
    this%is_initialized = .TRUE.
  END SUBROUTINE NL_Visc_MatState_InitFromInputs

  SUBROUTINE NL_Visc_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(NL_Visc_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE NL_Visc_MatCtx_InitFromInputs

  SUBROUTINE NL_Visc_MatCtx_InitDefaults(this)
    CLASS(NL_Visc_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE NL_Visc_MatCtx_InitDefaults

  SUBROUTINE NL_Visc_MatAlgo_InitDefaults(this)
    CLASS(NL_Visc_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%visco_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE NL_Visc_MatAlgo_InitDefaults

  !=============================================================================
  ! PolymerCure Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE PolymerCure_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(PolymerCure_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 6) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "PolymerCure_MatDesc: Insufficient properties (need at least 6)"
      RETURN
    END IF
    this%MD_MAT_E_uncured = props(1)
    this%MD_MAT_E_cured = props(2)
    this%nu = props(3)
    this%A_cure = props(4)
    this%MD_MAT_E_a = props(5)
    this%n_cure = props(6)
    this%cfg%id = 508_i4
    this%name = "Polymer Cure"
    this%cfg%class_id = MD_MAT_CATEGORY_VI
    this%pop%nProps = nprops
    this%pop%nStateV = 2
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE PolymerCure_MatDesc_InitFromProps

  FUNCTION PolymerCure_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(PolymerCure_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%MD_MAT_E_uncured > ZERO .AND. this%MD_MAT_E_cured > ZERO .AND. &
               this%A_cure > ZERO .AND. this%MD_MAT_E_a > ZERO
  END FUNCTION PolymerCure_MatDesc_Valid

  SUBROUTINE PolymerCure_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(PolymerCure_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%alpha_cure
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%T_cure
    END IF
  END SUBROUTINE PolymerCure_MatState_SyncToStateV

  SUBROUTINE PolymerCure_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(PolymerCure_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: offset
    offset = 0
    IF (nstatev >= offset + 1) THEN
      this%alpha_cure = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%alpha_cure = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%T_cure = statev(offset + 1)
    ELSE
      this%T_cure = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE PolymerCure_MatState_SyncFromStateV

  SUBROUTINE PolymerCure_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(PolymerCure_MatState), INTENT(INOUT) :: this
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
    this%alpha_cure = 0.0_wp
    this%T_cure = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE PolymerCure_MatState_InitFromInputs

  SUBROUTINE PolymerCure_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(PolymerCure_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE PolymerCure_MatCtx_InitFromInputs

  SUBROUTINE PolymerCure_MatCtx_InitDefaults(this)
    CLASS(PolymerCure_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE PolymerCure_MatCtx_InitDefaults

  SUBROUTINE PolymerCure_MatAlgo_InitDefaults(this)
    CLASS(PolymerCure_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%cure_model = 1
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE PolymerCure_MatAlgo_InitDefaults

  !=============================================================================
  ! ViscPlastDmg Type-Bound Procedures
  !=============================================================================

  !=============================================================================

  SUBROUTINE ViscPlastDmg_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(ViscPlastDmg_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    CALL init_error_status(status)
    IF (nprops < 6) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "ViscPlastDmg_MatDesc: Insufficient properties (need at least 6)"
      RETURN
    END IF
    this%E = props(1)
    this%nu = props(2)
    this%sigma_y = props(3)
    this%K_visc = props(4)
    this%n_visc = props(5)
    this%eps_f = props(6)
    this%cfg%id = 509_i4
    this%name = "Viscoplastic Damage"
    this%cfg%class_id = MD_MAT_CATEGORY_DA
    this%pop%nProps = nprops
    this%pop%nStateV = 8
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE ViscPlastDmg_MatDesc_InitFromProps

  FUNCTION ViscPlastDmg_MatDesc_Valid(this) RESULT(is_valid)
    CLASS(ViscPlastDmg_MatDesc), INTENT(IN) :: this
    LOGICAL :: is_valid
    REAL(wp), PARAMETER :: ZERO = 0.0_wp
    is_valid = this%is_initialized .AND. this%E > ZERO .AND. this%sigma_y > ZERO .AND. &
               this%K_visc > ZERO .AND. this%n_visc > ZERO .AND. this%eps_f > ZERO
  END FUNCTION ViscPlastDmg_MatDesc_Valid

  SUBROUTINE ViscPlastDmg_MatState_SyncToStateV(this, statev, nstatev)
    CLASS(ViscPlastDmg_MatState), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    IF (.NOT. this%is_initialized) RETURN
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) RETURN
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      statev(offset + i) = this%eps_p(i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%damage
      offset = offset + 1
    END IF
    IF (nstatev >= offset + 1) THEN
      statev(offset + 1) = this%eps_p_eqv
    END IF
  END SUBROUTINE ViscPlastDmg_MatState_SyncToStateV

  SUBROUTINE ViscPlastDmg_MatState_SyncFromStateV(this, statev, nstatev)
    CLASS(ViscPlastDmg_MatState), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: nstatev
    INTEGER(i4) :: i, offset
    offset = 0
    IF (.NOT. ALLOCATED(this%eps_p)) ALLOCATE(this%eps_p(6))
    DO i = 1, MIN(6, SIZE(this%eps_p, 1), nstatev - offset)
      this%eps_p(i) = statev(offset + i)
      offset = offset + 1
    END DO
    IF (nstatev >= offset + 1) THEN
      this%damage = statev(offset + 1)
      offset = offset + 1
    ELSE
      this%damage = 0.0_wp
    END IF
    IF (nstatev >= offset + 1) THEN
      this%eps_p_eqv = statev(offset + 1)
    ELSE
      this%eps_p_eqv = 0.0_wp
    END IF
    this%is_initialized = .TRUE.
  END SUBROUTINE ViscPlastDmg_MatState_SyncFromStateV

  SUBROUTINE ViscPlastDmg_MatState_InitFromInputs(this, ndir, nshr)
    CLASS(ViscPlastDmg_MatState), INTENT(INOUT) :: this
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
    this%damage = 0.0_wp
    this%eps_p_eqv = 0.0_wp
    this%is_initialized = .TRUE.
  END SUBROUTINE ViscPlastDmg_MatState_InitFromInputs

  SUBROUTINE ViscPlastDmg_MatCtx_InitFromInputs(this, ndir, nshr, temp, dtime, kstep, kinc)
    CLASS(ViscPlastDmg_MatCtx), INTENT(INOUT) :: this
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
  END SUBROUTINE ViscPlastDmg_MatCtx_InitFromInputs

  SUBROUTINE ViscPlastDmg_MatCtx_InitDefaults(this)
    CLASS(ViscPlastDmg_MatCtx), INTENT(INOUT) :: this
    this%ndir = 3
    this%nshr = 3
    this%ntens = 6
    this%temp = 0.0_wp
    this%dtime = 0.0_wp
    this%kstep = 0
    this%kinc = 0
    this%is_initialized = .TRUE.
  END SUBROUTINE ViscPlastDmg_MatCtx_InitDefaults

  SUBROUTINE ViscPlastDmg_MatAlgo_InitDefaults(this)
    CLASS(ViscPlastDmg_MatAlgo), INTENT(INOUT) :: this
    this%method = 1
    this%maxIter = 20
    this%tolerance = 1.0e-8_wp
    this%useconsistentta = .TRUE.
    this%return_mapping_method = 1
    this%yield_tolerance = 1.0e-6_wp
    this%use_consistent_tangent = .TRUE.
    this%is_initialized = .TRUE.
  END SUBROUTINE ViscPlastDmg_MatAlgo_InitDefaults

END MODULE MD_Mat_User_Contract
