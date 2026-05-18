!===============================================================================
! E2E Test C2-04: ThermoMech_Coupling (INTEGRATED VERSION)
! Layer:  Integration Test (E2E)
! Purpose: Verify thermo-mechanical coupling - thermal stress from constrained
!          thermal expansion under uniform temperature rise.
!
! Integration Status: PARTIAL
!   - PH_Mat_Therm_Iso_Core: NO .mod file available → all thermal computation inline
!   - Module source exists at L4_PH/Material/Thermal/PH_Mat_Therm_Iso_Core.f90
!     with PH_Therm_Props, PH_Therm_State, PH_Mat_Therm_Compute_ThermalStrain,
!     PH_Mat_Therm_Compute_Stress. Interface compatible but .mod not built.
!   - Code structure mirrors module API (props/state pattern) for future upgrade.
!
! Modules Available (.mod): IF_Prec_Core, IF_Err_Brg (not used — no module deps)
! Modules Missing (.mod): PH_Mat_Therm_Iso_Core
!
! Original: E2E_C2_04_ThermoMech_Coupling.f90 (self-contained, PASS)
! Status: ACTIVE | Created: 2026-04-28 | Integrated: 2026-04-28
!===============================================================================
PROGRAM E2E_C2_04_ThermoMech_Coupling_Integrated
  ! TODO: Integrate with PH_Mat_Therm_Iso_Core when .mod file is built.
  !       Replace inline computation with:
  !         USE PH_Mat_Therm_Iso_Core, ONLY: PH_Therm_Props, PH_Therm_State, &
  !             PH_Mat_Therm_Init, PH_Mat_Therm_Compute_ThermalStrain, &
  !             PH_Mat_Therm_Compute_Stress
  IMPLICIT NONE

  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)

  REAL(wp), PARAMETER :: E_MOD    = 200000.0_wp
  REAL(wp), PARAMETER :: NU_MAT   = 0.3_wp
  REAL(wp), PARAMETER :: ALPHA_TH = 12.0E-6_wp
  REAL(wp), PARAMETER :: DELTA_T  = 100.0_wp
  REAL(wp), PARAMETER :: TOL_STRESS = 1.0E-6_wp

  REAL(wp) :: sigma_expected, sigma_computed
  REAL(wp) :: eps_thermal(6), eps_mechanical(6), stress(6)
  REAL(wp) :: D(6,6), lambda, mu, err_abs
  INTEGER(i4) :: n_pass, n_total, i, j

  n_pass = 0; n_total = 0

  WRITE(*,'(A)') '=== E2E Test C2-04: ThermoMech_Coupling [INTEGRATED] ==='
  WRITE(*,'(A)') '  Partial: PH_Mat_Therm_Iso_Core .mod not available; inline retained'
  WRITE(*,'(A)') ''

  lambda = E_MOD*NU_MAT/((1.0_wp+NU_MAT)*(1.0_wp-2.0_wp*NU_MAT))
  mu     = E_MOD/(2.0_wp*(1.0_wp+NU_MAT))

  D = 0.0_wp
  D(1,1)=lambda+2.0_wp*mu; D(2,2)=lambda+2.0_wp*mu; D(3,3)=lambda+2.0_wp*mu
  D(1,2)=lambda; D(2,1)=lambda; D(1,3)=lambda; D(3,1)=lambda
  D(2,3)=lambda; D(3,2)=lambda
  D(4,4)=mu; D(5,5)=mu; D(6,6)=mu

  ! Check 1: Thermal strain
  n_total = n_total + 1
  eps_thermal = 0.0_wp
  eps_thermal(1) = ALPHA_TH*DELTA_T
  eps_thermal(2) = ALPHA_TH*DELTA_T
  eps_thermal(3) = ALPHA_TH*DELTA_T
  IF (ABS(eps_thermal(1)-1.2E-3_wp) < 1.0E-10_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES12.5,A,ES12.5,A)') &
      'Check 1: Thermal strain alpha*DT ... PASS (expected=', 1.2E-3_wp, &
      ', got=', eps_thermal(1), ')'
  ELSE
    WRITE(*,'(A,ES12.5,A,ES12.5,A)') &
      'Check 1: Thermal strain alpha*DT ... FAIL (expected=', 1.2E-3_wp, &
      ', got=', eps_thermal(1), ')'
  END IF

  ! Check 2: Uniaxial constraint stress
  n_total = n_total + 1
  sigma_expected = -E_MOD*ALPHA_TH*DELTA_T
  eps_mechanical = 0.0_wp
  eps_mechanical(1) = -ALPHA_TH*DELTA_T
  eps_mechanical(2) = NU_MAT*ALPHA_TH*DELTA_T
  eps_mechanical(3) = NU_MAT*ALPHA_TH*DELTA_T
  stress = 0.0_wp
  DO i = 1, 6; DO j = 1, 6
    stress(i) = stress(i) + D(i,j)*eps_mechanical(j)
  END DO; END DO
  sigma_computed = stress(1)
  err_abs = ABS(sigma_computed - sigma_expected)
  IF (err_abs < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.3,A,F10.3,A)') &
      'Check 2: Uniaxial thermal stress ... PASS (expected=', &
      sigma_expected, ', got=', sigma_computed, ')'
  ELSE
    WRITE(*,'(A,F10.3,A,F10.3,A)') &
      'Check 2: Uniaxial thermal stress ... FAIL (expected=', &
      sigma_expected, ', got=', sigma_computed, ')'
  END IF

  ! Check 3: Lateral stress zero
  n_total = n_total + 1
  IF (ABS(stress(2)) < TOL_STRESS .AND. ABS(stress(3)) < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES12.5,A,ES12.5,A)') &
      'Check 3: Lateral stress ~0 ... PASS (s_yy=', stress(2), ', s_zz=', stress(3), ')'
  ELSE
    WRITE(*,'(A,ES12.5,A,ES12.5,A)') &
      'Check 3: Lateral stress ~0 ... FAIL (s_yy=', stress(2), ', s_zz=', stress(3), ')'
  END IF

  ! Check 4: Triaxial constraint stress
  n_total = n_total + 1
  BLOCK
    REAL(wp) :: sigma_tri_expected, stress_tri(6), eps_tri(6), err_tri
    sigma_tri_expected = -E_MOD*ALPHA_TH*DELTA_T/(1.0_wp-2.0_wp*NU_MAT)
    eps_tri = 0.0_wp
    eps_tri(1) = -ALPHA_TH*DELTA_T
    eps_tri(2) = -ALPHA_TH*DELTA_T
    eps_tri(3) = -ALPHA_TH*DELTA_T
    stress_tri = 0.0_wp
    DO i = 1, 6; DO j = 1, 6
      stress_tri(i) = stress_tri(i) + D(i,j)*eps_tri(j)
    END DO; END DO
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

  ! Check 5: Hydrostatic state
  n_total = n_total + 1
  BLOCK
    REAL(wp) :: stress_tri2(6), eps_tri2(6)
    eps_tri2 = 0.0_wp
    eps_tri2(1) = -ALPHA_TH*DELTA_T
    eps_tri2(2) = -ALPHA_TH*DELTA_T
    eps_tri2(3) = -ALPHA_TH*DELTA_T
    stress_tri2 = 0.0_wp
    DO i = 1, 6; DO j = 1, 6
      stress_tri2(i) = stress_tri2(i) + D(i,j)*eps_tri2(j)
    END DO; END DO
    IF (ABS(stress_tri2(1)-stress_tri2(2)) < TOL_STRESS .AND. &
        ABS(stress_tri2(2)-stress_tri2(3)) < TOL_STRESS) THEN
      n_pass = n_pass + 1
      WRITE(*,'(A)') 'Check 5: Triaxial hydrostatic state s11=s22=s33 ... PASS'
    ELSE
      WRITE(*,'(A,3(F10.3,1X))') &
        'Check 5: Triaxial hydrostatic state ... FAIL (s=', &
        stress_tri2(1), stress_tri2(2), stress_tri2(3)
    END IF
  END BLOCK

  WRITE(*,'(A)') ''
  IF (n_pass == n_total) THEN
    WRITE(*,'(A,I0,A,I0,A)') &
      '=== RESULT: PASS (', n_pass, '/', n_total, ' checks passed) ==='
  ELSE
    WRITE(*,'(A,I0,A,I0,A)') &
      '=== RESULT: FAIL (', n_pass, '/', n_total, ' checks passed) ==='
  END IF

END PROGRAM E2E_C2_04_ThermoMech_Coupling_Integrated
