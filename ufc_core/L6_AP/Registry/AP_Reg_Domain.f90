!===============================================================================
! MODULE: AP_Reg_Domain
! LAYER:  L6_AP
! DOMAIN: Registry
! ROLE:   Domain â€?registry domain aggregate
! BRIEF:  Model registration, version management, degradation detection.
!===============================================================================

MODULE AP_Reg_Domain
  USE IF_Prec_Core,    ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: AP_REG_MAX_MODELS = 256_i4

  TYPE, PUBLIC :: AP_Registry_ModelEntry
    INTEGER(i8)     :: modelId   = 0_i8
    CHARACTER(LEN=128) :: modelName = ''
    CHARACTER(LEN=64)  :: modelType = ''
    CHARACTER(LEN=32)  :: version   = '1.0.0'
    LOGICAL            :: active    = .TRUE.
    REAL(wp)           :: lastScore = 0.0_wp
  END TYPE AP_Registry_ModelEntry

  TYPE, PUBLIC :: AP_Registry_State
    INTEGER(i4) :: nModels     = 0_i4
    INTEGER(i4) :: nAuditLogs  = 0_i4
    LOGICAL     :: auditEnabled = .TRUE.
  END TYPE AP_Registry_State

  TYPE, PUBLIC :: AP_Registry_Ctrl
    LOGICAL     :: degradationCheck = .TRUE.
    REAL(wp)    :: degradationThreshold = 0.1_wp
    INTEGER(i4) :: maxVersionHistory    = 100_i4
  END TYPE AP_Registry_Ctrl

  ! --- Arg types (Phase B) ---
  TYPE, PUBLIC :: AP_Registry_RegisterModel_Arg
    CHARACTER(LEN=128) :: modelName = ''  ! (IN)
    CHARACTER(LEN=64)  :: modelType = ''  ! (IN)
    INTEGER(i8)     :: modelId   = 0_i8  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Registry_RegisterModel_Arg

  TYPE, PUBLIC :: AP_Registry_CheckDegradation_Arg
    INTEGER(i8) :: modelId     = 0_i8  ! (IN)
    LOGICAL        :: isDegraded  = .FALSE.  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Registry_CheckDegradation_Arg

  TYPE, PUBLIC :: AP_Registry_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ''  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Registry_GetSummary_Arg

  TYPE, PUBLIC :: AP_Registry_Domain
    TYPE(AP_Registry_State) :: state
    TYPE(AP_Registry_Ctrl)  :: ctrl
    TYPE(AP_Registry_ModelEntry) :: models(AP_REG_MAX_MODELS)
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterModel
    PROCEDURE :: CheckDegradation
    PROCEDURE :: GetSummary
  END TYPE AP_Registry_Domain

CONTAINS

  SUBROUTINE AP_Registry_Domain_Finalize(this)
    CLASS(AP_Registry_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%state = AP_Registry_State()
    this%initialized = .FALSE.
  END SUBROUTINE AP_Registry_Domain_Finalize

  SUBROUTINE AP_Registry_Domain_Init(this, status)
    CLASS(AP_Registry_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctrl = AP_Registry_Ctrl()
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Registry_Domain_Init

  !====================================================================
  ! AP_Registry_Domain_RegisterModel  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Registry_Domain_RegisterModel(this, arg)
    CLASS(AP_Registry_Domain),           INTENT(INOUT) :: this
    TYPE(AP_Registry_RegisterModel_Arg), INTENT(INOUT) :: arg
    CALL AP_Registry_RegisterModel_Impl(this, arg%modelName, arg%modelType, &
                                         arg%modelId, arg%status)
  END SUBROUTINE AP_Registry_Domain_RegisterModel

  SUBROUTINE AP_Registry_RegisterModel_Impl(this, modelName, modelType, modelId, status)
    CLASS(AP_Registry_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),          INTENT(IN)    :: modelName
    CHARACTER(LEN=*),          INTENT(IN)    :: modelType
    INTEGER(i8),            INTENT(OUT)   :: modelId
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)
    modelId = 0_i8

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Registry domain not initialized'
      RETURN
    END IF

    IF (this%state%nModels >= AP_REG_MAX_MODELS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Registry capacity exceeded'
      RETURN
    END IF

    n = this%state%nModels + 1_i4
    this%models(n)%modelId   = INT(n, i8)
    this%models(n)%modelName = TRIM(modelName)
    this%models(n)%modelType = TRIM(modelType)
    this%models(n)%active    = .TRUE.
    this%state%nModels       = n
    modelId = INT(n, i8)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Registry_RegisterModel_Impl

  !====================================================================
  ! AP_Registry_Domain_CheckDegradation  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Registry_Domain_CheckDegradation(this, arg)
    CLASS(AP_Registry_Domain),               INTENT(IN)    :: this
    TYPE(AP_Registry_CheckDegradation_Arg),  INTENT(INOUT) :: arg
    CALL AP_Registry_CheckDegradation_Impl(this, arg%modelId, arg%isDegraded, arg%status)
  END SUBROUTINE AP_Registry_Domain_CheckDegradation

  SUBROUTINE AP_Registry_CheckDegradation_Impl(this, modelId, isDegraded, status)
    CLASS(AP_Registry_Domain), INTENT(IN)  :: this
    INTEGER(i8),            INTENT(IN)  :: modelId
    LOGICAL,                   INTENT(OUT) :: isDegraded
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)
    isDegraded = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Registry domain not initialized'
      RETURN
    END IF

    ! Placeholder: score-based degradation check
    IF (modelId >= 1_i8 .AND. modelId <= INT(this%state%nModels, i8)) THEN
      isDegraded = this%models(INT(modelId, i4))%lastScore < this%ctrl%degradationThreshold
    END IF
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Registry_CheckDegradation_Impl

  !====================================================================
  ! AP_Registry_Domain_GetSummary  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Registry_Domain_GetSummary(this, arg)
    CLASS(AP_Registry_Domain),      INTENT(IN)    :: this
    TYPE(AP_Registry_GetSummary_Arg),INTENT(INOUT) :: arg
    CALL AP_Registry_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE AP_Registry_Domain_GetSummary

  SUBROUTINE AP_Registry_GetSummary_Impl(this, summary, status)
    CLASS(AP_Registry_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),        INTENT(OUT) :: summary
    TYPE(ErrorStatusType),     INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'Registry domain not initialized'
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,L1,A,ES10.3)') &
      'Registry Summary: Models=', this%state%nModels, &
      ', AuditLogs=', this%state%nAuditLogs, &
      ', DegradationCheck=', this%ctrl%degradationCheck, &
      ', Threshold=', this%ctrl%degradationThreshold

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Registry_GetSummary_Impl

END MODULE AP_Reg_Domain