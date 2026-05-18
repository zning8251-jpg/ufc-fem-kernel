!======================================================================
! MODULE:  MD_Int_Manager
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Mgr
! BRIEF:   Surface management and contact initialisation.
!          Surface init, add-nodes, build-segments/topology,
!          normals, bbox, coord-update, validation, contact_init,
!          contact_update_geometry, face evaluation, user callbacks.
!          Extracted from original MD_Int_API monolith.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================
MODULE MD_Int_Manager
    USE MD_Int_Types
    USE MD_Int_Query, ONLY: contact_find_Elem_index, &
                            contact_find_node_index_in_part, &
                            contact_find_node_state_index, &
                            contact_get_node_coord_curr, &
                            contact_dot3
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE

    !==================================================================
    ! PUBLIC procedure interfaces (actual SUBROUTINE names)
    !==================================================================
    ! Surface management
    PUBLIC :: Cont_Surface_init, Cont_Surface_add_nodes
    PUBLIC :: Co_Su_bu_se_2d, Co_Su_bu_se_3d
    PUBLIC :: Co_Su_up_coords
    PUBLIC :: Co_Su_Co_no_2d, Co_Su_Co_no_3d
    PUBLIC :: Cont_Surface_Compute_bbox, Co_Su_Co_bb_internal
    PUBLIC :: Co_Su_bu_topology, Cont_Surface_Valid
    ! Contact init / geometry update
    PUBLIC :: contact_init, contact_init_Arg, contact_init_from_pair
    PUBLIC :: contact_update_geometry, contact_update_geometry_Arg
    ! Assembly helpers (model-level)
    PUBLIC :: co_de_gl_su_id
    PUBLIC :: co_co_su_nodes
    PUBLIC :: co_co_fa_no_area
    PUBLIC :: contact_Eval_face_gap, contact_Eval_face_gap_Arg
    ! User callbacks
    PUBLIC :: uinter_call, ucontprop_call
    PUBLIC :: user_contact_init, user_contact_Reg
    PUBLIC :: fric_call, vfric_call

    !==================================================================
    ! INTERFACE alias blocks  (PUBLIC name -> actual SUBROUTINE name)
    !==================================================================
    INTERFACE Cont_Surface_build_segments_2d
        MODULE PROCEDURE Co_Su_bu_se_2d
    END INTERFACE
    PUBLIC :: Cont_Surface_build_segments_2d

    INTERFACE Cont_Surface_build_segments_3d
        MODULE PROCEDURE Co_Su_bu_se_3d
    END INTERFACE
    PUBLIC :: Cont_Surface_build_segments_3d

    INTERFACE Cont_Surface_update_coords
        MODULE PROCEDURE Co_Su_up_coords
    END INTERFACE
    PUBLIC :: Cont_Surface_update_coords

    INTERFACE Cont_Surface_Compute_normals_2d
        MODULE PROCEDURE Co_Su_Co_no_2d
    END INTERFACE
    PUBLIC :: Cont_Surface_Compute_normals_2d

    INTERFACE Cont_Surface_Compute_normals_3d
        MODULE PROCEDURE Co_Su_Co_no_3d
    END INTERFACE
    PUBLIC :: Cont_Surface_Compute_normals_3d

    INTERFACE Cont_Surface_Compute_bbox_internal
        MODULE PROCEDURE Co_Su_Co_bb_internal
    END INTERFACE
    PUBLIC :: Cont_Surface_Compute_bbox_internal

    INTERFACE Cont_Surface_build_topology
        MODULE PROCEDURE Co_Su_bu_topology
    END INTERFACE
    PUBLIC :: Cont_Surface_build_topology

    INTERFACE contact_decode_global_surf_id
        MODULE PROCEDURE co_de_gl_su_id
    END INTERFACE
    PUBLIC :: contact_decode_global_surf_id

    INTERFACE contact_collect_surface_nodes
        MODULE PROCEDURE co_co_su_nodes
    END INTERFACE
    PUBLIC :: contact_collect_surface_nodes

    INTERFACE contact_compute_face_normal_area
        MODULE PROCEDURE co_co_fa_no_area
    END INTERFACE
    PUBLIC :: contact_compute_face_normal_area

    INTERFACE contact_Evaluate_face_gap
        MODULE PROCEDURE contact_Eval_face_gap
    END INTERFACE
    PUBLIC :: contact_Evaluate_face_gap

