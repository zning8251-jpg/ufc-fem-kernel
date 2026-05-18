# `MD_Mesh_API.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_API.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mesh_API`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_API`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh`
- **第四段角色（四段式）**: `_API`
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_API.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NodeGlobalMapEntry` (lines 86–93)

```fortran
  type, public :: NodeGlobalMapEntry
    integer(i4)                          :: global_node_id        = 0_i4
    integer(i4)                          :: part_index            = 0_i4
    integer(i4)                          :: instance_index        = 0_i4
    integer(i4)                          :: local_node_id         = 0_i4
    integer(i4)                          :: dof_start_index       = 0_i4
    integer(i4)                          :: n_dof                 = 0_i4
  end type NodeGlobalMapEntry
```

### `ElemGlobalMapEntry` (lines 95–101)

```fortran
  type, public :: ElemGlobalMapEntry
    integer(i4)                          :: global_elem_id        = 0_i4
    integer(i4)                          :: part_index            = 0_i4
    integer(i4)                          :: instance_index        = 0_i4
    integer(i4)                          :: local_elem_id         = 0_i4
    integer(i4),           allocatable   :: conn_global_nodes(:)
  end type ElemGlobalMapEntry
```

### `MeshGlobalNum` (lines 103–112)

```fortran
  type, public :: MeshGlobalNum
    integer(i4)                          :: n_global_nodes        = 0_i4
    integer(i4)                          :: n_global_elems        = 0_i4
    integer(i4)                          :: n_total_eq            = 0_i4
    type(NodeGlobalMapEntry), allocatable :: node_map(:)
    type(ElemGlobalMapEntry), allocatable :: elem_map(:)
    integer(i4),           allocatable   :: instance_node_off(:)
    integer(i4),           allocatable   :: INSTANCE_LEM_OFFS(:)
    type(MD_DOFMap)                       :: dof_sys
  end type MeshGlobalNum
```

### `Desc_Mesh` (lines 135–142)

```fortran
  type, public :: Desc_Mesh
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: nElems = 0_i4
    integer(i4) :: dimension = 3_i4
    real(wp), allocatable :: node_coords(:,:)
    integer(i4), allocatable :: element_conn(:,:)
    integer(i4), allocatable :: element_types(:)
  end type Desc_Mesh
```

### `MeshRefinement` (lines 2018–2032)

```fortran
  type, public :: MeshRefinement
    integer(i4) :: refinement_leve = 1_i4
    real(wp) :: refinement_rati = 2.0_wp
    logical :: uniform_refinem = .true.
    logical, allocatable :: refine_elements(:)
    real(wp), allocatable :: error_indicator(:)
    real(wp) :: refinement_thre = 0.5_wp
    logical :: isInitialized = .false.
  contains
    procedure, public :: Init => MeshRefinement_Init
    procedure, public :: SetRefinementLevel => MeshRefinement_SetRefinementLevel
    procedure, public :: SetRefinementRatio => MeshRefinement_SetRefinementRatio
    procedure, public :: MarkElementsForRefinement => MeshRefinement_MarkElementsForRefinement
    procedure, public :: Refine => MeshRefinement_Refine
  end type MeshRefinement
```

### `MeshSmoothing` (lines 2037–2049)

```fortran
  type, public :: MeshSmoothing
    integer(i4) :: smoothing_type = 0_i4
    integer(i4) :: num_iterations = 10_i4
    real(wp) :: relaxation_fact = 0.5_wp
    real(wp) :: convergence_tol = 1.0e-6_wp
    logical, allocatable :: fixed_nodes(:)
    logical :: isInitialized = .false.
  contains
    procedure, public :: Init => MeshSmoothing_Init
    procedure, public :: SetSmoothingParameters => MeshSmoothing_SetSmoothingParameters
    procedure, public :: SetFixedNodes => MeshSmoothing_SetFixedNodes
    procedure, public :: Smooth => MeshSmoothing_Smooth
  end type MeshSmoothing
