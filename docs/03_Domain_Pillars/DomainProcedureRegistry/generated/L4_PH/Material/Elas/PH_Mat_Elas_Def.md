# `PH_Mat_Elas_Def.f90`

- **Source**: `L4_PH/Material/Elas/PH_Mat_Elas_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Elas_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Elas_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Elas`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Elas`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Elas/PH_Mat_Elas_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Elas_Cfg_Init_Desc` (lines 40–47)

```fortran
  TYPE, PUBLIC :: PH_Mat_Elas_Cfg_Init_Desc
    INTEGER(i4) :: family_type    = 0_i4   ! Material family (ELASTIC)
    INTEGER(i4) :: sub_type       = 0_i4   ! Elastic variant (ISO/ORTHO/etc.)
    INTEGER(i4) :: num_constants  = 0_i4   ! Number of material constants
    INTEGER(i4) :: dependencies   = 0_i4   ! Temperature/field dependencies
    INTEGER(i4) :: property_flags = 0_i4   ! Additional property flags
    REAL(wp)    :: density        = 0.0_wp ! Material density
  END TYPE PH_Mat_Elas_Cfg_Init_Desc
```

### `PH_Mat_Elas_Pop_Vld_Desc` (lines 50–52)

```fortran
  TYPE, PUBLIC :: PH_Mat_Elas_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Elas_Pop_Vld_Desc
```

### `PH_Mat_Elas_Inc_Evo_Ctx` (lines 55–59)

```fortran
  TYPE, PUBLIC :: PH_Mat_Elas_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp       ! Current temperature
    REAL(wp) :: field_var   = 0.0_wp       ! Field variable
    REAL(wp) :: strain_inc(6) = 0.0_wp    ! Strain increment
  END TYPE PH_Mat_Elas_Inc_Evo_Ctx
```

### `PH_Mat_Elas_Desc` (lines 64–97)

```fortran
  TYPE, PUBLIC :: PH_Mat_Elas_Desc
    !--- Auxiliary nesting: cfg (config+init), pop (populate+validate) ---
    TYPE(PH_Mat_Elas_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Elas_Pop_Vld_Desc)  :: pop

    ! Material properties array (populated from L3_MD)
    REAL(wp), ALLOCATABLE :: props(:)

    ! Derived isotropic constants (fast access)
    REAL(wp) :: E        = 0.0_wp   ! Young's modulus
    REAL(wp) :: nu       = 0.0_wp   ! Poisson's ratio
    REAL(wp) :: G        = 0.0_wp   ! Shear modulus
    REAL(wp) :: K        = 0.0_wp   ! Bulk modulus
    REAL(wp) :: lambda   = 0.0_wp   ! Lame first parameter
    REAL(wp) :: mu       = 0.0_wp   ! Lame second parameter

    ! Derived orthotropic constants
    REAL(wp) :: E11 = 0.0_wp, E22 = 0.0_wp, E33 = 0.0_wp
    REAL(wp) :: nu12 = 0.0_wp, nu13 = 0.0_wp, nu23 = 0.0_wp
    REAL(wp) :: G12 = 0.0_wp, G13 = 0.0_wp, G23 = 0.0_wp

    ! Anisotropic stiffness matrix (Voigt notation)
    REAL(wp) :: C(6,6) = 0.0_wp

    ! Material density
    REAL(wp) :: density = 0.0_wp

  CONTAINS
    !--- TBP short names (no context prefix) ---
    PROCEDURE :: Init   => Desc_Init
    PROCEDURE :: Valid  => Desc_Valid
    PROCEDURE :: Copy   => Desc_Copy
    PROCEDURE :: Clean  => Desc_Clean
  END TYPE PH_Mat_Elas_Desc
```

### `PH_Mat_Elas_State` (lines 102–112)

```fortran
  TYPE, PUBLIC :: PH_Mat_Elas_State
    REAL(wp) :: stress(6)         = 0.0_wp   ! Current stress (Voigt)
    REAL(wp) :: strain(6)         = 0.0_wp   ! Current total strain
    REAL(wp) :: elastic_strain(6) = 0.0_wp   ! Elastic strain (= total for pure elastic)
    LOGICAL  :: initialized       = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => State_Init
    PROCEDURE :: Update   => State_Update
    PROCEDURE :: Clean    => State_Clean
    PROCEDURE :: Reset    => State_Reset
  END TYPE PH_Mat_Elas_State
```

