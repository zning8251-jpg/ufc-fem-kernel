# `RT_Step_Exec.f90`

- **Source**: `L5_RT/StepDriver/RT_Step_Exec.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Step_Exec`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Step_Exec`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Step_Exec`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `StepDriver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/StepDriver/RT_Step_Exec.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_StepDriver_Config` (lines 58–69)

```fortran
  TYPE, PUBLIC :: RT_StepDriver_Config
    LOGICAL :: use_newton_raphson = .TRUE.
    LOGICAL :: use_line_search = .TRUE.
    LOGICAL :: enable_restart = .TRUE.
    LOGICAL :: enable_output = .TRUE.
    LOGICAL :: verbose = .TRUE.
    INTEGER(i4) :: max_increment = 1000_i4
    INTEGER(i4) :: checkpoint_freq = 10_i4
    CHARACTER(LEN=256) :: restart_file = 'restart.bin'
    CHARACTER(LEN=256) :: output_dir = './output'
    INTEGER(i4) :: conv_combination_mode = CONV_MODE_AND
  END TYPE RT_StepDriver_Config
```

### `StepState` (lines 85–95)

```fortran
  TYPE, PUBLIC :: StepState
    INTEGER(i4) :: current_state = STEP_STATE_INIT
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_increment = 0_i4
    INTEGER(i4) :: current_iteration = 0_i4
    INTEGER(i4) :: total_steps = 0_i4
    INTEGER(i4) :: total_increments = 0_i4
    REAL(wp)    :: current_load_factor = 0.0_wp
    REAL(wp)    :: current_time = 0.0_wp
    LOGICAL     :: converged = .FALSE.
  END TYPE StepState
```

### `StepDriverContext` (lines 100–109)

```fortran
  TYPE, PUBLIC :: StepDriverContext
    TYPE(StepState) :: state
    INTEGER(i4) :: max_increments = 100_i4
    INTEGER(i4) :: max_iterations = 20_i4
    REAL(wp)    :: initial_step_size = 0.1_wp
    REAL(wp)    :: min_step_size = 1.0e-6_wp
    REAL(wp)    :: max_step_size = 1.0_wp
    INTEGER(i4) :: n_rollbacks = 0_i4
    INTEGER(i4) :: max_rollbacks = 5_i4
  END TYPE StepDriverContext
```

### `RT_StepDriver_ConfigDomain` (lines 114–127)

```fortran
  TYPE, PUBLIC :: RT_StepDriver_ConfigDomain
    TYPE(RT_StepDriver_Desc), ALLOCATABLE :: configs(:)
    TYPE(AnalysisStep), POINTER :: step_ref(:) => NULL()
    INTEGER(i4) :: n_configs = 0_i4
    INTEGER(i4) :: capacity = 0_i4
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddConfig
    PROCEDURE :: GetConfig
    PROCEDURE :: BindStepRefs
    PROCEDURE :: GetStepRef
  END TYPE RT_StepDriver_ConfigDomain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init` | 134 | `SUBROUTINE Init(this, initial_capacity, status)` |
| SUBROUTINE | `Finalize` | 147 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `AddConfig` | 157 | `SUBROUTINE AddConfig(this, desc, config_id, status)` |
| SUBROUTINE | `GetConfig` | 185 | `SUBROUTINE GetConfig(this, step_idx, desc, status)` |
| SUBROUTINE | `BindStepRefs` | 205 | `SUBROUTINE BindStepRefs(this, steps, status)` |
| FUNCTION | `GetStepRef` | 224 | `FUNCTION GetStepRef(this, step_idx) RESULT(ptr)` |
| SUBROUTINE | `StepDriver_Init` | 237 | `SUBROUTINE StepDriver_Init(ctx, total_steps, max_incr, max_iter)` |
| SUBROUTINE | `StepDriver_Finalize` | 247 | `SUBROUTINE StepDriver_Finalize(ctx)` |
| SUBROUTINE | `RT_StepDriver_Execute` | 255 | `SUBROUTINE RT_StepDriver_Execute(model, step, workspace, config, result, status)` |
| SUBROUTINE | `RT_StepDriver_RunDynamicExplicit` | 586 | `SUBROUTINE RT_StepDriver_RunDynamicExplicit(model, step, workspace, result, status)` |
| SUBROUTINE | `RT_StepDriver_RunDynamicImplicit` | 642 | `SUBROUTINE RT_StepDriver_RunDynamicImplicit(model, step, workspace, result, status)` |
| SUBROUTINE | `RunStep` | 695 | `SUBROUTINE RunStep(ctx, step_id, ierr)` |
| SUBROUTINE | `StepStateMachine` | 722 | `SUBROUTINE StepStateMachine(ctx, ierr)` |
| SUBROUTINE | `GetStepState` | 776 | `SUBROUTINE GetStepState(ctx, state)` |
| SUBROUTINE | `RunIncrement` | 782 | `SUBROUTINE RunIncrement(ctx, incr_id, ierr)` |
| SUBROUTINE | `InitIncrement` | 791 | `SUBROUTINE InitIncrement(ctx, load_factor)` |
| SUBROUTINE | `FinalizeIncrement` | 798 | `SUBROUTINE FinalizeIncrement(ctx, converged)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
