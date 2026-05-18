# `MD_Mat_Lib.f90`

- **Source**: `L3_MD/Material/Dispatch/MD_Mat_Lib.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Lib`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Lib`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat`
- **第四段角色（四段式）**: `_Lib`
- **源码子路径（层下目录，不含文件名）**: `Material/Dispatch`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Dispatch/MD_Mat_Lib.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ContmMatRes` (lines 67–73)

```fortran
  type, public :: ContmMatRes
    real(wp) :: stress6(6) = 0.0_wp
    real(wp) :: D6(6,6)    = 0.0_wp
    real(wp) :: energy_inc = 0.0_wp
    real(wp) :: plastic_diss = 0.0_wp
    type(MatFlags) :: flags
  end type ContmMatRes
```

### `UF_HardeningTable` (lines 156–165)

```fortran
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
```

### `DmgState` (lines 229–238)

```fortran
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
```

### `FatigueState` (lines 240–248)

```fortran
  type, public :: FatigueState
    real(wp) :: N_f = 0.0_wp
    real(wp) :: N_accumulated = 0.0_wp
    real(wp) :: D_fatigue = 0.0_wp
    real(wp) :: sigma_max = 0.0_wp
    real(wp) :: sigma_min = 0.0_wp
    real(wp) :: R_ratio = 0.0_wp
    real(wp) :: delta_sigma = 0.0_wp
  end type FatigueState
```

### `CreepState` (lines 250–258)

```fortran
  type, public :: CreepState
    real(wp) :: epsilon_c = 0.0_wp
    real(wp) :: epsilon_c_prev = 0.0_wp
    real(wp) :: epsilon_c_dot = 0.0_wp
    real(wp) :: omega = 0.0_wp
    real(wp) :: omega_prev = 0.0_wp
    real(wp) :: t = 0.0_wp
    real(wp) :: t_prev = 0.0_wp
  end type CreepState
```

### `PhaseTransformationState` (lines 260–267)

```fortran
  type, public :: PhaseTransformationState
    real(wp) :: f_martensite = 0.0_wp
    real(wp) :: f_austenite = 1.0_wp
    real(wp) :: f_prev = 0.0_wp
    real(wp) :: T = 0.0_wp
    real(wp) :: T_prev = 0.0_wp
    real(wp) :: sigma_transform = 0.0_wp
  end type PhaseTransformationState
```

### `Mat_Entry` (lines 1196–1229)

```fortran
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
```

### `ParameterValidResult` (lines 1424–1430)

```fortran
  TYPE, PUBLIC :: ParameterValidResult
    LOGICAL :: is_valid = .TRUE.
    INTEGER(i4) :: n_warnings = 0
    INTEGER(i4) :: n_errors = 0
    CHARACTER(LEN=256), ALLOCATABLE :: warnings(:)
    CHARACTER(LEN=256), ALLOCATABLE :: errors(:)
  END TYPE ParameterValidResult
```

### `UnifMatInfo` (lines 1435–1445)

```fortran
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
```

### `UF_MaterialModel` (lines 1467–1474)

```fortran
  type, public :: UF_MaterialModel
    !! Mat model container used by element computation routines
    integer(i4) :: id = 0_i4                        ! Mat ID
    type(MatProperties) :: props                ! Mat properties
  contains
    procedure, public :: Init => UF_MaterialModel_Init
    procedure, public :: Clean => UF_MaterialModel_Clean
  end type UF_MaterialModel
```

### `ElasMatInfo` (lines 1479–1488)

```fortran
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
```

### `HypMatInfo` (lines 1490–1499)

```fortran
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
```

### `ViscMatInfo` (lines 1501–1510)

```fortran
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
```

### `DmgMatInfo` (lines 1512–1521)

```fortran
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
```

### `CreepMatInfo` (lines 1523–1532)

```fortran
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
```

### `CompMatInfo` (lines 1534–1543)

```fortran
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
```

### `HardeningTable_Init_In` (lines 1551–1553)

```fortran
    TYPE, PUBLIC :: HardeningTable_Init_In
        INTEGER(i4) :: capacity = 100                              ! Initial capacity ????
    END TYPE HardeningTable_Init_In
```

### `HardeningTable_AddPoint_In` (lines 1555–1560)

```fortran
    TYPE, PUBLIC :: HardeningTable_AddPoint_In
        REAL(wp) :: stress = 0.0_wp                                ! Yield stress ?_y ????
        REAL(wp) :: plastic_strain = 0.0_wp                        ! Plastic strain ?_p ????
        REAL(wp) :: strain_rate = 0.0_wp                           ! Strain rate ?? ????(optional)
        REAL(wp) :: temperature = 0.0_wp                            ! Temperature T ????(optional)
    END TYPE HardeningTable_AddPoint_In
```

### `HardeningTable_Interpolate_In` (lines 1562–1564)

```fortran
    TYPE, PUBLIC :: HardeningTable_Interpolate_In
        REAL(wp) :: plastic_strain = 0.0_wp                         ! Plastic strain ?_p ????
    END TYPE HardeningTable_Interpolate_In
