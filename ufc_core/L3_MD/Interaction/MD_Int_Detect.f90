!======================================================================
! MODULE:  MD_Int_Detect
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Contact search and detection algorithms.
!          Bucket grid, BVH tree, brute-force search,
!          candidate finding, detection (2D/3D).
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================
MODULE MD_Int_Detect
    USE MD_Int_Types
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE

    !-- re-export nothing from Types; thin layer will do that ----------

    !-- local parameters (same as original) ---------------------------
    REAL(wp), PARAMETER :: SEARCH_TOL_DEFA = 1.0E-10_wp
    INTEGER(i4), PARAMETER :: MAX_CANDIDATES = 10

    !==================================================================
    ! PUBLIC procedure interfaces (using actual SUBROUTINE names)
    !==================================================================
    PUBLIC :: Cont_Bucket_grid_init, Cont_Bucket_grid_build
    PUBLIC :: Cont_Bucket_grid_query, Cont_Bucket_grid_cleanup
    PUBLIC :: Cont_Bucket_search
    PUBLIC :: Cont_BVH_build_recursive, Cont_BVH_query_recursive
    PUBLIC :: Cont_BVH_tree_build, Cont_BVH_tree_query, Cont_BVH_tree_cleanup
    PUBLIC :: brute_force_search
    PUBLIC :: Compute_gap_to_segment_2d, Compute_segment_bbox
    PUBLIC :: md_cont_get_bucket_range, md_cont_partition_segments
    PUBLIC :: resize_candidates, store_contact_results
    PUBLIC :: contact_detect, contact_detect_2d, contact_detect_3d
    PUBLIC :: Co_Se_fi_candidates, Co_Se_up_tracking
    PUBLIC :: Cont_Search_global_init, Cont_Search_local_update
    PUBLIC :: md_cont_aabb_overlap_test

    !==================================================================
    ! INTERFACE alias blocks  (PUBLIC name -> actual SUBROUTINE name)
    !==================================================================
    INTERFACE Cont_Search_find_candidates
        MODULE PROCEDURE Co_Se_fi_candidates
    END INTERFACE
    PUBLIC :: Cont_Search_find_candidates

    INTERFACE Cont_Search_update_tracking
        MODULE PROCEDURE Co_Se_up_tracking
    END INTERFACE
    PUBLIC :: Cont_Search_update_tracking

