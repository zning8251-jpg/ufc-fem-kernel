# `PH_Mat_Therm_Def.f90`

- **Source**: `L4_PH/Material/Thermal/PH_Mat_Therm_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Therm_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Therm_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Therm`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Thermal`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Thermal/PH_Mat_Therm_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Therm_Cfg_Init_Desc` (lines 25–28)

```fortran
  TYPE, PUBLIC :: PH_Mat_Therm_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: num_constants = 0
  END TYPE PH_Mat_Therm_Cfg_Init_Desc
```

### `PH_Mat_Therm_Pop_Vld_Desc` (lines 30–32)

```fortran
  TYPE, PUBLIC :: PH_Mat_Therm_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Therm_Pop_Vld_Desc
```

### `PH_Mat_Therm_Inc_Evo_Ctx` (lines 34–37)

```fortran
  TYPE, PUBLIC :: PH_Mat_Therm_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE PH_Mat_Therm_Inc_Evo_Ctx
```

### `PH_Mat_Therm_Desc` (lines 42–54)

```fortran
  TYPE, PUBLIC :: PH_Mat_Therm_Desc
    TYPE(PH_Mat_Therm_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Therm_Pop_Vld_Desc)  :: vld
    REAL(wp) :: kappa = 0.0_wp
    REAL(wp) :: specific_heat = 0.0_wp
    REAL(wp) :: density = 0.0_wp
    REAL(wp) :: alpha(3) = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Therm_Desc_Init
    PROCEDURE, PASS :: Valid => Therm_Desc_Valid
    PROCEDURE, PASS :: Clean => Therm_Desc_Clean
  END TYPE PH_Mat_Therm_Desc
```

### `PH_Mat_Therm_State` (lines 59–69)

```fortran
  TYPE, PUBLIC :: PH_Mat_Therm_State
    REAL(wp) :: temperature = 293.15_wp
    REAL(wp) :: heat_flux(3) = 0.0_wp
    REAL(wp) :: internal_energy = 0.0_wp
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => Therm_State_Init
    PROCEDURE, PASS :: Update => Therm_State_Update
    PROCEDURE, PASS :: Clean  => Therm_State_Clean
  END TYPE PH_Mat_Therm_State
```

### `PH_Mat_Therm_Algo` (lines 74–79)

```fortran
  TYPE, PUBLIC :: PH_Mat_Therm_Algo
    INTEGER(i4) :: time_integration = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => Therm_Algo_Init
  END TYPE PH_Mat_Therm_Algo
```

### `PH_Mat_Therm_Ctx` (lines 84–91)

```fortran
  TYPE, PUBLIC :: PH_Mat_Therm_Ctx
    TYPE(PH_Mat_Therm_Inc_Evo_Ctx) :: inc
    REAL(wp) :: K_th(3,3) = 0.0_wp
    REAL(wp) :: grad_T(3) = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Therm_Ctx_Init
    PROCEDURE, PASS :: Clean => Therm_Ctx_Clean
  END TYPE PH_Mat_Therm_Ctx
```

### `PH_Mat_Therm_Eval_Arg` (lines 96–103)

```fortran
  TYPE, PUBLIC :: PH_Mat_Therm_Eval_Arg
    REAL(wp) :: grad_T(3)          ! [IN] Temperature gradient
    REAL(wp) :: temperature        ! [IN] Current temperature
    REAL(wp) :: heat_flux(3)       ! [OUT] Heat flux
    REAL(wp) :: dq_dT(3,3)        ! [OUT] Conductivity tangent
    INTEGER(i4) :: status_code     ! [OUT] Status code
    CHARACTER(LEN=256) :: message  ! [OUT] Status message
  END TYPE PH_Mat_Therm_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Therm_Desc_Init` | 112 | `SUBROUTINE Therm_Desc_Init(this, cfg)` |
| SUBROUTINE | `Therm_Desc_Valid` | 123 | `SUBROUTINE Therm_Desc_Valid(this, vld)` |
| SUBROUTINE | `Therm_Desc_Clean` | 129 | `SUBROUTINE Therm_Desc_Clean(this)` |
| SUBROUTINE | `Therm_State_Init` | 143 | `SUBROUTINE Therm_State_Init(this)` |
| SUBROUTINE | `Therm_State_Update` | 152 | `SUBROUTINE Therm_State_Update(this, temperature, heat_flux)` |
| SUBROUTINE | `Therm_State_Clean` | 161 | `SUBROUTINE Therm_State_Clean(this)` |
| SUBROUTINE | `Therm_Algo_Init` | 172 | `SUBROUTINE Therm_Algo_Init(this)` |
| SUBROUTINE | `Therm_Ctx_Init` | 180 | `SUBROUTINE Therm_Ctx_Init(this)` |
| SUBROUTINE | `Therm_Ctx_Clean` | 188 | `SUBROUTINE Therm_Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
