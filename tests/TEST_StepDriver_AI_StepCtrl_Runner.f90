PROGRAM TEST_StepDriver_AI_StepCtrl_Runner
  USE TEST_StepDriver_AI_StepCtrl, ONLY: Run_StepDriver_AI_StepCtrl_Test
  IMPLICIT NONE

  LOGICAL :: all_passed

  CALL Run_StepDriver_AI_StepCtrl_Test(all_passed)
  IF (.NOT. all_passed) STOP 1
END PROGRAM TEST_StepDriver_AI_StepCtrl_Runner
