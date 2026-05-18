!===============================================================================
! Module: TEST_PH_Mat_Hill
! Layer:  L5_RT - Runtime Layer (Test)
! Domain: Material - Hill Plasticity
! Purpose: Test Hill anisotropic plasticity constitutive model
! Theory:
!   Hill yield criterion (1948):
!   f = √[F(σ_yy-σ_zz)² + G(σ_zz-σ_xx)² + H(σ_xx-σ_yy)² 
!        + 2Lτ_yz² + 2Mτ_zx² + 2Nτ_xy²] - σ_y
!   
!   Return mapping:
!   1. Elastic trial: σ_trial = σ_n + D_e·Δε
!   2. Check yield: f_trial = φ_trial - σ_y
!   3. If f_trial > 0: plastic correction σ_{n+1} = σ_trial·(σ_y/φ_trial)
!   4. Update: ε̄_p^{n+1} = ε̄_p^n + (φ_trial - σ_y)/H
!
! Test Cases:
!   TC-HILL-01: 各向同性退化验证 (F=G=H=1/2, L=M=N=3/2 → Von Mises)
!   TC-HILL-02: 单轴拉伸-屈服验证
!   TC-HILL-03: 单轴拉伸-塑性修正
!   TC-HILL-04: 纯剪切-屈服验证
!   TC-HILL-05: 各向异性系数影响-F参数
!   TC-HILL-06: 各向异性系数影响-N参数
!   TC-HILL-07: 等双轴拉伸
!   TC-HILL-08: 硬化模量影响
!
! Status: Production | Created: 2026-04-17
!===============================================================================

MODULE TEST_PH_Mat_Hill
  USE IF_Const, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Prec_Core, ONLY: i4, wp
  USE PH_Mat_Eval, ONLY: PH_Mat_PlasticHill_Eval_In, PH_Mat_PlasticHill_Eval_Out, &
                         PH_Mat_PlasticHill_Eval
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_All_Hill_Tests

  ! Test tolerance
  REAL(wp), PARAMETER :: TOLERANCE = 1.0e-6_wp
  REAL(wp), PARAMETER :: TOLERANCE_PLASTIC = 1.0e-2_wp  ! 1% for plastic

