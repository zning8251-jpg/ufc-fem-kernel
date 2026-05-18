!===============================================================================
! MODULE: NM_BVH_Brg
! LAYER:  L2_NM
! DOMAIN: BVH
! ROLE:   Brg — thin adapter API for BVH operations
! BRIEF:  Simplified interface to BVH functionality. Re-exports types and
!         procedures from NM_BVH_Def/NM_BVH_Mgr with cleaner aliases.
!
! Status: CORE
! Last verified: 2026-04-28
!===============================================================================
MODULE NM_BVH_Brg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE NM_BVH_Def, ONLY: BVH_Tree, BVH_Node, BVH_QueryResult, &
                          BVH_MEDIAN, BVH_SAH, BVH_EQUAL_AREA
  USE NM_BVH_Mgr, ONLY: NM_BVH_Build, NM_BVH_BuildMedian, NM_BVH_BuildSAH, &
                          NM_BVH_QueryRay, NM_BVH_QueryNearest, &
                          NM_BVH_Rebuild, NM_BVH_UpdateStats
  
  IMPLICIT NONE
  
  PRIVATE
  
  ! Re-export types
  PUBLIC :: BVH_Tree, BVH_Node, BVH_QueryResult
  PUBLIC :: BVH_MEDIAN, BVH_SAH, BVH_EQUAL_AREA
  
  ! Re-export build API (with shorter aliases)
  PUBLIC :: NM_BVH_Create, BVH_Create
  PUBLIC :: NM_BVH_Destroy, BVH_Destroy
  PUBLIC :: NM_BVH_Build, BVH_Build
  PUBLIC :: NM_BVH_Rebuild, BVH_Rebuild
  
  ! Re-export query API
  PUBLIC :: BVH_RayCast
  PUBLIC :: BVH_FindNearest
  PUBLIC :: NM_BVH_QueryRay, NM_BVH_QueryNearest
  
  ! Re-export utility
  PUBLIC :: NM_BVH_IsBuilt, BVH_IsBuilt
  PUBLIC :: NM_BVH_UpdateStats
  
  ! Alternative interfaces
  INTERFACE BVH_Create
    MODULE PROCEDURE BVH_Create_Simple
  END INTERFACE
  
  INTERFACE BVH_Build
    MODULE PROCEDURE BVH_Build_Str
  END INTERFACE
  
  INTERFACE BVH_RayCast
    MODULE PROCEDURE BVH_RayCast_Simple
  END INTERFACE
  
  INTERFACE BVH_FindNearest
    MODULE PROCEDURE BVH_FindNearest_Simple
  END INTERFACE

  INTERFACE BVH_Destroy
    MODULE PROCEDURE NM_BVH_Destroy
  END INTERFACE

  INTERFACE BVH_Rebuild
    MODULE PROCEDURE BVH_Rebuild_Wrap
  END INTERFACE

  INTERFACE BVH_IsBuilt
    MODULE PROCEDURE NM_BVH_IsBuilt
  END INTERFACE
  
