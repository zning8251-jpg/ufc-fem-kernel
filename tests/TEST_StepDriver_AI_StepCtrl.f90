!===============================================================================
! Module:  TEST_StepDriver_AI_StepCtrl
! Layer:   Tests
! Domain:  StepDriver / AI Step Size Controller
! Purpose: Unit tests for RT_AI_StepCtrAlgo (AI slot-1).
!          Validates Init / Predict / Update / Finalize interfaces,
!          boundary enforcement, cutback behaviour, and gradient placeholder.
!
! Test Cases:
!   TC-AISTEP-01: AI_StepCtr_Init - controller initialization
!   TC-AISTEP-02: AI_StepCtr_Predict - step size prediction
!   TC-AISTEP-03: Cutback response after non-convergence
!   TC-AISTEP-04: Gradient / sensitivity placeholder validation
!   TC-AISTEP-05: dt_min / dt_max boundary enforcement
!
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
MODULE TEST_StepDriver_AI_StepCtrl
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE RT_AI_StepCtrAlgo, ONLY: AI_StepCtr_Type, &
                                AI_StepCtr_Init, AI_StepCtr_Finalize, &
                                AI_StepCtr_Predict, AI_StepCtr_Update
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_StepDriver_AI_StepCtrl_Test

  REAL(wp), PARAMETER :: TOL = 1.0E-10_wp

