!===============================================================================
! MODULE: AP_Base_Mgr
! LAYER:  L6_AP
! DOMAIN: Base
! ROLE:   Mgr 鈥?domain manager
! BRIEF:  Application-level base services (version, license, config).
!===============================================================================
! Types:  AP_Base_State, AP_Base_Ctrl, AP_Base_Domain
! P0:     Init, Finalize, ValidateLicense, LoadConfig
! P3:     GetSummary
! Constants: AP_ERR_BASE .. AP_ERR_SOLVER_FAIL, AP_VERSION_*
!===============================================================================
MODULE AP_Base_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  ! --- L6 error code range: 6000-6999 ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_ERR_BASE            = 6000_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_ERR_LICENSE          = 6001_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_ERR_LICENSE_NOT_FOUND = 6003_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_ERR_CONFIG        = 6002_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_ERR_INPUT_FILE    = 6010_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_ERR_OUTPUT_FILE   = 6020_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_ERR_SOLVER_FAIL   = 6100_i4

  ! --- Version info ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_VERSION_MAJOR = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_VERSION_MINOR = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_VERSION_PATCH = 0_i4

  TYPE, PUBLIC :: AP_Base_State
    LOGICAL     :: licenseValid    = .FALSE.
    REAL(wp)    :: startupTime     = 0.0_wp   ! wall-clock at app start
    INTEGER(i4) :: exitCode        = 0_i4
  END TYPE AP_Base_State

  TYPE, PUBLIC :: AP_Base_Ctrl
    CHARACTER(LEN=512) :: configFilePath  = ' '
    CHARACTER(LEN=512) :: licenseFilePath = ' '
    CHARACTER(LEN=512) :: workDir         = '.'
    LOGICAL            :: debugMode      = .FALSE.
  END TYPE AP_Base_Ctrl

  TYPE, PUBLIC :: AP_Base_Domain
    TYPE(AP_Base_State) :: state
    TYPE(AP_Base_Ctrl)  :: ctrl
    LOGICAL             :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => AP_Base_Domain_Init
    PROCEDURE :: Finalize => AP_Base_Domain_Finalize
    PROCEDURE :: ValidateLicense => AP_Base_Domain_ValidateLicense
    PROCEDURE :: LoadConfig => AP_Base_Domain_LoadConfig
    PROCEDURE :: GetSummary => AP_Base_Domain_GetSummary
  END TYPE AP_Base_Domain

CONTAINS

  SUBROUTINE AP_Base_Domain_Finalize(this)
    CLASS(AP_Base_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%state = AP_Base_State()
    this%initialized = .FALSE.
  END SUBROUTINE AP_Base_Domain_Finalize

  SUBROUTINE AP_Base_Domain_Init(this, status)
    CLASS(AP_Base_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    REAL(wp) :: t
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctrl = AP_Base_Ctrl()
    CALL CPU_TIME(t)
    this%state%startupTime = t
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Base_Domain_Init

  !====================================================================
  ! AP_Base_Domain_ValidateLicense
  ! Validate license file and update licenseValid state
  !====================================================================
  SUBROUTINE AP_Base_Domain_ValidateLicense(this, licensePath, isValid, status)
    CLASS(AP_Base_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),      INTENT(IN)    :: licensePath
    LOGICAL,               INTENT(OUT)   :: isValid
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    LOGICAL :: fileExists

    CALL init_error_status(status)
    isValid = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Base domain not initialized"
      RETURN
    END IF

    ! Store license path
    this%ctrl%licenseFilePath = licensePath

    ! Validate license: path non-empty and file exists (minimal check)
    IF (LEN_TRIM(licensePath) == 0) THEN
      status%status_code = AP_ERR_LICENSE
      status%message = "License file path is empty"
      RETURN
    END IF
    INQUIRE(FILE=TRIM(licensePath), EXIST=fileExists)
    IF (.NOT. fileExists) THEN
      status%status_code = AP_ERR_LICENSE_NOT_FOUND
      status%message = "License file not found: " // TRIM(licensePath)
      RETURN
    END IF
    isValid = .TRUE.
    this%state%licenseValid = .TRUE.

  END SUBROUTINE AP_Base_Domain_ValidateLicense

  !====================================================================
  ! AP_Base_Domain_LoadConfig
  ! Load configuration from file
  !====================================================================
  SUBROUTINE AP_Base_Domain_LoadConfig(this, configPath, status)
    CLASS(AP_Base_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),      INTENT(IN)    :: configPath
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Base domain not initialized"
      RETURN
    END IF

    ! Store config path
    this%ctrl%configFilePath = configPath

    ! Load configuration (simplified - would parse config file in production)
    ! For now, just check if path is non-empty
    IF (LEN_TRIM(configPath) > 0) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = AP_ERR_CONFIG
      status%message = "Config file path is empty"
    END IF

  END SUBROUTINE AP_Base_Domain_LoadConfig

  !====================================================================
  ! AP_Base_Domain_GetSummary
  ! Get summary string of base domain
  !====================================================================
  SUBROUTINE AP_Base_Domain_GetSummary(this, summary, status)
    CLASS(AP_Base_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),    INTENT(OUT) :: summary
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Base domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,L1,A,ES10.3,A,I0)') &
      "Base Summary: Version=", AP_VERSION_MAJOR, ".", &
      AP_VERSION_MINOR, ".", AP_VERSION_PATCH, &
      ", LicenseValid=", this%state%licenseValid, &
      ", StartupTime=", this%state%startupTime, &
      ", ExitCode=", this%state%exitCode

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Base_Domain_GetSummary

END MODULE AP_Base_Mgr