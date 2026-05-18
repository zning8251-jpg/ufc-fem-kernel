!===============================================================================
! MODULE: RT_Asm_DofMap
! LAYER:  L5_RT
! DOMAIN: Assembly
! ROLE:   Util
! BRIEF:  DOF map builder -- global equation numbering, multi-field DOF mgmt
!===============================================================================
!
! Theory: Hughes The FEM (2000) S1.9; ABAQUS Theory S1.5
!
! Main Functions:
!   RT_Asm_DofMap_Build           - Build complete DOF mapping from model   [P1]
!   RT_Asm_DofMap_GetEqId         - Get equation ID from node/local DOF    [P2]
!   RT_Asm_DofMap_GetEqIdByDofType - Get equation ID from node/DOF type    [P2]
!   RT_Asm_DofMap_Unified_Manage  - Unified DOF management interface       [P1]
!   RT_Asm_DofMap_Unified_Cfg     - Unified DOF configuration interface    [P1]
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================

MODULE RT_Asm_DofMap
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
!> Theory: Hughes The FEM (2000) §1.9; ABAQUS Theory §1.5 | Last verified: 2026-02-14
!> Status: (TODO) | Last verified: 2026-02-14
  !! Runtime DOF Mapping Utilities
  !!
  !! Purpose:
  !!   - Build DOF mapping from model to solver
  !!   - Provide equation ID lookup functions
  !!   - Support multi-field DOF management
  !!
  !! Main Functions:
  !!   - RT_Asm_DofMap_Build: Build complete DOF mapping from model
  !!   - RT_Asm_DofMap_GetEqId: Get equation ID from node ID and local DOF
  !!   - RT_Asm_DofMap_GetEqIdByDofType: Get equation ID from node ID and DOF type
  !!   - RT_Asm_DofMap_GetEqId_Core: Get equation ID using unified DOF system

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core,   only: i4, wp
  use MD_Model_Mgr,        only: UF_Model, UF_Part, UF_Node, &
                            UF_DOF_U1, UF_DOF_U2, UF_DOF_U3, &
                            UF_DOF_UR1, UF_DOF_UR2, UF_DOF_UR3, &
                            UF_DOF_TEMP, UF_DOF_POR, UF_DOF_EPOT, &
                            UF_DOF_CHEM, UF_DOF_MPOT, &
                            UF_Field_Structural, UF_Field_Thermal, UF_Field_Pore, &
                            UF_FIELD_ELECTR, UF_FIELD_CHEMIC, UF_FIELD_MAGNET, &
                            UF_Field_Max
  use RT_Base_Core, only: ThreadWS
  use RT_Base_Sys, only: UF_WS_GetCurrentThreadWorkspacePtr, &
  USE RT_Solv_Def,  only: RT_Sol_DofMap
                         ThreadWS_PreheatDofMap, ThreadWS_GetDofMapWorkspace

  use RT_Solv_CoreMemPool, only: g_core_mem_pool, CoreMemPool_AllocInt1D, CoreMemPool_Dealloc
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  implicit none

  private

  public :: RT_Asm_DofMap_Build
  public :: RT_Asm_DofMap_GetEqId
  public :: RT_Asm_DofMap_GetEqIdByDofType
  ! Extended API (tasks 12900-12999)
  public :: RT_Asm_DofMap_Unified_Manage
  public :: RT_Asm_DofMap_Unified_Cfg