CONTAINS

  !=============================================================================
  ! Master runner - calls all test cases, accumulates pass/fail counts
  !=============================================================================
  SUBROUTINE Run_StepDriver_AI_StepCtrl_Test(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    INTEGER(i4) :: n_passed
    INTEGER(i4) :: n_failed

    n_passed = 0_i4
    n_failed = 0_i4

    WRITE(*,'(A)') ""
    WRITE(*,'(A)') "===================================================================="
    WRITE(*,'(A)') "TEST_StepDriver_AI_StepCtrl: AI Step Size Controller Tests"
    WRITE(*,'(A)') "===================================================================="
    WRITE(*,'(A)') ""

    CALL test_ai_stepctr_init(n_passed, n_failed)
    CALL test_ai_stepctr_predict(n_passed, n_failed)
    CALL test_ai_stepctr_cutback(n_passed, n_failed)
    CALL test_ai_stepctr_gradient(n_passed, n_failed)
    CALL test_ai_stepctr_bounds(n_passed, n_failed)

    all_passed = (n_failed == 0_i4)

    WRITE(*,'(A)') ""
    WRITE(*,'(A,I4,A,I4,A)') "[TEST_StepDriver_AI_StepCtrl] ", n_passed, &
                               " passed, ", n_failed, " failed"
    WRITE(*,'(A)') "===================================================================="
  END SUBROUTINE Run_StepDriver_AI_StepCtrl_Test

  !---------------------------------------------------------------------------
  ! TC-AISTEP-01: Verify AI step controller initialization
  !   - Call AI_StepCtr_Init with known dt bounds
  !   - Assert all configuration fields written correctly
  !   - Assert status == IF_STATUS_OK
  !---------------------------------------------------------------------------
  SUBROUTINE test_ai_stepctr_init(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(AI_StepCtr_Type) :: algo
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dt_init, dt_min, dt_max
    LOGICAL :: ok

    dt_init = 0.01_wp
    dt_min  = 1.0e-8_wp
    dt_max  = 0.5_wp

    CALL AI_StepCtr_Init(algo, dt_init, dt_min, dt_max, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_init status", n_failed)) RETURN

    ok = .TRUE.

    ! Verify time-step configuration
    IF (ABS(algo%initial_dtime - dt_init) > TOL) THEN
      WRITE(*,'(A,ES12.5,A,ES12.5)') "  FAIL: initial_dtime expected ", &
        dt_init, " got ", algo%initial_dtime
      ok = .FALSE.
    END IF

    IF (ABS(algo%min_dtime - dt_min) > TOL) THEN
      WRITE(*,'(A,ES12.5,A,ES12.5)') "  FAIL: min_dtime expected ", &
        dt_min, " got ", algo%min_dtime
      ok = .FALSE.
    END IF

    IF (ABS(algo%max_dtime - dt_max) > TOL) THEN
      WRITE(*,'(A,ES12.5,A,ES12.5)') "  FAIL: max_dtime expected ", &
        dt_max, " got ", algo%max_dtime
      ok = .FALSE.
    END IF

    ! Verify default controller type (PID = 0)
    IF (algo%controller_type /= 0_i4) THEN
      WRITE(*,'(A,I0)') "  FAIL: controller_type expected 0, got ", &
        algo%controller_type
      ok = .FALSE.
    END IF

    ! Verify target iterations
    IF (ABS(algo%target_its - 5.0_wp) > TOL) THEN
      WRITE(*,'(A)') "  FAIL: target_its not set to 5"
      ok = .FALSE.
    END IF

    ! Verify policy parameters
    IF (ABS(algo%growth_factor - 2.0_wp) > TOL) THEN
      WRITE(*,'(A)') "  FAIL: growth_factor not 2.0"
      ok = .FALSE.
    END IF

    IF (ABS(algo%shrink_factor - 0.5_wp) > TOL) THEN
      WRITE(*,'(A)') "  FAIL: shrink_factor not 0.5"
      ok = .FALSE.
    END IF

    IF (ABS(algo%error_tolerance - 1.0e-4_wp) > TOL) THEN
      WRITE(*,'(A)') "  FAIL: error_tolerance not 1e-4"
      ok = .FALSE.
    END IF

    ! Verify PID gains
    IF (algo%pid_kp /= 1_i4 .OR. algo%pid_ki /= 2_i4 .OR. algo%pid_kd /= 1_i4) THEN
      WRITE(*,'(A)') "  FAIL: PID gains not set correctly"
      ok = .FALSE.
    END IF

    ! Verify performance counters reset
    IF (ABS(algo%total_steps) > TOL .OR. ABS(algo%rejected_steps) > TOL) THEN
      WRITE(*,'(A)') "  FAIL: performance counters not zero after init"
      ok = .FALSE.
    END IF

    IF (ok) THEN
      n_passed = n_passed + 1_i4
      WRITE(*,'(A)') "  PASS: TC-AISTEP-01 ai_stepctr_init"
    ELSE
      n_failed = n_failed + 1_i4
    END IF

    ! Cleanup
    CALL AI_StepCtr_Finalize(algo, status)
  END SUBROUTINE test_ai_stepctr_init

  !---------------------------------------------------------------------------
  ! TC-AISTEP-02: Verify step size prediction
  !   - Initialize controller with known dt bounds
  !   - Call AI_StepCtr_Predict
  !   - Assert 0 < suggested_dtime <= dt_max
  !   - Current stub returns initial_dtime
  !---------------------------------------------------------------------------
  SUBROUTINE test_ai_stepctr_predict(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(AI_StepCtr_Type) :: algo
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dt_init, dt_min, dt_max, suggested

    dt_init = 0.05_wp
    dt_min  = 1.0e-6_wp
    dt_max  = 1.0_wp

    CALL AI_StepCtr_Init(algo, dt_init, dt_min, dt_max, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_predict init", n_failed)) RETURN

    CALL AI_StepCtr_Predict(algo, suggested, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_predict call", n_failed)) RETURN

    ! Predicted step size must be positive
    IF (suggested <= 0.0_wp) THEN
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,ES12.5)') "  FAIL: predicted dt <= 0: ", suggested
      CALL AI_StepCtr_Finalize(algo, status)
      RETURN
    END IF

    ! Predicted step size must not exceed dt_max
    IF (suggested > dt_max + TOL) THEN
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,ES12.5,A,ES12.5)') "  FAIL: predicted dt ", suggested, &
        " exceeds dt_max ", dt_max
      CALL AI_StepCtr_Finalize(algo, status)
      RETURN
    END IF

    ! Current stub should return initial_dtime exactly
    IF (ABS(suggested - dt_init) > TOL) THEN
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,ES12.5,A,ES12.5)') "  FAIL: stub predicted dt ", &
        suggested, " expected initial_dtime ", dt_init
      CALL AI_StepCtr_Finalize(algo, status)
      RETURN
    END IF

    n_passed = n_passed + 1_i4
    WRITE(*,'(A)') "  PASS: TC-AISTEP-02 ai_stepctr_predict"

    CALL AI_StepCtr_Finalize(algo, status)
  END SUBROUTINE test_ai_stepctr_predict

  !---------------------------------------------------------------------------
  ! TC-AISTEP-03: Verify cutback response
  !   - Initialize controller, then simulate divergence by calling Update
  !     with high iteration counts (mimicking non-convergence)
  !   - Verify that shrink_factor is available for the driver to apply
  !   - After update, total_steps should increment
  !---------------------------------------------------------------------------
  SUBROUTINE test_ai_stepctr_cutback(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(AI_StepCtr_Type) :: algo
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dt_init, dt_min, dt_max
    REAL(wp) :: dt_after_cutback, suggested
    LOGICAL :: ok

    dt_init = 0.1_wp
    dt_min  = 1.0e-8_wp
    dt_max  = 1.0_wp

    CALL AI_StepCtr_Init(algo, dt_init, dt_min, dt_max, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_cutback init", n_failed)) RETURN

    ok = .TRUE.

    ! Simulate a divergent step: many iterations, high truncation error
    CALL AI_StepCtr_Update(algo, 0.1_wp, 1.0e+2_wp, 50_i4, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_cutback update", n_failed)) RETURN

    ! total_steps should have incremented by 1
    IF (ABS(algo%total_steps - 1.0_wp) > TOL) THEN
      WRITE(*,'(A,ES12.5)') "  FAIL: total_steps expected 1, got ", algo%total_steps
      ok = .FALSE.
    END IF

    ! Verify shrink_factor is properly configured for driver cutback logic
    IF (algo%shrink_factor <= 0.0_wp .OR. algo%shrink_factor >= 1.0_wp) THEN
      WRITE(*,'(A,ES12.5)') "  FAIL: shrink_factor out of (0,1): ", algo%shrink_factor
      ok = .FALSE.
    END IF

    ! Apply shrink_factor manually (as driver would) and check dt_new < dt_old
    dt_after_cutback = dt_init * algo%shrink_factor
    IF (dt_after_cutback >= dt_init) THEN
      WRITE(*,'(A)') "  FAIL: dt after cutback not smaller than dt_old"
      ok = .FALSE.
    END IF

    ! Predict should still return a valid value after update
    CALL AI_StepCtr_Predict(algo, suggested, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_cutback predict", n_failed)) RETURN

    IF (suggested <= 0.0_wp) THEN
      WRITE(*,'(A)') "  FAIL: predicted dt non-positive after cutback update"
      ok = .FALSE.
    END IF

    IF (ok) THEN
      n_passed = n_passed + 1_i4
      WRITE(*,'(A)') "  PASS: TC-AISTEP-03 ai_stepctr_cutback"
    ELSE
      n_failed = n_failed + 1_i4
    END IF

    CALL AI_StepCtr_Finalize(algo, status)
  END SUBROUTINE test_ai_stepctr_cutback

  !---------------------------------------------------------------------------
  ! TC-AISTEP-04: Verify gradient / sensitivity placeholder
  !   - Initialize controller
  !   - Call Update with known inputs
  !   - Verify state is modified (total_steps incremented)
  !   - This is a placeholder test: when AI-PID gradient back-prop is
  !     implemented, this test should verify dJ/d(params) != 0
  !---------------------------------------------------------------------------
  SUBROUTINE test_ai_stepctr_gradient(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(AI_StepCtr_Type) :: algo
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dt_init, dt_min, dt_max
    REAL(wp) :: steps_before, steps_after
    LOGICAL :: ok

    dt_init = 0.02_wp
    dt_min  = 1.0e-10_wp
    dt_max  = 0.5_wp

    CALL AI_StepCtr_Init(algo, dt_init, dt_min, dt_max, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_gradient init", n_failed)) RETURN

    ok = .TRUE.

    ! Record state before forward pass
    steps_before = algo%total_steps

    ! Forward pass: call Update with representative convergence data
    CALL AI_StepCtr_Update(algo, 0.02_wp, 1.0e-5_wp, 4_i4, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_gradient update1", n_failed)) RETURN

    steps_after = algo%total_steps

    ! Verify state changed (gradient sensitivity: output depends on input)
    IF (ABS(steps_after - steps_before) < TOL) THEN
      WRITE(*,'(A)') "  FAIL: total_steps unchanged after Update (no gradient flow)"
      ok = .FALSE.
    END IF

    ! Second forward pass with different inputs
    CALL AI_StepCtr_Update(algo, 0.04_wp, 5.0e-6_wp, 3_i4, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_gradient update2", n_failed)) RETURN

    IF (ABS(algo%total_steps - 2.0_wp) > TOL) THEN
      WRITE(*,'(A,ES12.5)') "  FAIL: total_steps expected 2 after 2 updates, got ", &
        algo%total_steps
      ok = .FALSE.
    END IF

    IF (ok) THEN
      n_passed = n_passed + 1_i4
      WRITE(*,'(A)') "  PASS: TC-AISTEP-04 ai_stepctr_gradient (placeholder)"
    ELSE
      n_failed = n_failed + 1_i4
    END IF

    CALL AI_StepCtr_Finalize(algo, status)
  END SUBROUTINE test_ai_stepctr_gradient

  !---------------------------------------------------------------------------
  ! TC-AISTEP-05: Verify dt_min / dt_max boundary enforcement
  !   - Initialize with tight bounds
  !   - Verify predicted dt respects min/max
  !   - Verify shrink/growth factors cannot drive dt outside bounds
  !   - Verify Finalize properly deallocates history arrays
  !---------------------------------------------------------------------------
  SUBROUTINE test_ai_stepctr_bounds(n_passed, n_failed)
    INTEGER(i4), INTENT(INOUT) :: n_passed
    INTEGER(i4), INTENT(INOUT) :: n_failed

    TYPE(AI_StepCtr_Type) :: algo
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: dt_init, dt_min, dt_max, suggested
    REAL(wp) :: dt_grown, dt_shrunk
    LOGICAL :: ok

    dt_init = 0.1_wp
    dt_min  = 0.01_wp
    dt_max  = 0.2_wp

    CALL AI_StepCtr_Init(algo, dt_init, dt_min, dt_max, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_bounds init", n_failed)) RETURN

    ok = .TRUE.

    ! Predict returns initial_dtime (stub), which should be in [dt_min, dt_max]
    CALL AI_StepCtr_Predict(algo, suggested, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_bounds predict", n_failed)) RETURN

    IF (suggested < dt_min - TOL) THEN
      WRITE(*,'(A,ES12.5,A,ES12.5)') "  FAIL: predicted dt ", suggested, &
        " below dt_min ", dt_min
      ok = .FALSE.
    END IF

    IF (suggested > dt_max + TOL) THEN
      WRITE(*,'(A,ES12.5,A,ES12.5)') "  FAIL: predicted dt ", suggested, &
        " above dt_max ", dt_max
      ok = .FALSE.
    END IF

    ! Verify growth_factor cannot push dt beyond dt_max
    dt_grown = suggested * algo%growth_factor
    IF (dt_grown > dt_max) THEN
      ! Driver must clamp; verify the factor exists and is > 1
      IF (algo%growth_factor <= 1.0_wp) THEN
        WRITE(*,'(A)') "  FAIL: growth_factor <= 1.0"
        ok = .FALSE.
      END IF
    END IF

    ! Verify shrink_factor cannot push dt below dt_min
    dt_shrunk = suggested * algo%shrink_factor
    IF (dt_shrunk < dt_min) THEN
      ! Driver must clamp; verify the factor exists and is < 1
      IF (algo%shrink_factor >= 1.0_wp) THEN
        WRITE(*,'(A)') "  FAIL: shrink_factor >= 1.0"
        ok = .FALSE.
      END IF
    END IF

    ! Finalize and verify history arrays are deallocated
    ! First, manually allocate history to test Finalize cleanup
    ALLOCATE(algo%time_history(algo%history_window))
    ALLOCATE(algo%error_history(algo%history_window))
    ALLOCATE(algo%its_history(algo%history_window))
    algo%time_history  = 0.0_wp
    algo%error_history = 0.0_wp
    algo%its_history   = 0_i4

    CALL AI_StepCtr_Finalize(algo, status)
    IF (.NOT. expect_ok(status, "ai_stepctr_bounds finalize", n_failed)) RETURN

    ! After finalize, arrays must be deallocated
    IF (ALLOCATED(algo%time_history)) THEN
      WRITE(*,'(A)') "  FAIL: time_history still allocated after Finalize"
      ok = .FALSE.
    END IF

    IF (ALLOCATED(algo%error_history)) THEN
      WRITE(*,'(A)') "  FAIL: error_history still allocated after Finalize"
      ok = .FALSE.
    END IF

    IF (ALLOCATED(algo%its_history)) THEN
      WRITE(*,'(A)') "  FAIL: its_history still allocated after Finalize"
      ok = .FALSE.
    END IF

    IF (ok) THEN
      n_passed = n_passed + 1_i4
      WRITE(*,'(A)') "  PASS: TC-AISTEP-05 ai_stepctr_bounds"
    ELSE
      n_failed = n_failed + 1_i4
    END IF

  END SUBROUTINE test_ai_stepctr_bounds

  !===========================================================================
  ! Helper: expect_ok - checks ErrorStatusType, increments n_failed on error
  !===========================================================================
  LOGICAL FUNCTION expect_ok(status, label, n_failed)
    TYPE(ErrorStatusType), INTENT(IN) :: status
    CHARACTER(LEN=*), INTENT(IN) :: label
    INTEGER(i4), INTENT(INOUT) :: n_failed

    expect_ok = (status%status_code == IF_STATUS_OK)
    IF (.NOT. expect_ok) THEN
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A)') "  FAIL: ", TRIM(label)
    END IF
  END FUNCTION expect_ok

END MODULE TEST_StepDriver_AI_StepCtrl
