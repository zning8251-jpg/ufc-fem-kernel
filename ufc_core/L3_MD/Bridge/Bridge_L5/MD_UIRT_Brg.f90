!===============================================================================
! MODULE: MD_UIRT_Brg
! LAYER:  L3_MD
! DOMAIN: Bridge_L5
! ROLE:   Brg — UI/Job L3→L5 bridge
! BRIEF:  Forward UI job execution to L5_RT RT_RunJob.
! PILOT:  Single entry `MD_RT_UI_RunJob` (no duplicate *_Ctx wrapper — pilot forbids no-op bridges).
!===============================================================================


MODULE MD_UIRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Ctx_API, ONLY: RT_RunJob, UF_RT_JobStatus, &
                        UF_JobStatus_Success, UF_JobStatus_NonConvergence, &
                        UF_JobStatus_InputError, UF_JobStatus_InternalError, &
                        UF_JobStatus_UserAbort
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UF_RT_JobStatus
  PUBLIC :: UF_JobStatus_Success, UF_JobStatus_NonConvergence, &
            UF_JobStatus_InputError, UF_JobStatus_InternalError, &
            UF_JobStatus_UserAbort
  PUBLIC :: MD_RT_UI_RunJob

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_RT_UI_RunJob
  ! PHASE:      P1 (温路径-数据映射)
  ! PURPOSE:    Execute RT job (bridge → RT_RunJob).
  !---------------------------------------------------------------------------
  SUBROUTINE MD_RT_UI_RunJob(rt_job, rt_status)
    CLASS(*), INTENT(INOUT) :: rt_job
    TYPE(UF_RT_JobStatus), INTENT(OUT) :: rt_status

    CALL RT_RunJob(rt_job, rt_status)

  END SUBROUTINE MD_RT_UI_RunJob

END MODULE MD_UIRT_Brg
