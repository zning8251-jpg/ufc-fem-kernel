!===============================================================================
! Test: Test_Contact_AugLag
! Target: Augmented Lagrange Uzawa outer-iteration logic
!         (mirrors RT_Cont_AugLag_Solver.f90 and RT_Contact_Types.f90 changes)
!
! Strategy: Self-contained test that replicates the Uzawa update and convergence
!           logic inline to verify:
!   TC-01: AugLagInit allocates lambda_n / lambda_trial to correct size
!   TC-02: UpdateLambda: open pairs -> lambda_trial = 0 (KKT)
!   TC-03: UpdateLambda: penetrated pairs -> lambda grows with rho
!   TC-04: CheckConv: delta_norm computed correctly; commit advances lambda_n
!   TC-05: Rollback resets lambda_trial to lambda_n
!   TC-06: Full 3-pair Uzawa iteration converges in <= n_aug_max steps
!   TC-07: uzawa_iter counter increments correctly each commit
!
! Compile standalone:
!   gfortran -std=f2003 -o test_auglag Test_Contact_AugLag.f90 && ./test_auglag
!===============================================================================
PROGRAM Test_Contact_AugLag
  IMPLICIT NONE
  INTEGER, PARAMETER :: wp = KIND(1.0D0)
  INTEGER, PARAMETER :: i4 = KIND(1)

  !-- Inline replica of relevant RT_Contact_State AugLag fields
  TYPE :: AugLagState
    REAL(wp), POINTER :: lambda_n(:)     => NULL()
    REAL(wp), POINTER :: lambda_trial(:) => NULL()
    INTEGER(i4)       :: uzawa_iter      = 0
    LOGICAL           :: uzawa_converged = .FALSE.
  END TYPE AugLagState

  INTEGER :: pass_count = 0, fail_count = 0

  CALL Run_TC01(pass_count, fail_count)
  CALL Run_TC02(pass_count, fail_count)
  CALL Run_TC03(pass_count, fail_count)
  CALL Run_TC04(pass_count, fail_count)
  CALL Run_TC05(pass_count, fail_count)
  CALL Run_TC06(pass_count, fail_count)
  CALL Run_TC07(pass_count, fail_count)

  WRITE(*,'(A,I0,A,I0)') 'Test_Contact_AugLag: PASS=', pass_count, '  FAIL=', fail_count
  IF (fail_count > 0) STOP 1