contains

    function FindNodeInPart(part_local, nid) result(node_ptr)
      type(UF_Part), intent(in) :: part_local
      integer(i4),   intent(in) :: nid
      type(UF_Node), pointer    :: node_ptr
      integer(i4) :: k

      node_ptr => null()
      if (.not. allocated(part_local%nodes)) return
      do k = 1, size(part_local%nodes)
        if (part_local%nodes(k)%cfg%id == nid) then
          node_ptr => part_local%nodes(k)
          return
        end if
      end do
    end function FindNodeInPart

    subroutine FreeDofMap(map)
      type(RT_Sol_DofMap), intent(inout) :: map
      if (nodetoeqstart_f) then
        call g_core_mem_pool%Dealloc('dofmap_nodeToEqStart')
      else
        if (allocated(map%nodeToEqStart))   deallocate(map%nodeToEqStart)
      end if
      if (nodenumdof_from) then
        call g_core_mem_pool%Dealloc('dofmap_nodeNumDof')
      else
        if (allocated(map%nodeNumDof))      deallocate(map%nodeNumDof)
      end if
      if (eqtonode_from_p) then
        call g_core_mem_pool%Dealloc('dofmap_eqToNode')
      else
        if (allocated(map%eqToNode))        deallocate(map%eqToNode)
      end if
      if (eqtolocal_from) then
        call g_core_mem_pool%Dealloc('dofmap_eqToLocal')
      else
        if (allocated(map%eqToLocal))       deallocate(map%eqToLocal)
      end if
      if (eqfieldid_from) then
        call g_core_mem_pool%Dealloc('dofmap_eqFieldId')
      else
        if (allocated(map%eqFieldId))       deallocate(map%eqFieldId)
      end if
      if (fieldeqcount_fr) then
        call g_core_mem_pool%Dealloc('dofmap_fieldEqCount')
      else
        if (allocated(map%fieldEqCount))    deallocate(map%fieldEqCount)
      end if
      if (eqlocalinfield) then
        call g_core_mem_pool%Dealloc('dofmap_eqLocalInField')
      else
        if (allocated(map%eqLocalInField))  deallocate(map%eqLocalInField)
      end if
      if (dofmask_from_po) then
        call g_core_mem_pool%Dealloc('dofmap_dofMask')
      else
        if (allocated(map%dofMask))         deallocate(map%dofMask)
      end if
      if (constrained_value_alloc) then
        call g_core_mem_pool%Dealloc('dofmap_constrainedValue')
      else
        if (allocated(map%constrained_value)) deallocate(map%constrained_value)
      end if
      map%nTotalEq = 0_i4
      map%nFields  = 0_i4
    end subroutine FreeDofMap

    subroutine MarkPartNodes(part, map)
      type(UF_Part),   intent(in)    :: part
      type(RT_Sol_DofMap), intent(inout) :: map
      integer(i4) :: k, nid, ndof

      if (.not. allocated(part%nodes)) return
      do k = 1, size(part%nodes)
        nid = part%nodes(k)%cfg%id
        if (nid < 1_i4 .or. nid > size(map%nodeNumDof)) cycle

        ! Determine DOF count from node dofTypes; default to 3 structural DOFs if unset

        if (allocated(part%nodes(k)%dofTypes)) then
          ndof = size(part%nodes(k)%dofTypes)
          if (ndof <= 0_i4) ndof = 3_i4
        else
          ndof = 3_i4
        end if

        ! If a node appears in multiple parts/instances, take the maximum DOF count

        if (ndof > map%nodeNumDof(nid)) map%nodeNumDof(nid) = ndof
      end do
    end subroutine MarkPartNodes

    integer(i4) function MaxNodeIdInPart(part) result(maxId)
      type(UF_Part), intent(in) :: part
      integer(i4) :: k
      maxId = 0_i4
      if (.not. allocated(part%nodes)) return
      do k = 1, size(part%nodes)
        maxId = max(maxId, part%nodes(k)%cfg%id)
      end do
    end function MaxNodeIdInPart

    subroutine RT_Asm_DofMap_BuildFromMesh(dofMap)
      type(RT_Sol_DofMap), intent(inout) :: dofMap
      integer(i4) :: maxNodeId, eq, nid, ndof, i
      integer(i4) :: nNodes
      if (allocated(dofMap%nodeToEqStart))   deallocate(dofMap%nodeToEqStart)
      if (allocated(dofMap%nodeNumDof))      deallocate(dofMap%nodeNumDof)
      if (allocated(dofMap%eqFieldId))       deallocate(dofMap%eqFieldId)
      if (allocated(dofMap%fieldEqCount))    deallocate(dofMap%fieldEqCount)
      if (allocated(dofMap%eqLocalInField))  deallocate(dofMap%eqLocalInField)
      if (allocated(dofMap%eqToNode))        deallocate(dofMap%eqToNode)
      if (allocated(dofMap%eqToLocal))       deallocate(dofMap%eqToLocal)
      if (allocated(dofMap%dofMask))         deallocate(dofMap%dofMask)
      if (allocated(dofMap%constrained_value)) deallocate(dofMap%constrained_value)
      dofMap%nTotalEq = 0_i4
      dofMap%nFields  = 0_i4
      if (.not. g_ufc_global%IsReady()) return
      if (.not. g_ufc_global%md_layer%mesh%initialized) return
      nNodes = int(g_ufc_global%md_layer%mesh%desc%nNodes, i4)
      maxNodeId = nNodes
      if (maxNodeId < 1_i4) return
      allocate(dofMap%nodeToEqStart(maxNodeId))
      allocate(dofMap%nodeNumDof(maxNodeId))
      dofMap%nodeToEqStart = 0_i4
      dofMap%nodeNumDof    = 0_i4
      do nid = 1, maxNodeId
        dofMap%nodeNumDof(nid) = 3_i4
      end do
      eq = 1_i4
      do i = 1, maxNodeId
        if (dofMap%nodeNumDof(i) > 0_i4) then
          dofMap%nodeToEqStart(i) = eq
          eq = eq + dofMap%nodeNumDof(i)
        end if
      end do
      dofMap%nTotalEq = eq - 1_i4
      dofMap%nFields  = UF_Field_Max
      if (dofMap%nTotalEq > 0_i4) then
        allocate(dofMap%eqFieldId(dofMap%nTotalEq))
        allocate(dofMap%fieldEqCount(dofMap%nFields))
        dofMap%eqFieldId = UF_Field_Structural
        dofMap%fieldEqCount = 0_i4
        if (UF_Field_Structural >= 1_i4 .and. UF_Field_Structural <= dofMap%nFields) then
          dofMap%fieldEqCount(UF_Field_Structural) = dofMap%nTotalEq
        end if
        allocate(dofMap%eqLocalInField(dofMap%nTotalEq))
        dofMap%eqLocalInField = 0_i4
        block
          integer(i4) :: fieldId, fieldCounter(UF_Field_Max)
          fieldCounter = 0_i4
          do eq = 1_i4, dofMap%nTotalEq
            fieldId = dofMap%eqFieldId(eq)
            if (fieldId >= 1_i4 .and. fieldId <= dofMap%nFields) then
              fieldCounter(fieldId) = fieldCounter(fieldId) + 1_i4
              dofMap%eqLocalInField(eq) = fieldCounter(fieldId)
            end if
          end do
        end block
        allocate(dofMap%eqToNode(dofMap%nTotalEq))
        allocate(dofMap%eqToLocal(dofMap%nTotalEq))
        allocate(dofMap%dofMask(dofMap%nTotalEq))
        allocate(dofMap%constrained_value(dofMap%nTotalEq))
        dofMap%eqToNode        = 0_i4
        dofMap%eqToLocal       = 0_i4
        dofMap%dofMask         = 1_i4
        dofMap%constrained_value = 0.0_wp
        do nid = 1, maxNodeId
          ndof = dofMap%nodeNumDof(nid)
          if (ndof <= 0_i4) cycle
          if (dofMap%nodeToEqStart(nid) < 1_i4) cycle
          do i = 1, ndof
            eq = dofMap%nodeToEqStart(nid) + i - 1_i4
            if (eq < 1_i4 .or. eq > dofMap%nTotalEq) cycle
            dofMap%eqToNode(eq)  = nid
            dofMap%eqToLocal(eq) = i
          end do
        end do
      end if
    end subroutine RT_Asm_DofMap_BuildFromMesh

  subroutine RT_Asm_DofMap_Build(model, dofMap)
    type(UF_Model),  intent(in)    :: model
    type(RT_Sol_DofMap), intent(inout) :: dofMap

    logical :: use_mesh
    integer(i4) :: maxNodeId, p, i, eq, nid, ndof, fieldId
    integer(i4), allocatable :: fieldCounter(:)
    type(ErrorStatusType) :: mem_status
    logical :: use_mem_pool
    logical :: nodetoeqstart_f, nodenumdof_from
    logical :: eqfieldid_from, fieldeqcount_fr
    logical :: eqlocalinfield, fieldcounter_fr
    logical :: eqtonode_from_p, eqtolocal_from
    logical :: dofmask_from_po, constrained_value_alloc


    !----------------------------------------
    ! 1) Find max node id (for allocating node arrays)
    !----------------------------------------

    call init_error_status(mem_status)

    ! Mesh single-source path: when g_ufc_global ready and mesh initialized
    use_mesh = g_ufc_global%IsReady() .and. g_ufc_global%md_layer%mesh%initialized
    if (use_mesh) then
      call RT_Asm_DofMap_BuildFromMesh(dofMap)
      return
    end if

    use_mem_pool = g_core_mem_pool%initialized
    nodetoeqstart_f = .false.
    nodenumdof_from = .false.
    eqfieldid_from = .false.
    fieldeqcount_fr = .false.
    eqlocalinfield = .false.
    fieldcounter_fr = .false.
    eqtonode_from_p = .false.
    eqtolocal_from = .false.
    dofmask_from_po = .false.
    constrained_value_alloc = .false.

    ! Try to use pre-allocated workspace from ThreadWS (Optimization)
    type(ThreadWS), pointer :: tws
    integer(i4), pointer :: ws_nodetoeqstar(:), ws_nodeNumDof(:)
    integer(i4), pointer :: ws_eqFieldId(:), ws_fieldEqCount(:)
    integer(i4), pointer :: ws_eqlocalinfie(:), ws_eqToNode(:), ws_eqToLocal(:)
    logical :: use_preallocate
    integer(i4) :: max_eq_count_es

    tws => UF_WS_GetCurrentThreadWorkspacePtr()
    use_preallocate = .false.

    maxNodeId = 0_i4
    if (allocated(model%assembly%instances) .and. allocated(model%parts)) then
      do i = 1, size(model%assembly%instances)
        p = model%assembly%instances(i)%cfg%id
        if (p < 1_i4 .or. p > size(model%parts)) cycle
        maxNodeId = max(maxNodeId, MaxNodeIdInPart(model%parts(p)))
      end do
    else if (allocated(model%parts)) then
      do p = 1, size(model%parts)
        maxNodeId = max(maxNodeId, MaxNodeIdInPart(model%parts(p)))
      end do
    end if

    if (maxNodeId < 1_i4) then
      dofMap%nTotalEq = 0_i4
      call FreeDofMap(dofMap)
      return
    end if

    call FreeDofMap(dofMap)

    ! Estimate max equation count (conservative: assume 3 DOFs per node)
    max_eq_count_es = maxNodeId * 3_i4

    ! Try to use pre-allocated workspace
    if (associated(tws)) then
      call ThreadWS_PreheatDofMap(tws, maxNodeId, max_eq_count_es, mem_status)
      if (mem_status%status_code == IF_STATUS_OK) then
        call ThreadWS_GetDofMapWorkspace(tws, maxNodeId, max_eq_count_es, &
                                         ws_nodetoeqstar, ws_nodeNumDof, &
                                         ws_eqFieldId, ws_fieldEqCount, &
                                         ws_eqlocalinfie, ws_eqToNode, ws_eqToLocal)
        if (associated(ws_nodetoeqstar) .and. associated(ws_nodeNumDof)) then
          use_preallocate = .true.
        end if
      end if
    end if

    ! Allocate dofMap arrays (use pre-allocated workspace as temporary buffer to reduce allocation overhead)
    if (use_preallocate) then
      ! Init arrays (workspace is used as buffer, not source)
      allocate(dofMap%nodeToEqStart(maxNodeId))
      allocate(dofMap%nodeNumDof(maxNodeId))
      ! Arrays will be initialized to 0 below
    else if (use_mem_pool) then
      call g_core_mem_pool%AllocInt1D('dofmap_nodeToEqStart', maxNodeId, dofMap%nodeToEqStart, mem_status)
      if (mem_status%status_code /= 0) then
        allocate(dofMap%nodeToEqStart(maxNodeId))
      else
        nodetoeqstart_f = .true.
      end if
      call g_core_mem_pool%AllocInt1D('dofmap_nodeNumDof', maxNodeId, dofMap%nodeNumDof, mem_status)
      if (mem_status%status_code /= 0) then
        allocate(dofMap%nodeNumDof(maxNodeId))
      else
        nodenumdof_from = .true.
      end if
    else
      allocate(dofMap%nodeToEqStart(maxNodeId))
      allocate(dofMap%nodeNumDof(maxNodeId))
    end if

    dofMap%nodeToEqStart = 0_i4
    dofMap%nodeNumDof    = 0_i4

    !----------------------------------------
    ! 2) Mark each node's DOF count by part/instance
    !----------------------------------------

    if (allocated(model%assembly%instances) .and. allocated(model%parts)) then
      do i = 1, size(model%assembly%instances)
        p = model%assembly%instances(i)%cfg%id
        if (p < 1_i4 .or. p > size(model%parts)) cycle
        call MarkPartNodes(model%parts(p), dofMap)
      end do
    else if (allocated(model%parts)) then
      do p = 1, size(model%parts)
        call MarkPartNodes(model%parts(p), dofMap)
      end do
    end if

    !----------------------------------------
    ! 3) Assign equation indices for each node DOF range
    !----------------------------------------

    eq = 1_i4
    do i = 1, maxNodeId
      if (dofMap%nodeNumDof(i) > 0_i4) then
        dofMap%nodeToEqStart(i) = eq
        eq = eq + dofMap%nodeNumDof(i)
      end if
    end do
    dofMap%nTotalEq = eq - 1_i4

    !----------------------------------------
    ! 4) Fill field metadata: eqFieldId / fieldEqCount
    !----------------------------------------

    dofMap%nFields = UF_Field_Max
    if (dofMap%nTotalEq > 0_i4) then
      ! Update max_eq_count_es with actual value
      if (dofMap%nTotalEq > max_eq_count_es) then
        max_eq_count_es = dofMap%nTotalEq
        ! Re-preheat if needed
        if (associated(tws) .and. .not. use_preallocate) then
          call ThreadWS_PreheatDofMap(tws, maxNodeId, max_eq_count_es, mem_status)
          if (mem_status%status_code == IF_STATUS_OK) then
            call ThreadWS_GetDofMapWorkspace(tws, maxNodeId, max_eq_count_es, &
                                             ws_nodetoeqstar, ws_nodeNumDof, &
                                             ws_eqFieldId, ws_fieldEqCount, &
                                             ws_eqlocalinfie, ws_eqToNode, ws_eqToLocal)
            if (associated(ws_eqFieldId) .and. associated(ws_fieldEqCount)) then
              use_preallocate = .true.
            end if
          end if
        end if
      end if

      if (use_preallocate .and. associated(ws_eqFieldId) .and. &
          size(ws_eqFieldId) >= dofMap%nTotalEq) then
        allocate(dofMap%eqFieldId(dofMap%nTotalEq))
        allocate(dofMap%fieldEqCount(dofMap%nFields))
        dofMap%eqFieldId(1:dofMap%nTotalEq) = ws_eqFieldId(1:dofMap%nTotalEq)
        dofMap%fieldEqCount(1:dofMap%nFields) = ws_fieldEqCount(1:dofMap%nFields)
      else if (use_mem_pool) then
        call g_core_mem_pool%AllocInt1D('dofmap_eqFieldId', dofMap%nTotalEq, dofMap%eqFieldId, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(dofMap%eqFieldId(dofMap%nTotalEq))
        else
          eqfieldid_from = .true.
        end if
        call g_core_mem_pool%AllocInt1D('dofmap_fieldEqCount', dofMap%nFields, dofMap%fieldEqCount, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(dofMap%fieldEqCount(dofMap%nFields))
        else
          fieldeqcount_fr = .true.
        end if
      else
        allocate(dofMap%eqFieldId(dofMap%nTotalEq))
        allocate(dofMap%fieldEqCount(dofMap%nFields))
      end if
      dofMap%eqFieldId = 0_i4
      dofMap%fieldEqCount = 0_i4

      call AssignEqFieldIds(model, dofMap)

      do eq = 1_i4, dofMap%nTotalEq
        if (dofMap%eqFieldId(eq) == 0_i4) dofMap%eqFieldId(eq) = UF_Field_Structural
        if (dofMap%eqFieldId(eq) >= 1_i4 .and. dofMap%eqFieldId(eq) <= dofMap%nFields) then
          dofMap%fieldEqCount(dofMap%eqFieldId(eq)) = dofMap%fieldEqCount(dofMap%eqFieldId(eq)) + 1_i4
        end if
      end do

      ! Assign local index within each field: eqLocalInField

      if (use_preallocate .and. associated(ws_eqlocalinfie) .and. &
          size(ws_eqlocalinfie) >= dofMap%nTotalEq) then
        allocate(dofMap%eqLocalInField(dofMap%nTotalEq))
        dofMap%eqLocalInField(1:dofMap%nTotalEq) = ws_eqlocalinfie(1:dofMap%nTotalEq)
      else if (use_mem_pool) then
        call g_core_mem_pool%AllocInt1D('dofmap_eqLocalInField', dofMap%nTotalEq, dofMap%eqLocalInField, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(dofMap%eqLocalInField(dofMap%nTotalEq))
        else
          eqlocalinfield = .true.
        end if
      else
        allocate(dofMap%eqLocalInField(dofMap%nTotalEq))
      end if
      dofMap%eqLocalInField = 0_i4
      if (dofMap%nFields > 0_i4) then
        if (use_mem_pool) then
          call g_core_mem_pool%AllocInt1D('dofmap_fieldCounter', dofMap%nFields, fieldCounter, mem_status)
          if (mem_status%status_code /= 0) then
            allocate(fieldCounter(dofMap%nFields))
          else
            fieldcounter_fr = .true.
          end if
        else
          allocate(fieldCounter(dofMap%nFields))
        end if
        fieldCounter = 0_i4
        do eq = 1_i4, dofMap%nTotalEq
          fieldId = dofMap%eqFieldId(eq)
          if (fieldId >= 1_i4 .and. fieldId <= dofMap%nFields) then
            fieldCounter(fieldId) = fieldCounter(fieldId) + 1_i4
            dofMap%eqLocalInField(eq) = fieldCounter(fieldId)
          end if
        end do
        if (fieldcounter_fr) then
          call g_core_mem_pool%Dealloc('dofmap_fieldCounter')
        else
          deallocate(fieldCounter)
        end if
      end if
    end if

    !----------------------------------------
    ! 5) Populate reverse lookup eq -> (node, localDof)
    !----------------------------------------

    if (dofMap%nTotalEq > 0_i4) then
      if (use_preallocate .and. associated(ws_eqToNode) .and. &
          size(ws_eqToNode) >= dofMap%nTotalEq .and. &
          associated(ws_eqToLocal) .and. size(ws_eqToLocal) >= dofMap%nTotalEq) then
        allocate(dofMap%eqToNode(dofMap%nTotalEq))
        allocate(dofMap%eqToLocal(dofMap%nTotalEq))
        dofMap%eqToNode(1:dofMap%nTotalEq) = ws_eqToNode(1:dofMap%nTotalEq)
        dofMap%eqToLocal(1:dofMap%nTotalEq) = ws_eqToLocal(1:dofMap%nTotalEq)
      else if (use_mem_pool) then
        call g_core_mem_pool%AllocInt1D('dofmap_eqToNode', dofMap%nTotalEq, dofMap%eqToNode, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(dofMap%eqToNode(dofMap%nTotalEq))
        else
          eqtonode_from_p = .true.
        end if
        call g_core_mem_pool%AllocInt1D('dofmap_eqToLocal', dofMap%nTotalEq, dofMap%eqToLocal, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(dofMap%eqToLocal(dofMap%nTotalEq))
        else
          eqtolocal_from = .true.
        end if
      else
        allocate(dofMap%eqToNode(dofMap%nTotalEq))
        allocate(dofMap%eqToLocal(dofMap%nTotalEq))
      end if

      if (use_mem_pool) then
        call g_core_mem_pool%AllocInt1D('dofmap_dofMask', dofMap%nTotalEq, dofMap%dofMask, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(dofMap%dofMask(dofMap%nTotalEq))
        else
          dofmask_from_po = .true.
        end if
      else
        allocate(dofMap%dofMask(dofMap%nTotalEq))
      end if

      if (use_mem_pool) then
        call g_core_mem_pool%AllocDP1D('dofmap_constrainedValue', dofMap%nTotalEq, dofMap%constrained_value, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(dofMap%constrained_value(dofMap%nTotalEq))
        else
          constrained_value_alloc = .true.
        end if
      else
        allocate(dofMap%constrained_value(dofMap%nTotalEq))
      end if

      dofMap%eqToNode        = 0_i4
      dofMap%eqToLocal       = 0_i4
      dofMap%dofMask         = 1_i4   ! Default: all DOFs free

      dofMap%constrained_value = 0.0_wp

      do nid = 1, maxNodeId
        ndof = dofMap%nodeNumDof(nid)
        if (ndof <= 0_i4) cycle
        if (dofMap%nodeToEqStart(nid) < 1_i4) cycle
        do i = 1, ndof
          eq = dofMap%nodeToEqStart(nid) + i - 1_i4
          if (eq < 1_i4 .or. eq > dofMap%nTotalEq) cycle
          dofMap%eqToNode(eq)  = nid
          dofMap%eqToLocal(eq) = i
        end do
      end do
    end if


  contains

    subroutine AssignEqFieldIds(model, map)
      type(UF_Model),  intent(in)    :: model
      type(RT_Sol_DofMap), intent(inout) :: map
      integer(i4) :: p, i

      if (allocated(model%assembly%instances) .and. allocated(model%parts)) then
        do i = 1, size(model%assembly%instances)
          p = model%assembly%instances(i)%cfg%id
          if (p < 1_i4 .or. p > size(model%parts)) cycle
          call AssignPartEqFields(model%parts(p), map)
        end do
      else if (allocated(model%parts)) then
        do p = 1, size(model%parts)
          call AssignPartEqFields(model%parts(p), map)
        end do
      end if
    end subroutine AssignEqFieldIds

    subroutine AssignPartEqFields(part, map)
      type(UF_Part),   intent(in)    :: part
      type(RT_Sol_DofMap), intent(inout) :: map
      integer(i4) :: k, nid, ndof_local, d, eq, fieldId

      if (.not. allocated(part%nodes)) return

      do k = 1, size(part%nodes)
        nid = part%nodes(k)%cfg%id
        if (nid < 1_i4 .or. nid > size(map%nodeNumDof)) cycle
        if (.not. allocated(part%nodes(k)%dofTypes)) cycle
        ndof_local = min(size(part%nodes(k)%dofTypes), map%nodeNumDof(nid))
        if (map%nodeToEqStart(nid) < 1_i4) cycle

        do d = 1, ndof_local
          eq = map%nodeToEqStart(nid) + d - 1_i4
          if (eq < 1_i4 .or. eq > map%nTotalEq) cycle
          if (map%eqFieldId(eq) /= 0_i4) cycle

          fieldId = GetFieldIdFromDofType(part%nodes(k)%dofTypes(d))
          map%eqFieldId(eq) = fieldId
        end do
      end do
    end subroutine AssignPartEqFields

    integer(i4) function GetFieldIdFromDofType(dofType) result(fid)
      integer(i4), intent(in) :: dofType
      select case (dofType)
      case (UF_DOF_U1, UF_DOF_U2, UF_DOF_U3, UF_DOF_UR1, UF_DOF_UR2, UF_DOF_UR3)
        fid = UF_Field_Structural
      case (UF_DOF_TEMP)
        fid = UF_Field_Thermal
      case (UF_DOF_POR)
        fid = UF_Field_Pore
      case (UF_DOF_EPOT)
        fid = UF_FIELD_ELECTR
      case (UF_DOF_CHEM)
        fid = UF_FIELD_CHEMIC
      case (UF_DOF_MPOT)
        fid = UF_FIELD_MAGNET
      case default
        fid = UF_Field_Structural
      end select
    end function GetFieldIdFromDofType

  !--------------------------------------------------------------------
  ! RT_Asm_DofMap_GetEqId: Get equation ID from node ID and local DOF
  !   eq = nodeToEqStart(node_id) + local_dof - 1
  !--------------------------------------------------------------------
  integer(i4) function RT_Asm_DofMap_GetEqId(dof_map, node_id, local_dof) result(eq_id)
    type(RT_Sol_DofMap), intent(in) :: dof_map
    integer(i4), intent(in) :: node_id, local_dof
    integer(i4) :: ndof, start_eq
    eq_id = 0_i4
    if (.not. allocated(dof_map%nodeToEqStart) .or. .not. allocated(dof_map%nodeNumDof)) return
    if (node_id < 1_i4 .or. node_id > size(dof_map%nodeToEqStart)) return
    ndof = dof_map%nodeNumDof(node_id)
    if (local_dof < 1_i4 .or. local_dof > ndof) return
    start_eq = dof_map%nodeToEqStart(node_id)
    if (start_eq < 1_i4) return
    eq_id = start_eq + local_dof - 1_i4
    if (eq_id < 1_i4 .or. eq_id > dof_map%nTotalEq) eq_id = 0_i4
  end function RT_Asm_DofMap_GetEqId

  !--------------------------------------------------------------------
  ! RT_Asm_DofMap_GetEqIdByDofType: Get equation ID from node ID and DOF type
  !   Requires model to map dof_type (UF_DOF_U1 etc) to local DOF index
  !--------------------------------------------------------------------
  integer(i4) function RT_Asm_DofMap_GetEqIdByDofType(model, dof_map, node_id, dof_type) result(eq_id)
    type(UF_Model), intent(in) :: model
    type(RT_Sol_DofMap), intent(in) :: dof_map
    integer(i4), intent(in) :: node_id, dof_type
    integer(i4) :: local_dof
    ! Map UF_DOF_U1=1,U2=2,U3=3,UR1=4,UR2=5,UR3=6 to local 1..6
    select case (dof_type)
    case (UF_DOF_U1);   local_dof = 1_i4
    case (UF_DOF_U2);   local_dof = 2_i4
    case (UF_DOF_U3);   local_dof = 3_i4
    case (UF_DOF_UR1);  local_dof = 4_i4
    case (UF_DOF_UR2);  local_dof = 5_i4
    case (UF_DOF_UR3);  local_dof = 6_i4
    case (UF_DOF_TEMP); local_dof = 1_i4  ! thermal: first DOF
    case default;      local_dof = 1_i4
    end select
    eq_id = RT_Asm_DofMap_GetEqId(dof_map, node_id, local_dof)
  end function RT_Asm_DofMap_GetEqIdByDofType

  subroutine RT_Asm_DofMap_Unified_Cfg(model, field_types, dof_map, status)
    !! Unified DOF configuration interface
    !!
    !! This subroutine provides a unified interface for configuring DOF mapping,
    !! automatically building DOF map from model and field types.
    !!
    !! Input:
    !!   model       - Model instance
    !!   field_types - Array of field types (optional)
    !!
    !! Output:
    !!   dof_map     - Configured DOF mapping
    !!   status      - Error status
    !!
    !! Task: 12950-12999
    type(UF_Model), intent(in) :: model
    integer(i4), intent(in), optional :: field_types(:)
    type(RT_Sol_DofMap), intent(out) :: dof_map
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    ! Build DOF map from model
    call RT_Asm_DofMap_Build(model, dof_map)

    ! Cfg field-specific DOF mapping if field types provided
    if (present(field_types)) then
      ! TODO: Cfg field-specific DOF mapping
      ! For now, the basic DOF map is built
    end if

    local_status%status_code = IF_STATUS_OK
    local_status%message = 'RT_Asm_DofMap_Unified_Cfg: DOF configuration completed successfully'

    if (present(status)) status = local_status

  end subroutine RT_Asm_DofMap_Unified_Cfg

  subroutine RT_Asm_DofMap_Unified_Manage(model, dof_map, operation, &
                                      node_id, dof_type, eq_id, status)
    !! Unified DOF management interface
    !!
    !! This subroutine provides a unified interface for managing DOF mapping
    !! operations, including building DOF map and querying equation IDs.
    !!
    !! Input:
    !!   model         - Model instance
    !!   operation     - Operation: 'build', 'get_eq_id', 'get_eq_id_by_type'
    !!   node_id       - Node ID (for query operations)
    !!   dof_type      - DOF type (for query operations)
    !!
    !! Input/Output:
    !!   dof_map       - DOF mapping
    !!
    !! Output:
    !!   eq_id         - Equation ID (for query operations)
    !!   status        - Error status
    !!
    !! Task: 12900-12949
    type(UF_Model), intent(in) :: model
    type(RT_Sol_DofMap), intent(inout) :: dof_map
    character(len=*), intent(in) :: operation
    integer(i4), intent(in), optional :: node_id, dof_type
    integer(i4), intent(out), optional :: eq_id
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status
    integer(i4) :: local_eq_id

    call init_error_status(local_status)

    ! Process based on operation
    select case (trim(operation))
    case ('build', 'BUILD')
      ! Build DOF map
      call RT_Asm_DofMap_Build(model, dof_map)
      local_status%status_code = IF_STATUS_OK
      local_status%message = 'RT_Asm_DofMap_Unified_Manage: DOF map built successfully'

    case ('get_eq_id', 'GET_EQ_ID')
      ! Get equation ID from node ID and local DOF
      if (.not. present(node_id) .or. .not. present(dof_type)) then
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'RT_Asm_DofMap_Unified_Manage: Node ID and DOF type required for get_eq_id'
        if (present(status)) status = local_status
        return
      end if

      local_eq_id = RT_Asm_DofMap_GetEqId(dof_map, node_id, dof_type)
      if (local_eq_id > 0) then
        if (present(eq_id)) eq_id = local_eq_id
        local_status%status_code = IF_STATUS_OK
        local_status%message = 'RT_Asm_DofMap_Unified_Manage: Equation ID retrieved successfully'
      else
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'RT_Asm_DofMap_Unified_Manage: Invalid node ID or DOF type'
      end if

    case ('get_eq_id_by_type', 'GET_EQ_ID_BY_TYPE')
      ! Get equation ID from node ID and DOF type
      if (.not. present(node_id) .or. .not. present(dof_type)) then
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'RT_Asm_DofMap_Unified_Manage: Node ID and DOF type required for get_eq_id_by_type'
        if (present(status)) status = local_status
        return
      end if

      local_eq_id = RT_Asm_DofMap_GetEqIdByDofType(model, dof_map, node_id, dof_type)
      if (local_eq_id > 0) then
        if (present(eq_id)) eq_id = local_eq_id
        local_status%status_code = IF_STATUS_OK
        local_status%message = 'RT_Asm_DofMap_Unified_Manage: Equation ID retrieved successfully'
      else
        local_status%status_code = IF_STATUS_ERROR
        local_status%message = 'RT_Asm_DofMap_Unified_Manage: Invalid node ID or DOF type'
      end if

    case default
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'RT_Asm_DofMap_Unified_Manage: Invalid operation - ' // trim(operation)
    end select

    if (present(status)) status = local_status

  end subroutine RT_Asm_DofMap_Unified_Manage
END MODULE RT_Asm_DofMap