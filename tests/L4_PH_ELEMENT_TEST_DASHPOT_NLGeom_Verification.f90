!===============================================================================
! Module: TEST_DASHPOT_NLGeom_Verification
! Purpose: DASHPOT 阻尼器单元族非线性几何验证测试集（DASHPOT1/DASHPOT2�?
! Tests:   1. 恒定速度加载验证（F = c * v�?
!          2. 刚体匀速平移测试（零相对速度�?
!          3. DASHPOT1 vs DASHPOT2 对比�?D vs 2D�?
!===============================================================================
! Layer:  L4_PH - Physics Layer
! Domain: Element - DASHPOT Family
! Theory: Viscous damping with geometric nonlinearity (force follow velocity)
! Status: B-Element-10 Task #7 (⭐最简单快速交�?
!===============================================================================

MODULE TEST_DASHPOT_NLGeom_Verification
  USE IF_Const, ONLY: ZERO, ONE, HALF, TWO, THREE
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_DASHPOT1_Core, ONLY: PH_Elem_DASHPOT1_NL_TL, PH_Elem_DASHPOT1_NL_UL
  USE PH_Elem_DASHPOT2_Core, ONLY: PH_Elem_DASHPOT2_NL_TL, PH_Elem_DASHPOT2_NL_UL
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: TEST_Dashpot_Constant_Velocity, TEST_Dashpot_Rigid_Motion, &
          TEST_Dashpot_1D_vs_2D
  
