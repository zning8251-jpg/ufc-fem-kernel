PROGRAM TEST_Contact_L3_L4_Closure_Runner
  USE TEST_Contact_L3_L4_Closure, ONLY: Run_Contact_L3_L4_Closure_Test
  IMPLICIT NONE

  LOGICAL :: all_passed

  CALL Run_Contact_L3_L4_Closure_Test(all_passed)
  IF (.NOT. all_passed) STOP 1
END PROGRAM TEST_Contact_L3_L4_Closure_Runner
