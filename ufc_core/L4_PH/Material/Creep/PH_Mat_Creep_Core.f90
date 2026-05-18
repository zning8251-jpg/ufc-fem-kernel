!===============================================================================
! MODULE: PH_Mat_Creep_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Norton power-law and Nabarro-Herring diffusion creep models —
!         **W1**：**PH_Creep_Props** / Norton–NH 常数与 **`desc%props`**、**PH_Mat_Desc**
!         对齐；经 **PH_MAT_CREEP** / **Effective_Model** 路由。
!===============================================================================
!
! Design Document: DESIGN_Mat_ConstitutiveKernels.md §8
! Reference: Betten (2008) Creep Mechanics, Springer
!            Naumenko & Altenbach (2007) Modeling of Creep for Structural Analysis
!
! Norton Power-Law Creep (§8.2):
!   ε̇_cr = A · σ_eq^n · exp(-Q/(R·T))
!   where: A  = creep coefficient [Pa^-n · s^-1]
!          n  = stress exponent [-]
!          Q  = activation energy [J/mol]
!          R  = gas constant [J/(mol·K)]
!          T  = absolute temperature [K]
!   Simplified (isothermal): ε̇_cr = A · σ_eq^n
!
! Nabarro-Herring Diffusion Creep (§8.3):
!   ε̇_cr = (C_NH · Ω · D_v · σ) / (k_B · T · d²)
!   where: C_NH = geometric constant (~14)
!          Ω    = atomic volume [m³]
!          D_v  = lattice diffusion coefficient [m²/s]
!          d    = grain size [m]
!   Simplified: ε̇_cr = B · σ / d²
!
! Integration: Implicit backward Euler with local Newton iteration
!   Δε_cr = ε̇_cr(σ^{n+1}) · dt
!   σ^{n+1} = D_el : (ε^{n+1} - ε_cr^{n+1})
!
! CONTRACT Compliance:
!   - ErrorStatusType on all public procedures (no STOP)
!   - wp/i4 precision from IF_Prec_Core
!   - Intent declarations on all arguments
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
!
!>>> UFC_PH_QUENCH | Domain:Material/Creep | Role:Core | FuncSet:Compute,Init,Validate | HotPath:Yes
!>>> UFC_PH_CONTRACT | Material/CONTRACT.md
!
MODULE PH_Mat_Creep_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public Interface
  !-----------------------------------------------------------------------------
  PUBLIC :: PH_Mat_Creep_Compute_Stress
  PUBLIC :: PH_Mat_Creep_Compute_Tangent
  PUBLIC :: PH_Mat_Creep_Update_State
  PUBLIC :: PH_Mat_Creep_Validate_Params
  PUBLIC :: PH_Mat_Creep_Init

  !-----------------------------------------------------------------------------
  ! Constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CREEP_NORTON  = 1_i4  ! Norton power-law
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CREEP_NABARRO = 2_i4  ! Nabarro-Herring
  INTEGER(i4), PARAMETER :: PH_MAT_MAX_CREEP_ITER = 25_i4
  REAL(wp),    PARAMETER :: TOL_CREEP = 1.0E-10_wp
  REAL(wp),    PARAMETER :: PNEWDT_MIN = 0.25_wp

  !-----------------------------------------------------------------------------
  ! TYPE: PH_Creep_Props — Creep material properties
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Creep_Props
    INTEGER(i4) :: creep_type = PH_CREEP_NORTON  ! 1=Norton, 2=Nabarro
    !-- Elastic
    REAL(wp)    :: E     = 0.0_wp   ! Young's modulus [Pa]
    REAL(wp)    :: nu    = 0.0_wp   ! Poisson's ratio [-]
    !-- Norton parameters
    REAL(wp)    :: A_cr  = 0.0_wp   ! Creep coefficient [Pa^-n · s^-1]
    REAL(wp)    :: n_cr  = 1.0_wp   ! Stress exponent [-]
    REAL(wp)    :: Q_act = 0.0_wp   ! Activation energy [J/mol] (0 = isothermal)
    !-- Nabarro-Herring parameters
    REAL(wp)    :: B_nh  = 0.0_wp   ! Simplified Nabarro coefficient [Pa^-1·s^-1·m^2]
    REAL(wp)    :: d_grain = 1.0E-4_wp ! Grain size [m]
    !-- Temperature (for thermal activation)
    REAL(wp)    :: T_ref = 293.0_wp ! Reference temperature [K]
  END TYPE PH_Creep_Props

  !-----------------------------------------------------------------------------
  ! TYPE: PH_Creep_State — Integration point state variables
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Creep_State
    REAL(wp) :: stress(6)      = 0.0_wp  ! Cauchy stress [Pa]
    REAL(wp) :: strain_cr(6)   = 0.0_wp  ! Creep strain (Voigt) [-]
    REAL(wp) :: eps_cr_eq      = 0.0_wp  ! Equivalent creep strain [-]
    REAL(wp) :: creep_rate     = 0.0_wp  ! Current creep strain rate [s^-1]
    REAL(wp) :: C_tan(6,6)     = 0.0_wp  ! Algorithmic tangent [Pa]
  END TYPE PH_Creep_State

  !-- Gas constant for thermal activation
  REAL(wp), PARAMETER :: R_GAS = 8.314_wp  ! J/(mol·K)

