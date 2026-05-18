!===============================================================================
! MODULE: MD_Mesh_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Mesh L3→L5 bridge
! BRIEF:  Runtime mesh ID mapping (node/elem/mat/sect) and structure init.
!===============================================================================
MODULE MD_Mesh_Brg
  ! Runtime Mesh Bridge: ID mapping Model <-> RT (see file header comments).
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, only: wp, i4, i8
  USE MD_Mat_Lib, only: MatProperties
  USE MD_Mesh_API, only: MD_Mesh_GetNumElements, MD_Mesh_GetNumNodes, &
                         MD_Mesh_GetElementConnectivity, MD_Mesh_GetNodeCoords
  USE MD_Mesh_API, only: MD_Mesh_GetNodeCoords_Idx, MD_Mesh_GetNodeCoords_Arg, &
                                MD_Mesh_GetElemConnect_Idx, MD_Mesh_GetElemConnect_Arg
  USE RT_Mat_Core, only: RT_Mat_Init, RT_Mat_Clean
  ! RT_Elem_Core eliminated (thin wrapper) - use RT_ElemSect directly
  USE RT_Elem_Sect, only: RT_Elem_Sect_Populate => RT_Elem_Sect_Populate
  USE RT_Mesh_Sys, only: RT_Mesh_RegVars
  USE RT_Sect, only: UF_RT_Section_PopulateLegacyDB, UF_RT_Section_GetDescriptor
  USE MD_Sect_Mgr, only: MatDescription
  USE UF_Material_Base, only: UF_MaterialModel
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mesh_Brg
  PUBLIC :: RT_Mesh_IDMap
  PUBLIC :: MD_Mesh_BrgInit
  PUBLIC :: MD_Mesh_BrgClean
  PUBLIC :: MD_Mesh_BrgMapElemId
  PUBLIC :: MD_Mesh_BrgMapMatId
  PUBLIC :: MD_Mesh_BrgMapSectId
  PUBLIC :: MD_Mesh_BrgMapNodeId
  PUBLIC :: MD_Mesh_BrgGetElemCnt
  PUBLIC :: MD_Mesh_BrgGetNodeCnt
  PUBLIC :: MD_Mesh_BrgInitMats
  PUBLIC :: MD_Mesh_BrgInitElems
  PUBLIC :: MD_Mesh_BrgInitSects
  PUBLIC :: MD_Mesh_Brg_GetNodeCoords_Idx
  PUBLIC :: MD_Mesh_Brg_GetElemConnect_Idx

  !---------------------------------------------------------------------------
  ! TYPE: RT_Mesh_IDMap
  ! KIND: State
  ! DESC: Single model-to-runtime ID mapping entry.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Mesh_IDMap
    INTEGER(i4) :: modelId = 0_i4
    INTEGER(i4) :: runtimeId = 0_i4
    LOGICAL :: valid = .FALSE.
    CHARACTER(len=32) :: name = ""
  CONTAINS
    PROCEDURE :: Init => RT_Mesh_IDMapInit
    PROCEDURE :: Set => RT_Mesh_IDMapSet
    PROCEDURE :: Valid => RT_Mesh_IDMapValid
  END TYPE RT_Mesh_IDMap

  !---------------------------------------------------------------------------
  ! TYPE: MD_Mesh_Brg
  ! KIND: Ctx
  ! DESC: Container for all mesh ID-map arrays and element/node counts.
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Mesh_Brg_Counts
    INTEGER(i4) :: nElems = 0_i4
    INTEGER(i4) :: nNodes = 0_i4
    INTEGER(i4) :: nMats = 0_i4
    INTEGER(i4) :: nSects = 0_i4
  END TYPE MD_Mesh_Brg_Counts

  TYPE, PUBLIC :: MD_Mesh_Brg_IDMaps
    INTEGER(i4), ALLOCATABLE :: elemIdMap(:)
    INTEGER(i4), ALLOCATABLE :: matIdMap(:)
    INTEGER(i4), ALLOCATABLE :: sectIdMap(:)
    INTEGER(i4), ALLOCATABLE :: nodeIdMap(:)
  END TYPE MD_Mesh_Brg_IDMaps

  TYPE, PUBLIC :: MD_Mesh_Brg_Mappings
    TYPE(RT_Mesh_IDMap), ALLOCATABLE :: elemMappings(:)
    TYPE(RT_Mesh_IDMap), ALLOCATABLE :: matMapping(:)
    TYPE(RT_Mesh_IDMap), ALLOCATABLE :: sectMappings(:)
    TYPE(RT_Mesh_IDMap), ALLOCATABLE :: nodeMappings(:)
  END TYPE MD_Mesh_Brg_Mappings

  TYPE, PUBLIC :: MD_Mesh_Brg
    TYPE(MD_Mesh_Brg_Counts) :: counts
    LOGICAL :: inited = .FALSE.
    TYPE(MD_Mesh_Brg_IDMaps) :: idmaps
    TYPE(MD_Mesh_Brg_Mappings) :: mappings
  CONTAINS
    PROCEDURE :: Clean => MD_Mesh_BrgCleanType
    PROCEDURE :: GetElemCnt => MD_Mesh_BrgGetElemCntType
    PROCEDURE :: GetNodeCnt => MD_Mesh_BrgGetNodeCntType
    PROCEDURE :: Init => MD_Mesh_BrgInitType
    PROCEDURE :: MapElem => MD_Mesh_BrgMapElemType
    PROCEDURE :: MapMat => MD_Mesh_BrgMapMatType
    PROCEDURE :: MapNode => MD_Mesh_BrgMapNodeType
    PROCEDURE :: MapSect => MD_Mesh_BrgMapSectType
  END TYPE MD_Mesh_Brg

  TYPE(MD_Mesh_Brg), SAVE :: g_meshBrg

