# `MD_Mat_Geo_Def.f90`

- **Source**: `L3_MD/Material/Geo/MD_Mat_Geo_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Geo_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Geo_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Geo`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Geo`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Geo/MD_Mat_Geo_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Geo_Cfg_Init_Desc` (lines 33–39)

```fortran
  TYPE, PUBLIC :: MD_Mat_Geo_Cfg_Init_Desc
    INTEGER(i4) :: family_type    = MD_MAT_FAMILY_GEOTECHNICAL
    INTEGER(i4) :: sub_type       = MD_MAT_GEO_SUB_DP_LINEAR
    INTEGER(i4) :: property_flags = MD_MAT_PROP_NONE
    INTEGER(i4) :: num_constants  = 0_i4
    INTEGER(i4) :: dependencies   = 0_i4
  END TYPE MD_Mat_Geo_Cfg_Init_Desc
```

### `MD_Mat_Geo_Pop_Vld_Desc` (lines 45–47)

```fortran
  TYPE, PUBLIC :: MD_Mat_Geo_Pop_Vld_Desc
    LOGICAL :: is_initialized = .FALSE.
  END TYPE MD_Mat_Geo_Pop_Vld_Desc
```

### `MD_Mat_Geo_Stp_Evo_Ctx` (lines 53–55)

```fortran
  TYPE, PUBLIC :: MD_Mat_Geo_Stp_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
  END TYPE MD_Mat_Geo_Stp_Evo_Ctx
```

### `MD_Mat_Geo_State` (lines 81–93)

```fortran
  TYPE, PUBLIC :: MD_Mat_Geo_State
    REAL(wp) :: stress(6) = 0.0_wp
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: plastic_strain(6) = 0.0_wp
    REAL(wp) :: equivalent_plastic_strain = 0.0_wp
    REAL(wp) :: volumetric_plastic_strain = 0.0_wp
    REAL(wp) :: yield_surface_size = 0.0_wp
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => MD_Mat_Geo_State_Init
    PROCEDURE :: Update => MD_Mat_Geo_State_Update
    PROCEDURE :: Clean => MD_Mat_Geo_State_Clean
  END TYPE MD_Mat_Geo_State
```

### `MD_Mat_Geo_Algo` (lines 98–106)

```fortran
  TYPE, PUBLIC :: MD_Mat_Geo_Algo
    INTEGER(i4) :: integration_method = 1
    INTEGER(i4) :: return_mapping = 1     ! 1=closest-point, 2=cutting-plane
    INTEGER(i4) :: max_iter = 50
    REAL(wp) :: tolerance = 1.0e-8_wp
  CONTAINS
    PROCEDURE :: Init => MD_Mat_Geo_Algo_Init
    PROCEDURE :: Config => MD_Mat_Geo_Algo_Config
  END TYPE MD_Mat_Geo_Algo
```

### `MD_Mat_Geo_Ctx` (lines 111–116)

```fortran
  TYPE, PUBLIC :: MD_Mat_Geo_Ctx
    TYPE(MD_Mat_Geo_Stp_Evo_Ctx) :: stp
    REAL(wp) :: field_var = 0.0_wp
  CONTAINS
    PROCEDURE :: Init => MD_Mat_Geo_Ctx_Init
  END TYPE MD_Mat_Geo_Ctx
```

### `MD_Mat_Geo_Reg_Arg` (lines 379–392)

```fortran
  TYPE, PUBLIC :: MD_Mat_Geo_Reg_Arg
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
  END TYPE MD_Mat_Geo_Reg_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mat_Geo_Desc_Init` | 147 | `SUBROUTINE MD_Mat_Geo_Desc_Init(desc, sub_type, num_constants, dependencies, status)` |
| SUBROUTINE | `MD_Mat_Geo_Desc_Validate` | 183 | `SUBROUTINE MD_Mat_Geo_Desc_Validate(desc, status)` |
| SUBROUTINE | `MD_Mat_Geo_Desc_ComputeDerived` | 205 | `SUBROUTINE MD_Mat_Geo_Desc_ComputeDerived(desc, status)` |
| SUBROUTINE | `MD_Mat_Geo_Clean` | 224 | `SUBROUTINE MD_Mat_Geo_Clean(desc, status)` |
| SUBROUTINE | `MD_Mat_Geo_State_Init` | 253 | `SUBROUTINE MD_Mat_Geo_State_Init(state, status)` |
| SUBROUTINE | `MD_Mat_Geo_State_Update` | 275 | `SUBROUTINE MD_Mat_Geo_State_Update(state, stress, strain, eps_pl, &` |
| SUBROUTINE | `MD_Mat_Geo_State_Clean` | 301 | `SUBROUTINE MD_Mat_Geo_State_Clean(state, status)` |
| SUBROUTINE | `MD_Mat_Geo_Algo_Init` | 323 | `SUBROUTINE MD_Mat_Geo_Algo_Init(algo, status)` |
| SUBROUTINE | `MD_Mat_Geo_Algo_Config` | 342 | `SUBROUTINE MD_Mat_Geo_Algo_Config(algo, return_mapping, max_iter, &` |
| SUBROUTINE | `MD_Mat_Geo_Ctx_Init` | 364 | `SUBROUTINE MD_Mat_Geo_Ctx_Init(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
