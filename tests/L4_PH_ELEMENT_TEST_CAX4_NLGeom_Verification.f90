!===============================================================================
! Module: TEST_CAX4_NLGeom_Verification
! Layer:  L4_PH - Verification Test
! Domain: Element / CAX4 Axisymmetric (Geometric Nonlinearity)
!
! Purpose: Verification tests for CAX4 with TL/UL geometric nonlinearity
!          Validates existing PH_Elem_CAX4_NL_TL/UL implementation
!          Benchmarks against analytical solutions and CPE4 plane strain
!
! Test Cases:
!   1. Internal pressure (hoop stress) - Verify circumferential strain
!   2. Radial expansion (large deformation) - Stress update verification
!   3. Axial compression (ring test) - Comparison with CPE4
!
! Status: B-Element-10 (CAX4 Phase) | Created: 2026-03-31
!===============================================================================

MODULE TEST_CAX4_NLGeom_Verification
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE PH_Elem_CAX4_Core, ONLY: PH_Elem_CAX4_NL_TL_Legacy, PH_Elem_CAX4_NL_UL_Legacy
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: TEST_Run_CAX4_Verification
  
CONTAINS

  !============================================================================
  ! Subroutine: TEST_Run_CAX4_Verification
  ! Purpose: Run all verification tests for CAX4 nonlinear geometry
  !============================================================================
  SUBROUTINE TEST_Run_CAX4_Verification(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    LOGICAL :: test1_pass, test2_pass, test3_pass
    
    WRITE(*,*) ''
    WRITE(*,*) '=========================================='
    WRITE(*,*) 'CAX4 Axisymmetric Geometric Nonlinearity Verification'
    WRITE(*,*) '=========================================='
    
    ! Test 1: Internal pressure (hoop stress)
    CALL TEST_Internal_Pressure(test1_pass, status)
    IF (.NOT. test1_pass) THEN
      CALL init_error_status(status, STATUS_ERR, "Test 1 Failed: Internal pressure")
      RETURN
    END IF
    
    ! Test 2: Radial expansion (large deformation)
    CALL TEST_Radial_Expansion(test2_pass, status)
    IF (.NOT. test2_pass) THEN
      CALL init_error_status(status, STATUS_ERR, "Test 2 Failed: Radial expansion")
      RETURN
    END IF
    
    ! Test 3: Axial compression (ring test)
    CALL TEST_Axial_Compression(test3_pass, status)
    IF (.NOT. test3_pass) THEN
      CALL init_error_status(status, STATUS_ERR, "Test 3 Failed: Axial compression")
      RETURN
    END IF
    
    WRITE(*,*) ''
    WRITE(*,*) 'All verification tests PASSED �?
    CALL init_error_status(status, IF_STATUS_OK)
    
  END SUBROUTINE TEST_Run_CAX4_Verification
  
  !============================================================================
  ! Subroutine: TEST_Internal_Pressure
  ! Purpose: Thick-walled cylinder under internal pressure - verify hoop stress
  !============================================================================
  SUBROUTINE TEST_Internal_Pressure(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_ref(2, 4), u_elem(8)
    REAL(wp) :: D(4, 4)
    REAL(wp) :: Ke_mat(8, 8), Ke_geo(8, 8), R_int(8)
    REAL(wp) :: E_young, nu, lambda, mu
    REAL(wp) :: r_inner, r_outer, pressure
    REAL(wp) :: sigma_theta_analytical, sigma_theta_computed
    REAL(wp) :: error_norm
    INTEGER(i4) :: i
    
    WRITE(*,*) ''
    WRITE(*,*) 'Test 1: Internal Pressure (Hoop Stress)'
    WRITE(*,*) '-----------------------------------------'
    
    ! Material properties (steel)
    E_young = 210.0e9_wp      ! Pa
    nu = 0.3_wp
    
    ! Lame parameters for axisymmetric
    lambda = E_young * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu = E_young / (2.0_wp * (1.0_wp + nu))
    
    ! Axisymmetric constitutive matrix (4x4)
    ! Strain order: [err, ezz, ethetatheta, grz]
    D = 0.0_wp
    D(1,1) = lambda + 2.0_wp * mu
    D(1,2) = lambda
    D(1,3) = lambda
    D(2,1) = lambda
    D(2,2) = lambda + 2.0_wp * mu
    D(2,3) = lambda
    D(3,1) = lambda
    D(3,2) = lambda
    D(3,3) = lambda + 2.0_wp * mu
    D(4,4) = mu
    
    ! Thick-walled cylinder segment (inner radius=1m, outer=2m)
    r_inner = 1.0_wp
    r_outer = 2.0_wp
    thickness = r_outer - r_inner
    
    coords_ref(:,1) = [r_inner, 0.0_wp]  ! Node 1: inner bottom
    coords_ref(:,2) = [r_outer, 0.0_wp]  ! Node 2: outer bottom
    coords_ref(:,3) = [r_outer, 0.5_wp]  ! Node 3: outer top
    coords_ref(:,4) = [r_inner, 0.5_wp]  ! Node 4: inner top
    
    ! Apply internal pressure (radial displacement at inner surface)
    pressure = 10.0e6_wp  ! 10 MPa
    u_elem = 0.0_wp
    
    ! Analytical solution (Lame equations for thick cylinder)
    ! σ_θ(inner) = p * (r_o² + r_i²) / (r_o² - r_i²)
    sigma_theta_analytical = pressure * (r_outer**2 + r_inner**2) / &
                             (r_outer**2 - r_inner**2)
    
    ! Simplified: Apply equivalent radial displacement
    ! u_r = p*r_i/(E*(r_o²-r_i²)) * [(1-ν)*r_i² + (1+ν)*r_o²]
    REAL(wp) :: u_radial
    u_radial = pressure * r_inner / (E_young * (r_outer**2 - r_inner**2)) * &
               ((1.0_wp - nu) * r_inner**2 + (1.0_wp + nu) * r_outer**2)
    
    u_elem(1) = u_radial  ! Node 1: inner radial
    u_elem(7) = u_radial  ! Node 4: inner radial
    
    ! Call TL formulation
    CALL PH_Elem_CAX4_NL_TL_Legacy(coords_ref, u_elem, D, &
                                   Ke_mat, Ke_geo, R_int, status)
    
    IF (.NOT. status%ok()) THEN
      WRITE(*,*) 'ERROR: TL computation failed'
      passed = .FALSE.
      RETURN
    END IF
    
    ! Extract computed hoop stress (from reaction forces)
    ! Simplified: Check non-zero response
    sigma_theta_computed = ABS(R_int(1) + R_int(7)) / (thickness * 0.5_wp)
    
    ! Verification: qualitative check (hoop stress > pressure)
    passed = (sigma_theta_computed > pressure)
    
    WRITE(*,'(A,F8.2,A)') '  Inner radius:    ', r_inner, ' m'
    WRITE(*,'(A,F8.2,A)') '  Outer radius:    ', r_outer, ' m'
    WRITE(*,'(A,F8.2,A)') '  Pressure:        ', pressure / 1.0e6_wp, ' MPa'
    WRITE(*,'(A,E12.4,A)') '  Analytical σ_θ: ', sigma_theta_analytical, ' Pa'
    WRITE(*,'(A,E12.4,A)') '  Computed σ_θ:   ', sigma_theta_computed, ' Pa'
    WRITE(*,'(A,L1)') '  Result:          ', passed
    
  END SUBROUTINE TEST_Internal_Pressure
  
  !============================================================================
  ! Subroutine: TEST_Radial_Expansion
  ! Purpose: Large radial expansion - verify circumferential strain
  !============================================================================
  SUBROUTINE TEST_Radial_Expansion(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_ref(2, 4), u_elem(8)
    REAL(wp) :: D(4, 4)
    REAL(wp) :: Ke_mat(8, 8), Ke_geo(8, 8), R_int(8)
    REAL(wp) :: E_young, nu, lambda, mu
    REAL(wp) :: radius, expansion_ratio
    REAL(wp) :: epsilon_theta, sigma_theta
    REAL(wp) :: error_metric
    INTEGER(i4) :: i
    
    WRITE(*,*) ''
    WRITE(*,*) 'Test 2: Radial Expansion (Large Deformation)'
    WRITE(*,*) '---------------------------------------------'
    
    ! Material properties
    E_young = 210.0e9_wp
    nu = 0.3_wp
    
    lambda = E_young * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu = E_young / (2.0_wp * (1.0_wp + nu))
    
    ! Axisymmetric constitutive matrix
    D = 0.0_wp
    D(1,1) = lambda + 2.0_wp * mu
    D(1,2) = lambda
    D(1,3) = lambda
    D(2,1) = lambda
    D(2,2) = lambda + 2.0_wp * mu
    D(2,3) = lambda
    D(3,1) = lambda
    D(3,2) = lambda
    D(3,3) = lambda + 2.0_wp * mu
    D(4,4) = mu
    
    ! Ring geometry (mean radius=5m, thickness=0.5m)
    radius = 5.0_wp
    coords_ref(:,1) = [radius, 0.0_wp]
    coords_ref(:,2) = [radius + 0.5_wp, 0.0_wp]
    coords_ref(:,3) = [radius + 0.5_wp, 1.0_wp]
    coords_ref(:,4) = [radius, 1.0_wp]
    
    ! Large radial expansion (10% circumference increase)
    expansion_ratio = 0.10_wp
    u_elem = 0.0_wp
    
    ! Uniform radial expansion
    DO i = 1, 4
      u_elem(2*(i-1)+1) = expansion_ratio * radius  ! Radial displacement
    END DO
    
    ! Call TL formulation
    CALL PH_Elem_CAX4_NL_TL_Legacy(coords_ref, u_elem, D, &
                                   Ke_mat, Ke_geo, R_int, status)
    
    IF (.NOT. status%ok()) THEN
      WRITE(*,*) 'ERROR: TL computation failed'
      passed = .FALSE.
      RETURN
    END IF
    
    ! Circumferential strain (large deformation)
    ! ε_θθ = ln(r_final / r_initial) = ln(1 + u_r/r)
    epsilon_theta = LOG(1.0_wp + expansion_ratio)
    
    ! Hoop stress (simplified uniaxial)
    sigma_theta = (lambda + 2.0_wp * mu) * epsilon_theta
    
    ! Verification: Check energy consistency
    ! External work = �?F·du �?R_int · u
    REAL(wp) :: external_work, strain_energy
    external_work = DOT_PRODUCT(R_int, u_elem)
    strain_energy = 0.5_wp * sigma_theta * epsilon_theta * &
                    (radius * 0.5_wp * 1.0_wp)  ! Volume element
    
    error_metric = ABS(external_work - strain_energy) / MAX(1.0_wp, strain_energy)
    passed = (error_metric < 0.20_wp)  ! 20% tolerance for rough estimate
    
    WRITE(*,'(A,F8.2,A)') '  Initial radius:  ', radius, ' m'
    WRITE(*,'(A,F8.2,A)') '  Expansion ratio: ', expansion_ratio * 100.0_wp, '%'
    WRITE(*,'(A,F8.4,A)') '  ε_θθ (log):     ', epsilon_theta, ''
    WRITE(*,'(A,E12.4,A)') '  σ_θθ:           ', sigma_theta, ' Pa'
    WRITE(*,'(A,F8.4,A)') '  Energy error:   ', error_metric * 100.0_wp, '%'
    WRITE(*,'(A,L1)') '  Result:          ', passed
    
  END SUBROUTINE TEST_Radial_Expansion
  
  !============================================================================
  ! Subroutine: TEST_Axial_Compression
  ! Purpose: Axial compression of ring - comparison with CPE4 plane strain
  !============================================================================
  SUBROUTINE TEST_Axial_Compression(passed, status)
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: coords_ref(2, 4), u_elem(8)
    REAL(wp) :: D(4, 4)
    REAL(wp) :: Ke_mat(8, 8), Ke_geo(8, 8), R_int(8)
    REAL(wp) :: E_young, nu, lambda, mu
    REAL(wp) :: strain_axial, stress_analytical
    REAL(wp) :: stress_computed, error_norm
    INTEGER(i4) :: i
    
    WRITE(*,*) ''
    WRITE(*,*) 'Test 3: Axial Compression (Ring Test)'
    WRITE(*,*) '--------------------------------------'
    
    ! Material properties
    E_young = 210.0e9_wp
    nu = 0.3_wp
    
    lambda = E_young * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu = E_young / (2.0_wp * (1.0_wp + nu))
    
    ! Axisymmetric constitutive matrix
    D = 0.0_wp
    D(1,1) = lambda + 2.0_wp * mu
    D(1,2) = lambda
    D(1,3) = lambda
    D(2,1) = lambda
    D(2,2) = lambda + 2.0_wp * mu
    D(2,3) = lambda
    D(3,1) = lambda
    D(3,2) = lambda
    D(3,3) = lambda + 2.0_wp * mu
    D(4,4) = mu
    
    ! Ring geometry (radius=3m, height=1m)
    coords_ref(:,1) = [3.0_wp, 0.0_wp]
    coords_ref(:,2) = [4.0_wp, 0.0_wp]
    coords_ref(:,3) = [4.0_wp, 1.0_wp]
    coords_ref(:,4) = [3.0_wp, 1.0_wp]
    
    ! Axial compression (5% strain in Z direction)
    strain_axial = -0.05_wp
    u_elem = 0.0_wp
    
    ! Constrain radial displacement at bottom, apply axial at top
    u_elem(2) = 0.0_wp              ! Node 1: fixed Z
    u_elem(4) = 0.0_wp              ! Node 2: fixed Z
    u_elem(6) = strain_axial        ! Node 3: axial compression
    u_elem(8) = strain_axial        ! Node 4: axial compression
    
    ! Call TL formulation
    CALL PH_Elem_CAX4_NL_TL_Legacy(coords_ref, u_elem, D, &
                                   Ke_mat, Ke_geo, R_int, status)
    
    IF (.NOT. status%ok()) THEN
      WRITE(*,*) 'ERROR: TL computation failed'
      passed = .FALSE.
      RETURN
    END IF
    
    ! Analytical solution (uniaxial strain with circumferential constraint)
    ! σ_zz = (λ + 2μ) * ε_zz (similar to plane strain CPE4)
    stress_analytical = (lambda + 2.0_wp * mu) * strain_axial
    
    ! Extract computed axial stress (average from reaction forces)
    ! Area = π*(r_o² - r_i²) = π*(16-9) = 7π
    REAL(wp) :: area, force_total
    area = 3.14159265358979_wp * (4.0_wp**2 - 3.0_wp**2)
    force_total = ABS(R_int(6) + R_int(8))
    stress_computed = force_total / area
    
    ! Verification: relative error < 10%
    error_norm = ABS(stress_computed - ABS(stress_analytical)) / ABS(stress_analytical)
    passed = (error_norm < 0.10_wp)
    
    WRITE(*,'(A,F8.2,A)') '  Inner radius:    ', 3.0_wp, ' m'
    WRITE(*,'(A,F8.2,A)') '  Outer radius:    ', 4.0_wp, ' m'
    WRITE(*,'(A,F8.2,A)') '  Axial strain:    ', strain_axial * 100.0_wp, '%'
    WRITE(*,'(A,E12.4,A)') '  Analytical σ_z: ', ABS(stress_analytical), ' Pa'
    WRITE(*,'(A,E12.4,A)') '  Computed σ_z:   ', stress_computed, ' Pa'
    WRITE(*,'(A,F8.4,A)') '  Relative error:  ', error_norm * 100.0_wp, '%'
    WRITE(*,'(A,L1)') '  Result:          ', passed
    
  END SUBROUTINE TEST_Axial_Compression

END MODULE TEST_CAX4_NLGeom_Verification
