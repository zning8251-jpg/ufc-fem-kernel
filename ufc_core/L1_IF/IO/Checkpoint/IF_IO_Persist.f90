!===============================================================================
! MODULE: IF_IO_Persist
! LAYER:  L1_IF
! DOMAIN: IO
! ROLE:   Mgr — persistence domain (file registry, unit mgmt, checkpoint)
! BRIEF:  RegisterFile / OpenFile / WriteCheckpoint / CloseAll; Fortran unit pool.
!===============================================================================

MODULE IF_IO_Persist
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! File purpose enumerations
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: IF_FILE_GENERIC  = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_FILE_RESTART  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_FILE_RESULT   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: IF_FILE_LOG      = 3_i4

  !--- Fortran unit range reserved for managed files ---
  INTEGER(i4), PARAMETER :: IF_UNIT_BASE = 20_i4
  INTEGER(i4), PARAMETER :: IF_UNIT_MAX  = 99_i4

  !--------------------------------------------------------------------
  ! IF_PersistConfig ??persistence configuration
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_PersistConfig
    CHARACTER(LEN=256) :: workDir       = "."
    CHARACTER(LEN=256) :: backupDir     = "./backup"
    INTEGER(i4)        :: maxBackups    = 3_i4
    INTEGER(i4)        :: maxFiles      = 32_i4
    LOGICAL            :: enAutoBackup  = .FALSE.
    LOGICAL            :: enCompression = .FALSE.
  END TYPE IF_PersistConfig

  !--------------------------------------------------------------------
  ! IF_FileRecord ??per-file registry entry
  !
  ! Each managed file gets a unique Fortran unit in [IF_UNIT_BASE..IF_UNIT_MAX].
  ! The unit is reserved at RegisterFile and freed at CloseFile/Finalize.
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_FileRecord
    CHARACTER(LEN=256) :: filename = ""
    INTEGER(i4)        :: unit     = 0_i4    ! Fortran unit number
    INTEGER(i4)        :: purpose  = IF_FILE_GENERIC
    LOGICAL            :: isOpen   = .FALSE.
    LOGICAL            :: readOnly = .FALSE.
  END TYPE IF_FileRecord

  !--------------------------------------------------------------------
  ! IF_Persist_Domain ??domain container
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Persist_Domain
    TYPE(IF_PersistConfig)           :: config
    TYPE(IF_FileRecord), ALLOCATABLE :: files(:)
    INTEGER(i4) :: nFilesManaged = 0_i4
    INTEGER(i4) :: file_cap      = 0_i4
    LOGICAL     :: initialized   = .FALSE.
  CONTAINS
    PROCEDURE :: Init             => IF_IO_Persist_Init
    PROCEDURE :: Finalize         => IF_IO_Persist_Finalize
    PROCEDURE :: RegisterFile     => IF_Persist_RegisterFile
    PROCEDURE :: OpenFile         => IF_Persist_OpenFile
    PROCEDURE :: CloseFile        => IF_Persist_CloseFile
    PROCEDURE :: WriteCheckpoint  => IF_Persist_WriteCheckpoint
    PROCEDURE :: ReadCheckpoint   => IF_Persist_ReadCheckpoint
  END TYPE IF_Persist_Domain

