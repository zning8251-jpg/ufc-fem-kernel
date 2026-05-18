!===============================================================================
! Template: PH_XXX_Contact.f90                                    [Template v1.2]
! Layer:  L4_PH - Physics Layer
! Domain: Contact / [Family] (e.g., FULL / FRIC / COUL / GAP)
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.2 (2026-03)  Single PH_XXX_Contact_Args (replaces _In/_Out); _Impl(args).
!   v1.1 (2026-03)  Add PH_XXX_Contact_In/_Out TYPE pair (Principle #14 SIO);
!                   split API wrapper / Impl physics; fix tau_max local variable
!                   (was erroneously declared as inner FUNCTION — now REAL(wp) local);
!                   upgrade PUBLIC exports.
!   v1.0 (prev)     8-TYPE minimal baseline (tau_max bug present)
!
! PURPOSE:
!   UFC-native contact compute interface.
!   Replaces ABAQUS UINTER/VUINTER/UFRIC/VUFRIC/UCOUL/VUCOUL/GAPCON.
!
! DESIGN: "shen si ABAQUS contact subroutines er xing bu si"
!   - v1.2: PH_XXX_Contact_Args (INOUT) on _Impl; API fills args.
!   - v1.1: Principle #14 IO bundle; PH_XXX_Contact_API thin wrapper → _Impl
!   - v1.0: 8-TYPE minimal system (Desc/State/Algo/Ctx)
!   - Supports: FULL (full interaction), FRIC (friction only), COUL, GAP
!   - No flat arrays; all parameters carried by typed structs
!   - L5_RT and ABAQUS adapters BOTH call THIS interface
!
! ABAQUS SUBROUTINES MAPPED:
!   UINTER   → Standard full contact interaction
!   VUINTER  → Explicit full contact interaction
!   UFRIC    → Standard friction only
!   VUFRIC   → Explicit friction only
!   UCOUL    → Standard Coulomb critical shear
!   VUCOUL   → Explicit Coulomb critical shear
!   GAPCON   → Gap thermal/electrical conductance
!
! NAMING CONVENTION:
!   Module:      PH_[Family]_[Type]_Contact
!   Subroutine:  same name as module + _API suffix
!   XXX: [Family]_[Type] abbreviation
!
! HOW TO USE:
!   1. Copy to L4_PH/Contact/[Family]/
!   2. Rename: PH_[Family]_[Type]_Contact.f90
!   3. Replace XXX -> [Family]_[Type] throughout
!   4. USE matching Desc from L3_MD; define State here
!   5. Add model-specific fields to PH_XXX_Contact_Args if needed
!   6. Implement contact logic in PRIVATE SUBROUTINE PH_XXX_Contact_Impl
!      PH_XXX_Contact_API is generated glue — do NOT add physics there
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-02 ✓  _Impl 6th param is PH_XXX_Contact_Args (INOUT unified bundle)
!   SIO-03 ✓  PH_XXX_Contact_Args carries structured ErrorStatusType status ([OUT]);
!             check %status_code == IF_STATUS_OK
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  _In TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  _In TYPE has no ALLOCATABLE members
!===============================================================================
MODULE PH_XXX_Contact
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Base types
  USE MD_Contact_Types, ONLY: MD_Contact_Base_Desc, &
                              MD_Contact_Base_State, &
                              MD_Contact_Base_Algo
  !-- [PH] Per-increment types
  USE PH_Contact_Types, ONLY: PH_Contact_Base_Ctx, &
                              PH_Contact_Base_Algo
  !-- [RT] Runtime context
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_XXX_Contact_State   ! L4_PH state type (export for unit tests)
  PUBLIC :: PH_XXX_Contact_Args    ! Unified call-time IO bundle (Principle #14)
  PUBLIC :: PH_XXX_Contact_API     ! UFC-native contact entry (thin wrapper -> _Impl)
  ! PH_XXX_Contact_Impl is PRIVATE: contact physics lives there; API is pure glue.

  !-----------------------------------------------------------------------------
  ! STATE type: PH-owned internal state for contact.
  !   Extends MD_Contact_Base_State which provides:
  !     gap_history, slip_accumulated, pressure_cumulative
  !     energy_dissipated, converged, iterations, status
  !   Add contact-family-specific state variables below.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_Contact_Base_State) :: PH_XXX_Contact_State
    !-- TODO: replace/extend placeholders with actual contact model state
    REAL(wp) :: wear_accumulated = 0.0_wp  ! Archard wear accumulation   [m]
    REAL(wp) :: ivar1            = 0.0_wp  ! Placeholder ISV 1 — rename or replace
    REAL(wp) :: ivar2            = 0.0_wp  ! Placeholder ISV 2 — rename or replace
  END TYPE PH_XXX_Contact_State

  !-----------------------------------------------------------------------------
  ! PH_XXX_Contact_Args — unified bundle (Principle #14, L4 adaptation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_XXX_Contact_Args
    !-- [IN]
    INTEGER(i4) :: contact_pair_id = 0_i4
    LOGICAL     :: flag_firstinc   = .FALSE.
    LOGICAL     :: flag_nlgeom     = .FALSE.
    LOGICAL     :: flag_symmetric  = .TRUE.
    !-- TODO: contact-family-specific [IN] fields
    !-- [OUT]
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success       = .FALSE.
    LOGICAL               :: in_contact    = .FALSE.
    REAL(wp)              :: press         = 0.0_wp
    REAL(wp)              :: tau1          = 0.0_wp
    REAL(wp)              :: tau2          = 0.0_wp
    REAL(wp)              :: work_fric_incr = 0.0_wp
    !-- TODO: contact-family-specific [OUT] fields
  END TYPE PH_XXX_Contact_Args

CONTAINS

  !============================================================================
  ! PUBLIC API — thin wrapper (Principle #14 / SIO adaptation for L4_PH Contact)
  !============================================================================
  !> PH_XXX_Contact_API
  !>
  !> ROLE: THIN WRAPPER ONLY — fills PH_XXX_Contact_Args, delegates to PH_XXX_Contact_Impl.
  !>   DO NOT add contact physics here; implement in PH_XXX_Contact_Impl.
  !>
  !> Parameters (v1.1 ABI — backward compatible with v1.0):
  !>   MD_Contact_Desc  [MD] contact parameters (read-only)
  !>   PH_Contact_Ctx   [PH] driving inputs: gap, slip1, slip2, pressure, temp
  !>   PH_Contact_State [PH] contact state (in/out)
  !>   MD_Contact_Algo  [MD] analysis config
  !>   PH_Contact_Algo  [PH] iteration ctrl
  !>   RT_Com_Ctx       [RT] bookkeeping
  !>   press            [OUT] contact normal pressure [Pa] (positive = compressive)
  !>   tau1             [OUT] tangential stress direction 1 [Pa]
  !>   tau2             [OUT] tangential stress direction 2 [Pa]
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_XXX_Contact_API(MD_Contact_Desc, PH_Contact_Ctx, PH_Contact_State, &
                                 MD_Contact_Algo, PH_Contact_Algo, RT_Com_Ctx, &
                                 press, tau1, tau2)
    TYPE(MD_Contact_Base_Desc),   INTENT(IN)    :: MD_Contact_Desc
    TYPE(PH_Contact_Base_Ctx),    INTENT(IN)    :: PH_Contact_Ctx
    TYPE(PH_XXX_Contact_State),   INTENT(INOUT) :: PH_Contact_State
    TYPE(MD_Contact_Base_Algo),   INTENT(IN)    :: MD_Contact_Algo
    TYPE(PH_Contact_Base_Algo),   INTENT(IN)    :: PH_Contact_Algo
    TYPE(RT_Com_Base_Ctx),        INTENT(IN)    :: RT_Com_Ctx
    REAL(wp),                     INTENT(OUT)   :: press
    REAL(wp),                     INTENT(OUT)   :: tau1
    REAL(wp),                     INTENT(OUT)   :: tau2

    TYPE(PH_XXX_Contact_Args) :: ct_args

    ct_args%contact_pair_id = MD_Contact_Desc%contact_id
    ct_args%flag_firstinc   = RT_Com_Ctx%first_increment
    ct_args%flag_nlgeom     = RT_Com_Ctx%nlgeom
    ct_args%flag_symmetric  = .TRUE.   ! TODO: read from MD_Contact_Desc if present
    !-- TODO: fill additional model-specific ct_args [IN] fields here

    ct_args%success = .FALSE.    ! always reset before delegate call

    CALL PH_XXX_Contact_Impl(MD_Contact_Desc, PH_Contact_Ctx, PH_Contact_State, &
                              MD_Contact_Algo, PH_Contact_Algo, ct_args)

    press = ct_args%press
    tau1  = ct_args%tau1
    tau2  = ct_args%tau2
  END SUBROUTINE PH_XXX_Contact_API

  !============================================================================
  ! PRIVATE IMPLEMENTATION — all contact physics here
  !============================================================================
  !> PH_XXX_Contact_Impl
  !>
  !>  Six-parameter inner interface (Principle #14, L4 hot-path form).
  !>  Callers: PH_XXX_Contact_API (production) and unit-test harness (direct).
  !>
  !>  Contract:
  !>    args%contact_pair_id  identifier for multi-pair dispatch
  !>    args%flag_nlgeom      .TRUE. => large-deformation kinematics required
  !>    args%flag_symmetric   .TRUE. => symmetric K contribution (penalty/Lagrange)
  !>    args%success          .TRUE. IFF contact evaluated without error
  !>    args%in_contact       .TRUE. IFF gap <= 0 (active contact)
  !>    args%press            normal pressure (positive = compressive) [Pa]
  !>    args%tau1/tau2        tangential stress in slip directions 1/2 [Pa]
  !>    args%work_fric_incr   friction work increment this step [J/m²]
  !>    PH_Contact_State     updated in-place; undefined if args%success = .FALSE.
  !>
  !>  BUG FIX vs v1.0:
  !>    tau_max was erroneously declared as an inner FUNCTION inside
  !>    PH_XXX_Contact_API CONTAINS block (invalid Fortran — only SUBROUTINEs
  !>    allowed there).  Now correctly declared as a REAL(wp) local variable.
  SUBROUTINE PH_XXX_Contact_Impl(MD_Contact_Desc, PH_Contact_Ctx, PH_Contact_State, &
                                   MD_Contact_Algo, PH_Contact_Algo, args)
    TYPE(MD_Contact_Base_Desc),   INTENT(IN)    :: MD_Contact_Desc
    TYPE(PH_Contact_Base_Ctx),    INTENT(IN)    :: PH_Contact_Ctx
    TYPE(PH_XXX_Contact_State),   INTENT(INOUT) :: PH_Contact_State
    TYPE(MD_Contact_Base_Algo),   INTENT(IN)    :: MD_Contact_Algo
    TYPE(PH_Contact_Base_Algo),   INTENT(IN)    :: PH_Contact_Algo
    TYPE(PH_XXX_Contact_Args),    INTENT(INOUT) :: args

    !-- Local variables (stack-allocated; no ALLOCATE in hot path — SIO-09)
    !$UFC HOT_PATH
    REAL(wp) :: gap, slip_mag, fric_coeff, normal_stiff
    REAL(wp) :: tau_max   ! v1.1 FIX: local variable (was erroneously an inner FUNCTION)

    !-- Initialize
    CALL init_error_status(args%status)
    args%success        = .FALSE.
    args%in_contact     = .FALSE.
    args%press          = 0.0_wp
    args%tau1           = 0.0_wp
    args%tau2           = 0.0_wp
    args%work_fric_incr = 0.0_wp
    CALL init_error_status(PH_Contact_State%status)

    gap      = PH_Contact_Ctx%gap
    slip_mag = SQRT(PH_Contact_Ctx%slip1**2 + PH_Contact_Ctx%slip2**2)

    !=========================================================================
    ! Step 1: Normal contact behavior
    !   gap <= 0 : contact active — compute normal pressure
    !   gap >  0 : open gap — all outputs zero, early return
    !   Normal behavior types:
    !     1 = Hard contact (Lagrange enforced; pressure returned from solver)
    !     2 = Penalty      press = -k_n * gap  (linear spring)
    !     3 = Exponential  press = -k_n * exp(gap / gap_ref)
    !   TODO: add CASE 4 for augmented Lagrange or pressure-overclosure table
    !=========================================================================
    IF (gap <= 0.0_wp) THEN
      args%in_contact = .TRUE.
      SELECT CASE (MD_Contact_Desc%normal_behavior)
      CASE (1)  ! Hard contact (Lagrange): solver enforces gap=0; pressure is output
        args%press = 0.0_wp   ! TODO: filled by Lagrange multiplier from solver
      CASE (2)  ! Penalty: linear normal spring
        normal_stiff = MD_Contact_Desc%normal_stiffness
        args%press    = -normal_stiff * gap  ! compressive => positive press
      CASE (3)  ! Exponential (softened)
        args%press = -MD_Contact_Desc%normal_stiffness &
                  * EXP(gap / MD_Contact_Desc%contact_threshold)
      CASE DEFAULT
        CALL init_error_status(args%status, IF_STATUS_ERROR, &
            message='[XXX_Contact_Impl]: unknown normal_behavior — check MD_Contact_Desc')
        RETURN
      END SELECT
    ELSE
      !-- Open gap: no contact, early exit
      args%success = .TRUE.
      PH_Contact_State%status%status_code = IF_STATUS_OK
      args%status%status_code              = IF_STATUS_OK
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Tangential (friction) behavior
    !   Friction law types:
    !     1 = Coulomb:      |tau| <= mu * press;  tau = mu*p * (slip/|slip|)
    !     2 = Shear limit:  |tau| <= shear_limit  (e.g., Tresca-type)
    !     3 = User-defined: CALL XXX_User_Friction
    !   STICK criterion: slip_mag < stick_tol => tau computed from elastic stiffness
    !   TODO: add CASE 4 for exponential decay friction (Oden-Pires)
    !=========================================================================
    SELECT CASE (MD_Contact_Desc%fric_law)
    CASE (1)  ! Coulomb
      fric_coeff = XXX_Friction_Coeff(MD_Contact_Desc, PH_Contact_Ctx)
      tau_max    = fric_coeff * args%press
      IF (slip_mag > 1.0e-10_wp) THEN
        args%tau1 = tau_max * PH_Contact_Ctx%slip1 / slip_mag
        args%tau2 = tau_max * PH_Contact_Ctx%slip2 / slip_mag
      ELSE
        args%tau1 = 0.0_wp   ! Stick: no resultant slip direction
        args%tau2 = 0.0_wp
      END IF
    CASE (2)  ! Shear limit (Tresca-type)
      tau_max = MD_Contact_Desc%shear_limit
      IF (slip_mag > 1.0e-10_wp) THEN
        args%tau1 = tau_max * PH_Contact_Ctx%slip1 / slip_mag
        args%tau2 = tau_max * PH_Contact_Ctx%slip2 / slip_mag
      ELSE
        args%tau1 = 0.0_wp
        args%tau2 = 0.0_wp
      END IF
    CASE (3)  ! User-defined friction law
      CALL XXX_User_Friction(MD_Contact_Desc, PH_Contact_Ctx, args%tau1, args%tau2)
    CASE DEFAULT
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[XXX_Contact_Impl]: unknown fric_law — check MD_Contact_Desc')
      RETURN
    END SELECT

    !=========================================================================
    ! Step 3: Update contact state history
    !=========================================================================
    PH_Contact_State%gap_history          = gap
    PH_Contact_State%slip_accumulated     = PH_Contact_State%slip_accumulated + slip_mag
    PH_Contact_State%pressure_cumulative  = PH_Contact_State%pressure_cumulative + args%press

    !-- Friction work dissipation per unit area [J/m²]
    args%work_fric_incr = args%tau1 * PH_Contact_Ctx%slip1 &
                       + args%tau2 * PH_Contact_Ctx%slip2
    PH_Contact_State%energy_dissipated = PH_Contact_State%energy_dissipated &
                                       + args%work_fric_incr

    !-- TODO: wear model (Archard): delta_wear = k_w * press * slip_mag / hardness
    ! PH_Contact_State%wear_accumulated = PH_Contact_State%wear_accumulated + delta_wear

    !-- Finalise
    args%success = .TRUE.
    PH_Contact_State%status%status_code = IF_STATUS_OK
    args%status%status_code              = IF_STATUS_OK
  END SUBROUTINE PH_XXX_Contact_Impl

  !============================================================================
  ! PRIVATE HELPERS
  !   Name pattern: XXX_<Verb>_<Noun>   (all PRIVATE; only _Impl calls these)
  !============================================================================

  !> XXX_Friction_Coeff
  !>   Compute effective Coulomb friction coefficient mu.
  !>   PURE; receives Desc and Ctx for state-dependent mu.
  !>   Replace body with actual mu law, e.g.:
  !>     Constant:            mu = MD_Contact_Desc%fric_coeff
  !>     Pressure-dependent:  mu = mu_0 * (1 + k * press)
  !>     Velocity-dependent:  mu = mu_s + (mu_d - mu_s)*exp(-decay*slip_rate)
  !>     Tabular:             interpolate from Desc%fric_table
  PURE FUNCTION XXX_Friction_Coeff(MD_Contact_Desc, PH_Contact_Ctx) RESULT(mu)
    TYPE(MD_Contact_Base_Desc), INTENT(IN) :: MD_Contact_Desc
    TYPE(PH_Contact_Base_Ctx),  INTENT(IN) :: PH_Contact_Ctx
    REAL(wp) :: mu
    !-- TODO: replace stub with actual friction coefficient law
    !   Example pressure-dependent:
    !   mu = MD_Contact_Desc%fric_coeff * (1.0_wp + 0.01_wp * PH_Contact_Ctx%pressure)
    mu = MD_Contact_Desc%fric_coeff   ! Default: constant Coulomb coefficient
  END FUNCTION XXX_Friction_Coeff

  !> XXX_User_Friction
  !>   User-defined friction stress (advanced, non-Coulomb laws).
  !>   Called only for fric_law == 3; replace body with actual formulation.
  !>   Examples:
  !>     Oden-Pires exponential:  tau = tau_inf * tanh(slip_mag / slip_ref)
  !>     Anisotropic:             tau direction decoupled from slip direction
  SUBROUTINE XXX_User_Friction(MD_Contact_Desc, PH_Contact_Ctx, tau1_out, tau2_out)
    TYPE(MD_Contact_Base_Desc), INTENT(IN)  :: MD_Contact_Desc
    TYPE(PH_Contact_Base_Ctx),  INTENT(IN)  :: PH_Contact_Ctx
    REAL(wp),                   INTENT(OUT) :: tau1_out  ! Friction stress dir 1 [Pa]
    REAL(wp),                   INTENT(OUT) :: tau2_out  ! Friction stress dir 2 [Pa]
    !-- TODO: replace stub with actual user-defined friction law
    tau1_out = 0.0_wp
    tau2_out = 0.0_wp
  END SUBROUTINE XXX_User_Friction

END MODULE PH_XXX_Contact

!===============================================================================
! STRUCT REFERENCE CARD — Contact Domain
!
! ─────────────────────────────────────────────────────────────────────────────
! Layer  Domain  Role   Type name               Variable name    Key members
! ─────────────────────────────────────────────────────────────────────────────
!
! ── MD layer (L3_MD) ────────────────────────────────────────────────────────
!
!  MD  Contact Desc  MD_Contact_XXX_Desc    MD_Contact_Desc
!    contact_id, contact_family, master/slave_surface,
!    normal_behavior, normal_stiffness, fric_law, fric_coeff, shear_limit
!
!  MD  Contact State MD_Contact_Base_State MD_Contact_State
!    gap_history, slip_accumulated, pressure_cumulative, energy_dissipated
!
!  MD  Contact Algo  MD_Contact_Base_Algo  MD_Contact_Algo
!    algorithm, use_stabilization, print_debug
!
! ── PH layer (L4_PH) ────────────────────────────────────────────────────────
!
!  PH  Contact State PH_XXX_Contact_State  PH_Contact_State
!    Extends MD_Contact_Base_State; adds wear_accumulated, etc.
!
!  PH  Contact Ctx   PH_Contact_Base_Ctx   PH_Contact_Ctx
!    gap, slip1, slip2, pressure, temp, coords, elem_id, integ_pt_id
!
!  PH  Contact Algo  PH_Contact_Base_Algo  PH_Contact_Algo
!    max_iter, tolerance, pnewdt_min/max, use_stabilization
!
! ── RT layer (L5_RT) ────────────────────────────────────────────────────────
!
!  RT  Com   Ctx   RT_Com_Base_Ctx        RT_Com_Ctx
!    time_step, time_total, kstep, kinc, nlgeom
!
!  press  REAL(wp) OUT  Contact normal pressure (positive=compressive)
!  tau1   REAL(wp) OUT  Tangential stress in direction 1
!  tau2   REAL(wp) OUT  Tangential stress in direction 2
! ─────────────────────────────────────────────────────────────────────────────
!===============================================================================