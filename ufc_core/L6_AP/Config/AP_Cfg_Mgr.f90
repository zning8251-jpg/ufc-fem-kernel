!===============================================================================
! MODULE: AP_Cfg_Mgr
! LAYER:  L6_AP
! DOMAIN: Config
! ROLE:   Mgr �?configuration manager
! BRIEF:  Configuration management, AI switch, resource limits, governance.
!===============================================================================

MODULE AP_Cfg_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_CfgMgr_State, AP_Config_Ctrl, AP_Config_Domain
  PUBLIC :: AP_Config_LoadConfig_Arg, AP_Config_SetResourceLimit_Arg
  PUBLIC :: AP_Config_RegisterModelConfig_Arg, AP_Config_GetSummary_Arg

  TYPE, PUBLIC :: AP_CfgMgr_Cfg_Paths
    CHARACTER(LEN=256) :: configFile = ''
    CHARACTER(LEN=256) :: workDir    = ''
  END TYPE AP_CfgMgr_Cfg_Paths

  TYPE, PUBLIC :: AP_CfgMgr_Cfg_AI
    LOGICAL :: aiEnabled = .FALSE.
    CHARACTER(LEN=128) :: aiModelName = ''
    CHARACTER(LEN=256) :: aiModelPath = ''
    REAL(wp) :: aiConfidenceThreshold = 0.8_wp
  END TYPE AP_CfgMgr_Cfg_AI

  TYPE, PUBLIC :: AP_CfgMgr_Cfg_Resources
    LOGICAL :: resourceLimitsEnabled = .FALSE.
    REAL(wp) :: maxCpuTime  = 0.0_wp    ! 0 = unlimited
    REAL(wp) :: maxDiskIO   = 0.0_wp    ! 0 = unlimited
    INTEGER(i4) :: maxThreads = 0_i4   ! 0 = auto
  END TYPE AP_CfgMgr_Cfg_Resources

  TYPE, PUBLIC :: AP_CfgMgr_Cfg_Audit
    LOGICAL :: auditLogging = .TRUE.
    CHARACTER(LEN=256) :: auditLogPath = ''
  END TYPE AP_CfgMgr_Cfg_Audit

  TYPE, PUBLIC :: AP_CfgMgr_State
    TYPE(AP_CfgMgr_Cfg_Paths) :: paths
    TYPE(AP_CfgMgr_Cfg_AI) :: ai
    TYPE(AP_CfgMgr_Cfg_Resources) :: resources
    TYPE(AP_CfgMgr_Cfg_Audit) :: audit
  END TYPE AP_CfgMgr_State

  TYPE, PUBLIC :: AP_Config_Ctrl
    LOGICAL :: strictValidation = .TRUE.
    LOGICAL :: mergeOnLoad      = .FALSE.
    INTEGER(i4) :: maxVersionHistory = 100_i4
  END TYPE AP_Config_Ctrl

  ! --- Arg types (Phase B) ---
  TYPE, PUBLIC :: AP_Config_LoadConfig_Arg
    CHARACTER(LEN=256)    :: filename = ''  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Config_LoadConfig_Arg

  TYPE, PUBLIC :: AP_Config_SetResourceLimit_Arg
    REAL(wp)    :: maxCpuTime = 0.0_wp  ! (IN)
    REAL(wp)    :: maxDiskIO  = 0.0_wp  ! (IN)
    INTEGER(i4) :: maxThreads = 0_i4   ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Config_SetResourceLimit_Arg

  TYPE, PUBLIC :: AP_Config_RegisterModelConfig_Arg
    CHARACTER(LEN=128) :: modelName = ''  ! (IN)
    CHARACTER(LEN=256) :: modelPath = ''  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Config_RegisterModelConfig_Arg

  TYPE, PUBLIC :: AP_Config_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ''  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Config_GetSummary_Arg

  TYPE, PUBLIC :: AP_Config_Domain
    TYPE(AP_CfgMgr_State) :: state
    TYPE(AP_Config_Ctrl)  :: ctrl
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: LoadConfig
    PROCEDURE :: SetResourceLimit
    PROCEDURE :: RegisterModelConfig
    PROCEDURE :: GetSummary
  END TYPE AP_Config_Domain

