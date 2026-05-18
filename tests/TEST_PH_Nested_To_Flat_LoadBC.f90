!===============================================================================
! Module: TEST_PH_Nested_To_Flat_LoadBC
! Purpose: Unit Tests for PH_Nested_To_Flat_LoadBC Projection
! Test Coverage:
!   - PH_L4_Populate_Load: Load cache population from L3_Desc
!   - PH_L4_Populate_BC: BC cache population from L3_Desc
!   - PH_InterpolateAmpCurve: Amplitude interpolation (tabular/smooth step)
! Status: Phase A - Initial Design | Last verified: 2026-03-27
!===============================================================================

MODULE TEST_PH_Nested_To_Flat_LoadBC
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_LoadBC_Types, ONLY: MD_BC_Def_Type, MD_Load_Def_Type, MD_LoadBC_Ctrl_Type
  USE PH_Load_Types, ONLY: PH_LoadCtrl_Type
  USE PH_BC_Types, ONLY: PH_BCCtrl_Type
  USE PH_Nested_To_Flat_LoadBC, ONLY: PH_L4_Populate_Load, PH_L4_Populate_BC, &
                                       PH_InterpolateAmpCurve
  IMPLICIT NONE
  
  REAL(wp), PARAMETER :: TOL = 1.0e-12_wp
  
