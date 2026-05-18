# `MD_Step_Proc.f90`

- **Source**: `L3_MD/Analysis/Step/MD_Step_Proc.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Step_Proc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Step_Proc`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Step`
- **第四段角色（四段式）**: `_Proc`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Step`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Step/MD_Step_Proc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_IncrementControl` (lines 169–178)

```fortran
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
```

### `UF_SolutionControl` (lines 185–198)

```fortran
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
```

### `UF_RiksControl` (lines 205–212)

```fortran
    TYPE, PUBLIC :: UF_RiksControl
        REAL(wp) :: arc_length_init = 0.1_wp
        REAL(wp) :: arc_length_max = 1.0_wp
        REAL(wp) :: arc_length_min = 1.0E-5_wp
        REAL(wp) :: psi = 1.0_wp
        INTEGER(i4) :: max_increments = 500_i4
        INTEGER(i4) :: max_iter_per_inc = 16_i4
    END TYPE UF_RiksControl
```

### `UF_ModalControl_Modes` (lines 221–224)

```fortran
    TYPE, PUBLIC :: UF_ModalControl_Modes
        INTEGER(i4) :: n_modes          = 10_i4      ! Requested N_modes
        INTEGER(i4) :: n_modes_max      = 200_i4     ! Maximum modes
    END TYPE UF_ModalControl_Modes
```

### `UF_ModalControl_Freq` (lines 226–229)

```fortran
    TYPE, PUBLIC :: UF_ModalControl_Freq
        REAL(wp)    :: freq_min         = 0.0_wp     ! Min frequency (Hz), 0=no lower bound
        REAL(wp)    :: freq_max         = 1.0E6_wp   ! Max frequency (Hz)
    END TYPE UF_ModalControl_Freq
```

### `UF_ModalControl_Solver` (lines 231–236)

```fortran
    TYPE, PUBLIC :: UF_ModalControl_Solver
        INTEGER(i4) :: solver_type      = MODAL_LANCZOS ! Block Lanczos / Subspace
        INTEGER(i4) :: block_size       = 8_i4       ! Lanczos block size
        REAL(wp)    :: lanczos_tol      = 1.0E-8_wp  ! Lanczos convergence tolerance
        INTEGER(i4) :: max_lanczos_iter = 500_i4     ! Max Lanczos iterations
    END TYPE UF_ModalControl_Solver
```

### `UF_ModalControl_Flags` (lines 238–243)

```fortran
    TYPE, PUBLIC :: UF_ModalControl_Flags
        LOGICAL     :: normalize_mass   = .TRUE.     ! Mass-normalize: phi^T M phi = I
        LOGICAL     :: include_prestress= .FALSE.    ! Include geometric stiffness K_sigma
        REAL(wp)    :: shift_freq       = 0.0_wp     ! Shift frequency (Hz)
        INTEGER(i4) :: residual_modes   = 0_i4       ! Residual modes count
    END TYPE UF_ModalControl_Flags
```

### `UF_ModalControl_Modes` (lines 245–248)

```fortran
    TYPE, PUBLIC :: UF_ModalControl_Modes
        INTEGER(i4) :: n_modes          = 10_i4      ! Requested N_modes
        INTEGER(i4) :: n_modes_max      = 200_i4     ! Maximum modes
    END TYPE UF_ModalControl_Modes
```

### `UF_ModalControl_Freq` (lines 250–253)

```fortran
    TYPE, PUBLIC :: UF_ModalControl_Freq
        REAL(wp)    :: freq_min         = 0.0_wp     ! Min frequency (Hz), 0=no lower bound
        REAL(wp)    :: freq_max         = 1.0E6_wp   ! Max frequency (Hz)
    END TYPE UF_ModalControl_Freq
```

### `UF_ModalControl_Solver` (lines 255–260)

```fortran
    TYPE, PUBLIC :: UF_ModalControl_Solver
        INTEGER(i4) :: solver_type      = MODAL_LANCZOS ! Block Lanczos / Subspace
        INTEGER(i4) :: block_size       = 8_i4       ! Lanczos block size
        REAL(wp)    :: lanczos_tol      = 1.0E-8_wp  ! Lanczos convergence tolerance
        INTEGER(i4) :: max_lanczos_iter = 500_i4     ! Max Lanczos iterations
    END TYPE UF_ModalControl_Solver
```

### `UF_ModalControl_Flags` (lines 262–267)

```fortran
    TYPE, PUBLIC :: UF_ModalControl_Flags
        LOGICAL     :: normalize_mass   = .TRUE.     ! Mass-normalize: phi^T M phi = I
        LOGICAL     :: include_prestress= .FALSE.    ! Include geometric stiffness K_sigma
        REAL(wp)    :: shift_freq       = 0.0_wp     ! Shift frequency (Hz)
        INTEGER(i4) :: residual_modes   = 0_i4       ! Residual modes count
    END TYPE UF_ModalControl_Flags
```

### `UF_ModalControl` (lines 269–274)

```fortran
    TYPE, PUBLIC :: UF_ModalControl
        TYPE(UF_ModalControl_Modes)  :: modes
        TYPE(UF_ModalControl_Freq)   :: freq
        TYPE(UF_ModalControl_Solver) :: solver
        TYPE(UF_ModalControl_Flags)  :: flags
    END TYPE UF_ModalControl
```

### `UF_ModalStepDef_Base` (lines 281–285)

```fortran
    TYPE, PUBLIC :: UF_ModalStepDef_Base
        CHARACTER(LEN=64)        :: name        = ""
        INTEGER(i4)              :: procedure   = PROC_MODAL   ! = 21
        INTEGER(i4)              :: nlgeom      = NLGEOM_OFF   ! Geometric nonlinearity flag
    END TYPE UF_ModalStepDef_Base
```

### `UF_ModalStepDef_Ctrl` (lines 287–290)

```fortran
    TYPE, PUBLIC :: UF_ModalStepDef_Ctrl
        TYPE(UF_ModalControl)    :: modal_ctrl
        TYPE(UF_OutputManager)   :: output
    END TYPE UF_ModalStepDef_Ctrl
```

### `UF_ModalStepDef_Pre` (lines 292–294)

```fortran
    TYPE, PUBLIC :: UF_ModalStepDef_Pre
        INTEGER(i4)              :: prestress_step_id = -1_i4   ! Preceding prestress step ID
    END TYPE UF_ModalStepDef_Pre
```

### `UF_ModalStepDef` (lines 296–300)

```fortran
    TYPE, PUBLIC :: UF_ModalStepDef
        TYPE(UF_ModalStepDef_Base) :: base
        TYPE(UF_ModalStepDef_Ctrl) :: ctrl
        TYPE(UF_ModalStepDef_Pre)  :: pre
    END TYPE UF_ModalStepDef
```

### `UF_SSDControl_Config` (lines 312–319)

```fortran
    TYPE, PUBLIC :: UF_SSDControl_Config
        INTEGER(i4) :: solution_method  = SSD_MODAL
        REAL(wp)    :: freq_start       = 1.0_wp
        REAL(wp)    :: freq_end         = 1000.0_wp
        INTEGER(i4) :: n_freq_points    = 200_i4
        INTEGER(i4) :: freq_spacing     = FREQ_LOG
        INTEGER(i4) :: damping_type     = DAMP_MODAL
    END TYPE UF_SSDControl_Config
```

### `UF_SSDControl_Modal` (lines 321–327)

```fortran
    TYPE, PUBLIC :: UF_SSDControl_Modal
        INTEGER(i4) :: n_modes_used     = -1_i4
        REAL(wp)    :: modal_damping    = 0.02_wp
        INTEGER(i4) :: modal_base_step_id = -1_i4
        INTEGER(i4) :: residual_modes   = 0_i4
        LOGICAL     :: subspace_nondiag_damp = .FALSE.
    END TYPE UF_SSDControl_Modal
```

### `UF_SSDControl_Direct` (lines 329–337)

```fortran
    TYPE, PUBLIC :: UF_SSDControl_Direct
        REAL(wp)    :: rayleigh_alpha   = 0.0_wp
        REAL(wp)    :: rayleigh_beta    = 1.0E-5_wp
        REAL(wp)    :: structural_damp  = 0.0_wp
        REAL(wp)    :: lu_reuse_tol     = 0.01_wp
        INTEGER(i4) :: max_reuse_steps  = 10_i4
        INTEGER(i4) :: ring_buffer_size = 30_i4
        LOGICAL     :: save_all_freqs   = .TRUE.
    END TYPE UF_SSDControl_Direct
```

### `UF_SSDControl_Config` (lines 339–346)

```fortran
    TYPE, PUBLIC :: UF_SSDControl_Config
        INTEGER(i4) :: solution_method  = SSD_MODAL
        REAL(wp)    :: freq_start       = 1.0_wp
        REAL(wp)    :: freq_end         = 1000.0_wp
        INTEGER(i4) :: n_freq_points    = 200_i4
        INTEGER(i4) :: freq_spacing     = FREQ_LOG
        INTEGER(i4) :: damping_type     = DAMP_MODAL
    END TYPE UF_SSDControl_Config
```

### `UF_SSDControl_Modal` (lines 348–354)

```fortran
    TYPE, PUBLIC :: UF_SSDControl_Modal
        INTEGER(i4) :: n_modes_used     = -1_i4
        REAL(wp)    :: modal_damping    = 0.02_wp
        INTEGER(i4) :: modal_base_step_id = -1_i4
        INTEGER(i4) :: residual_modes   = 0_i4
        LOGICAL     :: subspace_nondiag_damp = .FALSE.
    END TYPE UF_SSDControl_Modal
