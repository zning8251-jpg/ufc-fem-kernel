!===============================================================================
! Module: PH_Analysis_Types                                      [Template v1.0]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Analysis Control — Ctx / State / Algo for analysis-level events
!
! Purpose:
!   Defines the full Ctx / State / Algo three-type system for analysis
!   control at the PH_ layer.  Covers:
!   - UEXTERNALDB : Analysis lifecycle event handler (LOP=0/1/2/3/4)
!   - UAMP / VUAMP: User-defined amplitude function
!   - UVARM       : User-defined output variable at material points
!
! Design principle:
!   Analysis domain PH_ layer handles cross-cutting concerns:
!   - UEXTERNALDB: database I/O, external coupling at analysis lifecycle events
!   - UAMP: time-varying amplitude functions for loads/BCs
!   - UVARM: custom post-processing variables per material point
!
! Abaqus parameter map (UEXTERNALDB):
!   LOP=0 : Analysis start (open files, init external data)
!   LOP=1 : Each increment start (sync external state)
!   LOP=2 : Analysis end (close files, finalize)
!   LOP=3 : Each step end
!   LOP=4 : Restart read (recover external state)
!
! Abaqus parameter map (UAMP):
!   TIME    → time_current   current analysis time
!   AMPVAL  → amp_val        amplitude value (OUTPUT)
!   DAMP    → d_amp          d(amp)/d(time) (OUTPUT)
!
! Layer dependency:
!   USE IF_Prec      (wp, i4)
!   USE IF_Err_Brg   (structured ErrorStatusType status; baseline vocabulary:
!                     init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE PH_Analysis_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Analy_Base_Ctx
  PUBLIC :: PH_Analy_Base_State
  PUBLIC :: PH_Analy_Base_Algo
  PUBLIC :: PH_Analy_UAMP_Ctx
  PUBLIC :: PH_Analy_UVARM_Ctx

  !-- LOP event code constants (UEXTERNALDB)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOP_LOP_ANALYSIS_START  = 0_i4  ! LOP=0: start  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOP_LOP_INCREMENT_START = 1_i4  ! LOP=1: incr  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOP_LOP_ANALYSIS_END    = 2_i4  ! LOP=2: end  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOP_LOP_STEP_END        = 3_i4  ! LOP=3: step end  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOP_LOP_RESTART_READ    = 4_i4  ! LOP=4: restart  ! migrated

  !-----------------------------------------------------------------------------
  ! CTX — Analysis Control Context (analysis lifecycle event driving inputs)
  !   UEXTERNALDB: called at analysis lifecycle events
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_Base_Ctx
    !-- Event identification
    INTEGER(i4) :: lop   = 0_i4        ! LOP: lifecycle event code (0-4)
    INTEGER(i4) :: lrestart = 0_i4     ! LRESTART: restart write flag
    !-- Temporal context
    REAL(wp) :: time_current = 0.0_wp  ! TIME(1): current step time
    REAL(wp) :: time_total   = 0.0_wp  ! TIME(2): total analysis time
    REAL(wp) :: dtime        = 0.0_wp  ! DT: time increment
    INTEGER(i4) :: kstep = 0_i4        ! KSTEP: step number
    INTEGER(i4) :: kinc  = 0_i4        ! KINC: increment number
    !-- Job identification
    CHARACTER(LEN=256) :: jobname    = ''  ! Job name (from GETJOBNAME)
    CHARACTER(LEN=256) :: outdir     = ''  ! Output directory
    !-- Analysis dimensions
    INTEGER(i4) :: noel   = 0_i4       ! Total number of elements
    INTEGER(i4) :: nnode  = 0_i4       ! Total number of nodes
  END TYPE PH_Analy_Base_Ctx

  !-----------------------------------------------------------------------------
  ! STATE — Analysis Control Output / Status
  !   UEXTERNALDB writes external data; State tracks completion status
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_Base_State
    !-- Event completion status
    LOGICAL     :: event_handled = .FALSE.   ! Event processed successfully
    INTEGER(i4) :: files_open   = 0_i4       ! Number of open external files
    !-- Data synchronisation status
    LOGICAL     :: data_written = .FALSE.    ! External data written this event
    LOGICAL     :: data_read    = .FALSE.    ! External data read this event
    !-- Convergence bookkeeping
    LOGICAL     :: converged = .TRUE.        ! Always TRUE for UEXTERNALDB
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Analy_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Analysis Control Algorithm Configuration
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_Base_Algo
    !-- Event trigger control
    LOGICAL :: call_on_start    = .TRUE.    ! Call at LOP=0?
    LOGICAL :: call_on_incr     = .TRUE.    ! Call at LOP=1?
    LOGICAL :: call_on_end      = .TRUE.    ! Call at LOP=2?
    LOGICAL :: call_on_step_end = .FALSE.   ! Call at LOP=3?
    LOGICAL :: call_on_restart  = .FALSE.   ! Call at LOP=4?
    !-- File handling
    INTEGER(i4) :: max_files = 10           ! Max open files
    LOGICAL     :: auto_close = .TRUE.      ! Auto close files at LOP=2
    !-- Output frequency
    INTEGER(i4) :: output_every = 1_i4     ! Write every N increments
  END TYPE PH_Analy_Base_Algo

  !-----------------------------------------------------------------------------
  ! PH_Analy_UAMP_Ctx — UAMP / VUAMP: user-defined amplitude function
  !   UAMP provides amplitude value and its derivative at given time.
  !   VUAMP: Explicit vectorised version (block of time values).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UAMP_Ctx
    !-- Amplitude identification
    CHARACTER(LEN=80) :: ampname = ''      ! AMPNAME: amplitude table name
    !-- Temporal inputs
    REAL(wp) :: time_current = 0.0_wp      ! TIME(1): step time
    REAL(wp) :: time_total   = 0.0_wp      ! TIME(2): total time
    REAL(wp) :: dtime        = 0.0_wp      ! DT: time increment
    INTEGER(i4) :: kstep = 0_i4
    INTEGER(i4) :: kinc  = 0_i4
    !-- Previous amplitude value (for smoothing/continuity)
    REAL(wp) :: amp_prev     = 0.0_wp      ! Amplitude at start of increment
    REAL(wp) :: d_amp_prev   = 0.0_wp      ! d(amp)/d(t) at start
    !-- Step period
    REAL(wp) :: period       = 0.0_wp      ! PERIOD: step period [s]
    !-- VUAMP block support
    LOGICAL  :: is_explicit  = .FALSE.     ! .TRUE. for VUAMP
    INTEGER(i4) :: nblock    = 1_i4        ! Block size for VUAMP
    REAL(wp), POINTER :: time_blk(:)   ! Time values [nblock] for VUAMP
    !-- Output: amplitude value and tangent
    REAL(wp) :: amp_val      = 0.0_wp      ! AMPVAL: amplitude value (output)
    REAL(wp) :: d_amp        = 0.0_wp      ! DAMP: d(amp)/d(time) (output)
    REAL(wp) :: d2_amp       = 0.0_wp      ! Second derivative (optional)
    !-- VUAMP output [nblock]
    REAL(wp), POINTER :: amp_blk(:)    ! Block amplitude values
    REAL(wp), POINTER :: d_amp_blk(:)  ! Block derivatives
  END TYPE PH_Analy_UAMP_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Analy_UVARM_Ctx — UVARM: user-defined output variables at material points
  !   Called during output requests to compute custom post-processing variables.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UVARM_Ctx
    !-- Material point identification
    INTEGER(i4) :: elem_id      = 0_i4   ! NOEL: element number
    INTEGER(i4) :: integ_pt_id  = 0_i4   ! NPT: integration point
    INTEGER(i4) :: layer_id     = 0_i4   ! LAYER
    INTEGER(i4) :: kspt         = 0_i4   ! KSPT
    !-- Material name
    CHARACTER(LEN=80) :: cmname = ''
    !-- Number of user output variables
    INTEGER(i4) :: nuvarm = 0_i4         ! NUVARM: number of output vars
    INTEGER(i4) :: nstatv = 0_i4         ! NSTATV: state variable count
    !-- Material state (from ABAQUS, read-only via GETVRM)
    REAL(wp) :: stress(6)  = 0.0_wp      ! Current stress tensor [Pa]
    REAL(wp) :: strain(6)  = 0.0_wp      ! Current strain tensor
    REAL(wp) :: peeq       = 0.0_wp      ! Equivalent plastic strain
    REAL(wp), POINTER :: statev(:)   ! State variables [nstatv]
    !-- Coordinates
    REAL(wp) :: coords(3)  = 0.0_wp
    !-- Temporal context
    REAL(wp) :: time_current = 0.0_wp
    REAL(wp) :: time_total   = 0.0_wp
    INTEGER(i4) :: kstep = 0_i4
    INTEGER(i4) :: kinc  = 0_i4
    !-- Output: user variables UVARM(NUVARM)
    REAL(wp), POINTER :: uvarm(:)    ! [nuvarm] computed output values
  END TYPE PH_Analy_UVARM_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Analy_UEXTERNALDB_State — UEXTERNALDB lifecycle event output state
  !   LOP-triggered response: external database sync / initialization status
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UEXTERNALDB_State
    INTEGER(i4) :: lop_processed = -1_i4  ! LOP value that was handled
    LOGICAL     :: db_open       = .FALSE. ! External DB is open
    LOGICAL     :: db_sync_ok    = .FALSE. ! Last sync succeeded
    LOGICAL     :: converged     = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Analy_UEXTERNALDB_State

  !-----------------------------------------------------------------------------
  ! PH_Analy_UAMP_State — UAMP amplitude output state
  !   AMP_VAL and DAMP_VAL written back by user
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UAMP_State
    REAL(wp) :: amp_val    = 0.0_wp  ! OUT: amplitude value at time_current
    REAL(wp) :: d_amp      = 0.0_wp  ! OUT: d(amplitude)/d(time)
    LOGICAL  :: converged  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Analy_UAMP_State

  !-----------------------------------------------------------------------------
  ! PH_Analy_VUAMP_State — VUAMP block amplitude output state (Explicit)
  !   AMP_BLKVAL(NBLOCK), DAMP_BLKVAL(NBLOCK)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_VUAMP_State
    REAL(wp), ALLOCATABLE :: amp_blk(:)   ! [nblock] amplitude values
    REAL(wp), ALLOCATABLE :: d_amp_blk(:) ! [nblock] d(amp)/dt
    INTEGER(i4) :: nblock = 0
    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Analy_VUAMP_State

  !-----------------------------------------------------------------------------
  ! PH_Analy_UVARM_State — UVARM user-defined output variable state
  !   UVARM(NUVARM): values computed by user and passed to Abaqus output
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UVARM_State
    REAL(wp), ALLOCATABLE :: uvarm(:)   ! OUT: UVARM(NUVARM) output values
    INTEGER(i4) :: nuvarm = 0
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Analy_UVARM_State

  !-----------------------------------------------------------------------------
  ! PH_Analy_UEXTERNALDB_Ctx — UEXTERNALDB per-call driving inputs
  !   UEXTERNALDB(LOP, LRESTART, TIME, DTIME, KSTEP, KINC)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UEXTERNALDB_Ctx
    REAL(wp) :: time(2) = 0.0_wp   ! I TIME(2) step/total time
    REAL(wp) :: dtime   = 0.0_wp   ! I DTIME
    INTEGER(i4) :: lop      = 0_i4  ! I LOP    0=start, 1=start-inc, ...
    INTEGER(i4) :: lrestart = 0_i4  ! I LRESTART restart flag
    INTEGER(i4) :: kstep    = 0_i4
    INTEGER(i4) :: kinc     = 0_i4
  END TYPE PH_Analy_UEXTERNALDB_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Analy_UEXTERNALDB_Algo — UEXTERNALDB algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UEXTERNALDB_Algo
    LOGICAL     :: write_on_converge = .TRUE.   ! write DB on convergence only
    INTEGER(i4) :: write_interval    = 1_i4     ! write every N increments
    CHARACTER(LEN=256) :: output_path = ' '     ! external DB output path
  END TYPE PH_Analy_UEXTERNALDB_Algo

  !-----------------------------------------------------------------------------
  ! PH_Analy_UAMP_Algo — UAMP amplitude algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UAMP_Algo
    LOGICAL     :: smooth       = .FALSE.  ! smooth amplitude
    REAL(wp)    :: smooth_width = 0.0_wp   ! smoothing window
    INTEGER(i4) :: interp       = 1_i4     ! 0=step, 1=linear interpolation
  END TYPE PH_Analy_UAMP_Algo

  !-----------------------------------------------------------------------------
  ! PH_Analy_VUAMP_Ctx — VUAMP vectorised amplitude per-call inputs
  !   VUAMP(AMPNAME, TIME, AMPVALUENEW, NBLOCK, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_VUAMP_Ctx
    REAL(wp), POINTER :: time(:)        ! I TIME   [nblock] time values
    REAL(wp), POINTER :: ampvalueold(:) ! I AMPVALUEOLD [nblock]
    INTEGER(i4) :: nblock = 0_i4
    CHARACTER(LEN=80) :: amp_name = ' '
  END TYPE PH_Analy_VUAMP_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Analy_VUAMP_Algo — VUAMP vectorised amplitude algorithm
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_VUAMP_Algo
    INTEGER(i4) :: nblock_max = 512_i4
    LOGICAL     :: smooth     = .FALSE.
    INTEGER(i4) :: interp     = 1_i4
  END TYPE PH_Analy_VUAMP_Algo

  !-----------------------------------------------------------------------------
  ! PH_Analy_UVARM_Algo — UVARM user-defined output variable algorithm
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Analy_UVARM_Algo
    INTEGER(i4) :: nuvarm     = 0_i4    ! number of user variables
    LOGICAL     :: use_svars  = .FALSE.  ! use state variables
    LOGICAL     :: use_stress = .TRUE.   ! use stress
  END TYPE PH_Analy_UVARM_Algo

END MODULE PH_Analysis_Types
