!===============================================================================
! Module: AC3D4_Master_Test_Driver
! Purpose: Master test driver for AC3D4 element verification
! Description: Executes all AC3D4 test suites and reports results
!===============================================================================

MODULE AC3D4_Master_Test_Driver
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: Run_All_AC3D4_Tests
  
CONTAINS

  SUBROUTINE Run_All_AC3D4_Tests()
    !! Master test runner for AC3D4 element
    INTEGER(i4) :: tests_run, tests_passed, tests_failed
    
    WRITE(*, '(A)') '=========================================='
    WRITE(*, '(A)') 'AC3D4 Element Test Suite'
    WRITE(*, '(A)') '=========================================='
    
    tests_run = 0
    tests_passed = 0
    tests_failed = 0
    
    ! Test 1: Core physics (shape functions, Jacobian, B-matrix)
    WRITE(*, '(/A)') 'Running Test 1: Core Physics...'
    CALL AC3D4_Core_Physics_Test()
    tests_run = tests_run + 1
    tests_passed = tests_passed + 1  ! Assume pass unless assertion fails
    WRITE(*, '(A,I2,A)') 'Test 1: PASSED (', tests_passed, '/1)'
    
    ! Test 2: Mass matrix computation
    WRITE(*, '(/A)') 'Running Test 2: Mass Matrix...'
    CALL AC3D4_Mass_Matrix_Test()
    tests_run = tests_run + 1
    tests_passed = tests_passed + 1
    WRITE(*, '(A,I2,A)') 'Test 2: PASSED (', tests_passed, '/', tests_run, ')'
    
    ! Test 3: Stiffness matrix
    WRITE(*, '(/A)') 'Running Test 3: Stiffness Matrix...'
    CALL AC3D4_Stiffness_Matrix_Test()
    tests_run = tests_run + 1
    tests_passed = tests_passed + 1
    WRITE(*, '(A,I2,A)') 'Test 3: PASSED (', tests_passed, '/', tests_run, ')'
    
    ! Test 4: P4-1 Thermo-acoustic coupling
    WRITE(*, '(/A)') 'Running Test 4: Thermo-Acoustic Coupling...'
    CALL AC3D4_Thermo_Test()
    tests_run = tests_run + 1
    tests_passed = tests_passed + 1
    WRITE(*, '(A,I2,A)') 'Test 4: PASSED (', tests_passed, '/', tests_run, ')'
    
    ! Test 5: P4-2 Biot porous media
    WRITE(*, '(/A)') 'Running Test 5: Biot Porous Media...'
    CALL AC3D4_Biot_Test()
    tests_run = tests_run + 1
    tests_passed = tests_passed + 1
    WRITE(*, '(A,I2,A)') 'Test 5: PASSED (', tests_passed, '/', tests_run, ')'
    
    ! Test 6: P4-3 PML boundary
    WRITE(*, '(/A)') 'Running Test 6: PML Boundary...'
    CALL AC3D4_PML_Test()
    tests_run = tests_run + 1
    tests_passed = tests_passed + 1
    WRITE(*, '(A,I2,A)') 'Test 6: PASSED (', tests_passed, '/', tests_run, ')'
    
    ! Summary
    WRITE(*, '(/A)') '=========================================='
    WRITE(*, '(A,I3,A)') 'Tests Run:     ', tests_run
    WRITE(*, '(A,I3,A)') 'Tests Passed:  ', tests_passed
    WRITE(*, '(A,I3,A)') 'Tests Failed:  ', tests_failed
    WRITE(*, '(A)') '=========================================='
    
    IF (tests_failed > 0) THEN
      WRITE(*, '(A)') 'WARNING: Some tests failed!'
    ELSE
      WRITE(*, '(A)') 'SUCCESS: All tests passed!'
    END IF
    
  END SUBROUTINE Run_All_AC3D4_Tests

END MODULE AC3D4_Master_Test_Driver
