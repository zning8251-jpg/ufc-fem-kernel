# `IF_Mon_Def.f90`

- **Source**: `L1_IF/Monitor/IF_Mon_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mon_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mon_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mon`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Monitor`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Monitor/IF_Mon_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Mon_Log_State` (lines 37–48)

```fortran
  TYPE, PUBLIC :: IF_Mon_Log_State
    INTEGER(i4) :: nErrors   = 0_i4
    INTEGER(i4) :: nWarnings = 0_i4
    INTEGER(i4) :: nInfo     = 0_i4
    INTEGER(i4) :: nDebug    = 0_i4
    INTEGER(i4) :: totalMsgs = 0_i4
    REAL(wp)    :: assemblyTimeTotal  = 0.0_wp
    REAL(wp)    :: solverTimeTotal    = 0.0_wp
    REAL(wp)    :: contactTimeTotal   = 0.0_wp
    REAL(wp)    :: outputTimeTotal    = 0.0_wp
    REAL(wp)    :: totalAnalysisTime  = 0.0_wp
  END TYPE IF_Mon_Log_State
```

### `LogState` (lines 51–62)

```fortran
  TYPE, PUBLIC :: LogState
    INTEGER(i4) :: nErrors   = 0_i4
    INTEGER(i4) :: nWarnings = 0_i4
    INTEGER(i4) :: nInfo     = 0_i4
    INTEGER(i4) :: nDebug    = 0_i4
    INTEGER(i4) :: totalMsgs = 0_i4
    REAL(wp)    :: assemblyTimeTotal  = 0.0_wp
    REAL(wp)    :: solverTimeTotal    = 0.0_wp
    REAL(wp)    :: contactTimeTotal   = 0.0_wp
    REAL(wp)    :: outputTimeTotal    = 0.0_wp
    REAL(wp)    :: totalAnalysisTime  = 0.0_wp
  END TYPE LogState
```

### `IF_Mon_Metrics_State` (lines 69–78)

```fortran
  TYPE, PUBLIC :: IF_Mon_Metrics_State
    INTEGER(i4) :: nTimers   = 0_i4
    INTEGER(i4) :: nCounters = 0_i4
    REAL(wp), ALLOCATABLE :: timer_values(:)
    INTEGER(i8), ALLOCATABLE :: counter_values(:)
    ! Named metrics (CollectMetrics)
    CHARACTER(64) :: metric_names(IF_MAX_METRIC_NAMES) = ""
    REAL(wp)      :: metric_values(IF_MAX_METRIC_NAMES) = 0.0_wp
    INTEGER(i4)   :: nMetrics = 0_i4
  END TYPE IF_Mon_Metrics_State
```

### `MetricsState` (lines 81–89)

```fortran
  TYPE, PUBLIC :: MetricsState
    INTEGER(i4) :: nTimers   = 0_i4
    INTEGER(i4) :: nCounters = 0_i4
    REAL(wp), ALLOCATABLE :: timer_values(:)
    INTEGER(i8), ALLOCATABLE :: counter_values(:)
    CHARACTER(64) :: metric_names(IF_MAX_METRIC_NAMES) = ""
    REAL(wp)      :: metric_values(IF_MAX_METRIC_NAMES) = 0.0_wp
    INTEGER(i4)   :: nMetrics = 0_i4
  END TYPE MetricsState
```

### `IF_Mon_Trace_State` (lines 95–98)

```fortran
  TYPE, PUBLIC :: IF_Mon_Trace_State
    INTEGER(i4) :: nSpans    = 0_i4
    INTEGER(i4) :: maxSpans  = 1024_i4
  END TYPE IF_Mon_Trace_State
```

### `TraceState` (lines 101–104)

```fortran
  TYPE, PUBLIC :: TraceState
    INTEGER(i4) :: nSpans    = 0_i4
    INTEGER(i4) :: maxSpans  = 1024_i4
  END TYPE TraceState
```

### `IF_Mon_Desc` (lines 110–117)

```fortran
  TYPE, PUBLIC :: IF_Mon_Desc
    INTEGER(i4) :: verbosity   = IF_MONITOR_LOG_INFO
    INTEGER(i4) :: logUnit     = 6_i4
    LOGICAL     :: logToFile   = .TRUE.
    LOGICAL     :: logTimestamp = .TRUE.
    LOGICAL     :: metricsEnabled = .TRUE.
    LOGICAL     :: traceEnabled   = .FALSE.
  END TYPE IF_Mon_Desc
```

### `MonitorDesc` (lines 120–127)

```fortran
  TYPE, PUBLIC :: MonitorDesc
    INTEGER(i4) :: verbosity   = IF_MONITOR_LOG_INFO
    INTEGER(i4) :: logUnit     = 6_i4
    LOGICAL     :: logToFile   = .TRUE.
    LOGICAL     :: logTimestamp = .TRUE.
    LOGICAL     :: metricsEnabled = .TRUE.
    LOGICAL     :: traceEnabled   = .FALSE.
  END TYPE MonitorDesc
```

### `IF_Mon_Ctx` (lines 133–135)

```fortran
  TYPE, PUBLIC :: IF_Mon_Ctx
    TYPE(IF_Mon_Desc) :: desc
  END TYPE IF_Mon_Ctx
```

### `MonitorCtx` (lines 138–140)

```fortran
  TYPE, PUBLIC :: MonitorCtx
    TYPE(IF_Mon_Desc) :: desc
  END TYPE MonitorCtx
```

### `IF_Mon_State` (lines 146–150)

```fortran
  TYPE, PUBLIC :: IF_Mon_State
    TYPE(IF_Mon_Log_State)     :: log
    TYPE(IF_Mon_Metrics_State) :: metrics
    TYPE(IF_Mon_Trace_State)   :: trace
  END TYPE IF_Mon_State
```

### `MonitorState` (lines 153–157)

```fortran
  TYPE, PUBLIC :: MonitorState
    TYPE(IF_Mon_Log_State)     :: log
    TYPE(IF_Mon_Metrics_State) :: metrics
    TYPE(IF_Mon_Trace_State)   :: trace
  END TYPE MonitorState
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
