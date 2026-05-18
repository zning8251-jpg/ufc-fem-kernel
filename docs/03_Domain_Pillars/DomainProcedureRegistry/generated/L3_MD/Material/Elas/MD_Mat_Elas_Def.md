# `MD_Mat_Elas_Def.f90`

- **Source**: `L3_MD/Material/Elas/MD_Mat_Elas_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Elas_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Elas_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Elas`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Elas`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Elas/MD_Mat_Elas_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Elas_Cfg_Init_Desc` (lines 56–62)

```fortran
  TYPE, PUBLIC :: MD_Mat_Elas_Cfg_Init_Desc
    INTEGER(i4) :: family_type      = 0_i4   ! Main family (ELASTIC)
    INTEGER(i4) :: sub_type         = 0_i4   ! Variant (ISO/ORTHO/etc.)
    INTEGER(i4) :: property_flags   = 0_i4   ! Additional properties (bit flags)
    INTEGER(i4) :: num_constants    = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies     = 0_i4   ! Temp/field dependencies
  END TYPE MD_Mat_Elas_Cfg_Init_Desc
```

### `MD_Mat_Elas_Pop_Vld_Desc` (lines 65–67)

```fortran
  TYPE, PUBLIC :: MD_Mat_Elas_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Elas_Pop_Vld_Desc
```

### `MD_Mat_Elas_Stp_Evo_Ctx` (lines 70–75)

```fortran
  TYPE, PUBLIC :: MD_Mat_Elas_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp   ! Current temperature (K)
    REAL(wp) :: field_var   = 0.0_wp      ! Field variable
    INTEGER(i4) :: ip_id     = 0_i4       ! Integration point number
    INTEGER(i4) :: elem_id   = 0_i4       ! Element ID
  END TYPE MD_Mat_Elas_Stp_Evo_Ctx
```

### `MD_Mat_Elas_State` (lines 116–124)

```fortran
  TYPE, PUBLIC :: MD_Mat_Elas_State
    REAL(wp) :: stress(6)         = 0.0_wp   ! Stress tensor (Voigt)
    REAL(wp) :: strain(6)         = 0.0_wp   ! Strain tensor (Voigt)
    REAL(wp) :: elastic_strain(6) = 0.0_wp   ! Elastic strain
  CONTAINS
    PROCEDURE :: Init   => State_Init
    PROCEDURE :: Update => State_Update
    PROCEDURE :: Clean  => State_Clean
  END TYPE MD_Mat_Elas_State
```

### `MD_Mat_Elas_Algo` (lines 129–137)

```fortran
  TYPE, PUBLIC :: MD_Mat_Elas_Algo
    INTEGER(i4) :: integration_method = 0_i4  ! Integration method
    INTEGER(i4) :: tangent_type       = 0_i4  ! Tangent type
    LOGICAL     :: use_numerical_tangent = .FALSE.
    REAL(wp)    :: numerical_perturbation = 1.0e-8_wp  ! perturbation for numerical tangent
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE MD_Mat_Elas_Algo
```

### `MD_Mat_Elas_Ctx` (lines 142–147)

```fortran
  TYPE, PUBLIC :: MD_Mat_Elas_Ctx
    TYPE(MD_Mat_Elas_Stp_Evo_Ctx) :: stp  ! Step-level context
  CONTAINS
    PROCEDURE :: Init  => Ctx_Init
    PROCEDURE :: Clean => Ctx_Clean
  END TYPE MD_Mat_Elas_Ctx
```

### `MD_Mat_Elas_Reg_Arg` (lines 152–164)

```fortran
  TYPE, PUBLIC :: MD_Mat_Elas_Reg_Arg
    ! [IN] fields
    INTEGER(i4)           :: sub_type       ! [IN]  elastic variant type
    INTEGER(i4)           :: num_constants  ! [IN]  number of constants
    REAL(wp), ALLOCATABLE :: constants(:,:) ! [IN]  material constants table
    INTEGER(i4)           :: dependencies   ! [IN]  temp/field dependencies

    ! [OUT] fields
    INTEGER(i4)           :: mat_id         ! [OUT] assigned material ID
    CHARACTER(len=64)     :: mat_name       ! [OUT] assigned material name
    INTEGER(i4)           :: status_code    ! [OUT] exit status
    CHARACTER(len=256)    :: message        ! [OUT] status message
  END TYPE MD_Mat_Elas_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 183 | `SUBROUTINE Desc_Init(this, sub_type, num_constants, dependencies, status)` |
| SUBROUTINE | `Desc_Valid` | 219 | `SUBROUTINE Desc_Valid(this, status)` |
| SUBROUTINE | `Desc_ComputeDerived` | 238 | `SUBROUTINE Desc_ComputeDerived(this, status)` |
| SUBROUTINE | `Desc_Clean` | 275 | `SUBROUTINE Desc_Clean(this)` |
| SUBROUTINE | `State_Init` | 285 | `SUBROUTINE State_Init(this)` |
| SUBROUTINE | `State_Update` | 292 | `SUBROUTINE State_Update(this, stress, strain)` |
| SUBROUTINE | `State_Clean` | 301 | `SUBROUTINE State_Clean(this)` |
| SUBROUTINE | `Algo_Init` | 312 | `SUBROUTINE Algo_Init(this)` |
| SUBROUTINE | `Algo_Config` | 319 | `SUBROUTINE Algo_Config(this, tangent_type, use_num)` |
| SUBROUTINE | `Ctx_Init` | 331 | `SUBROUTINE Ctx_Init(this)` |
| SUBROUTINE | `Ctx_Clean` | 335 | `SUBROUTINE Ctx_Clean(this)` |
| SUBROUTINE | `Build_Aniso_C` | 343 | `SUBROUTINE Build_Aniso_C(constants, C)` |
| FUNCTION | `MD_Mat_Elas_Get_SubType_Name` | 364 | `FUNCTION MD_Mat_Elas_Get_SubType_Name(sub_type) RESULT(name)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
