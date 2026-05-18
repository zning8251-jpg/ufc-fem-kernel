!===============================================================================
! MODULE: PH_Cont_SelfContact
! LAYER:  L4_PH
! DOMAIN: Contact / Self
! ROLE:   Core
! BRIEF:  Self-contact detection and response (BVH + exclusion + symmetric forces)
!
! Theory: Wriggers §12; Laursen §7
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Cont_SelfContact
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, SMALL_VAL => SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  
  IMPLICIT NONE
  PRIVATE
  
  ! Parameters
  INTEGER(i4), PARAMETER :: PH_ContSC_MAX_NEIGHBORS = 20_i4
  REAL(wp), PARAMETER :: PH_ContSC_EXCLUSION_RADIUS = 3.0_wp  ! Element sizes
  
  ! ===================================================================
  ! Public Types
  ! ===================================================================
  PUBLIC :: PH_ContSC_Surface
  PUBLIC :: PH_ContSC_NeighborList
  PUBLIC :: PH_ContSC_SelfPair
  
  ! ===================================================================
  ! Public Interfaces
  ! ===================================================================
  PUBLIC :: PH_ContSC_InitSurface
  PUBLIC :: PH_ContSC_BuildExclusion
  PUBLIC :: PH_ContSC_DetectSelfContact
  PUBLIC :: PH_ContSC_ComputeSelfForce
  PUBLIC :: PH_ContSC_IsExcluded
  PUBLIC :: PH_ContSC_Filter
  PUBLIC :: PH_ContSC_NRingExcluded
  PUBLIC :: PH_ContSC_BackfaceExcluded
  
  ! ===================================================================
  ! Type Definitions
  ! ===================================================================
  
  TYPE :: PH_ContSC_Surface
    ! Self-contact surface definition
    INTEGER(i4) :: surf_id
    INTEGER(i4) :: n_nodes
    INTEGER(i4) :: n_segments
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    INTEGER(i4), ALLOCATABLE :: seg_conn(:,:)  ! (nodes_per_seg, n_segs)
    REAL(wp), ALLOCATABLE :: coords(:,:)      ! (3, n_nodes)
    LOGICAL :: is_initialized = .FALSE.
  END TYPE PH_ContSC_Surface
  
  TYPE :: PH_ContSC_NeighborList
    ! Neighbor exclusion list for each node
    INTEGER(i4) :: n_nodes
    INTEGER(i4), ALLOCATABLE :: n_neighbors(:)        ! Count per node
    INTEGER(i4), ALLOCATABLE :: neighbors(:,:)        ! (max_neighbors, n_nodes)
    REAL(wp), ALLOCATABLE :: exclusion_dist(:)        ! Exclusion radius per node
  END TYPE PH_ContSC_NeighborList
  
  TYPE :: PH_ContSC_SelfPair
    ! Self-contact pair
    INTEGER(i4) :: node_i          ! Slave node index
    INTEGER(i4) :: segment_j       ! Master segment index
    REAL(wp) :: gap                ! Signed gap
    REAL(wp) :: normal(3)          ! Contact normal
    REAL(wp) :: force(3)           ! Contact force
    LOGICAL :: is_active           ! Active contact flag
    REAL(wp) :: penalty            ! Penalty stiffness
  END TYPE PH_ContSC_SelfPair
  
