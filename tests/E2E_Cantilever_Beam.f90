!===============================================================================
! Program: E2E_Cantilever_Beam
! Purpose: Split-runtime smoke test for LoadBC support on a cantilever-like case.
!===============================================================================
PROGRAM E2E_Cantilever_Beam
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Load_Impl_Def, ONLY: RT_Load_Impl_Desc, RT_Load_Impl_State, &
                              RT_Load_Impl_Algo, RT_Load_Impl_Ctx, RT_LOAD_STATIC
  USE RT_BC_Impl_Def, ONLY: RT_BC_Impl_Desc, RT_BC_Impl_State, &
                            RT_BC_Impl_Algo, RT_BC_Impl_Ctx
  USE RT_LoadBC_Proc, ONLY: RT_LoadBC_Init_Arg, RT_LoadBC_Update_Arg, &
                            RT_LoadBC_ApplyLoads_Arg, RT_LoadBC_ApplyBCs_Arg, &
                            RT_LoadBC_ComputeReactions_Arg, &
                            RT_LoadBC_Init, RT_LoadBC_Update, &
                            RT_LoadBC_ApplyLoads, RT_LoadBC_ApplyBCs, &
                            RT_LoadBC_ComputeReactions
  IMPLICIT NONE

  TYPE(RT_Load_Impl_Desc)  :: load_desc
  TYPE(RT_Load_Impl_State) :: load_state
  TYPE(RT_Load_Impl_Algo)  :: load_algo
  TYPE(RT_Load_Impl_Ctx)   :: load_ctx
  TYPE(RT_BC_Impl_Desc)    :: bc_desc
  TYPE(RT_BC_Impl_State)   :: bc_state
  TYPE(RT_BC_Impl_Algo)    :: bc_algo
  TYPE(RT_BC_Impl_Ctx)     :: bc_ctx
  TYPE(RT_LoadBC_Init_Arg) :: init_args
  TYPE(RT_LoadBC_Update_Arg) :: update_args
  TYPE(RT_LoadBC_ApplyLoads_Arg) :: load_args
  TYPE(RT_LoadBC_ApplyBCs_Arg) :: bc_args
  TYPE(RT_LoadBC_ComputeReactions_Arg) :: reaction_args
  REAL(wp), TARGET :: global_force(3)
  INTEGER(i4), TARGET :: bc_dofs(1)
  REAL(wp), TARGET :: bc_values(1)
  REAL(wp), TARGET :: reaction_input(6)
  REAL(wp), TARGET :: coords(3,2)
  LOGICAL :: passed

  PRINT *, '=========================================='
  PRINT *, 'E2E Test: Cantilever Beam (split LoadBC smoke)'
  PRINT *, '=========================================='

  passed = .TRUE.
  load_desc%is_active = .TRUE.
  bc_desc%is_active = .TRUE.

  init_args%analysis_type = RT_LOAD_STATIC
  init_args%initial_dt = 0.1_wp
  init_args%n_loads = 1_i4
  init_args%n_bcs = 1_i4
  CALL RT_LoadBC_Init(load_desc, load_state, load_algo, load_ctx, init_args)
  IF (.NOT. init_args%initialized) THEN
    PRINT *, 'FAIL: load initialization failed'
    passed = .FALSE.
  END IF
  CALL RT_LoadBC_Init(bc_desc, bc_state, bc_algo, bc_ctx, init_args)
  IF (.NOT. init_args%initialized) THEN
    PRINT *, 'FAIL: bc initialization failed'
    passed = .FALSE.
  END IF

  update_args%step_time = 1.0_wp
  update_args%time_increment = 0.1_wp
  update_args%increment_number = 1_i4
  update_args%iteration_number = 1_i4
  CALL RT_LoadBC_Update(load_desc, load_state, load_algo, load_ctx, update_args)
  CALL RT_LoadBC_Update(bc_desc, bc_state, bc_algo, bc_ctx, update_args)

  global_force = [0.0_wp, -1000.0_wp, 0.0_wp]
  load_args%f_external => global_force
  load_args%load_factor = 1.0_wp
  CALL RT_LoadBC_ApplyLoads(load_desc, load_state, load_algo, load_ctx, load_args)
  IF (.NOT. load_args%loads_applied) THEN
    PRINT *, 'FAIL: load application failed'
    passed = .FALSE.
  END IF

  bc_dofs = [2_i4]
  bc_values = [0.0_wp]
  bc_args%bc_dofs => bc_dofs
  bc_args%bc_values => bc_values
  CALL RT_LoadBC_ApplyBCs(bc_desc, bc_state, bc_algo, bc_ctx, bc_args)
  IF (.NOT. bc_args%bcs_applied) THEN
    PRINT *, 'FAIL: bc application failed'
    passed = .FALSE.
  END IF

  reaction_input = [0.0_wp, 1000.0_wp, 0.0_wp, 0.0_wp, 0.0_wp, 0.0_wp]
  coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
  coords(:,2) = [100.0_wp, 0.0_wp, 0.0_wp]
  reaction_args%f_reaction => reaction_input
  reaction_args%coords => coords
  CALL RT_LoadBC_ComputeReactions(bc_desc, bc_state, bc_algo, bc_ctx, reaction_args)
  IF (.NOT. reaction_args%computed) THEN
    PRINT *, 'FAIL: reaction recovery failed'
    passed = .FALSE.
  END IF

  IF (passed) THEN
    PRINT *, 'PASS: split LoadBC runtime smoke test completed'
    PRINT *, '  Applied force norm = ', load_args%applied_load_norm
    PRINT *, '  Reaction FY = ', reaction_args%reaction_sum(2)
  END IF
END PROGRAM E2E_Cantilever_Beam
