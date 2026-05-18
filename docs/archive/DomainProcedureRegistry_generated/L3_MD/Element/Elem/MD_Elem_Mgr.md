# `MD_Elem_Mgr.f90`

- **Source**: `L3_MD/Element/Elem/MD_Elem_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Elem_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Elem_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Elem`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Elem`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Elem/MD_Elem_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ShapeFuncResult` (lines 582–593)

```fortran
  TYPE, PUBLIC :: ShapeFuncResult
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4) :: nIntPoints = 0_i4
    REAL(wp), ALLOCATABLE :: N(:,:)
    REAL(wp), ALLOCATABLE :: dNdxi(:,:,:)
    REAL(wp), ALLOCATABLE :: dNdx(:,:,:)
    REAL(wp), ALLOCATABLE :: detJ(:)
    REAL(wp), ALLOCATABLE :: weights(:)
  CONTAINS
    PROCEDURE, PUBLIC :: Init => ShapeFuncResult_Init
    PROCEDURE, PUBLIC :: Clear => ShapeFuncResult_Clear
  END TYPE ShapeFuncResult
```

### `ElemFlags` (lines 595–603)

```fortran
  TYPE, PUBLIC :: ElemFlags
    LOGICAL :: failed = .false.
    LOGICAL :: suggest_cutback = .false.
    LOGICAL :: requires_reasse = .false.
    REAL(wp) :: stableDt = 0.0_wp
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: nlgeom = 0_i4            ! Geometric nonlinearity flag (0=OFF,1=ON)
    INTEGER(i4) :: formulation_typ = 0_i4   ! 0=linear, 1=TL, 2=UL
  END TYPE ElemFlags
```

### `ElementMetadata` (lines 682–701)

```fortran
  type, public :: ElementMetadata
    integer(i4)                          :: element_type           = 0_i4
    integer(i4)                          :: family              = MD_MESH_ELEMENT_FAMILY
    character(len=80)                    :: name                = ""
    character(len=200)                   :: description         = ""
    integer(i4)                          :: nNodes           = 0_i4
    integer(i4)                          :: nIps             = 0_i4
    integer(i4)                          :: nDofs            = 0_i4
    integer(i4)                          :: spatial_dim         = 0_i4
    logical                              :: supports_2d         = .true.
    logical                              :: supports_3d         = .true.
    logical                              :: supports_nlgeom     = .true.
    logical                              :: supports_materi   = .true.
    logical                              :: available           = .true.
  contains
    procedure :: Init
    procedure :: Clean
    procedure :: Valid
    procedure :: GetFamilyName
  end type ElementMetadata
```

### `Desc_Element` (lines 707–712)

```fortran
  type, public :: Desc_Element
    integer(i4) :: element_type = 0_i4
    character(len=64) :: element_type_na = ""
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: nIntPoints = 0_i4
  end type Desc_Element
```

### `ElementCatalog` (lines 717–731)

```fortran
  type, public :: ElementCatalog
    integer(i4)                          :: nElems        = 0_i4
    integer(i4)                          :: max_elements        = 100_i4
    type(ElementMetadata), allocatable   :: elements(:)
    LOGICAL :: init = .false.
  contains
    procedure :: Init
    procedure :: Clean
    procedure :: RegisterElement
    procedure :: GetElement
    procedure :: FindElement
    procedure :: ListElements
    procedure :: GetElementsByFamily
    procedure :: InitDefaults
  end type ElementCatalog
```

### `ElemType_Init_In` (lines 941–956)

```fortran
  TYPE, PUBLIC :: ElemType_Init_In
    TYPE(ElemType), POINTER :: elemType => null()
    INTEGER(i4) :: elem_type_id = 0_i4
    CHARACTER(len=64) :: name = ""
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_edges = 0_i4
    INTEGER(i4) :: n_faces = 0_i4
    INTEGER(i4) :: dim = 0_i4
    INTEGER(i4) :: family = 0_i4
    INTEGER(i4) :: topo = 0_i4
    INTEGER(i4) :: n_dof_per_node = 0_i4
    INTEGER(i4) :: n_int_points = 0_i4
    LOGICAL :: has_struct = .false.
    LOGICAL :: has_thermal = .false.
    LOGICAL :: has_pore = .false.
  END TYPE ElemType_Init_In
```

### `ElemType_Init_Out` (lines 958–960)

