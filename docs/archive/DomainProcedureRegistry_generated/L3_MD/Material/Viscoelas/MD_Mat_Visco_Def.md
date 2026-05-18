# `MD_Mat_Visco_Def.f90`

- **Source**: `L3_MD/Material/Viscoelas/MD_Mat_Visco_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Visco_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Visco_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Visco`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Viscoelas`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Viscoelas/MD_Mat_Visco_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Visco_Cfg_Init_Desc` (lines 44–51)

```fortran
  TYPE, PUBLIC :: MD_Mat_Visco_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Main family (VISCOELASTIC)
    INTEGER(i4) :: sub_type         = 0_i4   ! Variant (PRONY_DEV/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! Temp/field dependencies
    INTEGER(i4) :: n_prony_terms    = 0_i4   ! Number of Prony series terms
  END TYPE MD_Mat_Visco_Cfg_Init_Desc
```

### `MD_Mat_Visco_Pop_Vld_Desc` (lines 54–56)

```fortran
  TYPE, PUBLIC :: MD_Mat_Visco_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Visco_Pop_Vld_Desc
```

### `MD_Mat_Visco_Stp_Evo_Ctx` (lines 59–66)

```fortran
  TYPE, PUBLIC :: MD_Mat_Visco_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp) :: field_var   = 0.0_wp      ! Field variable
    REAL(wp) :: time        = 0.0_wp      ! Current total time
    INTEGER(i4) :: ip_id     = 0_i4       ! Integration point number
    INTEGER(i4) :: elem_id   = 0_i4       ! Element ID
    INTEGER(i4) :: inc_num   = 0_i4       ! Increment number
  END TYPE MD_Mat_Visco_Stp_Evo_Ctx
```

### `MD_Mat_Visco_State` (lines 98–107)

```fortran
  TYPE, PUBLIC :: MD_Mat_Visco_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp), ALLOCATABLE :: s_k_6(:)        ! Viscoelastic stress deviator history
    REAL(wp), ALLOCATABLE :: internal_vars(:,:) ! History variables per term
    LOGICAL  :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init   => MD_Mat_Visco_State_Init
    PROCEDURE :: Update => MD_Mat_Visco_State_Update
    PROCEDURE :: Clean  => MD_Mat_Visco_State_Clean
  END TYPE MD_Mat_Visco_State
```

### `MD_Mat_Visco_Algo` (lines 113–120)

```fortran
  TYPE, PUBLIC :: MD_Mat_Visco_Algo
    INTEGER(i4) :: integration_method = 1_i4  ! Integration method (1=Explicit, 2=Implicit)
    REAL(wp)    :: tolerance          = 1.0e-5_wp ! Integration tolerance
    LOGICAL     :: use_numerical_tangent = .FALSE.  ! Use numerical tangent
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => MD_Mat_Visco_Algo_Init
  END TYPE MD_Mat_Visco_Algo
```

### `MD_Mat_Visco_Ctx` (lines 126–135)

```fortran
  TYPE, PUBLIC :: MD_Mat_Visco_Ctx
    TYPE(MD_Mat_Visco_Stp_Evo_Ctx) :: stp  ! Step-level context
    REAL(wp) :: relaxation_modulus = 0.0_wp
    REAL(wp) :: dt = 0.0_wp                ! Time increment
    INTEGER(i4) :: integration_point = 0   ! Integration point number
    INTEGER(i4) :: element_id = 0          ! Element ID
  CONTAINS
    PROCEDURE :: Init  => MD_Mat_Visco_Ctx_Init
    PROCEDURE :: Clean => MD_Mat_Visco_Ctx_Clean
  END TYPE MD_Mat_Visco_Ctx
```

### `MD_Mat_Visco_Reg_Arg` (lines 316–329)

```fortran
  TYPE, PUBLIC :: MD_Mat_Visco_Reg_Arg
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
  END TYPE MD_Mat_Visco_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mat_Visco_Desc_Init` | 151 | `SUBROUTINE MD_Mat_Visco_Desc_Init(this, sub_type, num_constants, dependencies, status)` |
| SUBROUTINE | `MD_Mat_Visco_Desc_Valid` | 189 | `SUBROUTINE MD_Mat_Visco_Desc_Valid(this, status)` |
| SUBROUTINE | `MD_Mat_Visco_Desc_ComputeDerived` | 213 | `SUBROUTINE MD_Mat_Visco_Desc_ComputeDerived(this, status)` |
| SUBROUTINE | `MD_Mat_Visco_Desc_Clean` | 237 | `SUBROUTINE MD_Mat_Visco_Desc_Clean(this)` |
| SUBROUTINE | `MD_Mat_Visco_State_Init` | 252 | `SUBROUTINE MD_Mat_Visco_State_Init(this, n_terms)` |
| SUBROUTINE | `MD_Mat_Visco_State_Update` | 271 | `SUBROUTINE MD_Mat_Visco_State_Update(this, stress, strain)` |
| SUBROUTINE | `MD_Mat_Visco_State_Clean` | 280 | `SUBROUTINE MD_Mat_Visco_State_Clean(this)` |
| SUBROUTINE | `MD_Mat_Visco_Algo_Init` | 294 | `SUBROUTINE MD_Mat_Visco_Algo_Init(this)` |
| SUBROUTINE | `MD_Mat_Visco_Ctx_Init` | 305 | `SUBROUTINE MD_Mat_Visco_Ctx_Init(this)` |
| SUBROUTINE | `MD_Mat_Visco_Ctx_Clean` | 309 | `SUBROUTINE MD_Mat_Visco_Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
