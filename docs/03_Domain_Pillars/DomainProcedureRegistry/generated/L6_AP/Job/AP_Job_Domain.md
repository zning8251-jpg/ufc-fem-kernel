# `AP_Job_Domain.f90`

- **Source**: `L6_AP/Job/AP_Job_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Job_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Job_Domain`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Job_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Job`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Job/AP_Job_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Job_Metrics` (lines 40–50)

```fortran
  TYPE, PUBLIC :: AP_Job_Metrics
    REAL(wp)    :: cpuTime            = 0.0_wp
    REAL(wp)    :: wallTime           = 0.0_wp
    INTEGER(i8) :: memoryUsed      = 0_i8
    INTEGER(i8) :: memoryPeak      = 0_i8
    INTEGER(i8) :: diskIO          = 0_i8
    INTEGER(i4) :: nStepsCompleted    = 0_i4
    INTEGER(i4) :: nIncrementsCompleted = 0_i4
    INTEGER(i4) :: nIterationsTotal   = 0_i4
    INTEGER(i4) :: nRollbacks         = 0_i4
  END TYPE AP_Job_Metrics
```

### `AP_Job_State` (lines 52–61)

```fortran
  TYPE, PUBLIC :: AP_Job_State
    INTEGER(i8) :: jobId        = 0_i8
    CHARACTER(LEN=256) :: jobName  = ''
    INTEGER(i4)    :: status       = JOB_STATUS_INIT
    INTEGER(i4)    :: totalSteps   = 0_i4
    INTEGER(i4)    :: currentStep  = 0_i4   ! step_idx
    INTEGER(i4)    :: currentIncrIdx = 0_i4 ! incr_idx [??? L3?L6]
    REAL(wp)       :: progress     = 0.0_wp
    TYPE(AP_Job_Metrics) :: metrics
  END TYPE AP_Job_State
```

### `AP_Job_Ctrl` (lines 63–67)

```fortran
  TYPE, PUBLIC :: AP_Job_Ctrl
    REAL(wp)    :: maxCpuTime   = 0.0_wp     ! 0 = unlimited
    INTEGER(i8) :: maxMemory = 0_i8    ! 0 = unlimited
    LOGICAL     :: limitsSet    = .FALSE.
  END TYPE AP_Job_Ctrl
```

### `AP_Job_Run_Arg` (lines 70–72)

```fortran
  TYPE, PUBLIC :: AP_Job_Run_Arg
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_Run_Arg
```

### `AP_Job_Pause_Arg` (lines 74–76)

```fortran
  TYPE, PUBLIC :: AP_Job_Pause_Arg
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_Pause_Arg
```

### `AP_Job_Abort_Arg` (lines 78–81)

```fortran
  TYPE, PUBLIC :: AP_Job_Abort_Arg
    CHARACTER(LEN=256)    :: reason = ''  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_Abort_Arg
```

### `AP_Job_RollbackToStep_Arg` (lines 83–86)

```fortran
  TYPE, PUBLIC :: AP_Job_RollbackToStep_Arg
    INTEGER(i4)           :: stepId = 0_i4  ! (IN) step_idx for rollback
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_RollbackToStep_Arg
```

### `AP_Job_RecordResource_Arg` (lines 88–92)

```fortran
  TYPE, PUBLIC :: AP_Job_RecordResource_Arg
    REAL(wp)       :: cpuTime    = 0.0_wp    ! (IN)
    INTEGER(i8) :: memoryUsed = 0_i8   ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_RecordResource_Arg
```

### `AP_Job_GetSummary_Arg` (lines 94–97)

```fortran
  TYPE, PUBLIC :: AP_Job_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ''  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Job_GetSummary_Arg
```

### `AP_JobDomain` (lines 99–112)

```fortran
  TYPE, PUBLIC :: AP_JobDomain
    TYPE(AP_Job_State)  :: state
    TYPE(AP_Job_Ctrl)   :: ctrl
    LOGICAL             :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Run
    PROCEDURE :: Pause
    PROCEDURE :: Abort
    PROCEDURE :: RollbackToStep
    PROCEDURE :: RecordResource
    PROCEDURE :: GetSummary
  END TYPE AP_JobDomain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Job_Domain_Finalize` | 116 | `SUBROUTINE AP_Job_Domain_Finalize(this)` |
| SUBROUTINE | `AP_Job_Domain_Init` | 123 | `SUBROUTINE AP_Job_Domain_Init(this, jobName, totalSteps, status)` |
| SUBROUTINE | `AP_Job_Domain_Run` | 148 | `SUBROUTINE AP_Job_Domain_Run(this, arg)` |
| SUBROUTINE | `AP_Job_Run_Impl` | 154 | `SUBROUTINE AP_Job_Run_Impl(this, status)` |
| SUBROUTINE | `AP_Job_Domain_Pause` | 176 | `SUBROUTINE AP_Job_Domain_Pause(this, arg)` |
| SUBROUTINE | `AP_Job_Pause_Impl` | 182 | `SUBROUTINE AP_Job_Pause_Impl(this, status)` |
| SUBROUTINE | `AP_Job_Domain_Abort` | 203 | `SUBROUTINE AP_Job_Domain_Abort(this, arg)` |
| SUBROUTINE | `AP_Job_Abort_Impl` | 209 | `SUBROUTINE AP_Job_Abort_Impl(this, reason, status)` |
| SUBROUTINE | `AP_Job_Domain_RollbackToStep` | 226 | `SUBROUTINE AP_Job_Domain_RollbackToStep(this, arg)` |
| SUBROUTINE | `AP_Job_RollbackToStep_Impl` | 232 | `SUBROUTINE AP_Job_RollbackToStep_Impl(this, stepId, status)` |
| SUBROUTINE | `AP_Job_Domain_RecordResource` | 255 | `SUBROUTINE AP_Job_Domain_RecordResource(this, arg)` |
| SUBROUTINE | `AP_Job_RecordResource_Impl` | 261 | `SUBROUTINE AP_Job_RecordResource_Impl(this, cpuTime, memoryUsed, status)` |
| SUBROUTINE | `AP_Job_Domain_GetSummary` | 282 | `SUBROUTINE AP_Job_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `AP_Job_GetSummary_Impl` | 288 | `SUBROUTINE AP_Job_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
