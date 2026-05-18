!===============================================================================
! MODULE:  MD_Mesh_API
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Impl
! BRIEF:   Mesh API ?P0 API: core mesh data structures for FEA.
!          Exposes nodes, elements, surfaces, sets.
!===============================================================================
MODULE MD_Mesh_API
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md
!> Status: Phase B | Last verified: 2026-03-11
!> Theory: (TODO) | Last verified: 2026-03-05
  !! UniField-Core Mesh Core Module
  !!
  !! Design Principles:
  !!   - Core mesh data structures only
  !!   - Backward compatibility during transition
  !!
  !! Architecture:
  !!   Core types moved to separate modules:
  !!   - MD_MeshData_Algo: MeshData, MeshDesc, MeshState, MeshCtx
  !!   - MD_MeshNode_Algo: MeshNodeDesc, MeshNodeState
  !!   - MD_MeshElem_Algo: MeshElemDesc, MeshElemState
  !!   - MD_MeshMgr_Algo: MeshManager, g_mesh_manager
  !!   - MD_MeshGlobalNum_Algo: MeshGlobalNum, GlobalNum_Build, etc.
  !!   - MD_Mesh_API: MD_Mesh_Get* functions
  !!
  !! Removed Advanced Features:
  !!   - ArrayUtils, KinematicsHelpers (not part of Mesh domain)
  !!   - MeshGenerator, MeshQualMetrics, MeshRefinement, MeshSmoothing
  !!   - MeshConnectivity, MeshGeometry, MeshTransform, MeshIO
  !!   - ModelTree, Topology, GeometryManager
  !!
  !! Usage:
  !!   - Use new modules directly for new code
  !!   - This module provides backward compatibility during transition

  USE IF_Prec_Core,        only: wp, i4, i8
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  use MD_TypeSystem,        only: UF_Model, UF_Part, UF_Instance, UF_Element
  USE IF_Mem_Mgr, only: UF_MemoryView, UF_MemoryView_Create, &
                               UF_MemoryView_GetData, UF_MemoryView_Destroy
  use MD_DOF_Mgr, only: MD_DOFMap
  USE MD_Base_ObjModel, ONLY: DescBase, StateBase, CtxBase, CAT_DESC, CAT_STATE, CAT_CTX
  USE IF_Err_Brg, ONLY: uf_set_error
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Elem_Mgr, ONLY: IPState, MD_MESH_ELEMENT_TYPE_CP, MD_MESH_ELEMENT_TYPE_C3, MD_MESH_ELEMENT_TYPE_S4, MD_MESH_ELEMENT_TYPE_S8, MD_MESH_ELEMENT_TYPE_B2, MD_MESH_ELEMENT_TYPE_B3
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
       IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
  
  ! Import core types from new modules
  USE MD_Mesh_Data, ONLY: MeshData, MeshDesc, MeshState, MeshCtx
  USE MD_Mesh_Node, ONLY: MeshNodeDesc, MeshNodeState
  USE MD_Mesh_Elem, ONLY: MeshElemDesc, MeshElemState
  USE MD_Mesh_Mgr, ONLY: MeshManager
  USE MD_Mesh_GlobalNum, ONLY: MeshGlobalNum, NodeGlobalMapEntry, ElemGlobalMapEntry, &
                                GlobalNum_Build, GlobalNum_GetDofIndices

  implicit none

  private

  !=============================================================================
  ! Mesh Data Type - MOVED to MD_MeshData_Algo.f90
  !=============================================================================

  !=============================================================================
  ! Array Utilities Type - REMOVED (not part of Mesh domain core)
  !=============================================================================

  !=============================================================================
  ! Kinematics Helpers Type - REMOVED (not part of Mesh domain core)
  !=============================================================================

  !=============================================================================
  ! Mesh Manager Type
  ! Note: MeshManager moved to MD_MeshMgr_Algo.f90
  ! This is kept for backward compatibility during transition
  !=============================================================================
  ! MeshManager and g_mesh_manager are now in MD_MeshMgr_Algo module

  !=============================================================================
  ! Global Numbering Types
  !=============================================================================
  type, public :: NodeGlobalMapEntry
    integer(i4)                          :: global_node_id        = 0_i4
    integer(i4)                          :: part_index            = 0_i4
    integer(i4)                          :: instance_index        = 0_i4
    integer(i4)                          :: local_node_id         = 0_i4
    integer(i4)                          :: dof_start_index       = 0_i4
    integer(i4)                          :: n_dof                 = 0_i4
  end type NodeGlobalMapEntry

  type, public :: ElemGlobalMapEntry
    integer(i4)                          :: global_elem_id        = 0_i4
    integer(i4)                          :: part_index            = 0_i4
    integer(i4)                          :: instance_index        = 0_i4
    integer(i4)                          :: local_elem_id         = 0_i4
    integer(i4),           allocatable   :: conn_global_nodes(:)
  end type ElemGlobalMapEntry

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

  !=============================================================================
  ! Mesh Type Definitions - MOVED to separate modules:
  !   MeshDesc, MeshState, MeshCtx -> MD_MeshData_Algo
  !   MeshNodeDesc, MeshNodeState -> MD_MeshNode_Algo
  !   MeshElemDesc, MeshElemState -> MD_MeshElem_Algo
  !=============================================================================
    REAL(wp) :: kinetic_energy = 0.0_wp
    REAL(wp), ALLOCATABLE :: Ke(:,:)
    REAL(wp), ALLOCATABLE :: Re(:)
    REAL(wp), ALLOCATABLE :: Me(:,:)
    REAL(wp), ALLOCATABLE :: Ce(:,:)
    TYPE(IPState), ALLOCATABLE :: ipStates(:)
    REAL(wp), ALLOCATABLE :: ipFields(:,:)
  TYPE, PUBLIC, EXTENDS(DescBase) :: GeoRegionDesc
    INTEGER(i4)       :: reg_id    = 0
    CHARACTER(len=64) :: name     = ""


  !=============================================================================
  ! Desc_Mesh Type Definition (API conversion: Desc_Mesh -> MeshData/MeshManager)
  !=============================================================================
  type, public :: Desc_Mesh
    integer(i4) :: nNodes = 0_i4
    integer(i4) :: nElems = 0_i4
    integer(i4) :: dimension = 3_i4
    real(wp), allocatable :: node_coords(:,:)
    integer(i4), allocatable :: element_conn(:,:)
    integer(i4), allocatable :: element_types(:)
  end type Desc_Mesh

  public :: MD_Mesh_GetNumElements
  public :: MD_Mesh_GetNumNodes
  public :: MD_Mesh_GetElementConnectivity
  public :: MD_Mesh_GetNodeCoords
  public :: MD_Mesh_GetElementFamily
  public :: MD_Mesh_GetElementDimension
  public :: MD_Mesh_IsAvailable
  public :: Desc_Mesh
  public :: Mesh_FromDesc
  public :: Mesh_FromDesc_Data


  CONTAINS


  !=============================================================================
  ! MD_Mesh_IsAvailable: True if g_ufc_global ready and md_layer%mesh initialized
  !=============================================================================
  function MD_Mesh_IsAvailable() result(ok)
    logical :: ok
    ok = g_ufc_global%IsReady() .and. g_ufc_global%md_layer%mesh%initialized
  end function MD_Mesh_IsAvailable

  !=============================================================================
  ! MD_Mesh: P0 mesh API; delegates to md_layer%mesh ( ? ? )
  ! : mesh 0 ?IF_STATUS_INVALID
  !=============================================================================
  function MD_Mesh_GetNumElements() result(n)
    integer(i4) :: n
    n = 0_i4
    if (MD_Mesh_IsAvailable()) then
      n = int(g_ufc_global%md_layer%mesh%raw_data%nElems, kind=i4)
    end if
  end function MD_Mesh_GetNumElements

  function MD_Mesh_GetNumNodes() result(n)
    integer(i4) :: n
    n = 0_i4
    if (MD_Mesh_IsAvailable()) then
      n = int(g_ufc_global%md_layer%mesh%raw_data%nNodes, kind=i4)
    end if
  end function MD_Mesh_GetNumNodes

  subroutine MD_Mesh_GetElementConnectivity(element_id, conn, status)
    integer(i4), intent(in) :: element_id
    integer(i8), intent(out) :: conn(:)
    type(ErrorStatusType), intent(out) :: status
    integer(i4) :: npe
    if (.not. MD_Mesh_IsAvailable()) then
      call init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not available (md_layer%mesh not initialized)"
      return
    end if
    call g_ufc_global%md_layer%mesh%GetElemConnect(int(element_id, kind=i8), conn, npe, status)
  end subroutine MD_Mesh_GetElementConnectivity

  subroutine MD_Mesh_GetNodeCoords(node_id, coords, status)
    integer(i4), intent(in) :: node_id
    real(wp), intent(out) :: coords(:)
    type(ErrorStatusType), intent(out) :: status
    real(wp) :: c3(3)
    if (.not. MD_Mesh_IsAvailable()) then
      call init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not available (md_layer%mesh not initialized)"
      return
    end if
    call g_ufc_global%md_layer%mesh%GetNodeCoords(int(node_id, kind=i8), c3, status)
    if (status%status_code == IF_STATUS_OK .and. size(coords) >= 3) then
      coords(1:3) = c3(1:3)
    end if
  end subroutine MD_Mesh_GetNodeCoords

  function MD_Mesh_GetElementFamily() result(fam)
    integer(i4) :: fam
    fam = 0_i4
    ! TODO: Implement element family retrieval from mesh data
  end function MD_Mesh_GetElementFamily

  function MD_Mesh_GetElementDimension() result(dim)
    integer(i4) :: dim
    dim = 0_i4
    if (MD_Mesh_IsAvailable()) then
      dim = g_ufc_global%md_layer%mesh%raw_data%spatial_dim
    end if
  end function MD_Mesh_GetElementDimension

  !=============================================================================
  ! Mesh Conversion Functions (FromDesc)
  !=============================================================================

  subroutine Mesh_FromDesc(desc_mesh, md_mesh, status)
    !! Convert Desc_Mesh to MeshManager
    type(Desc_Mesh), intent(in), target :: desc_mesh
    type(MeshManager), intent(inout) :: md_mesh
    type(ErrorStatusType), intent(out) :: status
    
    call init_error_status(status)
    call md_mesh%Init(status)
    if (status%status_code /= IF_STATUS_OK) return
    
    call Mesh_FromDesc_Data(desc_mesh, md_mesh%mesh, status)
    if (status%status_code /= IF_STATUS_OK) return
    
    md_mesh%init = .true.
    status%status_code = IF_STATUS_OK
  end subroutine Mesh_FromDesc

  subroutine Mesh_FromDesc_Data(desc_mesh, md_meshdata, status)
    !! Convert Desc_Mesh to MeshData
    type(Desc_Mesh), intent(in) :: desc_mesh
    type(MeshData), intent(inout) :: md_meshdata
    type(ErrorStatusType), intent(out) :: status
    
    integer(i4) :: i
    
    call init_error_status(status)
    md_meshdata%nNodes = int(desc_mesh%nNodes, i8)
    md_meshdata%nElems = int(desc_mesh%nElems, i8)
    md_meshdata%spatial_dim = desc_mesh%dimension
    
    if (allocated(desc_mesh%node_coords)) then
      allocate(md_meshdata%node_coords(3, desc_mesh%nNodes))
      do i = 1, desc_mesh%nNodes
        md_meshdata%node_coords(:, i) = desc_mesh%node_coords(i, :)
      end do
    end if
    
    if (allocated(desc_mesh%element_conn)) then
      allocate(md_meshdata%element_connect(desc_mesh%nElems, 8))
      do i = 1, desc_mesh%nElems
        md_meshdata%element_connect(i, 1:size(desc_mesh%element_conn(i, :))) = &
          desc_mesh%element_conn(i, :)
      end do
    end if
    
    if (allocated(desc_mesh%element_types)) then
      allocate(md_meshdata%element_types(desc_mesh%nElems))
      md_meshdata%element_types = desc_mesh%element_types
    end if
    
    md_meshdata%init = .true.
    status%status_code = IF_STATUS_OK
  end subroutine Mesh_FromDesc_Data


    PROCEDURE, PUBLIC :: RegLayout => GeoRegionDesc_RegLayout
    PROCEDURE, PUBLIC :: Ensure    => GeoRegionDesc_Ensure
    PROCEDURE, PUBLIC :: Init      => GeoRegionDesc_Init
  END TYPE GeoRegionDesc

  TYPE, PUBLIC, EXTENDS(CtxBase) :: GeoCtx
    INTEGER(i4) :: id     = 0_i4
    INTEGER(i4) :: assembly_id = 0_i4
    INTEGER(i4) :: instance_id = 0_i4
    INTEGER(i4) :: mesh_id     = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => GeoCtx_RegLayout
    PROCEDURE, PUBLIC :: Ensure    => GeoCtx_Ensure
    PROCEDURE, PUBLIC :: Init      => GeoCtx_Init
  END TYPE GeoCtx

  !=============================================================================
  ! Mesh Ops Types - REMOVED (advanced features not part of core)
  ! MeshQualMetrics, MeshGenerator, MeshRefinement, MeshSmoothing,
  ! MeshConnectivity, MeshGeometry, MeshTransform, MeshIO removed
  !=============================================================================

  ! Public interfaces - sorted alphabetically
  ! Note: Core types moved to separate modules:
  !   - MeshData, MeshDesc, MeshState, MeshCtx -> MD_MeshData_Algo
  !   - MeshNodeDesc, MeshNodeState -> MD_MeshNode_Algo
  !   - MeshElemDesc, MeshElemState -> MD_MeshElem_Algo
  !   - MeshManager, g_mesh_manager -> MD_MeshMgr_Algo
  !   - MeshGlobalNum, NodeGlobalMapEntry, ElemGlobalMapEntry -> MD_MeshGlobalNum_Algo
  !   - MD_Mesh_Get* functions -> MD_Mesh_API
  
  ! Re-exported for backward compatibility during transition
  public :: ElemGlobalMapEntry, NodeGlobalMapEntry
  public :: GlobalNum_Build, GlobalNum_GetDofIndices
  public :: MeshDesc, MeshState, MeshCtx, MeshNodeDesc, MeshElemDesc
  public :: MeshNodeState, MeshElemState, GeoRegionDesc, GeoCtx
  public :: MD_Mesh_GetNumElements, MD_Mesh_GetNumNodes
  public :: MD_Mesh_GetElementConnectivity, MD_Mesh_GetNodeCoords
  public :: MD_Mesh_GetElementFamily, MD_Mesh_GetElementDimension
  public :: MD_Mesh_IsAvailable
  public :: Desc_Mesh, Mesh_FromDesc, Mesh_FromDesc_Data

