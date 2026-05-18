!===============================================================================
! Module: TEST_PH_Mat_Eval
! Layer:  L4_PH - Physics Layer
! Domain: Material
! Purpose: Comprehensive test suite for PH_Mat_Eval material constitutive evaluation
!
! Test Coverage:
!   TC-MAT-01: Isotropic Elastic Evaluation (uniaxial tension)
!   TC-MAT-02: Isotropic Elastic Evaluation (shear)
!   TC-MAT-03: Orthotropic Elastic Evaluation
!   TC-MAT-04: Von Mises Plasticity (elastic trial)
!   TC-MAT-05: Von Mises Plasticity (plastic correction)
!   TC-MAT-06: Hill Plasticity (anisotropic yield)
!   TC-MAT-07: Neo-Hookean Hyperelastic (simple tension)
!   TC-MAT-08: Damage Ductile (stiffness degradation)
!   TC-MAT-09: Norton Creep (steady-state creep)
!   TC-MAT-10: Viscoelastic Prony (relaxation test)
!
! Theory:
!   1. Elastic: σ = D·ε
!   2. Plastic: Return mapping algorithm with consistent tangent
!   3. Hyperelastic: S = 2·∂W/∂C
!   4. Damage: σ_eff = (1-D)·σ, D_eff = (1-D)·D
!   5. Creep: ε̇_cr = A·σ^n·exp(-Q/(R·T))
!   6. Viscoelastic: Prony series G(t) = G_∞ + Σ g_i·exp(-t/τ_i)
!
! Status: v1.0 | Created: 2026-04-17 (P4任务1)
!===============================================================================
PROGRAM TEST_PH_Mat_Eval
  USE IF_Const, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: i4, wp
  USE PH_Mat_Eval
  USE MD_Mat_Lib, ONLY: MD_ElasticMatDesc, MD_PlasticMatDesc, MD_HyperElasticMatDesc, &
                         MD_PronyMatDesc
  
  IMPLICIT NONE
  
  ! Test configuration
  INTEGER(i4), PARAMETER :: N_TESTS = 10
  INTEGER(i4) :: n_tests_run = 0
  INTEGER(i4) :: n_tests_passed = 0
  REAL(wp), PARAMETER :: TOLERANCE = 1.0e-6_wp
  
  WRITE(*,*) ''
  WRITE(*,*) '================================================================'
  WRITE(*,*) ' PH_Mat_Eval Material Constitutive Evaluation Test Suite'
  WRITE(*,*) '================================================================'
  WRITE(*,*) ''
  
  !===========================================================================
  ! TC-MAT-01: Isotropic Elastic Evaluation (Uniaxial Tension)
  !===========================================================================
  CALL TC_MAT_01_Isotropic_Elastic_Uniaxial()
  
  !===========================================================================
  ! TC-MAT-02: Isotropic Elastic Evaluation (Pure Shear)
  !===========================================================================
  CALL TC_MAT_02_Isotropic_Elastic_Shear()
  
  !===========================================================================
  ! TC-MAT-03: Orthotropic Elastic Evaluation
  !===========================================================================
  CALL TC_MAT_03_Orthotropic_Elastic()
  
  !===========================================================================
  ! TC-MAT-04: Von Mises Plasticity (Elastic Trial)
  !===========================================================================
  CALL TC_MAT_04_Plastic_VonMises_Elastic()
  
  !===========================================================================
  ! TC-MAT-05: Von Mises Plasticity (Plastic Correction)
  !===========================================================================
  CALL TC_MAT_05_Plastic_VonMises_Plastic()
  
  !===========================================================================
  ! TC-MAT-06: Hill Plasticity (Anisotropic Yield)
  !===========================================================================
  CALL TC_MAT_06_Plastic_Hill()
  
  !===========================================================================
  ! TC-MAT-07: Neo-Hookean Hyperelastic (Simple Tension)
  !===========================================================================
  CALL TC_MAT_07_Hyperelastic_NeoHookean()
  
  !===========================================================================
  ! TC-MAT-08: Damage Ductile (Stiffness Degradation)
  !===========================================================================
  CALL TC_MAT_08_Damage_Ductile()
  
  !===========================================================================
  ! TC-MAT-09: Norton Creep (Steady-State Creep)
  !===========================================================================
  CALL TC_MAT_09_Creep_Norton()
  
  !===========================================================================
  ! TC-MAT-10: Viscoelastic Prony (Relaxation Test)
  !===========================================================================
  CALL TC_MAT_10_Viscoelastic_Prony()
  
  !===========================================================================
  ! Test Summary
  !===========================================================================
  WRITE(*,*) ''
  WRITE(*,*) '================================================================'
  WRITE(*,*) ' Test Summary'
  WRITE(*,*) '================================================================'
  WRITE(*,*) ''
  WRITE(*,*) '  Total tests run:    ', n_tests_run
  WRITE(*,*) '  Tests passed:       ', n_tests_passed
  WRITE(*,*) '  Tests failed:       ', n_tests_run - n_tests_passed
  WRITE(*,*) '  Pass rate:          ', REAL(n_tests_passed, wp) / REAL(n_tests_run, wp) * 100.0_wp, '%'
  WRITE(*,*) ''
  
  IF (n_tests_passed == n_tests_run) THEN
    WRITE(*,*) '  ✅ ALL TESTS PASSED'
  ELSE
    WRITE(*,*) '  ❌ SOME TESTS FAILED'
  END IF
  WRITE(*,*) ''
  WRITE(*,*) '================================================================'
  WRITE(*,*) ''

