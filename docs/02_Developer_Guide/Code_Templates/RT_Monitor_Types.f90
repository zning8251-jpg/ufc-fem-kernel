!==============================================================================!
! MODULE RT_Monitor_Types
! Layer  : L5_RT  (When / run-time orchestration)
! Domain : Monitor  –  residual tracking, energy checks, diagnostics, timers
!
! Four TYPE kinds per concern:
!   RT_Residual_Monitor  – convergence residual tracking across NR iterations
!   RT_Energy_Monitor    – energy balance / hourglass energy watchdog
!   RT_Diag_Counter      – diagnostic event counters (cutbacks, warnings, …)
!   RT_Perf_Timer        – wall-clock performance timer with lap support
!==============================================================================!
MODULE RT_Monitor_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! ------------------------------------------------------------------ !
  ! RT_Residual_Monitor
  !   Tracks force/displacement residuals across Newton–Raphson iterations
  !   for the current increment.  Reset at increment start.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Residual_Monitor
    REAL(wp)    :: res_force_abs  = 0.0_wp   ! |R_f|   absolute force residual
    REAL(wp)    :: res_force_rel  = 0.0_wp   ! |R_f| / |R_f0|
    REAL(wp)    :: res_disp_abs   = 0.0_wp   ! |du|
    REAL(wp)    :: res_disp_rel   = 0.0_wp   ! |du| / |u|
    REAL(wp)    :: res_energy     = 0.0_wp   ! energy residual  (R·du)
    INTEGER(i4) :: n_iter         = 0_i4     ! current NR iteration count
    INTEGER(i4) :: n_iter_max     = 16_i4    ! max allowed iterations
    LOGICAL     :: converged      = .FALSE.
    LOGICAL     :: diverged       = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Residual_Monitor

  ! ------------------------------------------------------------------ !
  ! RT_Energy_Monitor
  !   Accumulates energy quantities for the current step/increment.
  !   Used for energy balance checks and hourglass-energy warnings.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Energy_Monitor
    REAL(wp) :: strain_energy      = 0.0_wp  ! internal (elastic) strain energy
    REAL(wp) :: kinetic_energy     = 0.0_wp  ! kinetic energy (explicit)
    REAL(wp) :: external_work      = 0.0_wp  ! work done by external forces
    REAL(wp) :: plastic_dissip     = 0.0_wp  ! plastic dissipation
    REAL(wp) :: creep_dissip       = 0.0_wp  ! creep dissipation
    REAL(wp) :: hourglass_energy   = 0.0_wp  ! hourglass stabilisation energy
    REAL(wp) :: hg_fraction        = 0.0_wp  ! hourglass / total strain energy
    REAL(wp) :: hg_warn_threshold  = 0.05_wp ! fraction above which warning fires
    LOGICAL  :: hg_warning_issued  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Energy_Monitor

  ! ------------------------------------------------------------------ !
  ! RT_Diag_Counter
  !   Accumulates diagnostic event counts across the analysis.
  !   Reset policy: never (accumulate over entire run).
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Diag_Counter
    INTEGER(i4) :: n_inc_cutbacks       = 0_i4  ! total increment cutbacks
    INTEGER(i4) :: n_nr_iter_total      = 0_i4  ! total NR iterations (all incs)
    INTEGER(i4) :: n_severe_discontin   = 0_i4  ! severe discontinuity iterations
    INTEGER(i4) :: n_pnewdt_requests    = 0_i4  ! pnewdt < 1 requests from subroutines
    INTEGER(i4) :: n_mat_fails          = 0_i4  ! material subroutine failures flagged
    INTEGER(i4) :: n_elem_warnings      = 0_i4  ! element quality warnings
    INTEGER(i4) :: n_contact_chatter    = 0_i4  ! contact open/close oscillations
    INTEGER(i4) :: n_cutback_max        = 5_i4  ! max cutbacks before error
    LOGICAL     :: abort_requested      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Diag_Counter

  ! ------------------------------------------------------------------ !
  ! RT_Perf_Timer
  !   Simple wall-clock performance timer with lap (split) support.
  !   Uses SYSTEM_CLOCK internally; reset by calling code at start.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Perf_Timer
    INTEGER(i8) :: t_start      = 0_i8      ! SYSTEM_CLOCK count at start
    INTEGER(i8) :: t_lap        = 0_i8      ! last lap start count
    REAL(wp)    :: elapsed_s    = 0.0_wp    ! cumulative elapsed seconds
    REAL(wp)    :: lap_s        = 0.0_wp    ! last lap duration in seconds
    REAL(wp)    :: t_mat        = 0.0_wp    ! time in material routines
    REAL(wp)    :: t_elem       = 0.0_wp    ! time in element routines
    REAL(wp)    :: t_solver     = 0.0_wp    ! time in linear solver
    REAL(wp)    :: t_output     = 0.0_wp    ! time in output routines
    LOGICAL     :: running      = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Perf_Timer

END MODULE RT_Monitor_Types
