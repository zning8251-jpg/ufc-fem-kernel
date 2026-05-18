# `MD_Out_UniFld.f90`

- **Source**: `L3_MD/Output/MD_Out_UniFld.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Out_UniFld`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_UniFld`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out_UniFld`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_UniFld.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_FieldCpl` (lines 203–212)

```fortran
  type, public :: MD_FieldCpl
    integer(i4) :: field1_type = MD_FIELD_UNKNOWN    ! First field type  ? ?
    integer(i4) :: field2_type = MD_FIELD_UNKNOWN      ! Second field type  ? ?
    integer(i4) :: coupling_type = MD_CPL_NONE         ! Coupling type  ? ?
    logical     :: active = .false.                     ! Active flag
    real(wp)    :: coupling_coeff = 1.0_wp             ! Coupling coefficient α_cpl  ? ?
  contains
    procedure, public :: Init
    procedure, public :: IsActive
  end type MD_FieldCpl
```

### `MD_Field_Mgr` (lines 218–247)

```fortran
  type, public :: MD_Field_Mgr
    integer(i4)       :: fieldId    = 0_i4              ! Field ID  ? ?
    integer(i4)       :: fieldType   = MD_FIELD_UNKNOWN ! Field type  ? ?
    character(len=64)  :: fieldName   = ""               ! Field name
    integer(i4)       :: nDOFs       = 0_i4             ! Number of DOFs n_dof  ? ?
    integer(i4)       :: order       = 1_i4             ! Field order  ? ?

    real(wp), allocatable :: values(:)                  ! Current values φ(t)  ?ℝ^n_dof
    real(wp), allocatable :: velocities(:)             ! Velocities dφ/dt  ?ℝ^n_dof
    real(wp), allocatable :: accelerations(:)           ! Accelerations d²φ/dt²  ?ℝ^n_dof
    real(wp), allocatable :: values_old(:)             ! Previous values φ(t-Δt)  ?ℝ^n_dof
    real(wp), allocatable :: velocities_old(:)         ! Previous velocities  ?ℝ^n_dof

    logical :: hasHistory = .false.                     ! History flag
    integer(i4) :: nHistory = 0_i4                     ! Number of history steps n_hist  ? ?
    real(wp), allocatable :: history(:,:)              ! History array  ?ℝ^(n_dof×n_hist)

    logical :: isConstrained = .false.                  ! Constrained flag
    logical, allocatable :: isFixed(:)                  ! Fixed DOF flags
    real(wp), allocatable :: prescribedvalue(:)        ! Prescribed values  ?ℝ^n_dof
  contains
    procedure, public :: Init
    procedure, public :: AllocateDOFs
    procedure, public :: SetValues
    procedure, public :: GetValues
    procedure, public :: UpdateHistory
    procedure, public :: GetHistory
    procedure, public :: ApplyConstraints
    procedure, public :: GetConstrainedDOFs
  end type MD_Field_Mgr
```

### `MD_FieldDesc` (lines 253–273)

```fortran
  type, public :: MD_FieldDesc
    integer(i4)       :: fieldId    = 0_i4              ! Field ID  ? ?
    integer(i4)       :: fieldType   = MD_FIELD_UNKNOWN ! Field type  ? ?
    character(len=64)  :: fieldName   = ""               ! Field name
    character(len=256) :: description = ""              ! Description
    integer(i4)       :: nDOFs       = 0_i4             ! Number of DOFs n_dof  ? ?
    integer(i4)       :: order       = 1_i4             ! Field order  ? ?
    integer(i4)       :: startDOF    = 0_i4             ! Start DOF index  ? ?
    integer(i4)       :: endDOF      = 0_i4             ! End DOF index  ? ?
    logical           :: isActive     = .true.          ! Active flag
    logical           :: isTransient  = .true.          ! Transient flag
    logical           :: isNonlinear  = .false.          ! Nonlinear flag

    real(wp) :: min_value = -huge(1.0_wp)              ! Minimum value φ_min  ? ?
    real(wp) :: max_value = huge(1.0_wp)                ! Maximum value φ_max  ? ?
    real(wp) :: default_value = 0.0_wp                  ! Default value φ_default  ? ?
  contains
    procedure, public :: Init
    procedure, public :: SetDOFRange
    procedure, public :: GetDOFRange
  end type MD_FieldDesc
```

### `MD_FieldInitDesc` (lines 280–284)

```fortran
  type, public :: MD_FieldInitDesc
    integer(i4) :: field_id = 0_i4                      ! Field ID  ? ?
    integer(i4) :: n_nodes = 0_i4                       ! Number of nodes n_nodes  ? ?
    integer(i4) :: n_dimensions = 0_i4                  ! Number of dimensions n_dim  ? ?
  end type MD_FieldInitDesc
```

### `MD_ThermalFieldInitDesc` (lines 289–292)

```fortran
  type, public :: MD_ThermalFieldInitDesc
    integer(i4) :: field_id = 0_i4                      ! Field ID  ? ?
    integer(i4) :: n_nodes = 0_i4                       ! Number of nodes n_nodes  ? ?
  end type MD_ThermalFieldInitDesc
```

### `MD_ChemicalFieldInitDesc` (lines 297–301)

```fortran
  type, public :: MD_ChemicalFieldInitDesc
    integer(i4) :: field_id = 0_i4                      ! Field ID  ? ?
    integer(i4) :: n_nodes = 0_i4                       ! Number of nodes n_nodes  ? ?
    integer(i4) :: n_species = 0_i4                     ! Number of species n_species  ? ?
  end type MD_ChemicalFieldInitDesc
```

### `MD_BiologicalFieldInitDesc` (lines 306–310)

```fortran
  type, public :: MD_BiologicalFieldInitDesc
    integer(i4) :: field_id = 0_i4                      ! Field ID  ? ?
    integer(i4) :: n_nodes = 0_i4                       ! Number of nodes n_nodes  ? ?
    integer(i4) :: n_cell_types = 0_i4                  ! Number of cell types n_cell_types  ? ?
  end type MD_BiologicalFieldInitDesc
```

### `MD_FieldManager` (lines 316–342)

```fortran
  type, public :: MD_FieldManager
    logical :: isInitialized = .false.                  ! Initialization flag

    integer(i4) :: nFields = 0_i4                       ! Number of fields n_fields  ? ?
    integer(i4) :: nDOFsTotal = 0_i4                    ! Total DOFs n_dofs_total  ? ?

    type(MD_FieldDesc), allocatable :: fields(:)       ! Field descriptions array
    type(MD_Field_Mgr), allocatable :: fieldStates(:)  ! Field states array
    type(MD_FieldCpl), allocatable :: couplings(:)      ! Field couplings array

    integer(i4), allocatable :: fieldDOFMap(:)          ! Field DOF mapping  ?ℤ^n_dofs_total
    integer(i4), allocatable :: globalDOFMap(:)         ! Global DOF mapping  ?ℤ^n_dofs_total
  contains
    procedure, public :: Init
    procedure, public :: RegisterField
    procedure, public :: GetFieldDesc
    procedure, public :: GetFieldState
    procedure, public :: GetFieldStateById
    procedure, public :: UpdateFieldState
    procedure, public :: AddCoupling
    procedure, public :: GetCoupling
    procedure, public :: GetTotalDOFs
    procedure, public :: GetFieldDOFMap
    procedure, public :: GetGlobalDOFMap
    procedure, public :: BuildDOFMap
    procedure, public :: Cleanup
  end type MD_FieldManager
