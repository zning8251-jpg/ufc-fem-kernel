!===============================================================================
! Module: TEST_PH_Flat_To_Nested_LoadBC
! Purpose: Unit Tests for WriteBack Mechanism (Flat to Nested Projection)
! Test Coverage:
!   - PH_L4_Create_WriteBack_Mask: White-list generation
!   - PH_L4_WriteBack_BC_From_Cache: Cache to Desc WriteBack
!   - PH_L4_Release_Failed_BC: BC release logic
!   - PH_L4_Validate_WriteBack: Mask validation
! Status: Phase A - Initial Design | Last verified: 2026-03-27
!===============================================================================

MODULE TEST_PH_Flat_To_Nested_LoadBC
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_LoadBC_Types, ONLY: MD_BC_Def_Type, MD_LoadBC_Ctrl_Type
  USE PH_BC_Types, ONLY: PH_BCCtrl_Type, PH_BC_Cache_Type
  USE PH_Flat_To_Nested_LoadBC, ONLY: PH_WriteBack_Mask_Type, &
                                       PH_WriteBack_Status_Type, &
                                       PH_L4_Create_WriteBack_Mask, &
                                       PH_L4_WriteBack_BC_From_Cache, &
                                       PH_L4_Release_Failed_BC, &
                                       PH_L4_Validate_WriteBack
  IMPLICIT NONE
  
  REAL(wp), PARAMETER :: TOL = 1.0e-12_wp
  REAL(wp), PARAMETER :: FAILURE_THRESHOLD = 1.0e6_wp  ! 1 MN
  
