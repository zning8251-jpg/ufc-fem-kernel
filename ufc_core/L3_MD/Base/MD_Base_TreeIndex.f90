!===============================================================================
! MODULE:  MD_Base_TreeIndex
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Impl (tree index management)
! BRIEF:   Tree node, path resolution, and index management for model
!          definition. TreeNodeBase, PathResolver, LazyIndexMgr, MemPool.
!===============================================================================
!   Tree, path, and index management for model definition layer. Merged from
!   MD_Base_Tree_Core (tree node management), MD_Base_Path_Core (path resolution),
!   MD_Base_Index_Mgr (index management). Provides tree node base class (TreeNodeBase),
!   path components and path resolver (PathComponents, PathResolver), lazy index manager
!   (LazyIndexMgr), memory pool (MemPool), batch operation manager (BatchOpMgr), index
!   manager (IndexMgr), ID list (IDList), parent-child map (ParentChildMap), node type
!   enumeration (TreeNodeType). Supports hierarchical tree structures, path-based object
!   access, lazy index rebuilding, memory pooling, batch operations, and efficient parent-child
!   relationship management.
!
! Theory chain:
!   Tree structure: Hierarchical tree of nodes with parent-child relationships. Each node
!   has ID, type, parent ID, active/visible flags. Tree node base class (TreeNodeBase)
!   extends CoreBase and provides deferred procedures for GetID, GetName, GetType,
!   GetParentID. Path resolution: Path strings parsed into components (PathComponents),
!   path resolver (PathResolver) handles parsing, validation, normalization, joining.
!   Abstract path resolver (AbstractPathRes) provides interface for path parsing. Lazy
!   indexing: Index marked dirty on changes, rebuilt automatically when threshold reached
!   or manually forced. Memory pooling: Pre-allocated pool of objects for efficient
!   allocation/deallocation. Batch operations: Batch mode defers index updates until
!   batch end, improving performance for bulk operations. Index management: Index manager
!   (IndexMgr) extends BaseManager, maintains type-based indices, parent-child mappings,
!   supports finding by ID/name/type, finding children, updating parent relationships.
!   ID list: Dynamic list of IDs with add/remove/contains operations. Parent-child map:
!   Maps parent IDs to child ID lists for efficient child lookup. Node types: Enumeration
!   of node types (MODEL, PART, ASSEM, MATER, SECTI, MESH, AMPLI, LOADB, INTER, STEP,
!   NODE, ELEME, NSET, ELSET, SURFA). Ref: Tree data structures, path resolution algorithms,
!   lazy evaluation, memory pooling, batch processing, index structures.
!
! Logic chain:
!   Tree operations: TreeNodeBase.Init -> SetParentID -> GetPath/GetFullPath -> ResolvePath
!   -> ParsePath -> Serialize/Deserialize -> SetIndexMgr -> UpdateIndex -> SetBatchMgr ->
!   BeginBatch/EndBatch -> SetPathResolver -> Valid. Path operations: PathComponents.Init
!   -> ParsePath (via PathResolver) -> GetComponent -> IsAbsolute -> Clear. PathResolver:
!   ParsePath -> ResolvePath -> BuildPath -> ValidatePath -> NormalizePath -> JoinPath ->
!   ParseComponent. Lazy index: LazyIndexMgr.Init -> MarkDirty -> RebuildIfDirty (auto or
!   manual) -> ForceRebuild -> IsDirty -> SetAutoRebuild -> SetRebuildThreshold. Memory pool:
!   MemPool.Init -> Allocate -> Deallocate -> GetFreeCount/GetPoolSize -> Clear -> Destroy.
!   Batch operations: BatchOpMgr.BeginBatch -> IncrementBatch -> EndBatch -> IsBatchMode ->
!   SetMaxBatchSize. Index manager: IndexMgr.Init -> Reg -> FindByID/FindByName/FindByType
!   -> FindChildren -> UpdateParent -> Rebuild -> Clear -> Unregister -> Clean -> Finalize.
!   ID list: IDList.Init -> Add -> Remove -> Contains -> GetCount -> GetIDs -> Clear.
!   Parent-child map: ParentChildMap.Init -> AddChild -> RemoveChild -> GetChildren ->
!   GetCount -> Clear. Dependency: L3_MD Base -> L1 IF (Error API, Precision), L3_MD Base
!   (ObjModel).
!
! Computation chain:
!   PathComponents: Init -> Allocate components array -> Clear -> GetCount (return count)
!   -> GetComponent (return component at index) -> IsAbsolute (return is_absolute flag).
!   PathResolver: ParsePath -> Split path by separator -> Create PathComponents -> Set
!   is_absolute if starts with separator. ResolvePath -> ParsePath -> Resolve each component
!   -> Build full path. BuildPath -> Join components with separator -> Handle absolute/
!   relative paths. ValidatePath -> Check for invalid characters -> Check length -> Return
!   validation result. NormalizePath -> Remove redundant separators -> Resolve ".." and "."
!   -> Return normalized path. JoinPath -> Trim paths -> Remove trailing/leading separators
!   -> Join with separator. ParseComponent -> Find separator -> Extract type_name and name.
!   LazyIndexMgr: Init -> Set container pointer -> Set auto_rebuild flag -> Set threshold.
!   MarkDirty -> Set index_dirty flag -> Increment dirty_count -> Auto rebuild if threshold
!   reached. RebuildIfDirty -> Check index_dirty -> Rebuild index if dirty -> Clear dirty
!   flag. ForceRebuild -> Rebuild index -> Clear dirty flag. MemPool: Init -> Allocate free_list
!   -> Initialize pool. Allocate -> Get from free_list -> Return index. Deallocate -> Add to
!   free_list -> Increment free_count. BatchOpMgr: BeginBatch -> Set batch_mode flag ->
!   Reset batch_count. IncrementBatch -> Increment batch_count -> Mark index dirty if max
!   reached. EndBatch -> Clear batch_mode -> Rebuild index if dirty. IndexMgr: Init -> Allocate
!   type_index arrays -> Initialize parent_child_map. Reg -> Add to container -> Update type_index
!   -> Update parent_child_map -> Mark index dirty. FindByID -> Search container. FindByName
!   -> Search container by name. FindByType -> Search type_index. FindChildren -> Query
!   parent_child_map. UpdateParent -> Update parent_child_map -> Mark index dirty. Rebuild ->
!   Clear type_index -> Rebuild from container -> Rebuild parent_child_map -> Clear dirty flag.
!
! Data chain:
!   Input: Path strings, node IDs, node types, parent IDs, container pointers, batch sizes,
!   rebuild thresholds, component strings, type names, names. Output: PathComponents objects,
!   resolved paths, normalized paths, node handles, child ID lists, index statistics, memory
!   pool indices, batch operation status. State: PathComponents state (count, components array,
!   is_absolute), TreeNodeBase state (node_id, node_type, parent_id, is_active, is_visible,
!   index_mgr, lazy_index, path_resolver, batch_mgr), LazyIndexMgr state (container pointer,
!   index_dirty, auto_rebuild, rebuild_thresho, dirty_count), MemPool state (pool_size,
!   free_count, free_list, init), BatchOpMgr state (batch_mode, batch_count, max_batch_size,
!   index_dirty), IndexMgr state (container pointer, type_index arrays, max_type_code,
!   parent_child_in, index_dirty), IDList state (count, capacity, ids array), ParentChildMap
!   state (count, capacity, entries array).
!
! Data structure:
!   Container path: Base (tree/index/path management).
!   - Desc: PathComponents (path component descriptor), TreeNodeType (node type descriptor).
!   - Algo: PathResolver (path resolution algorithm), LazyIndexMgr (lazy indexing algorithm),
!   BatchOpMgr (batch operation algorithm).
!   - Ctx: TreeNodeBase (tree node context), IndexMgr (index manager context), MemPool
!   (memory pool context).
!   - State: TreeNodeBase state (node_id, node_type, parent_id, is_active, is_visible),
!   LazyIndexMgr state (index_dirty, dirty_count), MemPool state (free_count, free_list),
!   BatchOpMgr state (batch_mode, batch_count), IndexMgr state (index_dirty), IDList state
!   (count, ids), ParentChildMap state (count, entries).
!   Supporting types: AbstractPathRes (abstract path resolver interface), ParentChildEntry
!   (parent-child entry), GetNodeID_IF/GetNodeName_IF/GetNodeType_IF/GetParentID_IF (abstract
!   interfaces), ParsePath_IF (path parsing interface).
!
! Three-step mapping:
!   Tree operations: Step level (hierarchical structure management).
!   Path resolution: Step level (path-based object access).
!   Index management: Step level (efficient object lookup).
!   Lazy indexing: Step level (performance optimization).
!   Memory pooling: Step level (memory management optimization).
!   Batch operations: Step level (bulk operation optimization).
!
! Contents (A-Z):
!   Constants: MD_MODEL_MAX_COMPONENTS, MD_MODEL_MAX_PATH_LENGTH, MD_MODEL_NODE_TYPE_AMPLI, MD_MODEL_NODE_TYPE_ASSEM,
!     MD_MODEL_NODE_TYPE_ELEME, MD_MODEL_NODE_TYPE_ELSET, MD_MODEL_NODE_TYPE_INTER, MD_MODEL_NODE_TYPE_LOADB, MD_MODEL_NODE_TYPE_MATER,
!     MD_MODEL_NODE_TYPE_MESH, MD_MODEL_NODE_TYPE_MODEL, MD_MODEL_NODE_TYPE_NODE, MD_MODEL_NODE_TYPE_NSET, MD_MODEL_NODE_TYPE_PART,
!     MD_MODEL_NODE_TYPE_SECTI, MD_MODEL_NODE_TYPE_STEP, MD_MODEL_NODE_TYPE_SURFA, PATH_SEPARATOR
!   Functions: BatchOp_IsBatchMode, IDList_Contains, IDList_GetCount, IndexMgr_Find,
!     IndexMgr_FindByID, IndexMgr_FindByName, IndexMgr_FindByType, IndexMgr_GetCount,
!     LazyIndex_IsDirty, MemPool_GetFreeCount, MemPool_GetPoolSize, ParentChildMap_GetCount,
!     PathComponents_GetComponent, PathComponents_GetCount, PathComponents_IsAbsolute,
!     Resolver_BuildPath, Resolver_JoinPath, Resolver_NormalizePath, Resolver_ValidatePath,
!     TreeNode_GetFullPath, TreeNode_GetPath, TreeNode_IsActive, TreeNode_IsVisible,
!     TreeNode_Valid, TreeNodeType_GetCode, TreeNodeType_IsAmplitude, TreeNodeType_IsAssembly,
!     TreeNodeType_IsElemSet, TreeNodeType_IsElement, TreeNodeType_IsInteraction,
!     TreeNodeType_IsLoadBC, TreeNodeType_IsMaterial, TreeNodeType_IsMesh, TreeNodeType_IsModel,
!     TreeNodeType_IsNode, TreeNodeType_IsNodeSet, TreeNodeType_IsPart, TreeNodeType_IsSection,
!     TreeNodeType_IsStep, TreeNodeType_IsSurface
!   Subroutines: BatchOp_BeginBatch, BatchOp_EndBatch, BatchOp_IncrementBatch,
!     BatchOp_SetMaxBatchSize, IDList_Add, IDList_Clear, IDList_Init, IDList_Remove,
!     IndexMgr_Clean, IndexMgr_Clear, IndexMgr_Create, IndexMgr_Delete, IndexMgr_Finalize,
!     IndexMgr_FindChildren, IndexMgr_Init, IndexMgr_List, IndexMgr_Rebuild, IndexMgr_Reg,
!     IndexMgr_Unregister, IndexMgr_UpdateParent, IndexMgr_ValidateConsistency,
!     LazyIdx_SetRebuildThresh, LazyIndex_ForceRebuild, LazyIndex_Init, LazyIndex_MarkDirty,
!     LazyIndex_RebuildIfDirty, LazyIndex_SetAutoRebuild, MemPool_Allocate, MemPool_Clear,
!     MemPool_Deallocate, MemPool_Destroy, MemPool_Init, ParentChildMap_AddChild,
!     ParentChildMap_Clear, ParentChildMap_Init, ParentChildMap_RemoveChild,
!     PathComponents_Clear, PathComponents_Init, Resolver_ParseComponent, Resolver_ParsePath,
!     Resolver_ResolvePath, TreeNode_BeginBatch, TreeNode_Deserialize, TreeNode_EndBatch,
!     TreeNode_ParsePath, TreeNode_ResolvePath, TreeNode_Serialize, TreeNode_SetActive,
!     TreeNode_SetBatchMgr, TreeNode_SetIndexMgr, TreeNode_SetLazyIndex, TreeNode_SetParentID,
!     TreeNode_SetPathResolver, TreeNode_SetVisible, TreeNodeType_Init, TreeNodeType_SetCode
!   Types: AbstractPathRes, BatchOpMgr, IDList, IndexMgr, LazyIndexMgr, MemPool,
!     ParentChildMap, PathComponents, PathResolver, Serializable, TreeDeserializer,
!     TreeNodeBase, TreeNodeType, TreeSerializer
!
! Notes:
!   Merged module: MD_Base_Tree_Core + MD_Base_Path_Core + MD_Base_Index_Mgr. Tree structure:
!   Hierarchical tree of nodes with parent-child relationships. Path resolution: Path strings
!   parsed into components, resolver handles parsing, validation, normalization, joining.
!   Lazy indexing: Index marked dirty on changes, rebuilt automatically when threshold reached.
!   Memory pooling: Pre-allocated pool for efficient allocation/deallocation. Batch operations:
!   Batch mode defers index updates until batch end. Index management: Type-based indices,
!   parent-child mappings, efficient lookup by ID/name/type. ID list: Dynamic list of IDs.
!   Parent-child map: Maps parent IDs to child ID lists. Node types: Enumeration of 15 node
!   types. Logic/Computation chain diagrams: see MD_Base_TreeIndex_Core_Chains.md
!
! Status: CORE | Last verified: 2026-03-02
! Theory: N/A
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Model | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Model/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Model | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Base_TreeIndex
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
    USE IF_Prec_Core, ONLY: i4, i8, wp
    USE MD_Base_ObjModel, ONLY: CoreBase, ObjBase, BaseManager, ObjContainer, MD_MODEL_CAT_DESC, MD_MODEL_CAT_STATE, MD_MODEL_CAT_ALGO, MD_MODEL_CAT_CTX, &
        Serializable, TreeSerializer, TreeDeserializer

    IMPLICIT NONE
    PRIVATE

    ! PUBLIC constants (A-Z)
    PUBLIC :: MD_MODEL_MAX_COMPONENTS, MD_MODEL_MAX_PATH_LENGTH
    PUBLIC :: MD_MODEL_NODE_TYPE_AMPLI, MD_MODEL_NODE_TYPE_ASSEM, MD_MODEL_NODE_TYPE_ELEME, MD_MODEL_NODE_TYPE_ELSET
    PUBLIC :: MD_MODEL_NODE_TYPE_INTER, MD_MODEL_NODE_TYPE_LOADB, MD_MODEL_NODE_TYPE_MATER, MD_MODEL_NODE_TYPE_MESH
    PUBLIC :: MD_MODEL_NODE_TYPE_MODEL, MD_MODEL_NODE_TYPE_NODE, MD_MODEL_NODE_TYPE_NSET, MD_MODEL_NODE_TYPE_PART
    PUBLIC :: MD_MODEL_NODE_TYPE_SECTI, MD_MODEL_NODE_TYPE_STEP, MD_MODEL_NODE_TYPE_SURFA, PATH_SEPARATOR

    ! PUBLIC types (A-Z)
    PUBLIC :: AbstractPathRes, BatchOpMgr, IDList, IndexMgr, LazyIndexMgr
    PUBLIC :: MemPool, ParentChildMap, PathComponents, PathResolver
    PUBLIC :: Serializable, TreeDeserializer, TreeNodeBase, TreeNodeType, TreeSerializer

  ! ===================================================================
  ! Path Constants (Path_Core)
  ! ===================================================================
  integer(i4), parameter :: MD_MODEL_MAX_PATH_LENGTH = 512_i4
  integer(i4), parameter :: MD_MODEL_MAX_COMPONENTS = 32_i4
  character(len=1), parameter :: PATH_SEPARATOR = '/'

  ! ===================================================================
  ! Path Components Type (Path_Core)
  ! ===================================================================
  type, public :: PathComponents
    integer(i4) :: count = 0_i4
    character(len=64), allocatable :: components(:)
    logical :: is_absolute = .false.
  contains
    procedure, public :: Init => PathComponents_Init
    procedure, public :: Clear => PathComponents_Clear
    procedure, public :: GetCount => PathComponents_GetCount
    procedure, public :: GetComponent => PathComponents_GetComponent
    procedure, public :: IsAbsolute => PathComponents_IsAbsolute
  end type PathComponents

  ! ===================================================================
  ! Abstract Path Resolver (Path_Core)
  ! ===================================================================
  type, abstract, public :: AbstractPathRes
  contains
    procedure(ParsePath_IF), deferred, public :: ParsePath
  end type AbstractPathRes

  abstract interface
    subroutine ParsePath_IF(this, path_str, components, status)
      import :: AbstractPathRes, PathComponents, ErrorStatusType
      class(AbstractPathRes), intent(in) :: this
      character(len=*), intent(in) :: path_str
      type(PathComponents), intent(out) :: components
      type(ErrorStatusType), intent(out) :: status
    end subroutine ParsePath_IF
  end interface

  ! ===================================================================
  ! Path Resolver Type (merged from MD_Base_TreeIndex_Mgr)
  ! ===================================================================
  type, public, extends(AbstractPathRes) :: PathResolver
    character(len=1) :: separator = PATH_SEPARATOR
    logical :: case_sensitive = .true.
  contains
    procedure, public :: ParsePath => Resolver_ParsePath
    procedure, public :: ResolvePath => Resolver_ResolvePath
    procedure, public :: BuildPath => Resolver_BuildPath
    procedure, public :: ValidatePath => Resolver_ValidatePath
    procedure, public :: NormalizePath => Resolver_NormalizePath
    procedure, public :: JoinPath => Resolver_JoinPath
    procedure, public :: ParseComponent => Resolver_ParseComponent
  end type PathResolver

  ! ===================================================================
  ! Node Type Constants (Tree_Core)
  ! ===================================================================
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_MODEL = 1_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_PART = 2_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_ASSEM = 3_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_MATER = 4_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_SECTI = 5_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_MESH = 6_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_AMPLI = 7_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_LOADB = 8_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_INTER = 9_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_STEP = 10_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_NODE = 11_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_ELEME = 12_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_NSET = 13_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_ELSET = 14_i4
  integer(i4), parameter :: MD_MODEL_NODE_TYPE_SURFA = 15_i4

  ! ===================================================================
  ! Lazy Index Manager (Tree_Core)
  ! ===================================================================
  type, public :: LazyIndexMgr
    type(ObjContainer), pointer :: container => null()
    logical :: index_dirty = .false.
    logical :: auto_rebuild = .true.
    integer(i4) :: rebuild_thresho = 10_i4
    integer(i4) :: dirty_count = 0_i4
  contains
    procedure, public :: Init => LazyIndex_Init
    procedure, public :: MarkDirty => LazyIndex_MarkDirty
    procedure, public :: RebuildIfDirty => LazyIndex_RebuildIfDirty
    procedure, public :: ForceRebuild => LazyIndex_ForceRebuild
    procedure, public :: IsDirty => LazyIndex_IsDirty
    procedure, public :: SetAutoRebuild => LazyIndex_SetAutoRebuild
    procedure, public :: SetRebuildThreshold => LazyIdx_SetRebuildThresh
  end type LazyIndexMgr

  ! ===================================================================
  ! Memory Pool (Tree_Core)
  ! ===================================================================
  type, public :: MemPool
    integer(i4) :: pool_size = 100_i4
    integer(i4) :: free_count = 0_i4
    integer(i4), allocatable :: free_list(:)
    LOGICAL :: is_init = .false.
  contains
    procedure, public :: Init => MemPool_Init
    procedure, public :: Destroy => MemPool_Destroy
    procedure, public :: Allocate => MemPool_Allocate
    procedure, public :: Deallocate => MemPool_Deallocate
    procedure, public :: GetFreeCount => MemPool_GetFreeCount
    procedure, public :: GetPoolSize => MemPool_GetPoolSize
    procedure, public :: Clear => MemPool_Clear
  end type MemPool

  ! ===================================================================
  ! Batch Operation Manager (Tree_Core)
  ! ===================================================================
  type, public :: BatchOpMgr
    logical :: batch_mode = .false.
    integer(i4) :: batch_count = 0_i4
    integer(i4) :: max_batch_size = 1000_i4
    logical :: index_dirty = .false.
  contains
    procedure, public :: BeginBatch => BatchOp_BeginBatch
    procedure, public :: EndBatch => BatchOp_EndBatch
    procedure, public :: IsBatchMode => BatchOp_IsBatchMode
    procedure, public :: IncrementBatch => BatchOp_IncrementBatch
    procedure, public :: SetMaxBatchSize => BatchOp_SetMaxBatchSize
  end type BatchOpMgr

  ! ===================================================================
  ! Tree Node Base Class (Tree_Core)
  ! Type defined first; abstract interfaces follow (both in same module).
  ! ===================================================================
  type, abstract, public, extends(CoreBase) :: TreeNodeBase
    integer(i4) :: node_id = 0_i4
    integer(i4) :: node_type = 0_i4
    integer(i4) :: parent_id = 0_i4
    logical :: is_active = .true.
    logical :: is_visible = .true.

    class(*), pointer :: index_mgr => null()
    type(LazyIndexMgr), pointer :: lazy_index => null()
    class(AbstractPathRes), pointer :: path_resolver => null()
    type(BatchOpMgr), pointer :: batch_mgr => null()
  contains
    procedure(GetNodeID_IF), deferred :: GetID
    procedure(GetNodeName_IF), deferred :: GetName
    procedure(GetNodeType_IF), deferred :: GetType
    procedure(GetParentID_IF), deferred :: GetParentID

    procedure, public :: SetParentID => TreeNode_SetParentID
    procedure, public :: IsActive => TreeNode_IsActive
    procedure, public :: IsVisible => TreeNode_IsVisible
    procedure, public :: SetActive => TreeNode_SetActive
    procedure, public :: SetVisible => TreeNode_SetVisible

    procedure, public :: GetPath => TreeNode_GetPath
    procedure, public :: GetFullPath => TreeNode_GetFullPath
    procedure, public :: ResolvePath => TreeNode_ResolvePath
    procedure, public :: ParsePath => TreeNode_ParsePath

    procedure, public :: Serialize => TreeNode_Serialize
    procedure, public :: Deserialize => TreeNode_Deserialize

    procedure, public :: SetIndexMgr => TreeNode_SetIndexMgr
    procedure, public :: SetLazyIndex => TreeNode_SetLazyIndex
    procedure, public :: UpdateIndex => TreeNode_UpdateIndex

    procedure, public :: SetBatchMgr => TreeNode_SetBatchMgr
    procedure, public :: BeginBatch => TreeNode_BeginBatch
    procedure, public :: EndBatch => TreeNode_EndBatch

    procedure, public :: SetPathResolver => TreeNode_SetPathResolver

    procedure, public :: Valid => TreeNode_Valid  ! Overrides ObjBase%Valid; arg must be 'self'
  end type TreeNodeBase

  ! ===================================================================
  ! Tree Abstract Interfaces (Tree_Core) - defined after TreeNodeBase
  ! ===================================================================
  abstract interface
    function GetNodeID_IF(this) result(id)
      import :: TreeNodeBase, i4
      class(TreeNodeBase), intent(in) :: this
      integer(i4) :: id
    end function GetNodeID_IF

    function GetNodeName_IF(this) result(name)
      import :: TreeNodeBase
      class(TreeNodeBase), intent(in) :: this
      character(len=64) :: name
    end function GetNodeName_IF

    function GetNodeType_IF(this) result(ntype)
      import :: TreeNodeBase, i4
      class(TreeNodeBase), intent(in) :: this
      integer(i4) :: ntype
    end function GetNodeType_IF

    function GetParentID_IF(this) result(pid)
      import :: TreeNodeBase, i4
      class(TreeNodeBase), intent(in) :: this
      integer(i4) :: pid
    end function GetParentID_IF
  end interface

  ! ===================================================================
  ! Node Type Enumeration (Tree_Core)
  ! ===================================================================
  type, public :: TreeNodeType
    integer(i4) :: type_code = 0_i4
  contains
    procedure, public :: Init => TreeNodeType_Init
    procedure, public :: GetCode => TreeNodeType_GetCode
    procedure, public :: SetCode => TreeNodeType_SetCode
    procedure, public :: IsModel => TreeNodeType_IsModel
    procedure, public :: IsPart => TreeNodeType_IsPart
    procedure, public :: IsAssembly => TreeNodeType_IsAssembly
    procedure, public :: IsMaterial => TreeNodeType_IsMaterial
    procedure, public :: IsSection => TreeNodeType_IsSection
    procedure, public :: IsMesh => TreeNodeType_IsMesh
    procedure, public :: IsAmplitude => TreeNodeType_IsAmplitude
    procedure, public :: IsLoadBC => TreeNodeType_IsLoadBC
    procedure, public :: IsInteraction => TreeNodeType_IsInteraction
    procedure, public :: IsStep => TreeNodeType_IsStep
    procedure, public :: IsNode => TreeNodeType_IsNode
    procedure, public :: IsElement => TreeNodeType_IsElement
    procedure, public :: IsNodeSet => TreeNodeType_IsNodeSet
    procedure, public :: IsElemSet => TreeNodeType_IsElemSet
    procedure, public :: IsSurface => TreeNodeType_IsSurface
  end type TreeNodeType

  ! ===================================================================
  ! ID List Type (Index_Mgr)
  ! ===================================================================
  type, public :: IDList
    integer(i4) :: count = 0_i4
    integer(i4) :: capacity = 0_i4
    integer(i4), allocatable :: ids(:)
  contains
    procedure, public :: Init => IDList_Init
    procedure, public :: Add => IDList_Add
    procedure, public :: Remove => IDList_Remove
    procedure, public :: Contains => IDList_Contains
    procedure, public :: Clear => IDList_Clear
    procedure, public :: GetCount => IDList_GetCount
    procedure, public :: GetIDs => IDList_GetIDs
  end type IDList

  ! ===================================================================
  ! Parent-Child Map (Index_Mgr)
  ! ===================================================================
  type :: ParentChildEntry
    integer(i4) :: parent_id = 0_i4
    type(IDList) :: child_ids
  end type ParentChildEntry

  type, public :: ParentChildMap
    integer(i4) :: count = 0_i4
    integer(i4) :: capacity = 0_i4
    type(ParentChildEntry), allocatable :: entries(:)
  contains
    procedure, public :: Init => ParentChildMap_Init
    procedure, public :: AddChild => ParentChildMap_AddChild
    procedure, public :: RemoveChild => ParentChildMap_RemoveChild
    procedure, public :: GetChildren => ParentChildMap_GetChildren
    procedure, public :: Clear => ParentChildMap_Clear
    procedure, public :: GetCount => ParentChildMap_GetCount
    procedure, private :: FindEntry => ParentChildMap_FindEntry
    procedure, private :: Expand => ParentChildMap_Expand
  end type ParentChildMap

  ! ===================================================================
  ! Index Manager (Index_Mgr)
  ! ===================================================================
    TYPE, PUBLIC, EXTENDS(BaseManager) :: IndexMgr
        TYPE(ObjContainer), POINTER :: container => null()
        TYPE(IDList), ALLOCATABLE :: type_index(:)
        INTEGER(i4) :: max_type_code = 0_i4
        TYPE(ParentChildMap) :: parent_child_in
        LOGICAL :: index_dirty = .FALSE.
    CONTAINS
        PROCEDURE :: Init => IndexMgr_Init
        PROCEDURE :: Finalize => IndexMgr_Finalize
        PROCEDURE :: Create => IndexMgr_Create
        PROCEDURE :: Delete => IndexMgr_Delete
        PROCEDURE :: Find => IndexMgr_Find
        PROCEDURE :: Get => IndexMgr_Get
        PROCEDURE :: GetCount => IndexMgr_GetCount
        PROCEDURE :: List => IndexMgr_List
        PROCEDURE :: Valid => IndexMgr_Valid
        PROCEDURE :: ValidateConsistency => IndexMgr_ValidateConsistency
        PROCEDURE :: GetStatistics => IndexMgr_GetStatistics
        PROCEDURE, PUBLIC :: Clean => IndexMgr_Clean
        PROCEDURE, PUBLIC :: Reg => IndexMgr_Reg
        PROCEDURE, PUBLIC :: Unregister => IndexMgr_Unregister
        PROCEDURE, PUBLIC :: FindByID => IndexMgr_FindByID
        PROCEDURE, PUBLIC :: FindByName => IndexMgr_FindByName
        PROCEDURE, PUBLIC :: FindByType => IndexMgr_FindByType
        PROCEDURE, PUBLIC :: FindChildren => IndexMgr_FindChildren
        PROCEDURE, PUBLIC :: UpdateParent => IndexMgr_UpdateParent
        PROCEDURE, PUBLIC :: Rebuild => IndexMgr_Rebuild
        PROCEDURE, PUBLIC :: Clear => IndexMgr_Clear
    END TYPE IndexMgr

