!===============================================================================
! MODULE: AP_Inp_Mesh
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Impl — mesh definition command handlers
! BRIEF:  Mesh definition commands (NODE, ELEMENT, NSET, ELSET, SURFACE).
!
! Process phases:
!   P1: Cmd_Node / Cmd_Element / Cmd_Nset / Cmd_Elset / Cmd_Surface
!   P2: parse_node_data / parse_element_data
!===============================================================================
MODULE AP_Inp_Mesh
    USE AP_Inp_Script, only: Cmd_SetVar, Cmd_GetVar
    USE AP_Inp_Def, only: Cmd, CmdCtx
    USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
    USE IF_Prec_Core, only: i4, wp
    USE MD_Elem_InpMap, only: MD_Elem_MapAbqTypeString
    ! UFC Mesh API imports - via Bridge module
    USE AP_Brg_L3, only: UF_Assem, ModelTree, UF_Part, &
                            Part_AddNode, Part_AddElement, Part_AddNodeSet, &
                            Part_AddElementSet, Part_AddSurface
    implicit none
    private
    
    ! Public command handlers
    public :: Cmd_Node
    public :: Cmd_Elem
    public :: Cmd_Nset
    public :: Cmd_Elset
    public :: Cmd_Surface
    public :: Cmd_Orientation
    public :: Cmd_Ngen
    public :: Cmd_Elgen
    
