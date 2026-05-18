!===============================================================================
! Template: PH_Thm_Film.f90                                    [Template v1.0]
! Layer:  L4_PH — Physics Layer
! Domain: Thermal / FilmBC (FILM — Convective Heat Transfer BC)
! Abaqus: FILM (surface film / convection boundary)
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.0 (2026-04)  Initial: constant / T-dependent / velocity-dependent / radiation
!
! PURPOSE:
!   UFC-native surface film (convection) boundary condition interface.
!   Returns film coefficient h and sink temperature T_sink for thermal BC assembly.
!
! PHYSICS:
!   Convection BC:  q = h · (T_sink - T_surface)  [W/m²]
!   Radiation BC:   q_rad = ε·σ·(T_amb⁴ - T⁴)  [W/m²]
!   Combined:      q_total = h·(T_sink - T) + ε·σ·(T_amb⁴ - T⁴)
!
! FILM MODEL TAXONOMY (hetype parameter):
!   1 = Constant:        h = h0 (user constant)
!   2 = T-dependent:     h = h(T_surface)
!   3 = T_amb-dependent:  h = h(T_ambient)  [free convection correlation]
!   4 = v-dependent:      h = h(v_fluid)    [forced convection, Dittus-Boelter]
!   5 = Radiation-linear: q_rad ≈ h_rad·(T_amb - T), h_rad = 4·ε·σ·T³
!   6 = Combined:        FILM + radiation linearization
!
! SIO COMPLIANCE (Principle #14):
!   SIO-01  ✓  Single PH_Thm_Film_Args bundle
!   SIO-02  ✓  _Impl 6th param is PH_Thm_Film_Args
!   SIO-03  ✓  Args carry structured ErrorStatusType status; check %status_code
!   SIO-07  ✓  No INTENT(...) in TYPE bodies
!
! ABAQUS FILM ARGUMENTS (reference):
!   SUBROUTINE FILM(SINK, FLUX, FNDS, COORDS, TEMP, VALUE, 
!                   KSTEP, KINC, TIME, DTIME, AREA, JLTYP,
!                   FIELD, NFIELD, FIELDID, NOEL, NPT, LAYER, KSPT,
!                   KDIR, DFDT, DFDTK, SNAME, PROPS, NPROPS, 
!                   JPROPS, NJPROPS, TRANS, LFLAGS, JLTYF, ST、厚,
!                   KSECSTPT, KSECFLPT)
!     SINK   [OUT] — sink temperature T_sink [K]
!     FLUX   [OUT] — heat flux q [W/m²] (negative = leaving body)
!     FNDS   [OUT] — film coefficient h [W/(m²·K)]
!     DFDT   [OUT] — d(FLUX)/dT  (Newton linearisation)
!     TEMP   [IN]  — surface temperature [K]
!     VALUE  [IN]  — film coefficient or amplitude value
!     COORDS [IN]  — surface point coordinates [m]
!     PROPS  [IN]  — material constants
!===============================================================================
MODULE PH_Thm_Film
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Thm_Film_State   ! L4_PH state (export for unit tests)
  PUBLIC :: PH_Thm_Film_Args    ! Unified IN/OUT call bundle (Principle #14)
  PUBLIC :: PH_Thm_Film_API     ! UFC-native entry (thin wrapper → _Impl)
  ! PH_Thm_Film_Impl is PRIVATE.

  !-----------------------------------------------------------------------------
  ! Film BC model constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: FILM_CONSTANT       = 1_i4  ! h = h0
  INTEGER(i4), PARAMETER, PUBLIC :: FILM_T_DEPENDENT     = 2_i4  ! h = h(T)
  INTEGER(i4), PARAMETER, PUBLIC :: FILM_AMB_DEPENDENT   = 3_i4  ! h = h(T_amb) — free conv.
  INTEGER(i4), PARAMETER, PUBLIC :: FILM_V_DEPENDENT    = 4_i4  ! h = h(v) — forced conv.
  INTEGER(i4), PARAMETER, PUBLIC :: FILM_RADIATION_LINEAR = 5_i4 ! radiation linearized
  INTEGER(i4), PARAMETER, PUBLIC :: FILM_COMBINED        = 6_i4  ! FILM + radiation

  !-----------------------------------------------------------------------------
  ! Stefan-Boltzmann constant and radiation constants
  !-----------------------------------------------------------------------------
  REAL(wp), PARAMETER, PUBLIC :: STEFAN_BOLTZMANN = 5.670374419e-8_wp  ! σ [W/(m²·K⁴)]

  !============================================================================
  ! STATE type
  !============================================================================
  TYPE, PUBLIC :: PH_Thm_Film_State
    !-- Film coefficient at previous iteration (for convergence monitoring)
    REAL(wp) :: h_prev = 0.0_wp
    !-- Cumulative heat flux through this BC (for output diagnostics)
    REAL(wp) :: Q_total = 0.0_wp
    !-- Previous surface temperature (for dhdt numerical evaluation)
    REAL(wp) :: T_surface_prev = 0.0_wp
    !-- Iteration convergence flag
    LOGICAL  :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Thm_Film_State

  !============================================================================
  ! ARGS type: Unified IN/OUT bundle (Principle #14 SIO)
  !============================================================================
  TYPE, PUBLIC :: PH_Thm_Film_Args
    !-- [IN] Surface state
    REAL(wp)    :: T_surface   = 0.0_wp   ! surface temperature [K]
    REAL(wp)    :: coords(3)   = 0.0_wp   ! surface point coordinates [m]

    !-- [IN] Time bookkeeping
    REAL(wp)    :: time_curr   = 0.0_wp   ! step time
    REAL(wp)    :: time_total  = 0.0_wp   ! total time
    REAL(wp)    :: dtime       = 0.0_wp   ! time increment [s]

    !-- [IN] Film BC parameters
    INTEGER(i4)  :: film_type  = FILM_CONSTANT  ! model selection
    REAL(wp)     :: h0_const   = 0.0_wp   ! constant film coeff [W/(m²·K)]
    REAL(wp)     :: h_scale    = 1.0_wp   ! scaling factor
    REAL(wp)     :: T_sink     = 293.15_wp ! sink (ambient) temperature [K]

    !-- [IN] Temperature-dependent h parameters: h(T) = a + b·T + c·T²
    REAL(wp)     :: h_T_a      = 0.0_wp   ! h(T) = a + b·T [W/(m²·K)]
    REAL(wp)     :: h_T_b      = 0.0_wp   ! coefficient of linear term
    REAL(wp)     :: h_T_c      = 0.0_wp   ! coefficient of T² term

    !-- [IN] Velocity-dependent h parameters: Dittus-Boelter h = 0.023·Re^0.8·Pr^0.4·k/D
    REAL(wp)     :: fluid_v    = 0.0_wp   ! fluid velocity magnitude [m/s]
    REAL(wp)     :: fluid_k    = 0.025_wp  ! fluid thermal conductivity [W/(m·K)]
    REAL(wp)     :: fluid_cp   = 4184.0_wp ! fluid specific heat [J/(kg·K)]
    REAL(wp)     :: fluid_rho  = 1.0_wp   ! fluid density [kg/m³]
    REAL(wp)     :: fluid_mu   = 1.8e-5_wp ! fluid dynamic viscosity [Pa·s]
    REAL(wp)     :: char_L     = 0.1_wp   ! characteristic length [m]

    !-- [IN] Radiation parameters (for FILM_RADIATION_LINEAR / FILM_COMBINED)
    LOGICAL      :: radiation_active = .FALSE.  ! include radiation term
    REAL(wp)     :: emissivity  = 0.85_wp  ! surface emissivity ε
    REAL(wp)     :: T_ambient_rad = 293.15_wp  ! ambient temperature for radiation [K]
    REAL(wp)     :: view_factor = 1.0_wp   ! view factor (1 = infinite parallel plates)

    !-- [IN] Amplitude function (maps time → amplitude)
    LOGICAL      :: use_amplitude = .FALSE.
    REAL(wp)     :: amp_factor   = 1.0_wp   ! current amplitude value

    !-- [OUT] BC outputs
    REAL(wp)     :: h_film      = 0.0_wp   ! film coefficient [W/(m²·K)]
    REAL(wp)     :: q_convec    = 0.0_wp   ! convective flux [W/m²]
    REAL(wp)     :: q_radiation = 0.0_wp   ! radiative flux [W/m²]
    REAL(wp)     :: q_total     = 0.0_wp   ! total BC flux [W/m²]

    !-- [OUT] Newton linearisation derivatives
    REAL(wp)     :: dhdt        = 0.0_wp   ! d(h·ΔT)/dT = h + (T_sink-T)·dh/dT
    REAL(wp)     :: dqrad_dt    = 0.0_wp   ! d(q_rad)/dT (for radiation linearization)

    !-- [OUT] Error handling
    TYPE(ErrorStatusType) :: status
    LOGICAL  :: success = .FALSE.
  END TYPE PH_Thm_Film_Args

CONTAINS

  !============================================================================
  ! PH_Thm_Film_API — THIN WRAPPER
  !============================================================================
  SUBROUTINE PH_Thm_Film_API(args, state, err_status)
    TYPE(PH_Thm_Film_Args),   INTENT(INOUT) :: args
    TYPE(PH_Thm_Film_State),  INTENT(INOUT) :: state
    TYPE(ErrorStatusType),    INTENT(INOUT) :: err_status

    CALL init_error_status(err_status, IF_STATUS_OK)
    args%success = .FALSE.
    CALL PH_Thm_Film_Impl(args, state)
    err_status = args%status
    IF (.NOT. args%success) CALL init_error_status(err_status, IF_STATUS_ERROR)
  END SUBROUTINE PH_Thm_Film_API

  !============================================================================
  ! PH_Thm_Film_Impl — Physics kernel (PRIVATE, hot path)
  !
  ! §IMPLEMENTATION
  !
  ! §CONVECTION:
  !   q_conv = h · (T_sink - T_surface)
  !   dhdt   = h + (T_sink - T) · dh/dT
  !
  ! §RADIATION LINEARIZATION (Stefan-Boltzmann):
  !   q_rad = ε·σ·F_v·(T_amb⁴ - T⁴)
  !   Linearized: q_rad ≈ h_rad · (T_amb - T)  where h_rad = 4·ε·σ·T³
  !   dqrad_dt = -4·ε·σ·T³ · h_rad ≈ -h_rad  (at each Newton iteration)
  !
  ! §DITTUS-BOELTER (forced convection, Re > 5000):
  !   Nu = 0.023 · Re^0.8 · Pr^0.4
  !   h  = Nu · k / D
  !   Re = ρ·v·D/μ  ;  Pr = μ·Cₚ/k
  !============================================================================
  SUBROUTINE PH_Thm_Film_Impl(args, state)
    TYPE(PH_Thm_Film_Args),  INTENT(INOUT) :: args
    TYPE(PH_Thm_Film_State), INTENT(INOUT) :: state

    REAL(wp) :: h_local       ! locally computed film coefficient
    REAL(wp) :: Re, Pr, Nu   ! Reynolds, Prandtl, Nusselt numbers
    REAL(wp) :: T_ref         ! reference temperature for correlations [K]
    REAL(wp) :: h_rad_linear  ! linearized radiation coefficient [W/(m²·K)]
    REAL(wp) :: dT            ! temperature difference T_sink - T_surface
    REAL(wp) :: T_abs_min    ! guard against T ≈ 0

    !-- Guard: T_sink = T_surface (no driving force → zero flux)
    dT = args%T_sink - args%T_surface
    IF (ABS(dT) < 1.0e-30_wp .AND. .NOT. args%radiation_active) THEN
      args%h_film  = 0.0_wp
      args%q_total = 0.0_wp
      args%dhdt    = 0.0_wp
      state%is_updated = .TRUE.
      args%success  = .TRUE.
      RETURN
    END IF

    !-- §CONVECTION COMPONENT
    SELECT CASE (args%film_type)

    CASE (FILM_CONSTANT)
      ! Constant film coefficient
      h_local = args%h0_const * args%h_scale * args%amp_factor
      args%dhdt = 0.0_wp   ! no temperature dependence

    CASE (FILM_T_DEPENDENT)
      ! h(T_surface) = a + b·T + c·T²  (typical for polymers, radiation shields)
      T_abs_min = MAX(args%T_surface, 1.0_wp)
      h_local = (args%h_T_a + args%h_T_b * T_abs_min &
               + args%h_T_c * T_abs_min**2) * args%h_scale
      args%dhdt = args%h_T_b + 2.0_wp * args%h_T_c * args%T_surface
      ! Full Newton: dhdt = h + (T_sink - T) · dh/dT
      args%dhdt = h_local + dT * args%dhdt

    CASE (FILM_AMB_DEPENDENT)
      ! Free convection: h = a · (|ΔT|/L)^n  (Churchill-Chu correlation)
      ! Simplified: h ∝ |ΔT|^0.33 for laminar natural convection on plates
      T_ref = 0.5_wp * (args%T_sink + args%T_surface)
      IF (ABS(dT) > 1.0_wp) THEN
        h_local = 1.42_wp * ABS(dT)**(0.25_wp) / (args%char_L**0.25_wp)  ! W/(m²·K)
      ELSE
        h_local = 5.0_wp   ! fallback: natural air convection floor
      END IF
      h_local = h_local * args%h_scale
      args%dhdt = 0.33_wp * h_local / MAX(ABS(dT), 1.0_wp)  ! approximate

    CASE (FILM_V_DEPENDENT)
      ! Forced convection: Dittus-Boelter correlation
      ! Nu = 0.023 · Re^0.8 · Pr^0.4  (heating: h = 0.023·Re^0.8·Pr^0.4·k/D)
      Re = args%fluid_rho * args%fluid_v * args%char_L &
           / MAX(args%fluid_mu, 1.0e-30_wp)
      Pr = args%fluid_mu * args%fluid_cp &
           / MAX(args%fluid_k, 1.0e-30_wp)
      IF (Re > 5000.0_wp) THEN
        Nu = 0.023_wp * Re**0.8_wp * Pr**0.4_wp
      ELSE
        Nu = 0.664_wp * REAL(INT(Re**0.5_wp * Pr**(1.0_wp/3.0_wp)), wp)  ! lamin.
      END IF
      h_local = Nu * args%fluid_k / MAX(args%char_L, 1.0e-30_wp)
      h_local = h_local * args%h_scale
      ! dhdt: h depends on fluid properties at film temperature
      args%dhdt = 0.0_wp   ! constant at given v; for T-dependent properties use props(T)

    CASE (FILM_RADIATION_LINEAR, FILM_COMBINED)
      ! Handled in radiation section below; use constant as placeholder here
      h_local = args%h0_const * args%h_scale
      args%dhdt = 0.0_wp

    CASE DEFAULT
      h_local = args%h0_const
      args%dhdt = 0.0_wp
    END SELECT

    !-- §CONVECTIVE FLUX
    args%h_film = h_local
    args%q_convec = h_local * dT

    !-- §RADIATION COMPONENT
    IF (args%radiation_active) THEN
      ! Stefan-Boltzmann with view factor:
      !   q_rad = ε · σ · F_v · (T_amb^4 - T^4)
      ! Linearized around T_surface:
      !   h_rad = 4 · ε · σ · F_v · T_surface^3
      !   q_rad ≈ h_rad · (T_amb - T_surface)
      T_abs_min = MAX(args%T_surface, 1.0_wp)
      h_rad_linear = 4.0_wp * args%emissivity * STEFAN_BOLTZMANN &
                   * args%view_factor * T_abs_min**3
      args%T_sink = args%T_ambient_rad   ! radiation uses T_ambient as sink
      args%q_radiation = h_rad_linear * (args%T_ambient_rad - args%T_surface)
      args%dqrad_dt = -h_rad_linear      ! d(q_rad)/dT (negative for cooling)
      ! Add radiation to convective dhdt
      args%dhdt = args%dhdt + args%dqrad_dt
    ELSE
      args%q_radiation = 0.0_wp
      args%dqrad_dt = 0.0_wp
    END IF

    !-- §TOTAL BC FLUX
    args%q_total = args%q_convec + args%q_radiation

    !-- §NEWTON LINEARISATION
    !   DFDT = d(q_conv + q_rad)/dT
    !        = h + (T_sink - T)·dh/dT + dqrad/dT
    args%dhdt = args%h_film + dT * MAX(args%dhdt, 0.0_wp) + args%dqrad_dt

    !-- §STATE UPDATE
    state%h_prev = args%h_film
    state%T_surface_prev = args%T_surface
    state%Q_total = state%Q_total + args%q_total * args%dtime
    state%is_updated = .TRUE.

    args%success = .TRUE.
    CALL init_error_status(args%status, IF_STATUS_OK)

  END SUBROUTINE PH_Thm_Film_Impl

  !============================================================================
  ! PH_Thm_Film_Init — Initialiser
  !============================================================================
  SUBROUTINE PH_Thm_Film_Init(state, err_status)
    TYPE(PH_Thm_Film_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),   INTENT(INOUT) :: err_status

    state%h_prev = 0.0_wp
    state%Q_total = 0.0_wp
    state%T_surface_prev = 0.0_wp
    state%is_updated = .FALSE.
    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE PH_Thm_Film_Init

END MODULE PH_Thm_Film
