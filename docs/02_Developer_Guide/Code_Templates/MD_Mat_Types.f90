!===============================================================================
! Module: MD_Mat_Types                                           [Template v3.1]
! Layer:  L3_MD — Model Description Layer (Core)
! Domain: Material — Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc / State / Algo three-type system shared by ALL material
!   families at the MD_ (model-description) layer.
!
!   NOTE (v3.1 design): MD_ layer does NOT carry a Ctx type (see Part VII §2,
!   Asymmetric Matrix).  The Ctx for material computation lives in PH_Mat_Types.
!
! Type roles (v3.1):
!   MD_Mat_Base_Desc  – Material parameters & identity (ABSTRACT, extended by
!                       each material model via EXTENDS)
!   MD_Mat_Base_State – Full material point state: responses + history (ABSTRACT,
!                       extended for model-specific internal variables)
!   MD_Mat_Base_Algo  – Analysis-phase configuration only: integration scheme,
!                       tangent flag, etc.  NO iteration-control fields here
!                       (those belong to PH_Mat_Base_Algo — see Part VIII §5).
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!
! v3.1 changes vs existing MD_Mat_Types.f90:
!   - Removed: MD_Mat_Ctx_Base  (migrated → PH_Mat_Types :: PH_Mat_Base_Ctx)
!   - Removed: MD_Mat_State_Base.pnewdt (migrated → RT_Common_Types :: RT_Algo)
!   - Added:   MD_Mat_Base_State.stran(6)  / dfgrd0(3,3)  [漏洞L1修正]
!   - Removed: MD_Mat_Algo_Base.max_iter / tolerance / pnewdt_*
!              (migrated → PH_Mat_Types :: PH_Mat_Base_Algo)
!   - Renamed: MD_Mat_Desc_Base → MD_Mat_Base_Desc  (suffix = type-class)
!              MD_Mat_State_Base → MD_Mat_Base_State
!              MD_Mat_Algo_Base  → MD_Mat_Base_Algo
!===============================================================================
! v3.2 changes vs v3.1:
!   - Added: Material family enum constants (MAT_FAMILY_XXX) covering all
!            Abaqus user subroutines: UMAT/VUMAT/CREEP/UEXPAN/UHARD/UHYPER/
!            UANISOHYPER_INV/UANISOHYPER_STRAIN/UCREEPNETWORK/UMULLINS
!   - Added: MD_Mat_Subrt_Desc — per-subroutine Desc (maps each Abaqus routine)
!   - Added: CREEP-specific: creep_law, A_creep, n_creep, Q_creep
!   - Added: UEXPAN-specific: thermal_exp(3,3)
!   - Added: UHARD-specific: yield_stress, H_iso, H_kin
!   - Added: UHYPER-specific: C10/C01/D1 hyperelastic parameters
!   - Rationale: Every Abaqus user subroutine → one dedicated Desc extension
!   - Baseline refresh: comments aligned to IF_Err_Brg structured-status
!     vocabulary (%status_code, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Mat_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_Base_Desc
  PUBLIC :: MD_Mat_Base_State
  PUBLIC :: MD_Mat_Base_Algo

  !-- Material family/subroutine enum constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UMAT            = 1_i4  ! UMAT (Std)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_VUMAT           = 2_i4  ! VUMAT (Exp)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_CREEP           = 3_i4  ! CREEP  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UEXPAN          = 4_i4  ! UEXPAN  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UHARD           = 5_i4  ! UHARD  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UHYPER          = 6_i4  ! UHYPER  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UANISOHYPER_INV = 7_i4  ! UANISOHYPER_INV  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UANISOHYPER_STR = 8_i4  ! UANISOHYPER_STRAIN  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UHYPEL          = 9_i4  ! UHYPEL  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UMULLINS        = 10_i4 ! UMULLINS  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UCREEPNETWORK   = 11_i4 ! UCREEPNETWORK  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_MAT_FAMILY_UTRS            = 12_i4 ! U_TRS (thermo-rheological)  ! migrated

  !-----------------------------------------------------------------------------
  ! ① DESC Base — Material Descriptor
  !    ABSTRACT: each model provides a concrete EXTENDS with model parameters.
  !    ValidateProps / InitFromProps are DEFERRED → must be implemented.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, ABSTRACT :: MD_Mat_Base_Desc
    !-- Identity & metadata (common to ALL material models)
    INTEGER(i4)       :: mat_id     = 0    ! Material ID (MAT_ID_XXX constant)
    INTEGER(i4)       :: mat_family = 0    ! Family enum (ELA/PLG/DMG/HYP/…)
    CHARACTER(LEN=64) :: model_name = ''   ! Human-readable label
    LOGICAL           :: is_initialized = .FALSE.
    !-- Density (universal for continuum mechanics)
    REAL(wp) :: rho = 0.0_wp   ! Density [kg/m³]
    !
    ! NOTE: Model-specific parameters (E, nu, cohesion, yield_stress, …)
    ! are NOT here. Each concrete material model EXTENDS this base type
    ! and declares its own parameters in the extended TYPE definition,
    ! e.g. MD_Mat_ELA_Desc { E, nu } or MD_Mat_MohrCoulomb_Desc { cohesion, friction_angle }.
  CONTAINS
    !-- Deferred: validate props array; set status on error
    PROCEDURE(mat_desc_iface), DEFERRED :: ValidateProps
    !-- Deferred: fill TYPE fields from flat props(:) array
    PROCEDURE(mat_desc_iface), DEFERRED :: InitFromProps
  END TYPE MD_Mat_Base_Desc

  ABSTRACT INTERFACE
    SUBROUTINE mat_desc_iface(self, nprops, props, st)
      IMPORT :: wp, i4, ErrorStatusType, MD_Mat_Base_Desc
      IMPLICIT NONE
      CLASS(MD_Mat_Base_Desc), INTENT(INOUT) :: self
      INTEGER(i4),             INTENT(IN)    :: nprops
      REAL(wp),                INTENT(IN)    :: props(:)
      TYPE(ErrorStatusType),   INTENT(OUT)   :: st
    END SUBROUTINE
  END INTERFACE

  !-----------------------------------------------------------------------------
  ! ② STATE Base — Material Point State
  !    ABSTRACT: model-specific types EXTEND this for extra internal variables.
  !
  !    v3.1 field assignment rationale:
  !      stress / statev / ddsdde   → output responses
  !      stran  / dfgrd0            → "known past" at increment START (history)
  !                                   ← [L1 fix] previously missing!
  !      sse/spd/scd/rpl / ddsddt / drplde / drpldt  → energy & thermal I/O
  !      converged / iterations     → convergence bookkeeping
  !
  !    NOT here:
  !      pnewdt   → bare REAL(wp) INTENT(INOUT) interface parameter (v4.0;
  !                  initialise with RT_PNEWDT_NO_CHANGE = 1.0_wp)
  !      dstran   → PH_Mat_Base_Ctx (increment driving input, NOT history)
  !      dfgrd1   → PH_Mat_Base_Ctx (increment-end deformation gradient)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, ABSTRACT :: MD_Mat_Base_State
    !-- Output: constitutive response
    REAL(wp)              :: stress(6)    = 0.0_wp  ! IO  STRESS   Cauchy stress σ [Pa]
    REAL(wp), POINTER :: statev(:)              ! IO  STATEV   solution-dep. state vars
    REAL(wp)              :: ddsdde(6,6)  = 0.0_wp  !  O  DDSDDE   consistent tangent C_tan
    !-- Input: history state at increment START ("known past")   [L1 fix]
    REAL(wp) :: stran(6)   = 0.0_wp  ! I   STRAN   strain at start of increment
    REAL(wp) :: dfgrd0(3,3)= 0.0_wp  ! I   DFGRD0  deformation gradient F₀ at start
    !-- Energy & thermal  (I/O as per ABAQUS convention)
    REAL(wp) :: elastic_energy = 0.0_wp  ! IO  SSE     elastic strain energy density
    REAL(wp) :: plastic_work   = 0.0_wp  ! IO  SPD     plastic dissipation density
    REAL(wp) :: creep_dissip   = 0.0_wp  ! IO  SCD     creep dissipation density
    REAL(wp) :: rpl            = 0.0_wp  !  O  RPL     volumetric heat generation rate
    !   ddsddt / drplde size = 6 = NTENS for 3-D (NDI=3, NSHR=3);
    !   for plane-stress elements NTENS=4 — concrete subclasses may override.
    REAL(wp) :: ddsddt(6)      = 0.0_wp  !  O  DDSDDT  ∂σ/∂T  (NTENS components)
    REAL(wp) :: drplde(6)      = 0.0_wp  !  O  DRPLDE  ∂RPL/∂ε (NTENS components)
    REAL(wp) :: drpldt         = 0.0_wp  !  O  DRPLDT  ∂RPL/∂T
    !-- Convergence bookkeeping (internal only, not passed to ABAQUS)
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_Base_State

  !-----------------------------------------------------------------------------
  ! ③ ALGO Base — Analysis-Phase Configuration
  !    CONCRETE: used directly or extended.
  !    Scope: "how to solve" configuration set BEFORE the analysis starts.
  !
  !    v3.1 rule (principle ⑬ ALGO SPLIT MD vs PH):
  !      MD_Mat_Base_Algo  = pre-analysis configuration (scheme, flags)
  !      PH_Mat_Base_Algo  = per-increment iteration control (max_iter, tol, …)
  !
  !    Fields intentionally ABSENT from MD_Mat_Base_Algo:
  !      max_iter, tolerance, pnewdt_min, pnewdt_max, auto_cut
  !      → those live in PH_Mat_Types :: PH_Mat_Base_Algo
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_Base_Algo
    !-- Integration scheme
    INTEGER(i4) :: integ_scheme    = 1       ! 1=implicit, 2=explicit, 3=midpoint
    REAL(wp)    :: theta           = 1.0_wp  ! Generalised mid-point θ (0=explicit,1=implicit)
    INTEGER(i4) :: ndi   = 3_i4
    INTEGER(i4) :: nshr  = 3_i4
    INTEGER(i4) :: ntens = 6_i4
    !-- Tangent computation
    LOGICAL :: compute_tangent  = .TRUE.  ! Compute consistent tangent?
    LOGICAL :: use_algorithmic  = .TRUE.  ! Algorithmic (consistent) vs continuum tangent
    !-- Optional diagnostics flag
    LOGICAL :: print_debug      = .FALSE.
  END TYPE MD_Mat_Base_Algo

  !-----------------------------------------------------------------------------
  ! ④ Subroutine-specific Desc extensions (CONCRETE, each maps to one Abaqus routine)
  !   Naming rule:  MD_Mat_<SubrtCode>_Desc
  !   Usage: EXTEND MD_Mat_Base_Desc and add routine-specific parameters.
  !-----------------------------------------------------------------------------

  !-- CREEP / UCREEP: creep law parameters
  TYPE, PUBLIC :: MD_Mat_CREEP_Desc
    INTEGER(i4) :: creep_law   = 1_i4    ! 1=power, 2=exp, 3=user-defined
    REAL(wp)    :: A_creep     = 0.0_wp  ! Creep coefficient A
    REAL(wp)    :: n_creep     = 1.0_wp  ! Stress exponent n
    REAL(wp)    :: Q_creep     = 0.0_wp  ! Activation energy Q [J/mol]
    REAL(wp)    :: R_gas       = 8.314_wp ! Gas constant [J/(mol·K)]
    INTEGER(i4) :: temp_depend = 0_i4    ! 0=no, 1=Arrhenius
  END TYPE MD_Mat_CREEP_Desc

  !-- UEXPAN: thermal/field expansion parameters
  TYPE, PUBLIC :: MD_Mat_UEXPAN_Desc
    REAL(wp) :: alpha_iso     = 0.0_wp      ! Isotropic CTE [1/K]
    REAL(wp) :: alpha_aniso(6)= 0.0_wp      ! Anisotropic CTE (Voigt 6)
    LOGICAL  :: is_anisotropic= .FALSE.     ! Anisotropic expansion flag
    INTEGER(i4) :: nfield_dep = 0_i4        ! No. of field-dependent tables
  END TYPE MD_Mat_UEXPAN_Desc

  !-- UHARD: user hardening law parameters
  TYPE, PUBLIC :: MD_Mat_UHARD_Desc
    REAL(wp) :: sigma_y0    = 0.0_wp   ! Initial yield stress [Pa]
    REAL(wp) :: H_iso       = 0.0_wp   ! Isotropic hardening modulus [Pa]
    REAL(wp) :: H_kin       = 0.0_wp   ! Kinematic hardening modulus [Pa]
    REAL(wp) :: peeq_max    = 1.0_wp   ! Max equiv. plastic strain cap
    INTEGER(i4) :: hard_law = 1_i4     ! 1=linear, 2=power, 3=tabular
  END TYPE MD_Mat_UHARD_Desc

  !-- UHYPER: hyperelastic user model (Neo-Hookean / Mooney-Rivlin base)
  TYPE, PUBLIC :: MD_Mat_UHYPER_Desc
    REAL(wp) :: C10 = 0.0_wp   ! Mooney-Rivlin C10 [Pa]
    REAL(wp) :: C01 = 0.0_wp   ! Mooney-Rivlin C01 [Pa]
    REAL(wp) :: D1  = 0.0_wp   ! Compressibility D1 [1/Pa]
    INTEGER(i4) :: hyper_order = 2_i4  ! 1=Neo-Hookean, 2=M-R, 3=higher
    INTEGER(i4) :: n_terms     = 1_i4  ! Number of Prony terms (if visco)
  END TYPE MD_Mat_UHYPER_Desc

  !-- UANISOHYPER_INV: anisotropic hyperelastic (invariant-based)
  TYPE, PUBLIC :: MD_Mat_UANISOHYPER_INV_Desc
    INTEGER(i4) :: n_fib_fam  = 1_i4       ! Number of fiber families
    REAL(wp)    :: fib_dir(3,4) = 0.0_wp   ! Fiber directions (up to 4)
    REAL(wp)    :: k1          = 0.0_wp    ! HGO k1 [Pa]
    REAL(wp)    :: k2          = 0.0_wp    ! HGO k2 [-]
    REAL(wp)    :: kappa_fib   = 0.0_wp    ! Fiber dispersion parameter
  END TYPE MD_Mat_UANISOHYPER_INV_Desc

  !-- UMULLINS: Mullins effect (damage in elastomers)
  TYPE, PUBLIC :: MD_Mat_UMULLINS_Desc
    REAL(wp) :: eta_inf  = 1.0_wp   ! Permanent set parameter
    REAL(wp) :: r_mul    = 0.0_wp   ! Mullins r
    REAL(wp) :: m_mul    = 0.0_wp   ! Mullins m [Pa]
    REAL(wp) :: beta_mul = 0.0_wp   ! Mullins beta
  END TYPE MD_Mat_UMULLINS_Desc

  !-- USDFLD: user-defined field variable parameters
  !   Corresponds to the USDFLD / VUSDFLD subroutine field-dependency Desc.
  TYPE, PUBLIC :: MD_Mat_USDFLD_Desc
    INTEGER(i4) :: nfield   = 0_i4   ! Number of field variables (NFIELD)
    INTEGER(i4) :: nstatv   = 0_i4   ! Number of solution-dependent state vars
    LOGICAL     :: use_user_pts = .FALSE.  ! Use user-defined field points
    !-- Field variable IDs (which Abaqus field variables are used)
    INTEGER(i4), ALLOCATABLE :: field_ids(:)   ! field_ids(nfield)
  END TYPE MD_Mat_USDFLD_Desc

  !-- UHYPEL: user hyperelastic (strain-energy-based, no invariants)
  TYPE, PUBLIC :: MD_Mat_UHYPEL_Desc
    INTEGER(i4) :: n_props  = 0_i4    ! Number of material properties
    REAL(wp), ALLOCATABLE :: props(:) ! Material parameters
    INTEGER(i4) :: formulation = 1_i4 ! 1=compressible, 2=nearly-incompressible
  END TYPE MD_Mat_UHYPEL_Desc

  !-- UCREEPNETWORK: creep in network polymer model
  TYPE, PUBLIC :: MD_Mat_UCREEPNETWORK_Desc
    INTEGER(i4) :: n_networks = 1_i4  ! Number of networks
    REAL(wp) :: mu_inf  = 0.0_wp      ! Long-term shear modulus
    REAL(wp) :: eta_0   = 0.0_wp      ! Reference viscosity
    INTEGER(i4) :: creep_law = 1_i4   ! Creep law type
  END TYPE MD_Mat_UCREEPNETWORK_Desc

  !-- UTRS: thermo-rheological simple material (time-temperature superposition)
  TYPE, PUBLIC :: MD_Mat_UTRS_Desc
    REAL(wp) :: t_ref   = 293.15_wp   ! Reference temperature [K]
    REAL(wp) :: c1      = 17.44_wp    ! WLF constant C1
    REAL(wp) :: c2      = 51.6_wp     ! WLF constant C2 [K]
    INTEGER(i4) :: shift_law = 1_i4   ! 1=WLF, 2=Arrhenius, 3=user
  END TYPE MD_Mat_UTRS_Desc

  !-- UANISOHYPER_STRAIN: anisotropic hyperelastic (strain-based)
  TYPE, PUBLIC :: MD_Mat_UANISOHYPER_STR_Desc
    INTEGER(i4) :: n_fib_fam = 1_i4     ! Number of fiber families
    REAL(wp)    :: fib_dir(3,4) = 0.0_wp ! Fiber directions (up to 4)
    REAL(wp)    :: kappa  = 0.0_wp       ! Fiber dispersion
    INTEGER(i4) :: strain_form = 1_i4   ! Strain formulation type
  END TYPE MD_Mat_UANISOHYPER_STR_Desc

  !-----------------------------------------------------------------------------
  ! MD_Mat_UMAT_Desc — UMAT user-material model description (INP-driven)
  !   Corresponds to *MATERIAL + *USER MATERIAL, CONSTANTS=n
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_UMAT_Desc
    CHARACTER(LEN=80) :: mat_name    = ' '   ! material name (*MATERIAL, NAME=)
    INTEGER(i4)       :: nprops      = 0_i4  ! number of material constants (CONSTANTS=)
    REAL(wp), ALLOCATABLE :: props(:)         ! material constants array [nprops]
    INTEGER(i4)       :: nstatv      = 0_i4  ! number of solution-dependent state vars
    INTEGER(i4)       :: ntens       = 6_i4  ! total number of stress components
    INTEGER(i4)       :: ndi         = 3_i4  ! number of direct stress components
    INTEGER(i4)       :: nshr        = 3_i4  ! number of shear stress components
    LOGICAL           :: large_strain= .FALSE.  ! NLGEOM flag
    LOGICAL           :: is_active   = .FALSE.
  END TYPE MD_Mat_UMAT_Desc

  !-----------------------------------------------------------------------------
  ! MD_Mat_VUMAT_Desc — VUMAT vectorised user-material description (INP-driven)
  !   *USER MATERIAL with DEPVAR + LCCM or CHARACTERISTICS
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_VUMAT_Desc
    CHARACTER(LEN=80) :: mat_name    = ' '
    INTEGER(i4)       :: nprops      = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4)       :: nstatv      = 0_i4
    INTEGER(i4)       :: nfieldv     = 0_i4  ! number of predefined field vars
    LOGICAL           :: large_strain= .FALSE.
    LOGICAL           :: is_active   = .FALSE.
  END TYPE MD_Mat_VUMAT_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Mat_UANISOHYPER_Desc
  !> @brief 各向异性超弹性材料描述（UANISOHYPER子程序，Desc类）
  !>
  !> 存储各向异性超弹性势函数所需的不变量类型、纤维方向数
  !> 及增量或全量应变能形式选择。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_UANISOHYPER_Desc
    INTEGER(i4)       :: n_fiber_dirs  = 1_i4    ! 纤维方向数（1或2）
    INTEGER(i4)       :: n_invariants  = 5_i4    ! 使用不变量数（≤11）
    LOGICAL           :: incompressible= .TRUE.  ! 是否不可压
    LOGICAL           :: incremental   = .FALSE. ! 增量型（.T.）或全量型（.F.）
    INTEGER(i4)       :: nstatv        = 0_i4    ! 状态变量数
    INTEGER(i4)       :: nprops        = 0_i4    ! 材料参数数
    LOGICAL           :: is_active     = .FALSE. ! 是否激活
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_UANISOHYPER_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Mat_UMATHT_Desc
  !> @brief UMATHT 热传导材料描述（Standard热斶，Desc类）
  !>
  !> 定义材料热传导行为：内能密度、燭通量及其导数。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_UMATHT_Desc
    INTEGER(i4)       :: nstatv       = 0_i4    ! 状态变量数
    INTEGER(i4)       :: nprops       = 0_i4    ! 材料参数数
    LOGICAL           :: coupled_t = .TRUE.  ! 是否热耦合
    LOGICAL           :: is_active    = .FALSE.  ! 是否激活
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_UMATHT_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Mat_VUHARD_Desc
  !> @brief VUHARD Explicit硬化次序描述（Desc类）
  !>
  !> Abaqus/Explicit屈服硬化用户子程序描述。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_VUHARD_Desc
    INTEGER(i4)       :: nprops       = 0_i4    ! 材料参数数
    LOGICAL           :: kinematic_hard = .FALSE. ! 随动硬化标志
    LOGICAL           :: combined_hard  = .FALSE. ! 混合硬化标志
    LOGICAL           :: is_active      = .FALSE.  ! 是否激活
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_VUHARD_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Mat_UANISOHYPER_STRAIN_Desc
  !> @brief UANISOHYPER_STRAIN Standard局格林应变基各向异超弹性描述（Desc类）
  !>
  !> 基于格林-布朗应变张量的各向异超弹性拟合，与不变量形式区别。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_UANISOHYPER_STRAIN_Desc
    INTEGER(i4)       :: n_fiber_dirs  = 1_i4    ! 纤维方向数
    LOGICAL           :: incompressible = .TRUE.  ! 不可压标志
    INTEGER(i4)       :: nstatv        = 0_i4    ! 状态变量数
    INTEGER(i4)       :: nprops        = 0_i4    ! 材料参数数
    LOGICAL           :: is_active     = .FALSE.  ! 是否激活
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_UANISOHYPER_STRAIN_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Mat_VUANISOHYPER_INV_Desc
  !> @brief VUANISOHYPER_INV Explicit各向异超弹性（不变量形式）描述（Desc类）
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_VUANISOHYPER_INV_Desc
    INTEGER(i4)       :: n_fiber_dirs  = 1_i4
    INTEGER(i4)       :: n_invariants  = 5_i4
    LOGICAL           :: incompressible = .TRUE.
    INTEGER(i4)       :: nstatv        = 0_i4
    INTEGER(i4)       :: nprops        = 0_i4
    LOGICAL           :: is_active     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_VUANISOHYPER_INV_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Mat_VUANISOHYPER_STRAIN_Desc
  !> @brief VUANISOHYPER_STRAIN Explicit局格林应变基各向异超弹性描述（Desc类）
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_VUANISOHYPER_STRAIN_Desc
    INTEGER(i4)       :: n_fiber_dirs  = 1_i4
    LOGICAL           :: incompressible = .TRUE.
    INTEGER(i4)       :: nstatv        = 0_i4
    INTEGER(i4)       :: nprops        = 0_i4
    LOGICAL           :: is_active     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_VUANISOHYPER_STRAIN_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Mat_UCREEPNETWORK_Desc
  !> @brief UCREEPNETWORK 并联流变学框架葡变描述（Desc类）
  !>
  !> 并联流变学框架（PRF）中每个网络的蚌变法则描述。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_UCREEPNETWORK_Desc
    INTEGER(i4)       :: network_id    = 0_i4    ! 网络编号
    INTEGER(i4)       :: nstatv        = 0_i4    ! 状态变量数
    INTEGER(i4)       :: nprops        = 0_i4    ! 材料参数数
    LOGICAL           :: swelling      = .FALSE.  ! 是否包含娨居
    LOGICAL           :: is_active     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_UCREEPNETWORK_Desc

  ! ----------------------------------------------------------------
  !> @type MD_Mat_VUMULLINS_Desc
  !> @brief VUMULLINS Explicit Mullins 损伤变量描述（Desc 类）
  !>
  !> Abaqus/Explicit Mullins 效应损伤变量用户子程序描述。
  ! ----------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mat_VUMULLINS_Desc
    INTEGER(i4)       :: nprops        = 0_i4    ! 材料参数数
    INTEGER(i4)       :: nstatv        = 0_i4    ! 状态变量数
    LOGICAL           :: is_active     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mat_VUMULLINS_Desc

  !=============================================================================
  ! MD_Mat_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Mat_Domain
    TYPE(MD_Mat_Base_Desc),  POINTER :: desc(:)   ! Polymorphic array [n_mats]
    TYPE(MD_Mat_Base_State), POINTER :: state(:)  ! Polymorphic array [n_mats]
    TYPE(MD_Mat_Base_Algo),  POINTER :: algo(:)   ! Polymorphic array [n_mats]
    INTEGER(i4) :: n_mats      = 0_i4
    INTEGER(i4) :: max_mats    = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen      = .FALSE.
  CONTAINS
    PROCEDURE :: Init      => MD_Mat_Domain_Init
    PROCEDURE :: Finalize  => MD_Mat_Domain_Finalize
    PROCEDURE :: WriteBack => MD_Mat_WriteBack
  END TYPE MD_Mat_Domain

