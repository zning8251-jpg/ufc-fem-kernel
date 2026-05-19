!===============================================================================
! MODULE: MD_Mat_Lib
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Lib
! BRIEF:  Merged material library -- consolidated from 15+ legacy modules.
!         Provides UF_MaterialDef, UF_MaterialDB, material constants,
!         evaluation context, mem-pool, tree, utils, dispatch, UMAT bridge.
! **W1**：**L3 材料库汇局面**；Populate 侧 **`MD_Mat_Validate*ForPopulate`**；**`MD_Mat_Desc`/`props`** 与
!         **`UF_Mat_Eval_Dispatch_FromDesc`**、**`UF_Elastic/Plastic_Eval_Dispatch_FromDesc`** 再导出；**`mat_id`/UMAT/L4**
!         经族 **`UF_*_Eval_Dispatch`** / **`UF_*_UMAT_Dispatch`**。
!===============================================================================

MODULE MD_Mat_Lib
    USE IF_Prec_Core, ONLY: i4, i8, wp
    USE IF_Base_Def, ONLY: ONE, TWO, ZERO
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
    USE IF_Mem_Mgr, ONLY: g_mem_pool, mem_alloc_pointer, mem_associate_pointer
    USE MD_Base_ObjModel, ONLY: CAT_DESC, ObjContainer
    USE MD_Base_TreeIndex
    USE MD_Mat_Def, ONLY: ExpDataPt, ExpDataSet, MD_Material_Ctx, MatCtxLegacy, MatFlags, MatParamId, MatProps, MatRes, &
         MatComp_RotMat, MatOri, MatPropValid, &
         MD_Mat_Desc, MD_Mat_Desc_SyncDeprecatedFlat, MD_MAT_CATEGORY_EL, MD_MAT_CATEGORY_PL, MD_MAT_CATEGORY_DA, MD_MAT_CATEGORY_HY, &
         MD_MAT_CATEGORY_VI, MD_MAT_CATEGORY_CR, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, &
         MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_WARN, Desc_MaterialModel, State_IntPoint, MD_MatPointSta, MD_MatState
    USE MD_MatReg_Ops, ONLY: MatReg, g_matlib
    USE MD_MatLibPH_Brg, ONLY: UF_Plastic_Eval_Dispatch, UF_Plastic_Eval_Dispatch_Arg, &
        UF_Plastic_UMAT_Dispatch
    USE MD_Mat_Plast_Reg, ONLY: MD_MAT_VONMISES_MAT_ID, MD_MAT_VONMISES_MAT_NA, &
         UF_Plastic_GetMaterialInfo, PlastModels_Desc, PlastMatInfo, &
         MD_MAT_HILL_MAT_ID, MD_MAT_DRUCKERPRAGER_M, MD_MAT_CAMCLAY_MAT_ID, &
         MD_MAT_MOHRCOULOMB_MAT, MD_MAT_GURSON_MAT_ID, MD_MAT_CHABOCHE_MAT_ID, &
         MD_MAT_JOHNSONCOOK_MAT
    USE MD_Mat_Elas_Dispatch, ONLY: UF_Elastic_Eval_Dispatch
    USE MD_Mat_Eval_Types, ONLY: MatEval_Ctx, MatAlgo_Algo, MAT_ALGO_DEFAULT, MD_MATCTX_MAX_STATEV
    IMPLICIT NONE
    PRIVATE

    ! --- from MD_MAT_BASE ---

  !=============================================================================
  ! PUBLIC TYPES & CONSTANTS
  !=============================================================================
  PUBLIC :: MatProperties
  PUBLIC :: UF_MaterialModel
  PUBLIC :: ContmMatRes

  ! Mat type constants (sunk from RT_Mat_Base for L4->L3 access; PH_Elem_Impl uses these)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_TYPE_ELAS    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_TYPE_PLASTI = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_TYPE_HYP    = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_TYPE_VISC   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_TYPE_CREEP  = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_TYPE_DAMAGE = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_TYPE_USER   = 10_i4
  ! Note: StructMatRes is defined in MD_UniFld.f90
  ! Legacy damage/creep material IDs (stubs for removed domain modules)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DUCTILE_DAMAGE  = 501_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_BRITTLE_DAMAGE         = 505_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PROG_DMG_MAT_ID        = 511_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FATIGUE_DAMAGE         = 512_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_NORTON_CREEP_MA = 601_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GAROFALO_CREEP  = 602_i4

  !=============================================================================
  ! CONTMMATRES: Structural Mat integration result (moved from RT_Contm_Struct_Mat to break L3->L5 cycle)
  !=============================================================================
  type, public :: ContmMatRes
    real(wp) :: stress6(6) = 0.0_wp
    real(wp) :: D6(6,6)    = 0.0_wp
    real(wp) :: energy_inc = 0.0_wp
    real(wp) :: plastic_diss = 0.0_wp
    type(MatFlags) :: flags
  end type ContmMatRes

  !=============================================================================
  ! Mat PROPERTIES TYPE
  ! Extends MatProps to add density field for element computation
  !=============================================================================
  type, public, extends(MatProps) :: MatProperties
    !! Mat properties container used by element computation routines
    !! Inherits material_id, props, nprops from MatProps
    real(wp) :: density = 0.0_wp                     ! Mat density
  contains
    procedure, public :: Init => MatProperties_Init
    procedure, public :: Clean => MatProperties_Clean
  end type MatProperties

    ! --- from MD_MAT_CONSTANTS ---
    
    ! ==========================================================================
    ! PUBLIC INTERFACE
    ! ==========================================================================
    PUBLIC :: MD_MAT_STEEL_DENSITY, MD_MAT_STEEL_YOUNG_MODULUS, &
              MD_MAT_STEEL_POISSON_RATIO, MD_MAT_STEEL_THERMAL_EXPANSION
    PUBLIC :: MD_MAT_ALUMINUM_DENSITY, MD_MAT_ALUMINUM_YOUNG_MODULUS, &
              MD_MAT_ALUMINUM_POISSON_RATIO, MD_MAT_ALUMINUM_THERMAL_EXPANSION
    PUBLIC :: MD_MAT_CONCRETE_DENSITY, MD_MAT_CONCRETE_YOUNG_MODULUS, &
              MD_MAT_CONCRETE_POISSON_RATIO, MD_MAT_CONCRETE_THERMAL_EXPANSION

    ! ==========================================================================
    ! STEEL MATERIAL CONSTANTS (typical values)
    ! ==========================================================================
    REAL(wp), PARAMETER :: MD_MAT_STEEL_DENSITY = 7850.0_wp              ! kg/m?
    REAL(wp), PARAMETER :: MD_MAT_STEEL_YOUNG_MODULUS = 200.0e9_wp       ! Pa
    REAL(wp), PARAMETER :: MD_MAT_STEEL_POISSON_RATIO = 0.3_wp           ! dimensionless
    REAL(wp), PARAMETER :: MD_MAT_STEEL_THERMAL_EXPANSION = 12.0e-6_wp  ! 1/K

    ! ==========================================================================
    ! ALUMINUM MATERIAL CONSTANTS (typical values)
    ! ==========================================================================
    REAL(wp), PARAMETER :: MD_MAT_ALUMINUM_DENSITY = 2700.0_wp           ! kg/m?
    REAL(wp), PARAMETER :: MD_MAT_ALUMINUM_YOUNG_MODULUS = 70.0e9_wp    ! Pa
    REAL(wp), PARAMETER :: MD_MAT_ALUMINUM_POISSON_RATIO = 0.33_wp      ! dimensionless
    REAL(wp), PARAMETER :: MD_MAT_ALUMINUM_THERMAL_EXPANSION = 23.0e-6_wp ! 1/K

    ! ==========================================================================
    ! CONCRETE MATERIAL CONSTANTS (typical values)
    ! ==========================================================================
    REAL(wp), PARAMETER :: MD_MAT_CONCRETE_DENSITY = 2400.0_wp           ! kg/m?
    REAL(wp), PARAMETER :: MD_MAT_CONCRETE_YOUNG_MODULUS = 30.0e9_wp    ! Pa
    REAL(wp), PARAMETER :: MD_MAT_CONCRETE_POISSON_RATIO = 0.2_wp        ! dimensionless
    REAL(wp), PARAMETER :: MD_MAT_CONCRETE_THERMAL_EXPANSION = 10.0e-6_wp ! 1/K


    ! --- from MD_Mat ---

    
    PUBLIC :: UF_MaterialDef, UF_MaterialDB
    PUBLIC :: UF_MaterialDef_EnsureCommittedForRollback
    PUBLIC :: MD_MAT_MAX_MATERIAL_NAME, MD_MAT_MAX_MATERIAL_PROPS
    PUBLIC :: HardeningTable_Init_Structured
    PUBLIC :: HardeningTable_AddPoint_Structured
    PUBLIC :: HardeningTable_Interpolate_Structured
    PUBLIC :: MaterialDef_Init_Structured
    PUBLIC :: MaterialDef_SetElasticIso_Structured
    PUBLIC :: MaterialDef_SetPlasticMises_Structured
    PUBLIC :: MaterialDef_SetDamping_Structured
    PUBLIC :: MaterialDef_SetExpansion_Structured
    PUBLIC :: MaterialDef_SetElasticOrtho_Structured
    PUBLIC :: MaterialDef_SetElasticTransIso_Structured
    PUBLIC :: MaterialDef_SetElasticAniso_Structured
    PUBLIC :: DampingDef_Set_Structured
    PUBLIC :: ExpansionDef_SetIso_Structured
    
    INTEGER(i4), PARAMETER :: MD_MAT_MAX_MATERIAL_NAME = 80
    INTEGER(i4), PARAMETER :: MD_MAT_MAX_MATERIAL_PROPS = 200
    INTEGER(i4), PARAMETER :: MD_MAT_MAX_HARDENING_POINTS = 1000
    INTEGER(i4), PARAMETER :: MD_MAT_MAX_MATERIALS = 1000
    
    ! ==========================================================================
    ! HARDENING DATA TABLE (for plastic materials) - Desc category
    ! ==========================================================================
    !> @brief Hardening table type (Desc category)
    !! @details Read-only configuration for plastic hardening data
    !!   Theory: Hardening table ?_y(?_p, ??, T), where ?_y ????is yield stress,
    !!     ?_p ????is plastic strain, ?? ????is strain rate, T ????is temperature
    TYPE, PUBLIC :: UF_HardeningTable
        INTEGER(i4) :: num_points = 0                              ! Number of points ????
        REAL(wp), ALLOCATABLE :: stress(:)                         ! Yield stress values ?_y ???^n_points
        REAL(wp), ALLOCATABLE :: plastic_strain(:)                  ! Plastic strain values ?_p ???^n_points
        REAL(wp), ALLOCATABLE :: strain_rate(:)                    ! Strain rate ?? ???^n_points (if rate-dependent)
        REAL(wp), ALLOCATABLE :: temperature(:)                     ! Temperature T ???^n_points (if temp-dependent)
    CONTAINS
        PROCEDURE :: init => hardening_init
        PROCEDURE :: add_point => hardening_add_point
    END TYPE UF_HardeningTable

    ! --- from MD_MAT_EVAL_CTX ---






    ! --- from MD_MAT_TREE ---
