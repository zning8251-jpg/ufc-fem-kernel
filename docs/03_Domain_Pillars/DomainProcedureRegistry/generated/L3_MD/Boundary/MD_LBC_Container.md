# `MD_LBC_Container.f90`

- **Source**: `L3_MD/Boundary/MD_LBC_Container.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_LBC_Container`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBC_Container`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBC_Container`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_LBC_Container.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_LoadBC_Desc` (lines 150–168)

```fortran
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
```

### `MD_LoadBC_State` (lines 175–186)

```fortran
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
```

### `MD_LoadBC_Algo` (lines 193–214)

```fortran
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
```

### `MD_LoadBC_Ctx` (lines 221–227)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_Ctx
    INTEGER(i4) :: currentLoadBCId = 0_i4
    TYPE(UF_Model), POINTER :: model => null()
    TYPE(AnalysisStep), POINTER :: step => null()
    REAL(wp), POINTER :: F(:) => null()
    REAL(wp) :: time = 0.0_wp
  END TYPE MD_LoadBC_Ctx
```

### `MD_LoadBC_Runtime_Domain` (lines 234–239)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_Runtime_Domain
    TYPE(MD_LoadBC_Desc) :: desc
    TYPE(MD_LoadBC_State) :: state
    TYPE(MD_LoadBC_Algo) :: algo
    TYPE(MD_LoadBC_Ctx) :: ctx
  END TYPE MD_LoadBC_Runtime_Domain
```

### `MD_LoadBC_TableDesc` (lines 248–261)

```fortran
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
```

### `MD_LoadBC_TableSta` (lines 268–278)

```fortran
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
```

### `MD_LoadBC_TableAlgo` (lines 285–306)

```fortran
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
```

### `MD_LoadBC_TableCtx` (lines 313–319)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_TableCtx
    INTEGER(i4) :: currentLoadId = 0_i4
    TYPE(UF_Model), POINTER :: model => null()
    TYPE(AnalysisStep), POINTER :: step => null()
    REAL(wp), POINTER :: F(:) => null()
    REAL(wp) :: time = 0.0_wp
  END TYPE MD_LoadBC_TableCtx
```

### `MD_LoadBC_TableDomain` (lines 326–331)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_TableDomain
    TYPE(MD_LoadBC_TableDesc) :: desc
    TYPE(MD_LoadBC_TableSta) :: state
    TYPE(MD_LoadBC_TableAlgo) :: algo
    TYPE(MD_LoadBC_TableCtx) :: ctx
  END TYPE MD_LoadBC_TableDomain