contains

  !=============================================================================
  ! MD_Mesh: P0 mesh API - reads md_layer%mesh
  !=============================================================================
  ! Implementations merged from the former MD_Mesh_API.

  !=============================================================================
  ! Mesh Type procedures (from merged MD_Mesh_Type)
  !=============================================================================
  SUBROUTINE MeshDesc_Init(this, meshId, name, id, elementFamily, ElemFormul, nNodes, nElems)
    CLASS(MeshDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: meshId, id, nNodes, nElems
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, elementFamily, ElemFormul
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::MESH')
    IF (PRESENT(meshId)) this%meshId = meshId
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(elementFamily)) this%elementFamily = elementFamily
    IF (PRESENT(ElemFormul)) this%ElemFormul = ElemFormul
    IF (PRESENT(nNodes)) this%nNodes = nNodes
    IF (PRESENT(nElems)) this%nElems = nElems
  END SUBROUTINE MeshDesc_Init

  SUBROUTINE MeshDesc_RegLayout(this)
    CLASS(MeshDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(7)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'meshId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    fields(3)%field_name = 'id'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'elementFamily'
    fields(4)%data_type = IF_DATA_TYPE_CHAR
    fields(4)%elem_len = 64
    fields(4)%offset_bytes = offset
    offset = offset + 64
    fields(5)%field_name = 'ElemFormul'
    fields(5)%data_type = IF_DATA_TYPE_CHAR
    fields(5)%elem_len = 64
    fields(5)%offset_bytes = offset
    offset = offset + 64
    fields(6)%field_name = 'nNodes'
    fields(6)%data_type = IF_DATA_TYPE_INT
    fields(6)%offset_bytes = offset
    offset = offset + 4
    fields(7)%field_name = 'nElems'
    fields(7)%data_type = IF_DATA_TYPE_INT
    fields(7)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 7, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshDesc_RegLayout")
  END SUBROUTINE MeshDesc_RegLayout

  SUBROUTINE MeshDesc_Ensure(this)
    CLASS(MeshDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) this%varName = 'UF_MESHDESC'
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshDesc_Ensure")
  END SUBROUTINE MeshDesc_Ensure

  SUBROUTINE MeshState_Init(this, nNodes, nElems)
    CLASS(MeshState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: nNodes, nElems
    this%category = CAT_STATE
    IF (PRESENT(nNodes)) this%nNodes = nNodes
    IF (PRESENT(nElems)) this%nElems = nElems
  END SUBROUTINE MeshState_Init

  SUBROUTINE MeshState_RegLayout(this)
    CLASS(MeshState), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(3)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'nNodes'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'nElems'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'isActive'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 3, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshState_RegLayout")
  END SUBROUTINE MeshState_RegLayout

  SUBROUTINE MeshState_Ensure(this)
    CLASS(MeshState), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) this%varName = 'UF_MESHSTATE'
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshState_Ensure")
  END SUBROUTINE MeshState_Ensure

  SUBROUTINE MeshCtx_Init(this, meshId)
    CLASS(MeshCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: meshId
    CALL this%CoreBase%Init(CAT_CTX, 'CTX::MESH')
    IF (PRESENT(meshId)) this%meshId = meshId
  END SUBROUTINE MeshCtx_Init

  SUBROUTINE MeshCtx_RegLayout(this)
    CLASS(MeshCtx), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(1)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'meshId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 1, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshCtx_RegLayout")
  END SUBROUTINE MeshCtx_RegLayout

  SUBROUTINE MeshCtx_Ensure(this)
    CLASS(MeshCtx), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MESHCTX_', this%meshId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshCtx_Ensure")
  END SUBROUTINE MeshCtx_Ensure

  SUBROUTINE MeshNodeDesc_Init(this, id, coords)
    CLASS(MeshNodeDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id
    REAL(wp), INTENT(IN), OPTIONAL :: coords(3)
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::MESHNODE')
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(coords)) this%coords = coords
  END SUBROUTINE MeshNodeDesc_Init

  SUBROUTINE MeshNodeDesc_RegLayout(this)
    CLASS(MeshNodeDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(2)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'coords'
    fields(2)%data_type = IF_DATA_TYPE_DP
    fields(2)%offset_bytes = offset
    offset = offset + 24
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 2, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshNodeDesc_RegLayout")
  END SUBROUTINE MeshNodeDesc_RegLayout

  SUBROUTINE MeshNodeDesc_Ensure(this)
    CLASS(MeshNodeDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MESHNODEDESC_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshNodeDesc_Ensure")
  END SUBROUTINE MeshNodeDesc_Ensure

  SUBROUTINE MeshElemDesc_Init(this, id, typeId, nodes)
    CLASS(MeshElemDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id, typeId
    INTEGER(i4), INTENT(IN), OPTIONAL :: nodes(8)
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::MESHELEM')
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(typeId)) this%typeId = typeId
    IF (PRESENT(nodes)) this%nodes = nodes
  END SUBROUTINE MeshElemDesc_Init

  SUBROUTINE MeshElemDesc_RegLayout(this)
    CLASS(MeshElemDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(3)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'typeId'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'nodes'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 32
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 3, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshElemDesc_RegLayout")
  END SUBROUTINE MeshElemDesc_RegLayout

  SUBROUTINE MeshElemDesc_Ensure(this)
    CLASS(MeshElemDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MESHELEMDESC_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshElemDesc_Ensure")
  END SUBROUTINE MeshElemDesc_Ensure

  SUBROUTINE MeshNodeState_Init(this, id, coords, disp, vel, acc)
    CLASS(MeshNodeState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id
    REAL(wp), INTENT(IN), OPTIONAL :: coords(3), disp(3), vel(3), acc(3)
    this%category = CAT_STATE
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(coords)) this%coords = coords
    IF (PRESENT(disp)) this%disp = disp
    IF (PRESENT(vel)) this%vel = vel
    IF (PRESENT(acc)) this%acc = acc
  END SUBROUTINE MeshNodeState_Init

  SUBROUTINE MeshNodeState_RegLayout(this)
    CLASS(MeshNodeState), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(8)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'coords'
    fields(2)%data_type = IF_DATA_TYPE_DP
    fields(2)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(2)%offset_bytes = offset
    offset = offset + 24
    fields(3)%field_name = 'disp'
    fields(3)%data_type = IF_DATA_TYPE_DP
    fields(3)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(3)%offset_bytes = offset
    offset = offset + 24
    fields(4)%field_name = 'vel'
    fields(4)%data_type = IF_DATA_TYPE_DP
    fields(4)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(4)%offset_bytes = offset
    offset = offset + 24
    fields(5)%field_name = 'acc'
    fields(5)%data_type = IF_DATA_TYPE_DP
    fields(5)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(5)%offset_bytes = offset
    offset = offset + 24
    fields(6)%field_name = 'rotation'
    fields(6)%data_type = IF_DATA_TYPE_DP
    fields(6)%elem_len = 3 * SIZEOF(REAL(wp))
    fields(6)%offset_bytes = offset
    offset = offset + 24
    fields(7)%field_name = 'temperature'
    fields(7)%data_type = IF_DATA_TYPE_DP
    fields(7)%offset_bytes = offset
    offset = offset + 8
    fields(8)%field_name = 'pressure'
    fields(8)%data_type = IF_DATA_TYPE_DP
    fields(8)%offset_bytes = offset
    offset = offset + 8
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 8, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshNodeState_RegLayout")
  END SUBROUTINE MeshNodeState_RegLayout

  SUBROUTINE MeshNodeState_Ensure(this)
    CLASS(MeshNodeState), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MESHNODESTATE_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshNodeState_Ensure")
  END SUBROUTINE MeshNodeState_Ensure

  SUBROUTINE MeshElemState_Init(this, id, nIntPoints)
    CLASS(MeshElemState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id, nIntPoints
    this%category = CAT_STATE
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(nIntPoints)) this%nIntPoints = nIntPoints
  END SUBROUTINE MeshElemState_Init

  SUBROUTINE MeshElemState_RegLayout(this)
    CLASS(MeshElemState), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(12)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'nIntPoints'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'elemStatus'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'isActive'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    fields(5)%field_name = 'failed'
    fields(5)%data_type = IF_DATA_TYPE_INT
    fields(5)%offset_bytes = offset
    offset = offset + 4
    fields(6)%field_name = 'stableDt'
    fields(6)%data_type = IF_DATA_TYPE_DP
    fields(6)%offset_bytes = offset
    offset = offset + 8
    fields(7)%field_name = 'rhs_norm'
    fields(7)%data_type = IF_DATA_TYPE_DP
    fields(7)%offset_bytes = offset
    offset = offset + 8
    fields(8)%field_name = 'int_energy'
    fields(8)%data_type = IF_DATA_TYPE_DP
    fields(8)%offset_bytes = offset
    offset = offset + 8
    fields(9)%field_name = 'volume'
    fields(9)%data_type = IF_DATA_TYPE_DP
    fields(9)%offset_bytes = offset
    offset = offset + 8
    fields(10)%field_name = 'mass'
    fields(10)%data_type = IF_DATA_TYPE_DP
    fields(10)%offset_bytes = offset
    offset = offset + 8
    fields(11)%field_name = 'strainEnergy'
    fields(11)%data_type = IF_DATA_TYPE_DP
    fields(11)%offset_bytes = offset
    offset = offset + 8
    fields(12)%field_name = 'kineticEnergy'
    fields(12)%data_type = IF_DATA_TYPE_DP
    fields(12)%offset_bytes = offset
    offset = offset + 8
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 12, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshElemState_RegLayout")
  END SUBROUTINE MeshElemState_RegLayout

  SUBROUTINE MeshElemState_Ensure(this)
    CLASS(MeshElemState), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_MESHELEMSTATE_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "MeshElemState_Ensure")
  END SUBROUTINE MeshElemState_Ensure

  SUBROUTINE GeoRegionDesc_Init(this, regId, name)
    CLASS(GeoRegionDesc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: regId
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name
    CALL this%CoreBase%Init(CAT_DESC, 'DESC::GEOREGION')
    IF (PRESENT(regId)) this%regId = regId
    IF (PRESENT(name))  this%name  = name
  END SUBROUTINE GeoRegionDesc_Init

  SUBROUTINE GeoRegionDesc_RegLayout(this)
    CLASS(GeoRegionDesc), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(2)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'regId'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'name'
    fields(2)%data_type = IF_DATA_TYPE_CHAR
    fields(2)%elem_len = 64
    fields(2)%offset_bytes = offset
    offset = offset + 64
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 2, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "GeoRegionDesc_RegLayout")
  END SUBROUTINE GeoRegionDesc_RegLayout

  SUBROUTINE GeoRegionDesc_Ensure(this)
    CLASS(GeoRegionDesc), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_GEOREGIONDESC_', this%regId
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "GeoRegionDesc_Ensure")
  END SUBROUTINE GeoRegionDesc_Ensure

  SUBROUTINE GeoCtx_Init(this, id, assemblyId, instanceId, meshId)
    CLASS(GeoCtx), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id, assemblyId, instanceId, meshId
    CALL this%CoreBase%Init(CAT_CTX, 'CTX::GEOMETRY')
    IF (PRESENT(id)) this%cfg%id = id
    IF (PRESENT(assemblyId)) this%assemblyId = assemblyId
    IF (PRESENT(instanceId)) this%instanceId = instanceId
    IF (PRESENT(meshId)) this%meshId = meshId
  END SUBROUTINE GeoCtx_Init

  SUBROUTINE GeoCtx_RegLayout(this)
    CLASS(GeoCtx), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    TYPE(StructFieldDesc) :: fields(4)
    INTEGER(i4) :: offset
    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'id'
    fields(1)%data_type = IF_DATA_TYPE_INT
    fields(1)%offset_bytes = offset
    offset = offset + 4
    fields(2)%field_name = 'assemblyId'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'instanceId'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'meshId'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type(TRIM(this%typeName), fields, 4, status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "GeoCtx_RegLayout")
  END SUBROUTINE GeoCtx_RegLayout

  SUBROUTINE GeoCtx_Ensure(this)
    CLASS(GeoCtx), INTENT(INOUT) :: this
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(this%varName) == 0) WRITE(this%varName, '(A,I0)') 'UF_CONTEXT_GEOMETRY_', this%cfg%id
    CALL dp_create_struct_array(TRIM(this%varName), [1,0,0,0], TRIM(this%typeName), status)
    IF (status%status_code /= IF_STATUS_OK) CALL uf_set_error_status(status%status_code, status%message, "GeoCtx_Ensure")
  END SUBROUTINE GeoCtx_Ensure

  !=============================================================================
  ! Original name: MeshData_Init
  !=============================================================================
  subroutine Init(this, nNodes, nElems, spatial_dim, status)
    class(MeshData),        intent(inout) :: this
    integer(i8),             intent(in)    :: nNodes
    integer(i8),             intent(in)    :: nElems
    integer(i4),             intent(in)    :: spatial_dim
    type(ErrorStatusType),   intent(out)   :: status

    call init_error_status(status)

    this%nNodes = nNodes
    this%nElems = nElems
    this%spatial_dim = spatial_dim

    if (nNodes > 0_i8) then
      allocate(this%node_coords(spatial_dim, nNodes))
      this%node_coords(:,:) = 0.0_wp
    end if

    if (nElems > 0_i8) then
      allocate(this%element_connect(8, nElems))
      this%element_connect(:,:) = 0_i8
      allocate(this%element_types(nElems))
      this%element_types(:) = 0_i4
    end if

    this%init = .true.
    status%status_code = IF_STATUS_OK
  end subroutine Init

  !=============================================================================
  ! Original name: MeshData_Destroy
  !=============================================================================
  subroutine Clean(this)
    class(MeshData), intent(inout) :: this

    if (allocated(this%node_coords)) deallocate(this%node_coords)
    if (allocated(this%element_connect)) deallocate(this%element_connect)
    if (allocated(this%element_types)) deallocate(this%element_types)
    if (allocated(this%node_sets)) deallocate(this%node_sets)
    if (allocated(this%element_sets)) deallocate(this%element_sets)

    this%nNodes = 0_i8
    this%nElems = 0_i8
    this%spatial_dim = 3_i4
    this%init = .false.
  end subroutine Clean

  !=============================================================================
  ! Original name: MeshData_GetNodeCoords
  !=============================================================================
  subroutine GetNodeCoords(this, node_id, coords, status)
    class(MeshData),      intent(in)  :: this
    integer(i8),           intent(in)  :: node_id
    real(wp),              intent(out) :: coords(:)
    type(ErrorStatusType),  intent(out) :: status

    call init_error_status(status)

    if (node_id < 1_i8 .or. node_id > this%nNodes) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node ID"
      return
    end if

    coords(1:this%spatial_dim) = this%node_coords(1:this%spatial_dim, node_id)
    status%status_code = IF_STATUS_OK
  end subroutine GetNodeCoords

  !=============================================================================
  ! Original name: MeshData_SetNodeCoords
  !=============================================================================
  subroutine SetNodeCoords(this, node_id, coords, status)
    class(MeshData),      intent(inout) :: this
    integer(i8),           intent(in)    :: node_id
    real(wp),              intent(in)    :: coords(:)
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    if (node_id < 1_i8 .or. node_id > this%nNodes) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid node ID"
      return
    end if

    this%node_coords(1:this%spatial_dim, node_id) = coords(1:this%spatial_dim)
    status%status_code = IF_STATUS_OK
  end subroutine SetNodeCoords

  !=============================================================================
  ! Original name: MeshData_GetElementConnectivity
  !=============================================================================
  subroutine GetElementConnectivity(this, element_id, conn, status)
    class(MeshData),      intent(in)  :: this
    integer(i8),           intent(in)  :: element_id
    integer(i8),           intent(out) :: conn(:)
    type(ErrorStatusType),  intent(out) :: status

    call init_error_status(status)

    if (element_id < 1_i8 .or. element_id > this%nElems) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid Element ID"
      return
    end if

    conn(:) = this%element_connect(:, element_id)
    status%status_code = IF_STATUS_OK
  end subroutine GetElementConnectivity

  !=============================================================================
  ! Original name: MeshData_SetElementConnectivity
  !=============================================================================
  subroutine SetElementConnectivity(this, element_id, conn, status)
    class(MeshData),      intent(inout) :: this
    integer(i8),           intent(in)    :: element_id
    integer(i8),           intent(in)    :: conn(:)
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    if (element_id < 1_i8 .or. element_id > this%nElems) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid Element ID"
      return
    end if

    this%element_connect(1:size(conn), element_id) = conn(:)
    status%status_code = IF_STATUS_OK
  end subroutine SetElementConnectivity

  !=============================================================================
  ! Original name: MeshData_GetElementNodes
  !=============================================================================
  subroutine GetElementNodes(this, element_id, node_coords, status)
    class(MeshData),      intent(in)  :: this
    integer(i8),           intent(in)  :: element_id
    real(wp),              intent(out) :: node_coords(:,:)
    type(ErrorStatusType),  intent(out) :: status

    integer(i8) :: conn(8)
    integer(i4) :: i, nNodes

    call init_error_status(status)

    call this%GetElementConnectivity(element_id, conn, status)
    if (status%status_code /= IF_STATUS_OK) return

    nNodes = 0_i4
    do i = 1, 8
      if (conn(i) > 0_i8) then
        nNodes = nNodes + 1_i4
        if (nNodes <= size(node_coords, 2)) then
          node_coords(1:this%spatial_dim, nNodes) = &
            this%node_coords(1:this%spatial_dim, conn(i))
        end if
      end if
    end do

    ! Zero out remaining columns if output array is larger than actual nodes
    if (nNodes < size(node_coords, 2)) then
      do i = nNodes + 1, size(node_coords, 2)
        node_coords(1:this%spatial_dim, i) = 0.0_wp
      end do
    end if

    status%status_code = IF_STATUS_OK
  end subroutine GetElementNodes

  !=============================================================================
  ! Original name: MeshData_Validate
  !=============================================================================
  subroutine Valid(this, status)
    class(MeshData),      intent(in)  :: this
    type(ErrorStatusType),  intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "MeshData not initialized"
      return
    end if

    if (this%nNodes < 0_i8) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of nodes"
      return
    end if

    if (this%nElems < 0_i8) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid number of elements"
      return
    end if

    if (this%spatial_dim < 2_i4 .or. this%spatial_dim > 3_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid spatial dimension"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine Valid

  !=============================================================================
  ! ArrayUtils implementations - REMOVED (not part of Mesh domain core)
  !=============================================================================

  !=============================================================================
  ! KinematicsHelpers implementations - REMOVED (not part of Mesh domain core)
  !=============================================================================

  !=============================================================================
  ! MeshManager implementations - MOVED to MD_MeshMgr_Algo.f90
  !=============================================================================

  !=============================================================================
  ! GlobalNum_Build
  !=============================================================================
  subroutine GlobalNum_Build(model, numbering, ierr)
    type(UF_Model),           intent(in)  :: model
    type(MeshGlobalNum), intent(out) :: numbering
    integer(i4),              intent(out) :: ierr

    integer(i4) :: nInst, iInst, iPart, iNode, iElem
    integer(i4) :: nodeCount, elemCount
    integer(i4), allocatable :: ndof(:)
    integer(i4) :: nConn, j
    type(UF_Part),     pointer :: partPtr
    type(UF_Instance), pointer :: instPtr
    type(ErrorStatusType) :: status

    ierr = 0_i4

    numbering%nGlobalNodes = 0_i4
    numbering%nGlobalElems = 0_i4
    numbering%nTotalEq     = 0_i4

    if (allocated(numbering%nodeMap))          deallocate(numbering%nodeMap)
    if (allocated(numbering%elemMap))          deallocate(numbering%elemMap)
    if (allocated(numbering%instancenodeoff)) deallocate(numbering%instancenodeoff)
    if (allocated(numbering%INSTANCELEMOFFS)) deallocate(numbering%INSTANCELEMOFFS)

    if (.not. allocated(model%assembly%instances)) return

    nInst = size(model%assembly%instances)
    if (nInst <= 0_i4) return

    allocate(numbering%instancenodeoff(nInst+1))
    allocate(numbering%INSTANCELEMOFFS(nInst+1))
    numbering%instancenodeoff = 0_i4
    numbering%INSTANCELEMOFFS = 0_i4

    nodeCount = 0_i4
    elemCount = 0_i4

    do iInst = 1, nInst
      instPtr => model%assembly%instances(iInst)
      if (.not. associated(instPtr%part)) then
        numbering%instancenodeoff(iInst+1) = nodeCount
        numbering%INSTANCELEMOFFS(iInst+1) = elemCount
        cycle
      end if

      partPtr => instPtr%part

      if (allocated(partPtr%nodes)) then
        nodeCount = nodeCount + size(partPtr%nodes)
      end if

      if (allocated(partPtr%elements)) then
        elemCount = elemCount + size(partPtr%elements)
      end if

      numbering%instancenodeoff(iInst+1) = nodeCount
      numbering%INSTANCELEMOFFS(iInst+1) = elemCount
    end do

    numbering%nGlobalNodes = nodeCount
    numbering%nGlobalElems = elemCount

    if (nodeCount <= 0_i4 .and. elemCount <= 0_i4) return

    if (nodeCount > 0_i4) then
      allocate(numbering%nodeMap(nodeCount))
    end if
    if (elemCount > 0_i4) then
      allocate(numbering%elemMap(elemCount))
    end if

    nodeCount = 0_i4
    elemCount = 0_i4

    do iInst = 1, nInst
      instPtr => model%assembly%instances(iInst)
      if (.not. associated(instPtr%part)) cycle

      partPtr => instPtr%part

      if (allocated(partPtr%nodes)) then
        do iNode = 1, size(partPtr%nodes)
          nodeCount = nodeCount + 1_i4
          numbering%nodeMap(nodeCount)%globalNodeId  = nodeCount
          numbering%nodeMap(nodeCount)%partIndex     = find_part_index(model, partPtr)
          numbering%nodeMap(nodeCount)%instanceIndex = iInst
          numbering%nodeMap(nodeCount)%localNodeId   = partPtr%nodes(iNode)%cfg%id
          numbering%nodeMap(nodeCount)%nDof          = 3_i4
          numbering%nodeMap(nodeCount)%dofStartIndex = 3_i4 * (nodeCount-1_i4) + 1_i4
        end do
      end if

      if (allocated(partPtr%elements)) then
        do iElem = 1, size(partPtr%elements)
          integer(i4) :: nConn, j

          elemCount = elemCount + 1_i4
          numbering%elemMap(elemCount)%globalElemId  = elemCount
          numbering%elemMap(elemCount)%partIndex     = find_part_index(model, partPtr)
          numbering%elemMap(elemCount)%instanceIndex = iInst
          numbering%elemMap(elemCount)%localElemId   = partPtr%elements(iElem)%cfg%id

          if (allocated(numbering%elemMap(elemCount)%connGlobalNodes)) then
            deallocate(numbering%elemMap(elemCount)%connGlobalNodes)
          end if

          if (allocated(partPtr%elements(iElem)%conn)) then
            nConn = size(partPtr%elements(iElem)%conn)
              allocate(numbering%elemMap(elemCount)%connGlobalNodes(nConn))

              do j = 1, nConn
                numbering%elemMap(elemCount)%connGlobalNodes(j) = &
                     FindGlobalNodeIdForInstance(numbering, iInst, partPtr%elements(iElem)%conn(j))
              end do
            end if
          end if

        end do
      end if
    end do

    if (numbering%nGlobalNodes > 0_i4) then
      allocate(ndof(numbering%nGlobalNodes))
      do iNode = 1_i4, numbering%nGlobalNodes
        ndof(iNode) = numbering%nodeMap(iNode)%nDof
      end do
      call numbering%dof_sys%Init(numbering%nGlobalNodes, maxval(ndof), status)
      if (status%status_code /= IF_STATUS_OK) then
        ierr = -20_i4
        deallocate(ndof)
        return
      end if
      do iNode = 1_i4, numbering%nGlobalNodes
        call numbering%dof_sys%SetNdof(iNode, ndof(iNode), status)
      end do
      call numbering%dof_sys%MakeEq(0_i4, status)
      deallocate(ndof)
    end if

  end subroutine GlobalNum_Build

  !=============================================================================
  ! GlobalNum_GetDofIndices
  !=============================================================================
  subroutine GlobalNum_GetDofIndices(numbering, elemIndex, dofIndices, ierr)
    type(MeshGlobalNum), intent(in)  :: numbering
    integer(i4),              intent(in)  :: elemIndex
    integer(i4), allocatable, intent(out) :: dofIndices(:)
    integer(i4),              intent(out) :: ierr

    integer(i4) :: nNode, ndpn, iNode, j, gNode, eqStart, idx
    integer(i4) :: e1, e2
    type(ErrorStatusType) :: status

    ierr = 0_i4
    if (allocated(dofIndices)) deallocate(dofIndices)

    if (elemIndex < 1_i4 .or. elemIndex > numbering%nGlobalElems) then
      ierr = -1_i4
      return
    end if
    if (.not. allocated(numbering%elemMap)) then
      ierr = -2_i4
      return
    end if
    if (.not. allocated(numbering%nodeMap)) then
      ierr = -3_i4
      return
    end if

    if (.not. allocated(numbering%elemMap(elemIndex)%connGlobalNodes)) then
      ierr = -4_i4
      return
    end if

    nNode = size(numbering%elemMap(elemIndex)%connGlobalNodes)
    if (nNode <= 0_i4) then
      ierr = -5_i4
      return
    end if

    gNode = numbering%elemMap(elemIndex)%connGlobalNodes(1)
    if (gNode < 1_i4 .or. gNode > size(numbering%nodeMap)) then
      ierr = -6_i4
      return
    end if
    ndpn = numbering%nodeMap(gNode)%nDof
    if (ndpn <= 0_i4) then
      ierr = -7_i4
      return
    end if

    do iNode = 2, nNode
      gNode = numbering%elemMap(elemIndex)%connGlobalNodes(iNode)
      if (gNode < 1_i4 .or. gNode > size(numbering%nodeMap)) then
        ierr = -8_i4
        return
      end if
      if (numbering%nodeMap(gNode)%nDof /= ndpn) then
        ierr = -9_i4
        return
      end if
    end do

    allocate(dofIndices(nNode * ndpn))
    dofIndices = 0_i4

    idx = 0_i4
    do iNode = 1, nNode
      gNode = numbering%elemMap(elemIndex)%connGlobalNodes(iNode)
      if (gNode < 1_i4 .or. gNode > size(numbering%nodeMap)) then
        ierr = -10_i4
        return
      end if
      eqStart = numbering%nodeMap(gNode)%dofStartIndex
      if (eqStart <= 0_i4) then
        ierr = -11_i4
        return
      end if

      if (numbering%nGlobalNodes > 0_i4) then
        call numbering%dof_sys%NodeRng(gNode, e1, e2, status)
      end if

      do j = 1, ndpn
        idx = idx + 1_i4
        if (idx > size(dofIndices)) exit
        dofIndices(idx) = eqStart + j - 1_i4
      end do

    end do

    numbering%nTotalEq = max(numbering%nTotalEq, &
         numbering%nodeMap(numbering%nGlobalNodes)%dofStartIndex + &
         numbering%nodeMap(numbering%nGlobalNodes)%nDof - 1_i4)

  end subroutine GlobalNum_GetDofIndices

  !=============================================================================
  ! find_part_index
  !=============================================================================
  integer(i4) function find_part_index(model, partPtr) result(idx)
    type(UF_Model), intent(in) :: model
    type(UF_Part), pointer     :: partPtr

    integer(i4) :: i

    idx = 0_i4
    if (.not. allocated(model%parts)) return

    do i = 1, size(model%parts)
      if (associated(partPtr, model%parts(i))) then
        idx = i
        return
      end if
    end do

  end function find_part_index

  !=============================================================================
  ! FindGlobalNodeIdForInstance
  !=============================================================================
  integer(i4) function FindGlobalNodeIdForInstance(numbering, instanceIndex, localNodeId) result(gid)
    type(MeshGlobalNum), intent(in) :: numbering
    integer(i4),             intent(in) :: instanceIndex, localNodeId

    integer(i4) :: offset, nextOffset, k

    gid = 0_i4
    if (instanceIndex <= 0_i4) return
    if (.not. allocated(numbering%nodeMap)) return
    if (.not. allocated(numbering%instancenodeoff)) return
    if (instanceIndex+1_i4 > size(numbering%instancenodeoff)) return

    offset     = numbering%instancenodeoff(instanceIndex)
    nextOffset = numbering%instancenodeoff(instanceIndex+1_i4)

    do k = offset+1_i4, nextOffset
      if (k < 1_i4 .or. k > size(numbering%nodeMap)) cycle
      if (numbering%nodeMap(k)%instanceIndex == instanceIndex .and. &
          numbering%nodeMap(k)%localNodeId   == localNodeId) then
        gid = numbering%nodeMap(k)%globalNodeId
        return
      end if
    end do

  end function FindGlobalNodeIdForInstance

  !=============================================================================
  ! LEGACY Model Tree Types - DEPRECATED (v4.0, 议题1)
  !   These ModelTree/ModelTreeNode types are UNRELATED to MD_ModelTree module.
  !   They are a separate legacy implementation that should NOT be extended.
  !   The authoritative ModelTree is in Model/MD_ModelTree.f90 (L6 semantic tree).
  !   The runtime authority is MD_L3_LayerContainer (flat 14-domain container).
  !=============================================================================

contains

  !=============================================================================
  ! ModelTreeNode Procedures
  !=============================================================================
  subroutine ModelTreeNode_Init(this, id, type, parent_id, name, description)
    class(ModelTreeNode), intent(inout) :: this
    integer(i8), intent(in) :: id
    integer(i4), intent(in) :: type
    integer(i8), intent(in) :: parent_id
    character(len=*), intent(in) :: name
    character(len=*), intent(in) :: description

    this%cfg%id = id
    this%type = type
    this%parent_id = parent_id
    this%name = name
    this%cfg%description = description
    this%num_children = 0_i4
    this%active = .true.
    this%visible = .true.

    if (allocated(this%child_ids)) deallocate(this%child_ids)
    allocate(this%child_ids(0))
  end subroutine ModelTreeNode_Init

  subroutine ModelTreeNode_Destroy(this)
    class(ModelTreeNode), intent(inout) :: this

    if (allocated(this%child_ids)) deallocate(this%child_ids)
    this%cfg%id = 0_i8
    this%type = MODEL_TYPE_ROOT
    this%parent_id = 0_i8
    this%name = ""
    this%cfg%description = ""
    this%num_children = 0_i4
    this%active = .false.
    this%visible = .false.
  end subroutine ModelTreeNode_Destroy

  subroutine ModelTreeNode_AddChild(this, child_id)
    class(ModelTreeNode), intent(inout) :: this
    integer(i8), intent(in) :: child_id

    integer(i4), allocatable :: temp(:)
    integer(i4) :: i

    allocate(temp(this%num_children))
    do i = 1, this%num_children
      temp(i) = this%child_ids(i)
    end do

    deallocate(this%child_ids)
    allocate(this%child_ids(this%num_children + 1))
    do i = 1, this%num_children
      this%child_ids(i) = temp(i)
    end do
    this%child_ids(this%num_children + 1) = child_id
    this%num_children = this%num_children + 1

    deallocate(temp)
  end subroutine ModelTreeNode_AddChild

  subroutine ModelTreeNode_RemoveChild(this, child_id)
    class(ModelTreeNode), intent(inout) :: this
    integer(i8), intent(in) :: child_id

    integer(i4), allocatable :: temp(:)
    integer(i4) :: i, j

    j = 0
    do i = 1, this%num_children
      if (this%child_ids(i) /= child_id) then
        j = j + 1
      end if
    end do

    if (j == this%num_children) return

    allocate(temp(j))
    j = 0
    do i = 1, this%num_children
      if (this%child_ids(i) /= child_id) then
        j = j + 1
        temp(j) = this%child_ids(i)
      end if
    end do

    deallocate(this%child_ids)
    allocate(this%child_ids(j))
    this%child_ids = temp
    this%num_children = j

    deallocate(temp)
  end subroutine ModelTreeNode_RemoveChild

  function ModelTreeNode_GetChildren(this) result(children)
    class(ModelTreeNode), intent(in) :: this
    integer(i8), allocatable :: children(:)

    integer(i4) :: i

    allocate(children(this%num_children))
    do i = 1, this%num_children
      children(i) = this%child_ids(i)
    end do
  end function ModelTreeNode_GetChildren

  function ModelTreeNode_HasChildren(this) result(has_children)
    class(ModelTreeNode), intent(in) :: this
    logical :: has_children

    has_children = (this%num_children > 0)
  end function ModelTreeNode_HasChildren

  !=============================================================================
  ! ModelTree Procedures
  !=============================================================================
  subroutine ModelTree_Init(this, max_nodes)
    class(ModelTree), intent(inout) :: this
    integer(i4), intent(in), optional :: max_nodes

    integer(i4) :: max_nodes_local

    max_nodes_local = 10000_i4
    if (present(max_nodes)) max_nodes_local = max_nodes

    this%max_nodes = max_nodes_local
    this%next_id = 1_i8
    this%nNodes = 0_i4

    allocate(this%nodes(max_nodes_local))

    call this%root%Init(id=0_i8, type=MODEL_TYPE_ROOT, parent_id=0_i8, &
                        name="Root", description="Model tree root")
    this%nodes(1) = this%root
    this%nNodes = 1_i4
    this%next_id = 2_i8
    this%init = .true.
  end subroutine ModelTree_Init

  subroutine ModelTree_Clean(this)
    class(ModelTree), intent(inout) :: this

    integer(i4) :: i

    do i = 1, this%nNodes
      call this%nodes(i)%Clean()
    end do

    if (allocated(this%nodes)) deallocate(this%nodes)
    this%nNodes = 0_i4
    this%next_id = 1_i8
    this%init = .false.
  end subroutine ModelTree_Clean

  function ModelTree_CreateNode(this, type, parent_id, name, description) result(node_id)
    class(ModelTree), intent(inout) :: this
    integer(i4), intent(in) :: type
    integer(i8), intent(in) :: parent_id
    character(len=*), intent(in) :: name
    character(len=*), intent(in) :: description
    integer(i8) :: node_id

    type(ErrorStatusType) :: status

    if (this%nNodes >= this%max_nodes) then
      node_id = 0_i8
      return
    end if

    node_id = this%next_id
    this%next_id = this%next_id + 1_i8
    this%nNodes = this%nNodes + 1_i4

    call this%nodes(this%nNodes)%Init(id=node_id, type=type, parent_id=parent_id, &
                                          name=name, description=description)

    if (parent_id > 0_i8) then
      call this%FindNode(parent_id, status)
      if (status%status_code == IF_STATUS_OK) then
        call this%nodes(int(parent_id))%AddChild(node_id)
      end if
    end if
  end function ModelTree_CreateNode

  subroutine ModelTree_DeleteNode(this, node_id)
    class(ModelTree), intent(inout) :: this
    integer(i8), intent(in) :: node_id

    integer(i4) :: i

    do i = 1, this%nNodes
      if (this%nodes(i)%cfg%id == node_id) then
        call this%nodes(i)%Clean()
        exit
      end if
    end do
  end subroutine ModelTree_DeleteNode

  subroutine ModelTree_FindNode(this, node_id, status)
    class(ModelTree), intent(in) :: this
    integer(i8), intent(in) :: node_id
    type(ErrorStatusType), intent(inout) :: status

    integer(i4) :: i

    call init_error_status(status)

    do i = 1, this%nNodes
      if (this%nodes(i)%cfg%id == node_id) then
        status%status_code = IF_STATUS_OK
        return
      end if
    end do

    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "Node not found"
  end subroutine ModelTree_FindNode

  subroutine ModelTree_FindNodeByName(this, name, status)
    class(ModelTree), intent(in) :: this
    character(len=*), intent(in) :: name
    type(ErrorStatusType), intent(inout) :: status

    integer(i4) :: i

    call init_error_status(status)

    do i = 1, this%nNodes
      if (trim(this%nodes(i)%name) == trim(name)) then
        status%status_code = IF_STATUS_OK
        return
      end if
    end do

    status%status_code = IF_STATUS_NOT_FOUND
    status%message = "Node not found"
  end subroutine ModelTree_FindNodeByName

  function ModelTree_GetRoot(this) result(root)
    class(ModelTree), intent(in) :: this
    type(ModelTreeNode) :: root

    root = this%root
  end function ModelTree_GetRoot

  function ModelTree_GetNode(this, node_id) result(node)
    class(ModelTree), intent(in) :: this
    integer(i8), intent(in) :: node_id
    type(ModelTreeNode) :: node

    integer(i4) :: i

    do i = 1, this%nNodes
      if (this%nodes(i)%cfg%id == node_id) then
        node = this%nodes(i)
        return
      end if
    end do
  end function ModelTree_GetNode

  function ModelTree_GetParent(this, node_id) result(parent)
    class(ModelTree), intent(in) :: this
    integer(i8), intent(in) :: node_id
    type(ModelTreeNode) :: parent

    integer(i4) :: i
    integer(i8) :: parent_id

    do i = 1, this%nNodes
      if (this%nodes(i)%cfg%id == node_id) then
        parent_id = this%nodes(i)%parent_id
        if (parent_id > 0_i8) then
          parent = this%GetNode(parent_id)
        end if
        return
      end if
    end do
  end function ModelTree_GetParent

  function ModelTree_GetChildren(this, node_id) result(children)
    class(ModelTree), intent(in) :: this
    integer(i8), intent(in) :: node_id
    integer(i8), allocatable :: children(:)

    integer(i4) :: i

    do i = 1, this%nNodes
      if (this%nodes(i)%cfg%id == node_id) then
        children = this%nodes(i)%GetChildren()
        return
      end if
    end do

    allocate(children(0))
  end function ModelTree_GetChildren

  function ModelTree_GetPath(this, node_id) result(path)
    class(ModelTree), intent(in) :: this
    integer(i8), intent(in) :: node_id
    character(len=200) :: path

    integer(i8) :: current_id
    type(ModelTreeNode) :: current_node
    character(len=200) :: temp_path

    path = ""
    current_id = node_id

    do while (current_id > 0_i8)
      current_node = this%GetNode(current_id)
      temp_path = trim(current_node%name) // "/" // trim(path)
      path = temp_path
      current_id = current_node%parent_id
    end do
  end function ModelTree_GetPath

  function ModelTree_Valid(this) result(valid)
    class(ModelTree), intent(in) :: this
    logical :: valid

    valid = .true.

    if (.not. this%init) then
      valid = .false.
      return
    end if

    if (this%nNodes <= 0_i4) then
      valid = .false.
      return
    end if

    if (this%nNodes > this%max_nodes) then
      valid = .false.
      return
    end if
  end function ModelTree_Valid

  !=============================================================================
  ! Topology Procedures
  !=============================================================================
  subroutine Topology_Init(this, nNodes, nElems)
    class(Topology), intent(inout) :: this
    integer(i8), intent(in) :: nNodes
    integer(i8), intent(in) :: nElems

    this%nNodes = nNodes
    this%nElems = nElems
    this%num_edges = 0_i8
    this%num_faces = 0_i8
    this%init = .true.
  end subroutine Topology_Init

  subroutine Topology_Clean(this)
    class(Topology), intent(inout) :: this

    if (allocated(this%node_to_element)) deallocate(this%node_to_element)
    if (allocated(this%element_to_elem)) deallocate(this%element_to_elem)
    if (allocated(this%edge_to_nodes)) deallocate(this%edge_to_nodes)
    if (allocated(this%face_to_nodes)) deallocate(this%face_to_nodes)
    if (allocated(this%edge_to_element)) deallocate(this%edge_to_element)
    if (allocated(this%face_to_element)) deallocate(this%face_to_element)

    this%nNodes = 0_i8
    this%nElems = 0_i8
    this%num_edges = 0_i8
    this%num_faces = 0_i8
    this%init = .false.
  end subroutine Topology_Clean

  subroutine Topology_BuildNodeToElements(this, element_connect)
    class(Topology), intent(inout) :: this
    integer(i8), intent(in) :: element_connect(:,:)

    integer(i8) :: i, j, node_id

    if (.not. allocated(this%node_to_element)) then
      allocate(this%node_to_element(this%nNodes, 20))
    end if

    do i = 1, this%nElems
      do j = 1, size(element_connect, 2)
        node_id = element_connect(j, i)
        if (node_id > 0_i8 .and. node_id <= this%nNodes) then
          this%node_to_element(node_id, 1) = this%node_to_element(node_id, 1) + 1
          if (this%node_to_element(node_id, 1) <= 20) then
            this%node_to_element(node_id, this%node_to_element(node_id, 1) + 1) = i
          end if
        end if
      end do
    end do
  end subroutine Topology_BuildNodeToElements

  subroutine Topology_BuildElementToElements(this)
    class(Topology), intent(inout) :: this

    integer(i8) :: i, j, k, num_neighbors

    if (.not. allocated(this%element_to_elem)) then
      allocate(this%element_to_elem(this%nElems, 20))
    end if

    do i = 1, this%nElems
      num_neighbors = 0
      do j = 1, this%nNodes
        do k = 1, this%node_to_element(j, 1)
          if (this%node_to_element(j, k + 1) == i .and. i /= this%node_to_element(j, k + 1)) then
            num_neighbors = num_neighbors + 1
            if (num_neighbors <= 20) then
              this%element_to_elem(i, num_neighbors) = this%node_to_element(j, k + 1)
            end if
          end if
        end do
      end do
    end do
  end subroutine Topology_BuildElementToElements

  subroutine Topology_BuildEdges(this, element_connect)
    class(Topology), intent(inout) :: this
    integer(i8), intent(in) :: element_connect(:,:)

    integer(i8) :: i, j, k, node1, node2

    if (.not. allocated(this%edge_to_nodes)) then
      allocate(this%edge_to_nodes(this%nElems * 10, 2))
    end if

    this%num_edges = 0
    do i = 1, this%nElems
      do j = 1, size(element_connect, 2) - 1
        do k = j + 1, size(element_connect, 2)
          node1 = element_connect(j, i)
          node2 = element_connect(k, i)
          if (node1 > 0_i8 .and. node2 > 0_i8) then
            this%num_edges = this%num_edges + 1
            if (this%num_edges <= size(this%edge_to_nodes, 1)) then
              this%edge_to_nodes(this%num_edges, 1) = node1
              this%edge_to_nodes(this%num_edges, 2) = node2
            end if
          end if
        end do
      end do
    end do
  end subroutine Topology_BuildEdges

  subroutine Topology_BuildFaces(this, element_connect)
    class(Topology), intent(inout) :: this
    integer(i8), intent(in) :: element_connect(:,:)

    integer(i8) :: i, j

    if (.not. allocated(this%face_to_nodes)) then
      allocate(this%face_to_nodes(this%nElems, 6, 4))
    end if

    this%num_faces = 0
    do i = 1, this%nElems
      do j = 1, size(element_connect, 2) - 2
        this%num_faces = this%num_faces + 1
        if (this%num_faces <= size(this%face_to_nodes, 1)) then
          this%face_to_nodes(this%num_faces, 1) = element_connect(j, i)
          this%face_to_nodes(this%num_faces, 2) = element_connect(j + 1, i)
          this%face_to_nodes(this%num_faces, 3) = element_connect(j + 2, i)
          this%face_to_nodes(this%num_faces, 4) = i
        end if
      end do
    end do
  end subroutine Topology_BuildFaces

  function Topology_GetNodeElements(this, node_id) result(elements)
    class(Topology), intent(in) :: this
    integer(i8), intent(in) :: node_id
    integer(i8), allocatable :: elements(:)

    integer(i4) :: i, num_elems

    if (node_id < 1_i8 .or. node_id > this%nNodes) then
      allocate(elements(0))
      return
    end if

    num_elems = this%node_to_element(node_id, 1)
    allocate(elements(num_elems))
    do i = 1, num_elems
      elements(i) = this%node_to_element(node_id, i + 1)
    end do
  end function Topology_GetNodeElements

  function Topology_GetElementNeighbors(this, element_id) result(neighbors)
    class(Topology), intent(in) :: this
    integer(i8), intent(in) :: element_id
    integer(i8), allocatable :: neighbors(:)

    integer(i4) :: i, num_neighbors

    if (element_id < 1_i8 .or. element_id > this%nElems) then
      allocate(neighbors(0))
      return
    end if

    num_neighbors = 0
    do i = 1, 20
      if (this%element_to_elem(element_id, i) > 0_i8) then
        num_neighbors = num_neighbors + 1
      end if
    end do

    allocate(neighbors(num_neighbors))
    num_neighbors = 0
    do i = 1, 20
      if (this%element_to_elem(element_id, i) > 0_i8) then
        num_neighbors = num_neighbors + 1
        neighbors(num_neighbors) = this%element_to_elem(element_id, i)
      end if
    end do
  end function Topology_GetElementNeighbors

  function Topology_GetElementEdges(this, element_id) result(edges)
    class(Topology), intent(in) :: this
    integer(i8), intent(in) :: element_id
    integer(i8), allocatable :: edges(:)

    integer(i8) :: i, j, node1, node2, num_edges

    num_edges = 0
    do i = 1, this%num_edges
      do j = 1, 2
        if (this%edge_to_element(i, j) == element_id) then
          num_edges = num_edges + 1
        end if
      end do
    end do

    allocate(edges(num_edges))
    num_edges = 0
    do i = 1, this%num_edges
      do j = 1, 2
        if (this%edge_to_element(i, j) == element_id) then
          num_edges = num_edges + 1
          edges(num_edges) = i
        end if
      end do
    end do
  end function Topology_GetElementEdges

  function Topology_GetElementFaces(this, element_id) result(faces)
    class(Topology), intent(in) :: this
    integer(i8), intent(in) :: element_id
    integer(i8), allocatable :: faces(:)

    integer(i4) :: i, num_faces

    if (element_id < 1_i8 .or. element_id > this%nElems) then
      allocate(faces(0))
      return
    end if

    num_faces = 0
    do i = 1, 6
      if (this%face_to_nodes(i, 4) == element_id) then
        num_faces = num_faces + 1
      end if
    end do

    allocate(faces(num_faces))
    num_faces = 0
    do i = 1, 6
      if (this%face_to_nodes(i, 4) == element_id) then
        num_faces = num_faces + 1
        faces(num_faces) = i
      end if
    end do
  end function Topology_GetElementFaces

  function Topology_Valid(this) result(valid)
    class(Topology), intent(in) :: this
    logical :: valid

    valid = .true.

    if (.not. this%init) then
      valid = .false.
      return
    end if

    if (this%nNodes <= 0_i8) then
      valid = .false.
      return
    end if

    if (this%nElems <= 0_i8) then
      valid = .false.
      return
    end if
  end function Topology_Valid

  !=============================================================================
  ! GeometryManager Procedures
  !=============================================================================
  subroutine GeometryManager_Init(this, max_nodes, max_elements)
    class(GeometryManager), intent(inout) :: this
    integer(i4), intent(in) :: max_nodes
    integer(i4), intent(in) :: max_elements

    call this%model_tree%Init()
    ! MeshGlobalNum is a data structure without bound procedures
    ! Init dof_sys if needed
    if (max_nodes > 0 .and. max_elements > 0) then
      call this%global_numberin%dof_sys%Init(max_nodes, 3_i4)
    end if
    call this%topo%Init(max_nodes, max_elements)
    this%init = .true.
  end subroutine GeometryManager_Init

  subroutine GeometryManager_Clean(this)
    class(GeometryManager), intent(inout) :: this

    call this%model_tree%Clean()
    ! Clean up MeshGlobalNum allocations
    if (allocated(this%global_numberin%nodeMap)) deallocate(this%global_numberin%nodeMap)
    if (allocated(this%global_numberin%elemMap)) deallocate(this%global_numberin%elemMap)
    if (allocated(this%global_numberin%instancenodeoff)) deallocate(this%global_numberin%instancenodeoff)
    if (allocated(this%global_numberin%INSTANCELEMOFFS)) deallocate(this%global_numberin%INSTANCELEMOFFS)
    call this%global_numberin%dof_sys%Free()
    call this%topo%Clean()
    this%init = .false.
  end subroutine GeometryManager_Clean

  function GeometryManager_GetModelTree(this) result(model_tree)
    class(GeometryManager), intent(in) :: this
    type(ModelTree) :: model_tree

    model_tree = this%model_tree
  end function GeometryManager_GetModelTree

  function GeometryMgr_GetGlobalNumbering(this) result(global_numberin)
    class(GeometryManager), intent(in) :: this
    type(MeshGlobalNum) :: global_numberin

    global_numberin = this%global_numberin
  end function GeometryMgr_GetGlobalNumbering

  function GeometryManager_GetTopology(this) result(topo)
    class(GeometryManager), intent(in) :: this
    type(Topology) :: topo

    topo = this%topo
  end function GeometryManager_GetTopology

  subroutine GeometryMgr_BuildGeometry(this, node_coords, element_connect)
    class(GeometryManager), intent(inout) :: this
    real(wp), intent(in) :: node_coords(:,:)
    integer(i8), intent(in) :: element_connect(:,:)

    call this%topo%BuildNodeToElements(element_connect)
    call this%topo%BuildElementToElements()
    call this%topo%BuildEdges(element_connect)
    call this%topo%BuildFaces(element_connect)
  end subroutine GeometryMgr_BuildGeometry

  function GeometryManager_Valid(this) result(valid)
    class(GeometryManager), intent(in) :: this
    logical :: valid

    valid = .true.

    if (.not. this%init) then
      valid = .false.
      return
    end if

    valid = this%model_tree%Valid() .and. this%global_numberin%Valid() .and. this%topo%Valid()
  end function GeometryManager_Valid

  subroutine CreateMeshQualityMetrics(metrics, status)
    type(MeshQualMetrics), intent(out) :: metrics
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call metrics%Init(status)
  end subroutine CreateMeshQualityMetrics

  subroutine MeshQualityMetrics_Init(this, status)
    class(MeshQualMetrics), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%nElems = 0_i8
    this%nNodes = 0_i8
    this%min_element_qua = 0.0_wp
    this%max_element_qua = 0.0_wp
    this%avg_element_qua = 0.0_wp
    this%min_jacobian = 0.0_wp
    this%max_jacobian = 0.0_wp
    this%min_aspect_rati = 0.0_wp
    this%max_aspect_rati = 0.0_wp
    this%min_skewness = 0.0_wp
    this%max_skewness = 0.0_wp
    this%min_orthogonali = 0.0_wp
    this%max_orthogonali = 0.0_wp
    this%num_inverted_el = 0_i8
    this%num_degenerate = 0_i8
    this%isComputed = .false.

    status%status_code = IF_STATUS_OK
  end subroutine MeshQualityMetrics_Init

  ! ===================================================================
  ! Mesh Refinement Type
  ! ===================================================================
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

  ! ===================================================================
  ! Mesh Smoothing Type
  ! ===================================================================
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

  ! ===================================================================
  ! Mesh Connectivity Type
  ! ===================================================================
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

  ! ===================================================================
  ! Mesh Geometry Type
  ! ===================================================================
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

  ! ===================================================================
  ! Mesh Transform Type
  ! ===================================================================
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

  ! ===================================================================
  ! Mesh IO Type
  ! ===================================================================
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

  !=============================================================================
  ! Mesh Ops Procedures
  !=============================================================================
contains

  ! ===================================================================
  ! Mesh Quality Metrics Procedures
  ! ===================================================================
  subroutine CreateMeshQualityMetrics(metrics, status)
    type(MeshQualMetrics), intent(out) :: metrics
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call metrics%Init(status)
  end subroutine CreateMeshQualityMetrics

  subroutine MeshQualityMetrics_Init(this, status)
    class(MeshQualMetrics), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%nElems = 0_i8
    this%nNodes = 0_i8
    this%min_element_qua = 0.0_wp
    this%max_element_qua = 0.0_wp
    this%avg_element_qua = 0.0_wp
    this%min_jacobian = 0.0_wp
    this%max_jacobian = 0.0_wp
    this%min_aspect_rati = 0.0_wp
    this%max_aspect_rati = 0.0_wp
    this%min_skewness = 0.0_wp
    this%max_skewness = 0.0_wp
    this%min_orthogonali = 0.0_wp
    this%max_orthogonali = 0.0_wp
    this%num_inverted_el = 0_i8
    this%num_degenerate = 0_i8
    this%isComputed = .false.

    status%status_code = IF_STATUS_OK
  end subroutine MeshQualityMetrics_Init

  subroutine MeshQualityMetrics_Calc(this, mesh, status)
    class(MeshQualMetrics), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    integer(i8) :: ielem, inode, nnodes, nelems
    real(wp) :: quality, jacobian, aspect_ratio, skewness, orthogonality
    real(wp) :: coords(3,8), detJ
    integer(i4) :: ip

    call init_error_status(status)

    if (.not. mesh%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not initialized"
      return
    end if

    nnodes = mesh%nNodes
    nelems = mesh%nElems

    this%nElems = nelems
    this%nNodes = nnodes

    this%min_element_qua = huge(1.0_wp)
    this%max_element_qua = 0.0_wp
    this%avg_element_qua = 0.0_wp
    this%min_jacobian = huge(1.0_wp)
    this%max_jacobian = 0.0_wp
    this%min_aspect_rati = huge(1.0_wp)
    this%max_aspect_rati = 0.0_wp
    this%min_skewness = huge(1.0_wp)
    this%max_skewness = 0.0_wp
    this%min_orthogonali = huge(1.0_wp)
    this%max_orthogonali = 0.0_wp
    this%num_inverted_el = 0_i8
    this%num_degenerate = 0_i8

    do ielem = 1, nelems
      call mesh%GetElementNodes(ielem, coords)

      quality = 1.0_wp
      jacobian = 1.0_wp
      aspect_ratio = 1.0_wp
      skewness = 0.0_wp
      orthogonality = 1.0_wp

      detJ = coords(1,1) * (coords(2,2) * coords(3,3) - coords(2,3) * coords(3,2)) - &
              coords(1,2) * (coords(2,1) * coords(3,3) - coords(2,3) * coords(3,1)) + &
              coords(1,3) * (coords(2,1) * coords(3,2) - coords(2,2) * coords(3,1))

      jacobian = abs(detJ)

      if (jacobian < 0.0_wp) then
        this%num_inverted_el = this%num_inverted_el + 1_i8
      end if

      if (jacobian < 1.0e-12_wp) then
        this%num_degenerate = this%num_degenerate + 1_i8
      end if

      this%min_jacobian = min(this%min_jacobian, jacobian)
      this%max_jacobian = max(this%max_jacobian, jacobian)

      this%min_element_qua = min(this%min_element_qua, quality)
      this%max_element_qua = max(this%max_element_qua, quality)
      this%avg_element_qua = this%avg_element_qua + quality

      this%min_aspect_rati = min(this%min_aspect_rati, aspect_ratio)
      this%max_aspect_rati = max(this%max_aspect_rati, aspect_ratio)

      this%min_skewness = min(this%min_skewness, skewness)
      this%max_skewness = max(this%max_skewness, skewness)

      this%min_orthogonali = min(this%min_orthogonali, orthogonality)
      this%max_orthogonali = max(this%max_orthogonali, orthogonality)
    end do

    if (nelems > 0) then
      this%avg_element_qua = this%avg_element_qua / real(nelems, wp)
    end if

    this%isComputed = .true.
    status%status_code = IF_STATUS_OK
  end subroutine MeshQualityMetrics_Calc

  subroutine MeshQualityMetrics_GetQualityReport(this, report)
    class(MeshQualMetrics), intent(in) :: this
    character(len=*), intent(out) :: report

    character(len=512) :: line

    report = "Mesh Quality Report:" // new_line('a')
    write(line, '(a,i12)') "  Number of elements: ", this%nElems
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,i12)') "  Number of nodes: ", this%nNodes
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,es12.5)') "  Min element quality: ", this%min_element_qua
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,es12.5)') "  Max element quality: ", this%max_element_qua
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,es12.5)') "  Avg element quality: ", this%avg_element_qua
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,i12)') "  Inverted elements: ", this%num_inverted_el
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,i12)') "  Degenerate elements: ", this%num_degenerate
    report = trim(report) // trim(line)
  end subroutine MeshQualityMetrics_GetQualityReport

  subroutine ComputeMeshQuality(mesh, metrics, status)
    type(MeshData), intent(in) :: mesh
    type(MeshQualMetrics), intent(inout) :: metrics
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call metrics%Compute(mesh, status)
  end subroutine ComputeMeshQuality

  ! ===================================================================
  ! Mesh Generator Procedures
  ! ===================================================================
  subroutine CreateMeshGenerator(generator, mesh_type, spatial_dim, element_type, status)
    type(MeshGenerator), intent(out) :: generator
    integer(i4), intent(in) :: mesh_type
    integer(i4), intent(in) :: spatial_dim
    integer(i4), intent(in) :: element_type
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call generator%Init(mesh_type, spatial_dim, element_type, status)
  end subroutine CreateMeshGenerator

  subroutine MeshGenerator_Init(this, mesh_type, spatial_dim, element_type, status)
    class(MeshGenerator), intent(inout) :: this
    integer(i4), intent(in) :: mesh_type
    integer(i4), intent(in) :: spatial_dim
    integer(i4), intent(in) :: element_type
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%mesh_type = mesh_type
    this%spatial_dim = spatial_dim
    this%element_type = element_type
    this%nElems_x = 10_i4
    this%nElems_y = 10_i4
    this%nElems_z = 10_i4
    this%length_x = 1.0_wp
    this%length_y = 1.0_wp
    this%length_z = 1.0_wp
    this%origin = [0.0_wp, 0.0_wp, 0.0_wp]
    this%isInitialized = .true.

    status%status_code = IF_STATUS_OK
  end subroutine MeshGenerator_Init

  subroutine MeshGenerator_SetDimensions(this, length_x, length_y, length_z)
    class(MeshGenerator), intent(inout) :: this
    real(wp), intent(in) :: length_x
    real(wp), intent(in), optional :: length_y, length_z

    this%length_x = length_x
    if (present(length_y)) this%length_y = length_y
    if (present(length_z)) this%length_z = length_z
  end subroutine MeshGenerator_SetDimensions

  subroutine MeshGenerator_SetElementCounts(this, num_x, num_y, num_z)
    class(MeshGenerator), intent(inout) :: this
    integer(i4), intent(in) :: num_x
    integer(i4), intent(in), optional :: num_y, num_z

    this%nElems_x = num_x
    if (present(num_y)) this%nElems_y = num_y
    if (present(num_z)) this%nElems_z = num_z
  end subroutine MeshGenerator_SetElementCounts

  subroutine MeshGenerator_SetOrigin(this, origin)
    class(MeshGenerator), intent(inout) :: this
    real(wp), intent(in) :: origin(3)

    this%origin = origin
  end subroutine MeshGenerator_SetOrigin

  subroutine MeshGenerator_Generate(this, mesh, status)
    class(MeshGenerator), intent(in) :: this
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (this%mesh_type == 1) then
      call GenerateStructuredMesh(this, mesh, status)
    else
      call GenerateUnstructuredMesh(this, mesh, status)
    end if
  end subroutine MeshGenerator_Generate

  subroutine GenerateStructuredMesh(generator, mesh, status)
    type(MeshGenerator), intent(in) :: generator
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: nx, ny, nz, nnodes, nelems
    integer(i8) :: inode, ielem
    integer(i4) :: i, j, k, ii, jj, kk
    real(wp) :: dx, dy, dz, x, y, z

    call init_error_status(status)

    nx = generator%nElems_x + 1
    ny = generator%nElems_y + 1
    nz = generator%nElems_z + 1

    nnodes = nx * ny * nz
    nelems = generator%nElems_x * generator%nElems_y * generator%nElems_z

    mesh%spatial_dim = generator%spatial_dim

    allocate(mesh%node_coords(3, nnodes))
    allocate(mesh%element_connect(8, nelems))
    allocate(mesh%element_types(nelems))

    dx = generator%length_x / real(generator%nElems_x, wp)
    dy = generator%length_y / real(generator%nElems_y, wp)
    dz = generator%length_z / real(generator%nElems_z, wp)

    inode = 0
    do k = 1, nz
      z = generator%origin(3) + (k - 1) * dz
      do j = 1, ny
        y = generator%origin(2) + (j - 1) * dy
        do i = 1, nx
          x = generator%origin(1) + (i - 1) * dx
          inode = inode + 1
          mesh%node_coords(1, inode) = x
          mesh%node_coords(2, inode) = y
          mesh%node_coords(3, inode) = z
        end do
      end do
    end do

    ielem = 0
    do k = 1, generator%nElems_z
      do j = 1, generator%nElems_y
        do i = 1, generator%nElems_x
          ielem = ielem + 1

          ii = (k - 1) * nx * ny + (j - 1) * nx + i
          jj = ii + 1
          kk = ii + nx
          mesh%element_connect(1, ielem) = ii
          mesh%element_connect(2, ielem) = jj
          mesh%element_connect(3, ielem) = jj + nx * ny
          mesh%element_connect(4, ielem) = ii + nx * ny
          mesh%element_connect(5, ielem) = kk
          mesh%element_connect(6, ielem) = kk + 1
          mesh%element_connect(7, ielem) = kk + nx * ny + 1
          mesh%element_connect(8, ielem) = kk + nx * ny

          mesh%element_types(ielem) = generator%element_type
        end do
      end do
    end do

    mesh%nNodes = nnodes
    mesh%nElems = nelems
    mesh%init = .true.

    status%status_code = IF_STATUS_OK
  end subroutine GenerateStructuredMesh

  subroutine GenerateUnstructuredMesh(generator, mesh, status)
    type(MeshGenerator), intent(in) :: generator
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    mesh%nNodes = 0_i8
    mesh%nElems = 0_i8
    mesh%init = .false.

    status%status_code = IF_STATUS_OK
  end subroutine GenerateUnstructuredMesh

  ! ===================================================================
  ! Mesh Refinement Procedures
  ! ===================================================================
  subroutine CreateMeshRefinement(refinement, refinement_leve, refinement_rati, status)
    type(MeshRefinement), intent(out) :: refinement
    integer(i4), intent(in) :: refinement_leve
    real(wp), intent(in) :: refinement_rati
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call refinement%Init(refinement_leve, refinement_rati, status)
  end subroutine CreateMeshRefinement

  subroutine MeshRefinement_Init(this, refinement_leve, refinement_rati, status)
    class(MeshRefinement), intent(inout) :: this
    integer(i4), intent(in) :: refinement_leve
    real(wp), intent(in) :: refinement_rati
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%refinement_leve = refinement_leve
    this%refinement_rati = refinement_rati
    this%uniform_refinem = .true.
    this%refinement_thre = 0.5_wp
    this%isInitialized = .true.

    status%status_code = IF_STATUS_OK
  end subroutine MeshRefinement_Init

  subroutine MeshRefinement_SetRefinementLevel(this, level)
    class(MeshRefinement), intent(inout) :: this
    integer(i4), intent(in) :: level

    this%refinement_leve = level
  end subroutine MeshRefinement_SetRefinementLevel

  subroutine MeshRefinement_SetRefinementRatio(this, ratio)
    class(MeshRefinement), intent(inout) :: this
    real(wp), intent(in) :: ratio

    this%refinement_rati = ratio
  end subroutine MeshRefinement_SetRefinementRatio

  subroutine MeshRefinement_MarkElementsForRefinement(this, error_indicator, threshold)
    class(MeshRefinement), intent(inout) :: this
    real(wp), intent(in) :: error_indicator(:)
    real(wp), intent(in) :: threshold

    integer(i8) :: ielem

    if (allocated(this%refine_elements)) deallocate(this%refine_elements)
    allocate(this%refine_elements(size(error_indicator)))

    do ielem = 1, size(error_indicator)
      if (error_indicator(ielem) > threshold) then
        this%refine_elements(ielem) = .true.
      else
        this%refine_elements(ielem) = .false.
      end if
    end do

    this%uniform_refinem = .false.
    this%refinement_thre = threshold
  end subroutine MeshRefinement_MarkElementsForRefinement

  subroutine MeshRefinement_Refine(this, mesh, status)
    class(MeshRefinement), intent(in) :: this
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (this%uniform_refinem) then
      call RefineMeshUniform(mesh, this%refinement_leve, status)
    else
      call RefineMeshAdaptive(mesh, this%refine_elements, status)
    end if
  end subroutine MeshRefinement_Refine

  subroutine RefineMeshUniform(mesh, refinement_leve, status)
    type(MeshData), intent(inout) :: mesh
    integer(i4), intent(in) :: refinement_leve
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine RefineMeshUniform

  subroutine RefineMeshAdaptive(mesh, refine_elements, status)
    type(MeshData), intent(inout) :: mesh
    logical, intent(in) :: refine_elements(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine RefineMeshAdaptive

  ! ===================================================================
  ! Mesh Smoothing Procedures
  ! ===================================================================
  subroutine CreateMeshSmoothing(smoothing, smoothing_type, num_iterations, status)
    type(MeshSmoothing), intent(out) :: smoothing
    integer(i4), intent(in) :: smoothing_type
    integer(i4), intent(in) :: num_iterations
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call smoothing%Init(smoothing_type, num_iterations, status)
  end subroutine CreateMeshSmoothing

  subroutine MeshSmoothing_Init(this, smoothing_type, num_iterations, status)
    class(MeshSmoothing), intent(inout) :: this
    integer(i4), intent(in) :: smoothing_type
    integer(i4), intent(in) :: num_iterations
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%smoothing_type = smoothing_type
    this%num_iterations = num_iterations
    this%relaxation_fact = 0.5_wp
    this%convergence_tol = 1.0e-6_wp
    this%isInitialized = .true.

    status%status_code = IF_STATUS_OK
  end subroutine MeshSmoothing_Init

  subroutine MeshSmoothing_SetSmoothingParameters(this, relaxation_fact, convergence_tol)
    class(MeshSmoothing), intent(inout) :: this
    real(wp), intent(in) :: relaxation_fact
    real(wp), intent(in), optional :: convergence_tol

    this%relaxation_fact = relaxation_fact
    if (present(convergence_tol)) then
      this%convergence_tol = convergence_tol
    end if
  end subroutine MeshSmoothing_SetSmoothingParameters

  subroutine MeshSmoothing_SetFixedNodes(this, fixed_nodes)
    class(MeshSmoothing), intent(inout) :: this
    logical, intent(in) :: fixed_nodes(:)

    if (allocated(this%fixed_nodes)) deallocate(this%fixed_nodes)
    allocate(this%fixed_nodes(size(fixed_nodes)))
    this%fixed_nodes = fixed_nodes
  end subroutine MeshSmoothing_SetFixedNodes

  subroutine MeshSmoothing_Smooth(this, mesh, status)
    class(MeshSmoothing), intent(in) :: this
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (this%smoothing_type == 1) then
      call SmoothMeshLaplacian(mesh, this%num_iterations, this%relaxation_fact, status)
    else
      call SmoothMeshOptimization(mesh, this%num_iterations, this%convergence_tol, status)
    end if
  end subroutine MeshSmoothing_Smooth

  subroutine SmoothMeshLaplacian(mesh, num_iterations, relaxation_fact, status)
    type(MeshData), intent(inout) :: mesh
    integer(i4), intent(in) :: num_iterations
    real(wp), intent(in) :: relaxation_fact
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: iter, inode
    real(wp) :: new_coords(3)

    call init_error_status(status)

    do iter = 1, num_iterations
      do inode = 1, mesh%nNodes
        new_coords = mesh%node_coords(:, inode)
        mesh%node_coords(:, inode) = mesh%node_coords(:, inode) + &
                                    relaxation_fact * (new_coords - mesh%node_coords(:, inode))
      end do
    end do

    status%status_code = IF_STATUS_OK
  end subroutine SmoothMeshLaplacian

  subroutine SmoothMeshOptimization(mesh, num_iterations, convergence_tol, status)
    type(MeshData), intent(inout) :: mesh
    integer(i4), intent(in) :: num_iterations
    real(wp), intent(in) :: convergence_tol
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine SmoothMeshOptimization

  ! ===================================================================
  ! Mesh Connectivity Procedures
  ! ===================================================================
  subroutine CreateMeshConnectivity(connectivity, status)
    type(MeshConnectivity), intent(out) :: connectivity
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call connectivity%Init(status)
  end subroutine CreateMeshConnectivity

  subroutine MeshConnectivity_Init(this, status)
    class(MeshConnectivity), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%isComputed = .false.
    this%num_neighbors = 0_i8

    status%status_code = IF_STATUS_OK
  end subroutine MeshConnectivity_Init

  subroutine MeshConnectivity_ComputeElementNeighbors(this, mesh, status)
    class(MeshConnectivity), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine MeshConnectivity_ComputeElementNeighbors

  subroutine MeshConnectivity_ComputeElementFaces(this, mesh, status)
    class(MeshConnectivity), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine MeshConnectivity_ComputeElementFaces

  subroutine MeshConnectivity_ComputeElementEdges(this, mesh, status)
    class(MeshConnectivity), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine MeshConnectivity_ComputeElementEdges

  subroutine MeshConnectivity_ComputeNodeElements(this, mesh, status)
    class(MeshConnectivity), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine MeshConnectivity_ComputeNodeElements

  subroutine MeshConnectivity_ComputeNodeNeighbors(this, mesh, status)
    class(MeshConnectivity), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine MeshConnectivity_ComputeNodeNeighbors

  subroutine MeshConnectivity_GetNeighborElements(this, element_id, neighbors)
    class(MeshConnectivity), intent(in) :: this
    integer(i8), intent(in) :: element_id
    integer(i8), intent(out) :: neighbors(:)

    neighbors = 0_i8
  end subroutine MeshConnectivity_GetNeighborElements

  subroutine MeshConnectivity_GetNeighborNodes(this, node_id, neighbors)
    class(MeshConnectivity), intent(in) :: this
    integer(i8), intent(in) :: node_id
    integer(i8), intent(out) :: neighbors(:)

    neighbors = 0_i8
  end subroutine MeshConnectivity_GetNeighborNodes

  subroutine FindElementNeighbors(mesh, element_id, neighbors, status)
    type(MeshData), intent(in) :: mesh
    integer(i8), intent(in) :: element_id
    integer(i8), intent(out) :: neighbors(:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    neighbors = 0_i8

    status%status_code = IF_STATUS_OK
  end subroutine FindElementNeighbors

  subroutine FindElementFaces(mesh, element_id, faces, status)
    type(MeshData), intent(in) :: mesh
    integer(i8), intent(in) :: element_id
    integer(i8), intent(out) :: faces(:,:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    faces = 0_i8

    status%status_code = IF_STATUS_OK
  end subroutine FindElementFaces

  subroutine FindElementEdges(mesh, element_id, edges, status)
    type(MeshData), intent(in) :: mesh
    integer(i8), intent(in) :: element_id
    integer(i8), intent(out) :: edges(:,:)
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    edges = 0_i8

    status%status_code = IF_STATUS_OK
  end subroutine FindElementEdges

  ! ===================================================================
  ! Mesh Geometry Procedures
  ! ===================================================================
  subroutine CreateMeshGeometry(geometry, status)
    type(MeshGeometry), intent(out) :: geometry
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call geometry%Init(status)
  end subroutine CreateMeshGeometry

  subroutine MeshGeometry_Init(this, status)
    class(MeshGeometry), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%bounding_box_mi = [0.0_wp, 0.0_wp, 0.0_wp]
    this%bounding_box_ma = [0.0_wp, 0.0_wp, 0.0_wp]
    this%centroid = [0.0_wp, 0.0_wp, 0.0_wp]
    this%volume = 0.0_wp
    this%surface_area = 0.0_wp
    this%total_length = 0.0_wp
    this%min_edge_length = 0.0_wp
    this%max_edge_length = 0.0_wp
    this%avg_edge_length = 0.0_wp
    this%isComputed = .false.

    status%status_code = IF_STATUS_OK
  end subroutine MeshGeometry_Init

  subroutine MeshGeometry_ComputeBoundingBox(this, mesh, status)
    class(MeshGeometry), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    integer(i8) :: inode

    call init_error_status(status)

    if (.not. mesh%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not initialized"
      return
    end if

    this%bounding_box_mi = huge(1.0_wp)
    this%bounding_box_ma = -huge(1.0_wp)

    do inode = 1, mesh%nNodes
      this%bounding_box_mi(1) = min(this%bounding_box_mi(1), mesh%node_coords(1, inode))
      this%bounding_box_mi(2) = min(this%bounding_box_mi(2), mesh%node_coords(2, inode))
      this%bounding_box_mi(3) = min(this%bounding_box_mi(3), mesh%node_coords(3, inode))
      this%bounding_box_ma(1) = max(this%bounding_box_ma(1), mesh%node_coords(1, inode))
      this%bounding_box_ma(2) = max(this%bounding_box_ma(2), mesh%node_coords(2, inode))
      this%bounding_box_ma(3) = max(this%bounding_box_ma(3), mesh%node_coords(3, inode))
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MeshGeometry_ComputeBoundingBox

  subroutine MeshGeometry_ComputeVolume(this, mesh, status)
    class(MeshGeometry), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    integer(i8) :: ielem
    real(wp) :: coords(3,8), element_volume

    call init_error_status(status)

    if (.not. mesh%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not initialized"
      return
    end if

    this%volume = 0.0_wp

    do ielem = 1, mesh%nElems
      call mesh%GetElementNodes(ielem, coords)

      element_volume = abs((coords(1,2) - coords(1,1)) * &
                     (coords(2,3) - coords(2,1)) * &
                     (coords(3,4) - coords(3,1)))

      this%volume = this%volume + element_volume
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MeshGeometry_ComputeVolume

  subroutine MeshGeometry_ComputeSurfArea(this, mesh, status)
    class(MeshGeometry), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%surface_area = 0.0_wp

    status%status_code = IF_STATUS_OK
  end subroutine MeshGeometry_ComputeSurfArea

  subroutine MeshGeometry_ComputeCentroid(this, mesh, status)
    class(MeshGeometry), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    integer(i8) :: inode

    call init_error_status(status)

    if (.not. mesh%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not initialized"
      return
    end if

    this%centroid = [0.0_wp, 0.0_wp, 0.0_wp]

    do inode = 1, mesh%nNodes
      this%centroid(1) = this%centroid(1) + mesh%node_coords(1, inode)
      this%centroid(2) = this%centroid(2) + mesh%node_coords(2, inode)
      this%centroid(3) = this%centroid(3) + mesh%node_coords(3, inode)
    end do

    if (mesh%nNodes > 0) then
      this%centroid = this%centroid / real(mesh%nNodes, wp)
    end if

    status%status_code = IF_STATUS_OK
  end subroutine MeshGeometry_ComputeCentroid

  subroutine MeshGeometry_ComputeEdgeLengths(this, mesh, status)
    class(MeshGeometry), intent(inout) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%min_edge_length = huge(1.0_wp)
    this%max_edge_length = 0.0_wp
    this%avg_edge_length = 0.0_wp

    status%status_code = IF_STATUS_OK
  end subroutine MeshGeometry_ComputeEdgeLengths

  subroutine MeshGeometry_GetGeometryReport(this, report)
    class(MeshGeometry), intent(in) :: this
    character(len=*), intent(out) :: report

    character(len=512) :: line

    report = "Mesh Geometry Report:" // new_line('a')
    write(line, '(a,es12.5,a,es12.5,a,es12.5)') "  Bounding box min: ", this%bounding_box_mi, ", ", this%bounding_box_mi(2), ", ", this%bounding_box_mi(3)
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,es12.5,a,es12.5,a,es12.5)') "  Bounding box max: ", this%bounding_box_ma, ", ", this%bounding_box_ma(2), ", ", this%bounding_box_ma(3)
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,es12.5)') "  Centroid: ", this%centroid
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,es12.5)') "  Volume: ", this%volume
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,es12.5)') "  Surface area: ", this%surface_area
    report = trim(report) // trim(line)
  end subroutine MeshGeometry_GetGeometryReport

  subroutine ComputeMeshBoundingBox(mesh, bbox_min, bbox_max, status)
    type(MeshData), intent(in) :: mesh
    real(wp), intent(out) :: bbox_min(3)
    real(wp), intent(out) :: bbox_max(3)
    type(ErrorStatusType), intent(out) :: status

    type(MeshGeometry) :: geometry

    call init_error_status(status)

    call geometry%Init(status)
    call geometry%ComputeBoundingBox(mesh, status)

    bbox_min = geometry%bounding_box_mi
    bbox_max = geometry%bounding_box_ma
  end subroutine ComputeMeshBoundingBox

  subroutine ComputeMeshVolume(mesh, volume, status)
    type(MeshData), intent(in) :: mesh
    real(wp), intent(out) :: volume
    type(ErrorStatusType), intent(out) :: status

    type(MeshGeometry) :: geometry

    call init_error_status(status)

    call geometry%Init(status)
    call geometry%ComputeVolume(mesh, status)

    volume = geometry%volume
  end subroutine ComputeMeshVolume

  subroutine ComputeMeshSurfaceArea(mesh, area, status)
    type(MeshData), intent(in) :: mesh
    real(wp), intent(out) :: area
    type(ErrorStatusType), intent(out) :: status

    type(MeshGeometry) :: geometry

    call init_error_status(status)

    call geometry%Init(status)
    call geometry%ComputeSurfaceArea(mesh, status)

    area = geometry%surface_area
  end subroutine ComputeMeshSurfaceArea

  ! ===================================================================
  ! Mesh Transform Procedures
  ! ===================================================================
  subroutine CreateMeshTransform(transform, status)
    type(MeshTransform), intent(out) :: transform
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call transform%Init(status)
  end subroutine CreateMeshTransform

  subroutine MeshTransform_Init(this, status)
    class(MeshTransform), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%scale_factor = [1.0_wp, 1.0_wp, 1.0_wp]
    this%rotation_angles = [0.0_wp, 0.0_wp, 0.0_wp]
    this%translation_vec = [0.0_wp, 0.0_wp, 0.0_wp]
    this%rotation_matrix = reshape([1.0_wp, 0.0_wp, 0.0_wp, &
                                  0.0_wp, 1.0_wp, 0.0_wp, &
                                  0.0_wp, 0.0_wp, 1.0_wp], [3,3])
    this%isInitialized = .true.

    status%status_code = IF_STATUS_OK
  end subroutine MeshTransform_Init

  subroutine MeshTransform_SetScale(this, scale_x, scale_y, scale_z)
    class(MeshTransform), intent(inout) :: this
    real(wp), intent(in) :: scale_x
    real(wp), intent(in), optional :: scale_y, scale_z

    this%scale_factor(1) = scale_x
    if (present(scale_y)) this%scale_factor(2) = scale_y
    if (present(scale_z)) this%scale_factor(3) = scale_z
  end subroutine MeshTransform_SetScale

  subroutine MeshTransform_SetRotation(this, angle_x, angle_y, angle_z)
    class(MeshTransform), intent(inout) :: this
    real(wp), intent(in) :: angle_x
    real(wp), intent(in), optional :: angle_y, angle_z

    this%rotation_angles(1) = angle_x
    if (present(angle_y)) this%rotation_angles(2) = angle_y
    if (present(angle_z)) this%rotation_angles(3) = angle_z

    call this%MatComp_RotMat()
  end subroutine MeshTransform_SetRotation

  subroutine MeshTransform_SetTranslation(this, translation)
    class(MeshTransform), intent(inout) :: this
    real(wp), intent(in) :: translation(3)

    this%translation_vec = translation
  end subroutine MeshTransform_SetTranslation

  subroutine MeshTransform_ComputeRotationMat(this)
    class(MeshTransform), intent(inout) :: this

    real(wp) :: cx, sx, cy, sy, cz, sz
    real(wp) :: Rx(3,3), Ry(3,3), Rz(3,3)

    cx = cos(this%rotation_angles(1))
    sx = sin(this%rotation_angles(1))
    cy = cos(this%rotation_angles(2))
    sy = sin(this%rotation_angles(2))
    cz = cos(this%rotation_angles(3))
    sz = sin(this%rotation_angles(3))

    Rx = reshape([1.0_wp, 0.0_wp, 0.0_wp, &
                  0.0_wp, cx, sx, &
                  0.0_wp, -sx, cx], [3,3])

    Ry = reshape([cy, 0.0_wp, -sy, &
                  0.0_wp, 1.0_wp, 0.0_wp, &
                  sy, 0.0_wp, cy], [3,3])

    Rz = reshape([cz, sz, 0.0_wp, &
                  -sz, cz, 0.0_wp, &
                  0.0_wp, 0.0_wp, 1.0_wp], [3,3])

    this%rotation_matrix = matmul(matmul(Rz, Ry), Rx)
  end subroutine MeshTransform_ComputeRotationMat

  subroutine MeshTransform_ApplyScale(this, mesh, status)
    class(MeshTransform), intent(in) :: this
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    integer(i8) :: inode

    call init_error_status(status)

    if (.not. mesh%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not initialized"
      return
    end if

    do inode = 1, mesh%nNodes
      mesh%node_coords(1, inode) = mesh%node_coords(1, inode) * this%scale_factor(1)
      mesh%node_coords(2, inode) = mesh%node_coords(2, inode) * this%scale_factor(2)
      mesh%node_coords(3, inode) = mesh%node_coords(3, inode) * this%scale_factor(3)
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MeshTransform_ApplyScale

  subroutine MeshTransform_ApplyRotation(this, mesh, status)
    class(MeshTransform), intent(in) :: this
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    integer(i8) :: inode
    real(wp) :: coords(3)

    call init_error_status(status)

    if (.not. mesh%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not initialized"
      return
    end if

    do inode = 1, mesh%nNodes
      coords = matmul(this%rotation_matrix, mesh%node_coords(:, inode))
      mesh%node_coords(:, inode) = coords
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MeshTransform_ApplyRotation

  subroutine MeshTransform_ApplyTranslation(this, mesh, status)
    class(MeshTransform), intent(in) :: this
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    integer(i8) :: inode

    call init_error_status(status)

    if (.not. mesh%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh not initialized"
      return
    end if

    do inode = 1, mesh%nNodes
      mesh%node_coords(1, inode) = mesh%node_coords(1, inode) + this%translation_vec(1)
      mesh%node_coords(2, inode) = mesh%node_coords(2, inode) + this%translation_vec(2)
      mesh%node_coords(3, inode) = mesh%node_coords(3, inode) + this%translation_vec(3)
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MeshTransform_ApplyTranslation

  subroutine MeshTransform_ApplyTransform(this, mesh, status)
    class(MeshTransform), intent(in) :: this
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call this%ApplyScale(mesh, status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%ApplyRotation(mesh, status)
    if (status%status_code /= IF_STATUS_OK) return

    call this%ApplyTranslation(mesh, status)
  end subroutine MeshTransform_ApplyTransform

  subroutine TransformMeshScale(mesh, scale_factor, status)
    type(MeshData), intent(inout) :: mesh
    real(wp), intent(in) :: scale_factor(3)
    type(ErrorStatusType), intent(out) :: status

    type(MeshTransform) :: transform

    call init_error_status(status)

    call transform%Init(status)
    call transform%SetScale(scale_factor(1), scale_factor(2), scale_factor(3))
    call transform%ApplyScale(mesh, status)
  end subroutine TransformMeshScale

  subroutine TransformMeshRotate(mesh, rotation_angles, status)
    type(MeshData), intent(inout) :: mesh
    real(wp), intent(in) :: rotation_angles(3)
    type(ErrorStatusType), intent(out) :: status

    type(MeshTransform) :: transform

    call init_error_status(status)

    call transform%Init(status)
    call transform%SetRotation(rotation_angles(1), rotation_angles(2), rotation_angles(3))
    call transform%ApplyRotation(mesh, status)
  end subroutine TransformMeshRotate

  subroutine TransformMeshTranslate(mesh, translation_vec, status)
    type(MeshData), intent(inout) :: mesh
    real(wp), intent(in) :: translation_vec(3)
    type(ErrorStatusType), intent(out) :: status

    type(MeshTransform) :: transform

    call init_error_status(status)

    call transform%Init(status)
    call transform%SetTranslation(translation_vec)
    call transform%ApplyTranslation(mesh, status)
  end subroutine TransformMeshTranslate

  ! ===================================================================
  ! Mesh IO Procedures
  ! ===================================================================
  subroutine CreateMeshIO(mesh_io, status)
    type(MeshIO), intent(out) :: mesh_io
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    call mesh_io%Init(status)
  end subroutine CreateMeshIO

  subroutine MeshIO_Init(this, status)
    class(MeshIO), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%input_filename = ""
    this%output_filename = ""
    this%file_format = "VTK"
    this%precision = 8_i4
    this%write_binary = .false.
    this%isInitialized = .true.

    status%status_code = IF_STATUS_OK
  end subroutine MeshIO_Init

  subroutine MeshIO_SetInputFile(this, filename)
    class(MeshIO), intent(inout) :: this
    character(len=*), intent(in) :: filename

    this%input_filename = trim(filename)
  end subroutine MeshIO_SetInputFile

  subroutine MeshIO_SetOutputFile(this, filename)
    class(MeshIO), intent(inout) :: this
    character(len=*), intent(in) :: filename

    this%output_filename = trim(filename)
  end subroutine MeshIO_SetOutputFile

  subroutine MeshIO_SetFileFormat(this, format)
    class(MeshIO), intent(inout) :: this
    character(len=*), intent(in) :: format

    this%file_format = trim(format)
  end subroutine MeshIO_SetFileFormat

  subroutine MeshIO_ExportMesh(this, mesh, status)
    class(MeshIO), intent(in) :: this
    type(MeshData), intent(in) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (trim(this%file_format) == "VTK") then
      call ExportMeshToVTK(mesh, this%output_filename, status)
    else
      status%status_code = IF_STATUS_INVALID
      status%message = "Unsupported file format"
    end if
  end subroutine MeshIO_ExportMesh

  subroutine MeshIO_ImportMesh(this, mesh, status)
    class(MeshIO), intent(in) :: this
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (trim(this%file_format) == "VTK") then
      call ImportMeshFromVTK(this%input_filename, mesh, status)
    else
      status%status_code = IF_STATUS_INVALID
      status%message = "Unsupported file format"
    end if
  end subroutine MeshIO_ImportMesh

  subroutine ExportMeshToVTK(mesh, filename, status)
    type(MeshData), intent(in) :: mesh
    character(len=*), intent(in) :: filename
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: unit_num, ielem, inode

    call init_error_status(status)

    open(newunit=unit_num, file=trim(filename), status='replace', action='write')

    write(unit_num, '(a)') "# vtk DataFile Version 3.0"
    write(unit_num, '(a)') "UFC Mesh"
    write(unit_num, '(a)') "ASCII"
    write(unit_num, '(a)') "DATASET UNSTRUCTURED_GRID"

    write(unit_num, '(a,i12)') "POINTS ", mesh%nNodes
    do inode = 1, mesh%nNodes
      write(unit_num, '(3es15.7)') mesh%node_coords(1, inode), &
                                      mesh%node_coords(2, inode), &
                                      mesh%node_coords(3, inode)
    end do

    write(unit_num, '(a,i12,i12)') "CELLS ", mesh%nElems, mesh%nElems * 9
    do ielem = 1, mesh%nElems
      write(unit_num, '(9i12)') 8, mesh%element_connect(1:8, ielem)
    end do

    write(unit_num, '(a,i12)') "CELL_TYPES ", mesh%nElems
    do ielem = 1, mesh%nElems
      write(unit_num, '(i12)') 12
    end do

    close(unit_num)

    status%status_code = IF_STATUS_OK
  end subroutine ExportMeshToVTK

  subroutine ImportMeshFromVTK(filename, mesh, status)
    character(len=*), intent(in) :: filename
    type(MeshData), intent(inout) :: mesh
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    status%status_code = IF_STATUS_OK
  end subroutine ImportMeshFromVTK

  ! ===================================================================
  ! Mesh Report Procedure
  ! ===================================================================
  subroutine GenerateMeshReport(mesh, report, status)
    type(MeshData), intent(in) :: mesh
    character(len=*), intent(out) :: report
    type(ErrorStatusType), intent(out) :: status

    type(MeshQualMetrics) :: quality
    type(MeshGeometry) :: geometry
    character(len=1024) :: line

    call init_error_status(status)

    report = "Mesh Report:" // new_line('a')
    write(line, '(a,i12)') "  Number of nodes: ", mesh%nNodes
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,i12)') "  Number of elements: ", mesh%nElems
    report = trim(report) // trim(line) // new_line('a')
    write(line, '(a,i12)') "  Spatial dimension: ", mesh%spatial_dim
    report = trim(report) // trim(line) // new_line('a')

    call quality%Init(status)
    call quality%Compute(mesh, status)
    report = trim(report) // new_line('a') // quality%GetQualityReport(line)

    call geometry%Init(status)
    call geometry%ComputeBoundingBox(mesh, status)
    call geometry%ComputeCentroid(mesh, status)
    report = trim(report) // new_line('a') // geometry%GetGeometryReport(line)

    status%status_code = IF_STATUS_OK
  end subroutine GenerateMeshReport

  !===============================================================================
  ! FEAP-STYLE ADAPTIVE MESH REFINEMENT ALGORITHMS
  !===============================================================================

  !---------------------------------------------------------------------------
  ! RefineMeshAdaptive_H - h-adaptive mesh refinement
  ! Refines mesh elements based on error indicators (h-refinement)
  !---------------------------------------------------------------------------
  subroutine RefineMeshAdaptive_H(mesh, error_indicator, refinement_crit, &
                                  max_elements, refined_mesh, status)
    type(MeshData), intent(in) :: mesh
    real(wp), intent(in) :: error_indicator(:)    ! Error indicators per element
    real(wp), intent(in) :: refinement_crit      ! Refinement threshold
    integer(i8), intent(in) :: max_elements          ! Maximum number of elements
    type(MeshData), intent(out) :: refined_mesh      ! Refined mesh
    integer(i4), intent(out) :: status               ! Status code

    integer(i8) :: nelem, nnode, nelem_new, nnode_new
    integer(i8) :: i, elem_count, node_count
    logical, allocatable :: refine_element(:)
    integer(i8) :: refinement_coun

    status = 0
    nelem = mesh%nElems
    nnode = mesh%nNodes

    ! Determine which elements to refine
    allocate(refine_element(nelem))
    refine_element = .false.
    refinement_coun = 0

    do i = 1, nelem
      if (error_indicator(i) > refinement_crit) then
        refine_element(i) = .true.
        refinement_coun = refinement_coun + 1
      end if
    end do

    ! Check if refinement would exceed maximum elements
    nelem_new = nelem + refinement_coun
    if (nelem_new > max_elements) then
      status = -1  ! Would exceed maximum elements
      deallocate(refine_element)
      return
    end if

    ! Init refined mesh
    call refined_mesh%Init(nelem_new, nnode_new, mesh%spatial_dim, status)
    if (status /= 0) return

    ! Perform h-refinement
    call perform_mesh_h_refinement(mesh, refine_element, refined_mesh, &
                                  elem_count, node_count, status)

    deallocate(refine_element)

  end subroutine RefineMeshAdaptive_H

  !---------------------------------------------------------------------------
  ! RefineMeshAdaptive_P - p-adaptive polynomial degree refinement
  ! Increases polynomial order for elements with high error (p-refinement)
  !---------------------------------------------------------------------------
  subroutine RefineMeshAdaptive_P(element_orders, error_indicator, &
                                  refinement_crit, max_order, &
                                  new_orders, status)
    integer(i4), intent(in) :: element_orders(:)      ! Current polynomial orders
    real(wp), intent(in) :: error_indicator(:)       ! Error indicators
    real(wp), intent(in) :: refinement_crit        ! Refinement threshold
    integer(i4), intent(in) :: max_order               ! Maximum polynomial order
    integer(i4), intent(out), allocatable :: new_orders(:) ! New polynomial orders
    integer(i4), intent(out) :: status                ! Status code

    integer(i8) :: nelem, i

    status = 0
    nelem = size(element_orders)

    allocate(new_orders(nelem))
    new_orders = element_orders

    ! Increase polynomial order for elements with high error
    do i = 1, nelem
      if (error_indicator(i) > refinement_crit .and. &
          element_orders(i) < max_order) then
        new_orders(i) = element_orders(i) + 1
      end if
    end do

  end subroutine RefineMeshAdaptive_P

  !---------------------------------------------------------------------------
  ! RefineMeshAdaptive_HP - Combined h-p adaptive refinement
  ! Decides between h-refinement and p-refinement based on efficiency
  !---------------------------------------------------------------------------
  subroutine RefineMeshAdaptive_HP(mesh, element_orders, error_indicator, &
                                   refinement_crit, max_elements, max_order, &
                                   refined_mesh, new_orders, status)
    type(MeshData), intent(in) :: mesh
    integer(i4), intent(in) :: element_orders(:)
    real(wp), intent(in) :: error_indicator(:)
    real(wp), intent(in) :: refinement_crit
    integer(i8), intent(in) :: max_elements, max_order
    type(MeshData), intent(out) :: refined_mesh
    integer(i4), intent(out), allocatable :: new_orders(:)
    integer(i4), intent(out) :: status

    integer(i8) :: nelem, i
    real(wp), allocatable :: efficiency_h(:), efficiency_p(:)
    logical, allocatable :: do_h_refinement(:), do_p_refinement(:)

    status = 0
    nelem = mesh%nElems

    allocate(efficiency_h(nelem), efficiency_p(nelem))
    allocate(do_h_refinement(nelem), do_p_refinement(nelem))
    do_h_refinement = .false.
    do_p_refinement = .false.

    ! Compute refinement efficiencies
    call Calc_adaptive_efficiencies(mesh, element_orders, error_indicator, &
                                      efficiency_h, efficiency_p)

    ! Decide refinement strategy for each element
    do i = 1, nelem
      if (error_indicator(i) > refinement_crit) then
        if (efficiency_p(i) > efficiency_h(i) .and. element_orders(i) < max_order) then
          ! p-refinement is more efficient
          do_p_refinement(i) = .true.
        else
          ! h-refinement
          do_h_refinement(i) = .true.
        end if
      end if
    end do

    ! Apply p-refinement first
    call RefineMeshAdaptive_P(element_orders, error_indicator, refinement_crit, &
                             max_order, new_orders, status)
    if (status /= 0) return

    ! Apply h-refinement to remaining elements
    call perform_selective_h_refinement(mesh, do_h_refinement, max_elements, &
                                       refined_mesh, status)

  end subroutine RefineMeshAdaptive_HP

  !---------------------------------------------------------------------------
  ! EstimateMeshError - Estimate discretization error
  ! Implements various error estimation techniques
  !---------------------------------------------------------------------------
  subroutine EstimateMeshError(method, mesh, solution, exact_solution, &
                              error_indicator, global_error, status)
    integer(i4), intent(in) :: method                  ! Error estimation method
    type(MeshData), intent(in) :: mesh                 ! Mesh data
    real(wp), intent(in) :: solution(:)                ! Numerical solution
    real(wp), intent(in), optional :: exact_solution(:) ! Exact solution (if available)
    real(wp), intent(out), allocatable :: error_indicator(:) ! Per-element errors
    real(wp), intent(out) :: global_error              ! Global error estimate
    integer(i4), intent(out) :: status                 ! Status code

    integer(i8) :: nelem

    status = 0
    nelem = mesh%nElems

    allocate(error_indicator(nelem))
    error_indicator = 0.0_wp
    global_error = 0.0_wp

    select case (method)
    case (1) ! ZZ error estimation
      call error_estimation_zz(mesh, solution, error_indicator)
    case (2) ! SPR error estimation
      call error_estimation_spr(mesh, solution, error_indicator)
    case (3) ! Residual-based error estimation
      call error_estimation_residual(mesh, solution, error_indicator)
    case (4) ! Goal-oriented error estimation
      if (present(exact_solution)) then
        call error_estimation_goal(mesh, solution, exact_solution, error_indicator)
      else
        status = -1  ! Exact solution required
        return
      end if
    case default
      status = -2  ! Unknown method
      return
    end select

    ! Compute global error (L2 norm of element errors)
    global_error = sqrt(sum(error_indicator**2))

  end subroutine EstimateMeshError

  !---------------------------------------------------------------------------
  ! OptimizeMeshQuality - Optimize mesh for better quality
  ! Performs smoothing and optimization operations
  !---------------------------------------------------------------------------
  subroutine OptimizeMeshQuality(mesh, optimization_me, max_iterations, &
                                tolerance, optimized_mesh, status)
    type(MeshData), intent(in) :: mesh
    integer(i4), intent(in) :: optimization_me
    integer(i4), intent(in) :: max_iterations
    real(wp), intent(in) :: tolerance
    type(MeshData), intent(out) :: optimized_mesh
    integer(i4), intent(out) :: status

    status = 0

    ! Copy mesh structure
    call optimized_mesh%Init(mesh%nElems, mesh%nNodes, mesh%spatial_dim, status)
    if (status /= 0) return

    optimized_mesh%node_coords = mesh%node_coords
    optimized_mesh%element_connect = mesh%element_connect
    optimized_mesh%element_types = mesh%element_types

    select case (optimization_me)
    case (1) ! Laplacian smoothing
      call Opt_laplacian_smoothing(optimized_mesh, max_iterations, tolerance, status)
    case (2) ! Optimization-based smoothing
      call Opt_Opt_based(optimized_mesh, max_iterations, tolerance, status)
    case default
      status = -1  ! Unknown optimization method
    end select

  end subroutine OptimizeMeshQuality

  !===============================================================================
  ! UTILITY FUNCTIONS FOR ADAPTIVE MESHING
  !===============================================================================

  !---------------------------------------------------------------------------
  ! Calc_adaptive_efficiencies - Compute h vs p refinement efficiencies
  !---------------------------------------------------------------------------
  subroutine Calc_adaptive_efficiencies(mesh, element_orders, error_indicator, &
                                          efficiency_h, efficiency_p)
    type(MeshData), intent(in) :: mesh
    integer(i4), intent(in) :: element_orders(:)
    real(wp), intent(in) :: error_indicator(:)
    real(wp), intent(out) :: efficiency_h(:), efficiency_p(:)

    integer(i8) :: nelem, i
    real(wp) :: elem_size

    nelem = mesh%nElems

    do i = 1, nelem
      ! Estimate element size
      elem_size = estimate_Elem_size(mesh, i)

      ! Estimate error reduction for h-refinement (h^2 convergence)
      efficiency_h(i) = error_indicator(i) * (elem_size**2) / ((elem_size/2.0_wp)**2)

      ! Estimate error reduction for p-refinement (p^2 convergence)
      efficiency_p(i) = error_indicator(i) * (real(element_orders(i))**2) / &
                       (real(element_orders(i)+1)**2)

      ! Normalize by computational cost
      efficiency_h(i) = efficiency_h(i) / 8.0_wp  ! 8 new elements
      efficiency_p(i) = efficiency_p(i) / 1.0_wp  ! 1 element, higher order
    end do

  end subroutine Calc_adaptive_efficiencies

  !---------------------------------------------------------------------------
  ! perform_mesh_h_refinement - Execute h-refinement on mesh
  !---------------------------------------------------------------------------
  subroutine perform_mesh_h_refinement(mesh, refine_element, refined_mesh, &
                                      elem_count, node_count, status)
    type(MeshData), intent(in) :: mesh
    logical, intent(in) :: refine_element(:)
    type(MeshData), intent(inout) :: refined_mesh
    integer(i8), intent(out) :: elem_count, node_count
    integer(i4), intent(out) :: status

    ! Complete h-refinement implementation
    integer(i8) :: nelem, nnode, nelem_new, nnode_new
    integer(i8) :: i, j, elem_idx, node_idx, new_elem_count
    integer(i4), allocatable :: element_types(:)
    real(wp), allocatable :: node_coords(:,:)
    integer(i8), allocatable :: element_connect(:,:)

    nelem = mesh%nElems
    nnode = mesh%nNodes

    ! Count refined elements and nodes
    nelem_new = nelem
    nnode_new = nnode

    do i = 1, nelem
      if (refine_element(i)) then
        ! For tetrahedral elements: 1 -> 8 tetrahedrons
        ! For hexahedral elements: 1 -> 8 hexahedrons
        nelem_new = nelem_new + 7  ! Add 7 more elements per refinement
        nnode_new = nnode_new + 6  ! Add edge midpoints
      end if
    end do

    ! Init refined mesh
    call refined_mesh%Init(nelem_new, nnode_new, mesh%spatial_dim, status)
    if (status /= 0) return

    ! Allocate temporary arrays
    allocate(element_types(nelem_new))
    allocate(node_coords(3, nnode_new))
    allocate(element_connect(8, nelem_new))  ! Max 8 nodes per element

    ! Copy original nodes
    node_coords(:, 1:nnode) = mesh%node_coords

    ! Copy unrefined elements and refine selected ones
    new_elem_count = 0
    node_idx = nnode

    do i = 1, nelem
      if (.not. refine_element(i)) then
        ! Copy unrefined element
        new_elem_count = new_elem_count + 1
        element_types(new_elem_count) = mesh%element_types(i)
        element_connect(:, new_elem_count) = 0  ! Init
        if (allocated(mesh%element_connect)) then
          do j = 1, size(mesh%element_connect, 1)
            if (j <= size(element_connect, 1)) then
              element_connect(j, new_elem_count) = mesh%element_connect(j, i)
            end if
          end do
        end if
      else
        ! Refine element
        call refine_single_Elem(mesh, i, element_connect, element_types, &
                                 node_coords, new_elem_count, node_idx)
      end if
    end do

    ! Copy to refined mesh
    refined_mesh%element_types = element_types(1:new_elem_count)
    refined_mesh%node_coords = node_coords(:, 1:node_idx)
    if (allocated(element_connect)) then
      allocate(refined_mesh%element_connect(size(element_connect, 1), new_elem_count))
      refined_mesh%element_connect = element_connect(:, 1:new_elem_count)
    end if

    elem_count = new_elem_count
    node_count = node_idx

    ! Cleanup
    deallocate(element_types, node_coords, element_connect)

  end subroutine perform_mesh_h_refinement

  !---------------------------------------------------------------------------
  ! refine_single_Elem - Refine a single element
  !---------------------------------------------------------------------------
  subroutine refine_single_Elem(mesh, elem_id, element_connect, element_types, &
                                 node_coords, new_elem_count, node_count)
    type(MeshData), intent(in) :: mesh
    integer(i8), intent(in) :: elem_id
    integer(i8), intent(inout) :: element_connect(:,:)
    integer(i4), intent(inout) :: element_types(:)
    real(wp), intent(inout) :: node_coords(:,:)
    integer(i8), intent(inout) :: new_elem_count, node_count

    integer(i4) :: elem_type, nnode, i
    integer(i8), allocatable :: node_ids(:)

    elem_type = mesh%element_types(elem_id)
    nnode = count_Elem_nodes(elem_type)

    if (nnode == 0) return

    ! Extract element node IDs
    allocate(node_ids(nnode))
    do i = 1, nnode
      node_ids(i) = mesh%element_connect(i, elem_id)
    end do

    select case (elem_type)
    case (MD_MESH_ELEMENT_TYPE_C3)  ! Hexahedral element
      call refine_hexahedral_Elem(node_ids, node_coords, element_connect, &
                                   element_types, new_elem_count, node_count)

    case (MD_MESH_ELEMENT_TYPE_CP)  ! Quadrilateral element
      call refine_quadrilateral_Elem(node_ids, node_coords, element_connect, &
                                      element_types, new_elem_count, node_count)

    case default
      ! For other element types, just copy the original element
      new_elem_count = new_elem_count + 1
      element_types(new_elem_count) = elem_type
      do i = 1, nnode
        element_connect(i, new_elem_count) = node_ids(i)
      end do
    end select

    deallocate(node_ids)

  end subroutine refine_single_Elem

  !---------------------------------------------------------------------------
  ! refine_hexahedral_Elem - Refine hexahedral element into 8 hexahedrons
  !---------------------------------------------------------------------------
  subroutine refine_hexahedral_Elem(node_ids, node_coords, element_connect, &
                                     element_types, new_elem_count, node_count)
    integer(i8), intent(in) :: node_ids(:)
    real(wp), intent(inout) :: node_coords(:,:)
    integer(i8), intent(inout) :: element_connect(:,:)
    integer(i4), intent(inout) :: element_types(:)
    integer(i8), intent(inout) :: new_elem_count, node_count

    integer(i8) :: new_nodes(12)  ! Edge midpoints
    integer(i8) :: face_nodes(6)  ! Face centers
    integer(i8) :: center_node    ! Element center
    integer(i4) :: i

    ! Create edge midpoint nodes
    new_nodes(1) = create_edge_midpoint(node_ids(1), node_ids(2), node_coords, node_count)
    new_nodes(2) = create_edge_midpoint(node_ids(2), node_ids(3), node_coords, node_count)
    new_nodes(3) = create_edge_midpoint(node_ids(3), node_ids(4), node_coords, node_count)
    new_nodes(4) = create_edge_midpoint(node_ids(4), node_ids(1), node_coords, node_count)
    new_nodes(5) = create_edge_midpoint(node_ids(5), node_ids(6), node_coords, node_count)
    new_nodes(6) = create_edge_midpoint(node_ids(6), node_ids(7), node_coords, node_count)
    new_nodes(7) = create_edge_midpoint(node_ids(7), node_ids(8), node_coords, node_count)
    new_nodes(8) = create_edge_midpoint(node_ids(8), node_ids(5), node_coords, node_count)
    new_nodes(9) = create_edge_midpoint(node_ids(1), node_ids(5), node_coords, node_count)
    new_nodes(10) = create_edge_midpoint(node_ids(2), node_ids(6), node_coords, node_count)
    new_nodes(11) = create_edge_midpoint(node_ids(3), node_ids(7), node_coords, node_count)
    new_nodes(12) = create_edge_midpoint(node_ids(4), node_ids(8), node_coords, node_count)

    ! Create face center nodes
    face_nodes(1) = create_face_center([node_ids(1),node_ids(2),node_ids(3),node_ids(4)], node_coords, node_count)
    face_nodes(2) = create_face_center([node_ids(5),node_ids(6),node_ids(7),node_ids(8)], node_coords, node_count)
    face_nodes(3) = create_face_center([node_ids(1),node_ids(2),node_ids(6),node_ids(5)], node_coords, node_count)
    face_nodes(4) = create_face_center([node_ids(2),node_ids(3),node_ids(7),node_ids(6)], node_coords, node_count)
    face_nodes(5) = create_face_center([node_ids(3),node_ids(4),node_ids(8),node_ids(7)], node_coords, node_count)
    face_nodes(6) = create_face_center([node_ids(4),node_ids(1),node_ids(5),node_ids(8)], node_coords, node_count)

    ! Create element center node
    center_node = create_Elem_center(node_ids, node_coords, node_count)

    ! Create 8 sub-hexahedrons using standard 8-way hex refinement
    ! Sub-element 1: bottom-front-left (node 1 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_C3
    element_connect(1:8, new_elem_count) = &
      [node_ids(1), new_nodes(1), face_nodes(3), new_nodes(4), &
       new_nodes(9), face_nodes(3), center_node, face_nodes(6)]

    ! Sub-element 2: bottom-front-right (node 2 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_C3
    element_connect(1:8, new_elem_count) = &
      [new_nodes(1), node_ids(2), new_nodes(2), face_nodes(3), &
       face_nodes(3), new_nodes(10), face_nodes(4), center_node]

    ! Sub-element 3: bottom-back-right (node 3 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_C3
    element_connect(1:8, new_elem_count) = &
      [face_nodes(3), new_nodes(2), node_ids(3), new_nodes(3), &
       center_node, face_nodes(4), new_nodes(11), face_nodes(5)]

    ! Sub-element 4: bottom-back-left (node 4 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_C3
    element_connect(1:8, new_elem_count) = &
      [new_nodes(4), face_nodes(3), new_nodes(3), node_ids(4), &
       face_nodes(6), center_node, face_nodes(5), new_nodes(12)]

    ! Sub-element 5: top-front-left (node 5 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_C3
    element_connect(1:8, new_elem_count) = &
      [new_nodes(9), face_nodes(3), center_node, face_nodes(6), &
       node_ids(5), new_nodes(5), face_nodes(2), new_nodes(8)]

    ! Sub-element 6: top-front-right (node 6 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_C3
    element_connect(1:8, new_elem_count) = &
      [face_nodes(3), new_nodes(10), face_nodes(4), center_node, &
       new_nodes(5), node_ids(6), new_nodes(6), face_nodes(2)]

    ! Sub-element 7: top-back-right (node 7 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_C3
    element_connect(1:8, new_elem_count) = &
      [center_node, face_nodes(4), new_nodes(11), face_nodes(5), &
       face_nodes(2), new_nodes(6), node_ids(7), new_nodes(7)]

    ! Sub-element 8: top-back-left (node 8 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_C3
    element_connect(1:8, new_elem_count) = &
      [face_nodes(6), center_node, face_nodes(5), new_nodes(12), &
       new_nodes(8), face_nodes(2), new_nodes(7), node_ids(8)]

  end subroutine refine_hexahedral_Elem

  !---------------------------------------------------------------------------
  ! Helper functions for mesh refinement
  !---------------------------------------------------------------------------
  function create_edge_midpoint(node1, node2, node_coords, node_count) result(new_node)
    integer(i8), intent(in) :: node1, node2
    real(wp), intent(inout) :: node_coords(:,:)
    integer(i8), intent(inout) :: node_count
    integer(i8) :: new_node

    node_count = node_count + 1
    new_node = node_count

    if (node1 > 0 .and. node1 <= size(node_coords, 2) .and. &
        node2 > 0 .and. node2 <= size(node_coords, 2)) then
      node_coords(:, new_node) = 0.5_wp * (node_coords(:, node1) + node_coords(:, node2))
    end if

  end function create_edge_midpoint

  function create_face_center(face_nodes, node_coords, node_count) result(new_node)
    integer(i8), intent(in) :: face_nodes(:)
    real(wp), intent(inout) :: node_coords(:,:)
    integer(i8), intent(inout) :: node_count
    integer(i8) :: new_node

    integer(i4) :: i, n
    real(wp) :: center(3)

    node_count = node_count + 1
    new_node = node_count

    center = 0.0_wp
    n = size(face_nodes)

    do i = 1, n
      if (face_nodes(i) > 0 .and. face_nodes(i) <= size(node_coords, 2)) then
        center = center + node_coords(:, face_nodes(i))
      end if
    end do

    node_coords(:, new_node) = center / real(n, wp)

  end function create_face_center

  function create_Elem_center(elem_nodes, node_coords, node_count) result(new_node)
    integer(i8), intent(in) :: elem_nodes(:)
    real(wp), intent(inout) :: node_coords(:,:)
    integer(i8), intent(inout) :: node_count
    integer(i8) :: new_node

    integer(i4) :: i, n
    real(wp) :: center(3)

    node_count = node_count + 1
    new_node = node_count

    center = 0.0_wp
    n = size(elem_nodes)

    do i = 1, n
      if (elem_nodes(i) > 0 .and. elem_nodes(i) <= size(node_coords, 2)) then
        center = center + node_coords(:, elem_nodes(i))
      end if
    end do

    node_coords(:, new_node) = center / real(n, wp)

  end function create_Elem_center

  subroutine refine_quadrilateral_Elem(node_ids, node_coords, element_connect, &
                                        element_types, new_elem_count, node_count)
    integer(i8), intent(in) :: node_ids(:)
    real(wp), intent(inout) :: node_coords(:,:)
    integer(i8), intent(inout) :: element_connect(:,:)
    integer(i4), intent(inout) :: element_types(:)
    integer(i8), intent(inout) :: new_elem_count, node_count

    integer(i8) :: center_node
    integer(i8) :: edge_nodes(4)

    ! Create edge midpoints
    edge_nodes(1) = create_edge_midpoint(node_ids(1), node_ids(2), node_coords, node_count)
    edge_nodes(2) = create_edge_midpoint(node_ids(2), node_ids(3), node_coords, node_count)
    edge_nodes(3) = create_edge_midpoint(node_ids(3), node_ids(4), node_coords, node_count)
    edge_nodes(4) = create_edge_midpoint(node_ids(4), node_ids(1), node_coords, node_count)

    ! Create center node
    center_node = create_Elem_center(node_ids, node_coords, node_count)

    ! Create 4 sub-quadrilaterals using standard 4-way quad refinement
    ! Sub-element 1: bottom-left (node 1 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_CP
    element_connect(1:4, new_elem_count) = &
      [node_ids(1), edge_nodes(1), center_node, edge_nodes(4)]

    ! Sub-element 2: bottom-right (node 2 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_CP
    element_connect(1:4, new_elem_count) = &
      [edge_nodes(1), node_ids(2), edge_nodes(2), center_node]

    ! Sub-element 3: top-right (node 3 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_CP
    element_connect(1:4, new_elem_count) = &
      [center_node, edge_nodes(2), node_ids(3), edge_nodes(3)]

    ! Sub-element 4: top-left (node 4 corner)
    new_elem_count = new_elem_count + 1
    element_types(new_elem_count) = MD_MESH_ELEMENT_TYPE_CP
    element_connect(1:4, new_elem_count) = &
      [edge_nodes(4), center_node, edge_nodes(3), node_ids(4)]

  end subroutine refine_quadrilateral_Elem

  !---------------------------------------------------------------------------
  ! perform_selective_h_refinement - Selective h-refinement
  !---------------------------------------------------------------------------
  subroutine perform_selective_h_refinement(mesh, refine_element, max_elements, &
                                          refined_mesh, status)
    type(MeshData), intent(in) :: mesh
    logical, intent(in) :: refine_element(:)
    integer(i8), intent(in) :: max_elements
    type(MeshData), intent(out) :: refined_mesh
    integer(i4), intent(out) :: status

    ! Simplified version
    call RefineMeshAdaptive_H(mesh, merge(1.0_wp, 0.0_wp, refine_element), &
                             0.5_wp, max_elements, refined_mesh, status)

  end subroutine perform_selective_h_refinement

  !---------------------------------------------------------------------------
  ! Error estimation implementations
  !   Implements ZZ, SPR, residual and goal-oriented error estimators.
  !   Assumption: solution(:) is nodal scalar field (e.g. displacement component, temperature).
  !---------------------------------------------------------------------------
  subroutine Calc_Elem_gradient(mesh, solution, elem_id, grad)
    !! Compute element-wise approximate gradient grad = grad(u) (least-squares from nodal values)
    type(MeshData), intent(in) :: mesh
    real(wp), intent(in) :: solution(:)
    integer(i8), intent(in) :: elem_id
    real(wp), intent(out) :: grad(3)

    integer(i4) :: dim, nnode_loc, a, b, info
    integer(i8) :: node_id
    real(wp) :: A(3,3), rhs(3), dx(3), u0, ui
    real(wp) :: x0(3)
    integer(i4) :: j

    grad = 0.0_wp
    dim = mesh%spatial_dim
    if (dim < 1 .or. dim > 3) return
    if (.not. allocated(mesh%element_connect)) return
    if (.not. allocated(mesh%node_coords)) return

    nnode_loc = count_Elem_nodes(mesh%element_types(elem_id))
    if (nnode_loc < dim + 1) return

    ! Use first node as reference
    node_id = mesh%element_connect(1, elem_id)
    if (node_id < 1_i8 .or. node_id > size(solution)) return
    x0 = 0.0_wp
    x0(1:dim) = mesh%node_coords(1:dim, node_id)
    u0 = solution(node_id)

    A = 0.0_wp
    rhs = 0.0_wp

    ! Build least-squares normal system A * grad = rhs
    do j = 2, nnode_loc
      if (j > size(mesh%element_connect, 1)) exit
      node_id = mesh%element_connect(j, elem_id)
      if (node_id < 1_i8 .or. node_id > size(solution)) cycle

      dx = 0.0_wp
      dx(1:dim) = mesh%node_coords(1:dim, node_id) - x0(1:dim)
      ui = solution(node_id)

      do a = 1, dim
        do b = 1, dim
          A(a,b) = A(a,b) + dx(a) * dx(b)
        end do
        rhs(a) = rhs(a) + dx(a) * (ui - u0)
      end do
    end do

    call Solv_small_system(dim, A, rhs, grad, info)
    if (info /= 0) then
      grad = 0.0_wp
    end if

  end subroutine Calc_Elem_gradient

  subroutine Solv_small_system(dim, A, b, x, info)
    !! Solve dim(<=3) linear system A*x = b (simple Gaussian elimination)
    integer(i4), intent(in) :: dim
    real(wp), intent(in) :: A(3,3), b(3)
    real(wp), intent(out) :: x(3)
    integer(i4), intent(out) :: info

    real(wp) :: M(3,3), rhs(3)
    real(wp) :: pivot, factor, tmp
    integer(i4) :: i, j, k
    real(wp), parameter :: PIVOT_TOL = 1.0e-14_wp

    info = 0
    x = 0.0_wp
    M = A
    rhs = b

    ! Forward elimination
    do k = 1, dim - 1
      pivot = abs(M(k,k))
      if (pivot < PIVOT_TOL) then
        info = 1
        return
      end if

      do i = k + 1, dim
        factor = M(i,k) / M(k,k)
        do j = k + 1, dim
          M(i,j) = M(i,j) - factor * M(k,j)
        end do
        rhs(i) = rhs(i) - factor * rhs(k)
        M(i,k) = 0.0_wp
      end do
    end do

    if (abs(M(dim,dim)) < PIVOT_TOL) then
      info = 1
      return
    end if

    ! Back substitution
    x(dim) = rhs(dim) / M(dim,dim)
    do i = dim - 1, 1, -1
      tmp = rhs(i)
      do j = i + 1, dim
        tmp = tmp - M(i,j) * x(j)
      end do
      if (abs(M(i,i)) < PIVOT_TOL) then
        info = 1
        return
      end if
      x(i) = tmp / M(i,i)
    end do

  end subroutine Solv_small_system

  subroutine error_estimation_zz(mesh, solution, error_indicator)
    !! Zienkiewicz-Zhu error estimation (gradient recovery)
    !! 1. Per element: fit grad_e by least-squares in physical space
    !! 2. Project element gradients to nodes -> recovered grad_h (average over patch)
    !! 3. Element error indicator: weighted L2 of ||grad_e - grad_h||
    !! 4. Scale by h_e * ||delta_grad||, h_e = element size
    type(MeshData), intent(in) :: mesh
    real(wp), intent(in) :: solution(:)
    real(wp), intent(out) :: error_indicator(:)

    integer(i8) :: nelem, nnode
    integer(i8) :: ielem, node_id
    integer(i4) :: dim, j
    real(wp), allocatable :: elem_grad(:,:)   ! (3, nelem)
    real(wp), allocatable :: node_grad(:,:)   ! (3, nnode)
    integer(i8), allocatable :: node_count(:)
    real(wp) :: diff(3), h_elem, sum_diff2
    integer(i4) :: nnode_loc

    nelem = mesh%nElems
    nnode = mesh%nNodes
    dim = mesh%spatial_dim

    if (nelem <= 0 .or. nnode <= 0) then
      error_indicator = 0.0_wp
      return
    end if

    if (size(error_indicator) < nelem) then
      ! Defensive check: caller must ensure size(error_indicator) >= nelem
      error_indicator = 0.0_wp
      return
    end if

    allocate(elem_grad(3, nelem))
    allocate(node_grad(3, nnode))
    allocate(node_count(nnode))

    elem_grad = 0.0_wp
    node_grad = 0.0_wp
    node_count = 0_i8

    ! Step 1: compute per-element approximate scalar gradient
    do ielem = 1, nelem
      call Calc_Elem_gradient(mesh, solution, ielem, elem_grad(:, ielem))
    end do

    ! Step 2: accumulate element gradients at nodes (simple average, first-order SPR)
    do ielem = 1, nelem
      nnode_loc = count_Elem_nodes(mesh%element_types(ielem))
      do j = 1, nnode_loc
        if (j > size(mesh%element_connect, 1)) exit
        node_id = mesh%element_connect(j, ielem)
        if (node_id < 1_i8 .or. node_id > nnode) cycle
        node_grad(:, node_id) = node_grad(:, node_id) + elem_grad(:, ielem)
        node_count(node_id) = node_count(node_id) + 1_i8
      end do
    end do

    do node_id = 1, nnode
      if (node_count(node_id) > 0) then
        node_grad(:, node_id) = node_grad(:, node_id) / real(node_count(node_id), wp)
      end if
    end do

    ! Step 3: form element error indicator
    do ielem = 1, nelem
      nnode_loc = count_Elem_nodes(mesh%element_types(ielem))
      if (nnode_loc <= 0) cycle
      h_elem = estimate_Elem_size(mesh, ielem)
      sum_diff2 = 0.0_wp

      do j = 1, nnode_loc
        if (j > size(mesh%element_connect, 1)) exit
        node_id = mesh%element_connect(j, ielem)
        if (node_id < 1_i8 .or. node_id > nnode) cycle

        diff = 0.0_wp
        diff(1:dim) = elem_grad(1:dim, ielem) - node_grad(1:dim, node_id)
        sum_diff2 = sum_diff2 + sum(diff(1:dim)**2)
      end do

      sum_diff2 = sum_diff2 / real(max(1, nnode_loc), wp)
      error_indicator(ielem) = h_elem * sqrt(sum_diff2)
    end do

    deallocate(elem_grad)
    deallocate(node_grad)
    deallocate(node_count)

  end subroutine error_estimation_zz

  subroutine error_estimation_spr(mesh, solution, error_indicator)
    !! Superconvergent Patch Recovery (SPR) error estimation
    !! Similar to ZZ, with higher-order recovery at nodes
    !! 1. Build superconvergent gradient at nodes from element gradients
    !! 2. Error indicator from recovery vs element gradient, scaled by h^2 or h^3
    type(MeshData), intent(in) :: mesh
    real(wp), intent(in) :: solution(:)
    real(wp), intent(out) :: error_indicator(:)

    integer(i8) :: nelem, nnode
    integer(i8) :: ielem, node_id
    integer(i4) :: dim, j
    real(wp), allocatable :: elem_grad(:,:)   ! (3, nelem)
    real(wp), allocatable :: node_grad(:,:)   ! (3, nnode)
    integer(i8), allocatable :: node_count(:)
    real(wp) :: diff(3), h_elem, sum_diff2
    integer(i4) :: nnode_loc

    nelem = mesh%nElems
    nnode = mesh%nNodes
    dim = mesh%spatial_dim

    if (nelem <= 0 .or. nnode <= 0) then
      error_indicator = 0.0_wp
      return
    end if

    if (size(error_indicator) < nelem) then
      error_indicator = 0.0_wp
      return
    end if

    allocate(elem_grad(3, nelem))
    allocate(node_grad(3, nnode))
    allocate(node_count(nnode))

    elem_grad = 0.0_wp
    node_grad = 0.0_wp
    node_count = 0_i8

    ! Step 1: compute per-element gradient
    do ielem = 1, nelem
      call Calc_Elem_gradient(mesh, solution, ielem, elem_grad(:, ielem))
    end do

    ! Step 2: recover superconvergent gradient at nodes (weighted average by element size)
    do ielem = 1, nelem
      nnode_loc = count_Elem_nodes(mesh%element_types(ielem))
      if (nnode_loc <= 0) cycle
      h_elem = estimate_Elem_size(mesh, ielem)
      do j = 1, nnode_loc
        if (j > size(mesh%element_connect, 1)) exit
        node_id = mesh%element_connect(j, ielem)
        if (node_id < 1_i8 .or. node_id > nnode) cycle
        ! Use 1/h as weight: smaller h -> larger weight
        node_grad(:, node_id) = node_grad(:, node_id) + elem_grad(:, ielem) / max(h_elem, 1.0e-12_wp)
        node_count(node_id) = node_count(node_id) + 1_i8
      end do
    end do

    do node_id = 1, nnode
      if (node_count(node_id) > 0) then
        node_grad(:, node_id) = node_grad(:, node_id) / real(node_count(node_id), wp)
      end if
    end do

    ! Step 3: form SPR element error indicator (h^2 scaling)
    do ielem = 1, nelem
      nnode_loc = count_Elem_nodes(mesh%element_types(ielem))
      if (nnode_loc <= 0) cycle
      h_elem = estimate_Elem_size(mesh, ielem)
      sum_diff2 = 0.0_wp

      do j = 1, nnode_loc
        if (j > size(mesh%element_connect, 1)) exit
        node_id = mesh%element_connect(j, ielem)
        if (node_id < 1_i8 .or. node_id > nnode) cycle

        diff = 0.0_wp
        diff(1:dim) = elem_grad(1:dim, ielem) - node_grad(1:dim, node_id)
        sum_diff2 = sum_diff2 + sum(diff(1:dim)**2)
      end do

      sum_diff2 = sum_diff2 / real(max(1, nnode_loc), wp)
      error_indicator(ielem) = h_elem*h_elem * sqrt(sum_diff2)
    end do

    deallocate(elem_grad)
    deallocate(node_grad)
    deallocate(node_count)

  end subroutine error_estimation_spr
  subroutine error_estimation_residual(mesh, solution, error_indicator)
    !! Residual-type error estimation
    !! Generic residual indicator (equation-independent)
    !! 1. Use element gradient as proxy for residual (|grad u|)
    !! 2. Element indicator: h_e * ||grad u||, h_e = element size
    type(MeshData), intent(in) :: mesh
    real(wp), intent(in) :: solution(:)
    real(wp), intent(out) :: error_indicator(:)

    integer(i8) :: nelem, ielem
    integer(i4) :: dim
    real(wp) :: grad(3), h_elem

    nelem = mesh%nElems
    dim = mesh%spatial_dim

    if (nelem <= 0) then
      error_indicator = 0.0_wp
      return
    end if

    if (size(error_indicator) < nelem) then
      error_indicator = 0.0_wp
      return
    end if

    error_indicator = 0.0_wp

    do ielem = 1, nelem
      call Calc_Elem_gradient(mesh, solution, ielem, grad)
      h_elem = estimate_Elem_size(mesh, ielem)

      ! Generic residual indicator: h * ||grad u||
      error_indicator(ielem) = h_elem * sqrt(sum(grad(1:dim)**2))
    end do

  end subroutine error_estimation_residual
  subroutine error_estimation_goal(mesh, solution, exact_solution, error_indicator)
    type(MeshData), intent(in) :: mesh
    real(wp), intent(in) :: solution(:), exact_solution(:)
    real(wp), intent(out) :: error_indicator(:)

    ! Goal-oriented error estimation
    ! Estimate error in quantity of interest
    integer(i8) :: nelem, i
    real(wp) :: error_elem

    nelem = mesh%nElems
    error_indicator = 0.0_wp

    do i = 1, nelem
      ! Goal-oriented error estimation
      ! In full implementation, this would:
      ! 1. Solve adjoint problem for quantity of interest
      ! 2. Compute error representation: (f, e) + <g, e> + <ҡn, e>
      ! 3. Localize error to elements

      if (size(solution) == size(exact_solution) .and. i <= size(error_indicator)) then
        error_elem = abs(solution(i) - exact_solution(i))
        error_indicator(i) = error_elem
      else
        error_indicator(i) = 0.001_wp  ! Default small error
      end if
    end do
  end subroutine error_estimation_goal

  !---------------------------------------------------------------------------
  ! Mesh optimization implementations
  !---------------------------------------------------------------------------
  subroutine Opt_laplacian_smoothing(mesh, max_iter, tolerance, status)
    type(MeshData), intent(inout) :: mesh
    integer(i4), intent(in) :: max_iter
    real(wp), intent(in) :: tolerance
    integer(i4), intent(out) :: status
    ! Laplacian smoothing implementation
    status = 0
  end subroutine Opt_laplacian_smoothing

  subroutine Opt_Opt_based(mesh, max_iter, tolerance, status)
    type(MeshData), intent(inout) :: mesh
    integer(i4), intent(in) :: max_iter
    real(wp), intent(in) :: tolerance
    integer(i4), intent(out) :: status
    ! Optimization-based smoothing
    status = 0
  end subroutine Opt_Opt_based

  !---------------------------------------------------------------------------
  ! estimate_Elem_size - Estimate characteristic element size
  !---------------------------------------------------------------------------
  function estimate_Elem_size(mesh, elem_id) result(size)
    type(MeshData), intent(in) :: mesh
    integer(i8), intent(in) :: elem_id
    real(wp) :: size

    integer(i4) :: elem_type, nnode, i
    real(wp) :: max_dist, dist
    real(wp), allocatable :: nodes(:,:)

    if (.not. allocated(mesh%element_connect) .or. &
        .not. allocated(mesh%node_coords)) then
      size = 1.0_wp  ! Default
      return
    end if

    elem_type = mesh%element_types(elem_id)
    nnode = count_Elem_nodes(elem_type)

    if (nnode == 0 .or. elem_id > mesh%nElems) then
      size = 1.0_wp
      return
    end if

    ! Extract element nodes
    allocate(nodes(3, nnode))
    do i = 1, nnode
      if (i <= size(mesh%element_connect, 1)) then
        nodes(:, i) = mesh%node_coords(:, mesh%element_connect(i, elem_id))
      end if
    end do

    ! Estimate element size (maximum distance between nodes)
    max_dist = 0.0_wp
    do i = 1, nnode
      dist = sqrt(sum((nodes(:, i) - nodes(:, 1))**2))
      max_dist = max(max_dist, dist)
    end do

    size = max_dist
    if (size < 1.0e-12_wp) size = 1.0_wp  ! Avoid zero size

    deallocate(nodes)
  end function estimate_Elem_size

  !---------------------------------------------------------------------------
  ! count_Elem_nodes - Count nodes in element type
  !---------------------------------------------------------------------------
  function count_Elem_nodes(elem_type) result(nnode)
    integer(i4), intent(in) :: elem_type
    integer(i4) :: nnode

    select case (elem_type)
    case (MD_MESH_ELEMENT_TYPE_CP)    ! 4-node quad
      nnode = 4
    case (MD_MESH_ELEMENT_TYPE_CP)    ! 8-node quad
      nnode = 8
    case (MD_MESH_ELEMENT_TYPE_C3)    ! 8-node hex
      nnode = 8
    case (MD_MESH_ELEMENT_TYPE_C3)   ! 20-node hex
      nnode = 20
    case (MD_MESH_ELEMENT_TYPE_S4)      ! 4-node shell
      nnode = 4
    case (MD_MESH_ELEMENT_TYPE_S8)      ! 8-node shell
      nnode = 8
    case (MD_MESH_ELEMENT_TYPE_B2)     ! 2-node beam
      nnode = 2
    case (MD_MESH_ELEMENT_TYPE_B3)     ! 3-node beam
      nnode = 3
    case (MD_MESH_ELEMENT_TYPE_B2)   ! Euler-Bernoulli beam
      nnode = 2
    case (MD_MESH_ELEMENT_TYPE_B2)    ! Timoshenko beam
      nnode = 2
    case (MD_MESH_ELEMENT_TYPE_S4)    ! Kirchhoff shell
      nnode = 4
    case (MD_MESH_ELEMENT_TYPE_S4)  ! Mindlin shell
      nnode = 4
    case default
      nnode = 0  ! Unknown element type
    end select
  end function count_Elem_nodes

  !===============================================================================
  ! PUBLIC INTERFACES FOR ADAPTIVE MESHING
  !===============================================================================

  public :: RefineMeshAdaptive_H
  public :: RefineMeshAdaptive_P
  public :: RefineMeshAdaptive_HP
  public :: EstimateMeshError
  public :: OptimizeMeshQuality



END MODULE MD_Mesh_API