CONTAINS

  SUBROUTINE AP_Config_Domain_Finalize(this)
    CLASS(AP_Config_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%state = AP_CfgMgr_State()
    this%initialized = .FALSE.
  END SUBROUTINE AP_Config_Domain_Finalize

  SUBROUTINE AP_Config_Domain_Init(this, status)
    CLASS(AP_Config_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctrl = AP_Config_Ctrl()
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Config_Domain_Init

  !====================================================================
  ! AP_Config_Domain_LoadConfig  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Config_Domain_LoadConfig(this, arg)
    CLASS(AP_Config_Domain),       INTENT(INOUT) :: this
    TYPE(AP_Config_LoadConfig_Arg),INTENT(INOUT) :: arg
    CALL AP_Config_LoadConfig_Impl(this, arg%filename, arg%status)
  END SUBROUTINE AP_Config_Domain_LoadConfig

  SUBROUTINE AP_Config_LoadConfig_Impl(this, filename, status)
    CLASS(AP_Config_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),        INTENT(IN)    :: filename
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Config domain not initialized'
      RETURN
    END IF

    IF (LEN_TRIM(filename) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Config filename is empty'
      RETURN
    END IF

    this%state%configFile = TRIM(filename)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Config_LoadConfig_Impl

  !====================================================================
  ! AP_Config_Domain_SetResourceLimit  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Config_Domain_SetResourceLimit(this, arg)
    CLASS(AP_Config_Domain),             INTENT(INOUT) :: this
    TYPE(AP_Config_SetResourceLimit_Arg),INTENT(INOUT) :: arg
    CALL AP_Config_SetResourceLimit_Impl(this, arg%maxCpuTime, arg%maxDiskIO, &
                                          arg%maxThreads, arg%status)
  END SUBROUTINE AP_Config_Domain_SetResourceLimit

  SUBROUTINE AP_Config_SetResourceLimit_Impl(this, maxCpuTime, maxDiskIO, maxThreads, status)
    CLASS(AP_Config_Domain), INTENT(INOUT) :: this
    REAL(wp),                INTENT(IN)    :: maxCpuTime
    REAL(wp),                INTENT(IN)    :: maxDiskIO
    INTEGER(i4),             INTENT(IN)    :: maxThreads
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Config domain not initialized'
      RETURN
    END IF

    this%state%maxCpuTime = maxCpuTime
    this%state%maxDiskIO  = maxDiskIO
    this%state%maxThreads = maxThreads
    this%state%resourceLimitsEnabled = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Config_SetResourceLimit_Impl

  !====================================================================
  ! AP_Config_Domain_RegisterModelConfig  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Config_Domain_RegisterModelConfig(this, arg)
    CLASS(AP_Config_Domain),                INTENT(INOUT) :: this
    TYPE(AP_Config_RegisterModelConfig_Arg),INTENT(INOUT) :: arg
    CALL AP_Config_RegisterModelConfig_Impl(this, arg%modelName, arg%modelPath, arg%status)
  END SUBROUTINE AP_Config_Domain_RegisterModelConfig

  SUBROUTINE AP_Config_RegisterModelConfig_Impl(this, modelName, modelPath, status)
    CLASS(AP_Config_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),        INTENT(IN)    :: modelName
    CHARACTER(LEN=*),        INTENT(IN)    :: modelPath
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Config domain not initialized'
      RETURN
    END IF

    this%state%aiModelName = TRIM(modelName)
    this%state%aiModelPath = TRIM(modelPath)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Config_RegisterModelConfig_Impl

  !====================================================================
  ! AP_Config_Domain_GetSummary  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Config_Domain_GetSummary(this, arg)
    CLASS(AP_Config_Domain),        INTENT(IN)    :: this
    TYPE(AP_Config_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL AP_Config_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE AP_Config_Domain_GetSummary

  SUBROUTINE AP_Config_GetSummary_Impl(this, summary, status)
    CLASS(AP_Config_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Config domain not initialized'
      RETURN
    END IF

    WRITE(summary, '(A,A,A,L1,A,A,A,L1,A,ES10.3,A,I0)') &
      'Config Summary: File=', TRIM(this%state%configFile), &
      ', AI_Enabled=', this%state%aiEnabled, &
      ', AI_Model=', TRIM(this%state%aiModelName), &
      ', Limits=', this%state%resourceLimitsEnabled, &
      ', MaxCPU=', this%state%maxCpuTime, &
      ', MaxThreads=', this%state%maxThreads

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Config_GetSummary_Impl

END MODULE AP_Cfg_Mgr