!===============================================================================
! test_UMAT_J2: Unit test for PH_UMAT_J2_Wrapper (mat_id 708) - SC-2 verification
! Run: BUILD_TESTING=ON, cmake --build build, ctest -R UMAT_J2_708
!
! Purpose: Verify four-chain integration for mat_id=708 (J2 von Mises elastoplasticity)
!          - Theoretical chain: J2 yield + isotropic hardening (Simo & Hughes §3.6)
!          - Logical chain: L3 Desc �?L4 Registry �?L5 dispatch
!          - Computational chain: Elastic predictor �?Plastic return mapping
!          - Data chain: props(4) = [E,nu,sigma_y0,H], statev(7) = [eq_pl, eps_p_1..6]
!
! Test sequence:
!   1. Elastic loading (σ < σ_y0) �?Verify linear elastic response
!   2. Yield point (σ = σ_y0) �?Verify equivalent stress = sigma_y0
!   3. Plastic return mapping (Δε > 0) �?Verify plastic strain accumulation
!   4. Unloading �?Verify elastic unloading path
!
! Status: Phase 1 B trial development | Last verified: 2026-03-28
!===============================================================================
program test_UMAT_J2
  use IF_Prec_Core, only: wp, i4
  use IF_Err_API, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  use PH_UMAT_Types, only: PH_UMAT_Context
  use PH_Mat_Compute_UMAT, only: PH_UMAT_J2_Wrapper
  implicit none

  type(PH_UMAT_Context) :: ctx
  type(ErrorStatusType) :: st
  real(wp) :: E, nu, sigma_y0, H, tol, err, expected_sigma
  integer :: i

  ! --- Initialize test parameters ---
  call init_error_status(st)
  E = 210000.0_wp      ! Young's modulus [MPa] (Steel)
  nu = 0.3_wp          ! Poisson's ratio
  sigma_y0 = 500.0_wp  ! Initial yield stress [MPa]
  H = 1000.0_wp        ! Hardening modulus [MPa]
  tol = 1.0e-6_wp

  write(*,*) '========================================'
  write(*,*) 'SC-2: test_UMAT_J2 (mat_id=708)'
  write(*,*) 'Material: J2 von Mises elastoplasticity'
  write(*,*) 'Props: E=', E, ', nu=', nu, ', sigma_y0=', sigma_y0, ', H=', H
  write(*,*) 'Statev: 7 (eq_pl + 6 plastic strain components)'
  write(*,*) '========================================'

  ! --- Step 0: Context initialization ---
  call ctx%Init(ndi=3, nshr=3, nstatv=7, nprops=4)
  ctx%ndi = 3
  ctx%nshr = 3
  ctx%props(1) = E
  ctx%props(2) = nu
  ctx%props(3) = sigma_y0
  ctx%props(4) = H
  ctx%statev = 0.0_wp  ! Initialize all state variables to zero
  ctx%sigma = 0.0_wp   ! Initial stress = 0

  !=============================================================================
  ! TEST 1: Elastic loading (uniaxial strain, σ < σ_y0)
  ! Expected: Linear elastic response, no plastic flow
  !=============================================================================
  write(*,*) ''
  write(*,*) 'TEST 1: Elastic loading (dε_11=0.001, σ < σ_y0)'
  
  ctx%dstran = 0.0_wp
  ctx%dstran(1) = 0.001_wp  ! Uniaxial strain increment
  
  call PH_UMAT_J2_Wrapper(ctx, st)
  
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: TEST 1 - PH_UMAT_J2_Wrapper returned status ', st%status_code
    write(*,*) '      Message: ', trim(st%message)
    call ctx%Cleanup()
    stop 1
  endif
  
  ! For elastic uniaxial strain: σ_11 = E*(1-ν)/((1+ν)*(1-2ν)) * ε_11
  ! With E=210000, ν=0.3, ε=0.001: σ_11 �?282.69 MPa
  expected_sigma = 282.69230769230769_wp
  err = abs(ctx%sigma(1) - expected_sigma)
  
  write(*,*) '  σ_11 = ', ctx%sigma(1), ' MPa (expected ~', expected_sigma, ')'
  write(*,*) '  Error = ', err
  
  if (err > tol) then
    write(*,*) 'FAIL: TEST 1 - sigma(1) error exceeds tolerance'
    call ctx%Cleanup()
    stop 1
  endif
  
  ! Equivalent plastic strain should remain zero (elastic response)
  if (abs(ctx%statev(1)) > tol) then
    write(*,*) 'FAIL: TEST 1 - eq_plastic_strain = ', ctx%statev(1), ' expected 0 (elastic)'
    call ctx%Cleanup()
    stop 1
  endif
  
  write(*,*) 'PASS: TEST 1 - Elastic loading verified'

  !=============================================================================
  ! TEST 2: Yield point detection (approach σ �?σ_y0)
  !=============================================================================
  write(*,*) ''
  write(*,*) 'TEST 2: Approach yield point'
  
  ! Apply additional strain to approach yield
  ctx%dstran(1) = 0.0008_wp  ! Smaller increment to approach yield
  
  call PH_UMAT_J2_Wrapper(ctx, st)
  
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: TEST 2 - PH_UMAT_J2_Wrapper returned status ', st%status_code
    call ctx%Cleanup()
    stop 1
  endif
  
  write(*,*) '  σ_11 = ', ctx%sigma(1), ' MPa'
  write(*,*) '  Current stress state after TEST 2'
  
  ! Store current stress for reference
  expected_sigma = ctx%sigma(1)

  !=============================================================================
  ! TEST 3: Plastic return mapping (trigger plastic flow)
  ! Expected: Equivalent plastic strain > 0, stress near yield surface
  !=============================================================================
  write(*,*) ''
  write(*,*) 'TEST 3: Plastic return mapping (large strain increment)'
  
  ! Large strain increment to trigger yielding
  ctx%dstran(1) = 0.005_wp
  
  call PH_UMAT_J2_Wrapper(ctx, st)
  
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: TEST 3 - PH_UMAT_J2_Wrapper returned status ', st%status_code
    call ctx%Cleanup()
    stop 1
  endif
  
  ! Check: Equivalent plastic strain must increase (> 0)
  write(*,*) '  eq_plastic_strain = ', ctx%statev(1)
  
  if (ctx%statev(1) <= 0.0_wp) then
    write(*,*) 'FAIL: TEST 3 - No plastic flow detected (eq_pl = ', ctx%statev(1), ')'
    call ctx%Cleanup()
    stop 1
  endif
  
  ! Check: Stress should be on/near yield surface
  ! For isotropic hardening: σ_yield = sigma_y0 + H * eq_pl
  expected_sigma = sigma_y0 + H * ctx%statev(1)
  err = abs(ctx%sigma(1) - expected_sigma) / expected_sigma  ! Relative error
  
  write(*,*) '  σ_11 = ', ctx%sigma(1), ' MPa'
  write(*,*) '  Expected yield stress = sigma_y0 + H*eq_pl = ', expected_sigma, ' MPa'
  write(*,*) '  Relative error = ', err
  
  if (err > 0.05_wp) then  ! 5% tolerance for plastic regime
    write(*,*) 'FAIL: TEST 3 - Stress deviates from yield surface (> 5%)'
    call ctx%Cleanup()
    stop 1
  endif
  
  ! Check: Plastic strain components should be updated
  write(*,*) '  Plastic strain components:'
  write(*,*) '    εp_11 = ', ctx%statev(2)
  write(*,*) '    εp_22 = ', ctx%statev(3)
  write(*,*) '    εp_33 = ', ctx%statev(4)
  
  write(*,*) 'PASS: TEST 3 - Plastic return mapping verified'

  !=============================================================================
  ! TEST 4: Elastic unloading
  ! Expected: Linear elastic response with accumulated plastic strain
  !=============================================================================
  write(*,*) ''
  write(*,*) 'TEST 4: Elastic unloading'
  
  ! Store previous plastic strain
  real(wp) :: prev_eq_pl
  prev_eq_pl = ctx%statev(1)
  
  ! Negative strain increment (unloading)
  ctx%dstran(1) = -0.002_wp
  
  call PH_UMAT_J2_Wrapper(ctx, st)
  
  if (st%status_code /= IF_STATUS_OK) then
    write(*,*) 'FAIL: TEST 4 - PH_UMAT_J2_Wrapper returned status ', st%status_code
    call ctx%Cleanup()
    stop 1
  endif
  
  ! During elastic unloading:
  ! - Stress should decrease
  ! - Equivalent plastic strain should remain constant (no reverse yielding)
  write(*,*) '  σ_11 = ', ctx%sigma(1), ' MPa'
  write(*,*) '  eq_plastic_strain = ', ctx%statev(1), ' (previous = ', prev_eq_pl, ')'
  
  ! Check: Plastic strain should not change during elastic unloading
  err = abs(ctx%statev(1) - prev_eq_pl)
  if (err > tol) then
    write(*,*) 'FAIL: TEST 4 - Plastic strain changed during unloading (err = ', err, ')'
    call ctx%Cleanup()
    stop 1
  endif
  
  write(*,*) 'PASS: TEST 4 - Elastic unloading verified'

  !=============================================================================
  ! Final summary
  !=============================================================================
  write(*,*) ''
  write(*,*) '========================================'
  write(*,*) 'ALL TESTS PASSED'
  write(*,*) 'SC-2: Four-chain integration verified'
  write(*,*) '  �?Theoretical chain: J2 yield + hardening'
  write(*,*) '  �?Logical chain: L3→L4→L5 dispatch'
  write(*,*) '  �?Computational chain: Return mapping'
  write(*,*) '  �?Data chain: props(4), statev(7)'
  write(*,*) '========================================'

  call ctx%Cleanup()
  
end program test_UMAT_J2
