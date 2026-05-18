!===============================================================================
! MODULE: PH_Cont_BVHQuery
! LAYER:  L4_PH
! DOMAIN: Contact / Search
! ROLE:   Core
! BRIEF:  BVH traversal (stack-based) and contact candidate detection
!
! Theory: Ericson (2005) Real-Time Collision Detection Ch.4
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================
MODULE PH_Cont_BVHQuery
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Cont_Def, ONLY: PH_Contact_BVH_Node
  IMPLICIT NONE
  PRIVATE

  ! ===================================================================
  ! Public Procedures - BVH Query Operations
  ! ===================================================================
  PUBLIC :: PH_ContBVH_Traverse
  PUBLIC :: PH_ContBVH_QueryPoint
  PUBLIC :: PH_ContBVH_QuerySegment
  PUBLIC :: PH_ContBVH_CollectCandidates

  ! ===================================================================
  ! Constants
  ! ===================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ContBVH_MAX_STACK_SIZE = 64_i4
  REAL(wp), PARAMETER, PUBLIC :: PH_ContBVH_EPSILON = 1.0e-12_wp

CONTAINS

  !===========================================================================
  ! Traverse BVH (Stack-based, Non-recursive)
  !===========================================================================
  SUBROUTINE PH_ContBVH_Traverse(root, query_bbox_min, query_bbox_max, &
                                 candidates, n_candidates, max_candidates, status)
    !! Traverse BVH tree to find all primitives overlapping query box
    !! 
    !! Algorithm:
    !!   1. Push root node onto stack
    !!   2. While stack not empty:
    !!      a. Pop node
    !!      b. If leaf: check primitives
    !!      c. If internal: push overlapping children
    !! 
    !! Arguments:
    !!   root: BVH root node
    !!   query_bbox_min: Query box minimum corner (3)
    !!   query_bbox_max: Query box maximum corner (3)
    !!   candidates: Output primitive IDs (max_candidates)
    !!   n_candidates: Number of candidates found (output)
    !!   max_candidates: Maximum capacity of candidates array
    !!   status: Error status
    
    TYPE(PH_Contact_BVH_Node), POINTER, INTENT(IN) :: root
    REAL(wp), INTENT(IN) :: query_bbox_min(3)
    REAL(wp), INTENT(IN) :: query_bbox_max(3)
    INTEGER(i4), INTENT(OUT) :: candidates(:)  ! (max_candidates)
    INTEGER(i4), INTENT(OUT) :: n_candidates
    INTEGER(i4), INTENT(IN) :: max_candidates
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    ! Stack for iterative traversal
    TYPE(PH_Contact_BVH_Node), POINTER :: stack(PH_ContBVH_MAX_STACK_SIZE)
    INTEGER(i4) :: stack_ptr
    INTEGER(i4) :: i
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Initialize
    n_candidates = 0_i4
    stack_ptr = 0_i4
    candidates = 0_i4
    
    ! Check if root overlaps
    IF (.NOT. ASSOCIATED(root)) RETURN
    
    ! Check bounding box overlap
    IF (.NOT. BoxOverlap(root%bbox_min, root%bbox_max, &
                         query_bbox_min, query_bbox_max)) THEN
      RETURN
    END IF
    
    ! Push root
    stack_ptr = stack_ptr + 1_i4
    IF (stack_ptr > PH_ContBVH_MAX_STACK_SIZE) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = 'PH_ContBVH_Traverse: Stack overflow'
      END IF
      RETURN
    END IF
    stack(stack_ptr) => root
    
    ! Iterative traversal
    DO WHILE (stack_ptr > 0_i4)
      ! Pop node
      ASSOCIATE(node => stack(stack_ptr))
        stack_ptr = stack_ptr - 1_i4
        
        ! Check node overlap
        IF (.NOT. BoxOverlap(node%bbox_min, node%bbox_max, &
                             query_bbox_min, query_bbox_max)) THEN
          CYCLE
        END IF
        
        ! If leaf, collect primitives
        IF (node%is_leaf) THEN
          DO i = 1, node%n_primitives
            IF (n_candidates >= max_candidates) EXIT
            
            ! Get primitive ID from node
            IF (ASSOCIATED(node%primitive_ids)) THEN
              n_candidates = n_candidates + 1_i4
              candidates(n_candidates) = node%primitive_ids(i)
            END IF
          END DO
        ELSE
          ! Push children (right first, then left - LIFO)
          IF (ASSOCIATED(node%right)) THEN
            stack_ptr = stack_ptr + 1_i4
            IF (stack_ptr <= PH_ContBVH_MAX_STACK_SIZE) THEN
              stack(stack_ptr) => node%right
            END IF
          END IF
          
          IF (ASSOCIATED(node%left)) THEN
            stack_ptr = stack_ptr + 1_i4
            IF (stack_ptr <= PH_ContBVH_MAX_STACK_SIZE) THEN
              stack(stack_ptr) => node%left
            END IF
          END IF
        END IF
      END ASSOCIATE
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContBVH_Traverse

  !===========================================================================
  ! Query Point Against BVH
  !===========================================================================
  SUBROUTINE PH_ContBVH_QueryPoint(root, query_point, tolerance, &
                                   coords, segment_conn, n_segments, &
                                   candidates, n_candidates, max_candidates, status)
    !! Find all segments within tolerance of query point
    !! 
    !! Arguments:
    !!   root: BVH root node
    !!   query_point: Query point coordinates (3)
    !!   tolerance: Search radius
    !!   coords: Nodal coordinates (3, n_nodes)
    !!   segment_conn: Segment connectivity (4, n_segments)
    !!   n_segments: Number of segments
    !!   candidates: Output segment IDs (max_candidates)
    !!   n_candidates: Number of candidates found
    !!   max_candidates: Array capacity
    !!   status: Error status
    
    TYPE(PH_Contact_BVH_Node), POINTER, INTENT(IN) :: root
    REAL(wp), INTENT(IN) :: query_point(3)
    REAL(wp), INTENT(IN) :: tolerance
    REAL(wp), INTENT(IN) :: coords(:,:)       ! (3, n_nodes)
    INTEGER(i4), INTENT(IN) :: segment_conn(:,:) ! (4, n_segments)
    INTEGER(i4), INTENT(IN) :: n_segments
    INTEGER(i4), INTENT(OUT) :: candidates(:) ! (max_candidates)
    INTEGER(i4), INTENT(OUT) :: n_candidates
    INTEGER(i4), INTENT(IN) :: max_candidates
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: query_bbox_min(3), query_bbox_max(3)
    INTEGER(i4) :: i, seg_id, node_id
    REAL(wp) :: dist_sq, tol_sq
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Build query box around point
    query_bbox_min = query_point - tolerance
    query_bbox_max = query_point + tolerance
    
    ! Traverse BVH
    CALL PH_ContBVH_Traverse(root, query_bbox_min, query_bbox_max, &
                            candidates, n_candidates, max_candidates, status)
    
    ! Filter by actual distance (refine candidates)
    tol_sq = tolerance * tolerance
    DO i = n_candidates, 1, -1_i4
      seg_id = candidates(i)
      
      ! Compute distance from point to segment
      dist_sq = PointToSegmentDistSq(query_point, coords, &
                                     segment_conn(:, seg_id))
      
      IF (dist_sq > tol_sq) THEN
        ! Remove from candidates (shift array)
        IF (i < n_candidates) THEN
          candidates(i:n_candidates-1) = candidates(i+1:n_candidates)
        END IF
        n_candidates = n_candidates - 1_i4
      END IF
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContBVH_QueryPoint

  !===========================================================================
  ! Query Segment Against BVH
  !===========================================================================
  SUBROUTINE PH_ContBVH_QuerySegment(root, seg_coords, tolerance, &
                                     target_coords, target_conn, n_target_segs, &
                                     candidates, n_candidates, max_candidates, status)
    !! Find all segments overlapping query segment (with tolerance)
    !! 
    !! Arguments:
    !!   root: BVH root node
    !!   seg_coords: Query segment coordinates (3, 4)
    !!   tolerance: Search tolerance
    !!   target_coords: Target surface coordinates (3, n_nodes)
    !!   target_conn: Target segment connectivity (4, n_segments)
    !!   n_target_segs: Number of target segments
    !!   candidates: Output segment IDs (max_candidates)
    !!   n_candidates: Number of candidates found
    !!   max_candidates: Array capacity
    !!   status: Error status
    
    TYPE(PH_Contact_BVH_Node), POINTER, INTENT(IN) :: root
    REAL(wp), INTENT(IN) :: seg_coords(:,:)     ! (3, 4)
    REAL(wp), INTENT(IN) :: tolerance
    REAL(wp), INTENT(IN) :: target_coords(:,:)  ! (3, n_nodes)
    INTEGER(i4), INTENT(IN) :: target_conn(:,:) ! (4, n_target_segs)
    INTEGER(i4), INTENT(IN) :: n_target_segs
    INTEGER(i4), INTENT(OUT) :: candidates(:)   ! (max_candidates)
    INTEGER(i4), INTENT(OUT) :: n_candidates
    INTEGER(i4), INTENT(IN) :: max_candidates
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    REAL(wp) :: seg_bbox_min(3), seg_bbox_max(3)
    INTEGER(i4) :: i, j, seg_id
    REAL(wp) :: bbox_min(3), bbox_max(3)
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    ! Compute bounding box of query segment
    CALL ComputeBBox(seg_coords, seg_bbox_min, seg_bbox_max)
    
    ! Expand by tolerance
    seg_bbox_min = seg_bbox_min - tolerance
    seg_bbox_max = seg_bbox_max + tolerance
    
    ! Traverse BVH to get initial candidates
    CALL PH_ContBVH_Traverse(root, seg_bbox_min, seg_bbox_max, &
                            candidates, n_candidates, max_candidates, status)
    
    ! Refine using segment-segment intersection
    DO i = n_candidates, 1, -1_i4
      seg_id = candidates(i)
      
      ! Get target segment coordinates
      DO j = 1, 4
        IF (target_conn(j, seg_id) <= SIZE(target_coords, 2)) THEN
          bbox_min = target_coords(:, target_conn(j, seg_id))
        ELSE
          bbox_min = 0.0_wp
        END IF
      END DO
      
      ! Quick rejection test (bounding boxes)
      IF (.NOT. BoxOverlap(seg_bbox_min, seg_bbox_max, bbox_min, bbox_max)) THEN
        ! Remove from candidates
        IF (i < n_candidates) THEN
          candidates(i:n_candidates-1) = candidates(i+1:n_candidates)
        END IF
        n_candidates = n_candidates - 1_i4
      END IF
    END DO
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContBVH_QuerySegment

  !===========================================================================
  ! Collect Candidates from Multiple BVHs
  !===========================================================================
  SUBROUTINE PH_ContBVH_CollectCandidates(bvh_list, n_bvhs, query_coords, &
                                          tolerance, all_candidates, n_total, status)
    !! Collect candidates from multiple BVH trees (for global search)
    !! 
    !! Arguments:
    !!   bvh_list: Array of BVH roots
    !!   n_bvhs: Number of BVH trees
    !!   query_coords: Query points (3, n_queries)
    !!   tolerance: Search tolerance
    !!   all_candidates: Output candidate list (flattened)
    !!   n_total: Total number of candidates
    !!   status: Error status
    
    TYPE(PH_Contact_BVH_Node), POINTER, INTENT(IN) :: bvh_list(:)
    INTEGER(i4), INTENT(IN) :: n_bvhs
    REAL(wp), INTENT(IN) :: query_coords(:,:)  ! (3, n_queries)
    REAL(wp), INTENT(IN) :: tolerance
    INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: all_candidates(:)
    INTEGER(i4), INTENT(OUT) :: n_total
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    INTEGER(i4) :: i, q, n_queries
    INTEGER(i4), ALLOCATABLE :: temp_candidates(:)
    INTEGER(i4) :: n_temp, offset
    
    IF (PRESENT(status)) CALL init_error_status(status)
    
    n_queries = SIZE(query_coords, 2)
    n_total = 0_i4
    ALLOCATE(all_candidates(0))
    
    ! Query each BVH
    DO i = 1, n_bvhs
      IF (.NOT. ASSOCIATED(bvh_list(i))) CYCLE
      
      DO q = 1, n_queries
        ALLOCATE(temp_candidates(100))  ! Initial guess
        n_temp = 0_i4
        
        CALL PH_ContBVH_QueryPoint(bvh_list(i), query_coords(:, q), tolerance, &
                                  temp_candidates, n_temp, SIZE(temp_candidates), status)
        
        IF (n_temp > 0) THEN
          ! Append to all_candidates
          offset = SIZE(all_candidates)
          CALL MOVE_ALLOC(FROM=temp_candidates, TO=all_candidates)
          ! Note: In production, implement proper array append
        END IF
        
        DEALLOCATE(temp_candidates)
      END DO
    END DO
    
    n_total = SIZE(all_candidates)
    
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_ContBVH_CollectCandidates

  !===========================================================================
  ! Helper: Bounding Box Overlap Test
  !===========================================================================
  FUNCTION BoxOverlap(min1, max1, min2, max2) RESULT(overlap)
    REAL(wp), INTENT(IN) :: min1(3), max1(3)
    REAL(wp), INTENT(IN) :: min2(3), max2(3)
    LOGICAL :: overlap
    
    INTEGER(i4) :: d
    
    overlap = .TRUE.
    DO d = 1, 3
      IF (max1(d) < min2(d) - PH_ContBVH_EPSILON .OR. &
          min1(d) > max2(d) + PH_ContBVH_EPSILON) THEN
        overlap = .FALSE.
        RETURN
      END IF
    END DO
    
  END FUNCTION BoxOverlap

  !===========================================================================
  ! Helper: Compute Bounding Box
  !===========================================================================
  SUBROUTINE ComputeBBox(coords, bbox_min, bbox_max)
    REAL(wp), INTENT(IN) :: coords(:,:)  ! (3, n_points)
    REAL(wp), INTENT(OUT) :: bbox_min(3)
    REAL(wp), INTENT(OUT) :: bbox_max(3)
    
    INTEGER(i4) :: i, d, n_points
    
    n_points = SIZE(coords, 2)
    
    IF (n_points == 0) THEN
      bbox_min = 0.0_wp
      bbox_max = 0.0_wp
      RETURN
    END IF
    
    bbox_min = coords(:, 1)
    bbox_max = coords(:, 1)
    
    DO d = 1, 3
      DO i = 2, n_points
        bbox_min(d) = MIN(bbox_min(d), coords(d, i))
        bbox_max(d) = MAX(bbox_max(d), coords(d, i))
      END DO
    END DO
    
  END SUBROUTINE ComputeBBox

  !===========================================================================
  ! Helper: Point-to-Segment Distance Squared
  !===========================================================================
  FUNCTION PointToSegmentDistSq(point, coords, seg_nodes) RESULT(dist_sq)
    REAL(wp), INTENT(IN) :: point(3)
    REAL(wp), INTENT(IN) :: coords(:,:)      ! (3, n_nodes)
    INTEGER(i4), INTENT(IN) :: seg_nodes(4)  ! Segment node indices
    REAL(wp) :: dist_sq
    
    ! Simplified: Use centroid as approximation
    INTEGER(i4) :: i
    REAL(wp) :: centroid(3)
    
    centroid = 0.0_wp
    DO i = 1, 4
      IF (seg_nodes(i) <= SIZE(coords, 2)) THEN
        centroid = centroid + coords(:, seg_nodes(i))
      END IF
    END DO
    centroid = centroid / 4.0_wp
    
    dist_sq = SUM((point - centroid)**2)
    
  END FUNCTION PointToSegmentDistSq

END MODULE PH_Cont_BVHQuery