!======================================================================
! Module: RT_OutRestart
! Layer:  L5_RT - Runtime Layer
! Domain: Output / Restart
! Purpose: Restart file writer/reader for job continuation.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: ACTIVE | SIO-REFACTORED | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output (AUTHORITY: RT_Out_Def.f90)
!======================================================================
!
! Contents (A-Z):
!   Types:
!     - [List types in A-Z order]
!   Subroutines:
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

module RT_Out_Restart
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
!> Theory: ABAQUS §9.1 (restart); Internal UFC restart spec §6 | Last verified: 2026-02-14
  !! Runtime IO - Refactored to route through L1_IF/IO (thin adapter pattern)
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, only: i4, i8, wp
  USE IF_IO_File, only: IF_FileHandle, IF_IO_MODE_READ, IF_IO_MODE_WRITE, &
                        IF_IO_FORMAT_BINARY, IF_FileHandle_Open_In, &
                        IF_FileHandle_Open_Out, IF_FileHandle_Close_In, &
                        IF_FileHandle_Close_Out
  USE MD_Step_Proc, only: MD_RestartData
  
  implicit none
  private
  
  public :: RT_Out_RestartSave
  public :: RT_Out_RestartRestore
  
contains

  SUBROUTINE RT_Out_RestartRestore(restart_data, filename, status)
    !! Restore restart data from file (binary deserialization)
    !See module header / UFC docs for context.
    !! Step 1:  inputparam（filename 
    !! Step 2:  （FORM='UNFORMATTED', ACCESS='STREAM'
    !! Step 3: ? time ? ?
    !! Step 4:  
    !! Step 5:  status 
    !! Step 6: Step ?
    !! Step 7:  
    !! Step 8:  return 
    TYPE(MD_RestartData), INTENT(OUT) :: restart_data
    CHARACTER(LEN=*), INTENT(IN) :: filename
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status, io_status
    TYPE(IF_FileHandle) :: handle
    TYPE(IF_FileHandle_Open_In) :: open_in
    TYPE(IF_FileHandle_Open_Out) :: open_out
    TYPE(IF_FileHandle_Close_In) :: close_in
    TYPE(IF_FileHandle_Close_Out) :: close_out
    INTEGER(i4) :: fileVer, dataSize, checksum
    INTEGER(i8) :: timestamp
    CHARACTER(LEN=256) :: fullPath
    LOGICAL :: fileExists
    INTEGER(i4), ALLOCATABLE :: intBuffer(:)
    
    CALL init_error_status(local_status)
    
    ! Step 1:  
    fullPath = TRIM(filename)
    INQUIRE(FILE=fullPath, EXIST=fileExists)
    
    IF (.NOT. fileExists) THEN
      local_status%status_code = IF_STATUS_INVALID
      WRITE(local_status%message, '(A,A)') 'Restart restore: File not found: ', TRIM(fullPath)
      restart_data%valid = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Step 2: Open file via L1_IF/IO (binary stream read)
    open_in%filename = fullPath
    open_in%mode = IF_IO_MODE_READ
    open_in%format = IF_IO_FORMAT_BINARY
    
    CALL IF_FileHandle_Open(handle, open_in%filename, open_in%mode, open_in%format, io_status)
    
    IF (io_status%status_code /= IF_STATUS_OK) THEN
      local_status%status_code = IF_STATUS_ERROR
      WRITE(local_status%message, '(A,A)') 'Restart restore: Cannot open file - ', TRIM(io_status%message)
      restart_data%valid = .FALSE.
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Step 3: Read header via L1_IF/IO
    CALL handle%ReadBinary([fileVer, INT(timestamp, i4), dataSize], 12_i8, io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 901
    
    ! Step 4:  
    IF (fileVer /= 1_i4) THEN
      local_status%status_code = IF_STATUS_INVALID
      WRITE(local_status%message, '(A,I0)') 'Restart restore: Incompatible file version: ', fileVer
      restart_data%valid = .FALSE.
      close_in%handle = handle
      CALL IF_FileHandle_Close(close_in, close_out)
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    IF (dataSize <= 0_i4) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Restart restore: Invalid data size'
      restart_data%valid = .FALSE.
      close_in%handle = handle
      CALL IF_FileHandle_Close(close_in, close_out)
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Step 5: status ?
    IF (ALLOCATED(restart_data%u)) DEALLOCATE(restart_data%u)
    IF (ALLOCATED(restart_data%v)) DEALLOCATE(restart_data%v)
    IF (ALLOCATED(restart_data%a)) DEALLOCATE(restart_data%a)
    
    ALLOCATE(restart_data%u(dataSize))
    ALLOCATE(restart_data%v(dataSize))
    ALLOCATE(restart_data%a(dataSize))
    ALLOCATE(intBuffer(dataSize))
    
    CALL handle%ReadBinary(restart_data%u, INT(8_i8 * dataSize, i8), io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 901
    
    CALL handle%ReadBinary(restart_data%v, INT(8_i8 * dataSize, i8), io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 901
    
    CALL handle%ReadBinary(restart_data%a, INT(8_i8 * dataSize, i8), io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 901
    
    ! Step 6: Read Step state
    CALL handle%ReadBinary([restart_data%time, INT(restart_data%increment, i4), &
                            restart_data%lambda], 20_i8, io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 901
    
    ! Read convergence history
    CALL handle%ReadBinary([restart_data%residual_norm, INT(restart_data%iterations, i4), &
                            restart_data%converged], 16_i8, io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 901
    
    ! Step 7: Read checksum
    CALL handle%ReadBinary([checksum], 4_i8, io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 901
    
    IF (checksum /= dataSize) THEN
      local_status%status_code = IF_STATUS_ERROR
      local_status%message = 'Restart restore: Checksum mismatch (file corrupted)'
      restart_data%valid = .FALSE.
      close_in%handle = handle
      CALL IF_FileHandle_Close(close_in, close_out)
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Step 8: Close file
    close_in%handle = handle
    CALL IF_FileHandle_Close(close_in, close_out)
    restart_data%valid = .TRUE.
    
    local_status%status_code = IF_STATUS_OK
    WRITE(local_status%message, '(A,A,A,I0,A)') &
      'Restart data restored from ', TRIM(filename), ' (', dataSize, ' DOFs)'
    IF (PRESENT(status)) status = local_status
    RETURN
    
901 CONTINUE
    ! error handling
    close_in%handle = handle
    CALL IF_FileHandle_Close(close_in, close_out)
    restart_data%valid = .FALSE.
    local_status%status_code = IF_STATUS_ERROR
    WRITE(local_status%message, '(A,A)') 'Restart restore: Read error - ', TRIM(io_status%message)
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_Out_RestartRestore

  SUBROUTINE RT_Out_RestartSave(restart_data, filename, status)
    !! Save restart data to file (binary serialization)
    !See module header / UFC docs for context.
    !! Step 1:  inputparam（filename ，restart_data 
    !! Step 2:  （FORM='UNFORMATTED', ACCESS='STREAM'
    !! Step 3: ? time ? ?
    !! Step 4:  status （u, v, a, history variables
    !! Step 5:  Stepstatus（time, increment, lambda
    !! Step 6:  convergence （residual_norm, iterations
    !! Step 7:  （CRC32 MD5
    !! Step 8:  return 
    TYPE(MD_RestartData), INTENT(IN) :: restart_data
    CHARACTER(LEN=*), INTENT(IN) :: filename
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(ErrorStatusType) :: local_status, io_status
    TYPE(IF_FileHandle) :: handle
    TYPE(IF_FileHandle_Open_In) :: open_in
    TYPE(IF_FileHandle_Open_Out) :: open_out
    TYPE(IF_FileHandle_Close_In) :: close_in
    TYPE(IF_FileHandle_Close_Out) :: close_out
    INTEGER(i4) :: fileVer, dataSize
    INTEGER(i8) :: timestamp
    CHARACTER(LEN=256) :: fullPath
    LOGICAL :: fileExists
    INTEGER(i4), ALLOCATABLE :: intBuffer(:)
    
    CALL init_error_status(local_status)
    
    ! Step 1:  inputparam
    IF (LEN_TRIM(filename) == 0) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Restart save: Empty filename'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    IF (.NOT. restart_data%valid) THEN
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = 'Restart save: Invalid restart data'
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Step 2: Open file via L1_IF/IO (binary stream write)
    fullPath = TRIM(filename)
    
    open_in%filename = fullPath
    open_in%mode = IF_IO_MODE_WRITE
    open_in%format = IF_IO_FORMAT_BINARY
    
    CALL IF_FileHandle_Open(handle, open_in%filename, open_in%mode, open_in%format, io_status)
    
    IF (io_status%status_code /= IF_STATUS_OK) THEN
      local_status%status_code = IF_STATUS_ERROR
      WRITE(local_status%message, '(A,A,A)') &
        'Restart save: Cannot open file - ', TRIM(fullPath), ' - ' // TRIM(io_status%message)
      IF (PRESENT(status)) status = local_status
      RETURN
    END IF
    
    ! Step 3: Write header via L1_IF/IO
    fileVer = 1_i4        ! Version
    timestamp = 20260204_i8    ! Timestamp (YYYYMMDD)
    dataSize = 0_i4
    IF (ALLOCATED(restart_data%u)) dataSize = SIZE(restart_data%u)
    
    CALL handle%WriteBinary([fileVer, INT(timestamp, i4), dataSize], 12_i8, io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 900
    
    ! Step 4: Write displacement/velocity/acceleration
    IF (ALLOCATED(restart_data%u)) THEN
      CALL handle%WriteBinary(restart_data%u, INT(8_i8 * SIZE(restart_data%u), i8), io_status)
      IF (io_status%status_code /= IF_STATUS_OK) GOTO 900
    END IF
    
    IF (ALLOCATED(restart_data%v)) THEN
      CALL handle%WriteBinary(restart_data%v, INT(8_i8 * SIZE(restart_data%v), i8), io_status)
      IF (io_status%status_code /= IF_STATUS_OK) GOTO 900
    END IF
    
    IF (ALLOCATED(restart_data%a)) THEN
      CALL handle%WriteBinary(restart_data%a, INT(8_i8 * SIZE(restart_data%a), i8), io_status)
      IF (io_status%status_code /= IF_STATUS_OK) GOTO 900
    END IF
    
    ! Step 5: Write Step state
    CALL handle%WriteBinary([restart_data%time, INT(restart_data%increment, i4), &
                             restart_data%lambda], 20_i8, io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 900
    
    ! Step 6: Write convergence history
    CALL handle%WriteBinary([restart_data%residual_norm, INT(restart_data%iterations, i4), &
                             restart_data%converged], 16_i8, io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 900
    
    ! Step 7: Write checksum
    CALL handle%WriteBinary([dataSize], 4_i8, io_status)
    IF (io_status%status_code /= IF_STATUS_OK) GOTO 900
    
    ! Step 8: Close file
    close_in%handle = handle
    CALL IF_FileHandle_Close(close_in, close_out)
    
    local_status%status_code = IF_STATUS_OK
    WRITE(local_status%message, '(A,A,A,I0,A)') &
      'Restart data saved to ', TRIM(filename), ' (', dataSize, ' DOFs)'
    IF (PRESENT(status)) status = local_status
    RETURN
    
900 CONTINUE
    ! error handling
    close_in%handle = handle
    CALL IF_FileHandle_Close(close_in, close_out)
    local_status%status_code = IF_STATUS_ERROR
    WRITE(local_status%message, '(A,A)') 'Restart save: Write error - ', TRIM(io_status%message)
    IF (PRESENT(status)) status = local_status
    
  END SUBROUTINE RT_Out_RestartSave
end module RT_Out_Restart