```

### `MeshConnectivity` (lines 2054–2071)

```fortran
  type, public :: MeshConnectivity
    integer(i8), allocatable :: element_neighbo(:,:)
    integer(i8), allocatable :: element_faces(:,:)
    integer(i8), allocatable :: element_edges(:,:)
    integer(i8), allocatable :: node_elements(:,:)
    integer(i8), allocatable :: node_neighbors(:,:)
    integer(i8) :: num_neighbors = 0_i8
    logical :: isComputed = .false.
  contains
    procedure, public :: Init => MeshConnectivity_Init
    procedure, public :: ComputeElementNeighbors => MeshConnectivity_ComputeElementNeighbors
    procedure, public :: ComputeElementFaces => MeshConnectivity_ComputeElementFaces
    procedure, public :: ComputeElementEdges => MeshConnectivity_ComputeElementEdges
    procedure, public :: ComputeNodeElements => MeshConnectivity_ComputeNodeElements
    procedure, public :: ComputeNodeNeighbors => MeshConnectivity_ComputeNodeNeighbors
    procedure, public :: GetNeighborElements => MeshConnectivity_GetNeighborElements
    procedure, public :: GetNeighborNodes => MeshConnectivity_GetNeighborNodes
  end type MeshConnectivity
```

### `MeshGeometry` (lines 2076–2095)

```fortran
  type, public :: MeshGeometry
    real(wp) :: bounding_box_mi(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    real(wp) :: bounding_box_ma(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    real(wp) :: centroid(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    real(wp) :: volume = 0.0_wp
    real(wp) :: surface_area = 0.0_wp
    real(wp) :: total_length = 0.0_wp
    real(wp) :: min_edge_length = 0.0_wp
    real(wp) :: max_edge_length = 0.0_wp
    real(wp) :: avg_edge_length = 0.0_wp
    logical :: isComputed = .false.
  contains
    procedure, public :: Init => MeshGeometry_Init
    procedure, public :: ComputeBoundingBox => MeshGeometry_ComputeBoundingBox
    procedure, public :: ComputeVolume => MeshGeometry_ComputeVolume
    procedure, public :: ComputeSurfaceArea => MeshGeometry_ComputeSurfArea
    procedure, public :: ComputeCentroid => MeshGeometry_ComputeCentroid
    procedure, public :: ComputeEdgeLengths => MeshGeometry_ComputeEdgeLengths
    procedure, public :: GetGeometryReport => MeshGeometry_GetGeometryReport
  end type MeshGeometry
```

### `MeshTransform` (lines 2100–2118)

```fortran
  type, public :: MeshTransform
    real(wp) :: scale_factor(3) = [1.0_wp, 1.0_wp, 1.0_wp]
    real(wp) :: rotation_angles(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    real(wp) :: translation_vec(3) = [0.0_wp, 0.0_wp, 0.0_wp]
    real(wp) :: rotation_matrix(3,3) = reshape([1.0_wp, 0.0_wp, 0.0_wp, &
                                                0.0_wp, 1.0_wp, 0.0_wp, &
                                                0.0_wp, 0.0_wp, 1.0_wp], [3,3])
    logical :: isInitialized = .false.
  contains
    procedure, public :: Init => MeshTransform_Init
    procedure, public :: SetScale => MeshTransform_SetScale
    procedure, public :: SetRotation => MeshTransform_SetRotation
    procedure, public :: SetTranslation => MeshTransform_SetTranslation
    procedure, public :: MatComp_RotMat => MeshTransform_ComputeRotationMat
    procedure, public :: ApplyScale => MeshTransform_ApplyScale
    procedure, public :: ApplyRotation => MeshTransform_ApplyRotation
    procedure, public :: ApplyTranslation => MeshTransform_ApplyTranslation
    procedure, public :: ApplyTransform => MeshTransform_ApplyTransform
  end type MeshTransform
```

### `MeshIO` (lines 2123–2137)

```fortran
  type, public :: MeshIO
    character(len=256) :: input_filename = ""
    character(len=256) :: output_filename = ""
    character(len=32) :: file_format = "VTK"
    integer(i4) :: precision = 8_i4
    logical :: write_binary = .false.
    logical :: isInitialized = .false.
  contains
    procedure, public :: Init => MeshIO_Init
    procedure, public :: SetInputFile => MeshIO_SetInputFile
    procedure, public :: SetOutputFile => MeshIO_SetOutputFile
    procedure, public :: SetFileFormat => MeshIO_SetFileFormat
    procedure, public :: ExportMesh => MeshIO_ExportMesh
    procedure, public :: ImportMesh => MeshIO_ImportMesh
  end type MeshIO
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `MD_Mesh_IsAvailable` | 162 | `function MD_Mesh_IsAvailable() result(ok)` |
| FUNCTION | `MD_Mesh_GetNumElements` | 171 | `function MD_Mesh_GetNumElements() result(n)` |
| FUNCTION | `MD_Mesh_GetNumNodes` | 179 | `function MD_Mesh_GetNumNodes() result(n)` |
| SUBROUTINE | `MD_Mesh_GetElementConnectivity` | 187 | `subroutine MD_Mesh_GetElementConnectivity(element_id, conn, status)` |
| SUBROUTINE | `MD_Mesh_GetNodeCoords` | 201 | `subroutine MD_Mesh_GetNodeCoords(node_id, coords, status)` |
| FUNCTION | `MD_Mesh_GetElementFamily` | 218 | `function MD_Mesh_GetElementFamily() result(fam)` |
| FUNCTION | `MD_Mesh_GetElementDimension` | 224 | `function MD_Mesh_GetElementDimension() result(dim)` |
| SUBROUTINE | `Mesh_FromDesc` | 236 | `subroutine Mesh_FromDesc(desc_mesh, md_mesh, status)` |
| SUBROUTINE | `Mesh_FromDesc_Data` | 253 | `subroutine Mesh_FromDesc_Data(desc_mesh, md_meshdata, status)` |
| SUBROUTINE | `MeshDesc_Init` | 343 | `SUBROUTINE MeshDesc_Init(this, meshId, name, id, elementFamily, ElemFormul, nNodes, nElems)` |
| SUBROUTINE | `MeshDesc_RegLayout` | 357 | `SUBROUTINE MeshDesc_RegLayout(this)` |
| SUBROUTINE | `MeshDesc_Ensure` | 399 | `SUBROUTINE MeshDesc_Ensure(this)` |
| SUBROUTINE | `MeshState_Init` | 408 | `SUBROUTINE MeshState_Init(this, nNodes, nElems)` |
| SUBROUTINE | `MeshState_RegLayout` | 416 | `SUBROUTINE MeshState_RegLayout(this)` |
| SUBROUTINE | `MeshState_Ensure` | 439 | `SUBROUTINE MeshState_Ensure(this)` |
| SUBROUTINE | `MeshCtx_Init` | 448 | `SUBROUTINE MeshCtx_Init(this, meshId)` |
| SUBROUTINE | `MeshCtx_RegLayout` | 455 | `SUBROUTINE MeshCtx_RegLayout(this)` |
| SUBROUTINE | `MeshCtx_Ensure` | 470 | `SUBROUTINE MeshCtx_Ensure(this)` |
| SUBROUTINE | `MeshNodeDesc_Init` | 479 | `SUBROUTINE MeshNodeDesc_Init(this, id, coords)` |
| SUBROUTINE | `MeshNodeDesc_RegLayout` | 488 | `SUBROUTINE MeshNodeDesc_RegLayout(this)` |
| SUBROUTINE | `MeshNodeDesc_Ensure` | 507 | `SUBROUTINE MeshNodeDesc_Ensure(this)` |
| SUBROUTINE | `MeshElemDesc_Init` | 516 | `SUBROUTINE MeshElemDesc_Init(this, id, typeId, nodes)` |
| SUBROUTINE | `MeshElemDesc_RegLayout` | 526 | `SUBROUTINE MeshElemDesc_RegLayout(this)` |
| SUBROUTINE | `MeshElemDesc_Ensure` | 549 | `SUBROUTINE MeshElemDesc_Ensure(this)` |
| SUBROUTINE | `MeshNodeState_Init` | 558 | `SUBROUTINE MeshNodeState_Init(this, id, coords, disp, vel, acc)` |
| SUBROUTINE | `MeshNodeState_RegLayout` | 570 | `SUBROUTINE MeshNodeState_RegLayout(this)` |
| SUBROUTINE | `MeshNodeState_Ensure` | 618 | `SUBROUTINE MeshNodeState_Ensure(this)` |
| SUBROUTINE | `MeshElemState_Init` | 627 | `SUBROUTINE MeshElemState_Init(this, id, nIntPoints)` |
| SUBROUTINE | `MeshElemState_RegLayout` | 635 | `SUBROUTINE MeshElemState_RegLayout(this)` |
| SUBROUTINE | `MeshElemState_Ensure` | 694 | `SUBROUTINE MeshElemState_Ensure(this)` |
| SUBROUTINE | `GeoRegionDesc_Init` | 703 | `SUBROUTINE GeoRegionDesc_Init(this, regId, name)` |
| SUBROUTINE | `GeoRegionDesc_RegLayout` | 712 | `SUBROUTINE GeoRegionDesc_RegLayout(this)` |
| SUBROUTINE | `GeoRegionDesc_Ensure` | 732 | `SUBROUTINE GeoRegionDesc_Ensure(this)` |
| SUBROUTINE | `GeoCtx_Init` | 741 | `SUBROUTINE GeoCtx_Init(this, id, assemblyId, instanceId, meshId)` |
| SUBROUTINE | `GeoCtx_RegLayout` | 751 | `SUBROUTINE GeoCtx_RegLayout(this)` |
| SUBROUTINE | `GeoCtx_Ensure` | 778 | `SUBROUTINE GeoCtx_Ensure(this)` |
| SUBROUTINE | `Init` | 790 | `subroutine Init(this, nNodes, nElems, spatial_dim, status)` |
| SUBROUTINE | `Clean` | 822 | `subroutine Clean(this)` |
| SUBROUTINE | `GetNodeCoords` | 840 | `subroutine GetNodeCoords(this, node_id, coords, status)` |
| SUBROUTINE | `SetNodeCoords` | 861 | `subroutine SetNodeCoords(this, node_id, coords, status)` |
| SUBROUTINE | `GetElementConnectivity` | 882 | `subroutine GetElementConnectivity(this, element_id, conn, status)` |
| SUBROUTINE | `SetElementConnectivity` | 903 | `subroutine SetElementConnectivity(this, element_id, conn, status)` |
| SUBROUTINE | `GetElementNodes` | 924 | `subroutine GetElementNodes(this, element_id, node_coords, status)` |
| SUBROUTINE | `Valid` | 962 | `subroutine Valid(this, status)` |
| SUBROUTINE | `GlobalNum_Build` | 1010 | `subroutine GlobalNum_Build(model, numbering, ierr)` |
| SUBROUTINE | `GlobalNum_GetDofIndices` | 1154 | `subroutine GlobalNum_GetDofIndices(numbering, elemIndex, dofIndices, ierr)` |
| SUBROUTINE | `ModelTreeNode_Init` | 1311 | `subroutine ModelTreeNode_Init(this, id, type, parent_id, name, description)` |
| SUBROUTINE | `ModelTreeNode_Destroy` | 1332 | `subroutine ModelTreeNode_Destroy(this)` |
| SUBROUTINE | `ModelTreeNode_AddChild` | 1346 | `subroutine ModelTreeNode_AddChild(this, child_id)` |
| SUBROUTINE | `ModelTreeNode_RemoveChild` | 1369 | `subroutine ModelTreeNode_RemoveChild(this, child_id)` |
| FUNCTION | `ModelTreeNode_GetChildren` | 1402 | `function ModelTreeNode_GetChildren(this) result(children)` |
| FUNCTION | `ModelTreeNode_HasChildren` | 1414 | `function ModelTreeNode_HasChildren(this) result(has_children)` |
| SUBROUTINE | `ModelTree_Init` | 1424 | `subroutine ModelTree_Init(this, max_nodes)` |
| SUBROUTINE | `ModelTree_Clean` | 1447 | `subroutine ModelTree_Clean(this)` |
| FUNCTION | `ModelTree_CreateNode` | 1462 | `function ModelTree_CreateNode(this, type, parent_id, name, description) result(node_id)` |
| SUBROUTINE | `ModelTree_DeleteNode` | 1492 | `subroutine ModelTree_DeleteNode(this, node_id)` |
| SUBROUTINE | `ModelTree_FindNode` | 1506 | `subroutine ModelTree_FindNode(this, node_id, status)` |
| SUBROUTINE | `ModelTree_FindNodeByName` | 1526 | `subroutine ModelTree_FindNodeByName(this, name, status)` |
| FUNCTION | `ModelTree_GetRoot` | 1546 | `function ModelTree_GetRoot(this) result(root)` |
| FUNCTION | `ModelTree_GetNode` | 1553 | `function ModelTree_GetNode(this, node_id) result(node)` |
| FUNCTION | `ModelTree_GetParent` | 1568 | `function ModelTree_GetParent(this, node_id) result(parent)` |
| FUNCTION | `ModelTree_GetChildren` | 1587 | `function ModelTree_GetChildren(this, node_id) result(children)` |
| FUNCTION | `ModelTree_GetPath` | 1604 | `function ModelTree_GetPath(this, node_id) result(path)` |
| FUNCTION | `ModelTree_Valid` | 1624 | `function ModelTree_Valid(this) result(valid)` |
| SUBROUTINE | `Topology_Init` | 1649 | `subroutine Topology_Init(this, nNodes, nElems)` |
| SUBROUTINE | `Topology_Clean` | 1661 | `subroutine Topology_Clean(this)` |
| SUBROUTINE | `Topology_BuildNodeToElements` | 1678 | `subroutine Topology_BuildNodeToElements(this, element_connect)` |
| SUBROUTINE | `Topology_BuildElementToElements` | 1701 | `subroutine Topology_BuildElementToElements(this)` |
| SUBROUTINE | `Topology_BuildEdges` | 1725 | `subroutine Topology_BuildEdges(this, element_connect)` |
| SUBROUTINE | `Topology_BuildFaces` | 1753 | `subroutine Topology_BuildFaces(this, element_connect)` |
| FUNCTION | `Topology_GetNodeElements` | 1777 | `function Topology_GetNodeElements(this, node_id) result(elements)` |
| FUNCTION | `Topology_GetElementNeighbors` | 1796 | `function Topology_GetElementNeighbors(this, element_id) result(neighbors)` |
| FUNCTION | `Topology_GetElementEdges` | 1825 | `function Topology_GetElementEdges(this, element_id) result(edges)` |
| FUNCTION | `Topology_GetElementFaces` | 1853 | `function Topology_GetElementFaces(this, element_id) result(faces)` |
| FUNCTION | `Topology_Valid` | 1882 | `function Topology_Valid(this) result(valid)` |
| SUBROUTINE | `GeometryManager_Init` | 1907 | `subroutine GeometryManager_Init(this, max_nodes, max_elements)` |
| SUBROUTINE | `GeometryManager_Clean` | 1922 | `subroutine GeometryManager_Clean(this)` |
| FUNCTION | `GeometryManager_GetModelTree` | 1936 | `function GeometryManager_GetModelTree(this) result(model_tree)` |
| FUNCTION | `GeometryMgr_GetGlobalNumbering` | 1943 | `function GeometryMgr_GetGlobalNumbering(this) result(global_numberin)` |
| FUNCTION | `GeometryManager_GetTopology` | 1950 | `function GeometryManager_GetTopology(this) result(topo)` |
| SUBROUTINE | `GeometryMgr_BuildGeometry` | 1957 | `subroutine GeometryMgr_BuildGeometry(this, node_coords, element_connect)` |
| FUNCTION | `GeometryManager_Valid` | 1968 | `function GeometryManager_Valid(this) result(valid)` |
| SUBROUTINE | `CreateMeshQualityMetrics` | 1982 | `subroutine CreateMeshQualityMetrics(metrics, status)` |
| SUBROUTINE | `MeshQualityMetrics_Init` | 1989 | `subroutine MeshQualityMetrics_Init(this, status)` |
| SUBROUTINE | `CreateMeshQualityMetrics` | 2147 | `subroutine CreateMeshQualityMetrics(metrics, status)` |
| SUBROUTINE | `MeshQualityMetrics_Init` | 2156 | `subroutine MeshQualityMetrics_Init(this, status)` |
| SUBROUTINE | `MeshQualityMetrics_Calc` | 2182 | `subroutine MeshQualityMetrics_Calc(this, mesh, status)` |
| SUBROUTINE | `MeshQualityMetrics_GetQualityReport` | 2268 | `subroutine MeshQualityMetrics_GetQualityReport(this, report)` |
| SUBROUTINE | `ComputeMeshQuality` | 2291 | `subroutine ComputeMeshQuality(mesh, metrics, status)` |
| SUBROUTINE | `CreateMeshGenerator` | 2304 | `subroutine CreateMeshGenerator(generator, mesh_type, spatial_dim, element_type, status)` |
| SUBROUTINE | `MeshGenerator_Init` | 2316 | `subroutine MeshGenerator_Init(this, mesh_type, spatial_dim, element_type, status)` |
| SUBROUTINE | `MeshGenerator_SetDimensions` | 2340 | `subroutine MeshGenerator_SetDimensions(this, length_x, length_y, length_z)` |
| SUBROUTINE | `MeshGenerator_SetElementCounts` | 2350 | `subroutine MeshGenerator_SetElementCounts(this, num_x, num_y, num_z)` |
| SUBROUTINE | `MeshGenerator_SetOrigin` | 2360 | `subroutine MeshGenerator_SetOrigin(this, origin)` |
| SUBROUTINE | `MeshGenerator_Generate` | 2367 | `subroutine MeshGenerator_Generate(this, mesh, status)` |
| SUBROUTINE | `GenerateStructuredMesh` | 2381 | `subroutine GenerateStructuredMesh(generator, mesh, status)` |
| SUBROUTINE | `GenerateUnstructuredMesh` | 2455 | `subroutine GenerateUnstructuredMesh(generator, mesh, status)` |
| SUBROUTINE | `CreateMeshRefinement` | 2472 | `subroutine CreateMeshRefinement(refinement, refinement_leve, refinement_rati, status)` |
| SUBROUTINE | `MeshRefinement_Init` | 2483 | `subroutine MeshRefinement_Init(this, refinement_leve, refinement_rati, status)` |
| SUBROUTINE | `MeshRefinement_SetRefinementLevel` | 2500 | `subroutine MeshRefinement_SetRefinementLevel(this, level)` |
| SUBROUTINE | `MeshRefinement_SetRefinementRatio` | 2507 | `subroutine MeshRefinement_SetRefinementRatio(this, ratio)` |
| SUBROUTINE | `MeshRefinement_MarkElementsForRefinement` | 2514 | `subroutine MeshRefinement_MarkElementsForRefinement(this, error_indicator, threshold)` |
| SUBROUTINE | `MeshRefinement_Refine` | 2536 | `subroutine MeshRefinement_Refine(this, mesh, status)` |
| SUBROUTINE | `RefineMeshUniform` | 2550 | `subroutine RefineMeshUniform(mesh, refinement_leve, status)` |
| SUBROUTINE | `RefineMeshAdaptive` | 2560 | `subroutine RefineMeshAdaptive(mesh, refine_elements, status)` |
| SUBROUTINE | `CreateMeshSmoothing` | 2573 | `subroutine CreateMeshSmoothing(smoothing, smoothing_type, num_iterations, status)` |
| SUBROUTINE | `MeshSmoothing_Init` | 2584 | `subroutine MeshSmoothing_Init(this, smoothing_type, num_iterations, status)` |
| SUBROUTINE | `MeshSmoothing_SetSmoothingParameters` | 2601 | `subroutine MeshSmoothing_SetSmoothingParameters(this, relaxation_fact, convergence_tol)` |
| SUBROUTINE | `MeshSmoothing_SetFixedNodes` | 2612 | `subroutine MeshSmoothing_SetFixedNodes(this, fixed_nodes)` |
| SUBROUTINE | `MeshSmoothing_Smooth` | 2621 | `subroutine MeshSmoothing_Smooth(this, mesh, status)` |
| SUBROUTINE | `SmoothMeshLaplacian` | 2635 | `subroutine SmoothMeshLaplacian(mesh, num_iterations, relaxation_fact, status)` |
| SUBROUTINE | `SmoothMeshOptimization` | 2657 | `subroutine SmoothMeshOptimization(mesh, num_iterations, convergence_tol, status)` |
| SUBROUTINE | `CreateMeshConnectivity` | 2671 | `subroutine CreateMeshConnectivity(connectivity, status)` |
| SUBROUTINE | `MeshConnectivity_Init` | 2680 | `subroutine MeshConnectivity_Init(this, status)` |
| SUBROUTINE | `MeshConnectivity_ComputeElementNeighbors` | 2692 | `subroutine MeshConnectivity_ComputeElementNeighbors(this, mesh, status)` |
| SUBROUTINE | `MeshConnectivity_ComputeElementFaces` | 2702 | `subroutine MeshConnectivity_ComputeElementFaces(this, mesh, status)` |
| SUBROUTINE | `MeshConnectivity_ComputeElementEdges` | 2712 | `subroutine MeshConnectivity_ComputeElementEdges(this, mesh, status)` |
| SUBROUTINE | `MeshConnectivity_ComputeNodeElements` | 2722 | `subroutine MeshConnectivity_ComputeNodeElements(this, mesh, status)` |
| SUBROUTINE | `MeshConnectivity_ComputeNodeNeighbors` | 2732 | `subroutine MeshConnectivity_ComputeNodeNeighbors(this, mesh, status)` |
| SUBROUTINE | `MeshConnectivity_GetNeighborElements` | 2742 | `subroutine MeshConnectivity_GetNeighborElements(this, element_id, neighbors)` |
| SUBROUTINE | `MeshConnectivity_GetNeighborNodes` | 2750 | `subroutine MeshConnectivity_GetNeighborNodes(this, node_id, neighbors)` |
| SUBROUTINE | `FindElementNeighbors` | 2758 | `subroutine FindElementNeighbors(mesh, element_id, neighbors, status)` |
| SUBROUTINE | `FindElementFaces` | 2771 | `subroutine FindElementFaces(mesh, element_id, faces, status)` |
| SUBROUTINE | `FindElementEdges` | 2784 | `subroutine FindElementEdges(mesh, element_id, edges, status)` |
| SUBROUTINE | `CreateMeshGeometry` | 2800 | `subroutine CreateMeshGeometry(geometry, status)` |
| SUBROUTINE | `MeshGeometry_Init` | 2809 | `subroutine MeshGeometry_Init(this, status)` |
| SUBROUTINE | `MeshGeometry_ComputeBoundingBox` | 2829 | `subroutine MeshGeometry_ComputeBoundingBox(this, mesh, status)` |
| SUBROUTINE | `MeshGeometry_ComputeVolume` | 2859 | `subroutine MeshGeometry_ComputeVolume(this, mesh, status)` |
| SUBROUTINE | `MeshGeometry_ComputeSurfArea` | 2890 | `subroutine MeshGeometry_ComputeSurfArea(this, mesh, status)` |
| SUBROUTINE | `MeshGeometry_ComputeCentroid` | 2902 | `subroutine MeshGeometry_ComputeCentroid(this, mesh, status)` |
| SUBROUTINE | `MeshGeometry_ComputeEdgeLengths` | 2932 | `subroutine MeshGeometry_ComputeEdgeLengths(this, mesh, status)` |
| SUBROUTINE | `MeshGeometry_GetGeometryReport` | 2946 | `subroutine MeshGeometry_GetGeometryReport(this, report)` |
| SUBROUTINE | `ComputeMeshBoundingBox` | 2965 | `subroutine ComputeMeshBoundingBox(mesh, bbox_min, bbox_max, status)` |
| SUBROUTINE | `ComputeMeshVolume` | 2982 | `subroutine ComputeMeshVolume(mesh, volume, status)` |
| SUBROUTINE | `ComputeMeshSurfaceArea` | 2997 | `subroutine ComputeMeshSurfaceArea(mesh, area, status)` |
| SUBROUTINE | `CreateMeshTransform` | 3015 | `subroutine CreateMeshTransform(transform, status)` |
| SUBROUTINE | `MeshTransform_Init` | 3024 | `subroutine MeshTransform_Init(this, status)` |
| SUBROUTINE | `MeshTransform_SetScale` | 3041 | `subroutine MeshTransform_SetScale(this, scale_x, scale_y, scale_z)` |
| SUBROUTINE | `MeshTransform_SetRotation` | 3051 | `subroutine MeshTransform_SetRotation(this, angle_x, angle_y, angle_z)` |
| SUBROUTINE | `MeshTransform_SetTranslation` | 3063 | `subroutine MeshTransform_SetTranslation(this, translation)` |
| SUBROUTINE | `MeshTransform_ComputeRotationMat` | 3070 | `subroutine MeshTransform_ComputeRotationMat(this)` |
| SUBROUTINE | `MeshTransform_ApplyScale` | 3098 | `subroutine MeshTransform_ApplyScale(this, mesh, status)` |
| SUBROUTINE | `MeshTransform_ApplyRotation` | 3122 | `subroutine MeshTransform_ApplyRotation(this, mesh, status)` |
| SUBROUTINE | `MeshTransform_ApplyTranslation` | 3146 | `subroutine MeshTransform_ApplyTranslation(this, mesh, status)` |
| SUBROUTINE | `MeshTransform_ApplyTransform` | 3170 | `subroutine MeshTransform_ApplyTransform(this, mesh, status)` |
| SUBROUTINE | `TransformMeshScale` | 3186 | `subroutine TransformMeshScale(mesh, scale_factor, status)` |
| SUBROUTINE | `TransformMeshRotate` | 3200 | `subroutine TransformMeshRotate(mesh, rotation_angles, status)` |
| SUBROUTINE | `TransformMeshTranslate` | 3214 | `subroutine TransformMeshTranslate(mesh, translation_vec, status)` |
| SUBROUTINE | `CreateMeshIO` | 3231 | `subroutine CreateMeshIO(mesh_io, status)` |
| SUBROUTINE | `MeshIO_Init` | 3240 | `subroutine MeshIO_Init(this, status)` |
| SUBROUTINE | `MeshIO_SetInputFile` | 3256 | `subroutine MeshIO_SetInputFile(this, filename)` |
| SUBROUTINE | `MeshIO_SetOutputFile` | 3263 | `subroutine MeshIO_SetOutputFile(this, filename)` |
| SUBROUTINE | `MeshIO_SetFileFormat` | 3270 | `subroutine MeshIO_SetFileFormat(this, format)` |
| SUBROUTINE | `MeshIO_ExportMesh` | 3277 | `subroutine MeshIO_ExportMesh(this, mesh, status)` |
| SUBROUTINE | `MeshIO_ImportMesh` | 3292 | `subroutine MeshIO_ImportMesh(this, mesh, status)` |
| SUBROUTINE | `ExportMeshToVTK` | 3307 | `subroutine ExportMeshToVTK(mesh, filename, status)` |
| SUBROUTINE | `ImportMeshFromVTK` | 3345 | `subroutine ImportMeshFromVTK(filename, mesh, status)` |
| SUBROUTINE | `GenerateMeshReport` | 3358 | `subroutine GenerateMeshReport(mesh, report, status)` |
| SUBROUTINE | `RefineMeshAdaptive_H` | 3397 | `subroutine RefineMeshAdaptive_H(mesh, error_indicator, refinement_crit, &` |
| SUBROUTINE | `RefineMeshAdaptive_P` | 3451 | `subroutine RefineMeshAdaptive_P(element_orders, error_indicator, &` |
| SUBROUTINE | `RefineMeshAdaptive_HP` | 3483 | `subroutine RefineMeshAdaptive_HP(mesh, element_orders, error_indicator, &` |
| SUBROUTINE | `EstimateMeshError` | 3539 | `subroutine EstimateMeshError(method, mesh, solution, exact_solution, &` |
| SUBROUTINE | `OptimizeMeshQuality` | 3586 | `subroutine OptimizeMeshQuality(mesh, optimization_me, max_iterations, &` |
| SUBROUTINE | `Calc_adaptive_efficiencies` | 3623 | `subroutine Calc_adaptive_efficiencies(mesh, element_orders, error_indicator, &` |
| SUBROUTINE | `perform_mesh_h_refinement` | 3656 | `subroutine perform_mesh_h_refinement(mesh, refine_element, refined_mesh, &` |
| SUBROUTINE | `refine_single_Elem` | 3742 | `subroutine refine_single_Elem(mesh, elem_id, element_connect, element_types, &` |
| SUBROUTINE | `refine_hexahedral_Elem` | 3790 | `subroutine refine_hexahedral_Elem(node_ids, node_coords, element_connect, &` |
| FUNCTION | `create_edge_midpoint` | 3890 | `function create_edge_midpoint(node1, node2, node_coords, node_count) result(new_node)` |
| FUNCTION | `create_face_center` | 3906 | `function create_face_center(face_nodes, node_coords, node_count) result(new_node)` |
| FUNCTION | `create_Elem_center` | 3931 | `function create_Elem_center(elem_nodes, node_coords, node_count) result(new_node)` |
| SUBROUTINE | `refine_quadrilateral_Elem` | 3956 | `subroutine refine_quadrilateral_Elem(node_ids, node_coords, element_connect, &` |
| SUBROUTINE | `perform_selective_h_refinement` | 4006 | `subroutine perform_selective_h_refinement(mesh, refine_element, max_elements, &` |
| SUBROUTINE | `Calc_Elem_gradient` | 4025 | `subroutine Calc_Elem_gradient(mesh, solution, elem_id, grad)` |
| SUBROUTINE | `Solv_small_system` | 4082 | `subroutine Solv_small_system(dim, A, b, x, info)` |
| SUBROUTINE | `error_estimation_zz` | 4138 | `subroutine error_estimation_zz(mesh, solution, error_indicator)` |
| SUBROUTINE | `error_estimation_spr` | 4230 | `subroutine error_estimation_spr(mesh, solution, error_indicator)` |
| SUBROUTINE | `error_estimation_residual` | 4322 | `subroutine error_estimation_residual(mesh, solution, error_indicator)` |
| SUBROUTINE | `error_estimation_goal` | 4359 | `subroutine error_estimation_goal(mesh, solution, exact_solution, error_indicator)` |
| SUBROUTINE | `Opt_laplacian_smoothing` | 4391 | `subroutine Opt_laplacian_smoothing(mesh, max_iter, tolerance, status)` |
| SUBROUTINE | `Opt_Opt_based` | 4400 | `subroutine Opt_Opt_based(mesh, max_iter, tolerance, status)` |
| FUNCTION | `estimate_Elem_size` | 4412 | `function estimate_Elem_size(mesh, elem_id) result(size)` |
| FUNCTION | `count_Elem_nodes` | 4459 | `function count_Elem_nodes(elem_type) result(nnode)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
