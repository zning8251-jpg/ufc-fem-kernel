# `MD_Mat_Creep_Def.f90`

- **Source**: `L3_MD/Material/Creep/MD_Mat_Creep_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Creep_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Creep_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Creep`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Creep`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Creep/MD_Mat_Creep_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Creep_Cfg_Init_Desc` (lines 43–49)

```fortran
  TYPE, PUBLIC :: MD_Mat_Creep_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Level 1: Main family (CREEP)
    INTEGER(i4) :: sub_type         = 0_i4   ! Level 2: Variant (POWER/GAROFALO/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Level 3: Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! DEPENDENCIES parameter (0=none, 1=temp, 2=field)
  END TYPE MD_Mat_Creep_Cfg_Init_Desc
```

### `MD_Mat_Creep_Pop_Vld_Desc` (lines 52–54)

```fortran
  TYPE, PUBLIC :: MD_Mat_Creep_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Creep_Pop_Vld_Desc
```

### `MD_Mat_Creep_Stp_Evo_Ctx` (lines 57–62)

```fortran
  TYPE, PUBLIC :: MD_Mat_Creep_Stp_Evo_Ctx
    REAL(wp)   :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp)   :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id      = 0_i4        ! Integration point number
    INTEGER(i4) :: elem_id    = 0_i4        ! Element ID
  END TYPE MD_Mat_Creep_Stp_Evo_Ctx
```

### `MD_Mat_Creep_State` (lines 98–106)

```fortran
  TYPE, PUBLIC :: MD_Mat_Creep_State
    REAL(wp) :: creep_strain(6)       = 0.0_wp  ! Creep strain tensor (Voigt)
    REAL(wp) :: equiv_creep_strain    = 0.0_wp  ! Equivalent creep strain
    REAL(wp) :: creep_strain_rate     = 0.0_wp  ! Current equivalent creep strain rate
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Creep_State
```

### `MD_Mat_Creep_Algo` (lines 112–119)

```fortran
  TYPE, PUBLIC :: MD_Mat_Creep_Algo
    INTEGER(i4) :: integration_method    = 1_i4   ! Integration method (1=Explicit, 2=Implicit)
    REAL(wp)    :: tolerance             = 1.0e-5_wp ! Integration tolerance
    LOGICAL     :: use_numerical_tangent = .FALSE.   ! Use numerical tangent
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
  END TYPE MD_Mat_Creep_Algo
```

### `MD_Mat_Creep_Ctx` (lines 125–133)

```fortran
  TYPE, PUBLIC :: MD_Mat_Creep_Ctx
    TYPE(MD_Mat_Creep_Stp_Evo_Ctx) :: stp  ! Step-level context
    REAL(wp)   :: time           = 0.0_wp   ! Current total time
    REAL(wp)   :: dt             = 0.0_wp   ! Time increment
    INTEGER(i4) :: increment_num = 0_i4     ! Increment number
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Creep_Ctx
```

### `MD_Mat_Creep_Reg_Arg` (lines 345–358)

```fortran
  TYPE, PUBLIC :: MD_Mat_Creep_Reg_Arg
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
  END TYPE MD_Mat_Creep_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 171 | `SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)` |
| SUBROUTINE | `Desc_Validate` | 213 | `SUBROUTINE Desc_Validate(this, status)` |
| SUBROUTINE | `Desc_ComputeDerived` | 261 | `SUBROUTINE Desc_ComputeDerived(this, status)` |
| SUBROUTINE | `Desc_Clean` | 285 | `SUBROUTINE Desc_Clean(this)` |
| SUBROUTINE | `State_Init` | 295 | `SUBROUTINE State_Init(this)` |
| SUBROUTINE | `State_Update` | 302 | `SUBROUTINE State_Update(this, creep_strain, equiv_creep_strain, creep_strain_rate)` |
| SUBROUTINE | `State_Clean` | 312 | `SUBROUTINE State_Clean(this)` |
| SUBROUTINE | `Algo_Init` | 323 | `SUBROUTINE Algo_Init(this)` |
| SUBROUTINE | `Ctx_Init` | 334 | `SUBROUTINE Ctx_Init(this)` |
| SUBROUTINE | `Ctx_Clean` | 338 | `SUBROUTINE Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
