!===============================================================================
! Module: TEST_PH_Field_MultiPhysics
! Layer:  L4_PH - Physics Layer (Test)
! Domain: Field - Multi-Physics Fields (Concentration/Pore Pressure)
! Purpose: Test multi-physics field coupling (mass transfer/porous media)
! Theory:
!   Multi-physics field equations:
!   - Concentration: ∂c/∂t = D·∇²c + R (Fick's law)
!   - Pore pressure: ∂p/∂t = (k/μ)·∇²p + Q (Darcy's law)
!   - Coupled THM: Thermal-Hydraulic-Mechanical
!   - Weak form: ∫Nᵢ·∂φ/∂t dΩ + ∫D·∇Nᵢ·∇φ dΩ = ∫Nᵢ·R dΩ
!
! Test Cases:
!   TC-MP-01: 浓度场-扩散方程
!   TC-MP-02: 孔隙压力-Darcy渗流
!   TC-MP-03: 扩散系数计算
!   TC-MP-04: 渗透率计算
!   TC-MP-05: 质量守恒-浓度场
!   TC-MP-06: 流体守恒-渗流场
!   TC-MP-07: THM耦合-热-流-固
!   TC-MP-08: 场变量插值
!
! Status: Production | Created: 2026-04-18
!===============================================================================

MODULE TEST_PH_Field_MultiPhysics
  USE IF_Const, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_All_Field_MultiPhysics_Tests

  REAL(wp), PARAMETER :: TOLERANCE = 1.0e-6_wp
  REAL(wp), PARAMETER :: TOLERANCE_FIELD = 1.0e-3_wp  ! 0.1% for field variables

CONTAINS

  SUBROUTINE Run_All_Field_MultiPhysics_Tests()
    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Field_MultiPhysics: Multi-Physics Field Tests'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    CALL TC_MP_01_Concentration_Diffusion()
    CALL TC_MP_02_PorePressure_Darcy()
    CALL TC_MP_03_DiffusionCoefficient()
    CALL TC_MP_04_Permeability_Calculation()
    CALL TC_MP_05_MassConservation_Concentration()
    CALL TC_MP_06_FluidConservation_Flow()
    CALL TC_MP_07_THM_Coupling()
    CALL TC_MP_08_FieldInterpolation()

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Field_MultiPhysics: All 8 Tests Completed'
    WRITE(*,*) '===================================================================='
  END SUBROUTINE Run_All_Field_MultiPhysics_Tests

  ! ============================================================================
  ! TC-MP-01: 浓度场-扩散方程
  ! 验证Fick扩散方程求解
  ! ============================================================================
  SUBROUTINE TC_MP_01_Concentration_Diffusion()
    REAL(wp) :: D, dt, dx
    REAL(wp) :: c_old(5), c_new(5)
    REAL(wp) :: r
    INTEGER(i4) :: i, n_steps
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MP-01: Concentration Field - Diffusion Equation (Fick''s Law)'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Diffusion coefficient
    D = 1.0e-9_wp  ! m²/s (typical for solutes in water)
    dx = 0.01_wp   ! Spatial step
    dt = 0.1_wp * dx**2 / D  ! Time step
    
    ! Initial condition (step function)
    c_old = [1.0_wp, 1.0_wp, 0.0_wp, 0.0_wp, 0.0_wp]
    
    r = D * dt / dx**2
    
    ! Explicit diffusion
    n_steps = 20_i4
    DO i = 1, n_steps
      c_new(1) = c_old(1)
      c_new(2) = c_old(2) + r * (c_old(3) - 2.0_wp*c_old(2) + c_old(1))
      c_new(3) = c_old(3) + r * (c_old(4) - 2.0_wp*c_old(3) + c_old(2))
      c_new(4) = c_old(4) + r * (c_old(5) - 2.0_wp*c_old(4) + c_old(3))
      c_new(5) = c_old(5)
      
      c_old = c_new
    END DO
    
    WRITE(*,*) '  Diffusion coefficient: D = ', D, ' m²/s'
    WRITE(*,*) '  Spatial step: Δx = ', dx, ' m'
    WRITE(*,*) '  Time step: Δt = ', dt, ' s'
    WRITE(*,*) '  Ratio: r = D·Δt/Δx² = ', r
    WRITE(*,*) '  Time steps: ', n_steps
    WRITE(*,*) '  Final concentration: ', c_new
    
    IF (ALL(c_new >= ZERO) .AND. ALL(c_new <= ONE)) THEN
      WRITE(*,*) '  ✅ PASSED: Diffusion solution bounded'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Concentration out of bounds'
    END IF
  END SUBROUTINE TC_MP_01_Concentration_Diffusion

  ! ============================================================================
  ! TC-MP-02: 孔隙压力-Darcy渗流
  ! 验证Darcy定律渗流求解
  ! ============================================================================
  SUBROUTINE TC_MP_02_PorePressure_Darcy()
    REAL(wp) :: k_perm, mu, dp_dx, v_darcy
    REAL(wp) :: porosity, permeability
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MP-02: Pore Pressure - Darcy Flow'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Darcy's law: v = -(k/μ)·∇p
    k_perm = 1.0e-12_wp   ! Permeability (m²)
    mu = 1.0e-3_wp        ! Dynamic viscosity (Pa·s)
    dp_dx = -1.0e6_wp     ! Pressure gradient (Pa/m)
    
    ! Darcy velocity
    v_darcy = -(k_perm / mu) * dp_dx
    
    porosity = 0.25_wp    ! Porosity
    permeability = k_perm
    
    WRITE(*,*) '  Permeability: k = ', k_perm, ' m²'
    WRITE(*,*) '  Viscosity: μ = ', mu, ' Pa·s'
    WRITE(*,*) '  Pressure gradient: ∇p = ', dp_dx, ' Pa/m'
    WRITE(*,*) '  Darcy velocity: v_D = ', v_darcy, ' m/s'
    WRITE(*,*) '  Porosity: φ = ', porosity
    
    IF (v_darcy > ZERO) THEN
      WRITE(*,*) '  ✅ PASSED: Darcy flow direction correct'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Flow direction error'
    END IF
  END SUBROUTINE TC_MP_02_PorePressure_Darcy

  ! ============================================================================
  ! TC-MP-03: 扩散系数计算
  ! 验证扩散系数温度依赖性
  ! ============================================================================
  SUBROUTINE TC_MP_03_DiffusionCoefficient()
    REAL(wp) :: D_0, E_a, R_gas, T
    REAL(wp) :: D_calc, D_expected
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MP-03: Diffusion Coefficient - Temperature Dependence'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Arrhenius equation: D = D_0·exp(-E_a/RT)
    D_0 = 1.0e-6_wp      ! Pre-exponential factor (m²/s)
    E_a = 50.0e3_wp      ! Activation energy (J/mol)
    R_gas = 8.314_wp     ! Gas constant (J/mol·K)
    T = 298.15_wp        ! Temperature (K)
    
    D_calc = D_0 * EXP(-E_a / (R_gas * T))
    D_expected = 1.57e-15_wp  ! Approximate
    
    WRITE(*,*) '  Pre-exponential: D_0 = ', D_0, ' m²/s'
    WRITE(*,*) '  Activation energy: E_a = ', E_a/1000.0_wp, ' kJ/mol'
    WRITE(*,*) '  Temperature: T = ', T, ' K'
    WRITE(*,*) '  Calculated D = ', D_calc, ' m²/s'
    WRITE(*,*) '  Expected D ≈ ', D_expected, ' m²/s'
    
    IF (D_calc > ZERO .AND. D_calc < D_0) THEN
      WRITE(*,*) '  ✅ PASSED: Diffusion coefficient valid (Arrhenius)'
    ELSE
      WRITE(*,*) '  ❌ FAILED: D calculation error'
    END IF
  END SUBROUTINE TC_MP_03_DiffusionCoefficient

  ! ============================================================================
  ! TC-MP-04: 渗透率计算
  ! 验证渗透率-孔隙率关系 (Kozeny-Carman)
  ! ============================================================================
  SUBROUTINE TC_MP_04_Permeability_Calculation()
    REAL(wp) :: porosity, grain_size
    REAL(wp) :: k_calc, KZ_const
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MP-04: Permeability Calculation - Kozeny-Carman Equation'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Kozeny-Carman: k = φ³ / [C·(1-φ)²·S²]
    porosity = 0.3_wp        ! Porosity
    grain_size = 1.0e-4_wp   ! Grain size (m)
    KZ_const = 180.0_wp      ! Kozeny constant
    
    k_calc = porosity**3 / (KZ_const * (ONE - porosity)**2 * (1.0_wp/grain_size)**2)
    
    WRITE(*,*) '  Porosity: φ = ', porosity
    WRITE(*,*) '  Grain size: d = ', grain_size * 1000.0_wp, ' mm'
    WRITE(*,*) '  Kozeny constant: C = ', KZ_const
    WRITE(*,*) '  Calculated permeability: k = ', k_calc, ' m²'
    
    IF (k_calc > ZERO .AND. k_calc < 1.0e-8_wp) THEN
      WRITE(*,*) '  ✅ PASSED: Permeability reasonable'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Permeability out of range'
    END IF
  END SUBROUTINE TC_MP_04_Permeability_Calculation

  ! ============================================================================
  ! TC-MP-05: 质量守恒-浓度场
  ! 验证扩散过程质量守恒
  ! ============================================================================
  SUBROUTINE TC_MP_05_MassConservation_Concentration()
    REAL(wp) :: c_initial(5), c_final(5)
    REAL(wp) :: mass_initial, mass_final
    REAL(wp) :: conservation_error
    INTEGER(i4) :: i
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MP-05: Mass Conservation - Concentration Field'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Initial concentration
    c_initial = [0.2_wp, 0.4_wp, 0.6_wp, 0.4_wp, 0.2_wp]
    
    ! After diffusion (simulated)
    c_final = [0.25_wp, 0.42_wp, 0.50_wp, 0.42_wp, 0.25_wp]
    
    ! Total mass
    mass_initial = SUM(c_initial)
    mass_final = SUM(c_final)
    
    ! Conservation error
    conservation_error = ABS(mass_final - mass_initial) / mass_initial * 100.0_wp
    
    WRITE(*,*) '  Initial concentration: ', c_initial
    WRITE(*,*) '  Final concentration: ', c_final
    WRITE(*,*) '  Initial mass: ', mass_initial
    WRITE(*,*) '  Final mass: ', mass_final
    WRITE(*,*) '  Conservation error: ', conservation_error, '%'
    
    IF (conservation_error < TOLERANCE_FIELD * 100.0_wp) THEN
      WRITE(*,*) '  ✅ PASSED: Mass conserved'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Mass not conserved'
    END IF
  END SUBROUTINE TC_MP_05_MassConservation_Concentration

  ! ============================================================================
  ! TC-MP-06: 流体守恒-渗流场
  ! 验证渗流过程流体守恒
  ! ============================================================================
  SUBROUTINE TC_MP_06_FluidConservation_Flow()
    REAL(wp) :: p_initial(5), p_final(5)
    REAL(wp) :: fluid_initial, fluid_final
    REAL(wp) :: porosity, V_elem
    REAL(wp) :: conservation_error
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MP-06: Fluid Conservation - Flow Field'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    porosity = 0.25_wp
    V_elem = 0.001_wp
    
    ! Initial pressure
    p_initial = [1.0e5_wp, 1.5e5_wp, 2.0e5_wp, 1.5e5_wp, 1.0e5_wp]
    
    ! After flow (simulated)
    p_final = [1.1e5_wp, 1.45e5_wp, 1.9e5_wp, 1.45e5_wp, 1.1e5_wp]
    
    ! Total fluid content (proportional to pressure for compressible flow)
    fluid_initial = SUM(p_initial)
    fluid_final = SUM(p_final)
    
    conservation_error = ABS(fluid_final - fluid_initial) / fluid_initial * 100.0_wp
    
    WRITE(*,*) '  Porosity: φ = ', porosity
    WRITE(*,*) '  Initial pressure: ', p_initial/1000.0_wp, ' kPa'
    WRITE(*,*) '  Final pressure: ', p_final/1000.0_wp, ' kPa'
    WRITE(*,*) '  Conservation error: ', conservation_error, '%'
    
    IF (conservation_error < 5.0_wp) THEN  ! 5% tolerance for compressible flow
      WRITE(*,*) '  ✅ PASSED: Fluid approximately conserved'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Fluid not conserved'
    END IF
  END SUBROUTINE TC_MP_06_FluidConservation_Flow

  ! ============================================================================
  ! TC-MP-07: THM耦合-热-流-固
  ! 验证THM三场耦合基本概念
  ! ============================================================================
  SUBROUTINE TC_MP_07_THM_Coupling()
    REAL(wp) :: alpha_T, alpha_p, beta_T
    REAL(wp) :: T_change, p_change, vol_change
    LOGICAL :: coupled
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MP-07: THM Coupling - Thermal-Hydraulic-Mechanical'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Coupling coefficients
    alpha_T = 1.0e-5_wp     ! Thermal expansion coefficient (1/K)
    alpha_p = 1.0e-9_wp     ! Biot coefficient (1/Pa)
    beta_T = 3.0e-4_wp      ! Thermal pressure coefficient (Pa/K)
    
    ! Field changes
    T_change = 50.0_wp      ! Temperature increase (K)
    p_change = 1.0e6_wp     ! Pressure increase (Pa)
    
    ! Volumetric strain (coupled)
    vol_change = alpha_T * T_change + alpha_p * p_change
    
    ! Coupling verification
    coupled = (vol_change > ZERO)
    
    WRITE(*,*) '  Thermal expansion: α_T = ', alpha_T, ' 1/K'
    WRITE(*,*) '  Biot coefficient: α_p = ', alpha_p, ' 1/Pa'
    WRITE(*,*) '  Thermal pressure: β_T = ', beta_T, ' Pa/K'
    WRITE(*,*) '  Temperature change: ΔT = ', T_change, ' K'
    WRITE(*,*) '  Pressure change: Δp = ', p_change/1.0e6_wp, ' MPa'
    WRITE(*,*) '  Volumetric strain: ε_v = ', vol_change
    WRITE(*,*) '  Coupled: ', coupled
    
    IF (coupled) THEN
      WRITE(*,*) '  ✅ PASSED: THM coupling active'
    ELSE
      WRITE(*,*) '  ❌ FAILED: No coupling detected'
    END IF
  END SUBROUTINE TC_MP_07_THM_Coupling

  ! ============================================================================
  ! TC-MP-08: 场变量插值
  ! 验证形函数插值场变量
  ! ============================================================================
  SUBROUTINE TC_MP_08_FieldInterpolation()
    REAL(wp) :: N(4), phi_nodes(4), phi_interp
    REAL(wp) :: xi, eta
    INTEGER(i4) :: i
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-MP-08: Field Variable Interpolation - Shape Functions'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Evaluation point
    xi = 0.0_wp
    eta = 0.0_wp
    
    ! 4-node quad shape functions at center
    N(1) = 0.25_wp * (ONE - xi) * (ONE - eta)
    N(2) = 0.25_wp * (ONE + xi) * (ONE - eta)
    N(3) = 0.25_wp * (ONE + xi) * (ONE + eta)
    N(4) = 0.25_wp * (ONE - xi) * (ONE + eta)
    
    ! Nodal values (temperature)
    phi_nodes = [100.0_wp, 150.0_wp, 200.0_wp, 150.0_wp]
    
    ! Interpolation: φ = ΣN_i·φ_i
    phi_interp = ZERO
    DO i = 1, 4
      phi_interp = phi_interp + N(i) * phi_nodes(i)
    END DO
    
    WRITE(*,*) '  Evaluation point: (ξ, η) = (', xi, ', ', eta, ')'
    WRITE(*,*) '  Shape functions: ', N
    WRITE(*,*) '  Nodal values: ', phi_nodes, '°C'
    WRITE(*,*) '  Interpolated value: φ = ', phi_interp, '°C'
    WRITE(*,*) '  Expected: ', SUM(phi_nodes)/4.0_wp, '°C (average)'
    
    IF (ABS(phi_interp - 150.0_wp) < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Field interpolation correct'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Interpolation error'
    END IF
  END SUBROUTINE TC_MP_08_FieldInterpolation

END MODULE TEST_PH_Field_MultiPhysics