### `PH_Mat_Elas_Algo` (lines 117–124)

```fortran
  TYPE, PUBLIC :: PH_Mat_Elas_Algo
    INTEGER(i4) :: tangent_type            = 1_i4       ! 1=consistent, 2=continuum
    LOGICAL     :: use_numerical_tangent   = .FALSE.
    REAL(wp)    :: numerical_perturbation  = 1.0e-8_wp
  CONTAINS
    PROCEDURE :: Init   => Algo_Init
    PROCEDURE :: Config => Algo_Config
  END TYPE PH_Mat_Elas_Algo
```

### `PH_Mat_Elas_Ctx` (lines 129–144)

```fortran
  TYPE, PUBLIC :: PH_Mat_Elas_Ctx
    !--- Auxiliary nesting ---
    TYPE(PH_Mat_Elas_Inc_Evo_Ctx) :: inc   ! Increment-level context

    ! Cached stiffness matrix (hot path optimization)
    REAL(wp) :: D_el(6,6)        = 0.0_wp
    LOGICAL  :: D_el_cached      = .FALSE.

    ! Integration point identification
    INTEGER(i4) :: ip_id    = 0_i4
    INTEGER(i4) :: elem_id  = 0_i4
  CONTAINS
    PROCEDURE :: Init      => Ctx_Init
    PROCEDURE :: CacheStif => Ctx_CacheStif
    PROCEDURE :: Clean     => Ctx_Clean
  END TYPE PH_Mat_Elas_Ctx
```

### `PH_Mat_Elas_Eval_Arg` (lines 151–169)

```fortran
  TYPE, PUBLIC :: PH_Mat_Elas_Eval_Arg
    !--- [IN] fields ---
    REAL(wp) :: strain(6)              ! [IN]  current total strain
    REAL(wp) :: dstrain(6)             ! [IN]  strain increment
    REAL(wp) :: temperature            ! [IN]  current temperature
    REAL(wp) :: dtemp                  ! [IN]  temperature increment
    REAL(wp) :: field_var              ! [IN]  field variable

    !--- [OUT] fields ---
    REAL(wp) :: stress(6)              ! [OUT] updated Cauchy stress
    REAL(wp) :: ddsdde(6,6)            ! [OUT] tangent stiffness matrix

    !--- [INOUT] fields ---
    REAL(wp), ALLOCATABLE :: statev(:) ! [INOUT] state variables

    !--- [OUT] status ---
    INTEGER(i4)           :: status_code ! [OUT] exit status
    CHARACTER(len=256)    :: message     ! [OUT] status message
  END TYPE PH_Mat_Elas_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 186 | `SUBROUTINE Desc_Init(this, sub_type, nprops, props, status)` |
| SUBROUTINE | `Desc_Valid` | 206 | `SUBROUTINE Desc_Valid(this, status)` |
| SUBROUTINE | `Desc_Copy` | 219 | `SUBROUTINE Desc_Copy(this, other, status)` |
| SUBROUTINE | `Desc_Clean` | 235 | `SUBROUTINE Desc_Clean(this)` |
| SUBROUTINE | `State_Init` | 245 | `SUBROUTINE State_Init(this)` |
| SUBROUTINE | `State_Update` | 253 | `SUBROUTINE State_Update(this, stress, strain)` |
| SUBROUTINE | `State_Clean` | 262 | `SUBROUTINE State_Clean(this)` |
| SUBROUTINE | `State_Reset` | 270 | `SUBROUTINE State_Reset(this)` |
| SUBROUTINE | `Algo_Init` | 280 | `SUBROUTINE Algo_Init(this)` |
| SUBROUTINE | `Algo_Config` | 287 | `SUBROUTINE Algo_Config(this, tangent_type, use_num_tangent)` |
| SUBROUTINE | `Ctx_Init` | 299 | `SUBROUTINE Ctx_Init(this)` |
| SUBROUTINE | `Ctx_CacheStif` | 307 | `SUBROUTINE Ctx_CacheStif(this, D_el)` |
| SUBROUTINE | `Ctx_Clean` | 314 | `SUBROUTINE Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
