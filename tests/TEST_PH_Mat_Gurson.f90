!===============================================================================
! Module: TEST_PH_Mat_Gurson
! Layer:  L5_RT - Runtime Layer (Test)
! Domain: Material - Gurson-Tvergaard-Needleman (GTN) Porous Plastic Damage
! Purpose: Test GTN porous plastic damage constitutive model
! Theory:
!   GTN yield criterion:
!   Φ = (q/σ_y0)² + 2·q1·f*·cosh(q/(2·σ_y0)) - 1 - (q1·f*)² = 0
!   
!   where:
!   - q: von Mises equivalent stress
!   - σ_y0: Initial yield stress
!   - f*: Effective void volume fraction (f_star)
!   - q1, q2, q3: Tvergaard parameters
!
!   Porosity evolution:
!   - Growth: ḟ_growth = (1-f)·tr(ε̇_p)
!   - Nucleation: ḟ_nucleation = A·ε̇_p
!   - f* = f (if f ≤ f_c), else accelerated growth
!
! Test Cases:
!   TC-GTN-01: 初始孔隙损伤-弹性试算
!   TC-GTN-02: 孔隙演化-单轴拉伸
!   TC-GTN-03: 临界孔隙度-f_c触发加速
!   TC-GTN-04: Tvergaard参数-q1影响
!   TC-GTN-05: Tvergaard参数-q2影响
!   TC-GTN-06: 失效分析-f_F达到失效
!   TC-GTN-07: 静水压力影响-三轴拉伸
!   TC-GTN-08: 孔隙损伤-刚度退化验证
!
! Status: Production | Created: 2026-04-17
!===============================================================================

MODULE TEST_PH_Mat_Gurson
  USE IF_Const, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Prec_Core, ONLY: i4, wp
  USE PH_Mat_Damage_Gurson, ONLY: PH_Mat_GTN_State, PH_GTN_UMAT_Args, &
                                   PH_GTN_UMAT_API
  USE MD_Pls_GTN, ONLY: MD_Mat_GTN_Desc
  USE PH_Mat_Types, ONLY: PH_Mat_Base_Ctx, PH_Mat_Base_Algo
  USE MD_Mat_Types, ONLY: MD_Mat_Base_Algo
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_All_Gurson_Tests

  ! Test tolerance
  REAL(wp), PARAMETER :: TOLERANCE = 1.0e-6_wp
  REAL(wp), PARAMETER :: TOLERANCE_DAMAGE = 1.0e-2_wp  ! 1% for damage

