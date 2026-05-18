!===============================================================================
! Template: PH_Thm_Flux.f90                                    [Template v1.0]
! Layer:  L4_PH — Physics Layer
! Domain: Thermal / FluxBC (DFLUX — Distributed Surface/Body Heat Flux BC)
! Abaqus: DFLUX / VDFLUX (surface or body heat flux)
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.0 (2026-04)  Initial: uniform / nonuniform / Gaussian / body flux models
!
! PURPOSE:
!   UFC-native distributed heat flux boundary condition interface.
!   Returns heat flux magnitude q [W/m²] on a surface facet or body element.
!
! PHYSICS:
!   Surface flux:    q = Q_flux · f(time, coords, TEMP)  [W/m²]
!   Body flux:      Q_body = q · A / V  [W/m³] (A = surface area, V = vol.)
!   Gauss heat:     q(r) = q0 · exp(-r² / r0²)  [nonuniform spot heat]
!
! DFLUX TYPE TAXONOMY (flux_type):
!   0 = Surface flux (default)
!   1 = Body flux (volumetric heat source per unit volume)
!
! SIO COMPLIANCE (Principle #14):
!   SIO-01  ✓  Single PH_Thm_Flux_Args bundle
!   SIO-02  ✓  _Impl 6th param is PH_Thm_Flux_Args
!   SIO-03  ✓  Args carry structured ErrorStatusType status; check %status_code
!   SIO-07  ✓  No INTENT(...) in TYPE bodies
!
! ABAQUS DFLUX ARGUMENTS (reference):
!   SUBROUTINE DFLUX(FLOW, SENSE, ELEMENT, KPOINT, KINC, TIME, NODE,
!                    COORDS, NOEL, NPT, STEEL, NODE, FLOW, AREA,
!                    JLTYP, VALUE, KES, FLUX, DTIME, T(2), DTEMP,
!                    PROPS, NPROPS, JLTYF)
!   VDFLUX: similar but for Explicit
!
!   FLOW   [OUT] — flux value [W/m² for surface, W/m³ for body]
!   SENSE  [IN]  — 1 = surface flux, 2 = body flux
!   COORDS [IN]  — integration point coordinates [m]
!   AREA   [IN]  — facet area [m²] (surface flux)
!   NODE   [IN]  — node number (Nodal flux)
!   PROPS  [IN]  — material/flux constants
!===============================================================================
MODULE PH_Thm_Flux
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Thm_Flux_State    ! L4_PH state (export for unit tests)
  PUBLIC :: PH_Thm_Flux_Args     ! Unified IN/OUT call bundle (Principle #14)
  PUBLIC :: PH_Thm_Flux_API      ! UFC-native entry (thin wrapper → _Impl)
  ! PH_Thm_Flux_Impl is PRIVATE.

  !-----------------------------------------------------------------------------
  ! Flux BC model constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: DFLUX_SURFACE      = 0_i4  ! q [W/m²]
  INTEGER(i4), PARAMETER, PUBLIC :: DFLUX_BODY          = 1_i4  ! Q_body [W/m³]
  INTEGER(i4), PARAMETER, PUBLIC :: DFLUX_UNIFORM       = 10_i4 ! q = q0·f(t)
  INTEGER(i4), PARAMETER, PUBLIC :: DFLUX_GAUSSIAN     = 11_i4 ! q(r) = q0·exp(-r²/r₀²)
  INTEGER(i4), PARAMETER, PUBLIC :: DFLUX_LINEAR_DECAY = 12_i4 ! q(x) = q0·(1-x/L)
  INTEGER(i4), PARAMETER, PUBLIC :: DFLUX_USERDEF       = 99_i4 ! full user model

  !============================================================================
  ! STATE type
  !============================================================================
  TYPE, PUBLIC :: PH_Thm_Flux_State
    !-- Previous flux value (for convergence monitoring)
    REAL(wp) :: flux_prev = 0.0_wp
    !-- Cumulative total heat through this BC [J/m²]
    REAL(wp) :: Q_cumulative = 0.0_wp
    !-- Source centre for Gaussian decay (initialised once per BC set)
    REAL(wp) :: source_centre(3) = 0.0_wp
    REAL(wp) :: source_radius = 0.0_wp
    LOGICAL  :: is_initialised = .FALSE.
    LOGICAL  :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Thm_Flux_State

  !============================================================================
  ! ARGS type: Unified IN/OUT bundle (Principle #14 SIO)
  !============================================================================
  TYPE, PUBLIC :: PH_Thm_Flux_Args
    !-- [IN] Surface/body element data
    REAL(wp)    :: coords(3)   = 0.0_wp   ! integration point coordinates [m]
    REAL(wp)    :: normal(3)   = 0.0_wp   ! outward surface normal (surface flux)
    REAL(wp)    :: area        = 0.0_wp   ! facet area [m²] (surface flux)
    INTEGER(i4)  :: flux_type  = DFLUX_SURFACE  ! 0=surface, 1=body

    !-- [IN] Time bookkeeping
    REAL(wp)    :: time_curr   = 0.0_wp   ! step time
    REAL(wp)    :: time_total  = 0.0_wp   ! total time
    REAL(wp)    :: dtime       = 0.0_wp   ! time increment [s]

    !-- [IN] Temperature data
    REAL(wp)    :: temp_curr   = 0.0_wp   ! surface/body temperature [K]
    REAL(wp)    :: dtemp       = 0.0_wp   ! temperature increment [K]

    !-- [IN] Flux BC parameters
    INTEGER(i4)  :: flux_model  = DFLUX_UNIFORM  ! model selection
    REAL(wp)     :: q0          = 0.0_wp   ! peak/constant flux magnitude [W/m²]
    REAL(wp)     :: q_scale     = 1.0_wp  ! scaling factor

    !-- [IN] Gaussian spot heat parameters
    REAL(wp)     :: centre(3)  = 0.0_wp  ! Gaussian centre [m]
    REAL(wp)     :: sigma_r     = 0.01_wp ! Gaussian spread σ [m] (q = q0·exp(-r²/2σ²))
    REAL(wp)     :: beam_radius = 0.01_wp ! laser/EB beam radius [m]

    !-- [IN] Linear decay parameters
    REAL(wp)     :: decay_L    = 1.0_wp   ! decay length [m] (q = q0·(1 - x/L))
    REAL(wp)     :: decay_dir  = 1.0_wp   ! decay direction (x=1, y=2, z=3)

    !-- [IN] Surface area and volume (for body ↔ surface conversion)
    REAL(wp)     :: body_vol   = 0.0_wp   ! element volume [m³] (body flux)
    REAL(wp)     :: surf_area  = 0.0_wp   ! heating surface area [m²]

    !-- [IN] Amplitude
    LOGICAL      :: use_amplitude = .FALSE.
    REAL(wp)     :: amp_factor    = 1.0_wp   ! current amplitude

    !-- [OUT] Flux outputs
    REAL(wp)     :: flux_mag  = 0.0_wp   ! heat flux magnitude [W/m² or W/m³]
    REAL(wp)     :: flux_dT   = 0.0_wp   ! d(flux)/dT (Newton linearisation)

    !-- [OUT] Diagnostics
    REAL(wp)     :: r_distance = 0.0_wp  ! distance from Gaussian centre
    REAL(wp)     :: heat_power = 0.0_wp  ! total heat [W] (= flux·area)

    !-- [OUT] Error handling
    TYPE(ErrorStatusType) :: status
    LOGICAL  :: success = .FALSE.
  END TYPE PH_Thm_Flux_Args

CONTAINS

  !============================================================================
  ! PH_Thm_Flux_API — THIN WRAPPER
  !============================================================================
  SUBROUTINE PH_Thm_Flux_API(args, state, err_status)
    TYPE(PH_Thm_Flux_Args),   INTENT(INOUT) :: args
    TYPE(PH_Thm_Flux_State),  INTENT(INOUT) :: state
    TYPE(ErrorStatusType),      INTENT(INOUT) :: err_status

    CALL init_error_status(err_status, IF_STATUS_OK)
    args%success = .FALSE.
    CALL PH_Thm_Flux_Impl(args, state)
    err_status = args%status
    IF (.NOT. args%success) CALL init_error_status(err_status, IF_STATUS_ERROR)
  END SUBROUTINE PH_Thm_Flux_API

  !============================================================================
  ! PH_Thm_Flux_Impl — Physics kernel (PRIVATE, hot path)
  !
  ! §UNIFORM FLUX:
  !   q = q0 · amp_factor
  !
  ! §GAUSSIAN HEAT (laser / electron beam welding, surface heating):
  !   q(r) = q0 · exp(-2·r² / beam_radius²)
  !   where r = |coords - centre|  (distance from beam centre)
  !
  ! §LINEAR DECAY (weld torch moving along x):
  !   q(x) = q0 · MAX(1 - x/L, 0)  (flux linearly decays from x=0 to x=L)
  !
  ! §BODY FLUX CONVERSION:
  !   For volumetric heat generation: Q_body [W/m³] = q_surface [W/m²] × A [m²] / V [m³]
  !   (Divides surface heat over element volume)
  !============================================================================
  SUBROUTINE PH_Thm_Flux_Impl(args, state)
    TYPE(PH_Thm_Flux_Args),  INTENT(INOUT) :: args
    TYPE(PH_Thm_Flux_State), INTENT(INOUT) :: state

    REAL(wp) :: r              ! distance from heat source centre
    REAL(wp) :: decay_x       ! normalized distance for linear decay
    REAL(wp) :: q_base         ! amplitude-scaled base flux

    !-- Initialise state on first call
    IF (.NOT. state%is_initialised) THEN
      state%source_centre = args%centre
      state%source_radius = args%beam_radius
      state%is_initialised = .TRUE.
    END IF

    !-- Base flux with amplitude
    q_base = args%q0 * args%q_scale
    IF (args%use_amplitude) q_base = q_base * args%amp_factor

    !-- §FLUX MODEL SELECTION
    SELECT CASE (args%flux_model)

    !------------------------------------------------------------------------
    CASE (DFLUX_UNIFORM)
    !   Uniform distributed heat flux over the surface.
    !------------------------------------------------------------------------
      args%flux_mag = q_base
      args%flux_dT  = 0.0_wp
      args%r_distance = 0.0_wp

    !------------------------------------------------------------------------
    CASE (DFLUX_GAUSSIAN)
    !   Gaussian heat distribution (laser, electron beam, plasma arc).
    !   Standard Gaussian: q(r) = q0 · exp(-r² / r0²)
    !   Industrial:         q(r) = q0 · exp(-2·r² / w²)  (peak flux at r=0)
    !   where r = distance from beam centre
    !------------------------------------------------------------------------
      r = SQRT((args%coords(1) - state%source_centre(1))**2 &
             + (args%coords(2) - state%source_centre(2))**2 &
             + (args%coords(3) - state%source_centre(3))**2)
      args%r_distance = r
      ! Gaussian: q = q0 · exp(-2·r²/w²)  (w = beam_radius)
      IF (args%beam_radius > 1.0e-30_wp) THEN
        args%flux_mag = q_base * EXP(-2.0_wp * (r / args%beam_radius)**2)
      ELSE
        args%flux_mag = q_base
      END IF
      ! dflux/dT: Gaussian flux is T-independent → 0
      args%flux_dT = 0.0_wp

    !------------------------------------------------------------------------
    CASE (DFLUX_LINEAR_DECAY)
    !   Linear decay from source: q(x) = q0 · (1 - x/L)
    !   Used for: moving heat source, weld pool trailing edge
    !------------------------------------------------------------------------
      IF (args%decay_dir == 1_i4) THEN
        decay_x = args%coords(1) - state%source_centre(1)
      ELSE IF (args%decay_dir == 2_i4) THEN
        decay_x = args%coords(2) - state%source_centre(2)
      ELSE
        decay_x = args%coords(3) - state%source_centre(3)
      END IF
      decay_x = decay_x / MAX(args%decay_L, 1.0e-30_wp)
      args%flux_mag = q_base * MAX(1.0_wp - decay_x, 0.0_wp)
      args%flux_dT  = 0.0_wp
      args%r_distance = ABS(decay_x)

    !------------------------------------------------------------------------
    CASE (DFLUX_USERDEF)
    !   Full user-defined heat flux model.
    !   Replace with: e.g. sinusoidal, pulsed, multi-source, etc.
    !------------------------------------------------------------------------
      ! TODO: implement user model
      args%flux_mag = q_base
      args%flux_dT  = 0.0_wp

    CASE DEFAULT
      args%flux_mag = q_base
      args%flux_dT  = 0.0_wp
    END SELECT

    !-- §BODY ↔ SURFACE FLUX CONVERSION
    IF (args%flux_type == DFLUX_BODY) THEN
      ! Convert surface flux [W/m²] to volumetric rate [W/m³]
      IF (args%body_vol > 1.0e-30_wp) THEN
        args%flux_mag = args%flux_mag * args%surf_area / args%body_vol
      ELSE
        args%flux_mag = 0.0_wp
      END IF
    END IF

    !-- §TOTAL HEAT POWER
    args%heat_power = args%flux_mag * MAX(args%area, 1.0_wp)

    !-- §STATE UPDATE
    state%flux_prev = args%flux_mag
    state%Q_cumulative = state%Q_cumulative + args%flux_mag * args%dtime
    state%is_updated = .TRUE.

    args%success = .TRUE.
    CALL init_error_status(args%status, IF_STATUS_OK)

  END SUBROUTINE PH_Thm_Flux_Impl

  !============================================================================
  ! PH_Thm_Flux_Init — Initialiser
  !============================================================================
  SUBROUTINE PH_Thm_Flux_Init(state, err_status)
    TYPE(PH_Thm_Flux_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),    INTENT(INOUT) :: err_status

    state%flux_prev = 0.0_wp
    state%Q_cumulative = 0.0_wp
    state%source_centre = 0.0_wp
    state%source_radius = 0.0_wp
    state%is_initialised = .FALSE.
    state%is_updated = .FALSE.
    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE PH_Thm_Flux_Init

END MODULE PH_Thm_Flux
