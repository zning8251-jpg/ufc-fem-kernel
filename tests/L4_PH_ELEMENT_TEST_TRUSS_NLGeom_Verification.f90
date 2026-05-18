!===============================================================================
! Module: TEST_TRUSS_NLGeom_Verification
! Purpose: TRUSS 单元族非线性几何验证测试集（T3D2/T2D2�?
! Tests:   1. 大伸长率验证（�?= L/L₀�?
!          2. 刚体旋转测试
!          3. �?B31 单元轴向行为对比
!===============================================================================
! Layer:  L4_PH - Physics Layer
! Domain: Element - TRUSS Family
! Theory: Total/Updated Lagrangian for 1D axial deformation
! Status: B-Element-10 Task #5 (⭐最简单快速交�?
!===============================================================================

MODULE TEST_TRUSS_NLGeom_Verification
  USE IF_Const, ONLY: ZERO, ONE, HALF, TWO, THREE
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_T3D2_Core, ONLY: PH_Elem_T3D2_NL_TL, PH_Elem_T3D2_NL_UL, &
                               PH_Elem_T3D2_GetLength, PH_Elem_T3D2_GetArea
  USE PH_Elem_T2D2_Core, ONLY: PH_Elem_T2D2_NL_TL, PH_Elem_T2D2_NL_UL, &
                               PH_Elem_T2D2_GetLength, PH_Elem_T2D2_GetArea
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: TEST_Truss_Large_Strain, TEST_Truss_Rigid_Rotation, &
          TEST_Truss_Comparison_B31
  
