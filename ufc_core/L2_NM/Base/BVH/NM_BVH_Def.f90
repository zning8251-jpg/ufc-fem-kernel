!===============================================================================
! MODULE: NM_BVH_Def
! LAYER:  L2_NM
! DOMAIN: BVH
! ROLE:   Def — BVH types, constants, and node/tree definitions
! BRIEF:  Bounding Volume Hierarchy types: BVH_Node (Desc), BVH_Tree (State),
!         BVH_QueryResult (Ctx), BVH_TraversalStack. Split strategy constants.
!
! Status: CORE
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_BVH_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  
  PRIVATE
  
  PUBLIC :: BVH_Node, BVH_Tree

  !> BVH split strategy constants (NM_BVH_* naming)
  INTEGER(i4), PARAMETER, PUBLIC :: NM_BVH_SPLIT_MEDIAN     = 1   ! Median axis split
  INTEGER(i4), PARAMETER, PUBLIC :: NM_BVH_SPLIT_SAH        = 2   ! Surface Area Heuristic
  INTEGER(i4), PARAMETER, PUBLIC :: NM_BVH_SPLIT_EQUAL_AREA  = 3   ! Equal area split
  ! legacy aliases
  INTEGER(i4), PARAMETER, PUBLIC :: BVH_MEDIAN     = NM_BVH_SPLIT_MEDIAN
  INTEGER(i4), PARAMETER, PUBLIC :: BVH_SAH        = NM_BVH_SPLIT_SAH
  INTEGER(i4), PARAMETER, PUBLIC :: BVH_EQUAL_AREA = NM_BVH_SPLIT_EQUAL_AREA
  
  !> BVH node type (bounding volume)
  TYPE, PUBLIC :: BVH_Node
    ! Bounding box: min_corner(3), max_corner(3)
    REAL(wp) :: bounding_box(2, 3)
    INTEGER(i4) :: left_child = 0      ! Index of left child (0 if leaf)
    INTEGER(i4) :: right_child = 0     ! Index of right child (0 if leaf)
    INTEGER(i4) :: parent = 0         ! Index of parent node
    INTEGER(i4) :: object_index = 0   ! First object index (if leaf)
    INTEGER(i4) :: n_objects = 0      ! Number of objects in leaf
    LOGICAL :: is_leaf = .FALSE.
  CONTAINS
    PROCEDURE :: ComputeVolume => BVH_Node_ComputeVolume
    PROCEDURE :: ComputeSurfaceArea => BVH_Node_ComputeSurfaceArea
    PROCEDURE :: Overlaps => BVH_Node_Overlaps
    PROCEDURE :: ContainsPoint => BVH_Node_ContainsPoint
  END TYPE BVH_Node
  
  !> BVH tree structure
  TYPE, PUBLIC :: BVH_Tree
    TYPE(BVH_Node), ALLOCATABLE :: nodes(:)
    INTEGER(i4) :: n_nodes = 0
    INTEGER(i4) :: n_objects = 0
    INTEGER(i4) :: split_strategy = BVH_MEDIAN
    INTEGER(i4) :: max_depth = 32
    INTEGER(i4) :: min_leaf_size = 1
    REAL(wp) :: build_cost = 1.0_wp      ! SAH parameter: cost of traversal
    REAL(wp) :: intersection_cost = 1.0_wp  ! SAH parameter: cost of intersection
    LOGICAL :: built = .FALSE.
    
    ! Statistics
    INTEGER(i4) :: n_leaves = 0
    INTEGER(i4) :: max_leaf_size = 0
    REAL(wp) :: avg_leaf_size = 0.0_wp
  CONTAINS
    PROCEDURE :: Initialize => BVH_Tree_Initialize
    PROCEDURE :: Destroy => BVH_Tree_Destroy
    PROCEDURE :: GetBoundingBox => BVH_Tree_GetBoundingBox
    PROCEDURE :: IsBuilt => BVH_Tree_IsBuilt
  END TYPE BVH_Tree
  
  !> Query result type
  TYPE, PUBLIC :: BVH_QueryResult
    INTEGER(i4) :: object_index = 0
    REAL(wp) :: distance = 0.0_wp
    REAL(wp) :: closest_point(3) = 0.0_wp
  END TYPE BVH_QueryResult
  
  !> Traversal stack for BVH query
  TYPE, PUBLIC :: BVH_TraversalStack
    INTEGER(i4), ALLOCATABLE :: node_indices(:)
    INTEGER(i4) :: top = 0
    INTEGER(i4) :: capacity = 0
  CONTAINS
    PROCEDURE :: Initialize => BVH_Stack_Initialize
    PROCEDURE :: Push => BVH_Stack_Push
    PROCEDURE :: Pop => BVH_Stack_Pop
    PROCEDURE :: IsEmpty => BVH_Stack_IsEmpty
    PROCEDURE :: Destroy => BVH_Stack_Destroy
  END TYPE BVH_TraversalStack

