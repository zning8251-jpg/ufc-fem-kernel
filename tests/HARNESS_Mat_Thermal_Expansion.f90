!===============================================================================
! Module: HARNESS_Mat_Thermal_Expansion
! Layer:  L4_PH - Physics Layer (Harness)
! Domain: Material
! Purpose: Harness acceptance test — isotropic thermal expansion.
!          Self-contained analytical verification.
!
! Theory:
!   Thermal strain (isotropic):
!     eps_th_ij = alpha * dT * delta_ij
!   For alpha = 1.2e-5 /K, dT = 100 K:
!     eps_th = 1.2e-3  (each normal component)
!     shear thermal strains = 0
!   If free expansion (no constraint):
!     sigma = 0   (zero stress)
!   If fully constrained:
!     sigma = -D * eps_th  (compressive thermal stress)
!
! Parameters: E=200 GPa, nu=0.3, alpha=1.2e-5 /K, dT=100 K
!
! Status: Harness | Created: 2026-04-28
!===============================================================================
MODULE HARNESS_Mat_Thermal_Expansion
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Harness_Mat_Thermal_Expansion

  REAL(wp), PARAMETER :: TOL = 1.0e-12_wp

CONTAINS

  SUBROUTINE Run_Harness_Mat_Thermal_Expansion()
    REAL(wp) :: E, nu, alpha, dT
    REAL(wp) :: lambda, mu
    REAL(wp) :: eps_th(6), eps_th_expected
    REAL(wp) :: sigma_constrained(6), sigma_expected
    REAL(wp) :: D(6,6)
    INTEGER(i4) :: i, j, n_pass, n_fail

    n_pass = 0
    n_fail = 0

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'HARNESS_Mat_Thermal_Expansion: Isotropic Thermal Expansion'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    ! ---------------------------------------------------------------
    ! Material and thermal parameters
    ! ---------------------------------------------------------------
    E     = 200.0e9_wp     ! Young's modulus  [Pa]
    nu    = 0.3_wp         ! Poisson's ratio
    alpha = 1.2e-5_wp      ! CTE [1/K]
    dT    = 100.0_wp       ! Temperature increment [K]

    lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu     = E / (2.0_wp * (1.0_wp + nu))

    ! ---------------------------------------------------------------
    ! Compute thermal strain: eps_th = alpha * dT (isotropic)
    ! ---------------------------------------------------------------
    eps_th = 0.0_wp
    eps_th(1) = alpha * dT   ! eps_11
    eps_th(2) = alpha * dT   ! eps_22
    eps_th(3) = alpha * dT   ! eps_33
    ! eps_12 = eps_13 = eps_23 = 0

    eps_th_expected = alpha * dT   ! = 1.2e-5 * 100 = 1.2e-3

    ! ---------------------------------------------------------------
    ! TC-1: Verify thermal strain magnitude eps_th = alpha * dT = 1.2e-3
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-1: Verify eps_th = alpha * dT'
    WRITE(*,*) '    alpha     = ', alpha, ' /K'
    WRITE(*,*) '    dT        = ', dT, ' K'
    WRITE(*,*) '    Expected  = ', eps_th_expected
    WRITE(*,*) '    Computed  = ', eps_th(1)

    IF (ABS(eps_th(1) - eps_th_expected) < TOL .AND. &
        ABS(eps_th(2) - eps_th_expected) < TOL .AND. &
        ABS(eps_th(3) - eps_th_expected) < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-2: Verify shear thermal strains = 0
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-2: Verify shear thermal strains = 0'

    IF (ABS(eps_th(4)) < TOL .AND. ABS(eps_th(5)) < TOL .AND. &
        ABS(eps_th(6)) < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-3: Verify isotropic expansion (all normal strains equal)
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-3: Verify isotropic (eps_11 = eps_22 = eps_33)'

    IF (ABS(eps_th(1) - eps_th(2)) < TOL .AND. &
        ABS(eps_th(2) - eps_th(3)) < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-4: Fully constrained thermal stress
    !   sigma = -D * eps_th  (mechanical strain = -eps_th)
    !   sigma_11 = -(lambda+2mu)*eps_th - lambda*eps_th - lambda*eps_th
    !            = -(lambda+2mu + 2*lambda) * eps_th
    !            = -(3*lambda + 2*mu) * eps_th
    !            = -E * eps_th / (1 - 2*nu)
    ! ---------------------------------------------------------------
    D = 0.0_wp
    D(1,1) = lambda + 2.0_wp * mu
    D(2,2) = lambda + 2.0_wp * mu
    D(3,3) = lambda + 2.0_wp * mu
    D(1,2) = lambda;  D(2,1) = lambda
    D(1,3) = lambda;  D(3,1) = lambda
    D(2,3) = lambda;  D(3,2) = lambda
    D(4,4) = mu;  D(5,5) = mu;  D(6,6) = mu

    ! sigma = -D * eps_th  (mechanical strain = -thermal strain)
    sigma_constrained = 0.0_wp
    DO i = 1, 6
      DO j = 1, 6
        sigma_constrained(i) = sigma_constrained(i) - D(i,j) * eps_th(j)
      END DO
    END DO

    sigma_expected = -E * eps_th_expected / (1.0_wp - 2.0_wp * nu)
    ! = -200e9 * 1.2e-3 / 0.4 = -600 MPa

    WRITE(*,*) '  TC-4: Verify fully constrained thermal stress'
    WRITE(*,*) '    Expected sigma_11 = ', sigma_expected / 1.0e6_wp, ' MPa'
    WRITE(*,*) '    Computed sigma_11 = ', sigma_constrained(1) / 1.0e6_wp, ' MPa'

    IF (ABS(sigma_constrained(1) - sigma_expected) / ABS(sigma_expected) < 1.0e-10_wp) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-5: Verify constrained shear stresses = 0
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-5: Verify constrained shear stress = 0'

    IF (ABS(sigma_constrained(4)) < TOL .AND. &
        ABS(sigma_constrained(5)) < TOL .AND. &
        ABS(sigma_constrained(6)) < TOL) THEN
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
    WRITE(*,*) '  HARNESS_Mat_Thermal_Expansion: ', n_pass, ' PASSED, ', n_fail, ' FAILED'
    IF (n_fail == 0) THEN
      WRITE(*,*) '  >> ALL PASS'
    ELSE
      WRITE(*,*) '  >> SOME FAILURES'
    END IF
    WRITE(*,*) '===================================================================='

  END SUBROUTINE Run_Harness_Mat_Thermal_Expansion

END MODULE HARNESS_Mat_Thermal_Expansion

!===============================================================================
! Runner
!===============================================================================
PROGRAM HARNESS_Mat_Thermal_Expansion_Runner
  USE HARNESS_Mat_Thermal_Expansion, ONLY: Run_Harness_Mat_Thermal_Expansion
  IMPLICIT NONE
  CALL Run_Harness_Mat_Thermal_Expansion()
END PROGRAM HARNESS_Mat_Thermal_Expansion_Runner
