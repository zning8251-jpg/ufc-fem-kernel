!===============================================================================
! MODULE: RT_Log_Def
! LAYER:  L5_RT
! DOMAIN: Logging
! ROLE:   Def — AUTHORITY three-type definitions (Desc/State/Ctx; no Algo)
! BRIEF:  RT_Log_Desc/State/Ctx + RT_LOG_LEVEL_* / RT_LOG_OUT_* constants.
!===============================================================================
MODULE RT_Log_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  ! Log level constants (aligned with IF_Err_Def / RT_Log_Sys)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_LEVEL_DEBUG   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_LEVEL_INFO    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_LEVEL_WARN    = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_LEVEL_ERROR   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_LEVEL_FATAL   = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_LEVEL_OFF     = 6_i4

  ! Log output routing constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_OUT_STDOUT  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_OUT_FILE    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_OUT_BUFFER  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LOG_OUT_BOTH    = 4_i4  ! stdout + file

  TYPE, PUBLIC :: RT_Log_Desc
    INTEGER(i4)        :: log_level   = RT_LOG_LEVEL_INFO
    INTEGER(i4)        :: log_unit    = 6_i4
    INTEGER(i4)        :: output_mode = RT_LOG_OUT_STDOUT
    CHARACTER(LEN=32)  :: prefix      = '[UFC] '
    CHARACTER(LEN=256) :: log_file    = ''
    LOGICAL            :: timestamp_enabled = .TRUE.
  END TYPE RT_Log_Desc

  TYPE, PUBLIC :: RT_Log_Ctx
    CHARACTER(LEN=256) :: line_buffer  = ''
    CHARACTER(LEN=64)  :: module_name  = ''
    INTEGER(i4)        :: step_id      = 0_i4
    INTEGER(i4)        :: inc_num      = 0_i4
    INTEGER(i4)        :: buf_pos      = 0_i4
  END TYPE RT_Log_Ctx

  TYPE, PUBLIC :: RT_Logging_State
    LOGICAL     :: active       = .FALSE.
    INTEGER(i4) :: n_messages   = 0_i4
    INTEGER(i4) :: n_warnings   = 0_i4
    INTEGER(i4) :: n_errors     = 0_i4
    INTEGER(i4) :: n_debug      = 0_i4
    INTEGER(i4) :: n_fatal      = 0_i4
  END TYPE RT_Logging_State

END MODULE RT_Log_Def
