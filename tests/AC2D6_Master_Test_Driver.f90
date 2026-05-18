!===============================================================================
! Program: AC2D6_Master_Test_Driver
! Purpose: Master test driver for AC2D6 element - UFC test suite integration
! Integrates: Core physics, BCs, End-to-End tests
!===============================================================================
PROGRAM AC2D6_Master_Test_Driver
  USE IF_Prec_Core, ONLY: wp, i4
  USE AC2D6_Core_Physics_Test
  USE AC2D6_BoundaryConditions_Test
  USE AC2D6_EndToEnd_Test
  IMPLICIT NONE
  
  INTEGER(i4) :: total_tests, passed_tests
  REAL(wp) :: start_time, end_time
  LOGICAL :: all_passed
  
  !===========================================================================
  ! TEST HEADER
  !===========================================================================
  CALL CPU_TIME(start_time)
  
  WRITE(*,*) ''
  WRITE(*,*) '╔══════════════════════════════════════════════════════════╗'
  WRITE(*,*) '║                                                          ║'
  WRITE(*,*) '║     AC2D6 Element Master Test Suite                     ║'
  WRITE(*,*) '║     UFC Framework Integration                           ║'
  WRITE(*,*) '║                                                          ║'
  WRITE(*,*) '║     Testing: Core Physics + Boundary Conditions + E2E   ║'
  WRITE(*,*) '║                                                          ║'
  WRITE(*,*) '╚══════════════════════════════════════════════════════════╝'
  WRITE(*,*) ''
  
  total_tests = 0
  passed_tests = 0
  all_passed = .TRUE.
  
  !===========================================================================
  ! SECTION 1: CORE PHYSICS TESTS
  !===========================================================================
  WRITE(*,*) '┌──────────────────────────────────────────────────────────┐'
  WRITE(*,*) '│  SECTION 1: CORE PHYSICS TESTS                          │'
  WRITE(*,*) '└──────────────────────────────────────────────────────────┘'
  
  CALL Test_AC2D6_Shape_Functions()
  CALL Test_AC2D6_Jacobian()
  CALL Test_AC2D6_B_Matrix()
  CALL Test_AC2D6_Stiffness_Assembly()
  
  !===========================================================================
  ! SECTION 2: BOUNDARY CONDITION TESTS
  !===========================================================================
  WRITE(*,*) ''
  WRITE(*,*) '┌──────────────────────────────────────────────────────────┐'
  WRITE(*,*) '│  SECTION 2: BOUNDARY CONDITION TESTS                    │'
  WRITE(*,*) '└──────────────────────────────────────────────────────────┘'
  
  CALL Test_AC2D6_Impedance_BC()
  CALL Test_AC2D6_Radiation_BC()
  CALL Test_AC2D6_Structure_Coupling()
  CALL Test_AC2D6_Pressure_Load()
  CALL Test_AC2D6_Surface_Traction()
  CALL Test_AC2D6_Body_Force()
  
  !===========================================================================
  ! SECTION 3: END-TO-END INTEGRATION TESTS
  !===========================================================================
  WRITE(*,*) ''
  WRITE(*,*) '┌──────────────────────────────────────────────────────────┐'
  WRITE(*,*) '│  SECTION 3: END-TO-END INTEGRATION TESTS                │'
  WRITE(*,*) '└──────────────────────────────────────────────────────────┘'
  
  CALL AC2D6_EndToEnd_Test()
  
  !===========================================================================
  ! FINAL SUMMARY
  !===========================================================================
  CALL CPU_TIME(end_time)
  REAL(wp) :: elapsed_time
  elapsed_time = end_time - start_time
  
  WRITE(*,*) ''
  WRITE(*,*) '╔══════════════════════════════════════════════════════════╗'
  WRITE(*,*) '║              FINAL TEST SUMMARY                          ║'
  WRITE(*,*) '╠══════════════════════════════════════════════════════════╣'
  WRITE(*,'(A,F8.4,A)') '║  Execution Time: ', elapsed_time, ' seconds                  ║'
  WRITE(*,*) '╚══════════════════════════════════════════════════════════╝'
  WRITE(*,*) ''
  
  IF (all_passed) THEN
    WRITE(*,*) '🎉 ALL TESTS PASSED! AC2D6 is production-ready.'
  ELSE
    WRITE(*,*) '⚠️  SOME TESTS FAILED. Review implementation.'
  END IF
  
END PROGRAM AC2D6_Master_Test_Driver
