# `NM_TimeInt_Scheme.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_Scheme.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_TimeInt_Scheme`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_Scheme`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt_Scheme`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_Scheme.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_TimeInt_Ctrl_Ctx` (lines 42–65)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_Ctrl_Ctx
      INTEGER(i4) :: method = 1
      REAL(wp) :: dt = 0.0_wp
      REAL(wp) :: t_current = 0.0_wp
      REAL(wp) :: t_final = 1.0_wp
      REAL(wp) :: newmark_beta = 0.25_wp
      REAL(wp) :: newmark_gamma = 0.5_wp
      REAL(wp) :: hht_alpha = 0.0_wp
      REAL(wp) :: gen_alpha_m = 0.0_wp
      REAL(wp) :: gen_alpha_f = 0.0_wp
      LOGICAL :: use_numerical_dissipation = .FALSE.
      REAL(wp) :: spectral_radius = 1.0_wp
      INTEGER(i4) :: max_iterations = 100
      REAL(wp) :: tolerance = 1.0e-6_wp
      LOGICAL :: is_initialized = .FALSE.
      LOGICAL :: use_adaptive_dt = .FALSE.
      REAL(wp) :: dt_min = 1.0e-10_wp
      REAL(wp) :: dt_max = 1.0_wp
  CONTAINS
      PROCEDURE, PUBLIC :: Init => NM_TimeInt_Ctrl_Init
      PROCEDURE, PUBLIC :: Cleanup => NM_TimeInt_Ctrl_Cleanup
      PROCEDURE, PUBLIC :: SetMethod => NM_TimeInt_Ctrl_SetMethod
      PROCEDURE, PUBLIC :: SetTimeStep => NM_TimeInt_Ctrl_SetTimeStep
  END TYPE NM_TimeInt_Ctrl_Ctx
```

### `NM_TimeInt_State` (lines 70–92)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_State
      REAL(wp), ALLOCATABLE :: u(:)
      REAL(wp), ALLOCATABLE :: v(:)
      REAL(wp), ALLOCATABLE :: a(:)
      REAL(wp), ALLOCATABLE :: u_prev(:)
      REAL(wp), ALLOCATABLE :: v_prev(:)
      REAL(wp), ALLOCATABLE :: a_prev(:)
      REAL(wp), ALLOCATABLE :: u_intermediate(:)
      REAL(wp), ALLOCATABLE :: v_intermediate(:)
      REAL(wp), ALLOCATABLE :: a_intermediate(:)
      REAL(wp) :: t_current = 0.0_wp
      REAL(wp) :: dt = 0.0_wp
      INTEGER(i4) :: step_count = 0
      LOGICAL :: converged = .FALSE.
      INTEGER(i4) :: iteration_count = 0
      REAL(wp) :: residual_norm = 0.0_wp
      LOGICAL :: is_initialized = .FALSE.
  CONTAINS
      PROCEDURE, PUBLIC :: Init => NM_TimeInt_State_Init
      PROCEDURE, PUBLIC :: Cleanup => NM_TimeInt_State_Cleanup
      PROCEDURE, PUBLIC :: Update => NM_TimeInt_State_Update
      PROCEDURE, PUBLIC :: SavePrevious => NM_TimeInt_State_SavePrevious
  END TYPE NM_TimeInt_State
```

### `NM_TimeInt_Newmark_Init_In` (lines 99–105)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_Newmark_Init_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: u0(:)
    REAL(wp), ALLOCATABLE :: v0(:)
    REAL(wp), ALLOCATABLE :: a0(:)
  END TYPE NM_TimeInt_Newmark_Init_In
```

### `NM_TimeInt_Newmark_Init_Out` (lines 108–111)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_Newmark_Init_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_Newmark_Init_Out
```

### `NM_TimeInt_Newmark_Step_In` (lines 114–118)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_Newmark_Step_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: a_new(:)
  END TYPE NM_TimeInt_Newmark_Step_In
```

### `NM_TimeInt_Newmark_Step_Out` (lines 121–124)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_Newmark_Step_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_Newmark_Step_Out
```

### `NM_TimeInt_HHTAlpha_Init_In` (lines 127–133)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_HHTAlpha_Init_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: u0(:)
    REAL(wp), ALLOCATABLE :: v0(:)
    REAL(wp), ALLOCATABLE :: a0(:)
  END TYPE NM_TimeInt_HHTAlpha_Init_In
