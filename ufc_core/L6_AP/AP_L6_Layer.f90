!===============================================================================
! MODULE: AP_L6_Layer
! LAYER:  L6_AP
! DOMAIN: Root
! ROLE:   Layer â€?layer-level container
! BRIEF:  L6 layer container aggregating all application domains.
!===============================================================================
! Init order (dependency-driven): Base -> Input -> Registry
! Finalize order: strict reverse
!===============================================================================
MODULE AP_L6_Layer
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID

  USE AP_Base_Mgr,        ONLY: AP_Base_Domain
  USE AP_Inp_Mgr,         ONLY: AP_Input_Domain
  USE AP_Reg_Domain,       ONLY: AP_Registry_Domain
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: AP_L6_LayerContainer
    ! --- Domain instances (only available ones) ---
    TYPE(AP_Base_Domain)      :: base
    TYPE(AP_Input_Domain)     :: input
    TYPE(AP_Registry_Domain)  :: registry
    ! Note: Other domains temporarily excluded due to dependencies
    ! --- Layer-level metadata ---
    CHARACTER(LEN=256) :: jobName     = ' '
    REAL(wp)           :: jobStartTime = 0.0_wp
    LOGICAL            :: initialized  = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE AP_L6_LayerContainer

CONTAINS

  SUBROUTINE AP_L6_Finalize(this)
    CLASS(AP_L6_LayerContainer), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    
    ! Finalize in strict reverse: Registry -> Input -> Base
    CALL this%registry%Finalize()
    CALL this%input%Finalize()
    CALL this%base%Finalize()
    
    this%jobName    = ' '
    this%initialized = .FALSE.
  END SUBROUTINE AP_L6_Finalize

  SUBROUTINE AP_L6_Init(this, status)
    CLASS(AP_L6_LayerContainer), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status
    
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    ! Init order: Base -> Input -> Registry
    CALL this%base%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    CALL this%input%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    CALL this%registry%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_L6_Init

END MODULE AP_L6_Layer