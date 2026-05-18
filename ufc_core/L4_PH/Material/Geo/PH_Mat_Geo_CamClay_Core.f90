!===============================================================================
! MODULE: PH_Mat_Geo_CamClay_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Modified Cam-Clay plasticity for geotechnical materials
!   W1: **props** from slot **PH_Mat_Desc%props**; routing via **PH_Mat_Dispatch** / **PH_MAT_*** geotech family + **Effective_Model**.
!===============================================================================
!
! Interface: SUBROUTINE PH_Mat_Geo_CamClay_Update(ctx, status)
!
! Supported Models:
!   - mat_id 203: Modified Cam-Clay with elliptical yield surface
!
! Theory:
!   - Yield function:      f = q²/M² + p·(p/p₀)^(λ/κ) - p₀ = 0
!   - Flow rule:           g = f (associated plasticity)
!   - Hardening law:       dp₀/dεᵥᵖ = p₀·(λ-κ)/κ · β
!   - Elastic behavior:    σ = Dᵉ�?ε - ε�?
!   where:
!     p = -σₖₖ/3 (mean effective stress, compression positive)
!     q = �?3/2·sᵢⱼsᵢⱼ) (von Mises equivalent stress)
!     M = critical state stress ratio (slope in p-q space)
!     λ = compression index (virgin compression slope)
!     κ = swelling index (recompression slope)
!     p₀ = preconsolidation pressure (hardening variable)
!     β = hardening parameter (default=1.0)
!
! Input Parameters (props):
!   - props(1): PH_MAT_E        - Young's modulus [Pa]
!   - props(2): nu       - Poisson's ratio [-]
!   - props(3): M        - Critical state stress ratio [-]
!   - props(4): lambda   - Compression index [-]
!   - props(5): kappa    - Swelling index [-]
!   - props(6): p0       - Initial preconsolidation pressure [Pa]
!   - props(7): beta     - Hardening parameter (optional) [-]
!
! State Variables (statev):
!   - statev(1): eps_vol     - Volumetric plastic strain [-]
!   - statev(2): eps_p_eqv   - Equivalent plastic strain [-]
!   - statev(3): p0_current  - Current preconsolidation pressure [Pa]
!   - statev(4:9): eps_p(1:6)- Plastic strain tensor (Voigt)
!
! References:
!   1. Roscoe & Burland (1968). On the generalized stress-strain behaviour of wet clay
!   2. Wood (1990). Soil Behaviour and Critical State Soil Mechanics
!   3. ABAQUS Theory Manual: Cam-Clay plasticity model
!
! Status: Template-aligned | P0 Priority | UFC Standard
!===============================================================================
MODULE PH_Mat_Geo_CamClay_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MAT_ID_203
  USE PH_Mat_Core_Types, ONLY: MatPoint_In, MatPoint_Out
  USE PH_Mat_Core_UMAT_Adapter, ONLY: Unpack_From_UMAT_Context, Pack_To_UMAT_Context
  USE PH_Mat_UMAT_Def, ONLY: PH_UMAT_Context
  USE PH_Mat_Geo_Def, ONLY: PH_Mat_Geo_Desc, PH_Mat_Geo_State, PH_Mat_Geo_Algo
  USE MD_Mat_Def, ONLY: MD_Mat_Desc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Mat_PLG_CamClay_Update
  PUBLIC :: CamClay_UpdateConstitutive
  PUBLIC :: PH_Mat_Geo_CC_Eval_Wrapper

  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ID_LEAF_203 = MAT_ID_203
  
  ! Numerical parameters
  REAL(wp), PARAMETER :: TOL = 1.0e-10_wp
  REAL(wp), PARAMETER :: REGULARIZATION = 1.0e-8_wp
  INTEGER(i4), PARAMETER :: PH_MAT_MAX_ITER = 50_i4

