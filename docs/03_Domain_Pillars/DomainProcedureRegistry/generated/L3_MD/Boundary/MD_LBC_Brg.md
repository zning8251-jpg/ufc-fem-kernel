# `MD_LBC_Brg.f90`

- **Source**: `L3_MD/Boundary/MD_LBC_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_LBC_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBC_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBC`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_LBC_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_BCDef` (lines 87–107)

```fortran
    TYPE, PUBLIC :: UF_BCDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        INTEGER(i4) :: bc_type = BC_DISPLACEMENT
        CHARACTER(LEN=MAX_LOADBC_NAME) :: region_name = ""
        INTEGER(i4) :: region_type = 0          ! 1=nset, 2=surface, 0=node_id
        INTEGER(i4) :: node_id = 0              ! Direct node ID referencing
        ! DOF specification (1-6 for mechanical)
        INTEGER(i4) :: dof_first = 1
        INTEGER(i4) :: dof_last = 1
        REAL(wp) :: magnitude = 0.0_wp
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
        LOGICAL :: is_active = .TRUE.
        LOGICAL :: op_new = .TRUE.              ! OP=NEW or OP=MOD
    CONTAINS
        PROCEDURE :: init => bc_init
        PROCEDURE :: set_displacement => bc_set_displacement
        PROCEDURE :: set_fixed => bc_set_fixed
        PROCEDURE :: set_symmetry => bc_set_symmetry
        PROCEDURE :: get_value_at_time => bc_get_value_at_time
        PROCEDURE :: print_info => bc_print_info
    END TYPE UF_BCDef
```

### `UF_CLoadDef` (lines 114–130)

```fortran
    TYPE, PUBLIC :: UF_CLoadDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""              ! Load name
        CHARACTER(LEN=MAX_LOADBC_NAME) :: nset_name = ""         ! Node set name
        INTEGER(i4) :: node_id = 0                                ! Direct node ID
        INTEGER(i4) :: dof = 1                                    ! DOF direction
        REAL(wp) :: magnitude = 0.0_wp                            ! Load magnitude F_0

        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""     ! Amplitude name
        LOGICAL :: follower = .FALSE.                              ! Follower force flag
        LOGICAL :: is_active = .TRUE.                              ! Active flag
        LOGICAL :: op_new = .TRUE.                                 ! OP=NEW or OP=MOD
    CONTAINS
        PROCEDURE :: init => cload_init
        PROCEDURE :: set_value => cload_set_value
        PROCEDURE :: get_value_at_time => cload_get_value_at_time
        PROCEDURE :: print_info => cload_print_info
    END TYPE UF_CLoadDef
```

### `CLoadDef_Init_In` (lines 137–145)

```fortran
    TYPE, PUBLIC :: CLoadDef_Init_In
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        CHARACTER(LEN=MAX_LOADBC_NAME) :: nset_name = ""
        INTEGER(i4) :: node_id = 0
        INTEGER(i4) :: dof = 1
        REAL(wp) :: magnitude = 0.0_wp
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
        LOGICAL :: follower = .FALSE.
    END TYPE CLoadDef_Init_In
```

### `CLoadDef_Init_Out` (lines 152–154)

```fortran
    TYPE, PUBLIC :: CLoadDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE CLoadDef_Init_Out
```

### `UF_DLoadDef` (lines 161–177)

```fortran
    TYPE, PUBLIC :: UF_DLoadDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""               ! Load name
        CHARACTER(LEN=MAX_LOADBC_NAME) :: surface_name = ""       ! Surface name
        INTEGER(i4) :: load_type = LOAD_PRESSURE                 ! Load type
        INTEGER(i4) :: distribution = DIST_UNIFORM                ! Distribution type
        REAL(wp) :: magnitude = 0.0_wp                           ! Load magnitude
        REAL(wp) :: direction(3) = [0.0_wp, 0.0_wp, 0.0_wp]     ! Direction vector
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""     ! Amplitude name
        LOGICAL :: is_active = .TRUE.                             ! Active flag
        LOGICAL :: op_new = .TRUE.                                ! OP=NEW or OP=MOD
    CONTAINS
        PROCEDURE :: init => dload_init
        PROCEDURE :: set_pressure => dload_set_pressure
        PROCEDURE :: set_traction => dload_set_traction
        PROCEDURE :: get_value_at_time => dload_get_value_at_time
        PROCEDURE :: print_info => dload_print_info
    END TYPE UF_DLoadDef
```

### `DLoadDef_Init_In` (lines 184–192)

```fortran
    TYPE, PUBLIC :: DLoadDef_Init_In
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        CHARACTER(LEN=MAX_LOADBC_NAME) :: surface_name = ""
        INTEGER(i4) :: load_type = LOAD_PRESSURE
        INTEGER(i4) :: distribution = DIST_UNIFORM
        REAL(wp) :: magnitude = 0.0_wp
        REAL(wp) :: direction(3) = [0.0_wp, 0.0_wp, 0.0_wp]
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
    END TYPE DLoadDef_Init_In