```fortran
  TYPE, PUBLIC :: ElemType_Init_Out
    TYPE(ErrorStatusType) :: status
  END TYPE ElemType_Init_Out
```

### `MD_IntegrationPoint_Type` (lines 3557–3568)

```fortran
  TYPE, PUBLIC :: MD_IntegrationPoint_Type
      INTEGER(i4) :: ip_id = 0_i4                 ! Integration point ID
      REAL(wp) :: coords_local(3) = 0.0_wp        ! Local coordinates (?, ?, ?)
      REAL(wp) :: coords_global(3) = 0.0_wp       ! Global coordinates
      REAL(wp) :: weight = 0.0_wp                 ! Integration weight
      REAL(wp) :: jacobian = 0.0_wp               ! Jacobian determinant
      REAL(wp) :: jacobian_matrix(3,3) = 0.0_wp  ! Jacobian matrix
      REAL(wp), ALLOCATABLE :: state_variables(:) ! State variables at IP
      REAL(wp), ALLOCATABLE :: sigma(:)          ! Stress tensor
      REAL(wp), ALLOCATABLE :: strain(:)          ! Strain tensor
      LOGICAL :: is_active = .TRUE.                ! Active/inactive flag
  END TYPE MD_IntegrationPoint_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Struct_IpKernel` | 609 | `subroutine UF_Struct_IpKernel(ip, sf, dN_dx, dVol, radius)` |