CONTAINS

  !===========================================================================
  ! PH_Mat_Creep_Validate_Params — Validate creep parameters
  !===========================================================================
  SUBROUTINE PH_Mat_Creep_Validate_Params(props, ierr)
    TYPE(PH_Creep_Props),   INTENT(IN)  :: props
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL init_error_status(ierr)

    IF (props%E <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Creep]: E must be positive'
      RETURN
    END IF
    IF (props%nu <= -1.0_wp .OR. props%nu >= 0.5_wp) THEN
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Creep]: nu must be in (-1, 0.5)'
      RETURN
    END IF

    SELECT CASE (props%creep_type)
    CASE (PH_CREEP_NORTON)
      IF (props%A_cr <= 0.0_wp) THEN
        ierr%status_code = IF_STATUS_INVALID
        ierr%message = '[PH_Mat_Creep]: A_cr must be positive for Norton'
        RETURN
      END IF
      IF (props%n_cr <= 0.0_wp) THEN
        ierr%status_code = IF_STATUS_INVALID
        ierr%message = '[PH_Mat_Creep]: n_cr must be positive'
        RETURN
      END IF

    CASE (PH_CREEP_NABARRO)
      IF (props%B_nh <= 0.0_wp) THEN
        ierr%status_code = IF_STATUS_INVALID
        ierr%message = '[PH_Mat_Creep]: B_nh must be positive for Nabarro'
        RETURN
      END IF
      IF (props%d_grain <= 0.0_wp) THEN
        ierr%status_code = IF_STATUS_INVALID
        ierr%message = '[PH_Mat_Creep]: d_grain must be positive'
        RETURN
      END IF

    CASE DEFAULT
      ierr%status_code = IF_STATUS_INVALID
      ierr%message = '[PH_Mat_Creep]: Unknown creep_type (1=Norton, 2=Nabarro)'
      RETURN
    END SELECT

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Creep_Validate_Params

  !===========================================================================
  ! PH_Mat_Creep_Init — Initialize creep context
  !===========================================================================
  SUBROUTINE PH_Mat_Creep_Init(props, state, ierr)
    TYPE(PH_Creep_Props),   INTENT(IN)  :: props
    TYPE(PH_Creep_State),   INTENT(OUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    CALL PH_Mat_Creep_Validate_Params(props, ierr)
    IF (ierr%status_code /= IF_STATUS_OK) RETURN

    state%stress    = 0.0_wp
    state%strain_cr = 0.0_wp
    state%eps_cr_eq = 0.0_wp
    state%creep_rate = 0.0_wp
    state%C_tan     = 0.0_wp

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Creep_Init

  !===========================================================================
  ! PH_Mat_Creep_Compute_Stress — Implicit creep stress update
  !
  ! Algorithm (backward Euler):
  !   Trial: σ_trial = D_el : (ε_{n+1} - ε_cr_n)
  !   Residual: R = σ - [σ_trial - D_el : Δε_cr(σ)]
  !   Δε_cr = ε̇_cr(σ_eq) * dt * n_flow
  !   n_flow = (3/2) * s / σ_eq  (deviatoric flow direction)
  !
  ! For Norton: uses local Newton iteration on scalar equation
  !===========================================================================
  SUBROUTINE PH_Mat_Creep_Compute_Stress(props, strain_total, dt, T_curr, &
                                           state, stress, pnewdt, ierr)
    TYPE(PH_Creep_Props),   INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: strain_total(6) ! Total strain
    REAL(wp),               INTENT(IN)    :: dt              ! Time step [s]
    REAL(wp),               INTENT(IN)    :: T_curr          ! Current temp [K]
    TYPE(PH_Creep_State),   INTENT(INOUT) :: state
    REAL(wp),               INTENT(OUT)   :: stress(6)
    REAL(wp),               INTENT(INOUT) :: pnewdt          ! Time step control
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    ! Local
    REAL(wp) :: D_el(6,6)             ! Elastic stiffness
    REAL(wp) :: sigma_trial(6)        ! Trial stress
    REAL(wp) :: s_trial(6)            ! Trial deviatoric
    REAL(wp) :: p_mean                ! Hydrostatic pressure
    REAL(wp) :: q_trial               ! Trial Von Mises
    REAL(wp) :: lambda, mu, G         ! Elastic moduli
    REAL(wp) :: eps_cr_rate           ! Creep strain rate
    REAL(wp) :: d_eps_cr              ! Scalar creep increment
    REAL(wp) :: n_dir(6)              ! Flow direction
    REAL(wp) :: R_res, dR             ! Newton residual, Jacobian
    REAL(wp) :: q_corrected           ! Corrected Von Mises
    REAL(wp) :: T_factor              ! Thermal activation factor
    INTEGER(i4) :: i, j, iter

    CALL init_error_status(ierr)

    IF (dt <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_Creep]: dt must be positive'
      RETURN
    END IF

    ! Build elastic stiffness
    mu = props%E / (2.0_wp * (1.0_wp + props%nu))
    G  = mu
    lambda = props%E * props%nu / ((1.0_wp + props%nu) * (1.0_wp - 2.0_wp * props%nu))

    D_el = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        D_el(i,j) = lambda
      END DO
      D_el(i,i) = lambda + 2.0_wp * mu
    END DO
    D_el(4,4) = mu;  D_el(5,5) = mu;  D_el(6,6) = mu

    ! Trial stress (elastic predictor): σ_trial = D_el : (ε - ε_cr_n)
    sigma_trial = MATMUL(D_el, strain_total - state%strain_cr)

    ! Deviatoric decomposition
    p_mean = (sigma_trial(1) + sigma_trial(2) + sigma_trial(3)) / 3.0_wp
    s_trial = sigma_trial
    s_trial(1) = s_trial(1) - p_mean
    s_trial(2) = s_trial(2) - p_mean
    s_trial(3) = s_trial(3) - p_mean

    ! Von Mises: q = sqrt(3/2) * ||s||
    q_trial = SQRT(1.5_wp) * SQRT( &
        s_trial(1)**2 + s_trial(2)**2 + s_trial(3)**2 &
      + 2.0_wp * (s_trial(4)**2 + s_trial(5)**2 + s_trial(6)**2) )

    ! If stress is essentially zero, no creep
    IF (q_trial < 1.0E-20_wp) THEN
      stress = sigma_trial
      state%creep_rate = 0.0_wp
      ierr%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Flow direction: n = (3/2) * s / q
    n_dir = 1.5_wp * s_trial / q_trial

    ! Thermal activation factor
    T_factor = 1.0_wp
    IF (props%Q_act > 0.0_wp .AND. T_curr > 0.0_wp) THEN
      T_factor = EXP(-props%Q_act / (R_GAS * T_curr))
    END IF

    ! ---- Implicit backward Euler with local Newton ----
    ! Scalar equation: q_trial - 3G*Δε_cr - q(Δε_cr) = 0
    ! where q depends on creep law
    d_eps_cr = 0.0_wp

    DO iter = 1, PH_MAT_MAX_CREEP_ITER
      q_corrected = q_trial - 3.0_wp * G * d_eps_cr

      IF (q_corrected <= 0.0_wp) THEN
        d_eps_cr = q_trial / (3.0_wp * G)
        q_corrected = 0.0_wp
        EXIT
      END IF

      ! Creep strain rate at corrected stress
      CALL creep_rate_scalar(props, q_corrected, T_factor, eps_cr_rate)

      ! Residual: R = d_eps_cr - eps_cr_rate * dt
      R_res = d_eps_cr - eps_cr_rate * dt

      IF (ABS(R_res) < TOL_CREEP * MAX(q_trial / (3.0_wp * G), 1.0E-15_wp)) EXIT

      ! Jacobian: dR/d(d_eps_cr) = 1 + 3G * dt * d(eps_cr_rate)/dq
      CALL creep_rate_deriv(props, q_corrected, T_factor, dR)
      dR = 1.0_wp + 3.0_wp * G * dt * dR

      IF (ABS(dR) < 1.0E-30_wp) THEN
        ierr%status_code = IF_STATUS_ERROR
        ierr%message = '[PH_Mat_Creep]: Zero Jacobian in creep Newton'
        RETURN
      END IF

      d_eps_cr = d_eps_cr - R_res / dR
      IF (d_eps_cr < 0.0_wp) d_eps_cr = 0.0_wp
    END DO

    IF (iter > PH_MAT_MAX_CREEP_ITER) THEN
      ierr%status_code = IF_STATUS_ERROR
      ierr%message = '[PH_Mat_Creep]: Creep Newton did not converge'
      pnewdt = PNEWDT_MIN
      RETURN
    END IF

    ! Update stress: σ = σ_trial - 3G * d_eps_cr * n_dir / ||n_dir||_factor
    stress = sigma_trial
    DO i = 1, 6
      stress(i) = stress(i) - 2.0_wp * G * d_eps_cr * n_dir(i)
    END DO

    ! Update creep strain
    state%strain_cr = state%strain_cr + d_eps_cr * n_dir
    state%eps_cr_eq = state%eps_cr_eq + d_eps_cr
    state%creep_rate = eps_cr_rate

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Creep_Compute_Stress

  !===========================================================================
  ! PH_Mat_Creep_Compute_Tangent — Compute algorithmic creep tangent
  !
  ! C_tan = D_el - correction terms for creep flow
  ! C_tan = D_el - (4G² * dt * dε̇/dq) / (1 + 3G*dt*dε̇/dq) * n⊗n
  !       - (4G² * ε̇*dt / q) * (I_dev - n⊗n)   [if creep active]
  !===========================================================================
  SUBROUTINE PH_Mat_Creep_Compute_Tangent(props, dt, T_curr, state, &
                                            C_tangent, ierr)
    TYPE(PH_Creep_Props),   INTENT(IN)  :: props
    REAL(wp),               INTENT(IN)  :: dt
    REAL(wp),               INTENT(IN)  :: T_curr
    TYPE(PH_Creep_State),   INTENT(IN)  :: state
    REAL(wp),               INTENT(OUT) :: C_tangent(6,6)
    TYPE(ErrorStatusType),  INTENT(OUT) :: ierr

    ! Local
    REAL(wp) :: lambda, mu, G, K_bulk
    REAL(wp) :: sigma_eq, T_factor
    REAL(wp) :: de_dq          ! d(eps_cr_rate)/d(sigma_eq)
    REAL(wp) :: theta1, theta2
    REAL(wp) :: s_dev(6), n_dir(6)
    REAL(wp) :: p_mean
    INTEGER(i4) :: i, j

    CALL init_error_status(ierr)

    mu = props%E / (2.0_wp * (1.0_wp + props%nu))
    G  = mu
    lambda = props%E * props%nu / ((1.0_wp + props%nu) * (1.0_wp - 2.0_wp * props%nu))
    K_bulk = lambda + 2.0_wp * mu / 3.0_wp

    ! Build elastic tangent
    C_tangent = 0.0_wp
    DO i = 1, 3
      DO j = 1, 3
        C_tangent(i,j) = lambda
      END DO
      C_tangent(i,i) = C_tangent(i,i) + 2.0_wp * mu
    END DO
    C_tangent(4,4) = mu;  C_tangent(5,5) = mu;  C_tangent(6,6) = mu

    ! If no creep active, return elastic tangent
    IF (state%creep_rate < 1.0E-30_wp .OR. dt <= 0.0_wp) THEN
      ierr%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Compute Von Mises and flow direction from current stress
    p_mean = (state%stress(1) + state%stress(2) + state%stress(3)) / 3.0_wp
    s_dev = state%stress
    s_dev(1) = s_dev(1) - p_mean
    s_dev(2) = s_dev(2) - p_mean
    s_dev(3) = s_dev(3) - p_mean

    sigma_eq = SQRT(1.5_wp) * SQRT( &
        s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 &
      + 2.0_wp * (s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2) )

    IF (sigma_eq < 1.0E-20_wp) THEN
      ierr%status_code = IF_STATUS_OK
      RETURN
    END IF

    n_dir = 1.5_wp * s_dev / sigma_eq

    ! Thermal factor
    T_factor = 1.0_wp
    IF (props%Q_act > 0.0_wp .AND. T_curr > 0.0_wp) THEN
      T_factor = EXP(-props%Q_act / (R_GAS * T_curr))
    END IF

    ! Creep rate derivative
    CALL creep_rate_deriv(props, sigma_eq, T_factor, de_dq)

    ! Correction coefficients
    ! theta1 = 1 / (1 + 3G*dt*de_dq)  (flow direction correction)
    ! theta2 = state%creep_rate * dt / sigma_eq (deviatoric scaling)
    theta1 = 1.0_wp / (1.0_wp + 3.0_wp * G * dt * de_dq)
    theta2 = state%creep_rate * dt / sigma_eq

    ! Corrected tangent:
    ! C_tan(i,j) = K*I_vol + 2G*(1-theta2)*I_dev
    !            - 2G*(1-theta2 - theta1) * n⊗n
    C_tangent = 0.0_wp
    ! Volumetric
    DO i = 1, 3
      DO j = 1, 3
        C_tangent(i,j) = K_bulk
      END DO
    END DO
    ! Deviatoric with creep correction
    DO i = 1, 6
      C_tangent(i,i) = C_tangent(i,i) + 2.0_wp * G * (1.0_wp - theta2)
    END DO
    DO i = 1, 3
      DO j = 1, 3
        C_tangent(i,j) = C_tangent(i,j) - 2.0_wp * G * (1.0_wp - theta2) / 3.0_wp
      END DO
    END DO
    ! n⊗n correction
    DO i = 1, 6
      DO j = 1, 6
        C_tangent(i,j) = C_tangent(i,j) &
          - 2.0_wp * G * (1.0_wp - theta2 - theta1) * n_dir(i) * n_dir(j)
      END DO
    END DO

    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Creep_Compute_Tangent

  !===========================================================================
  ! PH_Mat_Creep_Update_State — Update state after convergence
  !===========================================================================
  SUBROUTINE PH_Mat_Creep_Update_State(props, stress, C_tangent, state, ierr)
    TYPE(PH_Creep_Props),   INTENT(IN)    :: props
    REAL(wp),               INTENT(IN)    :: stress(6)
    REAL(wp),               INTENT(IN)    :: C_tangent(6,6)
    TYPE(PH_Creep_State),   INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: ierr

    CALL init_error_status(ierr)
    state%stress = stress
    state%C_tan  = C_tangent
    ierr%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Creep_Update_State

  !===========================================================================
  ! PRIVATE: creep_rate_scalar — Compute scalar creep strain rate
  !===========================================================================
  SUBROUTINE creep_rate_scalar(props, sigma_eq, T_factor, eps_cr_rate)
    TYPE(PH_Creep_Props), INTENT(IN)  :: props
    REAL(wp),             INTENT(IN)  :: sigma_eq   ! Von Mises stress
    REAL(wp),             INTENT(IN)  :: T_factor   ! Thermal activation
    REAL(wp),             INTENT(OUT) :: eps_cr_rate ! Creep strain rate

    SELECT CASE (props%creep_type)
    CASE (PH_CREEP_NORTON)
      ! ε̇_cr = A * σ_eq^n * T_factor
      eps_cr_rate = props%A_cr * sigma_eq**props%n_cr * T_factor

    CASE (PH_CREEP_NABARRO)
      ! ε̇_cr = B * σ_eq / d² * T_factor
      eps_cr_rate = props%B_nh * sigma_eq / (props%d_grain**2) * T_factor

    CASE DEFAULT
      eps_cr_rate = 0.0_wp
    END SELECT

  END SUBROUTINE creep_rate_scalar

  !===========================================================================
  ! PRIVATE: creep_rate_deriv — d(eps_cr_rate)/d(sigma_eq)
  !===========================================================================
  SUBROUTINE creep_rate_deriv(props, sigma_eq, T_factor, deriv)
    TYPE(PH_Creep_Props), INTENT(IN)  :: props
    REAL(wp),             INTENT(IN)  :: sigma_eq
    REAL(wp),             INTENT(IN)  :: T_factor
    REAL(wp),             INTENT(OUT) :: deriv

    SELECT CASE (props%creep_type)
    CASE (PH_CREEP_NORTON)
      ! d/dσ [A * σ^n] = A * n * σ^(n-1)
      IF (sigma_eq > 1.0E-20_wp) THEN
        deriv = props%A_cr * props%n_cr * sigma_eq**(props%n_cr - 1.0_wp) * T_factor
      ELSE
        deriv = 0.0_wp
      END IF

    CASE (PH_CREEP_NABARRO)
      ! d/dσ [B * σ / d²] = B / d²
      deriv = props%B_nh / (props%d_grain**2) * T_factor

    CASE DEFAULT
      deriv = 0.0_wp
    END SELECT

  END SUBROUTINE creep_rate_deriv

END MODULE PH_Mat_Creep_Core