```

### `UF_SSDControl_Direct` (lines 356–364)

```fortran
    TYPE, PUBLIC :: UF_SSDControl_Direct
        REAL(wp)    :: rayleigh_alpha   = 0.0_wp
        REAL(wp)    :: rayleigh_beta    = 1.0E-5_wp
        REAL(wp)    :: structural_damp  = 0.0_wp
        REAL(wp)    :: lu_reuse_tol     = 0.01_wp
        INTEGER(i4) :: max_reuse_steps  = 10_i4
        INTEGER(i4) :: ring_buffer_size = 30_i4
        LOGICAL     :: save_all_freqs   = .TRUE.
    END TYPE UF_SSDControl_Direct
```

### `UF_SSDControl` (lines 366–370)

```fortran
    TYPE, PUBLIC :: UF_SSDControl
        TYPE(UF_SSDControl_Config)  :: config
        TYPE(UF_SSDControl_Modal)   :: modal
        TYPE(UF_SSDControl_Direct)  :: direct
    END TYPE UF_SSDControl
```

### `UF_BuckleControl_Modes` (lines 386–390)

```fortran
    TYPE, PUBLIC :: UF_BuckleControl_Modes
        INTEGER(i4) :: n_buckling_modes  = 5_i4      ! Number of buckling modes
        INTEGER(i4) :: solver_type      = BUCKLE_LANCZOS
        INTEGER(i4) :: block_size       = 4_i4       ! Lanczos block size
    END TYPE UF_BuckleControl_Modes
```

### `UF_BuckleControl_Lanczos` (lines 392–396)

```fortran
    TYPE, PUBLIC :: UF_BuckleControl_Lanczos
        REAL(wp)    :: lanczos_tol      = 1.0E-6_wp  ! Lanczos convergence tolerance
        INTEGER(i4) :: max_lanczos_iter = 300_i4
        REAL(wp)    :: shift_value       = 0.0_wp    ! Eigenvalue shift
    END TYPE UF_BuckleControl_Lanczos
```

### `UF_BuckleControl_Flags` (lines 398–401)

```fortran
    TYPE, PUBLIC :: UF_BuckleControl_Flags
        LOGICAL     :: include_K_stress  = .TRUE.    ! Include stress stiffness K_sigma
        INTEGER(i4) :: prestress_step_id = -1_i4     ! Preceding prestress step ID
    END TYPE UF_BuckleControl_Flags
```

### `UF_BuckleControl` (lines 403–407)

```fortran
    TYPE, PUBLIC :: UF_BuckleControl
        TYPE(UF_BuckleControl_Modes)    :: modes
        TYPE(UF_BuckleControl_Lanczos)  :: lanczos
        TYPE(UF_BuckleControl_Flags)    :: flags
    END TYPE UF_BuckleControl
```

### `UF_HeatTransControl_Mode` (lines 423–425)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Mode
        INTEGER(i4) :: analysis_mode    = HT_TRANSIENT
    END TYPE UF_HeatTransControl_Mode
```

### `UF_HeatTransControl_Time` (lines 427–432)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.01_wp
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_HeatTransControl_Time
```

### `UF_HeatTransControl_Steps` (lines 434–437)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_HeatTransControl_Steps
```

### `UF_HeatTransControl_Solver` (lines 439–445)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Solver
        REAL(wp)    :: theta_integration= 1.0_wp
        REAL(wp)    :: temp_tol         = 1.0E-3_wp
        REAL(wp)    :: flux_tol         = 1.0E-4_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_HeatTransControl_Solver
```

### `UF_HeatTransControl_Flags` (lines 447–450)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Flags
        LOGICAL     :: nonlinear_kT     = .FALSE.
        LOGICAL     :: include_radiation= .FALSE.
    END TYPE UF_HeatTransControl_Flags
```

### `UF_HeatTransControl_Mode` (lines 452–454)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Mode
        INTEGER(i4) :: analysis_mode    = HT_TRANSIENT ! Transient/Steady
    END TYPE UF_HeatTransControl_Mode
```

### `UF_HeatTransControl_Time` (lines 456–461)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Time
        REAL(wp)    :: time_period      = 1.0_wp       ! Analysis time period
        REAL(wp)    :: initial_time_inc = 0.01_wp      ! Initial time increment dt
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_HeatTransControl_Time
```

### `UF_HeatTransControl_Steps` (lines 463–466)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_HeatTransControl_Steps
```

### `UF_HeatTransControl_Solver` (lines 468–474)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Solver
        REAL(wp)    :: theta_integration= 1.0_wp       ! 1.0=backward Euler; 0.5=Crank-Nicolson
        REAL(wp)    :: temp_tol         = 1.0E-3_wp    ! Temperature convergence tolerance (K)
        REAL(wp)    :: flux_tol         = 1.0E-4_wp    ! Heat flux convergence tolerance
        INTEGER(i4) :: max_iterations   = 16_i4        ! Max nonlinear iterations
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_HeatTransControl_Solver
```

### `UF_HeatTransControl_Flags` (lines 476–479)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl_Flags
        LOGICAL     :: nonlinear_kT     = .FALSE.      ! k(T) temperature-dependent conductivity
        LOGICAL     :: include_radiation= .FALSE.      ! Include radiation boundary
    END TYPE UF_HeatTransControl_Flags
```

### `UF_HeatTransControl` (lines 481–487)

```fortran
    TYPE, PUBLIC :: UF_HeatTransControl
        TYPE(UF_HeatTransControl_Mode)   :: mode
        TYPE(UF_HeatTransControl_Time)   :: time
        TYPE(UF_HeatTransControl_Steps)  :: steps
        TYPE(UF_HeatTransControl_Solver) :: solver
        TYPE(UF_HeatTransControl_Flags)  :: flags
    END TYPE UF_HeatTransControl
```

### `UF_ThermalBCManager_PrescribedT` (lines 494–497)

```fortran
    TYPE, PUBLIC :: UF_ThermalBCManager_PrescribedT
        INTEGER(i4), ALLOCATABLE :: prescribed_T_nodes(:)
        REAL(wp),    ALLOCATABLE :: prescribed_T_vals(:)
    END TYPE UF_ThermalBCManager_PrescribedT
```

### `UF_ThermalBCManager_Flux` (lines 499–502)

```fortran
    TYPE, PUBLIC :: UF_ThermalBCManager_Flux
        INTEGER(i4), ALLOCATABLE :: flux_face_ids(:)
        REAL(wp),    ALLOCATABLE :: flux_vals(:)
    END TYPE UF_ThermalBCManager_Flux
```

### `UF_ThermalBCManager_Convection` (lines 504–508)

```fortran
    TYPE, PUBLIC :: UF_ThermalBCManager_Convection
        INTEGER(i4), ALLOCATABLE :: conv_face_ids(:)
        REAL(wp),    ALLOCATABLE :: conv_h(:)
        REAL(wp),    ALLOCATABLE :: conv_T_inf(:)
    END TYPE UF_ThermalBCManager_Convection
```

### `UF_ThermalBCManager_Radiation` (lines 510–514)

```fortran
    TYPE, PUBLIC :: UF_ThermalBCManager_Radiation
        INTEGER(i4), ALLOCATABLE :: rad_face_ids(:)
        REAL(wp),    ALLOCATABLE :: rad_emissivity(:)
        REAL(wp),    ALLOCATABLE :: rad_T_amb(:)
    END TYPE UF_ThermalBCManager_Radiation
```

### `UF_ThermalBCManager` (lines 516–521)

```fortran
    TYPE, PUBLIC :: UF_ThermalBCManager
        TYPE(UF_ThermalBCManager_PrescribedT) :: prescribedT
        TYPE(UF_ThermalBCManager_Flux)        :: flux
        TYPE(UF_ThermalBCManager_Convection)  :: convection
        TYPE(UF_ThermalBCManager_Radiation)   :: radiation
    END TYPE UF_ThermalBCManager
```

### `UF_CTDispControl_Mode` (lines 530–532)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Mode
        INTEGER(i4) :: coupling_type    = CTD_SEQUENTIAL
    END TYPE UF_CTDispControl_Mode
```

### `UF_CTDispControl_Time` (lines 534–539)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.01_wp
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_CTDispControl_Time
```

### `UF_CTDispControl_Steps` (lines 541–544)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTDispControl_Steps
```

### `UF_CTDispControl_Config` (lines 546–549)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Config
        REAL(wp)    :: theta_heat       = 1.0_wp
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
    END TYPE UF_CTDispControl_Config
```

### `UF_CTDispControl_Solver` (lines 551–556)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol     = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTDispControl_Solver
```

### `UF_CTDispControl_Material` (lines 558–561)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Material
        LOGICAL     :: include_plastic_heat = .FALSE.
        REAL(wp)    :: taylor_quinney      = 0.9_wp
    END TYPE UF_CTDispControl_Material
```

### `UF_CTDispControl_Mode` (lines 563–565)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Mode
        INTEGER(i4) :: coupling_type    = CTD_SEQUENTIAL
    END TYPE UF_CTDispControl_Mode
```

### `UF_CTDispControl_Time` (lines 567–572)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.01_wp
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_CTDispControl_Time
```

### `UF_CTDispControl_Steps` (lines 574–577)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTDispControl_Steps
```

### `UF_CTDispControl_Config` (lines 579–582)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Config
        REAL(wp)    :: theta_heat       = 1.0_wp
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
    END TYPE UF_CTDispControl_Config
