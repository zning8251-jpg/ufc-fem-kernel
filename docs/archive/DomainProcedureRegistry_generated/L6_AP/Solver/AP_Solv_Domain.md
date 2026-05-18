# `AP_Solv_Domain.f90`

- **Source**: `L6_AP/Solver/AP_Solv_Domain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Solv_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Solv_Domain`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Solv_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Solver/AP_Solv_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Solver_State_Progress` (lines 26–32)

```fortran
  TYPE, PUBLIC :: AP_Solver_State_Progress
    INTEGER(i4) :: jobPhase        = AP_JOB_NOT_STARTED
    INTEGER(i4) :: totalSteps      = 0_i4
    INTEGER(i4) :: completedSteps  = 0_i4
    INTEGER(i4) :: currentStepId   = 0_i4   ! step_idx
    INTEGER(i4) :: currentIncrIdx  = 0_i4   ! incr_idx [ L3→L6]
  END TYPE AP_Solver_State_Progress
```

### `AP_Solver_State_Timing` (lines 34–39)

```fortran
  TYPE, PUBLIC :: AP_Solver_State_Timing
    REAL(wp)    :: totalJobTime    = 0.0_wp  ! wall-clock total
    REAL(wp)    :: preProcessTime  = 0.0_wp
    REAL(wp)    :: solveTime       = 0.0_wp
    REAL(wp)    :: postProcessTime = 0.0_wp
  END TYPE AP_Solver_State_Timing
```

### `AP_Solver_State_Resources` (lines 41–43)

```fortran
  TYPE, PUBLIC :: AP_Solver_State_Resources
    REAL(wp)    :: peakMemoryMB   = 0.0_wp
  END TYPE AP_Solver_State_Resources
```

### `AP_Solver_State` (lines 45–49)

```fortran
  TYPE, PUBLIC :: AP_Solver_State
    TYPE(AP_Solver_State_Progress)  :: progress
    TYPE(AP_Solver_State_Timing)    :: timing
    TYPE(AP_Solver_State_Resources) :: resources
  END TYPE AP_Solver_State
```

### `AP_Solver_Ctrl` (lines 51–56)

```fortran
  TYPE, PUBLIC :: AP_Solver_Ctrl
    INTEGER(i4) :: nOMPThreads    = 0_i4     ! 0 = env default
    REAL(wp)    :: memoryLimitMB  = 0.0_wp   ! 0 = unlimited
    LOGICAL     :: dryRun         = .FALSE.  ! parse only, no solve
    LOGICAL     :: dataCheck      = .FALSE.  ! validate model only
  END TYPE AP_Solver_Ctrl
```

### `AP_Solver_RunJob_Arg` (lines 59–61)

```fortran
  TYPE, PUBLIC :: AP_Solver_RunJob_Arg
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Solver_RunJob_Arg
```

### `AP_Solver_SetOMPThreads_Arg` (lines 63–66)

```fortran
  TYPE, PUBLIC :: AP_Solver_SetOMPThreads_Arg
    INTEGER(i4) :: nOMP = 0_i4            ! (IN) 0 = env default
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Solver_SetOMPThreads_Arg
```

### `AP_Solver_GetSummary_Arg` (lines 68–71)

```fortran
  TYPE, PUBLIC :: AP_Solver_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = "" ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Solver_GetSummary_Arg
```

### `AP_Solver_Domain` (lines 73–83)

```fortran
  TYPE, PUBLIC :: AP_Solver_Domain
    TYPE(AP_Solver_State) :: state
    TYPE(AP_Solver_Ctrl)  :: ctrl
    LOGICAL               :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RunJob
    PROCEDURE :: SetOMPThreads
    PROCEDURE :: GetSummary
  END TYPE AP_Solver_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Solver_Domain_Finalize` | 87 | `SUBROUTINE AP_Solver_Domain_Finalize(this)` |
| SUBROUTINE | `AP_Solver_Domain_Init` | 94 | `SUBROUTINE AP_Solver_Domain_Init(this, status)` |
| SUBROUTINE | `AP_Solver_Domain_RunJob` | 107 | `SUBROUTINE AP_Solver_Domain_RunJob(this, arg)` |
| SUBROUTINE | `AP_Solver_RunJob_Impl` | 113 | `SUBROUTINE AP_Solver_RunJob_Impl(this, status)` |
| SUBROUTINE | `AP_Solver_Domain_SetOMPThreads` | 236 | `SUBROUTINE AP_Solver_Domain_SetOMPThreads(this, arg)` |
| SUBROUTINE | `AP_Solver_SetOMPThreads_Impl` | 242 | `SUBROUTINE AP_Solver_SetOMPThreads_Impl(this, nOMP, status)` |
| SUBROUTINE | `AP_Solver_Domain_GetSummary` | 275 | `SUBROUTINE AP_Solver_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `AP_Solver_GetSummary_Impl` | 281 | `SUBROUTINE AP_Solver_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