```

### `DLoadDef_Init_Out` (lines 199–201)

```fortran
    TYPE, PUBLIC :: DLoadDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE DLoadDef_Init_Out
```

### `UF_BodyForceDef` (lines 208–223)

```fortran
    TYPE, PUBLIC :: UF_BodyForceDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""               ! Load name
        CHARACTER(LEN=MAX_LOADBC_NAME) :: elset_name = ""         ! Element set name
        INTEGER(i4) :: load_type = LOAD_BODYFORCE                 ! Load type
        REAL(wp) :: components(3) = [0.0_wp, 0.0_wp, 0.0_wp]     ! Force components
        REAL(wp) :: omega = 0.0_wp                                ! Angular velocity
        REAL(wp) :: axis(3) = [0.0_wp, 0.0_wp, 1.0_wp]          ! Rotation axis
        REAL(wp) :: center(3) = [0.0_wp, 0.0_wp, 0.0_wp]        ! Center c
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""     ! Amplitude name
        LOGICAL :: is_active = .TRUE.                             ! Active flag
    CONTAINS
        PROCEDURE :: init => bforce_init
        PROCEDURE :: set_gravity => bforce_set_gravity
        PROCEDURE :: set_centrifugal => bforce_set_centrifugal
        PROCEDURE :: print_info => bforce_print_info
    END TYPE UF_BodyForceDef
```

### `BodyForceDef_Init_In` (lines 230–239)

```fortran
    TYPE, PUBLIC :: BodyForceDef_Init_In
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        CHARACTER(LEN=MAX_LOADBC_NAME) :: elset_name = ""
        INTEGER(i4) :: load_type = LOAD_BODYFORCE
        REAL(wp) :: components(3) = [0.0_wp, 0.0_wp, 0.0_wp]
        REAL(wp) :: omega = 0.0_wp
        REAL(wp) :: axis(3) = [0.0_wp, 0.0_wp, 1.0_wp]
        REAL(wp) :: center(3) = [0.0_wp, 0.0_wp, 0.0_wp]
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
    END TYPE BodyForceDef_Init_In
```

### `BodyForceDef_Init_Out` (lines 246–248)

```fortran
    TYPE, PUBLIC :: BodyForceDef_Init_Out
        TYPE(ErrorStatusType) :: status
    END TYPE BodyForceDef_Init_Out
```

### `UF_ThermalLoadDef` (lines 255–272)

```fortran
    TYPE, PUBLIC :: UF_ThermalLoadDef
        CHARACTER(LEN=MAX_LOADBC_NAME) :: name = ""
        CHARACTER(LEN=MAX_LOADBC_NAME) :: surface_name = ""
        INTEGER(i4) :: load_type = LOAD_SFILM
        REAL(wp) :: film_coeff = 0.0_wp         ! Convection coefficient

        REAL(wp) :: sink_temp = 0.0_wp          ! Sink temperature
        REAL(wp) :: emissivity = 0.0_wp         ! Radiation emissivity
        REAL(wp) :: flux_magnitude = 0.0_wp     ! Heat flux
        CHARACTER(LEN=MAX_LOADBC_NAME) :: amplitude_name = ""
        LOGICAL :: is_active = .TRUE.
    CONTAINS
        PROCEDURE :: init => thermal_init
        PROCEDURE :: set_convection => thermal_set_convection
        PROCEDURE :: set_radiation => thermal_set_radiation
        PROCEDURE :: set_flux => thermal_set_flux
        PROCEDURE :: print_info => thermal_print_info
    END TYPE UF_ThermalLoadDef
```

### `UF_LoadBCManager` (lines 279–303)

```fortran
    TYPE, PUBLIC :: UF_LoadBCManager
        INTEGER(i4) :: num_bcs = 0
        INTEGER(i4) :: num_cloads = 0
        INTEGER(i4) :: num_dloads = 0
        INTEGER(i4) :: num_bforces = 0
        INTEGER(i4) :: num_thermal = 0
        TYPE(UF_BCDef), ALLOCATABLE :: bcs(:)
        TYPE(UF_CLoadDef), ALLOCATABLE :: cloads(:)
        TYPE(UF_DLoadDef), ALLOCATABLE :: dloads(:)
        TYPE(UF_BodyForceDef), ALLOCATABLE :: bforces(:)
        TYPE(UF_ThermalLoadDef), ALLOCATABLE :: thermals(:)
    CONTAINS
        PROCEDURE :: init => manager_init
        PROCEDURE :: add_bc => manager_add_bc
        PROCEDURE :: add_bc_simple => manager_add_bc_simple
        PROCEDURE :: add_cload => manager_add_cload
        PROCEDURE :: add_dload => manager_add_dload
        PROCEDURE :: add_bforce => manager_add_bforce
        PROCEDURE :: add_thermal => manager_add_thermal
        PROCEDURE :: get_bc => manager_get_bc
        PROCEDURE :: get_cload => manager_get_cload
        PROCEDURE :: deactivate_all => manager_deactivate_all
        PROCEDURE :: print_summary => manager_print_summary
        PROCEDURE :: destroy => manager_destroy
    END TYPE UF_LoadBCManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `bc_init` | 310 | `SUBROUTINE bc_init(this)` |
