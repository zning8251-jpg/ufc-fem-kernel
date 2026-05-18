# `MD_Mat_Damage_Def.f90`

- **Source**: `L3_MD/Material/Damage/MD_Mat_Damage_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Damage_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Damage_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Damage`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Damage`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Damage/MD_Mat_Damage_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Damage_Cfg_Init_Desc` (lines 40–46)

```fortran
  TYPE, PUBLIC :: MD_Mat_Damage_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Level 1: Main family (DAMAGE)
    INTEGER(i4) :: sub_type         = 0_i4   ! Level 2: Variant (DUCTILE/SHEAR/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Level 3: Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! DEPENDENCIES parameter (0=none, 1=temp, 2=field)
  END TYPE MD_Mat_Damage_Cfg_Init_Desc
```

### `MD_Mat_Damage_Pop_Vld_Desc` (lines 49–51)

```fortran
  TYPE, PUBLIC :: MD_Mat_Damage_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Damage_Pop_Vld_Desc
```

### `MD_Mat_Damage_Stp_Evo_Ctx` (lines 54–59)

```fortran
  TYPE, PUBLIC :: MD_Mat_Damage_Stp_Evo_Ctx
    REAL(wp)   :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp)   :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id      = 0_i4        ! Integration point number
    INTEGER(i4) :: elem_id    = 0_i4        ! Element ID
  END TYPE MD_Mat_Damage_Stp_Evo_Ctx
```

### `MD_Mat_Damage_State` (lines 93–101)

```fortran
  TYPE, PUBLIC :: MD_Mat_Damage_State
    REAL(wp) :: damage_variable     = 0.0_wp  ! Current damage D in [0, Dc]
    REAL(wp) :: energy_release_rate = 0.0_wp  ! Elastic energy release rate Y
    LOGICAL  :: is_fully_damaged    = .FALSE. ! Element deletion flag
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Damage_State
```

### `MD_Mat_Damage_Algo` (lines 107–116)

```fortran
  TYPE, PUBLIC :: MD_Mat_Damage_Algo
    INTEGER(i4) :: integration_method    = 1_i4   ! Integration method (1=Explicit, 2=Implicit)
    REAL(wp)    :: softening_law         = 1.0_wp ! Softening law type (1=linear, 2=exponential, etc.)
    REAL(wp)    :: damage_threshold      = 0.0_wp ! Damage threshold parameter
    REAL(wp)    :: tolerance             = 1.0e-5_wp ! Integration tolerance
    LOGICAL     :: use_numerical_tangent = .FALSE.   ! Use numerical tangent
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
  END TYPE MD_Mat_Damage_Algo
```

### `MD_Mat_Damage_Ctx` (lines 122–130)

```fortran
  TYPE, PUBLIC :: MD_Mat_Damage_Ctx
    TYPE(MD_Mat_Damage_Stp_Evo_Ctx) :: stp  ! Step-level context
    REAL(wp)   :: time           = 0.0_wp   ! Current total time
    REAL(wp)   :: dt             = 0.0_wp   ! Time increment
    INTEGER(i4) :: increment_num = 0_i4     ! Increment number
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Damage_Ctx
```

### `MD_Mat_Damage_Reg_Arg` (lines 350–363)

```fortran
  TYPE, PUBLIC :: MD_Mat_Damage_Reg_Arg
    ! [IN] properties
    INTEGER(i4) :: sub_type         ! [IN]  sub-type ID
    INTEGER(i4) :: nprops           ! [IN]  number of properties
    REAL(wp)    :: E                ! [IN]  Young's modulus
    REAL(wp)    :: nu               ! [IN]  Poisson ratio
    REAL(wp), ALLOCATABLE :: props(:) ! [IN]  material properties array
    INTEGER(i4) :: dependencies     ! [IN]  temp/field dependencies

    ! [OUT] results
    INTEGER(i4) :: mat_id           ! [OUT] assigned material ID
    INTEGER(i4) :: status_code      ! [OUT] exit status
    CHARACTER(len=256) :: message   ! [OUT] status message
  END TYPE MD_Mat_Damage_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 168 | `SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)` |
| SUBROUTINE | `Desc_Validate` | 210 | `SUBROUTINE Desc_Validate(this, status)` |
| SUBROUTINE | `Desc_ComputeDerived` | 258 | `SUBROUTINE Desc_ComputeDerived(this, status)` |
| SUBROUTINE | `Desc_Clean` | 282 | `SUBROUTINE Desc_Clean(this)` |
| SUBROUTINE | `State_Init` | 292 | `SUBROUTINE State_Init(this)` |
| SUBROUTINE | `State_Update` | 299 | `SUBROUTINE State_Update(this, damage, energy, fully_damaged)` |
| SUBROUTINE | `State_Clean` | 309 | `SUBROUTINE State_Clean(this)` |
| SUBROUTINE | `Algo_Init` | 320 | `SUBROUTINE Algo_Init(this, softening_law)` |
| SUBROUTINE | `Ctx_Init` | 339 | `SUBROUTINE Ctx_Init(this)` |
| SUBROUTINE | `Ctx_Clean` | 343 | `SUBROUTINE Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
