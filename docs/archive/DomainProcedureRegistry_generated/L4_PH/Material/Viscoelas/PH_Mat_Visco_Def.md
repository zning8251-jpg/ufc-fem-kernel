# `PH_Mat_Visco_Def.f90`

- **Source**: `L4_PH/Material/Viscoelas/PH_Mat_Visco_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Visco_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Visco_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Visco`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Viscoelas`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Viscoelas/PH_Mat_Visco_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Visco_Cfg_Init_Desc` (lines 23–26)

```fortran
  TYPE :: PH_Mat_Visco_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: property_flags = 0
  END TYPE PH_Mat_Visco_Cfg_Init_Desc
```

### `PH_Mat_Visco_Pop_Vld_Desc` (lines 28–30)

```fortran
  TYPE :: PH_Mat_Visco_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Visco_Pop_Vld_Desc
```

### `PH_Mat_Visco_Inc_Evo_Ctx` (lines 32–36)

```fortran
  TYPE :: PH_Mat_Visco_Inc_Evo_Ctx
    REAL(wp) :: dt = 0.0_wp
    REAL(wp) :: temperature = 293.15_wp
    REAL(wp), ALLOCATABLE :: field_var(:)
  END TYPE PH_Mat_Visco_Inc_Evo_Ctx
```

### `PH_Mat_Visco_Desc` (lines 42–61)

```fortran
  TYPE :: PH_Mat_Visco_Desc
    TYPE(PH_Mat_Visco_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Visco_Pop_Vld_Desc) :: pop
    REAL(wp), ALLOCATABLE :: tau_k(:)
    REAL(wp), ALLOCATABLE :: g_k(:)
    REAL(wp) :: g_inf = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
    ! --- Core fields ---
    INTEGER(i4) :: sub_type = 0
    LOGICAL :: is_valid = .FALSE.
    REAL(wp) :: E_inf = 0.0_wp
    REAL(wp) :: nu = 0.3_wp
    INTEGER(i4) :: n_prony_terms = 0
    REAL(wp) :: g_i(10) = 0.0_wp
    REAL(wp) :: tau_i(10) = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => PH_Mat_Visco_Desc_Init
    PROCEDURE, PASS :: Valid => PH_Mat_Visco_Desc_Valid
    PROCEDURE, PASS :: Clean => PH_Mat_Visco_Desc_Clean
  END TYPE PH_Mat_Visco_Desc
```

### `PH_Mat_Visco_State` (lines 63–72)

```fortran
  TYPE :: PH_Mat_Visco_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp), ALLOCATABLE :: s_k_6(:,:)
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => PH_Mat_Visco_State_Init
    PROCEDURE, PASS :: Update => PH_Mat_Visco_State_Update
    PROCEDURE, PASS :: Clean  => PH_Mat_Visco_State_Clean
  END TYPE PH_Mat_Visco_State
```

### `PH_Mat_Visco_Algo` (lines 74–81)

```fortran
  TYPE :: PH_Mat_Visco_Algo
    INTEGER(i4) :: integration_method = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
    REAL(wp) :: time_step = 1.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init   => PH_Mat_Visco_Algo_Init
    PROCEDURE, PASS :: Config => PH_Mat_Visco_Algo_Config
  END TYPE PH_Mat_Visco_Algo
```

### `PH_Mat_Visco_Ctx` (lines 83–91)

```fortran
  TYPE :: PH_Mat_Visco_Ctx
    TYPE(PH_Mat_Visco_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
    REAL(wp) :: D_inst(6,6) = 0.0_wp
    LOGICAL :: D_inst_cached = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init  => PH_Mat_Visco_Ctx_Init
    PROCEDURE, PASS :: Clean => PH_Mat_Visco_Ctx_Clean
  END TYPE PH_Mat_Visco_Ctx
```

### `PH_Mat_Visco_Eval_Arg` (lines 93–102)

```fortran
  TYPE :: PH_Mat_Visco_Eval_Arg
    REAL(wp) :: strain(6)              ! [IN] Total strain at start of increment
    REAL(wp) :: dstrain(6)             ! [IN] Strain increment
    REAL(wp) :: dt                     ! [IN] Time increment
    REAL(wp) :: temperature            ! [IN] Current temperature
    REAL(wp) :: stress(6)              ! [OUT] Updated stress (Voigt)
    REAL(wp) :: ddsdde(6,6)            ! [OUT] Consistent tangent stiffness
    INTEGER(i4) :: status_code         ! [OUT] Completion status code
    CHARACTER(LEN=:), ALLOCATABLE :: message  ! [OUT] Status message
  END TYPE PH_Mat_Visco_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Visco_Desc_Init` | 116 | `SUBROUTINE PH_Mat_Visco_Desc_Init(self)` |
| SUBROUTINE | `PH_Mat_Visco_Desc_Valid` | 134 | `SUBROUTINE PH_Mat_Visco_Desc_Valid(self)` |
| SUBROUTINE | `PH_Mat_Visco_Desc_Clean` | 140 | `SUBROUTINE PH_Mat_Visco_Desc_Clean(self)` |
| SUBROUTINE | `PH_Mat_Visco_State_Init` | 162 | `SUBROUTINE PH_Mat_Visco_State_Init(self)` |
| SUBROUTINE | `PH_Mat_Visco_State_Update` | 171 | `SUBROUTINE PH_Mat_Visco_State_Update(self)` |
| SUBROUTINE | `PH_Mat_Visco_State_Clean` | 177 | `SUBROUTINE PH_Mat_Visco_State_Clean(self)` |
| SUBROUTINE | `PH_Mat_Visco_Algo_Init` | 190 | `SUBROUTINE PH_Mat_Visco_Algo_Init(self)` |
| SUBROUTINE | `PH_Mat_Visco_Algo_Config` | 197 | `SUBROUTINE PH_Mat_Visco_Algo_Config(self)` |
| SUBROUTINE | `PH_Mat_Visco_Ctx_Init` | 208 | `SUBROUTINE PH_Mat_Visco_Ctx_Init(self)` |
| SUBROUTINE | `PH_Mat_Visco_Ctx_Clean` | 218 | `SUBROUTINE PH_Mat_Visco_Ctx_Clean(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
