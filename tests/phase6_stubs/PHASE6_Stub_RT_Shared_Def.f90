! Harness-only RT_Shared_Def subset for Phase6 driver smoke.
MODULE RT_Shared_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: RT_Sol_Cfg, UF_RT_JobStatus, UF_JobStatus_Success

  INTEGER(i4), PARAMETER :: UF_JobStatus_Success = 0_i4

  TYPE :: RT_Sol_Cfg
    CHARACTER(LEN=80) :: name = ''
    LOGICAL :: isExplicit = .FALSE.
    LOGICAL :: useHHT = .FALSE.
    REAL(wp) :: alphaHHT = 0.0_wp
    INTEGER(i4) :: linSolvType = 0_i4
  END TYPE RT_Sol_Cfg

  TYPE :: UF_RT_JobStatus
    INTEGER(i4) :: code = 0_i4
    CHARACTER(LEN=256) :: message = ''
  END TYPE UF_RT_JobStatus

END MODULE RT_Shared_Def
