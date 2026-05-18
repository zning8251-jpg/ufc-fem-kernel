# `PH_Mat_Plast_Def.f90`

- **Source**: `L4_PH/Material/Plast/PH_Mat_Plast_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Plast_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Plast_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Plast`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Plast/PH_Mat_Plast_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Mat_Plast_Cfg_Init_Desc` (lines 29–34)

```fortran
  TYPE :: PH_Mat_Plast_Cfg_Init_Desc
    INTEGER(i4) :: family_type = 0
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: property_flags = 0
    INTEGER(i4) :: hardening_type = 1
  END TYPE PH_Mat_Plast_Cfg_Init_Desc
```

### `PH_Mat_Plast_Pop_Vld_Desc` (lines 36–38)

```fortran
  TYPE :: PH_Mat_Plast_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Plast_Pop_Vld_Desc
```

### `PH_Mat_Plast_Inc_Evo_Ctx` (lines 40–45)

```fortran
  TYPE :: PH_Mat_Plast_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
    ! TYPE-003: field-variable vector aliases caller/workspace buffer (not ALLOCATABLE in *Ctx)
    REAL(wp), DIMENSION(:), POINTER :: field_var => NULL()
    REAL(wp) :: dstrain(6) = 0.0_wp    ! [IN] strain increment
  END TYPE PH_Mat_Plast_Inc_Evo_Ctx
```

### `PH_Mat_Plast_Desc` (lines 51–64)

```fortran
  TYPE :: PH_Mat_Plast_Desc
    TYPE(PH_Mat_Plast_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Plast_Pop_Vld_Desc) :: pop
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, G = 0.0_wp, K = 0.0_wp
    REAL(wp) :: sigma_y = 0.0_wp
    REAL(wp) :: H_iso = 0.0_wp, H_kin = 0.0_wp
    REAL(wp) :: F_hill = 0.0_wp, G_hill = 0.0_wp, H_hill = 0.0_wp
    REAL(wp) :: A_jc = 0.0_wp, B_jc = 0.0_wp, n_jc = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Plast_Desc
```

### `PH_Mat_Plast_State` (lines 66–79)

```fortran
  TYPE :: PH_Mat_Plast_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: elastic_strain(6) = 0.0_wp
    REAL(wp) :: plastic_strain(6) = 0.0_wp
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: backstress(6) = 0.0_wp
    REAL(wp) :: alpha_iso = 0.0_wp
    LOGICAL :: is_plastic = .FALSE., initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Plast_State
```

### `PH_Mat_Plast_Algo` (lines 81–89)

```fortran
  TYPE :: PH_Mat_Plast_Algo
    INTEGER(i4) :: integration_method = 1
    INTEGER(i4) :: max_iterations = 50
    REAL(wp) :: tolerance = 1.0e-8_wp
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Plast_Algo
```

### `PH_Mat_Plast_Ctx` (lines 91–102)

```fortran
  TYPE :: PH_Mat_Plast_Ctx
    TYPE(PH_Mat_Plast_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
    REAL(wp) :: stress_trial(6) = 0.0_wp
    REAL(wp) :: delta_lambda = 0.0_wp
    REAL(wp) :: yield_function = 0.0_wp
    INTEGER(i4) :: num_iterations = 0
    LOGICAL :: converged = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Plast_Ctx
```

### `PH_Mat_Plast_Eval_Arg` (lines 104–115)

```fortran
  TYPE :: PH_Mat_Plast_Eval_Arg
    REAL(wp) :: strain(6)              ! [IN] Total strain at start of increment
    REAL(wp) :: dstrain(6)             ! [IN] Strain increment
    REAL(wp) :: dt                     ! [IN] Time increment
    REAL(wp) :: temperature            ! [IN] Current temperature
    REAL(wp) :: dtemp                  ! [IN] Temperature increment
    REAL(wp), ALLOCATABLE :: statev(:) ! [INOUT] state variables array
    REAL(wp) :: stress(6)              ! [OUT] Updated stress (Voigt)
    REAL(wp) :: ddsdde(6,6)            ! [OUT] Consistent tangent stiffness
    INTEGER(i4) :: status_code         ! [OUT] Completion status code
    CHARACTER(LEN=:), ALLOCATABLE :: message  ! [OUT] Status message
  END TYPE PH_Mat_Plast_Eval_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Desc_Init` | 129 | `SUBROUTINE Desc_Init(self)` |
| SUBROUTINE | `Desc_Valid` | 152 | `SUBROUTINE Desc_Valid(self)` |
| SUBROUTINE | `Desc_Clean` | 157 | `SUBROUTINE Desc_Clean(self)` |
| SUBROUTINE | `State_Init` | 184 | `SUBROUTINE State_Init(self)` |
| SUBROUTINE | `State_Update` | 198 | `SUBROUTINE State_Update(self)` |
| SUBROUTINE | `State_Clean` | 204 | `SUBROUTINE State_Clean(self)` |
| SUBROUTINE | `Algo_Init` | 222 | `SUBROUTINE Algo_Init(self)` |
| SUBROUTINE | `Algo_Config` | 230 | `SUBROUTINE Algo_Config(self)` |
| SUBROUTINE | `Ctx_Init` | 242 | `SUBROUTINE Ctx_Init(self)` |
| SUBROUTINE | `Ctx_Clean` | 254 | `SUBROUTINE Ctx_Clean(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
