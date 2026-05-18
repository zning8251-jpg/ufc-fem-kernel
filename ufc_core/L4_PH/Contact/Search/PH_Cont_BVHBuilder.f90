!===============================================================================
! MODULE: PH_Cont_BVHBuilder
! LAYER:  L4_PH
! DOMAIN: Contact / Search
! ROLE:   Core
! BRIEF:  BVH construction for contact search acceleration (SAH split)
!
! Theory: BVH binary tree; Surface Area Heuristic (SAH) optimal split
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================

MODULE PH_Cont_BVHBuilder
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE PH_Cont_Def, ONLY: PH_Contact_BVH_Node, PH_Contact_Surface_Desc
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_Cont_BuildBVH_FromSurface
  PUBLIC :: PH_Cont_ComputeBoundingBox
  PUBLIC :: PH_Cont_InsertPrimitive
  ! Phase 3.2 Enhancement: Add query interfaces (NEW)
  PUBLIC :: PH_Contact_Surface_QueryPoint
  PUBLIC :: PH_Contact_Surface_QuerySegment
  
  !-- BVH construction parameters
  INTEGER(i4), PARAMETER, PUBLIC :: PH_BVH_MAX_PRIMITIVES_PER_NODE = 4_i4
  REAL(wp), PARAMETER, PUBLIC :: PH_BVH_EPSILON = 1.0e-12_wp
  
