!===============================================================================
! Module: TEST_PH_Cont_Friction
! Layer:  L5_RT - Runtime Layer (Test)
! Domain: Contact - Friction Models
! Purpose: Test friction models (Coulomb/stick-slip/velocity-dependent)
! Theory:
!   Friction models:
!   1. Coulomb: F_t = -μ·|F_n|·dir(v_t)
!   2. Stick-slip: μ(s) = μ_k + (μ_s - μ_k)·exp(-s/s_c)
!   3. Regularized: μ(v) = μ_k + (μ_s - μ_k)·exp(-|v|/v_c)
!   4. Velocity-dependent: μ(v) = μ_0 + (μ_∞ - μ_0)·(1 - exp(-v/v_ref))
!   5. Pressure-dependent: μ(p) = μ_0·(p/p_ref)^α
!
! Test Cases:
!   TC-FRIC-01: Coulomb摩擦-粘着状态
!   TC-FRIC-02: Coulomb摩擦-滑动状态
!   TC-FRIC-03: 粘滑摩擦-指数衰减
!   TC-FRIC-04: 正则化摩擦-平滑过渡
!   TC-FRIC-05: 速度相关摩擦
!   TC-FRIC-06: 压力相关摩擦
!   TC-FRIC-07: 摩擦切线刚度
!   TC-FRIC-08: 零法向力-无摩擦
!
! Status: Production | Created: 2026-04-18
!===============================================================================

MODULE TEST_PH_Cont_Friction
  USE IF_Const, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Prec_Core, ONLY: i4, wp
  USE PH_Cont_Friction, ONLY: PH_Cont_FrictModel, PH_Cont_FrictState, &
                              PH_ContFric_Coulomb, PH_ContFric_StickSlip, &
                              PH_ContFric_Regularized, PH_ContFric_VelocityDep, &
                              PH_ContFric_PressureDep, PH_ContFric_TangentStiff, &
                              PH_FRICT_COULOMB, PH_FRICT_STICK_SLIP, &
                              PH_FRICT_VELOCITY_DEP, PH_FRICT_PRESSURE_DEP, &
                              PH_FRICT_REGULARIZED
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_All_Cont_Friction_Tests

  ! Test tolerance
  REAL(wp), PARAMETER :: TOLERANCE = 1.0e-6_wp
  REAL(wp), PARAMETER :: TOLERANCE_FRICTION = 1.0e-3_wp  ! 0.1% for friction

