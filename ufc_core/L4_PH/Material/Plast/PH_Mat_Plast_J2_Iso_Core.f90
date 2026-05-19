!===============================================================================
! MODULE: PH_Mat_Plast_J2_Iso_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  J2 radial return algorithm with nonlinear hardening Newton iteration
!   W1: stress integration invoked from **PH_Mat_Dispatch** / **PH_Mat_Reg** routing;
!   material parameters come from slot **`desc%props`** upstream (**Populate**), not L5 ctx alone.
! Purpose: J2 isotropic radial-return kernel; public API is PH_J2_ComputeStress(Arg).
! Theory: von Mises yield, trial predictor + local Newton on radial return (Simo & Hughes).
! Status: ACTIVE
!===============================================================================
MODULE PH_Mat_Plast_J2_Iso_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public Interface
  !-----------------------------------------------------------------------------
  PUBLIC :: PH_J2_Init
  PUBLIC :: PH_J2_ComputeTrialStress
  PUBLIC :: PH_J2_ComputeStress_Arg
  PUBLIC :: PH_J2_ComputeStress
  PUBLIC :: PH_J2_ComputeHardening
  PUBLIC :: PH_J2_ComputeHardeningTangent

  !-----------------------------------------------------------------------------
  ! Hardening Type Constants (§3.3)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_J2_HARD_LINEAR = 1_i4  ! Linear isotropic
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_J2_HARD_SWIFT  = 2_i4  ! Swift power law
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_J2_HARD_VOCE   = 3_i4  ! Voce exponential
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_J2_HARD_AF     = 4_i4  ! Armstrong-Frederick

  !-----------------------------------------------------------------------------
  ! Algorithm Control Constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: PH_MAT_J2_MAX_LOCAL_ITER = 25_i4       ! Max Newton iterations
  REAL(wp),    PARAMETER :: TOL_NRLOC = 1.0E-10_wp       ! Relative tolerance
  REAL(wp),    PARAMETER :: PNEWDT_MIN = 0.25_wp         ! Min time step fraction

  !-----------------------------------------------------------------------------
  ! TYPE: PH_J2_Props — Material properties descriptor (P2 nested)
  !   Maps to: MD_Mat_PLM_J2_Desc (§2.3, §3.7)
  !   Written: Populate phase (cold path, once)
  !   Read by: Kernel (hot path, read-only)
  !-----------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_J2_Cfg_Elastic
    REAL(wp) :: E           = 0.0_wp   ! Young's modulus [Pa]
    REAL(wp) :: nu          = 0.0_wp   ! Poisson's ratio [-]
  END TYPE PH_J2_Cfg_Elastic

  TYPE, PUBLIC :: PH_J2_Cfg_Yield
    REAL(wp) :: sigma_y0    = 0.0_wp   ! Initial yield stress [Pa]
  END TYPE PH_J2_Cfg_Yield

  TYPE, PUBLIC :: PH_J2_Cfg_Harden
    REAL(wp) :: H           = 0.0_wp   ! Linear hardening modulus [Pa]
    !-- Swift parameters: σ_y = K_swift*(eps0_swift + ε̄_p)^n_swift
    REAL(wp) :: K_swift     = 0.0_wp   ! Swift strength coefficient [Pa]
    REAL(wp) :: n_swift     = 0.0_wp   ! Swift hardening exponent [-]
    REAL(wp) :: eps0_swift  = 0.0_wp   ! Swift reference strain [-]
    !-- Voce parameters: σ_y = σ_y0 + sigma_inf*(1 - exp(-delta_voce*ε̄_p))
    REAL(wp) :: sigma_inf   = 0.0_wp   ! Voce saturation stress [Pa]
    REAL(wp) :: delta_voce  = 0.0_wp   ! Voce decay rate [-]
    !-- Armstrong-Frederick kinematic: dα = (2/3)C·dε_p - γ·α·dε̄_p
    REAL(wp) :: C_af        = 0.0_wp   ! AF hardening C parameter [Pa]
    REAL(wp) :: gamma_af    = 0.0_wp   ! AF recall parameter γ [-]
  END TYPE PH_J2_Cfg_Harden

  TYPE, PUBLIC :: PH_J2_Cfg_Control
    INTEGER(i4) :: hardening_type = PH_MAT_J2_HARD_LINEAR
    LOGICAL     :: use_kinematic  = .FALSE.
  END TYPE PH_J2_Cfg_Control

  TYPE, PUBLIC :: PH_J2_Props
    TYPE(PH_J2_Cfg_Elastic)  :: elastic
    TYPE(PH_J2_Cfg_Yield)    :: yield
    TYPE(PH_J2_Cfg_Harden)   :: harden
    TYPE(PH_J2_Cfg_Control)  :: ctrl
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_J2_Props

  !-----------------------------------------------------------------------------
  ! TYPE: PH_J2_State — Integration point state variables (P2 nested)
  !   Maps to: PH_Mat_PLM_J2_State (§2.3)
  !   Layout: statev(1)=ε̄_p, statev(2:7)=ε_p(6), statev(8:13)=α(6) if kinematic
  !   Written: Each IP iteration (kernel writes)
  !   Read by: Element (assembly), L5 (output)
  !-----------------------------------------------------------------------------

  TYPE, PUBLIC :: PH_J2_St_Plastic
    REAL(wp) :: eps_p_eq       = 0.0_wp    ! Equivalent plastic strain ε̄_p
    REAL(wp) :: strain_p(6)    = 0.0_wp    ! Plastic strain ε_p (Voigt)
    LOGICAL  :: yielded        = .FALSE.   ! Current yield state flag
  END TYPE PH_J2_St_Plastic

  TYPE, PUBLIC :: PH_J2_St_Stress
    REAL(wp) :: stress(6)      = 0.0_wp    ! Cauchy stress σ (Voigt)
    REAL(wp) :: backstress(6)  = 0.0_wp    ! Backstress α (kinematic hardening)
  END TYPE PH_J2_St_Stress

  TYPE, PUBLIC :: PH_J2_St_Tangent
    REAL(wp) :: D_ep(6,6)      = 0.0_wp    ! Consistent tangent modulus
  END TYPE PH_J2_St_Tangent

  TYPE, PUBLIC :: PH_J2_State
    TYPE(PH_J2_St_Plastic) :: plastic
    TYPE(PH_J2_St_Stress)  :: stress
    TYPE(PH_J2_St_Tangent) :: tangent
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_J2_State

  ! SIO bundle for PH_J2_ComputeStress (INTF-001)
  TYPE, PUBLIC :: PH_J2_ComputeStress_Arg
    TYPE(PH_J2_Props) :: props                    ! [IN]
    REAL(wp) :: strain_inc(6) = 0.0_wp           ! [IN] strain increment (Voigt)
    TYPE(PH_J2_State) :: state                   ! [INOUT]
    REAL(wp) :: tangent(6, 6) = 0.0_wp           ! [OUT] consistent tangent D_ep
    REAL(wp) :: pnewdt = 1.0_wp                  ! [INOUT] suggested time-step ratio
    TYPE(ErrorStatusType) :: status              ! [OUT]
  END TYPE PH_J2_ComputeStress_Arg

