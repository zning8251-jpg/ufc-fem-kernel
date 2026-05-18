!===============================================================================
! MODULE: IF_IO_Mgr
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Mgr — IO domain container (file handle pool, config, lifecycle)
! BRIEF:  IF_IO_Domain container; Init/Finalize [P0], handle management.
!===============================================================================

MODULE IF_IO_Mgr
  USE IF_Prec_Core,     ONLY: wp, i4
  USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_IO_Def, ONLY: IF_IO_Cfg_Type
  USE IF_IO_File,  ONLY: IF_FileHandle, IF_IO_MODE_READ, IF_IO_MODE_WRITE, IF_IO_MODE_APPEND, &
                          IF_IO_FORMAT_TEXT, IF_IO_FORMAT_BINARY
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! IF_IO_Domain ??Domain container
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_IO_Domain
    TYPE(IF_IO_Cfg_Type) :: config
    TYPE(IF_FileHandle), ALLOCATABLE :: handles(:)
    INTEGER(i4) :: maxOpenFiles = 64_i4
    INTEGER(i4) :: nOpenFiles   = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: OpenFile
    PROCEDURE :: CloseFile
    PROCEDURE :: GetHandle
  END TYPE IF_IO_Domain

CONTAINS

  !====================================================================
  ! IF_IO_Finalize ??Close all open handles, reset config
  !====================================================================
  SUBROUTINE Finalize(this)
    CLASS(IF_IO_Domain), INTENT(INOUT) :: this
    INTEGER(i4) :: i
    TYPE(ErrorStatusType) :: loc_status

    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%handles)) THEN
      DO i = 1, this%maxOpenFiles
        IF (this%handles(i)%is_open) CALL this%handles(i)%Close(loc_status)
      END DO
      DEALLOCATE(this%handles)
    END IF
    this%nOpenFiles  = 0_i4
    this%config%bufferSize   = 65536_i4
    this%config%enBuffered   = .TRUE.
    this%config%enCompressed = .FALSE.
    this%initialized = .FALSE.

  END SUBROUTINE Finalize

  !====================================================================
  ! IF_IO_Init - Initialize IO domain
  !====================================================================
  SUBROUTINE Init(this, status)
    CLASS(IF_IO_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    ALLOCATE(this%handles(this%maxOpenFiles))
    this%nOpenFiles  = 0_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE Init

  !====================================================================
  ! IF_IO_OpenFile - Open file, return handle index
  !====================================================================
  SUBROUTINE OpenFile(this, filename, mode, format, handle_idx, status)
    CLASS(IF_IO_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: filename
    INTEGER(i4), INTENT(IN), OPTIONAL :: mode, format
    INTEGER(i4), INTENT(OUT) :: handle_idx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, m, f

    CALL init_error_status(status)
    handle_idx = 0_i4
    IF (.NOT. this%initialized .OR. .NOT. ALLOCATED(this%handles)) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    m = IF_IO_MODE_READ; IF (PRESENT(mode)) m = mode
    f = IF_IO_FORMAT_TEXT; IF (PRESENT(format)) f = format

    DO i = 1, this%maxOpenFiles
      IF (.NOT. this%handles(i)%is_open) THEN
        CALL this%handles(i)%Open(TRIM(filename), m, f, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        handle_idx = i
        this%nOpenFiles = this%nOpenFiles + 1_i4
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_INVALID
    status%message = "IF_IO_OpenFile: no free handle slot"

  END SUBROUTINE OpenFile

  !====================================================================
  ! IF_IO_CloseFile - Close file by handle index
  !====================================================================
  SUBROUTINE CloseFile(this, handle_idx, status)
    CLASS(IF_IO_Domain), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: handle_idx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. handle_idx < 1 .OR. handle_idx > this%maxOpenFiles) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. this%handles(handle_idx)%is_open) THEN
      status%status_code = IF_STATUS_OK; RETURN
    END IF
    CALL this%handles(handle_idx)%Close(status)
    this%nOpenFiles = MAX(0_i4, this%nOpenFiles - 1_i4)

  END SUBROUTINE CloseFile

  !====================================================================
  ! IF_IO_GetHandle - Get handle by index
  !====================================================================
  FUNCTION GetHandle(this, handle_idx) RESULT(h)
    CLASS(IF_IO_Domain), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: handle_idx
    TYPE(IF_FileHandle) :: h
    h%unit = -1_i4
    h%is_open = .FALSE.
    IF (ALLOCATED(this%handles) .AND. handle_idx >= 1 .AND. handle_idx <= this%maxOpenFiles) THEN
      h = this%handles(handle_idx)
    END IF
  END FUNCTION GetHandle

END MODULE IF_IO_Mgr