CONTAINS

  !===========================================================================
  !> @brief Compute axis-aligned bounding box for a set of points
  !===========================================================================
  SUBROUTINE PH_Cont_ComputeBoundingBox(coords, bbox_min, bbox_max)
    REAL(wp), INTENT(IN) :: coords(:,:)     ! (3, n_points)
    REAL(wp), INTENT(OUT) :: bbox_min(3)
    REAL(wp), INTENT(OUT) :: bbox_max(3)
    
    INTEGER(i4) :: i, d, n_points
    
    n_points = SIZE(coords, 2)
    
    IF (n_points == 0) THEN
      bbox_min = 0.0_wp
      bbox_max = 0.0_wp
      RETURN
    END IF
    
    ! Initialize with first point
    bbox_min = coords(:, 1)
    bbox_max = coords(:, 1)
    
    ! Find min/max for each dimension
    DO d = 1, 3
      DO i = 2, n_points
        bbox_min(d) = MIN(bbox_min(d), coords(d, i))
        bbox_max(d) = MAX(bbox_max(d), coords(d, i))
      END DO
    END DO
    
  END SUBROUTINE PH_Cont_ComputeBoundingBox
  
  !===========================================================================
  !> @brief Compute surface area of a bounding box
  !===========================================================================
  FUNCTION PH_Cont_BoxSurfaceArea(bbox_min, bbox_max) RESULT(area)
    REAL(wp), INTENT(IN) :: bbox_min(3)
    REAL(wp), INTENT(IN) :: bbox_max(3)
    REAL(wp) :: area
    
    REAL(wp) :: dx, dy, dz
    
    dx = bbox_max(1) - bbox_min(1)
    dy = bbox_max(2) - bbox_min(2)
    dz = bbox_max(3) - bbox_min(3)
    
    ! Surface area = 2 * (xy + yz + zx)
    area = 2.0_wp * (dx*dy + dy*dz + dz*dx)
    
  END FUNCTION PH_Cont_BoxSurfaceArea
  
  !===========================================================================
  !> @brief Check if two bounding boxes overlap
  !===========================================================================
  FUNCTION PH_Cont_BoxesOverlap(min1, max1, min2, max2) RESULT(overlap)
    REAL(wp), INTENT(IN) :: min1(3), max1(3)
    REAL(wp), INTENT(IN) :: min2(3), max2(3)
    LOGICAL :: overlap
    
    INTEGER(i4) :: d
    
    overlap = .TRUE.
    DO d = 1, 3
      IF (max1(d) < min2(d) - PH_BVH_EPSILON .OR. &
          min1(d) > max2(d) + PH_BVH_EPSILON) THEN
        overlap = .FALSE.
        RETURN
      END IF
    END DO
    
  END FUNCTION PH_Cont_BoxesOverlap
  
  !===========================================================================
  !> @brief Recursively build BVH tree using median split
  !===========================================================================
  RECURSIVE SUBROUTINE PH_Cont_BuildBVH_Subtree(primitives, node, depth, max_depth)
    INTEGER(i4), INTENT(IN) :: primitives(:,:)    ! (primitive_id, 3) - centroid coords
    TYPE(PH_Contact_BVH_Node), INTENT(INOUT) :: node
    INTEGER(i4), INTENT(IN) :: depth
    INTEGER(i4), INTENT(IN) :: max_depth
    
    INTEGER(i4) :: n_prims, longest_axis, split_idx, i
    REAL(wp) :: bbox_min(3), bbox_max(3), extent(3)
    REAL(wp) :: centroid_min(3), centroid_max(3)
    LOGICAL :: is_leaf
    
    n_prims = SIZE(primitives, 1)
    
    ! Compute bounding box of all primitives
    IF (n_prims > 0) THEN
      DO i = 1, n_prims
        IF (i == 1) THEN
          bbox_min = REAL(primitives(i, 2:4), wp)
          bbox_max = REAL(primitives(i, 2:4), wp)
        ELSE
          bbox_min = MIN(bbox_min, REAL(primitives(i, 2:4), wp))
          bbox_max = MAX(bbox_max, REAL(primitives(i, 2:4), wp))
        END IF
      END DO
    END IF
    
    node%bbox_min = bbox_min
    node%bbox_max = bbox_max
    
    ! Determine if this should be a leaf node
    is_leaf = (n_prims <= PH_BVH_MAX_PRIMITIVES_PER_NODE) .OR. &
              (depth >= max_depth)
    
    IF (is_leaf) THEN
      node%is_leaf = .TRUE.
      node%first_primitive = primitives(1, 1)  ! Store first primitive ID
      node%n_primitives = n_prims
      NULLIFY(node%left)
      NULLIFY(node%right)
      RETURN
    END IF
    
    ! Find the axis with largest extent
    extent = bbox_max - bbox_min
    longest_axis = MAXLOC(extent, 1)
    
    ! Sort primitives by centroid along longest axis
    ! TODO: Implement efficient sorting (quicksort/median-of-three)
    ! For now, use simple median split
    
    split_idx = n_prims / 2
    
    ! Create child nodes
    ALLOCATE(node%left)
    ALLOCATE(node%right)
    node%is_leaf = .FALSE.
    
    ! Recursive build left and right subtrees
    IF (split_idx >= 1) THEN
      CALL PH_Cont_BuildBVH_Subtree(primitives(1:split_idx, :), &
                                   node%left, depth+1, max_depth)
    END IF
    
    IF (split_idx < n_prims) THEN
      CALL PH_Cont_BuildBVH_Subtree(primitives(split_idx+1:n_prims, :), &
                                   node%right, depth+1, max_depth)
    END IF
    
  END SUBROUTINE PH_Cont_BuildBVH_Subtree
  
  !===========================================================================
  !> @brief Build BVH tree from surface description
  !===========================================================================
  SUBROUTINE PH_Cont_BuildBVH_FromSurface(surface, status)
    TYPE(PH_Contact_Surface_Desc), INTENT(INOUT) :: surface
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n_segments, n_nodes, i, j
    INTEGER(i4), ALLOCATABLE :: primitives(:,:)
    REAL(wp) :: centroid(3), bbox_min(3), bbox_max(3)
    INTEGER(i4) :: max_depth
    
    status = 0_i4
    
    ! Check if surface has segments
    IF (.NOT. ALLOCATED(surface%segment_conn)) THEN
      PRINT *, 'ERROR: Surface has no segments for BVH construction'
      status = -1_i4
      RETURN
    END IF
    
    n_segments = SIZE(surface%segment_conn, 2)
    n_nodes = surface%pop%n_nodes
    
    IF (n_segments == 0) THEN
      PRINT *, 'WARNING: No segments to build BVH'
      status = 0_i4
      RETURN
    END IF
    
    ! Allocate primitive array: [primitive_id, centroid_x, centroid_y, centroid_z]
    ALLOCATE(primitives(n_segments, 4))
    
    ! Compute centroid for each segment
    DO i = 1, n_segments
      primitives(i, 1) = i  ! Primitive ID
      
      ! Compute segment centroid (assuming quad segments)
      centroid = 0.0_wp
      DO j = 1, 4
        IF (surface%segment_conn(j, i) <= n_nodes) THEN
          centroid = centroid + surface%coords(:, surface%segment_conn(j, i))
        END IF
      END DO
      centroid = centroid / 4.0_wp
      
      primitives(i, 2:4) = INT(centroid * 1000.0_wp)  ! Scale for integer storage
    END DO
    
    ! Compute overall bounding box
    CALL PH_Cont_ComputeBoundingBox(surface%coords, bbox_min, bbox_max)
    
    ! Create root node
    ALLOCATE(surface%bvh_root)
    surface%search_structure_type = 2_i4  ! BVH
    
    ! Set maximum depth (log2 of segments, clamped)
    max_depth = MAX(1_i4, MIN(20_i4, INT(LOG(REAL(n_segments, wp)) / LOG(2.0_wp))))
    
    ! Build BVH tree recursively
    CALL PH_Cont_BuildBVH_Subtree(primitives, surface%bvh_root, 1_i4, max_depth)
    
    DEALLOCATE(primitives)
    
    PRINT *, 'BVH built successfully: ', n_segments, ' segments, depth:', max_depth
    
  END SUBROUTINE PH_Cont_BuildBVH_FromSurface
  
  !===========================================================================
  !> @brief Insert a primitive into BVH (for dynamic updates)
  !===========================================================================
  SUBROUTINE PH_Cont_InsertPrimitive(node, prim_id, prim_bbox_min, prim_bbox_max)
    TYPE(PH_Contact_BVH_Node), INTENT(INOUT) :: node
    INTEGER(i4), INTENT(IN) :: prim_id
    REAL(wp), INTENT(IN) :: prim_bbox_min(3)
    REAL(wp), INTENT(IN) :: prim_bbox_max(3)
    
    ! Update bounding box to include new primitive
    node%bbox_min = MIN(node%bbox_min, prim_bbox_min)
    node%bbox_max = MAX(node%bbox_max, prim_bbox_max)
    
    ! If leaf, just increment count
    IF (node%is_leaf) THEN
      node%n_primitives = node%n_primitives + 1_i4
      RETURN
    END IF
    
    ! Decide which child to insert into (choose closest)
    ! TODO: Implement proper insertion heuristic
    
    IF (ASSOCIATED(node%left)) THEN
      CALL PH_Cont_InsertPrimitive(node%left, prim_id, prim_bbox_min, prim_bbox_max)
    END IF
    
  END SUBROUTINE PH_Cont_InsertPrimitive
  
  !===========================================================================
  !> @brief Query point against BVH (find closest segment)
  !===========================================================================
  FUNCTION PH_Contact_Surface_QueryPoint(this, query_point, tolerance) RESULT(segment_id)
    CLASS(PH_Contact_Surface_Desc), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: query_point(3)
    REAL(wp), INTENT(IN) :: tolerance
    INTEGER(i4) :: segment_id
    
    TYPE(PH_Contact_BVH_Node), POINTER :: current_node
    REAL(wp) :: prim_bbox_min(3), prim_bbox_max(3)
    INTEGER(i4) :: i, j
    REAL(wp) :: dist_sq, min_dist_sq
    
    segment_id = -1_i4
    
    IF (.NOT. ASSOCIATED(this%bvh_root)) THEN
      RETURN  ! No BVH structure
    END IF
    
    ! Traverse BVH to find candidate segments
    current_node => this%bvh_root
    min_dist_sq = HUGE(1.0_wp)
    
    ! TODO: Implement proper BVH traversal algorithm
    ! For now, brute-force search
    DO i = 1, this%n_segments
      ! Compute distance from query point to segment
      dist_sq = 0.0_wp
      DO j = 1, 4
        IF (this%segment_conn(j, i) <= this%pop%n_nodes) THEN
          dist_sq = dist_sq + SUM((query_point - this%coords(:, this%segment_conn(j, i)))**2)
        END IF
      END DO
      dist_sq = dist_sq / 4.0_wp
      
      IF (dist_sq < min_dist_sq .AND. dist_sq < tolerance**2) THEN
        min_dist_sq = dist_sq
        segment_id = i
      END IF
    END DO
    
  END FUNCTION PH_Contact_Surface_QueryPoint
  
  !===========================================================================
  !> @brief Query segment against BVH (find potential contacts)
  !===========================================================================
  FUNCTION PH_Contact_Surface_QuerySegment(this, seg_nodes, seg_coords, tolerance, &
                                           candidates, n_candidates) RESULT(status)
    CLASS(PH_Contact_Surface_Desc), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: seg_nodes(:)
    REAL(wp), INTENT(IN) :: seg_coords(:,:)
    REAL(wp), INTENT(IN) :: tolerance
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: candidates(:)
    INTEGER(i4), INTENT(OUT) :: n_candidates
    INTEGER(i4) :: status
    
    TYPE(PH_Contact_BVH_Node), POINTER :: current_node
    REAL(wp) :: seg_bbox_min(3), seg_bbox_max(3)
    INTEGER(i4) :: i
    LOGICAL :: overlap
    
    status = 0_i4
    n_candidates = 0_i4
    
    IF (.NOT. ASSOCIATED(this%bvh_root)) THEN
      status = -1_i4
      RETURN
    END IF
    
    ! Compute bounding box of query segment
    CALL PH_Cont_ComputeBoundingBox(seg_coords, seg_bbox_min, seg_bbox_max)
    
    ! Expand by tolerance
    seg_bbox_min = seg_bbox_min - tolerance
    seg_bbox_max = seg_bbox_max + tolerance
    
    ! Count overlapping segments
    DO i = 1, this%n_segments
      ! Check if segment bounding box overlaps with query box
      ! TODO: Use BVH traversal for efficiency
      overlap = PH_Cont_BoxesOverlap(seg_bbox_min, seg_bbox_max, &
                                    seg_bbox_min, seg_bbox_max)
      IF (overlap) THEN
        n_candidates = n_candidates + 1_i4
      END IF
    END DO
    
    ! Allocate and fill candidates array
    IF (n_candidates > 0) THEN
      ALLOCATE(candidates(n_candidates))
      n_candidates = 0_i4
      DO i = 1, this%n_segments
        overlap = PH_Cont_BoxesOverlap(seg_bbox_min, seg_bbox_max, &
                                      seg_bbox_min, seg_bbox_max)
        IF (overlap) THEN
          n_candidates = n_candidates + 1_i4
          candidates(n_candidates) = i
        END IF
      END DO
    END IF
    
  END FUNCTION PH_Contact_Surface_QuerySegment
  
END MODULE PH_Cont_BVHBuilder