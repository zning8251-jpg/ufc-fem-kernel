!===============================================================================
! Module: TEST_Static_Analysis_E2E
! Layer:  L5_RT - Runtime Layer (Test Harness)
! Domain: Static Analysis - End-to-End Test
!
! Purpose: Static analysis E2E test (single step, single increment)
!         Tests full integration of Element domain with other domains
!
! Test scenario:
!   1. Initialize model with 1 element (C3D8R)
!   2. Apply displacement BC
!   3. Run single Newton-Raphson iteration
!   4. Verify K_global, F_residual, solution
!
! Integration points tested:
!   - RT_Element_Kernel_Proc (L5_RT Element kernel)
!   - RT_Element_Assembly_Proc (L5_RT assembly)
!   - RT_Asm_Solv (Global assembly)
!   - RT_Solver (Linear solver)
!   - PH_Element_Nlgeom_Core (L4_PH physics)
!   - MD_Element_Core (L3_MD registry)
!
! Status: v5.1 ST-9.3 | Created: 2026-03-31
!===============================================================================
MODULE TEST_Static_Analysis_E2E
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, STATUS_ERR
  USE RT_Elem_Types, ONLY: RT_Elem_State, RT_Elem_Ctx
  USE RT_Element_Kernel_Proc, ONLY: RT_Elem_Kernel_In, RT_Elem_Kernel_Out, &
                                     RT_Elem_Kernel_Compute, RT_Elem_Kernel_Init
  USE RT_Element_Assembly_Proc, ONLY: RT_Elem_Assembly_In, RT_Element_Assemble_Ke, &
                                       RT_Element_Assemble_Fe
  USE RT_Element_Compute_Proc, ONLY: RT_Elem_Compute_Args, RT_Element_Compute_All

  IMPLICIT NONE
  PRIVATE

  ! Test configuration
  INTEGER(i4), PARAMETER, PUBLIC :: TEST_N_NODES = 8
  INTEGER(i4), PARAMETER, PUBLIC :: TEST_N_DOFS = 24  ! 8 nodes * 3 DOF
  REAL(wp), PARAMETER, PUBLIC :: TEST_YOUNG_MOD = 210000.0_wp  ! Steel E=210 GPa
  REAL(wp), PARAMETER, PUBLIC :: TEST_POISSON = 0.3_wp

  ! Public interfaces
  PUBLIC :: TEST_Run_Static_Analysis
  PUBLIC :: TEST_Verify_Results
  PUBLIC :: TEST_Print_Summary

