# `PH_Mat_Geo_Def.f90`

- **Source**: `L4_PH/Material/Geo/PH_Mat_Geo_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Geo_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Geo_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Geo`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Geo`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Geo/PH_Mat_Geo_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Geo_Cfg_Init_Desc` (lines 23–25)

```fortran
  TYPE, PUBLIC :: PH_Mat_Geo_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0_i4
  END TYPE PH_Mat_Geo_Cfg_Init_Desc
```

### `PH_Mat_Geo_Pop_Vld_Desc` (lines 27–29)

```fortran
  TYPE, PUBLIC :: PH_Mat_Geo_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Geo_Pop_Vld_Desc
```

### `PH_Mat_Geo_Inc_Evo_Ctx` (lines 31–33)

```fortran
  TYPE, PUBLIC :: PH_Mat_Geo_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
  END TYPE PH_Mat_Geo_Inc_Evo_Ctx
```

### `PH_Mat_Geo_Desc` (lines 36–49)

```fortran
  TYPE, PUBLIC :: PH_Mat_Geo_Desc
    TYPE(PH_Mat_Geo_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Geo_Pop_Vld_Desc)  :: pop
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: phi_friction = 0.0_wp
    REAL(wp) :: c_cohesion = 0.0_wp
    REAL(wp) :: psi_dilation = 0.0_wp
    REAL(wp) :: K0 = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Geo_Desc
```

### `PH_Mat_Geo_State` (lines 52–63)

```fortran
  TYPE, PUBLIC :: PH_Mat_Geo_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: plastic_strain(6) = 0.0_wp
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: cap_vol_plastic_strain = 0.0_wp
    LOGICAL :: is_plastic = .FALSE., initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Geo_State
```

### `PH_Mat_Geo_Algo` (lines 66–75)

```fortran
  TYPE, PUBLIC :: PH_Mat_Geo_Algo
    INTEGER(i4) :: integration_method = 1
    REAL(wp) :: tolerance = 1.0e-8_wp
    INTEGER(i4) :: return_mapping = 1
    INTEGER(i4) :: max_iter = 50
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Geo_Algo
```

### `PH_Mat_Geo_Ctx` (lines 78–85)

```fortran
  TYPE, PUBLIC :: PH_Mat_Geo_Ctx
    TYPE(PH_Mat_Geo_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
    REAL(wp) :: stress_trial(6) = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Geo_Ctx
```

### `PH_Mat_Geo_Eval_Arg` (lines 88–95)

```fortran
  TYPE, PUBLIC :: PH_Mat_Geo_Eval_Arg
    REAL(wp) :: strain(6)            ! [IN]  Total strain
    REAL(wp) :: dstrain(6)           ! [IN]  Strain increment
    REAL(wp) :: stress(6)            ! [OUT] Updated stress
    REAL(wp) :: ddsdde(6,6)          ! [OUT] Tangent stiffness matrix
    INTEGER(i4) :: status_code       ! [OUT] Exit status code
    CHARACTER(len=256) :: message    ! [OUT] Diagnostic message
  END TYPE PH_Mat_Geo_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 108 | `SUBROUTINE Desc_Init(desc, sub_type, nprops)` |
| FUNCTION | `Desc_Valid` | 118 | `FUNCTION Desc_Valid(desc) RESULT(valid)` |
| SUBROUTINE | `Desc_Clean` | 124 | `SUBROUTINE Desc_Clean(desc)` |
| SUBROUTINE | `State_Init` | 138 | `SUBROUTINE State_Init(state)` |
| SUBROUTINE | `State_Update` | 150 | `SUBROUTINE State_Update(state, stress, plastic_strain)` |
| SUBROUTINE | `State_Clean` | 158 | `SUBROUTINE State_Clean(state)` |
| SUBROUTINE | `Algo_Init` | 172 | `SUBROUTINE Algo_Init(algo)` |
| SUBROUTINE | `Algo_Config` | 181 | `SUBROUTINE Algo_Config(algo, mapping, max_it, use_num_tang)` |
| SUBROUTINE | `Ctx_Init` | 192 | `SUBROUTINE Ctx_Init(ctx)` |
| SUBROUTINE | `Ctx_Clean` | 199 | `SUBROUTINE Ctx_Clean(ctx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
