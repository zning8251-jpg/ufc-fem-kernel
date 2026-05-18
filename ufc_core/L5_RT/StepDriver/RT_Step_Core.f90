!===============================================================================
! MODULE: RT_Step_Core
! LAYER:  L5_RT
! DOMAIN: StepDriver
! ROLE:   Core — Three-level state machine (Step/Increment/Iteration)
! BRIEF:  Drive/Cutback/Converge procedures (P2 time-phase).
!
! Three-level State Machine:
!   Level 1 (Step):      IDLE → RUNNING → CONVERGED → COMPLETED
!   Level 2 (Increment): IDLE → PREDICTING → ITERATING → CONVERGED
!   Level 3 (Iteration): NOT_STARTED → ASSEMBLING → SOLVING → UPDATING
!                         → CHECKING → CONVERGED|CONTINUING|DIVERGED
!
! Four-type signature: (desc, state, algo, ctx, status)
!   desc  — RT_Step_Desc  [IN]    step config
!   state — RT_Step_State [INOUT] step-level tracking (Level 1)
!   algo  — RT_Step_Algo  [IN]    adaptive strategy
!   ctx   — RT_Step_Ctx   [INOUT] increment/iteration scratch (Level 2+3)
!
! Status: DEMO/FACADE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Step_Core
  USE IF_Prec_Core,          ONLY: wp, i4
  USE IF_Err_Brg,       ONLY: ErrorStatusType, init_error_status, &
                              IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Step_Args, ONLY: RT_Step_NR_Arg, RT_Step_Solve_Arg, &
                              RT_Step_AsmSolve_Interface, RT_Step_UpdateState_Interface
  USE RT_Step_Def, ONLY: RT_Step_Desc, RT_Step_State, &
                               RT_Step_Algo, RT_Step_Ctx, &
                               RT_STEP_IDLE, RT_STEP_RUNNING, &
                               RT_STEP_CONVERGED, RT_STEP_CUTBACK, &
                               RT_STEP_FAILED, RT_STEP_COMPLETED, &
                               RT_INC_IDLE, RT_INC_PREDICTING, &
                               RT_INC_ITERATING, RT_INC_CONVERGED, &
                               RT_INC_CUTBACK, RT_INC_FAILED, &
                               RT_ITER_NOT_STARTED, RT_ITER_ASSEMBLING, &
                               RT_ITER_SOLVING, RT_ITER_UPDATING, &
                               RT_ITER_CHECKING, RT_ITER_CONVERGED, &
                               RT_ITER_CONTINUING, RT_ITER_DIVERGED
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_StepDriver_Core_Init
  PUBLIC :: RT_StepDriver_Core_Finalize
  PUBLIC :: RT_StepDriver_Begin_Step
  PUBLIC :: RT_StepDriver_End_Step
  PUBLIC :: RT_StepDriver_Begin_Increment
  PUBLIC :: RT_StepDriver_End_Increment
  PUBLIC :: RT_StepDriver_Advance_Time
  PUBLIC :: RT_StepDriver_Cutback
  PUBLIC :: RT_StepDriver_Check_Step_Complete
  PUBLIC :: RT_StepDriver_Get_Current_Time
  PUBLIC :: RT_StepDriver_Get_DT
  PUBLIC :: RT_StepDriver_NR_Increment
  PUBLIC :: RT_StepDriver_Run_Step
  ! Phase 3E: Arg-based SIO wrappers
  PUBLIC :: RT_StepDriver_NR_Increment_WithArg
  PUBLIC :: RT_StepDriver_Run_Step_WithArg

