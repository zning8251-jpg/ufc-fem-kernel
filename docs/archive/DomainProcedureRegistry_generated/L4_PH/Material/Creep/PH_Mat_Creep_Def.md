# `PH_Mat_Creep_Def.f90`

- **Source**: `L4_PH/Material/Creep/PH_Mat_Creep_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Creep_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Creep_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Creep`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Creep`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Creep/PH_Mat_Creep_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Creep_Cfg_Init_Desc` (lines 22–24)

```fortran
  TYPE, PUBLIC :: PH_Mat_Creep_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0_i4
  END TYPE PH_Mat_Creep_Cfg_Init_Desc
```

### `PH_Mat_Creep_Pop_Vld_Desc` (lines 26–28)

```fortran
  TYPE, PUBLIC :: PH_Mat_Creep_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Creep_Pop_Vld_Desc
```

### `PH_Mat_Creep_Inc_Evo_Ctx` (lines 30–33)

```fortran
  TYPE, PUBLIC :: PH_Mat_Creep_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
    REAL(wp) :: dt = 0.0_wp
  END TYPE PH_Mat_Creep_Inc_Evo_Ctx
```

### `PH_Mat_Creep_Desc` (lines 36–46)

```fortran
  TYPE, PUBLIC :: PH_Mat_Creep_Desc
    TYPE(PH_Mat_Creep_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Creep_Pop_Vld_Desc) :: pop
    REAL(wp) :: A = 0.0_wp, n = 0.0_wp, m = 0.0_wp
    REAL(wp) :: Q_act = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => PH_Mat_Creep_Desc_Init
    PROCEDURE, PASS :: Valid => PH_Mat_Creep_Desc_Valid
    PROCEDURE, PASS :: Clean => PH_Mat_Creep_Desc_Clean
  END TYPE PH_Mat_Creep_Desc
```

### `PH_Mat_Creep_State` (lines 49–59)

```fortran
  TYPE, PUBLIC :: PH_Mat_Creep_State
    REAL(wp) :: stress(6) = 0.0_wp, creep_strain(6) = 0.0_wp
    REAL(wp) :: equiv_creep_strain = 0.0_wp
    REAL(wp) :: creep_strain_rate(6) = 0.0_wp
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => PH_Mat_Creep_State_Init
    PROCEDURE, PASS :: Update => PH_Mat_Creep_State_Update
    PROCEDURE, PASS :: Clean  => PH_Mat_Creep_State_Clean
  END TYPE PH_Mat_Creep_State
```

### `PH_Mat_Creep_Algo` (lines 62–68)

```fortran
  TYPE, PUBLIC :: PH_Mat_Creep_Algo
    INTEGER(i4) :: integration_method = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => PH_Mat_Creep_Algo_Init
    PROCEDURE, PASS :: Config => PH_Mat_Creep_Algo_Config
  END TYPE PH_Mat_Creep_Algo
```

### `PH_Mat_Creep_Ctx` (lines 71–77)

```fortran
  TYPE, PUBLIC :: PH_Mat_Creep_Ctx
    TYPE(PH_Mat_Creep_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => PH_Mat_Creep_Ctx_Init
    PROCEDURE, PASS :: Clean => PH_Mat_Creep_Ctx_Clean
  END TYPE PH_Mat_Creep_Ctx
```

### `PH_Mat_Creep_Eval_Arg` (lines 80–89)

```fortran
  TYPE, PUBLIC :: PH_Mat_Creep_Eval_Arg
    REAL(wp) :: strain(6)            ! [IN]  Total strain
    REAL(wp) :: dstrain(6)           ! [IN]  Strain increment
    REAL(wp) :: dt                   ! [IN]  Time increment
    REAL(wp) :: temperature          ! [IN]  Current temperature
    REAL(wp) :: stress(6)            ! [OUT] Updated stress
    REAL(wp) :: ddsdde(6,6)          ! [OUT] Tangent stiffness matrix
    INTEGER(i4) :: status_code       ! [OUT] Exit status code
    CHARACTER(len=256) :: message    ! [OUT] Diagnostic message
  END TYPE PH_Mat_Creep_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Creep_Desc_Init` | 102 | `SUBROUTINE PH_Mat_Creep_Desc_Init(desc, sub_type, nprops)` |
| SUBROUTINE | `PH_Mat_Creep_Desc_Valid` | 112 | `SUBROUTINE PH_Mat_Creep_Desc_Valid(desc, status)` |
| SUBROUTINE | `PH_Mat_Creep_Desc_Clean` | 122 | `SUBROUTINE PH_Mat_Creep_Desc_Clean(desc)` |
| SUBROUTINE | `PH_Mat_Creep_State_Init` | 133 | `SUBROUTINE PH_Mat_Creep_State_Init(state)` |
| SUBROUTINE | `PH_Mat_Creep_State_Update` | 143 | `SUBROUTINE PH_Mat_Creep_State_Update(state, stress, creep_strain)` |
| SUBROUTINE | `PH_Mat_Creep_State_Clean` | 151 | `SUBROUTINE PH_Mat_Creep_State_Clean(state)` |
| SUBROUTINE | `PH_Mat_Creep_Algo_Init` | 163 | `SUBROUTINE PH_Mat_Creep_Algo_Init(algo)` |
| SUBROUTINE | `PH_Mat_Creep_Algo_Config` | 169 | `SUBROUTINE PH_Mat_Creep_Algo_Config(algo, method, use_num_tang)` |
| SUBROUTINE | `PH_Mat_Creep_Ctx_Init` | 179 | `SUBROUTINE PH_Mat_Creep_Ctx_Init(ctx)` |
| SUBROUTINE | `PH_Mat_Creep_Ctx_Clean` | 186 | `SUBROUTINE PH_Mat_Creep_Ctx_Clean(ctx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
