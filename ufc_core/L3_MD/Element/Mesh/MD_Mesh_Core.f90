!===============================================================================
! MODULE:  MD_Mesh_Core
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Core
! BRIEF:   Mesh CRUD + topology queries — P0 Init/Build/Search operations.
!===============================================================================
MODULE MD_Mesh_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mesh_Def,  ONLY: MD_Mesh_Desc, MD_Mesh_State, MD_Mesh_FaceDesc, &
                           MD_Mesh_NodeDesc, MD_Mesh_ElemDesc, &
                           MD_MESH_MAX_SETS, MD_MESH_MAX_SET_LEN, &
                           MD_MESH_MAX_FACE_NODES
  IMPLICIT NONE
  PRIVATE

  ! --- CRUD ---
  PUBLIC :: MD_Mesh_Core_Init
  PUBLIC :: MD_Mesh_Core_Finalize
  PUBLIC :: MD_Mesh_Set_Nodes
  PUBLIC :: MD_Mesh_Set_Connectivity
  PUBLIC :: MD_Mesh_Get_Node_Coords
  PUBLIC :: MD_Mesh_Get_Elem_Conn
  PUBLIC :: MD_Mesh_Add_NodeSet
  PUBLIC :: MD_Mesh_Add_ElemSet
  PUBLIC :: MD_Mesh_Validate
  ! --- Topology queries ---
  PUBLIC :: MD_Mesh_Build_NodeToElem
  PUBLIC :: MD_Mesh_Get_Node_Elems
  PUBLIC :: MD_Mesh_Get_Elem_Neighbors
  PUBLIC :: MD_Mesh_Count_Orphan_Nodes

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Core_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize Desc and State to blank slate
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Core_Init(desc, state, status)
    TYPE(MD_Mesh_Desc),    INTENT(INOUT) :: desc
    TYPE(MD_Mesh_State),   INTENT(OUT)   :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    desc%pop%n_nodes    = 0
    desc%pop%n_elements = 0
    desc%cfg%ndim       = 3
    desc%max_nn     = 8
    desc%n_nodesets  = 0
    desc%n_elemsets  = 0
    NULLIFY(desc%coords)
    NULLIFY(desc%conn)
    NULLIFY(desc%elem_type)
    NULLIFY(desc%node_to_elem_ptr)
    NULLIFY(desc%node_to_elem_col)
    desc%topo_built = .FALSE.
    desc%n_faces = 0
    IF (ALLOCATED(desc%faces)) DEALLOCATE(desc%faces)

    state%nodes_loaded     = .FALSE.
    state%conn_loaded      = .FALSE.
    state%topo_built       = .FALSE.
    state%faces_built      = .FALSE.
    state%validated        = .FALSE.
    state%n_orphan_nodes   = 0
    state%n_degenerate     = 0
    state%n_boundary_faces = 0
    state%modification_gen = 0
    state%disp_loaded      = .FALSE.
    state%vel_loaded       = .FALSE.
    state%acc_loaded       = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Core_Init

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Core_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Release mesh resources and reset state
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Core_Finalize(desc, state, status)
    TYPE(MD_Mesh_Desc),    INTENT(INOUT) :: desc
    TYPE(MD_Mesh_State),   INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (ASSOCIATED(desc%coords))         DEALLOCATE(desc%coords)
    IF (ASSOCIATED(desc%conn))           DEALLOCATE(desc%conn)
    IF (ASSOCIATED(desc%elem_type))      DEALLOCATE(desc%elem_type)
    IF (ASSOCIATED(desc%node_to_elem_ptr)) DEALLOCATE(desc%node_to_elem_ptr)
    IF (ASSOCIATED(desc%node_to_elem_col)) DEALLOCATE(desc%node_to_elem_col)
    NULLIFY(desc%coords)
    NULLIFY(desc%conn)
    NULLIFY(desc%elem_type)
    NULLIFY(desc%node_to_elem_ptr)
    NULLIFY(desc%node_to_elem_col)
    IF (ALLOCATED(desc%faces)) DEALLOCATE(desc%faces)

    desc%pop%n_nodes    = 0
    desc%pop%n_elements = 0
    desc%n_faces    = 0
    desc%n_nodesets = 0
    desc%n_elemsets = 0
    desc%topo_built = .FALSE.

    state%validated   = .FALSE.
    state%topo_built  = .FALSE.
    state%faces_built = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Core_Finalize

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Set_Nodes
  ! PHASE:      P0
  ! PURPOSE:    Load nodal coordinates into Desc
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Set_Nodes(desc, n_nodes, ndim, coords, status)
    TYPE(MD_Mesh_Desc),   INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: n_nodes
    INTEGER(i4),           INTENT(IN)    :: ndim
    REAL(wp),              INTENT(IN)    :: coords(ndim, n_nodes)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (n_nodes <= 0 .OR. ndim <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (ASSOCIATED(desc%coords)) DEALLOCATE(desc%coords)
    ALLOCATE(desc%coords(ndim, n_nodes))
    desc%coords(:,:) = coords(:,:)
    desc%pop%n_nodes = n_nodes
    desc%cfg%ndim    = ndim

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Set_Nodes

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Set_Connectivity
  ! PHASE:      P0
  ! PURPOSE:    Load element connectivity and type arrays into Desc
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Set_Connectivity(desc, n_elements, max_nn, conn, elem_type, status)
    TYPE(MD_Mesh_Desc),   INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: n_elements
    INTEGER(i4),           INTENT(IN)    :: max_nn
    INTEGER(i4),           INTENT(IN)    :: conn(max_nn, n_elements)
    INTEGER(i4),           INTENT(IN)    :: elem_type(n_elements)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (n_elements <= 0 .OR. max_nn <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    IF (ASSOCIATED(desc%conn))      DEALLOCATE(desc%conn)
    IF (ASSOCIATED(desc%elem_type)) DEALLOCATE(desc%elem_type)
    ALLOCATE(desc%conn(max_nn, n_elements))
    ALLOCATE(desc%elem_type(n_elements))
    desc%conn(:,:)    = conn(:,:)
    desc%elem_type(:) = elem_type(:)
    desc%pop%n_elements = n_elements
    desc%max_nn     = max_nn

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Set_Connectivity

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Get_Node_Coords
  ! PHASE:      P0
  ! PURPOSE:    Query nodal coordinates by node ID
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Get_Node_Coords(desc, node_id, coords_out, status)
    TYPE(MD_Mesh_Desc),   INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(IN)  :: node_id
    REAL(wp),              INTENT(OUT) :: coords_out(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: d

    CALL init_error_status(status)
    coords_out = 0.0_wp

    IF (.NOT. ASSOCIATED(desc%coords)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (node_id < 1 .OR. node_id > desc%pop%n_nodes) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO d = 1, MIN(desc%cfg%ndim, 3)
      coords_out(d) = desc%coords(d, node_id)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Get_Node_Coords

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Get_Elem_Conn
  ! PHASE:      P0
  ! PURPOSE:    Query element connectivity by element ID
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Get_Elem_Conn(desc, elem_id, nn, conn_out, status)
    TYPE(MD_Mesh_Desc),   INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(IN)  :: elem_id
    INTEGER(i4),           INTENT(OUT) :: nn
    INTEGER(i4),           INTENT(OUT) :: conn_out(desc%max_nn)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    nn = 0
    conn_out = 0

    IF (.NOT. ASSOCIATED(desc%conn)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (elem_id < 1 .OR. elem_id > desc%pop%n_elements) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    nn = desc%max_nn
    conn_out(1:nn) = desc%conn(1:nn, elem_id)

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Get_Elem_Conn

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Add_NodeSet
  ! PHASE:      P0
  ! PURPOSE:    Register a node set in Desc
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Add_NodeSet(desc, set_id, node_ids, n_nodes, status)
    TYPE(MD_Mesh_Desc),   INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: set_id
    INTEGER(i4),           INTENT(IN)    :: node_ids(:)
    INTEGER(i4),           INTENT(IN)    :: n_nodes
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idx, nn

    CALL init_error_status(status)

    IF (set_id <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (desc%n_nodesets >= MD_MESH_MAX_SETS) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    desc%n_nodesets = desc%n_nodesets + 1
    idx = desc%n_nodesets
    nn  = MIN(n_nodes, MD_MESH_MAX_SET_LEN)

    desc%nodesets(idx)%set_id          = set_id
    desc%nodesets(idx)%pop%n_nodes         = nn
    desc%nodesets(idx)%node_ids(1:nn)  = node_ids(1:nn)
    desc%nodesets(idx)%valid           = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Add_NodeSet

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Add_ElemSet
  ! PHASE:      P0
  ! PURPOSE:    Register an element set in Desc
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Add_ElemSet(desc, set_id, elem_ids, n_elems, status)
    TYPE(MD_Mesh_Desc),   INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: set_id
    INTEGER(i4),           INTENT(IN)    :: elem_ids(:)
    INTEGER(i4),           INTENT(IN)    :: n_elems
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: idx, ne

    CALL init_error_status(status)

    IF (set_id <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (desc%n_elemsets >= MD_MESH_MAX_SETS) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    desc%n_elemsets = desc%n_elemsets + 1
    idx = desc%n_elemsets
    ne  = MIN(n_elems, MD_MESH_MAX_SET_LEN)

    desc%elemsets(idx)%set_id          = set_id
    desc%elemsets(idx)%n_elems         = ne
    desc%elemsets(idx)%elem_ids(1:ne)  = elem_ids(1:ne)
    desc%elemsets(idx)%valid           = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Add_ElemSet

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Validate
  ! PHASE:      P0
  ! PURPOSE:    Validate mesh has nodes, elements, and allocated coords
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Validate(desc, status)
    TYPE(MD_Mesh_Desc),   INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (desc%pop%n_nodes <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (desc%pop%n_elements <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (.NOT. ASSOCIATED(desc%coords)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Validate

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Build_NodeToElem
  ! PHASE:      P0
  ! PURPOSE:    Build CSR node-to-element adjacency structure
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Build_NodeToElem(desc, state, status)
    TYPE(MD_Mesh_Desc),    INTENT(INOUT) :: desc
    TYPE(MD_Mesh_State),   INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: ie, jn, nid, nn
    INTEGER(i4), ALLOCATABLE :: count(:)

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(desc%conn) .OR. desc%pop%n_nodes <= 0 .OR. &
        desc%pop%n_elements <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ! Free old adjacency
    IF (ASSOCIATED(desc%node_to_elem_ptr)) DEALLOCATE(desc%node_to_elem_ptr)
    IF (ASSOCIATED(desc%node_to_elem_col)) DEALLOCATE(desc%node_to_elem_col)

    ALLOCATE(count(desc%pop%n_nodes))
    count = 0
    nn = desc%max_nn

    ! Pass 1: count entries per node
    DO ie = 1, desc%pop%n_elements
      DO jn = 1, nn
        nid = desc%conn(jn, ie)
        IF (nid >= 1 .AND. nid <= desc%pop%n_nodes) count(nid) = count(nid) + 1
      END DO
    END DO

    ! Build CSR row pointers
    ALLOCATE(desc%node_to_elem_ptr(desc%pop%n_nodes + 1))
    desc%node_to_elem_ptr(1) = 1
    DO jn = 1, desc%pop%n_nodes
      desc%node_to_elem_ptr(jn + 1) = desc%node_to_elem_ptr(jn) + count(jn)
    END DO

    ! Pass 2: fill column indices
    ALLOCATE(desc%node_to_elem_col(desc%node_to_elem_ptr(desc%pop%n_nodes + 1) - 1))
    count = 0
    DO ie = 1, desc%pop%n_elements
      DO jn = 1, nn
        nid = desc%conn(jn, ie)
        IF (nid >= 1 .AND. nid <= desc%pop%n_nodes) THEN
          count(nid) = count(nid) + 1
          desc%node_to_elem_col(desc%node_to_elem_ptr(nid) + count(nid) - 1) = ie
        END IF
      END DO
    END DO

    DEALLOCATE(count)
    desc%topo_built = .TRUE.
    state%topo_built = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Build_NodeToElem

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Get_Node_Elems
  ! PHASE:      P0
  ! PURPOSE:    Query elements sharing a given node
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Get_Node_Elems(desc, node_id, elem_ids, n_elems, status)
    TYPE(MD_Mesh_Desc),   INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(IN)  :: node_id
    INTEGER(i4),           INTENT(OUT) :: elem_ids(:)
    INTEGER(i4),           INTENT(OUT) :: n_elems
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: istart, iend, k

    CALL init_error_status(status)
    n_elems = 0
    elem_ids = 0

    IF (.NOT. desc%topo_built .OR. .NOT. ASSOCIATED(desc%node_to_elem_ptr)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (node_id < 1 .OR. node_id > desc%pop%n_nodes) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    istart = desc%node_to_elem_ptr(node_id)
    iend   = desc%node_to_elem_ptr(node_id + 1) - 1
    n_elems = iend - istart + 1
    n_elems = MIN(n_elems, SIZE(elem_ids))
    DO k = 1, n_elems
      elem_ids(k) = desc%node_to_elem_col(istart + k - 1)
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Get_Node_Elems

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Get_Elem_Neighbors
  ! PHASE:      P0
  ! PURPOSE:    Find elements sharing nodes with given element
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Get_Elem_Neighbors(desc, elem_id, nbr_ids, n_nbrs, status)
    TYPE(MD_Mesh_Desc),   INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(IN)  :: elem_id
    INTEGER(i4),           INTENT(OUT) :: nbr_ids(:)
    INTEGER(i4),           INTENT(OUT) :: n_nbrs
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: jn, nid, istart, iend, k, eid
    LOGICAL :: already

    CALL init_error_status(status)
    n_nbrs = 0
    nbr_ids = 0

    IF (.NOT. desc%topo_built .OR. .NOT. ASSOCIATED(desc%conn)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (elem_id < 1 .OR. elem_id > desc%pop%n_elements) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO jn = 1, desc%max_nn
      nid = desc%conn(jn, elem_id)
      IF (nid < 1 .OR. nid > desc%pop%n_nodes) CYCLE
      istart = desc%node_to_elem_ptr(nid)
      iend   = desc%node_to_elem_ptr(nid + 1) - 1
      DO k = istart, iend
        eid = desc%node_to_elem_col(k)
        IF (eid == elem_id) CYCLE
        ! Check not already added
        already = .FALSE.
        BLOCK
          INTEGER(i4) :: m
          DO m = 1, n_nbrs
            IF (nbr_ids(m) == eid) THEN
              already = .TRUE.
              EXIT
            END IF
          END DO
        END BLOCK
        IF (.NOT. already .AND. n_nbrs < SIZE(nbr_ids)) THEN
          n_nbrs = n_nbrs + 1
          nbr_ids(n_nbrs) = eid
        END IF
      END DO
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Get_Elem_Neighbors

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Mesh_Count_Orphan_Nodes
  ! PHASE:      P0
  ! PURPOSE:    Count nodes not referenced by any element
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Mesh_Count_Orphan_Nodes(desc, n_orphans, status)
    TYPE(MD_Mesh_Desc),   INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(OUT) :: n_orphans
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i
    LOGICAL, ALLOCATABLE :: referenced(:)

    CALL init_error_status(status)
    n_orphans = 0

    IF (.NOT. ASSOCIATED(desc%conn) .OR. desc%pop%n_nodes <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ALLOCATE(referenced(desc%pop%n_nodes))
    referenced = .FALSE.
    DO i = 1, desc%pop%n_elements
      BLOCK
        INTEGER(i4) :: jn, nid
        DO jn = 1, desc%max_nn
          nid = desc%conn(jn, i)
          IF (nid >= 1 .AND. nid <= desc%pop%n_nodes) referenced(nid) = .TRUE.
        END DO
      END BLOCK
    END DO

    DO i = 1, desc%pop%n_nodes
      IF (.NOT. referenced(i)) n_orphans = n_orphans + 1
    END DO
    DEALLOCATE(referenced)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Count_Orphan_Nodes

END MODULE MD_Mesh_Core
