!===============================================================================
! MODULE:  MD_Base_ObjModel
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Impl (object model foundation)
! BRIEF:   Core object types and base classes for unified four-category TYPE
!          system. Abstract bases (BaseDesc/Algo/Ctx/State), object containers,
!          shared types, field system, model/node/element/set types.
!===============================================================================
!   Core object types and base classes for unified four-category TYPE system.
!   Merged from MD_Base_Core (core type definitions), MD_Base_Obj_Container_Core
!   (object container types), MD_Base_Shared_Core (shared types like MatCtx, MatRes).
!   Defines fundamental object-oriented constructs: abstract base classes (BaseDesc,
!   BaseAlgo, BaseCtx, BaseState), extended base classes (DescBase, AlgoBase, CtxBase,
!   StateBase), serialization interfaces (TreeSerializer, TreeDeserializer), manager
!   and registry patterns (BaseManager, BaseRegistry), object container (ObjContainer),
!   shared types (MatCtx, MatRes, MatProps, IPState, ElemMatIntf), field system types
!   (UF_FldDesc, UF_FldHdl, UF_FldSys, UF_UFField), model system types (UF_Model,
!   UF_Description, UF_Part, UF_Instance, UF_Assem), node/element/set types (UF_Node,
!   UF_Element, UF_NodeSet, UF_ElemSet, UF_SurfSet), DOF system types (DofMap,
!   DofLabMap, DofSys), utility functions (ToUpper, ToLower, SortInt, UniqueInt,
!   NodeSet/ElemSet operations).
!
! Theory chain:
!   Four-category TYPE system: Desc (Description/Configuration) - immutable model
!   description, input config (E, nu, rho; element type; geometry X(ndim,nnode)).
!   Algo - algorithm parameters
!   and strategy selection (solver type, convergence tolerance ?, max iterations n_max
!   Desc. Ctx - global env, runtime context (step, time t, iter count, conv status).
!   State - mutable runtime data (u(ndof), sigma(nstress), epsilon(nstrain)).
!   Inheritance: BaseDesc -> DescBase (abstract base for
!   all Desc types), BaseAlgo ??AlgoBase (abstract base for all Algo types), BaseCtx ??
!   CtxBase (abstract base for all Ctx types), BaseState ??StateBase (abstract base for
!   all State types). Object-oriented programming: Abstract base classes with deferred
!   procedures, polymorphism via CLASS(*) and TYPE extension, encapsulation via PRIVATE
!   components. Serialization: TreeSerializer/TreeDeserializer for JSON/binary/XML/HDF5
!   formats, Serializable interface for object serialization. Manager pattern: BaseManager
!   for object lifecycle management (Create, Delete, Find, Get, List, ValidateConsistency).
!   Registry pattern: BaseRegistry for type registration and lookup. Container pattern:
!   ObjContainer for hash-based object storage and retrieval. Field system: Field descriptors,
!   field handles, field system for managing field variables at nodes/elements/IPs/global.
!   DOF system: DOF mapping, labeling, system for managing degrees of freedom. Ref: Design
!   Patterns (Gamma et al. 1994), Modern Fortran Explained (Metcalf et al. 2018), OOP
!   principles, serialization theory.
!
! Logic chain:
!   Base types: BaseDesc (abstract) -> DescBase (extended) -> Concrete Desc types.
!   BaseAlgo (abstract) -> AlgoBase (extended) -> Concrete Algo types. BaseCtx (abstract)
!   -> CtxBase (extended) -> Concrete Ctx types. BaseState (abstract) -> StateBase
!   (extended) -> Concrete State types. Object lifecycle: Init -> Use -> Destroy/Clear.
!   Serialization: TreeSerializer.Init -> Open -> WriteInt/WriteReal/WriteString/WriteBool/
!   WriteArrayInt/WriteArrayReal -> BeginObject/EndObject -> BeginArray/EndArray -> Close ->
!   Destroy. TreeDeserializer.Init -> Open -> ReadInt/ReadReal/ReadString/ReadBool/
!   ReadArrayInt/ReadArrayReal -> BeginObject/EndObject -> BeginArray/EndArray -> Close ->
!   Destroy. Manager operations: BaseManager.Init -> Create -> Find/Get -> List ->
!   ValidateConsistency -> Delete -> Finalize. Registry operations: BaseRegistry.Init ->
!   Reg -> Lookup/Exists -> ListRegistered -> Unregister -> Cleanup. Container operations:
!   ObjContainer.Add -> Find/GetByID/GetByName/GetByIndex -> GetAllIDs -> Delete ->
!   Clear/Clean. Field operations: UF_FldSys.RegisterField -> CreateField -> GetField ->
!   UpdateField -> DestroyField. DOF operations: DofSys.BuildDOF -> MapDOF -> GetDOFIndex.
!   Set operations: NodeSet_FromIds -> NodeSet_Union/Intersect/Subtract -> Is_Node_In_Set.
!   ElemSet_FromIds -> ElemSet_Union/Intersect/Subtract -> Is_Elem_In_Set. Dependency:
!   L3_MD Base -> L1 IF (DataPlatform, Error API, Memory Manager, Precision), L3_MD Amp,
!   L3_MD Base (Enums, IOSerial).
!
! Computation chain:
!   BaseDesc operations: Init -> Set name -> Validate -> GetStatus -> Serialize/Deserialize
!   -> Destroy. BaseAlgo operations: Init -> Set typeName/varName -> Cfg -> GetCategory/
!   GetStatus/GetTypeName/GetVarName -> IsAlgo -> Serialize/Deserialize -> Destroy.
!   BaseCtx operations: Init -> SetStatus -> IsOK/IsError -> ClearStatus -> Serialize/
!   Deserialize -> Destroy. BaseState operations: Init -> Clear -> GetStatus -> Serialize/
!   Deserialize -> Destroy. TreeSerializer: Init -> Set format -> Open file -> WriteIndent
!   -> WriteComma -> WriteInt/WriteReal/WriteString/WriteBool -> BeginObject/EndObject ->
!   BeginArray/EndArray -> Close -> Destroy. TreeDeserializer: Init -> Set format -> Open
!   file -> ReadInt/ReadReal/ReadString/ReadBool -> BeginObject/EndObject -> BeginArray/
!   EndArray -> Close -> Destroy. ObjContainer: HashString (hash function) -> Add (hash
!   and store) -> Find (hash and lookup) -> GetByID/GetByName/GetByIndex (direct access)
!   -> GetAllIDs (iterate) -> Delete (remove) -> Clear/Clean (reset). NodeSet/ElemSet:
!   FromIds (create from IDs) -> Union (merge sets) -> Intersect (common elements) ->
!   Subtract (remove elements) -> Is_Node_In_Set/Is_Elem_In_Set (membership test). Field
!   system: RegisterField (register descriptor) -> CreateField (allocate storage) ->
!   GetField (retrieve handle) -> UpdateField (modify data) -> DestroyField (deallocate).
!   DOF system: BuildDOF (create mapping) -> MapDOF (map DOF indices) -> GetDOFIndex
!   (retrieve index).
!
! Data chain:
!   Input: Object names, IDs, configuration data (Desc), algorithm parameters (Algo),
!   context data (Ctx), state data (State), serialization format (B/J/X/H), file paths,
!   field names, DOF labels, node/element IDs, set IDs. Output: Initialized objects,
!   serialized data (JSON/binary/XML/HDF5), object handles, field handles, DOF indices,
!   set membership results, error status. State: BaseDesc state (name, init), BaseAlgo
!   state (typeName, varName, category, init), BaseCtx state (status, init), BaseState
!   state (init), TreeSerializer state (format, indent_level, first_in_object, first_in_array,
!   file_open), TreeDeserializer state (format, file_open), ObjContainer state (hash table,
!   object array, count), field system state (field descriptors, field handles, registered
!   fields), DOF system state (DOF mapping, DOF labels, DOF count), set state (node IDs,
!   element IDs, surface IDs).
!
! Data structure:
!   Container path: Base (core object model).
!   - Desc: BaseDesc (base descriptor), DescBase (extended descriptor), UF_ModelDesc
!   (model descriptor), UF_FldDesc (field descriptor), VarDesc (variable descriptor),
!   UF_Description (description container).
!   - Algo: BaseAlgo (base algorithm), AlgoBase (extended algorithm), ComputationFlags
!   (computation flags).
!   - Ctx: BaseCtx (base context), CtxBase (extended context), MatCtx (material context),
!   MatCtxLegacy (legacy material context), MatStepCtx (material step context), ElemStepCtx
!   (element step context), VarCtx (variable context), UF_UFCore (core context), ModelSys
!   (model system context).
!   - State: BaseState (base state), StateBase (extended state), IPState (integration point
!   state), MatRes (material result), MatResExt (extended material result), EvalResult
!   (evaluation result).
!   Supporting types: BaseSystem (system base), BaseManager (manager base), BaseRegistry
!   (registry base), BaseAPI (API base), BaseSta (status base), ObjBase (object base),
!   CoreBase (core base), Serializable (serialization interface), TreeSerializer (tree
!   serializer), TreeDeserializer (tree deserializer), ObjContainer (object container),
!   HashString (hash function), MatFlags (material flags), MatProps (material properties),
!   Props (properties), ElemMatIntf (element-material interface), UF_NodeHdl (node handle),
!   UF_ElemHdl (element handle), UF_SetHdl (set handle), UF_SurfHdl (surface handle),
!   DofMap (DOF mapping), DofLabMap (DOF label mapping), DofSys (DOF system), UF_FldHdl
!   (field handle), UF_FldRegEnt (field registry entry), UF_FldSys (field system),
!   UF_UFField (unified field), UFView (view), UF_Node (node), UF_Element (element),
!   UF_NodeSet (node set), UF_ElemSet (element set), UF_SurfSet (surface set), UF_Part
!   (part), UF_Instance (instance), UF_Assem (assembly), UF_Model (model), RT_Node
!   (runtime node), RT_Element (runtime element), RT_Model (runtime model), NodeSet
!   (node set), ElemSet (element set), SurfSet (surface set).
!
! Three-step mapping:
!   Base types: Step level (foundation for all object types).
!   Serialization: Step level (data persistence).
!   Manager/Registry: Step level (object lifecycle management).
!   Container: Step level (object storage and retrieval).
!   Field system: Step level (field variable management).
!   DOF system: Step level (degree of freedom management).
!   Set operations: Step level (node/element/surface set operations).
!
! Contents (A-Z):
!   Constants: MD_MODEL_SERIAL_FORMAT_B, MD_MODEL_SERIAL_FORMAT_H, MD_MODEL_SERIAL_FORMAT_J, MD_MODEL_SERIAL_FORMAT_X,
!     MD_MODEL_STATUS_ERROR, MD_MODEL_STATUS_EXISTS, MD_MODEL_STATUS_INVALID, MD_MODEL_STATUS_IO_ERROR, MD_MODEL_STATUS_MEM_ERRO,
!     MD_MODEL_STATUS_NOT_FOUND, MD_MODEL_STATUS_NOT_FOUND, MD_MODEL_STATUS_OK, MD_MODEL_UF_FLD_AT_ELEME, MD_MODEL_UF_FLD_AT_GLOBA,
!     MD_MODEL_UF_FLD_AT_IP, MD_MODEL_UF_FLD_AT_NODE, MD_MODEL_UF_FLD_INT32, MD_MODEL_UF_FLD_LOGIC, MD_MODEL_UF_FLD_REAL8
!   Functions: AlgoBase_GetCategory, AlgoBase_GetStatus, AlgoBase_GetTypeName,
!     AlgoBase_GetVarName, AlgoBase_IsAlgo, BaseCtx_IsError, BaseCtx_IsOK, BaseSta_GetStatus,
!     BaseSta_IsError, BaseSta_IsOK, Container_Find, Container_GetByID, Container_GetByIndex,
!     Container_GetByName, DescBase_GetCategory, DescBase_GetStatus, DescBase_GetTypeName,
!     DescBase_GetVarName, DescBase_IsDesc, HashString, Is_Elem_In_Set, Is_Node_In_Set,
!     StateBase_GetCategory, StateBase_GetStatus, StateBase_GetTypeName, StateBase_GetVarName,
!     StateBase_IsState, String_Equals_CI, ToLower, ToUpper, TrimAll, UniqueInt
!   Subroutines: AlgoBase_Cfg, AlgoBase_Deserialize, AlgoBase_Destroy, AlgoBase_Init,
!     AlgoBase_Serialize, AlgoBase_SetTypeName, AlgoBase_SetVarName, Base_ClearBinding,
!     Base_Init, BaseCtx_ClearStatus, BaseCtx_SetStatus, BaseSta_ClearStatus, BaseSta_SetStatus,
!     Container_Add, Container_Clean, Container_Clear, Container_ExpandHashEntries,
!     Container_GetAllIDs, Container_Remove, DescBase_Deserialize, DescBase_Destroy,
!     DescBase_Init, DescBase_Serialize, DescBase_SetTypeName, DescBase_SetVarName,
!     Deserial_BeginArray, Deserial_BeginObject, Deserial_Close, Deserial_Destroy,
!     Deserial_EndArray, Deserial_EndObject, Deserial_Init, Deserial_Open,
!     Deserial_ReadArrayInt, Deserial_ReadArrayReal, Deserial_ReadBool, Deserial_ReadInt,
!     Deserial_ReadReal, Deserial_ReadString, ElemSet_FromIds, ElemSet_Intersect,
!     ElemSet_Subtract, ElemSet_Union, Init_EnergyBuckets, NodeSet_FromIds, NodeSet_Intersect,
!     NodeSet_Subtract, NodeSet_Union, Serial_BeginArray, Serial_BeginObject, Serial_Close,
!     Serial_Destroy, Serial_Init, Serial_Open, Serial_WriteArrayInt, Serial_WriteArrayReal,
!     Serial_WriteBool, Serial_WriteInt, Serial_WriteReal, Serial_WriteString, SortInt,
!     StateBase_Clear, StateBase_Deserialize, StateBase_Destroy, StateBase_Init,
!     StateBase_Serialize, StateBase_SetTypeName, StateBase_SetVarName
!   Types: AlgoBase, BaseAlgo, BaseAPI, BaseCtx, BaseDesc, BaseManager, BaseRegistry,
!     BaseSta, BaseState, BaseSystem, ComputationFlags, CoreBase, CtxBase, DescBase,
!     DofLabMap, DofMap, DofSys, ElemMatIntf, ElemSet, ElemStepCtx, ErrorStatusType,
!     EvalResult, HashString, init_error_status, IPState, MatCtx, MatCtxLegacy, MatFlags,
!     MatProps, MatRes, MatResExt, MatStepCtx, ModelSys, NodeSet, ObjBase, ObjContainer,
!     Props, RT_Element, RT_Model, RT_Node, Serializable, StateBase, SurfSet, TreeDeserializer,
!     TreeSerializer, UF_Assem, UF_Description, UF_ElemHdl, UF_ElemSet, UF_Element,
!     UF_FldDesc, UF_FldHdl, UF_FldSys, UF_Instance, UF_Model, UF_ModelDesc, UF_Node,
!     UF_NodeHdl, UF_NodeSet, UF_Part, UF_SurfHdl, UF_SurfSet, UF_UFCore, UF_UFField,
!     UFView, VarCtx, VarDesc
!
! Notes:
!   Merged module: MD_Base_Core + MD_Base_Obj_Container_Core + MD_Base_Shared_Core.
!   Four-category TYPE system: Desc (immutable configuration), Algo (algorithm parameters),
!   Ctx (runtime context), State (mutable runtime data). Abstract base classes with deferred
!   procedures enable polymorphism. Extended base classes (DescBase, AlgoBase, CtxBase,
!   StateBase) provide common functionality. Serialization supports multiple formats (binary,
!   JSON, XML, HDF5). Manager pattern for object lifecycle management. Registry pattern
!   for type registration. Container pattern for hash-based object storage. Field system
!   for managing field variables at different locations (nodes, elements, IPs, global).
!   DOF system for managing degrees of freedom. Set operations for node/element/surface sets.
!   Utility functions for string manipulation, sorting, uniqueness, set operations. Logic/
!   Computation chain diagrams: see MD_Base_ObjModel_Core_Chains.md
!
! Status: PROD | Last verified: 2026-03-02
! Theory: N/A
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Model | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Model/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Model | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Base_ObjModel
    USE IF_Base_DP, ONLY: dp_init, dp_register_struct_array, dp_create_dp_array1d, &
        StructFieldDesc, dp_register_struct_type, dp_create_struct_array
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, error_set, error_has_error
    USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, IF_MEM_DOMAIN_MAT
    USE IF_Prec_Core, ONLY: i4, i8, wp
    USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc
    USE MD_Base_Enums
    USE MD_Step_Proc, ONLY: AnalysisStep => UF_AnalysisStep
    USE MD_Base_IOSerialMgr, ONLY: RW_Serialize, RW_Deserialize, RW_Deserialize_DP, RW_Deserialize_Int4, &
        RW_Deserialize_String, RW_Serializer, RW_Deserializer, FileHandle, MD_MODEL_FILE_MODE_WRITE, MD_MODEL_FILE_MODE_READ

    IMPLICIT NONE

    PRIVATE

    ! Model data types
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_DATA_TYPE_INT = 1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_DATA_TYPE_DP = 2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_DATA_TYPE_CHAR = 3_i4

    ! Model status codes (re-export from MD_BaseIOSerialMgr)
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_OK = 0_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_INVALID = -1_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_MEM_ERROR = -2_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_IO_ERROR = -3_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_NOT_FOUND = -4_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_EXISTS = -5_i4
    INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_STATUS_ERROR = -99_i4

    ! PUBLIC constants (A-Z) - MD_MODEL_CAT_* re-exported from MD_BaseEnums
    PUBLIC :: MD_MODEL_CAT_ALGO, MD_MODEL_CAT_CTX, MD_MODEL_CAT_DESC, MD_MODEL_CAT_STATE
    PUBLIC :: MD_MODEL_SERIAL_FORMAT_B, MD_MODEL_SERIAL_FORMAT_H, MD_MODEL_SERIAL_FORMAT_J, MD_MODEL_SERIAL_FORMAT_X
    PUBLIC :: MD_MODEL_UF_FLD_AT_ELEME, MD_MODEL_UF_FLD_AT_GLOBA, MD_MODEL_UF_FLD_AT_IP, MD_MODEL_UF_FLD_AT_NODE
    PUBLIC :: MD_MODEL_UF_FLD_INT32, MD_MODEL_UF_FLD_LOGIC, MD_MODEL_UF_FLD_REAL8

    ! PUBLIC types (A-Z)
    PUBLIC :: AlgoBase, BaseAlgo, BaseAPI, BaseCtx, BaseDesc, BaseManager
    PUBLIC :: BaseRegistry, BaseSta, BaseState, BaseSystem
    PUBLIC :: CoreBase, CtxBase, DescBase, DofLabMap, DofMap, DofSys
    PUBLIC :: ElemMatIntf, ElemSet, ElemStepCtx, ErrorStatusType
    PUBLIC :: HashString, init_error_status, IPState, ModelSys
    PUBLIC :: NodeSet, ObjBase, ObjContainer, RT_Element, RT_Model
    PUBLIC :: RT_Node, Serializable, StateBase, SurfSet, TreeDeserializer
    PUBLIC :: UF_CoreObjectBase
    PUBLIC :: UF_DOF_U1, UF_DOF_U2, UF_DOF_U3, UF_DOF_UR1, UF_DOF_UR2, UF_DOF_UR3
    PUBLIC :: UF_DOF_TEMP, UF_DOF_POR, UF_DOF_EPOT, UF_DOF_CHEM, UF_DOF_MPOT
    PUBLIC :: TreeSerializer, UF_Assem, UF_Description, UF_ElemHdl, UF_ElemSet
    PUBLIC :: UF_Element, UF_FldDesc, UF_FldHdl, UF_FldSys, UF_Instance
    PUBLIC :: UF_ModelMeshHandle
    PUBLIC :: AnalysisStep, UF_Model, UF_ModelDesc, UF_Node, UF_NodeHdl, UF_NodeSet
    PUBLIC :: UF_Part, UF_SurfHdl, UF_SurfSet, UF_UFCore, UF_UFField
    PUBLIC :: UFView, VarCtx, VarDesc

    !===========================================================================
    ! Field System (merged from MD_Base_Field_Mgr)
    !===========================================================================
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_FLD_AT_NODE   = 1
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_FLD_AT_ELEME  = 2
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_FLD_AT_IP     = 3
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_FLD_AT_GLOBA  = 4
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_FLD_REAL8 = 1
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_FLD_INT32 = 2
    INTEGER(i4), PARAMETER :: MD_MODEL_UF_FLD_LOGIC = 3

    !===========================================================================
    ! Tree Serialization (merged from MD_Base_Tree_Serial)
    !===========================================================================
    INTEGER(i4), PARAMETER :: MD_MODEL_SERIAL_FORMAT_B = 1_i4
    INTEGER(i4), PARAMETER :: MD_MODEL_SERIAL_FORMAT_J = 2_i4
    INTEGER(i4), PARAMETER :: MD_MODEL_SERIAL_FORMAT_X = 3_i4
    INTEGER(i4), PARAMETER :: MD_MODEL_SERIAL_FORMAT_H = 4_i4

    ! DOF identifiers (UF_* aliases for MD_MODEL_DOF_* from MD_BaseEnums)
    INTEGER(i4), PARAMETER :: UF_DOF_U1   = MD_MODEL_DOF_U1
    INTEGER(i4), PARAMETER :: UF_DOF_U2   = MD_MODEL_DOF_U2
    INTEGER(i4), PARAMETER :: UF_DOF_U3   = MD_MODEL_DOF_U3
    INTEGER(i4), PARAMETER :: UF_DOF_UR1  = MD_MODEL_DOF_UR1
    INTEGER(i4), PARAMETER :: UF_DOF_UR2  = MD_MODEL_DOF_UR2
    INTEGER(i4), PARAMETER :: UF_DOF_UR3  = MD_MODEL_DOF_UR3
    INTEGER(i4), PARAMETER :: UF_DOF_TEMP = MD_MODEL_DOF_TEMP
    INTEGER(i4), PARAMETER :: UF_DOF_POR  = MD_MODEL_DOF_POR
    INTEGER(i4), PARAMETER :: UF_DOF_EPOT = MD_MODEL_DOF_EPOT
    INTEGER(i4), PARAMETER :: UF_DOF_CHEM = MD_MODEL_DOF_CHEM
    INTEGER(i4), PARAMETER :: UF_DOF_MPOT = MD_MODEL_DOF_MPOT


    ! Forward-declare abstract types BEFORE the ABSTRACT INTERFACE block
    ! (gfortran requires IMPORT types to be defined before the INTERFACE)
    TYPE, ABSTRACT, PUBLIC :: Serializable
    CONTAINS
        PROCEDURE(Serialize_IF), DEFERRED :: Serialize
        PROCEDURE(Deserialize_IF), DEFERRED :: Deserialize
    END TYPE Serializable

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

    ! Abstract interfaces for Serializable (defined after concrete types for gfortran compatibility)
    ABSTRACT INTERFACE
        SUBROUTINE Serialize_IF(this, serializer)
            IMPORT :: Serializable, TreeSerializer
            CLASS(Serializable), INTENT(IN) :: this
            CLASS(TreeSerializer), INTENT(INOUT) :: serializer
        END SUBROUTINE Serialize_IF
        SUBROUTINE Deserialize_IF(this, deserializer)
            IMPORT :: Serializable, TreeDeserializer
            CLASS(Serializable), INTENT(INOUT) :: this
            CLASS(TreeDeserializer), INTENT(INOUT) :: deserializer
        END SUBROUTINE Deserialize_IF
    END INTERFACE

    !===========================================================================
    ! Encapsulation Base Types (from former MD_Base_Encaps_Type)
    !===========================================================================
    TYPE, ABSTRACT, PUBLIC :: BaseSystem
        LOGICAL :: is_init = .FALSE.
    CONTAINS
        PROCEDURE(Init_IF), DEFERRED :: Init
        PROCEDURE(Shutdown_IF), DEFERRED :: Shutdown
    END TYPE BaseSystem

    ABSTRACT INTERFACE
        SUBROUTINE Init_IF(this, status)
            IMPORT :: BaseSystem, ErrorStatusType
            CLASS(BaseSystem), INTENT(INOUT) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Init_IF
        SUBROUTINE Shutdown_IF(this, status)
            IMPORT :: BaseSystem, ErrorStatusType
            CLASS(BaseSystem), INTENT(INOUT) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Shutdown_IF
    END INTERFACE

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

    ABSTRACT INTERFACE
        SUBROUTINE Mgr_Init_IF(this, max_capacity, status)
            IMPORT :: BaseManager, ErrorStatusType, i4
            CLASS(BaseManager), INTENT(INOUT) :: this
            INTEGER(i4), INTENT(IN), OPTIONAL :: max_capacity
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Mgr_Init_IF
        SUBROUTINE Mgr_Final_IF(this, status)
            IMPORT :: BaseManager, ErrorStatusType
            CLASS(BaseManager), INTENT(INOUT) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Mgr_Final_IF
        SUBROUTINE Mgr_Create_IF(this, id, name, status)
            IMPORT :: BaseManager, ErrorStatusType, i4
            CLASS(BaseManager), INTENT(INOUT) :: this
            INTEGER(i4), INTENT(OUT), OPTIONAL :: id
            CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Mgr_Create_IF
        SUBROUTINE Mgr_Delete_IF(this, id, status)
            IMPORT :: BaseManager, ErrorStatusType, i4
            CLASS(BaseManager), INTENT(INOUT) :: this
            INTEGER(i4), INTENT(IN) :: id
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Mgr_Delete_IF
        FUNCTION Mgr_Find_IF(this, name) RESULT(id)
            IMPORT :: BaseManager, i4
            CLASS(BaseManager), INTENT(IN) :: this
            CHARACTER(LEN=*), INTENT(IN) :: name
            INTEGER(i4) :: id
        END FUNCTION Mgr_Find_IF
        SUBROUTINE Mgr_Get_IF(this, id, status)
            IMPORT :: BaseManager, ErrorStatusType, i4
            CLASS(BaseManager), INTENT(IN) :: this
            INTEGER(i4), INTENT(IN) :: id
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Mgr_Get_IF
        FUNCTION Mgr_GetCount_IF(this) RESULT(n)
            IMPORT :: BaseManager, i4
            CLASS(BaseManager), INTENT(IN) :: this
            INTEGER(i4) :: n
        END FUNCTION Mgr_GetCount_IF
        SUBROUTINE Mgr_List_IF(this, status)
            IMPORT :: BaseManager, ErrorStatusType
            CLASS(BaseManager), INTENT(IN) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Mgr_List_IF
        FUNCTION Mgr_Valid_IF(this) RESULT(ok)
            IMPORT :: BaseManager
            CLASS(BaseManager), INTENT(IN) :: this
            LOGICAL :: ok
        END FUNCTION Mgr_Valid_IF
        SUBROUTINE Mgr_ValidateConsistency_IF(this, status)
            IMPORT :: BaseManager, ErrorStatusType
            CLASS(BaseManager), INTENT(IN) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Mgr_ValidateConsistency_IF
        SUBROUTINE Mgr_GetStatistics_IF(this, status)
            IMPORT :: BaseManager, ErrorStatusType
            CLASS(BaseManager), INTENT(IN) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Mgr_GetStatistics_IF
    END INTERFACE

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

    ABSTRACT INTERFACE
        SUBROUTINE Reg_Init_IF(this, max_capacity, status)
            IMPORT :: BaseRegistry, ErrorStatusType, i4
            CLASS(BaseRegistry), INTENT(INOUT) :: this
            INTEGER(i4), INTENT(IN), OPTIONAL :: max_capacity
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Reg_Init_IF
        SUBROUTINE Reg_Cleanup_IF(this, status)
            IMPORT :: BaseRegistry, ErrorStatusType
            CLASS(BaseRegistry), INTENT(INOUT) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Reg_Cleanup_IF
        SUBROUTINE Reg_Reg_IF(this, name, item, status)
            IMPORT :: BaseRegistry, ErrorStatusType
            CLASS(BaseRegistry), INTENT(INOUT) :: this
            CHARACTER(LEN=*), INTENT(IN) :: name
            CLASS(*), INTENT(IN), OPTIONAL :: item
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Reg_Reg_IF
        SUBROUTINE Reg_Unregister_IF(this, name, status)
            IMPORT :: BaseRegistry, ErrorStatusType
            CLASS(BaseRegistry), INTENT(INOUT) :: this
            CHARACTER(LEN=*), INTENT(IN) :: name
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Reg_Unregister_IF
        FUNCTION Reg_Lookup_IF(this, name) RESULT(found)
            IMPORT :: BaseRegistry
            CLASS(BaseRegistry), INTENT(IN) :: this
            CHARACTER(LEN=*), INTENT(IN) :: name
            LOGICAL :: found
        END FUNCTION Reg_Lookup_IF
        FUNCTION Reg_Exists_IF(this, name) RESULT(exists)
            IMPORT :: BaseRegistry
            CLASS(BaseRegistry), INTENT(IN) :: this
            CHARACTER(LEN=*), INTENT(IN) :: name
            LOGICAL :: exists
        END FUNCTION Reg_Exists_IF
        FUNCTION Reg_GetCount_IF(this) RESULT(n)
            IMPORT :: BaseRegistry, i4
            CLASS(BaseRegistry), INTENT(IN) :: this
            INTEGER(i4) :: n
        END FUNCTION Reg_GetCount_IF
        SUBROUTINE Reg_List_IF(this, names, count, status)
            IMPORT :: BaseRegistry, ErrorStatusType, i4
            CLASS(BaseRegistry), INTENT(IN) :: this
            CHARACTER(LEN=*), INTENT(OUT) :: names(:)
            INTEGER(i4), INTENT(OUT) :: count
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Reg_List_IF
    END INTERFACE

    TYPE, ABSTRACT, PUBLIC :: BaseAPI
        LOGICAL :: is_init = .FALSE.
    CONTAINS
        PROCEDURE(API_Init_IF), DEFERRED :: Init
        PROCEDURE(API_Cleanup_IF), DEFERRED :: Cleanup
    END TYPE BaseAPI

    ABSTRACT INTERFACE
        SUBROUTINE API_Init_IF(this, status)
            IMPORT :: BaseAPI, ErrorStatusType
            CLASS(BaseAPI), INTENT(INOUT) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE API_Init_IF
        SUBROUTINE API_Cleanup_IF(this, status)
            IMPORT :: BaseAPI, ErrorStatusType
            CLASS(BaseAPI), INTENT(INOUT) :: this
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE API_Cleanup_IF
    END INTERFACE

    !===========================================================================
    ! ObjModel Base Types (from former MD_Base_ObjModel_Type)
    !===========================================================================
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

    !===========================================================================
    !> @brief Base Description Type (Desc - Description/Configuration)
    !! @details Abstract base class for immutable model description types
    !!   Theory: Desc types contain input configuration and model structure
    !!   Examples: E, nu, rho; element type; geometry X(ndim,nnode)
    !!   All Desc types should extend BaseDesc and implement deferred procedures
    !===========================================================================
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

    ABSTRACT INTERFACE
        !> @brief Initialize Desc object
        SUBROUTINE Desc_Init_Intf(this)
            IMPORT :: BaseDesc
            CLASS(BaseDesc), INTENT(INOUT) :: this
        END SUBROUTINE Desc_Init_Intf
        !> @brief Destroy Desc object
        SUBROUTINE Desc_Destroy_Intf(this)
            IMPORT :: BaseDesc
            CLASS(BaseDesc), INTENT(INOUT) :: this
        END SUBROUTINE Desc_Destroy_Intf
        !> @brief Validate Desc object
        !! @returns is_valid True if Desc object is valid
        FUNCTION Desc_Valid_Intf(this) RESULT(is_valid)
            IMPORT :: BaseDesc
            CLASS(BaseDesc), INTENT(IN) :: this
            LOGICAL :: is_valid
        END FUNCTION Desc_Valid_Intf
        !> @brief Get error status
        !! @returns status ErrorStatusType containing error information
        FUNCTION Desc_GetStatus_Intf(this) RESULT(status)
            IMPORT :: BaseDesc, ErrorStatusType
            CLASS(BaseDesc), INTENT(IN) :: this
            TYPE(ErrorStatusType) :: status
        END FUNCTION Desc_GetStatus_Intf
        !> @brief Serialize Desc object to stream
        !! @param[in] this Desc object to serialize
        !! @param[inout] serializer TreeSerializer for output
        !! @param[out] status Error status (optional)
        SUBROUTINE Desc_Serialize_Intf(this, serializer, status)
            IMPORT :: BaseDesc, TreeSerializer, ErrorStatusType
            CLASS(BaseDesc), INTENT(IN) :: this
            CLASS(TreeSerializer), INTENT(INOUT) :: serializer
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Desc_Serialize_Intf
        !> @brief Deserialize Desc object from stream
        !! @param[inout] this Desc object to populate
        !! @param[inout] deserializer TreeDeserializer for input
        !! @param[out] status Error status (optional)
        SUBROUTINE Desc_Deserialize_Intf(this, deserializer, status)
            IMPORT :: BaseDesc, TreeDeserializer, ErrorStatusType
            CLASS(BaseDesc), INTENT(INOUT) :: this
            CLASS(TreeDeserializer), INTENT(INOUT) :: deserializer
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Desc_Deserialize_Intf
    END INTERFACE

    !===========================================================================
    !> @brief Base State Type (State - Runtime State)
    !! @details Abstract base class for mutable runtime state types
    !!   Theory: State types contain runtime data and field variables
    !!   Examples: u(ndof), sigma(nstress), epsilon(nstrain)
    !!   All State types should extend BaseState and implement deferred procedures
    !===========================================================================
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

    ABSTRACT INTERFACE
        !> @brief Initialize State object
        !! @param[inout] this State object to initialize
        !! @param[in] n Optional size n
        SUBROUTINE State_Init_Intf(this, n)
            IMPORT :: BaseState, i4
            CLASS(BaseState), INTENT(INOUT) :: this
            INTEGER(i4), INTENT(IN), OPTIONAL :: n  ! Optional size n
        END SUBROUTINE State_Init_Intf
        !> @brief Destroy State object
        SUBROUTINE State_Destroy_Intf(this)
            IMPORT :: BaseState
            CLASS(BaseState), INTENT(INOUT) :: this
        END SUBROUTINE State_Destroy_Intf
        !> @brief Clear State object (reset to initial state)
        SUBROUTINE State_Clear_Intf(this)
            IMPORT :: BaseState
            CLASS(BaseState), INTENT(INOUT) :: this
        END SUBROUTINE State_Clear_Intf
        !> @brief Get error status
        !! @returns status ErrorStatusType containing error information
        FUNCTION State_GetStatus_Intf(this) RESULT(status)
            IMPORT :: BaseState, ErrorStatusType
            CLASS(BaseState), INTENT(IN) :: this
            TYPE(ErrorStatusType) :: status
        END FUNCTION State_GetStatus_Intf
        !> @brief Serialize State object to stream
        !! @param[in] this State object to serialize
        !! @param[inout] serializer TreeSerializer for output
        !! @param[out] status Error status (optional)
        SUBROUTINE State_Serialize_Intf(this, serializer, status)
            IMPORT :: BaseState, TreeSerializer, ErrorStatusType
            CLASS(BaseState), INTENT(IN) :: this
            CLASS(TreeSerializer), INTENT(INOUT) :: serializer
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE State_Serialize_Intf
        !> @brief Deserialize State object from stream
        !! @param[inout] this State object to populate
        !! @param[inout] deserializer TreeDeserializer for input
        !! @param[out] status Error status (optional)
        SUBROUTINE State_Deserialize_Intf(this, deserializer, status)
            IMPORT :: BaseState, TreeDeserializer, ErrorStatusType
            CLASS(BaseState), INTENT(INOUT) :: this
            CLASS(TreeDeserializer), INTENT(INOUT) :: deserializer
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE State_Deserialize_Intf
    END INTERFACE

    !===========================================================================
    !> @brief Base Algorithm Type (Algo - Algorithm Configuration)
    !! @details Abstract base class for algorithm configuration types
    !!   Theory: Algo types contain algorithm parameters and strategy selection
    !!   Examples: Solver type, tol, max iterations n_max
    !!   All Algo types should extend BaseAlgo and implement deferred procedures
    !===========================================================================
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

    ABSTRACT INTERFACE
        !> @brief Initialize Algo object
        SUBROUTINE Algo_Init_Intf(this)
            IMPORT :: BaseAlgo
            CLASS(BaseAlgo), INTENT(INOUT) :: this
        END SUBROUTINE Algo_Init_Intf
        !> @brief Destroy Algo object
        SUBROUTINE Algo_Destroy_Intf(this)
            IMPORT :: BaseAlgo
            CLASS(BaseAlgo), INTENT(INOUT) :: this
        END SUBROUTINE Algo_Destroy_Intf
        !> @brief Configure Algo object with Desc configuration
        !! @param[inout] this Algo object to configure
        !! @param[in] config BaseDesc configuration object
        SUBROUTINE Algo_Cfg_Intf(this, config)
            IMPORT :: BaseAlgo, BaseDesc
            CLASS(BaseAlgo), INTENT(INOUT) :: this
            CLASS(BaseDesc), INTENT(IN) :: config  ! Desc configuration
        END SUBROUTINE Algo_Cfg_Intf
        !> @brief Get error status
        !! @returns status ErrorStatusType containing error information
        FUNCTION Algo_GetStatus_Intf(this) RESULT(status)
            IMPORT :: BaseAlgo, ErrorStatusType
            CLASS(BaseAlgo), INTENT(IN) :: this
            TYPE(ErrorStatusType) :: status
        END FUNCTION Algo_GetStatus_Intf
        !> @brief Serialize Algo object to stream
        !! @param[in] this Algo object to serialize
        !! @param[inout] serializer TreeSerializer for output
        !! @param[out] status Error status (optional)
        SUBROUTINE Algo_Serialize_Intf(this, serializer, status)
            IMPORT :: BaseAlgo, TreeSerializer, ErrorStatusType
            CLASS(BaseAlgo), INTENT(IN) :: this
            CLASS(TreeSerializer), INTENT(INOUT) :: serializer
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Algo_Serialize_Intf
        !> @brief Deserialize Algo object from stream
        !! @param[inout] this Algo object to populate
        !! @param[inout] deserializer TreeDeserializer for input
        !! @param[out] status Error status (optional)
        SUBROUTINE Algo_Deserialize_Intf(this, deserializer, status)
            IMPORT :: BaseAlgo, TreeDeserializer, ErrorStatusType
            CLASS(BaseAlgo), INTENT(INOUT) :: this
            CLASS(TreeDeserializer), INTENT(INOUT) :: deserializer
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Algo_Deserialize_Intf
    END INTERFACE

    !===========================================================================
    !> @brief Base Context Type (Ctx - Context/Control)
    !! @details Abstract base class for global environment and runtime context types
    !!   Theory: Ctx types contain global environment, runtime context, and control state
    !!   Examples: Current step, time t, iter count, conv status
    !!   All Ctx types should extend BaseCtx and implement deferred procedures
    !===========================================================================
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

    ABSTRACT INTERFACE
        !> @brief Initialize Ctx object
        SUBROUTINE Ctx_Init_Intf(this)
            IMPORT :: BaseCtx
            CLASS(BaseCtx), INTENT(INOUT) :: this
        END SUBROUTINE Ctx_Init_Intf
        !> @brief Destroy Ctx object
        SUBROUTINE Ctx_Destroy_Intf(this)
            IMPORT :: BaseCtx
            CLASS(BaseCtx), INTENT(INOUT) :: this
        END SUBROUTINE Ctx_Destroy_Intf
        !> @brief Reset Ctx object (reset to initial state)
        SUBROUTINE Ctx_Reset_Intf(this)
            IMPORT :: BaseCtx
            CLASS(BaseCtx), INTENT(INOUT) :: this
        END SUBROUTINE Ctx_Reset_Intf
        !> @brief Get error status
        !! @returns status ErrorStatusType containing error information
        FUNCTION Ctx_GetStatus_Intf(this) RESULT(status)
            IMPORT :: BaseCtx, ErrorStatusType
            CLASS(BaseCtx), INTENT(IN) :: this
            TYPE(ErrorStatusType) :: status
        END FUNCTION Ctx_GetStatus_Intf
        !> @brief Serialize Ctx object to stream
        !! @param[in] this Ctx object to serialize
        !! @param[inout] serializer TreeSerializer for output
        !! @param[out] status Error status (optional)
        SUBROUTINE Ctx_Serialize_Intf(this, serializer, status)
            IMPORT :: BaseCtx, TreeSerializer, ErrorStatusType
            CLASS(BaseCtx), INTENT(IN) :: this
            CLASS(TreeSerializer), INTENT(INOUT) :: serializer
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Ctx_Serialize_Intf
        !> @brief Deserialize Ctx object from stream
        !! @param[inout] this Ctx object to populate
        !! @param[inout] deserializer TreeDeserializer for input
        !! @param[out] status Error status (optional)
        SUBROUTINE Ctx_Deserialize_Intf(this, deserializer, status)
            IMPORT :: BaseCtx, TreeDeserializer, ErrorStatusType
            CLASS(BaseCtx), INTENT(INOUT) :: this
            CLASS(TreeDeserializer), INTENT(INOUT) :: deserializer
            TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        END SUBROUTINE Ctx_Deserialize_Intf
    END INTERFACE

    !===========================================================================
    ! 1. Abstract Base Class (must be defined first) - Simplified Interface
    !===========================================================================
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

    !===========================================================================
    ! Container helper types and constants
    !===========================================================================
    INTEGER(i4), PARAMETER :: MD_MODEL_HASH_TABLE_SIZE     = 256_i4   ! Hash table buckets
    INTEGER(i4), PARAMETER :: MD_MODEL_OBJ_INITIAL_CAPACIT = 16_i4    ! Initial object capacity
    INTEGER(i4), PARAMETER :: MD_MODEL_GROWTH_FACTOR        = 2_i4    ! Growth factor for resize

    !> Hash table entry (chained)
    TYPE, PUBLIC :: HashEntry
        INTEGER(i4) :: id   = 0_i4  ! Object ID stored at this entry
        INTEGER(i4) :: next = 0_i4  ! Next entry index (0 = end of chain)
    END TYPE HashEntry

    !> Wrapper for array-of-pointers (Fortran has no native array of polymorphic pointers)
    TYPE, PRIVATE :: ObjPtr
        CLASS(ObjBase), POINTER :: p => null()
    END TYPE ObjPtr

    !> General-purpose hash-based object container
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

    !===========================================================================
    ! Integration Point State (IPState)
    !===========================================================================
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

    !===========================================================================
    ! Element-Material Interface (ElemMatIntf)
    !===========================================================================
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

    !===========================================================================
    ! Element Step Context (ElemStepCtx)
    !===========================================================================
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




    !===========================================================================
    ! 2. Abstract Interfaces (one set per abstract base type)
    ! Use CLASS(*) to avoid forward-reference of CoreBase/DescBase/StateBase/AlgoBase/CtxBase
    !===========================================================================
    ABSTRACT INTERFACE
        SUBROUTINE RegLayout_Proc(this)
            CLASS(*), INTENT(IN) :: this
        END SUBROUTINE RegLayout_Proc
        SUBROUTINE Ensure_Proc(this)
            CLASS(*), INTENT(INOUT) :: this
        END SUBROUTINE Ensure_Proc
    END INTERFACE

    !===========================================================================
    ! 3. Core Object Base Class
    !===========================================================================
    TYPE, ABSTRACT, PUBLIC, EXTENDS(ObjBase) :: CoreBase
        INTEGER(i4)       :: algo_category         = 0_i4
        CHARACTER(LEN=64) :: algo_type_name = ""
        CHARACTER(LEN=64) :: algo_var_name      = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Category         => GetCategory
        PROCEDURE, PUBLIC :: TypeName         => TypeName
        PROCEDURE, PUBLIC :: VarName          => VarName
        PROCEDURE, PUBLIC :: SetTypeName      => SetTypeName
        PROCEDURE, PUBLIC :: SetVarName       => SetVarName
        PROCEDURE, PUBLIC :: IsDesc           => IsDesc
        PROCEDURE, PUBLIC :: IsState          => IsState
        PROCEDURE, PUBLIC :: IsAlgo           => IsAlgo
        PROCEDURE, PUBLIC :: IsCtx            => IsCtx
        PROCEDURE, PUBLIC :: Init             => Base_Init
        PROCEDURE, PUBLIC :: Clear            => Base_ClearBinding
        PROCEDURE, PUBLIC :: RegLayout     => CoreBase_RegLayout
        PROCEDURE, PUBLIC :: Ensure        => CoreBase_Ensure
    END TYPE CoreBase

    !> UF_CoreObjectBase: Alias for CoreBase (runtime object base with category/typeName/varName)
    TYPE, PUBLIC, EXTENDS(CoreBase) :: UF_CoreObjectBase
    END TYPE UF_CoreObjectBase

    !===========================================================================
    ! Unified Base Classes - Extend both CoreBase and BaseDesc/BaseState/BaseAlgo/BaseCtx
    ! Note: Fortran doesn't support multiple inheritance, so we use composition
    !===========================================================================
    TYPE, ABSTRACT, PUBLIC, EXTENDS(BaseDesc) :: DescBase
        ! CoreBase functionality (composition)
        INTEGER(i4)       :: algo_category         = MD_MODEL_CAT_DESC
        CHARACTER(LEN=64) :: algo_type_name = ""
        CHARACTER(LEN=64) :: algo_var_name      = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Category         => DescBase_GetCategory
        PROCEDURE, PUBLIC :: TypeName         => DescBase_GetTypeName
        PROCEDURE, PUBLIC :: VarName          => DescBase_GetVarName
        PROCEDURE, PUBLIC :: SetTypeName      => DescBase_SetTypeName
        PROCEDURE, PUBLIC :: SetVarName       => DescBase_SetVarName
        PROCEDURE, PUBLIC :: IsDesc           => DescBase_IsDesc
        PROCEDURE, PUBLIC :: RegLayout     => DescBase_RegLayout
        PROCEDURE, PUBLIC :: Ensure        => DescBase_Ensure
        ! BaseDesc interface implementations (default)
        PROCEDURE, PUBLIC :: Init => DescBase_Init
        PROCEDURE, PUBLIC :: Destroy => DescBase_Destroy
        PROCEDURE, PUBLIC :: Valid => DescBase_Valid
        PROCEDURE, PUBLIC :: GetStatus => DescBase_GetStatus
        PROCEDURE, PUBLIC :: Serialize => DescBase_Serialize
        PROCEDURE, PUBLIC :: Deserialize => DescBase_Deserialize
    END TYPE DescBase

    TYPE, ABSTRACT, PUBLIC, EXTENDS(BaseState) :: StateBase
        ! CoreBase functionality (composition)
        INTEGER(i4)       :: algo_category         = MD_MODEL_CAT_STATE
        CHARACTER(LEN=64) :: algo_type_name = ""
        CHARACTER(LEN=64) :: algo_var_name      = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Category         => StateBase_GetCategory
        PROCEDURE, PUBLIC :: TypeName         => StateBase_GetTypeName
        PROCEDURE, PUBLIC :: VarName          => StateBase_GetVarName
        PROCEDURE, PUBLIC :: SetTypeName      => StateBase_SetTypeName
        PROCEDURE, PUBLIC :: SetVarName       => StateBase_SetVarName
        PROCEDURE, PUBLIC :: IsState          => StateBase_IsState
        PROCEDURE, PUBLIC :: RegLayout     => StateBase_RegLayout
        PROCEDURE, PUBLIC :: Ensure        => StateBase_Ensure
        ! BaseState interface implementations (default)
        PROCEDURE, PUBLIC :: Init => StateBase_Init
        PROCEDURE, PUBLIC :: Destroy => StateBase_Destroy
        PROCEDURE, PUBLIC :: Clear => StateBase_Clear
        PROCEDURE, PUBLIC :: GetStatus => StateBase_GetStatus
        PROCEDURE, PUBLIC :: Serialize => StateBase_Serialize
        PROCEDURE, PUBLIC :: Deserialize => StateBase_Deserialize
    END TYPE StateBase

    TYPE, ABSTRACT, PUBLIC, EXTENDS(BaseAlgo) :: AlgoBase
        ! CoreBase functionality (composition)
        INTEGER(i4)       :: algo_category         = MD_MODEL_CAT_ALGO
        CHARACTER(LEN=64) :: algo_type_name = ""
        CHARACTER(LEN=64) :: algo_var_name      = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Category         => AlgoBase_GetCategory
        PROCEDURE, PUBLIC :: TypeName         => AlgoBase_GetTypeName
        PROCEDURE, PUBLIC :: VarName          => AlgoBase_GetVarName
        PROCEDURE, PUBLIC :: SetTypeName      => AlgoBase_SetTypeName
        PROCEDURE, PUBLIC :: SetVarName       => AlgoBase_SetVarName
        PROCEDURE, PUBLIC :: IsAlgo           => AlgoBase_IsAlgo
        PROCEDURE, PUBLIC :: RegLayout     => AlgoBase_RegLayout
        PROCEDURE, PUBLIC :: Ensure        => AlgoBase_Ensure
        ! BaseAlgo interface implementations (default)
        PROCEDURE, PUBLIC :: Init => AlgoBase_Init
        PROCEDURE, PUBLIC :: Destroy => AlgoBase_Destroy
        PROCEDURE, PUBLIC :: Cfg => AlgoBase_Cfg
        PROCEDURE, PUBLIC :: GetStatus => AlgoBase_GetStatus
        PROCEDURE, PUBLIC :: Serialize => AlgoBase_Serialize
        PROCEDURE, PUBLIC :: Deserialize => AlgoBase_Deserialize
    END TYPE AlgoBase

    TYPE, ABSTRACT, PUBLIC, EXTENDS(BaseCtx) :: CtxBase
        ! CoreBase functionality (composition)
        INTEGER(i4)       :: algo_category         = MD_MODEL_CAT_CTX
        CHARACTER(LEN=64) :: algo_type_name = ""
        CHARACTER(LEN=64) :: algo_var_name      = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Category         => CtxBase_GetCategory
        PROCEDURE, PUBLIC :: TypeName         => CtxBase_GetTypeName
        PROCEDURE, PUBLIC :: VarName          => CtxBase_GetVarName
        PROCEDURE, PUBLIC :: SetTypeName      => CtxBase_SetTypeName
        PROCEDURE, PUBLIC :: SetVarName       => CtxBase_SetVarName
        PROCEDURE, PUBLIC :: IsCtx            => CtxBase_IsCtx
        PROCEDURE, PUBLIC :: RegLayout     => CtxBase_RegLayout
        PROCEDURE, PUBLIC :: Ensure        => CtxBase_Ensure
        ! BaseCtx interface implementations (default)
        PROCEDURE, PUBLIC :: Init => CtxBase_Init
        PROCEDURE, PUBLIC :: Destroy => CtxBase_Destroy
        PROCEDURE, PUBLIC :: Reset => CtxBase_Reset
        PROCEDURE, PUBLIC :: GetStatus => CtxBase_GetStatus
        PROCEDURE, PUBLIC :: Serialize => CtxBase_Serialize
        PROCEDURE, PUBLIC :: Deserialize => CtxBase_Deserialize
    END TYPE CtxBase

    !===========================================================================
    ! 4. Handle Types
    !===========================================================================
    TYPE, PUBLIC :: UF_NodeHdl
        INTEGER(i4) :: id = 0_i4
        INTEGER(i4) :: index  = 0_i4
    END TYPE UF_NodeHdl

    TYPE, PUBLIC :: UF_ElemHdl
        INTEGER(i4) :: id = 0_i4
        INTEGER(i4) :: index  = 0_i4
    END TYPE UF_ElemHdl

    TYPE, PUBLIC :: UF_SetHdl
        CHARACTER(LEN=64) :: name  = ""
        INTEGER(i4)       :: type  = 0_i4
        INTEGER(i4)       :: index = 0_i4
    END TYPE UF_SetHdl

    TYPE, PUBLIC :: UF_SurfHdl
        CHARACTER(LEN=64) :: name  = ""
        INTEGER(i4)       :: index = 0_i4
    END TYPE UF_SurfHdl

    !===========================================================================
    ! 5. Model Variable Descriptors
    !===========================================================================
    TYPE, PUBLIC :: VarDesc
        CHARACTER(LEN=64) :: name = '', varName = ''
        INTEGER(i4)       :: location = 0_i4, dType = 0_i4, rank = 0_i4, dims(4) = 0_i4
        LOGICAL           :: is_history = .false., is_persistent = .false.
    END TYPE VarDesc

    TYPE, PUBLIC :: VarCtx
        CHARACTER(LEN=80) :: mName = ''
        INTEGER(i4)       :: maxVars = 0_i4, nVars = 0_i4
        TYPE(VarDesc), ALLOCATABLE :: vars(:)
    END TYPE VarCtx

    !===========================================================================
    ! 6. DOF Core & System
    !===========================================================================
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

    TYPE, PUBLIC :: DofLabMap
        INTEGER(i4) :: n_lbl = 0
        INTEGER, ALLOCATABLE :: lbl(:)
        INTEGER, ALLOCATABLE :: slot_arr(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Init    => lm_Init
        PROCEDURE, PUBLIC :: Free    => lm_Free
        PROCEDURE, PUBLIC :: Slot    => lm_Slot
    END TYPE DofLabMap

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

    !===========================================================================
    ! 6b. Field System Types (merged from MD_Base_Field_Mgr)
    !===========================================================================
    TYPE, PUBLIC :: UF_FldDesc
        CHARACTER(LEN=:), ALLOCATABLE :: name
        INTEGER(i4) :: loc  = MD_MODEL_UF_FLD_AT_NODE
        INTEGER(i4) :: bas  = MD_MODEL_UF_FLD_REAL8
        INTEGER(i4) :: rank = 0_i4
        INTEGER(i4), ALLOCATABLE :: eshape(:)
    CONTAINS
        PROCEDURE, PUBLIC :: compat => fd_compat
    END TYPE UF_FldDesc

    TYPE, PUBLIC :: UF_FldHdl
        TYPE(UF_FldDesc) :: desc
        CHARACTER(LEN=64) :: name = ""
    CONTAINS
        PROCEDURE, PUBLIC :: assoc => fh_assoc
    END TYPE UF_FldHdl

    TYPE :: UF_FldRegEnt
        TYPE(UF_FldDesc) :: desc
        CHARACTER(LEN=64) :: name
        INTEGER(i4)      :: nEntities = 0_i4
    END TYPE UF_FldRegEnt

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

    TYPE, PUBLIC :: UF_UFField
        TYPE(UF_FldDesc) :: desc
        INTEGER(i4)      :: fieldType = 0_i4
        INTEGER(i4)      :: nDof      = 0_i4
        INTEGER(i4)      :: eqStart   = 0_i4
        INTEGER(i4)      :: eqEnd     = 0_i4
    CONTAINS
        PROCEDURE, PUBLIC :: span => uf_field_span
    END TYPE UF_UFField

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

    !===========================================================================
    ! 7. Field System Extension (View & Model Integration)
    !===========================================================================
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

    !===========================================================================
    ! 8. Model Types (Placeholder declarations)
    !===========================================================================
    TYPE, PUBLIC :: UF_ModelDesc
        INTEGER(i4) :: id = 0
        CHARACTER(LEN=256) :: name = ""
    END TYPE UF_ModelDesc

    TYPE, PUBLIC :: UF_Node
        INTEGER(i4) :: id = 0
        REAL(wp) :: coords(3) = 0.0_wp
        INTEGER(i4), ALLOCATABLE :: dofTypes(:)
        LOGICAL :: isreferencepoin = .false.
        CHARACTER(LEN=64) :: name = ""
    END TYPE UF_Node

    TYPE, PUBLIC :: UF_Element
        INTEGER(i4) :: id = 0_i4
        INTEGER(i4) :: elemTypeId = 0_i4
        INTEGER(i4), ALLOCATABLE :: conn(:)
    END TYPE UF_Element

    TYPE, PUBLIC :: UF_NodeSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: nodeIds(:)
    END TYPE UF_NodeSet

    TYPE, PUBLIC :: UF_ElemSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: elemIds(:)
    END TYPE UF_ElemSet

    TYPE, PUBLIC :: UF_SurfSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: elemIds(:)
        INTEGER(i4), ALLOCATABLE :: faceIds(:)
    END TYPE UF_SurfSet

    TYPE, PUBLIC :: UF_Part
        CHARACTER(LEN=64) :: name = ""
        TYPE(UF_Node), ALLOCATABLE :: nodes(:)
        TYPE(UF_Element), ALLOCATABLE :: elements(:)
        TYPE(UF_NodeSet), ALLOCATABLE :: nodeSets(:)
        TYPE(UF_ElemSet), ALLOCATABLE :: elemSets(:)
        TYPE(UF_SurfSet), ALLOCATABLE :: surfSets(:)
    END TYPE UF_Part

    TYPE, PUBLIC :: UF_Instance
        INTEGER(i4) :: id = 0_i4
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: part_id = 0_i4   ! Index into model%parts(:), 0 = unset
    END TYPE UF_Instance

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

    TYPE, PUBLIC :: UF_Description
        CHARACTER(LEN=256) :: name = ""
    END TYPE UF_Description

    !> Lightweight mesh handle for L5 drivers (e.g. RT_Step_Exec mesh gate, RT_Asm_Solv elem count).
    TYPE, PUBLIC :: UF_ModelMeshHandle
        INTEGER(i4) :: nElems = 0_i4
        INTEGER(i4) :: nNodes = 0_i4
        LOGICAL :: initialized = .FALSE.
    END TYPE UF_ModelMeshHandle

    TYPE, PUBLIC :: UF_Model
        TYPE(UF_Description) :: desc
        TYPE(UF_Assem) :: assembly
        TYPE(UF_Part), ALLOCATABLE :: parts(:)
        TYPE(AnalysisStep), ALLOCATABLE :: steps(:)
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE :: amplitudes(:)
        TYPE(UF_ModelMeshHandle), POINTER :: mesh => NULL()
    END TYPE UF_Model

    TYPE, PUBLIC :: RT_Node
        INTEGER(i4) :: id = 0
        REAL(wp) :: coords(3) = 0.0_wp
        INTEGER(i4), ALLOCATABLE :: dofTypes(:)
    END TYPE RT_Node

    TYPE, PUBLIC :: RT_Element
        INTEGER(i4) :: id = 0_i4
        INTEGER(i4) :: elemTypeId = 0_i4
        INTEGER(i4), ALLOCATABLE :: conn(:)
    END TYPE RT_Element

    TYPE, PUBLIC :: RT_Model
        TYPE(UF_Description) :: desc
        TYPE(UF_Assem) :: assembly
        TYPE(UF_Part), ALLOCATABLE :: parts(:)
    END TYPE RT_Model

    TYPE, PUBLIC :: NodeSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: nodeIds(:)
    END TYPE NodeSet

    TYPE, PUBLIC :: ElemSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: elemIds(:)
    END TYPE ElemSet

    TYPE, PUBLIC :: SurfSet
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4), ALLOCATABLE :: elemIds(:)
        INTEGER(i4), ALLOCATABLE :: faceIds(:)
    END TYPE SurfSet

    !===========================================================================
    ! Public Utilities (Stateless Ops)
    !===========================================================================
    ! PUBLIC procedures (A-Z)
    PUBLIC :: AlgoBase_Cfg, AlgoBase_Deserialize, AlgoBase_Destroy, AlgoBase_Init
    PUBLIC :: AlgoBase_Serialize, AlgoBase_SetTypeName, AlgoBase_SetVarName
    PUBLIC :: Base_ClearBinding, Base_Init, BaseCtx_ClearStatus, BaseCtx_SetStatus, CtxBase_Init
    PUBLIC :: BaseSta_ClearStatus, BaseSta_SetStatus, Container_Add, Container_Clean
    PUBLIC :: Container_Clear, Container_ExpandHashEntries, Container_GetAllIDs, Container_Remove
    PUBLIC :: DescBase_Deserialize, DescBase_Destroy, DescBase_Init, DescBase_Serialize
    PUBLIC :: DescBase_SetTypeName, DescBase_SetVarName, Deserial_BeginArray, Deserial_BeginObject
    PUBLIC :: Deserial_Close, Deserial_Destroy, Deserial_EndArray, Deserial_EndObject
    PUBLIC :: Deserial_Init, Deserial_Open, Deserial_ReadArrayInt, Deserial_ReadArrayReal
    PUBLIC :: Deserial_ReadBool, Deserial_ReadInt, Deserial_ReadReal, Deserial_ReadString
    PUBLIC :: ElemSet_FromIds, ElemSet_Intersect, ElemSet_Subtract, ElemSet_Union
    PUBLIC :: Init_EnergyBuckets, NodeSet_FromIds, NodeSet_Intersect, NodeSet_Subtract
    PUBLIC :: NodeSet_Union, Serial_BeginArray, Serial_BeginObject, Serial_Close
    PUBLIC :: Serial_Destroy, Serial_Init, Serial_Open, Serial_WriteArrayInt
    PUBLIC :: Serial_WriteArrayReal, Serial_WriteBool, Serial_WriteInt, Serial_WriteReal
    PUBLIC :: Serial_WriteString, SortInt, StateBase_Clear, StateBase_Deserialize
    PUBLIC :: StateBase_Destroy, StateBase_Init, StateBase_Serialize, StateBase_SetTypeName
    PUBLIC :: StateBase_SetVarName, TrimAll, UniqueInt


CONTAINS


    !> Purpose: Configure AlgoBase
    SUBROUTINE AlgoBase_Cfg(this, config)
        CLASS(AlgoBase), INTENT(INOUT) :: this
        CLASS(BaseDesc), INTENT(IN) :: config
        ! Default implementation: do nothing
        ! Derived classes should override this
    END SUBROUTINE AlgoBase_Cfg

    !> Purpose: Deserialize AlgoBase
    SUBROUTINE AlgoBase_Deserialize(this, deserializer, status)
        CLASS(AlgoBase), INTENT(INOUT) :: this
        class(TreeDeserializer), intent(inout) :: deserializer
        type(ErrorStatusType), intent(out), optional :: status
        type(ErrorStatusType) :: local_status
        character(len=256) :: obj_name
        
        call init_error_status(local_status)
        
        obj_name = deserializer%BeginObject(local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        this%name = deserializer%ReadString(local_status)
        this%is_init = deserializer%ReadBool(local_status)
        this%algo_category = deserializer%ReadInt(local_status)
        this%algo_type_name = deserializer%ReadString(local_status)
        this%algo_var_name = deserializer%ReadString(local_status)
        
        call deserializer%EndObject(local_status)
        if (present(status)) status = local_status
    END SUBROUTINE AlgoBase_Deserialize

    !> Purpose: Destroy and clean up AlgoBase
    SUBROUTINE AlgoBase_Destroy(this)
        CLASS(AlgoBase), INTENT(INOUT) :: this
        this%name = ""
        this%is_init = .FALSE.
        this%algo_type_name = ""
        this%algo_var_name = ""
    END SUBROUTINE AlgoBase_Destroy

    !> Purpose: Perform GetCategory operation for AlgoBase
    FUNCTION AlgoBase_GetCategory(this) RESULT(cat)
        CLASS(AlgoBase), INTENT(IN) :: this
        INTEGER(i4) :: cat
        cat = this%algo_category
    END FUNCTION AlgoBase_GetCategory

    !> Purpose: Perform GetStatus operation for AlgoBase
    FUNCTION AlgoBase_GetStatus(this) RESULT(status)
        CLASS(AlgoBase), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "AlgoBase not initialized"
        END IF
    END FUNCTION AlgoBase_GetStatus

    !> Purpose: Perform GetTypeName operation for AlgoBase
    FUNCTION AlgoBase_GetTypeName(this) RESULT(name)
        CLASS(AlgoBase), INTENT(IN) :: this
        CHARACTER(LEN=64) :: name
        name = this%algo_type_name
    END FUNCTION AlgoBase_GetTypeName

    !> Purpose: Perform GetVarName operation for AlgoBase
    FUNCTION AlgoBase_GetVarName(this) RESULT(name)
        CLASS(AlgoBase), INTENT(IN) :: this
        CHARACTER(LEN=64) :: name
        name = this%algo_var_name
    END FUNCTION AlgoBase_GetVarName

    !> Purpose: Initialize AlgoBase
    SUBROUTINE AlgoBase_Init(this)
        CLASS(AlgoBase), INTENT(INOUT) :: this
        this%is_init = .TRUE.
        this%name = ""
    END SUBROUTINE AlgoBase_Init

    !> Purpose: Perform IsAlgo operation for AlgoBase
    FUNCTION AlgoBase_IsAlgo(this) RESULT(res)
        CLASS(AlgoBase), INTENT(IN) :: this
        LOGICAL :: res
        res = (this%algo_category == MD_MODEL_CAT_ALGO)
    END FUNCTION AlgoBase_IsAlgo

    !> Purpose: Serialize AlgoBase
    SUBROUTINE AlgoBase_Serialize(this, serializer, status)
        CLASS(AlgoBase), INTENT(IN) :: this
        class(TreeSerializer), intent(inout) :: serializer
        type(ErrorStatusType), intent(out), optional :: status
        type(ErrorStatusType) :: local_status
        
        call init_error_status(local_status)
        
        call serializer%BeginObject("AlgoBase", local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteString(trim(this%name), local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteBool(this%is_init, local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteInt(this%algo_category, local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteString(trim(this%algo_type_name), local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteString(trim(this%algo_var_name), local_status)
        
        call serializer%EndObject(local_status)
        if (present(status)) status = local_status
    END SUBROUTINE AlgoBase_Serialize

    !> Purpose: Perform SetTypeName operation for AlgoBase
    SUBROUTINE AlgoBase_SetTypeName(this, name)
        CLASS(AlgoBase), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        this%algo_type_name = name
    END SUBROUTINE AlgoBase_SetTypeName

    !> Purpose: Perform SetVarName operation for AlgoBase
    SUBROUTINE AlgoBase_SetVarName(this, name)
        CLASS(AlgoBase), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        this%algo_var_name = name
    END SUBROUTINE AlgoBase_SetVarName

    !> Purpose: Perform ClearBinding operation for Base
    SUBROUTINE Base_ClearBinding(self)
        CLASS(CoreBase), INTENT(INOUT) :: self
        self%algo_var_name = ""
    END SUBROUTINE Base_ClearBinding

    !> Purpose: Initialize Base (interface matches ObjBase%Init for override)
    ! Call as Init(struct_name, category) - name and id map to type_name and category
    SUBROUTINE Base_Init(self, name, id, status)
        CLASS(CoreBase), INTENT(INOUT) :: self
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: id
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        self%algo_category = id
        self%algo_type_name = TRIM(name)
        self%algo_var_name = ""
    END SUBROUTINE Base_Init

    !> Purpose: Perform ClearStatus operation for BaseCtx
    SUBROUTINE BaseCtx_ClearStatus(this)
        CLASS(BaseCtx), INTENT(INOUT) :: this
        CALL this%sta%ClearStatus()
    END SUBROUTINE BaseCtx_ClearStatus

    !> Purpose: Perform IsError operation for BaseCtx
    FUNCTION BaseCtx_IsError(this) RESULT(is_error)
        CLASS(BaseCtx), INTENT(IN) :: this
        LOGICAL :: is_error
        TYPE(ErrorStatusType) :: status
        status = this%GetStatus()
        is_error = (status%status_code /= MD_MODEL_STATUS_OK)
    END FUNCTION BaseCtx_IsError

    !> Purpose: Perform IsOK operation for BaseCtx
    FUNCTION BaseCtx_IsOK(this) RESULT(is_ok)
        CLASS(BaseCtx), INTENT(IN) :: this
        LOGICAL :: is_ok
        TYPE(ErrorStatusType) :: status
        status = this%GetStatus()
        is_ok = (status%status_code == MD_MODEL_STATUS_OK)
    END FUNCTION BaseCtx_IsOK

    !> Purpose: Perform SetStatus operation for BaseCtx
    SUBROUTINE BaseCtx_SetStatus(this, status)
        CLASS(BaseCtx), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(IN) :: status
        CALL this%sta%SetStatus(status)
    END SUBROUTINE BaseCtx_SetStatus

    !> Purpose: Perform ClearStatus operation for BaseSta
    SUBROUTINE BaseSta_ClearStatus(this)
        CLASS(BaseSta), INTENT(INOUT) :: this
        CALL init_error_status(this%status_)
        this%has_error = .false.
    END SUBROUTINE BaseSta_ClearStatus

    !> Purpose: Perform GetStatus operation for BaseSta
    FUNCTION BaseSta_GetStatus(this) RESULT(status)
        CLASS(BaseSta), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        status = this%status_
    END FUNCTION BaseSta_GetStatus

    !> Purpose: Perform IsError operation for BaseSta
    FUNCTION BaseSta_IsError(this) RESULT(is_error)
        CLASS(BaseSta), INTENT(IN) :: this
        LOGICAL :: is_error
        is_error = this%has_error
    END FUNCTION BaseSta_IsError

    !> Purpose: Perform IsOK operation for BaseSta
    FUNCTION BaseSta_IsOK(this) RESULT(is_ok)
        CLASS(BaseSta), INTENT(IN) :: this
        LOGICAL :: is_ok
        is_ok = (.not. this%has_error) .and. (this%status_%status_code == MD_MODEL_STATUS_OK)
    END FUNCTION BaseSta_IsOK

    !> Purpose: Perform SetStatus operation for BaseSta
    SUBROUTINE BaseSta_SetStatus(this, status)
        CLASS(BaseSta), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(IN) :: status
        this%status_ = status
        this%has_error = (status%status_code /= MD_MODEL_STATUS_OK)
    END SUBROUTINE BaseSta_SetStatus

    !> Purpose: Add Container
    SUBROUTINE Container_Add(this, obj, status)
        CLASS(ObjContainer), INTENT(INOUT) :: this
        CLASS(ObjBase), INTENT(IN), TARGET :: obj
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: id, idx, hash_val, entry_idx
        CHARACTER(LEN=64) :: name
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            CALL this%Init(status=status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        END IF
        id = obj%cfg%id()
        name = obj%name()
        IF (id > 0 .AND. id <= SIZE(this%id_map)) THEN
            IF (this%id_map(id) > 0) THEN
                status%status_code = MD_MODEL_STATUS_INVALID
                status%message = "Object with ID already exists"
                RETURN
            END IF
        END IF
        IF (this%count >= this%capacity) THEN
            CALL this%Resize(this%capacity * MD_MODEL_GROWTH_FACTOR, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        END IF
        IF (this%hash_entry_coun >= this%hash_entry_capa) THEN
            CALL this%ExpandHashEntries(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        END IF
        this%count = this%count + 1_i4
        idx = this%count
        IF (.NOT. ALLOCATED(this%objects)) THEN
            ALLOCATE(this%objects(this%capacity))
        END IF
        ALLOCATE(this%objects(idx)%p, source=obj)
        IF (id > 0) THEN
            IF (id > SIZE(this%id_map)) CALL this%Resize(MAX(id, this%capacity * MD_MODEL_GROWTH_FACTOR), status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            this%id_map(id) = idx
            this%max_id = MAX(this%max_id, id)
        END IF
        IF (this%use_hash .AND. LEN_TRIM(name) > 0) THEN
            hash_val = HashString(name)
            entry_idx = this%hash_entry_coun + 1_i4
            this%hash_entry_coun = entry_idx
            this%hash_entries(entry_idx)%cfg%id = id
            this%hash_entries(entry_idx)%next = this%hash_table(hash_val)
            this%hash_table(hash_val) = entry_idx
        END IF
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_Add

    !> Purpose: Clean up Container
    SUBROUTINE Container_Clean(this, status)
        CLASS(ObjContainer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (ALLOCATED(this%id_map)) DEALLOCATE(this%id_map)
        IF (ALLOCATED(this%hash_table)) DEALLOCATE(this%hash_table)
        IF (ALLOCATED(this%hash_entries)) DEALLOCATE(this%hash_entries)
        IF (ALLOCATED(this%objects)) THEN
            DEALLOCATE(this%objects)
        END IF
        this%capacity = 0_i4
        this%count = 0_i4
        this%max_id = 0_i4
        this%hash_entry_coun = 0_i4
        this%hash_entry_capa = 0_i4
        this%is_init = .false.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_Clean

    !> Purpose: Clear Container
    SUBROUTINE Container_Clear(this, status)
        CLASS(ObjContainer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (ALLOCATED(this%id_map)) this%id_map = 0_i4
        IF (ALLOCATED(this%hash_table)) this%hash_table = 0_i4
        IF (ALLOCATED(this%hash_entries)) THEN
            this%hash_entries%cfg%id = 0_i4
            this%hash_entries%next = 0_i4
        END IF
        this%count = 0_i4
        this%max_id = 0_i4
        this%hash_entry_coun = 0_i4
        this%index_dirty = .false.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_Clear

    !> Purpose: Perform ExpandHashEntries operation for Container
    SUBROUTINE Container_ExpandHashEntries(this, status)
        CLASS(ObjContainer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(HashEntry), ALLOCATABLE :: temp(:)
        INTEGER(i4) :: new_capacity
        CALL init_error_status(status)
        new_capacity = this%hash_entry_capa * MD_MODEL_GROWTH_FACTOR
        IF (new_capacity < this%hash_entry_capa) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END IF
        ALLOCATE(temp(new_capacity))
        temp(1:this%hash_entry_capa) = this%hash_entries(1:this%hash_entry_capa)
        temp(this%hash_entry_capa+1:new_capacity)%cfg%id = 0_i4
        temp(this%hash_entry_capa+1:new_capacity)%next = 0_i4
        CALL MOVE_ALLOC(temp, this%hash_entries)
        this%hash_entry_capa = new_capacity
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_ExpandHashEntries

    !> Purpose: Find Container
    FUNCTION Container_Find(this, id, name) RESULT(obj_ptr)
        CLASS(ObjContainer), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: id
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
        CLASS(ObjBase), POINTER :: obj_ptr
        obj_ptr => null()
        IF (PRESENT(id)) THEN
            obj_ptr => this%GetByID(id)
            IF (ASSOCIATED(obj_ptr)) RETURN
        END IF
        IF (PRESENT(name)) obj_ptr => this%GetByName(name)
    END FUNCTION Container_Find

    !> Purpose: Perform GetAllIDs operation for Container
    SUBROUTINE Container_GetAllIDs(this, ids, status)
        CLASS(ObjContainer), INTENT(IN) :: this
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: ids(:)
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        INTEGER(i4) :: i, n, id
        IF (PRESENT(status)) CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            IF (PRESENT(status)) status%status_code = MD_MODEL_STATUS_INVALID
            status%message = 'Container not initialized'
            RETURN
        END IF
        n = 0_i4
        IF (ALLOCATED(this%objects)) THEN
            DO i = 1, this%count
                IF (ASSOCIATED(this%objects(i)%p)) n = n + 1_i4
            END DO
        END IF
        IF (n > 0_i4) THEN
            ALLOCATE(ids(n))
            n = 0_i4
            DO i = 1, this%count
                IF (ASSOCIATED(this%objects(i)%p)) THEN
                    id = this%objects(i)%p%cfg%id()
                    IF (id > 0_i4) THEN
                        n = n + 1_i4
                        ids(n) = id
                    END IF
                END IF
            END DO
        ELSE
            ALLOCATE(ids(0))
        END IF
        IF (PRESENT(status)) status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_GetAllIDs

    !> Purpose: Perform GetByID operation for Container
    FUNCTION Container_GetByID(this, id) RESULT(obj_ptr)
        CLASS(ObjContainer), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: id
        CLASS(ObjBase), POINTER :: obj_ptr
        INTEGER(i4) :: idx
        obj_ptr => null()
        IF (.NOT. this%is_init) RETURN
        IF (id < 1 .OR. id > SIZE(this%id_map)) RETURN
        idx = this%id_map(id)
        IF (idx > 0 .AND. idx <= this%count .AND. ALLOCATED(this%objects) .AND. ASSOCIATED(this%objects(idx)%p)) &
            obj_ptr => this%objects(idx)%p
    END FUNCTION Container_GetByID

    !> Purpose: Perform GetByIndex operation for Container
    FUNCTION Container_GetByIndex(this, index) RESULT(obj_ptr)
        CLASS(ObjContainer), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: index
        CLASS(ObjBase), POINTER :: obj_ptr
        obj_ptr => null()
        IF (.NOT. this%is_init) RETURN
        IF (index < 1 .OR. index > this%count) RETURN
        IF (ALLOCATED(this%objects) .AND. ASSOCIATED(this%objects(index)%p)) obj_ptr => this%objects(index)%p
    END FUNCTION Container_GetByIndex

    !> Purpose: Perform GetByName operation for Container
    FUNCTION Container_GetByName(this, name) RESULT(obj_ptr)
        CLASS(ObjContainer), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        CLASS(ObjBase), POINTER :: obj_ptr
        INTEGER(i4) :: hash_val, entry_idx, id
        obj_ptr => null()
        IF (.NOT. this%is_init .OR. .NOT. this%use_hash .OR. LEN_TRIM(name) == 0) RETURN
        hash_val = HashString(name)
        entry_idx = this%hash_table(hash_val)
        DO WHILE (entry_idx > 0)
            id = this%hash_entries(entry_idx)%cfg%id
            IF (id > 0) THEN
                obj_ptr => this%GetByID(id)
                IF (ASSOCIATED(obj_ptr) .AND. TRIM(obj_ptr%name()) == TRIM(name)) RETURN
            END IF
            entry_idx = this%hash_entries(entry_idx)%next
        END DO
        obj_ptr => null()
    END FUNCTION Container_GetByName

    !> Purpose: Perform GetCapacity operation for Container
    FUNCTION Container_GetCapacity(this) RESULT(capacity)
        CLASS(ObjContainer), INTENT(IN) :: this
        INTEGER(i4) :: capacity
        capacity = this%capacity
    END FUNCTION Container_GetCapacity

    !> Purpose: Perform GetCount operation for Container
    FUNCTION Container_GetCount(this) RESULT(count)
        CLASS(ObjContainer), INTENT(IN) :: this
        INTEGER(i4) :: count
        count = this%count
    END FUNCTION Container_GetCount

    !> Purpose: Initialize Container
    SUBROUTINE Container_Init(this, init_cap, status)
        CLASS(ObjContainer), INTENT(OUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: init_cap
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: cap
        CALL init_error_status(status)
        cap = MD_MODEL_OBJ_INITIAL_CAPACIT
        IF (PRESENT(init_cap)) cap = MAX(1_i4, init_cap)
        this%capacity = cap
        this%count = 0_i4
        this%max_id = 0_i4
        this%hash_entry_coun = 0_i4
        this%hash_entry_capa = cap
        this%use_hash = .true.
        this%index_dirty = .false.
        this%is_init = .true.
        ALLOCATE(this%id_map(cap))
        this%id_map = 0_i4
        ALLOCATE(this%hash_table(MD_MODEL_HASH_TABLE_SIZE))
        this%hash_table = 0_i4
        ALLOCATE(this%hash_entries(cap))
        this%hash_entries%cfg%id = 0_i4
        this%hash_entries%next = 0_i4
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_Init

    !> Purpose: Perform RebuildIndex operation for Container
    SUBROUTINE Container_RebuildIndex(this, status)
        CLASS(ObjContainer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, id, hash_val, entry_idx
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END IF
        this%id_map = 0_i4
        this%hash_table = 0_i4
        this%hash_entry_coun = 0_i4
        IF (ALLOCATED(this%objects)) THEN
            DO i = 1, this%count
                IF (.NOT. ASSOCIATED(this%objects(i)%p)) CYCLE
                id = this%objects(i)%p%cfg%id()
                IF (id > 0) THEN
                    IF (id > SIZE(this%id_map)) THEN
                        CALL this%Resize(id, status)
                        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
                    END IF
                    this%id_map(id) = i
                    this%max_id = MAX(this%max_id, id)
                END IF
            END DO
        END IF
        IF (this%use_hash .AND. ALLOCATED(this%objects)) THEN
            DO i = 1, this%count
                IF (.NOT. ASSOCIATED(this%objects(i)%p)) CYCLE
                id = this%objects(i)%p%cfg%id()
                IF (id > 0) THEN
                    hash_val = HashString(this%objects(i)%p%name())
                    entry_idx = this%hash_entry_coun + 1_i4
                    IF (entry_idx > this%hash_entry_capa) THEN
                        CALL this%ExpandHashEntries(status)
                        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
                    END IF
                    this%hash_entry_coun = entry_idx
                    this%hash_entries(entry_idx)%cfg%id = id
                    this%hash_entries(entry_idx)%next = this%hash_table(hash_val)
                    this%hash_table(hash_val) = entry_idx
                END IF
            END DO
        END IF
        this%index_dirty = .false.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_RebuildIndex

    !> Purpose: Remove Container
    SUBROUTINE Container_Remove(this, id, status)
        CLASS(ObjContainer), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx, i, hash_val, entry_idx, prev_idx
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            status%status_code = MD_MODEL_STATUS_NOT_FOUND
            RETURN
        END IF
        IF (id < 1 .OR. id > SIZE(this%id_map)) THEN
            status%status_code = MD_MODEL_STATUS_NOT_FOUND
            RETURN
        END IF
        idx = this%id_map(id)
        IF (idx <= 0 .OR. idx > this%count) THEN
            status%status_code = MD_MODEL_STATUS_NOT_FOUND
            RETURN
        END IF
        IF (this%use_hash .AND. ALLOCATED(this%objects) .AND. ASSOCIATED(this%objects(idx)%p)) THEN
            hash_val = HashString(this%objects(idx)%p%name())
            entry_idx = this%hash_table(hash_val)
            prev_idx = 0_i4
            DO WHILE (entry_idx > 0)
                IF (this%hash_entries(entry_idx)%cfg%id == id) THEN
                    IF (prev_idx > 0) THEN
                        this%hash_entries(prev_idx)%next = this%hash_entries(entry_idx)%next
                    ELSE
                        this%hash_table(hash_val) = this%hash_entries(entry_idx)%next
                    END IF
                    EXIT
                END IF
                prev_idx = entry_idx
                entry_idx = this%hash_entries(entry_idx)%next
            END DO
        END IF
        IF (idx < this%count .AND. ASSOCIATED(this%objects(this%count)%p)) THEN
            IF (ASSOCIATED(this%objects(idx)%p)) DEALLOCATE(this%objects(idx)%p)
            ALLOCATE(this%objects(idx)%p, source=this%objects(this%count)%p)
            DEALLOCATE(this%objects(this%count)%p)
            NULLIFY(this%objects(this%count)%p)
            i = this%objects(idx)%p%cfg%id()
            IF (i > 0 .AND. i <= SIZE(this%id_map)) this%id_map(i) = idx
        ELSE IF (ASSOCIATED(this%objects(idx)%p)) THEN
            DEALLOCATE(this%objects(idx)%p)
            NULLIFY(this%objects(idx)%p)
        END IF
        this%id_map(id) = 0_i4
        this%count = this%count - 1_i4
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_Remove

    !> Purpose: Perform Resize operation for Container
    SUBROUTINE Container_Resize(this, new_capacity, status)
        CLASS(ObjContainer), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: new_capacity
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4), ALLOCATABLE :: temp_id_map(:)
        TYPE(ObjPtr), ALLOCATABLE :: temp_objects(:)
        INTEGER(i4) :: i
        CALL init_error_status(status)
        IF (new_capacity < this%count) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "New capacity must be >= current count"
            RETURN
        END IF
        IF (ALLOCATED(this%id_map)) THEN
            ALLOCATE(temp_id_map(new_capacity))
            temp_id_map(1:MIN(SIZE(this%id_map), new_capacity)) = this%id_map(1:MIN(SIZE(this%id_map), new_capacity))
            IF (new_capacity > SIZE(this%id_map)) temp_id_map(SIZE(this%id_map)+1:new_capacity) = 0_i4
            CALL MOVE_ALLOC(temp_id_map, this%id_map)
        ELSE
            ALLOCATE(this%id_map(new_capacity))
            this%id_map = 0_i4
        END IF
        IF (ALLOCATED(this%objects)) THEN
            ALLOCATE(temp_objects(new_capacity))
            DO i = 1, this%count
                IF (ASSOCIATED(this%objects(i)%p)) THEN
                    ALLOCATE(temp_objects(i)%p, source=this%objects(i)%p)
                    DEALLOCATE(this%objects(i)%p)
                END IF
            END DO
            CALL MOVE_ALLOC(temp_objects, this%objects)
        END IF
        this%capacity = new_capacity
        this%index_dirty = .true.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_Resize

    !> Purpose: Update Container
    SUBROUTINE Container_Update(this, id, obj, status)
        CLASS(ObjContainer), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: id
        CLASS(ObjBase), INTENT(IN) :: obj
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx, hash_val, entry_idx, prev_idx
        CHARACTER(LEN=64) :: old_name, new_name
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END IF
        IF (id < 1 .OR. id > SIZE(this%id_map)) THEN
            status%status_code = MD_MODEL_STATUS_NOT_FOUND
            RETURN
        END IF
        idx = this%id_map(id)
        IF (idx <= 0 .OR. idx > this%count) THEN
            status%status_code = MD_MODEL_STATUS_NOT_FOUND
            RETURN
        END IF
        IF (ALLOCATED(this%objects) .AND. ASSOCIATED(this%objects(idx)%p)) THEN
            old_name = this%objects(idx)%p%name()
        ELSE
            old_name = ''
        END IF
        new_name = obj%name()
        IF (this%use_hash .AND. TRIM(old_name) /= TRIM(new_name)) THEN
            IF (LEN_TRIM(old_name) > 0) THEN
                hash_val = HashString(old_name)
                entry_idx = this%hash_table(hash_val)
                prev_idx = 0_i4
                DO WHILE (entry_idx > 0)
                    IF (this%hash_entries(entry_idx)%cfg%id == id) THEN
                        IF (prev_idx > 0) THEN
                            this%hash_entries(prev_idx)%next = this%hash_entries(entry_idx)%next
                        ELSE
                            this%hash_table(hash_val) = this%hash_entries(entry_idx)%next
                        END IF
                        EXIT
                    END IF
                    prev_idx = entry_idx
                    entry_idx = this%hash_entries(entry_idx)%next
                END DO
            END IF
            IF (LEN_TRIM(new_name) > 0) THEN
                hash_val = HashString(new_name)
                IF (this%hash_entry_coun >= this%hash_entry_capa) THEN
                    CALL this%ExpandHashEntries(status)
                    IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
                END IF
                entry_idx = this%hash_entry_coun + 1_i4
                this%hash_entry_coun = entry_idx
                this%hash_entries(entry_idx)%cfg%id = id
                this%hash_entries(entry_idx)%next = this%hash_table(hash_val)
                this%hash_table(hash_val) = entry_idx
            END IF
        END IF
        IF (ASSOCIATED(this%objects(idx)%p)) DEALLOCATE(this%objects(idx)%p)
        ALLOCATE(this%objects(idx)%p, source=obj)
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_Update

    !> Purpose: Check validity Container
    SUBROUTINE Container_Valid(this, status)
        CLASS(ObjContainer), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, id, idx
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Container not initialized"
            RETURN
        END IF
        IF (ALLOCATED(this%objects) .AND. ALLOCATED(this%id_map)) THEN
            DO i = 1, this%count
                IF (.NOT. ASSOCIATED(this%objects(i)%p)) CYCLE
                id = this%objects(i)%p%cfg%id()
                IF (id > 0) THEN
                    IF (id > SIZE(this%id_map)) THEN
                        status%status_code = MD_MODEL_STATUS_INVALID
                        status%message = "ID exceeds ID map size"
                        RETURN
                    END IF
                    idx = this%id_map(id)
                    IF (idx /= i) THEN
                        status%status_code = MD_MODEL_STATUS_INVALID
                        status%message = "ID map inconsistency"
                        RETURN
                    END IF
                END IF
            END DO
        END IF
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Container_Valid

    !> Purpose: Deserialize CtxBase
    SUBROUTINE CtxBase_Deserialize(this, deserializer, status)
        CLASS(CtxBase), INTENT(INOUT) :: this
        CLASS(TreeDeserializer), INTENT(INOUT) :: deserializer
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        TYPE(ErrorStatusType) :: local_status
        CHARACTER(LEN=256) :: obj_name
        CALL init_error_status(local_status)
        obj_name = deserializer%BeginObject(local_status)
        IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        this%is_init = deserializer%ReadBool(local_status)
        this%algo_category = deserializer%ReadInt(local_status)
        this%algo_type_name = deserializer%ReadString(local_status)
        this%algo_var_name = deserializer%ReadString(local_status)
        local_status%status_code = deserializer%ReadInt(local_status)
        local_status%message = deserializer%ReadString(local_status)
        CALL this%sta%SetStatus(local_status)
        CALL deserializer%EndObject(local_status)
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE CtxBase_Deserialize

    !> Purpose: Destroy and clean up CtxBase
    SUBROUTINE CtxBase_Destroy(this)
        CLASS(CtxBase), INTENT(INOUT) :: this
        this%is_init = .FALSE.
        this%algo_type_name = ""
        this%algo_var_name = ""
        CALL this%sta%ClearStatus()
    END SUBROUTINE CtxBase_Destroy

    !> Purpose: Perform GetCategory operation for CtxBase
    FUNCTION CtxBase_GetCategory(this) RESULT(cat)
        CLASS(CtxBase), INTENT(IN) :: this
        INTEGER(i4) :: cat
        cat = this%algo_category
    END FUNCTION CtxBase_GetCategory

    !> Purpose: Perform GetStatus operation for CtxBase
    FUNCTION CtxBase_GetStatus(this) RESULT(status)
        CLASS(CtxBase), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        status = this%sta%GetStatus()
    END FUNCTION CtxBase_GetStatus

    !> Purpose: Perform GetTypeName operation for CtxBase
    FUNCTION CtxBase_GetTypeName(this) RESULT(name)
        CLASS(CtxBase), INTENT(IN) :: this
        CHARACTER(LEN=64) :: name
        name = this%algo_type_name
    END FUNCTION CtxBase_GetTypeName

    !> Purpose: Perform GetVarName operation for CtxBase
    FUNCTION CtxBase_GetVarName(this) RESULT(name)
        CLASS(CtxBase), INTENT(IN) :: this
        CHARACTER(LEN=64) :: name
        name = this%algo_var_name
    END FUNCTION CtxBase_GetVarName

    !> Purpose: Initialize CtxBase
    SUBROUTINE CtxBase_Init(this)
        CLASS(CtxBase), INTENT(INOUT) :: this
        this%is_init = .TRUE.
        CALL this%sta%ClearStatus()
    END SUBROUTINE CtxBase_Init

    !> Purpose: Perform IsCtx operation for CtxBase
    FUNCTION CtxBase_IsCtx(this) RESULT(res)
        CLASS(CtxBase), INTENT(IN) :: this
        LOGICAL :: res
        res = (this%algo_category == MD_MODEL_CAT_CTX)
    END FUNCTION CtxBase_IsCtx

    !> Purpose: Reset CtxBase
    SUBROUTINE CtxBase_Reset(this)
        CLASS(CtxBase), INTENT(INOUT) :: this
        CALL this%sta%ClearStatus()
    END SUBROUTINE CtxBase_Reset

    !> Purpose: Serialize CtxBase
    SUBROUTINE CtxBase_Serialize(this, serializer, status)
        CLASS(CtxBase), INTENT(IN) :: this
        CLASS(TreeSerializer), INTENT(INOUT) :: serializer
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        TYPE(ErrorStatusType) :: local_status
        CALL init_error_status(local_status)
        local_status = this%sta%GetStatus()
        CALL serializer%BeginObject("CtxBase", local_status)
        IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        CALL serializer%WriteBool(this%is_init, local_status)
        CALL serializer%WriteInt(this%algo_category, local_status)
        CALL serializer%WriteString(TRIM(this%algo_type_name), local_status)
        CALL serializer%WriteString(TRIM(this%algo_var_name), local_status)
        CALL serializer%WriteInt(local_status%status_code, local_status)
        CALL serializer%WriteString(TRIM(local_status%message), local_status)
        CALL serializer%EndObject(local_status)
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE CtxBase_Serialize

    !> Purpose: Perform SetTypeName operation for CtxBase
    SUBROUTINE CtxBase_SetTypeName(this, name)
        CLASS(CtxBase), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        this%algo_type_name = name
    END SUBROUTINE CtxBase_SetTypeName

    !> Purpose: Perform SetVarName operation for CtxBase
    SUBROUTINE CtxBase_SetVarName(this, name)
        CLASS(CtxBase), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        this%algo_var_name = name
    END SUBROUTINE CtxBase_SetVarName

    !> Purpose: Deserialize DescBase
    SUBROUTINE DescBase_Deserialize(this, deserializer, status)
        CLASS(DescBase), INTENT(INOUT) :: this
        CLASS(TreeDeserializer), INTENT(INOUT) :: deserializer
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        TYPE(ErrorStatusType) :: local_status
        CHARACTER(LEN=256) :: obj_name
        
        CALL init_error_status(local_status)
        
        obj_name = deserializer%BeginObject(local_status)
        IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        this%name = deserializer%ReadString(local_status)
        this%is_init = deserializer%ReadBool(local_status)
        this%algo_category = deserializer%ReadInt(local_status)
        this%algo_type_name = deserializer%ReadString(local_status)
        this%algo_var_name = deserializer%ReadString(local_status)
        
        CALL deserializer%EndObject(local_status)
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE DescBase_Deserialize

    !> Purpose: Destroy and clean up DescBase
    SUBROUTINE DescBase_Destroy(this)
        CLASS(DescBase), INTENT(INOUT) :: this
        this%name = ""
        this%is_init = .FALSE.
        this%algo_type_name = ""
        this%algo_var_name = ""
    END SUBROUTINE DescBase_Destroy

    !> Purpose: Perform GetCategory operation for DescBase
    FUNCTION DescBase_GetCategory(this) RESULT(cat)
        CLASS(DescBase), INTENT(IN) :: this
        INTEGER(i4) :: cat
        cat = this%algo_category
    END FUNCTION DescBase_GetCategory

    !> Purpose: Perform GetStatus operation for DescBase
    FUNCTION DescBase_GetStatus(this) RESULT(status)
        CLASS(DescBase), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "DescBase not initialized"
        END IF
    END FUNCTION DescBase_GetStatus

    !> Purpose: Perform GetTypeName operation for DescBase
    FUNCTION DescBase_GetTypeName(this) RESULT(name)
        CLASS(DescBase), INTENT(IN) :: this
        CHARACTER(LEN=64) :: name
        name = this%algo_type_name
    END FUNCTION DescBase_GetTypeName

    !> Purpose: Perform GetVarName operation for DescBase
    FUNCTION DescBase_GetVarName(this) RESULT(name)
        CLASS(DescBase), INTENT(IN) :: this
        CHARACTER(LEN=64) :: name
        name = this%algo_var_name
    END FUNCTION DescBase_GetVarName

    !> Purpose: Initialize DescBase
    SUBROUTINE DescBase_Init(this)
        CLASS(DescBase), INTENT(INOUT) :: this
        this%is_init = .TRUE.
        this%name = ""
    END SUBROUTINE DescBase_Init

    !> Purpose: Perform IsDesc operation for DescBase
    FUNCTION DescBase_IsDesc(this) RESULT(res)
        CLASS(DescBase), INTENT(IN) :: this
        LOGICAL :: res
        res = (this%algo_category == MD_MODEL_CAT_DESC)
    END FUNCTION DescBase_IsDesc

    !> Purpose: Serialize DescBase
    SUBROUTINE DescBase_Serialize(this, serializer, status)
        CLASS(DescBase), INTENT(IN) :: this
        CLASS(TreeSerializer), INTENT(INOUT) :: serializer
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(local_status)
        
        CALL serializer%BeginObject("DescBase", local_status)
        IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        CALL serializer%WriteString(TRIM(this%name), local_status)
        IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        CALL serializer%WriteBool(this%is_init, local_status)
        IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        CALL serializer%WriteInt(this%algo_category, local_status)
        IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        CALL serializer%WriteString(TRIM(this%algo_type_name), local_status)
        IF (local_status%status_code /= MD_MODEL_STATUS_OK) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        CALL serializer%WriteString(TRIM(this%algo_var_name), local_status)
        
        CALL serializer%EndObject(local_status)
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE DescBase_Serialize

    !> Purpose: Perform SetTypeName operation for DescBase
    SUBROUTINE DescBase_SetTypeName(this, name)
        CLASS(DescBase), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        this%algo_type_name = name
    END SUBROUTINE DescBase_SetTypeName

    !> Purpose: Perform SetVarName operation for DescBase
    SUBROUTINE DescBase_SetVarName(this, name)
        CLASS(DescBase), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        this%algo_var_name = name
    END SUBROUTINE DescBase_SetVarName

    !> Purpose: Check validity DescBase
    FUNCTION DescBase_Valid(this) RESULT(is_valid)
        CLASS(DescBase), INTENT(IN) :: this
        LOGICAL :: is_valid
        is_valid = this%is_init .AND. LEN_TRIM(this%name) > 0
    END FUNCTION DescBase_Valid

    !> Purpose: Perform BeginArray operation for Deserial
    FUNCTION Deserial_BeginArray(this, status) RESULT(name)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=256) :: name
        name = this%ReadString(status)
    END FUNCTION Deserial_BeginArray

    !> Purpose: Perform BeginObject operation for Deserial
    FUNCTION Deserial_BeginObject(this, status) RESULT(name)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=256) :: name
        name = this%ReadString(status)
    END FUNCTION Deserial_BeginObject

    !> Purpose: Close Deserial
    SUBROUTINE Deserial_Close(this, status)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. this%file_open) THEN
            status%status_code = MD_MODEL_STATUS_OK
            RETURN
        END IF
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%rw_deserializer%Close(status)
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
        this%file_open = .FALSE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Deserial_Close

    !> Purpose: Destroy and clean up Deserial
    SUBROUTINE Deserial_Destroy(this, status)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: fmt
        CALL init_error_status(status)
        fmt = this%format
        IF (this%file_open) CALL this%Close(status)
        IF (fmt == MD_MODEL_SERIAL_FORMAT_B) CALL this%rw_deserializer%Destroy()
        this%is_init = .FALSE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Deserial_Destroy

    !> Purpose: Perform EndArray operation for Deserial
    SUBROUTINE Deserial_EndArray(this, status)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: marker
        marker = this%ReadInt(status)
        IF (marker /= -2_i4) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid end array marker"
        END IF
    END SUBROUTINE Deserial_EndArray

    !> Purpose: Perform EndObject operation for Deserial
    SUBROUTINE Deserial_EndObject(this, status)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: marker
        marker = this%ReadInt(status)
        IF (marker /= -1_i4) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid end object marker"
        END IF
    END SUBROUTINE Deserial_EndObject

    !> Purpose: Initialize Deserial
    SUBROUTINE Deserial_Init(this, format, status)
        CLASS(TreeDeserializer), INTENT(OUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: format
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%format = MD_MODEL_SERIAL_FORMAT_B
        IF (PRESENT(format)) this%format = format
        this%is_init = .TRUE.
        this%file_open = .FALSE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Deserial_Init

    !> Purpose: Open Deserial
    SUBROUTINE Deserial_Open(this, file_path, status)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            CALL this%Init(status=status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        END IF
        this%file_path = TRIM(file_path)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%rw_deserializer%Init(file_path, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%rw_deserializer%Open(status)
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Format not yet implemented"
            RETURN
        END SELECT
        IF (status%status_code == MD_MODEL_STATUS_OK) this%file_open = .TRUE.
    END SUBROUTINE Deserial_Open

    !> Purpose: Perform ReadArrayInt operation for Deserial
    SUBROUTINE Deserial_ReadArrayInt(this, array, status)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: array(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, n
        CALL init_error_status(status)
        n = this%ReadInt(status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        IF (n > 0) THEN
            ALLOCATE(array(n))
            DO i = 1, n
                array(i) = this%ReadInt(status)
                IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                    DEALLOCATE(array)
                    RETURN
                END IF
            END DO
        ELSE
            ALLOCATE(array(0))
        END IF
    END SUBROUTINE Deserial_ReadArrayInt

    !> Purpose: Perform ReadArrayReal operation for Deserial
    SUBROUTINE Deserial_ReadArrayReal(this, array, status)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        REAL(wp), ALLOCATABLE, INTENT(OUT) :: array(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, n
        CALL init_error_status(status)
        n = this%ReadInt(status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        IF (n > 0) THEN
            ALLOCATE(array(n))
            DO i = 1, n
                array(i) = this%ReadReal(status)
                IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                    DEALLOCATE(array)
                    RETURN
                END IF
            END DO
        ELSE
            ALLOCATE(array(0))
        END IF
    END SUBROUTINE Deserial_ReadArrayReal

    !> Purpose: Perform ReadBool operation for Deserial
    FUNCTION Deserial_ReadBool(this, status) RESULT(value)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        LOGICAL :: value
        INTEGER(i4) :: int_val
        int_val = this%ReadInt(status)
        value = (int_val /= 0)
    END FUNCTION Deserial_ReadBool

    !> Purpose: Perform ReadInt operation for Deserial
    FUNCTION Deserial_ReadInt(this, status) RESULT(value)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: value
        CALL init_error_status(status)
        IF (.NOT. this%file_open) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "File not open"
            value = 0_i4
            RETURN
        END IF
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL RW_Deserialize_Int4(this%rw_deserializer, value, status)
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            value = 0_i4
            RETURN
        END SELECT
    END FUNCTION Deserial_ReadInt

    !> Purpose: Perform ReadReal operation for Deserial
    FUNCTION Deserial_ReadReal(this, status) RESULT(value)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        REAL(wp) :: value
        CALL init_error_status(status)
        IF (.NOT. this%file_open) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "File not open"
            value = 0.0_wp
            RETURN
        END IF
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL RW_Deserialize_DP(this%rw_deserializer, value, status)
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            value = 0.0_wp
            RETURN
        END SELECT
    END FUNCTION Deserial_ReadReal

    !> Purpose: Perform ReadString operation for Deserial
    FUNCTION Deserial_ReadString(this, status) RESULT(value)
        CLASS(TreeDeserializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=256) :: value
        INTEGER(i4) :: ncopy
        CHARACTER(LEN=:), ALLOCATABLE :: str_alloc
        CALL init_error_status(status)
        value = ""
        IF (.NOT. this%file_open) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL RW_Deserialize_String(this%rw_deserializer, str_alloc, status)
            IF (status%status_code == MD_MODEL_STATUS_OK .AND. ALLOCATED(str_alloc)) THEN
                ncopy = MIN(LEN(str_alloc), 256)
                IF (ncopy > 0) value(1:ncopy) = str_alloc(1:ncopy)
                value(ncopy+1:) = ""
            END IF
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END FUNCTION Deserial_ReadString

    !> Purpose: Get equation
    FUNCTION dm_Eq(this, node, slot) RESULT(eq)
        CLASS(DofMap), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: node, slot
        INTEGER(i4) :: eq
        eq = 0
        IF (node >= 1 .AND. node <= this%nNode) THEN
            IF (slot >= 1 .AND. slot <= this%ndof(node)) THEN
                eq = this%eq_map(node, slot)
            END IF
        END IF
    END FUNCTION dm_Eq

    !> Purpose: Free
    SUBROUTINE dm_Free(this)
        CLASS(DofMap), INTENT(INOUT) :: this
        IF (ASSOCIATED(this%ndof)) DEALLOCATE(this%ndof)
        IF (ASSOCIATED(this%eq_map)) DEALLOCATE(this%eq_map)
        this%nNode = 0
        this%maxDpn = 0
        NULLIFY(this%ndof)
        NULLIFY(this%eq_map)
    END SUBROUTINE dm_Free

    !> Purpose: Initialize
    SUBROUTINE dm_Init(this, nNode, maxDpn)
        CLASS(DofMap), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: nNode, maxDpn
        this%nNode = nNode
        this%maxDpn = maxDpn
        ALLOCATE(this%ndof(nNode))
        ALLOCATE(this%eq_map(nNode, maxDpn))
        this%ndof = 0
        this%eq_map = 0
    END SUBROUTINE dm_Init

    !> Purpose: Perform MakeEq operation
    SUBROUTINE dm_MakeEq(this)
        CLASS(DofMap), INTENT(INOUT) :: this
        INTEGER(i4) :: i, j, eq_counter
        eq_counter = 0
        DO i = 1, this%nNode
            DO j = 1, this%ndof(i)
                eq_counter = eq_counter + 1
                this%eq_map(i, j) = eq_counter
            END DO
        END DO
    END SUBROUTINE dm_MakeEq

    !> Purpose: Perform Neq operation
    FUNCTION dm_Neq(this) RESULT(neq)
        CLASS(DofMap), INTENT(IN) :: this
        INTEGER(i4) :: neq, i
        neq = 0
        DO i = 1, this%nNode
            neq = neq + this%ndof(i)
        END DO
    END FUNCTION dm_Neq

    !> Purpose: Perform NodeRng operation
    FUNCTION dm_NodeRng(this, node) RESULT(rng)
        CLASS(DofMap), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: node
        INTEGER(i4) :: rng(2)
        rng = 0
        IF (node >= 1 .AND. node <= this%nNode) THEN
            IF (this%ndof(node) > 0) THEN
                rng(1) = this%eq_map(node, 1)
                rng(2) = this%eq_map(node, this%ndof(node))
            ELSE
                ! Node has no DOFs
                rng(1) = 0
                rng(2) = 0
            END IF
        END IF
    END FUNCTION dm_NodeRng

    !> Purpose: Perform SetNdof operation
    SUBROUTINE dm_SetNdof(this, node, ndof)
        CLASS(DofMap), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: node, ndof
        IF (node >= 1 .AND. node <= this%nNode) THEN
            this%ndof(node) = ndof
        END IF
    END SUBROUTINE dm_SetNdof

    !> Purpose: Build DofSys
    SUBROUTINE DofSys_Build(this)
        CLASS(DofSys), INTENT(INOUT) :: this
        CALL this%dm%MakeEq()
        this%stored = .TRUE.
    END SUBROUTINE DofSys_Build

    !> Purpose: Ensure DofSys
    SUBROUTINE DofSys_Ensure(this)
        CLASS(DofSys), INTENT(INOUT) :: this
        IF (.NOT. this%stored) THEN
            CALL this%dm%MakeEq()
            this%stored = .TRUE.
        END IF
    END SUBROUTINE DofSys_Ensure

    !> Purpose: Perform BuildEq operation
    SUBROUTINE ds_BuildEq(this, ndof_array)
        CLASS(DofSys), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: ndof_array(:)
        CALL this%InitFromNdof(ndof_array)
        CALL this%Build()
    END SUBROUTINE ds_BuildEq

    !> Purpose: Perform lbl operation
    FUNCTION ds_eq_of_lbl(this, lbl) RESULT(eq)
        CLASS(DofSys), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: lbl
        INTEGER(i4) :: eq, slot
        slot = this%lm%Slot(lbl)
        eq = slot
    END FUNCTION ds_eq_of_lbl

    !> Purpose: Get slot
    FUNCTION ds_eq_of_node_slot(this, node, slot) RESULT(eq)
        CLASS(DofSys), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: node, slot
        INTEGER(i4) :: eq
        eq = this%dm%Eq(node, slot)
    END FUNCTION ds_eq_of_node_slot

    !> Purpose: Initialize
    SUBROUTINE ds_Init(this, nNode, maxDpn)
        CLASS(DofSys), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: nNode, maxDpn
        CALL this%dm%Init(nNode, maxDpn)
        CALL this%lm%Init(maxDpn)
    END SUBROUTINE ds_Init

    !> Purpose: Perform InitNdof operation
    SUBROUTINE ds_InitNdof(this, ndof_array)
        CLASS(DofSys), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: ndof_array(:)
        INTEGER(i4) :: i, nNode, maxDpn
        nNode = size(ndof_array)
        maxDpn = maxval(ndof_array)
        CALL this%dm%Init(nNode, maxDpn)
        DO i = 1, nNode
            CALL this%dm%SetNdof(i, ndof_array(i))
        END DO
    END SUBROUTINE ds_InitNdof

    !> Purpose: Get range
    FUNCTION ds_node_eq_rng(this, node) RESULT(rng)
        CLASS(DofSys), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: node
        INTEGER(i4) :: rng(2)
        rng = this%dm%NodeRng(node)
    END FUNCTION ds_node_eq_rng

    !> Purpose: Bind ElemMatIntf
    SUBROUTINE ElemMatIntf_Bind(this, material_ctx, material_res, ip_state)
        CLASS(ElemMatIntf), INTENT(INOUT) :: this
        CLASS(*),            TARGET, INTENT(IN), OPTIONAL :: material_ctx
        CLASS(*),      TARGET, INTENT(IN), OPTIONAL :: material_res
        TYPE(IPState), TARGET, INTENT(IN), OPTIONAL :: ip_state
        IF (PRESENT(material_ctx)) this%material_ctx => material_ctx
        IF (PRESENT(material_res)) this%material_res => material_res
        IF (PRESENT(ip_state)) this%ip_state => ip_state
    END SUBROUTINE ElemMatIntf_Bind

    !> Purpose: Clean up ElemMatIntf
    SUBROUTINE ElemMatIntf_Clean(this)
        CLASS(ElemMatIntf), INTENT(INOUT) :: this
        NULLIFY(this%material_ctx)
        NULLIFY(this%material_res)
        NULLIFY(this%ip_state)
        this%is_init = .false.
    END SUBROUTINE ElemMatIntf_Clean

    !> Purpose: Initialize ElemMatIntf
    SUBROUTINE ElemMatIntf_Init(this, status)
        CLASS(ElemMatIntf), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        NULLIFY(this%material_ctx)
        NULLIFY(this%material_res)
        NULLIFY(this%ip_state)
        this%is_init = .true.
        IF (PRESENT(status)) status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE ElemMatIntf_Init

    !> Purpose: Perform FromIds operation for ElemSet
    SUBROUTINE ElemSet_FromIds(name, ids, set)
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4),      INTENT(IN) :: ids(:)
        TYPE(ElemSet), INTENT(OUT) :: set
        set%name = name
        IF (ALLOCATED(set%elemIds)) DEALLOCATE(set%elemIds)
        IF (size(ids) > 0) THEN
            ALLOCATE(set%elemIds(size(ids)))
            set%elemIds = ids
        END IF
    END SUBROUTINE ElemSet_FromIds

    !> Purpose: Perform Intersect operation for ElemSet
    SUBROUTINE ElemSet_Intersect(a, b, out)
        TYPE(ElemSet), INTENT(IN)  :: a, b
        TYPE(ElemSet), INTENT(OUT) :: out
        INTEGER(i4), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: nMax, nUsed, i, j
        out%name = trim(a%name)//'_INTERSECT_'//trim(b%name)
        nMax = min(size(a%elemIds), size(b%elemIds))
        ALLOCATE(tmp(nMax))
        nUsed = 0
        DO i = 1, size(a%elemIds)
            DO j = 1, size(b%elemIds)
                IF (a%elemIds(i) == b%elemIds(j)) THEN
                    nUsed = nUsed + 1
                    tmp(nUsed) = a%elemIds(i)
                    EXIT
                END IF
            END DO
        END DO
        IF (nUsed > 0) THEN

            out%elemIds(1:nUsed) = tmp(1:nUsed)
        END IF
    END SUBROUTINE ElemSet_Intersect

    !> Purpose: Perform Subtract operation for ElemSet
    SUBROUTINE ElemSet_Subtract(a, b, out)
        TYPE(ElemSet), INTENT(IN)  :: a, b
        TYPE(ElemSet), INTENT(OUT) :: out
        INTEGER(i4), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: nMax, nUsed, i, j
        LOGICAL :: found
        out%name = trim(a%name)//'_SUBTRACT_'//trim(b%name)
        nMax = size(a%elemIds)
        ALLOCATE(tmp(nMax))
        nUsed = 0
        DO i = 1, size(a%elemIds)
            found = .FALSE.
            DO j = 1, size(b%elemIds)
                IF (a%elemIds(i) == b%elemIds(j)) THEN
                    found = .TRUE.
                    EXIT
                END IF
            END DO
            IF (.NOT. found) THEN
                nUsed = nUsed + 1
                tmp(nUsed) = a%elemIds(i)
            END IF
        END DO
        IF (nUsed > 0) THEN

            out%elemIds(1:nUsed) = tmp(1:nUsed)
        END IF
    END SUBROUTINE ElemSet_Subtract

    !> Purpose: Perform Union operation for ElemSet
    SUBROUTINE ElemSet_Union(a, b, out)
        TYPE(ElemSet), INTENT(IN)  :: a, b
        TYPE(ElemSet), INTENT(OUT) :: out
        INTEGER(i4), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: nMax, nUsed, i, j
        out%name = trim(a%name)//'_UNION_'//trim(b%name)
        nMax = size(a%elemIds) + size(b%elemIds)
        ALLOCATE(tmp(nMax))
        nUsed = size(a%elemIds)
        tmp(1:nUsed) = a%elemIds
        DO i = 1, size(b%elemIds)
            DO j = 1, nUsed
                IF (tmp(j) == b%elemIds(i)) EXIT
                IF (j == nUsed) THEN
                    nUsed = nUsed + 1
                    tmp(nUsed) = b%elemIds(i)
                END IF
            END DO
        END DO
        IF (nUsed > 0) THEN

            out%elemIds(1:nUsed) = tmp(1:nUsed)
        END IF
    END SUBROUTINE ElemSet_Union

        !> Purpose: Clean up element step Ctx resources
    SUBROUTINE ElemStepCtx_Clean(this)
        CLASS(ElemStepCtx), INTENT(INOUT) :: this
        this%step_id = 0_i4
        this%increment_id = 0_i4
        this%iteration_id = 0_i4
        this%current_time = 0.0_wp
        this%time_increment = 0.0_wp
        this%is_init = .false.
    END SUBROUTINE ElemStepCtx_Clean

        !> Purpose: Initialize element step Ctx with step, increment, iteration, and time information
    SUBROUTINE ElemStepCtx_Init(this, step_id, increment_id, iteration_id, current_time, time_increment, status)
        CLASS(ElemStepCtx), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: step_id, increment_id, iteration_id
        REAL(wp), INTENT(IN), OPTIONAL :: current_time, time_increment
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        IF (PRESENT(step_id)) this%step_id = step_id
        IF (PRESENT(increment_id)) this%increment_id = increment_id
        IF (PRESENT(iteration_id)) this%iteration_id = iteration_id
        IF (PRESENT(current_time)) this%current_time = current_time
        IF (PRESENT(time_increment)) this%time_increment = time_increment
        this%is_init = .true.
        IF (PRESENT(status)) status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE ElemStepCtx_Init

    !> Purpose: Bind
    SUBROUTINE fs_bind(this, desc, nEntities, fh, status)
        CLASS(UF_FldSys), INTENT(INOUT) :: this
        TYPE(UF_FldDesc), INTENT(IN)    :: desc
        INTEGER(i4),      INTENT(IN)    :: nEntities
        TYPE(UF_FldHdl),  INTENT(INOUT) :: fh
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx
        idx = fs_find(this, desc%name)
        IF (idx == 0) THEN
            CALL fs_reg_f(this, desc, nEntities, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        ELSE
            status%status_code = MD_MODEL_STATUS_OK
        END IF
        fh%desc = desc
        fh%name = desc%name
    END SUBROUTINE fs_bind

    !> Purpose: Get
    SUBROUTINE fs_get(this, name, fh)
        CLASS(UF_FldSys), INTENT(IN)    :: this
        CHARACTER(LEN=*), INTENT(IN)    :: name
        TYPE(UF_FldHdl),  INTENT(INOUT) :: fh
        INTEGER(i4) :: idx
        idx = fs_find(this, name)
        IF (idx == 0) THEN
            fh%name = ""
        ELSE
            fh%desc = this%reg(idx)%desc
            fh%name = this%reg(idx)%name
        END IF
    END SUBROUTINE fs_get

    !> Purpose: Perform 1d operation
    SUBROUTINE fs_get_ptr_1d(this, fh, ptr, status)
        CLASS(UF_FldSys), INTENT(IN) :: this
        TYPE(UF_FldHdl), INTENT(IN) :: fh
        REAL(wp), POINTER, INTENT(OUT) :: ptr(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: idx, dim1
        CALL init_error_status(status)
        NULLIFY(ptr)
        IF (.NOT. fh%assoc()) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Field handle not associated: " // TRIM(fh%name)
            RETURN
        END IF
        idx = fs_find(this, fh%name)
        IF (idx == 0) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Field not found in registry: " // TRIM(fh%name)
            RETURN
        END IF
        dim1 = this%reg(idx)%nEntities
        IF (ALLOCATED(this%reg(idx)%desc%eshape)) THEN
            IF (SIZE(this%reg(idx)%desc%eshape) > 0) THEN
                dim1 = dim1 * PRODUCT(this%reg(idx)%desc%eshape)
            END IF
        END IF
        IF (dim1 <= 0) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid field dimension for: " // TRIM(fh%name)
            RETURN
        END IF
        CALL dp_create_dp_array1d(fh%name, dim1, ptr, status)
    END SUBROUTINE fs_get_ptr_1d

    !> Purpose: Initialize
    SUBROUTINE fs_init(this)
        CLASS(UF_FldSys), INTENT(INOUT) :: this
        TYPE(ErrorStatusType) :: status
        CALL dp_init(status)
        IF (ALLOCATED(this%reg)) DEALLOCATE(this%reg)
        ALLOCATE(this%reg(0))
    END SUBROUTINE fs_init

    !> Purpose: Find field index by name
    FUNCTION fs_find(this, name) RESULT(idx)
        CLASS(UF_FldSys), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: idx, i
        idx = 0
        IF (.NOT. ALLOCATED(this%reg)) RETURN
        DO i = 1, SIZE(this%reg)
            IF (TRIM(this%reg(i)%name) == TRIM(name)) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION fs_find

    !> Purpose: Check if field descriptor is compatible
    FUNCTION fd_compat(this) RESULT(ok)
        CLASS(UF_FldDesc), INTENT(IN) :: this
        LOGICAL :: ok
        ok = (LEN_TRIM(this%name) > 0 .AND. this%loc >= 1 .AND. this%loc <= 4)
    END FUNCTION fd_compat

    !> Purpose: Check if field handle is associated
    FUNCTION fh_assoc(this) RESULT(ok)
        CLASS(UF_FldHdl), INTENT(IN) :: this
        LOGICAL :: ok
        ok = (LEN_TRIM(this%name) > 0)
    END FUNCTION fh_assoc

    !> Purpose: Perform f operation
    SUBROUTINE fs_reg_f(this, desc, nEntities, status)
        CLASS(UF_FldSys), INTENT(INOUT) :: this
        TYPE(UF_FldDesc), INTENT(IN)    :: desc
        INTEGER(i4),      INTENT(IN)    :: nEntities
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: n, i, idx
        TYPE(UF_FldRegEnt), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: dims(4), dType
        CALL init_error_status(status)
        IF (LEN_TRIM(desc%name) == 0) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Field name cannot be empty"
            RETURN
        END IF
        IF (nEntities <= 0) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Number of entities must be positive"
            RETURN
        END IF
        idx = fs_find(this, desc%name)
        IF (idx > 0) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Field already registered: " // TRIM(desc%name)
            RETURN
        END IF
        SELECT CASE (desc%bas)
        CASE (MD_MODEL_UF_FLD_REAL8)
            dType = MD_MODEL_DATA_TYPE_DP
        CASE (MD_MODEL_UF_FLD_INT32)
            dType = MD_MODEL_DATA_TYPE_INT
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Unsupported field base type"
            RETURN
        END SELECT
        dims = 0
        IF (ALLOCATED(desc%eshape)) THEN
            DO i = 1, SIZE(desc%eshape)
                dims(i) = desc%eshape(i)
            END DO
            dims(SIZE(desc%eshape)+1) = nEntities
        ELSE
            dims(1) = nEntities
        END IF
        CALL dp_register_struct_array(desc%name, dims, dType, "", status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        n = SIZE(this%reg)
        ALLOCATE(tmp(n+1))
        IF (n > 0) tmp(1:n) = this%reg(1:n)
        tmp(n+1)%desc = desc
        tmp(n+1)%name = desc%name
        tmp(n+1)%nEntities = nEntities
        CALL move_alloc_f90(tmp, this%reg)
    END SUBROUTINE fs_reg_f

    !> Purpose: Execute GetCategory
    FUNCTION GetCategory(self) RESULT(cat)
        CLASS(CoreBase), INTENT(IN) :: self
        INTEGER(i4) :: cat
        cat = self%algo_category
    END FUNCTION GetCategory

    !> Purpose: Execute HashString
    FUNCTION HashString(str) RESULT(hash)
        CHARACTER(LEN=*), INTENT(IN) :: str
        INTEGER(i4) :: hash
        INTEGER(i4) :: i, c
        hash = 5381_i4
        DO i = 1, LEN_TRIM(str)
            c = ICHAR(str(i:i))
            hash = ISHFT(hash, 5) + hash + c
        END DO
        hash = IAND(hash, HUGE(0_i4))
        IF (hash < 0) hash = -hash
        hash = MOD(hash, MD_MODEL_HASH_TABLE_SIZE) + 1_i4
    END FUNCTION HashString

    !> Purpose: Perform EnergyBuckets operation
    SUBROUTINE Init_EnergyBuckets(nBuckets, buckets)
        INTEGER(i4), INTENT(IN) :: nBuckets
        REAL(wp), INTENT(OUT) :: buckets(:)
        INTEGER(i4) :: i
        DO i = 1, min(nBuckets, size(buckets))
            buckets(i) = 0.0_wp
        END DO
    END SUBROUTINE Init_EnergyBuckets

    !> Purpose: Ensure
    SUBROUTINE IPState_Ensure(this)
        CLASS(IPState), INTENT(INOUT) :: this
    END SUBROUTINE IPState_Ensure

    !> Purpose: Initialize
    SUBROUTINE IPState_Init(this, ipId, elemId, materialId, numStateVars, status)
        CLASS(IPState), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: ipId, elemId, materialId, numStateVars
        TYPE(ErrorStatusType) :: st
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        IF (PRESENT(ipId)) this%ipId = ipId
        IF (PRESENT(elemId)) this%cfg%id = elemId
        IF (PRESENT(materialId)) this%material_id = materialId
        IF (PRESENT(numStateVars) .AND. numStateVars > 0) THEN
            this%numStateVars = numStateVars
            CALL init_error_status(st)
            IF (this%stateVars_id >= 0) CALL UF_Mem_FreeReal1D(this%stateVars_id, st)
            IF (this%stateVarsOld_id >= 0) CALL UF_Mem_FreeReal1D(this%stateVarsOld_id, st)
            CALL UF_Mem_AllocReal1D(IF_MEM_DOMAIN_MAT, 0_i4, numStateVars, &
                'IPState_stateVars', this%stateVars, this%stateVars_id, st)
            IF (st%status_code /= MD_MODEL_STATUS_OK) THEN
                IF (PRESENT(status)) status = st
                RETURN
            END IF
            CALL UF_Mem_AllocReal1D(IF_MEM_DOMAIN_MAT, 0_i4, numStateVars, &
                'IPState_stateVarsOld', this%stateVarsOld, this%stateVarsOld_id, st)
            IF (st%status_code /= MD_MODEL_STATUS_OK) THEN
                CALL UF_Mem_FreeReal1D(this%stateVars_id, st)
                this%stateVars_id = -1
                NULLIFY(this%stateVars)
                IF (PRESENT(status)) status = st
                RETURN
            END IF
            IF (.NOT. ALLOCATED(this%isActive)) ALLOCATE(this%isActive(numStateVars))
            IF (.NOT. ALLOCATED(this%stateNames)) ALLOCATE(this%stateNames(numStateVars))
            this%stateVars = 0.0_wp
            this%stateVarsOld = 0.0_wp
            this%isActive = .true.
            this%stateNames = ""
        END IF
        this%sigma = 0.0_wp
        this%strain = 0.0_wp
        this%plasticStrain = 0.0_wp
        this%equivalentplast = 0.0_wp
        this%temperature = 0.0_wp
        this%jacobian = 1.0_wp
        this%isInitialized = .true.
        IF (PRESENT(status)) status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE IPState_Init

        !> Purpose: Get a specific Mat property value by index
    SUBROUTINE IPState_RegLayout(this)
        CLASS(IPState), INTENT(IN) :: this
    END SUBROUTINE IPState_RegLayout

    !> Purpose: Reset
    SUBROUTINE IPState_Reset(this)
        CLASS(IPState), INTENT(INOUT) :: this
        this%sigma = 0.0_wp
        this%strain = 0.0_wp
        this%plasticStrain = 0.0_wp
        this%equivalentplast = 0.0_wp
        this%temperature = 0.0_wp
        this%jacobian = 1.0_wp
        IF (ASSOCIATED(this%stateVars)) this%stateVars = 0.0_wp
    END SUBROUTINE IPState_Reset

    !> Purpose: Perform Restore operation
    SUBROUTINE IPState_Restore(this)
        CLASS(IPState), INTENT(INOUT) :: this
        IF (ASSOCIATED(this%stateVars) .AND. ASSOCIATED(this%stateVarsOld)) this%stateVars = this%stateVarsOld
    END SUBROUTINE IPState_Restore

    !> Purpose: Perform Save operation
    SUBROUTINE IPState_Save(this)
        CLASS(IPState), INTENT(INOUT) :: this
        CALL this%Update()
    END SUBROUTINE IPState_Save

    !> Purpose: Update
    SUBROUTINE IPState_Update(this)
        CLASS(IPState), INTENT(INOUT) :: this
        IF (ASSOCIATED(this%stateVars) .AND. ASSOCIATED(this%stateVarsOld)) this%stateVarsOld = this%stateVars
    END SUBROUTINE IPState_Update

    !> Purpose: Set
    FUNCTION Is_Elem_In_Set(set, elemId) RESULT(is_in)
        TYPE(ElemSet), INTENT(IN) :: set
        INTEGER(i4), INTENT(IN) :: elemId
        LOGICAL :: is_in
        INTEGER(i4) :: i
        is_in = .FALSE.
        DO i = 1, size(set%elemIds)
            IF (set%elemIds(i) == elemId) THEN
                is_in = .TRUE.
                RETURN
            END IF
        END DO
    END FUNCTION Is_Elem_In_Set

    !> Purpose: Set
    FUNCTION Is_Node_In_Set(set, id) RESULT(is_in)
        TYPE(NodeSet), INTENT(IN) :: set
        INTEGER(i4), INTENT(IN) :: id
        LOGICAL :: is_in
        INTEGER(i4) :: i
        is_in = .FALSE.
        DO i = 1, size(set%nodeIds)
            IF (set%nodeIds(i) == id) THEN
                is_in = .TRUE.
                RETURN
            END IF
        END DO
    END FUNCTION Is_Node_In_Set

    !> Purpose: Execute IsAlgo
    FUNCTION IsAlgo(self) RESULT(res)
        CLASS(CoreBase), INTENT(IN) :: self
        LOGICAL :: res
        res = (self%algo_category == MD_MODEL_CAT_ALGO)
    END FUNCTION IsAlgo

    !> Purpose: Execute IsCtx
    FUNCTION IsCtx(self) RESULT(res)
        CLASS(CoreBase), INTENT(IN) :: self
        LOGICAL :: res
        res = (self%algo_category == MD_MODEL_CAT_CTX)
    END FUNCTION IsCtx

    !> Purpose: Execute IsDesc
    FUNCTION IsDesc(self) RESULT(res)
        CLASS(CoreBase), INTENT(IN) :: self
        LOGICAL :: res
        res = (self%algo_category == MD_MODEL_CAT_DESC)
    END FUNCTION IsDesc

    !> Purpose: Execute IsState
    FUNCTION IsState(self) RESULT(res)
        CLASS(CoreBase), INTENT(IN) :: self
        LOGICAL :: res
        res = (self%algo_category == MD_MODEL_CAT_STATE)
    END FUNCTION IsState

    !> Purpose: Free
    SUBROUTINE lm_Free(this)
        CLASS(DofLabMap), INTENT(INOUT) :: this
        IF (ALLOCATED(this%lbl)) DEALLOCATE(this%lbl)
        IF (ALLOCATED(this%slot_arr)) DEALLOCATE(this%slot_arr)
        this%n_lbl = 0
    END SUBROUTINE lm_Free

    !> Purpose: Initialize
    SUBROUTINE lm_Init(this, n_lbl)
        CLASS(DofLabMap), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: n_lbl
        this%n_lbl = n_lbl
        ALLOCATE(this%lbl(n_lbl))
        ALLOCATE(this%slot_arr(n_lbl))
        this%lbl = 0
        this%slot_arr = 0
    END SUBROUTINE lm_Init

    !> Purpose: Get slot
    FUNCTION lm_Slot(this, lbl) RESULT(slot)
        CLASS(DofLabMap), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: lbl
        INTEGER(i4) :: slot, i
        slot = 0
        DO i = 1, this%n_lbl
            IF (this%lbl(i) == lbl) THEN
                slot = this%slot_arr(i)
                RETURN
            END IF
        END DO
    END FUNCTION lm_Slot

    !> Purpose: Perform BuildDof operation
    SUBROUTINE ModelSys_BuildDof(this)
        CLASS(ModelSys), INTENT(INOUT) :: this
        CALL this%dof_system%Build()
    END SUBROUTINE ModelSys_BuildDof

    !> Purpose: Perform SetupUIF operation
    ! Note: Attach(dm) requires dm to have TARGET. Fortran forbids TARGET on type
    ! components. Caller with TARGET ModelSys may call uf_view%Attach(dof_system%dm)
    ! directly. Here we pass null; uf_view%dm stays unassociated.
    SUBROUTINE ModelSys_SetupUIF(this)
        CLASS(ModelSys), INTENT(INOUT) :: this
        TYPE(DofMap), POINTER :: dm_ptr
        NULLIFY(dm_ptr)
        CALL this%uf_view%Attach(dm_ptr)
    END SUBROUTINE ModelSys_SetupUIF

    !> Purpose: Perform f90 operation
    SUBROUTINE move_alloc_f90(src, dst)
        TYPE(UF_FldRegEnt), ALLOCATABLE, INTENT(INOUT) :: src(:)
        TYPE(UF_FldRegEnt), ALLOCATABLE, INTENT(OUT) :: dst(:)
        CALL MOVE_ALLOC(src, dst)
    END SUBROUTINE move_alloc_f90

    !> Purpose: Perform uf operation
    SUBROUTINE move_alloc_f90_uf(src, dst)
        TYPE(UF_UFField), ALLOCATABLE, INTENT(INOUT) :: src(:)
        TYPE(UF_UFField), ALLOCATABLE, INTENT(OUT) :: dst(:)
        CALL MOVE_ALLOC(src, dst)
    END SUBROUTINE move_alloc_f90_uf

    !> Purpose: Initialize
    SUBROUTINE ms_init(this)
        CLASS(ModelSys), INTENT(INOUT) :: this
        this%is_init = .FALSE.
    END SUBROUTINE ms_init

    !> Purpose: Perform FromIds operation for NodeSet
    SUBROUTINE NodeSet_FromIds(name, ids, set)
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4),      INTENT(IN) :: ids(:)
        TYPE(NodeSet), INTENT(OUT) :: set
        set%name = name
        IF (ALLOCATED(set%nodeIds)) DEALLOCATE(set%nodeIds)
        IF (size(ids) > 0) THEN
            ALLOCATE(set%nodeIds(size(ids)))
            set%nodeIds = ids
        END IF
    END SUBROUTINE NodeSet_FromIds

    !> Purpose: Perform Intersect operation for NodeSet
    SUBROUTINE NodeSet_Intersect(a, b, out)
        TYPE(NodeSet), INTENT(IN)  :: a, b
        TYPE(NodeSet), INTENT(OUT) :: out
        INTEGER(i4), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: nMax, nUsed, i, j
        out%name = trim(a%name)//'_INTERSECT_'//trim(b%name)
        nMax = min(size(a%nodeIds), size(b%nodeIds))
        ALLOCATE(tmp(nMax))
        nUsed = 0
        DO i = 1, size(a%nodeIds)
            DO j = 1, size(b%nodeIds)
                IF (a%nodeIds(i) == b%nodeIds(j)) THEN
                    nUsed = nUsed + 1
                    tmp(nUsed) = a%nodeIds(i)
                    EXIT
                END IF
            END DO
        END DO
        IF (nUsed > 0) THEN
            ALLOCATE(out%nodeIds(nUsed))
            out%nodeIds(1:nUsed) = tmp(1:nUsed)
        END IF
    END SUBROUTINE NodeSet_Intersect

    !> Purpose: Perform Subtract operation for NodeSet
    SUBROUTINE NodeSet_Subtract(a, b, out)
        TYPE(NodeSet), INTENT(IN)  :: a, b
        TYPE(NodeSet), INTENT(OUT) :: out
        INTEGER(i4), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: nMax, nUsed, i, j
        LOGICAL :: found
        out%name = trim(a%name)//'_SUBTRACT_'//trim(b%name)
        nMax = size(a%nodeIds)
        ALLOCATE(tmp(nMax))
        nUsed = 0
        DO i = 1, size(a%nodeIds)
            found = .FALSE.
            DO j = 1, size(b%nodeIds)
                IF (a%nodeIds(i) == b%nodeIds(j)) THEN
                    found = .TRUE.
                    EXIT
                END IF
            END DO
            IF (.NOT. found) THEN
                nUsed = nUsed + 1
                tmp(nUsed) = a%nodeIds(i)
            END IF
        END DO
        IF (nUsed > 0) THEN
            ALLOCATE(out%nodeIds(nUsed))
            out%nodeIds(1:nUsed) = tmp(1:nUsed)
        END IF
    END SUBROUTINE NodeSet_Subtract

    !> Purpose: Perform Union operation for NodeSet
    SUBROUTINE NodeSet_Union(a, b, out)
        TYPE(NodeSet), INTENT(IN)  :: a, b
        TYPE(NodeSet), INTENT(OUT) :: out
        INTEGER(i4), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: nMax, nUsed, i, j
        out%name = trim(a%name)//'_UNION_'//trim(b%name)
        nMax = size(a%nodeIds) + size(b%nodeIds)
        ALLOCATE(tmp(nMax))
        nUsed = size(a%nodeIds)
        tmp(1:nUsed) = a%nodeIds
        DO i = 1, size(b%nodeIds)
            DO j = 1, nUsed
                IF (tmp(j) == b%nodeIds(i)) EXIT
                IF (j == nUsed) THEN
                    nUsed = nUsed + 1
                    tmp(nUsed) = b%nodeIds(i)
                END IF
            END DO
        END DO
        IF (nUsed > 0) THEN
            ALLOCATE(out%nodeIds(nUsed))
            out%nodeIds(1:nUsed) = tmp(1:nUsed)
        END IF
    END SUBROUTINE NodeSet_Union

    !> Purpose: Perform Bound operation
    FUNCTION Obj_Bound(self) RESULT(bound)
        CLASS(ObjBase), INTENT(IN) :: self
        LOGICAL :: bound
        bound = self%obj_bound_
    END FUNCTION Obj_Bound

    !> Purpose: Destroy and clean up
    SUBROUTINE Obj_Destroy(self, status)
        CLASS(ObjBase), INTENT(INOUT) :: self
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        self%obj_id_ = 0
        self%obj_name_ = ""
        self%obj_valid_ = .FALSE.
        self%obj_bound_ = .FALSE.
    END SUBROUTINE Obj_Destroy

    !> Purpose: Perform GetInfo operation
    SUBROUTINE Obj_GetInfo(self, name, id, valid, status)
        CLASS(ObjBase), INTENT(IN) :: self
        CHARACTER(LEN=*), INTENT(OUT) :: name
        INTEGER(i4), INTENT(OUT) :: id
        LOGICAL, INTENT(OUT) :: valid
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        name = TRIM(self%obj_name_)
        id = self%obj_id_
        valid = self%obj_valid_
    END SUBROUTINE Obj_GetInfo

    !> Purpose: Perform Id operation
    FUNCTION Obj_Id(self) RESULT(id)
        CLASS(ObjBase), INTENT(IN) :: self
        INTEGER(i4) :: id
        id = self%obj_id_
    END FUNCTION Obj_Id

    !> Purpose: Initialize
    SUBROUTINE Obj_Init(self, name, id, status)
        CLASS(ObjBase), INTENT(INOUT) :: self
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: id
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        IF (PRESENT(status)) CALL init_error_status(status)
        self%obj_id_ = id
        self%obj_name_ = TRIM(name)
        self%obj_valid_ = .TRUE.
        self%obj_bound_ = .FALSE.
    END SUBROUTINE Obj_Init

    !> Purpose: Perform Invalidate operation
    SUBROUTINE Obj_Invalidate(self)
        CLASS(ObjBase), INTENT(INOUT) :: self
        self%obj_valid_ = .false.
        self%obj_bound_ = .false.
    END SUBROUTINE Obj_Invalidate

    !> Purpose: Perform Name operation
    FUNCTION Obj_Name(self) RESULT(name)
        CLASS(ObjBase), INTENT(IN) :: self
        CHARACTER(LEN=64) :: name
        name = self%obj_name_
    END FUNCTION Obj_Name

    !> Purpose: Perform SetId operation
    SUBROUTINE Obj_SetId(self, id)
        CLASS(ObjBase), INTENT(INOUT) :: self
        INTEGER(i4), INTENT(IN) :: id
        self%obj_id_ = id
    END SUBROUTINE Obj_SetId

    !> Purpose: Perform SetName operation
    SUBROUTINE Obj_SetName(self, name)
        CLASS(ObjBase), INTENT(INOUT) :: self
        CHARACTER(LEN=*), INTENT(IN) :: name
        self%obj_name_ = name
    END SUBROUTINE Obj_SetName

    !> Purpose: Check validity
    FUNCTION Obj_Valid(self) RESULT(valid)
        CLASS(ObjBase), INTENT(IN) :: self
        LOGICAL :: valid
        valid = self%obj_valid_
    END FUNCTION Obj_Valid

    !> Purpose: Perform BeginArray operation for Serial
    SUBROUTINE Serial_BeginArray(this, name, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            IF (PRESENT(name)) THEN
                CALL this%WriteString(name, status)
            ELSE
                CALL this%WriteInt(0_i4, status)
            END IF
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%WriteComma(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%WriteIndent(status)
            IF (PRESENT(name) .AND. LEN_TRIM(name) > 0) THEN
                WRITE(this%json_file%unit, '(A)', iostat=status%status_code) '"' // TRIM(name) // '": ['
            ELSE
                WRITE(this%json_file%unit, '(A)', iostat=status%status_code) '['
            END IF
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%message = "Failed to write array start to JSON file"
                RETURN
            END IF
            this%indent_level = this%indent_level + 1_i4
            this%first_in_array = .TRUE.
            this%first_in_object = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_BeginArray

    !> Purpose: Perform BeginObject operation for Serial
    SUBROUTINE Serial_BeginObject(this, name, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            IF (PRESENT(name)) THEN
                CALL this%WriteString(name, status)
            ELSE
                CALL this%WriteInt(0_i4, status)
            END IF
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%WriteComma(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%WriteIndent(status)
            IF (PRESENT(name) .AND. LEN_TRIM(name) > 0) THEN
                WRITE(this%json_file%unit, '(A)', iostat=status%status_code) '"' // TRIM(name) // '": {'
            ELSE
                WRITE(this%json_file%unit, '(A)', iostat=status%status_code) '{'
            END IF
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%message = "Failed to write object start to JSON file"
                RETURN
            END IF
            this%indent_level = this%indent_level + 1_i4
            this%first_in_object = .TRUE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_BeginObject

    !> Purpose: Close Serial
    SUBROUTINE Serial_Close(this, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. this%file_open) THEN
            status%status_code = MD_MODEL_STATUS_OK
            RETURN
        END IF
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%rw_serializer%Close(status)
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%json_file%Close(status)
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
        this%file_open = .FALSE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Serial_Close

    !> Purpose: Destroy and clean up Serial
    SUBROUTINE Serial_Destroy(this, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: fmt
        CALL init_error_status(status)
        fmt = this%format
        IF (this%file_open) CALL this%Close(status)
        IF (fmt == MD_MODEL_SERIAL_FORMAT_B) CALL this%rw_serializer%Destroy()
        this%is_init = .FALSE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Serial_Destroy

    !> Purpose: Perform EndArray operation for Serial
    SUBROUTINE Serial_EndArray(this, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%WriteInt(-2_i4, status)
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            this%indent_level = this%indent_level - 1_i4
            WRITE(this%json_file%unit, '(A)', iostat=status%status_code) ''
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(A)', iostat=status%status_code) ']'
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%message = "Failed to write array end to JSON file"
                RETURN
            END IF
            this%first_in_array = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_EndArray

    !> Purpose: Perform EndObject operation for Serial
    SUBROUTINE Serial_EndObject(this, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%WriteInt(-1_i4, status)
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            this%indent_level = this%indent_level - 1_i4
            WRITE(this%json_file%unit, '(A)', iostat=status%status_code) ''
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(A)', iostat=status%status_code) '}'
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%status_code = MD_MODEL_STATUS_IO_ERROR
                status%message = "Failed to write object end to JSON file"
                RETURN
            END IF
            this%first_in_object = .FALSE.
            this%first_in_array = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_EndObject

    !> Purpose: Initialize Serial
    SUBROUTINE Serial_Init(this, format, status)
        CLASS(TreeSerializer), INTENT(OUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: format
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%format = MD_MODEL_SERIAL_FORMAT_B
        IF (PRESENT(format)) this%format = format
        this%is_init = .TRUE.
        this%file_open = .FALSE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Serial_Init

    !> Purpose: Open Serial
    SUBROUTINE Serial_Open(this, file_path, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: file_path
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            CALL this%Init(status=status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        END IF
        this%file_path = TRIM(file_path)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%rw_serializer%Init(file_path, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%rw_serializer%Open(status)
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%json_file%Init(file_path, MD_MODEL_FILE_MODE_WRITE)
            CALL this%json_file%Open(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            this%indent_level = 0_i4
            this%first_in_object = .TRUE.
            this%first_in_array = .TRUE.
        CASE (MD_MODEL_SERIAL_FORMAT_X)
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "XML format not yet implemented"
            RETURN
        CASE (MD_MODEL_SERIAL_FORMAT_H)
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "HDF5 format not yet implemented"
            RETURN
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Unknown serialization format"
            RETURN
        END SELECT
        IF (status%status_code == MD_MODEL_STATUS_OK) this%file_open = .TRUE.
    END SUBROUTINE Serial_Open

    !> Purpose: Perform WriteArrayInt operation for Serial
    SUBROUTINE Serial_WriteArrayInt(this, array, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: array(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, n
        CALL init_error_status(status)
        n = SIZE(array)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%WriteInt(n, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            DO i = 1, n
                CALL this%WriteInt(array(i), status)
                IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            END DO
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%WriteComma(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) '['
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%message = "Failed to write array start to JSON file"
                RETURN
            END IF
            DO i = 1, n
                IF (i > 1) WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) ', '
                WRITE(this%json_file%unit, '(I0)', advance='no', iostat=status%status_code) array(i)
                IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                    status%message = "Failed to write array element to JSON file"
                    RETURN
                END IF
            END DO
            WRITE(this%json_file%unit, '(A)', iostat=status%status_code) ''
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(A)', iostat=status%status_code) ']'
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%status_code = MD_MODEL_STATUS_IO_ERROR
                status%message = "Failed to write array end to JSON file"
                RETURN
            END IF
            this%first_in_array = .FALSE.
            this%first_in_object = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_WriteArrayInt

    !> Purpose: Perform WriteArrayReal operation for Serial
    SUBROUTINE Serial_WriteArrayReal(this, array, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: array(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, n
        CALL init_error_status(status)
        n = SIZE(array)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%WriteInt(n, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            DO i = 1, n
                CALL this%WriteReal(array(i), status)
                IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            END DO
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%WriteComma(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) '['
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%message = "Failed to write array start to JSON file"
                RETURN
            END IF
            DO i = 1, n
                IF (i > 1) WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) ', '
                WRITE(this%json_file%unit, '(ES25.16)', advance='no', iostat=status%status_code) array(i)
                IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                    status%message = "Failed to write array element to JSON file"
                    RETURN
                END IF
            END DO
            WRITE(this%json_file%unit, '(A)', iostat=status%status_code) ''
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(A)', iostat=status%status_code) ']'
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%status_code = MD_MODEL_STATUS_IO_ERROR
                status%message = "Failed to write array end to JSON file"
                RETURN
            END IF
            this%first_in_array = .FALSE.
            this%first_in_object = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_WriteArrayReal

    !> Purpose: Perform WriteBool operation for Serial
    SUBROUTINE Serial_WriteBool(this, value, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        LOGICAL, INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: int_val
        CALL init_error_status(status)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            int_val = 0_i4
            IF (value) int_val = 1_i4
            CALL this%WriteInt(int_val, status)
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%WriteComma(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%WriteIndent(status)
            IF (value) THEN
                WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) 'true'
            ELSE
                WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) 'false'
            END IF
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%status_code = MD_MODEL_STATUS_IO_ERROR
                status%message = "Failed to write boolean to JSON file"
                RETURN
            END IF
            this%first_in_object = .FALSE.
            this%first_in_array = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_WriteBool

    !> Purpose: Perform WriteComma operation for Serial
    SUBROUTINE Serial_WriteComma(this, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (this%format == MD_MODEL_SERIAL_FORMAT_J) THEN
            IF (.NOT. this%first_in_object .AND. .NOT. this%first_in_array) THEN
                WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) ','
                IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                    status%status_code = MD_MODEL_STATUS_IO_ERROR
                    status%message = "Failed to write comma to JSON file"
                    RETURN
                END IF
            END IF
        END IF
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Serial_WriteComma

    !> Purpose: Perform WriteIndent operation for Serial
    SUBROUTINE Serial_WriteIndent(this, status)
        CLASS(TreeSerializer), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        CALL init_error_status(status)
        IF (this%format == MD_MODEL_SERIAL_FORMAT_J) THEN
            DO i = 1, this%indent_level
                WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) '  '
                IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                    status%message = "Failed to write indent to JSON file"
                    RETURN
                END IF
            END DO
        END IF
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Serial_WriteIndent

    !> Purpose: Perform WriteInt operation for Serial
    SUBROUTINE Serial_WriteInt(this, value, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. this%file_open) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL RW_Serialize(this%rw_serializer, value, status)
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%WriteComma(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(I0)', advance='no', iostat=status%status_code) value
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%status_code = MD_MODEL_STATUS_IO_ERROR
                status%message = "Failed to write integer to JSON file"
                RETURN
            END IF
            this%first_in_object = .FALSE.
            this%first_in_array = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_WriteInt

    !> Purpose: Perform WriteReal operation for Serial
    SUBROUTINE Serial_WriteReal(this, value, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        REAL(wp), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. this%file_open) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL RW_Serialize(this%rw_serializer, value, status)
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%WriteComma(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(ES25.16)', advance='no', iostat=status%status_code) value
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%status_code = MD_MODEL_STATUS_IO_ERROR
                status%message = "Failed to write real to JSON file"
                RETURN
            END IF
            this%first_in_object = .FALSE.
            this%first_in_array = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_WriteReal

    !> Purpose: Perform WriteString operation for Serial
    SUBROUTINE Serial_WriteString(this, value, status)
        CLASS(TreeSerializer), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: len_str
        CALL init_error_status(status)
        IF (.NOT. this%file_open) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "File not open"
            RETURN
        END IF
        len_str = LEN_TRIM(value)
        SELECT CASE (this%format)
        CASE (MD_MODEL_SERIAL_FORMAT_B)
            CALL this%WriteInt(len_str, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            IF (len_str > 0) CALL RW_Serialize(this%rw_serializer, value(1:len_str), status)
        CASE (MD_MODEL_SERIAL_FORMAT_J)
            CALL this%WriteComma(status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            CALL this%WriteIndent(status)
            WRITE(this%json_file%unit, '(A)', advance='no', iostat=status%status_code) '"' // TRIM(value) // '"'
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                status%status_code = MD_MODEL_STATUS_IO_ERROR
                status%message = "Failed to write string to JSON file"
                RETURN
            END IF
            this%first_in_object = .FALSE.
            this%first_in_array = .FALSE.
            status%status_code = MD_MODEL_STATUS_OK
        CASE DEFAULT
            status%status_code = MD_MODEL_STATUS_INVALID
            RETURN
        END SELECT
    END SUBROUTINE Serial_WriteString

    !> Purpose: Execute SetTypeName
    SUBROUTINE SetTypeName(self, name)
        CLASS(CoreBase), INTENT(INOUT) :: self
        CHARACTER(LEN=*), INTENT(IN) :: name
        self%algo_type_name = name
    END SUBROUTINE SetTypeName

    !> Purpose: Execute SetVarName
    SUBROUTINE SetVarName(self, name)
        CLASS(CoreBase), INTENT(INOUT) :: self
        CHARACTER(LEN=*), INTENT(IN) :: name
        self%algo_var_name = name
    END SUBROUTINE SetVarName

    !> Purpose: Execute SortInt
    SUBROUTINE SortInt(a, n)
        INTEGER(i4), INTENT(INOUT) :: a(:)
        INTEGER(i4), INTENT(IN)    :: n
        INTEGER(i4) :: i, j, key
        DO i = 2, n
            key = a(i)
            j = i - 1
            DO WHILE (j >= 1 .AND. a(j) > key)
                a(j+1) = a(j)
                j = j - 1
            END DO
            a(j+1) = key
        END DO
    END SUBROUTINE SortInt

    !> Purpose: Clear StateBase
    SUBROUTINE StateBase_Clear(this)
        CLASS(StateBase), INTENT(INOUT) :: this
        this%is_init = .FALSE.
    END SUBROUTINE StateBase_Clear

    !> Purpose: Deserialize StateBase
    SUBROUTINE StateBase_Deserialize(this, deserializer, status)
        CLASS(StateBase), INTENT(INOUT) :: this
        class(TreeDeserializer), intent(inout) :: deserializer
        type(ErrorStatusType), intent(out), optional :: status
        type(ErrorStatusType) :: local_status
        character(len=256) :: obj_name
        
        call init_error_status(local_status)
        
        obj_name = deserializer%BeginObject(local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        this%is_init = deserializer%ReadBool(local_status)
        this%algo_category = deserializer%ReadInt(local_status)
        this%algo_type_name = deserializer%ReadString(local_status)
        this%algo_var_name = deserializer%ReadString(local_status)
        
        call deserializer%EndObject(local_status)
        if (present(status)) status = local_status
    END SUBROUTINE StateBase_Deserialize

    !> Purpose: Destroy and clean up StateBase
    SUBROUTINE StateBase_Destroy(this)
        CLASS(StateBase), INTENT(INOUT) :: this
        this%is_init = .FALSE.
        this%algo_type_name = ""
        this%algo_var_name = ""
    END SUBROUTINE StateBase_Destroy

    !> Purpose: Perform GetCategory operation for StateBase
    FUNCTION StateBase_GetCategory(this) RESULT(cat)
        CLASS(StateBase), INTENT(IN) :: this
        INTEGER(i4) :: cat
        cat = this%algo_category
    END FUNCTION StateBase_GetCategory

    !> Purpose: Perform GetStatus operation for StateBase
    FUNCTION StateBase_GetStatus(this) RESULT(status)
        CLASS(StateBase), INTENT(IN) :: this
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        IF (.NOT. this%is_init) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "StateBase not initialized"
        END IF
    END FUNCTION StateBase_GetStatus

    !> Purpose: Perform GetTypeName operation for StateBase
    FUNCTION StateBase_GetTypeName(this) RESULT(name)
        CLASS(StateBase), INTENT(IN) :: this
        CHARACTER(LEN=64) :: name
        name = this%algo_type_name
    END FUNCTION StateBase_GetTypeName

    !> Purpose: Perform GetVarName operation for StateBase
    FUNCTION StateBase_GetVarName(this) RESULT(name)
        CLASS(StateBase), INTENT(IN) :: this
        CHARACTER(LEN=64) :: name
        name = this%algo_var_name
    END FUNCTION StateBase_GetVarName

    !> Purpose: Initialize StateBase
    SUBROUTINE StateBase_Init(this, n)
        CLASS(StateBase), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: n
        this%is_init = .TRUE.
    END SUBROUTINE StateBase_Init

    !> Purpose: Perform IsState operation for StateBase
    FUNCTION StateBase_IsState(this) RESULT(res)
        CLASS(StateBase), INTENT(IN) :: this
        LOGICAL :: res
        res = (this%algo_category == MD_MODEL_CAT_STATE)
    END FUNCTION StateBase_IsState

    !> Purpose: Serialize StateBase
    SUBROUTINE StateBase_Serialize(this, serializer, status)
        CLASS(StateBase), INTENT(IN) :: this
        class(TreeSerializer), intent(inout) :: serializer
        type(ErrorStatusType), intent(out), optional :: status
        type(ErrorStatusType) :: local_status
        
        call init_error_status(local_status)
        
        call serializer%BeginObject("StateBase", local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteBool(this%is_init, local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteInt(this%algo_category, local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteString(trim(this%algo_type_name), local_status)
        if (local_status%status_code /= MD_MODEL_STATUS_OK) then
          if (present(status)) status = local_status
          return
        end if
        
        call serializer%WriteString(trim(this%algo_var_name), local_status)
        
        call serializer%EndObject(local_status)
        if (present(status)) status = local_status
    END SUBROUTINE StateBase_Serialize

    !> Purpose: Perform SetTypeName operation for StateBase
    SUBROUTINE StateBase_SetTypeName(this, name)
        CLASS(StateBase), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        this%algo_type_name = name
    END SUBROUTINE StateBase_SetTypeName

    !> Purpose: Perform SetVarName operation for StateBase
    SUBROUTINE StateBase_SetVarName(this, name)
        CLASS(StateBase), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        this%algo_var_name = name
    END SUBROUTINE StateBase_SetVarName

    !> Purpose: Execute TrimAll
    FUNCTION TrimAll(str) RESULT(out)
        CHARACTER(LEN=*), INTENT(IN) :: str
        CHARACTER(LEN=:), ALLOCATABLE :: out
        out = trim(adjustl(str))
    END FUNCTION TrimAll

    !> Purpose: Execute TypeName
    FUNCTION TypeName(self) RESULT(name)
        CLASS(CoreBase), INTENT(IN) :: self
        CHARACTER(LEN=64) :: name
        name = self%algo_type_name
    END FUNCTION TypeName

    !> Purpose: Reset UF_UFCore
    SUBROUTINE uf_reset(this)
        CLASS(UF_UFCore), INTENT(INOUT) :: this
        IF (ALLOCATED(this%fields)) DEALLOCATE(this%fields)
        this%nFields = 0_i4
        this%nEq = 0_i4
    END SUBROUTINE uf_reset

    !> Purpose: Perform field operation
    SUBROUTINE uf_add_field(this, fieldType, name, nDof)
        CLASS(UF_UFCore), INTENT(INOUT) :: this
        INTEGER(i4),      INTENT(IN)    :: fieldType
        CHARACTER(LEN=*), INTENT(IN)    :: name
        INTEGER(i4),      INTENT(IN)    :: nDof
        INTEGER(i4) :: n, eq0
        TYPE(UF_UFField), ALLOCATABLE :: tmp(:)
        IF (nDof <= 0_i4) RETURN
        n = this%nFields
        IF (ALLOCATED(this%fields)) THEN
            ALLOCATE(tmp(n+1))
            IF (n > 0) tmp(1:n) = this%fields(1:n)
            CALL move_alloc_f90_uf(tmp, this%fields)
        ELSE
            ALLOCATE(this%fields(1))
        END IF
        IF (n == 0) THEN
            eq0 = 1_i4
        ELSE
            eq0 = this%fields(n)%eqEnd + 1_i4
        END IF
        this%fields(n+1)%fieldType = fieldType
        this%fields(n+1)%nDof      = nDof
        this%fields(n+1)%eqStart   = eq0
        this%fields(n+1)%eqEnd     = eq0 + nDof - 1_i4
        this%fields(n+1)%desc%loc  = MD_MODEL_UF_FLD_AT_NODE
        this%fields(n+1)%desc%bas  = MD_MODEL_UF_FLD_REAL8
        this%fields(n+1)%desc%rank = 1
        IF (ALLOCATED(this%fields(n+1)%desc%name))   DEALLOCATE(this%fields(n+1)%desc%name)
        ALLOCATE(CHARACTER(LEN=LEN_TRIM(name)) :: this%fields(n+1)%desc%name)
        this%fields(n+1)%desc%name = TRIM(name)
        IF (ALLOCATED(this%fields(n+1)%desc%eshape)) DEALLOCATE(this%fields(n+1)%desc%eshape)
        ALLOCATE(this%fields(n+1)%desc%eshape(1))
        this%fields(n+1)%desc%eshape(1) = 1
        this%nFields = n + 1_i4
        this%nEq     = this%fields(n+1)%eqEnd
    END SUBROUTINE uf_add_field

    !> Purpose: Perform AddField operation
    SUBROUTINE uf_AddField(this, fieldType, name, nDof)
        CLASS(UFView), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: fieldType, nDof
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: n, eq0
        TYPE(UF_UFField), ALLOCATABLE :: tmp(:)
        IF (nDof <= 0_i4) RETURN
        n = this%nFields
        IF (ALLOCATED(this%fields)) THEN
            ALLOCATE(tmp(n+1))
            IF (n > 0) tmp(1:n) = this%fields(1:n)
            DEALLOCATE(this%fields)
            CALL MOVE_ALLOC(tmp, this%fields)
        ELSE
            ALLOCATE(this%fields(1))
        END IF
        IF (n == 0) THEN
            eq0 = 1_i4
        ELSE
            eq0 = this%fields(n)%eqEnd + 1_i4
        END IF
        this%fields(n+1)%fieldType = fieldType
        this%fields(n+1)%nDof = nDof
        this%fields(n+1)%eqStart = eq0
        this%fields(n+1)%eqEnd = eq0 + nDof - 1_i4
        this%fields(n+1)%desc%loc = MD_MODEL_UF_FLD_AT_NODE
        this%fields(n+1)%desc%bas = MD_MODEL_UF_FLD_REAL8
        this%fields(n+1)%desc%rank = 1
        IF (ALLOCATED(this%fields(n+1)%desc%name)) DEALLOCATE(this%fields(n+1)%desc%name)
        this%fields(n+1)%desc%name = trim(name)
        IF (ALLOCATED(this%fields(n+1)%desc%eshape)) DEALLOCATE(this%fields(n+1)%desc%eshape)
        ALLOCATE(this%fields(n+1)%desc%eshape(1))
        this%fields(n+1)%desc%eshape(1) = 1
        this%nFields = n + 1_i4
        this%nEq = this%fields(n+1)%eqEnd
    END SUBROUTINE uf_AddField

    !> Purpose: Perform AttachDm operation
    SUBROUTINE uf_AttachDm(this, dm_ptr)
        CLASS(UFView), INTENT(INOUT) :: this
        TYPE(DofMap), POINTER, INTENT(IN) :: dm_ptr
        this%dm => dm_ptr
        IF (ASSOCIATED(this%dm)) THEN
            this%nEq = this%dm%Neq()
        END IF
    END SUBROUTINE uf_AttachDm

    !> Purpose: Perform span operation
    SUBROUTINE uf_field_span(this, eqStart, eqEnd)
        CLASS(UF_UFField), INTENT(IN)  :: this
        INTEGER(i4),       INTENT(OUT) :: eqStart, eqEnd
        eqStart = this%eqStart
        eqEnd   = this%eqEnd
    END SUBROUTINE uf_field_span

    !> Purpose: Perform span operation
    SUBROUTINE uf_get_eq_span(this, idx, eqStart, eqEnd)
        CLASS(UF_UFCore), INTENT(IN)  :: this
        INTEGER(i4),      INTENT(IN)  :: idx
        INTEGER(i4),      INTENT(OUT) :: eqStart, eqEnd
        IF (idx < 1_i4 .OR. idx > this%nFields) THEN
            eqStart = 0_i4
            eqEnd   = 0_i4
        ELSE
            eqStart = this%fields(idx)%eqStart
            eqEnd   = this%fields(idx)%eqEnd
        END IF
    END SUBROUTINE uf_get_eq_span

    !> Purpose: Perform field operation
    SUBROUTINE uf_get_field(this, idx, fld)
        CLASS(UF_UFCore), INTENT(IN)  :: this
        INTEGER(i4),      INTENT(IN)  :: idx
        TYPE(UF_UFField), INTENT(OUT) :: fld
        IF (idx < 1_i4 .OR. idx > this%nFields) THEN
            fld%nDof      = 0_i4
            fld%eqStart   = 0_i4
            fld%eqEnd     = 0_i4
            fld%fieldType = 0_i4
            IF (ALLOCATED(fld%desc%name))   DEALLOCATE(fld%desc%name)
            IF (ALLOCATED(fld%desc%eshape)) DEALLOCATE(fld%desc%eshape)
            RETURN
        END IF
        fld = this%fields(idx)
    END SUBROUTINE uf_get_field

    !> Purpose: Perform GetEqSpan operation
    SUBROUTINE uf_GetEqSpan(this, idx, eqStart, eqEnd)
        CLASS(UFView), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: idx
        INTEGER(i4), INTENT(OUT) :: eqStart, eqEnd
        IF (idx < 1_i4 .OR. idx > this%nFields) THEN
            eqStart = 0_i4
            eqEnd = 0_i4
        ELSE
            eqStart = this%fields(idx)%eqStart
            eqEnd = this%fields(idx)%eqEnd
        END IF
    END SUBROUTINE uf_GetEqSpan

    !> Purpose: Perform GetField operation
    SUBROUTINE uf_GetField(this, idx, fld)
        CLASS(UFView), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: idx
        TYPE(UF_UFField), INTENT(OUT) :: fld
        IF (idx < 1_i4 .OR. idx > this%nFields) THEN
            fld%nDof = 0_i4
            fld%eqStart = 0_i4
            fld%eqEnd = 0_i4
            fld%fieldType = 0_i4
            IF (ALLOCATED(fld%desc%name)) DEALLOCATE(fld%desc%name)
            IF (ALLOCATED(fld%desc%eshape)) DEALLOCATE(fld%desc%eshape)
            RETURN
        END IF
        fld = this%fields(idx)
    END SUBROUTINE uf_GetField

    !> Purpose: Reset
    SUBROUTINE uf_ResetView(this)
        CLASS(UFView), INTENT(INOUT) :: this
        IF (ALLOCATED(this%fields)) DEALLOCATE(this%fields)
        this%nFields = 0_i4
        this%nEq = 0_i4
        NULLIFY(this%dm)
    END SUBROUTINE uf_ResetView

    !> Purpose: Execute UniqueInt
    SUBROUTINE UniqueInt(a, n, out, nOut)
        INTEGER(i4), INTENT(IN)  :: a(:)
        INTEGER(i4), INTENT(IN)  :: n
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: out(:)
        INTEGER(i4), INTENT(OUT) :: nOut
        INTEGER(i4) :: i, j, k
        INTEGER(i4), ALLOCATABLE :: temp(:)
        LOGICAL :: found

        IF (n <= 0) THEN
            nOut = 0_i4
            IF (ALLOCATED(out)) DEALLOCATE(out)
            ALLOCATE(out(0))
            RETURN
        END IF

        ! Create temporary sorted array
        ALLOCATE(temp(n))
        temp(1:n) = a(1:n)
        CALL SortInt(temp, n)

        ! Extract unique values from sorted array
        ALLOCATE(out(n))
        k = 0_i4
        DO i = 1, n
            IF (i == 1_i4 .OR. temp(i) /= temp(i-1)) THEN
                k = k + 1_i4
                out(k) = temp(i)
            END IF
        END DO
        nOut = k
        DEALLOCATE(temp)
    END SUBROUTINE UniqueInt

    !> Purpose: Execute VarName
    FUNCTION VarName(self) RESULT(name)
        CLASS(CoreBase), INTENT(IN) :: self
        CHARACTER(LEN=64) :: name
        name = self%algo_var_name
    END FUNCTION VarName



    !> Default stub for CoreBase%RegLayout (override in concrete subtype)
    SUBROUTINE CoreBase_RegLayout(this)
        CLASS(CoreBase), INTENT(IN) :: this
        ! Default: no-op stub
    END SUBROUTINE CoreBase_RegLayout

    !> Default stub for CoreBase%Ensure (override in concrete subtype)
    SUBROUTINE CoreBase_Ensure(this)
        CLASS(CoreBase), INTENT(INOUT) :: this
        ! Default: no-op stub
    END SUBROUTINE CoreBase_Ensure

    !> Default stub for DescBase%RegLayout (override in concrete subtype)
    SUBROUTINE DescBase_RegLayout(this)
        CLASS(DescBase), INTENT(IN) :: this
        ! Default: no-op stub
    END SUBROUTINE DescBase_RegLayout

    !> Default stub for DescBase%Ensure (override in concrete subtype)
    SUBROUTINE DescBase_Ensure(this)
        CLASS(DescBase), INTENT(INOUT) :: this
        ! Default: no-op stub
    END SUBROUTINE DescBase_Ensure

    !> Default stub for StateBase%RegLayout (override in concrete subtype)
    SUBROUTINE StateBase_RegLayout(this)
        CLASS(StateBase), INTENT(IN) :: this
        ! Default: no-op stub
    END SUBROUTINE StateBase_RegLayout

    !> Default stub for StateBase%Ensure (override in concrete subtype)
    SUBROUTINE StateBase_Ensure(this)
        CLASS(StateBase), INTENT(INOUT) :: this
        ! Default: no-op stub
    END SUBROUTINE StateBase_Ensure

    !> Default stub for AlgoBase%RegLayout (override in concrete subtype)
    SUBROUTINE AlgoBase_RegLayout(this)
        CLASS(AlgoBase), INTENT(IN) :: this
        ! Default: no-op stub
    END SUBROUTINE AlgoBase_RegLayout

    !> Default stub for AlgoBase%Ensure (override in concrete subtype)
    SUBROUTINE AlgoBase_Ensure(this)
        CLASS(AlgoBase), INTENT(INOUT) :: this
        ! Default: no-op stub
    END SUBROUTINE AlgoBase_Ensure

    !> Default stub for CtxBase%RegLayout (override in concrete subtype)
    SUBROUTINE CtxBase_RegLayout(this)
        CLASS(CtxBase), INTENT(IN) :: this
        ! Default: no-op stub
    END SUBROUTINE CtxBase_RegLayout

    !> Default stub for CtxBase%Ensure (override in concrete subtype)
    SUBROUTINE CtxBase_Ensure(this)
        CLASS(CtxBase), INTENT(INOUT) :: this
        ! Default: no-op stub
    END SUBROUTINE CtxBase_Ensure

END MODULE MD_Base_ObjModel