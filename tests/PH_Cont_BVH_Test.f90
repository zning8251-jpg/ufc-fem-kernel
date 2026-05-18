!===============================================================================
! Module: PH_Cont_BVH_Test
! Layer:  L4_PH - Physics Layer
! Domain: Contact - BVH Algorithm Tests
! Purpose: Unit tests for BVH construction and query algorithms
! Status: Phase 3 Test - Implementation | 2026-03-27
!===============================================================================

MODULE PH_Cont_BVH_Test
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE PH_Cont_Types, ONLY: PH_Contact_BVH_Node, PH_Contact_Surface_Desc
  USE PH_Cont_BVH_Builder, ONLY: PH_Cont_ComputeBoundingBox, PH_Cont_BoxesOverlap, &
                                 PH_Cont_BuildBVH_FromSurface
  USE PH_Cont_Test_Framework, ONLY: PH_Cont_Test_Case, PH_TEST_PASS, PH_TEST_FAIL, &
                                    PH_TEST_TOLERANCE, PH_Cont_Assert
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_Cont_Test_BVH_BoundingBox
  PUBLIC :: PH_Cont_Test_BVH_Overlap
  PUBLIC :: PH_Cont_Test_BVH_Build
  PUBLIC :: PH_Cont_Run_All_BVH_Tests
  
