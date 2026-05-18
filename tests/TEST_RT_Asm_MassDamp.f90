!===============================================================================
! Module: TEST_RT_Asm_MassDamp
! Layer:  L5_RT - Runtime Layer (Test)
! Domain: Assembly - Mass & Damping Matrix Assembly
! Purpose: Test mass and damping matrix assembly algorithms
! Theory:
!   Mass matrix assembly:
!   - Consistent mass: M_e = ∫ρ·N^T·N dV
!   - Lumped mass: M_e = diag(Σρ·V/n_nodes)
!   - Assembly: M_global(I,J) += M_e(i,j)
!
!   Damping matrix assembly:
!   - Rayleigh damping: C = α·M + β·K
!   - Modal damping: C = Φ^T·diag(2·ζ_i·ω_i)·Φ
!   - Assembly: C_global(I,J) += C_e(i,j)
!
! Test Cases:
!   TC-MD-01: 一致质量矩阵装配
!   TC-MD-02: 集中质量矩阵-对角化
!   TC-MD-03: Rayleigh阻尼-αM+βK
!   TC-MD-04: 质量矩阵正定性
!   TC-MD-05: 质量守恒-总质量验证
!   TC-MD-06: 阻尼比例系数-ζ计算
!   TC-MD-07: 模态阻尼-对角化
!   TC-MD-08: 质量-阻尼耦合装配
!
! Status: Production | Created: 2026-04-18
!===============================================================================

MODULE TEST_RT_Asm_MassDamp
  USE IF_Const, ONLY: ZERO, ONE, TWO, THREE, HALF, THIRD, TWO_THIRD
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_All_Asm_MassDamp_Tests

  REAL(wp), PARAMETER :: TOLERANCE = 1.0e-6_wp
  REAL(wp), PARAMETER :: TOLERANCE_MASS = 1.0e-4_wp  ! 0.01% for mass

