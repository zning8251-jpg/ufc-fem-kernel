!===============================================================================
! MODULE: AP_UI_TreeMgr
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Mgr — model tree manager
! BRIEF:  Model tree operations and navigation for UI layer.
!===============================================================================

module AP_UI_TreeMgr
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  USE IF_Prec_Core, only: i4, wp
  USE MD_Base_TreeIndex, only: TreeNodeBase, NODE_TYPE_MODEL, NODE_TYPE_PART, &
                          NODE_TYPE_ASSEM, NODE_TYPE_MATER, &
                          NODE_TYPE_SECTI, NODE_TYPE_MESH, &
                          NODE_TYPE_AMPLI, NODE_TYPE_LOADB, &
                          NODE_TYPE_INTER, NODE_TYPE_STEP
  USE MD_Mat_Lib, only: MD_Mat_Desc
  USE MD_Model_Tree, only: ModelTree
  USE MD_Part_Mgr, only: PartDesc
  USE MD_Sect_Mgr, only: SectDesc
  USE MD_Step_Proc, only: StepDesc
  
  implicit none
  private
  
  public :: AP_UI_TreeMgr_Type
  public :: AP_UI_TreeMgr_CreateNode
  public :: AP_UI_TreeMgr_DeleteNode
  public :: AP_UI_TreeMgr_RenameNode
  public :: AP_UI_TreeMgr_GetNodeData
  public :: AP_UI_TreeMgr_SetNodeData
  public :: AP_UI_TreeMgr_GetChildren
  public :: AP_UI_TreeMgr_MoveNode
  public :: AP_UI_TreeMgr_GetNodePath
  public :: AP_UI_TreeMgr_FindNodeByName
  
  !=============================================================================
  !> @brief Tree manager type
  !! @details Manages model tree operations for UI layer
  !!   Theory: Tree operations: create, delete, rename, move, get/set data, find by name
  !=============================================================================
  type, public :: AP_UI_TreeMgr_Type
    type(ModelTree), pointer :: model_tree => null()  ! Model tree pointer
    LOGICAL :: init = .false.                          ! Initialization flag
  contains
    procedure, public :: Init => AP_UI_TreeMgr_Init
    procedure, public :: CreateNode => AP_UI_TreeMgr_CreateNode
    procedure, public :: DeleteNode => AP_UI_TreeMgr_DeleteNode
    procedure, public :: RenameNode => AP_UI_TreeMgr_RenameNode
    procedure, public :: GetNodeData => AP_UI_TreeMgr_GetNodeData
    procedure, public :: SetNodeData => AP_UI_TreeMgr_SetNodeData
    procedure, public :: GetChildren => AP_UI_TreeMgr_GetChildren
    procedure, public :: MoveNode => AP_UI_TreeMgr_MoveNode
    procedure, public :: GetNodePath => AP_UI_TreeMgr_GetNodePath
    procedure, public :: FindNodeByName => AP_UI_TreeMgr_FindNodeByName
    procedure, public :: ValidateNode => AP_UI_TreeMgr_ValidateNode
  end type AP_UI_TreeMgr_Type
  
  !=============================================================================
  !> @brief UI tree node type
  !! @details Tree node representation for UI display
  !!   Theory: Node with ID, parent ID, type, name, display properties, child IDs
  !=============================================================================
  type, public :: AP_UI_TreeNode
    integer(i4) :: node_id = 0_i4                      ! Node ID ??
    integer(i4) :: parent_id = 0_i4                     ! Parent node ID ??
    integer(i4) :: node_type = 0_i4                     ! Node type code ??
    character(len=64) :: name = ''                      ! Node name
    character(len=128) :: display_name = ''             ! Display name
    logical :: is_expanded = .false.                    ! Expanded flag
    logical :: is_selected = .false.                    ! Selected flag
    logical :: is_visible = .true.                      ! Visible flag
    integer(i4), allocatable :: child_ids(:)             ! Child node IDs ??^n_children
    class(*), pointer :: data_ptr => null()             ! Data pointer
  end type UITreeNode
  