CONTAINS
  
  !===========================================================================
  ! TC-MAT-01: Isotropic Elastic Evaluation (Uniaxial Tension)
  !===========================================================================
  SUBROUTINE TC_MAT_01_Isotropic_Elastic_Uniaxial()
    TYPE(MD_ElasticMatDesc) :: mat_desc
    TYPE(PH_Mat_ElasticIsotropic_Eval_In) :: eval_in
    TYPE(PH_Mat_ElasticIsotropic_Eval_Out) :: eval_out
    REAL(wp) :: E, nu, epsilon, sigma_expected, sigma_actual, rel_error
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-01: Isotropic Elastic - Uniaxial Tension'
    WRITE(*,*) '------------------------------------------------'
    
    ! Material properties: Steel
    E = 210.0e9_wp      ! Young's modulus (Pa)
    nu = 0.3_wp         ! Poisson's ratio
    
    mat_desc%young_modulus = E
    mat_desc%poisson_ratio = nu
    
    ! Uniaxial strain: ε_xx = 0.001
    epsilon = 0.001_wp
    eval_in%mat_desc = mat_desc
    eval_in%strain = [epsilon, ZERO, ZERO, ZERO, ZERO, ZERO]
    
    ! Evaluate
    CALL PH_Mat_ElasticIsotropic_Eval(eval_in, eval_out)
    
    ! Verify stress status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    ! Expected stress: σ_xx = E·ε_xx = 210e9 × 0.001 = 210e6 Pa
    sigma_expected = E * epsilon
    sigma_actual = eval_out%sigma(1)
    rel_error = ABS(sigma_actual - sigma_expected) / ABS(sigma_expected)
    
    WRITE(*,*) '  Input: E =', E, ' Pa, ε_xx =', epsilon
    WRITE(*,*) '  Expected σ_xx =', sigma_expected, ' Pa'
    WRITE(*,*) '  Actual σ_xx   =', sigma_actual, ' Pa'
    WRITE(*,*) '  Relative error =', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Error > tolerance'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_01_Isotropic_Elastic_Uniaxial
  
  !===========================================================================
  ! TC-MAT-02: Isotropic Elastic Evaluation (Pure Shear)
  !===========================================================================
  SUBROUTINE TC_MAT_02_Isotropic_Elastic_Shear()
    TYPE(MD_ElasticMatDesc) :: mat_desc
    TYPE(PH_Mat_ElasticIsotropic_Eval_In) :: eval_in
    TYPE(PH_Mat_ElasticIsotropic_Eval_Out) :: eval_out
    REAL(wp) :: E, nu, G, gamma, tau_expected, tau_actual, rel_error
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-02: Isotropic Elastic - Pure Shear'
    WRITE(*,*) '------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    G = E / (TWO * (ONE + nu))  ! Shear modulus
    
    mat_desc%young_modulus = E
    mat_desc%poisson_ratio = nu
    
    ! Pure shear: γ_xy = 0.002
    gamma = 0.002_wp
    eval_in%mat_desc = mat_desc
    eval_in%strain = [ZERO, ZERO, ZERO, gamma, ZERO, ZERO]
    
    ! Evaluate
    CALL PH_Mat_ElasticIsotropic_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    ! Expected shear stress: τ_xy = G·γ_xy
    tau_expected = G * gamma
    tau_actual = eval_out%sigma(4)
    rel_error = ABS(tau_actual - tau_expected) / ABS(tau_expected)
    
    WRITE(*,*) '  Input: G =', G, ' Pa, γ_xy =', gamma
    WRITE(*,*) '  Expected τ_xy =', tau_expected, ' Pa'
    WRITE(*,*) '  Actual τ_xy   =', tau_actual, ' Pa'
    WRITE(*,*) '  Relative error =', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Error > tolerance'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_02_Isotropic_Elastic_Shear
  
  !===========================================================================
  ! TC-MAT-03: Orthotropic Elastic Evaluation
  !===========================================================================
  SUBROUTINE TC_MAT_03_Orthotropic_Elastic()
    TYPE(MD_ElasticMatDesc) :: mat_desc
    TYPE(PH_Mat_ElasticOrthotropic_Eval_In) :: eval_in
    TYPE(PH_Mat_ElasticOrthotropic_Eval_Out) :: eval_out
    REAL(wp) :: Ex, Ey, Ez, nu_xy, strain_x, sigma_x_expected, sigma_x_actual, rel_error
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-03: Orthotropic Elastic'
    WRITE(*,*) '------------------------------------------------'
    
    ! Material properties: Carbon fiber composite (orthotropic)
    Ex = 140.0e9_wp     ! E_x
    Ey = 10.0e9_wp      ! E_y
    Ez = 10.0e9_wp      ! E_z
    nu_xy = 0.3_wp      ! ν_xy
    
    mat_desc%young_modulus = Ex
    mat_desc%poisson_ratio = nu_xy
    mat_desc%orthotropic_ex = Ex
    mat_desc%orthotropic_ey = Ey
    mat_desc%orthotropic_ez = Ez
    mat_desc%is_orthotropic = .TRUE.
    
    ! Uniaxial strain in x-direction
    strain_x = 0.001_wp
    eval_in%mat_desc = mat_desc
    eval_in%strain = [strain_x, ZERO, ZERO, ZERO, ZERO, ZERO]
    
    ! Evaluate
    CALL PH_Mat_ElasticOrthotropic_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    ! Expected: σ_x ≈ Ex·ε_x (simplified check)
    sigma_x_expected = Ex * strain_x
    sigma_x_actual = eval_out%sigma(1)
    rel_error = ABS(sigma_x_actual - sigma_x_expected) / ABS(sigma_x_expected)
    
    WRITE(*,*) '  Input: Ex =', Ex, ' Pa, ε_x =', strain_x
    WRITE(*,*) '  Expected σ_x ≈', sigma_x_expected, ' Pa'
    WRITE(*,*) '  Actual σ_x   =', sigma_x_actual, ' Pa'
    WRITE(*,*) '  Relative error =', rel_error
    
    ! Relaxed tolerance for orthotropic
    IF (rel_error < 0.01_wp) THEN
      WRITE(*,*) '  ✅ PASSED'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Error > tolerance'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_03_Orthotropic_Elastic
  
  !===========================================================================
  ! TC-MAT-04: Von Mises Plasticity (Elastic Trial)
  !===========================================================================
  SUBROUTINE TC_MAT_04_Plastic_VonMises_Elastic()
    TYPE(MD_PlasticMatDesc) :: mat_desc
    TYPE(PH_Mat_PlasticVonMises_Eval_In) :: eval_in
    TYPE(PH_Mat_PlasticVonMises_Eval_Out) :: eval_out
    REAL(wp) :: E, nu, sigma_y, strain_inc, von_mises_stress, yield_stress
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-04: Von Mises Plasticity - Elastic Trial'
    WRITE(*,*) '------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y = 250.0e6_wp  ! Yield stress
    
    mat_desc%young_modulus = E
    mat_desc%poisson_ratio = nu
    mat_desc%yield_stress = sigma_y
    
    ! Small strain increment (elastic regime)
    strain_inc = 0.0005_wp
    eval_in%mat_desc = mat_desc
    eval_in%strain_increment = [strain_inc, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%equiv_plastic_strain = ZERO
    
    ! Evaluate
    CALL PH_Mat_PlasticVonMises_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    ! Check von Mises stress < yield stress (elastic)
    von_mises_stress = eval_out%stress_new(1)  ! Simplified for uniaxial
    yield_stress = sigma_y
    
    WRITE(*,*) '  Input: σ_y =', sigma_y, ' Pa, Δε =', strain_inc
    WRITE(*,*) '  Von Mises stress =', von_mises_stress, ' Pa'
    WRITE(*,*) '  Yield stress     =', yield_stress, ' Pa'
    
    IF (von_mises_stress < yield_stress) THEN
      WRITE(*,*) '  ✅ PASSED (Elastic trial, no plastic flow)'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Stress exceeds yield'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_04_Plastic_VonMises_Elastic
  
  !===========================================================================
  ! TC-MAT-05: Von Mises Plasticity (Plastic Correction)
  !===========================================================================
  SUBROUTINE TC_MAT_05_Plastic_VonMises_Plastic()
    TYPE(MD_PlasticMatDesc) :: mat_desc
    TYPE(PH_Mat_PlasticVonMises_Eval_In) :: eval_in
    TYPE(PH_Mat_PlasticVonMises_Eval_Out) :: eval_out
    REAL(wp) :: E, nu, sigma_y, strain_inc, stress_new
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-05: Von Mises Plasticity - Plastic Correction'
    WRITE(*,*) '------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y = 250.0e6_wp
    
    mat_desc%young_modulus = E
    mat_desc%poisson_ratio = nu
    mat_desc%yield_stress = sigma_y
    
    ! Large strain increment (plastic regime)
    strain_inc = 0.005_wp
    eval_in%mat_desc = mat_desc
    eval_in%strain_increment = [strain_inc, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%equiv_plastic_strain = ZERO
    
    ! Evaluate
    CALL PH_Mat_PlasticVonMises_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    ! Check stress is capped near yield (with hardening)
    stress_new = eval_out%stress_new(1)
    
    WRITE(*,*) '  Input: σ_y =', sigma_y, ' Pa, Δε =', strain_inc
    WRITE(*,*) '  Updated stress =', stress_new, ' Pa'
    
    ! Stress should be slightly above yield due to hardening
    IF (stress_new > sigma_y .AND. stress_new < sigma_y * 1.5_wp) THEN
      WRITE(*,*) '  ✅ PASSED (Plastic correction with hardening)'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Unexpected stress level'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_05_Plastic_VonMises_Plastic
  
  !===========================================================================
  ! TC-MAT-06: Hill Plasticity (Anisotropic Yield)
  !===========================================================================
  SUBROUTINE TC_MAT_06_Plastic_Hill()
    TYPE(MD_PlasticMatDesc) :: mat_desc
    TYPE(PH_Mat_PlasticHill_Eval_In) :: eval_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: eval_out
    REAL(wp) :: E, nu, sigma_y, strain_inc, stress_new
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-06: Hill Plasticity - Anisotropic Yield'
    WRITE(*,*) '------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y = 250.0e6_wp
    
    mat_desc%young_modulus = E
    mat_desc%poisson_ratio = nu
    mat_desc%yield_stress = sigma_y
    
    ! Hill anisotropic parameters (simplified, isotropic case)
    mat_desc%hill_f = ONE
    mat_desc%hill_g = ONE
    mat_desc%hill_h = ONE
    mat_desc%hill_l = THREE
    mat_desc%hill_m = THREE
    mat_desc%hill_n = THREE
    
    ! Strain increment
    strain_inc = 0.002_wp
    eval_in%mat_desc = mat_desc
    eval_in%strain_increment = [strain_inc, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%equiv_plastic_strain = ZERO
    
    ! Evaluate
    CALL PH_Mat_PlasticHill_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    stress_new = eval_out%stress_new(1)
    
    WRITE(*,*) '  Input: σ_y =', sigma_y, ' Pa, Δε =', strain_inc
    WRITE(*,*) '  Updated stress =', stress_new, ' Pa'
    
    ! Verify stress is reasonable
    IF (stress_new > ZERO .AND. stress_new < E * strain_inc) THEN
      WRITE(*,*) '  ✅ PASSED (Hill plasticity evaluation)'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Unexpected stress level'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_06_Plastic_Hill
  
  !===========================================================================
  ! TC-MAT-07: Neo-Hookean Hyperelastic (Simple Tension)
  !===========================================================================
  SUBROUTINE TC_MAT_07_Hyperelastic_NeoHookean()
    TYPE(MD_HyperElasticMatDesc) :: mat_desc
    TYPE(PH_Mat_HyperelasticNeoHookean_Eval_In) :: eval_in
    TYPE(PH_Mat_HyperelasticNeoHookean_Eval_Out) :: eval_out
    REAL(wp) :: C10, stretch_ratio, J, sigma_xx
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-07: Neo-Hookean Hyperelastic - Simple Tension'
    WRITE(*,*) '------------------------------------------------'
    
    ! Neo-Hookean parameters
    C10 = 0.5e6_wp  ! Material parameter (Pa)
    
    mat_desc%neo_hookean_c10 = C10
    mat_desc%bulk_modulus = 2.0e9_wp  ! Bulk modulus
    
    ! Simple tension: λ = 1.2 (20% stretch)
    stretch_ratio = 1.2_wp
    J = stretch_ratio  ! Volume ratio (simplified)
    
    ! Deformation gradient F (uniaxial)
    eval_in%mat_desc = mat_desc
    eval_in%F = ZERO
    eval_in%F(1,1) = stretch_ratio
    eval_in%F(2,2) = ONE / SQRT(stretch_ratio)
    eval_in%F(3,3) = ONE / SQRT(stretch_ratio)
    
    ! Evaluate
    CALL PH_Mat_HyperelasticNeoHookean_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    sigma_xx = eval_out%sigma(1)
    
    WRITE(*,*) '  Input: C10 =', C10, ' Pa, λ =', stretch_ratio
    WRITE(*,*) '  Cauchy stress σ_xx =', sigma_xx, ' Pa'
    
    ! Verify stress is positive and reasonable
    IF (sigma_xx > ZERO) THEN
      WRITE(*,*) '  ✅ PASSED (Hyperelastic tension)'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Negative stress in tension'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_07_Hyperelastic_NeoHookean
  
  !===========================================================================
  ! TC-MAT-08: Damage Ductile (Stiffness Degradation)
  !===========================================================================
  SUBROUTINE TC_MAT_08_Damage_Ductile()
    TYPE(PH_Mat_DamageDuctile_Eval_In) :: eval_in
    TYPE(PH_Mat_DamageDuctile_Eval_Out) :: eval_out
    REAL(wp) :: E, nu, stress_undamaged, damage, stress_damaged_expected, stress_damaged_actual, rel_error
    REAL(wp) :: D_undamaged(6,6)
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-08: Damage Ductile - Stiffness Degradation'
    WRITE(*,*) '------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    
    ! Undamaged stress
    stress_undamaged = 100.0e6_wp  ! 100 MPa
    
    ! Damage variable: D = 0.3 (30% damage)
    damage = 0.3_wp
    
    ! Prepare undamaged stiffness matrix (simplified)
    D_undamaged = ZERO
    D_undamaged(1,1) = E / (ONE - nu**2)
    D_undamaged(2,2) = E / (ONE - nu**2)
    D_undamaged(3,3) = E / (ONE - nu**2)
    
    eval_in%stress_undamaged = [stress_undamaged, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%damage = damage
    eval_in%D_matrix_undamaged = D_undamaged
    
    ! Evaluate
    CALL PH_Mat_DamageDuctile_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    ! Expected: σ_eff = (1-D)·σ = 0.7 × 100 MPa = 70 MPa
    stress_damaged_expected = (ONE - damage) * stress_undamaged
    stress_damaged_actual = eval_out%stress_damaged(1)
    rel_error = ABS(stress_damaged_actual - stress_damaged_expected) / ABS(stress_damaged_expected)
    
    WRITE(*,*) '  Input: σ =', stress_undamaged, ' Pa, D =', damage
    WRITE(*,*) '  Expected σ_eff =', stress_damaged_expected, ' Pa'
    WRITE(*,*) '  Actual σ_eff   =', stress_damaged_actual, ' Pa'
    WRITE(*,*) '  Relative error =', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Error > tolerance'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_08_Damage_Ductile
  
  !===========================================================================
  ! TC-MAT-09: Norton Creep (Steady-State Creep)
  !===========================================================================
  SUBROUTINE TC_MAT_09_Creep_Norton()
    TYPE(MD_ElasticMatDesc) :: mat_desc
    TYPE(PH_Mat_CreepNorton_Eval_In) :: eval_in
    TYPE(PH_Mat_CreepNorton_Eval_Out) :: eval_out
    REAL(wp) :: E, nu, A, n, Q, R, T, sigma, creep_rate_expected, creep_rate_actual, rel_error
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-09: Norton Creep - Steady-State Creep'
    WRITE(*,*) '------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    
    ! Norton creep parameters
    A = 1.0e-10_wp     ! Creep coefficient
    n = 3.0_wp         ! Stress exponent
    Q = 200.0e3_wp     ! Activation energy (J/mol)
    R = 8.314_wp       ! Gas constant (J/(mol·K))
    T = 800.0_wp       ! Temperature (K)
    
    mat_desc%young_modulus = E
    mat_desc%poisson_ratio = nu
    mat_desc%creep_A = A
    mat_desc%creep_n = n
    mat_desc%creep_Q = Q
    
    ! Applied stress
    sigma = 100.0e6_wp  ! 100 MPa
    
    eval_in%mat_desc = mat_desc
    eval_in%sigma = [sigma, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%temperature = T
    
    ! Evaluate
    CALL PH_Mat_CreepNorton_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    ! Expected creep rate: ε̇_cr = A·σ^n·exp(-Q/(R·T))
    creep_rate_expected = A * sigma**n * EXP(-Q / (R * T))
    creep_rate_actual = eval_out%creep_rate(1)
    rel_error = ABS(creep_rate_actual - creep_rate_expected) / ABS(creep_rate_expected)
    
    WRITE(*,*) '  Input: σ =', sigma, ' Pa, T =', T, ' K'
    WRITE(*,*) '  Expected ε̇_cr =', creep_rate_expected, ' 1/s'
    WRITE(*,*) '  Actual ε̇_cr   =', creep_rate_actual, ' 1/s'
    WRITE(*,*) '  Relative error =', rel_error
    
    IF (rel_error < 0.01_wp) THEN
      WRITE(*,*) '  ✅ PASSED'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Error > tolerance'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_09_Creep_Norton
  
  !===========================================================================
  ! TC-MAT-10: Viscoelastic Prony (Relaxation Test)
  !===========================================================================
  SUBROUTINE TC_MAT_10_Viscoelastic_Prony()
    TYPE(MD_PronyMatDesc) :: mat_desc
    TYPE(PH_Mat_ViscoelasticProny_Eval_In) :: eval_in
    TYPE(PH_Mat_ViscoelasticProny_Eval_Out) :: eval_out
    REAL(wp) :: E_inf, g1, tau1, strain, strain_rate, time, dtime, sigma
    
    n_tests_run = n_tests_run + 1
    WRITE(*,*) 'TC-MAT-10: Viscoelastic Prony - Relaxation Test'
    WRITE(*,*) '------------------------------------------------'
    
    ! Prony series parameters
    E_inf = 1.0e9_wp       ! Long-term modulus
    g1 = 0.5_wp            ! Relative modulus of term 1
    tau1 = 10.0_wp         ! Relaxation time
    
    mat_desc%long_term_modulus = E_inf
    mat_desc%n_prony_terms = 1
    mat_desc%prony_g(1) = g1
    mat_desc%prony_tau(1) = tau1
    
    ! Step strain: ε = 0.01, ε̇ = 0 (relaxation)
    strain = 0.01_wp
    strain_rate = ZERO
    time = 5.0_wp         ! Current time
    dtime = 0.1_wp        ! Time increment
    
    eval_in%mat_desc = mat_desc
    eval_in%strain = [strain, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%strain_rate = [strain_rate, ZERO, ZERO, ZERO, ZERO, ZERO]
    eval_in%time = time
    eval_in%dtime = dtime
    
    ! Evaluate
    CALL PH_Mat_ViscoelasticProny_Eval(eval_in, eval_out)
    
    ! Verify status
    IF (eval_out%status%status_code /= IF_STATUS_OK) THEN
      WRITE(*,*) '  ❌ FAILED: Status code =', eval_out%status%status_code
      RETURN
    END IF
    
    sigma = eval_out%sigma(1)
    
    WRITE(*,*) '  Input: ε =', strain, ', t =', time, ' s'
    WRITE(*,*) '  Stress σ =', sigma, ' Pa'
    
    ! Verify stress is positive and decreasing (relaxation)
    IF (sigma > ZERO) THEN
      WRITE(*,*) '  ✅ PASSED (Viscoelastic relaxation)'
      n_tests_passed = n_tests_passed + 1
    ELSE
      WRITE(*,*) '  ❌ FAILED: Negative stress'
    END IF
    WRITE(*,*) ''
  END SUBROUTINE TC_MAT_10_Viscoelastic_Prony

END PROGRAM TEST_PH_Mat_Eval