CONTAINS

    !===================================================================
    ! md_cont_aabb_overlap_test
    !===================================================================
    FUNCTION md_cont_aabb_overlap_test(bbox1_min, bbox1_max, bbox2_min, bbox2_max) RESULT(overlap)
        REAL(wp), INTENT(IN) :: bbox1_min(3), bbox1_max(3)
        REAL(wp), INTENT(IN) :: bbox2_min(3), bbox2_max(3)
        LOGICAL :: overlap

        overlap = .NOT. (bbox1_max(1) < bbox2_min(1) .OR. bbox1_min(1) > bbox2_max(1) .OR. &
                        bbox1_max(2) < bbox2_min(2) .OR. bbox1_min(2) > bbox2_max(2) .OR. &
                        bbox1_max(3) < bbox2_min(3) .OR. bbox1_min(3) > bbox2_max(3))
    END FUNCTION

    !===================================================================
    ! brute_force_search  (version 1 - basic)
    !===================================================================
    SUBROUTINE brute_force_search(master_surf, slave_surf, pair, &
                                   candidates, n_candidates, preallocated_te)
        TYPE(ContSurface), INTENT(IN) :: master_surf
        TYPE(ContSurface), INTENT(IN) :: slave_surf
        TYPE(ContPairDef), INTENT(IN) :: pair
        TYPE(ContCandidate), ALLOCATABLE, INTENT(INOUT) :: candidates(:)
        INTEGER(i4), INTENT(OUT) :: n_candidates
        TYPE(ContCandidate), INTENT(IN), OPTIONAL, TARGET :: preallocated_te(:)

        INTEGER(i4) :: k, j, max_cand, n_slave, n_master
        REAL(wp) :: slave_pt(3), search_rad
        REAL(wp) :: seg_min(3), seg_max(3)
        TYPE(ContCandidate), ALLOCATABLE :: temp_cand(:)
        TYPE(ContCandidate), POINTER :: work_cand(:)
        LOGICAL :: use_preallocate

        n_slave = slave_surf%pop%n_nodes
        n_master = master_surf%n_segments
        search_rad = pair%search_toleranc

        max_cand = MIN(n_slave * MAX_CANDIDATES, n_slave * n_master)

        use_preallocate = .FALSE.
        NULLIFY(work_cand)

        IF (PRESENT(preallocated_te)) THEN
            IF (SIZE(preallocated_te) >= max_cand) THEN
                work_cand => preallocated_te(1:max_cand)
                use_preallocate = .TRUE.
            END IF
        END IF

        IF (.NOT. use_preallocate) THEN
            ALLOCATE(temp_cand(max_cand))
            work_cand => temp_cand
        END IF

        n_candidates = 0

        DO k = 1, n_slave
            slave_pt = slave_surf%coords_current(:, k)

            DO j = 1, n_master
                CALL Compute_segment_bbox(master_surf, j, seg_min, seg_max, search_rad)

                IF (.NOT. md_cont_point_in_aabb(slave_pt, seg_min, seg_max)) CYCLE

                IF (n_candidates < max_cand) THEN
                    n_candidates = n_candidates + 1
                    work_cand(n_candidates)%slave_node = k
                    work_cand(n_candidates)%master_segment = j
                    work_cand(n_candidates)%distance = 0.0_wp
                END IF
            END DO
        END DO

        IF (ALLOCATED(candidates)) DEALLOCATE(candidates)
        IF (n_candidates > 0) THEN
            ALLOCATE(candidates(n_candidates))
            candidates(1:n_candidates) = work_cand(1:n_candidates)
        END IF

        IF (.NOT. use_preallocate) THEN
            DEALLOCATE(temp_cand)
        END IF
    END SUBROUTINE

    !===================================================================
    ! Compute_gap_to_segment_2d
    !===================================================================
    SUBROUTINE Compute_gap_to_segment_2d(surf, seg_id, point, gap, xi_local)
        TYPE(ContSurface), INTENT(IN) :: surf
        INTEGER(i4), INTENT(IN) :: seg_id
        REAL(wp), INTENT(IN) :: point(3)
        REAL(wp), INTENT(OUT) :: gap
        REAL(wp), INTENT(OUT) :: xi_local(2)

        INTEGER(i4) :: n1, n2
        REAL(wp) :: p1(3), p2(3), seg_vec(3), pt_vec(3)
        REAL(wp) :: seg_len, t, closest(3), dist_vec(3)
        REAL(wp) :: normal(3)

        n1 = surf%segments(seg_id)%nodes(1)
        n2 = surf%segments(seg_id)%nodes(2)

        p1 = surf%coords_current(:, n1)
        p2 = surf%coords_current(:, n2)

        seg_vec = p2 - p1
        seg_len = SQRT(SUM(seg_vec**2))

        IF (seg_len < 1.0E-30_wp) THEN
            gap = SQRT(SUM((point - p1)**2))
            xi_local = 0.0_wp
            RETURN
        END IF

        pt_vec = point - p1
        t = SUM(pt_vec * seg_vec) / (seg_len * seg_len)

        t = MAX(0.0_wp, MIN(1.0_wp, t))

        closest = p1 + t * seg_vec
        dist_vec = point - closest

        normal = surf%segments(seg_id)%normal
        gap = SUM(dist_vec * normal)

        xi_local(1) = 2.0_wp * t - 1.0_wp
        xi_local(2) = 0.0_wp
    END SUBROUTINE

    !===================================================================
    ! Compute_segment_bbox  (version with OPTIONAL expand)
    !===================================================================
    SUBROUTINE Compute_segment_bbox(surf, seg_id, bbox_min, bbox_max, expand)
        TYPE(ContSurface), INTENT(IN) :: surf
        INTEGER(i4), INTENT(IN) :: seg_id
        REAL(wp), INTENT(OUT) :: bbox_min(3), bbox_max(3)
        REAL(wp), INTENT(IN), OPTIONAL :: expand

        INTEGER(i4) :: i, node
        REAL(wp) :: exp_val

        exp_val = 0.0_wp
        IF (PRESENT(expand)) exp_val = expand

        bbox_min = HUGE(1.0_wp)
        bbox_max = -HUGE(1.0_wp)

        DO i = 1, surf%segments(seg_id)%pop%n_nodes
            node = surf%segments(seg_id)%nodes(i)
            IF (node >= 1 .AND. node <= surf%pop%n_nodes) THEN
                bbox_min = MIN(bbox_min, surf%coords_current(:, node))
                bbox_max = MAX(bbox_max, surf%coords_current(:, node))
            END IF
        END DO

        bbox_min = bbox_min - exp_val
        bbox_max = bbox_max + exp_val
    END SUBROUTINE

    !===================================================================
    ! Cont_Bucket_grid_init
    !===================================================================
    SUBROUTINE Cont_Bucket_grid_init(grid, surf, n_divisions, search_rad)
        TYPE(BucketGrid), INTENT(INOUT) :: grid
        TYPE(ContSurface), INTENT(IN) :: surf
        INTEGER(i4), INTENT(IN), OPTIONAL :: n_divisions
        REAL(wp), INTENT(IN), OPTIONAL :: search_rad

        INTEGER(i4) :: ndiv, i, j, k
        REAL(wp) :: domain_size(3), rad

        ndiv = 10
        IF (PRESENT(n_divisions)) ndiv = n_divisions

        rad = 0.0_wp
        IF (PRESENT(search_rad)) rad = search_rad

        grid%origin = surf%bbox_min - rad
        domain_size = surf%bbox_max - surf%bbox_min + 2.0_wp * rad

        grid%nx = MAX(1, ndiv)
        grid%ny = MAX(1, ndiv)
        grid%nz = MAX(1, ndiv)

        grid%cell_size(1) = domain_size(1) / REAL(grid%nx, wp)
        grid%cell_size(2) = domain_size(2) / REAL(grid%ny, wp)
        grid%cell_size(3) = domain_size(3) / REAL(grid%nz, wp)

        WHERE (grid%cell_size < 1.0E-30_wp)
            grid%cell_size = 1.0_wp
        END WHERE

        IF (ALLOCATED(grid%buckets)) DEALLOCATE(grid%buckets)
        ALLOCATE(grid%buckets(grid%nx, grid%ny, grid%nz))

        DO k = 1, grid%nz
            DO j = 1, grid%ny
                DO i = 1, grid%nx
                    grid%buckets(i,j,k)%n_items = 0
                END DO
            END DO
        END DO
    END SUBROUTINE

    !===================================================================
    ! Cont_Bucket_grid_build
    !===================================================================
    SUBROUTINE Cont_Bucket_grid_build(grid, surf, search_rad)
        TYPE(BucketGrid), INTENT(INOUT) :: grid
        TYPE(ContSurface), INTENT(IN) :: surf
        REAL(wp), INTENT(IN) :: search_rad

        INTEGER(i4) :: seg, i, j, k
        INTEGER(i4) :: imin, imax, jmin, jmax, kmin, kmax
        REAL(wp) :: seg_min(3), seg_max(3)
        INTEGER(i4), ALLOCATABLE :: count_arr(:,:,:)

        ALLOCATE(count_arr(grid%nx, grid%ny, grid%nz))
        count_arr = 0

        DO seg = 1, surf%n_segments
            CALL Compute_segment_bbox(surf, seg, seg_min, seg_max, search_rad)
            CALL md_cont_get_bucket_range(grid, seg_min, seg_max, &
                                  imin, imax, jmin, jmax, kmin, kmax)

            DO k = kmin, kmax
                DO j = jmin, jmax
                    DO i = imin, imax
                        count_arr(i,j,k) = count_arr(i,j,k) + 1
                    END DO
                END DO
            END DO
        END DO

        DO k = 1, grid%nz
            DO j = 1, grid%ny
                DO i = 1, grid%nx
                    IF (count_arr(i,j,k) > 0) THEN
                        IF (ALLOCATED(grid%buckets(i,j,k)%item_ids)) &
                            DEALLOCATE(grid%buckets(i,j,k)%item_ids)
                        ALLOCATE(grid%buckets(i,j,k)%item_ids(count_arr(i,j,k)))
                    END IF
                    grid%buckets(i,j,k)%n_items = 0
                END DO
            END DO
        END DO

        DO seg = 1, surf%n_segments
            CALL Compute_segment_bbox(surf, seg, seg_min, seg_max, search_rad)
            CALL md_cont_get_bucket_range(grid, seg_min, seg_max, &
                                  imin, imax, jmin, jmax, kmin, kmax)

            DO k = kmin, kmax
                DO j = jmin, jmax
                    DO i = imin, imax
                        grid%buckets(i,j,k)%n_items = grid%buckets(i,j,k)%n_items + 1
                        grid%buckets(i,j,k)%item_ids(grid%buckets(i,j,k)%n_items) = seg
                    END DO
                END DO
            END DO
        END DO

        DEALLOCATE(count_arr)
    END SUBROUTINE

    !===================================================================
    ! Cont_Bucket_grid_cleanup
    !===================================================================
    SUBROUTINE Cont_Bucket_grid_cleanup(grid)
        TYPE(BucketGrid), INTENT(INOUT) :: grid

        INTEGER(i4) :: i, j, k

        IF (ALLOCATED(grid%buckets)) THEN
            DO k = 1, grid%nz
                DO j = 1, grid%ny
                    DO i = 1, grid%nx
                        IF (ALLOCATED(grid%buckets(i,j,k)%item_ids)) &
                            DEALLOCATE(grid%buckets(i,j,k)%item_ids)
                    END DO
                END DO
            END DO
            DEALLOCATE(grid%buckets)
        END IF

        grid%nx = 0
        grid%ny = 0
        grid%nz = 0
    END SUBROUTINE

    !===================================================================
    ! Cont_Bucket_grid_query
    !===================================================================
    SUBROUTINE Cont_Bucket_grid_query(grid, point, seg_ids, n_segs, preallocated_se)
        TYPE(BucketGrid), INTENT(IN) :: grid
        REAL(wp), INTENT(IN) :: point(3)
        INTEGER(i4), ALLOCATABLE, INTENT(INOUT) :: seg_ids(:)
        INTEGER(i4), INTENT(OUT) :: n_segs
        INTEGER(i4), INTENT(IN), OPTIONAL, TARGET :: preallocated_se(:)

        INTEGER(i4) :: ix, iy, iz
        INTEGER(i4) :: ix_min, ix_max, iy_min, iy_max, iz_min, iz_max
        INTEGER(i4) :: i, j, k, idx, seg
        INTEGER(i4), ALLOCATABLE :: temp_ids(:)
        INTEGER(i4), POINTER :: work_seg_ids(:)
        INTEGER(i4) :: temp_count, unique_count, max_seg_ids
        LOGICAL :: is_duplicate, use_preallocate

        ix = INT((point(1) - grid%origin(1)) / grid%cell_size(1)) + 1
        iy = INT((point(2) - grid%origin(2)) / grid%cell_size(2)) + 1
        iz = INT((point(3) - grid%origin(3)) / grid%cell_size(3)) + 1

        n_segs = 0
        IF (ix >= 1 .AND. ix <= grid%nx .AND. &
            iy >= 1 .AND. iy <= grid%ny .AND. &
            iz >= 1 .AND. iz <= grid%nz) THEN

            ix_min = MAX(1, ix - 1)
            ix_max = MIN(grid%nx, ix + 1)
            iy_min = MAX(1, iy - 1)
            iy_max = MIN(grid%ny, iy + 1)
            iz_min = MAX(1, iz - 1)
            iz_max = MIN(grid%nz, iz + 1)

            temp_count = 0
            DO k = iz_min, iz_max
                DO j = iy_min, iy_max
                    DO i = ix_min, ix_max
                        temp_count = temp_count + grid%buckets(i, j, k)%n_items
                    END DO
                END DO
            END DO

            IF (temp_count > 0) THEN
                use_preallocate = .FALSE.
                NULLIFY(work_seg_ids)

                IF (PRESENT(preallocated_se)) THEN
                    max_seg_ids = SIZE(preallocated_se)
                    IF (max_seg_ids >= temp_count) THEN
                        work_seg_ids => preallocated_se(1:temp_count)
                        use_preallocate = .TRUE.
                    END IF
                END IF

                IF (.NOT. use_preallocate) THEN
                    ALLOCATE(temp_ids(temp_count))
                    work_seg_ids => temp_ids
                END IF

                idx = 0
                DO k = iz_min, iz_max
                    DO j = iy_min, iy_max
                        DO i = ix_min, ix_max
                            DO seg = 1, grid%buckets(i, j, k)%n_items
                                idx = idx + 1
                                work_seg_ids(idx) = grid%buckets(i, j, k)%item_ids(seg)
                            END DO
                        END DO
                    END DO
                END DO

                unique_count = 0
                DO i = 1, temp_count
                    is_duplicate = .FALSE.
                    DO j = 1, unique_count
                        IF (work_seg_ids(i) == work_seg_ids(j)) THEN
                            is_duplicate = .TRUE.
                            EXIT
                        END IF
                    END DO
                    IF (.NOT. is_duplicate) THEN
                        unique_count = unique_count + 1
                        work_seg_ids(unique_count) = work_seg_ids(i)
                    END IF
                END DO

                n_segs = unique_count
                IF (ALLOCATED(seg_ids)) DEALLOCATE(seg_ids)
                IF (n_segs > 0) THEN
                    ALLOCATE(seg_ids(n_segs))
                    seg_ids = work_seg_ids(1:n_segs)
                END IF
                IF (.NOT. use_preallocate .AND. ALLOCATED(temp_ids)) THEN
                    DEALLOCATE(temp_ids)
                END IF
            END IF
        END IF
    END SUBROUTINE

    !===================================================================
    ! Cont_Bucket_search
    !===================================================================
    SUBROUTINE Cont_Bucket_search(master_surf, slave_surf, pair, &
                             candidates, n_candidates, preallocated_se)
        TYPE(ContSurface), INTENT(IN) :: master_surf
        TYPE(ContSurface), INTENT(IN) :: slave_surf
        TYPE(ContPairDef), INTENT(IN) :: pair
        TYPE(ContCandidate), ALLOCATABLE, INTENT(INOUT) :: candidates(:)
        INTEGER(i4), INTENT(OUT) :: n_candidates
        INTEGER(i4), INTENT(IN), OPTIONAL, TARGET :: preallocated_se(:)

        TYPE(BucketGrid) :: grid
        INTEGER(i4) :: k, max_cand
        INTEGER(i4), ALLOCATABLE :: seg_ids(:)
        INTEGER(i4) :: n_segs, i, seg

        max_cand = MIN(slave_surf%pop%n_nodes * MAX_CANDIDATES, &
                       slave_surf%pop%n_nodes * master_surf%n_segments)
        ALLOCATE(candidates(max_cand))
        n_candidates = 0

        CALL Cont_Bucket_grid_init(grid, master_surf, 10, pair%search_toleranc)
        CALL Cont_Bucket_grid_build(grid, master_surf, pair%search_toleranc)

        DO k = 1, slave_surf%pop%n_nodes
            CALL Cont_Bucket_grid_query(grid, slave_surf%coords_current(:, k), seg_ids, n_segs, &
                                    preallocated_se=preallocated_se)

            DO i = 1, n_segs
                seg = seg_ids(i)
                IF (n_candidates < max_cand) THEN
                    n_candidates = n_candidates + 1
                    candidates(n_candidates)%slave_node = k
                    candidates(n_candidates)%master_segment = seg
                    candidates(n_candidates)%distance = 0.0_wp
                END IF
            END DO
        END DO

        CALL Cont_Bucket_grid_cleanup(grid)

        IF (n_candidates == 0) THEN
            DEALLOCATE(candidates)
        ELSE
            CALL resize_candidates(candidates, n_candidates)
        END IF
    END SUBROUTINE

    !===================================================================
    ! Cont_BVH_build_recursive
    !===================================================================
    RECURSIVE SUBROUTINE Cont_BVH_build_recursive(tree, surf, seg_indices, centroids, &
                                              start_idx, end_idx, search_rad, node_id)
        TYPE(BVHTree), INTENT(INOUT) :: tree
        TYPE(ContSurface), INTENT(IN) :: surf
        INTEGER(i4), INTENT(INOUT) :: seg_indices(:)
        REAL(wp), INTENT(IN) :: centroids(:,:)
        INTEGER(i4), INTENT(IN) :: start_idx, end_idx
        REAL(wp), INTENT(IN) :: search_rad
        INTEGER(i4), INTENT(OUT) :: node_id

        INTEGER(i4) :: n_prims, mid, axis, i, seg
        REAL(wp) :: bbox_min(3), bbox_max(3), seg_min(3), seg_max(3)
        REAL(wp) :: extent(3), split_val
        INTEGER(i4) :: left_id, right_id

        n_prims = end_idx - start_idx + 1

        tree%pop%n_nodes = tree%pop%n_nodes + 1
        node_id = tree%pop%n_nodes
        tree%nodes(node_id)%cfg%id = node_id

        bbox_min = HUGE(1.0_wp)
        bbox_max = -HUGE(1.0_wp)

        DO i = start_idx, end_idx
            seg = seg_indices(i)
            CALL Compute_segment_bbox(surf, seg, seg_min, seg_max, search_rad)
            bbox_min = MIN(bbox_min, seg_min)
            bbox_max = MAX(bbox_max, seg_max)
        END DO

        tree%nodes(node_id)%bbox_min = bbox_min
        tree%nodes(node_id)%bbox_max = bbox_max

        IF (n_prims <= 1) THEN
            tree%nodes(node_id)%is_leaf = .TRUE.
            tree%nodes(node_id)%segment_id = seg_indices(start_idx)
            tree%nodes(node_id)%left_child = 0
            tree%nodes(node_id)%right_child = 0
            RETURN
        END IF

        extent = bbox_max - bbox_min
        axis = 1
        IF (extent(2) > extent(1)) axis = 2
        IF (extent(3) > extent(axis)) axis = 3

        mid = (start_idx + end_idx) / 2
        split_val = (bbox_min(axis) + bbox_max(axis)) * 0.5_wp

        CALL md_cont_partition_segments(seg_indices, centroids, start_idx, end_idx, &
                                axis, split_val, mid)

        IF (mid < start_idx) mid = start_idx
        IF (mid >= end_idx) mid = end_idx - 1

        tree%nodes(node_id)%is_leaf = .FALSE.
        tree%nodes(node_id)%segment_id = 0

        CALL Cont_BVH_build_recursive(tree, surf, seg_indices, centroids, &
                                 start_idx, mid, search_rad, left_id)
        tree%nodes(node_id)%left_child = left_id

        CALL Cont_BVH_build_recursive(tree, surf, seg_indices, centroids, &
                                 mid + 1, end_idx, search_rad, right_id)
        tree%nodes(node_id)%right_child = right_id
    END SUBROUTINE

    !===================================================================
    ! Cont_BVH_query_recursive
    !===================================================================
    RECURSIVE SUBROUTINE Cont_BVH_query_recursive(tree, node_id, point, search_rad, &
                                              seg_ids, n_segs, max_hits)
        TYPE(BVHTree), INTENT(IN) :: tree
        INTEGER(i4), INTENT(IN) :: node_id
        REAL(wp), INTENT(IN) :: point(3)
        REAL(wp), INTENT(IN) :: search_rad
        INTEGER(i4), INTENT(INOUT) :: seg_ids(:)
        INTEGER(i4), INTENT(INOUT) :: n_segs
        INTEGER(i4), INTENT(IN) :: max_hits

        REAL(wp) :: expanded_min(3), expanded_max(3)

        IF (node_id <= 0 .OR. node_id > tree%pop%n_nodes) RETURN
        IF (n_segs >= max_hits) RETURN

        expanded_min = tree%nodes(node_id)%bbox_min - search_rad
        expanded_max = tree%nodes(node_id)%bbox_max + search_rad

        IF (.NOT. md_cont_point_in_aabb(point, expanded_min, expanded_max)) RETURN

        IF (tree%nodes(node_id)%is_leaf) THEN
            n_segs = n_segs + 1
            seg_ids(n_segs) = tree%nodes(node_id)%segment_id
            RETURN
        END IF

        CALL Cont_BVH_query_recursive(tree, tree%nodes(node_id)%left_child, point, &
                                 search_rad, seg_ids, n_segs, max_hits)
        CALL Cont_BVH_query_recursive(tree, tree%nodes(node_id)%right_child, point, &
                                 search_rad, seg_ids, n_segs, max_hits)
    END SUBROUTINE

    !===================================================================
    ! Cont_BVH_tree_build
    !===================================================================
    SUBROUTINE Cont_BVH_tree_build(tree, surf, search_rad)
        TYPE(BVHTree), INTENT(INOUT) :: tree
        TYPE(ContSurface), INTENT(IN) :: surf
        REAL(wp), INTENT(IN) :: search_rad

        INTEGER(i4) :: n_segs, max_nodes
        INTEGER(i4), ALLOCATABLE :: seg_indices(:)
        REAL(wp), ALLOCATABLE :: centroids(:,:)
        INTEGER(i4) :: i

        n_segs = surf%n_segments
        IF (n_segs == 0) RETURN

        max_nodes = 2 * n_segs - 1

        IF (ALLOCATED(tree%nodes)) DEALLOCATE(tree%nodes)
        ALLOCATE(tree%nodes(max_nodes))
        tree%pop%n_nodes = 0

        ALLOCATE(seg_indices(n_segs))
        ALLOCATE(centroids(3, n_segs))

        DO i = 1, n_segs
            seg_indices(i) = i
            centroids(:, i) = surf%segments(i)%centroid
        END DO

        CALL Cont_BVH_build_recursive(tree, surf, seg_indices, centroids, &
                                 1, n_segs, search_rad, tree%root)

        DEALLOCATE(seg_indices)
        DEALLOCATE(centroids)
    END SUBROUTINE

    !===================================================================
    ! Cont_BVH_tree_cleanup
    !===================================================================
    SUBROUTINE Cont_BVH_tree_cleanup(tree)
        TYPE(BVHTree), INTENT(INOUT) :: tree

        IF (ALLOCATED(tree%nodes)) DEALLOCATE(tree%nodes)
        tree%pop%n_nodes = 0
        tree%root = 0
    END SUBROUTINE

    !===================================================================
    ! Cont_BVH_tree_query
    !===================================================================
    SUBROUTINE Cont_BVH_tree_query(tree, point, search_rad, seg_ids, n_segs)
        TYPE(BVHTree), INTENT(IN) :: tree
        REAL(wp), INTENT(IN) :: point(3)
        REAL(wp), INTENT(IN) :: search_rad
        INTEGER(i4), ALLOCATABLE, INTENT(INOUT) :: seg_ids(:)
        INTEGER(i4), INTENT(OUT) :: n_segs

        INTEGER(i4), ALLOCATABLE :: temp_ids(:)
        INTEGER(i4) :: max_hits

        IF (tree%pop%n_nodes == 0 .OR. tree%root == 0) THEN
            n_segs = 0
            RETURN
        END IF

        max_hits = tree%pop%n_nodes
        ALLOCATE(temp_ids(max_hits))
        n_segs = 0

        CALL Cont_BVH_query_recursive(tree, tree%root, point, search_rad, &
                                 temp_ids, n_segs, max_hits)

        IF (ALLOCATED(seg_ids)) DEALLOCATE(seg_ids)
        IF (n_segs > 0) THEN
            ALLOCATE(seg_ids(n_segs))
            seg_ids = temp_ids(1:n_segs)
        END IF

        DEALLOCATE(temp_ids)
    END SUBROUTINE

    !===================================================================
    ! md_cont_get_bucket_range
    !===================================================================
    SUBROUTINE md_cont_get_bucket_range(grid, bbox_min, bbox_max, &
                                 imin, imax, jmin, jmax, kmin, kmax)
        TYPE(BucketGrid), INTENT(IN) :: grid
        REAL(wp), INTENT(IN) :: bbox_min(3)
        REAL(wp), INTENT(IN) :: bbox_max(3)
        INTEGER(i4), INTENT(OUT) :: imin, imax, jmin, jmax, kmin, kmax

        imin = MAX(1, INT((bbox_min(1) - grid%origin(1)) / grid%cell_size(1)) + 1)
        imax = MIN(grid%nx, INT((bbox_max(1) - grid%origin(1)) / grid%cell_size(1)) + 1)

        jmin = MAX(1, INT((bbox_min(2) - grid%origin(2)) / grid%cell_size(2)) + 1)
        jmax = MIN(grid%ny, INT((bbox_max(2) - grid%origin(2)) / grid%cell_size(2)) + 1)

        kmin = MAX(1, INT((bbox_min(3) - grid%origin(3)) / grid%cell_size(3)) + 1)
        kmax = MIN(grid%nz, INT((bbox_max(3) - grid%origin(3)) / grid%cell_size(3)) + 1)
    END SUBROUTINE

    !===================================================================
    ! md_cont_partition_segments
    !===================================================================
    SUBROUTINE md_cont_partition_segments(seg_indices, centroids, start_idx, end_idx, &
                                   axis, split_val, mid)
        INTEGER(i4), INTENT(INOUT) :: seg_indices(:)
        REAL(wp), INTENT(IN) :: centroids(:,:)
        INTEGER(i4), INTENT(IN) :: start_idx, end_idx
        INTEGER(i4), INTENT(IN) :: axis
        REAL(wp), INTENT(IN) :: split_val
        INTEGER(i4), INTENT(OUT) :: mid

        INTEGER(i4) :: left, right, temp_idx

        left = start_idx
        right = end_idx

        DO WHILE (left < right)
            DO WHILE (left < right .AND. centroids(axis, seg_indices(left)) < split_val)
                left = left + 1
            END DO

            DO WHILE (left < right .AND. centroids(axis, seg_indices(right)) >= split_val)
                right = right - 1
            END DO

            IF (left < right) THEN
                temp_idx = seg_indices(left)
                seg_indices(left) = seg_indices(right)
                seg_indices(right) = temp_idx
            END IF
        END DO

        mid = left
    END SUBROUTINE

    !===================================================================
    ! resize_candidates
    !===================================================================
    SUBROUTINE resize_candidates(candidates, n_candidates)
        TYPE(ContCandidate), ALLOCATABLE, INTENT(INOUT) :: candidates(:)
        INTEGER(i4), INTENT(IN) :: n_candidates

        TYPE(ContCandidate), ALLOCATABLE :: temp(:)

        IF (n_candidates > 0 .AND. n_candidates < SIZE(candidates)) THEN
            ALLOCATE(temp(n_candidates))
            temp(1:n_candidates) = candidates(1:n_candidates)
            CALL MOVE_ALLOC(temp, candidates)
        END IF
    END SUBROUTINE

    !===================================================================
    ! store_contact_results
    !===================================================================
    SUBROUTINE store_contact_results(cpair, n_contact, temp_nodes, temp_master, &
                                     temp_state, temp_gaps, temp_normals, &
                                     temp_tangents, temp_xi, ndim)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        INTEGER(i4), INTENT(IN) :: n_contact
        INTEGER(i4), INTENT(IN) :: temp_nodes(:)
        INTEGER(i4), INTENT(IN) :: temp_master(:)
        INTEGER(i4), INTENT(IN) :: temp_state(:)
        REAL(wp), INTENT(IN) :: temp_gaps(:)
        REAL(wp), INTENT(IN) :: temp_normals(:,:)
        REAL(wp), INTENT(IN) :: temp_tangents(:,:)
        REAL(wp), INTENT(IN) :: temp_xi(:,:)
        INTEGER(i4), INTENT(IN) :: ndim

        cpair%n_contact_point = n_contact

        IF (ALLOCATED(cpair%contact_nodes)) DEALLOCATE(cpair%contact_nodes)
        IF (ALLOCATED(cpair%master_elements)) DEALLOCATE(cpair%master_elements)
        IF (ALLOCATED(cpair%contact_state)) DEALLOCATE(cpair%contact_state)
        IF (ALLOCATED(cpair%gaps)) DEALLOCATE(cpair%gaps)
        IF (ALLOCATED(cpair%normals)) DEALLOCATE(cpair%normals)
        IF (ALLOCATED(cpair%tangents)) DEALLOCATE(cpair%tangents)
        IF (ALLOCATED(cpair%xi_local)) DEALLOCATE(cpair%xi_local)

        IF (n_contact > 0) THEN
            ALLOCATE(cpair%contact_nodes(n_contact))
            ALLOCATE(cpair%master_elements(n_contact))
            ALLOCATE(cpair%contact_state(n_contact))
            ALLOCATE(cpair%gaps(n_contact))
            ALLOCATE(cpair%normals(ndim, n_contact))
            ALLOCATE(cpair%tangents(ndim, n_contact))
            ALLOCATE(cpair%xi_local(2, n_contact))

            cpair%contact_nodes = temp_nodes(1:n_contact)
            cpair%master_elements = temp_master(1:n_contact)
            cpair%contact_state = temp_state(1:n_contact)
            cpair%gaps = temp_gaps(1:n_contact)
            cpair%normals = temp_normals(:, 1:n_contact)
            cpair%tangents = temp_tangents(:, 1:n_contact)
            cpair%xi_local = temp_xi(:, 1:n_contact)
        END IF
    END SUBROUTINE

    !===================================================================
    ! contact_detect
    !===================================================================
    SUBROUTINE contact_detect(cpair, slave_coords, slave_nodes, n_slave, &
                               master_coords, master_elems, n_master_elemen, &
                               n_contact, ierr)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        REAL(wp), INTENT(IN) :: slave_coords(:,:)
        INTEGER(i4), INTENT(IN) :: slave_nodes(:)
        INTEGER(i4), INTENT(IN) :: n_slave
        REAL(wp), INTENT(IN) :: master_coords(:,:)
        INTEGER(i4), INTENT(IN) :: master_elems(:,:)
        INTEGER(i4), INTENT(IN) :: n_master_elemen
        INTEGER(i4), INTENT(OUT) :: n_contact
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        IF (PRESENT(ierr)) ierr = 0

        IF (cpair%dimension == 2) THEN
            CALL contact_detect_2d(cpair, slave_coords, slave_nodes, n_slave, &
                                   master_coords, master_elems, n_master_elemen, &
                                   n_contact, ierr)
        ELSE
            CALL contact_detect_3d(cpair, slave_coords, slave_nodes, n_slave, &
                                   master_coords, master_elems, n_master_elemen, &
                                   n_contact, ierr)
        END IF
    END SUBROUTINE

    !===================================================================
    ! contact_detect_2d
    !===================================================================
    SUBROUTINE contact_detect_2d(cpair, slave_coords, slave_nodes, n_slave, &
                                  master_coords, master_elems, n_master_elemen, &
                                  n_contact, ierr)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        REAL(wp), INTENT(IN) :: slave_coords(:,:)
        INTEGER(i4), INTENT(IN) :: slave_nodes(:)
        INTEGER(i4), INTENT(IN) :: n_slave
        REAL(wp), INTENT(IN) :: master_coords(:,:)
        INTEGER(i4), INTENT(IN) :: master_elems(:,:)
        INTEGER(i4), INTENT(IN) :: n_master_elemen
        INTEGER(i4), INTENT(OUT) :: n_contact
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        INTEGER(i4) :: is, ie, n_alloc
        REAL(wp) :: slave_pt(2), gap, xi_param
        REAL(wp) :: normal(2), tangent(2), proj_pt(2)
        REAL(wp) :: tol, min_gap
        INTEGER(i4) :: best_element
        LOGICAL :: in_contact

        INTEGER(i4), ALLOCATABLE :: temp_nodes(:)
        INTEGER(i4), ALLOCATABLE :: temp_master(:)
        INTEGER(i4), ALLOCATABLE :: temp_state(:)
        REAL(wp), ALLOCATABLE :: temp_gaps(:)
        REAL(wp), ALLOCATABLE :: temp_normals(:,:)
        REAL(wp), ALLOCATABLE :: temp_tangents(:,:)
        REAL(wp), ALLOCATABLE :: temp_xi(:,:)

        IF (PRESENT(ierr)) ierr = 0
        tol = cpair%gap_tolerance
        n_contact = 0

        n_alloc = n_slave
        ALLOCATE(temp_nodes(n_alloc), temp_master(n_alloc), temp_state(n_alloc))
        ALLOCATE(temp_gaps(n_alloc))
        ALLOCATE(temp_normals(2, n_alloc), temp_tangents(2, n_alloc))
        ALLOCATE(temp_xi(2, n_alloc))

        DO is = 1, n_slave
            slave_pt(1) = slave_coords(1, is)
            slave_pt(2) = slave_coords(2, is)

            min_gap = HUGE(1.0_wp)
            best_element = 0

            DO ie = 1, n_master_elemen
                CALL project_point_to_segment_2d(slave_pt, master_coords, master_elems(:, ie), &
                                                  proj_pt, normal, tangent, gap, xi_param, in_contact, tol)

                IF (ABS(gap) < ABS(min_gap) .AND. xi_param >= -1.0_wp - 0.01_wp .AND. &
                    xi_param <= 1.0_wp + 0.01_wp) THEN
                    min_gap = gap
                    best_element = ie
                    temp_normals(:, n_contact+1) = normal
                    temp_tangents(:, n_contact+1) = tangent
                    temp_xi(1, n_contact+1) = xi_param
                    temp_xi(2, n_contact+1) = 0.0_wp
                END IF
            END DO

            IF (best_element > 0 .AND. min_gap <= tol) THEN
                n_contact = n_contact + 1
                temp_nodes(n_contact) = slave_nodes(is)
                temp_master(n_contact) = best_element
                temp_gaps(n_contact) = min_gap
                temp_state(n_contact) = CSTATE_STICKING
            END IF
        END DO

        CALL store_contact_results(cpair, n_contact, temp_nodes, temp_master, &
                                    temp_state, temp_gaps, temp_normals, &
                                    temp_tangents, temp_xi, 2)

        DEALLOCATE(temp_nodes, temp_master, temp_state, temp_gaps)
        DEALLOCATE(temp_normals, temp_tangents, temp_xi)
    END SUBROUTINE

    !===================================================================
    ! contact_detect_3d
    !===================================================================
    SUBROUTINE contact_detect_3d(cpair, slave_coords, slave_nodes, n_slave, &
                                  master_coords, master_elems, n_master_elemen, &
                                  n_contact, ierr)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        REAL(wp), INTENT(IN) :: slave_coords(:,:)
        INTEGER(i4), INTENT(IN) :: slave_nodes(:)
        INTEGER(i4), INTENT(IN) :: n_slave
        REAL(wp), INTENT(IN) :: master_coords(:,:)
        INTEGER(i4), INTENT(IN) :: master_elems(:,:)
        INTEGER(i4), INTENT(IN) :: n_master_elemen
        INTEGER(i4), INTENT(OUT) :: n_contact
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr

        INTEGER(i4) :: is, ie, n_alloc, n_nodes_per_ele
        REAL(wp) :: slave_pt(3), gap, xi_param(2)
        REAL(wp) :: normal(3), tangent1(3), tangent2(3), proj_pt(3)
        REAL(wp) :: tol, min_gap
        INTEGER(i4) :: best_element
        LOGICAL :: in_contact, converged

        INTEGER(i4), ALLOCATABLE :: temp_nodes(:)
        INTEGER(i4), ALLOCATABLE :: temp_master(:)
        INTEGER(i4), ALLOCATABLE :: temp_state(:)
        REAL(wp), ALLOCATABLE :: temp_gaps(:)
        REAL(wp), ALLOCATABLE :: temp_normals(:,:)
        REAL(wp), ALLOCATABLE :: temp_tangents(:,:)
        REAL(wp), ALLOCATABLE :: temp_xi(:,:)

        IF (PRESENT(ierr)) ierr = 0
        tol = cpair%gap_tolerance
        n_contact = 0
        n_nodes_per_ele = SIZE(master_elems, 1)

        n_alloc = n_slave
        ALLOCATE(temp_nodes(n_alloc), temp_master(n_alloc), temp_state(n_alloc))
        ALLOCATE(temp_gaps(n_alloc))
        ALLOCATE(temp_normals(3, n_alloc), temp_tangents(3, n_alloc))
        ALLOCATE(temp_xi(2, n_alloc))

        DO is = 1, n_slave
            slave_pt = slave_coords(:, is)

            min_gap = HUGE(1.0_wp)
            best_element = 0

            DO ie = 1, n_master_elemen
                CALL project_point_to_quad_3d(slave_pt, master_coords, master_elems(:, ie), &
                                              proj_pt, normal, tangent1, tangent2, gap, xi_param, &
                                              converged, tol)

                IF (converged .AND. ABS(gap) < ABS(min_gap)) THEN
                    min_gap = gap
                    best_element = ie
                    temp_normals(:, n_contact+1) = normal
                    temp_tangents(:, n_contact+1) = tangent1
                    temp_xi(:, n_contact+1) = xi_param
                END IF
            END DO

            IF (best_element > 0 .AND. min_gap <= tol) THEN
                n_contact = n_contact + 1
                temp_nodes(n_contact) = slave_nodes(is)
                temp_master(n_contact) = best_element
                temp_gaps(n_contact) = min_gap
                temp_state(n_contact) = CSTATE_STICKING
            END IF
        END DO

        CALL store_contact_results(cpair, n_contact, temp_nodes, temp_master, &
                                    temp_state, temp_gaps, temp_normals, &
                                    temp_tangents, temp_xi, 3)

        DEALLOCATE(temp_nodes, temp_master, temp_state, temp_gaps)
        DEALLOCATE(temp_normals, temp_tangents, temp_xi)
    END SUBROUTINE

    !===================================================================
    ! Co_Se_fi_candidates  (PUBLIC: Cont_Search_find_candidates)
    !===================================================================
    SUBROUTINE Co_Se_fi_candidates(master_surf, slave_surf, pair, &
                                       candidates, n_candidates, algorithm, &
                                       preallocated_se, preallocated_te)
        TYPE(ContSurface), INTENT(IN) :: master_surf
        TYPE(ContSurface), INTENT(IN) :: slave_surf
        TYPE(ContPairDef), INTENT(IN) :: pair
        TYPE(ContCandidate), ALLOCATABLE, INTENT(INOUT) :: candidates(:)
        INTEGER(i4), INTENT(OUT) :: n_candidates
        INTEGER(i4), INTENT(IN), OPTIONAL :: algorithm
        INTEGER(i4), INTENT(IN), OPTIONAL, TARGET :: preallocated_se(:)
        TYPE(ContCandidate), INTENT(IN), OPTIONAL, TARGET :: preallocated_te(:)

        INTEGER(i4) :: alg

        alg = 1
        IF (PRESENT(algorithm)) alg = algorithm

        SELECT CASE (alg)
        CASE (0)
            CALL brute_force_search(master_surf, slave_surf, pair, &
                                    candidates, n_candidates, &
                                    preallocated_te=preallocated_te)
        CASE (1)
            CALL Cont_Bucket_search(master_surf, slave_surf, pair, &
                              candidates, n_candidates, &
                              preallocated_se=preallocated_se)
        CASE DEFAULT
            CALL Cont_Bucket_search(master_surf, slave_surf, pair, &
                              candidates, n_candidates, &
                              preallocated_se=preallocated_se)
        END SELECT
    END SUBROUTINE

    !===================================================================
    ! Cont_Search_global_init
    !===================================================================
    SUBROUTINE Cont_Search_global_init(master_surf, slave_surf, pair, search_tol)
        TYPE(ContSurface), INTENT(INOUT) :: master_surf
        TYPE(ContSurface), INTENT(INOUT) :: slave_surf
        TYPE(ContPairDef), INTENT(INOUT) :: pair
        REAL(wp), INTENT(IN), OPTIONAL :: search_tol

        REAL(wp) :: tol

        tol = SEARCH_TOL_DEFA
        IF (PRESENT(search_tol)) tol = search_tol
        pair%search_toleranc = tol

        ! Cross-module call to Manager: Co_Su_Co_bb_internal
        ! Resolved at thin-layer level; here we inline the bbox logic
        CALL compute_bbox_internal_local(master_surf, tol)
        CALL compute_bbox_internal_local(slave_surf, tol)
    END SUBROUTINE

    !===================================================================
    ! Cont_Search_local_update
    !===================================================================
    SUBROUTINE Cont_Search_local_update(cpair, master_surf, slave_surf, disp, dof_map, ndof)
        TYPE(ContPair), INTENT(INOUT) :: cpair
        TYPE(ContSurface), INTENT(INOUT) :: master_surf
        TYPE(ContSurface), INTENT(INOUT) :: slave_surf
        REAL(wp), INTENT(IN) :: disp(:)
        INTEGER(i4), INTENT(IN) :: dof_map(:,:)
        INTEGER(i4), INTENT(IN) :: ndof

        ! Cross-module call to Manager: Co_Su_up_coords
        ! Resolved by inlining update_coords logic
        CALL update_coords_local(master_surf, disp, dof_map, ndof)
        CALL update_coords_local(slave_surf, disp, dof_map, ndof)
    END SUBROUTINE

    !===================================================================
    ! Co_Se_up_tracking  (PUBLIC: Cont_Search_update_tracking)
    !===================================================================
    SUBROUTINE Co_Se_up_tracking(master_surf, node, pair)
        TYPE(ContSurface), INTENT(IN) :: master_surf
        TYPE(ContNode), INTENT(INOUT) :: node
        TYPE(ContPairDef), INTENT(IN) :: pair

        INTEGER(i4) :: seg, new_seg
        REAL(wp) :: xi, best_gap, gap
        REAL(wp) :: xi_local(2)

        seg = node%matched_segment
        IF (seg <= 0) RETURN

        xi = node%xi_local(1)

        IF (xi < -1.0_wp .OR. xi > 1.0_wp) THEN
            IF (xi < -1.0_wp) THEN
                new_seg = seg - 1
                IF (new_seg < 1) new_seg = 1
            ELSE
                new_seg = seg + 1
                IF (new_seg > master_surf%n_segments) new_seg = master_surf%n_segments
            END IF

            CALL Compute_gap_to_segment_2d(master_surf, new_seg, node%coords, &
                                           gap, xi_local)
            CALL Compute_gap_to_segment_2d(master_surf, seg, node%coords, &
                                           best_gap, node%xi_local)

            IF (ABS(gap) < ABS(best_gap)) THEN
                node%matched_segment = new_seg
                node%gap = gap
                node%xi_local = xi_local
            END IF
        END IF
    END SUBROUTINE

    !===================================================================
    ! project_point_to_segment_2d (private helper used by detect_2d)
    !===================================================================
    SUBROUTINE project_point_to_segment_2d(slave_pt, master_coords, master_element, &
                                            proj_pt, normal, tangent, gap, xi_param, in_contact, tol)
        REAL(wp), INTENT(IN) :: slave_pt(2)
        REAL(wp), INTENT(IN) :: master_coords(:,:)
        INTEGER(i4), INTENT(IN) :: master_element(:)
        REAL(wp), INTENT(OUT) :: proj_pt(2)
        REAL(wp), INTENT(OUT) :: normal(2)
        REAL(wp), INTENT(OUT) :: tangent(2)
        REAL(wp), INTENT(OUT) :: gap
        REAL(wp), INTENT(OUT) :: xi_param
        LOGICAL, INTENT(OUT) :: in_contact
        REAL(wp), INTENT(IN) :: tol

        REAL(wp) :: P_A(2), P_B(2), seg_vec(2), pt_vec(2)
        REAL(wp) :: seg_len, t_param
        REAL(wp), PARAMETER :: GEOM_TOL = 1.0E-12_wp

        P_A = master_coords(:, master_element(1))
        P_B = master_coords(:, master_element(2))

        seg_vec = P_B - P_A
        seg_len = SQRT(seg_vec(1)**2 + seg_vec(2)**2)

        IF (seg_len < GEOM_TOL) THEN
            xi_param = 0.0_wp
            proj_pt = P_A
            in_contact = .FALSE.
            gap = 0.0_wp
            normal = 0.0_wp
            tangent = 0.0_wp
            RETURN
        END IF

        pt_vec = slave_pt - P_A
        t_param = (pt_vec(1)*seg_vec(1) + pt_vec(2)*seg_vec(2)) / (seg_len * seg_len)
        xi_param = 2.0_wp * t_param - 1.0_wp

        in_contact = (xi_param >= -1.0_wp - GEOM_TOL .AND. xi_param <= 1.0_wp + GEOM_TOL)

        t_param = MAX(0.0_wp, MIN(1.0_wp, t_param))
        proj_pt = P_A + t_param * seg_vec

        tangent = seg_vec / seg_len
        normal(1) = -tangent(2)
        normal(2) = tangent(1)

        gap = (slave_pt(1) - proj_pt(1)) * normal(1) + (slave_pt(2) - proj_pt(2)) * normal(2)
    END SUBROUTINE

    !===================================================================
    ! project_point_to_quad_3d (private helper used by detect_3d)
    !===================================================================
    SUBROUTINE project_point_to_quad_3d(slave_pt, master_coords, master_element, &
                                         proj_pt, normal, tangent1, tangent2, gap, xi_param, converged, tol)
        USE MD_Int_Convert, ONLY: Co_Ge_pr_po_3d, Co_Ge_Co_no_3d, Co_Ge_Co_ta_3d
        REAL(wp), INTENT(IN) :: slave_pt(3)
        REAL(wp), INTENT(IN) :: master_coords(:,:)
        INTEGER(i4), INTENT(IN) :: master_element(:)
        REAL(wp), INTENT(OUT) :: proj_pt(3)
        REAL(wp), INTENT(OUT) :: normal(3)
        REAL(wp), INTENT(OUT) :: tangent1(3), tangent2(3)
        REAL(wp), INTENT(OUT) :: gap
        REAL(wp), INTENT(OUT) :: xi_param(2)
        LOGICAL, INTENT(OUT) :: converged
        REAL(wp), INTENT(IN) :: tol

        REAL(wp) :: P_nodes(3,4)
        INTEGER(i4) :: i

        DO i = 1, 4
            P_nodes(:, i) = master_coords(:, master_element(i))
        END DO

        CALL Co_Ge_pr_po_3d(slave_pt, P_nodes, xi_param(1), xi_param(2), proj_pt, converged)

        CALL Co_Ge_Co_no_3d(P_nodes, xi_param(1), xi_param(2), normal)
        CALL Co_Ge_Co_ta_3d(P_nodes, xi_param(1), xi_param(2), tangent1, tangent2)

        gap = SUM((slave_pt - proj_pt) * normal)
    END SUBROUTINE

    !===================================================================
    ! compute_bbox_internal_local  (private - inlined from Manager)
    !===================================================================
    SUBROUTINE compute_bbox_internal_local(surf, tolerance)
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
    ! update_coords_local  (private - inlined from Manager)
    !===================================================================
    SUBROUTINE update_coords_local(surf, disp, dof_map, ndof)
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

END MODULE MD_Int_Detect
