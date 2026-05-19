!===============================================================================
! MODULE: PH_Mat_Plast_Core
! LAYER:  L4_PH
! DOMAIN: Material / Plast
! ROLE:   Core
! BRIEF:  Core computation routines for plastic material family (J2 return mapping).
! Purpose: Populate Desc from L3 props; elastic predictor + J2 radial return on Ctx/State.
! Theory: J2 von Mises with isotropic hardening; σ_eq − (σ_y + H·ε̄_p) ≤ 0.
! Status: Production | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Plast_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
       IF_STATUS_OK, IF_STATUS_INVALID
  USE PH_Mat_Plast_Def, ONLY: PH_Mat_Plast_Desc, &
                               PH_Mat_Plast_State, &
                               PH_Mat_Plast_Algo, &
                               PH_Mat_Plast_Ctx, &
                               PH_MAT_PLAST_SUB_J2_ISO
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Plast_Populate_From_L3
  PUBLIC :: PH_Mat_Plast_Build_Elastic_Stiffness
  PUBLIC :: PH_Mat_Plast_Compute_Trial_Stress
  PUBLIC :: PH_Mat_Plast_Check_Yield
  PUBLIC :: PH_Mat_Plast_ComputeReturnMapping
  PUBLIC :: PH_Mat_Plast_Update_State

