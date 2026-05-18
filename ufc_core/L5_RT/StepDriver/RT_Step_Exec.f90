!===============================================================================
! MODULE: RT_Step_Exec
! LAYER:  L5_RT
! DOMAIN: StepDriver
! ROLE:   Exec — Production step/increment/iteration driver
! BRIEF:  GOLDEN-LINE orchestration: static NR, dynamic explicit/implicit.
!
! Static NR: `nr_divergence_growth_limit` is read from L3 `MD_NonlinSolv` (default 0 = off).
!   If NR returns `IF_STATUS_WARN` (soft residual blow-up), increment success is suppressed
!   so the driver takes cut-back/retry while cutbacks remain (same path as hard non-convergence).
!
! Routes to: RT_Solv_Nonlin (NR), RT_Step_Impl (dynamics).
!
! Status: GOLDEN-LINE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Step_Exec
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, &
                         IF_STATUS_INVALID, IF_STATUS_ERROR, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE MD_Model_Lib_Core, ONLY: UF_Model, UF_ModelDef
  USE MD_Mat_Lib, ONLY: UF_MaterialDef_EnsureCommittedForRollback
  USE MD_Mat_Def, ONLY: MD_MatState, MD_MatState_Snapshot, MD_MatState_RestoreInto, MD_MAT_STATUS_OK
  USE MD_Step_Proc, ONLY: AnalysisStep, StepStateData, MD_TimeIncrementControl, &
                          MD_TimeIncrementResult, MD_TimeIncrement_Calc, &
                          MD_ConvergenceCriteria, MD_ConvergenceResult, &
                          MD_Conv_Check, MD_NonlinSolv, MD_SolverState, &
                          MD_RestartData, MD_OutCfg, MD_OutReq, &
                          CONV_MODE_AND, CONV_MODE_OR, CONV_MODE_WEIGHTED, &
                          PROC_STATIC, PROC_DYNAMIC_EXPLICIT, PROC_DYNAMIC_IMPLICIT
  USE RT_Asm_DofMap, ONLY: RT_Asm_DofMap_Build
  USE RT_Step_DP_Brg, ONLY: RT_Static_RegisterVars
  USE RT_Step_WS, ONLY: JobWS, ThreadWS
  USE RT_Ctx_API, ONLY: RT_Asm_Complete, RT_Assembly_Config, RT_Asm_Complete_Ctx_Type
  USE RT_Out_Mgr, ONLY: RT_Out_CfgAddFldOut, RT_Out_CfgAddHistOut, &
                         RT_Out_UnifMgr, RT_Out_Cfg, RT_Out_State
  USE RT_Out_Restart, ONLY: RT_Out_RestartSave, RT_Out_RestartRestore
  USE RT_Solv_Lin, ONLY: RT_LinearSolver, RT_LinearSolver_Init, RT_LinearSolver_Solv, RT_LinearSolver_Clean
  USE RT_Step_Impl, ONLY: RT_DynExpl_Run, RT_DynImpl_Run
  USE RT_Solv_Nonlin, ONLY: RT_NLSolver_NewtonRaph, RT_NLSolver_LineSearch
  USE RT_Solv_Def, ONLY: RT_CSRMatrix, RT_Sol_DofMap, RT_Solv, RT_Solv_NRState
  USE RT_Solv_Proc, ONLY: RT_Solv_Cutback_In, RT_Solv_Cutback_Out
  USE RT_Solv_Impl, ONLY: RT_Solv_Impl_Cutback
  USE RT_Step_Def, ONLY: RT_StepDriver_Desc, RT_StepDriver_Result, &
                                 RT_PHASE_INIT, RT_PHASE_INCREMENT, RT_PHASE_CONVERGED, &
                                 RT_PHASE_CUTBACK, RT_PHASE_FAILED, RT_PHASE_COMPLETED
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global

  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! Public interfaces
  !=============================================================================
  PUBLIC :: RT_StepDriver_Execute
  PUBLIC :: RT_StepDriver_Execute_WithModelDef
  PUBLIC :: RT_StepDriver_RunDynamicExplicit
  PUBLIC :: RT_StepDriver_RunDynamicImplicit
  PUBLIC :: StepDriverContext, StepState
  PUBLIC :: RT_StepDriver_ConfigDomain
  PUBLIC :: StepDriver_Init, StepDriver_Finalize
  PUBLIC :: RunStep, StepStateMachine, GetStepState
  PUBLIC :: RunIncrement, InitIncrement, FinalizeIncrement

  ! Phase6 harness: set true when RT_StepDriver_Execute is entered with optional model_def present.
  LOGICAL, SAVE, PUBLIC :: PHASE6_step_exec_saw_model_def = .FALSE.

  !=============================================================================
  ! Step Driver Configuration
  !=============================================================================
  TYPE, PUBLIC :: RT_StepDriver_Config
    LOGICAL :: use_newton_raphson = .TRUE.
    LOGICAL :: use_line_search = .TRUE.
    LOGICAL :: enable_restart = .TRUE.
    LOGICAL :: enable_output = .TRUE.
    LOGICAL :: verbose = .TRUE.
    INTEGER(i4) :: max_increment = 1000_i4
    INTEGER(i4) :: checkpoint_freq = 10_i4
    CHARACTER(LEN=256) :: restart_file = 'restart.bin'
    CHARACTER(LEN=256) :: output_dir = './output'
    INTEGER(i4) :: conv_combination_mode = CONV_MODE_AND
  END TYPE RT_StepDriver_Config

  !=============================================================================
  ! State Enumerators
  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_INIT = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_RUNNING = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_INCREMENT = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_ITERATION = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_DONE = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_FAILED = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: STEP_STATE_ROLLBACK = 6_i4

  !=============================================================================
  ! StepState (运行时状�?
  !=============================================================================
  TYPE, PUBLIC :: StepState
    INTEGER(i4) :: current_state = STEP_STATE_INIT
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_increment = 0_i4
    INTEGER(i4) :: current_iteration = 0_i4
    INTEGER(i4) :: total_steps = 0_i4
    INTEGER(i4) :: total_increments = 0_i4
    REAL(wp)    :: current_load_factor = 0.0_wp
    REAL(wp)    :: current_time = 0.0_wp
    LOGICAL     :: converged = .FALSE.
  END TYPE StepState

  !=============================================================================
  ! StepDriverContext (驱动上下�?
  !=============================================================================
  TYPE, PUBLIC :: StepDriverContext
    TYPE(StepState) :: state
    INTEGER(i4) :: max_increments = 100_i4
    INTEGER(i4) :: max_iterations = 20_i4
    REAL(wp)    :: initial_step_size = 0.1_wp
    REAL(wp)    :: min_step_size = 1.0e-6_wp
    REAL(wp)    :: max_step_size = 1.0_wp
    INTEGER(i4) :: n_rollbacks = 0_i4
    INTEGER(i4) :: max_rollbacks = 5_i4
  END TYPE StepDriverContext

  !=============================================================================
  ! RT_StepDriver_ConfigDomain (flat storage for step configs)
  !=============================================================================
  TYPE, PUBLIC :: RT_StepDriver_ConfigDomain
    TYPE(RT_StepDriver_Desc), ALLOCATABLE :: configs(:)
    TYPE(AnalysisStep), POINTER :: step_ref(:) => NULL()
    INTEGER(i4) :: n_configs = 0_i4
    INTEGER(i4) :: capacity = 0_i4
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddConfig
    PROCEDURE :: GetConfig
    PROCEDURE :: BindStepRefs
    PROCEDURE :: GetStepRef
  END TYPE RT_StepDriver_ConfigDomain

CONTAINS

  !=============================================================================
  ! ConfigDomain Methods
  !=============================================================================
  SUBROUTINE Init(this, initial_capacity, status)
    CLASS(RT_StepDriver_ConfigDomain), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: initial_capacity
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%capacity = MAX(16_i4, initial_capacity)
    ALLOCATE(this%configs(this%capacity))
    this%n_configs = 0_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  SUBROUTINE Finalize(this)
    CLASS(RT_StepDriver_ConfigDomain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%configs)) DEALLOCATE(this%configs)
    IF (ASSOCIATED(this%step_ref)) NULLIFY(this%step_ref)
    this%n_configs = 0_i4
    this%capacity = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE AddConfig(this, desc, config_id, status)
    CLASS(RT_StepDriver_ConfigDomain), INTENT(INOUT) :: this
    TYPE(RT_StepDriver_Desc), INTENT(IN) :: desc
    INTEGER(i4), INTENT(OUT) :: config_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(RT_StepDriver_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: new_cap
    CALL init_error_status(status)
    config_id = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "StepDriver config domain not initialized"
      RETURN
    END IF
    IF (this%n_configs >= this%capacity) THEN
      new_cap = this%capacity * 2_i4
      ALLOCATE(tmp(new_cap))
      tmp(1:this%n_configs) = this%configs
      CALL MOVE_ALLOC(tmp, this%configs)
      this%capacity = new_cap
    END IF
    this%n_configs = this%n_configs + 1_i4
    config_id = this%n_configs
    this%configs(config_id) = desc
    this%configs(config_id)%step_id = config_id
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AddConfig

  SUBROUTINE GetConfig(this, step_idx, desc, status)
    CLASS(RT_StepDriver_ConfigDomain), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: step_idx
    TYPE(RT_StepDriver_Desc), INTENT(OUT) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "StepDriver config domain not initialized"
      RETURN
    END IF
    IF (step_idx < 1_i4 .OR. step_idx > this%n_configs) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid step index for GetConfig"
      RETURN
    END IF
    desc = this%configs(step_idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetConfig

  SUBROUTINE BindStepRefs(this, steps, status)
    CLASS(RT_StepDriver_ConfigDomain), INTENT(INOUT) :: this
    TYPE(AnalysisStep), TARGET, INTENT(IN) :: steps(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Config domain not initialized"
      RETURN
    END IF
    IF (SIZE(steps) /= this%n_configs) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "BindStepRefs: steps size mismatch"
      RETURN
    END IF
    this%step_ref => steps
    status%status_code = IF_STATUS_OK
  END SUBROUTINE BindStepRefs

  FUNCTION GetStepRef(this, step_idx) RESULT(ptr)
    CLASS(RT_StepDriver_ConfigDomain), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: step_idx
    TYPE(AnalysisStep), POINTER :: ptr
    NULLIFY(ptr)
    IF (.NOT. ASSOCIATED(this%step_ref)) RETURN
    IF (step_idx < 1_i4 .OR. step_idx > this%n_configs) RETURN
    ptr => this%step_ref(step_idx)
  END FUNCTION GetStepRef

  !=============================================================================
  ! StepDriverContext Methods
  !=============================================================================
  SUBROUTINE StepDriver_Init(ctx, total_steps, max_incr, max_iter)
    TYPE(StepDriverContext), INTENT(OUT) :: ctx
    INTEGER(i4), INTENT(IN) :: total_steps, max_incr, max_iter
    ctx%state%current_state = STEP_STATE_INIT
    ctx%state%total_steps = total_steps
    ctx%max_increments = max_incr
    ctx%max_iterations = max_iter
    ctx%n_rollbacks = 0_i4
  END SUBROUTINE StepDriver_Init

  SUBROUTINE StepDriver_Finalize(ctx)
    TYPE(StepDriverContext), INTENT(INOUT) :: ctx
    ctx%state%current_state = STEP_STATE_DONE
  END SUBROUTINE StepDriver_Finalize

  !=============================================================================
  ! INTEGRATED STEP DRIVER - COMPLETE SOLVE PIPELINE
  !=============================================================================
  SUBROUTINE RT_StepDriver_Execute(model, step, workspace, config, result, status, model_def)
    TYPE(UF_Model), INTENT(INOUT) :: model
    TYPE(AnalysisStep), INTENT(INOUT) :: step
    TYPE(JobWS), INTENT(INOUT) :: workspace
    TYPE(RT_StepDriver_Config), INTENT(IN), OPTIONAL :: config
    TYPE(RT_StepDriver_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(UF_ModelDef), INTENT(INOUT), OPTIONAL, TARGET :: model_def

    TYPE(RT_StepDriver_Config) :: cfg
    TYPE(StepStateData) :: state
    TYPE(MD_TimeIncrementControl) :: time_ctrl
    TYPE(MD_TimeIncrementResult) :: time_result
    TYPE(MD_ConvergenceCriteria) :: conv_criteria
    TYPE(MD_ConvergenceResult) :: conv_result
    TYPE(MD_NonlinSolv) :: solver
    TYPE(MD_SolverState) :: solver_state
    TYPE(RT_Sol_DofMap) :: dofMap
    TYPE(RT_CSRMatrix) :: K
    REAL(wp), ALLOCATABLE :: F_ext(:), u(:)
    INTEGER(i4), ALLOCATABLE :: dof_mask(:)
    TYPE(RT_Assembly_Config) :: asm_config
    TYPE(RT_Asm_Complete_Ctx_Type) :: asm_ctx
    TYPE(MD_RestartData) :: restart_data
    TYPE(MD_OutCfg) :: output_config
    TYPE(ErrorStatusType) :: local_status
    TYPE(ErrorStatusType) :: nr_exit_status
    TYPE(RT_Solv_NRState), TARGET :: solv_nr_state
    TYPE(RT_Solv), TARGET :: solv_algo
    TYPE(RT_Solv_Cutback_In) :: cutback_in
    TYPE(RT_Solv_Cutback_Out) :: cutback_out
    
    REAL(wp), ALLOCATABLE :: u_old(:)
    TYPE(MD_MatState), ALLOCATABLE :: mat_inc_snap(:)
    INTEGER(i4) :: iMat, nMatSnap, jm
    LOGICAL :: mat_rb_active
    
    INTEGER(i4) :: iInc, nDOF, phase
    REAL(wp) :: time, cpu_start, cpu_end
    LOGICAL :: converged
    TYPE(RT_Out_Cfg) :: out_cfg
    TYPE(RT_Out_State) :: out_state

    CALL init_error_status(status)
    PHASE6_step_exec_saw_model_def = PRESENT(model_def)
    CALL CPU_TIME(cpu_start)

    ! Validate model before Step execution
    IF (g_ufc_global%md_layer%initialized) THEN
      CALL g_ufc_global%md_layer%ValidateModel(status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        result%success = .FALSE.
        RETURN
      END IF
    END IF

    IF (.NOT. ASSOCIATED(model%mesh)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'StepDriver: Model mesh not initialized'
      result%success = .FALSE.
      RETURN
    END IF

    ! Explicit / implicit dynamics: dedicated runners
    SELECT CASE (step%procedure)
    CASE (PROC_DYNAMIC_EXPLICIT)
      CALL RT_StepDriver_RunDynamicExplicit(model, step, workspace, result, status)
      RETURN
    CASE (PROC_DYNAMIC_IMPLICIT)
      CALL RT_StepDriver_RunDynamicImplicit(model, step, workspace, result, status)
      RETURN
    CASE (PROC_STATIC)
      CONTINUE
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'StepDriver: unsupported procedure'
      result%success = .FALSE.
      RETURN
    END SELECT

    IF (PRESENT(config)) THEN
      cfg = config
    ELSE
      cfg = RT_StepDriver_Config()
    END IF

    state%currentTime = step%start_time
    state%totalTime = step%time_period
    state%currentInc = 0_i4
    state%failed = .FALSE.

    time_ctrl%initial_increment = step%inc_ctrl%initial_inc
    time_ctrl%min_increment = step%inc_ctrl%min_inc
    time_ctrl%max_increment = step%inc_ctrl%max_inc
    time_ctrl%current_increment = step%inc_ctrl%initial_inc
    time_ctrl%time_period = step%time_period
    time_ctrl%automatic = .TRUE.
    time_ctrl%max_increments = cfg%max_increment

    ! Cutback policy: authoritative dt scaling + n_cutbacks via RT_Solv_Impl_Cutback
    CALL solv_nr_state%Init()
    CALL solv_algo%Init()
    solv_algo%itr%nr_max_cutbacks = 11_i4

    conv_criteria%use_residual = .TRUE.
    conv_criteria%use_displacement = .TRUE.
    conv_criteria%use_energy = .TRUE.
    conv_criteria%residual_tolerance = 1.0e-6_wp
    conv_criteria%displacement_tol = 1.0e-5_wp
    conv_criteria%energy_tolerance = 1.0e-4_wp
    conv_criteria%max_iterations = 50_i4
    conv_criteria%combination_mode = cfg%conv_combination_mode

    solver%max_iterations = 50_i4
    solver%tolerance_force = 1.0e-6_wp
    solver%tolerance_displacement = 1.0e-5_wp

    ! L4 Init: ensure PH layer initialized at Step start
    IF (g_ufc_global%IsReady()) THEN
      CALL g_ufc_global%ph_layer%Init(MAX(1_i4, step%step_number), local_status, &
           proc_type=step%procedure)
    END IF

    ! DOF Map Build
    CALL RT_Asm_DofMap_Build(model, dofMap)
    nDOF = dofMap%nTotalEq
    IF (nDOF < 1_i4) nDOF = 1_i4

    ! Register STATIC_* vars for NR/Output
    CALL RT_Static_RegisterVars(nDOF)

    ! Output config/state for RT_Out_UnifMgr
    CALL out_cfg%Init()
    CALL out_state%Init()

    ALLOCATE(F_ext(nDOF), u(nDOF), u_old(nDOF), dof_mask(nDOF))
    F_ext = 0.0_wp
    u = 0.0_wp
    u_old = 0.0_wp
    dof_mask = 1_i4
    ALLOCATE(solver_state%u(nDOF), solver_state%R(nDOF), solver_state%du(nDOF))
    solver_state%u = 0.0_wp
    solver_state%R = 0.0_wp
    solver_state%du = 0.0_wp
    solver_state%lambda = 1.0_wp

    mat_rb_active = .FALSE.
    nMatSnap = 0_i4
    IF (PRESENT(model_def)) THEN
      nMatSnap = model_def%material_db%num_materials
      IF (nMatSnap > 0_i4) THEN
        ALLOCATE(mat_inc_snap(nMatSnap))
        DO iMat = 1_i4, nMatSnap
          CALL mat_inc_snap(iMat)%Init()
          CALL UF_MaterialDef_EnsureCommittedForRollback(model_def%material_db%materials(iMat), 1_i4, local_status)
          IF (local_status%status_code /= MD_MAT_STATUS_OK) THEN
            status = local_status
            status%status_code = IF_STATUS_ERROR
            result%success = .FALSE.
            DO jm = 1_i4, nMatSnap
              CALL mat_inc_snap(jm)%Destroy()
            END DO
            IF (ALLOCATED(mat_inc_snap)) DEALLOCATE(mat_inc_snap)
            IF (ALLOCATED(solver_state%u)) DEALLOCATE(solver_state%u)
            IF (ALLOCATED(solver_state%R)) DEALLOCATE(solver_state%R)
            IF (ALLOCATED(solver_state%du)) DEALLOCATE(solver_state%du)
            DEALLOCATE(F_ext, u, u_old, dof_mask)
            RETURN
          END IF
        END DO
        mat_rb_active = .TRUE.
      END IF
    END IF

    IF (cfg%verbose) THEN
      PRINT '(A)', '========================================'
      PRINT '(A)', 'UFC Step Driver - Integrated Pipeline'
      PRINT '(A)', '========================================'
      PRINT '(A,I0)', '  Total DOFs: ', nDOF
      PRINT '(A,F12.6)', '  Time period: ', state%totalTime
    END IF

    ! Increment Loop (Modified to allow cutbacks and retries)
    phase = RT_PHASE_INIT
    iInc = 1_i4
    
    inc_driver: DO WHILE (state%currentTime < step%time_period - 1.0e-10_wp .AND. iInc <= cfg%max_increment)
      
      ! 1. Save state for potential rollback
      u_old = u
      state%currentInc = iInc
      phase = RT_PHASE_INCREMENT

      IF (mat_rb_active) THEN
        DO iMat = 1_i4, nMatSnap
          IF (.NOT. ALLOCATED(model_def%material_db%materials(iMat)%committed_state)) CYCLE
          CALL MD_MatState_Snapshot(model_def%material_db%materials(iMat)%committed_state, &
               mat_inc_snap(iMat), local_status)
          IF (local_status%status_code /= MD_MAT_STATUS_OK) THEN
            status = local_status
            status%status_code = IF_STATUS_ERROR
            result%success = .FALSE.
            EXIT inc_driver
          END IF
        END DO
      END IF
      
      ! Ensure we do not overshoot the step total time
      IF (state%currentTime + time_ctrl%current_increment > step%time_period) THEN
         time_ctrl%current_increment = step%time_period - state%currentTime
      END IF
      
      time = state%currentTime + time_ctrl%current_increment

      IF (cfg%verbose) THEN
        PRINT '(/,A,I0,A,F12.6,A,ES12.5)', &
          'Increment ', iInc, ': time = ', time, ', dt = ', time_ctrl%current_increment
      END IF

      ! Assembly pipeline (K, F_ext, BC, L3 constraints, optional Contact)
      asm_config%assemble_stiffness = .TRUE.
      asm_config%assemble_load = .TRUE.
      asm_config%apply_bc = .TRUE.
      asm_config%apply_contact = cfg%use_newton_raphson
      asm_config%verbose = .FALSE.

      asm_ctx%model = model
      asm_ctx%step = step
      asm_ctx%state = state
      asm_ctx%time = time
      asm_ctx%dofMap = dofMap
      asm_ctx%K = K
      asm_ctx%F_ext = F_ext
      IF (ALLOCATED(dof_mask)) asm_ctx%dof_mask = dof_mask
      asm_ctx%has_config = .TRUE.
      asm_ctx%config = asm_config
      CALL RT_Asm_Complete(asm_ctx)
      K = asm_ctx%K
      F_ext = asm_ctx%F_ext
      IF (ALLOCATED(asm_ctx%dof_mask)) dof_mask = asm_ctx%dof_mask
      local_status = asm_ctx%status

      IF (local_status%status_code /= IF_STATUS_OK) THEN
        status = local_status
        result%success = .FALSE.
        EXIT
      END IF

      solver_state%u = u
      solver_state%lambda = 1.0_wp

      ! Newton–Raphson (implicit static)
      CALL RT_NLSolver_NewtonRaph(solver, solver_state, converged, local_status, &
           model=model, step=step, step_state=state, dofMap=dofMap, F_ext=F_ext, K_CSR=K, &
           l3_csr_reanalyze_required=asm_ctx%l3_csr_reanalyze_required, &
           nr_divergence_growth_limit=solver%nr_divergence_growth_limit)

      nr_exit_status = local_status

      u = solver_state%u
      state%resNorm = solver_state%residual_norm
      state%dispNorm = solver_state%displacement_norm
      state%energyRatio = solver_state%energy_norm
      state%nItersTotal = solver_state%iterations

      ! Convergence check (NR may return IF_STATUS_WARN on soft divergence; MD_Conv_Check resets status)
      CALL MD_Conv_Check(conv_criteria, state, conv_result, local_status)
      IF (nr_exit_status%status_code == IF_STATUS_WARN) THEN
        conv_result%converged = .FALSE.
      END IF

      IF (conv_result%converged) THEN
        phase = RT_PHASE_CONVERGED
        state%converged = .TRUE.
        state%currentTime = time
        result%total_iterations = result%total_iterations + conv_result%iterations
        solv_nr_state%stp%n_cutbacks = 0_i4

        ! Output management
        IF (cfg%enable_output) THEN
          CALL RT_Out_UnifMgr(model, step%step_number, iInc, time, out_cfg, out_state, local_status)
        END IF

        ! Restart checkpoint
        IF (cfg%enable_restart .AND. MOD(iInc, cfg%checkpoint_freq) == 0) THEN
          restart_data%valid = .TRUE.
          restart_data%time = time
          restart_data%increment = iInc
          restart_data%u = u
          restart_data%converged = .TRUE.
          CALL RT_Out_RestartSave(restart_data, cfg%restart_file, local_status)
        END IF

        ! Time control (Compute next increment)
        CALL MD_TimeIncrement_Calc(time_ctrl, state, conv_result, time_result, local_status)
        
        ! Advance to next increment
        iInc = iInc + 1_i4

      ELSE
        ! === CUT-BACK LOGIC (dt via RT_Solv_Impl_Cutback; n_cutbacks in solv_nr_state%stp) ===
        IF (nr_exit_status%status_code == IF_STATUS_WARN) local_status = nr_exit_status
        phase = RT_PHASE_CUTBACK
        state%converged = .FALSE.
        state%cutbackOccurred = .TRUE.
        result%total_cutbacks = result%total_cutbacks + 1_i4

        cutback_in%current_dt = time_ctrl%current_increment
        cutback_in%pnewdt_from_physics = 1.0_wp
        cutback_in%cutback_reason = 1_i4
        cutback_in%allow_expansion = .FALSE.
        cutback_in%nr_state => solv_nr_state
        cutback_in%algo => solv_algo
        solv_nr_state%itr%converged = .FALSE.

        CALL RT_Solv_Impl_Cutback(cutback_in, cutback_out)

        IF (cfg%verbose) THEN
          PRINT '(A,I0,A,ES12.5)', '  ** DIVERGENCE: cutback applied, n_cutbacks=', &
            solv_nr_state%stp%n_cutbacks, ', new_dt=', cutback_out%new_dt
        END IF

        IF (cutback_out%max_cutbacks_reached) THEN
          phase = RT_PHASE_FAILED
          status%status_code = IF_STATUS_ERROR
          status%message = 'Maximum consecutive cutbacks exceeded. Step failed.'
          result%success = .FALSE.
          EXIT
        END IF

        time_ctrl%current_increment = cutback_out%new_dt

        IF (time_ctrl%current_increment < time_ctrl%min_increment) THEN
          phase = RT_PHASE_FAILED
          status%status_code = IF_STATUS_ERROR
          status%message = 'Time increment reduced below minimum allowable limit. Step failed.'
          result%success = .FALSE.
          EXIT
        END IF

        IF (mat_rb_active) THEN
          DO iMat = 1_i4, nMatSnap
            IF (.NOT. ALLOCATED(model_def%material_db%materials(iMat)%committed_state)) CYCLE
            CALL MD_MatState_RestoreInto(model_def%material_db%materials(iMat)%committed_state, &
                 mat_inc_snap(iMat), local_status)
            IF (local_status%status_code /= MD_MAT_STATUS_OK) THEN
              status = local_status
              status%status_code = IF_STATUS_ERROR
              status%message = 'RT_StepDriver: MD_MatState_RestoreInto failed on cut-back'
              result%success = .FALSE.
              EXIT inc_driver
            END IF
          END DO
        END IF
        u = u_old
        ! state%currentTime unchanged: repeat increment iInc with smaller dt
      END IF

    END DO inc_driver

    ! Final success check
    IF (state%currentTime >= step%time_period - 1.0e-10_wp .AND. status%status_code == IF_STATUS_OK) THEN
      phase = RT_PHASE_COMPLETED
      result%success = .TRUE.
      result%final_time = state%currentTime
    END IF

    ! Cleanup
    IF (ALLOCATED(mat_inc_snap)) THEN
      DO iMat = 1_i4, SIZE(mat_inc_snap)
        CALL mat_inc_snap(iMat)%Destroy()
      END DO
      DEALLOCATE(mat_inc_snap)
    END IF
    IF (ALLOCATED(solver_state%u)) DEALLOCATE(solver_state%u)
    IF (ALLOCATED(solver_state%R)) DEALLOCATE(solver_state%R)
    IF (ALLOCATED(solver_state%du)) DEALLOCATE(solver_state%du)
    DEALLOCATE(F_ext, u, u_old, dof_mask)

    CALL CPU_TIME(cpu_end)
    result%cpu_time = cpu_end - cpu_start
    result%total_increments = state%currentInc
    result%final_load_factor = state%lambda

    IF (result%success) THEN
      status%status_code = IF_STATUS_OK
      WRITE(status%message, '(A,I0,A,I0,A,F8.2,A)') &
        'Step completed: ', result%total_increments, ' increments, ', &
        result%total_iterations, ' iterations, CPU = ', result%cpu_time, 's'
    ELSE
      IF (status%status_code == IF_STATUS_OK) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = 'Step failed to complete'
      END IF
    END IF

    result%message = status%message

    IF (cfg%verbose) THEN
      PRINT '(/,A)', '========================================'
      PRINT '(A)', TRIM(status%message)
      PRINT '(A,I0)', '  Total increments: ', result%total_increments
      PRINT '(A,I0)', '  Total iterations: ', result%total_iterations
      PRINT '(A,I0)', '  Total cutbacks: ', result%total_cutbacks
      PRINT '(A,F12.6)', '  Final time: ', result%final_time
      PRINT '(A,F8.2,A)', '  CPU time: ', result%cpu_time, ' s'
      PRINT '(A)', '========================================'
    END IF

  END SUBROUTINE RT_StepDriver_Execute

  ! Phase6 §1.3: explicit model_def entry for L6/L5 driver bridges.
  SUBROUTINE RT_StepDriver_Execute_WithModelDef(model, model_def, step, workspace, result, status, config)
    TYPE(UF_Model), INTENT(INOUT) :: model
    TYPE(UF_ModelDef), INTENT(INOUT), TARGET :: model_def
    TYPE(AnalysisStep), INTENT(INOUT) :: step
    TYPE(JobWS), INTENT(INOUT) :: workspace
    TYPE(RT_StepDriver_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(RT_StepDriver_Config), INTENT(IN), OPTIONAL :: config
    IF (PRESENT(config)) THEN
      CALL RT_StepDriver_Execute(model, step, workspace, config, result, status, model_def=model_def)
    ELSE
      CALL RT_StepDriver_Execute(model, step, workspace, result=result, status=status, model_def=model_def)
    END IF
  END SUBROUTINE RT_StepDriver_Execute_WithModelDef

  !=============================================================================
  ! PROC_11: Explicit dynamics (central-difference)
  !=============================================================================
  SUBROUTINE RT_StepDriver_RunDynamicExplicit(model, step, workspace, result, status)
    TYPE(UF_Model), INTENT(INOUT) :: model
    TYPE(AnalysisStep), INTENT(INOUT) :: step
    TYPE(JobWS), INTENT(INOUT) :: workspace
    TYPE(RT_StepDriver_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: u(:)
    INTEGER(i4) :: n_dof
    TYPE(RT_Sol_DofMap) :: dofMap
    TYPE(StepStateData) :: state
    LOGICAL :: use_asm
    TYPE(ErrorStatusType) :: ph_status

    CALL init_error_status(status)
    result%success = .FALSE.
    result%converged = .FALSE.
    n_dof = 100_i4
    use_asm = g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%mesh%initialized

    IF (use_asm) THEN
      CALL RT_Asm_DofMap_Build(model, dofMap)
      n_dof = MAX(1_i4, dofMap%nTotalEq)
      state%currentTime = 0.0_wp
      state%totalTime = MAX(step%time_period, 1.0e-6_wp)
      IF (g_ufc_global%IsReady()) THEN
        CALL init_error_status(ph_status)
        CALL g_ufc_global%ph_layer%Init(MAX(1_i4, step%step_number), ph_status, proc_type=step%procedure)
      END IF
    END IF

    ALLOCATE(u(n_dof)); u = 0.0_wp

    IF (use_asm .AND. n_dof > 0_i4) THEN
      CALL RT_DynExpl_Run(step%dyn_params, status, u=u, n_dof=n_dof, model=model, step=step, &
           state=state, dofMap=dofMap, &
           apply_cfl_clamp=step%dyn_params%dyn_expl_apply_cfl_clamp, &
           cfl_safety=step%dyn_params%dyn_expl_cfl_safety)
    ELSE
      CALL RT_DynExpl_Run(step%dyn_params, status, u=u, n_dof=n_dof)
    END IF

    DEALLOCATE(u)

    IF (status%status_code == IF_STATUS_OK) THEN
      result%success = .TRUE.
      result%converged = .TRUE.
      result%total_increments = 1_i4
      result%message = 'PROC_DYNAMIC_EXPLICIT: central-diff completed'
    END IF

  END SUBROUTINE RT_StepDriver_RunDynamicExplicit

  !=============================================================================
  ! PROC_10: Implicit dynamics (HHT-alpha)
  !=============================================================================
  SUBROUTINE RT_StepDriver_RunDynamicImplicit(model, step, workspace, result, status)
    TYPE(UF_Model), INTENT(INOUT) :: model
    TYPE(AnalysisStep), INTENT(INOUT) :: step
    TYPE(JobWS), INTENT(INOUT) :: workspace
    TYPE(RT_StepDriver_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), ALLOCATABLE :: u(:)
    INTEGER(i4) :: n_dof
    TYPE(RT_Sol_DofMap) :: dofMap
    TYPE(StepStateData) :: state
    LOGICAL :: use_asm
    TYPE(ErrorStatusType) :: ph_status

    CALL init_error_status(status)
    result%success = .FALSE.
    result%converged = .FALSE.
    n_dof = 100_i4
    use_asm = g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%mesh%initialized

    IF (use_asm) THEN
      CALL RT_Asm_DofMap_Build(model, dofMap)
      n_dof = MAX(1_i4, dofMap%nTotalEq)
      state%currentTime = 0.0_wp
      state%totalTime = MAX(step%time_period, 1.0e-6_wp)
      IF (g_ufc_global%IsReady()) THEN
        CALL init_error_status(ph_status)
        CALL g_ufc_global%ph_layer%Init(MAX(1_i4, step%step_number), ph_status, proc_type=step%procedure)
      END IF
    END IF

    ALLOCATE(u(n_dof)); u = 0.0_wp

    IF (use_asm .AND. n_dof > 0_i4) THEN
      CALL RT_DynImpl_Run(step%dyn_params, status, u=u, n_dof=n_dof, model=model, step=step, state=state, dofMap=dofMap)
    ELSE
      CALL RT_DynImpl_Run(step%dyn_params, status, u=u, n_dof=n_dof)
    END IF

    DEALLOCATE(u)

    IF (status%status_code == IF_STATUS_OK) THEN
      result%success = .TRUE.
      result%converged = .TRUE.
      result%total_increments = 1_i4
      result%message = 'PROC_DYNAMIC_IMPLICIT: Newmark completed'
    END IF

  END SUBROUTINE RT_StepDriver_RunDynamicImplicit

  !=============================================================================
  ! Domain State Machine Procedures
  !=============================================================================
  SUBROUTINE RunStep(ctx, step_id, ierr)
    TYPE(StepDriverContext), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: step_id
    INTEGER(i4), INTENT(OUT) :: ierr

    ierr = 0_i4
    ctx%state%current_step = step_id
    ctx%state%current_state = STEP_STATE_RUNNING

    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%step%initialized) THEN
      g_ufc_global%md_layer%step%current_step_idx = step_id
    END IF

    IF (g_ufc_global%IsReady() .AND. g_ufc_global%rt_layer%initialized) THEN
      CALL g_ufc_global%rt_layer%contact%SyncStepIncr(INT(step_id, i4), 0_i4)
      CALL g_ufc_global%rt_layer%output%SyncStepIncr(INT(step_id, i4), 0_i4)
      CALL g_ufc_global%rt_layer%assembly%SyncStepIncr(INT(step_id, i4), 0_i4)
      CALL g_ufc_global%rt_layer%element%SyncStepIncr(INT(step_id, i4), 0_i4)
      CALL g_ufc_global%rt_layer%solver%SyncStepIncr(INT(step_id, i4), 0_i4)
      CALL g_ufc_global%rt_layer%step%SyncStepIncr(INT(step_id, i4), 0_i4)
      CALL g_ufc_global%rt_layer%bridge%SyncStepIncr(INT(step_id, i4), 0_i4)
      CALL g_ufc_global%rt_layer%logging%SyncStepIncr(INT(step_id, i4), 0_i4)
    END IF

    CALL StepStateMachine(ctx, ierr)
  END SUBROUTINE RunStep

  SUBROUTINE StepStateMachine(ctx, ierr)
    TYPE(StepDriverContext), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(OUT) :: ierr

    INTEGER(i4) :: incr, iter
    LOGICAL :: conv

    ierr = 0_i4
    IF (ctx%state%current_state /= STEP_STATE_RUNNING) RETURN

    DO incr = 1, ctx%max_increments
      ctx%state%current_increment = incr
      ctx%state%current_state = STEP_STATE_INCREMENT

      IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%step%initialized) THEN
        g_ufc_global%md_layer%step%current_incr_idx = incr
      END IF

      IF (g_ufc_global%IsReady() .AND. g_ufc_global%rt_layer%initialized) THEN
        CALL g_ufc_global%rt_layer%contact%SyncStepIncr(INT(ctx%state%current_step, i4), INT(incr, i4))
        CALL g_ufc_global%rt_layer%output%SyncStepIncr(INT(ctx%state%current_step, i4), INT(incr, i4))
        CALL g_ufc_global%rt_layer%assembly%SyncStepIncr(INT(ctx%state%current_step, i4), INT(incr, i4))
        CALL g_ufc_global%rt_layer%element%SyncStepIncr(INT(ctx%state%current_step, i4), INT(incr, i4))
        CALL g_ufc_global%rt_layer%solver%SyncStepIncr(INT(ctx%state%current_step, i4), INT(incr, i4))
        CALL g_ufc_global%rt_layer%step%SyncStepIncr(INT(ctx%state%current_step, i4), INT(incr, i4))
        CALL g_ufc_global%rt_layer%bridge%SyncStepIncr(INT(ctx%state%current_step, i4), INT(incr, i4))
        CALL g_ufc_global%rt_layer%logging%SyncStepIncr(INT(ctx%state%current_step, i4), INT(incr, i4))
      END IF

      CALL InitIncrement(ctx, ctx%initial_step_size)

      DO iter = 1, ctx%max_iterations
        ctx%state%current_iteration = iter
        ctx%state%current_state = STEP_STATE_ITERATION
        conv = (iter >= 2)
        IF (conv) EXIT
      END DO

      CALL FinalizeIncrement(ctx, conv)

      IF (.NOT. conv .AND. ctx%n_rollbacks < ctx%max_rollbacks) THEN
        ctx%state%current_state = STEP_STATE_ROLLBACK
        ctx%n_rollbacks = ctx%n_rollbacks + 1_i4
        ctx%state%current_iteration = 0_i4
      ELSE IF (.NOT. conv) THEN
        ctx%state%current_state = STEP_STATE_FAILED
        ierr = -1_i4
        RETURN
      END IF
    END DO

    ctx%state%current_state = STEP_STATE_DONE
  END SUBROUTINE StepStateMachine

  SUBROUTINE GetStepState(ctx, state)
    TYPE(StepDriverContext), INTENT(IN) :: ctx
    TYPE(StepState), INTENT(OUT) :: state
    state = ctx%state
  END SUBROUTINE GetStepState

  SUBROUTINE RunIncrement(ctx, incr_id, ierr)
    TYPE(StepDriverContext), INTENT(INOUT) :: ctx
    INTEGER(i4), INTENT(IN) :: incr_id
    INTEGER(i4), INTENT(OUT) :: ierr
    ierr = 0_i4
    ctx%state%current_increment = incr_id
    ctx%state%current_state = STEP_STATE_INCREMENT
  END SUBROUTINE RunIncrement

  SUBROUTINE InitIncrement(ctx, load_factor)
    TYPE(StepDriverContext), INTENT(INOUT) :: ctx
    REAL(wp), INTENT(IN) :: load_factor
    ctx%state%current_load_factor = load_factor
    ctx%state%current_iteration = 0_i4
  END SUBROUTINE InitIncrement

  SUBROUTINE FinalizeIncrement(ctx, converged)
    TYPE(StepDriverContext), INTENT(INOUT) :: ctx
    LOGICAL, INTENT(IN) :: converged
    ctx%state%converged = converged
    IF (.NOT. converged) THEN
      ctx%n_rollbacks = ctx%n_rollbacks + 1_i4
    END IF
    ! G7 POST-ITERATION GATE: WriteBack and Output triggered HERE
  END SUBROUTINE FinalizeIncrement

END MODULE RT_Step_Exec