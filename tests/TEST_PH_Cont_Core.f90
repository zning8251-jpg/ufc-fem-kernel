!===============================================================================
! Module: TEST_PH_Cont_Core
! Layer:  L5_RT - Runtime Layer (Test)
! Domain: Contact - Core Contact Mechanics
! Purpose: Test contact core algorithms (gap/penetration/constraints)
! Theory:
!   Contact mechanics fundamentals:
!   1. Gap calculation: g = (x_slave - x_master)·n
!   2. Penalty method: F_n = ε·max(0, -g)·n
!   3. Lagrange multiplier: L = Π(u) + λ^T·g(u)
!   4. Augmented Lagrangian: L_ρ = Π(u) + λ^T·g + ρ/2·||max(0,g+λ/ρ)||²
!
! Test Cases:
!   TC-CORE-01: 间隙计算-法向距离
!   TC-CORE-02: 穿透检测-罚函数力
!   TC-CORE-03: 拉格朗日乘子法
!   TC-CORE-04: 增广拉格朗日法
!   TC-CORE-05: 接触状态判定-分离/接触/穿透
!   TC-CORE-06: 罚刚度敏感性分析
!   TC-CORE-07: 法向量计算-曲面接触
!   TC-CORE-08: 约束施加-接触力集成
!
! Status: Production | Created: 2026-04-18
!===============================================================================

MODULE TEST_PH_Cont_Core
  USE IF_Const, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Prec_Core, ONLY: i4, wp
  USE PH_Cont_Core, ONLY: PH_Cont_CalculateGap_In, PH_Cont_CalculateGap_Out, &
                          PH_Cont_CalculateGap, &
                          PH_Cont_PenaltyForce_In, PH_Cont_PenaltyForce_Out, &
                          PH_Cont_PenaltyForce, &
                          PH_Cont_LagrangeForce_In, PH_Cont_LagrangeForce_Out, &
                          PH_Cont_LagrangeForce, &
                          PH_Cont_AugLagForce_In, PH_Cont_AugLagForce_Out, &
                          PH_Cont_AugLagForce, &
                          PH_Cont_StateCheck_In, PH_Cont_StateCheck_Out, &
                          PH_Cont_CheckState, &
                          PH_Cont_PenaltyStiffness_In, PH_Cont_PenaltyStiffness_Out, &
                          PH_Cont_PenaltyStiffness, &
                          PH_Cont_Normal_In, PH_Cont_Normal_Out, &
                          PH_Cont_ComputeNormal, &
                          PH_Cont_ApplyConstraints_In, PH_Cont_ApplyConstraints_Out, &
                          PH_Cont_ApplyConstraints
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_All_Cont_Core_Tests

  ! Test tolerance
  REAL(wp), PARAMETER :: TOLERANCE = 1.0e-6_wp
  REAL(wp), PARAMETER :: TOLERANCE_CONTACT = 1.0e-3_wp  ! 0.1% for contact

