!===============================================================================
! MODULE:  MD_Mesh_Domain
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Domain
! BRIEF:   Mesh domain container — unified container for Mesh topology (Elem/ is sibling for element defs).
!          SSOT for mesh topology (nodes, elements, DOF mapping).
!===============================================================================
! Design outline: Outline Sec 12.2, 2.6a, L3_MD Mesh domain contract 1.5
! USE contract (Outline 7.3): L1_IF, L3_MD only; L2/L4/L5/L6 via Bridge/KeyWord
! Purpose:
!   Unified domain container MD_Mesh_Domain for Mesh topology domain.
!   Single source of truth for mesh topology (node coordinates, element
!   connectivity) and global DOF mapping. Encapsulates MeshManager and
!   exposes a read-only API to L4_PH/L5_RT layers.
!
! Theory chain:
!   Mesh discretization (ABAQUS ?.1):
!     Node positions X ?R^(3 n_n), connectivity conn ?Z^(max_npe n_e).
!     Shape functions N(?,?,?): isoparametric mapping x = ? N_I(?) X_I.
!     Jacobian J = dX/d? ?R^(3?), det(J) > 0 required.
!     DOF mapping L?G: localNodeId ?globalDofStartIndex (via MeshGlobalNum).
!
! Logic chain:
!   L6_AP (parse *NODE/*ELEMENT) ?MD_Mesh_Domain_Init ?
!   GlobalNum_Build (DOF mapping) ?[L3 frozen: l3Frozen=.TRUE.] ?
!   L4_PH_Elem (GetElemConnect, per Step boundary) ?
!   L5_RT_Asm  (GetDofMap, per Increment) ?
!   [large-deform only] MD_Mesh_WriteBack_NodePos (WriteBack API).
!
! Computation chain:
!   Init: MeshData%Init(nNodes,nElems,spatial_dim); ALLOCATE node/elem arrays.
!         GlobalNum_Build(global_num, assembly) ?n_dof = ? nDof/node ?nNodes.
!   GetNodeCoords: x_i = raw_data%node_coords(:,local_id); O(1).
!   GetElemConnect: conn_e = raw_data%element_connect(:,elem_id); O(1).
!   GetDofMap: dof_start = global_num%nodeMap(id)%dofStartIndex; O(1).
!   WriteBack: node_state(i)%currentCoords = x_updated (large-deform only).
!
! Data chain:
!   Container: g_ufc_global%md_layer%mesh (TYPE :: MD_Mesh_Domain)
!   Desc (Write-Once after parse):
!     desc        : meshId/name/nNodes/nElems/elemFamily
!     node_desc(:): globalNodeId/coords (Analysis-level frozen)
!     elem_desc(:): elemType/connectivity (Analysis-level frozen)
!     global_num  : dof_sys (frozen after GlobalNum_Build)
!   State (WriteBack whitelist):
!     state               : isActive/nAssembled
!     node_state(:)%currentCoords (large-deform WriteBack target)
!     elem_state(:)       : IP-state cache (sync at Increment end)
!   Algo (Solve-phase read-only):
!     algo: integration_order/nlgeom/large_strain/elem_formulation
!   Ctx (transient, not resident in container):
!     MeshCtx (meshId/assemblyId/instanceId): created by L6_AP, released post-parse
!
! Three-step mapping:
!   Analysis step: Init/build_global_num (parse phase); GetDofMap (step boundary).
!   Increment:     GetNodeCoords/GetElemConnect (per increment, read-only).
!   Iteration:     GetDofMap (per iteration, read-only).
!
! WriteBack whitelist (L5_RT -> L3_MD only via these APIs):
!   MD_Mesh_WriteBack_NodePos  : node_state(i)%currentCoords (large-deform)
!   MD_Mesh_WriteBack_State    : state%nAssembled
!   Prohibited: desc%nNodes/nElems/global_num/elem_desc (frozen forever).
!
! Contents (A-Z):
!   Types:
!     MeshAlgo            ?Algorithm parameters (Algo)
!     MD_Mesh_Domain     ?Domain container
!   Subroutines:
!     MD_Mesh_Domain_Finalize
!     MD_Mesh_Domain_GetDofMap
!     MD_Mesh_Domain_GetElemConnect
!     MD_Mesh_Domain_GetNodeCoords
!     MD_Mesh_Domain_GetSurfaceByName
!     MD_Mesh_Domain_Init
!     MD_Mesh_WriteBack_NodePos
!     MD_Mesh_WriteBack_State
!
! Notes:
!   - g_mesh_manager is encapsulated inside raw_data; external code must NOT
!     access g_mesh_manager directly after Phase B migration.
!   - MD_Mesh_Algo.f90 backward-compat bridge remains until Phase C cleanup.
!   - Logic/Computation chain diagram: MD_Mesh_Domain_Core_Chains.md
!
! Status: Phase B (Arg-wrapped: GetSummary)
! Last verified: 2026-03-11
! Theory: N/A
! Status: Draft
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Domain_Core | FuncSet:Init,Query,Valid | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Mesh/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Mesh | Role:Domain_Core | FuncSet:Init,Query,Valid | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Mesh_Domain
  USE IF_Prec_Core,           ONLY: wp, i4, i8
  USE IF_Err_Brg,        ONLY: ErrorStatusType, init_error_status, &
                                IF_STATUS_OK, IF_STATUS_INVALID
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Mesh_Data,      ONLY: MeshData, MeshDesc, MeshState, MeshCtx, MD_MESH_MAX_NODES_PER_ELEM
  USE MD_Mesh_Node,      ONLY: MeshNodeDesc, MeshNodeState
  USE MD_Mesh_Elem,      ONLY: MeshElemDesc, MeshElemState
  USE MD_Mesh_GlobalNum, ONLY: MeshGlobalNum, GlobalNum_Build

  IMPLICIT NONE
  PRIVATE

  !============================================================================
  ! MeshAlgo: Algorithm parameters (Algo category)
  ! Read-only during Solve phase; frozen after L6_AP parse.
  !============================================================================
  TYPE, PUBLIC :: MeshAlgo
    INTEGER(i4) :: integration_order = 2_i4  !! Gauss integration order
    INTEGER(i4) :: elem_formulation  = 1_i4  !! 1=full, 2=reduced integration
    LOGICAL     :: nlgeom      = .FALSE.      !! Large displacement flag
    LOGICAL     :: large_strain = .FALSE.     !! Large strain flag (WriteBack enabled)
  END TYPE MeshAlgo

  !============================================================================
  ! MD_Mesh_Domain: Unified domain container (Single Source of Truth)
  ! Container path: g_ufc_global%md_layer%mesh
  !
  ! Lifecycle: Init (parse) ?[frozen] ?GetXxx (L4/L5 RO) ?Finalize.
  ! WriteBack is gated: only WriteBack_NodePos / WriteBack_State APIs.
  !============================================================================
  TYPE, PUBLIC :: MD_Mesh_Domain
    !--- Desc (Write-Once, Read-Many) ---
    TYPE(MeshDesc)                       :: desc         !! Mesh descriptor
    TYPE(MeshNodeDesc),      ALLOCATABLE :: node_desc(:) !! Node descriptors (nNodes)
    TYPE(MeshElemDesc),      ALLOCATABLE :: elem_desc(:) !! Element descriptors (nElems)
    TYPE(MeshGlobalNum)                  :: global_num   !! Global DOF numbering table
    !--- State (Analysis-level; WriteBack target for large-deform) ---
    TYPE(MeshState)                      :: state        !! Mesh state (isActive/nAssembled)
    TYPE(MeshNodeState),     ALLOCATABLE :: node_state(:)!! Per-node state (currentCoords)
    TYPE(MeshElemState),     ALLOCATABLE :: elem_state(:)!! Per-element state (IP cache)
    !--- Algo (Solve-phase read-only) ---
    TYPE(MeshAlgo)                       :: algo         !! Algorithm parameters
    !--- Internal raw storage (encapsulates g_mesh_manager data) ---
    TYPE(MeshData)                       :: raw_data     !! Raw coords + connectivity
    !--- Control ---
    LOGICAL                              :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: GetNodeCoords
    PROCEDURE :: GetElemConnect
    PROCEDURE :: GetElemSection
    PROCEDURE :: GetDofMap
    PROCEDURE :: GetSurfaceByName
    PROCEDURE :: GetNodeByName
    PROCEDURE :: GetSummary
    PROCEDURE :: WriteBack_NodePos => MD_Mesh_WriteBack_NodePos
    PROCEDURE :: WriteBack_NodeDisp => MD_Mesh_WriteBack_NodeDisp
    PROCEDURE :: WriteBack_NodeVel => MD_Mesh_WriteBack_NodeVel
    PROCEDURE :: WriteBack_NodeAcc => MD_Mesh_WriteBack_NodeAcc
    PROCEDURE :: WriteBack_ElemStress => MD_Mesh_WriteBack_ElemStress
    PROCEDURE :: WriteBack_State   => MD_Mesh_WriteBack_State
  END TYPE MD_Mesh_Domain

  ! --- Arg types (Phase B) ---
  !============================================================================
  ! MD_Mesh_GetNodeCoords_Arg - Output container for index-based GetNodeCoords
  ! (?????? Phase 2: entity_idx + arg ??)
  !============================================================================
  TYPE, PUBLIC :: MD_Mesh_GetNodeCoords_Arg
    REAL(wp) :: coords(3) = 0.0_wp
  END TYPE MD_Mesh_GetNodeCoords_Arg

  !============================================================================
  ! MD_Mesh_GetElemConnect_Arg - Output container for index-based GetElemConnect
  ! (?????? Phase 2: entity_idx + arg ??)
  !============================================================================
  TYPE, PUBLIC :: MD_Mesh_GetElemConnect_Arg
    INTEGER(i8) :: connect(MD_MESH_MAX_NODES_PER_ELEM) = 0_i8  ! Valid entries: 1:npe
    INTEGER(i4) :: npe = 0_i4
  END TYPE MD_Mesh_GetElemConnect_Arg

  !============================================================================
  ! MD_Mesh_GetDofMap_Arg - Output container for index-based GetDofMap
  ! (?????? Phase 2: entity_idx + arg ??)
  !============================================================================
  TYPE, PUBLIC :: MD_Mesh_GetDofMap_Arg
    INTEGER(i4) :: global_dof_start = 0_i4
    INTEGER(i4) :: n_dof = 0_i4
  END TYPE MD_Mesh_GetDofMap_Arg

  !============================================================================
  ! MD_Mesh_GetElemSection_Arg - Output container for index-based GetElemSection
  ! (Phase 3: elem_idx + arg -> section_idx)
  !============================================================================
  TYPE, PUBLIC :: MD_Mesh_GetElemSection_Arg
    INTEGER(i4) :: section_idx = 0_i4  ! 0 = not assigned
  END TYPE MD_Mesh_GetElemSection_Arg

  TYPE, PUBLIC :: MD_Mesh_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mesh_GetSummary_Arg

  ! WriteBack whitelist (Phase 2): node_state only
  TYPE, PUBLIC :: MD_Mesh_WriteBack_NodePos_Arg
    REAL(wp) :: new_coords(3) = 0.0_wp
  END TYPE MD_Mesh_WriteBack_NodePos_Arg

  ! Arg for GetSurfaceByName (Phase B: name lookup)
  TYPE, PUBLIC :: MD_Mesh_GetSurfaceByName_Arg
    LOGICAL :: found = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mesh_GetSurfaceByName_Arg

  ! Arg for GetNodeByName (Phase B: >4 params -> Arg)
  TYPE, PUBLIC :: MD_Mesh_GetNodeByName_Arg
    INTEGER(i4) :: node_idx = 0_i4
    LOGICAL :: found = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Mesh_GetNodeByName_Arg

  ! Arg for WriteBack_ElemStress (Phase B: >4 params -> Arg)
  TYPE, PUBLIC :: MD_Mesh_WriteBack_ElemStress_Arg
    INTEGER(i4) :: ip_idx = 0_i4
    REAL(wp) :: sigma(6) = 0.0_wp
  END TYPE MD_Mesh_WriteBack_ElemStress_Arg

  PUBLIC :: MD_Mesh_Domain, MeshAlgo
  PUBLIC :: MD_Mesh_GetNodeCoords_Arg, MD_Mesh_GetNodeCoords_Idx
  PUBLIC :: MD_Mesh_GetElemConnect_Arg, MD_Mesh_GetElemConnect_Idx
  PUBLIC :: MD_Mesh_GetDofMap_Arg, MD_Mesh_GetDofMap_Idx
  PUBLIC :: MD_Mesh_GetElemSection_Arg, MD_Mesh_GetElemSection_Idx
  PUBLIC :: MD_Mesh_WriteBack_NodePos_Arg, MD_Mesh_WriteBack_NodePos_Idx
  PUBLIC :: MD_Mesh_GetSurfaceByName_Arg, MD_Mesh_GetSurfaceByName_Idx
  PUBLIC :: MD_Mesh_GetNodeByName_Arg, MD_Mesh_GetNodeByName_Idx
  PUBLIC :: MD_Mesh_WriteBack_ElemStress_Arg, MD_Mesh_WriteBack_ElemStress_Idx

CONTAINS

  !============================================================================
  ! MD_Mesh_Domain_Finalize
  ! Release all allocated resources; called in reverse init order (L5->L4->L3).
  !============================================================================
  SUBROUTINE Finalize(this)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this

    IF (ALLOCATED(this%node_desc))  DEALLOCATE(this%node_desc)
    IF (ALLOCATED(this%elem_desc))  DEALLOCATE(this%elem_desc)
    IF (ALLOCATED(this%node_state)) DEALLOCATE(this%node_state)
    IF (ALLOCATED(this%elem_state)) DEALLOCATE(this%elem_state)
    CALL this%raw_data%Clean()
    this%initialized = .FALSE.

  END SUBROUTINE Finalize

  !============================================================================
  ! MD_Mesh_Domain_GetDofMap
  ! Read-only access to global DOF index for a local node.
  ! Called by L5_RT_Asm per Increment; O(1) lookup.
  !============================================================================
  SUBROUTINE GetDofMap(this, local_node_id, global_dof_start, nDof, status)
    CLASS(MD_Mesh_Domain), INTENT(IN)  :: this
    INTEGER(i4),           INTENT(IN)  :: local_node_id
    INTEGER(i4),           INTENT(OUT) :: global_dof_start
    INTEGER(i4),           INTENT(OUT) :: nDof
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    global_dof_start = this%global_num%nodeMap(local_node_id)%dofStartIndex
    nDof             = this%global_num%nodeMap(local_node_id)%nDof

  END SUBROUTINE GetDofMap

  !============================================================================
  ! MD_Mesh_Domain_GetElemConnect
  ! Read-only element connectivity access; called by L4_PH_Elem per Step.
  !============================================================================
  SUBROUTINE GetElemConnect(this, elem_id, connect, npe, status)
    CLASS(MD_Mesh_Domain), INTENT(IN)  :: this
    INTEGER(i8),           INTENT(IN)  :: elem_id
    INTEGER(i8),           INTENT(OUT) :: connect(:)
    INTEGER(i4),           INTENT(OUT) :: npe
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: k

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    CALL this%raw_data%GetElementConnectivity(elem_id, connect, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    npe = 0_i4
    DO k = 1, SIZE(connect)
      IF (connect(k) <= 0_i8) EXIT
      npe = npe + 1_i4
    END DO

  END SUBROUTINE GetElemConnect

  !============================================================================
  ! MD_Mesh_Domain_GetElemSection
  ! Read-only section_ref for element (MD_MESH_ELEMENT_INDEX_FLAT_MIGRATION Phase A).
  ! Returns 0 if not assigned.
  !============================================================================
  SUBROUTINE GetElemSection(this, elem_id, section_ref, status)
    CLASS(MD_Mesh_Domain), INTENT(IN)  :: this
    INTEGER(i8),           INTENT(IN)  :: elem_id
    INTEGER(i4),           INTENT(OUT) :: section_ref
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    section_ref = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (elem_id < 1_i8 .OR. elem_id > this%raw_data%nElems) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (ALLOCATED(this%raw_data%elem_section_ref)) THEN
      section_ref = this%raw_data%elem_section_ref(INT(elem_id, i4))
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE GetElemSection

  !============================================================================
  ! MD_Mesh_GetElemSection_Idx - Standalone index-based API (Phase 3)
  !   Signature: (elem_idx, arg, status) - uses g_ufc_global internally.
  !   Returns section_idx in arg (0 = not assigned).
  !============================================================================
  SUBROUTINE MD_Mesh_GetElemSection_Idx(elem_idx, arg, status)
    INTEGER(i4),                        INTENT(IN)    :: elem_idx
    TYPE(MD_Mesh_GetElemSection_Arg),  INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),              INTENT(OUT)   :: status

    CALL init_error_status(status)
    arg%section_idx = 0_i4
    ASSOCIATE(mesh => g_ufc_global%md_layer%mesh)
      IF (.NOT. mesh%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Mesh domain not initialized"
        RETURN
      END IF
      IF (elem_idx < 1_i4 .OR. elem_idx > INT(mesh%raw_data%nElems, i4)) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      IF (ALLOCATED(mesh%raw_data%elem_section_ref)) THEN
        arg%section_idx = mesh%raw_data%elem_section_ref(elem_idx)
      END IF
    END ASSOCIATE
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_GetElemSection_Idx

  !============================================================================
  ! MD_Mesh_Domain_GetNodeCoords
  ! Read-only node coordinate access; called by L4/L5 per Increment.
  ! Caller MUST NOT attempt to modify coords through this interface.
  !============================================================================
  SUBROUTINE GetNodeCoords(this, local_id, coords, status)
    CLASS(MD_Mesh_Domain), INTENT(IN)  :: this
    INTEGER(i8),           INTENT(IN)  :: local_id
    REAL(wp),              INTENT(OUT) :: coords(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    CALL this%raw_data%GetNodeCoords(local_id, coords, status)

  END SUBROUTINE GetNodeCoords

  !============================================================================
  ! MD_Mesh_GetNodeCoords_Idx - Standalone index-based API (Phase 2)
  !   Signature: (node_idx, arg, status) - no container, no struct input.
  !   Uses g_ufc_global%md_layer%mesh internally.
  !============================================================================
  SUBROUTINE MD_Mesh_GetNodeCoords_Idx(node_idx, arg, status)
    INTEGER(i4),                        INTENT(IN)    :: node_idx
    TYPE(MD_Mesh_GetNodeCoords_Arg),   INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),              INTENT(OUT)   :: status

    CALL init_error_status(status)

    ASSOCIATE(mesh => g_ufc_global%md_layer%mesh)
      IF (.NOT. mesh%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Mesh domain not initialized"
        RETURN
      END IF
      IF (node_idx < 1_i4 .OR. node_idx > mesh%desc%nNodes) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      CALL mesh%raw_data%GetNodeCoords(INT(node_idx, i8), arg%coords, status)
    END ASSOCIATE

  END SUBROUTINE MD_Mesh_GetNodeCoords_Idx

  !============================================================================
  ! MD_Mesh_GetElemConnect_Idx - Standalone index-based API (Phase 2)
  !   Signature: (elem_idx, arg, status) - no container, no struct input.
  !   Uses g_ufc_global%md_layer%mesh internally.
  !============================================================================
  SUBROUTINE MD_Mesh_GetElemConnect_Idx(elem_idx, arg, status)
    INTEGER(i4),                         INTENT(IN)    :: elem_idx
    TYPE(MD_Mesh_GetElemConnect_Arg),   INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),              INTENT(OUT)   :: status

    INTEGER(i4) :: k

    CALL init_error_status(status)
    arg%npe = 0_i4
    arg%connect = 0_i8

    ASSOCIATE(mesh => g_ufc_global%md_layer%mesh)
      IF (.NOT. mesh%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Mesh domain not initialized"
        RETURN
      END IF
      IF (elem_idx < 1_i4 .OR. elem_idx > INT(mesh%raw_data%nElems, i4)) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      CALL mesh%raw_data%GetElementConnectivity(INT(elem_idx, i8), arg%connect, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      DO k = 1, SIZE(arg%connect)
        IF (arg%connect(k) <= 0_i8) EXIT
        arg%npe = arg%npe + 1_i4
      END DO
    END ASSOCIATE

  END SUBROUTINE MD_Mesh_GetElemConnect_Idx

  !============================================================================
  ! MD_Mesh_GetDofMap_Idx - Standalone index-based API (Phase 2)
  !   Signature: (node_idx, arg, status) - no container, no struct input.
  !   Uses g_ufc_global%md_layer%mesh internally.
  !============================================================================
  SUBROUTINE MD_Mesh_GetDofMap_Idx(node_idx, arg, status)
    INTEGER(i4),                    INTENT(IN)    :: node_idx
    TYPE(MD_Mesh_GetDofMap_Arg),   INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),          INTENT(OUT)   :: status

    CALL init_error_status(status)
    arg%global_dof_start = 0_i4
    arg%pop%n_dof = 0_i4

    ASSOCIATE(mesh => g_ufc_global%md_layer%mesh)
      IF (.NOT. mesh%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Mesh domain not initialized"
        RETURN
      END IF
      IF (.NOT. ALLOCATED(mesh%global_num%nodeMap)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Global numbering not built"
        RETURN
      END IF
      IF (node_idx < 1_i4 .OR. node_idx > SIZE(mesh%global_num%nodeMap)) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      arg%global_dof_start = mesh%global_num%nodeMap(node_idx)%dofStartIndex
      arg%pop%n_dof = mesh%global_num%nodeMap(node_idx)%nDof
    END ASSOCIATE

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Mesh_GetDofMap_Idx

  !============================================================================
  ! MD_Mesh_WriteBack_NodePos_Idx - Standalone WriteBack (Phase 2)
  !   Whitelist: node_state%currentCoords only
  !============================================================================
  SUBROUTINE MD_Mesh_WriteBack_NodePos_Idx(node_idx, arg, status)
    INTEGER(i4),                         INTENT(IN)    :: node_idx
    TYPE(MD_Mesh_WriteBack_NodePos_Arg), INTENT(IN)    :: arg
    TYPE(ErrorStatusType),                INTENT(OUT)   :: status

    CALL init_error_status(status)
    ASSOCIATE(mesh => g_ufc_global%md_layer%mesh)
      IF (.NOT. mesh%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Mesh domain not initialized"
        RETURN
      END IF
      IF (node_idx < 1_i4 .OR. node_idx > mesh%desc%nNodes) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      mesh%node_state(node_idx)%currentCoords = arg%new_coords
    END ASSOCIATE
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_WriteBack_NodePos_Idx

  !============================================================================
  ! MD_Mesh_Domain_Init
  ! Initialize domain container from parsed mesh data (L6_AP parse phase).
  ! After this call, desc/node_desc/elem_desc/global_num are frozen.
  !============================================================================
  SUBROUTINE Init(this, nNodes, nElems, spatial_dim, status, max_nodes_per_elem)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i8),           INTENT(IN)    :: nNodes, nElems
    INTEGER(i4),           INTENT(IN)    :: spatial_dim
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    INTEGER(i4),           INTENT(IN), OPTIONAL :: max_nodes_per_elem

    CALL init_error_status(status)

    !--- Initialize raw mesh data container (supports up to 27 nodes/elem) ---
    CALL this%raw_data%Init(nNodes, nElems, spatial_dim, status, max_nodes_per_elem)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    !--- Populate frozen Desc fields ---
    this%desc%nNodes = INT(nNodes, i4)
    this%desc%nElems = INT(nElems, i4)

    !--- Allocate per-node and per-element arrays ---
    ALLOCATE(this%node_desc(nNodes))
    ALLOCATE(this%elem_desc(nElems))
    ALLOCATE(this%node_state(nNodes))
    ALLOCATE(this%elem_state(nElems))

    this%initialized = .TRUE.

  END SUBROUTINE Init

  !============================================================================
  ! MD_Mesh_WriteBack_NodePos
  ! ONLY legal L5_RT WriteBack path for node position update (large-deform).
  ! Updates node_state(i)%currentCoords ONLY; raw_data%node_coords is immutable.
  !============================================================================
  SUBROUTINE MD_Mesh_WriteBack_NodePos(this, node_id, new_coords, status)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i8),           INTENT(IN)    :: node_id
    REAL(wp),              INTENT(IN)    :: new_coords(3)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. &
        node_id < 1_i8 .OR. node_id > INT(this%desc%nNodes, i8)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    this%node_state(node_id)%currentCoords = new_coords

  END SUBROUTINE MD_Mesh_WriteBack_NodePos

  !============================================================================
  ! MD_Mesh_WriteBack_NodeDisp - update node displacement (solution field u)
  ! Whitelist: mesh.currentNodeDisp -> node_state(i)%disp
  !============================================================================
  SUBROUTINE MD_Mesh_WriteBack_NodeDisp(this, node_id, new_disp, status)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i8),           INTENT(IN)    :: node_id
    REAL(wp),              INTENT(IN)    :: new_disp(3)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. &
        node_id < 1_i8 .OR. node_id > INT(this%desc%nNodes, i8)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    this%node_state(node_id)%disp = new_disp
  END SUBROUTINE MD_Mesh_WriteBack_NodeDisp

  !============================================================================
  ! MD_Mesh_WriteBack_NodeVel - update node velocity (mesh.currentNodeVel)
  !============================================================================
  SUBROUTINE MD_Mesh_WriteBack_NodeVel(this, node_id, new_vel, status)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i8),           INTENT(IN)    :: node_id
    REAL(wp),              INTENT(IN)    :: new_vel(3)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. &
        node_id < 1_i8 .OR. node_id > INT(this%desc%nNodes, i8)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    this%node_state(node_id)%vel = new_vel
  END SUBROUTINE MD_Mesh_WriteBack_NodeVel

  !============================================================================
  ! MD_Mesh_WriteBack_NodeAcc - update node acceleration (mesh.currentNodeAcc)
  !============================================================================
  SUBROUTINE MD_Mesh_WriteBack_NodeAcc(this, node_id, new_acc, status)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i8),           INTENT(IN)    :: node_id
    REAL(wp),              INTENT(IN)    :: new_acc(3)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. &
        node_id < 1_i8 .OR. node_id > INT(this%desc%nNodes, i8)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    this%node_state(node_id)%acc = new_acc
  END SUBROUTINE MD_Mesh_WriteBack_NodeAcc

  !============================================================================
  ! MD_Mesh_WriteBack_ElemStress_Idx - Index-style API (Phase B, >4 params -> Arg)
  !============================================================================
  SUBROUTINE MD_Mesh_WriteBack_ElemStress_Idx(elem_idx, arg, status)
    INTEGER(i4), INTENT(IN) :: elem_idx
    TYPE(MD_Mesh_WriteBack_ElemStress_Arg), INTENT(IN) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ASSOCIATE(dom => g_ufc_global%md_layer%mesh)
      CALL init_error_status(status)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Mesh domain not initialized"
        RETURN
      END IF
      IF (.NOT. ALLOCATED(dom%elem_state)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "elem_state not allocated"
        RETURN
      END IF
      IF (elem_idx < 1 .OR. elem_idx > SIZE(dom%elem_state)) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0)') "elem_idx out of range: ", elem_idx, " / ", SIZE(dom%elem_state)
        RETURN
      END IF
      IF (arg%ip_idx < 1 .OR. arg%ip_idx > dom%elem_state(elem_idx)%nIntPoints) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0)') "ip_idx out of range: ", arg%ip_idx, " / ", dom%elem_state(elem_idx)%nIntPoints
        RETURN
      END IF
      IF (.NOT. ALLOCATED(dom%elem_state(elem_idx)%ipStates)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "ipStates not allocated"
        RETURN
      END IF
      dom%elem_state(elem_idx)%ipStates(arg%ip_idx)%sigma(1:6) = arg%sigma(1:6)
      status%status_code = IF_STATUS_OK
    END ASSOCIATE
  END SUBROUTINE MD_Mesh_WriteBack_ElemStress_Idx

  !============================================================================
  ! MD_Mesh_WriteBack_ElemStress - update elem_state(elem_id)%ipStates(ip_id)%sigma
  ! Whitelist: mesh.elem_ip_stress -> elem_state%ipStates%sigma (? Output ?)
  !============================================================================
  SUBROUTINE MD_Mesh_WriteBack_ElemStress(this, elem_id, ip_id, sigma, status)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i8),           INTENT(IN)    :: elem_id
    INTEGER(i4),           INTENT(IN)    :: ip_id
    REAL(wp),              INTENT(IN)    :: sigma(6)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. elem_id < 1_i8 .OR. elem_id > INT(this%desc%nElems, i8)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (.NOT. ALLOCATED(this%elem_state)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (ip_id < 1_i4 .OR. ip_id > this%elem_state(elem_id)%nIntPoints) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (.NOT. ALLOCATED(this%elem_state(elem_id)%ipStates)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    this%elem_state(elem_id)%ipStates(ip_id)%sigma(1:6) = sigma(1:6)
  END SUBROUTINE MD_Mesh_WriteBack_ElemStress

  !============================================================================
  ! MD_Mesh_WriteBack_State
  ! Update mesh assembly state counter (nAssembled) via guarded API.
  !============================================================================
  SUBROUTINE MD_Mesh_WriteBack_State(this, n_assembled, status)
    CLASS(MD_Mesh_Domain), INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: n_assembled
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    this%state%nAssembled = n_assembled

  END SUBROUTINE MD_Mesh_WriteBack_State

  !============================================================================
  ! MD_Mesh_Domain_GetSurfaceByName
  ! Check if surface name exists in mesh; used for Interaction domain validation.
  ! Returns: found = .TRUE. if surface_name exists in mesh%desc%surface_names
  !============================================================================
  SUBROUTINE GetSurfaceByName(this, surface_name, found, status)
    CLASS(MD_Mesh_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),        INTENT(IN)  :: surface_name
    LOGICAL,                 INTENT(OUT) :: found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    found = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ! Check if surface exists in surface_names
    IF (ALLOCATED(this%desc%surface_names)) THEN
      DO i = 1, this%desc%n_surfaces
        IF (TRIM(this%desc%surface_names(i)) == TRIM(surface_name)) THEN
          found = .TRUE.
          EXIT
        END IF
      END DO
    END IF

    ! Also check node_set_names (surfaces can be defined on node sets)
    IF (.NOT. found .AND. ALLOCATED(this%desc%node_set_names)) THEN
      DO i = 1, this%desc%n_node_sets
        IF (TRIM(this%desc%node_set_names(i)) == TRIM(surface_name)) THEN
          found = .TRUE.
          EXIT
        END IF
      END DO
    END IF

    ! Also check elem_set_names (surfaces can be defined on element sets)
    IF (.NOT. found .AND. ALLOCATED(this%desc%elem_set_names)) THEN
      DO i = 1, this%desc%n_elem_sets
        IF (TRIM(this%desc%elem_set_names(i)) == TRIM(surface_name)) THEN
          found = .TRUE.
          EXIT
        END IF
      END DO
    END IF

  END SUBROUTINE GetSurfaceByName

  !============================================================================
  ! MD_Mesh_GetSurfaceByName_Idx - Index-style API (Phase B)
  !   Direct access to g_ufc_global%md_layer%mesh
  !============================================================================
  SUBROUTINE MD_Mesh_GetSurfaceByName_Idx(surface_name, arg, status)
    CHARACTER(LEN=*), INTENT(IN)    :: surface_name
    TYPE(MD_Mesh_GetSurfaceByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    arg%found = .FALSE.
    ASSOCIATE(dom => g_ufc_global%md_layer%mesh)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        RETURN
      END IF
      IF (ALLOCATED(dom%desc%surface_names)) THEN
        DO i = 1, dom%desc%n_surfaces
          IF (TRIM(dom%desc%surface_names(i)) == TRIM(surface_name)) THEN
            arg%found = .TRUE.
            status%status_code = IF_STATUS_OK
            RETURN
          END IF
        END DO
      END IF
      IF (.NOT. arg%found .AND. ALLOCATED(dom%desc%node_set_names)) THEN
        DO i = 1, dom%desc%n_node_sets
          IF (TRIM(dom%desc%node_set_names(i)) == TRIM(surface_name)) THEN
            arg%found = .TRUE.
            status%status_code = IF_STATUS_OK
            RETURN
          END IF
        END DO
      END IF
      IF (.NOT. arg%found .AND. ALLOCATED(dom%desc%elem_set_names)) THEN
        DO i = 1, dom%desc%n_elem_sets
          IF (TRIM(dom%desc%elem_set_names(i)) == TRIM(surface_name)) THEN
            arg%found = .TRUE.
            status%status_code = IF_STATUS_OK
            RETURN
          END IF
        END DO
      END IF
    END ASSOCIATE
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_GetSurfaceByName_Idx

  !============================================================================
  ! MD_Mesh_Domain_GetNodeByName
  ! Get node index by name (linear search)
  !============================================================================
  SUBROUTINE GetNodeByName(this, name, node_idx, found, status)
    CLASS(MD_Mesh_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),      INTENT(IN)  :: name
    INTEGER(i4),           INTENT(OUT) :: node_idx
    LOGICAL,               INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    node_idx = 0_i4
    found = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh domain not initialized"
      RETURN
    END IF

    DO i = 1, SIZE(this%node_desc)
      IF (TRIM(this%node_desc(i)%name) == TRIM(name)) THEN
        found = .TRUE.
        node_idx = i
        EXIT
      END IF
    END DO

    IF (found) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') "Node '", TRIM(name), "' not found"
    END IF

  END SUBROUTINE GetNodeByName

  !============================================================================
  ! MD_Mesh_GetNodeByName_Idx - Index-style API (Phase B)
  !   Direct access to g_ufc_global%md_layer%mesh
  !============================================================================
  SUBROUTINE MD_Mesh_GetNodeByName_Idx(name, arg, status)
    CHARACTER(LEN=*), INTENT(IN)    :: name
    TYPE(MD_Mesh_GetNodeByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    arg%node_idx = 0_i4
    arg%found = .FALSE.
    ASSOCIATE(dom => g_ufc_global%md_layer%mesh)
      IF (.NOT. dom%initialized) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Mesh domain not initialized"
        RETURN
      END IF
      DO i = 1, SIZE(dom%node_desc)
        IF (TRIM(dom%node_desc(i)%name) == TRIM(name)) THEN
          arg%found = .TRUE.
          arg%node_idx = i
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO
    END ASSOCIATE
    status%status_code = IF_STATUS_INVALID
    WRITE(status%message, '(A,A,A)') "Node '", TRIM(name), "' not found"
  END SUBROUTINE MD_Mesh_GetNodeByName_Idx

  !============================================================================
  ! MD_Mesh_Domain_GetSummary  [Arg wrapper]
  !============================================================================
  SUBROUTINE GetSummary(this, arg)
    CLASS(MD_Mesh_Domain),        INTENT(IN)    :: this
    TYPE(MD_Mesh_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL MD_Mesh_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE GetSummary

  SUBROUTINE MD_Mesh_GetSummary_Impl(this, summary, status)
    CLASS(MD_Mesh_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),    INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Mesh domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,L1)') &
      "Mesh Summary: Nodes=", this%desc%nNodes, &
      ", Elements=", this%desc%nElems, &
      ", DOF=", this%global_num%nTotalEq, &
      ", Active=", this%state%nAssembled, &
      ", nlgeom=", this%algo%stp%nlgeom

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Mesh_GetSummary_Impl

END MODULE MD_Mesh_Domain