CONTAINS

  SUBROUTINE MD_Mesh_BrgClean()
    CALL g_meshBrg%Clean()
  END SUBROUTINE MD_Mesh_BrgClean

  SUBROUTINE MD_Mesh_BrgCleanType(this)
    class(MD_Mesh_Brg), intent(inout) :: this

    if (allocated(this%idmaps%elemIdMap)) deallocate(this%idmaps%elemIdMap)
    if (allocated(this%idmaps%matIdMap)) deallocate(this%idmaps%matIdMap)
    if (allocated(this%idmaps%sectIdMap)) deallocate(this%idmaps%sectIdMap)
    if (allocated(this%idmaps%nodeIdMap)) deallocate(this%idmaps%nodeIdMap)

    if (allocated(this%mappings%elemMappings)) deallocate(this%mappings%elemMappings)
    if (allocated(this%mappings%matMapping)) deallocate(this%mappings%matMapping)
    if (allocated(this%mappings%sectMappings)) deallocate(this%mappings%sectMappings)
    if (allocated(this%mappings%nodeMappings)) deallocate(this%mappings%nodeMappings)

    this%counts%nElems = 0_i4
    this%counts%nNodes = 0_i4
    this%counts%nMats = 0_i4
    this%counts%nSects = 0_i4

    this%inited = .false.
  end subroutine MD_Mesh_BrgCleanType

  function MD_Mesh_BrgGetElemCnt() result(count)
    integer(i4) :: count
    count = g_meshBrg%GetElemCnt()
  end function MD_Mesh_BrgGetElemCnt

  function MD_Mesh_BrgGetElemCntType(this) result(count)
    class(MD_Mesh_Brg), intent(in) :: this
    integer(i4) :: count
    count = this%counts%nElems
  end function MD_Mesh_BrgGetElemCntType

  function MD_Mesh_BrgGetNodeCnt() result(count)
    integer(i4) :: count
    count = g_meshBrg%GetNodeCnt()
  end function MD_Mesh_BrgGetNodeCnt

  function MD_Mesh_BrgGetNodeCntType(this) result(count)
    class(MD_Mesh_Brg), intent(in) :: this
    integer(i4) :: count
    count = this%counts%nNodes
  end function MD_Mesh_BrgGetNodeCntType

  subroutine MD_Mesh_BrgInit(nElems, nNodes, nMats, nSects, status)
    integer(i4), intent(in), optional :: nElems
    integer(i4), intent(in), optional :: nNodes
    integer(i4), intent(in), optional :: nMats
    integer(i4), intent(in), optional :: nSects
    type(ErrorStatusType), intent(out), optional :: status

    integer(i4) :: n_elem, n_node, n_mat, n_sect
    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (g_meshBrg%inited) then
      if (present(status)) status = local_status
      return
    end if

    ! Use default values if not provided
    n_elem = 0_i4
    n_node = 0_i4
    n_mat = 0_i4
    n_sect = 0_i4
    if (present(nElems)) n_elem = nElems
    if (present(nNodes)) n_node = nNodes
    if (present(nMats)) n_mat = nMats
    if (present(nSects)) n_sect = nSects

    call g_meshBrg%Init(n_elem, n_node, n_mat, n_sect, local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      if (present(status)) status = local_status
      return
    end if

    call RT_Elem_InitReg()

    local_status%status_code = IF_STATUS_OK
    if (present(status)) status = local_status
  end subroutine MD_Mesh_BrgInit

  subroutine MD_Mesh_BrgInitElems(nElems, status)
    integer(i4), intent(in) :: nElems
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. g_meshBrg%inited) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh bridge not initialized"
      return
    end if

    do i = 1, nElems
      call g_meshBrg%MapElem(i, i)
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MD_Mesh_BrgInitElems

  subroutine MD_Mesh_BrgInitMats(nMats, status)
    integer(i4), intent(in) :: nMats
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. g_meshBrg%inited) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh bridge not initialized"
      return
    end if

    do i = 1, nMats
      call g_meshBrg%MapMat(i, i)
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MD_Mesh_BrgInitMats

  subroutine MD_Mesh_BrgInitSects(nSects, status)
    integer(i4), intent(in) :: nSects
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. g_meshBrg%inited) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh bridge not initialized"
      return
    end if

    do i = 1, nSects
      call g_meshBrg%MapSect(i, i)
    end do

    status%status_code = IF_STATUS_OK
  end subroutine MD_Mesh_BrgInitSects

  subroutine MD_Mesh_BrgInitType(this, nElems, nNodes, nMats, nSects, status)
    class(MD_Mesh_Brg), intent(inout) :: this
    integer(i4), intent(in) :: nElems
    integer(i4), intent(in) :: nNodes
    integer(i4), intent(in) :: nMats
    integer(i4), intent(in) :: nSects
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (this%inited) then
      status%status_code = IF_STATUS_OK
      return
    end if

    this%counts%nElems = nElems
    this%counts%nNodes = nNodes
    this%counts%nMats = nMats
    this%counts%nSects = nSects

    allocate(this%idmaps%elemIdMap(nElems))
    allocate(this%idmaps%matIdMap(nMats))
    allocate(this%idmaps%sectIdMap(nSects))
    allocate(this%idmaps%nodeIdMap(nNodes))

    allocate(this%mappings%elemMappings(nElems))
    allocate(this%mappings%matMapping(nMats))
    allocate(this%mappings%sectMappings(nSects))
    allocate(this%mappings%nodeMappings(nNodes))

    this%idmaps%elemIdMap = 0_i4
    this%idmaps%matIdMap = 0_i4
    this%idmaps%sectIdMap = 0_i4
    this%idmaps%nodeIdMap = 0_i4

    this%inited = .true.
    status%status_code = IF_STATUS_OK
  end subroutine MD_Mesh_BrgInitType

  subroutine MD_Mesh_BrgMapElemId(modelId, runtimeId, status)
    integer(i4), intent(in) :: modelId
    integer(i4), intent(in) :: runtimeId
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. g_meshBrg%inited) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh bridge not initialized"
      return
    end if

    call g_meshBrg%MapElem(modelId, runtimeId)

    status%status_code = IF_STATUS_OK
  end subroutine MD_Mesh_BrgMapElemId

  subroutine MD_Mesh_BrgMapElemType(this, modelId, runtimeId)
    class(MD_Mesh_Brg), intent(inout) :: this
    integer(i4), intent(in) :: modelId
    integer(i4), intent(in) :: runtimeId

    if (modelId >= 1_i4 .and. modelId <= this%counts%nElems) then
      this%idmaps%elemIdMap(modelId) = runtimeId
      call this%mappings%elemMappings(modelId)%Init(modelId, "Element")
      call this%mappings%elemMappings(modelId)%Set(runtimeId)
    end if
  end subroutine MD_Mesh_BrgMapElemType

  subroutine MD_Mesh_BrgMapMatId(modelId, runtimeId, status)
    integer(i4), intent(in) :: modelId
    integer(i4), intent(in) :: runtimeId
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. g_meshBrg%inited) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh bridge not initialized"
      return
    end if

    call g_meshBrg%MapMat(modelId, runtimeId)

    status%status_code = IF_STATUS_OK
  end subroutine MD_Mesh_BrgMapMatId

  subroutine MD_Mesh_BrgMapMatType(this, modelId, runtimeId)
    class(MD_Mesh_Brg), intent(inout) :: this
    integer(i4), intent(in) :: modelId
    integer(i4), intent(in) :: runtimeId

    if (modelId >= 1_i4 .and. modelId <= this%counts%nMats) then
      this%idmaps%matIdMap(modelId) = runtimeId
      call this%mappings%matMapping(modelId)%Init(modelId, "Mat")
      call this%mappings%matMapping(modelId)%Set(runtimeId)
    end if
  end subroutine MD_Mesh_BrgMapMatType

  subroutine MD_Mesh_BrgMapNodeId(modelId, runtimeId, status)
    integer(i4), intent(in) :: modelId
    integer(i4), intent(in) :: runtimeId
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. g_meshBrg%inited) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh bridge not initialized"
      return
    end if

    call g_meshBrg%MapNode(modelId, runtimeId)

    status%status_code = IF_STATUS_OK
  end subroutine MD_Mesh_BrgMapNodeId

  subroutine MD_Mesh_BrgMapNodeType(this, modelId, runtimeId)
    class(MD_Mesh_Brg), intent(inout) :: this
    integer(i4), intent(in) :: modelId
    integer(i4), intent(in) :: runtimeId

    if (modelId >= 1_i4 .and. modelId <= this%counts%nNodes) then
      this%idmaps%nodeIdMap(modelId) = runtimeId
      call this%mappings%nodeMappings(modelId)%Init(modelId, "Node")
      call this%mappings%nodeMappings(modelId)%Set(runtimeId)
    end if
  end subroutine MD_Mesh_BrgMapNodeType

  subroutine MD_Mesh_BrgMapSectId(modelId, runtimeId, status)
    integer(i4), intent(in) :: modelId
    integer(i4), intent(in) :: runtimeId
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. g_meshBrg%inited) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh bridge not initialized"
      return
    end if

    call g_meshBrg%MapSect(modelId, runtimeId)

    status%status_code = IF_STATUS_OK
  end subroutine MD_Mesh_BrgMapSectId

  subroutine MD_Mesh_BrgMapSectType(this, modelId, runtimeId)
    class(MD_Mesh_Brg), intent(inout) :: this
    integer(i4), intent(in) :: modelId
    integer(i4), intent(in) :: runtimeId

    if (modelId >= 1_i4 .and. modelId <= this%counts%nSects) then
      this%idmaps%sectIdMap(modelId) = runtimeId
      call this%mappings%sectMappings(modelId)%Init(modelId, "Section")
      call this%mappings%sectMappings(modelId)%Set(runtimeId)
    end if
  end subroutine MD_Mesh_BrgMapSectType

  subroutine RT_Mesh_IDMapInit(this, modelId, name)
    class(RT_Mesh_IDMap), intent(inout) :: this
    integer(i4), intent(in) :: modelId
    character(len=*), intent(in) :: name

    this%modelId = modelId
    this%runtimeId = 0_i4
    this%valid = .false.
    this%name = trim(name)
  end subroutine RT_Mesh_IDMapInit

  subroutine RT_Mesh_IDMapSet(this, runtimeId)
    class(RT_Mesh_IDMap), intent(inout) :: this
    integer(i4), intent(in) :: runtimeId

    this%runtimeId = runtimeId
    this%valid = .true.
  end subroutine RT_Mesh_IDMapSet

  function RT_Mesh_IDMapValid(this) result(valid)
    class(RT_Mesh_IDMap), intent(in) :: this
    logical :: valid

    valid = this%valid
  end function RT_Mesh_IDMapValid

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Brg_GetNodeCoords_Idx
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Index-based node-coords bridge → MD_MeshDomain_Algo.
  !---------------------------------------------------------------------------
  subroutine MD_Mesh_Brg_GetNodeCoords_Idx(node_idx, arg, status)
    integer(i4), intent(in) :: node_idx
    type(MD_Mesh_GetNodeCoords_Arg), intent(inout) :: arg
    type(ErrorStatusType), intent(out) :: status
    call MD_Mesh_GetNodeCoords_Idx(node_idx, arg, status)
  end subroutine MD_Mesh_Brg_GetNodeCoords_Idx

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Brg_GetElemConnect_Idx
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Index-based elem-connectivity bridge → MD_MeshDomain_Algo.
  !---------------------------------------------------------------------------
  subroutine MD_Mesh_Brg_GetElemConnect_Idx(elem_idx, arg, status)
    integer(i4), intent(in) :: elem_idx
    type(MD_Mesh_GetElemConnect_Arg), intent(inout) :: arg
    type(ErrorStatusType), intent(out) :: status
    call MD_Mesh_GetElemConnect_Idx(elem_idx, arg, status)
  end subroutine MD_Mesh_Brg_GetElemConnect_Idx
end module MD_Mesh_Brg
