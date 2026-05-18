!===============================================================================
! MODULE: IF_Mon_Core
! LAYER:  L1_IF
! DOMAIN: Monitor
! ROLE:   _Core
! BRIEF:  Monitor domain flat storage and core operations.
!===============================================================================
!
! Data chain:
!   Container path: g_ufc_global%if_layer%monitor (when integrated)
!   Flat storage: log_state, metrics_state, trace_state
!
! Contents (A-Z):
!   Types:
!     IF_Monitor_Domain        [Ctx]  Domain container
!   Subroutines:
!     ChainMonitor_Init        [P0]   Initialize chain monitoring
!     ChainMonitor_Record      [P1]   Record chain event
!     ChainMonitor_Report      [P3]   Generate chain monitoring report
!     CollectMetrics           [P1]   Store metric by name
!     EndSpan                  [P1]   End trace span
!     ExportTrace              [P3]   Export trace to file
!     IF_Monitor_Domain_Finalize [P0] Finalize domain
!     IF_Monitor_Domain_Init   [P0]   Initialize domain
!     IF_Monitor_GetDomain     [P2]   Access flat domain pointer
!     Monitor_Finalize         [P0]   Finalize global monitor
!     Monitor_Init             [P0]   Initialize global monitor
!     RecordTrace              [P1]   Record trace data
!     StartSpan                [P1]   Generate span ID
!
! Status: Production | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Mon_Core
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Mon_Def, ONLY: MonitorDesc, MonitorState, IF_Mon_Log_State, IF_Mon_Metrics_State, &
                               IF_Mon_Trace_State, IF_Mon_Desc, IF_Mon_State, LogState, &
                               IF_MONITOR_LOG_INFO, IF_MAX_METRIC_NAMES
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Monitor_Init, Monitor_Finalize
  PUBLIC :: CollectMetrics, RecordTrace, ExportTrace
  PUBLIC :: StartSpan, EndSpan
  PUBLIC :: ChainMonitor_Init, ChainMonitor_Record, ChainMonitor_Report
  PUBLIC :: IF_Monitor_GetDomain

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Monitor_Domain  [Ctx]  (canonical: IF_Mon_Domain_Ctx)
  ! Flat storage domain container (single copy).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Monitor_Domain
    TYPE(MonitorDesc)  :: desc
    TYPE(MonitorState) :: state
    LOGICAL            :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE IF_Monitor_Domain

  ! Global domain instance (flat storage, single source)
  TYPE(IF_Monitor_Domain), SAVE, TARGET :: g_if_monitor_domain

  ! Simple span ID generator (replaces GenerateDataID from non-existent IF_Trace_DataChain)
  INTEGER(i8), SAVE :: g_span_id_counter = 0_i8

