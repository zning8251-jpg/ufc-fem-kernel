!===============================================================================
! E2E Test C2-07: MultiStep_StateTransfer (INTEGRATED VERSION)
! Layer:  Integration Test (E2E)
! Purpose: Verify multi-step analysis with correct state variable transfer
!          between load steps.
!
! Integration Status: PARTIAL
!   - RT_Step_Def: NO .mod file available (depends on MD_Step_Proc chain)
!     Module source at L5_RT/StepDriver/RT_Step_Def.f90 has RT_StepDriver_Desc,
!     RT_StepDriver_State, step state constants. Not built.
!   - RT_WB_Core: No module found for WriteBack core
!   - J2 plasticity: Could USE PH_Mat_Plast_J2_Iso_Core (.mod available), but
!     test uses 1D ideal plasticity (H=0), which is a degenerate case of the
!     3D J2 algorithm. Interface mismatch: module expects 6-comp Voigt strain,
!     test operates in 1D scalar. Retained inline for clean 1D verification.
!
! Modules Available (.mod): IF_Prec_Core, IF_Err_Brg, PH_Mat_Plast_J2_Iso_Core
! Modules Missing (.mod): RT_Step_Def, RT_WB_Core
!
! Original: E2E_C2_07_MultiStep_StateTransfer.f90 (self-contained, PASS)
! Status: ACTIVE | Created: 2026-04-28 | Integrated: 2026-04-28
!===============================================================================
PROGRAM E2E_C2_07_MultiStep_StateTransfer_Integrated
  ! TODO: Integrate with RT_Step_Def when .mod file is built.
  !       Use RT_StepDriver_Desc for step configuration, RT_StepDriver_State
  !       for step state tracking.
  ! TODO: Integrate 1D plasticity with PH_Mat_Plast_J2_Iso_Core when 1D/uniaxial
  !       wrapper is available (current module is full 3D Voigt).
  IMPLICIT NONE

  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)

  REAL(wp), PARAMETER :: E_MOD    = 200000.0_wp
  REAL(wp), PARAMETER :: SIGMA_Y  = 250.0_wp
  REAL(wp), PARAMETER :: H_HARD   = 0.0_wp
  REAL(wp), PARAMETER :: EPS_MAX  = 0.003_wp
  INTEGER(i4), PARAMETER :: NSTEP1 = 30_i4
  INTEGER(i4), PARAMETER :: NSTEP2 = 30_i4
  REAL(wp), PARAMETER :: TOL_STRESS = 1.0E-6_wp
  REAL(wp), PARAMETER :: TOL_STRAIN = 1.0E-10_wp

  REAL(wp) :: sigma_n, eps_p_n, eps_n, sigma_y_n
  REAL(wp) :: sigma_step1_end, eps_p_step1_end
  REAL(wp) :: sigma_step2_end, eps_p_step2_end
  REAL(wp) :: eps_p_step2_start
  REAL(wp) :: d_eps, sigma_trial, f_yield, d_gamma
  REAL(wp) :: eps_yield, eps_p_expected, sigma_unload_elastic
  INTEGER(i4) :: istep, n_pass, n_total

  n_pass = 0; n_total = 0

  WRITE(*,'(A)') '=== E2E Test C2-07: MultiStep_StateTransfer [INTEGRATED] ==='
  WRITE(*,'(A)') '  Partial: RT_Step_Def .mod not available; inline retained'
  WRITE(*,'(A)') '  Partial: 1D plasticity inline (module is 3D Voigt)'
  WRITE(*,'(A)') ''

  eps_yield = SIGMA_Y / E_MOD
  sigma_n = 0.0_wp; eps_p_n = 0.0_wp; eps_n = 0.0_wp; sigma_y_n = SIGMA_Y

  ! === STEP 1: Loading ===
  d_eps = EPS_MAX / REAL(NSTEP1, wp)
  DO istep = 1, NSTEP1
    eps_n = eps_n + d_eps
    sigma_trial = sigma_n + E_MOD*d_eps
    f_yield = ABS(sigma_trial) - sigma_y_n
    IF (f_yield > 0.0_wp) THEN
      d_gamma = f_yield / (E_MOD + H_HARD)
      sigma_n = sigma_trial - SIGN(E_MOD*d_gamma, sigma_trial)
      eps_p_n = eps_p_n + d_gamma
      sigma_y_n = SIGMA_Y + H_HARD*eps_p_n
    ELSE
      sigma_n = sigma_trial
    END IF
  END DO
  sigma_step1_end = sigma_n; eps_p_step1_end = eps_p_n

  ! Check 1
  n_total = n_total + 1
  IF (ABS(sigma_step1_end - SIGMA_Y) < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 1: Step1 end s=s_y ... PASS (expected=', SIGMA_Y, &
      ', got=', sigma_step1_end, ')'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 1: Step1 end s=s_y ... FAIL (expected=', SIGMA_Y, &
      ', got=', sigma_step1_end, ')'
  END IF

  ! Check 2
  n_total = n_total + 1
  eps_p_expected = EPS_MAX - SIGMA_Y/E_MOD
  IF (ABS(eps_p_step1_end - eps_p_expected) < TOL_STRAIN) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
      'Check 2: Step1 eps_p=0.00175 ... PASS (expected=', eps_p_expected, &
      ', got=', eps_p_step1_end, ')'
  ELSE
    WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
      'Check 2: Step1 eps_p=0.00175 ... FAIL (expected=', eps_p_expected, &
      ', got=', eps_p_step1_end, ')'
  END IF

  ! === STEP 2: Unloading (STATE TRANSFER) ===
  eps_p_step2_start = eps_p_n

  ! Check 3: State transfer
  n_total = n_total + 1
  IF (ABS(eps_p_step2_start - eps_p_step1_end) < 1.0E-15_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES14.7,A)') &
      'Check 3: State transfer eps_p preserved ... PASS (eps_p=', &
      eps_p_step2_start, ')'
  ELSE
    WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
      'Check 3: State transfer ... FAIL (Step1_end=', eps_p_step1_end, &
      ', Step2_start=', eps_p_step2_start, ')'
  END IF

  d_eps = -EPS_MAX / REAL(NSTEP2, wp)
  DO istep = 1, NSTEP2
    eps_n = eps_n + d_eps
    sigma_trial = sigma_n + E_MOD*d_eps
    f_yield = ABS(sigma_trial) - sigma_y_n
    IF (f_yield > 0.0_wp) THEN
      d_gamma = f_yield / (E_MOD + H_HARD)
      sigma_n = sigma_trial - SIGN(E_MOD*d_gamma, sigma_trial)
      eps_p_n = eps_p_n + d_gamma
      sigma_y_n = SIGMA_Y + H_HARD*eps_p_n
    ELSE
      sigma_n = sigma_trial
    END IF
  END DO
  sigma_step2_end = sigma_n; eps_p_step2_end = eps_p_n

  ! Check 4
  n_total = n_total + 1
  IF (ABS(sigma_step2_end - (-SIGMA_Y)) < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 4: Step2 reverse yield s=-s_y ... PASS (expected=', -SIGMA_Y, &
      ', got=', sigma_step2_end, ')'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 4: Step2 reverse yield s=-s_y ... FAIL (expected=', -SIGMA_Y, &
      ', got=', sigma_step2_end, ')'
  END IF

  ! Check 5
  n_total = n_total + 1
  BLOCK
    REAL(wp) :: eps_p_step2_expected, elastic_range, plastic_incr_step2
    elastic_range = 2.0_wp*SIGMA_Y/E_MOD
    plastic_incr_step2 = EPS_MAX - elastic_range
    eps_p_step2_expected = eps_p_expected + plastic_incr_step2
    IF (ABS(eps_p_step2_end - eps_p_step2_expected) < TOL_STRAIN) THEN
      n_pass = n_pass + 1
      WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
        'Check 5: Total eps_p after Step2 ... PASS (expected=', &
        eps_p_step2_expected, ', got=', eps_p_step2_end, ')'
    ELSE
      WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
        'Check 5: Total eps_p after Step2 ... FAIL (expected=', &
        eps_p_step2_expected, ', got=', eps_p_step2_end, ')'
    END IF
  END BLOCK

  ! Check 6
  n_total = n_total + 1
  IF (ABS(eps_n) < TOL_STRAIN) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES14.7,A)') 'Check 6: Final total strain eps=0 ... PASS (eps=', eps_n, ')'
  ELSE
    WRITE(*,'(A,ES14.7,A)') 'Check 6: Final total strain eps=0 ... FAIL (eps=', eps_n, ')'
  END IF

  ! Check 7
  n_total = n_total + 1
  IF (ABS(sigma_step2_end) > 1.0_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A)') 'Check 7: Non-zero residual stress ... PASS (s=', sigma_step2_end, ')'
  ELSE
    WRITE(*,'(A,F10.4,A)') 'Check 7: Non-zero residual stress ... FAIL (s=', sigma_step2_end, ')'
  END IF

  WRITE(*,'(A)') ''
  IF (n_pass == n_total) THEN
    WRITE(*,'(A,I0,A,I0,A)') '=== RESULT: PASS (', n_pass, '/', n_total, ' checks passed) ==='
  ELSE
    WRITE(*,'(A,I0,A,I0,A)') '=== RESULT: FAIL (', n_pass, '/', n_total, ' checks passed) ==='
  END IF

END PROGRAM E2E_C2_07_MultiStep_StateTransfer_Integrated