!> Status: stub (not implemented yet)
!> Theory: (TODO) | Last verified: 2026-02-14


  public :: MatTree

  ! ===================================================================
  ! Mat Tree Type (extends MD_Mat_Desc and TreeNodeBase)
  ! ===================================================================
  type, public, extends(MD_Mat_Desc) :: MatTree
    ! Tree node properties
    integer(i4) :: node_id = 0_i4
    integer(i4) :: parent_id = 0_i4
    logical :: is_active = .true.
    logical :: is_visible = .true.

    ! Index manager
    type(IndexMgr) :: index_mgr

    ! Performance optimization
    type(LazyIndexMgr) :: lazy_index
    type(BatchOpMgr) :: batch_mgr

    ! Path resolver
    type(PathResolver) :: path_resolver

    logical :: tree_initialize = .false.
  end type MatTree

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: MD_Mat_ConvertElasticModulus
    PUBLIC :: MD_Mat_ConvertPoissonRatio
    PUBLIC :: MD_Mat_ValidateProperties
    PUBLIC :: MD_Mat_CompareProperties
    PUBLIC :: MD_Mat_GetBulkModulus
    PUBLIC :: MD_Mat_GetShearModulus
    PUBLIC :: MD_Mat_GetLameParameters
    

  public :: DmgState, FatigueState, CreepState, PhaseTransformationState
  public :: MD_MAT_UMAT_Damage_CDM, MD_MAT_UMAT_Damage_Lemaitre, MD_MAT_UMAT_Damage_GTN
  public :: MD_MAT_UMAT_Fatigue_Miner, MD_MAT_UMAT_Fatigue_CoffinManson, MD_MAT_UMAT_Fatigue_ParisLaw
  public :: MD_MAT_UMAT_Creep_Norton, MD_MAT_UMAT_Creep_Garofalo, MD_MAT_UMAT_Creep_KachanovRabotnov
  public :: MD_MAT_UMAT_PhaseTransformation_Martensite, MD_MAT_UMAT_PhaseTransformation_Austenite
  public :: MD_MAT_UMAT_Multiscale_Homogenization, MD_MAT_UMAT_Multiscale_RVE
  public :: ComputeElasticStiffness, ComputeElasticStress
  ! Legacy UMAT 602/603 (merged from Leg_Special_Core)
  public :: MD_MAT_UMAT_602, MD_MAT_UMAT_603, UF_Legacy_Special_602, UF_Legacy_Special_603

  ! ===================================================================
  ! DAMAGE MODEL TYPES
  ! ===================================================================
  type, public :: DmgState
    real(wp) :: D = 0.0_wp
    real(wp) :: D_prev = 0.0_wp
    real(wp) :: Y = 0.0_wp
    real(wp) :: Y_prev = 0.0_wp
    real(wp) :: r = 0.0_wp
    real(wp) :: r_prev = 0.0_wp
    real(wp) :: p = 0.0_wp
    real(wp) :: p_prev = 0.0_wp
  end type DmgState

  type, public :: FatigueState
    real(wp) :: N_f = 0.0_wp
    real(wp) :: N_accumulated = 0.0_wp
    real(wp) :: D_fatigue = 0.0_wp
    real(wp) :: sigma_max = 0.0_wp
    real(wp) :: sigma_min = 0.0_wp
    real(wp) :: R_ratio = 0.0_wp
    real(wp) :: delta_sigma = 0.0_wp
  end type FatigueState

  type, public :: CreepState
    real(wp) :: epsilon_c = 0.0_wp
    real(wp) :: epsilon_c_prev = 0.0_wp
    real(wp) :: epsilon_c_dot = 0.0_wp
    real(wp) :: omega = 0.0_wp
    real(wp) :: omega_prev = 0.0_wp
    real(wp) :: t = 0.0_wp
    real(wp) :: t_prev = 0.0_wp
  end type CreepState

  type, public :: PhaseTransformationState
    real(wp) :: f_martensite = 0.0_wp
    real(wp) :: f_austenite = 1.0_wp
    real(wp) :: f_prev = 0.0_wp
    real(wp) :: T = 0.0_wp
    real(wp) :: T_prev = 0.0_wp
    real(wp) :: sigma_transform = 0.0_wp
  end type PhaseTransformationState

  ! ===================================================================
  ! HELPER PROCEDURES (used by advanced models)
  ! ===================================================================
  subroutine ComputeElasticStiffness(E, nu, C)
    real(wp), intent(in) :: E, nu
    real(wp), intent(out) :: C(6,6)
    real(wp) :: lambda, mu
    lambda = E * nu / max((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu), 1.0e-12_wp)
    mu = E / max(2.0_wp * (1.0_wp + nu), 1.0e-12_wp)
    C = 0.0_wp
    C(1,1) = lambda + 2.0_wp * mu
    C(2,2) = lambda + 2.0_wp * mu
    C(3,3) = lambda + 2.0_wp * mu
    C(1,2) = lambda
    C(1,3) = lambda
    C(2,3) = lambda
    C(2,1) = lambda
    C(3,1) = lambda
    C(3,2) = lambda
    C(4,4) = mu
    C(5,5) = mu
    C(6,6) = mu
  end subroutine ComputeElasticStiffness

  subroutine ComputeElasticStress(E, nu, epsilon, stress)
    real(wp), intent(in) :: E, nu
    real(wp), intent(in) :: epsilon(6)
    real(wp), intent(out) :: stress(6)
    real(wp) :: C(6,6)
    call ComputeElasticStiffness(E, nu, C)
    stress = matmul(C, epsilon)
  end subroutine ComputeElasticStress

  ! ===================================================================
  ! ADVANCED DAMAGE MODELS
  ! ===================================================================
  subroutine MD_MAT_UMAT_Damage_CDM(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: n
    real(wp) :: E, nu, S, s, D_c
    real(wp) :: sigma_eq, Y, D, D_prev, p, p_prev, dp
    real(wp) :: stress(6), epsilon(6), epsilon_prev(6)
    real(wp) :: sigma_eff(6), D_dot
    real(wp) :: C(6,6), C_eff(6,6)
    call init_error_status(status)
    n = umat_in%ndir + umat_in%nshr
    if (size(umat_in%props) >= 5) then
      E = umat_in%props(1)
      nu = umat_in%props(2)
      S = umat_in%props(3)
      s = umat_in%props(4)
      D_c = umat_in%props(5)
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for CDM model"
      return
    end if
    if (size(umat_in%statev) >= 2) then
      D_prev = umat_in%statev(1)
      p_prev = umat_in%statev(2)
    else
      D_prev = 0.0_wp
      p_prev = 0.0_wp
    end if
    epsilon = 0.0_wp
    epsilon_prev = 0.0_wp
    if (allocated(umat_in%dstran)) epsilon(1:min(6, size(umat_in%dstran))) = umat_in%dstran(1:min(6, size(umat_in%dstran)))
    if (allocated(umat_in%stran)) epsilon_prev(1:min(6, size(umat_in%stran))) = umat_in%stran(1:min(6, size(umat_in%stran)))
    dp = sqrt(2.0_wp/3.0_wp * dot_product(epsilon - epsilon_prev, epsilon - epsilon_prev))
    p = p_prev + dp
    call ComputeElasticStiffness(E, nu, C)
    stress = matmul(C, epsilon)
    sigma_eq = sqrt(1.5_wp * dot_product(stress(1:3), stress(1:3)))
    Y = sigma_eq**2 / max(2.0_wp * E * (1.0_wp - D_prev)**2, 1.0e-12_wp)
    if (p > p_prev .and. D_prev < D_c) then
      D_dot = (Y / max(S, 1.0e-12_wp))**s * dp
      D = D_prev + D_dot * umat_in%dtime
      D = min(D, D_c)
    else
      D = D_prev
    end if
    sigma_eff = stress / max(1.0_wp - D, 1.0e-6_wp)
    C_eff = C / max(1.0_wp - D, 1.0e-6_wp)
    if (allocated(umat_out%stress)) umat_out%stress(1:min(6, size(umat_out%stress))) = sigma_eff(1:min(6, size(umat_out%stress)))
    if (allocated(umat_out%ddsdde)) umat_out%ddsdde(1:min(6, size(umat_out%ddsdde,1)), 1:min(6, size(umat_out%ddsdde,2))) = C_eff(1:min(6, size(umat_out%ddsdde,1)), 1:min(6, size(umat_out%ddsdde,2)))
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 2) then
      umat_out%statev(1) = D
      umat_out%statev(2) = p
    end if
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Damage_CDM

  subroutine MD_MAT_UMAT_Damage_Lemaitre(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    call MD_MAT_UMAT_Damage_CDM(umat_ifc, umat_in, umat_out, status)
  end subroutine MD_MAT_UMAT_Damage_Lemaitre

  subroutine MD_MAT_UMAT_Damage_GTN(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: E, nu, q1, q2, q3, f0, fc, ff, fn
    real(wp) :: sigma_eq, sigma_m, f, f_prev
    real(wp) :: stress(6), epsilon(6)
    call init_error_status(status)
    if (size(umat_in%props) >= 9) then
      E = umat_in%props(1)
      nu = umat_in%props(2)
      q1 = umat_in%props(3)
      q2 = umat_in%props(4)
      q3 = umat_in%props(5)
      f0 = umat_in%props(6)
      fc = umat_in%props(7)
      ff = umat_in%props(8)
      fn = umat_in%props(9)
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for GTN model"
      return
    end if
    if (size(umat_in%statev) >= 1) then
      f_prev = umat_in%statev(1)
    else
      f_prev = f0
    end if
    epsilon = 0.0_wp
    if (allocated(umat_in%dstran)) epsilon(1:min(6, size(umat_in%dstran))) = umat_in%dstran(1:min(6, size(umat_in%dstran)))
    call ComputeElasticStress(E, nu, epsilon, stress)
    sigma_eq = sqrt(1.5_wp * dot_product(stress(1:3), stress(1:3)))
    sigma_m = sum(stress(1:3)) / 3.0_wp
    f = f_prev
    if (allocated(umat_out%stress)) umat_out%stress(1:min(6, size(umat_out%stress))) = stress(1:min(6, size(umat_out%stress)))
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 1) umat_out%statev(1) = f
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Damage_GTN

  ! ===================================================================
  ! FATIGUE MODELS
  ! ===================================================================
  subroutine MD_MAT_UMAT_Fatigue_Miner(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: sigma_f_prime, b, epsilon_f_prime, c
    real(wp) :: sigma_a, N_f, D_fatigue, D_prev
    real(wp) :: sigma_max, sigma_min, delta_sigma
    real(wp) :: n_cycles
    call init_error_status(status)
    if (size(umat_in%props) >= 4) then
      sigma_f_prime = umat_in%props(1)
      b = umat_in%props(2)
      epsilon_f_prime = umat_in%props(3)
      c = umat_in%props(4)
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for Miner fatigue model"
      return
    end if
    if (size(umat_in%statev) >= 3) then
      D_prev = umat_in%statev(1)
      sigma_max = umat_in%statev(2)
      sigma_min = umat_in%statev(3)
    else
      D_prev = 0.0_wp
      sigma_max = 0.0_wp
      sigma_min = 0.0_wp
    end if
    delta_sigma = abs(sigma_max - sigma_min)
    sigma_a = delta_sigma / 2.0_wp
    if (sigma_a > 0.0_wp) then
      N_f = (sigma_f_prime / sigma_a)**(1.0_wp / b)
    else
      N_f = huge(1.0_wp)
    end if
    n_cycles = 1.0_wp
    D_fatigue = D_prev + n_cycles / N_f
    if (allocated(umat_out%stress) .and. allocated(umat_in%stress)) &
      umat_out%stress(1:min(size(umat_out%stress), size(umat_in%stress))) = umat_in%stress(1:min(size(umat_out%stress), size(umat_in%stress)))
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 3) then
      umat_out%statev(1) = D_fatigue
      umat_out%statev(2) = sigma_max
      umat_out%statev(3) = sigma_min
    end if
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Fatigue_Miner

  subroutine MD_MAT_UMAT_Fatigue_CoffinManson(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: epsilon_f_prime, c
    real(wp) :: delta_epsilon_p, N_f, D_fatigue, D_prev
    call init_error_status(status)
    if (size(umat_in%props) >= 2) then
      epsilon_f_prime = umat_in%props(1)
      c = umat_in%props(2)
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for Coffin-Manson model"
      return
    end if
    if (size(umat_in%statev) >= 2) then
      D_prev = umat_in%statev(1)
      delta_epsilon_p = umat_in%statev(2)
    else
      D_prev = 0.0_wp
      delta_epsilon_p = 0.0_wp
    end if
    if (delta_epsilon_p > 0.0_wp .and. epsilon_f_prime > 0.0_wp) then
      N_f = 0.5_wp * (delta_epsilon_p / (2.0_wp * epsilon_f_prime))**(1.0_wp / c)
    else
      N_f = huge(1.0_wp)
    end if
    D_fatigue = D_prev + 1.0_wp / N_f
    if (allocated(umat_out%stress) .and. allocated(umat_in%stress)) &
      umat_out%stress(1:min(size(umat_out%stress), size(umat_in%stress))) = umat_in%stress(1:min(size(umat_out%stress), size(umat_in%stress)))
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 1) umat_out%statev(1) = D_fatigue
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Fatigue_CoffinManson

  subroutine MD_MAT_UMAT_Fatigue_ParisLaw(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: C, m, K_IC
    real(wp) :: delta_K, a, a_prev, da_dN
    real(wp) :: sigma_max, sigma_min, Y_factor
    call init_error_status(status)
    if (size(umat_in%props) >= 3) then
      C = umat_in%props(1)
      m = umat_in%props(2)
      K_IC = umat_in%props(3)
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for Paris law model"
      return
    end if
    if (size(umat_in%statev) >= 3) then
      a_prev = umat_in%statev(1)
      sigma_max = umat_in%statev(2)
      sigma_min = umat_in%statev(3)
    else
      a_prev = 0.0_wp
      sigma_max = 0.0_wp
      sigma_min = 0.0_wp
    end if
    Y_factor = 1.12_wp
    delta_K = Y_factor * sqrt(3.14159_wp * a_prev) * abs(sigma_max - sigma_min)
    da_dN = C * delta_K**m
    a = a_prev + da_dN
    if (a > 0.0_wp .and. delta_K > K_IC) then
      status%status_code = MD_MAT_STATUS_WARN
      status%message = "Fatigue failure: K > K_IC"
    end if
    if (allocated(umat_out%stress) .and. allocated(umat_in%stress)) &
      umat_out%stress(1:min(size(umat_out%stress), size(umat_in%stress))) = umat_in%stress(1:min(size(umat_out%stress), size(umat_in%stress)))
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 1) umat_out%statev(1) = a
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Fatigue_ParisLaw

  ! ===================================================================
  ! CREEP MODELS
  ! ===================================================================
  subroutine MD_MAT_UMAT_Creep_Norton(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: A, n, Q, R_gas
    real(wp) :: sigma_eq, T, epsilon_c, epsilon_c_prev, epsilon_c_dot
    real(wp) :: dt
    call init_error_status(status)
    if (size(umat_in%props) >= 4) then
      A = umat_in%props(1)
      n = umat_in%props(2)
      Q = umat_in%props(3)
      R_gas = umat_in%props(4)
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for Norton creep model"
      return
    end if
    if (size(umat_in%statev) >= 1) then
      epsilon_c_prev = umat_in%statev(1)
    else
      epsilon_c_prev = 0.0_wp
    end if
    T = umat_in%temp
    if (allocated(umat_in%stress)) then
      sigma_eq = sqrt(1.5_wp * dot_product(umat_in%stress(1:min(3, size(umat_in%stress))), umat_in%stress(1:min(3, size(umat_in%stress)))))
    else
      sigma_eq = 0.0_wp
    end if
    if (T > 0.0_wp) then
      epsilon_c_dot = A * sigma_eq**n * exp(-Q / (R_gas * T))
    else
      epsilon_c_dot = 0.0_wp
    end if
    dt = umat_in%dtime
    epsilon_c = epsilon_c_prev + epsilon_c_dot * dt
    if (allocated(umat_out%stress) .and. allocated(umat_in%stress)) &
      umat_out%stress(1:min(size(umat_out%stress), size(umat_in%stress))) = umat_in%stress(1:min(size(umat_out%stress), size(umat_in%stress)))
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 1) umat_out%statev(1) = epsilon_c
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Creep_Norton

  subroutine MD_MAT_UMAT_Creep_Garofalo(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: A, alpha, n, Q, R_gas
    real(wp) :: sigma_eq, T, epsilon_c, epsilon_c_prev, epsilon_c_dot
    real(wp) :: dt
    call init_error_status(status)
    if (size(umat_in%props) >= 5) then
      A = umat_in%props(1)
      alpha = umat_in%props(2)
      n = umat_in%props(3)
      Q = umat_in%props(4)
      R_gas = umat_in%props(5)
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for Garofalo creep model"
      return
    end if
    if (size(umat_in%statev) >= 1) then
      epsilon_c_prev = umat_in%statev(1)
    else
      epsilon_c_prev = 0.0_wp
    end if
    T = umat_in%temp
    if (allocated(umat_in%stress)) then
      sigma_eq = sqrt(1.5_wp * dot_product(umat_in%stress(1:min(3, size(umat_in%stress))), umat_in%stress(1:min(3, size(umat_in%stress)))))
    else
      sigma_eq = 0.0_wp
    end if
    if (T > 0.0_wp) then
      epsilon_c_dot = A * (sinh(alpha * sigma_eq))**n * exp(-Q / (R_gas * T))
    else
      epsilon_c_dot = 0.0_wp
    end if
    dt = umat_in%dtime
    epsilon_c = epsilon_c_prev + epsilon_c_dot * dt
    if (allocated(umat_out%stress) .and. allocated(umat_in%stress)) &
      umat_out%stress(1:min(size(umat_out%stress), size(umat_in%stress))) = umat_in%stress(1:min(size(umat_out%stress), size(umat_in%stress)))
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 1) umat_out%statev(1) = epsilon_c
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Creep_Garofalo

  subroutine MD_MAT_UMAT_Creep_KachanovRabotnov(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: A, n, B, m, chi
    real(wp) :: sigma_eq, omega, omega_prev, epsilon_c, epsilon_c_prev
    real(wp) :: omega_dot, epsilon_c_dot, dt
    call init_error_status(status)
    if (size(umat_in%props) >= 5) then
      A = umat_in%props(1)
      n = umat_in%props(2)
      B = umat_in%props(3)
      m = umat_in%props(4)
      chi = umat_in%props(5)
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat parameters for Kachanov-Rabotnov model"
      return
    end if
    if (size(umat_in%statev) >= 2) then
      omega_prev = umat_in%statev(1)
      epsilon_c_prev = umat_in%statev(2)
    else
      omega_prev = 0.0_wp
      epsilon_c_prev = 0.0_wp
    end if
    if (allocated(umat_in%stress)) then
      sigma_eq = sqrt(1.5_wp * dot_product(umat_in%stress(1:min(3, size(umat_in%stress))), umat_in%stress(1:min(3, size(umat_in%stress)))))
    else
      sigma_eq = 0.0_wp
    end if
    epsilon_c_dot = A * (sigma_eq / max(1.0_wp - omega_prev, 1.0e-6_wp))**n
    omega_dot = B * (sigma_eq / max(1.0_wp - omega_prev, 1.0e-6_wp))**m / max(1.0_wp - omega_prev, 1.0e-6_wp)**chi
    dt = umat_in%dtime
    omega = omega_prev + omega_dot * dt
    omega = min(omega, 0.999_wp)
    epsilon_c = epsilon_c_prev + epsilon_c_dot * dt
    if (omega >= 0.999_wp) then
      status%status_code = MD_MAT_STATUS_WARN
      status%message = "Creep failure: omega >= 0.999"
    end if
    if (allocated(umat_out%stress) .and. allocated(umat_in%stress)) &
      umat_out%stress = umat_in%stress / max(1.0_wp - omega, 1.0e-6_wp)
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 2) then
      umat_out%statev(1) = omega
      umat_out%statev(2) = epsilon_c
    end if
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Creep_KachanovRabotnov

  ! ===================================================================
  ! PHASE TRANSFORMATION MODELS
  ! ===================================================================
  subroutine UM_Ph_Martensite(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: M_s, M_f, A_s, A_f
    real(wp) :: C_M, C_A, sigma_crit
    real(wp) :: T, f_martensite, f_martensite_pr
    real(wp) :: sigma_eq
    call init_error_status(status)
    M_s = umat_in%props(1)
    M_f = umat_in%props(2)
    A_s = umat_in%props(3)
    A_f = umat_in%props(4)
    C_M = umat_in%props(5)
    C_A = umat_in%props(6)
    sigma_crit = umat_in%props(7)
    f_martensite_pr = umat_in%statev(1)
    T = umat_in%temp
    if (allocated(umat_in%stress)) then
      sigma_eq = sqrt(1.5_wp * dot_product(umat_in%stress(1:min(3, size(umat_in%stress))), umat_in%stress(1:min(3, size(umat_in%stress)))))
    else
      sigma_eq = 0.0_wp
    end if
    if (T < M_s) then
      f_martensite = 1.0_wp - exp(-C_M * (M_s - T))
    else if (T > A_s .and. T < A_f) then
      f_martensite = exp(-C_A * (T - A_s))
    else
      f_martensite = f_martensite_pr
    end if
    if (sigma_eq > sigma_crit) then
      f_martensite = min(f_martensite + 0.1_wp * (sigma_eq - sigma_crit) / max(sigma_crit, 1.0e-6_wp), 1.0_wp)
    end if
    if (allocated(umat_out%stress) .and. allocated(umat_in%stress)) &
      umat_out%stress(1:min(size(umat_out%stress), size(umat_in%stress))) = umat_in%stress(1:min(size(umat_out%stress), size(umat_in%stress)))
    if (allocated(umat_out%statev) .and. size(umat_out%statev) >= 1) umat_out%statev(1) = f_martensite
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_PhaseTransformation_Martensite

  subroutine UM_Ph_Austenite(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    call MD_MAT_UMAT_PhaseTransformation_Martensite(umat_ifc, umat_in, umat_out, status)
  end subroutine MD_MAT_UMAT_PhaseTransformation_Austenite

  ! ===================================================================
  ! MULTISCALE Mat MODELS
  ! ===================================================================
  subroutine UM_Mu_Homogenization(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: MD_MAT_E_macro, nu_macro
    real(wp) :: MD_MAT_E_micro, nu_micro, f_fiber
    real(wp) :: sigma_macro(6), epsilon_macro(6)
    real(wp) :: C_homogenized(6,6)
    call init_error_status(status)
    MD_MAT_E_micro = umat_in%props(1)
    nu_micro = umat_in%props(2)
    f_fiber = umat_in%props(3)
    epsilon_macro = 0.0_wp
    if (allocated(umat_in%dstran)) epsilon_macro(1:min(6, size(umat_in%dstran))) = umat_in%dstran(1:min(6, size(umat_in%dstran)))
    MD_MAT_E_macro = f_fiber * MD_MAT_E_micro + (1.0_wp - f_fiber) * MD_MAT_E_micro * 0.1_wp
    nu_macro = nu_micro
    call ComputeElasticStiffness(MD_MAT_E_macro, nu_macro, C_homogenized)
    sigma_macro = matmul(C_homogenized, epsilon_macro)
    if (allocated(umat_out%stress)) umat_out%stress(1:min(6, size(umat_out%stress))) = sigma_macro(1:min(6, size(umat_out%stress)))
    if (allocated(umat_out%ddsdde)) umat_out%ddsdde(1:min(6, size(umat_out%ddsdde,1)), 1:min(6, size(umat_out%ddsdde,2))) = C_homogenized(1:min(6, size(umat_out%ddsdde,1)), 1:min(6, size(umat_out%ddsdde,2)))
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Multiscale_Homogenization

  subroutine MD_MAT_UMAT_Multiscale_RVE(umat_ifc, umat_in, umat_out, status)
    type(MD_MAT_UMAT_Intf), intent(in) :: umat_ifc
    type(MD_MAT_UMAT_Input), intent(in) :: umat_in
    type(MD_MAT_UMAT_Output), intent(inout) :: umat_out
    type(ErrorStatusType), intent(out) :: status
    call MD_MAT_UMAT_Multiscale_Homogenization(umat_ifc, umat_in, umat_out, status)
  end subroutine MD_MAT_UMAT_Multiscale_RVE

  !----------------------------------------------------------------------
  ! Legacy UMAT 602/603 (merged from MD_MatLib_Leg_Special_Core)
  !----------------------------------------------------------------------
  SUBROUTINE MD_MAT_UMAT_602(stress, statev, ddsdde, sse, spd, scd, rpl, &
                      ddsddt, drplde, drpldt, stran, dstran, time, dtime, &
                      temp, dtemp, predef, dpred, cmname, ndi, nshr, ntens, &
                      nstatv, props, nprops, coords, drot, pnewdt, celent, &
                      dfgrd0, dfgrd1, noel, npt, layer, kspt, kstep, kinc)
    CHARACTER(LEN=80), INTENT(IN) :: cmname
    REAL(wp), INTENT(INOUT) :: stress(ntens), statev(nstatv)
    REAL(wp), INTENT(OUT) :: ddsdde(ntens,ntens), sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(ntens), drplde(ntens), drpldt
    REAL(wp), INTENT(IN) :: stran(ntens), dstran(ntens), time(2), dtime, temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*), props(nprops), coords(3), drot(3,3)
    REAL(wp), INTENT(IN) :: dfgrd0(3,3), dfgrd1(3,3), celent
    REAL(wp), INTENT(OUT) :: pnewdt
    INTEGER(i4), INTENT(IN) :: ndi, nshr, ntens, nstatv, nprops, noel, npt, layer, kspt, kstep, kinc

    REAL(wp) :: MD_MAT_E_bulk, nu_bulk, lambda_bulk, mu_bulk
    REAL(wp) :: surface_stress, characteristic, size_effect_exp
    REAL(wp) :: surface_thickne, surface_modulus, thermal_expansion_coefficien
    REAL(wp) :: lambda_effectiv, mu_effective
    REAL(wp) :: D_bulk(6,6), D_effective(6,6)
    REAL(wp) :: strain_total(6), strain_elastic(6), strain_thermal(6)
    REAL(wp) :: stress_bulk(6), stress_surface(6), stress_effectiv(6)
    REAL(wp) :: size_effect_mul, surface_to_volu
    INTEGER(i4) :: analysis_type, i, j
    REAL(wp) :: element_size
    REAL(wp), PARAMETER :: ZERO = 0.0_wp, ONE = 1.0_wp, TWO = 2.0_wp, THREE = 3.0_wp

    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    pnewdt = ONE
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO
    stress = ZERO
    thermal_expansion_coefficien = ZERO

    IF (nprops < 7) THEN
      CALL log_error('MD_MatLib_Adv_Core::MD_MAT_UMAT_602', 'Insufficient props: need MD_MAT_E_bulk, nu_bulk, surface_stress, characteristic, size_effect_exp, surface_thickne, surface_modulus')
      RETURN
    END IF

    MD_MAT_E_bulk = props(1)
    nu_bulk = props(2)
    surface_stress = props(3)
    characteristic = props(4)
    size_effect_exp = props(5)
    surface_thickne = props(6)
    surface_modulus = props(7)
    IF (nprops >= 8) thermal_expansion_coefficien = props(8)

    analysis_type = DetectAnalysisType_602(ndi, nshr)
    element_size = EstimateElementSize_602(celent, ndi)
    IF (element_size > ZERO) THEN
      surface_to_volu = ONE / element_size
    ELSE
      surface_to_volu = ZERO
    END IF
    size_effect_mul = ComputeSizeEffectMultiplier_602(element_size, characteristic, size_effect_exp)

    lambda_bulk = MD_MAT_E_bulk * nu_bulk / ((ONE + nu_bulk) * (ONE - TWO * nu_bulk))
    mu_bulk = MD_MAT_E_bulk / (TWO * (ONE + nu_bulk))
    lambda_effectiv = lambda_bulk * size_effect_mul
    mu_effective = mu_bulk * size_effect_mul

    CALL BuildElasticStiffness_602(lambda_bulk, mu_bulk, ndi, nshr, ntens, analysis_type, D_bulk)
    CALL BuildElasticStiffness_602(lambda_effectiv, mu_effective, ndi, nshr, ntens, analysis_type, D_effective)

    strain_total = ZERO
    DO i = 1, ntens
      strain_total(i) = stran(i) + dstran(i)
    END DO
    strain_thermal = ZERO
    IF (thermal_expansion_coefficien /= ZERO) THEN
      CALL ComputeThermalStrain_602(thermal_expansion_coefficien, temp - 293.15_wp, ndi, nshr, ntens, strain_thermal)
    END IF
    strain_elastic = strain_total - strain_thermal

    stress_bulk = ZERO
    DO i = 1, ntens
      DO j = 1, ntens
        stress_bulk(i) = stress_bulk(i) + D_bulk(i,j) * strain_elastic(j)
      END DO
    END DO
    CALL ComputeSurfaceStress_602(surface_stress, surface_to_volu, surface_thickne, ndi, nshr, ntens, stress_surface)
    stress_effectiv = stress_bulk + stress_surface
    stress = stress_effectiv
    ddsdde = D_effective

    sse = 0.5_wp * SUM(stress_effectiv(1:ntens) * strain_elastic(1:ntens))
    IF (nstatv >= 1) statev(1) = REAL(analysis_type, wp)
    IF (nstatv >= 2) statev(2) = size_effect_mul
    IF (nstatv >= 3) statev(3) = surface_to_volu

  END SUBROUTINE MD_MAT_UMAT_602

  INTEGER FUNCTION DetectAnalysisType_602(ndi, nshr)
    INTEGER(i4), INTENT(IN) :: ndi, nshr
    IF (ndi == 1) THEN
      DetectAnalysisType_602 = 0
    ELSE IF (ndi == 2) THEN
      IF (nshr == 1) THEN
        DetectAnalysisType_602 = 2
      ELSE
        DetectAnalysisType_602 = 1
      END IF
    ELSE
      DetectAnalysisType_602 = 0
    END IF
  END FUNCTION DetectAnalysisType_602

  REAL(wp) FUNCTION EstimateElementSize_602(celent, ndi)
    REAL(wp), INTENT(IN) :: celent
    INTEGER(i4), INTENT(IN) :: ndi
    IF (celent > 0.0_wp) THEN
      EstimateElementSize_602 = celent
    ELSE
      EstimateElementSize_602 = 1.0e-9_wp
    END IF
  END FUNCTION EstimateElementSize_602

  REAL(wp) FUNCTION Co_602(element_size, characteristic, exponent)
    REAL(wp), INTENT(IN) :: element_size, characteristic, exponent
    IF (characteristic > 0.0_wp .AND. element_size > 0.0_wp) THEN
      ComputeSizeEffectMultiplier_602 = 1.0_wp + exponent * (characteristic / element_size)
    ELSE
      ComputeSizeEffectMultiplier_602 = 1.0_wp
    END IF
    ComputeSizeEffectMultiplier_602 = MAX(MIN(ComputeSizeEffectMultiplier_602, 10.0_wp), 0.1_wp)
  END FUNCTION ComputeSizeEffectMultiplier_602

  SUBROUTINE BuildElasticStiffness_602(lambda, mu, ndi, nshr, ntens, analysis_type, D)
    REAL(wp), INTENT(IN) :: lambda, mu
    INTEGER(i4), INTENT(IN) :: ndi, nshr, ntens, analysis_type
    REAL(wp), INTENT(OUT) :: D(6,6)
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp, ONE = 1.0_wp, TWO = 2.0_wp
    D = ZERO
    IF (analysis_type == 1) THEN
      D(1,1) = lambda + TWO * mu
      D(1,2) = lambda
      D(2,1) = lambda
      D(2,2) = lambda + TWO * mu
      IF (ntens >= 3) D(3,3) = mu
    ELSE
      D(1,1) = lambda + TWO * mu
      D(1,2) = lambda
      D(1,3) = lambda
      D(2,1) = lambda
      D(2,2) = lambda + TWO * mu
      D(2,3) = lambda
      D(3,1) = lambda
      D(3,2) = lambda
      D(3,3) = lambda + TWO * mu
      IF (ntens >= 4) D(4,4) = mu
      IF (ntens >= 5) D(5,5) = mu
      IF (ntens >= 6) D(6,6) = mu
    END IF
    DO i = 1, 6
      IF (D(i,i) < 1.0e-10_wp) D(i,i) = 1.0e-10_wp
    END DO
  END SUBROUTINE BuildElasticStiffness_602

  SUBROUTINE ComputeThermalStrain_602(alpha, dT, ndi, nshr, ntens, strain_thermal)
    REAL(wp), INTENT(IN) :: alpha, dT
    INTEGER(i4), INTENT(IN) :: ndi, nshr, ntens
    REAL(wp), INTENT(OUT) :: strain_thermal(6)
    INTEGER(i4) :: i
    strain_thermal = 0.0_wp
    DO i = 1, ndi
      strain_thermal(i) = alpha * dT
    END DO
  END SUBROUTINE ComputeThermalStrain_602

  SUBROUTINE ComputeSurfaceStress_602(surface_stress, surface_to_volu, surface_thickne, ndi, nshr, ntens, stress_surface)
    REAL(wp), INTENT(IN) :: surface_stress, surface_to_volu, surface_thickne
    INTEGER(i4), INTENT(IN) :: ndi, nshr, ntens
    REAL(wp), INTENT(OUT) :: stress_surface(6)
    INTEGER(i4) :: i
    REAL(wp) :: surface_stress
    surface_stress = surface_stress * surface_to_volu * surface_thickne
    stress_surface = 0.0_wp
    DO i = 1, ndi
      stress_surface(i) = surface_stress
    END DO
  END SUBROUTINE ComputeSurfaceStress_602

  SUBROUTINE UF_Legacy_Special_602(stress, statev, ddsdde, sse, spd, scd, rpl, &
                                   ddsddt, drplde, drpldt, stran, dstran, time, dtime, &
                                   temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, &
                                   props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    INTEGER(i4) :: ntens
    CHARACTER(LEN=80) :: cmname
    REAL(wp) :: coords(3), drot(3,3), dfgrd0(3,3), dfgrd1(3,3)
    ntens = ndir + nshr
    cmname = ''
    coords = 0.0_wp
    drot = 0.0_wp
    drot(1,1) = 1.0_wp
    drot(2,2) = 1.0_wp
    drot(3,3) = 1.0_wp
    dfgrd0 = drot
    dfgrd1 = drot
    CALL MD_MAT_UMAT_602(stress, statev, ddsdde, sse, spd, scd, rpl, &
                  ddsddt, drplde, drpldt, stran, dstran, time, dtime, &
                  temp, dtemp, predef, dpred, cmname, ndir, nshr, ntens, &
                  nstatev, props, nprops, coords, drot, 1.0_wp, 0.0_wp, &
                  dfgrd0, dfgrd1, 0, 0, 0, 0, kstep, kinc)
  END SUBROUTINE UF_Legacy_Special_602

  SUBROUTINE MD_MAT_UMAT_603(stress, statev, ddsdde, sse, spd, scd, rpl, &
                      ddsddt, drplde, drpldt, stran, dstran, time, dtime, &
                      temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType) :: status
    CALL MD_MAT_UMAT_603_Internal(stress, statev, ddsdde, sse, spd, scd, rpl, &
                           ddsddt, drplde, drpldt, stran, dstran, time, dtime, &
                           temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, &
                           props, ndim, kstep, kinc, status)
  END SUBROUTINE MD_MAT_UMAT_603

  SUBROUTINE MD_MAT_UMAT_603_Internal(stress, statev, ddsdde, sse, spd, scd, rpl, &
                               ddsddt, drplde, drpldt, stran, dstran, time, dtime, &
                               temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, &
                               props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: MD_MAT_E_min, MD_MAT_E_max, nu_min, nu_max
    REAL(wp) :: sigma_y_min, sigma_y_max, H_min, H_max
    REAL(wp) :: alpha_thermal_m, alpha_thermal_m
    REAL(wp) :: gradient_direct(3), gradient_length, gradient_expone, gradient_type
    REAL(wp) :: gradient_parame, MD_MAT_E_effective, nu_effective
    REAL(wp) :: sigma_y_effecti, H_effective, alpha_thermal_e
    REAL(wp) :: strain_total(6), strain_elastic(6), strain_plastic(6), strain_thermal(6)
    REAL(wp) :: D_elastic(6,6), position(3)
    INTEGER(i4) :: ntens, i
    REAL(wp), PARAMETER :: ZERO = 0.0_wp, ONE = 1.0_wp

    CALL init_error_status(status)
    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    IF (nprops < 15) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient Mat properties for Gradient Mat model 603"
      RETURN
    END IF
    IF (nstatev < 11) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Insufficient state variables for Gradient Mat model 603"
      RETURN
    END IF

    MD_MAT_E_min = props(1)
    MD_MAT_E_max = props(2)
    nu_min = props(3)
    nu_max = props(4)
    sigma_y_min = props(5)
    sigma_y_max = props(6)
    H_min = props(7)
    H_max = props(8)
    alpha_thermal_m = props(9)
    alpha_thermal_m = props(10)
    gradient_direct(1) = props(11)
    gradient_direct(2) = props(12)
    gradient_direct(3) = props(13)
    gradient_length = props(14)
    gradient_type = props(15)
    gradient_expone = ONE
    IF (nprops >= 16) gradient_expone = props(16)

    ntens = ndir + nshr
    position(1) = statev(3)
    position(2) = statev(4)
    position(3) = statev(5)
    IF (ndim >= 1 .AND. SIZE(predef) >= 1) position(1) = predef(1)
    IF (ndim >= 2 .AND. SIZE(predef) >= 2) position(2) = predef(2)
    IF (ndim >= 3 .AND. SIZE(predef) >= 3) position(3) = predef(3)
    CALL ComputeGradientParameter603(position, gradient_direct, gradient_length, gradient_type, gradient_expone, gradient_parame)
    MD_MAT_E_effective = MD_MAT_E_min + (MD_MAT_E_max - MD_MAT_E_min) * gradient_parame
    nu_effective = nu_min + (nu_max - nu_min) * gradient_parame
    sigma_y_effecti = sigma_y_min + (sigma_y_max - sigma_y_min) * gradient_parame
    H_effective = H_min + (H_max - H_min) * gradient_parame
    alpha_thermal_e = alpha_thermal_m + (alpha_thermal_m - alpha_thermal_m) * gradient_parame

    strain_total = stran + dstran
    strain_thermal = ZERO
    DO i = 1, ndir
      strain_thermal(i) = alpha_thermal_e * (temp - statev(11))
    END DO
    strain_plastic = ZERO
    IF (nstatev >= 11) THEN
      DO i = 1, MIN(6, nstatev - 5)
        strain_plastic(i) = statev(4 + i)
      END DO
    END IF
    strain_elastic = strain_total - strain_plastic - strain_thermal

    CALL BuildElasticStiffness603(MD_MAT_E_effective, nu_effective, ndim, 0, D_elastic)
    stress = MATMUL(D_elastic(1:ntens,1:ntens), strain_elastic(1:ntens))
    ddsdde = D_elastic
    sse = 0.5_wp * DOT_PRODUCT(stress(1:ntens), strain_elastic(1:ntens))
    statev(11) = temp
  END SUBROUTINE MD_MAT_UMAT_603_Internal

  SUBROUTINE ComputeGradientParameter603(position, gradient_direct, gradient_length, gradient_type, gradient_expone, gradient_parame)
    REAL(wp), INTENT(IN) :: position(3), gradient_direct(3)
    REAL(wp), INTENT(IN) :: gradient_length, gradient_type, gradient_expone
    REAL(wp), INTENT(OUT) :: gradient_parame
    REAL(wp) :: normalized_posi, gradient_distan
    REAL(wp), PARAMETER :: ZERO = 0.0_wp, ONE = 1.0_wp
    gradient_distan = DOT_PRODUCT(position, gradient_direct) / SQRT(MAX(DOT_PRODUCT(gradient_direct, gradient_direct), 1.0e-30_wp))
    IF (gradient_length > ZERO) THEN
      normalized_posi = MAX(MIN(gradient_distan / gradient_length, ONE), ZERO)
    ELSE
      normalized_posi = ZERO
    END IF
    SELECT CASE (INT(gradient_type))
      CASE (1)
        gradient_parame = (EXP(gradient_expone * normalized_posi) - ONE) / (EXP(gradient_expone) - ONE + 1.0e-30_wp)
      CASE (2)
        gradient_parame = normalized_posi**gradient_expone
      CASE DEFAULT
        gradient_parame = normalized_posi
    END SELECT
  END SUBROUTINE ComputeGradientParameter603

  SUBROUTINE BuildElasticStiffness603(E, nu, ndim, analysis_type, D)
    REAL(wp), INTENT(IN) :: E, nu
    INTEGER(i4), INTENT(IN) :: ndim, analysis_type
    REAL(wp), INTENT(OUT) :: D(6,6)
    REAL(wp) :: lambda, mu
    REAL(wp), PARAMETER :: ZERO = 0.0_wp, ONE = 1.0_wp, TWO = 2.0_wp
    lambda = E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = E / (TWO * (ONE + nu))
    D = ZERO
    IF (ndim == 3) THEN
      D(1,1) = lambda + TWO * mu
      D(1,2) = lambda
      D(1,3) = lambda
      D(2,1) = lambda
      D(2,2) = lambda + TWO * mu
      D(2,3) = lambda
      D(3,1) = lambda
      D(3,2) = lambda
      D(3,3) = lambda + TWO * mu
      D(4,4) = mu
      D(5,5) = mu
      D(6,6) = mu
    ELSE IF (ndim == 2) THEN
      D(1,1) = E / (ONE - nu*nu)
      D(1,2) = E * nu / (ONE - nu*nu)
      D(2,1) = D(1,2)
      D(2,2) = D(1,1)
      D(3,3) = E / (TWO * (ONE + nu))
    ELSE
      D(1,1) = E
    END IF
  END SUBROUTINE BuildElasticStiffness603

  SUBROUTINE UF_Legacy_Special_603(stress, statev, ddsdde, sse, spd, scd, rpl, &
                                   ddsddt, drplde, drpldt, stran, dstran, time, dtime, &
                                   temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, &
                                   props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6), statev(*)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6), sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6), time(2), dtime, temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*), props(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    CALL MD_MAT_UMAT_603(stress, statev, ddsdde, sse, spd, scd, rpl, &
                  ddsddt, drplde, drpldt, stran, dstran, time, dtime, &
                  temp, dtemp, predef, dpred, ndir, nshr, nstatev, nprops, &
                  props, ndim, kstep, kinc)
  END SUBROUTINE UF_Legacy_Special_603


    ! --- from MD_MATLIB_DB ---
!> Status: CORE
!> Last verified: 2026-02-28


  !=============================================================================
  ! Public Interfaces
  !=============================================================================
  PUBLIC :: MD_MAT_DB_GetMaterialByName
  PUBLIC :: MD_MAT_DB_GetMaterialByID
  PUBLIC :: MD_MAT_DB_ListAllMaterials
  PUBLIC :: MD_MAT_DB_ValidateParameters

  !=============================================================================
  ! Constants
  !=============================================================================
  INTEGER(i4), PARAMETER :: MD_MAT_DB_MAX_MATS = 60
  INTEGER(i4), PARAMETER :: MD_MAT_CLASS_METAL = 1
  INTEGER(i4), PARAMETER :: MD_MAT_CLASS_RUBBER = 2
  INTEGER(i4), PARAMETER :: MD_MAT_CLASS_POLYMER = 3
  INTEGER(i4), PARAMETER :: MD_MAT_CLASS_CERAMIC = 4
  INTEGER(i4), PARAMETER :: MD_MAT_CLASS_COMPOSITE = 5

  ! ==================== Material database entry type ====================
  TYPE, PUBLIC :: Mat_Entry
    CHARACTER(LEN=50) :: name                      !! Material name
    INTEGER(i4) :: material_class                      !! Material class (1=Metal, 2=Rubber, etc.)
    INTEGER(i4) :: const_model                  !! Constitutive model ID (31=Von Mises, 101=Neo-H, 181=Prony)

    ! Von Mises parameters
    REAL(8) :: E = 0.0D0                           !! Young's modulus (Pa)
    REAL(8) :: nu = 0.0D0                          !! Poisson's ratio
    REAL(8) :: sigma_y = 0.0D0                     !! Yield stress (Pa)
    REAL(8) :: H = 0.0D0                           !! Hardening modulus (Pa)

    ! Neo-Hookean parameters
    REAL(8) :: mu = 0.0D0                          !! Shear modulus (Pa)
    REAL(8) :: lambda = 0.0D0                      !! Lame parameter (Pa)
    REAL(8) :: K = 0.0D0                           !! Bulk modulus (Pa)

    ! Prony parameters
    REAL(8) :: G_inf = 0.0D0                       !! Long-term shear modulus (Pa)
    REAL(8), ALLOCATABLE :: G_terms(:)             !! Prony G_n (up to 10 terms)
    REAL(8), ALLOCATABLE :: tau_terms(:)           !! Prony tau_n (relaxation time)
    INTEGER(i4) :: n_prony_terms = 0                   !! Number of Prony terms

    REAL(8) :: dE_dT = 0.0D0                       !! dE/dT (Pa/K)
    REAL(8) :: dmu_dT = 0.0D0                      !! dmu/dT (Pa/K)

    REAL(8) :: density = 0.0D0                     !! Density (kg/m3)
    REAL(8) :: CTE = 0.0D0                         !! Thermal expansion coefficient (1/K)
    REAL(8) :: kappa_thermal = 0.0D0               !! Thermal conductivity (W/m?K)
    REAL(8) :: specific_heat = 0.0D0               !! Specific heat (J/kg?K)

    CHARACTER(LEN=200) :: reference                !! Data source (literature/ABAQUS official)
    CHARACTER(LEN=50) :: temperature_range         !! Applicable temperature range
    CHARACTER(LEN=100) :: notes                    !! Notes
  END TYPE Mat_Entry

  ! ==================== Material database array ====================
  TYPE(Mat_Entry), ALLOCATABLE, TARGET :: material_db(:)
  INTEGER(i4) :: n_materials = 0                       !! Actual number of materials


    ! --- from MD_MAT_UTILS ---


  !=============================================================================
  ! PUBLIC Exports
  !=============================================================================
  PUBLIC :: MatComp_RotMat, ValidMatProps, CheckPropertyRange
  PUBLIC :: MatChk_Compat, GetMatPropInfo
  PUBLIC :: MatInit_StateV, UpdateStateV, GetStateV, SetStateV
  PUBLIC :: MatComp_Stress, InterpolateProperty
  PUBLIC :: MatSet_Ori, TransformMatProps, TransformStress, TransformStrain
  PUBLIC :: MatParamId, ExpDataPt, ExpDataSet, MatParamId_LSQ
  PUBLIC :: MD_Mat_GetUnifiedParams, MD_Mat_SetUnifiedParams
  PUBLIC :: MD_Mat_ValidateUnifiedParams, MD_Mat_GetParamInfo
  PUBLIC :: MD_Mat_RegisterModel, MD_Mat_UnregisterModel
  PUBLIC :: MD_Mat_GetRegisteredModels, MD_Mat_FindModelByName
  PUBLIC :: UF_MatProp_Init, UF_MatProp_Valid, UF_MatProp_GetInfo
  PUBLIC :: UF_MatProp_QueryByName, UF_MatProp_ListByCategory
  PUBLIC :: MD_Mat_ValidatePlasticPropsForPopulate
  PUBLIC :: MD_Mat_ValidatePropsForPopulate


  PUBLIC :: UF_Mat_Eval_Dispatch
  PUBLIC :: UF_Mat_Eval_Dispatch_FromDesc
  PUBLIC :: UF_Elastic_Eval_Dispatch_FromDesc
  PUBLIC :: UF_Plastic_Eval_Dispatch_FromDesc
  ! UF_Mat_UMAT_Dispatch is PRIVATE: ABAQUS ABI boundary layer, not a UFC internal interface


  !=============================================================================
  ! PUBLIC Exports - Re-export everything for backward compatibility
  !=============================================================================
  PUBLIC :: MatCtxLegacy, MatRes, MatFlags, MatProps
  PUBLIC :: MD_Mat_Desc, MD_MatSta, MD_MatCtx, MD_MatModel, MD_MatModelDesc, MD_MatAlgo
  ! DEPRECATED 2026-05: MD_MatSta is a transitional EXTENDS(StateBase) type.
  ! Use MD_MatState (from MD_Mat_Def) for new code. See MD_Mat_Def.f90 ::383 for
  ! the deprecation note. Will be removed after all consumers migrate.
  PUBLIC :: MD_MatPointSta
  ! DEPRECATED 2026-05: MD_MatPointSta is a transitional EXTENDS type.
  ! Prefer MD_MatState for new integration-point state. See MD_Mat_Def.f90 ::425.
  PUBLIC :: MD_ElasticMatDesc, MD_PlasticMatDesc, MD_HyperElasticMatDesc
  PUBLIC :: MD_DamageMatDesc, MD_PronyMatDesc, MD_CompositeMatDesc
  PUBLIC :: MD_Material_Ctx
  PUBLIC :: MD_MatMeta, MatReg, MatInst, MatPoolMgr
  PUBLIC :: MatOri, MatPropValid
  PUBLIC :: MatEval, EvalMaterial_Ctx
  PUBLIC :: UniUMAT
  PUBLIC :: init_mate, reg_mate_types, prop_mate, st_mate, del_mate
  PUBLIC :: MatInit_Def
  PUBLIC :: MatComp_RotMat, ValidMatProps, CheckPropertyRange
  PUBLIC :: MatChk_Compat, GetMatPropInfo
  PUBLIC :: MatInit_StateV, UpdateStateV, GetStateV, SetStateV
  PUBLIC :: MatComp_Stress, InterpolateProperty
  PUBLIC :: MatSet_Ori, TransformMatProps, TransformStress, TransformStrain
  PUBLIC :: MatParamId, ExpDataPt, ExpDataSet
  PUBLIC :: MatParamId_LSQ
  PUBLIC :: MD_Mat_GetUnifiedParams, MD_Mat_SetUnifiedParams
  PUBLIC :: MD_Mat_ValidateUnifiedParams, MD_Mat_GetParamInfo
  PUBLIC :: MD_Mat_RegisterModel, MD_Mat_UnregisterModel
  PUBLIC :: MD_Mat_GetRegisteredModels, MD_Mat_FindModelByName
  PUBLIC :: MD_MAT_MODEL_UNKNO, MD_MAT_MODEL_ELAS, MD_MAT_MODEL_PLAST, MD_MAT_MODEL_HYP
  PUBLIC :: MD_MAT_MODEL_VISC, MD_MAT_MODEL_CREEP, MD_MAT_MODEL_USER
  PUBLIC :: MD_MAT_CATEGORY_GENERAL
  PUBLIC :: MATERIAL_DESC_I, MATERIAL_ST_ID, MD_MAT_G_MATERIAL_ID
  PUBLIC :: MD_MAT_CAT_ELASTIC, MD_MAT_CAT_PLASTIC, MD_MAT_CAT_HYPERELASTIC
  PUBLIC :: MD_MAT_CAT_DAMAGE, MD_MAT_CAT_CREEP, MD_MAT_CAT_VISCOELASTIC
  PUBLIC :: MD_MAT_CAT_COMPOSITE, MD_MAT_CAT_MULTIPHYSICS, MD_MAT_CAT_USER_DEFINED
  PUBLIC :: MD_MAT_ID_ISO_ELASTIC  ! [REMOVED] MD_MAT_ID_ELASTIC_ISOTROPIC_101 (no external refs)
  PUBLIC :: MD_MAT_ID_ORTHO_ELASTIC, MD_MAT_ID_TRANS_ISO, MD_MAT_ID_ANISO_ELASTIC
  PUBLIC :: MD_MAT_ID_POROUS_ELASTIC, MD_MAT_ID_VONMISES, MD_MAT_ID_HILL
  PUBLIC :: MD_MAT_ID_DRUCKER_PRAGER, MD_MAT_ID_MOHR_COULOMB, MD_MAT_ID_JOHNSON_COOK
  PUBLIC :: MD_MAT_ID_CHABOCHE, MD_MAT_ID_CAM_CLAY, MD_MAT_ID_GURSON, MD_MAT_ID_CDP
  PUBLIC :: MD_MAT_ID_NEOHOOKEAN, MD_MAT_ID_MOONEY_RIVLIN, MD_MAT_ID_OGDEN
  PUBLIC :: MD_MAT_ID_YEOH, MD_MAT_ID_ARRUDA_BOYCE, MD_MAT_ID_HYPERFOAM
  PUBLIC :: MD_MAT_ID_DUCTILE_DMG, MD_MAT_ID_BRITTLE_DMG, MD_MAT_ID_PROGRESSIVE_DMG
  PUBLIC :: MD_MAT_ID_NORTON_CREEP, MD_MAT_ID_GAROFALO_CREEP, MD_MAT_ID_PRONY
  PUBLIC :: MD_MAT_ID_MAXWELL, MD_MAT_ID_KELVIN, MD_MAT_ID_LAMINATE, MD_MAT_ID_FIBER_REINF
  PUBLIC :: MD_MAT_ID_UMAT, MD_MAT_ID_VUMAT
  ! [REMOVED] Legacy aliases MatDesc, MaterialDesc (migrated to MD_Mat_Desc)
  ! ---- New domain exports (74-model extension) ----
  ! Concrete/Brittle (MD_MAT_UMAT_700~703)
  PUBLIC :: MD_MAT_UMAT_700, MD_MAT_UMAT_701, MD_MAT_UMAT_702, MD_MAT_UMAT_703
  PUBLIC :: CDP_Desc, CDP_State, SmearedCrack_Desc
  PUBLIC :: MD_MAT_UMAT_CDP, MD_MAT_UMAT_DiffuseCrack, MD_MAT_UMAT_BrittleCrack, MD_MAT_UMAT_MohrCoulomb_Conc
  PUBLIC :: UF_Concrete_RegAllMats
  ! GeoMat (MD_MAT_UMAT_800~806)
  PUBLIC :: MD_MAT_UMAT_800, MD_MAT_UMAT_801, MD_MAT_UMAT_802, MD_MAT_UMAT_803, MD_MAT_UMAT_804, MD_MAT_UMAT_805, MD_MAT_UMAT_806
  PUBLIC :: MCC_Desc, MCC_State, JointedRock_Desc
  PUBLIC :: MD_MAT_UMAT_MC_Geo, MD_MAT_UMAT_ExtDP, MD_MAT_UMAT_CappedDP, MD_MAT_UMAT_CamClay, MD_MAT_UMAT_ModCamClay
  PUBLIC :: MD_MAT_UMAT_JointedRock, MD_MAT_UMAT_GeoCreep, UF_GeoMat_RegAllMats
  ! Composite (MD_MAT_UMAT_900~909)
  PUBLIC :: MD_MAT_UMAT_900, MD_MAT_UMAT_901, MD_MAT_UMAT_902, MD_MAT_UMAT_903, MD_MAT_UMAT_904
  PUBLIC :: MD_MAT_UMAT_905, MD_MAT_UMAT_906, MD_MAT_UMAT_907, MD_MAT_UMAT_908, MD_MAT_UMAT_909
  PUBLIC :: Lamina_Desc, CompDmg_State, CZM_Desc
  PUBLIC :: MD_MAT_UMAT_Lamina, MD_MAT_UMAT_Ortho3D, MD_MAT_UMAT_Aniso21, MD_MAT_UMAT_PQFiber
  PUBLIC :: MD_MAT_UMAT_Hashin, MD_MAT_UMAT_Puck, MD_MAT_UMAT_LaRC, MD_MAT_UMAT_CZM, MD_MAT_UMAT_ProgDmg, MD_MAT_UMAT_Fabric
  PUBLIC :: UF_Composite_RegAllMats
  ! MultiPhys (MD_MAT_UMAT_1000~1007)
  PUBLIC :: MD_MAT_UMAT_1000, MD_MAT_UMAT_1001, MD_MAT_UMAT_1002, MD_MAT_UMAT_1003
  PUBLIC :: MD_MAT_UMAT_1004, MD_MAT_UMAT_1005, MD_MAT_UMAT_1006, MD_MAT_UMAT_1007
  PUBLIC :: SMA_Desc, Biot_Desc, HolzapfelOgden_Desc
  PUBLIC :: MD_MAT_UMAT_ThermoMech, MD_MAT_UMAT_Piezo, MD_MAT_UMAT_DielectElast, MD_MAT_UMAT_SMA, MD_MAT_UMAT_SMP
  PUBLIC :: MD_MAT_UMAT_MagnetoMech, MD_MAT_UMAT_PoroFluid, MD_MAT_UMAT_BioTissue, UF_MultiPhys_RegAllMats
  ! Foam/Special (MD_MAT_UMAT_1100~1105)
  PUBLIC :: MD_MAT_UMAT_1100, MD_MAT_UMAT_1101, MD_MAT_UMAT_1102, MD_MAT_UMAT_1103, MD_MAT_UMAT_1104, MD_MAT_UMAT_1105
  PUBLIC :: CrushFoam_Desc, RateFoam_Desc, Multiscale_Desc
  PUBLIC :: MD_MAT_UMAT_CrushFoam, MD_MAT_UMAT_RateFoam, MD_MAT_UMAT_NoTension, MD_MAT_UMAT_NoCompression
  PUBLIC :: MD_MAT_UMAT_MultiscaleFoam, MD_MAT_UMAT_TempDepFoam, UF_Foam_RegAllMats
  ! HyperElastic extensions (MD_MAT_UMAT_451~453)
  PUBLIC :: MD_MAT_UMAT_451, MD_MAT_UMAT_452, MD_MAT_UMAT_453
  PUBLIC :: Mullins_Desc, Mullins_State, VDW_Ext_Desc, Marlow_Ext_Desc
  PUBLIC :: MD_MAT_UMAT_Mullins, MD_MAT_UMAT_VDW_Ext, MD_MAT_UMAT_Marlow_Ext, UF_HyperExt_RegAllMats
  ! Viscosity extensions (MD_MAT_UMAT_506~510)
  PUBLIC :: MD_MAT_UMAT_506, MD_MAT_UMAT_507, MD_MAT_UMAT_508, MD_MAT_UMAT_509, MD_MAT_UMAT_510
  PUBLIC :: NLVisc_Desc, Viscoplast_Desc, PolymerCure_Desc
  PUBLIC :: ViscoplDmg_Desc, RateFoam_Ext_Desc
  PUBLIC :: MD_MAT_UMAT_NLVisc, MD_MAT_UMAT_Viscoplast, MD_MAT_UMAT_PolymerCure
  PUBLIC :: MD_MAT_UMAT_ViscoplDmg, MD_MAT_UMAT_RateFoam_Ext, UF_ViscExt_RegAllMats
  ! User extended interfaces
  PUBLIC :: MD_MAT_UMAT_ID_UMAT, MD_MAT_UMAT_ID_VUMAT, MD_MAT_UMAT_ID_UHARD, MD_MAT_UMAT_ID_USDFLD, MD_MAT_UMAT_ID_UEXPAN
  PUBLIC :: UserMat_Registry, UHARD_Desc, USDFLD_Desc, UEXPAN_Desc
  PUBLIC :: UF_UserMat_Register, UF_UserMat_Exists, UF_UserMat_GetInfo
  PUBLIC :: UF_UserMat_RegAllInterfaces
  ! Note: MatProperties is defined in MD_Mat_Base.f90, not in MD_Mat_Unified


  !=============================================================================
  ! PUBLIC Exports
  !=============================================================================
  PUBLIC :: MatEval, EvalMaterial_Ctx
  PUBLIC :: MatEval_Plast, MatEval_Mises, MatEval_DP


  !=============================================================================
  ! Public Interfaces
  !=============================================================================
  PUBLIC :: UF_Mat_GetInfo
  PUBLIC :: UF_Mat_Reg
  PUBLIC :: MD_Mat_InitReg
  PUBLIC :: UF_Mat_GetCategory
  PUBLIC :: UF_Mat_ListMaterials
  ! Parameter validation (merged from Param_Valid_API)
  PUBLIC :: MD_Mat_ValidParameters
  PUBLIC :: MD_Mat_ValidParameterRange
  PUBLIC :: MD_Mat_ValidParameterConsist
  PUBLIC :: MD_Mat_ValidParameterDependencies
  PUBLIC :: ParameterValidResult

  !=============================================================================
  ! Mat Constants
  !=============================================================================
  INTEGER(i4), PARAMETER :: MD_MAT_REG_MAX_MATS = 500_i4

  ! Mat category constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_ELAS = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_PLASTI = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_COMP = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_HYP = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_VISC = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_DAMAGE = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_CREEP = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_SPECIA = 7_i4

  CHARACTER(LEN=*), PARAMETER :: MD_MAT_CATEGORY_NAMES(8) = &
    ["Elastic     ", "Plastic     ", "Hyperelastic", &
     "Viscoelastic", "Damage      ", "Creep       ", "Special     ", &
     "Composite   "]

  ! Mat ID ranges (PUBLIC so downstream modules can use them)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_ELAS_S = 101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_ELAS_E = 199_i4
  ! Mat ID range constants (start/end pairs for each category)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_PLAST_S = 201_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_PLAST_E = 299_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_HYP_ST  = 301_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_HYP_EN  = 399_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_VISC_S  = 401_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_VISC_E  = 499_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_DMG_S   = 501_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_DMG_E   = 599_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_CREEP_S = 601_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_CREEP_E = 699_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_SPEC_S  = 701_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_RANGE_SPEC_E  = 999_i4

  !=============================================================================
  ! Parameter Validation Result Type (merged from Param_Valid_API)
  !=============================================================================
  TYPE, PUBLIC :: ParameterValidResult
    LOGICAL :: is_valid = .TRUE.
    INTEGER(i4) :: n_warnings = 0
    INTEGER(i4) :: n_errors = 0
    CHARACTER(LEN=256), ALLOCATABLE :: warnings(:)
    CHARACTER(LEN=256), ALLOCATABLE :: errors(:)
  END TYPE ParameterValidResult

  !=============================================================================
  ! Unified Mat Information Type
  !=============================================================================
  TYPE, PUBLIC :: UnifMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4) :: category = 0
    CHARACTER(LEN=32) :: category_name = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE UnifMatInfo

  !=============================================================================
  ! Mat Registry
  !=============================================================================
  TYPE(UnifMatInfo), SAVE, ALLOCATABLE :: unified_registr(:)
  INTEGER(i4), SAVE :: n_registered = 0_i4
  LOGICAL, SAVE :: registry_initialized = .FALSE.


  !=============================================================================
  ! PUBLIC Exports
  !=============================================================================
  PUBLIC :: UniUMAT
  PUBLIC :: MatCtxLegacy, MatRes, MatFlags, MatProps
  PUBLIC :: MD_Material_Ctx


  !=============================================================================
  ! UF_MaterialModel TYPE (merged from UF_Material_Base)
  ! Mat model container used by element computation routines
  !=============================================================================
  type, public :: UF_MaterialModel
    !! Mat model container used by element computation routines
    integer(i4) :: id = 0_i4                        ! Mat ID
    type(MatProperties) :: props                ! Mat properties
  contains
    procedure, public :: Init => UF_MaterialModel_Init
    procedure, public :: Clean => UF_MaterialModel_Clean
  end type UF_MaterialModel

  !=============================================================================
  ! MATERIAL CATEGORY INFO TYPES (stubs for missing domain interfaces)
  !=============================================================================
  TYPE, PUBLIC :: ElasMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: category = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE ElasMatInfo

  TYPE, PUBLIC :: HypMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: category = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE HypMatInfo

  TYPE, PUBLIC :: ViscMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: category = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE ViscMatInfo

  TYPE, PUBLIC :: DmgMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: category = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE DmgMatInfo

  TYPE, PUBLIC :: CreepMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: category = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE CreepMatInfo

  TYPE, PUBLIC :: CompMatInfo
    INTEGER(i4) :: material_id = 0
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: category = ""
    INTEGER(i4) :: nprops_min = 0
    INTEGER(i4) :: nprops_max = 0
    INTEGER(i4) :: nstatev_min = 0
    INTEGER(i4) :: nstatev_max = 0
    LOGICAL :: available = .FALSE.
  END TYPE CompMatInfo

  !=============================================================================
  ! STRUCTURAL Mat RESULT TYPE
  ! Note: StructMatRes is defined in MD_UniFld.f90 to avoid circular dependencies
  ! This module only defines MatProperties
  !=============================================================================

    TYPE, PUBLIC :: HardeningTable_Init_In
        INTEGER(i4) :: capacity = 100                              ! Initial capacity ????
    END TYPE HardeningTable_Init_In

    TYPE, PUBLIC :: HardeningTable_AddPoint_In
        REAL(wp) :: stress = 0.0_wp                                ! Yield stress ?_y ????
        REAL(wp) :: plastic_strain = 0.0_wp                        ! Plastic strain ?_p ????
        REAL(wp) :: strain_rate = 0.0_wp                           ! Strain rate ?? ????(optional)
        REAL(wp) :: temperature = 0.0_wp                            ! Temperature T ????(optional)
    END TYPE HardeningTable_AddPoint_In

    TYPE, PUBLIC :: HardeningTable_Interpolate_In
        REAL(wp) :: plastic_strain = 0.0_wp                         ! Plastic strain ?_p ????
    END TYPE HardeningTable_Interpolate_In

    TYPE, PUBLIC :: HardeningTable_Interpolate_Out
        REAL(wp) :: yield_stress = 0.0_wp                          ! Yield stress ?_y ????
    END TYPE HardeningTable_Interpolate_Out

    TYPE, PUBLIC :: UF_DampingDef
        LOGICAL :: is_defined = .FALSE.                            ! Defined flag
        REAL(wp) :: alpha = 0.0_wp                                  ! Mass proportional coefficient ? ????(Rayleigh)
        REAL(wp) :: beta = 0.0_wp                                   ! Stiffness proportional coefficient ? ????(Rayleigh)
        REAL(wp) :: composite = 0.0_wp                             ! Structural composite damping ????
    CONTAINS
        PROCEDURE :: set => damping_set
    END TYPE UF_DampingDef

    TYPE, PUBLIC :: DampingDef_Set_In
        REAL(wp) :: alpha = 0.0_wp                                  ! Mass proportional ? ????(optional)
        REAL(wp) :: beta = 0.0_wp                                   ! Stiffness proportional ? ????(optional)
        REAL(wp) :: composite = 0.0_wp                              ! Composite damping ????(optional)
    END TYPE DampingDef_Set_In

    TYPE, PUBLIC :: UF_ExpansionDef
        LOGICAL :: is_defined = .FALSE.                            ! Defined flag
        INTEGER(i4) :: type = 1                                     ! Expansion type ????(1=ISO, 2=ORTHO, 3=ANISO)
        REAL(wp) :: ref_temp = 0.0_wp                              ! Reference temperature T_ref ????
        REAL(wp), ALLOCATABLE :: alpha(:)                          ! Expansion coefficients ? ???^n_dim
    CONTAINS
        PROCEDURE :: set_iso => expansion_set_iso
        PROCEDURE :: set_ortho3 => expansion_set_ortho3
        PROCEDURE :: set_aniso_voigt6 => expansion_set_aniso_voigt6
    END TYPE UF_ExpansionDef

    TYPE, PUBLIC :: ExpansionDef_SetIso_In
        REAL(wp) :: alpha = 0.0_wp                                  ! Expansion coefficient ? ????
        REAL(wp) :: ref_temp = 0.0_wp                              ! Reference temperature T_ref ????(optional)
    END TYPE ExpansionDef_SetIso_In

  type, public :: ExpDataPt
    !! Single experimental data point

    real(wp) :: strain = 0.0_wp
    real(wp) :: stress = 0.0_wp
    real(wp) :: temp = 0.0_wp
    real(wp) :: time = 0.0_wp
    real(wp) :: weight = 1.0_wp
  end type ExpDataPt

  type, public :: ExpDataSet
    !! Collection of experimental data points

    integer(i4) :: n_points = 0
    type(ExpDataPt), allocatable :: data(:)
    character(len=64) :: test_type = ""
  end type ExpDataSet

  type, public :: MatParamId
    !! Mat parameter identifier

    logical :: is_initialized = .false.
    type(ExpDataSet) :: exp_data
    real(wp), allocatable :: param_lower(:)
    real(wp), allocatable :: param_upper(:)
    real(wp), allocatable :: param_initial(:)
    real(wp), allocatable :: param_identifie(:)
    real(wp) :: fit_error = 0.0_wp
    integer(i4) :: method = 1_i4
    integer(i4) :: max_iterations = 1000_i4
    real(wp) :: tolerance = 1.0e-6_wp

  contains
    procedure, public :: Init => MatParamId_Init
    procedure, public :: LoadData => MatParamId_LoadData
    procedure, public :: SetBounds => MatParamId_SetBounds
    procedure, public :: Identify => MatParamId_Identify
    procedure, public :: GetParams => MatParamId_GetParams
    procedure, public :: GetError => MatParamId_GetError
    procedure, public :: Clean => MatParamId_Clean
  end type MatParamId

  TYPE, PUBLIC :: MatPropertyDef
    INTEGER(i4) :: mat_id           = 0_i4          !! Mat model ID (1?00)
    INTEGER(i4) :: mat_category     = 0_i4          !! Category: ELASTIC/PLASTIC/HYPERELASTIC/DAMAGE/CREEP/VISCOELASTIC/COMPOSITE
    INTEGER(i4) :: num_props        = 0_i4          !! Number of Mat properties
    REAL(wp), ALLOCATABLE :: props(:)               !! Mat properties (flexible size, max 50)
    CHARACTER(len=64) :: mat_name   = ""           !! Mat model name (e.g., "VonMises", "Neo-Hookean")
    LOGICAL :: is_user_defined      = .FALSE.       !! UMAT/VUMAT flag
    CHARACTER(len=256) :: umat_path = ""           !! Path to user subroutine (if is_user_defined=.true.)

    ! Extension for advanced features
    INTEGER(i4) :: num_state_vars   = 0_i4          !! Number of state variables (SDVs)
    INTEGER(i4) :: num_field_vars   = 0_i4          !! Number of field variables
    LOGICAL :: is_temperature_dependent = .FALSE.
    LOGICAL :: is_rate_dependent        = .FALSE.
    LOGICAL :: requires_tangent         = .TRUE.    !! Whether consistent tangent is required

    ! Metadata for validation and documentation
    REAL(wp) :: min_props(50) = 0.0_wp              !! Minimum allowable values for each property
    REAL(wp) :: max_props(50) = 1.0e30_wp           !! Maximum allowable values for each property
    CHARACTER(len=128) :: prop_names(50) = ""      !! Property names (e.g., "Young's Modulus", "Yield Stress")
    CHARACTER(len=32) :: prop_units(50)  = ""      !! Property units (e.g., "MPa", "1/K")
  END TYPE MatPropertyDef

    TYPE, PUBLIC :: MaterialDef_Init_In
        CHARACTER(LEN=MD_MAT_MAX_MATERIAL_NAME) :: name = ""
        INTEGER(i4) :: mat_type = 0                                ! Material type ????(optional)
    END TYPE MaterialDef_Init_In

    TYPE, PUBLIC :: MaterialDef_SetElasticIso_In
        REAL(wp) :: E = 0.0_wp                                     ! Young's modulus E ????
        REAL(wp) :: nu = 0.0_wp                                    ! Poisson's ratio ? ????
    END TYPE MaterialDef_SetElasticIso_In

    TYPE, PUBLIC :: MaterialDef_SetPlasticMises_In
        REAL(wp) :: sigma_y0 = 0.0_wp                              ! Initial yield stress ?_y0 ????
        REAL(wp) :: H = 0.0_wp                                     ! Hardening modulus H ????(optional)
    END TYPE MaterialDef_SetPlasticMises_In

    TYPE, PUBLIC :: MaterialDef_SetDamping_In
        REAL(wp) :: alpha = 0.0_wp                                  ! Mass proportional coefficient ? ????(optional)
        REAL(wp) :: beta = 0.0_wp                                   ! Stiffness proportional coefficient ? ????(optional)
        REAL(wp) :: composite = 0.0_wp                             ! Composite damping ????(optional)
    END TYPE MaterialDef_SetDamping_In

    TYPE, PUBLIC :: MaterialDef_SetExpansion_In
        REAL(wp) :: alpha = 0.0_wp                                  ! Expansion coefficient ? ????
        REAL(wp) :: ref_temp = 0.0_wp                              ! Reference temperature T_ref ????(optional)
    END TYPE MaterialDef_SetExpansion_In

    TYPE, PUBLIC :: MaterialDef_SetElasticOrtho_In
        REAL(wp) :: E1 = 0.0_wp                                    ! Young's modulus E??????(direction 1)
        REAL(wp) :: E2 = 0.0_wp                                    ! Young's modulus E??????(direction 2)
        REAL(wp) :: E3 = 0.0_wp                                    ! Young's modulus E??????(direction 3)
        REAL(wp) :: nu12 = 0.0_wp                                  ! Poisson's ratio ??? ????
        REAL(wp) :: nu13 = 0.0_wp                                  ! Poisson's ratio ??? ????
        REAL(wp) :: nu23 = 0.0_wp                                  ! Poisson's ratio ??? ????
        REAL(wp) :: G12 = 0.0_wp                                   ! Shear modulus G?? ????
        REAL(wp) :: G13 = 0.0_wp                                   ! Shear modulus G?? ????
        REAL(wp) :: G23 = 0.0_wp                                   ! Shear modulus G?? ????
    END TYPE MaterialDef_SetElasticOrtho_In

    TYPE, PUBLIC :: MaterialDef_SetElasticTransIso_In
        REAL(wp) :: Ep = 0.0_wp                                    ! Young's modulus MD_MAT_E_p ????(in-plane)
        REAL(wp) :: Et = 0.0_wp                                    ! Young's modulus MD_MAT_E_t ????(transverse)
        REAL(wp) :: nup = 0.0_wp                                   ! Poisson's ratio ?_p ????(in-plane)
        REAL(wp) :: nut = 0.0_wp                                   ! Poisson's ratio ?_t ????(transverse)
        REAL(wp) :: Gp = 0.0_wp                                    ! Shear modulus G_p ????(in-plane)
    END TYPE MaterialDef_SetElasticTransIso_In

    TYPE, PUBLIC :: MaterialDef_SetElasticAniso_In
        REAL(wp) :: C(21) = 0.0_wp                                 ! Elastic stiffness matrix C ??????(Voigt notation)
    END TYPE MaterialDef_SetElasticAniso_In

    TYPE :: UF_MaterialDef
        CHARACTER(LEN=MD_MAT_MAX_MATERIAL_NAME) :: name = ""              ! Material name
        CHARACTER(LEN=MD_MAT_MAX_MATERIAL_NAME) :: model_keyword = ""      ! Model keyword (e.g. 'Elastic-Isotropic-101')
        INTEGER(i4) :: id = 0                                       ! Material ID ????
        INTEGER(i4) :: material_type = 0                           ! Material type ????(from UF_MaterialTypes)
        
        ! General properties array (interpreted based on material_type)
        INTEGER(i4) :: num_props = 0                                ! Number of properties ????
        REAL(wp) :: props(MD_MAT_MAX_MATERIAL_PROPS) = 0.0_wp             ! Properties array ???^n_props
        
        ! Common elastic properties (convenience access)
        REAL(wp) :: E = 0.0_wp                                     ! Young's modulus E ????
        REAL(wp) :: nu = 0.0_wp                                     ! Poisson's ratio ? ????
        REAL(wp) :: G = 0.0_wp                                     ! Shear modulus G ????
        REAL(wp) :: K = 0.0_wp                                     ! Bulk modulus K ????
        REAL(wp) :: lambda = 0.0_wp                                ! Lam?'s first parameter ? ????
        
        ! Density (for dynamics/gravity)
        REAL(wp) :: density = 0.0_wp                               ! Density ? ????
        
        ! Thermal properties
        REAL(wp) :: alpha = 0.0_wp                                 ! Thermal expansion coefficient ? ????
        REAL(wp) :: conductivity = 0.0_wp                          ! Thermal conductivity k ????
        REAL(wp) :: specific_heat = 0.0_wp                        ! Specific heat capacity c_p ????
        
        ! Poroelastic / pore-fluid properties (for UF-PORO)
        REAL(wp) :: biot_alpha      = 0.0_wp       ! Biot coefficient ?_b ????
        REAL(wp) :: k_hyd_poro      = 0.0_wp       ! Hydraulic conductivity k_hyd ????
        REAL(wp) :: S_s_poro        = 0.0_wp       ! Storage coefficient S_s ????
        REAL(wp) :: rho_fluid_poro  = 0.0_wp       ! Pore fluid density ?_f ????
        REAL(wp) :: cp_fluid_poro   = 0.0_wp       ! Pore fluid specific heat c_pf ????
        
        ! Two-phase pore-flow parameters (for *UF-PORO-2PH)
        REAL(wp) :: twoph_model_flag = 0.0_wp      ! <1.5: Corey; >=1.5: van Genuchten-Mualem
        REAL(wp) :: vg_alpha         = 0.0_wp      ! van Genuchten/BC ? (1/Pa)
        REAL(wp) :: vg_n             = 0.0_wp      ! van Genuchten n
        REAL(wp) :: phi_total        = 0.0_wp      ! Total porosity ?
        REAL(wp) :: corey_Swr        = 0.0_wp      ! Corey: residual wetting phase saturation S_wr
        REAL(wp) :: corey_Snr        = 0.0_wp      ! Corey: residual non-wetting phase saturation S_nr
        REAL(wp) :: corey_nw         = 0.0_wp      ! Corey: wetting-phase exponent n_w
        REAL(wp) :: vg_m             = 0.0_wp      ! van Genuchten m
        REAL(wp) :: mualem_l         = 0.0_wp      ! Mualem connectivity parameter l
        
        ! Hardening data (for plasticity)



        TYPE(UF_HardeningTable) :: hardening
        
        ! Damping
        TYPE(UF_DampingDef) :: damping
        
        ! Expansion
        TYPE(UF_ExpansionDef) :: expansion
        
        ! State variable requirements
        INTEGER(i4) :: num_statev = 0                              ! Number of state variables per IP ????
        
        ! Flags
        LOGICAL :: is_user_material = .FALSE.                       ! True if UMAT
        LOGICAL :: is_temperature_dependent = .FALSE.               ! Temperature-dependent flag
        LOGICAL :: is_rate_dependent = .FALSE.                      ! Rate-dependent flag
        
        ! Coupled-field switches (mapped down to L4 UF_MatProps%props):
        !   - THERMEXP flag -> Thermal elementMAT_IDX_ENABLE_TH_EXP (currently 7)
        !   - VOLRATE  flag -> Poro elementMAT_IDX_ENABLE_VOLRATE (currently 8)
        LOGICAL :: enable_thermal_expansion = .TRUE.                ! Enable thermal expansion flag
        LOGICAL :: enable_poro_volrate      = .TRUE.                ! Enable poro volume rate flag

        ! Phase6 1.3: committed integration-point state for increment rollback (L5 snapshot/restore)
        TYPE(MD_MatState), ALLOCATABLE :: committed_state
        
    CONTAINS

        PROCEDURE :: init                 => material_init
        PROCEDURE :: set_elastic_iso      => material_set_elastic_iso
        PROCEDURE :: set_elastic_ortho    => material_set_elastic_ortho
        PROCEDURE :: set_elastic_transiso => material_set_elastic_transiso
        PROCEDURE :: set_elastic_aniso    => material_set_elastic_aniso
        PROCEDURE :: set_plastic_mises    => material_set_plastic_mises
        PROCEDURE :: set_plastic_dp       => material_set_plastic_dp
        PROCEDURE :: set_plastic_cc       => material_set_plastic_cc
        PROCEDURE :: set_plastic_mc       => material_set_plastic_mc
        PROCEDURE :: set_plastic_cdpm     => material_set_plastic_cdpm
        PROCEDURE :: set_viscoplastic_iso => material_set_viscoplastic_iso
        PROCEDURE :: set_damage_ortho_puck=> material_set_damage_ortho_puck
        PROCEDURE :: set_hyperelastic_nh  => material_set_hyperelastic_nh
        PROCEDURE :: set_density          => material_set_density


        PROCEDURE :: set_thermal          => material_set_thermal
        PROCEDURE :: set_damping          => material_set_damping
        PROCEDURE :: set_expansion        => material_set_expansion
        PROCEDURE :: get_D_matrix         => material_get_D_matrix
    END TYPE UF_MaterialDef

    TYPE :: UF_MaterialDB
        INTEGER(i4) :: num_materials = 0                           ! Number of materials ????
        TYPE(UF_MaterialDef), ALLOCATABLE :: materials(:)          ! Material definitions array
    CONTAINS
        PROCEDURE :: init => matdb_init
        PROCEDURE :: add_material => matdb_add_material
        PROCEDURE :: find_by_name => matdb_find_by_name
        PROCEDURE :: find_by_id => matdb_find_by_id
        PROCEDURE :: get_material => matdb_get_material
        PROCEDURE :: clear => matdb_clear
    END TYPE UF_MaterialDB

contains

  !=============================================================================
  ! MatProperties Procedures
  !=============================================================================
  subroutine MatProperties_Init(this, material_id, props, density)
    class(MatProperties), intent(inout) :: this
    integer(i4), intent(in), optional :: material_id
    real(wp), intent(in), optional :: props(:)
    real(wp), intent(in), optional :: density

    ! Init base class fields
    this%material_id = 0_i4
    this%nprops = 0_i4
    if (allocated(this%props)) deallocate(this%props)

    if (present(material_id)) this%material_id = material_id
    if (present(density)) this%density = density

    if (present(props)) then
      allocate(this%props(size(props)))
      this%props = props
      this%nprops = size(props)
    end if
  end subroutine MatProperties_Init

  subroutine MatProperties_Clean(this)
    class(MatProperties), intent(inout) :: this
    if (allocated(this%props)) deallocate(this%props)
    this%material_id = 0_i4
    this%nprops = 0_i4
    this%density = 0.0_wp
  end subroutine MatProperties_Clean

  !=============================================================================
  ! UF_MaterialModel Procedures (merged from UF_Material_Base)
  !=============================================================================
  subroutine UF_MaterialModel_Init(this, material_id, props, density)
    class(UF_MaterialModel), intent(inout) :: this
    integer(i4), intent(in), optional :: material_id
    type(MatProperties), intent(in), optional :: props
    real(wp), intent(in), optional :: density

    if (present(material_id)) this%cfg%id = material_id
    if (present(props)) then
      this%props = props
    else if (present(density)) then
      call this%props%Init(density=density)
    end if
  end subroutine UF_MaterialModel_Init

  subroutine UF_MaterialModel_Clean(this)
    class(UF_MaterialModel), intent(inout) :: this
    call this%props%Clean()
    this%cfg%id = 0_i4
  end subroutine UF_MaterialModel_Clean



    !> @brief Hardening table initialization input structure (Desc category)

    !> @brief Hardening table add point input structure (Desc category)

    !> @brief Hardening table interpolation input structure (Desc category)

    !> @brief Hardening table interpolation output structure (State category)
    
    ! ==========================================================================
    ! DAMPING DATA (Desc category)
    ! ==========================================================================
    !> @brief Damping definition type (Desc category)
    !! @details Read-only configuration for damping properties
    !!   Theory: Rayleigh damping C = ??M + ??K, where ?, ? ????are damping coefficients,
    !!     M ???^(n_dof?n_dof) is mass matrix, K ???^(n_dof?n_dof) is stiffness matrix

    !> @brief Damping set input structure (Desc category)
    
    ! ==========================================================================
    ! EXPANSION DATA (Desc category)
    ! ==========================================================================
    !> @brief Thermal expansion definition type (Desc category)
    !! @details Read-only configuration for thermal expansion properties
    !!   Theory: Thermal expansion ?_th = ??(T - T_ref), where ? ????is expansion coefficient,
    !!     T ????is temperature, T_ref ????is reference temperature

    !> @brief Expansion set isotropic input structure (Desc category)

    ! ==========================================================================
    ! MATERIAL DEFINITION TYPE (Desc category)
    ! ==========================================================================
    !> @brief Material definition type (Desc category)
    !! @details Read-only configuration for material properties
    !!   Theory: Material properties include elastic (E, ?, G, K, ?), plastic (?_y, H),
    !!     thermal (?, k, c_p), density ? ???? and coupled-field properties


    
    ! ==========================================================================
    ! MATERIAL DATABASE TYPE (Ctx category)
    ! ==========================================================================
    !> @brief Material database type (Ctx category)
    !! @details Aggregates references to material definitions for management





    !> @brief Material initialization input structure (Desc category)

    !> @brief Material set elastic isotropic input structure (Desc category)

    !> @brief Material set plastic Mises input structure (Desc category)
    
    !> @brief Material set damping input structure (Desc category)
    
    !> @brief Material set expansion input structure (Desc category)
    
    !> @brief Material set elastic orthotropic input structure (Desc category)
    
    !> @brief Material set elastic transversely isotropic input structure (Desc category)
    
    !> @brief Material set elastic anisotropic input structure (Desc category)
    
    
    ! ==========================================================================
    ! STRUCTURED INTERFACE PROCEDURES
    ! ==========================================================================
    
    !> @brief Initialize hardening table (structured interface)
    SUBROUTINE HardeningTable_Init_Structured(in, table, status)
        TYPE(HardeningTable_Init_In), INTENT(IN) :: in
        TYPE(UF_HardeningTable), INTENT(INOUT) :: table
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL table%init(in%capacity)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE HardeningTable_Init_Structured
    
    !> @brief Add point to hardening table (structured interface)
    SUBROUTINE HardeningTable_AddPoint_Structured(in, table, status)
        TYPE(HardeningTable_AddPoint_In), INTENT(IN) :: in
        TYPE(UF_HardeningTable), INTENT(INOUT) :: table
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL table%add_point(in%stress, in%plastic_strain)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE HardeningTable_AddPoint_Structured
    
    !> @brief Interpolate yield stress (structured interface)
    SUBROUTINE HardeningTable_Interpolate_Structured(in, out, table)
        TYPE(HardeningTable_Interpolate_In), INTENT(IN) :: in
        TYPE(HardeningTable_Interpolate_Out), INTENT(OUT) :: out
        TYPE(UF_HardeningTable), INTENT(IN) :: table
        
        out%yield_stress = table%interpolate(in%plastic_strain)
    END SUBROUTINE HardeningTable_Interpolate_Structured
    
    !> @brief Initialize material (structured interface)
    SUBROUTINE MaterialDef_Init_Structured(in, material, status)
        TYPE(MaterialDef_Init_In), INTENT(IN) :: in
        TYPE(UF_MaterialDef), INTENT(INOUT) :: material
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL material%init(in%name, in%mat_type)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MaterialDef_Init_Structured
    
    !> @brief Set elastic isotropic properties (structured interface)
    SUBROUTINE MaterialDef_SetElasticIso_Structured(in, material, status)
        TYPE(MaterialDef_SetElasticIso_In), INTENT(IN) :: in
        TYPE(UF_MaterialDef), INTENT(INOUT) :: material
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL material%set_elastic_iso(in%E, in%nu)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MaterialDef_SetElasticIso_Structured
    
    !> @brief Set plastic Mises properties (structured interface)
    SUBROUTINE MaterialDef_SetPlasticMises_Structured(in, material, status)
        TYPE(MaterialDef_SetPlasticMises_In), INTENT(IN) :: in
        TYPE(UF_MaterialDef), INTENT(INOUT) :: material
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL material%set_plastic_mises(in%sigma_y0, in%H)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MaterialDef_SetPlasticMises_Structured
    
    !> @brief Set damping properties (structured interface)
    SUBROUTINE MaterialDef_SetDamping_Structured(in, material, status)
        TYPE(MaterialDef_SetDamping_In), INTENT(IN) :: in
        TYPE(UF_MaterialDef), INTENT(INOUT) :: material
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL material%set_damping(in%alpha, in%beta, in%composite)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MaterialDef_SetDamping_Structured
    
    !> @brief Set thermal expansion properties (structured interface)
    SUBROUTINE MaterialDef_SetExpansion_Structured(in, material, status)
        TYPE(MaterialDef_SetExpansion_In), INTENT(IN) :: in
        TYPE(UF_MaterialDef), INTENT(INOUT) :: material
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL material%set_expansion(in%alpha, in%ref_temp)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MaterialDef_SetExpansion_Structured
    
    !> @brief Set elastic orthotropic properties (structured interface)
    SUBROUTINE MaterialDef_SetElasticOrtho_Structured(in, material, status)
        TYPE(MaterialDef_SetElasticOrtho_In), INTENT(IN) :: in
        TYPE(UF_MaterialDef), INTENT(INOUT) :: material
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL material%set_elastic_ortho(in%E1, in%E2, in%E3, in%nu12, in%nu13, in%nu23, &
                                        in%G12, in%G13, in%G23)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MaterialDef_SetElasticOrtho_Structured
    
    !> @brief Set elastic transversely isotropic properties (structured interface)
    SUBROUTINE MaterialDef_SetElasticTransIso_Structured(in, material, status)
        TYPE(MaterialDef_SetElasticTransIso_In), INTENT(IN) :: in
        TYPE(UF_MaterialDef), INTENT(INOUT) :: material
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL material%set_elastic_transiso(in%Ep, in%Et, in%nup, in%nut, in%Gp)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MaterialDef_SetElasticTransIso_Structured
    
    !> @brief Set elastic anisotropic properties (structured interface)
    SUBROUTINE MaterialDef_SetElasticAniso_Structured(in, material, status)
        TYPE(MaterialDef_SetElasticAniso_In), INTENT(IN) :: in
        TYPE(UF_MaterialDef), INTENT(INOUT) :: material
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL material%set_elastic_aniso(in%C)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MaterialDef_SetElasticAniso_Structured
    
    !> @brief Set damping definition (structured interface)
    SUBROUTINE DampingDef_Set_Structured(in, damping, status)
        TYPE(DampingDef_Set_In), INTENT(IN) :: in
        TYPE(UF_DampingDef), INTENT(INOUT) :: damping
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL damping%set(in%alpha, in%beta, in%composite)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE DampingDef_Set_Structured
    
    !> @brief Set isotropic expansion definition (structured interface)
    SUBROUTINE ExpansionDef_SetIso_Structured(in, expansion, status)
        TYPE(ExpansionDef_SetIso_In), INTENT(IN) :: in
        TYPE(UF_ExpansionDef), INTENT(INOUT) :: expansion
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        CALL expansion%set_iso(in%alpha, in%ref_temp)
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE ExpansionDef_SetIso_Structured
    
    ! ==========================================================================
    ! LEGACY INTERFACE PROCEDURES (for backward compatibility)
    ! NOTE: These are legacy interfaces. Use structured interfaces (_In/_Out) instead.
    ! @deprecated Use structured interfaces (MaterialDef_*_Structured) instead
    ! ==========================================================================
    
    ! ==========================================================================
    ! HARDENING TABLE METHODS
    ! ==========================================================================
    !=============================================================================
    !> @brief Initialize hardening table (legacy interface)
    !! @details Initializes hardening table with optional capacity
    !! @param[inout] this Hardening table instance
    !! @param[in] capacity Initial capacity ????(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use HardeningTable_Init_In type to encapsulate initialization parameters
    !=============================================================================
    SUBROUTINE hardening_init(this, capacity)
        CLASS(UF_HardeningTable), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: capacity
        INTEGER(i4) :: cap
        
        cap = 100
        IF (PRESENT(capacity)) cap = capacity
        
        this%num_points = 0
        IF (ALLOCATED(this%stress)) DEALLOCATE(this%stress)
        IF (ALLOCATED(this%plastic_strain)) DEALLOCATE(this%plastic_strain)
        ALLOCATE(this%stress(cap))
        ALLOCATE(this%plastic_strain(cap))
        this%stress = 0.0_wp
        this%plastic_strain = 0.0_wp
        
    END SUBROUTINE hardening_init
    
    !=============================================================================
    !> @brief Add point to hardening table (legacy interface)
    !! @details Adds a (?_y, ?_p) point to the hardening table
    !! @param[inout] this Hardening table instance
    !! @param[in] stress Yield stress ?_y ????
    !! @param[in] plastic_strain Plastic strain ?_p ????
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use HardeningTable_AddPoint_In type to encapsulate point parameters
    !=============================================================================
    SUBROUTINE hardening_add_point(this, stress, plastic_strain)
        CLASS(UF_HardeningTable), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: stress, plastic_strain
        
        IF (.NOT. ALLOCATED(this%stress)) CALL this%init()
        IF (this%num_points >= SIZE(this%stress)) RETURN
        
        this%num_points = this%num_points + 1
        this%stress(this%num_points) = stress
        this%plastic_strain(this%num_points) = plastic_strain
        
    END SUBROUTINE hardening_add_point
    
    !=============================================================================
    !> @brief Interpolate yield stress from hardening table
    !! @details Computes ?_y(?_p) by linear interpolation/extrapolation
    !! @param[in] this Hardening table instance
    !! @param[in] eps_p Plastic strain ?_p ????
    !! @return Yield stress ?_y ????
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use HardeningTable_Interpolate_In and HardeningTable_Interpolate_Out types
    !=============================================================================
    FUNCTION hardening_interpolate(this, eps_p) RESULT(sigma_y)
        CLASS(UF_HardeningTable), INTENT(IN) :: this
        REAL(wp), INTENT(IN) :: eps_p
        REAL(wp) :: sigma_y
        INTEGER(i4) :: i
        REAL(wp) :: t
        
        sigma_y = 0.0_wp
        IF (this%num_points == 0) RETURN
        
        ! Before first point
        IF (eps_p <= this%plastic_strain(1)) THEN
            sigma_y = this%stress(1)
            RETURN
        END IF
        
        ! After last point (extrapolate constant)
        IF (eps_p >= this%plastic_strain(this%num_points)) THEN
            sigma_y = this%stress(this%num_points)
            RETURN
        END IF
        
        ! Linear interpolation
        DO i = 1, this%num_points - 1
            IF (eps_p >= this%plastic_strain(i) .AND. &
                eps_p < this%plastic_strain(i+1)) THEN
                t = (eps_p - this%plastic_strain(i)) / &
                    (this%plastic_strain(i+1) - this%plastic_strain(i))
                sigma_y = this%stress(i) + t * (this%stress(i+1) - this%stress(i))
                RETURN
            END IF
        END DO
        
    END FUNCTION hardening_interpolate
    
    ! ========================================================================== 
    ! DAMPING METHODS
    ! ==========================================================================
    !=============================================================================
    !> @brief Set damping parameters (legacy interface)
    !! @details Sets Rayleigh damping coefficients ?, ? ????and composite damping
    !!   Theory: C = ??M + ??K
    !! @param[inout] this Damping definition instance
    !! @param[in] alpha Mass proportional coefficient ? ????(optional)
    !! @param[in] beta Stiffness proportional coefficient ? ????(optional)
    !! @param[in] composite Composite damping ????(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use DampingDef_Set_In type to encapsulate damping parameters
    !=============================================================================
    SUBROUTINE damping_set(this, alpha, beta, composite)
        CLASS(UF_DampingDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN), OPTIONAL :: alpha, beta, composite
        
        this%is_defined = .TRUE.
        IF (PRESENT(alpha)) this%alpha = alpha
        IF (PRESENT(beta)) this%beta = beta
        IF (PRESENT(composite)) this%composite = composite
    END SUBROUTINE damping_set


    ! ==========================================================================
    ! EXPANSION METHODS
    ! ==========================================================================
    !=============================================================================
    !> @brief Set isotropic thermal expansion (legacy interface)
    !! @details Sets isotropic expansion coefficient ? ????and reference temperature T_ref ????
    !!   Theory: ?_th = ??(T - T_ref)
    !! @param[inout] this Expansion definition instance
    !! @param[in] alpha Expansion coefficient ? ????
    !! @param[in] ref_temp Reference temperature T_ref ????(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use ExpansionDef_SetIso_In type to encapsulate expansion parameters
    !=============================================================================
    SUBROUTINE expansion_set_iso(this, alpha, ref_temp)
        CLASS(UF_ExpansionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: alpha
        REAL(wp), INTENT(IN), OPTIONAL :: ref_temp
        
        this%is_defined = .TRUE.
        this%type = 1
        IF (ALLOCATED(this%alpha)) DEALLOCATE(this%alpha)
        ALLOCATE(this%alpha(1))
        this%alpha(1) = alpha
        
        IF (PRESENT(ref_temp)) this%ref_temp = ref_temp
    END SUBROUTINE expansion_set_iso

    SUBROUTINE expansion_set_ortho3(this, a11, a22, a33, ref_temp)
        CLASS(UF_ExpansionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: a11, a22, a33
        REAL(wp), INTENT(IN), OPTIONAL :: ref_temp

        this%is_defined = .TRUE.
        this%type = 2
        IF (ALLOCATED(this%alpha)) DEALLOCATE(this%alpha)
        ALLOCATE(this%alpha(3))
        this%alpha(1) = a11
        this%alpha(2) = a22
        this%alpha(3) = a33
        IF (PRESENT(ref_temp)) this%ref_temp = ref_temp
    END SUBROUTINE expansion_set_ortho3

    SUBROUTINE expansion_set_aniso_voigt6(this, a6, ref_temp)
        CLASS(UF_ExpansionDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: a6(6)
        REAL(wp), INTENT(IN), OPTIONAL :: ref_temp

        this%is_defined = .TRUE.
        this%type = 3
        IF (ALLOCATED(this%alpha)) DEALLOCATE(this%alpha)
        ALLOCATE(this%alpha(6))
        this%alpha(1:6) = a6(1:6)
        IF (PRESENT(ref_temp)) this%ref_temp = ref_temp
    END SUBROUTINE expansion_set_aniso_voigt6
    !=============================================================================
    ! MATERIAL DEFINITION METHODS
    !=============================================================================
    !=============================================================================
    !> @brief Set material damping (legacy interface)
    !! @details Sets damping parameters for material
    !! @param[inout] this Material definition instance
    !! @param[in] alpha Mass proportional coefficient ? ????(optional)
    !! @param[in] beta Stiffness proportional coefficient ? ????(optional)
    !! @param[in] composite Composite damping ????(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE material_set_damping(this, alpha, beta, composite)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN), OPTIONAL :: alpha, beta, composite
        CALL this%damping%set(alpha, beta, composite)
    END SUBROUTINE material_set_damping
    
    !=============================================================================
    !> @brief Set material thermal expansion (legacy interface)
    !! @details Sets isotropic expansion coefficient ? ????and reference temperature
    !! @param[inout] this Material definition instance
    !! @param[in] alpha Expansion coefficient ? ????
    !! @param[in] ref_temp Reference temperature T_ref ????(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE material_set_expansion(this, alpha, ref_temp)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: alpha
        REAL(wp), INTENT(IN), OPTIONAL :: ref_temp
        CALL this%expansion%set_iso(alpha, ref_temp)
        this%alpha = alpha ! Update legacy field
    END SUBROUTINE material_set_expansion

    !=============================================================================
    !> @brief Initialize material definition (legacy interface)
    !! @details Initializes material with name and optional type
    !! @param[inout] this Material definition instance
    !! @param[in] name Material name
    !! @param[in] mat_type Material type ????(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use MaterialDef_Init_In type to encapsulate initialization parameters
    !=============================================================================
    SUBROUTINE material_init(this, name, mat_type)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN), OPTIONAL :: mat_type
        
        this%name = TRIM(name)
        this%model_keyword = ""
        this%material_type = 0
        IF (PRESENT(mat_type)) this%material_type = mat_type

        
        this%num_props = 0
        this%props = 0.0_wp
        this%E = 0.0_wp
        this%nu = 0.0_wp
        this%G = 0.0_wp
        this%K = 0.0_wp
        this%lambda = 0.0_wp
        this%density = 0.0_wp
        this%alpha           = 0.0_wp
        this%conductivity    = 0.0_wp
        this%specific_heat   = 0.0_wp
        this%biot_alpha      = 0.0_wp
        this%k_hyd_poro      = 0.0_wp
        this%S_s_poro        = 0.0_wp
        this%rho_fluid_poro  = 0.0_wp
        this%cp_fluid_poro   = 0.0_wp
        this%twoph_model_flag = 0.0_wp
        this%vg_alpha         = 0.0_wp
        this%vg_n             = 0.0_wp
        this%phi_total        = 0.0_wp
        this%corey_Swr        = 0.0_wp
        this%corey_Snr        = 0.0_wp
        this%corey_nw         = 0.0_wp
        this%vg_m             = 0.0_wp
        this%mualem_l         = 0.0_wp
        this%num_statev      = 0
        
        this%enable_thermal_expansion = .TRUE.
        this%enable_poro_volrate      = .TRUE.

        IF (ALLOCATED(this%committed_state)) THEN
            CALL this%committed_state%Destroy()
            DEALLOCATE(this%committed_state)
        END IF
        
    END SUBROUTINE material_init

    
    !=============================================================================
    !> @brief Set isotropic elastic properties (legacy interface)
    !! @details Sets Young's modulus E ????and Poisson's ratio ? ???? computes G, K, ?
    !!   Theory: G = E/(2(1+?)), K = E/(3(1-2?)), ? = ?E/((1+?)(1-2?))
    !! @param[inout] this Material definition instance
    !! @param[in] E Young's modulus E ????
    !! @param[in] nu Poisson's ratio ? ????
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use MaterialDef_SetElasticIso_In type to encapsulate elastic parameters
    !=============================================================================
    SUBROUTINE material_set_elastic_iso(this, E, nu)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: E, nu
        
        this%E = E
        this%nu = nu
        this%G = E / (2.0_wp * (1.0_wp + nu))
        this%K = E / (3.0_wp * (1.0_wp - 2.0_wp * nu))
        this%lambda = nu * E / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
        
        this%props(1) = E
        this%props(2) = nu
        this%num_props = 2
        
    END SUBROUTINE material_set_elastic_iso
    
    !=============================================================================
    !> @brief Set orthotropic elastic properties (legacy interface)
    !! @details Sets orthotropic elastic constants: E?? E?? E?? ???, ???, ???, G??, G??, G??
    !! @param[inout] this Material definition instance
    !! @param[in] E1, E2, E3 Young's moduli E?? E?? E??????
    !! @param[in] nu12, nu13, nu23 Poisson's ratios ???, ???, ??? ????
    !! @param[in] G12, G13, G23 Shear moduli G??, G??, G?? ????
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use MaterialDef_SetElasticOrtho_In type to encapsulate orthotropic parameters
    !=============================================================================
    SUBROUTINE material_set_elastic_ortho(this, E1, E2, E3, nu12, nu13, nu23, G12, G13, G23)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: E1, E2, E3, nu12, nu13, nu23, G12, G13, G23
        
        this%props(1) = E1
        this%props(2) = E2
        this%props(3) = E3
        this%props(4) = nu12
        this%props(5) = nu13
        this%props(6) = nu23
        this%props(7) = G12
        this%props(8) = G13
        this%props(9) = G23
        this%num_props = MAX(this%num_props, 9)
        
    END SUBROUTINE material_set_elastic_ortho
    
    !=============================================================================
    !> @brief Set transversely isotropic elastic properties (legacy interface)
    !! @details Sets transversely isotropic elastic constants: MD_MAT_E_p, MD_MAT_E_t, ?_p, ?_t, G_p
    !! @param[inout] this Material definition instance
    !! @param[in] Ep Young's modulus MD_MAT_E_p ????(in-plane)
    !! @param[in] Et Young's modulus MD_MAT_E_t ????(transverse)
    !! @param[in] nup Poisson's ratio ?_p ????(in-plane)
    !! @param[in] nut Poisson's ratio ?_t ????(transverse)
    !! @param[in] Gp Shear modulus G_p ????(in-plane)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use MaterialDef_SetElasticTransIso_In type to encapsulate transversely isotropic parameters
    !=============================================================================
    SUBROUTINE material_set_elastic_transiso(this, Ep, Et, nup, nut, Gp)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: Ep, Et, nup, nut, Gp
        
        this%props(1) = Ep
        this%props(2) = Et
        this%props(3) = nup
        this%props(4) = nut
        this%props(5) = Gp
        this%num_props = MAX(this%num_props, 5)
        
    END SUBROUTINE material_set_elastic_transiso
    
    !=============================================================================
    !> @brief Set anisotropic elastic properties (legacy interface)
    !! @details Sets full anisotropic elastic stiffness matrix C ??????(Voigt notation)
    !! @param[inout] this Material definition instance
    !! @param[in] C Elastic stiffness matrix C ??????(Voigt notation: C??, C??, ..., C??)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use MaterialDef_SetElasticAniso_In type to encapsulate anisotropic parameters
    !=============================================================================
    SUBROUTINE material_set_elastic_aniso(this, C)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: C(:)
        
        IF (SIZE(C) < 21) RETURN
        this%props(1:21) = C(1:21)
        this%num_props = MAX(this%num_props, 21)
        
    END SUBROUTINE material_set_elastic_aniso
    
    !=============================================================================
    !> @brief Set von Mises plastic properties (legacy interface)
    !! @details Sets initial yield stress ?_y0 ????and optional hardening modulus H ????
    !! @param[inout] this Material definition instance
    !! @param[in] sigma_y0 Initial yield stress ?_y0 ????
    !! @param[in] H Hardening modulus H ????(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !!   Recommended: Use MaterialDef_SetPlasticMises_In type to encapsulate plastic parameters
    !=============================================================================
    SUBROUTINE material_set_plastic_mises(this, sigma_y0, H)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: sigma_y0      ! Initial yield stress ?_y0 ????
        REAL(wp), INTENT(IN), OPTIONAL :: H   ! Hardening modulus H ????
        
        this%props(3) = sigma_y0
        IF (PRESENT(H)) this%props(4) = H
        this%num_props = MAX(this%num_props, 4)
        this%num_statev = MAX(this%num_statev, 7)  ! eps_p, back_stress(6)
        
    END SUBROUTINE material_set_plastic_mises
    
    SUBROUTINE material_set_plastic_dp(this, phi, c, H_iso, psi)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: phi, c, H_iso
        REAL(wp), INTENT(IN), OPTIONAL :: psi
        
        this%props(3) = phi
        this%props(4) = c
        this%props(5) = H_iso
        IF (PRESENT(psi)) this%props(6) = psi
        this%num_props   = MAX(this%num_props, 6)
        this%num_statev  = MAX(this%num_statev, 10)
        
    END SUBROUTINE material_set_plastic_dp
    
    SUBROUTINE material_set_plastic_cc(this, M, pc0, H_pc, H_iso)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: M, pc0, H_pc, H_iso
        
        this%props(3) = M
        this%props(4) = pc0
        this%props(5) = H_pc
        this%props(6) = H_iso
        this%num_props   = MAX(this%num_props, 6)
        this%num_statev  = MAX(this%num_statev, 12)
        
    END SUBROUTINE material_set_plastic_cc
    
    SUBROUTINE material_set_plastic_mc(this, phi, c, H_iso, psi)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: phi, c, H_iso
        REAL(wp), INTENT(IN), OPTIONAL :: psi
        
        this%props(3) = phi
        this%props(4) = c
        this%props(5) = H_iso
        IF (PRESENT(psi)) this%props(6) = psi
        this%num_props   = MAX(this%num_props, 6)
        this%num_statev  = MAX(this%num_statev, 10)
        
    END SUBROUTINE material_set_plastic_mc
    
    SUBROUTINE material_set_plastic_cdpm(this, phi, c, H_iso, d0, H_d, d_max)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: phi, c, H_iso, d0, H_d, d_max
        
        this%props(3) = phi
        this%props(4) = c
        this%props(5) = H_iso
        this%props(6) = d0
        this%props(7) = H_d
        this%props(8) = d_max
        this%num_props   = MAX(this%num_props, 8)
        this%num_statev  = MAX(this%num_statev, 15)
        
    END SUBROUTINE material_set_plastic_cdpm
    
    SUBROUTINE material_set_viscoplastic_iso(this, MD_MAT_E_ref, nu, sigma_y0_ref, H_ref, m_rate, &
                                             eps0_ref, Q_activation, R_gas, T_ref, alpha_thermal)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: MD_MAT_E_ref, nu, sigma_y0_ref, H_ref, m_rate
        REAL(wp), INTENT(IN) :: eps0_ref, Q_activation, R_gas, T_ref
        REAL(wp), INTENT(IN), OPTIONAL :: alpha_thermal

        ! Viscoplastic (MD_MAT_UMAT_260) parameters props(1:10)
        this%E  = MD_MAT_E_ref
        this%nu = nu
        this%props(1) = MD_MAT_E_ref
        this%props(2) = nu
        this%props(3) = sigma_y0_ref
        this%props(4) = H_ref
        this%props(5) = m_rate
        this%props(6) = eps0_ref
        this%props(7) = Q_activation
        this%props(8) = R_gas
        this%props(9) = T_ref

        IF (PRESENT(alpha_thermal)) THEN
            this%props(10) = alpha_thermal
            this%alpha     = alpha_thermal
            this%num_props = MAX(this%num_props, 10)
        ELSE
            this%props(10) = 0.0_wp
            this%num_props = MAX(this%num_props, 9)
        END IF

        ! Viscoplastic/creep material flags
        this%is_temperature_dependent = .TRUE.
        this%is_rate_dependent        = .TRUE.

        ! State variables: MD_MAT_UMAT_260 (analysis_type + eps_vp_eq + temp_old + eps_vp(6) + epsdot_old(6))
        this%num_statev = MAX(this%num_statev, 15)

    END SUBROUTINE material_set_viscoplastic_iso

    SUBROUTINE material_set_damage_ortho_puck(this, &
        E1, E2, E3, nu12, nu13, nu23, G12, G13, G23, &
        Xt, Xc, Yt, Yc, Zt, Zc, &
        S12, S13, S23, &
        G1c, G2c, G3c, G12c, G13c, G23c, &
        alpha1, alpha2, alpha3, theta, phi, psi)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: E1, E2, E3, nu12, nu13, nu23, G12, G13, G23
        REAL(wp), INTENT(IN) :: Xt, Xc, Yt, Yc, Zt, Zc
        REAL(wp), INTENT(IN) :: S12, S13, S23
        REAL(wp), INTENT(IN) :: G1c, G2c, G3c, G12c, G13c, G23c
        REAL(wp), INTENT(IN) :: alpha1, alpha2, alpha3, theta, phi, psi

        ! Orthotropic material Puck damage (MD_MAT_UMAT_263) parameters props(1:30)
        this%props(1)  = E1
        this%props(2)  = E2
        this%props(3)  = E3
        this%props(4)  = nu12
        this%props(5)  = nu13
        this%props(6)  = nu23
        this%props(7)  = G12
        this%props(8)  = G13
        this%props(9)  = G23
        this%props(10) = Xt
        this%props(11) = Xc
        this%props(12) = Yt
        this%props(13) = Yc
        this%props(14) = Zt
        this%props(15) = Zc
        this%props(16) = S12
        this%props(17) = S13
        this%props(18) = S23
        this%props(19) = G1c
        this%props(20) = G2c
        this%props(21) = G3c
        this%props(22) = G12c
        this%props(23) = G13c
        this%props(24) = G23c
        this%props(25) = alpha1
        this%props(26) = alpha2
        this%props(27) = alpha3
        this%props(28) = theta
        this%props(29) = phi
        this%props(30) = psi

        this%num_props  = MAX(this%num_props, 30)
        ! MD_MAT_UMAT_263 state variables: damage statev(29)
        this%num_statev = MAX(this%num_statev, 29)

    END SUBROUTINE material_set_damage_ortho_puck
    
    SUBROUTINE material_set_hyperelastic_nh(this, C10, D1)

        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: C10           ! Neo-Hookean parameter
        REAL(wp), INTENT(IN), OPTIONAL :: D1  ! Compressibility parameter
        
        this%props(1) = C10
        IF (PRESENT(D1)) THEN
            this%props(2) = D1
        ELSE
            this%props(2) = 0.0_wp  ! Incompressible
        END IF
        this%num_props = 2
        
    END SUBROUTINE material_set_hyperelastic_nh

    
    !=============================================================================
    !> @brief Set material density (legacy interface)
    !! @details Sets material density ? ????
    !! @param[inout] this Material definition instance
    !! @param[in] rho Density ? ????
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    !> @brief Set density (legacy interface)
    SUBROUTINE material_set_density(this, rho)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: rho
        this%density = rho
    END SUBROUTINE material_set_density
    
    !=============================================================================
    !> @brief Set material thermal properties (legacy interface)
    !! @details Sets thermal expansion coefficient ? ???? conductivity k ???? and specific heat c_p ????
    !! @param[inout] this Material definition instance
    !! @param[in] alpha Thermal expansion coefficient ? ????
    !! @param[in] k Thermal conductivity k ????
    !! @param[in] c Specific heat capacity c_p ????
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE material_set_thermal(this, alpha, k, c)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: alpha   ! Thermal expansion coefficient ? ????
        REAL(wp), INTENT(IN) :: k       ! Thermal conductivity k ????
        REAL(wp), INTENT(IN) :: c       ! Specific heat capacity c_p ????
        
        this%alpha = alpha
        this%conductivity = k
        this%specific_heat = c
        
    END SUBROUTINE material_set_thermal
    
    !=============================================================================
    !> @brief Get elasticity matrix D (legacy interface)
    !! @details Computes elasticity matrix D ???^(n_strain?n_strain) for isotropic material
    !!   Theory: D relates stress ? ???^n_strain to strain ? ???^n_strain: ? = D??
    !!   For 3D: D uses Lam? parameters ?, ? ????
    !!   For 2D: D uses plane strain (pt=1) or plane stress (pt=2) assumptions
    !! @param[in] this Material definition instance
    !! @param[out] D Elasticity matrix D ???^(n_strain?n_strain)
    !! @param[in] ndim Number of dimensions ????(2 or 3)
    !! @param[in] plane_type Plane type ????(1=strain, 2=stress, optional, default 1)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE material_get_D_matrix(this, D, ndim, plane_type)
        CLASS(UF_MaterialDef), INTENT(IN) :: this
        REAL(wp), INTENT(OUT) :: D(:,:)
        INTEGER(i4), INTENT(IN) :: ndim
        INTEGER(i4), INTENT(IN), OPTIONAL :: plane_type  ! 1=strain, 2=stress
        
        REAL(wp) :: E, nu, lambda, mu, c1, c2
        INTEGER(i4) :: i, pt
        
        D = 0.0_wp
        E = this%E
        nu = this%nu
        
        IF (E <= 0.0_wp) RETURN
        
        mu = E / (2.0_wp * (1.0_wp + nu))
        
        pt = 1  ! Default plane strain
        IF (PRESENT(plane_type)) pt = plane_type
        
        IF (ndim == 3) THEN
            ! 3D isotropic elastic
            lambda = nu * E / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
            c1 = lambda + 2.0_wp * mu
            
            D(1,1) = c1
            D(1,2) = lambda
            D(1,3) = lambda
            D(2,1) = lambda
            D(2,2) = c1
            D(2,3) = lambda
            D(3,1) = lambda
            D(3,2) = lambda
            D(3,3) = c1
            D(4,4) = mu
            D(5,5) = mu
            D(6,6) = mu
            
        ELSE IF (ndim == 2) THEN
            IF (pt == 1) THEN
                ! Plane strain
                lambda = nu * E / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
                c1 = lambda + 2.0_wp * mu
                
                D(1,1) = c1
                D(1,2) = lambda
                D(1,3) = lambda
                D(2,1) = lambda
                D(2,2) = c1
                D(2,3) = lambda
                D(3,1) = lambda
                D(3,2) = lambda
                D(3,3) = c1
                D(4,4) = mu
            ELSE
                ! Plane stress
                c1 = E / (1.0_wp - nu * nu)
                c2 = nu * c1
                
                D(1,1) = c1
                D(1,2) = c2
                D(2,1) = c2
                D(2,2) = c1
                D(3,3) = mu
            END IF
        END IF
        
    END SUBROUTINE material_get_D_matrix
    
    SUBROUTINE material_clear(this)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        IF (ALLOCATED(this%committed_state)) THEN
            CALL this%committed_state%Destroy()
            DEALLOCATE(this%committed_state)
        END IF
        this%name = ""
        this%model_keyword = ""
        this%num_props = 0
        this%props = 0.0_wp
    END SUBROUTINE material_clear

    !> Allocate / reset %committed_state for Phase6 cut-back (minimal: n_ip IPs, Voigt6 stress/strain).
    SUBROUTINE UF_MaterialDef_EnsureCommittedForRollback(this, n_ip, status)
        CLASS(UF_MaterialDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: n_ip
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: nip, nst, nsv_buf, six_n

        CALL init_error_status(status)
        nip = n_ip
        IF (nip < 1_i4) nip = 1_i4
        nst = this%num_statev
        IF (nst < 1_i4) nst = 1_i4
        nsv_buf = nip * nst
        six_n = 6_i4 * nip

        IF (ALLOCATED(this%committed_state)) THEN
            CALL this%committed_state%Destroy()
            DEALLOCATE(this%committed_state)
        END IF
        ALLOCATE(this%committed_state)
        CALL this%committed_state%Init()
        this%committed_state%nIntPoints = nip
        this%committed_state%cfg%id = this%id
        ALLOCATE(this%committed_state%stateV(nsv_buf))
        this%committed_state%stateV = 0.0_wp
        ALLOCATE(this%committed_state%stress(six_n))
        ALLOCATE(this%committed_state%strain(six_n))
        this%committed_state%stress = 0.0_wp
        this%committed_state%strain = 0.0_wp
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE UF_MaterialDef_EnsureCommittedForRollback

    
    ! ==========================================================================
    ! MATERIAL DATABASE METHODS
    ! ==========================================================================
    !=============================================================================
    !> @brief Initialize material database (legacy interface)
    !! @details Initializes material database with optional capacity
    !! @param[inout] this Material database instance
    !! @param[in] capacity Initial capacity ????(optional)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE matdb_init(this, capacity)
        CLASS(UF_MaterialDB), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: capacity
        INTEGER(i4) :: cap
        
        cap = 100
        IF (PRESENT(capacity)) cap = capacity
        
        this%num_materials = 0
        IF (ALLOCATED(this%materials)) DEALLOCATE(this%materials)
        ALLOCATE(this%materials(cap))
        
    END SUBROUTINE matdb_init
    
    !=============================================================================
    !> @brief Add material to database (legacy interface)
    !! @details Adds a material definition to the database
    !! @param[inout] this Material database instance
    !! @param[in] mat Material definition
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    SUBROUTINE matdb_add_material(this, mat)
        CLASS(UF_MaterialDB), INTENT(INOUT) :: this
        TYPE(UF_MaterialDef), INTENT(IN) :: mat
        TYPE(UF_MaterialDef), ALLOCATABLE :: temp(:)
        
        IF (.NOT. ALLOCATED(this%materials)) CALL this%init()
        
        IF (this%num_materials >= SIZE(this%materials)) THEN
            ALLOCATE(temp(SIZE(this%materials) * 2))
            temp(1:this%num_materials) = this%materials(1:this%num_materials)
            CALL MOVE_ALLOC(temp, this%materials)
        END IF
        
        this%num_materials = this%num_materials + 1
        this%materials(this%num_materials) = mat
        this%materials(this%num_materials)%cfg%id = this%num_materials
        
    END SUBROUTINE matdb_add_material
    
    !=============================================================================
    !> @brief Find material by name (legacy interface)
    !! @details Searches for material by name, returns index ????or 0 if not found
    !! @param[in] this Material database instance
    !! @param[in] name Material name
    !! @return Material index idx ????(0 if not found)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    FUNCTION matdb_find_by_name(this, name) RESULT(idx)
        CLASS(UF_MaterialDB), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: idx
        INTEGER(i4) :: i
        
        idx = -1
        DO i = 1, this%num_materials
            IF (TRIM(this%materials(i)%name) == TRIM(name)) THEN
                idx = i
                RETURN
            END IF
        END DO
        
    END FUNCTION matdb_find_by_name
    
    !=============================================================================
    !> @brief Find material by ID (legacy interface)
    !! @details Searches for material by ID, returns index ????or 0 if not found
    !! @param[in] this Material database instance
    !! @param[in] id Material ID ????
    !! @return Material index idx ????(0 if not found)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    FUNCTION matdb_find_by_id(this, id) RESULT(idx)
        CLASS(UF_MaterialDB), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: id
        INTEGER(i4) :: idx
        
        idx = -1
        IF (id >= 1 .AND. id <= this%num_materials) idx = id
        
    END FUNCTION matdb_find_by_id
    
    !=============================================================================
    !> @brief Get material by index (legacy interface)
    !! @details Returns pointer to material at index idx ????
    !! @param[in] this Material database instance
    !! @param[in] idx Material index ????
    !! @return Material pointer (null if invalid index)
    !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
    !=============================================================================
    FUNCTION matdb_get_material(this, idx) RESULT(mat_ptr)
        CLASS(UF_MaterialDB), INTENT(IN), TARGET :: this
        INTEGER(i4), INTENT(IN) :: idx
        TYPE(UF_MaterialDef), POINTER :: mat_ptr
        
        NULLIFY(mat_ptr)
        IF (idx >= 1 .AND. idx <= this%num_materials) THEN
            mat_ptr => this%materials(idx)
        END IF
        
    END FUNCTION matdb_get_material
    
    !=============================================================================
    !> @brief Clear material database
    !! @details Clears all materials from database
    !! @param[inout] this Material database instance
    !=============================================================================
    SUBROUTINE matdb_clear(this)
        CLASS(UF_MaterialDB), INTENT(INOUT) :: this
        this%num_materials = 0
        IF (ALLOCATED(this%materials)) DEALLOCATE(this%materials)
    END SUBROUTINE matdb_clear
    

    ! ????????????????????????????????????????????????????????????
    ! Procedures from: MD_MAT_TREE
    ! ????????????????????????????????????????????????????????????
  subroutine MatTree_BeginBatch(this, max_size)
    class(MatTree), intent(inout) :: this
    integer(i4), intent(in), optional :: max_size

    call this%batch_mgr%BeginBatch(max_size)
  end subroutine MatTree_BeginBatch

  subroutine MatTree_Deserialize(this, deserializer)
    class(MatTree), intent(inout) :: this
    class(TreeDeserializer), intent(in) :: deserializer

    integer(i4) :: n_props
    type(ErrorStatusType) :: status
    character(len=256) :: obj_name

    ! Deserialize Mat basic info
    obj_name = deserializer%BeginObject(status)
    this%cfg%id = deserializer%ReadInt(status)
    this%name = deserializer%ReadString(status)
    this%cfg%materialType = deserializer%ReadString(status)
    this%cfg%behavior = deserializer%ReadString(status)
    this%cfg%description = deserializer%ReadString(status)
    this%pop%nProps = deserializer%ReadInt(status)
    this%pop%nStateV = deserializer%ReadInt(status)
    this%node_id = deserializer%ReadInt(status)
    this%parent_id = deserializer%ReadInt(status)
    this%is_active = deserializer%ReadBool(status)
    this%is_visible = deserializer%ReadBool(status)

    ! Deserialize properties if present
    obj_name = deserializer%BeginArray(status)
    if (len_trim(obj_name) > 0 .and. this%pop%nProps > 0) then
      if (allocated(this%props)) deallocate(this%props)
      allocate(this%props(this%pop%nProps))
      call deserializer%ReadRealArray(this%props, status)
      call deserializer%EndArray(status)
    end if

    ! Init tree if not already initialized
    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
    end if

    ! Rebuild index after deserialization
    call this%RebuildIndex(status)

    call deserializer%EndObject(status)
  end subroutine MatTree_Deserialize

  subroutine MatTree_DestroyTree(this, status)
    class(MatTree), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call this%index_mgr%Destroy(status)

    this%tree_initialize = .false.

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatTree_DestroyTree

  subroutine MatTree_EndBatch(this, rebuild_index, status)
    class(MatTree), intent(inout) :: this
    logical, intent(in), optional :: rebuild_index
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call this%batch_mgr%EndBatch(rebuild_index, local_status)

    if (present(rebuild_index) .and. rebuild_index) then
      call this%RebuildIndex(local_status)
    end if

    if (present(status)) then
      status = local_status
    end if
  end subroutine MatTree_EndBatch

  function MatTree_GetByPath(this, path_str) result(obj_ptr)
    class(MatTree), intent(in), target :: this
    character(len=*), intent(in) :: path_str
    class(TreeNodeBase), pointer :: obj_ptr

    type(PathComponents) :: components

    obj_ptr => null()

    if (.not. this%tree_initialize) return

    components = this%path_resolver%ParsePath(path_str)
    if (components%GetCount() == 0) then
      obj_ptr => this
      return
    end if

    ! Mat tree has no children, so only return self if path is empty
    obj_ptr => this
  end function MatTree_GetByPath

  function MatTree_GetFullPath(this) result(path_str)
    !! Get full path string from root to this node
    class(MatTree), intent(in) :: this
    character(len=512) :: path_str
    
    character(len=64) :: name
    
    name = this%GetName()
    if (len_trim(name) > 0) then
      path_str = '/Mat/' // trim(name)
    else
      write(path_str, '(A,I0)') '/Mat/Mat_', this%GetID()
    end if
  end function MatTree_GetFullPath

  function MatTree_GetID(this) result(id)
    class(MatTree), intent(in) :: this
    integer(i4) :: id
    id = this%node_id
    if (id == 0) id = this%cfg%id
  end function MatTree_GetID

  function MatTree_GetName(this) result(name)
    class(MatTree), intent(in) :: this
    character(len=64) :: name
    name = this%name
  end function MatTree_GetName

  function MatTree_GetParentID(this) result(pid)
    class(MatTree), intent(in) :: this
    integer(i4) :: pid
    pid = this%parent_id
  end function MatTree_GetParentID

  function MatTree_GetType(this) result(ntype)
    class(MatTree), intent(in) :: this
    integer(i4) :: ntype
    ntype = NODE_TYPE_MATER
  end function MatTree_GetType

  subroutine MatTree_InitTree(this, initial_capacit, status)
    class(MatTree), intent(inout) :: this
    integer(i4), intent(in), optional :: initial_capacit
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    ! Init index manager (using a dummy container for now)
    ! Note: MatTree doesn't have child containers, so index_mgr is minimal
    ! In future, if materials have sub-properties, we can add containers here

    ! Init performance optimization modules
    ! Note: LazyIndexMgr requires a container, so we skip it for now
    ! If needed, we can create a minimal container for Mat properties

    this%node_id = this%cfg%id
    this%tree_initialize = .true.

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatTree_InitTree

  subroutine MatTree_RebuildIndex(this, status)
    class(MatTree), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%tree_initialize) then
      status%status_code = MD_MAT_STATUS_INVALID
      return
    end if

    call this%index_mgr%Rebuild(status)

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatTree_RebuildIndex

  subroutine MatTree_Serialize(this, serializer)
    class(MatTree), intent(in) :: this
    class(TreeSerializer), intent(inout) :: serializer

    type(ErrorStatusType) :: status

    ! Serialize Mat basic info
    call serializer%BeginObject("MatTree", status)
    call serializer%WriteInt(this%cfg%id, status)
    call serializer%WriteString(this%name, status)
    call serializer%WriteString(this%cfg%materialType, status)
    call serializer%WriteString(this%cfg%behavior, status)
    call serializer%WriteString(this%cfg%description, status)
    call serializer%WriteInt(this%pop%nProps, status)
    call serializer%WriteInt(this%pop%nStateV, status)
    call serializer%WriteInt(this%node_id, status)
    call serializer%WriteInt(this%parent_id, status)
    call serializer%WriteBool(this%is_active, status)
    call serializer%WriteBool(this%is_visible, status)

    ! Serialize properties if allocated
    if (allocated(this%props)) then
      call serializer%BeginArray("Properties", status)
      call serializer%WriteRealArray(this%props, status)
      call serializer%EndArray(status)
    end if

    call serializer%EndObject(status)
  end subroutine MatTree_Serialize

  subroutine MatTree_ValidateTree(this, status)
    class(MatTree), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%tree_initialize) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Tree not initialized"
      return
    end if

    call this%index_mgr%Valid(status)

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatTree_ValidateTree

    ! ????????????????????????????????????????????????????????????
    ! Procedures from: MD_MAT_UTILS_CORE
    ! ????????????????????????????????????????????????????????????

    !=============================================================================
    !> @brief Compute Lame parameters from elastic modulus and Poisson's ratio (legacy interface)
    !! @details Calculates ? = E??/((1+?)(1-2?)) and ? = E/(2(1+?))
    !!   Theory: Lame parameters relate to elastic constants: ?, ? ????
    !! @param[in] E Young's modulus E ????
    !! @param[in] nu Poisson's ratio ? ????
    !! @param[out] lambda First Lame parameter ? ????
    !! @param[out] mu Second Lame parameter (shear modulus) ? ????
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE MD_Mat_GetLameParameters(E, nu, lambda, mu)
        REAL(wp), INTENT(IN) :: E, nu
        REAL(wp), INTENT(OUT) :: lambda, mu
        
        ! Second Lame parameter (shear modulus) ? = E/(2(1+?))
        mu = MD_Mat_GetShearModulus(E, nu)
        
        ! First Lame parameter ? = E??/((1+?)(1-2?))
        lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - TWO * nu))
    END SUBROUTINE MD_Mat_GetLameParameters

    !=============================================================================
    !> @brief Validate material properties (legacy interface)
    !! @details Checks E > 0 and -1 < ? < 0.5
    !!   Theory: Physical constraints: E ????, ? ??(-1, 0.5)
    !! @param[in] E Young's modulus E ????
    !! @param[in] nu Poisson's ratio ? ????
    !! @param[out] is_valid Validation result
    !! @param[out] status Error status
    !! @note Legacy interface - parameters should be encapsulated in structured types
    !=============================================================================
    SUBROUTINE MD_Mat_ValidateProperties(E, nu, is_valid, status)
        REAL(wp), INTENT(IN) :: E, nu
        LOGICAL, INTENT(OUT) :: is_valid
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        
        CALL init_error_status(status)
        
        is_valid = .TRUE.
        
        ! Check Young's modulus E > 0
        IF (E <= ZERO) THEN
            is_valid = .FALSE.
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = 'MD_Mat_ValidateProperties: Invalid Young''s modulus'
            RETURN
        END IF
        
        ! Check Poisson's ratio -1 < ? < 0.5
        IF (nu <= -1.0_wp .OR. nu >= 0.5_wp) THEN
            is_valid = .FALSE.
            status%status_code = MD_MAT_STATUS_INVALID
            status%message = 'MD_Mat_ValidateProperties: Invalid Poisson''s ratio'
            RETURN
        END IF
        
        status%status_code = MD_MAT_STATUS_OK
    END SUBROUTINE MD_Mat_ValidateProperties

    ! ????????????????????????????????????????????????????????????
    ! Procedures from: MD_MATLIB_DB
    ! ????????????????????????????????????????????????????????????

  !! ======================================================================
  !! SUBROUTINE: MD_MAT_DB_Init
  !! ======================================================================
  SUBROUTINE MD_MAT_DB_Init()

    IMPLICIT NONE
    INTEGER(i4) :: idx

    ALLOCATE(material_db(MD_MAT_DB_MAX_MATS))
    idx = 0

    ! ========== Category 1: Metals (Von Mises) ==========

    ! 1. Low-carbon steel (Mild Steel)
    idx = idx + 1
    material_db(idx)%name = "Steel_Mild_Grade_250"
    material_db(idx)%material_class = MD_MAT_CLASS_METAL
    material_db(idx)%const_model = 31  ! Von Mises
    material_db(idx)%E = 210.0D9      ! Pa
    material_db(idx)%nu = 0.3D0
    material_db(idx)%sigma_y = 250.0D6        ! Pa
    material_db(idx)%H = 1.0D9                ! Linear hardening
    material_db(idx)%density = 7850.0D0       ! kg/m?
    material_db(idx)%reference = "ABAQUS Mat Library v2024"
    material_db(idx)%temperature_range = "20-100 C"

    ! 2. Stainless Steel 304
    idx = idx + 1
    material_db(idx)%name = "Steel_Stainless_304"
    material_db(idx)%material_class = MD_MAT_CLASS_METAL
    material_db(idx)%const_model = 31
    material_db(idx)%E = 193.0D9
    material_db(idx)%nu = 0.31D0
    material_db(idx)%sigma_y = 310.0D6
    material_db(idx)%H = 1.1D9
    material_db(idx)%density = 8000.0D0
    material_db(idx)%reference = "ABAQUS Mat Library"
    material_db(idx)%temperature_range = "20-200 C"

    ! 3. Aluminum Alloy 2024-T4
    idx = idx + 1
    material_db(idx)%name = "Aluminum_2024_T4"
    material_db(idx)%material_class = MD_MAT_CLASS_METAL
    material_db(idx)%const_model = 31
    material_db(idx)%E = 73.0D9
    material_db(idx)%nu = 0.33D0
    material_db(idx)%sigma_y = 325.0D6
    material_db(idx)%H = 0.5D9
    material_db(idx)%density = 2780.0D0
    material_db(idx)%reference = "ASM Handbook"
    material_db(idx)%temperature_range = "-50-150 C"

    ! 4. Aluminum Alloy 7075-T6
    idx = idx + 1
    material_db(idx)%name = "Aluminum_7075_T6"
    material_db(idx)%material_class = MD_MAT_CLASS_METAL
    material_db(idx)%const_model = 31
    material_db(idx)%E = 72.0D9
    material_db(idx)%nu = 0.33D0
    material_db(idx)%sigma_y = 505.0D6
    material_db(idx)%H = 0.4D9
    material_db(idx)%density = 2810.0D0
    material_db(idx)%reference = "ASM Handbook"

    ! 5. Titanium Alloy Ti-6Al-4V
    idx = idx + 1
    material_db(idx)%name = "Titanium_Ti6Al4V"
    material_db(idx)%material_class = MD_MAT_CLASS_METAL
    material_db(idx)%const_model = 31
    material_db(idx)%E = 103.0D9
    material_db(idx)%nu = 0.342D0
    material_db(idx)%sigma_y = 880.0D6
    material_db(idx)%H = 1.2D9
    material_db(idx)%density = 4430.0D0
    material_db(idx)%reference = "ABAQUS Mat Library"
    material_db(idx)%temperature_range = "-100-300 C"

    ! ========== Category 2: Rubber Materials (Neo-Hookean) ==========

    ! 6. Natural Rubber NR
    idx = idx + 1
    material_db(idx)%name = "Rubber_Natural_NR"
    material_db(idx)%material_class = MD_MAT_CLASS_RUBBER
    material_db(idx)%const_model = 101  ! Neo-Hookean
    material_db(idx)%mu = 0.3D6        ! Pa (long-term modulus)
    material_db(idx)%lambda = 0.2D6    ! Pa
    material_db(idx)%K = 2.0D9         ! Bulk modulus
    material_db(idx)%density = 920.0D0
    material_db(idx)%reference = "Boyce & Arruda (2000) on Rubber Elasticity"
    material_db(idx)%temperature_range = "-40-80 C"
    material_db(idx)%notes = "Low vulcanization natural rubber"

    ! 7. Synthetic Rubber SBR
    idx = idx + 1
    material_db(idx)%name = "Rubber_Synthetic_SBR"
    material_db(idx)%material_class = MD_MAT_CLASS_RUBBER
    material_db(idx)%const_model = 101
    material_db(idx)%mu = 0.28D6
    material_db(idx)%lambda = 0.18D6
    material_db(idx)%K = 1.9D9
    material_db(idx)%density = 940.0D0
    material_db(idx)%reference = "Rubber Industry Data"

    ! 8. Nitrile Rubber NBR
    idx = idx + 1
    material_db(idx)%name = "Rubber_NBR"
    material_db(idx)%material_class = MD_MAT_CLASS_RUBBER
    material_db(idx)%const_model = 101
    material_db(idx)%mu = 0.32D6
    material_db(idx)%lambda = 0.22D6
    material_db(idx)%K = 2.1D9
    material_db(idx)%density = 980.0D0
    material_db(idx)%reference = "ASTM D1418"
    material_db(idx)%temperature_range = "-30-100 C"

    idx = idx + 1
    material_db(idx)%name = "Rubber_EPDM"
    material_db(idx)%material_class = MD_MAT_CLASS_RUBBER
    material_db(idx)%const_model = 101
    material_db(idx)%mu = 0.25D6
    material_db(idx)%lambda = 0.15D6
    material_db(idx)%K = 1.8D9
    material_db(idx)%density = 870.0D0
    material_db(idx)%reference = "DuPont Elastomers"
    material_db(idx)%temperature_range = "-40-120 C"

    ! ==================== Material database entry type ====================

    ! 10. PVC (Rigid)
    idx = idx + 1
    material_db(idx)%name = "Polymer_PVC_Rigid"
    material_db(idx)%material_class = MD_MAT_CLASS_POLYMER
    material_db(idx)%const_model = 181  ! Prony
    material_db(idx)%G_inf = 0.8D9     ! Pa (long-term modulus)
    material_db(idx)%K = 4.0D9
    material_db(idx)%density = 1380.0D0
    material_db(idx)%n_prony_terms = 3
    ALLOCATE(material_db(idx)%G_terms(3), material_db(idx)%tau_terms(3))
    material_db(idx)%G_terms = [2.5D8, 1.0D8, 0.5D8]     ! G_1, G_2, G_3
    material_db(idx)%tau_terms = [1.0D-2, 1.0D0, 100.0D0]  ! tau_1, tau_2, tau_3 (s)
    material_db(idx)%reference = "Polymer Science Database"
    material_db(idx)%temperature_range = "20-60 C"

    ! 11. PMMA (Polymethyl methacrylate)
    idx = idx + 1
    material_db(idx)%name = "Polymer_PMMA"
    material_db(idx)%material_class = MD_MAT_CLASS_POLYMER
    material_db(idx)%const_model = 181
    material_db(idx)%G_inf = 1.2D9
    material_db(idx)%K = 5.0D9
    material_db(idx)%density = 1190.0D0
    material_db(idx)%n_prony_terms = 2
    ALLOCATE(material_db(idx)%G_terms(2), material_db(idx)%tau_terms(2))
    material_db(idx)%G_terms = [3.0D8, 1.2D8]
    material_db(idx)%tau_terms = [0.1D0, 10.0D0]
    material_db(idx)%reference = "Plexiglass Technical Data"

    ! 12. Polypropylene PP
    idx = idx + 1
    material_db(idx)%name = "Polymer_PP"
    material_db(idx)%material_class = MD_MAT_CLASS_POLYMER
    material_db(idx)%const_model = 181
    material_db(idx)%G_inf = 0.5D9
    material_db(idx)%K = 2.5D9
    material_db(idx)%density = 905.0D0
    material_db(idx)%n_prony_terms = 4
    ALLOCATE(material_db(idx)%G_terms(4), material_db(idx)%tau_terms(4))
    material_db(idx)%G_terms = [2.0D8, 1.0D8, 0.4D8, 0.1D8]
    material_db(idx)%tau_terms = [0.01D0, 0.1D0, 1.0D0, 100.0D0]
    material_db(idx)%reference = "Polypropylene Consortium"
    material_db(idx)%temperature_range = "0-80 C"

    ! 13. PET (Polyethylene terephthalate)
    idx = idx + 1
    material_db(idx)%name = "Polymer_PET"
    material_db(idx)%material_class = MD_MAT_CLASS_POLYMER
    material_db(idx)%const_model = 181
    material_db(idx)%G_inf = 1.0D9
    material_db(idx)%K = 4.5D9
    material_db(idx)%density = 1380.0D0
    material_db(idx)%n_prony_terms = 3
    ALLOCATE(material_db(idx)%G_terms(3), material_db(idx)%tau_terms(3))
    material_db(idx)%G_terms = [2.8D8, 1.2D8, 0.5D8]
    material_db(idx)%tau_terms = [0.001D0, 0.1D0, 50.0D0]
    material_db(idx)%reference = "Eastman Kodak Company"

    ! ==================== Material database entry type ====================

    ! 14. Aluminum Oxide Al2O3
    idx = idx + 1
    material_db(idx)%name = "Ceramic_Aluminum_Oxide"
    material_db(idx)%material_class = MD_MAT_CLASS_CERAMIC
    material_db(idx)%const_model = 31  ! Using Von Mises as simplified model
    material_db(idx)%E = 380.0D9
    material_db(idx)%nu = 0.22D0
    material_db(idx)%sigma_y = 400.0D6  ! Compressive strength
    material_db(idx)%density = 3970.0D0
    material_db(idx)%reference = "MatWeb Ceramics Database"

    ! 15. Silicon Nitride Si?N??
    idx = idx + 1
    material_db(idx)%name = "Ceramic_Silicon_Nitride"
    material_db(idx)%material_class = MD_MAT_CLASS_CERAMIC
    material_db(idx)%const_model = 31
    material_db(idx)%E = 320.0D9
    material_db(idx)%nu = 0.24D0
    material_db(idx)%sigma_y = 800.0D6
    material_db(idx)%density = 3240.0D0
    material_db(idx)%reference = "CoorsTek Technical Data"

    ! ==================== Material database entry type ====================

    ! 16. GFRP (Unidirectional, fiber direction)
    idx = idx + 1
    material_db(idx)%name = "Comp_GFRP_Unidirectional"
    material_db(idx)%material_class = MD_MAT_CLASS_COMPOSITE
    material_db(idx)%const_model = 31
    material_db(idx)%E = 45.0D9        ! Along fiber direction
    material_db(idx)%nu = 0.28D0
    material_db(idx)%sigma_y = 1200.0D6
    material_db(idx)%density = 1950.0D0
    material_db(idx)%reference = "Composites Design Manual"
    material_db(idx)%notes = "Glass fiber volume fraction ~60%"

    ! 17. CFRP (Carbon Fiber Reinforced Polymer)
    idx = idx + 1
    material_db(idx)%name = "Comp_CFRP_Unidirectional"
    material_db(idx)%material_class = MD_MAT_CLASS_COMPOSITE
    material_db(idx)%const_model = 31
    material_db(idx)%E = 148.0D9       ! Along fiber direction
    material_db(idx)%nu = 0.25D0
    material_db(idx)%sigma_y = 1600.0D6
    material_db(idx)%density = 1600.0D0
    material_db(idx)%reference = "Hexcel Composites"

    ! ========== Update counter ==========
    n_materials = idx

    WRITE (*, '(A)') "Mat Database Initialized:"
    WRITE (*, '(A,I0)') "Total materials loaded:", n_materials

  END SUBROUTINE MD_MAT_DB_Init

  !=============================================================================
  !> @brief Get material by name (legacy interface)
  !! @details Searches for material by name, returns material entry or "UNKNOWN"
  !! @param[in] mat_name Material name
  !! @return Material entry
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !!   Recommended: Use MatDB_GetByName_In and MatDB_GetByName_Out types:
  !!     TYPE(MatDB_GetByName_In) :: get_in
  !!     get_in%name = ...
  !!     CALL MD_MAT_DB_GetMaterialByName_Structured(get_in, get_out)
  !=============================================================================
  FUNCTION MD_MAT_DB_GetMaterialByName(mat_name) RESULT(mat_entry)
    CHARACTER(LEN=*), INTENT(IN) :: mat_name
    TYPE(Mat_Entry) :: mat_entry
    INTEGER(i4) :: i

    mat_entry%name = "UNKNOWN"

    IF (.NOT. ALLOCATED(material_db)) THEN
      CALL MD_MAT_DB_Init()
    END IF

    DO i = 1, n_materials
      IF (TRIM(material_db(i)%name) == TRIM(mat_name)) THEN
        mat_entry = material_db(i)
        RETURN
      END IF
    END DO

    WRITE (*, '(A,A)') "WARNING: Mat not found: ", TRIM(mat_name)

  END FUNCTION MD_MAT_DB_GetMaterialByName

  !=============================================================================
  !> @brief Get material by ID (legacy interface)
  !! @details Searches for material by ID ???? returns material entry or "UNKNOWN"
  !! @param[in] mat_id Material ID ????
  !! @return Material entry
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !!   Recommended: Use MatDB_GetByID_In and MatDB_GetByID_Out types:
  !!     TYPE(MatDB_GetByID_In) :: get_in
  !!     get_in%mat_id = ...
  !!     CALL MD_MAT_DB_GetMaterialByID_Structured(get_in, get_out)
  !=============================================================================
  FUNCTION MD_MAT_DB_GetMaterialByID(mat_id) RESULT(mat_entry)
    INTEGER(i4), INTENT(IN) :: mat_id
    TYPE(Mat_Entry) :: mat_entry

    IF (.NOT. ALLOCATED(material_db)) THEN
      CALL MD_MAT_DB_Init()
    END IF

    IF (mat_id >= 1 .AND. mat_id <= n_materials) THEN
      mat_entry = material_db(mat_id)
    ELSE
      WRITE (*, '(A,I0)') "ERROR: Mat ID out of range: ", mat_id
      mat_entry%name = "UNKNOWN"
    END IF

  END FUNCTION MD_MAT_DB_GetMaterialByID

  !! ======================================================================
  !! SUBROUTINE: MD_MAT_DB_ListAllMaterials
  !! ======================================================================
  SUBROUTINE MD_MAT_DB_ListAllMaterials()

    IMPLICIT NONE

    INTEGER(i4) :: i
    CHARACTER(LEN=30) :: class_name, model_name

    IF (.NOT. ALLOCATED(material_db)) THEN
      CALL MD_MAT_DB_Init()
    END IF

    WRITE (*, '(A)') "========================================"
    WRITE (*, '(A)') "Available Materials in Database"
    WRITE (*, '(A)') "========================================"

    DO i = 1, n_materials
      WRITE(*, '(I3, A, A50)') i, ": ", TRIM(material_db(i)%name)
      WRITE(*, '(A, I2)') "  Class: ", material_db(i)%material_class
      WRITE(*, '(A, I3)') "  Model ID: ", material_db(i)%const_model
      WRITE(*, '(A)') "  ---"
    END DO

    WRITE (*, '(A)') "========================================"

  END SUBROUTINE MD_MAT_DB_ListAllMaterials

  !=============================================================================
  !> @brief Validate material parameters (legacy interface)
  !! @details Validates material parameters for physical reasonableness
  !!   Validation: Density > 0, model-specific checks (E > 0, ?_y > 0 for Von Mises;
  !!     ? > 0, K > 0 for Neo-Hookean; G_inf > 0, K > 0 for Prony)
  !! @param[in] mat_entry Material entry
  !! @param[out] err_stat Error status ????(0=OK, >0=errors)
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !!   Recommended: Use MatDB_ValidateParams_In and MatDB_ValidateParams_Out types:
  !!     TYPE(MatDB_ValidateParams_In) :: validate_in
  !!     validate_in%mat_entry = ...
  !!     CALL MD_MAT_DB_ValidateParameters_Structured(validate_in, validate_out)
  !=============================================================================
  SUBROUTINE MD_MAT_DB_ValidateParameters(mat_entry, err_stat)
    TYPE(Mat_Entry), INTENT(IN) :: mat_entry
    INTEGER(i4), INTENT(OUT) :: err_stat

    err_stat = 0

    ! Basic validation
    IF (mat_entry%density <= 0.0D0) THEN
      WRITE (*, '(A,A)') "WARNING: Invalid density for ", TRIM(mat_entry%name)
      err_stat = 1
    END IF

    ! Model-specific validation
    IF (mat_entry%const_model == 31) THEN  ! Von Mises
      IF (mat_entry%E <= 0.0D0 .OR. mat_entry%sigma_y <= 0.0D0) THEN
        err_stat = err_stat + 1
      END IF
    ELSE IF (mat_entry%const_model == 101) THEN  ! Neo-Hookean
      IF (mat_entry%mu <= 0.0D0 .OR. mat_entry%K <= 0.0D0) THEN
        err_stat = err_stat + 1
      END IF
    ELSE IF (mat_entry%const_model == 181) THEN  ! Prony
      IF (mat_entry%G_inf <= 0.0D0 .OR. mat_entry%K <= 0.0D0) THEN
        err_stat = err_stat + 1
      END IF
    END IF

  END SUBROUTINE MD_MAT_DB_ValidateParameters

  !=============================================================================
  !> @brief Finalize material database
  !! @details Deallocates material database and resets count
  !! @note Legacy interface - parameters should be encapsulated in structured types (Desc/Algo/Ctx/State)
  !=============================================================================
  SUBROUTINE MD_MAT_DB_Finalize()

    IMPLICIT NONE

    IF (ALLOCATED(material_db)) THEN
      DEALLOCATE(material_db)
      n_materials = 0
    END IF

  END SUBROUTINE MD_MAT_DB_Finalize


    ! ????????????????????????????????????????????????????????????
    ! Procedures from: MD_MAT_UTILS
    ! ????????????????????????????????????????????????????????????


  subroutine MatValid_Props(properties, validator, status)
    real(wp), intent(in) :: properties(:)
    type(MatPropValid), intent(inout) :: validator
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (validator%Valid(properties)) then
      status%status_code = MD_MAT_STATUS_OK
    else
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = validator%GetErrMsg()
    end if
  end subroutine MatValid_Props

  subroutine MatChk_PropRange(propId, value, minValue, maxValue, status)
    integer(i4), intent(in) :: propId
    real(wp), intent(in) :: value, minValue, maxValue
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (value < minValue .or. value > maxValue) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Property out of range"
    else
      status%status_code = MD_MAT_STATUS_OK
    end if
  end subroutine CheckPropertyRange

  subroutine MatChk_Compat(matId1, matId2, status)
    integer(i4), intent(in) :: matId1, matId2
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatChk_Compat

  subroutine MatGet_PropInfo(id, propName, propValue, status)
    integer(i4), intent(in) :: id
    character(len=*), intent(in) :: propName
    real(wp), intent(out) :: propValue
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    propValue = 0.0_wp
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatGet_PropInfo

  subroutine MatInit_StateV(state, initialValues, varNames, status)
    type(MD_MatPointSta), intent(inout) :: state
    real(wp), intent(in), optional :: initialValues(:)
    character(len=*), intent(in), optional :: varNames(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call state%Init(state%cfg%id, state%numStateVars)
    if (present(initialValues)) then
        state%stateVars = initialValues
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatInit_StateV

  subroutine MatUpd_StateV(state, newValues, status)
    type(MD_MatPointSta), intent(inout) :: state
    real(wp), intent(in) :: newValues(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    call state%Update(newValues)
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatUpd_StateV

  subroutine GetStateV(state, varId, value, status)
    type(MD_MatPointSta), intent(in) :: state
    integer(i4), intent(in) :: varId
    real(wp), intent(out) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    if (varId >= 1 .and. varId <= state%numStateVars) then
      value = state%stateVars(varId)
    else
      value = 0.0_wp
    end if
    status%status_code = MD_MAT_STATUS_OK
  end subroutine GetStateV

  subroutine SetStateV(state, varId, value, status)
    type(MD_MatPointSta), intent(inout) :: state
    integer(i4), intent(in) :: varId
    real(wp), intent(in) :: value
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    if (varId >= 1 .and. varId <= state%numStateVars) then
      state%stateVarsOld(varId) = state%stateVars(varId)
      state%stateVars(varId) = value
    end if
    status%status_code = MD_MAT_STATUS_OK
  end subroutine SetStateV

  subroutine MatComp_Stress(ntens, strain, properties, stress, status)
    integer(i4), intent(in) :: ntens
    real(wp), intent(in) :: strain(ntens)
    real(wp), intent(in) :: properties(:)
    real(wp), intent(out) :: stress(ntens)
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    stress = 0.0_wp
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatComp_Stress

  subroutine MatInterp_Prop(temperatures, properties, temp, propId, value)
    real(wp), intent(in) :: temperatures(:)
    real(wp), intent(in) :: properties(:,:)
    real(wp), intent(in) :: temp
    integer(i4), intent(in) :: propId
    real(wp), intent(out) :: value
    value = properties(1, propId)
  end subroutine InterpolateProperty

  subroutine MatSet_Ori(orientation, angles, status)
    type(MatOri), intent(inout) :: orientation
    real(wp), intent(in) :: angles(:)
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call MatComp_RotMat(angles(1:3), orientation%rotationMatrix)
    orientation%angles = angles(1:3)
    orientation%isSet = .true.
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatSet_Ori

  subroutine MatXform_Props(properties, rotationMatrix, transformedprop, status)
    real(wp), intent(in) :: properties(:,:)
    real(wp), intent(in) :: rotationMatrix(3,3)
    real(wp), intent(out) :: transformedprop(:,:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    transformedprop = properties
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatXform_Props

  subroutine MatXform_Stress(stress, rotationMatrix, transformedstre, status)
    real(wp), intent(in) :: stress(:)
    real(wp), intent(in) :: rotationMatrix(3,3)
    real(wp), intent(out) :: transformedstre(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    transformedstre = stress
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatXform_Stress

  subroutine MatXform_Strain(strain, rotationMatrix, transformedstra, status)
    real(wp), intent(in) :: strain(:)
    real(wp), intent(in) :: rotationMatrix(3,3)
    real(wp), intent(out) :: transformedstra(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    transformedstra = strain
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatXform_Strain

  ! ===================================================================
  ! Mat Parameter Identification
  ! ===================================================================





  subroutine MatParamId_Init(this, n_params, method, status)
    !! Init Mat parameter identifier
    class(MatParamId), intent(inout) :: this
    integer(i4), intent(in) :: n_params
    integer(i4), intent(in), optional :: method
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    allocate(this%param_lower(n_params))
    allocate(this%param_upper(n_params))
    allocate(this%param_initial(n_params))
    allocate(this%param_identifie(n_params))

    this%param_lower = 0.0_wp
    this%param_upper = 1.0e10_wp
    this%param_initial = 0.0_wp
    this%param_identifie = 0.0_wp

    if (present(method)) then
      this%method = method
    end if

    this%is_initialized = .true.
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatParamId_Init

  subroutine MatParamId_LoadData(this, data_points, test_type, status)
    !! Load experimental data
    class(MatParamId), intent(inout) :: this
    type(ExpDataPt), intent(in) :: data_points(:)
    character(len=*), intent(in), optional :: test_type
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n

    call init_error_status(status)

    n = size(data_points)
    this%exp_data%n_points = n
    allocate(this%exp_data%data(n))
    this%exp_data%data = data_points

    if (present(test_type)) then
      this%exp_data%test_type = test_type
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatParamId_LoadData

  subroutine MatParamId_SetBounds(this, param_lower, param_upper, &
                                   param_initial, status)
    !! Set parameter bounds
    class(MatParamId), intent(inout) :: this
    real(wp), intent(in) :: param_lower(:), param_upper(:)
    real(wp), intent(in), optional :: param_initial(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (size(param_lower) /= size(this%param_lower) .or. &
        size(param_upper) /= size(this%param_upper)) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Parameter bounds size mismatch"
      return
    end if

    this%param_lower = param_lower
    this%param_upper = param_upper

    if (present(param_initial)) then
      if (size(param_initial) == size(this%param_initial)) then
        this%param_initial = param_initial
      end if
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatParamId_SetBounds

  subroutine MatParamId_Identify(this, model_mate_func, status)
    !! Identify parameters
    class(MatParamId), intent(inout) :: this
    interface
      subroutine model_mate_func(params, strains, stresses, status)
        import :: wp, i4, ErrorStatusType
        real(wp), intent(in) :: params(:)
        real(wp), intent(in) :: strains(:)
        real(wp), intent(out) :: stresses(:)
        type(ErrorStatusType), intent(out) :: status
      end subroutine
    end interface
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    ! Use least squares method
    call MatParamId_LSQ(this, model_mate_func, status)

  end subroutine MatParamId_Identify

  subroutine MatParamId_GetParams(this, params, status)
    !! Get identified parameters
    class(MatParamId), intent(in) :: this
    real(wp), intent(out) :: params(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (size(params) /= size(this%param_identifie)) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Parameter array size mismatch"
      return
    end if

    params = this%param_identifie
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatParamId_GetParams

  function MatParamId_GetError(this) result(error)
    !! Get fit error
    class(MatParamId), intent(in) :: this
    real(wp) :: error
    error = this%fit_error
  end function MatParamId_GetError

  subroutine MatParamId_Cleanup(this)
    !! Cleanup Mat parameter identifier
    class(MatParamId), intent(inout) :: this

    if (allocated(this%exp_data%data)) deallocate(this%exp_data%data)
    if (allocated(this%param_lower)) deallocate(this%param_lower)
    if (allocated(this%param_upper)) deallocate(this%param_upper)
    if (allocated(this%param_initial)) deallocate(this%param_initial)
    if (allocated(this%param_identifie)) deallocate(this%param_identifie)

    this%is_initialized = .false.
  end subroutine MatParamId_Clean

  subroutine MatParamId_LSQ(identifier, model_mate_func, status)
    type(MatParamId), intent(inout) :: identifier
    interface
      subroutine model_mate_func(params, strains, stresses, status)
        import :: wp, i4, ErrorStatusType
        real(wp), intent(in) :: params(:)
        real(wp), intent(in) :: strains(:)
        real(wp), intent(out) :: stresses(:)
        type(ErrorStatusType), intent(out) :: status
      end subroutine
    end interface
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, j, k, iter, n_params, n_points
    real(wp), allocatable :: params(:), params_trial(:)
    real(wp), allocatable :: strains(:), stresses_exp(:), stresses_model(:), stresses_trial(:)
    real(wp), allocatable :: residual(:), residual_trial(:)
    real(wp), allocatable :: J(:,:), JTJ(:,:), A(:,:), g(:), delta(:)
    real(wp) :: error, error_new, lambda, lambda_up, lambda_down
    real(wp) :: h, w, small_pivot
    real(wp) :: tmp

    call init_error_status(status)

    n_params = size(identifier%param_initial)
    n_points = identifier%exp_data%n_points

    if (n_params <= 0 .or. n_points <= 0) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MatParamId_LSQ: invalid problem size"
      return
    end if

    allocate(params(n_params), params_trial(n_params))
    allocate(strains(n_points), stresses_exp(n_points))
    allocate(stresses_model(n_points), stresses_trial(n_points))
    allocate(residual(n_points), residual_trial(n_points))
    allocate(J(n_points, n_params), JTJ(n_params, n_params))
    allocate(A(n_params, n_params), g(n_params), delta(n_params))

    do i = 1, n_points
      strains(i) = identifier%exp_data%data(i)%strain
      stresses_exp(i) = identifier%exp_data%data(i)%stress
    end do

    params = identifier%param_initial
    do j = 1, n_params
      if (params(j) < identifier%param_lower(j)) params(j) = identifier%param_lower(j)
      if (params(j) > identifier%param_upper(j)) params(j) = identifier%param_upper(j)
    end do

    lambda = 1.0e-3_wp
    lambda_up = 10.0_wp
    lambda_down = 0.1_wp
    small_pivot = 1.0e-16_wp

    call model_mate_func(params, strains, stresses_model, status)
    if (status%status_code /= MD_MAT_STATUS_OK) then
      deallocate(params, params_trial, strains, stresses_exp, stresses_model, stresses_trial, &
                 residual, residual_trial, J, JTJ, A, g, delta)
      return
    end if

    error = 0.0_wp
    do i = 1, n_points
      w = max(identifier%exp_data%data(i)%itr%weight, 0.0_wp)
      residual(i) = sqrt(w) * (stresses_model(i) - stresses_exp(i))
      error = error + residual(i)**2
    end do
    if (n_points > 0) error = sqrt(error / real(n_points, wp))

    do iter = 1, identifier%max_iterations

      do j = 1, n_params
        params_trial = params
        h = 1.0e-8_wp * max(abs(params(j)), 1.0_wp)
        params_trial(j) = params_trial(j) + h
        if (params_trial(j) < identifier%param_lower(j)) params_trial(j) = identifier%param_lower(j)
        if (params_trial(j) > identifier%param_upper(j)) params_trial(j) = identifier%param_upper(j)

        call model_mate_func(params_trial, strains, stresses_trial, status)
        if (status%status_code /= MD_MAT_STATUS_OK) then
          deallocate(params, params_trial, strains, stresses_exp, stresses_model, stresses_trial, &
                     residual, residual_trial, J, JTJ, A, g, delta)
          return
        end if

        do i = 1, n_points
          w = max(identifier%exp_data%data(i)%itr%weight, 0.0_wp)
          residual_trial(i) = sqrt(w) * (stresses_trial(i) - stresses_exp(i))
          J(i,j) = (residual_trial(i) - residual(i)) / h
        end do
      end do

      JTJ = 0.0_wp
      g = 0.0_wp
      do j = 1, n_params
        do k = 1, n_params
          tmp = 0.0_wp
          do i = 1, n_points
            tmp = tmp + J(i,j) * J(i,k)
          end do
          JTJ(j,k) = tmp
        end do
        tmp = 0.0_wp
        do i = 1, n_points
          tmp = tmp + J(i,j) * residual(i)
        end do
        g(j) = tmp
      end do

      A = JTJ
      do j = 1, n_params
        if (A(j,j) >= 0.0_wp) then
          A(j,j) = A(j,j) * (1.0_wp + lambda)
        else
          A(j,j) = A(j,j) * (1.0_wp + lambda) + lambda
        end if
      end do
      do j = 1, n_params
        g(j) = -g(j)
      end do

      do k = 1, n_params - 1
        if (abs(A(k,k)) < small_pivot) then
          status%status_code = MD_MAT_STATUS_INVALID
          status%message = "MatParamId_LSQ: singular normal matrix"
          deallocate(params, params_trial, strains, stresses_exp, stresses_model, stresses_trial, &
                     residual, residual_trial, J, JTJ, A, g, delta)
          return
        end if
        do i = k + 1, n_params
          tmp = A(i,k) / A(k,k)
          A(i,k) = 0.0_wp
          do j = k + 1, n_params
            A(i,j) = A(i,j) - tmp * A(k,j)
          end do
          g(i) = g(i) - tmp * g(k)
        end do
      end do

      if (abs(A(n_params,n_params)) < small_pivot) then
        status%status_code = MD_MAT_STATUS_INVALID
        status%message = "MatParamId_LSQ: singular normal matrix"
        deallocate(params, params_trial, strains, stresses_exp, stresses_model, stresses_trial, &
                   residual, residual_trial, J, JTJ, A, g, delta)
        return
      end if

      do i = n_params, 1, -1
        tmp = g(i)
        if (i < n_params) then
          do j = i + 1, n_params
            tmp = tmp - A(i,j) * delta(j)
          end do
        end if
        if (abs(A(i,i)) < small_pivot) then
          status%status_code = MD_MAT_STATUS_INVALID
          status%message = "MatParamId_LSQ: singular normal matrix"
          deallocate(params, params_trial, strains, stresses_exp, stresses_model, stresses_trial, &
                     residual, residual_trial, J, JTJ, A, g, delta)
          return
        end if
        delta(i) = tmp / A(i,i)
      end do

      params_trial = params + delta
      do j = 1, n_params
        if (params_trial(j) < identifier%param_lower(j)) params_trial(j) = identifier%param_lower(j)
        if (params_trial(j) > identifier%param_upper(j)) params_trial(j) = identifier%param_upper(j)
      end do

      call model_mate_func(params_trial, strains, stresses_trial, status)
      if (status%status_code /= MD_MAT_STATUS_OK) then
        deallocate(params, params_trial, strains, stresses_exp, stresses_model, stresses_trial, &
                   residual, residual_trial, J, JTJ, A, g, delta)
        return
      end if

      error_new = 0.0_wp
      do i = 1, n_points
        w = max(identifier%exp_data%data(i)%itr%weight, 0.0_wp)
        residual_trial(i) = sqrt(w) * (stresses_trial(i) - stresses_exp(i))
        error_new = error_new + residual_trial(i)**2
      end do
      if (n_points > 0) error_new = sqrt(error_new / real(n_points, wp))

      if (error_new < error) then
        params = params_trial
        stresses_model = stresses_trial
        residual = residual_trial
        error = error_new
        lambda = lambda * lambda_down
        if (error < identifier%tolerance) exit
      else
        lambda = lambda * lambda_up
      end if

    end do

    identifier%param_identifie = params
    identifier%fit_error = error

    deallocate(params, params_trial, strains, stresses_exp, stresses_model, stresses_trial, &
               residual, residual_trial, J, JTJ, A, g, delta)

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatParamId_LSQ

  !=============================================================================
  ! UNIFIED Mat PROPERTY INTERFACE (Phase 1 - Battlefield 3)
  ! - 100+ constitutive model support
  ! - Unified parameter interface for L3_MD ?L4_PH
  ! - Mat category enumeration and model ID allocation
  !=============================================================================

  !> Mat category enumeration (aligned with 9-module structure)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_ELASTIC      = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_PLASTIC      = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_HYPERELASTIC = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_DAMAGE       = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_CREEP        = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_VISCOELASTIC = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_COMPOSITE    = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_MULTIPHYSICS = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CAT_USER_DEFINED = 9_i4

  !> Mat model ID allocation (100+ constitutive models)
  ! Elastic: 1-30 (new) and 101 (legacy/UMAT MD_MAT_ISO_ELAS)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_ISO_ELASTIC   = 1_i4
  ! [REMOVED] MD_MAT_ID_ELASTIC_ISOTROPIC_101 legacy alias (no external refs)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_ORTHO_ELASTIC = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_TRANS_ISO     = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_ANISO_ELASTIC = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_POROUS_ELASTIC= 5_i4

  ! Plastic: 31-100 (Classic, Advanced, Damage, Special)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_VONMISES      = 31_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_HILL          = 32_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_DRUCKER_PRAGER= 33_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_MOHR_COULOMB  = 34_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_JOHNSON_COOK  = 35_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_CHABOCHE      = 36_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_CAM_CLAY      = 37_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_GURSON        = 38_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_CDP           = 39_i4  ! Concrete Damage Plasticity
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_PERZYNA       = 40_i4  ! Viscoplasticity

  ! Hyperelastic: 101-130
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_NEOHOOKEAN    = 101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_MOONEY_RIVLIN = 102_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_OGDEN         = 103_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_YEOH          = 104_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_ARRUDA_BOYCE  = 105_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_VAN_DER_WAALS = 106_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_HYPERFOAM     = 107_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_MARLOW        = 108_i4

  ! Damage: 131-160
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_DUCTILE_DMG   = 131_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_BRITTLE_DMG   = 132_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_PROGRESSIVE_DMG=133_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_FATIGUE_DMG   = 134_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_CREEP_DMG     = 135_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_THERMAL_DMG   = 136_i4

  ! Creep: 161-180
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_NORTON_CREEP  = 161_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_GAROFALO_CREEP= 162_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_TIME_HARDENING= 163_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_STRAIN_HARDENING=164_i4

  ! Viscoelastic: 181-200
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_PRONY         = 181_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_MAXWELL       = 182_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_KELVIN        = 183_i4

  ! Composite: 201-220
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_LAMINATE      = 201_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_FIBER_REINF   = 202_i4

  ! MultiPhysics: 221-250
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_VISC_DAMAGE   = 221_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_THERMO_VISC   = 222_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_NANO_MAT      = 223_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_SMART_MAT     = 224_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_BIO_MAT       = 225_i4

  ! User-Defined: 251-300
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_UMAT          = 251_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_VUMAT         = 252_i4

  !> Mat Property Definition - Unified interface for 100+ constitutive models

  ! Public interfaces for unified Mat property operations
  PUBLIC :: UF_MatProp_Init, UF_MatProp_Valid, UF_MatProp_GetInfo
  PUBLIC :: UF_MatProp_QueryByName, UF_MatProp_ListByCategory


    ! ????????????????????????????????????????????????????????????
    ! Procedures from: MD_MAT_DISPATCH
    ! ????????????????????????????????????????????????????????????

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Mat_Eval_Dispatch
  ! Purpose: Top-level struct-only material dispatch.
  !   Interface: (material_id, nprops, props, ctx, algo, status)
  !   ??no UMAT scalar arguments exposed here.
  !   Priority order:
  !   1. L4_PH bridge (structured Desc/Algo/Ctx/State interface)
  !   2. Range-based routing: Elastic / Plastic / Hyper / Visco / Damage / Creep
  !   3. Composite (ID 121-139)
  !   4. Unknown ID ??MD_MAT_STATUS_NOT_FOUND
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Mat_Eval_Dispatch(material_id, nprops, props, ctx, algo, status)

    INTEGER(i4),           INTENT(IN)    :: material_id
    INTEGER(i4),           INTENT(IN)    :: nprops
    REAL(wp),              INTENT(IN)    :: props(:)
    TYPE(MatEval_Ctx),     INTENT(INOUT) :: ctx
    TYPE(MatAlgo_Algo),    INTENT(IN)    :: algo
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    TYPE(PlastModels_Desc) :: plast_desc
    INTEGER(i4) :: np

    CALL init_error_status(status)
    CALL MD_Mat_InitReg(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! -------------------------------------------------------------------------
    ! 1. L4_PH bridge ??structured interface takes priority
    ! -------------------------------------------------------------------------
    ! -------------------------------------------------------------------------
    ! 2. Range-based dispatch ??each domain's Eval_Dispatch takes (mat_id, ..., ctx, algo)
    ! -------------------------------------------------------------------------
    IF (material_id >= MD_MAT_ID_RANGE_PLAST_S .AND. material_id <= MD_MAT_ID_RANGE_PLAST_E) THEN
      np = MIN(nprops, SIZE(plast_desc%props, KIND=i4))
      plast_desc%nprops = np
      IF (np > 0) plast_desc%props(1:np) = props(1:np)
      BLOCK
        TYPE(UF_Plastic_Eval_Dispatch_Arg) :: eval_arg
        eval_arg%material_id = material_id
        eval_arg%plm_in = plast_desc
        eval_arg%ctx = ctx
        eval_arg%algo = algo
        CALL init_error_status(eval_arg%status)
        CALL UF_Plastic_Eval_Dispatch(eval_arg)
        ctx = eval_arg%ctx
        status = eval_arg%status
      END BLOCK

    ELSE IF (material_id >= MD_MAT_ID_RANGE_ELAS_S .AND. material_id <= MD_MAT_ID_RANGE_ELAS_E) THEN
      CALL UF_Elastic_Eval_Dispatch(material_id, nprops, props, ctx, algo, status)

    ELSE IF (material_id >= MD_MAT_ID_RANGE_HYP_ST .AND. material_id <= MD_MAT_ID_RANGE_HYP_EN) THEN
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message = 'Hyperelastic dispatch not implemented'

    ELSE IF (material_id >= MD_MAT_ID_RANGE_VISC_S .AND. material_id <= MD_MAT_ID_RANGE_VISC_E) THEN
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message = 'Viscoelastic dispatch not implemented'

    ELSE IF (material_id >= MD_MAT_ID_RANGE_DMG_S .AND. material_id <= MD_MAT_ID_RANGE_DMG_E) THEN
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message = 'Damage dispatch not implemented'

    ELSE IF (material_id >= MD_MAT_ID_RANGE_CREEP_S .AND. material_id <= MD_MAT_ID_RANGE_CREEP_E) THEN
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message = 'Creep dispatch not implemented'

    ELSE IF ((material_id >= 121_i4 .AND. material_id <= 129_i4) .OR. &
             (material_id >= 130_i4 .AND. material_id <= 139_i4)) THEN
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      status%message = 'Composite dispatch not implemented'

    ELSE
      status%status_code = MD_MAT_STATUS_NOT_FOUND
      WRITE(status%message, '(A,I0)') 'Unknown material ID: ', material_id
    END IF

  END SUBROUTINE UF_Mat_Eval_Dispatch

  !---------------------------------------------------------------------------
  ! UF_Mat_Eval_Dispatch_FromDesc — W1
  ! Resolve **material_id** / **nprops** from **MD_Mat_Desc** (same band defaults as
  ! **MD_Mat_ValidatePropsForPopulate**), then delegate to **UF_Mat_Eval_Dispatch**.
  !---------------------------------------------------------------------------
  SUBROUTINE UF_Mat_Eval_Dispatch_FromDesc(desc, ctx, algo, status)
    TYPE(MD_Mat_Desc), INTENT(INOUT) :: desc
    TYPE(MatEval_Ctx), INTENT(INOUT) :: ctx
    TYPE(MatAlgo_Algo), INTENT(IN) :: algo
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: material_id, eff_class, np, nprops_eff

    CALL init_error_status(status)
    CALL MD_Mat_Desc_SyncDeprecatedFlat(desc)

    IF (.NOT. ALLOCATED(desc%props)) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'UF_Mat_Eval_Dispatch_FromDesc: desc%props not allocated'
      RETURN
    END IF

    eff_class = desc%cfg%class_id
    IF (eff_class == 0_i4) eff_class = desc%class_id
    material_id = desc%cfg%id
    IF (material_id <= 0_i4) material_id = desc%id

    SELECT CASE (eff_class)
    CASE (MD_MAT_CATEGORY_EL)
      IF (material_id < MD_MAT_ID_RANGE_ELAS_S .OR. material_id > MD_MAT_ID_RANGE_ELAS_E) &
        material_id = MD_MAT_ID_RANGE_ELAS_S
    CASE (MD_MAT_CATEGORY_PL)
      IF (material_id < MD_MAT_ID_RANGE_PLAST_S .OR. material_id > MD_MAT_ID_RANGE_PLAST_E) &
        material_id = MD_MAT_VONMISES_MAT_ID
    CASE (MD_MAT_CATEGORY_HY)
      IF (material_id < MD_MAT_ID_RANGE_HYP_ST .OR. material_id > MD_MAT_ID_RANGE_HYP_EN) material_id = 311_i4
    CASE (MD_MAT_CATEGORY_VI)
      IF (material_id < MD_MAT_ID_RANGE_VISC_S .OR. material_id > MD_MAT_ID_RANGE_VISC_E) material_id = MD_MAT_ID_RANGE_VISC_S
    CASE (MD_MAT_CATEGORY_CR)
      IF (material_id < MD_MAT_ID_RANGE_CREEP_S .OR. material_id > MD_MAT_ID_RANGE_CREEP_E) material_id = 601_i4
    CASE (MD_MAT_CATEGORY_DA)
      IF (material_id < MD_MAT_ID_RANGE_DMG_S .OR. material_id > MD_MAT_ID_RANGE_DMG_E) material_id = 501_i4
    CASE DEFAULT
      CONTINUE
    END SELECT

    nprops_eff = desc%pop%nProps
    IF (nprops_eff <= 0_i4) nprops_eff = desc%nProps
    IF (nprops_eff <= 0_i4) nprops_eff = INT(SIZE(desc%props), KIND=i4)
    np = MIN(nprops_eff, INT(SIZE(desc%props), KIND=i4))
    IF (np < 1_i4) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'UF_Mat_Eval_Dispatch_FromDesc: no property values'
      RETURN
    END IF

    CALL UF_Mat_Eval_Dispatch(material_id, np, desc%props, ctx, algo, status)
  END SUBROUTINE UF_Mat_Eval_Dispatch_FromDesc

  !-----------------------------------------------------------------------------
  ! Subroutine: UF_Mat_UMAT_Dispatch  [PRIVATE]
  ! Purpose: ABAQUS ABI boundary adapter ??packs flat UMAT scalars into ctx/algo,
  !   delegates to UF_Mat_Eval_Dispatch (struct-only), then unpacks results.
  !   NOT a UFC internal interface; retained only for ABAQUS/legacy ABI callers.
  !   stress replaces stress per Material domain naming convention.
  !-----------------------------------------------------------------------------
  SUBROUTINE UF_Mat_UMAT_Dispatch(material_id, stress, statev, ddsdde,   &
                                   sse, spd, scd, rpl, ddsddt, drplde,    &
                                   drpldt, stran, dstran, time, dtime,    &
                                   temp, dtemp, predef, dpred,             &
                                   ndir, nshr, nstatev, nprops,            &
                                   props, ndim, kstep, kinc, status)

    INTEGER(i4),          INTENT(IN)    :: material_id
    REAL(wp),             INTENT(INOUT) :: stress(6)
    REAL(wp),             INTENT(INOUT) :: statev(:)
    REAL(wp),             INTENT(OUT)   :: ddsdde(6,6)
    REAL(wp),             INTENT(OUT)   :: sse, spd, scd, rpl
    REAL(wp),             INTENT(OUT)   :: ddsddt(6), drplde(6), drpldt
    REAL(wp),             INTENT(IN)    :: stran(6), dstran(6)
    REAL(wp),             INTENT(IN)    :: time(2), dtime
    REAL(wp),             INTENT(IN)    :: temp, dtemp
    REAL(wp),             INTENT(IN)    :: predef(*), dpred(*)
    INTEGER(i4),          INTENT(IN)    :: ndir, nshr, nstatev, nprops
    INTEGER(i4),          INTENT(IN)    :: ndim, kstep, kinc
    REAL(wp),             INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),INTENT(OUT)   :: status

    TYPE(MatEval_Ctx)  :: ctx
    TYPE(MatAlgo_Algo) :: algo

    CALL init_error_status(status)

    ! Pack ctx
    ctx%ndi    = ndir
    ctx%nshr   = nshr
    ctx%ntens  = ndir + nshr
    ctx%cfg%ndim   = ndim
    ctx%nstatv = nstatev
    ctx%stress(1:6)  = stress(1:6)
    ctx%stran(1:6)   = stran(1:6)
    ctx%dstran(1:6)  = dstran(1:6)
    ctx%time         = time
    ctx%dtime        = dtime
    ctx%temp         = temp
    ctx%dtemp        = dtemp
    IF (nstatev > 0) ctx%statev(1:MIN(nstatev,SIZE(ctx%statev))) = &
                     statev(1:MIN(nstatev,SIZE(ctx%statev)))

    ! Pack algo
    algo%kstep = kstep
    algo%kinc  = kinc

    ! Delegate to struct-only Eval_Dispatch (no member names cross this boundary)
    CALL UF_Mat_Eval_Dispatch(material_id, nprops, props, ctx, algo, status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! Unpack ctx
    stress(1:6)        = ctx%stress(1:6)
    ddsdde(1:6,1:6)    = ctx%ddsdde(1:6,1:6)
    sse                = ctx%sse
    spd                = ctx%spd
    scd                = ctx%scd
    rpl                = ctx%rpl
    drpldt             = ctx%drpldt
    IF (nstatev > 0) statev(1:MIN(nstatev,SIZE(ctx%statev))) = &
                     ctx%statev(1:MIN(nstatev,SIZE(ctx%statev)))

  END SUBROUTINE UF_Mat_UMAT_Dispatch


    ! ????????????????????????????????????????????????????????????
    ! Procedures from: MD_MAT_EVALUATION
    ! ????????????????????????????????????????????????????????????

  !=============================================================================
  ! PROCEDURES FROM MD_Material_Core
  !=============================================================================

  !=============================================================================
  ! EvalMaterial_Ctx - Unified Mat Evaluation Interface using Ctx
  !=============================================================================
  subroutine MatEval_Ctx(ctx)
    type(MD_Material_Ctx), intent(inout) :: ctx

    type(ErrorStatusType) :: validate_status

    ! Valid Ctx
    call init_error_status(validate_status)
    if (.not. ctx%Valid()) then
      ctx%success = .false.
      validate_status%status_code = MD_MAT_STATUS_INVALID
      validate_status%message = "EvalMaterial_Ctx: Ctx validation failed"
      call ctx%SetStatus(validate_status)
      return
    end if

    if (.not. associated(ctx%ctx)) then
      validate_status%status_code = MD_MAT_STATUS_INVALID
      validate_status%message = "Mat Ctx not provided"
      call ctx%SetStatus(validate_status)
      ctx%success = .false.
      return
    end if

    if (ctx%ctx%material_id <= 0) then
      validate_status%status_code = MD_MAT_STATUS_INVALID
      validate_status%message = "Invalid Mat ID"
      call ctx%SetStatus(validate_status)
      if (associated(ctx%res)) then
        ctx%res%failed = .true.
      end if
      ctx%success = .false.
      return
    end if

    if (.not. associated(ctx%res)) then
      validate_status%status_code = MD_MAT_STATUS_INVALID
      validate_status%message = "Mat result not provided"
      call ctx%SetStatus(validate_status)
      ctx%success = .false.
      return
    end if

    call ctx%res%Init(ctx%ctx%kin%meta%ntens, ctx%ctx%nstatev, ctx%GetStatus())
    if (ctx%IsError()) return

    call UniUMAT(ctx%ctx%kin, ctx%ctx%desc, ctx%res, ctx%GetStatus())
    if (ctx%IsError()) return

    ctx%success = ctx%IsOK()
  end subroutine MatEval_Ctx

  !=============================================================================
  ! EvalMaterial - DEPRECATED: Use EvalMaterial_Ctx instead
  !=============================================================================
  subroutine MatEval(ctx, res, status)
    type(MatCtxLegacy),           intent(in), target    :: ctx
    type(MatRes),           intent(inout), target :: res
    type(ErrorStatusType),  intent(out)   :: status

    type(MD_Material_Ctx) :: mat_ctx

    ! Bind Ctx
    call mat_ctx%Bind(ctx=ctx, res=res)

    ! Call unified interface
    call MatEval_Ctx(mat_ctx)

    ! Extract status
    status = mat_ctx%GetStatus()
  end subroutine MatEval

  !=============================================================================
  ! UniUMAT - Unified UMAT Interface
  !=============================================================================
  !! Unified UMAT interface that dispatches to appropriate Mat model
  !! based on Mat ID from desc
  !!
  !! This function:
  !!   1. Extracts Mat ID from desc
  !!   2. Prepares UMAT input arrays from kin and desc
  !!   3. Calls g_matlib%MD_MAT_UMAT_Dispatch to invoke appropriate Mat model
  !!   4. Copies results back to res
  !!
  subroutine UniUMAT(kin, desc, res, status)
    type(UF_Kinematics),      intent(in)    :: kin
    type(Desc_MaterialModel),  intent(in)    :: desc
    type(MatRes),              intent(inout) :: res
    type(ErrorStatusType),     intent(out)   :: status

    integer(i4) :: material_id, ntens, ndim, ndir, nshr, nstatev, nprops
    integer(i4) :: i, j
    real(wp) :: stress(6), statev_array(100), ddsdde(6,6)
    real(wp) :: stran(6), dstran(6)
    real(wp) :: sse, spd, scd, rpl
    real(wp) :: ddsddt(6), drplde(6), drpldt
    real(wp) :: time(2), dtime, temp, dtemp
    real(wp) :: predef(1), dpred(1)
    real(wp), allocatable :: props_array(:)

    call init_error_status(status)

    if (.not. allocated(res%stress)) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Mat result not initialized"
      return
    end if

    ! Extract Mat ID from desc
    material_id = desc%material_id
    if (material_id == 0_i4) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Invalid Mat ID in desc"
      return
    end if

    ! Extract dimensions from kinematics
    ntens = kin%meta%ntens
    ndim = kin%meta%cfg%ndim
    ndir = ndim
    nshr = ntens - ndir

    ! Extract nstatev and nprops from desc
    nstatev = desc%nstatev
    nprops = desc%nprops

    ! Init arrays
    stress = 0.0_wp
    statev_array = 0.0_wp
    ddsdde = 0.0_wp
    stran = 0.0_wp
    dstran = 0.0_wp
    sse = 0.0_wp
    spd = 0.0_wp
    scd = 0.0_wp
    rpl = 0.0_wp
    ddsddt = 0.0_wp
    drplde = 0.0_wp
    drpldt = 0.0_wp

    ! Extract strain from kinematics
    if (allocated(kin%eps)) then
      do i = 1, min(ntens, 6)
        stran(i) = kin%eps(i)
      end do
    end if
    if (allocated(kin%deps)) then
      do i = 1, min(ntens, 6)
        dstran(i) = kin%deps(i)
      end do
    end if

    ! Extract stress from res (previous step)
    if (allocated(res%stress)) then
      do i = 1, min(ntens, 6)
        stress(i) = res%stress(i)
      end do
    end if

    ! Extract state variables from desc (if available)
    if (allocated(desc%statev) .and. nstatev > 0) then
      do i = 1, min(nstatev, 100)
        statev_array(i) = desc%statev(i)
      end do
    end if

    ! Extract Mat properties from desc
    allocate(props_array(max(nprops, 1)))
    props_array = 0.0_wp
    if (allocated(desc%props) .and. nprops > 0) then
      do i = 1, min(nprops, size(props_array))
        props_array(i) = desc%props(i)
      end do
    end if

    ! Set time and temperature
    time(1) = kin%meta%time
    time(2) = kin%meta%time_old
    dtime = max(time(1) - time(2), 1.0e-12_wp)
    temp = 0.0_wp
    dtemp = 0.0_wp

    ! Init g_matlib if not already initialized
    if (.not. g_matlib%initialized) then
      call g_matlib%Init(status=status)
      if (status%status_code /= MD_MAT_STATUS_OK) then
        deallocate(props_array)
        return
      end if
    end if

    ! Call Mat library dispatcher
    call g_matlib%MD_MAT_UMAT_Dispatch(material_id, stress, statev_array, ddsdde, &
                                sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                stran, dstran, time, dtime, temp, dtemp, &
                                predef, dpred, ndir, nshr, nstatev, nprops, &
                                props_array, ndim, 1, 1, status)

    if (status%status_code /= MD_MAT_STATUS_OK) then
      deallocate(props_array)
      return
    end if

    ! Copy results back to res
    do i = 1, min(ntens, 6)
      res%stress(i) = stress(i)
    end do

    if (allocated(res%tangent)) then
      do i = 1, min(ntens, 6)
        do j = 1, min(ntens, 6)
          res%tangent(i, j) = ddsdde(i, j)
        end do
      end do
    end if

    ! Update state variables in desc (if allocated)
    if (allocated(desc%statev) .and. nstatev > 0) then
      do i = 1, min(nstatev, 100)
        desc%statev(i) = statev_array(i)
      end do
    end if

    deallocate(props_array)
    status%status_code = MD_MAT_STATUS_OK
  end subroutine UniUMAT


  !=============================================================================
  ! EvalMaterial_Plastic - General plasticity framework
  !=============================================================================
  subroutine MatEval_Plast(ctx, res, status)
    type(MatCtxLegacy),           intent(in)    :: ctx
    type(MatRes),           intent(inout) :: res
    type(ErrorStatusType),  intent(out)   :: status

    if (.not. associated(ctx%props)) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Mat properties not set"
      res%failed = .true.
      return
    end if

    if (size(ctx%props) >= 8) then
      select case (int(ctx%props(8)))
      case (1)
        call MatEval_Mises(ctx, res, status)
      case (2)
        call MatEval_DP(ctx, res, status)
      case default
        call MatEval_Mises(ctx, res, status)
      end select
    else
      call MatEval_Mises(ctx, res, status)
    end if
  end subroutine MatEval_Plast

  !=============================================================================
  ! EvalMaterial_Plastic_Mises - Mises J2 plasticity
  !=============================================================================
  subroutine MatEval_Mises(ctx, res, status)
    type(MatCtxLegacy),           intent(in)    :: ctx
    type(MatRes),           intent(inout) :: res
    type(ErrorStatusType),  intent(out)   :: status

    real(wp) :: E, nu, sy0, Hiso, Hkin, rinf, beta
    real(wp) :: G, K, twog, hk, hi, s23, one3, two3
    real(wp) :: r0, expb, rbar
    real(wp) :: stress_old(6), ep_old(6), alp_old(6)
    real(wp) :: stress_trial(6), stress_dev(6), ep(6), alp(6), xi(6)
    real(wp) :: dlam, phi, dphi, theta, press, von_mises, expbl
    integer(i4) :: ntens, i, iter
    logical :: yield, conv

    call init_error_status(status)

    if (.not. associated(ctx%props)) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Mat properties not set"
      res%failed = .true.
      return
    end if

    E = ctx%props(1)
    nu = ctx%props(2)
    sy0 = ctx%props(3)
    Hiso = 0.0_wp
    Hkin = 0.0_wp
    rinf = sy0
    beta = 0.0_wp

    if (size(ctx%props) >= 4) Hiso = ctx%props(4)
    if (size(ctx%props) >= 5) Hkin = ctx%props(5)
    if (size(ctx%props) >= 6) rinf = ctx%props(6)
    if (size(ctx%props) >= 7) beta = ctx%props(7)

    G = E / (2.0_wp * (1.0_wp + nu))
    K = E / (3.0_wp * (1.0_wp - 2.0_wp * nu))

    one3 = 1.0_wp / 3.0_wp
    two3 = 2.0_wp / 3.0_wp
    s23 = sqrt(two3)
    twog = 2.0_wp * G

    hk = Hkin
    hi = Hiso
    r0 = s23 * sy0

    ntens = ctx%kin%meta%ntens

    if (associated(ctx%statev)) then
      stress_old(1:ntens) = ctx%statev(1:ntens)
      if (size(ctx%statev) >= ntens*2) then
        ep_old(1:ntens) = ctx%statev(ntens+1:ntens*2)
      end if
      if (size(ctx%statev) >= ntens*3) then
        alp_old(1:ntens) = ctx%statev(ntens*2+1:ntens*3)
      end if
    end if

    do i = 1, ntens
      stress_trial(i) = stress_old(i) + twog * (ctx%kin%deps(i) - ep_old(i))
    end do

    press = (stress_trial(1) + stress_trial(2) + stress_trial(3)) * one3
    do i = 1, 3
      stress_dev(i) = stress_trial(i) - press
    end do
    do i = 4, ntens
      stress_dev(i) = stress_trial(i) * 0.5_wp
    end do

    do i = 1, ntens
      xi(i) = stress_dev(i) - alp_old(i)
    end do

    von_mises = sqrt(1.5_wp * dot_product(xi, xi))

    if (beta > 0.0_wp) then
      theta = dot_product(ep_old, ep_old)
      expb = exp(-beta * theta)
      rbar = r0 + (rinf - r0) * (1.0_wp - expb)
    else
      rbar = r0
    end if

    phi = von_mises - rbar
    yield = (phi > 0.0_wp)

    if (.not. yield) then
      res%stress(1:ntens) = stress_trial(1:ntens)
      res%tangent(:,:) = 0.0_wp
      do i = 1, 3
        res%tangent(i,i) = twog
      end do
      do i = 4, ntens
        res%tangent(i,i) = G
      end do
      res%failed = .false.
      res%is_plastic = .false.
    else
      dlam = phi / (3.0_wp * G + hk + hi)

      conv = .false.
      do iter = 1, 20
        if (beta > 0.0_wp) then
          theta = dot_product(ep_old, ep_old) + 1.5_wp * dlam * dlam
          expbl = exp(-beta * theta)
          rbar = r0 + (rinf - r0) * (1.0_wp - expbl)
        end if

        do i = 1, ntens
          alp(i) = alp_old(i) + hk * dlam * xi(i) / von_mises
        end do

        do i = 1, ntens
          stress_dev(i) = xi(i) - 3.0_wp * G * dlam * xi(i) / von_mises
        end do

        von_mises = sqrt(1.5_wp * dot_product(stress_dev, stress_dev))

        phi = von_mises - rbar
        if (abs(phi) < 1.0e-10_wp) then
          conv = .true.
          exit
        end if

        dphi = -3.0_wp * G - hk - hi
        if (beta > 0.0_wp) then
          dphi = dphi - beta * rinf * expbl
        end if

        dlam = dlam - phi / dphi
        if (dlam < 0.0_wp) dlam = 0.0_wp
      end do

      if (.not. conv) then
        res%failed = .true.
        res%suggest_cutback = .true.
        status%status_code = MD_MAT_STATUS_INVALID
        status%message = "Mises plasticity: Newton iteration did not converge"
        return
      end if

      do i = 1, 3
        res%stress(i) = stress_dev(i) + press
      end do
      do i = 4, ntens
        res%stress(i) = 2.0_wp * stress_dev(i)
      end do

      do i = 1, ntens
        ep(i) = ep_old(i) + dlam * xi(i) / von_mises
      end do

      if (allocated(res%statev)) then
        res%statev(1:ntens) = res%stress(1:ntens)
        if (size(res%statev) >= ntens*2) then
          res%statev(ntens+1:ntens*2) = ep(1:ntens)
        end if
        if (size(res%statev) >= ntens*3) then
          res%statev(ntens*2+1:ntens*3) = alp(1:ntens)
        end if
      end if

      res%tangent(:,:) = 0.0_wp
      do i = 1, 3
        res%tangent(i,i) = twog * (1.0_wp - 3.0_wp * G * dlam / von_mises)
      end do
      do i = 4, ntens
        res%tangent(i,i) = G * (1.0_wp - 3.0_wp * G * dlam / von_mises)
      end do

      res%failed = .false.
      res%is_plastic = .true.
      res%pnewdt_factor = 1.0_wp
    end if

    res%sse = 0.5_wp * dot_product(res%stress, ctx%kin%deps)
    res%spd = 0.0_wp
    res%scd = 0.0_wp
    res%rpl = 0.0_wp

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatEval_Mises

  !=============================================================================
  ! EvalMaterial_Plastic_DruckerPrager - Drucker-Prager plasticity
  !=============================================================================
  subroutine MatEval_DP(ctx, res, status)
    type(MatCtxLegacy),           intent(in)    :: ctx
    type(MatRes),           intent(inout) :: res
    type(ErrorStatusType),  intent(out)   :: status

    integer(i4) :: material_id, ntens, ndir, nshr, nstatev, nprops, ndim
    real(wp) :: stress(6), statev_array(100), ddsdde(6,6)
    real(wp) :: sse, spd, scd, rpl, ddsddt(6), drplde(6), drpldt
    real(wp) :: stran(6), dstran(6), time(2), dtime, temp, dtemp
    real(wp) :: predef(1), dpred(1)
    integer(i4) :: i

    call init_error_status(status)

    ! Init g_matlib if not already initialized
    if (.not. g_matlib%initialized) then
      call g_matlib%Init(status=status)
      if (status%status_code /= MD_MAT_STATUS_OK) return
    end if

    ! Determine Mat ID (default: von Mises plasticity; avoid implicit DP@202)
    material_id = ctx%material_id
    if (material_id == 0_i4) then
      material_id = MD_MAT_VONMISES_MAT_ID
    end if

    ! Extract dimensions
    ntens = ctx%kin%meta%ntens
    ndim = ctx%kin%meta%cfg%ndim
    ndir = ndim
    nshr = ntens - ndir
    nstatev = ctx%nstatev
    nprops = ctx%nprops

    ! Init arrays
    stress = 0.0_wp
    statev_array = 0.0_wp
    ddsdde = 0.0_wp
    stran = 0.0_wp
    dstran = 0.0_wp

    ! Extract strain from kinematics
    if (allocated(ctx%kin%eps)) then
      stran(1:ntens) = ctx%kin%eps(1:ntens)
    end if
    if (allocated(ctx%kin%deps)) then
      dstran(1:ntens) = ctx%kin%deps(1:ntens)
    end if

    ! Extract stress from statev (if available)
    if (associated(ctx%statev) .and. size(ctx%statev) >= ntens) then
      stress(1:ntens) = ctx%statev(1:ntens)
    end if

    ! Extract state variables
    if (associated(ctx%statev) .and. nstatev > 0) then
      do i = 1, min(nstatev, 100)
        statev_array(i) = ctx%statev(i)
      end do
    end if

    ! Set time and temperature
    time(1) = ctx%kin%meta%time
    time(2) = ctx%kin%meta%time_old
    dtime = time(1) - time(2)
    temp = 0.0_wp
    dtemp = 0.0_wp

    ! Call Reg's MD_MAT_UMAT_Dispatch
    call g_matlib%MD_MAT_UMAT_Dispatch(material_id, stress, statev_array, ddsdde, &
                                sse, spd, scd, rpl, ddsddt, drplde, drpldt, &
                                stran, dstran, time, dtime, temp, dtemp, &
                                predef, dpred, ndir, nshr, nstatev, nprops, &
                                ctx%props, ndim, 1, 1, status)
    if (status%status_code /= MD_MAT_STATUS_OK) then
      res%failed = .true.
      return
    end if

    ! Copy results back to res
    if (.not. allocated(res%stress)) allocate(res%stress(ntens))
    res%stress(1:ntens) = stress(1:ntens)

    if (.not. allocated(res%tangent)) allocate(res%tangent(ntens, ntens))
    res%tangent(1:ntens, 1:ntens) = ddsdde(1:ntens, 1:ntens)

    if (.not. allocated(res%statev)) allocate(res%statev(nstatev))
    res%statev(1:nstatev) = statev_array(1:nstatev)

    res%sse = sse
    res%spd = spd
    res%scd = scd
    res%rpl = rpl
    res%failed = .false.
    res%is_plastic = .true.

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatEval_DP


    ! ????????????????????????????????????????????????????????????
    ! Procedures from: MD_MAT_UNIF_API
    ! ????????????????????????????????????????????????????????????

  FUNCTION MD_Mat_GetCategoryFromName(category_name) RESULT(category)
    !! Get category constant from category name

    CHARACTER(LEN=*), INTENT(IN) :: category_name
    INTEGER(i4) :: category

    CHARACTER(LEN=32) :: name_upper

    name_upper = category_name
    CALL UF_ToUpper(name_upper)

    SELECT CASE (TRIM(name_upper))
    CASE ("ELASTIC")
      category = MD_MAT_CATEGORY_ELAS
    CASE ("PLASTIC")
      category = MD_MAT_CATEGORY_PLASTI
    CASE ("HYPERELASTIC")
      category = MD_MAT_CATEGORY_HYP
    CASE ("VISCOELASTIC")
      category = MD_MAT_CATEGORY_VISC
    CASE ("DAMAGE")
      category = MD_MAT_CATEGORY_DAMAGE
    CASE ("CREEP")
      category = MD_MAT_CATEGORY_CREEP
    CASE ("COMPOSITE")
      category = MD_MAT_CATEGORY_COMP
    CASE ("SPECIAL")
      category = MD_MAT_CATEGORY_SPECIA
    CASE DEFAULT
      category = 0
    END SELECT

  END FUNCTION MD_Mat_GetCategoryFromName

  SUBROUTINE MD_Mat_InitReg(status)
    !! Init the unified Mat registry
    !! This registers all built-in materials from all categories

    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i
    TYPE(ErrorStatusType) :: cat_status

    CALL init_error_status(status)

    IF (registry_initialized) THEN
      status%status_code = MD_MAT_STATUS_OK
      RETURN
    END IF

    ! Allocate registry
    IF (.NOT. ALLOCATED(unified_registr)) THEN
      ALLOCATE(unified_registr(MD_MAT_REG_MAX_MATS))
    END IF

    ! Init entries
    DO i = 1, MD_MAT_REG_MAX_MATS
      unified_registr(i)%material_id = 0
      unified_registr(i)%name = ""
      unified_registr(i)%category = 0
      unified_registr(i)%category_name = ""
      unified_registr(i)%nprops_min = 0
      unified_registr(i)%nprops_max = 0
      unified_registr(i)%nstatev_min = 0
      unified_registr(i)%nstatev_max = 0
      unified_registr(i)%available = .FALSE.
    END DO

    ! Init category-specific registries
    CALL UF_Elastic_RegAllMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    CALL UF_Plastic_RegAllMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    CALL UF_Hyp_RegAllMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    CALL UF_Creep_RegAllMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! Init Viscoelastic Interface
    CALL UF_Viscoelastic_InitReg(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! Reg all viscoelastic materials
    CALL UF_Viscoelastic_RegAllMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! Init Damage Interface
    CALL UF_Damage_InitializeRegistry(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! Reg all damage materials
    CALL UF_Dmg_RegAllMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! Init Composite Interface
    CALL UF_Comp_InitReg(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! Reg all composite materials
    CALL UF_Comp_RegAllMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    ! Reg materials from all categories
    CALL UF_Mat_RegBuiltInMats(status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    registry_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE MD_Mat_InitReg

  SUBROUTINE MD_Mat_Reg_Int(material_id, name, category, &
                                           nprops_min, nprops_max, &
                                           nstatev_min, nstatev_max, status)
    !! Reg a Mat in the unified registry (internal)

    INTEGER(i4), INTENT(IN) :: material_id
    CHARACTER(LEN=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(IN) :: category
    INTEGER(i4), INTENT(IN) :: nprops_min, nprops_max
    INTEGER(i4), INTENT(IN) :: nstatev_min, nstatev_max
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: idx, i

    CALL init_error_status(status)

    ! Init registry if needed
    IF (.NOT. registry_initialized) THEN
      CALL MD_Mat_InitReg(status)
      IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    END IF

    ! Check if already registered
    DO i = 1, n_registered
      IF (unified_registr(i)%material_id == material_id) THEN
        status%status_code = MD_MAT_STATUS_INVALID
        status%message = "Mat ID already registered: " // CHAR(material_id)
        RETURN
      END IF
    END DO

    ! Check registry capacity
    IF (n_registered >= MD_MAT_REG_MAX_MATS) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Unified Mat registry full"
      RETURN
    END IF

    ! Valid category
    IF (category < 1 .OR. category > 8) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Invalid Mat category"
      RETURN
    END IF

    ! Add to registry
    idx = n_registered + 1
    unified_registr(idx)%material_id = material_id
    unified_registr(idx)%name = name
    unified_registr(idx)%category = category
    unified_registr(idx)%category_name = MD_MAT_CATEGORY_NAMES(category)
    unified_registr(idx)%nprops_min = nprops_min
    unified_registr(idx)%nprops_max = nprops_max
    unified_registr(idx)%nstatev_min = nstatev_min
    unified_registr(idx)%nstatev_max = nstatev_max
    unified_registr(idx)%available = .TRUE.

    n_registered = n_registered + 1
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE MD_Mat_Reg_Int

  SUBROUTINE MD_Mat_ValidParameterConsist(props, nprops, &
                                                       result, status, &
                                                       material_type)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: material_type

    REAL(wp) :: E, G, nu
    REAL(wp), PARAMETER :: TOL_CONSISTENCY = 1.0e-6_wp

    CALL init_error_status(status)
    IF (nprops >= 2) THEN
      IF (PRESENT(material_type)) THEN
        IF (material_type >= 101_i4 .AND. material_type <= 199_i4) THEN
          IF (nprops >= 2 .AND. props(1) > TOL_CONSISTENCY .AND. props(2) > TOL_CONSISTENCY) THEN
            E = props(1)
            G = props(2)
            IF (E <= 2.0_wp * G) THEN
              CALL UF_AddValidationWarning(result, &
                "Young's modulus E should be > 2*G for isotropic materials")
            END IF
          END IF
          IF (nprops >= 3 .AND. props(1) > TOL_CONSISTENCY .AND. props(2) > TOL_CONSISTENCY) THEN
            E = props(1)
            G = props(2)
            nu = props(3)
            IF (ABS(nu - (E / (2.0_wp * G) - 1.0_wp)) > 0.1_wp) THEN
              CALL UF_AddValidationWarning(result, &
                "Poisson's ratio may be inconsistent with E and G")
            END IF
          END IF
        END IF
      ELSE
        IF (props(1) > TOL_CONSISTENCY .AND. props(2) > TOL_CONSISTENCY) THEN
          IF (props(1) <= 2.0_wp * props(2)) THEN
            CALL UF_AddValidationWarning(result, &
              "First parameter should be > 2*second parameter for typical elastic materials")
          END IF
        END IF
      END IF
    END IF
    IF (PRESENT(material_type)) THEN
      IF (material_type >= 121_i4 .AND. material_type <= 139_i4) THEN
        IF (nprops >= 2 .AND. (props(1) < 0.0_wp .OR. props(1) > 1.0_wp)) THEN
          CALL UF_AddValidationWarning(result, "Volume fraction should be in [0, 1]")
        END IF
      END IF
    END IF
  END SUBROUTINE MD_Mat_ValidParameterConsist

  SUBROUTINE MD_Mat_ValidParameterDepende(props, nprops, &
                                                         result, status, &
                                                         required_props, &
                                                         dependency_rule)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4), INTENT(IN), OPTIONAL :: required_props
    INTEGER(i4), INTENT(IN), OPTIONAL :: dependency_rule(:)

    INTEGER(i4) :: min_props, i

    CALL init_error_status(status)
    IF (PRESENT(required_props)) THEN
      min_props = required_props
    ELSE
      min_props = 2
    END IF
    IF (nprops < min_props) THEN
      CALL UF_AddValidationError(result, &
        "At least " // TRIM(UF_IntToString(min_props)) // " parameters required")
      result%is_valid = .FALSE.
      RETURN
    END IF
    IF (PRESENT(dependency_rule)) THEN
      DO i = 1, SIZE(dependency_rule) - 1, 2
        IF (i + 1 <= SIZE(dependency_rule)) THEN
          IF (dependency_rule(i) <= nprops .AND. &
              ABS(props(dependency_rule(i))) > 1.0e-10_wp) THEN
            IF (dependency_rule(i+1) > nprops) THEN
              CALL UF_AddValidationError(result, &
                "Property " // TRIM(UF_IntToString(dependency_rule(i))) // &
                " requires property " // TRIM(UF_IntToString(dependency_rule(i+1))))
              result%is_valid = .FALSE.
            END IF
          END IF
        END IF
      END DO
    END IF
    IF (nprops >= 5) THEN
      IF (props(4) > 0.0_wp .AND. props(4) < 1.0e3_wp) THEN
        IF (nprops < 5) THEN
          CALL UF_AddValidationWarning(result, &
            "Thermal expansion coef provided but reference temperature may be missing")
        END IF
      END IF
    END IF
  END SUBROUTINE MD_Mat_ValidParameterDependencies

  SUBROUTINE MD_Mat_ValidParameterRange(param_value, param_name, &
                                                  min_val, max_val, &
                                                  result, status, &
                                                  inclusive_min, inclusive_max)
    REAL(wp), INTENT(IN) :: param_value
    CHARACTER(LEN=*), INTENT(IN) :: param_name
    REAL(wp), INTENT(IN) :: min_val, max_val
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    LOGICAL, INTENT(IN), OPTIONAL :: inclusive_min, inclusive_max

    LOGICAL :: incl_min, incl_max
    CHARACTER(LEN=1) :: bracket_min, bracket_max

    CALL init_error_status(status)
    incl_min = .TRUE.
    incl_max = .TRUE.
    IF (PRESENT(inclusive_min)) incl_min = inclusive_min
    IF (PRESENT(inclusive_max)) incl_max = inclusive_max
    IF (incl_min) THEN
      bracket_min = "["
    ELSE
      bracket_min = "("
    END IF
    IF (incl_max) THEN
      bracket_max = "]"
    ELSE
      bracket_max = ")"
    END IF
    IF ((incl_min .AND. param_value < min_val) .OR. &
        (.NOT. incl_min .AND. param_value <= min_val) .OR. &
        (incl_max .AND. param_value > max_val) .OR. &
        (.NOT. incl_max .AND. param_value >= max_val)) THEN
      CALL UF_AddValidationError(result, &
        TRIM(param_name) // " is out of range " // bracket_min // &
        TRIM(UF_RealToString(min_val)) // ", " // &
        TRIM(UF_RealToString(max_val)) // bracket_max)
      result%is_valid = .FALSE.
    END IF
  END SUBROUTINE MD_Mat_ValidParameterRange

  SUBROUTINE MD_Mat_ValidParameters(material_id, props, nprops, &
                                             statev, nstatev, result, status)
    !! Unified parameter validation for all Mat types
    !! Routes to category-specific validation functions

    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN), OPTIONAL :: statev(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: nstatev
    TYPE(ParameterValidResult), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Init result
    result%is_valid = .TRUE.
    result%n_warnings = 0
    result%n_errors = 0

    ! Route to category-specific validation based on Mat ID
    IF (material_id >= 101_i4 .AND. material_id <= 199_i4) THEN
      ! Elastic materials
      CALL UF_Elastic_ValidParameters(material_id, props, nprops, &
                                         statev, nstatev, result, status)
    ELSE IF (material_id >= 201_i4 .AND. material_id <= 299_i4) THEN
      ! Plastic materials
      CALL UF_Plastic_ValidParameters(material_id, props, nprops, &
                                         statev, nstatev, result, status)
    ELSE IF (material_id >= 301_i4 .AND. material_id <= 399_i4) THEN
      ! Hyperelastic materials
      CALL UF_Hyp_ValidParameters(material_id, props, nprops, &
                                               statev, nstatev, result, status)
    ELSE IF (material_id >= 401_i4 .AND. material_id <= 499_i4) THEN
      ! Viscoelastic materials
      CALL UF_Viscoelastic_ValidParameters(material_id, props, nprops, &
                                               statev, nstatev, result, status)
    ELSE IF (material_id >= 501_i4 .AND. material_id <= 599_i4) THEN
      ! Damage materials
      CALL UF_Damage_ValidateParameters(material_id, props, nprops, &
                                        statev, nstatev, result, status)
    ELSE IF (material_id >= 601_i4 .AND. material_id <= 699_i4) THEN
      ! Creep materials
      CALL UF_Creep_ValidateParameters(material_id, props, nprops, &
                                       statev, nstatev, result, status)
    ELSE IF (material_id >= 121_i4 .AND. material_id <= 139_i4) THEN
      ! Composite materials
      CALL UF_Comp_ValidParameters(material_id, props, nprops, &
                                          statev, nstatev, result, status)
    ELSE
      WRITE(status%message, '(A,I0)') "Unknown Mat ID for validation: ", material_id
      CALL UF_AddValidationError(result, TRIM(status%message))
      result%is_valid = .FALSE.
    END IF

    IF (result%n_errors > 0) THEN
      result%is_valid = .FALSE.
      status%status_code = MD_MAT_STATUS_INVALID
    ELSE IF (result%n_warnings > 0) THEN
      status%status_code = MD_MAT_STATUS_WARN
    ELSE
      status%status_code = MD_MAT_STATUS_OK
    END IF

  END SUBROUTINE MD_Mat_ValidParameters

  SUBROUTINE UF_AddValidationError(result, error_message)
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    CHARACTER(LEN=*), INTENT(IN) :: error_message

    INTEGER(i4) :: n_errors_old

    n_errors_old = result%n_errors
    result%n_errors = result%n_errors + 1
    IF (.NOT. ALLOCATED(result%errors)) THEN
      ALLOCATE(result%errors(10))
    ELSE IF (result%n_errors > SIZE(result%errors)) THEN
      CALL UF_ReallocateErrors(result%errors, result%n_errors + 10)
    END IF
    IF (result%n_errors <= SIZE(result%errors)) THEN
      result%errors(result%n_errors) = error_message
    END IF
    result%is_valid = .FALSE.
  END SUBROUTINE UF_AddValidationError

  SUBROUTINE UF_AddValidationWarning(result, warning_message)
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    CHARACTER(LEN=*), INTENT(IN) :: warning_message

    result%n_warnings = result%n_warnings + 1
    IF (.NOT. ALLOCATED(result%warnings)) THEN
      ALLOCATE(result%warnings(10))
    ELSE IF (result%n_warnings > SIZE(result%warnings)) THEN
      CALL UF_ReallocateWarnings(result%warnings, result%n_warnings + 10)
    END IF
    IF (result%n_warnings <= SIZE(result%warnings)) THEN
      result%warnings(result%n_warnings) = warning_message
    END IF
  END SUBROUTINE UF_AddValidationWarning

  SUBROUTINE UF_Comp_ValidParameters(material_id, props, nprops, &
                                              statev, nstatev, result, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN), OPTIONAL :: statev(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: nstatev
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: val_status

    CALL init_error_status(status)
    SELECT CASE (material_id)
    CASE (MD_MAT_LAM_COMP_MAT_ID, 121_i4)
      CALL UF_LamComp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_FIBER_REINF_COMP_MAT_ID, 122_i4)
      CALL UF_FiberReinfComp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE DEFAULT
      IF (nprops < 2) THEN
        CALL UF_AddValidationError(result, "Insufficient properties for composite Mat")
        result%is_valid = .FALSE.
      END IF
      IF (nprops >= 2 .AND. (props(1) < 0.0_wp .OR. props(1) > 1.0_wp)) THEN
        CALL UF_AddValidationError(result, "Volume fraction must be in [0, 1]")
        result%is_valid = .FALSE.
      END IF
    END SELECT
  END SUBROUTINE UF_Comp_ValidParameters

  SUBROUTINE UF_Creep_ValidateParameters(material_id, props, nprops, &
                                          statev, nstatev, result, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN), OPTIONAL :: statev(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: nstatev
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: val_status

    CALL init_error_status(status)
    SELECT CASE (material_id)
    CASE (MD_MAT_NORTON_CREEP_MA, 601_i4)
      CALL UF_NortonCreep_ValidateProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_GAROFALO_CREEP, 602_i4)
      CALL UF_GarofaloCreep_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE DEFAULT
      IF (nprops >= 1 .AND. props(1) <= 0.0_wp) &
        CALL UF_AddValidationError(result, "Creep coef must be positive")
      IF (nprops >= 2 .AND. props(2) <= 0.0_wp) &
        CALL UF_AddValidationError(result, "Creep stress exponent must be positive")
    END SELECT
  END SUBROUTINE UF_Creep_ValidateParameters

  SUBROUTINE UF_Damage_ValidateParameters(material_id, props, nprops, &
                                           statev, nstatev, result, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN), OPTIONAL :: statev(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: nstatev
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: val_status

    CALL init_error_status(status)
    IF (nprops < 3) THEN
      CALL UF_AddValidationError(result, "Insufficient properties for damage Mat")
      RETURN
    END IF
    SELECT CASE (material_id)
    CASE (MD_MAT_DUCTILE_DAMAGE, 501_i4)
      CALL UF_DuctileDmg_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_BRITTLE_DAMAGE, 505_i4)
      CALL UF_BrittleDmg_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_PROG_DMG_MAT_ID, 511_i4)
      CALL UF_ProgDmg_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_FATIGUE_DAMAGE, 512_i4)
      CALL UF_FatigueDmg_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_CREEP_DAMAGE_MA, 541_i4)
      CALL UF_CreepDamage_ValidateProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_THERMAL_DAMAGE, 551_i4)
      CALL UF_ThermalDmg_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE DEFAULT
      IF (nprops >= 1 .AND. props(1) <= 0.0_wp) &
        CALL UF_AddValidationError(result, "Mat modulus must be positive")
    END SELECT
  END SUBROUTINE UF_Damage_ValidateParameters

  SUBROUTINE UF_Elastic_ValidParameters(material_id, props, nprops, &
                                            statev, nstatev, result, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN), OPTIONAL :: statev(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: nstatev
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: val_status

    CALL init_error_status(status)
    SELECT CASE (material_id)
    CASE (MD_MAT_ISO_ELAS_MAT_ID)
      CALL UF_IsotropicElastic_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_ORTHO_ELAS_MAT_ID)
      CALL UF_OrthoElastic_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_TRANSV_ISO_ELAS_MAT_ID)
      CALL UF_TransverseIsoElastic_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_ANISO_ELAS_MAT_ID)
      CALL UF_AnisotropicElastic_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_POROUS_ELAS_MAT)
      CALL UF_PorousElastic_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE DEFAULT
      IF (nprops >= 1 .AND. props(1) <= 0.0_wp) THEN
        CALL UF_AddValidationError(result, "Young's modulus must be positive")
      END IF
    END SELECT
  END SUBROUTINE UF_Elastic_ValidParameters

  SUBROUTINE UF_Hyp_ValidParameters(material_id, props, nprops, &
                                                  statev, nstatev, result, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN), OPTIONAL :: statev(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: nstatev
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: val_status

    CALL init_error_status(status)
    SELECT CASE (material_id)
    CASE (311_i4)
      CALL UF_NeoHookeanHyp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (321_i4)
      CALL UF_MRHyp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (331_i4)
      CALL UF_OgdenHyp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (341_i4)
      CALL UF_ArrudaBoyceHyp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (351_i4)
      CALL UF_YeohHyp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (403_i4)
      CALL UF_VanDerWaalsHyp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (404_i4)
      CALL UF_MarlowHyp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (405_i4)
      CALL UF_HyperfoamHyp_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE DEFAULT
      IF (nprops >= 1 .AND. props(1) <= 0.0_wp) THEN
        CALL UF_AddValidationError(result, "Hyperelastic Mat constant must be positive")
      END IF
      IF (nprops >= 2 .AND. props(2) <= 0.0_wp) THEN
        CALL UF_AddValidationError(result, "Compressibility parameter must be positive")
      END IF
    END SELECT
  END SUBROUTINE UF_Hyp_ValidParameters

  FUNCTION UF_IntToString(value) RESULT(str)
    INTEGER(i4), INTENT(IN) :: value
    CHARACTER(LEN=32) :: str
    WRITE(str, '(I0)') value
  END FUNCTION UF_IntToString

  FUNCTION UF_Mat_GetCategory(material_id) RESULT(category)
    !! Get Mat category from Mat ID

    INTEGER(i4), INTENT(IN) :: material_id
    INTEGER(i4) :: category

    IF (material_id >= MD_MAT_ID_RANGE_ELAS_S .AND. &
        material_id <= MD_MAT_ID_RANGE_ELAS_E) THEN
      category = MD_MAT_CATEGORY_ELAS
    ELSE IF (material_id >= MD_MAT_ID_RANGE_PLAST_S .AND. &
             material_id <= MD_MAT_ID_RANGE_PLAST_E) THEN
      category = MD_MAT_CATEGORY_PLASTI
    ELSE IF (material_id >= MD_MAT_ID_RANGE_HYP_ST .AND. &
             material_id <= MD_MAT_ID_RANGE_HYP_EN) THEN
      category = MD_MAT_CATEGORY_HYP
    ELSE IF (material_id >= MD_MAT_ID_RANGE_VISC_S .AND. &
              material_id <= MD_MAT_ID_RANGE_VISC_E) THEN
      category = MD_MAT_CATEGORY_VISC
    ELSE IF (material_id >= MD_MAT_ID_RANGE_DMG_S .AND. &
              material_id <= MD_MAT_ID_RANGE_DMG_E) THEN
      category = MD_MAT_CATEGORY_DAMAGE
    ELSE IF (material_id >= MD_MAT_ID_RANGE_CREEP_S .AND. &
              material_id <= MD_MAT_ID_RANGE_CREEP_E) THEN
      category = MD_MAT_CATEGORY_CREEP
    ELSE IF ((material_id >= 121_i4 .AND. material_id <= 129_i4) .OR. &
             (material_id >= 130_i4 .AND. material_id <= 139_i4)) THEN
      category = MD_MAT_CATEGORY_COMP
    ELSE
      category = MD_MAT_CATEGORY_SPECIA
    END IF

  END FUNCTION UF_Mat_GetCategory

  SUBROUTINE UF_Mat_GetInfo(material_id, info, status)
    !! Get information about a Mat from unified registry

    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(UnifMatInfo), INTENT(OUT) :: info
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Init registry if needed
    IF (.NOT. registry_initialized) THEN
      CALL MD_Mat_InitReg(status)
      IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    END IF

    ! Linear search in unified registry
    DO i = 1, n_registered
      IF (unified_registr(i)%material_id == material_id) THEN
        info = unified_registr(i)
        status%status_code = MD_MAT_STATUS_OK
        RETURN
      END IF
    END DO

    ! Not found in unified registry - try category-specific interfaces
    ! First determine category from Mat ID
    IF (material_id >= MD_MAT_ID_RANGE_PLAST_S .AND. &
        material_id <= MD_MAT_ID_RANGE_PLAST_E) THEN
      ! Try Plastic Interface
      TYPE(PlastMatInfo) :: plastic_info
      CALL UF_Plastic_GetMaterialInfo(material_id, plastic_info, status)
      IF (status%status_code == MD_MAT_STATUS_OK) THEN
        info%material_id = plastic_info%material_id
        info%name = plastic_info%name
        info%category = MD_MAT_CATEGORY_PLASTI
        info%category_name = MD_MAT_CATEGORY_NAMES(MD_MAT_CATEGORY_PLASTI)
        info%nprops_min = plastic_info%nprops_min
        info%nprops_max = plastic_info%nprops_max
        info%nstatev_min = plastic_info%nstatev_min
        info%nstatev_max = plastic_info%nstatev_max
        info%available = plastic_info%available
        RETURN
      END IF
    ELSE IF (material_id >= MD_MAT_ID_RANGE_ELAS_S .AND. &
             material_id <= MD_MAT_ID_RANGE_ELAS_E) THEN
      ! Try Elastic Interface
      TYPE(ElasMatInfo) :: elastic_info
      CALL UF_Elastic_GetMaterialInfo(material_id, elastic_info, status)
      IF (status%status_code == MD_MAT_STATUS_OK) THEN
        info%material_id = elastic_info%material_id
        info%name = elastic_info%name
        info%category = MD_MAT_CATEGORY_ELAS
        info%category_name = MD_MAT_CATEGORY_NAMES(MD_MAT_CATEGORY_ELAS)
        info%nprops_min = elastic_info%nprops_min
        info%nprops_max = elastic_info%nprops_max
        info%nstatev_min = elastic_info%nstatev_min
        info%nstatev_max = elastic_info%nstatev_max
        info%available = elastic_info%available
        RETURN
      END IF
    ELSE IF (material_id >= MD_MAT_ID_RANGE_HYP_ST .AND. &
             material_id <= MD_MAT_ID_RANGE_HYP_EN) THEN
      ! Try Hyperelastic Interface
      TYPE(HypMatInfo) :: hyp_info
      CALL UF_Hyp_GetMatInfo(material_id, hyp_info, status)
      IF (status%status_code == MD_MAT_STATUS_OK) THEN
        info%material_id = hyp_info%material_id
        info%name = hyp_info%name
        info%category = MD_MAT_CATEGORY_HYP
        info%category_name = MD_MAT_CATEGORY_NAMES(MD_MAT_CATEGORY_HYP)
        info%nprops_min = hyp_info%nprops_min
        info%nprops_max = hyp_info%nprops_max
        info%nstatev_min = hyp_info%nstatev_min
        info%nstatev_max = hyp_info%nstatev_max
        info%available = hyp_info%available
        RETURN
      END IF
    ELSE IF (material_id >= MD_MAT_ID_RANGE_VISC_S .AND. &
             material_id <= MD_MAT_ID_RANGE_VISC_E) THEN
      ! Try Viscoelastic Interface
      TYPE(ViscMatInfo) :: visc_info
      CALL UF_Viscoelastic_GetMatInfo(material_id, visc_info, status)
      IF (status%status_code == MD_MAT_STATUS_OK) THEN
        info%material_id = visc_info%material_id
        info%name = visc_info%name
        info%category = MD_MAT_CATEGORY_VISC
        info%category_name = MD_MAT_CATEGORY_NAMES(MD_MAT_CATEGORY_VISC)
        info%nprops_min = visc_info%nprops_min
        info%nprops_max = visc_info%nprops_max
        info%nstatev_min = visc_info%nstatev_min
        info%nstatev_max = visc_info%nstatev_max
        info%available = visc_info%available
        RETURN
      END IF
    ELSE IF (material_id >= MD_MAT_ID_RANGE_DMG_S .AND. &
             material_id <= MD_MAT_ID_RANGE_DMG_E) THEN
      ! Try Damage Interface
      TYPE(DmgMatInfo) :: damage_info
      CALL UF_Damage_GetMaterialInfo(material_id, damage_info, status)
      IF (status%status_code == MD_MAT_STATUS_OK) THEN
        info%material_id = damage_info%material_id
        info%name = damage_info%name
        info%category = MD_MAT_CATEGORY_DAMAGE
        info%category_name = MD_MAT_CATEGORY_NAMES(MD_MAT_CATEGORY_DAMAGE)
        info%nprops_min = damage_info%nprops_min
        info%nprops_max = damage_info%nprops_max
        info%nstatev_min = damage_info%nstatev_min
        info%nstatev_max = damage_info%nstatev_max
        info%available = damage_info%available
        RETURN
      END IF
    ELSE IF (material_id >= MD_MAT_ID_RANGE_CREEP_S .AND. &
             material_id <= MD_MAT_ID_RANGE_CREEP_E) THEN
      ! Try Creep Interface
      TYPE(CreepMatInfo) :: creep_info
      CALL UF_Creep_GetMaterialInfo(material_id, creep_info, status)
      IF (status%status_code == MD_MAT_STATUS_OK) THEN
        info%material_id = creep_info%material_id
        info%name = creep_info%name
        info%category = MD_MAT_CATEGORY_CREEP
        info%category_name = MD_MAT_CATEGORY_NAMES(MD_MAT_CATEGORY_CREEP)
        info%nprops_min = creep_info%nprops_min
        info%nprops_max = creep_info%nprops_max
        info%nstatev_min = creep_info%nstatev_min
        info%nstatev_max = creep_info%nstatev_max
        info%available = creep_info%available
        RETURN
      END IF
    ELSE IF ((material_id >= 121_i4 .AND. material_id <= 129_i4) .OR. &
             (material_id >= 130_i4 .AND. material_id <= 139_i4)) THEN
      ! Try Composite Interface
      TYPE(CompMatInfo) :: composite_info
      CALL UF_Composite_GetMaterialInfo(material_id, composite_info, status)
      IF (status%status_code == MD_MAT_STATUS_OK) THEN
        info%material_id = composite_info%material_id
        info%name = composite_info%name
        info%category = MD_MAT_CATEGORY_COMP
        info%category_name = MD_MAT_CATEGORY_NAMES(MD_MAT_CATEGORY_COMP)
        info%nprops_min = composite_info%nprops_min
        info%nprops_max = composite_info%nprops_max
        info%nstatev_min = composite_info%nstatev_min
        info%nstatev_max = composite_info%nstatev_max
        info%available = composite_info%available
        RETURN
      END IF
    END IF

    ! Mat not found
    status%status_code = MD_MAT_STATUS_NOT_FOUND
    WRITE(status%message, '(A,I0)') 'Mat not found: ', material_id

  END SUBROUTINE UF_Mat_GetInfo

  SUBROUTINE UF_Mat_ListMaterials(category_filter, material_list, n_materials, status)
    !! List all registered materials, optionally filtered by category

    INTEGER(i4), INTENT(IN), OPTIONAL :: category_filter
    TYPE(UnifMatInfo), INTENT(OUT), ALLOCATABLE :: material_list(:)
    INTEGER(i4), INTENT(OUT) :: n_materials
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, count

    CALL init_error_status(status)

    ! Init registry if needed
    IF (.NOT. registry_initialized) THEN
      CALL MD_Mat_InitReg(status)
      IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    END IF

    ! Count matching materials
    count = 0
    DO i = 1, n_registered
      IF (.NOT. PRESENT(category_filter) .OR. &
          unified_registr(i)%category == category_filter) THEN
        count = count + 1
      END IF
    END DO

    ! Allocate and fill list
    IF (ALLOCATED(material_list)) DEALLOCATE(material_list)
    ALLOCATE(material_list(count))

    count = 0
    DO i = 1, n_registered
      IF (.NOT. PRESENT(category_filter) .OR. &
          unified_registr(i)%category == category_filter) THEN
        count = count + 1
        material_list(count) = unified_registr(i)
      END IF
    END DO

    n_materials = count
    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Mat_ListMaterials

  SUBROUTINE UF_Mat_Reg(material_id, name, category_name, &
                                   nprops_min, nprops_max, &
                                   nstatev_min, nstatev_max, status)
    !! Reg a Mat in the unified registry (public)

    INTEGER(i4), INTENT(IN) :: material_id
    CHARACTER(LEN=*), INTENT(IN) :: name, category_name
    INTEGER(i4), INTENT(IN) :: nprops_min, nprops_max
    INTEGER(i4), INTENT(IN) :: nstatev_min, nstatev_max
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: category

    CALL init_error_status(status)

    ! Determine category from name
    category = MD_Mat_GetCategoryFromName(category_name)
    IF (category == 0) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Unknown category: " // TRIM(category_name)
      RETURN
    END IF

    ! Reg
    CALL MD_Mat_Reg_Int(material_id, name, category, &
                                       nprops_min, nprops_max, &
                                       nstatev_min, nstatev_max, status)

  END SUBROUTINE UF_Mat_Reg

  SUBROUTINE UF_Mat_RegBuiltInMats(status)
    !! Reg all built-in materials from all categories

    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: reg_status
    TYPE(PlastMatInfo) :: plastic_info
    TYPE(ElasMatInfo) :: elastic_info
    TYPE(HypMatInfo) :: hyp_info
    TYPE(ViscMatInfo) :: visc_info
    TYPE(DmgMatInfo) :: damage_info
    TYPE(CreepMatInfo) :: creep_info
    TYPE(CompMatInfo) :: composite_info

    CALL init_error_status(status)

    ! Reg Elastic Materials
    ! Query from Layer 2 (Elastic Interface) and add to unified registry

    ! Isotropic Elastic
    CALL UF_Elastic_GetMaterialInfo(101_i4, elastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(101_i4, &
                                         TRIM(elastic_info%name), &
                                         MD_MAT_CATEGORY_ELAS, &
                                         elastic_info%nprops_min, &
                                         elastic_info%nprops_max, &
                                         elastic_info%nstatev_min, &
                                         elastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Orthotropic Elastic
    CALL UF_Elastic_GetMaterialInfo(102_i4, elastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(102_i4, &
                                         TRIM(elastic_info%name), &
                                         MD_MAT_CATEGORY_ELAS, &
                                         elastic_info%nprops_min, &
                                         elastic_info%nprops_max, &
                                         elastic_info%nstatev_min, &
                                         elastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Transversely Isotropic Elastic (mat_id 103; 112 is LaminatedElastic per MD_MatIds)
    CALL UF_Elastic_GetMaterialInfo(103_i4, elastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(103_i4, &
                                         TRIM(elastic_info%name), &
                                         MD_MAT_CATEGORY_ELAS, &
                                         elastic_info%nprops_min, &
                                         elastic_info%nprops_max, &
                                         elastic_info%nstatev_min, &
                                         elastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Anisotropic Elastic (mat_id 104 per MD_MatIds / L4 registry)
    CALL UF_Elastic_GetMaterialInfo(104_i4, elastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(104_i4, &
                                         TRIM(elastic_info%name), &
                                         MD_MAT_CATEGORY_ELAS, &
                                         elastic_info%nprops_min, &
                                         elastic_info%nprops_max, &
                                         elastic_info%nstatev_min, &
                                         elastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Porous Elastic
    CALL UF_Elastic_GetMaterialInfo(123_i4, elastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(123_i4, &
                                         TRIM(elastic_info%name), &
                                         MD_MAT_CATEGORY_ELAS, &
                                         elastic_info%nprops_min, &
                                         elastic_info%nprops_max, &
                                         elastic_info%nstatev_min, &
                                         elastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Reg Hyperelastic Materials
    ! Query from Layer 2 (Hyperelastic Interface) and add to unified registry

    ! Neo-Hookean
    CALL UF_Hyp_GetMatInfo(301_i4, hyp_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(301_i4, &
                                         TRIM(hyp_info%name), &
                                         MD_MAT_CATEGORY_HYP, &
                                         hyp_info%nprops_min, &
                                         hyp_info%nprops_max, &
                                         hyp_info%nstatev_min, &
                                         hyp_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Mooney-Rivlin
    CALL UF_Hyp_GetMatInfo(311_i4, hyp_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(311_i4, &
                                         TRIM(hyp_info%name), &
                                         MD_MAT_CATEGORY_HYP, &
                                         hyp_info%nprops_min, &
                                         hyp_info%nprops_max, &
                                         hyp_info%nstatev_min, &
                                         hyp_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Ogden
    CALL UF_Hyp_GetMatInfo(321_i4, hyp_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(321_i4, &
                                         TRIM(hyp_info%name), &
                                         MD_MAT_CATEGORY_HYP, &
                                         hyp_info%nprops_min, &
                                         hyp_info%nprops_max, &
                                         hyp_info%nstatev_min, &
                                         hyp_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Arruda-Boyce
    CALL UF_Hyp_GetMatInfo(331_i4, hyp_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(331_i4, &
                                         TRIM(hyp_info%name), &
                                         MD_MAT_CATEGORY_HYP, &
                                         hyp_info%nprops_min, &
                                         hyp_info%nprops_max, &
                                         hyp_info%nstatev_min, &
                                         hyp_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Yeoh
    CALL UF_Hyp_GetMatInfo(341_i4, hyp_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(341_i4, &
                                         TRIM(hyp_info%name), &
                                         MD_MAT_CATEGORY_HYP, &
                                         hyp_info%nprops_min, &
                                         hyp_info%nprops_max, &
                                         hyp_info%nstatev_min, &
                                         hyp_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Mooney-Rivlin
    CALL UF_Hyp_GetMatInfo(141_i4, hyp_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(141_i4, &
                                         TRIM(hyp_info%name), &
                                         MD_MAT_CATEGORY_HYP, &
                                         hyp_info%nprops_min, &
                                         hyp_info%nprops_max, &
                                         hyp_info%nstatev_min, &
                                         hyp_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Reg Plastic Materials
    ! Note: These are already registered in Layer 2 (Plastic Interface)
    ! We query them and add to unified registry

    ! Von Mises
    CALL UF_Plastic_GetMaterialInfo(MD_MAT_VONMISES_MAT_ID, plastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(MD_MAT_VONMISES_MAT_ID, &
                                         TRIM(plastic_info%name), &
                                         MD_MAT_CATEGORY_PLASTI, &
                                         plastic_info%nprops_min, &
                                         plastic_info%nprops_max, &
                                         plastic_info%nstatev_min, &
                                         plastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Hill
    CALL UF_Plastic_GetMaterialInfo(MD_MAT_HILL_MAT_ID, plastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(MD_MAT_HILL_MAT_ID, &
                                         TRIM(plastic_info%name), &
                                         MD_MAT_CATEGORY_PLASTI, &
                                         plastic_info%nprops_min, &
                                         plastic_info%nprops_max, &
                                         plastic_info%nstatev_min, &
                                         plastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Drucker-Prager
    CALL UF_Plastic_GetMaterialInfo(MD_MAT_DRUCKERPRAGER_M, plastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(MD_MAT_DRUCKERPRAGER_M, &
                                         TRIM(plastic_info%name), &
                                         MD_MAT_CATEGORY_PLASTI, &
                                         plastic_info%nprops_min, &
                                         plastic_info%nprops_max, &
                                         plastic_info%nstatev_min, &
                                         plastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Cam-Clay
    CALL UF_Plastic_GetMaterialInfo(MD_MAT_CAMCLAY_MAT_ID, plastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(MD_MAT_CAMCLAY_MAT_ID, &
                                         TRIM(plastic_info%name), &
                                         MD_MAT_CATEGORY_PLASTI, &
                                         plastic_info%nprops_min, &
                                         plastic_info%nprops_max, &
                                         plastic_info%nstatev_min, &
                                         plastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Mohr-Coulomb
    CALL UF_Plastic_GetMaterialInfo(MD_MAT_MOHRCOULOMB_MAT, plastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(MD_MAT_MOHRCOULOMB_MAT, &
                                         TRIM(plastic_info%name), &
                                         MD_MAT_CATEGORY_PLASTI, &
                                         plastic_info%nprops_min, &
                                         plastic_info%nprops_max, &
                                         plastic_info%nstatev_min, &
                                         plastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Johnson-Cook
    CALL UF_Plastic_GetMaterialInfo(MD_MAT_JOHNSONCOOK_MAT, plastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(MD_MAT_JOHNSONCOOK_MAT, &
                                         TRIM(plastic_info%name), &
                                         MD_MAT_CATEGORY_PLASTI, &
                                         plastic_info%nprops_min, &
                                         plastic_info%nprops_max, &
                                         plastic_info%nstatev_min, &
                                         plastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Gurson (GTN)
    CALL UF_Plastic_GetMaterialInfo(MD_MAT_GURSON_MAT_ID, plastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(MD_MAT_GURSON_MAT_ID, &
                                         TRIM(plastic_info%name), &
                                         MD_MAT_CATEGORY_PLASTI, &
                                         plastic_info%nprops_min, &
                                         plastic_info%nprops_max, &
                                         plastic_info%nstatev_min, &
                                         plastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Chaboche
    CALL UF_Plastic_GetMaterialInfo(MD_MAT_CHABOCHE_MAT_ID, plastic_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(MD_MAT_CHABOCHE_MAT_ID, &
                                         TRIM(plastic_info%name), &
                                         MD_MAT_CATEGORY_PLASTI, &
                                         plastic_info%nprops_min, &
                                         plastic_info%nprops_max, &
                                         plastic_info%nstatev_min, &
                                         plastic_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Reg Viscoelastic Materials
    ! Query from Layer 2 (Viscoelastic Interface) and add to unified registry

    ! Prony Viscoelastic (new modular implementation)
    CALL UF_Viscoelastic_GetMatInfo(MD_MAT_VISC_PRONY_ID, visc_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(401_i4, &
                                         TRIM(visc_info%name), &
                                         MD_MAT_CATEGORY_VISC, &
                                         visc_info%nprops_min, &
                                         visc_info%nprops_max, &
                                         visc_info%nstatev_min, &
                                         visc_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Generalized Viscoelastic
    CALL UF_Viscoelastic_GetMatInfo(402_i4, visc_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(402_i4, &
                                         TRIM(visc_info%name), &
                                         MD_MAT_CATEGORY_VISC, &
                                         visc_info%nprops_min, &
                                         visc_info%nprops_max, &
                                         visc_info%nstatev_min, &
                                         visc_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Hysteresis Viscoelastic
    CALL UF_Viscoelastic_GetMatInfo(403_i4, visc_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(403_i4, &
                                         TRIM(visc_info%name), &
                                         MD_MAT_CATEGORY_VISC, &
                                         visc_info%nprops_min, &
                                         visc_info%nprops_max, &
                                         visc_info%nstatev_min, &
                                         visc_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Parallel Viscoelastic
    CALL UF_Viscoelastic_GetMatInfo(404_i4, visc_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(404_i4, &
                                         TRIM(visc_info%name), &
                                         MD_MAT_CATEGORY_VISC, &
                                         visc_info%nprops_min, &
                                         visc_info%nprops_max, &
                                         visc_info%nstatev_min, &
                                         visc_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Fractional Viscoelastic
    CALL UF_Viscoelastic_GetMatInfo(405_i4, visc_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(405_i4, &
                                         TRIM(visc_info%name), &
                                         MD_MAT_CATEGORY_VISC, &
                                         visc_info%nprops_min, &
                                         visc_info%nprops_max, &
                                         visc_info%nstatev_min, &
                                         visc_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Reg Damage Materials
    ! Query from Layer 2 (Damage Interface) and add to unified registry

    ! Ductile Damage (new modular implementation)
    CALL UF_Damage_GetMaterialInfo(MD_MAT_DAMAGE_DUCTILE, damage_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(501_i4, &
                                         TRIM(damage_info%name), &
                                         MD_MAT_CATEGORY_DAMAGE, &
                                         damage_info%nprops_min, &
                                         damage_info%nprops_max, &
                                         damage_info%nstatev_min, &
                                         damage_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Brittle Damage (new modular implementation)
    CALL UF_Damage_GetMaterialInfo(MD_MAT_DAMAGE_BRITTLE, damage_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(505_i4, &
                                         TRIM(damage_info%name), &
                                         MD_MAT_CATEGORY_DAMAGE, &
                                         damage_info%nprops_min, &
                                         damage_info%nprops_max, &
                                         damage_info%nstatev_min, &
                                         damage_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Progressive Damage (new modular implementation)
    CALL UF_Damage_GetMaterialInfo(MD_MAT_DAMAGE_PROG_ID, damage_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(511_i4, &
                                         TRIM(damage_info%name), &
                                         MD_MAT_CATEGORY_DAMAGE, &
                                         damage_info%nprops_min, &
                                         damage_info%nprops_max, &
                                         damage_info%nstatev_min, &
                                         damage_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Fatigue Damage (new modular implementation)
    CALL UF_Damage_GetMaterialInfo(MD_MAT_DAMAGE_FATIGUE, damage_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(512_i4, &
                                         TRIM(damage_info%name), &
                                         MD_MAT_CATEGORY_DAMAGE, &
                                         damage_info%nprops_min, &
                                         damage_info%nprops_max, &
                                         damage_info%nstatev_min, &
                                         damage_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Creep Damage (new modular implementation)
    CALL UF_Damage_GetMaterialInfo(MD_MAT_DAMAGE_CREEP_ID, damage_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(541_i4, &
                                         TRIM(damage_info%name), &
                                         MD_MAT_CATEGORY_DAMAGE, &
                                         damage_info%nprops_min, &
                                         damage_info%nprops_max, &
                                         damage_info%nstatev_min, &
                                         damage_info%nstatev_max, &
                                         reg_status)
    END IF

    ! Thermal Damage (new modular implementation)
    CALL UF_Damage_GetMaterialInfo(MD_MAT_DAMAGE_THERMAL, damage_info, reg_status)
    IF (reg_status%status_code == MD_MAT_STATUS_OK) THEN
      CALL MD_Mat_Reg_Int(551_i4, &
                                         TRIM(damage_info%name), &
                                         MD_MAT_CATEGORY_DAMAGE, &
                                         damage_info%nprops_min, &
                                         damage_info%nprops_max, &
                                         damage_info%nstatev_min, &
                                         damage_info%nstatev_max, &
                                         reg_status)
    END IF

    status%status_code = MD_MAT_STATUS_OK

  END SUBROUTINE UF_Mat_RegBuiltInMats

  SUBROUTINE UF_Plastic_ValidParameters(material_id, props, nprops, &
                                            statev, nstatev, result, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN), OPTIONAL :: statev(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: nstatev
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: val_status

    CALL init_error_status(status)
    SELECT CASE (material_id)
    CASE (MD_MAT_VONMISES_MAT_ID)
      CALL UF_VonMises_ValidateProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_HILL_MAT_ID)
      CALL UF_Hill_ValidateProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_DRUCKERPRAGER_M)
      CALL UF_DruckerPrager_ValidateProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_CAMCLAY_MAT_ID)
      CALL UF_CamClay_ValidateProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_MOHRCOULOMB_MAT)
      CALL UF_MohrCoulomb_ValidateProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (MD_MAT_JOHNSONCOOK_MAT)
      CALL UF_JohnsonCook_ValidateProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE DEFAULT
      IF (nprops >= 1 .AND. props(1) <= 0.0_wp) THEN
        CALL UF_AddValidationError(result, "Yield strength must be positive")
      END IF
    END SELECT
  END SUBROUTINE UF_Plastic_ValidParameters

  !-----------------------------------------------------------------------------
  ! MD_Mat_ValidatePlasticPropsForPopulate
  ! Purpose: Validate plastic material props when Populate fills slot_pool.
  !   Called from PH_L4_Populate_Material for PH_MAT_ELASTO_PLASTIC materials.
  !   Effective category: cfg%class_id, else DEPRECATED flat class_id (W1).
  !   Uses effective id (cfg%id, else flat id) when (201-299) or defaults.
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_ValidatePlasticPropsForPopulate(desc, props, nprops, status)
    CLASS(MD_Mat_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ParameterValidResult) :: result
    INTEGER(i4) :: material_id
    INTEGER(i4) :: eff_class

    CALL init_error_status(status)
    eff_class = desc%cfg%class_id
    IF (eff_class == 0_i4) eff_class = desc%class_id
    IF (eff_class /= MD_MAT_CATEGORY_PL) RETURN
    IF (nprops < 3) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MD_Mat_ValidatePlasticPropsForPopulate: Insufficient plastic props"
      RETURN
    END IF
    material_id = desc%cfg%id
    IF (material_id <= 0_i4) material_id = desc%id
    IF (material_id < 201_i4 .OR. material_id > 299_i4) material_id = MD_MAT_VONMISES_MAT_ID
    result%is_valid = .TRUE.
    result%n_warnings = 0
    result%n_errors = 0
    CALL UF_Plastic_ValidParameters(material_id, props, nprops, result=result, status=status)
    IF (.NOT. result%is_valid .AND. result%n_errors > 0) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      IF (ALLOCATED(result%errors) .AND. SIZE(result%errors) >= 1) &
        status%message = result%errors(1)
    END IF
  END SUBROUTINE MD_Mat_ValidatePlasticPropsForPopulate

  !-----------------------------------------------------------------------------
  ! MD_Mat_ValidatePropsForPopulate (P3: generic for all material categories)
  ! Purpose: Validate material props when Populate fills slot_pool.
  !   Routes by effective class_id (cfg%class_id, else DEPRECATED flat class_id);
  !   uses effective id (cfg%id, else flat id) when in valid range, else default.
  !   Covers: Elastic, Plastic, Hyperelastic, Viscoelastic, Creep, Damage.
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_ValidatePropsForPopulate(desc, props, nprops, status)
    CLASS(MD_Mat_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ParameterValidResult) :: result
    INTEGER(i4) :: material_id
    INTEGER(i4) :: eff_class

    CALL init_error_status(status)
    IF (nprops < 1) RETURN
    eff_class = desc%cfg%class_id
    IF (eff_class == 0_i4) eff_class = desc%class_id
    material_id = desc%cfg%id
    IF (material_id <= 0_i4) material_id = desc%id
    SELECT CASE (eff_class)
    CASE (MD_MAT_CATEGORY_EL)
      IF (material_id < 101_i4 .OR. material_id > 199_i4) material_id = MD_MAT_ISO_ELAS_MAT_ID
    CASE (MD_MAT_CATEGORY_PL)
      IF (material_id < 201_i4 .OR. material_id > 299_i4) material_id = MD_MAT_VONMISES_MAT_ID
    CASE (MD_MAT_CATEGORY_HY)
      IF (material_id < 301_i4 .OR. material_id > 399_i4) material_id = 311_i4
    CASE (MD_MAT_CATEGORY_VI)
      IF (material_id < 401_i4 .OR. material_id > 499_i4) material_id = MD_MAT_PRONY_VISC_MAT_ID
    CASE (MD_MAT_CATEGORY_CR)
      IF (material_id < 601_i4 .OR. material_id > 699_i4) material_id = 601_i4
    CASE (MD_MAT_CATEGORY_DA)
      IF (material_id < 501_i4 .OR. material_id > 599_i4) material_id = 501_i4
    CASE DEFAULT
      RETURN
    END SELECT
    CALL MD_Mat_ValidParameters(material_id, props, nprops, result=result, status=status)
    IF (.NOT. result%is_valid .AND. result%n_errors > 0) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      IF (ALLOCATED(result%errors) .AND. SIZE(result%errors) >= 1) &
        status%message = result%errors(1)
    END IF
  END SUBROUTINE MD_Mat_ValidatePropsForPopulate

  SUBROUTINE UF_ReallocateErrors(errors_array, new_size)
    CHARACTER(LEN=256), ALLOCATABLE, INTENT(INOUT) :: errors_array(:)
    INTEGER(i4), INTENT(IN) :: new_size

    CHARACTER(LEN=256), ALLOCATABLE :: temp_array(:)
    INTEGER(i4) :: old_size, i

    IF (ALLOCATED(errors_array)) THEN
      old_size = SIZE(errors_array)
      ALLOCATE(temp_array(old_size))
      temp_array = errors_array
      DEALLOCATE(errors_array)
      ALLOCATE(errors_array(new_size))
      DO i = 1, MIN(old_size, new_size)
        errors_array(i) = temp_array(i)
      END DO
      DEALLOCATE(temp_array)
    ELSE
      ALLOCATE(errors_array(new_size))
    END IF
  END SUBROUTINE UF_ReallocateErrors

  SUBROUTINE UF_ReallocateWarnings(warnings_array, new_size)
    CHARACTER(LEN=256), ALLOCATABLE, INTENT(INOUT) :: warnings_array(:)
    INTEGER(i4), INTENT(IN) :: new_size

    CHARACTER(LEN=256), ALLOCATABLE :: temp_array(:)
    INTEGER(i4) :: old_size, i

    IF (ALLOCATED(warnings_array)) THEN
      old_size = SIZE(warnings_array)
      ALLOCATE(temp_array(old_size))
      temp_array = warnings_array
      DEALLOCATE(warnings_array)
      ALLOCATE(warnings_array(new_size))
      DO i = 1, MIN(old_size, new_size)
        warnings_array(i) = temp_array(i)
      END DO
      DEALLOCATE(temp_array)
    ELSE
      ALLOCATE(warnings_array(new_size))
    END IF
  END SUBROUTINE UF_ReallocateWarnings

  FUNCTION UF_RealToString(value) RESULT(str)
    REAL(wp), INTENT(IN) :: value
    CHARACTER(LEN=32) :: str
    WRITE(str, '(G0.6)') value
  END FUNCTION UF_RealToString

  SUBROUTINE UF_ToUpper(str)
    !! Convert string to uppercase

    CHARACTER(LEN=*), INTENT(INOUT) :: str

    INTEGER(i4) :: i, ic

    DO i = 1, LEN(str)
      ic = ICHAR(str(i:i))
      IF (ic >= 97 .AND. ic <= 122) THEN
        str(i:i) = CHAR(ic - 32)
      END IF
    END DO

  END SUBROUTINE UF_ToUpper

  SUBROUTINE UF_Vi_ValidParameters(material_id, props, nprops, &
                                                  statev, nstatev, result, status)
    INTEGER(i4), INTENT(IN) :: material_id
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN), OPTIONAL :: statev(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: nstatev
    TYPE(ParameterValidResult), INTENT(INOUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ErrorStatusType) :: val_status
    INTEGER(i4) :: n_branches_loca

    CALL init_error_status(status)
    IF (nprops < 6) THEN
      CALL UF_AddValidationError(result, "Insufficient properties for viscoelastic Mat")
      RETURN
    END IF
    IF (props(1) <= 0.0_wp) THEN
      CALL UF_AddValidationError(result, "Long-term modulus must be positive")
    END IF
    SELECT CASE (material_id)
    CASE (MD_MAT_PRONY_VISC_MAT_ID, 401_i4)
      CALL UF_PronyViscoelastic_ValidProps(props, nprops, val_status)
      IF (val_status%status_code /= MD_MAT_STATUS_OK) THEN
        CALL UF_AddValidationError(result, TRIM(val_status%message))
        result%is_valid = .FALSE.
      END IF
    CASE (402_i4)
      IF (nprops < 4) THEN
        CALL UF_AddValidationError(result, "Generalized viscoelastic requires at least 4 properties")
        result%is_valid = .FALSE.
      ELSE
        IF (props(1) <= 0.0_wp) THEN
          CALL UF_AddValidationError(result, "Instantaneous modulus MD_MAT_E_0 must be positive")
          result%is_valid = .FALSE.
        END IF
        IF (nprops >= 2 .AND. (props(2) < -1.0_wp .OR. props(2) >= 0.5_wp)) THEN
          CALL UF_AddValidationError(result, "Poisson's ratio must be in [-1, 0.5)")
          result%is_valid = .FALSE.
        END IF
        IF (props(3) <= 0.0_wp) THEN
          CALL UF_AddValidationError(result, "Relaxation time must be positive")
          result%is_valid = .FALSE.
        END IF
        IF (props(3) < 1.0e-6_wp .OR. props(3) > 1.0e6_wp) THEN
          CALL UF_AddValidationError(result, "Relaxation time should be in reasonable range [1e-6, 1e6] seconds")
          result%is_valid = .FALSE.
        END IF
        IF (nprops >= 4) THEN
          IF (props(4) <= 0.0_wp) THEN
            CALL UF_AddValidationError(result, "Long-term modulus MD_MAT_E_inf must be positive")
            result%is_valid = .FALSE.
          END IF
          IF (props(4) >= props(1)) THEN
            CALL UF_AddValidationError(result, "Long-term modulus MD_MAT_E_inf should be less than instantaneous modulus MD_MAT_E_0")
            result%is_valid = .FALSE.
          END IF
        END IF
      END IF
    CASE (503_i4)
      IF (nprops < 5) THEN
        CALL UF_AddValidationError(result, "Hysteresis viscoelastic requires at least 5 properties")
        result%is_valid = .FALSE.
      ELSE
        IF (props(1) <= 0.0_wp) CALL UF_AddValidationError(result, "Elastic modulus must be positive")
        IF (nprops >= 2 .AND. (props(2) < -1.0_wp .OR. props(2) >= 0.5_wp)) &
          CALL UF_AddValidationError(result, "Poisson's ratio must be in [-1, 0.5)")
        IF (nprops >= 3 .AND. props(3) <= 0.0_wp) &
          CALL UF_AddValidationError(result, "Hysteresis parameter must be positive")
        IF (nprops >= 4 .AND. props(4) <= 0.0_wp) &
          CALL UF_AddValidationError(result, "Relaxation time must be positive")
      END IF
    CASE (504_i4)
      IF (nprops < 6) THEN
        CALL UF_AddValidationError(result, "Parallel viscoelastic requires at least 6 properties")
        result%is_valid = .FALSE.
      ELSE
        IF (props(1) <= 0.0_wp) CALL UF_AddValidationError(result, "Elastic modulus must be positive")
        IF (nprops >= 2 .AND. (props(2) < -1.0_wp .OR. props(2) >= 0.5_wp)) &
          CALL UF_AddValidationError(result, "Poisson's ratio must be in [-1, 0.5)")
        IF (nprops >= 3) THEN
          n_branches_loca = INT(props(3))
          IF (n_branches_loca <= 0 .OR. n_branches_loca > 10) THEN
            CALL UF_AddValidationError(result, "Number of parallel branches must be in [1, 10]")
            result%is_valid = .FALSE.
          END IF
        END IF
      END IF
    CASE (505_i4)
      IF (nprops < 4) THEN
        CALL UF_AddValidationError(result, "Fractional viscoelastic requires at least 4 properties")
        result%is_valid = .FALSE.
      ELSE
        IF (props(1) <= 0.0_wp) CALL UF_AddValidationError(result, "Elastic modulus must be positive")
        IF (nprops >= 2 .AND. (props(2) < -1.0_wp .OR. props(2) >= 0.5_wp)) &
          CALL UF_AddValidationError(result, "Poisson's ratio must be in [-1, 0.5)")
        IF (nprops >= 3 .AND. (props(3) < 0.0_wp .OR. props(3) > 1.0_wp)) &
          CALL UF_AddValidationError(result, "Fractional order must be in [0, 1]")
        IF (nprops >= 4 .AND. props(4) <= 0.0_wp) &
          CALL UF_AddValidationError(result, "Relaxation time must be positive")
      END IF
    CASE DEFAULT
      IF (props(1) <= 0.0_wp) &
        CALL UF_AddValidationError(result, "Long-term modulus must be positive")
      IF (nprops >= 4 .AND. props(4) <= 0.0_wp) &
        CALL UF_AddValidationError(result, "Relaxation time must be positive")
    END SELECT
  END SUBROUTINE UF_Viscoelastic_ValidParameters




  ! ==========================================================================
  ! STUB SUBROUTINES for missing domain GetMaterialInfo interfaces
  ! ==========================================================================

  SUBROUTINE UF_Elastic_GetMaterialInfo(material_id, info, status)
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(ElasMatInfo), INTENT(OUT) :: info
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    info%material_id = material_id
    status%status_code = MD_MAT_STATUS_NOT_FOUND
    status%message = 'Elastic material info interface not implemented'
  END SUBROUTINE UF_Elastic_GetMaterialInfo

  SUBROUTINE UF_Hyp_GetMatInfo(material_id, info, status)
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(HypMatInfo), INTENT(OUT) :: info
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    info%material_id = material_id
    status%status_code = MD_MAT_STATUS_NOT_FOUND
    status%message = 'Hyperelastic material info interface not implemented'
  END SUBROUTINE UF_Hyp_GetMatInfo

  SUBROUTINE UF_Viscoelastic_GetMatInfo(material_id, info, status)
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(ViscMatInfo), INTENT(OUT) :: info
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    info%material_id = material_id
    status%status_code = MD_MAT_STATUS_NOT_FOUND
    status%message = 'Viscoelastic material info interface not implemented'
  END SUBROUTINE UF_Viscoelastic_GetMatInfo

  SUBROUTINE UF_Damage_GetMaterialInfo(material_id, info, status)
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(DmgMatInfo), INTENT(OUT) :: info
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    info%material_id = material_id
    status%status_code = MD_MAT_STATUS_NOT_FOUND
    status%message = 'Damage material info interface not implemented'
  END SUBROUTINE UF_Damage_GetMaterialInfo

  SUBROUTINE UF_Creep_GetMaterialInfo(material_id, info, status)
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(CreepMatInfo), INTENT(OUT) :: info
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    info%material_id = material_id
    status%status_code = MD_MAT_STATUS_NOT_FOUND
    status%message = 'Creep material info interface not implemented'
  END SUBROUTINE UF_Creep_GetMaterialInfo

  SUBROUTINE UF_Composite_GetMaterialInfo(material_id, info, status)
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(CompMatInfo), INTENT(OUT) :: info
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    info%material_id = material_id
    status%status_code = MD_MAT_STATUS_NOT_FOUND
    status%message = 'Composite material info interface not implemented'
  END SUBROUTINE UF_Composite_GetMaterialInfo



  !---------------------------------------------------------------------
  ! STUB: Category registry initializers (domains removed)
  !---------------------------------------------------------------------
  SUBROUTINE UF_Elastic_RegAllMats(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Elastic_RegAllMats

  SUBROUTINE UF_Hyp_RegAllMats(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Hyp_RegAllMats

  SUBROUTINE UF_Creep_RegAllMats(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Creep_RegAllMats

  SUBROUTINE UF_Viscoelastic_InitReg(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Viscoelastic_InitReg

  SUBROUTINE UF_Viscoelastic_RegAllMats(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Viscoelastic_RegAllMats

  SUBROUTINE UF_Damage_InitializeRegistry(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Damage_InitializeRegistry

  SUBROUTINE UF_Dmg_RegAllMats(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Dmg_RegAllMats

  SUBROUTINE UF_Comp_InitReg(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Comp_InitReg

  SUBROUTINE UF_Comp_RegAllMats(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_Comp_RegAllMats

  !---------------------------------------------------------------------
  ! STUB: Material validation routines (domains removed)
  !---------------------------------------------------------------------

  SUBROUTINE UF_AnisotropicElastic_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_AnisotropicElastic_ValidProps

  SUBROUTINE UF_ArrudaBoyceHyp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_ArrudaBoyceHyp_ValidProps

  SUBROUTINE UF_BrittleDmg_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_BrittleDmg_ValidProps

  SUBROUTINE UF_CamClay_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_CamClay_ValidateProps

  SUBROUTINE UF_DruckerPrager_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_DruckerPrager_ValidateProps

  SUBROUTINE UF_DuctileDmg_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_DuctileDmg_ValidProps

  SUBROUTINE UF_FatigueDmg_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_FatigueDmg_ValidProps

  SUBROUTINE UF_FiberReinfComp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_FiberReinfComp_ValidProps

  SUBROUTINE UF_GarofaloCreep_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_GarofaloCreep_ValidProps

  SUBROUTINE UF_Hill_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_Hill_ValidateProps

  SUBROUTINE UF_HyperfoamHyp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_HyperfoamHyp_ValidProps

  SUBROUTINE UF_IsotropicElastic_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_IsotropicElastic_ValidProps

  SUBROUTINE UF_JohnsonCook_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_JohnsonCook_ValidateProps

  SUBROUTINE UF_LamComp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_LamComp_ValidProps

  SUBROUTINE UF_MRHyp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_MRHyp_ValidProps

  SUBROUTINE UF_MarlowHyp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_MarlowHyp_ValidProps

  SUBROUTINE UF_MohrCoulomb_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_MohrCoulomb_ValidateProps

  SUBROUTINE UF_NeoHookeanHyp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_NeoHookeanHyp_ValidProps

  SUBROUTINE UF_NortonCreep_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_NortonCreep_ValidateProps

  SUBROUTINE UF_OgdenHyp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_OgdenHyp_ValidProps

  SUBROUTINE UF_PorousElastic_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_PorousElastic_ValidProps

  SUBROUTINE UF_ProgDmg_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_ProgDmg_ValidProps

  SUBROUTINE UF_PronyViscoelastic_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_PronyViscoelastic_ValidProps

  SUBROUTINE UF_ThermalDmg_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_ThermalDmg_ValidProps

  SUBROUTINE UF_TransverseIsoElastic_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_TransverseIsoElastic_ValidProps

  SUBROUTINE UF_VanDerWaalsHyp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_VanDerWaalsHyp_ValidProps

  SUBROUTINE UF_VonMises_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_VonMises_ValidateProps

  SUBROUTINE UF_YeohHyp_ValidProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
  END SUBROUTINE UF_YeohHyp_ValidProps

END MODULE MD_Mat_Lib