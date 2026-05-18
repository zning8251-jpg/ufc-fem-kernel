!===============================================================================
! MODULE: AP_Inp_Step
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Impl — analysis step command handlers
! BRIEF:  Analysis step commands (Static, Dynamic, Modal, Buckling, Frequency).
!
! Process phases:
!   P1: Cmd_Step / Cmd_Static / Cmd_Dynamic / Cmd_Frequency / Cmd_BoundaryCondition
!   P2: parse_step_parameters / validate_step_definition
!===============================================================================
MODULE AP_Inp_Step
  USE AP_Inp_Script, only: Cmd_Reg, Cmd_FormatError
  USE AP_Inp_Param, only: ParseKeyValue, PARSEKEYVALUERE, ParseKeyValueInt, ParseKeyValueStr, ParseArray
  USE AP_Inp_Def, only: Cmd, CmdCtx
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, only: i4, wp
  
  ! UFC Step API imports - via Bridge module
  USE AP_Brg_L3, only: ModelTree, UF_StepDef, UF_StepManager, &
                      PROC_STATIC, PROC_STATIC_RIKS, PROC_DYNAMIC_IMPLICIT, &
                      PROC_DYNAMIC_EXPLICIT, PROC_MODAL, PROC_FREQUENCY, &
                      PROC_BUCKLE, PROC_HEAT_TRANSFER, PROC_COUPLED_TEMP_DISP, &
                      NLGEOM_OFF, NLGEOM_ON, &
                      INTEG_NEWMARK_BETA, INTEG_HHT_ALPHA, INTEG_CENTRAL_DIFF, &
                      StepDesc, StepTree, &
                      Step_Init_Structured, Step_Init_In, Step_Init_Out, &
                      Step_SetProcedure_Structured, Step_SetProcedure_In, Step_SetProcedure_Out, &
                      Step_SetTime_Structured, Step_SetTime_In, Step_SetTime_Out
  
  implicit none
  private
  
  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: UF_Cmd_Step_RegAll
  