CONTAINS

  !====================================================================
  ! IF_IO_Persist_Init ??initialise persistence domain
  !====================================================================
  SUBROUTINE IF_IO_Persist_Init(this, workDir, status)
    CLASS(IF_Persist_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),         INTENT(IN)    :: workDir
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    this%config%workDir   = TRIM(workDir)
    this%file_cap         = this%config%maxFiles
    ALLOCATE(this%files(this%file_cap))
    this%nFilesManaged    = 0_i4
    this%initialized      = .TRUE.
    status%status_code    = IF_STATUS_OK

  END SUBROUTINE IF_IO_Persist_Init

  !====================================================================
  ! IF_IO_Persist_Finalize ??close all open files, release registry
  !====================================================================
  SUBROUTINE IF_IO_Persist_Finalize(this)
    CLASS(IF_Persist_Domain), INTENT(INOUT) :: this
    INTEGER(i4) :: i
    TYPE(ErrorStatusType) :: dummy_status

    IF (.NOT. this%initialized) RETURN

    DO i = 1, this%nFilesManaged
      IF (this%files(i)%isOpen) CALL this%CloseFile(i, dummy_status)
    END DO

    IF (ALLOCATED(this%files)) DEALLOCATE(this%files)
    this%nFilesManaged        = 0_i4
    this%file_cap             = 0_i4
    this%config%workDir       = "."
    this%config%backupDir     = "./backup"
    this%config%maxBackups    = 3_i4
    this%config%maxFiles      = 32_i4
    this%config%enAutoBackup  = .FALSE.
    this%config%enCompression = .FALSE.
    this%initialized          = .FALSE.

  END SUBROUTINE IF_IO_Persist_Finalize

  !====================================================================
  ! IF_Persist_RegisterFile ??register a filename, assign Fortran unit
  !
  ! Computation chain:
  !   1. Guard: domain initialized, slot available, filename non-empty
  !   2. Find next free unit in [IF_UNIT_BASE..IF_UNIT_MAX] not already used
  !      by any registered file (sequential scan of files(1:n)%unit)
  !   3. Write IF_FileRecord entry; nFilesManaged++
  !   4. Return registry index [OUT] for subsequent Open/Close/Write calls
  !
  ! Fortran unit assignment is stable for the lifetime of the job;
  ! units are released only by CloseFile or Finalize.
  !====================================================================
  SUBROUTINE IF_Persist_RegisterFile(this, filename, purpose, &
                                     readOnly, reg_idx, status)
    CLASS(IF_Persist_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),         INTENT(IN)    :: filename
    INTEGER(i4),              INTENT(IN)    :: purpose
    LOGICAL,                  INTENT(IN)    :: readOnly
    INTEGER(i4),              INTENT(OUT)   :: reg_idx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: u, i
    LOGICAL     :: unit_used

    CALL init_error_status(status)
    reg_idx = 0_i4

    IF (.NOT. this%initialized .OR. LEN_TRIM(filename) == 0) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (this%nFilesManaged >= this%file_cap) THEN
      status%status_code = IF_STATUS_INVALID; RETURN   ! registry full
    END IF

    ! Find a free Fortran unit
    u = 0_i4
    DO u = IF_UNIT_BASE, IF_UNIT_MAX
      unit_used = .FALSE.
      DO i = 1, this%nFilesManaged
        IF (this%files(i)%unit == u) THEN
          unit_used = .TRUE.; EXIT
        END IF
      END DO
      IF (.NOT. unit_used) EXIT
    END DO
    IF (u > IF_UNIT_MAX) THEN
      status%status_code = IF_STATUS_INVALID; RETURN   ! no free unit
    END IF

    this%nFilesManaged = this%nFilesManaged + 1_i4
    reg_idx            = this%nFilesManaged
    this%files(reg_idx)%filename = TRIM(filename)
    this%files(reg_idx)%unit     = u
    this%files(reg_idx)%purpose  = purpose
    this%files(reg_idx)%isOpen   = .FALSE.
    this%files(reg_idx)%readOnly = readOnly
    status%status_code           = IF_STATUS_OK

  END SUBROUTINE IF_Persist_RegisterFile

  !====================================================================
  ! IF_Persist_OpenFile ??open a registered file
  !
  ! Computation chain:
  !   OPEN(unit, FILE=filename, FORM='UNFORMATTED'/'FORMATTED',
  !        STATUS='OLD'/'UNKNOWN', ACTION='READ'/'READWRITE')
  !   Sets files(idx)%isOpen = .TRUE. on success.
  !   Restart files: UNFORMATTED (binary, compact, fast).
  !   Log/result files: FORMATTED (human-readable or text-based).
  !====================================================================
  SUBROUTINE IF_Persist_OpenFile(this, reg_idx, status)
    CLASS(IF_Persist_Domain), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: reg_idx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: ios

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. reg_idx < 1 .OR. &
        reg_idx > this%nFilesManaged) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (this%files(reg_idx)%isOpen) THEN
      status%status_code = IF_STATUS_OK; RETURN   ! already open, no-op
    END IF

    IF (this%files(reg_idx)%purpose == IF_FILE_RESTART .OR. &
        this%files(reg_idx)%purpose == IF_FILE_RESULT) THEN
      ! Binary unformatted for compact restart/result files
      IF (this%files(reg_idx)%readOnly) THEN
        OPEN(UNIT=this%files(reg_idx)%unit, &
             FILE=TRIM(this%files(reg_idx)%filename), &
             FORM='UNFORMATTED', STATUS='OLD', ACTION='READ', IOSTAT=ios)
      ELSE
        OPEN(UNIT=this%files(reg_idx)%unit, &
             FILE=TRIM(this%files(reg_idx)%filename), &
             FORM='UNFORMATTED', STATUS='UNKNOWN', ACTION='READWRITE', IOSTAT=ios)
      END IF
    ELSE
      ! Formatted (log, generic)
      OPEN(UNIT=this%files(reg_idx)%unit, &
           FILE=TRIM(this%files(reg_idx)%filename), &
           FORM='FORMATTED', STATUS='UNKNOWN', ACTION='READWRITE', IOSTAT=ios)
    END IF

    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    this%files(reg_idx)%isOpen = .TRUE.
    status%status_code         = IF_STATUS_OK

  END SUBROUTINE IF_Persist_OpenFile

  !====================================================================
  ! IF_Persist_CloseFile ??close a registered file
  !====================================================================
  SUBROUTINE IF_Persist_CloseFile(this, reg_idx, status)
    CLASS(IF_Persist_Domain), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: reg_idx
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: ios

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. reg_idx < 1 .OR. &
        reg_idx > this%nFilesManaged) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. this%files(reg_idx)%isOpen) THEN
      status%status_code = IF_STATUS_OK; RETURN   ! already closed
    END IF

    CLOSE(UNIT=this%files(reg_idx)%unit, IOSTAT=ios)
    this%files(reg_idx)%isOpen = .FALSE.
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    status%status_code = IF_STATUS_OK

  END SUBROUTINE IF_Persist_CloseFile

  !====================================================================
  ! IF_Persist_ReadCheckpoint - read binary restart header
  !
  ! Usage: Call after OpenFile; caller reads payload records after header.
  !====================================================================
  SUBROUTINE IF_Persist_ReadCheckpoint(this, reg_idx, step_id, inc_id, sim_time, status)
    CLASS(IF_Persist_Domain), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: reg_idx
    INTEGER(i4),              INTENT(OUT)   :: step_id
    INTEGER(i4),              INTENT(OUT)   :: inc_id
    REAL(wp),                 INTENT(OUT)   :: sim_time
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: ios
    CHARACTER(LEN=12), PARAMETER :: MAGIC = "UFC_RESTART "
    CHARACTER(LEN=12) :: magic_read

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. reg_idx < 1 .OR. &
        reg_idx > this%nFilesManaged) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. this%files(reg_idx)%isOpen .OR. .NOT. this%files(reg_idx)%readOnly) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    READ(UNIT=this%files(reg_idx)%unit, IOSTAT=ios) magic_read, step_id, inc_id, sim_time
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (TRIM(magic_read) /= TRIM(MAGIC)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_Persist_ReadCheckpoint: invalid magic header"
      RETURN
    END IF
    status%status_code = IF_STATUS_OK

  END SUBROUTINE IF_Persist_ReadCheckpoint

  !====================================================================
  ! IF_Persist_WriteCheckpoint - write binary restart snapshot
  !
  ! Computation chain:
  !   1. Guard: file registered, open, not readOnly
  !   2. WRITE(unit) magic header ("UFC_RESTART"), step, inc, time
  !      (payload written by caller immediately after this header)
  !   3. Update stats (future: nCheckpoints counter)
  !
  ! Usage protocol:
  !   CALL persist%WriteCheckpoint(idx, step_id, inc_id, sim_time, status)
  !   WRITE(persist%files(idx)%unit) u_vec(:)    ! displacements
  !   WRITE(persist%files(idx)%unit) sigma(:,:)  ! stresses
  !   (caller owns the payload writes; this routine writes header only)
  !====================================================================
  SUBROUTINE IF_Persist_WriteCheckpoint(this, reg_idx, step_id, inc_id, &
                                        sim_time, status)
    CLASS(IF_Persist_Domain), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: reg_idx
    INTEGER(i4),              INTENT(IN)    :: step_id
    INTEGER(i4),              INTENT(IN)    :: inc_id
    REAL(wp),                 INTENT(IN)    :: sim_time
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: ios
    CHARACTER(LEN=12), PARAMETER :: MAGIC = "UFC_RESTART "

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. reg_idx < 1 .OR. &
        reg_idx > this%nFilesManaged) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    IF (.NOT. this%files(reg_idx)%isOpen .OR. this%files(reg_idx)%readOnly) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    ! Write checkpoint header record; caller follows with payload records
    WRITE(UNIT=this%files(reg_idx)%unit, IOSTAT=ios) &
      MAGIC, step_id, inc_id, sim_time

    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    status%status_code = IF_STATUS_OK

  END SUBROUTINE IF_Persist_WriteCheckpoint

END MODULE IF_IO_Persist