# `PH_Mat_Acou_Def.f90`

- **Source**: `L4_PH/Material/Acoustic/PH_Mat_Acou_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Acou_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Acou_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Acou`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Acoustic/PH_Mat_Acou_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Acou_Cfg_Init_Desc` (lines 26–29)

```fortran
  TYPE, PUBLIC :: PH_Mat_Acou_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: num_constants = 0
  END TYPE PH_Mat_Acou_Cfg_Init_Desc
```

### `PH_Mat_Acou_Pop_Vld_Desc` (lines 31–33)

```fortran
  TYPE, PUBLIC :: PH_Mat_Acou_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Acou_Pop_Vld_Desc
```

### `PH_Mat_Acou_Inc_Evo_Ctx` (lines 35–38)

```fortran
  TYPE, PUBLIC :: PH_Mat_Acou_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE PH_Mat_Acou_Inc_Evo_Ctx
```

### `PH_Mat_Acou_Desc` (lines 43–53)

```fortran
  TYPE, PUBLIC :: PH_Mat_Acou_Desc
    TYPE(PH_Mat_Acou_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Acou_Pop_Vld_Desc)  :: vld
    REAL(wp) :: bulk_modulus = 0.0_wp
    REAL(wp) :: density = 0.0_wp
    REAL(wp) :: speed_of_sound = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Acou_Desc_Init
    PROCEDURE, PASS :: Valid => Acou_Desc_Valid
    PROCEDURE, PASS :: Clean => Acou_Desc_Clean
  END TYPE PH_Mat_Acou_Desc
```

### `PH_Mat_Acou_State` (lines 58–68)

```fortran
  TYPE, PUBLIC :: PH_Mat_Acou_State
    REAL(wp) :: stress(6) = 0.0_wp
    REAL(wp) :: pressure = 0.0_wp
    REAL(wp) :: strain(6) = 0.0_wp
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => Acou_State_Init
    PROCEDURE, PASS :: Update => Acou_State_Update
    PROCEDURE, PASS :: Clean  => Acou_State_Clean
  END TYPE PH_Mat_Acou_State
```

### `PH_Mat_Acou_Algo` (lines 73–78)

```fortran
  TYPE, PUBLIC :: PH_Mat_Acou_Algo
    INTEGER(i4) :: method = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => Acou_Algo_Init
  END TYPE PH_Mat_Acou_Algo
```

### `PH_Mat_Acou_Ctx` (lines 83–90)

```fortran
  TYPE, PUBLIC :: PH_Mat_Acou_Ctx
    TYPE(PH_Mat_Acou_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_acou(6,6) = 0.0_wp
    REAL(wp) :: temperature = 293.15_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Acou_Ctx_Init
    PROCEDURE, PASS :: Clean => Acou_Ctx_Clean
  END TYPE PH_Mat_Acou_Ctx
```

### `PH_Mat_Acou_Eval_Arg` (lines 95–101)

```fortran
  TYPE, PUBLIC :: PH_Mat_Acou_Eval_Arg
    REAL(wp) :: strain(6)                ! [IN] Input strain
    REAL(wp) :: stress(6)                ! [OUT] Output stress
    REAL(wp) :: ddsdde(6,6)              ! [OUT] Tangent stiffness
    INTEGER(i4) :: status_code           ! [OUT] Status code
    CHARACTER(LEN=256) :: message        ! [OUT] Status message
  END TYPE PH_Mat_Acou_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Acou_Desc_Init` | 110 | `SUBROUTINE Acou_Desc_Init(this, cfg)` |
| SUBROUTINE | `Acou_Desc_Valid` | 119 | `SUBROUTINE Acou_Desc_Valid(this, vld)` |
| SUBROUTINE | `Acou_Desc_Clean` | 125 | `SUBROUTINE Acou_Desc_Clean(this)` |
| SUBROUTINE | `Acou_State_Init` | 137 | `SUBROUTINE Acou_State_Init(this)` |
| SUBROUTINE | `Acou_State_Update` | 146 | `SUBROUTINE Acou_State_Update(this, stress, strain)` |
| SUBROUTINE | `Acou_State_Clean` | 155 | `SUBROUTINE Acou_State_Clean(this)` |
| SUBROUTINE | `Acou_Algo_Init` | 166 | `SUBROUTINE Acou_Algo_Init(this)` |
| SUBROUTINE | `Acou_Ctx_Init` | 174 | `SUBROUTINE Acou_Ctx_Init(this)` |
| SUBROUTINE | `Acou_Ctx_Clean` | 182 | `SUBROUTINE Acou_Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
