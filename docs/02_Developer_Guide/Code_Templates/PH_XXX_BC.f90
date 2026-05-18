!===============================================================================
! Template: PH_XXX_BC.f90                                        [Template v1.2]
! Layer:  L4_PH - Physics Layer
! Domain: BC / [Family] (e.g., DISP / VEL / ACC / POT)
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.2 (2026-03)  Single PH_XXX_BC_Args (replaces _In/_Out); _Impl(args).
!   v1.1 (2026-03)  Add PH_XXX_BC_In/_Out TYPE pair (Principle #14 SIO);
!                   split API wrapper / Impl physics; upgrade PUBLIC exports.
!   v1.0 (prev)     8-TYPE minimal baseline
!
! PURPOSE:
!   UFC-native boundary condition compute interface.
!   Replaces ABAQUS DISP/VDISP/UPOT user subroutines.
!
! DESIGN: "shen si ABAQUS BC subroutines er xing bu si"
!   - v1.1: Principle #14 / SIO-compliant _In/_Out TYPE pair added
!           PH_XXX_BC_API is a THIN WRAPPER; physics lives in PH_XXX_BC_Impl
!   - v1.0: 8-TYPE minimal system (Desc/State/Algo/Ctx)
!   - Supports: DISP (displacement), VEL (velocity), ACC (acceleration), POT
!   - No flat arrays; all parameters carried by typed structs
!   - L5_RT and ABAQUS adapters BOTH call THIS interface
!
! ABAQUS SUBROUTINES MAPPED:
!   DISP    → Standard displacement/velocity/acceleration boundary
!   VDISP   → Explicit displacement boundary
!   UPOT    → Multi-field potential boundary
!
! NAMING CONVENTION:
!   Module:      PH_[Family]_[Type]_BC
!   Subroutine:  same name as module + _API suffix
!   XXX: [Family]_[Type] abbreviation
!
! HOW TO USE:
!   1. Copy to L4_PH/BC/[Family]/
!   2. Rename: PH_[Family]_[Type]_BC.f90
!   3. Replace XXX -> [Family]_[Type] throughout
!   4. USE matching Desc from L3_MD; define State here
!   5. Add model-specific fields to PH_XXX_BC_Args if needed
!   6. Implement BC logic in PRIVATE SUBROUTINE PH_XXX_BC_Impl
!      PH_XXX_BC_API is generated glue — do NOT add physics there
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-02 ✓  _Impl 6th param is PH_XXX_BC_Args (INOUT unified bundle)
!   SIO-03 ✓  PH_XXX_BC_Args carries structured ErrorStatusType status ([OUT]);
!             check %status_code == IF_STATUS_OK
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  _In TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  _In TYPE has no ALLOCATABLE members
!===============================================================================
MODULE PH_XXX_BC
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Base types
  USE MD_BC_Types,  ONLY: MD_BC_Base_Desc, &
                          MD_BC_Base_State, &
                          MD_BC_Base_Algo
  !-- [PH] Per-increment types
  USE PH_BC_Types,  ONLY: PH_BC_Base_Ctx, &
                          PH_BC_Base_Algo
  !-- [RT] Runtime context
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_XXX_BC_State   ! L4_PH state type (export for unit tests)
  PUBLIC :: PH_XXX_BC_Args    ! Unified call-time IO bundle (Principle #14)
  PUBLIC :: PH_XXX_BC_API     ! UFC-native BC entry (thin wrapper -> _Impl)
  ! PH_XXX_BC_Impl is PRIVATE: BC physics lives there; API is pure glue.

  !-----------------------------------------------------------------------------
  ! STATE type: PH-owned internal state for BC.
  !   Extends MD_BC_Base_State which provides:
  !     accumulated, last_value, converged, iterations, status
  !   Add BC-family-specific state variables below.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_BC_Base_State) :: PH_XXX_BC_State
    !-- TODO: replace placeholders with actual model state variables
    REAL(wp) :: ivar1 = 0.0_wp     ! Placeholder ISV 1 — rename or replace
    REAL(wp) :: ivar2 = 0.0_wp     ! Placeholder ISV 2 — rename or replace
  END TYPE PH_XXX_BC_State

  !-----------------------------------------------------------------------------
  ! PH_XXX_BC_Args — unified bundle (Principle #14, L4 adaptation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_XXX_BC_Args
    !-- [IN]
    INTEGER(i4) :: dof_number   = 0_i4
    INTEGER(i4) :: node_id      = 0_i4
    LOGICAL     :: flag_firstinc = .FALSE.
    LOGICAL     :: need_velocity = .FALSE.
    !-- TODO: BC-family-specific [IN] fields
    !-- [OUT]
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success      = .FALSE.
    REAL(wp)              :: disp_value   = 0.0_wp
    REAL(wp)              :: vel_value    = 0.0_wp
    !-- TODO: BC-family-specific [OUT] diagnostics
  END TYPE PH_XXX_BC_Args

CONTAINS

  !============================================================================
  ! PUBLIC API — thin wrapper (Principle #14 / SIO adaptation for L4_PH BC)
  !============================================================================
  !> PH_XXX_BC_API
  !>
  !> ROLE: THIN WRAPPER ONLY — fills PH_XXX_BC_Args, delegates to PH_XXX_BC_Impl.
  !>   DO NOT add BC physics here; implement in PH_XXX_BC_Impl.
  !>
  !> Parameters (v1.1 ABI — backward compatible with v1.0):
  !>   MD_BC_Desc   [MD] BC parameters (read-only)
  !>   PH_BC_Ctx    [PH] driving inputs: node_id, dof_number, coords, time
  !>   PH_BC_State  [PH] BC state (in/out)
  !>   MD_BC_Algo   [MD] analysis config
  !>   PH_BC_Algo   [PH] iteration ctrl
  !>   RT_Com_Ctx   [RT] bookkeeping: kstep, kinc, time
  !>   disp_value   [OUT] prescribed displacement / DOF value
  !>   vel_value    [OUT] prescribed velocity (OPTIONAL)
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_XXX_BC_API(MD_BC_Desc, PH_BC_Ctx, PH_BC_State, &
                            MD_BC_Algo, PH_BC_Algo, RT_Com_Ctx, &
                            disp_value, vel_value)
    TYPE(MD_BC_Base_Desc),    INTENT(IN)    :: MD_BC_Desc
    TYPE(PH_BC_Base_Ctx),     INTENT(IN)    :: PH_BC_Ctx
    TYPE(PH_XXX_BC_State),    INTENT(INOUT) :: PH_BC_State
    TYPE(MD_BC_Base_Algo),    INTENT(IN)    :: MD_BC_Algo
    TYPE(PH_BC_Base_Algo),    INTENT(IN)    :: PH_BC_Algo
    TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                 INTENT(OUT)   :: disp_value
    REAL(wp), OPTIONAL,       INTENT(OUT)   :: vel_value

    TYPE(PH_XXX_BC_Args) :: bc_args

    bc_args%dof_number    = PH_BC_Ctx%dof_number
    bc_args%node_id       = PH_BC_Ctx%node_id
    bc_args%flag_firstinc = RT_Com_Ctx%first_increment
    bc_args%need_velocity = PRESENT(vel_value)
    !-- TODO: fill additional model-specific bc_args [IN] fields here

    bc_args%success = .FALSE.    ! always reset before delegate call

    CALL PH_XXX_BC_Impl(MD_BC_Desc, PH_BC_Ctx, PH_BC_State, &
                         MD_BC_Algo, PH_BC_Algo, bc_args)

    disp_value = bc_args%disp_value
    IF (PRESENT(vel_value)) vel_value = bc_args%vel_value
  END SUBROUTINE PH_XXX_BC_API

  !============================================================================
  ! PRIVATE IMPLEMENTATION — all BC physics here
  !============================================================================
  !> PH_XXX_BC_Impl
  !>
  !>  Six-parameter inner interface (Principle #14, L4 hot-path form).
  !>  Callers: PH_XXX_BC_API (production) and unit-test harness (direct).
  !>
  !>  Contract:
  !>    args%dof_number     DOF index routing (1=U1 … 6=UR3)
  !>    args%flag_firstinc  .TRUE. => cold-start permitted
  !>    args%need_velocity  .TRUE. => populate args%vel_value
  !>    args%success        .TRUE. IFF BC value computed without error
  !>    args%disp_value     prescribed displacement (or velocity/acc depending on family)
  !>    args%vel_value      prescribed velocity (if args%need_velocity)
  !>    PH_BC_State         updated in-place; undefined if args%success = .FALSE.
  SUBROUTINE PH_XXX_BC_Impl(MD_BC_Desc, PH_BC_Ctx, PH_BC_State, &
                              MD_BC_Algo, PH_BC_Algo, args)
    TYPE(MD_BC_Base_Desc),  INTENT(IN)    :: MD_BC_Desc
    TYPE(PH_BC_Base_Ctx),   INTENT(IN)    :: PH_BC_Ctx
    TYPE(PH_XXX_BC_State),  INTENT(INOUT) :: PH_BC_State
    TYPE(MD_BC_Base_Algo),  INTENT(IN)    :: MD_BC_Algo
    TYPE(PH_BC_Base_Algo),  INTENT(IN)    :: PH_BC_Algo
    TYPE(PH_XXX_BC_Args),   INTENT(INOUT) :: args

    !-- Local variables (stack-allocated; no ALLOCATE in hot path — SIO-09)
    !$UFC HOT_PATH
    REAL(wp) :: time_factor

    !-- Initialize
    CALL init_error_status(args%status)
    args%success    = .FALSE.
    args%disp_value = 0.0_wp
    args%vel_value  = 0.0_wp
    CALL init_error_status(PH_BC_State%status)

    !=========================================================================
    ! Step 1: Time-dependent factor
    !   Routing: bc_type == 3 => user-defined time function
    !            bc_type == 1 => fixed (zero); no time factor needed
    !            bc_type == 2 => prescribed constant magnitude
    !=========================================================================
    IF (MD_BC_Desc%bc_type == 3) THEN
      time_factor = XXX_Time_Function(args%dof_number, &
                                       PH_BC_Ctx%time_current, PH_BC_Ctx%time_total)
    ELSE
      time_factor = 1.0_wp
    END IF

    !=========================================================================
    ! Step 2: Compute BC value based on bc_type
    !   CASE 1: Fixed (homogeneous Dirichlet) — zero DOF value
    !   CASE 2: Prescribed magnitude * amplitude * time_factor
    !   CASE 3: User-defined function (coords, time, DOF-dependent)
    !   TODO: add further cases for tabular amplitude, field-variable BC, etc.
    !=========================================================================
    SELECT CASE (MD_BC_Desc%bc_type)
    CASE (1)  ! Fixed (zero)
      args%disp_value = 0.0_wp
    CASE (2)  ! Prescribed constant
      args%disp_value = MD_BC_Desc%magnitude * time_factor
    CASE (3)  ! User-defined
      args%disp_value = XXX_User_Function(args%node_id, args%dof_number, &
                                          PH_BC_Ctx%coords, &
                                          PH_BC_Ctx%time_current, PH_BC_Ctx%time_total)
    CASE DEFAULT
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_BC_Impl]: unknown bc_type — add CASE or check MD_BC_Desc')
      RETURN
    END SELECT

    !=========================================================================
    ! Step 3: Velocity (if requested by caller)
    !   VEL family: the computed value IS the velocity
    !   DISP family with need_velocity: derive vel = disp / dtime
    !   TODO: adjust for the actual BC family of this module
    !=========================================================================
    IF (args%need_velocity) THEN
      IF (MD_BC_Desc%bc_family == BC_FAMILY_VEL) THEN
        args%vel_value = args%disp_value  ! VEL boundary: value is velocity
      ELSE
        !-- TODO: derive velocity from displacement if required
        args%vel_value = 0.0_wp
      END IF
    END IF

    !=========================================================================
    ! Step 4: Update BC state history
    !=========================================================================
    PH_BC_State%accumulated = args%disp_value
    PH_BC_State%last_value  = args%disp_value

    !-- Finalise
    args%success = .TRUE.
    PH_BC_State%status%status_code = IF_STATUS_OK
    args%status%status_code         = IF_STATUS_OK
  END SUBROUTINE PH_XXX_BC_Impl

  !============================================================================
  ! PRIVATE HELPERS
  !   Name pattern: XXX_<Verb>_<Noun>   (all PRIVATE; only _Impl calls these)
  !============================================================================

  !> XXX_Time_Function
  !>   Time-dependent amplitude factor in [0, 1] (or beyond for loading).
  !>   PURE to allow compiler inlining on hot path.
  !>   Replace body with actual amplitude law:
  !>     Linear ramp:  factor = MIN(time_current / ramp_duration, 1.0_wp)
  !>     Sinusoidal:   factor = SIN(2*PI * frequency * time_total)
  !>     Tabular:      interpolate from MD_BC_Desc amplitude table
  PURE FUNCTION XXX_Time_Function(dof_num, time_current, time_total) RESULT(factor)
    INTEGER(i4), INTENT(IN) :: dof_num      ! DOF index (routing if per-DOF amplitude)
    REAL(wp),    INTENT(IN) :: time_current ! Increment step time
    REAL(wp),    INTENT(IN) :: time_total   ! Total analysis time
    REAL(wp) :: factor
    !-- TODO: replace stub with actual time function
    factor = 1.0_wp   ! Default: static (no time variation)
  END FUNCTION XXX_Time_Function

  !> XXX_User_Function
  !>   User-defined BC value as function of node/DOF/coords/time.
  !>   PURE to enable inlining; add IMPURE ELEMENTAL if I/O needed.
  !>   Replace body with actual user formulation, e.g.:
  !>     Sinusoidal displacement: value = A * SIN(omega * time_total)
  !>     Spatially-varying:       value = B * coords(1)            (linear in X)
  PURE FUNCTION XXX_User_Function(node_id, dof_num, coords, time_current, time_total) &
      RESULT(value)
    INTEGER(i4), INTENT(IN) :: node_id      ! Node label
    INTEGER(i4), INTENT(IN) :: dof_num      ! DOF index
    REAL(wp),    INTENT(IN) :: coords(3)    ! Physical coordinates [m]
    REAL(wp),    INTENT(IN) :: time_current ! Step time
    REAL(wp),    INTENT(IN) :: time_total   ! Total time
    REAL(wp) :: value
    !-- TODO: replace stub with actual user-defined BC law
    value = 0.0_wp
  END FUNCTION XXX_User_Function

END MODULE PH_XXX_BC

!===============================================================================
! STRUCT REFERENCE CARD — BC Domain
!
! ─────────────────────────────────────────────────────────────────────────────
! Layer  Domain  Role   Type name           Variable name    Key members
! ─────────────────────────────────────────────────────────────────────────────
!
! ── MD layer (L3_MD) ────────────────────────────────────────────────────────
!
!  MD  BC   Desc  MD_BC_XXX_Desc      MD_BC_Desc
!    bc_id, bc_family, node_set_id, dof_start/end, bc_type, magnitude
!
!  MD  BC   State MD_BC_Base_State   MD_BC_State
!    accumulated, last_value
!
!  MD  BC   Algo  MD_BC_Base_Algo    MD_BC_Algo
!    apply_mode, print_debug
!
! ── PH layer (L4_PH) ────────────────────────────────────────────────────────
!
!  PH  BC   State PH_XXX_BC_State    PH_BC_State
!    Extends MD_BC_Base_State
!
!  PH  BC   Ctx   PH_BC_Base_Ctx     PH_BC_Ctx
!    node_id, dof_number, time_current, time_total, step_id, inc_id
!
!  PH  BC   Algo  PH_BC_Base_Algo    PH_BC_Algo
!    max_iter, tolerance, pnewdt_min/max
!
! ── RT layer (L5_RT) ────────────────────────────────────────────────────────
!
!  RT  Com   Ctx   RT_Com_Base_Ctx   RT_Com_Ctx
!    time_step, time_total, kstep, kinc
!
!  disp_value  REAL(wp) OUT   Prescribed displacement
!  vel_value   REAL(wp) OUT   Prescribed velocity (optional)
! ─────────────────────────────────────────────────────────────────────────────
!===============================================================================