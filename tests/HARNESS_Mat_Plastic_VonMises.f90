!===============================================================================
! Module: HARNESS_Mat_Plastic_VonMises
! Layer:  L4_PH - Physics Layer (Harness)
! Domain: Material
! Purpose: Harness acceptance test — Von Mises J2 plasticity with isotropic
!          hardening. Self-contained radial return mapping verification.
!
! Theory:
!   Yield function: f = sqrt(3*J2) - sigma_y = 0
!   J2 = 0.5 * s_ij * s_ij  (s = deviatoric stress)
!   Radial return: sigma_trial = D_e * eps_total
!     if f_trial > 0 => plastic correction via radial return
!     sigma = sigma_trial - 2*mu*d_gamma * n_hat
!     d_gamma = (f_trial) / (3*mu + H')
!   Equivalent plastic strain: eps_p_eq += d_gamma
!
! Parameters: E = 200 GPa, nu = 0.3, sigma_y = 250 MPa, H' = 0
!             Applied strain eps_11 = 0.002 (exceeds yield at ~0.00125)
!
! Status: Harness | Created: 2026-04-28
!===============================================================================
MODULE HARNESS_Mat_Plastic_VonMises
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Harness_Mat_Plastic_VonMises

  REAL(wp), PARAMETER :: TOL = 1.0e-8_wp

CONTAINS

  SUBROUTINE Run_Harness_Mat_Plastic_VonMises()
    REAL(wp) :: E, nu, sigma_y, H_prime
    REAL(wp) :: lambda, mu, K_bulk
    REAL(wp) :: eps(6), sigma_trial(6), s_trial(6)
    REAL(wp) :: sigma_m, J2_trial, q_trial, f_trial
    REAL(wp) :: d_gamma, sigma_final(6), s_final(6)
    REAL(wp) :: eps_p_eq, q_final
    INTEGER(i4) :: i, n_pass, n_fail

    n_pass = 0
    n_fail = 0

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'HARNESS_Mat_Plastic_VonMises: J2 Plasticity — Radial Return'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    ! ---------------------------------------------------------------
    ! Material parameters
    ! ---------------------------------------------------------------
    E       = 200.0e9_wp    ! Young's modulus [Pa]
    nu      = 0.3_wp        ! Poisson's ratio
    sigma_y = 250.0e6_wp    ! Initial yield stress [Pa]
    H_prime = 0.0_wp        ! Hardening modulus (perfect plasticity)

    lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu     = E / (2.0_wp * (1.0_wp + nu))
    K_bulk = E / (3.0_wp * (1.0_wp - 2.0_wp * nu))

    ! ---------------------------------------------------------------
    ! Strain: eps_11 = 0.002 (beyond yield)
    ! Yield strain (uniaxial) = sigma_y / E = 250e6/200e9 = 0.00125
    ! ---------------------------------------------------------------
    eps    = 0.0_wp
    eps(1) = 0.002_wp

    ! ---------------------------------------------------------------
    ! Step 1: Elastic trial stress  sigma_trial = D_e * eps
    ! ---------------------------------------------------------------
    sigma_trial = 0.0_wp
    sigma_trial(1) = (lambda + 2.0_wp * mu) * eps(1)
    sigma_trial(2) = lambda * eps(1)
    sigma_trial(3) = lambda * eps(1)
    ! shear components = 0

    ! Hydrostatic (mean) stress
    sigma_m = (sigma_trial(1) + sigma_trial(2) + sigma_trial(3)) / 3.0_wp

    ! Deviatoric trial stress
    s_trial = sigma_trial
    s_trial(1) = s_trial(1) - sigma_m
    s_trial(2) = s_trial(2) - sigma_m
    s_trial(3) = s_trial(3) - sigma_m

    ! J2 = 0.5 * s_ij * s_ij  (Voigt: normal^2 + 2*shear^2)
    J2_trial = 0.5_wp * (s_trial(1)**2 + s_trial(2)**2 + s_trial(3)**2) + &
               s_trial(4)**2 + s_trial(5)**2 + s_trial(6)**2
    q_trial = SQRT(3.0_wp * J2_trial)   ! Von Mises equivalent stress

    ! Yield function
    f_trial = q_trial - sigma_y

    ! ---------------------------------------------------------------
    ! TC-1: Verify trial stress exceeds yield (f_trial > 0)
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-1: Verify elastic trial exceeds yield'
    WRITE(*,*) '    q_trial  = ', q_trial / 1.0e6_wp, ' MPa'
    WRITE(*,*) '    sigma_y  = ', sigma_y / 1.0e6_wp, ' MPa'
    WRITE(*,*) '    f_trial  = ', f_trial / 1.0e6_wp, ' MPa'

    IF (f_trial > 0.0_wp) THEN
      WRITE(*,*) '    >> PASS (f_trial > 0, plastic)'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL (should be plastic)'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! Step 2: Radial return (perfect plasticity H'=0)
    !   d_gamma = f_trial / (3*mu)   [when H'=0]
    !   s_final = s_trial * (1 - 3*mu*d_gamma / q_trial)
    !           = s_trial * sigma_y / q_trial
    ! ---------------------------------------------------------------
    d_gamma = f_trial / (3.0_wp * mu)

    DO i = 1, 6
      s_final(i) = s_trial(i) * sigma_y / q_trial
    END DO

    ! Final stress = deviatoric + hydrostatic (hydrostatic unchanged)
    sigma_final = s_final
    sigma_final(1) = sigma_final(1) + sigma_m
    sigma_final(2) = sigma_final(2) + sigma_m
    sigma_final(3) = sigma_final(3) + sigma_m

    ! Equivalent plastic strain increment
    eps_p_eq = d_gamma

    ! ---------------------------------------------------------------
    ! TC-2: Verify returned stress lies on yield surface (q = sigma_y)
    ! ---------------------------------------------------------------
    q_final = SQRT(3.0_wp * (0.5_wp * (s_final(1)**2 + s_final(2)**2 + &
              s_final(3)**2) + s_final(4)**2 + s_final(5)**2 + s_final(6)**2))

    WRITE(*,*) '  TC-2: Verify returned q = sigma_y'
    WRITE(*,*) '    q_final  = ', q_final / 1.0e6_wp, ' MPa'
    WRITE(*,*) '    sigma_y  = ', sigma_y / 1.0e6_wp, ' MPa'

    IF (ABS(q_final - sigma_y) / sigma_y < 1.0e-10_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL (relative error = ', ABS(q_final - sigma_y)/sigma_y, ')'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-3: Verify equivalent plastic strain > 0
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-3: Verify eps_p_eq > 0'
    WRITE(*,*) '    d_gamma  = ', d_gamma
    WRITE(*,*) '    eps_p_eq = ', eps_p_eq

    IF (eps_p_eq > 0.0_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-4: Verify plastic volume preservation (tr(eps_p) = 0)
    !   d_eps_p = d_gamma * n_hat,  n_hat = s/q  =>  tr(n_hat) = 0
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-4: Verify plastic incompressibility (tr(s_final) = 0)'

    IF (ABS(s_final(1) + s_final(2) + s_final(3)) < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL (tr(s) = ', s_final(1)+s_final(2)+s_final(3), ')'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-5: Verify hydrostatic stress unchanged by plasticity
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-5: Verify hydrostatic stress preserved'
    WRITE(*,*) '    sigma_m (trial)  = ', sigma_m / 1.0e6_wp, ' MPa'
    WRITE(*,*) '    sigma_m (final)  = ', (sigma_final(1)+sigma_final(2)+sigma_final(3))/3.0_wp / 1.0e6_wp, ' MPa'

    IF (ABS((sigma_final(1)+sigma_final(2)+sigma_final(3))/3.0_wp - sigma_m) < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! Summary
    ! ---------------------------------------------------------------
    WRITE(*,*) ''
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) '  HARNESS_Mat_Plastic_VonMises: ', n_pass, ' PASSED, ', n_fail, ' FAILED'
    IF (n_fail == 0) THEN
      WRITE(*,*) '  >> ALL PASS'
    ELSE
      WRITE(*,*) '  >> SOME FAILURES'
    END IF
    WRITE(*,*) '===================================================================='

  END SUBROUTINE Run_Harness_Mat_Plastic_VonMises

END MODULE HARNESS_Mat_Plastic_VonMises

!===============================================================================
! Runner
!===============================================================================
PROGRAM HARNESS_Mat_Plastic_VonMises_Runner
  USE HARNESS_Mat_Plastic_VonMises, ONLY: Run_Harness_Mat_Plastic_VonMises
  IMPLICIT NONE
  CALL Run_Harness_Mat_Plastic_VonMises()
END PROGRAM HARNESS_Mat_Plastic_VonMises_Runner
