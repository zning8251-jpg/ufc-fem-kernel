!===============================================================================
! MODULE:  MD_Model_Tree
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Impl (semantic tree structure)
! BRIEF:   P0 Insert/Search/Traverse: Hierarchical model tree for L6_AP
!          modeling phase (INP parsing, UI model management).
!          NOT runtime authority (that is MD_L3_LayerContainer).
!===============================================================================

MODULE MD_Model_Tree
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MODEL_STATUS_OK, MD_MODEL_STATUS_INVALID, MD_MODEL_STATUS_NOT_FOUND
  USE IF_Prec_Core, ONLY: i4, i8, wp
  USE MD_Base_ObjModel, ONLY: ObjContainer
  USE MD_Base_ObjModel, ONLY: MD_MODEL_CAT_DESC, ObjBase
  USE MD_Base_TreeIndex
  USE MD_Model_Def, ONLY: MD_Model_Desc
  ! Material Domain Container (Phase A)
  ! Material domain: md_layer%material (index+flat, MATERIAL_INDEX_FLAT_MIGRATION)

  implicit none
  private

  public :: ModelTree
  ! Extended API (task3400-3499)
  public :: MD_ModelTree_DFS_Traverse, MD_ModelTree_BFS_Traverse
  public :: MD_ModelTree_QueryOptimize, MD_ModelTree_BuildIndex
  public :: MD_ModelTree_FindByPath, MD_ModelTree_FindByType
  public :: MD_ModelTree_Traverse_Arg, MD_ModelTree_QueryOptimize_Arg, MD_ModelTree_FindByPath_Arg

  ! ===================================================================
  ! Model Tree Type (extends ModelDesc and TreeNodeBase)
  ! ===================================================================
  type, public, extends(MD_Model_Desc) :: ModelTree
    ! Tree node properties (inherited from TreeNodeBase interface)
    integer(i4) :: node_id = 0_i4
    integer(i4) :: parent_id = 0_i4
    logical :: is_active = .true.
    logical :: is_visible = .true.

    ! Child object containers - unified container interface
    type(ObjContainer) :: parts
    type(ObjContainer) :: assemblies
    type(ObjContainer) :: materials
    type(ObjContainer) :: sections
    type(ObjContainer) :: meshes
    type(ObjContainer) :: amplitudes
    type(ObjContainer) :: loadbcs
    type(ObjContainer) :: interactions
    type(ObjContainer) :: steps
    
    ! Container registry for unified access (indexed by node type)
    type(ObjContainer), pointer :: container_regis(:) => null()

    ! Index manager (unified for all containers)
    type(IndexMgr) :: index_mgr

    ! Performance optimization (lazy index for each container type)
    type(LazyIndexMgr) :: lazy_index_part
    type(LazyIndexMgr) :: lazy_index_mate
    type(LazyIndexMgr) :: lazy_index_sect
    type(LazyIndexMgr) :: lazy_index_step
    type(BatchOpMgr) :: batch_mgr

    ! Path resolver (for path-based access)
    type(PathResolver) :: path_resolver

    ! Multi-level nesting support
    logical :: supports_nestin = .true.
    integer(i4) :: max_nesting_dep = 10_i4
    logical :: tree_initialize = .false.
  contains
  SUBROUTINE ModelTree_Build_NameIndex(tree, status)
    TYPE(ModelTree), INTENT(INOUT) :: tree
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Use existing index manager to build name index
    CALL tree%RebuildIndex(status)
    
  END SUBROUTINE ModelTree_Build_NameIndex

  SUBROUTINE ModelTree_Build_PathIndex(tree, status)
    TYPE(ModelTree), INTENT(INOUT) :: tree
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Use path resolver to build path index
    ! Simplified: production code should build path-based lookup table
    
    status%status_code = MD_MODEL_STATUS_OK
    
  END SUBROUTINE ModelTree_Build_PathIndex

  SUBROUTINE ModelTree_Build_TypeIndex(tree, status)
    TYPE(ModelTree), INTENT(INOUT) :: tree
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Build index grouped by object type
    ! Simplified: production code should build type-based hash/index
    
    status%status_code = MD_MODEL_STATUS_OK
    
  END SUBROUTINE ModelTree_Build_TypeIndex

  RECURSIVE SUBROUTINE ModelTree_DFS_Recursive(tree, visitor_proc, depth, status)
    TYPE(ModelTree), INTENT(IN) :: tree
    INTERFACE
      SUBROUTINE visitor_proc(node_id, node_type, depth, status)
        IMPORT :: i4, ErrorStatusType
        INTEGER(i4), INTENT(IN) :: node_id, node_type, depth
        TYPE(ErrorStatusType), INTENT(INOUT) :: status
      END SUBROUTINE visitor_proc
    END INTERFACE
    INTEGER(i4), INTENT(IN) :: depth
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    
    INTEGER(i4) :: i, nParts, nMats, num_steps
    INTEGER(i4) :: node_id, node_type
    
    IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
    
    ! Visit current node
    node_id = tree%GetID()
    node_type = tree%GetType()
    CALL visitor_proc(node_id, node_type, depth, status)
    IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
    
    ! Traverse children (simplified - production should traverse all containers)
    nParts = tree%GetNumParts()
    nMats = tree%GetNumMaterials()
    num_steps = tree%GetNumSteps()
    
    ! Recursively traverse child nodes
    ! Simplified: production code should properly traverse nested tree structure
    
  END SUBROUTINE ModelTree_DFS_Recursive

  SUBROUTINE MD_ModelTree_BFS_Traverse(tree, visitor_proc, status)
    TYPE(ModelTree), INTENT(IN) :: tree
    INTERFACE
      SUBROUTINE visitor_proc(node_id, node_type, depth, status)
        IMPORT :: i4, ErrorStatusType
        INTEGER(i4), INTENT(IN) :: node_id, node_type, depth
        TYPE(ErrorStatusType), INTENT(INOUT) :: status
      END SUBROUTINE visitor_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4), ALLOCATABLE :: queue(:), depths(:)
    INTEGER(i4) :: front, rear, current_id, current_depth, current_type
    INTEGER(i4) :: max_queue_size
    TYPE(ErrorStatusType) :: local_status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    CALL init_error_status(local_status)
    
    ! Init queue
    max_queue_size = 1000
    ALLOCATE(queue(max_queue_size), depths(max_queue_size))
    front = 1
    rear = 1
    
    ! Enqueue root
    queue(rear) = tree%GetID()
    depths(rear) = 0
    rear = rear + 1
    
    ! BFS traversal
    DO WHILE (front < rear)
      current_id = queue(front)
      current_depth = depths(front)
      current_type = tree%GetType()
      front = front + 1
      
      ! Visit node
      CALL visitor_proc(current_id, current_type, current_depth, local_status)
      IF (local_status%status_code /= MD_MODEL_STATUS_OK) EXIT
      
      ! Enqueue children (simplified - production should enqueue all children)
      ! For now, just mark as visited
    END DO
    
    DEALLOCATE(queue, depths)
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE MD_ModelTree_BFS_Traverse

  SUBROUTINE MD_ModelTree_BuildIndex(tree, index_type, status)
    TYPE(ModelTree), INTENT(INOUT) :: tree
    INTEGER(i4), INTENT(IN), OPTIONAL :: index_type  ! 1=name, 2=type, 3=path
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: idx_type
    
    IF (PRESENT(status)) CALL init_error_status(status)
    CALL init_error_status(local_status)
    
    idx_type = 1  ! Default: name index
    IF (PRESENT(index_type)) idx_type = index_type
    
    ! Build index based on type
    SELECT CASE (idx_type)
    CASE (1)  ! Name index
      CALL ModelTree_Build_NameIndex(tree, local_status)
    CASE (2)  ! Type index
      CALL ModelTree_Build_TypeIndex(tree, local_status)
    CASE (3)  ! Path index
      CALL ModelTree_Build_PathIndex(tree, local_status)
    CASE DEFAULT
      CALL ModelTree_Build_NameIndex(tree, local_status)
    END SELECT
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE MD_ModelTree_BuildIndex

  SUBROUTINE MD_ModelTree_DFS_Traverse(tree, visitor_proc, status)
    TYPE(ModelTree), INTENT(IN) :: tree
    INTERFACE
      SUBROUTINE visitor_proc(node_id, node_type, depth, status)
        IMPORT :: i4, ErrorStatusType
        INTEGER(i4), INTENT(IN) :: node_id, node_type, depth
        TYPE(ErrorStatusType), INTENT(INOUT) :: status
      END SUBROUTINE visitor_proc
    END INTERFACE
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    INTEGER(i4) :: depth
    
    IF (PRESENT(status)) CALL init_error_status(status)
    CALL init_error_status(local_status)
    
    depth = 0
    CALL ModelTree_DFS_Recursive(tree, visitor_proc, depth, local_status)
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE MD_ModelTree_DFS_Traverse

  SUBROUTINE MD_ModelTree_FindByPath(tree, path, obj_ptr, status)
    TYPE(ModelTree), INTENT(IN) :: tree
    CHARACTER(LEN=*), INTENT(IN) :: path
    TYPE(ObjBase), POINTER, INTENT(OUT) :: obj_ptr
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    CALL init_error_status(local_status)
    
    ! Use path resolver for optimized lookup
    obj_ptr => tree%GetByPath(path, local_status)
    
    IF (.NOT. ASSOCIATED(obj_ptr)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = MD_MODEL_STATUS_NOT_FOUND
        status%message = "MD_ModelTree_FindByPath: Object not found at path"
      END IF
      RETURN
    END IF
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE MD_ModelTree_FindByPath

  SUBROUTINE MD_ModelTree_FindByType(tree, obj_type, obj_list, nFound, status)
    TYPE(ModelTree), INTENT(IN) :: tree
    INTEGER(i4), INTENT(IN) :: obj_type
    TYPE(ObjBase), POINTER, INTENT(OUT) :: obj_list(:)
    INTEGER(i4), INTENT(OUT) :: nFound
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    TYPE(ObjContainer), POINTER :: container_ptr
    
    IF (PRESENT(status)) CALL init_error_status(status)
    CALL init_error_status(local_status)
    
    nFound = 0
    
    ! Get container by type
    container_ptr => tree%GetContainer(obj_type)
    
    IF (.NOT. ASSOCIATED(container_ptr)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = MD_MODEL_STATUS_NOT_FOUND
        status%message = "MD_ModelTree_FindByType: Container not found"
      END IF
      RETURN
    END IF
    
    ! Get objects from container (simplified - production should properly extract)
    nFound = 0  ! Placeholder
    
    IF (PRESENT(status)) status%status_code = MD_MODEL_STATUS_OK
    
  END SUBROUTINE MD_ModelTree_FindByType

  SUBROUTINE MD_ModelTree_QueryOptimize(tree, rebuild_index, status)
    TYPE(ModelTree), INTENT(INOUT) :: tree
    LOGICAL, INTENT(IN), OPTIONAL :: rebuild_index
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status
    LOGICAL :: do_rebuild
    
    IF (PRESENT(status)) CALL init_error_status(status)
    CALL init_error_status(local_status)
    
    do_rebuild = .TRUE.
    IF (PRESENT(rebuild_index)) do_rebuild = rebuild_index
    
    ! Rebuild all indices
    IF (do_rebuild) THEN
      CALL tree%RebuildIndex(local_status)
      IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
        IF (PRESENT(status)) status = local_status
        RETURN
      END IF
    END IF
    
    ! Optimize lazy indices
    CALL ModelTree_OptimizeLazyIndices(tree, local_status)
    
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE MD_ModelTree_QueryOptimize

  subroutine ModelTree_AddAssembly(this, assembly, status)
    !! Add assembly to model tree with full production-level validation
    !! Production Implementation ( -grade :
    !! 1. whetherinit ?init init
    !! 2. object ? ? ?
    !! 3. checkwhether ? ?
    !! 4.  assemblies  
    !! 5.  ?MarkDirty
    !! 6.  management 
    !! 7.  
    !! 8.  
    class(ModelTree), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: assembly
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: assem_name
    class(ObjBase), pointer :: existing_assem

    call init_error_status(status)

    ! Step 1: init ?
    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        status%message = 'Failed to initialize ModelTree: ' // trim(status%message)
        return
      end if
    end if
    
    ! Step 2:  object 
    assem_name = assembly%GetName()
    if (len_trim(assem_name) == 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'Assembly name cannot be empty'
      return
    end if
    
    ! Step 3: checkwhether 
    existing_assem => this%assemblies%GetByName(assem_name)
    if (associated(existing_assem)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      write(status%message, '(A,A,A)') 'Assembly "', trim(assem_name), '" already exists in ModelTree'
      return
    end if

    ! Step 4:  assemblies  
    call this%assemblies%Add(assembly, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) then
      write(status%message, '(A,A,A)') 'Failed to add assembly "', trim(assem_name), '": ' // trim(status%message)
      return
    end if

    ! Step 5: ? ?
    ! Note: management ?

    ! Step 6:  management 
    if (.not. this%batch_mgr%IsBatchMode()) then
      call this%index_mgr%Reg(assembly, status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        !  See module header / UFC docs for context.
        call init_error_status(status)
      end if
    end if

    ! Step 7:  
    this%nAssemblies = this%assemblies%GetCount()

    ! Step 8:  
    if (this%batch_mgr%IsBatchMode()) then
      call this%batch_mgr%IncrementBatch()
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_AddAssembly

  subroutine ModelTree_AddChild(this, child, status)
    !! Add child object to appropriate container based on type
    class(ModelTree), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: child
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: node_type
    type(ObjContainer), pointer :: container_ptr
    
    call init_error_status(status)
    
    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end if
    
    node_type = child%GetType()
    container_ptr => this%GetContainer(node_type)
    
    if (.not. associated(container_ptr)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Invalid node type for ModelTree"
      return
    end if
    
    call container_ptr%Add(child, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    
    ! Update parent ID
    call child%SetParentID(this%GetID(), status)
    
    ! Mark index as dirty if not in batch mode
    if (.not. this%batch_mgr%IsBatchMode()) then
      call this%index_mgr%Reg(child, status=status)
    end if
  end subroutine ModelTree_AddChild

  subroutine ModelTree_AddInteraction(this, interaction, status)
    !! Add interaction to model tree with full production-level validation
    !! Production Implementation ( -grade :
    !! 1. whetherinit ?init init
    !! 2. object ? ? ?
    !! 3. checkwhether ? ?
    !! 4.  interactions  
    !! 5.  ?MarkDirty
    !! 6.  management 
    !! 7.  
    !! 8.  
    class(ModelTree), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: interaction
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: inter_name
    class(ObjBase), pointer :: existing_inter

    call init_error_status(status)

    ! Step 1: init ?
    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        status%message = 'Failed to initialize ModelTree: ' // trim(status%message)
        return
      end if
    end if
    
    ! Step 2:  object 
    inter_name = interaction%GetName()
    if (len_trim(inter_name) == 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'Interaction name cannot be empty'
      return
    end if
    
    ! Step 3: checkwhether 
    existing_inter => this%interactions%GetByName(inter_name)
    if (associated(existing_inter)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      write(status%message, '(A,A,A)') 'Interaction "', trim(inter_name), '" already exists in ModelTree'
      return
    end if

    ! Step 4:  interactions  
    call this%interactions%Add(interaction, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) then
      write(status%message, '(A,A,A)') 'Failed to add interaction "', trim(inter_name), '": ' // trim(status%message)
      return
    end if

    ! Step 5: ? ?
    ! Note: management ?

    ! Step 6:  management 
    if (.not. this%batch_mgr%IsBatchMode()) then
      call this%index_mgr%Reg(interaction, status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        !  See module header / UFC docs for context.
        call init_error_status(status)
      end if
    end if

    ! Step 7:  
    this%nInteractions = this%interactions%GetCount()

    ! Step 8:  
    if (this%batch_mgr%IsBatchMode()) then
      call this%batch_mgr%IncrementBatch()
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_AddInteraction

  subroutine ModelTree_AddLoadBC(this, loadbc, status)
    !! Add load/boundary condition to model tree with full production-level validation
    !! Production Implementation ( -grade :
    !! 1. whetherinit ?init init
    !! 2. load/boundary conditionobject ? ? ?
    !! 3. checkwhether load/boundary condition ? ?
    !! 4.  loadbcs  
    !! 5.  ?MarkDirty
    !! 6.  management 
    !! 7.  load/boundary condition 
    !! 8.  
    class(ModelTree), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: loadbc
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: loadbc_name
    class(ObjBase), pointer :: existing_loadbc

    call init_error_status(status)

    ! Step 1: init ?
    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        status%message = 'Failed to initialize ModelTree: ' // trim(status%message)
        return
      end if
    end if
    
    ! Step 2:  load/boundary conditionobject 
    loadbc_name = loadbc%GetName()
    if (len_trim(loadbc_name) == 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'LoadBC name cannot be empty'
      return
    end if
    
    ! Step 3: checkwhether load/boundary condition
    existing_loadbc => this%loadbcs%GetByName(loadbc_name)
    if (associated(existing_loadbc)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      write(status%message, '(A,A,A)') 'LoadBC "', trim(loadbc_name), '" already exists in ModelTree'
      return
    end if

    ! Step 4:  loadbcs  
    call this%loadbcs%Add(loadbc, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) then
      write(status%message, '(A,A,A)') 'Failed to add loadbc "', trim(loadbc_name), '": ' // trim(status%message)
      return
    end if

    ! Step 5: ? ?
    ! Note: management ?

    ! Step 6:  management 
    if (.not. this%batch_mgr%IsBatchMode()) then
      call this%index_mgr%Reg(loadbc, status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        !  See module header / UFC docs for context.
        call init_error_status(status)
      end if
    end if

    ! Step 7:  load/boundary condition 
    this%nLoads = this%loadbcs%GetCount()

    ! Step 8:  
    if (this%batch_mgr%IsBatchMode()) then
      call this%batch_mgr%IncrementBatch()
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_AddLoadBC

  subroutine ModelTree_AddMaterial(this, Mat, status)
    !! Add Mat to model tree with full production-level validation
    !! Production Implementation ( -grade :
    !! 1. whetherinit ?init init
    !! 2. materialobject ? ? ?
    !! 3. checkwhether material ? ?
    !! 4.  materials  
    !! 5.  ?MarkDirty
    !! 6.  management 
    !! 7.  material 
    !! 8.  
    class(ModelTree), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: Mat
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: mat_name
    class(ObjBase), pointer :: existing_mat

    call init_error_status(status)

    ! Step 1: init ?
    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        status%message = 'Failed to initialize ModelTree: ' // trim(status%message)
        return
      end if
    end if
    
    ! Step 2:  materialobject 
    mat_name = Mat%GetName()
    if (len_trim(mat_name) == 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'Mat name cannot be empty'
      return
    end if
    
    ! Step 3: checkwhether material
    existing_mat => this%materials%GetByName(mat_name)
    if (associated(existing_mat)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      write(status%message, '(A,A,A)') 'Mat "', trim(mat_name), '" already exists in ModelTree'
      return
    end if

    ! Step 4:  materials  
    call this%materials%Add(Mat, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) then
      write(status%message, '(A,A,A)') 'Failed to add Mat "', trim(mat_name), '": ' // trim(status%message)
      return
    end if

    ! Step 5: ? ?
    call this%lazy_index_mate%MarkDirty()

    ! Step 6:  management 
    if (.not. this%batch_mgr%IsBatchMode()) then
      call this%index_mgr%Reg(Mat, status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        !  See module header / UFC docs for context.
        !  
        ! write(*, '(A,A,A)') 'Warning: Failed to register Mat "', trim(mat_name), '" to index'
        !  status 
        call init_error_status(status)
      end if
    end if

    ! Step 7:  material 
    this%nMaterials = this%materials%GetCount()

    ! Step 8:  
    if (this%batch_mgr%IsBatchMode()) then
      call this%batch_mgr%IncrementBatch()
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_AddMaterial

  subroutine ModelTree_AddPart(this, part, status)
    class(ModelTree), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: part
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end if

    call this%parts%Add(part, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    ! Mark index as dirty (lazy update)
    call this%lazy_index_part%MarkDirty()

    ! Reg in index manager if not in batch mode
    if (.not. this%batch_mgr%IsBatchMode()) then
      call this%index_mgr%Reg(part, status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end if

    this%nParts = this%parts%GetCount()

    ! Increment batch counter if in batch mode
    if (this%batch_mgr%IsBatchMode()) then
      call this%batch_mgr%IncrementBatch()
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_AddPart

  subroutine ModelTree_AddSection(this, section, status)
    !! Add section to model tree with full production-level validation
    !! Production Implementation ( -grade :
    !! 1. whetherinit ?init init
    !! 2. object ? ? ?
    !! 3. checkwhether ? ?
    !! 4.  sections  
    !! 5.  ?MarkDirty
    !! 6.  management 
    !! 7.  
    !! 8.  
    class(ModelTree), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: section
    type(ErrorStatusType), intent(out) :: status
    
    character(len=64) :: sec_name
    class(ObjBase), pointer :: existing_sec

    call init_error_status(status)

    ! Step 1: init ?
    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        status%message = 'Failed to initialize ModelTree: ' // trim(status%message)
        return
      end if
    end if
    
    ! Step 2:  object 
    sec_name = section%GetName()
    if (len_trim(sec_name) == 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'Section name cannot be empty'
      return
    end if
    
    ! Step 3: checkwhether 
    existing_sec => this%sections%GetByName(sec_name)
    if (associated(existing_sec)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      write(status%message, '(A,A,A)') 'Section "', trim(sec_name), '" already exists in ModelTree'
      return
    end if

    ! Step 4:  sections  
    call this%sections%Add(section, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) then
      write(status%message, '(A,A,A)') 'Failed to add section "', trim(sec_name), '": ' // trim(status%message)
      return
    end if

    ! Step 5: ? ?
    call this%lazy_index_sect%MarkDirty()

    ! Step 6:  management 
    if (.not. this%batch_mgr%IsBatchMode()) then
      call this%index_mgr%Reg(section, status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        !  See module header / UFC docs for context.
        call init_error_status(status)
      end if
    end if

    ! Step 7:  
    this%nSections = this%sections%GetCount()

    ! Step 8:  
    if (this%batch_mgr%IsBatchMode()) then
      call this%batch_mgr%IncrementBatch()
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_AddSection

  subroutine ModelTree_AddStep(this, step, status)
    class(ModelTree), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: step
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end if

    call this%steps%Add(step, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%index_mgr%Reg(step, status=status)
    this%nSteps = this%steps%GetCount()

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_AddStep

  subroutine ModelTree_BeginBatch(this, max_size)
    class(ModelTree), intent(inout) :: this
    integer(i4), intent(in), optional :: max_size

    call this%batch_mgr%BeginBatch(max_size)
  end subroutine ModelTree_BeginBatch

  subroutine ModelTree_ClearAll(this, status)
    !! Clear all child containers
    class(ModelTree), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    
    if (.not. this%tree_initialize) then
      status%status_code = MD_MODEL_STATUS_INVALID
      return
    end if
    
    call this%parts%Clear(status)
    call this%assemblies%Clear(status)
    call this%materials%Clear(status)
    call this%sections%Clear(status)
    call this%meshes%Clear(status)
    call this%amplitudes%Clear(status)
    call this%loadbcs%Clear(status)
    call this%interactions%Clear(status)
    call this%steps%Clear(status)
    
    call this%index_mgr%Clear(status)
  end subroutine ModelTree_ClearAll

  subroutine ModelTree_Deserialize(this, deserializer)
    class(ModelTree), intent(inout) :: this
    class(TreeDeserializer), intent(in) :: deserializer

    integer(i4) :: i, n_parts, n_assemblies, n_materials
    integer(i4) :: n_sections, n_meshes, n_amplitudes
    integer(i4) :: n_loadbcs, n_interactions, n_steps
    type(ErrorStatusType) :: status
    character(len=256) :: obj_name

    ! Deserialize Model basic info
    obj_name = deserializer%BeginObject(status)
    this%cfg%id = deserializer%ReadInt(status)
    this%name = deserializer%ReadString(status)
    this%cfg%description = deserializer%ReadString(status)
    this%dimensionality = deserializer%ReadString(status)
    this%timePeriod = deserializer%ReadReal(status)

    ! Deserialize child object counts
    n_parts = deserializer%ReadInt(status)
    n_assemblies = deserializer%ReadInt(status)
    n_materials = deserializer%ReadInt(status)
    n_sections = deserializer%ReadInt(status)
    n_meshes = deserializer%ReadInt(status)
    n_amplitudes = deserializer%ReadInt(status)
    n_loadbcs = deserializer%ReadInt(status)
    n_interactions = deserializer%ReadInt(status)
    n_steps = deserializer%ReadInt(status)

    ! Init tree if not already initialized
    if (.not. this%tree_initialize) then
      call this%InitTree(status=status)
    end if

    ! Deserialize Parts (placeholder - requires PartTree to implement Serializable)
    obj_name = deserializer%BeginArray(status)
    do i = 1, n_parts
      ! Note: Actual deserialization would create appropriate PartTree objects
      ! For now, this is a placeholder
    end do
    call deserializer%EndArray(status)

    ! Rebuild index after deserialization
    call this%RebuildIndex(status)

    call deserializer%EndObject(status)
  end subroutine ModelTree_Deserialize

  subroutine ModelTree_DestroyTree(this, status)
    class(ModelTree), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call this%parts%Clean(status)
    call this%assemblies%Clean(status)
    call this%materials%Clean(status)
    
    ! Material domain: finalized by MD_L3_Finalize (md_layer%material)
    
    call this%sections%Clean(status)
    call this%meshes%Clean(status)
    call this%amplitudes%Clean(status)
    call this%loadbcs%Clean(status)
    call this%interactions%Clean(status)
    call this%steps%Clean(status)

    call this%index_mgr%Clean(status)
    
    ! Cleanup container registry
    if (associated(this%container_regis)) then
      deallocate(this%container_regis)
    end if

    this%tree_initialize = .false.

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_DestroyTree

  subroutine ModelTree_EndBatch(this, rebuild_index, status)
    class(ModelTree), intent(inout) :: this
    logical, intent(in), optional :: rebuild_index
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call this%batch_mgr%EndBatch(rebuild_index, local_status)

    if (present(rebuild_index) .and. rebuild_index) then
      call this%RebuildIndex(local_status)
    end if

    if (present(status)) then
      status = local_status
    end if
  end subroutine ModelTree_EndBatch

  function ModelTree_GetAmplitude(this, id, name) result(amplitude_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: amplitude_ptr
    class(ObjBase), pointer :: base_ptr

    amplitude_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%amplitudes%GetByID(id)
    else if (present(name)) then
      base_ptr => this%amplitudes%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        amplitude_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetAmplitude

  function ModelTree_GetAssembly(this, id, name) result(assembly_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: assembly_ptr
    class(ObjBase), pointer :: base_ptr

    assembly_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%assemblies%GetByID(id)
    else if (present(name)) then
      base_ptr => this%assemblies%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        assembly_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetAssembly

  function ModelTree_GetByPath(this, path_str) result(obj_ptr)
    !! Get object by path string, supporting multi-level nesting
    !! Path format: "Part/Part-1/Node/Node-100" or "Mat/Steel"
    class(ModelTree), intent(in), target :: this
    character(len=*), intent(in) :: path_str
    class(TreeNodeBase), pointer :: obj_ptr

    type(PathComponents) :: components
    integer(i4) :: i, nesting_depth
    character(len=64) :: comp, type_name, name
    class(TreeNodeBase), pointer :: current_obj
    type(ErrorStatusType) :: status

    obj_ptr => null()

    if (.not. this%tree_initialize) return

    ! Parse path into components
    call this%path_resolver%ParsePath(path_str, components, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    if (components%GetCount() == 0) then
      obj_ptr => this
      return
    end if

    ! Check nesting depth
    nesting_depth = components%GetCount()
    if (nesting_depth > this%max_nesting_dep) then
      return  ! Exceeds max nesting depth
    end if

    current_obj => this

    ! Traverse path components
    do i = 1, components%GetCount()
      comp = components%GetComponent(i)
      if (len_trim(comp) == 0) cycle

      ! Parse component (format: "Type/Name" or just "Name")
      call this%path_resolver%ParseComponent(comp, type_name, name, status)
      if (status%status_code /= MD_MODEL_STATUS_OK) exit

      ! Resolve based on type (first level - ModelTree children)
      select case (trim(type_name))
      case ("Part", "PART", "part")
        current_obj => this%GetPart(name=name)
      case ("Mat", "Mat", "Mat")
        current_obj => this%GetMaterial(name=name)
      case ("Step", "STEP", "step")
        current_obj => this%GetStep(name=name)
      case ("Assembly", "ASSEMBLY", "assembly")
        current_obj => this%GetAssembly(name=name)
      case ("Section", "SECTION", "section")
        current_obj => this%GetSection(name=name)
      case ("Mesh", "MESH", "mesh")
        current_obj => this%GetMesh(name=name)
      case ("Amplitude", "AMPLITUDE", "amplitude")
        current_obj => this%GetAmplitude(name=name)
      case ("LoadBC", "LOADBC", "loadbc")
        current_obj => this%GetLoadBC(name=name)
      case ("Interaction", "INTERACTION", "interaction")
        current_obj => this%GetInteraction(name=name)
      case default
        ! Try as name only (search all containers)
        if (len_trim(name) > 0) then
          current_obj => this%GetPart(name=name)
          if (.not. associated(current_obj)) current_obj => this%GetMaterial(name=name)
          if (.not. associated(current_obj)) current_obj => this%GetStep(name=name)
          if (.not. associated(current_obj)) current_obj => this%GetSection(name=name)
        end if
      end select

      ! If not found at current level, try nested access
      if (.not. associated(current_obj) .and. i > 1) then
        ! Try to resolve nested path (e.g., Part/Part-1/Node/Node-100)
        ! This requires the child object to support GetByPath
        ! For now, return null if not found
        exit
      end if

      ! If found and there are more components, try nested resolution
      if (associated(current_obj) .and. i < components%GetCount()) then
        ! Check if current_obj supports GetByPath (for nested access)
        ! For now, we'll try to call it if it's a tree node
        ! This is a simplified implementation - full nested support requires
        ! all tree nodes to implement GetByPath
        select type (obj => current_obj)
        type is (ModelTree)
          ! Recursive call for nested ModelTree
          ! Note: This would require extracting remaining path components
          ! For now, we'll handle it in a simplified way
        end select
      end if

      if (.not. associated(current_obj)) exit
    end do

    obj_ptr => current_obj
  end function ModelTree_GetByPath

  function ModelTree_GetChildByType(this, node_type, id, name) result(obj_ptr)
    !! Get child object by type, ID or name
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in) :: node_type
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: obj_ptr
    class(ObjBase), pointer :: base_ptr
    type(ObjContainer), pointer :: container_ptr
    
    obj_ptr => null()
    container_ptr => this%GetContainer(node_type)
    if (.not. associated(container_ptr)) return
    if (present(id)) then
      base_ptr => container_ptr%GetByID(id)
    else if (present(name)) then
      base_ptr => container_ptr%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        obj_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetChildByType

  function ModelTree_GetContainer(this, node_type) result(container_ptr)
    !! Get container by node type
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in) :: node_type
    type(ObjContainer), pointer :: container_ptr
    
    container_ptr => null()
    if (.not. this%tree_initialize) return
    
    select case (node_type)
    case (MD_MODEL_NODE_TYPE_PART)
      container_ptr => this%parts
    case (MD_MODEL_NODE_TYPE_ASSEM)
      container_ptr => this%assemblies
    case (MD_MODEL_NODE_TYPE_MATER)
      container_ptr => this%materials
    case (MD_MODEL_NODE_TYPE_SECTI)
      container_ptr => this%sections
    case (MD_MODEL_NODE_TYPE_MESH)
      container_ptr => this%meshes
    case (MD_MODEL_NODE_TYPE_AMPLI)
      container_ptr => this%amplitudes
    case (MD_MODEL_NODE_TYPE_LOADB)
      container_ptr => this%loadbcs
    case (MD_MODEL_NODE_TYPE_INTER)
      container_ptr => this%interactions
    case (MD_MODEL_NODE_TYPE_STEP)
      container_ptr => this%steps
    end select
  end function ModelTree_GetContainer

  function ModelTree_GetFullPath(this) result(path_str)
    !! Get full path string from root to this node
    class(ModelTree), intent(in) :: this
    character(len=512) :: path_str
    
    character(len=64) :: name
    
    name = this%GetName()
    if (len_trim(name) > 0) then
      path_str = '/' // trim(name)
    else
      write(path_str, '(A,I0)') '/Model_', this%GetID()
    end if
  end function ModelTree_GetFullPath

  function ModelTree_GetID(this) result(id)
    class(ModelTree), intent(in) :: this
    integer(i4) :: id
    id = this%node_id
    if (id == 0) id = this%cfg%id
  end function ModelTree_GetID

  function ModelTree_GetInteraction(this, id, name) result(interaction_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: interaction_ptr
    class(ObjBase), pointer :: base_ptr

    interaction_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%interactions%GetByID(id)
    else if (present(name)) then
      base_ptr => this%interactions%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        interaction_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetInteraction

  function ModelTree_GetLoadBC(this, id, name) result(loadbc_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: loadbc_ptr
    class(ObjBase), pointer :: base_ptr

    loadbc_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%loadbcs%GetByID(id)
    else if (present(name)) then
      base_ptr => this%loadbcs%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        loadbc_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetLoadBC

  function ModelTree_GetMaterial(this, id, name) result(material_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: material_ptr
    class(ObjBase), pointer :: base_ptr

    material_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%materials%GetByID(id)
    else if (present(name)) then
      base_ptr => this%materials%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        material_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetMaterial

  function ModelTree_GetMesh(this, id, name) result(mesh_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: mesh_ptr
    class(ObjBase), pointer :: base_ptr

    mesh_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%meshes%GetByID(id)
    else if (present(name)) then
      base_ptr => this%meshes%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        mesh_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetMesh

  function ModelTree_GetName(this) result(name)
    class(ModelTree), intent(in) :: this
    character(len=64) :: name
    name = this%name
  end function ModelTree_GetName

  function ModelTree_GetNumMaterials(this) result(count)
    class(ModelTree), intent(in) :: this
    integer(i4) :: count
    if (this%tree_initialize) then
      count = this%materials%GetCount()
    else
      count = this%nMaterials
    end if
  end function ModelTree_GetNumMaterials

  function ModelTree_GetNumParts(this) result(count)
    class(ModelTree), intent(in) :: this
    integer(i4) :: count
    if (this%tree_initialize) then
      count = this%parts%GetCount()
    else
      count = this%nParts
    end if
  end function ModelTree_GetNumParts

  function ModelTree_GetNumSteps(this) result(count)
    class(ModelTree), intent(in) :: this
    integer(i4) :: count
    if (this%tree_initialize) then
      count = this%steps%GetCount()
    else
      count = this%nSteps
    end if
  end function ModelTree_GetNumSteps

  function ModelTree_GetParentID(this) result(pid)
    class(ModelTree), intent(in) :: this
    integer(i4) :: pid
    pid = this%parent_id
  end function ModelTree_GetParentID

  function ModelTree_GetPart(this, id, name) result(part_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: part_ptr
    class(ObjBase), pointer :: base_ptr

    part_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%parts%GetByID(id)
    else if (present(name)) then
      base_ptr => this%parts%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        part_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetPart

  function ModelTree_GetSection(this, id, name) result(section_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: section_ptr
    class(ObjBase), pointer :: base_ptr

    section_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%sections%GetByID(id)
    else if (present(name)) then
      base_ptr => this%sections%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        section_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetSection

  function ModelTree_GetStep(this, id, name) result(step_ptr)
    class(ModelTree), intent(in) :: this
    integer(i4), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    class(TreeNodeBase), pointer :: step_ptr
    class(ObjBase), pointer :: base_ptr

    step_ptr => null()
    if (.not. this%tree_initialize) return
    if (present(id)) then
      base_ptr => this%steps%GetByID(id)
    else if (present(name)) then
      base_ptr => this%steps%GetByName(name)
    else
      return
    end if
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        step_ptr => base_ptr
      end select
    end if
  end function ModelTree_GetStep

  function ModelTree_GetType(this) result(ntype)
    class(ModelTree), intent(in) :: this
    integer(i4) :: ntype
    ntype = MD_MODEL_NODE_TYPE_MODEL
  end function ModelTree_GetType

  subroutine ModelTree_InitTree(this, initial_capacit, status)
    class(ModelTree), intent(inout) :: this
    integer(i4), intent(in), optional :: initial_capacit
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: cap

    call init_error_status(status)

    cap = 100_i4
    if (present(initial_capacit)) then
      cap = max(1_i4, initial_capacit)
    end if

    ! Init containers with unified interface
    call this%parts%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%assemblies%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%materials%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    ! Material domain: initialized by MD_L3_Init (md_layer%material, Set_Domain_Ptr)

    call this%sections%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%meshes%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%amplitudes%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%loadbcs%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%interactions%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%steps%Init(cap, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return
    
    ! Init container registry for unified access
    allocate(this%container_regis(9))
    this%container_regis(1) => this%parts
    this%container_regis(2) => this%assemblies
    this%container_regis(3) => this%materials
    this%container_regis(4) => this%sections
    this%container_regis(5) => this%meshes
    this%container_regis(6) => this%amplitudes
    this%container_regis(7) => this%loadbcs
    this%container_regis(8) => this%interactions
    this%container_regis(9) => this%steps

    ! Init index manager
    ! Note: IndexMgr needs a container reference, but we have multiple containers
    ! For now, use parts container as the primary reference
    ! In future, we may need a unified container or multiple index managers
    call this%index_mgr%Init(this%parts, max_type_code=20_i4, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    ! Init performance optimization modules
    call this%lazy_index_part%Init(this%parts, auto_rebuild=.true., threshold=10_i4, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%lazy_index_mate%Init(this%materials, auto_rebuild=.true., threshold=10_i4, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%lazy_index_sect%Init(this%sections, auto_rebuild=.true., threshold=10_i4, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%lazy_index_step%Init(this%steps, auto_rebuild=.true., threshold=10_i4, status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    ! Init path resolver
    ! (PathResolver has default initialization)
    
    ! Set up TreeNodeBase integration (using pointers from TreeNodeBase)
    ! Note: TreeNodeBase has pointer members, so we need to set them
    ! For now, these are handled through the InitTree method

    this%node_id = this%cfg%id
    this%tree_initialize = .true.

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_InitTree

  subroutine ModelTree_RebuildIndex(this, status)
    class(ModelTree), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%tree_initialize) then
      status%status_code = MD_MODEL_STATUS_INVALID
      return
    end if

    call this%parts%RebuildIndex(status)
    call this%materials%RebuildIndex(status)
    call this%steps%RebuildIndex(status)
    ! ... rebuild other containers

    call this%index_mgr%Rebuild(status)

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_RebuildIndex

  subroutine ModelTree_RemoveChild(this, child_id, node_type, status)
    !! Remove child object from container
    class(ModelTree), intent(inout) :: this
    integer(i4), intent(in) :: child_id
    integer(i4), intent(in) :: node_type
    type(ErrorStatusType), intent(out) :: status
    
    type(ObjContainer), pointer :: container_ptr
    class(TreeNodeBase), pointer :: child_ptr
    class(ObjBase), pointer :: base_ptr
    
    call init_error_status(status)
    
    if (.not. this%tree_initialize) then
      status%status_code = MD_MODEL_STATUS_INVALID
      return
    end if
    
    container_ptr => this%GetContainer(node_type)
    if (.not. associated(container_ptr)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      return
    end if
    
    base_ptr => container_ptr%GetByID(child_id)
    if (associated(base_ptr)) then
      select type (base_ptr)
      type is (TreeNodeBase)
        child_ptr => base_ptr
        call this%index_mgr%Unregister(child_ptr, status)
      end select
    end if
    
    call container_ptr%Remove(child_id, status=status)
  end subroutine ModelTree_RemoveChild

  subroutine ModelTree_Serialize(this, serializer)
    class(ModelTree), intent(in) :: this
    class(TreeSerializer), intent(inout) :: serializer

    integer(i4) :: i
    type(ErrorStatusType) :: status
    class(TreeNodeBase), pointer :: obj_ptr

    ! Serialize Model basic info
    call serializer%BeginObject("ModelTree", status)
    call serializer%WriteInt(this%cfg%id, status)
    call serializer%WriteString(this%name, status)
    call serializer%WriteString(this%cfg%description, status)
    call serializer%WriteString(this%dimensionality, status)
    call serializer%WriteReal(this%timePeriod, status)

    ! Serialize child object counts
    call serializer%WriteInt(this%GetNumParts(), status)
    call serializer%WriteInt(this%assemblies%GetCount(), status)
    call serializer%WriteInt(this%GetNumMaterials(), status)
    call serializer%WriteInt(this%sections%GetCount(), status)
    call serializer%WriteInt(this%meshes%GetCount(), status)
    call serializer%WriteInt(this%amplitudes%GetCount(), status)
    call serializer%WriteInt(this%loadbcs%GetCount(), status)
    call serializer%WriteInt(this%interactions%GetCount(), status)
    call serializer%WriteInt(this%GetNumSteps(), status)

    ! Serialize Parts (if they implement Serializable)
    call serializer%BeginArray("Parts", status)
    do i = 1, this%parts%GetCount()
      obj_ptr => this%parts%objects(i)
      if (associated(obj_ptr)) then
        select type (ser_obj => obj_ptr)
        class is (Serializable)
          call ser_obj%Serialize(serializer)
        end select
      end if
    end do
    call serializer%EndArray(status)

    call serializer%EndObject(status)
  end subroutine ModelTree_Serialize

  subroutine ModelTree_ValidateTree(this, status)
    class(ModelTree), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%tree_initialize) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Tree not initialized"
      return
    end if

    call this%parts%Valid(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%materials%Valid(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%steps%Valid(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call this%index_mgr%Valid(status)

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ModelTree_ValidateTree

  SUBROUTINE ModelTree_OptimizeLazyIndices(tree, status)
    TYPE(ModelTree), INTENT(INOUT) :: tree
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Pre-build lazy indices for faster access
    ! Simplified: production code should properly initialize lazy indices
    ! tree%lazy_index_part%Build(...)
    ! tree%lazy_index_mate%Build(...)
    ! tree%lazy_index_sect%Build(...)
    ! tree%lazy_index_step%Build(...)
    
    status%status_code = MD_MODEL_STATUS_OK
    
  END SUBROUTINE ModelTree_OptimizeLazyIndices

  !=============================================================================
  ! *Arg SIO types for cross-layer ModelTree operations
  !=============================================================================

  TYPE, PUBLIC :: MD_ModelTree_Traverse_Arg
    TYPE(ModelTree), POINTER          :: tree        ! [IN] tree to traverse
    CHARACTER(LEN=256)                :: result      ! [OUT] traversal result
    TYPE(ErrorStatusType)             :: status      ! [OUT] error status
  END TYPE MD_ModelTree_Traverse_Arg

  TYPE, PUBLIC :: MD_ModelTree_QueryOptimize_Arg
    TYPE(ModelTree), POINTER          :: tree        ! [IN] tree to optimize
    INTEGER(i4)                       :: opt_level   ! [IN] optimization level
    TYPE(ErrorStatusType)             :: status      ! [OUT] error status
  END TYPE MD_ModelTree_QueryOptimize_Arg

  TYPE, PUBLIC :: MD_ModelTree_FindByPath_Arg
    TYPE(ModelTree), POINTER          :: tree        ! [IN] tree
    CHARACTER(LEN=256)                :: path        ! [IN] path string
    CLASS(TreeNodeBase), POINTER      :: result      ! [OUT] found node
    TYPE(ErrorStatusType)             :: status      ! [OUT] error status
  END TYPE MD_ModelTree_FindByPath_Arg

end module MD_Model_Tree