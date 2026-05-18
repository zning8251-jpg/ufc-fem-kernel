!===============================================================================
! Test: Test_MatCache_Swap
! Target: RT_MatCache_Snapshot_Type + RT_MatCache_Commit + RT_MatCache_Rollback
!         (in RT_Mat_Core.f90)
!
! Strategy: Self-contained test that replicates the MOVE_ALLOC Commit/Rollback
!           logic inline (without linking the full project) to verify:
!   TC-01: Commit swaps stress arrays correctly (O(1) pointer swap)
!   TC-02: Commit swaps statev arrays correctly
!   TC-03: Rollback restores committed state into trial
!   TC-04: Multiple Commit cycles remain consistent
!   TC-05: Rollback after Commit returns trial to pre-commit state
!
! Compile standalone:
!   gfortran -std=f2003 -o test_matcache Test_MatCache_Swap.f90 && ./test_matcache
!===============================================================================
PROGRAM Test_MatCache_Swap
  IMPLICIT NONE
  INTEGER, PARAMETER :: wp = KIND(1.0D0)
  INTEGER, PARAMETER :: i4 = KIND(1)

  !-- Inline replica of RT_MatCache_Snapshot_Type (avoids full project build)
  TYPE :: Snapshot
    REAL(wp), ALLOCATABLE :: stress(:,:)   ! [6, n_intpts]
    REAL(wp), ALLOCATABLE :: statev(:,:)   ! [n_sdv, n_intpts]
    INTEGER(i4) :: n_intpts = 0
    INTEGER(i4) :: n_sdv    = 0
  END TYPE Snapshot

  INTEGER :: pass_count = 0, fail_count = 0
  CALL Run_TC01(pass_count, fail_count)
  CALL Run_TC02(pass_count, fail_count)
  CALL Run_TC03(pass_count, fail_count)
  CALL Run_TC04(pass_count, fail_count)
  CALL Run_TC05(pass_count, fail_count)

  WRITE(*,'(A,I0,A,I0)') 'Test_MatCache_Swap: PASS=', pass_count, '  FAIL=', fail_count
  IF (fail_count > 0) STOP 1

