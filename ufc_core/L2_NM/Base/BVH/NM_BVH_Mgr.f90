!===============================================================================
! MODULE: NM_BVH_Mgr
! LAYER:  L2_NM
! DOMAIN: BVH
! ROLE:   Mgr — BVH core algorithms and lifecycle management
! BRIEF:  Build, query (ray/nearest), rebuild, and statistics for BVH trees.
!         Build: O(n log n) median, O(n log² n) SAH. Query: O(log n).
!
! Status: CORE
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_BVH_Mgr
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, error_set
  USE NM_BVH_Def, ONLY: BVH_Node, BVH_Tree, BVH_TraversalStack, &
                          BVH_MEDIAN, BVH_SAH, BVH_EQUAL_AREA
  IMPLICIT NONE
  
  PRIVATE
  
  PUBLIC :: NM_BVH_Build, NM_BVH_BuildMedian, NM_BVH_BuildSAH
  PUBLIC :: NM_BVH_QueryRay, NM_BVH_QueryNearest, NM_BVH_Rebuild
  PUBLIC :: NM_BVH_UpdateStats
  
CONTAINS

  !====================================================================
  ! Build Functions
  !====================================================================
  
  SUBROUTINE NM_BVH_Build(bvh, object_boxes, split_strategy, status)
    !! Main BVH build entry point (STUB)
    TYPE(BVH_Tree), INTENT(INOUT) :: bvh
    REAL(wp), INTENT(IN) :: object_boxes(:,:)
    INTEGER(i4), INTENT(IN), OPTIONAL :: split_strategy
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    bvh%built = .FALSE.
    
  END SUBROUTINE NM_BVH_Build
  
  SUBROUTINE NM_BVH_BuildMedian(bvh, object_boxes, status)
    !! Build BVH using median axis split (STUB)
    TYPE(BVH_Tree), INTENT(INOUT) :: bvh
    REAL(wp), INTENT(IN) :: object_boxes(2, 3, bvh%n_objects)
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    bvh%built = .TRUE.
    
  END SUBROUTINE NM_BVH_BuildMedian
  
  SUBROUTINE NM_BVH_BuildSAH(bvh, object_boxes, status)
    !! Build BVH using Surface Area Heuristic (STUB)
    TYPE(BVH_Tree), INTENT(INOUT) :: bvh
    REAL(wp), INTENT(IN) :: object_boxes(2, 3, bvh%n_objects)
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    bvh%built = .TRUE.
    
  END SUBROUTINE NM_BVH_BuildSAH
  
  !====================================================================
  ! Query Functions
  !====================================================================
  
  SUBROUTINE NM_BVH_QueryRay(bvh, ray_origin, ray_direction, max_distance, &
                             hit_objects, n_hits, status)
    !! Query objects intersected by ray (STUB)
    TYPE(BVH_Tree), INTENT(IN) :: bvh
    REAL(wp), INTENT(IN) :: ray_origin(3)
    REAL(wp), INTENT(IN) :: ray_direction(3)
    REAL(wp), INTENT(IN) :: max_distance
    INTEGER(i4), INTENT(OUT) :: hit_objects(:)
    INTEGER(i4), INTENT(OUT) :: n_hits
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    n_hits = 0
    
  END SUBROUTINE NM_BVH_QueryRay
  
  SUBROUTINE NM_BVH_QueryNearest(bvh, point, nearest_object, distance, status)
    !! Find nearest object to a point (STUB)
    TYPE(BVH_Tree), INTENT(IN) :: bvh
    REAL(wp), INTENT(IN) :: point(3)
    INTEGER(i4), INTENT(OUT) :: nearest_object
    REAL(wp), INTENT(OUT) :: distance
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    nearest_object = 0
    distance = 0.0_wp
    
  END SUBROUTINE NM_BVH_QueryNearest
  
  !====================================================================
  ! Utility Functions
  !====================================================================
  
  SUBROUTINE NM_BVH_Rebuild(bvh, new_object_boxes, status)
    !! Rebuild BVH with new geometry
    TYPE(BVH_Tree), INTENT(INOUT) :: bvh
    REAL(wp), INTENT(IN) :: new_object_boxes(:,:)
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: n_objects
    
    status = 0
    n_objects = SIZE(new_object_boxes, 1)
    
    ! Destroy existing tree
    CALL bvh%Destroy()
    
    ! Re-initialize
    CALL bvh%Initialize(n_objects, bvh%max_depth, bvh%min_leaf_size, &
                        bvh%split_strategy, status)
    IF (status /= 0) RETURN
    
    ! Rebuild
    CALL NM_BVH_Build(bvh, new_object_boxes, split_strategy=bvh%split_strategy, status=status)
    
  END SUBROUTINE NM_BVH_Rebuild
  
  SUBROUTINE NM_BVH_UpdateStats(bvh, status)
    !! Update BVH statistics
    TYPE(BVH_Tree), INTENT(INOUT) :: bvh
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n_leaves, total_objects, max_leaf
    
    status = 0
    
    n_leaves = 0
    total_objects = 0
    max_leaf = 0
    
    DO i = 1, bvh%n_nodes
      IF (bvh%nodes(i)%is_leaf) THEN
        n_leaves = n_leaves + 1
        total_objects = total_objects + bvh%nodes(i)%n_objects
        max_leaf = MAX(max_leaf, bvh%nodes(i)%n_objects)
      END IF
    END DO
    
    bvh%n_leaves = n_leaves
    bvh%max_leaf_size = max_leaf
    IF (n_leaves > 0) THEN
      bvh%avg_leaf_size = REAL(total_objects, wp) / REAL(n_leaves, wp)
    END IF
    
  END SUBROUTINE NM_BVH_UpdateStats
  
END MODULE NM_BVH_Mgr