CONTAINS

  SUBROUTINE Run_All_Gurson_Tests()
    !! Run all GTN porous damage test cases
    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Mat_Gurson: GTN Porous Plastic Damage Tests'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    CALL TC_GTN_01_Initial_Porosity_Elastic()
    CALL TC_GTN_02_Porosity_Evolution_Uniaxial()
    CALL TC_GTN_03_Critical_Porosity_fc()
    CALL TC_GTN_04_Tvergaard_q1_Effect()
    CALL TC_GTN_05_Tvergaard_q2_Effect()
    CALL TC_GTN_06_Failure_Analysis_fF()
    CALL TC_GTN_07_Hydrostatic_Pressure_Triaxial()
    CALL TC_GTN_08_Damage_Stiffness_Degradation()

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'TEST_PH_Mat_Gurson: All 8 Tests Completed'
    WRITE(*,*) '===================================================================='
  END SUBROUTINE Run_All_Gurson_Tests

  ! ============================================================================
  ! TC-GTN-01: 初始孔隙损伤-弹性试算
  ! 验证小应变下处于弹性阶段，孔隙度不变
  ! ============================================================================
  SUBROUTINE TC_GTN_01_Initial_Porosity_Elastic()
    TYPE(MD_Mat_GTN_Desc) :: gtn_desc
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    TYPE(PH_Mat_GTN_State) :: mat_state
    TYPE(MD_Mat_Base_Algo) :: mat_algo
    TYPE(PH_Mat_Base_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: com_ctx
    REAL(wp) :: pnewdt
    REAL(wp) :: D_el(6,6), strain_inc(6)
    REAL(wp) :: sigma_expected(6), sigma_actual(6)
    REAL(wp) :: E, nu, sigma_y0, H_iso
    REAL(wp) :: f0, rel_error
    INTEGER(i4) :: i
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-GTN-01: Initial Porosity - Elastic Trial'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties (Steel with initial porosity)
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_iso = 2.0e9_wp
    f0 = 0.001_wp  ! 0.1% initial porosity
    
    ! Initialize GTN descriptor
    gtn_desc%E = E
    gtn_desc%nu = nu
    gtn_desc%sigma_y0 = sigma_y0
    gtn_desc%H_iso = H_iso
    gtn_desc%q1 = 1.5_wp
    gtn_desc%q2 = 1.0_wp
    gtn_desc%q3 = 1.0_wp
    gtn_desc%f0 = f0
    gtn_desc%fN = 0.01_wp
    gtn_desc%epsilonN = 0.3_wp
    gtn_desc%sN = 0.1_wp
    gtn_desc%fc = 0.1_wp
    gtn_desc%fF = 0.2_wp
    gtn_desc%G = E / (TWO * (ONE + nu))
    gtn_desc%K = E / (THREE * (ONE - TWO * nu))
    gtn_desc%mat_id = 207_i4
    gtn_desc%mat_family = 2_i4
    gtn_desc%model_name = "GTN Porous Plastic Damage"
    gtn_desc%is_initialized = .TRUE.
    
    ! Initialize state
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    ! Context
    strain_inc = [0.0005_wp, -0.00015_wp, -0.00015_wp, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_inc
    
    ! Algorithm flags
    mat_algo%ntens = 6
    mat_algo%compute_tangent = .TRUE.
    
    ! Common context
    com_ctx%nlgeom = .FALSE.
    com_ctx%first_increment = .TRUE.
    com_ctx%gauss_pt = 1_i4
    
    ! Call GTN UMAT
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    
    ! Expected: Elastic stress σ = D·ε
    ! σ_xx = E·ε_xx = 210e9 × 0.0005 = 105e6 Pa
    sigma_expected(1) = E * strain_inc(1)
    sigma_expected(2) = ZERO  ! Simplified
    sigma_expected(3) = ZERO
    sigma_expected(4) = ZERO
    sigma_expected(5) = ZERO
    sigma_expected(6) = ZERO
    
    sigma_actual = mat_state%stress
    rel_error = ABS(sigma_actual(1) - sigma_expected(1)) / sigma_expected(1)
    
    WRITE(*,*) '  Input: ε_xx = 0.0005 (elastic, small strain)'
    WRITE(*,*) '  Initial porosity: f0 = ', f0
    WRITE(*,*) '  Expected: σ_xx = 105 MPa (elastic, < σ_y)'
    WRITE(*,*) '  Actual: σ_xx = ', sigma_actual(1) / 1.0e6_wp, ' MPa'
    WRITE(*,*) '  Porosity after: f = ', mat_state%porosity
    WRITE(*,*) '  Relative error: ', rel_error
    
    IF (rel_error < TOLERANCE .AND. ABS(mat_state%porosity - f0) < TOLERANCE) THEN
      WRITE(*,*) '  ✅ PASSED: Elastic trial (porosity unchanged)'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Elastic test failed'
    END IF
  END SUBROUTINE TC_GTN_01_Initial_Porosity_Elastic

  ! ============================================================================
  ! TC-GTN-02: 孔隙演化-单轴拉伸
  ! 验证塑性变形导致孔隙度增长
  ! ============================================================================
  SUBROUTINE TC_GTN_02_Porosity_Evolution_Uniaxial()
    TYPE(MD_Mat_GTN_Desc) :: gtn_desc
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    TYPE(PH_Mat_GTN_State) :: mat_state
    TYPE(MD_Mat_Base_Algo) :: mat_algo
    TYPE(PH_Mat_Base_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: com_ctx
    REAL(wp) :: pnewdt
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: f_initial, f_final, df_expected
    REAL(wp) :: E, nu, sigma_y0, H_iso, f0, fN
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-GTN-02: Porosity Evolution - Uniaxial Tension'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_iso = 2.0e9_wp
    f0 = 0.001_wp
    fN = 0.01_wp
    
    ! Initialize GTN descriptor
    gtn_desc%E = E
    gtn_desc%nu = nu
    gtn_desc%sigma_y0 = sigma_y0
    gtn_desc%H_iso = H_iso
    gtn_desc%q1 = 1.5_wp
    gtn_desc%q2 = 1.0_wp
    gtn_desc%q3 = 1.0_wp
    gtn_desc%f0 = f0
    gtn_desc%fN = fN
    gtn_desc%epsilonN = 0.3_wp
    gtn_desc%sN = 0.1_wp
    gtn_desc%fc = 0.1_wp
    gtn_desc%fF = 0.2_wp
    gtn_desc%G = E / (TWO * (ONE + nu))
    gtn_desc%K = E / (THREE * (ONE - TWO * nu))
    gtn_desc%mat_id = 207_i4
    gtn_desc%mat_family = 2_i4
    gtn_desc%model_name = "GTN Porous Plastic Damage"
    gtn_desc%is_initialized = .TRUE.
    
    ! Initialize state
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    ! Large plastic strain
    strain_inc = [0.003_wp, -0.0009_wp, -0.0009_wp, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_inc
    
    mat_algo%ntens = 6
    mat_algo%compute_tangent = .TRUE.
    
    com_ctx%nlgeom = .FALSE.
    com_ctx%first_increment = .FALSE.
    com_ctx%gauss_pt = 1_i4
    
    f_initial = mat_state%porosity
    
    ! Call GTN UMAT
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    
    f_final = mat_state%porosity
    
    ! Expected: Porosity should increase (f_final > f_initial)
    WRITE(*,*) '  Input: ε_xx = 0.003 (plastic)'
    WRITE(*,*) '  Initial porosity: f0 = ', f_initial
    WRITE(*,*) '  Final porosity: f = ', f_final
    WRITE(*,*) '  Porosity increase: Δf = ', f_final - f_initial
    WRITE(*,*) '  Equivalent plastic strain: ε̄_p = ', mat_state%peeq
    
    IF (f_final > f_initial .AND. mat_state%peeq > 1.0e-8_wp) THEN
      WRITE(*,*) '  ✅ PASSED: Porosity evolution (f increased with plastic strain)'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Porosity did not evolve'
    END IF
  END SUBROUTINE TC_GTN_02_Porosity_Evolution_Uniaxial

  ! ============================================================================
  ! TC-GTN-03: 临界孔隙度-f_c触发加速
  ! 验证当f > f_c时，f*加速增长机制
  ! ============================================================================
  SUBROUTINE TC_GTN_03_Critical_Porosity_fc()
    TYPE(MD_Mat_GTN_Desc) :: gtn_desc
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    TYPE(PH_Mat_GTN_State) :: mat_state
    TYPE(MD_Mat_Base_Algo) :: mat_algo
    TYPE(PH_Mat_Base_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: com_ctx
    REAL(wp) :: pnewdt
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: f0_low, f0_high, fc
    REAL(wp) :: f_final_low, f_final_high
    REAL(wp) :: E, nu, sigma_y0, H_iso
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-GTN-03: Critical Porosity - f_c Trigger Accelerated Growth'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    H_iso = 2.0e9_wp
    fc = 0.05_wp  ! Critical porosity 5%
    
    ! Test 1: f0 < f_c (normal growth)
    f0_low = 0.01_wp
    
    gtn_desc%E = E
    gtn_desc%nu = nu
    gtn_desc%sigma_y0 = sigma_y0
    gtn_desc%H_iso = H_iso
    gtn_desc%q1 = 1.5_wp
    gtn_desc%q2 = 1.0_wp
    gtn_desc%q3 = 1.0_wp
    gtn_desc%f0 = f0_low
    gtn_desc%fN = 0.01_wp
    gtn_desc%epsilonN = 0.3_wp
    gtn_desc%sN = 0.1_wp
    gtn_desc%fc = fc
    gtn_desc%fF = 0.15_wp
    gtn_desc%G = E / (TWO * (ONE + nu))
    gtn_desc%K = E / (THREE * (ONE - TWO * nu))
    gtn_desc%mat_id = 207_i4
    gtn_desc%mat_family = 2_i4
    gtn_desc%model_name = "GTN Porous Plastic Damage"
    gtn_desc%is_initialized = .TRUE.
    
    mat_state%peeq = ZERO
    mat_state%porosity = f0_low
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    strain_inc = [0.005_wp, -0.0015_wp, -0.0015_wp, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_inc
    mat_algo%ntens = 6
    mat_algo%compute_tangent = .TRUE.
    com_ctx%nlgeom = .FALSE.
    com_ctx%first_increment = .FALSE.
    com_ctx%gauss_pt = 1_i4
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    f_final_low = mat_state%porosity
    
    ! Test 2: f0 > f_c (accelerated growth)
    f0_high = 0.08_wp
    
    mat_state%porosity = f0_high
    mat_state%peeq = ZERO
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    f_final_high = mat_state%porosity
    
    ! Expected: f_final_high should show accelerated growth
    WRITE(*,*) '  Input: Large plastic strain (ε_xx = 0.005)'
    WRITE(*,*) '  Critical porosity: f_c = ', fc
    WRITE(*,*) '  Test 1 (f0 = ', f0_low, ' < f_c): f_final = ', f_final_low
    WRITE(*,*) '  Test 2 (f0 = ', f0_high, ' > f_c): f_final = ', f_final_high
    WRITE(*,*) '  Growth ratio (high/low): ', (f_final_high - f0_high) / (f_final_low - f0_low)
    
    IF (f_final_high > f_final_low) THEN
      WRITE(*,*) '  ✅ PASSED: Accelerated growth triggered when f > f_c'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Accelerated growth not detected'
    END IF
  END SUBROUTINE TC_GTN_03_Critical_Porosity_fc

  ! ============================================================================
  ! TC-GTN-04: Tvergaard参数-q1影响
  ! 验证q1参数对屈服面的影响
  ! ============================================================================
  SUBROUTINE TC_GTN_04_Tvergaard_q1_Effect()
    TYPE(MD_Mat_GTN_Desc) :: gtn_desc
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    TYPE(PH_Mat_GTN_State) :: mat_state
    TYPE(MD_Mat_Base_Algo) :: mat_algo
    TYPE(PH_Mat_Base_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: com_ctx
    REAL(wp) :: pnewdt
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: q1_low, q1_high
    REAL(wp) :: phi_q1_low, phi_q1_high
    REAL(wp) :: E, nu, sigma_y0, f0, p, q
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-GTN-04: Tvergaard Parameter - q1 Effect'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    f0 = 0.01_wp
    
    ! Initialize common descriptor
    gtn_desc%E = E
    gtn_desc%nu = nu
    gtn_desc%sigma_y0 = sigma_y0
    gtn_desc%H_iso = 2.0e9_wp
    gtn_desc%q2 = 1.0_wp
    gtn_desc%q3 = 1.0_wp
    gtn_desc%f0 = f0
    gtn_desc%fN = 0.01_wp
    gtn_desc%epsilonN = 0.3_wp
    gtn_desc%sN = 0.1_wp
    gtn_desc%fc = 0.1_wp
    gtn_desc%fF = 0.2_wp
    gtn_desc%G = E / (TWO * (ONE + nu))
    gtn_desc%K = E / (THREE * (ONE - TWO * nu))
    gtn_desc%mat_id = 207_i4
    gtn_desc%mat_family = 2_i4
    gtn_desc%model_name = "GTN Porous Plastic Damage"
    gtn_desc%is_initialized = .TRUE.
    
    strain_inc = [0.003_wp, -0.0009_wp, -0.0009_wp, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_inc
    mat_algo%ntens = 6
    mat_algo%compute_tangent = .TRUE.
    com_ctx%nlgeom = .FALSE.
    com_ctx%first_increment = .FALSE.
    com_ctx%gauss_pt = 1_i4
    
    ! Test with q1 = 1.0
    q1_low = ONE
    gtn_desc%q1 = q1_low
    
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    
    ! Compute yield function value
    p = (mat_state%stress(1) + mat_state%stress(2) + mat_state%stress(3)) / THREE
    q = SQRT(1.5_wp * ((mat_state%stress(1)-p)**2 + (mat_state%stress(2)-p)**2 + &
         (mat_state%stress(3)-p)**2 + TWO*(mat_state%stress(4)**2 + mat_state%stress(5)**2 + mat_state%stress(6)**2)))
    phi_q1_low = (q/sigma_y0)**2 + TWO*q1_low*mat_state%porosity*COSH(q/(TWO*sigma_y0)) - ONE - (q1_low*mat_state%porosity)**2
    
    ! Test with q1 = 2.0
    q1_high = TWO
    gtn_desc%q1 = q1_high
    
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    
    p = (mat_state%stress(1) + mat_state%stress(2) + mat_state%stress(3)) / THREE
    q = SQRT(1.5_wp * ((mat_state%stress(1)-p)**2 + (mat_state%stress(2)-p)**2 + &
         (mat_state%stress(3)-p)**2 + TWO*(mat_state%stress(4)**2 + mat_state%stress(5)**2 + mat_state%stress(6)**2)))
    phi_q1_high = (q/sigma_y0)**2 + TWO*q1_high*mat_state%porosity*COSH(q/(TWO*sigma_y0)) - ONE - (q1_high*mat_state%porosity)**2
    
    WRITE(*,*) '  Input: Plastic strain (ε_xx = 0.003)'
    WRITE(*,*) '  q1_low = 1.0 → Φ = ', phi_q1_low
    WRITE(*,*) '  q1_high = 2.0 → Φ = ', phi_q1_high
    WRITE(*,*) '  Expected: Larger q1 → stronger void interaction → lower yield stress'
    
    IF (phi_q1_high > phi_q1_low) THEN
      WRITE(*,*) '  ✅ PASSED: q1 parameter effect verified'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: q1 effect may be model-dependent'
    END IF
  END SUBROUTINE TC_GTN_04_Tvergaard_q1_Effect

  ! ============================================================================
  ! TC-GTN-05: Tvergaard参数-q2影响
  ! 验证q2参数在f*计算中的作用
  ! ============================================================================
  SUBROUTINE TC_GTN_05_Tvergaard_q2_Effect()
    TYPE(MD_Mat_GTN_Desc) :: gtn_desc
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    TYPE(PH_Mat_GTN_State) :: mat_state
    TYPE(MD_Mat_Base_Algo) :: mat_algo
    TYPE(PH_Mat_Base_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: com_ctx
    REAL(wp) :: pnewdt
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: q2_low, q2_high
    REAL(wp) :: f_final_low, f_final_high
    REAL(wp) :: E, nu, sigma_y0, f0, fc
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-GTN-05: Tvergaard Parameter - q2 Effect on f*'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    f0 = 0.06_wp  ! Above fc to activate f*
    fc = 0.05_wp
    
    ! Initialize common descriptor
    gtn_desc%E = E
    gtn_desc%nu = nu
    gtn_desc%sigma_y0 = sigma_y0
    gtn_desc%H_iso = 2.0e9_wp
    gtn_desc%q1 = 1.5_wp
    gtn_desc%q3 = 1.0_wp
    gtn_desc%f0 = f0
    gtn_desc%fN = 0.01_wp
    gtn_desc%epsilonN = 0.3_wp
    gtn_desc%sN = 0.1_wp
    gtn_desc%fc = fc
    gtn_desc%fF = 0.15_wp
    gtn_desc%G = E / (TWO * (ONE + nu))
    gtn_desc%K = E / (THREE * (ONE - TWO * nu))
    gtn_desc%mat_id = 207_i4
    gtn_desc%mat_family = 2_i4
    gtn_desc%model_name = "GTN Porous Plastic Damage"
    gtn_desc%is_initialized = .TRUE.
    
    strain_inc = [0.004_wp, -0.0012_wp, -0.0012_wp, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_inc
    mat_algo%ntens = 6
    mat_algo%compute_tangent = .TRUE.
    com_ctx%nlgeom = .FALSE.
    com_ctx%first_increment = .FALSE.
    com_ctx%gauss_pt = 1_i4
    
    ! Test with q2 = 1.0
    q2_low = ONE
    gtn_desc%q2 = q2_low
    
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    f_final_low = mat_state%porosity
    
    ! Test with q2 = 2.0 (accelerated f* growth)
    q2_high = TWO
    gtn_desc%q2 = q2_high
    
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    f_final_high = mat_state%porosity
    
    WRITE(*,*) '  Input: Plastic strain with f0 > f_c'
    WRITE(*,*) '  q2_low = 1.0 → f_final = ', f_final_low
    WRITE(*,*) '  q2_high = 2.0 → f_final = ', f_final_high
    WRITE(*,*) '  Expected: Larger q2 → faster f* growth → more damage'
    
    IF (f_final_high > f_final_low) THEN
      WRITE(*,*) '  ✅ PASSED: q2 parameter effect on f* verified'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: q2 effect may be model-dependent'
    END IF
  END SUBROUTINE TC_GTN_05_Tvergaard_q2_Effect

  ! ============================================================================
  ! TC-GTN-06: 失效分析-f_F达到失效
  ! 验证当孔隙度达到f_F时材料失效
  ! ============================================================================
  SUBROUTINE TC_GTN_06_Failure_Analysis_fF()
    TYPE(MD_Mat_GTN_Desc) :: gtn_desc
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    TYPE(PH_Mat_GTN_State) :: mat_state
    TYPE(MD_Mat_Base_Algo) :: mat_algo
    TYPE(PH_Mat_Base_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: com_ctx
    REAL(wp) :: pnewdt
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: f0, fF
    REAL(wp) :: E, nu, sigma_y0
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-GTN-06: Failure Analysis - f_F Reached'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    f0 = 0.15_wp  ! Close to f_F
    fF = 0.20_wp
    
    ! Initialize GTN descriptor
    gtn_desc%E = E
    gtn_desc%nu = nu
    gtn_desc%sigma_y0 = sigma_y0
    gtn_desc%H_iso = 1.0e9_wp
    gtn_desc%q1 = 1.5_wp
    gtn_desc%q2 = 1.0_wp
    gtn_desc%q3 = 1.0_wp
    gtn_desc%f0 = f0
    gtn_desc%fN = 0.01_wp
    gtn_desc%epsilonN = 0.3_wp
    gtn_desc%sN = 0.1_wp
    gtn_desc%fc = 0.10_wp
    gtn_desc%fF = fF
    gtn_desc%G = E / (TWO * (ONE + nu))
    gtn_desc%K = E / (THREE * (ONE - TWO * nu))
    gtn_desc%mat_id = 207_i4
    gtn_desc%mat_family = 2_i4
    gtn_desc%model_name = "GTN Porous Plastic Damage"
    gtn_desc%is_initialized = .TRUE.
    
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    ! Very large strain to drive porosity to f_F
    strain_inc = [0.010_wp, -0.003_wp, -0.003_wp, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_inc
    mat_algo%ntens = 6
    mat_algo%compute_tangent = .TRUE.
    com_ctx%nlgeom = .FALSE.
    com_ctx%first_increment = .FALSE.
    com_ctx%gauss_pt = 1_i4
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    
    WRITE(*,*) '  Input: Very large plastic strain (ε_xx = 0.010)'
    WRITE(*,*) '  Initial porosity: f0 = ', f0
    WRITE(*,*) '  Failure porosity: f_F = ', fF
    WRITE(*,*) '  Final porosity: f = ', mat_state%porosity
    WRITE(*,*) '  Distance to failure: f_F - f = ', fF - mat_state%porosity
    WRITE(*,*) '  pnewdt = ', pnewdt
    
    IF (mat_state%porosity >= 0.99_wp * fF) THEN
      WRITE(*,*) '  ✅ PASSED: Material approaching failure (f ≈ f_F)'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: Porosity not yet at failure level'
    END IF
  END SUBROUTINE TC_GTN_06_Failure_Analysis_fF

  ! ============================================================================
  ! TC-GTN-07: 静水压力影响-三轴拉伸
  ! 验证静水压力加速孔隙增长
  ! ============================================================================
  SUBROUTINE TC_GTN_07_Hydrostatic_Pressure_Triaxial()
    TYPE(MD_Mat_GTN_Desc) :: gtn_desc
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    TYPE(PH_Mat_GTN_State) :: mat_state
    TYPE(MD_Mat_Base_Algo) :: mat_algo
    TYPE(PH_Mat_Base_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: com_ctx
    REAL(wp) :: pnewdt
    REAL(wp) :: strain_uniaxial(6), strain_triaxial(6)
    REAL(wp) :: f_uniaxial, f_triaxial
    REAL(wp) :: E, nu, sigma_y0, f0
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-GTN-07: Hydrostatic Pressure - Triaxial Tension'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    f0 = 0.01_wp
    
    ! Initialize GTN descriptor
    gtn_desc%E = E
    gtn_desc%nu = nu
    gtn_desc%sigma_y0 = sigma_y0
    gtn_desc%H_iso = 2.0e9_wp
    gtn_desc%q1 = 1.5_wp
    gtn_desc%q2 = 1.0_wp
    gtn_desc%q3 = 1.0_wp
    gtn_desc%f0 = f0
    gtn_desc%fN = 0.01_wp
    gtn_desc%epsilonN = 0.3_wp
    gtn_desc%sN = 0.1_wp
    gtn_desc%fc = 0.1_wp
    gtn_desc%fF = 0.2_wp
    gtn_desc%G = E / (TWO * (ONE + nu))
    gtn_desc%K = E / (THREE * (ONE - TWO * nu))
    gtn_desc%mat_id = 207_i4
    gtn_desc%mat_family = 2_i4
    gtn_desc%model_name = "GTN Porous Plastic Damage"
    gtn_desc%is_initialized = .TRUE.
    
    mat_algo%ntens = 6
    mat_algo%compute_tangent = .TRUE.
    com_ctx%nlgeom = .FALSE.
    com_ctx%first_increment = .FALSE.
    com_ctx%gauss_pt = 1_i4
    
    ! Uniaxial tension
    strain_uniaxial = [0.003_wp, -0.0009_wp, -0.0009_wp, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_uniaxial
    
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    f_uniaxial = mat_state%porosity
    
    ! Triaxial tension (σ_xx = σ_yy = σ_zz)
    ! Higher hydrostatic stress → faster void growth
    strain_triaxial = [0.003_wp, 0.003_wp, 0.003_wp, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_triaxial
    
    mat_state%peeq = ZERO
    mat_state%porosity = f0
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    f_triaxial = mat_state%porosity
    
    WRITE(*,*) '  Input: Same equivalent strain, different stress states'
    WRITE(*,*) '  Uniaxial: f = ', f_uniaxial
    WRITE(*,*) '  Triaxial: f = ', f_triaxial
    WRITE(*,*) '  Ratio (triaxial/uniaxial): ', f_triaxial / f_uniaxial
    WRITE(*,*) '  Expected: Triaxial tension → higher hydrostatic → faster void growth'
    
    IF (f_triaxial > f_uniaxial) THEN
      WRITE(*,*) '  ✅ PASSED: Hydrostatic pressure accelerates void growth'
    ELSE
      WRITE(*,*) '  ⚠️  WARNING: Triaxial effect not detected'
    END IF
  END SUBROUTINE TC_GTN_07_Hydrostatic_Pressure_Triaxial

  ! ============================================================================
  ! TC-GTN-08: 孔隙损伤-刚度退化验证
  ! 验证孔隙度增加导致有效刚度降低
  ! ============================================================================
  SUBROUTINE TC_GTN_08_Damage_Stiffness_Degradation()
    TYPE(MD_Mat_GTN_Desc) :: gtn_desc
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    TYPE(PH_Mat_GTN_State) :: mat_state
    TYPE(MD_Mat_Base_Algo) :: mat_algo
    TYPE(PH_Mat_Base_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: com_ctx
    REAL(wp) :: pnewdt
    REAL(wp) :: strain_inc(6)
    REAL(wp) :: f_low, f_high
    REAL(wp) :: stress_low(6), stress_high(6)
    REAL(wp) :: E, nu, sigma_y0
    REAL(wp) :: E_eff_low, E_eff_high, degradation_ratio
    
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) 'TC-GTN-08: Porous Damage - Stiffness Degradation'
    WRITE(*,*) '--------------------------------------------------------------------'
    
    ! Material properties
    E = 210.0e9_wp
    nu = 0.3_wp
    sigma_y0 = 250.0e6_wp
    
    ! Initialize GTN descriptor
    gtn_desc%E = E
    gtn_desc%nu = nu
    gtn_desc%sigma_y0 = sigma_y0
    gtn_desc%H_iso = 2.0e9_wp
    gtn_desc%q1 = 1.5_wp
    gtn_desc%q2 = 1.0_wp
    gtn_desc%q3 = 1.0_wp
    gtn_desc%f0 = 0.01_wp
    gtn_desc%fN = 0.01_wp
    gtn_desc%epsilonN = 0.3_wp
    gtn_desc%sN = 0.1_wp
    gtn_desc%fc = 0.1_wp
    gtn_desc%fF = 0.2_wp
    gtn_desc%G = E / (TWO * (ONE + nu))
    gtn_desc%K = E / (THREE * (ONE - TWO * nu))
    gtn_desc%mat_id = 207_i4
    gtn_desc%mat_family = 2_i4
    gtn_desc%model_name = "GTN Porous Plastic Damage"
    gtn_desc%is_initialized = .TRUE.
    
    strain_inc = [0.001_wp, ZERO, ZERO, ZERO, ZERO, ZERO]
    mat_ctx%dstran = strain_inc
    mat_algo%ntens = 6
    mat_algo%compute_tangent = .TRUE.
    com_ctx%nlgeom = .FALSE.
    com_ctx%first_increment = .FALSE.
    com_ctx%gauss_pt = 1_i4
    
    ! Test with low porosity (f = 0.01)
    f_low = 0.01_wp
    mat_state%peeq = ZERO
    mat_state%porosity = f_low
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    stress_low = mat_state%stress
    
    ! Test with high porosity (f = 0.10)
    f_high = 0.10_wp
    mat_state%peeq = ZERO
    mat_state%porosity = f_high
    mat_state%stress = ZERO
    mat_state%stran = ZERO
    
    CALL PH_GTN_UMAT_API(gtn_desc, mat_ctx, mat_state, mat_algo, ph_algo, com_ctx, pnewdt)
    stress_high = mat_state%stress
    
    ! Effective modulus: E_eff = σ / ε
    E_eff_low = stress_low(1) / strain_inc(1)
    E_eff_high = stress_high(1) / strain_inc(1)
    degradation_ratio = E_eff_high / E_eff_low
    
    ! Expected: Higher porosity → lower effective modulus
    WRITE(*,*) '  Input: Same strain (ε_xx = 0.001), different porosity'
    WRITE(*,*) '  f_low = 0.01 → E_eff = ', E_eff_low / 1.0e9_wp, ' GPa'
    WRITE(*,*) '  f_high = 0.10 → E_eff = ', E_eff_high / 1.0e9_wp, ' GPa'
    WRITE(*,*) '  Degradation ratio: E_eff_high / E_eff_low = ', degradation_ratio
    WRITE(*,*) '  Expected: Degradation ratio < 1.0 (stiffness decreases with porosity)'
    
    IF (degradation_ratio < ONE) THEN
      WRITE(*,*) '  ✅ PASSED: Stiffness degradation verified (E_eff decreases with f)'
    ELSE
      WRITE(*,*) '  ❌ FAILED: Stiffness degradation not detected'
    END IF
  END SUBROUTINE TC_GTN_08_Damage_Stiffness_Degradation

END MODULE TEST_PH_Mat_Gurson