```

### `UF_CTDispControl_Solver` (lines 584–589)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol     = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTDispControl_Solver
```

### `UF_CTDispControl_Material` (lines 591–594)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Material
        LOGICAL     :: include_plastic_heat = .FALSE.
        REAL(wp)    :: taylor_quinney      = 0.9_wp
    END TYPE UF_CTDispControl_Material
```

### `UF_CTDispControl_Mode` (lines 596–598)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Mode
        INTEGER(i4) :: coupling_type    = CTD_SEQUENTIAL
    END TYPE UF_CTDispControl_Mode
```

### `UF_CTDispControl_Time` (lines 600–605)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.01_wp
        REAL(wp)    :: min_time_inc     = 1.0E-8_wp
        REAL(wp)    :: max_time_inc     = 0.1_wp
    END TYPE UF_CTDispControl_Time
```

### `UF_CTDispControl_Steps` (lines 607–610)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Steps
        INTEGER(i4) :: max_increments   = 1000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTDispControl_Steps
```

### `UF_CTDispControl_Config` (lines 612–615)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Config
        REAL(wp)    :: theta_heat       = 1.0_wp
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
    END TYPE UF_CTDispControl_Config
```

### `UF_CTDispControl_Solver` (lines 617–622)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol     = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTDispControl_Solver
```

### `UF_CTDispControl_Flags` (lines 624–627)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl_Flags
        LOGICAL     :: include_plastic_heat = .FALSE.
        REAL(wp)    :: taylor_quinney      = 0.9_wp
    END TYPE UF_CTDispControl_Flags
```

### `UF_CTDispControl` (lines 629–636)

```fortran
    TYPE, PUBLIC :: UF_CTDispControl
        TYPE(UF_CTDispControl_Mode)   :: mode
        TYPE(UF_CTDispControl_Time)   :: time
        TYPE(UF_CTDispControl_Steps)  :: steps
        TYPE(UF_CTDispControl_Config) :: config
        TYPE(UF_CTDispControl_Solver) :: solver
        TYPE(UF_CTDispControl_Flags)  :: flags
    END TYPE UF_CTDispControl
```

### `UF_CTElecControl_Time` (lines 643–648)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.001_wp
        REAL(wp)    :: min_time_inc     = 1.0E-10_wp
        REAL(wp)    :: max_time_inc     = 0.01_wp
    END TYPE UF_CTElecControl_Time
```

### `UF_CTElecControl_Steps` (lines 650–653)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTElecControl_Steps
```

### `UF_CTElecControl_Thermal` (lines 655–657)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Thermal
        REAL(wp)    :: theta_heat       = 1.0_wp
    END TYPE UF_CTElecControl_Thermal
```

### `UF_CTElecControl_Solver` (lines 659–664)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Solver
        REAL(wp)    :: temp_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTElecControl_Solver
```

### `UF_CTElecControl_Material` (lines 666–670)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Material
        LOGICAL     :: include_seebeck  = .FALSE.
        LOGICAL     :: sigma_temp_depend= .TRUE.
        LOGICAL     :: kappa_temp_depend= .TRUE.
    END TYPE UF_CTElecControl_Material
```

### `UF_CTElecControl_Time` (lines 672–677)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.001_wp
        REAL(wp)    :: min_time_inc     = 1.0E-10_wp
        REAL(wp)    :: max_time_inc     = 0.01_wp
    END TYPE UF_CTElecControl_Time
```

### `UF_CTElecControl_Steps` (lines 679–682)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTElecControl_Steps
```

### `UF_CTElecControl_Thermal` (lines 684–686)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Thermal
        REAL(wp)    :: theta_heat       = 1.0_wp
    END TYPE UF_CTElecControl_Thermal
```

### `UF_CTElecControl_Solver` (lines 688–693)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Solver
        REAL(wp)    :: temp_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTElecControl_Solver
```

### `UF_CTElecControl_Material` (lines 695–699)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Material
        LOGICAL     :: include_seebeck  = .FALSE.
        LOGICAL     :: sigma_temp_depend= .TRUE.
        LOGICAL     :: kappa_temp_depend= .TRUE.
    END TYPE UF_CTElecControl_Material
```

### `UF_CTElecControl_Time` (lines 701–706)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Time
        REAL(wp)    :: time_period      = 1.0_wp
        REAL(wp)    :: initial_time_inc = 0.001_wp
        REAL(wp)    :: min_time_inc     = 1.0E-10_wp
        REAL(wp)    :: max_time_inc     = 0.01_wp
    END TYPE UF_CTElecControl_Time
```

### `UF_CTElecControl_Steps` (lines 708–711)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_CTElecControl_Steps
```

### `UF_CTElecControl_Solver` (lines 713–719)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Solver
        REAL(wp)    :: theta_heat       = 1.0_wp
        REAL(wp)    :: temp_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_CTElecControl_Solver
```

### `UF_CTElecControl_Material` (lines 721–725)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl_Material
        LOGICAL     :: include_seebeck  = .FALSE.
        LOGICAL     :: sigma_temp_depend= .TRUE.
        LOGICAL     :: kappa_temp_depend= .TRUE.
    END TYPE UF_CTElecControl_Material
```

### `UF_CTElecControl` (lines 727–732)

```fortran
    TYPE, PUBLIC :: UF_CTElecControl
        TYPE(UF_CTElecControl_Time)     :: time
        TYPE(UF_CTElecControl_Steps)    :: steps
        TYPE(UF_CTElecControl_Solver)   :: solver
        TYPE(UF_CTElecControl_Material) :: material
    END TYPE UF_CTElecControl
```

### `UF_ElecBCManager` (lines 739–745)

```fortran
    TYPE, PUBLIC :: UF_ElecBCManager
        INTEGER(i4), ALLOCATABLE :: prescribed_phi_nodes(:)
        REAL(wp),    ALLOCATABLE :: prescribed_phi_vals(:)
        INTEGER(i4), ALLOCATABLE :: current_face_ids(:)
        REAL(wp),    ALLOCATABLE :: current_flux_vals(:)
        INTEGER(i4), ALLOCATABLE :: elec_contact_ids(:)
    END TYPE UF_ElecBCManager
```

### `UF_GeostaticControl_Soil` (lines 754–759)

```fortran
    TYPE, PUBLIC :: UF_GeostaticControl_Soil
        INTEGER(i4) :: method           = GEO_K0_METHOD
        REAL(wp)    :: k0_horizontal    = 0.5_wp
        REAL(wp)    :: gravity_z        = -9.81_wp
        REAL(wp)    :: density_ref      = 2000.0_wp
    END TYPE UF_GeostaticControl_Soil
```

### `UF_GeostaticControl_Tol` (lines 761–764)

```fortran
    TYPE, PUBLIC :: UF_GeostaticControl_Tol
        REAL(wp)    :: residual_tol     = 1.0E-3_wp
        REAL(wp)    :: correction_tol   = 1.0E-2_wp
    END TYPE UF_GeostaticControl_Tol
```

### `UF_GeostaticControl_Steps` (lines 766–769)

```fortran
    TYPE, PUBLIC :: UF_GeostaticControl_Steps
        INTEGER(i4) :: max_iterations   = 20_i4
        INTEGER(i4) :: max_increments   = 10_i4
    END TYPE UF_GeostaticControl_Steps
```

### `UF_GeostaticControl_Check` (lines 771–775)

```fortran
    TYPE, PUBLIC :: UF_GeostaticControl_Check
        REAL(wp)    :: disp_zero_check_tol = 1.0E-6_wp
        LOGICAL     :: check_stress_equil = .TRUE.
        LOGICAL     :: reset_displacements = .TRUE.
    END TYPE UF_GeostaticControl_Check
```

### `UF_GeostaticControl` (lines 777–782)

```fortran
    TYPE, PUBLIC :: UF_GeostaticControl
        TYPE(UF_GeostaticControl_Soil)  :: soil
        TYPE(UF_GeostaticControl_Tol)   :: tol
        TYPE(UF_GeostaticControl_Steps) :: steps
        TYPE(UF_GeostaticControl_Check) :: check
    END TYPE UF_GeostaticControl
```

### `UF_SoilsControl_Time` (lines 789–794)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Time
        REAL(wp)    :: time_period      = 864000.0_wp
        REAL(wp)    :: initial_time_inc = 1.0_wp
        REAL(wp)    :: min_time_inc     = 1.0E-4_wp
        REAL(wp)    :: max_time_inc     = 86400.0_wp
    END TYPE UF_SoilsControl_Time
```

### `UF_SoilsControl_Steps` (lines 796–799)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_SoilsControl_Steps
```

### `UF_SoilsControl_Log` (lines 801–805)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Log
        REAL(wp)    :: theta_int        = 1.0_wp
        REAL(wp)    :: log_time_factor  = 2.0_wp
        LOGICAL     :: use_log_time     = .TRUE.
    END TYPE UF_SoilsControl_Log
```

### `UF_SoilsControl_Biot` (lines 807–812)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Biot
        REAL(wp)    :: biot_alpha       = 1.0_wp
        REAL(wp)    :: biot_modulus_M   = 1.0E9_wp
        REAL(wp)    :: k_permeability   = 1.0E-9_wp
        REAL(wp)    :: gamma_water      = 9810.0_wp
    END TYPE UF_SoilsControl_Biot
