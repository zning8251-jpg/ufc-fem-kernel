!===============================================================================
! MODULE:  MD_Mesh_Topo
! LAYER:   L3_MD
! DOMAIN:  Mesh
! ROLE:    _Impl
! BRIEF:   Topology analysis — P1 BuildTopology: face extraction,
!          boundary detection, connectivity validation.
!===============================================================================
MODULE MD_Mesh_Topo
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mesh_Def, ONLY: MD_Mesh_Desc, MD_Mesh_State, MD_Mesh_FaceDesc, &
                          MD_MESH_MAX_FACE_NODES
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mesh_Topo_Build_Faces
  PUBLIC :: MD_Mesh_Topo_Find_Boundary_Faces
  PUBLIC :: MD_Mesh_Topo_Validate_Connectivity
  PUBLIC :: MD_Mesh_Topo_Get_Elem_Faces

CONTAINS

  !====================================================================
  ! MD_Mesh_Topo_Build_Faces — extract all element faces into desc%faces
  !
  ! For hex elements (max_nn=8): 6 faces of 4 nodes each.
  ! For tet elements (max_nn=4): 4 faces of 3 nodes each.
  ! Generic: builds face table from sorted node tuples.
  !====================================================================
  SUBROUTINE MD_Mesh_Topo_Build_Faces(desc, state, status)
    TYPE(MD_Mesh_Desc),    INTENT(INOUT) :: desc
    TYPE(MD_Mesh_State),   INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: ie, iface, nlocal, fid
    INTEGER(i4) :: face_nodes_local(MD_MESH_MAX_FACE_NODES)
    INTEGER(i4) :: est_faces

    CALL init_error_status(status)

    IF (.NOT. ASSOCIATED(desc%conn) .OR. desc%pop%n_elements <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ! Estimate face count: hex → 6 faces/elem, tet → 4
    est_faces = desc%pop%n_elements * 6
    IF (ALLOCATED(desc%faces)) DEALLOCATE(desc%faces)
    ALLOCATE(desc%faces(est_faces))
    desc%n_faces = 0

    DO ie = 1, desc%pop%n_elements
      SELECT CASE (desc%max_nn)
      CASE (8)  ! Hex8: 6 quad faces
        CALL add_hex_faces(desc, ie, fid)
      CASE (4)  ! Tet4: 4 tri faces
        CALL add_tet_faces(desc, ie, fid)
      CASE DEFAULT
        ! Generic: treat all nodes as a single face (degenerate for non-standard)
        nlocal = MIN(desc%max_nn, MD_MESH_MAX_FACE_NODES)
        face_nodes_local(1:nlocal) = desc%conn(1:nlocal, ie)
        CALL append_face(desc, ie, 1, face_nodes_local, nlocal)
      END SELECT
    END DO

    state%faces_built = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Topo_Build_Faces

  !====================================================================
  ! MD_Mesh_Topo_Find_Boundary_Faces — mark faces appearing only once
  !   (boundary faces are not shared between two elements)
  !====================================================================
  SUBROUTINE MD_Mesh_Topo_Find_Boundary_Faces(desc, state, status)
    TYPE(MD_Mesh_Desc),    INTENT(INOUT) :: desc
    TYPE(MD_Mesh_State),   INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: i, j, nbf
    LOGICAL :: shared

    CALL init_error_status(status)

    IF (.NOT. state%faces_built .OR. .NOT. ALLOCATED(desc%faces) .OR. &
        desc%n_faces <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    nbf = 0
    DO i = 1, desc%n_faces
      shared = .FALSE.
      DO j = 1, desc%n_faces
        IF (j == i) CYCLE
        IF (faces_match(desc%faces(i), desc%faces(j))) THEN
          shared = .TRUE.
          EXIT
        END IF
      END DO
      desc%faces(i)%is_boundary = .NOT. shared
      IF (.NOT. shared) nbf = nbf + 1
    END DO

    state%n_boundary_faces = nbf
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Topo_Find_Boundary_Faces

  !====================================================================
  ! MD_Mesh_Topo_Validate_Connectivity — check connectivity integrity
  !====================================================================
  SUBROUTINE MD_Mesh_Topo_Validate_Connectivity(desc, n_degenerate, status)
    TYPE(MD_Mesh_Desc),   INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(OUT) :: n_degenerate
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: ie, jn, nid

    CALL init_error_status(status)
    n_degenerate = 0

    IF (.NOT. ASSOCIATED(desc%conn)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO ie = 1, desc%pop%n_elements
      ! Check for invalid node references
      DO jn = 1, desc%max_nn
        nid = desc%conn(jn, ie)
        IF (nid < 0 .OR. nid > desc%pop%n_nodes) THEN
          n_degenerate = n_degenerate + 1
          EXIT
        END IF
      END DO
      ! Check for duplicate nodes within an element
      BLOCK
        INTEGER(i4) :: k1, k2
        DO k1 = 1, desc%max_nn - 1
          IF (desc%conn(k1, ie) == 0) CYCLE
          DO k2 = k1 + 1, desc%max_nn
            IF (desc%conn(k2, ie) == 0) CYCLE
            IF (desc%conn(k1, ie) == desc%conn(k2, ie)) THEN
              n_degenerate = n_degenerate + 1
              EXIT
            END IF
          END DO
        END DO
      END BLOCK
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Topo_Validate_Connectivity

  !====================================================================
  ! MD_Mesh_Topo_Get_Elem_Faces — get faces belonging to a single element
  !====================================================================
  SUBROUTINE MD_Mesh_Topo_Get_Elem_Faces(desc, elem_id, face_ids, n_faces, status)
    TYPE(MD_Mesh_Desc),   INTENT(IN)  :: desc
    INTEGER(i4),           INTENT(IN)  :: elem_id
    INTEGER(i4),           INTENT(OUT) :: face_ids(:)
    INTEGER(i4),           INTENT(OUT) :: n_faces
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    n_faces = 0
    face_ids = 0

    IF (.NOT. ALLOCATED(desc%faces) .OR. desc%n_faces <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (elem_id < 1 .OR. elem_id > desc%pop%n_elements) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    DO i = 1, desc%n_faces
      IF (desc%faces(i)%elem_id == elem_id) THEN
        IF (n_faces < SIZE(face_ids)) THEN
          n_faces = n_faces + 1
          face_ids(n_faces) = i
        END IF
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mesh_Topo_Get_Elem_Faces

  !====================================================================
  ! PRIVATE helpers
  !====================================================================

  SUBROUTINE append_face(desc, elem_id, local_id, nodes, nn)
    TYPE(MD_Mesh_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),         INTENT(IN)    :: elem_id, local_id, nn
    INTEGER(i4),         INTENT(IN)    :: nodes(MD_MESH_MAX_FACE_NODES)

    TYPE(MD_Mesh_FaceDesc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: new_cap

    ! Grow if needed
    IF (.NOT. ALLOCATED(desc%faces)) THEN
      ALLOCATE(desc%faces(256))
    ELSE IF (desc%n_faces >= SIZE(desc%faces)) THEN
      new_cap = SIZE(desc%faces) * 2
      ALLOCATE(tmp(new_cap))
      tmp(1:desc%n_faces) = desc%faces(1:desc%n_faces)
      CALL MOVE_ALLOC(tmp, desc%faces)
    END IF

    desc%n_faces = desc%n_faces + 1
    desc%faces(desc%n_faces)%face_id       = desc%n_faces
    desc%faces(desc%n_faces)%elem_id       = elem_id
    desc%faces(desc%n_faces)%local_face_id = local_id
    desc%faces(desc%n_faces)%n_face_nodes  = nn
    desc%faces(desc%n_faces)%face_nodes    = 0
    desc%faces(desc%n_faces)%face_nodes(1:nn) = nodes(1:nn)
    desc%faces(desc%n_faces)%is_boundary   = .FALSE.
  END SUBROUTINE append_face

  SUBROUTINE add_hex_faces(desc, ie, fid_out)
    TYPE(MD_Mesh_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),         INTENT(IN)    :: ie
    INTEGER(i4),         INTENT(OUT)   :: fid_out

    INTEGER(i4) :: fn(MD_MESH_MAX_FACE_NODES)
    INTEGER(i4) :: c(8)

    c = desc%conn(1:8, ie)
    fn = 0

    ! Face 1: bottom (1,2,3,4)
    fn(1:4) = (/ c(1), c(2), c(3), c(4) /)
    CALL append_face(desc, ie, 1, fn, 4)
    ! Face 2: top (5,6,7,8)
    fn(1:4) = (/ c(5), c(6), c(7), c(8) /)
    CALL append_face(desc, ie, 2, fn, 4)
    ! Face 3: front (1,2,6,5)
    fn(1:4) = (/ c(1), c(2), c(6), c(5) /)
    CALL append_face(desc, ie, 3, fn, 4)
    ! Face 4: right (2,3,7,6)
    fn(1:4) = (/ c(2), c(3), c(7), c(6) /)
    CALL append_face(desc, ie, 4, fn, 4)
    ! Face 5: back (3,4,8,7)
    fn(1:4) = (/ c(3), c(4), c(8), c(7) /)
    CALL append_face(desc, ie, 5, fn, 4)
    ! Face 6: left (4,1,5,8)
    fn(1:4) = (/ c(4), c(1), c(5), c(8) /)
    CALL append_face(desc, ie, 6, fn, 4)

    fid_out = desc%n_faces
  END SUBROUTINE add_hex_faces

  SUBROUTINE add_tet_faces(desc, ie, fid_out)
    TYPE(MD_Mesh_Desc), INTENT(INOUT) :: desc
    INTEGER(i4),         INTENT(IN)    :: ie
    INTEGER(i4),         INTENT(OUT)   :: fid_out

    INTEGER(i4) :: fn(MD_MESH_MAX_FACE_NODES)
    INTEGER(i4) :: c(4)

    c = desc%conn(1:4, ie)
    fn = 0

    ! Face 1: (1,2,3)
    fn(1:3) = (/ c(1), c(2), c(3) /)
    CALL append_face(desc, ie, 1, fn, 3)
    ! Face 2: (1,2,4)
    fn(1:3) = (/ c(1), c(2), c(4) /)
    CALL append_face(desc, ie, 2, fn, 3)
    ! Face 3: (2,3,4)
    fn(1:3) = (/ c(2), c(3), c(4) /)
    CALL append_face(desc, ie, 3, fn, 3)
    ! Face 4: (1,3,4)
    fn(1:3) = (/ c(1), c(3), c(4) /)
    CALL append_face(desc, ie, 4, fn, 3)

    fid_out = desc%n_faces
  END SUBROUTINE add_tet_faces

  PURE LOGICAL FUNCTION faces_match(f1, f2) RESULT(match)
    TYPE(MD_Mesh_FaceDesc), INTENT(IN) :: f1, f2

    INTEGER(i4) :: i, j, n1, n2, found_count

    match = .FALSE.
    n1 = f1%n_face_nodes
    n2 = f2%n_face_nodes
    IF (n1 /= n2 .OR. n1 <= 0) RETURN

    ! Match if same set of nodes (order-independent)
    found_count = 0
    DO i = 1, n1
      DO j = 1, n2
        IF (f1%face_nodes(i) == f2%face_nodes(j) .AND. &
            f1%face_nodes(i) /= 0) THEN
          found_count = found_count + 1
          EXIT
        END IF
      END DO
    END DO
    match = (found_count == n1)
  END FUNCTION faces_match

END MODULE MD_Mesh_Topo
