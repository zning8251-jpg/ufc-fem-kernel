!===============================================================================
! MODULE: PH_Mat_Damage_Lemaitre_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Lemaitre CDM coupled with J2 plasticity — scalar isotropic damage —
!         **W1**：**PH_CDM_Props** 由 **`desc%props`** 填充；与 **J2** 链及 **PH_MAT_***
!         损伤族路由、**Effective_Model** 一致。
!===============================================================================
!
! Design Document: DESIGN_Mat_ConstitutiveKernels.md §5
! Reference: Lemaitre (1985) A continuous damage mechanics model for ductile fracture
!            Simo & Hughes (1998) Computational Inelasticity
!
! Core Concept — Effective Stress Hypothesis (§5.1):
!   σ̃ = σ / (1-D)   (effective stress in undamaged material)
!   D ∈ [0, 1]:  D=0 intact, D=D_c material failure
!
! Damage Evolution Law (§5.2):
!   Y = σ_eq² · Rv / (2E(1-D)²)   (damage energy release rate)
!   Rv = (2/3)(1+ν) + 3(1-2ν)(σ_H/σ_eq)²   (triaxiality function)
!   Ḋ = (Y/S)^s · ε̄̇_p   when ε̄_p > ε_D (damage threshold)
!
! Coupled Algorithm — 6-Step Update (§5.3):
!   Step 1: Elastic trial in effective stress space
!   Step 2: Yield check (effective stress space)
!   Step 3: Radial return (effective stress space, reuses J2 kernel)
!   Step 4: Damage evolution (Y, Rv, ΔD)
!   Step 5: Nominal stress recovery: σ = (1-D)·σ̃
!   Step 6: Damaged consistent tangent: D_ep^dmg ≈ (1-D)·D_ep
!
! Coupling with J2 Module (§5.5):
!   This module USE-s PH_Mat_Plast_J2_Iso_Core for:
!     - PH_J2_Hardening (yield stress evaluation)
!     - PH_J2_ComputeHardeningTangent (hardening slope)
!   The radial return in effective stress space follows identical logic.
!
! State Variable Layout (§6.3):
!   statev(1)   = ε̄_p (equivalent plastic strain)
!   statev(2:7) = ε_p(6) (plastic strain, Voigt)
!   statev(8)   = D (damage variable)
!   nstatv = 8
!
! CONTRACT Compliance:
!   - ErrorStatusType on all public procedures (no STOP)
!   - wp/i4 precision from IF_Prec_Core
!   - Intent declarations on all arguments
!   - D_crit check for element deletion signaling
!
! Status: SKELETON | Created: 2026-04-28
!===============================================================================
MODULE PH_Mat_Damage_Lemaitre_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR
  USE PH_Mat_Plast_J2_Iso_Core, ONLY: PH_J2_Props, PH_J2_Hardening, &
                                     PH_J2_ComputeHardeningTangent
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public Interface
  !-----------------------------------------------------------------------------
  PUBLIC :: PH_CDM_Init              ! Initialize Lemaitre CDM context
  PUBLIC :: PH_CDM_EffectiveStress   ! σ̃ = σ/(1-D)
  PUBLIC :: PH_CDM_EnergyRelease     ! Y = σ_eq²·Rv / (2E(1-D)²)
  PUBLIC :: PH_CDM_Triaxiality       ! Rv triaxiality function
  PUBLIC :: PH_CDM_DamageEvolution   ! Ḋ = (Y/S)^s · Δε̄_p
  PUBLIC :: PH_CDM_CoupledUpdate     ! Full 6-step coupled elasto-plastic-damage
  PUBLIC :: PH_CDM_DamagedTangent    ! Damaged consistent tangent
  PUBLIC :: PH_CDM_ComputeStress     ! Unified entry point
  !-- Standard 4-routine interface (§B2 dispatch contract)
  PUBLIC :: PH_Mat_CDM_Compute_Stress
  PUBLIC :: PH_Mat_CDM_Compute_Tangent
  PUBLIC :: PH_Mat_CDM_Update_State
  PUBLIC :: PH_Mat_CDM_Validate_Params

  !-----------------------------------------------------------------------------
  ! Algorithm Control Constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: PH_MAT_LEMAITRE_MAX_LOCAL_ITER  = 25_i4     ! Max Newton iterations
  REAL(wp),    PARAMETER :: TOL_NRLOC      = 1.0E-10_wp ! Newton tolerance
  REAL(wp),    PARAMETER :: PNEWDT_MIN     = 0.25_wp    ! Min time step fraction
  REAL(wp),    PARAMETER :: D_SAFE_MIN     = 1.0E-12_wp ! Min (1-D) denominator

  !-----------------------------------------------------------------------------
  ! TYPE: PH_CDM_Props — Material and damage properties
  !   Written: Populate phase (cold path, once)
  !   Read by: Kernel (hot path, read-only)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_CDM_Props
    !-- Damage parameters (§5.2)
    REAL(wp) :: S_dmg       = 0.0_wp   ! Damage strength parameter S [Pa]
    REAL(wp) :: s_exp       = 1.0_wp   ! Damage exponent s [-]
    REAL(wp) :: eps_D       = 0.0_wp   ! Damage threshold strain [-]
    REAL(wp) :: D_crit      = 0.5_wp   ! Critical damage value D_c [-]
    !-- Elastic parameters (shared with J2)
    REAL(wp) :: E           = 0.0_wp   ! Young's modulus [Pa]
    REAL(wp) :: nu          = 0.0_wp   ! Poisson's ratio [-]
    !-- Plasticity parameters (delegated to J2 kernel)
    REAL(wp) :: sigma_y0    = 0.0_wp   ! Initial yield stress [Pa]
    REAL(wp) :: H           = 0.0_wp   ! Linear hardening modulus [Pa]
    REAL(wp) :: K_swift     = 0.0_wp   ! Swift K parameter [Pa]
    REAL(wp) :: n_swift     = 0.0_wp   ! Swift exponent [-]
    REAL(wp) :: eps0_swift  = 0.0_wp   ! Swift reference strain [-]
    REAL(wp) :: sigma_inf   = 0.0_wp   ! Voce saturation stress [Pa]
    REAL(wp) :: delta_voce  = 0.0_wp   ! Voce decay rate [-]
    INTEGER(i4) :: hardening_type = 1_i4  ! 1=Linear, 2=Swift, 3=Voce
  END TYPE PH_CDM_Props

  !-----------------------------------------------------------------------------
  ! TYPE: PH_CDM_State — Integration point state
  !   Layout: statev(1)=ε̄_p, statev(2:7)=ε_p(6), statev(8)=D
  !   nstatv = 8
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_CDM_State
    REAL(wp) :: D           = 0.0_wp   ! Damage variable [0,1]
    REAL(wp) :: Y           = 0.0_wp   ! Damage energy release rate [Pa]
    REAL(wp) :: eps_p_eq    = 0.0_wp   ! Equivalent plastic strain [-]
    REAL(wp) :: strain_p(6) = 0.0_wp   ! Plastic strain (Voigt) [-]
    REAL(wp) :: stress(6)   = 0.0_wp   ! Nominal (Cauchy) stress (Voigt) [Pa]
    REAL(wp) :: eff_stress(6) = 0.0_wp ! Effective stress σ̃ (Voigt) [Pa]
    REAL(wp) :: D_ep(6,6)   = 0.0_wp   ! Damaged consistent tangent [Pa]
    LOGICAL  :: damaged     = .FALSE.  ! Damage activated (ε̄_p > ε_D)
    LOGICAL  :: failed      = .FALSE.  ! Material failed (D >= D_crit)
  END TYPE PH_CDM_State