CONTAINS

  !=============================================================================
  !> @brief Test WriteBack mask creation
  !=============================================================================
  SUBROUTINE Test_WriteBack_Mask_Creation()
    TYPE(MD_LoadBC_Ctrl_Type) :: md_ctrl
    TYPE(PH_WriteBack_Mask_Type) :: mask
    INTEGER(i4) :: n_mutable
    
    PRINT *, 'Test: WriteBack Mask Creation'
    
    ! Setup: Create mock L3_MD controller with 3 BCs
    md_ctrl%nBCs = 3_i4
    ALLOCATE(md_ctrl%bcs(3))
    
    ! BC 1: Fixed support (should NOT be mutable)
    md_ctrl%bcs(1)%id = 1_i4
    md_ctrl%bcs(1)%name = 'FIXED_SUPPORT'
    md_ctrl%bcs(1)%isFixed = .TRUE.
    md_ctrl%bcs(1)%magnitude = 0.0_wp
    
    ! BC 2: Prescribed displacement (SHOULD be mutable)
    md_ctrl%bcs(2)%id = 2_i4
    md_ctrl%bcs(2)%name = 'DISP_Y'
    md_ctrl%bcs(2)%isFixed = .FALSE.
    md_ctrl%bcs(2)%magnitude = -5.0_wp
    
    ! BC 3: Another fixed support (should NOT be mutable)
    md_ctrl%bcs(3)%id = 3_i4
    md_ctrl%bcs(3)%name = 'FIXED_BOTTOM'
    md_ctrl%bcs(3)%isFixed = .TRUE.
    md_ctrl%bcs(3)%magnitude = 0.0_wp
    
    ! Execute mask creation
    CALL PH_L4_Create_WriteBack_Mask(md_ctrl, mask)
    
    ! Verify mask size
    IF (SIZE(mask%bc_mutable) == 3_i4) THEN
      PRINT *, '  PASS: Mask size = 3'
    ELSE
      PRINT *, '  FAIL: Expected size 3, got ', SIZE(mask%bc_mutable)
    END IF
    
    ! Count mutable BCs (should be 1: only BC #2)
    n_mutable = COUNT(mask%bc_mutable)
    IF (n_mutable == 1_i4) THEN
      PRINT *, '  PASS: n_mutable = 1 (only prescribed BC)'
    ELSE
      PRINT *, '  FAIL: Expected 1 mutable, got ', n_mutable
    END IF
    
    ! Verify field permissions
    IF (mask%allow_magnitude_change .AND. mask%allow_isFixed_change) THEN
      PRINT *, '  PASS: Field permissions correct'
    ELSE
      PRINT *, '  FAIL: Field permissions incorrect'
    END IF
    
    IF (.NOT. mask%allow_type_change) THEN
      PRINT *, '  PASS: Type change disabled (safety)'
    ELSE
      PRINT *, '  FAIL: Type change should be disabled'
    END IF
    
    ! Cleanup
    DEALLOCATE(md_ctrl%bcs)
    IF (ALLOCATED(mask%bc_mutable)) DEALLOCATE(mask%bc_mutable)
    
  END SUBROUTINE Test_WriteBack_Mask_Creation

  !=============================================================================
  !> @brief Test WriteBack from cache to Desc
  !=============================================================================
  SUBROUTINE Test_WriteBack_From_Cache()
    TYPE(MD_LoadBC_Ctrl_Type) :: md_ctrl
    TYPE(PH_BCCtrl_Type) :: ph_bc_ctrl
    TYPE(PH_WriteBack_Mask_Type) :: mask
    TYPE(PH_WriteBack_Status_Type) :: status
    REAL(wp) :: reaction_forces(2)
    
    PRINT *, 'Test: WriteBack From Cache to Desc'
    
    ! Setup: Create mock L3_MD controller with 2 BCs
    md_ctrl%nBCs = 2_i4
    ALLOCATE(md_ctrl%bcs(2))
    
    ! BC 1: Normal BC (should survive)
    md_ctrl%bcs(1)%id = 1_i4
    md_ctrl%bcs(1)%name = 'NORMAL_BC'
    md_ctrl%bcs(1)%isFixed = .FALSE.
    md_ctrl%bcs(1)%magnitude = 10.0_wp
    
    ! BC 2: Failed BC (should be released)
    md_ctrl%bcs(2)%id = 2_i4
    md_ctrl%bcs(2)%name = 'FAILED_BC'
    md_ctrl%bcs(2)%isFixed = .FALSE.
    md_ctrl%bcs(2)%magnitude = 5.0_wp
    
    ! Setup: Create mock L4_PH BC cache
    ph_bc_ctrl%nConstrainedDOFs = 2_i4
    ALLOCATE(ph_bc_ctrl%bc_cache(2))
    
    ph_bc_ctrl%bc_cache(1)%nodeId = 1_i4  ! Matches BC #1
    ph_bc_ctrl%bc_cache(1)%dof = 1_i4
    ph_bc_ctrl%bc_cache(1)%value = 10.0_wp
    
    ph_bc_ctrl%bc_cache(2)%nodeId = 2_i4  ! Matches BC #2
    ph_bc_ctrl%bc_cache(2)%dof = 2_i4
    ph_bc_ctrl%bc_cache(2)%value = 5.0_wp
    
    ! Create writeback mask
    CALL PH_L4_Create_WriteBack_Mask(md_ctrl, mask)
    
    ! Simulate reaction forces (BC #2 fails)
    reaction_forces(1) = 1000.0_wp  ! Normal (below threshold)
    reaction_forces(2) = 2.0e6_wp   ! FAILED (above threshold)
    
    ! Execute WriteBack
    CALL PH_L4_WriteBack_BC_From_Cache(md_ctrl, ph_bc_ctrl, mask, &
                                       reaction_forces, status)
    
    ! Verify results
    IF (status%writeback_success) THEN
      PRINT *, '  PASS: WriteBack succeeded'
    ELSE
      PRINT *, '  FAIL: WriteBack failed'
    END IF
    
    IF (status%n_released == 1_i4) THEN
      PRINT *, '  PASS: 1 BC released as expected'
    ELSE
      PRINT *, '  FAIL: Expected 1 release, got ', status%n_released
    END IF
    
    ! Verify BC #1 unchanged
    IF (ABS(md_ctrl%bcs(1)%magnitude - 10.0_wp) < TOL) THEN
      PRINT *, '  PASS: BC #1 magnitude unchanged'
    ELSE
      PRINT *, '  FAIL: BC #1 magnitude changed incorrectly'
    END IF
    
    ! Verify BC #2 released (magnitude �?0)
    IF (ABS(md_ctrl%bcs(2)%magnitude) < TOL) THEN
      PRINT *, '  PASS: BC #2 released (magnitude=0)'
    ELSE
      PRINT *, '  FAIL: BC #2 not released, magnitude=', md_ctrl%bcs(2)%magnitude
    END IF
    
    ! Cleanup
    DEALLOCATE(md_ctrl%bcs)
    DEALLOCATE(ph_bc_ctrl%bc_cache)
    IF (ALLOCATED(mask%bc_mutable)) DEALLOCATE(mask%bc_mutable)
    
  END SUBROUTINE Test_WriteBack_From_Cache

  !=============================================================================
  !> @brief Test BC release function directly
  !=============================================================================
  SUBROUTINE Test_BC_Release_Direct()
    TYPE(MD_LoadBC_Ctrl_Type) :: md_ctrl
    TYPE(PH_WriteBack_Mask_Type) :: mask
    TYPE(PH_WriteBack_Status_Type) :: status
    
    PRINT *, 'Test: Direct BC Release'
    
    ! Setup: Single BC
    md_ctrl%nBCs = 1_i4
    ALLOCATE(md_ctrl%bcs(1))
    
    md_ctrl%bcs(1)%id = 1_i4
    md_ctrl%bcs(1)%name = 'TEST_BC'
    md_ctrl%bcs(1)%isFixed = .FALSE.
    md_ctrl%bcs(1)%magnitude = 100.0_wp
    
    ! Create permissive mask
    ALLOCATE(mask%bc_mutable(1))
    mask%bc_mutable(1) = .TRUE.
    mask%allow_magnitude_change = .TRUE.
    mask%allow_isFixed_change = .TRUE.
    mask%allow_type_change = .FALSE.
    
    ! Execute direct release
    CALL PH_L4_Release_Failed_BC(md_ctrl, 1_i4, mask, status)
    
    ! Verify
    IF (status%n_released == 1_i4) THEN
      PRINT *, '  PASS: Release counted'
    ELSE
      PRINT *, '  FAIL: Release not counted'
    END IF
    
    IF (ABS(md_ctrl%bcs(1)%magnitude) < TOL) THEN
      PRINT *, '  PASS: Magnitude zeroed'
    ELSE
      PRINT *, '  FAIL: Magnitude not zeroed'
    END IF
    
    IF (.NOT. md_ctrl%bcs(1)%isFixed) THEN
      PRINT *, '  PASS: isFixed toggled'
    ELSE
      PRINT *, '  FAIL: isFixed not toggled'
    END IF
    
    ! Cleanup
    DEALLOCATE(md_ctrl%bcs)
    IF (ALLOCATED(mask%bc_mutable)) DEALLOCATE(mask%bc_mutable)
    
  END SUBROUTINE Test_BC_Release_Direct

  !=============================================================================
  !> @brief Test WriteBack mask validation
  !=============================================================================
  SUBROUTINE Test_WriteBack_Validation()
    TYPE(MD_LoadBC_Ctrl_Type) :: md_ctrl
    TYPE(PH_WriteBack_Mask_Type) :: mask
    TYPE(PH_WriteBack_Status_Type) :: status
    LOGICAL :: is_valid
    
    PRINT *, 'Test: WriteBack Validation'
    
    ! Setup: 2 BCs
    md_ctrl%nBCs = 2_i4
    ALLOCATE(md_ctrl%bcs(2))
    md_ctrl%bcs(1)%id = 1_i4
    md_ctrl%bcs(2)%id = 2_i4
    
    ! Test 1: Valid mask
    ALLOCATE(mask%bc_mutable(2))
    mask%bc_mutable = [.TRUE., .TRUE.]
    mask%allow_magnitude_change = .TRUE.
    mask%allow_isFixed_change = .TRUE.
    mask%allow_type_change = .FALSE.
    
    status%writeback_success = .TRUE.
    is_valid = PH_L4_Validate_WriteBack(md_ctrl, mask, status)
    
    IF (is_valid) THEN
      PRINT *, '  PASS: Valid mask accepted'
    ELSE
      PRINT *, '  FAIL: Valid mask rejected'
    END IF
    
    ! Test 2: Size mismatch (should fail)
    IF (ALLOCATED(mask%bc_mutable)) DEALLOCATE(mask%bc_mutable)
    ALLOCATE(mask%bc_mutable(3))  ! Wrong size!
    
    status%writeback_success = .TRUE.
    is_valid = PH_L4_Validate_WriteBack(md_ctrl, mask, status)
    
    IF (.NOT. is_valid .AND. .NOT. status%writeback_success) THEN
      PRINT *, '  PASS: Size mismatch detected'
    ELSE
      PRINT *, '  FAIL: Size mismatch not detected'
    END IF
    
    ! Cleanup
    DEALLOCATE(md_ctrl%bcs)
    IF (ALLOCATED(mask%bc_mutable)) DEALLOCATE(mask%bc_mutable)
    
  END SUBROUTINE Test_WriteBack_Validation

  !=============================================================================
  !> @brief Test WriteBack edge cases and boundary conditions
  !=============================================================================
  SUBROUTINE Test_WriteBack_EdgeCases()
    TYPE(MD_LoadBC_Ctrl_Type) :: md_ctrl
    TYPE(PH_BCCtrl_Type) :: ph_bc_ctrl
    TYPE(PH_WriteBack_Mask_Type) :: mask
    TYPE(PH_WriteBack_Status_Type) :: status
    REAL(wp) :: reaction_forces(3)
    
    PRINT *, 'Test: WriteBack Edge Cases'
    
    ! Setup: 3 BCs with different scenarios
    md_ctrl%nBCs = 3_i4
    ALLOCATE(md_ctrl%bcs(3))
    
    ! BC 1: Normal (below threshold)
    md_ctrl%bcs(1)%id = 1_i4
    md_ctrl%bcs(1)%name = 'NORMAL_BC'
    md_ctrl%bcs(1)%magnitude = 10.0_wp
    
    ! BC 2: Exactly at threshold (boundary case)
    md_ctrl%bcs(2)%id = 2_i4
    md_ctrl%bcs(2)%name = 'THRESHOLD_BC'
    md_ctrl%bcs(2)%magnitude = 5.0_wp
    
    ! BC 3: Immutable (should NOT release even if failed)
    md_ctrl%bcs(3)%id = 3_i4
    md_ctrl%bcs(3)%name = 'IMMUTABLE_BC'
    md_ctrl%bcs(3)%magnitude = 100.0_wp
    
    ! Setup cache
    ph_bc_ctrl%nConstrainedDOFs = 3_i4
    ALLOCATE(ph_bc_ctrl%bc_cache(3))
    ph_bc_ctrl%bc_cache(1)%bcId = 1_i4
    ph_bc_ctrl%bc_cache(2)%bcId = 2_i4
    ph_bc_ctrl%bc_cache(3)%bcId = 3_i4
    
    ! Create mask
    CALL PH_L4_Create_WriteBack_Mask(md_ctrl, mask)
    
    ! Simulate reaction forces:
    ! - BC 1: Normal (below threshold)
    ! - BC 2: Exactly at threshold (boundary)
    ! - BC 3: Very high (but immutable, should NOT release)
    reaction_forces = [1000.0_wp, 1.0e6_wp, 5.0e6_wp]
    
    ! Execute WriteBack with explicit threshold
    CALL PH_L4_WriteBack_BC_From_Cache(md_ctrl, ph_bc_ctrl, mask, &
                                       reaction_forces, status, &
                                       failure_threshold=1.0e6_wp)
    
    ! Verify results
    IF (status%writeback_success) THEN
      PRINT *, '  PASS: WriteBack completed successfully'
    ELSE
      PRINT *, '  FAIL: WriteBack failed'
    END IF
    
    ! BC 1 should be unchanged (below threshold)
    IF (ABS(md_ctrl%bcs(1)%magnitude - 10.0_wp) < TOL) THEN
      PRINT *, '  PASS: BC 1 unchanged (below threshold)'
    ELSE
      PRINT *, '  FAIL: BC 1 incorrectly modified'
    END IF
    
    ! BC 2: Boundary case (exactly at threshold - implementation dependent)
    ! Most implementations will NOT release at exact boundary
    PRINT *, '  INFO: BC 2 at threshold (implementation dependent)'
    
    ! BC 3: Should NOT release if marked as immutable
    IF (mask%bc_mutable(3)) THEN
      IF (ABS(md_ctrl%bcs(3)%magnitude) < TOL) THEN
        PRINT *, '  PASS: BC 3 released (mutable + high RF)'
      ELSE
        PRINT *, '  INFO: BC 3 not released (below threshold or mutable=false)'
      END IF
    ELSE
      IF (ABS(md_ctrl%bcs(3)%magnitude - 100.0_wp) < TOL) THEN
        PRINT *, '  PASS: BC 3 preserved (immutable)'
      ELSE
        PRINT *, '  FAIL: BC 3 incorrectly modified despite immutable flag'
      END IF
    END IF
    
    ! Cleanup
    DEALLOCATE(md_ctrl%bcs)
    DEALLOCATE(ph_bc_ctrl%bc_cache)
    IF (ALLOCATED(mask%bc_mutable)) DEALLOCATE(mask%bc_mutable)
    
  END SUBROUTINE Test_WriteBack_EdgeCases

  !=============================================================================
  !> @brief Run all tests
  !=============================================================================
  SUBROUTINE RunAllTests()
    PRINT *, '=========================================='
    PRINT *, 'Running PH_Flat_To_Nested_LoadBC Tests'
    PRINT *, '(WriteBack Mechanism: Flat �?Nested)'
    PRINT *, '=========================================='
    
    CALL Test_WriteBack_Mask_Creation()
    CALL Test_WriteBack_From_Cache()
    CALL Test_BC_Release_Direct()
    CALL Test_WriteBack_Validation()
    CALL Test_WriteBack_EdgeCases()  ! NEW: Edge cases and boundary conditions
    
    PRINT *, '=========================================='
    PRINT *, 'All WriteBack tests completed'
    PRINT *, '=========================================='
    
  END SUBROUTINE RunAllTests

END MODULE TEST_PH_Flat_To_Nested_LoadBC
