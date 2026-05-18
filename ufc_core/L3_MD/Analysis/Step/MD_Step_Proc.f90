!===============================================================================
! MODULE:   MD_Step_Proc
! LAYER:    L3_MD
! SUBDOMAIN Analysis · Step（域缩 **Step**）
! ROLE:      _Proc — **`PROC_*`** 枚举 + **`UF_*`** 过程控制 **Desc** 族 + **`UF_StepDef` / `UF_StepManager`**
! BRIEF:    分析过程类型常量（28+ 子变体）与 **Legacy 步定义 / 步管理器**；**`ProcTo*`** 路由
!===============================================================================
!
!---------------------------------------------------------------------------
! 功能模块二元结构（本文件：**数据结构 · 过程元数据 TYPE + 枚举** + **过程算法 · TBP / Map**；
!   **索引域 Desc/Domain/TBP** 在 **`MD_Step_Mgr`**；**State/Ctx 四型半柱** 在 **`MD_Step_Def`**；
!   **Populate 同步** 在 **`MD_Step_Sync`**）
!---------------------------------------------------------------------------
!
!   [1] 数据结构（四型 + Args + 主/辅 + 嵌套 · 并列 · 主从）
!
!       **TYPE / 常量命名**
!       — **层前缀**：**`MD_`** | **`PH_`** | **`RT_`**。  
!       — **`PROC_*` / `NLGEOM_*` / `SSD_*`**：**INTEGER PARAMETER** — **过程族真值**，供 **`MD_Step_Desc%procedure`**、
!         L5 **`RT_STEP_TYPE_*`** / **`RT_SOLVER_*`** 映射消费。  
!       — **`UF_*Control` / `UF_*Manager` / `UF_*Params`**：**Legacy 过程配置片段** — **并列** 于 **`UF_StepDef`**，
!         按 **`PROC_*`** 分支 **填充 / 忽略**（**主** 容器 **`UF_StepDef`**，**从** 各 **Ctrl** 块）。  
!       — **`UF_StepManager`**：**Legacy Ctx** 语义 — **`steps(:)`** + **当前步指针**；与 **`MD_Step_Domain`** **对照
!         阅读**（**新柱** vs **旧树**）。  
!       — **`MD_Model_StepConfig`** 等：**小颗粒 Desc** — 与 **模型级步计数** 相关。  
!       — **Args（+1）**：本模块 **UF 步 TBP** 以 **显式标量形参** 为主；**结构化 `*_Arg`** 归 **Mgr / L5**。
!
!   [2] 过程算法（空间维 · 时间维 · 动作维）— **`CONTAINS`**
!       — **时间维**：**`step_*` / `stepmgr_*`** — 单步 / 管理器 **生命周期**；**`ProcToRTStepType` /
!         `ProcToSolverType`** — **COLD** 映射。  
!       — **空间维**：**`UF_StepDef`** 内 **LoadBC / Output / pair_ids** 为 **Legacy 侧载**；**几何 / 集解析** 归
!         **Mesh / Ldbc**。  
!       — **动作维**：**`step_init` / `step_set_*` / `step_destroy`** — **Init / Mutate / Finalize**；**`UF_Step_AttachLoadDefs`**
!         — **Bind** Legacy **`loadDefs`** 指针供 L5。
!
! **依赖**：**`IF_*`**, **`MD_Load_Mgr`**, **`MD_LBC_Brg`**, **`MD_Out_Lib`**, **`MD_Step_ProcIDs`**, **`MD_Step_RT_Brg`** 等。  
! **非依赖**：**不** `USE` **`MD_Step_Mgr`**（防 **Proc ⇄ Mgr** 环；**Mgr** 单向 **USE** **Proc**）。
!
!===============================================================================
! Pilot: ufc-layer-l3-l4-l5-pilot.md — **PROC_*** + **UF_*** 控制块 (Depth≤3)
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Step | Role:Proc | FuncSet:PROC,UF_Step,Map | HotPath:No
!>>> UFC_L3_CONTRACT | Analysis/Step/CONTRACT.md
!
MODULE MD_Step_Proc
    USE IF_Prec_Core, ONLY: wp, i4
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR, IF_STATUS_WARN, &
                          IF_STATUS_UNSUPPORTED
    USE MD_Load_Mgr, ONLY: LoadDef
    USE MD_LBC_Brg, ONLY: UF_LoadBCManager
    USE MD_Out_Lib, ONLY: UF_OutputManager
    USE MD_Step_ProcIDs
    USE MD_Step_RT_Brg, ONLY: ProcToSolverType
    IMPLICIT NONE
    PRIVATE

    !---------------------------------------------------------------------------
    ! 能力上限；**`PROC_*` / `SSD_*`** 数值 SSOT 在 **`MD_Step_ProcIDs`**；**`ProcToSolverType`** 在 **`MD_Step_RT_Brg`**（DEP-001）。
    !---------------------------------------------------------------------------

    INTEGER(i4), PARAMETER, PUBLIC :: MAX_STEP_NAME = 64
    INTEGER(i4), PARAMETER, PUBLIC :: MAX_STEPS1 = 100

    PUBLIC :: PROC_STATIC, PROC_STATIC_RIKS, PROC_STATIC_PERTURBATION, PROC_VISCO, &
        PROC_DYNAMIC_IMPLICIT, PROC_DYNAMIC_EXPLICIT, PROC_DYNAMIC_SUBSPACE, PROC_MODAL_DYNAMIC, &
        PROC_DYNAMIC_CTD_EXPLICIT, PROC_ANNEAL, PROC_MODAL, PROC_BUCKLE, PROC_FREQUENCY, &
        PROC_RANDOM_RESPONSE, PROC_RESPONSE_SPECTRUM, PROC_COMPLEX_FREQUENCY, PROC_HEAT_TRANSFER, &
        PROC_MASS_DIFFUSION, PROC_COUPLED_TEMP_DISP, PROC_COUPLED_THERMAL_ELEC, PROC_COUPLED_TES, &
        PROC_PIEZOELECTRIC, PROC_ELECTROMAGNETIC, PROC_ACOUSTIC, PROC_GEOSTATIC, PROC_SOILS, &
        PROC_STEADY_STATE_TRANSPORT, PROC_SUBSTRUCTURE, SSD_MODAL, SSD_SUBSPACE, SSD_DIRECT, &
        ProcToSolverType

    INTEGER(i4), PARAMETER, PUBLIC :: NLGEOM_OFF = 0
    INTEGER(i4), PARAMETER, PUBLIC :: NLGEOM_ON = 1

    INTEGER(i4), PARAMETER, PUBLIC :: INTEG_BACKWARD_EULER = 1
    INTEGER(i4), PARAMETER, PUBLIC :: INTEG_NEWMARK_BETA = 2
    INTEGER(i4), PARAMETER, PUBLIC :: INTEG_HHT_ALPHA = 3
    INTEGER(i4), PARAMETER, PUBLIC :: INTEG_CENTRAL_DIFF = 4
    INTEGER(i4), PARAMETER, PUBLIC :: INTEG_RUNGE_KUTTA = 5

    !---------------------------------------------------------------------------
    ! TYPE:  UF_IncrementControl
    ! KIND:  Algo
    ! DESC:  Time increment control — initial/min/max inc, cutback, auto.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_IncrementControl
        REAL(wp) :: initial_inc = 0.1_wp
        REAL(wp) :: min_inc = 1.0E-10_wp
        REAL(wp) :: max_inc = 1.0_wp
        INTEGER(i4) :: max_num_inc = 1000
        LOGICAL :: auto_increment = .TRUE.
        REAL(wp) :: cutback_factor = 0.25_wp
        REAL(wp) :: increase_factor = 1.5_wp
        INTEGER(i4) :: opt_iter = 8
    END TYPE UF_IncrementControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_SolutionControl
    ! KIND:  Algo
    ! DESC:  Solution control — convergence tolerances, line search, stabilize.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_SolutionControl
        INTEGER(i4) :: max_iterations = 16
        REAL(wp) :: residual_tol = 1.0E-5_wp
        REAL(wp) :: correction_tol = 1.0E-3_wp
        REAL(wp) :: energy_tol = 1.0E-4_wp
        LOGICAL :: check_residual = .TRUE.
        LOGICAL :: check_correction = .TRUE.
        LOGICAL :: check_energy = .FALSE.
        LOGICAL :: line_search = .FALSE.
        REAL(wp) :: line_search_tol = 0.25_wp
        LOGICAL :: stabilize = .FALSE.
        REAL(wp) :: stabilize_factor = 2.0E-4_wp
        REAL(wp) :: stabilize_energy_fraction = 0.05_wp
    END TYPE UF_SolutionControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_RiksControl
    ! KIND:  Algo
    ! DESC:  Arc-length (Riks) parameters — arc length limits, psi, max incr.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_RiksControl
        REAL(wp) :: arc_length_init = 0.1_wp
        REAL(wp) :: arc_length_max = 1.0_wp
        REAL(wp) :: arc_length_min = 1.0E-5_wp
        REAL(wp) :: psi = 1.0_wp
        INTEGER(i4) :: max_increments = 500_i4
        INTEGER(i4) :: max_iter_per_inc = 16_i4
    END TYPE UF_RiksControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ModalControl
    ! KIND:  Algo
    ! DESC:  Modal extraction control — modes, frequency range, Lanczos params.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: MODAL_LANCZOS = 1
    INTEGER(i4), PARAMETER, PUBLIC :: MODAL_SUBSPACE = 2
    TYPE, PUBLIC :: UF_ModalControl_Modes
        INTEGER(i4) :: n_modes          = 10_i4      ! Requested N_modes
        INTEGER(i4) :: n_modes_max      = 200_i4     ! Maximum modes
    END TYPE UF_ModalControl_Modes

    TYPE, PUBLIC :: UF_ModalControl_Freq
        REAL(wp)    :: freq_min         = 0.0_wp     ! Min frequency (Hz), 0=no lower bound
        REAL(wp)    :: freq_max         = 1.0E6_wp   ! Max frequency (Hz)
    END TYPE UF_ModalControl_Freq

    TYPE, PUBLIC :: UF_ModalControl_Solver
        INTEGER(i4) :: solver_type      = MODAL_LANCZOS ! Block Lanczos / Subspace
        INTEGER(i4) :: block_size       = 8_i4       ! Lanczos block size
        REAL(wp)    :: lanczos_tol      = 1.0E-8_wp  ! Lanczos convergence tolerance
        INTEGER(i4) :: max_lanczos_iter = 500_i4     ! Max Lanczos iterations
    END TYPE UF_ModalControl_Solver

    TYPE, PUBLIC :: UF_ModalControl_Flags
        LOGICAL     :: normalize_mass   = .TRUE.     ! Mass-normalize: phi^T M phi = I
        LOGICAL     :: include_prestress= .FALSE.    ! Include geometric stiffness K_sigma
        REAL(wp)    :: shift_freq       = 0.0_wp     ! Shift frequency (Hz)
        INTEGER(i4) :: residual_modes   = 0_i4       ! Residual modes count
    END TYPE UF_ModalControl_Flags

    TYPE, PUBLIC :: UF_ModalControl
        TYPE(UF_ModalControl_Modes)  :: modes
        TYPE(UF_ModalControl_Freq)   :: freq
        TYPE(UF_ModalControl_Solver) :: solver
        TYPE(UF_ModalControl_Flags)  :: flags
    END TYPE UF_ModalControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ModalStepDef
    ! KIND:  Desc
    ! DESC:  Modal step definition — procedure, modal control, output.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_ModalStepDef_Base
        CHARACTER(LEN=64)        :: name        = ""
        INTEGER(i4)              :: procedure   = PROC_MODAL   ! = 21
        INTEGER(i4)              :: nlgeom      = NLGEOM_OFF   ! Geometric nonlinearity flag
    END TYPE UF_ModalStepDef_Base

    TYPE, PUBLIC :: UF_ModalStepDef_Ctrl
        TYPE(UF_ModalControl)    :: modal_ctrl
        TYPE(UF_OutputManager)   :: output
    END TYPE UF_ModalStepDef_Ctrl

    TYPE, PUBLIC :: UF_ModalStepDef_Pre
        INTEGER(i4)              :: prestress_step_id = -1_i4   ! Preceding prestress step ID
    END TYPE UF_ModalStepDef_Pre

    TYPE, PUBLIC :: UF_ModalStepDef
        TYPE(UF_ModalStepDef_Base) :: base
        TYPE(UF_ModalStepDef_Ctrl) :: ctrl
        TYPE(UF_ModalStepDef_Pre)  :: pre
    END TYPE UF_ModalStepDef

    !---------------------------------------------------------------------------
    ! TYPE:  UF_SSDControl
    ! KIND:  Algo
    ! DESC:  Steady-state dynamics control — Modal/Subspace/Direct variants.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: FREQ_LOG    = 0   ! Logarithmic frequency spacing
    INTEGER(i4), PARAMETER, PUBLIC :: FREQ_LINEAR = 1   ! Linear frequency spacing
    INTEGER(i4), PARAMETER, PUBLIC :: DAMP_MODAL    = 1 ! Modal damping ratio per mode
    INTEGER(i4), PARAMETER, PUBLIC :: DAMP_RAYLEIGH  = 2 ! Rayleigh alpha+beta damping
    INTEGER(i4), PARAMETER, PUBLIC :: DAMP_STRUCTURAL= 3 ! Structural (hysteretic) damping
    TYPE, PUBLIC :: UF_SSDControl_Config
        INTEGER(i4) :: solution_method  = SSD_MODAL
        REAL(wp)    :: freq_start       = 1.0_wp
        REAL(wp)    :: freq_end         = 1000.0_wp
        INTEGER(i4) :: n_freq_points    = 200_i4
        INTEGER(i4) :: freq_spacing     = FREQ_LOG
        INTEGER(i4) :: damping_type     = DAMP_MODAL
    END TYPE UF_SSDControl_Config

    TYPE, PUBLIC :: UF_SSDControl_Modal
        INTEGER(i4) :: n_modes_used     = -1_i4
        REAL(wp)    :: modal_damping    = 0.02_wp
        INTEGER(i4) :: modal_base_step_id = -1_i4
        INTEGER(i4) :: residual_modes   = 0_i4
        LOGICAL     :: subspace_nondiag_damp = .FALSE.
    END TYPE UF_SSDControl_Modal

    TYPE, PUBLIC :: UF_SSDControl_Direct
        REAL(wp)    :: rayleigh_alpha   = 0.0_wp
        REAL(wp)    :: rayleigh_beta    = 1.0E-5_wp
        REAL(wp)    :: structural_damp  = 0.0_wp
        REAL(wp)    :: lu_reuse_tol     = 0.01_wp
        INTEGER(i4) :: max_reuse_steps  = 10_i4
        INTEGER(i4) :: ring_buffer_size = 30_i4
        LOGICAL     :: save_all_freqs   = .TRUE.
    END TYPE UF_SSDControl_Direct

    TYPE, PUBLIC :: UF_SSDControl_Config
        INTEGER(i4) :: solution_method  = SSD_MODAL
        REAL(wp)    :: freq_start       = 1.0_wp
        REAL(wp)    :: freq_end         = 1000.0_wp
        INTEGER(i4) :: n_freq_points    = 200_i4
        INTEGER(i4) :: freq_spacing     = FREQ_LOG
        INTEGER(i4) :: damping_type     = DAMP_MODAL
    END TYPE UF_SSDControl_Config

    TYPE, PUBLIC :: UF_SSDControl_Modal
        INTEGER(i4) :: n_modes_used     = -1_i4
        REAL(wp)    :: modal_damping    = 0.02_wp
        INTEGER(i4) :: modal_base_step_id = -1_i4
        INTEGER(i4) :: residual_modes   = 0_i4
        LOGICAL     :: subspace_nondiag_damp = .FALSE.
    END TYPE UF_SSDControl_Modal

    TYPE, PUBLIC :: UF_SSDControl_Direct
        REAL(wp)    :: rayleigh_alpha   = 0.0_wp
        REAL(wp)    :: rayleigh_beta    = 1.0E-5_wp
        REAL(wp)    :: structural_damp  = 0.0_wp
        REAL(wp)    :: lu_reuse_tol     = 0.01_wp
        INTEGER(i4) :: max_reuse_steps  = 10_i4
        INTEGER(i4) :: ring_buffer_size = 30_i4
        LOGICAL     :: save_all_freqs   = .TRUE.
    END TYPE UF_SSDControl_Direct

    TYPE, PUBLIC :: UF_SSDControl
        TYPE(UF_SSDControl_Config)  :: config
        TYPE(UF_SSDControl_Modal)   :: modal
        TYPE(UF_SSDControl_Direct)  :: direct
    END TYPE UF_SSDControl

    ! Backward-compat aliases for existing callers (phase-out with UF_SSDControl)
    ! UF_FreqControl: old Freq Response (PROC_06); maps to UF_SSDControl, SSD_MODAL
    INTEGER(i4), PARAMETER, PUBLIC :: FREQ_MODAL  = SSD_MODAL
    INTEGER(i4), PARAMETER, PUBLIC :: FREQ_DIRECT = SSD_DIRECT
    ! UF_SteadyStateControl: old SSD (PROC_08); maps to UF_SSDControl, SSD_DIRECT
    INTEGER(i4), PARAMETER, PUBLIC :: SS_DIRECT = SSD_DIRECT
    INTEGER(i4), PARAMETER, PUBLIC :: SS_MODAL  = SSD_MODAL
    INTEGER(i4), PARAMETER, PUBLIC :: BUCKLE_LANCZOS = 1
    INTEGER(i4), PARAMETER, PUBLIC :: BUCKLE_SUBSPACE = 2
    !---------------------------------------------------------------------------
    ! TYPE:  UF_BuckleControl
    ! KIND:  Algo
    ! DESC:  Buckling eigenvalue control — modes, Lanczos, shift, prestress.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_BuckleControl_Modes
        INTEGER(i4) :: n_buckling_modes  = 5_i4      ! Number of buckling modes
        INTEGER(i4) :: solver_type      = BUCKLE_LANCZOS
        INTEGER(i4) :: block_size       = 4_i4       ! Lanczos block size
    END TYPE UF_BuckleControl_Modes

    TYPE, PUBLIC :: UF_BuckleControl_Lanczos
        REAL(wp)    :: lanczos_tol      = 1.0E-6_wp  ! Lanczos convergence tolerance
        INTEGER(i4) :: max_lanczos_iter = 300_i4
        REAL(wp)    :: shift_value       = 0.0_wp    ! Eigenvalue shift
    END TYPE UF_BuckleControl_Lanczos

    TYPE, PUBLIC :: UF_BuckleControl_Flags
        LOGICAL     :: include_K_stress  = .TRUE.    ! Include stress stiffness K_sigma
        INTEGER(i4) :: prestress_step_id = -1_i4     ! Preceding prestress step ID
    END TYPE UF_BuckleControl_Flags

    TYPE, PUBLIC :: UF_BuckleControl
        TYPE(UF_BuckleControl_Modes)    :: modes
        TYPE(UF_BuckleControl_Lanczos)  :: lanczos
        TYPE(UF_BuckleControl_Flags)    :: flags
    END TYPE UF_BuckleControl

    !--------------------------------------------------------------------------
    ! NOTE: UF_SteadyStateControl is superseded by UF_SSDControl (see above).
    ! Retained as type alias for backward compatibility with RT_Step_Core,
    ! RT_Steady_Core, PH_LoadBC_Steady. Will be removed after full migration.
    !--------------------------------------------------------------------------
    ! (UF_SteadyStateControl removed; use UF_SSDControl with solution_method=SSD_DIRECT)

    !---------------------------------------------------------------------------
    ! TYPE:  UF_HeatTransControl
    ! KIND:  Algo
    ! DESC:  Heat transfer control — transient/steady, theta, conductivity.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: HT_TRANSIENT = 1
    INTEGER(i4), PARAMETER, PUBLIC :: HT_STEADY = 2
    TYPE, PUBLIC :: UF_HeatTransControl_Mode
        INTEGER(i4) :: analysis_mode    = HT_TRANSIENT
    END TYPE UF_HeatTransControl_Mode

    TYPE, PUBLIC :: UF_HeatTransControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.01_wp
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_HeatTransControl_Time

    TYPE, PUBLIC :: UF_HeatTransControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_HeatTransControl_Steps

    TYPE, PUBLIC :: UF_HeatTransControl_Solver
        REAL(wp)    :: theta_integration= 1.0_wp
        REAL(wp)    :: temp_tol         = 1.0E-3_wp
        REAL(wp)    :: flux_tol         = 1.0E-4_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_HeatTransControl_Solver

    TYPE, PUBLIC :: UF_HeatTransControl_Flags
        LOGICAL     :: nonlinear_kT     = .FALSE.
        LOGICAL     :: include_radiation= .FALSE.
    END TYPE UF_HeatTransControl_Flags

    TYPE, PUBLIC :: UF_HeatTransControl_Mode
        INTEGER(i4) :: analysis_mode    = HT_TRANSIENT ! Transient/Steady
    END TYPE UF_HeatTransControl_Mode

    TYPE, PUBLIC :: UF_HeatTransControl_Time
        REAL(wp)    :: time_period      = 1.0_wp       ! Analysis time period
        REAL(wp)    :: initial_time_inc = 0.01_wp      ! Initial time increment dt
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_HeatTransControl_Time

    TYPE, PUBLIC :: UF_HeatTransControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_HeatTransControl_Steps

    TYPE, PUBLIC :: UF_HeatTransControl_Solver
        REAL(wp)    :: theta_integration= 1.0_wp       ! 1.0=backward Euler; 0.5=Crank-Nicolson
        REAL(wp)    :: temp_tol         = 1.0E-3_wp    ! Temperature convergence tolerance (K)
        REAL(wp)    :: flux_tol         = 1.0E-4_wp    ! Heat flux convergence tolerance
        INTEGER(i4) :: max_iterations   = 16_i4        ! Max nonlinear iterations
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_HeatTransControl_Solver

    TYPE, PUBLIC :: UF_HeatTransControl_Flags
        LOGICAL     :: nonlinear_kT     = .FALSE.      ! k(T) temperature-dependent conductivity
        LOGICAL     :: include_radiation= .FALSE.      ! Include radiation boundary
    END TYPE UF_HeatTransControl_Flags

    TYPE, PUBLIC :: UF_HeatTransControl
        TYPE(UF_HeatTransControl_Mode)   :: mode
        TYPE(UF_HeatTransControl_Time)   :: time
        TYPE(UF_HeatTransControl_Steps)  :: steps
        TYPE(UF_HeatTransControl_Solver) :: solver
        TYPE(UF_HeatTransControl_Flags)  :: flags
    END TYPE UF_HeatTransControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ThermalBCManager
    ! KIND:  Ctx
    ! DESC:  Thermal BC manager — prescribed T, flux, convection, radiation.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_ThermalBCManager_PrescribedT
        INTEGER(i4), ALLOCATABLE :: prescribed_T_nodes(:)
        REAL(wp),    ALLOCATABLE :: prescribed_T_vals(:)
    END TYPE UF_ThermalBCManager_PrescribedT

    TYPE, PUBLIC :: UF_ThermalBCManager_Flux
        INTEGER(i4), ALLOCATABLE :: flux_face_ids(:)
        REAL(wp),    ALLOCATABLE :: flux_vals(:)
    END TYPE UF_ThermalBCManager_Flux

    TYPE, PUBLIC :: UF_ThermalBCManager_Convection
        INTEGER(i4), ALLOCATABLE :: conv_face_ids(:)
        REAL(wp),    ALLOCATABLE :: conv_h(:)
        REAL(wp),    ALLOCATABLE :: conv_T_inf(:)
    END TYPE UF_ThermalBCManager_Convection

    TYPE, PUBLIC :: UF_ThermalBCManager_Radiation
        INTEGER(i4), ALLOCATABLE :: rad_face_ids(:)
        REAL(wp),    ALLOCATABLE :: rad_emissivity(:)
        REAL(wp),    ALLOCATABLE :: rad_T_amb(:)
    END TYPE UF_ThermalBCManager_Radiation

    TYPE, PUBLIC :: UF_ThermalBCManager
        TYPE(UF_ThermalBCManager_PrescribedT) :: prescribedT
        TYPE(UF_ThermalBCManager_Flux)        :: flux
        TYPE(UF_ThermalBCManager_Convection)  :: convection
        TYPE(UF_ThermalBCManager_Radiation)   :: radiation
    END TYPE UF_ThermalBCManager

    !---------------------------------------------------------------------------
    ! TYPE:  UF_CTDispControl
    ! KIND:  Algo
    ! DESC:  Coupled temp-displacement control — sequential/monolithic, nlgeom.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: CTD_SEQUENTIAL = 1
    INTEGER(i4), PARAMETER, PUBLIC :: CTD_FULLY_COUPLED = 2
    TYPE, PUBLIC :: UF_CTDispControl_Mode
        INTEGER(i4) :: coupling_type    = CTD_SEQUENTIAL
    END TYPE UF_CTDispControl_Mode

    TYPE, PUBLIC :: UF_CTDispControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.01_wp
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_CTDispControl_Time

    TYPE, PUBLIC :: UF_CTDispControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTDispControl_Steps

    TYPE, PUBLIC :: UF_CTDispControl_Config
        REAL(wp)    :: theta_heat       = 1.0_wp
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
    END TYPE UF_CTDispControl_Config

    TYPE, PUBLIC :: UF_CTDispControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol     = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTDispControl_Solver

    TYPE, PUBLIC :: UF_CTDispControl_Material
        LOGICAL     :: include_plastic_heat = .FALSE.
        REAL(wp)    :: taylor_quinney      = 0.9_wp
    END TYPE UF_CTDispControl_Material

    TYPE, PUBLIC :: UF_CTDispControl_Mode
        INTEGER(i4) :: coupling_type    = CTD_SEQUENTIAL
    END TYPE UF_CTDispControl_Mode

    TYPE, PUBLIC :: UF_CTDispControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.01_wp
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_CTDispControl_Time

    TYPE, PUBLIC :: UF_CTDispControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTDispControl_Steps

    TYPE, PUBLIC :: UF_CTDispControl_Config
        REAL(wp)    :: theta_heat       = 1.0_wp
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
    END TYPE UF_CTDispControl_Config

    TYPE, PUBLIC :: UF_CTDispControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol     = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTDispControl_Solver

    TYPE, PUBLIC :: UF_CTDispControl_Material
        LOGICAL     :: include_plastic_heat = .FALSE.
        REAL(wp)    :: taylor_quinney      = 0.9_wp
    END TYPE UF_CTDispControl_Material

    TYPE, PUBLIC :: UF_CTDispControl_Mode
        INTEGER(i4) :: coupling_type    = CTD_SEQUENTIAL
    END TYPE UF_CTDispControl_Mode

    TYPE, PUBLIC :: UF_CTDispControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.01_wp
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_CTDispControl_Time

    TYPE, PUBLIC :: UF_CTDispControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTDispControl_Steps

    TYPE, PUBLIC :: UF_CTDispControl_Config
        REAL(wp)    :: theta_heat       = 1.0_wp
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
    END TYPE UF_CTDispControl_Config

    TYPE, PUBLIC :: UF_CTDispControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol     = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTDispControl_Solver

    TYPE, PUBLIC :: UF_CTDispControl_Flags
        LOGICAL     :: include_plastic_heat = .FALSE.
        REAL(wp)    :: taylor_quinney      = 0.9_wp
    END TYPE UF_CTDispControl_Flags

    TYPE, PUBLIC :: UF_CTDispControl
        TYPE(UF_CTDispControl_Mode)   :: mode
        TYPE(UF_CTDispControl_Time)   :: time
        TYPE(UF_CTDispControl_Steps)  :: steps
        TYPE(UF_CTDispControl_Config) :: config
        TYPE(UF_CTDispControl_Solver) :: solver
        TYPE(UF_CTDispControl_Flags)  :: flags
    END TYPE UF_CTDispControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_CTElecControl
    ! KIND:  Algo
    ! DESC:  Coupled thermal-electrical control — Joule heating, Seebeck.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_CTElecControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.001_wp
        REAL(wp)    :: min_time_inc     = 1.0E-10_wp
        REAL(wp)    :: max_time_inc     = 0.01_wp
    END TYPE UF_CTElecControl_Time

    TYPE, PUBLIC :: UF_CTElecControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTElecControl_Steps

    TYPE, PUBLIC :: UF_CTElecControl_Thermal
        REAL(wp)    :: theta_heat       = 1.0_wp
    END TYPE UF_CTElecControl_Thermal

    TYPE, PUBLIC :: UF_CTElecControl_Solver
        REAL(wp)    :: temp_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTElecControl_Solver

    TYPE, PUBLIC :: UF_CTElecControl_Material
        LOGICAL     :: include_seebeck  = .FALSE.
        LOGICAL     :: sigma_temp_depend= .TRUE.
        LOGICAL     :: kappa_temp_depend= .TRUE.
    END TYPE UF_CTElecControl_Material

    TYPE, PUBLIC :: UF_CTElecControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.001_wp
        REAL(wp)    :: min_time_inc     = 1.0E-10_wp
        REAL(wp)    :: max_time_inc     = 0.01_wp
    END TYPE UF_CTElecControl_Time

    TYPE, PUBLIC :: UF_CTElecControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTElecControl_Steps

    TYPE, PUBLIC :: UF_CTElecControl_Thermal
        REAL(wp)    :: theta_heat       = 1.0_wp
    END TYPE UF_CTElecControl_Thermal

    TYPE, PUBLIC :: UF_CTElecControl_Solver
        REAL(wp)    :: temp_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTElecControl_Solver

    TYPE, PUBLIC :: UF_CTElecControl_Material
        LOGICAL     :: include_seebeck  = .FALSE.
        LOGICAL     :: sigma_temp_depend= .TRUE.
        LOGICAL     :: kappa_temp_depend= .TRUE.
    END TYPE UF_CTElecControl_Material

    TYPE, PUBLIC :: UF_CTElecControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.001_wp
        REAL(wp)    :: min_time_inc     = 1.0E-10_wp
        REAL(wp)    :: max_time_inc     = 0.01_wp
    END TYPE UF_CTElecControl_Time

    TYPE, PUBLIC :: UF_CTElecControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTElecControl_Steps

    TYPE, PUBLIC :: UF_CTElecControl_Solver
        REAL(wp)    :: theta_heat       = 1.0_wp
        REAL(wp)    :: temp_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTElecControl_Solver

    TYPE, PUBLIC :: UF_CTElecControl_Material
        LOGICAL     :: include_seebeck  = .FALSE.
        LOGICAL     :: sigma_temp_depend= .TRUE.
        LOGICAL     :: kappa_temp_depend= .TRUE.
    END TYPE UF_CTElecControl_Material

    TYPE, PUBLIC :: UF_CTElecControl
        TYPE(UF_CTElecControl_Time)     :: time
        TYPE(UF_CTElecControl_Steps)    :: steps
        TYPE(UF_CTElecControl_Solver)   :: solver
        TYPE(UF_CTElecControl_Material) :: material
    END TYPE UF_CTElecControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ElecBCManager
    ! KIND:  Ctx
    ! DESC:  Electrical BC manager — prescribed phi, current flux, contacts.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_ElecBCManager
        INTEGER(i4), ALLOCATABLE :: prescribed_phi_nodes(:)
        REAL(wp),    ALLOCATABLE :: prescribed_phi_vals(:)
        INTEGER(i4), ALLOCATABLE :: current_face_ids(:)
        REAL(wp),    ALLOCATABLE :: current_flux_vals(:)
        INTEGER(i4), ALLOCATABLE :: elec_contact_ids(:)
    END TYPE UF_ElecBCManager

    !---------------------------------------------------------------------------
    ! TYPE:  UF_GeostaticControl
    ! KIND:  Algo
    ! DESC:  Geostatic stress initialization — K0 method, gravity, density.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: GEO_K0_METHOD = 1
    INTEGER(i4), PARAMETER, PUBLIC :: GEO_ELASTOPLASTIC_METHOD = 2
    TYPE, PUBLIC :: UF_GeostaticControl_Soil
        INTEGER(i4) :: method           = GEO_K0_METHOD
        REAL(wp)    :: k0_horizontal    = 0.5_wp
        REAL(wp)    :: gravity_z        = -9.81_wp
        REAL(wp)    :: density_ref      = 2000.0_wp
    END TYPE UF_GeostaticControl_Soil

    TYPE, PUBLIC :: UF_GeostaticControl_Tol
        REAL(wp)    :: residual_tol     = 1.0E-3_wp
        REAL(wp)    :: correction_tol   = 1.0E-2_wp
    END TYPE UF_GeostaticControl_Tol

    TYPE, PUBLIC :: UF_GeostaticControl_Steps
        INTEGER(i4) :: max_iterations   = 20_i4
        INTEGER(i4) :: max_increments   = 10_i4
    END TYPE UF_GeostaticControl_Steps

    TYPE, PUBLIC :: UF_GeostaticControl_Check
        REAL(wp)    :: disp_zero_check_tol = 1.0E-6_wp
        LOGICAL     :: check_stress_equil = .TRUE.
        LOGICAL     :: reset_displacements = .TRUE.
    END TYPE UF_GeostaticControl_Check

    TYPE, PUBLIC :: UF_GeostaticControl
        TYPE(UF_GeostaticControl_Soil)  :: soil
        TYPE(UF_GeostaticControl_Tol)   :: tol
        TYPE(UF_GeostaticControl_Steps) :: steps
        TYPE(UF_GeostaticControl_Check) :: check
    END TYPE UF_GeostaticControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_SoilsControl
    ! KIND:  Algo
    ! DESC:  Biot consolidation control — permeability, pore pressure, time.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_SoilsControl_Time
        REAL(wp)    :: time_period      = 864000.0_wp
        REAL(wp)    :: initial_time_inc = 1.0_wp
        REAL(wp)    :: min_time_inc     = 1.0E-4_wp
        REAL(wp)    :: max_time_inc     = 86400.0_wp
    END TYPE UF_SoilsControl_Time

    TYPE, PUBLIC :: UF_SoilsControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_SoilsControl_Steps

    TYPE, PUBLIC :: UF_SoilsControl_Log
        REAL(wp)    :: theta_int        = 1.0_wp
        REAL(wp)    :: log_time_factor  = 2.0_wp
        LOGICAL     :: use_log_time     = .TRUE.
    END TYPE UF_SoilsControl_Log

    TYPE, PUBLIC :: UF_SoilsControl_Biot
        REAL(wp)    :: biot_alpha       = 1.0_wp
        REAL(wp)    :: biot_modulus_M   = 1.0E9_wp
        REAL(wp)    :: k_permeability   = 1.0E-9_wp
        REAL(wp)    :: gamma_water      = 9810.0_wp
    END TYPE UF_SoilsControl_Biot

    TYPE, PUBLIC :: UF_SoilsControl_Solver
        REAL(wp)    :: disp_tol         = 1.0E-5_wp
        REAL(wp)    :: pore_tol         = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        INTEGER(i4) :: prestress_step_id= -1
    END TYPE UF_SoilsControl_Solver

    TYPE, PUBLIC :: UF_SoilsControl_Time
        REAL(wp)    :: time_period      = 864000.0_wp
        REAL(wp)    :: initial_time_inc = 1.0_wp
        REAL(wp)    :: min_time_inc     = 1.0E-4_wp
        REAL(wp)    :: max_time_inc     = 86400.0_wp
    END TYPE UF_SoilsControl_Time

    TYPE, PUBLIC :: UF_SoilsControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_SoilsControl_Steps

    TYPE, PUBLIC :: UF_SoilsControl_Log
        REAL(wp)    :: theta_int        = 1.0_wp
        REAL(wp)    :: log_time_factor  = 2.0_wp
        LOGICAL     :: use_log_time     = .TRUE.
    END TYPE UF_SoilsControl_Log

    TYPE, PUBLIC :: UF_SoilsControl_Biot
        REAL(wp)    :: biot_alpha       = 1.0_wp
        REAL(wp)    :: biot_modulus_M   = 1.0E9_wp
        REAL(wp)    :: k_permeability   = 1.0E-9_wp
        REAL(wp)    :: gamma_water      = 9810.0_wp
    END TYPE UF_SoilsControl_Biot

    TYPE, PUBLIC :: UF_SoilsControl_Solver
        REAL(wp)    :: disp_tol         = 1.0E-5_wp
        REAL(wp)    :: pore_tol         = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        INTEGER(i4) :: prestress_step_id= -1
    END TYPE UF_SoilsControl_Solver

    TYPE, PUBLIC :: UF_SoilsControl
        TYPE(UF_SoilsControl_Time)   :: time
        TYPE(UF_SoilsControl_Steps)  :: steps
        TYPE(UF_SoilsControl_Log)    :: log
        TYPE(UF_SoilsControl_Biot)   :: biot
        TYPE(UF_SoilsControl_Solver) :: solver
    END TYPE UF_SoilsControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_PoreBCManager
    ! KIND:  Ctx
    ! DESC:  Pore pressure BC manager — zero pore nodes, impervious faces.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_PoreBCManager
        INTEGER(i4), ALLOCATABLE :: zero_pore_nodes(:)
        INTEGER(i4), ALLOCATABLE :: imperv_face_ids(:)
        REAL(wp),    ALLOCATABLE :: init_pore_vals(:)
    END TYPE UF_PoreBCManager

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ViscoControl
    ! KIND:  Algo
    ! DESC:  Viscoelastic/creep control — Maxwell model, Norton creep, log time.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_ViscoControl_Time
        REAL(wp)    :: time_period      = 3600.0_wp
        REAL(wp)    :: initial_time_inc = 1.0_wp
        REAL(wp)    :: min_time_inc     = 1.0E-6_wp
        REAL(wp)    :: max_time_inc     = 100.0_wp
    END TYPE UF_ViscoControl_Time

    TYPE, PUBLIC :: UF_ViscoControl_Steps
        INTEGER(i4) :: max_increments   = 10000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_ViscoControl_Steps

    TYPE, PUBLIC :: UF_ViscoControl_Log
        LOGICAL     :: use_log_time     = .TRUE.
        REAL(wp)    :: log_time_factor  = 1.5_wp
    END TYPE UF_ViscoControl_Log

    TYPE, PUBLIC :: UF_ViscoControl_Config
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
        INTEGER(i4) :: n_maxwell        = 3_i4
    END TYPE UF_ViscoControl_Config

    TYPE, PUBLIC :: UF_ViscoControl_Solver
        REAL(wp)    :: maxwell_tol      = 1.0E-6_wp
        REAL(wp)    :: residual_tol     = 1.0E-5_wp
        REAL(wp)    :: correction_tol   = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_ViscoControl_Solver

    TYPE, PUBLIC :: UF_ViscoControl_Time
        REAL(wp)    :: time_period      = 3600.0_wp
        REAL(wp)    :: initial_time_inc = 1.0_wp
        REAL(wp)    :: min_time_inc     = 1.0E-6_wp
        REAL(wp)    :: max_time_inc     = 100.0_wp
    END TYPE UF_ViscoControl_Time

    TYPE, PUBLIC :: UF_ViscoControl_Steps
        INTEGER(i4) :: max_increments   = 10000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_ViscoControl_Steps

    TYPE, PUBLIC :: UF_ViscoControl_Log
        LOGICAL     :: use_log_time     = .TRUE.
        REAL(wp)    :: log_time_factor  = 1.5_wp
    END TYPE UF_ViscoControl_Log

    TYPE, PUBLIC :: UF_ViscoControl_Config
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
        INTEGER(i4) :: n_maxwell        = 3_i4
    END TYPE UF_ViscoControl_Config

    TYPE, PUBLIC :: UF_ViscoControl_Solver
        REAL(wp)    :: maxwell_tol      = 1.0E-6_wp
        REAL(wp)    :: residual_tol     = 1.0E-5_wp
        REAL(wp)    :: correction_tol   = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_ViscoControl_Solver

    TYPE, PUBLIC :: UF_ViscoControl
        TYPE(UF_ViscoControl_Time)   :: time
        TYPE(UF_ViscoControl_Steps)  :: steps
        TYPE(UF_ViscoControl_Log)    :: log
        TYPE(UF_ViscoControl_Config) :: config
        TYPE(UF_ViscoControl_Solver) :: solver
    END TYPE UF_ViscoControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_AnnealControl
    ! KIND:  Algo
    ! DESC:  Annealing control — heating/holding/cooling, plastic/creep reset.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: ANNEAL_HEATING = 1
    INTEGER(i4), PARAMETER, PUBLIC :: ANNEAL_HOLDING = 2
    INTEGER(i4), PARAMETER, PUBLIC :: ANNEAL_COOLING = 3
    TYPE, PUBLIC :: UF_AnnealControl_Temp
        REAL(wp)    :: T_anneal         = 1173.0_wp
        REAL(wp)    :: T_initial        = 293.0_wp
    END TYPE UF_AnnealControl_Temp

    TYPE, PUBLIC :: UF_AnnealControl_Rate
        REAL(wp)    :: heating_rate     = 5.0_wp
        REAL(wp)    :: holding_time     = 3600.0_wp
        REAL(wp)    :: cooling_rate     = -10.0_wp
    END TYPE UF_AnnealControl_Rate

    TYPE, PUBLIC :: UF_AnnealControl_Time
        REAL(wp)    :: initial_time_inc = 0.5_wp
        REAL(wp)    :: min_time_inc     = 1.0E-5_wp
        REAL(wp)    :: max_time_inc     = 5.0_wp
    END TYPE UF_AnnealControl_Time

    TYPE, PUBLIC :: UF_AnnealControl_Steps
        INTEGER(i4) :: max_increments   = 50000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_AnnealControl_Steps

    TYPE, PUBLIC :: UF_AnnealControl_Config
        INTEGER(i4) :: nlgeom           = NLGEOM_ON
        LOGICAL     :: clear_plastic    = .TRUE.
        LOGICAL     :: clear_creep      = .FALSE.
        LOGICAL     :: reset_hardening  = .TRUE.
    END TYPE UF_AnnealControl_Config

    TYPE, PUBLIC :: UF_AnnealControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-4_wp
        REAL(wp)    :: temp_tol         = 0.5_wp
        INTEGER(i4) :: max_iterations   = 20_i4
    END TYPE UF_AnnealControl_Solver

    TYPE, PUBLIC :: UF_AnnealControl_Temp
        REAL(wp)    :: T_anneal         = 1173.0_wp
        REAL(wp)    :: T_initial        = 293.0_wp
    END TYPE UF_AnnealControl_Temp

    TYPE, PUBLIC :: UF_AnnealControl_Rate
        REAL(wp)    :: heating_rate     = 5.0_wp
        REAL(wp)    :: holding_time     = 3600.0_wp
        REAL(wp)    :: cooling_rate     = -10.0_wp
    END TYPE UF_AnnealControl_Rate

    TYPE, PUBLIC :: UF_AnnealControl_Time
        REAL(wp)    :: initial_time_inc = 0.5_wp
        REAL(wp)    :: min_time_inc     = 1.0E-5_wp
        REAL(wp)    :: max_time_inc     = 5.0_wp
    END TYPE UF_AnnealControl_Time

    TYPE, PUBLIC :: UF_AnnealControl_Steps
        INTEGER(i4) :: max_increments   = 50000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_AnnealControl_Steps

    TYPE, PUBLIC :: UF_AnnealControl_Config
        INTEGER(i4) :: nlgeom           = NLGEOM_ON
        LOGICAL     :: clear_plastic    = .TRUE.
        LOGICAL     :: clear_creep      = .FALSE.
        LOGICAL     :: reset_hardening  = .TRUE.
    END TYPE UF_AnnealControl_Config

    TYPE, PUBLIC :: UF_AnnealControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-4_wp
        REAL(wp)    :: temp_tol         = 0.5_wp
        INTEGER(i4) :: max_iterations   = 20_i4
    END TYPE UF_AnnealControl_Solver

    TYPE, PUBLIC :: UF_AnnealControl
        TYPE(UF_AnnealControl_Temp)   :: temp
        TYPE(UF_AnnealControl_Rate)   :: rate
        TYPE(UF_AnnealControl_Time)   :: time
        TYPE(UF_AnnealControl_Steps)  :: steps
        TYPE(UF_AnnealControl_Config) :: config
        TYPE(UF_AnnealControl_Solver) :: solver
    END TYPE UF_AnnealControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_StaticPerturbControl
    ! KIND:  Algo
    ! DESC:  Linear perturbation static — prestress, multi-load case.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_StaticPerturbControl
        LOGICAL     :: include_prestress    = .TRUE.   ! Include K_sigma from base state
        LOGICAL     :: include_friction     = .FALSE.  ! Linearized friction tangent
        INTEGER(i4) :: base_step_id         = -1_i4   ! ID of preceding general step
        LOGICAL     :: multi_load_case      = .FALSE.  ! Multiple load cases in one step
        INTEGER(i4) :: n_load_cases         = 1_i4    ! Number of load cases
    END TYPE UF_StaticPerturbControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_DynamicSubspaceControl
    ! KIND:  Algo
    ! DESC:  Subspace-based implicit dynamic — reduced modal, Rayleigh damp.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-8_wp
        REAL(wp)    :: max_time_inc         = 0.1_wp
    END TYPE UF_DynamicSubspaceControl_Time

    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Steps
        INTEGER(i4) :: max_increments       = 5000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_DynamicSubspaceControl_Steps

    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Solver
        INTEGER(i4) :: n_modes_used         = -1_i4   ! -1 = all extracted modes
        INTEGER(i4) :: max_iter             = 8_i4
        REAL(wp)    :: residual_tol         = 1.0E-4_wp
    END TYPE UF_DynamicSubspaceControl_Solver

    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Modal
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 1.0E-4_wp
        INTEGER(i4) :: modal_base_step_id   = -1_i4   ! Frequency extraction step
    END TYPE UF_DynamicSubspaceControl_Modal

    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-8_wp
        REAL(wp)    :: max_time_inc         = 0.1_wp
    END TYPE UF_DynamicSubspaceControl_Time

    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Steps
        INTEGER(i4) :: max_increments       = 5000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_DynamicSubspaceControl_Steps

    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Solver
        INTEGER(i4) :: n_modes_used         = -1_i4   ! -1 = all extracted modes
        INTEGER(i4) :: max_iter             = 8_i4
        REAL(wp)    :: residual_tol         = 1.0E-4_wp
    END TYPE UF_DynamicSubspaceControl_Solver

    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Modal
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 1.0E-4_wp
        INTEGER(i4) :: modal_base_step_id   = -1_i4   ! Frequency extraction step
    END TYPE UF_DynamicSubspaceControl_Modal

    TYPE, PUBLIC :: UF_DynamicSubspaceControl
        TYPE(UF_DynamicSubspaceControl_Time)   :: time
        TYPE(UF_DynamicSubspaceControl_Steps)  :: steps
        TYPE(UF_DynamicSubspaceControl_Solver) :: solver
        TYPE(UF_DynamicSubspaceControl_Modal)  :: modal
    END TYPE UF_DynamicSubspaceControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ModalDynamicControl
    ! KIND:  Algo
    ! DESC:  Modal superposition transient — decoupled oscillator, damping.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_ModalDynamicControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-8_wp
        REAL(wp)    :: max_time_inc         = 0.01_wp
    END TYPE UF_ModalDynamicControl_Time

    TYPE, PUBLIC :: UF_ModalDynamicControl_Steps
        INTEGER(i4) :: max_increments       = 10000_i4
        INTEGER(i4) :: n_modes_used         = -1_i4
    END TYPE UF_ModalDynamicControl_Steps

    TYPE, PUBLIC :: UF_ModalDynamicControl_Modal
        REAL(wp)    :: modal_damping        = 0.02_wp
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 0.0_wp
    END TYPE UF_ModalDynamicControl_Modal

    TYPE, PUBLIC :: UF_ModalDynamicControl_Config
        LOGICAL     :: use_initial_cond     = .FALSE.
        INTEGER(i4) :: modal_base_step_id   = -1_i4
        INTEGER(i4) :: residual_modes       = 0_i4
        LOGICAL     :: use_explicit_modal   = .FALSE.
    END TYPE UF_ModalDynamicControl_Config

    TYPE, PUBLIC :: UF_ModalDynamicControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-8_wp
        REAL(wp)    :: max_time_inc         = 0.01_wp
    END TYPE UF_ModalDynamicControl_Time

    TYPE, PUBLIC :: UF_ModalDynamicControl_Steps
        INTEGER(i4) :: max_increments       = 10000_i4
        INTEGER(i4) :: n_modes_used         = -1_i4   ! -1 = all extracted modes
    END TYPE UF_ModalDynamicControl_Steps

    TYPE, PUBLIC :: UF_ModalDynamicControl_Modal
        REAL(wp)    :: modal_damping        = 0.02_wp  ! Global modal damping ratio ?
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 0.0_wp
    END TYPE UF_ModalDynamicControl_Modal

    TYPE, PUBLIC :: UF_ModalDynamicControl_Config
        LOGICAL     :: use_initial_cond     = .FALSE.  ! IC from previous general step
        INTEGER(i4) :: modal_base_step_id   = -1_i4   ! Frequency extraction step
        INTEGER(i4) :: residual_modes       = 0_i4    ! Static correction modes
        LOGICAL     :: use_explicit_modal   = .FALSE. ! .TRUE. = central-diff on q_r (CFL-limited)
    END TYPE UF_ModalDynamicControl_Config

    TYPE, PUBLIC :: UF_ModalDynamicControl
        TYPE(UF_ModalDynamicControl_Time)   :: time
        TYPE(UF_ModalDynamicControl_Steps)  :: steps
        TYPE(UF_ModalDynamicControl_Modal)  :: modal
        TYPE(UF_ModalDynamicControl_Config) :: config
    END TYPE UF_ModalDynamicControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_RandomResponseControl
    ! KIND:  Algo
    ! DESC:  Random response — PSD input/output, modal-based.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_RandomResponseControl_Freq
        REAL(wp)    :: freq_start           = 1.0_wp   ! PSD frequency range start (Hz)
        REAL(wp)    :: freq_end             = 2000.0_wp
        INTEGER(i4) :: n_freq_points        = 200_i4
        INTEGER(i4) :: freq_spacing         = FREQ_LOG  ! Log or linear
    END TYPE UF_RandomResponseControl_Freq

    TYPE, PUBLIC :: UF_RandomResponseControl_Modal
        INTEGER(i4) :: n_modes_used         = -1_i4
        REAL(wp)    :: modal_damping        = 0.02_wp
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 0.0_wp
        INTEGER(i4) :: modal_base_step_id   = -1_i4
    END TYPE UF_RandomResponseControl_Modal

    TYPE, PUBLIC :: UF_RandomResponseControl_Output
        LOGICAL     :: compute_rms          = .TRUE.   ! Output RMS (1-sigma) values
        LOGICAL     :: compute_psd          = .TRUE.   ! Store full PSD fields
    END TYPE UF_RandomResponseControl_Output

    TYPE, PUBLIC :: UF_RandomResponseControl_Freq
        REAL(wp)    :: freq_start           = 1.0_wp   ! PSD frequency range start (Hz)
        REAL(wp)    :: freq_end             = 2000.0_wp
        INTEGER(i4) :: n_freq_points        = 200_i4
        INTEGER(i4) :: freq_spacing         = FREQ_LOG  ! Log or linear
    END TYPE UF_RandomResponseControl_Freq

    TYPE, PUBLIC :: UF_RandomResponseControl_Modal
        INTEGER(i4) :: n_modes_used         = -1_i4
        REAL(wp)    :: modal_damping        = 0.02_wp
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 0.0_wp
        INTEGER(i4) :: modal_base_step_id   = -1_i4
    END TYPE UF_RandomResponseControl_Modal

    TYPE, PUBLIC :: UF_RandomResponseControl_Output
        LOGICAL     :: compute_rms          = .TRUE.   ! Output RMS (1-sigma) values
        LOGICAL     :: compute_psd          = .TRUE.   ! Store full PSD fields
    END TYPE UF_RandomResponseControl_Output

    TYPE, PUBLIC :: UF_RandomResponseControl
        TYPE(UF_RandomResponseControl_Freq)   :: freq
        TYPE(UF_RandomResponseControl_Modal)  :: modal
        TYPE(UF_RandomResponseControl_Output) :: output
    END TYPE UF_RandomResponseControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ResponseSpectrumControl
    ! KIND:  Algo
    ! DESC:  Response spectrum — SRSS/CQC/ABS modal combination.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: RS_SRSS = 1  ! Square-Root Sum of Squares
    INTEGER(i4), PARAMETER, PUBLIC :: RS_CQC  = 2  ! Complete Quadratic Combination
    INTEGER(i4), PARAMETER, PUBLIC :: RS_ABS  = 3  ! Absolute Sum
    TYPE, PUBLIC :: UF_ResponseSpectrumControl_Config
        INTEGER(i4) :: combination_rule      = RS_CQC
        INTEGER(i4) :: n_excitation_dirs     = 1_i4   ! 1, 2, or 3 directions
    END TYPE UF_ResponseSpectrumControl_Config

    TYPE, PUBLIC :: UF_ResponseSpectrumControl_Scales
        REAL(wp)    :: scale_x              = 1.0_wp  ! Scale factor X direction
        REAL(wp)    :: scale_y              = 1.0_wp
        REAL(wp)    :: scale_z              = 1.0_wp
    END TYPE UF_ResponseSpectrumControl_Scales

    TYPE, PUBLIC :: UF_ResponseSpectrumControl_Modal
        REAL(wp)    :: modal_damping        = 0.05_wp
        INTEGER(i4) :: n_modes_used         = -1_i4
        INTEGER(i4) :: modal_base_step_id   = -1_i4
    END TYPE UF_ResponseSpectrumControl_Modal

    TYPE, PUBLIC :: UF_ResponseSpectrumControl
        TYPE(UF_ResponseSpectrumControl_Config) :: config
        TYPE(UF_ResponseSpectrumControl_Scales) :: scales
        TYPE(UF_ResponseSpectrumControl_Modal)  :: modal
    END TYPE UF_ResponseSpectrumControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ComplexFreqControl
    ! KIND:  Algo
    ! DESC:  Complex frequency / damped eigenvalue — brake squeal, flutter.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_ComplexFreqControl_Solver
        INTEGER(i4) :: n_eigenvalues        = 20_i4
        INTEGER(i4) :: solver_type          = MODAL_LANCZOS
        REAL(wp)    :: lanczos_tol          = 1.0E-8_wp
        INTEGER(i4) :: max_lanczos_iter     = 500_i4
    END TYPE UF_ComplexFreqControl_Solver

    TYPE, PUBLIC :: UF_ComplexFreqControl_Freq
        REAL(wp)    :: freq_lower_bound     = 0.0_wp  ! Hz
        REAL(wp)    :: freq_upper_bound     = 1.0E6_wp
    END TYPE UF_ComplexFreqControl_Freq

    TYPE, PUBLIC :: UF_ComplexFreqControl_Rotor
        LOGICAL     :: include_gyroscopic   = .FALSE.  ! For rotating systems
        REAL(wp)    :: spin_speed           = 0.0_wp   ! rad/s (if gyroscopic)
    END TYPE UF_ComplexFreqControl_Rotor

    TYPE, PUBLIC :: UF_ComplexFreqControl_Base
        INTEGER(i4) :: modal_base_step_id   = -1_i4   ! Preceding real eigenvalue step
    END TYPE UF_ComplexFreqControl_Base

    TYPE, PUBLIC :: UF_ComplexFreqControl
        TYPE(UF_ComplexFreqControl_Solver) :: solver
        TYPE(UF_ComplexFreqControl_Freq)   :: freq
        TYPE(UF_ComplexFreqControl_Rotor)  :: rotor
        TYPE(UF_ComplexFreqControl_Base)   :: base
    END TYPE UF_ComplexFreqControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_MassDiffControl
    ! KIND:  Algo
    ! DESC:  Mass diffusion control — H embrittlement, moisture, Soret effect.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: MD_TRANSIENT = 1
    INTEGER(i4), PARAMETER, PUBLIC :: MD_STEADY    = 2
    TYPE, PUBLIC :: UF_MassDiffControl_Mode
        INTEGER(i4) :: analysis_mode        = MD_TRANSIENT
    END TYPE UF_MassDiffControl_Mode

    TYPE, PUBLIC :: UF_MassDiffControl_Time
        REAL(wp)    :: time_period          = 3600.0_wp
        REAL(wp)    :: initial_time_inc     = 1.0_wp
        REAL(wp)    :: min_time_inc         = 1.0E-6_wp
        REAL(wp)    :: max_time_inc         = 100.0_wp
    END TYPE UF_MassDiffControl_Time

    TYPE, PUBLIC :: UF_MassDiffControl_Steps
        INTEGER(i4) :: max_increments       = 10000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_MassDiffControl_Steps

    TYPE, PUBLIC :: UF_MassDiffControl_Solver
        REAL(wp)    :: theta_int            = 1.0_wp   ! 1.0 = backward Euler
        REAL(wp)    :: conc_tol             = 1.0E-5_wp
        INTEGER(i4) :: max_iterations       = 16_i4
    END TYPE UF_MassDiffControl_Solver

    TYPE, PUBLIC :: UF_MassDiffControl_Flags
        LOGICAL     :: include_soret        = .FALSE.  ! Stress-driven diffusion
        REAL(wp)    :: cutback_factor       = 0.25_wp
    END TYPE UF_MassDiffControl_Flags

    TYPE, PUBLIC :: UF_MassDiffControl_Mode
        INTEGER(i4) :: analysis_mode        = MD_TRANSIENT
    END TYPE UF_MassDiffControl_Mode

    TYPE, PUBLIC :: UF_MassDiffControl_Time
        REAL(wp)    :: time_period          = 3600.0_wp
        REAL(wp)    :: initial_time_inc     = 1.0_wp
        REAL(wp)    :: min_time_inc         = 1.0E-6_wp
        REAL(wp)    :: max_time_inc         = 100.0_wp
    END TYPE UF_MassDiffControl_Time

    TYPE, PUBLIC :: UF_MassDiffControl_Steps
        INTEGER(i4) :: max_increments       = 10000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_MassDiffControl_Steps

    TYPE, PUBLIC :: UF_MassDiffControl_Solver
        REAL(wp)    :: theta_int            = 1.0_wp   ! 1.0 = backward Euler
        REAL(wp)    :: conc_tol             = 1.0E-5_wp
        INTEGER(i4) :: max_iterations       = 16_i4
    END TYPE UF_MassDiffControl_Solver

    TYPE, PUBLIC :: UF_MassDiffControl_Flags
        LOGICAL     :: include_soret        = .FALSE.  ! Stress-driven diffusion
        REAL(wp)    :: cutback_factor       = 0.25_wp
    END TYPE UF_MassDiffControl_Flags

    TYPE, PUBLIC :: UF_MassDiffControl
        TYPE(UF_MassDiffControl_Mode)   :: mode
        TYPE(UF_MassDiffControl_Time)   :: time
        TYPE(UF_MassDiffControl_Steps)  :: steps
        TYPE(UF_MassDiffControl_Solver) :: solver
        TYPE(UF_MassDiffControl_Flags)  :: flags
    END TYPE UF_MassDiffControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_CoupledTESControl
    ! KIND:  Algo
    ! DESC:  Thermal-electrical-structural control — Joule heat + expansion.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_CoupledTESControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-10_wp
        REAL(wp)    :: max_time_inc         = 0.01_wp
    END TYPE UF_CoupledTESControl_Time

    TYPE, PUBLIC :: UF_CoupledTESControl_Steps
        INTEGER(i4) :: max_increments       = 5000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_CoupledTESControl_Steps

    TYPE, PUBLIC :: UF_CoupledTESControl_Thermal
        REAL(wp)    :: theta_heat           = 1.0_wp
    END TYPE UF_CoupledTESControl_Thermal

    TYPE, PUBLIC :: UF_CoupledTESControl_Solver
        REAL(wp)    :: mech_res_tol         = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_res_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations       = 20_i4
        REAL(wp)    :: cutback_factor       = 0.25_wp
    END TYPE UF_CoupledTESControl_Solver

    TYPE, PUBLIC :: UF_CoupledTESControl_Config
        INTEGER(i4) :: nlgeom              = NLGEOM_OFF
        LOGICAL     :: include_seebeck      = .FALSE.
        LOGICAL     :: include_plastic_heat = .FALSE.
    END TYPE UF_CoupledTESControl_Config

    TYPE, PUBLIC :: UF_CoupledTESControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-10_wp
        REAL(wp)    :: max_time_inc         = 0.01_wp
    END TYPE UF_CoupledTESControl_Time

    TYPE, PUBLIC :: UF_CoupledTESControl_Steps
        INTEGER(i4) :: max_increments       = 5000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_CoupledTESControl_Steps

    TYPE, PUBLIC :: UF_CoupledTESControl_Thermal
        REAL(wp)    :: theta_heat           = 1.0_wp
    END TYPE UF_CoupledTESControl_Thermal

    TYPE, PUBLIC :: UF_CoupledTESControl_Solver
        REAL(wp)    :: mech_res_tol         = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_res_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations       = 20_i4
        REAL(wp)    :: cutback_factor       = 0.25_wp
    END TYPE UF_CoupledTESControl_Solver

    TYPE, PUBLIC :: UF_CoupledTESControl_Config
        INTEGER(i4) :: nlgeom              = NLGEOM_OFF
        LOGICAL     :: include_seebeck      = .FALSE.
        LOGICAL     :: include_plastic_heat = .FALSE.
    END TYPE UF_CoupledTESControl_Config

    TYPE, PUBLIC :: UF_CoupledTESControl
        TYPE(UF_CoupledTESControl_Time)   :: time
        TYPE(UF_CoupledTESControl_Steps)  :: steps
        TYPE(UF_CoupledTESControl_Thermal):: thermal
        TYPE(UF_CoupledTESControl_Solver) :: solver
        TYPE(UF_CoupledTESControl_Config) :: config
    END TYPE UF_CoupledTESControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_PiezoControl
    ! KIND:  Algo
    ! DESC:  Piezoelectric control — sensor/actuator mode, coupling stiffness.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: PIEZO_SENSOR    = 1  ! Charge output mode
    INTEGER(i4), PARAMETER, PUBLIC :: PIEZO_ACTUATOR  = 2  ! Voltage input mode
    TYPE, PUBLIC :: UF_PiezoControl_Mode
        INTEGER(i4) :: mode               = PIEZO_SENSOR
        INTEGER(i4) :: base_proc          = PROC_STATIC  ! Underlying procedure
    END TYPE UF_PiezoControl_Mode

    TYPE, PUBLIC :: UF_PiezoControl_Tol
        REAL(wp)    :: electric_field_tol = 1.0E-6_wp
        REAL(wp)    :: charge_tol         = 1.0E-8_wp
    END TYPE UF_PiezoControl_Tol

    TYPE, PUBLIC :: UF_PiezoControl_Iter
        LOGICAL     :: include_damping    = .FALSE.  ! Piezo structural damping
        INTEGER(i4) :: max_iterations     = 16_i4
    END TYPE UF_PiezoControl_Iter

    TYPE, PUBLIC :: UF_PiezoControl
        TYPE(UF_PiezoControl_Mode) :: mode
        TYPE(UF_PiezoControl_Tol)  :: tol
        TYPE(UF_PiezoControl_Iter) :: iter
    END TYPE UF_PiezoControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_ElectromagneticControl
    ! KIND:  Algo
    ! DESC:  Electromagnetic control — eddy current, magnetostatic, transient.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: EM_MAGNETOSTATIC  = 1
    INTEGER(i4), PARAMETER, PUBLIC :: EM_EDDY_CURRENT   = 2  ! Time-harmonic
    INTEGER(i4), PARAMETER, PUBLIC :: EM_TRANSIENT       = 3
    TYPE, PUBLIC :: UF_ElectromagneticControl_Type
        INTEGER(i4) :: em_type           = EM_EDDY_CURRENT
        REAL(wp)    :: frequency         = 50.0_wp    ! Hz (eddy current)
    END TYPE UF_ElectromagneticControl_Type

    TYPE, PUBLIC :: UF_ElectromagneticControl_Time
        REAL(wp)    :: time_period        = 0.02_wp    ! s (transient)
        REAL(wp)    :: initial_time_inc   = 1.0E-4_wp
        REAL(wp)    :: min_time_inc       = 1.0E-8_wp
        REAL(wp)    :: max_time_inc       = 1.0E-3_wp
    END TYPE UF_ElectromagneticControl_Time

    TYPE, PUBLIC :: UF_ElectromagneticControl_Steps
        INTEGER(i4) :: max_increments     = 2000_i4
    END TYPE UF_ElectromagneticControl_Steps

    TYPE, PUBLIC :: UF_ElectromagneticControl_Solver
        REAL(wp)    :: A_field_tol        = 1.0E-8_wp  ! Magnetic vector potential tol
        INTEGER(i4) :: max_iterations     = 20_i4
    END TYPE UF_ElectromagneticControl_Solver

    TYPE, PUBLIC :: UF_ElectromagneticControl_Coupling
        LOGICAL     :: include_lorentz    = .FALSE.    ! Lorentz force coupling
        LOGICAL     :: include_joule_heat = .FALSE.    ! Induction heating
    END TYPE UF_ElectromagneticControl_Coupling

    TYPE, PUBLIC :: UF_ElectromagneticControl
        TYPE(UF_ElectromagneticControl_Type)    :: em_type
        TYPE(UF_ElectromagneticControl_Time)    :: time
        TYPE(UF_ElectromagneticControl_Steps)   :: steps
        TYPE(UF_ElectromagneticControl_Solver)  :: solver
        TYPE(UF_ElectromagneticControl_Coupling):: coupling
    END TYPE UF_ElectromagneticControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_AcousticControl
    ! KIND:  Algo
    ! DESC:  Acoustic control — transient/steady, FSI coupling, absorbing BC.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: ACOU_TRANSIENT  = 1
    INTEGER(i4), PARAMETER, PUBLIC :: ACOU_STEADY     = 2  ! Frequency sweep
    TYPE, PUBLIC :: UF_AcousticControl_Mode
        INTEGER(i4) :: analysis_mode     = ACOU_TRANSIENT
    END TYPE UF_AcousticControl_Mode

    TYPE, PUBLIC :: UF_AcousticControl_Fluid
        REAL(wp)    :: fluid_density      = 1.2_wp    ! kg/m  (air default)
        REAL(wp)    :: sound_speed        = 343.0_wp  ! m/s
    END TYPE UF_AcousticControl_Fluid

    TYPE, PUBLIC :: UF_AcousticControl_Freq
        REAL(wp)    :: freq_start         = 10.0_wp   ! Hz (steady-state sweep)
        REAL(wp)    :: freq_end           = 8000.0_wp
        INTEGER(i4) :: n_freq_points      = 200_i4
    END TYPE UF_AcousticControl_Freq

    TYPE, PUBLIC :: UF_AcousticControl_Coupling
        LOGICAL     :: coupled_structural = .TRUE.    ! FSI coupling
        REAL(wp)    :: coupling_tol       = 1.0E-4_wp
        INTEGER(i4) :: max_iterations     = 10_i4
    END TYPE UF_AcousticControl_Coupling

    TYPE, PUBLIC :: UF_AcousticControl_BC
        LOGICAL     :: absorbing_boundary = .FALSE.   ! Impedance/NRB BC
    END TYPE UF_AcousticControl_BC

    TYPE, PUBLIC :: UF_AcousticControl
        TYPE(UF_AcousticControl_Mode)     :: mode
        TYPE(UF_AcousticControl_Fluid)    :: fluid
        TYPE(UF_AcousticControl_Freq)     :: freq
        TYPE(UF_AcousticControl_Coupling) :: coupling
        TYPE(UF_AcousticControl_BC)       :: bc
    END TYPE UF_AcousticControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_SteadyStateTransportControl
    ! KIND:  Algo
    ! DESC:  Steady-state transport — rolling/spinning contact, Eulerian.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_SSTransportControl_Motion
        REAL(wp)    :: rolling_speed       = 1.0_wp   ! m/s or rad/s
        REAL(wp)    :: transport_velocity  = 0.0_wp   ! Translational velocity
    END TYPE UF_SSTransportControl_Motion

    TYPE, PUBLIC :: UF_SSTransportControl_Steps
        INTEGER(i4) :: n_load_steps        = 10_i4
        INTEGER(i4) :: max_iterations      = 20_i4
        INTEGER(i4) :: max_increments      = 200_i4
    END TYPE UF_SSTransportControl_Steps

    TYPE, PUBLIC :: UF_SSTransportControl_Tol
        REAL(wp)    :: residual_tol        = 1.0E-4_wp
        REAL(wp)    :: correction_tol      = 1.0E-3_wp
    END TYPE UF_SSTransportControl_Tol

    TYPE, PUBLIC :: UF_SSTransportControl_Flags
        LOGICAL     :: include_friction     = .TRUE.
        INTEGER(i4) :: nlgeom             = NLGEOM_OFF
    END TYPE UF_SSTransportControl_Flags

    TYPE, PUBLIC :: UF_SteadyStateTransportControl
        TYPE(UF_SSTransportControl_Motion) :: motion
        TYPE(UF_SSTransportControl_Steps)  :: steps
        TYPE(UF_SSTransportControl_Tol)    :: tol
        TYPE(UF_SSTransportControl_Flags)  :: flags
    END TYPE UF_SteadyStateTransportControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_SubstructureControl
    ! KIND:  Algo
    ! DESC:  Substructure generation — Guyan/Craig-Bampton reduction.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: SUBSTRUCT_GUYAN = 1        ! Static condensation
    INTEGER(i4), PARAMETER, PUBLIC :: SUBSTRUCT_CRAIG_BAMPTON = 2 ! Dynamic reduction
    TYPE, PUBLIC :: UF_SubstructureControl_Method
        INTEGER(i4) :: reduction_method    = SUBSTRUCT_GUYAN
        INTEGER(i4) :: n_retained_modes    = 0_i4    ! Craig-Bampton internal modes
        INTEGER(i4), ALLOCATABLE :: retained_dof_ids(:)  ! Boundary DOF list
    END TYPE UF_SubstructureControl_Method

    TYPE, PUBLIC :: UF_SubstructureControl_Flags
        LOGICAL     :: generate_recovery   = .TRUE.  ! Generate stress recovery data
        LOGICAL     :: include_mass        = .TRUE.
        LOGICAL     :: include_damping     = .FALSE.
    END TYPE UF_SubstructureControl_Flags

    TYPE, PUBLIC :: UF_SubstructureControl_Name
        CHARACTER(LEN=64) :: substructure_name = ""
    END TYPE UF_SubstructureControl_Name

    TYPE, PUBLIC :: UF_SubstructureControl
        TYPE(UF_SubstructureControl_Method) :: method
        TYPE(UF_SubstructureControl_Flags)  :: flags
        TYPE(UF_SubstructureControl_Name)   :: name
    END TYPE UF_SubstructureControl

    !---------------------------------------------------------------------------
    ! TYPE:  UF_DynamicParams
    ! KIND:  Algo
    ! DESC:  Dynamic integration params — Newmark beta/gamma, HHT alpha, Rayleigh.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_DynamicParams
        INTEGER(i4) :: integration_scheme = INTEG_NEWMARK_BETA
        REAL(wp) :: alpha = -0.05_wp
        REAL(wp) :: beta = 0.2756_wp
        REAL(wp) :: gamma = 0.55_wp
        REAL(wp) :: alpha_rayleigh = 0.0_wp
        REAL(wp) :: beta_rayleigh = 0.0_wp
        LOGICAL :: use_initial_velocity = .FALSE.
        LOGICAL :: use_initial_accel = .FALSE.
        ! PROC_DYNAMIC_EXPLICIT (11): optional stable-dt clamp vs tangent K & lumped M (see RT_DynExpl_Runner)
        LOGICAL :: dyn_expl_apply_cfl_clamp = .FALSE.
        REAL(wp) :: dyn_expl_cfl_safety = 0.9_wp
    END TYPE UF_DynamicParams

    !---------------------------------------------------------------------------
    ! TYPE:  StepStateData
    ! KIND:  State
    ! DESC:  Step-level iteration state — time, norms, cutback, incremental disp.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: StepStateData
        REAL(wp) :: currentTime = 0.0_wp
        REAL(wp) :: totalTime = 0.0_wp
        INTEGER(i4) :: currentInc = 0_i4
        LOGICAL :: failed = .FALSE.
        REAL(wp) :: resNorm = 0.0_wp
        REAL(wp) :: dispNorm = 0.0_wp
        REAL(wp) :: energyRatio = 0.0_wp
        INTEGER(i4) :: nItersTotal = 0_i4
        LOGICAL :: converged = .FALSE.
        LOGICAL :: cutbackOccurred = .FALSE.
        REAL(wp) :: lambda = 1.0_wp
        REAL(wp) :: dlambda = 0.0_wp
        REAL(wp), ALLOCATABLE :: du_inc(:)
        REAL(wp), ALLOCATABLE :: v_inc(:)
        REAL(wp), ALLOCATABLE :: a_inc(:)
    END TYPE StepStateData

    !---------------------------------------------------------------------------
    ! TYPE:  StepDesc
    ! KIND:  Desc
    ! DESC:  Legacy step descriptor alias — name, procedure, time range.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: StepDesc
        CHARACTER(LEN=MAX_STEP_NAME) :: name = ""
        INTEGER(i4) :: step_number = 0
        INTEGER(i4) :: step_id = 0
        INTEGER(i4) :: procedure = PROC_STATIC
        INTEGER(i4) :: step_type = 0
        INTEGER(i4) :: n_increments = 0
        REAL(wp) :: time_start = 0.0_wp
        REAL(wp) :: time_end = 1.0_wp
        CHARACTER(LEN=32) :: solver_algo_str = ""
    END TYPE StepDesc

    !---------------------------------------------------------------------------
    ! TYPE:  StepCtx
    ! KIND:  Ctx
    ! DESC:  Step context — aggregates StepDesc + StepStateData.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: StepCtx
        TYPE(StepDesc) :: step_desc
        TYPE(StepStateData) :: step_state
    END TYPE StepCtx

    !---------------------------------------------------------------------------
    ! TYPE:  MD_TimeIncrementControl
    ! KIND:  Algo
    ! DESC:  Time increment control — initial/min/max/current dt, auto flag.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_TimeIncrementControl
        REAL(wp) :: initial_increment = 0.1_wp
        REAL(wp) :: min_increment = 1.0E-10_wp
        REAL(wp) :: max_increment = 1.0_wp
        REAL(wp) :: current_increment = 0.1_wp
        REAL(wp) :: time_period = 1.0_wp
        LOGICAL :: automatic = .TRUE.
        INTEGER(i4) :: max_increments = 1000_i4
    END TYPE MD_TimeIncrementControl

    !---------------------------------------------------------------------------
    ! TYPE:  MD_TimeIncrementResult
    ! KIND:  State
    ! DESC:  Time increment result — suggested dt + success flag.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_TimeIncrementResult
        REAL(wp) :: suggested_dt = 0.0_wp
        LOGICAL :: success = .TRUE.
    END TYPE MD_TimeIncrementResult

    !---------------------------------------------------------------------------
    ! TYPE:  MD_ConvergenceCriteria
    ! KIND:  Algo
    ! DESC:  Convergence criteria — residual/displacement/energy tolerances.
    !---------------------------------------------------------------------------
    INTEGER(i4), PARAMETER, PUBLIC :: CONV_MODE_AND = 1
    INTEGER(i4), PARAMETER, PUBLIC :: CONV_MODE_OR = 2
    INTEGER(i4), PARAMETER, PUBLIC :: CONV_MODE_WEIGHTED = 3
    TYPE, PUBLIC :: MD_ConvergenceCriteria
        LOGICAL :: use_residual = .TRUE.
        LOGICAL :: use_displacement = .TRUE.
        LOGICAL :: use_energy = .FALSE.
        REAL(wp) :: residual_tolerance = 1.0e-6_wp
        REAL(wp) :: displacement_tol = 1.0e-5_wp
        REAL(wp) :: energy_tolerance = 1.0e-4_wp
        INTEGER(i4) :: max_iterations = 50_i4
        ! I-05: combination_mode: 1=AND, 2=OR, 3=WEIGHTED
        INTEGER(i4) :: combination_mode = CONV_MODE_AND
        REAL(wp) :: residual_weight = 1.0_wp
        REAL(wp) :: energy_weight = 1.0_wp
        REAL(wp) :: displacement_weight = 1.0_wp
    END TYPE MD_ConvergenceCriteria

    !---------------------------------------------------------------------------
    ! TYPE:  MD_ConvergenceResult
    ! KIND:  State
    ! DESC:  Convergence result — converged flag + iteration count.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_ConvergenceResult
        LOGICAL :: converged = .FALSE.
        INTEGER(i4) :: iterations = 0_i4
    END TYPE MD_ConvergenceResult

    !---------------------------------------------------------------------------
    ! TYPE:  MD_NonlinSolv
    ! KIND:  Algo
    ! DESC:  Nonlinear solver config — NR/Modified/Quasi/ArcLen method.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_NonlinSolv
        INTEGER(i4) :: method = 1_i4              ! 1=NR, 2=ModifiedNR, 3=QuasiNR, 4=ArcLen
        INTEGER(i4) :: max_iterations = 50_i4
        REAL(wp) :: tolerance_force = 1.0e-6_wp
        REAL(wp) :: tolerance_displacement = 1.0e-5_wp
        REAL(wp) :: tolerance_energy = 1.0e-4_wp
        ! NR soft divergence guard: exit when ||R_k|| > limit * max(||R_{k-1}||, floor); 0 = off (legacy)
        REAL(wp) :: nr_divergence_growth_limit = 0.0_wp
        ! Arc-length (method=4): if .TRUE., max-iter non-convergence returns IF_STATUS_WARN (StepDriver/cut-back)
        ! instead of IF_STATUS_ERROR; default .FALSE. preserves legacy hard-fail semantics.
        LOGICAL :: arc_nonconverge_use_warn = .FALSE.
        ! Arc-length: scale applied to internal tol_arc for sphere constraint (>=1); 1 = legacy
        REAL(wp) :: arc_constraint_tol_scale = 1.0_wp
    END TYPE MD_NonlinSolv

    !---------------------------------------------------------------------------
    ! TYPE:  MD_SolverState
    ! KIND:  State
    ! DESC:  Solver runtime state — displacement/residual/energy norms.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_SolverState
        REAL(wp), ALLOCATABLE :: u(:)
        REAL(wp), ALLOCATABLE :: R(:)
        REAL(wp), ALLOCATABLE :: du(:)
        REAL(wp) :: lambda = 1.0_wp
        REAL(wp) :: residual_norm = 0.0_wp
        REAL(wp) :: displacement_norm = 0.0_wp
        REAL(wp) :: energy_norm = 0.0_wp
        INTEGER(i4) :: iteration = 0_i4
        INTEGER(i4) :: iterations = 0_i4
        INTEGER(i4) :: line_search_iters = 0_i4
        LOGICAL :: converged = .FALSE.
        ! Arc-length: current arc length (for adaptive stepping)
        REAL(wp) :: arc_length = 0.0_wp
    END TYPE MD_SolverState

    !---------------------------------------------------------------------------
    ! TYPE:  MD_RestartData
    ! KIND:  State
    ! DESC:  Restart checkpoint — time, increment, displacement snapshot.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_RestartData
        LOGICAL :: valid = .FALSE.
        REAL(wp) :: time = 0.0_wp
        INTEGER(i4) :: increment = 0_i4
        REAL(wp), ALLOCATABLE :: u(:)
        LOGICAL :: converged = .FALSE.
    END TYPE MD_RestartData

    !---------------------------------------------------------------------------
    ! TYPE:  MD_OutCfg
    ! KIND:  Desc
    ! DESC:  Output config — field/history output frequency.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_OutCfg
        INTEGER(i4) :: field_freq = 1_i4
        INTEGER(i4) :: hist_freq = 1_i4
    END TYPE MD_OutCfg

    !---------------------------------------------------------------------------
    ! TYPE:  MD_OutReq
    ! KIND:  Desc
    ! DESC:  Output request — number of output requests.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_OutReq
        INTEGER(i4) :: n_requests = 0_i4
    END TYPE MD_OutReq

    !---------------------------------------------------------------------------
    ! TYPE:  IncState
    ! KIND:  State
    ! DESC:  Increment state — index + time increment dt.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: IncState
        INTEGER(i4) :: inc_index = 0_i4
        REAL(wp) :: dt = 0.0_wp
    END TYPE IncState

    !---------------------------------------------------------------------------
    ! TYPE:  IncCtx
    ! KIND:  Ctx
    ! DESC:  Increment context — step index + increment index.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: IncCtx
        INTEGER(i4) :: step_idx = 0_i4
        INTEGER(i4) :: inc_idx = 0_i4
    END TYPE IncCtx

    !---------------------------------------------------------------------------
    ! TYPE:  MD_Model_StepConfig
    ! KIND:  Desc
    ! DESC:  Model-level step config — total step count.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: MD_Model_StepConfig
        INTEGER(i4) :: n_steps = 0_i4
    END TYPE MD_Model_StepConfig

    !---------------------------------------------------------------------------
    ! TYPE:  UF_StepDef
    ! KIND:  Desc
    ! DESC:  Legacy step definition — full procedure config + runtime state.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_StepDef
        CHARACTER(LEN=MAX_STEP_NAME) :: name = ""
        INTEGER(i4) :: step_number = 0
        INTEGER(i4) :: procedure = PROC_STATIC
        INTEGER(i4) :: type = PROC_STATIC      ! RT step type: mirrors procedure for RT_RunJob dispatch
        INTEGER(i4) :: nlgeom = NLGEOM_OFF
        REAL(wp) :: time_period = 1.0_wp
        REAL(wp) :: start_time = 0.0_wp
        REAL(wp) :: current_time = 0.0_wp
        INTEGER(i4) :: current_increment = 0
        TYPE(UF_IncrementControl) :: inc_ctrl
        TYPE(UF_SolutionControl) :: sol_ctrl
        TYPE(UF_RiksControl) :: riks_ctrl
        TYPE(UF_DynamicParams) :: dyn_params
        TYPE(UF_ModalControl) :: modal_ctrl   ! PROC_MODAL: Lanczos/Subspace options
        ! PROC_ID=22 (PROC_FREQUENCY, alias PROC_STEADY_STATE): canonical SSD fields in ssd_ctrl.
        ! L5 StepDriver reads ssd_ctrl (RT_StepDriver_RunSteadyState). Parsers should mirror
        ! ssd_ctrl <-> ss_ctrl/freq_ctrl after writes (see MD_KWMapper map_*_procedure).
        TYPE(UF_SSDControl)         :: ssd_ctrl  ! SSD sweep / method (canonical for id=22)
        TYPE(UF_SSDControl)         :: freq_ctrl ! Legacy mirror; keep in sync with ssd_ctrl
        TYPE(UF_BuckleControl)       :: buckle_ctrl ! PROC_BUCKLE: buckling modes/prestress step
        TYPE(UF_SSDControl)         :: ss_ctrl   ! Legacy mirror (*STEADY STATE DYNAMICS path)
        TYPE(UF_HeatTransControl)   :: ht_ctrl ! PROC_HEAT_TRANSFER
        TYPE(UF_ThermalBCManager)   :: thermal_bc ! PROC_HEAT_TRANSFER
        TYPE(UF_CTDispControl)      :: ctd_ctrl ! PROC_COUPLED_TEMP_DISP
        TYPE(UF_CTElecControl)      :: cte_ctrl ! PROC_COUPLED_THERMAL_ELEC
        TYPE(UF_ElecBCManager)      :: elec_bc  ! PROC_COUPLED_THERMAL_ELEC
        TYPE(UF_GeostaticControl)   :: geo_ctrl ! PROC_GEOSTATIC
        TYPE(UF_SoilsControl)       :: soils_ctrl ! PROC_SOILS
        TYPE(UF_PoreBCManager)      :: pore_bc  ! PROC_SOILS: pore pressure BC
        TYPE(UF_ViscoControl)       :: visco_ctrl ! PROC_VISCO
        TYPE(UF_AnnealControl)      :: anneal_ctrl ! PROC_ANNEAL
        TYPE(UF_DynamicSubspaceControl) :: dyn_subspace_ctrl ! PROC_DYNAMIC_SUBSPACE (12)
        TYPE(UF_ModalDynamicControl)    :: modal_dynamic_ctrl ! PROC_MODAL_DYNAMIC (13)
        TYPE(UF_RandomResponseControl)  :: random_response_ctrl ! PROC_RANDOM_RESPONSE (23)
        TYPE(UF_ResponseSpectrumControl):: response_spectrum_ctrl ! PROC_RESPONSE_SPECTRUM (24)
        TYPE(UF_ComplexFreqControl)     :: complex_freq_ctrl ! PROC_COMPLEX_FREQUENCY (25)
        TYPE(UF_CoupledTESControl)      :: coupled_tes_ctrl ! PROC_COUPLED_TES (42)
        TYPE(UF_PiezoControl)           :: piezo_ctrl ! PROC_PIEZOELECTRIC (43)
        TYPE(UF_MassDiffControl)        :: mass_diff_ctrl ! PROC_MASS_DIFFUSION (31)
        TYPE(UF_ElectromagneticControl) :: electromagnetic_ctrl ! PROC_ELECTROMAGNETIC (44)
        TYPE(UF_AcousticControl)        :: acoustic_ctrl ! PROC_ACOUSTIC (45)
        TYPE(UF_SteadyStateTransportControl) :: ss_transport_ctrl ! PROC_STEADY_STATE_TRANSPORT (60)
        TYPE(UF_SubstructureControl)     :: substructure_ctrl ! PROC_SUBSTRUCTURE (61)
        TYPE(UF_LoadBCManager) :: loadbc
        TYPE(UF_OutputManager) :: output
        ! Optional legacy flat loads (L5 RT_Asm_GlobalLoad Legacy path); null unless wired by driver/parser.
        TYPE(LoadDef), POINTER :: loadDefs(:) => NULL()
        ! Phase F: step-level contact pair IDs (Sync reads from here)
        INTEGER(i4), ALLOCATABLE :: pair_ids(:)
        LOGICAL :: perturbation = .FALSE.
        LOGICAL :: is_active = .TRUE.
        LOGICAL :: is_complete = .FALSE.
    CONTAINS
        PROCEDURE :: init => step_init
        PROCEDURE :: set_procedure => step_set_procedure
        PROCEDURE :: set_time => step_set_time
        PROCEDURE :: set_nlgeom => step_set_nlgeom
        PROCEDURE :: set_increment => step_set_increment
        PROCEDURE :: get_time_fraction => step_get_time_fraction
        PROCEDURE :: advance_increment => step_advance_increment
        PROCEDURE :: print_info => step_print_info
        PROCEDURE :: destroy => step_destroy
        PROCEDURE :: AddPairId => step_add_pair_id
    END TYPE UF_StepDef

    !--------------------------------------------------------------------------
    ! UF_AnalysisStep: Legacy alias for UF_StepDef (used by L5_RT, MD_Model)
    !--------------------------------------------------------------------------
    TYPE, PUBLIC, EXTENDS(UF_StepDef) :: UF_AnalysisStep
    END TYPE UF_AnalysisStep

    !---------------------------------------------------------------------------
    ! TYPE:  UF_StepManager
    ! KIND:  Ctx
    ! DESC:  Legacy step manager — step array + current step tracking.
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: UF_StepManager
        INTEGER(i4) :: num_steps = 0
        INTEGER(i4) :: current_step = 0
        TYPE(UF_StepDef), ALLOCATABLE :: steps(:)
        REAL(wp) :: total_time = 0.0_wp
    CONTAINS
        PROCEDURE :: init => stepmgr_init
        PROCEDURE :: add_step => stepmgr_add_step
        PROCEDURE :: get_step => stepmgr_get_step
        PROCEDURE :: get_current => stepmgr_get_current
        PROCEDURE :: advance_step => stepmgr_advance_step
        PROCEDURE :: print_summary => stepmgr_print_summary
        PROCEDURE :: destroy => stepmgr_destroy
    END TYPE UF_StepManager

    PUBLIC :: ProcToRTStepType
    PUBLIC :: UF_Step_AttachLoadDefs, UF_Step_ClearLoadDefs

