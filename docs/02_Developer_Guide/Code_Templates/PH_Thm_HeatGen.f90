!===============================================================================
! Template: PH_Thm_HeatGen.f90                                  [Template v1.0]
! Layer:  L4_PH — Physics Layer
! Domain: Thermal / HeatGen (HETVAL — Volumetric Heat Generation)
! Abaqus: HETVAL (coupled temp-disp / fully coupled thermal analysis)
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.0 (2026-04)  Initial: Taylor-Quinney + user-defined heat source models
!
! PURPOSE:
!   UFC-native volumetric heat generation rate (Q [W/m³]) interface.
!   Called once per material point per increment in coupled thermal analyses.
!   This is the STR → THM coupling gateway (Taylor-Quinney plastic heating).
!
! KEY DIFFERENCE vs BC subroutines:
!   HETVAL is a VOLUMETRIC source (not a surface BC).
!   It receives σ and ε̇_p from STR and returns Q to THM.
!   The coupling data path:
!     L4_PH/Plastic (UMAT) → σ:ε̇_p → PH_Thm_HeatGen → Q [W/m³] → THM energy eqn
!
! PHYSICS:
!   Taylor-Quinney model:    Q = χ · σ : ε̇_p
!   Constant user source:    Q = Q0 · f(time, T, coords)
!   Phase-change latent:     Q = ρ·L·(dα/dt)  [HETVAL for latent heat]
!   Joule heating:           Q = J²/σ_elec  [EM→THM coupling, separate module]
!
! SIO COMPLIANCE (Principle #14):
!   SIO-01  ✓  Single PH_Thm_Hetval_Args bundle
!   SIO-02  ✓  _Impl 6th param is PH_Thm_Hetval_Args
!   SIO-03  ✓  Args carry structured ErrorStatusType status; check %status_code
!   SIO-07  ✓  No INTENT(...) in TYPE bodies
!   SIO-13  ✓  _Args has no _Desc/_State/_Algo members
!   SIO-14  ✓  _Args has no ALLOCATABLE members
!
! HOW TO USE:
!   1. Copy to L4_PH/Material/Thermal/
!   2. Rename module: PH_Thm_HeatGen
!   3. Select model in §IMPLEMENTATION (Constant / Taylor-Quinney / UserDef)
!   4. For STR→THM coupling: call PH_Thm_HeatGen_API from UMAT after σ update
!
! ABAQUS HETVAL ARGUMENTS (reference):
!   SUBROUTINE HETVAL(CMLELE, RPL, DRPLDT, TIME, DTIME, TEMP, DTEMP,
!                     STATEV, NDI, NSHR, NTENS, NSTATV, PROPS, NPROPS,
!                     COORDS, JLTYP, SPOS, SNEG)
!     RPL     [OUT]  — volumetric heat generation rate [J/(m³·s)] = [W/m³]
!     DRPLDT  [OUT]  — d(RPL)/dT  (thermal Jacobian for Newton)
!     DTEMP   [IN]   — temperature increment
!     STATEV  [IN/IO] — solution-dependent state variables
!     PROPS   [IN]   — material constants (χ, Q0, activation energies, etc.)
!===============================================================================
MODULE PH_Thm_HeatGen
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_WARN
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Thm_Hetval_State  ! L4_PH state (export for unit tests)
  PUBLIC :: PH_Thm_Hetval_Args   ! Unified IN/OUT call bundle (Principle #14)
  PUBLIC :: PH_Thm_Hetval_API    ! UFC-native entry (thin wrapper → _Impl)
  ! PH_Thm_Hetval_Impl is PRIVATE: physics lives here only.

  !-----------------------------------------------------------------------------
  ! Heat generation model constants (use in CASE statements)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: HETVAL_CONSTANT   = 1_i4  ! Q = Q0·f(t)
  INTEGER(i4), PARAMETER, PUBLIC :: HETVAL_TAYLOR_Q   = 2_i4  ! Q = χ·σ:ε̇_p
  INTEGER(i4), PARAMETER, PUBLIC :: HETVAL_USERDEF    = 3_i4  ! full user model
  INTEGER(i4), PARAMETER, PUBLIC :: HETVAL_LATENT     = 4_i4  ! phase-change latent heat

  !============================================================================
  ! STATE type: L4_PH-owned internal state for heat generation.
  !   HETVAL is stateless in pure ABAQUS (RPL computed directly from inputs).
  !   UFC adds state for history-dependent models (e.g. latent heat evolution).
  !============================================================================
  TYPE, PUBLIC :: PH_Thm_Hetval_State
    !-- Accumulated plastic heat energy density [J/m³] (for output diagnostics)
    REAL(wp) :: Q_accumulated = 0.0_wp
    !-- Previous step plastic strain rate magnitude (for rate-dependent models)
    REAL(wp) :: ep_dot_prev = 0.0_wp
    !-- Phase fraction α for latent heat model (0 ≤ α ≤ 1)
    REAL(wp) :: phase_fraction = 0.0_wp
    !-- Cumulative equivalent plastic strain (for history-dependent χ)
    REAL(wp) :: eps_eq_plas_cum = 0.0_wp
    !-- Convergence flag (mirrors UMAT convention)
    LOGICAL  :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Thm_Hetval_State

  !============================================================================
  ! ARGS type: Unified IN/OUT bundle (Principle #14 SIO)
  !   Single bundle replaces the flat ABAQUS HETVAL parameter list.
  !
  ! Field classification:
  !   [IN]  — read-only inputs (not modified by this routine)
  !   [INOUT] — modified by this routine
  !   [OUT] — computed outputs
  !============================================================================
  TYPE, PUBLIC :: PH_Thm_Hetval_Args
    !-- [IN] Time bookkeeping
    REAL(wp)    :: time_curr    = 0.0_wp   ! current step time
    REAL(wp)    :: time_total   = 0.0_wp   ! total analysis time
    REAL(wp)    :: dtime        = 0.0_wp   ! time increment Δt [s]

    !-- [IN] Temperature state
    REAL(wp)    :: temp_curr    = 0.0_wp   ! temperature at end of increment [K]
    REAL(wp)    :: dtemp        = 0.0_wp   ! temperature increment ΔT [K]

    !-- [IN] Mechanical coupling inputs (from STR / UMAT)
    !   These fields are populated when called from UMAT after σ update.
    REAL(wp)    :: stress(6)    = 0.0_wp   ! Cauchy stress σ [Pa] (NDI+NSHR components)
    REAL(wp)    :: plas_strain_rate(6) = 0.0_wp  ! plastic strain rate ε̇_p [1/s]
    REAL(wp)    :: eq_plas_rate = 0.0_wp   ! equivalent plastic strain rate [1/s]
    REAL(wp)    :: eq_plas_incr = 0.0_wp   ! equivalent plastic strain increment Δεₑᵖ

    !-- [IN] Integration point data
    REAL(wp)    :: coords(3)    = 0.0_wp   ! IP coordinates [m]
    INTEGER(i4)  :: nstatv      = 0_i4     ! number of SDVs
    REAL(wp)    :: statev_start(100) = 0.0_wp  ! SDV at start [nstatv] — shortcut; use pointer in production

    !-- [IN] Material constants (PROPS array, NPROPS long)
    INTEGER(i4)  :: nprops      = 0_i4
    INTEGER(i4)  :: hetype      = HETVAL_CONSTANT  ! heat generation model ID
    REAL(wp)     :: chi_tq      = 0.9_wp   ! Taylor-Quinney coefficient (default 0.9)
    REAL(wp)     :: Q0_const    = 0.0_wp   ! constant heat source [W/m³]
    REAL(wp)     :: act_energy  = 0.0_wp   ! activation energy for Arrhenius [J/mol]
    REAL(wp)     :: latent_heat = 0.0_wp   ! latent heat of phase change [J/kg]
    REAL(wp)     :: ref_rate    = 1.0e-3_wp ! reference strain rate for user model [1/s]

    !-- [IN] Control flags
    LOGICAL      :: use_taylor_quinney = .TRUE.   ! enable STR→THM coupling
    LOGICAL      :: use_joule = .FALSE.            ! EM→THM (separate coupling)
    LOGICAL      :: couple_from_plastic = .FALSE.  ! called from UMAT after plastic step

    !-- [OUT] Heat generation outputs
    REAL(wp)     :: RPL         = 0.0_wp   ! volumetric heat rate [W/m³] = [J/(m³·s)]
    REAL(wp)     :: DRPLDT      = 0.0_wp   ! d(RPL)/dT thermal Jacobian
    REAL(wp)     :: DRPLDEPS    = 0.0_wp   ! d(RPL)/dεₑᵖ  (optional, for coupled NR)

    !-- [OUT] Diagnostics (non-ABAQUS, UFC extension)
    REAL(wp)     :: plastic_dissipation = 0.0_wp  ! σ:ε̇_p [W/m³]
    REAL(wp)     :: chi_effective = 0.0_wp       ! effective Taylor-Quinney ratio used

    !-- [OUT] Error handling
    TYPE(ErrorStatusType) :: status
    LOGICAL  :: success = .FALSE.
  END TYPE PH_Thm_Hetval_Args

CONTAINS

  !============================================================================
  ! PH_Thm_Hetval_API — UFC-native entry (THIN WRAPPER)
  !   All logic lives in _Impl. This wrapper only:
  !     1. Initialises status
  !     2. Calls _Impl
  !     3. Propagates error code
  !============================================================================
  SUBROUTINE PH_Thm_Hetval_API(args, state, err_status)
    TYPE(PH_Thm_Hetval_Args),   INTENT(INOUT) :: args
    TYPE(PH_Thm_Hetval_State),  INTENT(INOUT) :: state
    TYPE(ErrorStatusType),       INTENT(INOUT) :: err_status

    !-- Initialise
    CALL init_error_status(err_status, IF_STATUS_OK)
    args%success = .FALSE.

    !-- Delegate to physics implementation
    CALL PH_Thm_Hetval_Impl(args, state)

    !-- Propagate
    err_status = args%status
    IF (.NOT. args%success) THEN
      CALL init_error_status(err_status, IF_STATUS_ERROR)
    END IF

  END SUBROUTINE PH_Thm_Hetval_API

  !============================================================================
  ! PH_Thm_Hetval_Impl — Physics kernel (PRIVATE, hot path)
  !
  ! §IMPLEMENTATION — select model by hetype flag:
  !
  !   CASE (HETVAL_CONSTANT)    → Q = Q0 · ramp_factor(t)
  !   CASE (HETVAL_TAYLOR_Q)     → Q = χ · σ : ε̇_p
  !   CASE (HETVAL_USERDEF)      → Q = f(σ, ε̇_p, T, coords, statev)
  !   CASE (HETVAL_LATENT)      → Q = ρ·L·dα/dt  (phase change)
  !
  ! §TAYLOR-QUINNEY DERIVATION:
  !   W_p = σ : ε̇_p  (plastic dissipation rate per unit volume [W/m³])
  !   Q   = χ · W_p  (χ = Taylor-Quinney coefficient, 0 ≤ χ ≤ 1)
  !   DRPLDT = χ · d(σ:ε̇_p)/dT
  !           = χ · (∂σ/∂T : ε̇_p)  (stress temperature sensitivity)
  !
  ! §COUPLING INTERFACE:
  !   When couple_from_plastic = .TRUE.:
  !     → stress(6) + plas_strain_rate(6) are already set by UMAT caller
  !     → This routine computes RPL and writes it back for THM energy assembly
  !============================================================================
  SUBROUTINE PH_Thm_Hetval_Impl(args, state)
    TYPE(PH_Thm_Hetval_Args),  INTENT(INOUT) :: args
    TYPE(PH_Thm_Hetval_State), INTENT(INOUT) :: state

    REAL(wp) :: W_plastic      ! plastic dissipation rate [W/m³]
    REAL(wp) :: ramp_factor    ! time/amplitude scaling
    REAL(wp) :: deviator_stress(6)
    REAL(wp) :: sigma_vm       ! von Mises stress
    REAL(wp) :: eps_eq_dot     ! equivalent plastic strain rate
    REAL(wp) :: dalpha_dt      ! phase change rate [1/s]

    !-- Guard: zero time step (avoid divide by zero)
    IF (args%dtime <= 0.0_wp) THEN
      args%RPL    = 0.0_wp
      args%DRPLDT = 0.0_wp
      state%is_updated = .TRUE.
      RETURN
    END IF

    !-- §MODEL SELECTION
    SELECT CASE (args%hetype)

    !------------------------------------------------------------------------
    CASE (HETVAL_CONSTANT)
    !   Constant volumetric heat generation rate.
    !   RPL = Q0 · ramp_factor
    !------------------------------------------------------------------------
      ramp_factor = 1.0_wp   ! TODO: replace with amplitude function
      args%RPL = args%Q0_const * ramp_factor
      args%DRPLDT = 0.0_wp              ! constant → no T dependency
      args%DRPLDEPS = 0.0_wp
      args%plastic_dissipation = 0.0_wp
      args%chi_effective = 0.0_wp

    !------------------------------------------------------------------------
    CASE (HETVAL_TAYLOR_Q)
    !   Taylor-Quinney: plastic dissipation → heat conversion.
    !   Q = χ · σ : ε̇_p
    !   This is the STR→THM primary coupling channel.
    !------------------------------------------------------------------------
      ! Compute plastic dissipation: W_p = σ_dev : ε̇_p_dev + K·ε̇_p_vol
      !   For associative plasticity (J2): W_p ≈ σ_vm · ε̇_eq
      !   Full formula: W_p = σ₁·ε̇₁ + σ₂·ε̇₂ + ... (contracted)
      W_plastic = DOT_PRODUCT(args%stress(1:6), args%plas_strain_rate(1:6))

      ! Apply Taylor-Quinney: Q = χ · W_p
      !   χ may depend on temperature, strain rate, cumulative plastic strain
      args%chi_effective = args%chi_tq   ! TODO: χ(T, ε̄ₑᵖ) lookup table
      args%RPL = args%chi_effective * MAX(W_plastic, 0.0_wp)
      args%plastic_dissipation = W_plastic

      ! Thermal Jacobian: DRPLDT = χ · ∂W_p/∂T
      !   Approximation: DRPLDT ≈ χ · (∂σ/∂T) · ε̇_p
      !   For rate-independent plasticity: ∂σ/∂T ≈ -E·α  (thermal softening)
      !   Conservative: DRPLDT = 0.0  (purely mechanical heating)
      args%DRPLDT = 0.0_wp   ! TODO: add E×α×ε̇_eq if temperature coupling needed

      ! Strain rate Jacobian for coupled THM-STR Newton: DRPLDEPS = χ · σ_eq
      IF (args%eq_plas_rate > 1.0e-30_wp) THEN
        sigma_vm = ABS(W_plastic) / MAX(args%eq_plas_rate, 1.0e-30_wp)
        args%DRPLDEPS = args%chi_effective * sigma_vm
      ELSE
        args%DRPLDEps = 0.0_wp
      END IF

    !------------------------------------------------------------------------
    CASE (HETVAL_USERDEF)
    !   Full user-defined model. Replace placeholder with model equation.
    !   Example: Johnson-Cook heat: Q = χ₀·(1+T*)/(1+m*)·ε̇_eq^α
    !------------------------------------------------------------------------
      ! TODO: implement user model
      args%RPL = 0.0_wp
      args%DRPLDT = 0.0_wp
      args%DRPLDEps = 0.0_wp

    !------------------------------------------------------------------------
    CASE (HETVAL_LATENT)
    !   Phase-change latent heat: Q = ρ · L · dα/dt
    !   α = phase fraction (0 = liquid, 1 = solid)
    !------------------------------------------------------------------------
      ! Compute phase change rate from statev or from temperature
      dalpha_dt = 0.0_wp  ! TODO: derive from phase field model or statev
      args%RPL = args%latent_heat * ABS(dalpha_dt)   ! always positive (exothermic)
      args%DRPLDT = 0.0_wp   ! TODO: latent heat temperature dependence

    CASE DEFAULT
      args%RPL    = 0.0_wp
      args%DRPLDT = 0.0_wp
    END SELECT

    !-- §DIAGNOSTICS: accumulate total plastic heat
    state%Q_accumulated = state%Q_accumulated + args%RPL * args%dtime

    !-- §STATE UPDATE (history-dependent models)
    state%ep_dot_prev = args%eq_plas_rate
    state%eps_eq_plas_cum = state%eps_eq_plas_cum + args%eq_plas_incr

    state%is_updated = .TRUE.
    args%success = .TRUE.
    CALL init_error_status(args%status, IF_STATUS_OK)

  END SUBROUTINE PH_Thm_Hetval_Impl

  !============================================================================
  ! PH_Thm_Hetval_Init — Optional initialiser for state
  !   Called once per material point at start of analysis.
  !============================================================================
  SUBROUTINE PH_Thm_Hetval_Init(state, temp_init, err_status)
    TYPE(PH_Thm_Hetval_State), INTENT(INOUT) :: state
    REAL(wp),                  INTENT(IN)    :: temp_init
    TYPE(ErrorStatusType),     INTENT(INOUT) :: err_status

    state%Q_accumulated = 0.0_wp
    state%ep_dot_prev = 0.0_wp
    state%phase_fraction = 0.0_wp
    state%eps_eq_plas_cum = 0.0_wp
    state%is_updated = .FALSE.
    CALL init_error_status(err_status, IF_STATUS_OK)
  END SUBROUTINE PH_Thm_Hetval_Init

END MODULE PH_Thm_HeatGen
