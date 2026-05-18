# `PH_Mat_Comp_Def.f90`

- **Source**: `L4_PH/Material/Composite/PH_Mat_Comp_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Comp_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Comp_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Comp`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Composite`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Composite/PH_Mat_Comp_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Comp_Cfg_Init_Desc` (lines 26–29)

```fortran
  TYPE, PUBLIC :: PH_Mat_Comp_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: num_constants = 0
  END TYPE PH_Mat_Comp_Cfg_Init_Desc
```

### `PH_Mat_Comp_Pop_Vld_Desc` (lines 31–33)

```fortran
  TYPE, PUBLIC :: PH_Mat_Comp_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Comp_Pop_Vld_Desc
```

### `PH_Mat_Comp_Inc_Evo_Ctx` (lines 35–38)

```fortran
  TYPE, PUBLIC :: PH_Mat_Comp_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE PH_Mat_Comp_Inc_Evo_Ctx
```

### `PH_Mat_Comp_Desc` (lines 43–57)

```fortran
  TYPE, PUBLIC :: PH_Mat_Comp_Desc
    TYPE(PH_Mat_Comp_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Comp_Pop_Vld_Desc)  :: vld
    REAL(wp) :: E11 = 0.0_wp, E22 = 0.0_wp, E33 = 0.0_wp
    REAL(wp) :: nu12 = 0.0_wp, nu13 = 0.0_wp, nu23 = 0.0_wp
    REAL(wp) :: G12 = 0.0_wp, G13 = 0.0_wp, G23 = 0.0_wp
    REAL(wp) :: ply_thickness = 0.0_wp
    INTEGER(i4) :: n_plies = 0
    REAL(wp), ALLOCATABLE :: ply_angles(:)
    REAL(wp), ALLOCATABLE :: ply_fractions(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Comp_Desc_Init
    PROCEDURE, PASS :: Valid => Comp_Desc_Valid
    PROCEDURE, PASS :: Clean => Comp_Desc_Clean
  END TYPE PH_Mat_Comp_Desc
```

### `PH_Mat_Comp_State` (lines 62–71)

```fortran
  TYPE, PUBLIC :: PH_Mat_Comp_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: failure_index(6) = 0.0_wp
    LOGICAL :: is_failed = .FALSE., initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => Comp_State_Init
    PROCEDURE, PASS :: Update => Comp_State_Update
    PROCEDURE, PASS :: Clean  => Comp_State_Clean
  END TYPE PH_Mat_Comp_State
```

### `PH_Mat_Comp_Algo` (lines 76–81)

```fortran
  TYPE, PUBLIC :: PH_Mat_Comp_Algo
    INTEGER(i4) :: failure_criterion = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => Comp_Algo_Init
  END TYPE PH_Mat_Comp_Algo
```

### `PH_Mat_Comp_Ctx` (lines 86–93)

```fortran
  TYPE, PUBLIC :: PH_Mat_Comp_Ctx
    TYPE(PH_Mat_Comp_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_comp(6,6) = 0.0_wp
    REAL(wp) :: temperature = 293.15_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Comp_Ctx_Init
    PROCEDURE, PASS :: Clean => Comp_Ctx_Clean
  END TYPE PH_Mat_Comp_Ctx
```

### `PH_Mat_Comp_Eval_Arg` (lines 98–104)

```fortran
  TYPE, PUBLIC :: PH_Mat_Comp_Eval_Arg
    REAL(wp) :: strain(6)          ! [IN] Input strain
    REAL(wp) :: stress(6)          ! [OUT] Output stress
    REAL(wp) :: ddsdde(6,6)        ! [OUT] Tangent stiffness
    INTEGER(i4) :: status_code     ! [OUT] Status code
    CHARACTER(LEN=256) :: message  ! [OUT] Status message
  END TYPE PH_Mat_Comp_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Comp_Desc_Init` | 113 | `SUBROUTINE Comp_Desc_Init(this, cfg)` |
| SUBROUTINE | `Comp_Desc_Valid` | 126 | `SUBROUTINE Comp_Desc_Valid(this, vld)` |
| SUBROUTINE | `Comp_Desc_Clean` | 132 | `SUBROUTINE Comp_Desc_Clean(this)` |
| SUBROUTINE | `Comp_State_Init` | 148 | `SUBROUTINE Comp_State_Init(this)` |
| SUBROUTINE | `Comp_State_Update` | 157 | `SUBROUTINE Comp_State_Update(this, stress, strain)` |
| SUBROUTINE | `Comp_State_Clean` | 166 | `SUBROUTINE Comp_State_Clean(this)` |
| SUBROUTINE | `Comp_Algo_Init` | 177 | `SUBROUTINE Comp_Algo_Init(this)` |
| SUBROUTINE | `Comp_Ctx_Init` | 185 | `SUBROUTINE Comp_Ctx_Init(this)` |
| SUBROUTINE | `Comp_Ctx_Clean` | 193 | `SUBROUTINE Comp_Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
