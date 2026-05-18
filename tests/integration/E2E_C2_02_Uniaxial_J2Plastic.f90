!===============================================================================
! E2E Test: C2-02 Uniaxial J2 Plasticity with Radial Return
! Layer:  Integration (L3->L4->L5 cross-layer)
! Domain: Material_Plastic + NonlinearIteration + WriteBack
!
! Scenario:
!   - Single integration point (material point test)
!   - Uniaxial tension with incremental strain loading
!   - J2 plasticity with linear isotropic hardening
!
! Material:
!   - E = 200000 MPa, nu = 0.3
!   - sigma_y = 250 MPa (initial yield stress)
!   - H = 1000 MPa (linear hardening modulus)
!
! Loading:
!   - Incremental uniaxial strain: eps = [0.001, 0.002, 0.003, 0.005]
!   - eps_yield = sigma_y / E = 0.00125
!   - Steps 1-2: elastic; Steps 3-4: plastic
!
! Verification:
!   - Elastic: sigma = E * eps
!   - Plastic: radial return to yield surface
!   - Hardening: sigma_eq = sigma_y + H * eps_p
!
! Note: Self-contained. J2 radial return algorithm is inlined.
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
program E2E_C2_02_Uniaxial_J2Plastic
  implicit none

  ! -- Precision
  integer, parameter :: wp = selected_real_kind(15, 307)
  integer, parameter :: i4 = selected_int_kind(9)

  ! -- Material parameters
  real(wp), parameter :: E_mod    = 200000.0_wp   ! Young's modulus [MPa]
  real(wp), parameter :: nu_mat   = 0.3_wp        ! Poisson's ratio
  real(wp), parameter :: sigma_y  = 250.0_wp      ! Initial yield stress [MPa]
  real(wp), parameter :: H_mod    = 1000.0_wp     ! Linear hardening modulus [MPa]

  ! -- Derived constants
  real(wp), parameter :: G_mod = E_mod / (2.0_wp * (1.0_wp + nu_mat))   ! Shear modulus
  real(wp), parameter :: K_bulk = E_mod / (3.0_wp * (1.0_wp - 2.0_wp * nu_mat))  ! Bulk modulus

  ! -- Loading: total strains at each step (uniaxial, eps_11 only)
  integer(i4), parameter :: n_steps = 4
  real(wp) :: eps_total(n_steps)

  ! -- State variables
  real(wp) :: stress(6)        ! Cauchy stress (Voigt: 11,22,33,12,23,13)
  real(wp) :: eps_p_vec(6)     ! Plastic strain (Voigt)
  real(wp) :: eps_p_eq         ! Equivalent plastic strain
  real(wp) :: strain(6)        ! Total strain
  real(wp) :: d_strain(6)      ! Strain increment

  ! -- Previous state
  real(wp) :: stress_prev(6)
  real(wp) :: eps_p_vec_prev(6)
  real(wp) :: eps_p_eq_prev
  real(wp) :: strain_prev(6)

  ! -- Verification
  real(wp) :: sigma_expected, sigma_got, sigma_eq_vm
  real(wp) :: yield_stress_current, err_pct
  real(wp) :: eps_yield
  logical  :: check_ok

  ! -- Counters
  integer(i4) :: istep, n_checks, n_pass, n_fail

  n_checks = 0
  n_pass   = 0
  n_fail   = 0

  eps_total(1) = 0.001_wp
  eps_total(2) = 0.002_wp
  eps_total(3) = 0.003_wp
  eps_total(4) = 0.005_wp

  eps_yield = sigma_y / E_mod   ! = 0.00125

  print '(A)', '=== E2E Test C2-02: Uniaxial_J2Plastic ==='
  print '(A)', ''

  !============================================================================
  ! Initialize state
  !============================================================================
  stress       = 0.0_wp
  eps_p_vec    = 0.0_wp
  eps_p_eq     = 0.0_wp
  strain       = 0.0_wp

  !============================================================================
  ! Main loading loop
  !============================================================================
  do istep = 1, n_steps

    print '(A,I0,A,F8.5)', '[Step ', istep, '] Total strain eps_11 = ', eps_total(istep)

    ! Save previous state
    stress_prev    = stress
    eps_p_vec_prev = eps_p_vec
    eps_p_eq_prev  = eps_p_eq
    strain_prev    = strain

    ! Current total strain (uniaxial: eps_22 = eps_33 = -nu*eps_11 for elastic,
    ! but for simplicity in material point test, impose full strain vector)
    strain = 0.0_wp
    strain(1) = eps_total(istep)       ! eps_11
    strain(2) = -nu_mat * eps_total(istep)  ! eps_22 (lateral)
    strain(3) = -nu_mat * eps_total(istep)  ! eps_33

    ! Strain increment
    d_strain = strain - strain_prev

    ! L4: J2 radial return (PH_Mat_J2_RadialReturn equivalent)
    call j2_radial_return(d_strain, stress_prev, eps_p_vec_prev, eps_p_eq_prev, &
                          E_mod, nu_mat, G_mod, K_bulk, sigma_y, H_mod,         &
                          stress, eps_p_vec, eps_p_eq)

    ! Compute von Mises equivalent stress
    sigma_eq_vm = compute_von_mises(stress)

    print '(A,F12.4,A,F12.6)', '  sigma_11 = ', stress(1), '  eps_p_eq = ', eps_p_eq

    ! ---- Verification per step ----
    if (eps_total(istep) <= eps_yield) then
      ! ELASTIC step: sigma_11 should = E * eps_11
      sigma_expected = E_mod * eps_total(istep)
      sigma_got      = stress(1)
      err_pct = abs(sigma_got - sigma_expected) / abs(sigma_expected) * 100.0_wp

      n_checks = n_checks + 1
      check_ok = (err_pct < 0.1_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F10.2,A,F10.2,A,F6.3,A,A)', &
        'Check ', n_checks, ': Elastic sigma_11 ... expected=', sigma_expected, &
        ' got=', sigma_got, ' err=', err_pct, '% ... ', &
        merge('PASS', 'FAIL', check_ok)

      ! Plastic strain should be zero
      n_checks = n_checks + 1
      check_ok = (eps_p_eq < 1.0e-12_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,ES10.3,A,A)', &
        'Check ', n_checks, ': No plastic strain ... eps_p_eq=', eps_p_eq, &
        ' ... ', merge('PASS', 'FAIL', check_ok)

    else
      ! PLASTIC step: stress should be on yield surface
      yield_stress_current = sigma_y + H_mod * eps_p_eq

      ! Von Mises stress should equal current yield stress
      err_pct = abs(sigma_eq_vm - yield_stress_current) / yield_stress_current * 100.0_wp

      n_checks = n_checks + 1
      check_ok = (err_pct < 1.0_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,F10.3,A,F10.3,A,F6.3,A,A)', &
        'Check ', n_checks, ': Yield surface ... sigma_vm=', sigma_eq_vm, &
        ' sigma_y_cur=', yield_stress_current, ' err=', err_pct, '% ... ', &
        merge('PASS', 'FAIL', check_ok)

      ! Plastic strain should be positive
      n_checks = n_checks + 1
      check_ok = (eps_p_eq > 0.0_wp)
      if (check_ok) then
        n_pass = n_pass + 1
      else
        n_fail = n_fail + 1
      end if
      print '(A,I0,A,ES12.5,A,A)', &
        'Check ', n_checks, ': Plastic strain > 0 ... eps_p=', eps_p_eq, &
        ' ... ', merge('PASS', 'FAIL', check_ok)
    end if
  end do

  !============================================================================
  ! Additional global checks
  !============================================================================
  print '(A)', ''
  print '(A)', '--- Global Checks ---'

  ! Check: Final equivalent plastic strain should be consistent
  ! Total strain at step 4: 0.005, elastic strain ~ sigma_y_final/E
  ! eps_p_eq should be > 0 and < total strain
  n_checks = n_checks + 1
  check_ok = (eps_p_eq > 0.0_wp .and. eps_p_eq < eps_total(n_steps))
  if (check_ok) then
    n_pass = n_pass + 1
  else
    n_fail = n_fail + 1
  end if
  print '(A,I0,A,F10.6,A,A)', &
    'Check ', n_checks, ': 0 < eps_p_eq < eps_total ... eps_p=', eps_p_eq, &
    ' ... ', merge('PASS', 'FAIL', check_ok)

  ! Check: Stress monotonically increased (hardening)
  n_checks = n_checks + 1
  check_ok = (stress(1) > sigma_y)
  if (check_ok) then
    n_pass = n_pass + 1
  else
    n_fail = n_fail + 1
  end if
  print '(A,I0,A,F10.2,A,F10.2,A,A)', &
    'Check ', n_checks, ': Hardening sigma > sigma_y ... sigma=', stress(1), &
    ' sigma_y=', sigma_y, ' ... ', merge('PASS', 'FAIL', check_ok)

  !============================================================================
  ! SUMMARY
  !============================================================================
  print '(A)', ''
  if (n_fail == 0) then
    print '(A,I0,A,I0,A)', '=== RESULT: PASS (', n_pass, '/', n_checks, ' checks passed) ==='
  else
    print '(A,I0,A,I0,A)', '=== RESULT: FAIL (', n_pass, '/', n_checks, ' checks passed) ==='
  end if

