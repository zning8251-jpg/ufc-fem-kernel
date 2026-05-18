!===============================================================================
! Module: HARNESS_Mat_Elastic_Uniaxial
! Layer:  L4_PH - Physics Layer (Harness)
! Domain: Material
! Purpose: Harness acceptance test — isotropic elastic material under uniaxial
!          tension. Self-contained analytical verification (no kernel dispatch).
!
! Theory:
!   Hooke's law (3-D isotropic):
!     sigma_ij = lambda * delta_ij * tr(eps) + 2 * mu * eps_ij
!   For uniaxial tension (eps_11 = e, others zero):
!     sigma_11 = (lambda + 2*mu) * e = E*(1-nu)/((1+nu)*(1-2*nu)) * e
!   Simplified (when Poisson effect is neglected in 1-D):
!     sigma_11 ~ E * e  (exact only in 1-D bar)
!   Here we verify the FULL 3-D Hooke's law:
!     sigma_11 = E*(1-nu)/((1+nu)*(1-2*nu)) * eps_11
!   Tangent modulus D_1111 = E*(1-nu)/((1+nu)*(1-2*nu))
!
! Parameters: E = 200 GPa, nu = 0.3, eps_11 = 0.001
!
! Status: Harness | Created: 2026-04-28
!===============================================================================
MODULE HARNESS_Mat_Elastic_Uniaxial
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Harness_Mat_Elastic_Uniaxial

  REAL(wp), PARAMETER :: TOL = 1.0e-10_wp

