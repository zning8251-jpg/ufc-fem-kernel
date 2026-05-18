!===============================================================================
! E2E Test: C2-02 Uniaxial J2 Plasticity with Radial Return (INTEGRATED VERSION)
! Layer:  Integration (L3->L4->L5 cross-layer)
! Domain: Material_Plastic + NonlinearIteration + WriteBack
!
! Integration Status: FULL
!   - USE PH_Mat_Plast_J2_Iso_Core: PH_J2_Props, PH_J2_State, PH_J2_ComputeStress
!     Module .mod file available in build_mod/
!   - USE IF_Prec_Core: wp, i4 (replaces local parameter definitions)
!   - USE IF_Err_Brg: ErrorStatusType for error handling
!
! Changes from self-contained version:
!   1. PH_J2_Props replaces inline material parameters
!   2. PH_J2_State replaces inline stress/strain_p/eps_p_eq arrays
!   3. PH_J2_ComputeStress replaces inline j2_radial_return subroutine
!   4. ErrorStatusType used for return status checking
!   5. compute_von_mises retained inline (utility, not in module public API)
!
! Original: E2E_C2_02_Uniaxial_J2Plastic.f90 (self-contained, PASS)
! Status: ACTIVE | Created: 2026-04-28 | Integrated: 2026-04-28
!===============================================================================
program E2E_C2_02_Uniaxial_J2Plastic_Integrated
  ! === INTEGRATED: USE actual UFC modules ===
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Plast_J2_Iso_Core, ONLY: PH_J2_Props, PH_J2_State, &
                                     PH_J2_ComputeStress, PH_J2_Init, &
                                     HARD_LINEAR
  implicit none

  ! -- Material parameters (will be set into PH_J2_Props)
  real(wp), parameter :: E_mod    = 200000.0_wp
  real(wp), parameter :: nu_mat   = 0.3_wp
  real(wp), parameter :: sigma_y  = 250.0_wp
  real(wp), parameter :: H_mod    = 1000.0_wp

  ! -- Derived constants (for verification)
  real(wp), parameter :: G_mod = E_mod / (2.0_wp * (1.0_wp + nu_mat))
  real(wp), parameter :: K_bulk = E_mod / (3.0_wp * (1.0_wp - 2.0_wp * nu_mat))

  ! -- Loading
  integer(i4), parameter :: n_steps = 4
  real(wp) :: eps_total(n_steps)

  ! === INTEGRATED: Module types replace inline state ===
  TYPE(PH_J2_Props) :: j2_props
  TYPE(PH_J2_State) :: j2_state
  TYPE(ErrorStatusType) :: ierr

  ! -- Strain tracking (not in module state)
  real(wp) :: strain(6), strain_prev(6), d_strain(6)
  real(wp) :: tangent(6,6)
  real(wp) :: pnewdt

  ! -- Verification
  real(wp) :: sigma_expected, sigma_got, sigma_eq_vm
  real(wp) :: yield_stress_current, err_pct
  real(wp) :: eps_yield
  logical  :: check_ok

  ! -- Counters
  integer(i4) :: istep, n_checks, n_pass, n_fail

  n_checks = 0; n_pass = 0; n_fail = 0

  eps_total(1) = 0.001_wp
  eps_total(2) = 0.002_wp
  eps_total(3) = 0.003_wp
  eps_total(4) = 0.005_wp

  eps_yield = sigma_y / E_mod

  print '(A)', '=== E2E Test C2-02: Uniaxial_J2Plastic [INTEGRATED] ==='
  print '(A)', '  Using: PH_Mat_Plast_J2_Iso_Core (PH_J2_ComputeStress)'
  print '(A)', ''

  ! === INTEGRATED: Initialize via module PH_J2_Init ===
  j2_props%elastic%E       = E_mod
  j2_props%elastic%nu      = nu_mat
  j2_props%yield%sigma_y0  = sigma_y
  j2_props%harden%H        = H_mod
  j2_props%ctrl%hardening_type = HARD_LINEAR

  CALL PH_J2_Init(j2_props, j2_state, ierr)
  IF (ierr%status_code /= IF_STATUS_OK) THEN
    print '(A)', 'ERROR: PH_J2_Init failed'
    STOP 1
  END IF

  strain = 0.0_wp
  pnewdt = 1.0_wp

  ! === Main loading loop ===
  do istep = 1, n_steps
    print '(A,I0,A,F8.5)', '[Step ', istep, '] Total strain eps_11 = ', eps_total(istep)

    strain_prev = strain

    ! Current total strain (uniaxial)
    strain = 0.0_wp
    strain(1) = eps_total(istep)
    strain(2) = -nu_mat * eps_total(istep)
    strain(3) = -nu_mat * eps_total(istep)

    d_strain = strain - strain_prev

    ! === INTEGRATED: Call module PH_J2_ComputeStress instead of inline ===
    pnewdt = 1.0_wp
    CALL PH_J2_ComputeStress(j2_props, d_strain, j2_state, tangent, pnewdt, ierr)

    IF (ierr%status_code /= IF_STATUS_OK) THEN
      print '(A,I0,A)', 'WARNING: PH_J2_ComputeStress returned error at step ', istep
    END IF

    ! === INTEGRATED: Read results from module state ===
    sigma_eq_vm = compute_von_mises(j2_state%stress%stress)

    print '(A,F12.4,A,F12.6)', '  sigma_11 = ', j2_state%stress%stress(1), &
      '  eps_p_eq = ', j2_state%plastic%eps_p_eq

    ! ---- Verification per step ----
    if (eps_total(istep) <= eps_yield) then
      ! ELASTIC step
      sigma_expected = E_mod * eps_total(istep)
      sigma_got      = j2_state%stress%stress(1)
      err_pct = abs(sigma_got - sigma_expected) / abs(sigma_expected) * 100.0_wp

      n_checks = n_checks + 1
      check_ok = (err_pct < 0.1_wp)
      if (check_ok) then; n_pass = n_pass + 1; else; n_fail = n_fail + 1; end if
      print '(A,I0,A,F10.2,A,F10.2,A,F6.3,A,A)', &
        'Check ', n_checks, ': Elastic sigma_11 ... expected=', sigma_expected, &
        ' got=', sigma_got, ' err=', err_pct, '% ... ', &
        merge('PASS', 'FAIL', check_ok)

      ! Plastic strain should be zero
      n_checks = n_checks + 1
      check_ok = (j2_state%plastic%eps_p_eq < 1.0e-12_wp)
      if (check_ok) then; n_pass = n_pass + 1; else; n_fail = n_fail + 1; end if
      print '(A,I0,A,ES10.3,A,A)', &
        'Check ', n_checks, ': No plastic strain ... eps_p_eq=', j2_state%plastic%eps_p_eq, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    else
      ! PLASTIC step
      yield_stress_current = sigma_y + H_mod * j2_state%plastic%eps_p_eq

      err_pct = abs(sigma_eq_vm - yield_stress_current) / yield_stress_current * 100.0_wp

      n_checks = n_checks + 1
      check_ok = (err_pct < 1.0_wp)
      if (check_ok) then; n_pass = n_pass + 1; else; n_fail = n_fail + 1; end if
      print '(A,I0,A,F10.3,A,F10.3,A,F6.3,A,A)', &
        'Check ', n_checks, ': Yield surface ... sigma_vm=', sigma_eq_vm, &
        ' sigma_y_cur=', yield_stress_current, ' err=', err_pct, '% ... ', &
        merge('PASS', 'FAIL', check_ok)

      ! Plastic strain should be positive
      n_checks = n_checks + 1
      check_ok = (j2_state%plastic%eps_p_eq > 0.0_wp)
      if (check_ok) then; n_pass = n_pass + 1; else; n_fail = n_fail + 1; end if
      print '(A,I0,A,ES12.5,A,A)', &
        'Check ', n_checks, ': Plastic strain > 0 ... eps_p=', j2_state%plastic%eps_p_eq, &
        ' ... ', merge('PASS', 'FAIL', check_ok)
    end if
  end do

  ! === Global checks ===
  print '(A)', ''
  print '(A)', '--- Global Checks ---'

  n_checks = n_checks + 1
  check_ok = (j2_state%plastic%eps_p_eq > 0.0_wp .and. j2_state%plastic%eps_p_eq < eps_total(n_steps))
  if (check_ok) then; n_pass = n_pass + 1; else; n_fail = n_fail + 1; end if
  print '(A,I0,A,F10.6,A,A)', &
    'Check ', n_checks, ': 0 < eps_p_eq < eps_total ... eps_p=', j2_state%plastic%eps_p_eq, &
    ' ... ', merge('PASS', 'FAIL', check_ok)

  n_checks = n_checks + 1
  check_ok = (j2_state%stress%stress(1) > sigma_y)
  if (check_ok) then; n_pass = n_pass + 1; else; n_fail = n_fail + 1; end if
  print '(A,I0,A,F10.2,A,F10.2,A,A)', &
    'Check ', n_checks, ': Hardening sigma > sigma_y ... sigma=', j2_state%stress%stress(1), &
    ' sigma_y=', sigma_y, ' ... ', merge('PASS', 'FAIL', check_ok)

  ! === SUMMARY ===
  print '(A)', ''
  if (n_fail == 0) then
    print '(A,I0,A,I0,A)', '=== RESULT: PASS (', n_pass, '/', n_checks, ' checks passed) ==='
  else
    print '(A,I0,A,I0,A)', '=== RESULT: FAIL (', n_pass, '/', n_checks, ' checks passed) ==='
  end if

contains

  ! Retained inline: Von Mises utility (not in module public API)
  function compute_von_mises(sig) result(vm)
    real(wp), intent(in) :: sig(6)
    real(wp) :: vm
    real(wp) :: s(6), p
    p = (sig(1) + sig(2) + sig(3)) / 3.0_wp
    s(1) = sig(1) - p; s(2) = sig(2) - p; s(3) = sig(3) - p
    s(4) = sig(4); s(5) = sig(5); s(6) = sig(6)
    vm = sqrt(1.5_wp * (s(1)**2 + s(2)**2 + s(3)**2) &
        + 3.0_wp * (s(4)**2 + s(5)**2 + s(6)**2))
  end function compute_von_mises

end program E2E_C2_02_Uniaxial_J2Plastic_Integrated