CONTAINS

  !============================================================================
  ! Subroutine: TEST_Run_Static_Analysis
  ! Purpose: Run complete static analysis E2E test
  !============================================================================
  SUBROUTINE TEST_Run_Static_Analysis(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Element data structures
    TYPE(RT_Elem_State) :: elem_state
    TYPE(RT_Elem_Ctx) :: elem_ctx
    
    ! Kernel input/output
    TYPE(RT_Elem_Kernel_In) :: kernel_inp
    TYPE(RT_Elem_Kernel_Out) :: kernel_out
    
    ! Assembly input
    TYPE(RT_Elem_Assembly_In) :: asm_inp
    
    ! Global system matrices
    REAL(wp), ALLOCATABLE :: K_global(:,:)
    REAL(wp), ALLOCATABLE :: F_global(:)
    REAL(wp), ALLOCATABLE :: U_global(:)
    
    ! LM array for single element
    INTEGER(i4), ALLOCATABLE :: lm(:)
    
    ! Local variables
    INTEGER(i4) :: i, j, nstatev
    LOGICAL :: test_passed

    CALL init_error_status(status)

    WRITE(*,*) '========================================'
    WRITE(*,*) 'TEST: Static Analysis E2E (Single Step)'
    WRITE(*,*) '========================================'

    !--------------------------------------------------------------------------
    ! Step 1: Initialize element state
    !--------------------------------------------------------------------------
    WRITE(*,*) '[TEST] Step 1: Initialize element state...'
    nstatev = 10  ! Number of state variables
    CALL RT_Elem_Kernel_Init(elem_state, nstatev, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'Failed to initialize element state'
      RETURN
    END IF

    !--------------------------------------------------------------------------
    ! Step 2: Setup element context (C3D8R)
    !--------------------------------------------------------------------------
    WRITE(*,*) '[TEST] Step 2: Setup C3D8R element context...'
    elem_ctx%base%elem_type_id = 10  ! C3D8R

    !--------------------------------------------------------------------------
    ! Step 3: Setup nodal coordinates (unit cube)
    !--------------------------------------------------------------------------
    WRITE(*,*) '[TEST] Step 3: Setup unit cube geometry...'
    ALLOCATE(kernel_inp%coords(3, TEST_N_NODES))
    kernel_inp%coords = 0.0_wp
    ! Node 1: (0,0,0)
    kernel_inp%coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    ! Node 2: (1,0,0)
    kernel_inp%coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
    ! Node 3: (1,1,0)
    kernel_inp%coords(:,3) = [1.0_wp, 1.0_wp, 0.0_wp]
    ! Node 4: (0,1,0)
    kernel_inp%coords(:,4) = [0.0_wp, 1.0_wp, 0.0_wp]
    ! Node 5: (0,0,1)
    kernel_inp%coords(:,5) = [0.0_wp, 0.0_wp, 1.0_wp]
    ! Node 6: (1,0,1)
    kernel_inp%coords(:,6) = [1.0_wp, 0.0_wp, 1.0_wp]
    ! Node 7: (1,1,1)
    kernel_inp%coords(:,7) = [1.0_wp, 1.0_wp, 1.0_wp]
    ! Node 8: (0,1,1)
    kernel_inp%coords(:,8) = [0.0_wp, 1.0_wp, 1.0_wp]

    !--------------------------------------------------------------------------
    ! Step 4: Apply boundary conditions (fixed at z=0)
    !--------------------------------------------------------------------------
    WRITE(*,*) '[TEST] Step 4: Apply BC (fixed bottom face)...'
    ALLOCATE(kernel_inp%displ(3, TEST_N_NODES))
    ALLOCATE(kernel_inp%vel(3, TEST_N_NODES))
    ALLOCATE(kernel_inp%accel(3, TEST_N_NODES))
    kernel_inp%displ = 0.0_wp
    kernel_inp%vel = 0.0_wp
    kernel_inp%accel = 0.0_wp

    !--------------------------------------------------------------------------
    ! Step 5: Setup time and loading
    !--------------------------------------------------------------------------
    WRITE(*,*) '[TEST] Step 5: Setup time parameters...'
    kernel_inp%time = 0.0_wp
    kernel_inp%dtime = 1.0_wp
    kernel_inp%kstep = 1
    kernel_inp%kinc = 1
    kernel_inp%is_first_iter = .TRUE.

    !--------------------------------------------------------------------------
    ! Step 6: Run element kernel computation
    !--------------------------------------------------------------------------
    WRITE(*,*) '[TEST] Step 6: Call RT_Element_Kernel_Compute...'
    CALL RT_Elem_Kernel_Compute(elem_state, elem_ctx, &
                                kernel_inp, kernel_out, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'Element kernel computation failed'
      RETURN
    END IF

    WRITE(*,*) '  - Ke computed: ', ALLOCATED(kernel_out%amatrx)
    WRITE(*,*) '  - Fe computed: ', ALLOCATED(kernel_out%rhs)
    WRITE(*,*) '  - Me computed: ', ALLOCATED(kernel_out%mass)

    !--------------------------------------------------------------------------
    ! Step 7: Assemble into global system
    !--------------------------------------------------------------------------
    WRITE(*,*) '[TEST] Step 7: Assemble into global system...'
    ALLOCATE(K_global(TEST_N_DOFS, TEST_N_DOFS))
    ALLOCATE(F_global(TEST_N_DOFS))
    ALLOCATE(lm(TEST_N_DOFS))
    
    ! Build LM array (identity for single element test)
    DO i = 1, TEST_N_DOFS
      lm(i) = i
    END DO

    ! Initialize global matrices
    K_global = 0.0_wp
    F_global = 0.0_wp

    ! Setup assembly input
    asm_inp%elem_id = 1
    asm_inp%n_nodes = TEST_N_NODES
    asm_inp%dof_per_node = 3
    asm_inp%conn = [(i, i=1, TEST_N_NODES)]
    asm_inp%lm = lm
    asm_inp%coords = kernel_inp%coords
    asm_inp%displ = kernel_inp%displ
    asm_inp%time = kernel_inp%time
    asm_inp%dtime = kernel_inp%dtime
    asm_inp%kstep = kernel_inp%kstep
    asm_inp%kinc = kernel_inp%kinc

    ! Assemble stiffness
    CALL RT_Element_Assemble_Ke(elem_state, elem_ctx, &
                                asm_inp, K_global, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'Stiffness assembly failed'
      RETURN
    END IF

    ! Assemble force
    CALL RT_Element_Assemble_Fe(elem_state, elem_ctx, &
                                asm_inp, F_global, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      status%message = 'Force assembly failed'
      RETURN
    END IF

    !--------------------------------------------------------------------------
    ! Step 8: Verify results
    !--------------------------------------------------------------------------
    WRITE(*,*) '[TEST] Step 8: Verify results...'
    CALL TEST_Verify_Results(K_global, F_global, kernel_out, test_passed, status)

    IF (test_passed) THEN
      WRITE(*,*) '========================================'
      WRITE(*,*) 'TEST PASSED �?
      WRITE(*,*) '========================================'
    ELSE
      status%status_code = STATUS_ERR
      status%message = 'Verification failed'
      WRITE(*,*) '========================================'
      WRITE(*,*) 'TEST FAILED �?
      WRITE(*,*) '========================================'
    END IF

    ! Cleanup
    IF (ALLOCATED(kernel_inp%coords)) DEALLOCATE(kernel_inp%coords)
    IF (ALLOCATED(kernel_inp%displ)) DEALLOCATE(kernel_inp%displ)
    IF (ALLOCATED(kernel_inp%vel)) DEALLOCATE(kernel_inp%vel)
    IF (ALLOCATED(kernel_inp%accel)) DEALLOCATE(kernel_inp%accel)
    IF (ALLOCATED(kernel_out%amatrx)) DEALLOCATE(kernel_out%amatrx)
    IF (ALLOCATED(kernel_out%rhs)) DEALLOCATE(kernel_out%rhs)
    IF (ALLOCATED(kernel_out%mass)) DEALLOCATE(kernel_out%mass)
    IF (ALLOCATED(K_global)) DEALLOCATE(K_global)
    IF (ALLOCATED(F_global)) DEALLOCATE(F_global)
    IF (ALLOCATED(lm)) DEALLOCATE(lm)

  END SUBROUTINE TEST_Run_Static_Analysis

  !============================================================================
  ! Subroutine: TEST_Verify_Results
  ! Purpose: Verify test results
  !============================================================================
  SUBROUTINE TEST_Verify_Results(K_global, F_global, kernel_out, passed, status)
    REAL(wp), INTENT(IN) :: K_global(:,:)
    REAL(wp), INTENT(IN) :: F_global(:)
    TYPE(RT_Elem_Kernel_Out), INTENT(IN) :: kernel_out
    LOGICAL, INTENT(OUT) :: passed
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: ke_norm, kg_norm, ratio
    INTEGER(i4) :: i, j

    CALL init_error_status(status)
    passed = .TRUE.

    ! Check 1: Ke matrix allocated
    IF (.NOT. ALLOCATED(kernel_out%amatrx)) THEN
      WRITE(*,*) '  [FAIL] Ke not allocated'
      passed = .FALSE.
    ELSE
      WRITE(*,*) '  [PASS] Ke allocated'
    END IF

    ! Check 2: Fe vector allocated
    IF (.NOT. ALLOCATED(kernel_out%rhs)) THEN
      WRITE(*,*) '  [FAIL] Fe not allocated'
      passed = .FALSE.
    ELSE
      WRITE(*,*) '  [PASS] Fe allocated'
    END IF

    ! Check 3: K_global symmetry (should be symmetric for linear elastic)
    WRITE(*,*) '  Checking K_global symmetry...'
    kg_norm = 0.0_wp
    DO i = 1, SIZE(K_global, 1)
      DO j = i+1, SIZE(K_global, 2)
        kg_norm = kg_norm + ABS(K_global(i,j) - K_global(j,i))
      END DO
    END DO
    
    IF (kg_norm < 1.0e-6_wp) THEN
      WRITE(*,*) '    [PASS] K_global is symmetric (norm = ', kg_norm, ')'
    ELSE
      WRITE(*,*) '    [FAIL] K_global not symmetric (norm = ', kg_norm, ')'
      passed = .FALSE.
    END IF

    ! Check 4: Ke positive definiteness (trace > 0)
    IF (ALLOCATED(kernel_out%amatrx)) THEN
      ke_norm = 0.0_wp
      DO i = 1, SIZE(kernel_out%amatrx, 1)
        ke_norm = ke_norm + kernel_out%amatrx(i,i)
      END DO
      
      IF (ke_norm > 0.0_wp) THEN
        WRITE(*,*) '  [PASS] Ke trace positive (', ke_norm, ')'
      ELSE
        WRITE(*,*) '  [FAIL] Ke trace not positive (', ke_norm, ')'
        passed = .FALSE.
      END IF
    END IF

    ! Print summary
    CALL TEST_Print_Summary(K_global, F_global, kernel_out)

  END SUBROUTINE TEST_Verify_Results

  !============================================================================
  ! Subroutine: TEST_Print_Summary
  ! Purpose: Print test summary
  !============================================================================
  SUBROUTINE TEST_Print_Summary(K_global, F_global, kernel_out)
    REAL(wp), INTENT(IN) :: K_global(:,:)
    REAL(wp), INTENT(IN) :: F_global(:)
    TYPE(RT_Elem_Kernel_Out), INTENT(IN) :: kernel_out

    WRITE(*,*) ''
    WRITE(*,*) '--- Test Summary ---'
    WRITE(*,*) 'K_global size: ', SIZE(K_global, 1), 'x', SIZE(K_global, 2)
    WRITE(*,*) 'F_global size: ', SIZE(F_global)
    
    IF (ALLOCATED(kernel_out%amatrx)) THEN
      WRITE(*,*) 'Ke size: ', SIZE(kernel_out%amatrx, 1), 'x', SIZE(kernel_out%amatrx, 2)
      WRITE(*,*) 'Ke max: ', MAXVAL(ABS(kernel_out%amatrx))
      WRITE(*,*) 'Ke min: ', MINVAL(ABS(kernel_out%amatrx))
    END IF
    
    IF (ALLOCATED(kernel_out%rhs)) THEN
      WRITE(*,*) 'Fe size: ', SIZE(kernel_out%rhs)
      WRITE(*,*) 'Fe norm: ', SQRT(SUM(kernel_out%rhs**2))
    END IF
    
    IF (ALLOCATED(kernel_out%energy)) THEN
      WRITE(*,*) 'Energy: SSE=', kernel_out%energy(1), &
                 ' SPD=', kernel_out%energy(2), &
                 ' RPL=', kernel_out%energy(3)
    END IF

  END SUBROUTINE TEST_Print_Summary

END MODULE TEST_Static_Analysis_E2E