contains

  ! ===================================================================
  ! PathComponents Methods
  ! ===================================================================
  subroutine PathComponents_Init(this, max_components, status)
    class(PathComponents), intent(out) :: this
    integer(i4), intent(in), optional :: max_components
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: max_comp

    call init_error_status(status)

    max_comp = MD_MODEL_MAX_COMPONENTS
    if (present(max_components)) then
      max_comp = max(1_i4, max_components)
    end if

    this%count = 0_i4
    this%is_absolute = .false.
    allocate(this%components(max_comp))
    this%components = ""

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine PathComponents_Init

  subroutine PathComponents_Clear(this, status)
    class(PathComponents), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%count = 0_i4
    this%is_absolute = .false.
    if (allocated(this%components)) then
      this%components = ""
    end if
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine PathComponents_Clear

  function PathComponents_GetCount(this) result(count)
    class(PathComponents), intent(in) :: this
    integer(i4) :: count
    count = this%count
  end function PathComponents_GetCount

  function PathComponents_GetComponent(this, index) result(component)
    class(PathComponents), intent(in) :: this
    integer(i4), intent(in) :: index
    character(len=64) :: component

    component = ""
    if (index >= 1 .and. index <= this%count) then
      if (allocated(this%components)) then
        component = this%components(index)
      end if
    end if
  end function PathComponents_GetComponent

  function PathComponents_IsAbsolute(this) result(is_abs)
    class(PathComponents), intent(in) :: this
    logical :: is_abs
    is_abs = this%is_absolute
  end function PathComponents_IsAbsolute

  ! ===================================================================
  ! LazyIndexMgr Methods
  ! ===================================================================
  subroutine LazyIndex_Init(this, container_ptr, auto_rebuild, threshold, status)
    class(LazyIndexMgr), intent(out) :: this
    type(ObjContainer), pointer, intent(in) :: container_ptr
    logical, intent(in), optional :: auto_rebuild
    integer(i4), intent(in), optional :: threshold
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. associated(container_ptr)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Container pointer is not associated"
      return
    end if

    this%container => container_ptr
    this%index_dirty = .false.
    this%dirty_count = 0_i4

    this%auto_rebuild = .true.
    if (present(auto_rebuild)) then
      this%auto_rebuild = auto_rebuild
    end if

    this%rebuild_thresho = 10_i4
    if (present(threshold)) then
      this%rebuild_thresho = max(1_i4, threshold)
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine LazyIndex_Init

  subroutine LazyIndex_MarkDirty(this)
    class(LazyIndexMgr), intent(inout) :: this
    this%index_dirty = .true.
    this%dirty_count = this%dirty_count + 1_i4

    if (this%auto_rebuild .and. this%dirty_count >= this%rebuild_thresho) then
      call this%RebuildIfDirty()
    end if
  end subroutine LazyIndex_MarkDirty

  subroutine LazyIndex_RebuildIfDirty(this, status)
    class(LazyIndexMgr), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    if (present(status)) then
      call init_error_status(status)
    else
      call init_error_status(local_status)
    end if

    if (.not. this%index_dirty) then
      if (present(status)) then
        status%status_code = MD_MODEL_STATUS_OK
      end if
      return
    end if

    if (.not. associated(this%container)) then
      if (present(status)) then
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "Container not associated"
      end if
      return
    end if

    call this%container%RebuildIndex(local_status)
    if (local_status%status_code == MD_MODEL_STATUS_OK) then
      this%index_dirty = .false.
      this%dirty_count = 0_i4
    end if

    if (present(status)) then
      status = local_status
    end if
  end subroutine LazyIndex_RebuildIfDirty

  subroutine LazyIndex_ForceRebuild(this, status)
    class(LazyIndexMgr), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. associated(this%container)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Container not associated"
      return
    end if

    call this%container%RebuildIndex(status)
    if (status%status_code == MD_MODEL_STATUS_OK) then
      this%index_dirty = .false.
      this%dirty_count = 0_i4
    end if
  end subroutine LazyIndex_ForceRebuild

  function LazyIndex_IsDirty(this) result(is_dirty)
    class(LazyIndexMgr), intent(in) :: this
    logical :: is_dirty
    is_dirty = this%index_dirty
  end function LazyIndex_IsDirty

  subroutine LazyIndex_SetAutoRebuild(this, enable)
    class(LazyIndexMgr), intent(inout) :: this
    logical, intent(in) :: enable
    this%auto_rebuild = enable
  end subroutine LazyIndex_SetAutoRebuild

  subroutine LazyIdx_SetRebuildThresh(this, threshold)
    class(LazyIndexMgr), intent(inout) :: this
    integer(i4), intent(in) :: threshold
    this%rebuild_thresho = max(1_i4, threshold)
  end subroutine LazyIdx_SetRebuildThresh

  ! ===================================================================
  ! MemPool Methods
  ! ===================================================================
  subroutine MemPool_Init(this, pool_size, status)
    class(MemPool), intent(out) :: this
    integer(i4), intent(in), optional :: pool_size
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: size_val, i

    call init_error_status(status)

    size_val = 100_i4
    if (present(pool_size)) then
      size_val = max(1_i4, pool_size)
    end if

    this%pool_size = size_val
    this%free_count = size_val
    allocate(this%free_list(size_val), stat=status%status_code)
    if (status%status_code /= MD_MODEL_STATUS_OK) then
      status%message = "Failed to allocate free list"
      return
    end if

    do i = 1, size_val
      this%free_list(i) = i
    end do

    this%is_init = .true.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine MemPool_Init

  subroutine MemPool_Destroy(this, status)
    class(MemPool), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (allocated(this%free_list)) then
      deallocate(this%free_list)
    end if

    this%pool_size = 0_i4
    this%free_count = 0_i4
    this%is_init = .false.

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine MemPool_Destroy

  function MemPool_Allocate(this, status) result(index)
    class(MemPool), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: index

    call init_error_status(status)

    if (.not. this%is_init) then
      call this%Init(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) then
        index = 0_i4
        return
      end if
    end if

    if (this%free_count <= 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Memory pool exhausted"
      index = 0_i4
      return
    end if

    index = this%free_list(this%free_count)
    this%free_count = this%free_count - 1_i4

    status%status_code = MD_MODEL_STATUS_OK
  end function MemPool_Allocate

  subroutine MemPool_Deallocate(this, index, status)
    class(MemPool), intent(inout) :: this
    integer(i4), intent(in) :: index
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%is_init) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Memory pool not initialized"
      return
    end if

    if (index < 1 .or. index > this%pool_size) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Invalid index"
      return
    end if

    if (this%free_count >= this%pool_size) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Free list full"
      return
    end if

    this%free_count = this%free_count + 1_i4
    this%free_list(this%free_count) = index

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine MemPool_Deallocate

  function MemPool_GetFreeCount(this) result(count)
    class(MemPool), intent(in) :: this
    integer(i4) :: count
    count = this%free_count
  end function MemPool_GetFreeCount

  function MemPool_GetPoolSize(this) result(size)
    class(MemPool), intent(in) :: this
    integer(i4) :: size
    size = this%pool_size
  end function MemPool_GetPoolSize

  subroutine MemPool_Clear(this, status)
    class(MemPool), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%is_init) return

    this%free_count = this%pool_size
    do i = 1, this%pool_size
      this%free_list(i) = i
    end do

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine MemPool_Clear

  ! ===================================================================
  ! BatchOpMgr Methods
  ! ===================================================================
  subroutine BatchOp_BeginBatch(this, max_size)
    class(BatchOpMgr), intent(inout) :: this
    integer(i4), intent(in), optional :: max_size

    this%batch_mode = .true.
    this%batch_count = 0_i4
    this%index_dirty = .false.

    if (present(max_size)) then
      this%max_batch_size = max(1_i4, max_size)
    end if
  end subroutine BatchOp_BeginBatch

  subroutine BatchOp_EndBatch(this, rebuild_index, status)
    class(BatchOpMgr), intent(inout) :: this
    logical, intent(in), optional :: rebuild_index
    type(ErrorStatusType), intent(out), optional :: status

    logical :: do_rebuild

    if (present(status)) then
      call init_error_status(status)
    end if

    do_rebuild = .true.
    if (present(rebuild_index)) then
      do_rebuild = rebuild_index
    end if

    this%batch_mode = .false.
    this%batch_count = 0_i4

    if (do_rebuild .and. this%index_dirty) then
      this%index_dirty = .false.
    end if
  end subroutine BatchOp_EndBatch

  function BatchOp_IsBatchMode(this) result(is_batch)
    class(BatchOpMgr), intent(in) :: this
    logical :: is_batch
    is_batch = this%batch_mode
  end function BatchOp_IsBatchMode

  subroutine BatchOp_IncrementBatch(this)
    class(BatchOpMgr), intent(inout) :: this
    this%batch_count = this%batch_count + 1_i4
    this%index_dirty = .true.

    if (this%batch_count >= this%max_batch_size) then
      this%batch_mode = .false.
    end if
  end subroutine BatchOp_IncrementBatch

  subroutine BatchOp_SetMaxBatchSize(this, max_size)
    class(BatchOpMgr), intent(inout) :: this
    integer(i4), intent(in) :: max_size
    this%max_batch_size = max(1_i4, max_size)
  end subroutine BatchOp_SetMaxBatchSize

  ! ===================================================================
  ! TreeNodeBase Methods
  ! ===================================================================
  subroutine TreeNode_SetParentID(this, parent_id, status)
    class(TreeNodeBase), intent(inout) :: this
    integer(i4), intent(in) :: parent_id
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (parent_id < 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Parent ID must be non-negative"
      return
    end if

    this%parent_id = parent_id
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine TreeNode_SetParentID

  subroutine TreeNode_SetActive(this, is_active)
    class(TreeNodeBase), intent(inout) :: this
    logical, intent(in) :: is_active
    this%is_active = is_active
  end subroutine TreeNode_SetActive

  subroutine TreeNode_SetVisible(this, is_visible)
    class(TreeNodeBase), intent(inout) :: this
    logical, intent(in) :: is_visible
    this%is_visible = is_visible
  end subroutine TreeNode_SetVisible

  function TreeNode_IsActive(this) result(is_active)
    class(TreeNodeBase), intent(in) :: this
    logical :: is_active
    is_active = this%is_active
  end function TreeNode_IsActive

  function TreeNode_IsVisible(this) result(is_visible)
    class(TreeNodeBase), intent(in) :: this
    logical :: is_visible
    is_visible = this%is_visible
  end function TreeNode_IsVisible

  function TreeNode_GetPath(this) result(path_str)
    class(TreeNodeBase), intent(in) :: this
    character(len=256) :: path_str

    character(len=64) :: name

    name = this%GetName()
    if (len_trim(name) > 0) then
      path_str = trim(name)
    else
      write(path_str, '(A,I0)') 'Node_', this%GetID()
    end if
  end function TreeNode_GetPath

  function TreeNode_GetFullPath(this) result(path_str)
    class(TreeNodeBase), intent(in) :: this
    character(len=512) :: path_str

    path_str = this%GetPath()
  end function TreeNode_GetFullPath

  function TreeNode_Valid(self) result(is_valid)
    class(TreeNodeBase), intent(in) :: self
    logical :: is_valid

    is_valid = .true.

    if (self%node_id < 0) then
      is_valid = .false.
      return
    end if

    if (self%node_type < MD_MODEL_NODE_TYPE_MODEL .or. self%node_type > MD_MODEL_NODE_TYPE_SURFA) then
      is_valid = .false.
      return
    end if

    if (self%parent_id < 0) then
      is_valid = .false.
      return
    end if
  end function TreeNode_Valid

  ! ===================================================================
  ! TreeNodeType Methods
  ! ===================================================================
  subroutine TreeNodeType_Init(this, type_code, status)
    class(TreeNodeType), intent(out) :: this
    integer(i4), intent(in) :: type_code
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (type_code < MD_MODEL_NODE_TYPE_MODEL .or. type_code > MD_MODEL_NODE_TYPE_SURFA) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Invalid node type code"
      return
    end if

    this%type_code = type_code
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine TreeNodeType_Init

  function TreeNodeType_GetCode(this) result(type_code)
    class(TreeNodeType), intent(in) :: this
    integer(i4) :: type_code
    type_code = this%type_code
  end function TreeNodeType_GetCode

  subroutine TreeNodeType_SetCode(this, type_code, status)
    class(TreeNodeType), intent(inout) :: this
    integer(i4), intent(in) :: type_code
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (type_code < MD_MODEL_NODE_TYPE_MODEL .or. type_code > MD_MODEL_NODE_TYPE_SURFA) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Invalid node type code"
      return
    end if

    this%type_code = type_code
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine TreeNodeType_SetCode

  function TreeNodeType_IsModel(this) result(is_model)
    class(TreeNodeType), intent(in) :: this
    logical :: is_model
    is_model = (this%type_code == MD_MODEL_NODE_TYPE_MODEL)
  end function TreeNodeType_IsModel

  function TreeNodeType_IsPart(this) result(is_part)
    class(TreeNodeType), intent(in) :: this
    logical :: is_part
    is_part = (this%type_code == MD_MODEL_NODE_TYPE_PART)
  end function TreeNodeType_IsPart

  function TreeNodeType_IsAssembly(this) result(is_assembly)
    class(TreeNodeType), intent(in) :: this
    logical :: is_assembly
    is_assembly = (this%type_code == MD_MODEL_NODE_TYPE_ASSEM)
  end function TreeNodeType_IsAssembly

  function TreeNodeType_IsMaterial(this) result(is_material)
    class(TreeNodeType), intent(in) :: this
    logical :: is_material
    is_material = (this%type_code == MD_MODEL_NODE_TYPE_MATER)
  end function TreeNodeType_IsMaterial

  function TreeNodeType_IsSection(this) result(is_section)
    class(TreeNodeType), intent(in) :: this
    logical :: is_section
    is_section = (this%type_code == MD_MODEL_NODE_TYPE_SECTI)
  end function TreeNodeType_IsSection

  function TreeNodeType_IsMesh(this) result(is_mesh)
    class(TreeNodeType), intent(in) :: this
    logical :: is_mesh
    is_mesh = (this%type_code == MD_MODEL_NODE_TYPE_MESH)
  end function TreeNodeType_IsMesh

  function TreeNodeType_IsAmplitude(this) result(is_amplitude)
    class(TreeNodeType), intent(in) :: this
    logical :: is_amplitude
    is_amplitude = (this%type_code == MD_MODEL_NODE_TYPE_AMPLI)
  end function TreeNodeType_IsAmplitude

  function TreeNodeType_IsLoadBC(this) result(is_loadbc)
    class(TreeNodeType), intent(in) :: this
    logical :: is_loadbc
    is_loadbc = (this%type_code == MD_MODEL_NODE_TYPE_LOADB)
  end function TreeNodeType_IsLoadBC

  function TreeNodeType_IsInteraction(this) result(is_interaction)
    class(TreeNodeType), intent(in) :: this
    logical :: is_interaction
    is_interaction = (this%type_code == MD_MODEL_NODE_TYPE_INTER)
  end function TreeNodeType_IsInteraction

  function TreeNodeType_IsStep(this) result(is_step)
    class(TreeNodeType), intent(in) :: this
    logical :: is_step
    is_step = (this%type_code == MD_MODEL_NODE_TYPE_STEP)
  end function TreeNodeType_IsStep

  function TreeNodeType_IsNode(this) result(is_node)
    class(TreeNodeType), intent(in) :: this
    logical :: is_node
    is_node = (this%type_code == MD_MODEL_NODE_TYPE_NODE)
  end function TreeNodeType_IsNode

  function TreeNodeType_IsElement(this) result(is_element)
    class(TreeNodeType), intent(in) :: this
    logical :: is_element
    is_element = (this%type_code == MD_MODEL_NODE_TYPE_ELEME)
  end function TreeNodeType_IsElement

  function TreeNodeType_IsNodeSet(this) result(is_nodeset)
    class(TreeNodeType), intent(in) :: this
    logical :: is_nodeset
    is_nodeset = (this%type_code == MD_MODEL_NODE_TYPE_NSET)
  end function TreeNodeType_IsNodeSet

  function TreeNodeType_IsElemSet(this) result(is_elemset)
    class(TreeNodeType), intent(in) :: this
    logical :: is_elemset
    is_elemset = (this%type_code == MD_MODEL_NODE_TYPE_ELSET)
  end function TreeNodeType_IsElemSet

  function TreeNodeType_IsSurface(this) result(is_surface)
    class(TreeNodeType), intent(in) :: this
    logical :: is_surface
    is_surface = (this%type_code == MD_MODEL_NODE_TYPE_SURFA)
  end function TreeNodeType_IsSurface

  ! ===================================================================
  ! Enhanced TreeNodeBase Methods
  ! ===================================================================
  subroutine TreeNode_ResolvePath(this, path_str, resolved_node, status)
    class(TreeNodeBase), intent(in) :: this
    character(len=*), intent(in) :: path_str
    class(TreeNodeBase), pointer, intent(out) :: resolved_node
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    nullify(resolved_node)

    if (.not. associated(this%path_resolver)) then
      status%status_code = MD_MODEL_STATUS_NOT_FOUND
      status%message = "No path resolver set"
      return
    end if
    status%status_code = MD_MODEL_STATUS_NOT_FOUND
    status%message = "Path resolution not implemented for base class"
  end subroutine TreeNode_ResolvePath

  subroutine TreeNode_ParsePath(this, path_str, components, status)
    class(TreeNodeBase), intent(in) :: this
    character(len=*), intent(in) :: path_str
    type(PathComponents), intent(out) :: components
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    if (associated(this%path_resolver)) then
      call this%path_resolver%ParsePath(path_str, components, status)
    else
      call components%Init(status=status)
    end if
  end subroutine TreeNode_ParsePath

  subroutine TreeNode_Serialize(this, serializer, status)
    class(TreeNodeBase), intent(in) :: this
    class(TreeSerializer), intent(inout) :: serializer
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call serializer%BeginObject("TreeNodeBase", status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call serializer%WriteInt(this%node_id, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call serializer%WriteInt(this%node_type, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call serializer%WriteInt(this%parent_id, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call serializer%WriteBool(this%is_active, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call serializer%WriteBool(this%is_visible, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call serializer%EndObject(status)
  end subroutine TreeNode_Serialize

  subroutine TreeNode_Deserialize(this, deserializer, status)
    class(TreeNodeBase), intent(inout) :: this
    class(TreeDeserializer), intent(inout) :: deserializer
    type(ErrorStatusType), intent(out) :: status

    character(len=256) :: obj_name

    call init_error_status(status)

    obj_name = deserializer%BeginObject(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    this%node_id = deserializer%ReadInt(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    this%node_type = deserializer%ReadInt(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    this%parent_id = deserializer%ReadInt(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    this%is_active = deserializer%ReadBool(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    this%is_visible = deserializer%ReadBool(status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    call deserializer%EndObject(status)
  end subroutine TreeNode_Deserialize

  subroutine TreeNode_SetIndexMgr(this, index_mgr, status)
    class(TreeNodeBase), intent(inout) :: this
    class(*), target, intent(in) :: index_mgr
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%index_mgr => index_mgr
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine TreeNode_SetIndexMgr

  subroutine TreeNode_SetLazyIndex(this, lazy_index, status)
    class(TreeNodeBase), intent(inout) :: this
    type(LazyIndexMgr), target, intent(in) :: lazy_index
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%lazy_index => lazy_index
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine TreeNode_SetLazyIndex

  subroutine TreeNode_UpdateIndex(this, status)
    class(TreeNodeBase), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (associated(this%lazy_index)) then
      call this%lazy_index%RebuildIfDirty(status)
    else if (associated(this%index_mgr)) then
      status%status_code = MD_MODEL_STATUS_OK
    else
      status%status_code = MD_MODEL_STATUS_OK
    end if
  end subroutine TreeNode_UpdateIndex

  subroutine TreeNode_SetBatchMgr(this, batch_mgr, status)
    class(TreeNodeBase), intent(inout) :: this
    type(BatchOpMgr), target, intent(in) :: batch_mgr
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%batch_mgr => batch_mgr
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine TreeNode_SetBatchMgr

  subroutine TreeNode_BeginBatch(this, status)
    class(TreeNodeBase), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (associated(this%batch_mgr)) then
      call this%batch_mgr%BeginBatch()
    else
      status%status_code = MD_MODEL_STATUS_OK
    end if
  end subroutine TreeNode_BeginBatch

  subroutine TreeNode_EndBatch(this, status)
    class(TreeNodeBase), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (associated(this%batch_mgr)) then
      call this%batch_mgr%EndBatch(rebuild_index=.true., status=status)
      if (status%status_code == MD_MODEL_STATUS_OK) then
        call this%UpdateIndex(status)
      end if
    else
      status%status_code = MD_MODEL_STATUS_OK
    end if
  end subroutine TreeNode_EndBatch

  subroutine TreeNode_SetPathResolver(this, path_resolver, status)
    class(TreeNodeBase), intent(inout) :: this
    class(AbstractPathRes), target, intent(in) :: path_resolver
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%path_resolver => path_resolver
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine TreeNode_SetPathResolver

  ! ===================================================================
  ! IDList Methods (Index_Mgr)
  ! ===================================================================
  subroutine IDList_Init(this, initial_capacit, status)
    class(IDList), intent(out) :: this
    integer(i4), intent(in), optional :: initial_capacit
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: cap

    call init_error_status(status)

    cap = 16_i4
    if (present(initial_capacit)) then
      cap = max(1_i4, initial_capacit)
    end if

    this%count = 0_i4
    this%capacity = cap
    allocate(this%ids(cap))
    this%ids = 0_i4

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine IDList_Init

  subroutine IDList_Add(this, id, status)
    class(IDList), intent(inout) :: this
    integer(i4), intent(in) :: id
    type(ErrorStatusType), intent(out) :: status

    integer(i4), allocatable :: temp(:)

    call init_error_status(status)

    if (this%Contains(id)) then
      status%status_code = MD_MODEL_STATUS_OK
      return
    end if

    if (this%count >= this%capacity) then
      allocate(temp(this%capacity * 2_i4))
      temp(1:this%capacity) = this%ids(1:this%capacity)
      temp(this%capacity+1:) = 0_i4
      call move_alloc(temp, this%ids)
      this%capacity = this%capacity * 2_i4
    end if

    this%count = this%count + 1_i4
    this%ids(this%count) = id

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine IDList_Add

  subroutine IDList_Remove(this, id, status)
    class(IDList), intent(inout) :: this
    integer(i4), intent(in) :: id
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, pos

    call init_error_status(status)

    pos = 0
    do i = 1, this%count
      if (this%ids(i) == id) then
        pos = i
        exit
      end if
    end do

    if (pos == 0) then
      status%status_code = MD_MODEL_STATUS_NOT_FOUND
      return
    end if

    if (pos < this%count) then
      this%ids(pos) = this%ids(this%count)
    end if
    this%count = this%count - 1_i4

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine IDList_Remove

  function IDList_Contains(this, id) result(contains_id)
    class(IDList), intent(in) :: this
    integer(i4), intent(in) :: id
    logical :: contains_id

    integer(i4) :: i

    contains_id = .false.
    do i = 1, this%count
      if (this%ids(i) == id) then
        contains_id = .true.
        return
      end if
    end do
  end function IDList_Contains

  subroutine IDList_Clear(this, status)
    class(IDList), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)
    this%count = 0_i4
    if (allocated(this%ids)) this%ids = 0_i4
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine IDList_Clear

  function IDList_GetCount(this) result(count)
    class(IDList), intent(in) :: this
    integer(i4) :: count
    count = this%count
  end function IDList_GetCount

  function IDList_GetIDs(this) result(ids)
    class(IDList), intent(in) :: this
    integer(i4), allocatable :: ids(:)
    if (allocated(this%ids) .and. this%count > 0) then
      ids = this%ids(1:this%count)
    end if
  end function IDList_GetIDs

  ! ===================================================================
  ! ParentChildMap Methods (Index_Mgr)
  ! ===================================================================
  subroutine ParentChildMap_Init(this, initial_capacit, status)
    class(ParentChildMap), intent(out) :: this
    integer(i4), intent(in), optional :: initial_capacit
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: cap, i

    call init_error_status(status)

    cap = 16_i4
    if (present(initial_capacit)) then
      cap = max(1_i4, initial_capacit)
    end if

    this%count = 0_i4
    this%capacity = cap
    allocate(this%entries(cap))
    do i = 1, cap
      call this%entries(i)%child_ids%Init(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end do

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ParentChildMap_Init

  subroutine ParentChildMap_AddChild(this, parent_id, child_id, status)
    class(ParentChildMap), intent(inout) :: this
    integer(i4), intent(in) :: parent_id
    integer(i4), intent(in) :: child_id
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: idx

    call init_error_status(status)

    idx = this%FindEntry(parent_id)
    if (idx == 0) then
      if (this%count >= this%capacity) then
        call this%Expand(status)
        if (status%status_code /= MD_MODEL_STATUS_OK) return
      end if
      this%count = this%count + 1_i4
      idx = this%count
      this%entries(idx)%parent_id = parent_id
    end if

    call this%entries(idx)%child_ids%Add(child_id, status)
  end subroutine ParentChildMap_AddChild

  subroutine ParentChildMap_RemoveChild(this, parent_id, child_id, status)
    class(ParentChildMap), intent(inout) :: this
    integer(i4), intent(in) :: parent_id
    integer(i4), intent(in) :: child_id
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: idx

    call init_error_status(status)

    idx = this%FindEntry(parent_id)
    if (idx == 0) then
      status%status_code = MD_MODEL_STATUS_NOT_FOUND
      return
    end if

    call this%entries(idx)%child_ids%Remove(child_id, status)
  end subroutine ParentChildMap_RemoveChild

  function ParentChildMap_GetChildren(this, parent_id) result(child_ids)
    class(ParentChildMap), intent(in) :: this
    integer(i4), intent(in) :: parent_id
    integer(i4), allocatable :: child_ids(:)

    integer(i4) :: idx

    idx = this%FindEntry(parent_id)
    if (idx > 0) then
      child_ids = this%entries(idx)%child_ids%GetIDs()
    end if
  end function ParentChildMap_GetChildren

  subroutine ParentChildMap_Clear(this, status)
    class(ParentChildMap), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    do i = 1, this%count
      call this%entries(i)%child_ids%Clear(status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end do
    this%count = 0_i4

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ParentChildMap_Clear

  function ParentChildMap_GetCount(this) result(count)
    class(ParentChildMap), intent(in) :: this
    integer(i4) :: count
    count = this%count
  end function ParentChildMap_GetCount

  function ParentChildMap_FindEntry(this, parent_id) result(idx)
    class(ParentChildMap), intent(in) :: this
    integer(i4), intent(in) :: parent_id
    integer(i4) :: idx

    integer(i4) :: i

    idx = 0
    do i = 1, this%count
      if (this%entries(i)%parent_id == parent_id) then
        idx = i
        return
      end if
    end do
  end function ParentChildMap_FindEntry

  subroutine ParentChildMap_Expand(this, status)
    class(ParentChildMap), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    type(ParentChildEntry), allocatable :: temp(:)
    integer(i4) :: i, new_capacity

    call init_error_status(status)

    new_capacity = this%capacity * 2_i4
    allocate(temp(new_capacity))
    temp(1:this%capacity) = this%entries(1:this%capacity)

    do i = this%capacity + 1, new_capacity
      call temp(i)%child_ids%Init(status=status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end do

    call move_alloc(temp, this%entries)
    this%capacity = new_capacity

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine ParentChildMap_Expand

  ! ===================================================================
  ! IndexMgr Methods
  ! ===================================================================
  subroutine IndexMgr_Init(this, max_capacity, status)
    class(IndexMgr), intent(inout) :: this
    integer(i4), intent(in), optional :: max_capacity
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status
    integer(i4) :: i

    call init_error_status(local_status)

    if (present(max_capacity)) then
      this%max_capacity = max_capacity
      this%max_type_code = max(1_i4, max_capacity / 10_i4)
    else
      this%max_type_code = 20_i4
    end if

    if (allocated(this%type_index)) deallocate(this%type_index)
    allocate(this%type_index(this%max_type_code))

    do i = 1, this%max_type_code
      call this%type_index(i)%Init(status=local_status)
      if (local_status%status_code /= MD_MODEL_STATUS_OK) then
        if (present(status)) status = local_status
        return
      end if
    end do

    call this%parent_child_in%Init(status=local_status)
    if (local_status%status_code /= MD_MODEL_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if

    this%count = 0_i4
    this%is_init = .true.
    this%index_dirty = .false.

    if (present(status)) status = local_status
  end subroutine IndexMgr_Init

  subroutine IndexMgr_Finalize(this, status)
    class(IndexMgr), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status

    call this%Clean(status)
  end subroutine IndexMgr_Finalize

  subroutine IndexMgr_Clean(this, status)
    class(IndexMgr), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status

    integer(i4) :: i
    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (allocated(this%type_index)) then
      do i = 1, size(this%type_index)
        call this%type_index(i)%Clear(status=local_status)
      end do
      deallocate(this%type_index)
    end if

    call this%parent_child_in%Clear(status=local_status)

    nullify(this%container)
    this%is_init = .false.
    this%count = 0_i4
    this%index_dirty = .false.

    if (present(status)) status = local_status
  end subroutine IndexMgr_Clean

  subroutine IndexMgr_Create(this, id, name, status)
    class(IndexMgr), intent(inout) :: this
    integer(i4), intent(out), optional :: id
    character(len=*), intent(in), optional :: name
    type(ErrorStatusType), intent(out), optional :: status

    if (present(status)) call init_error_status(status)
    if (present(id)) id = 0_i4
  end subroutine IndexMgr_Create

  subroutine IndexMgr_Delete(this, id, status)
    class(IndexMgr), intent(inout) :: this
    integer(i4), intent(in) :: id
    type(ErrorStatusType), intent(out), optional :: status

    if (present(status)) call init_error_status(status)
  end subroutine IndexMgr_Delete

  function IndexMgr_Find(this, name) result(id)
    class(IndexMgr), intent(in) :: this
    character(len=*), intent(in) :: name
    integer(i4) :: id

    class(TreeNodeBase), pointer :: obj_ptr

    obj_ptr => this%FindByName(name)
    if (associated(obj_ptr)) then
      id = obj_ptr%GetID()
    else
      id = 0_i4
    end if
  end function IndexMgr_Find

  subroutine IndexMgr_Get(this, id, status)
    class(IndexMgr), intent(in) :: this
    integer(i4), intent(in) :: id
    type(ErrorStatusType), intent(out), optional :: status

    class(TreeNodeBase), pointer :: obj_ptr

    if (present(status)) call init_error_status(status)

    obj_ptr => this%FindByID(id)
    if (.not. associated(obj_ptr)) then
      if (present(status)) status%status_code = MD_MODEL_STATUS_NOT_FOUND
    end if
  end subroutine IndexMgr_Get

  function IndexMgr_GetCount(this) result(count)
    class(IndexMgr), intent(in) :: this
    integer(i4) :: count

    count = this%count
    if (associated(this%container)) then
      count = this%container%GetCount()
    end if
  end function IndexMgr_GetCount

  subroutine IndexMgr_List(this, status)
    class(IndexMgr), intent(in) :: this
    type(ErrorStatusType), intent(out), optional :: status

    if (present(status)) call init_error_status(status)
    if (present(status)) status%status_code = MD_MODEL_STATUS_OK
  end subroutine IndexMgr_List

  subroutine IndexMgr_ValidateConsistency(this, status)
    class(IndexMgr), intent(in) :: this
    type(ErrorStatusType), intent(out), optional :: status

    integer(i4) :: i, j, k, id, parent_id
    integer(i4), allocatable :: seen_ids(:)
    type(ErrorStatusType) :: local_status

    if (.not. this%Valid()) then
      if (present(status)) then
        call init_error_status(status)
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "Index manager not valid"
      end if
      return
    end if

    call init_error_status(local_status)

    if (allocated(this%type_index)) then
      do i = 1, this%max_type_code
        if (this%type_index(i)%count > 0) then
          allocate(seen_ids(this%type_index(i)%count))
          seen_ids = 0
          do j = 1, this%type_index(i)%count
            id = this%type_index(i)%ids(j)
            do k = 1, j - 1
              if (seen_ids(k) == id) then
                local_status%status_code = MD_MODEL_STATUS_INVALID
                write(local_status%message, '(A,I0,A,I0)') 'Duplicate ID ', id, ' in type_index(', i, ')'
                deallocate(seen_ids)
                if (present(status)) status = local_status
                return
              end if
            end do
            seen_ids(j) = id
          end do
          deallocate(seen_ids)
        end if
      end do
    end if

    if (associated(this%container)) then
      do i = 1, this%parent_child_in%count
        parent_id = this%parent_child_in%entries(i)%parent_id
        if (parent_id > 0) then
          do j = 1, this%parent_child_in%entries(i)%child_ids%count
            id = this%parent_child_in%entries(i)%child_ids%ids(j)
            if (id <= 0 .or. id > this%container%GetCount()) then
              local_status%status_code = MD_MODEL_STATUS_INVALID
              write(local_status%message, '(A,I0,A,I0)') 'Invalid child ID ', id, ' for parent ', parent_id
              if (present(status)) status = local_status
              return
            end if
          end do
        end if
      end do
    end if

    local_status%status_code = MD_MODEL_STATUS_OK
    if (present(status)) status = local_status
  end subroutine IndexMgr_ValidateConsistency

  subroutine IndexMgr_GetStatistics(this, status)
    class(IndexMgr), intent(in) :: this
    type(ErrorStatusType), intent(out), optional :: status

    integer(i4) :: i, total_entries, total_children
    character(len=256) :: stat_msg

    if (present(status)) then
      call init_error_status(status)
      total_entries = 0
      total_children = 0

      if (allocated(this%type_index)) then
        do i = 1, this%max_type_code
          if (this%type_index(i)%count > 0) then
            total_entries = total_entries + this%type_index(i)%count
          end if
        end do
      end if

      do i = 1, this%parent_child_in%count
        total_children = total_children + this%parent_child_in%entries(i)%child_ids%count
      end do

      write(stat_msg, '(A,I0,A,I0,A,I0,A,L1)') &
        'IndexMgr Statistics: TypeEntries=', total_entries, &
        ', ParentChildPairs=', this%parent_child_in%count, &
        ', TotalChildren=', total_children, &
        ', Dirty=', this%index_dirty

      status%status_code = MD_MODEL_STATUS_OK
      status%message = trim(stat_msg)
    end if
  end subroutine IndexMgr_GetStatistics

  subroutine IndexMgr_Reg(this, obj, status)
    class(IndexMgr), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: obj
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: type_code, id, parent_id

    call init_error_status(status)

    if (.not. this%is_init) then
      status%status_code = MD_MODEL_STATUS_INVALID
      return
    end if

    type_code = obj%GetType()
    id = obj%GetID()
    parent_id = obj%GetParentID()

    if (type_code > 0 .and. type_code <= this%max_type_code) then
      call this%type_index(type_code)%Add(id, status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end if

    if (parent_id > 0) then
      call this%parent_child_in%AddChild(parent_id, id, status)
      if (status%status_code /= MD_MODEL_STATUS_OK) return
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine IndexMgr_Reg

  subroutine IndexMgr_Unregister(this, obj, status)
    class(IndexMgr), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: obj
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: type_code, id, parent_id

    call init_error_status(status)

    if (.not. this%is_init) then
      status%status_code = MD_MODEL_STATUS_INVALID
      return
    end if

    type_code = obj%GetType()
    id = obj%GetID()
    parent_id = obj%GetParentID()

    if (type_code > 0 .and. type_code <= this%max_type_code) then
      call this%type_index(type_code)%Remove(id, status)
    end if

    if (parent_id > 0) then
      call this%parent_child_in%RemoveChild(parent_id, id, status)
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine IndexMgr_Unregister

  function IndexMgr_FindByID(this, id) result(obj_ptr)
    class(IndexMgr), intent(in) :: this
    integer(i4), intent(in) :: id
    class(TreeNodeBase), pointer :: obj_ptr
    class(ObjBase), pointer :: base_ptr

    obj_ptr => null()
    if (.not. this%is_init) return
    if (.not. associated(this%container)) return
    base_ptr => this%container%GetByID(id)
    if (associated(base_ptr)) then
      select type (base_ptr)
      class is (TreeNodeBase)
        obj_ptr => base_ptr
      end select
    end if
  end function IndexMgr_FindByID

  function IndexMgr_FindByName(this, name) result(obj_ptr)
    class(IndexMgr), intent(in) :: this
    character(len=*), intent(in) :: name
    class(TreeNodeBase), pointer :: obj_ptr
    class(ObjBase), pointer :: base_ptr

    obj_ptr => null()
    if (.not. this%is_init) return
    if (.not. associated(this%container)) return
    base_ptr => this%container%GetByName(name)
    if (associated(base_ptr)) then
      select type (base_ptr)
      class is (TreeNodeBase)
        obj_ptr => base_ptr
      end select
    end if
  end function IndexMgr_FindByName

  function IndexMgr_FindByType(this, type_code) result(ids)
    class(IndexMgr), intent(in) :: this
    integer(i4), intent(in) :: type_code
    integer(i4), allocatable :: ids(:)

    if (.not. this%is_init) return
    if (type_code < 1 .or. type_code > this%max_type_code) return
    ids = this%type_index(type_code)%GetIDs()
  end function IndexMgr_FindByType

  function IndexMgr_FindChildren(this, parent_id) result(child_ids)
    class(IndexMgr), intent(in) :: this
    integer(i4), intent(in) :: parent_id
    integer(i4), allocatable :: child_ids(:)

    if (.not. this%is_init) return
    child_ids = this%parent_child_in%GetChildren(parent_id)
  end function IndexMgr_FindChildren

  subroutine IndexMgr_UpdateParent(this, obj, old_parent_id, new_parent_id, status)
    class(IndexMgr), intent(inout) :: this
    class(TreeNodeBase), intent(in), target :: obj
    integer(i4), intent(in) :: old_parent_id
    integer(i4), intent(in) :: new_parent_id
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: id

    call init_error_status(status)

    if (.not. this%is_init) then
      status%status_code = MD_MODEL_STATUS_INVALID
      return
    end if

    id = obj%GetID()

    if (old_parent_id > 0) then
      call this%parent_child_in%RemoveChild(old_parent_id, id, status)
    end if

    if (new_parent_id > 0) then
      call this%parent_child_in%AddChild(new_parent_id, id, status)
    end if
  end subroutine IndexMgr_UpdateParent

  subroutine IndexMgr_Rebuild(this, status)
    class(IndexMgr), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, type_code, id, parent_id
    class(ObjBase), pointer :: base_ptr
    class(TreeNodeBase), pointer :: obj_ptr

    call init_error_status(status)

    if (.not. this%is_init) return
    if (.not. associated(this%container)) then
      status%status_code = MD_MODEL_STATUS_INVALID
      return
    end if

    do i = 1, this%max_type_code
      call this%type_index(i)%Clear(status)
    end do
    call this%parent_child_in%Clear(status)

    do i = 1, this%container%GetCount()
      obj_ptr => null()
      base_ptr => this%container%GetByID(i)
      if (.not. associated(base_ptr)) cycle
      select type (base_ptr)
      class is (TreeNodeBase)
        obj_ptr => base_ptr
      class default
        cycle
      end select
      if (.not. associated(obj_ptr)) cycle

      type_code = obj_ptr%GetType()
      id = obj_ptr%GetID()
      parent_id = obj_ptr%GetParentID()

      if (type_code > 0 .and. type_code <= this%max_type_code) then
        call this%type_index(type_code)%Add(id, status)
      end if

      if (parent_id > 0) then
        call this%parent_child_in%AddChild(parent_id, id, status)
      end if
    end do

    this%index_dirty = .false.
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine IndexMgr_Rebuild

  subroutine IndexMgr_Clear(this, status)
    class(IndexMgr), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (allocated(this%type_index)) then
      do i = 1, size(this%type_index)
        call this%type_index(i)%Clear(status)
      end do
    end if

    call this%parent_child_in%Clear(status)

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine IndexMgr_Clear

  function IndexMgr_Valid(this) result(ok)
    class(IndexMgr), intent(in) :: this
    logical :: ok

    ok = .true.
    if (.not. this%is_init) then
      ok = .false.
      return
    end if
    if (.not. associated(this%container)) then
      ok = .false.
    end if
  end function IndexMgr_Valid

  ! ===================================================================
  ! PathResolver Methods (merged from MD_Base_TreeIndex_Mgr)
  ! ===================================================================
  subroutine Resolver_ParsePath(this, path_str, components, status)
    class(PathResolver), intent(in) :: this
    character(len=*), intent(in) :: path_str
    type(PathComponents), intent(out) :: components
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, start_pos, end_pos, comp_count
    character(len=MD_MODEL_MAX_PATH_LENGTH) :: path

    call init_error_status(status)
    call components%Init(status=status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    path = trim(adjustl(path_str))
    if (len_trim(path) == 0) then
      status%status_code = MD_MODEL_STATUS_OK
      return
    end if

    components%is_absolute = (path(1:1) == this%separator)
    if (components%is_absolute) then
      start_pos = 2
    else
      start_pos = 1
    end if

    comp_count = 0
    end_pos = start_pos

    do i = start_pos, len_trim(path)
      if (path(i:i) == this%separator) then
        if (end_pos < i) then
          comp_count = comp_count + 1_i4
          if (comp_count <= size(components%components)) then
            components%components(comp_count) = path(end_pos:i-1)
          end if
        end if
        end_pos = i + 1
      end if
    end do

    if (end_pos <= len_trim(path)) then
      comp_count = comp_count + 1_i4
      if (comp_count <= size(components%components)) then
        components%components(comp_count) = path(end_pos:len_trim(path))
      end if
    end if

    components%count = comp_count
    status%status_code = MD_MODEL_STATUS_OK
  end subroutine Resolver_ParsePath

  function Resolver_ResolvePath(this, root_node, path_str) result(obj_ptr)
    class(PathResolver), intent(in) :: this
    class(TreeNodeBase), intent(in), target :: root_node
    character(len=*), intent(in) :: path_str
    class(TreeNodeBase), pointer :: obj_ptr

    type(PathComponents) :: components
    type(ErrorStatusType) :: local_status
    integer(i4) :: i
    class(TreeNodeBase), pointer :: current_obj
    character(len=64) :: comp_name

    obj_ptr => null()
    call this%ParsePath(path_str, components, local_status)
    if (components%GetCount() == 0) then
      obj_ptr => root_node
      return
    end if

    if (components%IsAbsolute()) then
      current_obj => root_node
    else
      current_obj => root_node
    end if

    do i = 1, components%GetCount()
      comp_name = components%GetComponent(i)
      if (len_trim(comp_name) == 0) cycle

      obj_ptr => null()
      return
    end do

    obj_ptr => current_obj
  end function Resolver_ResolvePath

  function Resolver_BuildPath(this, components) result(path_str)
    class(PathResolver), intent(in) :: this
    type(PathComponents), intent(in) :: components
    character(len=MD_MODEL_MAX_PATH_LENGTH) :: path_str

    integer(i4) :: i
    character(len=64) :: comp

    path_str = ""

    if (components%IsAbsolute()) then
      path_str = this%separator
    end if

    do i = 1, components%GetCount()
      comp = components%GetComponent(i)
      if (len_trim(comp) > 0) then
        if (len_trim(path_str) > 0 .and. path_str(len_trim(path_str):len_trim(path_str)) /= this%separator) then
          path_str = trim(path_str) // this%separator
        end if
        path_str = trim(path_str) // trim(comp)
      end if
    end do
  end function Resolver_BuildPath

  subroutine Resolver_ValidatePath(this, path_str, status)
    class(PathResolver), intent(in) :: this
    character(len=*), intent(in) :: path_str
    type(ErrorStatusType), intent(out) :: status

    type(PathComponents) :: components
    integer(i4) :: i
    character(len=64) :: comp

    call init_error_status(status)

    if (len_trim(path_str) == 0) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Empty path string"
      return
    end if

    if (len_trim(path_str) > MD_MODEL_MAX_PATH_LENGTH) then
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "Path string too long"
      return
    end if

    call this%ParsePath(path_str, components, status)
    if (status%status_code /= MD_MODEL_STATUS_OK) return

    do i = 1, components%GetCount()
      comp = components%GetComponent(i)
      if (len_trim(comp) == 0) then
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "Empty path component"
        return
      end if
      if (index(comp, this%separator) > 0) then
        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "Invalid character in path component"
        return
      end if
    end do

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine Resolver_ValidatePath

  function Resolver_NormalizePath(this, path_str) result(normalized_path)
    class(PathResolver), intent(in) :: this
    character(len=*), intent(in) :: path_str
    character(len=MD_MODEL_MAX_PATH_LENGTH) :: normalized_path

    type(PathComponents) :: components
    type(ErrorStatusType) :: local_status
    integer(i4) :: i, j, comp_count
    character(len=64), allocatable :: normalized_comp(:)
    character(len=64) :: comp

    normalized_path = ""
    call this%ParsePath(path_str, components, local_status)
    comp_count = components%GetCount()

    if (comp_count == 0) then
      normalized_path = this%separator
      return
    end if

    allocate(normalized_comp(comp_count))
    j = 0

    do i = 1, comp_count
      comp = components%GetComponent(i)
      if (comp == ".") then
        cycle
      else if (comp == "..") then
        if (j > 0) then
          j = j - 1
        end if
      else
        j = j + 1
        normalized_comp(j) = comp
      end if
    end do

    if (components%IsAbsolute()) then
      normalized_path = this%separator
    end if

    do i = 1, j
      if (i > 1) then
        normalized_path = trim(normalized_path) // this%separator
      end if
      normalized_path = trim(normalized_path) // trim(normalized_comp(i))
    end do

    deallocate(normalized_comp)
  end function Resolver_NormalizePath

  function Resolver_JoinPath(this, path1, path2) result(joined_path)
    class(PathResolver), intent(in) :: this
    character(len=*), intent(in) :: path1, path2
    character(len=MD_MODEL_MAX_PATH_LENGTH) :: joined_path

    character(len=MD_MODEL_MAX_PATH_LENGTH) :: p1, p2

    p1 = trim(adjustl(path1))
    p2 = trim(adjustl(path2))

    if (len_trim(p1) == 0) then
      joined_path = p2
      return
    end if

    if (len_trim(p2) == 0) then
      joined_path = p1
      return
    end if

    if (p1(len_trim(p1):len_trim(p1)) == this%separator) then
      p1 = p1(1:len_trim(p1)-1)
    end if

    if (p2(1:1) == this%separator) then
      p2 = p2(2:)
    end if

    joined_path = trim(p1) // this%separator // trim(p2)
  end function Resolver_JoinPath

  subroutine Resolver_ParseComponent(this, component_str, type_name, name, status)
    class(PathResolver), intent(in) :: this
    character(len=*), intent(in) :: component_str
    character(len=*), intent(out) :: type_name
    character(len=*), intent(out) :: name
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: sep_pos

    call init_error_status(status)

    type_name = ""
    name = ""

    sep_pos = index(component_str, this%separator)
    if (sep_pos > 0) then
      type_name = component_str(1:sep_pos-1)
      name = component_str(sep_pos+1:)
    else
      name = component_str
    end if

    status%status_code = MD_MODEL_STATUS_OK
  end subroutine Resolver_ParseComponent

end module MD_Base_TreeIndex