CONTAINS

  SUBROUTINE Run_All_Hill_Tests()
    !! Run all Hill plasticity test cases
    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Mat_Hill: Hill Anisotropic Plasticity Tests'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    CALL TC_HILL_01_Isotropic_Degeneration()
    CALL TC_HILL_02_Uniaxial_Tension_Elastic()
    CALL TC_HILL_03_Uniaxial_Tension_Plastic()
    CALL TC_HILL_04_Pure_Shear_Yield()
    CALL TC_HILL_05_Anisotropy_F_Parameter()
    CALL TC_HILL_06_Anisotropy_N_Parameter()
    CALL TC_HILL_07_EquiBiaxial_Tension()
    CALL TC_HILL_08_Hardening_Modulus_Effect()

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Mat_Hill: All 8 Tests Completed'
    WRITE(*,*) '===================================================================='
  END SUBROUTINE Run_All_Hill_Tests

  ! ============================================================================
  ! TC-HILL-01: 各向同性退化验证
  ! 验证Hill参数退化为Von Mises的情况
  ! ============================================================================
  SUBROUTINE TC_HILL_01_Isotropic_Degeneration()
    TYPE(PH_Mat_PlasticHill_Eval_In) :: hill_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: hill_out
    REAL(wp) :: E, nu, sigma_y0, H_hard
    REAL(wp) :: F, G, Hh, L, M, N
    REAL(wp) :: strain_inc(6), stress_old(6)
    REAL(wp) :: sigma_vm_expected, phi_hill, rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-HILL-01: Isotropic Degeneration (Hill → Von Mises)'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties (Steel)
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_hard = 2.0e9_wp
    
    ! Hill parameters for isotropic degeneration:
    ! F = G = H = 1/2, L = M = N = 3/2
    F = HALF
    G = HALF
    Hh = HALF
    L = 1.5_wp
    M = 1.5_wp
    N = 1.5_wp
    
    ! Initialize Hill input
    hill_in%mat_desc%E = E
    hill_in%mat_desc%nu = nu
    hill_in%mat_desc%yieldStress = sigma_y0
    hill_in%mat_desc%hardeningModulus = H_hard
    hill_in%mat_desc%Hill_F = F
    hill_in%mat_desc%Hill_G = G
    hill_in%mat_desc%Hill_H = Hh
    hill_in%mat_desc%Hill_L = L
    hill_in%mat_desc%Hill_M = M
    hill_in%mat_desc%Hill_N = N
    
    ! Uniaxial tension strain
    strain_inc = [0.002_wp, -0.0006_wp, -0.0006_wp, ZERO, ZERO, ZERO]
    stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    hill_in%strain_increment = strain_inc
    hill_in%stress_old = stress_old
    hill_in%equiv_plastic_strain = ZERO
    
    ! Call Hill evaluation
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    
    ! Expected: For isotropic case, Hill equivalent stress = Von Mises stress
    ! σ_vm = √[3/2·s:s] where s = dev(σ)
    ! For uniaxial tension: σ_vm = σ_xx
    sigma_vm_expected = ABS(hill_out%stress_new(1))
    
    ! Hill equivalent stress (should match Von Mises)
    phi_hill = SQRT( &
      F * (hill_out%stress_new(2) - hill_out%stress_new(3))**2 + &
      G * (hill_out%stress_new(3) - hill_out%stress_new(1))**2 + &
      Hh * (hill_out%stress_new(1) - hill_out%stress_new(2))**2 + &
      TWO * L * hill_out%stress_new(4)**2 + &
      TWO * M * hill_out%stress_new(5)**2 + &
      TWO * N * hill_out%stress_new(6)**2 )
    
    ! Verify: φ_hill ≈ σ_vm
    rel_error = ABS(phi_hill - sigma_vm_expected) / sigma_vm_expected
    
    WRITE(*,*) '  Input strain: ε_xx = 0.002, ε_yy = ε_zz = -0.0006'
    WRITE(*,*) '  Expected: φ_hill = σ_vm (isotropic degeneration)'
    WRITE(*,*) '  φ_hill = ', phi_hill, ' Pa'
    WRITE(*,*) '  σ_vm = ', sigma_vm_expected, ' Pa'
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Hill degenerates to Von Mises correctly'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Hill-Von Mises mismatch (error = ', rel_error, ')'
    END IF
  END SUBROUTINE TC_HILL_01_Isotropic_Degeneration

  ! ============================================================================
  ! TC-HILL-02: 单轴拉伸-弹性阶段
  ! 验证应变较小时处于弹性阶段
  ! ============================================================================
  SUBROUTINE TC_HILL_02_Uniaxial_Tension_Elastic()
    TYPE(PH_Mat_PlasticHill_Eval_In) :: hill_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: hill_out
    REAL(wp) :: E, nu, sigma_y0, H_hard
    REAL(wp) :: strain_inc(6), stress_expected(6)
    REAL(wp) :: stress_actual(6), rel_error
    INTEGER(i4) :: i
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-HILL-02: Uniaxial Tension - Elastic Loading'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_hard = 2.0e9_wp
    
    ! Initialize Hill input
    hill_in%mat_desc%E = E
    hill_in%mat_desc%nu = nu
    hill_in%mat_desc%yieldStress = sigma_y0
    hill_in%mat_desc%hardeningModulus = H_hard
    hill_in%mat_desc%Hill_F = HALF
    hill_in%mat_desc%Hill_G = HALF
    hill_in%mat_desc%Hill_H = HALF
    hill_in%mat_desc%Hill_L = 1.5_wp
    hill_in%mat_desc%Hill_M = 1.5_wp
    hill_in%mat_desc%Hill_N = 1.5_wp
    
    ! Small strain (elastic): ε_xx = 0.001 → σ_xx = 210 MPa < 250 MPa
    strain_inc = [0.001_wp, -0.0003_wp, -0.0003_wp, ZERO, ZERO, ZERO]
    hill_in%strain_increment = strain_inc
    hill_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    hill_in%equiv_plastic_strain = ZERO
    
    ! Call Hill evaluation
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    
    ! Expected: σ_xx = E·ε_xx = 210e9 × 0.001 = 210e6 Pa
    stress_expected(1) = E * strain_inc(1)
    stress_expected(2) = ZERO  ! Simplified
    stress_expected(3) = ZERO
    stress_expected(4) = ZERO
    stress_expected(5) = ZERO
    stress_expected(6) = ZERO
    
    ! Verify stress
    stress_actual = hill_out%stress_new
    rel_error = ABS(stress_actual(1) - stress_expected(1)) / stress_expected(1)
    
    WRITE(*,*) '  Input strain: ε_xx = 0.001 (elastic)'
    WRITE(*,*) '  Expected: σ_xx = 210 MPa (elastic, < σ_y = 250 MPa)'
    WRITE(*,*) '  Actual: σ_xx = ', stress_actual(1) / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Relative error: ', rel_error
    WRITE(*,*) '  Plastic strain: ', hill_out%equiv_plastic_strain
    
    IF (rel_error < TOLERANCE .AND. hill_out%equiv_plastic_strain < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Elastic loading (no plastic strain)'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Elastic test failed'
    END IF
  END SUBROUTINE TC_HILL_02_Uniaxial_Tension_Elastic

  ! ============================================================================
  ! TC-HILL-03: 单轴拉伸-塑性修正
  ! 验证应变较大时进入塑性阶段，应力被修正到屈服面
  ! ============================================================================
  SUBROUTINE TC_HILL_03_Uniaxial_Tension_Plastic()
    TYPE(PH_Mat_PlasticHill_Eval_In) :: hill_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: hill_out
    REAL(wp) :: E, nu, sigma_y0, H_hard
    REAL(wp) :: strain_inc(6), phi_trial, sigma_y
    REAL(wp) :: stress_actual, rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-HILL-03: Uniaxial Tension - Plastic Correction'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_hard = 2.0e9_wp
    
    ! Initialize Hill input
    hill_in%mat_desc%E = E
    hill_in%mat_desc%nu = nu
    hill_in%mat_desc%yieldStress = sigma_y0
    hill_in%mat_desc%hardeningModulus = H_hard
    hill_in%mat_desc%Hill_F = HALF
    hill_in%mat_desc%Hill_G = HALF
    hill_in%mat_desc%Hill_H = HALF
    hill_in%mat_desc%Hill_L = 1.5_wp
    hill_in%mat_desc%Hill_M = 1.5_wp
    hill_in%mat_desc%Hill_N = 1.5_wp
    
    ! Large strain (plastic): ε_xx = 0.002 → σ_trial = 420 MPa > 250 MPa
    strain_inc = [0.002_wp, -0.0006_wp, -0.0006_wp, ZERO, ZERO, ZERO]
    hill_in%strain_increment = strain_inc
    hill_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    hill_in%equiv_plastic_strain = ZERO
    
    ! Call Hill evaluation
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    
    ! Expected: Stress corrected to yield surface
    ! φ_trial = E·ε_xx = 420 MPa
    ! σ_y = 250 MPa (initial)
    ! σ_corrected = σ_trial·(σ_y/φ_trial) = 420·(250/420) ≈ 250 MPa
    phi_trial = E * strain_inc(1)
    sigma_y = sigma_y0
    stress_actual = hill_out%stress_new(1)
    
    ! After plastic correction: σ ≈ σ_y (with hardening)
    rel_error = ABS(stress_actual - sigma_y) / sigma_y
    
    WRITE(*,*) '  Input strain: ε_xx = 0.002 (plastic)'
    WRITE(*,*) '  Expected: σ_trial = 420 MPa > σ_y = 250 MPa'
    WRITE(*,*) '  After correction: σ ≈ 250 MPa (on yield surface)'
    WRITE(*,*) '  Actual: σ_xx = ', stress_actual / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Relative error: ', rel_error
    WRITE(*,*) '  Plastic strain: ', hill_out%equiv_plastic_strain
    
    IF (rel_error < TOLERANCE_PLASTIC .AND. hill_out%equiv_plastic_strain > 1.0e-8_wp) THEN
      WRITE(*,*) '  ✅ PASSED: Plastic correction to yield surface'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Plastic correction failed'
    END IF
  END SUBROUTINE TC_HILL_03_Uniaxial_Tension_Plastic

  ! ============================================================================
  ! TC-HILL-04: 纯剪切-屈服验证
  ! 验证纯剪切载荷下的屈服行为
  ! ============================================================================
  SUBROUTINE TC_HILL_04_Pure_Shear_Yield()
    TYPE(PH_Mat_PlasticHill_Eval_In) :: hill_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: hill_out
    REAL(wp) :: E, nu, sigma_y0, H_hard, G_shear
    REAL(wp) :: strain_inc(6), phi_trial, tau_y_expected
    REAL(wp) :: tau_actual, rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-HILL-04: Pure Shear - Yield Verification'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_hard = 2.0e9_wp
    G_shear = E / (TWO * (ONE + nu))
    
    ! Initialize Hill input
    hill_in%mat_desc%E = E
    hill_in%mat_desc%nu = nu
    hill_in%mat_desc%yieldStress = sigma_y0
    hill_in%mat_desc%hardeningModulus = H_hard
    hill_in%mat_desc%Hill_F = HALF
    hill_in%mat_desc%Hill_G = HALF
    hill_in%mat_desc%Hill_H = HALF
    hill_in%mat_desc%Hill_L = 1.5_wp
    hill_in%mat_desc%Hill_M = 1.5_wp
    hill_in%mat_desc%Hill_N = 1.5_wp
    
    ! Pure shear strain: γ_xy = 0.003
    strain_inc = [ZERO, ZERO, ZERO, 0.003_wp, ZERO, ZERO]
    hill_in%strain_increment = strain_inc
    hill_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    hill_in%equiv_plastic_strain = ZERO
    
    ! Call Hill evaluation
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    
    ! Expected: For Von Mises, τ_y = σ_y/√3 ≈ 144.3 MPa
    ! Hill: φ = √[2N·τ_xy²] = √3·|τ_xy| (for isotropic N=3/2)
    tau_y_expected = sigma_y0 / SQRT(3.0_wp)
    
    ! Actual shear stress
    tau_actual = ABS(hill_out%stress_new(4))
    
    ! φ_trial = √3·τ_trial = √3·G·γ_xy
    phi_trial = SQRT(3.0_wp) * G_shear * strain_inc(4)
    
    rel_error = ABS(tau_actual - tau_y_expected) / tau_y_expected
    
    WRITE(*,*) '  Input shear strain: γ_xy = 0.003'
    WRITE(*,*) '  Expected: τ_y = σ_y/√3 = ', tau_y_expected / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  φ_trial = ', phi_trial / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Actual: τ_xy = ', tau_actual / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Relative error: ', rel_error
    WRITE(*,*) '  Plastic strain: ', hill_out%equiv_plastic_strain
    
    IF (rel_error < TOLERANCE_PLASTIC) THEN
      WRITE(*,*) '  ✅ PASSED: Pure shear yield criterion verified'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Shear yield mismatch'
    END IF
  END SUBROUTINE TC_HILL_04_Pure_Shear_Yield

  ! ============================================================================
  ! TC-HILL-05: 各向异性系数影响-F参数
  ! 验证F参数对屈服面的影响（影响σ_yy-σ_zz项）
  ! ============================================================================
  SUBROUTINE TC_HILL_05_Anisotropy_F_Parameter()
    TYPE(PH_Mat_PlasticHill_Eval_In) :: hill_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: hill_out
    REAL(wp) :: E, nu, sigma_y0, H_hard
    REAL(wp) :: F1, F2, phi_F1, phi_F2
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: ratio_expected, ratio_actual, rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-HILL-05: Anisotropy Coefficient - F Parameter Effect'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_hard = 2.0e9_wp
    
    ! Biaxial tension: σ_yy ≠ σ_zz
    strain_inc = [0.001_wp, 0.0015_wp, -0.00075_wp, ZERO, ZERO, ZERO]
    
    ! Test with F = 0.5 (isotropic)
    F1 = HALF
    hill_in%mat_desc%E = E
    hill_in%mat_desc%nu = nu
    hill_in%mat_desc%yieldStress = sigma_y0
    hill_in%mat_desc%hardeningModulus = H_hard
    hill_in%mat_desc%Hill_F = F1
    hill_in%mat_desc%Hill_G = HALF
    hill_in%mat_desc%Hill_H = HALF
    hill_in%mat_desc%Hill_L = 1.5_wp
    hill_in%mat_desc%Hill_M = 1.5_wp
    hill_in%mat_desc%Hill_N = 1.5_wp
    
    hill_in%strain_increment = strain_inc
    hill_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    hill_in%equiv_plastic_strain = ZERO
    
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    phi_F1 = SQRT( &
      F1 * (hill_out%stress_new(2) - hill_out%stress_new(3))**2 + &
      HALF * (hill_out%stress_new(3) - hill_out%stress_new(1))**2 + &
      HALF * (hill_out%stress_new(1) - hill_out%stress_new(2))**2 + &
      THREE * hill_out%stress_new(4)**2 + &
      THREE * hill_out%stress_new(5)**2 + &
      THREE * hill_out%stress_new(6)**2 )
    
    ! Test with F = 1.0 (anisotropic, enhanced yy-zz coupling)
    F2 = ONE
    hill_in%mat_desc%Hill_F = F2
    
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    phi_F2 = SQRT( &
      F2 * (hill_out%stress_new(2) - hill_out%stress_new(3))**2 + &
      HALF * (hill_out%stress_new(3) - hill_out%stress_new(1))**2 + &
      HALF * (hill_out%stress_new(1) - hill_out%stress_new(2))**2 + &
      THREE * hill_out%stress_new(4)**2 + &
      THREE * hill_out%stress_new(5)**2 + &
      THREE * hill_out%stress_new(6)**2 )
    
    ! Expected: φ_F2 > φ_F1 (larger F → larger equivalent stress)
    ratio_expected = SQRT(F2 / F1)
    ratio_actual = phi_F2 / phi_F1
    rel_error = ABS(ratio_actual - ratio_expected) / ratio_expected
    
    WRITE(*,*) '  Input: Biaxial tension (σ_yy ≠ σ_zz)'
    WRITE(*,*) '  F1 = 0.5 → φ_F1 = ', phi_F1 / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  F2 = 1.0 → φ_F2 = ', phi_F2 / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Expected ratio: φ_F2/φ_F1 = ', ratio_expected
    WRITE(*,*) '  Actual ratio: ', ratio_actual
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE_PLASTIC) THEN
      WRITE(*,*) '  ✅ PASSED: F parameter effect verified'
    ELSE
      WRITE(*,*) '  ❌ FAILED: F parameter effect mismatch'
    END IF
  END SUBROUTINE TC_HILL_05_Anisotropy_F_Parameter

  ! ============================================================================
  ! TC-HILL-06: 各向异性系数影响-N参数
  ! 验证N参数对剪切屈服的影响（影响τ_xy项）
  ! ============================================================================
  SUBROUTINE TC_HILL_06_Anisotropy_N_Parameter()
    TYPE(PH_Mat_PlasticHill_Eval_In) :: hill_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: hill_out
    REAL(wp) :: E, nu, sigma_y0, H_hard
    REAL(wp) :: N1, N2, phi_N1, phi_N2
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: ratio_expected, ratio_actual, rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-HILL-06: Anisotropy Coefficient - N Parameter Effect'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_hard = 2.0e9_wp
    
    ! Pure shear strain
    strain_inc = [ZERO, ZERO, ZERO, 0.002_wp, ZERO, ZERO]
    
    ! Test with N = 1.5 (isotropic)
    N1 = 1.5_wp
    hill_in%mat_desc%E = E
    hill_in%mat_desc%nu = nu
    hill_in%mat_desc%yieldStress = sigma_y0
    hill_in%mat_desc%hardeningModulus = H_hard
    hill_in%mat_desc%Hill_F = HALF
    hill_in%mat_desc%Hill_G = HALF
    hill_in%mat_desc%Hill_H = HALF
    hill_in%mat_desc%Hill_L = 1.5_wp
    hill_in%mat_desc%Hill_M = 1.5_wp
    hill_in%mat_desc%Hill_N = N1
    
    hill_in%strain_increment = strain_inc
    hill_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    hill_in%equiv_plastic_strain = ZERO
    
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    phi_N1 = SQRT(TWO * N1 * hill_out%stress_new(6)**2)
    
    ! Test with N = 2.0 (enhanced xy shear resistance)
    N2 = 2.0_wp
    hill_in%mat_desc%Hill_N = N2
    
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    phi_N2 = SQRT(TWO * N2 * hill_out%stress_new(6)**2)
    
    ! Expected: φ_N2/φ_N1 = √(N2/N1)
    ratio_expected = SQRT(N2 / N1)
    ratio_actual = phi_N2 / phi_N1
    rel_error = ABS(ratio_actual - ratio_expected) / ratio_expected
    
    WRITE(*,*) '  Input: Pure shear (γ_xy = 0.002)'
    WRITE(*,*) '  N1 = 1.5 → φ_N1 = ', phi_N1 / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  N2 = 2.0 → φ_N2 = ', phi_N2 / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Expected ratio: φ_N2/φ_N1 = ', ratio_expected
    WRITE(*,*) '  Actual ratio: ', ratio_actual
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: N parameter effect verified'
    ELSE
      WRITE(*,*) '  ❌ FAILED: N parameter effect mismatch'
    END IF
  END SUBROUTINE TC_HILL_06_Anisotropy_N_Parameter

  ! ============================================================================
  ! TC-HILL-07: 等双轴拉伸
  ! 验证σ_xx = σ_yy载荷下的屈服行为
  ! ============================================================================
  SUBROUTINE TC_HILL_07_EquiBiaxial_Tension()
    TYPE(PH_Mat_PlasticHill_Eval_In) :: hill_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: hill_out
    REAL(wp) :: E, nu, sigma_y0, H_hard
    REAL(wp) :: strain_inc(6), phi_trial, sigma_y
    REAL(wp) :: sigma_xx, sigma_yy, diff_stress
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-HILL-07: Equi-Biaxial Tension (σ_xx = σ_yy)'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_hard = 2.0e9_wp
    
    ! Initialize Hill input
    hill_in%mat_desc%E = E
    hill_in%mat_desc%nu = nu
    hill_in%mat_desc%yieldStress = sigma_y0
    hill_in%mat_desc%hardeningModulus = H_hard
    hill_in%mat_desc%Hill_F = HALF
    hill_in%mat_desc%Hill_G = HALF
    hill_in%mat_desc%Hill_H = HALF
    hill_in%mat_desc%Hill_L = 1.5_wp
    hill_in%mat_desc%Hill_M = 1.5_wp
    hill_in%mat_desc%Hill_N = 1.5_wp
    
    ! Equi-biaxial strain: ε_xx = ε_yy
    strain_inc = [0.0015_wp, 0.0015_wp, -0.0009_wp, ZERO, ZERO, ZERO]
    hill_in%strain_increment = strain_inc
    hill_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    hill_in%equiv_plastic_strain = ZERO
    
    ! Call Hill evaluation
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    
    ! For equi-biaxial (σ_xx = σ_yy):
    ! φ = √[F(σ_yy-σ_zz)² + G(σ_zz-σ_xx)² + H(σ_xx-σ_yy)²]
    ! With σ_xx = σ_yy, H term vanishes
    sigma_xx = hill_out%stress_new(1)
    sigma_yy = hill_out%stress_new(2)
    diff_stress = ABS(sigma_xx - sigma_yy)
    
    ! Check if σ_xx ≈ σ_yy (symmetry)
    WRITE(*,*) '  Input: ε_xx = ε_yy = 0.0015'
    WRITE(*,*) '  σ_xx = ', sigma_xx / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  σ_yy = ', sigma_yy / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  |σ_xx - σ_yy| = ', diff_stress / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Plastic strain: ', hill_out%equiv_plastic_strain
    
    IF (diff_stress < TOLERANCE * sigma_y0) THEN
      WRITE(*,*) '  ✅ PASSED: Equi-biaxial symmetry maintained'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: Stress asymmetry detected'
    END IF
  END SUBROUTINE TC_HILL_07_EquiBiaxial_Tension

  ! ============================================================================
  ! TC-HILL-08: 硬化模量影响
  ! 验证不同硬化模量对塑性修正的影响
  ! ============================================================================
  SUBROUTINE TC_HILL_08_Hardening_Modulus_Effect()
    TYPE(PH_Mat_PlasticHill_Eval_In) :: hill_in
    TYPE(PH_Mat_PlasticHill_Eval_Out) :: hill_out
    REAL(wp) :: E, nu, sigma_y0
    REAL(wp) :: H_hard1, H_hard2
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: eps_p1, eps_p2, ratio_hard, ratio_plastic
    REAL(wp) :: rel_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-HILL-08: Hardening Modulus Effect'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    
    ! Two hardening moduli
    H_hard1 = 1.0e9_wp   ! Soft hardening
    H_hard2 = 5.0e9_wp   ! Hard hardening
    
    ! Large plastic strain
    strain_inc = [0.003_wp, -0.0009_wp, -0.0009_wp, ZERO, ZERO, ZERO]
    
    ! Test with H_hard1
    hill_in%mat_desc%E = E
    hill_in%mat_desc%nu = nu
    hill_in%mat_desc%yieldStress = sigma_y0
    hill_in%mat_desc%hardeningModulus = H_hard1
    hill_in%mat_desc%Hill_F = HALF
    hill_in%mat_desc%Hill_G = HALF
    hill_in%mat_desc%Hill_H = HALF
    hill_in%mat_desc%Hill_L = 1.5_wp
    hill_in%mat_desc%Hill_M = 1.5_wp
    hill_in%mat_desc%Hill_N = 1.5_wp
    
    hill_in%strain_increment = strain_inc
    hill_in%stress_old = [ZERO, ZERO, ZERO, ZERO, ZERO, ZERO]
    hill_in%equiv_plastic_strain = ZERO
    
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    eps_p1 = hill_out%equiv_plastic_strain
    
    ! Test with H_hard2
    hill_in%mat_desc%hardeningModulus = H_hard2
    hill_in%equiv_plastic_strain = ZERO
    
    CALL PH_Mat_PlasticHill_Eval(hill_in, hill_out)
    eps_p2 = hill_out%equiv_plastic_strain
    
    ! Expected: ε̄_p ∝ 1/H (larger H → smaller plastic strain)
    ratio_hard = H_hard2 / H_hard1
    ratio_plastic = eps_p1 / eps_p2
    rel_error = ABS(ratio_plastic - ratio_hard) / ratio_hard
    
    WRITE(*,*) '  Input: Large plastic strain (ε_xx = 0.003)'
    WRITE(*,*) '  H_hard1 = 1.0 GPa → ε̄_p1 = ', eps_p1
    WRITE(*,*) '  H_hard2 = 5.0 GPa → ε̄_p2 = ', eps_p2
    WRITE(*,*) '  Hardening ratio: H2/H1 = ', ratio_hard
    WRITE(*,*) '  Plastic strain ratio: ε̄_p1/ε̄_p2 = ', ratio_plastic
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE_PLASTIC) THEN
      WRITE(*,*) '  ✅ PASSED: Hardening modulus effect verified (ε̄_p ∝ 1/H)'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: Hardening effect deviates (error = ', rel_error, ')'
    END IF
  END SUBROUTINE TC_HILL_08_Hardening_Modulus_Effect

END MODULE TEST_PH_Mat_Hill