```

### `UF_SoilsControl_Solver` (lines 814–819)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Solver
        REAL(wp)    :: disp_tol         = 1.0E-5_wp
        REAL(wp)    :: pore_tol         = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        INTEGER(i4) :: prestress_step_id= -1
    END TYPE UF_SoilsControl_Solver
```

### `UF_SoilsControl_Time` (lines 821–826)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Time
        REAL(wp)    :: time_period      = 864000.0_wp
        REAL(wp)    :: initial_time_inc = 1.0_wp
        REAL(wp)    :: min_time_inc     = 1.0E-4_wp
        REAL(wp)    :: max_time_inc     = 86400.0_wp
    END TYPE UF_SoilsControl_Time
```

### `UF_SoilsControl_Steps` (lines 828–831)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Steps
        INTEGER(i4) :: max_increments   = 5000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_SoilsControl_Steps
```

### `UF_SoilsControl_Log` (lines 833–837)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Log
        REAL(wp)    :: theta_int        = 1.0_wp
        REAL(wp)    :: log_time_factor  = 2.0_wp
        LOGICAL     :: use_log_time     = .TRUE.
    END TYPE UF_SoilsControl_Log
```

### `UF_SoilsControl_Biot` (lines 839–844)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Biot
        REAL(wp)    :: biot_alpha       = 1.0_wp
        REAL(wp)    :: biot_modulus_M   = 1.0E9_wp
        REAL(wp)    :: k_permeability   = 1.0E-9_wp
        REAL(wp)    :: gamma_water      = 9810.0_wp
    END TYPE UF_SoilsControl_Biot
```

### `UF_SoilsControl_Solver` (lines 846–851)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl_Solver
        REAL(wp)    :: disp_tol         = 1.0E-5_wp
        REAL(wp)    :: pore_tol         = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        INTEGER(i4) :: prestress_step_id= -1
    END TYPE UF_SoilsControl_Solver
```

### `UF_SoilsControl` (lines 853–859)

```fortran
    TYPE, PUBLIC :: UF_SoilsControl
        TYPE(UF_SoilsControl_Time)   :: time
        TYPE(UF_SoilsControl_Steps)  :: steps
        TYPE(UF_SoilsControl_Log)    :: log
        TYPE(UF_SoilsControl_Biot)   :: biot
        TYPE(UF_SoilsControl_Solver) :: solver
    END TYPE UF_SoilsControl
```

### `UF_PoreBCManager` (lines 866–870)

```fortran
    TYPE, PUBLIC :: UF_PoreBCManager
        INTEGER(i4), ALLOCATABLE :: zero_pore_nodes(:)
        INTEGER(i4), ALLOCATABLE :: imperv_face_ids(:)
        REAL(wp),    ALLOCATABLE :: init_pore_vals(:)
    END TYPE UF_PoreBCManager
```

### `UF_ViscoControl_Time` (lines 877–882)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Time
        REAL(wp)    :: time_period      = 3600.0_wp
        REAL(wp)    :: initial_time_inc = 1.0_wp
        REAL(wp)    :: min_time_inc     = 1.0E-6_wp
        REAL(wp)    :: max_time_inc     = 100.0_wp
    END TYPE UF_ViscoControl_Time
```

### `UF_ViscoControl_Steps` (lines 884–887)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Steps
        INTEGER(i4) :: max_increments   = 10000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_ViscoControl_Steps
```

### `UF_ViscoControl_Log` (lines 889–892)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Log
        LOGICAL     :: use_log_time     = .TRUE.
        REAL(wp)    :: log_time_factor  = 1.5_wp
    END TYPE UF_ViscoControl_Log
```

### `UF_ViscoControl_Config` (lines 894–897)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Config
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
        INTEGER(i4) :: n_maxwell        = 3_i4
    END TYPE UF_ViscoControl_Config
```

### `UF_ViscoControl_Solver` (lines 899–905)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Solver
        REAL(wp)    :: maxwell_tol      = 1.0E-6_wp
        REAL(wp)    :: residual_tol     = 1.0E-5_wp
        REAL(wp)    :: correction_tol   = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_ViscoControl_Solver
```

### `UF_ViscoControl_Time` (lines 907–912)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Time
        REAL(wp)    :: time_period      = 3600.0_wp
        REAL(wp)    :: initial_time_inc = 1.0_wp
        REAL(wp)    :: min_time_inc     = 1.0E-6_wp
        REAL(wp)    :: max_time_inc     = 100.0_wp
    END TYPE UF_ViscoControl_Time
```

### `UF_ViscoControl_Steps` (lines 914–917)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Steps
        INTEGER(i4) :: max_increments   = 10000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_ViscoControl_Steps
```

### `UF_ViscoControl_Log` (lines 919–922)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Log
        LOGICAL     :: use_log_time     = .TRUE.
        REAL(wp)    :: log_time_factor  = 1.5_wp
    END TYPE UF_ViscoControl_Log
```

### `UF_ViscoControl_Config` (lines 924–927)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Config
        INTEGER(i4) :: nlgeom           = NLGEOM_OFF
        INTEGER(i4) :: n_maxwell        = 3_i4
    END TYPE UF_ViscoControl_Config
```

### `UF_ViscoControl_Solver` (lines 929–935)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl_Solver
        REAL(wp)    :: maxwell_tol      = 1.0E-6_wp
        REAL(wp)    :: residual_tol     = 1.0E-5_wp
        REAL(wp)    :: correction_tol   = 1.0E-3_wp
        INTEGER(i4) :: max_iterations   = 16_i4
        REAL(wp)    :: cutback_factor   = 0.25_wp
    END TYPE UF_ViscoControl_Solver
```

### `UF_ViscoControl` (lines 937–943)

```fortran
    TYPE, PUBLIC :: UF_ViscoControl
        TYPE(UF_ViscoControl_Time)   :: time
        TYPE(UF_ViscoControl_Steps)  :: steps
        TYPE(UF_ViscoControl_Log)    :: log
        TYPE(UF_ViscoControl_Config) :: config
        TYPE(UF_ViscoControl_Solver) :: solver
    END TYPE UF_ViscoControl
```

### `UF_AnnealControl_Temp` (lines 953–956)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Temp
        REAL(wp)    :: T_anneal         = 1173.0_wp
        REAL(wp)    :: T_initial        = 293.0_wp
    END TYPE UF_AnnealControl_Temp
```

### `UF_AnnealControl_Rate` (lines 958–962)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Rate
        REAL(wp)    :: heating_rate     = 5.0_wp
        REAL(wp)    :: holding_time     = 3600.0_wp
        REAL(wp)    :: cooling_rate     = -10.0_wp
    END TYPE UF_AnnealControl_Rate
```

### `UF_AnnealControl_Time` (lines 964–968)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Time
        REAL(wp)    :: initial_time_inc = 0.5_wp
        REAL(wp)    :: min_time_inc     = 1.0E-5_wp
        REAL(wp)    :: max_time_inc     = 5.0_wp
    END TYPE UF_AnnealControl_Time
```

### `UF_AnnealControl_Steps` (lines 970–973)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Steps
        INTEGER(i4) :: max_increments   = 50000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_AnnealControl_Steps
```

### `UF_AnnealControl_Config` (lines 975–980)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Config
        INTEGER(i4) :: nlgeom           = NLGEOM_ON
        LOGICAL     :: clear_plastic    = .TRUE.
        LOGICAL     :: clear_creep      = .FALSE.
        LOGICAL     :: reset_hardening  = .TRUE.
    END TYPE UF_AnnealControl_Config
```

### `UF_AnnealControl_Solver` (lines 982–986)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-4_wp
        REAL(wp)    :: temp_tol         = 0.5_wp
        INTEGER(i4) :: max_iterations   = 20_i4
    END TYPE UF_AnnealControl_Solver
```

### `UF_AnnealControl_Temp` (lines 988–991)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Temp
        REAL(wp)    :: T_anneal         = 1173.0_wp
        REAL(wp)    :: T_initial        = 293.0_wp
    END TYPE UF_AnnealControl_Temp
```

### `UF_AnnealControl_Rate` (lines 993–997)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Rate
        REAL(wp)    :: heating_rate     = 5.0_wp
        REAL(wp)    :: holding_time     = 3600.0_wp
        REAL(wp)    :: cooling_rate     = -10.0_wp
    END TYPE UF_AnnealControl_Rate
```

### `UF_AnnealControl_Time` (lines 999–1003)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Time
        REAL(wp)    :: initial_time_inc = 0.5_wp
        REAL(wp)    :: min_time_inc     = 1.0E-5_wp
        REAL(wp)    :: max_time_inc     = 5.0_wp
    END TYPE UF_AnnealControl_Time
```

### `UF_AnnealControl_Steps` (lines 1005–1008)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Steps
        INTEGER(i4) :: max_increments   = 50000_i4
        LOGICAL     :: auto_increment   = .TRUE.
    END TYPE UF_AnnealControl_Steps
```

### `UF_AnnealControl_Config` (lines 1010–1015)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Config
        INTEGER(i4) :: nlgeom           = NLGEOM_ON
        LOGICAL     :: clear_plastic    = .TRUE.
        LOGICAL     :: clear_creep      = .FALSE.
        LOGICAL     :: reset_hardening  = .TRUE.
    END TYPE UF_AnnealControl_Config
```

### `UF_AnnealControl_Solver` (lines 1017–1021)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl_Solver
        REAL(wp)    :: mech_res_tol     = 1.0E-4_wp
        REAL(wp)    :: temp_tol         = 0.5_wp
        INTEGER(i4) :: max_iterations   = 20_i4
    END TYPE UF_AnnealControl_Solver