CONTAINS

  SUBROUTINE MD_Mat_Domain_Init(this, cap_mats, status)
    CLASS(MD_Mat_Domain),  INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: cap_mats
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Mat_Domain_Finalize(this)
    IF (cap_mats < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Mat_Domain_Init: cap_mats must be >= 1'
      RETURN
    END IF
    ALLOCATE(this%desc(cap_mats))
    ALLOCATE(this%state(cap_mats))
    ALLOCATE(this%algo(cap_mats))
    this%n_mats      = 0_i4
    this%max_mats    = cap_mats
    this%initialized = .TRUE.
    this%frozen      = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_Domain_Init

  SUBROUTINE MD_Mat_Domain_Finalize(this)
    CLASS(MD_Mat_Domain), INTENT(INOUT) :: this
    INTEGER(i4) :: i
    IF (.NOT. this%initialized) RETURN
    IF (ASSOCIATED(this%desc)) THEN
      DO i = 1, this%n_mats
        IF (ASSOCIATED(this%desc(i))) DEALLOCATE(this%desc(i))
      END DO
      DEALLOCATE(this%desc)
    END IF
    IF (ASSOCIATED(this%state)) THEN
      DO i = 1, this%n_mats
        IF (ASSOCIATED(this%state(i))) DEALLOCATE(this%state(i))
      END DO
      DEALLOCATE(this%state)
    END IF
    IF (ASSOCIATED(this%algo)) THEN
      DO i = 1, this%n_mats
        IF (ASSOCIATED(this%algo(i))) DEALLOCATE(this%algo(i))
      END DO
      DEALLOCATE(this%algo)
    END IF
    this%n_mats      = 0_i4
    this%max_mats    = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_Mat_Domain_Finalize

  SUBROUTINE MD_Mat_WriteBack(this, mat_id, new_state, status)
    CLASS(MD_Mat_Domain),  INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: mat_id
    TYPE(MD_Mat_Base_State), INTENT(IN)  :: new_state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. mat_id < 1_i4 .OR. mat_id > this%n_mats) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'MD_Mat_WriteBack: invalid mat_id=', mat_id
      RETURN
    END IF
    this%state(mat_id) = new_state
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_WriteBack

END MODULE MD_Mat_Types