```

### `NM_TimeInt_HHTAlpha_Init_Out` (lines 136–139)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_HHTAlpha_Init_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_HHTAlpha_Init_Out
```

### `NM_TimeInt_HHTAlpha_Step_In` (lines 142–146)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_HHTAlpha_Step_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: a_new(:)
  END TYPE NM_TimeInt_HHTAlpha_Step_In
```

### `NM_TimeInt_HHTAlpha_Step_Out` (lines 149–152)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_HHTAlpha_Step_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_HHTAlpha_Step_Out
```

### `NM_TimeInt_GeneralizedAlpha_Init_In` (lines 155–161)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_GeneralizedAlpha_Init_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: u0(:)
    REAL(wp), ALLOCATABLE :: v0(:)
    REAL(wp), ALLOCATABLE :: a0(:)
  END TYPE NM_TimeInt_GeneralizedAlpha_Init_In
```

### `NM_TimeInt_GeneralizedAlpha_Init_Out` (lines 164–167)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_GeneralizedAlpha_Init_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_GeneralizedAlpha_Init_Out
```

### `NM_TimeInt_GeneralizedAlpha_Step_In` (lines 170–174)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_GeneralizedAlpha_Step_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: a_new(:)
  END TYPE NM_TimeInt_GeneralizedAlpha_Step_In
```

### `NM_TimeInt_GeneralizedAlpha_Step_Out` (lines 177–180)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_GeneralizedAlpha_Step_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_GeneralizedAlpha_Step_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_TimeInt_Ctrl_Init` | 188 | `SUBROUTINE NM_TimeInt_Ctrl_Init(this, method, dt, t_final, status)` |
| SUBROUTINE | `NM_TimeInt_Ctrl_Cleanup` | 247 | `SUBROUTINE NM_TimeInt_Ctrl_Cleanup(this)` |
| SUBROUTINE | `NM_TimeInt_Ctrl_SetMethod` | 255 | `SUBROUTINE NM_TimeInt_Ctrl_SetMethod(this, method, status)` |
| SUBROUTINE | `NM_TimeInt_Ctrl_SetTimeStep` | 285 | `SUBROUTINE NM_TimeInt_Ctrl_SetTimeStep(this, dt, status)` |
| SUBROUTINE | `NM_TimeInt_State_Init` | 314 | `SUBROUTINE NM_TimeInt_State_Init(this, n_dof, status)` |
| SUBROUTINE | `NM_TimeInt_State_Cleanup` | 359 | `SUBROUTINE NM_TimeInt_State_Cleanup(this)` |
| SUBROUTINE | `NM_TimeInt_State_Update` | 375 | `SUBROUTINE NM_TimeInt_State_Update(this, u_new, v_new, a_new, dt)` |
| SUBROUTINE | `NM_TimeInt_State_SavePrevious` | 394 | `SUBROUTINE NM_TimeInt_State_SavePrevious(this)` |
| SUBROUTINE | `NM_TimeInt_Newmark_Init` | 412 | `SUBROUTINE NM_TimeInt_Newmark_Init(arg)` |
| SUBROUTINE | `NM_TimeInt_Newmark_Step` | 461 | `SUBROUTINE NM_TimeInt_Newmark_Step(in, out)` |
| SUBROUTINE | `NM_TimeInt_HHTAlpha_Init` | 506 | `SUBROUTINE NM_TimeInt_HHTAlpha_Init(in, out)` |
| SUBROUTINE | `NM_TimeInt_HHTAlpha_Step` | 547 | `SUBROUTINE NM_TimeInt_HHTAlpha_Step(in, out)` |
| SUBROUTINE | `NM_TimeInt_GeneralizedAlpha_Init` | 588 | `SUBROUTINE NM_TimeInt_GeneralizedAlpha_Init(in, out)` |
| SUBROUTINE | `NM_TimeInt_GeneralizedAlpha_Step` | 632 | `SUBROUTINE NM_TimeInt_GeneralizedAlpha_Step(in, out)` |
| SUBROUTINE | `NM_TimeInt_GetAlpha` | 685 | `SUBROUTINE NM_TimeInt_GetAlpha(rho_inf, alpha_m, alpha_f, beta, gamma)` |
| FUNCTION | `NM_TimeInt_GetBeta` | 699 | `FUNCTION NM_TimeInt_GetBeta(method, rho_inf) RESULT(beta)` |
| FUNCTION | `NM_TimeInt_GetGamma` | 721 | `FUNCTION NM_TimeInt_GetGamma(method, rho_inf) RESULT(gamma)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