contains
  
  !=============================================================================
  !> @brief Initialize tree manager (legacy interface)
  !! @details Sets up tree manager with model tree reference
  !! @param[inout] this Tree manager instance
  !! @param[in] model_tree Model tree reference
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine TreeMgr_Init(this, model_tree, status)
    class(TreeMgr), intent(inout) :: this
    type(ModelTree), intent(in), target :: model_tree
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    this%model_tree => model_tree
    this%init = .true.
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine TreeMgr_Init
  
  !=============================================================================
  !> @brief Create tree node (legacy interface)
  !! @details Creates a new node in the model tree
  !! @param[inout] this Tree manager instance
  !! @param[in] parent_id Parent node ID ??
  !! @param[in] node_type Node type code ??
  !! @param[in] name Node name
  !! @param[out] node_id Created node ID ??
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine TreeMgr_CreateNode(this, parent_id, node_type, name, node_id, status)
    class(TreeMgr), intent(inout) :: this
    integer(i4), intent(in) :: parent_id, node_type
    character(len=*), intent(in) :: name
    integer(i4), intent(out) :: node_id
    type(ErrorStatusType), intent(out), optional :: status
    
    type(ErrorStatusType) :: local_status
    class(*), pointer :: new_obj => null()
    
    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    
    if (.not. this%init) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'TreeMgr not initialized'
      end if
      return
    end if
    
    node_id = 0_i4
    
    ! Create object based on node type
    select case (node_type)
    case (NODE_TYPE_PART)
      call CreatePartNode(this, name, new_obj, local_status)
    case (NODE_TYPE_MATER)
      call CreateMaterialNode(this, name, new_obj, local_status)
    case (NODE_TYPE_SECTI)
      call CreateSectionNode(this, name, new_obj, local_status)
    case (NODE_TYPE_STEP)
      call CreateStepNode(this, name, new_obj, local_status)
    case default
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Unsupported node type'
    end select
    
    if (local_status%status_code == IF_STATUS_OK .and. associated(new_obj)) then
      ! Add to model tree
      select case (node_type)
      case (NODE_TYPE_PART)
        select type (p => new_obj)
        type is (PartDesc)
          call this%model_tree%AddPart(p, local_status)
        end select
      case (NODE_TYPE_MATER)
        select type (m => new_obj)
        type is (MatDesc)
          call this%model_tree%AddMaterial(m, local_status)
        end select
      case (NODE_TYPE_SECTI)
        select type (s => new_obj)
        type is (SectDesc)
          call this%model_tree%AddSection(s, local_status)
        end select
      case (NODE_TYPE_STEP)
        select type (st => new_obj)
        type is (StepDesc)
          call this%model_tree%AddStep(st, local_status)
        end select
      end select
      
      ! Get node ID (from index manager)
      node_id = this%model_tree%index_mgr%GetNextID()
    end if
    
    if (present(status)) status = local_status
    
  contains
    
    subroutine CreatePartNode(ctrl, name, obj_ptr, status)
      type(TreeMgr), intent(in) :: ctrl
      character(len=*), intent(in) :: name
      class(*), pointer, intent(out) :: obj_ptr
      type(ErrorStatusType), intent(out) :: status
      
      type(PartDesc), pointer :: part
      
      call init_error_status(status)
      allocate(part)
      call part%Init(name=name)
      obj_ptr => part
      status%status_code = IF_STATUS_OK
    end subroutine CreatePartNode
    
    subroutine CreateMaterialNode(ctrl, name, obj_ptr, status)
      type(TreeMgr), intent(in) :: ctrl
      character(len=*), intent(in) :: name
      class(*), pointer, intent(out) :: obj_ptr
      type(ErrorStatusType), intent(out) :: status
      
      type(MD_Mat_Desc), pointer :: Mat
      
      call init_error_status(status)
      allocate(Mat)
      call Mat%Init(name=name)
      obj_ptr => Mat
      status%status_code = IF_STATUS_OK
    end subroutine CreateMaterialNode
    
    subroutine CreateSectionNode(ctrl, name, obj_ptr, status)
      type(TreeMgr), intent(in) :: ctrl
      character(len=*), intent(in) :: name
      class(*), pointer, intent(out) :: obj_ptr
      type(ErrorStatusType), intent(out) :: status
      
      type(SectDesc), pointer :: section
      
      call init_error_status(status)
      allocate(section)
      call section%Init(name=name)
      obj_ptr => section
      status%status_code = IF_STATUS_OK
    end subroutine CreateSectionNode
    
    subroutine CreateStepNode(ctrl, name, obj_ptr, status)
      type(TreeMgr), intent(in) :: ctrl
      character(len=*), intent(in) :: name
      class(*), pointer, intent(out) :: obj_ptr
      type(ErrorStatusType), intent(out) :: status
      
      type(StepDesc), pointer :: step
      
      call init_error_status(status)
      allocate(step)
      call step%Init(name=name)
      obj_ptr => step
      status%status_code = IF_STATUS_OK
    end subroutine CreateStepNode
    
  end subroutine TreeMgr_CreateNode
  
  ! ===================================================================
  ! Delete Node
  ! ===================================================================
  
  !=============================================================================
  !> @brief Delete tree node (legacy interface)
  !! @details Deletes a node from the model tree
  !! @param[inout] this Tree manager instance
  !! @param[in] node_id Node ID to delete ??
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine TreeMgr_DeleteNode(this, node_id, status)
    class(TreeMgr), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    type(ErrorStatusType), intent(out), optional :: status
    
    class(*), pointer :: obj_ptr => null()
    class(TreeNodeBase), pointer :: tree_node_ptr => null()
    integer(i4) :: node_type
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    
    if (.not. associated(this%model_tree)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Model tree not associated'
      end if
      return
    end if
    
    ! Get object first to extract type
    obj_ptr => this%GetNodeData(node_id, status)
    if (.not. associated(obj_ptr)) return
    
    ! Extract node type from object
    select type (obj => obj_ptr)
    class is (TreeNodeBase)
      node_type = obj%GetType()
    class is (PartDesc)
      node_type = NODE_TYPE_PART
    class is (MD_Mat_Desc)
      node_type = NODE_TYPE_MATER
    class is (SectDesc)
      node_type = NODE_TYPE_SECTI
    class is (StepDesc)
      node_type = NODE_TYPE_STEP
    class default
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Unknown node type'
      end if
      return
    end select
    
    ! Remove from appropriate container based on type
    select case (node_type)
    case (NODE_TYPE_PART)
      call this%model_tree%parts%Remove(node_id, local_status)
    case (NODE_TYPE_MATER)
      call this%model_tree%materials%Remove(node_id, local_status)
    case (NODE_TYPE_SECTI)
      call this%model_tree%sections%Remove(node_id, local_status)
    case (NODE_TYPE_STEP)
      call this%model_tree%steps%Remove(node_id, local_status)
    case (NODE_TYPE_LOADB)
      call this%model_tree%loadbcs%Remove(node_id, local_status)
    case (NODE_TYPE_INTER)
      call this%model_tree%interactions%Remove(node_id, local_status)
    case default
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        write(status%message, '(A,I0)') 'Unsupported node type for deletion: ', node_type
      end if
      return
    end select
    
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    ! Unregister from index manager
    select type (obj => obj_ptr)
    class is (TreeNodeBase)
      tree_node_ptr => obj
      call this%model_tree%index_mgr%Unregister(tree_node_ptr, local_status)
    end select
    
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine TreeMgr_DeleteNode
  
  ! ===================================================================
  ! Rename Node
  ! ===================================================================
  
  !=============================================================================
  !> @brief Rename tree node (legacy interface)
  !! @details Renames a node in the model tree
  !! @param[inout] this Tree manager instance
  !! @param[in] node_id Node ID to rename ??
  !! @param[in] new_name New node name
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine TreeMgr_RenameNode(this, node_id, new_name, status)
    class(TreeMgr), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    character(len=*), intent(in) :: new_name
    type(ErrorStatusType), intent(out), optional :: status
    
    class(*), pointer :: obj_ptr => null()
    
    if (present(status)) call init_error_status(status)
    
    ! Get node data
    obj_ptr => this%GetNodeData(node_id, status)
    if (.not. associated(obj_ptr)) return
    
    ! Rename based on type
    select type (obj => obj_ptr)
    type is (PartDesc)
      obj%name = new_name
    type is (MatDesc)
      obj%name = new_name
    type is (SectDesc)
      obj%name = new_name
    type is (StepDesc)
      obj%name = new_name
    end select
    
    ! Note: IndexMgr doesn't have UpdateName method
    ! The name is stored in the object itself, so no index update needed
    ! If needed, we could rebuild the index, but that's expensive
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine TreeMgr_RenameNode
  
  ! ===================================================================
  ! Get Node Data
  ! ===================================================================
  
  function TreeMgr_GetNodeData(this, node_id, status) result(obj_ptr)
    class(TreeMgr), intent(in) :: this
    integer(i4), intent(in) :: node_id
    type(ErrorStatusType), intent(out), optional :: status
    class(*), pointer :: obj_ptr
    
    integer(i4) :: node_type
    
    nullify(obj_ptr)
    if (present(status)) call init_error_status(status)
    
    if (.not. associated(this%model_tree)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Model tree not associated'
      end if
      return
    end if
    
    ! Get object from model tree by ID (try all containers)
    obj_ptr => this%model_tree%GetPart(id=node_id)
    if (associated(obj_ptr)) then
      node_type = NODE_TYPE_PART
    else
      obj_ptr => this%model_tree%GetMaterial(id=node_id)
      if (associated(obj_ptr)) then
        node_type = NODE_TYPE_MATER
      else
        obj_ptr => this%model_tree%GetSection(id=node_id)
        if (associated(obj_ptr)) then
          node_type = NODE_TYPE_SECTI
        else
          obj_ptr => this%model_tree%GetStep(id=node_id)
          if (associated(obj_ptr)) then
            node_type = NODE_TYPE_STEP
          else
            obj_ptr => this%model_tree%GetLoadBC(id=node_id)
            if (associated(obj_ptr)) then
              node_type = NODE_TYPE_LOADB
            else
              obj_ptr => this%model_tree%GetInteraction(id=node_id)
              if (associated(obj_ptr)) then
                node_type = NODE_TYPE_INTER
              end if
            end if
          end if
        end if
      end if
    end if
    
    ! Get object from model tree by ID
    select case (node_type)
    case (NODE_TYPE_PART)
      obj_ptr => this%model_tree%GetPart(id=node_id)
    case (NODE_TYPE_MATER)
      obj_ptr => this%model_tree%GetMaterial(id=node_id)
    case (NODE_TYPE_SECTI)
      obj_ptr => this%model_tree%GetSection(id=node_id)
    case (NODE_TYPE_STEP)
      obj_ptr => this%model_tree%GetStep(id=node_id)
    case (NODE_TYPE_LOADB)
      obj_ptr => this%model_tree%GetLoadBC(id=node_id)
    case (NODE_TYPE_INTER)
      obj_ptr => this%model_tree%GetInteraction(id=node_id)
    case default
      ! Try all containers if type is unknown
      obj_ptr => this%model_tree%GetPart(id=node_id)
      if (.not. associated(obj_ptr)) obj_ptr => this%model_tree%GetMaterial(id=node_id)
      if (.not. associated(obj_ptr)) obj_ptr => this%model_tree%GetSection(id=node_id)
      if (.not. associated(obj_ptr)) obj_ptr => this%model_tree%GetStep(id=node_id)
      if (.not. associated(obj_ptr)) obj_ptr => this%model_tree%GetLoadBC(id=node_id)
      if (.not. associated(obj_ptr)) obj_ptr => this%model_tree%GetInteraction(id=node_id)
    end select
    
    if (.not. associated(obj_ptr) .and. present(status)) then
      status%status_code = STATUS_NOT_FOUN
      write(status%message, '(A,I0)') 'Node not found: ', node_id
    end if
  end function TreeMgr_GetNodeData
  
  ! ===================================================================
  ! Set Node Data
  ! ===================================================================
  
  subroutine TreeMgr_SetNodeData(this, node_id, obj_ptr, status)
    class(TreeMgr), intent(inout) :: this
    integer(i4), intent(in) :: node_id
    class(*), pointer, intent(in) :: obj_ptr
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4) :: node_type
    class(*), pointer :: old_obj_ptr => null()
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    
    if (.not. associated(this%model_tree)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Model tree not associated'
      end if
      return
    end if
    
    if (.not. associated(obj_ptr)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Object pointer is null'
      end if
      return
    end if
    
    ! Get old object to determine type
    old_obj_ptr => this%GetNodeData(node_id, local_status)
    if (.not. associated(old_obj_ptr)) then
      if (present(status)) then
        status%status_code = IF_STATUS_NOT_FOUND
        write(status%message, '(A,I0)') 'Node not found: ', node_id
      end if
      return
    end if
    
    ! Valid types match and update using ObjContainer Update method
    select type (old_obj => old_obj_ptr)
    class is (PartDesc)
      select type (new_obj => obj_ptr)
      class is (PartDesc)
        ! Types match, update using ObjContainer Update method
        select type (tree_node => new_obj)
        class is (TreeNodeBase)
          call this%model_tree%parts%Update(node_id, tree_node, local_status)
        end select
      class default
        if (present(status)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'Type mismatch: expected PartDesc'
        end if
        return
      end select
    class is (MD_Mat_Desc)
      select type (new_obj => obj_ptr)
      class is (MD_Mat_Desc)
        select type (tree_node => new_obj)
        class is (TreeNodeBase)
          call this%model_tree%materials%Update(node_id, tree_node, local_status)
        end select
      class default
        if (present(status)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'Type mismatch: expected MD_Mat_Desc'
        end if
        return
      end select
    class is (SectDesc)
      select type (new_obj => obj_ptr)
      class is (SectDesc)
        select type (tree_node => new_obj)
        class is (TreeNodeBase)
          call this%model_tree%sections%Update(node_id, tree_node, local_status)
        end select
      class default
        if (present(status)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'Type mismatch: expected SectDesc'
        end if
        return
      end select
    class is (StepDesc)
      select type (new_obj => obj_ptr)
      class is (StepDesc)
        select type (tree_node => new_obj)
        class is (TreeNodeBase)
          call this%model_tree%steps%Update(node_id, tree_node, local_status)
        end select
      class default
        if (present(status)) then
          status%status_code = IF_STATUS_INVALID
          status%message = 'Type mismatch: expected StepDesc'
        end if
        return
      end select
    class default
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Unsupported object type for update'
      end if
      return
    end select
    
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine TreeMgr_SetNodeData
  
  ! ===================================================================
  ! Get Children
  ! ===================================================================
  
  subroutine TreeMgr_GetChildren(this, parent_id, child_ids, status)
    class(TreeMgr), intent(in) :: this
    integer(i4), intent(in) :: parent_id
    integer(i4), allocatable, intent(out) :: child_ids(:)
    type(ErrorStatusType), intent(out), optional :: status
    
    integer(i4), allocatable :: ids_tmp(:)
    integer(i4) :: i, num_children
    
    if (present(status)) call init_error_status(status)
    
    if (.not. associated(this%model_tree)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Model tree not associated'
      end if
      allocate(child_ids(0))
      return
    end if
    
    ! Query index manager for children
    ids_tmp = this%model_tree%index_mgr%FindChildren(parent_id)
    
    if (allocated(ids_tmp)) then
      num_children = size(ids_tmp)
      allocate(child_ids(num_children))
      child_ids = ids_tmp
    else
      allocate(child_ids(0))
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine TreeMgr_GetChildren
  
  ! ===================================================================
  ! Move Node
  ! ===================================================================
  
  subroutine TreeMgr_MoveNode(this, node_id, new_parent_id, status)
    class(TreeMgr), intent(inout) :: this
    integer(i4), intent(in) :: node_id, new_parent_id
    type(ErrorStatusType), intent(out), optional :: status
    
    class(TreeNodeBase), pointer :: obj_ptr => null()
    integer(i4) :: old_parent_id
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    
    if (.not. associated(this%model_tree)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Model tree not associated'
      end if
      return
    end if
    
    ! Get node object
    obj_ptr => this%GetNodeData(node_id, local_status)
    if (.not. associated(obj_ptr)) then
      if (present(status)) then
        status%status_code = IF_STATUS_NOT_FOUND
        write(status%message, '(A,I0)') 'Node not found: ', node_id
      end if
      return
    end if
    
    ! Get old parent ID
    select type (obj => obj_ptr)
    class is (TreeNodeBase)
      old_parent_id = obj%GetParentID()
      
      ! Update parent relationship via index manager
      call this%model_tree%index_mgr%UpdateParent(obj, old_parent_id, new_parent_id, local_status)
      
      if (local_status%status_code /= IF_STATUS_OK) then
        if (present(status)) status = local_status
        return
      end if
    end select
    
    ! Note: TreeNodeBase objects may need to update their parent_id field
    ! This depends on the implementation of TreeNodeBase
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine TreeMgr_MoveNode
  
  ! ===================================================================
  ! Get Node Path
  ! ===================================================================
  
  function TreeMgr_GetNodePath(this, node_id) result(path)
    class(TreeMgr), intent(in) :: this
    integer(i4), intent(in) :: node_id
    character(len=512) :: path
    
    class(*), pointer :: obj_ptr => null()
    character(len=64) :: node_name
    integer(i4) :: node_type
    type(ErrorStatusType) :: status
    
    path = ''
    
    ! Get node object to extract name and type
    obj_ptr => this%GetNodeData(node_id, status)
    if (.not. associated(obj_ptr)) return
    
    ! Extract name and type from object
    select type (obj => obj_ptr)
    class is (TreeNodeBase)
      node_name = obj%GetName()
      node_type = obj%GetType()
    class is (PartDesc)
      node_name = obj%name
      node_type = NODE_TYPE_PART
    class is (MD_Mat_Desc)
      node_name = obj%name
      node_type = NODE_TYPE_MATER
    class is (SectDesc)
      node_name = obj%name
      node_type = NODE_TYPE_SECTI
    class is (StepDesc)
      node_name = obj%name
      node_type = NODE_TYPE_STEP
    end select
    
    ! Build path
    select case (node_type)
    case (NODE_TYPE_MODEL)
      path = 'Model/' // trim(node_name)
    case (NODE_TYPE_PART)
      path = 'Model/Parts/' // trim(node_name)
    case (NODE_TYPE_MATER)
      path = 'Model/Materials/' // trim(node_name)
    case (NODE_TYPE_SECTI)
      path = 'Model/Sections/' // trim(node_name)
    case (NODE_TYPE_STEP)
      path = 'Model/Steps/' // trim(node_name)
    end select
  end function TreeMgr_GetNodePath
  
  ! ===================================================================
  ! Find Node By Name
  ! ===================================================================
  
  function TreeMgr_FindNodeByName(this, name, node_type) result(node_id)
    class(TreeMgr), intent(in) :: this
    character(len=*), intent(in) :: name
    integer(i4), intent(in), optional :: node_type
    integer(i4) :: node_id
    
    class(TreeNodeBase), pointer :: obj_ptr => null()
    
    node_id = 0_i4
    
    if (.not. associated(this%model_tree)) return
    
    ! Find by name using index manager
    obj_ptr => this%model_tree%index_mgr%FindByName(name)
    
    if (associated(obj_ptr)) then
      ! Check if type matches (if specified)
      if (present(node_type)) then
        if (obj_ptr%GetType() == node_type) then
          node_id = obj_ptr%GetID()
        end if
      else
        node_id = obj_ptr%GetID()
      end if
    end if
  end function TreeMgr_FindNodeByName
  
  ! ===================================================================
  ! Valid Node
  ! ===================================================================
  
  function TreeMgr_ValidateNode(this, node_id) result(is_valid)
    class(TreeMgr), intent(in) :: this
    integer(i4), intent(in) :: node_id
    logical :: is_valid
    
    class(*), pointer :: obj_ptr => null()
    type(ErrorStatusType) :: status
    
    is_valid = .false.
    
    obj_ptr => this%GetNodeData(node_id, status)
    if (associated(obj_ptr)) then
      is_valid = .true.
    end if
  end function TreeMgr_ValidateNode
  
end module AP_UI_TreeMgr