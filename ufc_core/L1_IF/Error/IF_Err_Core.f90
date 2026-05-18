!===============================================================================
! MODULE: IF_Err_Core
! LAYER:  L1_IF
! DOMAIN: Error
! ROLE:   _Core
! BRIEF:  Error creation, chaining, and query utilities.
!===============================================================================
!
! Contents (A-Z):
!   IF_Error_Chain        [P1] Chain child error into parent
!   IF_Error_Core_Init    [P0] Initialize error core (desc-based)
!   IF_Error_Core_Finalize[P0] Finalize error core
!   IF_Error_Create       [P0] Create error status with code/message/source
!   IF_Error_Get_Message  [P3] Extract message from status
!   IF_Error_Is_Fatal     [P2] Check if status is fatal
!   IF_Error_Is_OK        [P2] Check if status is OK
!   IF_Error_Log          [P3] Write error to output unit
!   IF_Error_Set_Source   [P1] Set source field on status
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Err_Core
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Def, ONLY: IF_Error_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: IF_Error_Core_Init
  PUBLIC :: IF_Error_Core_Finalize
  PUBLIC :: IF_Error_Create
  PUBLIC :: IF_Error_Chain
  PUBLIC :: IF_Error_Set_Source
  PUBLIC :: IF_Error_Is_OK
  PUBLIC :: IF_Error_Is_Fatal
  PUBLIC :: IF_Error_Get_Message
  PUBLIC :: IF_Error_Log

CONTAINS

  SUBROUTINE IF_Error_Core_Init(desc, status)
    TYPE(IF_Error_Desc),   INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Error_Core_Init

  SUBROUTINE IF_Error_Core_Finalize(desc, status)
    TYPE(IF_Error_Desc),   INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Error_Core_Finalize

  SUBROUTINE IF_Error_Create(code, message, source, status)
    INTEGER(i4),           INTENT(IN)  :: code
    CHARACTER(LEN=*),      INTENT(IN)  :: message
    CHARACTER(LEN=*),      INTENT(IN)  :: source
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = code
    status%message     = message
    status%source      = source
  END SUBROUTINE IF_Error_Create

  SUBROUTINE IF_Error_Chain(parent, child, status)
    TYPE(ErrorStatusType), INTENT(INOUT) :: parent
    TYPE(ErrorStatusType), INTENT(IN)    :: child
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (child%status_code /= IF_STATUS_OK) THEN
      parent%status_code = child%status_code
      parent%message     = child%message
      parent%source      = child%source
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Error_Chain

  SUBROUTINE IF_Error_Set_Source(status, source)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status
    CHARACTER(LEN=*),      INTENT(IN)    :: source
    status%source = source
  END SUBROUTINE IF_Error_Set_Source

  PURE FUNCTION IF_Error_Is_OK(status) RESULT(ok)
    TYPE(ErrorStatusType), INTENT(IN) :: status
    LOGICAL :: ok
    ok = (status%status_code == IF_STATUS_OK)
  END FUNCTION IF_Error_Is_OK

  PURE FUNCTION IF_Error_Is_Fatal(status) RESULT(fatal)
    TYPE(ErrorStatusType), INTENT(IN) :: status
    LOGICAL :: fatal
    fatal = (status%status_code /= IF_STATUS_OK)
  END FUNCTION IF_Error_Is_Fatal

  SUBROUTINE IF_Error_Get_Message(status, message)
    TYPE(ErrorStatusType), INTENT(IN)  :: status
    CHARACTER(LEN=*),      INTENT(OUT) :: message
    message = status%message
  END SUBROUTINE IF_Error_Get_Message

  SUBROUTINE IF_Error_Log(status, unit_num)
    TYPE(ErrorStatusType), INTENT(IN) :: status
    INTEGER(i4),           INTENT(IN) :: unit_num
    IF (status%status_code /= IF_STATUS_OK) THEN
      WRITE(unit_num, '(A,I6,A,A,A,A)') &
        "[ERROR code=", status%status_code, "] ", &
        TRIM(status%source), ": ", TRIM(status%message)
    END IF
  END SUBROUTINE IF_Error_Log

END MODULE IF_Err_Core
