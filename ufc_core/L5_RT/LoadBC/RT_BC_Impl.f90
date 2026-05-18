!===============================================================================
! MODULE:  RT_BC_Impl
! LAYER:   L5_RT
! DOMAIN:  BC
! ROLE:    Impl
! BRIEF:   BC implementation logic (thin adapter to L4_PH).
!===============================================================================
MODULE RT_BC_Impl
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID
  USE RT_BC_Impl_Def
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_BC_Init_Impl
  PUBLIC :: RT_BC_Update_Impl
  PUBLIC :: RT_BC_ApplyBCs_Impl
  PUBLIC :: RT_BC_ComputeReactions_Impl
  PUBLIC :: RT_BC_CheckConvergence_Impl
  PUBLIC :: RT_BC_ApplyCutback_Impl
  PUBLIC :: RT_BC_Finalize_Impl

CONTAINS

  SUBROUTINE RT_BC_Init_Impl(desc, state, algo, ctx, analysis_type, &
                              initial_dt, n_bcs, status)
    CLASS(RT_BC_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_BC_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_BC_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_BC_Impl_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: analysis_type, n_bcs
    REAL(wp), INTENT(IN) :: initial_dt
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ctx%analysis_type = analysis_type
    ctx%time_increment = initial_dt
    ctx%step_time = 0.0_wp
    ctx%total_time = 0.0_wp
    algo%auto_cutback_enabled = .TRUE.
    algo%max_cutbacks = 10_i4
    algo%cutback_factor = 0.5_wp
    state%bc_applied = .FALSE.
    state%cutback_active = .FALSE.
    state%total_cutbacks = 0_i4
    desc%n_bcs = n_bcs
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_BC_Update_Impl(desc, state, algo, ctx, step_time, &
                                time_increment, increment_number, &
                                iteration_number, status)
    CLASS(RT_BC_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_BC_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_BC_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_BC_Impl_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: step_time, time_increment
    INTEGER(i4), INTENT(IN) :: increment_number, iteration_number
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ctx%step_time = step_time
    ctx%time_increment = time_increment
    ctx%current_step = increment_number / MAX(1, iteration_number)
    ctx%current_incr = increment_number
    ctx%current_iter = iteration_number
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_BC_ApplyBCs_Impl(desc, state, algo, ctx, bc_dofs, &
                                  bc_values, zero_trust_check, &
                                  n_bcs_applied, status)
    CLASS(RT_BC_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_BC_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_BC_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_BC_Impl_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: bc_dofs(:)
    REAL(wp), INTENT(IN) :: bc_values(:)
    LOGICAL, INTENT(IN) :: zero_trust_check
    INTEGER(i4), INTENT(OUT) :: n_bcs_applied
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ibc

    CALL init_error_status(status)
    n_bcs_applied = 0_i4

    IF (zero_trust_check) THEN
      DO ibc = 1, SIZE(bc_values)
        IF (bc_values(ibc) /= bc_values(ibc)) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = 'NaN detected'
          RETURN
        END IF
      END DO
    END IF

    n_bcs_applied = SIZE(bc_dofs)
    state%bc_applied = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_BC_ComputeReactions_Impl(desc, state, algo, ctx, &
                                          f_reaction, coords, &
                                          compute_moments, reaction_sum, &
                                          status)
    CLASS(RT_BC_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_BC_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_BC_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_BC_Impl_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: f_reaction(:), coords(:,:)
    LOGICAL, INTENT(IN) :: compute_moments
    REAL(wp), INTENT(OUT) :: reaction_sum(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i

    CALL init_error_status(status)
    reaction_sum = 0.0_wp

    IF (SIZE(f_reaction) >= 6) THEN
      reaction_sum(1) = SUM(f_reaction(1::3))
      reaction_sum(2) = SUM(f_reaction(2::3))
      reaction_sum(3) = SUM(f_reaction(3::3))
    END IF

    IF (compute_moments .AND. SIZE(coords, 2) >= 1) THEN
      DO i = 1, MIN(SIZE(f_reaction) / 3, SIZE(coords, 2))
        reaction_sum(4) = reaction_sum(4) &
          + coords(2, i) * f_reaction(3 * i) &
          - coords(3, i) * f_reaction(2 * i)
        reaction_sum(5) = reaction_sum(5) &
          + coords(3, i) * f_reaction(1 * i) &
          - coords(1, i) * f_reaction(3 * i)
        reaction_sum(6) = reaction_sum(6) &
          + coords(1, i) * f_reaction(2 * i) &
          - coords(2, i) * f_reaction(1 * i)
      END DO
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_BC_CheckConvergence_Impl(desc, state, algo, ctx, &
                                          residual_norm, iteration_count, &
                                          converged, do_cutback, status)
    CLASS(RT_BC_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_BC_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_BC_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_BC_Impl_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: residual_norm
    INTEGER(i4), INTENT(IN) :: iteration_count
    LOGICAL, INTENT(OUT) :: converged, do_cutback
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    converged = (residual_norm < algo%load_convergence_tol)
    do_cutback = (.NOT. converged .AND. algo%auto_cutback_enabled)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_BC_ApplyCutback_Impl(desc, state, algo, ctx, &
                                      force_cutback, new_dt, &
                                      cutback_applied, status)
    CLASS(RT_BC_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_BC_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_BC_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_BC_Impl_Ctx), INTENT(INOUT) :: ctx
    LOGICAL, INTENT(IN) :: force_cutback
    REAL(wp), INTENT(OUT) :: new_dt
    LOGICAL, INTENT(OUT) :: cutback_applied
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    cutback_applied = .FALSE.
    new_dt = ctx%time_increment

    IF (force_cutback .OR. state%cutback_active) THEN
      ctx%time_increment = ctx%time_increment * algo%cutback_factor
      new_dt = ctx%time_increment
      state%cutback_active = .TRUE.
      state%total_cutbacks = state%total_cutbacks + 1_i4
      cutback_applied = .TRUE.
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_BC_Finalize_Impl(desc, state, algo, ctx, clear_history, &
                                  finalized, status)
    CLASS(RT_BC_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_BC_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_BC_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_BC_Impl_Ctx), INTENT(INOUT) :: ctx
    LOGICAL, INTENT(IN) :: clear_history
    LOGICAL, INTENT(OUT) :: finalized
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    state%bc_applied = .FALSE.
    state%cutback_active = .FALSE.

    IF (clear_history) THEN
      state%total_cutbacks = 0_i4
      state%total_iterations = 0_i4
      state%accumulated_work = 0.0_wp
    END IF

    ctx%step_time = 0.0_wp
    ctx%time_increment = 0.0_wp
    finalized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

END MODULE RT_BC_Impl
