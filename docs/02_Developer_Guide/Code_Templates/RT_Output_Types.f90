!==============================================================================!
! MODULE RT_Output_Types
! Layer  : L5_RT  (When / run-time orchestration)
! Domain : Output  –  run-time output request execution state
!
! Four TYPE kinds:
!   RT_FieldOut_State  – field output (ODB frame) write state
!   RT_HistOut_State   – history output (ODB xy-data) accumulation state
!   RT_Output_Ctx      – call-scoped context passed to output dispatchers
!   RT_WriteCtrl_Algo  – write frequency / throttle algorithmic parameters
!==============================================================================!
MODULE RT_Output_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! Output trigger type constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_OUT_TRIG_TIME_INTERVAL  = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_OUT_TRIG_INC_INTERVAL   = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_OUT_TRIG_STEP_END       = 3_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_OUT_TRIG_EVERY_INC      = 4_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_OUT_TRIG_OUT_TRIG_USER           = 5_i4  ! UEXTERNALDB  ! migrated

  ! ------------------------------------------------------------------ !
  ! RT_FieldOut_State
  !   Tracks the run-time progress of field output (ODB frame) writes
  !   for the current step.  One instance per *OUTPUT, FIELD block.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_FieldOut_State
    INTEGER(i4) :: n_frames_written  = 0_i4   ! frames written this step
    INTEGER(i4) :: n_frames_max      = 0_i4   ! 0 = unlimited
    REAL(wp)    :: t_last_written    = -HUGE(1.0_wp)  ! time of last frame
    REAL(wp)    :: t_next_due        = 0.0_wp  ! next scheduled write time
    INTEGER(i4) :: inc_last_written  = -1_i4  ! increment of last write
    LOGICAL     :: suppress_this_inc = .FALSE. ! skip write for current inc
    LOGICAL     :: write_pending     = .FALSE. ! triggered but not yet written
    TYPE(ErrorStatusType) :: status
  END TYPE RT_FieldOut_State

  ! ------------------------------------------------------------------ !
  ! RT_HistOut_State
  !   Tracks history output (ODB xy-data / .dat tabular output) state.
  !   One instance per *OUTPUT, HISTORY block.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_HistOut_State
    INTEGER(i4) :: n_points_written  = 0_i4   ! total xy-data points written
    REAL(wp)    :: t_last_written    = -HUGE(1.0_wp)
    REAL(wp)    :: t_next_due        = 0.0_wp
    INTEGER(i4) :: n_vars            = 0_i4   ! number of output variables
    LOGICAL     :: buffer_active     = .FALSE. ! in-memory buffer not flushed
    INTEGER(i4) :: buffer_count      = 0_i4   ! points in current buffer
    INTEGER(i4) :: buffer_max        = 128_i4 ! max points before flush
    TYPE(ErrorStatusType) :: status
  END TYPE RT_HistOut_State

  ! ------------------------------------------------------------------ !
  ! RT_Output_Ctx
  !   Call-scoped context passed to output dispatcher routines.
  !   Aggregates current time/increment/step info needed for output logic.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Output_Ctx
    INTEGER(i4) :: step_id           = 0_i4   ! current step number (1-based)
    INTEGER(i4) :: inc_id            = 0_i4   ! current increment number
    REAL(wp)    :: step_time         = 0.0_wp  ! time within step
    REAL(wp)    :: total_time        = 0.0_wp  ! total analysis time
    REAL(wp)    :: dtime             = 0.0_wp  ! current time increment
    LOGICAL     :: is_step_end       = .FALSE.
    LOGICAL     :: is_analysis_end   = .FALSE.
    LOGICAL     :: force_write       = .FALSE. ! override: write regardless of trigger
    INTEGER(i4) :: trig_type        = OUT_TRIG_INC_INTERVAL
  END TYPE RT_Output_Ctx

  ! ------------------------------------------------------------------ !
  ! RT_WriteCtrl_Algo
  !   Algorithmic parameters controlling write frequency throttling,
  !   buffer sizes, and ODB compression strategy.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_WriteCtrl_Algo
    INTEGER(i4) :: field_interval    = 1_i4   ! write field every N increments
    INTEGER(i4) :: hist_interval     = 1_i4   ! write history every N increments
    REAL(wp)    :: field_time_intv   = 0.0_wp  ! min time between field writes (0=off)
    REAL(wp)    :: hist_time_intv    = 0.0_wp
    LOGICAL     :: compress_odb      = .FALSE. ! enable ODB compression
    LOGICAL     :: lock_odb_between  = .TRUE.  ! hold ODB file lock between writes
    INTEGER(i4) :: flush_freq        = 10_i4  ! flush buffer every N writes
    INTEGER(i4) :: max_odb_size_mb   = 0_i4   ! 0 = unlimited
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WriteCtrl_Algo

END MODULE RT_Output_Types