contains

    subroutine Cmd_Elem(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(UF_Part), pointer :: current_part
        character(len=32) :: elem_type_str, elset_name
        integer(i4) :: elem_id, elem_type_code, ios, i, num_lines
        integer(i4), allocatable :: connectivity(:)
        integer(i4) :: num_nodes, j
        logical :: has_elset
        
        call init_error_status(status)
        
        ! Step 1: Get current Part
        current_part => ModelTree_GetCurrentPart(ctx%model_tree)
        if (.not. associated(current_part)) then
            status%status_code = IF_STATUS_ERROR
            status%message = '*ELEMENT command must be inside *PART definition'
            return
        end if
        
        ! Step 2: Parse ELEMENT parameters
        call Cmd_GetVar(cmd, "TYPE", elem_type_str)
        call Cmd_GetVar(cmd, "ELSET", elset_name)
        
        if (len_trim(elem_type_str) == 0) then
            status%status_code = IF_STATUS_INVALID
            status%message = '*ELEMENT requires TYPE= parameter (e.g., TYPE=C3D8)'
            return
        end if
        
        has_elset = len_trim(elset_name) > 0
        
        ! Step 3: Map ABAQUS element type -> L3 MD_Elem_Algo ELEM_* (for elem_type_cache / PH_ElemDomain_Algo)
        call map_Elem_type(elem_type_str, elem_type_code, num_nodes, status)
        if (status%status_code /= IF_STATUS_OK) return
        
        ! Step 4: Read element data from data lines
        num_lines = cmd%num_data_lines
        if (num_lines == 0) then
            status%status_code = IF_STATUS_INVALID
            status%message = '*ELEMENT requires data lines'
            return
        end if
        
        allocate(connectivity(num_nodes))
        
        do i = 1, num_lines
            ! Parse: elem_id, node1, node2, ..., nodeN
            read(cmd%data_lines(i), *, iostat=ios) elem_id, (connectivity(j), j=1, num_nodes)
            if (ios /= 0) then
                status%status_code = IF_STATUS_INVALID
                write(status%message, '(A,I0)') '*ELEMENT: Invalid data at line ', i
                deallocate(connectivity)
                return
            end if
            
            ! Step 5: Add element to Part
            call Part_AddElement(current_part, elem_id, elem_type_code, connectivity, status)
            if (status%status_code /= IF_STATUS_OK) then
                deallocate(connectivity)
                return
            end if
            
            ! Step 6: Add to ELSET if specified
            if (has_elset) then
                ! TODO: Part_AddElementToSet(current_part, elset_name, elem_id, status)
            end if
        end do
        
        deallocate(connectivity)
        status%status_code = IF_STATUS_OK
    end subroutine Cmd_Elem

    subroutine Cmd_Elgen(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        character(len=64) :: elset_name
        
        call init_error_status(status)
        
        call Cmd_GetVar(cmd, "ELSET", elset_name)
        
        ! TODO: Implement element generation algorithm
        
        status%status_code = IF_STATUS_OK
        status%message = '*ELGEN command executed (placeholder)'
    end subroutine Cmd_Elgen

    subroutine Cmd_Elset(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(UF_Part), pointer :: current_part
        character(len=64) :: elset_name
        logical :: generate_mode, is_internal
        integer(i4) :: i, num_lines, ios
        integer(i4) :: elem_id, elem_start, elem_end, elem_inc
        
        call init_error_status(status)
        
        call Cmd_GetVar(cmd, "ELSET", elset_name)
        call Cmd_GetVar(cmd, "GENERATE", generate_mode)
        call Cmd_GetVar(cmd, "INTERNAL", is_internal)
        
        if (len_trim(elset_name) == 0) then
            status%status_code = IF_STATUS_INVALID
            status%message = '*ELSET requires ELSET= parameter'
            return
        end if
        
        current_part => ModelTree_GetCurrentPart(ctx%model_tree)
        if (.not. associated(current_part)) then
            status%status_code = IF_STATUS_ERROR
            status%message = '*ELSET must be inside *PART or *ASSEMBLY'
            return
        end if
        
        call Part_AddElementSet(current_part, elset_name, is_internal, status)
        if (status%status_code /= IF_STATUS_OK) return
        
        ! Read element IDs (similar to Cmd_Nset)
        num_lines = cmd%num_data_lines
        do i = 1, num_lines
            if (generate_mode) then
                read(cmd%data_lines(i), *, iostat=ios) elem_start, elem_end, elem_inc
                if (ios /= 0) elem_inc = 1
                ! TODO: Part_AddElementRange
            else
                read(cmd%data_lines(i), *, iostat=ios) elem_id
                if (ios == 0) then
                    ! TODO: Part_AddElementToSet
                end if
            end if
        end do
        
        status%status_code = IF_STATUS_OK
    end subroutine Cmd_Elset

    subroutine Cmd_Ngen(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        character(len=64) :: nset_name, line_type
        
        call init_error_status(status)
        
        call Cmd_GetVar(cmd, "NSET", nset_name)
        call Cmd_GetVar(cmd, "LINE", line_type)
        
        ! TODO: Implement node generation algorithm
        
        status%status_code = IF_STATUS_OK
        status%message = '*NGEN command executed (placeholder)'
    end subroutine Cmd_Ngen

    subroutine Cmd_Node(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(UF_Part), pointer :: current_part
        character(len=64) :: nset_name, system_type, input_file
        integer(i4) :: node_id, ios, i, num_lines
        real(wp) :: x, y, z
        logical :: has_nset, has_input
        
        call init_error_status(status)
        
        ! Step 1: Get current Part context
        current_part => ModelTree_GetCurrentPart(ctx%model_tree)
        if (.not. associated(current_part)) then
            status%status_code = IF_STATUS_ERROR
            status%message = '*NODE command must be inside *PART definition'
            return
        end if
        
        ! Step 2: Parse NODE parameters
        call Cmd_GetVar(cmd, "NSET", nset_name)
        call Cmd_GetVar(cmd, "SYSTEM", system_type)
        call Cmd_GetVar(cmd, "INPUT", input_file)
        
        has_nset = len_trim(nset_name) > 0
        has_input = len_trim(input_file) > 0
        
        if (len_trim(system_type) == 0) system_type = "R"  ! Default: rectangular
        
        ! Step 3: Process INPUT file if specified
        if (has_input) then
            ! TODO: Implement external file reading
            ! call read_nodes_from_file(input_file, current_part, status)
            status%status_code = IF_STATUS_ERROR
            status%message = '*NODE INPUT= parameter not yet implemented'
            return
        end if
        
        ! Step 4: Read node data from data lines
        num_lines = cmd%num_data_lines
        if (num_lines == 0) then
            status%status_code = IF_STATUS_INVALID
            status%message = '*NODE requires data lines: node_id, x, y, z'
            return
        end if
        
        do i = 1, num_lines
            ! Parse data line: node_id, x, y, z
            read(cmd%data_lines(i), *, iostat=ios) node_id, x, y, z
            if (ios /= 0) then
                status%status_code = IF_STATUS_INVALID
                write(status%message, '(A,I0)') '*NODE: Invalid data at line ', i
                return
            end if
            
            ! Step 5: Add node to Part
            call Part_AddNode(current_part, node_id, x, y, z, status)
            if (status%status_code /= IF_STATUS_OK) return
            
            ! Step 6: Add to NSET if specified
            if (has_nset) then
                ! TODO: Part_AddNodeToSet(current_part, nset_name, node_id, status)
            end if
        end do
        
        status%status_code = IF_STATUS_OK
    end subroutine Cmd_Node

    subroutine Cmd_Nset(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(UF_Part), pointer :: current_part
        type(UF_Assem), pointer :: current_assembly
        character(len=64) :: nset_name, instance_name
        logical :: generate_mode, is_internal, in_part, in_assembly
        integer(i4) :: i, num_lines, ios
        integer(i4) :: node_id, node_start, node_end, node_inc
        
        call init_error_status(status)
        
        ! Step 1: Parse NSET parameters
        call Cmd_GetVar(cmd, "NSET", nset_name)
        call Cmd_GetVar(cmd, "GENERATE", generate_mode)
        call Cmd_GetVar(cmd, "INSTANCE", instance_name)
        call Cmd_GetVar(cmd, "INTERNAL", is_internal)
        
        if (len_trim(nset_name) == 0) then
            status%status_code = IF_STATUS_INVALID
            status%message = '*NSET requires NSET= parameter'
            return
        end if
        
        ! Step 2: Determine context (Part or Assembly)
        current_part => ModelTree_GetCurrentPart(ctx%model_tree)
        current_assembly => ModelTree_GetAssembly(ctx%model_tree)
        
        in_part = associated(current_part)
        in_assembly = associated(current_assembly)
        
        if (.not. in_part .and. .not. in_assembly) then
            status%status_code = IF_STATUS_ERROR
            status%message = '*NSET must be inside *PART or *ASSEMBLY'
            return
        end if
        
        ! Step 3: Create node set
        if (in_part) then
            call Part_AddNodeSet(current_part, nset_name, is_internal, status)
        else
            ! TODO: Assembly_AddNodeSet(current_assembly, nset_name, instance_name, status)
        end if
        
        if (status%status_code /= IF_STATUS_OK) return
        
        ! Step 4: Read node IDs from data lines
        num_lines = cmd%num_data_lines
        
        do i = 1, num_lines
            if (generate_mode) then
                ! GENERATE mode: start, end, increment
                read(cmd%data_lines(i), *, iostat=ios) node_start, node_end, node_inc
                if (ios /= 0) node_inc = 1  ! Default increment
                
                ! TODO: Part_AddNodeRange(current_part, nset_name, node_start, node_end, node_inc, status)
            else
                ! Normal mode: node_id1, node_id2, ...
                read(cmd%data_lines(i), *, iostat=ios) node_id
                if (ios == 0) then
                    ! TODO: Part_AddNodeToSet(current_part, nset_name, node_id, status)
                end if
            end if
        end do
        
        status%status_code = IF_STATUS_OK
    end subroutine Cmd_Nset

    subroutine Cmd_Orientation(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        character(len=64) :: orientation_name, system_type
        integer(i4) :: local_directions
        real(wp) :: axis_a(3), axis_b(3)
        
        call init_error_status(status)
        
        call Cmd_GetVar(cmd, "NAME", orientation_name)
        call Cmd_GetVar(cmd, "SYSTEM", system_type)
        call Cmd_GetVar(cmd, "LOCAL DIRECTIONS", local_directions)
        
        if (len_trim(orientation_name) == 0) then
            status%status_code = IF_STATUS_INVALID
            status%message = '*ORIENTATION requires NAME= parameter'
            return
        end if
        
        ! TODO: Read axis vectors from data lines and create orientation
        ! TODO: Part_AddOrientation or ModelTree_AddOrientation
        
        status%status_code = IF_STATUS_OK
        status%message = '*ORIENTATION command executed (placeholder)'
    end subroutine Cmd_Orientation

    subroutine Cmd_Surface(cmd, ctx, status)
        type(Cmd), intent(in) :: cmd
        type(CmdCtx), intent(inout) :: ctx
        type(ErrorStatusType), intent(out) :: status
        
        type(UF_Part), pointer :: current_part
        character(len=64) :: surface_name, surface_type, combine_mode
        integer(i4) :: num_lines, i, ios
        character(len=64) :: elset_name, face_identifier
        
        call init_error_status(status)
        
        call Cmd_GetVar(cmd, "NAME", surface_name)
        call Cmd_GetVar(cmd, "TYPE", surface_type)
        call Cmd_GetVar(cmd, "COMBINE", combine_mode)
        
        if (len_trim(surface_name) == 0) then
            status%status_code = IF_STATUS_INVALID
            status%message = '*SURFACE requires NAME= parameter'
            return
        end if
        
        if (len_trim(surface_type) == 0) surface_type = "ELEMENT"
        
        current_part => ModelTree_GetCurrentPart(ctx%model_tree)
        if (.not. associated(current_part)) then
            status%status_code = IF_STATUS_ERROR
            status%message = '*SURFACE must be inside *PART or *ASSEMBLY'
            return
        end if
        
        call Part_AddSurface(current_part, surface_name, surface_type, status)
        if (status%status_code /= IF_STATUS_OK) return
        
        ! Read surface definition from data lines
        num_lines = cmd%num_data_lines
        do i = 1, num_lines
            ! Format: elset_name, face_identifier (e.g., "ELSET-1", "S1")
            read(cmd%data_lines(i), *, iostat=ios) elset_name, face_identifier
            if (ios == 0) then
                ! TODO: Part_AddSurfaceFace(current_part, surface_name, elset_name, face_identifier, status)
            end if
        end do
        
        status%status_code = IF_STATUS_OK
    end subroutine Cmd_Surface

    subroutine map_Elem_type(type_str, type_code, num_nodes, status)
        character(len=*), intent(in) :: type_str
        integer(i4), intent(out) :: type_code, num_nodes
        type(ErrorStatusType), intent(out) :: status

        ! Delegate to L3 MD_ElemInpMap_Algo (MD_Elem_Algo ELEM_* integers)
        call MD_Elem_MapAbqTypeString(type_str, type_code, num_nodes, status)
    end subroutine map_Elem_type
end MODULE AP_Inp_Mesh