!===============================================================================
! MODULE: MD_ModelRT_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — Model/StepMgr L3→L5 bridge
! BRIEF:  Re-export ThreadWS/StepDesc/StepMgr types and wrap StepMgr ops.
!===============================================================================


MODULE MD_ModelRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Step_WS, ONLY: ThreadWS
  USE MD_Step_Proc, ONLY: StepDesc
  USE RT_Step_Type, ONLY: RT_StepConvInfo, RT_StepState_Type
  USE RT_Step_Mgr, ONLY: RT_Ste, RT_AnalysisStep, RT_StepRuntimeCfg, &
                         StepMgr_Init, StepMgr_AddStep, StepMgr_GetStepCfg, &
                         StepMgr_InitModelVars
  IMPLICIT NONE
  PRIVATE
  
  ! --- Re-exported RT types ---
  PUBLIC :: ThreadWS
  PUBLIC :: StepDesc, RT_StepState_Type, RT_StepConvInfo
  PUBLIC :: RT_Ste, RT_AnalysisStep, RT_StepRuntimeCfg

  ! --- Bridge procedures ---
  
  PUBLIC :: MD_RT_Model_Sys_StepMgr_AddStep
  PUBLIC :: MD_RT_Model_Sys_StepMgr_GetStepCfg
  PUBLIC :: MD_RT_Model_Sys_StepMgr_Init
  PUBLIC :: MD_RT_Model_Sys_StepMgr_InitModelVars

CONTAINS

  !---------------------------------------------------------------------------
  ! StepMgr bridge subroutines
  !---------------------------------------------------------------------------

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Model_Sys_StepMgr_AddStep
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Add analysis step to RT StepMgr.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Model_Sys_StepMgr_AddStep(step_mgr, step, status)
    TYPE(RT_Ste), INTENT(INOUT) :: step_mgr
    TYPE(RT_AnalysisStep), INTENT(IN) :: step
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    ! step_mgr reserved for future registry binding; StepMgr_* uses RT_Step_Mgr module state
    CALL StepMgr_AddStep(step, status=status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_RT_Model_Sys_StepMgr_AddStep

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Model_Sys_StepMgr_GetStepCfg
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Get step runtime config from RT StepMgr.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Model_Sys_StepMgr_GetStepCfg(step_mgr, step_id, cfg, status)
    TYPE(RT_Ste), INTENT(IN) :: step_mgr
    INTEGER(i4), INTENT(IN) :: step_id
    TYPE(RT_StepRuntimeCfg), INTENT(OUT) :: cfg
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL StepMgr_GetStepCfg(step_id, cfg, status=status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_RT_Model_Sys_StepMgr_GetStepCfg

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Model_Sys_StepMgr_Init
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Initialize RT StepMgr.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Model_Sys_StepMgr_Init(step_mgr, status)
    TYPE(RT_Ste), INTENT(INOUT) :: step_mgr
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL StepMgr_Init(status=status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_RT_Model_Sys_StepMgr_Init

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_Model_Sys_StepMgr_InitModelVars
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Initialize RT model variables from StepMgr.
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_Model_Sys_StepMgr_InitModelVars(step_mgr, model, status)
    TYPE(RT_Ste), INTENT(INOUT) :: step_mgr
    CLASS(*), INTENT(INOUT) :: model
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL StepMgr_InitModelVars(model, status=status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_RT_Model_Sys_StepMgr_InitModelVars

END MODULE MD_ModelRT_Brg