CONTAINS

  !====================================================================
  ! BVH_Node methods
  !====================================================================
  
  FUNCTION BVH_Node_ComputeVolume(this) RESULT(volume)
    CLASS(BVH_Node), INTENT(IN) :: this
    REAL(wp) :: volume
    REAL(wp) :: extent(3)
    
    extent = this%bounding_box(2, :) - this%bounding_box(1, :)
    volume = extent(1) * extent(2) * extent(3)
    
  END FUNCTION BVH_Node_ComputeVolume
  
  FUNCTION BVH_Node_ComputeSurfaceArea(this) RESULT(sa)
    CLASS(BVH_Node), INTENT(IN) :: this
    REAL(wp) :: sa
    REAL(wp) :: extent(3)
    
    extent = this%bounding_box(2, :) - this%bounding_box(1, :)
    sa = 2.0_wp * (extent(1)*extent(2) + extent(2)*extent(3) + extent(1)*extent(3))
    
  END FUNCTION BVH_Node_ComputeSurfaceArea
  
  FUNCTION BVH_Node_Overlaps(this, other) RESULT(overlap)
    CLASS(BVH_Node), INTENT(IN) :: this
    TYPE(BVH_Node), INTENT(IN) :: other
    LOGICAL :: overlap
    INTEGER(i4) :: i
    
    overlap = .TRUE.
    DO i = 1, 3
      IF (this%bounding_box(2, i) < other%bounding_box(1, i) .OR. &
          this%bounding_box(1, i) > other%bounding_box(2, i)) THEN
        overlap = .FALSE.
        RETURN
      END IF
    END DO
    
  END FUNCTION BVH_Node_Overlaps
  
  FUNCTION BVH_Node_ContainsPoint(this, point) RESULT(contains)
    CLASS(BVH_Node), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: point(3)
    LOGICAL :: contains
    INTEGER(i4) :: i
    
    contains = .TRUE.
    DO i = 1, 3
      IF (point(i) < this%bounding_box(1, i) .OR. &
          point(i) > this%bounding_box(2, i)) THEN
        contains = .FALSE.
        RETURN
      END IF
    END DO
    
  END FUNCTION BVH_Node_ContainsPoint
  
  !====================================================================
  ! BVH_Tree methods
  !====================================================================
  
  SUBROUTINE BVH_Tree_Initialize(this, n_objects, max_depth, min_leaf_size, &
                                  split_strat_in, status)
    CLASS(BVH_Tree), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: n_objects
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_depth
    INTEGER(i4), INTENT(IN), OPTIONAL :: min_leaf_size
    INTEGER(i4), INTENT(IN), OPTIONAL :: split_strat_in
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    status = 0
    
    this%n_objects = n_objects
    this%max_depth = MERGE(max_depth, 32_i4, PRESENT(max_depth))
    this%min_leaf_size = MERGE(min_leaf_size, 1_i4, PRESENT(min_leaf_size))
    this%split_strategy = MERGE(split_strat_in, BVH_MEDIAN, PRESENT(split_strat_in))
    
    ! Allocate node array (max 2*n_objects - 1 nodes for binary BVH)
    IF (ALLOCATED(this%nodes)) DEALLOCATE(this%nodes)
    ALLOCATE(this%nodes(2*n_objects), STAT=status)
    IF (status /= 0) RETURN
    
    ! Initialize nodes array components
    DO i = 1, 2*n_objects
      this%nodes(i)%bounding_box = 0.0_wp
      this%nodes(i)%left_child = 0
      this%nodes(i)%right_child = 0
      this%nodes(i)%parent = 0
      this%nodes(i)%object_index = 0
      this%nodes(i)%n_objects = 0
      this%nodes(i)%is_leaf = .FALSE.
    END DO
    this%n_nodes = 0
    this%built = .FALSE.
    
  END SUBROUTINE BVH_Tree_Initialize
  
  SUBROUTINE BVH_Tree_Destroy(this)
    CLASS(BVH_Tree), INTENT(INOUT) :: this
    
    IF (ALLOCATED(this%nodes)) DEALLOCATE(this%nodes)
    this%n_nodes = 0
    this%n_objects = 0
    this%built = .FALSE.
    
  END SUBROUTINE BVH_Tree_Destroy
  
  SUBROUTINE BVH_Tree_GetBoundingBox(this, bb_min, bb_max, status)
    CLASS(BVH_Tree), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: bb_min(3), bb_max(3)
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    
    IF (.NOT. this%built .OR. this%n_nodes == 0) THEN
      status = -1
      RETURN
    END IF
    
    ! Root node is always at index 1
    bb_min = this%nodes(1)%bounding_box(1, :)
    bb_max = this%nodes(1)%bounding_box(2, :)
    
  END SUBROUTINE BVH_Tree_GetBoundingBox
  
  FUNCTION BVH_Tree_IsBuilt(this) RESULT(built)
    CLASS(BVH_Tree), INTENT(IN) :: this
    LOGICAL :: built
    
    built = this%built
    
  END FUNCTION BVH_Tree_IsBuilt
  
  !====================================================================
  ! BVH_TraversalStack methods
  !====================================================================
  
  SUBROUTINE BVH_Stack_Initialize(this, capacity, status)
    CLASS(BVH_TraversalStack), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: capacity
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    this%capacity = capacity
    this%top = 0
    
    ALLOCATE(this%node_indices(capacity), STAT=status)
    IF (status /= 0) RETURN
    
    this%node_indices = 0
    
  END SUBROUTINE BVH_Stack_Initialize
  
  SUBROUTINE BVH_Stack_Push(this, node_index, status)
    CLASS(BVH_TraversalStack), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: node_index
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    
    IF (this%top >= this%capacity) THEN
      status = -1  ! Stack overflow
      RETURN
    END IF
    
    this%top = this%top + 1
    this%node_indices(this%top) = node_index
    
  END SUBROUTINE BVH_Stack_Push
  
  SUBROUTINE BVH_Stack_Pop(this, node_index, status)
    CLASS(BVH_TraversalStack), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(OUT) :: node_index
    INTEGER(i4), INTENT(OUT) :: status
    
    status = 0
    
    IF (this%top <= 0) THEN
      status = -1  ! Stack underflow
      node_index = 0
      RETURN
    END IF
    
    node_index = this%node_indices(this%top)
    this%top = this%top - 1
    
  END SUBROUTINE BVH_Stack_Pop
  
  FUNCTION BVH_Stack_IsEmpty(this) RESULT(is_empty)
    CLASS(BVH_TraversalStack), INTENT(IN) :: this
    LOGICAL :: is_empty
    
    is_empty = (this%top <= 0)
    
  END FUNCTION BVH_Stack_IsEmpty
  
  SUBROUTINE BVH_Stack_Destroy(this)
    CLASS(BVH_TraversalStack), INTENT(INOUT) :: this
    
    IF (ALLOCATED(this%node_indices)) DEALLOCATE(this%node_indices)
    this%top = 0
    this%capacity = 0
    
  END SUBROUTINE BVH_Stack_Destroy
  
END MODULE NM_BVH_Def
