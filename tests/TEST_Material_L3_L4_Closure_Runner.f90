PROGRAM TEST_Material_L3_L4_Closure_Runner
  USE TEST_Material_L3_L4_Closure, ONLY: Run_Material_L3_L4_Closure_Test
  IMPLICIT NONE

  LOGICAL :: all_passed

  CALL Run_Material_L3_L4_Closure_Test(all_passed)
  IF (.NOT. all_passed) STOP 1
END PROGRAM TEST_Material_L3_L4_Closure_Runner