CONTAINS

    SUBROUTINE step_init(this, name, number)
        CLASS(UF_StepDef), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: number
        this%name = TRIM(name)
        this%step_number = number
        NULLIFY(this%loadDefs)
        CALL this%loadbc%init()
        CALL this%output%init()
    END SUBROUTINE step_init

    SUBROUTINE step_set_procedure(this, proc_type, perturbation)
        CLASS(UF_StepDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: proc_type
        LOGICAL, INTENT(IN), OPTIONAL :: perturbation
        this%procedure = proc_type
        this%type = proc_type   ! RT dispatch uses type; keep in sync with procedure
        IF (PRESENT(perturbation)) this%perturbation = perturbation
    END SUBROUTINE step_set_procedure

    SUBROUTINE step_set_time(this, period, start)
        CLASS(UF_StepDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: period
        REAL(wp), INTENT(IN), OPTIONAL :: start
        this%time_period = period
        IF (PRESENT(start)) this%start_time = start
        this%current_time = this%start_time
    END SUBROUTINE step_set_time

    SUBROUTINE step_set_nlgeom(this, nlg)
        CLASS(UF_StepDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: nlg
        this%stp%nlgeom = nlg
    END SUBROUTINE step_set_nlgeom

    SUBROUTINE step_set_increment(this, initial, minimum, maximum, max_num)
        CLASS(UF_StepDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN), OPTIONAL :: initial, minimum, maximum
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_num
        IF (PRESENT(initial)) this%inc_ctrl%initial_inc = initial
        IF (PRESENT(minimum)) this%inc_ctrl%min_inc = minimum
        IF (PRESENT(maximum)) this%inc_ctrl%max_inc = maximum
        IF (PRESENT(max_num)) this%inc_ctrl%max_num_inc = max_num
    END SUBROUTINE step_set_increment

    FUNCTION step_get_time_fraction(this) RESULT(frac)
        CLASS(UF_StepDef), INTENT(IN) :: this
        REAL(wp) :: frac
        IF (this%time_period > 0.0_wp) THEN
            frac = (this%current_time - this%start_time) / this%time_period
        ELSE
            frac = 1.0_wp
        END IF
    END FUNCTION step_get_time_fraction

    SUBROUTINE step_advance_increment(this, dt, converged)
        CLASS(UF_StepDef), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: dt
        LOGICAL, INTENT(IN) :: converged
        IF (converged) THEN
            this%current_time = this%current_time + dt
            this%current_increment = this%current_increment + 1
            IF (this%current_time >= this%start_time + this%time_period) THEN
                this%is_complete = .TRUE.
            END IF
        END IF
    END SUBROUTINE step_advance_increment

    SUBROUTINE step_print_info(this, unit_num)
        CLASS(UF_StepDef), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        WRITE(unit_num, '(A,I3,A,A)') 'Step ', this%step_number, ': ', TRIM(this%name)
        WRITE(unit_num, '(A,I3)') '  Procedure: ', this%procedure
        WRITE(unit_num, '(A,ES12.4)') '  Time period: ', this%time_period
        WRITE(unit_num, '(A,I3)') '  NLGEOM: ', this%stp%nlgeom
    END SUBROUTINE step_print_info

    SUBROUTINE step_destroy(this)
        CLASS(UF_StepDef), INTENT(INOUT) :: this
        CALL this%loadbc%destroy()
        CALL this%output%destroy()
        IF (ASSOCIATED(this%loadDefs)) NULLIFY(this%loadDefs)
        IF (ALLOCATED(this%pair_ids)) DEALLOCATE(this%pair_ids)
    END SUBROUTINE step_destroy

    !---------------------------------------------------------------------------
    ! UF_Step_AttachLoadDefs: wire optional Legacy flat loads for L5 RT_Asm_GlobalLoad.
    !   load_array must stay allocated (TARGET) for the lifetime of the association.
    !---------------------------------------------------------------------------
    SUBROUTINE UF_Step_AttachLoadDefs(step, load_array)
        CLASS(UF_StepDef), INTENT(INOUT) :: step
        TYPE(LoadDef), TARGET, INTENT(IN) :: load_array(:)

        step%loadDefs => load_array
    END SUBROUTINE UF_Step_AttachLoadDefs

    SUBROUTINE UF_Step_ClearLoadDefs(step)
        CLASS(UF_StepDef), INTENT(INOUT) :: step

        IF (ASSOCIATED(step%loadDefs)) NULLIFY(step%loadDefs)
    END SUBROUTINE UF_Step_ClearLoadDefs

    ! Phase F: Add contact pair ID to step (parse/mapper calls this)
    SUBROUTINE step_add_pair_id(this, pair_id)
        CLASS(UF_StepDef), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: pair_id
        INTEGER(i4) :: n
        INTEGER(i4), ALLOCATABLE :: tmp(:)
        n = 0
        IF (ALLOCATED(this%pair_ids)) n = SIZE(this%pair_ids)
        ALLOCATE(tmp(n + 1))
        IF (n > 0) tmp(1:n) = this%pair_ids
        tmp(n + 1) = pair_id
        CALL MOVE_ALLOC(tmp, this%pair_ids)
    END SUBROUTINE step_add_pair_id

    SUBROUTINE stepmgr_init(this, max_steps)
        CLASS(UF_StepManager), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_steps
        INTEGER(i4) :: ms
        ms = MAX_STEPS1
        IF (PRESENT(max_steps)) ms = max_steps
        ALLOCATE(this%steps(ms))
        this%num_steps = 0
        this%current_step = 0
        this%total_time = 0.0_wp
    END SUBROUTINE stepmgr_init

    SUBROUTINE stepmgr_add_step(this, step)
        CLASS(UF_StepManager), INTENT(INOUT) :: this
        TYPE(UF_StepDef), INTENT(IN) :: step
        IF (this%num_steps >= SIZE(this%steps)) RETURN
        this%num_steps = this%num_steps + 1
        this%steps(this%num_steps) = step
        this%steps(this%num_steps)%step_number = this%num_steps
        this%total_time = this%total_time + step%time_period
    END SUBROUTINE stepmgr_add_step

    FUNCTION stepmgr_get_step(this, num) RESULT(ptr)
        CLASS(UF_StepManager), INTENT(IN), TARGET :: this
        INTEGER(i4), INTENT(IN) :: num
        TYPE(UF_StepDef), POINTER :: ptr
        ptr => NULL()
        IF (num >= 1 .AND. num <= this%num_steps) THEN
            ptr => this%steps(num)
        END IF
    END FUNCTION stepmgr_get_step

    FUNCTION stepmgr_get_current(this) RESULT(ptr)
        CLASS(UF_StepManager), INTENT(IN), TARGET :: this
        TYPE(UF_StepDef), POINTER :: ptr
        ptr => NULL()
        IF (this%current_step >= 1 .AND. this%current_step <= this%num_steps) THEN
            ptr => this%steps(this%current_step)
        END IF
    END FUNCTION stepmgr_get_current

    FUNCTION stepmgr_advance_step(this) RESULT(has_next)
        CLASS(UF_StepManager), INTENT(INOUT) :: this
        LOGICAL :: has_next
        has_next = .FALSE.
        IF (this%current_step < this%num_steps) THEN
            this%current_step = this%current_step + 1
            has_next = .TRUE.
        END IF
    END FUNCTION stepmgr_advance_step

    SUBROUTINE stepmgr_print_summary(this, unit_num)
        CLASS(UF_StepManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: unit_num
        INTEGER(i4) :: i
        WRITE(unit_num, '(A)') '=== Step Summary ==='
        WRITE(unit_num, '(A,I5)') '  Total steps: ', this%num_steps
        WRITE(unit_num, '(A,ES12.4)') '  Total time: ', this%total_time
        DO i = 1, this%num_steps
            CALL this%steps(i)%print_info(unit_num)
        END DO
    END SUBROUTINE stepmgr_print_summary

    SUBROUTINE stepmgr_destroy(this)
        CLASS(UF_StepManager), INTENT(INOUT) :: this
        INTEGER(i4) :: i
        DO i = 1, this%num_steps
            CALL this%steps(i)%destroy()
        END DO
        IF (ALLOCATED(this%steps)) DEALLOCATE(this%steps)
        this%num_steps = 0
        this%current_step = 0
    END SUBROUTINE stepmgr_destroy

    !--------------------------------------------------------------------------
    ! MD_Conv_Check: convergence check with AND/OR/WEIGHTED (I-05)
    !--------------------------------------------------------------------------
    SUBROUTINE MD_Conv_Check(criteria, state, result, status)
        TYPE(MD_ConvergenceCriteria), INTENT(IN) :: criteria
        TYPE(StepStateData), INTENT(IN) :: state
        TYPE(MD_ConvergenceResult), INTENT(OUT) :: result
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        LOGICAL :: res_ok, disp_ok, en_ok
        REAL(wp) :: combined

        CALL init_error_status(status)
        result%iterations = state%nItersTotal
        result%converged = .FALSE.

        IF (.NOT. (criteria%use_residual .OR. criteria%use_displacement .OR. criteria%use_energy)) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Conv_Check: no convergence criterion enabled"
            RETURN
        END IF
        IF (criteria%use_residual .AND. criteria%residual_tolerance <= 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Conv_Check: residual_tolerance must be > 0 when use_residual"
            RETURN
        END IF
        IF (criteria%use_displacement .AND. criteria%displacement_tol <= 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Conv_Check: displacement_tol must be > 0 when use_displacement"
            RETURN
        END IF
        IF (criteria%use_energy .AND. criteria%energy_tolerance <= 0.0_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "MD_Conv_Check: energy_tolerance must be > 0 when use_energy"
            RETURN
        END IF

        res_ok = .TRUE.
        IF (criteria%use_residual) res_ok = (state%resNorm < criteria%residual_tolerance)
        disp_ok = .TRUE.
        IF (criteria%use_displacement) disp_ok = (state%dispNorm < criteria%displacement_tol)
        en_ok = .TRUE.
        IF (criteria%use_energy) en_ok = (state%energyRatio < criteria%energy_tolerance)

        SELECT CASE (criteria%combination_mode)
        CASE (CONV_MODE_OR)
            result%converged = res_ok .OR. disp_ok .OR. en_ok
        CASE (CONV_MODE_WEIGHTED)
            combined = 0.0_wp
            IF (criteria%use_residual .AND. criteria%residual_tolerance > 0.0_wp) &
                combined = combined + criteria%residual_weight * state%resNorm / criteria%residual_tolerance
            IF (criteria%use_displacement .AND. criteria%displacement_tol > 0.0_wp) &
                combined = combined + criteria%displacement_weight * state%dispNorm / criteria%displacement_tol
            IF (criteria%use_energy .AND. criteria%energy_tolerance > 0.0_wp) &
                combined = combined + criteria%energy_weight * state%energyRatio / criteria%energy_tolerance
            result%converged = (combined < 1.0_wp)
        CASE DEFAULT
            result%converged = res_ok .AND. disp_ok .AND. en_ok
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE MD_Conv_Check

    !--------------------------------------------------------------------------
    ! ProcToRTStepType: map PROC_* -> RT_STEP_TYPE_* (D1 explicit mapping)
    ! Canonical constants from IF_Step_Type; must match RT_Step_Core / RT_Step_Drv.
    !--------------------------------------------------------------------------
    SUBROUTINE ProcToRTStepType(proc, rt_type, ierr)
        USE IF_Step_Type, ONLY: RT_STEP_TYPE_STATIC, RT_STEP_TYPE_IMPL_DYN, &
            RT_STEP_TYPE_EXPL_DYN, RT_STEP_TYPE_ARC, RT_STEP_TYPE_HEAT, &
            RT_STEP_TYPE_CPL_TD, RT_STEP_TYPE_EIGEN, RT_STEP_TYPE_FREQUENCY_RESP, &
            RT_STEP_TYPE_RANDOM_RESP, RT_STEP_TYPE_SUBSTRUCTURE
        INTEGER(i4), INTENT(IN) :: proc
        INTEGER(i4), INTENT(OUT) :: rt_type
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        IF (PRESENT(ierr)) ierr = 0
        SELECT CASE (proc)
        ! Group A: Static & Quasi-Static
        CASE (PROC_STATIC, PROC_STATIC_PERTURBATION)
            rt_type = RT_STEP_TYPE_STATIC
        CASE (PROC_STATIC_RIKS)
            rt_type = RT_STEP_TYPE_ARC
        ! Group B: Dynamic
        CASE (PROC_DYNAMIC_IMPLICIT, PROC_DYNAMIC_SUBSPACE, PROC_MODAL_DYNAMIC)
            rt_type = RT_STEP_TYPE_IMPL_DYN
        CASE (PROC_DYNAMIC_EXPLICIT, PROC_DYNAMIC_CTD_EXPLICIT)
            rt_type = RT_STEP_TYPE_EXPL_DYN
        ! Group C: Frequency / Modal
        CASE (PROC_MODAL, PROC_BUCKLE, PROC_COMPLEX_FREQUENCY)
            rt_type = RT_STEP_TYPE_EIGEN
        CASE (PROC_FREQUENCY)  ! PROC_STEADY_STATE is an alias for PROC_FREQUENCY (=22)
            rt_type = RT_STEP_TYPE_FREQUENCY_RESP
        CASE (PROC_RANDOM_RESPONSE, PROC_RESPONSE_SPECTRUM)
            rt_type = RT_STEP_TYPE_RANDOM_RESP
        ! Group D: Heat / Diffusion
        CASE (PROC_HEAT_TRANSFER, PROC_MASS_DIFFUSION)
            rt_type = RT_STEP_TYPE_HEAT
        ! Group E: Coupled
        CASE (PROC_COUPLED_TEMP_DISP, PROC_COUPLED_THERMAL_ELEC, PROC_COUPLED_TES, PROC_PIEZOELECTRIC)
            rt_type = RT_STEP_TYPE_CPL_TD
        ! Group F: Geotechnical -> static-like
        CASE (PROC_GEOSTATIC, PROC_SOILS)
            rt_type = RT_STEP_TYPE_STATIC
        ! Group G: Special
        CASE (PROC_VISCO, PROC_ANNEAL, PROC_STEADY_STATE_TRANSPORT)
            rt_type = RT_STEP_TYPE_STATIC
        CASE (PROC_SUBSTRUCTURE)
            rt_type = RT_STEP_TYPE_SUBSTRUCTURE
        ! Electromagnetic / Acoustic -> CPL_TD for now (no dedicated RT type yet)
        CASE (PROC_ELECTROMAGNETIC, PROC_ACOUSTIC)
            rt_type = RT_STEP_TYPE_CPL_TD
        CASE DEFAULT
            rt_type = RT_STEP_TYPE_STATIC
            IF (PRESENT(ierr)) ierr = -1
        END SELECT
    END SUBROUTINE ProcToRTStepType

    !--------------------------------------------------------------------------
    ! MD_TimeIncrement_Calc: adaptive time increment (engineering heuristic).
    !   Not a full operator-split / error-controller driver (see RT_Step_Drv).
    !   Unsupported: automatic=.TRUE. with min_increment > max_increment (invalid window).
    !--------------------------------------------------------------------------
    SUBROUTINE MD_TimeIncrement_Calc(time_ctrl, state, conv_result, time_result, status)
        TYPE(MD_TimeIncrementControl), INTENT(INOUT) :: time_ctrl
        TYPE(StepStateData), INTENT(IN) :: state
        TYPE(MD_ConvergenceResult), INTENT(IN) :: conv_result
        TYPE(MD_TimeIncrementResult), INTENT(OUT) :: time_result
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp) :: target_dt
        INTEGER(i4), PARAMETER :: OPTIMAL_ITERS = 5_i4

        CALL init_error_status(status)
        time_result%suggested_dt = time_ctrl%current_increment
        time_result%success = .FALSE.

        IF (time_ctrl%min_increment > time_ctrl%max_increment) THEN
            status%status_code = IF_STATUS_UNSUPPORTED
            status%message = "MD_TimeIncrement_Calc: min_increment > max_increment (automatic unsupported)"
            RETURN
        END IF

        IF (.NOT. time_ctrl%automatic) THEN
            time_result%suggested_dt = time_ctrl%current_increment
            time_result%success = .TRUE.
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ! Heuristic: fast Newton -> grow dt; slow -> shrink slightly; diverged -> strong cut.
        IF (conv_result%converged) THEN
            IF (conv_result%iterations <= OPTIMAL_ITERS) THEN
                target_dt = time_ctrl%current_increment * 1.25_wp
            ELSE IF (conv_result%iterations > OPTIMAL_ITERS + 3_i4) THEN
                target_dt = time_ctrl%current_increment * 0.85_wp
            ELSE
                target_dt = time_ctrl%current_increment
            END IF
        ELSE
            target_dt = time_ctrl%current_increment * 0.25_wp
        END IF
        IF (state%cutbackOccurred .AND. conv_result%converged) THEN
            target_dt = MIN(target_dt, time_ctrl%current_increment * 0.9_wp)
        END IF

        target_dt = MIN(target_dt, time_ctrl%max_increment)
        target_dt = MAX(target_dt, time_ctrl%min_increment)

        time_ctrl%current_increment = target_dt
        time_result%suggested_dt = target_dt
        time_result%success = .TRUE.
        status%status_code = IF_STATUS_OK

    END SUBROUTINE MD_TimeIncrement_Calc

END MODULE MD_Step_Proc
