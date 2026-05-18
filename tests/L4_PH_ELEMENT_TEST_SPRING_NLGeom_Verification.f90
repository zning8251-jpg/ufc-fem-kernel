!===============================================================================
! Module: TEST_SPRING_NLGeom_Verification
! Purpose: SPRING 单元族非线性几何验证测试集（SPRING1/SPRING2�?
! Tests:   1. 大变形拉伸验证（�?- 位移曲线�?
!          2. 刚体平移测试（零应变�?
!          3. SPRING1 vs SPRING2 对比�?D vs 2D�?
!===============================================================================
! Layer:  L4_PH - Physics Layer
! Domain: Element - SPRING Family
! Theory: Linear spring with geometric nonlinearity (force follow displacement)
! Status: B-Element-10 Task #6 (⭐最简单快速交�?
!===============================================================================

MODULE TEST_SPRING_NLGeom_Verification
  USE IF_Const, ONLY: ZERO, ONE, HALF, TWO, THREE
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_SPRING1_Core, ONLY: PH_Elem_SPRING1_NL_TL, PH_Elem_SPRING1_NL_UL
  USE PH_Elem_SPRING2_Core, ONLY: PH_Elem_SPRING2_NL_TL, PH_Elem_SPRING2_NL_UL
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: TEST_Spring_Large_Deformation, TEST_Spring_Rigid_Translation, &
          TEST_Spring_1D_vs_2D
  
