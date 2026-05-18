!===============================================================================
! MODULE: AP_Job_Def
! LAYER:  L6_AP
! DOMAIN: Job
! ROLE:   Def — type definitions
! BRIEF:  Type definitions for job lifecycle management.
!===============================================================================
! Types: AP_Job_Desc, AP_Job_State
! Constants: AP_JOB_IDLE, AP_JOB_RUNNING, AP_JOB_DONE, AP_JOB_FAILED
!===============================================================================
MODULE AP_Job_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Job_Desc
  PUBLIC :: AP_Job_State

  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_IDLE    = 0
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_RUNNING = 1
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_DONE    = 2
  INTEGER(i4), PARAMETER, PUBLIC :: AP_JOB_FAILED  = 3

  TYPE :: AP_Job_Desc
    CHARACTER(LEN=128) :: job_name   = ""
    CHARACTER(LEN=256) :: input_file = ""
    INTEGER(i4)        :: job_type   = 0
  END TYPE AP_Job_Desc

  TYPE :: AP_Job_State
    INTEGER(i4) :: job_status   = AP_JOB_IDLE
    REAL(wp)    :: elapsed_time = 0.0_wp
    INTEGER(i4) :: current_step = 0
  END TYPE AP_Job_State

END MODULE AP_Job_Def