```

### `HardeningTable_Interpolate_Out` (lines 1566–1568)

```fortran
    TYPE, PUBLIC :: HardeningTable_Interpolate_Out
        REAL(wp) :: yield_stress = 0.0_wp                          ! Yield stress ?_y ????
    END TYPE HardeningTable_Interpolate_Out
```

### `UF_DampingDef` (lines 1570–1577)

```fortran
    TYPE, PUBLIC :: UF_DampingDef
        LOGICAL :: is_defined = .FALSE.                            ! Defined flag
        REAL(wp) :: alpha = 0.0_wp                                  ! Mass proportional coefficient ? ????(Rayleigh)
        REAL(wp) :: beta = 0.0_wp                                   ! Stiffness proportional coefficient ? ????(Rayleigh)
        REAL(wp) :: composite = 0.0_wp                             ! Structural composite damping ????
    CONTAINS
        PROCEDURE :: set => damping_set
    END TYPE UF_DampingDef
```

### `DampingDef_Set_In` (lines 1579–1583)

```fortran
    TYPE, PUBLIC :: DampingDef_Set_In
        REAL(wp) :: alpha = 0.0_wp                                  ! Mass proportional ? ????(optional)
        REAL(wp) :: beta = 0.0_wp                                   ! Stiffness proportional ? ????(optional)
        REAL(wp) :: composite = 0.0_wp                              ! Composite damping ????(optional)
    END TYPE DampingDef_Set_In
```

### `UF_ExpansionDef` (lines 1585–1594)

```fortran
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
```

### `ExpansionDef_SetIso_In` (lines 1596–1599)

```fortran
    TYPE, PUBLIC :: ExpansionDef_SetIso_In
        REAL(wp) :: alpha = 0.0_wp                                  ! Expansion coefficient ? ????
        REAL(wp) :: ref_temp = 0.0_wp                              ! Reference temperature T_ref ????(optional)
    END TYPE ExpansionDef_SetIso_In
```

### `ExpDataPt` (lines 1601–1609)

```fortran
  type, public :: ExpDataPt
    !! Single experimental data point

    real(wp) :: strain = 0.0_wp
    real(wp) :: stress = 0.0_wp
    real(wp) :: temp = 0.0_wp
    real(wp) :: time = 0.0_wp
    real(wp) :: weight = 1.0_wp
  end type ExpDataPt
```

### `ExpDataSet` (lines 1611–1617)

```fortran
  type, public :: ExpDataSet
    !! Collection of experimental data points

    integer(i4) :: n_points = 0
    type(ExpDataPt), allocatable :: data(:)
    character(len=64) :: test_type = ""
  end type ExpDataSet
```

### `MatParamId` (lines 1619–1641)

```fortran
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
```

### `MatPropertyDef` (lines 1643–1664)

```fortran
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
```

### `MaterialDef_Init_In` (lines 1666–1669)

```fortran
    TYPE, PUBLIC :: MaterialDef_Init_In
        CHARACTER(LEN=MD_MAT_MAX_MATERIAL_NAME) :: name = ""
        INTEGER(i4) :: mat_type = 0                                ! Material type ????(optional)
    END TYPE MaterialDef_Init_In
```

### `MaterialDef_SetElasticIso_In` (lines 1671–1674)

```fortran
    TYPE, PUBLIC :: MaterialDef_SetElasticIso_In
        REAL(wp) :: E = 0.0_wp                                     ! Young's modulus E ????
        REAL(wp) :: nu = 0.0_wp                                    ! Poisson's ratio ? ????
    END TYPE MaterialDef_SetElasticIso_In
```

### `MaterialDef_SetPlasticMises_In` (lines 1676–1679)

```fortran
    TYPE, PUBLIC :: MaterialDef_SetPlasticMises_In
        REAL(wp) :: sigma_y0 = 0.0_wp                              ! Initial yield stress ?_y0 ????
        REAL(wp) :: H = 0.0_wp                                     ! Hardening modulus H ????(optional)
    END TYPE MaterialDef_SetPlasticMises_In
```

### `MaterialDef_SetDamping_In` (lines 1681–1685)

```fortran
    TYPE, PUBLIC :: MaterialDef_SetDamping_In
        REAL(wp) :: alpha = 0.0_wp                                  ! Mass proportional coefficient ? ????(optional)
        REAL(wp) :: beta = 0.0_wp                                   ! Stiffness proportional coefficient ? ????(optional)
        REAL(wp) :: composite = 0.0_wp                             ! Composite damping ????(optional)
    END TYPE MaterialDef_SetDamping_In
```

### `MaterialDef_SetExpansion_In` (lines 1687–1690)

```fortran
    TYPE, PUBLIC :: MaterialDef_SetExpansion_In
        REAL(wp) :: alpha = 0.0_wp                                  ! Expansion coefficient ? ????
        REAL(wp) :: ref_temp = 0.0_wp                              ! Reference temperature T_ref ????(optional)
    END TYPE MaterialDef_SetExpansion_In