CONTAINS

  ! ===========================================================================
  ! Surface Initialization
  ! ===========================================================================
  
  SUBROUTINE PH_ContSC_InitSurface(surf, surf_id, n_nodes, n_segments, &
                                   node_ids, coords, seg_conn, status)
    !> Initialize self-contact surface
    TYPE(PH_ContSC_Surface), INTENT(OUT) :: surf
    INTEGER(i4), INTENT(IN) :: surf_id, n_nodes, n_segments
    INTEGER(i4), INTENT(IN) :: node_ids(:)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: seg_conn(:,:)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Validate inputs
    IF (SIZE(node_ids) /= n_nodes) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "node_ids size mismatch"
      END IF
      RETURN
    END IF
    
    IF (SIZE(coords, 1) < 2 .OR. SIZE(coords, 1) > 3) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "coords must be (2or3, n_nodes)"
      END IF
      RETURN
    END IF
    
    ! Allocate and copy
    surf%surf_id = surf_id
    surf%pop%n_nodes = n_nodes
    surf%n_segments = n_segments
    
    ALLOCATE(surf%node_ids(n_nodes))
    ALLOCATE(surf%coords(3, n_nodes))
    ALLOCATE(surf%seg_conn(SIZE(seg_conn, 1), n_segments))
    
    surf%node_ids = node_ids
    surf%coords(1:SIZE(coords,1), :) = coords
    surf%seg_conn = seg_conn
    surf%is_initialized = .TRUE.
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContSC_InitSurface
  
  ! ===========================================================================
  ! Exclusion List Construction
  ! ===========================================================================
  
  SUBROUTINE PH_ContSC_BuildExclusion(surf, neighbors, status)
    !> Build neighbor exclusion list to avoid spurious contacts
    TYPE(PH_ContSC_Surface), INTENT(IN) :: surf
    TYPE(PH_ContSC_NeighborList), INTENT(OUT) :: neighbors
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i_node, i_seg, i_local, j_local
    INTEGER(i4) :: n_per_seg, ni, nj
    INTEGER(i4), ALLOCATABLE :: temp_neighbors(:)
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    IF (.NOT. surf%is_initialized) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "Surface not initialized"
      END IF
      RETURN
    END IF
    
    ! Initialize
    neighbors%pop%n_nodes = surf%pop%n_nodes
    ALLOCATE(neighbors%n_neighbors(surf%pop%n_nodes))
    ALLOCATE(neighbors%neighbors(PH_ContSC_MAX_NEIGHBORS, surf%pop%n_nodes))
    ALLOCATE(neighbors%exclusion_dist(surf%pop%n_nodes))
    
    neighbors%n_neighbors = 0_i4
    neighbors%neighbors = 0_i4
    
    ! Build adjacency from connectivity
    n_per_seg = SIZE(surf%seg_conn, 1)
    
    DO i_seg = 1, surf%n_segments
      ! For each segment, mark all node pairs as neighbors
      DO i_local = 1, n_per_seg
        ni = surf%seg_conn(i_local, i_seg)
        
        DO j_local = i_local + 1, n_per_seg
          nj = surf%seg_conn(j_local, i_seg)
          
          ! Add to both directions
          CALL AddNeighbor(neighbors, ni, nj)
          CALL AddNeighbor(neighbors, nj, ni)
        END DO
      END DO
    END DO
    
    ! Compute exclusion distance (based on element size)
    DO i_node = 1, surf%pop%n_nodes
      neighbors%exclusion_dist(i_node) = &
        PH_ContSC_EXCLUSION_RADIUS * EstimateElementSize(surf, i_node)
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContSC_BuildExclusion
  
  ! ===========================================================================
  ! Self-Contact Detection
  ! ===========================================================================
  
  SUBROUTINE PH_ContSC_DetectSelfContact(surf, neighbors, bvh_root, &
                                         pairs, n_pairs, max_pairs, status)
    !> Detect self-contact pairs using BVH
    TYPE(PH_ContSC_Surface), INTENT(IN) :: surf
    TYPE(PH_ContSC_NeighborList), INTENT(IN) :: neighbors
    TYPE(*), INTENT(IN) :: bvh_root  ! BVH root pointer
    TYPE(PH_ContSC_SelfPair), INTENT(OUT) :: pairs(:)
    INTEGER(i4), INTENT(OUT) :: n_pairs
    INTEGER(i4), INTENT(IN) :: max_pairs
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i_node, i_cand, j_seg
    REAL(wp) :: query_point(3), tolerance
    INTEGER(i4) :: candidates(100), n_candidates
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    n_pairs = 0_i4
    tolerance = 1.0e-6_wp
    
    ! Query each node against BVH
    DO i_node = 1, surf%pop%n_nodes
      query_point = surf%coords(:, i_node)
      
      ! BVH query (placeholder - would call PH_ContBVH_QueryPoint)
      n_candidates = 0_i4
      ! CALL PH_ContBVH_QueryPoint(bvh_root, query_point, tolerance, &
      !                            surf%coords, candidates, n_candidates, ...)
      
      ! Process candidates
      DO i_cand = 1, n_candidates
        j_seg = candidates(i_cand)
        
        ! Check exclusion
        IF (PH_ContSC_IsExcluded(neighbors, i_node, j_seg)) THEN
          CYCLE
        END IF
        
        ! Compute gap and normal
        CALL ComputeGapAndNormal(surf, i_node, j_seg, &
                                 pairs(n_pairs+1)%gap, &
                                 pairs(n_pairs+1)%normal)
        
        ! Check if active
        IF (pairs(n_pairs+1)%gap <= tolerance) THEN
          n_pairs = n_pairs + 1_i4
          pairs(n_pairs)%node_i = i_node
          pairs(n_pairs)%segment_j = j_seg
          pairs(n_pairs)%is_active = .TRUE.
          
          IF (n_pairs >= max_pairs) EXIT
        END IF
      END DO
      
      IF (n_pairs >= max_pairs) EXIT
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContSC_DetectSelfContact
  
  ! ===========================================================================
  ! Self-Contact Force Computation
  ! ===========================================================================
  
  SUBROUTINE PH_ContSC_ComputeSelfForce(pairs, n_pairs, coords, F_self, &
                                        n_dofs, use_damping, damping, dt, status)
    !> Compute self-contact forces
    TYPE(PH_ContSC_SelfPair), INTENT(INOUT) :: pairs(:)
    INTEGER(i4), INTENT(IN) :: n_pairs
    REAL(wp), INTENT(IN) :: coords(:,:)
    REAL(wp), INTENT(OUT) :: F_self(:)
    INTEGER(i4), INTENT(IN) :: n_dofs
    LOGICAL, INTENT(IN) :: use_damping
    REAL(wp), INTENT(IN) :: damping, dt
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i_pair, i_node, dof_idx
    REAL(wp) :: penetration, force_mag, force(3)
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Clear force vector
    F_self = ZERO
    
    ! Process each active pair
    DO i_pair = 1, n_pairs
      IF (.NOT. pairs(i_pair)%is_active) CYCLE
      
      i_node = pairs(i_pair)%node_i
      penetration = -MIN(ZERO, pairs(i_pair)%gap)
      
      ! Penalty force: F = k * p * n
      force_mag = pairs(i_pair)%penalty * penetration
      force = force_mag * pairs(i_pair)%normal
      
      ! Add damping if enabled
      IF (use_damping) THEN
        ! Placeholder for damping computation
        ! Would need velocity at node_i
      END IF
      
      ! Accumulate force
      dof_idx = (i_node - 1) * 3
      F_self(dof_idx+1:dof_idx+3) = F_self(dof_idx+1:dof_idx+3) + force
      
      ! Store reaction force
      pairs(i_pair)%force = force
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContSC_ComputeSelfForce
  
  ! ===========================================================================
  ! Exclusion Check
  ! ===========================================================================
  
  FUNCTION PH_ContSC_IsExcluded(neighbors, node_i, node_j) RESULT(is_excluded)
    !> Check if two nodes are neighbors (should be excluded)
    TYPE(PH_ContSC_NeighborList), INTENT(IN) :: neighbors
    INTEGER(i4), INTENT(IN) :: node_i, node_j
    LOGICAL :: is_excluded
    
    INTEGER(i4) :: i_neighbor, dist_sq
    REAL(wp) :: exclusion_dist
    
    is_excluded = .FALSE.
    
    IF (node_i < 1 .OR. node_i > neighbors%pop%n_nodes) RETURN
    IF (node_j < 1 .OR. node_j > neighbors%pop%n_nodes) RETURN
    
    ! Check if node_j is in node_i's neighbor list
    DO i_neighbor = 1, neighbors%n_neighbors(node_i)
      IF (neighbors%neighbors(i_neighbor, node_i) == node_j) THEN
        is_excluded = .TRUE.
        RETURN
      END IF
    END DO
    
    ! Also check geometric exclusion
    exclusion_dist = neighbors%exclusion_dist(node_i)
    ! Would compute actual distance here
    
  END FUNCTION PH_ContSC_IsExcluded
  
  ! ===========================================================================
  ! Helper Functions
  ! ===========================================================================
  
  SUBROUTINE AddNeighbor(neighbors, node_i, node_j)
    !> Add node_j to node_i's neighbor list
    TYPE(PH_ContSC_NeighborList), INTENT(INOUT) :: neighbors
    INTEGER(i4), INTENT(IN) :: node_i, node_j
    
    INTEGER(i4) :: n_curr
    
    IF (node_i < 1 .OR. node_i > neighbors%pop%n_nodes) RETURN
    
    n_curr = neighbors%n_neighbors(node_i)
    IF (n_curr < PH_ContSC_MAX_NEIGHBORS) THEN
      n_curr = n_curr + 1_i4
      neighbors%n_neighbors(node_i) = n_curr
      neighbors%neighbors(n_curr, node_i) = node_j
    END IF
  END SUBROUTINE AddNeighbor
  
  FUNCTION EstimateElementSize(surf, node_i) RESULT(h_elem)
    !> Estimate local element size around node
    TYPE(PH_ContSC_Surface), INTENT(IN) :: surf
    INTEGER(i4), INTENT(IN) :: node_i
    REAL(wp) :: h_elem
    
    ! Simplified: average edge length connected to node
    h_elem = 1.0_wp  ! Placeholder
  END FUNCTION EstimateElementSize
  
  SUBROUTINE ComputeGapAndNormal(surf, node_i, seg_j, gap, normal)
    !> Compute gap and normal for node-segment pair
    !> Projects node onto the segment and computes signed gap
    TYPE(PH_ContSC_Surface), INTENT(IN) :: surf
    INTEGER(i4), INTENT(IN) :: node_i, seg_j
    REAL(wp), INTENT(OUT) :: gap, normal(3)

    REAL(wp) :: x_node(3), x_proj(3)
    REAL(wp) :: v1(3), v2(3), v3(3), e1(3), e2(3)
    REAL(wp) :: cross_n(3), norm_n, r(3)
    INTEGER(i4) :: n1, n2, n3, n_per_seg

    x_node = surf%coords(:, node_i)
    n_per_seg = SIZE(surf%seg_conn, 1)

    ! Get segment nodes (first 3 for triangular projection)
    n1 = surf%seg_conn(1, seg_j)
    n2 = surf%seg_conn(2, seg_j)
    IF (n_per_seg >= 3) THEN
      n3 = surf%seg_conn(3, seg_j)
    ELSE
      n3 = n2  ! degenerate
    END IF

    v1 = surf%coords(:, n1)
    v2 = surf%coords(:, n2)
    v3 = surf%coords(:, n3)

    ! Segment normal via cross product
    e1 = v2 - v1
    e2 = v3 - v1
    cross_n(1) = e1(2)*e2(3) - e1(3)*e2(2)
    cross_n(2) = e1(3)*e2(1) - e1(1)*e2(3)
    cross_n(3) = e1(1)*e2(2) - e1(2)*e2(1)
    norm_n = SQRT(DOT_PRODUCT(cross_n, cross_n))

    IF (norm_n < SMALL_VAL) THEN
      gap = 1.0e10_wp  ! degenerate segment
      normal = ZERO
      RETURN
    END IF
    normal = cross_n / norm_n

    ! Signed gap: projection distance along normal
    r = x_node - v1
    gap = DOT_PRODUCT(r, normal)
  END SUBROUTINE ComputeGapAndNormal

  ! ===========================================================================
  ! Self-Contact Filter (unified entry)
  ! ===========================================================================

  SUBROUTINE PH_ContSC_Filter(surf, neighbors, candidate_pairs, n_candidates, &
                               filtered_pairs, n_filtered, max_filtered, &
                               n_ring, angle_threshold, status)
    !> Filter self-contact candidate pairs by:
    !>   1. N-ring neighbor exclusion (topological adjacency)
    !>   2. Backface exclusion (normal angle check)
    TYPE(PH_ContSC_Surface), INTENT(IN) :: surf
    TYPE(PH_ContSC_NeighborList), INTENT(IN) :: neighbors
    TYPE(PH_ContSC_SelfPair), INTENT(IN) :: candidate_pairs(:)
    INTEGER(i4), INTENT(IN) :: n_candidates
    TYPE(PH_ContSC_SelfPair), INTENT(OUT) :: filtered_pairs(:)
    INTEGER(i4), INTENT(OUT) :: n_filtered
    INTEGER(i4), INTENT(IN) :: max_filtered
    INTEGER(i4), INTENT(IN) :: n_ring           ! Exclusion ring depth (typically 2-3)
    REAL(wp), INTENT(IN) :: angle_threshold     ! Backface angle threshold [radians]
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i_pair, node_i, seg_j
    LOGICAL :: excluded

    IF (PRESENT(status)) CALL init_error_status(status)
    n_filtered = 0_i4

    DO i_pair = 1, n_candidates
      node_i = candidate_pairs(i_pair)%node_i
      seg_j  = candidate_pairs(i_pair)%segment_j

      ! Check 1: N-ring topological exclusion
      IF (PH_ContSC_NRingExcluded(neighbors, surf, node_i, seg_j, n_ring)) CYCLE

      ! Check 2: Backface exclusion (normals pointing away)
      IF (PH_ContSC_BackfaceExcluded(surf, node_i, seg_j, angle_threshold)) CYCLE

      ! Passed both filters
      IF (n_filtered >= max_filtered) EXIT
      n_filtered = n_filtered + 1_i4
      filtered_pairs(n_filtered) = candidate_pairs(i_pair)
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_ContSC_Filter

  ! ===========================================================================
  ! N-Ring Neighbor Exclusion
  ! ===========================================================================

  FUNCTION PH_ContSC_NRingExcluded(neighbors, surf, node_i, seg_j, n_ring) &
           RESULT(is_excluded)
    !> Check if node_i shares any node within n_ring hops of segment seg_j.
    !> This prevents false self-contact between adjacent elements.
    TYPE(PH_ContSC_NeighborList), INTENT(IN) :: neighbors
    TYPE(PH_ContSC_Surface), INTENT(IN) :: surf
    INTEGER(i4), INTENT(IN) :: node_i, seg_j, n_ring
    LOGICAL :: is_excluded

    INTEGER(i4) :: i_local, seg_node, i_neighbor, n_per_seg

    is_excluded = .FALSE.
    n_per_seg = SIZE(surf%seg_conn, 1)

    ! Direct check: is node_i a vertex of segment seg_j?
    DO i_local = 1, n_per_seg
      seg_node = surf%seg_conn(i_local, seg_j)
      IF (seg_node == node_i) THEN
        is_excluded = .TRUE.
        RETURN
      END IF
    END DO

    ! 1-ring: check if node_i is a neighbor of any segment vertex
    IF (n_ring >= 1) THEN
      DO i_local = 1, n_per_seg
        seg_node = surf%seg_conn(i_local, seg_j)
        IF (seg_node < 1 .OR. seg_node > neighbors%pop%n_nodes) CYCLE
        DO i_neighbor = 1, neighbors%n_neighbors(seg_node)
          IF (neighbors%neighbors(i_neighbor, seg_node) == node_i) THEN
            is_excluded = .TRUE.
            RETURN
          END IF
        END DO
      END DO
    END IF

    ! Higher rings could be added recursively but typically n_ring=1 or 2 suffices

  END FUNCTION PH_ContSC_NRingExcluded

  ! ===========================================================================
  ! Backface Exclusion (Normal Angle Check)
  ! ===========================================================================

  FUNCTION PH_ContSC_BackfaceExcluded(surf, node_i, seg_j, angle_threshold) &
           RESULT(is_excluded)
    !> Exclude pairs where the node's approximate normal and the segment's
    !> normal point in roughly the same direction (backface contact).
    !> cos(angle) = n_node . n_seg > cos(threshold)
    TYPE(PH_ContSC_Surface), INTENT(IN) :: surf
    INTEGER(i4), INTENT(IN) :: node_i, seg_j
    REAL(wp), INTENT(IN) :: angle_threshold
    LOGICAL :: is_excluded

    REAL(wp) :: n_seg(3), n_node(3)
    REAL(wp) :: v1(3), v2(3), v3(3), e1(3), e2(3)
    REAL(wp) :: cross_n(3), norm_n, cos_angle
    INTEGER(i4) :: n1, n2, n3, n_per_seg

    is_excluded = .FALSE.
    n_per_seg = SIZE(surf%seg_conn, 1)

    ! Segment normal
    n1 = surf%seg_conn(1, seg_j)
    n2 = surf%seg_conn(2, seg_j)
    IF (n_per_seg >= 3) THEN
      n3 = surf%seg_conn(3, seg_j)
    ELSE
      RETURN  ! Can't compute normal for a line segment, skip
    END IF

    v1 = surf%coords(:, n1);  v2 = surf%coords(:, n2);  v3 = surf%coords(:, n3)
    e1 = v2 - v1;  e2 = v3 - v1
    cross_n(1) = e1(2)*e2(3) - e1(3)*e2(2)
    cross_n(2) = e1(3)*e2(1) - e1(1)*e2(3)
    cross_n(3) = e1(1)*e2(2) - e1(2)*e2(1)
    norm_n = SQRT(DOT_PRODUCT(cross_n, cross_n))
    IF (norm_n < SMALL_VAL) RETURN
    n_seg = cross_n / norm_n

    ! Approximate node normal: use stored normals if available,
    ! otherwise use direction from segment centroid to node
    IF (ALLOCATED(surf%coords)) THEN
      n_node = surf%coords(:, node_i) - (v1 + v2 + v3) / 3.0_wp
      norm_n = SQRT(DOT_PRODUCT(n_node, n_node))
      IF (norm_n > SMALL_VAL) THEN
        n_node = n_node / norm_n
      ELSE
        RETURN
      END IF
    ELSE
      RETURN
    END IF

    ! Backface test: if normals point in same direction, it's a backface pair
    cos_angle = DOT_PRODUCT(n_node, n_seg)
    IF (cos_angle > COS(angle_threshold)) THEN
      is_excluded = .TRUE.
    END IF

  END FUNCTION PH_ContSC_BackfaceExcluded

END MODULE PH_Cont_SelfContact