!===============================================================================
! MODULE: PH_Mat_Visco_Core
! LAYER:  L4_PH
! DOMAIN: Material / Viscoelas
! ROLE:   Core — viscoelastic constitutive integration
! BRIEF:  Prony series viscoelasticity with relaxation.
!         Supports Generalized Maxwell (Prony), Kelvin-Voigt, and Maxwell models.
!===============================================================================
MODULE PH_Mat_Visco_Core
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Visco_Def, ONLY: PH_Mat_Visco_Desc, PH_Mat_Visco_State, &
                               PH_Mat_Visco_Algo, PH_Mat_Visco_Ctx, &
                               PH_MAT_VISCO_SUB_PRONY, &
                               PH_MAT_VISCO_SUB_KELVIN, &
                               PH_MAT_VISCO_SUB_MAXWELL
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Visco_Build_Instantaneous_Stiffness
  PUBLIC :: PH_Mat_Visco_Relax_Stress
  PUBLIC :: PH_Mat_Visco_Update_State
  PUBLIC :: PH_Mat_Visco_Populate_From_L3

CONTAINS

  !-----------------------------------------------------------------------------
  ! PH_Mat_Visco_Populate_From_L3
  ! Populate Desc fields from raw L3 property array.
  ! l3_props layout:
  !   Prony:   [E_inf, nu, g_1, tau_1, g_2, tau_2, ...]
  !   Kelvin:  [E, nu, eta]
  !   Maxwell: [E, nu, eta]
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Visco_Populate_From_L3(desc, l3_props, l3_nprops, &
                                            l3_sub_type, status)
    TYPE(PH_Mat_Visco_Desc), INTENT(INOUT) :: desc
    REAL(wp), INTENT(IN) :: l3_props(:)
    INTEGER(i4), INTENT(IN) :: l3_nprops, l3_sub_type
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, n_terms

    CALL init_error_status(status)
    desc%sub_type = l3_sub_type
    desc%is_valid = .TRUE.

    IF (l3_nprops < 2) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    desc%E_inf = l3_props(1)
    desc%nu = l3_props(2)

    SELECT CASE (l3_sub_type)
    CASE (PH_MAT_VISCO_SUB_PRONY)
      ! Prony series: g_i, tau_i pairs
      n_terms = (l3_nprops - 2) / 2
      desc%n_prony_terms = MIN(n_terms, 10)
      IF (desc%n_prony_terms > 0) THEN
        DO i = 1, desc%n_prony_terms
          desc%g_i(i) = l3_props(2 + 2*(i-1) + 1)
          desc%tau_i(i) = l3_props(2 + 2*(i-1) + 2)
        END DO
      END IF

    CASE (PH_MAT_VISCO_SUB_KELVIN)
      ! Kelvin-Voigt: E, nu, eta
      IF (l3_nprops >= 3) THEN
        desc%g_i(1) = l3_props(3) ! eta (viscosity coefficient)
        ! tau = eta / E  (retardation time)
        IF (desc%E_inf > 0.0_wp) THEN
          desc%tau_i(1) = l3_props(3) / desc%E_inf
        ELSE
          desc%tau_i(1) = 0.0_wp
        END IF
      END IF
      desc%n_prony_terms = 1

    CASE (PH_MAT_VISCO_SUB_MAXWELL)
      ! Maxwell: E, nu, eta
      IF (l3_nprops >= 3) THEN
        desc%g_i(1) = l3_props(3) ! eta (viscosity coefficient)
        ! tau = eta / E  (relaxation time)
        IF (desc%E_inf > 0.0_wp) THEN
          desc%tau_i(1) = l3_props(3) / desc%E_inf
        ELSE
          desc%tau_i(1) = 0.0_wp
        END IF
      END IF
      desc%n_prony_terms = 1
    END SELECT

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Visco_Populate_From_L3

  !-----------------------------------------------------------------------------
  ! PH_Mat_Visco_Build_Instantaneous_Stiffness
  ! Build the 6x6 instantaneous (unrelaxed) stiffness matrix D_inst
  ! from E_inf, nu and the Prony coefficients.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Visco_Build_Instantaneous_Stiffness(desc, ctx, status)
    TYPE(PH_Mat_Visco_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Visco_Ctx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: G0, K0, lam0, G_term
    INTEGER(i4) :: i

    CALL init_error_status(status)

    ! Instantaneous shear modulus: G0 = G_inf * (1 + sum(g_i))
    ! where G_inf = E_inf / (2*(1+nu)) and g_i are unitless Prony ratios
    G_term = desc%E_inf / (2.0_wp * (1.0_wp + desc%nu))
    G0 = G_term
    DO i = 1, desc%n_prony_terms
      G0 = G0 + desc%g_i(i) * G_term
    END DO

    K0 = desc%E_inf / (3.0_wp * (1.0_wp - 2.0_wp * desc%nu))
    lam0 = K0 - 2.0_wp * G0 / 3.0_wp

    ctx%D_inst = 0.0_wp
    ctx%D_inst(1,1) = lam0 + 2.0_wp*G0; ctx%D_inst(1,2) = lam0; ctx%D_inst(1,3) = lam0
    ctx%D_inst(2,1) = lam0; ctx%D_inst(2,2) = lam0 + 2.0_wp*G0; ctx%D_inst(2,3) = lam0
    ctx%D_inst(3,1) = lam0; ctx%D_inst(3,2) = lam0; ctx%D_inst(3,3) = lam0 + 2.0_wp*G0
    ctx%D_inst(4,4) = G0; ctx%D_inst(5,5) = G0; ctx%D_inst(6,6) = G0

    ctx%D_inst_cached = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Visco_Build_Instantaneous_Stiffness

  !-----------------------------------------------------------------------------
  ! PH_Mat_Visco_Relax_Stress
  ! Integrate viscoelastic stress and tangent stiffness.
  !
  ! Prony:     G(t) = G_inf * (1 - sum(g_i * (1 - exp(-t/tau_i))))
  !            Relaxation via time-step factor.
  ! Kelvin-Voigt: sigma = E*eps + eta*deps/dt  (rate-dependent elastic)
  ! Maxwell:      dsigma/dt + sigma/tau = E*deps/dt
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Visco_Relax_Stress(desc, state, algo, ctx, &
                                        strain, stress, ddsdde, status)
    TYPE(PH_Mat_Visco_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_Visco_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_Visco_Algo), INTENT(IN) :: algo
    TYPE(PH_Mat_Visco_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: strain(6)
    REAL(wp), INTENT(OUT) :: stress(6), ddsdde(6,6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: G0, stress_inst(6), ratio
    REAL(wp) :: dt, rel_coeff
    INTEGER(i4) :: i

    CALL init_error_status(status)

    IF (.NOT. ctx%D_inst_cached) THEN
      CALL PH_Mat_Visco_Build_Instantaneous_Stiffness(desc, ctx, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    ! Compute instantaneous elastic response
    CALL compute_stress_from_D(ctx%D_inst, strain, stress_inst)

    dt = algo%time_step
    IF (dt <= 0.0_wp) dt = 1.0_wp

    SELECT CASE (desc%sub_type)
    CASE (PH_MAT_VISCO_SUB_PRONY)
      ! Prony series relaxation factor over one time step:
      !   G(t) = G_inf * (1 + sum(g_i * exp(-t/tau_i)))
      !   G0 = G_inf * (1 + sum(g_i))
      !   ratio = G(dt) / G0 = (1 + sum(g_i*exp(-dt/tau_i))) / (1 + sum(g_i))
      !   stress = stress_inst * ratio
      G0 = 0.0_wp
      DO i = 1, desc%n_prony_terms
        G0 = G0 + desc%g_i(i)
      END DO
      G0 = 1.0_wp + G0  ! dimensionless: 1 + sum(g_i)

      rel_coeff = 0.0_wp
      DO i = 1, desc%n_prony_terms
        IF (desc%tau_i(i) > 0.0_wp) THEN
          rel_coeff = rel_coeff + desc%g_i(i) * (1.0_wp - EXP(-dt / desc%tau_i(i)))
        END IF
      END DO

      ! relaxed = (G0 - rel_coeff) / G0 * instantaneous
      ratio = (G0 - rel_coeff) / G0
      stress = stress_inst * ratio
      ddsdde = ctx%D_inst * ratio

    CASE (PH_MAT_VISCO_SUB_KELVIN)
      ! Kelvin-Voigt: purely elastic instantaneous response
      ! (damping handled via rate-dependent contribution elsewhere)
      stress = stress_inst
      ddsdde = ctx%D_inst

    CASE (PH_MAT_VISCO_SUB_MAXWELL)
      ! Maxwell first-order integration:
      !   sigma_n+1 = exp(-dt/tau) * sigma_n + (G0 * relaxed) * dstrain
      IF (desc%tau_i(1) > 0.0_wp) THEN
        rel_coeff = EXP(-dt / desc%tau_i(1))
        ! dstrain approximated as strain (from zero reference)
        stress = state%stress * rel_coeff + stress_inst * (1.0_wp - rel_coeff)
        ddsdde = ctx%D_inst * (1.0_wp - rel_coeff)
      ELSE
        stress = stress_inst
        ddsdde = ctx%D_inst
      END IF

    CASE DEFAULT
      ! Fallback: pure elastic via instantaneous stiffness
      stress = stress_inst
      ddsdde = ctx%D_inst
    END SELECT

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Visco_Relax_Stress

  !-----------------------------------------------------------------------------
  ! PH_Mat_Visco_Update_State
  ! Commit converged stress/strain back to state.
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Mat_Visco_Update_State(state, stress, strain, status)
    TYPE(PH_Mat_Visco_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(6), strain(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    state%stress = stress
    state%strain = strain
    state%num_evaluations = state%num_evaluations + 1
    state%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Visco_Update_State

  !-----------------------------------------------------------------------------
  ! Private helper: compute stress = D * strain
  !-----------------------------------------------------------------------------
  SUBROUTINE compute_stress_from_D(D, strain, stress)
    REAL(wp), INTENT(IN) :: D(6,6), strain(6)
    REAL(wp), INTENT(OUT) :: stress(6)
    INTEGER(i4) :: i, j
    DO i = 1, 6
      stress(i) = 0.0_wp
      DO j = 1, 6
        stress(i) = stress(i) + D(i,j) * strain(j)
      END DO
    END DO
  END SUBROUTINE compute_stress_from_D

END MODULE PH_Mat_Visco_Core
