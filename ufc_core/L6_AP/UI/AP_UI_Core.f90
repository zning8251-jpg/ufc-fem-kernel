!===============================================================================
! MODULE: AP_UI_Core
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Core — console output helpers
! BRIEF:  Banners, progress bars, section headers, warning/error messages.
!===============================================================================
MODULE AP_UI_Core
  USE IF_Prec_Core,     ONLY: wp, i4
  USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_UI_Def,   ONLY: AP_UI_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_UI_Core_Init
  PUBLIC :: AP_UI_Core_Finalize
  PUBLIC :: AP_UI_Print_Banner
  PUBLIC :: AP_UI_Print_Progress
  PUBLIC :: AP_UI_Print_Section
  PUBLIC :: AP_UI_Print_Warning
  PUBLIC :: AP_UI_Print_Error
  PUBLIC :: AP_UI_Print_Done

CONTAINS

  SUBROUTINE AP_UI_Core_Init(desc, status)
    TYPE(AP_UI_Desc),      INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Core_Init

  SUBROUTINE AP_UI_Core_Finalize(desc, status)
    TYPE(AP_UI_Desc),      INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Core_Finalize

  !---------------------------------------------------------------------------
  ! Print banner with repeated character
  !---------------------------------------------------------------------------
  SUBROUTINE AP_UI_Print_Banner(desc, title, status)
    TYPE(AP_UI_Desc),      INTENT(IN)  :: desc
    CHARACTER(LEN=*),      INTENT(IN)  :: title
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(LEN=256) :: line
    INTEGER(i4) :: i, w

    CALL init_error_status(status)
    w = MIN(desc%line_width, 256)
    DO i = 1, w
      line(i:i) = desc%banner_char(1:1)
    END DO
    WRITE(desc%output_unit, '(A)') line(1:w)
    WRITE(desc%output_unit, '(A)') TRIM(title)
    WRITE(desc%output_unit, '(A)') line(1:w)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Print_Banner

  !---------------------------------------------------------------------------
  ! Print progress: label [current/total]
  !---------------------------------------------------------------------------
  SUBROUTINE AP_UI_Print_Progress(desc, label, current, total, status)
    TYPE(AP_UI_Desc),      INTENT(IN)  :: desc
    CHARACTER(LEN=*),      INTENT(IN)  :: label
    INTEGER(i4),           INTENT(IN)  :: current
    INTEGER(i4),           INTENT(IN)  :: total
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (total <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_UI_Print_Progress]: total <= 0"
      RETURN
    END IF
    WRITE(desc%output_unit, '(A,A,I0,A,I0,A)') &
      TRIM(label), " [", current, "/", total, "]"
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Print_Progress

  !---------------------------------------------------------------------------
  ! Print section header
  !---------------------------------------------------------------------------
  SUBROUTINE AP_UI_Print_Section(desc, title, status)
    TYPE(AP_UI_Desc),      INTENT(IN)  :: desc
    CHARACTER(LEN=*),      INTENT(IN)  :: title
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    WRITE(desc%output_unit, '(A)') ""
    WRITE(desc%output_unit, '(A,A,A)') "--- ", TRIM(title), " ---"
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Print_Section

  !---------------------------------------------------------------------------
  ! Print warning message
  !---------------------------------------------------------------------------
  SUBROUTINE AP_UI_Print_Warning(desc, message, status)
    TYPE(AP_UI_Desc),      INTENT(IN)  :: desc
    CHARACTER(LEN=*),      INTENT(IN)  :: message
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    WRITE(desc%output_unit, '(A,A)') "*** WARNING: ", TRIM(message)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Print_Warning

  !---------------------------------------------------------------------------
  ! Print error message
  !---------------------------------------------------------------------------
  SUBROUTINE AP_UI_Print_Error(desc, message, status)
    TYPE(AP_UI_Desc),      INTENT(IN)  :: desc
    CHARACTER(LEN=*),      INTENT(IN)  :: message
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    WRITE(desc%output_unit, '(A,A)') "*** ERROR: ", TRIM(message)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Print_Error

  !---------------------------------------------------------------------------
  ! Print completion message
  !---------------------------------------------------------------------------
  SUBROUTINE AP_UI_Print_Done(desc, message, status)
    TYPE(AP_UI_Desc),      INTENT(IN)  :: desc
    CHARACTER(LEN=*),      INTENT(IN)  :: message
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    WRITE(desc%output_unit, '(A,A)') "[DONE] ", TRIM(message)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_UI_Print_Done

END MODULE AP_UI_Core
