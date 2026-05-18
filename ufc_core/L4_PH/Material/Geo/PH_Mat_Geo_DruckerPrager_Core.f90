!===============================================================================
! MODULE: PH_Mat_Geo_DruckerPrager_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Drucker-Prager plasticity for pressure-dependent geomaterials
!   W1: parameters from **desc%props**; family routing consistent with **PH_Mat_Reg** / **PH_Mat_Dispatch**.
!===============================================================================
!
! Interface: SUBROUTINE PH_Mat_Geo_DruckerPrager_Update(ctx, status)
!
! Supported Models:
!   - mat_id 202: Drucker-Prager Plasticity
!
! Theory:
!   - Yield function:      f = �?3J�? + α·I�?- k = 0
!   - Flow potential:      g = �?3J�? + β·I�?(non-associated when β �?α)
!   - Hardening:           k = k₀ + H·ε̃^p
!   where:
!     I�?= tr(σ) (first invariant)
!     J�?= 1/2·sᵢⱼsᵢⱼ (second invariant of deviatoric stress)
!     α = friction parameter, k = cohesion, H = hardening modulus
!     β = dilation parameter (β = α for associated flow)
!
! Input Parameters (props):
!   - props(1): PH_MAT_E        - Young's modulus [Pa]
!   - props(2): nu       - Poisson's ratio [-]
!   - props(3): alpha    - Friction parameter α [-]
!   - props(4): k0       - Initial cohesion k₀ [Pa]
!   - props(5): H        - Hardening modulus [Pa] (optional)
!   - props(6): beta     - Dilation parameter β [-] (optional)
!
! State Variables (statev):
!   - statev(1): eps_p_eqv    - Equivalent plastic strain [-]
!   - statev(2): plastic_work - Plastic work density [J/m³]
!   - statev(3:8): eps_p(1:6) - Plastic strain tensor [-]
!
! References:
!   1. Chen & Han (1988). Plasticity for Structural Engineers
!   2. Drucker & Prager (1952). Soil mechanics and plastic analysis
!
! Status: Template-aligned | P0 Priority | UFC Standard
!===============================================================================
MODULE PH_Mat_Geo_DruckerPrager_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_INVALID, init_error_status
  USE MD_Mat_Ids, ONLY: MAT_ID_202
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, DP_MatDesc
  USE PH_Mat_Core_Types, ONLY: MatPoint_In, MatPoint_Out
  USE PH_Mat_Core_UMAT_Adapter, ONLY: Unpack_From_UMAT_Context, Pack_To_UMAT_Context
  USE PH_Mat_UMAT_Def, ONLY: PH_UMAT_Context
  IMPLICIT NONE
  PRIVATE
  
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ID_LEAF_202 = MAT_ID_202
  PUBLIC :: PH_Mat_PLG_DruckerPrager_Update
  PUBLIC :: DP_UpdateConstitutive

  ! Numerical parameters
  REAL(wp), PARAMETER :: TOL = 1.0e-10_wp
  REAL(wp), PARAMETER :: REGULARIZATION = 1.0e-12_wp
  INTEGER(i4), PARAMETER :: PH_MAT_MAX_ITER = 50_i4