```

### `LoadB` (lines 421–430)

```fortran
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
```

### `StepDef` (lines 432–445)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_LdbcDesc_Init` | 499 | `SUBROUTINE MD_LdbcDesc_Init(this, loadBCId, name, loadBCType, region, dofs, amplitudeName, timeFunctionName, value, direction, description)` |
| FUNCTION | `MD_LdbcDesc_GetName` | 527 | `FUNCTION MD_LdbcDesc_GetName(this) RESULT(name)` |
| SUBROUTINE | `MD_LdbcDesc_Destroy` | 541 | `SUBROUTINE MD_LdbcDesc_Destroy(this)` |
| SUBROUTINE | `MD_LdbcDesc_RegLayout` | 547 | `SUBROUTINE MD_LdbcDesc_RegLayout(this)` |
| SUBROUTINE | `MD_LdbcDesc_Ensure` | 567 | `SUBROUTINE MD_LdbcDesc_Ensure(this)` |
| SUBROUTINE | `MD_LdbcSta_Init` | 579 | `SUBROUTINE MD_LdbcSta_Init(this, loadBCId, nDOF)` |
| SUBROUTINE | `MD_LdbcSta_Destroy` | 593 | `SUBROUTINE MD_LdbcSta_Destroy(this)` |
| SUBROUTINE | `MD_LdbcSta_RegLayout` | 599 | `SUBROUTINE MD_LdbcSta_RegLayout(this)` |
| SUBROUTINE | `MD_LdbcSta_Ensure` | 614 | `SUBROUTINE MD_LdbcSta_Ensure(this)` |
| SUBROUTINE | `MD_LdbcCtx_Init` | 626 | `SUBROUTINE MD_LdbcCtx_Init(this, loadBCId)` |
| SUBROUTINE | `MD_LdbcCtx_RegLayout` | 633 | `SUBROUTINE MD_LdbcCtx_RegLayout(this)` |
| SUBROUTINE | `MD_LdbcCtx_Ensure` | 645 | `SUBROUTINE MD_LdbcCtx_Ensure(this)` |
| SUBROUTINE | `MD_LoadDesc_Init` | 657 | `SUBROUTINE MD_LoadDesc_Init(this, loadId, name, loadType)` |
| FUNCTION | `MD_LoadDesc_GetName` | 667 | `FUNCTION MD_LoadDesc_GetName(this) RESULT(name)` |
| SUBROUTINE | `MD_LoadDesc_RegLayout` | 681 | `SUBROUTINE MD_LoadDesc_RegLayout(this)` |
| SUBROUTINE | `MD_LoadDesc_Ensure` | 695 | `SUBROUTINE MD_LoadDesc_Ensure(this)` |
| SUBROUTINE | `MD_BndDesc_Init` | 707 | `SUBROUTINE MD_BndDesc_Init(this, boundaryId, name, boundaryType)` |
| SUBROUTINE | `MD_BndDesc_RegLayout` | 717 | `SUBROUTINE MD_BndDesc_RegLayout(this)` |
| SUBROUTINE | `MD_BndDesc_Ensure` | 731 | `SUBROUTINE MD_BndDesc_Ensure(this)` |
| SUBROUTINE | `MD_ConcForceDesc_Init` | 743 | `SUBROUTINE MD_ConcForceDesc_Init(this, loadId, name, setName, force, amplitudeName)` |
| SUBROUTINE | `MD_ConcForceDesc_RegLayout` | 756 | `SUBROUTINE MD_ConcForceDesc_RegLayout(this)` |
| SUBROUTINE | `MD_ConcForceDesc_Ensure` | 772 | `SUBROUTINE MD_ConcForceDesc_Ensure(this)` |
| SUBROUTINE | `MD_DistLoadDesc_Init` | 784 | `SUBROUTINE MD_DistLoadDesc_Init(this, loadId, name, setName, magnitude, direction, amplitudeName)` |
| SUBROUTINE | `MD_DistLoadDesc_RegLayout` | 798 | `SUBROUTINE MD_DistLoadDesc_RegLayout(this)` |
| SUBROUTINE | `MD_DistLoadDesc_Ensure` | 815 | `SUBROUTINE MD_DistLoadDesc_Ensure(this)` |
| SUBROUTINE | `MD_DispBCDesc_Init` | 827 | `SUBROUTINE MD_DispBCDesc_Init(this, boundaryId, name, setName, displacement, amplitudeName)` |
| SUBROUTINE | `MD_DispBCDesc_RegLayout` | 840 | `SUBROUTINE MD_DispBCDesc_RegLayout(this)` |
| SUBROUTINE | `MD_DispBCDesc_Ensure` | 856 | `SUBROUTINE MD_DispBCDesc_Ensure(this)` |
| SUBROUTINE | `MD_VelBCDesc_Init` | 868 | `SUBROUTINE MD_VelBCDesc_Init(this, boundaryId, name, setName, velocity, amplitudeName)` |
| SUBROUTINE | `MD_VelBCDesc_RegLayout` | 881 | `SUBROUTINE MD_VelBCDesc_RegLayout(this)` |
| SUBROUTINE | `MD_VelBCDesc_Ensure` | 897 | `SUBROUTINE MD_VelBCDesc_Ensure(this)` |
| SUBROUTINE | `MD_BodyForceDesc_Init` | 909 | `SUBROUTINE MD_BodyForceDesc_Init(this, loadId, name, setName, magnitude, amplitudeName)` |
| SUBROUTINE | `MD_BodyForceDesc_RegLayout` | 922 | `SUBROUTINE MD_BodyForceDesc_RegLayout(this)` |
| SUBROUTINE | `MD_BodyForceDesc_Ensure` | 938 | `SUBROUTINE MD_BodyForceDesc_Ensure(this)` |
| SUBROUTINE | `MD_NeumBCDesc_RegLayout` | 950 | `SUBROUTINE MD_NeumBCDesc_RegLayout(this)` |
| SUBROUTINE | `MD_NeumBCDesc_Ensure` | 968 | `SUBROUTINE MD_NeumBCDesc_Ensure(this)` |
| SUBROUTINE | `MD_NeumBCDesc_Init` | 977 | `SUBROUTINE MD_NeumBCDesc_Init(this, boundaryId, name, surfaceName, tractionVector, amplitudeName, status)` |
| SUBROUTINE | `MD_RobinBCDesc_RegLayout` | 997 | `SUBROUTINE MD_RobinBCDesc_RegLayout(this)` |
| SUBROUTINE | `MD_RobinBCDesc_Ensure` | 1016 | `SUBROUTINE MD_RobinBCDesc_Ensure(this)` |
| SUBROUTINE | `MD_RobinBCDesc_Init` | 1025 | `SUBROUTINE MD_RobinBCDesc_Init(this, boundaryId, name, nodeSetName, dofComponent, &` |
| SUBROUTINE | `MD_PerBCDesc_RegLayout` | 1047 | `SUBROUTINE MD_PerBCDesc_RegLayout(this)` |
| SUBROUTINE | `MD_PerBCDesc_Ensure` | 1065 | `SUBROUTINE MD_PerBCDesc_Ensure(this)` |
| SUBROUTINE | `MD_PerBCDesc_Init` | 1074 | `SUBROUTINE MD_PerBCDesc_Init(this, boundaryId, name, masterNodeId, slaveNodeId, &` |
| SUBROUTINE | `MD_LdbcAlgo_Init` | 1095 | `SUBROUTINE MD_LdbcAlgo_Init(this, applicationmeth, penaltyFactor, updateFrequency, uselagrangemult, usepenaltymetho)` |
| SUBROUTINE | `MD_LdbcAlgo_RegLayout` | 1109 | `SUBROUTINE MD_LdbcAlgo_RegLayout(this)` |
| SUBROUTINE | `MD_LdbcAlgo_Ensure` | 1125 | `SUBROUTINE MD_LdbcAlgo_Ensure(this)` |
| FUNCTION | `LoadBCTree_GetID` | 1137 | `FUNCTION LoadBCTree_GetID(this) RESULT(id)` |
| FUNCTION | `LoadBCTree_GetName` | 1144 | `FUNCTION LoadBCTree_GetName(this) RESULT(name)` |
| FUNCTION | `LoadBCTree_GetType` | 1150 | `FUNCTION LoadBCTree_GetType(this) RESULT(ntype)` |
| FUNCTION | `LoadBCTree_GetParentID` | 1156 | `FUNCTION LoadBCTree_GetParentID(this) RESULT(pid)` |
| FUNCTION | `LoadBCTree_GetByPath` | 1162 | `FUNCTION LoadBCTree_GetByPath(this, path_str) RESULT(obj_ptr)` |
| FUNCTION | `LoadBCTree_GetFullPath` | 1177 | `FUNCTION LoadBCTree_GetFullPath(this) RESULT(path_str)` |
| SUBROUTINE | `LoadBCTree_InitTree` | 1189 | `SUBROUTINE LoadBCTree_InitTree(this, initial_capacit, status)` |
| SUBROUTINE | `LoadBCTree_DestroyTree` | 1199 | `SUBROUTINE LoadBCTree_DestroyTree(this, status)` |
| SUBROUTINE | `LoadBCTree_RebuildIndex` | 1209 | `SUBROUTINE LoadBCTree_RebuildIndex(this, status)` |
| SUBROUTINE | `LoadBCTree_ValidateTree` | 1221 | `SUBROUTINE LoadBCTree_ValidateTree(this, status)` |
| SUBROUTINE | `LoadBCTree_Serialize` | 1234 | `SUBROUTINE LoadBCTree_Serialize(this, serializer)` |
| SUBROUTINE | `LoadBCTree_Deserialize` | 1264 | `SUBROUTINE LoadBCTree_Deserialize(this, deserializer)` |
| SUBROUTINE | `LoadBCTree_BeginBatch` | 1297 | `SUBROUTINE LoadBCTree_BeginBatch(this, max_size)` |
| SUBROUTINE | `LoadBCTree_EndBatch` | 1303 | `SUBROUTINE LoadBCTree_EndBatch(this, rebuild_index, status)` |
| SUBROUTINE | `MD_LoadBC_Domain_Init` | 1316 | `SUBROUTINE MD_LoadBC_Domain_Init(domain, model)` |
| SUBROUTINE | `MD_LoadBC_Domain_Reset` | 1331 | `SUBROUTINE MD_LoadBC_Domain_Reset(domain)` |
| SUBROUTINE | `MD_LoadBC_Domain_Finalize` | 1341 | `SUBROUTINE MD_LoadBC_Domain_Finalize(domain)` |
| SUBROUTINE | `MD_LoadBC_Domain_SyncFromStep` | 1379 | `SUBROUTINE MD_LoadBC_Domain_SyncFromStep(domain, step)` |
| SUBROUTINE | `MD_LoadBC_Table_Init` | 1530 | `SUBROUTINE MD_LoadBC_Table_Init(domain, status)` |
| SUBROUTINE | `MD_LoadBC_Table_Reset` | 1541 | `SUBROUTINE MD_LoadBC_Table_Reset(domain)` |
| SUBROUTINE | `MD_LoadBC_Table_Finalize` | 1551 | `SUBROUTINE MD_LoadBC_Table_Finalize(domain)` |
| SUBROUTINE | `MD_LoadBC_Table_SyncFromStep` | 1575 | `SUBROUTINE MD_LoadBC_Table_SyncFromStep(domain, step)` |
| SUBROUTINE | `LBCAlgo_Init` | 1688 | `SUBROUTINE LBCAlgo_Init(this)` |
| SUBROUTINE | `LBCAlgo_Reset` | 1693 | `SUBROUTINE LBCAlgo_Reset(this)` |
| SUBROUTINE | `LBCAlgo_Finalize` | 1699 | `SUBROUTINE LBCAlgo_Finalize(this)` |
| SUBROUTINE | `LBCAlgo_SyncFromStep` | 1710 | `SUBROUTINE LBCAlgo_SyncFromStep(this, domain, step)` |
| SUBROUTINE | `LBCAlgo_SyncFromTree` | 1717 | `SUBROUTINE LBCAlgo_SyncFromTree(this, domain, tree)` |
| SUBROUTINE | `LBCAlgo_GetActiveLoadsForStep` | 1841 | `SUBROUTINE LBCAlgo_GetActiveLoadsForStep(this, domain, stepId, loadList)` |
| SUBROUTINE | `LBCAlgo_GetRegionNodes` | 1867 | `SUBROUTINE LBCAlgo_GetRegionNodes(this, domain, regionName, nodeList)` |
| SUBROUTINE | `LBCAlgo_GetAmplitudeFactor` | 1890 | `SUBROUTINE LBCAlgo_GetAmplitudeFactor(this, domain, amplitudeName, time, factor)` |
| SUBROUTINE | `LBCAlgo_GetDofIndices` | 1915 | `SUBROUTINE LBCAlgo_GetDofIndices(this, domain, loadBCId, dofIndices)` |
| SUBROUTINE | `LBCAlgo_WriteBack` | 1939 | `SUBROUTINE LBCAlgo_WriteBack(this, domain, loadBCId, currentValue, currentTime)` |
| SUBROUTINE | `LBCTableAlgo_Init` | 1958 | `SUBROUTINE LBCTableAlgo_Init(this)` |
| SUBROUTINE | `LBCTableAlgo_Reset` | 1964 | `SUBROUTINE LBCTableAlgo_Reset(this)` |
| SUBROUTINE | `LBCTableAlgo_Finalize` | 1971 | `SUBROUTINE LBCTableAlgo_Finalize(this)` |
| SUBROUTINE | `LBCTableAlgo_SyncFromStep` | 1982 | `SUBROUTINE LBCTableAlgo_SyncFromStep(this, domain, step)` |
| SUBROUTINE | `LBCTableAlgo_GetActiveLoadsForStep` | 1989 | `SUBROUTINE LBCTableAlgo_GetActiveLoadsForStep(this, domain, stepId, loadList)` |
| SUBROUTINE | `LBCTableAlgo_GetRegionNodes` | 2015 | `SUBROUTINE LBCTableAlgo_GetRegionNodes(this, domain, regionName, nodeList)` |
| SUBROUTINE | `LBCTableAlgo_GetAmplitudeFactor` | 2038 | `SUBROUTINE LBCTableAlgo_GetAmplitudeFactor(this, domain, amplitudeName, time, factor)` |
| SUBROUTINE | `LBCTableAlgo_WriteBack` | 2070 | `SUBROUTINE LBCTableAlgo_WriteBack(this, domain, loadId, currentValue, currentTime)` |
| SUBROUTINE | `LBCTableAlgo_ApplyToForce` | 2086 | `SUBROUTINE LBCTableAlgo_ApplyToForce(this, domain, stepId, time, F, dofMap, status)` |
| SUBROUTINE | `MD_LoadBC_TableAlgo_ApplyConcentratedLoad_Internal` | 2235 | `SUBROUTINE MD_LoadBC_TableAlgo_ApplyConcentratedLoad_Internal(domain, idx, factor, F, dofMap, nDOFPerNode, status)` |
| SUBROUTINE | `MD_LoadBC_TableAlgo_ApplyDistributedLoad_Internal` | 2288 | `SUBROUTINE MD_LoadBC_TableAlgo_ApplyDistributedLoad_Internal(domain, idx, factor, F, dofMap, model, loadDef, status)` |
| SUBROUTINE | `MD_LoadBC_TableAlgo_ApplyBodyForce_Internal` | 2389 | `SUBROUTINE MD_LoadBC_TableAlgo_ApplyBodyForce_Internal(domain, idx, factor, F, dofMap, model, nDOFPerNode, loadDef, status)` |
| SUBROUTINE | `MD_LoadBC_Helper_GrowRegionCache` | 2565 | `SUBROUTINE MD_LoadBC_Helper_GrowRegionCache(algo)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
