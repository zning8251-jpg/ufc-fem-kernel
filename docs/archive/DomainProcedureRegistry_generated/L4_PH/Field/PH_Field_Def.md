# `PH_Field_Def.f90`

- **Source**: `L4_PH/Field/PH_Field_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Field_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Field_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Field`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Field/PH_Field_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Field_Desc` (lines 29–35)

```fortran
  TYPE, PUBLIC :: PH_Field_Desc
    INTEGER(i4) :: nn      = 0   ! number of element nodes
    INTEGER(i4) :: nip     = 0   ! number of integration points
    INTEGER(i4) :: ndim    = 3   ! spatial dimension
    INTEGER(i4) :: n_comp  = 1   ! number of field components
    INTEGER(i4) :: n_nodes = 0   ! total nodes for global averaging
  END TYPE PH_Field_Desc
```

### `PH_Field_Ctx` (lines 42–57)

```fortran
  TYPE, PUBLIC :: PH_Field_Ctx
    REAL(wp) :: N_shape(27)       = 0.0_wp   ! shape function values
    REAL(wp) :: dN_dx(3,27)       = 0.0_wp   ! shape function derivatives
    REAL(wp) :: E_mat(27,27)      = 0.0_wp   ! extrapolation matrix
    REAL(wp) :: ip_vals(6,27)     = 0.0_wp   ! IP values (n_comp, nip)
    REAL(wp) :: nodal_vals(6,27)  = 0.0_wp   ! nodal values (n_comp, nn)
    REAL(wp) :: grad(3)           = 0.0_wp   ! gradient result
    REAL(wp) :: stress_voigt(6)   = 0.0_wp   ! stress for invariants
    REAL(wp) :: I1                = 0.0_wp   ! first invariant
    REAL(wp) :: J2                = 0.0_wp   ! second deviatoric invariant
    REAL(wp) :: J3                = 0.0_wp   ! third deviatoric invariant
    ! Global averaging buffers (allocated externally)
    REAL(wp),    POINTER :: nodal_sum(:,:)   => NULL()  ! (n_comp, n_nodes)
    INTEGER(i4), POINTER :: nodal_count(:)   => NULL()  ! (n_nodes)
    REAL(wp),    POINTER :: nodal_avg(:,:)   => NULL()  ! (n_comp, n_nodes)
  END TYPE PH_Field_Ctx
```

### `PH_Field_State` (lines 62–68)

```fortran
  TYPE, PUBLIC :: PH_Field_State
    LOGICAL     :: allocated    = .FALSE.
    LOGICAL     :: values_set   = .FALSE.
    INTEGER(i4) :: n_dof_active = 0
    INTEGER(i4) :: current_step = 0
    INTEGER(i4) :: current_incr = 0
  END TYPE PH_Field_State
```

### `PH_Field_Cfg_Time` (lines 74–79)

```fortran
  TYPE, PUBLIC :: PH_Field_Cfg_Time
    INTEGER(i4) :: time_integration = 1_i4    ! 1=backward Euler, 2=Crank-Nicolson
    REAL(wp)    :: theta             = 1.0_wp  ! time integration parameter
    REAL(wp)    :: dt                = 0.0_wp  ! current time step
    LOGICAL     :: lumped_capacity   = .FALSE. ! lumped vs consistent capacity
  END TYPE PH_Field_Cfg_Time
```

### `PH_Field_Cfg_Control` (lines 82–86)

```fortran
  TYPE, PUBLIC :: PH_Field_Cfg_Control
    INTEGER(i4) :: extrapolation     = 1_i4    ! 1=IP-to-node, 2=L2 projection
    INTEGER(i4) :: max_field_iter    = 1_i4    ! field sub-iterations
    REAL(wp)    :: field_tol         = 1.0E-6_wp ! convergence tolerance
  END TYPE PH_Field_Cfg_Control
```

### `PH_Field_Algo` (lines 88–92)

```fortran
  TYPE, PUBLIC :: PH_Field_Algo
    TYPE(PH_Field_Cfg_Time)    :: time
    TYPE(PH_Field_Cfg_Control) :: ctrl
    ! NOTE: Flat fields removed after P2 migration (zero external references verified)
  END TYPE PH_Field_Algo
```

### `PH_Field_Domain` (lines 97–104)

```fortran
  TYPE, PUBLIC :: PH_Field_Domain
    TYPE(PH_Field_Desc)  :: desc
    TYPE(PH_Field_State) :: state
    TYPE(PH_Field_Algo)  :: algo
    TYPE(PH_Field_Ctx)   :: ctx
    INTEGER(i4) :: domain_id    = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  END TYPE PH_Field_Domain
