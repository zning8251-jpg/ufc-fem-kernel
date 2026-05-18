!===============================================================================
! Module:  RT_LBC_Test
! Layer:   L5_RT
! Domain:  LoadBC
! Purpose: Verify the split runtime Load/BC support facade in RT_LoadBC_Proc.
!===============================================================================
MODULE RT_LBC_Test
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Load_Impl_Def, ONLY: RT_Load_Impl_Desc, RT_Load_Impl_State, &
                              RT_Load_Impl_Algo, RT_Load_Impl_Ctx, RT_LOAD_STATIC
  USE RT_BC_Impl_Def, ONLY: RT_BC_Impl_Desc, RT_BC_Impl_State, &
                            RT_BC_Impl_Algo, RT_BC_Impl_Ctx
  USE RT_LoadBC_Proc, ONLY: RT_LoadBC_Init_Arg, RT_LoadBC_Update_Arg, &
                            RT_LoadBC_ApplyLoads_Arg, RT_LoadBC_ApplyBCs_Arg, &
                            RT_LoadBC_ComputeReactions_Arg, &
                            RT_LoadBC_CheckConvergence_Arg, &
                            RT_LoadBC_ApplyCutback_Arg, RT_LoadBC_Finalize_Arg, &
                            RT_LoadBC_Init, RT_LoadBC_Update, &
                            RT_LoadBC_ApplyLoads, RT_LoadBC_ApplyBCs, &
                            RT_LoadBC_ComputeReactions, &
                            RT_LoadBC_CheckConvergence, &
                            RT_LoadBC_ApplyCutback, RT_LoadBC_Finalize
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_LoadBC_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE RT_LoadBC_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0_i4
    n_failed = 0_i4

    CALL test_load_runtime_path()
    CALL test_bc_runtime_path()

    all_passed = (n_failed == 0_i4)
    WRITE(*,'(A,I4,A,I4,A)') '[RT_LBC_Test] ', n_passed, ' passed, ', &
                              n_failed, ' failed'
  END SUBROUTINE RT_LoadBC_Run_Tests

  SUBROUTINE test_load_runtime_path()
    TYPE(RT_Load_Impl_Desc)  :: desc
    TYPE(RT_Load_Impl_State) :: state
    TYPE(RT_Load_Impl_Algo)  :: algo
    TYPE(RT_Load_Impl_Ctx)   :: ctx
    TYPE(RT_LoadBC_Init_Arg) :: init_args
    TYPE(RT_LoadBC_Update_Arg) :: update_args
    TYPE(RT_LoadBC_ApplyLoads_Arg) :: load_args
    TYPE(RT_LoadBC_CheckConvergence_Arg) :: conv_args
    TYPE(RT_LoadBC_ApplyCutback_Arg) :: cutback_args
    TYPE(RT_LoadBC_Finalize_Arg) :: finalize_args
    REAL(wp), TARGET :: f_external(3)

    desc%is_active = .TRUE.
    init_args%analysis_type = RT_LOAD_STATIC
    init_args%initial_dt = 0.1_wp
    init_args%n_loads = 1_i4
    CALL RT_LoadBC_Init(desc, state, algo, ctx, init_args)
    CALL assert_true(init_args%initialized, 'load init succeeds')
    CALL assert_true(desc%n_loads == 1_i4, 'load init stores n_loads')
    CALL assert_true(ctx%analysis_type == RT_LOAD_STATIC, 'load init stores analysis type')

    update_args%step_time = 0.5_wp
    update_args%time_increment = 0.05_wp
    update_args%increment_number = 2_i4
    update_args%iteration_number = 1_i4
    CALL RT_LoadBC_Update(desc, state, algo, ctx, update_args)
    CALL assert_true(update_args%updated, 'load update succeeds')
    CALL assert_true(ctx%current_incr == 2_i4 .AND. ctx%step_time == 0.5_wp, &
                     'load update stores time bookkeeping')

    f_external = [0.0_wp, -10.0_wp, 0.0_wp]
    state%current_amp = 0.25_wp
    load_args%f_external => f_external
    load_args%load_factor = 2.0_wp
    CALL RT_LoadBC_ApplyLoads(desc, state, algo, ctx, load_args)
    CALL assert_true(load_args%loads_applied, 'load apply succeeds')
    CALL assert_true(ABS(f_external(2) + 5.0_wp) < 1.0e-12_wp, 'load vector scaled by amp and factor')

    conv_args%residual_norm = 1.0e-8_wp
    conv_args%iteration_count = 2_i4
    CALL RT_LoadBC_CheckConvergence(desc, state, algo, ctx, conv_args)
    CALL assert_true(conv_args%converged, 'load convergence accepts small residual')

    conv_args%residual_norm = 1.0_wp
    conv_args%iteration_count = 4_i4
    CALL RT_LoadBC_CheckConvergence(desc, state, algo, ctx, conv_args)
    CALL assert_true(conv_args%do_cutback, 'load convergence requests cutback on large residual')

    cutback_args%force_cutback = .TRUE.
    CALL RT_LoadBC_ApplyCutback(desc, state, algo, ctx, cutback_args)
    CALL assert_true(cutback_args%cutback_applied, 'load cutback applied')
    CALL assert_true(ABS(cutback_args%new_dt - 0.025_wp) < 1.0e-12_wp, 'load cutback updates dt')

    finalize_args%clear_history = .TRUE.
    CALL RT_LoadBC_Finalize(desc, state, algo, ctx, finalize_args)
    CALL assert_true(finalize_args%finalized, 'load finalize succeeds')
    CALL assert_true(state%total_cutbacks == 0_i4, 'load finalize clears history on request')
  END SUBROUTINE test_load_runtime_path

  SUBROUTINE test_bc_runtime_path()
    TYPE(RT_BC_Impl_Desc)  :: desc
    TYPE(RT_BC_Impl_State) :: state
    TYPE(RT_BC_Impl_Algo)  :: algo
    TYPE(RT_BC_Impl_Ctx)   :: ctx
    TYPE(RT_LoadBC_Init_Arg) :: init_args
    TYPE(RT_LoadBC_Update_Arg) :: update_args
    TYPE(RT_LoadBC_ApplyBCs_Arg) :: bc_args
    TYPE(RT_LoadBC_ComputeReactions_Arg) :: reaction_args
    TYPE(RT_LoadBC_CheckConvergence_Arg) :: conv_args
    TYPE(RT_LoadBC_ApplyCutback_Arg) :: cutback_args
    TYPE(RT_LoadBC_Finalize_Arg) :: finalize_args
    INTEGER(i4), TARGET :: bc_dofs(2)
    REAL(wp), TARGET :: bc_values(2)
    REAL(wp), TARGET :: f_reaction(6)
    REAL(wp), TARGET :: coords(3,2)

    desc%is_active = .TRUE.
    init_args%analysis_type = 1_i4
    init_args%initial_dt = 0.2_wp
    init_args%n_bcs = 2_i4
    CALL RT_LoadBC_Init(desc, state, algo, ctx, init_args)
    CALL assert_true(init_args%initialized, 'bc init succeeds')
    CALL assert_true(desc%n_bcs == 2_i4, 'bc init stores n_bcs')

    update_args%step_time = 0.25_wp
    update_args%time_increment = 0.1_wp
    update_args%increment_number = 3_i4
    update_args%iteration_number = 2_i4
    CALL RT_LoadBC_Update(desc, state, algo, ctx, update_args)
    CALL assert_true(update_args%updated, 'bc update succeeds')
    CALL assert_true(state%total_iterations == 2_i4, 'bc update tracks iterations')

    bc_dofs = [1_i4, 2_i4]
    bc_values = [0.0_wp, 1.5_wp]
    bc_args%bc_dofs => bc_dofs
    bc_args%bc_values => bc_values
    CALL RT_LoadBC_ApplyBCs(desc, state, algo, ctx, bc_args)
    CALL assert_true(bc_args%bcs_applied, 'bc apply succeeds')
    CALL assert_true(bc_args%n_bcs_applied == 2_i4, 'bc apply counts constrained dofs')

    f_reaction = [1.0_wp, 2.0_wp, 3.0_wp, 4.0_wp, 5.0_wp, 6.0_wp]
    coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
    reaction_args%f_reaction => f_reaction
    reaction_args%coords => coords
    CALL RT_LoadBC_ComputeReactions(desc, state, algo, ctx, reaction_args)
    CALL assert_true(reaction_args%computed, 'bc reaction recovery succeeds')
    CALL assert_true(ABS(reaction_args%reaction_sum(1) - 5.0_wp) < 1.0e-12_wp .AND. &
                     ABS(reaction_args%reaction_sum(2) - 7.0_wp) < 1.0e-12_wp .AND. &
                     ABS(reaction_args%reaction_sum(3) - 9.0_wp) < 1.0e-12_wp, &
                     'bc reaction sums are accumulated correctly')

    conv_args%residual_norm = 1.0e-8_wp
    conv_args%iteration_count = 1_i4
    CALL RT_LoadBC_CheckConvergence(desc, state, algo, ctx, conv_args)
    CALL assert_true(conv_args%converged, 'bc convergence accepts small residual')

    cutback_args%force_cutback = .TRUE.
    CALL RT_LoadBC_ApplyCutback(desc, state, algo, ctx, cutback_args)
    CALL assert_true(cutback_args%cutback_applied, 'bc cutback applied')

    finalize_args%clear_history = .TRUE.
    CALL RT_LoadBC_Finalize(desc, state, algo, ctx, finalize_args)
    CALL assert_true(finalize_args%finalized, 'bc finalize succeeds')
    CALL assert_true(state%total_cutbacks == 0_i4, 'bc finalize clears history on request')
  END SUBROUTINE test_bc_runtime_path

  SUBROUTINE assert_true(condition, message)
    LOGICAL, INTENT(IN) :: condition
    CHARACTER(len=*), INTENT(IN) :: message

    IF (condition) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A)') '  FAIL: ', TRIM(message)
    END IF
  END SUBROUTINE assert_true

END MODULE RT_LBC_Test