CONTAINS

  !===========================================================================
  ! PH_CDM_ComputeStress — Unified entry point for coupled damage update
  !
  ! Design Doc: §5.3, §5.4
  ! Delegates to PH_CDM_CoupledUpdate for the full 6-step algorithm.
  !===========================================================================
  SUBROUTINE PH_CDM_ComputeStress(props, strain_inc, state, tangent, pnewdt, ierr)
    TYPE(PH_CDM_Props),     INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: strain_inc(6)  ! Δε (Voigt)
    TYPE(PH_CDM_State),     INTENT(INOUT) :: state
    REAL(wp),               INTENT(OUT)   :: tangent(6,6)   ! D_ep^dmg
    REAL(wp),               INTENT(INOUT) :: pnewdt         ! Time step suggestion
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL init_error_status(ierr)

    ! Check if material already failed
    IF (state%failed) THEN
      ! Material fully damaged — return zero stress, zero stiffness
      state%stress = 0.0_wp
      tangent      = 0.0_wp
      ierr%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Full coupled update
    CALL PH_CDM_CoupledUpdate(props, strain_inc, state, tangent, pnewdt, ierr)

  END SUBROUTINE PH_CDM_ComputeStress

  !===========================================================================
  ! PH_CDM_Init — Initialize Lemaitre CDM context
  !
  ! Design Doc: §5
  ! Validates damage parameters and zero-initializes state.
  !===========================================================================
  SUBROUTINE PH_CDM_Init(props, state, ierr)
    TYPE(PH_CDM_Props),     INTENT(IN)    :: props
    TYPE(PH_CDM_State),     INTENT(OUT)   :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL init_error_status(ierr)

    ! Validate damage parameters
    IF (props%S_dmg <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_CDM_Init]: S_dmg must be positive'
      RETURN
    END IF
    IF (props%D_crit <= 0.0_wp .OR. props%D_crit > 1.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_CDM_Init]: D_crit must be in (0, 1]'
      RETURN
    END IF
    IF (props%E <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_CDM_Init]: E must be positive'
      RETURN
    END IF

    ! Zero-initialize state
    state%D         = 0.0_wp
    state%Y         = 0.0_wp
    state%eps_p_eq  = 0.0_wp
    state%strain_p  = 0.0_wp
    state%stress    = 0.0_wp
    state%eff_stress = 0.0_wp
    state%D_ep      = 0.0_wp
    state%damaged   = .FALSE.
    state%failed    = .FALSE.

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_CDM_Init

  !===========================================================================
  ! PH_CDM_CoupledUpdate — Full 6-step coupled elasto-plastic-damage algorithm
  !
  ! Design Doc: §5.3
  ! Step 1: Elastic trial in effective stress space
  ! Step 2: Yield check (effective stress space)
  ! Step 3: Radial return (effective stress space)
  ! Step 4: Damage evolution (Y, Rv, ΔD)
  ! Step 5: Nominal stress recovery σ = (1-D_new)·σ̃
  ! Step 6: Damaged tangent D_ep^dmg ≈ (1-D_new)·D_ep
  !===========================================================================
  SUBROUTINE PH_CDM_CoupledUpdate(props, strain_inc, state, tangent, pnewdt, ierr)
    TYPE(PH_CDM_Props),     INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: strain_inc(6)
    TYPE(PH_CDM_State),     INTENT(INOUT) :: state
    REAL(wp),               INTENT(OUT)   :: tangent(6,6)
    REAL(wp),               INTENT(INOUT) :: pnewdt
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    ! Local variables
    REAL(wp) :: D_el(6,6)            ! Elastic stiffness
    REAL(wp) :: sigma_eff_trial(6)   ! Trial effective stress
    REAL(wp) :: s_eff_trial(6)       ! Trial effective deviatoric
    REAL(wp) :: q_eff_trial          ! Trial effective Von Mises
    REAL(wp) :: p_mean               ! Mean pressure (effective)
    REAL(wp) :: sigma_y              ! Current yield stress
    REAL(wp) :: H_tan                ! Hardening tangent
    REAL(wp) :: f_trial              ! Trial yield function
    REAL(wp) :: dg                   ! Plastic multiplier Δγ
    REAL(wp) :: G                    ! Shear modulus
    REAL(wp) :: beta                 ! Radial return factor
    REAL(wp) :: n_dir(6)             ! Flow direction
    REAL(wp) :: D_old, D_new         ! Damage old/new
    REAL(wp) :: Y_dam                ! Damage energy release rate
    REAL(wp) :: Rv                   ! Triaxiality function
    REAL(wp) :: sigma_eff_new(6)     ! Updated effective stress
    REAL(wp) :: q_eff_new            ! Updated effective Von Mises
    REAL(wp) :: one_minus_D          ! (1 - D_old) with safety floor
    REAL(wp) :: lambda, mu           ! Lamé parameters
    REAL(wp) :: R_nrloc, dR_ddg      ! Newton residual/Jacobian
    REAL(wp) :: peeq_trial           ! Trial equiv. plastic strain
    TYPE(PH_J2_Props) :: j2_props    ! J2 props for hardening delegation
    INTEGER(i4) :: i, j, iter

    CALL init_error_status(ierr)

    D_old = state%D
    one_minus_D = MAX(1.0_wp - D_old, D_SAFE_MIN)

    ! Build J2 props for hardening delegation (§5.5)
    j2_props%elastic%E             = props%E
    j2_props%elastic%nu            = props%nu
    j2_props%yield%sigma_y0      = props%sigma_y0
    j2_props%harden%H             = props%H
    j2_props%harden%K_swift       = props%K_swift
    j2_props%harden%n_swift       = props%n_swift
    j2_props%harden%eps0_swift    = props%eps0_swift
    j2_props%harden%sigma_inf     = props%sigma_inf
    j2_props%harden%delta_voce    = props%delta_voce
    j2_props%ctrl%hardening_type = props%hardening_type

    ! ---- Step 1: Elastic trial in effective stress space (§5.3 Step 1) ----
    ! σ̃_trial = σ̃_n + D_e : Δε
    ! where σ̃_n = σ_n / (1-D_n)
    G      = props%E / (2.0_wp * (1.0_wp + props%nu))
    mu     = G
    lambda = props%E * props%nu / ((1.0_wp + props%nu) * (1.0_wp - 2.0_wp * props%nu))

    ! Build elastic stiffness D_el
    D_el = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        D_el(i,j) = lambda
      END DO
      D_el(i,i) = lambda + 2.0_wp * mu
    END DO
    D_el(4,4) = mu
    D_el(5,5) = mu
    D_el(6,6) = mu

    ! Effective stress at t_n: σ̃_n = σ_n / (1-D_n)
    ! Trial effective stress: σ̃_trial = σ̃_n + D_el : Δε
    sigma_eff_trial = state%stress / one_minus_D + MATMUL(D_el, strain_inc)

    ! Deviatoric decomposition of trial effective stress
    p_mean = (sigma_eff_trial(1) + sigma_eff_trial(2) + sigma_eff_trial(3)) / 3.0_wp
    s_eff_trial = sigma_eff_trial
    s_eff_trial(1) = s_eff_trial(1) - p_mean
    s_eff_trial(2) = s_eff_trial(2) - p_mean
    s_eff_trial(3) = s_eff_trial(3) - p_mean

    ! Von Mises equivalent (effective): q̃ = sqrt(3/2) · ||s̃||
    q_eff_trial = SQRT(1.5_wp) * SQRT( &
        s_eff_trial(1)**2 + s_eff_trial(2)**2 + s_eff_trial(3)**2 &
      + 2.0_wp * (s_eff_trial(4)**2 + s_eff_trial(5)**2 + s_eff_trial(6)**2) )

    ! ---- Step 2: Yield check in effective stress space (§5.3 Step 2) ----
    ! f̃ = q̃_trial - σ_y(ε̄_p_n)
    CALL PH_J2_Hardening(j2_props, state%eps_p_eq, sigma_y)
    f_trial = q_eff_trial - sigma_y

    IF (f_trial <= 0.0_wp) THEN
      ! Elastic step — no plasticity, no damage evolution
      ! Nominal stress: σ = (1-D) · σ̃
      state%eff_stress = sigma_eff_trial
      state%stress     = one_minus_D * sigma_eff_trial
      tangent          = one_minus_D * D_el
      state%D_ep       = tangent
      ierr%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! ---- Step 3: Radial return in effective stress space (§5.3 Step 3) ----
    ! Same algorithm as J2 but operating on σ̃
    ! Initial guess: Δγ^(0) = f̃ / (3G + H')
    CALL PH_J2_ComputeHardeningTangent(j2_props, state%eps_p_eq, H_tan)
    dg = f_trial / (3.0_wp * G + H_tan)

    ! Local Newton iteration for nonlinear hardening
    ! R(Δγ) = q̃_trial - 3G·Δγ - σ_y(ε̄_p_n + Δγ) = 0
    DO iter = 1, PH_MAT_LEMAITRE_MAX_LOCAL_ITER
      peeq_trial = state%eps_p_eq + dg
      CALL PH_J2_Hardening(j2_props, peeq_trial, sigma_y)
      CALL PH_J2_ComputeHardeningTangent(j2_props, peeq_trial, H_tan)

      R_nrloc = q_eff_trial - 3.0_wp * G * dg - sigma_y
      IF (ABS(R_nrloc) < TOL_NRLOC * props%sigma_y0) EXIT

      dR_ddg = -(3.0_wp * G + H_tan)
      IF (ABS(dR_ddg) < 1.0E-30_wp) THEN
        ierr%status_code = IF_STATUS_ERROR
        ierr%message = '[PH_CDM_CoupledUpdate]: Zero Jacobian in Newton'
        RETURN
      END IF
      dg = dg - R_nrloc / dR_ddg
      IF (dg < 0.0_wp) dg = 0.0_wp
    END DO

    IF (iter > PH_MAT_LEMAITRE_MAX_LOCAL_ITER) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_CDM_CoupledUpdate]: Local Newton did not converge'
      pnewdt = PNEWDT_MIN
      RETURN
    END IF

    ! Flow direction and radial return
    IF (q_eff_trial < 1.0E-30_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_CDM_CoupledUpdate]: q_eff_trial near zero'
      RETURN
    END IF
    n_dir = s_eff_trial / (q_eff_trial / SQRT(1.5_wp))
    beta  = 1.0_wp - 3.0_wp * G * dg / q_eff_trial

    ! Update effective stress
    sigma_eff_new(1) = beta * s_eff_trial(1) + p_mean
    sigma_eff_new(2) = beta * s_eff_trial(2) + p_mean
    sigma_eff_new(3) = beta * s_eff_trial(3) + p_mean
    sigma_eff_new(4) = beta * s_eff_trial(4)
    sigma_eff_new(5) = beta * s_eff_trial(5)
    sigma_eff_new(6) = beta * s_eff_trial(6)

    ! Update plastic strain
    state%eps_p_eq = state%eps_p_eq + dg
    state%strain_p = state%strain_p + dg * n_dir

    ! Updated effective Von Mises
    q_eff_new = sigma_y  ! At convergence: q̃_new = σ_y(ε̄_p_new)

    ! ---- Step 4: Damage evolution (§5.3 Step 4) ----
    D_new = D_old
    IF (state%eps_p_eq > props%eps_D) THEN
      state%damaged = .TRUE.
      ! Triaxiality function Rv
      CALL PH_CDM_Triaxiality(sigma_eff_new, q_eff_new, props%nu, Rv)
      ! Damage energy release rate Y
      CALL PH_CDM_EnergyRelease(q_eff_new, Rv, props%E, Y_dam)
      state%Y = Y_dam
      ! Damage increment: ΔD = (Y/S)^s · Δγ
      CALL PH_CDM_DamageEvolution(Y_dam, props%S_dmg, props%s_exp, dg, &
                                    D_old, props%D_crit, D_new)
    END IF

    ! Check critical damage
    IF (D_new >= props%D_crit) THEN
      state%failed = .TRUE.
      D_new = props%D_crit
    END IF
    state%D = D_new

    ! ---- Step 5: Nominal stress recovery (§5.3 Step 5) ----
    ! σ = (1 - D_new) · σ̃
    state%eff_stress = sigma_eff_new
    state%stress     = (1.0_wp - D_new) * sigma_eff_new

    ! ---- Step 6: Damaged consistent tangent (§5.3 Step 6) ----
    ! D_ep^dmg ≈ (1-D_new) · D_ep  (simplified, ignoring ∂D/∂ε terms)
    CALL PH_CDM_DamagedTangent(D_el, G, H_tan, dg, q_eff_trial, n_dir, &
                                D_new, tangent)
    state%D_ep = tangent

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_CDM_CoupledUpdate

  !===========================================================================
  ! PH_CDM_EffectiveStress — Compute effective stress σ̃ = σ/(1-D)
  !
  ! Design Doc: §5.1
  ! Formula: σ̃_i = σ_i / (1 - D)
  !===========================================================================
  SUBROUTINE PH_CDM_EffectiveStress(stress, D, eff_stress)
    REAL(wp), INTENT(IN)  :: stress(6)      ! Nominal stress (Voigt)
    REAL(wp), INTENT(IN)  :: D              ! Damage variable
    REAL(wp), INTENT(OUT) :: eff_stress(6)  ! Effective stress (Voigt)

    REAL(wp) :: one_minus_D

    one_minus_D = MAX(1.0_wp - D, D_SAFE_MIN)
    eff_stress = stress / one_minus_D

  END SUBROUTINE PH_CDM_EffectiveStress

  !===========================================================================
  ! PH_CDM_EnergyRelease — Damage energy release rate Y
  !
  ! Design Doc: §5.2
  ! Formula: Y = σ_eq² · Rv / (2E)
  ! Note: In effective stress space, (1-D)² cancels out
  !===========================================================================
  SUBROUTINE PH_CDM_EnergyRelease(sigma_eq, Rv, E, Y)
    REAL(wp), INTENT(IN)  :: sigma_eq    ! Effective Von Mises stress
    REAL(wp), INTENT(IN)  :: Rv          ! Triaxiality function
    REAL(wp), INTENT(IN)  :: E           ! Young's modulus
    REAL(wp), INTENT(OUT) :: Y           ! Energy release rate

    ! Y = σ_eq² · Rv / (2E)
    Y = sigma_eq**2 * Rv / (2.0_wp * E)

  END SUBROUTINE PH_CDM_EnergyRelease

  !===========================================================================
  ! PH_CDM_Triaxiality — Triaxiality function Rv
  !
  ! Design Doc: §5.2
  ! Formula: Rv = (2/3)(1+ν) + 3(1-2ν)(σ_H/σ_eq)²
  !   where σ_H = (1/3)tr(σ)  (hydrostatic stress)
  !===========================================================================
  SUBROUTINE PH_CDM_Triaxiality(stress, sigma_eq, nu, Rv)
    REAL(wp), INTENT(IN)  :: stress(6)   ! Stress (Voigt)
    REAL(wp), INTENT(IN)  :: sigma_eq    ! Von Mises equivalent
    REAL(wp), INTENT(IN)  :: nu          ! Poisson's ratio
    REAL(wp), INTENT(OUT) :: Rv          ! Triaxiality function

    REAL(wp) :: sigma_H    ! Hydrostatic stress
    REAL(wp) :: triax      ! Stress triaxiality ratio σ_H/σ_eq

    ! σ_H = (1/3)(σ_11 + σ_22 + σ_33)
    sigma_H = (stress(1) + stress(2) + stress(3)) / 3.0_wp

    ! Triaxiality ratio (with floor to avoid division by zero)
    triax = sigma_H / MAX(sigma_eq, 1.0E-12_wp)

    ! Rv = (2/3)(1+ν) + 3(1-2ν)·(σ_H/σ_eq)²
    Rv = (2.0_wp / 3.0_wp) * (1.0_wp + nu) &
       + 3.0_wp * (1.0_wp - 2.0_wp * nu) * triax**2

  END SUBROUTINE PH_CDM_Triaxiality

  !===========================================================================
  ! PH_CDM_DamageEvolution — Compute damage increment ΔD
  !
  ! Design Doc: §5.2, §5.3 Step 4
  ! Formula: ΔD = (Y/S)^s · Δγ
  !          D_new = min(D_old + ΔD, D_crit)
  !===========================================================================
  SUBROUTINE PH_CDM_DamageEvolution(Y, S_dmg, s_exp, dg, D_old, D_crit, D_new)
    REAL(wp), INTENT(IN)  :: Y           ! Damage energy release rate
    REAL(wp), INTENT(IN)  :: S_dmg       ! Damage strength parameter
    REAL(wp), INTENT(IN)  :: s_exp       ! Damage exponent
    REAL(wp), INTENT(IN)  :: dg          ! Plastic multiplier increment
    REAL(wp), INTENT(IN)  :: D_old       ! Previous damage
    REAL(wp), INTENT(IN)  :: D_crit      ! Critical damage
    REAL(wp), INTENT(OUT) :: D_new       ! Updated damage

    REAL(wp) :: delta_D  ! Damage increment

    ! ΔD = (Y/S)^s · Δγ
    delta_D = (Y / S_dmg)**s_exp * dg

    ! D_{n+1} = min(D_n + ΔD, D_c)
    D_new = MIN(D_old + delta_D, D_crit)

  END SUBROUTINE PH_CDM_DamageEvolution

  !===========================================================================
  ! PH_CDM_DamagedTangent — Consistent tangent with damage correction
  !
  ! Design Doc: §5.3 Step 6
  ! Simplified form (engineering approximation):
  !   D_ep^dmg ≈ (1-D) · D_ep
  ! where D_ep is the standard J2 consistent tangent:
  !   D_ep = D_el - (6G²/(3G+H')) · n⊗n
  !
  ! Note: Full form includes ∂D/∂ε terms (omitted for computational
  !       efficiency, see §5.3 discussion). Higher-order correction:
  !   D_ep^dmg = (1-D)·D_ep - σ̃⊗(∂D/∂ε)
  !===========================================================================
  SUBROUTINE PH_CDM_DamagedTangent(D_el, G, H_tan, dg, q_trial, n_dir, &
                                     D_new, tangent)
    REAL(wp), INTENT(IN)  :: D_el(6,6)    ! Elastic stiffness
    REAL(wp), INTENT(IN)  :: G            ! Shear modulus
    REAL(wp), INTENT(IN)  :: H_tan        ! Hardening tangent
    REAL(wp), INTENT(IN)  :: dg           ! Plastic multiplier
    REAL(wp), INTENT(IN)  :: q_trial      ! Trial Von Mises
    REAL(wp), INTENT(IN)  :: n_dir(6)     ! Flow direction
    REAL(wp), INTENT(IN)  :: D_new        ! Updated damage variable
    REAL(wp), INTENT(OUT) :: tangent(6,6) ! Damaged tangent

    ! Local
    REAL(wp) :: D_ep(6,6)   ! Undamaged J2 consistent tangent
    REAL(wp) :: theta1      ! Radial return factor (= beta)
    REAL(wp) :: theta2      ! Newton correction factor
    REAL(wp) :: K_bulk      ! Bulk modulus
    INTEGER(i4) :: i, j

    ! Build full undamaged consistent tangent D_ep (Simo & Taylor 1985)
    ! D_ep = K·I⊗I + 2G·θ₁·I_dev - 2G·(θ₁-θ₂)·n⊗n
    ! θ₁ = 1 - 3G·Δγ/q_trial,  θ₂ = 3G/(3G+H')
    theta1 = 1.0_wp - 3.0_wp * G * dg / q_trial
    theta2 = 3.0_wp * G / (3.0_wp * G + H_tan)
    K_bulk = (D_el(1,1) + 2.0_wp * D_el(1,2)) / 3.0_wp

    D_ep = 0.0_wp
    ! Volumetric part: K·I⊗I
    DO i = 1, 3
      DO j = 1, 3
        D_ep(i,j) = D_ep(i,j) + K_bulk
      END DO
    END DO
    ! Deviatoric part: 2G·θ₁·I_dev
    DO i = 1, 6
      D_ep(i,i) = D_ep(i,i) + 2.0_wp * G * theta1
    END DO
    DO i = 1, 3
      DO j = 1, 3
        D_ep(i,j) = D_ep(i,j) - 2.0_wp * G * theta1 / 3.0_wp
      END DO
    END DO
    ! n⊗n correction: -2G·(θ₁-θ₂)·n⊗n
    DO i = 1, 6
      DO j = 1, 6
        D_ep(i,j) = D_ep(i,j) &
          - 2.0_wp * G * (theta1 - theta2) * n_dir(i) * n_dir(j)
      END DO
    END DO

    ! Damaged tangent: D_ep^dmg = (1-D) · D_ep
    tangent = (1.0_wp - D_new) * D_ep

    ! Note: Full form D_ep^dmg = (1-D)·D_ep - σ̃⊗(∂D/∂ε) is omitted
    ! for computational efficiency (§5.3 discussion). The simplified form
    ! provides adequate convergence for most engineering applications.

  END SUBROUTINE PH_CDM_DamagedTangent

  !===========================================================================
  ! STANDARD 4-ROUTINE INTERFACE (B2 Dispatch Contract)
  !===========================================================================

  !---------------------------------------------------------------------------
  ! PH_Mat_CDM_Validate_Params — Standard validation entry
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_CDM_Validate_Params(props, ierr)
    TYPE(PH_CDM_Props),     INTENT(IN)  :: props
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL init_error_status(ierr)
    IF (props%E <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_CDM_Validate]: E must be positive'
      RETURN
    END IF
    IF (props%S_dmg <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_CDM_Validate]: S_dmg must be positive'
      RETURN
    END IF
    IF (props%D_crit <= 0.0_wp .OR. props%D_crit > 1.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_CDM_Validate]: D_crit must be in (0, 1]'
      RETURN
    END IF
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_CDM_Validate_Params

  !---------------------------------------------------------------------------
  ! PH_Mat_CDM_Compute_Stress — Standard stress computation entry
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_CDM_Compute_Stress(props, strain_inc, state, stress, ierr)
    TYPE(PH_CDM_Props),     INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: strain_inc(6)
    TYPE(PH_CDM_State),     INTENT(INOUT) :: state
    REAL(wp),               INTENT(OUT)   :: stress(6)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    REAL(wp) :: tangent(6,6)
    REAL(wp) :: pnewdt

    pnewdt = 1.0_wp
    CALL PH_CDM_ComputeStress(props, strain_inc, state, tangent, pnewdt, ierr)
    stress = state%stress
  END SUBROUTINE PH_Mat_CDM_Compute_Stress

  !---------------------------------------------------------------------------
  ! PH_Mat_CDM_Compute_Tangent — Standard tangent entry
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_CDM_Compute_Tangent(props, state, C_tangent, ierr)
    TYPE(PH_CDM_Props),     INTENT(IN)  :: props
    TYPE(PH_CDM_State),     INTENT(IN)  :: state
    REAL(wp),               INTENT(OUT) :: C_tangent(6,6)
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL init_error_status(ierr)
    C_tangent = state%D_ep
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_CDM_Compute_Tangent

  !---------------------------------------------------------------------------
  ! PH_Mat_CDM_Update_State — Standard state update entry
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_CDM_Update_State(props, state, ierr)
    TYPE(PH_CDM_Props),     INTENT(IN)    :: props
    TYPE(PH_CDM_State),     INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL init_error_status(ierr)
    ! State already updated in PH_CDM_CoupledUpdate
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_CDM_Update_State

END MODULE PH_Mat_Damage_Lemaitre_Core
