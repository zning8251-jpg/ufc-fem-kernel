!===============================================================================
! MODULE:  MD_LBC_Container
! LAYER:   L3_MD
! DOMAIN:  Boundary
! ROLE:    _Domain
! BRIEF:   LoadBC container types ?Desc + State + Algo + Ctx + Runtime domain.
!===============================================================================
MODULE MD_LBC_Container
    USE ieee_arithmetic, ONLY: ieee_is_finite
    USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Err_Brg, ONLY: log_warn
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc, MD_Amp_Slot_Ctx
    USE MD_Amp_Mgr, ONLY: Amp_GetFactor, MD_Amp_GetFactor
    USE MD_Base_ObjModel, ONLY: DescBase, StateBase, CtxBase, AlgoBase, BaseCtx, BaseSta, CAT_DESC, CAT_STATE, CAT_CTX, CAT_ALGO, &
                           uf_set_error_status, AnalysisStep, UF_Element, UF_DOF_U1, UF_DOF_U2, UF_DOF_U3, UF_DOF_UR1, UF_DOF_UR2, UF_DOF_UR3
    USE MD_Base_TreeIndex
    USE MD_Model_Lib_Core, ONLY: UF_Model
    USE MD_L3_Layer, ONLY: MD_L3_LayerContainer
    USE MD_Elem_Mgr, ONLY: ElemType, UF_ElementType_FillById, UF_El_GetConnectivity
    USE MD_Load_Mgr, ONLY: LoadDef, LoadDef_Init, LOAD_CONCENTRAT, LOAD_DISTRIBUTE, LOAD_PRESSURE, &
                            LOAD_BODY_FORCE, LOAD_GRAVITY, LOAD_CENTRIFUGA, &
                            TARGET_NODE, TARGET_NODESET, TARGET_SURFACE, TARGET_ELEMSET
    USE MD_BC_Mgr, ONLY: BCDef, BC_DISPLACEMENT
    USE MD_LBC_Query, ONLY: Ldbc_GetNodeSetNodes, Ldbc_GetElemSetElements, Ldbc_GetElementNodes, &
                             Ldbc_GetFaceNodes, Ldbc_GetSurfaceElemFaceArrays, &
                             Ldbc_FindElementIndexById, Ldbc_NodeCoordsForMeshIndex, &
                             Ldbc_FindNodeSetId, Ldbc_FindSurfaceSetId, &
                             Ldbc_FindElementSetId
    USE MD_LBC_Helper, ONLY: MD_LoadBC_Helper_ComputeFaceNormalArea, MD_LoadBC_Helper_AddNodalVectorForce

    IMPLICIT NONE
    PRIVATE

  ! Forward declarations of type-bound procedure implementations
  ! (needed for PROCEDURE statements in types)

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LdbcDesc
  ! KIND:  Desc
  ! DESC:  Single LoadBC descriptor ?ID, name, region, DOFs, amplitude.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_LdbcDesc
    INTEGER(i4) :: loadBCId = 0_i4
    INTEGER(i4) :: name_index = 0_i4
    CHARACTER(len=64) :: name_legacy = ""
    CHARACTER(len=32) :: loadBCType = ""
    CHARACTER(len=64) :: region = ""
    INTEGER(i4), ALLOCATABLE :: dofs(:)
    CHARACTER(len=64) :: amplitudeName = ""
    CHARACTER(len=64) :: timeFunctionName = ""
    REAL(wp) :: value = 0.0_wp
    REAL(wp), ALLOCATABLE :: direction(:)
    CHARACTER(len=256) :: description = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_LdbcDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_LdbcDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_LdbcDesc_Init
    PROCEDURE, PUBLIC :: Destroy => MD_LdbcDesc_Destroy
    PROCEDURE, PUBLIC :: GetName => MD_LdbcDesc_GetName
  END TYPE MD_LdbcDesc

  !---------------------------------------------------------------------------
  ! TYPE:  LoadBCTree
  ! KIND:  Desc
  ! DESC:  Tree-structured LoadBC descriptor with index/batch management.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(MD_LdbcDesc) :: LoadBCTree
    INTEGER(i4) :: node_id = 0_i4
    INTEGER(i4) :: parent_id = 0_i4
    LOGICAL :: is_active = .TRUE.
    LOGICAL :: is_visible = .TRUE.
    TYPE(IndexMgr) :: index_mgr
    TYPE(LazyIndexMgr) :: lazy_index
    TYPE(BatchOpMgr) :: batch_mgr
    TYPE(PathResolver) :: path_resolver
    LOGICAL :: tree_initialize = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: GetID => LoadBCTree_GetID
    PROCEDURE, PUBLIC :: GetName => LoadBCTree_GetName
    PROCEDURE, PUBLIC :: GetType => LoadBCTree_GetType
    PROCEDURE, PUBLIC :: GetParentID => LoadBCTree_GetParentID
    PROCEDURE, PUBLIC :: GetByPath => LoadBCTree_GetByPath
    PROCEDURE, PUBLIC :: GetFullPath => LoadBCTree_GetFullPath
    PROCEDURE, PUBLIC :: InitTree => LoadBCTree_InitTree
    PROCEDURE, PUBLIC :: DestroyTree => LoadBCTree_DestroyTree
    PROCEDURE, PUBLIC :: RebuildIndex => LoadBCTree_RebuildIndex
    PROCEDURE, PUBLIC :: ValidateTree => LoadBCTree_ValidateTree
    PROCEDURE, PUBLIC :: Serialize => LoadBCTree_Serialize
    PROCEDURE, PUBLIC :: Deserialize => LoadBCTree_Deserialize
    PROCEDURE, PUBLIC :: BeginBatch => LoadBCTree_BeginBatch
    PROCEDURE, PUBLIC :: EndBatch => LoadBCTree_EndBatch
  END TYPE LoadBCTree

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LdbcSta
  ! KIND:  State
  ! DESC:  Single LoadBC runtime state ?active flag, applied force, prescribed.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_LdbcSta
    INTEGER(i4) :: loadBCId = 0_i4
    LOGICAL :: isActive = .false.
    REAL(wp), ALLOCATABLE :: F_applied(:)
    REAL(wp), ALLOCATABLE :: u_prescribed(:)
    REAL(wp) :: currentValue = 0.0_wp
    REAL(wp) :: currentTime = 0.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_LdbcSta_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_LdbcSta_Ensure
    PROCEDURE, PUBLIC :: Init => MD_LdbcSta_Init
    PROCEDURE, PUBLIC :: Destroy => MD_LdbcSta_Destroy
  END TYPE MD_LdbcSta

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LdbcCtx
  ! KIND:  Ctx
  ! DESC:  Single LoadBC context ?current loadBC ID binding.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(CtxBase) :: MD_LdbcCtx
    INTEGER(i4) :: loadBCId = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_LdbcCtx_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_LdbcCtx_Ensure
    PROCEDURE, PUBLIC :: Init => MD_LdbcCtx_Init
  END TYPE MD_LdbcCtx

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LdbcAlgo
  ! KIND:  Algo
  ! DESC:  Single LoadBC algorithm ?application method, penalty, Lagrange.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(AlgoBase) :: MD_LdbcAlgo
    CHARACTER(len=32) :: applicationmeth = "direct"
    REAL(wp) :: penaltyFactor = 1.0e6_wp
    INTEGER(i4) :: updateFrequency = 1_i4
    LOGICAL :: uselagrangemult = .false.
    LOGICAL :: usepenaltymetho = .true.
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_LdbcAlgo_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_LdbcAlgo_Ensure
    PROCEDURE, PUBLIC :: Init => MD_LdbcAlgo_Init
  END TYPE MD_LdbcAlgo

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_Desc
  ! KIND:  Desc
  ! DESC:  SOA container ?all LoadBC descriptors (IDs, names, types, regions).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_Desc
    INTEGER(i4) :: nLoadBCs = 0_i4
    INTEGER(i4), ALLOCATABLE :: loadBCId(:)
    CHARACTER(len=64), ALLOCATABLE :: name(:)
    CHARACTER(len=32), ALLOCATABLE :: loadBCType(:)
    CHARACTER(len=64), ALLOCATABLE :: region(:)
    INTEGER(i4), ALLOCATABLE :: dofs(:,:)
    INTEGER(i4), ALLOCATABLE :: nDofsPerLoadBC(:)
    CHARACTER(len=64), ALLOCATABLE :: amplitudeName(:)
    CHARACTER(len=64), ALLOCATABLE :: timeFunctionName(:)
    REAL(wp), ALLOCATABLE :: value(:)
    REAL(wp), ALLOCATABLE :: direction(:,:)
    CHARACTER(len=256), ALLOCATABLE :: description(:)
    INTEGER(i4), ALLOCATABLE :: bcIndices(:)
    INTEGER(i4), ALLOCATABLE :: cloadIndices(:)
    INTEGER(i4), ALLOCATABLE :: dloadIndices(:)
    INTEGER(i4), ALLOCATABLE :: bforceIndices(:)
    INTEGER(i4), ALLOCATABLE :: stepMapping(:)
  END TYPE MD_LoadBC_Desc

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_State
  ! KIND:  State
  ! DESC:  SOA container ?all LoadBC runtime states (active, forces, values).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_State
    INTEGER(i4) :: nLoadBCs = 0_i4
    INTEGER(i4) :: state_capacity = 0_i4
    INTEGER(i4), ALLOCATABLE :: loadBCId(:)
    LOGICAL, ALLOCATABLE :: isActive(:)
    REAL(wp), ALLOCATABLE :: F_applied(:,:)
    REAL(wp), ALLOCATABLE :: u_prescribed(:,:)
    REAL(wp), ALLOCATABLE :: currentValue(:)
    REAL(wp), ALLOCATABLE :: currentTime(:)
    INTEGER(i4) :: stepId = -1_i4
    REAL(wp) :: time = 0.0_wp
  END TYPE MD_LoadBC_State

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_Algo
  ! KIND:  Algo
  ! DESC:  SOA container ?all LoadBC algorithms + ID-to-index map.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_Algo
    INTEGER(i4) :: nLoadBCs = 0_i4
    INTEGER(i4) :: idxMap_capacity = 0_i4
    CHARACTER(len=32), ALLOCATABLE :: applicationMethod(:)
    REAL(wp), ALLOCATABLE :: penaltyFactor(:)
    INTEGER(i4), ALLOCATABLE :: updateFrequency(:)
    LOGICAL, ALLOCATABLE :: useLagrangeMultiplier(:)
    LOGICAL, ALLOCATABLE :: usePenaltyMethod(:)
    INTEGER(i4), ALLOCATABLE :: idToIndexMap(:)
    INTEGER(i4) :: maxLoadBCId = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => LBCAlgo_Init
    PROCEDURE, PUBLIC :: Reset => LBCAlgo_Reset
    PROCEDURE, PUBLIC :: Finalize => LBCAlgo_Finalize
    PROCEDURE, PUBLIC :: SyncFromStep => LBCAlgo_SyncFromStep
    PROCEDURE, PUBLIC :: SyncFromTree => LBCAlgo_SyncFromTree
    PROCEDURE, PUBLIC :: GetActiveLoadsForStep => LBCAlgo_GetActiveLoadsForStep
    PROCEDURE, PUBLIC :: GetRegionNodes => LBCAlgo_GetRegionNodes
    PROCEDURE, PUBLIC :: GetAmplitudeFactor => LBCAlgo_GetAmplitudeFactor
    PROCEDURE, PUBLIC :: GetDofIndices => LBCAlgo_GetDofIndices
    PROCEDURE, PUBLIC :: WriteBack => LBCAlgo_WriteBack
  END TYPE MD_LoadBC_Algo

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_Ctx
  ! KIND:  Ctx
  ! DESC:  SOA container ?runtime context (model pointer, step, force vector).
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_Ctx
    INTEGER(i4) :: currentLoadBCId = 0_i4
    TYPE(UF_Model), POINTER :: model => null()
    TYPE(AnalysisStep), POINTER :: step => null()
    REAL(wp), POINTER :: F(:) => null()
    REAL(wp) :: time = 0.0_wp
  END TYPE MD_LoadBC_Ctx

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_Runtime_Domain
  ! KIND:  Ctx
  ! DESC:  Aggregated domain ?Desc + State + Algo + Ctx for runtime LoadBC.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_Runtime_Domain
    TYPE(MD_LoadBC_Desc) :: desc
    TYPE(MD_LoadBC_State) :: state
    TYPE(MD_LoadBC_Algo) :: algo
    TYPE(MD_LoadBC_Ctx) :: ctx
  END TYPE MD_LoadBC_Runtime_Domain

  TYPE(MD_LoadBC_Runtime_Domain), SAVE, PUBLIC :: g_md_loadbc_domain

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_TableDesc
  ! KIND:  Desc
  ! DESC:  Table-layout load descriptors ?SOA for batch load operations.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_TableDesc
    INTEGER(i4) :: nLoads = 0_i4
    INTEGER(i4), ALLOCATABLE :: loadId(:)
    CHARACTER(len=64), ALLOCATABLE :: name(:)
    CHARACTER(len=32), ALLOCATABLE :: loadType(:)
    CHARACTER(len=64), ALLOCATABLE :: region(:)
    REAL(wp), ALLOCATABLE :: magnitude(:)
    REAL(wp), ALLOCATABLE :: direction(:,:)
    CHARACTER(len=64), ALLOCATABLE :: amplitudeName(:)
    CHARACTER(len=256), ALLOCATABLE :: description(:)
    INTEGER(i4), ALLOCATABLE :: cloadIndices(:)
    INTEGER(i4), ALLOCATABLE :: dloadIndices(:)
    INTEGER(i4), ALLOCATABLE :: bforceIndices(:)
  END TYPE MD_LoadBC_TableDesc

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_TableSta
  ! KIND:  State
  ! DESC:  Table-layout load runtime state ?active flags, applied forces.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_TableSta
    INTEGER(i4) :: nLoads = 0_i4
    INTEGER(i4) :: state_capacity = 0_i4
    INTEGER(i4), ALLOCATABLE :: loadId(:)
    LOGICAL, ALLOCATABLE :: isActive(:)
    REAL(wp), ALLOCATABLE :: F_applied(:,:)
    REAL(wp), ALLOCATABLE :: currentValue(:)
    REAL(wp), ALLOCATABLE :: currentTime(:)
    INTEGER(i4) :: stepId = -1_i4
    REAL(wp) :: time = 0.0_wp
  END TYPE MD_LoadBC_TableSta

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_TableAlgo
  ! KIND:  Algo
  ! DESC:  Table-layout load algorithm ?index map, amplitude cache, apply.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_TableAlgo
    INTEGER(i4) :: nLoads = 0_i4
    INTEGER(i4) :: idxMap_capacity = 0_i4
    INTEGER(i4), ALLOCATABLE :: idToIndexMap(:)
    INTEGER(i4) :: maxLoadId = 0_i4
    TYPE(MD_Amp_Slot_Ctx), POINTER :: amplitudeDB_cache => null()
    INTEGER(i4) :: cached_model_id = -1_i4
    CHARACTER(len=64), ALLOCATABLE :: cached_regionNames(:)
    INTEGER(i4), ALLOCATABLE :: cached_regionIds(:)
    INTEGER(i4), ALLOCATABLE :: cached_regionTypes(:)
    INTEGER(i4) :: cache_size = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => LBCTableAlgo_Init
    PROCEDURE, PUBLIC :: Reset => LBCTableAlgo_Reset
    PROCEDURE, PUBLIC :: Finalize => LBCTableAlgo_Finalize
    PROCEDURE, PUBLIC :: SyncFromStep => LBCTableAlgo_SyncFromStep
    PROCEDURE, PUBLIC :: GetActiveLoadsForStep => LBCTableAlgo_GetActiveLoadsForStep
    PROCEDURE, PUBLIC :: GetRegionNodes => LBCTableAlgo_GetRegionNodes
    PROCEDURE, PUBLIC :: GetAmplitudeFactor => LBCTableAlgo_GetAmplitudeFactor
    PROCEDURE, PUBLIC :: WriteBack => LBCTableAlgo_WriteBack
    PROCEDURE, PUBLIC :: ApplyToForce => LBCTableAlgo_ApplyToForce
  END TYPE MD_LoadBC_TableAlgo

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_TableCtx
  ! KIND:  Ctx
  ! DESC:  Table-layout load context ?current load binding, model pointer.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_TableCtx
    INTEGER(i4) :: currentLoadId = 0_i4
    TYPE(UF_Model), POINTER :: model => null()
    TYPE(AnalysisStep), POINTER :: step => null()
    REAL(wp), POINTER :: F(:) => null()
    REAL(wp) :: time = 0.0_wp
  END TYPE MD_LoadBC_TableCtx

  !---------------------------------------------------------------------------
  ! TYPE:  MD_LoadBC_TableDomain
  ! KIND:  Ctx
  ! DESC:  Aggregated table domain ?Desc + State + Algo + Ctx for table loads.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_LoadBC_TableDomain
    TYPE(MD_LoadBC_TableDesc) :: desc
    TYPE(MD_LoadBC_TableSta) :: state
    TYPE(MD_LoadBC_TableAlgo) :: algo
    TYPE(MD_LoadBC_TableCtx) :: ctx
  END TYPE MD_LoadBC_TableDomain

  TYPE(MD_LoadBC_TableDomain), SAVE, PUBLIC :: g_md_loadbc_table

  !======================================================================
  ! Additional descriptor types
  !======================================================================
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_LoadDesc
    INTEGER(i4) :: loadId = 0_i4
    INTEGER(i4) :: name_index = 0_i4
    CHARACTER(len=64) :: name_legacy = ""
    CHARACTER(len=32) :: loadType = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_LoadDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_LoadDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_LoadDesc_Init
    PROCEDURE, PUBLIC :: GetName => MD_LoadDesc_GetName
  END TYPE MD_LoadDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_BndDesc
    INTEGER(i4) :: boundaryId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=32) :: boundaryType = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_BndDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_BndDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_BndDesc_Init
  END TYPE MD_BndDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_ConcForceDesc
    INTEGER(i4) :: loadId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: setName = ""
    REAL(wp) :: force(3) = 0.0_wp
    CHARACTER(len=64) :: amplitudeName = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_ConcForceDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_ConcForceDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_ConcForceDesc_Init
  END TYPE MD_ConcForceDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_DistLoadDesc
    INTEGER(i4) :: loadId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: setName = ""
    REAL(wp) :: magnitude = 0.0_wp
    REAL(wp) :: direction(3) = 0.0_wp
    CHARACTER(len=64) :: amplitudeName = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_DistLoadDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_DistLoadDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_DistLoadDesc_Init
  END TYPE MD_DistLoadDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_DispBCDesc
    INTEGER(i4) :: boundaryId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: setName = ""
    REAL(wp) :: displacement(3) = 0.0_wp
    CHARACTER(len=64) :: amplitudeName = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_DispBCDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_DispBCDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_DispBCDesc_Init
  END TYPE MD_DispBCDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_VelBCDesc
    INTEGER(i4) :: boundaryId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: setName = ""
    REAL(wp) :: velocity(3) = 0.0_wp
    CHARACTER(len=64) :: amplitudeName = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_VelBCDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_VelBCDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_VelBCDesc_Init
  END TYPE MD_VelBCDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_BodyForceDesc
    INTEGER(i4) :: loadId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: setName = ""
    REAL(wp) :: magnitude(3) = 0.0_wp
    CHARACTER(len=64) :: amplitudeName = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_BodyForceDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_BodyForceDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_BodyForceDesc_Init
  END TYPE MD_BodyForceDesc

  TYPE, PUBLIC :: LoadB
    INTEGER(i4) :: numBCs = 0_i4
    INTEGER(i4) :: numCLoads = 0_i4
    INTEGER(i4) :: numDLoads = 0_i4
    INTEGER(i4) :: numBForces = 0_i4
    TYPE(MD_BndDesc), ALLOCATABLE :: bcs(:)
    TYPE(MD_ConcForceDesc), ALLOCATABLE :: cloads(:)
    TYPE(MD_DistLoadDesc), ALLOCATABLE :: dloads(:)
    TYPE(MD_BodyForceDesc), ALLOCATABLE :: bforces(:)
  END TYPE LoadB

  TYPE, PUBLIC :: StepDef
    INTEGER(i4) :: stepNumber = 0_i4
    CHARACTER(len=80) :: name = ""
    INTEGER(i4) :: procedure = 1_i4
    INTEGER(i4) :: nlgeom = 0_i4
    INTEGER(i4) :: perturbation = 0_i4
    REAL(wp) :: timePeriod = 0.0_wp
    REAL(wp) :: timeIncrement = 0.0_wp
    REAL(wp) :: startTime = 0.0_wp
    INTEGER(i4) :: maxIncrements = 100_i4
    LOGICAL :: isActive = .TRUE.
    LOGICAL :: isComplete = .FALSE.
    TYPE(LoadB) :: loadbc
  END TYPE StepDef

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_NeumBCDesc
    INTEGER(i4) :: boundaryId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: surfaceName = ""
    REAL(wp) :: tractionVector(3) = 0.0_wp
    INTEGER(i4) :: distributiontyp = 1_i4
    CHARACTER(len=64) :: amplitudeName = ""
    LOGICAL :: isFollowerLoad = .false.
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_NeumBCDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_NeumBCDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_NeumBCDesc_Init
  END TYPE MD_NeumBCDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_RobinBCDesc
    INTEGER(i4) :: boundaryId = 0_i4
    CHARACTER(len=64) :: name = ""
    CHARACTER(len=64) :: nodeSetName = ""
    INTEGER(i4) :: dofComponent = 1_i4
    REAL(wp) :: stiffnessCoeff = 0.0_wp
    REAL(wp) :: convectionCoeff = 0.0_wp
    REAL(wp) :: ambientValue = 0.0_wp
    CHARACTER(len=64) :: amplitudeName = ""
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_RobinBCDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_RobinBCDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_RobinBCDesc_Init
  END TYPE MD_RobinBCDesc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_PerBCDesc
    INTEGER(i4) :: boundaryId = 0_i4
    CHARACTER(len=64) :: name = ""
    INTEGER(i4) :: masterNodeId = 0_i4
    INTEGER(i4) :: slaveNodeId = 0_i4
    INTEGER(i4) :: dofComponent = 1_i4
    REAL(wp) :: scaleFactor = 1.0_wp
    REAL(wp) :: offsetValue = 0.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_PerBCDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_PerBCDesc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_PerBCDesc_Init
  END TYPE MD_PerBCDesc

  ! Domain lifecycle PUBLIC exports
  PUBLIC :: MD_LoadBC_Domain_Init, MD_LoadBC_Domain_Reset, MD_LoadBC_Domain_Finalize, MD_LoadBC_Domain_SyncFromStep
  PUBLIC :: MD_LoadBC_Table_Init, MD_LoadBC_Table_Reset, MD_LoadBC_Table_Finalize, MD_LoadBC_Table_SyncFromStep