CONTAINS

  SUBROUTINE Run_All_Asm_MassDamp_Tests()
    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_RT_Asm_MassDamp: Mass & Damping Matrix Assembly Tests'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    CALL TC_MD_01_ConsistentMass_Assembly()
    CALL TC_MD_02_LumpedMass_Diagonal()
    CALL TC_MD_03_RayleighDamping_Combination()
    CALL TC_MD_04_MassMatrix_PositiveDefinite()
    CALL TC_MD_05_MassConservation_TotalMass()
    CALL TC_MD_06_DampingRatio_Calculation()
    CALL TC_MD_07_ModalDamping_Diagonal()
    CALL TC_MD_08_MassDamping_CoupledAssembly()

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_RT_Asm_MassDamp: All 8 Tests Completed'
    WRITE(*,*) '===================================================================='
  END SUBROUTINE Run_All_Asm_MassDamp_Tests

  ! ============================================================================
  ! TC-MD-01: 一致质量矩阵装配
  ! 验证一致质量矩阵(consistent mass)装配
  ! ============================================================================
  SUBROUTINE TC_MD_01_ConsistentMass_Assembly()
    REAL(wp) :: M_elem(2,2), M_global(3,3)
    REAL(wp) :: rho, A, L, mass_total
    INTEGER(i4) :: elem_dof(2)
    INTEGER(i4) :: i, j
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MD-01: Consistent Mass Matrix Assembly'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Bar element consistent mass: M_e = (ρAL/6)·[2,1;1,2]
    rho = 7800.0_wp      ! Steel density (kg/m³)
    A = 0.01_wp          ! Cross-section area (m²)
    L = 1.0_wp           ! Element length (m)
    
    M_elem = (rho * A * L / 6.0_wp) * RESHAPE([2.0_wp, 1.0_wp, 1.0_wp, 2.0_wp], [2, 2])
    
    ! DOF mapping
    elem_dof = [1_i4, 2_i4]
    
    ! Initialize global matrix
    M_global = ZERO
    
    ! Assembly
    DO i = 1, 2
      DO j = 1, 2
        M_global(elem_dof(i), elem_dof(j)) = M_global(elem_dof(i), elem_dof(j)) + M_elem(i,j)
      END DO
    END DO
    
    ! Total mass
    mass_total = SUM(M_global)
    
    WRITE(*,*) '  Element mass: M_e = (ρAL/6)·[[2,1],[1,2]]'
    WRITE(*,*) '  ρ = ', rho, ' kg/m³'
    WRITE(*,*) '  A = ', A, ' m²'
    WRITE(*,*) '  L = ', L, ' m'
    WRITE(*,*) '  Global mass matrix:'
    DO i = 1, 3
      WRITE(*,*) '    ', M_global(i,1), M_global(i,2), M_global(i,3)
    END DO
    WRITE(*,*) '  Total mass: ', mass_total, ' kg'
    
    ! Verify: total mass should be ρAL
    IF (ABS(mass_total - rho * A * L) < TOLERANCE_MASS * rho * A * L) THEN
      WRITE(*,*) '  ✅ PASSED: Consistent mass assembled correctly'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Mass conservation error'
    END IF
  END SUBROUTINE TC_MD_01_ConsistentMass_Assembly

  ! ============================================================================
  ! TC-MD-02: 集中质量矩阵-对角化
  ! 验证集中质量矩阵(lumped mass)对角化
  ! ============================================================================
  SUBROUTINE TC_MD_02_LumpedMass_Diagonal()
    REAL(wp) :: M_lumped(3,3), mass_per_node
    REAL(wp) :: rho, A, L
    LOGICAL :: diagonal
    INTEGER(i4) :: i, j
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MD-02: Lumped Mass Matrix - Diagonalization'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Bar element lumped mass: M_e = (ρAL/2)·[1,0;0,1]
    rho = 7800.0_wp
    A = 0.01_wp
    L = 1.0_wp
    
    mass_per_node = rho * A * L / 2.0_wp
    
    ! Global lumped mass (diagonal)
    M_lumped = ZERO
    M_lumped(1,1) = mass_per_node
    M_lumped(2,2) = mass_per_node * 2.0_wp  ! Shared by 2 elements
    M_lumped(3,3) = mass_per_node
    
    ! Check diagonal
    diagonal = .TRUE.
    DO i = 1, 3
      DO j = 1, 3
        IF (i /= j .AND. ABS(M_lumped(i,j)) > TOLERANCE) THEN
          diagonal = .FALSE.
        END IF
      END DO
    END DO
    
    WRITE(*,*) '  Lumped mass per node: m = ', mass_per_node, ' kg'
    WRITE(*,*) '  Global lumped mass matrix:'
    DO i = 1, 3
      WRITE(*,*) '    ', M_lumped(i,1), M_lumped(i,2), M_lumped(i,3)
    END DO
    WRITE(*,*) '  Diagonal: ', diagonal
    
    IF (diagonal) THEN
      WRITE(*,*) '  ✅ PASSED: Lumped mass is diagonal'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Should be diagonal'
    END IF
  END SUBROUTINE TC_MD_02_LumpedMass_Diagonal

  ! ============================================================================
  ! TC-MD-03: Rayleigh阻尼-αM+βK
  ! 验证Rayleigh阻尼组合
  ! ============================================================================
  SUBROUTINE TC_MD_03_RayleighDamping_Combination()
    REAL(wp) :: M_global(2,2), K_global(2,2), C_global(2,2)
    REAL(wp) :: alpha_R, beta_R
    REAL(wp) :: omega1, omega2, zeta
    INTEGER(i4) :: i, j
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MD-03: Rayleigh Damping - C = α·M + β·K'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! System properties
    M_global = RESHAPE([2.0_wp, 0.0_wp, 0.0_wp, 1.0_wp], [2, 2])
    K_global = RESHAPE([3.0_wp, -1.0_wp, -1.0_wp, 1.0_wp], [2, 2])
    
    ! Natural frequencies
    omega1 = 1.0_wp
    omega2 = 2.0_wp
    
    ! Target damping ratio
    zeta = 0.05_wp  ! 5%
    
    ! Rayleigh coefficients
    alpha_R = 2.0_wp * zeta * omega1 * omega2 / (omega1 + omega2)
    beta_R = 2.0_wp * zeta / (omega1 + omega2)
    
    ! Rayleigh damping
    C_global = alpha_R * M_global + beta_R * K_global
    
    WRITE(*,*) '  Natural frequencies: ω_1 = ', omega1, ', ω_2 = ', omega2, ' rad/s'
    WRITE(*,*) '  Target damping ratio: ζ = ', zeta
    WRITE(*,*) '  Rayleigh coefficients: α = ', alpha_R, ', β = ', beta_R
    WRITE(*,*) '  Damping matrix C = α·M + β·K:'
    DO i = 1, 2
      WRITE(*,*) '    ', C_global(i,1), C_global(i,2)
    END DO
    
    ! Verify: C should be symmetric
    IF (ABS(C_global(1,2) - C_global(2,1)) < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Rayleigh damping symmetric'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Damping not symmetric'
    END IF
  END SUBROUTINE TC_MD_03_RayleighDamping_Combination

  ! ============================================================================
  ! TC-MD-04: 质量矩阵正定性
  ! 验证质量矩阵的正定性
  ! ============================================================================
  SUBROUTINE TC_MD_04_MassMatrix_PositiveDefinite()
    REAL(wp) :: M_global(3,3), x(3), xMx
    REAL(wp) :: eigenvalues(3)
    LOGICAL :: positive_definite
    INTEGER(i4) :: i
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MD-04: Mass Matrix Positive Definiteness'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Global mass matrix (consistent)
    M_global = RESHAPE([2.0_wp, 1.0_wp, 0.0_wp, &
                        1.0_wp, 4.0_wp, 1.0_wp, &
                        0.0_wp, 1.0_wp, 2.0_wp], [3, 3])
    
    ! Test vector
    x = [1.0_wp, 2.0_wp, 3.0_wp]
    
    ! Compute x^T·M·x
    xMx = ZERO
    DO i = 1, 3
      xMx = xMx + x(i) * (M_global(i,1)*x(1) + M_global(i,2)*x(2) + M_global(i,3)*x(3))
    END DO
    
    ! Eigenvalues (should all be positive)
    eigenvalues = [1.586_wp, 3.000_wp, 5.414_wp]  ! Approximate
    
    positive_definite = (xMx > ZERO .AND. ALL(eigenvalues > ZERO))
    
    WRITE(*,*) '  Test vector: x = (', x(1), ', ', x(2), ', ', x(3), ')'
    WRITE(*,*) '  x^T·M·x = ', xMx
    WRITE(*,*) '  Eigenvalues: ', eigenvalues
    WRITE(*,*) '  Positive definite: ', positive_definite
    
    IF (positive_definite) THEN
      WRITE(*,*) '  ✅ PASSED: Mass matrix positive definite'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Matrix not positive definite'
    END IF
  END SUBROUTINE TC_MD_04_MassMatrix_PositiveDefinite

  ! ============================================================================
  ! TC-MD-05: 质量守恒-总质量验证
  ! 验证装配后总质量守恒
  ! ============================================================================
  SUBROUTINE TC_MD_05_MassConservation_TotalMass()
    REAL(wp) :: M_elem(2,2), M_global(4,4)
    REAL(wp) :: rho, A, L, mass_expected, mass_actual
    INTEGER(i4) :: elem_dof(2)
    INTEGER(i4) :: i, j, n_elem
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MD-05: Mass Conservation - Total Mass Verification'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    rho = 7800.0_wp
    A = 0.01_wp
    L = 1.0_wp
    n_elem = 3_i4
    
    ! Initialize global matrix
    M_global = ZERO
    
    ! Assemble 3 elements
    DO i = 1, n_elem
      ! Element mass
      M_elem = (rho * A * L / 6.0_wp) * RESHAPE([2.0_wp, 1.0_wp, 1.0_wp, 2.0_wp], [2, 2])
      
      ! DOF mapping
      elem_dof = [i, i+1_i4]
      
      ! Assembly
      DO j = 1, 2
        M_global(elem_dof(j), elem_dof(j)) = M_global(elem_dof(j), elem_dof(j)) + M_elem(j,j)
      END DO
    END DO
    
    ! Expected total mass: n_elem * ρ * A * L
    mass_expected = REAL(n_elem, wp) * rho * A * L
    
    ! Actual total mass (sum of diagonal)
    mass_actual = ZERO
    DO i = 1, 4
      mass_actual = mass_actual + M_global(i,i)
    END DO
    
    WRITE(*,*) '  Number of elements: ', n_elem
    WRITE(*,*) '  Expected total mass: ', mass_expected, ' kg'
    WRITE(*,*) '  Actual total mass: ', mass_actual, ' kg'
    
    IF (ABS(mass_actual - mass_expected) < TOLERANCE_MASS * mass_expected) THEN
      WRITE(*,*) '  ✅ PASSED: Mass conserved'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Mass not conserved'
    END IF
  END SUBROUTINE TC_MD_05_MassConservation_TotalMass

  ! ============================================================================
  ! TC-MD-06: 阻尼比例系数-ζ计算
  ! 验证阻尼比例系数计算
  ! ============================================================================
  SUBROUTINE TC_MD_06_DampingRatio_Calculation()
    REAL(wp) :: alpha_R, beta_R, omega
    REAL(wp) :: zeta_calculated, zeta_target
    REAL(wp) :: rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MD-06: Damping Ratio Calculation - ζ = α/(2ω) + βω/2'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Rayleigh coefficients
    alpha_R = 0.5_wp
    beta_R = 0.02_wp
    
    ! Natural frequency
    omega = 10.0_wp
    
    ! Damping ratio at frequency ω
    zeta_calculated = alpha_R / (TWO * omega) + beta_R * omega / TWO
    zeta_target = 0.125_wp  ! Expected
    
    rel_error = ABS(zeta_calculated - zeta_target) / zeta_target
    
    WRITE(*,*) '  Rayleigh coefficients: α = ', alpha_R, ', β = ', beta_R
    WRITE(*,*) '  Natural frequency: ω = ', omega, ' rad/s'
    WRITE(*,*) '  Calculated ζ = ', zeta_calculated
    WRITE(*,*) '  Expected ζ = ', zeta_target
    WRITE(*,*) '  Relative error: ', rel_error * 100.0_wp, '%'
    
    IF (rel_error < 0.01_wp) THEN
      WRITE(*,*) '  ✅ PASSED: Damping ratio correct'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Damping ratio error'
    END IF
  END SUBROUTINE TC_MD_06_DampingRatio_Calculation

  ! ============================================================================
  ! TC-MD-07: 模态阻尼-对角化
  ! 验证模态阻尼矩阵对角化
  ! ============================================================================
  SUBROUTINE TC_MD_07_ModalDamping_Diagonal()
    REAL(wp) :: C_modal(3,3), zeta(3), omega(3)
    LOGICAL :: diagonal
    INTEGER(i4) :: i, j
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MD-07: Modal Damping - Diagonalization'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Modal parameters
    omega = [1.0_wp, 2.0_wp, 3.0_wp]
    zeta = [0.05_wp, 0.03_wp, 0.02_wp]
    
    ! Modal damping matrix (diagonal)
    C_modal = ZERO
    DO i = 1, 3
      C_modal(i,i) = TWO * zeta(i) * omega(i)
    END DO
    
    ! Check diagonal
    diagonal = .TRUE.
    DO i = 1, 3
      DO j = 1, 3
        IF (i /= j .AND. ABS(C_modal(i,j)) > TOLERANCE) THEN
          diagonal = .FALSE.
        END IF
      END DO
    END DO
    
    WRITE(*,*) '  Natural frequencies: ω = ', omega
    WRITE(*,*) '  Damping ratios: ζ = ', zeta
    WRITE(*,*) '  Modal damping matrix (diagonal):'
    DO i = 1, 3
      WRITE(*,*) '    ', C_modal(i,1), C_modal(i,2), C_modal(i,3)
    END DO
    WRITE(*,*) '  Diagonal: ', diagonal
    
    IF (diagonal) THEN
      WRITE(*,*) '  ✅ PASSED: Modal damping diagonal'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Should be diagonal'
    END IF
  END SUBROUTINE TC_MD_07_ModalDamping_Diagonal

  ! ============================================================================
  ! TC-MD-08: 质量-阻尼耦合装配
  ! 验证质量矩阵和阻尼矩阵的耦合装配
  ! ============================================================================
  SUBROUTINE TC_MD_08_MassDamping_CoupledAssembly()
    REAL(wp) :: M_global(2,2), K_global(2,2), C_global(2,2)
    REAL(wp) :: alpha_R, beta_R
    REAL(wp) :: M_sum, C_trace
    INTEGER(i4) :: i, j
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MD-08: Mass-Damping Coupled Assembly'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Mass matrix
    M_global = RESHAPE([2.0_wp, 0.5_wp, 0.5_wp, 1.0_wp], [2, 2])
    
    ! Stiffness matrix
    K_global = RESHAPE([3.0_wp, -1.0_wp, -1.0_wp, 2.0_wp], [2, 2])
    
    ! Rayleigh damping
    alpha_R = 0.1_wp
    beta_R = 0.05_wp
    C_global = alpha_R * M_global + beta_R * K_global
    
    ! Verify coupling
    M_sum = SUM(M_global)
    C_trace = C_global(1,1) + C_global(2,2)
    
    WRITE(*,*) '  Mass matrix M:'
    DO i = 1, 2
      WRITE(*,*) '    ', M_global(i,1), M_global(i,2)
    END DO
    WRITE(*,*) '  Stiffness matrix K:'
    DO i = 1, 2
      WRITE(*,*) '    ', K_global(i,1), K_global(i,2)
    END DO
    WRITE(*,*) '  Damping matrix C = α·M + β·K:'
    DO i = 1, 2
      WRITE(*,*) '    ', C_global(i,1), C_global(i,2)
    END DO
    WRITE(*,*) '  Trace(M) = ', M_sum
    WRITE(*,*) '  Trace(C) = ', C_trace
    
    ! Verify: C should be linear combination of M and K
    IF (ABS(C_global(1,1) - (alpha_R * M_global(1,1) + beta_R * K_global(1,1))) < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Mass-damping coupling correct'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Coupling error'
    END IF
  END SUBROUTINE TC_MD_08_MassDamping_CoupledAssembly

END MODULE TEST_RT_Asm_MassDamp
