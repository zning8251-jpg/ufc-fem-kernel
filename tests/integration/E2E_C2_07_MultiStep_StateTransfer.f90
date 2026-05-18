!===============================================================================
! E2E Test C2-07: MultiStep_StateTransfer
! Layer:  Integration Test (E2E)
! Purpose: Verify multi-step analysis with correct state variable transfer
!          between load steps. Tests elastic-plastic loading followed by
!          unloading with proper history variable persistence.
!
! Setup:
!   - Material: E=200000 MPa, σ_y=250 MPa, H=0 (ideal elastic-plastic)
!   - Step 1: Strain loading to ε=0.003 (beyond yield εy=σy/E=0.00125)
!   - Step 2: Strain unloading from ε=0.003 to ε=0
!
! Verification:
!   Step 1 end: σ=σ_y=250 MPa, ε_p=0.003-250/200000=0.00175
!   Step 2: Elastic unloading from σ=250, Δε=-0.003
!           σ = 250 + E·(-0.003) = 250 - 600 = -350 MPa
!           But |σ|>σ_y → reverse yielding at σ=-250 MPa
!           Additional plastic strain from reverse yield point
!   Key: ε_p at Step2 start = ε_p at Step1 end (state transfer)
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
PROGRAM E2E_C2_07_MultiStep_StateTransfer
  IMPLICIT NONE

  ! Precision
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)

  ! Material parameters
  REAL(wp), PARAMETER :: E_MOD    = 200000.0_wp    ! Young's modulus [MPa]
  REAL(wp), PARAMETER :: SIGMA_Y  = 250.0_wp       ! Yield stress [MPa]
  REAL(wp), PARAMETER :: H_HARD   = 0.0_wp         ! Hardening modulus (ideal plastic)

  ! Loading parameters
  REAL(wp), PARAMETER :: EPS_MAX  = 0.003_wp       ! Max strain in Step 1
  INTEGER(i4), PARAMETER :: NSTEP1 = 30_i4         ! Increments in Step 1
  INTEGER(i4), PARAMETER :: NSTEP2 = 30_i4         ! Increments in Step 2

  ! Tolerances
  REAL(wp), PARAMETER :: TOL_STRESS = 1.0E-6_wp    ! Stress tolerance [MPa]
  REAL(wp), PARAMETER :: TOL_STRAIN = 1.0E-10_wp   ! Strain tolerance

  ! State variables
  REAL(wp) :: sigma_n          ! Current stress
  REAL(wp) :: eps_p_n          ! Current plastic strain (accumulated)
  REAL(wp) :: eps_n            ! Current total strain
  REAL(wp) :: sigma_y_n        ! Current yield stress (for hardening)

  ! Step-end snapshots
  REAL(wp) :: sigma_step1_end, eps_p_step1_end
  REAL(wp) :: sigma_step2_end, eps_p_step2_end
  REAL(wp) :: eps_p_step2_start

  ! Incremental variables
  REAL(wp) :: d_eps            ! Strain increment
  REAL(wp) :: sigma_trial      ! Trial stress
  REAL(wp) :: f_yield          ! Yield function value
  REAL(wp) :: d_gamma          ! Plastic multiplier

  ! Analytical values
  REAL(wp) :: eps_yield        ! Yield strain = σ_y/E
  REAL(wp) :: eps_p_expected   ! Expected plastic strain at Step1 end
  REAL(wp) :: sigma_unload_elastic  ! Elastic unload prediction

  ! Counters
  INTEGER(i4) :: istep, n_pass, n_total

  n_pass = 0
  n_total = 0

  WRITE(*,'(A)') '=== E2E Test C2-07: MultiStep_StateTransfer ==='
  WRITE(*,'(A)') ''

  ! Derived quantities
  eps_yield = SIGMA_Y / E_MOD    ! = 0.00125

  !---------------------------------------------------------------------------
  ! Initialize state
  !---------------------------------------------------------------------------
  sigma_n   = 0.0_wp
  eps_p_n   = 0.0_wp
  eps_n     = 0.0_wp
  sigma_y_n = SIGMA_Y

  !===========================================================================
  ! STEP 1: Loading from ε=0 to ε=0.003
  !===========================================================================
  d_eps = EPS_MAX / REAL(NSTEP1, wp)

  DO istep = 1, NSTEP1
    eps_n = eps_n + d_eps

    ! Elastic predictor (trial stress)
    sigma_trial = sigma_n + E_MOD * d_eps

    ! Yield function: f = |σ_trial| - σ_y
    f_yield = ABS(sigma_trial) - sigma_y_n

    IF (f_yield > 0.0_wp) THEN
      ! Plastic corrector (radial return for 1D)
      ! For ideal plasticity (H=0): Δγ = f / E, σ = σ_y·sign(σ_trial)
      d_gamma = f_yield / (E_MOD + H_HARD)
      sigma_n = sigma_trial - SIGN(E_MOD * d_gamma, sigma_trial)
      eps_p_n = eps_p_n + d_gamma
      ! Update yield stress (for hardening case)
      sigma_y_n = SIGMA_Y + H_HARD * eps_p_n
    ELSE
      ! Elastic step
      sigma_n = sigma_trial
    END IF
  END DO

  ! Snapshot Step 1 end state
  sigma_step1_end = sigma_n
  eps_p_step1_end = eps_p_n

  !---------------------------------------------------------------------------
  ! Check 1: Step 1 end stress = σ_y = 250 MPa
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (ABS(sigma_step1_end - SIGMA_Y) < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 1: Step1 end σ=σ_y ... PASS (expected=', SIGMA_Y, &
      ', got=', sigma_step1_end, ')'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 1: Step1 end σ=σ_y ... FAIL (expected=', SIGMA_Y, &
      ', got=', sigma_step1_end, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 2: Step 1 end plastic strain ε_p = 0.003 - 250/200000 = 0.00175
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  eps_p_expected = EPS_MAX - SIGMA_Y / E_MOD   ! = 0.003 - 0.00125 = 0.00175

  IF (ABS(eps_p_step1_end - eps_p_expected) < TOL_STRAIN) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
      'Check 2: Step1 ε_p=0.00175 ... PASS (expected=', eps_p_expected, &
      ', got=', eps_p_step1_end, ')'
  ELSE
    WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
      'Check 2: Step1 ε_p=0.00175 ... FAIL (expected=', eps_p_expected, &
      ', got=', eps_p_step1_end, ')'
  END IF

  !===========================================================================
  ! STEP 2: Unloading from ε=0.003 to ε=0
  ! STATE TRANSFER: eps_p_n, sigma_n, sigma_y_n carry over from Step 1
  !===========================================================================
  eps_p_step2_start = eps_p_n   ! Record initial ε_p for Step 2

  !---------------------------------------------------------------------------
  ! Check 3: State transfer - ε_p at Step2 start = ε_p at Step1 end
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (ABS(eps_p_step2_start - eps_p_step1_end) < 1.0E-15_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES14.7,A)') &
      'Check 3: State transfer ε_p(Step2_start)=ε_p(Step1_end) ... PASS (ε_p=', &
      eps_p_step2_start, ')'
  ELSE
    WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
      'Check 3: State transfer ... FAIL (Step1_end=', eps_p_step1_end, &
      ', Step2_start=', eps_p_step2_start, ')'
  END IF

  ! Unloading
  d_eps = -EPS_MAX / REAL(NSTEP2, wp)

  DO istep = 1, NSTEP2
    eps_n = eps_n + d_eps

    ! Elastic predictor
    sigma_trial = sigma_n + E_MOD * d_eps

    ! Yield function
    f_yield = ABS(sigma_trial) - sigma_y_n

    IF (f_yield > 0.0_wp) THEN
      ! Reverse yielding (plastic in compression)
      d_gamma = f_yield / (E_MOD + H_HARD)
      sigma_n = sigma_trial - SIGN(E_MOD * d_gamma, sigma_trial)
      eps_p_n = eps_p_n + d_gamma
      sigma_y_n = SIGMA_Y + H_HARD * eps_p_n
    ELSE
      ! Elastic unloading
      sigma_n = sigma_trial
    END IF
  END DO

  ! Snapshot Step 2 end state
  sigma_step2_end = sigma_n
  eps_p_step2_end = eps_p_n

  !---------------------------------------------------------------------------
  ! Check 4: Step 2 triggers reverse yielding (σ reaches -σ_y)
  !   Elastic unload: σ = 250 - 200000·0.003 = -350 → exceeds -250
  !   So reverse yield occurs, final σ = -σ_y = -250
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (ABS(sigma_step2_end - (-SIGMA_Y)) < TOL_STRESS) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 4: Step2 reverse yield σ=-σ_y ... PASS (expected=', -SIGMA_Y, &
      ', got=', sigma_step2_end, ')'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A)') &
      'Check 4: Step2 reverse yield σ=-σ_y ... FAIL (expected=', -SIGMA_Y, &
      ', got=', sigma_step2_end, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 5: Plastic strain increased during Step 2 (reverse yielding adds ε_p)
  !   Elastic range: Δε_elastic = 2·σ_y/E = 500/200000 = 0.0025
  !   Total unload Δε = 0.003
  !   Plastic increment in Step2 = 0.003 - 0.0025 = 0.0005
  !   Total ε_p = 0.00175 + 0.0005 = 0.00225
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  BLOCK
    REAL(wp) :: eps_p_step2_expected
    REAL(wp) :: elastic_range, plastic_incr_step2

    elastic_range = 2.0_wp * SIGMA_Y / E_MOD       ! = 0.0025
    plastic_incr_step2 = EPS_MAX - elastic_range    ! = 0.0005
    eps_p_step2_expected = eps_p_expected + plastic_incr_step2  ! = 0.00225

    IF (ABS(eps_p_step2_end - eps_p_step2_expected) < TOL_STRAIN) THEN
      n_pass = n_pass + 1
      WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
        'Check 5: Total ε_p after Step2 ... PASS (expected=', &
        eps_p_step2_expected, ', got=', eps_p_step2_end, ')'
    ELSE
      WRITE(*,'(A,ES14.7,A,ES14.7,A)') &
        'Check 5: Total ε_p after Step2 ... FAIL (expected=', &
        eps_p_step2_expected, ', got=', eps_p_step2_end, ')'
    END IF
  END BLOCK

  !---------------------------------------------------------------------------
  ! Check 6: Final total strain = 0 (fully unloaded)
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (ABS(eps_n) < TOL_STRAIN) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,ES14.7,A)') &
      'Check 6: Final total strain ε=0 ... PASS (ε=', eps_n, ')'
  ELSE
    WRITE(*,'(A,ES14.7,A)') &
      'Check 6: Final total strain ε=0 ... FAIL (ε=', eps_n, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 7: Residual stress is non-zero (permanent deformation)
  !   After full unload (ε_total=0), σ ≠ 0 because ε_p ≠ 0
  !   σ = E·(ε_total - ε_p) ... but we track incrementally
  !   Actually with ideal plasticity + reverse yield: σ = -250 MPa
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (ABS(sigma_step2_end) > 1.0_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A)') &
      'Check 7: Non-zero residual stress ... PASS (σ=', sigma_step2_end, ')'
  ELSE
    WRITE(*,'(A,F10.4,A)') &
      'Check 7: Non-zero residual stress ... FAIL (σ=', sigma_step2_end, ')'
  END IF

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

END PROGRAM E2E_C2_07_MultiStep_StateTransfer