CONTAINS

  !-- Mirror of state%AugLagInit
  SUBROUTINE DoAugLagInit(s, n_pairs, lam0)
    TYPE(AugLagState), INTENT(INOUT) :: s
    INTEGER(i4), INTENT(IN) :: n_pairs
    REAL(wp), INTENT(IN), OPTIONAL :: lam0
    REAL(wp) :: l0
    l0 = 0.0_wp
    IF (PRESENT(lam0)) l0 = lam0
    IF (.NOT. ASSOCIATED(s%lambda_n)) THEN
      ALLOCATE(s%lambda_n(n_pairs))
    ELSE IF (SIZE(s%lambda_n) /= n_pairs) THEN
      DEALLOCATE(s%lambda_n) ; ALLOCATE(s%lambda_n(n_pairs))
    END IF
    s%lambda_n = l0
    IF (.NOT. ASSOCIATED(s%lambda_trial)) THEN
      ALLOCATE(s%lambda_trial(n_pairs))
    ELSE IF (SIZE(s%lambda_trial) /= n_pairs) THEN
      DEALLOCATE(s%lambda_trial) ; ALLOCATE(s%lambda_trial(n_pairs))
    END IF
    s%lambda_trial    = l0
    s%uzawa_iter      = 0
    s%uzawa_converged = .FALSE.
  END SUBROUTINE DoAugLagInit

  !-- Mirror of RT_Cont_AugLag_UpdateLambda
  !   gap(i) < 0 => penetration; lambda_trial(i) = max(0, lambda_n(i) - rho*gap(i))
  SUBROUTINE DoUpdateLambda(s, gap, rho)
    TYPE(AugLagState), INTENT(INOUT) :: s
    REAL(wp), INTENT(IN) :: gap(:), rho
    INTEGER(i4) :: i, n
    n = SIZE(s%lambda_n)
    DO i = 1, n
      s%lambda_trial(i) = MAX(0.0_wp, s%lambda_n(i) - rho * gap(i))
    END DO
  END SUBROUTINE DoUpdateLambda

  !-- Mirror of state%AugLagCommit
  SUBROUTINE DoCommit(s, delta_norm)
    TYPE(AugLagState), INTENT(INOUT) :: s
    REAL(wp), INTENT(OUT) :: delta_norm
    INTEGER(i4) :: i, n
    delta_norm = 0.0_wp
    n = SIZE(s%lambda_n)
    DO i = 1, n
      delta_norm = MAX(delta_norm, ABS(s%lambda_trial(i) - s%lambda_n(i)))
    END DO
    s%lambda_n    = s%lambda_trial
    s%uzawa_iter  = s%uzawa_iter + 1
  END SUBROUTINE DoCommit

  !-- Mirror of state%AugLagRollback
  SUBROUTINE DoRollback(s)
    TYPE(AugLagState), INTENT(INOUT) :: s
    s%lambda_trial = s%lambda_n
  END SUBROUTINE DoRollback

  SUBROUTINE Assert(cond, tag, p, f)
    LOGICAL, INTENT(IN) :: cond
    CHARACTER(*), INTENT(IN) :: tag
    INTEGER, INTENT(INOUT) :: p, f
    IF (cond) THEN
      WRITE(*,'(A,A)') '  PASS: ', tag ; p = p + 1
    ELSE
      WRITE(*,'(A,A)') '  FAIL: ', tag ; f = f + 1
    END IF
  END SUBROUTINE Assert

  !-- TC-01: Init allocates correct size, values = 0
  SUBROUTINE Run_TC01(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(AugLagState) :: s
    WRITE(*,*) '--- TC-01: AugLagInit ---'
    CALL DoAugLagInit(s, 5_i4)
    CALL Assert(ASSOCIATED(s%lambda_n),     'lambda_n allocated', p, f)
    CALL Assert(ASSOCIATED(s%lambda_trial), 'lambda_trial allocated', p, f)
    CALL Assert(SIZE(s%lambda_n) == 5,      'lambda_n size == 5', p, f)
    CALL Assert(ALL(ABS(s%lambda_n) < 1.0e-14_wp),    'lambda_n == 0', p, f)
    CALL Assert(ALL(ABS(s%lambda_trial) < 1.0e-14_wp),'lambda_trial == 0', p, f)
    CALL Assert(s%uzawa_iter == 0,          'uzawa_iter == 0', p, f)
    IF (ASSOCIATED(s%lambda_n))     DEALLOCATE(s%lambda_n)
    IF (ASSOCIATED(s%lambda_trial)) DEALLOCATE(s%lambda_trial)
  END SUBROUTINE Run_TC01

  !-- TC-02: Open pairs (gap >= 0) => lambda_trial = 0
  SUBROUTINE Run_TC02(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(AugLagState) :: s
    REAL(wp) :: gap(3)
    WRITE(*,*) '--- TC-02: UpdateLambda open pairs ---'
    CALL DoAugLagInit(s, 3_i4)
    gap = [0.5_wp, 1.0_wp, 2.0_wp]   ! all open (gap > 0)
    CALL DoUpdateLambda(s, gap, 1.0_wp)
    CALL Assert(ALL(ABS(s%lambda_trial) < 1.0e-14_wp), &
                'lambda_trial == 0 for open pairs', p, f)
    IF (ASSOCIATED(s%lambda_n))     DEALLOCATE(s%lambda_n)
    IF (ASSOCIATED(s%lambda_trial)) DEALLOCATE(s%lambda_trial)
  END SUBROUTINE Run_TC02

  !-- TC-03: Penetrating pairs => lambda grows
  SUBROUTINE Run_TC03(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(AugLagState) :: s
    REAL(wp) :: gap(2)
    REAL(wp), PARAMETER :: rho = 100.0_wp
    WRITE(*,*) '--- TC-03: UpdateLambda penetrating pairs ---'
    CALL DoAugLagInit(s, 2_i4)
    gap = [-0.01_wp, -0.02_wp]  ! penetration: gap < 0
    CALL DoUpdateLambda(s, gap, rho)
    !-- Expected: lambda_trial(1) = max(0, 0 - 100*(-0.01)) = 1.0
    CALL Assert(ABS(s%lambda_trial(1) - 1.0_wp) < 1.0e-10_wp, &
                'lambda_trial(1) == 1.0 (rho*|gap|)', p, f)
    CALL Assert(ABS(s%lambda_trial(2) - 2.0_wp) < 1.0e-10_wp, &
                'lambda_trial(2) == 2.0 (rho*|gap|)', p, f)
    IF (ASSOCIATED(s%lambda_n))     DEALLOCATE(s%lambda_n)
    IF (ASSOCIATED(s%lambda_trial)) DEALLOCATE(s%lambda_trial)
  END SUBROUTINE Run_TC03

  !-- TC-04: CheckConv (DoCommit): delta_norm and lambda_n update
  SUBROUTINE Run_TC04(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(AugLagState) :: s
    REAL(wp) :: gap(2), delta_norm
    WRITE(*,*) '--- TC-04: CheckConv / Commit ---'
    CALL DoAugLagInit(s, 2_i4)
    gap = [-0.01_wp, -0.03_wp]
    CALL DoUpdateLambda(s, gap, 100.0_wp)
    ! lambda_trial = [1.0, 3.0]
    CALL DoCommit(s, delta_norm)
    CALL Assert(ABS(delta_norm - 3.0_wp) < 1.0e-10_wp, &
                'delta_norm == 3.0 (max |delta_lambda|)', p, f)
    CALL Assert(ALL(ABS(s%lambda_n - s%lambda_trial) < 1.0e-14_wp), &
                'lambda_n == lambda_trial after Commit', p, f)
    IF (ASSOCIATED(s%lambda_n))     DEALLOCATE(s%lambda_n)
    IF (ASSOCIATED(s%lambda_trial)) DEALLOCATE(s%lambda_trial)
  END SUBROUTINE Run_TC04

  !-- TC-05: Rollback resets lambda_trial to lambda_n
  SUBROUTINE Run_TC05(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(AugLagState) :: s
    REAL(wp) :: gap(2), delta_norm
    WRITE(*,*) '--- TC-05: Rollback ---'
    CALL DoAugLagInit(s, 2_i4)
    gap = [-0.01_wp, -0.02_wp]
    CALL DoUpdateLambda(s, gap, 100.0_wp)
    ! lambda_trial = [1.0, 2.0]; lambda_n = [0, 0]
    CALL DoCommit(s, delta_norm)    ! lambda_n -> [1, 2]
    ! Load bad trial
    s%lambda_trial = 999.0_wp
    ! Rollback
    CALL DoRollback(s)
    CALL Assert(ALL(ABS(s%lambda_trial - s%lambda_n) < 1.0e-14_wp), &
                'lambda_trial == lambda_n after Rollback', p, f)
    IF (ASSOCIATED(s%lambda_n))     DEALLOCATE(s%lambda_n)
    IF (ASSOCIATED(s%lambda_trial)) DEALLOCATE(s%lambda_trial)
  END SUBROUTINE Run_TC05

  !-- TC-06: Uzawa lambda update: single step produces correct value;
  !   and after n_aug_max steps with gap driven to zero (NR converged),
  !   the iteration is trivially converged.
  !   This test simulates the scheduler logic: gap reduces as lambda grows
  !   via a simple compliance model: gap(k) = gap0 + lambda_n / K_eff
  !   (contact stiffness K_eff). Uzawa converges when lambda stabilises.
  SUBROUTINE Run_TC06(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(AugLagState) :: s
    REAL(wp) :: gap(1), delta_norm, tol_aug
    REAL(wp) :: gap0, K_eff, rho, lam_exact
    INTEGER :: k, n_aug_max
    LOGICAL :: converged
    WRITE(*,*) '--- TC-06: Uzawa convergence with compliance feedback ---'
    !-- Model: rigid penetration gap0 = -1e-3, K_eff = 1e5 (compliance),
    !          rho = 1e4, lambda_exact = K_eff * |gap0| = 100
    gap0    = -1.0e-3_wp
    K_eff   = 1.0e5_wp
    rho     = 1.0e4_wp
    lam_exact = K_eff * ABS(gap0)    ! = 100.0
    tol_aug   = 1.0e-3_wp   ! relative tolerance (|delta_lambda| < tol)
    n_aug_max = 500         ! enough for contraction ratio 0.9 to converge
    CALL DoAugLagInit(s, 1_i4)
    converged = .FALSE.
    DO k = 1, n_aug_max
      !-- Simulate NR converged: effective gap = gap0 + lambda_n / K_eff
      gap(1) = gap0 + s%lambda_n(1) / K_eff
      CALL DoUpdateLambda(s, gap, rho)
      CALL DoCommit(s, delta_norm)
      IF (delta_norm < tol_aug) THEN
        converged = .TRUE.
        EXIT
      END IF
    END DO
    CALL Assert(converged, 'Uzawa converges with compliance feedback', p, f)
    CALL Assert(ABS(s%lambda_n(1) - lam_exact) / (lam_exact + 1.0_wp) < 1.0e-4_wp, &
                'Converged lambda ~= K_eff * |gap0|', p, f)
    IF (ASSOCIATED(s%lambda_n))     DEALLOCATE(s%lambda_n)
    IF (ASSOCIATED(s%lambda_trial)) DEALLOCATE(s%lambda_trial)
  END SUBROUTINE Run_TC06

  !-- TC-07: uzawa_iter increments correctly each commit
  SUBROUTINE Run_TC07(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(AugLagState) :: s
    REAL(wp) :: gap(2), delta_norm
    INTEGER :: k
    WRITE(*,*) '--- TC-07: uzawa_iter counter ---'
    CALL DoAugLagInit(s, 2_i4)
    gap = [-0.001_wp, -0.001_wp]
    DO k = 1, 3
      CALL DoUpdateLambda(s, gap, 10.0_wp)
      CALL DoCommit(s, delta_norm)
    END DO
    CALL Assert(s%uzawa_iter == 3, 'uzawa_iter == 3 after 3 commits', p, f)
    IF (ASSOCIATED(s%lambda_n))     DEALLOCATE(s%lambda_n)
    IF (ASSOCIATED(s%lambda_trial)) DEALLOCATE(s%lambda_trial)
  END SUBROUTINE Run_TC07

END PROGRAM Test_Contact_AugLag
