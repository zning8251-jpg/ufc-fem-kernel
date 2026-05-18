# `MD_Base_ObjModel.f90`

- **Source**: `L3_MD/Base/MD_Base_ObjModel.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Base_ObjModel`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Base_ObjModel`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Base_ObjModel`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Base_ObjModel.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Serializable` (lines 287–291)

```fortran
    TYPE, ABSTRACT, PUBLIC :: Serializable
    CONTAINS
        PROCEDURE(Serialize_IF), DEFERRED :: Serialize
        PROCEDURE(Deserialize_IF), DEFERRED :: Deserialize
    END TYPE Serializable
```

### `TreeSerializer` (lines 293–320)

```fortran
    TYPE, PUBLIC :: TreeSerializer
        INTEGER(i4) :: format = MD_MODEL_SERIAL_FORMAT_B
        TYPE(RW_Serializer) :: rw_serializer
        TYPE(FileHandle) :: json_file
        INTEGER(i4) :: indent_level = 0_i4
        LOGICAL :: first_in_object = .TRUE.
        LOGICAL :: first_in_array = .TRUE.
        LOGICAL :: is_init = .FALSE.
        LOGICAL :: file_open = .FALSE.
        CHARACTER(LEN=256) :: file_path = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init => Serial_Init
        PROCEDURE, PUBLIC :: Destroy => Serial_Destroy
        PROCEDURE, PUBLIC :: Open => Serial_Open
        PROCEDURE, PUBLIC :: Close => Serial_Close
        PROCEDURE, PUBLIC :: WriteInt => Serial_WriteInt
        PROCEDURE, PUBLIC :: WriteReal => Serial_WriteReal
        PROCEDURE, PUBLIC :: WriteString => Serial_WriteString
        PROCEDURE, PUBLIC :: WriteBool => Serial_WriteBool
        PROCEDURE, PUBLIC :: WriteArrayInt => Serial_WriteArrayInt
        PROCEDURE, PUBLIC :: WriteArrayReal => Serial_WriteArrayReal
        PROCEDURE, PUBLIC :: BeginObject => Serial_BeginObject
        PROCEDURE, PUBLIC :: EndObject => Serial_EndObject
        PROCEDURE, PUBLIC :: BeginArray => Serial_BeginArray
        PROCEDURE, PUBLIC :: EndArray => Serial_EndArray
        PROCEDURE, PRIVATE :: WriteIndent => Serial_WriteIndent
        PROCEDURE, PRIVATE :: WriteComma => Serial_WriteComma
    END TYPE TreeSerializer
```

### `TreeDeserializer` (lines 322–343)

```fortran
    TYPE, PUBLIC :: TreeDeserializer
        INTEGER(i4) :: format = MD_MODEL_SERIAL_FORMAT_B
        TYPE(RW_Deserializer) :: rw_deserializer
        LOGICAL :: is_init = .FALSE.
        LOGICAL :: file_open = .FALSE.
        CHARACTER(LEN=256) :: file_path = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init => Deserial_Init
        PROCEDURE, PUBLIC :: Destroy => Deserial_Destroy
        PROCEDURE, PUBLIC :: Open => Deserial_Open
        PROCEDURE, PUBLIC :: Close => Deserial_Close
        PROCEDURE, PUBLIC :: ReadInt => Deserial_ReadInt
        PROCEDURE, PUBLIC :: ReadReal => Deserial_ReadReal
        PROCEDURE, PUBLIC :: ReadString => Deserial_ReadString
        PROCEDURE, PUBLIC :: ReadBool => Deserial_ReadBool
        PROCEDURE, PUBLIC :: ReadArrayInt => Deserial_ReadArrayInt
        PROCEDURE, PUBLIC :: ReadArrayReal => Deserial_ReadArrayReal
        PROCEDURE, PUBLIC :: BeginObject => Deserial_BeginObject
        PROCEDURE, PUBLIC :: EndObject => Deserial_EndObject
        PROCEDURE, PUBLIC :: BeginArray => Deserial_BeginArray
        PROCEDURE, PUBLIC :: EndArray => Deserial_EndArray
    END TYPE TreeDeserializer
```

### `BaseSystem` (lines 362–367)

```fortran
    TYPE, ABSTRACT, PUBLIC :: BaseSystem
        LOGICAL :: is_init = .FALSE.
    CONTAINS
        PROCEDURE(Init_IF), DEFERRED :: Init
        PROCEDURE(Shutdown_IF), DEFERRED :: Shutdown
    END TYPE BaseSystem
```

### `BaseManager` (lines 382–398)

```fortran
    TYPE, ABSTRACT, PUBLIC :: BaseManager
        INTEGER(i4) :: count = 0_i4
        INTEGER(i4) :: max_capacity = 0_i4
        LOGICAL :: is_init = .FALSE.
    CONTAINS
        PROCEDURE(Mgr_Init_IF), DEFERRED :: Init
        PROCEDURE(Mgr_Final_IF), DEFERRED :: Finalize
        PROCEDURE(Mgr_Create_IF), DEFERRED :: Create
        PROCEDURE(Mgr_Delete_IF), DEFERRED :: Delete
        PROCEDURE(Mgr_Find_IF), DEFERRED :: Find
        PROCEDURE(Mgr_Get_IF), DEFERRED :: Get
        PROCEDURE(Mgr_GetCount_IF), DEFERRED :: GetCount
        PROCEDURE(Mgr_List_IF), DEFERRED :: List
        PROCEDURE(Mgr_Valid_IF), DEFERRED :: Valid
        PROCEDURE(Mgr_ValidateConsistency_IF), DEFERRED :: ValidateConsistency
        PROCEDURE(Mgr_GetStatistics_IF), DEFERRED :: GetStatistics
    END TYPE BaseManager
```

### `BaseRegistry` (lines 464–477)

```fortran
    TYPE, ABSTRACT, PUBLIC :: BaseRegistry
        INTEGER(i4) :: max_capacity = 0_i4
        INTEGER(i4) :: registered_count = 0_i4
        LOGICAL :: is_init = .FALSE.
    CONTAINS
        PROCEDURE(Reg_Init_IF), DEFERRED :: Init
        PROCEDURE(Reg_Cleanup_IF), DEFERRED :: Cleanup
        PROCEDURE(Reg_Reg_IF), DEFERRED :: Reg
        PROCEDURE(Reg_Unregister_IF), DEFERRED :: Unregister
        PROCEDURE(Reg_Lookup_IF), DEFERRED :: Lookup
        PROCEDURE(Reg_Exists_IF), DEFERRED :: Exists
        PROCEDURE(Reg_GetCount_IF), DEFERRED :: GetRegisteredCount
        PROCEDURE(Reg_List_IF), DEFERRED :: ListRegistered
    END TYPE BaseRegistry
```

### `BaseAPI` (lines 530–535)

```fortran
    TYPE, ABSTRACT, PUBLIC :: BaseAPI
        LOGICAL :: is_init = .FALSE.
    CONTAINS
        PROCEDURE(API_Init_IF), DEFERRED :: Init
        PROCEDURE(API_Cleanup_IF), DEFERRED :: Cleanup
    END TYPE BaseAPI
```

### `BaseSta` (lines 553–562)

```fortran
    TYPE, PUBLIC :: BaseSta
        TYPE(ErrorStatusType), PRIVATE :: status_
        LOGICAL :: has_error = .false.
    CONTAINS
        PROCEDURE, PUBLIC :: SetStatus => BaseSta_SetStatus
        PROCEDURE, PUBLIC :: GetStatus => BaseSta_GetStatus
        PROCEDURE, PUBLIC :: ClearStatus => BaseSta_ClearStatus
        PROCEDURE, PUBLIC :: IsOK => BaseSta_IsOK
        PROCEDURE, PUBLIC :: IsError => BaseSta_IsError
    END TYPE BaseSta
```

### `BaseDesc` (lines 571–581)

```fortran
    TYPE, ABSTRACT, PUBLIC :: BaseDesc
        CHARACTER(LEN=80) :: name = ''  ! Object name
        LOGICAL :: is_init = .false.  ! Initialization flag
    CONTAINS
        PROCEDURE(Desc_Init_Intf), DEFERRED :: Init  ! Initialize Desc object
        PROCEDURE(Desc_Destroy_Intf), DEFERRED :: Destroy  ! Destroy Desc object
        PROCEDURE(Desc_Valid_Intf), DEFERRED :: Valid  ! Validate Desc object
        PROCEDURE(Desc_GetStatus_Intf), DEFERRED :: GetStatus  ! Get error status
        PROCEDURE(Desc_Serialize_Intf), DEFERRED :: Serialize  ! Serialize to stream
        PROCEDURE(Desc_Deserialize_Intf), DEFERRED :: Deserialize  ! Deserialize from stream
    END TYPE BaseDesc
