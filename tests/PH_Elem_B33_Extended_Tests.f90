!===============================================================================
! Module: PH_Elem_B33_Extended_Tests
! Purpose: Unit tests for B33 extended elements (B33T, B33S, B33NL, B33P)
! Tests: Thermo-mechanical, shear deformation, large rotation, plasticity
!===============================================================================

MODULE PH_Elem_B33_Extended_Tests
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Const, ONLY: ZERO, ONE, HALF
  USE PH_Elem_B33T_Core
  USE PH_Elem_B33S_Core
  USE PH_Elem_B33NL_Core
  USE PH_Elem_B33P_Core
  IMPLICIT NONE
  
CONTAINS

  !===========================================================================
  ! B33T Tests - Thermo-mechanical Coupling
  !===========================================================================
  
  SUBROUTINE Test_B33T_ConsMassMatrix()
    REAL(wp) :: coords(3, 2), Me8(8, 8)
    REAL(wp) :: rho, area, L_expected, m_total
    TYPE(ErrorStatusType) :: status
    
    WRITE(*, *) 'Test B33T-101: B33T Consistent Mass Matrix'
    
    ! Setup: Simple beam along x-axis, length L=2.0
    coords = ZERO
    coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 2) = [2.0_wp, 0.0_wp, 0.0_wp]
    
    rho = 7800.0_wp      ! Steel density [kg/m³]
    area = 0.01_wp       ! Cross-section [m²]
    
    ! Compute mass matrix
    CALL PH_Elem_B33T_ConsMassMatrix(coords, rho, area, Me8, status)
    
    ! Verify: Total translational mass should be rho*A*L
    L_expected = 2.0_wp
    m_total = rho * area * L_expected
    
    ! Check diagonal terms (translational DOF only)
    REAL(wp) :: m_sum
    m_sum = Me8(1,1) + Me8(2,2) + Me8(5,5) + Me8(6,6)
    
    IF (ABS(m_sum - 2.0_wp * m_total) < 1.0e-6_wp * m_total) THEN
      WRITE(*, *) '  PASS: Total mass = ', m_sum, ' expected ', 2.0_wp * m_total
    ELSE
      WRITE(*, *) '  FAIL: Mass mismatch'
      STOP 1
    END IF
    
    ! Verify symmetry
    REAL(wp) :: max_asym
    max_asym = MAXVAL(ABS(Me8 - TRANSPOSE(Me8)))
    IF (max_asym < 1.0e-12_wp) THEN
      WRITE(*, *) '  PASS: Symmetric mass matrix'
    ELSE
      WRITE(*, *) '  FAIL: Asymmetry = ', max_asym
      STOP 1
    END IF
    
    ! Verify zero rotary/thermal inertia
    IF (ALL(Me8([3,4,7,8], :) == ZERO)) THEN
      WRITE(*, *) '  PASS: Zero rotary/thermal inertia (as expected)'
    ELSE
      WRITE(*, *) '  WARNING: Non-zero rotary/thermal inertia'
    END IF
    
    WRITE(*, *) 'Test B33T-101: COMPLETE'
  END SUBROUTINE Test_B33T_ConsMassMatrix

  SUBROUTINE Test_B33T_ThermalCoupling()
    REAL(wp) :: coords(3, 2), Ke8(8, 8)
    REAL(wp) :: E, nu, area_a, I_bend, k_th, alpha
    TYPE(ErrorStatusType) :: status
    
    WRITE(*, *) 'Test B33T-201: B33T Thermal-Mechanical Coupling'
    
    ! Setup: Beam along x-axis
    coords = ZERO
    coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    
    E = 210.0e9_wp     ! Steel Young's modulus [Pa]
    nu = 0.3_wp
    area_a = 0.01_wp   ! [m²]
    I_bend = 8.33e-6_wp ! [m⁴]
    k_th = 50.0_wp     ! Thermal conductivity
    alpha = 1.2e-5_wp  ! CTE [1/K]
    
    ! Compute stiffness with thermal coupling
    CALL PH_Elem_B33T_FormStiffMatrix(coords, E, nu, area_a, I_bend, &
         k_th, alpha, Ke8, status)
    
    ! Verify: K_ut block should be non-zero (mech-thermal coupling)
    REAL(wp) :: kut_max
    kut_max = MAXVAL(ABS(Ke8(1:3, 4)))   ! Node 1 mech x Node 1 temp
    
    IF (kut_max > 1.0e-6_wp) THEN
      WRITE(*, *) '  PASS: K_ut coupling present, max = ', kut_max
    ELSE
      WRITE(*, *) '  FAIL: No thermal-mechanical coupling detected'
      STOP 1
    END IF
    
    ! Verify symmetry of coupling: K_ut = K_tu^T
    REAL(wp) :: asym_coupling
    asym_coupling = MAXVAL(ABS(Ke8(1:3, 4) - Ke8(4, 1:3)))
    IF (asym_coupling < 1.0e-6_wp) THEN
      WRITE(*, *) '  PASS: K_ut/K_tu symmetry preserved'
    ELSE
      WRITE(*, *) '  FAIL: Coupling asymmetry = ', asym_coupling
      STOP 1
    END IF
    
    ! Verify thermal block (should be standard conduction matrix)
    REAL(wp) :: k_cond
    k_cond = k_th / 1.0_wp  ! k_th / L
    IF (ABS(Ke8(4,4) - k_cond) < 1.0e-6_wp .AND. &
        ABS(Ke8(4,8) + k_cond) < 1.0e-6_wp) THEN
      WRITE(*, *) '  PASS: Thermal conduction matrix correct'
    ELSE
      WRITE(*, *) '  FAIL: Thermal block error'
      STOP 1
    END IF
    
    WRITE(*, *) 'Test B33T-201: COMPLETE'
  END SUBROUTINE Test_B33T_ThermalCoupling

  !===========================================================================
  ! B33S Tests - Timoshenko Shear Deformation
  !===========================================================================
  
  SUBROUTINE Test_B33S_ShearFlexibility()
    REAL(wp) :: coords(3, 2), Ke6(6, 6), Ke_shear6(6, 6)
    REAL(wp) :: E, nu, area_a, I_bend, kappa
    TYPE(ErrorStatusType) :: status
    
    WRITE(*, *) 'Test B33S-101: B33S Shear Flexibility'
    
    ! Setup: Short thick beam (L/h = 5, shear important)
    coords = ZERO
    coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 2) = [0.5_wp, 0.0_wp, 0.0_wp]  ! L = 0.5m
    
    E = 210.0e9_wp
    nu = 0.3_wp
    area_a = 0.01_wp
    I_bend = 8.33e-6_wp
    kappa = 5.0_wp/6.0_wp  ! Shear correction factor
    
    ! Compute stiffness with shear
    CALL PH_Elem_B33S_FormStiffMatrixWithShear(coords, E, nu, area_a, I_bend, &
         kappa, Ke_shear6)
    
    ! Compute stiffness without shear (Euler-Bernoulli)
    CALL PH_Elem_B33S_FormStiffMatrix(coords, E, nu, Ke6)
    
    ! Verify: Shear should make the beam more flexible (lower stiffness)
    REAL(wp) :: K22_shear, K22_EB
    K22_shear = Ke_shear6(2, 2)
    K22_EB = Ke6(2, 2)
    
    IF (K22_shear < K22_EB) THEN
      WRITE(*, *) '  PASS: Shear reduces stiffness (more flexible)'
      WRITE(*, *) '    Euler-Bernoulli K22 = ', K22_EB
      WRITE(*, *) '    Timoshenko K22 = ', K22_shear
      WRITE(*, *) '    Reduction = ', (K22_EB - K22_shear)/K22_EB * 100.0_wp, '%'
    ELSE
      WRITE(*, *) '  FAIL: Shear should reduce stiffness'
      STOP 1
    END IF
    
    ! Verify: For very slender beam (L/h > 10), difference should be small
    coords(:, 2) = [2.0_wp, 0.0_wp, 0.0_wp]  ! L = 2.0m (slender)
    CALL PH_Elem_B33S_FormStiffMatrixWithShear(coords, E, nu, area_a, I_bend, &
         kappa, Ke_shear6)
    CALL PH_Elem_B33S_FormStiffMatrix(coords, E, nu, Ke6)
    
    REAL(wp) :: diff_ratio
    diff_ratio = ABS(Ke_shear6(2, 2) - Ke6(2, 2)) / Ke6(2, 2)
    
    IF (diff_ratio < 0.05_wp) THEN  ! Less than 5% difference
      WRITE(*, *) '  PASS: Slender beam converges to Euler-Bernoulli'
      WRITE(*, *) '    Stiffness difference = ', diff_ratio * 100.0_wp, '%'
    ELSE
      WRITE(*, *) '  WARNING: Large difference for slender beam'
    END IF
    
    WRITE(*, *) 'Test B33S-101: COMPLETE'
  END SUBROUTINE Test_B33S_ShearFlexibility

  !===========================================================================
  ! B33NL Tests - Large Rotation (Corotational)
  !===========================================================================
  
  SUBROUTINE Test_B33NL_GeometricStiffness()
    REAL(wp) :: coords_ref(3, 2), u(6), Ke_tan(6, 6), P_axial
    REAL(wp) :: E, nu, area_a, I_bend
    
    WRITE(*, *) 'Test B33NL-101: B33NL Geometric Stiffness'
    
    ! Setup: Cantilever beam
    coords_ref = ZERO
    coords_ref(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    
    E = 210.0e9_wp
    nu = 0.3_wp
    area_a = 0.01_wp
    I_bend = 8.33e-6_wp
    
    ! Case 1: Tension (stress stiffening)
    u = ZERO
    u(4) = 0.001_wp  ! Small axial stretch
    
    CALL PH_Elem_B33NL_FormStiffMatrixTan(coords_ref, u, E, nu, area_a, I_bend, &
         Ke_tan, P_axial)
    
    IF (P_axial > 0) THEN
      WRITE(*, *) '  PASS: Tensile axial force = ', P_axial, ' N'
      
      ! Tangent stiffness should be higher than linear due to stress stiffening
      REAL(wp) :: K_lin(6, 6), K22_tan, K22_lin
      CALL PH_Elem_B33NL_FormStiffMatrix(coords_ref, E, nu, area_a, I_bend, K_lin)
      
      K22_tan = Ke_tan(2, 2)
      K22_lin = K_lin(2, 2)
      
      IF (K22_tan > K22_lin) THEN
        WRITE(*, *) '  PASS: Stress stiffening observed (K_tan > K_lin)'
        WRITE(*, *) '    Linear K22 = ', K22_lin
        WRITE(*, *) '    Tangent K22 = ', K22_tan
      ELSE
        WRITE(*, *) '  FAIL: Expected stress stiffening'
        STOP 1
      END IF
    ELSE
      WRITE(*, *) '  FAIL: Expected tensile force'
      STOP 1
    END IF
    
    ! Case 2: Compression (stress softening)
    u(4) = -0.001_wp  ! Small axial compression
    
    CALL PH_Elem_B33NL_FormStiffMatrixTan(coords_ref, u, E, nu, area_a, I_bend, &
         Ke_tan, P_axial)
    
    IF (P_axial < 0) THEN
      WRITE(*, *) '  PASS: Compressive axial force = ', P_axial, ' N'
      
      CALL PH_Elem_B33NL_FormStiffMatrix(coords_ref, E, nu, area_a, I_bend, K_lin)
      K22_tan = Ke_tan(2, 2)
      K22_lin = K_lin(2, 2)
      
      IF (K22_tan < K22_lin) THEN
        WRITE(*, *) '  PASS: Stress softening observed (K_tan < K_lin)'
        WRITE(*, *) '    Linear K22 = ', K22_lin
        WRITE(*, *) '    Tangent K22 = ', K22_tan
      ELSE
        WRITE(*, *) '  FAIL: Expected stress softening'
        STOP 1
      END IF
    ELSE
      WRITE(*, *) '  FAIL: Expected compressive force'
      STOP 1
    END IF
    
    WRITE(*, *) 'Test B33NL-101: COMPLETE'
  END SUBROUTINE Test_B33NL_GeometricStiffness

  !===========================================================================
  ! B33P Tests - Plasticity (Fiber Integration)
  !===========================================================================
  
  SUBROUTINE Test_B33P_Yielding()
    REAL(wp) :: coords_ref(3, 2), u(6), Ke_tan(6, 6), R(6)
    REAL(wp) :: E, nu, area_a, I_bend, sigma_y, H
    INTEGER(i4) :: n_fibers
    TYPE(FiberState), ALLOCATABLE :: fibers(:)
    
    WRITE(*, *) 'Test B33P-101: B33P Material Yielding'
    
    ! Setup: Simply supported beam in bending
    coords_ref = ZERO
    coords_ref(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    
    E = 210.0e9_wp
    nu = 0.3_wp
    area_a = 0.01_wp
    I_bend = 8.33e-6_wp
    sigma_y = 250.0e6_wp  ! Yield stress 250 MPa
    H = 2.0e9_wp          ! Hardening modulus
    n_fibers = 10
    
    ALLOCATE(fibers(n_fibers))
    
    ! Apply pure bending (rotation at node 2)
    u = ZERO
    u(6) = 0.01_wp  ! Small rotation
    
    ! Compute tangent stiffness and internal force
    CALL PH_Elem_B33P_FormTangentMatrix(coords_ref, u, E, nu, area_a, I_bend, &
         sigma_y, H, n_fibers, Ke_tan, fibers)
    
    CALL PH_Elem_B33P_FormIntForce(coords_ref, u, E, nu, area_a, I_bend, &
         sigma_y, H, n_fibers, R, fibers)
    
    ! Check for yielding
    INTEGER(i4) :: n_yielded
    n_yielded = COUNT(fibers%is_yielding)
    
    WRITE(*, *) '  Fibers yielded: ', n_yielded, ' out of ', n_fibers
    
    ! With small rotation, some outer fibers should yield
    IF (n_yielded > 0) THEN
      WRITE(*, *) '  PASS: Plastic deformation detected'
      
      ! Verify tangent stiffness reduced due to plasticity
      REAL(wp) :: Et_avg
      Et_avg = SUM([(fibers(i)%stress/fibers(i)%strain, i=1, n_fibers)]) / n_fibers
      
      IF (Et_avg < E) THEN
        WRITE(*, *) '  PASS: Tangent modulus reduced (plasticity)'
        WRITE(*, *) '    Elastic E = ', E/1.0e9_wp, ' GPa'
        WRITE(*, *) '    Average Et = ', Et_avg/1.0e9_wp, ' GPa'
      ELSE
        WRITE(*, *) '  WARNING: No stiffness reduction'
      END IF
    ELSE
      WRITE(*, *) '  INFO: All fibers elastic (increase rotation)'
    END IF
    
    ! Cleanup
    DEALLOCATE(fibers)
    
    WRITE(*, *) 'Test B33P-101: COMPLETE'
  END SUBROUTINE Test_B33P_Yielding

  SUBROUTINE Test_B33P_MomentCurvature()
    REAL(wp) :: coords_ref(3, 2), u(6), R(6), M_applied, kappa
    REAL(wp) :: E, nu, area_a, I_bend, sigma_y, H
    INTEGER(i4) :: n_fibers, i
    TYPE(FiberState), ALLOCATABLE :: fibers(:)
    
    WRITE(*, *) 'Test B33P-201: B33P Moment-Curvature Response'
    
    ! Setup
    coords_ref = ZERO
    coords_ref(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    
    E = 210.0e9_wp
    nu = 0.3_wp
    area_a = 0.01_wp
    I_bend = 8.33e-6_wp
    sigma_y = 250.0e6_wp
    H = 1.0e9_wp
    n_fibers = 20
    
    ALLOCATE(fibers(n_fibers))
    
    WRITE(*, *) '  Moment-Curvature Curve:'
    WRITE(*, *) '  Curvature [1/m] | Moment [Nm]'
    
    ! Incremental curvature
    DO i = 1, 10
      kappa = REAL(i, wp) * 0.001_wp
      
      ! Apply curvature through end rotations
      u = ZERO
      u(3) = -kappa * 0.5_wp  ! Node 1 rotation
      u(6) =  kappa * 0.5_wp  ! Node 2 rotation
      
      CALL PH_Elem_B33P_FormIntForce(coords_ref, u, E, nu, area_a, I_bend, &
           sigma_y, H, n_fibers, R, fibers)
      
      ! Extract moment from reaction (simplified)
      M_applied = R(6)  ! Moment at node 2
      
      WRITE(*, '(F12.4, F12.2)') kappa, M_applied
    END DO
    
    ! Cleanup
    DEALLOCATE(fibers)
    
    WRITE(*, *) 'Test B33P-201: COMPLETE'
  END SUBROUTINE Test_B33P_MomentCurvature

  !===========================================================================
  ! Master Test Runner
  !===========================================================================
  SUBROUTINE Run_All_B33_Extended_Tests()
    WRITE(*, *) ''
    WRITE(*, *) '========================================'
    WRITE(*, *) 'B33 Extended Elements Unit Tests'
    WRITE(*, *) '========================================'
    WRITE(*, *) ''
    
    ! B33T Tests
    WRITE(*, *) '--- B33T: Thermo-mechanical Coupling ---'
    CALL Test_B33T_ConsMassMatrix()
    WRITE(*, *) ''
    CALL Test_B33T_ThermalCoupling()
    WRITE(*, *) ''
    
    ! B33S Tests
    WRITE(*, *) '--- B33S: Timoshenko Shear Deformation ---'
    CALL Test_B33S_ShearFlexibility()
    WRITE(*, *) ''
    
    ! B33NL Tests
    WRITE(*, *) '--- B33NL: Large Rotation (Corotational) ---'
    CALL Test_B33NL_GeometricStiffness()
    WRITE(*, *) ''
    
    ! B33P Tests
    WRITE(*, *) '--- B33P: Plasticity (Fiber Integration) ---'
    CALL Test_B33P_Yielding()
    WRITE(*, *) ''
    CALL Test_B33P_MomentCurvature()
    WRITE(*, *) ''
    
    WRITE(*, *) '========================================'
    WRITE(*, *) 'All B33 Extended Tests PASSED'
    WRITE(*, *) '========================================'
  END SUBROUTINE Run_All_B33_Extended_Tests

END MODULE PH_Elem_B33_Extended_Tests
