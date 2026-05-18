!===============================================================================
! MODULE:  MD_Mesh_GlobalNum
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Impl
! BRIEF:   Global numbering — P1 Renumber: global node/element numbering
!          system across instances.
!===============================================================================
!
! Contents:
!   Types:
!     - NodeGlobalMapEntry: Node global mapping entry
!     - ElemGlobalMapEntry: Element global mapping entry
!     - MeshGlobalNum: Global numbering system
!   Subroutines:
!     - GlobalNum_Build: Build global numbering from model
!     - GlobalNum_GetDofIndices: Get DOF indices for element
!   Functions:
!     - FindGlobalNodeIdForInstance: Find global node ID for instance
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
MODULE MD_Mesh_GlobalNum
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md
  USE IF_Prec_Core,        only: wp, i4, i8
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
  use MD_TypeSystem,        only: UF_Model, UF_Part, UF_Instance, UF_Element
  use MD_DOF_Mgr, only: MD_DOFMap
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global

  implicit none

  private

  !=============================================================================
  ! Global Numbering Types
  !=============================================================================
  type, public :: NodeGlobalMapEntry
    integer(i4)                          :: globalNodeId        = 0_i4
    integer(i4)                          :: partIndex           = 0_i4
    integer(i4)                          :: instanceIndex       = 0_i4
    integer(i4)                          :: localNodeId         = 0_i4
    integer(i4)                          :: dofStartIndex       = 0_i4
    integer(i4)                          :: nDof                = 0_i4
  end type NodeGlobalMapEntry

  type, public :: ElemGlobalMapEntry
    integer(i4)                          :: globalElemId        = 0_i4
    integer(i4)                          :: partIndex           = 0_i4
    integer(i4)                          :: instanceIndex       = 0_i4
    integer(i4)                          :: localElemId         = 0_i4
    integer(i4),           allocatable   :: connGlobalNodes(:)
  end type ElemGlobalMapEntry

  type, public :: MeshGlobalNum
    integer(i4)                          :: nGlobalNodes        = 0_i4
    integer(i4)                          :: nGlobalElems        = 0_i4
    integer(i4)                          :: nTotalEq            = 0_i4
    type(NodeGlobalMapEntry), allocatable :: nodeMap(:)
    type(ElemGlobalMapEntry), allocatable :: elemMap(:)
    integer(i4),           allocatable   :: instancenodeoff(:)
    integer(i4),           allocatable   :: INSTANCELEMOFFS(:)
    type(MD_DOFMap)                       :: dof_sys
  end type MeshGlobalNum

  public :: NodeGlobalMapEntry, ElemGlobalMapEntry, MeshGlobalNum
  public :: GlobalNum_Build, GlobalNum_BuildFromFlat, GlobalNum_GetDofIndices