```

### `StructMatRes` (lines 1707–1709)

```fortran
  type, public :: StructMatRes
    type(ContmMatRes) :: core
  end type StructMatRes
```

### `MD_FldEq` (lines 1811–1871)

```fortran
  type, public :: MD_FldEq
    !! Unified field equation: CĂÂˇĂâ Ăâ?+ KĂÂˇĂâ?+ f_int(Ăâ? = f_ext(t)
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: field_type = MD_FIELD_UNKNOWN
    integer(i4) :: system_type = MD_SYS_FIRST_ORDER
    integer(i4) :: n_dofs = 0_i4
    
    ! Capacity matrix C (mass M, thermal capacity C_T, storage S, etc.)
    real(wp), allocatable :: C(:,:)
    
    ! Conduction/stiffness matrix K
    real(wp), allocatable :: K(:,:)
    
    ! Damping matrix (for second-order systems)
    real(wp), allocatable :: D(:,:)
    
    ! Mass matrix (for second-order systems)
    real(wp), allocatable :: M(:,:)
    
    ! Internal force/flux f_int(Ăâ? - nonlinear function
    real(wp), allocatable :: f_int(:)
    
    ! External force/source f_ext(t)
    real(wp), allocatable :: f_ext(:)
    
    ! Field variable Ăâ?
    real(wp), allocatable :: phi(:)
    
    ! Time derivative Ăâ Ăâ?
    real(wp), allocatable :: phi_dot(:)
    
    ! Second time derivative Ăâ ĂË?(for second-order systems)
    real(wp), allocatable :: phi_ddot(:)
    
    ! Residual R = f_ext - f_int - CĂÂˇĂâ Ăâ?- KĂÂˇĂâ?
    real(wp), allocatable :: residual(:)
    
    ! Tangent operator K_t = Ă˘ËâR/Ă˘ËâĂ?
    real(wp), allocatable :: K_tangent(:,:)
    
    ! Time step
    real(wp) :: dt = 0.0_wp
    
    ! Current time
    real(wp) :: time = 0.0_wp
    
    ! Nonlinear flag
    logical :: is_nonlinear = .false.
    
    ! Transient flag
    logical :: is_transient = .true.
    
  contains
    procedure, public :: Init => MD_FldEq_Init
    procedure, public :: ComputeResidual => MD_FldEq_ComputeResidual
    procedure, public :: ComputeTangent => MD_FldEq_ComputeTangent
    procedure, public :: UpdateState => MD_FldEq_UpdateState
    procedure, public :: GetResidualNorm => MD_FldEq_GetResidualNorm
    procedure, public :: Clean => MD_FldEq_Clean
  end type MD_FldEq
```

### `MD_FldSysType` (lines 1876–1891)

```fortran
  type, public :: MD_FldSysType
    !! Field system type descriptor
    
    integer(i4) :: system_type = MD_SYS_FIRST_ORDER
    integer(i4) :: n_fields = 0_i4
    integer(i4), allocatable :: field_types(:)
    integer(i4), allocatable :: field_orders(:)  ! Order of each field (1 or 2)
    logical :: is_coupled = .false.
    integer(i4), allocatable :: coupling_matrix(:,:)  ! Coupling relationship matrix
    
  contains
    procedure, public :: Init => MD_FldSysType_Init
    procedure, public :: AddField => MD_FldSysType_AddField
    procedure, public :: SetCoupling => MD_FldSysType_SetCoupling
    procedure, public :: Clean => MD_FldSysType_Clean
  end type MD_FldSysType
```

### `MD_FldCplDesc` (lines 1896–1920)

```fortran
  type, public :: MD_FldCplDesc
    !! Describes coupling between two fields
    
    integer(i4) :: field1_id = 0_i4
    integer(i4) :: field2_id = 0_i4
    integer(i4) :: field1_type = MD_FIELD_UNKNOWN
    integer(i4) :: field2_type = MD_FIELD_UNKNOWN
    
    ! Coupling matrix K_{ij} (field i affects field j)
    real(wp), allocatable :: coupling_matrix(:,:)
    
    ! Coupling strength
    real(wp) :: cpl_strength = 1.0_wp
    
    ! Coupling type
    integer(i4) :: coupling_type = 0_i4  ! 0=none, 1=one-way, 2=two-way, 3=full
    
    ! Active flag
    logical :: is_active = .false.
    
  contains
    procedure, public :: Init => MD_FldCplDesc_Init
    procedure, public :: ComputeCouplingTerm => MD_FldCplDesc_ComputeCouplingTerm
    procedure, public :: Clean => MD_FldCplDesc_Clean
  end type MD_FldCplDesc
```

### `MD_UniFldSys` (lines 1925–1975)

```fortran
  type, public :: MD_UniFldSys
    !! Unified field system containing multiple coupled fields
    
    logical :: is_initialized = .false.
    
    ! System configuration
    type(MD_FldSysType) :: system_config
    
    ! Field equations
    type(MD_FldEq), allocatable :: field_equations(:)
    
    ! Field manager (from MD_UniFld)
    type(MD_FieldManager) :: field_manager
    
    ! Coupling descriptors
    type(MD_FldCplDesc), allocatable :: couplings(:)
    
    ! Global system matrices (for monolithic coupling)
    real(wp), allocatable :: K_global(:,:)
    real(wp), allocatable :: C_global(:,:)
    real(wp), allocatable :: M_global(:,:)
    real(wp), allocatable :: R_global(:)
    real(wp), allocatable :: phi_global(:)
    
    ! Total DOFs
    integer(i4) :: n_dofs_total = 0_i4
    
    ! Time integration parameters
    real(wp) :: dt = 0.0_wp
    real(wp) :: time = 0.0_wp
    real(wp) :: theta = 0.5_wp  ! Time integration parameter (0=explicit, 1=implicit, 0.5=Crank-Nicolson)
    
    ! Solver parameters
    integer(i4) :: max_iterations = 50_i4
    real(wp) :: tolerance = 1.0e-6_wp
    logical :: converged = .false.
    integer(i4) :: iterations = 0_i4
    
  contains
    procedure, public :: Init => MD_UniFldSys_Init
    procedure, public :: AddField => MD_UniFldSys_AddField
    procedure, public :: AddCoupling => MD_UniFldSys_AddCoupling
    procedure, public :: AssembleGlobal => MD_UniFldSys_AssembleGlobal
    procedure, public :: ComputeResidual => MD_UniFldSys_ComputeResidual
    procedure, public :: ComputeTangent => MD_UniFldSys_ComputeTangent
    procedure, public :: Solve => MD_UniFldSys_Solv
    procedure, public :: UpdateTimeStep => MD_UniFldSys_UpdateTimeStep
    procedure, public :: GetFieldEquation => MD_UniFldSys_GetFieldEquation
    procedure, public :: GetTotalDOFs => MD_UniFldSys_GetTotalDOFs
    procedure, public :: Clean => MD_UniFldSys_Clean
  end type MD_UniFldSys
```

### `MD_UniFldMgr` (lines 1980–1994)

```fortran
  type, public :: MD_UniFldMgr
    !! Enhanced unified field manager
    
    type(MD_FieldManager) :: base_manager
    type(MD_UniFldSys) :: unified_system
    
    logical :: is_initialized = .false.
    
  contains
    procedure, public :: Init => MD_UniFldMgr_Init
    procedure, public :: RegisterField => MD_UniFldMgr_RegisterField
    procedure, public :: RegisterCoupling => MD_UniFldMgr_RegCoupling
    procedure, public :: GetFieldSystem => MD_UniFldMgr_GetFieldSystem
    procedure, public :: Clean => MD_UniFldMgr_Clean
  end type MD_UniFldMgr
```

### `MD_FldStaSnap` (lines 2869–2894)

```fortran
  type, public :: MD_FldStaSnap
    !! Snapshot of field state at a specific time
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: field_type = MD_FIELD_UNKNOWN
    real(wp) :: time = 0.0_wp
    integer(i4) :: n_dofs = 0_i4
    integer(i4) :: order = 1_i4
    
    ! Field values
    real(wp), allocatable :: phi(:)
    real(wp), allocatable :: phi_dot(:)
    real(wp), allocatable :: phi_ddot(:)
    
    ! Metadata
    integer(i8) :: timestamp = 0_i8
    character(len=256) :: description = ""
    
  contains
    procedure, public :: Init => MD_FldStaSnap_Init
    procedure, public :: CopyFrom => MD_FldStaSnap_CopyFrom
    procedure, public :: CopyTo => MD_FldStaSnap_CopyTo
    procedure, public :: Ser => MD_FldStaSnap_Ser
    procedure, public :: Deserial => MD_FldStaSnap_Deserial
    procedure, public :: Clean => MD_FldStaSnap_Clean
  end type MD_FldStaSnap
```

### `MD_FldStaHist` (lines 2899–2921)

```fortran
  type, public :: MD_FldStaHist
    !! History of field states over time
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: field_type = MD_FIELD_UNKNOWN
    integer(i4) :: max_history = 100_i4
    integer(i4) :: current_size = 0_i4
    
    ! History snapshots
    type(MD_FldStaSnap), allocatable :: snapshots(:)
    
    ! Time array
    real(wp), allocatable :: time_array(:)
    
  contains
    procedure, public :: Init => MD_FldStaHist_Init
    procedure, public :: AddSnap => MD_FldStaHist_AddSnap
    procedure, public :: GetSnap => MD_FldStaHist_GetSnap
    procedure, public :: GetSnapAtTime => MD_FldStaHist_GetSnapAtTime
    procedure, public :: GetLatestSnap => MD_FldStaHist_GetLatestSnap
    procedure, public :: Clear => MD_FldStaHist_Clear
    procedure, public :: Clean => MD_FldStaHist_Clean
  end type MD_FldStaHist
```

### `MD_UniFldSta` (lines 2926–2970)

```fortran
  type, public :: MD_UniFldSta
    !! Enhanced unified field state
    
    ! Base state (from MD_Field_Mgr)
    type(MD_Field_Mgr) :: base_state
    
    ! Current state
    real(wp), allocatable :: phi(:)           ! Field values
    real(wp), allocatable :: phi_dot(:)       ! Field velocities
    real(wp), allocatable :: phi_ddot(:)      ! Field accelerations
    
    ! Previous state
    real(wp), allocatable :: phi_old(:)
    real(wp), allocatable :: phi_dot_old(:)
    real(wp), allocatable :: phi_ddot_old(:)
    
    ! State history
    type(MD_FldStaHist) :: history
    
    ! Checkpoint state
    type(MD_FldStaSnap) :: checkpoint
    
    ! State metadata
    real(wp) :: time = 0.0_wp
    real(wp) :: dt = 0.0_wp
    integer(i4) :: step = 0_i4
    integer(i4) :: iteration = 0_i4
    
    ! State flags
    logical :: has_checkpoint = .false.
    logical :: is_dirty = .false.
    
  contains
    procedure, public :: Init => MD_UniFldSta_Init
    procedure, public :: UpdateSta => MD_UniFldSta_UpdateSta
    procedure, public :: SaveChkpt => MD_UniFldSta_SaveChkpt
    procedure, public :: RestoreChkpt => MD_UniFldSta_RestoreChkpt
    procedure, public :: AddToHist => MD_UniFldSta_AddToHist
    procedure, public :: GetStaAtTime => MD_UniFldSta_GetStaAtTime
    procedure, public :: CopyFromFldEq => MD_UniFldSta_CopyFromFldEq
    procedure, public :: CopyToFldEq => MD_UniFldSta_CopyToFldEq
    procedure, public :: Ser => MD_UniFldSta_Ser
    procedure, public :: Deserial => MD_UniFldSta_Deserial
    procedure, public :: Clean => MD_UniFldSta_Clean
  end type MD_UniFldSta
```

### `MD_FldStaMgr` (lines 2975–2999)

```fortran
  type, public :: MD_FldStaMgr
    !! Manager for multiple field states
    
    logical :: is_initialized = .false.
    
    integer(i4) :: n_fields = 0_i4
    type(MD_UniFldSta), allocatable :: field_states(:)
    
    ! Global state metadata
    real(wp) :: global_time = 0.0_wp
    real(wp) :: global_dt = 0.0_wp
    integer(i4) :: global_step = 0_i4
    
    ! Checkpoint directory
    character(len=512) :: checkpoint_dir = "./checkpoints"
    
  contains
    procedure, public :: Init => MD_FldStaMgr_Init
    procedure, public :: RegField => MD_FldStaMgr_RegField
    procedure, public :: UpdateAllSta => MD_FldStaMgr_UpdateAllSta
    procedure, public :: SaveAllChkpt => MD_FldStaMgr_SaveAllChkpt
    procedure, public :: RestoreAllChkpt => MD_FldStaMgr_RestoreAllChkpt
    procedure, public :: GetFldSta => MD_FldStaMgr_GetFldSta
    procedure, public :: Clean => MD_FldStaMgr_Clean
  end type MD_FldStaMgr
```

### `MD_StructFld` (lines 3844–3871)

```fortran
  type, public :: MD_StructFld
    !! Structural field: displacement and rotation
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Displacement field (u, v, w)
    integer(i4) :: n_disp_dofs = 0_i4
    real(wp), allocatable :: displacement(:,:)  ! (n_dimensions, n_nodes)
    real(wp), allocatable :: velocity(:,:)     ! (n_dimensions, n_nodes)
    real(wp), allocatable :: acceleration(:,:) ! (n_dimensions, n_nodes)
    
    ! Rotation field (ĂÂ¸x, ĂÂ¸y, ĂÂ¸z)
    integer(i4) :: n_rot_dofs = 0_i4
    real(wp), allocatable :: rotation(:,:)     ! (n_dimensions, n_nodes)
    real(wp), allocatable :: angular_velocit(:,:)  ! (n_dimensions, n_nodes)
    real(wp), allocatable :: angular_acceler(:,:) ! (n_dimensions, n_nodes)
    
    ! Field equation
    type(MD_FldEq) :: disp_equation
    type(MD_FldEq) :: rot_equation
    
  contains
    procedure, public :: Init => MD_StructFld_Init
    procedure, public :: ComputeStrain => MD_StructFld_ComputeStrain
    procedure, public :: MatCompStress => MD_StructFld_MatCompStress
    procedure, public :: Clean => MD_StructFld_Clean
  end type MD_StructFld
```

### `MD_ThermalFld` (lines 3876–3904)

```fortran
  type, public :: MD_ThermalFld
    !! Thermal field: temperature and heat flux
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Temperature field (T)
    integer(i4) :: n_temp_dofs = 0_i4
    real(wp), allocatable :: temperature(:)    ! (n_nodes)
    real(wp), allocatable :: temp_rate(:)      ! (n_nodes)
    
    ! Heat flux field (q)
    integer(i4) :: n_flux_dofs = 0_i4
    real(wp), allocatable :: heat_flux(:,:)    ! (n_dimensions, n_nodes)
    
    ! Mat properties
    real(wp), allocatable :: thermal_conduct(:)  ! (n_nodes)
    real(wp), allocatable :: thermal_capacit(:)      ! (n_nodes)
    real(wp), allocatable :: density(:)               ! (n_nodes)
    
    ! Field equation
    type(MD_FldEq) :: temp_equation
    
  contains
    procedure, public :: Init => MD_ThermalFld_Init
    procedure, public :: ComputeHeatFlux => MD_ThermalFld_ComputeHeatFlux
    procedure, public :: ComputeThermalGrad => MD_ThermalFld_ComputeThermalGrad
    procedure, public :: Clean => MD_ThermalFld_Clean
  end type MD_ThermalFld
```

### `MD_FluidFld` (lines 3909–3939)

```fortran
  type, public :: MD_FluidFld
    !! Fluid field: velocity and pressure
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Velocity field (vx, vy, vz)
    integer(i4) :: n_vel_dofs = 0_i4
    real(wp), allocatable :: velocity(:,:)     ! (n_dimensions, n_nodes)
    real(wp), allocatable :: velocity_rate(:,:) ! (n_dimensions, n_nodes)
    
    ! Pressure field (p)
    integer(i4) :: n_press_dofs = 0_i4
    real(wp), allocatable :: pressure(:)       ! (n_nodes)
    real(wp), allocatable :: pressure_rate(:)  ! (n_nodes)
    
    ! Mat properties
    real(wp) :: viscosity = 1.0e-3_wp
    real(wp) :: density = 1000.0_wp
    real(wp) :: bulk_modulus = 2.0e9_wp
    
    ! Field equations
    type(MD_FldEq) :: vel_equation
    type(MD_FldEq) :: press_equation
    
  contains
    procedure, public :: Init => MD_FluidFld_Init
    procedure, public :: ComputeStrainRate => MD_FluidFld_ComputeStrainRate
    procedure, public :: ComputeDivergence => MD_FluidFld_ComputeDivergence
    procedure, public :: Clean => MD_FluidFld_Clean
  end type MD_FluidFld
```

### `MD_ElectroMagFld` (lines 3944–3976)

```fortran
  type, public :: MD_ElectroMagFld
    !! Electromagnetic field: electric and magnetic fields
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Electric field (Ex, Ey, Ez)
    integer(i4) :: n_electric_dofs = 0_i4
    real(wp), allocatable :: electric_field(:,:)    ! (n_dimensions, n_nodes)
    real(wp), allocatable :: electric_potent(:)  ! (n_nodes)
    real(wp), allocatable :: electric_rate(:,:)     ! (n_dimensions, n_nodes)
    
    ! Magnetic field (Bx, By, Bz)
    integer(i4) :: n_magnetic_dofs = 0_i4
    real(wp), allocatable :: magnetic_field(:,:)    ! (n_dimensions, n_nodes)
    real(wp), allocatable :: magnetic_potent(:,:) ! (n_dimensions, n_nodes)
    real(wp), allocatable :: magnetic_rate(:,:)     ! (n_dimensions, n_nodes)
    
    ! Mat properties
    real(wp), allocatable :: permittivity(:)   ! (n_nodes)
    real(wp), allocatable :: permeability(:)  ! (n_nodes)
    real(wp), allocatable :: conductivity(:)  ! (n_nodes)
    
    ! Field equations
    type(MD_FldEq) :: electric_equation
    type(MD_FldEq) :: magnetic_equation
    
  contains
    procedure, public :: Init => MD_ElectroMagFld_Init
    procedure, public :: ComputePoyntingVec => MD_ElectroMagFld_ComputePoyntingVec
    procedure, public :: ComputeMaxwellStress => MD_ElectroMagFld_ComputeMaxwellStress
    procedure, public :: Clean => MD_ElectroMagFld_Clean
  end type MD_ElectroMagFld
```

### `MD_ChemicalFld` (lines 3981–4011)

```fortran
  type, public :: MD_ChemicalFld
    !! Chemical field: concentration and reaction rate
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    integer(i4) :: n_species = 1_i4
    
    ! Concentration field (c1, c2, ..., cn)
    integer(i4) :: n_conc_dofs = 0_i4
    real(wp), allocatable :: concentration(:,:)    ! (n_species, n_nodes)
    real(wp), allocatable :: conc_rate(:,:)         ! (n_species, n_nodes)
    
    ! Reaction rate field (r1, r2, ..., rn)
    integer(i4) :: n_reaction_dofs = 0_i4
    real(wp), allocatable :: reaction_rate(:,:)     ! (n_species, n_nodes)
    
    ! Diffusion coefficients
    real(wp), allocatable :: diffusion_coeff(:,:)   ! (n_species, n_nodes)
    
    ! Reaction kinetics
    real(wp), allocatable :: reaction_coeff(:,:)    ! (n_species, n_nodes)
    
    ! Field equations
    type(MD_FldEq), allocatable :: conc_equations(:)
    
  contains
    procedure, public :: Init => MD_ChemicalFld_Init
    procedure, public :: ComputeDiffusionFlux => MD_ChemicalFld_ComputeDiffusionFlux
    procedure, public :: ComputeReactionRate => MD_ChemicalFld_ComputeReactionRate
    procedure, public :: Clean => MD_ChemicalFld_Clean
  end type MD_ChemicalFld
```

### `MD_BiologicalFld` (lines 4016–4047)

```fortran
  type, public :: MD_BiologicalFld
    !! Biological field: cell density and growth rate
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    integer(i4) :: n_cell_types = 1_i4
    
    ! Cell density field (Ăĝż?, Ăĝż?, ..., Ăĝż˝n)
    integer(i4) :: n_density_dofs = 0_i4
    real(wp), allocatable :: cell_density(:,:)      ! (n_cell_types, n_nodes)
    real(wp), allocatable :: density_rate(:,:)      ! (n_cell_types, n_nodes)
    
    ! Growth rate field (g1, g2, ..., gn)
    integer(i4) :: n_growth_dofs = 0_i4
    real(wp), allocatable :: growth_rate(:,:)       ! (n_cell_types, n_nodes)
    
    ! Migration parameters
    real(wp), allocatable :: migration_coeff(:,:)    ! (n_cell_types, n_nodes)
    
    ! Growth parameters
    real(wp), allocatable :: growth_coeff(:,:)      ! (n_cell_types, n_nodes)
    real(wp), allocatable :: carrying_capaci(:,:) ! (n_cell_types, n_nodes)
    
    ! Field equations
    type(MD_FldEq), allocatable :: density_equation(:)
    
  contains
    procedure, public :: Init => MD_BiologicalFld_Init
    procedure, public :: COMPUTEMIGRATIO => MD_BiologicalFld_ComputeMigrationFlux
    procedure, public :: COMPUTEGROWTHRA => MD_BiologicalFld_ComputeGrowthRate
    procedure, public :: Clean => MD_BiologicalFld_Clean
  end type MD_BiologicalFld
```

### `MD_QuantumFld` (lines 4052–4081)

```fortran
  type, public :: MD_QuantumFld
    !! Quantum field: wave function and probability density
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Wave function (ĂË, complex)
    integer(i4) :: n_wave_dofs = 0_i4
    complex(wp), allocatable :: wave_function(:)    ! (n_nodes)
    complex(wp), allocatable :: wave_function_rate(:) ! (n_nodes)
    
    ! Probability density (|ĂË|ĂÂ˛)
    real(wp), allocatable :: probability_den(:) ! (n_nodes)
    
    ! Phase (arg(ĂË))
    real(wp), allocatable :: phase(:)               ! (n_nodes)
    
    ! Quantum properties
    real(wp) :: planck_constant = 1.054571817e-34_wp
    real(wp) :: mass = 9.1093837015e-31_wp
    
    ! Field equation (SchrĂÂśdinger equation)
    type(MD_FldEq) :: wave_equation
    
  contains
    procedure, public :: Init => MD_QuantumFld_Init
    procedure, public :: ComputeProbDensity => MD_QuantumFld_ComputeProbDensity
    procedure, public :: ComputeExpectVal => MD_QuantumFld_ComputeExpectVal
    procedure, public :: Clean => MD_QuantumFld_Clean
  end type MD_QuantumFld
```

### `MD_GravitationalFld` (lines 4086–4112)

```fortran
  type, public :: MD_GravitationalFld
    !! Gravitational field: spacetime curvature
    
    integer(i4) :: field_id = 0_i4
    integer(i4) :: n_nodes = 0_i4
    
    ! Spacetime curvature (Riemann tensor components)
    integer(i4) :: n_curvature_dof = 0_i4
    real(wp), allocatable :: curvature(:,:,:,:)     ! (4, 4, 4, 4) - Riemann tensor
    real(wp), allocatable :: ricci_tensor(:,:)      ! (4, 4)
    real(wp) :: ricci_scalar = 0.0_wp
    
    ! Metric tensor (g_ĂÂźĂÂ˝)
    real(wp), allocatable :: metric(:,:)             ! (4, 4)
    
    ! Stress-energy tensor (T_ĂÂźĂÂ˝)
    real(wp), allocatable :: stress_energy(:,:)     ! (4, 4)
    
    ! Field equation (Einstein field equations)
    type(MD_FldEq) :: einstein_equation
    
  contains
    procedure, public :: Init => MD_GravitationalFld_Init
    procedure, public :: ComputeRicciTensor => MD_GravitationalFld_ComputeRicciTensor
    procedure, public :: ComputeEinsteinTensor => MD_GravitationalFld_ComputeEinsteinTensor
    procedure, public :: Clean => MD_GravitationalFld_Clean
  end type MD_GravitationalFld
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `DiffIpKernel_Proc` | 130 | `subroutine DiffIpKernel_Proc(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)` |
| SUBROUTINE | `ThermCoeffs_Proc` | 142 | `subroutine ThermCoeffs_Proc(matModel, Ctx, k_cond, rho, c_p, alphaT, flag_th_exp, &` |
| SUBROUTINE | `PoroCoeffs_Proc` | 157 | `subroutine PoroCoeffs_Proc(matModel, Ctx, alpha_b, k_hyd, S_s, rho_f, cp_f, flag_vol, &` |
| FUNCTION | `GetFieldTypeName` | 349 | `function GetFieldTypeName(fieldType) result(name)` |
| FUNCTION | `GetFieldDOFs` | 379 | `function GetFieldDOFs(fieldType, nDim) result(nDOFs)` |
| FUNCTION | `GetFieldOrder` | 410 | `function GetFieldOrder(fieldType) result(order)` |
| SUBROUTINE | `Init` | 449 | `subroutine Init(this, field1_type, field2_type, coupling_type)` |
| FUNCTION | `IsActive` | 466 | `function IsActive(this) result(isActive)` |
| SUBROUTINE | `Init` | 483 | `subroutine Init(this, fieldId, fieldType, fieldName, nDOFs, order)` |
| SUBROUTINE | `AllocateDOFs` | 505 | `subroutine AllocateDOFs(this, nHistory)` |
| SUBROUTINE | `SetValues` | 545 | `subroutine SetValues(this, values, velocities, accelerations)` |
| SUBROUTINE | `GetValues` | 573 | `subroutine GetValues(this, values, velocities, accelerations)` |
| SUBROUTINE | `UpdateHistory` | 601 | `subroutine UpdateHistory(this)` |
| SUBROUTINE | `GetHistory` | 620 | `subroutine GetHistory(this, historyStep, values)` |
| SUBROUTINE | `ApplyConstraints` | 639 | `subroutine ApplyConstraints(this, isFixed, prescribedvalue)` |
| SUBROUTINE | `GetConstrainedDOFs` | 661 | `subroutine GetConstrainedDOFs(this, isFixed, prescribedvalue)` |
| SUBROUTINE | `Init` | 698 | `subroutine Init(this, fieldId, fieldType, fieldName, nDOFs, order)` |
| SUBROUTINE | `SetDOFRange` | 723 | `subroutine SetDOFRange(this, startDOF, endDOF)` |
| SUBROUTINE | `GetDOFRange` | 732 | `subroutine GetDOFRange(this, startDOF, endDOF)` |
| SUBROUTINE | `Init` | 748 | `subroutine Init(this, nFields, status)` |
| SUBROUTINE | `RegisterField` | 778 | `subroutine RegisterField(this, fieldDesc, status)` |
| SUBROUTINE | `GetFieldDesc` | 831 | `subroutine GetFieldDesc(this, fieldId, fieldDesc, status)` |
| SUBROUTINE | `GetFieldState` | 850 | `subroutine GetFieldState(this, fieldDesc, fieldState, status)` |
| SUBROUTINE | `GetFieldStateById` | 869 | `subroutine GetFieldStateById(this, fieldId, fieldState, status)` |
| SUBROUTINE | `UpdateFieldState` | 888 | `subroutine UpdateFieldState(this, fieldId, values, velocities, accelerations, status)` |
| SUBROUTINE | `AddCoupling` | 908 | `subroutine AddCoupling(this, field1_type, field2_type, coupling_type, coupling_coeff, status)` |
| SUBROUTINE | `GetCoupling` | 934 | `subroutine GetCoupling(this, field1_type, field2_type, coupling, status)` |
| FUNCTION | `GetTotalDOFs` | 964 | `function GetTotalDOFs(this) result(nDOFs)` |
| SUBROUTINE | `GetFieldDOFMap` | 971 | `subroutine GetFieldDOFMap(this, fieldDOFMap)` |
| SUBROUTINE | `GetGlobalDOFMap` | 992 | `subroutine GetGlobalDOFMap(this, globalDOFMap)` |
| SUBROUTINE | `BuildDOFMap` | 1005 | `subroutine BuildDOFMap(this, status)` |
| SUBROUTINE | `Cleanup` | 1038 | `subroutine Cleanup(this)` |
| SUBROUTINE | `ContIpKernel` | 1082 | `subroutine ContIpKernel(ip, sf, dN_dx, dVol, radius)` |
| SUBROUTINE | `DiffIpKernel` | 1090 | `subroutine DiffIpKernel(ip, sf, field_ip, field_old_ip, k_eff_ip, C_eff_ip)` |
| SUBROUTINE | `ContGauss` | 1156 | `subroutine ContGauss(et, fm, cx, ipKernel)` |
| SUBROUTINE | `DiffGauss` | 1216 | `subroutine DiffGauss(et, fm, cx, &` |
| SUBROUTINE | `ComputeKinematics` | 1323 | `subroutine ComputeKinematics(Ctx, sf, dN_dx, form, nDim, isAxisym, radius, kin)` |
| FUNCTION | `TensorIndex` | 1444 | `function TensorIndex(i, j) result(idx)` |
| FUNCTION | `if_real` | 1460 | `function if_real(cond, val_true, val_false) result(res)` |
| SUBROUTINE | `UF_Co_MakeCoeffsFromContxt` | 1474 | `subroutine UF_Co_MakeCoeffsFromContxt(matModel, Ctx, k_cond, rho, c_p, &` |
| SUBROUTINE | `UF_ContTh_AllocCapacity` | 1520 | `subroutine UF_ContTh_AllocCapacity(nNode, C)` |
| SUBROUTINE | `UF_Co_MakeCoeffsFromContxt` | 1539 | `subroutine UF_Co_MakeCoeffsFromContxt(matModel, Ctx, alpha_b, k_hyd, S_s, &` |
| SUBROUTINE | `UF_ContPoro_AllocCapacity` | 1589 | `subroutine UF_ContPoro_AllocCapacity(nNode, S)` |
| SUBROUTINE | `UF_ContTHM_EvalMaterial` | 1621 | `subroutine UF_ContTHM_EvalMaterial(matModel, thmState, rho_s, k_cond_s, c_p_s, &` |
| SUBROUTINE | `UF_ContTHM_AllocCtt` | 1672 | `subroutine UF_ContTHM_AllocCtt(nNode, Ctt)` |
| SUBROUTINE | `UF_ContTHM_AllocSpp` | 1688 | `subroutine UF_ContTHM_AllocSpp(nNode, Spp)` |
| FUNCTION | `StructGetSectionDesc` | 1711 | `function StructGetSectionDesc(id) result(desc)` |
| SUBROUTINE | `StructIntegrateIp` | 1718 | `subroutine StructIntegrateIp(matModel, Ctx, kin, desc, &` |
| SUBROUTINE | `ThermCoeffs` | 1743 | `subroutine ThermCoeffs(matModel, Ctx, k_cond, rho, c_p, &` |
| SUBROUTINE | `ThermAllocCtt` | 1758 | `subroutine ThermAllocCtt(nNode, C)` |
| SUBROUTINE | `PoroCoeffs` | 1765 | `subroutine PoroCoeffs(matModel, Ctx, alpha_b, k_hyd, S_s, &` |
| SUBROUTINE | `PoroAllocSpp` | 1780 | `subroutine PoroAllocSpp(nNode, S)` |
| SUBROUTINE | `THMAllocSpp` | 1787 | `subroutine THMAllocSpp(nNode, Spp)` |
| SUBROUTINE | `MD_Phys_THM_EvalMaterial` | 1794 | `subroutine MD_Phys_THM_EvalMaterial(matModel, thmState, rho_s, k_cond_s, c_p_s, &` |
| SUBROUTINE | `MD_FldEq_Init` | 2000 | `subroutine MD_FldEq_Init(this, field_id, field_type, n_dofs, system_type, dt, status)` |
| SUBROUTINE | `MD_FldEq_ComputeResidual` | 2066 | `subroutine MD_FldEq_ComputeResidual(this, status)` |
| SUBROUTINE | `MD_FldEq_ComputeTangent` | 2106 | `subroutine MD_FldEq_ComputeTangent(this, theta, dt, status)` |
| SUBROUTINE | `MD_FldEq_UpdateState` | 2151 | `subroutine MD_FldEq_UpdateState(this, delta_phi, delta_phi_dot, delta_phi_ddot, status)` |
| FUNCTION | `MD_FldEq_GetResidualNorm` | 2188 | `function MD_FldEq_GetResidualNorm(this) result(norm)` |
| SUBROUTINE | `MD_FldEq_Clean` | 2201 | `subroutine MD_FldEq_Clean(this)` |
| SUBROUTINE | `MD_FldSysType_Init` | 2221 | `subroutine MD_FldSysType_Init(this, n_fields, status)` |
| SUBROUTINE | `MD_FldSysType_AddField` | 2247 | `subroutine MD_FldSysType_AddField(this, field_id, field_type, field_order, status)` |
| SUBROUTINE | `MD_FldSysType_SetCoupling` | 2276 | `subroutine MD_FldSysType_SetCoupling(this, field1_id, field2_id, coupling_type, status)` |
| SUBROUTINE | `MD_FldSysType_Clean` | 2298 | `subroutine MD_FldSysType_Clean(this)` |
| SUBROUTINE | `MD_FldCplDesc_Init` | 2310 | `subroutine MD_FldCplDesc_Init(this, field1_id, field2_id, field1_type, field2_type, &` |
| SUBROUTINE | `MD_Fl_ComputeCouplingTerm` | 2340 | `subroutine MD_Fl_ComputeCouplingTerm(this, phi1, phi2, coupling_term, status)` |
| SUBROUTINE | `MD_FldCplDesc_Clean` | 2371 | `subroutine MD_FldCplDesc_Clean(this)` |
| SUBROUTINE | `MD_UniFldSys_Init` | 2381 | `subroutine MD_UniFldSys_Init(this, n_fields, dt, theta, status)` |
| SUBROUTINE | `MD_UniFldSys_AddField` | 2409 | `subroutine MD_UniFldSys_AddField(this, field_id, field_type, n_dofs, system_type, status)` |
| SUBROUTINE | `MD_UniFldSys_AddCoupling` | 2446 | `subroutine MD_UniFldSys_AddCoupling(this, field1_id, field2_id, field1_type, field2_type, &` |
| SUBROUTINE | `MD_UniFldSys_AssembleGlobal` | 2491 | `subroutine MD_UniFldSys_AssembleGlobal(this, status)` |
| SUBROUTINE | `MD_UniFldSys_ComputeResidual` | 2579 | `subroutine MD_UniFldSys_ComputeResidual(this, status)` |
| SUBROUTINE | `MD_UniFldSys_ComputeTangent` | 2599 | `subroutine MD_UniFldSys_ComputeTangent(this, status)` |
| SUBROUTINE | `MD_UniFldSys_Solv` | 2619 | `subroutine MD_UniFldSys_Solv(this, status)` |
| FUNCTION | `i4_to_str` | 2718 | `function i4_to_str(i) result(str)` |
| SUBROUTINE | `MD_UniFldSys_UpdateTimeStep` | 2726 | `subroutine MD_UniFldSys_UpdateTimeStep(this, dt, time, status)` |
| SUBROUTINE | `MD_Un_GetFieldEquation` | 2747 | `subroutine MD_Un_GetFieldEquation(this, field_id, field_eq, status)` |
| FUNCTION | `MD_UniFldSys_GetTotalDOFs` | 2765 | `function MD_UniFldSys_GetTotalDOFs(this) result(n_dofs)` |
| SUBROUTINE | `MD_UniFldSys_Clean` | 2771 | `subroutine MD_UniFldSys_Clean(this)` |
| SUBROUTINE | `MD_UniFldMgr_Init` | 2806 | `subroutine MD_UniFldMgr_Init(this, n_fields, dt, theta, status)` |
| SUBROUTINE | `MD_UniFldMgr_RegisterField` | 2825 | `subroutine MD_UniFldMgr_RegisterField(this, field_id, field_type, n_dofs, system_type, status)` |
| SUBROUTINE | `MD_UniFldMgr_RegCoupling` | 2836 | `subroutine MD_UniFldMgr_RegCoupling(this, field1_id, field2_id, field1_type, field2_type, &` |
| FUNCTION | `MD_UniFldMgr_GetFieldSystem` | 2850 | `function MD_UniFldMgr_GetFieldSystem(this) result(system)` |
| SUBROUTINE | `MD_UniFldMgr_Clean` | 2857 | `subroutine MD_UniFldMgr_Clean(this)` |
| SUBROUTINE | `MD_FldStaSnap_Init` | 3005 | `subroutine MD_FldStaSnap_Init(this, field_id, field_type, n_dofs, order, time, status)` |
| SUBROUTINE | `MD_FldStaSnap_CopyFrom` | 3050 | `subroutine MD_FldStaSnap_CopyFrom(this, source, status)` |
| SUBROUTINE | `MD_FldStaSnap_CopyTo` | 3088 | `subroutine MD_FldStaSnap_CopyTo(this, target, status)` |
| SUBROUTINE | `MD_FldStaSnap_Ser` | 3096 | `subroutine MD_FldStaSnap_Ser(this, buffer, status)` |
| SUBROUTINE | `MD_FldStaSnap_Deserial` | 3140 | `subroutine MD_FldStaSnap_Deserial(this, buffer, status)` |
| SUBROUTINE | `MD_FldStaSnap_Clean` | 3201 | `subroutine MD_FldStaSnap_Clean(this)` |
| SUBROUTINE | `MD_FldStaHist_Init` | 3213 | `subroutine MD_FldStaHist_Init(this, field_id, field_type, max_history, status)` |
| SUBROUTINE | `MD_FldStaHist_AddSnap` | 3236 | `subroutine MD_FldStaHist_AddSnap(this, snapshot, status)` |
| SUBROUTINE | `MD_FldStaHist_GetSnap` | 3264 | `subroutine MD_FldStaHist_GetSnap(this, index, snapshot, status)` |
| SUBROUTINE | `MD_FldStaHist_GetSnapAtTime` | 3281 | `subroutine MD_FldStaHist_GetSnapAtTime(this, time, snapshot, tolerance, status)` |
| SUBROUTINE | `MD_FldStaHist_GetLatestSnap` | 3320 | `subroutine MD_FldStaHist_GetLatestSnap(this, snapshot, status)` |
| SUBROUTINE | `MD_FldStaHist_Clear` | 3336 | `subroutine MD_FldStaHist_Clear(this)` |
| SUBROUTINE | `MD_FldStaHist_Clean` | 3342 | `subroutine MD_FldStaHist_Clean(this)` |
| SUBROUTINE | `MD_UniFldSta_Init` | 3361 | `subroutine MD_UniFldSta_Init(this, field_id, field_type, n_dofs, order, max_history, status)` |
| SUBROUTINE | `MD_UniFldSta_UpdateSta` | 3423 | `subroutine MD_UniFldSta_UpdateSta(this, phi_new, phi_dot_new, phi_ddot_new, time, dt, step, iteration, status)` |
| SUBROUTINE | `MD_UniFldSta_SaveChkpt` | 3475 | `subroutine MD_UniFldSta_SaveChkpt(this, status)` |
| SUBROUTINE | `MD_UniFldSta_RestoreChkpt` | 3499 | `subroutine MD_UniFldSta_RestoreChkpt(this, status)` |
| SUBROUTINE | `MD_UniFldSta_AddToHist` | 3527 | `subroutine MD_UniFldSta_AddToHist(this, status)` |
| SUBROUTINE | `MD_UniFldSta_GetStaAtTime` | 3553 | `subroutine MD_UniFldSta_GetStaAtTime(this, time, phi, phi_dot, phi_ddot, status)` |
| SUBROUTINE | `MD_UniFldSta_CopyFromFldEq` | 3583 | `subroutine MD_UniFldSta_CopyFromFldEq(this, field_eq, status)` |
| SUBROUTINE | `MD_UniFldSta_CopyToFldEq` | 3611 | `subroutine MD_UniFldSta_CopyToFldEq(this, field_eq, status)` |
| SUBROUTINE | `MD_UniFldSta_Ser` | 3639 | `subroutine MD_UniFldSta_Ser(this, buffer, status)` |
| SUBROUTINE | `MD_UniFldSta_Deserial` | 3647 | `subroutine MD_UniFldSta_Deserial(this, buffer, status)` |
| SUBROUTINE | `MD_UniFldSta_Clean` | 3659 | `subroutine MD_UniFldSta_Clean(this)` |
| SUBROUTINE | `MD_FldStaMgr_Init` | 3677 | `subroutine MD_FldStaMgr_Init(this, n_fields, checkpoint_dir, status)` |
| SUBROUTINE | `MD_FldStaMgr_RegField` | 3702 | `subroutine MD_FldStaMgr_RegField(this, field_id, field_type, n_dofs, order, max_history, status)` |
| SUBROUTINE | `MD_FldStaMgr_UpdateAllSta` | 3721 | `subroutine MD_FldStaMgr_UpdateAllSta(this, time, dt, step, iteration, status)` |
| SUBROUTINE | `MD_FldStaMgr_SaveAllChkpt` | 3772 | `subroutine MD_FldStaMgr_SaveAllChkpt(this, status)` |
| SUBROUTINE | `MD_FldStaMgr_RestoreAllChkpt` | 3788 | `subroutine MD_FldStaMgr_RestoreAllChkpt(this, status)` |
| SUBROUTINE | `MD_FldStaMgr_GetFldSta` | 3804 | `subroutine MD_FldStaMgr_GetFldSta(this, field_id, field_state, status)` |
| SUBROUTINE | `MD_FldStaMgr_Clean` | 3822 | `subroutine MD_FldStaMgr_Clean(this)` |
| SUBROUTINE | `MD_StructFld_Init` | 4125 | `subroutine MD_StructFld_Init(this, init_desc, status)` |
| SUBROUTINE | `MD_StructFld_ComputeStrain` | 4163 | `subroutine MD_StructFld_ComputeStrain(this, coordinates, strain, status)` |
| SUBROUTINE | `MD_StructFld_MatCompStress` | 4174 | `subroutine MD_StructFld_MatCompStress(this, strain, sigma, status)` |
| SUBROUTINE | `MD_StructFld_Clean` | 4185 | `subroutine MD_StructFld_Clean(this)` |
| SUBROUTINE | `MD_ThermalFld_Init` | 4210 | `subroutine MD_ThermalFld_Init(this, init_desc, status)` |
| SUBROUTINE | `MD_Th_ComputeHeatFlux` | 4243 | `subroutine MD_Th_ComputeHeatFlux(this, temp_gradient, heat_flux, status)` |
| SUBROUTINE | `MD_Th_ComputeThermalGrad` | 4261 | `subroutine MD_Th_ComputeThermalGrad(this, coordinates, temp_gradient, status)` |
| SUBROUTINE | `MD_ThermalFld_Clean` | 4272 | `subroutine MD_ThermalFld_Clean(this)` |
| SUBROUTINE | `MD_FluidFld_Init` | 4296 | `subroutine MD_FluidFld_Init(this, init_desc, status)` |
| SUBROUTINE | `MD_Fl_ComputeStrainRate` | 4330 | `subroutine MD_Fl_ComputeStrainRate(this, velocity_gradie, strain_rate, status)` |
| SUBROUTINE | `MD_Fl_ComputeDivergence` | 4341 | `subroutine MD_Fl_ComputeDivergence(this, velocity, divergence, status)` |
| SUBROUTINE | `MD_FluidFld_Clean` | 4352 | `subroutine MD_FluidFld_Clean(this)` |
| SUBROUTINE | `MD_ElectroMagFld_Init` | 4375 | `subroutine MD_ElectroMagFld_Init(this, init_desc, status)` |
| SUBROUTINE | `MD_El_ComputePoyntingVec` | 4419 | `subroutine MD_El_ComputePoyntingVec(this, poynting, status)` |
| SUBROUTINE | `MD_El_ComputeMaxwellStress` | 4444 | `subroutine MD_El_ComputeMaxwellStress(this, maxwell_stress, status)` |
| SUBROUTINE | `MD_ElectroMagFld_Clean` | 4454 | `subroutine MD_ElectroMagFld_Clean(this)` |
| SUBROUTINE | `MD_ChemicalFld_Init` | 4482 | `subroutine MD_ChemicalFld_Init(this, init_desc, status)` |
| SUBROUTINE | `MD_Ch_ComputeDiffusionFlux` | 4521 | `subroutine MD_Ch_ComputeDiffusionFlux(this, conc_gradient, flux, status)` |
| SUBROUTINE | `MD_Ch_ComputeReactionRate` | 4541 | `subroutine MD_Ch_ComputeReactionRate(this, concentration, reaction_rate, status)` |
| SUBROUTINE | `MD_ChemicalFld_Clean` | 4552 | `subroutine MD_ChemicalFld_Clean(this)` |
| SUBROUTINE | `MD_BiologicalFld_Init` | 4582 | `subroutine MD_BiologicalFld_Init(this, init_desc, status)` |
| SUBROUTINE | `MD_Bi_ComputeMigrationFlux` | 4623 | `subroutine MD_Bi_ComputeMigrationFlux(this, density_gradien, flux, status)` |
| SUBROUTINE | `MD_Bi_ComputeGrowthRate` | 4643 | `subroutine MD_Bi_ComputeGrowthRate(this, cell_density, growth_rate, status)` |
| SUBROUTINE | `MD_BiologicalFld_Clean` | 4668 | `subroutine MD_BiologicalFld_Clean(this)` |
| SUBROUTINE | `MD_QuantumFld_Init` | 4699 | `subroutine MD_QuantumFld_Init(this, init_desc, status)` |
| SUBROUTINE | `MD_Qu_ComputeProbDensity` | 4727 | `subroutine MD_Qu_ComputeProbDensity(this)` |
| SUBROUTINE | `MD_Qu_ComputeExpectVal` | 4739 | `subroutine MD_Qu_ComputeExpectVal(this, operator, expectation, status)` |
| SUBROUTINE | `MD_QuantumFld_Clean` | 4761 | `subroutine MD_QuantumFld_Clean(this)` |
| SUBROUTINE | `MD_GravitationalFld_Init` | 4783 | `subroutine MD_GravitationalFld_Init(this, init_desc, status)` |
| SUBROUTINE | `MD_Gr_ComputeRicciTensor` | 4818 | `subroutine MD_Gr_ComputeRicciTensor(this, status)` |
| SUBROUTINE | `MD_Gr_ComputeEinsteinTensor` | 4849 | `subroutine MD_Gr_ComputeEinsteinTensor(this, einstein_tensor, status)` |
| SUBROUTINE | `MD_GravitationalFld_Clean` | 4869 | `subroutine MD_GravitationalFld_Clean(this)` |
| SUBROUTINE | `MD_CreateStructFld` | 4891 | `subroutine MD_CreateStructFld(init_desc, structural_fiel, status)` |
| SUBROUTINE | `MD_CreateThermalFld` | 4906 | `subroutine MD_CreateThermalFld(init_desc, thermal_field, status)` |
| SUBROUTINE | `MD_CreateFluidFld` | 4921 | `subroutine MD_CreateFluidFld(init_desc, fluid_field, status)` |
| SUBROUTINE | `MD_CreateElectroMagFld` | 4936 | `subroutine MD_CreateElectroMagFld(init_desc, em_field, status)` |
| SUBROUTINE | `MD_CreateChemicalFld` | 4951 | `subroutine MD_CreateChemicalFld(init_desc, chemical_field, status)` |
| SUBROUTINE | `MD_CreateBiologicalFld` | 4966 | `subroutine MD_CreateBiologicalFld(init_desc, biological_fiel, status)` |
| SUBROUTINE | `MD_CreateQuantumFld` | 4981 | `subroutine MD_CreateQuantumFld(init_desc, quantum_field, status)` |
| SUBROUTINE | `MD_CreateGravitationalFld` | 4996 | `subroutine MD_CreateGravitationalFld(init_desc, gravitational_f, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 1101–1106 | `interface KineEval` |
