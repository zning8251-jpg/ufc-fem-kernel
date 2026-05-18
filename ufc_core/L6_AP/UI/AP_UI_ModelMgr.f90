!===============================================================================
! MODULE: AP_UI_ModelMgr
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Mgr — model UI manager
! BRIEF:  Model validation and property editing for model tree UI.
!===============================================================================

module AP_UI_ModelMgr
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: i4, wp
  USE MD_Base_TreeIndex, only: TreeNodeBase, NODE_TYPE_MODEL, NODE_TYPE_PART, &
                          NODE_TYPE_ASSEM, NODE_TYPE_MATER, &
                          NODE_TYPE_SECTI, NODE_TYPE_MESH, &
                          NODE_TYPE_AMPLI, NODE_TYPE_LOADB, &
                          NODE_TYPE_INTER, NODE_TYPE_STEP
  USE MD_Int_Ctx_Core, only: MD_InterDesc, MD_ContDesc, MD_TieDesc
  USE MD_LBC_Mgr, only: MD_LdbcDesc
  USE MD_Mat_Lib, only: MD_Mat_Desc
  USE MD_Model_Tree, only: ModelTree
  USE MD_Part_Mgr, only: PartDesc, PartTree, PartElemSetDesc
  USE MD_Sect_Mgr, only: SectDesc, SolidSectDesc, ShellSectDesc, BeamSectDesc
  USE MD_Step_Proc, only: StepDesc
  USE AP_UI_TreeMgr, only: TreeMgr
  USE VD_Core, only: ValidState, ValidIssue, VALID_SEV_ERR, VALID_SEV_WARN
  USE VD_Mgr, only: ValidMgr_ValidModel

  implicit none
  private

  ! --- ValidMgr public ---
  public :: ValidMgr
  public :: ValidRes
  public :: ValidMgr_ValidModel
  public :: ValidMgr_ValidNode
  public :: ValidMgr_ChkDep
  public :: ValidMgr_GetRpt

  ! --- PropertyMgr public ---
  public :: PropertyMgr
  public :: PropertyField
  public :: PropertyForm
  public :: PropertyMgr_GetForm
  public :: PropertyMgr_GetFieldValue
  public :: PropertyMgr_SetFieldValue
  public :: PropertyMgr_ValidateForm
  public :: PropertyMgr_ApplyChanges

  ! Field type constants (PropertyMgr)
  integer(i4), parameter, public :: FIELD_TYPE_TEXT = 1_i4
  integer(i4), parameter, public :: FIELD_TYPE_INT = 2_i4
  integer(i4), parameter, public :: FIELD_TYPE_REAL = 3_i4
  integer(i4), parameter, public :: FIELD_TYPE_BOOL = 4_i4
  integer(i4), parameter, public :: FIELD_TYPE_CHOICE = 5_i4
  integer(i4), parameter, public :: FIELD_TYPE_CHOICECE = 5_i4
  integer(i4), parameter, public :: FIELD_TYPE_MULTI = 6_i4

  !=============================================================================
  ! ValidRes - validation result type
  !=============================================================================
  type, public :: ValidRes
    logical :: is_valid = .true.
    integer(i4) :: num_errors = 0_i4
    integer(i4) :: num_warnings = 0_i4
    character(len=256), allocatable :: errors(:)
    character(len=256), allocatable :: warnings(:)
  end type ValidRes

  !=============================================================================
  ! ValidMgr - validation manager type
  !=============================================================================
  type, public :: ValidMgr
    type(TreeMgr), pointer :: tree_mgr => null()
    logical :: init = .false.
  contains
    procedure, public :: Init => ValidMgr_Init
    procedure, public :: ValidateModel => ValidMgr_ValidModel
    procedure, public :: ValidateNode => ValidMgr_ValidNode
    procedure, public :: CheckDependencies => ValidMgr_ChkDep
    procedure, public :: GetValidationReport => ValidMgr_GetRpt
    procedure, private :: ValidatePart => ValidMgr_ValidatePart
    procedure, private :: ValidateMaterial => ValidMgr_ValidateMaterial
    procedure, private :: ValidateSection => ValidMgr_ValidateSection
    procedure, private :: ValidateStep => ValidMgr_ValidateStep
    procedure, private :: ValidateLoadBC => ValidMgr_ValidateLoadBC
  end type ValidMgr

  !=============================================================================
  ! PropertyField - property field type
  !=============================================================================
  type, public :: PropertyField
    character(len=64) :: field_name = ''
    character(len=128) :: display_name = ''
    character(len=256) :: description = ''
    integer(i4) :: field_type = FIELD_TYPE_TEXT
    logical :: is_required = .false.
    logical :: is_readonly = .false.
    character(len=256) :: default_value = ''
    character(len=256) :: current_value = ''
    character(len=256) :: validation_rule = ''
    integer(i4) :: num_choices = 0_i4
    character(len=64), allocatable :: choices(:)
  end type PropertyField

  !=============================================================================
  ! PropertyForm - property form type
  !=============================================================================
  type, public :: PropertyForm
    integer(i4) :: node_type = 0_i4
    character(len=64) :: form_name = ''
    character(len=128) :: form_title = ''
    integer(i4) :: num_fields = 0_i4
    type(PropertyField), allocatable :: fields(:)
  end type PropertyForm

  !=============================================================================
  ! PropertyMgr - property manager type
  !=============================================================================
  type, public :: PropertyMgr
    type(TreeMgr), pointer :: tree_mgr => null()
    type(PropertyForm), allocatable :: forms(:)
    logical :: init = .false.
  contains
    procedure, public :: Init => PropertyMgr_Init
    procedure, public :: GetForm => PropertyMgr_GetForm
    procedure, public :: GetFieldValue => PropertyMgr_GetFieldValue
    procedure, public :: SetFieldValue => PropertyMgr_SetFieldValue
    procedure, public :: ValidateForm => PropertyMgr_ValidateForm
    procedure, public :: ApplyChanges => PropertyMgr_ApplyChanges
    procedure, private :: CreateFormForNodeType => PropMgr_CreateFormForNodeType
  end type PropertyMgr