contains

  !=============================================================================
  ! GlobalNum_BuildFromFlat
  ! Build MeshGlobalNum from flat mesh data (assembly or md_layer%mesh).
  ! No dependency on UF_Model; uses nNodes, nElems, element_connect only.
  ! Design: MESH_DOMAIN_DESIGN.md § A
  !=============================================================================
  subroutine GlobalNum_BuildFromFlat(nNodes, nElems, conn, numbering, nDofPerNode, status)
    integer(i8), intent(in) :: nNodes, nElems
    integer(i8), intent(in) :: conn(:,:)   ! (max_npe, nElems)
    type(MeshGlobalNum), intent(inout) :: numbering
    integer(i4), intent(in), optional :: nDofPerNode
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: ndpn, i, k, nConn, nNonZero
    integer(i4), allocatable :: ndof(:)

    call init_error_status(status)

    numbering%nGlobalNodes = 0_i4
    numbering%nGlobalElems = 0_i4
    numbering%nTotalEq     = 0_i4

    if (allocated(numbering%nodeMap)) deallocate(numbering%nodeMap)
    if (allocated(numbering%elemMap)) deallocate(numbering%elemMap)
    if (allocated(numbering%instancenodeoff)) deallocate(numbering%instancenodeoff)
    if (allocated(numbering%INSTANCELEMOFFS)) deallocate(numbering%INSTANCELEMOFFS)

    if (nNodes <= 0_i8 .and. nElems <= 0_i8) then
      status%status_code = IF_STATUS_OK
      return
    end if

    ndpn = 3_i4
    if (present(nDofPerNode)) ndpn = max(1_i4, nDofPerNode)

    numbering%nGlobalNodes = int(nNodes, i4)
    numbering%nGlobalElems = int(nElems, i4)

    ! Single flat instance
    allocate(numbering%instancenodeoff(2))
    allocate(numbering%INSTANCELEMOFFS(2))
    numbering%instancenodeoff(1) = 0_i4
    numbering%instancenodeoff(2) = numbering%nGlobalNodes
    numbering%INSTANCELEMOFFS(1) = 0_i4
    numbering%INSTANCELEMOFFS(2) = numbering%nGlobalElems

    ! Node map: sequential DOF numbering
    if (numbering%nGlobalNodes > 0_i4) then
      allocate(numbering%nodeMap(numbering%nGlobalNodes))
      do i = 1_i4, numbering%nGlobalNodes
        numbering%nodeMap(i)%globalNodeId  = i
        numbering%nodeMap(i)%partIndex     = 0_i4
        numbering%nodeMap(i)%instanceIndex = 1_i4
        numbering%nodeMap(i)%localNodeId   = i
        numbering%nodeMap(i)%nDof          = ndpn
        numbering%nodeMap(i)%dofStartIndex = ndpn * (i - 1_i4) + 1_i4
      end do
    end if

    ! Elem map: connGlobalNodes from connectivity
    if (numbering%nGlobalElems > 0_i4) then
      allocate(numbering%elemMap(numbering%nGlobalElems))
      nConn = size(conn, 1)
      do i = 1_i4, numbering%nGlobalElems
        numbering%elemMap(i)%globalElemId  = i
        numbering%elemMap(i)%partIndex     = 0_i4
        numbering%elemMap(i)%instanceIndex = 1_i4
        numbering%elemMap(i)%localElemId   = i

        nNonZero = 0_i4
        do k = 1, nConn
          if (conn(k, i) > 0_i8) nNonZero = nNonZero + 1_i4
        end do

        if (allocated(numbering%elemMap(i)%connGlobalNodes)) deallocate(numbering%elemMap(i)%connGlobalNodes)
        if (nNonZero > 0_i4) then
          allocate(numbering%elemMap(i)%connGlobalNodes(nNonZero))
          nNonZero = 0_i4
          do k = 1, nConn
            if (conn(k, i) > 0_i8) then
              nNonZero = nNonZero + 1_i4
              numbering%elemMap(i)%connGlobalNodes(nNonZero) = int(conn(k, i), i4)
            end if
          end do
        end if
      end do
    end if

    ! Init dof_sys (MD_DOFMap: Init(nNode,maxDpn), SetNdof(node,nd), MakeEq(eq0))
    if (numbering%nGlobalNodes > 0_i4) then
      allocate(ndof(numbering%nGlobalNodes))
      do i = 1_i4, numbering%nGlobalNodes
        ndof(i) = numbering%nodeMap(i)%nDof
      end do
      call numbering%dof_sys%Init(numbering%nGlobalNodes, maxval(ndof))
      do i = 1_i4, numbering%nGlobalNodes
        call numbering%dof_sys%SetNdof(i, ndof(i))
      end do
      call numbering%dof_sys%MakeEq(0_i4)
      deallocate(ndof)
    end if

    status%status_code = IF_STATUS_OK

  end subroutine GlobalNum_BuildFromFlat

  !=============================================================================
  ! GlobalNum_Build
  !=============================================================================
  subroutine GlobalNum_Build(model, numbering, ierr)
    type(UF_Model), intent(in) :: model
    type(MeshGlobalNum), intent(inout) :: numbering
    integer(i4), intent(out) :: ierr

    integer(i4) :: nInst, iInst, iNode, iElem, nodeCount, elemCount
    integer(i4) :: nConn, j
    integer(i4), allocatable :: ndof(:)
    type(UF_Instance), pointer :: instPtr
    type(UF_Part), pointer :: partPtr
    type(ErrorStatusType) :: status

    ierr = 0_i4
    call init_error_status(status)

    ! Mesh single-source path: when g_ufc_global ready and mesh%global_num built
    if (g_ufc_global%IsReady()) then
      if (g_ufc_global%md_layer%mesh%initialized) then
        if (allocated(g_ufc_global%md_layer%mesh%global_num%nodeMap) .and. &
            allocated(g_ufc_global%md_layer%mesh%global_num%elemMap)) then
          numbering = g_ufc_global%md_layer%mesh%global_num
          return
        end if
      end if
    end if

    numbering%nGlobalNodes = 0_i4
    numbering%nGlobalElems = 0_i4
    numbering%nTotalEq     = 0_i4

    if (allocated(numbering%nodeMap)) deallocate(numbering%nodeMap)
    if (allocated(numbering%elemMap)) deallocate(numbering%elemMap)
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
          nConn = 0_i4
          if (allocated(partPtr%elements(iElem)%conn)) then
            nConn = size(partPtr%elements(iElem)%conn)
          end if

          elemCount = elemCount + 1_i4
          numbering%elemMap(elemCount)%globalElemId  = elemCount
          numbering%elemMap(elemCount)%partIndex     = find_part_index(model, partPtr)
          numbering%elemMap(elemCount)%instanceIndex = iInst
          numbering%elemMap(elemCount)%localElemId   = partPtr%elements(iElem)%cfg%id

          if (allocated(numbering%elemMap(elemCount)%connGlobalNodes)) then
            deallocate(numbering%elemMap(elemCount)%connGlobalNodes)
          end if

          if (nConn > 0_i4) then
            allocate(numbering%elemMap(elemCount)%connGlobalNodes(nConn))

            do j = 1, nConn
              numbering%elemMap(elemCount)%connGlobalNodes(j) = &
                   FindGlobalNodeIdForInstance(numbering, iInst, partPtr%elements(iElem)%conn(j))
            end do
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
  ! find_part_index (internal helper)
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
  ! FindGlobalNodeIdForInstance (internal helper)
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

END MODULE MD_Mesh_GlobalNum