CONTAINS
  
  !=============================================================================
  ! Test 1: 大变形拉伸验证（SPRING1�?
  !=============================================================================
  SUBROUTINE TEST_Spring_Large_Deformation(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_ref(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                       1.0_wp, 0.0_wp, 0.0_wp], &
                                                      [3, 2])
    REAL(wp) :: u_elem(2)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int(2), Ke(2, 2)
    REAL(wp) :: ip_stress(1, 1), ip_strain(1, 1)
    REAL(wp) :: ip_peeq(1), ip_creep(1)
    REAL(wp) :: stiffness, displacement, analytical_force
    REAL(wp) :: error_norm
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: k = 1000.0_wp  ! Spring stiffness N/m
    REAL(wp), PARAMETER :: disp_target = 0.5_wp  ! 50% large deformation
    
    CALL init_error_status(status)
    passed = .FALSE.
    
    ! Initialize
    u_elem = 0.0_wp
    D = 0.0_wp
    R_int = 0.0_wp
    Ke = 0.0_wp
    ip_stress = 0.0_wp
    ip_strain = 0.0_wp
    ip_peeq = 0.0_wp
    ip_creep = 0.0_wp
    
    ! Spring stiffness (stored in D matrix for consistency)
    D(1, 1) = k
    
    ! Apply large displacement (50% of original length)
    u_elem(1) = 0.0_wp                ! Node 1 fixed
    u_elem(2) = disp_target           ! Node 2: ΔL = 0.5m
    
    ! TL analysis
    CALL PH_Elem_SPRING1_NL_TL(coords_ref, u_elem, D, ip_stress, ip_strain, &
                              ip_peeq, ip_creep, R_int, Ke, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?SPRING1 NL_TL failed'
      RETURN
    END IF
    
    ! Analytical: F = k * ΔL (linear spring, small strain)
    ! For large deformation: F = k * (L - L0) where L = L0 + u
    analytical_force = k * disp_target
    
    ! Extract computed force at node 2
    error_norm = ABS(R_int(2) - analytical_force) / ABS(analytical_force)
    
    ! Verification: relative error < 1%
    passed = (error_norm < 0.01_wp)
    
    IF (passed) THEN
      PRINT *, '�?SPRING1 Large Deformation PASSED'
      PRINT *, '   Stiffness k =', k, 'N/m'
      PRINT *, '   Displacement =', disp_target, 'm'
      PRINT *, '   Analytical force =', analytical_force, 'N'
      PRINT *, '   Computed reaction =', R_int(2), 'N'
      PRINT *, '   Relative error =', error_norm * 100.0_wp, '%'
    ELSE
      PRINT *, '�?SPRING1 Large Deformation FAILED'
      PRINT *, '   Error =', error_norm * 100.0_wp, '%'
    END IF
    
  END SUBROUTINE TEST_Spring_Large_Deformation
  
  !=============================================================================
  ! Test 2: 刚体平移测试（SPRING2�?
  !=============================================================================
  SUBROUTINE TEST_Spring_Rigid_Translation(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_ref(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                       1.0_wp, 0.0_wp, 0.0_wp], &
                                                      [3, 2])
    REAL(wp) :: u_elem(4)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int(4), Ke(4, 4)
    REAL(wp) :: ip_stress(1, 1), ip_strain(1, 1)
    REAL(wp) :: ip_peeq(1), ip_creep(1)
    REAL(wp) :: rigid_disp
    REAL(wp) :: force_norm
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: k = 1000.0_wp
    
    CALL init_error_status(status)
    passed = .FALSE.
    
    ! Initialize
    u_elem = 0.0_wp
    D = 0.0_wp
    R_int = 0.0_wp
    Ke = 0.0_wp
    ip_stress = 0.0_wp
    ip_strain = 0.0_wp
    ip_peeq = 0.0_wp
    ip_creep = 0.0_wp
    
    D(1, 1) = k
    
    ! Rigid body translation (both nodes move same amount)
    rigid_disp = 0.1_wp
    u_elem(1) = rigid_disp  ! Node 1 X
    u_elem(2) = 0.0_wp      ! Node 1 Y (fixed)
    u_elem(3) = rigid_disp  ! Node 2 X
    u_elem(4) = 0.0_wp      ! Node 2 Y (fixed)
    
    ! TL analysis (should have zero strain for rigid motion)
    CALL PH_Elem_SPRING2_NL_TL(coords_ref, u_elem, D, ip_stress, ip_strain, &
                              ip_peeq, ip_creep, R_int, Ke, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?SPRING2 Rigid Translation failed'
      RETURN
    END IF
    
    ! Verification: internal force should be ~zero (rigid motion �?no stretch)
    force_norm = SQRT(SUM(R_int**2))
    passed = (force_norm < 1.0e-6_wp)
    
    IF (passed) THEN
      PRINT *, '�?SPRING2 Rigid Translation PASSED'
      PRINT *, '   Rigid displacement =', rigid_disp, 'm'
      PRINT *, '   Internal force norm =', force_norm, '(should be ~0)'
      PRINT *, '   Stress =', ip_stress(1,1), '(should be ~0)'
    ELSE
      PRINT *, '�?SPRING2 Rigid Translation FAILED'
      PRINT *, '   Force norm =', force_norm
    END IF
    
  END SUBROUTINE TEST_Spring_Rigid_Translation
  
  !=============================================================================
  ! Test 3: SPRING1 vs SPRING2 对比�?D vs 2D�?
  !=============================================================================
  SUBROUTINE TEST_Spring_1D_vs_2D(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_1d(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                      1.0_wp, 0.0_wp, 0.0_wp], &
                                                     [3, 2])
    REAL(wp) :: u_elem_1d(2), u_elem_2d(4)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int_1d(2), Ke_1d(2, 2)
    REAL(wp) :: R_int_2d(4), Ke_2d(4, 4)
    REAL(wp) :: ip_stress_1d(1, 1), ip_strain_1d(1, 1)
    REAL(wp) :: ip_stress_2d(1, 1), ip_strain_2d(1, 1)
    REAL(wp) :: ip_peeq_1d(1), ip_creep_1d(1)
    REAL(wp) :: ip_peeq_2d(1), ip_creep_2d(1)
    REAL(wp) :: axial_disp, analytical_force
    REAL(wp) :: error_axial
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: k = 1000.0_wp
    
    CALL init_error_status(status)
    passed = .FALSE.
    
    ! Initialize
    u_elem_1d = 0.0_wp
    u_elem_2d = 0.0_wp
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
    
    D(1, 1) = k
    
    ! Apply axial displacement (same for both)
    axial_disp = 0.01_wp  ! 1cm tension
    u_elem_1d(1) = 0.0_wp        ! Node 1 fixed
    u_elem_1d(2) = axial_disp    ! Node 2 X-disp
    
    u_elem_2d(1) = 0.0_wp        ! Node 1 X-fixed
    u_elem_2d(2) = 0.0_wp        ! Node 1 Y-fixed
    u_elem_2d(3) = axial_disp    ! Node 2 X-disp
    u_elem_2d(4) = 0.0_wp        ! Node 2 Y-fixed
    
    ! SPRING1 NL_TL
    CALL PH_Elem_SPRING1_NL_TL(coords_1d, u_elem_1d, D, ip_stress_1d, &
                              ip_strain_1d, ip_peeq_1d, ip_creep_1d, &
                              R_int_1d, Ke_1d, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?SPRING1 comparison failed'
      RETURN
    END IF
    
    ! SPRING2 NL_TL
    CALL PH_Elem_SPRING2_NL_TL(coords_1d, u_elem_2d, D, ip_stress_2d, &
                              ip_strain_2d, ip_peeq_2d, ip_creep_2d, &
                              R_int_2d, Ke_2d, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?SPRING2 comparison failed'
      RETURN
    END IF
    
    ! Analytical: F = k * ΔL
    analytical_force = k * axial_disp
    
    ! Compare SPRING1 and SPRING2 axial reactions
    error_axial = ABS(R_int_1d(2) - R_int_2d(3)) / ABS(analytical_force)
    
    ! Verification: relative error < 1%
    passed = (error_axial < 0.01_wp)
    
    IF (passed) THEN
      PRINT *, '�?SPRING1 vs SPRING2 Comparison PASSED'
      PRINT *, '   Axial displacement =', axial_disp * 100.0_wp, 'cm'
      PRINT *, '   Analytical force =', analytical_force, 'N'
      PRINT *, '   SPRING1 reaction =', R_int_1d(2), 'N'
      PRINT *, '   SPRING2 reaction =', R_int_2d(3), 'N'
      PRINT *, '   Relative error =', error_axial * 100.0_wp, '%'
    ELSE
      PRINT *, '�?SPRING1 vs SPRING2 Comparison FAILED'
      PRINT *, '   Error =', error_axial * 100.0_wp, '%'
    END IF
    
  END SUBROUTINE TEST_Spring_1D_vs_2D
  
END MODULE TEST_SPRING_NLGeom_Verification
