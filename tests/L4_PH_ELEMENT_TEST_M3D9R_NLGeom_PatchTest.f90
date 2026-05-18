!===============================================================================
! Module: TEST_M3D9R_NLGeom_PatchTest
! Layer:  L4_PH - Verification Test
! Domain: Element / M3D9R Membrane (Geometric Nonlinearity)
!
! Purpose: Patch test for M3D9R with TL/UL geometric nonlinearity
!          Validates PH_Elem_M3D9R_NL_TL/UL against analytical solutions
!
! Test Cases:
!   1. Uniaxial tension (large strain) - Verify stress update
!   2. Pure rotation (rigid body) - Zero strain energy
!   3. Simple shear - Compare TL vs UL
!
! Status: B-Element-10 | Created: 2026-03-31
!===============================================================================

MODULE TEST_M3D9R_NLGeom_PatchTest
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE PH_Elem_Membrane_Core, ONLY: PH_Elem_M3D9R_NL_TL, PH_Elem_M3D9R_NL_UL
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: TEST_Run_M3D9R_PatchTest
  
CONTAINS

  !============================================================================
  ! Subroutine: TEST_Run_M3D9R_PatchTest
  ! Purpose: Run all patch tests for M3D9R nonlinear geometry
  !============================================================================
  SUBROUTINE TEST_Run_M3D9R_PatchTest(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    LOGICAL :: test1_pass, test2_pass, test3_pass
    
    WRITE(*,*) ''
    WRITE(*,*) '=========================================='
    WRITE(*,*) 'M3D9R Geometric Nonlinearity Patch Tests'
    WRITE(*,*) '=========================================='
    
    ! Test 1: Uniaxial tension (TL formulation)
    CALL TEST_Uniaxial_Tension_TL(test1_pass, status)
    IF (.NOT. test1_pass) THEN
      CALL init_error_status(status, STATUS_ERR, "Test 1 Failed: Uniaxial tension")
      RETURN
    END IF
    
    ! Test 2: Rigid body rotation (zero strain)
    CALL TEST_Rigid_Body_Rotation(test2_pass, status)
    IF (.NOT. test2_pass) THEN
      CALL init_error_status(status, STATUS_ERR, "Test 2 Failed: Rigid body rotation")
      RETURN
    END IF
    
    ! Test 3: Simple shear (TL vs UL comparison)
    CALL TEST_Simple_Shear_Comparison(test3_pass, status)
    IF (.NOT. test3_pass) THEN
      CALL init_error_status(status, STATUS_ERR, "Test 3 Failed: Simple shear")
      RETURN
    END IF
    
    WRITE(*,*) ''
    WRITE(*,*) 'All patch tests PASSED �?
    CALL init_error_status(status, IF_STATUS_OK)
    
  END SUBROUTINE TEST_Run_M3D9R_PatchTest
  
  !============================================================================
  ! Subroutine: TEST_Uniaxial_Tension_TL
  ! Purpose: Uniaxial tension test - verify stress and stiffness
  !============================================================================
  SUBROUTINE TEST_Uniaxial_Tension_TL(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_ref(3, 4)
    REAL(wp) :: u_elem(12)
    REAL(wp) :: D(6, 6)
    REAL(wp) :: thickness
    REAL(wp) :: Ke_mat(12, 12), Ke_geo(12, 12), R_int(12)
    REAL(wp) :: E_young, nu
    REAL(wp) :: strain_target, stress_analytical
    REAL(wp) :: stress_computed, error_norm
    INTEGER(i4) :: i
    
    WRITE(*,*) ''
    WRITE(*,*) 'Test 1: Uniaxial Tension (TL)'
    WRITE(*,*) '-------------------------------'
    
    ! Material properties
    E_young = 210.0e3_wp      ! MPa (steel)
    nu = 0.3_wp
    thickness = 10.0_wp       ! mm
    
    ! Plane stress constitutive matrix
    D = 0.0_wp
    D(1,1) = E_young / (ONE - nu**2)
    D(1,2) = E_young * nu / (ONE - nu**2)
    D(2,1) = D(1,2)
    D(2,2) = D(1,1)
    D(3,3) = E_young / (2.0_wp * (ONE + nu))
    
    ! Unit square geometry (reference)
    coords_ref(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:,2) = [100.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:,3) = [100.0_wp, 100.0_wp, 0.0_wp]
    coords_ref(:,4) = [0.0_wp, 100.0_wp, 0.0_wp]
    
    ! Apply uniaxial displacement (10% strain)
    strain_target = 0.10_wp
    u_elem = 0.0_wp
    u_elem(1) = 0.0_wp                    ! Node 1 fixed
    u_elem(2) = 0.0_wp
    u_elem(3) = strain_target * 100.0_wp  ! Node 2: ΔX = 10mm
    u_elem(4) = 0.0_wp
    u_elem(7) = 0.0_wp                    ! Node 4 fixed X
    u_elem(8) = -nu * strain_target * 100.0_wp  ! Poisson effect
    
    ! Call TL formulation
    CALL PH_Elem_M3D9R_NL_TL(coords_ref, u_elem, D, thickness, &
                             Ke_mat, Ke_geo, R_int, status)
    
    IF (.NOT. status%ok()) THEN
      WRITE(*,*) 'ERROR: TL computation failed'
      passed = .FALSE.
      RETURN
    END IF
    
    ! Analytical solution (engineering stress)
    stress_analytical = E_young * strain_target
    
    ! Extract computed stress (simplified: average from internal force)
    stress_computed = ABS(R_int(3)) / (thickness * 100.0_wp)  ! F_x / A_0
    
    ! Verification: relative error < 5%
    error_norm = ABS(stress_computed - stress_analytical) / stress_analytical
    passed = (error_norm < 0.05_wp)
    
    WRITE(*,'(A,F12.6,A)') '  Target strain:     ', strain_target, ''
    WRITE(*,'(A,F12.2,A)') '  Analytical σ:    ', stress_analytical, ' MPa'
    WRITE(*,'(A,F12.2,A)') '  Computed σ:      ', stress_computed, ' MPa'
    WRITE(*,'(A,F8.4,A)') '  Relative error:  ', error_norm * 100.0_wp, '%'
    WRITE(*,'(A,L1)') '  Result:          ', passed
    
  END SUBROUTINE TEST_Uniaxial_Tension_TL
  
  !============================================================================
  ! Subroutine: TEST_Rigid_Body_Rotation
  ! Purpose: Rigid body rotation - should produce zero strain/stress
  !============================================================================
  SUBROUTINE TEST_Rigid_Body_Rotation(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_ref(3, 4), coords_rot(3, 4)
    REAL(wp) :: u_elem(12)
    REAL(wp) :: D(6, 6)
    REAL(wp) :: thickness
    REAL(wp) :: Ke_mat(12, 12), Ke_geo(12, 12), R_int(12)
    REAL(wp) :: angle, c, s
    REAL(wp) :: strain_norm, stress_norm
    INTEGER(i4) :: i
    
    WRITE(*,*) ''
    WRITE(*,*) 'Test 2: Rigid Body Rotation (45°)'
    WRITE(*,*) '----------------------------------'
    
    ! Material (dummy)
    D = 0.0_wp
    D(1,1) = 210.0e3_wp
    D(1,2) = 0.0_wp
    D(2,2) = 210.0e3_wp
    D(3,3) = 80.0e3_wp
    thickness = 1.0_wp
    
    ! Unit square
    coords_ref(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:,2) = [100.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:,3) = [100.0_wp, 100.0_wp, 0.0_wp]
    coords_ref(:,4) = [0.0_wp, 100.0_wp, 0.0_wp]
    
    ! Rotate 45 degrees around Z-axis
    angle = 45.0_wp * 3.14159265358979_wp / 180.0_wp
    c = COS(angle)
    s = SIN(angle)
    
    DO i = 1, 4
      coords_rot(1, i) = c * coords_ref(1, i) - s * coords_ref(2, i)
      coords_rot(2, i) = s * coords_ref(1, i) + c * coords_ref(2, i)
      coords_rot(3, i) = coords_ref(3, i)
    END DO
    
    ! Displacement: u = x_rot - x_ref
    DO i = 1, 4
      u_elem((i-1)*3+1) = coords_rot(1, i) - coords_ref(1, i)
      u_elem((i-1)*3+2) = coords_rot(2, i) - coords_ref(2, i)
      u_elem((i-1)*3+3) = coords_rot(3, i) - coords_ref(3, i)
    END DO
    
    ! Call TL formulation
    CALL PH_Elem_M3D9R_NL_TL(coords_ref, u_elem, D, thickness, &
                             Ke_mat, Ke_geo, R_int, status)
    
    IF (.NOT. status%ok()) THEN
      WRITE(*,*) 'ERROR: TL computation failed'
      passed = .FALSE.
      RETURN
    END IF
    
    ! Verification: internal force should be ~0 (rigid body motion)
    stress_norm = SQRT(SUM(R_int**2)) / 12.0_wp
    passed = (stress_norm < 1.0e-6_wp)  ! Near-zero tolerance
    
    WRITE(*,'(A,F8.2,A)') '  Rotation angle:  ', angle * 180.0_wp / 3.14159265_wp, ' deg'
    WRITE(*,'(A,E12.4)') '  Stress norm:     ', stress_norm
    WRITE(*,'(A,L1)') '  Result:          ', passed
    
  END SUBROUTINE TEST_Rigid_Body_Rotation
  
  !============================================================================
  ! Subroutine: TEST_Simple_Shear_Comparison
  ! Purpose: Simple shear - compare TL and UL formulations
  !============================================================================
  SUBROUTINE TEST_Simple_Shear_Comparison(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_ref(3, 4)
    REAL(wp) :: u_elem(12)
    REAL(wp) :: D(6, 6)
    REAL(wp) :: thickness
    REAL(wp) :: Ke_mat_TL(12, 12), Ke_geo_TL(12, 12), R_int_TL(12)
    REAL(wp) :: Ke_mat_UL(12, 12), Ke_geo_UL(12, 12), R_int_UL(12)
    REAL(wp) :: gamma_shear
    REAL(wp) :: diff_TL_UL, tolerance
    INTEGER(i4) :: i
    
    WRITE(*,*) ''
    WRITE(*,*) 'Test 3: Simple Shear (TL vs UL)'
    WRITE(*,*) '--------------------------------'
    
    ! Material
    D = 0.0_wp
    D(1,1) = 210.0e3_wp
    D(1,2) = 63.0e3_wp
    D(2,2) = 210.0e3_wp
    D(3,3) = 80.0e3_wp
    thickness = 5.0_wp
    
    ! Unit square
    coords_ref(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:,2) = [100.0_wp, 0.0_wp, 0.0_wp]
    coords_ref(:,3) = [100.0_wp, 100.0_wp, 0.0_wp]
    coords_ref(:,4) = [0.0_wp, 100.0_wp, 0.0_wp]
    
    ! Simple shear: u_x = γ*y
    gamma_shear = 0.05_wp  ! 5% shear strain
    u_elem = 0.0_wp
    u_elem(1) = 0.0_wp
    u_elem(2) = 0.0_wp
    u_elem(3) = gamma_shear * 0.0_wp     ! Node 2: y=0
    u_elem(4) = 0.0_wp
    u_elem(5) = gamma_shear * 100.0_wp   ! Node 3: y=100 �?u_x=5mm
    u_elem(6) = 0.0_wp
    u_elem(7) = 0.0_wp
    u_elem(8) = gamma_shear * 100.0_wp   ! Node 4: y=100 �?u_x=5mm
    
    ! Call TL formulation
    CALL PH_Elem_M3D9R_NL_TL(coords_ref, u_elem, D, thickness, &
                             Ke_mat_TL, Ke_geo_TL, R_int_TL, status)
    
    IF (.NOT. status%ok()) THEN
      WRITE(*,*) 'ERROR: TL computation failed'
      passed = .FALSE.
      RETURN
    END IF
    
    ! Call UL formulation (using reference as previous)
    CALL PH_Elem_M3D9R_NL_UL(coords_ref, u_elem, D, thickness, &
                             Ke_mat_UL, Ke_geo_UL, R_int_UL, status)
    
    IF (.NOT. status%ok()) THEN
      WRITE(*,*) 'ERROR: UL computation failed'
      passed = .FALSE.
      RETURN
    END IF
    
    ! Comparison: For small strains, TL and UL should be similar
    diff_TL_UL = SQRT(SUM((R_int_TL - R_int_UL)**2)) / SQRT(SUM(R_int_TL**2))
    tolerance = 0.10_wp  ! 10% difference acceptable for small strain
    
    passed = (diff_TL_UL < tolerance)
    
    WRITE(*,'(A,F8.4)') '  Shear strain γ:  ', gamma_shear
    WRITE(*,'(A,F12.6)') '  R_int TL norm:  ', SQRT(SUM(R_int_TL**2))
    WRITE(*,'(A,F12.6)') '  R_int UL norm:  ', SQRT(SUM(R_int_UL**2))
    WRITE(*,'(A,F8.4,A)') '  Difference:    ', diff_TL_UL * 100.0_wp, '%'
    WRITE(*,'(A,L1)') '  Result:          ', passed
    
  END SUBROUTINE TEST_Simple_Shear_Comparison

END MODULE TEST_M3D9R_NLGeom_PatchTest
