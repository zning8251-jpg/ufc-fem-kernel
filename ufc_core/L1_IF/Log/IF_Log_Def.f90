!===============================================================================
! MODULE: IF_Log_Def
! LAYER:  L1_IF
! DOMAIN: Log
! ROLE:   _Def
! BRIEF:  Desc TYPE and level constants for the Log domain.
!===============================================================================
MODULE IF_Log_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Log level constants: IF_LOG_*
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_DEBUG = 0
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_INFO  = 1
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_WARN  = 2
  INTEGER(i4), PARAMETER, PUBLIC :: IF_LOG_ERROR = 3

  !-----------------------------------------------------------------------------
  ! TYPE: IF_Log_Desc  [Desc]
  ! Immutable log configuration descriptor.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Log_Desc
    INTEGER(i4)       :: log_level = IF_LOG_INFO
    INTEGER(i4)       :: log_unit  = 6    ! stdout
    CHARACTER(LEN=32) :: prefix    = "[UFC] "
  END TYPE IF_Log_Desc

END MODULE IF_Log_Def
