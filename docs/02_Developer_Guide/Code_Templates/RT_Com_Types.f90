!===============================================================================
! Module: RT_Common_Types                                        [Template v4.0]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Common — Shared runtime context (8-TYPE lower-bound design)
!
! Purpose:
!   Defines the Ctx type for the RT_ (runtime) layer under the 8-TYPE
!   minimal design.  RT_ carries ONLY Ctx (no Desc, no State, no Algo).
!
! Design change (v3.1 → v4.0):
!   RT_Com_Base_Algo TYPE is ELIMINATED.
!   Rationale:
!     RT_ layer is a "framework channel", not a configuration layer.
!     It injects a read-only context (RT_Com_Base_Ctx) and receives a
!     scalar feedback signal (pnewdt).  A single-field wrapper TYPE
!     adds no semantic value.
!   Migration:
!     pnewdt is now a bare REAL(wp) parameter (INTENT INOUT) in every
!     UMAT / UEL interface that previously carried RT_Com_Base_Algo.
!     Use the module constant RT_PNEWDT_NO_CHANGE (= 1.0) for initialisation.
!
!   PH_Elem_Base_Algo (Newmark params) is also ELIMINATED.
!   Rationale:
!     Newmark/HHT-α parameters are solver-level configuration injected by
!     the framework, not element-private state.  They are moved into
!     RT_Com_Base_Ctx as newmark_params(3) so the framework controls them.
!
! Type roles:
!   RT_Com_Base_Ctx  – Increment bookkeeping + time-integration parameters.
!                    Shared by BOTH UMAT and UEL call paths.  Read-only from
!                    the physics side.
!                    19 declared fields: 14 common + 4 UEL-only + 1 Newmark vec.
!                    (lflags counted as 1 array field; newmark_params as 1 array field)
!
! UEL-only fields (principle ⑭ RT_CTX UEL-ONLY FIELDS):
!   nrhs   – NRHS   : number of RHS columns (UEL only, UMAT defaults to 0)
!   mlvarx – MLVARX : max. variable index in LVAR (UEL, typically = ndofel)
!   ndload – NDLOAD : no. of active distributed load types (UEL only)
!   period – PERIOD : analysis step period [s]       (UEL only)
!   When these are 0 / 0.0, the UMAT path simply ignores them.
!
! LFLAGS convention (6 flags, array size = 6):
!   lflags(1) : analysis procedure type
!   lflags(2) : 0=linear incremental, 1=nonlinear step (NLGEOM=YES)
!   lflags(3) : 1=normal increment, 2=buckling, 3=Riks arc-length
!   lflags(4) : 1=last iteration of increment
!   lflags(5) : 1=ABAQUS/Explicit call
!   lflags(6) : reserved / unused (zero-filled by ABAQUS)
!
! pnewdt convention (bare scalar):
!   pnewdt < 1.0  → cut the increment (ABAQUS resets and retries smaller)
!   pnewdt > 1.0  → suggest a larger next step
!   pnewdt = 1.0  → no change (initialise with RT_PNEWDT_NO_CHANGE)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!===============================================================================
MODULE RT_Com_Types
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE RT_Global_Types, ONLY: RT_Global_Ctx   ! Level 1 of three-tier Ctx
  IMPLICIT NONE
  PRIVATE

  !===========================================================================
  ! Three-Tier Ctx Architecture (Level 2 is this module's RT_Com_Base_Ctx)
  !===========================================================================
  ! Level 1: RT_Global_Ctx  (RT_Global_Types)   — singleton time/step/convergence
  ! Level 2: RT_Com_Base_Ctx (THIS MODULE)       — LFLAGS / elem_id / UEL-fields
  ! Level 3: RT_Mat_Ctx, RT_Elem_Ctx ...         — domain-specific (RT_Domain_Types)
  !
  ! Zero-copy hot-path access pattern:
  !   time_now = mat_ctx%com%global_ctx%time_current   ← O(1) pointer chain
  !
  ! Additional domain-specific run-time Ctx types in this module:
  !   RT_Explicit_Ctx  — per-increment Explicit solver state
  !   RT_Therm_Ctx     — per-increment thermal analysis state
  !===========================================================================

  PUBLIC :: RT_Com_Base_Ctx
  PUBLIC :: RT_PNEWDT_NO_CHANGE   ! convenience initialiser for bare pnewdt
  PUBLIC :: RT_Inc_Ctrl_Ctx
  PUBLIC :: RT_Step_Ctrl_Ctx
  PUBLIC :: RT_Explicit_Ctx
  PUBLIC :: RT_Therm_Ctx

  !-- Convenience constant: pass to initialise pnewdt (replaces RT_Com_Base_Algo)
  REAL(wp), PARAMETER :: RT_PNEWDT_NO_CHANGE = 1.0_wp

  !-----------------------------------------------------------------------------
  ! RT_Com_Base_Ctx — Runtime Common Context (pointer to global + UMAT/UEL shared)
  !    Populated by the UMAT/UEL bridge before calling any physics routine.
  !    Fields marked [UEL] are zero-initialised for UMAT calls (no side effect).
  !    Fields marked [DYN] are zero for static analysis (ignored by physics).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Com_Base_Ctx
    !-- Pointer to global context (SINGLE SOURCE OF TRUTH for time)
    TYPE(RT_Global_Ctx), POINTER :: global_ctx => NULL()
      
    !-- ABAQUS LFLAGS array (6 procedure / status flags)
    INTEGER(i4) :: lflags(6) = 0
      
    !-- Element / Gauss point identifiers (for diagnostics and output)
    INTEGER(i4) :: elem_id  = 0    ! Element number (NOEL / JELEM)
    INTEGER(i4) :: gauss_pt = 0    ! Integration point index within element
    INTEGER(i4) :: layer_id = 0    ! Layer index (LAYER; composite use)
    INTEGER(i4) :: kspt     = 0    ! Section point within layer (KSPT)
      
    !-- UEL-only fields (principle ⑭)                         [UEL only]
    INTEGER(i4) :: nrhs   = 0       ! UEL  NRHS    number of RHS columns
    INTEGER(i4) :: mlvarx = 0       ! UEL  MLVARX  max. variable storage index
    INTEGER(i4) :: ndload = 0       ! UEL  NDLOAD  no. of active dist. load types
    REAL(wp)    :: period = 0.0_wp  ! UEL  PERIOD  analysis step period [s]
      
  CONTAINS
      
    !-- Backward compatible accessors (delegate to global_ctx)
    PROCEDURE, PASS(this) :: GetTime => RT_Com_GetTime
    PROCEDURE, PASS(this) :: GetDtime => RT_Com_GetDtime
    PROCEDURE, PASS(this) :: GetKstep => RT_Com_GetKstep
    PROCEDURE, PASS(this) :: GetKinc => RT_Com_GetKinc
      
  END TYPE RT_Com_Base_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Inc_Ctrl_Ctx — Per-increment control scalars (pnewdt + cutback state)
  !   Carries the increment controller state between the bridge and the solver.
  !   pnewdt is the user-physics feedback signal; do NOT store inside State.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Inc_Ctrl_Ctx
    REAL(wp)    :: pnewdt       = 1.0_wp   ! Current pnewdt signal (bare scalar)
    INTEGER(i4) :: n_cutbacks   = 0_i4    ! Cumulative cut-backs in this increment
    INTEGER(i4) :: n_iter       = 0_i4    ! Current iteration count
    INTEGER(i4) :: max_cutbacks = 5_i4    ! Max allowed cut-backs
    LOGICAL     :: force_cutback = .FALSE. ! Flag to force a cut-back from bridge
    LOGICAL     :: converged    = .FALSE.  ! Increment converged flag
  END TYPE RT_Inc_Ctrl_Ctx

  !-----------------------------------------------------------------------------
  ! RT_Step_Ctrl_Ctx — Per-step execution control
  !   Drives the automatic-increment (AI) loop within one analysis step.
  !   Populated from MD_Step_Inc_Desc before the step loop begins.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Step_Ctrl_Ctx
    INTEGER(i4) :: step_id       = 0_i4    ! Current step number
    INTEGER(i4) :: kinc          = 0_i4    ! Current increment counter
    INTEGER(i4) :: max_incs      = 100_i4  ! Max increments for this step
    REAL(wp)    :: dt_current    = 0.01_wp ! Current time increment [step-time units]
    REAL(wp)    :: dt_min        = 1.0e-8_wp
    REAL(wp)    :: dt_max        = 1.0_wp
    REAL(wp)    :: expand_factor = 1.5_wp  ! dt growth cap when pnewdt > 1
    REAL(wp)    :: time_in_step  = 0.0_wp  ! Accumulated time within current step
    REAL(wp)    :: time_target   = 1.0_wp  ! Target step end time
    LOGICAL     :: step_complete = .FALSE.
  END TYPE RT_Step_Ctrl_Ctx

  !=============================================================================
  ! Backward compatible accessors (delegate to global_ctx)
  !=============================================================================
  FUNCTION RT_Com_GetTime(this) RESULT(time_val)
    CLASS(RT_Com_Base_Ctx), INTENT(IN) :: this
    REAL(wp) :: time_val
    
    IF (ASSOCIATED(this%global_ctx)) THEN
      time_val = this%global_ctx%time_current
    ELSE
      time_val = 0.0_wp
      ! CALL Log_Warning("global_ctx not associated in RT_Com_GetTime")
    END IF
  END FUNCTION
  
  FUNCTION RT_Com_GetDtime(this) RESULT(dtime_val)
    CLASS(RT_Com_Base_Ctx), INTENT(IN) :: this
    REAL(wp) :: dtime_val
    
    IF (ASSOCIATED(this%global_ctx)) THEN
      dtime_val = this%global_ctx%dtime
    ELSE
      dtime_val = 0.0_wp
    END IF
  END FUNCTION
  
  FUNCTION RT_Com_GetKstep(this) RESULT(kstep_val)
    CLASS(RT_Com_Base_Ctx), INTENT(IN) :: this
    INTEGER(i4) :: kstep_val
    
    IF (ASSOCIATED(this%global_ctx)) THEN
      kstep_val = this%global_ctx%kstep
    ELSE
      kstep_val = 0
    END IF
  END FUNCTION
  
  FUNCTION RT_Com_GetKinc(this) RESULT(kinc_val)
    CLASS(RT_Com_Base_Ctx), INTENT(IN) :: this
    INTEGER(i4) :: kinc_val
    
    IF (ASSOCIATED(this%global_ctx)) THEN
      kinc_val = this%global_ctx%kinc
    ELSE
      kinc_val = 0
    END IF
  END FUNCTION
  
  ! ------------------------------------------------------------------ !
  ! RT_Inc_Algo
  !   Algorithmic parameters controlling increment size selection,
  !   automatic time stepping (ATS) and cutback policy.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Inc_Algo
    REAL(wp)    :: dt_init        = 0.0_wp   ! initial time increment (from INP)
    REAL(wp)    :: dt_min         = 0.0_wp   ! minimum allowed dt (0 = auto)
    REAL(wp)    :: dt_max         = 0.0_wp   ! maximum allowed dt (0 = step period)
    REAL(wp)    :: dt_current     = 0.0_wp   ! current dt
    REAL(wp)    :: pnewdt_min     = 1.0_wp   ! minimum pnewdt across all sub-calls
    INTEGER(i4) :: max_incs       = 100_i4   ! max increments per step
    INTEGER(i4) :: max_cutbacks   = 5_i4     ! max cutbacks before abort
    LOGICAL     :: use_ats        = .TRUE.   ! automatic time stepping enabled
    REAL(wp)    :: ats_cutback_factor = 0.25_wp  ! dt multiplier on cutback
    REAL(wp)    :: ats_grow_factor    = 1.5_wp   ! dt multiplier on success
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Inc_Algo

  ! ------------------------------------------------------------------ !
  ! RT_Analysis_Ctx
  !   Top-level run-time context for the entire analysis (all steps).
  !   Carries step index, total time, and global convergence flags.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Analysis_Ctx
    INTEGER(i4) :: n_steps        = 0_i4    ! total number of steps defined
    INTEGER(i4) :: current_step   = 0_i4    ! 1-based current step index
    INTEGER(i4) :: current_inc    = 0_i4    ! current increment number in step
    REAL(wp)    :: total_time     = 0.0_wp  ! elapsed total analysis time
    REAL(wp)    :: step_time      = 0.0_wp  ! elapsed time in current step
    REAL(wp)    :: step_period    = 0.0_wp  ! total period of current step
    LOGICAL     :: is_first_inc   = .TRUE.  ! first increment flag
    LOGICAL     :: is_restart     = .FALSE. ! running from a restart file
    LOGICAL     :: abort_flag     = .FALSE. ! abort requested by any domain
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Analysis_Ctx

  ! ------------------------------------------------------------------ !
  ! RT_Event_Ctx
  !   Transient event context: records which analysis events have
  !   fired in the current increment (for output and checkpoint triggers).
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Event_Ctx
    LOGICAL :: inc_start       = .FALSE.  ! fired at increment start
    LOGICAL :: inc_end         = .FALSE.  ! fired at increment end
    LOGICAL :: step_start      = .FALSE.  ! first increment of step
    LOGICAL :: step_end        = .FALSE.  ! last increment of step
    LOGICAL :: analysis_end    = .FALSE.  ! very last increment
    LOGICAL :: cutback         = .FALSE.  ! current increment is a cutback
    LOGICAL :: severe_discontin= .FALSE.  ! severe discontinuity iteration
    LOGICAL :: contact_changed = .FALSE.  ! contact status changed this iter
    INTEGER(i4) :: nr_iter     = 0_i4    ! current Newton iteration number
  END TYPE RT_Event_Ctx

  !=============================================================================
  ! RT_Explicit_Ctx — Per-increment Explicit solver context (Level 2 extension)
  !   Carries Abaqus/Explicit-specific state not present in Standard.
  !   Used by VDISP/VDLOAD/VUINTER/VUMAT bridges.
  !=============================================================================
  TYPE, PUBLIC :: RT_Explicit_Ctx
    !-- Level 2 base pointer (non-owning; caller manages lifetime)
    TYPE(RT_Com_Base_Ctx), POINTER :: com => NULL()   ! → RT_Com_Base_Ctx

    !-- Explicit time integration bookkeeping
    REAL(wp)    :: stable_dt    = 0.0_wp   ! stable time increment (Courant)
    REAL(wp)    :: mass_scale   = 1.0_wp   ! mass scaling factor (default=1)
    INTEGER(i4) :: nblock       = 0_i4    ! current vectorisation block size

    !-- Kinematic state at start of increment
    REAL(wp), POINTER :: velold(:,:)  ! [nblock, ndof] velocity at t_n
    REAL(wp), POINTER :: accold(:,:)  ! [nblock, ndof] acceleration at t_n

    !-- Explicit contact bookkeeping
    INTEGER(i4) :: n_contact_pairs = 0_i4  ! active contact pairs this increment
    LOGICAL     :: contact_active  = .FALSE.

    !-- Energy tracking
    REAL(wp)    :: internal_energy = 0.0_wp  ! current internal energy
    REAL(wp)    :: kinetic_energy  = 0.0_wp  ! current kinetic energy
    REAL(wp)    :: external_work   = 0.0_wp  ! work done by external loads

    !-- Control flags
    LOGICAL     :: is_explicit     = .TRUE.  ! always .TRUE. for Explicit
    LOGICAL     :: use_double_inc  = .FALSE. ! central-difference double-inc scheme
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Explicit_Ctx

  !=============================================================================
  ! RT_Therm_Ctx — Per-increment thermal analysis context (Level 2 extension)
  !   Extends RT_Com_Base_Ctx for thermal / coupled-temperature analyses.
  !   Used by UMATHT / DFLUX / FILM / coupled-temperature bridges.
  !=============================================================================
  TYPE, PUBLIC :: RT_Therm_Ctx
    !-- Level 2 base pointer (non-owning)
    TYPE(RT_Com_Base_Ctx), POINTER :: com => NULL()   ! → RT_Com_Base_Ctx

    !-- Thermal analysis parameters
    INTEGER(i4) :: ntgrd        = 3_i4    ! spatial dimension of thermal gradient
    LOGICAL     :: is_coupled   = .FALSE. ! fully-coupled temperature-displacement
    LOGICAL     :: is_transient = .TRUE.  ! .FALSE. = steady-state

    !-- Current thermal state
    REAL(wp)    :: temp_global  = 0.0_wp  ! global mean temperature (diagnostic)
    REAL(wp)    :: temp_max     = 0.0_wp  ! maximum temperature in model
    REAL(wp)    :: temp_min     = 0.0_wp  ! minimum temperature in model

    !-- Heat balance
    REAL(wp)    :: total_rpl    = 0.0_wp  ! summed volumetric heat generation
    REAL(wp)    :: total_flux   = 0.0_wp  ! net boundary heat flux

    !-- Convergence control
    REAL(wp)    :: temp_conv_tol = 1.0e-6_wp  ! temperature convergence tolerance
    REAL(wp)    :: flux_conv_tol = 1.0e-10_wp ! heat flux convergence tolerance
    INTEGER(i4) :: max_iter     = 20_i4   ! max NR thermal iterations
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Therm_Ctx

END MODULE RT_Com_Types