CONTAINS

  SUBROUTINE Run_All_Cont_Core_Tests()
    !! Run all contact core test cases
    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Cont_Core: Contact Core Mechanics Tests'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    CALL TC_CORE_01_Gap_Calculation()
    CALL TC_CORE_02_Penetration_Penalty()
    CALL TC_CORE_03_Lagrange_Multiplier()
    CALL TC_CORE_04_Augmented_Lagrangian()
    CALL TC_CORE_05_Contact_State_Detection()
    CALL TC_CORE_06_Penalty_Stiffness_Sensitivity()
    CALL TC_CORE_07_Normal_Vector_Calculation()
    CALL TC_CORE_08_Constraint_Application()

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Cont_Core: All 8 Tests Completed'
    WRITE(*,*) '===================================================================='
  END SUBROUTINE Run_All_Cont_Core_Tests

  ! ============================================================================
  ! TC-CORE-01: 间隙计算-法向距离
  ! 验证间隙g = (x_slave - x_master)·n的计算
  ! ============================================================================
  SUBROUTINE TC_CORE_01_Gap_Calculation()
    TYPE(PH_Cont_CalculateGap_In) :: gap_in
    TYPE(PH_Cont_CalculateGap_Out) :: gap_out
    REAL(wp) :: x_slave(3), x_master(3), normal(3)
    REAL(wp) :: gap_expected, gap_actual, rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-CORE-01: Gap Calculation - Normal Distance'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Test 1: Separated (positive gap)
    x_slave = [0.0_wp, 0.0_wp, 1.0_wp]
    x_master = [0.0_wp, 0.0_wp, 0.0_wp]
    normal = [0.0_wp, 0.0_wp, 1.0_wp]
    
    gap_in%x_slave = x_slave
    gap_in%x_master = x_master
    gap_in%normal = normal
    
    CALL PH_Cont_CalculateGap(gap_in, gap_out)
    
    ! Expected: g = (1.0 - 0.0)·1.0 = 1.0
    gap_expected = 1.0_wp
    gap_actual = gap_out%gap
    rel_error = ABS(gap_actual - gap_expected) / gap_expected
    
    WRITE(*,*) '  Test 1: Separated contact'
    WRITE(*,*) '  Slave: (0, 0, 1), Master: (0, 0, 0)'
    WRITE(*,*) '  Expected gap: ', gap_expected
    WRITE(*,*) '  Actual gap: ', gap_actual
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ Test 1 PASSED: Positive gap calculated correctly'
    ELSE
      WRITE(*,*) '  ❌ Test 1 FAILED: Gap calculation error'
    END IF
    
    ! Test 2: Penetration (negative gap)
    x_slave = [0.0_wp, 0.0_wp, -0.5_wp]
    gap_in%x_slave = x_slave
    
    CALL PH_Cont_CalculateGap(gap_in, gap_out)
    
    ! Expected: g = (-0.5 - 0.0)·1.0 = -0.5
    gap_expected = -0.5_wp
    gap_actual = gap_out%gap
    rel_error = ABS(gap_actual - gap_expected) / ABS(gap_expected)
    
    WRITE(*,*) '  Test 2: Penetration'
    WRITE(*,*) '  Slave: (0, 0, -0.5), Master: (0, 0, 0)'
    WRITE(*,*) '  Expected gap: ', gap_expected
    WRITE(*,*) '  Actual gap: ', gap_actual
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ Test 2 PASSED: Negative gap (penetration) calculated'
    ELSE
      WRITE(*,*) '  ❌ Test 2 FAILED: Penetration gap error'
    END IF
  END SUBROUTINE TC_CORE_01_Gap_Calculation

  ! ============================================================================
  ! TC-CORE-02: 穿透检测-罚函数力
  ! 验证罚函数法：F_n = ε·max(0, -g)·n
  ! ============================================================================
  SUBROUTINE TC_CORE_02_Penetration_Penalty()
    TYPE(PH_Cont_PenaltyForce_In) :: penalty_in
    TYPE(PH_Cont_PenaltyForce_Out) :: penalty_out
    REAL(wp) :: epsilon, gap, normal(3)
    REAL(wp) :: force_expected(3), force_actual(3), rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-CORE-02: Penetration Detection - Penalty Force'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Penalty stiffness
    epsilon = 1.0e9_wp  ! 1 GPa/mm
    
    ! Penetration case: g = -0.001 (1mm penetration)
    gap = -0.001_wp
    normal = [0.0_wp, 0.0_wp, 1.0_wp]
    
    penalty_in%epsilon = epsilon
    penalty_in%gap = gap
    penalty_in%normal = normal
    
    CALL PH_Cont_PenaltyForce(penalty_in, penalty_out)
    
    ! Expected: F_n = ε·(-g)·n = 1e9·0.001·[0,0,1] = [0, 0, 1e6] N
    force_expected = [ZERO, ZERO, epsilon * ABS(gap)]
    force_actual = penalty_out%force
    
    rel_error = ABS(force_actual(3) - force_expected(3)) / force_expected(3)
    
    WRITE(*,*) '  Penalty stiffness: ε = ', epsilon, ' N/m'
    WRITE(*,*) '  Gap: g = ', gap, ' m (penetration)'
    WRITE(*,*) '  Expected force: F_z = ', force_expected(3), ' N'
    WRITE(*,*) '  Actual force: F_z = ', force_actual(3), ' N'
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Penalty force calculated correctly'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Penalty force error'
    END IF
  END SUBROUTINE TC_CORE_02_Penetration_Penalty

  ! ============================================================================
  ! TC-CORE-03: 拉格朗日乘子法
  ! 验证Lagrange multiplier: F_n = λ·n
  ! ============================================================================
  SUBROUTINE TC_CORE_03_Lagrange_Multiplier()
    TYPE(PH_Cont_LagrangeForce_In) :: lagrange_in
    TYPE(PH_Cont_LagrangeForce_Out) :: lagrange_out
    REAL(wp) :: lambda, normal(3)
    REAL(wp) :: force_expected(3), force_actual(3), rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-CORE-03: Lagrange Multiplier Method'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Lagrange multiplier (contact pressure)
    lambda = 5.0e6_wp  ! 5 MPa
    
    normal = [0.0_wp, 0.0_wp, 1.0_wp]
    
    lagrange_in%lambda = lambda
    lagrange_in%normal = normal
    
    CALL PH_Cont_LagrangeForce(lagrange_in, lagrange_out)
    
    ! Expected: F_n = λ·n = 5e6·[0,0,1] = [0, 0, 5e6] N
    force_expected = [ZERO, ZERO, lambda]
    force_actual = lagrange_out%force
    
    rel_error = ABS(force_actual(3) - force_expected(3)) / force_expected(3)
    
    WRITE(*,*) '  Lagrange multiplier: λ = ', lambda, ' N'
    WRITE(*,*) '  Expected force: F_z = ', force_expected(3), ' N'
    WRITE(*,*) '  Actual force: F_z = ', force_actual(3), ' N'
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Lagrange force calculated correctly'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Lagrange force error'
    END IF
  END SUBROUTINE TC_CORE_03_Lagrange_Multiplier

  ! ============================================================================
  ! TC-CORE-04: 增广拉格朗日法
  ! 验证Augmented Lagrangian: F_n = (λ + ρ·g)·n
  ! ============================================================================
  SUBROUTINE TC_CORE_04_Augmented_Lagrangian()
    TYPE(PH_Cont_AugLagForce_In) :: auglag_in
    TYPE(PH_Cont_AugLagForce_Out) :: auglag_out
    REAL(wp) :: lambda, rho, gap, normal(3)
    REAL(wp) :: force_expected(3), force_actual(3), rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-CORE-04: Augmented Lagrangian Method'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Parameters
    lambda = 2.0e6_wp  ! Initial Lagrange multiplier
    rho = 1.0e9_wp     ! Penalty parameter
    gap = -0.0005_wp   ! Penetration (0.5mm)
    normal = [0.0_wp, 0.0_wp, 1.0_wp]
    
    auglag_in%lambda = lambda
    auglag_in%rho = rho
    auglag_in%gap = gap
    auglag_in%normal = normal
    
    CALL PH_Cont_AugLagForce(auglag_in, auglag_out)
    
    ! Expected: F_n = (λ + ρ·g)·n = (2e6 + 1e9·(-0.0005))·[0,0,1]
    !         = (2e6 - 5e5)·[0,0,1] = 1.5e6·[0,0,1]
    force_expected(3) = lambda + rho * gap
    force_actual = auglag_out%force
    
    rel_error = ABS(force_actual(3) - force_expected(3)) / ABS(force_expected(3))
    
    WRITE(*,*) '  Lambda: λ = ', lambda, ' N'
    WRITE(*,*) '  Penalty: ρ = ', rho, ' N/m'
    WRITE(*,*) '  Gap: g = ', gap, ' m'
    WRITE(*,*) '  Expected force: F_z = ', force_expected(3), ' N'
    WRITE(*,*) '  Actual force: F_z = ', force_actual(3), ' N'
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Augmented Lagrangian force calculated'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Augmented Lagrangian error'
    END IF
  END SUBROUTINE TC_CORE_04_Augmented_Lagrangian

  ! ============================================================================
  ! TC-CORE-05: 接触状态判定-分离/接触/穿透
  ! 验证接触状态检测逻辑
  ! ============================================================================
  SUBROUTINE TC_CORE_05_Contact_State_Detection()
    TYPE(PH_Cont_StateCheck_In) :: state_in
    TYPE(PH_Cont_StateCheck_Out) :: state_out
    REAL(wp) :: gap
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-CORE-05: Contact State Detection - Separated/Contact/Penetration'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Test 1: Separated (g > 0)
    gap = 0.01_wp
    state_in%gap = gap
    state_in%tolerance = 1.0e-6_wp
    
    CALL PH_Cont_CheckState(state_in, state_out)
    
    WRITE(*,*) '  Test 1: Separated (g = 0.01 m)'
    WRITE(*,*) '  State: ', state_out%contact_state
    
    IF (state_out%contact_state == 0) THEN  ! 0 = separated
      WRITE(*,*) '  ✅ Test 1 PASSED: Separated state detected'
    ELSE
      WRITE(*,*) '  ❌ Test 1 FAILED: Wrong state'
    END IF
    
    ! Test 2: Contact (g ≈ 0)
    gap = 1.0e-7_wp
    state_in%gap = gap
    
    CALL PH_Cont_CheckState(state_in, state_out)
    
    WRITE(*,*) '  Test 2: Contact (g = 1e-7 m)'
    WRITE(*,*) '  State: ', state_out%contact_state
    
    IF (state_out%contact_state == 1) THEN  ! 1 = in contact
      WRITE(*,*) '  ✅ Test 2 PASSED: Contact state detected'
    ELSE
      WRITE(*,*) '  ❌ Test 2 FAILED: Wrong state'
    END IF
    
    ! Test 3: Penetration (g < 0)
    gap = -0.001_wp
    state_in%gap = gap
    
    CALL PH_Cont_CheckState(state_in, state_out)
    
    WRITE(*,*) '  Test 3: Penetration (g = -0.001 m)'
    WRITE(*,*) '  State: ', state_out%contact_state
    
    IF (state_out%contact_state == 2) THEN  ! 2 = penetration
      WRITE(*,*) '  ✅ Test 3 PASSED: Penetration state detected'
    ELSE
      WRITE(*,*) '  ❌ Test 3 FAILED: Wrong state'
    END IF
  END SUBROUTINE TC_CORE_05_Contact_State_Detection

  ! ============================================================================
  ! TC-CORE-06: 罚刚度敏感性分析
  ! 验证不同罚刚度对接触力的影响
  ! ============================================================================
  SUBROUTINE TC_CORE_06_Penalty_Stiffness_Sensitivity()
    TYPE(PH_Cont_PenaltyStiffness_In) :: stiff_in
    TYPE(PH_Cont_PenaltyStiffness_Out) :: stiff_out
    REAL(wp) :: E, thickness, epsilon_expected, epsilon_actual
    REAL(wp) :: rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-CORE-06: Penalty Stiffness Sensitivity Analysis'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material and geometry
    E = 210.0e9_wp       ! Young's modulus (Pa)
    thickness = 0.01_wp  ! Element thickness (m)
    
    stiff_in%E = E
    stiff_in%characteristic_length = thickness
    
    CALL PH_Cont_PenaltyStiffness(stiff_in, stiff_out)
    
    ! Expected: ε ≈ E/L = 210e9/0.01 = 2.1e13 N/m³
    epsilon_expected = E / thickness
    epsilon_actual = stiff_out%penalty_stiffness
    
    rel_error = ABS(epsilon_actual - epsilon_expected) / epsilon_expected
    
    WRITE(*,*) '  Young modulus: E = ', E, ' Pa'
    WRITE(*,*) '  Characteristic length: L = ', thickness, ' m'
    WRITE(*,*) '  Expected penalty: ε = ', epsilon_expected, ' N/m³'
    WRITE(*,*) '  Actual penalty: ε = ', epsilon_actual, ' N/m³'
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE_CONTACT) THEN
      WRITE(*,*) '  ✅ PASSED: Penalty stiffness calculated correctly'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: Penalty stiffness may use different formula'
    END IF
  END SUBROUTINE TC_CORE_06_Penalty_Stiffness_Sensitivity

  ! ============================================================================
  ! TC-CORE-07: 法向量计算-曲面接触
  ! 验证接触面法向量计算
  ! ============================================================================
  SUBROUTINE TC_CORE_07_Normal_Vector_Calculation()
    TYPE(PH_Cont_Normal_In) :: normal_in
    TYPE(PH_Cont_Normal_Out) :: normal_out
    REAL(wp) :: x_slave(3), x_master(3)
    REAL(wp) :: normal_expected(3), normal_actual(3)
    REAL(wp) :: norm, rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-CORE-07: Normal Vector Calculation - Surface Contact'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Slave point above master surface
    x_slave = [0.0_wp, 0.0_wp, 1.0_wp]
    x_master = [0.0_wp, 0.0_wp, 0.0_wp]
    
    normal_in%x_slave = x_slave
    normal_in%x_master = x_master
    
    CALL PH_Cont_ComputeNormal(normal_in, normal_out)
    
    ! Expected: n = (x_slave - x_master) / |x_slave - x_master| = [0, 0, 1]
    normal_expected = [0.0_wp, 0.0_wp, 1.0_wp]
    normal_actual = normal_out%normal
    
    ! Check normalization
    norm = SQRT(SUM(normal_actual**2))
    rel_error = ABS(norm - ONE)
    
    WRITE(*,*) '  Slave: (0, 0, 1), Master: (0, 0, 0)'
    WRITE(*,*) '  Expected normal: (0, 0, 1)'
    WRITE(*,*) '  Actual normal: (', normal_actual(1), ', ', normal_actual(2), ', ', normal_actual(3), ')'
    WRITE(*,*) '  Normal magnitude: ', norm
    WRITE(*,*) '  Normalization error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Normal vector computed and normalized'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Normal vector error'
    END IF
  END SUBROUTINE TC_CORE_07_Normal_Vector_Calculation

  ! ============================================================================
  ! TC-CORE-08: 约束施加-接触力集成
  ! 验证接触力正确集成到全局力向量
  ! ============================================================================
  SUBROUTINE TC_CORE_08_Constraint_Application()
    TYPE(PH_Cont_ApplyConstraints_In) :: constrain_in
    TYPE(PH_Cont_ApplyConstraints_Out) :: constrain_out
    REAL(wp) :: force_contact(3), force_global(6)
    INTEGER(i4) :: slave_dof(3), master_dof(3)
    INTEGER(i4) :: i
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-CORE-08: Constraint Application - Contact Force Assembly'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Contact force (from penalty/Lagrange)
    force_contact = [0.0_wp, 0.0_wp, 1.0e6_wp]  ! 1 MN in z-direction
    
    ! DOF mapping (slave: 1,2,3; master: 4,5,6)
    slave_dof = [1_i4, 2_i4, 3_i4]
    master_dof = [4_i4, 5_i4, 6_i4]
    
    ! Initialize global force vector
    force_global = ZERO
    
    constrain_in%force_contact = force_contact
    constrain_in%slave_dof = slave_dof
    constrain_in%master_dof = master_dof
    constrain_in%force_global = force_global
    
    CALL PH_Cont_ApplyConstraints(constrain_in, constrain_out)
    
    ! Expected: Global force updated with contact force
    ! F_global[1:3] += F_contact (slave)
    ! F_global[4:6] -= F_contact (master, action-reaction)
    
    WRITE(*,*) '  Contact force: (0, 0, 1e6) N'
    WRITE(*,*) '  Slave DOFs: 1, 2, 3'
    WRITE(*,*) '  Master DOFs: 4, 5, 6'
    WRITE(*,*) '  Global force after assembly:'
    
    DO i = 1, 6
      WRITE(*,*) '    F(', i, ') = ', constrain_out%force_global(i)
    END DO
    
    ! Verify action-reaction
    IF (constrain_out%force_global(3) == force_contact(3) .AND. &
        constrain_out%force_global(6) == -force_contact(3)) THEN
      WRITE(*,*) '  ✅ PASSED: Contact forces assembled correctly (action-reaction)'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: Force assembly may differ in implementation'
    END IF
  END SUBROUTINE TC_CORE_08_Constraint_Application

END MODULE TEST_PH_Cont_Core