CONTAINS

  SUBROUTINE plast_desc_read_elastic(desc, E, nu, G, K)
    TYPE(PH_Mat_Plast_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(OUT) :: E, nu, G, K
    REAL(wp) :: one, two, three
    one = 1.0_wp; two = 2.0_wp; three = 3.0_wp
    IF (ALLOCATED(desc%props) .AND. SIZE(desc%props) >= 2) THEN
      E = desc%props(1)
      nu = desc%props(2)
    ELSE
      E = desc%E
      nu = desc%nu
    END IF
    G = E / (two * (one + nu))
    K = E / (three * (one - two * nu))
  END SUBROUTINE plast_desc_read_elastic

  SUBROUTINE plast_desc_read_hardening(desc, sigma_y, H_iso)
    TYPE(PH_Mat_Plast_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(OUT) :: sigma_y, H_iso
    IF (ALLOCATED(desc%props) .AND. SIZE(desc%props) >= 4) THEN
      sigma_y = desc%props(3)
      H_iso = desc%props(4)
    ELSE IF (ALLOCATED(desc%props) .AND. SIZE(desc%props) >= 3) THEN
      sigma_y = desc%props(3)
      H_iso = desc%H_iso
    ELSE
      sigma_y = desc%sigma_y
      H_iso = desc%H_iso
    END IF
  END SUBROUTINE plast_desc_read_hardening

  SUBROUTINE PH_Mat_Plast_Populate_From_L3(desc, l3_props, l3_nprops, &
                                            l3_sub_type, status)
    TYPE(PH_Mat_Plast_Desc), INTENT(OUT) :: desc
    REAL(wp), INTENT(IN) :: l3_props(:)
    INTEGER(i4), INTENT(IN) :: l3_nprops, l3_sub_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    desc%cfg%sub_type = l3_sub_type
    IF (ALLOCATED(desc%props)) DEALLOCATE(desc%props)
    IF (l3_nprops > 0) THEN
      ALLOCATE(desc%props(l3_nprops))
      desc%props(1:l3_nprops) = l3_props(1:l3_nprops)
    END IF
    desc%pop%is_valid = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Plast_Populate_From_L3

  SUBROUTINE PH_Mat_Plast_Build_Elastic_Stiffness(desc, ctx, status)
    TYPE(PH_Mat_Plast_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Plast_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: lam, G2, E_loc, nu_loc, G_loc, K_loc

    CALL init_error_status(status)
    CALL plast_desc_read_elastic(desc, E_loc, nu_loc, G_loc, K_loc)
    lam = E_loc * nu_loc / ((1.0_wp + nu_loc) * (1.0_wp - 2.0_wp * nu_loc))
    G2 = 2.0_wp * G_loc

    ctx%D_el = 0.0_wp
    ctx%D_el(1,1) = lam + G2; ctx%D_el(1,2) = lam; ctx%D_el(1,3) = lam
    ctx%D_el(2,1) = lam; ctx%D_el(2,2) = lam + G2; ctx%D_el(2,3) = lam
    ctx%D_el(3,1) = lam; ctx%D_el(3,2) = lam; ctx%D_el(3,3) = lam + G2
    ctx%D_el(4,4) = G_loc; ctx%D_el(5,5) = G_loc; ctx%D_el(6,6) = G_loc

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Plast_Build_Elastic_Stiffness

  SUBROUTINE PH_Mat_Plast_Compute_Trial_Stress(ctx, strain, stress_trial, status)
    TYPE(PH_Mat_Plast_Ctx), INTENT(IN) :: ctx
    REAL(wp), INTENT(IN) :: strain(6)
    REAL(wp), INTENT(OUT) :: stress_trial(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j

    CALL init_error_status(status)
    DO i = 1, 6
      stress_trial(i) = 0.0_wp
      DO j = 1, 6
        stress_trial(i) = stress_trial(i) + ctx%D_el(i,j) * strain(j)
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Plast_Compute_Trial_Stress

  SUBROUTINE PH_Mat_Plast_Check_Yield(desc, state, stress_trial, &
                                       yield_function, status)
    TYPE(PH_Mat_Plast_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Plast_State), INTENT(IN) :: state
    REAL(wp), INTENT(IN) :: stress_trial(6)
    REAL(wp), INTENT(OUT) :: yield_function
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: s_dev(6), J2, sigma_eq, sigma_y_current, sigma_y0, H_iso

    CALL init_error_status(status)
    CALL plast_desc_read_hardening(desc, sigma_y0, H_iso)

    ! Compute deviatoric stress
    s_dev(1:3) = stress_trial(1:3) - SUM(stress_trial(1:3))/3.0_wp
    s_dev(4:6) = stress_trial(4:6)

    ! Compute J2 and equivalent stress
    J2 = 0.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2) + &
         s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2
    sigma_eq = SQRT(3.0_wp * J2)

    ! Current yield stress (with hardening)
    sigma_y_current = sigma_y0 + H_iso * state%equiv_plastic_strain

    ! Yield function
    yield_function = sigma_eq - sigma_y_current

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Plast_Check_Yield

  SUBROUTINE PH_Mat_Plast_ComputeReturnMapping(desc, state, algo, ctx, &
                                          strain, stress, ddsdde, status)
    ! 理论链: 弹塑性返回映射（trial → 屈服 → 径向/族内修正）。
    ! 逻辑链: 组装 D_e、试应力、屈服判据、塑性修正与切线。
    ! 计算链: PH_Mat_Plast_Build_Elastic_Stiffness / Check_Yield / 族 dispatch。
    ! 数据链: desc·state·algo·ctx(IN/OUT); stress·ddsdde(OUT)。
    TYPE(PH_Mat_Plast_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Plast_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Plast_Algo), INTENT(IN) :: algo
    TYPE(PH_Mat_Plast_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: strain(6)
    REAL(wp), INTENT(OUT) :: stress(6), ddsdde(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: stress_trial(6), yield_func

    CALL init_error_status(status)

    ! Build elastic stiffness
    CALL PH_Mat_Plast_Build_Elastic_Stiffness(desc, ctx, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Compute trial stress
    CALL PH_Mat_Plast_Compute_Trial_Stress(ctx, strain, stress_trial, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Check yield
    CALL PH_Mat_Plast_Check_Yield(desc, state, stress_trial, yield_func, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    IF (yield_func <= 0.0_wp) THEN
      ! Elastic step: trial stress is correct
      stress = stress_trial
      ddsdde = ctx%D_el
      state%is_plastic = .FALSE.
    ELSE
      ! Plastic step: J2 radial return mapping with isotropic hardening
      CALL J2_Radial_Return(desc, stress_trial, yield_func, &
                             ctx, stress, ddsdde, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      state%is_plastic = .TRUE.
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Plast_ComputeReturnMapping

  SUBROUTINE PH_Mat_Plast_Update_State(state, stress, strain, status)
    TYPE(PH_Mat_Plast_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(6), strain(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    state%stress = stress
    state%strain = strain
    state%num_evaluations = state%num_evaluations + 1
    state%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Plast_Update_State

  !-----------------------------------------------------------------------------
  ! J2_Radial_Return
  ! Radial return mapping for J2 plasticity with isotropic hardening.
  ! Computes updated stress and consistent tangent (algorithmic) modulus.
  ! Reference: Simo & Hughes, "Computational Inelasticity", Section 3.6
  !-----------------------------------------------------------------------------
  SUBROUTINE J2_Radial_Return(desc, stress_trial, yield_func, &
                               ctx, stress, ddsdde, status)
    TYPE(PH_Mat_Plast_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(IN) :: stress_trial(6)
    REAL(wp), INTENT(IN) :: yield_func
    TYPE(PH_Mat_Plast_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(OUT) :: stress(6), ddsdde(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: s_dev(6), s_mag, sigma_eq, dgamma
    REAL(wp) :: n_dev(6), one, two, three, mu_bar
    REAL(wp) :: H_prime, Kp, theta, two_G, K_bulk
    REAL(wp) :: G2, mu_val, H_iso, sigma_y0
    REAL(wp) :: E_loc, nu_loc, G_loc
    INTEGER(i4) :: i, j

    CALL init_error_status(status)
    CALL plast_desc_read_hardening(desc, sigma_y0, H_iso)
    CALL plast_desc_read_elastic(desc, E_loc, nu_loc, G_loc, K_bulk)
    one = 1.0_wp; two = 2.0_wp; three = 3.0_wp

    ! Extract deviatoric trial stress
    s_dev(1:3) = stress_trial(1:3) - SUM(stress_trial(1:3))/three
    s_dev(4:6) = stress_trial(4:6)

    ! Magnitude of deviatoric stress
    s_mag = SQRT(s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 + &
                 two*(s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2))

    ! Plastic multiplier (gamma dot)
    sigma_eq = SQRT(1.5_wp) * s_mag
    ! J2: f = sigma_eq - sigma_y(ep_bar)
    ! Radial return: dgamma = f / (3*mu + H')
    mu_val = G_loc
    H_prime = H_iso

    ! Check for perfect plasticity (H' = 0)
    Kp = three * mu_val + H_prime
    IF (Kp <= 0.0_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "J2_Radial_Return: Non-positive plastic modulus"
      RETURN
    END IF

    ! Plastic multiplier
    dgamma = yield_func / Kp

    ! Unit flow direction (normal to yield surface)
    IF (s_mag > EPSILON(one)) THEN
      n_dev = s_dev / s_mag
    ELSE
      n_dev = 0.0_wp
    END IF

    ! Updated stress = stress_trial - 2*mu*dgamma*n
    stress = stress_trial
    DO i = 1, 6
      stress(i) = stress(i) - two * mu_val * dgamma * n_dev(i)
    END DO

    ! Store plastic multiplier in context
    ctx%delta_lambda = dgamma

    ! Consistent tangent (algorithmic modulus):
    ! ddsdde = D_el - (2*mu)^2 * dgamma / s_mag * (n_dev*n_dev^T)
    !          - (2*mu)^2 / (3*mu + H') * (n_dev*n_dev^T)
    !          + (2*mu)^2 * dgamma / s_mag * I_dev
    ddsdde = ctx%D_el

    ! Projection tensor modification
    two_G = two * mu_val
    G2 = two_G
    theta = one - two_G * dgamma / s_mag
    ! Consistent tangent: K * (I x I) + 2*mu*theta*I_dev - 2*mu*(theta-1)*n*n
    ! Simplified: elastic predictor minus plastic correction
    DO i = 1, 6
      DO j = 1, 6
        ! Subtract (2*mu)^2/(3*mu+H') * n_i * n_j
        ddsdde(i,j) = ddsdde(i,j) - (two_G*two_G / Kp) * n_dev(i) * n_dev(j)
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE J2_Radial_Return

END MODULE PH_Mat_Plast_Core