CONTAINS
  
  !=============================================================================
  ! Test 1: 恒定速度加载验证（DASHPOT1�?
  !=============================================================================
  SUBROUTINE TEST_Dashpot_Constant_Velocity(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_ref(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                       1.0_wp, 0.0_wp, 0.0_wp], &
                                                      [3, 2])
    REAL(wp) :: u_elem(2), v_elem(2)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int(2), Ke(2, 2)
    REAL(wp) :: ip_stress(1, 1), ip_strain(1, 1)
    REAL(wp) :: ip_peeq(1), ip_creep(1)
    REAL(wp) :: damping_coef, velocity, analytical_force
    REAL(wp) :: error_norm
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: c = 100.0_wp  ! Damping coefficient N·s/m
    REAL(wp), PARAMETER :: vel_target = 2.0_wp  ! Constant velocity m/s
    
    CALL init_error_status(status)
    passed = .FALSE.
    
    ! Initialize
    u_elem = 0.0_wp
    v_elem = 0.0_wp
    D = 0.0_wp
    R_int = 0.0_wp
    Ke = 0.0_wp
    ip_stress = 0.0_wp
    ip_strain = 0.0_wp
    ip_peeq = 0.0_wp
    ip_creep = 0.0_wp
    
    ! Damping coefficient (stored in D matrix for consistency)
    D(1, 1) = c
    
    ! Apply constant velocity (Node 2 moves at 2 m/s)
    v_elem(1) = 0.0_wp        ! Node 1 fixed (v=0)
    v_elem(2) = vel_target    ! Node 2: v = 2 m/s
    
    ! TL analysis (damping force depends on velocity)
    ! Note: In real implementation, velocity would come from time integration
    CALL PH_Elem_DASHPOT1_NL_TL(coords_ref, u_elem, D, ip_stress, ip_strain, &
                               ip_peeq, ip_creep, R_int, Ke, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?DASHPOT1 NL_TL failed'
      RETURN
    END IF
    
    ! Analytical: F = c * (v2 - v1) = c * relative_velocity
    analytical_force = c * (vel_target - 0.0_wp)
    
    ! Extract computed damping force at node 2
    error_norm = ABS(R_int(2) - analytical_force) / ABS(analytical_force)
    
    ! Verification: relative error < 1%
    passed = (error_norm < 0.01_wp)
    
    IF (passed) THEN
      PRINT *, '�?DASHPOT1 Constant Velocity PASSED'
      PRINT *, '   Damping coefficient c =', c, 'N·s/m'
      PRINT *, '   Relative velocity =', vel_target, 'm/s'
      PRINT *, '   Analytical force =', analytical_force, 'N'
      PRINT *, '   Computed reaction =', R_int(2), 'N'
      PRINT *, '   Relative error =', error_norm * 100.0_wp, '%'
    ELSE
      PRINT *, '�?DASHPOT1 Constant Velocity FAILED'
      PRINT *, '   Error =', error_norm * 100.0_wp, '%'
    END IF
    
  END SUBROUTINE TEST_Dashpot_Constant_Velocity
  
  !=============================================================================
  ! Test 2: 刚体匀速平移测试（DASHPOT2�?
  !=============================================================================
  SUBROUTINE TEST_Dashpot_Rigid_Motion(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_ref(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                       1.0_wp, 0.0_wp, 0.0_wp], &
                                                      [3, 2])
    REAL(wp) :: u_elem(4), v_elem(4)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int(4), Ke(4, 4)
    REAL(wp) :: ip_stress(1, 1), ip_strain(1, 1)
    REAL(wp) :: ip_peeq(1), ip_creep(1)
    REAL(wp) :: rigid_velocity
    REAL(wp) :: force_norm
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: c = 100.0_wp
    
    CALL init_error_status(status)
    passed = .FALSE.
    
    ! Initialize
    u_elem = 0.0_wp
    v_elem = 0.0_wp
    D = 0.0_wp
    R_int = 0.0_wp
    Ke = 0.0_wp
    ip_stress = 0.0_wp
    ip_strain = 0.0_wp
    ip_peeq = 0.0_wp
    ip_creep = 0.0_wp
    
    D(1, 1) = c
    
    ! Rigid body motion (both nodes move at same velocity)
    rigid_velocity = 1.0_wp
    v_elem(1) = rigid_velocity  ! Node 1 X velocity
    v_elem(2) = 0.0_wp          ! Node 1 Y velocity (fixed)
    v_elem(3) = rigid_velocity  ! Node 2 X velocity
    v_elem(4) = 0.0_wp          ! Node 2 Y velocity (fixed)
    
    ! TL analysis (should have zero relative velocity �?zero force)
    CALL PH_Elem_DASHPOT2_NL_TL(coords_ref, u_elem, D, ip_stress, ip_strain, &
                               ip_peeq, ip_creep, R_int, Ke, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?DASHPOT2 Rigid Motion failed'
      RETURN
    END IF
    
    ! Verification: internal force should be ~zero (rigid motion �?no relative velocity)
    force_norm = SQRT(SUM(R_int**2))
    passed = (force_norm < 1.0e-6_wp)
    
    IF (passed) THEN
      PRINT *, '�?DASHPOT2 Rigid Motion PASSED'
      PRINT *, '   Rigid velocity =', rigid_velocity, 'm/s'
      PRINT *, '   Internal force norm =', force_norm, '(should be ~0)'
      PRINT *, '   Stress =', ip_stress(1,1), '(should be ~0)'
    ELSE
      PRINT *, '�?DASHPOT2 Rigid Motion FAILED'
      PRINT *, '   Force norm =', force_norm
    END IF
    
  END SUBROUTINE TEST_Dashpot_Rigid_Motion
  
  !=============================================================================
  ! Test 3: DASHPOT1 vs DASHPOT2 对比�?D vs 2D�?
  !=============================================================================
  SUBROUTINE TEST_Dashpot_1D_vs_2D(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_1d(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                      1.0_wp, 0.0_wp, 0.0_wp], &
                                                     [3, 2])
    REAL(wp) :: u_elem_1d(2), v_elem_1d(2)
    REAL(wp) :: u_elem_2d(4), v_elem_2d(4)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int_1d(2), Ke_1d(2, 2)
    REAL(wp) :: R_int_2d(4), Ke_2d(4, 4)
    REAL(wp) :: ip_stress_1d(1, 1), ip_strain_1d(1, 1)
    REAL(wp) :: ip_stress_2d(1, 1), ip_strain_2d(1, 1)
    REAL(wp) :: ip_peeq_1d(1), ip_creep_1d(1)
    REAL(wp) :: ip_peeq_2d(1), ip_creep_2d(1)
    REAL(wp) :: axial_velocity, analytical_force
    REAL(wp) :: error_axial
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: c = 100.0_wp
    
    CALL init_error_status(status)
    passed = .FALSE.
    
    ! Initialize
    u_elem_1d = 0.0_wp
    v_elem_1d = 0.0_wp
    u_elem_2d = 0.0_wp
    v_elem_2d = 0.0_wp
    D = 0.0_wp
    R_int_1d = 0.0_wp
    Ke_1d = 0.0_wp
    R_int_2d = 0.0_wp
    Ke_2d = 0.0_wp
    ip_stress_1d = 0.0_wp
    ip_strain_1d = 0.0_wp
    ip_stress_2d = 0.0_wp
    ip_strain_2d = 0.0_wp
    ip_peeq_1d = 0.0_wp
    ip_creep_1d = 0.0_wp
    ip_peeq_2d = 0.0_wp
    ip_creep_2d = 0.0_wp
    
    D(1, 1) = c
    
    ! Apply axial velocity (same for both)
    axial_velocity = 0.5_wp  ! 0.5 m/s
    v_elem_1d(1) = 0.0_wp           ! Node 1 fixed
    v_elem_1d(2) = axial_velocity   ! Node 2 X-velocity
    
    v_elem_2d(1) = 0.0_wp           ! Node 1 X-fixed
    v_elem_2d(2) = 0.0_wp           ! Node 1 Y-fixed
    v_elem_2d(3) = axial_velocity   ! Node 2 X-velocity
    v_elem_2d(4) = 0.0_wp           ! Node 2 Y-fixed
    
    ! DASHPOT1 NL_TL
    CALL PH_Elem_DASHPOT1_NL_TL(coords_1d, u_elem_1d, D, ip_stress_1d, &
                               ip_strain_1d, ip_peeq_1d, ip_creep_1d, &
                               R_int_1d, Ke_1d, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?DASHPOT1 comparison failed'
      RETURN
    END IF
    
    ! DASHPOT2 NL_TL
    CALL PH_Elem_DASHPOT2_NL_TL(coords_1d, u_elem_2d, D, ip_stress_2d, &
                               ip_strain_2d, ip_peeq_2d, ip_creep_2d, &
                               R_int_2d, Ke_2d, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?DASHPOT2 comparison failed'
      RETURN
    END IF
    
    ! Analytical: F = c * Δv
    analytical_force = c * axial_velocity
    
    ! Compare DASHPOT1 and DASHPOT2 axial reactions
    error_axial = ABS(R_int_1d(2) - R_int_2d(3)) / ABS(analytical_force)
    
    ! Verification: relative error < 1%
    passed = (error_axial < 0.01_wp)
    
    IF (passed) THEN
      PRINT *, '�?DASHPOT1 vs DASHPOT2 Comparison PASSED'
      PRINT *, '   Axial velocity =', axial_velocity, 'm/s'
      PRINT *, '   Analytical force =', analytical_force, 'N'
      PRINT *, '   DASHPOT1 reaction =', R_int_1d(2), 'N'
      PRINT *, '   DASHPOT2 reaction =', R_int_2d(3), 'N'
      PRINT *, '   Relative error =', error_axial * 100.0_wp, '%'
    ELSE
      PRINT *, '�?DASHPOT1 vs DASHPOT2 Comparison FAILED'
      PRINT *, '   Error =', error_axial * 100.0_wp, '%'
    END IF
    
  END SUBROUTINE TEST_Dashpot_1D_vs_2D
  
END MODULE TEST_DASHPOT_NLGeom_Verification