CONTAINS

  !> Inline Commit implementation (mirrors RT_MatCache_Commit)
  SUBROUTINE DoCommit(committed, trial)
    TYPE(Snapshot), INTENT(INOUT) :: committed, trial
    REAL(wp), ALLOCATABLE :: tmp_s(:,:), tmp_v(:,:)
    INTEGER(i4) :: n_tmp
    IF (ALLOCATED(trial%stress)) THEN
      CALL MOVE_ALLOC(FROM=committed%stress, TO=tmp_s)
      CALL MOVE_ALLOC(FROM=trial%stress,     TO=committed%stress)
      CALL MOVE_ALLOC(FROM=tmp_s,            TO=trial%stress)
    END IF
    IF (ALLOCATED(trial%statev)) THEN
      CALL MOVE_ALLOC(FROM=committed%statev, TO=tmp_v)
      CALL MOVE_ALLOC(FROM=trial%statev,     TO=committed%statev)
      CALL MOVE_ALLOC(FROM=tmp_v,            TO=trial%statev)
    END IF
    n_tmp = committed%n_intpts ; committed%n_intpts = trial%n_intpts ; trial%n_intpts = n_tmp
    n_tmp = committed%n_sdv   ; committed%n_sdv    = trial%n_sdv    ; trial%n_sdv    = n_tmp
  END SUBROUTINE DoCommit

  !> Inline Rollback implementation (mirrors RT_MatCache_Rollback)
  SUBROUTINE DoRollback(committed, trial)
    TYPE(Snapshot), INTENT(IN)    :: committed
    TYPE(Snapshot), INTENT(INOUT) :: trial
    INTEGER(i4) :: n_ip, n_sv
    n_ip = committed%n_intpts
    n_sv = committed%n_sdv
    IF (ALLOCATED(committed%stress)) THEN
      IF (.NOT. ALLOCATED(trial%stress)) THEN
        ALLOCATE(trial%stress(6, n_ip))
      ELSE IF (SIZE(trial%stress, 2) /= n_ip) THEN
        DEALLOCATE(trial%stress) ; ALLOCATE(trial%stress(6, n_ip))
      END IF
      trial%stress = committed%stress
    END IF
    IF (ALLOCATED(committed%statev)) THEN
      IF (.NOT. ALLOCATED(trial%statev)) THEN
        ALLOCATE(trial%statev(n_sv, n_ip))
      ELSE IF (SIZE(trial%statev, 2) /= n_ip .OR. SIZE(trial%statev, 1) /= n_sv) THEN
        DEALLOCATE(trial%statev) ; ALLOCATE(trial%statev(n_sv, n_ip))
      END IF
      trial%statev = committed%statev
    END IF
    trial%n_intpts = committed%n_intpts
    trial%n_sdv    = committed%n_sdv
  END SUBROUTINE DoRollback

  SUBROUTINE Assert(cond, tag, pass_count, fail_count)
    LOGICAL, INTENT(IN) :: cond
    CHARACTER(*), INTENT(IN) :: tag
    INTEGER, INTENT(INOUT) :: pass_count, fail_count
    IF (cond) THEN
      WRITE(*,'(A,A)') '  PASS: ', tag
      pass_count = pass_count + 1
    ELSE
      WRITE(*,'(A,A)') '  FAIL: ', tag
      fail_count = fail_count + 1
    END IF
  END SUBROUTINE Assert

  !-- TC-01: Commit swaps stress arrays
  SUBROUTINE Run_TC01(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(Snapshot) :: committed, trial
    INTEGER, PARAMETER :: NIP = 4, N6 = 6
    WRITE(*,*) '--- TC-01: Commit stress swap ---'
    ALLOCATE(committed%stress(N6, NIP))
    ALLOCATE(trial%stress(N6, NIP))
    committed%stress = 1.0_wp
    trial%stress     = 2.0_wp
    committed%n_intpts = NIP ; trial%n_intpts = NIP
    CALL DoCommit(committed, trial)
    !-- After commit: committed should be 2.0, trial should be 1.0
    CALL Assert(ALL(ABS(committed%stress - 2.0_wp) < 1.0e-14_wp), &
                'committed%stress == 2.0 after Commit', p, f)
    CALL Assert(ALL(ABS(trial%stress - 1.0_wp) < 1.0e-14_wp), &
                'trial%stress == 1.0 after Commit', p, f)
    IF (ALLOCATED(committed%stress)) DEALLOCATE(committed%stress)
    IF (ALLOCATED(trial%stress))     DEALLOCATE(trial%stress)
  END SUBROUTINE Run_TC01

  !-- TC-02: Commit swaps statev arrays
  SUBROUTINE Run_TC02(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(Snapshot) :: committed, trial
    INTEGER, PARAMETER :: NIP = 8, NSDV = 12
    WRITE(*,*) '--- TC-02: Commit statev swap ---'
    ALLOCATE(committed%statev(NSDV, NIP))
    ALLOCATE(trial%statev(NSDV, NIP))
    committed%statev = 10.0_wp
    trial%statev     = 20.0_wp
    committed%n_intpts = NIP ; trial%n_intpts = NIP
    committed%n_sdv    = NSDV ; trial%n_sdv    = NSDV
    CALL DoCommit(committed, trial)
    CALL Assert(ALL(ABS(committed%statev - 20.0_wp) < 1.0e-14_wp), &
                'committed%statev == 20.0 after Commit', p, f)
    CALL Assert(ALL(ABS(trial%statev - 10.0_wp) < 1.0e-14_wp), &
                'trial%statev == 10.0 after Commit', p, f)
    IF (ALLOCATED(committed%statev)) DEALLOCATE(committed%statev)
    IF (ALLOCATED(trial%statev))     DEALLOCATE(trial%statev)
  END SUBROUTINE Run_TC02

  !-- TC-03: Rollback restores committed into trial
  SUBROUTINE Run_TC03(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(Snapshot) :: committed, trial
    INTEGER, PARAMETER :: NIP = 4, NSDV = 6
    WRITE(*,*) '--- TC-03: Rollback restores trial ---'
    ALLOCATE(committed%stress(6, NIP))
    ALLOCATE(committed%statev(NSDV, NIP))
    ALLOCATE(trial%stress(6, NIP))
    ALLOCATE(trial%statev(NSDV, NIP))
    committed%stress = 5.0_wp ; committed%statev = 50.0_wp
    trial%stress     = 9.0_wp ; trial%statev     = 90.0_wp
    committed%n_intpts = NIP ; committed%n_sdv = NSDV
    CALL DoRollback(committed, trial)
    CALL Assert(ALL(ABS(trial%stress - 5.0_wp) < 1.0e-14_wp), &
                'trial%stress == committed%stress after Rollback', p, f)
    CALL Assert(ALL(ABS(trial%statev - 50.0_wp) < 1.0e-14_wp), &
                'trial%statev == committed%statev after Rollback', p, f)
    !-- committed must be unchanged
    CALL Assert(ALL(ABS(committed%stress - 5.0_wp) < 1.0e-14_wp), &
                'committed%stress unchanged after Rollback', p, f)
    IF (ALLOCATED(committed%stress)) DEALLOCATE(committed%stress)
    IF (ALLOCATED(committed%statev)) DEALLOCATE(committed%statev)
    IF (ALLOCATED(trial%stress))     DEALLOCATE(trial%stress)
    IF (ALLOCATED(trial%statev))     DEALLOCATE(trial%statev)
  END SUBROUTINE Run_TC03

  !-- TC-04: Multiple Commit cycles remain consistent
  SUBROUTINE Run_TC04(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(Snapshot) :: committed, trial
    INTEGER, PARAMETER :: NIP = 2
    INTEGER :: k
    REAL(wp) :: expected
    WRITE(*,*) '--- TC-04: Multiple Commit cycles ---'
    ALLOCATE(committed%stress(6, NIP))
    ALLOCATE(trial%stress(6, NIP))
    committed%stress = 0.0_wp
    committed%n_intpts = NIP ; trial%n_intpts = NIP
    DO k = 1, 5
      trial%stress = REAL(k, wp) * 1.0_wp
      CALL DoCommit(committed, trial)
      expected = REAL(k, wp)
      CALL Assert(ALL(ABS(committed%stress - expected) < 1.0e-14_wp), &
                  'committed%stress == k after Commit cycle k', p, f)
    END DO
    IF (ALLOCATED(committed%stress)) DEALLOCATE(committed%stress)
    IF (ALLOCATED(trial%stress))     DEALLOCATE(trial%stress)
  END SUBROUTINE Run_TC04

  !-- TC-05: Rollback after Commit returns trial to pre-commit state
  SUBROUTINE Run_TC05(p, f)
    INTEGER, INTENT(INOUT) :: p, f
    TYPE(Snapshot) :: committed, trial
    INTEGER, PARAMETER :: NIP = 3
    WRITE(*,*) '--- TC-05: Rollback after Commit ---'
    ALLOCATE(committed%stress(6, NIP))
    ALLOCATE(trial%stress(6, NIP))
    committed%stress = 1.0_wp
    trial%stress     = 3.0_wp
    committed%n_intpts = NIP ; trial%n_intpts = NIP
    !-- Commit: committed=3, trial=1
    CALL DoCommit(committed, trial)
    !-- Now load new trial that we want to discard
    trial%stress = 99.0_wp
    !-- Rollback: trial should return to committed (=3)
    CALL DoRollback(committed, trial)
    CALL Assert(ALL(ABS(trial%stress - 3.0_wp) < 1.0e-14_wp), &
                'trial%stress == 3.0 after Rollback post-Commit', p, f)
    IF (ALLOCATED(committed%stress)) DEALLOCATE(committed%stress)
    IF (ALLOCATED(trial%stress))     DEALLOCATE(trial%stress)
  END SUBROUTINE Run_TC05

END PROGRAM Test_MatCache_Swap
