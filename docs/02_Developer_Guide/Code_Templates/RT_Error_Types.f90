!==============================================================================!
! MODULE RT_Error_Types
! Layer  : L5_RT  (When / run-time orchestration)
! Domain : Error  –  structured error/warning collection and abort control
!
! Four TYPE kinds:
!   RT_Error_Record  – single error event (code + message + location)
!   RT_Error_Stack   – LIFO stack of error records (max N recent errors)
!   RT_Warning_List  – accumulating warning list (non-fatal)
!   RT_Abort_Ctx     – abort decision context (threshold + policy)
!==============================================================================!
MODULE RT_Error_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_ERROR_SEVERITY_ERROR
  IMPLICIT NONE
  PRIVATE

  ! Error severity constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ERR_ERR_SEV_INFO    = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ERR_ERR_SEV_WARNING = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ERR_ERR_SEV_ERROR   = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ERR_ERR_SEV_FATAL   = 3_i4  ! migrated

  ! Abort policy constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ABORT_ABORT_ON_FIRST_FATAL  = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ABORT_ABORT_ON_MAX_ERRORS   = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_ABORT_ABORT_NEVER           = 3_i4  ! collect only  ! migrated

  ! ------------------------------------------------------------------ !
  ! RT_Error_Record
  !   A single error/warning event captured during analysis.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Error_Record
    INTEGER(i4)       :: code       = 0_i4      ! application error code
    INTEGER(i4)       :: severity   = IF_ERROR_SEVERITY_ERROR
    CHARACTER(LEN=256):: message    = ' '        ! human-readable description
    CHARACTER(LEN=80) :: source_mod = ' '        ! module where error occurred
    CHARACTER(LEN=80) :: source_sub = ' '        ! subroutine name
    INTEGER(i4)       :: step_id    = 0_i4
    INTEGER(i4)       :: inc_id     = 0_i4
    INTEGER(i4)       :: elem_id    = 0_i4       ! element label (-1 = n/a)
    INTEGER(i4)       :: mat_id     = 0_i4       ! material id  (-1 = n/a)
  END TYPE RT_Error_Record

  ! ------------------------------------------------------------------ !
  ! RT_Error_Stack
  !   Circular LIFO buffer of recent error records.
  !   When full, oldest records are overwritten.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Error_Stack
    INTEGER(i4)                   :: capacity   = 64_i4
    INTEGER(i4)                   :: n_stored   = 0_i4   ! total ever added
    INTEGER(i4)                   :: head       = 0_i4   ! next write position
    TYPE(RT_Error_Record), POINTER :: records(:)      ! [capacity] circular buffer
    INTEGER(i4)                   :: n_fatal    = 0_i4   ! fatal count
    INTEGER(i4)                   :: n_errors   = 0_i4   ! error count
    INTEGER(i4)                   :: n_warnings = 0_i4
    LOGICAL                       :: overflow   = .FALSE. ! buffer wrapped
    TYPE(ErrorStatusType)         :: status
  END TYPE RT_Error_Stack

  ! ------------------------------------------------------------------ !
  ! RT_Warning_List
  !   Accumulating list of non-fatal warning messages.
  !   Printed as a summary at step/analysis end.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Warning_List
    INTEGER(i4)                   :: n_warnings = 0_i4
    INTEGER(i4)                   :: n_max      = 256_i4  ! max before suppression
    TYPE(RT_Error_Record), POINTER :: warnings(:)      ! [n_max]
    LOGICAL                       :: suppressing= .FALSE.  ! over limit, suppressing
    INTEGER(i4)                   :: n_suppressed= 0_i4
    TYPE(ErrorStatusType)         :: status
  END TYPE RT_Warning_List

  ! ------------------------------------------------------------------ !
  ! RT_Abort_Ctx
  !   Abort decision context: checks against policy and triggers
  !   analysis termination if conditions are met.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: RT_Abort_Ctx
    INTEGER(i4) :: policy           = ABORT_ON_FIRST_FATAL
    INTEGER(i4) :: max_errors       = 10_i4   ! for ABORT_ON_MAX_ERRORS
    INTEGER(i4) :: current_errors   = 0_i4
    LOGICAL     :: abort_triggered  = .FALSE.
    CHARACTER(LEN=256) :: abort_msg = ' '     ! final abort reason
    INTEGER(i4) :: abort_step       = 0_i4
    INTEGER(i4) :: abort_inc        = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Abort_Ctx

END MODULE RT_Error_Types