CONTAINS

  !---------------------------------------------------------------------------
  ! Config | Init | COLD_PATH
  !   Resets all three levels to initial state.
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_Core_Init(desc, state, algo, ctx, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Algo),    INTENT(IN)    :: algo
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! Level 1: Step
    state%stp%step_status    = RT_STEP_IDLE
    state%inc%inc_num        = 0
    state%stp%n_cutbacks     = 0
    state%stp%total_iters    = 0
    state%inc%total_incs     = 0
    state%inc%time_current   = desc%inc%time_start
    state%inc%dt             = desc%inc%dt_init
    state%stp%total_cpu_time = 0.0_wp
    ! Level 2: Increment
    ctx%inc%inc_status       = RT_INC_IDLE
    ctx%inc%dt_trial         = 0.0_wp
    ctx%inc%time_at_inc_start= 0.0_wp
    ctx%inc%inc_converged    = .FALSE.
    ! Level 3: Iteration
    ctx%itr%ctrl%iter_status      = RT_ITER_NOT_STARTED
    ctx%itr%ctrl%inc_iters        = 0
    ctx%itr%ctrl%inc_iters_max    = 0
    ctx%itr%residual%res_norm_0       = 0.0_wp
    ctx%itr%residual%res_norm         = 0.0_wp
    ctx%itr%residual%res_norm_prev    = 0.0_wp
    ctx%itr%metrics%disp_norm        = 0.0_wp
    ctx%itr%metrics%conv_rate        = 0.0_wp
    ctx%itr%metrics%pnewdt           = 1.0_wp
    ! Phase6 §2.3: step-level scratch vector (pointer); NR/assembly may bind slices later.
    IF (ASSOCIATED(ctx%work_vec)) DEALLOCATE (ctx%work_vec)
    ALLOCATE (ctx%work_vec(4096))
    ctx%work_vec = 0.0_wp
    status%status_code   = IF_STATUS_OK
  END SUBROUTINE RT_StepDriver_Core_Init

  !---------------------------------------------------------------------------
  ! Config | Finalize | COLD_PATH
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_Core_Finalize(state, ctx, status)
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%stp%step_status  = RT_STEP_IDLE
    ctx%inc%inc_status     = RT_INC_IDLE
    ctx%itr%ctrl%iter_status    = RT_ITER_NOT_STARTED
    ctx%inc%inc_converged  = .FALSE.
    IF (ASSOCIATED(ctx%work_vec)) DEALLOCATE (ctx%work_vec)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_StepDriver_Core_Finalize

  !---------------------------------------------------------------------------
  ! Step | Begin | COLD_PATH
  !   Level 1: IDLE → RUNNING
  !   Level 2: → IDLE (ready for first increment)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_Begin_Step(desc, state, ctx, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ! Level 1
    state%inc%time_current    = desc%inc%time_start
    state%inc%dt              = desc%inc%dt_init
    state%inc%inc_num         = 0
    state%stp%n_cutbacks      = 0
    state%stp%total_iters     = 0
    state%inc%total_incs      = 0
    state%stp%step_status     = RT_STEP_RUNNING
    ! Level 2: reset for first increment
    ctx%inc%inc_status        = RT_INC_IDLE
    ctx%inc%dt_trial          = desc%inc%dt_init
    ctx%inc%time_at_inc_start = desc%inc%time_start
    ! Level 3: reset
    ctx%itr%ctrl%iter_status       = RT_ITER_NOT_STARTED
    status%status_code    = IF_STATUS_OK
  END SUBROUTINE RT_StepDriver_Begin_Step

  !---------------------------------------------------------------------------
  ! Step | End | COLD_PATH
  !   Level 1: → COMPLETED
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_End_Step(state, status)
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    state%stp%step_status  = RT_STEP_COMPLETED
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_StepDriver_End_Step

  !---------------------------------------------------------------------------
  ! Increment | Begin | HOT_PATH
  !   Level 2: IDLE → PREDICTING → ITERATING
  !   Level 3: → NOT_STARTED (ready for first NR iteration)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_Begin_Increment(desc, state, ctx, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%inc%inc_num   = state%inc%inc_num + 1
    state%inc%total_incs = state%inc%total_incs + 1
    IF (state%inc%inc_num > desc%inc%max_inc) THEN
      state%stp%step_status  = RT_STEP_FAILED
      ctx%inc%inc_status     = RT_INC_FAILED
      status%status_code = IF_STATUS_INVALID
      status%message     = "max increments exceeded"
      RETURN
    END IF

    ! Level 2: begin increment
    ctx%inc%inc_status        = RT_INC_PREDICTING
    ctx%inc%time_at_inc_start = state%inc%time_current
    ctx%inc%dt_trial          = state%inc%dt
    IF (state%inc%time_current + state%inc%dt > desc%inc%time_end) THEN
      state%inc%dt   = desc%inc%time_end - state%inc%time_current
      ctx%inc%dt_trial = state%inc%dt
    END IF
    ctx%inc%inc_converged = .FALSE.

    ! Level 3: reset iteration diagnostics
    ctx%itr%ctrl%iter_status   = RT_ITER_NOT_STARTED
    ctx%itr%ctrl%inc_iters     = 0
    ctx%itr%ctrl%inc_iters_max = desc%itr%nr_max_iter
    ctx%itr%residual%res_norm_0    = 0.0_wp
    ctx%itr%residual%res_norm      = 0.0_wp
    ctx%itr%residual%res_norm_prev = 0.0_wp
    ctx%itr%metrics%disp_norm     = 0.0_wp
    ctx%itr%metrics%conv_rate     = 0.0_wp
    ctx%itr%metrics%pnewdt        = 1.0_wp

    ! Transition Level 2: PREDICTING → ITERATING
    ctx%inc%inc_status     = RT_INC_ITERATING
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_StepDriver_Begin_Increment

  !---------------------------------------------------------------------------
  ! Increment | End | HOT_PATH
  !   Level 2: ITERATING → CONVERGED | CUTBACK
  !   Linkage: Level 2 result propagates to Level 1
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_End_Increment(desc, state, algo, ctx, &
                                          converged, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Algo),    INTENT(IN)    :: algo
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    LOGICAL,               INTENT(IN)    :: converged
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    ctx%inc%inc_converged = converged

    IF (converged) THEN
      ! Level 2 → CONVERGED, Level 1 → CONVERGED
      ctx%inc%inc_status    = RT_INC_CONVERGED
      state%stp%step_status = RT_STEP_CONVERGED
      state%stp%n_cutbacks  = 0
      CALL RT_StepDriver_Advance_Time(state, ctx, status)
      ! Adaptive dt growth
      IF (algo%stp%auto_dt) THEN
        IF (ctx%itr%ctrl%inc_iters <= INT(algo%stp%target_iters * algo%stp%growth_threshold)) THEN
          state%inc%dt = MIN(state%inc%dt * algo%stp%growth_factor, desc%inc%dt_max)
        END IF
      END IF
      ! Level 2 → IDLE (ready for next increment)
      ctx%inc%inc_status = RT_INC_IDLE
    ELSE
      ! Level 2 → CUTBACK
      ctx%inc%inc_status = RT_INC_CUTBACK
      CALL RT_StepDriver_Cutback(desc, state, algo, ctx, status)
      ! Level 2 → IDLE (for retry)
      IF (state%stp%step_status /= RT_STEP_FAILED) THEN
        ctx%inc%inc_status = RT_INC_IDLE
      END IF
    END IF
  END SUBROUTINE RT_StepDriver_End_Increment

  !---------------------------------------------------------------------------
  ! Increment | Advance | HOT_PATH
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_Advance_Time(state, ctx, status)
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Ctx),     INTENT(IN)    :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    state%inc%time_current = state%inc%time_current + ctx%inc%dt_trial
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_StepDriver_Advance_Time

  !---------------------------------------------------------------------------
  ! Increment | Cutback | HOT_PATH
  !   Level 2 → CUTBACK, Level 1 → CUTBACK | FAILED
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_Cutback(desc, state, algo, ctx, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Algo),    INTENT(IN)    :: algo
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%stp%n_cutbacks = state%stp%n_cutbacks + 1
    IF (state%stp%n_cutbacks > desc%inc%max_cutbacks) THEN
      state%stp%step_status  = RT_STEP_FAILED
      ctx%inc%inc_status     = RT_INC_FAILED
      status%status_code = IF_STATUS_INVALID
      status%message     = "max cutbacks exceeded"
      RETURN
    END IF

    state%inc%dt = state%inc%dt * algo%stp%cutback_factor
    IF (state%inc%dt < desc%inc%dt_min) THEN
      state%stp%step_status  = RT_STEP_FAILED
      ctx%inc%inc_status     = RT_INC_FAILED
      status%status_code = IF_STATUS_INVALID
      status%message     = "dt below minimum"
      RETURN
    END IF

    state%stp%step_status  = RT_STEP_CUTBACK
    state%inc%time_current = ctx%inc%time_at_inc_start
    state%inc%inc_num      = state%inc%inc_num - 1
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_StepDriver_Cutback

  !---------------------------------------------------------------------------
  ! Step | Check | COLD_PATH
  !---------------------------------------------------------------------------
  FUNCTION RT_StepDriver_Check_Step_Complete(desc, state) RESULT(done)
    TYPE(RT_Step_Desc),  INTENT(IN) :: desc
    TYPE(RT_Step_State), INTENT(IN) :: state
    LOGICAL :: done
    done = (state%inc%time_current >= desc%inc%time_end - 1.0E-15_wp) &
      .OR. (state%stp%step_status == RT_STEP_COMPLETED) &
      .OR. (state%stp%step_status == RT_STEP_FAILED)
  END FUNCTION RT_StepDriver_Check_Step_Complete

  FUNCTION RT_StepDriver_Get_Current_Time(state) RESULT(t)
    TYPE(RT_Step_State), INTENT(IN) :: state
    REAL(wp) :: t
    t = state%inc%time_current
  END FUNCTION RT_StepDriver_Get_Current_Time

  FUNCTION RT_StepDriver_Get_DT(state) RESULT(dt)
    TYPE(RT_Step_State), INTENT(IN) :: state
    REAL(wp) :: dt
    dt = state%inc%dt
  END FUNCTION RT_StepDriver_Get_DT

  !---------------------------------------------------------------------------
  ! Iteration | NR Loop | HOT_PATH
  !   Level 3 state machine: full cycle per NR iteration
  !     ASSEMBLING → SOLVING → UPDATING → CHECKING → CONVERGED|CONTINUING
  !   Level 2: ITERATING throughout; transitions at end
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_NR_Increment(desc, state, algo, ctx, &
                                         n_dof, u, du, &
                                         assemble_and_solve, &
                                         update_state, &
                                         nr_tol, nr_maxiter, &
                                         converged, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Algo),    INTENT(IN)    :: algo
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    INTEGER(i4),           INTENT(IN)    :: n_dof
    REAL(wp),              INTENT(INOUT) :: u(n_dof)
    REAL(wp),              INTENT(INOUT) :: du(n_dof)
    EXTERNAL                             :: assemble_and_solve
    EXTERNAL                             :: update_state
    REAL(wp),              INTENT(IN)    :: nr_tol
    INTEGER(i4),           INTENT(IN)    :: nr_maxiter
    LOGICAL,               INTENT(OUT)   :: converged
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: iter
    REAL(wp)    :: rnorm
    TYPE(ErrorStatusType) :: sub_status

    CALL init_error_status(status)
    converged = .FALSE.

    IF (ASSOCIATED(ctx%work_vec) .AND. SIZE(ctx%work_vec) >= n_dof) THEN
      ctx%work_vec(1:n_dof) = 0.0_wp
    END IF

    DO iter = 1, nr_maxiter
      !--- Level 3: ASSEMBLING ---
      ctx%itr%ctrl%iter_status = RT_ITER_ASSEMBLING

      !--- Level 3: SOLVING (assemble + solve combined callback) ---
      ctx%itr%ctrl%iter_status = RT_ITER_SOLVING
      IF (ASSOCIATED(ctx%work_vec) .AND. SIZE(ctx%work_vec) >= n_dof) THEN
        ctx%work_vec(1:n_dof) = du(1:n_dof)
      END IF
      CALL assemble_and_solve(u, du, rnorm, sub_status)
      IF (sub_status%status_code /= IF_STATUS_OK) THEN
        ctx%itr%ctrl%iter_status = RT_ITER_DIVERGED
        status = sub_status
        RETURN
      END IF

      !--- Level 3: UPDATING ---
      ctx%itr%ctrl%iter_status = RT_ITER_UPDATING
      IF (iter == 1) ctx%itr%residual%res_norm_0 = MAX(rnorm, 1.0E-30_wp)
      ctx%itr%residual%res_norm_prev = ctx%itr%residual%res_norm
      ctx%itr%residual%res_norm      = rnorm
      IF (iter > 1 .AND. ctx%itr%residual%res_norm_prev > 1.0E-30_wp) THEN
        ctx%itr%metrics%conv_rate = ctx%itr%residual%res_norm / ctx%itr%residual%res_norm_prev
      END IF

      u(1:n_dof) = u(1:n_dof) + du(1:n_dof)
      ctx%itr%ctrl%inc_iters     = iter
      state%stp%total_iters = state%stp%total_iters + 1

      !--- Level 3: CHECKING ---
      ctx%itr%ctrl%iter_status = RT_ITER_CHECKING

      IF (rnorm / ctx%itr%residual%res_norm_0 < nr_tol .OR. rnorm < 1.0E-12_wp) THEN
        !--- Level 3: CONVERGED ---
        ctx%itr%ctrl%iter_status = RT_ITER_CONVERGED
        converged = .TRUE.
        CALL update_state(u, du, sub_status)
        EXIT
      ELSE IF (ctx%itr%metrics%conv_rate > 1.0_wp .AND. iter > 3) THEN
        !--- Level 3: DIVERGED (residual growing after 3+ iterations) ---
        ctx%itr%ctrl%iter_status = RT_ITER_DIVERGED
        EXIT
      ELSE
        !--- Level 3: CONTINUING ---
        ctx%itr%ctrl%iter_status = RT_ITER_CONTINUING
      END IF
    END DO

    IF (.NOT. converged .AND. ctx%itr%ctrl%iter_status /= RT_ITER_DIVERGED) THEN
      ctx%itr%ctrl%iter_status = RT_ITER_DIVERGED
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_StepDriver_NR_Increment

  !---------------------------------------------------------------------------
  ! Step | Run | HOT_PATH
  !   Full three-level loop: Step → Increment → NR Iteration
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_Run_Step(desc, state, algo, ctx, &
                                     n_dof, u, du, &
                                     assemble_and_solve, &
                                     update_state, &
                                     nr_tol, nr_maxiter, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Algo),    INTENT(IN)    :: algo
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    INTEGER(i4),           INTENT(IN)    :: n_dof
    REAL(wp),              INTENT(INOUT) :: u(n_dof)
    REAL(wp),              INTENT(INOUT) :: du(n_dof)
    EXTERNAL                             :: assemble_and_solve
    EXTERNAL                             :: update_state
    REAL(wp),              INTENT(IN)    :: nr_tol
    INTEGER(i4),           INTENT(IN)    :: nr_maxiter
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    LOGICAL :: converged, step_done
    TYPE(ErrorStatusType) :: sub_status

    CALL init_error_status(status)
    CALL RT_StepDriver_Begin_Step(desc, state, ctx, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    step_done = .FALSE.
    DO WHILE (.NOT. step_done)
      CALL RT_StepDriver_Begin_Increment(desc, state, ctx, sub_status)
      IF (sub_status%status_code /= IF_STATUS_OK) THEN
        status = sub_status
        RETURN
      END IF

      CALL RT_StepDriver_NR_Increment(desc, state, algo, ctx, &
                                       n_dof, u, du, &
                                       assemble_and_solve, &
                                       update_state, &
                                       nr_tol, nr_maxiter, &
                                       converged, sub_status)

      CALL RT_StepDriver_End_Increment(desc, state, algo, ctx, &
                                        converged, sub_status)

      step_done = RT_StepDriver_Check_Step_Complete(desc, state)
      IF (state%stp%step_status == RT_STEP_FAILED) THEN
        status%status_code = IF_STATUS_INVALID
        status%message     = "step failed"
        RETURN
      END IF
    END DO

    CALL RT_StepDriver_End_Step(state, status)
  END SUBROUTINE RT_StepDriver_Run_Step

  !=============================================================================
  ! Phase 3E: Arg-based SIO wrappers
  !   Standard signature: (desc, state, algo, ctx, arg, asm_solve, upd_state, status)
  !   Note: EXTERNAL callbacks cannot be embedded in Fortran TYPEs,
  !         so assemble_and_solve/update_state remain separate PROCEDURE arguments.
  !=============================================================================

  !---------------------------------------------------------------------------
  ! RT_StepDriver_NR_Increment_WithArg
  ! Legacy: 12 params → (desc, state, algo, ctx, arg, callbacks, status)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_NR_Increment_WithArg(desc, state, algo, ctx, arg, &
                                                  assemble_and_solve, &
                                                  update_state, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Algo),    INTENT(IN)    :: algo
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    TYPE(RT_Step_NR_Arg),  INTENT(INOUT) :: arg
    EXTERNAL                             :: assemble_and_solve
    EXTERNAL                             :: update_state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL RT_StepDriver_NR_Increment(desc, state, algo, ctx, &
                                     arg%pop%n_dof, arg%u, arg%du, &
                                     assemble_and_solve, update_state, &
                                     arg%nr_tol, arg%nr_maxiter, &
                                     arg%converged, status)
  END SUBROUTINE RT_StepDriver_NR_Increment_WithArg

  !---------------------------------------------------------------------------
  ! RT_StepDriver_Run_Step_WithArg
  ! Legacy: 11 params → (desc, state, algo, ctx, arg, callbacks, status)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_StepDriver_Run_Step_WithArg(desc, state, algo, ctx, arg, &
                                              assemble_and_solve, &
                                              update_state, status)
    TYPE(RT_Step_Desc),    INTENT(IN)    :: desc
    TYPE(RT_Step_State),   INTENT(INOUT) :: state
    TYPE(RT_Step_Algo),    INTENT(IN)    :: algo
    TYPE(RT_Step_Ctx),     INTENT(INOUT) :: ctx
    TYPE(RT_Step_Solve_Arg), INTENT(INOUT) :: arg
    EXTERNAL                             :: assemble_and_solve
    EXTERNAL                             :: update_state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL RT_StepDriver_Run_Step(desc, state, algo, ctx, &
                                 arg%pop%n_dof, arg%u, arg%du, &
                                 assemble_and_solve, update_state, &
                                 arg%nr_tol, arg%nr_maxiter, status)
  END SUBROUTINE RT_StepDriver_Run_Step_WithArg

END MODULE RT_Step_Core
