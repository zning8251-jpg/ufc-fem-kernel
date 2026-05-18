# `PH_Mat_User_Def.f90`

- **Source**: `L4_PH/Material/User/PH_Mat_User_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_User_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_User_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_User`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/User`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/User/PH_Mat_User_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_User_Cfg_Init_Desc` (lines 26–29)

```fortran
  TYPE, PUBLIC :: PH_Mat_User_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: num_constants = 0
  END TYPE PH_Mat_User_Cfg_Init_Desc
```

### `PH_Mat_User_Pop_Vld_Desc` (lines 31–33)

```fortran
  TYPE, PUBLIC :: PH_Mat_User_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_User_Pop_Vld_Desc
```

### `PH_Mat_User_Inc_Evo_Ctx` (lines 35–38)

```fortran
  TYPE, PUBLIC :: PH_Mat_User_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE PH_Mat_User_Inc_Evo_Ctx
```

### `PH_Mat_User_Desc` (lines 43–53)

```fortran
  TYPE, PUBLIC :: PH_Mat_User_Desc
    TYPE(PH_Mat_User_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_User_Pop_Vld_Desc)  :: vld
    INTEGER(i4) :: nprops = 0, nstatv = 0
    REAL(wp), ALLOCATABLE :: props(:)
    CHARACTER(LEN=80) :: umat_name = ""
  CONTAINS
    PROCEDURE, PASS :: Init  => User_Desc_Init
    PROCEDURE, PASS :: Valid => User_Desc_Valid
    PROCEDURE, PASS :: Clean => User_Desc_Clean
  END TYPE PH_Mat_User_Desc
```

### `PH_Mat_User_State` (lines 58–67)

```fortran
  TYPE, PUBLIC :: PH_Mat_User_State
    REAL(wp) :: stress(6) = 0.0_wp
    REAL(wp), ALLOCATABLE :: statev(:)
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => User_State_Init
    PROCEDURE, PASS :: Update => User_State_Update
    PROCEDURE, PASS :: Clean  => User_State_Clean
  END TYPE PH_Mat_User_State
```

### `PH_Mat_User_Algo` (lines 72–76)

```fortran
  TYPE, PUBLIC :: PH_Mat_User_Algo
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => User_Algo_Init
  END TYPE PH_Mat_User_Algo
```

### `PH_Mat_User_Ctx` (lines 81–88)

```fortran
  TYPE, PUBLIC :: PH_Mat_User_Ctx
    TYPE(PH_Mat_User_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
    REAL(wp) :: temperature = 293.15_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => User_Ctx_Init
    PROCEDURE, PASS :: Clean => User_Ctx_Clean
  END TYPE PH_Mat_User_Ctx
```

### `PH_Mat_User_Eval_Arg` (lines 93–103)

```fortran
  TYPE, PUBLIC :: PH_Mat_User_Eval_Arg
    REAL(wp) :: strain(6)          ! [IN] Total strain
    REAL(wp) :: dstrain(6)         ! [IN] Strain increment
    REAL(wp) :: dt                 ! [IN] Time increment
    REAL(wp) :: temperature        ! [IN] Current temperature
    REAL(wp) :: stress(6)          ! [OUT] Output stress
    REAL(wp) :: ddsdde(6,6)        ! [OUT] Tangent stiffness
    REAL(wp), ALLOCATABLE :: statev(:)  ! [INOUT] State variables
    INTEGER(i4) :: status_code     ! [OUT] Status code
    CHARACTER(LEN=256) :: message  ! [OUT] Status message
  END TYPE PH_Mat_User_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `User_Desc_Init` | 112 | `SUBROUTINE User_Desc_Init(this, cfg)` |
| SUBROUTINE | `User_Desc_Valid` | 121 | `SUBROUTINE User_Desc_Valid(this, vld)` |
| SUBROUTINE | `User_Desc_Clean` | 127 | `SUBROUTINE User_Desc_Clean(this)` |
| SUBROUTINE | `User_State_Init` | 139 | `SUBROUTINE User_State_Init(this, nstatv)` |
| SUBROUTINE | `User_State_Update` | 149 | `SUBROUTINE User_State_Update(this, stress)` |
| SUBROUTINE | `User_State_Clean` | 156 | `SUBROUTINE User_State_Clean(this)` |
| SUBROUTINE | `User_Algo_Init` | 166 | `SUBROUTINE User_Algo_Init(this)` |
| SUBROUTINE | `User_Ctx_Init` | 173 | `SUBROUTINE User_Ctx_Init(this)` |
| SUBROUTINE | `User_Ctx_Clean` | 181 | `SUBROUTINE User_Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