```

### `UF_AnnealControl` (lines 1023–1030)

```fortran
    TYPE, PUBLIC :: UF_AnnealControl
        TYPE(UF_AnnealControl_Temp)   :: temp
        TYPE(UF_AnnealControl_Rate)   :: rate
        TYPE(UF_AnnealControl_Time)   :: time
        TYPE(UF_AnnealControl_Steps)  :: steps
        TYPE(UF_AnnealControl_Config) :: config
        TYPE(UF_AnnealControl_Solver) :: solver
    END TYPE UF_AnnealControl
```

### `UF_StaticPerturbControl` (lines 1037–1043)

```fortran
    TYPE, PUBLIC :: UF_StaticPerturbControl
        LOGICAL     :: include_prestress    = .TRUE.   ! Include K_sigma from base state
        LOGICAL     :: include_friction     = .FALSE.  ! Linearized friction tangent
        INTEGER(i4) :: base_step_id         = -1_i4   ! ID of preceding general step
        LOGICAL     :: multi_load_case      = .FALSE.  ! Multiple load cases in one step
        INTEGER(i4) :: n_load_cases         = 1_i4    ! Number of load cases
    END TYPE UF_StaticPerturbControl
```

### `UF_DynamicSubspaceControl_Time` (lines 1050–1055)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-8_wp
        REAL(wp)    :: max_time_inc         = 0.1_wp
    END TYPE UF_DynamicSubspaceControl_Time
```

### `UF_DynamicSubspaceControl_Steps` (lines 1057–1060)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Steps
        INTEGER(i4) :: max_increments       = 5000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_DynamicSubspaceControl_Steps
```

### `UF_DynamicSubspaceControl_Solver` (lines 1062–1066)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Solver
        INTEGER(i4) :: n_modes_used         = -1_i4   ! -1 = all extracted modes
        INTEGER(i4) :: max_iter             = 8_i4
        REAL(wp)    :: residual_tol         = 1.0E-4_wp
    END TYPE UF_DynamicSubspaceControl_Solver
```

### `UF_DynamicSubspaceControl_Modal` (lines 1068–1072)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Modal
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 1.0E-4_wp
        INTEGER(i4) :: modal_base_step_id   = -1_i4   ! Frequency extraction step
    END TYPE UF_DynamicSubspaceControl_Modal
```

### `UF_DynamicSubspaceControl_Time` (lines 1074–1079)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-8_wp
        REAL(wp)    :: max_time_inc         = 0.1_wp
    END TYPE UF_DynamicSubspaceControl_Time
```

### `UF_DynamicSubspaceControl_Steps` (lines 1081–1084)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Steps
        INTEGER(i4) :: max_increments       = 5000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_DynamicSubspaceControl_Steps
```

### `UF_DynamicSubspaceControl_Solver` (lines 1086–1090)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Solver
        INTEGER(i4) :: n_modes_used         = -1_i4   ! -1 = all extracted modes
        INTEGER(i4) :: max_iter             = 8_i4
        REAL(wp)    :: residual_tol         = 1.0E-4_wp
    END TYPE UF_DynamicSubspaceControl_Solver
```

### `UF_DynamicSubspaceControl_Modal` (lines 1092–1096)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl_Modal
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 1.0E-4_wp
        INTEGER(i4) :: modal_base_step_id   = -1_i4   ! Frequency extraction step
    END TYPE UF_DynamicSubspaceControl_Modal
```

### `UF_DynamicSubspaceControl` (lines 1098–1103)

```fortran
    TYPE, PUBLIC :: UF_DynamicSubspaceControl
        TYPE(UF_DynamicSubspaceControl_Time)   :: time
        TYPE(UF_DynamicSubspaceControl_Steps)  :: steps
        TYPE(UF_DynamicSubspaceControl_Solver) :: solver
        TYPE(UF_DynamicSubspaceControl_Modal)  :: modal
    END TYPE UF_DynamicSubspaceControl
```

### `UF_ModalDynamicControl_Time` (lines 1110–1115)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-8_wp
        REAL(wp)    :: max_time_inc         = 0.01_wp
    END TYPE UF_ModalDynamicControl_Time
```

### `UF_ModalDynamicControl_Steps` (lines 1117–1120)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl_Steps
        INTEGER(i4) :: max_increments       = 10000_i4
        INTEGER(i4) :: n_modes_used         = -1_i4
    END TYPE UF_ModalDynamicControl_Steps
```

### `UF_ModalDynamicControl_Modal` (lines 1122–1126)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl_Modal
        REAL(wp)    :: modal_damping        = 0.02_wp
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 0.0_wp
    END TYPE UF_ModalDynamicControl_Modal
```

### `UF_ModalDynamicControl_Config` (lines 1128–1133)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl_Config
        LOGICAL     :: use_initial_cond     = .FALSE.
        INTEGER(i4) :: modal_base_step_id   = -1_i4
        INTEGER(i4) :: residual_modes       = 0_i4
        LOGICAL     :: use_explicit_modal   = .FALSE.
    END TYPE UF_ModalDynamicControl_Config
```

### `UF_ModalDynamicControl_Time` (lines 1135–1140)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-8_wp
        REAL(wp)    :: max_time_inc         = 0.01_wp
    END TYPE UF_ModalDynamicControl_Time
```

### `UF_ModalDynamicControl_Steps` (lines 1142–1145)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl_Steps
        INTEGER(i4) :: max_increments       = 10000_i4
        INTEGER(i4) :: n_modes_used         = -1_i4   ! -1 = all extracted modes
    END TYPE UF_ModalDynamicControl_Steps
```

### `UF_ModalDynamicControl_Modal` (lines 1147–1151)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl_Modal
        REAL(wp)    :: modal_damping        = 0.02_wp  ! Global modal damping ratio ?
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 0.0_wp
    END TYPE UF_ModalDynamicControl_Modal
```

### `UF_ModalDynamicControl_Config` (lines 1153–1158)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl_Config
        LOGICAL     :: use_initial_cond     = .FALSE.  ! IC from previous general step
        INTEGER(i4) :: modal_base_step_id   = -1_i4   ! Frequency extraction step
        INTEGER(i4) :: residual_modes       = 0_i4    ! Static correction modes
        LOGICAL     :: use_explicit_modal   = .FALSE. ! .TRUE. = central-diff on q_r (CFL-limited)
    END TYPE UF_ModalDynamicControl_Config
```

### `UF_ModalDynamicControl` (lines 1160–1165)

```fortran
    TYPE, PUBLIC :: UF_ModalDynamicControl
        TYPE(UF_ModalDynamicControl_Time)   :: time
        TYPE(UF_ModalDynamicControl_Steps)  :: steps
        TYPE(UF_ModalDynamicControl_Modal)  :: modal
        TYPE(UF_ModalDynamicControl_Config) :: config
    END TYPE UF_ModalDynamicControl
```

### `UF_RandomResponseControl_Freq` (lines 1172–1177)

```fortran
    TYPE, PUBLIC :: UF_RandomResponseControl_Freq
        REAL(wp)    :: freq_start           = 1.0_wp   ! PSD frequency range start (Hz)
        REAL(wp)    :: freq_end             = 2000.0_wp
        INTEGER(i4) :: n_freq_points        = 200_i4
        INTEGER(i4) :: freq_spacing         = FREQ_LOG  ! Log or linear
    END TYPE UF_RandomResponseControl_Freq
```

### `UF_RandomResponseControl_Modal` (lines 1179–1185)

```fortran
    TYPE, PUBLIC :: UF_RandomResponseControl_Modal
        INTEGER(i4) :: n_modes_used         = -1_i4
        REAL(wp)    :: modal_damping        = 0.02_wp
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 0.0_wp
        INTEGER(i4) :: modal_base_step_id   = -1_i4
    END TYPE UF_RandomResponseControl_Modal
```

### `UF_RandomResponseControl_Output` (lines 1187–1190)

```fortran
    TYPE, PUBLIC :: UF_RandomResponseControl_Output
        LOGICAL     :: compute_rms          = .TRUE.   ! Output RMS (1-sigma) values
        LOGICAL     :: compute_psd          = .TRUE.   ! Store full PSD fields
    END TYPE UF_RandomResponseControl_Output
```

### `UF_RandomResponseControl_Freq` (lines 1192–1197)

```fortran
    TYPE, PUBLIC :: UF_RandomResponseControl_Freq
        REAL(wp)    :: freq_start           = 1.0_wp   ! PSD frequency range start (Hz)
        REAL(wp)    :: freq_end             = 2000.0_wp
        INTEGER(i4) :: n_freq_points        = 200_i4
        INTEGER(i4) :: freq_spacing         = FREQ_LOG  ! Log or linear
    END TYPE UF_RandomResponseControl_Freq
```

### `UF_RandomResponseControl_Modal` (lines 1199–1205)

```fortran
    TYPE, PUBLIC :: UF_RandomResponseControl_Modal
        INTEGER(i4) :: n_modes_used         = -1_i4
        REAL(wp)    :: modal_damping        = 0.02_wp
        REAL(wp)    :: rayleigh_alpha       = 0.0_wp
        REAL(wp)    :: rayleigh_beta        = 0.0_wp
        INTEGER(i4) :: modal_base_step_id   = -1_i4
    END TYPE UF_RandomResponseControl_Modal
```

### `UF_RandomResponseControl_Output` (lines 1207–1210)

```fortran
    TYPE, PUBLIC :: UF_RandomResponseControl_Output
        LOGICAL     :: compute_rms          = .TRUE.   ! Output RMS (1-sigma) values
        LOGICAL     :: compute_psd          = .TRUE.   ! Store full PSD fields
    END TYPE UF_RandomResponseControl_Output