CONTAINS

  !====================================================================
  ! Simplified Create/Destroy
  !====================================================================
  
  SUBROUTINE NM_BVH_Create(bvh, n_objects, max_depth, min_leaf_size, &
                           split_strategy, status)
    !! Create and initialize BVH tree
    TYPE(BVH_Tree), INTENT(OUT) :: bvh
    INTEGER(i4), INTENT(IN) :: n_objects
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_depth
    INTEGER(i4), INTENT(IN), OPTIONAL :: min_leaf_size
    INTEGER(i4), INTENT(IN), OPTIONAL :: split_strategy
    INTEGER(i4), INTENT(OUT) :: status
    
    CALL bvh%Initialize(n_objects, max_depth, min_leaf_size, &
                       split_strategy, status)
    
  END SUBROUTINE NM_BVH_Create
  
  SUBROUTINE BVH_Create_Simple(bvh, n_objects, status)
    TYPE(BVH_Tree), INTENT(OUT) :: bvh
    INTEGER(i4), INTENT(IN) :: n_objects
    INTEGER(i4), INTENT(OUT) :: status
    
    CALL bvh%Initialize(n_objects, status=status)
    
  END SUBROUTINE BVH_Create_Simple
  
  SUBROUTINE NM_BVH_Destroy(bvh)
    !! Destroy BVH tree and free memory
    TYPE(BVH_Tree), INTENT(INOUT) :: bvh
    
    CALL bvh%Destroy()
    
  END SUBROUTINE NM_BVH_Destroy
  
  !====================================================================
  ! Simplified Build
  !====================================================================
  
  SUBROUTINE BVH_Build_Str(bvh, object_boxes, strategy, status)
    TYPE(BVH_Tree), INTENT(INOUT) :: bvh
    REAL(wp), INTENT(IN) :: object_boxes(:,:)
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: strategy
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: local_strategy
    
    local_strategy = BVH_MEDIAN  ! Default
    IF (PRESENT(strategy)) THEN
      SELECT CASE (TRIM(ADJUSTL(strategy)))
      CASE ('SAH')
        local_strategy = BVH_SAH
      CASE ('MEDIAN')
        local_strategy = BVH_MEDIAN
      CASE ('EQUAL_AREA')
        local_strategy = BVH_EQUAL_AREA
      END SELECT
    END IF
    
    CALL NM_BVH_Build(bvh, object_boxes, local_strategy, status)
    
  END SUBROUTINE BVH_Build_Str
  
  !====================================================================
  ! Simplified Query
  !====================================================================
  
  SUBROUTINE BVH_RayCast_Simple(bvh, ray_origin, ray_direction, max_distance, &
                                hit_objects, n_hits, status)
    TYPE(BVH_Tree), INTENT(IN) :: bvh
    REAL(wp), INTENT(IN) :: ray_origin(3)
    REAL(wp), INTENT(IN) :: ray_direction(3)
    REAL(wp), INTENT(IN) :: max_distance
    INTEGER(i4), INTENT(OUT) :: hit_objects(:)
    INTEGER(i4), INTENT(OUT) :: n_hits
    INTEGER(i4), INTENT(OUT) :: status
    
    CALL NM_BVH_QueryRay(bvh, ray_origin, ray_direction, max_distance, &
                        hit_objects, n_hits, status)
    
  END SUBROUTINE BVH_RayCast_Simple
  
  SUBROUTINE BVH_FindNearest_Simple(bvh, point, nearest_object, distance, status)
    TYPE(BVH_Tree), INTENT(IN) :: bvh
    REAL(wp), INTENT(IN) :: point(3)
    INTEGER(i4), INTENT(OUT) :: nearest_object
    REAL(wp), INTENT(OUT) :: distance
    INTEGER(i4), INTENT(OUT) :: status
    
    CALL NM_BVH_QueryNearest(bvh, point, nearest_object, distance, status)
    
  END SUBROUTINE BVH_FindNearest_Simple
  
  !====================================================================
  ! Utility Functions
  !====================================================================
  
  FUNCTION NM_BVH_IsBuilt(bvh) RESULT(built)
    !! Check if BVH is built
    TYPE(BVH_Tree), INTENT(IN) :: bvh
    LOGICAL :: built
    
    built = bvh%IsBuilt()
    
  END FUNCTION NM_BVH_IsBuilt

  SUBROUTINE BVH_Rebuild_Wrap(bvh, new_object_boxes, status)
    TYPE(BVH_Tree), INTENT(INOUT) :: bvh
    REAL(wp), INTENT(IN) :: new_object_boxes(:,:)
    INTEGER(i4), INTENT(OUT) :: status
    CALL NM_BVH_Rebuild(bvh, new_object_boxes, status)
  END SUBROUTINE BVH_Rebuild_Wrap
  
END MODULE NM_BVH_Brg
