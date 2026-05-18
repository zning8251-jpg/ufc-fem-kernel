!===============================================================================
! MODULE: AP_InpScript_UFC
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl — UFC command implementations
! BRIEF:  UFC command implementations.
!
! Process phases:
!   P0: UF_Cmd_UFC_RegAll
!   P2: UF_Cmd_* (individual command handlers)
!===============================================================================

module AP_InpScript_UFC
  USE AP_Inp_Script, only: Cmd_Reg, Cmd_FormatError, Cmd_SetVar, &
                          Cmd_HistoryAdd, Cmd_HistoryGet, Cmd_HistoryClear, &
                          Cmd_LabelResolve, Cmd_HelpShow, Cmd_HelpSearch, &
                          Cmd_DebugSetBrk, Cmd_DebugShowVars, &
                          Cmd_AliasDefine
  USE AP_Inp_Def, only: Cmd, CmdCtx
  USE AP_Inp_Amp, only: UF_Cmd_Amp_RegAll
  USE AP_Inp_Conn, only: UF_Cmd_Connector_RegAll
  USE AP_Inp_Const, only: UF_Cmd_Const_RegAll
  USE AP_Inp_Cont, only: UF_Cmd_Cont_RegAll
  USE AP_Inp_ElemSpcl, only: UF_Cmd_Elem_Spcl_RegAll
  USE AP_Inp_Field, only: UF_Cmd_Field_RegAll
  USE AP_Inp_Geom, only: UF_Cmd_Geom_RegAll
  USE AP_Inp_Init, only: UF_Cmd_Init_RegAll
  USE AP_Inp_KW_Brg, only: UF_Cmd_KWBrg_Init, UF_Cmd_KWBrg_Sync
  USE AP_Inp_Ldbc, only: UF_Cmd_Ldbc_RegAll
  USE AP_Inp_Mat, only: UF_Cmd_Mat_RegAll, ParseMaterialParams
  USE AP_Inp_MatConc, only: UF_Cmd_Mat_Concrete_RegAll
  USE AP_Inp_MatDmg, only: UF_Cmd_Mat_Damage_RegAll
  USE AP_Inp_MatFoam, only: UF_Cmd_Mat_Foam_RegAll
  USE AP_Inp_MatGeoAdv, only: UF_Cmd_Mat_GeoAdv_RegAll
  USE AP_Inp_MatGeo, only: UF_Cmd_Mat_Geomech_RegAll
  USE AP_Inp_MatHyper, only: UF_Cmd_Mat_Hyper_RegAll
  USE AP_Inp_MatPorous, only: UF_Cmd_Mat_Porous_RegAll
  USE AP_Inp_MatTherm, only: UF_Cmd_Mat_Thermal_RegAll
  USE AP_Inp_Orient, only: UF_Cmd_Orient_Surf_RegAll
  USE AP_Inp_Out, only: UF_Cmd_Out_RegAll
  USE AP_Inp_Output, only: UF_Cmd_Output_RegAll
  USE AP_Inp_Param, only: ParseKeyValueStr
  USE AP_Inp_Post, only: UF_Cmd_Post_RegAll
  USE AP_Inp_Sect, only: UF_Cmd_Sect_RegAll
  USE AP_Inp_Solv, only: UF_Cmd_Solv_RegAll
  USE AP_Inp_Spec, only: UF_Cmd_Spec_RegAll
  USE AP_Inp_Step, only: UF_Cmd_Step_RegAll
  USE AP_InpScript_User, only: UF_Cmd_User_RegAll
  USE AP_Inp_UX, only: UF_Cmd_UX_RegAll
  USE IF_Step_Type, only: RT_STEP_TYPE_STATIC, RT_STEP_TYPE_IMPL_DYN, RT_STEP_TYPE_EXPL_DYN
  
  ! UFC Runtime API imports?L6?L5  ?RunModel   ctx?
  ! UFC API imports - via Bridge modules
  USE AP_Brg_L3, only: MaterialDesc, ModelTree, UF_PartDef, StepDesc, &
                                    Part_Init_In, Part_Init_Out, Part_Init_Structured, &
                                    MaterialDef_Init_In, MaterialDef_Init_Structured, &
                                    MaterialDesc_Init_Structured_Wrapper, &
                                    Step_Init_In, Step_Init_Out, Step_Init_Structured
  USE AP_Brg_L5, only: RT_Sol_Cfg
  ! UFC Runtime API imports - via Bridge modules
  USE AP_Brg_L3, only: TreeMgr, NODE_TYPE_PART, NODE_TYPE_MATER, NODE_TYPE_STEP
  USE AP_Brg_L5, only: UF_Model, UF_RT_JobStatus, UF_JobStatus_Success, &
                                    RT_RunModel_Ctx, RT_Drv_Ctx
  USE MD_Model_Lib_Core, ONLY: MD_MODEL_UF_JOBSTATUS_InputError
  ! Step/solver entry points go through AP_BrgL5 (not direct USE of L5_RT step modules here).
  
  implicit none
  private
  
  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: UF_Cmd_UFC_RegAll
  
