!===============================================================================
! MODULE: IF_Mon_Def
! LAYER:  L1_IF
! DOMAIN: Monitor
! ROLE:   _Def
! BRIEF:  Monitor domain type definitions (Desc/Ctx/State).
!===============================================================================
!
! TYPE Four-Type Mapping:
!   IF_Mon_Log_State     [State] Flat log statistics
!   IF_Mon_Metrics_State [State] Flat metrics storage
!   IF_Mon_Trace_State   [State] Flat trace span storage
!   IF_Mon_Desc          [Desc]  Config descriptor
!   IF_Mon_Ctx           [Ctx]   Context (aggregates Desc + refs)
!   IF_Mon_State         [State] Flat domain state (single copy)
!
! Constants: IF_MONITOR_LOG_*, IF_MAX_METRIC_NAMES
!
! Status: Production | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Mon_Def
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  ! Log level constants (align with IF_Log)
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MONITOR_LOG_ERROR   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MONITOR_LOG_WARNING = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MONITOR_LOG_INFO    = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MONITOR_LOG_DEBUG   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MONITOR_LOG_TRACE  = 5_i4

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Mon_Log_State  [State]
  ! Flat log statistics (index tree references config only).
  !-----------------------------------------------------------------------------
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

  ! [LEGACY] backward compatibility
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

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Mon_Metrics_State  [State]
  ! Flat metrics storage.
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: IF_MAX_METRIC_NAMES = 64_i4
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

  ! [LEGACY] backward compatibility
  TYPE, PUBLIC :: MetricsState
    INTEGER(i4) :: nTimers   = 0_i4
    INTEGER(i4) :: nCounters = 0_i4
    REAL(wp), ALLOCATABLE :: timer_values(:)
    INTEGER(i8), ALLOCATABLE :: counter_values(:)
    CHARACTER(64) :: metric_names(IF_MAX_METRIC_NAMES) = ""
    REAL(wp)      :: metric_values(IF_MAX_METRIC_NAMES) = 0.0_wp
    INTEGER(i4)   :: nMetrics = 0_i4
  END TYPE MetricsState

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Mon_Trace_State  [State]
  ! Flat trace span storage (placeholder for spans array).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Mon_Trace_State
    INTEGER(i4) :: nSpans    = 0_i4
    INTEGER(i4) :: maxSpans  = 1024_i4
  END TYPE IF_Mon_Trace_State

  ! [LEGACY] backward compatibility
  TYPE, PUBLIC :: TraceState
    INTEGER(i4) :: nSpans    = 0_i4
    INTEGER(i4) :: maxSpans  = 1024_i4
  END TYPE TraceState

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Mon_Desc  [Desc]
  ! Monitor config descriptor (index tree).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Mon_Desc
    INTEGER(i4) :: verbosity   = IF_MONITOR_LOG_INFO
    INTEGER(i4) :: logUnit     = 6_i4
    LOGICAL     :: logToFile   = .TRUE.
    LOGICAL     :: logTimestamp = .TRUE.
    LOGICAL     :: metricsEnabled = .TRUE.
    LOGICAL     :: traceEnabled   = .FALSE.
  END TYPE IF_Mon_Desc

  ! [LEGACY] backward compatibility
  TYPE, PUBLIC :: MonitorDesc
    INTEGER(i4) :: verbosity   = IF_MONITOR_LOG_INFO
    INTEGER(i4) :: logUnit     = 6_i4
    LOGICAL     :: logToFile   = .TRUE.
    LOGICAL     :: logTimestamp = .TRUE.
    LOGICAL     :: metricsEnabled = .TRUE.
    LOGICAL     :: traceEnabled   = .FALSE.
  END TYPE MonitorDesc

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Mon_Ctx  [Ctx]
  ! Monitor context (aggregates Desc + refs).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Mon_Ctx
    TYPE(IF_Mon_Desc) :: desc
  END TYPE IF_Mon_Ctx

  ! [LEGACY] backward compatibility
  TYPE, PUBLIC :: MonitorCtx
    TYPE(IF_Mon_Desc) :: desc
  END TYPE MonitorCtx

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Mon_State  [State]
  ! Flat domain state (single copy).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Mon_State
    TYPE(IF_Mon_Log_State)     :: log
    TYPE(IF_Mon_Metrics_State) :: metrics
    TYPE(IF_Mon_Trace_State)   :: trace
  END TYPE IF_Mon_State

  ! [LEGACY] backward compatibility
  TYPE, PUBLIC :: MonitorState
    TYPE(IF_Mon_Log_State)     :: log
    TYPE(IF_Mon_Metrics_State) :: metrics
    TYPE(IF_Mon_Trace_State)   :: trace
  END TYPE MonitorState

END MODULE IF_Mon_Def
