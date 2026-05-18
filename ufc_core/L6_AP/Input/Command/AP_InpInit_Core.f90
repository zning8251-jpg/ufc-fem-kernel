!===============================================================================
! MODULE: AP_InpInit_Core
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Core
! BRIEF:  Initial condition commands (Temperature, Field, State, Geostatic).
!
! Process phases:
!   P0: UF_Cmd_Initial_RegAll (register all handlers)
!   P2: Cmd_InitialTemperature / Cmd_PredefinedField /
!       Cmd_InitialState / Cmd_GeostaticStress
!
! Status: FOUR-TYPE | Last verified: 2026-04-28
!===============================================================================

MODULE AP_InpInit_Core
  USE AP_Inp_Script, only: Cmd_Reg, Cmd_FormatError
  USE AP_Inp_Param, only: ParseKeyValue, PARSEKEYVALUERE, ParseKeyValueInt, ParseKeyValueStr, ParseArray
  USE AP_Inp_Def, only: Cmd, CmdCtx
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: i4, wp
  
  ! UFC LoadBC API imports (initial conditions treated as special loads) - via Bridge module
  USE AP_Brg_L3, only: UF_BCDef, UF_ThermalLoadDef, &
                        BC_TEMPERATURE, BC_DISPLACEMENT, &
                        TARGET_NODE, TARGET_NODESET, TARGET_ELEMSET, ModelTree
  
  implicit none
  private
  
  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: UF_Cmd_Initial_RegAll
  
