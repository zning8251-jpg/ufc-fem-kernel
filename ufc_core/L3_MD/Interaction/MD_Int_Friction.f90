!======================================================================
! MODULE:  MD_Int_Friction
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Contact friction models. Coulomb, stick-slip,
!          velocity/pressure-dependent, damping, bond-debond,
!          and user friction callbacks.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================
MODULE MD_Int_Friction
    USE MD_Int_Types
    IMPLICIT NONE
    PRIVATE

    ! --- Direct PUBLIC procedures ---
    PUBLIC :: Cont_ApplyFriction
    PUBLIC :: Cont_Friction_bond_debond
    PUBLIC :: Cont_Friction_check_slip_condition
    PUBLIC :: Co_Fr_Co_force, Co_Fr_Co_fo_2d, Co_Fr_Co_fo_3d
    PUBLIC :: Co_Fr_Co_sl_direction, Co_Fr_Co_Stiff
    PUBLIC :: Co_Fr_co_damping, Co_Fr_set_da_ratio
    PUBLIC :: Cont_Friction_COULOM, Cont_Friction_critical_damping
    PUBLIC :: Co_Fr_Ev_coulomb, Co_Fr_Ev_st_slip, Co_Fr_Ev_ve_dep
    PUBLIC :: Co_Fr_pr_dependent, Co_Fr_up_state, Co_Fr_ve_dependent
    PUBLIC :: Cont_Friction_STICK
    ! fric_call, vfric_call live in MD_Int_Manager (user callbacks)
    PUBLIC :: UF_Fr_ComputeFrictionForce, UF_Fr_GetStatistics
    PUBLIC :: UF_Co_ComputeFrictionForce

    ! --- PUBLIC name aliases (match original PUBLIC declarations) ---
    INTERFACE Cont_Friction_Compute_force
        MODULE PROCEDURE Co_Fr_Co_force
    END INTERFACE
    PUBLIC :: Cont_Friction_Compute_force

    INTERFACE Cont_Friction_Compute_force_2d
        MODULE PROCEDURE Co_Fr_Co_fo_2d
    END INTERFACE
    PUBLIC :: Cont_Friction_Compute_force_2d

    INTERFACE Cont_Friction_Compute_force_3d
        MODULE PROCEDURE Co_Fr_Co_fo_3d
    END INTERFACE
    PUBLIC :: Cont_Friction_Compute_force_3d

    INTERFACE Cont_Friction_Compute_Stiff
        MODULE PROCEDURE Co_Fr_Co_Stiff
    END INTERFACE
    PUBLIC :: Cont_Friction_Compute_Stiff

    INTERFACE Cont_Friction_Compute_slip_direction
        MODULE PROCEDURE Co_Fr_Co_sl_direction
    END INTERFACE
    PUBLIC :: Cont_Friction_Compute_slip_direction

    INTERFACE Cont_Friction_velocity_dependent
        MODULE PROCEDURE Co_Fr_ve_dependent
    END INTERFACE
    PUBLIC :: Cont_Friction_velocity_dependent

    INTERFACE Cont_Friction_update_state
        MODULE PROCEDURE Co_Fr_up_state
    END INTERFACE
    PUBLIC :: Cont_Friction_update_state

    INTERFACE Cont_Friction_pressure_dependent
        MODULE PROCEDURE Co_Fr_pr_dependent
    END INTERFACE
    PUBLIC :: Cont_Friction_pressure_dependent

    INTERFACE Cont_Friction_contact_damping
        MODULE PROCEDURE Co_Fr_co_damping
    END INTERFACE
    PUBLIC :: Cont_Friction_contact_damping

    INTERFACE Cont_Friction_set_damping_ratio
        MODULE PROCEDURE Co_Fr_set_da_ratio
    END INTERFACE
    PUBLIC :: Cont_Friction_set_damping_ratio