contains
  
  !===============================================================================
  ! Reg All UFC Commands
  !===============================================================================
  subroutine UF_Cmd_UFC_RegAll(status)
    type(ErrorStatusType), intent(out), optional :: status
    
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    
    ! Reg geometry commands (Phase 1)
    call UF_Cmd_Geom_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg material commands (Phase 1)
    call UF_Cmd_Mat_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg advanced material commands - Damage/Failure (Phase 1+)
    call UF_Cmd_Mat_Damage_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg advanced material commands - Geomechanics (Phase 1+)
    call UF_Cmd_Mat_Geomech_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg advanced material commands - Concrete (Phase 1+)
    call UF_Cmd_Mat_Concrete_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg advanced material commands - Porous Materials (Phase 1+)
    call UF_Cmd_Mat_Porous_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg advanced material commands - Foam Materials (Phase 1+)
    call UF_Cmd_Mat_Foam_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg advanced material commands - Geomechanics Advanced (Phase 1+)
    call UF_Cmd_Mat_GeoAdv_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg advanced material commands - Hyperelastic/Viscoelastic (Phase 1+)
    call UF_Cmd_Mat_Hyper_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg thermal material commands (Phase 1+)
    call UF_Cmd_Mat_Thermal_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg section commands (Phase 1)
    call UF_Cmd_Sect_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg load/BC commands (Phase 2)
    call UF_Cmd_Ldbc_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg step/solver/output commands (Phase 3)
    call UF_Cmd_Step_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    call UF_Cmd_Solv_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    call UF_Cmd_Out_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg post-processing commands (Phase 4)
    call UF_Cmd_Post_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg advanced feature commands (Phase 5)
    call UF_Cmd_Cont_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    call UF_Cmd_Const_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg connector commands (Phase 5+)
    call UF_Cmd_Connector_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg field commands (Phase 6 - Mid Priority)
    call UF_Cmd_Field_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg special commands (Phase 6 - Mid Priority)
    call UF_Cmd_Spec_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    call UF_Cmd_Amp_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg initial/control commands (Phase 6+)
    call UF_Cmd_Init_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg user subroutine commands (Phase 6+)
    call UF_Cmd_User_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg special element commands (Phase 6+)
    call UF_Cmd_Elem_Spcl_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg orientation and surface commands (Phase 6+)
    call UF_Cmd_Orient_Surf_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg output control commands (Phase 6+)
    call UF_Cmd_Output_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Init Keyword Bridge and sync metadata (Phase 6)
    call UF_Cmd_KWBrg_Init(local_status)
    if (local_status%status_code == IF_STATUS_OK) then
      call UF_Cmd_KWBrg_Sync(local_status)
      ! Continue even if sync fails (fallback to manual metadata)
    end if
    
    ! Reg UX commands (Phase 6)
    call UF_Cmd_UX_RegAll(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Reg basic commands
    call Cmd_Reg('init', Cmd_Init, 'Init analysis', local_status)
    call Cmd_Reg('tang', Cmd_Tangent, 'Compute tangent stiffness', local_status)
    call Cmd_Reg('form', Cmd_Form, 'Form system matrix', local_status)
    call Cmd_Reg('solv', Cmd_Solv, 'Solve linear system', local_status)
    call Cmd_Reg('iter', Cmd_Iterate, 'Nonlinear iteration', local_status)
    call Cmd_Reg('disp', Cmd_Displacement, 'Output displacement', local_status)
    call Cmd_Reg('plot', Cmd_Plot, 'Plot results', local_status)
    
    ! Reg step commands
    call Cmd_Reg('step', Cmd_Step, 'Create analysis step', local_status)
    call Cmd_Reg('inc', Cmd_Increment, 'Create increment', local_status)
    
    ! Reg model commands
    call Cmd_Reg('part', Cmd_Part, 'Define part', local_status)
    call Cmd_Reg('mat', Cmd_Mat, 'Define material', local_status)
    call Cmd_Reg('load', Cmd_Load, 'Apply load', local_status)
    call Cmd_Reg('bc', Cmd_BC, 'Apply boundary condition', local_status)
    
    ! Reg control commands
    call Cmd_Reg('run', Cmd_Run, 'Run analysis', local_status)
    call Cmd_Reg('stop', Cmd_Stop, 'Stop execution', local_status)
    call Cmd_Reg('jump', Cmd_Jump, 'Jump to label', local_status)
    call Cmd_Reg('break', Cmd_Break, 'Break from loop', local_status)
    call Cmd_Reg('cont', Cmd_Continue, 'Continue loop', local_status)
    call Cmd_Reg('hist', Cmd_History, 'Show/edit history', local_status)
    
    ! Reg utility commands
    call Cmd_Reg('help', Cmd_Help, 'Show command help', local_status)
    call Cmd_Reg('debug', Cmd_Debug, 'Debug commands', local_status)
    call Cmd_Reg('label', Cmd_Label, 'Define label', local_status)
    call Cmd_Reg('echo', Cmd_Echo, 'Echo message', local_status)
    call Cmd_Reg('set', Cmd_Set, 'Set variable', local_status)
    call Cmd_Reg('alias', Cmd_Alias, 'Define command alias', local_status)
    
    if (present(status)) status = local_status
    
  end subroutine UF_Cmd_UFC_RegAll
  
  !===============================================================================
  ! Command Handlers
  !===============================================================================
  
  !-------------------------------------------------------------------------------
  ! INIT - Init Analysis
  !-------------------------------------------------------------------------------
  subroutine Cmd_Init(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    ! Init context
    ctx%step_id = 0
    ctx%inc_id = 0
    ctx%iter_id = 0
    
    if (ctx%verbose) then
      write(*,*) 'Command INIT: Analysis initialized'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Init
  
  !-------------------------------------------------------------------------------
  ! TANG - Compute Tangent Stiffness
  !-------------------------------------------------------------------------------
  subroutine Cmd_Tangent(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! For now, mark that tangent needs to be computed
    ! Actual computation will be done in FORM or SOLV command
    
    if (ctx%verbose) then
      write(*,*) 'Command TANG: Tangent stiffness flag set'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Tangent
  
  !-------------------------------------------------------------------------------
  ! FORM - Form System Matrix (Debug/Manual Ctrl)
  ! Note: In normal analysis, matrix assembly happens automatically during step execution
  !-------------------------------------------------------------------------------
  subroutine Cmd_Form(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! Form system matrix for current step
    ! Note: This is a debug/manual control command
    ! In normal analysis, matrix assembly happens automatically during step execution
    ! For now, we mark that matrix needs to be formed
    ! Actual implementation would call runtime API:
    ! CALL RT_FormSystemMatrix(ctx%model, ctx%step_id, status)
    
    if (ctx%verbose) then
      write(*,'(A,I0)') 'Command FORM: System matrix formation requested for step ', ctx%step_id
      write(*,'(A)') '  Note: Matrix assembly typically happens automatically during step execution'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Form
  
  !-------------------------------------------------------------------------------
  ! SOLV - Solve Linear System (Debug/Manual Ctrl)
  ! Note: In normal analysis, solving happens automatically during step execution
  !-------------------------------------------------------------------------------
  subroutine Cmd_Solv(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    if (.not. associated(ctx%solver)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Solver not associated'
      return
    end if
    
    ! Solve linear system for current step
    ! Note: This is a debug/manual control command
    ! In normal analysis, solving happens automatically during step execution
    ! For now, we mark that system needs to be solved
    ! Actual implementation would call runtime API:
    ! CALL RT_SolveLinearSystem(ctx%model, ctx%solver, ctx%step_id, status)
    
    if (ctx%verbose) then
      write(*,'(A,I0)') 'Command SOLV: Linear system solution requested for step ', ctx%step_id
      write(*,'(A)') '  Note: Solving typically happens automatically during step execution'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Solv
  
  !-------------------------------------------------------------------------------
  ! ITER - Nonlinear Iteration
  !-------------------------------------------------------------------------------
  subroutine Cmd_Iterate(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! TODO: Nonlinear iteration
    ! CALL RT_NonlinearIteration(ctx%model, ctx%step_id, ctx%inc_id, status)
    
    ctx%iter_id = ctx%iter_id + 1
    
    if (ctx%verbose) then
      write(*,'(A,I0)') 'Command ITER: Iteration ', ctx%iter_id
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Iterate
  
  !-------------------------------------------------------------------------------
  ! DISP - Output Displacement
  !-------------------------------------------------------------------------------
  subroutine Cmd_Displacement(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! TODO: Output displacement
    ! CALL RT_Step_OutputDisplacement(ctx%model, ctx%step_id, status)
    
    if (ctx%verbose) then
      write(*,*) 'Command DISP: Displacement output'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Displacement
  
  !-------------------------------------------------------------------------------
  ! PLOT - Plot Results
  !-------------------------------------------------------------------------------
  subroutine Cmd_Plot(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! TODO: Plot results
    ! CALL RT_Step_Plot(ctx%model, ctx%step_id, cmd%opt, status)
    
    if (ctx%verbose) then
      write(*,*) 'Command PLOT: Results plotted'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Plot
  
  !-------------------------------------------------------------------------------
  ! STEP - Create Analysis Step
  !-------------------------------------------------------------------------------
  subroutine Cmd_Step(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(StepDesc), pointer :: step_desc => null()
    integer(i4) :: step_type, ios
    character(len=64) :: step_name
    real(wp) :: time_period, init_incr
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! Parse step parameters
    step_name = cmd%opt
    if (len_trim(step_name) == 0) then
      write(step_name, '(A,I0)') 'Step', ctx%step_id + 1
    end if
    
    ! Determine step type from param_str or params
    step_type = RT_STEP_TYPE_STATIC  ! Default
    if (index(cmd%param_str, 'static') > 0) then
      step_type = RT_STEP_TYPE_STATIC
    else if (index(cmd%param_str, 'dynamic') > 0 .or. index(cmd%param_str, 'implicit') > 0) then
      step_type = RT_STEP_TYPE_IMPL_DYN
    else if (index(cmd%param_str, 'explicit') > 0) then
      step_type = RT_STEP_TYPE_EXPL_DYN
    end if
    
    ! Get time period and initial increment
    time_period = cmd%params(1)
    if (time_period <= 0.0_wp) time_period = 1.0_wp
    init_incr = cmd%params(2)
    if (init_incr <= 0.0_wp) init_incr = 0.1_wp * time_period
    
    ! Create step descriptor
    allocate(step_desc, stat=ios)
    if (ios /= 0) then
      status%status_code = IF_STATUS_ERROR
      call Cmd_FormatError(cmd, 'Failed to allocate step descriptor', status%message)
      return
    end if
    ! Use structured interface for step initialization
    type(Step_Init_In) :: step_init_in
    type(Step_Init_Out) :: step_init_out
    
    step_init_in%number = ctx%step_id + 1
    step_init_in%name = step_name
    call Step_Init_Structured(step_init_in, step_init_out, step_desc)
    if (step_init_out%status%status_code /= IF_STATUS_OK) then
      status = step_init_out%status
      return
    end if
    step_desc%time_period = time_period
    step_desc%time_increment = init_incr
    
    ! Add step to model (if model has step manager)
    ctx%step_id = ctx%step_id + 1
    
    if (ctx%verbose) then
      write(*,'(A,A,A,I0,A,I0)') 'Command STEP: Step "', trim(step_name), &
        '" created (ID=', ctx%step_id, ', Type=', step_type, ')'
    end if
    
    deallocate(step_desc)
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Step
  
  !-------------------------------------------------------------------------------
  ! INC - Create Increment
  !-------------------------------------------------------------------------------
  subroutine Cmd_Increment(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! TODO: Create increment
    ! CALL RT_Inc_Create(ctx%model, ctx%step_id, cmd%params(1), status)
    
    ctx%inc_id = ctx%inc_id + 1
    
    if (ctx%verbose) then
      write(*,'(A,I0,A,ES12.4)') 'Command INC: Increment ', ctx%inc_id, ' created (dt=', cmd%params(1), ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Increment
  
  !-------------------------------------------------------------------------------
  ! PART - Define Part
  !-------------------------------------------------------------------------------
  subroutine Cmd_Part(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    ! USE statements moved to module level via Bridge
    type(UF_PartDef), pointer :: part => null()
    type(ModelTree), pointer :: model_tree => null()
    class(PartDesc), pointer :: existing_part => null()
    character(len=64) :: part_name
    integer(i4) :: ios
    type(Part_Init_In) :: part_init_in
    type(Part_Init_Out) :: part_init_out
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! Get model tree
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    part_name = cmd%opt
    if (len_trim(part_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Part name required'
      return
    end if
    
    ! Check if part already exists
    existing_part => model_tree%GetPart(name=part_name)
    if (associated(existing_part)) then
      ! Use existing part
      ctx%current_part => existing_part
    else
      ! Create new part using structured interface
      allocate(part, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate part descriptor', status%message)
        return
      end if
      
      ! Use structured interface
      part_init_in%name = part_name
      part_init_in%num_nodes = 1000
      part_init_in%num_elements = 1000
      part_init_in%cfg%ndim = 3
      call Part_Init_Structured(part_init_in, part_init_out, part)
      if (part_init_out%status%status_code /= IF_STATUS_OK) then
        status = part_init_out%status
        deallocate(part)
        return
      end if
      
      ! Add part to model tree
      call model_tree%AddPart(part, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(part)
        return
      end if
      
      ! Set as current part
      ctx%current_part => part
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command PART: Part "', trim(part_name), '" activated'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Part
  
  !-------------------------------------------------------------------------------
  ! MAT - Define Material (Enhanced with material types)
  ! Syntax: mat,name,type=elastic,E=200000,nu=0.3,rho=7800
  !         mat,name,type=plastic_j2,E=200000,nu=0.3,sigma_y=300,E_t=2000
  !         mat,name,type=hyperelastic,C10=0.5,C01=0.1
  !-------------------------------------------------------------------------------
  subroutine Cmd_Mat(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    ! ParseMaterialParams from AP_InpMat (USE at module level)
    type(MaterialDesc), pointer :: material => null()
    type(ModelTree), pointer :: model_tree => null()
    class(MaterialDesc), pointer :: existing_material => null()
    character(len=64) :: mat_name, param_str
    integer(i4) :: mat_type, num_props, ios
    real(wp) :: props(20)
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! Get model tree
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    mat_name = cmd%opt
    if (len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Material name required'
      return
    end if
    
    ! Check if material already exists
    existing_material => model_tree%GetMaterial(name=mat_name)
    if (associated(existing_material)) then
      ! Material already exists, just update properties if needed
      material => existing_material
      param_str = cmd%param_str
      call ParseMaterialParams(param_str, mat_type, props, num_props, status)
      if (status%status_code /= IF_STATUS_OK) return
      ! TODO: Update existing material properties
    else
      ! Create new material using structured interface via wrapper
      allocate(material, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_ERROR
        call Cmd_FormatError(cmd, 'Failed to allocate material descriptor', status%message)
        return
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = mat_type
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
      
      ! Parse and set material properties
      param_str = cmd%param_str
      call ParseMaterialParams(param_str, mat_type, props, num_props, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
      
      ! Add material to model tree
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
      end if
      
      ! Use structured interface via wrapper function
      type(MaterialDef_Init_In) :: mat_init_in
      
      mat_init_in%name = mat_name
      mat_init_in%mat_type = 0  ! default
      call MaterialDesc_Init_Structured_Wrapper(mat_init_in, material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
      
      ! Parse material parameters using enhanced parser
      param_str = cmd%param_str
      call ParseMaterialParams(param_str, mat_type, props, num_props, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
      
      ! Set material type and properties
      ! TODO: material%mat_type = mat_type
      ! TODO: material%props(1:num_props) = props(1:num_props)
      
      ! Add material to model tree
      call model_tree%AddMaterial(material, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(material)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A,I0,A,I0)') 'Command MAT: Material "', trim(mat_name), &
        '" defined (type=', mat_type, ', props=', num_props, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Mat
  
  !-------------------------------------------------------------------------------
  ! LOAD - Apply Load
  !-------------------------------------------------------------------------------
  subroutine Cmd_Load(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! TODO: Apply load
    ! CALL RT_Load_Apply(ctx%model, ctx%step_id, cmd%opt, cmd%params, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command LOAD: Load "', trim(cmd%opt), '" applied'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Load
  
  !-------------------------------------------------------------------------------
  ! BC - Apply Boundary Condition
  !-------------------------------------------------------------------------------
  subroutine Cmd_BC(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! TODO: Apply boundary condition
    ! CALL RT_BC_Apply(ctx%model, ctx%step_id, cmd%opt, cmd%params, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command BC: Boundary condition "', trim(cmd%opt), '" applied'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_BC
  
  !-------------------------------------------------------------------------------
  ! RUN - Run Analysis
  !-------------------------------------------------------------------------------
  subroutine Cmd_Run(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_RT_JobStatus) :: job_status
    character(len=64) :: job_name
    logical :: found
    class(RT_Sol_Cfg), pointer :: solver_ptr => null()
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    if (.not. associated(ctx%solver)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Solver not associated'
      return
    end if
    
    ! Parse job name from command parameters
    job_name = 'Job-1'  ! Default job name
    call ParseKeyValueStr(cmd%param_str, 'name', job_name, found)
    if (.not. found .and. len_trim(cmd%opt) > 0) then
      job_name = cmd%opt
    end if
    
    solver_ptr => ctx%solver

    job_status%code = UF_JobStatus_Success
    job_status%message = ''

    block
      type(RT_Drv_Ctx) :: run_ctx
      call run_ctx%Init()
      select type(m => ctx%model)
      type is (UF_Model)
        call run_ctx%Bind(model=m, solver=solver_ptr, jobName=trim(job_name), rt_status=job_status)
        call RT_RunModel_Ctx(run_ctx)
      class default
        job_status%code = MD_MODEL_UF_JOBSTATUS_InputError
        job_status%message = 'Cmd_Run: ctx%model must be UF_Model (ModelTree -> UF_Model bridge TBD)'
      end select
    end block
    
    ! Check job status
    if (job_status%code == UF_JobStatus_Success) then
      status%status_code = IF_STATUS_OK
      if (ctx%verbose) then
        write(*,'(A,A,A)') 'Command RUN: Analysis "', trim(job_name), '" completed successfully'
      end if
    else
      status%status_code = IF_STATUS_ERROR
      write(status%message, '(A,A,A)') 'Analysis "', trim(job_name), '" failed: ' // trim(job_status%message)
      if (ctx%verbose) then
        write(*,'(A,A,A)') 'Command RUN: Analysis "', trim(job_name), '" failed'
        write(*,'(A,A)') '  Error: ', trim(job_status%message)
      end if
    end if
    
  end subroutine Cmd_Run
  
  !-------------------------------------------------------------------------------
  ! STOP - Stop Execution
  !-------------------------------------------------------------------------------
  subroutine Cmd_Stop(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (ctx%verbose) then
      write(*,*) 'Command STOP: Execution stopped'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Stop
  
  !-------------------------------------------------------------------------------
  ! JUMP - Jump to Label
  !-------------------------------------------------------------------------------
  subroutine Cmd_Jump(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=32) :: label_name
    integer(i4) :: cmd_index
    logical :: found
    
    call init_error_status(status)
    
    ! Get label name from option or param_str
    label_name = cmd%opt
    if (len_trim(label_name) == 0) then
      label_name = cmd%param_str
    end if
    if (len_trim(label_name) == 0) then
      ! Try to use params as line number
      if (cmd%params(1) > 0.0_wp) then
        write(label_name, '(I0)') int(cmd%params(1), i4)
      else
        status%status_code = IF_STATUS_INVALID
        call Cmd_FormatError(cmd, 'JUMP requires a label name or line number', status%message)
        return
      end if
    end if
    
    ! Resolve label
    cmd_index = Cmd_LabelResolve(label_name)
    if (cmd_index == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Label "' // trim(label_name) // '" not found', status%message)
      return
    end if
    
    ctx%jump_target = cmd_index
    if (ctx%verbose) then
      write(*,'(A,A,A,I0)') 'Command JUMP: Jumping to label "', trim(label_name), '" (index=', cmd_index, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Jump
  
  !-------------------------------------------------------------------------------
  ! BREAK - Break from Loop
  !-------------------------------------------------------------------------------
  subroutine Cmd_Break(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: break_level
    
    call init_error_status(status)
    
    ! Parse break level (default = 1, break from innermost loop)
    break_level = int(cmd%params(1))
    if (break_level <= 0) break_level = 1
    
    ctx%break_level = break_level
    
    if (ctx%verbose) then
      write(*,'(A,I0)') 'Command BREAK: Breaking from ', break_level, ' loop(s)'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Break
  
  !-------------------------------------------------------------------------------
  ! CONTINUE - Continue Loop
  !-------------------------------------------------------------------------------
  subroutine Cmd_Continue(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: continue_level
    
    call init_error_status(status)
    
    ! Parse continue level (default = 1, continue innermost loop)
    continue_level = int(cmd%params(1))
    if (continue_level <= 0) continue_level = 1
    
    ctx%continue_level = continue_level
    
    if (ctx%verbose) then
      write(*,'(A,I0)') 'Command CONTINUE: Continuing ', continue_level, ' loop(s)'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Continue
  
  !-------------------------------------------------------------------------------
  ! HISTORY - Show/Edit History
  !-------------------------------------------------------------------------------
  subroutine Cmd_History(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: n_hist, i
    type(Cmd) :: hist_cmd
    character(len=64) :: action
    character(len=256) :: filename
    
    call init_error_status(status)
    
    action = cmd%opt
    if (len_trim(action) == 0) action = 'show'
    
    if (trim(action) == 'show' .or. trim(action) == 'list') then
      ! TODO: Get number of history entries
      n_hist = 0
      if (ctx%verbose) then
        write(*,'(A,I0,A)') 'Command History (', n_hist, ' commands):'
        ! TODO: Show history entries
      end if
    else if (trim(action) == 'clear') then
      call Cmd_HistoryClear(status)
      if (ctx%verbose) then
        write(*,*) 'Command HISTORY: History cleared'
      end if
    else if (trim(action) == 'save') then
      filename = cmd%param_str
      if (len_trim(filename) == 0) filename = 'command_history.cmd'
      ! TODO: Save history
      if (ctx%verbose) then
        write(*,'(A,A,A)') 'Command HISTORY: Saved to ', trim(filename)
      end if
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_History
  
  !-------------------------------------------------------------------------------
  ! HELP - Show Command Help
  !-------------------------------------------------------------------------------
  subroutine Cmd_Help(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: cmd_name, action
    
    call init_error_status(status)
    
    action = cmd%opt
    cmd_name = cmd%param_str
    
    if (len_trim(action) == 0) action = 'all'
    
    if (trim(action) == 'all' .or. trim(action) == 'list') then
      call Cmd_HelpShow('', status)
    else if (trim(action) == 'search' .and. len_trim(cmd_name) > 0) then
      call Cmd_HelpSearch(cmd_name, status)
    else if (len_trim(cmd_name) > 0) then
      call Cmd_HelpShow(cmd_name, status)
    else
      call Cmd_HelpShow('', status)
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Help
  
  !-------------------------------------------------------------------------------
  ! DEBUG - Debug Commands
  !-------------------------------------------------------------------------------
  subroutine Cmd_Debug(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: action
    integer(i4) :: line_num
    
    call init_error_status(status)
    
    action = cmd%opt
    if (len_trim(action) == 0) action = 'vars'
    
    if (trim(action) == 'vars' .or. trim(action) == 'variables') then
      call Cmd_DebugShowVars(ctx, status)
    else if (trim(action) == 'stack') then
      ! TODO: Show stack
      if (ctx%verbose) then
        write(*,*) 'Command DEBUG: Stack information'
      end if
    else if (trim(action) == 'break' .or. trim(action) == 'breakpoint') then
      line_num = int(cmd%params(1))
      if (line_num > 0) then
        call Cmd_DebugSetBrk(line_num, status)
      end if
    else if (trim(action) == 'step') then
      ! TODO: Step execution
      if (ctx%verbose) then
        write(*,*) 'Command DEBUG: Step mode'
      end if
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Debug
  
  !-------------------------------------------------------------------------------
  ! LABEL - Define Label
  !-------------------------------------------------------------------------------
  subroutine Cmd_Label(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=32) :: label_name
    
    call init_error_status(status)
    
    ! Label name from option or param_str
    label_name = cmd%opt
    if (len_trim(label_name) == 0) then
      label_name = cmd%param_str
    end if
    
    if (len_trim(label_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'LABEL requires a label name', status%message)
      return
    end if
    
    ! Label is registered during parsing, so just acknowledge
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command LABEL: Label "', trim(label_name), '" defined'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Label
  
  !-------------------------------------------------------------------------------
  ! ECHO - Echo Message
  !-------------------------------------------------------------------------------
  subroutine Cmd_Echo(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=256) :: message
    
    call init_error_status(status)
    
    ! Get message from option or param_str
    message = cmd%opt
    if (len_trim(message) == 0) then
      message = cmd%param_str
    end if
    
    ! Echo message
    write(*,'(A)') trim(message)
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Echo
  
  !-------------------------------------------------------------------------------
  ! SET - Set Variable
  !-------------------------------------------------------------------------------
  subroutine Cmd_Set(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=32) :: var_name
    real(wp) :: var_value
    integer(i4) :: ios
    
    call init_error_status(status)
    
    ! Variable name from option
    var_name = cmd%opt
    if (len_trim(var_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'SET requires a variable name', status%message)
      return
    end if
    
    ! Variable value from params or param_str
    var_value = cmd%params(1)
    if (abs(var_value) < 1.0e-30_wp .and. len_trim(cmd%param_str) > 0) then
      read(cmd%param_str, *, iostat=ios) var_value
      if (ios /= 0) var_value = 0.0_wp
    end if
    
    ! Set variable
    call Cmd_SetVar(ctx, var_name, var_value, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    if (ctx%verbose) then
      write(*,'(A,A,A,ES15.8)') 'Command SET: Variable "', trim(var_name), '" = ', var_value
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Set
  
  !-------------------------------------------------------------------------------
  ! ALIAS - Define Command Alias
  !-------------------------------------------------------------------------------
  subroutine Cmd_Alias(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=32) :: alias_name, command_name, action
    type(Cmd) :: alias_cmd
    logical :: found
    
    call init_error_status(status)
    
    action = cmd%opt
    alias_name = cmd%param_str
    
    if (trim(action) == 'list' .or. len_trim(action) == 0) then
      ! TODO: List aliases
      if (ctx%verbose) then
        write(*,*) 'Command ALIAS: List aliases'
      end if
      return
    end if
    
    ! Parse alias definition: alias,short_name,full_command
    if (len_trim(alias_name) == 0) then
      alias_name = cmd%opt
      command_name = cmd%param_str
    else
      command_name = cmd%opt
    end if
    
    if (len_trim(alias_name) == 0 .or. len_trim(command_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'ALIAS requires alias name and command name', status%message)
      return
    end if
    
    ! Parse command name into Cmd structure
    ! For now, just store the command name
    alias_cmd%name = command_name
    alias_cmd%opt = ''
    alias_cmd%params = 0.0_wp
    alias_cmd%param_str = ''
    
    ! Define alias
    call Cmd_AliasDefine(alias_name, alias_cmd, status)
    if (status%status_code == IF_STATUS_OK .and. ctx%verbose) then
      write(*,'(A,A,A,A,A)') 'Command ALIAS: "', trim(alias_name), '" -> "', trim(command_name), '"'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Alias
  
end module AP_InpScript_UFC