```

### `MaterialDef_SetElasticOrtho_In` (lines 1692–1702)

```fortran
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
```

### `MaterialDef_SetElasticTransIso_In` (lines 1704–1710)

```fortran
    TYPE, PUBLIC :: MaterialDef_SetElasticTransIso_In
        REAL(wp) :: Ep = 0.0_wp                                    ! Young's modulus MD_MAT_E_p ????(in-plane)
        REAL(wp) :: Et = 0.0_wp                                    ! Young's modulus MD_MAT_E_t ????(transverse)
        REAL(wp) :: nup = 0.0_wp                                   ! Poisson's ratio ?_p ????(in-plane)
        REAL(wp) :: nut = 0.0_wp                                   ! Poisson's ratio ?_t ????(transverse)
        REAL(wp) :: Gp = 0.0_wp                                    ! Shear modulus G_p ????(in-plane)
    END TYPE MaterialDef_SetElasticTransIso_In
```

### `MaterialDef_SetElasticAniso_In` (lines 1712–1714)

```fortran
    TYPE, PUBLIC :: MaterialDef_SetElasticAniso_In
        REAL(wp) :: C(21) = 0.0_wp                                 ! Elastic stiffness matrix C ??????(Voigt notation)
    END TYPE MaterialDef_SetElasticAniso_In
