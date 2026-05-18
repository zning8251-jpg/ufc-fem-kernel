# `MD_Mat_Comp_Def.f90`

- **Source**: `L3_MD/Material/Composite/MD_Mat_Comp_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Comp_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Comp_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Comp`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Composite`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Composite/MD_Mat_Comp_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Comp_Cfg_Init_Desc` (lines 37–43)

```fortran
  TYPE, PUBLIC :: MD_Mat_Comp_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Main family (COMPOSITE)
    INTEGER(i4) :: sub_type         = 0_i4   ! Variant (CLT/HASHIN/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! Temp/field dependencies
  END TYPE MD_Mat_Comp_Cfg_Init_Desc
```

### `MD_Mat_Comp_Pop_Vld_Desc` (lines 46–48)

```fortran
  TYPE, PUBLIC :: MD_Mat_Comp_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Comp_Pop_Vld_Desc
```

### `MD_Mat_Comp_Stp_Evo_Ctx` (lines 51–56)

```fortran
  TYPE, PUBLIC :: MD_Mat_Comp_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp) :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id     = 0_i4       ! Integration point number
    INTEGER(i4) :: elem_id   = 0_i4       ! Element ID
  END TYPE MD_Mat_Comp_Stp_Evo_Ctx
```

### `MD_Mat_Comp_State` (lines 83–93)

```fortran
  TYPE, PUBLIC :: MD_Mat_Comp_State
    REAL(wp) :: fiber_damage_1  = 0.0_wp
    REAL(wp) :: fiber_damage_2  = 0.0_wp
    REAL(wp) :: matrix_damage_1 = 0.0_wp
    REAL(wp) :: matrix_damage_2 = 0.0_wp
    REAL(wp) :: shear_damage    = 0.0_wp
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Comp_State
```

### `MD_Mat_Comp_Algo` (lines 98–102)

```fortran
  TYPE, PUBLIC :: MD_Mat_Comp_Algo
    INTEGER(i4) :: integration_method = 1_i4
  CONTAINS
    PROCEDURE :: Init => Algo_Init
  END TYPE MD_Mat_Comp_Algo
```

### `MD_Mat_Comp_Ctx` (lines 107–112)

```fortran
  TYPE, PUBLIC :: MD_Mat_Comp_Ctx
    TYPE(MD_Mat_Comp_Stp_Evo_Ctx) :: stp  ! Step-level context
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Comp_Ctx
```

### `MD_Mat_Comp_Reg_Arg` (lines 249–262)

```fortran
  TYPE, PUBLIC :: MD_Mat_Comp_Reg_Arg
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
  END TYPE MD_Mat_Comp_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 120 | `SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)` |
| SUBROUTINE | `Desc_Valid` | 157 | `SUBROUTINE Desc_Valid(this, status)` |
| SUBROUTINE | `Desc_ComputeDerived` | 175 | `SUBROUTINE Desc_ComputeDerived(this, status)` |
| SUBROUTINE | `Desc_Clean` | 183 | `SUBROUTINE Desc_Clean(this)` |
| SUBROUTINE | `State_Init` | 194 | `SUBROUTINE State_Init(this)` |
| SUBROUTINE | `State_Update` | 203 | `SUBROUTINE State_Update(this, fiber_d1, fiber_d2, matrix_d1, matrix_d2, shear_d)` |
| SUBROUTINE | `State_Clean` | 216 | `SUBROUTINE State_Clean(this)` |
| SUBROUTINE | `Algo_Init` | 229 | `SUBROUTINE Algo_Init(this)` |
| SUBROUTINE | `Ctx_Init` | 238 | `SUBROUTINE Ctx_Init(this)` |
| SUBROUTINE | `Ctx_Clean` | 242 | `SUBROUTINE Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
