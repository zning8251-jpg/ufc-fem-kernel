!===============================================================================
! E2E Test C2-05: Dynamic_Newmark (INTEGRATED VERSION)
! Layer:  Integration Test (E2E)
! Purpose: Verify implicit Newmark time integration for SDOF spring-mass.
!
! Integration Status: PARTIAL
!   - RT_Solv_TimeInt: NO .mod file in build_mod → Newmark algorithm inline
!   - Module source at L5_RT/Solver/RT_Solv_TimeInt.f90 contains UF_TimeIntState
!     type and full Newmark/HHT implementation, but requires RT_Solv_Def,
!     RT_Solv_Sparse dependencies (complex chain).
!   - RT_Step_Def: NO .mod file → step driver types not integrated
!   - Code structure mirrors SDOF Newmark from module (same β=0.25, γ=0.5).
!
! Modules Available (.mod): IF_Prec_Core, IF_Err_Brg (not used)
! Modules Missing (.mod): RT_Solv_TimeInt, RT_Step_Def
!
! Original: E2E_C2_05_Dynamic_Newmark.f90 (self-contained, PASS)
! Status: ACTIVE | Created: 2026-04-28 | Integrated: 2026-04-28
!===============================================================================
PROGRAM E2E_C2_05_Dynamic_Newmark_Integrated
  ! TODO: Integrate with RT_Solv_TimeInt when .mod file is built and
  !       SDOF interface is available (current module requires CSR sparse).
  !       Target: USE RT_Solv_TimeInt, ONLY: UF_TimeIntState, RT_Newmark_Step
  IMPLICIT NONE

  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)

  REAL(wp), PARAMETER :: MASS   = 1.0_wp
  REAL(wp), PARAMETER :: STIFF  = 100.0_wp
  REAL(wp), PARAMETER :: PI     = 3.141592653589793_wp
  REAL(wp), PARAMETER :: BETA   = 0.25_wp
  REAL(wp), PARAMETER :: GAMMA  = 0.5_wp
  REAL(wp), PARAMETER :: DT     = 0.01_wp
  INTEGER(i4), PARAMETER :: NSTEP = 100_i4
  REAL(wp), PARAMETER :: OMEGA  = 10.0_wp
  REAL(wp), PARAMETER :: PERIOD = 0.6283185307179587_wp
  REAL(wp), PARAMETER :: TOL_DISP   = 0.05_wp
  REAL(wp), PARAMETER :: TOL_ENERGY = 0.02_wp

  REAL(wp) :: u_n, v_n, a_n, u_np1, v_np1, a_np1
  REAL(wp) :: u_pred, v_pred, K_eff, F_eff
  REAL(wp) :: u_exact, t_current
  REAL(wp) :: energy_0, energy_n
  REAL(wp) :: u_at_period, u_at_quarter
  REAL(wp) :: err_period, err_quarter, err_energy
  INTEGER(i4) :: istep, step_at_period, step_at_quarter
  INTEGER(i4) :: n_pass, n_total

  n_pass = 0; n_total = 0

  WRITE(*,'(A)') '=== E2E Test C2-05: Dynamic_Newmark [INTEGRATED] ==='
  WRITE(*,'(A)') '  Partial: RT_Solv_TimeInt .mod not available; inline retained'
  WRITE(*,'(A)') ''

  u_n = 1.0_wp; v_n = 0.0_wp
  a_n = -STIFF*u_n/MASS
  energy_0 = 0.5_wp*STIFF*u_n**2 + 0.5_wp*MASS*v_n**2
  step_at_period  = NINT(PERIOD/DT)
  step_at_quarter = NINT(0.25_wp*PERIOD/DT)
  K_eff = STIFF + MASS/(BETA*DT**2)
  u_at_period = 0.0_wp; u_at_quarter = 0.0_wp

  DO istep = 1, NSTEP
    u_pred = u_n + DT*v_n + 0.5_wp*DT**2*(1.0_wp-2.0_wp*BETA)*a_n
    v_pred = v_n + DT*(1.0_wp-GAMMA)*a_n
    u_np1 = (MASS/(BETA*DT**2))*u_pred/K_eff
    a_np1 = (u_np1-u_pred)/(BETA*DT**2)
    v_np1 = v_pred + GAMMA*DT*a_np1
    IF (istep == step_at_period)  u_at_period  = u_np1
    IF (istep == step_at_quarter) u_at_quarter = u_np1
    u_n = u_np1; v_n = v_np1; a_n = a_np1
  END DO

  energy_n = 0.5_wp*STIFF*u_n**2 + 0.5_wp*MASS*v_n**2

  ! Check 1
  n_total = n_total + 1
  t_current = REAL(step_at_period,wp)*DT
  u_exact = COS(OMEGA*t_current)
  err_period = ABS(u_at_period-u_exact)/ABS(u_exact)
  IF (err_period < TOL_DISP) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 1: u(T)~cos(wT) ... PASS (expected=', u_exact, ', got=', u_at_period, ')'
  ELSE
    WRITE(*,'(A,F10.6,A,F10.6,A,F8.4,A)') &
      'Check 1: u(T)~cos(wT) ... FAIL (expected=', u_exact, &
      ', got=', u_at_period, ', err=', err_period*100.0_wp, '%)'
  END IF

  ! Check 2
  n_total = n_total + 1
  t_current = REAL(step_at_quarter,wp)*DT
  u_exact = COS(OMEGA*t_current)
  err_quarter = ABS(u_at_quarter-u_exact)
  IF (err_quarter < 0.05_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 2: u(T/4)~0 ... PASS (expected=', u_exact, ', got=', u_at_quarter, ')'
  ELSE
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 2: u(T/4)~0 ... FAIL (expected=', u_exact, ', got=', u_at_quarter, ')'
  END IF

  ! Check 3
  n_total = n_total + 1
  err_energy = ABS(energy_n-energy_0)/energy_0
  IF (err_energy < TOL_ENERGY) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.4,A,F10.4,A,F8.4,A)') &
      'Check 3: Energy conservation ... PASS (E0=', energy_0, &
      ', E_final=', energy_n, ', drift=', err_energy*100.0_wp, '%)'
  ELSE
    WRITE(*,'(A,F10.4,A,F10.4,A,F8.4,A)') &
      'Check 3: Energy conservation ... FAIL (E0=', energy_0, &
      ', E_final=', energy_n, ', drift=', err_energy*100.0_wp, '%)'
  END IF

  ! Check 4
  n_total = n_total + 1
  t_current = REAL(NSTEP,wp)*DT
  u_exact = COS(OMEGA*t_current)
  IF (ABS(u_n-u_exact)/MAX(ABS(u_exact),1.0E-10_wp) < TOL_DISP) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 4: u(1.0s)~cos(10) ... PASS (expected=', u_exact, ', got=', u_n, ')'
  ELSE
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 4: u(1.0s)~cos(10) ... FAIL (expected=', u_exact, ', got=', u_n, ')'
  END IF

  ! Check 5
  n_total = n_total + 1
  IF (ABS(u_n) < 2.0_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.6,A)') 'Check 5: Scheme stability |u|<2 ... PASS (u_final=', u_n, ')'
  ELSE
    WRITE(*,'(A,F10.6,A)') 'Check 5: Scheme stability |u|<2 ... FAIL (u_final=', u_n, ')'
  END IF

  WRITE(*,'(A)') ''
  IF (n_pass == n_total) THEN
    WRITE(*,'(A,I0,A,I0,A)') '=== RESULT: PASS (', n_pass, '/', n_total, ' checks passed) ==='
  ELSE
    WRITE(*,'(A,I0,A,I0,A)') '=== RESULT: FAIL (', n_pass, '/', n_total, ' checks passed) ==='
  END IF

END PROGRAM E2E_C2_05_Dynamic_Newmark_Integrated
