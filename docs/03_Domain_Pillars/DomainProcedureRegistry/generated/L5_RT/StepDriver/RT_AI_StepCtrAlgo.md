# `RT_AI_StepCtrAlgo.f90`

- **Source**: `L5_RT/StepDriver/RT_AI_StepCtrAlgo.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_AI_StepCtrAlgo`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_AI_StepCtrAlgo`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_AI_StepCtrAlgo`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `StepDriver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/StepDriver/RT_AI_StepCtrAlgo.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AI_StepCtr_Type` (lines 26–57)

```fortran
  TYPE, PUBLIC :: AI_StepCtr_Type
    !-------------------------------------------------------------------------
    ! Algorithm configuration (冷数据，Write-Once)
    !-------------------------------------------------------------------------
    INTEGER(i4) :: controller_type = 0       ! 0=PID, 1=HR2, 2=AI-PID
    REAL(wp)    :: initial_dtime = 1.0_wp     ! Initial time increment
    REAL(wp)    :: min_dtime = 1e-10_wp      ! Minimum time increment
    REAL(wp)    :: max_dtime = 1.0_wp        ! Maximum time increment
    REAL(wp)    :: target_its = 5            ! Target Newton iterations
    
    ! Step size policy parameters
    REAL(wp)    :: growth_factor = 2.0_wp    ! Maximum growth factor
    REAL(wp)    :: shrink_factor = 0.5_wp    ! Emergency shrink factor
    REAL(wp)    :: error_tolerance = 1e-4_wp  ! Truncation error tolerance
    
    ! Solution history (fixed-size, AP-8 compliant)
    INTEGER(i4) :: history_window = 20        ! Number of stored solutions
    REAL(wp), ALLOCATABLE :: time_history(:)    ! Time at step start
    REAL(wp), ALLOCATABLE :: error_history(:)   ! Truncation error
    INTEGER(i4), ALLOCATABLE :: its_history(:)  ! Newton iterations
    
    ! AI model parameters (for AI-PID)
    INTEGER(i4) :: pid_kp = 0                 ! PID proportional gain
    INTEGER(i4) :: pid_ki = 0                 ! PID integral gain
    INTEGER(i4) :: pid_kd = 0                 ! PID derivative gain
    
    ! Performance metrics
    REAL(wp)    :: total_steps = 0           ! Total number of steps
    REAL(wp)    :: rejected_steps = 0         ! Number of rejected steps
    REAL(wp)    :: avg_its_per_step = 0.0_wp  ! Average Newton iterations
    
  END TYPE AI_StepCtr_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AI_StepCtr_Init` | 65 | `SUBROUTINE AI_StepCtr_Init(step_algo, initial_dtime, min_dtime, max_dtime, status)` |
| SUBROUTINE | `AI_StepCtr_Finalize` | 103 | `SUBROUTINE AI_StepCtr_Finalize(step_algo, status)` |
| SUBROUTINE | `AI_StepCtr_Predict` | 127 | `SUBROUTINE AI_StepCtr_Predict(step_algo, suggested_dtime, status)` |
| SUBROUTINE | `AI_StepCtr_Update` | 150 | `SUBROUTINE AI_StepCtr_Update(step_algo, current_time, truncation_error, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