```

### `BaseState` (lines 637–646)

```fortran
    TYPE, ABSTRACT, PUBLIC :: BaseState
        LOGICAL :: is_init = .false.  ! Initialization flag
    CONTAINS
        PROCEDURE(State_Init_Intf), DEFERRED :: Init  ! Initialize State object
        PROCEDURE(State_Destroy_Intf), DEFERRED :: Destroy  ! Destroy State object
        PROCEDURE(State_Clear_Intf), DEFERRED :: Clear  ! Clear State object
        PROCEDURE(State_GetStatus_Intf), DEFERRED :: GetStatus  ! Get error status
        PROCEDURE(State_Serialize_Intf), DEFERRED :: Serialize  ! Serialize to stream
        PROCEDURE(State_Deserialize_Intf), DEFERRED :: Deserialize  ! Deserialize from stream
    END TYPE BaseState
```

### `BaseAlgo` (lines 703–713)

```fortran
    TYPE, ABSTRACT, PUBLIC :: BaseAlgo
        CHARACTER(LEN=80) :: name = ''  ! Algorithm name
        LOGICAL :: is_init = .false.  ! Initialization flag
    CONTAINS
        PROCEDURE(Algo_Init_Intf), DEFERRED :: Init  ! Initialize Algo object
        PROCEDURE(Algo_Destroy_Intf), DEFERRED :: Destroy  ! Destroy Algo object
        PROCEDURE(Algo_Cfg_Intf), DEFERRED :: Cfg  ! Configure with Desc
        PROCEDURE(Algo_GetStatus_Intf), DEFERRED :: GetStatus  ! Get error status
        PROCEDURE(Algo_Serialize_Intf), DEFERRED :: Serialize  ! Serialize to stream
        PROCEDURE(Algo_Deserialize_Intf), DEFERRED :: Deserialize  ! Deserialize from stream
    END TYPE BaseAlgo
```

### `BaseCtx` (lines 770–784)

```fortran
    TYPE, ABSTRACT, PUBLIC :: BaseCtx
        LOGICAL :: is_init = .false.  ! Initialization flag
        TYPE(BaseSta) :: sta  ! Status object
    CONTAINS
        PROCEDURE(Ctx_Init_Intf), DEFERRED :: Init  ! Initialize Ctx object
        PROCEDURE(Ctx_Destroy_Intf), DEFERRED :: Destroy  ! Destroy Ctx object
        PROCEDURE(Ctx_Reset_Intf), DEFERRED :: Reset  ! Reset Ctx object
        PROCEDURE(Ctx_GetStatus_Intf), DEFERRED :: GetStatus  ! Get error status
        PROCEDURE(Ctx_Serialize_Intf), DEFERRED :: Serialize  ! Serialize to stream
        PROCEDURE(Ctx_Deserialize_Intf), DEFERRED :: Deserialize  ! Deserialize from stream
        PROCEDURE, PUBLIC :: SetStatus => BaseCtx_SetStatus  ! Set error status
        PROCEDURE, PUBLIC :: ClearStatus => BaseCtx_ClearStatus  ! Clear error status
        PROCEDURE, PUBLIC :: IsOK => BaseCtx_IsOK  ! Check if status is OK
        PROCEDURE, PUBLIC :: IsError => BaseCtx_IsError  ! Check if status is error
    END TYPE BaseCtx
```

### `ObjBase` (lines 834–851)

```fortran
    TYPE, ABSTRACT, PUBLIC :: ObjBase
        INTEGER(i4)       :: obj_id_   = 0_i4
        CHARACTER(LEN=64) :: obj_name_ = ""
        LOGICAL           :: obj_valid_    = .false.
        LOGICAL           :: obj_bound_    = .false.
    CONTAINS
        PROCEDURE, PUBLIC :: Id          => Obj_Id
        PROCEDURE, PUBLIC :: Name        => Obj_Name
        PROCEDURE, PUBLIC :: SetId       => Obj_SetId
        PROCEDURE, PUBLIC :: SetName     => Obj_SetName
        PROCEDURE, PUBLIC :: Valid       => Obj_Valid
        PROCEDURE, PUBLIC :: Bound       => Obj_Bound
        PROCEDURE, PUBLIC :: Invalidate  => Obj_Invalidate
        ! Simplified interface methods
        PROCEDURE, PUBLIC :: init => Obj_Init
        PROCEDURE, PUBLIC :: destroy => Obj_Destroy
        PROCEDURE, PUBLIC :: get_info => Obj_GetInfo
    END TYPE ObjBase
```

### `HashEntry` (lines 861–864)

```fortran
    TYPE, PUBLIC :: HashEntry
        INTEGER(i4) :: id   = 0_i4  ! Object ID stored at this entry
        INTEGER(i4) :: next = 0_i4  ! Next entry index (0 = end of chain)
    END TYPE HashEntry
```

### `ObjPtr` (lines 867–869)

```fortran
    TYPE, PRIVATE :: ObjPtr
        CLASS(ObjBase), POINTER :: p => null()
    END TYPE ObjPtr