contains

  subroutine Cmd_Buckling(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(Cmd) :: step_cmd
    
    step_cmd = cmd
    step_cmd%param_str = trim(cmd%param_str) // ',type=buckling'
    call Cmd_Step(step_cmd, ctx, status)
    
  end subroutine Cmd_Buckling

  subroutine Cmd_CoupledTempDisp(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    ! USE statements moved to module level via Bridge
    type(UF_StepDef) :: step_def
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: step_name, steady_str, creep_str
    real(wp) :: time_period, init_incr, deltmx
    logical :: found, steady_state
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse parameters
    call ParseKeyValueStr(cmd%param_str, 'name', step_name, found)
    if (.not. found) step_name = 'CoupledTempDisp-1'
    
    call ParseKeyValueStr(cmd%param_str, 'steady_state', steady_str, found)
    steady_state = (index(steady_str, 'yes') > 0 .or. index(steady_str, 'true') > 0)
    
    call PARSEKEYVALUERE(cmd%param_str, 'time', time_period, found, default_val=1.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'dt', init_incr, found, default_val=0.1_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'deltmx', deltmx, found, default_val=0.0_wp)
    
    ! Init step definition using structured interfaces
    type(Step_Init_In) :: step_init_in
    type(Step_Init_Out) :: step_init_out
    type(Step_SetProcedure_In) :: proc_in
    type(Step_SetProcedure_Out) :: proc_out
    type(Step_SetTime_In) :: time_in
    type(Step_SetTime_Out) :: time_out
    
    ! Initialize step
    step_init_in%name = step_name
    step_init_in%number = 0  ! Will be set by step manager
    call Step_Init_Structured(step_init_in, step_init_out, step_def)
    if (step_init_out%status%status_code /= IF_STATUS_OK) then
      status = step_init_out%status
      return
    end if
    
    ! Set procedure
    proc_in%proc_type = PROC_COUPLED_TEMP_DISP
    proc_in%perturbation = .false.
    call Step_SetProcedure_Structured(proc_in, proc_out, step_def)
    if (proc_out%status%status_code /= IF_STATUS_OK) then
      status = proc_out%status
      return
    end if
    
    ! Set time parameters
    time_in%period = time_period
    time_in%start = 0.0_wp
    call Step_SetTime_Structured(time_in, time_out, step_def)
    if (time_out%status%status_code /= IF_STATUS_OK) then
      status = time_out%status
      return
    end if
    
    ! Set additional parameters (legacy direct assignment for now)
    step_def%init_incr = init_incr
    step_def%steady_state = steady_state
    if (deltmx > 0.0_wp) step_def%deltmx = deltmx
    
    ! Parse creep option
    call ParseKeyValueStr(cmd%param_str, 'creep', creep_str, found)
    if (found) then
      ! Set creep option (if supported by step_def)
      ! Note: UF_StepDef may not have direct creep flag, this would be handled in material properties
    end if
    
    ! Add step to model tree
    ! Note: StepDesc needs to be converted to TreeNodeBase for ModelTree
    ! For now, we'll create the step definition
    ! The actual addition to model_tree will be handled by the step management system
    ! TODO: Convert step_def to StepDesc and add to model_tree via AddStep
    ! call model_tree%AddStep(step_def, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command COUPLED_TEMP_DISP: Step "', trim(step_name), '" defined'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_CoupledTempDisp

  subroutine Cmd_Dynamic(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(Cmd) :: step_cmd
    character(len=64) :: dyn_type_str
    logical :: found
    
    ! Determine implicit or explicit
    call ParseKeyValueStr(cmd%param_str, 'type', dyn_type_str, found)
    if (.not. found) dyn_type_str = 'implicit'
    
    step_cmd = cmd
    step_cmd%param_str = trim(cmd%param_str) // ',type=dynamic_' // trim(dyn_type_str)
    
    ! Parse dynamic parameters
    ! TODO: Parse alpha, beta for HHT/Newmark
    
    call Cmd_Step(step_cmd, ctx, status)
    
  end subroutine Cmd_Dynamic

  subroutine Cmd_Explicit(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    ! USE statements moved to module level via Bridge
    type(UF_StepDef) :: step_def
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: step_name
    real(wp) :: time_period, init_incr, mass_scaling
    logical :: found
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse parameters
    call ParseKeyValueStr(cmd%param_str, 'name', step_name, found)
    if (.not. found) step_name = 'Explicit-1'
    
    call PARSEKEYVALUERE(cmd%param_str, 'time', time_period, found, default_val=1.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'dt', init_incr, found, default_val=1.0e-6_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'mass_scaling', mass_scaling, found, default_val=1.0_wp)
    
    ! Init step definition
    call step_def%init()
    step_def%name = step_name
    step_def%proc_type = PROC_DYNAMIC_EXPLICIT
    step_def%time_period = time_period
    step_def%init_incr = init_incr
    if (mass_scaling /= 1.0_wp) then
      ! Set mass scaling (if supported by step_def)
      ! Note: Mass scaling would be handled in explicit analysis parameters
    end if
    
    ! Add step to model tree
    ! Note: StepDesc needs to be converted to TreeNodeBase for ModelTree
    ! For now, we'll create the step definition
    ! The actual addition to model_tree will be handled by the step management system
    ! TODO: Convert step_def to StepDesc and add to model_tree via AddStep
    ! call model_tree%AddStep(step_def, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command EXPLICIT: Step "', trim(step_name), '" defined'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Explicit

  subroutine Cmd_Frequency(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(Cmd) :: step_cmd
    
    step_cmd = cmd
    step_cmd%param_str = trim(cmd%param_str) // ',type=frequency'
    call Cmd_Step(step_cmd, ctx, status)
    
  end subroutine Cmd_Frequency

  subroutine Cmd_HeatTransfer(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    ! USE statements moved to module level via Bridge
    type(UF_StepDef) :: step_def
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: step_name, steady_str
    real(wp) :: time_period, init_incr, deltmx
    logical :: found, steady_state
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse parameters
    call ParseKeyValueStr(cmd%param_str, 'name', step_name, found)
    if (.not. found) step_name = 'HeatTransfer-1'
    
    call ParseKeyValueStr(cmd%param_str, 'steady_state', steady_str, found)
    steady_state = (index(steady_str, 'yes') > 0 .or. index(steady_str, 'true') > 0)
    
    call PARSEKEYVALUERE(cmd%param_str, 'time', time_period, found, default_val=1.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'dt', init_incr, found, default_val=0.1_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'deltmx', deltmx, found, default_val=0.0_wp)
    
    ! Init step definition
    call step_def%init()
    step_def%name = step_name
    step_def%proc_type = PROC_HEAT_TRANSFER
    step_def%time_period = time_period
    step_def%init_incr = init_incr
    step_def%steady_state = steady_state
    if (deltmx > 0.0_wp) step_def%deltmx = deltmx
    
    ! TODO: Add step to model tree
    ! call model_tree%AddStep(step_def, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command HEAT_TRANSFER: Step "', trim(step_name), '" defined'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_HeatTransfer

  subroutine Cmd_Modal(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(Cmd) :: step_cmd
    integer(i4) :: num_modes
    real(wp) :: freq_range(2)
    logical :: found
    
    step_cmd = cmd
    step_cmd%param_str = trim(cmd%param_str) // ',type=modal'
    
    ! Parse modal parameters
    call ParseKeyValueInt(cmd%param_str, 'num_modes', num_modes, found, default_val=20)
    call ParseKeyValueStr(cmd%param_str, 'frequency_range', step_cmd%param_str, found)
    ! TODO: Parse frequency range
    
    call Cmd_Step(step_cmd, ctx, status)
    
  end subroutine Cmd_Modal

  subroutine Cmd_Static(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(Cmd) :: step_cmd
    
    step_cmd = cmd
    step_cmd%param_str = trim(cmd%param_str) // ',type=static'
    call Cmd_Step(step_cmd, ctx, status)
    
  end subroutine Cmd_Static

  subroutine Cmd_Step(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    ! USE statements moved to module level via Bridge
    type(UF_StepDef) :: step_def
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: step_name, step_type_str, nlgeom_str
    integer(i4) :: step_type, proc_type
    real(wp) :: time_period, init_incr, min_incr, max_incr
    integer(i4) :: max_incr_num
    logical :: found, nlgeom
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      model_tree => m
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      return
    end select
    
    ! Parse parameters
    step_name = cmd%opt
    proc_type = PROC_STATIC
    time_period = 1.0_wp
    init_incr = 0.1_wp
    min_incr = 1.0e-10_wp
    max_incr = 1.0_wp
    max_incr_num = 1000
    nlgeom = .false.
    
    if (len_trim(step_name) == 0) then
      call ParseKeyValueStr(cmd%param_str, 'name', step_name, found)
      if (.not. found) then
        write(step_name, '(A,I0)') 'Step', ctx%step_id + 1
      end if
    end if
    
    call ParseKeyValueStr(cmd%param_str, 'type', step_type_str, found)
    if (found) then
      select case(trim(step_type_str))
      case('static')
        proc_type = PROC_STATIC
      case('static_riks', 'riks')
        proc_type = PROC_STATIC_RIKS
      case('dynamic', 'dynamic_implicit', 'implicit')
        proc_type = PROC_DYNAMIC_IMPLICIT
      case('dynamic_explicit', 'explicit')
        proc_type = PROC_DYNAMIC_EXPLICIT
      case('modal')
        proc_type = PROC_MODAL
      case('frequency')
        proc_type = PROC_FREQUENCY
      case('buckling', 'buckle')
        proc_type = PROC_BUCKLE
      case('heat', 'heat_transfer')
        proc_type = PROC_HEAT_TRANSFER
      case('coupled_temp_disp', 'coupled')
        proc_type = PROC_COUPLED_TEMP_DISP
      case default
        proc_type = PROC_STATIC
      end select
    end if
    
    call PARSEKEYVALUERE(cmd%param_str, 'time', time_period, found, default_val=1.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'dt', init_incr, found)
    call PARSEKEYVALUERE(cmd%param_str, 'initial', init_incr, found)
    call PARSEKEYVALUERE(cmd%param_str, 'min', min_incr, found, default_val=1.0e-10_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'max', max_incr, found, default_val=1.0_wp)
    call ParseKeyValueInt(cmd%param_str, 'max_incr', max_incr_num, found, default_val=1000)
    call ParseKeyValueStr(cmd%param_str, 'nlgeom', nlgeom_str, found)
    if (found) then
      nlgeom = (trim(nlgeom_str) == 'on' .or. trim(nlgeom_str) == 'yes' .or. trim(nlgeom_str) == 'true')
    end if
    
    ! Create StepTree from step definition (StepTree extends StepDesc and TreeNodeBase)
    type(StepTree), allocatable, target :: step_tree
    allocate(step_tree)
    
    ! Init step description
    call step_tree%Init(status=status)
    if (status%status_code /= IF_STATUS_OK) then
      deallocate(step_tree)
      return
    end if
    
    ! Set step properties
    step_tree%name = step_name
    step_tree%cfg%id = ctx%step_id + 1
    
    ! Set procedure (P1 L6→L3: ensure steps(i)%procedure for L5 ProcToRTStepType)
    step_tree%procedure = proc_type
    ! Set step type based on procedure type
    select case(proc_type)
    case(PROC_STATIC)
      step_tree%stepType = 'STATIC'
      step_tree%analysisType = 'STATIC'
    case(PROC_DYNAMIC_IMPLICIT)
      step_tree%stepType = 'DYNAMIC'
      step_tree%analysisType = 'DYNAMIC'
    case(PROC_DYNAMIC_EXPLICIT)
      step_tree%stepType = 'EXPLICIT'
      step_tree%analysisType = 'DYNAMIC'
    case(PROC_MODAL)
      step_tree%stepType = 'MODAL'
      step_tree%analysisType = 'MODAL'
    case(PROC_BUCKLE)
      step_tree%stepType = 'BUCKLE'
      step_tree%analysisType = 'BUCKLE'
    case(PROC_FREQUENCY)
      step_tree%stepType = 'FREQUENCY'
      step_tree%analysisType = 'FREQUENCY'
    case(PROC_HEAT_TRANSFER)
      step_tree%stepType = 'HEAT_TRANSFER'
      step_tree%analysisType = 'THERMAL'
    case(PROC_COUPLED_TEMP_DISP)
      step_tree%stepType = 'COUPLED_TEMP_DISP'
      step_tree%analysisType = 'COUPLED'
    case default
      step_tree%stepType = 'STATIC'
      step_tree%analysisType = 'STATIC'
    end select
    
    ! Set time control
    step_tree%timeStart = 0.0_wp
    step_tree%timeEnd = time_period
    step_tree%totalTime = time_period
    step_tree%dtInit = init_incr
    step_tree%dtMin = min_incr
    step_tree%dtMax = max_incr
    step_tree%nIncs = max_incr_num
    
    ! Set nonlinear geometry flag
    step_tree%nlFlag = nlgeom
    
    ! Add step to model tree (StepTree extends TreeNodeBase, so it can be added)
    call model_tree%AddStep(step_tree, status)
    if (status%status_code /= IF_STATUS_OK) then
      deallocate(step_tree)
      return
    end if
    
    ctx%step_id = ctx%step_id + 1
    
    if (ctx%verbose) then
      write(*,'(A,A,A,I0)') 'Command STEP: Step "', trim(step_name), &
        '" created (type=', proc_type, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Step

  subroutine UF_Cmd_Step_RegAll(status)
    type(ErrorStatusType), intent(out), optional :: status
    
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    
    ! Step commands
    call Cmd_Reg('step', Cmd_Step, 'Analysis step', local_status)
    call Cmd_Reg('static', Cmd_Static, 'Static analysis step', local_status)
    call Cmd_Reg('dynamic', Cmd_Dynamic, 'Dynamic analysis step', local_status)
    call Cmd_Reg('modal', Cmd_Modal, 'Modal analysis step', local_status)
    call Cmd_Reg('buckling', Cmd_Buckling, 'Buckling analysis step', local_status)
    call Cmd_Reg('frequency', Cmd_Frequency, 'Frequency response step', local_status)
    
    ! Extended step commands
    call Cmd_Reg('heat_transfer', Cmd_HeatTransfer, 'Heat transfer analysis', local_status)
    call Cmd_Reg('coupled_temp_disp', Cmd_CoupledTempDisp, 'Coupled temperature-displacement', local_status)
    call Cmd_Reg('explicit', Cmd_Explicit, 'Explicit dynamic analysis', local_status)
    
    if (present(status)) status = local_status
    
  end subroutine UF_Cmd_Step_RegAll
end MODULE AP_Inp_Step