CONTAINS

    SUBROUTINE Cont_ApplyFriction(contact_node, relative_veloci, control, &
                                   tangent_force, slip_rate)
        TYPE(ContNode), INTENT(INOUT) :: contact_node
        REAL(wp), INTENT(IN) :: relative_veloci(3)
        TYPE(ContAlgoCtrl), INTENT(IN) :: control
        REAL(wp), INTENT(OUT) :: tangent_force(2), slip_rate(2)
        REAL(wp) :: normal_force, mu, slip_velocity(2), slip_magnitude
        REAL(wp) :: t1_vector(3), t2_vector(3)
        mu = control%friction_coeffi
        normal_force = ABS(contact_node%force_n)
        t1_vector = contact_node%tangent(1:3)
        slip_velocity(1) = DOT_PRODUCT(relative_veloci, t1_vector)
        slip_velocity(2) = 0.0_wp
        slip_magnitude = SQRT(slip_velocity(1)**2 + slip_velocity(2)**2)
        slip_rate = slip_velocity
        SELECT CASE (control%friction_model)
        CASE (FRICTION_ALGO_C)
            IF (slip_magnitude < control%tolerance_slip) THEN
                contact_node%state = CSTATE_STICKING
                tangent_force = 0.0_wp
            ELSE
                contact_node%state = CSTATE_SLIDING
                tangent_force(1) = -mu * normal_force * slip_velocity(1) / slip_magnitude
                tangent_force(2) = -mu * normal_force * slip_velocity(2) / slip_magnitude
            END IF
        CASE (FRICTION_ALGO_S)
            tangent_force = 0.0_wp
        CASE (FRICTION_ALGO_R)
            tangent_force = 0.0_wp
        CASE DEFAULT
            tangent_force = 0.0_wp
        END SELECT
    END SUBROUTINE

    SUBROUTINE Cont_Friction_bond_debond(node, fric_params, F_n, k_t, &
                                     bond_strength, delta_f, &
                                     F_t, damage, new_state)
        TYPE(ContNode), INTENT(IN) :: node
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: F_n, k_t, bond_strength, delta_f
        REAL(wp), INTENT(OUT) :: F_t(3)
        REAL(wp), INTENT(INOUT) :: damage
        INTEGER(i4), INTENT(OUT) :: new_state
        REAL(wp) :: slip_mag, delta_0, tau_trial, mu, t_dir(3)
        REAL(wp) :: F_bond(3), F_fric(3)
        slip_mag = node%slip
        mu = fric_params%mu_static
        t_dir = node%tangent
        delta_0 = bond_strength / k_t
        tau_trial = k_t * slip_mag
        IF (damage >= 1.0_wp) THEN
            new_state = CSTATE_SLIDING
            F_t = mu * MAX(0.0_wp, F_n) * t_dir
        ELSE IF (slip_mag < delta_0 .AND. damage < FRICTION_TOL) THEN
            new_state = CSTATE_STICKING
            F_t = k_t * slip_mag * t_dir
        ELSE
            IF (slip_mag > delta_0) THEN
                damage = MAX(damage, (slip_mag - delta_0) / (delta_f - delta_0))
                damage = MIN(damage, 1.0_wp)
            END IF
            F_bond = (1.0_wp - damage) * k_t * slip_mag * t_dir
            F_fric = damage * mu * MAX(0.0_wp, F_n) * t_dir
            F_t = F_bond + F_fric
            IF (damage < 1.0_wp) THEN
                new_state = CSTATE_STICKING
            ELSE
                new_state = CSTATE_SLIDING
            END IF
        END IF
    END SUBROUTINE

    PURE FUNCTION Cont_Friction_check_slip_condition(trial_t, F_n, mu) RESULT(is_slip)
        REAL(wp), INTENT(IN) :: trial_t, F_n, mu
        LOGICAL :: is_slip
        REAL(wp) :: F_t_max
        F_t_max = mu * MAX(0.0_wp, F_n)
        is_slip = (trial_t > F_t_max)
    END FUNCTION

    SUBROUTINE Co_Fr_Co_force(node, fric_params, F_n, dt, F_t, new_state)
        TYPE(ContNode), INTENT(IN) :: node
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: F_n, dt
        REAL(wp), INTENT(OUT) :: F_t(3)
        INTEGER(i4), INTENT(OUT) :: new_state
        REAL(wp) :: mu_eff
        SELECT CASE (fric_params%model)
        CASE (FRICTION_NONE)
            F_t = 0.0_wp
            new_state = node%state
        CASE (FRICTION_COULOM)
            IF (fric_params%pressure_depend) THEN
                CALL Co_Fr_pr_dependent(fric_params, F_n, mu_eff)
                CALL Co_Fr_Ev_coulomb(node, mu_eff, F_n, F_t, new_state)
            ELSE
                CALL Co_Fr_Ev_coulomb(node, fric_params%mu_static, F_n, F_t, new_state)
            END IF
        CASE (FRICTION_STICK)
            IF (fric_params%pressure_depend) THEN
                CALL Co_Fr_pr_dependent(fric_params, F_n, mu_eff)
                CALL Co_Fr_Ev_st_slip(node, mu_eff, fric_params%mu_kinetic, &
                                      fric_params%tolerance, F_n, F_t, new_state)
            ELSE
                CALL Co_Fr_Ev_st_slip(node, fric_params%mu_static, fric_params%mu_kinetic, &
                                      fric_params%tolerance, F_n, F_t, new_state)
            END IF
        CASE (FRICTION_VELOCI)
            CALL Co_Fr_Ev_ve_dep(node, fric_params, F_n, dt, F_t, new_state)
        CASE (FRICTION_PRESSU)
            CALL Co_Fr_pr_dependent(fric_params, F_n, mu_eff)
            CALL Co_Fr_Ev_coulomb(node, mu_eff, F_n, F_t, new_state)
        CASE (FRICTION_USER)
            IF (fric_params%bond_strength > 0.0_wp) THEN
                CALL Cont_Friction_bond_debond(node, fric_params, F_n, 0.0_wp, &
                                               fric_params%bond_strength, &
                                               fric_params%bond_delta_f, &
                                               F_t, fric_params%damage, new_state)
            ELSE
                CALL Co_Fr_Ev_coulomb(node, fric_params%mu_static, F_n, F_t, new_state)
            END IF
        CASE DEFAULT
            CALL Co_Fr_Ev_coulomb(node, fric_params%mu_static, F_n, F_t, new_state)
        END SELECT
        node%force_t = F_t
    END SUBROUTINE

    SUBROUTINE Co_Fr_Co_fo_2d(slip_y, slip_z, tangent, normal, &
                                          mu, F_n, k_t, F_t_y, F_t_z, is_sliding)
        REAL(wp), INTENT(IN) :: slip_y, slip_z, tangent(3), normal(3), mu, F_n, k_t
        REAL(wp), INTENT(OUT) :: F_t_y, F_t_z
        LOGICAL, INTENT(OUT) :: is_sliding
        REAL(wp) :: slip_mag, trial_t, F_t_max, slip_dir_y, slip_dir_z
        slip_mag = ABS(slip_y * tangent(2) + slip_z * tangent(3))
        trial_t = k_t * slip_mag
        F_t_max = mu * MAX(0.0_wp, F_n)
        IF (trial_t <= F_t_max .OR. F_t_max < FRICTION_TOL) THEN
            is_sliding = .FALSE.
            F_t_y = k_t * slip_y
            F_t_z = k_t * slip_z
        ELSE
            is_sliding = .TRUE.
            IF (slip_mag > FRICTION_TOL) THEN
                slip_dir_y = slip_y / slip_mag
                slip_dir_z = slip_z / slip_mag
            ELSE
                slip_dir_y = tangent(2)
                slip_dir_z = tangent(3)
            END IF
            F_t_y = F_t_max * slip_dir_y
            F_t_z = F_t_max * slip_dir_z
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Fr_Co_fo_3d(slip, tangent1, tangent2, normal, &
                                          mu, F_n, k_t, F_t, is_sliding)
        REAL(wp), INTENT(IN) :: slip(3), tangent1(3), tangent2(3), normal(3)
        REAL(wp), INTENT(IN) :: mu, F_n, k_t
        REAL(wp), INTENT(OUT) :: F_t(3)
        LOGICAL, INTENT(OUT) :: is_sliding
        REAL(wp) :: slip_t(3), slip_t_mag, trial_t, F_t_max, slip_dir(3)
        slip_t = slip - SUM(slip * normal) * normal
        slip_t_mag = SQRT(SUM(slip_t**2))
        trial_t = k_t * slip_t_mag
        F_t_max = mu * MAX(0.0_wp, F_n)
        IF (trial_t <= F_t_max .OR. F_t_max < FRICTION_TOL) THEN
            is_sliding = .FALSE.
            F_t = k_t * slip_t
        ELSE
            is_sliding = .TRUE.
            IF (slip_t_mag > FRICTION_TOL) THEN
                slip_dir = slip_t / slip_t_mag
            ELSE
                slip_dir = tangent1
            END IF
            F_t = F_t_max * slip_dir
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Fr_Co_sl_direction(slip, tangent, normal, slip_dir, slip_mag)
        REAL(wp), INTENT(IN) :: slip(3), tangent(3), normal(3)
        REAL(wp), INTENT(OUT) :: slip_dir(3), slip_mag
        REAL(wp) :: slip_t(3)
        slip_t = slip - SUM(slip * normal) * normal
        slip_mag = SQRT(SUM(slip_t**2))
        IF (slip_mag > FRICTION_TOL) THEN
            slip_dir = slip_t / slip_mag
        ELSE
            slip_dir = tangent
            slip_mag = 0.0_wp
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Fr_Co_Stiff(node, fric_params, F_n, k_n, k_t, K_fric, dim)
        TYPE(ContNode), INTENT(IN) :: node
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: F_n, k_n, k_t
        REAL(wp), INTENT(OUT) :: K_fric(:,:)
        INTEGER(i4), INTENT(IN) :: dim
        REAL(wp) :: mu, t(3), n(3)
        INTEGER(i4) :: i, j
        mu = fric_params%mu_static
        t = node%tangent
        n = node%normal
        K_fric = 0.0_wp
        IF (node%state == CSTATE_STICKING) THEN
            DO i = 1, dim
                DO j = 1, dim
                    K_fric(i, j) = k_t * t(i) * t(j)
                END DO
            END DO
        ELSE IF (node%state == CSTATE_SLIDING) THEN
            DO i = 1, dim
                DO j = 1, dim
                    K_fric(i, j) = mu * k_n * t(i) * n(j)
                END DO
            END DO
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Fr_co_damping(v_normal, v_tangent, normal, tangent, &
                                         c_n, c_t, F_damp_n, F_damp_t)
        REAL(wp), INTENT(IN) :: v_normal, v_tangent(3), normal(3), tangent(3)
        REAL(wp), INTENT(IN) :: c_n, c_t
        REAL(wp), INTENT(OUT) :: F_damp_n
        REAL(wp), INTENT(OUT) :: F_damp_t(3)
        REAL(wp) :: v_t_mag
        IF (v_normal < 0.0_wp) THEN
            F_damp_n = -c_n * v_normal
        ELSE
            F_damp_n = 0.0_wp
        END IF
        v_t_mag = SQRT(SUM(v_tangent**2))
        IF (v_t_mag > FRICTION_TOL) THEN
            F_damp_t = -c_t * v_tangent
        ELSE
            F_damp_t = 0.0_wp
        END IF
    END SUBROUTINE

    SUBROUTINE Cont_Friction_COULOM(fric_params, normal_pressure, tangential_trac, &
                                 friction_force, state, slip_velocity)
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: normal_pressure, tangential_trac(3)
        REAL(wp), INTENT(OUT) :: friction_force(3)
        INTEGER(i4), INTENT(OUT) :: state
        REAL(wp), INTENT(IN), OPTIONAL :: slip_velocity
        REAL(wp) :: mu, traction_mag
        IF (fric_params%model == FRICTION_NONE) THEN
            friction_force = 0.0_wp
            state = CSTATE_SEPARATE
            RETURN
        END IF
        mu = fric_params%mu_kinetic
        traction_mag = SQRT(SUM(tangential_trac**2))
        IF (traction_mag < FRICTION_TOL) THEN
            friction_force = tangential_trac
            state = CSTATE_STICKING
        ELSE
            IF (traction_mag <= mu * normal_pressure) THEN
                friction_force = tangential_trac
                state = CSTATE_STICKING
            ELSE
                friction_force = mu * normal_pressure * tangential_trac / traction_mag
                state = CSTATE_SLIDING
            END IF
        END IF
    END SUBROUTINE

    FUNCTION Cont_Friction_critical_damping(mass, stiffness) RESULT(c_crit)
        REAL(wp), INTENT(IN) :: mass, stiffness
        REAL(wp) :: c_crit
        c_crit = 2.0_wp * SQRT(mass * stiffness)
    END FUNCTION

    SUBROUTINE Co_Fr_Ev_coulomb(node, mu, F_n, F_t, new_state)
        TYPE(ContNode), INTENT(IN) :: node
        REAL(wp), INTENT(IN) :: mu, F_n
        REAL(wp), INTENT(OUT) :: F_t(3)
        INTEGER(i4), INTENT(OUT) :: new_state
        REAL(wp) :: slip_mag, F_t_max, slip_dir(3)
        slip_mag = node%slip
        F_t_max = mu * MAX(0.0_wp, F_n)
        IF (slip_mag < SLIP_VELOCITY_T .OR. F_t_max < FRICTION_TOL) THEN
            F_t = 0.0_wp
            new_state = CSTATE_STICKING
        ELSE
            new_state = CSTATE_SLIDING
            slip_dir = node%tangent
            F_t = -F_t_max * slip_dir
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Fr_Ev_st_slip(node, mu_s, mu_k, tol, F_n, F_t, new_state)
        TYPE(ContNode), INTENT(IN) :: node
        REAL(wp), INTENT(IN) :: mu_s, mu_k, tol, F_n
        REAL(wp), INTENT(OUT) :: F_t(3)
        INTEGER(i4), INTENT(OUT) :: new_state
        REAL(wp) :: F_s_max, F_k_max, trial_t, slip_mag, slip_dir(3), trans_force
        F_s_max = mu_s * MAX(0.0_wp, F_n)
        F_k_max = mu_k * MAX(0.0_wp, F_n)
        slip_mag = node%slip
        slip_dir = node%tangent
        trial_t = SQRT(SUM(node%force_t**2))
        IF (node%state == CSTATE_STICKING .OR. node%state == CSTATE_INITIAL) THEN
            IF (trial_t > F_s_max * (1.0_wp + tol)) THEN
                new_state = CSTATE_SLIDING
                F_t = -F_k_max * slip_dir
            ELSE IF (trial_t > F_s_max * (1.0_wp - tol)) THEN
                trans_force = F_s_max + (F_k_max - F_s_max) * &
                              (trial_t - F_s_max*(1.0_wp - tol)) / (2.0_wp*tol*F_s_max)
                new_state = CSTATE_STICKING
                F_t = -trans_force * slip_dir
            ELSE
                new_state = CSTATE_STICKING
                F_t = node%force_t
            END IF
        ELSE
            IF (slip_mag < SLIP_VELOCITY_T .AND. trial_t < F_s_max * (1.0_wp - tol)) THEN
                new_state = CSTATE_STICKING
                F_t = node%force_t
            ELSE IF (slip_mag < SLIP_VELOCITY_T) THEN
                new_state = CSTATE_SLIDING
                F_t = -F_k_max * slip_dir
            ELSE
                new_state = CSTATE_SLIDING
                F_t = -F_k_max * slip_dir
            END IF
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Fr_Ev_ve_dep(node, fric_params, F_n, dt, F_t, new_state)
        TYPE(ContNode), INTENT(IN) :: node
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: F_n, dt
        REAL(wp), INTENT(OUT) :: F_t(3)
        INTEGER(i4), INTENT(OUT) :: new_state
        REAL(wp) :: mu_s, mu_k, decay, v_ref, slip_velocity, mu_eff, F_t_max, slip_dir(3)
        mu_s = fric_params%mu_static
        mu_k = fric_params%mu_kinetic
        decay = fric_params%decay_coeff
        v_ref = fric_params%slip_rate_ref
        IF (dt > FRICTION_TOL) THEN
            slip_velocity = node%slip / dt
        ELSE
            slip_velocity = 0.0_wp
        END IF
        mu_eff = mu_k + (mu_s - mu_k) * EXP(-decay * slip_velocity / v_ref)
        F_t_max = mu_eff * MAX(0.0_wp, F_n)
        IF (ABS(slip_velocity) > SLIP_VELOCITY_T) THEN
            slip_dir = node%tangent
            new_state = CSTATE_SLIDING
        ELSE
            slip_dir = node%tangent
            new_state = CSTATE_STICKING
        END IF
        F_t = -F_t_max * slip_dir
    END SUBROUTINE

    SUBROUTINE Co_Fr_pr_dependent(fric_params, p_n, mu_eff)
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: p_n
        REAL(wp), INTENT(OUT) :: mu_eff
        REAL(wp) :: mu_0, alpha, p_ref
        mu_0 = fric_params%mu_static
        alpha = fric_params%pressure_alpha
        p_ref = fric_params%pressure_ref
        IF (p_ref > 0.0_wp) THEN
            mu_eff = mu_0 * (1.0_wp - alpha * p_n / p_ref)
        ELSE
            mu_eff = mu_0
        END IF
        mu_eff = MAX(0.01_wp, mu_eff)
    END SUBROUTINE

    SUBROUTINE Co_Fr_set_da_ratio(eps_n, eps_t, mass, xi, c_n, c_t)
        REAL(wp), INTENT(IN) :: eps_n, eps_t, mass, xi
        REAL(wp), INTENT(OUT) :: c_n, c_t
        REAL(wp) :: c_crit_n, c_crit_t
        c_crit_n = 2.0_wp * SQRT(mass * eps_n)
        c_crit_t = 2.0_wp * SQRT(mass * eps_t)
        c_n = xi * c_crit_n
        c_t = xi * c_crit_t
    END SUBROUTINE

    SUBROUTINE Cont_Friction_STICK(fric_params, normal_pressure, tangential_trac, &
                                    friction_force, state, slip_velocity)
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: normal_pressure, tangential_trac(3)
        REAL(wp), INTENT(OUT) :: friction_force(3)
        INTEGER(i4), INTENT(OUT) :: state
        REAL(wp), INTENT(IN), OPTIONAL :: slip_velocity
        REAL(wp) :: mu_s, mu_k, traction_mag, mu_eff
        mu_s = fric_params%mu_static
        mu_k = fric_params%mu_kinetic
        traction_mag = SQRT(SUM(tangential_trac**2))
        IF (traction_mag < FRICTION_TOL) THEN
            friction_force = tangential_trac
            state = CSTATE_STICKING
            RETURN
        END IF
        IF (PRESENT(slip_velocity)) THEN
            IF (ABS(slip_velocity) < fric_params%tolerance) THEN
                mu_eff = mu_s
            ELSE
                mu_eff = mu_k
            END IF
        ELSE
            mu_eff = mu_s
        END IF
        IF (traction_mag <= mu_eff * normal_pressure) THEN
            friction_force = tangential_trac
            state = CSTATE_STICKING
        ELSE
            friction_force = mu_eff * normal_pressure * tangential_trac / traction_mag
            state = CSTATE_SLIDING
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Fr_up_state(fric_params, normal_pressure, tangential_trac, &
                                       state, slip_velocity)
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: normal_pressure, tangential_trac(3)
        INTEGER(i4), INTENT(INOUT) :: state
        REAL(wp), INTENT(IN), OPTIONAL :: slip_velocity
        REAL(wp) :: mu, traction_mag
        IF (fric_params%model == FRICTION_NONE) THEN
            state = CSTATE_SEPARATE
            RETURN
        END IF
        mu = fric_params%mu_kinetic
        traction_mag = SQRT(SUM(tangential_trac**2))
        IF (traction_mag < FRICTION_TOL) THEN
            state = CSTATE_STICKING
        ELSE
            IF (traction_mag <= mu * normal_pressure) THEN
                state = CSTATE_STICKING
            ELSE
                state = CSTATE_SLIDING
            END IF
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Fr_ve_dependent(fric_params, normal_pressure, tangential_trac, &
                                            friction_force, state, slip_velocity)
        TYPE(FrictionParams), INTENT(IN) :: fric_params
        REAL(wp), INTENT(IN) :: normal_pressure, tangential_trac(3)
        REAL(wp), INTENT(OUT) :: friction_force(3)
        INTEGER(i4), INTENT(OUT) :: state
        REAL(wp), INTENT(IN) :: slip_velocity
        REAL(wp) :: mu_s, mu_k, traction_mag, mu_eff, v_ref
        mu_s = fric_params%mu_static
        mu_k = fric_params%mu_kinetic
        v_ref = fric_params%slip_rate_ref
        traction_mag = SQRT(SUM(tangential_trac**2))
        IF (traction_mag < FRICTION_TOL) THEN
            friction_force = tangential_trac
            state = CSTATE_STICKING
            RETURN
        END IF
        IF (v_ref > 0.0_wp) THEN
            mu_eff = mu_k + (mu_s - mu_k) * EXP(-fric_params%decay_coeff * ABS(slip_velocity) / v_ref)
        ELSE
            mu_eff = mu_s
        END IF
        IF (traction_mag <= mu_eff * normal_pressure) THEN
            friction_force = tangential_trac
            state = CSTATE_STICKING
        ELSE
            friction_force = mu_eff * normal_pressure * tangential_trac / traction_mag
            state = CSTATE_SLIDING
        END IF
    END SUBROUTINE

    ! NOTE: fric_call and vfric_call removed - they live in MD_Int_Manager

    SUBROUTINE UF_Fr_ComputeFrictionForce(normal_force, mu, &
                                                      relative_velocity, &
                                                      friction_force, status)
        REAL(wp), INTENT(IN) :: normal_force, mu
        REAL(wp), INTENT(IN) :: relative_velocity(3)
        REAL(wp), INTENT(OUT) :: friction_force(3)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status
        REAL(wp) :: velocity_magnitude, friction_magnitude
        IF (PRESENT(status)) status = 0
        velocity_magnitude = SQRT(SUM(relative_velocity**2))
        IF (velocity_magnitude > 1.0e-12_wp) THEN
            friction_magnitude = mu * ABS(normal_force)
            friction_force = -friction_magnitude * relative_velocity / velocity_magnitude
        ELSE
            friction_force = 0.0_wp
        END IF
    END SUBROUTINE

    SUBROUTINE UF_Fr_GetStatistics(friction_type, mu, stats, status)
        INTEGER(i4), INTENT(IN) :: friction_type
        REAL(wp), INTENT(IN) :: mu
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status
        CHARACTER(LEN=32) :: friction_name
        IF (PRESENT(status)) status = 0
        SELECT CASE (friction_type)
        CASE (FRICTION_NONE)
            friction_name = "None"
        CASE (FRICTION_COULOMB)
            friction_name = "Coulomb"
        CASE (FRICTION_STICK)
            friction_name = "Stick"
        CASE DEFAULT
            friction_name = "Unknown"
        END SELECT
        WRITE(stats, '(A,A,A,F6.3)') &
            'Friction Model Statistics: type="', TRIM(friction_name), '", mu=', mu
    END SUBROUTINE

    SUBROUTINE UF_Co_ComputeFrictionForce(normal_force, friction_coeff, &
                                               slip_velocity, friction_force, status)
        REAL(wp), INTENT(IN) :: normal_force, friction_coeff
        REAL(wp), INTENT(IN) :: slip_velocity(3)
        REAL(wp), INTENT(OUT) :: friction_force(3)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status
        REAL(wp) :: slip_magnitude, max_friction
        IF (PRESENT(status)) status = 0
        max_friction = friction_coeff * normal_force
        slip_magnitude = SQRT(SUM(slip_velocity**2))
        IF (slip_magnitude > 1.0e-12_wp) THEN
            friction_force = -max_friction * slip_velocity / slip_magnitude
        ELSE
            friction_force = 0.0_wp
        END IF
    END SUBROUTINE

END MODULE MD_Int_Friction
