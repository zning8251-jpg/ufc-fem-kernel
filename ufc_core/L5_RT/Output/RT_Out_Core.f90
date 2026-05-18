!===============================================================================
! Module:  RT_Output_Core
! Layer:   L5_RT - Runtime Layer
! Domain:  Output
! Purpose: LEGACY/FACADE file-I/O wrapper using RT_Output_Def legacy types.
!          Production output orchestration is in RT_Out.f90 (Golden Path).
!
! Status: LEGACY | FACADE | Last verified: 2026-04-26
!
! Migration: New code should use RT_Out.f90 + RT_Out_Def.f90 (AUTHORITY).
!            This module exists only for backward compatibility.
!
! WARNING — Shadow types: The types RT_Output_Desc, RT_Output_State, and
!   RT_Output_Ctx defined below are SHADOW types that conflict with the
!   AUTHORITY four-type system in RT_Out_Def.f90 (where the canonical types
!   are RT_Out_Desc, RT_Out_FieldState, RT_Out_HistState, RT_Out, RT_Out_Ctx).
!   These shadow types are retained for legacy FACADE compat only; new code
!   must use RT_Out_Def.f90 types. Do NOT add fields here.
!
! Domain Pillar: P5 Output
!   AUTHORITY: RT_Out_Def.f90
!   Golden Path: RT_Out.f90
!===============================================================================
MODULE RT_Out_Core
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !-- Legacy adapter types (FACADE only; AUTHORITY is RT_Out_Def.f90)
  TYPE, PUBLIC :: RT_Output_Desc
    CHARACTER(LEN=256) :: file_path   = ''
    INTEGER(i4)        :: unit_num    = 10_i4
    INTEGER(i4)        :: output_freq = 1_i4
    INTEGER(i4)        :: output_format = 1_i4  ! 1=VTK
    LOGICAL            :: is_active   = .TRUE.
  END TYPE RT_Output_Desc

  TYPE, PUBLIC :: RT_Output_State
    INTEGER(i4) :: frame_count   = 0_i4
    INTEGER(i4) :: bytes_written = 0_i4
    REAL(wp)    :: total_written = 0.0_wp
    LOGICAL     :: is_open       = .FALSE.
  END TYPE RT_Output_State

  TYPE, PUBLIC :: RT_Output_Ctx
    REAL(wp), POINTER :: write_buffer(:) => NULL()
    INTEGER(i4)       :: buf_size = 0_i4
  END TYPE RT_Output_Ctx

  PUBLIC :: RT_Output_Core_Init
  PUBLIC :: RT_Output_Core_Finalize
  PUBLIC :: RT_Output_Open_File
  PUBLIC :: RT_Output_Close_File
  PUBLIC :: RT_Output_Write_Frame
  PUBLIC :: RT_Output_Write_Field
  PUBLIC :: RT_Output_Write_History
  PUBLIC :: RT_Output_Check_Frequency

