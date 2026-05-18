! Harness-only AP_Job_Def subset.
MODULE AP_Job_Def
  USE IF_Prec_Core, ONLY: i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: AP_Job_Desc

  TYPE :: AP_Job_Desc
    CHARACTER(LEN=128) :: job_name = ''
  END TYPE AP_Job_Desc

END MODULE AP_Job_Def