contains

  !============================================================================
  ! J2 Radial Return Algorithm (PH_Mat_J2_RadialReturn equivalent)
  !
  ! Implements: elastic predictor -> plastic corrector with linear hardening
  !============================================================================
  subroutine j2_radial_return(d_eps, sig_n, ep_n, ep_eq_n, &
                               Emod, nu, G, Kb, sy, Hmod,  &
                               sig_np1, ep_np1, ep_eq_np1)
    real(wp), intent(in)  :: d_eps(6)       ! Strain increment
    real(wp), intent(in)  :: sig_n(6)       ! Stress at step n
    real(wp), intent(in)  :: ep_n(6)        ! Plastic strain at step n
    real(wp), intent(in)  :: ep_eq_n        ! Equiv plastic strain at step n
    real(wp), intent(in)  :: Emod, nu, G, Kb, sy, Hmod
    real(wp), intent(out) :: sig_np1(6)     ! Stress at step n+1
    real(wp), intent(out) :: ep_np1(6)      ! Plastic strain at step n+1
    real(wp), intent(out) :: ep_eq_np1      ! Equiv plastic strain at step n+1

    real(wp) :: sig_trial(6)     ! Trial stress
    real(wp) :: s_trial(6)       ! Trial deviatoric stress
    real(wp) :: p_trial          ! Trial pressure
    real(wp) :: J2_trial         ! J2 invariant of trial deviatoric stress
    real(wp) :: sigma_vm_trial   ! Trial von Mises stress
    real(wp) :: f_trial          ! Yield function value
    real(wp) :: d_gamma          ! Plastic multiplier increment
    real(wp) :: norm_s           ! Norm of deviatoric stress
    real(wp) :: lam, mu2
    integer(i4) :: ii

    ! Lame parameters
    lam = Emod * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu2 = 2.0_wp * G

    ! -- Step 1: Elastic predictor (trial stress)
    ! sig_trial = sig_n + C : d_eps
    ! For isotropic: sig_trial_ij = sig_n_ij + lam*tr(d_eps)*delta_ij + 2*G*d_eps_ij
    p_trial = (d_eps(1) + d_eps(2) + d_eps(3))  ! trace of strain increment

    sig_trial(1) = sig_n(1) + lam * p_trial + mu2 * d_eps(1)
    sig_trial(2) = sig_n(2) + lam * p_trial + mu2 * d_eps(2)
    sig_trial(3) = sig_n(3) + lam * p_trial + mu2 * d_eps(3)
    sig_trial(4) = sig_n(4) + mu2 * d_eps(4)   ! shear (engineering -> tensor: /2 already in Voigt)
    sig_trial(5) = sig_n(5) + mu2 * d_eps(5)
    sig_trial(6) = sig_n(6) + mu2 * d_eps(6)

    ! -- Step 2: Compute trial deviatoric stress
    p_trial = (sig_trial(1) + sig_trial(2) + sig_trial(3)) / 3.0_wp

    s_trial(1) = sig_trial(1) - p_trial
    s_trial(2) = sig_trial(2) - p_trial
    s_trial(3) = sig_trial(3) - p_trial
    s_trial(4) = sig_trial(4)
    s_trial(5) = sig_trial(5)
    s_trial(6) = sig_trial(6)

    ! -- Step 3: Compute J2 and von Mises
    J2_trial = 0.5_wp * (s_trial(1)**2 + s_trial(2)**2 + s_trial(3)**2) &
             + s_trial(4)**2 + s_trial(5)**2 + s_trial(6)**2

    sigma_vm_trial = sqrt(3.0_wp * J2_trial)

    ! -- Step 4: Check yield criterion
    f_trial = sigma_vm_trial - (sy + Hmod * ep_eq_n)

    if (f_trial <= 0.0_wp) then
      ! Elastic step - accept trial stress
      sig_np1   = sig_trial
      ep_np1    = ep_n
      ep_eq_np1 = ep_eq_n
    else
      ! -- Step 5: Plastic corrector (radial return)
      ! d_gamma = f_trial / (3*G + H)
      d_gamma = f_trial / (3.0_wp * G + Hmod)

      ! Update equivalent plastic strain
      ep_eq_np1 = ep_eq_n + d_gamma

      ! Return direction: n = s_trial / ||s_trial||
      norm_s = sqrt(2.0_wp * J2_trial)

      ! Update stress: sig = p*I + s_trial * (1 - 3*G*d_gamma / sigma_vm_trial)
      ! which is: deviatoric part scaled back to yield surface
      do ii = 1, 3
        sig_np1(ii) = p_trial + s_trial(ii) * (1.0_wp - 3.0_wp*G*d_gamma / sigma_vm_trial)
      end do
      do ii = 4, 6
        sig_np1(ii) = s_trial(ii) * (1.0_wp - 3.0_wp*G*d_gamma / sigma_vm_trial)
      end do

      ! Update plastic strain
      if (norm_s > 1.0e-30_wp) then
        do ii = 1, 6
          ep_np1(ii) = ep_n(ii) + d_gamma * 1.5_wp * s_trial(ii) / sigma_vm_trial
        end do
      else
        ep_np1 = ep_n
      end if
    end if

  end subroutine j2_radial_return

  !============================================================================
  ! Compute von Mises equivalent stress from stress vector (Voigt)
  !============================================================================
  function compute_von_mises(sig) result(vm)
    real(wp), intent(in) :: sig(6)
    real(wp) :: vm
    real(wp) :: s(6), p

    p = (sig(1) + sig(2) + sig(3)) / 3.0_wp
    s(1) = sig(1) - p
    s(2) = sig(2) - p
    s(3) = sig(3) - p
    s(4) = sig(4)
    s(5) = sig(5)
    s(6) = sig(6)

    vm = sqrt(1.5_wp * (s(1)**2 + s(2)**2 + s(3)**2) &
        + 3.0_wp * (s(4)**2 + s(5)**2 + s(6)**2))
  end function compute_von_mises

end program E2E_C2_02_Uniaxial_J2Plastic