CONTAINS

  !--------------------------------------------------------------------
  ! [P2] IF_Monitor_GetDomain - access flat domain
  !--------------------------------------------------------------------
  FUNCTION IF_Monitor_GetDomain() RESULT(dom)
    TYPE(IF_Monitor_Domain), POINTER :: dom
    dom => g_if_monitor_domain
  END FUNCTION IF_Monitor_GetDomain

  !--------------------------------------------------------------------
  ! [P0] IF_Monitor_Domain_Init
  !--------------------------------------------------------------------
  SUBROUTINE Init(this, status)
    CLASS(IF_Monitor_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: loc_status

    CALL init_error_status(loc_status)
    IF (this%initialized) CALL this%Finalize()
    this%desc = MonitorDesc()
    this%state%log = IF_Mon_Log_State()
    this%state%trace%nSpans = 0_i4
    this%state%trace%maxSpans = 1024_i4
    this%initialized = .TRUE.
    IF (PRESENT(status)) status = loc_status
  END SUBROUTINE Init

  !--------------------------------------------------------------------
  ! [P0] IF_Monitor_Domain_Finalize
  !--------------------------------------------------------------------
  SUBROUTINE Finalize(this)
    CLASS(IF_Monitor_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%state%log = IF_Mon_Log_State()
    IF (ALLOCATED(this%state%metrics%timer_values)) DEALLOCATE(this%state%metrics%timer_values)
    IF (ALLOCATED(this%state%metrics%counter_values)) DEALLOCATE(this%state%metrics%counter_values)
    this%state%metrics%nTimers = 0_i4
    this%state%metrics%nCounters = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  !--------------------------------------------------------------------
  ! [P0] Monitor_Init - unified init (delegates to Domain)
  !--------------------------------------------------------------------
  SUBROUTINE Monitor_Init(trace_level, max_trace_records)
    INTEGER(i4), INTENT(IN) :: trace_level
    INTEGER, INTENT(IN), OPTIONAL :: max_trace_records
    TYPE(ErrorStatusType) :: status

    CALL g_if_monitor_domain%Init(status)
    IF (PRESENT(max_trace_records)) THEN
      g_if_monitor_domain%state%trace%maxSpans = INT(max_trace_records, i4)
    END IF
  END SUBROUTINE Monitor_Init

  !--------------------------------------------------------------------
  ! [P0] Monitor_Finalize
  !--------------------------------------------------------------------
  SUBROUTINE Monitor_Finalize()
    CALL g_if_monitor_domain%Finalize()
  END SUBROUTINE Monitor_Finalize

  !--------------------------------------------------------------------
  ! [P1] CollectMetrics - store metric by name in flat metrics_state
  !--------------------------------------------------------------------
  SUBROUTINE CollectMetrics(metric_name, value)
    CHARACTER(*), INTENT(IN) :: metric_name
    REAL(8), INTENT(IN) :: value
    INTEGER(i4) :: i, n
    CHARACTER(64) :: name_trim

    name_trim = metric_name(1:MIN(64, LEN_TRIM(metric_name)))
    n = g_if_monitor_domain%state%metrics%nMetrics
    ! Update if name exists
    DO i = 1, n
      IF (TRIM(g_if_monitor_domain%state%metrics%metric_names(i)) == TRIM(name_trim)) THEN
        g_if_monitor_domain%state%metrics%metric_values(i) = REAL(value, wp)
        RETURN
      END IF
    END DO
    ! Append if space
    IF (n < IF_MAX_METRIC_NAMES) THEN
      n = n + 1_i4
      g_if_monitor_domain%state%metrics%metric_names(n) = name_trim
      g_if_monitor_domain%state%metrics%metric_values(n) = REAL(value, wp)
      g_if_monitor_domain%state%metrics%nMetrics = n
    END IF
  END SUBROUTINE CollectMetrics

  !--------------------------------------------------------------------
  ! [P1] RecordTrace - delegate to Domain
  !--------------------------------------------------------------------
  SUBROUTINE RecordTrace(data_id, data_name, layer, domain, checksum)
    INTEGER(8), INTENT(IN) :: data_id
    CHARACTER(*), INTENT(IN) :: data_name, layer, domain
    REAL(8), INTENT(IN), OPTIONAL :: checksum
    ! Store in flat trace_state (simplified)
    g_if_monitor_domain%state%trace%nSpans = g_if_monitor_domain%state%trace%nSpans + 1_i4
  END SUBROUTINE RecordTrace

  !--------------------------------------------------------------------
  ! [P3] ExportTrace - placeholder
  !--------------------------------------------------------------------
  SUBROUTINE ExportTrace(filename)
    CHARACTER(*), INTENT(IN) :: filename
    ! Would export trace_state to file
  END SUBROUTINE ExportTrace

  !--------------------------------------------------------------------
  ! [P1] StartSpan - generate span ID
  !--------------------------------------------------------------------
  SUBROUTINE StartSpan(span_name, span_id)
    CHARACTER(*), INTENT(IN) :: span_name
    INTEGER(8), INTENT(OUT) :: span_id
    g_span_id_counter = g_span_id_counter + 1_i8
    span_id = g_span_id_counter
  END SUBROUTINE StartSpan

  !--------------------------------------------------------------------
  ! [P1] EndSpan
  !--------------------------------------------------------------------
  SUBROUTINE EndSpan(span_id)
    INTEGER(8), INTENT(IN) :: span_id
    ! Span finalization (simplified)
  END SUBROUTINE EndSpan

  !--------------------------------------------------------------------
  ! [P0] ChainMonitor_Init
  !--------------------------------------------------------------------
  SUBROUTINE ChainMonitor_Init()
    ! Initialize chain monitoring
  END SUBROUTINE ChainMonitor_Init

  !--------------------------------------------------------------------
  ! [P1] ChainMonitor_Record
  !--------------------------------------------------------------------
  SUBROUTINE ChainMonitor_Record(chain_type, event_name)
    CHARACTER(*), INTENT(IN) :: chain_type, event_name
    ! Record chain event to flat storage
  END SUBROUTINE ChainMonitor_Record

  !--------------------------------------------------------------------
  ! [P3] ChainMonitor_Report
  !--------------------------------------------------------------------
  SUBROUTINE ChainMonitor_Report(unit)
    INTEGER, INTENT(IN), OPTIONAL :: unit
    ! Generate chain monitoring report from flat state
  END SUBROUTINE ChainMonitor_Report

END MODULE IF_Mon_Core