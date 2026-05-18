!===============================================================================
! MODULE:  RT_Load_Impl
! LAYER:   L5_RT
! DOMAIN:  Load
! ROLE:    Impl
! BRIEF:   Load implementation logic (thin adapter to L4_PH).
!===============================================================================
MODULE RT_Load_Impl
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID
  USE RT_Load_Impl_Def
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Load_Init_Impl
  PUBLIC :: RT_Load_Update_Impl
  PUBLIC :: RT_Load_ApplyLoads_Impl
  PUBLIC :: RT_Load_CheckConvergence_Impl
  PUBLIC :: RT_Load_ApplyCutback_Impl
  PUBLIC :: RT_Load_Finalize_Impl

CONTAINS

  SUBROUTINE RT_Load_Init_Impl(desc, state, algo, ctx, analysis_type, &
                                nlgeom, initial_dt, n_loads, status)
    CLASS(RT_Load_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_Load_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_Load_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_Load_Impl_Ctx), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: analysis_type, n_loads
    LOGICAL, INTENT(IN) :: nlgeom
    REAL(wp), INTENT(IN) :: initial_dt
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    ctx%analysis_type = analysis_type
    ctx%nlgeom = nlgeom
    ctx%time_increment = initial_dt
    ctx%step_time = 0.0_wp
    ctx%total_time = 0.0_wp
    algo%auto_cutback_enabled = .TRUE.
    algo%max_cutbacks = 10_i4
    algo%cutback_factor = 0.5_wp
    state%load_applied = .FALSE.
    state%cutback_active = .FALSE.
    state%total_cutbacks = 0_i4
    desc%n_loads = n_loads
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_Load_Update_Impl(desc, state, algo, ctx, step_time, &
                                  time_increment, increment_number, &
                                  iteration_number, status)
    CLASS(RT_Load_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_Load_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_Load_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_Load_Impl_Ctx), INTENT(INOUT) :: ctx
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

  SUBROUTINE RT_Load_ApplyLoads_Impl(desc, state, algo, ctx, f_external, &
                                      load_factor, applied_load_norm, status)
    CLASS(RT_Load_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_Load_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_Load_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_Load_Impl_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(INOUT) :: f_external(:)
    REAL(wp), INTENT(IN) :: load_factor
    REAL(wp), INTENT(OUT) :: applied_load_norm
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    f_external = f_external * state%current_amp * load_factor
    applied_load_norm = SQRT(SUM(f_external ** 2))
    state%load_applied = .TRUE.
    state%state_committed = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_Load_CheckConvergence_Impl(desc, state, algo, ctx, &
                                            residual_norm, iteration_count, &
                                            converged, do_cutback, status)
    CLASS(RT_Load_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_Load_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_Load_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_Load_Impl_Ctx), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: residual_norm
    INTEGER(i4), INTENT(IN) :: iteration_count
    LOGICAL, INTENT(OUT) :: converged, do_cutback
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    converged = (residual_norm < 1.0e-6_wp)
    do_cutback = (.NOT. converged .AND. algo%auto_cutback_enabled)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

  SUBROUTINE RT_Load_ApplyCutback_Impl(desc, state, algo, ctx, force_cutback, &
                                        new_dt, cutback_applied, status)
    CLASS(RT_Load_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_Load_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_Load_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_Load_Impl_Ctx), INTENT(INOUT) :: ctx
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

  SUBROUTINE RT_Load_Finalize_Impl(desc, state, algo, ctx, clear_history, &
                                    finalized, status)
    CLASS(RT_Load_Impl_Desc), INTENT(INOUT) :: desc
    CLASS(RT_Load_Impl_State), INTENT(INOUT) :: state
    CLASS(RT_Load_Impl_Algo), INTENT(INOUT) :: algo
    CLASS(RT_Load_Impl_Ctx), INTENT(INOUT) :: ctx
    LOGICAL, INTENT(IN) :: clear_history
    LOGICAL, INTENT(OUT) :: finalized
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    state%load_applied = .FALSE.
    state%cutback_active = .FALSE.

    IF (clear_history) THEN
      state%total_cutbacks = 0_i4
      state%accumulated_work = 0.0_wp
    END IF

    finalized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE

END MODULE RT_Load_Impl