```

### `UF_MaterialDef` (lines 1716–1807)

```fortran
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
```

### `UF_MaterialDB` (lines 1809–1819)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ComputeElasticStiffness` | 272 | `subroutine ComputeElasticStiffness(E, nu, C)` |
| SUBROUTINE | `ComputeElasticStress` | 293 | `subroutine ComputeElasticStress(E, nu, epsilon, stress)` |
| SUBROUTINE | `MD_MAT_UMAT_Damage_CDM` | 305 | `subroutine MD_MAT_UMAT_Damage_CDM(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Damage_Lemaitre` | 364 | `subroutine MD_MAT_UMAT_Damage_Lemaitre(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Damage_GTN` | 372 | `subroutine MD_MAT_UMAT_Damage_GTN(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Fatigue_Miner` | 415 | `subroutine MD_MAT_UMAT_Fatigue_Miner(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Fatigue_CoffinManson` | 463 | `subroutine MD_MAT_UMAT_Fatigue_CoffinManson(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Fatigue_ParisLaw` | 498 | `subroutine MD_MAT_UMAT_Fatigue_ParisLaw(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Creep_Norton` | 542 | `subroutine MD_MAT_UMAT_Creep_Norton(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Creep_Garofalo` | 585 | `subroutine MD_MAT_UMAT_Creep_Garofalo(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Creep_KachanovRabotnov` | 629 | `subroutine MD_MAT_UMAT_Creep_KachanovRabotnov(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `UM_Ph_Martensite` | 683 | `subroutine UM_Ph_Martensite(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `UM_Ph_Austenite` | 723 | `subroutine UM_Ph_Austenite(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `UM_Mu_Homogenization` | 734 | `subroutine UM_Mu_Homogenization(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Multiscale_RVE` | 758 | `subroutine MD_MAT_UMAT_Multiscale_RVE(umat_ifc, umat_in, umat_out, status)` |
| SUBROUTINE | `MD_MAT_UMAT_602` | 769 | `SUBROUTINE MD_MAT_UMAT_602(stress, statev, ddsdde, sse, spd, scd, rpl, &` |
| SUBROUTINE | `BuildElasticStiffness_602` | 902 | `SUBROUTINE BuildElasticStiffness_602(lambda, mu, ndi, nshr, ntens, analysis_type, D)` |
| SUBROUTINE | `ComputeThermalStrain_602` | 934 | `SUBROUTINE ComputeThermalStrain_602(alpha, dT, ndi, nshr, ntens, strain_thermal)` |
| SUBROUTINE | `ComputeSurfaceStress_602` | 945 | `SUBROUTINE ComputeSurfaceStress_602(surface_stress, surface_to_volu, surface_thickne, ndi, nshr, ntens, stress_surface)` |
| SUBROUTINE | `UF_Legacy_Special_602` | 958 | `SUBROUTINE UF_Legacy_Special_602(stress, statev, ddsdde, sse, spd, scd, rpl, &` |
| SUBROUTINE | `MD_MAT_UMAT_603` | 987 | `SUBROUTINE MD_MAT_UMAT_603(stress, statev, ddsdde, sse, spd, scd, rpl, &` |
| SUBROUTINE | `MD_MAT_UMAT_603_Internal` | 1004 | `SUBROUTINE MD_MAT_UMAT_603_Internal(stress, statev, ddsdde, sse, spd, scd, rpl, &` |
| SUBROUTINE | `ComputeGradientParameter603` | 1100 | `SUBROUTINE ComputeGradientParameter603(position, gradient_direct, gradient_length, gradient_type, gradient_expone, gradient_parame)` |
| SUBROUTINE | `BuildElasticStiffness603` | 1122 | `SUBROUTINE BuildElasticStiffness603(E, nu, ndim, analysis_type, D)` |
| SUBROUTINE | `UF_Legacy_Special_603` | 1155 | `SUBROUTINE UF_Legacy_Special_603(stress, statev, ddsdde, sse, spd, scd, rpl, &` |
| SUBROUTINE | `MatProperties_Init` | 1826 | `subroutine MatProperties_Init(this, material_id, props, density)` |
| SUBROUTINE | `MatProperties_Clean` | 1847 | `subroutine MatProperties_Clean(this)` |
| SUBROUTINE | `UF_MaterialModel_Init` | 1858 | `subroutine UF_MaterialModel_Init(this, material_id, props, density)` |
| SUBROUTINE | `UF_MaterialModel_Clean` | 1872 | `subroutine UF_MaterialModel_Clean(this)` |
| SUBROUTINE | `HardeningTable_Init_Structured` | 1950 | `SUBROUTINE HardeningTable_Init_Structured(in, table, status)` |
| SUBROUTINE | `HardeningTable_AddPoint_Structured` | 1961 | `SUBROUTINE HardeningTable_AddPoint_Structured(in, table, status)` |
| SUBROUTINE | `HardeningTable_Interpolate_Structured` | 1972 | `SUBROUTINE HardeningTable_Interpolate_Structured(in, out, table)` |
| SUBROUTINE | `MaterialDef_Init_Structured` | 1981 | `SUBROUTINE MaterialDef_Init_Structured(in, material, status)` |
| SUBROUTINE | `MaterialDef_SetElasticIso_Structured` | 1992 | `SUBROUTINE MaterialDef_SetElasticIso_Structured(in, material, status)` |
| SUBROUTINE | `MaterialDef_SetPlasticMises_Structured` | 2003 | `SUBROUTINE MaterialDef_SetPlasticMises_Structured(in, material, status)` |
| SUBROUTINE | `MaterialDef_SetDamping_Structured` | 2014 | `SUBROUTINE MaterialDef_SetDamping_Structured(in, material, status)` |
| SUBROUTINE | `MaterialDef_SetExpansion_Structured` | 2025 | `SUBROUTINE MaterialDef_SetExpansion_Structured(in, material, status)` |
| SUBROUTINE | `MaterialDef_SetElasticOrtho_Structured` | 2036 | `SUBROUTINE MaterialDef_SetElasticOrtho_Structured(in, material, status)` |
| SUBROUTINE | `MaterialDef_SetElasticTransIso_Structured` | 2047 | `SUBROUTINE MaterialDef_SetElasticTransIso_Structured(in, material, status)` |
| SUBROUTINE | `MaterialDef_SetElasticAniso_Structured` | 2057 | `SUBROUTINE MaterialDef_SetElasticAniso_Structured(in, material, status)` |
| SUBROUTINE | `DampingDef_Set_Structured` | 2067 | `SUBROUTINE DampingDef_Set_Structured(in, damping, status)` |
| SUBROUTINE | `ExpansionDef_SetIso_Structured` | 2078 | `SUBROUTINE ExpansionDef_SetIso_Structured(in, expansion, status)` |
| SUBROUTINE | `hardening_init` | 2105 | `SUBROUTINE hardening_init(this, capacity)` |
| SUBROUTINE | `hardening_add_point` | 2132 | `SUBROUTINE hardening_add_point(this, stress, plastic_strain)` |
| FUNCTION | `hardening_interpolate` | 2154 | `FUNCTION hardening_interpolate(this, eps_p) RESULT(sigma_y)` |
| SUBROUTINE | `damping_set` | 2203 | `SUBROUTINE damping_set(this, alpha, beta, composite)` |
| SUBROUTINE | `expansion_set_iso` | 2227 | `SUBROUTINE expansion_set_iso(this, alpha, ref_temp)` |
| SUBROUTINE | `expansion_set_ortho3` | 2241 | `SUBROUTINE expansion_set_ortho3(this, a11, a22, a33, ref_temp)` |
| SUBROUTINE | `expansion_set_aniso_voigt6` | 2256 | `SUBROUTINE expansion_set_aniso_voigt6(this, a6, ref_temp)` |
| SUBROUTINE | `material_set_damping` | 2280 | `SUBROUTINE material_set_damping(this, alpha, beta, composite)` |
| SUBROUTINE | `material_set_expansion` | 2294 | `SUBROUTINE material_set_expansion(this, alpha, ref_temp)` |
| SUBROUTINE | `material_init` | 2311 | `SUBROUTINE material_init(this, name, mat_type)` |
| SUBROUTINE | `material_set_elastic_iso` | 2368 | `SUBROUTINE material_set_elastic_iso(this, E, nu)` |
| SUBROUTINE | `material_set_elastic_ortho` | 2394 | `SUBROUTINE material_set_elastic_ortho(this, E1, E2, E3, nu12, nu13, nu23, G12, G13, G23)` |
| SUBROUTINE | `material_set_elastic_transiso` | 2423 | `SUBROUTINE material_set_elastic_transiso(this, Ep, Et, nup, nut, Gp)` |
| SUBROUTINE | `material_set_elastic_aniso` | 2444 | `SUBROUTINE material_set_elastic_aniso(this, C)` |
| SUBROUTINE | `material_set_plastic_mises` | 2463 | `SUBROUTINE material_set_plastic_mises(this, sigma_y0, H)` |
| SUBROUTINE | `material_set_plastic_dp` | 2475 | `SUBROUTINE material_set_plastic_dp(this, phi, c, H_iso, psi)` |
| SUBROUTINE | `material_set_plastic_cc` | 2489 | `SUBROUTINE material_set_plastic_cc(this, M, pc0, H_pc, H_iso)` |
| SUBROUTINE | `material_set_plastic_mc` | 2502 | `SUBROUTINE material_set_plastic_mc(this, phi, c, H_iso, psi)` |
| SUBROUTINE | `material_set_plastic_cdpm` | 2516 | `SUBROUTINE material_set_plastic_cdpm(this, phi, c, H_iso, d0, H_d, d_max)` |
| SUBROUTINE | `material_set_viscoplastic_iso` | 2531 | `SUBROUTINE material_set_viscoplastic_iso(this, MD_MAT_E_ref, nu, sigma_y0_ref, H_ref, m_rate, &` |
| SUBROUTINE | `material_set_damage_ortho_puck` | 2569 | `SUBROUTINE material_set_damage_ortho_puck(this, &` |
| SUBROUTINE | `material_set_hyperelastic_nh` | 2620 | `SUBROUTINE material_set_hyperelastic_nh(this, C10, D1)` |
| SUBROUTINE | `material_set_density` | 2645 | `SUBROUTINE material_set_density(this, rho)` |
| SUBROUTINE | `material_set_thermal` | 2660 | `SUBROUTINE material_set_thermal(this, alpha, k, c)` |
| SUBROUTINE | `material_get_D_matrix` | 2684 | `SUBROUTINE material_get_D_matrix(this, D, ndim, plane_type)` |
| SUBROUTINE | `material_clear` | 2753 | `SUBROUTINE material_clear(this)` |
| SUBROUTINE | `matdb_init` | 2772 | `SUBROUTINE matdb_init(this, capacity)` |
| SUBROUTINE | `matdb_add_material` | 2793 | `SUBROUTINE matdb_add_material(this, mat)` |
| FUNCTION | `matdb_find_by_name` | 2820 | `FUNCTION matdb_find_by_name(this, name) RESULT(idx)` |
| FUNCTION | `matdb_find_by_id` | 2844 | `FUNCTION matdb_find_by_id(this, id) RESULT(idx)` |
| FUNCTION | `matdb_get_material` | 2862 | `FUNCTION matdb_get_material(this, idx) RESULT(mat_ptr)` |
| SUBROUTINE | `matdb_clear` | 2879 | `SUBROUTINE matdb_clear(this)` |
| SUBROUTINE | `MatTree_BeginBatch` | 2889 | `subroutine MatTree_BeginBatch(this, max_size)` |
| SUBROUTINE | `MatTree_Deserialize` | 2896 | `subroutine MatTree_Deserialize(this, deserializer)` |
| SUBROUTINE | `MatTree_DestroyTree` | 2938 | `subroutine MatTree_DestroyTree(this, status)` |
| SUBROUTINE | `MatTree_EndBatch` | 2951 | `subroutine MatTree_EndBatch(this, rebuild_index, status)` |
| FUNCTION | `MatTree_GetByPath` | 2969 | `function MatTree_GetByPath(this, path_str) result(obj_ptr)` |
| FUNCTION | `MatTree_GetFullPath` | 2990 | `function MatTree_GetFullPath(this) result(path_str)` |
| FUNCTION | `MatTree_GetID` | 3005 | `function MatTree_GetID(this) result(id)` |
| FUNCTION | `MatTree_GetName` | 3012 | `function MatTree_GetName(this) result(name)` |
| FUNCTION | `MatTree_GetParentID` | 3018 | `function MatTree_GetParentID(this) result(pid)` |
| FUNCTION | `MatTree_GetType` | 3024 | `function MatTree_GetType(this) result(ntype)` |
| SUBROUTINE | `MatTree_InitTree` | 3030 | `subroutine MatTree_InitTree(this, initial_capacit, status)` |
| SUBROUTINE | `MatTree_RebuildIndex` | 3051 | `subroutine MatTree_RebuildIndex(this, status)` |
| SUBROUTINE | `MatTree_Serialize` | 3067 | `subroutine MatTree_Serialize(this, serializer)` |
| SUBROUTINE | `MatTree_ValidateTree` | 3097 | `subroutine MatTree_ValidateTree(this, status)` |
| SUBROUTINE | `MD_Mat_GetLameParameters` | 3128 | `SUBROUTINE MD_Mat_GetLameParameters(E, nu, lambda, mu)` |
| SUBROUTINE | `MD_Mat_ValidateProperties` | 3149 | `SUBROUTINE MD_Mat_ValidateProperties(E, nu, is_valid, status)` |
| SUBROUTINE | `MD_MAT_DB_Init` | 3184 | `SUBROUTINE MD_MAT_DB_Init()` |
| FUNCTION | `MD_MAT_DB_GetMaterialByName` | 3435 | `FUNCTION MD_MAT_DB_GetMaterialByName(mat_name) RESULT(mat_entry)` |
| FUNCTION | `MD_MAT_DB_GetMaterialByID` | 3468 | `FUNCTION MD_MAT_DB_GetMaterialByID(mat_id) RESULT(mat_entry)` |
| SUBROUTINE | `MD_MAT_DB_ListAllMaterials` | 3488 | `SUBROUTINE MD_MAT_DB_ListAllMaterials()` |
| SUBROUTINE | `MD_MAT_DB_ValidateParameters` | 3527 | `SUBROUTINE MD_MAT_DB_ValidateParameters(mat_entry, err_stat)` |
| SUBROUTINE | `MD_MAT_DB_Finalize` | 3561 | `SUBROUTINE MD_MAT_DB_Finalize()` |
| SUBROUTINE | `MatValid_Props` | 3578 | `subroutine MatValid_Props(properties, validator, status)` |
| SUBROUTINE | `MatChk_PropRange` | 3593 | `subroutine MatChk_PropRange(propId, value, minValue, maxValue, status)` |
| SUBROUTINE | `MatChk_Compat` | 3608 | `subroutine MatChk_Compat(matId1, matId2, status)` |
| SUBROUTINE | `MatGet_PropInfo` | 3616 | `subroutine MatGet_PropInfo(id, propName, propValue, status)` |
| SUBROUTINE | `MatInit_StateV` | 3627 | `subroutine MatInit_StateV(state, initialValues, varNames, status)` |
| SUBROUTINE | `MatUpd_StateV` | 3643 | `subroutine MatUpd_StateV(state, newValues, status)` |
| SUBROUTINE | `GetStateV` | 3653 | `subroutine GetStateV(state, varId, value, status)` |
| SUBROUTINE | `SetStateV` | 3668 | `subroutine SetStateV(state, varId, value, status)` |
| SUBROUTINE | `MatComp_Stress` | 3682 | `subroutine MatComp_Stress(ntens, strain, properties, stress, status)` |
| SUBROUTINE | `MatInterp_Prop` | 3693 | `subroutine MatInterp_Prop(temperatures, properties, temp, propId, value)` |
| SUBROUTINE | `MatSet_Ori` | 3702 | `subroutine MatSet_Ori(orientation, angles, status)` |
| SUBROUTINE | `MatXform_Props` | 3713 | `subroutine MatXform_Props(properties, rotationMatrix, transformedprop, status)` |
| SUBROUTINE | `MatXform_Stress` | 3724 | `subroutine MatXform_Stress(stress, rotationMatrix, transformedstre, status)` |
| SUBROUTINE | `MatXform_Strain` | 3735 | `subroutine MatXform_Strain(strain, rotationMatrix, transformedstra, status)` |
| SUBROUTINE | `MatParamId_Init` | 3754 | `subroutine MatParamId_Init(this, n_params, method, status)` |
| SUBROUTINE | `MatParamId_LoadData` | 3781 | `subroutine MatParamId_LoadData(this, data_points, test_type, status)` |
| SUBROUTINE | `MatParamId_SetBounds` | 3804 | `subroutine MatParamId_SetBounds(this, param_lower, param_upper, &` |
| SUBROUTINE | `MatParamId_Identify` | 3833 | `subroutine MatParamId_Identify(this, model_mate_func, status)` |
| SUBROUTINE | `model_mate_func` | 3837 | `subroutine model_mate_func(params, strains, stresses, status)` |
| SUBROUTINE | `MatParamId_GetParams` | 3854 | `subroutine MatParamId_GetParams(this, params, status)` |
| FUNCTION | `MatParamId_GetError` | 3872 | `function MatParamId_GetError(this) result(error)` |
| SUBROUTINE | `MatParamId_Cleanup` | 3879 | `subroutine MatParamId_Cleanup(this)` |
| SUBROUTINE | `MatParamId_LSQ` | 3892 | `subroutine MatParamId_LSQ(identifier, model_mate_func, status)` |
| SUBROUTINE | `model_mate_func` | 3895 | `subroutine model_mate_func(params, strains, stresses, status)` |
| SUBROUTINE | `UF_Mat_Eval_Dispatch` | 4206 | `SUBROUTINE UF_Mat_Eval_Dispatch(material_id, nprops, props, ctx, algo, status)` |
| SUBROUTINE | `UF_Mat_Eval_Dispatch_FromDesc` | 4270 | `SUBROUTINE UF_Mat_Eval_Dispatch_FromDesc(desc, ctx, algo, status)` |
| SUBROUTINE | `UF_Mat_UMAT_Dispatch` | 4331 | `SUBROUTINE UF_Mat_UMAT_Dispatch(material_id, stress, statev, ddsdde,   &` |
| SUBROUTINE | `MatEval_Ctx` | 4407 | `subroutine MatEval_Ctx(ctx)` |
| SUBROUTINE | `MatEval` | 4461 | `subroutine MatEval(ctx, res, status)` |
| SUBROUTINE | `UniUMAT` | 4490 | `subroutine UniUMAT(kin, desc, res, status)` |
| SUBROUTINE | `MatEval_Plast` | 4637 | `subroutine MatEval_Plast(ctx, res, status)` |
| SUBROUTINE | `MatEval_Mises` | 4666 | `subroutine MatEval_Mises(ctx, res, status)` |
| SUBROUTINE | `MatEval_DP` | 4855 | `subroutine MatEval_DP(ctx, res, status)` |
| FUNCTION | `MD_Mat_GetCategoryFromName` | 4959 | `FUNCTION MD_Mat_GetCategoryFromName(category_name) RESULT(category)` |
| SUBROUTINE | `MD_Mat_InitReg` | 4993 | `SUBROUTINE MD_Mat_InitReg(status)` |
| SUBROUTINE | `MD_Mat_Reg_Int` | 5073 | `SUBROUTINE MD_Mat_Reg_Int(material_id, name, category, &` |
| SUBROUTINE | `MD_Mat_ValidParameterConsist` | 5135 | `SUBROUTINE MD_Mat_ValidParameterConsist(props, nprops, &` |
| SUBROUTINE | `MD_Mat_ValidParameterDepende` | 5187 | `SUBROUTINE MD_Mat_ValidParameterDepende(props, nprops, &` |
| SUBROUTINE | `MD_Mat_ValidParameterRange` | 5237 | `SUBROUTINE MD_Mat_ValidParameterRange(param_value, param_name, &` |
| SUBROUTINE | `MD_Mat_ValidParameters` | 5278 | `SUBROUTINE MD_Mat_ValidParameters(material_id, props, nprops, &` |
| SUBROUTINE | `UF_AddValidationError` | 5344 | `SUBROUTINE UF_AddValidationError(result, error_message)` |
| SUBROUTINE | `UF_AddValidationWarning` | 5363 | `SUBROUTINE UF_AddValidationWarning(result, warning_message)` |
| SUBROUTINE | `UF_Comp_ValidParameters` | 5378 | `SUBROUTINE UF_Comp_ValidParameters(material_id, props, nprops, &` |
| SUBROUTINE | `UF_Creep_ValidateParameters` | 5416 | `SUBROUTINE UF_Creep_ValidateParameters(material_id, props, nprops, &` |
| SUBROUTINE | `UF_Damage_ValidateParameters` | 5450 | `SUBROUTINE UF_Damage_ValidateParameters(material_id, props, nprops, &` |
| SUBROUTINE | `UF_Elastic_ValidParameters` | 5510 | `SUBROUTINE UF_Elastic_ValidParameters(material_id, props, nprops, &` |
| SUBROUTINE | `UF_Hyp_ValidParameters` | 5561 | `SUBROUTINE UF_Hyp_ValidParameters(material_id, props, nprops, &` |
| FUNCTION | `UF_IntToString` | 5633 | `FUNCTION UF_IntToString(value) RESULT(str)` |
| FUNCTION | `UF_Mat_GetCategory` | 5639 | `FUNCTION UF_Mat_GetCategory(material_id) RESULT(category)` |
| SUBROUTINE | `UF_Mat_GetInfo` | 5672 | `SUBROUTINE UF_Mat_GetInfo(material_id, info, status)` |
| SUBROUTINE | `UF_Mat_ListMaterials` | 5827 | `SUBROUTINE UF_Mat_ListMaterials(category_filter, material_list, n_materials, status)` |
| SUBROUTINE | `UF_Mat_Reg` | 5872 | `SUBROUTINE UF_Mat_Reg(material_id, name, category_name, &` |
| SUBROUTINE | `UF_Mat_RegBuiltInMats` | 5902 | `SUBROUTINE UF_Mat_RegBuiltInMats(status)` |
| SUBROUTINE | `UF_Plastic_ValidParameters` | 6328 | `SUBROUTINE UF_Plastic_ValidParameters(material_id, props, nprops, &` |
| SUBROUTINE | `MD_Mat_ValidatePlasticPropsForPopulate` | 6392 | `SUBROUTINE MD_Mat_ValidatePlasticPropsForPopulate(desc, props, nprops, status)` |
| SUBROUTINE | `MD_Mat_ValidatePropsForPopulate` | 6432 | `SUBROUTINE MD_Mat_ValidatePropsForPopulate(desc, props, nprops, status)` |
| SUBROUTINE | `UF_ReallocateErrors` | 6472 | `SUBROUTINE UF_ReallocateErrors(errors_array, new_size)` |
| SUBROUTINE | `UF_ReallocateWarnings` | 6494 | `SUBROUTINE UF_ReallocateWarnings(warnings_array, new_size)` |
| FUNCTION | `UF_RealToString` | 6516 | `FUNCTION UF_RealToString(value) RESULT(str)` |
| SUBROUTINE | `UF_ToUpper` | 6522 | `SUBROUTINE UF_ToUpper(str)` |
| SUBROUTINE | `UF_Vi_ValidParameters` | 6538 | `SUBROUTINE UF_Vi_ValidParameters(material_id, props, nprops, &` |
| SUBROUTINE | `UF_Elastic_GetMaterialInfo` | 6655 | `SUBROUTINE UF_Elastic_GetMaterialInfo(material_id, info, status)` |
| SUBROUTINE | `UF_Hyp_GetMatInfo` | 6665 | `SUBROUTINE UF_Hyp_GetMatInfo(material_id, info, status)` |
| SUBROUTINE | `UF_Viscoelastic_GetMatInfo` | 6675 | `SUBROUTINE UF_Viscoelastic_GetMatInfo(material_id, info, status)` |
| SUBROUTINE | `UF_Damage_GetMaterialInfo` | 6685 | `SUBROUTINE UF_Damage_GetMaterialInfo(material_id, info, status)` |
| SUBROUTINE | `UF_Creep_GetMaterialInfo` | 6695 | `SUBROUTINE UF_Creep_GetMaterialInfo(material_id, info, status)` |
| SUBROUTINE | `UF_Composite_GetMaterialInfo` | 6705 | `SUBROUTINE UF_Composite_GetMaterialInfo(material_id, info, status)` |
| SUBROUTINE | `UF_Elastic_RegAllMats` | 6720 | `SUBROUTINE UF_Elastic_RegAllMats(status)` |
| SUBROUTINE | `UF_Hyp_RegAllMats` | 6726 | `SUBROUTINE UF_Hyp_RegAllMats(status)` |
| SUBROUTINE | `UF_Creep_RegAllMats` | 6732 | `SUBROUTINE UF_Creep_RegAllMats(status)` |
| SUBROUTINE | `UF_Viscoelastic_InitReg` | 6738 | `SUBROUTINE UF_Viscoelastic_InitReg(status)` |
| SUBROUTINE | `UF_Viscoelastic_RegAllMats` | 6744 | `SUBROUTINE UF_Viscoelastic_RegAllMats(status)` |
| SUBROUTINE | `UF_Damage_InitializeRegistry` | 6750 | `SUBROUTINE UF_Damage_InitializeRegistry(status)` |
| SUBROUTINE | `UF_Dmg_RegAllMats` | 6756 | `SUBROUTINE UF_Dmg_RegAllMats(status)` |
| SUBROUTINE | `UF_Comp_InitReg` | 6762 | `SUBROUTINE UF_Comp_InitReg(status)` |
| SUBROUTINE | `UF_Comp_RegAllMats` | 6768 | `SUBROUTINE UF_Comp_RegAllMats(status)` |
| SUBROUTINE | `UF_AnisotropicElastic_ValidProps` | 6778 | `SUBROUTINE UF_AnisotropicElastic_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_ArrudaBoyceHyp_ValidProps` | 6785 | `SUBROUTINE UF_ArrudaBoyceHyp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_BrittleDmg_ValidProps` | 6792 | `SUBROUTINE UF_BrittleDmg_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_CamClay_ValidateProps` | 6799 | `SUBROUTINE UF_CamClay_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_DruckerPrager_ValidateProps` | 6806 | `SUBROUTINE UF_DruckerPrager_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_DuctileDmg_ValidProps` | 6813 | `SUBROUTINE UF_DuctileDmg_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_FatigueDmg_ValidProps` | 6820 | `SUBROUTINE UF_FatigueDmg_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_FiberReinfComp_ValidProps` | 6827 | `SUBROUTINE UF_FiberReinfComp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_GarofaloCreep_ValidProps` | 6834 | `SUBROUTINE UF_GarofaloCreep_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_Hill_ValidateProps` | 6841 | `SUBROUTINE UF_Hill_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_HyperfoamHyp_ValidProps` | 6848 | `SUBROUTINE UF_HyperfoamHyp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_IsotropicElastic_ValidProps` | 6855 | `SUBROUTINE UF_IsotropicElastic_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_JohnsonCook_ValidateProps` | 6862 | `SUBROUTINE UF_JohnsonCook_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_LamComp_ValidProps` | 6869 | `SUBROUTINE UF_LamComp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_MRHyp_ValidProps` | 6876 | `SUBROUTINE UF_MRHyp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_MarlowHyp_ValidProps` | 6883 | `SUBROUTINE UF_MarlowHyp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_MohrCoulomb_ValidateProps` | 6890 | `SUBROUTINE UF_MohrCoulomb_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_NeoHookeanHyp_ValidProps` | 6897 | `SUBROUTINE UF_NeoHookeanHyp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_NortonCreep_ValidateProps` | 6904 | `SUBROUTINE UF_NortonCreep_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_OgdenHyp_ValidProps` | 6911 | `SUBROUTINE UF_OgdenHyp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_PorousElastic_ValidProps` | 6918 | `SUBROUTINE UF_PorousElastic_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_ProgDmg_ValidProps` | 6925 | `SUBROUTINE UF_ProgDmg_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_PronyViscoelastic_ValidProps` | 6932 | `SUBROUTINE UF_PronyViscoelastic_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_ThermalDmg_ValidProps` | 6939 | `SUBROUTINE UF_ThermalDmg_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_TransverseIsoElastic_ValidProps` | 6946 | `SUBROUTINE UF_TransverseIsoElastic_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_VanDerWaalsHyp_ValidProps` | 6953 | `SUBROUTINE UF_VanDerWaalsHyp_ValidProps(props, nprops, status)` |
| SUBROUTINE | `UF_VonMises_ValidateProps` | 6960 | `SUBROUTINE UF_VonMises_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_YeohHyp_ValidProps` | 6967 | `SUBROUTINE UF_YeohHyp_ValidProps(props, nprops, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 3836–3844 | `interface` |
| 3894–3902 | `interface` |
