! Harness-only AP_Job_Mgr subset for L6 bridge smoke.
MODULE AP_Job_Mgr
  USE IF_Prec_Core, ONLY: i4
  USE AP_Job_Def, ONLY: AP_Job_Desc
  USE MD_TypeSystem, ONLY: State_Model
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: JobOpts, JobCtx, AP_JOB_RT_FULL_JOB_DONE

  INTEGER(i4), PARAMETER :: AP_JOB_RT_FULL_JOB_DONE = -2_i4

  TYPE :: JobOpts
    INTEGER(i4) :: placeholder = 0_i4
  END TYPE JobOpts

  TYPE :: JobCtx
    TYPE(AP_Job_Desc), POINTER :: desc => NULL()
    TYPE(State_Model), POINTER :: stateModel => NULL()
    TYPE(JobOpts) :: opts
  END TYPE JobCtx

END MODULE AP_Job_Mgr