CONTAINS

  SUBROUTINE RT_Output_Core_Init(desc, state, ctx, status)
    TYPE(RT_Output_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Output_State), INTENT(INOUT) :: state
    TYPE(RT_Output_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%frame_count   = 0
    state%bytes_written = 0
    state%total_written = 0.0_wp
    state%is_open       = .FALSE.
    NULLIFY(ctx%write_buffer)
    ctx%buf_size = 0
    status%status_code  = IF_STATUS_OK
  END SUBROUTINE RT_Output_Core_Init

  SUBROUTINE RT_Output_Core_Finalize(state, ctx, status)
    TYPE(RT_Output_State), INTENT(INOUT) :: state
    TYPE(RT_Output_Ctx),   INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (ASSOCIATED(ctx%write_buffer)) DEALLOCATE(ctx%write_buffer)
    NULLIFY(ctx%write_buffer)
    ctx%buf_size        = 0
    state%frame_count   = 0
    state%bytes_written = 0
    state%total_written = 0.0_wp
    state%is_open       = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Output_Core_Finalize

  SUBROUTINE RT_Output_Open_File(desc, state, status)
    TYPE(RT_Output_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Output_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: ios

    CALL init_error_status(status)
    IF (state%is_open) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (LEN_TRIM(desc%file_path) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    OPEN(UNIT=desc%unit_num, FILE=TRIM(desc%file_path), &
         STATUS='REPLACE', FORM='FORMATTED', IOSTAT=ios)
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    state%is_open = .TRUE.
    status%status_code   = IF_STATUS_OK
  END SUBROUTINE RT_Output_Open_File

  SUBROUTINE RT_Output_Close_File(state, status)
    TYPE(RT_Output_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (state%is_open) THEN
      state%is_open = .FALSE.
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Output_Close_File

  SUBROUTINE RT_Output_Write_Frame(desc, state, ctx, time, status)
    TYPE(RT_Output_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Output_State), INTENT(INOUT) :: state
    TYPE(RT_Output_Ctx),   INTENT(INOUT) :: ctx
    REAL(wp),              INTENT(IN)    :: time
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. state%is_open) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output file not open"
      RETURN
    END IF

    state%frame_count = state%frame_count + 1

    ! Write VTK-style frame header to output file
    WRITE(desc%unit_num, '(A)') 'BEGIN_FRAME'
    WRITE(desc%unit_num, '(A,I8)') '  FRAME_NUMBER: ', state%frame_count
    WRITE(desc%unit_num, '(A,ES16.8)') '  TIME: ', time
    WRITE(desc%unit_num, '(A)') 'END_FRAME'
    FLUSH(desc%unit_num)

    ! Update statistics
    state%bytes_written = state%bytes_written + 128  ! Estimate header size

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Output_Write_Frame

  SUBROUTINE RT_Output_Write_Field(desc, state, ctx, field_name, &
                                    n_vals, vals, status)
    TYPE(RT_Output_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Output_State), INTENT(INOUT) :: state
    TYPE(RT_Output_Ctx),   INTENT(INOUT) :: ctx
    CHARACTER(LEN=*),      INTENT(IN)    :: field_name
    INTEGER(i4),           INTENT(IN)    :: n_vals
    REAL(wp),              INTENT(IN)    :: vals(n_vals)
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. state%is_open) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output file not open"
      RETURN
    END IF

    ! Write field data: header + values + footer
    WRITE(desc%unit_num, '(A)') 'BEGIN_FIELD'
    WRITE(desc%unit_num, '(A,A)') '  NAME: ', TRIM(field_name)
    WRITE(desc%unit_num, '(A,I12)') '  N_VALS: ', n_vals

    ! Write data in rows of 6 values for readability
    BLOCK
      INTEGER(i4) :: idx, chunk
      CHARACTER(LEN=256) :: line_buf
      DO idx = 1, n_vals, 6
        chunk = MIN(6, n_vals - idx + 1)
        WRITE(line_buf, '(6ES16.8)') (vals(MIN(idx + j - 1, n_vals)), j = 1, chunk)
        WRITE(desc%unit_num, '(A,A)') '  DATA: ', TRIM(line_buf)
      END DO
    END BLOCK

    WRITE(desc%unit_num, '(A)') 'END_FIELD'
    FLUSH(desc%unit_num)

    ! Update statistics (estimate: header + data + footer)
    state%bytes_written = state%bytes_written + 64 + n_vals * 16

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Output_Write_Field

  SUBROUTINE RT_Output_Write_History(desc, state, time, value, label, status)
    TYPE(RT_Output_Desc),  INTENT(IN)    :: desc
    TYPE(RT_Output_State), INTENT(INOUT) :: state
    REAL(wp),              INTENT(IN)    :: time
    REAL(wp),              INTENT(IN)    :: value
    CHARACTER(LEN=*),      INTENT(IN)    :: label
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. state%is_open) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output file not open"
      RETURN
    END IF

    ! Write history point: time, value, label format
    WRITE(desc%unit_num, '(A,A)') 'HISTORY: ', TRIM(label)
    WRITE(desc%unit_num, '(ES16.8,2X,ES16.8)') time, value
    FLUSH(desc%unit_num)

    ! Track total written data
    state%total_written = state%total_written + value

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Output_Write_History

  SUBROUTINE RT_Output_Check_Frequency(desc, state, inc_num, should_write)
    TYPE(RT_Output_Desc),  INTENT(IN)  :: desc
    TYPE(RT_Output_State), INTENT(IN)  :: state
    INTEGER(i4),           INTENT(IN)  :: inc_num
    LOGICAL,               INTENT(OUT) :: should_write

    IF (desc%output_freq <= 0) THEN
      should_write = .FALSE.
    ELSE
      should_write = (MOD(inc_num, desc%output_freq) == 0)
    END IF
  END SUBROUTINE RT_Output_Check_Frequency

END MODULE RT_Out_Core
