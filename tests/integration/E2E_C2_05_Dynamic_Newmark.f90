!===============================================================================
! E2E Test C2-05: Dynamic_Newmark
! Layer:  Integration Test (E2E)
! Purpose: Verify implicit Newmark time integration for a single-DOF
!          spring-mass system. Validates unconditionally stable scheme
!          preserves energy and phase over one full period.
!
! Setup:
!   - SDOF: m=1.0, k=100.0
!   - Initial conditions: u(0)=1.0, v(0)=0
!   - Analytical solution: u(t) = cos(ωt), ω = √(k/m) = 10 rad/s
!   - Period: T = 2π/ω ≈ 0.6283 s
!   - Newmark parameters: β=0.25, γ=0.5 (average acceleration, unconditional)
!   - dt=0.01, 100 steps → t_final=1.0 s
!
! Verification:
!   - u(T) ≈ 1.0 (return to initial displacement after one period)
!   - Energy conservation check
!   - Phase error check at t=T/4 (u≈0)
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
PROGRAM E2E_C2_05_Dynamic_Newmark
  IMPLICIT NONE

  ! Precision
  INTEGER, PARAMETER :: wp = SELECTED_REAL_KIND(15, 307)
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)

  ! System parameters
  REAL(wp), PARAMETER :: MASS   = 1.0_wp       ! Mass [kg]
  REAL(wp), PARAMETER :: STIFF  = 100.0_wp     ! Spring stiffness [N/m]
  REAL(wp), PARAMETER :: PI     = 3.141592653589793_wp

  ! Newmark parameters (average acceleration method)
  REAL(wp), PARAMETER :: BETA   = 0.25_wp
  REAL(wp), PARAMETER :: GAMMA  = 0.5_wp

  ! Time integration
  REAL(wp), PARAMETER :: DT       = 0.01_wp    ! Time step [s]
  INTEGER(i4), PARAMETER :: NSTEP = 100_i4     ! Number of steps

  ! Derived quantities
  REAL(wp), PARAMETER :: OMEGA  = 10.0_wp      ! ω = √(k/m) = 10 rad/s
  REAL(wp), PARAMETER :: PERIOD = 0.6283185307179587_wp  ! T = 2π/ω

  ! Tolerances
  REAL(wp), PARAMETER :: TOL_DISP   = 0.05_wp  ! 5% relative error on displacement
  REAL(wp), PARAMETER :: TOL_ENERGY = 0.02_wp  ! 2% energy drift

  ! Variables
  REAL(wp) :: u_n, v_n, a_n          ! Current state
  REAL(wp) :: u_np1, v_np1, a_np1    ! Next state
  REAL(wp) :: u_pred, v_pred         ! Predictors
  REAL(wp) :: K_eff, F_eff           ! Effective stiffness/force
  REAL(wp) :: u_exact, t_current
  REAL(wp) :: energy_0, energy_n     ! Energies
  REAL(wp) :: u_at_period            ! Displacement at t≈T
  REAL(wp) :: u_at_quarter           ! Displacement at t≈T/4
  REAL(wp) :: err_period, err_quarter, err_energy
  INTEGER(i4) :: istep, step_at_period, step_at_quarter
  INTEGER(i4) :: n_pass, n_total

  n_pass = 0
  n_total = 0

  WRITE(*,'(A)') '=== E2E Test C2-05: Dynamic_Newmark ==='
  WRITE(*,'(A)') ''

  !---------------------------------------------------------------------------
  ! Initialize
  !---------------------------------------------------------------------------
  u_n = 1.0_wp       ! Initial displacement
  v_n = 0.0_wp       ! Initial velocity
  a_n = -STIFF * u_n / MASS   ! Initial acceleration: ma = -ku → a = -100

  ! Initial energy: E = 0.5·k·u² + 0.5·m·v² = 50.0
  energy_0 = 0.5_wp * STIFF * u_n**2 + 0.5_wp * MASS * v_n**2

  ! Find steps closest to T and T/4
  step_at_period  = NINT(PERIOD / DT)      ! ≈ 63
  step_at_quarter = NINT(0.25_wp * PERIOD / DT)  ! ≈ 16

  ! Effective stiffness (constant for linear problem)
  K_eff = STIFF + MASS / (BETA * DT**2)

  !---------------------------------------------------------------------------
  ! Newmark time integration loop
  !---------------------------------------------------------------------------
  u_at_period  = 0.0_wp
  u_at_quarter = 0.0_wp

  DO istep = 1, NSTEP
    ! Predictor step
    u_pred = u_n + DT * v_n + 0.5_wp * DT**2 * (1.0_wp - 2.0_wp * BETA) * a_n
    v_pred = v_n + DT * (1.0_wp - GAMMA) * a_n

    ! Effective force (F_ext = 0 for free vibration)
    F_eff = -STIFF * u_pred + MASS / (BETA * DT**2) * u_pred
    ! Solve: K_eff * u_{n+1} = F_eff_total
    ! For SDOF: M·a_{n+1} + K·u_{n+1} = 0
    ! Using Newmark: (K + M/(β·dt²))·u_{n+1} = M/(β·dt²)·ũ
    ! where ũ = u_n + dt·v_n + dt²·(0.5-β)·a_n
    u_np1 = (MASS / (BETA * DT**2) * u_pred) / K_eff

    ! Actually, let's do proper Newmark for F=0:
    ! Predictor: ũ = u_n + dt·v_n + (0.5-β)·dt²·a_n
    ! Solve: (M/(β·dt²) + K)·u_{n+1} = M/(β·dt²)·ũ
    u_np1 = (MASS / (BETA * DT**2)) * u_pred / K_eff

    ! Corrector: compute acceleration and velocity
    a_np1 = (u_np1 - u_pred) / (BETA * DT**2)
    v_np1 = v_pred + GAMMA * DT * a_np1

    ! Record at key time steps
    IF (istep == step_at_period)  u_at_period  = u_np1
    IF (istep == step_at_quarter) u_at_quarter = u_np1

    ! Advance
    u_n = u_np1
    v_n = v_np1
    a_n = a_np1
  END DO

  ! Final energy
  energy_n = 0.5_wp * STIFF * u_n**2 + 0.5_wp * MASS * v_n**2

  !---------------------------------------------------------------------------
  ! Check 1: Displacement at t≈T (one full period) should return to ~1.0
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  t_current = REAL(step_at_period, wp) * DT
  u_exact = COS(OMEGA * t_current)
  err_period = ABS(u_at_period - u_exact) / ABS(u_exact)

  IF (err_period < TOL_DISP) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 1: u(T)≈cos(ωT) at t=T ... PASS (expected=', u_exact, &
      ', got=', u_at_period, ')'
  ELSE
    WRITE(*,'(A,F10.6,A,F10.6,A,F8.4,A)') &
      'Check 1: u(T)≈cos(ωT) at t=T ... FAIL (expected=', u_exact, &
      ', got=', u_at_period, ', err=', err_period*100.0_wp, '%)'
  END IF

  !---------------------------------------------------------------------------
  ! Check 2: Displacement at t≈T/4 (quarter period) should be ~0
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  t_current = REAL(step_at_quarter, wp) * DT
  u_exact = COS(OMEGA * t_current)
  err_quarter = ABS(u_at_quarter - u_exact)

  IF (err_quarter < 0.05_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 2: u(T/4)≈0 ... PASS (expected=', u_exact, &
      ', got=', u_at_quarter, ')'
  ELSE
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 2: u(T/4)≈0 ... FAIL (expected=', u_exact, &
      ', got=', u_at_quarter, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 3: Energy conservation (Newmark β=0.25,γ=0.5 is energy-conserving)
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  err_energy = ABS(energy_n - energy_0) / energy_0

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

  !---------------------------------------------------------------------------
  ! Check 4: Final displacement accuracy at t=1.0s
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  t_current = REAL(NSTEP, wp) * DT
  u_exact = COS(OMEGA * t_current)  ! cos(10) ≈ -0.8391

  IF (ABS(u_n - u_exact) / MAX(ABS(u_exact), 1.0E-10_wp) < TOL_DISP) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 4: u(1.0s)≈cos(10) ... PASS (expected=', u_exact, &
      ', got=', u_n, ')'
  ELSE
    WRITE(*,'(A,F10.6,A,F10.6,A)') &
      'Check 4: u(1.0s)≈cos(10) ... FAIL (expected=', u_exact, &
      ', got=', u_n, ')'
  END IF

  !---------------------------------------------------------------------------
  ! Check 5: Newmark scheme stability (no blow-up)
  !---------------------------------------------------------------------------
  n_total = n_total + 1
  IF (ABS(u_n) < 2.0_wp) THEN
    n_pass = n_pass + 1
    WRITE(*,'(A,F10.6,A)') &
      'Check 5: Scheme stability |u|<2 ... PASS (u_final=', u_n, ')'
  ELSE
    WRITE(*,'(A,F10.6,A)') &
      'Check 5: Scheme stability |u|<2 ... FAIL (u_final=', u_n, ')'
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

END PROGRAM E2E_C2_05_Dynamic_Newmark
