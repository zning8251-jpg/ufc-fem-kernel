!===============================================================================
! MODULE: AP_Inp_Init
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Impl — initial conditions command handlers
! BRIEF:  Initial conditions and predefined field commands.
!
! Process phases:
!   P1: Cmd_InitialConditions / Cmd_PredefinedField / Cmd_Amplitude
!   P2: parse_amplitude_tabular / parse_amplitude_smooth / set_initial_conditions
!===============================================================================
MODULE AP_Inp_Init
    USE AP_Inp_Script, only: Cmd_SetVar, Cmd_GetVar, Cmd_Reg
    USE AP_Inp_Param, only: ParseKeyValueStr, PARSEKEYVALUERE, ParseKeyValueInt
    USE AP_Inp_Def, only: Cmd, CmdCtx
    USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
    USE IF_Prec_Core, only: i4, wp
    ! UFC Init API imports - via Bridge module
    USE AP_Brg_L3, only: ModelTree, StepTree
    implicit none
    private
    
    public :: UF_Cmd_Init_RegAll
    public :: Cmd_InitialConditions
    public :: Cmd_PredefinedField
    public :: Cmd_Restart
    
contains

    subroutine Cmd_InitialConditions(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(ModelTree), pointer :: model_tree => null()
        character(len=64) :: ic_type, nset_name, elset_name
        real(wp) :: values(6)
        integer(i4) :: num_values, i, ios
        logical :: found
        
        call init_error_status(status)
        
        ! Valid context (Step 1: context 
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
        
        ! Parse parameters (Step 2:  param)
        ic_type = 'VELOCITY'  ! Default
        nset_name = ''
        elset_name = ''
        
        call ParseKeyValueStr(cmd%param_str, 'type', ic_type, found)
        if (.not. found) call ParseKeyValueStr(cmd%param_str, 'TYPE', ic_type, found)
        
        call ParseKeyValueStr(cmd%param_str, 'nset', nset_name, found)
        if (.not. found) call ParseKeyValueStr(cmd%param_str, 'NSET', nset_name, found)
        
        if (len_trim(nset_name) == 0) then
            call ParseKeyValueStr(cmd%param_str, 'elset', elset_name, found)
            if (.not. found) call ParseKeyValueStr(cmd%param_str, 'ELSET', elset_name, found)
        end if
        
        if (len_trim(nset_name) == 0 .and. len_trim(elset_name) == 0) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'INITIAL CONDITIONS requires NSET= or ELSET= parameter'
            return
        end if
        
        ! Read data line (Step 3:  
        if (.not. cmd%has_data .or. cmd%num_data_lines < 1) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'INITIAL CONDITIONS requires data line with initial values'
            return
        end if
        
        ! Parse initial values based on type
        num_values = 0
        values = 0.0_wp
        
        select case(trim(ic_type))
        case('VELOCITY', 'velocity')
            ! Format: vx, vy, vz[, omega_x, omega_y, omega_z]
            read(cmd%data_lines(1), *, iostat=ios) (values(i), i=1,6)
            if (ios /= 0) then
                read(cmd%data_lines(1), *, iostat=ios) (values(i), i=1,3)
                if (ios /= 0) then
                    status%status_code = IF_STATUS_INVALID
                    write(status%message, '(A)') 'Error parsing VELOCITY initial conditions'
                    return
                end if
                num_values = 3
            else
                num_values = 6
            end if
            
        case('TEMPERATURE', 'temperature')
            ! Format: T0
            read(cmd%data_lines(1), *, iostat=ios) values(1)
            if (ios /= 0) then
                status%status_code = IF_STATUS_INVALID
                write(status%message, '(A)') 'Error parsing TEMPERATURE initial condition'
                return
            end if
            num_values = 1
            
        case('STRESS', 'sigma')
            ! Format: S11, S22, S33, S12, S13, S23
            read(cmd%data_lines(1), *, iostat=ios) (values(i), i=1,6)
            if (ios /= 0) then
                status%status_code = IF_STATUS_INVALID
                write(status%message, '(A)') 'Error parsing STRESS initial conditions'
                return
            end if
            num_values = 6
            
        case('DISPLACEMENT', 'displacement')
            ! Format: u1, u2, u3[, theta1, theta2, theta3]
            read(cmd%data_lines(1), *, iostat=ios) (values(i), i=1,6)
            if (ios /= 0) then
                read(cmd%data_lines(1), *, iostat=ios) (values(i), i=1,3)
                if (ios /= 0) then
                    status%status_code = IF_STATUS_INVALID
                    write(status%message, '(A)') 'Error parsing DISPLACEMENT initial conditions'
                    return
                end if
                num_values = 3
            else
                num_values = 6
            end if
            
        case default
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A,A,A)') 'Unknown initial condition type: ', trim(ic_type)
            return
        end select
        
        ! Store to command context (Step 4:  context)
        call Cmd_SetVar(cmd, 'last_ic_type', ic_type, status)
        if (len_trim(nset_name) > 0) then
            call Cmd_SetVar(cmd, 'last_ic_region', nset_name, status)
        else
            call Cmd_SetVar(cmd, 'last_ic_region', elset_name, status)
        end if
        
        ! Future Model layer integration (Step 5:  Model :
        ! type(InitialCondition) :: ic
        ! ic%ic_type = trim(ic_type)
        ! ic%region_name = trim(nset_name) or trim(elset_name)
        ! ic%num_values = num_values
        ! allocate(ic%values(num_values))
        ! ic%values(1:num_values) = values(1:num_values)
        ! call model_tree%GetInitialConditionManager()%AddIC(ic, status)
        
        if (ctx%verbose) then
            if (len_trim(nset_name) > 0) then
                write(*,'(A,A,A,A,A)') 'Command INITIAL_CONDITIONS: Type=', trim(ic_type), &
                    ', Nset="', trim(nset_name), '"'
            else
                write(*,'(A,A,A,A,A)') 'Command INITIAL_CONDITIONS: Type=', trim(ic_type), &
                    ', Elset="', trim(elset_name), '"'
            end if
            write(*,'(A,I0,A)') '  Values: ', num_values, ' components'
        end if
        
        status%status_code = IF_STATUS_OK
        
    end subroutine Cmd_InitialConditions

    subroutine Cmd_PredefinedField(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(ModelTree), pointer :: model_tree => null()
        class(StepTree), pointer :: current_step => null()
        character(len=64) :: field_type, nset_name, amplitude_name
        real(wp) :: field_value
        integer(i4) :: field_number, ios
        logical :: found
        
        call init_error_status(status)
        
        ! Valid context
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
        field_type = 'TEMPERATURE'  ! Default
        nset_name = ''
        amplitude_name = ''
        field_number = 1  ! For FIELD type
        
        call ParseKeyValueStr(cmd%param_str, 'type', field_type, found)
        if (.not. found) call ParseKeyValueStr(cmd%param_str, 'TYPE', field_type, found)
        
        call ParseKeyValueStr(cmd%param_str, 'nset', nset_name, found)
        if (.not. found) call ParseKeyValueStr(cmd%param_str, 'NSET', nset_name, found)
        
        call ParseKeyValueStr(cmd%param_str, 'amplitude', amplitude_name, found)
        if (.not. found) call ParseKeyValueStr(cmd%param_str, 'AMPLITUDE', amplitude_name, found)
        
        call ParseKeyValueInt(cmd%param_str, 'variable', field_number, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'VARIABLE', field_number, found)
        
        if (len_trim(nset_name) == 0) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'PREDEFINED FIELD requires NSET= parameter'
            return
        end if
        
        ! Read data line
        if (.not. cmd%has_data .or. cmd%num_data_lines < 1) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'PREDEFINED FIELD requires data line with field value'
            return
        end if
        
        read(cmd%data_lines(1), *, iostat=ios) field_value
        if (ios /= 0) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'Error parsing PREDEFINED FIELD value'
            return
        end if
        
        ! Get current step
        if (ctx%step_id <= 0) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'No active step. Use STEP command first'
            return
        end if
        
        current_step => model_tree%GetStep(id=ctx%step_id)
        if (.not. associated(current_step)) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A,I0,A)') 'Step ', ctx%step_id, ' not found'
            return
        end if
        
        ! Store to command context
        call Cmd_SetVar(cmd, 'last_predefined_field_type', field_type, status)
        call Cmd_SetVar(cmd, 'last_predefined_field_nset', nset_name, status)
        
        ! Future Model layer integration:
        ! type(PredefinedField) :: pfield
        ! pfield%field_type = trim(field_type)
        ! pfield%region_name = trim(nset_name)
        ! pfield%amplitude_name = trim(amplitude_name)
        ! pfield%field_value = field_value
        ! pfield%field_number = field_number  ! For FIELD type
        ! call current_step%GetPredefinedFieldManager()%AddField(pfield, status)
        
        if (ctx%verbose) then
            write(*,'(A,A,A,A,A,ES12.4)') 'Command PREDEFINED_FIELD: Type=', trim(field_type), &
                ', Nset="', trim(nset_name), '", Value=', field_value
            if (len_trim(amplitude_name) > 0) then
                write(*,'(A,A,A)') '  Amplitude: "', trim(amplitude_name), '"'
            end if
        end if
        
        status%status_code = IF_STATUS_OK
        
    end subroutine Cmd_PredefinedField

    subroutine Cmd_Restart(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(ModelTree), pointer :: model_tree => null()
        character(len=64) :: write_str, read_str, overlay_str
        integer(i4) :: frequency, start_step, start_inc
        logical :: write_restart, read_restart, overlay
        logical :: found
        
        call init_error_status(status)
        
        ! Valid context
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
        write_restart = .false.
        read_restart = .false.
        overlay = .false.
        frequency = 1  ! Default: write every increment
        start_step = 1
        start_inc = 1
        
        ! Check WRITE mode
        call ParseKeyValueStr(cmd%param_str, 'write', write_str, found)
        if (found) then
            write_restart = (index(write_str, 'yes') > 0 .or. index(write_str, 'true') > 0 .or. &
                           index(write_str, 'YES') > 0 .or. index(write_str, 'TRUE') > 0)
        end if
        if (.not. found) then
            ! Check for WRITE keyword without value
            if (index(cmd%param_str, 'WRITE') > 0 .or. index(cmd%param_str, 'write') > 0) then
                write_restart = .true.
            end if
        end if
        
        ! Check READ mode
        call ParseKeyValueStr(cmd%param_str, 'read', read_str, found)
        if (found) then
            read_restart = (index(read_str, 'yes') > 0 .or. index(read_str, 'true') > 0 .or. &
                          index(read_str, 'YES') > 0 .or. index(read_str, 'TRUE') > 0)
        end if
        if (.not. found) then
            ! Check for READ keyword without value
            if (index(cmd%param_str, 'READ') > 0 .or. index(cmd%param_str, 'read') > 0) then
                read_restart = .true.
            end if
        end if
        
        ! Parse frequency
        call ParseKeyValueInt(cmd%param_str, 'frequency', frequency, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'FREQUENCY', frequency, found)
        
        if (frequency < 1) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'RESTART frequency must be positive'
            return
        end if
        
        ! Parse overlay option
        call ParseKeyValueStr(cmd%param_str, 'overlay', overlay_str, found)
        if (found) then
            overlay = (index(overlay_str, 'yes') > 0 .or. index(overlay_str, 'true') > 0 .or. &
                      index(overlay_str, 'YES') > 0 .or. index(overlay_str, 'TRUE') > 0)
        end if
        if (.not. found) then
            if (index(cmd%param_str, 'OVERLAY') > 0 .or. index(cmd%param_str, 'overlay') > 0) then
                overlay = .true.
            end if
        end if
        
        ! Parse restart step/inc for READ mode
        call ParseKeyValueInt(cmd%param_str, 'step', start_step, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'STEP', start_step, found)
        
        call ParseKeyValueInt(cmd%param_str, 'inc', start_inc, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'INC', start_inc, found)
        
        ! Valid mode
        if (.not. write_restart .and. .not. read_restart) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'RESTART requires WRITE or READ mode'
            return
        end if
        
        ! Store to command context
        if (write_restart) then
            call Cmd_SetVar(cmd, 'restart_mode', 'WRITE', status)
        else
            call Cmd_SetVar(cmd, 'restart_mode', 'READ', status)
        end if
        
        ! Future Model layer integration:
        ! type(RestartConfig) :: restart_cfg
        ! restart_cfg%write_enabled = write_restart
        ! restart_cfg%read_enabled = read_restart
        ! restart_cfg%write_frequency = frequency
        ! restart_cfg%overlay = overlay
        ! restart_cfg%start_step = start_step
        ! restart_cfg%start_inc = start_inc
        ! call model_tree%GetSolverConfig()%SetRestart(restart_cfg, status)
        ! 
        ! Restart file naming convention:
        ! - job_name.res (restart file)
        ! - job_name.mdl (model database)
        ! - job_name.prt (part file)
        
        if (ctx%verbose) then
            if (write_restart) then
                write(*,'(A,I0)') 'Command RESTART: Write mode enabled, frequency=', frequency
                if (overlay) then
                    write(*,'(A)') '  Overlay mode: ON (single restart file)'
                else
                    write(*,'(A)') '  Overlay mode: OFF (multiple restart files)'
                end if
            end if
            if (read_restart) then
                write(*,'(A,I0,A,I0)') 'Command RESTART: Read mode, step=', start_step, ', inc=', start_inc
            end if
        end if
        
        status%status_code = IF_STATUS_OK
        
    end subroutine Cmd_Restart

    subroutine UF_Cmd_Init_RegAll(status)
        type(ErrorStatusType), intent(out), optional :: status
        type(ErrorStatusType) :: local_status
        
        if (present(status)) call init_error_status(status)
        
        ! Initial and control commands
        call Cmd_Reg('initial_conditions', Cmd_InitialConditions, 'Initial conditions', local_status)
        call Cmd_Reg('predefined_field', Cmd_PredefinedField, 'Predefined field', local_status)
        call Cmd_Reg('restart', Cmd_Restart, 'Restart control', local_status)
        
        if (present(status)) status = local_status
    end subroutine UF_Cmd_Init_RegAll
end MODULE AP_Inp_Init