| SUBROUTINE | `UF_ElementType_FillById` | 774 | `SUBROUTINE UF_ElementType_FillById(this, elemTypeId)` |
| FUNCTION | `UF_ElementType_FromId` | 928 | `FUNCTION UF_ElementType_FromId(elemTypeId) RESULT(elem)` |
| SUBROUTINE | `ElemType_Init_Structured` | 967 | `SUBROUTINE ElemType_Init_Structured(in, out)` |
| SUBROUTINE | `ElemType_Init_Base` | 988 | `SUBROUTINE ElemType_Init_Base(this)` |
| SUBROUTINE | `ElemType_Init` | 998 | `SUBROUTINE ElemType_Init(this, elem_type_id, name, n_nodes, n_edges, n_faces, dim, family, topo, &` |
| SUBROUTINE | `ElemType_RegLayout` | 1021 | `SUBROUTINE ElemType_RegLayout(this)` |
| SUBROUTINE | `ElemType_Ensure` | 1085 | `SUBROUTINE ElemType_Ensure(this)` |
| SUBROUTINE | `ElemFormul_Init_Base` | 1094 | `SUBROUTINE ElemFormul_Init_Base(this)` |
| SUBROUTINE | `ElemFormul_Init` | 1100 | `SUBROUTINE ElemFormul_Init(this, formulationType, order, numIntPoints, reducedintegrat, hourglasscontro)` |
| SUBROUTINE | `ElemFormul_RegLayout` | 1112 | `SUBROUTINE ElemFormul_RegLayout(this)` |
| SUBROUTINE | `ElemFormul_Ensure` | 1155 | `SUBROUTINE ElemFormul_Ensure(this)` |
| SUBROUTINE | `ElemCtx_Init` | 1164 | `SUBROUTINE ElemCtx_Init(this, id, ElemType, numNodes, numIntPoints, currentTime, deltaTime)` |
| SUBROUTINE | `ElemCtx_RegLayout` | 1177 | `SUBROUTINE ElemCtx_RegLayout(this)` |
| SUBROUTINE | `ElemCtx_Ensure` | 1194 | `SUBROUTINE ElemCtx_Ensure(this)` |
| SUBROUTINE | `ElemState_RegLayout` | 1205 | `SUBROUTINE ElemState_RegLayout(this)` |
| SUBROUTINE | `ElemState_Ensure` | 1211 | `SUBROUTINE ElemState_Ensure(this)` |
| SUBROUTINE | `ElemState_Init` | 1218 | `SUBROUTINE ElemState_Init(this, id_opt)` |
| SUBROUTINE | `ShapeFuncResult_Init` | 1234 | `SUBROUTINE ShapeFuncResult_Init(this, numNodes, numIntPoints)` |
| SUBROUTINE | `ShapeFuncResult_Clear` | 1253 | `SUBROUTINE ShapeFuncResult_Clear(this)` |
| SUBROUTINE | `UF_Elem_PrepareStructStorage` | 1264 | `SUBROUTINE UF_Elem_PrepareStructStorage(ElemType, ElemState, needMass, needDamp)` |
| SUBROUTINE | `UF_El_PrepareIntPointStates` | 1339 | `SUBROUTINE UF_El_PrepareIntPointStates(ElemType, ElemState, nInt_opt)` |
| SUBROUTINE | `ElementMetadata_Init` | 1362 | `subroutine ElementMetadata_Init(this, element_type, family, name, description, &` |
| SUBROUTINE | `Element_FromDesc_Metadata` | 1404 | `subroutine Element_FromDesc_Metadata(desc_element, md_metadata, status)` |
| SUBROUTINE | `ElementMetadata_Clean` | 1435 | `subroutine ElementMetadata_Clean(this)` |
| SUBROUTINE | `ElementMetadata_Valid` | 1456 | `subroutine ElementMetadata_Valid(this, status)` |
| FUNCTION | `ElementMetadata_GetFamilyName` | 1498 | `function ElementMetadata_GetFamilyName(this) result(name)` |
| SUBROUTINE | `ElementCatalog_Init` | 1531 | `subroutine ElementCatalog_Init(this, max_elements, status)` |
| SUBROUTINE | `ElementCatalog_Clean` | 1558 | `subroutine ElementCatalog_Clean(this)` |
| SUBROUTINE | `ElementCatalog_RegElement` | 1572 | `subroutine ElementCatalog_RegElement(this, element_type, family, name, description, &` |
| SUBROUTINE | `ElementCatalog_GetElement` | 1622 | `subroutine ElementCatalog_GetElement(this, element_type, metadata, status)` |
| SUBROUTINE | `ElementCatalog_FindElement` | 1653 | `subroutine ElementCatalog_FindElement(this, name, element_type, status)` |
| SUBROUTINE | `ElementCatalog_ListElements` | 1686 | `subroutine ElementCatalog_ListElements(this, element_types, element_names, nFound, status)` |
| SUBROUTINE | `El_GetElementsByFamily` | 1723 | `subroutine El_GetElementsByFamily(this, family, element_types, element_names, nFound, status)` |
| SUBROUTINE | `ElementCatalog_InitDefaults` | 1761 | `subroutine ElementCatalog_InitDefaults(this, status)` |
| SUBROUTINE | `ElementDispatcher_Init` | 1946 | `subroutine ElementDispatcher_Init(this, status)` |
| SUBROUTINE | `ElementDispatcher_Clean` | 1970 | `subroutine ElementDispatcher_Clean(this)` |
| SUBROUTINE | `ElementDispatcher_Dispatch` | 1980 | `subroutine ElementDispatcher_Dispatch(this, element_type, status)` |
| SUBROUTINE | `El_GetElementInfo` | 1998 | `subroutine El_GetElementInfo(this, element_type, metadata, status)` |
| SUBROUTINE | `El_ValidElement` | 2010 | `subroutine El_ValidElement(this, element_type, status)` |
| SUBROUTINE | `ElementAdapter_Init` | 2026 | `subroutine ElementAdapter_Init(this, element_type, adapter_type, status)` |
| SUBROUTINE | `ElementAdapter_Clean` | 2044 | `subroutine ElementAdapter_Clean(this)` |
| SUBROUTINE | `ElementAdapter_Adapt` | 2055 | `subroutine ElementAdapter_Adapt(this, status)` |
| SUBROUTINE | `ElementAdapter_Valid` | 2067 | `subroutine ElementAdapter_Valid(this, status)` |
| SUBROUTINE | `UserElement_Init` | 2085 | `subroutine UserElement_Init(this, element_type, name, source_file, compiled_lib, status)` |
| SUBROUTINE | `UserElement_Clean` | 2108 | `subroutine UserElement_Clean(this)` |
| SUBROUTINE | `UserElement_Load` | 2122 | `subroutine UserElement_Load(this, status)` |
| SUBROUTINE | `UserElement_Valid` | 2135 | `subroutine UserElement_Valid(this, status)` |
| SUBROUTINE | `UserElement_GetMetadata` | 2154 | `subroutine UserElement_GetMetadata(this, metadata)` |
| SUBROUTINE | `ElementManager_Init` | 2164 | `subroutine ElementManager_Init(this, max_elements, max_user_elemen, status)` |
| SUBROUTINE | `ElementManager_Clean` | 2200 | `subroutine ElementManager_Clean(this)` |
| SUBROUTINE | `ElementMgr_RegElement` | 2223 | `subroutine ElementMgr_RegElement(this, element_type, family, name, description, &` |
| SUBROUTINE | `ElementMgr_RegUserElement` | 2251 | `subroutine ElementMgr_RegUserElement(this, element_type, name, source_file, compiled_lib, status)` |
| SUBROUTINE | `ElementMgr_GetElementInfo` | 2284 | `subroutine ElementMgr_GetElementInfo(this, element_type, metadata, status)` |
| SUBROUTINE | `ElementManager_ListElements` | 2296 | `subroutine ElementManager_ListElements(this, element_types, element_names, nFound, status)` |
| SUBROUTINE | `ElementManager_Dispatch` | 2309 | `subroutine ElementManager_Dispatch(this, element_type, status)` |
| SUBROUTINE | `ElementManager_Valid` | 2320 | `subroutine ElementManager_Valid(this, status)` |
| SUBROUTINE | `UF_El_GetConnectivity` | 2338 | `subroutine UF_El_GetConnectivity(elemName, dim, nFace, nEdge, face_nodes, edge_nodes, ierr)` |
| SUBROUTINE | `UF_GetFaceNormal` | 2808 | `subroutine UF_GetFaceNormal(face_coords, n_face_nodes, normal)` |
| SUBROUTINE | `UF_ApplyFacePressure` | 2835 | `subroutine UF_ApplyFacePressure(face_coords, n_face_nodes, pressure, nodal_forces)` |
| SUBROUTINE | `UF_ApplyFaceTraction` | 2879 | `subroutine UF_ApplyFaceTraction(face_coords, n_face_nodes, traction, nodal_forces)` |
| SUBROUTINE | `UF_ApplyEdgeLoad` | 2920 | `subroutine UF_ApplyEdgeLoad(edge_coords, n_edge_nodes, isPressure, magnitude, direction, nodal_forces)` |
| SUBROUTINE | `UF_Ad_El_To_State` | 2964 | `subroutine UF_Ad_El_To_State(state_old, state_new, element_id, nIntPoints)` |
| SUBROUTINE | `UF_Adapt_ElementType_To_Desc` | 3000 | `subroutine UF_Adapt_ElementType_To_Desc(element_old, desc)` |
| SUBROUTINE | `UF_Struct_GaussKernel` | 3021 | `subroutine UF_Struct_GaussKernel(ElemType, Formul, Ctx, ipKernel)` |
| SUBROUTINE | `UF_Be_EulerBernoulli` | 3099 | `subroutine UF_Be_EulerBernoulli(coords, material_props, cross_section, &` |
| SUBROUTINE | `DispatchCompute` | 3220 | `subroutine DispatchCompute(desc, ElemType, Formul, Ctx, &` |
| SUBROUTINE | `DispatchFromType` | 3335 | `subroutine DispatchFromType(ElemType, Formul, Ctx, &` |
| SUBROUTINE | `UF_Ki_So_FromContxt` | 3360 | `subroutine UF_Ki_So_FromContxt(ElemType, Formul, Ctx, ip, kin)` |
| SUBROUTINE | `UF_Init_UserElement` | 3479 | `subroutine UF_Init_UserElement(Element, name)` |
| SUBROUTINE | `Calc_UserElement` | 3493 | `subroutine Calc_UserElement(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `MD_Element_Init_Base` | 3695 | `SUBROUTINE MD_Element_Init_Base(this)` |
| SUBROUTINE | `MD_Element_Init` | 3701 | `SUBROUTINE MD_Element_Init(this, id, elem_type, connectivity, name, status)` |
| SUBROUTINE | `MD_Element_Clean` | 3790 | `SUBROUTINE MD_Element_Clean(this)` |
| SUBROUTINE | `MD_Element_GetConnectivity` | 3816 | `SUBROUTINE MD_Element_GetConnectivity(this, connectivity, status)` |
| SUBROUTINE | `MD_Element_SetConnectivity` | 3837 | `SUBROUTINE MD_Element_SetConnectivity(this, connectivity, status)` |
| SUBROUTINE | `MD_Element_GetSection` | 3863 | `SUBROUTINE MD_Element_GetSection(this, section_id, material_id, orientation_id, status)` |
| SUBROUTINE | `MD_Element_SetSection` | 3878 | `SUBROUTINE MD_Element_SetSection(this, section_id, material_id, orientation_id, status)` |
| SUBROUTINE | `MD_Element_ComputeJacobian` | 3908 | `SUBROUTINE MD_Element_ComputeJacobian(this, node_coords, jacobian, jacobian_det, status)` |
| SUBROUTINE | `MD_Element_GetQuality` | 3962 | `SUBROUTINE MD_Element_GetQuality(this, aspect_ratio, skewness, jacobian_ratio, quality_score, status)` |
| SUBROUTINE | `MD_Element_AddIntegrationPoint` | 3978 | `SUBROUTINE MD_Element_AddIntegrationPoint(this, ip_coords_local, ip_weight, status)` |
| SUBROUTINE | `MD_Element_GetIntegrationPoint` | 4015 | `SUBROUTINE MD_Element_GetIntegrationPoint(this, ip_id, ip_point, status)` |
| SUBROUTINE | `MD_Element_AddNeighbor` | 4037 | `SUBROUTINE MD_Element_AddNeighbor(this, neighbor_id, status)` |
| SUBROUTINE | `MD_Element_RemoveNeighbor` | 4074 | `SUBROUTINE MD_Element_RemoveNeighbor(this, neighbor_id, status)` |
| SUBROUTINE | `MD_Element_AddTag` | 4115 | `SUBROUTINE MD_Element_AddTag(this, tag, status)` |
| FUNCTION | `MD_Element_Valid` | 4171 | `FUNCTION MD_Element_Valid(this) RESULT(ok)` |
| SUBROUTINE | `MD_Element_GetStatistics` | 4177 | `SUBROUTINE MD_Element_GetStatistics(this, stats, status)` |
| SUBROUTINE | `MD_Elem_Create` | 4196 | `SUBROUTINE MD_Elem_Create(element, id, elem_type, connectivity, name, status)` |
| SUBROUTINE | `MD_Elem_Destroy` | 4207 | `SUBROUTINE MD_Elem_Destroy(element, status)` |
| SUBROUTINE | `MD_Elem_SetConnectivity` | 4219 | `SUBROUTINE MD_Elem_SetConnectivity(element, connectivity, status)` |
| SUBROUTINE | `MD_Elem_GetConnectivity` | 4228 | `SUBROUTINE MD_Elem_GetConnectivity(element, connectivity, status)` |
| SUBROUTINE | `MD_Elem_SetSection` | 4237 | `SUBROUTINE MD_Elem_SetSection(element, section_id, material_id, orientation_id, status)` |
| SUBROUTINE | `MD_Elem_GetSection` | 4247 | `SUBROUTINE MD_Elem_GetSection(element, section_id, material_id, orientation_id, status)` |
| SUBROUTINE | `MD_Elem_ComputeJacobian` | 4270 | `SUBROUTINE MD_Elem_ComputeJacobian(element, node_coords, jacobian, jacobian_det, status)` |
| SUBROUTINE | `MD_Elem_GetQuality` | 4281 | `SUBROUTINE MD_Elem_GetQuality(element, aspect_ratio, skewness, jacobian_ratio, quality_score, status)` |
| SUBROUTINE | `MD_Elem_GetStatistics` | 4290 | `SUBROUTINE MD_Elem_GetStatistics(element, stats, status)` |
| SUBROUTINE | `MD_Elem_Valid` | 4299 | `SUBROUTINE MD_Elem_Valid(element, status)` |
| SUBROUTINE | `MD_ElementState_Init` | 4313 | `SUBROUTINE MD_ElementState_Init(this, element_id, nNodes, nIntPoints, status)` |
| SUBROUTINE | `MD_ElementState_Clean` | 4352 | `SUBROUTINE MD_ElementState_Clean(this)` |
| SUBROUTINE | `MD_ElementState_Update` | 4367 | `SUBROUTINE MD_ElementState_Update(this, dt, status)` |
| SUBROUTINE | `MD_ElementState_SetStrainEnergy` | 4392 | `SUBROUTINE MD_ElementState_SetStrainEnergy(this, strain_energy, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 3084–3089 | `interface StructGaussKernel` |
