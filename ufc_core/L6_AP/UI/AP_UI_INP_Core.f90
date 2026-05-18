!===============================================================================
! MODULE: AP_UI_INP_Core
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Core — INP file generator
! BRIEF:  ABAQUS-compatible .inp file generation routines.
!===============================================================================

MODULE AP_UI_INP_Core
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: i4, wp
  USE MD_Base_TreeIndex, only: NODE_TYPE_PART, NODE_TYPE_MATER, NODE_TYPE_SECTI, &
                          NODE_TYPE_STEP, NODE_TYPE_LOADB, NODE_TYPE_INTER
  USE MD_Int_Ctx_Core, only: MD_InterDesc, MD_ContDesc, MD_TieDesc
  USE MD_LBC_Mgr, only: MD_LdbcDesc, MD_ConcForceDesc, MD_DispBCDesc, &
                             MD_DistLoadDesc, MD_BodyForceDesc
  USE MD_Mat_Lib, only: MD_Mat_Desc
  USE MD_Model_Tree, only: ModelTree
  USE MD_Out_Def, only: FldOutReq, HistOutReq, &
                             OUT_LOC_NODE, OUT_LOC_ELEM_IN, OUT_FREQ_INCREMENT, &
                             OUT_REGION_ALL, OUT_REGION_NSET, OUT_REGION_ELSET, &
                             OUT_VAR_U, OUT_VAR_RF, OUT_VAR_S, OUT_VAR_E, &
                             OUT_VAR_ALLIE, OUT_VAR_ALLKE
  USE MD_Out_VarReg, only: OutVarReg_GetVarName, g_var_registry
  USE MD_Part_Mgr, only: PartDesc, PartNodeDesc, PartElemDesc, &
                            PartNodeSetDesc, PartElemSetDesc, PartTree
  USE MD_Sect_Mgr, only: SectDesc, SolidSectDesc, ShellSectDesc, BeamSectDesc, SectAssignDesc
  USE MD_Step_Proc, only: StepDesc
  
  implicit none
  private
  
  public :: INPGenerator
  public :: INPGenerator_Generate
  public :: INPGenerator_GeneratePart
  public :: INPGenerator_GenerateMat
  public :: INPGenerator_GenerateSection
  public :: INPGenerator_GenerateStep
  public :: INPGenerator_GenerateLoadBC
  public :: INPGenerator_GenerateInteract
  public :: INPGenerator_Valid
  
  !=============================================================================
  ! TYPE: INPGenerator
  ! Category: Ctx (Context - aggregates references/embedding of Desc/State/Algo)
  ! Purpose: INP file generator context aggregating model tree, formatting options, and file I/O state.
  ! Members:
  !   model_tree: Model tree pointer (Desc reference)
  !   indent_level: Current indentation level n_indent ? ?
  !   indent_size: Indentation size (spaces) n_spaces ?ℤ^+
  !   add_comments: Add comments flag
  !   format_numbers: Format numbers flag
  !   unit_number: File unit number n_unit ? ?
  !=============================================================================
  type, public :: INPGenerator
    type(ModelTree), pointer :: model_tree => null()   ! Desc reference
    integer(i4) :: indent_level = 0_i4                 ! n_indent  ? ?
    integer(i4) :: indent_size = 2_i4                  ! n_spaces  ?ℤ^+
    logical :: add_comments = .true.
    logical :: format_numbers = .true.
    integer(i4) :: unit_number = 0_i4                  ! n_unit  ? ?
  contains
  !=============================================================================
  !> @brief Generate field output section (legacy interface)
  !! @details Generates *OUTPUT, FIELD keyword with node/element variable lists
  !! @param[inout] this INP generator instance
  !! @param[in] field_req Field output request
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine IN_GenerateFieldOutput(this, field_req)
    class(INPGenerator), intent(inout) :: this
    type(FldOutReq), intent(in) :: field_req
    
    character(len=256) :: line, var_list
    integer(i4) :: i
    character(len=16) :: var_name
    logical :: has_node_vars, has_elem_vars
    
    if (.not. field_req%is_active) return
    
    ! Init variable registry if needed
    if (.not. g_var_registry%initialized) then
      call g_var_registry%Init()
    end if
    
    ! Write *OUTPUT, FIELD keyword
    line = '*OUTPUT, FIELD'
    if (field_req%frequency_type == OUT_FREQ_INCREMENT) then
      write(line, '(A,A,I0)') trim(line), ', FREQUENCY=', field_req%frequency
    else if (field_req%frequency_type == OUT_FREQ_TIME_INTERVAL) then
      write(line, '(A,A,ES15.8)') trim(line), ', TIME INTERVAL=', field_req%time_interval
    end if
    call this%WriteKeyword(trim(line))
    
    ! Group variables by location
    has_node_vars = .false.
    has_elem_vars = .false.
    
    ! Check for node variables
    do i = 1, field_req%nVars
      if (g_var_registry%GetVarLocation(field_req%variables(i)) == OUT_LOC_NODE) then
        has_node_vars = .true.
        exit
      end if
    end do
    
    ! Check for element variables
    do i = 1, field_req%nVars
      if (g_var_registry%GetVarLocation(field_req%variables(i)) == OUT_LOC_ELEM_IN) then
        has_elem_vars = .true.
        exit
      end if
    end do
    
    ! Write node output
    if (has_node_vars) then
      call this%WriteKeyword('*NODE OUTPUT')
      var_list = ''
      do i = 1, field_req%nVars
        if (g_var_registry%GetVarLocation(field_req%variables(i)) == OUT_LOC_NODE) then
          var_name = OutVarReg_GetVarName(field_req%variables(i))
          if (len_trim(var_list) > 0) then
            var_list = trim(var_list) // ', ' // trim(var_name)
          else
            var_list = trim(var_name)
          end if
        end if
      end do
      call this%WriteData(trim(var_list))
    end if
    
    ! Write element output
    if (has_elem_vars) then
      call this%WriteKeyword('*ELEMENT OUTPUT')
      var_list = ''
      do i = 1, field_req%nVars
        if (g_var_registry%GetVarLocation(field_req%variables(i)) == OUT_LOC_ELEM_IN) then
          var_name = OutVarReg_GetVarName(field_req%variables(i))
          if (len_trim(var_list) > 0) then
            var_list = trim(var_list) // ', ' // trim(var_name)
          else
            var_list = trim(var_name)
          end if
        end if
      end do
      call this%WriteData(trim(var_list))
    end if
    
  end subroutine INPGenerator_GenerateFieldOutput

  subroutine IN_GenerateHistoryOutput(this, hist_req)
    class(INPGenerator), intent(inout) :: this
    type(HistOutReq), intent(in) :: hist_req
    
    character(len=256) :: line, var_list
    integer(i4) :: i
    character(len=16) :: var_name
    
    if (.not. hist_req%is_active) return
    
    ! Init variable registry if needed
    if (.not. g_var_registry%initialized) then
      call g_var_registry%Init()
    end if
    
    ! Write *OUTPUT, HISTORY keyword
    line = '*OUTPUT, HISTORY'
    if (hist_req%frequency_type == OUT_FREQ_INCREM) then
      write(line, '(A,A,I0)') trim(line), ', FREQUENCY=', hist_req%frequency
    else if (hist_req%frequency_type == OUT_FREQ_TIME_INTERVAL) then
      write(line, '(A,A,ES15.8)') trim(line), ', TIME INTERVAL=', hist_req%time_interval
    end if
    call this%WriteKeyword(trim(line))
    
    ! Write region if specified
    if (len_trim(hist_req%region_name) > 0) then
      select case (hist_req%region_type)
      case (OUT_REGION_NSET)
        call this%WriteKeyword('*NODE OUTPUT, NSET=' // trim(hist_req%region_name))
      case (OUT_REGION_ELSET)
        call this%WriteKeyword('*ELEMENT OUTPUT, ELSET=' // trim(hist_req%region_name))
      case default
        call this%WriteKeyword('*NODE OUTPUT')
      end select
    else
      call this%WriteKeyword('*NODE OUTPUT')
    end if
    
    ! Write variables
    var_list = ''
    do i = 1, hist_req%nVars
      var_name = OutVarReg_GetVarName(hist_req%variables(i))
      if (len_trim(var_list) > 0) then
        var_list = trim(var_list) // ', ' // trim(var_name)
      else
        var_list = trim(var_name)
      end if
    end do
    if (len_trim(var_list) > 0) then
      call this%WriteData(trim(var_list))
    end if
    
  end subroutine INPGenerator_GenerateHistoryOutput

  subroutine IN_GenerateInteract(this, interaction, status)
    class(INPGenerator), intent(inout) :: this
    type(MD_InterDesc), intent(in) :: interaction
    type(ErrorStatusType), intent(out), optional :: status
    
    character(len=256) :: line
    
    if (present(status)) call init_error_status(status)
    
    ! Write interaction keyword based on type
    select type (i => interaction)
    type is (MD_ContDesc)
      call this%WriteKeyword('*CONTACT PAIR, INTERACTION=' // trim(i%name))
      ! Write master and slave surfaces
      if (len_trim(i%masterSurface) > 0 .and. len_trim(i%slaveSurface) > 0) then
        write(line, '(A,1X,A)') trim(i%masterSurface), trim(i%slaveSurface)
        call this%WriteData(trim(line))
      end if
      
      ! Write friction coef if available
      if (i%frictionCoeff > 0.0_wp) then
        call this%WriteComment('Friction coef: ' // trim(real_to_string(i%frictionCoeff)))
      end if
      
    type is (MD_TieDesc)
      call this%WriteKeyword('*TIE, NAME=' // trim(i%name))
      ! Write master and slave surfaces
      if (len_trim(i%masterSurface) > 0 .and. len_trim(i%slaveSurface) > 0) then
        write(line, '(A,1X,A)') trim(i%masterSurface), trim(i%slaveSurface)
        call this%WriteData(trim(line))
      end if
      
    class default
      ! Fallback for basic MD_InterDesc
      select case (trim(interaction%interactionType))
      case ('CONTACT', 'CONTACT_PAIR')
        call this%WriteKeyword('*CONTACT PAIR, INTERACTION=' // trim(interaction%name))
        call this%WriteComment('Master and slave surfaces to be specified')
      case ('TIE', 'TIE_CONSTRAINT')
        call this%WriteKeyword('*TIE, NAME=' // trim(interaction%name))
        call this%WriteComment('Master and slave surfaces to be specified')
      case default
        call this%WriteComment('Interaction type: ' // trim(interaction%interactionType))
      end select
    end select
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  contains
    
    function real_to_string(r) result(str)
      real(wp), intent(in) :: r
      character(len=32) :: str
      write(str, '(ES15.8)') r
    end function real_to_string
    
  end subroutine INPGenerator_GenerateInteract

  subroutine IN_GenerateOutputRequests(this, step)
    class(INPGenerator), intent(inout) :: this
    type(StepDesc), intent(in) :: step
    
    integer(i4) :: i
    type(FldOutReq) :: default_field_r
    type(HistOutReq) :: default_hist_re
    
    ! Generate default field output if no specific requests are defined
    ! In a real implementation, we would get output requests from ModelTree
    ! For now, we'll generate default outputs
    
    ! Default field output: U, RF, S, E
    call default_field_r%Init(name='Field-Output-1', frequency=1, &
                                frequency_type=OUT_FREQ_INCREMENT)
    call default_field_r%AddVariable(OUT_VAR_U)
    call default_field_r%AddVariable(OUT_VAR_RF)
    call default_field_r%AddVariable(OUT_VAR_S)
    call default_field_r%AddVariable(OUT_VAR_E)
    call this%GenerateFieldOutput(default_field_r)
    
    ! Default history output: ALLIE, ALLKE
    call default_hist_re%Init(name='History-Output-1', frequency=1, &
                               frequency_type=OUT_FREQ_INCREMENT)
    call default_hist_re%AddVariable(OUT_VAR_ALLIE)
    call default_hist_re%AddVariable(OUT_VAR_ALLKE)
    call this%GenerateHistoryOutput(default_hist_re)
    
    ! Try to get actual output requests from ModelTree
    ! Check if ModelTree has output requests stored
    if (associated(this%model_tree)) then
      ! Get step ID from step description
      integer(i4) :: step_id, i
      type(FldOutReq), allocatable :: field_reqs(:)
      type(HistOutReq), allocatable :: hist_reqs(:)
      class(*), pointer :: step_ptr => null()
      
      ! Try to get step from ModelTree
      step_id = step%cfg%id
      if (step_id > 0_i4) then
        step_ptr => this%model_tree%GetStep(id=step_id)
        if (associated(step_ptr)) then
          ! Check if step has output requests
          ! Note: Output requests are typically stored in StepDesc or ModelTree
          ! For now, we check if there are output requests in the step
          
          ! In production, we would:
          !   1. Check StepDesc for output request IDs
          !   2. Query ModelTree for FldOutReq/HistOutReq objects
          !   3. Generate output requests from those
          
          ! For now, we use default outputs as fallback
          ! The default outputs generated above will be used
        end if
      end if
    end if
    
  end subroutine INPGenerator_GenerateOutputRequests

  !=============================================================================
  !> @brief Generate INP file (legacy interface)
  !! @details Generates complete ABAQUS INP file from model tree
  !! @param[inout] this INP generator instance
  !! @param[in] model_tree Model tree reference
  !! @param[in] output_file Output file path
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !!   Theory: Generate INP file with parts, materials, sections, steps, loads, interactions
  !=============================================================================
  subroutine INPGenerator_Generate(this, model_tree, output_file, status)
    class(INPGenerator), intent(inout) :: this
    type(ModelTree), intent(in), target :: model_tree
    character(len=*), intent(in) :: output_file
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: ios, i
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    
    this%model_tree => model_tree
    
    ! Open output file
    open(newunit=this%unit_number, file=trim(output_file), status='replace', &
         action='write', form='formatted', iostat=ios)
    if (ios /= 0_i4) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        write(status%message, '(A,A)') 'Failed to open output file: ', trim(output_file)
      end if
      return
    end if
    
    ! Write header
    call this%WriteComment('ABAQUS Input File')
    call this%WriteComment('Generated by UFC (UniFieldCore)')
    call this%WriteComment('')
    
    ! Write model header
    call this%WriteKeyword('*HEADING')
    call this%WriteData(trim(model_tree%name))
    call this%WriteData('')
    
    ! Generate Parts
    if (model_tree%GetNumParts() > 0_i4) then
      call this%WriteComment('Parts')
      do i = 1, model_tree%GetNumParts()
        obj_ptr => model_tree%GetPart(id=i)
        if (associated(obj_ptr)) then
          select type (p => obj_ptr)
          type is (PartTree)
            call this%GeneratePart(p, local_status)
          class is (PartDesc)
            call this%GeneratePart(p, local_status)
          end select
        end if
      end do
    end if
    
    ! Generate Materials
    if (model_tree%GetNumMaterials() > 0_i4) then
      call this%WriteComment('Materials')
      do i = 1, model_tree%GetNumMaterials()
        obj_ptr => model_tree%GetMaterial(id=i)
        if (associated(obj_ptr)) then
          select type (m => obj_ptr)
          type is (MD_Mat_Desc)
            call this%GenerateMaterial(m, local_status)
          end select
        end if
      end do
    end if
    
    ! Generate Sections
    if (model_tree%GetNumSections() > 0_i4) then
      call this%WriteComment('Sections')
      do i = 1, model_tree%GetNumSections()
        obj_ptr => model_tree%GetSection(id=i)
        if (associated(obj_ptr)) then
          select type (s => obj_ptr)
          type is (SectDesc)
            call this%GenerateSection(s, local_status)
          end select
        end if
      end do
    end if
    
    ! Generate Steps
    if (model_tree%GetNumSteps() > 0_i4) then
      call this%WriteComment('Steps')
      do i = 1, model_tree%GetNumSteps()
        obj_ptr => model_tree%GetStep(id=i)
        if (associated(obj_ptr)) then
          select type (st => obj_ptr)
          type is (StepDesc)
            call this%GenerateStep(st, local_status)
          end select
        end if
      end do
    end if
    
    ! Generate LoadBCs (if available)
    ! Note: LoadBCs are typically generated within Steps, but can also be standalone
    ! For now, we'll generate them within Steps (see GenerateStep)
    
    ! Generate Interactions (if available)
    ! Note: Interactions are typically generated within Steps, but can also be standalone
    ! For now, we'll generate them within Steps (see GenerateStep)
    
    ! Close file
    close(this%unit_number)
    this%unit_number = 0_i4
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  end subroutine INPGenerator_Generate

  subroutine INPGenerator_GenerateLoadBC(this, loadbc, status)
    class(INPGenerator), intent(inout) :: this
    type(MD_LdbcDesc), intent(in) :: loadbc
    type(ErrorStatusType), intent(out), optional :: status
    
    character(len=256) :: line
    integer(i4) :: i
    
    if (present(status)) call init_error_status(status)
    
    ! Write load/BC keyword based on type
    select case (trim(loadbc%loadBCType))
    case ('DISPLACEMENT', 'BOUNDARY', 'FIXED')
      call this%WriteKeyword('*BOUNDARY')
      ! Write boundary condition: node set/region, DOF, value
      if (len_trim(loadbc%region) > 0) then
        write(line, '(A,1X,I0,1X,ES15.8)') trim(loadbc%region), 1, loadbc%value
        if (allocated(loadbc%dofs)) then
          do i = 1, size(loadbc%dofs)
            if (loadbc%dofs(i) > 0) then
              write(line, '(A,1X,I0,1X,ES15.8)') trim(loadbc%region), loadbc%dofs(i), loadbc%value
              call this%WriteData(trim(line))
            end if
          end do
        else
          call this%WriteData(trim(line))
        end if
      end if
      
    case ('FORCE', 'CONCENTRATED_FORCE', 'CLOAD')
      call this%WriteKeyword('*CLOAD')
      ! Write concentrated load: node set/region, DOF, magnitude
      if (len_trim(loadbc%region) > 0) then
        if (allocated(loadbc%dofs)) then
          do i = 1, size(loadbc%dofs)
            if (loadbc%dofs(i) > 0) then
              write(line, '(A,1X,I0,1X,ES15.8)') trim(loadbc%region), loadbc%dofs(i), loadbc%value
              call this%WriteData(trim(line))
            end if
          end do
        else
          write(line, '(A,1X,I0,1X,ES15.8)') trim(loadbc%region), 1, loadbc%value
          call this%WriteData(trim(line))
        end if
      end if
      
    case ('PRESSURE', 'distributed_loa', 'DLOAD')
      call this%WriteKeyword('*DLOAD')
      ! Write distributed load: element set/surface, pressure magnitude
      if (len_trim(loadbc%region) > 0) then
        write(line, '(A,1X,A,1X,ES15.8)') trim(loadbc%region), 'P', loadbc%value
        call this%WriteData(trim(line))
      end if
      
    case ('BODY_FORCE', 'GRAVITY')
      call this%WriteKeyword('*DLOAD')
      ! Write body force: element set, gravity magnitude
      if (len_trim(loadbc%region) > 0) then
        write(line, '(A,1X,A,1X,ES15.8)') trim(loadbc%region), 'GRAV', loadbc%value
        call this%WriteData(trim(line))
      end if
      
    case default
      ! Default: boundary condition
      call this%WriteKeyword('*BOUNDARY')
      if (len_trim(loadbc%region) > 0) then
        write(line, '(A,1X,I0,1X,ES15.8)') trim(loadbc%region), 1, loadbc%value
        call this%WriteData(trim(line))
      end if
    end select
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine INPGenerator_GenerateLoadBC

  subroutine INPGenerator_GenerateMat(this, Mat, status)
    class(INPGenerator), intent(inout) :: this
    type(MD_Mat_Desc), intent(in) :: Mat
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i, n_props
    character(len=256) :: line
    
    if (present(status)) call init_error_status(status)
    
    ! Write *Mat keyword
    call this%WriteKeyword('*Mat, NAME=' // trim(Mat%name))
    
    ! Write Mat properties based on type
    select case (trim(Mat%cfg%materialType))
    case ('ELASTIC', 'ISOTROPIC', 'LINEAR_ELASTIC')
      call this%WriteKeyword('*ELASTIC')
      ! Write E, nu (first two properties)
      if (allocated(Mat%props) .and. size(Mat%props) >= 2) then
        write(line, '(2(1X,ES15.8))') Mat%props(1), Mat%props(2)
        call this%WriteData(trim(line))
      else
        call this%WriteData('1.0E6, 0.3')
      end if
      
    case ('PLASTIC', 'MISES', 'VON_MISES')
      ! Write elastic properties first
      call this%WriteKeyword('*ELASTIC')
      if (allocated(Mat%props) .and. size(Mat%props) >= 2) then
        write(line, '(2(1X,ES15.8))') Mat%props(1), Mat%props(2)
        call this%WriteData(trim(line))
      else
        call this%WriteData('1.0E6, 0.3')
      end if
      
      ! Write plastic properties
      call this%WriteKeyword('*PLASTIC')
      if (allocated(Mat%props) .and. size(Mat%props) >= 4) then
        ! Write yield sigma and plastic strain pairs
        n_props = size(Mat%props)
        do i = 3, n_props, 2
          if (i+1 <= n_props) then
            write(line, '(2(1X,ES15.8))') Mat%props(i), Mat%props(i+1)
            call this%WriteData(trim(line))
          else
            write(line, '(1X,ES15.8)') Mat%props(i)
            call this%WriteData(trim(line))
          end if
        end do
      else
        call this%WriteData('2.0E5, 0.0')
      end if
      
    case ('DAMAGE', 'damage_initiati')
      ! Write elastic properties first
      call this%WriteKeyword('*ELASTIC')
      if (allocated(Mat%props) .and. size(Mat%props) >= 2) then
        write(line, '(2(1X,ES15.8))') Mat%props(1), Mat%props(2)
        call this%WriteData(trim(line))
      else
        call this%WriteData('1.0E6, 0.3')
      end if
      
      ! Write damage initiation
      call this%WriteKeyword('*DAMAGE INITIATION, CRITERION=MAXS')
      if (allocated(Mat%props) .and. size(Mat%props) >= 3) then
        write(line, '(1X,ES15.8)') Mat%props(3)
        call this%WriteData(trim(line))
      else
        call this%WriteData('1.0E6')
      end if
      
    case ('HYPERELASTIC', 'HYPER_ELASTIC')
      call this%WriteKeyword('*HYPERELASTIC')
      if (allocated(Mat%props)) then
        line = ''
        do i = 1, min(size(Mat%props), 6)
          if (len_trim(line) > 0) then
            write(line, '(A,1X,ES15.8)') trim(line), Mat%props(i)
          else
            write(line, '(ES15.8)') Mat%props(i)
          end if
        end do
        call this%WriteData(trim(line))
      end if
      
    case default
      ! Default: elastic Mat
      call this%WriteKeyword('*ELASTIC')
      if (allocated(Mat%props) .and. size(Mat%props) >= 2) then
        write(line, '(2(1X,ES15.8))') Mat%props(1), Mat%props(2)
        call this%WriteData(trim(line))
      else
        call this%WriteData('1.0E6, 0.3')
      end if
    end select
    
    ! Write density if available
    if (allocated(Mat%props) .and. size(Mat%props) >= 10) then
      call this%WriteKeyword('*DENSITY')
      write(line, '(1X,ES15.8)') Mat%props(10)
      call this%WriteData(trim(line))
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine INPGenerator_GenerateMat

  subroutine INPGenerator_GeneratePart(this, part, status)
    class(INPGenerator), intent(inout) :: this
    type(PartDesc), intent(in) :: part
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: i, j, n_nodes, n_elems, n_nodesets, n_elemsets
    class(*), pointer :: obj_ptr
    character(len=256) :: line, elem_type_str
    type(PartNodeDesc), pointer :: node_ptr
    type(PartElemDesc), pointer :: elem_ptr
    type(PartNodeSetDesc), pointer :: nodeset_ptr
    type(PartElemSetDesc), pointer :: elemset_ptr
    
    if (present(status)) call init_error_status(status)
    
    ! Write *PART keyword
    call this%WriteKeyword('*PART, NAME=' // trim(part%name))
    
    ! Check if part is PartTree (has tree structure)
    select type (pt => part)
    type is (PartTree)
      ! Write nodes from PartTree
      n_nodes = pt%GetNumNodes()
      if (n_nodes > 0_i4) then
        call this%WriteKeyword('*NODE')
        do i = 1, n_nodes
          obj_ptr => pt%GetNode(id=i)
          if (associated(obj_ptr)) then
            select type (n => obj_ptr)
            type is (PartNodeDesc)
              write(line, '(I0,3(1X,ES15.8))') n%cfg%id, n%coords(1), n%coords(2), n%coords(3)
              call this%WriteData(trim(line))
            end select
          end if
        end do
      end if
      
      ! Write elements from PartTree
      n_elems = pt%GetNumElements()
      if (n_elems > 0_i4) then
        ! Group elements by type
        do i = 1, n_elems
          obj_ptr => pt%GetElement(id=i)
          if (associated(obj_ptr)) then
            select type (e => obj_ptr)
            type is (PartElemDesc)
              ! Get element type string
              elem_type_str = GetElementTypeString(e%typeId)
              call this%WriteKeyword('*ELEMENT, TYPE=' // trim(elem_type_str))
              
              ! Write element connectivity
              write(line, '(I0)') e%cfg%id
              do j = 1, 8
                if (e%nodes(j) > 0_i4) then
                  write(line, '(A,1X,I0)') trim(line), e%nodes(j)
                end if
              end do
              call this%WriteData(trim(line))
            end select
          end if
        end do
      end if
      
      ! Write node sets
      n_nodesets = pt%GetNumNodeSets()
      if (n_nodesets > 0_i4) then
        do i = 1, n_nodesets
          obj_ptr => pt%GetNodeSet(id=i)
          if (associated(obj_ptr)) then
            select type (ns => obj_ptr)
            type is (PartNodeSetDesc)
              call this%WriteKeyword('*NSET, NSET=' // trim(ns%name))
              ! Write node IDs (format: up to 16 per line)
              line = ''
              j = 0
              do j = 1, size(ns%localNodeIds)
                if (j > 1 .and. mod(j-1, 16) == 0) then
                  call this%WriteData(trim(line))
                  line = ''
                end if
                if (len_trim(line) > 0) then
                  write(line, '(A,1X,I0)') trim(line), ns%localNodeIds(j)
                else
                  write(line, '(I0)') ns%localNodeIds(j)
                end if
              end do
              if (len_trim(line) > 0) call this%WriteData(trim(line))
            end select
          end if
        end do
      end if
      
      ! Write element sets
      n_elemsets = pt%GetNumElemSets()
      if (n_elemsets > 0_i4) then
        do i = 1, n_elemsets
          obj_ptr => pt%GetElemSet(id=i)
          if (associated(obj_ptr)) then
            select type (es => obj_ptr)
            type is (PartElemSetDesc)
              call this%WriteKeyword('*ELSET, ELSET=' // trim(es%name))
              ! Write element IDs (format: up to 16 per line)
              line = ''
              do j = 1, size(es%localElemIds)
                if (j > 1 .and. mod(j-1, 16) == 0) then
                  call this%WriteData(trim(line))
                  line = ''
                end if
                if (len_trim(line) > 0) then
                  write(line, '(A,1X,I0)') trim(line), es%localElemIds(j)
                else
                  write(line, '(I0)') es%localElemIds(j)
                end if
              end do
              if (len_trim(line) > 0) call this%WriteData(trim(line))
            end select
          end if
        end do
      end if
    class default
      ! Fallback for basic PartDesc (no tree structure)
      !! ?PartDesc ? ?
      !! Step 1:  Part 
      !! Step 2: part ? ID
      !! Step 3: Part ?
      call this%WriteComment('Part ' // trim(part%name) // ' (basic PartDesc, tree structure not available)')
    end select
    
    ! Write *END PART
    call this%WriteKeyword('*END PART')
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  contains
    
    function GetElementTypeString(typeId) result(typeStr)
      integer(i4), intent(in) :: typeId
      character(len=32) :: typeStr
      
      select case (typeId)
      case (1)
        typeStr = 'C3D8'
      case (2)
        typeStr = 'C3D4'
      case (3)
        typeStr = 'C3D6'
      case (4)
        typeStr = 'S4'
      case (5)
        typeStr = 'S3'
      case (6)
        typeStr = 'B31'
      case default
        write(typeStr, '(A,I0)') 'UNKNOWN_', typeId
      end select
    end function GetElementTypeString
    
  end subroutine INPGenerator_GeneratePart

  subroutine INPGenerator_GenerateSection(this, section, status)
    class(INPGenerator), intent(inout) :: this
    type(SectDesc), intent(in) :: section
    type(ErrorStatusType), intent(out), optional :: status
    
    character(len=256) :: line, elem_set_name, material_name
    
    if (present(status)) call init_error_status(status)
    
    ! Get element set and Mat name from section assignment (if available)
    !! getelement material ? ?
    !! Step 1: section.materialName getmaterial 
    !! Step 2:  section getelset 
    !! Step 3: ?section.name default
    elem_set_name = trim(section%name) // '_ELSET'
    material_name = trim(section%name) // '_MAT'
    
    ! Write section keyword based on type
    select type (s => section)
    type is (SolidSectDesc)
      call this%WriteKeyword('*SOLID SECTION, ELSET=' // trim(elem_set_name) // &
                            ', Mat=' // trim(s%materialName))
      
    type is (ShellSectionDesc)
      call this%WriteKeyword('*SHELL SECTION, ELSET=' // trim(elem_set_name) // &
                            ', Mat=' // trim(s%materialName))
      ! Write thickness
      write(line, '(1X,ES15.8)') s%thickness
      call this%WriteData(trim(line))
      
    type is (BeamSectDesc)
      call this%WriteKeyword('*BEAM SECTION, ELSET=' // trim(elem_set_name) // &
                            ', Mat=' // trim(s%materialName))
      ! Write beam properties (area, I11, I22, I12)
      write(line, '(4(1X,ES15.8))') s%area, s%I11, s%I22, s%I12
      call this%WriteData(trim(line))
      
    class default
      ! Fallback for basic SectDesc
      select case (trim(section%sectionType))
      case ('SOLID', 'SOLID_SECTION')
        call this%WriteKeyword('*SOLID SECTION, ELSET=' // trim(elem_set_name) // &
                              ', Mat=' // trim(material_name))
      case ('SHELL', 'SHELL_SECTION')
        call this%WriteKeyword('*SHELL SECTION, ELSET=' // trim(elem_set_name) // &
                              ', Mat=' // trim(material_name))
        call this%WriteData('1.0')
      case ('BEAM', 'BEAM_SECTION')
        call this%WriteKeyword('*BEAM SECTION, ELSET=' // trim(elem_set_name) // &
                              ', Mat=' // trim(material_name))
        call this%WriteData('1.0, 1.0, 1.0, 1.0')
      case default
        ! Default: solid section
        call this%WriteKeyword('*SOLID SECTION, ELSET=' // trim(elem_set_name) // &
                              ', Mat=' // trim(material_name))
      end select
    end select
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine INPGenerator_GenerateSection

  subroutine INPGenerator_GenerateStep(this, step, status)
    class(INPGenerator), intent(inout) :: this
    type(StepDesc), intent(in) :: step
    type(ErrorStatusType), intent(out), optional :: status
    
    character(len=256) :: line
    integer(i4) :: i
    
    if (present(status)) call init_error_status(status)
    
    ! Write *STEP keyword
    select case (trim(step%stepType))
    case ('STATIC', 'STATIC_GENERAL')
      if (step%nlFlag) then
        call this%WriteKeyword('*STEP, NAME=' // trim(step%name) // ', NLGEOM=YES')
      else
        call this%WriteKeyword('*STEP, NAME=' // trim(step%name) // ', NLGEOM=NO')
      end if
      call this%WriteKeyword('*STATIC')
      ! Write time period, initial increment, min increment, max increment
      write(line, '(4(1X,ES15.8))') step%totalTime, step%dtInit, step%dtMin, step%dtMax
      call this%WriteData(trim(line))
      
    case ('DYNAMIC', 'DYNAMIC_EXPLICIT', 'DYNAMIC_IMPLICIT')
      call this%WriteKeyword('*STEP, NAME=' // trim(step%name))
      if (step%nIncs > 0) then
        write(line, '(A,I0)') '*DYNAMIC, INC=', step%nIncs
        call this%WriteKeyword(trim(line))
      else
        call this%WriteKeyword('*DYNAMIC')
      end if
      ! Write time period, initial increment, etc.
      write(line, '(4(1X,ES15.8))') step%totalTime, step%dtInit, step%dtMin, step%dtMax
      call this%WriteData(trim(line))
      
    case ('FREQUENCY', 'FREQUENCY_EXTRACTION')
      call this%WriteKeyword('*STEP, NAME=' // trim(step%name))
      call this%WriteKeyword('*FREQUENCY')
      ! Write number of eigenvalues
      if (step%nIncs > 0) then
        write(line, '(I0)') step%nIncs
        call this%WriteData(trim(line))
      else
        call this%WriteData('10')
      end if
      
    case ('BUCKLE', 'BUCKLE_EIGENVALUE')
      call this%WriteKeyword('*STEP, NAME=' // trim(step%name))
      call this%WriteKeyword('*BUCKLE')
      ! Write number of eigenvalues
      if (step%nIncs > 0) then
        write(line, '(I0)') step%nIncs
        call this%WriteData(trim(line))
      else
        call this%WriteData('10')
      end if
      
    case default
      ! Default: static step
      call this%WriteKeyword('*STEP, NAME=' // trim(step%name))
      call this%WriteKeyword('*STATIC')
      write(line, '(4(1X,ES15.8))') step%totalTime, step%dtInit, step%dtMin, step%dtMax
      call this%WriteData(trim(line))
    end select
    
    ! Write loads and BCs (if IDs are available)
    if (allocated(step%loadIds)) then
      do i = 1, size(step%loadIds)
        ! Get MD_LdbcDesc from model tree
        if (associated(this%model_tree)) then
          obj_ptr => this%model_tree%GetLoadBC(id=step%loadIds(i))
          if (associated(obj_ptr)) then
            select type (lb => obj_ptr)
            type is (MD_LdbcDesc)
              ! Only generate if it's a load (not BC)
              if (index(trim(lb%loadBCType), 'FORCE') > 0 .or. &
                  index(trim(lb%loadBCType), 'LOAD') > 0 .or. &
                  index(trim(lb%loadBCType), 'PRESSURE') > 0) then
                call this%GenerateLoadBC(lb, local_status)
              end if
            end select
          end if
        end if
      end do
    end if
    
    if (allocated(step%bcIds)) then
      do i = 1, size(step%bcIds)
        ! Get MD_LdbcDesc from model tree
        if (associated(this%model_tree)) then
          obj_ptr => this%model_tree%GetLoadBC(id=step%bcIds(i))
          if (associated(obj_ptr)) then
            select type (bc => obj_ptr)
            type is (MD_LdbcDesc)
              ! Only generate if it's a boundary condition
              if (index(trim(bc%loadBCType), 'BOUNDARY') > 0 .or. &
                  index(trim(bc%loadBCType), 'DISPLACEMENT') > 0 .or. &
                  index(trim(bc%loadBCType), 'FIXED') > 0) then
                call this%GenerateLoadBC(bc, local_status)
              end if
            end select
          end if
        end if
      end do
    end if
    
    ! Write interactions
    if (allocated(step%interactionIds)) then
      do i = 1, size(step%interactionIds)
        ! Get MD_InterDesc from model tree
        if (associated(this%model_tree)) then
          obj_ptr => this%model_tree%GetInteraction(id=step%interactionIds(i))
          if (associated(obj_ptr)) then
            select type (int => obj_ptr)
            type is (MD_InterDesc)
              call this%GenerateInteraction(int, local_status)
            end select
          end if
        end if
      end do
    end if
    
    ! Write output requests
    call this%GenerateOutputRequests(step)
    
    ! Write *END STEP
    call this%WriteKeyword('*END STEP')
    
    if (present(status)) status%status_code = IF_STATUS_OK
    
  contains
    
    function itoa(i) result(str)
      integer(i4), intent(in) :: i
      character(len=32) :: str
      write(str, '(I0)') i
    end function itoa
    
  end subroutine INPGenerator_GenerateStep

  function INPGenerator_GetIndent(this) result(indent_str)
    class(INPGenerator), intent(in) :: this
    character(len=256) :: indent_str
    integer(i4) :: i, n_spaces
    
    indent_str = ''
    n_spaces = this%indent_level * this%indent_size
    do i = 1, min(n_spaces, 256)
      indent_str(i:i) = ' '
    end do
  end function INPGenerator_GetIndent

  function INPGenerator_Valid(this, inp_file) result(is_valid)
    class(INPGenerator), intent(in) :: this
    character(len=*), intent(in) :: inp_file
    logical :: is_valid
    
    integer(i4) :: unit_num, ios
    character(len=256) :: line
    integer(i4) :: line_count
    
    is_valid = .false.
    
    ! Open file for reading
    open(newunit=unit_num, file=trim(inp_file), status='old', &
         action='read', form='formatted', iostat=ios)
    if (ios /= 0_i4) return
    
    ! Basic validation: check file is readable and has content
    line_count = 0_i4
    do
      read(unit_num, '(A)', iostat=ios) line
      if (ios /= 0_i4) exit
      line_count = line_count + 1_i4
      if (line_count > 10_i4) exit  ! Just check first few lines
    end do
    
    close(unit_num)
    
    is_valid = (line_count > 0_i4)
  end function INPGenerator_Valid

  !=============================================================================
  !> @brief Write comment line (legacy interface)
  !! @details Writes a comment line to the INP file
  !! @param[inout] this INP generator instance
  !! @param[in] comment Comment text
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine INPGenerator_WriteComment(this, comment)
    class(INPGenerator), intent(inout) :: this
    character(len=*), intent(in) :: comment
    
    if (this%unit_number <= 0_i4) return
    if (.not. this%add_comments) return
    
    write(this%unit_number, '(A,A)') '** ', trim(comment)
  end subroutine INPGenerator_WriteComment

  !=============================================================================
  !> @brief Write data line (legacy interface)
  !! @details Writes a data line with indentation to the INP file
  !! @param[inout] this INP generator instance
  !! @param[in] data_line Data line text
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine INPGenerator_WriteData(this, data_line)
    class(INPGenerator), intent(inout) :: this
    character(len=*), intent(in) :: data_line
    
    character(len=256) :: indent_str
    
    if (this%unit_number <= 0_i4) return
    
    indent_str = this%GetIndent()
    write(this%unit_number, '(A,A)') trim(indent_str), trim(data_line)
  end subroutine INPGenerator_WriteData

  !=============================================================================
  !> @brief Write keyword line (legacy interface)
  !! @details Writes a keyword line with indentation to the INP file
  !! @param[inout] this INP generator instance
  !! @param[in] keyword Keyword text
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine INPGenerator_WriteKeyword(this, keyword)
    class(INPGenerator), intent(inout) :: this
    character(len=*), intent(in) :: keyword
    
    character(len=256) :: indent_str
    
    if (this%unit_number <= 0_i4) return
    
    indent_str = this%GetIndent()
    write(this%unit_number, '(A,A)') trim(indent_str), trim(keyword)
  end subroutine INPGenerator_WriteKeyword
end MODULE AP_UI_INP_Core