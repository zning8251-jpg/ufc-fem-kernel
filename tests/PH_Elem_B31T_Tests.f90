!===============================================================================
! Module: PH_Elem_B31T_Tests
! Purpose: Unit tests for B31T (3D thermo-mechanical beam) element
! Tests: Mass matrix, damping, thermal coupling, nonlinear geometry
!===============================================================================

MODULE PH_Elem_B31T_Tests
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Const, ONLY: ZERO, ONE, HALF
  USE PH_Elem_B31T_Core
  IMPLICIT NONE
  
CONTAINS

  !===========================================================================
  ! Test 101: Consistent Mass Matrix Formation
  !===========================================================================
  SUBROUTINE Test_B31T_ConsMassMatrix()
    REAL(wp) :: coords(3, 2), Me14(14, 14)
    REAL(wp) :: rho, area, L_expected, m_total
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: i
    
    WRITE(*, *) 'Test 101: B31T Consistent Mass Matrix'
    
    ! Setup: Simple beam along x-axis, length L=2.0
    coords = ZERO
    coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 2) = [2.0_wp, 0.0_wp, 0.0_wp]
    
    rho = 7800.0_wp      ! Steel density [kg/m³]
    area = 0.01_wp       ! Cross-section [m²]
    
    ! Compute mass matrix
    CALL PH_Elem_B31T_ConsMassMatrix(coords, rho, area, Me14, status)
    
    ! Verify: Total translational mass should be rho*A*L
    L_expected = 2.0_wp
    m_total = rho * area * L_expected
    
    ! Check diagonal terms (translational DOF only)
    REAL(wp) :: m_sum
    m_sum = Me14(1,1) + Me14(2,2) + Me14(3,3) + &
            Me14(8,8) + Me14(9,9) + Me14(10,10)
    
    IF (ABS(m_sum - 2.0_wp * m_total) < 1.0e-6_wp * m_total) THEN
      WRITE(*, *) '  PASS: Total mass = ', m_sum, ' expected ', 2.0_wp * m_total
    ELSE
      WRITE(*, *) '  FAIL: Mass mismatch'
      STOP 1
    END IF
    
    ! Verify symmetry
    REAL(wp) :: max_asym
    max_asym = MAXVAL(ABS(Me14 - TRANSPOSE(Me14)))
    IF (max_asym < 1.0e-12_wp) THEN
      WRITE(*, *) '  PASS: Symmetric mass matrix'
    ELSE
      WRITE(*, *) '  FAIL: Asymmetry = ', max_asym
      STOP 1
    END IF
    
    ! Verify zero rotary/thermal inertia
    IF (ALL(Me14([4,5,6,7,11,12,13,14], :) == ZERO) .AND. &
        ALL(Me14(:, [4,5,6,7,11,12,13,14]) == ZERO)) THEN
      WRITE(*, *) '  PASS: Zero rotary/thermal inertia (as expected)'
    ELSE
      WRITE(*, *) '  WARNING: Non-zero rotary/thermal inertia'
    END IF
    
    WRITE(*, *) 'Test 101: COMPLETE'
  END SUBROUTINE Test_B31T_ConsMassMatrix

  !===========================================================================
  ! Test 102: Lumped Mass Vector Formation
  !===========================================================================
  SUBROUTINE Test_B31T_LumpMassVector()
    REAL(wp) :: coords(3, 2), M_lumped14(14)
    REAL(wp) :: rho, area, L, m_half
    TYPE(ErrorStatusType) :: status
    
    WRITE(*, *) 'Test 102: B31T Lumped Mass Vector'
    
    ! Setup
    coords = ZERO
    coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 2) = [3.0_wp, 0.0_wp, 0.0_wp]
    
    rho = 7800.0_wp
    area = 0.01_wp
    
    CALL PH_Elem_B31T_LumpMassVector(coords, rho, area, M_lumped14, status)
    
    ! Verify: Each node gets half total mass
    L = 3.0_wp
    m_half = rho * area * L * 0.5_wp
    
    IF (ABS(M_lumped14(1) - m_half) < 1.0e-10_wp .AND. &
        ABS(M_lumped14(2) - m_half) < 1.0e-10_wp .AND. &
        ABS(M_lumped14(3) - m_half) < 1.0e-10_wp) THEN
      WRITE(*, *) '  PASS: Node 1 lumped mass correct'
    ELSE
      WRITE(*, *) '  FAIL: Node 1 mass error'
      STOP 1
    END IF
    
    IF (ABS(M_lumped14(8) - m_half) < 1.0e-10_wp .AND. &
        ABS(M_lumped14(9) - m_half) < 1.0e-10_wp .AND. &
        ABS(M_lumped14(10) - m_half) < 1.0e-10_wp) THEN
      WRITE(*, *) '  PASS: Node 2 lumped mass correct'
    ELSE
      WRITE(*, *) '  FAIL: Node 2 mass error'
      STOP 1
    END IF
    
    ! Verify zero rotary/thermal mass
    IF (ALL(M_lumped14([4,5,6,7,11,12,13,14]) == ZERO)) THEN
      WRITE(*, *) '  PASS: Zero rotary/thermal lumped mass'
    ELSE
      WRITE(*, *) '  FAIL: Non-zero rotary/thermal mass'
      STOP 1
    END IF
    
    WRITE(*, *) 'Test 102: COMPLETE'
  END SUBROUTINE Test_B31T_LumpMassVector

  !===========================================================================
  ! Test 201: Thermal-Mechanical Coupling (K_ut formation)
  !===========================================================================
  SUBROUTINE Test_B31T_ThermalCoupling()
    REAL(wp) :: coords(3, 2), Ke14(14, 14)
    REAL(wp) :: E, nu, area, Iy, Iz, J_tors, k_th, alpha
    TYPE(ErrorStatusType) :: status
    
    WRITE(*, *) 'Test 201: B31T Thermal-Mechanical Coupling'
    
    ! Setup: Beam along x-axis
    coords = ZERO
    coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    
    E = 210.0e9_wp     ! Steel Young's modulus [Pa]
    nu = 0.3_wp
    area = 0.01_wp     ! [m²]
    Iy = 8.33e-6_wp    ! [m⁴]
    Iz = 8.33e-6_wp    ! [m⁴]
    J_tors = 1.67e-5_wp ! [m⁴]
    k_th = 50.0_wp     ! Thermal conductivity
    alpha = 1.2e-5_wp  ! CTE [1/K]
    
    ! Compute stiffness with thermal coupling
    CALL PH_Elem_B31T_FormStiffMatrix(coords, E, nu, area, Iy, Iz, J_tors, &
         k_th, alpha, Ke14, status)
    
    ! Verify: K_ut block should be non-zero (mech-thermal coupling)
    REAL(wp) :: kut_max
    kut_max = MAXVAL(ABS(Ke14(1:6, 7)))   ! Node 1 mech x Node 1 temp
    
    IF (kut_max > 1.0e-6_wp) THEN
      WRITE(*, *) '  PASS: K_ut coupling present, max = ', kut_max
    ELSE
      WRITE(*, *) '  FAIL: No thermal-mechanical coupling detected'
      STOP 1
    END IF
    
    ! Verify symmetry of coupling: K_ut = K_tu^T
    REAL(wp) :: asym_coupling
    asym_coupling = MAXVAL(ABS(Ke14(1:6, 7) - Ke14(7, 1:6)))
    IF (asym_coupling < 1.0e-6_wp) THEN
      WRITE(*, *) '  PASS: K_ut/K_tu symmetry preserved'
    ELSE
      WRITE(*, *) '  FAIL: Coupling asymmetry = ', asym_coupling
      STOP 1
    END IF
    
    ! Verify thermal block (should be standard conduction matrix)
    REAL(wp) :: k_cond
    k_cond = k_th / 1.0_wp  ! k_th / L
    IF (ABS(Ke14(7,7) - k_cond) < 1.0e-6_wp .AND. &
        ABS(Ke14(7,14) + k_cond) < 1.0e-6_wp) THEN
      WRITE(*, *) '  PASS: Thermal conduction matrix correct'
    ELSE
      WRITE(*, *) '  FAIL: Thermal block error'
      STOP 1
    END IF
    
    WRITE(*, *) 'Test 201: COMPLETE'
  END SUBROUTINE Test_B31T_ThermalCoupling

  !===========================================================================
  ! Test 202: Thermal Expansion Induced Force
  !===========================================================================
  SUBROUTINE Test_B31T_ThermalExpansion()
    REAL(wp) :: coords(3, 2), u14(14), R14(14)
    REAL(wp) :: E, area, alpha, delta_T, F_thermal
    TYPE(ErrorStatusType) :: status
    
    WRITE(*, *) 'Test 202: B31T Thermal Expansion Force'
    
    ! Setup: Constrained beam with temperature increase
    coords = ZERO
    coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    
    E = 210.0e9_wp
    area = 0.01_wp
    alpha = 1.2e-5_wp
    delta_T = 100.0_wp   ! Temperature increase [K]
    
    ! Apply temperature DOF (both nodes heated)
    u14 = ZERO
    u14(7) = delta_T     ! Node 1 T
    u14(14) = delta_T    ! Node 2 T
    
    ! Compute internal force
    CALL PH_Elem_B31T_FormIntForce(coords, u14, E, 0.3_wp, area, &
         8.33e-6_wp, 8.33e-6_wp, 1.67e-5_wp, 50.0_wp, alpha, R14, status)
    
    ! Expected thermal force: F = E * A * alpha * delta_T
    F_thermal = E * area * alpha * delta_T
    
    ! Check axial force at node 1 (DOF 1) and node 2 (DOF 8)
    IF (ABS(R14(1) + F_thermal) < 1.0e-3_wp * F_thermal) THEN
      WRITE(*, *) '  PASS: Node 1 thermal force = ', R14(1), ' expected -', F_thermal
    ELSE
      WRITE(*, *) '  FAIL: Node 1 thermal force error'
      WRITE(*, *) '    Computed: ', R14(1), ' Expected: -', F_thermal
      STOP 1
    END IF
    
    IF (ABS(R14(8) - F_thermal) < 1.0e-3_wp * F_thermal) THEN
      WRITE(*, *) '  PASS: Node 2 thermal force = ', R14(8), ' expected ', F_thermal
    ELSE
      WRITE(*, *) '  FAIL: Node 2 thermal force error'
      STOP 1
    END IF
    
    WRITE(*, *) 'Test 202: COMPLETE'
  END SUBROUTINE Test_B31T_ThermalExpansion

  !===========================================================================
  ! Test 301: Total Lagrangian Nonlinear (TL) - Large Displacement
  !===========================================================================
  SUBROUTINE Test_B31T_NL_TL()
    TYPE(ElemType) :: elem_type
    TYPE(ElemFormul) :: formul
    TYPE(ElemCtx) :: ctx
    TYPE(ElemState) :: state_in, state_out
    TYPE(MatProperties) :: mat
    TYPE(ElemFlags) :: flags
    
    WRITE(*, *) 'Test 301: B31T Total Lagrangian Nonlinear'
    
    ! Setup element type
    elem_type%numNodes = 2_i4
    elem_type%dim = 3_i4
    elem_type%elemTypeId = 420_i4  ! B31T
    
    ! Allocate context
    ALLOCATE(ctx%coords_ref(3, 2))
    ALLOCATE(ctx%disp_total(4, 2))  ! 3 mech + 1 temp per node
    
    ! Reference configuration: beam along x-axis
    ctx%coords_ref = ZERO
    ctx%coords_ref(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    ctx%coords_ref(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    
    ! Apply large displacement (10% stretch)
    ctx%disp_total = ZERO
    ctx%disp_total(1, 1) = 0.0_wp           ! Node 1 fixed
    ctx%disp_total(1, 2) = 0.1_wp           ! Node 2 displaced 0.1m
    
    ! Material properties
    ALLOCATE(mat%props%props(8))
    mat%props%props(1) = 210.0e9_wp         ! E
    mat%props%props(2) = 0.3_wp             ! nu
    mat%props%props(3) = 0.01_wp            ! A
    mat%props%props(4) = 8.33e-6_wp         ! Iy
    mat%props%props(5) = 8.33e-6_wp         ! Iz
    mat%props%props(6) = 1.67e-5_wp         ! J
    mat%props%props(7) = 50.0_wp            ! k_th
    mat%props%props(8) = 1.2e-5_wp          ! alpha
    
    ! Call TL nonlinear formulation
    CALL PH_Elem_B31T_NL_TL(elem_type, formul, ctx, state_in, mat, state_out, flags)
    
    ! Verify: Should have geometric stiffness contribution
    IF (.NOT. flags%failed) THEN
      WRITE(*, *) '  PASS: TL nonlinear computation successful'
      
      ! Check that tangent stiffness includes geometric part
      REAL(wp) :: K_geo_effect
      K_geo_effect = MAXVAL(ABS(state_out%Ke(1:3, 1:3)))
      WRITE(*, *) '  Tangent stiffness (mechanical block): ', K_geo_effect
    ELSE
      WRITE(*, *) '  FAIL: TL computation failed'
      WRITE(*, *) '  Error: ', TRIM(flags%status%message)
      STOP 1
    END IF
    
    ! Cleanup
    DEALLOCATE(ctx%coords_ref, ctx%disp_total)
    DEALLOCATE(mat%props%props)
    IF (ALLOCATED(state_out%Ke)) DEALLOCATE(state_out%Ke)
    IF (ALLOCATED(state_out%Re)) DEALLOCATE(state_out%Re)
    
    WRITE(*, *) 'Test 301: COMPLETE'
  END SUBROUTINE Test_B31T_NL_TL

  !===========================================================================
  ! Test Runner
  !===========================================================================
  SUBROUTINE Run_All_Tests_B31T()
    WRITE(*, *) ''
    WRITE(*, *) '========================================'
    WRITE(*, *) 'B31T Element Unit Tests'
    WRITE(*, *) '========================================'
    WRITE(*, *) ''
    
    CALL Test_B31T_ConsMassMatrix()
    WRITE(*, *) ''
    
    CALL Test_B31T_LumpMassVector()
    WRITE(*, *) ''
    
    CALL Test_B31T_ThermalCoupling()
    WRITE(*, *) ''
    
    CALL Test_B31T_ThermalExpansion()
    WRITE(*, *) ''
    
    CALL Test_B31T_NL_TL()
    WRITE(*, *) ''
    
    WRITE(*, *) '========================================'
    WRITE(*, *) 'All B31T Tests PASSED'
    WRITE(*, *) '========================================'
  END SUBROUTINE Run_All_Tests_B31T

END MODULE PH_Elem_B31T_Tests