CONTAINS

    !===================================================================
    ! Cont_Surface_init
    !===================================================================
    SUBROUTINE Cont_Surface_init(surf, id, n_nodes, n_segs, is_master, coord_type)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        INTEGER(i4), INTENT(IN) :: id
        INTEGER(i4), INTENT(IN) :: n_nodes
        INTEGER(i4), INTENT(IN) :: n_segs
        LOGICAL, INTENT(IN), OPTIONAL :: is_master
        INTEGER(i4), INTENT(IN), OPTIONAL :: coord_type
        INTEGER(i4) :: i

        surf%cfg%id = id
        surf%pop%n_nodes = n_nodes
        surf%n_segments = n_segs

        IF (PRESENT(is_master)) surf%is_master = is_master
        IF (PRESENT(coord_type)) surf%coord_type = coord_type

        IF (ALLOCATED(surf%node_ids)) DEALLOCATE(surf%node_ids)
        IF (ALLOCATED(surf%coords)) DEALLOCATE(surf%coords)
        IF (ALLOCATED(surf%coords_current)) DEALLOCATE(surf%coords_current)
        IF (ALLOCATED(surf%segments)) DEALLOCATE(surf%segments)

        ALLOCATE(surf%node_ids(n_nodes))
        ALLOCATE(surf%coords(3, n_nodes))
        ALLOCATE(surf%coords_current(3, n_nodes))
        ALLOCATE(surf%segments(n_segs))

        surf%node_ids = 0
        surf%coords = 0.0_wp
        surf%coords_current = 0.0_wp

        DO i = 1, n_segs
            surf%segments(i)%cfg%id = i
            surf%segments(i)%surface_id = id
        END DO
    END SUBROUTINE

    !===================================================================
    ! Cont_Surface_add_nodes
    !===================================================================
    SUBROUTINE Cont_Surface_add_nodes(surf, global_node_ids, X, Y, Z, n_nodes)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        INTEGER(i4), INTENT(IN) :: global_node_ids(:)
        REAL(wp), INTENT(IN) :: X(:), Y(:), Z(:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        INTEGER(i4) :: k, node

        IF (n_nodes > surf%pop%n_nodes) RETURN

        DO k = 1, n_nodes
            node = global_node_ids(k)
            surf%node_ids(k) = node

            IF (node > 0 .AND. node <= SIZE(X)) THEN
                surf%coords(1, k) = X(node)
                surf%coords(2, k) = Y(node)
                surf%coords(3, k) = Z(node)
                surf%coords_current(:, k) = surf%coords(:, k)
            END IF
        END DO

        IF (n_nodes >= 2) THEN
            surf%is_closed = (surf%node_ids(1) == surf%node_ids(n_nodes))
        END IF
    END SUBROUTINE

    !===================================================================
    ! Co_Su_bu_se_2d  (PUBLIC: Cont_Surface_build_segments_2d)
    !===================================================================
    SUBROUTINE Co_Su_bu_se_2d(surf)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        INTEGER(i4) :: j, na, nb, n_eff

        n_eff = surf%pop%n_nodes
        IF (surf%is_closed) n_eff = surf%pop%n_nodes - 1

        DO j = 1, surf%n_segments
            na = j
            nb = j + 1
            IF (nb > surf%pop%n_nodes) nb = 1

            surf%segments(j)%pop%n_nodes = 2
            surf%segments(j)%nodes(1) = na
            surf%segments(j)%nodes(2) = nb
            surf%segments(j)%state = CSTATE_INITIAL
        END DO
    END SUBROUTINE

    !===================================================================
    ! Co_Su_bu_se_3d  (PUBLIC: Cont_Surface_build_segments_3d)
    !===================================================================
    SUBROUTINE Co_Su_bu_se_3d(surf, conn, n_segs)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        INTEGER(i4), INTENT(IN) :: conn(:,:)
        INTEGER(i4), INTENT(IN) :: n_segs
        INTEGER(i4) :: j, l

        DO j = 1, MIN(n_segs, surf%n_segments)
            surf%segments(j)%pop%n_nodes = 4
            DO l = 1, 4
                surf%segments(j)%nodes(l) = conn(l, j)
            END DO
            surf%segments(j)%state = CSTATE_INITIAL
        END DO
    END SUBROUTINE

    !===================================================================
    ! Co_Su_up_coords  (PUBLIC: Cont_Surface_update_coords)
    !===================================================================
    SUBROUTINE Co_Su_up_coords(surf, disp, dof_map, ndof)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        REAL(wp), INTENT(IN) :: disp(:)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        INTEGER(i4), INTENT(IN) :: ndof
        INTEGER(i4) :: k, l, kdof, node
        REAL(wp) :: dx

        DO k = 1, surf%pop%n_nodes
            node = surf%node_ids(k)
            surf%coords_current(:, k) = surf%coords(:, k)

            DO l = 1, MIN(ndof, 3)
                IF (node > 0 .AND. node <= SIZE(dof_map, 2)) THEN
                    kdof = dof_map(l, node)
                ELSE
                    kdof = 0
                END IF

                IF (kdof > 0 .AND. kdof <= SIZE(disp)) THEN
                    dx = disp(kdof)
                    surf%coords_current(l, k) = surf%coords_current(l, k) + dx
                END IF
            END DO
        END DO
    END SUBROUTINE

    !===================================================================
    ! Co_Su_Co_no_2d  (PUBLIC: Cont_Surface_Compute_normals_2d)
    !===================================================================
    SUBROUTINE Co_Su_Co_no_2d(surf)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        INTEGER(i4) :: j, na, nb
        REAL(wp) :: dy, dz, length
        REAL(wp), PARAMETER :: tol = 1.0E-30_wp

        DO j = 1, surf%n_segments
            na = surf%segments(j)%nodes(1)
            nb = surf%segments(j)%nodes(2)

            dy = surf%coords_current(2, nb) - surf%coords_current(2, na)
            dz = surf%coords_current(3, nb) - surf%coords_current(3, na)

            length = SQRT(dy*dy + dz*dz)
            surf%segments(j)%length = length

            IF (length > tol) THEN
                surf%segments(j)%tangent(1) = 0.0_wp
                surf%segments(j)%tangent(2) = dy / length
                surf%segments(j)%tangent(3) = dz / length
                surf%segments(j)%normal(1) = 0.0_wp
                surf%segments(j)%normal(2) = -dz / length
                surf%segments(j)%normal(3) = dy / length
            ELSE
                surf%segments(j)%tangent = 0.0_wp
                surf%segments(j)%normal = 0.0_wp
            END IF

            surf%segments(j)%centroid(1) = 0.0_wp
            surf%segments(j)%centroid(2) = 0.5_wp * (surf%coords_current(2, na) + surf%coords_current(2, nb))
            surf%segments(j)%centroid(3) = 0.5_wp * (surf%coords_current(3, na) + surf%coords_current(3, nb))
        END DO
    END SUBROUTINE

    !===================================================================
    ! Co_Su_Co_no_3d  (PUBLIC: Cont_Surface_Compute_normals_3d)
    !===================================================================
    SUBROUTINE Co_Su_Co_no_3d(surf)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        INTEGER(i4) :: j, n1, n2, n3, n4
        REAL(wp) :: rx, ry, rz, sx, sy, sz
        REAL(wp) :: vx, vy, vz, vmag
        REAL(wp), PARAMETER :: tol = 1.0E-30_wp

        DO j = 1, surf%n_segments
            n1 = surf%segments(j)%nodes(1)
            n2 = surf%segments(j)%nodes(2)
            n3 = surf%segments(j)%nodes(3)
            n4 = surf%segments(j)%nodes(4)

            rx = surf%coords_current(1, n3) - surf%coords_current(1, n1)
            ry = surf%coords_current(2, n3) - surf%coords_current(2, n1)
            rz = surf%coords_current(3, n3) - surf%coords_current(3, n1)
            sx = surf%coords_current(1, n4) - surf%coords_current(1, n2)
            sy = surf%coords_current(2, n4) - surf%coords_current(2, n2)
            sz = surf%coords_current(3, n4) - surf%coords_current(3, n2)

            vx = ry*sz - rz*sy
            vy = rz*sx - rx*sz
            vz = rx*sy - ry*sx

            vmag = SQRT(vx*vx + vy*vy + vz*vz)

            IF (vmag > tol) THEN
                surf%segments(j)%normal(1) = vx / vmag
                surf%segments(j)%normal(2) = vy / vmag
                surf%segments(j)%normal(3) = vz / vmag
                surf%segments(j)%length = 0.5_wp * vmag
            ELSE
                surf%segments(j)%normal = 0.0_wp
                surf%segments(j)%length = 0.0_wp
            END IF

            surf%segments(j)%centroid(1) = 0.25_wp * ( &
                surf%coords_current(1, n1) + surf%coords_current(1, n2) + &
                surf%coords_current(1, n3) + surf%coords_current(1, n4))
            surf%segments(j)%centroid(2) = 0.25_wp * ( &
                surf%coords_current(2, n1) + surf%coords_current(2, n2) + &
                surf%coords_current(2, n3) + surf%coords_current(2, n4))
            surf%segments(j)%centroid(3) = 0.25_wp * ( &
                surf%coords_current(3, n1) + surf%coords_current(3, n2) + &
                surf%coords_current(3, n3) + surf%coords_current(3, n4))
        END DO
    END SUBROUTINE

    !===================================================================
    ! Cont_Surface_Compute_bbox
    !===================================================================
    SUBROUTINE Cont_Surface_Compute_bbox(surf, tolerance)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        REAL(wp), INTENT(IN), OPTIONAL :: tolerance
        INTEGER(i4) :: k
        REAL(wp) :: tol

        tol = 0.0_wp
        IF (PRESENT(tolerance)) tol = tolerance

        IF (surf%pop%n_nodes > 0) THEN
            surf%bbox_min = surf%coords_current(:, 1)
            surf%bbox_max = surf%coords_current(:, 1)
        END IF

        DO k = 2, surf%pop%n_nodes
            surf%bbox_min(1) = MIN(surf%bbox_min(1), surf%coords_current(1, k))
            surf%bbox_min(2) = MIN(surf%bbox_min(2), surf%coords_current(2, k))
            surf%bbox_min(3) = MIN(surf%bbox_min(3), surf%coords_current(3, k))
            surf%bbox_max(1) = MAX(surf%bbox_max(1), surf%coords_current(1, k))
            surf%bbox_max(2) = MAX(surf%bbox_max(2), surf%coords_current(2, k))
            surf%bbox_max(3) = MAX(surf%bbox_max(3), surf%coords_current(3, k))
        END DO

        surf%bbox_min = surf%bbox_min - tol
        surf%bbox_max = surf%bbox_max + tol
    END SUBROUTINE

    !===================================================================
    ! Co_Su_Co_bb_internal  (PUBLIC: Cont_Surface_Compute_bbox_internal)
    !===================================================================
    SUBROUTINE Co_Su_Co_bb_internal(surf, tolerance)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        REAL(wp), INTENT(IN) :: tolerance
        INTEGER(i4) :: k

        IF (surf%pop%n_nodes > 0) THEN
            surf%bbox_min = surf%coords_current(:, 1)
            surf%bbox_max = surf%coords_current(:, 1)
        END IF

        DO k = 2, surf%pop%n_nodes
            surf%bbox_min(1) = MIN(surf%bbox_min(1), surf%coords_current(1, k))
            surf%bbox_min(2) = MIN(surf%bbox_min(2), surf%coords_current(2, k))
            surf%bbox_min(3) = MIN(surf%bbox_min(3), surf%coords_current(3, k))
            surf%bbox_max(1) = MAX(surf%bbox_max(1), surf%coords_current(1, k))
            surf%bbox_max(2) = MAX(surf%bbox_max(2), surf%coords_current(2, k))
            surf%bbox_max(3) = MAX(surf%bbox_max(3), surf%coords_current(3, k))
        END DO

        surf%bbox_min = surf%bbox_min - tolerance
        surf%bbox_max = surf%bbox_max + tolerance
    END SUBROUTINE

    !===================================================================
    ! Co_Su_bu_topology  (PUBLIC: Cont_Surface_build_topology)
    !===================================================================
    SUBROUTINE Co_Su_bu_topology(surf, max_seg_per_nod)
        TYPE(ContSurface), INTENT(INOUT) :: surf
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_seg_per_nod
        INTEGER(i4) :: k, j, l, node, cnt
        INTEGER(i4) :: max_seg

        max_seg = 4
        IF (PRESENT(max_seg_per_nod)) max_seg = max_seg_per_nod
        surf%max_seg_per_nod = max_seg

        IF (ALLOCATED(surf%node_to_seg)) DEALLOCATE(surf%node_to_seg)
        ALLOCATE(surf%node_to_seg(max_seg, surf%pop%n_nodes))
        surf%node_to_seg = 0

        DO k = 1, surf%pop%n_nodes
            cnt = 0
            DO j = 1, surf%n_segments
                DO l = 1, surf%segments(j)%pop%n_nodes
                    node = surf%segments(j)%nodes(l)
                    IF (node == k) THEN
                        cnt = cnt + 1
                        IF (cnt <= max_seg) THEN
                            surf%node_to_seg(cnt, k) = j
                        END IF
                        EXIT
                    END IF
                END DO
            END DO
        END DO
    END SUBROUTINE

    !===================================================================
    ! Cont_Surface_Valid
    !===================================================================
    SUBROUTINE Cont_Surface_Valid(surf, ierr, error_msg)
        TYPE(ContSurface), INTENT(IN) :: surf
        INTEGER(i4), INTENT(OUT) :: ierr
        CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: error_msg
        INTEGER(i4) :: j, l, node
        REAL(wp) :: len

        ierr = 0
        IF (PRESENT(error_msg)) error_msg = ''

        IF (surf%pop%n_nodes < 2) THEN
            ierr = 1
            IF (PRESENT(error_msg)) error_msg = 'Surface must have at least 2 nodes'
            RETURN
        END IF

        IF (surf%n_segments < 1) THEN
            ierr = 2
            IF (PRESENT(error_msg)) error_msg = 'Surface must have at least 1 segment'
            RETURN
        END IF

        DO j = 1, surf%n_segments
            DO l = 1, surf%segments(j)%pop%n_nodes
                node = surf%segments(j)%nodes(l)
                IF (node < 1 .OR. node > surf%pop%n_nodes) THEN
                    ierr = 3
                    IF (PRESENT(error_msg)) error_msg = 'Invalid node index in segment'
                    RETURN
                END IF
            END DO

            len = surf%segments(j)%length
            IF (len <= 0.0_wp) THEN
                ierr = 4
                IF (PRESENT(error_msg)) error_msg = 'Segment has zero or negative length'
                RETURN
            END IF
        END DO
    END SUBROUTINE

    !===================================================================
    ! contact_init
    !===================================================================
    SUBROUTINE contact_init(cpair, master_id, slave_id, contact_type, dimension, tol, search_tol)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        INTEGER(i4), INTENT(IN) :: master_id, slave_id
        INTEGER(i4), INTENT(IN), OPTIONAL :: contact_type
        INTEGER(i4), INTENT(IN), OPTIONAL :: dimension
        REAL(wp), INTENT(IN), OPTIONAL :: tol
        REAL(wp), INTENT(IN), OPTIONAL :: search_tol

        cpair%master_surf_id = master_id
        cpair%slave_surf_id = slave_id

        IF (PRESENT(contact_type)) THEN
            cpair%contact_type = contact_type
        ELSE
            cpair%contact_type = CONTACT_NODE_TO
        END IF

        IF (PRESENT(dimension)) THEN
            cpair%dimension = dimension
        ELSE
            cpair%dimension = 3
        END IF

        IF (PRESENT(tol)) THEN
            cpair%gap_tolerance = tol
        ELSE
            cpair%gap_tolerance = 1.0E-6_wp
        END IF

        IF (PRESENT(search_tol)) THEN
            cpair%search_toleranc = search_tol
        ELSE
            cpair%search_toleranc = 0.1_wp * cpair%gap_tolerance
        END IF

        cpair%is_self_contact = (master_id == slave_id)
        cpair%active = .TRUE.
        cpair%use_bucket_sear = .TRUE.
        cpair%use_bvh_search = .FALSE.
        NULLIFY(cpair%bucket_grid)
        NULLIFY(cpair%bvh_tree)
    END SUBROUTINE

    !===================================================================
    ! contact_init_Arg
    !===================================================================
    SUBROUTINE contact_init_Arg(cpair, arg)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        TYPE(MD_IC_ContactInit_Arg), INTENT(IN) :: arg

        IF (arg%search_tol < 0.0_wp) THEN
            CALL contact_init(cpair, arg%master_id, arg%slave_id, &
                contact_type=arg%contact_type, dimension=arg%dimension, tol=arg%tol)
        ELSE
            CALL contact_init(cpair, arg%master_id, arg%slave_id, &
                contact_type=arg%contact_type, dimension=arg%dimension, tol=arg%tol, &
                search_tol=arg%search_tol)
        END IF
    END SUBROUTINE

    !===================================================================
    ! contact_init_from_pair
    !===================================================================
    SUBROUTINE contact_init_from_pair(cpair, pair_def)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        TYPE(ContPairDef), INTENT(IN) :: pair_def

        cpair%cfg%id               = pair_def%cfg%id
        cpair%master_surf_id   = pair_def%master_surface
        cpair%slave_surf_id    = pair_def%slave_surface_i
        cpair%contact_type     = pair_def%contact_type
        cpair%gap_tolerance    = pair_def%gap_tolerance
        cpair%search_toleranc = pair_def%search_toleranc
        cpair%is_self_contact  = pair_def%is_self_contact
        cpair%active        = pair_def%active
        cpair%dimension = 3
    END SUBROUTINE

    !===================================================================
    ! contact_update_geometry
    !===================================================================
    SUBROUTINE contact_update_geometry(cpair, master_surf, slave_surf, disp, dof_map, ndof)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        TYPE(ContSurface), INTENT(INOUT) :: master_surf
        TYPE(ContSurface), INTENT(INOUT) :: slave_surf
        REAL(wp), INTENT(IN) :: disp(:)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        INTEGER(i4), INTENT(IN) :: ndof

        CALL Co_Su_up_coords(master_surf, disp, dof_map, ndof)
        CALL Co_Su_up_coords(slave_surf, disp, dof_map, ndof)
    END SUBROUTINE

    !===================================================================
    ! contact_update_geometry_Arg
    !===================================================================
    SUBROUTINE contact_update_geometry_Arg(cpair, master_surf, slave_surf, disp, dof_map, arg)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        TYPE(ContSurface), INTENT(INOUT) :: master_surf
        TYPE(ContSurface), INTENT(INOUT) :: slave_surf
        REAL(wp), INTENT(IN) :: disp(:)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        TYPE(MD_IC_ContactUpdateGeom_Arg), INTENT(IN), OPTIONAL :: arg
        INTEGER(i4) :: ndm

        ndm = SIZE(disp)
        IF (PRESENT(arg)) THEN
            IF (arg%ndof > 0_i4) ndm = arg%ndof
        END IF
        CALL contact_update_geometry(cpair, master_surf, slave_surf, disp, dof_map, ndm)
    END SUBROUTINE

    !===================================================================
    ! co_de_gl_su_id  (PUBLIC: contact_decode_global_surf_id)
    !===================================================================
    SUBROUTINE co_de_gl_su_id(model, globalId, partIndex, localSurfId)
        USE MD_Base_ObjModel, ONLY: UF_Model

        TYPE(UF_Model), INTENT(IN) :: model
        INTEGER(i4), INTENT(IN) :: globalId
        INTEGER(i4), INTENT(OUT) :: partIndex
        INTEGER(i4), INTENT(OUT) :: localSurfId

        INTEGER(i4) :: iPart, offset, nSurf

        partIndex = 0_i4
        localSurfId = 0_i4
        IF (globalId < 1_i4) RETURN

        offset = 0_i4

        IF (ALLOCATED(model%parts)) THEN
            IF (SIZE(model%parts) > 0) THEN
                DO iPart = 1, SIZE(model%parts)
                    IF (.NOT. ALLOCATED(model%parts(iPart)%surfSets)) CYCLE
                    nSurf = SIZE(model%parts(iPart)%surfSets)
                    IF (globalId > offset .AND. globalId <= offset + nSurf) THEN
                        partIndex = iPart
                        localSurfId = globalId - offset
                        RETURN
                    END IF
                    offset = offset + nSurf
                END DO
            END IF
        END IF
    END SUBROUTINE

    !===================================================================
    ! co_co_su_nodes  (PUBLIC: contact_collect_surface_nodes)
    !===================================================================
    SUBROUTINE co_co_su_nodes(part, surfId, nodeIds, nUnique)
        USE MD_Mesh_Mgr, ONLY: UF_ElementType, UF_GetElementType, UF_GetFaceLocalNodes
        USE MD_Base_ObjModel, ONLY: UF_Part

        TYPE(UF_Part), INTENT(IN) :: part
        INTEGER(i4), INTENT(IN) :: surfId
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: nodeIds(:)
        INTEGER(i4), INTENT(OUT) :: nUnique

        INTEGER(i4), ALLOCATABLE :: tmp(:)
        INTEGER(i4) :: iFace, id, faceId, elemIdx, nFaceNode, k, nMax
        INTEGER(i4) :: localNodes(9)
        TYPE(UF_ElementType), POINTER :: ElemType

        nUnique = 0_i4
        nMax = SIZE(part%surfSets(surfId)%faces, 2) * 9
        ALLOCATE(tmp(MAX(1_i4, nMax)))

        DO iFace = 1, SIZE(part%surfSets(surfId)%faces, 2)
            id = part%surfSets(surfId)%faces(1, iFace)
            faceId = part%surfSets(surfId)%faces(2, iFace)
            elemIdx = contact_find_Elem_index(part, id)
            IF (elemIdx < 1) CYCLE
            ElemType => UF_GetElementType(part%elements(elemIdx)%elemTypeId)
            IF (.NOT. ASSOCIATED(ElemType)) CYCLE
            CALL UF_GetFaceLocalNodes(ElemType, faceId, localNodes, nFaceNode)
            IF (nFaceNode < 1) CYCLE
            DO k = 1, nFaceNode
                id = part%elements(elemIdx)%conn(localNodes(k))
                IF (contact_has_int(tmp, nUnique, id)) CYCLE
                nUnique = nUnique + 1_i4
                tmp(nUnique) = id
            END DO
        END DO

        ALLOCATE(nodeIds(MAX(1_i4, nUnique)))
        IF (nUnique > 0) nodeIds(1:nUnique) = tmp(1:nUnique)
        DEALLOCATE(tmp)
    END SUBROUTINE

    !===================================================================
    ! co_co_fa_no_area  (PUBLIC: contact_compute_face_normal_area)
    !===================================================================
    SUBROUTINE co_co_fa_no_area(coords, nNode, nrm, area)
        REAL(wp), INTENT(IN) :: coords(3, :)
        INTEGER(i4), INTENT(IN) :: nNode
        REAL(wp), INTENT(OUT) :: nrm(3)
        REAL(wp), INTENT(OUT) :: area
        REAL(wp) :: v1(3), v2(3), n1(3), n2(3)
        REAL(wp) :: a(3), b(3), c(3), d(3), nn(3)

        nrm = 0.0_wp
        area = 0.0_wp
        IF (nNode < 3) RETURN

        a = coords(:,1)
        b = coords(:,2)
        c = coords(:,3)
        v1 = b - a
        v2 = c - a
        n1 = [v1(2)*v2(3)-v1(3)*v2(2), v1(3)*v2(1)-v1(1)*v2(3), v1(1)*v2(2)-v1(2)*v2(1)]
        area = 0.5_wp * SQRT(SUM(n1**2))
        nn = n1

        IF (nNode == 4) THEN
            d = coords(:,4)
            v1 = c - a
            v2 = d - a
            n2 = [v1(2)*v2(3)-v1(3)*v2(2), v1(3)*v2(1)-v1(1)*v2(3), v1(1)*v2(2)-v1(2)*v2(1)]
            area = area + 0.5_wp * SQRT(SUM(n2**2))
            nn = n1 + n2
        END IF

        IF (SQRT(SUM(nn**2)) > 1.0E-30_wp) THEN
            nrm = nn / SQRT(SUM(nn**2))
        ELSE
            nrm = 0.0_wp
        END IF
    END SUBROUTINE

    !===================================================================
    ! contact_Eval_face_gap
    !===================================================================
    SUBROUTINE contact_Eval_face_gap(part, nodeStates, elemId, faceId, xSlave, bestGap, bestElemId, bestFaceId, bestNrm, bestX0)
        USE MD_Mesh_Mgr, ONLY: UF_ElementType, UF_GetElementType, UF_GetFaceLocalNodes
        USE MD_Base_ObjModel, ONLY: UF_Part

        TYPE(UF_Part), INTENT(IN) :: part
        TYPE(MD_NodeDisp), INTENT(IN) :: nodeStates(:)
        INTEGER(i4), INTENT(IN) :: elemId, faceId
        REAL(wp), INTENT(IN) :: xSlave(3)
        REAL(wp), INTENT(INOUT) :: bestGap
        INTEGER(i4), INTENT(INOUT) :: bestElemId, bestFaceId
        REAL(wp), INTENT(INOUT) :: bestNrm(3), bestX0(3)

        INTEGER(i4) :: elemIdx, nFaceNode, nid, k
        TYPE(UF_ElementType), POINTER :: ElemType
        INTEGER(i4) :: localNodes(9)
        REAL(wp) :: x(3,9), nrm(3), area, gap

        elemIdx = contact_find_Elem_index(part, elemId)
        IF (elemIdx < 1) RETURN
        ElemType => UF_GetElementType(part%elements(elemIdx)%elemTypeId)
        IF (.NOT. ASSOCIATED(ElemType)) RETURN

        CALL UF_GetFaceLocalNodes(ElemType, faceId, localNodes, nFaceNode)
        IF (nFaceNode < 3) RETURN

        DO k = 1, nFaceNode
            nid = part%elements(elemIdx)%conn(localNodes(k))
            x(:, k) = contact_get_node_coord_curr(part, nodeStates, nid)
        END DO

        CALL co_co_fa_no_area(x(:,1:nFaceNode), nFaceNode, nrm, area)
        IF (area <= 0.0_wp) RETURN

        gap = contact_dot3(nrm, xSlave - x(:,1))
        IF (gap < bestGap) THEN
            bestGap = gap
            bestElemId = elemId
            bestFaceId = faceId
            bestNrm = nrm
            bestX0 = x(:,1)
        END IF
    END SUBROUTINE

    !===================================================================
    ! contact_Eval_face_gap_Arg
    !===================================================================
    SUBROUTINE contact_Eval_face_gap_Arg(part, nodeStates, arg)
        USE MD_Base_ObjModel, ONLY: UF_Part
        TYPE(UF_Part), INTENT(IN) :: part
        TYPE(MD_NodeDisp), INTENT(IN) :: nodeStates(:)
        TYPE(MD_IC_ContactEvalFace_Arg), INTENT(INOUT) :: arg

        CALL contact_Eval_face_gap(part, nodeStates, arg%elemId, arg%faceId, arg%xSlave, &
            arg%bestGap, arg%bestElemId, arg%bestFaceId, arg%bestNrm, arg%bestX0)
    END SUBROUTINE

    !===================================================================
    ! uinter_call
    !===================================================================
    SUBROUTINE uinter_call(node, pair, props, nprops, statev, nstatev, &
                            sigma, stiffness, temp, dtime, kstep, kinc, ierr)
        TYPE(ContNode), INTENT(INOUT) :: node
        TYPE(ContPairDef), INTENT(IN) :: pair
        REAL(wp), INTENT(IN) :: props(*)
        INTEGER(i4), INTENT(IN) :: nprops
        REAL(wp), INTENT(INOUT) :: statev(*)
        INTEGER(i4), INTENT(IN) :: nstatev
        REAL(wp), INTENT(OUT) :: sigma(6)
        REAL(wp), INTENT(OUT) :: stiffness(6,6)
        REAL(wp), INTENT(IN) :: temp, dtime
        INTEGER(i4), INTENT(IN) :: kstep, kinc
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        REAL(wp) :: pnewdt, flux, ddfddt, ddfddr, deff
        REAL(wp) :: area, apts(2), slip(2), dslip(2)
        REAL(wp) :: pener, sener, rdisp(3), drdisp(3)
        REAL(wp) :: pres, dpres, ctime(2)
        CHARACTER(LEN=80) :: cname
        REAL(wp) :: predel, precd, dpred, dprecd
        REAL(wp) :: eps_n

        IF (PRESENT(ierr)) ierr = 0

        sigma = 0.0_wp
        stiffness = 0.0_wp

        IF (is_uinter_activ .AND. ASSOCIATED(user_uinter)) THEN
            area = 1.0_wp
            apts = 0.0_wp
            slip(1) = node%slip * node%tangent(2)
            slip(2) = node%slip * node%tangent(3)
            dslip = slip
            pener = 0.0_wp
            sener = 0.0_wp
            rdisp(1) = -node%penetration
            rdisp(2) = slip(1)
            rdisp(3) = slip(2)
            drdisp = 0.0_wp
            pres = node%force_n
            dpres = 0.0_wp
            ctime(1) = dtime
            ctime(2) = dtime * REAL(kinc, wp)
            cname = 'CONTACT_PAIR'
            pnewdt = 1.0_wp
            predel = pres
            precd = rdisp(1)
            dpred = 0.0_wp
            dprecd = 0.0_wp

            CALL user_uinter(sigma, stiffness, flux, flux, ddfddt, ddfddr, &
                             deff, temp, 0.0_wp, pnewdt, &
                             props, nprops, statev, nstatev, &
                             area, apts, slip, dslip, pener, sener, &
                             rdisp, drdisp, pres, dpres, &
                             ctime, dtime, kstep, kinc, 1, cname, &
                             predel, precd, dpred, dprecd)
        ELSE
            eps_n = pair%penalty_normal

            IF (node%penetration > 0.0_wp) THEN
                sigma(1) = eps_n * node%penetration
                stiffness(1,1) = eps_n
            END IF

            IF (node%state /= CSTATE_SEPARATE) THEN
                sigma(2) = node%force_t(2)
                sigma(3) = node%force_t(3)
                stiffness(2,2) = pair%penalty_tangent
                stiffness(3,3) = pair%penalty_tangent
            END IF
        END IF
    END SUBROUTINE

    !===================================================================
    ! ucontprop_call
    !===================================================================
    SUBROUTINE ucontprop_call(cpen, cdamp, props, nprops, temp, press, &
                              area, jtype, kstep, kinc, ierr)
        REAL(wp), INTENT(OUT) :: cpen
        REAL(wp), INTENT(OUT) :: cdamp
        REAL(wp), INTENT(IN) :: props(*)
        INTEGER(i4), INTENT(IN) :: nprops
        REAL(wp), INTENT(IN) :: temp
        REAL(wp), INTENT(IN) :: press
        REAL(wp), INTENT(IN) :: area
        INTEGER(i4), INTENT(IN) :: jtype
        INTEGER(i4), INTENT(IN) :: kstep
        INTEGER(i4), INTENT(IN) :: kinc
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        IF (PRESENT(ierr)) ierr = 0

        IF (nprops >= 1) THEN
            cpen = props(1)
        ELSE
            cpen = 1.0E12_wp
        END IF

        IF (nprops >= 2) THEN
            cdamp = props(2)
        ELSE
            cdamp = 0.0_wp
        END IF
    END SUBROUTINE

    !===================================================================
    ! user_contact_init
    !===================================================================
    SUBROUTINE user_contact_init()
        is_uinter_activ = .FALSE.
        is_fric_active = .FALSE.
        user_uinter => NULL()
        user_fric => NULL()
    END SUBROUTINE

    !===================================================================
    ! user_contact_Reg
    !===================================================================
    SUBROUTINE user_contact_Reg(sub_type, active)
        CHARACTER(LEN=*), INTENT(IN) :: sub_type
        LOGICAL, INTENT(IN) :: active

        SELECT CASE (TRIM(sub_type))
        CASE ('UINTER')
            is_uinter_activ = active
        CASE ('FRIC')
            is_fric_active = active
        END SELECT
    END SUBROUTINE

    !===================================================================
    ! fric_call
    !===================================================================
    SUBROUTINE fric_call(mu, ddmudp, ddmudv, press, slip, temp, &
                          props, nprops, statev, nstatev, ierr)
        REAL(wp), INTENT(OUT) :: mu
        REAL(wp), INTENT(OUT) :: ddmudp
        REAL(wp), INTENT(OUT) :: ddmudv
        REAL(wp), INTENT(IN) :: press
        REAL(wp), INTENT(IN) :: slip
        REAL(wp), INTENT(IN) :: temp
        REAL(wp), INTENT(IN) :: props(*)
        INTEGER(i4), INTENT(IN) :: nprops
        REAL(wp), INTENT(INOUT) :: statev(*)
        INTEGER(i4), INTENT(IN) :: nstatev
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        IF (PRESENT(ierr)) ierr = 0

        IF (is_fric_active .AND. ASSOCIATED(user_fric)) THEN
            CALL user_fric(mu, ddmudp, ddmudv, press, slip, temp, &
                          props, nprops, statev, nstatev)
        ELSE
            mu = 0.3_wp
            ddmudp = 0.0_wp
            ddmudv = 0.0_wp
        END IF
    END SUBROUTINE

    !===================================================================
    ! vfric_call
    !===================================================================
    SUBROUTINE vfric_call(mu, ddmudp, ddmudv, press, slip, sliprate, temp, &
                           props, nprops, statev, nstatev, ierr)
        REAL(wp), INTENT(OUT) :: mu
        REAL(wp), INTENT(OUT) :: ddmudp
        REAL(wp), INTENT(OUT) :: ddmudv
        REAL(wp), INTENT(IN) :: press
        REAL(wp), INTENT(IN) :: slip
        REAL(wp), INTENT(IN) :: sliprate
        REAL(wp), INTENT(IN) :: temp
        REAL(wp), INTENT(IN) :: props(*)
        INTEGER(i4), INTENT(IN) :: nprops
        REAL(wp), INTENT(INOUT) :: statev(*)
        INTEGER(i4), INTENT(IN) :: nstatev
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        IF (PRESENT(ierr)) ierr = 0

        IF (is_fric_active .AND. ASSOCIATED(user_fric)) THEN
            CALL user_fric(mu, ddmudp, ddmudv, press, slip, temp, &
                          props, nprops, statev, nstatev)
        ELSE
            mu = 0.3_wp
            ddmudp = 0.0_wp
            ddmudv = 0.0_wp
        END IF
    END SUBROUTINE

END MODULE MD_Int_Manager