CONTAINS

  !=============================================================================
  !> @brief Test amplitude interpolation (tabular curve)
  !=============================================================================
  SUBROUTINE Test_AmpInterpolation_Tabular()
    REAL(wp) :: amp_factor
    
    PRINT *, 'Test: Amplitude Interpolation (Tabular)'
    
    ! TODO: Create mock amplitude curve
    ! Example data: [(0.0, 0.0), (1.0, 1.0), (2.0, 0.5)]
    ! Test linear interpolation at t=0.5 -> expected 0.5
    ! Test extrapolation at t=3.0 -> expected 0.5
    
    ! Mock test (placeholder until amplitude container defined)
    amp_factor = PH_InterpolateAmpCurve('', 0.5_wp)
    
    IF (ABS(amp_factor - 1.0_wp) < TOL) THEN
      PRINT *, '  PASS: Default amplitude = 1.0'
    ELSE
      PRINT *, '  FAIL: Expected 1.0, got ', amp_factor
    END IF
    
  END SUBROUTINE Test_AmpInterpolation_Tabular

  !=============================================================================
  !> @brief Test amplitude interpolation boundary cases
  !=============================================================================
  SUBROUTINE Test_AmpInterpolation_BoundaryCases()
    REAL(wp) :: amp_factor
    LOGICAL :: pass_all
    
    PRINT *, 'Test: Amplitude Interpolation Boundary Cases'
    
    pass_all = .TRUE.
    
    ! Test 1: Empty amplitude name -> default 1.0
    amp_factor = PH_InterpolateAmpCurve('', 0.0_wp)
    IF (ABS(amp_factor - 1.0_wp) < TOL) THEN
      PRINT *, '  PASS: Empty name -> 1.0'
    ELSE
      PRINT *, '  FAIL: Expected 1.0, got ', amp_factor
      pass_all = .FALSE.
    END IF
    
    ! Test 2: Negative time -> should handle gracefully (extrapolation)
    amp_factor = PH_InterpolateAmpCurve('DUMMY_AMP', -1.0_wp)
    IF (amp_factor >= 0.0_wp) THEN  ! At least non-negative
      PRINT *, '  PASS: Negative time handled (amp_factor=', amp_factor, ')'
    ELSE
      PRINT *, '  FAIL: Negative time returned negative amp_factor: ', amp_factor
      pass_all = .FALSE.
    END IF
    
    ! Test 3: Very large time -> should not crash
    amp_factor = PH_InterpolateAmpCurve('DUMMY_AMP', 1.0e10_wp)
    IF (amp_factor >= 0.0_wp) THEN
      PRINT *, '  PASS: Large time handled (amp_factor=', amp_factor, ')'
    ELSE
      PRINT *, '  FAIL: Large time caused issues'
      pass_all = .FALSE.
    END IF
    
    ! Summary
    IF (pass_all) THEN
      PRINT *, '  ALL BOUNDARY TESTS PASSED'
    ELSE
      PRINT *, '  SOME BOUNDARY TESTS FAILED'
    END IF
    
  END SUBROUTINE Test_AmpInterpolation_BoundaryCases

  !=============================================================================
  !> @brief Test load cache population
  !=============================================================================
  SUBROUTINE Test_LoadCache_Population()
    TYPE(MD_LoadBC_Ctrl_Type) :: md_ctrl
    TYPE(PH_LoadCtrl_Type) :: ph_load_ctrl
    REAL(wp) :: step_time
    INTEGER(i4) :: i
    
    PRINT *, 'Test: Load Cache Population'
    
    ! Setup: Create mock L3_MD controller with 2 loads
    md_ctrl%nLoads = 2_i4
    ALLOCATE(md_ctrl%loads(2))
    
    ! Load 1: CLOAD, stepId=1, magnitude=[100,0,0], no amplitude
    md_ctrl%loads(1)%id = 1_i4
    md_ctrl%loads(1)%name = 'CLOAD_1'
    md_ctrl%loads(1)%stepId = 1_i4
    md_ctrl%loads(1)%loadType = 'CLOAD'
    md_ctrl%loads(1)%target = 'NODE_TOP'
    md_ctrl%loads(1)%magnitude = [100.0_wp, 0.0_wp, 0.0_wp]
    md_ctrl%loads(1)%ampName = ''
    
    ! Load 2: GRAVITY, stepId=1, magnitude=[0,0,-9.81], no amplitude
    md_ctrl%loads(2)%id = 2_i4
    md_ctrl%loads(2)%name = 'GRAVITY_1'
    md_ctrl%loads(2)%stepId = 1_i4
    md_ctrl%loads(2)%loadType = 'GRAVITY'
    md_ctrl%loads(2)%target = 'ALL_ELEMS'
    md_ctrl%loads(2)%magnitude = [0.0_wp, 0.0_wp, -9.81_wp]
    md_ctrl%loads(2)%ampName = ''
    
    ! Initialize L4_PH controller
    ph_load_ctrl%current_stepId = 1_i4
    ph_load_ctrl%nTotalDOFs = 0_i4  ! Not used in this test
    
    ! Execute projection
    step_time = 0.5_wp
    CALL PH_L4_Populate_Load(md_ctrl, step_time, ph_load_ctrl=ph_load_ctrl)
    
    ! Verify results
    IF (ph_load_ctrl%nActiveLoads == 2_i4) THEN
      PRINT *, '  PASS: nActiveLoads = 2'
    ELSE
      PRINT *, '  FAIL: Expected 2, got ', ph_load_ctrl%nActiveLoads
    END IF
    
    ! Verify load cache values
    IF (ALLOCATED(ph_load_ctrl%load_cache)) THEN
      PRINT *, '  PASS: load_cache allocated'
      
      ! Check load magnitudes (should match Desc since amp_factor=1.0)
      DO i = 1, SIZE(ph_load_ctrl%load_cache)
        IF (ALL(ABS(ph_load_ctrl%load_cache(i)%magnitude - &
            md_ctrl%loads(i)%magnitude) < TOL)) THEN
          PRINT *, '  PASS: Load ', i, ' magnitude correct'
        ELSE
          PRINT *, '  FAIL: Load ', i, ' magnitude mismatch'
        END IF
      END DO
      
    ELSE
      PRINT *, '  FAIL: load_cache not allocated'
    END IF
    
    ! Cleanup
    DEALLOCATE(md_ctrl%loads)
    IF (ALLOCATED(ph_load_ctrl%load_cache)) &
      DEALLOCATE(ph_load_ctrl%load_cache)
    
  END SUBROUTINE Test_LoadCache_Population

  !=============================================================================
  !> @brief Test BC cache population
  !=============================================================================
  SUBROUTINE Test_BCCache_Population()
    TYPE(MD_LoadBC_Ctrl_Type) :: md_ctrl
    TYPE(PH_BCCtrl_Type) :: ph_bc_ctrl
    REAL(wp) :: step_time
    INTEGER(i4) :: i
    
    PRINT *, 'Test: BC Cache Population'
    
    ! Setup: Create mock L3_MD controller with 2 BCs
    md_ctrl%nBCs = 2_i4
    ALLOCATE(md_ctrl%bcs(2))
    
    ! BC 1: Fixed support, stepId=1, dof=123 (all DOFs), magnitude=0
    md_ctrl%bcs(1)%id = 1_i4
    md_ctrl%bcs(1)%name = 'FIXED_SUPPORT'
    md_ctrl%bcs(1)%stepId = 1_i4
    md_ctrl%bcs(1)%nodeSet = 'NODE_BOTTOM'
    md_ctrl%bcs(1)%dof = 1_i4  ! UX
    md_ctrl%bcs(1)%magnitude = 0.0_wp
    md_ctrl%bcs(1)%ampName = ''
    md_ctrl%bcs(1)%isFixed = .TRUE.
    
    ! BC 2: Prescribed displacement, stepId=1, dof=1, magnitude=-5.0
    md_ctrl%bcs(2)%id = 2_i4
    md_ctrl%bcs(2)%name = 'DISP_Y'
    md_ctrl%bcs(2)%stepId = 1_i4
    md_ctrl%bcs(2)%nodeSet = 'NODE_TOP'
    md_ctrl%bcs(2)%dof = 2_i4  ! UY
    md_ctrl%bcs(2)%magnitude = -5.0_wp
    md_ctrl%bcs(2)%ampName = ''
    md_ctrl%bcs(2)%isFixed = .FALSE.
    
    ! Initialize L4_PH controller
    ph_bc_ctrl%current_stepId = 1_i4
    ph_bc_ctrl%nConstrainedDOFs = 0_i4
    
    ! Execute projection
    step_time = 0.5_wp
    CALL PH_L4_Populate_BC(md_ctrl, step_time, ph_bc_ctrl=ph_bc_ctrl)
    
    ! Verify results
    IF (ph_bc_ctrl%nConstrainedDOFs == 2_i4) THEN
      PRINT *, '  PASS: nConstrainedDOFs = 2'
    ELSE
      PRINT *, '  FAIL: Expected 2, got ', ph_bc_ctrl%nConstrainedDOFs
    END IF
    
    ! Verify BC cache values
    IF (ALLOCATED(ph_bc_ctrl%bc_cache)) THEN
      PRINT *, '  PASS: bc_cache allocated'
      
      ! Check prescribed values
      IF (ABS(ph_bc_ctrl%bc_cache(1)%value - 0.0_wp) < TOL) THEN
        PRINT *, '  PASS: BC 1 value = 0.0 (fixed)'
      ELSE
        PRINT *, '  FAIL: BC 1 value incorrect'
      END IF
      
      IF (ABS(ph_bc_ctrl%bc_cache(2)%value - (-5.0_wp)) < TOL) THEN
        PRINT *, '  PASS: BC 2 value = -5.0 (prescribed)'
      ELSE
        PRINT *, '  FAIL: BC 2 value incorrect'
      END IF
      
    ELSE
      PRINT *, '  FAIL: bc_cache not allocated'
    END IF
    
    ! Cleanup
    DEALLOCATE(md_ctrl%bcs)
    IF (ALLOCATED(ph_bc_ctrl%bc_cache)) &
      DEALLOCATE(ph_bc_ctrl%bc_cache)
    
  END SUBROUTINE Test_BCCache_Population

  !=============================================================================
  !> @brief Run all tests
  !=============================================================================
  SUBROUTINE RunAllTests()
    PRINT *, '=========================================='
    PRINT *, 'Running PH_Nested_To_Flat_LoadBC Tests'
    PRINT *, '=========================================='
    
    CALL Test_AmpInterpolation_Tabular()
    CALL Test_AmpInterpolation_BoundaryCases()  ! NEW: Boundary case tests
    CALL Test_LoadCache_Population()
    CALL Test_BCCache_Population()
    
    PRINT *, '=========================================='
    PRINT *, 'All tests completed'
    PRINT *, '=========================================='
    
  END SUBROUTINE RunAllTests

END MODULE TEST_PH_Nested_To_Flat_LoadBC