```

### `UF_RandomResponseControl` (lines 1212–1216)

```fortran
    TYPE, PUBLIC :: UF_RandomResponseControl
        TYPE(UF_RandomResponseControl_Freq)   :: freq
        TYPE(UF_RandomResponseControl_Modal)  :: modal
        TYPE(UF_RandomResponseControl_Output) :: output
    END TYPE UF_RandomResponseControl
```

### `UF_ResponseSpectrumControl_Config` (lines 1226–1229)

```fortran
    TYPE, PUBLIC :: UF_ResponseSpectrumControl_Config
        INTEGER(i4) :: combination_rule      = RS_CQC
        INTEGER(i4) :: n_excitation_dirs     = 1_i4   ! 1, 2, or 3 directions
    END TYPE UF_ResponseSpectrumControl_Config
```

### `UF_ResponseSpectrumControl_Scales` (lines 1231–1235)

```fortran
    TYPE, PUBLIC :: UF_ResponseSpectrumControl_Scales
        REAL(wp)    :: scale_x              = 1.0_wp  ! Scale factor X direction
        REAL(wp)    :: scale_y              = 1.0_wp
        REAL(wp)    :: scale_z              = 1.0_wp
    END TYPE UF_ResponseSpectrumControl_Scales
```

### `UF_ResponseSpectrumControl_Modal` (lines 1237–1241)

```fortran
    TYPE, PUBLIC :: UF_ResponseSpectrumControl_Modal
        REAL(wp)    :: modal_damping        = 0.05_wp
        INTEGER(i4) :: n_modes_used         = -1_i4
        INTEGER(i4) :: modal_base_step_id   = -1_i4
    END TYPE UF_ResponseSpectrumControl_Modal
```

### `UF_ResponseSpectrumControl` (lines 1243–1247)

```fortran
    TYPE, PUBLIC :: UF_ResponseSpectrumControl
        TYPE(UF_ResponseSpectrumControl_Config) :: config
        TYPE(UF_ResponseSpectrumControl_Scales) :: scales
        TYPE(UF_ResponseSpectrumControl_Modal)  :: modal
    END TYPE UF_ResponseSpectrumControl
```

### `UF_ComplexFreqControl_Solver` (lines 1254–1259)

```fortran
    TYPE, PUBLIC :: UF_ComplexFreqControl_Solver
        INTEGER(i4) :: n_eigenvalues        = 20_i4
        INTEGER(i4) :: solver_type          = MODAL_LANCZOS
        REAL(wp)    :: lanczos_tol          = 1.0E-8_wp
        INTEGER(i4) :: max_lanczos_iter     = 500_i4
    END TYPE UF_ComplexFreqControl_Solver
```

### `UF_ComplexFreqControl_Freq` (lines 1261–1264)

```fortran
    TYPE, PUBLIC :: UF_ComplexFreqControl_Freq
        REAL(wp)    :: freq_lower_bound     = 0.0_wp  ! Hz
        REAL(wp)    :: freq_upper_bound     = 1.0E6_wp
    END TYPE UF_ComplexFreqControl_Freq
```

### `UF_ComplexFreqControl_Rotor` (lines 1266–1269)

```fortran
    TYPE, PUBLIC :: UF_ComplexFreqControl_Rotor
        LOGICAL     :: include_gyroscopic   = .FALSE.  ! For rotating systems
        REAL(wp)    :: spin_speed           = 0.0_wp   ! rad/s (if gyroscopic)
    END TYPE UF_ComplexFreqControl_Rotor
```

### `UF_ComplexFreqControl_Base` (lines 1271–1273)

```fortran
    TYPE, PUBLIC :: UF_ComplexFreqControl_Base
        INTEGER(i4) :: modal_base_step_id   = -1_i4   ! Preceding real eigenvalue step
    END TYPE UF_ComplexFreqControl_Base
```

### `UF_ComplexFreqControl` (lines 1275–1280)

```fortran
    TYPE, PUBLIC :: UF_ComplexFreqControl
        TYPE(UF_ComplexFreqControl_Solver) :: solver
        TYPE(UF_ComplexFreqControl_Freq)   :: freq
        TYPE(UF_ComplexFreqControl_Rotor)  :: rotor
        TYPE(UF_ComplexFreqControl_Base)   :: base
    END TYPE UF_ComplexFreqControl
```

### `UF_MassDiffControl_Mode` (lines 1289–1291)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Mode
        INTEGER(i4) :: analysis_mode        = MD_TRANSIENT
    END TYPE UF_MassDiffControl_Mode
```

### `UF_MassDiffControl_Time` (lines 1293–1298)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Time
        REAL(wp)    :: time_period          = 3600.0_wp
        REAL(wp)    :: initial_time_inc     = 1.0_wp
        REAL(wp)    :: min_time_inc         = 1.0E-6_wp
        REAL(wp)    :: max_time_inc         = 100.0_wp
    END TYPE UF_MassDiffControl_Time
```

### `UF_MassDiffControl_Steps` (lines 1300–1303)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Steps
        INTEGER(i4) :: max_increments       = 10000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_MassDiffControl_Steps
```

### `UF_MassDiffControl_Solver` (lines 1305–1309)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Solver
        REAL(wp)    :: theta_int            = 1.0_wp   ! 1.0 = backward Euler
        REAL(wp)    :: conc_tol             = 1.0E-5_wp
        INTEGER(i4) :: max_iterations       = 16_i4
    END TYPE UF_MassDiffControl_Solver
```

### `UF_MassDiffControl_Flags` (lines 1311–1314)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Flags
        LOGICAL     :: include_soret        = .FALSE.  ! Stress-driven diffusion
        REAL(wp)    :: cutback_factor       = 0.25_wp
    END TYPE UF_MassDiffControl_Flags
```

### `UF_MassDiffControl_Mode` (lines 1316–1318)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Mode
        INTEGER(i4) :: analysis_mode        = MD_TRANSIENT
    END TYPE UF_MassDiffControl_Mode
```

### `UF_MassDiffControl_Time` (lines 1320–1325)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Time
        REAL(wp)    :: time_period          = 3600.0_wp
        REAL(wp)    :: initial_time_inc     = 1.0_wp
        REAL(wp)    :: min_time_inc         = 1.0E-6_wp
        REAL(wp)    :: max_time_inc         = 100.0_wp
    END TYPE UF_MassDiffControl_Time
```

### `UF_MassDiffControl_Steps` (lines 1327–1330)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Steps
        INTEGER(i4) :: max_increments       = 10000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_MassDiffControl_Steps
```

### `UF_MassDiffControl_Solver` (lines 1332–1336)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Solver
        REAL(wp)    :: theta_int            = 1.0_wp   ! 1.0 = backward Euler
        REAL(wp)    :: conc_tol             = 1.0E-5_wp
        INTEGER(i4) :: max_iterations       = 16_i4
    END TYPE UF_MassDiffControl_Solver
```

### `UF_MassDiffControl_Flags` (lines 1338–1341)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl_Flags
        LOGICAL     :: include_soret        = .FALSE.  ! Stress-driven diffusion
        REAL(wp)    :: cutback_factor       = 0.25_wp
    END TYPE UF_MassDiffControl_Flags
```

### `UF_MassDiffControl` (lines 1343–1349)

```fortran
    TYPE, PUBLIC :: UF_MassDiffControl
        TYPE(UF_MassDiffControl_Mode)   :: mode
        TYPE(UF_MassDiffControl_Time)   :: time
        TYPE(UF_MassDiffControl_Steps)  :: steps
        TYPE(UF_MassDiffControl_Solver) :: solver
        TYPE(UF_MassDiffControl_Flags)  :: flags
    END TYPE UF_MassDiffControl
```

### `UF_CoupledTESControl_Time` (lines 1356–1361)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-10_wp
        REAL(wp)    :: max_time_inc         = 0.01_wp
    END TYPE UF_CoupledTESControl_Time
```

### `UF_CoupledTESControl_Steps` (lines 1363–1366)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Steps
        INTEGER(i4) :: max_increments       = 5000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_CoupledTESControl_Steps
```

### `UF_CoupledTESControl_Thermal` (lines 1368–1370)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Thermal
        REAL(wp)    :: theta_heat           = 1.0_wp
    END TYPE UF_CoupledTESControl_Thermal
```

### `UF_CoupledTESControl_Solver` (lines 1372–1378)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Solver
        REAL(wp)    :: mech_res_tol         = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_res_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations       = 20_i4
        REAL(wp)    :: cutback_factor       = 0.25_wp
    END TYPE UF_CoupledTESControl_Solver
```

### `UF_CoupledTESControl_Config` (lines 1380–1384)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Config
        INTEGER(i4) :: nlgeom              = NLGEOM_OFF
        LOGICAL     :: include_seebeck      = .FALSE.
        LOGICAL     :: include_plastic_heat = .FALSE.
    END TYPE UF_CoupledTESControl_Config
```

### `UF_CoupledTESControl_Time` (lines 1386–1391)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Time
        REAL(wp)    :: time_period          = 1.0_wp
        REAL(wp)    :: initial_time_inc     = 0.001_wp
        REAL(wp)    :: min_time_inc         = 1.0E-10_wp
        REAL(wp)    :: max_time_inc         = 0.01_wp
    END TYPE UF_CoupledTESControl_Time
