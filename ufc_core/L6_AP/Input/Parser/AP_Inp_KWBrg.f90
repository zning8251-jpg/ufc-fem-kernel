!===============================================================================
! MODULE: AP_Inp_KW_Brg
! LAYER:  L6_AP
! DOMAIN: Input/Parser
! ROLE:   Brg — keyword bridge between command system and keyword registry
! BRIEF:  Bridge between Command System and Keyword Registry.
!
! Process phases:
!   P0: AP_KWBrg_Init / AP_KWBrg_Finalize
!   P1: AP_KWBrg_Register / AP_KWBrg_Lookup / AP_KWBrg_Bind
!===============================================================================
module AP_Inp_KW_Brg
!> Theory: (TODO) | Last verified: 2026-02-14
  USE AP_Inp_Def, only: Cmd, CmdCtx, add_metadata_Intf
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: i4, wp
  
  ! Keyword Registry imports - via Bridge module
  USE AP_Brg_L3, only: kw_registry_init, kw_registry_get_count, &
                            kw_registry_get_all, kw_registry_find, kw_is_initialized, &
                            KW_MetadataType, KW_MAX_NAME_LEN, KW_MAX_DESC_LEN, &
                            KW_MAX_PARAMS, KW_CAT_MODEL, KW_CAT_PART, KW_CAT_MESH, &
                            KW_CAT_MATERIAL, KW_CAT_SECTION, KW_CAT_CONSTRAINT, &
                            KW_CAT_LOAD, KW_CAT_CONTACT, KW_CAT_STEP, KW_CAT_OUTPUT, &
                            KW_CAT_AMPLITUDE, KW_CAT_SPECIAL, PARAM_TYPE_STRING, &
                            PARAM_TYPE_INTEGER, PARAM_TYPE_REAL, PARAM_TYPE_ENUM, &
                            PARAM_TYPE_LOGICAL, PARAM_TYPE_NAME_REF
  
  implicit none
  private
  
  !===============================================================================
  ! Public Interface
  !===============================================================================
  public :: UF_Cmd_KWBrg_Init
  public :: UF_Cmd_KWBrg_Sync
  public :: UF_Cmd_KWBrg_GetCmd
  public :: UF_Cmd_KWBrg_ConvKw
  public :: UF_Cmd_KWBrg_RegAddMetadata

  !===============================================================================
  ! Bridge State (add_metadata  ?UX  ?KWBrg  ?KWBrg?UX  )
  !===============================================================================
  logical, save :: bridgeInited = .false.
  integer(i4), save :: syncedKw = 0
  procedure(add_metadata_Intf), pointer, save :: addMetadataCb => null()
  
