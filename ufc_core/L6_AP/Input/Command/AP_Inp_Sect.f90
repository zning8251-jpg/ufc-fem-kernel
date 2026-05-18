!===============================================================================
! MODULE: AP_Inp_Sect
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Impl — section definition command handlers
! BRIEF:  Section definition commands (Solid, Shell, Beam, Composite).
!
! Process phases:
!   P1: Cmd_Section / Cmd_SolidSection / Cmd_ShellSection / Cmd_BeamSection
!   P2: parse_section_data / validate_section_properties
!===============================================================================
MODULE AP_Inp_Sect
  USE AP_Inp_Script, only: Cmd_Reg, Cmd_FormatError
  USE AP_Inp_Param, only: ParseKeyValue, PARSEKEYVALUERE, ParseKeyValueInt, ParseKeyValueStr
  USE AP_Inp_Def, only: Cmd, CmdCtx
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, only: i4, wp
  
  ! UFC Section API imports - via Bridge module
  USE AP_Brg_L3, only: ModelTree, UF_SectionDef, SECTION_SOLID, SECTION_SHELL, &
                          SECTION_BEAM, SECTION_MEMBRANE, SECTION_TRUSS, SECTION_COHESIVE, &
                          BEAM_XSEC_RECT, BEAM_XSEC_CIRCULAR, BEAM_XSEC_PIPE, &
                          BEAM_XSEC_I, BEAM_XSEC_BOX, SectionDesc, &
                          SectionDef_Init_Structured, SectionDef_Init_In, SectionDef_Init_Out
  
  implicit none
  private
  
  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: UF_Cmd_Sect_RegAll
  