CONTAINS

  !======================================================================
  ! MD_LdbcDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_LdbcDesc_Init(this, loadBCId, name, loadBCType, region, dofs, amplitudeName, timeFunctionName, value, direction, description)
    CLASS(MD_LdbcDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: loadBCId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, loadBCType, region, amplitudeName, timeFunctionName, description
    INTEGER(i4), INTENT(IN), OPTIONAL :: dofs(:)
    REAL(wp), INTENT(IN), OPTIONAL :: value
    REAL(wp), INTENT(IN), OPTIONAL :: direction(:)
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::LOADBC')
    IF (PRESENT(loadBCId)) this%loadBCId = loadBCId
    IF (PRESENT(name)) this%name_legacy = name
    IF (PRESENT(loadBCType)) this%loadBCType = loadBCType
    IF (PRESENT(region)) this%region = region
    IF (PRESENT(amplitudeName)) this%amplitudeName = amplitudeName
    IF (PRESENT(timeFunctionName)) this%timeFunctionName = timeFunctionName
    IF (PRESENT(value)) this%value = value
    IF (PRESENT(description)) this%cfg%description = description
    IF (PRESENT(dofs)) THEN
      IF (ALLOCATED(this%dofs)) DEALLOCATE(this%dofs)
      ALLOCATE(this%dofs(SIZE(dofs)))
      this%dofs = dofs
    END IF
    IF (PRESENT(direction)) THEN
      IF (ALLOCATED(this%direction)) DEALLOCATE(this%direction)
      ALLOCATE(this%direction(SIZE(direction)))
      this%direction = direction
    END IF
  END SUBROUTINE MD_LdbcDesc_Init

  FUNCTION MD_LdbcDesc_GetName(this) RESULT(name)
    CLASS(MD_LdbcDesc), INTENT(IN) :: this
    CHARACTER(len=64) :: name
    IF (this%name_index > 0 .AND. this%name_index <= g_md_loadbc_domain%desc%nLoadBCs) THEN
      IF (ALLOCATED(g_md_loadbc_domain%desc%name)) THEN
        name = g_md_loadbc_domain%desc%name(this%name_index)
      ELSE
        name = this%name_legacy
      END IF
    ELSE
      name = this%name_legacy
    END IF
  END FUNCTION MD_LdbcDesc_GetName

  SUBROUTINE MD_LdbcDesc_Destroy(this)
    CLASS(MD_LdbcDesc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%dofs)) DEALLOCATE(this%dofs)
    IF (ALLOCATED(this%direction)) DEALLOCATE(this%direction)
  END SUBROUTINE MD_LdbcDesc_Destroy

  SUBROUTINE MD_LdbcDesc_RegLayout(this)
    CLASS(MD_LdbcDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(9)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'loadBCId';      fields(1)%data_type = IF_DATA_TYPE_INT;  fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'name';          fields(2)%data_type = IF_DATA_TYPE_CHAR; fields(2)%elem_len = 64;  fields(2)%offset_bytes = offset; offset = offset + 64
    fields(3)%field_name = 'loadBCType';    fields(3)%data_type = IF_DATA_TYPE_CHAR; fields(3)%elem_len = 32;  fields(3)%offset_bytes = offset; offset = offset + 32
    fields(4)%field_name = 'region';        fields(4)%data_type = IF_DATA_TYPE_CHAR; fields(4)%elem_len = 64;  fields(4)%offset_bytes = offset; offset = offset + 64
    fields(5)%field_name = 'amplitudeName'; fields(5)%data_type = IF_DATA_TYPE_CHAR; fields(5)%elem_len = 64;  fields(5)%offset_bytes = offset; offset = offset + 64
    fields(6)%field_name = 'timeFunctionName'; fields(6)%data_type = IF_DATA_TYPE_CHAR; fields(6)%elem_len = 64; fields(6)%offset_bytes = offset; offset = offset + 64
    fields(7)%field_name = 'value';         fields(7)%data_type = IF_DATA_TYPE_DP;   fields(7)%offset_bytes = offset; offset = offset + 8
    fields(8)%field_name = 'currentTime';   fields(8)%data_type = IF_DATA_TYPE_DP;   fields(8)%offset_bytes = offset; offset = offset + 8
    fields(9)%field_name = 'description';   fields(9)%data_type = IF_DATA_TYPE_CHAR; fields(9)%elem_len = 256; fields(9)%offset_bytes = offset; offset = offset + 256
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 9, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LdbcDesc_RegLayout")
  END SUBROUTINE MD_LdbcDesc_RegLayout

  SUBROUTINE MD_LdbcDesc_Ensure(this)
    CLASS(MD_LdbcDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_LOADBCDESC_', this%loadBCId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LdbcDesc_Ensure")
  END SUBROUTINE MD_LdbcDesc_Ensure

  !======================================================================
  ! MD_LdbcSta type-bound procedures
  !======================================================================
  SUBROUTINE MD_LdbcSta_Init(this, loadBCId, nDOF)
    CLASS(MD_LdbcSta), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: loadBCId, nDOF
    INTEGER(i4) :: n
    this%category = CAT_STATE
    IF (PRESENT(loadBCId)) this%loadBCId = loadBCId
    n = 3_i4
    IF (PRESENT(nDOF)) n = nDOF
    IF (n > 0_i4 .AND. .NOT. ALLOCATED(this%F_applied)) ALLOCATE(this%F_applied(n))
    IF (n > 0_i4 .AND. .NOT. ALLOCATED(this%u_prescribed)) ALLOCATE(this%u_prescribed(n))
    IF (ALLOCATED(this%F_applied)) this%F_applied = 0.0_wp
    IF (ALLOCATED(this%u_prescribed)) this%u_prescribed = 0.0_wp
  END SUBROUTINE MD_LdbcSta_Init

  SUBROUTINE MD_LdbcSta_Destroy(this)
    CLASS(MD_LdbcSta), INTENT(INOUT) :: this
    IF (ALLOCATED(this%F_applied)) DEALLOCATE(this%F_applied)
    IF (ALLOCATED(this%u_prescribed)) DEALLOCATE(this%u_prescribed)
  END SUBROUTINE MD_LdbcSta_Destroy

  SUBROUTINE MD_LdbcSta_RegLayout(this)
    CLASS(MD_LdbcSta), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'loadBCId';     fields(1)%data_type = IF_DATA_TYPE_INT; fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'isActive';     fields(2)%data_type = IF_DATA_TYPE_INT; fields(2)%offset_bytes = offset; offset = offset + 4
    fields(3)%field_name = 'currentValue'; fields(3)%data_type = IF_DATA_TYPE_DP;  fields(3)%offset_bytes = offset; offset = offset + 8
    fields(4)%field_name = 'currentTime';  fields(4)%data_type = IF_DATA_TYPE_DP;  fields(4)%offset_bytes = offset; offset = offset + 8
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 4, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LdbcSta_RegLayout")
  END SUBROUTINE MD_LdbcSta_RegLayout

  SUBROUTINE MD_LdbcSta_Ensure(this)
    CLASS(MD_LdbcSta), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_LOADBCSTATE_', this%loadBCId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LdbcSta_Ensure")
  END SUBROUTINE MD_LdbcSta_Ensure

  !======================================================================
  ! MD_LdbcCtx type-bound procedures
  !======================================================================
  SUBROUTINE MD_LdbcCtx_Init(this, loadBCId)
    CLASS(MD_LdbcCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: loadBCId
    CALL this%CoreBase%Init(CAT_CTX, 'CTX::LOADBC')
    IF (PRESENT(loadBCId)) this%loadBCId = loadBCId
  END SUBROUTINE MD_LdbcCtx_Init

  SUBROUTINE MD_LdbcCtx_RegLayout(this)
    CLASS(MD_LdbcCtx), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(1)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'loadBCId'; fields(1)%data_type = IF_DATA_TYPE_INT; fields(1)%offset_bytes = offset; offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 1, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LdbcCtx_RegLayout")
  END SUBROUTINE MD_LdbcCtx_RegLayout

  SUBROUTINE MD_LdbcCtx_Ensure(this)
    CLASS(MD_LdbcCtx), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_LOADBCCTX_', this%loadBCId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LdbcCtx_Ensure")
  END SUBROUTINE MD_LdbcCtx_Ensure

  !======================================================================
  ! MD_LoadDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_LoadDesc_Init(this, loadId, name, loadType)
    CLASS(MD_LoadDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: loadId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, loadType
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::LOAD')
    IF (PRESENT(loadId)) this%loadId = loadId
    IF (PRESENT(name)) this%name_legacy = name
    IF (PRESENT(loadType)) this%loadType = loadType
  END SUBROUTINE MD_LoadDesc_Init

  FUNCTION MD_LoadDesc_GetName(this) RESULT(name)
    CLASS(MD_LoadDesc), INTENT(IN) :: this
    CHARACTER(len=64) :: name
    IF (this%name_index > 0 .AND. this%name_index <= g_md_loadbc_table%desc%nLoads) THEN
      IF (ALLOCATED(g_md_loadbc_table%desc%name)) THEN
        name = g_md_loadbc_table%desc%name(this%name_index)
      ELSE
        name = this%name_legacy
      END IF
    ELSE
      name = this%name_legacy
    END IF
  END FUNCTION MD_LoadDesc_GetName

  SUBROUTINE MD_LoadDesc_RegLayout(this)
    CLASS(MD_LoadDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(3)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'loadId';   fields(1)%data_type = IF_DATA_TYPE_INT;  fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'name';     fields(2)%data_type = IF_DATA_TYPE_CHAR; fields(2)%elem_len = 64; fields(2)%offset_bytes = offset; offset = offset + 64
    fields(3)%field_name = 'loadType'; fields(3)%data_type = IF_DATA_TYPE_CHAR; fields(3)%elem_len = 32; fields(3)%offset_bytes = offset; offset = offset + 32
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 3, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LoadDesc_RegLayout")
  END SUBROUTINE MD_LoadDesc_RegLayout

  SUBROUTINE MD_LoadDesc_Ensure(this)
    CLASS(MD_LoadDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_LOADDESC_', this%loadId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LoadDesc_Ensure")
  END SUBROUTINE MD_LoadDesc_Ensure

  !======================================================================
  ! MD_BndDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_BndDesc_Init(this, boundaryId, name, boundaryType)
    CLASS(MD_BndDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: boundaryId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, boundaryType
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::BOUNDARY')
    IF (PRESENT(boundaryId)) this%boundaryId = boundaryId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(boundaryType)) this%boundaryType = boundaryType
  END SUBROUTINE MD_BndDesc_Init

  SUBROUTINE MD_BndDesc_RegLayout(this)
    CLASS(MD_BndDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(3)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'boundaryId';   fields(1)%data_type = IF_DATA_TYPE_INT;  fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'name';         fields(2)%data_type = IF_DATA_TYPE_CHAR; fields(2)%elem_len = 64; fields(2)%offset_bytes = offset; offset = offset + 64
    fields(3)%field_name = 'boundaryType'; fields(3)%data_type = IF_DATA_TYPE_CHAR; fields(3)%elem_len = 32; fields(3)%offset_bytes = offset; offset = offset + 32
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 3, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_BndDesc_RegLayout")
  END SUBROUTINE MD_BndDesc_RegLayout

  SUBROUTINE MD_BndDesc_Ensure(this)
    CLASS(MD_BndDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_BOUNDARYDESC_', this%boundaryId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_BndDesc_Ensure")
  END SUBROUTINE MD_BndDesc_Ensure

  !======================================================================
  ! MD_ConcForceDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_ConcForceDesc_Init(this, loadId, name, setName, force, amplitudeName)
    CLASS(MD_ConcForceDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: loadId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, setName, amplitudeName
    REAL(wp), INTENT(IN), OPTIONAL :: force(3)
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::CONCENTRATEDFORCE')
    IF (PRESENT(loadId)) this%loadId = loadId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(setName)) this%setName = setName
    IF (PRESENT(force)) this%force = force
    IF (PRESENT(amplitudeName)) this%amplitudeName = amplitudeName
  END SUBROUTINE MD_ConcForceDesc_Init

  SUBROUTINE MD_ConcForceDesc_RegLayout(this)
    CLASS(MD_ConcForceDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'loadId';        fields(1)%data_type = IF_DATA_TYPE_INT;  fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'name';          fields(2)%data_type = IF_DATA_TYPE_CHAR; fields(2)%elem_len = 64; fields(2)%offset_bytes = offset; offset = offset + 64
    fields(3)%field_name = 'setName';       fields(3)%data_type = IF_DATA_TYPE_CHAR; fields(3)%elem_len = 64; fields(3)%offset_bytes = offset; offset = offset + 64
    fields(4)%field_name = 'force';         fields(4)%data_type = IF_DATA_TYPE_DP;   fields(4)%offset_bytes = offset; offset = offset + 24
    fields(5)%field_name = 'amplitudeName'; fields(5)%data_type = IF_DATA_TYPE_CHAR; fields(5)%elem_len = 64; fields(5)%offset_bytes = offset; offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 5, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_ConcForceDesc_RegLayout")
  END SUBROUTINE MD_ConcForceDesc_RegLayout

  SUBROUTINE MD_ConcForceDesc_Ensure(this)
    CLASS(MD_ConcForceDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_CONCENTRATEDFORCEDESC_', this%loadId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_ConcForceDesc_Ensure")
  END SUBROUTINE MD_ConcForceDesc_Ensure

  !======================================================================
  ! MD_DistLoadDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_DistLoadDesc_Init(this, loadId, name, setName, magnitude, direction, amplitudeName)
    CLASS(MD_DistLoadDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: loadId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, setName, amplitudeName
    REAL(wp), INTENT(IN), OPTIONAL :: magnitude, direction(3)
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::DISTRIBUTEDLOAD')
    IF (PRESENT(loadId)) this%loadId = loadId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(setName)) this%setName = setName
    IF (PRESENT(magnitude)) this%magnitude = magnitude
    IF (PRESENT(direction)) this%direction = direction
    IF (PRESENT(amplitudeName)) this%amplitudeName = amplitudeName
  END SUBROUTINE MD_DistLoadDesc_Init

  SUBROUTINE MD_DistLoadDesc_RegLayout(this)
    CLASS(MD_DistLoadDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(6)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'loadId';        fields(1)%data_type = IF_DATA_TYPE_INT;  fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'name';          fields(2)%data_type = IF_DATA_TYPE_CHAR; fields(2)%elem_len = 64; fields(2)%offset_bytes = offset; offset = offset + 64
    fields(3)%field_name = 'setName';       fields(3)%data_type = IF_DATA_TYPE_CHAR; fields(3)%elem_len = 64; fields(3)%offset_bytes = offset; offset = offset + 64
    fields(4)%field_name = 'magnitude';     fields(4)%data_type = IF_DATA_TYPE_DP;   fields(4)%offset_bytes = offset; offset = offset + 8
    fields(5)%field_name = 'direction';     fields(5)%data_type = IF_DATA_TYPE_DP;   fields(5)%offset_bytes = offset; offset = offset + 24
    fields(6)%field_name = 'amplitudeName'; fields(6)%data_type = IF_DATA_TYPE_CHAR; fields(6)%elem_len = 64; fields(6)%offset_bytes = offset; offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 6, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DistLoadDesc_RegLayout")
  END SUBROUTINE MD_DistLoadDesc_RegLayout

  SUBROUTINE MD_DistLoadDesc_Ensure(this)
    CLASS(MD_DistLoadDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_DISTRIBUTEDLOADDESC_', this%loadId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DistLoadDesc_Ensure")
  END SUBROUTINE MD_DistLoadDesc_Ensure

  !======================================================================
  ! MD_DispBCDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_DispBCDesc_Init(this, boundaryId, name, setName, displacement, amplitudeName)
    CLASS(MD_DispBCDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: boundaryId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, setName, amplitudeName
    REAL(wp), INTENT(IN), OPTIONAL :: displacement(3)
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::DISPLACEMENTBC')
    IF (PRESENT(boundaryId)) this%boundaryId = boundaryId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(setName)) this%setName = setName
    IF (PRESENT(displacement)) this%displacement = displacement
    IF (PRESENT(amplitudeName)) this%amplitudeName = amplitudeName
  END SUBROUTINE MD_DispBCDesc_Init

  SUBROUTINE MD_DispBCDesc_RegLayout(this)
    CLASS(MD_DispBCDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'boundaryId';    fields(1)%data_type = IF_DATA_TYPE_INT;  fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'name';          fields(2)%data_type = IF_DATA_TYPE_CHAR; fields(2)%elem_len = 64; fields(2)%offset_bytes = offset; offset = offset + 64
    fields(3)%field_name = 'setName';       fields(3)%data_type = IF_DATA_TYPE_CHAR; fields(3)%elem_len = 64; fields(3)%offset_bytes = offset; offset = offset + 64
    fields(4)%field_name = 'displacement';  fields(4)%data_type = IF_DATA_TYPE_DP;   fields(4)%offset_bytes = offset; offset = offset + 24
    fields(5)%field_name = 'amplitudeName'; fields(5)%data_type = IF_DATA_TYPE_CHAR; fields(5)%elem_len = 64; fields(5)%offset_bytes = offset; offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 5, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DispBCDesc_RegLayout")
  END SUBROUTINE MD_DispBCDesc_RegLayout

  SUBROUTINE MD_DispBCDesc_Ensure(this)
    CLASS(MD_DispBCDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_DISPLACEMENTBCDESC_', this%boundaryId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_DispBCDesc_Ensure")
  END SUBROUTINE MD_DispBCDesc_Ensure

  !======================================================================
  ! MD_VelBCDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_VelBCDesc_Init(this, boundaryId, name, setName, velocity, amplitudeName)
    CLASS(MD_VelBCDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: boundaryId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, setName, amplitudeName
    REAL(wp), INTENT(IN), OPTIONAL :: velocity(3)
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::VELOCITYBC')
    IF (PRESENT(boundaryId)) this%boundaryId = boundaryId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(setName)) this%setName = setName
    IF (PRESENT(velocity)) this%velocity = velocity
    IF (PRESENT(amplitudeName)) this%amplitudeName = amplitudeName
  END SUBROUTINE MD_VelBCDesc_Init

  SUBROUTINE MD_VelBCDesc_RegLayout(this)
    CLASS(MD_VelBCDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'boundaryId';    fields(1)%data_type = IF_DATA_TYPE_INT;  fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'name';          fields(2)%data_type = IF_DATA_TYPE_CHAR; fields(2)%elem_len = 64; fields(2)%offset_bytes = offset; offset = offset + 64
    fields(3)%field_name = 'setName';       fields(3)%data_type = IF_DATA_TYPE_CHAR; fields(3)%elem_len = 64; fields(3)%offset_bytes = offset; offset = offset + 64
    fields(4)%field_name = 'velocity';      fields(4)%data_type = IF_DATA_TYPE_DP;   fields(4)%offset_bytes = offset; offset = offset + 24
    fields(5)%field_name = 'amplitudeName'; fields(5)%data_type = IF_DATA_TYPE_CHAR; fields(5)%elem_len = 64; fields(5)%offset_bytes = offset; offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 5, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_VelBCDesc_RegLayout")
  END SUBROUTINE MD_VelBCDesc_RegLayout

  SUBROUTINE MD_VelBCDesc_Ensure(this)
    CLASS(MD_VelBCDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_VELOCITYBCDESC_', this%boundaryId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_VelBCDesc_Ensure")
  END SUBROUTINE MD_VelBCDesc_Ensure

  !======================================================================
  ! MD_BodyForceDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_BodyForceDesc_Init(this, loadId, name, setName, magnitude, amplitudeName)
    CLASS(MD_BodyForceDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: loadId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, setName, amplitudeName
    REAL(wp), INTENT(IN), OPTIONAL :: magnitude(3)
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::BODYFORCE')
    IF (PRESENT(loadId)) this%loadId = loadId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(setName)) this%setName = setName
    IF (PRESENT(magnitude)) this%magnitude = magnitude
    IF (PRESENT(amplitudeName)) this%amplitudeName = amplitudeName
  END SUBROUTINE MD_BodyForceDesc_Init

  SUBROUTINE MD_BodyForceDesc_RegLayout(this)
    CLASS(MD_BodyForceDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'loadId';        fields(1)%data_type = IF_DATA_TYPE_INT;  fields(1)%offset_bytes = offset; offset = offset + 4
    fields(2)%field_name = 'name';          fields(2)%data_type = IF_DATA_TYPE_CHAR; fields(2)%elem_len = 64; fields(2)%offset_bytes = offset; offset = offset + 64
    fields(3)%field_name = 'setName';       fields(3)%data_type = IF_DATA_TYPE_CHAR; fields(3)%elem_len = 64; fields(3)%offset_bytes = offset; offset = offset + 64
    fields(4)%field_name = 'magnitude';     fields(4)%data_type = IF_DATA_TYPE_DP;   fields(4)%offset_bytes = offset; offset = offset + 24
    fields(5)%field_name = 'amplitudeName'; fields(5)%data_type = IF_DATA_TYPE_CHAR; fields(5)%elem_len = 64; fields(5)%offset_bytes = offset; offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 5, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_BodyForceDesc_RegLayout")
  END SUBROUTINE MD_BodyForceDesc_RegLayout

  SUBROUTINE MD_BodyForceDesc_Ensure(this)
    CLASS(MD_BodyForceDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_BODYFORCEDESC_', this%loadId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_BodyForceDesc_Ensure")
  END SUBROUTINE MD_BodyForceDesc_Ensure

  !======================================================================
  ! MD_NeumBCDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_NeumBCDesc_RegLayout(this)
    CLASS(MD_NeumBCDesc), INTENT(INOUT) :: this
    TYPE(StructFieldDesc) :: fields(8)
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    fields(1) = StructFieldDesc("boundaryId", IF_DATA_TYPE_INT, [1,0,0,0], "Boundary condition ID")
    fields(2) = StructFieldDesc("name", IF_DATA_TYPE_CHAR, [64,0,0,0], "Boundary condition name")
    fields(3) = StructFieldDesc("surfaceName", IF_DATA_TYPE_CHAR, [64,0,0,0], "Surface set name")
    fields(4) = StructFieldDesc("tractionVector", IF_DATA_TYPE_DP, [3,0,0,0], "Traction vector (force per unit area)")
    fields(5) = StructFieldDesc("distributiontyp", IF_DATA_TYPE_INT, [1,0,0,0], "Distribution type (1=uniform, 2=linear, 3=quadratic)")
    fields(6) = StructFieldDesc("amplitudeName", IF_DATA_TYPE_CHAR, [64,0,0,0], "Amplitude function name")
    fields(7) = StructFieldDesc("isFollowerLoad", IF_DATA_TYPE_INT, [1,0,0,0], "Whether load follows deformation")
    fields(8) = StructFieldDesc("typeName", IF_DATA_TYPE_CHAR, [32,0,0,0], "Type name")
    CALL dp_register_struct_type("UF_NEUMANNBCDESC", fields, status)
    this%typeName = "UF_NEUMANNBCDESC"
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_NeumBCDesc_RegLayout")
  END SUBROUTINE MD_NeumBCDesc_RegLayout

  SUBROUTINE MD_NeumBCDesc_Ensure(this)
    CLASS(MD_NeumBCDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_NEUMANNBCDESC_', this%boundaryId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_NeumBCDesc_Ensure")
  END SUBROUTINE MD_NeumBCDesc_Ensure

  SUBROUTINE MD_NeumBCDesc_Init(this, boundaryId, name, surfaceName, tractionVector, amplitudeName, status)
    CLASS(MD_NeumBCDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: boundaryId
    CHARACTER(len=*), INTENT(IN) :: name, surfaceName, amplitudeName
    REAL(wp), INTENT(IN) :: tractionVector(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%boundaryId = boundaryId
    this%name = TRIM(name)
    this%surfaceName = TRIM(surfaceName)
    this%tractionVector = tractionVector
    this%amplitudeName = TRIM(amplitudeName)
    this%distributiontyp = 1
    this%isFollowerLoad = .false.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_NeumBCDesc_Init

  !======================================================================
  ! MD_RobinBCDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_RobinBCDesc_RegLayout(this)
    CLASS(MD_RobinBCDesc), INTENT(INOUT) :: this
    TYPE(StructFieldDesc) :: fields(9)
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    fields(1) = StructFieldDesc("boundaryId", IF_DATA_TYPE_INT, [1,0,0,0], "Boundary condition ID")
    fields(2) = StructFieldDesc("name", IF_DATA_TYPE_CHAR, [64,0,0,0], "Boundary condition name")
    fields(3) = StructFieldDesc("nodeSetName", IF_DATA_TYPE_CHAR, [64,0,0,0], "Node set name")
    fields(4) = StructFieldDesc("dofComponent", IF_DATA_TYPE_INT, [1,0,0,0], "DOF component (1=x, 2=y, 3=z, 4=temp)")
    fields(5) = StructFieldDesc("stiffnessCoeff", IF_DATA_TYPE_DP, [1,0,0,0], "Stiffness coef (k)")
    fields(6) = StructFieldDesc("convectionCoeff", IF_DATA_TYPE_DP, [1,0,0,0], "Convection coef (h)")
    fields(7) = StructFieldDesc("ambientValue", IF_DATA_TYPE_DP, [1,0,0,0], "Ambient temperature/condition (T_inf)")
    fields(8) = StructFieldDesc("amplitudeName", IF_DATA_TYPE_CHAR, [64,0,0,0], "Amplitude function name")
    fields(9) = StructFieldDesc("typeName", IF_DATA_TYPE_CHAR, [32,0,0,0], "Type name")
    CALL dp_register_struct_type("UF_ROBINBCDESC", fields, status)
    this%typeName = "UF_ROBINBCDESC"
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_RobinBCDesc_RegLayout")
  END SUBROUTINE MD_RobinBCDesc_RegLayout

  SUBROUTINE MD_RobinBCDesc_Ensure(this)
    CLASS(MD_RobinBCDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_ROBINBCDESC_', this%boundaryId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_RobinBCDesc_Ensure")
  END SUBROUTINE MD_RobinBCDesc_Ensure

  SUBROUTINE MD_RobinBCDesc_Init(this, boundaryId, name, nodeSetName, dofComponent, &
                             stiffnessCoeff, convectionCoeff, ambientValue, amplitudeName, status)
    CLASS(MD_RobinBCDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: boundaryId, dofComponent
    CHARACTER(len=*), INTENT(IN) :: name, nodeSetName, amplitudeName
    REAL(wp), INTENT(IN) :: stiffnessCoeff, convectionCoeff, ambientValue
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%boundaryId = boundaryId
    this%name = TRIM(name)
    this%nodeSetName = TRIM(nodeSetName)
    this%dofComponent = dofComponent
    this%stiffnessCoeff = stiffnessCoeff
    this%convectionCoeff = convectionCoeff
    this%ambientValue = ambientValue
    this%amplitudeName = TRIM(amplitudeName)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_RobinBCDesc_Init

  !======================================================================
  ! MD_PerBCDesc type-bound procedures
  !======================================================================
  SUBROUTINE MD_PerBCDesc_RegLayout(this)
    CLASS(MD_PerBCDesc), INTENT(INOUT) :: this
    TYPE(StructFieldDesc) :: fields(8)
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    fields(1) = StructFieldDesc("boundaryId", IF_DATA_TYPE_INT, [1,0,0,0], "Boundary condition ID")
    fields(2) = StructFieldDesc("name", IF_DATA_TYPE_CHAR, [64,0,0,0], "Boundary condition name")
    fields(3) = StructFieldDesc("masterNodeId", IF_DATA_TYPE_INT, [1,0,0,0], "Master node ID")
    fields(4) = StructFieldDesc("slaveNodeId", IF_DATA_TYPE_INT, [1,0,0,0], "Slave node ID")
    fields(5) = StructFieldDesc("dofComponent", IF_DATA_TYPE_INT, [1,0,0,0], "DOF component")
    fields(6) = StructFieldDesc("scaleFactor", IF_DATA_TYPE_DP, [1,0,0,0], "Scaling factor for periodic relation")
    fields(7) = StructFieldDesc("offsetValue", IF_DATA_TYPE_DP, [1,0,0,0], "Offset value")
    fields(8) = StructFieldDesc("typeName", IF_DATA_TYPE_CHAR, [32,0,0,0], "Type name")
    CALL dp_register_struct_type("UF_PERIODICBCDESC", fields, status)
    this%typeName = "UF_PERIODICBCDESC"
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_PerBCDesc_RegLayout")
  END SUBROUTINE MD_PerBCDesc_RegLayout

  SUBROUTINE MD_PerBCDesc_Ensure(this)
    CLASS(MD_PerBCDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_PERIODICBCDESC_', this%boundaryId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_PerBCDesc_Ensure")
  END SUBROUTINE MD_PerBCDesc_Ensure

  SUBROUTINE MD_PerBCDesc_Init(this, boundaryId, name, masterNodeId, slaveNodeId, &
                                dofComponent, scaleFactor, offsetValue, status)
    CLASS(MD_PerBCDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: boundaryId, masterNodeId, slaveNodeId, dofComponent
    CHARACTER(len=*), INTENT(IN) :: name
    REAL(wp), INTENT(IN) :: scaleFactor, offsetValue
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%boundaryId = boundaryId
    this%name = TRIM(name)
    this%masterNodeId = masterNodeId
    this%slaveNodeId = slaveNodeId
    this%dofComponent = dofComponent
    this%scaleFactor = scaleFactor
    this%offsetValue = offsetValue
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_PerBCDesc_Init

  !======================================================================
  ! MD_LdbcAlgo type-bound procedures
  !======================================================================
  SUBROUTINE MD_LdbcAlgo_Init(this, applicationmeth, penaltyFactor, updateFrequency, uselagrangemult, usepenaltymetho)
    CLASS(MD_LdbcAlgo), INTENT(INOUT) :: this
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: applicationmeth
    REAL(wp), INTENT(IN), OPTIONAL :: penaltyFactor
    INTEGER(i4), INTENT(IN), OPTIONAL :: updateFrequency
    LOGICAL, INTENT(IN), OPTIONAL :: uselagrangemult, usepenaltymetho
    CALL this%CoreBase%Init(CAT_ALGO, 'ALGO::LOADBC')
    IF (PRESENT(applicationmeth)) this%applicationmeth = applicationmeth
    IF (PRESENT(penaltyFactor)) this%penaltyFactor = penaltyFactor
    IF (PRESENT(updateFrequency)) this%updateFrequency = updateFrequency
    IF (PRESENT(uselagrangemult)) this%uselagrangemult = uselagrangemult
    IF (PRESENT(usepenaltymetho)) this%usepenaltymetho = usepenaltymetho
  END SUBROUTINE MD_LdbcAlgo_Init

  SUBROUTINE MD_LdbcAlgo_RegLayout(this)
    CLASS(MD_LdbcAlgo), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(5)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'applicationmeth'; fields(1)%data_type = IF_DATA_TYPE_CHAR; fields(1)%elem_len = 32; fields(1)%offset_bytes = offset; offset = offset + 32
    fields(2)%field_name = 'penaltyFactor';   fields(2)%data_type = IF_DATA_TYPE_DP;   fields(2)%offset_bytes = offset; offset = offset + 8
    fields(3)%field_name = 'updateFrequency'; fields(3)%data_type = IF_DATA_TYPE_INT;  fields(3)%offset_bytes = offset; offset = offset + 4
    fields(4)%field_name = 'uselagrangemult'; fields(4)%data_type = IF_DATA_TYPE_INT;  fields(4)%offset_bytes = offset; offset = offset + 4
    fields(5)%field_name = 'usepenaltymetho'; fields(5)%data_type = IF_DATA_TYPE_INT;  fields(5)%offset_bytes = offset; offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 5, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LdbcAlgo_RegLayout")
  END SUBROUTINE MD_LdbcAlgo_RegLayout

  SUBROUTINE MD_LdbcAlgo_Ensure(this)
    CLASS(MD_LdbcAlgo), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) this%varName = 'UF_LOADBCALGO'
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MD_LdbcAlgo_Ensure")
  END SUBROUTINE MD_LdbcAlgo_Ensure

  !======================================================================
  ! LoadBCTree procedures
  !======================================================================
  FUNCTION LoadBCTree_GetID(this) RESULT(id)
    CLASS(LoadBCTree), INTENT(IN) :: this
    INTEGER(i4) :: id
    id = this%node_id
    IF (id == 0) id = this%loadBCId
  END FUNCTION LoadBCTree_GetID

  FUNCTION LoadBCTree_GetName(this) RESULT(name)
    CLASS(LoadBCTree), INTENT(IN) :: this
    CHARACTER(LEN=64) :: name
    name = MD_LdbcDesc_GetName(this)
  END FUNCTION LoadBCTree_GetName

  FUNCTION LoadBCTree_GetType(this) RESULT(ntype)
    CLASS(LoadBCTree), INTENT(IN) :: this
    INTEGER(i4) :: ntype
    ntype = NODE_TYPE_LOADB
  END FUNCTION LoadBCTree_GetType

  FUNCTION LoadBCTree_GetParentID(this) RESULT(pid)
    CLASS(LoadBCTree), INTENT(IN) :: this
    INTEGER(i4) :: pid
    pid = this%parent_id
  END FUNCTION LoadBCTree_GetParentID

  FUNCTION LoadBCTree_GetByPath(this, path_str) RESULT(obj_ptr)
    CLASS(LoadBCTree), INTENT(IN), TARGET :: this
    CHARACTER(LEN=*), INTENT(IN) :: path_str
    CLASS(TreeNodeBase), POINTER :: obj_ptr
    TYPE(PathComponents) :: components
    obj_ptr => NULL()
    IF (.NOT. this%tree_initialize) RETURN
    components = this%path_resolver%ParsePath(path_str)
    IF (components%GetCount() == 0) THEN
      obj_ptr => this
      RETURN
    END IF
    obj_ptr => this
  END FUNCTION LoadBCTree_GetByPath

  FUNCTION LoadBCTree_GetFullPath(this) RESULT(path_str)
    CLASS(LoadBCTree), INTENT(IN) :: this
    CHARACTER(LEN=512) :: path_str
    CHARACTER(LEN=64) :: name
    name = this%GetName()
    IF (LEN_TRIM(name) > 0) THEN
      path_str = '/LoadBC/' // TRIM(name)
    ELSE
      WRITE(path_str, '(A,I0)') '/LoadBC/LoadBC_', this%GetID()
    END IF
  END FUNCTION LoadBCTree_GetFullPath

  SUBROUTINE LoadBCTree_InitTree(this, initial_capacit, status)
    CLASS(LoadBCTree), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: initial_capacit
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%node_id = this%loadBCId
    this%tree_initialize = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE LoadBCTree_InitTree

  SUBROUTINE LoadBCTree_DestroyTree(this, status)
    CLASS(LoadBCTree), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL this%index_mgr%Destroy(status)
    this%tree_initialize = .FALSE.
    CALL MD_LoadBC_Domain_Reset(g_md_loadbc_domain)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE LoadBCTree_DestroyTree

  SUBROUTINE LoadBCTree_RebuildIndex(this, status)
    CLASS(LoadBCTree), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%tree_initialize) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    CALL this%index_mgr%Rebuild(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE LoadBCTree_RebuildIndex

  SUBROUTINE LoadBCTree_ValidateTree(this, status)
    CLASS(LoadBCTree), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. this%tree_initialize) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Tree not initialized"
      RETURN
    END IF
    CALL this%index_mgr%Valid(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE LoadBCTree_ValidateTree

  SUBROUTINE LoadBCTree_Serialize(this, serializer)
    CLASS(LoadBCTree), INTENT(IN) :: this
    CLASS(TreeSerializer), INTENT(INOUT) :: serializer
    TYPE(ErrorStatusType) :: status
    CALL serializer%BeginObject("LoadBCTree", status)
    CALL serializer%WriteInt(this%loadBCId, status)
    CALL serializer%WriteString(this%GetName(), status)
    CALL serializer%WriteString(this%loadBCType, status)
    CALL serializer%WriteString(this%region, status)
    CALL serializer%WriteString(this%amplitudeName, status)
    CALL serializer%WriteString(this%timeFunctionName, status)
    CALL serializer%WriteReal(this%value, status)
    CALL serializer%WriteString(this%cfg%description, status)
    CALL serializer%WriteInt(this%node_id, status)
    CALL serializer%WriteInt(this%parent_id, status)
    CALL serializer%WriteBool(this%is_active, status)
    CALL serializer%WriteBool(this%is_visible, status)
    IF (ALLOCATED(this%dofs)) THEN
      CALL serializer%BeginArray("DOFs", status)
      CALL serializer%WriteArrayInt(this%dofs, status)
      CALL serializer%EndArray(status)
    END IF
    IF (ALLOCATED(this%direction)) THEN
      CALL serializer%BeginArray("Direction", status)
      CALL serializer%WriteArrayReal(this%direction, status)
      CALL serializer%EndArray(status)
    END IF
    CALL serializer%EndObject(status)
  END SUBROUTINE LoadBCTree_Serialize

  SUBROUTINE LoadBCTree_Deserialize(this, deserializer)
    CLASS(LoadBCTree), INTENT(INOUT) :: this
    CLASS(TreeDeserializer), INTENT(IN) :: deserializer
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: obj_name
    obj_name = deserializer%BeginObject(status)
    this%loadBCId = deserializer%ReadInt(status)
    this%name_legacy = deserializer%ReadString(status)
    this%loadBCType = deserializer%ReadString(status)
    this%region = deserializer%ReadString(status)
    this%amplitudeName = deserializer%ReadString(status)
    this%timeFunctionName = deserializer%ReadString(status)
    this%value = deserializer%ReadReal(status)
    this%cfg%description = deserializer%ReadString(status)
    this%node_id = deserializer%ReadInt(status)
    this%parent_id = deserializer%ReadInt(status)
    this%is_active = deserializer%ReadBool(status)
    this%is_visible = deserializer%ReadBool(status)
    obj_name = deserializer%BeginArray(status)
    IF (LEN_TRIM(obj_name) > 0) THEN
      CALL deserializer%ReadArrayInt(this%dofs, status)
      CALL deserializer%EndArray(status)
    END IF
    obj_name = deserializer%BeginArray(status)
    IF (LEN_TRIM(obj_name) > 0) THEN
      CALL deserializer%ReadArrayReal(this%direction, status)
      CALL deserializer%EndArray(status)
    END IF
    IF (.NOT. this%tree_initialize) CALL this%InitTree(status=status)
    CALL this%RebuildIndex(status)
    CALL deserializer%EndObject(status)
  END SUBROUTINE LoadBCTree_Deserialize

  SUBROUTINE LoadBCTree_BeginBatch(this, max_size)
    CLASS(LoadBCTree), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_size
    CALL this%batch_mgr%BeginBatch(max_size)
  END SUBROUTINE LoadBCTree_BeginBatch

  SUBROUTINE LoadBCTree_EndBatch(this, rebuild_index, status)
    CLASS(LoadBCTree), INTENT(INOUT) :: this
    LOGICAL, INTENT(IN), OPTIONAL :: rebuild_index
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(ErrorStatusType) :: local_status
    CALL this%batch_mgr%EndBatch(rebuild_index, local_status)
    IF (PRESENT(rebuild_index) .AND. rebuild_index) CALL this%RebuildIndex(local_status)
    IF (PRESENT(status)) status = local_status
  END SUBROUTINE LoadBCTree_EndBatch

  !======================================================================
  ! Domain Lifecycle (MD_LoadBC_Domain_*)
  !======================================================================
  SUBROUTINE MD_LoadBC_Domain_Init(domain, model)
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(INOUT) :: domain
    TYPE(UF_Model), INTENT(IN), TARGET :: model
    domain%desc%nLoadBCs = 0_i4
    domain%state%nLoadBCs = 0_i4
    domain%state%stepId = -1_i4
    domain%state%time = 0.0_wp
    domain%algo%nLoadBCs = 0_i4
    domain%algo%maxLoadBCId = 0_i4
    domain%ctx%currentLoadBCId = 0_i4
    domain%ctx%time = 0.0_wp
    domain%ctx%model => model
    NULLIFY(domain%ctx%step, domain%ctx%F)
  END SUBROUTINE MD_LoadBC_Domain_Init

  SUBROUTINE MD_LoadBC_Domain_Reset(domain)
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(INOUT) :: domain
    IF (ALLOCATED(domain%state%isActive))      domain%state%isActive(:) = .FALSE.
    IF (ALLOCATED(domain%state%currentValue))  domain%state%currentValue(:) = 0.0_wp
    IF (ALLOCATED(domain%state%currentTime))   domain%state%currentTime(:) = 0.0_wp
    domain%state%stepId = -1_i4;  domain%state%time = 0.0_wp;  domain%state%nLoadBCs = 0_i4
    IF (ALLOCATED(domain%algo%idToIndexMap))    domain%algo%idToIndexMap(:) = 0_i4
    domain%algo%nLoadBCs = 0_i4;  domain%algo%maxLoadBCId = 0_i4
  END SUBROUTINE MD_LoadBC_Domain_Reset

  SUBROUTINE MD_LoadBC_Domain_Finalize(domain)
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(INOUT) :: domain
    IF (ALLOCATED(domain%desc%loadBCId))       DEALLOCATE(domain%desc%loadBCId)
    IF (ALLOCATED(domain%desc%name))           DEALLOCATE(domain%desc%name)
    IF (ALLOCATED(domain%desc%loadBCType))     DEALLOCATE(domain%desc%loadBCType)
    IF (ALLOCATED(domain%desc%region))         DEALLOCATE(domain%desc%region)
    IF (ALLOCATED(domain%desc%dofs))           DEALLOCATE(domain%desc%dofs)
    IF (ALLOCATED(domain%desc%nDofsPerLoadBC)) DEALLOCATE(domain%desc%nDofsPerLoadBC)
    IF (ALLOCATED(domain%desc%amplitudeName))  DEALLOCATE(domain%desc%amplitudeName)
    IF (ALLOCATED(domain%desc%timeFunctionName)) DEALLOCATE(domain%desc%timeFunctionName)
    IF (ALLOCATED(domain%desc%value))          DEALLOCATE(domain%desc%value)
    IF (ALLOCATED(domain%desc%direction))      DEALLOCATE(domain%desc%direction)
    IF (ALLOCATED(domain%desc%cfg%description))    DEALLOCATE(domain%desc%cfg%description)
    IF (ALLOCATED(domain%desc%bcIndices))      DEALLOCATE(domain%desc%bcIndices)
    IF (ALLOCATED(domain%desc%cloadIndices))   DEALLOCATE(domain%desc%cloadIndices)
    IF (ALLOCATED(domain%desc%dloadIndices))   DEALLOCATE(domain%desc%dloadIndices)
    IF (ALLOCATED(domain%desc%bforceIndices))  DEALLOCATE(domain%desc%bforceIndices)
    IF (ALLOCATED(domain%desc%stepMapping))    DEALLOCATE(domain%desc%stepMapping)
    IF (ALLOCATED(domain%state%loadBCId))      DEALLOCATE(domain%state%loadBCId)
    IF (ALLOCATED(domain%state%isActive))      DEALLOCATE(domain%state%isActive)
    IF (ALLOCATED(domain%state%F_applied))     DEALLOCATE(domain%state%F_applied)
    IF (ALLOCATED(domain%state%u_prescribed))  DEALLOCATE(domain%state%u_prescribed)
    IF (ALLOCATED(domain%state%currentValue))  DEALLOCATE(domain%state%currentValue)
    IF (ALLOCATED(domain%state%currentTime))   DEALLOCATE(domain%state%currentTime)
    IF (ALLOCATED(domain%algo%applicationMethod))    DEALLOCATE(domain%algo%applicationMethod)
    IF (ALLOCATED(domain%algo%penaltyFactor))        DEALLOCATE(domain%algo%penaltyFactor)
    IF (ALLOCATED(domain%algo%updateFrequency))      DEALLOCATE(domain%algo%updateFrequency)
    IF (ALLOCATED(domain%algo%useLagrangeMultiplier)) DEALLOCATE(domain%algo%useLagrangeMultiplier)
    IF (ALLOCATED(domain%algo%usePenaltyMethod))     DEALLOCATE(domain%algo%usePenaltyMethod)
    IF (ALLOCATED(domain%algo%idToIndexMap))          DEALLOCATE(domain%algo%idToIndexMap)
    NULLIFY(domain%ctx%model, domain%ctx%step, domain%ctx%F)
    domain%desc%nLoadBCs = 0_i4
    domain%state%nLoadBCs = 0_i4;  domain%state%state_capacity = 0_i4
    domain%state%stepId = -1_i4;   domain%state%time = 0.0_wp
    domain%algo%nLoadBCs = 0_i4;   domain%algo%idxMap_capacity = 0_i4;  domain%algo%maxLoadBCId = 0_i4
    domain%ctx%currentLoadBCId = 0_i4;  domain%ctx%time = 0.0_wp
  END SUBROUTINE MD_LoadBC_Domain_Finalize

  SUBROUTINE MD_LoadBC_Domain_SyncFromStep(domain, step)
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(INOUT) :: domain
    TYPE(StepDef), INTENT(IN) :: step
    TYPE(LoadB) :: loadbc_mgr
    INTEGER(i4) :: nTotal, i, idx, maxId, nDofs
    INTEGER(i4) :: nBCs, nCLoads, nDLoads, nBForces
    loadbc_mgr = step%loadbc
    nBCs = loadbc_mgr%numBCs;  nCLoads = loadbc_mgr%numCLoads
    nDLoads = loadbc_mgr%numDLoads;  nBForces = loadbc_mgr%numBForces
    nTotal = nBCs + nCLoads + nDLoads + nBForces
    IF (nTotal > domain%desc%nLoadBCs) THEN
      maxId = 0_i4
      DO i = 1, nBCs
        IF (ALLOCATED(loadbc_mgr%bcs)) maxId = MAX(maxId, loadbc_mgr%bcs(i)%boundaryId)
      END DO
      DO i = 1, nCLoads
        IF (ALLOCATED(loadbc_mgr%cloads)) maxId = MAX(maxId, loadbc_mgr%cloads(i)%loadId)
      END DO
      DO i = 1, nDLoads
        IF (ALLOCATED(loadbc_mgr%dloads)) maxId = MAX(maxId, loadbc_mgr%dloads(i)%loadId)
      END DO
      DO i = 1, nBForces
        IF (ALLOCATED(loadbc_mgr%bforces)) maxId = MAX(maxId, loadbc_mgr%bforces(i)%loadId)
      END DO
      IF (.NOT. ALLOCATED(domain%desc%loadBCId)) THEN
        ALLOCATE(domain%desc%loadBCId(nTotal), domain%desc%name(nTotal), domain%desc%loadBCType(nTotal))
        ALLOCATE(domain%desc%region(nTotal), domain%desc%dofs(nTotal, 6), domain%desc%nDofsPerLoadBC(nTotal))
        ALLOCATE(domain%desc%amplitudeName(nTotal), domain%desc%timeFunctionName(nTotal))
        ALLOCATE(domain%desc%value(nTotal), domain%desc%direction(nTotal, 3), domain%desc%cfg%description(nTotal))
      ELSE IF (nTotal > SIZE(domain%desc%loadBCId)) THEN
        DEALLOCATE(domain%desc%loadBCId, domain%desc%name, domain%desc%loadBCType, &
                   domain%desc%region, domain%desc%dofs, domain%desc%nDofsPerLoadBC, &
                   domain%desc%amplitudeName, domain%desc%timeFunctionName, &
                   domain%desc%value, domain%desc%direction, domain%desc%cfg%description)
        ALLOCATE(domain%desc%loadBCId(nTotal), domain%desc%name(nTotal), domain%desc%loadBCType(nTotal))
        ALLOCATE(domain%desc%region(nTotal), domain%desc%dofs(nTotal, 6), domain%desc%nDofsPerLoadBC(nTotal))
        ALLOCATE(domain%desc%amplitudeName(nTotal), domain%desc%timeFunctionName(nTotal))
        ALLOCATE(domain%desc%value(nTotal), domain%desc%direction(nTotal, 3), domain%desc%cfg%description(nTotal))
      END IF
      IF (.NOT. ALLOCATED(domain%state%loadBCId)) THEN
        ALLOCATE(domain%state%loadBCId(nTotal), domain%state%isActive(nTotal))
        ALLOCATE(domain%state%currentValue(nTotal), domain%state%currentTime(nTotal))
        domain%state%state_capacity = nTotal
      ELSE IF (nTotal > domain%state%state_capacity) THEN
        DEALLOCATE(domain%state%loadBCId, domain%state%isActive, domain%state%currentValue, domain%state%currentTime)
        ALLOCATE(domain%state%loadBCId(nTotal), domain%state%isActive(nTotal))
        ALLOCATE(domain%state%currentValue(nTotal), domain%state%currentTime(nTotal))
        domain%state%state_capacity = nTotal
      END IF
      IF (maxId > domain%algo%maxLoadBCId) THEN
        IF (ALLOCATED(domain%algo%idToIndexMap)) DEALLOCATE(domain%algo%idToIndexMap)
        ALLOCATE(domain%algo%idToIndexMap(maxId))
        domain%algo%idToIndexMap(:) = 0_i4
        domain%algo%maxLoadBCId = maxId;  domain%algo%idxMap_capacity = maxId
      END IF
    END IF
    domain%desc%nLoadBCs = 0_i4;  idx = 0_i4
    IF (ALLOCATED(loadbc_mgr%bcs)) THEN
      DO i = 1, nBCs
        idx = idx + 1
        domain%desc%loadBCId(idx) = loadbc_mgr%bcs(i)%boundaryId
        domain%desc%name(idx) = loadbc_mgr%bcs(i)%name
        domain%desc%loadBCType(idx) = loadbc_mgr%bcs(i)%boundaryType
        domain%desc%region(idx) = loadbc_mgr%bcs(i)%setName
        domain%desc%amplitudeName(idx) = loadbc_mgr%bcs(i)%amplitudeName
        domain%desc%value(idx) = loadbc_mgr%bcs(i)%displacement(1)
        domain%desc%nDofsPerLoadBC(idx) = 1;  domain%desc%dofs(idx, 1) = 1
        domain%state%loadBCId(idx) = loadbc_mgr%bcs(i)%boundaryId
        domain%state%isActive(idx) = .TRUE.
        domain%state%currentValue(idx) = 0.0_wp;  domain%state%currentTime(idx) = 0.0_wp
        IF (loadbc_mgr%bcs(i)%boundaryId > 0 .AND. loadbc_mgr%bcs(i)%boundaryId <= domain%algo%maxLoadBCId) &
          domain%algo%idToIndexMap(loadbc_mgr%bcs(i)%boundaryId) = idx
      END DO
    END IF
    IF (ALLOCATED(loadbc_mgr%cloads)) THEN
      DO i = 1, nCLoads
        idx = idx + 1
        domain%desc%loadBCId(idx) = loadbc_mgr%cloads(i)%loadId
        domain%desc%name(idx) = loadbc_mgr%cloads(i)%name
        domain%desc%loadBCType(idx) = "CLOAD"
        domain%desc%region(idx) = loadbc_mgr%cloads(i)%setName
        domain%desc%amplitudeName(idx) = loadbc_mgr%cloads(i)%amplitudeName
        domain%desc%value(idx) = SQRT(SUM(loadbc_mgr%cloads(i)%force(:)**2))
        domain%desc%direction(idx, :) = loadbc_mgr%cloads(i)%force(:) / MAX(domain%desc%value(idx), 1.0e-10_wp)
        domain%desc%nDofsPerLoadBC(idx) = 3;  domain%desc%dofs(idx, 1:3) = [1, 2, 3]
        domain%state%loadBCId(idx) = loadbc_mgr%cloads(i)%loadId
        domain%state%isActive(idx) = .TRUE.
        domain%state%currentValue(idx) = 0.0_wp;  domain%state%currentTime(idx) = 0.0_wp
        IF (loadbc_mgr%cloads(i)%loadId > 0 .AND. loadbc_mgr%cloads(i)%loadId <= domain%algo%maxLoadBCId) &
          domain%algo%idToIndexMap(loadbc_mgr%cloads(i)%loadId) = idx
      END DO
    END IF
    IF (ALLOCATED(loadbc_mgr%dloads)) THEN
      DO i = 1, nDLoads
        idx = idx + 1
        domain%desc%loadBCId(idx) = loadbc_mgr%dloads(i)%loadId
        domain%desc%name(idx) = loadbc_mgr%dloads(i)%name
        domain%desc%loadBCType(idx) = "DLOAD"
        domain%desc%region(idx) = loadbc_mgr%dloads(i)%setName
        domain%desc%amplitudeName(idx) = loadbc_mgr%dloads(i)%amplitudeName
        domain%desc%value(idx) = loadbc_mgr%dloads(i)%magnitude
        domain%desc%direction(idx, :) = loadbc_mgr%dloads(i)%direction(:)
        domain%desc%nDofsPerLoadBC(idx) = 3;  domain%desc%dofs(idx, 1:3) = [1, 2, 3]
        domain%state%loadBCId(idx) = loadbc_mgr%dloads(i)%loadId
        domain%state%isActive(idx) = .TRUE.
        domain%state%currentValue(idx) = 0.0_wp;  domain%state%currentTime(idx) = 0.0_wp
        IF (loadbc_mgr%dloads(i)%loadId > 0 .AND. loadbc_mgr%dloads(i)%loadId <= domain%algo%maxLoadBCId) &
          domain%algo%idToIndexMap(loadbc_mgr%dloads(i)%loadId) = idx
      END DO
    END IF
    IF (ALLOCATED(loadbc_mgr%bforces)) THEN
      DO i = 1, nBForces
        idx = idx + 1
        domain%desc%loadBCId(idx) = loadbc_mgr%bforces(i)%loadId
        domain%desc%name(idx) = loadbc_mgr%bforces(i)%name
        domain%desc%loadBCType(idx) = "BFORCE"
        domain%desc%region(idx) = ""
        domain%desc%amplitudeName(idx) = loadbc_mgr%bforces(i)%amplitudeName
        domain%desc%value(idx) = SQRT(SUM(loadbc_mgr%bforces(i)%force(:)**2))
        domain%desc%direction(idx, :) = loadbc_mgr%bforces(i)%force(:) / MAX(domain%desc%value(idx), 1.0e-10_wp)
        domain%desc%nDofsPerLoadBC(idx) = 3;  domain%desc%dofs(idx, 1:3) = [1, 2, 3]
        domain%state%loadBCId(idx) = loadbc_mgr%bforces(i)%loadId
        domain%state%isActive(idx) = .TRUE.
        domain%state%currentValue(idx) = 0.0_wp;  domain%state%currentTime(idx) = 0.0_wp
        IF (loadbc_mgr%bforces(i)%loadId > 0 .AND. loadbc_mgr%bforces(i)%loadId <= domain%algo%maxLoadBCId) &
          domain%algo%idToIndexMap(loadbc_mgr%bforces(i)%loadId) = idx
      END DO
    END IF
    domain%desc%nLoadBCs = idx;  domain%state%nLoadBCs = idx;  domain%algo%nLoadBCs = idx
    domain%state%stepId = step%stepNumber;  domain%state%time = step%startTime
    IF (ALLOCATED(domain%desc%bcIndices))     DEALLOCATE(domain%desc%bcIndices)
    IF (ALLOCATED(domain%desc%cloadIndices))  DEALLOCATE(domain%desc%cloadIndices)
    IF (ALLOCATED(domain%desc%dloadIndices))  DEALLOCATE(domain%desc%dloadIndices)
    IF (ALLOCATED(domain%desc%bforceIndices)) DEALLOCATE(domain%desc%bforceIndices)
    IF (nBCs > 0) THEN
      ALLOCATE(domain%desc%bcIndices(nBCs)); domain%desc%bcIndices = [(i, i=1, nBCs)]
    END IF
    IF (nCLoads > 0) THEN
      ALLOCATE(domain%desc%cloadIndices(nCLoads)); domain%desc%cloadIndices = [(i, i=nBCs+1, nBCs+nCLoads)]
    END IF
    IF (nDLoads > 0) THEN
      ALLOCATE(domain%desc%dloadIndices(nDLoads)); domain%desc%dloadIndices = [(i, i=nBCs+nCLoads+1, nBCs+nCLoads+nDLoads)]
    END IF
    IF (nBForces > 0) THEN
      ALLOCATE(domain%desc%bforceIndices(nBForces)); domain%desc%bforceIndices = [(i, i=nBCs+nCLoads+nDLoads+1, nTotal)]
    END IF
  END SUBROUTINE MD_LoadBC_Domain_SyncFromStep

  !======================================================================
  ! Table Lifecycle (MD_LoadBC_Table_*)
  !======================================================================
  SUBROUTINE MD_LoadBC_Table_Init(domain, status)
    TYPE(MD_LoadBC_TableDomain), INTENT(INOUT) :: domain
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    domain%desc%nLoads = 0_i4;  domain%state%nLoads = 0_i4
    domain%state%stepId = -1_i4;  domain%state%time = 0.0_wp
    domain%algo%nLoads = 0_i4;  domain%algo%maxLoadId = 0_i4
    domain%ctx%currentLoadId = 0_i4;  domain%ctx%time = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_LoadBC_Table_Init

  SUBROUTINE MD_LoadBC_Table_Reset(domain)
    TYPE(MD_LoadBC_TableDomain), INTENT(INOUT) :: domain
    IF (ALLOCATED(domain%state%isActive))     domain%state%isActive(:) = .FALSE.
    IF (ALLOCATED(domain%state%currentValue)) domain%state%currentValue(:) = 0.0_wp
    IF (ALLOCATED(domain%state%currentTime))  domain%state%currentTime(:) = 0.0_wp
    domain%state%stepId = -1_i4;  domain%state%time = 0.0_wp;  domain%state%nLoads = 0_i4
    IF (ALLOCATED(domain%algo%idToIndexMap))   domain%algo%idToIndexMap(:) = 0_i4
    domain%algo%nLoads = 0_i4;  domain%algo%maxLoadId = 0_i4
  END SUBROUTINE MD_LoadBC_Table_Reset

  SUBROUTINE MD_LoadBC_Table_Finalize(domain)
    TYPE(MD_LoadBC_TableDomain), INTENT(INOUT) :: domain
    IF (ALLOCATED(domain%desc%loadId))        DEALLOCATE(domain%desc%loadId)
    IF (ALLOCATED(domain%desc%name))          DEALLOCATE(domain%desc%name)
    IF (ALLOCATED(domain%desc%loadType))      DEALLOCATE(domain%desc%loadType)
    IF (ALLOCATED(domain%desc%region))        DEALLOCATE(domain%desc%region)
    IF (ALLOCATED(domain%desc%magnitude))     DEALLOCATE(domain%desc%magnitude)
    IF (ALLOCATED(domain%desc%direction))     DEALLOCATE(domain%desc%direction)
    IF (ALLOCATED(domain%desc%amplitudeName)) DEALLOCATE(domain%desc%amplitudeName)
    IF (ALLOCATED(domain%desc%cfg%description))   DEALLOCATE(domain%desc%cfg%description)
    IF (ALLOCATED(domain%desc%cloadIndices))  DEALLOCATE(domain%desc%cloadIndices)
    IF (ALLOCATED(domain%desc%dloadIndices))  DEALLOCATE(domain%desc%dloadIndices)
    IF (ALLOCATED(domain%desc%bforceIndices)) DEALLOCATE(domain%desc%bforceIndices)
    IF (ALLOCATED(domain%state%loadId))       DEALLOCATE(domain%state%loadId)
    IF (ALLOCATED(domain%state%isActive))     DEALLOCATE(domain%state%isActive)
    IF (ALLOCATED(domain%state%F_applied))    DEALLOCATE(domain%state%F_applied)
    IF (ALLOCATED(domain%state%currentValue)) DEALLOCATE(domain%state%currentValue)
    IF (ALLOCATED(domain%state%currentTime))  DEALLOCATE(domain%state%currentTime)
    IF (ALLOCATED(domain%algo%idToIndexMap))  DEALLOCATE(domain%algo%idToIndexMap)
    domain%desc%nLoads = 0_i4;  domain%state%nLoads = 0_i4;  domain%state%state_capacity = 0_i4
    domain%algo%nLoads = 0_i4;  domain%algo%idxMap_capacity = 0_i4;  domain%algo%maxLoadId = 0_i4
    domain%ctx%currentLoadId = 0_i4;  domain%ctx%time = 0.0_wp
  END SUBROUTINE MD_LoadBC_Table_Finalize

  SUBROUTINE MD_LoadBC_Table_SyncFromStep(domain, step)
    TYPE(MD_LoadBC_TableDomain), INTENT(INOUT) :: domain
    TYPE(StepDef), INTENT(IN) :: step
    TYPE(LoadB) :: loadbc_mgr
    INTEGER(i4) :: nTotal, i, idx, maxId, nCLoads, nDLoads, nBForces
    loadbc_mgr = step%loadbc
    nCLoads = loadbc_mgr%numCLoads;  nDLoads = loadbc_mgr%numDLoads;  nBForces = loadbc_mgr%numBForces
    nTotal = nCLoads + nDLoads + nBForces
    IF (nTotal > domain%desc%nLoads) THEN
      maxId = 0_i4
      DO i = 1, nCLoads
        IF (ALLOCATED(loadbc_mgr%cloads)) maxId = MAX(maxId, loadbc_mgr%cloads(i)%loadId)
      END DO
      DO i = 1, nDLoads
        IF (ALLOCATED(loadbc_mgr%dloads)) maxId = MAX(maxId, loadbc_mgr%dloads(i)%loadId)
      END DO
      DO i = 1, nBForces
        IF (ALLOCATED(loadbc_mgr%bforces)) maxId = MAX(maxId, loadbc_mgr%bforces(i)%loadId)
      END DO
      IF (.NOT. ALLOCATED(domain%desc%loadId)) THEN
        ALLOCATE(domain%desc%loadId(nTotal), domain%desc%name(nTotal), domain%desc%loadType(nTotal))
        ALLOCATE(domain%desc%region(nTotal), domain%desc%magnitude(nTotal), domain%desc%direction(nTotal, 3))
        ALLOCATE(domain%desc%amplitudeName(nTotal), domain%desc%cfg%description(nTotal))
        ALLOCATE(domain%desc%cloadIndices(nTotal), domain%desc%dloadIndices(nTotal), domain%desc%bforceIndices(nTotal))
      ELSE IF (nTotal > SIZE(domain%desc%loadId)) THEN
        DEALLOCATE(domain%desc%loadId, domain%desc%name, domain%desc%loadType, &
                   domain%desc%region, domain%desc%magnitude, domain%desc%direction, &
                   domain%desc%amplitudeName, domain%desc%cfg%description, &
                   domain%desc%cloadIndices, domain%desc%dloadIndices, domain%desc%bforceIndices)
        ALLOCATE(domain%desc%loadId(nTotal), domain%desc%name(nTotal), domain%desc%loadType(nTotal))
        ALLOCATE(domain%desc%region(nTotal), domain%desc%magnitude(nTotal), domain%desc%direction(nTotal, 3))
        ALLOCATE(domain%desc%amplitudeName(nTotal), domain%desc%cfg%description(nTotal))
        ALLOCATE(domain%desc%cloadIndices(nTotal), domain%desc%dloadIndices(nTotal), domain%desc%bforceIndices(nTotal))
      END IF
      IF (.NOT. ALLOCATED(domain%state%loadId)) THEN
        ALLOCATE(domain%state%loadId(nTotal), domain%state%isActive(nTotal))
        ALLOCATE(domain%state%currentValue(nTotal), domain%state%currentTime(nTotal))
        domain%state%state_capacity = nTotal
      ELSE IF (nTotal > domain%state%state_capacity) THEN
        DEALLOCATE(domain%state%loadId, domain%state%isActive, domain%state%currentValue, domain%state%currentTime)
        ALLOCATE(domain%state%loadId(nTotal), domain%state%isActive(nTotal))
        ALLOCATE(domain%state%currentValue(nTotal), domain%state%currentTime(nTotal))
        domain%state%state_capacity = nTotal
      END IF
      IF (maxId > domain%algo%maxLoadId) THEN
        IF (ALLOCATED(domain%algo%idToIndexMap)) DEALLOCATE(domain%algo%idToIndexMap)
        ALLOCATE(domain%algo%idToIndexMap(maxId))
        domain%algo%idToIndexMap(:) = 0_i4
        domain%algo%maxLoadId = maxId;  domain%algo%idxMap_capacity = maxId
      END IF
    END IF
    domain%desc%nLoads = 0_i4;  idx = 0_i4
    domain%desc%cloadIndices(:) = 0_i4;  domain%desc%dloadIndices(:) = 0_i4;  domain%desc%bforceIndices(:) = 0_i4
    IF (ALLOCATED(loadbc_mgr%cloads)) THEN
      DO i = 1, nCLoads
        idx = idx + 1
        domain%desc%loadId(idx) = loadbc_mgr%cloads(i)%loadId
        domain%desc%name(idx) = loadbc_mgr%cloads(i)%name
        domain%desc%loadType(idx) = "CLOAD"
        domain%desc%region(idx) = loadbc_mgr%cloads(i)%setName
        domain%desc%magnitude(idx) = SQRT(SUM(loadbc_mgr%cloads(i)%force(:)**2))
        domain%desc%direction(idx, :) = loadbc_mgr%cloads(i)%force(:) / MAX(domain%desc%magnitude(idx), 1.0e-10_wp)
        domain%desc%amplitudeName(idx) = loadbc_mgr%cloads(i)%amplitudeName
        domain%desc%cfg%description(idx) = "";  domain%desc%cloadIndices(idx) = i
        domain%state%loadId(idx) = loadbc_mgr%cloads(i)%loadId
        domain%state%isActive(idx) = .TRUE.
        domain%state%currentValue(idx) = 0.0_wp;  domain%state%currentTime(idx) = 0.0_wp
        IF (loadbc_mgr%cloads(i)%loadId > 0 .AND. loadbc_mgr%cloads(i)%loadId <= domain%algo%maxLoadId) &
          domain%algo%idToIndexMap(loadbc_mgr%cloads(i)%loadId) = idx
      END DO
    END IF
    IF (ALLOCATED(loadbc_mgr%dloads)) THEN
      DO i = 1, nDLoads
        idx = idx + 1
        domain%desc%loadId(idx) = loadbc_mgr%dloads(i)%loadId
        domain%desc%name(idx) = loadbc_mgr%dloads(i)%name
        domain%desc%loadType(idx) = "DLOAD"
        domain%desc%region(idx) = loadbc_mgr%dloads(i)%setName
        domain%desc%magnitude(idx) = loadbc_mgr%dloads(i)%magnitude
        domain%desc%direction(idx, :) = loadbc_mgr%dloads(i)%direction(:)
        domain%desc%amplitudeName(idx) = loadbc_mgr%dloads(i)%amplitudeName
        domain%desc%cfg%description(idx) = "";  domain%desc%dloadIndices(idx) = i
        domain%state%loadId(idx) = loadbc_mgr%dloads(i)%loadId
        domain%state%isActive(idx) = .TRUE.
        domain%state%currentValue(idx) = 0.0_wp;  domain%state%currentTime(idx) = 0.0_wp
        IF (loadbc_mgr%dloads(i)%loadId > 0 .AND. loadbc_mgr%dloads(i)%loadId <= domain%algo%maxLoadId) &
          domain%algo%idToIndexMap(loadbc_mgr%dloads(i)%loadId) = idx
      END DO
    END IF
    IF (ALLOCATED(loadbc_mgr%bforces)) THEN
      DO i = 1, nBForces
        idx = idx + 1
        domain%desc%loadId(idx) = loadbc_mgr%bforces(i)%loadId
        domain%desc%name(idx) = loadbc_mgr%bforces(i)%name
        domain%desc%loadType(idx) = "BFORCE"
        domain%desc%region(idx) = ""
        domain%desc%magnitude(idx) = SQRT(SUM(loadbc_mgr%bforces(i)%magnitude(:)**2))
        domain%desc%direction(idx, :) = loadbc_mgr%bforces(i)%magnitude(:) / MAX(domain%desc%magnitude(idx), 1.0e-10_wp)
        domain%desc%amplitudeName(idx) = loadbc_mgr%bforces(i)%amplitudeName
        domain%desc%cfg%description(idx) = "";  domain%desc%bforceIndices(idx) = i
        domain%state%loadId(idx) = loadbc_mgr%bforces(i)%loadId
        domain%state%isActive(idx) = .TRUE.
        domain%state%currentValue(idx) = 0.0_wp;  domain%state%currentTime(idx) = 0.0_wp
        IF (loadbc_mgr%bforces(i)%loadId > 0 .AND. loadbc_mgr%bforces(i)%loadId <= domain%algo%maxLoadId) &
          domain%algo%idToIndexMap(loadbc_mgr%bforces(i)%loadId) = idx
      END DO
    END IF
    domain%desc%nLoads = idx;  domain%state%nLoads = idx;  domain%algo%nLoads = idx
  END SUBROUTINE MD_LoadBC_Table_SyncFromStep

  !======================================================================
  ! LBCAlgo Binding Procedures (MD_LoadBC_Algo type-bound)
  !======================================================================
  SUBROUTINE LBCAlgo_Init(this)
    CLASS(MD_LoadBC_Algo), INTENT(INOUT) :: this
    this%nLoadBCs = 0_i4;  this%idxMap_capacity = 0_i4;  this%maxLoadBCId = 0_i4
  END SUBROUTINE LBCAlgo_Init

  SUBROUTINE LBCAlgo_Reset(this)
    CLASS(MD_LoadBC_Algo), INTENT(INOUT) :: this
    IF (ALLOCATED(this%idToIndexMap)) this%idToIndexMap(:) = 0_i4
    this%nLoadBCs = 0_i4;  this%maxLoadBCId = 0_i4
  END SUBROUTINE LBCAlgo_Reset

  SUBROUTINE LBCAlgo_Finalize(this)
    CLASS(MD_LoadBC_Algo), INTENT(INOUT) :: this
    IF (ALLOCATED(this%applicationMethod))      DEALLOCATE(this%applicationMethod)
    IF (ALLOCATED(this%penaltyFactor))          DEALLOCATE(this%penaltyFactor)
    IF (ALLOCATED(this%updateFrequency))        DEALLOCATE(this%updateFrequency)
    IF (ALLOCATED(this%useLagrangeMultiplier))  DEALLOCATE(this%useLagrangeMultiplier)
    IF (ALLOCATED(this%usePenaltyMethod))       DEALLOCATE(this%usePenaltyMethod)
    IF (ALLOCATED(this%idToIndexMap))           DEALLOCATE(this%idToIndexMap)
    this%nLoadBCs = 0_i4;  this%idxMap_capacity = 0_i4;  this%maxLoadBCId = 0_i4
  END SUBROUTINE LBCAlgo_Finalize

  SUBROUTINE LBCAlgo_SyncFromStep(this, domain, step)
    CLASS(MD_LoadBC_Algo), INTENT(INOUT) :: this
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(INOUT) :: domain
    TYPE(StepDef), INTENT(IN) :: step
    CALL MD_LoadBC_Domain_SyncFromStep(domain, step)
  END SUBROUTINE LBCAlgo_SyncFromStep

  SUBROUTINE LBCAlgo_SyncFromTree(this, domain, tree)
    CLASS(MD_LoadBC_Algo), INTENT(INOUT) :: this
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(INOUT) :: domain
    TYPE(LoadBCTree), INTENT(IN) :: tree
    INTEGER(i4), PARAMETER :: MAX_DOFS = 6_i4
    INTEGER(i4) :: idx, nDofs, newSize, oldSize
    CHARACTER(len=64) :: treeName
    INTEGER(i4), ALLOCATABLE :: temp_loadBCId(:), temp_nDofsPerLoadBC(:), temp_dofs(:,:)
    CHARACTER(len=64), ALLOCATABLE :: temp_name(:), temp_region(:), temp_amplitudeName(:), &
                                      temp_timeFunctionName(:), temp_description(:)
    CHARACTER(len=32), ALLOCATABLE :: temp_loadBCType(:)
    REAL(wp), ALLOCATABLE :: temp_value(:), temp_direction(:,:)
    INTEGER(i4), ALLOCATABLE :: temp_state_loadBCId(:), temp_state_isActive(:)
    REAL(wp), ALLOCATABLE :: temp_state_currentValue(:), temp_state_currentTime(:)
    treeName = tree%GetName()
    idx = 0_i4
    IF (tree%loadBCId > 0 .AND. tree%loadBCId <= this%maxLoadBCId) THEN
      IF (ALLOCATED(this%idToIndexMap)) THEN
        IF (this%idToIndexMap(tree%loadBCId) > 0) idx = this%idToIndexMap(tree%loadBCId)
      END IF
    END IF
    IF (idx == 0_i4) THEN
      domain%desc%nLoadBCs = domain%desc%nLoadBCs + 1_i4
      idx = domain%desc%nLoadBCs
      IF (.NOT. ALLOCATED(domain%desc%loadBCId)) THEN
        ALLOCATE(domain%desc%loadBCId(idx), domain%desc%name(idx), domain%desc%loadBCType(idx))
        ALLOCATE(domain%desc%region(idx), domain%desc%dofs(idx, MAX_DOFS), domain%desc%nDofsPerLoadBC(idx))
        ALLOCATE(domain%desc%amplitudeName(idx), domain%desc%timeFunctionName(idx))
        ALLOCATE(domain%desc%value(idx), domain%desc%direction(idx, 3), domain%desc%cfg%description(idx))
      ELSE IF (idx > SIZE(domain%desc%loadBCId)) THEN
        oldSize = SIZE(domain%desc%loadBCId);  newSize = idx * 2_i4
        CALL MOVE_ALLOC(domain%desc%loadBCId, temp_loadBCId)
        CALL MOVE_ALLOC(domain%desc%name, temp_name)
        CALL MOVE_ALLOC(domain%desc%loadBCType, temp_loadBCType)
        CALL MOVE_ALLOC(domain%desc%region, temp_region)
        CALL MOVE_ALLOC(domain%desc%dofs, temp_dofs)
        CALL MOVE_ALLOC(domain%desc%nDofsPerLoadBC, temp_nDofsPerLoadBC)
        CALL MOVE_ALLOC(domain%desc%amplitudeName, temp_amplitudeName)
        CALL MOVE_ALLOC(domain%desc%timeFunctionName, temp_timeFunctionName)
        CALL MOVE_ALLOC(domain%desc%value, temp_value)
        CALL MOVE_ALLOC(domain%desc%direction, temp_direction)
        CALL MOVE_ALLOC(domain%desc%cfg%description, temp_description)
        ALLOCATE(domain%desc%loadBCId(newSize), domain%desc%name(newSize), domain%desc%loadBCType(newSize))
        ALLOCATE(domain%desc%region(newSize), domain%desc%dofs(newSize, MAX_DOFS), domain%desc%nDofsPerLoadBC(newSize))
        ALLOCATE(domain%desc%amplitudeName(newSize), domain%desc%timeFunctionName(newSize))
        ALLOCATE(domain%desc%value(newSize), domain%desc%direction(newSize, 3), domain%desc%cfg%description(newSize))
        domain%desc%loadBCId(1:oldSize) = temp_loadBCId(1:oldSize)
        domain%desc%name(1:oldSize) = temp_name(1:oldSize)
        domain%desc%loadBCType(1:oldSize) = temp_loadBCType(1:oldSize)
        domain%desc%region(1:oldSize) = temp_region(1:oldSize)
        domain%desc%dofs(1:oldSize, :) = temp_dofs(1:oldSize, :)
        domain%desc%nDofsPerLoadBC(1:oldSize) = temp_nDofsPerLoadBC(1:oldSize)
        domain%desc%amplitudeName(1:oldSize) = temp_amplitudeName(1:oldSize)
        domain%desc%timeFunctionName(1:oldSize) = temp_timeFunctionName(1:oldSize)
        domain%desc%value(1:oldSize) = temp_value(1:oldSize)
        domain%desc%direction(1:oldSize, :) = temp_direction(1:oldSize, :)
        domain%desc%cfg%description(1:oldSize) = temp_description(1:oldSize)
      END IF
      IF (tree%loadBCId > 0) THEN
        IF (tree%loadBCId > this%maxLoadBCId) THEN
          IF (ALLOCATED(this%idToIndexMap)) THEN
            CALL MOVE_ALLOC(this%idToIndexMap, temp_loadBCId)
            ALLOCATE(this%idToIndexMap(tree%loadBCId))
            this%idToIndexMap(1:this%maxLoadBCId) = temp_loadBCId(1:this%maxLoadBCId)
            this%idToIndexMap(this%maxLoadBCId+1:) = 0_i4
          ELSE
            ALLOCATE(this%idToIndexMap(tree%loadBCId))
            this%idToIndexMap(:) = 0_i4
          END IF
          this%maxLoadBCId = tree%loadBCId;  this%idxMap_capacity = tree%loadBCId
        END IF
        this%idToIndexMap(tree%loadBCId) = idx
      END IF
    END IF
    domain%desc%loadBCId(idx) = tree%loadBCId
    domain%desc%name(idx) = treeName
    domain%desc%loadBCType(idx) = tree%loadBCType
    domain%desc%region(idx) = tree%region
    domain%desc%amplitudeName(idx) = tree%amplitudeName
    domain%desc%timeFunctionName(idx) = tree%timeFunctionName
    domain%desc%value(idx) = tree%value
    domain%desc%cfg%description(idx) = tree%cfg%description
    IF (ALLOCATED(tree%dofs)) THEN
      nDofs = SIZE(tree%dofs)
      domain%desc%nDofsPerLoadBC(idx) = MIN(nDofs, MAX_DOFS)
      domain%desc%dofs(idx, 1:MIN(nDofs, MAX_DOFS)) = tree%dofs(1:MIN(nDofs, MAX_DOFS))
      IF (nDofs > MAX_DOFS) domain%desc%dofs(idx, MAX_DOFS+1:) = 0_i4
    ELSE
      domain%desc%nDofsPerLoadBC(idx) = 0_i4;  domain%desc%dofs(idx, :) = 0_i4
    END IF
    IF (ALLOCATED(tree%direction)) THEN
      domain%desc%direction(idx, 1:MIN(SIZE(tree%direction), 3)) = tree%direction(1:MIN(SIZE(tree%direction), 3))
      IF (SIZE(tree%direction) < 3) domain%desc%direction(idx, SIZE(tree%direction)+1:) = 0.0_wp
    ELSE
      domain%desc%direction(idx, :) = 0.0_wp
    END IF
    IF (idx > domain%state%nLoadBCs) THEN
      domain%state%nLoadBCs = idx
      IF (.NOT. ALLOCATED(domain%state%loadBCId)) THEN
        ALLOCATE(domain%state%loadBCId(idx), domain%state%isActive(idx))
        ALLOCATE(domain%state%currentValue(idx), domain%state%currentTime(idx))
        domain%state%state_capacity = idx
      ELSE IF (idx > domain%state%state_capacity) THEN
        oldSize = domain%state%state_capacity;  newSize = idx * 2_i4
        CALL MOVE_ALLOC(domain%state%loadBCId, temp_state_loadBCId)
        CALL MOVE_ALLOC(domain%state%isActive, temp_state_isActive)
        CALL MOVE_ALLOC(domain%state%currentValue, temp_state_currentValue)
        CALL MOVE_ALLOC(domain%state%currentTime, temp_state_currentTime)
        ALLOCATE(domain%state%loadBCId(newSize), domain%state%isActive(newSize))
        ALLOCATE(domain%state%currentValue(newSize), domain%state%currentTime(newSize))
        domain%state%loadBCId(1:oldSize) = temp_state_loadBCId(1:oldSize)
        domain%state%isActive(1:oldSize) = temp_state_isActive(1:oldSize)
        domain%state%currentValue(1:oldSize) = temp_state_currentValue(1:oldSize)
        domain%state%currentTime(1:oldSize) = temp_state_currentTime(1:oldSize)
        domain%state%state_capacity = newSize
      END IF
      domain%state%loadBCId(idx) = tree%loadBCId
      domain%state%isActive(idx) = tree%is_active
      domain%state%currentValue(idx) = 0.0_wp;  domain%state%currentTime(idx) = 0.0_wp
    ELSE
      domain%state%isActive(idx) = tree%is_active
    END IF
  END SUBROUTINE LBCAlgo_SyncFromTree

  SUBROUTINE LBCAlgo_GetActiveLoadsForStep(this, domain, stepId, loadList)
    CLASS(MD_LoadBC_Algo), INTENT(IN) :: this
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN) :: stepId
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: loadList(:)
    INTEGER(i4) :: i, nActive, count
    INTEGER(i4), ALLOCATABLE :: tempList(:)
    ALLOCATE(loadList(0))
    IF (domain%state%stepId /= stepId) RETURN
    nActive = 0_i4
    IF (ALLOCATED(domain%state%isActive)) THEN
      DO i = 1, domain%state%nLoadBCs
        IF (domain%state%isActive(i)) nActive = nActive + 1_i4
      END DO
    END IF
    IF (nActive > 0) THEN
      ALLOCATE(tempList(nActive));  count = 0_i4
      DO i = 1, domain%state%nLoadBCs
        IF (domain%state%isActive(i)) THEN
          count = count + 1_i4;  tempList(count) = i
        END IF
      END DO
      loadList = tempList;  DEALLOCATE(tempList)
    END IF
  END SUBROUTINE LBCAlgo_GetActiveLoadsForStep

  SUBROUTINE LBCAlgo_GetRegionNodes(this, domain, regionName, nodeList)
    CLASS(MD_LoadBC_Algo), INTENT(IN) :: this
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(IN) :: domain
    CHARACTER(len=*), INTENT(IN) :: regionName
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: nodeList(:)
    TYPE(UF_Model), POINTER :: model
    INTEGER(i4), POINTER :: nodeIds(:)
    INTEGER(i4) :: nNodes, setId
    ALLOCATE(nodeList(0))
    model => domain%ctx%model
    IF (.NOT. ASSOCIATED(model)) RETURN
    setId = Ldbc_FindNodeSetId(model, regionName)
    IF (setId > 0_i4) THEN
      CALL Ldbc_GetNodeSetNodes(model, setId, nodeIds)
      IF (ASSOCIATED(nodeIds)) THEN
        nNodes = SIZE(nodeIds)
        IF (nNodes > 0) THEN
          ALLOCATE(nodeList(nNodes));  nodeList = nodeIds(1:nNodes)
        END IF
      END IF
    END IF
  END SUBROUTINE LBCAlgo_GetRegionNodes

  SUBROUTINE LBCAlgo_GetAmplitudeFactor(this, domain, amplitudeName, time, factor)
    CLASS(MD_LoadBC_Algo), INTENT(INOUT) :: this
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(IN) :: domain
    CHARACTER(len=*), INTENT(IN) :: amplitudeName
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(OUT) :: factor
    TYPE(UF_Model), POINTER :: model
    TYPE(MD_Amp_Slot_Ctx) :: amplitudeDB
    INTEGER(i4) :: i
    CHARACTER(len=64) :: trimmedAmplitudeName
    factor = 1.0_wp
    model => domain%ctx%model
    IF (.NOT. ASSOCIATED(model)) RETURN
    trimmedAmplitudeName = TRIM(amplitudeName)
    IF (LEN_TRIM(trimmedAmplitudeName) == 0) RETURN
    IF (ALLOCATED(model%amplitudes)) THEN
      CALL amplitudeDB%init()
      DO i = 1, SIZE(model%amplitudes)
        CALL amplitudeDB%add_amplitude(model%amplitudes(i))
      END DO
      factor = MD_Amp_GetFactor(amplitudeDB, trimmedAmplitudeName, time)
      CALL amplitudeDB%clear()
    END IF
  END SUBROUTINE LBCAlgo_GetAmplitudeFactor

  SUBROUTINE LBCAlgo_GetDofIndices(this, domain, loadBCId, dofIndices)
    CLASS(MD_LoadBC_Algo), INTENT(IN) :: this
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN) :: loadBCId
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: dofIndices(:)
    INTEGER(i4) :: idx, nDofs, i
    TYPE(UF_Model), POINTER :: model
    ALLOCATE(dofIndices(0))
    idx = 0_i4
    IF (loadBCId > 0 .AND. loadBCId <= this%maxLoadBCId) THEN
      IF (ALLOCATED(this%idToIndexMap)) idx = this%idToIndexMap(loadBCId)
    END IF
    IF (idx <= 0 .OR. idx > domain%desc%nLoadBCs) RETURN
    nDofs = domain%desc%nDofsPerLoadBC(idx)
    IF (nDofs <= 0) RETURN
    model => domain%ctx%model
    IF (ASSOCIATED(model)) THEN
      ALLOCATE(dofIndices(nDofs))
      DO i = 1, nDofs
        dofIndices(i) = domain%desc%dofs(idx, i)
      END DO
    END IF
  END SUBROUTINE LBCAlgo_GetDofIndices

  SUBROUTINE LBCAlgo_WriteBack(this, domain, loadBCId, currentValue, currentTime)
    CLASS(MD_LoadBC_Algo), INTENT(INOUT) :: this
    TYPE(MD_LoadBC_Runtime_Domain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: loadBCId
    REAL(wp), INTENT(IN) :: currentValue, currentTime
    INTEGER(i4) :: idx
    idx = 0_i4
    IF (loadBCId > 0 .AND. loadBCId <= this%maxLoadBCId) THEN
      IF (ALLOCATED(this%idToIndexMap)) idx = this%idToIndexMap(loadBCId)
    END IF
    IF (idx > 0 .AND. idx <= domain%state%nLoadBCs) THEN
      domain%state%currentValue(idx) = currentValue
      domain%state%currentTime(idx) = currentTime
    END IF
  END SUBROUTINE LBCAlgo_WriteBack

  !======================================================================
  ! LBCTableAlgo Binding Procedures (MD_LoadBC_TableAlgo type-bound)
  !======================================================================
  SUBROUTINE LBCTableAlgo_Init(this)
    CLASS(MD_LoadBC_TableAlgo), INTENT(INOUT) :: this
    this%nLoads = 0_i4;  this%idxMap_capacity = 0_i4;  this%maxLoadId = 0_i4
    NULLIFY(this%amplitudeDB_cache);  this%cached_model_id = -1_i4;  this%cache_size = 0_i4
  END SUBROUTINE LBCTableAlgo_Init

  SUBROUTINE LBCTableAlgo_Reset(this)
    CLASS(MD_LoadBC_TableAlgo), INTENT(INOUT) :: this
    IF (ALLOCATED(this%idToIndexMap)) this%idToIndexMap(:) = 0_i4
    this%nLoads = 0_i4;  this%maxLoadId = 0_i4
    NULLIFY(this%amplitudeDB_cache);  this%cached_model_id = -1_i4;  this%cache_size = 0_i4
  END SUBROUTINE LBCTableAlgo_Reset

  SUBROUTINE LBCTableAlgo_Finalize(this)
    CLASS(MD_LoadBC_TableAlgo), INTENT(INOUT) :: this
    IF (ALLOCATED(this%idToIndexMap))        DEALLOCATE(this%idToIndexMap)
    IF (ALLOCATED(this%cached_regionNames))  DEALLOCATE(this%cached_regionNames)
    IF (ALLOCATED(this%cached_regionIds))    DEALLOCATE(this%cached_regionIds)
    IF (ALLOCATED(this%cached_regionTypes))  DEALLOCATE(this%cached_regionTypes)
    NULLIFY(this%amplitudeDB_cache)
    this%nLoads = 0_i4;  this%idxMap_capacity = 0_i4;  this%maxLoadId = 0_i4
    this%cached_model_id = -1_i4;  this%cache_size = 0_i4
  END SUBROUTINE LBCTableAlgo_Finalize

  SUBROUTINE LBCTableAlgo_SyncFromStep(this, domain, step)
    CLASS(MD_LoadBC_TableAlgo), INTENT(INOUT) :: this
    TYPE(MD_LoadBC_TableDomain), INTENT(INOUT) :: domain
    TYPE(StepDef), INTENT(IN) :: step
    CALL MD_LoadBC_Table_SyncFromStep(domain, step)
  END SUBROUTINE LBCTableAlgo_SyncFromStep

  SUBROUTINE LBCTableAlgo_GetActiveLoadsForStep(this, domain, stepId, loadList)
    CLASS(MD_LoadBC_TableAlgo), INTENT(IN) :: this
    TYPE(MD_LoadBC_TableDomain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN) :: stepId
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: loadList(:)
    INTEGER(i4) :: i, nActive, count
    INTEGER(i4), ALLOCATABLE :: tempList(:)
    ALLOCATE(loadList(0))
    IF (domain%state%stepId /= stepId) RETURN
    nActive = 0_i4
    IF (ALLOCATED(domain%state%isActive)) THEN
      DO i = 1, domain%state%nLoads
        IF (domain%state%isActive(i)) nActive = nActive + 1_i4
      END DO
    END IF
    IF (nActive > 0) THEN
      ALLOCATE(tempList(nActive));  count = 0_i4
      DO i = 1, domain%state%nLoads
        IF (domain%state%isActive(i)) THEN
          count = count + 1_i4;  tempList(count) = i
        END IF
      END DO
      loadList = tempList;  DEALLOCATE(tempList)
    END IF
  END SUBROUTINE LBCTableAlgo_GetActiveLoadsForStep

  SUBROUTINE LBCTableAlgo_GetRegionNodes(this, domain, regionName, nodeList)
    CLASS(MD_LoadBC_TableAlgo), INTENT(IN) :: this
    TYPE(MD_LoadBC_TableDomain), INTENT(IN) :: domain
    CHARACTER(len=*), INTENT(IN) :: regionName
    INTEGER(i4), INTENT(OUT), ALLOCATABLE :: nodeList(:)
    TYPE(UF_Model), POINTER :: model
    INTEGER(i4), POINTER :: nodeIds(:)
    INTEGER(i4) :: nNodes, setId
    ALLOCATE(nodeList(0))
    model => domain%ctx%model
    IF (.NOT. ASSOCIATED(model)) RETURN
    setId = Ldbc_FindNodeSetId(model, regionName)
    IF (setId > 0_i4) THEN
      CALL Ldbc_GetNodeSetNodes(model, setId, nodeIds)
      IF (ASSOCIATED(nodeIds)) THEN
        nNodes = SIZE(nodeIds)
        IF (nNodes > 0) THEN
          ALLOCATE(nodeList(nNodes));  nodeList = nodeIds(1:nNodes)
        END IF
      END IF
    END IF
  END SUBROUTINE LBCTableAlgo_GetRegionNodes

  SUBROUTINE LBCTableAlgo_GetAmplitudeFactor(this, domain, amplitudeName, time, factor)
    CLASS(MD_LoadBC_TableAlgo), INTENT(INOUT) :: this
    TYPE(MD_LoadBC_TableDomain), INTENT(IN) :: domain
    CHARACTER(len=*), INTENT(IN) :: amplitudeName
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(OUT) :: factor
    TYPE(UF_Model), POINTER :: model
    TYPE(MD_Amp_Slot_Ctx), POINTER :: amplitudeDB
    INTEGER(i4) :: i
    CHARACTER(len=64) :: trimmedAmplitudeName
    factor = 1.0_wp
    model => domain%ctx%model
    IF (.NOT. ASSOCIATED(model)) RETURN
    trimmedAmplitudeName = TRIM(amplitudeName)
    IF (LEN_TRIM(trimmedAmplitudeName) == 0) RETURN
    IF (ALLOCATED(model%amplitudes)) THEN
      IF (.NOT. ASSOCIATED(this%amplitudeDB_cache) .OR. this%cached_model_id /= model%cfg%id) THEN
        IF (ASSOCIATED(this%amplitudeDB_cache)) THEN
          CALL this%amplitudeDB_cache%clear();  DEALLOCATE(this%amplitudeDB_cache)
        END IF
        ALLOCATE(this%amplitudeDB_cache)
        CALL this%amplitudeDB_cache%init()
        DO i = 1, SIZE(model%amplitudes)
          CALL this%amplitudeDB_cache%add_amplitude(model%amplitudes(i))
        END DO
        this%cached_model_id = model%cfg%id
      END IF
      amplitudeDB => this%amplitudeDB_cache
      factor = MD_Amp_GetFactor(amplitudeDB, trimmedAmplitudeName, time)
    END IF
  END SUBROUTINE LBCTableAlgo_GetAmplitudeFactor

  SUBROUTINE LBCTableAlgo_WriteBack(this, domain, loadId, currentValue, currentTime)
    CLASS(MD_LoadBC_TableAlgo), INTENT(INOUT) :: this
    TYPE(MD_LoadBC_TableDomain), INTENT(INOUT) :: domain
    INTEGER(i4), INTENT(IN) :: loadId
    REAL(wp), INTENT(IN) :: currentValue, currentTime
    INTEGER(i4) :: idx
    idx = 0_i4
    IF (loadId > 0 .AND. loadId <= this%maxLoadId) THEN
      IF (ALLOCATED(this%idToIndexMap)) idx = this%idToIndexMap(loadId)
    END IF
    IF (idx > 0 .AND. idx <= domain%state%nLoads) THEN
      domain%state%currentValue(idx) = currentValue
      domain%state%currentTime(idx) = currentTime
    END IF
  END SUBROUTINE LBCTableAlgo_WriteBack

  SUBROUTINE LBCTableAlgo_ApplyToForce(this, domain, stepId, time, F, dofMap, status)
    CLASS(MD_LoadBC_TableAlgo), INTENT(INOUT) :: this
    TYPE(MD_LoadBC_TableDomain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN) :: stepId
    REAL(wp), INTENT(IN) :: time
    REAL(wp), INTENT(INOUT) :: F(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dofMap(:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4), ALLOCATABLE :: loadList(:)
    INTEGER(i4) :: i, idx, nLoads, loadTypeInt, targetTypeInt, targetId, nDOFPerNode, ic
    REAL(wp) :: factor, magnitude, direction(3)
    CHARACTER(len=32) :: loadTypeStr
    CHARACTER(len=64) :: regionName, amplitudeName
    INTEGER(i4), ALLOCATABLE :: nodeList(:)
    TYPE(UF_Model), POINTER :: model
    TYPE(LoadDef) :: tempLoadDef
    TYPE(ErrorStatusType) :: loc_stat
    IF (PRESENT(status)) CALL init_error_status(status)
    model => domain%ctx%model
    IF (.NOT. ASSOCIATED(model)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'LBCTableAlgo_ApplyToForce: model not associated in domain context'
      END IF
      RETURN
    END IF
    nDOFPerNode = 3_i4
    IF (ALLOCATED(model%parts) .AND. SIZE(model%parts) >= 1) THEN
      IF (ALLOCATED(model%parts(1)%nodes)) THEN
        IF (SIZE(F) / SIZE(model%parts(1)%nodes) >= 3) nDOFPerNode = SIZE(F) / SIZE(model%parts(1)%nodes)
      END IF
    END IF
    CALL this%GetActiveLoadsForStep(domain, stepId, loadList)
    nLoads = SIZE(loadList)
    IF (nLoads == 0) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    DO i = 1, nLoads
      idx = loadList(i)
      IF (idx < 1 .OR. idx > domain%desc%nLoads) CYCLE
      loadTypeStr = domain%desc%loadType(idx)
      regionName = domain%desc%region(idx)
      magnitude = domain%desc%magnitude(idx)
      direction = domain%desc%direction(idx, :)
      amplitudeName = domain%desc%amplitudeName(idx)
      factor = 1.0_wp
      IF (LEN_TRIM(amplitudeName) > 0) CALL this%GetAmplitudeFactor(domain, amplitudeName, time, factor)
      loadTypeInt = LOAD_CONCENTRAT
      IF (TRIM(loadTypeStr) == "CLOAD") THEN
        loadTypeInt = LOAD_CONCENTRAT
      ELSE IF (TRIM(loadTypeStr) == "DLOAD" .OR. TRIM(loadTypeStr) == "PRESSURE") THEN
        loadTypeInt = LOAD_PRESSURE
      ELSE IF (TRIM(loadTypeStr) == "BFORCE" .OR. TRIM(loadTypeStr) == "GRAVITY") THEN
        loadTypeInt = LOAD_GRAVITY
      ELSE IF (TRIM(loadTypeStr) == "BODYFORCE") THEN
        loadTypeInt = LOAD_BODY_FORCE
      END IF
      targetTypeInt = TARGET_NODE;  targetId = 0_i4
      IF (LEN_TRIM(regionName) > 0) THEN
        IF (ALLOCATED(this%cached_regionNames)) THEN
          DO ic = 1, this%cache_size
            IF (ic <= SIZE(this%cached_regionNames) .AND. TRIM(this%cached_regionNames(ic)) == TRIM(regionName)) THEN
              targetId = this%cached_regionIds(ic);  targetTypeInt = this%cached_regionTypes(ic);  EXIT
            END IF
          END DO
        END IF
        IF (targetId == 0) THEN
          targetId = Ldbc_FindNodeSetId(model, regionName)
          IF (targetId > 0) THEN
            targetTypeInt = TARGET_NODESET
          ELSE
            targetId = Ldbc_FindSurfaceSetId(model, regionName)
            IF (targetId > 0) THEN
              targetTypeInt = TARGET_SURFACE
            ELSE
              targetId = Ldbc_FindElementSetId(model, regionName)
              IF (targetId > 0) THEN
                targetTypeInt = TARGET_ELEMSET
              ELSE
                READ(regionName, *, ERR=100) targetId
                targetTypeInt = TARGET_NODE
100             CONTINUE
              END IF
            END IF
          END IF
          IF (targetId > 0) THEN
            this%cache_size = this%cache_size + 1
            IF (.NOT. ALLOCATED(this%cached_regionNames)) THEN
              ALLOCATE(this%cached_regionNames(16), this%cached_regionIds(16), this%cached_regionTypes(16))
            ELSE IF (this%cache_size > SIZE(this%cached_regionNames)) THEN
              CALL MD_LoadBC_Helper_GrowRegionCache(this)
            END IF
            IF (this%cache_size <= SIZE(this%cached_regionNames)) THEN
              this%cached_regionNames(this%cache_size) = TRIM(regionName)
              this%cached_regionIds(this%cache_size) = targetId
              this%cached_regionTypes(this%cache_size) = targetTypeInt
            END IF
          END IF
        END IF
      END IF
      IF (targetId <= 0) THEN
        IF (PRESENT(status)) THEN
          status%status_code = IF_STATUS_INVALID
          WRITE(status%message, '(A,A,A)') 'LBCTableAlgo_ApplyToForce: Invalid region "', &
            TRIM(regionName), '"'
        END IF
        CYCLE
      END IF
      CALL LoadDef_Init(tempLoadDef, domain%desc%loadId(idx), TRIM(domain%desc%name(idx)), &
        loadTypeInt, targetTypeInt, targetId, 1_i4, magnitude, 0_i4, loc_stat)
      IF (loc_stat%status_code /= IF_STATUS_OK) THEN
        IF (PRESENT(status)) status = loc_stat
        CYCLE
      END IF
      IF (loadTypeInt == LOAD_CONCENTRAT) THEN
        IF (ABS(direction(1)) > 0.9_wp) THEN
          tempLoadDef%val%dof = 1_i4
        ELSE IF (ABS(direction(2)) > 0.9_wp) THEN
          tempLoadDef%val%dof = 2_i4
        ELSE IF (ABS(direction(3)) > 0.9_wp) THEN
          tempLoadDef%val%dof = 3_i4
        END IF
        tempLoadDef%dof = tempLoadDef%val%dof
      END IF
      SELECT CASE (loadTypeInt)
      CASE (LOAD_CONCENTRAT)
        CALL MD_LoadBC_TableAlgo_ApplyConcentratedLoad_Internal(domain, idx, factor, F, dofMap, nDOFPerNode, status)
      CASE (LOAD_PRESSURE)
        CALL MD_LoadBC_TableAlgo_ApplyDistributedLoad_Internal(domain, idx, factor, F, dofMap, model, tempLoadDef, status)
      CASE (LOAD_GRAVITY, LOAD_BODY_FORCE)
        CALL MD_LoadBC_TableAlgo_ApplyBodyForce_Internal(domain, idx, factor, F, dofMap, model, nDOFPerNode, tempLoadDef, status)
      CASE DEFAULT
        IF (PRESENT(status)) CALL log_warn('LBCTableAlgo_ApplyToForce', &
          'Unknown load type "' // TRIM(loadTypeStr) // '"')
        CYCLE
      END SELECT
      IF (PRESENT(status)) THEN
        IF (status%status_code /= IF_STATUS_OK) CYCLE
      END IF
    END DO
    IF (ALLOCATED(loadList)) DEALLOCATE(loadList)
    IF (ALLOCATED(nodeList)) DEALLOCATE(nodeList)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE LBCTableAlgo_ApplyToForce

  !======================================================================
  ! Internal Helper Procedures
  !======================================================================
  SUBROUTINE MD_LoadBC_TableAlgo_ApplyConcentratedLoad_Internal(domain, idx, factor, F, dofMap, nDOFPerNode, status)
    TYPE(MD_LoadBC_TableDomain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN) :: idx
    REAL(wp), INTENT(IN) :: factor
    REAL(wp), INTENT(INOUT) :: F(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dofMap(:)
    INTEGER(i4), INTENT(IN) :: nDOFPerNode
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4), ALLOCATABLE :: nodeList(:)
    INTEGER(i4) :: i, nodeId, globalDof, dof
    REAL(wp) :: magnitude, direction(3)
    TYPE(UF_Model), POINTER :: model
    CHARACTER(len=64) :: regionName
    IF (PRESENT(status)) CALL init_error_status(status)
    model => domain%ctx%model
    IF (.NOT. ASSOCIATED(model)) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'ApplyConcentratedLoad_Internal: model not associated'
      END IF
      RETURN
    END IF
    IF (idx < 1 .OR. idx > domain%desc%nLoads) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID;  status%message = 'ApplyConcentratedLoad_Internal: invalid load index'
      END IF
      RETURN
    END IF
    magnitude = domain%desc%magnitude(idx) * factor
    direction = domain%desc%direction(idx, :)
    regionName = domain%desc%region(idx)
    CALL domain%algo%GetRegionNodes(domain, regionName, nodeList)
    IF (SIZE(nodeList) == 0) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    dof = 1_i4
    IF (ABS(direction(1)) > 0.9_wp) THEN
      dof = 1_i4
    ELSE IF (ABS(direction(2)) > 0.9_wp) THEN
      dof = 2_i4
    ELSE IF (ABS(direction(3)) > 0.9_wp) THEN
      dof = 3_i4
    END IF
    DO i = 1, SIZE(nodeList)
      nodeId = nodeList(i)
      globalDof = (nodeId - 1) * nDOFPerNode + dof
      IF (globalDof > 0 .AND. globalDof <= SIZE(F)) F(globalDof) = F(globalDof) + magnitude
    END DO
    IF (ALLOCATED(nodeList)) DEALLOCATE(nodeList)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_LoadBC_TableAlgo_ApplyConcentratedLoad_Internal

  SUBROUTINE MD_LoadBC_TableAlgo_ApplyDistributedLoad_Internal(domain, idx, factor, F, dofMap, model, loadDef, status)
    TYPE(MD_LoadBC_TableDomain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN) :: idx
    REAL(wp), INTENT(IN) :: factor
    REAL(wp), INTENT(INOUT) :: F(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dofMap(:)
    TYPE(UF_Model), TARGET, INTENT(IN) :: model
    TYPE(LoadDef), INTENT(IN) :: loadDef
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    INTEGER(i4) :: setId, iFace, id, faceId, iPart, elemIdx, nFaceNode, k, n, ierr
    INTEGER(i4) :: diml, nFace, nEdge, lf, lj, nnix, cnt
    INTEGER(i4), ALLOCATABLE :: sElems(:), sFaces(:)
    INTEGER(i4) :: face_tab(6, 9), edge_tab(12, 3)
    TYPE(ElemType) :: et
    REAL(wp) :: coords(3, 9), nrm(3), area, p, fnode(3), magnitude
    LOGICAL :: found
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (idx < 1 .OR. idx > domain%desc%nLoads) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID;  status%message = 'ApplyDistributedLoad_Internal: invalid load index'
      END IF
      RETURN
    END IF
    IF (loadDef%targetType /= TARGET_SURFACE) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID;  status%message = 'ApplyDistributedLoad_Internal: load target is not a surface'
      END IF
      RETURN
    END IF
    IF (.NOT. ALLOCATED(model%parts) .OR. SIZE(model%parts) < 1) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    magnitude = domain%desc%magnitude(idx);  p = magnitude * factor
    setId = loadDef%targetId
    IF (ALLOCATED(model%parts(1)%surfSets) .AND. setId >= 1_i4 .AND. &
        setId <= INT(SIZE(model%parts(1)%surfSets), i4) .AND. &
        ALLOCATED(model%parts(1)%surfSets(setId)%elemIds)) THEN
      n = INT(SIZE(model%parts(1)%surfSets(setId)%elemIds), i4)
      ALLOCATE(sElems(n), sFaces(n))
      sElems(:) = model%parts(1)%surfSets(setId)%elemIds(:)
      IF (ALLOCATED(model%parts(1)%surfSets(setId)%faceIds) .AND. &
          SIZE(model%parts(1)%surfSets(setId)%faceIds) == n) THEN
        sFaces(:) = model%parts(1)%surfSets(setId)%faceIds(:)
      ELSE
        DO k = 1_i4, n
          sFaces(k) = 1_i4
        END DO
      END IF
    ELSE
      CALL Ldbc_GetSurfaceElemFaceArrays(model, setId, sElems, sFaces)
    END IF
    IF (.NOT. ALLOCATED(sElems) .OR. SIZE(sElems) <= 0) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    DO iFace = 1_i4, INT(SIZE(sElems), i4)
      id = sElems(iFace);  faceId = sFaces(iFace)
      IF (id <= 0_i4 .OR. faceId <= 0_i4) CYCLE
      CALL Ldbc_FindElementIndexById(model, id, iPart, elemIdx, found)
      IF (.NOT. found) CYCLE
      IF (.NOT. ALLOCATED(model%parts(iPart)%elements(elemIdx)%conn)) CYCLE
      CALL UF_ElementType_FillById(et, model%parts(iPart)%elements(elemIdx)%elemTypeId)
      CALL UF_El_GetConnectivity(TRIM(et%name), diml, nFace, nEdge, face_tab, edge_tab, ierr)
      IF (ierr /= 0_i4) CYCLE
      IF (faceId < 1_i4 .OR. faceId > nFace) CYCLE
      cnt = 0_i4
      DO lf = 1_i4, SIZE(face_tab, 2)
        IF (face_tab(faceId, lf) <= 0_i4) EXIT
        cnt = cnt + 1_i4
      END DO
      nFaceNode = cnt
      IF (nFaceNode < 3_i4) CYCLE
      DO k = 1_i4, nFaceNode
        lj = face_tab(faceId, k)
        IF (lj < 1_i4 .OR. lj > SIZE(model%parts(iPart)%elements(elemIdx)%conn)) CYCLE
        nnix = model%parts(iPart)%elements(elemIdx)%conn(lj)
        IF (nnix >= 1_i4 .AND. nnix <= SIZE(model%parts(iPart)%nodes)) THEN
          coords(:, k) = model%parts(iPart)%nodes(nnix)%coords(:)
        ELSE
          coords(:, k) = 0.0_wp
        END IF
      END DO
      CALL MD_LoadBC_Helper_ComputeFaceNormalArea(coords(:, 1:nFaceNode), nFaceNode, nrm, area)
      IF (area <= 0.0_wp) CYCLE
      fnode = (-p * nrm) * (area / REAL(nFaceNode, wp))
      DO k = 1_i4, nFaceNode
        lj = face_tab(faceId, k)
        IF (lj < 1_i4 .OR. lj > SIZE(model%parts(iPart)%elements(elemIdx)%conn)) CYCLE
        nnix = model%parts(iPart)%elements(elemIdx)%conn(lj)
        CALL MD_LoadBC_Helper_AddNodalVectorForce(nnix, fnode, F, dofMap)
      END DO
    END DO
    IF (ALLOCATED(sElems)) DEALLOCATE(sElems)
    IF (ALLOCATED(sFaces)) DEALLOCATE(sFaces)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_LoadBC_TableAlgo_ApplyDistributedLoad_Internal

    !---------------------------------------------------------------------------
  !> @brief Apply body force (gravity/centrifugal) to element nodes (internal)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_LoadBC_TableAlgo_ApplyBodyForce_Internal(domain, idx, factor, F, dofMap, model, nDOFPerNode, loadDef, status)
    TYPE(MD_LoadBC_TableDomain), INTENT(IN) :: domain
    INTEGER(i4), INTENT(IN) :: idx
    REAL(wp), INTENT(IN) :: factor
    REAL(wp), INTENT(INOUT) :: F(:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: dofMap(:)
    TYPE(UF_Model), TARGET, INTENT(IN) :: model
    INTEGER(i4), INTENT(IN) :: nDOFPerNode
    TYPE(LoadDef), INTENT(IN) :: loadDef
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: iPart, iElem, iNode, id, globalDof, k
    INTEGER(i4) :: nNodes, setId, idxNode
    INTEGER(i4), POINTER :: elemIds(:)
    REAL(wp) :: bodyForce(3), nodeForce(3), elemMass
    REAL(wp) :: magnitude, direction(3)
    CHARACTER(len=32) :: loadTypeStr
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate index
    IF (idx < 1 .OR. idx > domain%desc%nLoads) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'MD_LoadBC_TableAlgo_ApplyBodyForce_Internal: invalid load index'
      END IF
      RETURN
    END IF
    
    ! Validate model structure
    IF (.NOT. ALLOCATED(model%parts)) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    IF (SIZE(model%parts) < 1) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    magnitude = domain%desc%magnitude(idx)
    direction = domain%desc%direction(idx, :)
    loadTypeStr = domain%desc%loadType(idx)
    
    ! Initialize body force vector
    bodyForce = 0.0_wp
    
    ! Determine body force direction based on load type
    IF (TRIM(loadTypeStr) == "GRAVITY") THEN
      ! Gravity: downward in Z direction
      bodyForce(3) = -magnitude * factor
    ELSE IF (TRIM(loadTypeStr) == "BFORCE" .OR. TRIM(loadTypeStr) == "BODYFORCE") THEN
      ! Body force: use direction vector
      bodyForce = direction * magnitude * factor
    ELSE
      ! Default: use direction vector
      bodyForce = direction * magnitude * factor
    END IF
    
    ! Apply body force based on target type
    SELECT CASE (loadDef%targetType)
    CASE (TARGET_ELEMSET)
      ! Apply to elements in element set
      setId = loadDef%targetId
      elemIds => null()
      
      ! Try assembly-level element sets first
      IF (ALLOCATED(model%assembly%elemSets)) THEN
        IF (setId >= 1_i4 .AND. setId <= SIZE(model%assembly%elemSets)) THEN
          IF (ALLOCATED(model%assembly%elemSets(setId)%elemIds)) THEN
            elemIds => model%assembly%elemSets(setId)%elemIds
          END IF
        END IF
      END IF
      
      ! Fallback to part-level element sets
      IF (.NOT. ASSOCIATED(elemIds)) THEN
        IF (ALLOCATED(model%parts(1)%elemSets)) THEN
          IF (setId >= 1 .AND. setId <= SIZE(model%parts(1)%elemSets)) THEN
            IF (ALLOCATED(model%parts(1)%elemSets(setId)%elemIds)) THEN
              elemIds => model%parts(1)%elemSets(setId)%elemIds
            END IF
          END IF
        END IF
      END IF
      
      IF (.NOT. ASSOCIATED(elemIds)) THEN
        IF (PRESENT(status)) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = 'MD_LoadBC_TableAlgo_ApplyBodyForce_Internal: element set not found'
        END IF
        RETURN
      END IF
      
      ! Apply to each element in the set
      DO idxNode = 1, SIZE(elemIds)
        ! Find element index
        iElem = 0_i4
        IF (ALLOCATED(model%parts(1)%elements)) THEN
          DO k = 1, SIZE(model%parts(1)%elements)
            IF (model%parts(1)%elements(k)%cfg%id == elemIds(idxNode)) THEN
              iElem = k
              EXIT
            END IF
          END DO
        END IF
        
        IF (iElem < 1) CYCLE
        
        ! Get element mass
        elemMass = 0.0_wp
        IF (ALLOCATED(model%parts(1)%elements(iElem)%materialProps)) THEN
          IF (SIZE(model%parts(1)%elements(iElem)%materialProps) >= 1) THEN
            elemMass = model%parts(1)%elements(iElem)%materialProps(1)
          END IF
        END IF
        
        IF (elemMass <= 0.0_wp) CYCLE
        
        ! Distribute force to nodes
        nNodes = SIZE(model%parts(1)%elements(iElem)%conn)
        DO iNode = 1, nNodes
          id = model%parts(1)%elements(iElem)%conn(iNode)
          nodeForce = bodyForce * elemMass / REAL(nNodes, wp)
          
          ! Apply to each DOF
          DO k = 1, MIN(3, nDOFPerNode)
              globalDof = (id - 1) * nDOFPerNode + k
            IF (globalDof > 0 .AND. globalDof <= SIZE(F)) THEN
              F(globalDof) = F(globalDof) + nodeForce(k)
            END IF
          END DO
        END DO
      END DO
      
    CASE DEFAULT
      ! Apply to all elements (for gravity without element set)
      DO iPart = 1, SIZE(model%parts)
        IF (.NOT. ALLOCATED(model%parts(iPart)%elements)) CYCLE
        IF (.NOT. ALLOCATED(model%parts(iPart)%nodes)) CYCLE
        
        DO iElem = 1, SIZE(model%parts(iPart)%elements)
          ! Get element mass
          elemMass = 0.0_wp
          IF (ALLOCATED(model%parts(iPart)%elements(iElem)%materialProps)) THEN
            IF (SIZE(model%parts(iPart)%elements(iElem)%materialProps) >= 1) THEN
              elemMass = model%parts(iPart)%elements(iElem)%materialProps(1)
            END IF
          END IF
          
          IF (elemMass <= 0.0_wp) CYCLE
          
          ! Distribute force to nodes
          nNodes = SIZE(model%parts(iPart)%elements(iElem)%conn)
          DO iNode = 1, nNodes
            id = model%parts(iPart)%elements(iElem)%conn(iNode)
            nodeForce = bodyForce * elemMass / REAL(nNodes, wp)
            
            ! Apply to each DOF
            DO k = 1, MIN(3, nDOFPerNode)
                globalDof = (id - 1) * nDOFPerNode + k
              IF (globalDof > 0 .AND. globalDof <= SIZE(F)) THEN
                F(globalDof) = F(globalDof) + nodeForce(k)
              END IF
            END DO
          END DO
        END DO
      END DO
    END SELECT
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_LoadBC_TableAlgo_ApplyBodyForce_Internal

  !---------------------------------------------------------------------------
  !> @brief Grow region cache arrays (HWM strategy)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_LoadBC_Helper_GrowRegionCache(algo)
    TYPE(MD_LoadBC_TableAlgo), INTENT(INOUT) :: algo
    INTEGER(i4) :: oldSize, newSize
    CHARACTER(len=64), ALLOCATABLE :: tempNames(:)
    INTEGER(i4), ALLOCATABLE :: tempIds(:), tempTypes(:)
    
    oldSize = SIZE(algo%cached_regionNames)
    newSize = oldSize * 2  ! Double the size
    
    ! Save existing data
    ALLOCATE(tempNames(oldSize))
    ALLOCATE(tempIds(oldSize))
    ALLOCATE(tempTypes(oldSize))
    tempNames = algo%cached_regionNames(1:oldSize)
    tempIds = algo%cached_regionIds(1:oldSize)
    tempTypes = algo%cached_regionTypes(1:oldSize)
    
    ! Reallocate with new size
    DEALLOCATE(algo%cached_regionNames, algo%cached_regionIds, algo%cached_regionTypes)
    ALLOCATE(algo%cached_regionNames(newSize))
    ALLOCATE(algo%cached_regionIds(newSize))
    ALLOCATE(algo%cached_regionTypes(newSize))
    
    ! Restore existing data
    algo%cached_regionNames(1:oldSize) = tempNames
    algo%cached_regionIds(1:oldSize) = tempIds
    algo%cached_regionTypes(1:oldSize) = tempTypes
    
    DEALLOCATE(tempNames, tempIds, tempTypes)
  END SUBROUTINE MD_LoadBC_Helper_GrowRegionCache

END MODULE MD_LBC_Container