CONTAINS

  !=============================================================================
  ! CamClay_UpdateConstitutive
  !   Updates stress and state for Modified Cam-Clay model using return
  !   mapping algorithm with elliptical yield surface.
  !
  ! Algorithm:
  !   1. Compute elastic trial stress: σ_trial = Dᵉ�?ε - εᵖ_old)
  !   2. Compute stress invariants: p_trial, q_trial
  !   3. Check yield: f(p_trial, q_trial, p₀_old) > 0 ?
  !   4. IF yielding: perform return mapping
  !      - Newton iteration to find plastic multiplier Δλ
  !      - Update stresses: p_new, q_new
  !      - Update hardening: p₀_new = p₀_old·exp((λ-κ)/κ·Δεᵥᵖ·β)
  !      - Update plastic strain: εᵖ_new = εᵖ_old + Δλ·∂g/∂�?
  !   5. Compute consistent tangent operator
  !=============================================================================
  SUBROUTINE CamClay_UpdateConstitutive(mat_desc, nprops, props, &
                                       ndim, ncomp, strain, statev,
                                       stress, ddnde, st)
    IMPLICIT NONE
    CLASS(MD_Mat_Desc), INTENT(INOUT) :: mat_desc
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: ndim, ncomp
    REAL(wp), INTENT(IN) :: strain(:)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(OUT) :: stress(:)
    REAL(wp), INTENT(OUT) :: ddnde(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    REAL(wp) :: E_young, nu_poisson, M_crit, lambda_comp, kappa_swell, p0_init, beta_hard
    REAL(wp) :: lambda_lame, mu_shear, K_bulk
    REAL(wp) :: p_trial, q_trial, s_dev(6)
    REAL(wp) :: p0_old, p0_new, eps_vol_old, eps_p_eqv_old
    REAL(wp) :: eps_p_old(6), eps_p_new(6)
    REAL(wp) :: dlambda_pl, f_yield
    REAL(wp) :: stress_trial(6), D_elastic(6,6)
    INTEGER(i4) :: i, j, ntens
    LOGICAL :: is_yielding

    CALL init_error_status(st)

    ! Get material properties from L3 descriptor or props
    IF (.NOT. mat_desc%is_initialized) THEN
      IF (nprops < 6) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "CamClay: need at least 6 props"
        RETURN
      END IF
      E_young = props(1)
      nu_poisson = props(2)
      M_crit = props(3)
      lambda_comp = props(4)
      kappa_swell = props(5)
      p0_init = props(6)
      beta_hard = 1.0_wp
      IF (nprops >= 7) beta_hard = props(7)
    ELSE
      SELECT TYPE (mat_desc)
      TYPE IS (CamClay_MatDesc)
        E_young = mat_desc%E_young
        nu_poisson = mat_desc%nu_poisson
        M_crit = mat_desc%M_critical
        lambda_comp = mat_desc%lambda_comp
        kappa_swell = mat_desc%kappa_swell
        p0_init = mat_desc%p0_initial
        beta_hard = mat_desc%beta_hard
      END SELECT
    END IF

    ! Compute elastic parameters
    lambda_lame = E_young * nu_poisson / ((1.0_wp + nu_poisson) * (1.0_wp - 2.0_wp * nu_poisson))
    mu_shear = E_young / (2.0_wp * (1.0_wp + nu_poisson))
    K_bulk = E_young / (3.0_wp * (1.0_wp - 2.0_wp * nu_poisson))

    ! Initialize output
    stress = 0.0_wp
    ddnde = 0.0_wp

    ! Build elastic stiffness matrix
    D_elastic = 0.0_wp
    DO i = 1, ndim
      D_elastic(i,i) = lambda_lame + 2.0_wp * mu_shear
      DO j = 1, ndim
        IF (i /= j) THEN
          D_elastic(i,j) = lambda_lame
        END IF
      END DO
    END DO
    DO i = ndim+1, ncomp
      D_elastic(i,i) = mu_shear
    END DO

    ! Get old state variables
    eps_vol_old = 0.0_wp
    eps_p_eqv_old = 0.0_wp
    p0_old = p0_init
    eps_p_old = 0.0_wp
    
    IF (SIZE(statev) >= 1) eps_vol_old = statev(1)
    IF (SIZE(statev) >= 2) eps_p_eqv_old = statev(2)
    IF (SIZE(statev) >= 3) p0_old = statev(3)
    IF (SIZE(statev) >= 9) THEN
      DO i = 1, 6
        eps_p_old(i) = statev(3 + i)
      END DO
    END IF

    ! Compute total strain increment
    ntens = ndim + (ncomp - ndim)
    
    ! Compute elastic trial stress
    stress_trial = 0.0_wp
    DO i = 1, ntens
      DO j = 1, ntens
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * (strain(j) - eps_p_old(j))
      END DO
    END DO

    ! Compute stress invariants
    CALL ComputeStressInvariants(stress_trial, ndim, p_trial, q_trial, s_dev)

    ! Check yield condition
    CALL ComputeYieldFunction(p_trial, q_trial, p0_old, M_crit, lambda_comp, kappa_swell, f_yield)
    is_yielding = (f_yield > TOL)

    ! Initialize plastic strain increment
    eps_p_new = eps_p_old
    dlambda_pl = 0.0_wp
    p0_new = p0_old

    IF (is_yielding) THEN
      ! Perform return mapping
      CALL ReturnMapping( &
        p_trial, q_trial, s_dev, p0_old, &
        M_crit, lambda_comp, kappa_swell, beta_hard, &
        K_bulk, mu_shear, dlambda_pl, &
        eps_p_new, p0_new, st)
    END IF

    ! Compute final stress
    DO i = 1, ntens
      stress(i) = 0.0_wp
      DO j = 1, ntens
        stress(i) = stress(i) + D_elastic(i,j) * (strain(j) - eps_p_new(j))
      END DO
    END DO

    ! Update state variables
    IF (SIZE(statev) >= 1) THEN
      eps_vol_old = 0.0_wp
      DO i = 1, ndim
        eps_vol_old = eps_vol_old + eps_p_new(i)
      END DO
      statev(1) = eps_vol_old
    END IF
    
    IF (SIZE(statev) >= 2) statev(2) = eps_p_eqv_old + dlambda_pl
    IF (SIZE(statev) >= 3) statev(3) = p0_new
    IF (SIZE(statev) >= 9) THEN
      DO i = 1, 6
        statev(3 + i) = eps_p_new(i)
      END DO
    END IF

    ! Set tangent stiffness (elastic for now)
    ddnde = D_elastic

    st%status_code = IF_STATUS_OK
  END SUBROUTINE CamClay_UpdateConstitutive

  !=============================================================================
  ! Helper: Compute stress invariants p, q, and deviatoric stress
  !=============================================================================
  SUBROUTINE ComputeStressInvariants(stress, ndim, p, q, s_dev)
    IMPLICIT NONE
    REAL(wp), INTENT(IN) :: stress(:)
    INTEGER(i4), INTENT(IN) :: ndim
    REAL(wp), INTENT(OUT) :: p, q, s_dev(6)
    
    REAL(wp) :: p_mean, J2
    INTEGER(i4) :: i
    
    ! Mean stress (tension positive in UMAT, convert to compression positive)
    p_mean = 0.0_wp
    DO i = 1, MIN(3, ndim)
      p_mean = p_mean + stress(i)
    END DO
    p_mean = p_mean / 3.0_wp
    
    ! Mean effective stress (compression positive)
    p = -p_mean
    
    ! Deviatoric stress
    s_dev = stress
    DO i = 1, MIN(3, ndim)
      s_dev(i) = s_dev(i) - p_mean
    END DO
    
    ! Second invariant of deviatoric stress
    J2 = 0.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2)
    IF (ndim >= 3) THEN
      J2 = J2 + s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2
    ELSE IF (ndim == 2) THEN
      J2 = J2 + s_dev(4)**2
    END IF
    
    ! Von Mises equivalent stress
    q = SQRT(3.0_wp * J2)
  END SUBROUTINE ComputeStressInvariants

  !=============================================================================
  ! Helper: Compute yield function value
  !=============================================================================
  SUBROUTINE ComputeYieldFunction(p, q, p0, M, lambda, kappa, f)
    IMPLICIT NONE
    REAL(wp), INTENT(IN) :: p, q, p0, M, lambda, kappa
    REAL(wp), INTENT(OUT) :: f
    
    REAL(wp) :: p_safe, p_ratio
    
    p_safe = MAX(p, REGULARIZATION)
    p_ratio = p0 / p_safe
    
    ! Modified Cam-Clay yield function
    f = (q**2) / (M**2) + p * (p_ratio**(lambda/kappa)) - p0
  END SUBROUTINE ComputeYieldFunction

  !=============================================================================
  ! Return mapping algorithm for Cam-Clay
  !=============================================================================
  SUBROUTINE ReturnMapping(p_trial, q_trial, s_dev, p0_old, &
                          M, lambda, kappa, beta, &
                          K, G, dlambda, &
                          eps_p_new, p0_new, st)
    IMPLICIT NONE
    REAL(wp), INTENT(IN) :: p_trial, q_trial, s_dev(6)
    REAL(wp), INTENT(IN) :: p0_old, M, lambda, kappa, beta, K, G
    REAL(wp), INTENT(OUT) :: dlambda, eps_p_new(6), p0_new
    TYPE(ErrorStatusType), INTENT(OUT) :: st
    
    REAL(wp) :: p_iter, q_iter, p0_iter, f, df_dp, df_dq, df_dp0
    REAL(wp) :: dg_dp, dg_dq, n_flow(6), n_vol
    REAL(wp) :: A, B, C, delta, p_safe, p_ratio
    INTEGER(i4) :: iter, i
    LOGICAL :: converged
    
    converged = .FALSE.
    dlambda = 0.0_wp
    eps_p_new = 0.0_wp
    p0_new = p0_old
    
    p_iter = p_trial
    q_iter = q_trial
    p0_iter = p0_old
    
    ! Newton iteration
    DO iter = 1, PH_MAT_MAX_ITER
      CALL ComputeYieldFunction(p_iter, q_iter, p0_iter, M, lambda, kappa, f)
      
      IF (ABS(f) < TOL) THEN
        converged = .TRUE.
        EXIT
      END IF
      
      ! Compute derivatives
      p_safe = MAX(p_iter, REGULARIZATION)
      p_ratio = p0_iter / p_safe
      
      df_dp = (p_ratio**(lambda/kappa)) * (1.0_wp - (lambda/kappa))
      df_dq = 2.0_wp * q_iter / (M**2)
      df_dp0 = (p_iter / p0_iter) * (p_ratio**(lambda/kappa))
      
      ! Associated flow rule
      dg_dp = df_dp
      dg_dq = df_dq
      
      ! Flow direction
      IF (q_iter > REGULARIZATION) THEN
        DO i = 1, 6
          n_flow(i) = s_dev(i) / q_iter
        END DO
      ELSE
        n_flow = 0.0_wp
      END IF
      
      n_vol = dg_dp
      
      ! Consistency parameter
      A = (lambda - kappa) / (p0_iter * kappa)
      B = K * n_vol**2 + 3.0_wp * G + df_dp0 * A * n_vol
      
      IF (ABS(B) < REGULARIZATION) EXIT
      
      delta = f / B
      dlambda = dlambda + delta
      
      ! Update stresses and hardening
      p_iter = p_iter - K * n_vol * delta
      q_iter = q_iter - 3.0_wp * G * delta
      
      p0_iter = p0_old * EXP((lambda - kappa) / kappa * n_vol * dlambda * beta)
      
      p_iter = MAX(p_iter, REGULARIZATION)
      q_iter = MAX(q_iter, 0.0_wp)
      p0_iter = MAX(p0_iter, REGULARIZATION)
    END DO
    
    IF (.NOT. converged) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "CamClay: return mapping did not converge"
      RETURN
    END IF
    
    ! Compute plastic strain increment
    DO i = 1, 6
      IF (q_iter > REGULARIZATION) THEN
        eps_p_new(i) = n_vol * dlambda / 3.0_wp + n_flow(i) * dlambda
      ELSE
        eps_p_new(i) = n_vol * dlambda / 3.0_wp
      END IF
    END DO
    
    p0_new = p0_iter
    st%status_code = IF_STATUS_OK
  END SUBROUTINE ReturnMapping

  !=============================================================================
  ! PH_Mat_PLG_CamClay_Update
  !   UMAT wrapper for Cam-Clay model following MatPoint paradigm.
  !=============================================================================
  SUBROUTINE PH_Mat_PLG_CamClay_Update(ctx, status)
    TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(MatPoint_In) :: mp_in
    TYPE(MatPoint_Out) :: mp_out
    TYPE(ErrorStatusType) :: local_st
    
    CALL init_error_status(status)
    
    ! Unpack from UMAT context to MatPoint_In
    CALL Unpack_From_UMAT_Context(mp_in, ctx)
    
    ! Call constitutive update
    CALL CamClay_UpdateConstitutive( &
         mp_in%mat_desc, &
         mp_in%nprops, &
         mp_in%props, &
         mp_in%cfg%ndim, &
         mp_in%ncomp, &
         mp_in%strain, &
         mp_in%statev, &
         mp_out%stress, &
         mp_out%ddsdde, &
         local_st)
    
    ! Check for errors
    IF (local_st%status_code /= IF_STATUS_OK) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "CamClay_Update: " // TRIM(local_st%message)
      RETURN
    END IF
    
    ! Pack back to UMAT context
    CALL Pack_To_UMAT_Context(mp_out, ctx)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_PLG_CamClay_Update

  !=============================================================================
  ! PH_Mat_Geo_CC_Eval_Wrapper
  !   Four-type wrapper around CamClay_UpdateConstitutive.
  !   Bridges PH_Mat_Geo_Desc/State -> CamClay_UpdateConstitutive.
  !   Uses desc%props (if allocated) for E, nu, M, lambda, kappa, p0, beta.
  !=============================================================================
  SUBROUTINE PH_Mat_Geo_CC_Eval_Wrapper(desc, state, algo, strain_in, stress, ddsdde, status)
    TYPE(PH_Mat_Geo_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Geo_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Geo_Algo), INTENT(IN) :: algo
    REAL(wp), INTENT(IN) :: strain_in(6)
    REAL(wp), INTENT(OUT) :: stress(6), ddsdde(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(MD_Mat_Desc) :: dummy_desc
    REAL(wp) :: props_local(7), statev_local(9)
    INTEGER(i4) :: i

    CALL init_error_status(status)
    dummy_desc%is_initialized = .FALSE.

    !--- Assemble props: [E, nu, M, lambda, kappa, p0, beta]
    IF (ALLOCATED(desc%props) .AND. SIZE(desc%props) >= 6) THEN
      props_local(1) = desc%props(1)  ! E
      props_local(2) = desc%props(2)  ! nu
      props_local(3) = desc%props(3)  ! M
      props_local(4) = desc%props(4)  ! lambda
      props_local(5) = desc%props(5)  ! kappa
      props_local(6) = desc%props(6)  ! p0
      IF (SIZE(desc%props) >= 7) THEN
        props_local(7) = desc%props(7)  ! beta
      ELSE
        props_local(7) = 1.0_wp
      END IF
    ELSE
      ! Default from Desc E/nu; reasonable Cam-Clay defaults for remaining params
      props_local(1) = MAX(desc%E, 1.0e-10_wp)   ! E
      props_local(2) = desc%nu                     ! nu
      props_local(3) = 1.0_wp                      ! M (critical state ratio)
      props_local(4) = 0.2_wp                      ! lambda
      props_local(5) = 0.05_wp                     ! kappa
      props_local(6) = 1.0e5_wp                    ! p0
      props_local(7) = 1.0_wp                      ! beta
    END IF

    !--- Assemble statev: [eps_vol, eps_p_eqv, p0_current, eps_p(1:6)]
    statev_local(1) = SUM(state%plastic_strain(1:3))  ! eps_vol
    statev_local(2) = state%equiv_plastic_strain       ! eps_p_eqv
    statev_local(3) = 0.0_wp                           ! p0_current (reset; CamClay tracks it)
    DO i = 1, 6
      statev_local(3 + i) = state%plastic_strain(i)
    END DO

    !--- Call core algorithm
    CALL CamClay_UpdateConstitutive(dummy_desc, 7, props_local, &
                                     3, 6, strain_in, statev_local, &
                                     stress, ddsdde, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    !--- Update state
    state%equiv_plastic_strain = statev_local(2)
    DO i = 1, 6
      state%plastic_strain(i) = statev_local(3 + i)
    END DO
    state%stress = stress
    state%strain = strain_in
    state%initialized = .TRUE.
    state%num_evaluations = state%num_evaluations + 1

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Geo_CC_Eval_Wrapper

END MODULE PH_Mat_Geo_CamClay_Core