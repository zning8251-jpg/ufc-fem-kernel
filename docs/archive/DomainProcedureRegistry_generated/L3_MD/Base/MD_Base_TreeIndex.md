# `MD_Base_TreeIndex.f90`

- **Source**: `L3_MD/Base/MD_Base_TreeIndex.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Base_TreeIndex`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Base_TreeIndex`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Base_TreeIndex`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Base_TreeIndex.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PathComponents` (lines 201–211)

```fortran
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
```

### `AbstractPathRes` (lines 216–219)

```fortran
  type, abstract, public :: AbstractPathRes
  contains
    procedure(ParsePath_IF), deferred, public :: ParsePath
  end type AbstractPathRes
```

### `LazyIndexMgr` (lines 269–283)

```fortran
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
```

### `MemPool` (lines 288–301)

```fortran
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
```

### `BatchOpMgr` (lines 306–317)

```fortran
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
```

### `TreeNodeType` (lines 399–420)

```fortran
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
```

### `IDList` (lines 425–437)

```fortran
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
```

### `ParentChildEntry` (lines 442–445)

```fortran
  type :: ParentChildEntry
    integer(i4) :: parent_id = 0_i4
    type(IDList) :: child_ids
  end type ParentChildEntry
```

### `ParentChildMap` (lines 447–460)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ParsePath_IF` | 222 | `subroutine ParsePath_IF(this, path_str, components, status)` |
| FUNCTION | `GetNodeID_IF` | 371 | `function GetNodeID_IF(this) result(id)` |
| FUNCTION | `GetNodeName_IF` | 377 | `function GetNodeName_IF(this) result(name)` |
| FUNCTION | `GetNodeType_IF` | 383 | `function GetNodeType_IF(this) result(ntype)` |
| FUNCTION | `GetParentID_IF` | 389 | `function GetParentID_IF(this) result(pid)` |
| SUBROUTINE | `PathComponents_Init` | 500 | `subroutine PathComponents_Init(this, max_components, status)` |
| SUBROUTINE | `PathComponents_Clear` | 522 | `subroutine PathComponents_Clear(this, status)` |
| FUNCTION | `PathComponents_GetCount` | 535 | `function PathComponents_GetCount(this) result(count)` |
| FUNCTION | `PathComponents_GetComponent` | 541 | `function PathComponents_GetComponent(this, index) result(component)` |
| FUNCTION | `PathComponents_IsAbsolute` | 554 | `function PathComponents_IsAbsolute(this) result(is_abs)` |
| SUBROUTINE | `LazyIndex_Init` | 563 | `subroutine LazyIndex_Init(this, container_ptr, auto_rebuild, threshold, status)` |
| SUBROUTINE | `LazyIndex_MarkDirty` | 595 | `subroutine LazyIndex_MarkDirty(this)` |
| SUBROUTINE | `LazyIndex_RebuildIfDirty` | 605 | `subroutine LazyIndex_RebuildIfDirty(this, status)` |
| SUBROUTINE | `LazyIndex_ForceRebuild` | 643 | `subroutine LazyIndex_ForceRebuild(this, status)` |
| FUNCTION | `LazyIndex_IsDirty` | 662 | `function LazyIndex_IsDirty(this) result(is_dirty)` |
| SUBROUTINE | `LazyIndex_SetAutoRebuild` | 668 | `subroutine LazyIndex_SetAutoRebuild(this, enable)` |
| SUBROUTINE | `LazyIdx_SetRebuildThresh` | 674 | `subroutine LazyIdx_SetRebuildThresh(this, threshold)` |
| SUBROUTINE | `MemPool_Init` | 683 | `subroutine MemPool_Init(this, pool_size, status)` |
| SUBROUTINE | `MemPool_Destroy` | 713 | `subroutine MemPool_Destroy(this, status)` |
| FUNCTION | `MemPool_Allocate` | 730 | `function MemPool_Allocate(this, status) result(index)` |
| SUBROUTINE | `MemPool_Deallocate` | 758 | `subroutine MemPool_Deallocate(this, index, status)` |
| FUNCTION | `MemPool_GetFreeCount` | 789 | `function MemPool_GetFreeCount(this) result(count)` |
| FUNCTION | `MemPool_GetPoolSize` | 795 | `function MemPool_GetPoolSize(this) result(size)` |
| SUBROUTINE | `MemPool_Clear` | 801 | `subroutine MemPool_Clear(this, status)` |
| SUBROUTINE | `BatchOp_BeginBatch` | 822 | `subroutine BatchOp_BeginBatch(this, max_size)` |
| SUBROUTINE | `BatchOp_EndBatch` | 835 | `subroutine BatchOp_EndBatch(this, rebuild_index, status)` |
| FUNCTION | `BatchOp_IsBatchMode` | 859 | `function BatchOp_IsBatchMode(this) result(is_batch)` |
| SUBROUTINE | `BatchOp_IncrementBatch` | 865 | `subroutine BatchOp_IncrementBatch(this)` |
| SUBROUTINE | `BatchOp_SetMaxBatchSize` | 875 | `subroutine BatchOp_SetMaxBatchSize(this, max_size)` |
| SUBROUTINE | `TreeNode_SetParentID` | 884 | `subroutine TreeNode_SetParentID(this, parent_id, status)` |
| SUBROUTINE | `TreeNode_SetActive` | 901 | `subroutine TreeNode_SetActive(this, is_active)` |
| SUBROUTINE | `TreeNode_SetVisible` | 907 | `subroutine TreeNode_SetVisible(this, is_visible)` |
| FUNCTION | `TreeNode_IsActive` | 913 | `function TreeNode_IsActive(this) result(is_active)` |
| FUNCTION | `TreeNode_IsVisible` | 919 | `function TreeNode_IsVisible(this) result(is_visible)` |
| FUNCTION | `TreeNode_GetPath` | 925 | `function TreeNode_GetPath(this) result(path_str)` |
| FUNCTION | `TreeNode_GetFullPath` | 939 | `function TreeNode_GetFullPath(this) result(path_str)` |
| FUNCTION | `TreeNode_Valid` | 946 | `function TreeNode_Valid(self) result(is_valid)` |
| SUBROUTINE | `TreeNodeType_Init` | 971 | `subroutine TreeNodeType_Init(this, type_code, status)` |
| FUNCTION | `TreeNodeType_GetCode` | 988 | `function TreeNodeType_GetCode(this) result(type_code)` |
| SUBROUTINE | `TreeNodeType_SetCode` | 994 | `subroutine TreeNodeType_SetCode(this, type_code, status)` |
| FUNCTION | `TreeNodeType_IsModel` | 1011 | `function TreeNodeType_IsModel(this) result(is_model)` |
| FUNCTION | `TreeNodeType_IsPart` | 1017 | `function TreeNodeType_IsPart(this) result(is_part)` |
| FUNCTION | `TreeNodeType_IsAssembly` | 1023 | `function TreeNodeType_IsAssembly(this) result(is_assembly)` |
| FUNCTION | `TreeNodeType_IsMaterial` | 1029 | `function TreeNodeType_IsMaterial(this) result(is_material)` |
| FUNCTION | `TreeNodeType_IsSection` | 1035 | `function TreeNodeType_IsSection(this) result(is_section)` |
| FUNCTION | `TreeNodeType_IsMesh` | 1041 | `function TreeNodeType_IsMesh(this) result(is_mesh)` |
| FUNCTION | `TreeNodeType_IsAmplitude` | 1047 | `function TreeNodeType_IsAmplitude(this) result(is_amplitude)` |
| FUNCTION | `TreeNodeType_IsLoadBC` | 1053 | `function TreeNodeType_IsLoadBC(this) result(is_loadbc)` |
| FUNCTION | `TreeNodeType_IsInteraction` | 1059 | `function TreeNodeType_IsInteraction(this) result(is_interaction)` |
| FUNCTION | `TreeNodeType_IsStep` | 1065 | `function TreeNodeType_IsStep(this) result(is_step)` |
| FUNCTION | `TreeNodeType_IsNode` | 1071 | `function TreeNodeType_IsNode(this) result(is_node)` |
| FUNCTION | `TreeNodeType_IsElement` | 1077 | `function TreeNodeType_IsElement(this) result(is_element)` |
| FUNCTION | `TreeNodeType_IsNodeSet` | 1083 | `function TreeNodeType_IsNodeSet(this) result(is_nodeset)` |
| FUNCTION | `TreeNodeType_IsElemSet` | 1089 | `function TreeNodeType_IsElemSet(this) result(is_elemset)` |
| FUNCTION | `TreeNodeType_IsSurface` | 1095 | `function TreeNodeType_IsSurface(this) result(is_surface)` |
| SUBROUTINE | `TreeNode_ResolvePath` | 1104 | `subroutine TreeNode_ResolvePath(this, path_str, resolved_node, status)` |
| SUBROUTINE | `TreeNode_ParsePath` | 1122 | `subroutine TreeNode_ParsePath(this, path_str, components, status)` |
| SUBROUTINE | `TreeNode_Serialize` | 1136 | `subroutine TreeNode_Serialize(this, serializer, status)` |
| SUBROUTINE | `TreeNode_Deserialize` | 1164 | `subroutine TreeNode_Deserialize(this, deserializer, status)` |
| SUBROUTINE | `TreeNode_SetIndexMgr` | 1194 | `subroutine TreeNode_SetIndexMgr(this, index_mgr, status)` |
| SUBROUTINE | `TreeNode_SetLazyIndex` | 1204 | `subroutine TreeNode_SetLazyIndex(this, lazy_index, status)` |
| SUBROUTINE | `TreeNode_UpdateIndex` | 1214 | `subroutine TreeNode_UpdateIndex(this, status)` |
| SUBROUTINE | `TreeNode_SetBatchMgr` | 1229 | `subroutine TreeNode_SetBatchMgr(this, batch_mgr, status)` |
| SUBROUTINE | `TreeNode_BeginBatch` | 1239 | `subroutine TreeNode_BeginBatch(this, status)` |
| SUBROUTINE | `TreeNode_EndBatch` | 1252 | `subroutine TreeNode_EndBatch(this, status)` |
| SUBROUTINE | `TreeNode_SetPathResolver` | 1268 | `subroutine TreeNode_SetPathResolver(this, path_resolver, status)` |
| SUBROUTINE | `IDList_Init` | 1281 | `subroutine IDList_Init(this, initial_capacit, status)` |
| SUBROUTINE | `IDList_Add` | 1303 | `subroutine IDList_Add(this, id, status)` |
| SUBROUTINE | `IDList_Remove` | 1331 | `subroutine IDList_Remove(this, id, status)` |
| FUNCTION | `IDList_Contains` | 1361 | `function IDList_Contains(this, id) result(contains_id)` |
| SUBROUTINE | `IDList_Clear` | 1377 | `subroutine IDList_Clear(this, status)` |
| FUNCTION | `IDList_GetCount` | 1387 | `function IDList_GetCount(this) result(count)` |
| FUNCTION | `IDList_GetIDs` | 1393 | `function IDList_GetIDs(this) result(ids)` |
| SUBROUTINE | `ParentChildMap_Init` | 1404 | `subroutine ParentChildMap_Init(this, initial_capacit, status)` |
| SUBROUTINE | `ParentChildMap_AddChild` | 1429 | `subroutine ParentChildMap_AddChild(this, parent_id, child_id, status)` |
| SUBROUTINE | `ParentChildMap_RemoveChild` | 1453 | `subroutine ParentChildMap_RemoveChild(this, parent_id, child_id, status)` |
| FUNCTION | `ParentChildMap_GetChildren` | 1472 | `function ParentChildMap_GetChildren(this, parent_id) result(child_ids)` |
| SUBROUTINE | `ParentChildMap_Clear` | 1485 | `subroutine ParentChildMap_Clear(this, status)` |
| FUNCTION | `ParentChildMap_GetCount` | 1502 | `function ParentChildMap_GetCount(this) result(count)` |
| FUNCTION | `ParentChildMap_FindEntry` | 1508 | `function ParentChildMap_FindEntry(this, parent_id) result(idx)` |
| SUBROUTINE | `ParentChildMap_Expand` | 1524 | `subroutine ParentChildMap_Expand(this, status)` |
| SUBROUTINE | `IndexMgr_Init` | 1551 | `subroutine IndexMgr_Init(this, max_capacity, status)` |
| SUBROUTINE | `IndexMgr_Finalize` | 1592 | `subroutine IndexMgr_Finalize(this, status)` |
| SUBROUTINE | `IndexMgr_Clean` | 1599 | `subroutine IndexMgr_Clean(this, status)` |
| SUBROUTINE | `IndexMgr_Create` | 1625 | `subroutine IndexMgr_Create(this, id, name, status)` |
| SUBROUTINE | `IndexMgr_Delete` | 1635 | `subroutine IndexMgr_Delete(this, id, status)` |
| FUNCTION | `IndexMgr_Find` | 1643 | `function IndexMgr_Find(this, name) result(id)` |
| SUBROUTINE | `IndexMgr_Get` | 1658 | `subroutine IndexMgr_Get(this, id, status)` |
| FUNCTION | `IndexMgr_GetCount` | 1673 | `function IndexMgr_GetCount(this) result(count)` |
| SUBROUTINE | `IndexMgr_List` | 1683 | `subroutine IndexMgr_List(this, status)` |
| SUBROUTINE | `IndexMgr_ValidateConsistency` | 1691 | `subroutine IndexMgr_ValidateConsistency(this, status)` |
| SUBROUTINE | `IndexMgr_GetStatistics` | 1754 | `subroutine IndexMgr_GetStatistics(this, status)` |
| SUBROUTINE | `IndexMgr_Reg` | 1789 | `subroutine IndexMgr_Reg(this, obj, status)` |
| SUBROUTINE | `IndexMgr_Unregister` | 1820 | `subroutine IndexMgr_Unregister(this, obj, status)` |
| FUNCTION | `IndexMgr_FindByID` | 1849 | `function IndexMgr_FindByID(this, id) result(obj_ptr)` |
| FUNCTION | `IndexMgr_FindByName` | 1867 | `function IndexMgr_FindByName(this, name) result(obj_ptr)` |
| FUNCTION | `IndexMgr_FindByType` | 1885 | `function IndexMgr_FindByType(this, type_code) result(ids)` |
| FUNCTION | `IndexMgr_FindChildren` | 1895 | `function IndexMgr_FindChildren(this, parent_id) result(child_ids)` |
| SUBROUTINE | `IndexMgr_UpdateParent` | 1904 | `subroutine IndexMgr_UpdateParent(this, obj, old_parent_id, new_parent_id, status)` |
| SUBROUTINE | `IndexMgr_Rebuild` | 1931 | `subroutine IndexMgr_Rebuild(this, status)` |
| SUBROUTINE | `IndexMgr_Clear` | 1981 | `subroutine IndexMgr_Clear(this, status)` |
| FUNCTION | `IndexMgr_Valid` | 2000 | `function IndexMgr_Valid(this) result(ok)` |
| SUBROUTINE | `Resolver_ParsePath` | 2017 | `subroutine Resolver_ParsePath(this, path_str, components, status)` |
| FUNCTION | `Resolver_ResolvePath` | 2069 | `function Resolver_ResolvePath(this, root_node, path_str) result(obj_ptr)` |
| FUNCTION | `Resolver_BuildPath` | 2105 | `function Resolver_BuildPath(this, components) result(path_str)` |
| SUBROUTINE | `Resolver_ValidatePath` | 2130 | `subroutine Resolver_ValidatePath(this, path_str, status)` |
| FUNCTION | `Resolver_NormalizePath` | 2173 | `function Resolver_NormalizePath(this, path_str) result(normalized_path)` |
| FUNCTION | `Resolver_JoinPath` | 2224 | `function Resolver_JoinPath(this, path1, path2) result(joined_path)` |
| SUBROUTINE | `Resolver_ParseComponent` | 2255 | `subroutine Resolver_ParseComponent(this, component_str, type_name, name, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