```

### `PH_Temperature_Desc` (lines 110–115)

```fortran
  TYPE :: PH_Temperature_Desc
    REAL(wp) :: thermal_conductivity = 0.0_wp
    REAL(wp) :: heat_capacity        = 1.0_wp
    REAL(wp) :: density              = 1.0_wp
    REAL(wp) :: heat_source          = 0.0_wp
  END TYPE PH_Temperature_Desc
```

### `PH_Temperature_Algo` (lines 117–123)

```fortran
  TYPE :: PH_Temperature_Algo
    INTEGER(i4) :: time_integration = 1_i4
    REAL(wp)    :: dt               = 0.0_wp
    REAL(wp)    :: theta            = 1.0_wp
    REAL(wp)    :: tolerance        = 1.0E-6_wp
    INTEGER(i4) :: max_iter         = 25_i4
  END TYPE PH_Temperature_Algo
```

### `PH_Temperature_Arg` (lines 125–129)

```fortran
  TYPE :: PH_Temperature_Arg
    REAL(wp), POINTER     :: t_n(:,:) => NULL() ! [IN]
    REAL(wp), ALLOCATABLE :: temperature(:,:)   ! [OUT]
    REAL(wp), ALLOCATABLE :: heat_flux(:,:)     ! [OUT]
  END TYPE PH_Temperature_Arg
```

### `PH_PorePressure_Desc` (lines 131–136)

```fortran
  TYPE :: PH_PorePressure_Desc
    REAL(wp) :: permeability    = 0.0_wp
    REAL(wp) :: storativity     = 1.0_wp
    REAL(wp) :: fluid_density   = 1.0_wp
    REAL(wp) :: fluid_viscosity = 1.0_wp
  END TYPE PH_PorePressure_Desc
```

### `PH_PorePressure_Algo` (lines 138–144)

```fortran
  TYPE :: PH_PorePressure_Algo
    INTEGER(i4) :: time_integration = 1_i4
    REAL(wp)    :: dt               = 0.0_wp
    REAL(wp)    :: theta            = 1.0_wp
    REAL(wp)    :: tolerance        = 1.0E-6_wp
    INTEGER(i4) :: max_iter         = 25_i4
  END TYPE PH_PorePressure_Algo
```

### `PH_PorePressure_In` (lines 146–148)

```fortran
  TYPE :: PH_PorePressure_In
    REAL(wp), POINTER :: pressure(:,:) => NULL() ! [IN]
  END TYPE PH_PorePressure_In
```

### `PH_PorePressure_Out` (lines 150–153)

```fortran
  TYPE :: PH_PorePressure_Out
    REAL(wp), ALLOCATABLE :: pressure(:,:) ! [OUT]
    REAL(wp), ALLOCATABLE :: velocity(:,:) ! [OUT]
  END TYPE PH_PorePressure_Out
```

### `PH_Concentration_Desc` (lines 155–160)

```fortran
  TYPE :: PH_Concentration_Desc
    REAL(wp) :: diffusivity    = 0.0_wp
    REAL(wp) :: reaction_rate  = 0.0_wp
    REAL(wp) :: source_rate    = 0.0_wp
    LOGICAL  :: has_reaction   = .FALSE.
  END TYPE PH_Concentration_Desc
```

### `PH_Concentration_Algo` (lines 162–168)

```fortran
  TYPE :: PH_Concentration_Algo
    INTEGER(i4) :: time_integration = 1_i4
    REAL(wp)    :: dt               = 0.0_wp
    REAL(wp)    :: theta            = 1.0_wp
    REAL(wp)    :: tolerance        = 1.0E-6_wp
    INTEGER(i4) :: max_iter         = 25_i4
  END TYPE PH_Concentration_Algo
```

### `PH_Concentration_In` (lines 170–172)

```fortran
  TYPE :: PH_Concentration_In
    REAL(wp), POINTER :: concentration(:,:) => NULL() ! [IN]
  END TYPE PH_Concentration_In
```

### `PH_Concentration_Out` (lines 174–177)

```fortran
  TYPE :: PH_Concentration_Out
    REAL(wp), ALLOCATABLE :: concentration(:,:) ! [OUT]
    REAL(wp), ALLOCATABLE :: flux(:,:)          ! [OUT]
  END TYPE PH_Concentration_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
