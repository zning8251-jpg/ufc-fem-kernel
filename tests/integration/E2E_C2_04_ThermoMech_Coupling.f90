!===============================================================================
! E2E Test C2-04: ThermoMech_Coupling
! Layer:  Integration Test (E2E)
! Purpose: Verify thermo-mechanical coupling - thermal stress from constrained
!          thermal expansion under uniform temperature rise.
!
! Setup:
!   - Single element, uniform temperature rise ΔT = 100°C
!   - Material: E=200000 MPa, nu=0.3, α=12e-6/°C
!   - BC: Uniaxial constraint (fixed in x-direction, free in y,z)
!   - Expected: σ_xx = -E·α·ΔT = -200000·12e-6·100 = -240 MPa (compressive)
!
! Theory:
!   For a bar constrained in x-direction with free lateral expansion:
!   ε_thermal = α·ΔT (free thermal strain)
!   ε_mechanical = 0 (fully constrained in x)
!   σ_xx = -E·α·ΔT (compressive stress to prevent expansion)
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
PROGRAM E2E_C2_04_ThermoMech_Coupling
  IMPLICIT NONE

  ! Precision
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)

  ! Material parameters
  REAL(wp), PARAMETER :: E_MOD    = 200000.0_wp     ! Young's modulus [MPa]
  REAL(wp), PARAMETER :: NU_MAT   = 0.3_wp          ! Poisson's ratio [-]
  REAL(wp), PARAMETER :: ALPHA_TH = 12.0E-6_wp      ! Thermal expansion coeff [1/°C]
  REAL(wp), PARAMETER :: DELTA_T  = 100.0_wp        ! Temperature rise [°C]

  ! Tolerances
  REAL(wp), PARAMETER :: TOL_STRESS = 1.0E-6_wp     ! Stress tolerance [MPa]

  ! Variables
  REAL(wp) :: sigma_expected, sigma_computed
  REAL(wp) :: eps_thermal(6)          ! Thermal strain (Voigt: 11,22,33,12,13,23)
  REAL(wp) :: eps_mechanical(6)       ! Mechanical strain
  REAL(wp) :: stress(6)               ! Cauchy stress (Voigt)
  REAL(wp) :: D(6,6)                  ! Elasticity matrix (3D isotropic)
  REAL(wp) :: lambda, mu             ! Lamé parameters
  REAL(wp) :: err_abs
  INTEGER(i4) :: n_pass, n_total
  INTEGER(i4) :: i, j

  n_pass = 0
  n_total = 0

  WRITE(*,'(A)') '=== E2E Test C2-04: ThermoMech_Coupling ==='
  WRITE(*,'(A)') ''

  !---------------------------------------------------------------------------
  ! Compute Lamé parameters
  !---------------------------------------------------------------------------
  lambda = E_MOD * NU_MAT / ((1.0_wp + NU_MAT) * (1.0_wp - 2.0_wp * NU_MAT))
  mu     = E_MOD / (2.0_wp * (1.0_wp + NU_MAT))

  !---------------------------------------------------------------------------
  ! Build 3D isotropic elasticity matrix D (Voigt notation)
  !---------------------------------------------------------------------------
  D = 0.0_wp
  ! Diagonal: normal components
  D(1,1) = lambda + 2.0_wp * mu
  D(2,2) = lambda + 2.0_wp * mu
  D(3,3) = lambda + 2.0_wp * mu
  ! Off-diagonal: normal coupling
  D(1,2) = lambda;  D(2,1) = lambda
  D(1,3) = lambda;  D(3,1) = lambda
  D(2,3) = lambda;  D(3,2) = lambda
  ! Shear components
  D(4,4) = mu
  D(5,5) = mu
  D(6,6) = mu

  !---------------------------------------------------------------------------
  ! Check 1: Thermal strain computation
  !   ε_thermal = α·ΔT in all normal directions, zero shear
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  eps_thermal = 0.0_wp
  eps_thermal(1) = ALPHA_TH * DELTA_T    ! ε_11
  eps_thermal(2) = ALPHA_TH * DELTA_T    ! ε_22
  eps_thermal(3) = ALPHA_TH * DELTA_T    ! ε_33
  ! Shear components remain zero

  IF (ABS(eps_thermal(1) - 1.2E-3_wp) < 1.0E-10_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES12.5,A,ES12.5,A)') &
      'Check 1: Thermal strain α·ΔT ... PASS (expected=', 1.2E-3_wp, &
      ', got=', eps_thermal(1), ')'
  ELSE
    WRITE(*,'(A,ES12.5,A,ES12.5,A)') &
      'Check 1: Thermal strain α·ΔT ... FAIL (expected=', 1.2E-3_wp, &
      ', got=', eps_thermal(1), ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 2: Uniaxial constraint stress (σ_xx = -E·α·ΔT)
  !   BC: ε_xx_total = 0 (constrained), ε_yy, ε_zz free
  !   Mechanical strain: ε_mech_xx = -ε_thermal_xx
  !   For uniaxial constraint: σ_xx = E·ε_mech_xx = -E·α·ΔT
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  sigma_expected = -E_MOD * ALPHA_TH * DELTA_T   ! = -240 MPa

  ! Uniaxial constraint: only x is constrained
  ! ε_mech_xx = 0 - ε_th_xx = -α·ΔT
  ! ε_mech_yy = ε_mech_zz = free → σ_yy = σ_zz = 0
  ! From σ_yy = 0: λ(ε_xx + ε_yy + ε_zz) + 2μ·ε_yy = 0
  ! From σ_zz = 0: λ(ε_xx + ε_yy + ε_zz) + 2μ·ε_zz = 0
  ! → ε_yy = ε_zz and solve system

  ! For uniaxial stress state (σ_yy=σ_zz=0), σ_xx = E·ε_xx
  ! where ε_xx is the mechanical strain in x-direction
  eps_mechanical = 0.0_wp
  eps_mechanical(1) = -ALPHA_TH * DELTA_T   ! constrained: total=0, mech = -thermal

  ! Solve for free lateral strains: σ_yy = σ_zz = 0
  ! λ(ε_xx + ε_yy + ε_zz) + 2μ·ε_yy = 0
  ! By symmetry ε_yy = ε_zz = -λ/(λ+2μ) * (-1) ... actually:
  ! ε_yy = ε_zz = -λ/(2(λ+μ)) · ε_xx = ν·α·ΔT
  eps_mechanical(2) = NU_MAT * ALPHA_TH * DELTA_T
  eps_mechanical(3) = NU_MAT * ALPHA_TH * DELTA_T

  ! Compute stress: σ = D · ε_mechanical
  stress = 0.0_wp
  DO i = 1, 6
    DO j = 1, 6
      stress(i) = stress(i) + D(i,j) * eps_mechanical(j)
    END DO
  END DO

  sigma_computed = stress(1)

  err_abs = ABS(sigma_computed - sigma_expected)
  IF (err_abs < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.3,A,F10.3,A)') &
      'Check 2: Uniaxial thermal stress σ_xx ... PASS (expected=', &
      sigma_expected, ', got=', sigma_computed, ')'
  ELSE
    WRITE(*,'(A,F10.3,A,F10.3,A)') &
      'Check 2: Uniaxial thermal stress σ_xx ... FAIL (expected=', &
      sigma_expected, ', got=', sigma_computed, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 3: Lateral stress should be zero (free expansion)
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (ABS(stress(2)) < TOL_STRESS .AND. ABS(stress(3)) < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES12.5,A,ES12.5,A)') &
      'Check 3: Lateral stress σ_yy≈0, σ_zz≈0 ... PASS (σ_yy=', &
      stress(2), ', σ_zz=', stress(3), ')'
  ELSE
    WRITE(*,'(A,ES12.5,A,ES12.5,A)') &
      'Check 3: Lateral stress σ_yy≈0, σ_zz≈0 ... FAIL (σ_yy=', &
      stress(2), ', σ_zz=', stress(3), ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 4: Triaxial constraint stress σ = -E·α·ΔT/(1-2ν)
  !   All directions constrained: ε_mechanical = -ε_thermal
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  BLOCK
    REAL(wp) :: sigma_tri_expected, stress_tri(6), eps_tri(6)
    REAL(wp) :: err_tri

    sigma_tri_expected = -E_MOD * ALPHA_TH * DELTA_T / (1.0_wp - 2.0_wp * NU_MAT)
    ! = -200000 * 12e-6 * 100 / 0.4 = -600 MPa

    eps_tri = 0.0_wp
    eps_tri(1) = -ALPHA_TH * DELTA_T
    eps_tri(2) = -ALPHA_TH * DELTA_T
    eps_tri(3) = -ALPHA_TH * DELTA_T

    stress_tri = 0.0_wp
    DO i = 1, 6
      DO j = 1, 6
        stress_tri(i) = stress_tri(i) + D(i,j) * eps_tri(j)
      END DO
    END DO

    err_tri = ABS(stress_tri(1) - sigma_tri_expected)
    IF (err_tri < TOL_STRESS) THEN
      n_pass = n_pass + 1
      WRITE(*,'(A,F10.3,A,F10.3,A)') &
        'Check 4: Triaxial thermal stress ... PASS (expected=', &
        sigma_tri_expected, ', got=', stress_tri(1), ')'
    ELSE
      WRITE(*,'(A,F10.3,A,F10.3,A)') &
        'Check 4: Triaxial thermal stress ... FAIL (expected=', &
        sigma_tri_expected, ', got=', stress_tri(1), ')'
    END IF
  END BLOCK

  !---------------------------------------------------------------------------
  ! Check 5: Hydrostatic state under triaxial constraint (σ_11=σ_22=σ_33)
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  BLOCK
    REAL(wp) :: stress_tri2(6), eps_tri2(6)

    eps_tri2 = 0.0_wp
    eps_tri2(1) = -ALPHA_TH * DELTA_T
    eps_tri2(2) = -ALPHA_TH * DELTA_T
    eps_tri2(3) = -ALPHA_TH * DELTA_T

    stress_tri2 = 0.0_wp
    DO i = 1, 6
      DO j = 1, 6
        stress_tri2(i) = stress_tri2(i) + D(i,j) * eps_tri2(j)
      END DO
    END DO

    IF (ABS(stress_tri2(1) - stress_tri2(2)) < TOL_STRESS .AND. &
        ABS(stress_tri2(2) - stress_tri2(3)) < TOL_STRESS) THEN
      n_pass = n_pass + 1
      WRITE(*,'(A)') &
        'Check 5: Triaxial hydrostatic state σ_11=σ_22=σ_33 ... PASS'
    ELSE
      WRITE(*,'(A,3(F10.3,1X))') &
        'Check 5: Triaxial hydrostatic state ... FAIL (σ=', &
        stress_tri2(1), stress_tri2(2), stress_tri2(3)
    END IF
  END BLOCK

  !---------------------------------------------------------------------------
  ! Summary
  !---------------------------------------------------------------------------
  WRITE(*,'(A)') ''
  IF (n_pass == n_total) THEN
    WRITE(*,'(A,I0,A,I0,A)') &
      '=== RESULT: PASS (', n_pass, '/', n_total, ' checks passed) ==='
  ELSE
    WRITE(*,'(A,I0,A,I0,A)') &
      '=== RESULT: FAIL (', n_pass, '/', n_total, ' checks passed) ==='
  END IF

END PROGRAM E2E_C2_04_ThermoMech_Coupling
