PROGRAM TEST_Material_Pillar_Runner
  USE TEST_Material_L3_L4_Closure, ONLY: Run_Material_L3_L4_Closure_Test
  USE RT_Mat_Test, ONLY: RT_Material_Run_Tests
  IMPLICIT NONE

  LOGICAL :: closure_passed
  LOGICAL :: rt_passed

  CALL Run_Material_L3_L4_Closure_Test(closure_passed)
  CALL RT_Material_Run_Tests(rt_passed)

  IF (.NOT. (closure_passed .AND. rt_passed)) STOP 1
END PROGRAM TEST_Material_Pillar_Runner
