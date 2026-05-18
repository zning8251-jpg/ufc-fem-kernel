!===============================================================================
! MODULE: IF_IO_Core
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Core — file I/O using Desc+Ctx types
! BRIEF:  Init/Finalize [P0], Open/Close/Read/Write [P1/P2], checkpoint read.
!===============================================================================
MODULE IF_IO_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_IO_Def,  ONLY: IF_IO_Desc, IF_IO_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: IF_IO_Core_Init
  PUBLIC :: IF_IO_Core_Finalize
  PUBLIC :: IF_IO_Open
  PUBLIC :: IF_IO_Close
  PUBLIC :: IF_IO_Write_Real_Array
  PUBLIC :: IF_IO_Read_Real_Array
  PUBLIC :: IF_IO_Read_Checkpoint
  PUBLIC :: IF_IO_File_Exists

CONTAINS

  SUBROUTINE IF_IO_Core_Init(desc, ctx, status)
    TYPE(IF_IO_Desc),      INTENT(IN)  :: desc
    TYPE(IF_IO_Ctx),       INTENT(OUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    ctx%current_unit = 0
    ctx%unit_open    = .FALSE.
    ctx%current_file = ""
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_IO_Core_Init

  SUBROUTINE IF_IO_Core_Finalize(desc, ctx, status)
    TYPE(IF_IO_Desc),      INTENT(IN)    :: desc
    TYPE(IF_IO_Ctx),       INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    INTEGER(i4) :: istat
    CALL init_error_status(status)
    IF (ctx%unit_open) THEN
      CLOSE(ctx%current_unit, IOSTAT=istat)
      ctx%unit_open    = .FALSE.
      ctx%current_unit = 0
      ctx%current_file = ""
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_IO_Core_Finalize

  SUBROUTINE IF_IO_Open(desc, ctx, filename, unit_num, status)
    TYPE(IF_IO_Desc),      INTENT(IN)    :: desc
    TYPE(IF_IO_Ctx),       INTENT(INOUT) :: ctx
    CHARACTER(LEN=*),      INTENT(IN)    :: filename
    INTEGER(i4),           INTENT(IN)    :: unit_num
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    INTEGER(i4) :: istat
    CALL init_error_status(status)
    IF (unit_num < desc%unit_min .OR. unit_num > desc%unit_max) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_IO_Open: unit_num out of allowed range"
      RETURN
    END IF
    OPEN(UNIT=unit_num, FILE=TRIM(filename), STATUS='UNKNOWN', IOSTAT=istat)
    IF (istat /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_IO_Open: cannot open " // TRIM(filename)
      RETURN
    END IF
    ctx%current_unit = unit_num
    ctx%unit_open    = .TRUE.
    ctx%current_file = filename
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_IO_Open

  SUBROUTINE IF_IO_Close(ctx, status)
    TYPE(IF_IO_Ctx),       INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    INTEGER(i4) :: istat
    CALL init_error_status(status)
    IF (ctx%unit_open) THEN
      CLOSE(ctx%current_unit, IOSTAT=istat)
      IF (istat /= 0) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "IF_IO_Close: close failed"
        RETURN
      END IF
      ctx%unit_open    = .FALSE.
      ctx%current_unit = 0
      ctx%current_file = ""
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_IO_Close

  SUBROUTINE IF_IO_Write_Real_Array(ctx, n, arr, status)
    TYPE(IF_IO_Ctx),       INTENT(IN)  :: ctx
    INTEGER(i4),           INTENT(IN)  :: n
    REAL(wp),              INTENT(IN)  :: arr(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: istat
    CALL init_error_status(status)
    IF (.NOT. ctx%unit_open) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_IO_Write_Real_Array: no unit open"
      RETURN
    END IF
    WRITE(ctx%current_unit, IOSTAT=istat) arr(1:n)
    IF (istat /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_IO_Write_Real_Array: write failed"
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_IO_Write_Real_Array

  SUBROUTINE IF_IO_Read_Real_Array(ctx, n, arr, status)
    TYPE(IF_IO_Ctx),       INTENT(IN)  :: ctx
    INTEGER(i4),           INTENT(IN)  :: n
    REAL(wp),              INTENT(OUT) :: arr(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: istat
    CALL init_error_status(status)
    IF (.NOT. ctx%unit_open) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_IO_Read_Real_Array: no unit open"
      RETURN
    END IF
    READ(ctx%current_unit, IOSTAT=istat) arr(1:n)
    IF (istat /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_IO_Read_Real_Array: read failed"
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_IO_Read_Real_Array

  SUBROUTINE IF_IO_Read_Checkpoint(ctx, step_id, time, status)
    TYPE(IF_IO_Ctx),       INTENT(IN)  :: ctx
    INTEGER(i4),           INTENT(OUT) :: step_id
    REAL(wp),              INTENT(OUT) :: time
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    step_id = 0
    time    = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_IO_Read_Checkpoint

  SUBROUTINE IF_IO_File_Exists(filename, exists)
    CHARACTER(LEN=*), INTENT(IN)  :: filename
    LOGICAL,          INTENT(OUT) :: exists
    INQUIRE(FILE=TRIM(filename), EXIST=exists)
  END SUBROUTINE IF_IO_File_Exists

END MODULE IF_IO_Core