| SUBROUTINE | `bc_set_displacement` | 321 | `SUBROUTINE bc_set_displacement(this, name, nset, dof1, dof2, value)` |
| SUBROUTINE | `bc_set_fixed` | 335 | `SUBROUTINE bc_set_fixed(this, name, nset, bc_type)` |
| SUBROUTINE | `bc_set_symmetry` | 357 | `SUBROUTINE bc_set_symmetry(this, name, nset, bc_type)` |
| FUNCTION | `bc_get_value_at_time` | 367 | `FUNCTION bc_get_value_at_time(this, time, amp_value) RESULT(val)` |
| SUBROUTINE | `bc_print_info` | 374 | `SUBROUTINE bc_print_info(this, unit_num)` |
| SUBROUTINE | `cload_init` | 393 | `SUBROUTINE cload_init(this)` |
| SUBROUTINE | `cload_set_value` | 417 | `SUBROUTINE cload_set_value(this, name, nset, dof, value, follower)` |
| FUNCTION | `cload_get_value_at_time` | 442 | `FUNCTION cload_get_value_at_time(this, amp_value) RESULT(val)` |
| SUBROUTINE | `cload_print_info` | 449 | `SUBROUTINE cload_print_info(this, unit_num)` |
| SUBROUTINE | `dload_init` | 466 | `SUBROUTINE dload_init(this)` |
| SUBROUTINE | `dload_set_pressure` | 486 | `SUBROUTINE dload_set_pressure(this, name, surface, value)` |
| SUBROUTINE | `dload_set_traction` | 511 | `SUBROUTINE dload_set_traction(this, name, surface, tx, ty, tz)` |
| FUNCTION | `dload_get_value_at_time` | 533 | `FUNCTION dload_get_value_at_time(this, amp_value) RESULT(val)` |
| SUBROUTINE | `dload_print_info` | 540 | `SUBROUTINE dload_print_info(this, unit_num)` |
| SUBROUTINE | `bforce_init` | 557 | `SUBROUTINE bforce_init(this)` |
| SUBROUTINE | `bforce_set_gravity` | 580 | `SUBROUTINE bforce_set_gravity(this, name, elset, gx, gy, gz)` |
| SUBROUTINE | `bforce_set_centrifugal` | 615 | `SUBROUTINE bforce_set_centrifugal(this, name, elset, omega, ax, ay, az, cx, cy, cz)` |
| SUBROUTINE | `bforce_print_info` | 627 | `SUBROUTINE bforce_print_info(this, unit_num)` |
| SUBROUTINE | `thermal_init` | 644 | `SUBROUTINE thermal_init(this)` |
| SUBROUTINE | `thermal_set_convection` | 668 | `SUBROUTINE thermal_set_convection(this, name, surface, h, sink_T)` |
| SUBROUTINE | `thermal_set_radiation` | 695 | `SUBROUTINE thermal_set_radiation(this, name, surface, eps, sink_T)` |
| SUBROUTINE | `thermal_set_flux` | 717 | `SUBROUTINE thermal_set_flux(this, name, surface, flux)` |
| SUBROUTINE | `thermal_print_info` | 727 | `SUBROUTINE thermal_print_info(this, unit_num)` |
| SUBROUTINE | `manager_init` | 749 | `SUBROUTINE manager_init(this, max_bc, max_load)` |
| SUBROUTINE | `manager_add_bc` | 769 | `SUBROUTINE manager_add_bc(this, bc)` |
| SUBROUTINE | `manager_add_bc_simple` | 777 | `SUBROUTINE manager_add_bc_simple(this, name, nset, bc_type, dof1, dof2, value, amp_name)` |
| SUBROUTINE | `manager_add_cload` | 798 | `SUBROUTINE manager_add_cload(this, load)` |
| SUBROUTINE | `manager_add_dload` | 806 | `SUBROUTINE manager_add_dload(this, load)` |
| SUBROUTINE | `manager_add_bforce` | 814 | `SUBROUTINE manager_add_bforce(this, load)` |
| SUBROUTINE | `manager_add_thermal` | 822 | `SUBROUTINE manager_add_thermal(this, load)` |
| FUNCTION | `manager_get_bc` | 830 | `FUNCTION manager_get_bc(this, name) RESULT(ptr)` |
| FUNCTION | `manager_get_cload` | 844 | `FUNCTION manager_get_cload(this, name) RESULT(ptr)` |
| SUBROUTINE | `manager_deactivate_all` | 858 | `SUBROUTINE manager_deactivate_all(this)` |
| SUBROUTINE | `manager_print_summary` | 872 | `SUBROUTINE manager_print_summary(this, unit_num)` |
| SUBROUTINE | `manager_destroy` | 883 | `SUBROUTINE manager_destroy(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