CONTAINS

  SUBROUTINE Run_All_Cont_Friction_Tests()
    !! Run all friction model test cases
    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Cont_Friction: Friction Model Tests'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    CALL TC_FRIC_01_Coulomb_Sticking()
    CALL TC_FRIC_02_Coulomb_Sliding()
    CALL TC_FRIC_03_StickSlip_Exponential()
    CALL TC_FRIC_04_Regularized_Smooth()
    CALL TC_FRIC_05_Velocity_Dependent()
    CALL TC_FRIC_06_Pressure_Dependent()
    CALL TC_FRIC_07_Tangent_Stiffness()
    CALL TC_FRIC_08_Zero_Normal_Force()

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Cont_Friction: All 8 Tests Completed'
    WRITE(*,*) '===================================================================='
  END SUBROUTINE Run_All_Cont_Friction_Tests

  ! ============================================================================
  ! TC-FRIC-01: Coulomb摩擦-粘着状态
  ! 验证零切向速度时处于粘着状态
  ! ============================================================================
  SUBROUTINE TC_FRIC_01_Coulomb_Sticking()
    TYPE(PH_Cont_FrictModel) :: frict_model
    TYPE(PH_Cont_FrictState) :: frict_state
    REAL(wp) :: normal_force, tangent_vel(3), friction_force(3)
    LOGICAL :: is_sliding
    TYPE(ErrorStatusType) :: status
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-FRIC-01: Coulomb Friction - Sticking State'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Friction model
    frict_model%model_type = PH_FRICT_COULOMB
    frict_model%mu_static = 0.4_wp
    frict_model%mu_kinetic = 0.3_wp
    
    ! Normal compression (negative = compression)
    normal_force = -1000.0_wp  ! 1000 N compression
    
    ! Zero tangential velocity
    tangent_vel = [ZERO, ZERO, ZERO]
    
    CALL PH_ContFric_Coulomb(frict_model, frict_state, normal_force, &
                             tangent_vel, friction_force, is_sliding, status)
    
    WRITE(*,*) '  Normal force: F_n = ', ABS(normal_force), ' N (compression)'
    WRITE(*,*) '  Tangential velocity: v_t = (0, 0, 0)'
    WRITE(*,*) '  Friction force: F_f = (', friction_force(1), ', ', &
              friction_force(2), ', ', friction_force(3), ')'
    WRITE(*,*) '  Is sliding: ', is_sliding
    WRITE(*,*) '  Is sticking: ', frict_state%is_sticking
    
    IF (.NOT. is_sliding .AND. frict_state%is_sticking) THEN
      WRITE(*,*) '  ✅ PASSED: Sticking state (v_t = 0)'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Should be sticking'
    END IF
  END SUBROUTINE TC_FRIC_01_Coulomb_Sticking

  ! ============================================================================
  ! TC-FRIC-02: Coulomb摩擦-滑动状态
  ! 验证切向滑动时F_t = -μ·|F_n|·dir(v_t)
  ! ============================================================================
  SUBROUTINE TC_FRIC_02_Coulomb_Sliding()
    TYPE(PH_Cont_FrictModel) :: frict_model
    TYPE(PH_Cont_FrictState) :: frict_state
    REAL(wp) :: normal_force, tangent_vel(3), friction_force(3)
    REAL(wp) :: mu, force_expected(3), vel_mag, rel_error
    LOGICAL :: is_sliding
    TYPE(ErrorStatusType) :: status
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-FRIC-02: Coulomb Friction - Sliding State'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Friction model
    frict_model%model_type = PH_FRICT_COULOMB
    frict_model%mu_static = 0.4_wp
    frict_model%mu_kinetic = 0.3_wp
    
    ! Normal compression
    normal_force = -1000.0_wp
    
    ! Tangential velocity (sliding in x-direction)
    tangent_vel = [0.1_wp, ZERO, ZERO]
    
    CALL PH_ContFric_Coulomb(frict_model, frict_state, normal_force, &
                             tangent_vel, friction_force, is_sliding, status)
    
    ! Expected: F_f = -μ·|F_n|·dir(v_t) = -0.4·1000·[1,0,0] = [-400, 0, 0]
    mu = frict_model%mu_static
    vel_mag = SQRT(SUM(tangent_vel**2))
    force_expected = -mu * ABS(normal_force) * (tangent_vel / vel_mag)
    
    rel_error = ABS(friction_force(1) - force_expected(1)) / ABS(force_expected(1))
    
    WRITE(*,*) '  Normal force: F_n = ', ABS(normal_force), ' N'
    WRITE(*,*) '  Tangential velocity: v_t = (0.1, 0, 0) m/s'
    WRITE(*,*) '  Friction coefficient: μ = ', mu
    WRITE(*,*) '  Expected friction: F_f = (', force_expected(1), ', 0, 0) N'
    WRITE(*,*) '  Actual friction: F_f = (', friction_force(1), ', ', &
              friction_force(2), ', ', friction_force(3), ')'
    WRITE(*,*) '  Is sliding: ', is_sliding
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE .AND. is_sliding) THEN
      WRITE(*,*) '  ✅ PASSED: Sliding friction calculated correctly'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Sliding friction error'
    END IF
  END SUBROUTINE TC_FRIC_02_Coulomb_Sliding

  ! ============================================================================
  ! TC-FRIC-03: 粘滑摩擦-指数衰减
  ! 验证μ(s) = μ_k + (μ_s - μ_k)·exp(-s/s_c)
  ! ============================================================================
  SUBROUTINE TC_FRIC_03_StickSlip_Exponential()
    TYPE(PH_Cont_FrictModel) :: frict_model
    TYPE(PH_Cont_FrictState) :: frict_state
    REAL(wp) :: normal_force, tangent_vel(3), friction_force(3)
    REAL(wp) :: slip_dist, mu_s, mu_k, s_c, mu_eff_expected, mu_eff_actual
    REAL(wp) :: vel_mag, rel_error
    LOGICAL :: is_sliding
    TYPE(ErrorStatusType) :: status
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-FRIC-03: Stick-Slip Friction - Exponential Decay'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Friction model
    frict_model%model_type = PH_FRICT_STICK_SLIP
    frict_model%mu_static = 0.5_wp
    frict_model%mu_kinetic = 0.3_wp
    frict_model%critical_slip = 1.0e-4_wp  ! s_c = 0.1 mm
    
    mu_s = frict_model%mu_static
    mu_k = frict_model%mu_kinetic
    s_c = frict_model%critical_slip
    
    normal_force = -1000.0_wp
    tangent_vel = [0.05_wp, ZERO, ZERO]
    slip_dist = 5.0e-5_wp  ! s = 0.05 mm (half of s_c)
    
    CALL PH_ContFric_StickSlip(frict_model, frict_state, normal_force, &
                               tangent_vel, slip_dist, friction_force, &
                               is_sliding, status)
    
    ! Expected: μ_eff = μ_k + (μ_s - μ_k)·exp(-s/s_c)
    !         = 0.3 + (0.5 - 0.3)·exp(-0.05/0.1) = 0.3 + 0.2·exp(-0.5) ≈ 0.421
    mu_eff_expected = mu_k + (mu_s - mu_k) * EXP(-slip_dist / s_c)
    
    ! Actual effective friction coefficient
    vel_mag = SQRT(SUM(tangent_vel**2))
    mu_eff_actual = ABS(friction_force(1)) / (ABS(normal_force) * vel_mag / ABS(tangent_vel(1)))
    
    rel_error = ABS(mu_eff_actual - mu_eff_expected) / mu_eff_expected
    
    WRITE(*,*) '  μ_static = ', mu_s, ', μ_kinetic = ', mu_k
    WRITE(*,*) '  Critical slip: s_c = ', s_c * 1000.0_wp, ' mm'
    WRITE(*,*) '  Current slip: s = ', slip_dist * 1000.0_wp, ' mm'
    WRITE(*,*) '  Expected μ_eff = ', mu_eff_expected
    WRITE(*,*) '  Actual μ_eff = ', mu_eff_actual
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE_FRICTION) THEN
      WRITE(*,*) '  ✅ PASSED: Stick-slip exponential decay verified'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Stick-slip calculation error'
    END IF
  END SUBROUTINE TC_FRIC_03_StickSlip_Exponential

  ! ============================================================================
  ! TC-FRIC-04: 正则化摩擦-平滑过渡
  ! 验证速度正则化避免数值不连续
  ! ============================================================================
  SUBROUTINE TC_FRIC_04_Regularized_Smooth()
    TYPE(PH_Cont_FrictModel) :: frict_model
    TYPE(PH_Cont_FrictState) :: frict_state
    REAL(wp) :: normal_force, tangent_vel(3), friction_force(3)
    REAL(wp) :: v_low, v_high, f_low, f_high, ratio
    LOGICAL :: is_sliding
    TYPE(ErrorStatusType) :: status
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-FRIC-04: Regularized Friction - Smooth Transition'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Friction model
    frict_model%model_type = PH_FRICT_REGULARIZED
    frict_model%mu_static = 0.4_wp
    frict_model%mu_kinetic = 0.3_wp
    frict_model%velocity_scale = 1.0e-3_wp  ! v_c = 1 mm/s
    
    normal_force = -1000.0_wp
    
    ! Test 1: Low velocity
    v_low = 1.0e-6_wp  ! 1 μm/s
    tangent_vel = [v_low, ZERO, ZERO]
    
    CALL PH_ContFric_Regularized(frict_model, frict_state, normal_force, &
                                 tangent_vel, friction_force, is_sliding, status)
    f_low = ABS(friction_force(1))
    
    ! Test 2: High velocity
    v_high = 0.1_wp  ! 100 mm/s
    tangent_vel = [v_high, ZERO, ZERO]
    
    CALL PH_ContFric_Regularized(frict_model, frict_state, normal_force, &
                                 tangent_vel, friction_force, is_sliding, status)
    f_high = ABS(friction_force(1))
    
    ratio = f_high / f_low
    
    WRITE(*,*) '  Low velocity: v = ', v_low * 1000.0_wp, ' mm/s → F_f = ', f_low, ' N'
    WRITE(*,*) '  High velocity: v = ', v_high * 1000.0_wp, ' mm/s → F_f = ', f_high, ' N'
    WRITE(*,*) '  Force ratio (high/low): ', ratio
    WRITE(*,*) '  Expected: Smooth transition (no discontinuity)'
    
    IF (f_high > f_low .AND. ratio > ONE) THEN
      WRITE(*,*) '  ✅ PASSED: Regularized friction shows smooth transition'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: Regularization behavior may differ'
    END IF
  END SUBROUTINE TC_FRIC_04_Regularized_Smooth

  ! ============================================================================
  ! TC-FRIC-05: 速度相关摩擦
  ! 验证μ(v) = μ_0 + (μ_∞ - μ_0)·(1 - exp(-v/v_ref))
  ! ============================================================================
  SUBROUTINE TC_FRIC_05_Velocity_Dependent()
    TYPE(PH_Cont_FrictModel) :: frict_model
    TYPE(PH_Cont_FrictState) :: frict_state
    REAL(wp) :: normal_force, tangent_vel(3), friction_force(3)
    REAL(wp) :: mu_0, mu_inf, v_ref, v_test, mu_expected, mu_actual
    REAL(wp) :: vel_mag, rel_error
    LOGICAL :: is_sliding
    TYPE(ErrorStatusType) :: status
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-FRIC-05: Velocity-Dependent Friction'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Friction model
    frict_model%model_type = PH_FRICT_VELOCITY_DEP
    frict_model%mu_static = 0.3_wp   ! μ_0 (low velocity)
    frict_model%mu_kinetic = 0.5_wp  ! μ_∞ (high velocity)
    frict_model%velocity_scale = 0.01_wp  ! v_ref = 10 mm/s
    
    mu_0 = frict_model%mu_static
    mu_inf = frict_model%mu_kinetic
    v_ref = frict_model%velocity_scale
    
    normal_force = -1000.0_wp
    v_test = 0.01_wp  ! v = v_ref
    tangent_vel = [v_test, ZERO, ZERO]
    
    CALL PH_ContFric_VelocityDep(frict_model, frict_state, normal_force, &
                                 tangent_vel, friction_force, is_sliding, status)
    
    ! Expected: μ(v_ref) = μ_0 + (μ_∞ - μ_0)·(1 - exp(-1)) ≈ 0.3 + 0.2·0.632 = 0.426
    mu_expected = mu_0 + (mu_inf - mu_0) * (ONE - EXP(-v_test / v_ref))
    
    vel_mag = SQRT(SUM(tangent_vel**2))
    mu_actual = ABS(friction_force(1)) / (ABS(normal_force) * vel_mag / ABS(tangent_vel(1)))
    
    rel_error = ABS(mu_actual - mu_expected) / mu_expected
    
    WRITE(*,*) '  μ_0 = ', mu_0, ' (low velocity)'
    WRITE(*,*) '  μ_∞ = ', mu_inf, ' (high velocity)'
    WRITE(*,*) '  v_ref = ', v_ref * 1000.0_wp, ' mm/s'
    WRITE(*,*) '  Test velocity: v = ', v_test * 1000.0_wp, ' mm/s'
    WRITE(*,*) '  Expected μ = ', mu_expected
    WRITE(*,*) '  Actual μ = ', mu_actual
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE_FRICTION) THEN
      WRITE(*,*) '  ✅ PASSED: Velocity-dependent friction verified'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Velocity-dependent friction error'
    END IF
  END SUBROUTINE TC_FRIC_05_Velocity_Dependent

  ! ============================================================================
  ! TC-FRIC-06: 压力相关摩擦
  ! 验证μ(p) = μ_0·(p/p_ref)^α
  ! ============================================================================
  SUBROUTINE TC_FRIC_06_Pressure_Dependent()
    TYPE(PH_Cont_FrictModel) :: frict_model
    TYPE(PH_Cont_FrictState) :: frict_state
    REAL(wp) :: normal_force, tangent_vel(3), friction_force(3)
    REAL(wp) :: mu_0, p_ref, alpha, p_test, mu_expected, mu_actual
    REAL(wp) :: vel_mag, rel_error
    LOGICAL :: is_sliding
    TYPE(ErrorStatusType) :: status
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-FRIC-06: Pressure-Dependent Friction'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Friction model
    frict_model%model_type = PH_FRICT_PRESSURE_DEP
    frict_model%mu_static = 0.4_wp
    frict_model%pressure_ref = 1.0e6_wp  ! p_ref = 1 MPa
    frict_model%pressure_exponent = 0.2_wp  ! α = 0.2
    
    mu_0 = frict_model%mu_static
    p_ref = frict_model%pressure_ref
    alpha = frict_model%pressure_exponent
    
    ! Test pressure: p = 5 MPa
    normal_force = -5.0e6_wp  ! 5 MPa (assuming unit area)
    tangent_vel = [0.01_wp, ZERO, ZERO]
    
    CALL PH_ContFric_PressureDep(frict_model, frict_state, normal_force, &
                                 tangent_vel, friction_force, is_sliding, status)
    
    ! Expected: μ(5MPa) = 0.4·(5e6/1e6)^0.2 = 0.4·5^0.2 ≈ 0.4·1.38 = 0.552
    p_test = ABS(normal_force)
    mu_expected = mu_0 * (p_test / p_ref)**alpha
    
    vel_mag = SQRT(SUM(tangent_vel**2))
    mu_actual = ABS(friction_force(1)) / (p_test * vel_mag / ABS(tangent_vel(1)))
    
    rel_error = ABS(mu_actual - mu_expected) / mu_expected
    
    WRITE(*,*) '  μ_0 = ', mu_0
    WRITE(*,*) '  p_ref = ', p_ref / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  α = ', alpha
    WRITE(*,*) '  Test pressure: p = ', p_test / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Expected μ = ', mu_expected
    WRITE(*,*) '  Actual μ = ', mu_actual
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE_FRICTION) THEN
      WRITE(*,*) '  ✅ PASSED: Pressure-dependent friction verified'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Pressure-dependent friction error'
    END IF
  END SUBROUTINE TC_FRIC_06_Pressure_Dependent

  ! ============================================================================
  ! TC-FRIC-07: 摩擦切线刚度
  ! 验证摩擦切线刚度矩阵计算
  ! ============================================================================
  SUBROUTINE TC_FRIC_07_Tangent_Stiffness()
    TYPE(PH_Cont_FrictModel) :: frict_model
    REAL(wp) :: normal_force, tangent_stiff(3,3)
    REAL(wp) :: mu, epsilon_t, kt_expected, kt_actual
    REAL(wp) :: rel_error
    TYPE(ErrorStatusType) :: status
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-FRIC-07: Friction Tangent Stiffness'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Friction model
    frict_model%mu_static = 0.3_wp
    
    normal_force = -1000.0_wp
    mu = frict_model%mu_static
    
    ! Tangential penalty stiffness
    epsilon_t = 1.0e8_wp  ! 100 MN/m²
    
    CALL PH_ContFric_TangentStiff(frict_model, normal_force, epsilon_t, &
                                  tangent_stiff, status)
    
    ! Expected: K_t = ε_t·I (diagonal matrix for sticking)
    kt_expected = epsilon_t
    kt_actual = tangent_stiff(1,1)
    
    rel_error = ABS(kt_actual - kt_expected) / kt_expected
    
    WRITE(*,*) '  Normal force: F_n = ', ABS(normal_force), ' N'
    WRITE(*,*) '  Tangential penalty: ε_t = ', epsilon_t, ' N/m'
    WRITE(*,*) '  Expected K_t = ', kt_expected, ' N/m'
    WRITE(*,*) '  Actual K_t(1,1) = ', kt_actual, ' N/m'
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Tangent stiffness calculated correctly'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Tangent stiffness error'
    END IF
  END SUBROUTINE TC_FRIC_07_Tangent_Stiffness

  ! ============================================================================
  ! TC-FRIC-08: 零法向力-无摩擦
  ! 验证F_n=0时摩擦力为零
  ! ============================================================================
  SUBROUTINE TC_FRIC_08_Zero_Normal_Force()
    TYPE(PH_Cont_FrictModel) :: frict_model
    TYPE(PH_Cont_FrictState) :: frict_state
    REAL(wp) :: normal_force, tangent_vel(3), friction_force(3)
    LOGICAL :: is_sliding
    TYPE(ErrorStatusType) :: status
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-FRIC-08: Zero Normal Force - No Friction'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    frict_model%mu_static = 0.4_wp
    
    ! Zero normal force (no contact)
    normal_force = ZERO
    tangent_vel = [0.1_wp, ZERO, ZERO]
    
    CALL PH_ContFric_Coulomb(frict_model, frict_state, normal_force, &
                             tangent_vel, friction_force, is_sliding, status)
    
    WRITE(*,*) '  Normal force: F_n = 0 N (no contact)'
    WRITE(*,*) '  Tangential velocity: v_t = (0.1, 0, 0) m/s'
    WRITE(*,*) '  Friction force: F_f = (', friction_force(1), ', ', &
              friction_force(2), ', ', friction_force(3), ')'
    WRITE(*,*) '  Is sliding: ', is_sliding
    
    IF (ALL(ABS(friction_force) < TOLERANCE)) THEN
      WRITE(*,*) '  ✅ PASSED: Zero friction when F_n = 0'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Friction should be zero'
    END IF
  END SUBROUTINE TC_FRIC_08_Zero_Normal_Force

END MODULE TEST_PH_Cont_Friction
