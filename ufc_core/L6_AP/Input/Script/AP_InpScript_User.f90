!===============================================================================
! MODULE: AP_InpScript_User
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl — user subroutine commands
! BRIEF:  User subroutine commands for UFC Command System.
!
! Process phases:
!   P0: UF_Cmd_User_RegAll
!   P1: Cmd_UserMaterial / Cmd_UserElement / Cmd_UserSubroutine
!===============================================================================

module AP_InpScript_User
    USE AP_Inp_Script, only: Cmd_SetVar, Cmd_GetVar, Cmd_Reg
    USE AP_Inp_Param, only: ParseKeyValueStr, PARSEKEYVALUERE, ParseKeyValueInt
    USE AP_Inp_Def, only: Cmd, CmdCtx
    USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
    USE IF_Prec_Core, only: i4, wp
    ! UFC Material API imports - via Bridge module
    USE AP_Brg_L3, only: MD_Mat_Desc, ModelTree
    implicit none
    private
    
    public :: UF_Cmd_User_RegAll
    public :: Cmd_UserMaterial
    public :: Cmd_UserElement
    
contains

    subroutine Cmd_UserElement(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(ModelTree), pointer :: model_tree => null()
        character(len=64) :: elem_type, coord_system
        integer(i4) :: num_nodes, num_properties, num_i_properties, num_coordinates, i, j, ios
        real(wp), allocatable :: properties(:)
        real(wp) :: line_props(8)
        integer(i4) :: total_read, num_read
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
        num_nodes = 0
        num_properties = 0
        num_i_properties = 0
        num_coordinates = 3  ! Default: 3D
        elem_type = 'U1'  ! Default
        coord_system = '3D'
        
        call ParseKeyValueInt(cmd%param_str, 'nodes', num_nodes, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'NODES', num_nodes, found)
        
        if (num_nodes <= 0) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'USER ELEMENT requires NODES= parameter (number of nodes)'
            return
        end if
        
        call ParseKeyValueStr(cmd%param_str, 'type', elem_type, found)
        if (.not. found) call ParseKeyValueStr(cmd%param_str, 'TYPE', elem_type, found)
        
        call ParseKeyValueInt(cmd%param_str, 'properties', num_properties, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'PROPERTIES', num_properties, found)
        
        call ParseKeyValueInt(cmd%param_str, 'i_properties', num_i_properties, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'I_PROPERTIES', num_i_properties, found)
        
        call ParseKeyValueStr(cmd%param_str, 'coordinates', coord_system, found)
        if (.not. found) call ParseKeyValueStr(cmd%param_str, 'COORDINATES', coord_system, found)
        
        ! Parse coordinate system
        if (trim(coord_system) == '2D' .or. trim(coord_system) == '2d') then
            num_coordinates = 2
        else if (trim(coord_system) == '3D' .or. trim(coord_system) == '3d') then
            num_coordinates = 3
        else
            ! Try to parse as integer
            read(coord_system, *, iostat=ios) num_coordinates
            if (ios /= 0 .or. num_coordinates < 1 .or. num_coordinates > 3) then
                status%status_code = IF_STATUS_INVALID
                write(status%message, '(A)') 'USER ELEMENT coordinates must be 2D or 3D'
                return
            end if
        end if
        
        ! Read data lines for properties (if any)
        if (num_properties > 0) then
            if (.not. cmd%has_data .or. cmd%num_data_lines < 1) then
                status%status_code = IF_STATUS_INVALID
                write(status%message, '(A)') 'USER ELEMENT with PROPERTIES requires data lines'
                return
            end if
            
            allocate(properties(num_properties), stat=ios)
            if (ios /= 0) then
                status%status_code = IF_STATUS_ERROR
                write(status%message, '(A)') 'Failed to allocate properties array'
                return
            end if
            
            ! Read properties (up to 8 per line)
            total_read = 0
            do i = 1, cmd%num_data_lines
                if (total_read >= num_properties) exit
                
                line_props = 0.0_wp
                read(cmd%data_lines(i), *, iostat=ios) (line_props(j), j=1,min(8, num_properties-total_read))
                if (ios /= 0) then
                    deallocate(properties)
                    status%status_code = IF_STATUS_INVALID
                    write(status%message, '(A,I0)') 'Error parsing USER ELEMENT properties at line ', i
                    return
                end if
                
                num_read = min(8, num_properties - total_read)
                properties(total_read+1:total_read+num_read) = line_props(1:num_read)
                total_read = total_read + num_read
            end do
            
            if (total_read /= num_properties) then
                deallocate(properties)
                status%status_code = IF_STATUS_INVALID
                write(status%message, '(A,I0,A,I0)') 'Expected ', num_properties, ' properties, read ', total_read
                return
            end if
        end if
        
        ! Store to command context
        call Cmd_SetVar(cmd, 'last_user_element_type', elem_type, status)
        
        ! Future Model layer integration:
        ! type(UserElementDef) :: uel_def
        ! uel_def%element_type = trim(elem_type)
        ! uel_def%num_nodes = num_nodes
        ! uel_def%num_coordinates = num_coordinates
        ! uel_def%num_properties = num_properties
        ! uel_def%num_i_properties = num_i_properties
        ! if (num_properties > 0) then
        !     allocate(uel_def%properties(num_properties))
        !     uel_def%properties(1:num_properties) = properties(1:num_properties)
        ! end if
        ! call model_tree%GetUserElementManager()%AddElement(uel_def, status)
        !
        ! UEL interface signature (ABAQUS standard):
        ! subroutine UEL(rhs, amatrx, svars, energy, ndofel, nrhs, nsvars, &
        !                props, nprops, coords, mcrd, nnode, u, du, &
        !                v, a, jtype, time, dtime, kstep, kinc, &
        !                jelem, params, ndload, jdltyp, adlmag, predef, npredf, &
        !                lflags, mlvarx, ddlmag, mdload, pnewdt, jprops, njprop, period)
        
        if (num_properties > 0) deallocate(properties)
        
        if (ctx%verbose) then
            write(*,'(A,A,A,I0,A,I0,A)') 'Command USER_ELEMENT: Type=', trim(elem_type), &
                ', Nodes=', num_nodes, ', Coordinates=', num_coordinates, 'D'
            if (num_properties > 0) then
                write(*,'(A,I0)') '  Properties: ', num_properties
            end if
            if (num_i_properties > 0) then
                write(*,'(A,I0)') '  Integer properties: ', num_i_properties
            end if
            write(*,'(A)') '  Note: User must provide UEL subroutine in Fortran'
        end if
        
        status%status_code = IF_STATUS_OK
        
    end subroutine Cmd_UserElement

    subroutine Cmd_UserMaterial(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(ModelTree), pointer :: model_tree => null()
        character(len=256) :: material_name, umat_type
        integer(i4) :: num_constants, num_state_vars, i, j, ios, line_idx
        real(wp), allocatable :: constants(:)
        real(wp) :: line_constants(8)
        integer(i4) :: num_read, total_read
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
        
        ! Get current material (Step 2: get material)
        call Cmd_GetVar(cmd, 'current_material', material_name, found, status)
        if (.not. found .or. len_trim(material_name) == 0) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'No active material. USER MATERIAL must follow *MATERIAL'
            return
        end if
        
        ! Parse parameters (Step 3:  param)
        num_constants = 0
        num_state_vars = 0
        umat_type = 'MECHANICAL'  ! Default
        
        call ParseKeyValueInt(cmd%param_str, 'constants', num_constants, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'CONSTANTS', num_constants, found)
        
        if (num_constants <= 0) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'USER MATERIAL requires CONSTANTS= parameter (number of material constants)'
            return
        end if
        
        call ParseKeyValueInt(cmd%param_str, 'statevars', num_state_vars, found)
        if (.not. found) call ParseKeyValueInt(cmd%param_str, 'STATEVARS', num_state_vars, found)
        
        call ParseKeyValueStr(cmd%param_str, 'type', umat_type, found)
        if (.not. found) call ParseKeyValueStr(cmd%param_str, 'TYPE', umat_type, found)
        
        ! Valid type
        if (trim(umat_type) /= 'MECHANICAL' .and. trim(umat_type) /= 'mechanical' .and. &
            trim(umat_type) /= 'THERMAL' .and. trim(umat_type) /= 'thermal' .and. &
            trim(umat_type) /= 'MECH_THERMAL' .and. trim(umat_type) /= 'mech_thermal') then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'USER MATERIAL type must be MECHANICAL, THERMAL, or MECH_THERMAL'
            return
        end if
        
        ! Read data lines (Step 4:  material  -  
        if (.not. cmd%has_data .or. cmd%num_data_lines < 1) then
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A)') 'USER MATERIAL requires data lines with material constants (max 8 per line)'
            return
        end if
        
        ! Allocate constants array
        allocate(constants(num_constants), stat=ios)
        if (ios /= 0) then
            status%status_code = IF_STATUS_ERROR
            write(status%message, '(A)') 'Failed to allocate material constants array'
            return
        end if
        
        ! Read constants (up to 8 per line)
        total_read = 0
        do line_idx = 1, cmd%num_data_lines
            if (total_read >= num_constants) exit
            
            ! Try to read up to 8 constants from this line
            line_constants = 0.0_wp
            read(cmd%data_lines(line_idx), *, iostat=ios) (line_constants(j), j=1,min(8, num_constants-total_read))
            if (ios /= 0) then
                deallocate(constants)
                status%status_code = IF_STATUS_INVALID
                write(status%message, '(A,I0)') 'Error parsing USER MATERIAL constants at line ', line_idx
                return
            end if
            
            ! Copy to main constants array
            num_read = min(8, num_constants - total_read)
            constants(total_read+1:total_read+num_read) = line_constants(1:num_read)
            total_read = total_read + num_read
        end do
        
        if (total_read /= num_constants) then
            deallocate(constants)
            status%status_code = IF_STATUS_INVALID
            write(status%message, '(A,I0,A,I0)') 'Expected ', num_constants, ' constants, read ', total_read
            return
        end if
        
        ! Store to command context (Step 5:  context)
        call Cmd_SetVar(cmd, 'last_user_material', material_name, status)
        call Cmd_SetVar(cmd, 'last_user_material_type', umat_type, status)
        
        ! Future Model layer integration (Step 6:  Model :
        ! if (associated(material)) then
        !     material%materialType = 'USER_MATERIAL'
        !     material%has_user_material = .true.
        !     material%umat_type = trim(umat_type)
        !     material%num_user_constants = num_constants
        !     material%num_state_vars = num_state_vars
        !     if (allocated(material%user_material_constants)) deallocate(material%user_material_constants)
        !     allocate(material%user_material_constants(num_constants))
        !     material%user_material_constants(1:num_constants) = constants(1:num_constants)
        !     
        !     ! UMAT interface signature (ABAQUS standard):
        !     ! subroutine UMAT(sigma, statev, ddsdde, sse, spd, scd, &
        !     !                 rpl, ddsddt, drplde, drpldt, &
        !     !                 stran, dstran, time, dtime, temp, dtemp, predef, dpred, &
        !     !                 cmname, ndi, nshr, ntens, nstatv, props, nprops, &
        !     !                 coords, drot, pnewdt, celent, dfgrd0, dfgrd1, &
        !     !                 noel, npt, layer, kspt, jstep, kinc)
        !     !   USE IF_Prec, only: wp
        !     !   implicit none
        !     !   real(wp), intent(inout) :: sigma(ntens), statev(nstatv), ddsdde(ntens,ntens)
        !     !   real(wp), intent(inout) :: sse, spd, scd, rpl, ddsddt(ntens), drplde(ntens), drpldt
        !     !   real(wp), intent(in) :: stran(ntens), dstran(ntens), time(2), dtime
        !     !   real(wp), intent(in) :: temp, dtemp, predef(*), dpred(*)
        !     !   character(len=80), intent(in) :: cmname
        !     !   integer, intent(in) :: ndi, nshr, ntens, nstatv, nprops
        !     !   real(wp), intent(in) :: props(nprops), coords(3), drot(3,3)
        !     !   real(wp), intent(inout) :: pnewdt
        !     !   real(wp), intent(in) :: celent, dfgrd0(3,3), dfgrd1(3,3)
        !     !   integer, intent(in) :: noel, npt, layer, kspt, jstep(4), kinc
        ! end if
        
        deallocate(constants)
        
        if (ctx%verbose) then
            write(*,'(A,A,A,A,A,I0)') 'Command USER_MATERIAL: Material "', trim(material_name), &
                '" (Type: ', trim(umat_type), ', Constants: ', num_constants, ')'
            if (num_state_vars > 0) then
                write(*,'(A,I0)') '  State variables: ', num_state_vars
            end if
            write(*,'(A)') '  Note: User must provide UMAT subroutine in Fortran'
        end if
        
        status%status_code = IF_STATUS_OK
        
    end subroutine Cmd_UserMaterial

    subroutine UF_Cmd_User_RegAll(status)
        type(ErrorStatusType), intent(out), optional :: status
        type(ErrorStatusType) :: local_status
        
        if (present(status)) call init_error_status(status)
        
        ! User subroutine commands
        call Cmd_Reg('user_material', Cmd_UserMaterial, 'User material (UMAT)', local_status)
        call Cmd_Reg('user_element', Cmd_UserElement, 'User element (UEL)', local_status)
        
        if (present(status)) status = local_status
    end subroutine UF_Cmd_User_RegAll
end module AP_InpScript_User