CONTAINS

  SUBROUTINE Run_Harness_Mat_Elastic_Uniaxial()
    REAL(wp) :: E, nu, lambda, mu
    REAL(wp) :: eps(6), sigma(6), D(6,6)
    REAL(wp) :: sigma_11_expected, D_11_expected
    REAL(wp) :: err_sigma, err_D
    INTEGER(i4) :: i, j, n_pass, n_fail

    n_pass = 0
    n_fail = 0

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'HARNESS_Mat_Elastic_Uniaxial: Isotropic Elastic — Uniaxial Tension'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    ! ---------------------------------------------------------------
    ! Material parameters
    ! ---------------------------------------------------------------
    E  = 200.0e9_wp     ! Young's modulus  [Pa]
    nu = 0.3_wp         ! Poisson's ratio  [-]
    lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    mu     = E / (2.0_wp * (1.0_wp + nu))

    ! ---------------------------------------------------------------
    ! Build full 3-D isotropic elasticity matrix D (Voigt notation)
    !   D(i,j) using ordering: 11, 22, 33, 12, 13, 23
    ! ---------------------------------------------------------------
    D = 0.0_wp
    D(1,1) = lambda + 2.0_wp * mu
    D(2,2) = lambda + 2.0_wp * mu
    D(3,3) = lambda + 2.0_wp * mu
    D(1,2) = lambda;  D(2,1) = lambda
    D(1,3) = lambda;  D(3,1) = lambda
    D(2,3) = lambda;  D(3,2) = lambda
    D(4,4) = mu
    D(5,5) = mu
    D(6,6) = mu

    ! ---------------------------------------------------------------
    ! Strain: uniaxial eps_11 = 0.001, all others = 0
    ! ---------------------------------------------------------------
    eps = 0.0_wp
    eps(1) = 0.001_wp

    ! ---------------------------------------------------------------
    ! Stress: sigma = D * eps  (matrix-vector multiply)
    ! ---------------------------------------------------------------
    sigma = 0.0_wp
    DO i = 1, 6
      DO j = 1, 6
        sigma(i) = sigma(i) + D(i,j) * eps(j)
      END DO
    END DO

    ! ---------------------------------------------------------------
    ! TC-1: Verify sigma_11 = D_1111 * eps_11
    ! ---------------------------------------------------------------
    sigma_11_expected = (lambda + 2.0_wp * mu) * eps(1)
    ! = E*(1-nu)/((1+nu)*(1-2*nu)) * 0.001
    ! = 200e9 * 0.7 / (1.3 * 0.4) * 0.001 = 269.230769... MPa

    err_sigma = ABS(sigma(1) - sigma_11_expected)
    WRITE(*,*) '  TC-1: Verify sigma_11 = D_1111 * eps_11'
    WRITE(*,*) '    Expected sigma_11 = ', sigma_11_expected / 1.0e6_wp, ' MPa'
    WRITE(*,*) '    Computed sigma_11 = ', sigma(1) / 1.0e6_wp, ' MPa'
    WRITE(*,*) '    Abs error         = ', err_sigma

    IF (err_sigma < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-2: Verify sigma_22 = sigma_33 = lambda * eps_11
    !        (Poisson lateral stress)
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-2: Verify lateral stress sigma_22 = lambda * eps_11'
    WRITE(*,*) '    Expected sigma_22 = ', lambda * eps(1) / 1.0e6_wp, ' MPa'
    WRITE(*,*) '    Computed sigma_22 = ', sigma(2) / 1.0e6_wp, ' MPa'

    IF (ABS(sigma(2) - lambda * eps(1)) < TOL .AND. &
        ABS(sigma(3) - lambda * eps(1)) < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-3: Verify shear stress components = 0
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-3: Verify shear stress = 0 (sigma_12,13,23)'

    IF (ABS(sigma(4)) < TOL .AND. ABS(sigma(5)) < TOL .AND. &
        ABS(sigma(6)) < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL (sigma_4,5,6 = ', sigma(4), sigma(5), sigma(6), ')'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-4: Verify tangent modulus D_1111 = E*(1-nu)/((1+nu)*(1-2*nu))
    ! ---------------------------------------------------------------
    D_11_expected = E * (1.0_wp - nu) / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
    err_D = ABS(D(1,1) - D_11_expected)
    WRITE(*,*) '  TC-4: Verify tangent D_1111'
    WRITE(*,*) '    Expected D_1111 = ', D_11_expected / 1.0e9_wp, ' GPa'
    WRITE(*,*) '    Computed D_1111 = ', D(1,1) / 1.0e9_wp, ' GPa'

    IF (err_D < TOL) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-5: Verify D matrix symmetry D(i,j) = D(j,i)
    ! ---------------------------------------------------------------
    WRITE(*,*) '  TC-5: Verify D matrix symmetry'
    DO i = 1, 6
      DO j = i+1, 6
        IF (ABS(D(i,j) - D(j,i)) > TOL) THEN
          WRITE(*,*) '    >> FAIL at (', i, ',', j, ')'
          n_fail = n_fail + 1
          GOTO 100
        END IF
      END DO
    END DO
    WRITE(*,*) '    >> PASS'
    n_pass = n_pass + 1
100 CONTINUE

    ! ---------------------------------------------------------------
    ! Summary
    ! ---------------------------------------------------------------
    WRITE(*,*) ''
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) '  HARNESS_Mat_Elastic_Uniaxial: ', n_pass, ' PASSED, ', n_fail, ' FAILED'
    IF (n_fail == 0) THEN
      WRITE(*,*) '  >> ALL PASS'
    ELSE
      WRITE(*,*) '  >> SOME FAILURES'
    END IF
    WRITE(*,*) '===================================================================='

  END SUBROUTINE Run_Harness_Mat_Elastic_Uniaxial

END MODULE HARNESS_Mat_Elastic_Uniaxial

!===============================================================================
! Runner
!===============================================================================
PROGRAM HARNESS_Mat_Elastic_Uniaxial_Runner
  USE HARNESS_Mat_Elastic_Uniaxial, ONLY: Run_Harness_Mat_Elastic_Uniaxial
  IMPLICIT NONE
  CALL Run_Harness_Mat_Elastic_Uniaxial()
END PROGRAM HARNESS_Mat_Elastic_Uniaxial_Runner