CONTAINS

  !===========================================================================
  !> @brief Test bounding box computation
  !===========================================================================
  SUBROUTINE PH_Cont_Test_BVH_BoundingBox(test_case, status)
    TYPE(PH_Cont_Test_Case), INTENT(INOUT) :: test_case
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp), ALLOCATABLE :: coords(:,:)
    REAL(wp) :: bbox_min(3), bbox_max(3)
    REAL(wp) :: expected_min(3), expected_max(3)
    INTEGER(i4) :: i
    LOGICAL :: all_pass
    
    CALL test_case%Init('BVH_BoundingBox', 'Test bounding box computation')
    
    ! Create simple test case: 4 points forming a cube
    ALLOCATE(coords(3, 4))
    coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    coords(:, 3) = [0.0_wp, 1.0_wp, 0.0_wp]
    coords(:, 4) = [0.0_wp, 0.0_wp, 1.0_wp]
    
    ! Compute bounding box
    CALL PH_Cont_ComputeBoundingBox(coords, bbox_min, bbox_max)
    
    ! Expected results
    expected_min = [0.0_wp, 0.0_wp, 0.0_wp]
    expected_max = [1.0_wp, 1.0_wp, 1.0_wp]
    
    ! Verify
    all_pass = .TRUE.
    DO i = 1, 3
      IF (ABS(bbox_min(i) - expected_min(i)) > PH_TEST_TOLERANCE) THEN
        all_pass = .FALSE.
        EXIT
      END IF
      IF (ABS(bbox_max(i) - expected_max(i)) > PH_TEST_TOLERANCE) THEN
        all_pass = .FALSE.
        EXIT
      END IF
    END DO
    
    IF (all_pass) THEN
      status = PH_TEST_PASS
    ELSE
      status = PH_TEST_FAIL
      WRITE(test_case%message, '(A)') 'Bounding box mismatch'
    END IF
    
    DEALLOCATE(coords)
    
  END SUBROUTINE PH_Cont_Test_BVH_BoundingBox
  
  !===========================================================================
  !> @brief Test bounding box overlap detection
  !===========================================================================
  SUBROUTINE PH_Cont_Test_BVH_Overlap(test_case, status)
    TYPE(PH_Cont_Test_Case), INTENT(INOUT) :: test_case
    INTEGER(i4), INTENT(OUT) :: status
    
    REAL(wp) :: min1(3), max1(3), min2(3), max2(3)
    LOGICAL :: overlap
    LOGICAL :: test1, test2, test3
    
    CALL test_case%Init('BVH_Overlap', 'Test bounding box overlap detection')
    
    ! Test 1: Overlapping boxes
    min1 = [0.0_wp, 0.0_wp, 0.0_wp]
    max1 = [2.0_wp, 2.0_wp, 2.0_wp]
    min2 = [1.0_wp, 1.0_wp, 1.0_wp]
    max2 = [3.0_wp, 3.0_wp, 3.0_wp]
    
    overlap = PH_Cont_BoxesOverlap(min1, max1, min2, max2)
    test1 = overlap
    
    ! Test 2: Non-overlapping boxes (separated in X)
    min2 = [3.0_wp, 1.0_wp, 1.0_wp]
    max2 = [4.0_wp, 2.0_wp, 2.0_wp]
    
    overlap = PH_Cont_BoxesOverlap(min1, max1, min2, max2)
    test2 = (.NOT. overlap)
    
    ! Test 3: Touching boxes (edge contact)
    min2 = [2.0_wp, 0.0_wp, 0.0_wp]
    max2 = [3.0_wp, 1.0_wp, 1.0_wp]
    
    overlap = PH_Cont_BoxesOverlap(min1, max1, min2, max2)
    test3 = overlap  ! Should detect as overlapping (with tolerance)
    
    IF (test1 .AND. test2 .AND. test3) THEN
      status = PH_TEST_PASS
    ELSE
      status = PH_TEST_FAIL
      WRITE(test_case%message, '(A)') 'Overlap detection failed'
    END IF
    
  END SUBROUTINE PH_Cont_Test_BVH_Overlap
  
  !===========================================================================
  !> @brief Test BVH tree construction
  !===========================================================================
  SUBROUTINE PH_Cont_Test_BVH_Build(test_case, status)
    TYPE(PH_Cont_Test_Case), INTENT(INOUT) :: test_case
    INTEGER(i4), INTENT(OUT) :: status
    
    TYPE(PH_Contact_Surface_Desc) :: surface
    INTEGER(i4) :: build_status, n_nodes, n_segments
    INTEGER(i4) :: i, j
    LOGICAL :: bvh_built
    
    CALL test_case%Init('BVH_Build', 'Test BVH tree construction from surface')
    
    ! Create simple surface: 4 nodes, 1 quad segment
    n_nodes = 4_i4
    n_segments = 1_i4
    
    surface%surface_id = 1_i4
    surface%surface_name = 'Test_Surface'
    surface%n_nodes = n_nodes
    surface%n_segments = n_segments
    
    ! Allocate arrays
    ALLOCATE(surface%node_ids(n_nodes))
    ALLOCATE(surface%segment_conn(4, n_segments))
    ALLOCATE(surface%coords(3, n_nodes))
    ALLOCATE(surface%normals(3, n_nodes))
    
    ! Set node IDs
    surface%node_ids = [(i, i=1, n_nodes)]
    
    ! Set segment connectivity (quad)
    surface%segment_conn(:, 1) = [1, 2, 3, 4]
    
    ! Set coordinates (square in XY plane)
    surface%coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
    surface%coords(:, 2) = [1.0_wp, 0.0_wp, 0.0_wp]
    surface%coords(:, 3) = [1.0_wp, 1.0_wp, 0.0_wp]
    surface%coords(:, 4) = [0.0_wp, 1.0_wp, 0.0_wp]
    
    ! Set normals (all in Z direction)
    surface%normals(:, :) = [0.0_wp, 0.0_wp, 1.0_wp]
    
    ! Build BVH
    CALL PH_Cont_BuildBVH_FromSurface(surface, build_status)
    
    ! Verify BVH was built
    bvh_built = ASSOCIATED(surface%bvh_root)
    
    IF (bvh_built .AND. build_status == 0) THEN
      ! Verify root node bounding box
      IF (surface%bvh_root%bbox_min(1) >= 0.0_wp .AND. &
          surface%bvh_root%bbox_max(1) <= 1.0_wp .AND. &
          surface%bvh_root%bbox_min(2) >= 0.0_wp .AND. &
          surface%bvh_root%bbox_max(2) <= 1.0_wp .AND. &
          ABS(surface%bvh_root%bbox_min(3)) <= 1.0e-10_wp .AND. &
          ABS(surface%bvh_root%bbox_max(3)) <= 1.0e-10_wp) THEN
        status = PH_TEST_PASS
      ELSE
        status = PH_TEST_FAIL
        WRITE(test_case%message, '(A)') 'Root bounding box incorrect'
      END IF
    ELSE
      status = PH_TEST_FAIL
      WRITE(test_case%message, '(A,I0)'), 'BVH build failed with status: ', build_status
    END IF
    
    ! Cleanup
    IF (ASSOCIATED(surface%bvh_root)) THEN
      ! TODO: Implement BVH tree deallocation
      DEALLOCATE(surface%bvh_root)
    END IF
    DEALLOCATE(surface%node_ids)
    DEALLOCATE(surface%segment_conn)
    DEALLOCATE(surface%coords)
    DEALLOCATE(surface%normals)
    
  END SUBROUTINE PH_Cont_Test_BVH_Build
  
  !===========================================================================
  !> @brief Run all BVH tests
  !===========================================================================
  SUBROUTINE PH_Cont_Run_All_BVH_Tests()
    TYPE(PH_Cont_Test_Case) :: test1, test2, test3
    INTEGER(i4) :: status
    
    PRINT *, ''
    PRINT *, '=========================================='
    PRINT *, 'Running BVH Algorithm Tests'
    PRINT *, '=========================================='
    
    ! Test 1: Bounding box
    CALL PH_Cont_Test_BVH_BoundingBox(test1, status)
    IF (status == PH_TEST_PASS) THEN
      PRINT '(A)', '  [PASS] BVH_BoundingBox'
    ELSE
      PRINT '(A,A)', '  [FAIL] BVH_BoundingBox: ', TRIM(test1%message)
    END IF
    
    ! Test 2: Overlap detection
    CALL PH_Cont_Test_BVH_Overlap(test2, status)
    IF (status == PH_TEST_PASS) THEN
      PRINT '(A)', '  [PASS] BVH_Overlap'
    ELSE
      PRINT '(A,A)', '  [FAIL] BVH_Overlap: ', TRIM(test2%message)
    END IF
    
    ! Test 3: BVH build
    CALL PH_Cont_Test_BVH_Build(test3, status)
    IF (status == PH_TEST_PASS) THEN
      PRINT '(A)', '  [PASS] BVH_Build'
    ELSE
      PRINT '(A,A)', '  [FAIL] BVH_Build: ', TRIM(test3%message)
    END IF
    
    PRINT *, '=========================================='
    
  END SUBROUTINE PH_Cont_Run_All_BVH_Tests
  
END MODULE PH_Cont_BVH_Test
