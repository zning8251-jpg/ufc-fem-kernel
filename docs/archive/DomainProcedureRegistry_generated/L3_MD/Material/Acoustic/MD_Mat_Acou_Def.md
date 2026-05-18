# `MD_Mat_Acou_Def.f90`

- **Source**: `L3_MD/Material/Acoustic/MD_Mat_Acou_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Acou_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Acou_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Acou`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Acoustic/MD_Mat_Acou_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Acou_Cfg_Init_Desc` (lines 34–40)

```fortran
  TYPE, PUBLIC :: MD_Mat_Acou_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Main family (ACOUSTIC)
    INTEGER(i4) :: sub_type         = 0_i4   ! Variant (LINEAR/ABSORB)
    INTEGER(i4) :: property_flags   = 0_i4   ! Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! Temp/field dependencies
  END TYPE MD_Mat_Acou_Cfg_Init_Desc
```

### `MD_Mat_Acou_Pop_Vld_Desc` (lines 43–45)

```fortran
  TYPE, PUBLIC :: MD_Mat_Acou_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Acou_Pop_Vld_Desc
```

### `MD_Mat_Acou_Stp_Evo_Ctx` (lines 48–53)

```fortran
  TYPE, PUBLIC :: MD_Mat_Acou_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp) :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id     = 0_i4       ! Integration point number
    INTEGER(i4) :: elem_id   = 0_i4       ! Element ID
  END TYPE MD_Mat_Acou_Stp_Evo_Ctx
```

### `MD_Mat_Acou_State` (lines 82–88)

```fortran
  TYPE, PUBLIC :: MD_Mat_Acou_State
    REAL(wp) :: acoustic_pressure = 0.0_wp
  CONTAINS
    PROCEDURE :: Init   => MD_Mat_Acou_State_Init
    PROCEDURE :: Update => MD_Mat_Acou_State_Update
    PROCEDURE :: Clean  => MD_Mat_Acou_State_Clean
  END TYPE MD_Mat_Acou_State
```

### `MD_Mat_Acou_Algo` (lines 93–97)

```fortran
  TYPE, PUBLIC :: MD_Mat_Acou_Algo
    INTEGER(i4) :: integration_method = 1_i4
  CONTAINS
    PROCEDURE :: Init => MD_Mat_Acou_Algo_Init
  END TYPE MD_Mat_Acou_Algo
```

### `MD_Mat_Acou_Ctx` (lines 102–107)

```fortran
  TYPE, PUBLIC :: MD_Mat_Acou_Ctx
    TYPE(MD_Mat_Acou_Stp_Evo_Ctx) :: stp  ! Step-level context
  CONTAINS
    PROCEDURE :: Init  => MD_Mat_Acou_Ctx_Init
    PROCEDURE :: Clean => MD_Mat_Acou_Ctx_Clean
  END TYPE MD_Mat_Acou_Ctx
```

### `MD_Mat_Acou_Reg_Arg` (lines 234–247)

```fortran
  TYPE, PUBLIC :: MD_Mat_Acou_Reg_Arg
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
  END TYPE MD_Mat_Acou_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mat_Acou_Desc_Init` | 115 | `SUBROUTINE MD_Mat_Acou_Desc_Init(this, sub_type, num_constants, dependencies, status)` |
| SUBROUTINE | `MD_Mat_Acou_Desc_Valid` | 152 | `SUBROUTINE MD_Mat_Acou_Desc_Valid(this, status)` |
| SUBROUTINE | `MD_Mat_Acou_Desc_ComputeDerived` | 170 | `SUBROUTINE MD_Mat_Acou_Desc_ComputeDerived(this, status)` |
| SUBROUTINE | `MD_Mat_Acou_Desc_Clean` | 181 | `SUBROUTINE MD_Mat_Acou_Desc_Clean(this)` |
| SUBROUTINE | `MD_Mat_Acou_State_Init` | 194 | `SUBROUTINE MD_Mat_Acou_State_Init(this)` |
| SUBROUTINE | `MD_Mat_Acou_State_Update` | 199 | `SUBROUTINE MD_Mat_Acou_State_Update(this, pressure)` |
| SUBROUTINE | `MD_Mat_Acou_State_Clean` | 205 | `SUBROUTINE MD_Mat_Acou_State_Clean(this)` |
| SUBROUTINE | `MD_Mat_Acou_Algo_Init` | 214 | `SUBROUTINE MD_Mat_Acou_Algo_Init(this)` |
| SUBROUTINE | `MD_Mat_Acou_Ctx_Init` | 223 | `SUBROUTINE MD_Mat_Acou_Ctx_Init(this)` |
| SUBROUTINE | `MD_Mat_Acou_Ctx_Clean` | 227 | `SUBROUTINE MD_Mat_Acou_Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