```

### `UF_CoupledTESControl_Steps` (lines 1393–1396)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Steps
        INTEGER(i4) :: max_increments       = 5000_i4
        LOGICAL     :: auto_increment       = .TRUE.
    END TYPE UF_CoupledTESControl_Steps
```

### `UF_CoupledTESControl_Thermal` (lines 1398–1400)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Thermal
        REAL(wp)    :: theta_heat           = 1.0_wp
    END TYPE UF_CoupledTESControl_Thermal
```

### `UF_CoupledTESControl_Solver` (lines 1402–1408)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Solver
        REAL(wp)    :: mech_res_tol         = 1.0E-5_wp
        REAL(wp)    :: temp_res_tol         = 1.0E-3_wp
        REAL(wp)    :: phi_res_tol          = 1.0E-6_wp
        INTEGER(i4) :: max_iterations       = 20_i4
        REAL(wp)    :: cutback_factor       = 0.25_wp
    END TYPE UF_CoupledTESControl_Solver
```

### `UF_CoupledTESControl_Config` (lines 1410–1414)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl_Config
        INTEGER(i4) :: nlgeom              = NLGEOM_OFF
        LOGICAL     :: include_seebeck      = .FALSE.
        LOGICAL     :: include_plastic_heat = .FALSE.
    END TYPE UF_CoupledTESControl_Config
```

### `UF_CoupledTESControl` (lines 1416–1422)

```fortran
    TYPE, PUBLIC :: UF_CoupledTESControl
        TYPE(UF_CoupledTESControl_Time)   :: time
        TYPE(UF_CoupledTESControl_Steps)  :: steps
        TYPE(UF_CoupledTESControl_Thermal):: thermal
        TYPE(UF_CoupledTESControl_Solver) :: solver
        TYPE(UF_CoupledTESControl_Config) :: config
    END TYPE UF_CoupledTESControl
```

### `UF_PiezoControl_Mode` (lines 1431–1434)

```fortran
    TYPE, PUBLIC :: UF_PiezoControl_Mode
        INTEGER(i4) :: mode               = PIEZO_SENSOR
        INTEGER(i4) :: base_proc          = PROC_STATIC  ! Underlying procedure
    END TYPE UF_PiezoControl_Mode
```

### `UF_PiezoControl_Tol` (lines 1436–1439)

```fortran
    TYPE, PUBLIC :: UF_PiezoControl_Tol
        REAL(wp)    :: electric_field_tol = 1.0E-6_wp
        REAL(wp)    :: charge_tol         = 1.0E-8_wp
    END TYPE UF_PiezoControl_Tol
```

### `UF_PiezoControl_Iter` (lines 1441–1444)

```fortran
    TYPE, PUBLIC :: UF_PiezoControl_Iter
        LOGICAL     :: include_damping    = .FALSE.  ! Piezo structural damping
        INTEGER(i4) :: max_iterations     = 16_i4
    END TYPE UF_PiezoControl_Iter
```

### `UF_PiezoControl` (lines 1446–1450)

```fortran
    TYPE, PUBLIC :: UF_PiezoControl
        TYPE(UF_PiezoControl_Mode) :: mode
        TYPE(UF_PiezoControl_Tol)  :: tol
        TYPE(UF_PiezoControl_Iter) :: iter
    END TYPE UF_PiezoControl
```

### `UF_ElectromagneticControl_Type` (lines 1460–1463)

```fortran
    TYPE, PUBLIC :: UF_ElectromagneticControl_Type
        INTEGER(i4) :: em_type           = EM_EDDY_CURRENT
        REAL(wp)    :: frequency         = 50.0_wp    ! Hz (eddy current)
    END TYPE UF_ElectromagneticControl_Type
```

### `UF_ElectromagneticControl_Time` (lines 1465–1470)

```fortran
    TYPE, PUBLIC :: UF_ElectromagneticControl_Time
        REAL(wp)    :: time_period        = 0.02_wp    ! s (transient)
        REAL(wp)    :: initial_time_inc   = 1.0E-4_wp
        REAL(wp)    :: min_time_inc       = 1.0E-8_wp
        REAL(wp)    :: max_time_inc       = 1.0E-3_wp
    END TYPE UF_ElectromagneticControl_Time
```

### `UF_ElectromagneticControl_Steps` (lines 1472–1474)

```fortran
    TYPE, PUBLIC :: UF_ElectromagneticControl_Steps
        INTEGER(i4) :: max_increments     = 2000_i4
    END TYPE UF_ElectromagneticControl_Steps
```

### `UF_ElectromagneticControl_Solver` (lines 1476–1479)

```fortran
    TYPE, PUBLIC :: UF_ElectromagneticControl_Solver
        REAL(wp)    :: A_field_tol        = 1.0E-8_wp  ! Magnetic vector potential tol
        INTEGER(i4) :: max_iterations     = 20_i4
    END TYPE UF_ElectromagneticControl_Solver
```

### `UF_ElectromagneticControl_Coupling` (lines 1481–1484)

```fortran
    TYPE, PUBLIC :: UF_ElectromagneticControl_Coupling
        LOGICAL     :: include_lorentz    = .FALSE.    ! Lorentz force coupling
        LOGICAL     :: include_joule_heat = .FALSE.    ! Induction heating
    END TYPE UF_ElectromagneticControl_Coupling
```

### `UF_ElectromagneticControl` (lines 1486–1492)

```fortran
    TYPE, PUBLIC :: UF_ElectromagneticControl
        TYPE(UF_ElectromagneticControl_Type)    :: em_type
        TYPE(UF_ElectromagneticControl_Time)    :: time
        TYPE(UF_ElectromagneticControl_Steps)   :: steps
        TYPE(UF_ElectromagneticControl_Solver)  :: solver
        TYPE(UF_ElectromagneticControl_Coupling):: coupling
    END TYPE UF_ElectromagneticControl
```

### `UF_AcousticControl_Mode` (lines 1501–1503)

```fortran
    TYPE, PUBLIC :: UF_AcousticControl_Mode
        INTEGER(i4) :: analysis_mode     = ACOU_TRANSIENT
    END TYPE UF_AcousticControl_Mode
```

### `UF_AcousticControl_Fluid` (lines 1505–1508)

```fortran
    TYPE, PUBLIC :: UF_AcousticControl_Fluid
        REAL(wp)    :: fluid_density      = 1.2_wp    ! kg/m  (air default)
        REAL(wp)    :: sound_speed        = 343.0_wp  ! m/s
    END TYPE UF_AcousticControl_Fluid
```

### `UF_AcousticControl_Freq` (lines 1510–1514)

```fortran
    TYPE, PUBLIC :: UF_AcousticControl_Freq
        REAL(wp)    :: freq_start         = 10.0_wp   ! Hz (steady-state sweep)
        REAL(wp)    :: freq_end           = 8000.0_wp
        INTEGER(i4) :: n_freq_points      = 200_i4
    END TYPE UF_AcousticControl_Freq
```

### `UF_AcousticControl_Coupling` (lines 1516–1520)

```fortran
    TYPE, PUBLIC :: UF_AcousticControl_Coupling
        LOGICAL     :: coupled_structural = .TRUE.    ! FSI coupling
        REAL(wp)    :: coupling_tol       = 1.0E-4_wp
        INTEGER(i4) :: max_iterations     = 10_i4
    END TYPE UF_AcousticControl_Coupling
```

### `UF_AcousticControl_BC` (lines 1522–1524)

```fortran
    TYPE, PUBLIC :: UF_AcousticControl_BC
        LOGICAL     :: absorbing_boundary = .FALSE.   ! Impedance/NRB BC
    END TYPE UF_AcousticControl_BC
```

### `UF_AcousticControl` (lines 1526–1532)

```fortran
    TYPE, PUBLIC :: UF_AcousticControl
        TYPE(UF_AcousticControl_Mode)     :: mode
        TYPE(UF_AcousticControl_Fluid)    :: fluid
        TYPE(UF_AcousticControl_Freq)     :: freq
        TYPE(UF_AcousticControl_Coupling) :: coupling
        TYPE(UF_AcousticControl_BC)       :: bc
    END TYPE UF_AcousticControl
```

### `UF_SSTransportControl_Motion` (lines 1539–1542)

```fortran
    TYPE, PUBLIC :: UF_SSTransportControl_Motion
        REAL(wp)    :: rolling_speed       = 1.0_wp   ! m/s or rad/s
        REAL(wp)    :: transport_velocity  = 0.0_wp   ! Translational velocity
    END TYPE UF_SSTransportControl_Motion
```

### `UF_SSTransportControl_Steps` (lines 1544–1548)

```fortran
    TYPE, PUBLIC :: UF_SSTransportControl_Steps
        INTEGER(i4) :: n_load_steps        = 10_i4
        INTEGER(i4) :: max_iterations      = 20_i4
        INTEGER(i4) :: max_increments      = 200_i4
    END TYPE UF_SSTransportControl_Steps
```

### `UF_SSTransportControl_Tol` (lines 1550–1553)

```fortran
    TYPE, PUBLIC :: UF_SSTransportControl_Tol
        REAL(wp)    :: residual_tol        = 1.0E-4_wp
        REAL(wp)    :: correction_tol      = 1.0E-3_wp
    END TYPE UF_SSTransportControl_Tol
```

### `UF_SSTransportControl_Flags` (lines 1555–1558)

```fortran
    TYPE, PUBLIC :: UF_SSTransportControl_Flags
        LOGICAL     :: include_friction     = .TRUE.
        INTEGER(i4) :: nlgeom             = NLGEOM_OFF
    END TYPE UF_SSTransportControl_Flags