CONTAINS

  !===========================================================================
  ! PH_J2_ComputeStress — SIO public entry (single Arg bundle)
  !===========================================================================
  SUBROUTINE PH_J2_ComputeStress(arg)
    ! Theory: J2 radial return (see PH_J2_ComputeStress_Core).
    ! Logic:  Unpack Arg bundle and delegate to core integrator.
    ! Compute: PH_J2_ComputeStress_Core.
    ! Data:   arg%props/strain_inc/state in; arg%tangent/pnewdt/status out.
    TYPE(PH_J2_ComputeStress_Arg), INTENT(INOUT) :: arg
    CALL PH_J2_ComputeStress_Core(arg%props, arg%strain_inc, arg%state, &
        arg%tangent, arg%pnewdt, arg%status)
  END SUBROUTINE PH_J2_ComputeStress

  !===========================================================================
  ! PH_J2_ComputeStress_Core — radial return spine (module-private callers)
  !===========================================================================
  SUBROUTINE PH_J2_ComputeStress_Core(props, strain_inc, state, tangent, pnewdt, ierr)
    ! 理论链: J2 von Mises 径向返回 + 等向/随动硬化。
    ! 逻辑链: 弹性试应力 → 屈服判据 → 塑性分支径向返回。
    ! 计算链: PH_J2_ComputeTrialStress / ComputeYieldCheck / ApplyRadialReturn / ComputeConsistentTangent。
    ! 数据链: props(IN); state(INOUT); tangent·pnewdt·status(OUT/INOUT)。
    TYPE(PH_J2_Props),      INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: strain_inc(6)  ! Δε (Voigt)
    TYPE(PH_J2_State),      INTENT(INOUT) :: state
    REAL(wp),               INTENT(OUT)   :: tangent(6,6)   ! D_ep output
    REAL(wp),               INTENT(INOUT) :: pnewdt         ! Time step suggestion
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    ! Local variables
    REAL(wp) :: D_el(6,6)           ! Elastic stiffness
    REAL(wp) :: sigma_trial(6)      ! Trial stress
    REAL(wp) :: s_trial(6)          ! Trial deviatoric stress
    REAL(wp) :: q_trial             ! Trial Von Mises equivalent stress
    REAL(wp) :: p_mean              ! Mean (hydrostatic) pressure
    REAL(wp) :: f_trial             ! Trial yield function value
    REAL(wp) :: sigma_y             ! Current yield stress
    REAL(wp) :: dg                  ! Plastic multiplier increment Δγ
    REAL(wp) :: G                   ! Shear modulus
    REAL(wp) :: n_dir(6)            ! Flow direction
    REAL(wp) :: beta                ! Radial return factor

    CALL init_error_status(ierr)

    ! ---- Step 1: Elastic Prediction (§3.2) ----
    ! σ_trial = σ_n + D_e : Δε
    CALL PH_J2_ComputeTrialStress(props, state%stress%stress, strain_inc, &
                            D_el, sigma_trial, s_trial, q_trial, p_mean)

    ! ---- Step 2: Yield Check (§3.2) ----
    ! f_trial = q_trial - σ_y(ε̄_p_n)
    CALL PH_J2_ComputeYieldCheck(props, state%plastic%eps_p_eq, q_trial, f_trial, sigma_y)

    IF (f_trial <= 0.0_wp) THEN
      ! Elastic step: accept trial stress, tangent = D_el
      state%stress%stress = sigma_trial
      state%tangent%D_ep  = D_el
      tangent             = D_el
      state%plastic%yielded = .FALSE.
      ierr%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! ---- Step 3: Radial Return (§3.2 Step 3 + §3.5 Newton) ----
    ! Plastic step: find Δγ via Newton iteration
    G = props%elastic%E / (2.0_wp * (1.0_wp + props%elastic%nu))
    CALL PH_J2_ApplyRadialReturn(props, state, G, q_trial, s_trial, p_mean, &
                             dg, n_dir, beta, pnewdt, ierr)
    IF (ierr%status_code /= IF_STATUS_OK) RETURN

    ! ---- Step 4: Consistent Tangent (§3.4) ----
    ! D_ep = D_e - correction terms
    CALL PH_J2_ComputeConsistentTangent(props, D_el, G, dg, q_trial, n_dir, &
                                  state%plastic%eps_p_eq, tangent)
    state%tangent%D_ep  = tangent
    state%plastic%yielded = .TRUE.

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_J2_ComputeStress_Core

  !===========================================================================
  ! PH_J2_Init — Initialize J2 properties and state
  !
  ! Design Doc: §2.3, §3.7
  ! Purpose: Set up Props from material parameters, zero-initialize State
  !===========================================================================
  SUBROUTINE PH_J2_Init(props, state, ierr)
    TYPE(PH_J2_Props),      INTENT(INOUT) :: props
    TYPE(PH_J2_State),      INTENT(OUT)   :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL init_error_status(ierr)

    ! Validate basic parameters
    IF (props%elastic%E <= 0.0_wp .OR. props%elastic%nu < 0.0_wp .OR. props%elastic%nu >= 0.5_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_J2_Init]: Invalid elastic parameters (E<=0 or nu out of range)'
      RETURN
    END IF
    IF (props%yield%sigma_y0 <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_J2_Init]: sigma_y0 must be positive'
      RETURN
    END IF

    ! Zero-initialize state
    state%plastic%eps_p_eq   = 0.0_wp
    state%stress%stress      = 0.0_wp
    state%plastic%strain_p   = 0.0_wp
    state%stress%backstress  = 0.0_wp
    state%tangent%D_ep       = 0.0_wp
    state%plastic%yielded    = .FALSE.

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_J2_Init

  !===========================================================================
  ! PH_J2_ComputeTrialStress — Step 1: Elastic predictor (trial stress)
  !
  ! Design Doc: §3.2 Step 1
  ! Formula: σ_trial = σ_n + D_e : Δε
  !          s_trial = dev(σ_trial)
  !          q_trial = sqrt(3/2 * s:s)
  !          p_mean  = (1/3) tr(σ_trial)
  !===========================================================================
  SUBROUTINE PH_J2_ComputeTrialStress(props, stress_n, strain_inc, &
                                 D_el, sigma_trial, s_trial, q_trial, p_mean)
    ! 理论链: σ_tr = σ_n + D_e Δε；偏应力与 von Mises q。
    ! 逻辑链: 构造 D_e，更新试应力与偏量。
    ! 计算链: Construct_Elastic_D + 张量偏量分解。
    ! 数据链: stress_n·strain_inc(IN); D_el·sigma_trial·s_trial·q_trial·p_mean(OUT)。
    TYPE(PH_J2_Props), INTENT(IN)  :: props
    REAL(wp),          INTENT(IN)  :: stress_n(6)     ! σ_n (previous converged)
    REAL(wp),          INTENT(IN)  :: strain_inc(6)   ! Δε
    REAL(wp),          INTENT(OUT) :: D_el(6,6)       ! Elastic stiffness
    REAL(wp),          INTENT(OUT) :: sigma_trial(6)  ! Trial stress
    REAL(wp),          INTENT(OUT) :: s_trial(6)      ! Trial deviatoric
    REAL(wp),          INTENT(OUT) :: q_trial         ! Trial Von Mises
    REAL(wp),          INTENT(OUT) :: p_mean          ! Hydrostatic pressure

    ! Local
    REAL(wp) :: lambda, mu
    INTEGER(i4) :: i, j

    ! Lamé parameters:
    ! λ = E·ν / ((1+ν)(1-2ν))
    ! μ = G = E / (2(1+ν))
    mu     = props%elastic%E / (2.0_wp * (1.0_wp + props%elastic%nu))
    lambda = props%elastic%E * props%elastic%nu / ((1.0_wp + props%elastic%nu) * (1.0_wp - 2.0_wp * props%elastic%nu))

    ! Build isotropic elastic stiffness D_el (6×6 Voigt)
    ! D_el = [λ+2μ  λ     λ     0  0  0 ]
    !        [λ     λ+2μ  λ     0  0  0 ]
    !        [λ     λ     λ+2μ  0  0  0 ]
    !        [0     0     0     μ  0  0 ]
    !        [0     0     0     0  μ  0 ]
    !        [0     0     0     0  0  μ ]
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

    ! Trial stress: σ_trial = σ_n + D_el : Δε
    sigma_trial = stress_n + MATMUL(D_el, strain_inc)

    ! Hydrostatic pressure: p = (1/3)(σ_11 + σ_22 + σ_33)
    p_mean = (sigma_trial(1) + sigma_trial(2) + sigma_trial(3)) / 3.0_wp

    ! Deviatoric stress: s = σ - p·I
    s_trial = sigma_trial
    s_trial(1) = s_trial(1) - p_mean
    s_trial(2) = s_trial(2) - p_mean
    s_trial(3) = s_trial(3) - p_mean

    ! Von Mises equivalent stress (Voigt):
    ! q = sqrt(s1² + s2² + s3² + 2*(s4² + s5² + s6²))
    ! Note: factor sqrt(3/2) included via shear component doubling
    q_trial = SQRT( s_trial(1)**2 + s_trial(2)**2 + s_trial(3)**2 &
                  + 2.0_wp * (s_trial(4)**2 + s_trial(5)**2 + s_trial(6)**2) )
    ! Scale to Von Mises: q = sqrt(3/2) * ||s||
    q_trial = SQRT(1.5_wp) * q_trial

  END SUBROUTINE PH_J2_ComputeTrialStress

  !===========================================================================
  ! PH_J2_ComputeYieldCheck — Step 2: Yield function evaluation
  !
  ! Design Doc: §3.2 Step 2
  ! Formula: f_trial = q_trial - σ_y(ε̄_p_n)
  !          If f_trial <= 0 → elastic step
  !          If f_trial > 0  → plastic step (proceed to radial return)
  !===========================================================================
  SUBROUTINE PH_J2_ComputeYieldCheck(props, eps_p_eq, q_trial, f_trial, sigma_y)
    TYPE(PH_J2_Props), INTENT(IN)  :: props
    REAL(wp),          INTENT(IN)  :: eps_p_eq  ! Current ε̄_p
    REAL(wp),          INTENT(IN)  :: q_trial   ! Trial Von Mises stress
    REAL(wp),          INTENT(OUT) :: f_trial   ! Yield function value
    REAL(wp),          INTENT(OUT) :: sigma_y   ! Current yield stress

    ! Evaluate hardening law at current plastic strain
    CALL PH_J2_ComputeHardening(props, eps_p_eq, sigma_y)

    ! Yield function: f = q - σ_y
    f_trial = q_trial - sigma_y

  END SUBROUTINE PH_J2_ComputeYieldCheck

  !===========================================================================
  ! PH_J2_ApplyRadialReturn — Step 3: Radial return mapping with Newton iteration
  !
  ! Design Doc: §3.2 Step 3, §3.5
  ! Algorithm:
  !   For linear hardening: Δγ = f_trial / (3G + H')  (closed-form)
  !   For nonlinear hardening: local Newton iteration on residual
  !     R(Δγ) = q_trial - 3G·Δγ - σ_y(ε̄_p_n + Δγ) = 0
  !     dR/dΔγ = -(3G + H'(ε̄_p_n + Δγ))
  !     Δγ^(k+1) = Δγ^(k) - R/dR
  !   Convergence: |R| < tol_nrloc · σ_y0
  !   Updates: stress, ε̄_p, ε_p, backstress
  !===========================================================================
  SUBROUTINE PH_J2_ApplyRadialReturn(props, state, G, q_trial, s_trial, p_mean, &
                                  dg, n_dir, beta, pnewdt, ierr)
    TYPE(PH_J2_Props),      INTENT(IN)    :: props
    TYPE(PH_J2_State),      INTENT(INOUT) :: state
    REAL(wp),               INTENT(IN)    :: G          ! Shear modulus
    REAL(wp),               INTENT(IN)    :: q_trial    ! Trial Von Mises
    REAL(wp),               INTENT(IN)    :: s_trial(6) ! Trial deviatoric
    REAL(wp),               INTENT(IN)    :: p_mean     ! Hydrostatic pressure
    REAL(wp),               INTENT(OUT)   :: dg         ! Plastic multiplier Δγ
    REAL(wp),               INTENT(OUT)   :: n_dir(6)   ! Flow direction
    REAL(wp),               INTENT(OUT)   :: beta       ! Radial return factor
    REAL(wp),               INTENT(INOUT) :: pnewdt     ! Time step control
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    ! Local
    REAL(wp) :: H_tan               ! Hardening tangent H'
    REAL(wp) :: sigma_y             ! Yield stress at trial peeq
    REAL(wp) :: peeq_trial          ! Trial equivalent plastic strain
    REAL(wp) :: R_nrloc             ! Newton residual
    REAL(wp) :: dR_ddg              ! Newton Jacobian dR/dΔγ
    REAL(wp) :: f_trial             ! Initial yield function
    INTEGER(i4) :: iter             ! Iteration counter

    CALL init_error_status(ierr)

    ! Flow direction: n = s_trial / ||s_trial|| (normalized)
    ! Since q_trial = sqrt(3/2) * ||s_trial||, ||s_trial|| = q_trial / sqrt(3/2)
    IF (q_trial < 1.0E-30_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_J2_ApplyRadialReturn]: q_trial near zero, degenerate state'
      RETURN
    END IF
    n_dir = s_trial / (q_trial / SQRT(1.5_wp))  ! n = s/||s||

    ! Initial guess (linear approximation): Δγ^(0) = f / (3G + H'(ε̄_p_n))
    CALL PH_J2_ComputeHardeningTangent(props, state%plastic%eps_p_eq, H_tan)
    CALL PH_J2_ComputeHardening(props, state%plastic%eps_p_eq, sigma_y)
    f_trial = q_trial - sigma_y
    dg = f_trial / (3.0_wp * G + H_tan)

    ! ---- Local Newton Iteration (§3.5) ----
    ! Residual: R(Δγ) = q_trial - 3G·Δγ - σ_y(ε̄_p_n + Δγ)
    ! Jacobian: dR/dΔγ = -(3G + H')
    DO iter = 1, PH_MAT_J2_MAX_LOCAL_ITER
      peeq_trial = state%plastic%eps_p_eq + dg
      CALL PH_J2_ComputeHardening(props, peeq_trial, sigma_y)
      CALL PH_J2_ComputeHardeningTangent(props, peeq_trial, H_tan)

      R_nrloc = q_trial - 3.0_wp * G * dg - sigma_y

      ! Check convergence: |R| < tol · σ_y0
      IF (ABS(R_nrloc) < TOL_NRLOC * props%yield%sigma_y0) EXIT

      ! Newton update
      dR_ddg = -(3.0_wp * G + H_tan)
      IF (ABS(dR_ddg) < 1.0E-30_wp) THEN
        ierr%status_code = IF_STATUS_ERROR
        ierr%message = '[PH_J2_ApplyRadialReturn]: Zero Jacobian in local Newton'
        RETURN
      END IF
      dg = dg - R_nrloc / dR_ddg

      ! Safety: Δγ must remain positive
      IF (dg < 0.0_wp) dg = 0.0_wp
    END DO

    ! Check convergence
    IF (iter > PH_MAT_J2_MAX_LOCAL_ITER) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_J2_ApplyRadialReturn]: Local Newton did not converge'
      pnewdt = PNEWDT_MIN
      RETURN
    END IF

    ! ---- Update state (§3.2 Step 3b) ----
    ! Radial return factor: β = 1 - 3G·Δγ/q_trial
    beta = 1.0_wp - 3.0_wp * G * dg / q_trial

    ! Stress update: σ_{n+1} = β·s_trial + p·I
    state%stress%stress(1) = beta * s_trial(1) + p_mean
    state%stress%stress(2) = beta * s_trial(2) + p_mean
    state%stress%stress(3) = beta * s_trial(3) + p_mean
    state%stress%stress(4) = beta * s_trial(4)
    state%stress%stress(5) = beta * s_trial(5)
    state%stress%stress(6) = beta * s_trial(6)

    ! Equivalent plastic strain update: ε̄_p_{n+1} = ε̄_p_n + Δγ
    state%plastic%eps_p_eq = state%plastic%eps_p_eq + dg

    ! Plastic strain increment: Δε_p = Δγ · n
    state%plastic%strain_p = state%plastic%strain_p + dg * n_dir

    ! Backstress update (Armstrong-Frederick, §3.3):
    ! α_{n+1} = α_n + (2/3)C·Δγ·n - γ·α_n·Δγ
    IF (props%ctrl%use_kinematic) THEN
      state%stress%backstress = state%stress%backstress &
        + props%harden%C_af * dg * n_dir &
        - props%harden%gamma_af * state%stress%backstress * dg
    END IF

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_J2_ApplyRadialReturn

  !===========================================================================
  ! PH_J2_ComputeConsistentTangent — Step 4: Consistent tangent modulus D_ep
  !
  ! Design Doc: §3.4
  ! Formula (simplified): D_ep = D_e - (6G²/(3G+H')) · n⊗n
  ! Formula (full, with deviatoric projection correction):
  !   D_ep = D_e - (6G²·Δγ/q_trial)·I_dev
  !        + 6G²·(Δγ/q_trial - 1/(3G+H'))·n⊗n
  !===========================================================================
  SUBROUTINE PH_J2_ComputeConsistentTangent(props, D_el, G, dg, q_trial, n_dir, &
                                       eps_p_eq, tangent)
    ! 理论链: 一致切线 D_ep（径向返回线性化）。
    ! 逻辑链: 由 Δγ、q_trial 与硬化切线组装 D_ep。
    ! 计算链: 6×6 Voigt 修正弹性刚度。
    ! 数据链: D_el·G·dg·n_dir(IN); tangent(OUT)。
    TYPE(PH_J2_Props), INTENT(IN)  :: props
    REAL(wp),          INTENT(IN)  :: D_el(6,6)    ! Elastic stiffness
    REAL(wp),          INTENT(IN)  :: G            ! Shear modulus
    REAL(wp),          INTENT(IN)  :: dg           ! Plastic multiplier Δγ
    REAL(wp),          INTENT(IN)  :: q_trial      ! Trial Von Mises
    REAL(wp),          INTENT(IN)  :: n_dir(6)     ! Flow direction
    REAL(wp),          INTENT(IN)  :: eps_p_eq     ! Updated ε̄_p
    REAL(wp),          INTENT(OUT) :: tangent(6,6) ! Consistent tangent

    ! Local
    REAL(wp) :: H_tan          ! Hardening tangent at updated ε̄_p
    REAL(wp) :: theta1, theta2 ! Simo & Taylor coefficients
    INTEGER(i4) :: i, j

    CALL PH_J2_ComputeHardeningTangent(props, eps_p_eq, H_tan)

    ! Coefficients (§3.4):
    ! θ₁ = 1 - 3G·Δγ/q_trial  (= β, radial return factor)
    ! θ₂ = 3G/(3G + H')       (Newton correction factor)
    theta1 = 1.0_wp - 3.0_wp * G * dg / q_trial
    theta2 = 3.0_wp * G / (3.0_wp * G + H_tan)

    ! Full consistent tangent (Simo & Taylor 1985):
    ! D_ep = K·I⊗I + 2G·θ₁·I_dev - 2G·(θ₁ - θ₂)·n⊗n
    ! where I_dev = I_sym - (1/3)·I⊗I
    !
    ! Build volumetric part: K·I⊗I
    ! Build deviatoric part with θ₁ = 1 - 3G·Δγ/q_trial (= beta)
    ! Build n⊗n correction with θ₂ = 3G/(3G + H')
    tangent = 0.0_wp

    ! Bulk modulus
    ! K = λ + (2/3)·μ = E / (3(1-2ν))
    ! Already available via D_el: K = (D_el(1,1) + 2*D_el(1,2)) / 3
    ! We recompute for clarity:
    ! K·(I⊗I): tangent(i,j) += K for i,j in 1..3
    DO i = 1, 3
      DO j = 1, 3
        ! K·I⊗I
        tangent(i,j) = tangent(i,j) &
          + (D_el(1,1) + 2.0_wp * D_el(1,2)) / 3.0_wp
      END DO
    END DO

    ! 2G·θ₁·I_dev = 2G·θ₁·(I_sym - (1/3)·I⊗I)
    ! I_sym diagonal: 1 for i=j; off-diag (shear): 0.5 for Voigt pairs 4,5,6
    ! I⊗I: 1 for i,j in 1..3, else 0
    DO i = 1, 6
      ! Diagonal of I_sym
      tangent(i,i) = tangent(i,i) + 2.0_wp * G * theta1
    END DO
    ! Subtract (1/3)·I⊗I part from deviatoric
    DO i = 1, 3
      DO j = 1, 3
        tangent(i,j) = tangent(i,j) - 2.0_wp * G * theta1 / 3.0_wp
      END DO
    END DO

    ! n⊗n correction: -2G·(θ₁ - θ₂)·n⊗n
    DO i = 1, 6
      DO j = 1, 6
        tangent(i,j) = tangent(i,j) &
          - 2.0_wp * G * (theta1 - theta2) * n_dir(i) * n_dir(j)
      END DO
    END DO

  END SUBROUTINE PH_J2_ComputeConsistentTangent

  !===========================================================================
  ! PH_J2_ComputeHardening — Evaluate yield stress σ_y(ε̄_p)
  !
  ! Design Doc: §3.3
  ! Type 1: σ_y = σ_y0 + H · ε̄_p
  ! Type 2: σ_y = K_swift · (eps0_swift + ε̄_p)^n_swift
  ! Type 3: σ_y = σ_y0 + sigma_inf · (1 - exp(-delta_voce · ε̄_p))
  !===========================================================================
  SUBROUTINE PH_J2_ComputeHardening(props, eps_p_eq, sigma_y)
    TYPE(PH_J2_Props), INTENT(IN)  :: props
    REAL(wp),          INTENT(IN)  :: eps_p_eq  ! Equivalent plastic strain
    REAL(wp),          INTENT(OUT) :: sigma_y   ! Yield stress

    SELECT CASE (props%ctrl%hardening_type)
    CASE (PH_MAT_J2_HARD_LINEAR)
      ! σ_y = σ_y0 + H · ε̄_p
      sigma_y = props%yield%sigma_y0 + props%harden%H * eps_p_eq

    CASE (PH_MAT_J2_HARD_SWIFT)
      ! σ_y = K · (ε0 + ε̄_p)^n
      sigma_y = props%harden%K_swift * (props%harden%eps0_swift + eps_p_eq)**props%harden%n_swift

    CASE (PH_MAT_J2_HARD_VOCE)
      ! σ_y = σ_y0 + Q · (1 - exp(-δ · ε̄_p))
      sigma_y = props%yield%sigma_y0 + props%harden%sigma_inf * (1.0_wp - EXP(-props%harden%delta_voce * eps_p_eq))

    CASE DEFAULT
      ! Fallback to linear
      sigma_y = props%yield%sigma_y0 + props%harden%H * eps_p_eq
    END SELECT

  END SUBROUTINE PH_J2_ComputeHardening

  !===========================================================================
  ! PH_J2_ComputeHardeningTangent — Evaluate hardening tangent H' = dσ_y/dε̄_p
  !
  ! Design Doc: §3.3
  ! Type 1: H' = H (constant)
  ! Type 2: H' = K · n · (ε0 + ε̄_p)^(n-1)
  ! Type 3: H' = sigma_inf · delta · exp(-delta · ε̄_p)
  !===========================================================================
  SUBROUTINE PH_J2_ComputeHardeningTangent(props, eps_p_eq, H_tan)
    TYPE(PH_J2_Props), INTENT(IN)  :: props
    REAL(wp),          INTENT(IN)  :: eps_p_eq  ! Equivalent plastic strain
    REAL(wp),          INTENT(OUT) :: H_tan     ! Hardening tangent

    SELECT CASE (props%ctrl%hardening_type)
    CASE (PH_MAT_J2_HARD_LINEAR)
      ! H' = H (constant)
      H_tan = props%harden%H

    CASE (PH_MAT_J2_HARD_SWIFT)
      ! H' = K · n · (ε0 + ε̄_p)^(n-1)
      H_tan = props%harden%K_swift * props%harden%n_swift &
            * (props%harden%eps0_swift + eps_p_eq)**(props%harden%n_swift - 1.0_wp)

    CASE (PH_MAT_J2_HARD_VOCE)
      ! H' = Q · δ · exp(-δ · ε̄_p)
      H_tan = props%harden%sigma_inf * props%harden%delta_voce * EXP(-props%harden%delta_voce * eps_p_eq)

    CASE DEFAULT
      H_tan = props%harden%H
    END SELECT

  END SUBROUTINE PH_J2_ComputeHardeningTangent

  !---------------------------------------------------------------------------
  ! PH_Mat_J2_Validate_Params — validation (module-private)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_J2_Validate_Params(props, ierr)
    TYPE(PH_J2_Props),      INTENT(IN)  :: props
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL init_error_status(ierr)
    IF (props%elastic%E <= 0.0_wp .OR. props%elastic%nu < 0.0_wp .OR. props%elastic%nu >= 0.5_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_J2_Validate]: Invalid elastic parameters'
      RETURN
    END IF
    IF (props%yield%sigma_y0 <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_J2_Validate]: sigma_y0 must be positive'
      RETURN
    END IF
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_J2_Validate_Params

  !---------------------------------------------------------------------------
  ! PH_Mat_J2_Compute_Tangent — tangent readback (module-private)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_J2_Compute_Tangent(props, state, C_tangent, ierr)
    TYPE(PH_J2_Props),      INTENT(IN)  :: props
    TYPE(PH_J2_State),      INTENT(IN)  :: state
    REAL(wp),               INTENT(OUT) :: C_tangent(6,6)
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL init_error_status(ierr)
    C_tangent = state%tangent%D_ep
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_J2_Compute_Tangent

  !---------------------------------------------------------------------------
  ! PH_Mat_J2_Update_State — Standard state update entry
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Mat_J2_Update_State(props, state, ierr)
    TYPE(PH_J2_Props),      INTENT(IN)    :: props
    TYPE(PH_J2_State),      INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL init_error_status(ierr)
    ! State already updated in PH_J2_ComputeStress/RadialReturn
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_J2_Update_State

END MODULE PH_Mat_Plast_J2_Iso_Core