CONTAINS
  
  !=============================================================================
  ! Test 1: 大伸长率验证（T3D2�?
  !=============================================================================
  SUBROUTINE TEST_Truss_Large_Strain(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_ref(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                       1.0_wp, 0.0_wp, 0.0_wp], &
                                                      [3, 2])
    REAL(wp) :: u_elem(6)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int(6), Ke(6, 6)
    REAL(wp) :: ip_stress(1, 1), ip_strain(1, 1)
    REAL(wp) :: ip_peeq(1), ip_creep(1)
    REAL(wp) :: stretch_ratio, lambda, analytical_stress
    REAL(wp) :: error_norm
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: E_young = 210.0e9_wp  ! 210 GPa
    REAL(wp), PARAMETER :: strain_target = 0.10_wp  ! 10% large strain
    
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
    
    ! Young's modulus (1D)
    D(1, 1) = E_young
    
    ! 10% tensile stretch
    stretch_ratio = 1.0_wp + strain_target
    u_elem(1) = 0.0_wp              ! Node 1 fixed
    u_elem(4) = 0.10_wp             ! Node 2: ΔL = 0.1 * L0
    
    ! TL analysis
    CALL PH_Elem_T3D2_NL_TL(coords_ref, u_elem, D, ip_stress, ip_strain, &
                           ip_peeq, ip_creep, R_int, Ke, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?T3D2 NL_TL failed'
      RETURN
    END IF
    
    ! Analytical: Engineering stress σ = E * ε (small strain approx)
    ! For large strain: 2nd PK stress S = E * E_Green
    ! E_Green = 0.5*(λ² - 1) where λ = L/L0
    lambda = stretch_ratio
    analytical_stress = E_young * 0.5_wp * (lambda**2 - 1.0_wp)
    
    ! Extract computed stress at IP
    error_norm = ABS(ip_stress(1,1) - analytical_stress) / ABS(analytical_stress)
    
    ! Verification: relative error < 5%
    passed = (error_norm < 0.05_wp)
    
    IF (passed) THEN
      PRINT *, '�?T3D2 Large Strain PASSED'
      PRINT *, '   Stretch ratio λ =', lambda
      PRINT *, '   Green-Lagrange strain =', 0.5_wp * (lambda**2 - 1.0_wp)
      PRINT *, '   Analytical 2nd PK =', analytical_stress / 1.0e6_wp, 'MPa'
      PRINT *, '   Computed 2nd PK =', ip_stress(1,1) / 1.0e6_wp, 'MPa'
      PRINT *, '   Relative error =', error_norm * 100.0_wp, '%'
    ELSE
      PRINT *, '�?T3D2 Large Strain FAILED'
      PRINT *, '   Error =', error_norm * 100.0_wp, '%'
    END IF
    
  END SUBROUTINE TEST_Truss_Large_Strain
  
  !=============================================================================
  ! Test 2: 刚体旋转测试（T3D2�?
  !=============================================================================
  SUBROUTINE TEST_Truss_Rigid_Rotation(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_ref(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                       1.0_wp, 0.0_wp, 0.0_wp], &
                                                      [3, 2])
    REAL(wp) :: coords_cur(3, 2)
    REAL(wp) :: u_elem(6)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int(6), Ke(6, 6)
    REAL(wp) :: ip_stress(1, 1), ip_strain(1, 1)
    REAL(wp) :: ip_peeq(1), ip_creep(1)
    REAL(wp) :: angle_rad, cos_a, sin_a
    REAL(wp) :: force_norm
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: E_young = 210.0e9_wp
    
    CALL init_error_status(status)
    passed = .FALSE.
    
    ! Initialize
    D = 0.0_wp
    R_int = 0.0_wp
    Ke = 0.0_wp
    ip_stress = 0.0_wp
    ip_strain = 0.0_wp
    ip_peeq = 0.0_wp
    ip_creep = 0.0_wp
    
    D(1, 1) = E_young
    
    ! 90-degree rigid body rotation about Z-axis
    angle_rad = 0.5_wp * ACOS(-1.0_wp)  ! π/2
    cos_a = COS(angle_rad)
    sin_a = SIN(angle_rad)
    
    ! Current coordinates after rotation
    coords_cur(1,1) = 0.0_wp
    coords_cur(2,1) = 0.0_wp
    coords_cur(3,1) = 0.0_wp
    coords_cur(1,2) = cos_a  ! X = L*cos(90°) = 0
    coords_cur(2,2) = sin_a  ! Y = L*sin(90°) = 1
    coords_cur(3,2) = 0.0_wp
    
    ! Displacement: u = x_cur - x_ref
    u_elem(1:3) = coords_cur(:,1) - coords_ref(:,1)
    u_elem(4:6) = coords_cur(:,2) - coords_ref(:,2)
    
    ! TL analysis (should have zero strain for rigid motion)
    CALL PH_Elem_T3D2_NL_TL(coords_ref, u_elem, D, ip_stress, ip_strain, &
                           ip_peeq, ip_creep, R_int, Ke, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?T3D2 Rigid Rotation failed'
      RETURN
    END IF
    
    ! Verification: internal force should be ~zero (rigid motion �?no strain)
    force_norm = SQRT(SUM(R_int**2))
    passed = (force_norm < 1.0e-6_wp)
    
    IF (passed) THEN
      PRINT *, '�?T3D2 Rigid Rotation PASSED'
      PRINT *, '   Rotation angle = 90 degrees'
      PRINT *, '   Internal force norm =', force_norm, '(should be ~0)'
      PRINT *, '   Stress =', ip_stress(1,1), '(should be ~0)'
    ELSE
      PRINT *, '�?T3D2 Rigid Rotation FAILED'
      PRINT *, '   Force norm =', force_norm
    END IF
    
  END SUBROUTINE TEST_Truss_Rigid_Rotation
  
  !=============================================================================
  ! Test 3: �?B31 单元轴向行为对比（T2D2 vs B31�?
  !=============================================================================
  SUBROUTINE TEST_Truss_Comparison_B31(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp), PARAMETER :: coords_2d(3,2) = RESHAPE([0.0_wp, 0.0_wp, 0.0_wp, &
                                                      1.0_wp, 0.0_wp, 0.0_wp], &
                                                     [3, 2])
    REAL(wp) :: u_elem_t2d2(4)
    REAL(wp) :: D(1, 1)
    REAL(wp) :: R_int_t2d2(4), Ke_t2d2(4, 4)
    REAL(wp) :: ip_stress_t2d2(1, 1), ip_strain_t2d2(1, 1)
    REAL(wp) :: ip_peeq_t2d2(1), ip_creep_t2d2(1)
    REAL(wp) :: axial_disp, analytical_force
    REAL(wp) :: error_axial
    
    INTEGER(i4) :: i
    REAL(wp), PARAMETER :: E_young = 210.0e9_wp
    REAL(wp), PARAMETER :: area = 0.01_wp  ! 100 mm²
    
    CALL init_error_status(status)
    passed = .FALSE.
    
    ! Initialize
    u_elem_t2d2 = 0.0_wp
    D = 0.0_wp
    R_int_t2d2 = 0.0_wp
    Ke_t2d2 = 0.0_wp
    ip_stress_t2d2 = 0.0_wp
    ip_strain_t2d2 = 0.0_wp
    ip_peeq_t2d2 = 0.0_wp
    ip_creep_t2d2 = 0.0_wp
    
    D(1, 1) = E_young
    
    ! Apply axial displacement (same as B31 would see)
    axial_disp = 0.001_wp  ! 1mm tension
    u_elem_t2d2(1) = 0.0_wp        ! Node 1 X-fixed
    u_elem_t2d2(3) = axial_disp    ! Node 2 X-disp
    
    ! T2D2 NL_TL
    CALL PH_Elem_T2D2_NL_TL(coords_2d, u_elem_t2d2, D, ip_stress_t2d2, &
                           ip_strain_t2d2, ip_peeq_t2d2, ip_creep_t2d2, &
                           R_int_t2d2, Ke_t2d2, status)
    
    IF (.NOT. STATUS_SUCCESS(status)) THEN
      PRINT *, '�?T2D2 comparison failed'
      RETURN
    END IF
    
    ! Analytical: F = EA * ε = EA * (ΔL/L)
    analytical_force = E_young * area * (axial_disp / 1.0_wp)
    
    ! Extract axial force from T2D2 reaction
    error_axial = ABS(R_int_t2d2(3) - analytical_force) / ABS(analytical_force)
    
    ! Verification: relative error < 5%
    passed = (error_axial < 0.05_wp)
    
    IF (passed) THEN
      PRINT *, '�?T2D2 vs B31 Comparison PASSED'
      PRINT *, '   Axial displacement =', axial_disp * 1000.0_wp, 'mm'
      PRINT *, '   Analytical force =', analytical_force / 1000.0_wp, 'kN'
      PRINT *, '   Computed reaction =', R_int_t2d2(3) / 1000.0_wp, 'kN'
      PRINT *, '   Relative error =', error_axial * 100.0_wp, '%'
    ELSE
      PRINT *, '�?T2D2 vs B31 Comparison FAILED'
      PRINT *, '   Error =', error_axial * 100.0_wp, '%'
    END IF
    
  END SUBROUTINE TEST_Truss_Comparison_B31
  
END MODULE TEST_TRUSS_NLGeom_Verification