```

### `UF_SteadyStateTransportControl` (lines 1560–1565)

```fortran
    TYPE, PUBLIC :: UF_SteadyStateTransportControl
        TYPE(UF_SSTransportControl_Motion) :: motion
        TYPE(UF_SSTransportControl_Steps)  :: steps
        TYPE(UF_SSTransportControl_Tol)    :: tol
        TYPE(UF_SSTransportControl_Flags)  :: flags
    END TYPE UF_SteadyStateTransportControl
```

### `UF_SubstructureControl_Method` (lines 1574–1578)

```fortran
    TYPE, PUBLIC :: UF_SubstructureControl_Method
        INTEGER(i4) :: reduction_method    = SUBSTRUCT_GUYAN
        INTEGER(i4) :: n_retained_modes    = 0_i4    ! Craig-Bampton internal modes
        INTEGER(i4), ALLOCATABLE :: retained_dof_ids(:)  ! Boundary DOF list
    END TYPE UF_SubstructureControl_Method
```

### `UF_SubstructureControl_Flags` (lines 1580–1584)

```fortran
    TYPE, PUBLIC :: UF_SubstructureControl_Flags
        LOGICAL     :: generate_recovery   = .TRUE.  ! Generate stress recovery data
        LOGICAL     :: include_mass        = .TRUE.
        LOGICAL     :: include_damping     = .FALSE.
    END TYPE UF_SubstructureControl_Flags
```

### `UF_SubstructureControl_Name` (lines 1586–1588)

```fortran
    TYPE, PUBLIC :: UF_SubstructureControl_Name
        CHARACTER(LEN=64) :: substructure_name = ""
    END TYPE UF_SubstructureControl_Name
```

### `UF_SubstructureControl` (lines 1590–1594)

```fortran
    TYPE, PUBLIC :: UF_SubstructureControl
        TYPE(UF_SubstructureControl_Method) :: method
        TYPE(UF_SubstructureControl_Flags)  :: flags
        TYPE(UF_SubstructureControl_Name)   :: name
    END TYPE UF_SubstructureControl
```

### `UF_DynamicParams` (lines 1601–1613)

```fortran
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
```

### `StepStateData` (lines 1620–1636)

```fortran
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
```

### `StepDesc` (lines 1643–1653)

```fortran
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
```

### `StepCtx` (lines 1660–1663)

```fortran
    TYPE, PUBLIC :: StepCtx
        TYPE(StepDesc) :: step_desc
        TYPE(StepStateData) :: step_state
    END TYPE StepCtx
```

### `MD_TimeIncrementControl` (lines 1670–1678)

```fortran
    TYPE, PUBLIC :: MD_TimeIncrementControl
        REAL(wp) :: initial_increment = 0.1_wp
        REAL(wp) :: min_increment = 1.0E-10_wp
        REAL(wp) :: max_increment = 1.0_wp
        REAL(wp) :: current_increment = 0.1_wp
        REAL(wp) :: time_period = 1.0_wp
        LOGICAL :: automatic = .TRUE.
        INTEGER(i4) :: max_increments = 1000_i4
    END TYPE MD_TimeIncrementControl
```

### `MD_TimeIncrementResult` (lines 1685–1688)

```fortran
    TYPE, PUBLIC :: MD_TimeIncrementResult
        REAL(wp) :: suggested_dt = 0.0_wp
        LOGICAL :: success = .TRUE.
    END TYPE MD_TimeIncrementResult
```

### `MD_ConvergenceCriteria` (lines 1698–1711)

```fortran
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
```

### `MD_ConvergenceResult` (lines 1718–1721)

```fortran
    TYPE, PUBLIC :: MD_ConvergenceResult
        LOGICAL :: converged = .FALSE.
        INTEGER(i4) :: iterations = 0_i4
    END TYPE MD_ConvergenceResult
```

### `MD_NonlinSolv` (lines 1728–1734)

```fortran
    TYPE, PUBLIC :: MD_NonlinSolv
        INTEGER(i4) :: method = 1_i4              ! 1=NR, 2=ModifiedNR, 3=QuasiNR, 4=ArcLen
        INTEGER(i4) :: max_iterations = 50_i4
        REAL(wp) :: tolerance_force = 1.0e-6_wp
        REAL(wp) :: tolerance_displacement = 1.0e-5_wp
        REAL(wp) :: tolerance_energy = 1.0e-4_wp
    END TYPE MD_NonlinSolv
```

### `MD_SolverState` (lines 1741–1755)

```fortran
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
```

### `MD_RestartData` (lines 1762–1768)

```fortran
    TYPE, PUBLIC :: MD_RestartData
        LOGICAL :: valid = .FALSE.
        REAL(wp) :: time = 0.0_wp
        INTEGER(i4) :: increment = 0_i4
        REAL(wp), ALLOCATABLE :: u(:)
        LOGICAL :: converged = .FALSE.
    END TYPE MD_RestartData
```

### `MD_OutCfg` (lines 1775–1778)

```fortran
    TYPE, PUBLIC :: MD_OutCfg
        INTEGER(i4) :: field_freq = 1_i4
        INTEGER(i4) :: hist_freq = 1_i4
    END TYPE MD_OutCfg
```

### `MD_OutReq` (lines 1785–1787)

```fortran
    TYPE, PUBLIC :: MD_OutReq
        INTEGER(i4) :: n_requests = 0_i4
    END TYPE MD_OutReq
```

### `IncState` (lines 1794–1797)

```fortran
    TYPE, PUBLIC :: IncState
        INTEGER(i4) :: inc_index = 0_i4
        REAL(wp) :: dt = 0.0_wp
    END TYPE IncState
```

### `IncCtx` (lines 1804–1807)

```fortran
    TYPE, PUBLIC :: IncCtx
        INTEGER(i4) :: step_idx = 0_i4
        INTEGER(i4) :: inc_idx = 0_i4
    END TYPE IncCtx
```

### `MD_Model_StepConfig` (lines 1814–1816)

```fortran
    TYPE, PUBLIC :: MD_Model_StepConfig
        INTEGER(i4) :: n_steps = 0_i4
    END TYPE MD_Model_StepConfig
```

### `UF_StepDef` (lines 1823–1887)

```fortran
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
```

### `UF_StepManager` (lines 1900–1913)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `step_init` | 1921 | `SUBROUTINE step_init(this, name, number)` |
| SUBROUTINE | `step_set_procedure` | 1932 | `SUBROUTINE step_set_procedure(this, proc_type, perturbation)` |
| SUBROUTINE | `step_set_time` | 1941 | `SUBROUTINE step_set_time(this, period, start)` |
| SUBROUTINE | `step_set_nlgeom` | 1950 | `SUBROUTINE step_set_nlgeom(this, nlg)` |
| SUBROUTINE | `step_set_increment` | 1956 | `SUBROUTINE step_set_increment(this, initial, minimum, maximum, max_num)` |
| FUNCTION | `step_get_time_fraction` | 1966 | `FUNCTION step_get_time_fraction(this) RESULT(frac)` |
| SUBROUTINE | `step_advance_increment` | 1976 | `SUBROUTINE step_advance_increment(this, dt, converged)` |
| SUBROUTINE | `step_print_info` | 1989 | `SUBROUTINE step_print_info(this, unit_num)` |
| SUBROUTINE | `step_destroy` | 1998 | `SUBROUTINE step_destroy(this)` |
| SUBROUTINE | `UF_Step_AttachLoadDefs` | 2010 | `SUBROUTINE UF_Step_AttachLoadDefs(step, load_array)` |
| SUBROUTINE | `UF_Step_ClearLoadDefs` | 2017 | `SUBROUTINE UF_Step_ClearLoadDefs(step)` |
| SUBROUTINE | `step_add_pair_id` | 2024 | `SUBROUTINE step_add_pair_id(this, pair_id)` |
| SUBROUTINE | `stepmgr_init` | 2037 | `SUBROUTINE stepmgr_init(this, max_steps)` |
| SUBROUTINE | `stepmgr_add_step` | 2049 | `SUBROUTINE stepmgr_add_step(this, step)` |
| FUNCTION | `stepmgr_get_step` | 2059 | `FUNCTION stepmgr_get_step(this, num) RESULT(ptr)` |
| FUNCTION | `stepmgr_get_current` | 2069 | `FUNCTION stepmgr_get_current(this) RESULT(ptr)` |
| FUNCTION | `stepmgr_advance_step` | 2078 | `FUNCTION stepmgr_advance_step(this) RESULT(has_next)` |
| SUBROUTINE | `stepmgr_print_summary` | 2088 | `SUBROUTINE stepmgr_print_summary(this, unit_num)` |
| SUBROUTINE | `stepmgr_destroy` | 2100 | `SUBROUTINE stepmgr_destroy(this)` |
| SUBROUTINE | `MD_Conv_Check` | 2114 | `SUBROUTINE MD_Conv_Check(criteria, state, result, status)` |
| SUBROUTINE | `ProcToRTStepType` | 2178 | `SUBROUTINE ProcToRTStepType(proc, rt_type, ierr)` |
| SUBROUTINE | `ProcToSolverType` | 2232 | `SUBROUTINE ProcToSolverType(proc, solver_type, ierr)` |
| SUBROUTINE | `MD_TimeIncrement_Calc` | 2285 | `SUBROUTINE MD_TimeIncrement_Calc(time_ctrl, state, conv_result, time_result, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