CONTAINS

  !=============================================================================
  ! DP_UpdateConstitutive
  !   Updates stress and state for Drucker-Prager model using return mapping.
  !
  ! Algorithm:
  !   1. Compute elastic trial stress: σ_trial = D₀·(ε - ε^pl_old)
  !   2. Compute invariants: I�? �?3J�?
  !   3. Check yield: f = �?3J�? + α·I�?- k > 0 ?
  !   4. IF yielding: perform return mapping
  !      - Update plastic strain: ε^pl_new = ε^pl_old + Δλ·∂g/∂�?
  !      - Update hardening: k_new = k₀ + H·ε̃^p_new
  !   5. Compute consistent tangent (optional)
  !=============================================================================
  SUBROUTINE DP_UpdateConstitutive(mat_desc, nprops, props, &
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

    REAL(wp) :: E_young, nu_poisson, alpha, k0, H, beta
    REAL(wp) :: lambda_lame, mu_shear, K_bulk
    REAL(wp) :: stress_trial(6), D_elastic(6,6)
    REAL(wp) :: I1_trial, sqrt_J2_trial, f_yield
    REAL(wp) :: dlambda, k_current, eps_p_eqv_old
    REAL(wp) :: s_dev(6), eps_p_old(6)
    REAL(wp) :: df_dI1, df_dsqrtJ2, dg_dI1, dg_dsqrtJ2
    REAL(wp) :: denominator, residual
    INTEGER(i4) :: i, j, ntens, iter
    LOGICAL :: converged

    CALL init_error_status(st)

    ! Get material properties from L3 descriptor or props
    IF (.NOT. mat_desc%is_initialized) THEN
      IF (nprops < 4) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "DP: need at least 4 props (PH_MAT_E,nu,alpha,k0)"
        RETURN
      END IF
      E_young = props(1)
      nu_poisson = props(2)
      alpha = props(3)
      k0 = props(4)
      H = 0.0_wp
      IF (nprops >= 5) H = props(5)
      beta = alpha
      IF (nprops >= 6) beta = props(6)
    ELSE
      SELECT TYPE (mat_desc)
      TYPE IS (DP_MatDesc)
        E_young = mat_desc%E_young
        nu_poisson = mat_desc%nu_poisson
        alpha = mat_desc%alpha_friction
        k0 = mat_desc%k0_cohesion
        H = mat_desc%H_hardening
        beta = mat_desc%beta_dilation
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
    eps_p_eqv_old = 0.0_wp
    eps_p_old = 0.0_wp
    
    IF (SIZE(statev) >= 1) eps_p_eqv_old = statev(1)
    IF (SIZE(statev) >= 2) THEN
      ! plastic_work is not used in calculation, skip
    END IF
    IF (SIZE(statev) >= 8) THEN
      eps_p_old(1:6) = statev(3:8)
    END IF

    ! Compute total strain
    ntens = ndim + (ncomp - ndim)
    
    ! Compute elastic trial stress (effective stress)
    stress_trial = 0.0_wp
    DO i = 1, ntens
      DO j = 1, ntens
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * (strain(j) - eps_p_old(j))
      END DO
    END DO

    ! Compute stress invariants
    I1_trial = stress_trial(1) + stress_trial(2) + stress_trial(3)
    
    s_dev = stress_trial
    s_dev(1) = stress_trial(1) - I1_trial / 3.0_wp
    s_dev(2) = stress_trial(2) - I1_trial / 3.0_wp
    s_dev(3) = stress_trial(3) - I1_trial / 3.0_wp
    s_dev(4:6) = stress_trial(4:6)
    
    sqrt_J2_trial = SQRT(0.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2) + &
                          s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)

    ! Compute current cohesion
    k_current = k0 + H * eps_p_eqv_old

    ! Evaluate yield function
    f_yield = sqrt_J2_trial + alpha * I1_trial - k_current

    ! Check for yielding
    IF (f_yield > TOL) THEN
      ! Plastic return mapping (Newton iteration)
      dlambda = 0.0_wp
      converged = .FALSE.
      
      DO iter = 1, PH_MAT_MAX_ITER
        ! Residual
        residual = sqrt_J2_trial - 3.0_wp * mu_shear * dlambda + &
                   alpha * (I1_trial - 9.0_wp * K_bulk * alpha * dlambda) - &
                   (k0 + H * (eps_p_eqv_old + dlambda))
        
        IF (ABS(residual) < TOL) THEN
          converged = .TRUE.
          EXIT
        END IF
        
        ! Tangent stiffness
        denominator = 3.0_wp * mu_shear + 9.0_wp * K_bulk * alpha**2 + H
        
        IF (ABS(denominator) < REGULARIZATION) EXIT
        
        ! Newton update
        dlambda = dlambda - residual / denominator
        dlambda = MAX(dlambda, 0.0_wp)
      END DO

      ! If Newton didn't converge, use explicit update
      IF (.NOT. converged) THEN
        denominator = 3.0_wp * mu_shear + 9.0_wp * K_bulk * alpha**2 + H
        IF (ABS(denominator) > REGULARIZATION) THEN
          dlambda = f_yield / denominator
          dlambda = MAX(dlambda, 0.0_wp)
        END IF
      END IF

      ! Update stress
      IF (sqrt_J2_trial > REGULARIZATION) THEN
        DO i = 1, 3
          stress(i) = I1_trial / 3.0_wp - 3.0_wp * K_bulk * alpha * dlambda + &
                      s_dev(i) * (sqrt_J2_trial - 3.0_wp * mu_shear * dlambda) / sqrt_J2_trial
        END DO
        DO i = 4, 6
          stress(i) = s_dev(i) * (sqrt_J2_trial - 3.0_wp * mu_shear * dlambda) / sqrt_J2_trial
        END DO
      ELSE
        stress = stress_trial - 9.0_wp * K_bulk * alpha * dlambda / 3.0_wp
      END IF

      ! Update plastic strain (non-associated flow)
      df_dI1 = alpha
      df_dsqrtJ2 = 1.0_wp
      dg_dI1 = beta
      dg_dsqrtJ2 = 1.0_wp
      
      IF (sqrt_J2_trial > REGULARIZATION) THEN
        DO i = 1, 3
          eps_p_old(i) = eps_p_old(i) + dlambda * ( &
            dg_dI1 + dg_dsqrtJ2 * s_dev(i) / (2.0_wp * sqrt_J2_trial))
        END DO
        DO i = 4, 6
          eps_p_old(i) = eps_p_old(i) + dlambda * dg_dsqrtJ2 * s_dev(i) / sqrt_J2_trial
        END DO
      ELSE
        DO i = 1, ntens
          eps_p_old(i) = eps_p_old(i) + dlambda * dg_dI1
        END DO
      END IF

      ! Update equivalent plastic strain
      eps_p_eqv_old = eps_p_eqv_old + dlambda

      ! Set tangent stiffness (consistent tangent for plastic loading)
      CALL DP_ConsistentTangent(D_elastic, K_bulk, mu_shear, alpha, beta, H, &
                                sqrt_J2_trial, dlambda, ntens, ddnde)
    ELSE
      ! Elastic state
      stress = stress_trial
      
      ! Elastic tangent
      DO i = 1, ntens
        DO j = 1, ntens
          ddnde(i,j) = D_elastic(i,j)
        END DO
      END DO
    END IF

    ! Update state variables
    IF (SIZE(statev) >= 1) statev(1) = eps_p_eqv_old
    IF (SIZE(statev) >= 2) statev(2) = statev(2) + 0.5_wp * DOT_PRODUCT(stress, strain)
    IF (SIZE(statev) >= 8) statev(3:8) = eps_p_old(1:6)

    st%status_code = IF_STATUS_OK
  END SUBROUTINE DP_UpdateConstitutive

  !=============================================================================
  ! Helper: Consistent tangent for Drucker-Prager
  !=============================================================================
  SUBROUTINE DP_ConsistentTangent(D_e, K, mu, alpha, beta, H, sqrt_J2, dlambda, ntens, D_ep)
    IMPLICIT NONE
    REAL(wp), INTENT(IN) :: D_e(:,:), K, mu, alpha, beta, H, sqrt_J2, dlambda
    INTEGER(i4), INTENT(IN) :: ntens
    REAL(wp), INTENT(OUT) :: D_ep(:,:)
    
    REAL(wp) :: denominator, theta
    INTEGER(i4) :: i, j
    
    D_ep = D_e
    
    IF (dlambda <= 0.0_wp .OR. sqrt_J2 < 1.0e-30_wp) RETURN
    
    denominator = 3.0_wp * mu + 9.0_wp * K * alpha**2 + H
    
    IF (ABS(denominator) < 1.0e-30_wp) RETURN
    
    theta = 1.0_wp / denominator
    
    ! Simplified consistent tangent (diagonal approximation)
    DO i = 1, ntens
      DO j = 1, ntens
        IF (i <= 3 .AND. j <= 3) THEN
          D_ep(i,j) = D_ep(i,j) - 9.0_wp * K**2 * alpha * beta * theta
        END IF
        IF (i > 3 .OR. j > 3) THEN
          IF (i == j) THEN
            D_ep(i,j) = D_ep(i,j) - 3.0_wp * mu**2 * theta / sqrt_J2
          END IF
        END IF
      END DO
    END DO
  END SUBROUTINE DP_ConsistentTangent

  !=============================================================================
  ! PH_Mat_PLG_DruckerPrager_Update
  !   UMAT wrapper for Drucker-Prager model following MatPoint paradigm.
  !=============================================================================
  SUBROUTINE PH_Mat_PLG_DruckerPrager_Update(ctx, status)
    TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    TYPE(MatPoint_In) :: mp_in
    TYPE(MatPoint_Out) :: mp_out
    TYPE(ErrorStatusType) :: local_st
    
    CALL init_error_status(status)
    
    ! Unpack from UMAT context to MatPoint_In
    CALL Unpack_From_UMAT_Context(mp_in, ctx)
    
    ! Call constitutive update
    CALL DP_UpdateConstitutive( &
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
      status%message = "DP_Update: " // TRIM(local_st%message)
      RETURN
    END IF
    
    ! Pack back to UMAT context
    CALL Pack_To_UMAT_Context(mp_out, ctx)
    
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_PLG_DruckerPrager_Update

END MODULE PH_Mat_Geo_DruckerPrager_Core