contains
  
  !===============================================================================
  ! Init Bridge
  !===============================================================================
  subroutine UF_Cmd_KWBrg_Init(status)
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    ! Init keyword registry if not already done
    if (.not. kw_is_initialized()) then
      call kw_registry_init()
    end if
    
    bridgeInited = .true.
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine UF_Cmd_KWBrg_Init

  !===============================================================================
  ! Reg AddMetadata callback (UX  ?KWBrg?UX  )
  !===============================================================================
  subroutine UF_Cmd_KWBrg_RegAddMetadata(proc)
    procedure(add_metadata_Intf) :: proc
    addMetadataCb => proc
  end subroutine UF_Cmd_KWBrg_RegAddMetadata
  
  !===============================================================================
  ! Sync Metadata from Keyword Registry to Command System
  !===============================================================================
  subroutine UF_Cmd_KWBrg_Sync(status)
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: kw_count, i
    type(KW_MetadataType), allocatable :: keywords(:)
    type(KW_MetadataType), pointer :: kw
    character(len=16) :: cmd_name
    character(len=256) :: syntax_str, params_str, example_str
    
    if (present(status)) call init_error_status(status)
    
    if (.not. bridgeInited) then
      call UF_Cmd_KWBrg_Init(status)
      if (present(status) .and. status%status_code /= IF_STATUS_OK) return
    end if
    
    ! Get keyword count
    kw_count = kw_registry_get_count()
    if (kw_count <= 0) then
      if (present(status)) status%status_code = IF_STATUS_OK
      return
    end if
    
    ! Allocate temporary array
    allocate(keywords(kw_count), stat=i)
    if (i /= 0) then
      if (present(status)) status%status_code = IF_STATUS_INVALID
      return
    end if
    
    ! Get all keywords
    call kw_registry_get_all(keywords, kw_count)
    
    ! Convert each keyword to command metadata
    syncedKw = 0
    do i = 1, kw_count
      ! Check if keyword is registered
      if (.not. keywords(i)%is_registered) cycle
      if (keywords(i)%is_deprecated) cycle
      
      ! Convert keyword name to command name
      cmd_name = UF_Cmd_KWBrg_ConvKw2CmdName(keywords(i)%keyword_name)
      if (len_trim(cmd_name) == 0) cycle
      
      ! Build syntax string
      call UF_Cmd_KWBrg_BldSyntax(keywords(i), syntax_str)
      
      ! Build parameters string
      call UF_Cmd_KWBrg_BldParams(keywords(i), params_str)
      
      ! Build example string
      call UF_Cmd_KWBrg_BldExample(keywords(i), cmd_name, example_str)
      
      ! Add to command metadata (via injected callback if registered)
      if (associated(addMetadataCb)) then
        call addMetadataCb(cmd_name, &
                             trim(keywords(i)%cfg%description), &
                             trim(syntax_str), &
                             trim(params_str), &
                             trim(example_str))
      end if
      
      syncedKw = syncedKw + 1
    end do
    
    deallocate(keywords)
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine UF_Cmd_KWBrg_Sync
  
  !===============================================================================
  ! Convert Keyword Name to Command Name
  !===============================================================================
  function UF_Cmd_KWBrg_ConvKw2CmdName(kw_name) result(cmd_name)
    character(len=*), intent(in) :: kw_name
    character(len=16) :: cmd_name
    
    character(len=KW_MAX_NAME_LEN) :: upper_name, lower_name
    integer(i4) :: i, j, space_pos
    
    cmd_name = ''
    upper_name = kw_name
    
    ! Convert to lowercase
    do i = 1, len_trim(upper_name)
      j = ichar(upper_name(i:i))
      if (j >= ichar('A') .and. j <= ichar('Z')) then
        lower_name(i:i) = char(j + 32)
      else
        lower_name(i:i) = upper_name(i:i)
      end if
    end do
    
    ! Remove spaces and convert to command name
    ! Strategy: Use first word, or combine words (e.g., "SOLID SECTION" -> "solid_section")
    space_pos = index(lower_name, ' ')
    if (space_pos > 0) then
      ! Multi-word keyword: use first word or combine
      if (index(upper_name, 'SECTION') > 0) then
        ! Special handling for SECTION keywords
        if (index(upper_name, 'SOLID') > 0) then
          cmd_name = 'solid_section'
        else if (index(upper_name, 'SHELL') > 0) then
          cmd_name = 'shell_section'
        else if (index(upper_name, 'BEAM') > 0) then
          cmd_name = 'beam_section'
        else if (index(upper_name, 'MEMBRANE') > 0) then
          cmd_name = 'membrane_section'
        else if (index(upper_name, 'COHESIVE') > 0) then
          cmd_name = 'cohesive_section'
        end if
      else if (index(upper_name, 'COUPLING') > 0) then
        if (index(upper_name, 'KINEMATIC') > 0) then
          cmd_name = 'kinematic_coupling'
        else if (index(upper_name, 'DISTRIBUTING') > 0) then
          cmd_name = 'distributing_coupling'
        else
          cmd_name = 'coupling'
        end if
      else if (index(upper_name, 'OUTPUT') > 0) then
        if (index(upper_name, 'NODE') > 0) then
          cmd_name = 'node_output'
        else if (index(upper_name, 'ELEMENT') > 0 .or. index(upper_name, 'EL') > 0) then
          cmd_name = 'element_output'
        else if (index(upper_name, 'CONTACT') > 0) then
          cmd_name = 'contact_output'
        else if (index(upper_name, 'ENERGY') > 0) then
          cmd_name = 'energy_output'
        else
          cmd_name = 'output'
        end if
      else if (index(upper_name, 'CONTACT') > 0) then
        if (index(upper_name, 'PAIR') > 0) then
          cmd_name = 'contact_pair'
        else if (index(upper_name, 'INTERACTION') > 0) then
          cmd_name = 'surface_interaction'
        else if (index(upper_name, 'INCLUSIONS') > 0) then
          cmd_name = 'contact_inclusions'
        else if (index(upper_name, 'EXCLUSIONS') > 0) then
          cmd_name = 'contact_exclusions'
        else
          cmd_name = 'contact'
        end if
      else if (index(upper_name, 'SURFACE') > 0) then
        if (index(upper_name, 'INTERACTION') > 0) then
          cmd_name = 'surface_interaction'
        else if (index(upper_name, 'BEHAVIOR') > 0) then
          cmd_name = 'surface_behavior'
        end if
      else if (index(upper_name, 'HEAT TRANSFER') > 0) then
        cmd_name = 'heat_transfer'
      else if (index(upper_name, 'COUPLED TEMPERATURE-DISPLACEMENT') > 0 .or. &
               index(upper_name, 'COUPLED TEMP-DISP') > 0) then
        cmd_name = 'coupled_temp_disp'
      else if (index(upper_name, 'INITIAL CONDITIONS') > 0) then
        cmd_name = 'initial_conditions'
      else if (index(upper_name, 'PREDEFINED FIELD') > 0) then
        cmd_name = 'predefined_field'
      else if (index(upper_name, 'HYPERELASTIC') > 0) then
        cmd_name = 'hyperelastic'
      else if (index(upper_name, 'VISCOELASTIC') > 0) then
        cmd_name = 'viscoelastic'
      else if (index(upper_name, 'CREEP') > 0) then
        cmd_name = 'creep'
      else if (index(upper_name, 'DAMPING') > 0) then
        cmd_name = 'damping'
      else if (index(upper_name, 'USER MATERIAL') > 0 .or. index(upper_name, 'UMAT') > 0) then
        cmd_name = 'user_material'
      else if (index(upper_name, 'DSLOAD') > 0) then
        cmd_name = 'dsload'
      else if (index(upper_name, 'CFLUX') > 0) then
        cmd_name = 'cflux'
      else if (index(upper_name, 'DFLUX') > 0) then
        cmd_name = 'dflux'
      else if (index(upper_name, 'FRICTION') > 0) then
        cmd_name = 'friction'
      else if (index(upper_name, 'GAP CONDUCTANCE') > 0) then
        cmd_name = 'gap_conductance'
      else if (index(upper_name, 'MODAL DYNAMIC') > 0) then
        cmd_name = 'modal_dynamic'
      else if (index(upper_name, 'STEADY STATE DYNAMICS') > 0) then
        cmd_name = 'steady_state_dyn'
      else if (index(upper_name, 'GEOSTATIC') > 0) then
        cmd_name = 'geostatic'
      else if (index(upper_name, 'SOILS') > 0) then
        cmd_name = 'soils'
      else if (index(upper_name, 'CONTROLS') > 0) then
        cmd_name = 'controls'
      else if (index(upper_name, 'RESTART') > 0) then
        cmd_name = 'restart'
      else if (index(upper_name, 'MONITOR') > 0) then
        cmd_name = 'monitor'
      else if (index(upper_name, 'NODE PRINT') > 0 .or. index(upper_name, 'NODE FILE') > 0) then
        cmd_name = 'node_output'
      else if (index(upper_name, 'EL PRINT') > 0 .or. index(upper_name, 'EL FILE') > 0 .or. &
               index(upper_name, 'ELEMENT PRINT') > 0 .or. index(upper_name, 'ELEMENT FILE') > 0) then
        cmd_name = 'element_output'
      else if (index(upper_name, 'FIELD OUTPUT') > 0) then
        cmd_name = 'field_output'
      else if (index(upper_name, 'HISTORY OUTPUT') > 0) then
        cmd_name = 'history_output'
      else if (index(upper_name, 'INCLUDE') > 0) then
        cmd_name = 'include'
      else if (index(upper_name, 'PARAMETER') > 0) then
        cmd_name = 'parameter'
      else if (index(upper_name, 'PREPRINT') > 0) then
        cmd_name = 'preprint'
      else if (index(upper_name, 'HEADING') > 0) then
        cmd_name = 'heading'
      else if (index(upper_name, 'END') > 0) then
        ! END keywords: end_part, end_step, etc.
        if (index(upper_name, 'PART') > 0) then
          cmd_name = 'end_part'
        else if (index(upper_name, 'STEP') > 0) then
          cmd_name = 'end_step'
        else if (index(upper_name, 'ASSEMBLY') > 0) then
          cmd_name = 'end_assembly'
        else if (index(upper_name, 'INSTANCE') > 0) then
          cmd_name = 'end_instance'
        else if (index(upper_name, 'CONTACT') > 0) then
          cmd_name = 'end_contact'
        else
          cmd_name = 'end'
        end if
      else
        ! Default: use first word
        cmd_name = lower_name(1:min(space_pos-1, 16))
      end if
    else
      ! Single word keyword
      cmd_name = lower_name(1:min(len_trim(lower_name), 16))
    end if
    
    ! Remove underscores if too long
    if (len_trim(cmd_name) > 16) then
      cmd_name = cmd_name(1:16)
    end if
    
  end function UF_Cmd_KWBrg_ConvKw2CmdName
  
  !===============================================================================
  ! Build Syntax String from Keyword Metadata
  !===============================================================================
  subroutine UF_Cmd_KWBrg_BldSyntax(kw, syntax_str)
    type(KW_MetadataType), intent(in) :: kw
    character(len=*), intent(out) :: syntax_str
    
    integer(i4) :: i
    character(len=16) :: cmd_name
    character(len=256) :: param_list
    
    cmd_name = UF_Cmd_KWBrg_ConvKw2CmdName(kw%keyword_name)
    syntax_str = trim(cmd_name)
    param_list = ''
    
    ! Add parameters
    do i = 1, kw%param_count
      if (len_trim(param_list) > 0) then
        param_list = trim(param_list) // ','
      end if
      param_list = trim(param_list) // trim(kw%params(i)%name) // '=value'
    end do
    
    if (len_trim(param_list) > 0) then
      syntax_str = trim(cmd_name) // ',' // trim(param_list)
    end if
    
    ! Truncate if too long
    if (len_trim(syntax_str) > 256) then
      syntax_str = syntax_str(1:253) // '...'
    end if
    
  end subroutine UF_Cmd_KWBrg_BldSyntax
  
  !===============================================================================
  ! Build Parameters String from Keyword Metadata
  !===============================================================================
  subroutine UF_Cmd_KWBrg_BldParams(kw, params_str)
    type(KW_MetadataType), intent(in) :: kw
    character(len=*), intent(out) :: params_str
    
    integer(i4) :: i
    character(len=512) :: temp_str
    character(len=64) :: param_desc
    
    params_str = ''
    
    do i = 1, kw%param_count
      if (len_trim(params_str) > 0) then
        params_str = trim(params_str) // ', '
      end if
      
      ! Build parameter description
      temp_str = trim(kw%params(i)%name) // ': '
      
      ! Add type info
      select case (kw%params(i)%param_type)
      case (PARAM_TYPE_STRING)
        temp_str = trim(temp_str) // 'string'
      case (PARAM_TYPE_INTEGER)
        temp_str = trim(temp_str) // 'integer'
      case (PARAM_TYPE_REAL)
        temp_str = trim(temp_str) // 'real'
      case (PARAM_TYPE_ENUM)
        temp_str = trim(temp_str) // 'enum'
        if (len_trim(kw%params(i)%enum_values) > 0) then
          temp_str = trim(temp_str) // ' (' // trim(kw%params(i)%enum_values) // ')'
        end if
      case (PARAM_TYPE_LOGICAL)
        temp_str = trim(temp_str) // 'logical'
      case (PARAM_TYPE_NAME_REF)
        temp_str = trim(temp_str) // 'name reference'
      end select
      
      ! Add required flag
      if (kw%params(i)%is_required) then
        temp_str = trim(temp_str) // ' (required)'
      end if
      
      ! Add default value if present
      if (len_trim(kw%params(i)%default_value) > 0) then
        temp_str = trim(temp_str) // ', default=' // trim(kw%params(i)%default_value)
      end if
      
      ! Add description if present
      if (len_trim(kw%params(i)%cfg%description) > 0) then
        temp_str = trim(temp_str) // ' - ' // trim(kw%params(i)%cfg%description)
      end if
      
      params_str = trim(params_str) // trim(temp_str)
      
      ! Truncate if too long
      if (len_trim(params_str) > 500) then
        params_str = params_str(1:497) // '...'
        exit
      end if
    end do
    
  end subroutine UF_Cmd_KWBrg_BldParams
  
  !===============================================================================
  ! Build Example String from Keyword Metadata
  !===============================================================================
  subroutine UF_Cmd_KWBrg_BldExample(kw, cmd_name, example_str)
    type(KW_MetadataType), intent(in) :: kw
    character(len=*), intent(in) :: cmd_name
    character(len=*), intent(out) :: example_str
    
    integer(i4) :: i
    character(len=256) :: temp_str
    
    example_str = trim(cmd_name)
    temp_str = ''
    
    ! Add a few example parameters
    do i = 1, min(kw%param_count, 3)
      if (len_trim(temp_str) > 0) then
        temp_str = trim(temp_str) // ','
      end if
      
      temp_str = trim(temp_str) // trim(kw%params(i)%name) // '='
      
      ! Add example value based on type
      select case (kw%params(i)%param_type)
      case (PARAM_TYPE_STRING, PARAM_TYPE_NAME_REF)
        if (len_trim(kw%params(i)%default_value) > 0) then
          temp_str = trim(temp_str) // trim(kw%params(i)%default_value)
        else
          temp_str = trim(temp_str) // 'value'
        end if
      case (PARAM_TYPE_INTEGER)
        temp_str = trim(temp_str) // '1'
      case (PARAM_TYPE_REAL)
        temp_str = trim(temp_str) // '1.0'
      case (PARAM_TYPE_ENUM)
        if (len_trim(kw%params(i)%default_value) > 0) then
          temp_str = trim(temp_str) // trim(kw%params(i)%default_value)
        else
          temp_str = trim(temp_str) // 'value'
        end if
      case (PARAM_TYPE_LOGICAL)
        temp_str = trim(temp_str) // 'yes'
      end select
    end do
    
    if (len_trim(temp_str) > 0) then
      example_str = trim(cmd_name) // ',' // trim(temp_str)
    end if
    
    ! Truncate if too long
    if (len_trim(example_str) > 512) then
      example_str = example_str(1:509) // '...'
    end if
    
  end subroutine UF_Cmd_KWBrg_BldExample
  
  !===============================================================================
  ! Get Command Name for a Keyword
  !===============================================================================
  function UF_Cmd_KWBrg_GetCmdName(kw_name) result(cmd_name)
    character(len=*), intent(in) :: kw_name
    character(len=16) :: cmd_name
    
    type(KW_MetadataType), pointer :: kw
    
    ! Find keyword
    kw => kw_registry_find(kw_name)
    if (.not. associated(kw)) then
      cmd_name = ''
      return
    end if
    
    ! Convert to command name
    cmd_name = UF_Cmd_KWBrg_ConvKw2CmdName(kw%keyword_name)
    
  end function UF_Cmd_KWBrg_GetCmd
  
  !===============================================================================
  ! Convert Keyword to Command (for future use)
  !===============================================================================
  subroutine UF_Cmd_KWBrg_ConvKw(kw_name, cmd, status)
    character(len=*), intent(in) :: kw_name
    type(Cmd), intent(out) :: cmd
    type(ErrorStatusType), intent(out), optional :: status
    
    type(KW_MetadataType), pointer :: kw
    
    if (present(status)) call init_error_status(status)
    
    ! Find keyword
    kw => kw_registry_find(kw_name)
    if (.not. associated(kw)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        write(status%message, '(A,A,A)') 'Keyword "', trim(kw_name), '" not found'
      end if
      return
    end if
    
    ! Convert keyword name to command name
    cmd%name = UF_Cmd_KWBrg_ConvKw2CmdName(kw%keyword_name)
    
    ! TODO: Convert parameters from keyword format to command format
    ! This would require parsing the keyword's parameter values
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine UF_Cmd_KWBrg_ConvKw
  
end module AP_Inp_KW_Brg