contains

  subroutine Cmd_CohesiveSection(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(ModelTree), pointer :: model_tree => null()
    type(UF_SectionDef), pointer :: section => null()
    class(SectionDesc), pointer :: existing_section => null()
    character(len=64) :: sect_name, mat_name, response_str
    real(wp) :: thickness
    integer(i4) :: response_type, ios
    logical :: found
    type(SectionDef_Init_In) :: sect_init_in
    type(SectionDef_Init_Out) :: sect_init_out
    
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
    call ParseKeyValueStr(cmd%param_str, 'name', sect_name, found)
    if (.not. found .or. len_trim(sect_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Section name required', status%message)
      return
    end if
    
    call ParseKeyValueStr(cmd%param_str, 'material', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    call PARSEKEYVALUERE(cmd%param_str, 'thickness', thickness, found, default_val=1.0_wp)
    call ParseKeyValueStr(cmd%param_str, 'response', response_str, found)
    response_type = 1  ! Default: traction-separation
    if (found) then
      if (index(response_str, 'traction') > 0) then
        response_type = 1
      else if (index(response_str, 'damage') > 0) then
        response_type = 2
      end if
    end if
    
    ! Check if section already exists
    existing_section => model_tree%GetSection(name=sect_name)
    if (associated(existing_section)) then
      select type(s => existing_section)
      type is(UF_SectionDef)
        section => s
      end select
    else
      allocate(section, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_INVALID
        call Cmd_FormatError(cmd, 'Failed to allocate section', status%message)
        return
      end if
      
      ! Use structured interface
      sect_init_in%name = sect_name
      sect_init_in%sec_type = SECTION_COHESIVE
      sect_init_in%material_name = mat_name
      call SectionDef_Init_Structured(sect_init_in, sect_init_out, section)
      if (sect_init_out%status%status_code /= IF_STATUS_OK) then
        status = sect_init_out%status
        deallocate(section)
        return
      end if
    end if
    
    ! Set section properties
    section%cfg%section_type = SECTION_COHESIVE
    section%material_name = mat_name
    ! Note: SectionDesc may need additional fields for cohesive thickness and response type
    ! For now, we'll store them in a generic properties array if available
    
    ! Add section to model tree if new
    if (.not. associated(existing_section)) then
      call model_tree%AddSection(section, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(section)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A,A,A,ES12.4)') 'Command COHESIVE_SECTION: Section "', trim(sect_name), &
        '" defined (material=', trim(mat_name), ', thickness=', thickness, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_CohesiveSection

  subroutine Cmd_Layer(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    real(wp) :: thickness, angle
    character(len=64) :: mat_name
    integer(i4) :: i, eq_pos, comma_pos
    
    call init_error_status(status)
    
    ! Parse layer parameters
    thickness = 0.001_wp
    angle = 0.0_wp
    mat_name = ''
    
    i = index(cmd%param_str, 'thickness=')
    if (i > 0) then
      eq_pos = i + 10
      comma_pos = index(cmd%param_str(eq_pos:), ',')
      if (comma_pos > 0) then
        read(cmd%param_str(eq_pos:eq_pos+comma_pos-2), *, iostat=i) thickness
      else
        read(cmd%param_str(eq_pos:), *, iostat=i) thickness
      end if
    end if
    
    i = index(cmd%param_str, 'angle=')
    if (i > 0) then
      eq_pos = i + 6
      comma_pos = index(cmd%param_str(eq_pos:), ',')
      if (comma_pos > 0) then
        read(cmd%param_str(eq_pos:eq_pos+comma_pos-2), *, iostat=i) angle
      else
        read(cmd%param_str(eq_pos:), *, iostat=i) angle
      end if
    end if
    
    i = index(cmd%param_str, 'material=')
    if (i > 0) then
      eq_pos = i + 9
      comma_pos = index(cmd%param_str(eq_pos:), ',')
      if (comma_pos > 0) then
        mat_name = cmd%param_str(eq_pos:eq_pos+comma_pos-2)
      else
        mat_name = cmd%param_str(eq_pos:)
      end if
    end if
    
    ! TODO: Add layer to current composite section
    ! call current_section%add_layer(thickness, angle, mat_name, status)
    
    if (ctx%verbose) then
      write(*,'(A,ES12.4,A,ES12.4,A,A)') 'Command LAYER: Layer added (thickness=', &
        thickness, ', angle=', angle, ', material=', trim(mat_name), ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Layer

  subroutine Cmd_MembraneSection(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(ModelTree), pointer :: model_tree => null()
    type(SectionDesc), pointer :: section => null()
    class(SectionDesc), pointer :: existing_section => null()
    character(len=64) :: sect_name, mat_name
    real(wp) :: thickness
    integer(i4) :: ios
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
    call ParseKeyValueStr(cmd%param_str, 'name', sect_name, found)
    if (.not. found .or. len_trim(sect_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Section name required', status%message)
      return
    end if
    
    call ParseKeyValueStr(cmd%param_str, 'material', mat_name, found)
    if (.not. found .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Material name required', status%message)
      return
    end if
    
    call PARSEKEYVALUERE(cmd%param_str, 'thickness', thickness, found, default_val=0.0_wp)
    if (thickness <= 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Thickness must be positive', status%message)
      return
    end if
    
    ! Check if section already exists
    existing_section => model_tree%GetSection(name=sect_name)
    if (associated(existing_section)) then
      select type(s => existing_section)
      type is(UF_SectionDef)
        section => s
      end select
    else
      allocate(section, stat=ios)
      if (ios /= 0) then
        status%status_code = IF_STATUS_INVALID
        call Cmd_FormatError(cmd, 'Failed to allocate section', status%message)
        return
      end if
      
      ! Use structured interface
      sect_init_in%name = sect_name
      sect_init_in%sec_type = SECTION_MEMBRANE
      sect_init_in%material_name = mat_name
      call SectionDef_Init_Structured(sect_init_in, sect_init_out, section)
      if (sect_init_out%status%status_code /= IF_STATUS_OK) then
        status = sect_init_out%status
        deallocate(section)
        return
      end if
    end if
    
    ! Set section properties
    section%cfg%section_type = SECTION_MEMBRANE
    section%material_name = mat_name
    ! Note: SectionDesc may need additional fields for membrane thickness
    ! For now, we'll store it in a generic properties array if available
    
    ! Add section to model tree if new
    if (.not. associated(existing_section)) then
      call model_tree%AddSection(section, status)
      if (status%status_code /= IF_STATUS_OK) then
        deallocate(section)
        return
      end if
    end if
    
    if (ctx%verbose) then
      write(*,'(A,A,A,A,A,ES12.4)') 'Command MEMBRANE_SECTION: Section "', trim(sect_name), &
        '" defined (material=', trim(mat_name), ', thickness=', thickness, ')'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_MembraneSection

  subroutine Cmd_Section(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: sect_name, sect_type_str, mat_name, shape_str
    integer(i4) :: sect_type, shape_type, ios
    real(wp) :: thickness, width, height, radius
    type(UF_SectionDef), pointer :: section => null()
    integer(i4) :: i, eq_pos, comma_pos
    type(SectionDef_Init_In) :: sect_init_in
    type(SectionDef_Init_Out) :: sect_init_out
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! Parse section name
    sect_name = cmd%opt
    if (len_trim(sect_name) == 0) then
      i = index(cmd%param_str, 'name=')
      if (i > 0) then
        eq_pos = i + 5
        comma_pos = index(cmd%param_str(eq_pos:), ',')
        if (comma_pos > 0) then
          sect_name = cmd%param_str(eq_pos:eq_pos+comma_pos-2)
        else
          sect_name = cmd%param_str(eq_pos:)
        end if
      end if
    end if
    
    ! Parse section type
    sect_type = SECTION_SOLID  ! Default
    i = index(cmd%param_str, 'type=')
    if (i > 0) then
      eq_pos = i + 5
      comma_pos = index(cmd%param_str(eq_pos:), ',')
      if (comma_pos > 0) then
        sect_type_str = cmd%param_str(eq_pos:eq_pos+comma_pos-2)
      else
        sect_type_str = cmd%param_str(eq_pos:)
      end if
      
      select case(trim(sect_type_str))
      case('solid')
        sect_type = SECTION_SOLID
      case('shell')
        sect_type = SECTION_SHELL
      case('beam')
        sect_type = SECTION_BEAM
      case('membrane')
        sect_type = SECTION_MEMBRANE
      case('truss')
        sect_type = SECTION_TRUSS
      case('cohesive')
        sect_type = SECTION_COHESIVE
      end select
    end if
    
    ! Parse material name
    mat_name = ''
    i = index(cmd%param_str, 'material=')
    if (i > 0) then
      eq_pos = i + 9
      comma_pos = index(cmd%param_str(eq_pos:), ',')
      if (comma_pos > 0) then
        mat_name = cmd%param_str(eq_pos:eq_pos+comma_pos-2)
      else
        mat_name = cmd%param_str(eq_pos:)
      end if
    end if
    
    if (len_trim(sect_name) == 0 .or. len_trim(mat_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Section name and material name required', status%message)
      return
    end if
    
    ! Create section
    allocate(section, stat=ios)
    if (ios /= 0) then
      status%status_code = IF_STATUS_ERROR
      call Cmd_FormatError(cmd, 'Failed to allocate section descriptor', status%message)
      return
    end if
    
    section%name = sect_name
    section%cfg%section_type = sect_type
    section%material_name = mat_name
    
    ! Parse section-specific parameters
    select case(sect_type)
    case(SECTION_SHELL)
      ! Shell: thickness
      thickness = 0.01_wp  ! Default
      i = index(cmd%param_str, 'thickness=')
      if (i > 0) then
        eq_pos = i + 10
        comma_pos = index(cmd%param_str(eq_pos:), ',')
        if (comma_pos > 0) then
          read(cmd%param_str(eq_pos:eq_pos+comma_pos-2), *, iostat=i) thickness
        else
          read(cmd%param_str(eq_pos:), *, iostat=i) thickness
        end if
      end if
      section%shell_thickness = thickness
      
    case(SECTION_BEAM)
      ! Beam: shape and dimensions
      shape_type = BEAM_XSEC_RECT  ! Default
      i = index(cmd%param_str, 'shape=')
      if (i > 0) then
        eq_pos = i + 6
        comma_pos = index(cmd%param_str(eq_pos:), ',')
        if (comma_pos > 0) then
          shape_str = cmd%param_str(eq_pos:eq_pos+comma_pos-2)
        else
          shape_str = cmd%param_str(eq_pos:)
        end if
        
        select case(trim(shape_str))
        case('rectangular', 'rect')
          shape_type = BEAM_XSEC_RECT
        case('circular', 'circle')
          shape_type = BEAM_XSEC_CIRCULAR
        case('pipe')
          shape_type = BEAM_XSEC_PIPE
        case('I', 'i-beam')
          shape_type = BEAM_XSEC_I
        case('box')
          shape_type = BEAM_XSEC_BOX
        end select
      end if
      section%xsec_type = shape_type
      
      ! Parse dimensions
      width = 0.0_wp
      height = 0.0_wp
      radius = 0.0_wp
      
      i = index(cmd%param_str, 'width=')
      if (i > 0) then
        eq_pos = i + 6
        comma_pos = index(cmd%param_str(eq_pos:), ',')
        if (comma_pos > 0) then
          read(cmd%param_str(eq_pos:eq_pos+comma_pos-2), *, iostat=i) width
        else
          read(cmd%param_str(eq_pos:), *, iostat=i) width
        end if
      end if
      
      i = index(cmd%param_str, 'height=')
      if (i > 0) then
        eq_pos = i + 7
        comma_pos = index(cmd%param_str(eq_pos:), ',')
        if (comma_pos > 0) then
          read(cmd%param_str(eq_pos:eq_pos+comma_pos-2), *, iostat=i) height
        else
          read(cmd%param_str(eq_pos:), *, iostat=i) height
        end if
      end if
      
      i = index(cmd%param_str, 'radius=')
      if (i > 0) then
        eq_pos = i + 7
        comma_pos = index(cmd%param_str(eq_pos:), ',')
        if (comma_pos > 0) then
          read(cmd%param_str(eq_pos:eq_pos+comma_pos-2), *, iostat=i) radius
        else
          read(cmd%param_str(eq_pos:), *, iostat=i) radius
        end if
      end if
      
      ! Store dimensions in xsec_dims
      select case(shape_type)
      case(BEAM_XSEC_RECT)
        section%xsec_dims(1) = width
        section%xsec_dims(2) = height
      case(BEAM_XSEC_CIRCULAR)
        section%xsec_dims(1) = radius
      case(BEAM_XSEC_PIPE)
        section%xsec_dims(1) = radius
        section%xsec_dims(2) = thickness  ! Wall thickness
      end select
      
    end select
    
    ! Get model tree
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      deallocate(section)
      return
    end if
    
    select type(m => ctx%model)
    type is(ModelTree)
      ! Check if section already exists
      nullify(section)
      section => m%GetSection(name=sect_name)
      if (.not. associated(section)) then
        ! Create new section (convert UF_SectionDef to SectionDesc)
        ! TODO: Convert UF_SectionDef to SectionDesc and add to model
        ! For now, just create placeholder
        allocate(section, stat=ios)
        if (ios == 0) then
          call section%Init(name=sect_name)
          ! TODO: Set section properties
          call m%AddSection(section, status)
          if (status%status_code /= IF_STATUS_OK) then
            deallocate(section)
            return
          end if
        end if
      end if
    class default
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model is not a ModelTree'
      deallocate(section)
      return
    end select
    
    if (ctx%verbose) then
      write(*,'(A,A,A,I0)') 'Command SECTION: Section "', trim(sect_name), &
        '" created (type=', sect_type, ')'
    end if
    
    deallocate(section)
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_Section

  subroutine Cmd_SectionAssign(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: part_name, sect_name, elset_name
    integer(i4) :: i, eq_pos, comma_pos
    
    call init_error_status(status)
    
    if (.not. associated(ctx%model)) then
      status%status_code = IF_STATUS_INVALID
      write(status%message, '(A)') 'Model not associated'
      return
    end if
    
    ! Parse parameters
    part_name = ''
    sect_name = ''
    elset_name = ''
    
    i = index(cmd%param_str, 'part=')
    if (i > 0) then
      eq_pos = i + 5
      comma_pos = index(cmd%param_str(eq_pos:), ',')
      if (comma_pos > 0) then
        part_name = cmd%param_str(eq_pos:eq_pos+comma_pos-2)
      else
        part_name = cmd%param_str(eq_pos:)
      end if
    end if
    
    i = index(cmd%param_str, 'section=')
    if (i > 0) then
      eq_pos = i + 8
      comma_pos = index(cmd%param_str(eq_pos:), ',')
      if (comma_pos > 0) then
        sect_name = cmd%param_str(eq_pos:eq_pos+comma_pos-2)
      else
        sect_name = cmd%param_str(eq_pos:)
      end if
    end if
    
    i = index(cmd%param_str, 'elset=')
    if (i > 0) then
      eq_pos = i + 6
      comma_pos = index(cmd%param_str(eq_pos:), ',')
      if (comma_pos > 0) then
        elset_name = cmd%param_str(eq_pos:eq_pos+comma_pos-2)
      else
        elset_name = cmd%param_str(eq_pos:)
      end if
    end if
    
    if (len_trim(sect_name) == 0 .or. len_trim(elset_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Section name and element set name required', status%message)
      return
    end if
    
    ! TODO: Assign section to element set
    ! call part%assign_section(elset_name, sect_name, status)
    
    if (ctx%verbose) then
      write(*,'(A,A,A,A,A)') 'Command SECTION_ASSIGN: Section "', trim(sect_name), &
        '" assigned to element set "', trim(elset_name), '"'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_SectionAssign

  subroutine Cmd_SectionControls(cmd, ctx, status)
    type(Cmd), intent(in) :: cmd
    type(CmdCtx), intent(inout) :: ctx
    type(ErrorStatusType), intent(out) :: status
    
    type(ModelTree), pointer :: model_tree => null()
    character(len=64) :: sect_name, distortion_str, hourglass_str
    logical :: distortion_cont
    integer(i4) :: hourglass_type
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
    call ParseKeyValueStr(cmd%param_str, 'name', sect_name, found)
    if (.not. found .or. len_trim(sect_name) == 0) then
      status%status_code = IF_STATUS_INVALID
      call Cmd_FormatError(cmd, 'Section name required', status%message)
      return
    end if
    
    call ParseKeyValueStr(cmd%param_str, 'distortion_cont', distortion_str, found)
    distortion_cont = (index(distortion_str, 'yes') > 0 .or. index(distortion_str, 'true') > 0)
    
    call ParseKeyValueStr(cmd%param_str, 'hourglass', hourglass_str, found)
    hourglass_type = 0  ! Default: none
    if (found) then
      if (index(hourglass_str, 'enhanced') > 0) then
        hourglass_type = 1
      else if (index(hourglass_str, 'reduced') > 0) then
        hourglass_type = 2
      end if
    end if
    
    ! TODO: Apply section controls to the specified section
    ! The controls will affect element integration and hourglass control
    
    if (ctx%verbose) then
      write(*,'(A,A,A)') 'Command SECTION_CONTROLS: Controls applied to section "', trim(sect_name), '"'
    end if
    
    status%status_code = IF_STATUS_OK
    
  end subroutine Cmd_SectionControls

  subroutine UF_Cmd_Sect_RegAll(status)
    type(ErrorStatusType), intent(out), optional :: status
    
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    
    ! Section commands
    call Cmd_Reg('section', Cmd_Section, 'Define section', local_status)
    call Cmd_Reg('layer', Cmd_Layer, 'Define composite layer', local_status)
    call Cmd_Reg('section_assign', Cmd_SectionAssign, 'Assign section to element set', local_status)
    
    ! Extended section commands
    call Cmd_Reg('membrane_section', Cmd_MembraneSection, 'Membrane section', local_status)
    call Cmd_Reg('cohesive_section', Cmd_CohesiveSection, 'Cohesive section', local_status)
    call Cmd_Reg('section_controls', Cmd_SectionControls, 'Section controls', local_status)
    
    if (present(status)) status = local_status
    
  end subroutine UF_Cmd_Sect_RegAll
end MODULE AP_Inp_Sect