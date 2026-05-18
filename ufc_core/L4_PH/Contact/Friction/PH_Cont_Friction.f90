!===============================================================================
! MODULE: PH_Cont_Friction
! LAYER:  L4_PH
! DOMAIN: Contact / Friction
! ROLE:   Core
! BRIEF:  Friction models (Coulomb/regularized/velocity/pressure-dependent)
!
! Four-Type: PH_Cont_FrictModel (Desc), PH_Cont_FrictState (State)
! Constants: PH_FRICT_* (algorithm-level friction model IDs)
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Cont_Friction
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !===========================================================================
  ! Public types �?friction model parameters and state
  !===========================================================================
  PUBLIC :: PH_Cont_FrictModel
  PUBLIC :: PH_Cont_FrictState

  !-- Friction model type constants
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICT_COULOMB      = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICT_STICK_SLIP   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICT_VELOCITY_DEP = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICT_PRESSURE_DEP = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICT_REGULARIZED  = 5_i4

  !-- Friction model parameters (Desc �?read-only)
  TYPE, PUBLIC :: PH_Cont_FrictModel
    INTEGER(i4) :: model_type = PH_FRICT_COULOMB
    REAL(wp)    :: mu_static  = 0.3_wp       ! Static friction coef
    REAL(wp)    :: mu_kinetic = 0.2_wp       ! Kinetic friction coef
    REAL(wp)    :: critical_slip = 1.0e-6_wp ! Critical slip distance
    REAL(wp)    :: velocity_scale  = 1.0e-3_wp ! Velocity scale parameter
    REAL(wp)    :: pressure_ref    = 1.0_wp    ! Reference pressure
    REAL(wp)    :: pressure_exponent = 0.0_wp  ! Pressure exponent
  END TYPE PH_Cont_FrictModel

  !-- Friction state (State �?dynamic, per iteration)
  TYPE, PUBLIC :: PH_Cont_FrictState
    REAL(wp) :: normal_force    = 0.0_wp
    REAL(wp) :: tangent_vel(3)  = [0.0_wp, 0.0_wp, 0.0_wp]
    REAL(wp) :: slip_distance   = 0.0_wp
    REAL(wp) :: friction_force(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    LOGICAL  :: is_sticking     = .TRUE.
    LOGICAL  :: is_sliding      = .FALSE.
  END TYPE PH_Cont_FrictState

  !===========================================================================
  ! Public API �?pure friction computation
  !===========================================================================
  PUBLIC :: PH_ContFric_Coulomb
  PUBLIC :: PH_ContFric_StickSlip
  PUBLIC :: PH_ContFric_Regularized
  PUBLIC :: PH_ContFric_VelocityDep
  PUBLIC :: PH_ContFric_PressureDep
  PUBLIC :: PH_ContFric_TangentStiff

CONTAINS

  !===========================================================================
  !> @brief Coulomb friction: F_t = -mu * |F_n| * dir(v_t)
  !===========================================================================
  SUBROUTINE PH_ContFric_Coulomb(frict_model, frict_state, normal_force, &
                                  tangent_vel, friction_force, is_sliding, status)
    TYPE(PH_Cont_FrictModel), INTENT(IN)  :: frict_model
    TYPE(PH_Cont_FrictState), INTENT(INOUT), OPTIONAL :: frict_state
    REAL(wp),                 INTENT(IN)  :: normal_force
    REAL(wp),                 INTENT(IN)  :: tangent_vel(3)
    REAL(wp),                 INTENT(OUT) :: friction_force(3)
    LOGICAL,                  INTENT(OUT) :: is_sliding
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    REAL(wp) :: mu, vel_mag, vel_dir(3)

    CALL init_error_status(status)
    friction_force = 0.0_wp
    is_sliding = .FALSE.

    ! C1.2: Zero normal force -> no friction
    IF (normal_force <= 0.0_wp) THEN
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .TRUE.
        frict_state%is_sliding = .FALSE.
        frict_state%friction_force = 0.0_wp
      END IF
      RETURN
    END IF

    mu = frict_model%mu_static
    vel_mag = SQRT(SUM(tangent_vel**2))

    IF (vel_mag < 1.0e-12_wp) THEN
      ! Sticking
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .TRUE.
        frict_state%is_sliding = .FALSE.
      END IF
    ELSE
      ! Sliding
      is_sliding = .TRUE.
      vel_dir = tangent_vel / vel_mag
      friction_force = -mu * ABS(normal_force) * vel_dir
      
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .FALSE.
        frict_state%is_sliding = .TRUE.
        frict_state%friction_force = friction_force
      END IF
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContFric_Coulomb

  !===========================================================================
  !> @brief Stick-slip friction with smooth transition
  !> mu(s) = mu_k + (mu_s - mu_k) * exp(-s/s_c)
  !===========================================================================
  SUBROUTINE PH_ContFric_StickSlip(frict_model, frict_state, normal_force, &
                                    tangent_vel, slip_dist, friction_force, &
                                    is_sliding, status)
    TYPE(PH_Cont_FrictModel), INTENT(IN)  :: frict_model
    TYPE(PH_Cont_FrictState), INTENT(INOUT), OPTIONAL :: frict_state
    REAL(wp),                 INTENT(IN)  :: normal_force
    REAL(wp),                 INTENT(IN)  :: tangent_vel(3)
    REAL(wp),                 INTENT(IN)  :: slip_dist
    REAL(wp),                 INTENT(OUT) :: friction_force(3)
    LOGICAL,                  INTENT(OUT) :: is_sliding
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    REAL(wp) :: mu_eff, vel_mag, vel_dir(3)

    CALL init_error_status(status)
    friction_force = 0.0_wp
    is_sliding = .FALSE.

    IF (normal_force <= 0.0_wp) THEN
      IF (PRESENT(frict_state)) frict_state%is_sticking = .TRUE.
      RETURN
    END IF

    ! Compute effective friction coef
    IF (slip_dist < frict_model%critical_slip) THEN
      mu_eff = frict_model%mu_kinetic + &
               (frict_model%mu_static - frict_model%mu_kinetic) * &
               EXP(-slip_dist / frict_model%critical_slip)
    ELSE
      mu_eff = frict_model%mu_kinetic
    END IF

    vel_mag = SQRT(SUM(tangent_vel**2))
    IF (vel_mag < 1.0e-12_wp) THEN
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .TRUE.
        frict_state%is_sliding = .FALSE.
      END IF
    ELSE
      is_sliding = .TRUE.
      vel_dir = tangent_vel / vel_mag
      friction_force = -mu_eff * ABS(normal_force) * vel_dir
      
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .FALSE.
        frict_state%is_sliding = .TRUE.
        frict_state%friction_force = friction_force
        frict_state%slip_distance = slip_dist
      END IF
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContFric_StickSlip

  !===========================================================================
  !> @brief Regularized friction: F_t = -mu*|F_n|*tanh(|v|/v_c)*dir(v)
  !===========================================================================
  SUBROUTINE PH_ContFric_Regularized(frict_model, frict_state, normal_force, &
                                      tangent_vel, friction_force, is_sliding, status)
    TYPE(PH_Cont_FrictModel), INTENT(IN)  :: frict_model
    TYPE(PH_Cont_FrictState), INTENT(INOUT), OPTIONAL :: frict_state
    REAL(wp),                 INTENT(IN)  :: normal_force
    REAL(wp),                 INTENT(IN)  :: tangent_vel(3)
    REAL(wp),                 INTENT(OUT) :: friction_force(3)
    LOGICAL,                  INTENT(OUT) :: is_sliding
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    REAL(wp) :: mu, vel_mag, v_scale, scale

    CALL init_error_status(status)
    friction_force = 0.0_wp
    is_sliding = .FALSE.

    IF (normal_force <= 0.0_wp) THEN
      IF (PRESENT(frict_state)) frict_state%is_sticking = .TRUE.
      RETURN
    END IF

    mu = frict_model%mu_kinetic
    IF (mu <= 0.0_wp) mu = frict_model%mu_static
    vel_mag = SQRT(SUM(tangent_vel**2))
    v_scale = frict_model%velocity_scale
    IF (v_scale <= 0.0_wp) v_scale = 1.0e-6_wp

    IF (vel_mag < 1.0e-20_wp) THEN
      IF (PRESENT(frict_state)) frict_state%is_sticking = .TRUE.
    ELSE
      is_sliding = .TRUE.
      scale = TANH(vel_mag / v_scale)
      friction_force = -mu * ABS(normal_force) * scale * (tangent_vel / vel_mag)
      
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .FALSE.
        frict_state%is_sliding = .TRUE.
        frict_state%friction_force = friction_force
      END IF
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContFric_Regularized

  !===========================================================================
  !> @brief Velocity-dependent friction: mu(v) = mu_k + (mu_s-mu_k)/(1+(v/v_s)^2)
  !===========================================================================
  SUBROUTINE PH_ContFric_VelocityDep(frict_model, frict_state, normal_force, &
                                      tangent_vel, friction_force, is_sliding, status)
    TYPE(PH_Cont_FrictModel), INTENT(IN)  :: frict_model
    TYPE(PH_Cont_FrictState), INTENT(INOUT), OPTIONAL :: frict_state
    REAL(wp),                 INTENT(IN)  :: normal_force
    REAL(wp),                 INTENT(IN)  :: tangent_vel(3)
    REAL(wp),                 INTENT(OUT) :: friction_force(3)
    LOGICAL,                  INTENT(OUT) :: is_sliding
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    REAL(wp) :: mu_eff, vel_mag, vel_ratio, vel_dir(3)

    CALL init_error_status(status)
    friction_force = 0.0_wp
    is_sliding = .FALSE.

    IF (normal_force <= 0.0_wp) THEN
      IF (PRESENT(frict_state)) frict_state%is_sticking = .TRUE.
      RETURN
    END IF

    vel_mag = SQRT(SUM(tangent_vel**2))
    IF (vel_mag < 1.0e-12_wp) THEN
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .TRUE.
        frict_state%is_sliding = .FALSE.
      END IF
    ELSE
      is_sliding = .TRUE.
      vel_ratio = vel_mag / frict_model%velocity_scale
      mu_eff = frict_model%mu_kinetic + &
               (frict_model%mu_static - frict_model%mu_kinetic) / &
               (1.0_wp + vel_ratio**2)
      
      vel_dir = tangent_vel / vel_mag
      friction_force = -mu_eff * ABS(normal_force) * vel_dir
      
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .FALSE.
        frict_state%is_sliding = .TRUE.
        frict_state%friction_force = friction_force
      END IF
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContFric_VelocityDep

  !===========================================================================
  !> @brief Pressure-dependent friction: mu(p) = mu_0 * (p/p_0)^alpha
  !===========================================================================
  SUBROUTINE PH_ContFric_PressureDep(frict_model, frict_state, normal_force, &
                                      tangent_vel, friction_force, is_sliding, status)
    TYPE(PH_Cont_FrictModel), INTENT(IN)  :: frict_model
    TYPE(PH_Cont_FrictState), INTENT(INOUT), OPTIONAL :: frict_state
    REAL(wp),                 INTENT(IN)  :: normal_force
    REAL(wp),                 INTENT(IN)  :: tangent_vel(3)
    REAL(wp),                 INTENT(OUT) :: friction_force(3)
    LOGICAL,                  INTENT(OUT) :: is_sliding
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    REAL(wp) :: mu_eff, pressure, vel_mag, vel_dir(3)

    CALL init_error_status(status)
    friction_force = 0.0_wp
    is_sliding = .FALSE.

    IF (normal_force <= 0.0_wp) THEN
      IF (PRESENT(frict_state)) frict_state%is_sticking = .TRUE.
      RETURN
    END IF

    pressure = ABS(normal_force)
    mu_eff = frict_model%mu_static * &
             (pressure / frict_model%pressure_ref)**frict_model%pressure_exponent

    vel_mag = SQRT(SUM(tangent_vel**2))
    IF (vel_mag < 1.0e-12_wp) THEN
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .TRUE.
        frict_state%is_sliding = .FALSE.
      END IF
    ELSE
      is_sliding = .TRUE.
      vel_dir = tangent_vel / vel_mag
      friction_force = -mu_eff * pressure * vel_dir
      
      IF (PRESENT(frict_state)) THEN
        frict_state%is_sticking = .FALSE.
        frict_state%is_sliding = .TRUE.
        frict_state%friction_force = friction_force
      END IF
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContFric_PressureDep

  !===========================================================================
  !> @brief Tangent stiffness for Newton: K_t = dF_t/du
  !===========================================================================
  SUBROUTINE PH_ContFric_TangentStiff(frict_model, frict_state, normal_force, &
                                       K_tangent, status)
    TYPE(PH_Cont_FrictModel), INTENT(IN)  :: frict_model
    TYPE(PH_Cont_FrictState), INTENT(IN)  :: frict_state
    REAL(wp),                 INTENT(IN)  :: normal_force
    REAL(wp),                 INTENT(OUT) :: K_tangent(3, 3)
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    REAL(wp) :: vel_mag, mu, k_approx, t(3)
    INTEGER(i4) :: i, j

    CALL init_error_status(status)
    K_tangent = 0.0_wp

    IF (normal_force <= 0.0_wp) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    vel_mag = SQRT(SUM(frict_state%tangent_vel**2))
    IF (vel_mag < 1.0e-20_wp) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    t = frict_state%tangent_vel / vel_mag
    mu = frict_model%mu_kinetic
    IF (mu <= 0.0_wp) mu = frict_model%mu_static
    
    ! Approximate: K_t �?mu * |F_n| / |v_t| * (t �?t)
    k_approx = mu * ABS(normal_force) / (vel_mag + 1.0e-20_wp)
    
    DO i = 1, 3
      DO j = 1, 3
        K_tangent(i, j) = k_approx * t(i) * t(j)
      END DO
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContFric_TangentStiff

END MODULE PH_Cont_Friction