```

### `ObjContainer` (lines 872–903)

```fortran
    TYPE, PUBLIC :: ObjContainer
        LOGICAL                              :: is_init          = .false.
        LOGICAL                              :: use_hash         = .true.
        LOGICAL                              :: index_dirty      = .false.
        INTEGER(i4)                          :: capacity         = 0_i4
        INTEGER(i4)                          :: count            = 0_i4
        INTEGER(i4)                          :: max_id           = 0_i4
        INTEGER(i4)                          :: hash_entry_coun  = 0_i4
        INTEGER(i4)                          :: hash_entry_capa  = 0_i4
        INTEGER(i4),       ALLOCATABLE       :: id_map(:)
        INTEGER(i4),       ALLOCATABLE       :: hash_table(:)
        TYPE(HashEntry),   ALLOCATABLE       :: hash_entries(:)
        TYPE(ObjPtr),      ALLOCATABLE       :: objects(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Init               => Container_Init
        PROCEDURE, PUBLIC :: Clean              => Container_Clean
        PROCEDURE, PUBLIC :: Clear              => Container_Clear
        PROCEDURE, PUBLIC :: Add                => Container_Add
        PROCEDURE, PUBLIC :: Remove             => Container_Remove
        PROCEDURE, PUBLIC :: Update             => Container_Update
        PROCEDURE, PUBLIC :: Find               => Container_Find
        PROCEDURE, PUBLIC :: GetByID            => Container_GetByID
        PROCEDURE, PUBLIC :: GetByName          => Container_GetByName
        PROCEDURE, PUBLIC :: GetByIndex         => Container_GetByIndex
        PROCEDURE, PUBLIC :: GetAllIDs          => Container_GetAllIDs
        PROCEDURE, PUBLIC :: GetCapacity        => Container_GetCapacity
        PROCEDURE, PUBLIC :: GetCount           => Container_GetCount
        PROCEDURE, PUBLIC :: Resize             => Container_Resize
        PROCEDURE, PUBLIC :: RebuildIndex       => Container_RebuildIndex
        PROCEDURE, PUBLIC :: ExpandHashEntries  => Container_ExpandHashEntries
        PROCEDURE, PUBLIC :: Valid              => Container_Valid
    END TYPE ObjContainer
```

### `IPState` (lines 908–934)

```fortran
    TYPE, PUBLIC :: IPState
        INTEGER(i4)             :: ipId           = 0_i4
        INTEGER(i4)             :: id             = 0_i4   ! element ID
        INTEGER(i4)             :: material_id    = 0_i4
        INTEGER(i4)             :: numStateVars   = 0_i4
        INTEGER(i4)             :: stateVars_id   = -1_i4
        INTEGER(i4)             :: stateVarsOld_id = -1_i4
        REAL(wp)                :: sigma          = 0.0_wp
        REAL(wp)                :: strain         = 0.0_wp
        REAL(wp)                :: plasticStrain  = 0.0_wp
        REAL(wp)                :: equivalentplast = 0.0_wp
        REAL(wp)                :: temperature    = 0.0_wp
        REAL(wp)                :: jacobian       = 1.0_wp
        REAL(wp), POINTER       :: stateVars(:)    => NULL()
        REAL(wp), POINTER       :: stateVarsOld(:) => NULL()
        LOGICAL,  ALLOCATABLE   :: isActive(:)
        CHARACTER(LEN=64), ALLOCATABLE :: stateNames(:)
        LOGICAL                 :: isInitialized  = .false.
    CONTAINS
        PROCEDURE, PUBLIC :: Init       => IPState_Init
        PROCEDURE, PUBLIC :: Reset      => IPState_Reset
        PROCEDURE, PUBLIC :: Restore    => IPState_Restore
        PROCEDURE, PUBLIC :: Save       => IPState_Save
        PROCEDURE, PUBLIC :: Update     => IPState_Update
        PROCEDURE, PUBLIC :: Ensure     => IPState_Ensure
        PROCEDURE, PUBLIC :: RegLayout  => IPState_RegLayout
    END TYPE IPState
```

### `ElemMatIntf` (lines 939–948)

```fortran
    TYPE, PUBLIC :: ElemMatIntf
        LOGICAL                           :: is_init      = .false.
        CLASS(*),            POINTER      :: material_ctx => NULL()
        CLASS(*),            POINTER      :: material_res => NULL()
        TYPE(IPState),       POINTER      :: ip_state     => NULL()
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => ElemMatIntf_Init
        PROCEDURE, PUBLIC :: Clean => ElemMatIntf_Clean
        PROCEDURE, PUBLIC :: Bind  => ElemMatIntf_Bind
    END TYPE ElemMatIntf
```

### `ElemStepCtx` (lines 953–963)

```fortran
    TYPE, PUBLIC :: ElemStepCtx
        LOGICAL                 :: is_init       = .false.
        INTEGER(i4)             :: step_id       = 0_i4
        INTEGER(i4)             :: increment_id  = 0_i4
        INTEGER(i4)             :: iteration_id  = 0_i4
        REAL(wp)                :: current_time  = 0.0_wp
        REAL(wp)                :: time_increment = 0.0_wp
    CONTAINS
        PROCEDURE, PUBLIC :: Init  => ElemStepCtx_Init
        PROCEDURE, PUBLIC :: Clean => ElemStepCtx_Clean
    END TYPE ElemStepCtx
```

### `UF_NodeHdl` (lines 1107–1110)

```fortran
    TYPE, PUBLIC :: UF_NodeHdl
        INTEGER(i4) :: id = 0_i4
        INTEGER(i4) :: index  = 0_i4
    END TYPE UF_NodeHdl
```

### `UF_ElemHdl` (lines 1112–1115)

```fortran
    TYPE, PUBLIC :: UF_ElemHdl
        INTEGER(i4) :: id = 0_i4
        INTEGER(i4) :: index  = 0_i4
    END TYPE UF_ElemHdl
```

### `UF_SetHdl` (lines 1117–1121)

```fortran
    TYPE, PUBLIC :: UF_SetHdl
        CHARACTER(LEN=64) :: name  = ""
        INTEGER(i4)       :: type  = 0_i4
        INTEGER(i4)       :: index = 0_i4
    END TYPE UF_SetHdl
```

### `UF_SurfHdl` (lines 1123–1126)

```fortran
    TYPE, PUBLIC :: UF_SurfHdl
        CHARACTER(LEN=64) :: name  = ""
        INTEGER(i4)       :: index = 0_i4
    END TYPE UF_SurfHdl
```

### `VarDesc` (lines 1131–1135)

```fortran
    TYPE, PUBLIC :: VarDesc
        CHARACTER(LEN=64) :: name = '', varName = ''
        INTEGER(i4)       :: location = 0_i4, dType = 0_i4, rank = 0_i4, dims(4) = 0_i4
        LOGICAL           :: is_history = .false., is_persistent = .false.
    END TYPE VarDesc
```

### `VarCtx` (lines 1137–1141)

```fortran
    TYPE, PUBLIC :: VarCtx
        CHARACTER(LEN=80) :: mName = ''
        INTEGER(i4)       :: maxVars = 0_i4, nVars = 0_i4
        TYPE(VarDesc), ALLOCATABLE :: vars(:)
    END TYPE VarCtx
```

### `DofMap` (lines 1146–1159)

```fortran
    TYPE, PUBLIC :: DofMap
        INTEGER(i4) :: nNode   = 0
        INTEGER(i4) :: maxDpn  = 0
        INTEGER, POINTER :: ndof(:) => null()
        INTEGER, POINTER :: eq_map(:,:) => null()
    CONTAINS
        PROCEDURE, PUBLIC :: Init     => dm_Init
        PROCEDURE, PUBLIC :: Free     => dm_Free
        PROCEDURE, PUBLIC :: SetNdof  => dm_SetNdof
        PROCEDURE, PUBLIC :: MakeEq   => dm_MakeEq
        PROCEDURE, PUBLIC :: Eq       => dm_Eq
        PROCEDURE, PUBLIC :: NodeRng  => dm_NodeRng
        PROCEDURE, PUBLIC :: Neq      => dm_Neq
    END TYPE DofMap
```

### `DofLabMap` (lines 1161–1169)

```fortran
    TYPE, PUBLIC :: DofLabMap
        INTEGER(i4) :: n_lbl = 0
        INTEGER, ALLOCATABLE :: lbl(:)
        INTEGER, ALLOCATABLE :: slot_arr(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Init    => lm_Init
        PROCEDURE, PUBLIC :: Free    => lm_Free
        PROCEDURE, PUBLIC :: Slot    => lm_Slot
    END TYPE DofLabMap
```

### `DofSys` (lines 1171–1188)

```fortran
    TYPE, PUBLIC :: DofSys
        TYPE(DofMap) :: dm
        TYPE(DofLabMap)  :: lm
        CHARACTER(LEN=64)   :: ndofVar = "MD_MODEL_DOF_ndof"
        CHARACTER(LEN=64)   :: eqVar   = "MD_MODEL_DOF_eq"
        CHARACTER(LEN=64)   :: fidVar  = "MD_MODEL_DOF_fid"
        INTEGER, POINTER    :: eq_fid(:)     => null()
        LOGICAL             :: stored     = .false.
    CONTAINS
        PROCEDURE, PUBLIC :: Init            => ds_Init
        PROCEDURE, PUBLIC :: InitFromNdof    => ds_InitNdof
        PROCEDURE, PUBLIC :: Ensure          => DofSys_Ensure
        PROCEDURE, PUBLIC :: Build           => DofSys_Build
        PROCEDURE, PUBLIC :: BuildSimple     => ds_BuildEq
        PROCEDURE, PUBLIC :: EqByLbl         => ds_eq_of_lbl
        PROCEDURE, PUBLIC :: Eq              => ds_eq_of_node_slot
        PROCEDURE, PUBLIC :: NodeEqRng       => ds_node_eq_rng
    END TYPE DofSys
```

### `UF_FldDesc` (lines 1193–1201)

```fortran
    TYPE, PUBLIC :: UF_FldDesc
        CHARACTER(LEN=:), ALLOCATABLE :: name
        INTEGER(i4) :: loc  = MD_MODEL_UF_FLD_AT_NODE
        INTEGER(i4) :: bas  = MD_MODEL_UF_FLD_REAL8
        INTEGER(i4) :: rank = 0_i4
        INTEGER(i4), ALLOCATABLE :: eshape(:)
    CONTAINS
        PROCEDURE, PUBLIC :: compat => fd_compat
    END TYPE UF_FldDesc
```

### `UF_FldHdl` (lines 1203–1208)

```fortran
    TYPE, PUBLIC :: UF_FldHdl
        TYPE(UF_FldDesc) :: desc
        CHARACTER(LEN=64) :: name = ""
    CONTAINS
        PROCEDURE, PUBLIC :: assoc => fh_assoc
    END TYPE UF_FldHdl
```

### `UF_FldRegEnt` (lines 1210–1214)

```fortran
    TYPE :: UF_FldRegEnt
        TYPE(UF_FldDesc) :: desc
        CHARACTER(LEN=64) :: name
        INTEGER(i4)      :: nEntities = 0_i4
    END TYPE UF_FldRegEnt
```

### `UF_FldSys` (lines 1216–1225)

```fortran
    TYPE, PUBLIC :: UF_FldSys
        TYPE(UF_FldRegEnt), ALLOCATABLE :: reg(:)
    CONTAINS
        PROCEDURE, PUBLIC :: init  => fs_init
        PROCEDURE, PUBLIC :: reg_f => fs_reg_f
        PROCEDURE, PUBLIC :: find  => fs_find
        PROCEDURE, PUBLIC :: bind  => fs_bind
        PROCEDURE, PUBLIC :: get   => fs_get
        PROCEDURE, PUBLIC :: get_ptr_1d => fs_get_ptr_1d
    END TYPE UF_FldSys
```

### `UF_UFField` (lines 1227–1235)

```fortran
    TYPE, PUBLIC :: UF_UFField
        TYPE(UF_FldDesc) :: desc
        INTEGER(i4)      :: fieldType = 0_i4
        INTEGER(i4)      :: nDof      = 0_i4
        INTEGER(i4)      :: eqStart   = 0_i4
        INTEGER(i4)      :: eqEnd     = 0_i4
    CONTAINS
        PROCEDURE, PUBLIC :: span => uf_field_span
    END TYPE UF_UFField
```

### `UF_UFCore` (lines 1237–1246)

```fortran
    TYPE, PUBLIC :: UF_UFCore
        INTEGER(i4) :: nFields = 0_i4
        INTEGER(i4) :: nEq     = 0_i4
        TYPE(UF_UFField), ALLOCATABLE :: fields(:)
    CONTAINS
        PROCEDURE, PUBLIC :: reset       => uf_reset
        PROCEDURE, PUBLIC :: add_field   => uf_add_field
        PROCEDURE, PUBLIC :: get_field   => uf_get_field
        PROCEDURE, PUBLIC :: get_eq_span => uf_get_eq_span
    END TYPE UF_UFCore
```

### `UFView` (lines 1251–1262)

```fortran
    TYPE, PUBLIC :: UFView
        INTEGER(i4) :: nFields = 0_i4
        INTEGER(i4) :: nEq     = 0_i4
        TYPE(DofMap), POINTER :: dm => null()
        TYPE(UF_UFField), ALLOCATABLE :: fields(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Reset       => uf_ResetView
        PROCEDURE, PUBLIC :: Attach      => uf_AttachDm
        PROCEDURE, PUBLIC :: AddField    => uf_AddField
        PROCEDURE, PUBLIC :: GetField    => uf_GetField
        PROCEDURE, PUBLIC :: Span        => uf_GetEqSpan
    END TYPE UFView
```

### `ModelSys` (lines 1264–1273)

```fortran
    TYPE, PUBLIC :: ModelSys
        TYPE(DofSys)     :: dof_system
        TYPE(UF_FldSys)  :: fld_system
        TYPE(UFView) :: uf_view
        LOGICAL          :: is_init = .false.
    CONTAINS
        PROCEDURE, PUBLIC :: Init        => ms_init
        PROCEDURE, PUBLIC :: BuildDof    => ModelSys_BuildDof
        PROCEDURE, PUBLIC :: SetupUIF    => ModelSys_SetupUIF
    END TYPE ModelSys
```

### `UF_ModelDesc` (lines 1278–1281)

```fortran
    TYPE, PUBLIC :: UF_ModelDesc
        INTEGER(i4) :: id = 0
        CHARACTER(LEN=256) :: name = ""
    END TYPE UF_ModelDesc
```

### `UF_Node` (lines 1283–1289)

```fortran
    TYPE, PUBLIC :: UF_Node
        INTEGER(i4) :: id = 0
        REAL(wp) :: coords(3) = 0.0_wp
        INTEGER(i4), ALLOCATABLE :: dofTypes(:)
        LOGICAL :: isreferencepoin = .false.
        CHARACTER(LEN=64) :: name = ""
    END TYPE UF_Node
```

### `UF_Element` (lines 1291–1295)

```fortran
    TYPE, PUBLIC :: UF_Element
        INTEGER(i4) :: id = 0_i4
        INTEGER(i4) :: elemTypeId = 0_i4
        INTEGER(i4), ALLOCATABLE :: conn(:)
    END TYPE UF_Element
```

### `UF_NodeSet` (lines 1297–1300)

```fortran
    TYPE, PUBLIC :: UF_NodeSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: nodeIds(:)
    END TYPE UF_NodeSet
```

### `UF_ElemSet` (lines 1302–1305)

```fortran
    TYPE, PUBLIC :: UF_ElemSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: elemIds(:)
    END TYPE UF_ElemSet
```

### `UF_SurfSet` (lines 1307–1311)

```fortran
    TYPE, PUBLIC :: UF_SurfSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: elemIds(:)
        INTEGER(i4), ALLOCATABLE :: faceIds(:)
    END TYPE UF_SurfSet
```

### `UF_Part` (lines 1313–1320)

```fortran
    TYPE, PUBLIC :: UF_Part
        CHARACTER(LEN=64) :: name = ""
        TYPE(UF_Node), ALLOCATABLE :: nodes(:)
        TYPE(UF_Element), ALLOCATABLE :: elements(:)
        TYPE(UF_NodeSet), ALLOCATABLE :: nodeSets(:)
        TYPE(UF_ElemSet), ALLOCATABLE :: elemSets(:)
        TYPE(UF_SurfSet), ALLOCATABLE :: surfSets(:)
    END TYPE UF_Part
```

### `UF_Instance` (lines 1322–1326)

```fortran
    TYPE, PUBLIC :: UF_Instance
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: part_id = 0_i4   ! Index into model%parts(:), 0 = unset
    END TYPE UF_Instance
```

### `UF_Assem` (lines 1328–1337)

```fortran
    TYPE, PUBLIC :: UF_Assem
        TYPE(UF_Instance), ALLOCATABLE :: instances(:)
        TYPE(UF_NodeSet), ALLOCATABLE :: nodeSets(:)
        TYPE(UF_ElemSet), ALLOCATABLE :: elemSets(:)
        TYPE(UF_SurfSet), ALLOCATABLE :: surfSets(:)
        ! Cached global counts (0 = not yet computed)
        INTEGER(i4) :: total_nodes = 0_i4
        INTEGER(i4) :: total_elements = 0_i4
        INTEGER(i4) :: totDofs = 0_i4
    END TYPE UF_Assem
```

### `UF_Description` (lines 1339–1341)

```fortran
    TYPE, PUBLIC :: UF_Description
        CHARACTER(LEN=256) :: name = ""
    END TYPE UF_Description
```

### `UF_Model` (lines 1343–1349)

```fortran
    TYPE, PUBLIC :: UF_Model
        TYPE(UF_Description) :: desc
        TYPE(UF_Assem) :: assembly
        TYPE(UF_Part), ALLOCATABLE :: parts(:)
        TYPE(AnalysisStep), ALLOCATABLE :: steps(:)
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE :: amplitudes(:)
    END TYPE UF_Model
```

### `RT_Node` (lines 1351–1355)

```fortran
    TYPE, PUBLIC :: RT_Node
        INTEGER(i4) :: id = 0
        REAL(wp) :: coords(3) = 0.0_wp
        INTEGER(i4), ALLOCATABLE :: dofTypes(:)
    END TYPE RT_Node
```

### `RT_Element` (lines 1357–1361)

```fortran
    TYPE, PUBLIC :: RT_Element
        INTEGER(i4) :: id = 0_i4
        INTEGER(i4) :: elemTypeId = 0_i4
        INTEGER(i4), ALLOCATABLE :: conn(:)
    END TYPE RT_Element
```

### `RT_Model` (lines 1363–1367)

```fortran
    TYPE, PUBLIC :: RT_Model
        TYPE(UF_Description) :: desc
        TYPE(UF_Assem) :: assembly
        TYPE(UF_Part), ALLOCATABLE :: parts(:)
    END TYPE RT_Model
```

### `NodeSet` (lines 1369–1372)

```fortran
    TYPE, PUBLIC :: NodeSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: nodeIds(:)
    END TYPE NodeSet
```

### `ElemSet` (lines 1374–1377)

```fortran
    TYPE, PUBLIC :: ElemSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: elemIds(:)
    END TYPE ElemSet
```

### `SurfSet` (lines 1379–1383)

```fortran
    TYPE, PUBLIC :: SurfSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: elemIds(:)
        INTEGER(i4), ALLOCATABLE :: faceIds(:)
    END TYPE SurfSet
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Serialize_IF` | 347 | `SUBROUTINE Serialize_IF(this, serializer)` |
| SUBROUTINE | `Deserialize_IF` | 352 | `SUBROUTINE Deserialize_IF(this, deserializer)` |
| SUBROUTINE | `Init_IF` | 370 | `SUBROUTINE Init_IF(this, status)` |
| SUBROUTINE | `Shutdown_IF` | 375 | `SUBROUTINE Shutdown_IF(this, status)` |
| SUBROUTINE | `Mgr_Init_IF` | 401 | `SUBROUTINE Mgr_Init_IF(this, max_capacity, status)` |
| SUBROUTINE | `Mgr_Final_IF` | 407 | `SUBROUTINE Mgr_Final_IF(this, status)` |
| SUBROUTINE | `Mgr_Create_IF` | 412 | `SUBROUTINE Mgr_Create_IF(this, id, name, status)` |
| SUBROUTINE | `Mgr_Delete_IF` | 419 | `SUBROUTINE Mgr_Delete_IF(this, id, status)` |
| FUNCTION | `Mgr_Find_IF` | 425 | `FUNCTION Mgr_Find_IF(this, name) RESULT(id)` |
| SUBROUTINE | `Mgr_Get_IF` | 431 | `SUBROUTINE Mgr_Get_IF(this, id, status)` |
| FUNCTION | `Mgr_GetCount_IF` | 437 | `FUNCTION Mgr_GetCount_IF(this) RESULT(n)` |
| SUBROUTINE | `Mgr_List_IF` | 442 | `SUBROUTINE Mgr_List_IF(this, status)` |
| FUNCTION | `Mgr_Valid_IF` | 447 | `FUNCTION Mgr_Valid_IF(this) RESULT(ok)` |
| SUBROUTINE | `Mgr_ValidateConsistency_IF` | 452 | `SUBROUTINE Mgr_ValidateConsistency_IF(this, status)` |
| SUBROUTINE | `Mgr_GetStatistics_IF` | 457 | `SUBROUTINE Mgr_GetStatistics_IF(this, status)` |
| SUBROUTINE | `Reg_Init_IF` | 480 | `SUBROUTINE Reg_Init_IF(this, max_capacity, status)` |
| SUBROUTINE | `Reg_Cleanup_IF` | 486 | `SUBROUTINE Reg_Cleanup_IF(this, status)` |
| SUBROUTINE | `Reg_Reg_IF` | 491 | `SUBROUTINE Reg_Reg_IF(this, name, item, status)` |
| SUBROUTINE | `Reg_Unregister_IF` | 498 | `SUBROUTINE Reg_Unregister_IF(this, name, status)` |
| FUNCTION | `Reg_Lookup_IF` | 504 | `FUNCTION Reg_Lookup_IF(this, name) RESULT(found)` |
| FUNCTION | `Reg_Exists_IF` | 510 | `FUNCTION Reg_Exists_IF(this, name) RESULT(exists)` |
| FUNCTION | `Reg_GetCount_IF` | 516 | `FUNCTION Reg_GetCount_IF(this) RESULT(n)` |
| SUBROUTINE | `Reg_List_IF` | 521 | `SUBROUTINE Reg_List_IF(this, names, count, status)` |
| SUBROUTINE | `API_Init_IF` | 538 | `SUBROUTINE API_Init_IF(this, status)` |
| SUBROUTINE | `API_Cleanup_IF` | 543 | `SUBROUTINE API_Cleanup_IF(this, status)` |
| SUBROUTINE | `Desc_Init_Intf` | 585 | `SUBROUTINE Desc_Init_Intf(this)` |
| SUBROUTINE | `Desc_Destroy_Intf` | 590 | `SUBROUTINE Desc_Destroy_Intf(this)` |
| FUNCTION | `Desc_Valid_Intf` | 596 | `FUNCTION Desc_Valid_Intf(this) RESULT(is_valid)` |
| FUNCTION | `Desc_GetStatus_Intf` | 603 | `FUNCTION Desc_GetStatus_Intf(this) RESULT(status)` |
| SUBROUTINE | `Desc_Serialize_Intf` | 612 | `SUBROUTINE Desc_Serialize_Intf(this, serializer, status)` |
| SUBROUTINE | `Desc_Deserialize_Intf` | 622 | `SUBROUTINE Desc_Deserialize_Intf(this, deserializer, status)` |
| SUBROUTINE | `State_Init_Intf` | 652 | `SUBROUTINE State_Init_Intf(this, n)` |
| SUBROUTINE | `State_Destroy_Intf` | 658 | `SUBROUTINE State_Destroy_Intf(this)` |
| SUBROUTINE | `State_Clear_Intf` | 663 | `SUBROUTINE State_Clear_Intf(this)` |
| FUNCTION | `State_GetStatus_Intf` | 669 | `FUNCTION State_GetStatus_Intf(this) RESULT(status)` |
| SUBROUTINE | `State_Serialize_Intf` | 678 | `SUBROUTINE State_Serialize_Intf(this, serializer, status)` |
| SUBROUTINE | `State_Deserialize_Intf` | 688 | `SUBROUTINE State_Deserialize_Intf(this, deserializer, status)` |
| SUBROUTINE | `Algo_Init_Intf` | 717 | `SUBROUTINE Algo_Init_Intf(this)` |
| SUBROUTINE | `Algo_Destroy_Intf` | 722 | `SUBROUTINE Algo_Destroy_Intf(this)` |
| SUBROUTINE | `Algo_Cfg_Intf` | 729 | `SUBROUTINE Algo_Cfg_Intf(this, config)` |
| FUNCTION | `Algo_GetStatus_Intf` | 736 | `FUNCTION Algo_GetStatus_Intf(this) RESULT(status)` |
| SUBROUTINE | `Algo_Serialize_Intf` | 745 | `SUBROUTINE Algo_Serialize_Intf(this, serializer, status)` |
| SUBROUTINE | `Algo_Deserialize_Intf` | 755 | `SUBROUTINE Algo_Deserialize_Intf(this, deserializer, status)` |
| SUBROUTINE | `Ctx_Init_Intf` | 788 | `SUBROUTINE Ctx_Init_Intf(this)` |
| SUBROUTINE | `Ctx_Destroy_Intf` | 793 | `SUBROUTINE Ctx_Destroy_Intf(this)` |
| SUBROUTINE | `Ctx_Reset_Intf` | 798 | `SUBROUTINE Ctx_Reset_Intf(this)` |
| FUNCTION | `Ctx_GetStatus_Intf` | 804 | `FUNCTION Ctx_GetStatus_Intf(this) RESULT(status)` |
| SUBROUTINE | `Ctx_Serialize_Intf` | 813 | `SUBROUTINE Ctx_Serialize_Intf(this, serializer, status)` |
| SUBROUTINE | `Ctx_Deserialize_Intf` | 823 | `SUBROUTINE Ctx_Deserialize_Intf(this, deserializer, status)` |
| SUBROUTINE | `RegLayout_Proc` | 973 | `SUBROUTINE RegLayout_Proc(this)` |
| SUBROUTINE | `Ensure_Proc` | 976 | `SUBROUTINE Ensure_Proc(this)` |
| SUBROUTINE | `AlgoBase_Cfg` | 1413 | `SUBROUTINE AlgoBase_Cfg(this, config)` |
| SUBROUTINE | `AlgoBase_Deserialize` | 1421 | `SUBROUTINE AlgoBase_Deserialize(this, deserializer, status)` |
| SUBROUTINE | `AlgoBase_Destroy` | 1447 | `SUBROUTINE AlgoBase_Destroy(this)` |
| FUNCTION | `AlgoBase_GetCategory` | 1456 | `FUNCTION AlgoBase_GetCategory(this) RESULT(cat)` |
| FUNCTION | `AlgoBase_GetStatus` | 1463 | `FUNCTION AlgoBase_GetStatus(this) RESULT(status)` |
| FUNCTION | `AlgoBase_GetTypeName` | 1474 | `FUNCTION AlgoBase_GetTypeName(this) RESULT(name)` |
| FUNCTION | `AlgoBase_GetVarName` | 1481 | `FUNCTION AlgoBase_GetVarName(this) RESULT(name)` |
| SUBROUTINE | `AlgoBase_Init` | 1488 | `SUBROUTINE AlgoBase_Init(this)` |
| FUNCTION | `AlgoBase_IsAlgo` | 1495 | `FUNCTION AlgoBase_IsAlgo(this) RESULT(res)` |
| SUBROUTINE | `AlgoBase_Serialize` | 1502 | `SUBROUTINE AlgoBase_Serialize(this, serializer, status)` |
| SUBROUTINE | `AlgoBase_SetTypeName` | 1547 | `SUBROUTINE AlgoBase_SetTypeName(this, name)` |
| SUBROUTINE | `AlgoBase_SetVarName` | 1554 | `SUBROUTINE AlgoBase_SetVarName(this, name)` |
| SUBROUTINE | `Base_ClearBinding` | 1561 | `SUBROUTINE Base_ClearBinding(self)` |
| SUBROUTINE | `Base_Init` | 1568 | `SUBROUTINE Base_Init(self, name, id, status)` |
| SUBROUTINE | `BaseCtx_ClearStatus` | 1580 | `SUBROUTINE BaseCtx_ClearStatus(this)` |
| FUNCTION | `BaseCtx_IsError` | 1586 | `FUNCTION BaseCtx_IsError(this) RESULT(is_error)` |
| FUNCTION | `BaseCtx_IsOK` | 1595 | `FUNCTION BaseCtx_IsOK(this) RESULT(is_ok)` |
| SUBROUTINE | `BaseCtx_SetStatus` | 1604 | `SUBROUTINE BaseCtx_SetStatus(this, status)` |
| SUBROUTINE | `BaseSta_ClearStatus` | 1611 | `SUBROUTINE BaseSta_ClearStatus(this)` |
| FUNCTION | `BaseSta_GetStatus` | 1618 | `FUNCTION BaseSta_GetStatus(this) RESULT(status)` |
| FUNCTION | `BaseSta_IsError` | 1625 | `FUNCTION BaseSta_IsError(this) RESULT(is_error)` |
| FUNCTION | `BaseSta_IsOK` | 1632 | `FUNCTION BaseSta_IsOK(this) RESULT(is_ok)` |
| SUBROUTINE | `BaseSta_SetStatus` | 1639 | `SUBROUTINE BaseSta_SetStatus(this, status)` |
| SUBROUTINE | `Container_Add` | 1647 | `SUBROUTINE Container_Add(this, obj, status)` |
| SUBROUTINE | `Container_Clean` | 1699 | `SUBROUTINE Container_Clean(this, status)` |
| SUBROUTINE | `Container_Clear` | 1719 | `SUBROUTINE Container_Clear(this, status)` |
| SUBROUTINE | `Container_ExpandHashEntries` | 1737 | `SUBROUTINE Container_ExpandHashEntries(this, status)` |
| FUNCTION | `Container_Find` | 1758 | `FUNCTION Container_Find(this, id, name) RESULT(obj_ptr)` |
| SUBROUTINE | `Container_GetAllIDs` | 1772 | `SUBROUTINE Container_GetAllIDs(this, ids, status)` |
| FUNCTION | `Container_GetByID` | 1808 | `FUNCTION Container_GetByID(this, id) RESULT(obj_ptr)` |
| FUNCTION | `Container_GetByIndex` | 1822 | `FUNCTION Container_GetByIndex(this, index) RESULT(obj_ptr)` |
| FUNCTION | `Container_GetByName` | 1833 | `FUNCTION Container_GetByName(this, name) RESULT(obj_ptr)` |
| FUNCTION | `Container_GetCapacity` | 1854 | `FUNCTION Container_GetCapacity(this) RESULT(capacity)` |
| FUNCTION | `Container_GetCount` | 1861 | `FUNCTION Container_GetCount(this) RESULT(count)` |
| SUBROUTINE | `Container_Init` | 1868 | `SUBROUTINE Container_Init(this, init_cap, status)` |
| SUBROUTINE | `Container_RebuildIndex` | 1895 | `SUBROUTINE Container_RebuildIndex(this, status)` |
| SUBROUTINE | `Container_Remove` | 1944 | `SUBROUTINE Container_Remove(this, id, status)` |
| SUBROUTINE | `Container_Resize` | 1997 | `SUBROUTINE Container_Resize(this, new_capacity, status)` |
| SUBROUTINE | `Container_Update` | 2035 | `SUBROUTINE Container_Update(this, id, obj, status)` |
| SUBROUTINE | `Container_Valid` | 2099 | `SUBROUTINE Container_Valid(this, status)` |
| SUBROUTINE | `CtxBase_Deserialize` | 2132 | `SUBROUTINE CtxBase_Deserialize(this, deserializer, status)` |
| SUBROUTINE | `CtxBase_Destroy` | 2156 | `SUBROUTINE CtxBase_Destroy(this)` |
| FUNCTION | `CtxBase_GetCategory` | 2165 | `FUNCTION CtxBase_GetCategory(this) RESULT(cat)` |
| FUNCTION | `CtxBase_GetStatus` | 2172 | `FUNCTION CtxBase_GetStatus(this) RESULT(status)` |
| FUNCTION | `CtxBase_GetTypeName` | 2179 | `FUNCTION CtxBase_GetTypeName(this) RESULT(name)` |
| FUNCTION | `CtxBase_GetVarName` | 2186 | `FUNCTION CtxBase_GetVarName(this) RESULT(name)` |
| SUBROUTINE | `CtxBase_Init` | 2193 | `SUBROUTINE CtxBase_Init(this)` |
| FUNCTION | `CtxBase_IsCtx` | 2200 | `FUNCTION CtxBase_IsCtx(this) RESULT(res)` |
| SUBROUTINE | `CtxBase_Reset` | 2207 | `SUBROUTINE CtxBase_Reset(this)` |
| SUBROUTINE | `CtxBase_Serialize` | 2213 | `SUBROUTINE CtxBase_Serialize(this, serializer, status)` |
| SUBROUTINE | `CtxBase_SetTypeName` | 2236 | `SUBROUTINE CtxBase_SetTypeName(this, name)` |
| SUBROUTINE | `CtxBase_SetVarName` | 2243 | `SUBROUTINE CtxBase_SetVarName(this, name)` |
| SUBROUTINE | `DescBase_Deserialize` | 2250 | `SUBROUTINE DescBase_Deserialize(this, deserializer, status)` |
| SUBROUTINE | `DescBase_Destroy` | 2276 | `SUBROUTINE DescBase_Destroy(this)` |
| FUNCTION | `DescBase_GetCategory` | 2285 | `FUNCTION DescBase_GetCategory(this) RESULT(cat)` |
| FUNCTION | `DescBase_GetStatus` | 2292 | `FUNCTION DescBase_GetStatus(this) RESULT(status)` |
| FUNCTION | `DescBase_GetTypeName` | 2303 | `FUNCTION DescBase_GetTypeName(this) RESULT(name)` |
| FUNCTION | `DescBase_GetVarName` | 2310 | `FUNCTION DescBase_GetVarName(this) RESULT(name)` |
| SUBROUTINE | `DescBase_Init` | 2317 | `SUBROUTINE DescBase_Init(this)` |
| FUNCTION | `DescBase_IsDesc` | 2324 | `FUNCTION DescBase_IsDesc(this) RESULT(res)` |
| SUBROUTINE | `DescBase_Serialize` | 2331 | `SUBROUTINE DescBase_Serialize(this, serializer, status)` |
| SUBROUTINE | `DescBase_SetTypeName` | 2376 | `SUBROUTINE DescBase_SetTypeName(this, name)` |
| SUBROUTINE | `DescBase_SetVarName` | 2383 | `SUBROUTINE DescBase_SetVarName(this, name)` |
| FUNCTION | `DescBase_Valid` | 2390 | `FUNCTION DescBase_Valid(this) RESULT(is_valid)` |
| FUNCTION | `Deserial_BeginArray` | 2397 | `FUNCTION Deserial_BeginArray(this, status) RESULT(name)` |
| FUNCTION | `Deserial_BeginObject` | 2405 | `FUNCTION Deserial_BeginObject(this, status) RESULT(name)` |
| SUBROUTINE | `Deserial_Close` | 2413 | `SUBROUTINE Deserial_Close(this, status)` |
| SUBROUTINE | `Deserial_Destroy` | 2433 | `SUBROUTINE Deserial_Destroy(this, status)` |
| SUBROUTINE | `Deserial_EndArray` | 2446 | `SUBROUTINE Deserial_EndArray(this, status)` |
| SUBROUTINE | `Deserial_EndObject` | 2458 | `SUBROUTINE Deserial_EndObject(this, status)` |
| SUBROUTINE | `Deserial_Init` | 2470 | `SUBROUTINE Deserial_Init(this, format, status)` |
| SUBROUTINE | `Deserial_Open` | 2483 | `SUBROUTINE Deserial_Open(this, file_path, status)` |
| SUBROUTINE | `Deserial_ReadArrayInt` | 2507 | `SUBROUTINE Deserial_ReadArrayInt(this, array, status)` |
| SUBROUTINE | `Deserial_ReadArrayReal` | 2530 | `SUBROUTINE Deserial_ReadArrayReal(this, array, status)` |
| FUNCTION | `Deserial_ReadBool` | 2553 | `FUNCTION Deserial_ReadBool(this, status) RESULT(value)` |
| FUNCTION | `Deserial_ReadInt` | 2563 | `FUNCTION Deserial_ReadInt(this, status) RESULT(value)` |
| FUNCTION | `Deserial_ReadReal` | 2585 | `FUNCTION Deserial_ReadReal(this, status) RESULT(value)` |
| FUNCTION | `Deserial_ReadString` | 2607 | `FUNCTION Deserial_ReadString(this, status) RESULT(value)` |
| FUNCTION | `dm_Eq` | 2635 | `FUNCTION dm_Eq(this, node, slot) RESULT(eq)` |
| SUBROUTINE | `dm_Free` | 2648 | `SUBROUTINE dm_Free(this)` |
| SUBROUTINE | `dm_Init` | 2659 | `SUBROUTINE dm_Init(this, nNode, maxDpn)` |
| SUBROUTINE | `dm_MakeEq` | 2671 | `SUBROUTINE dm_MakeEq(this)` |
| FUNCTION | `dm_Neq` | 2684 | `FUNCTION dm_Neq(this) RESULT(neq)` |
| FUNCTION | `dm_NodeRng` | 2694 | `FUNCTION dm_NodeRng(this, node) RESULT(rng)` |
| SUBROUTINE | `dm_SetNdof` | 2712 | `SUBROUTINE dm_SetNdof(this, node, ndof)` |
| SUBROUTINE | `DofSys_Build` | 2721 | `SUBROUTINE DofSys_Build(this)` |
| SUBROUTINE | `DofSys_Ensure` | 2728 | `SUBROUTINE DofSys_Ensure(this)` |
| SUBROUTINE | `ds_BuildEq` | 2737 | `SUBROUTINE ds_BuildEq(this, ndof_array)` |
| FUNCTION | `ds_eq_of_lbl` | 2745 | `FUNCTION ds_eq_of_lbl(this, lbl) RESULT(eq)` |
| FUNCTION | `ds_eq_of_node_slot` | 2754 | `FUNCTION ds_eq_of_node_slot(this, node, slot) RESULT(eq)` |
| SUBROUTINE | `ds_Init` | 2762 | `SUBROUTINE ds_Init(this, nNode, maxDpn)` |
| SUBROUTINE | `ds_InitNdof` | 2770 | `SUBROUTINE ds_InitNdof(this, ndof_array)` |
| FUNCTION | `ds_node_eq_rng` | 2783 | `FUNCTION ds_node_eq_rng(this, node) RESULT(rng)` |
| SUBROUTINE | `ElemMatIntf_Bind` | 2791 | `SUBROUTINE ElemMatIntf_Bind(this, material_ctx, material_res, ip_state)` |
| SUBROUTINE | `ElemMatIntf_Clean` | 2802 | `SUBROUTINE ElemMatIntf_Clean(this)` |
| SUBROUTINE | `ElemMatIntf_Init` | 2811 | `SUBROUTINE ElemMatIntf_Init(this, status)` |
| SUBROUTINE | `ElemSet_FromIds` | 2823 | `SUBROUTINE ElemSet_FromIds(name, ids, set)` |
| SUBROUTINE | `ElemSet_Intersect` | 2836 | `SUBROUTINE ElemSet_Intersect(a, b, out)` |
| SUBROUTINE | `ElemSet_Subtract` | 2861 | `SUBROUTINE ElemSet_Subtract(a, b, out)` |
| SUBROUTINE | `ElemSet_Union` | 2891 | `SUBROUTINE ElemSet_Union(a, b, out)` |
| SUBROUTINE | `ElemStepCtx_Clean` | 2917 | `SUBROUTINE ElemStepCtx_Clean(this)` |
| SUBROUTINE | `ElemStepCtx_Init` | 2928 | `SUBROUTINE ElemStepCtx_Init(this, step_id, increment_id, iteration_id, current_time, time_increment, status)` |
| SUBROUTINE | `fs_bind` | 2944 | `SUBROUTINE fs_bind(this, desc, nEntities, fh, status)` |
| SUBROUTINE | `fs_get` | 2963 | `SUBROUTINE fs_get(this, name, fh)` |
| SUBROUTINE | `fs_get_ptr_1d` | 2978 | `SUBROUTINE fs_get_ptr_1d(this, fh, ptr, status)` |
| SUBROUTINE | `fs_init` | 3012 | `SUBROUTINE fs_init(this)` |
| FUNCTION | `fs_find` | 3021 | `FUNCTION fs_find(this, name) RESULT(idx)` |
| FUNCTION | `fd_compat` | 3036 | `FUNCTION fd_compat(this) RESULT(ok)` |
| FUNCTION | `fh_assoc` | 3043 | `FUNCTION fh_assoc(this) RESULT(ok)` |
| SUBROUTINE | `fs_reg_f` | 3050 | `SUBROUTINE fs_reg_f(this, desc, nEntities, status)` |
| FUNCTION | `GetCategory` | 3106 | `FUNCTION GetCategory(self) RESULT(cat)` |
| FUNCTION | `HashString` | 3113 | `FUNCTION HashString(str) RESULT(hash)` |
| SUBROUTINE | `Init_EnergyBuckets` | 3128 | `SUBROUTINE Init_EnergyBuckets(nBuckets, buckets)` |
| SUBROUTINE | `IPState_Ensure` | 3138 | `SUBROUTINE IPState_Ensure(this)` |
| SUBROUTINE | `IPState_Init` | 3143 | `SUBROUTINE IPState_Init(this, ipId, elemId, materialId, numStateVars, status)` |
| SUBROUTINE | `IPState_RegLayout` | 3190 | `SUBROUTINE IPState_RegLayout(this)` |
| SUBROUTINE | `IPState_Reset` | 3195 | `SUBROUTINE IPState_Reset(this)` |
| SUBROUTINE | `IPState_Restore` | 3207 | `SUBROUTINE IPState_Restore(this)` |
| SUBROUTINE | `IPState_Save` | 3213 | `SUBROUTINE IPState_Save(this)` |
| SUBROUTINE | `IPState_Update` | 3219 | `SUBROUTINE IPState_Update(this)` |
| FUNCTION | `Is_Elem_In_Set` | 3225 | `FUNCTION Is_Elem_In_Set(set, elemId) RESULT(is_in)` |
| FUNCTION | `Is_Node_In_Set` | 3240 | `FUNCTION Is_Node_In_Set(set, id) RESULT(is_in)` |
| FUNCTION | `IsAlgo` | 3255 | `FUNCTION IsAlgo(self) RESULT(res)` |
| FUNCTION | `IsCtx` | 3262 | `FUNCTION IsCtx(self) RESULT(res)` |
| FUNCTION | `IsDesc` | 3269 | `FUNCTION IsDesc(self) RESULT(res)` |
| FUNCTION | `IsState` | 3276 | `FUNCTION IsState(self) RESULT(res)` |
| SUBROUTINE | `lm_Free` | 3283 | `SUBROUTINE lm_Free(this)` |
| SUBROUTINE | `lm_Init` | 3291 | `SUBROUTINE lm_Init(this, n_lbl)` |
| FUNCTION | `lm_Slot` | 3302 | `FUNCTION lm_Slot(this, lbl) RESULT(slot)` |
| SUBROUTINE | `ModelSys_BuildDof` | 3316 | `SUBROUTINE ModelSys_BuildDof(this)` |
| SUBROUTINE | `ModelSys_SetupUIF` | 3325 | `SUBROUTINE ModelSys_SetupUIF(this)` |
| SUBROUTINE | `move_alloc_f90` | 3333 | `SUBROUTINE move_alloc_f90(src, dst)` |
| SUBROUTINE | `move_alloc_f90_uf` | 3340 | `SUBROUTINE move_alloc_f90_uf(src, dst)` |
| SUBROUTINE | `ms_init` | 3347 | `SUBROUTINE ms_init(this)` |
| SUBROUTINE | `NodeSet_FromIds` | 3353 | `SUBROUTINE NodeSet_FromIds(name, ids, set)` |
| SUBROUTINE | `NodeSet_Intersect` | 3366 | `SUBROUTINE NodeSet_Intersect(a, b, out)` |
| SUBROUTINE | `NodeSet_Subtract` | 3391 | `SUBROUTINE NodeSet_Subtract(a, b, out)` |
| SUBROUTINE | `NodeSet_Union` | 3421 | `SUBROUTINE NodeSet_Union(a, b, out)` |
| FUNCTION | `Obj_Bound` | 3447 | `FUNCTION Obj_Bound(self) RESULT(bound)` |
| SUBROUTINE | `Obj_Destroy` | 3454 | `SUBROUTINE Obj_Destroy(self, status)` |
| SUBROUTINE | `Obj_GetInfo` | 3466 | `SUBROUTINE Obj_GetInfo(self, name, id, valid, status)` |
| FUNCTION | `Obj_Id` | 3480 | `FUNCTION Obj_Id(self) RESULT(id)` |
| SUBROUTINE | `Obj_Init` | 3487 | `SUBROUTINE Obj_Init(self, name, id, status)` |
| SUBROUTINE | `Obj_Invalidate` | 3500 | `SUBROUTINE Obj_Invalidate(self)` |
| FUNCTION | `Obj_Name` | 3507 | `FUNCTION Obj_Name(self) RESULT(name)` |
| SUBROUTINE | `Obj_SetId` | 3514 | `SUBROUTINE Obj_SetId(self, id)` |
| SUBROUTINE | `Obj_SetName` | 3521 | `SUBROUTINE Obj_SetName(self, name)` |
| FUNCTION | `Obj_Valid` | 3528 | `FUNCTION Obj_Valid(self) RESULT(valid)` |
| SUBROUTINE | `Serial_BeginArray` | 3535 | `SUBROUTINE Serial_BeginArray(this, name, status)` |
| SUBROUTINE | `Serial_BeginObject` | 3571 | `SUBROUTINE Serial_BeginObject(this, name, status)` |
| SUBROUTINE | `Serial_Close` | 3606 | `SUBROUTINE Serial_Close(this, status)` |
| SUBROUTINE | `Serial_Destroy` | 3628 | `SUBROUTINE Serial_Destroy(this, status)` |
| SUBROUTINE | `Serial_EndArray` | 3641 | `SUBROUTINE Serial_EndArray(this, status)` |
| SUBROUTINE | `Serial_EndObject` | 3666 | `SUBROUTINE Serial_EndObject(this, status)` |
| SUBROUTINE | `Serial_Init` | 3693 | `SUBROUTINE Serial_Init(this, format, status)` |
| SUBROUTINE | `Serial_Open` | 3706 | `SUBROUTINE Serial_Open(this, file_path, status)` |
| SUBROUTINE | `Serial_WriteArrayInt` | 3745 | `SUBROUTINE Serial_WriteArrayInt(this, array, status)` |
| SUBROUTINE | `Serial_WriteArrayReal` | 3795 | `SUBROUTINE Serial_WriteArrayReal(this, array, status)` |
| SUBROUTINE | `Serial_WriteBool` | 3845 | `SUBROUTINE Serial_WriteBool(this, value, status)` |
| SUBROUTINE | `Serial_WriteComma` | 3880 | `SUBROUTINE Serial_WriteComma(this, status)` |
| SUBROUTINE | `Serial_WriteIndent` | 3898 | `SUBROUTINE Serial_WriteIndent(this, status)` |
| SUBROUTINE | `Serial_WriteInt` | 3916 | `SUBROUTINE Serial_WriteInt(this, value, status)` |
| SUBROUTINE | `Serial_WriteReal` | 3949 | `SUBROUTINE Serial_WriteReal(this, value, status)` |
| SUBROUTINE | `Serial_WriteString` | 3982 | `SUBROUTINE Serial_WriteString(this, value, status)` |
| SUBROUTINE | `SetTypeName` | 4019 | `SUBROUTINE SetTypeName(self, name)` |
| SUBROUTINE | `SetVarName` | 4026 | `SUBROUTINE SetVarName(self, name)` |
| SUBROUTINE | `SortInt` | 4033 | `SUBROUTINE SortInt(a, n)` |
| SUBROUTINE | `StateBase_Clear` | 4049 | `SUBROUTINE StateBase_Clear(this)` |
| SUBROUTINE | `StateBase_Deserialize` | 4055 | `SUBROUTINE StateBase_Deserialize(this, deserializer, status)` |
| SUBROUTINE | `StateBase_Destroy` | 4080 | `SUBROUTINE StateBase_Destroy(this)` |
| FUNCTION | `StateBase_GetCategory` | 4088 | `FUNCTION StateBase_GetCategory(this) RESULT(cat)` |
| FUNCTION | `StateBase_GetStatus` | 4095 | `FUNCTION StateBase_GetStatus(this) RESULT(status)` |
| FUNCTION | `StateBase_GetTypeName` | 4106 | `FUNCTION StateBase_GetTypeName(this) RESULT(name)` |
| FUNCTION | `StateBase_GetVarName` | 4113 | `FUNCTION StateBase_GetVarName(this) RESULT(name)` |
| SUBROUTINE | `StateBase_Init` | 4120 | `SUBROUTINE StateBase_Init(this, n)` |
| FUNCTION | `StateBase_IsState` | 4127 | `FUNCTION StateBase_IsState(this) RESULT(res)` |
| SUBROUTINE | `StateBase_Serialize` | 4134 | `SUBROUTINE StateBase_Serialize(this, serializer, status)` |
| SUBROUTINE | `StateBase_SetTypeName` | 4173 | `SUBROUTINE StateBase_SetTypeName(this, name)` |
| SUBROUTINE | `StateBase_SetVarName` | 4180 | `SUBROUTINE StateBase_SetVarName(this, name)` |
| FUNCTION | `TrimAll` | 4187 | `FUNCTION TrimAll(str) RESULT(out)` |
| FUNCTION | `TypeName` | 4194 | `FUNCTION TypeName(self) RESULT(name)` |
| SUBROUTINE | `uf_reset` | 4201 | `SUBROUTINE uf_reset(this)` |
| SUBROUTINE | `uf_add_field` | 4209 | `SUBROUTINE uf_add_field(this, fieldType, name, nDof)` |
| SUBROUTINE | `uf_AddField` | 4248 | `SUBROUTINE uf_AddField(this, fieldType, name, nDof)` |
| SUBROUTINE | `uf_AttachDm` | 4286 | `SUBROUTINE uf_AttachDm(this, dm_ptr)` |
| SUBROUTINE | `uf_field_span` | 4296 | `SUBROUTINE uf_field_span(this, eqStart, eqEnd)` |
| SUBROUTINE | `uf_get_eq_span` | 4304 | `SUBROUTINE uf_get_eq_span(this, idx, eqStart, eqEnd)` |
| SUBROUTINE | `uf_get_field` | 4318 | `SUBROUTINE uf_get_field(this, idx, fld)` |
| SUBROUTINE | `uf_GetEqSpan` | 4335 | `SUBROUTINE uf_GetEqSpan(this, idx, eqStart, eqEnd)` |
| SUBROUTINE | `uf_GetField` | 4349 | `SUBROUTINE uf_GetField(this, idx, fld)` |
| SUBROUTINE | `uf_ResetView` | 4366 | `SUBROUTINE uf_ResetView(this)` |
| SUBROUTINE | `UniqueInt` | 4375 | `SUBROUTINE UniqueInt(a, n, out, nOut)` |
| FUNCTION | `VarName` | 4410 | `FUNCTION VarName(self) RESULT(name)` |
| SUBROUTINE | `CoreBase_RegLayout` | 4419 | `SUBROUTINE CoreBase_RegLayout(this)` |
| SUBROUTINE | `CoreBase_Ensure` | 4425 | `SUBROUTINE CoreBase_Ensure(this)` |
| SUBROUTINE | `DescBase_RegLayout` | 4431 | `SUBROUTINE DescBase_RegLayout(this)` |
| SUBROUTINE | `DescBase_Ensure` | 4437 | `SUBROUTINE DescBase_Ensure(this)` |
| SUBROUTINE | `StateBase_RegLayout` | 4443 | `SUBROUTINE StateBase_RegLayout(this)` |
| SUBROUTINE | `StateBase_Ensure` | 4449 | `SUBROUTINE StateBase_Ensure(this)` |
| SUBROUTINE | `AlgoBase_RegLayout` | 4455 | `SUBROUTINE AlgoBase_RegLayout(this)` |
| SUBROUTINE | `AlgoBase_Ensure` | 4461 | `SUBROUTINE AlgoBase_Ensure(this)` |
| SUBROUTINE | `CtxBase_RegLayout` | 4467 | `SUBROUTINE CtxBase_RegLayout(this)` |
| SUBROUTINE | `CtxBase_Ensure` | 4473 | `SUBROUTINE CtxBase_Ensure(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