contains

  !=============================================================================
  ! ValidMgr procedures
  !=============================================================================

  subroutine ValidMgr_Init(this, tree_mgr, status)
    class(ValidMgr), intent(inout) :: this
    type(TreeMgr), intent(in), target :: tree_mgr
    type(ErrorStatusType), intent(out), optional :: status

    if (present(status)) call init_error_status(status)
    this%tree_mgr => tree_mgr
    this%init = .true.
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine ValidMgr_Init

  subroutine ValidMgr_ValidModel(this, model_tree, result, status)
    class(ValidMgr), intent(in) :: this
    type(ModelTree), intent(in) :: model_tree
    type(ValidRes), intent(out) :: result
    type(ErrorStatusType), intent(out), optional :: status

    type(ValidState) :: val_state
    type(ErrorStatusType) :: val_status
    type(ValidIssue), allocatable :: error_issues(:), warn_issues(:)
    integer(i4) :: i

    if (present(status)) call init_error_status(status)
    result%is_valid = .true.
    result%num_errors = 0_i4
    result%num_warnings = 0_i4

    call ValidMgr_ValidModel(model_tree, val_state, val_status)

    if (val_state%n_errors > 0_i4) then
      error_issues = val_state%GetIssues(VALID_SEV_ERR)
      if (allocated(error_issues)) then
        result%is_valid = .false.
        result%num_errors = size(error_issues)
        allocate(result%errors(result%num_errors))
        do i = 1, result%num_errors
          result%errors(i) = error_issues(i)%message
        end do
      end if
    end if

    if (val_state%n_warnings > 0_i4) then
      warn_issues = val_state%GetIssues(VALID_SEV_WARN)
      if (allocated(warn_issues)) then
        result%num_warnings = size(warn_issues)
        allocate(result%warnings(result%num_warnings))
        do i = 1, result%num_warnings
          result%warnings(i) = warn_issues(i)%message
        end do
      end if
    end if

    call this%CheckDependencies(model_tree, result)
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine ValidMgr_ValidModel

  subroutine ValidMgr_ValidNode(this, node_id, result, status)
    class(ValidMgr), intent(in) :: this
    integer(i4), intent(in) :: node_id
    type(ValidRes), intent(out) :: result
    type(ErrorStatusType), intent(out), optional :: status

    class(*), pointer :: obj_ptr => null()
    integer(i4) :: node_type
    type(ErrorStatusType) :: local_status

    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    result%is_valid = .true.
    result%num_errors = 0_i4
    result%num_warnings = 0_i4

    obj_ptr => this%tree_mgr%GetNodeData(node_id, local_status)
    if (.not. associated(obj_ptr)) then
      result%is_valid = .false.
      result%num_errors = 1_i4
      allocate(result%errors(1))
      result%errors(1) = 'Node not found'
      if (present(status)) status = local_status
      return
    end if

    node_type = 0_i4
    select type (obj => obj_ptr)
    type is (PartDesc)
      node_type = NODE_TYPE_PART
    type is (MD_Mat_Desc)
      node_type = NODE_TYPE_MATER
    type is (SectDesc)
      node_type = NODE_TYPE_SECTI
    type is (StepDesc)
      node_type = NODE_TYPE_STEP
    type is (MD_LdbcDesc)
      node_type = NODE_TYPE_LOADB
    end select

    select case (node_type)
    case (NODE_TYPE_PART)
      call this%ValidatePart(obj_ptr, result)
    case (NODE_TYPE_MATER)
      call this%ValidateMaterial(obj_ptr, result)
    case (NODE_TYPE_SECTI)
      call this%ValidateSection(obj_ptr, result)
    case (NODE_TYPE_STEP)
      call this%ValidateStep(obj_ptr, result)
    case (NODE_TYPE_LOADB)
      call this%ValidateLoadBC(obj_ptr, result)
    end select

    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine ValidMgr_ValidNode

  subroutine ValidMgr_ChkDep(this, model_tree, result)
    class(ValidMgr), intent(in) :: this
    type(ModelTree), intent(in) :: model_tree
    type(ValidRes), intent(inout) :: result

    integer(i4) :: i, j
    class(*), pointer :: section_ptr => null()
    integer(i4), allocatable :: section_ids(:)
    type(ErrorStatusType) :: local_status, local_status2
    integer(i4), allocatable :: loadbc_ids(:), part_ids(:)
    class(*), pointer :: loadbc_ptr => null(), part_ptr => null()
    type(MD_LdbcDesc), pointer :: loadbc => null()
    type(PartTree), pointer :: part_tree => null()
    class(*), pointer :: set_ptr => null()
    logical :: region_found
    character(len=512) :: msg

    call init_error_status(local_status)
    call init_error_status(local_status2)

    if (model_tree%sections%GetCount() > 0_i4) then
      call model_tree%sections%GetAllIDs(section_ids, local_status2)
      if (allocated(section_ids) .and. local_status2%status_code == IF_STATUS_OK) then
        do i = 1, size(section_ids)
          section_ptr => model_tree%GetSection(id=section_ids(i))
          if (associated(section_ptr)) then
            call this%ValidateSection(section_ptr, result)
          end if
        end do
      end if
    end if

    call model_tree%loadbcs%GetAllIDs(loadbc_ids, local_status)
    if (allocated(loadbc_ids)) then
      do i = 1, size(loadbc_ids)
        loadbc_ptr => model_tree%GetLoadBC(id=loadbc_ids(i))
        if (associated(loadbc_ptr)) then
          select type (lb => loadbc_ptr)
          type is (MD_LdbcDesc)
            loadbc => lb
            if (len_trim(loadbc%region) > 0) then
              region_found = .false.
              call model_tree%parts%GetAllIDs(part_ids, local_status)
              if (allocated(part_ids)) then
                do j = 1, size(part_ids)
                  part_ptr => model_tree%GetPart(id=part_ids(j))
                  if (associated(part_ptr)) then
                    select type (pt => part_ptr)
                    type is (PartTree)
                      part_tree => pt
                      set_ptr => part_tree%GetNodeSet(name=loadbc%region)
                      if (associated(set_ptr)) region_found = .true.
                      if (.not. region_found) then
                        set_ptr => part_tree%GetElemSet(name=loadbc%region)
                        if (associated(set_ptr)) region_found = .true.
                      end if
                      if (.not. region_found) then
                        set_ptr => part_tree%GetSurface(name=loadbc%region)
                        if (associated(set_ptr)) region_found = .true.
                      end if
                    end select
                  end if
                end do
              end if
              if (.not. region_found) then
                msg = 'LoadBC '//trim(loadbc%name)//' references non-existent region: '//trim(loadbc%region)
                call AddError(result, trim(msg))
              end if
            end if
          end select
        end if
      end do
    end if
  end subroutine ValidMgr_ChkDep

  function ValidMgr_GetRpt(this, result) result(report)
    class(ValidMgr), intent(in) :: this
    type(ValidRes), intent(in) :: result
    character(len=:), allocatable :: report

    integer(i4) :: i
    character(len=1024) :: line

    report = 'Validation Report' // new_line('A')
    report = report // '================' // new_line('A') // new_line('A')
    if (result%is_valid) then
      report = report // 'Status: VALID' // new_line('A')
    else
      report = report // 'Status: INVALID' // new_line('A')
    end if
    report = report // new_line('A')
    write(line, '(A,I0)') 'Errors: ', result%num_errors
    report = report // trim(line) // new_line('A')
    if (result%num_errors > 0_i4) then
      do i = 1, result%num_errors
        report = report // '  ERROR: ' // trim(result%errors(i)) // new_line('A')
      end do
    end if
    report = report // new_line('A')
    write(line, '(A,I0)') 'Warnings: ', result%num_warnings
    report = report // trim(line) // new_line('A')
    if (result%num_warnings > 0_i4) then
      do i = 1, result%num_warnings
        report = report // '  WARNING: ' // trim(result%warnings(i)) // new_line('A')
      end do
    end if
  end function ValidMgr_GetRpt

  subroutine ValidMgr_ValidatePart(this, obj_ptr, result)
    class(ValidMgr), intent(in) :: this
    class(*), pointer, intent(in) :: obj_ptr
    type(ValidRes), intent(inout) :: result

    type(PartDesc), pointer :: part => null()
    type(PartTree), pointer :: part_tree => null()
    character(len=256) :: msg

    select type (obj => obj_ptr)
    type is (PartDesc)
      part => obj
      if (len_trim(part%name) == 0) call AddError(result, 'Part name is empty')
      if (part%nNodes <= 0) call AddWarning(result, 'Part has no nodes')
      if (part%nElems <= 0) call AddWarning(result, 'Part has no elements')
      select type (pt => obj_ptr)
      type is (PartTree)
        part_tree => pt
        if (part_tree%tree_initialize) then
          if (part_tree%nodes%GetCount() /= part%nNodes) then
            write(msg, '(A,I0,A,I0)') 'Part node count mismatch: declared=', part%nNodes, ', actual=', part_tree%nodes%GetCount()
            call AddWarning(result, trim(msg))
          end if
          if (part_tree%elements%GetCount() /= part%nElems) then
            write(msg, '(A,I0,A,I0)') 'Part element count mismatch: declared=', part%nElems, ', actual=', part_tree%elements%GetCount()
            call AddWarning(result, trim(msg))
          end if
        end if
      end select
    class default
      call AddError(result, 'Invalid object type for Part validation')
    end select
  end subroutine ValidMgr_ValidatePart

  subroutine ValidMgr_ValidateMaterial(this, obj_ptr, result)
    class(ValidMgr), intent(in) :: this
    class(*), pointer, intent(in) :: obj_ptr
    type(ValidRes), intent(inout) :: result

    type(MD_Mat_Desc), pointer :: Mat => null()
    character(len=256) :: msg
    logical :: is_valid_type

    select type (obj => obj_ptr)
    type is (MD_Mat_Desc)
      Mat => obj
      if (len_trim(Mat%name) == 0) call AddError(result, 'Mat name is empty')
      is_valid_type = .false.
      select case (trim(Mat%cfg%materialType))
      case ('ELASTIC', 'PLASTIC', 'DAMAGE', 'HYPERELASTIC', 'VISCOELASTIC', 'CREEP', 'USER')
        is_valid_type = .true.
      case default
        if (len_trim(Mat%cfg%materialType) > 0) then
          write(msg, '(A,A,A)') 'Unknown Mat type: ', trim(Mat%cfg%materialType)
          call AddWarning(result, trim(msg))
        else
          call AddWarning(result, 'Mat type is not specified')
        end if
      end select
      if (allocated(Mat%props)) then
        select case (trim(Mat%cfg%materialType))
        case ('ELASTIC', 'PLASTIC')
          if (size(Mat%props) >= 1) then
            if (Mat%props(1) <= 0.0_wp) call AddError(result, 'Young''s Modulus must be positive')
          else
            call AddError(result, 'Mat missing Young''s Modulus')
          end if
          if (size(Mat%props) >= 2) then
            if (Mat%props(2) < 0.0_wp .or. Mat%props(2) >= 0.5_wp) then
              write(msg, '(A,ES10.3)') 'Poisson''s Ratio out of range [0, 0.5): ', Mat%props(2)
              call AddError(result, trim(msg))
            end if
          else
            call AddError(result, 'Mat missing Poisson''s Ratio')
          end if
          if (trim(Mat%cfg%materialType) == 'PLASTIC') then
            if (size(Mat%props) >= 3) then
              if (Mat%props(3) < 0.0_wp) call AddError(result, 'Yield Stress must be non-negative')
            else
              call AddWarning(result, 'Plastic Mat missing Yield Stress')
            end if
          end if
        case ('HYPERELASTIC')
          if (size(Mat%props) < 2) call AddError(result, 'Hyperelastic Mat needs at least 2 parameters')
        case default
          if (size(Mat%props) == 0) call AddWarning(result, 'Mat has no properties defined')
        end select
        if (size(Mat%props) >= 10) then
          if (Mat%props(10) <= 0.0_wp) call AddError(result, 'Density must be positive')
        end if
      else
        call AddError(result, 'Mat has no properties defined')
      end if
    class default
      call AddError(result, 'Invalid object type for Mat validation')
    end select
  end subroutine ValidMgr_ValidateMaterial

  subroutine ValidMgr_ValidateSection(this, obj_ptr, result)
    class(ValidMgr), intent(in) :: this
    class(*), pointer, intent(in) :: obj_ptr
    type(ValidRes), intent(inout) :: result

    type(SectDesc), pointer :: section => null()
    class(TreeNodeBase), pointer :: material_ptr => null()
    character(len=256) :: msg
    type(ModelTree), pointer :: model_tree => null()

    select type (obj => obj_ptr)
    type is (SectDesc)
      section => obj
      if (len_trim(section%name) == 0) call AddError(result, 'Section name is empty')
      select case (trim(section%sectionType))
      case ('SOLID', 'SHELL', 'BEAM')
      case default
        if (len_trim(section%sectionType) > 0) then
          write(msg, '(A,A,A)') 'Unknown section type: ', trim(section%sectionType)
          call AddWarning(result, trim(msg))
        else
          call AddWarning(result, 'Section type is not specified')
        end if
      end select
      select type (s => section)
      type is (SolidSectDesc)
        if (len_trim(s%materialName) > 0) then
          if (associated(this%tree_mgr)) then
            model_tree => this%tree_mgr%model_tree
            if (associated(model_tree)) then
              material_ptr => model_tree%GetMaterial(name=s%materialName)
              if (.not. associated(material_ptr)) then
                write(msg, '(A,A,A)') 'Mat not found: ', trim(s%materialName)
                call AddError(result, trim(msg))
              end if
            end if
          end if
        else
          call AddError(result, 'Section missing Mat reference')
        end if
      type is (ShellSectDesc)
        if (len_trim(s%materialName) > 0) then
          if (associated(this%tree_mgr)) then
            model_tree => this%tree_mgr%model_tree
            if (associated(model_tree)) then
              material_ptr => model_tree%GetMaterial(name=s%materialName)
              if (.not. associated(material_ptr)) then
                write(msg, '(A,A,A)') 'Mat not found: ', trim(s%materialName)
                call AddError(result, trim(msg))
              end if
            end if
          end if
        else
          call AddError(result, 'Section missing Mat reference')
        end if
        if (s%thickness <= 0.0_wp) call AddError(result, 'Shell section thickness must be positive')
      type is (BeamSectDesc)
        if (len_trim(s%materialName) > 0) then
          if (associated(this%tree_mgr)) then
            model_tree => this%tree_mgr%model_tree
            if (associated(model_tree)) then
              material_ptr => model_tree%GetMaterial(name=s%materialName)
              if (.not. associated(material_ptr)) then
                write(msg, '(A,A,A)') 'Mat not found: ', trim(s%materialName)
                call AddError(result, trim(msg))
              end if
            end if
          end if
        else
          call AddError(result, 'Section missing Mat reference')
        end if
        if (s%area <= 0.0_wp) call AddError(result, 'Beam section area must be positive')
        if (s%I11 <= 0.0_wp) call AddError(result, 'Beam section I11 must be positive')
        if (s%I22 <= 0.0_wp) call AddError(result, 'Beam section I22 must be positive')
      class default
      end select
    class default
      call AddError(result, 'Invalid object type for Section validation')
    end select
  end subroutine ValidMgr_ValidateSection

  subroutine ValidMgr_ValidateStep(this, obj_ptr, result)
    class(ValidMgr), intent(in) :: this
    class(*), pointer, intent(in) :: obj_ptr
    type(ValidRes), intent(inout) :: result

    type(StepDesc), pointer :: step => null()
    class(TreeNodeBase), pointer :: loadbc_ptr => null(), interaction_ptr => null()
    type(ModelTree), pointer :: model_tree => null()
    character(len=256) :: msg
    integer(i4) :: i

    select type (obj => obj_ptr)
    type is (StepDesc)
      step => obj
      if (len_trim(step%name) == 0) call AddError(result, 'Step name is empty')
      select case (trim(step%stepType))
      case ('STATIC', 'DYNAMIC', 'FREQUENCY', 'BUCKLE', 'STATIC_GENERAL', 'DYNAMIC_EXPLICIT', 'DYNAMIC_IMPLICIT', 'FREQUENCY_EXTRACTION', 'BUCKLE_EIGENVALUE')
      case default
        if (len_trim(step%stepType) > 0) then
          write(msg, '(A,A,A)') 'Unknown step type: ', trim(step%stepType)
          call AddWarning(result, trim(msg))
        else
          call AddWarning(result, 'Step type is not specified')
        end if
      end select
      if (step%totalTime <= 0.0_wp) call AddError(result, 'Step total time must be positive')
      if (step%dtInit <= 0.0_wp) call AddError(result, 'Step initial time increment must be positive')
      if (step%dtMin <= 0.0_wp) call AddError(result, 'Step minimum time increment must be positive')
      if (step%dtMax < step%dtMin) then
        write(msg, '(A,ES10.3,A,ES10.3,A)') 'Step max time increment (', step%dtMax, ') < min (', step%dtMin, ')'
        call AddError(result, trim(msg))
      end if
      if (step%dtInit < step%dtMin .or. step%dtInit > step%dtMax) then
        write(msg, '(A,ES10.3)') 'Step initial time increment out of range'
        call AddWarning(result, trim(msg))
      end if
      if (step%nIncs <= 0) call AddWarning(result, 'Step has no increments specified')
      if (associated(this%tree_mgr)) then
        model_tree => this%tree_mgr%model_tree
        if (associated(model_tree)) then
          if (allocated(step%loadIds)) then
            do i = 1, size(step%loadIds)
              loadbc_ptr => model_tree%GetLoadBC(id=step%loadIds(i))
              if (.not. associated(loadbc_ptr)) then
                write(msg, '(A,I0)') 'LoadBC not found: ', step%loadIds(i)
                call AddError(result, trim(msg))
              end if
            end do
          end if
          if (allocated(step%bcIds)) then
            do i = 1, size(step%bcIds)
              loadbc_ptr => model_tree%GetLoadBC(id=step%bcIds(i))
              if (.not. associated(loadbc_ptr)) then
                write(msg, '(A,I0)') 'Boundary condition not found: ', step%bcIds(i)
                call AddError(result, trim(msg))
              end if
            end do
          end if
          if (allocated(step%interactionIds)) then
            do i = 1, size(step%interactionIds)
              interaction_ptr => model_tree%GetInteraction(id=step%interactionIds(i))
              if (.not. associated(interaction_ptr)) then
                write(msg, '(A,I0)') 'Interaction not found: ', step%interactionIds(i)
                call AddError(result, trim(msg))
              end if
            end do
          end if
        end if
      end if
    class default
      call AddError(result, 'Invalid object type for Step validation')
    end select
  end subroutine ValidMgr_ValidateStep

  subroutine ValidMgr_ValidateLoadBC(this, obj_ptr, result)
    class(ValidMgr), intent(in) :: this
    class(*), pointer, intent(in) :: obj_ptr
    type(ValidRes), intent(inout) :: result

    type(MD_LdbcDesc), pointer :: loadbc => null()
    type(ModelTree), pointer :: model_tree => null()
    class(*), pointer :: part_ptr => null(), set_ptr => null()
    type(PartTree), pointer :: part_tree => null()
    integer(i4) :: i, n_parts
    integer(i4), allocatable :: part_ids(:)
    character(len=256) :: msg
    logical :: region_found
    type(ErrorStatusType) :: local_status

    select type (obj => obj_ptr)
    type is (MD_LdbcDesc)
      loadbc => obj
      if (len_trim(loadbc%name) == 0) call AddError(result, 'LoadBC name is empty')
      select case (trim(loadbc%loadBCType))
      case ('DISPLACEMENT', 'BOUNDARY', 'FIXED', 'FORCE', 'CONCENTRATED_FORCE', 'CLOAD', 'PRESSURE', 'distributed_loa', 'DLOAD', 'BODY_FORCE', 'GRAVITY')
      case default
        if (len_trim(loadbc%loadBCType) > 0) then
          write(msg, '(A,A,A)') 'Unknown LoadBC type: ', trim(loadbc%loadBCType)
          call AddWarning(result, trim(msg))
        else
          call AddWarning(result, 'LoadBC type is not specified')
        end if
      end select
      if (len_trim(loadbc%region) > 0) then
        region_found = .false.
        if (associated(this%tree_mgr)) then
          model_tree => this%tree_mgr%model_tree
          if (associated(model_tree)) then
            call model_tree%parts%GetAllIDs(part_ids, local_status)
            if (allocated(part_ids)) then
              do i = 1, size(part_ids)
                part_ptr => model_tree%GetPart(id=part_ids(i))
                if (associated(part_ptr)) then
                  select type (pt => part_ptr)
                  type is (PartTree)
                    part_tree => pt
                    set_ptr => part_tree%GetNodeSet(name=loadbc%region)
                    if (associated(set_ptr)) region_found = .true.
                    if (.not. region_found) then
                      set_ptr => part_tree%GetElemSet(name=loadbc%region)
                      if (associated(set_ptr)) region_found = .true.
                    end if
                    if (.not. region_found) then
                      set_ptr => part_tree%GetSurface(name=loadbc%region)
                      if (associated(set_ptr)) region_found = .true.
                    end if
                  end select
                end if
              end do
            end if
          end if
        end if
        if (.not. region_found) then
          write(msg, '(A,A,A)') 'LoadBC region not found: ', trim(loadbc%region)
          call AddError(result, trim(msg))
        end if
      else
        call AddWarning(result, 'LoadBC region is not specified')
      end if
      if (allocated(loadbc%dofs)) then
        do i = 1, size(loadbc%dofs)
          if (loadbc%dofs(i) < 1 .or. loadbc%dofs(i) > 6) then
            write(msg, '(A,I0)') 'Invalid DOF number: ', loadbc%dofs(i)
            call AddError(result, trim(msg))
          end if
        end do
      end if
    class default
      call AddError(result, 'Invalid object type for LoadBC validation')
    end select
  end subroutine ValidMgr_ValidateLoadBC

  subroutine AddError(result, error_msg)
    type(ValidRes), intent(inout) :: result
    character(len=*), intent(in) :: error_msg

    integer(i4) :: n
    character(len=256), allocatable :: tmp_errors(:)

    n = result%num_errors + 1_i4
    if (allocated(result%errors)) then
      allocate(tmp_errors(n))
      tmp_errors(1:result%num_errors) = result%errors
      tmp_errors(n) = error_msg
      call move_alloc(tmp_errors, result%errors)
    else
      allocate(result%errors(1))
      result%errors(1) = error_msg
    end if
    result%num_errors = n
    result%is_valid = .false.
  end subroutine AddError

  subroutine AddWarning(result, warning_msg)
    type(ValidRes), intent(inout) :: result
    character(len=*), intent(in) :: warning_msg

    integer(i4) :: n
    character(len=256), allocatable :: tmp_warnings(:)

    n = result%num_warnings + 1_i4
    if (allocated(result%warnings)) then
      allocate(tmp_warnings(n))
      tmp_warnings(1:result%num_warnings) = result%warnings
      tmp_warnings(n) = warning_msg
      call move_alloc(tmp_warnings, result%warnings)
    else
      allocate(result%warnings(1))
      result%warnings(1) = warning_msg
    end if
    result%num_warnings = n
  end subroutine AddWarning

  !=============================================================================
  ! PropertyMgr procedures
  !=============================================================================

  subroutine PropertyMgr_Init(this, tree_mgr, status)
    class(PropertyMgr), intent(inout) :: this
    type(TreeMgr), intent(in), target :: tree_mgr
    type(ErrorStatusType), intent(out), optional :: status

    if (present(status)) call init_error_status(status)
    this%tree_mgr => tree_mgr
    allocate(this%forms(10))
    call this%CreateFormForNodeType(NODE_TYPE_PART, this%forms(1))
    call this%CreateFormForNodeType(NODE_TYPE_MATER, this%forms(2))
    call this%CreateFormForNodeType(NODE_TYPE_SECTI, this%forms(3))
    call this%CreateFormForNodeType(NODE_TYPE_STEP, this%forms(4))
    call this%CreateFormForNodeType(NODE_TYPE_LOADB, this%forms(5))
    call this%CreateFormForNodeType(NODE_TYPE_INTER, this%forms(6))
    this%init = .true.
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine PropertyMgr_Init

  function PropertyMgr_GetForm(this, node_type) result(form)
    class(PropertyMgr), intent(in) :: this
    integer(i4), intent(in) :: node_type
    type(PropertyForm), pointer :: form

    integer(i4) :: i

    nullify(form)
    if (.not. this%init) return
    do i = 1, size(this%forms)
      if (this%forms(i)%node_type == node_type) then
        form => this%forms(i)
        return
      end if
    end do
  end function PropertyMgr_GetForm

  function PropertyMgr_GetFieldValue(this, node_id, field_name) result(value)
    class(PropertyMgr), intent(in) :: this
    integer(i4), intent(in) :: node_id
    character(len=*), intent(in) :: field_name
    character(len=256) :: value

    class(*), pointer :: obj_ptr => null()
    type(ErrorStatusType) :: status

    value = ''
    obj_ptr => this%tree_mgr%GetNodeData(node_id, status)
    if (.not. associated(obj_ptr)) return

    select type (obj => obj_ptr)
    type is (PartDesc)
      select case (trim(field_name))
      case ('name')
        value = trim(obj%name)
      case ('nNodes')
        write(value, '(I0)') obj%nNodes
      case ('nElems')
        write(value, '(I0)') obj%nElems
      end select
    type is (MD_Mat_Desc)
      select case (trim(field_name))
      case ('name')
        value = trim(obj%name)
      case ('materialType')
        value = trim(obj%cfg%materialType)
      case ('youngsModulus', 'E')
        if (allocated(obj%props) .and. size(obj%props) >= 1) write(value, '(ES15.8)') obj%props(1)
      case ('poissonsRatio', 'nu')
        if (allocated(obj%props) .and. size(obj%props) >= 2) write(value, '(ES15.8)') obj%props(2)
      case ('density', 'rho')
        if (allocated(obj%props) .and. size(obj%props) >= 10) write(value, '(ES15.8)') obj%props(10)
      end select
    type is (SectDesc)
      select case (trim(field_name))
      case ('name')
        value = trim(obj%name)
      case ('sectionType')
        value = trim(obj%sectionType)
      end select
    type is (StepDesc)
      select case (trim(field_name))
      case ('name')
        value = trim(obj%name)
      case ('stepType')
        value = trim(obj%stepType)
      case ('totalTime')
        write(value, '(ES15.8)') obj%totalTime
      case ('nIncs')
        write(value, '(I0)') obj%nIncs
      end select
    type is (MD_LdbcDesc)
      select case (trim(field_name))
      case ('name')
        value = trim(obj%name)
      case ('loadBCType')
        value = trim(obj%loadBCType)
      case ('value')
        write(value, '(ES15.8)') obj%value
      case ('region')
        value = trim(obj%region)
      end select
    type is (MD_InterDesc)
      select case (trim(field_name))
      case ('name')
        value = trim(obj%name)
      case ('interactionType')
        value = trim(obj%interactionType)
      end select
    end select
  end function PropertyMgr_GetFieldValue

  subroutine PropertyMgr_SetFieldValue(this, node_id, field_name, value, status)
    class(PropertyMgr), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    character(len=*), intent(in) :: field_name, value
    type(ErrorStatusType), intent(out), optional :: status

    class(*), pointer :: obj_ptr => null()
    type(ErrorStatusType) :: local_status

    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    obj_ptr => this%tree_mgr%GetNodeData(node_id, local_status)
    if (.not. associated(obj_ptr)) then
      if (present(status)) status = local_status
      return
    end if

    select type (obj => obj_ptr)
    type is (PartDesc)
      select case (trim(field_name))
      case ('name')
        obj%name = trim(value)
      end select
    type is (MD_Mat_Desc)
      select case (trim(field_name))
      case ('name')
        obj%name = trim(value)
      case ('materialType')
        obj%cfg%materialType = trim(value)
      case ('youngsModulus', 'E')
        if (.not. allocated(obj%props)) allocate(obj%props(12))
        if (size(obj%props) >= 1) read(value, *) obj%props(1)
      case ('poissonsRatio', 'nu')
        if (.not. allocated(obj%props)) allocate(obj%props(12))
        if (size(obj%props) >= 2) read(value, *) obj%props(2)
      case ('density', 'rho')
        if (.not. allocated(obj%props)) allocate(obj%props(12))
        if (size(obj%props) >= 10) read(value, *) obj%props(10)
      end select
    type is (SectDesc)
      select case (trim(field_name))
      case ('name')
        obj%name = trim(value)
      case ('sectionType')
        obj%sectionType = trim(value)
      end select
    type is (StepDesc)
      select case (trim(field_name))
      case ('name')
        obj%name = trim(value)
      case ('stepType')
        obj%stepType = trim(value)
      case ('totalTime')
        read(value, *) obj%totalTime
      case ('nIncs')
        read(value, *) obj%nIncs
      end select
    type is (MD_LdbcDesc)
      select case (trim(field_name))
      case ('name')
        obj%name = trim(value)
      case ('loadBCType')
        obj%loadBCType = trim(value)
      case ('value')
        read(value, *) obj%value
      case ('region')
        obj%region = trim(value)
      end select
    type is (MD_InterDesc)
      select case (trim(field_name))
      case ('name')
        obj%name = trim(value)
      case ('interactionType')
        obj%interactionType = trim(value)
      end select
    end select
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine PropertyMgr_SetFieldValue

  function PropertyMgr_ValidateForm(this, node_id, form) result(is_valid)
    class(PropertyMgr), intent(in) :: this
    integer(i4), intent(in) :: node_id
    type(PropertyForm), intent(in) :: form
    logical :: is_valid

    integer(i4) :: i
    character(len=256) :: value

    is_valid = .true.
    do i = 1, form%num_fields
      if (form%fields(i)%is_required) then
        value = this%GetFieldValue(node_id, form%fields(i)%field_name)
        if (len_trim(value) == 0_i4) then
          is_valid = .false.
          return
        end if
      end if
      if (len_trim(form%fields(i)%validation_rule) > 0_i4) then
        character(len=256) :: rule, val_str
        real(wp) :: val_real
        integer(i4) :: val_int, ios
        logical :: rule_passed
        rule = trim(form%fields(i)%validation_rule)
        val_str = trim(form%fields(i)%current_value)
        rule_passed = .true.
        select case (form%fields(i)%field_type)
        case (FIELD_TYPE_REAL)
          read(val_str, *, iostat=ios) val_real
          if (ios == 0_i4) then
            if (index(rule, '>0') > 0) rule_passed = (val_real > 0.0_wp)
            if (index(rule, '>=0') > 0) rule_passed = (val_real >= 0.0_wp)
            if (index(rule, '<0') > 0) rule_passed = (val_real < 0.0_wp)
            if (index(rule, '<=0') > 0) rule_passed = (val_real <= 0.0_wp)
            if (.not. rule_passed) then
              is_valid = .false.
              return
            end if
          end if
        case (FIELD_TYPE_INT)
          read(val_str, *, iostat=ios) val_int
          if (ios == 0_i4) then
            if (index(rule, '>0') > 0) rule_passed = (val_int > 0_i4)
            if (index(rule, '>=0') > 0) rule_passed = (val_int >= 0_i4)
            if (.not. rule_passed) then
              is_valid = .false.
              return
            end if
          end if
        case default
        end select
      end if
    end do
  end function PropertyMgr_ValidateForm

  subroutine PropertyMgr_ApplyChanges(this, node_id, form, status)
    class(PropertyMgr), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    type(PropertyForm), intent(in) :: form
    type(ErrorStatusType), intent(out), optional :: status

    integer(i4) :: i

    if (present(status)) call init_error_status(status)
    if (.not. this%ValidateForm(node_id, form)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Form validation failed'
      end if
      return
    end if
    do i = 1, form%num_fields
      call this%SetFieldValue(node_id, form%fields(i)%field_name, form%fields(i)%current_value, status)
      if (present(status) .and. status%status_code /= IF_STATUS_OK) return
    end do
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine PropertyMgr_ApplyChanges

  subroutine PropMgr_CreateFormForNodeType(this, node_type, form)
    class(PropertyMgr), intent(in) :: this
    integer(i4), intent(in) :: node_type
    type(PropertyForm), intent(out) :: form

    integer(i4) :: n_fields, i
    integer(i4), allocatable :: material_ids(:), part_ids(:), elemset_ids(:)
    type(ErrorStatusType) :: local_status
    class(*), pointer :: material_ptr => null(), part_ptr => null(), set_ptr => null()
    type(MD_Mat_Desc), pointer :: Mat => null()
    type(PartTree), pointer :: part_tree => null()
    type(PartElemSetDesc), pointer :: elemset => null()
    integer(i4) :: n_materials, j, k
    character(len=64), allocatable :: set_names(:)
    integer(i4) :: set_count

    form%node_type = node_type

    select case (node_type)
    case (NODE_TYPE_PART)
      form%form_name = 'PartForm'
      form%form_title = 'Part Properties'
      n_fields = 5_i4
      allocate(form%fields(n_fields))
      i = 1
      form%fields(i)%field_name = 'name'
      form%fields(i)%display_name = 'Name'
      form%fields(i)%field_type = FIELD_TYPE_TEXT
      form%fields(i)%is_required = .true.
      i = 2
      form%fields(i)%field_name = 'dimensionality'
      form%fields(i)%display_name = 'Dimensionality'
      form%fields(i)%field_type = FIELD_TYPE_CHOICE
      form%fields(i)%is_required = .true.
      allocate(form%fields(i)%choices(2))
      form%fields(i)%choices(1) = '2D'
      form%fields(i)%choices(2) = '3D'
      form%fields(i)%num_choices = 2_i4
      i = 3
      form%fields(i)%field_name = 'ElemType'
      form%fields(i)%display_name = 'Element Type'
      form%fields(i)%field_type = FIELD_TYPE_CHOICE
      form%fields(i)%is_required = .true.
      allocate(form%fields(i)%choices(5))
      form%fields(i)%choices(1) = 'C3D8'
      form%fields(i)%choices(2) = 'C3D20'
      form%fields(i)%choices(3) = 'S4'
      form%fields(i)%choices(4) = 'B31'
      form%fields(i)%choices(5) = 'T3D2'
      form%fields(i)%num_choices = 5_i4
      i = 4
      form%fields(i)%field_name = 'description'
      form%fields(i)%display_name = 'Description'
      form%fields(i)%field_type = FIELD_TYPE_MULTI
      form%fields(i)%is_required = .false.
      i = 5
      form%fields(i)%field_name = 'nNodes'
      form%fields(i)%display_name = 'Number of Nodes'
      form%fields(i)%field_type = FIELD_TYPE_INT
      form%fields(i)%is_readonly = .true.
      form%num_fields = n_fields

    case (NODE_TYPE_MATER)
      form%form_name = 'MatForm'
      form%form_title = 'Mat Properties'
      n_fields = 6_i4
      allocate(form%fields(n_fields))
      i = 1
      form%fields(i)%field_name = 'name'
      form%fields(i)%display_name = 'Name'
      form%fields(i)%field_type = FIELD_TYPE_TEXT
      form%fields(i)%is_required = .true.
      i = 2
      form%fields(i)%field_name = 'materialType'
      form%fields(i)%display_name = 'Mat Type'
      form%fields(i)%field_type = FIELD_TYPE_CHOICE
      form%fields(i)%is_required = .true.
      allocate(form%fields(i)%choices(4))
      form%fields(i)%choices(1) = 'ELASTIC'
      form%fields(i)%choices(2) = 'PLASTIC'
      form%fields(i)%choices(3) = 'DAMAGE'
      form%fields(i)%choices(4) = 'HYPERELASTIC'
      form%fields(i)%num_choices = 4_i4
      i = 3
      form%fields(i)%field_name = 'youngsModulus'
      form%fields(i)%display_name = "Young's Modulus (E)"
      form%fields(i)%field_type = FIELD_TYPE_REAL
      form%fields(i)%is_required = .true.
      form%fields(i)%validation_rule = '>0'
      i = 4
      form%fields(i)%field_name = 'poissonsRatio'
      form%fields(i)%display_name = "Poisson's Ratio"
      form%fields(i)%field_type = FIELD_TYPE_REAL
      form%fields(i)%is_required = .true.
      form%fields(i)%validation_rule = '0<value<0.5'
      i = 5
      form%fields(i)%field_name = 'density'
      form%fields(i)%display_name = 'Density'
      form%fields(i)%field_type = FIELD_TYPE_REAL
      form%fields(i)%is_required = .false.
      form%fields(i)%validation_rule = '>=0'
      i = 6
      form%fields(i)%field_name = 'description'
      form%fields(i)%display_name = 'Description'
      form%fields(i)%field_type = FIELD_TYPE_MULTI
      form%fields(i)%is_required = .false.
      form%num_fields = n_fields

    case (NODE_TYPE_SECTI)
      form%form_name = 'SectForm'
      form%form_title = 'Section Properties'
      n_fields = 4_i4
      allocate(form%fields(n_fields))
      i = 1
      form%fields(i)%field_name = 'name'
      form%fields(i)%display_name = 'Name'
      form%fields(i)%field_type = FIELD_TYPE_TEXT
      form%fields(i)%is_required = .true.
      i = 2
      form%fields(i)%field_name = 'sectionType'
      form%fields(i)%display_name = 'Section Type'
      form%fields(i)%field_type = FIELD_TYPE_CHOICE
      form%fields(i)%is_required = .true.
      allocate(form%fields(i)%choices(3))
      form%fields(i)%choices(1) = 'SOLID'
      form%fields(i)%choices(2) = 'SHELL'
      form%fields(i)%choices(3) = 'BEAM'
      form%fields(i)%num_choices = 3_i4
      i = 3
      form%fields(i)%field_name = 'Mat'
      form%fields(i)%display_name = 'Mat'
      form%fields(i)%field_type = FIELD_TYPE_CHOICE
      form%fields(i)%is_required = .true.
      if (associated(this%tree_mgr) .and. associated(this%tree_mgr%model_tree)) then
        call this%tree_mgr%model_tree%materials%GetAllIDs(material_ids, local_status)
        if (allocated(material_ids)) then
          n_materials = size(material_ids)
          allocate(form%fields(i)%choices(n_materials))
          form%fields(i)%num_choices = n_materials
          do j = 1, n_materials
            material_ptr => this%tree_mgr%model_tree%GetMaterial(id=material_ids(j))
            if (associated(material_ptr)) then
              select type (m => material_ptr)
              type is (MD_Mat_Desc)
                Mat => m
                form%fields(i)%choices(j) = trim(Mat%name)
              end select
            end if
          end do
        else
          allocate(form%fields(i)%choices(0))
          form%fields(i)%num_choices = 0_i4
        end if
      else
        allocate(form%fields(i)%choices(0))
        form%fields(i)%num_choices = 0_i4
      end if
      i = 4
      form%fields(i)%field_name = 'elemSet'
      form%fields(i)%display_name = 'Element Set'
      form%fields(i)%field_type = FIELD_TYPE_CHOICE
      form%fields(i)%is_required = .true.
      if (associated(this%tree_mgr) .and. associated(this%tree_mgr%model_tree)) then
        call init_error_status(local_status)
        set_count = 0_i4
        allocate(set_names(1000))
        call this%tree_mgr%model_tree%parts%GetAllIDs(part_ids, local_status)
        if (allocated(part_ids)) then
          do j = 1, size(part_ids)
            part_ptr => this%tree_mgr%model_tree%GetPart(id=part_ids(j))
            if (associated(part_ptr)) then
              select type (pt => part_ptr)
              type is (PartTree)
                part_tree => pt
                if (part_tree%tree_initialize) then
                  call part_tree%elemsets%GetAllIDs(elemset_ids, local_status)
                  if (allocated(elemset_ids)) then
                    do k = 1, size(elemset_ids)
                      set_ptr => part_tree%GetElemSet(id=elemset_ids(k))
                      if (associated(set_ptr)) then
                        select type (es => set_ptr)
                        type is (PartElemSetDesc)
                          elemset => es
                          set_count = set_count + 1_i4
                          if (set_count <= size(set_names)) set_names(set_count) = trim(elemset%name)
                        end select
                      end if
                    end do
                  end if
                end if
              end select
            end if
          end do
        end if
        if (set_count > 0_i4) then
          allocate(form%fields(i)%choices(set_count))
          form%fields(i)%num_choices = set_count
          do j = 1, set_count
            form%fields(i)%choices(j) = trim(set_names(j))
          end do
          deallocate(set_names)
        else
          allocate(form%fields(i)%choices(0))
          form%fields(i)%num_choices = 0_i4
          if (allocated(set_names)) deallocate(set_names)
        end if
      else
        allocate(form%fields(i)%choices(0))
        form%fields(i)%num_choices = 0_i4
      end if
      form%num_fields = n_fields

    case (NODE_TYPE_STEP)
      form%form_name = 'StepForm'
      form%form_title = 'Step Properties'
      n_fields = 6_i4
      allocate(form%fields(n_fields))
      i = 1
      form%fields(i)%field_name = 'name'
      form%fields(i)%display_name = 'Name'
      form%fields(i)%field_type = FIELD_TYPE_TEXT
      form%fields(i)%is_required = .true.
      i = 2
      form%fields(i)%field_name = 'stepType'
      form%fields(i)%display_name = 'Step Type'
      form%fields(i)%field_type = FIELD_TYPE_CHOICE
      form%fields(i)%is_required = .true.
      allocate(form%fields(i)%choices(4))
      form%fields(i)%choices(1) = 'STATIC'
      form%fields(i)%choices(2) = 'DYNAMIC'
      form%fields(i)%choices(3) = 'FREQUENCY'
      form%fields(i)%choices(4) = 'BUCKLE'
      form%fields(i)%num_choices = 4_i4
      i = 3
      form%fields(i)%field_name = 'timePeriod'
      form%fields(i)%display_name = 'Time Period'
      form%fields(i)%field_type = FIELD_TYPE_REAL
      form%fields(i)%is_required = .true.
      form%fields(i)%validation_rule = '>0'
      i = 4
      form%fields(i)%field_name = 'maxIncrements'
      form%fields(i)%display_name = 'Max Increments'
      form%fields(i)%field_type = FIELD_TYPE_INT
      form%fields(i)%is_required = .true.
      form%fields(i)%validation_rule = '>0'
      i = 5
      form%fields(i)%field_name = 'initialIncrement'
      form%fields(i)%display_name = 'Initial Increment Size'
      form%fields(i)%field_type = FIELD_TYPE_REAL
      form%fields(i)%is_required = .false.
      form%fields(i)%validation_rule = '>0'
      i = 6
      form%fields(i)%field_name = 'description'
      form%fields(i)%display_name = 'Description'
      form%fields(i)%field_type = FIELD_TYPE_MULTI
      form%fields(i)%is_required = .false.
      form%num_fields = n_fields

    case default
      form%form_name = 'GenericForm'
      form%form_title = 'Properties'
      form%num_fields = 0_i4
    end select

  end subroutine PropMgr_CreateFormForNodeType

end module AP_UI_ModelMgr