contains

  subroutine Cmd_GeostaticStress(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: geostatic_name, elset_name
    real(wp) :: overburden_pressure, k0_coefficient
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
    
    ! Parse parameters (ABAQUS 2020 alignment)
    geostatic_name = cmd%opt
    elset_name = ''
    overburden_pressure = 0.0_wp
    k0_coefficient = 1.0_wp  ! Default: K0 = 1.0 (isotropic)
    
    if (len_trim(geostatic_name) == 0) then
      call ParseKeyValueStr(cmd%param_str, 'name', geostatic_name, found)
      if (.not. found) geostatic_name = 'GeostaticStress-1'
    end if
    
    call ParseKeyValueStr(cmd%param_str, 'elset', elset_name, found)
    if (.not. found) call ParseKeyValueStr(cmd%param_str, 'ELSET', elset_name, found)
    
    call PARSEKEYVALUERE(cmd%param_str, 'overburden_pressure', overburden_pressure, found, default_val=0.0_wp)
    call PARSEKEYVALUERE(cmd%param_str, 'k0', k0_coefficient, found, default_val=1.0_wp)
    if (.not. found) call PARSEKEYVALUERE(cmd%param_str, 'K0', k0_coefficient, found, default_val=1.0_wp)
    
    if (len_trim(elset_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'ELSET required', status%message)
      return
    end if
    
    ! TODO: Create GeostaticStressDef and add to initial condition manager
    ! type(GeostaticStressDef) :: geostatic_def
    ! geostatic_def%name = geostatic_name
    ! geostatic_def%elset_name = elset_name
    ! geostatic_def%overburden_pressure = overburden_pressure
    ! geostatic_def%k0_coefficient = k0_coefficient
    ! call model_tree%GetInitialConditionManager()%AddGeostaticStress(geostatic_def, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A,A,A,ES12.4,A,ES12.4)') 'Command GEOSTATIC_STRESS: Geostatic "', trim(geostatic_name), &
        '" for elset "', trim(elset_name), '" (overburden=', overburden_pressure, ', K0=', k0_coefficient, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_GeostaticStress

  subroutine Cmd_InitialState(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: state_name, state_type_str, elset_name, values_str
    integer(i4) :: state_type
    real(wp) :: state_values(20)
    integer(i4) :: num_values
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
    
    ! Parse parameters (ABAQUS 2020 alignment)
    state_name = cmd%opt
    state_type = 1  ! 1=STRESS, 2=STRAIN, 3=SOLUTION DEPENDENT
    elset_name = ''
    state_values = 0.0_wp
    num_values = 0
    
    if (len_trim(state_name) == 0) then
      call ParseKeyValueStr(cmd%param_str, 'name', state_name, found)
      if (.not. found) state_name = 'InitialState-1'
    end if
    
    ! ABAQUS: TYPE=STRESS/STRAIN/SOLUTION DEPENDENT
    call ParseKeyValueStr(cmd%param_str, 'type', state_type_str, found)
    if (.not. found) call ParseKeyValueStr(cmd%param_str, 'TYPE', state_type_str, found)
    if (found) then
      select case(trim(state_type_str))
      case('sigma', 'STRESS')
        state_type = 1
      case('strain', 'STRAIN')
        state_type = 2
      case('solution_dependent', 'SOLUTION DEPENDENT', 'SOLUTION_DEPENDENT')
        state_type = 3
      case default
        state_type = 1
      end select
    end if
    
    call ParseKeyValueStr(cmd%param_str, 'elset', elset_name, found)
    if (.not. found) call ParseKeyValueStr(cmd%param_str, 'ELSET', elset_name, found)
    
    call ParseKeyValueStr(cmd%param_str, 'values', values_str, found)
    if (found) then
      call ParseArray(values_str, state_values, num_values, 20)
    end if
    
    if (len_trim(elset_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'ELSET required', status%message)
      return
    end if
    
    ! TODO: Create InitialStateDef and add to initial condition manager
    ! type(InitialStateDef) :: state_def
    ! state_def%name = state_name
    ! state_def%state_type = state_type
    ! state_def%elset_name = elset_name
    ! state_def%state_values(1:num_values) = state_values(1:num_values)
    ! call model_tree%GetInitialConditionManager()%AddInitialState(state_def, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A,A,A,I0,A)') 'Command INITIAL_STATE: State "', trim(state_name), &
        '" for elset "', trim(elset_name), '" (type=', state_type, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_InitialState

  subroutine Cmd_InitialTemperature(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(UF_BCDef) :: temp_bc
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: nset_name
    integer(i4) :: node_id
    real(wp) :: temperature_value
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
    
    ! Parse parameters (ABAQUS 2020 alignment)
    nset_name = ''
    node_id = 0
    temperature_value = 0.0_wp
    
    call ParseKeyValueStr(cmd%param_str, 'nset', nset_name, found)
    if (.not. found) call ParseKeyValueStr(cmd%param_str, 'NSET', nset_name, found)
    
    call ParseKeyValueInt(cmd%param_str, 'node', node_id, found)
    if (.not. found) call ParseKeyValueInt(cmd%param_str, 'NODE', node_id, found)
    
    call PARSEKEYVALUERE(cmd%param_str, 'temperature', temperature_value, found)
    if (.not. found) call PARSEKEYVALUERE(cmd%param_str, 'TEMPERATURE', temperature_value, found)
    
    if (len_trim(nset_name) == 0 .and. node_id == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Node set name or node ID required', status%message)
      return
    end if
    
    ! Init temperature BC (initial condition)
    call temp_bc%init()
    temp_bc%bc_type = BC_TEMPERATURE
    
    if (len_trim(nset_name) > 0) then
      temp_bc%region_name = nset_name
      temp_bc%region_type = TARGET_NODESET
    else
      temp_bc%node_id = node_id
      temp_bc%region_type = TARGET_NODE
    end if
    
    temp_bc%magnitude = temperature_value
    temp_bc%dof_first = 11  ! Temperature DOF
    temp_bc%dof_last = 11
    
    ! TODO: Add to model's initial condition manager
    ! call model_tree%GetInitialConditionManager()%AddTemperature(temp_bc, status)
    
    if (ctx%verbose) then
      if (len_trim(nset_name) > 0) then
        write(*,'(A,A,A,ES12.4)') 'Command INITIAL_TEMPERATURE: Temperature on nset "', trim(nset_name), &
          '", value=', temperature_value
      else
        write(*,'(A,I0,A,ES12.4)') 'Command INITIAL_TEMPERATURE: Temperature on node ', node_id, &
          ', value=', temperature_value
      end if
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_InitialTemperature

  subroutine Cmd_PredefinedField(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: field_name, nset_name, elset_name
    integer(i4) :: field_id, variable_id
    real(wp) :: field_value
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
    
    ! Parse parameters (ABAQUS 2020 alignment)
    field_name = cmd%opt
    field_id = 1
    variable_id = 1
    nset_name = ''
    elset_name = ''
    field_value = 0.0_wp
    
    if (len_trim(field_name) == 0) then
      call ParseKeyValueStr(cmd%param_str, 'name', field_name, found)
      if (.not. found) field_name = 'PredefinedField-1'
    end if
    
    ! ABAQUS: FIELD=field_number (required)
    call ParseKeyValueInt(cmd%param_str, 'field', field_id, found)
    if (.not. found) call ParseKeyValueInt(cmd%param_str, 'FIELD', field_id, found)
    
    call ParseKeyValueInt(cmd%param_str, 'variable', variable_id, found)
    if (.not. found) call ParseKeyValueInt(cmd%param_str, 'VARIABLE', variable_id, found)
    
    call ParseKeyValueStr(cmd%param_str, 'nset', nset_name, found)
    if (.not. found) call ParseKeyValueStr(cmd%param_str, 'NSET', nset_name, found)
    
    call ParseKeyValueStr(cmd%param_str, 'elset', elset_name, found)
    if (.not. found) call ParseKeyValueStr(cmd%param_str, 'ELSET', elset_name, found)
    
    call PARSEKEYVALUERE(cmd%param_str, 'value', field_value, found, default_val=0.0_wp)
    
    if (field_id <= 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'FIELD number required', status%message)
      return
    end if
    
    if (len_trim(nset_name) == 0 .and. len_trim(elset_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Node set or element set required', status%message)
      return
    end if
    
    ! TODO: Create PredefinedFieldDef and add to initial condition manager
    ! type(PredefinedFieldDef) :: field_def
    ! field_def%name = field_name
    ! field_def%field_id = field_id
    ! field_def%variable_id = variable_id
    ! field_def%region_name = nset_name or elset_name
    ! field_def%field_value = field_value
    ! call model_tree%GetInitialConditionManager()%AddPredefinedField(field_def, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A,I0,A,I0)') 'Command PREDEFINED_FIELD: Field "', trim(field_name), &
        '" (field_id=', field_id, ', variable_id=', variable_id, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_PredefinedField

  subroutine UF_Cmd_Initial_RegAll(status)
    type(ErrorStatusType), intent(out), optional :: status
    
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    
    ! Phase B Tier 1: Initial condition commands (4 commands)
    call Cmd_Reg('initial_temperature', Cmd_InitialTemperature, 'Initial temperature field', local_status)
    call Cmd_Reg('predefined_field', Cmd_PredefinedField, 'Predefined field variables', local_status)
    call Cmd_Reg('initial_state', Cmd_InitialState, 'Initial state variables', local_status)
    call Cmd_Reg('geostatic_stress', Cmd_GeostaticStress, 'Geostatic sigma initialization', local_status)
    
    if (present(status)) status = local_status
    
  end subroutine UF_Cmd_Initial_RegAll
end MODULE AP_InpInit_Core