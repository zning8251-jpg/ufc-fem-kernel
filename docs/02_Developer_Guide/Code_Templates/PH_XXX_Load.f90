!===============================================================================
! Template: PH_XXX_Load.f90                                      [Template v1.2]
! Layer:  L4_PH - Physics Layer
! Domain: Load / [Family] (e.g., DIST / CONC / FLUX / BODY / SURF)
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.2 (2026-03)  Single PH_XXX_Load_Args (replaces _In/_Out); _Impl(args).
!   v1.1 (2026-03)  Add PH_XXX_Load_In/_Out TYPE pair (Principle #14 SIO);
!                   split API wrapper / Impl physics; upgrade PUBLIC exports.
!   v1.0 (prev)     8-TYPE minimal baseline
!
! PURPOSE:
!   UFC-native load compute interface.
!   Replaces ABAQUS DLOAD/VDLOAD/CLOAD/VCLOAD/DFLUX/VDFLUX user subroutines.
!
! DESIGN: "shen si ABAQUS load subroutines er xing bu si"
!   - v1.2: unified PH_XXX_Load_Args (INOUT) on _Impl; API fills args.
!   - v1.1: Principle #14 / SIO-compliant IO bundle; API thin wrapper → _Impl
!   - v1.0: 8-TYPE minimal system (Desc/State/Algo/Ctx)
!   - Supports: DIST (distributed), CONC (concentrated), FLUX (thermal)
!   - No flat arrays; all parameters carried by typed structs
!   - L5_RT and ABAQUS adapters BOTH call THIS interface
!
! ABAQUS SUBROUTINES MAPPED:
!   DLOAD   → Standard distributed load
!   VDLOAD  → Explicit distributed load
!   CLOAD   → Standard concentrated load (nodal force)
!   VCLOAD  → Explicit concentrated load
!   DFLUX   → Standard thermal flux
!   VDFLUX  → Explicit thermal flux
!
! NAMING CONVENTION:
!   Module:      PH_[Family]_[LoadType]_Load  -> PH_DIST_Pressure_Load
!   Subroutine:  same name as module + _API suffix
!   XXX: [Family]_[LoadType] abbreviation
!
! HOW TO USE:
!   1. Copy to L4_PH/Load/[Family]/
!   2. Rename: PH_[Family]_[Type]_Load.f90
!   3. Replace XXX -> [Family]_[Type] throughout
!   4. USE matching Desc from L3_MD; define State here
!   5. Add model-specific fields to PH_XXX_Load_Args if needed
!   6. Implement load logic in PRIVATE SUBROUTINE PH_XXX_Load_Impl
!      PH_XXX_Load_API is generated glue — do NOT add physics there
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-02 ✓  _Impl 6th param is PH_XXX_Load_Args (INOUT unified bundle)
!   SIO-03 ✓  PH_XXX_Load_Args carries structured ErrorStatusType status ([OUT]);
!             check %status_code == IF_STATUS_OK
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  _In TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  _In TYPE has no ALLOCATABLE members
!===============================================================================
MODULE PH_XXX_Load
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Base types
  USE MD_Load_Types,  ONLY: MD_Load_Base_Desc, &
                            MD_Load_Base_State, &
                            MD_Load_Base_Algo
  !-- [PH] Per-increment types
  USE PH_Load_Types,  ONLY: PH_Load_Base_Ctx, &
                            PH_Load_Base_Algo
  !-- [RT] Runtime context
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_XXX_Load_State  ! L4_PH state type (export for unit tests)
  PUBLIC :: PH_XXX_Load_Args       ! Unified call-time IO bundle (Principle #14)
  PUBLIC :: PH_XXX_Load_API        ! UFC-native load entry (thin wrapper -> _Impl)
  ! PH_XXX_Load_Impl is PRIVATE: load physics lives there; API is pure glue.

  !-----------------------------------------------------------------------------
  ! STATE type: PH-owned internal state for load.
  !   Extends MD_Load_Base_State which provides:
  !     accumulated, last_magnitude, work_done, converged, iterations, status
  !   Add load-family-specific state variables below.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_Load_Base_State) :: PH_XXX_Load_State
    !-- TODO: replace placeholders with actual load state variables
    !   e.g., load_history(10), cycle_count, phase_angle, ...
    REAL(wp) :: ivar1 = 0.0_wp     ! Placeholder ISV 1 — rename or replace
    REAL(wp) :: ivar2 = 0.0_wp     ! Placeholder ISV 2 — rename or replace
  END TYPE PH_XXX_Load_State

  !-----------------------------------------------------------------------------
  ! PH_XXX_Load_Args — unified bundle (Principle #14, L4 adaptation)
  !
  !   [IN]  SIO-13/14: no _Desc/_State/_Algo/_Ctx; no ALLOCATABLE on [IN] slice.
!   [OUT] SIO-03: structured ErrorStatusType status; initialize with
!         init_error_status(...) and inspect via %status_code.
  !
  !   Usage (L5_RT or harness calling _Impl directly):
  !     TYPE(PH_XXX_Load_Args) :: ld_args
  !     ld_args%load_id  = 5
  !     ld_args%success  = .FALSE.
  !     CALL PH_XXX_Load_Impl(MD_Load_Desc, PH_Load_Ctx, PH_Load_State,
  !                            MD_Load_Algo, PH_Load_Algo, ld_args)
!     IF (ld_args%status%status_code == IF_STATUS_OK) load_value = ld_args%load_value
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_XXX_Load_Args
    !-- [IN]
    INTEGER(i4) :: load_id       = 0_i4
    INTEGER(i4) :: jltyp         = 0_i4
    LOGICAL     :: flag_firstinc = .FALSE.
    LOGICAL     :: flag_nlgeom   = .FALSE.
    !-- TODO: load-family-specific [IN] fields
    !-- [OUT]
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success    = .FALSE.
    REAL(wp)              :: load_value = 0.0_wp
    REAL(wp)              :: work_incr  = 0.0_wp
    !-- TODO: load-family-specific [OUT] diagnostics
  END TYPE PH_XXX_Load_Args

CONTAINS

  !============================================================================
  ! PUBLIC API — thin wrapper (Principle #14 / SIO adaptation for L4_PH Load)
  !============================================================================
  !> PH_XXX_Load_API
  !>
  !> ROLE: THIN WRAPPER ONLY — fills PH_XXX_Load_Args, delegates to PH_XXX_Load_Impl.
  !>   DO NOT add load physics here; implement in PH_XXX_Load_Impl.
  !>
  !> Parameters (v1.1 ABI — backward compatible with v1.0):
  !>   MD_Load_Desc  [MD] load parameters (read-only)
  !>   PH_Load_Ctx   [PH] driving inputs: coords, time, elem_id, npt, face_id
  !>   PH_Load_State [PH] load state (in/out)
  !>   MD_Load_Algo  [MD] analysis config
  !>   PH_Load_Algo  [PH] iteration ctrl
  !>   RT_Com_Ctx    [RT] bookkeeping: kstep, kinc, time, nlgeom
  !>   load_value    [OUT] computed load magnitude [N, Pa, W/m², ...]
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_XXX_Load_API(MD_Load_Desc, PH_Load_Ctx, PH_Load_State, &
                              MD_Load_Algo, PH_Load_Algo, RT_Com_Ctx, load_value)
    TYPE(MD_Load_Base_Desc),     INTENT(IN)    :: MD_Load_Desc
    TYPE(PH_Load_Base_Ctx),      INTENT(IN)    :: PH_Load_Ctx
    TYPE(PH_XXX_Load_State), INTENT(INOUT) :: PH_Load_State
    TYPE(MD_Load_Base_Algo),     INTENT(IN)    :: MD_Load_Algo
    TYPE(PH_Load_Base_Algo),     INTENT(IN)    :: PH_Load_Algo
    TYPE(RT_Com_Base_Ctx),       INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                    INTENT(OUT)   :: load_value

    TYPE(PH_XXX_Load_Args) :: ld_args

    ld_args%load_id       = MD_Load_Desc%load_id
    ld_args%jltyp         = PH_Load_Ctx%jltyp
    ld_args%flag_firstinc = RT_Com_Ctx%first_increment
    ld_args%flag_nlgeom   = RT_Com_Ctx%nlgeom
    !-- TODO: fill additional model-specific ld_args [IN] fields here

    ld_args%success = .FALSE.    ! always reset before delegate call

    CALL PH_XXX_Load_Impl(MD_Load_Desc, PH_Load_Ctx, PH_Load_State, &
                           MD_Load_Algo, PH_Load_Algo, ld_args)

    load_value = ld_args%load_value
  END SUBROUTINE PH_XXX_Load_API

  !============================================================================
  ! PRIVATE IMPLEMENTATION — all load physics here
  !============================================================================
  !> PH_XXX_Load_Impl
  !>
  !>  Six-parameter inner interface (Principle #14, L4 hot-path form).
  !>  Callers: PH_XXX_Load_API (production) and unit-test harness (direct).
  !>
  !>  Contract:
  !>    args%load_id       load set identifier (for multi-load routing)
  !>    args%jltyp         ABAQUS JLTYP: load-type flag (face ID, body load, ...)
  !>    args%flag_nlgeom   .TRUE. => follower-force correction may be needed
  !>    args%flag_firstinc .TRUE. => cold-start / reference-config update
  !>    args%success       .TRUE. IFF load evaluated without error
  !>    args%load_value    computed load magnitude
  !>    args%work_incr     incremental work contribution (for energy accounting)
  !>    PH_Load_State     updated in-place; undefined if args%success = .FALSE.
  SUBROUTINE PH_XXX_Load_Impl(MD_Load_Desc, PH_Load_Ctx, PH_Load_State, &
                               MD_Load_Algo, PH_Load_Algo, args)
    TYPE(MD_Load_Base_Desc),     INTENT(IN)    :: MD_Load_Desc
    TYPE(PH_Load_Base_Ctx),      INTENT(IN)    :: PH_Load_Ctx
    TYPE(PH_XXX_Load_State), INTENT(INOUT) :: PH_Load_State
    TYPE(MD_Load_Base_Algo),     INTENT(IN)    :: MD_Load_Algo
    TYPE(PH_Load_Base_Algo),     INTENT(IN)    :: PH_Load_Algo
    TYPE(PH_XXX_Load_Args),      INTENT(INOUT) :: args

    !-- Local variables (stack-allocated; no ALLOCATE in hot path — SIO-09)
    !$UFC HOT_PATH
    REAL(wp) :: time_factor, spatial_factor, x, y, z

    !-- Initialize
    CALL init_error_status(args%status)
    args%success    = .FALSE.
    args%load_value = 0.0_wp
    args%work_incr  = 0.0_wp
    CALL init_error_status(PH_Load_State%status)

    !-- Extract spatial coordinates from Ctx
    x = PH_Load_Ctx%coords(1)
    y = PH_Load_Ctx%coords(2)
    z = PH_Load_Ctx%coords(3)

    !=========================================================================
    ! Step 1: Time-dependent amplitude factor
    !   time_dependence == 0 : constant load
    !   time_dependence == 1 : user-defined time function
    !   time_dependence == 2 : tabular amplitude (add interpolation below)
    !   TODO: route additional time_dependence modes
    !=========================================================================
    IF (MD_Load_Desc%time_dependence == 1) THEN
      !-- Use PH_Load_Ctx time fields (populate from RT_Com_Ctx in L5_RT before call)
      time_factor = XXX_Time_Function(PH_Load_Ctx%time_current, PH_Load_Ctx%time_total)
    ELSE
      time_factor = 1.0_wp
    END IF

    !=========================================================================
    ! Step 2: Spatial variation factor
    !   Replace with actual spatial function for this load family:
    !     DIST pressure: spatially uniform => factor = 1.0
    !     BODY force: function of coords (e.g., centrifugal = omega^2 * r)
    !     FLUX: function of surface temperature (non-linear)
    !   TODO: implement XXX_Spatial_Function body
    !=========================================================================
    spatial_factor = XXX_Spatial_Function(x, y, z, MD_Load_Desc)

    !=========================================================================
    ! Step 3: Compute load magnitude
    !   F = magnitude * scale_factor * time_factor * spatial_factor
    !   For follower forces (args%flag_nlgeom): apply deformation-dependent
    !   direction correction in spatial_factor (or add Step 3b).
    !=========================================================================
    args%load_value = MD_Load_Desc%magnitude * MD_Load_Desc%scale_factor &
                   * time_factor * spatial_factor

    !=========================================================================
    ! Step 4: Update load state history and energy accounting
    !=========================================================================
    PH_Load_State%accumulated    = PH_Load_State%accumulated + args%load_value
    PH_Load_State%last_magnitude = args%load_value
    PH_Load_State%work_done      = PH_Load_State%accumulated

    !-- Work increment: load_value * displacement_increment
    !   (displacement increment not available here; UEL/RT level must assemble)
    args%work_incr = 0.0_wp   ! TODO: fill at RT level if needed

    !-- Finalise
    args%success = .TRUE.
    PH_Load_State%status%status_code = IF_STATUS_OK
    args%status%status_code           = IF_STATUS_OK
  END SUBROUTINE PH_XXX_Load_Impl

  !============================================================================
  ! PRIVATE HELPERS
  !   Name pattern: XXX_<Verb>_<Noun>   (all PRIVATE; only _Impl calls these)
  !============================================================================

  !> XXX_Time_Function
  !>   Time-dependent amplitude factor for this load.
  !>   PURE to allow compiler inlining on hot path.
  !>   Replace body with actual amplitude law:
  !>     Linear ramp:    factor = MIN(time_step / ramp_dur, 1.0_wp)
  !>     Sinusoidal:     factor = 0.5*(1 - COS(2*PI*freq*time_total))
  !>     Tabular:        interpolate from MD_Load_Desc amplitude table
  !>     Constant:       factor = 1.0 (no time variation)
  PURE FUNCTION XXX_Time_Function(time_step, time_total) RESULT(factor)
    REAL(wp), INTENT(IN) :: time_step   ! Step time at start of increment [s]
    REAL(wp), INTENT(IN) :: time_total  ! Total analysis time at start    [s]
    REAL(wp) :: factor
    !-- TODO: replace stub with actual time amplitude function
    !   Example linear ramp:
    !   factor = MIN(time_step / ramp_duration, 1.0_wp)
    !   Example sinusoidal:
    !   factor = 0.5_wp * (1.0_wp - COS(2.0_wp * 3.14159265358979_wp * time_total))
    factor = 1.0_wp   ! Default: constant (static)
  END FUNCTION XXX_Time_Function

  !> XXX_Spatial_Function
  !>   Spatial amplitude factor as function of integration-point coordinates.
  !>   PURE; receives MD_Load_Desc for model-specific parameters.
  !>   Replace body with actual spatial variation, e.g.:
  !>     Uniform distributed:        factor = 1.0
  !>     Hydrostatic (depth):        factor = rho_fluid * g * z
  !>     Centrifugal body force:     factor = omega^2 * SQRT(x^2+y^2) / r_ref
  PURE FUNCTION XXX_Spatial_Function(x, y, z, MD_Load_Desc) RESULT(factor)
    REAL(wp),                INTENT(IN) :: x, y, z       ! IP coordinates [m]
    TYPE(MD_Load_Base_Desc), INTENT(IN) :: MD_Load_Desc  ! Load descriptor
    REAL(wp) :: factor
    !-- TODO: replace stub with actual spatial function
    factor = 1.0_wp   ! Default: spatially uniform
  END FUNCTION XXX_Spatial_Function

END MODULE PH_XXX_Load

!===============================================================================
! STRUCT REFERENCE CARD — Load Domain
!
! ─────────────────────────────────────────────────────────────────────────────
! Layer  Domain  Role   Type name               Variable name    Key members
! ─────────────────────────────────────────────────────────────────────────────
!
! ── MD layer (L3_MD) — model description, static ────────────────────────────
!
!  MD  Load  Desc  MD_Load_XXX_Desc        MD_Load_Desc
!    Concrete extension; holds load-specific parameters:
!      load_id, load_family, load_name, magnitude, scale_factor, ...
!
!  MD  Load  State MD_Load_Base_State       MD_Load_State
!    Load history: accumulated, last_magnitude, work_done
!
!  MD  Load  Algo  MD_Load_Base_Algo       MD_Load_Algo
!    Pre-analysis: apply_mode, use_ramp, ramp_duration, print_debug
!
! ── PH layer (L4_PH) — physical computation, per-increment ──────────────────
!
!  PH  Load  State PH_XXX_Load_State    PH_Load_State
!    Extends MD_Load_Base_State; add model-specific ISVs
!
!  PH  Load  Ctx   PH_Load_Base_Ctx         PH_Load_Ctx
!    Per-increment inputs: coords, time_current, time_total,
!                          elem_id, integ_pt_id, node_id, face_id
!
!  PH  Load  Algo  PH_Load_Base_Algo        PH_Load_Algo
!    Per-increment ctrl: max_iter, tolerance, pnewdt_min/max
!
! ── RT layer (L5_RT) — runtime bookkeeping ─────────────────────────────────
!
!  RT  Com   Ctx   RT_Com_Base_Ctx          RT_Com_Ctx
!    Step/inc: time_step, time_total, kstep, kinc, dtime
!
!  load_value  REAL(wp) OUT
!    Computed load magnitude returned to solver
! ─────────────────────────────────────────────────────────────────────────────
!===============================================================================