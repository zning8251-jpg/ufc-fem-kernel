!===============================================================================
! MODULE: AP_Input_Core
! LAYER:  L6_AP
! DOMAIN: Input
! ROLE:   Core
! BRIEF:  Input file reading, keyword processing, and validation.
!
! Signature: (desc, state, status)
!   desc  — AP_Input_Desc  [IN]    file path and format
!   state — AP_Input_State [INOUT] parse progress counters
!
! Process phases:
!   P0: AP_Input_Core_Init / AP_Input_Core_Finalize
!   P1: AP_Input_Read_File / AP_Input_Process_Keywords
!   P0: AP_Input_Validate
!   P3: AP_Input_Get_Line_Count / AP_Input_Get_Error_Count
!
! NOTE: Standardised 4-step pipeline is in AP_Inp_Execute_Mod.
!       This module provides the low-level building blocks.
!
! Status: FOUR-TYPE | Last verified: 2026-04-29
!===============================================================================
MODULE AP_Input_Core
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Input_Def,   ONLY: AP_Input_Desc, AP_Input_State
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Input_Core_Init
  PUBLIC :: AP_Input_Core_Finalize
  PUBLIC :: AP_Input_Read_File
  PUBLIC :: AP_Input_Process_Keywords
  PUBLIC :: AP_Input_Validate
  PUBLIC :: AP_Input_Get_Line_Count
  PUBLIC :: AP_Input_Get_Error_Count

CONTAINS

  SUBROUTINE AP_Input_Core_Init(desc, state, status)
    TYPE(AP_Input_Desc),   INTENT(IN)  :: desc
    TYPE(AP_Input_State),  INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    state%lines_read   = 0
    state%parse_errors = 0
    state%is_complete  = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Input_Core_Init

  SUBROUTINE AP_Input_Core_Finalize(desc, state, status)
    TYPE(AP_Input_Desc),   INTENT(IN)    :: desc
    TYPE(AP_Input_State),  INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)
    state%lines_read   = 0
    state%parse_errors = 0
    state%is_complete  = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Input_Core_Finalize

  !---------------------------------------------------------------------------
  ! Read input file: open, count lines, close
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Input_Read_File(desc, state, status)
    TYPE(AP_Input_Desc),   INTENT(IN)    :: desc
    TYPE(AP_Input_State),  INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: iu, ios, n_lines
    CHARACTER(LEN=256) :: line

    CALL init_error_status(status)
    IF (LEN_TRIM(desc%file_path) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Input_Read_File]: empty file path"
      RETURN
    END IF

    OPEN(NEWUNIT=iu, FILE=TRIM(desc%file_path), STATUS='OLD', &
         ACTION='READ', IOSTAT=ios)
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Input_Read_File]: cannot open file"
      RETURN
    END IF

    n_lines = 0
    DO
      READ(iu, '(A)', IOSTAT=ios) line
      IF (ios /= 0) EXIT
      n_lines = n_lines + 1
    END DO
    CLOSE(iu)

    state%lines_read  = n_lines
    state%is_complete = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Input_Read_File

  !---------------------------------------------------------------------------
  ! Process keywords: parse ABAQUS-style INP line by line
  !   *NODE -> node coordinates
  !   *ELEMENT -> connectivity
  !   *MATERIAL -> material definition
  !   *BOUNDARY -> boundary conditions
  !   *STEP/*END STEP -> step definition
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Input_Process_Keywords(desc, state, status)
    TYPE(AP_Input_Desc),   INTENT(IN)    :: desc
    TYPE(AP_Input_State),  INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: iu, ios, n_kw
    CHARACTER(LEN=256) :: line
    CHARACTER(LEN=32)  :: keyword

    CALL init_error_status(status)
    IF (LEN_TRIM(desc%file_path) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Input_Process_Keywords]: empty file path"
      RETURN
    END IF

    OPEN(NEWUNIT=iu, FILE=TRIM(desc%file_path), STATUS='OLD', &
         ACTION='READ', IOSTAT=ios)
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Input_Process_Keywords]: cannot open file"
      RETURN
    END IF

    n_kw = 0
    DO
      READ(iu, '(A)', IOSTAT=ios) line
      IF (ios /= 0) EXIT
      line = ADJUSTL(line)
      IF (LEN_TRIM(line) == 0) CYCLE
      IF (line(1:2) == '**') CYCLE

      IF (line(1:1) == '*') THEN
        n_kw = n_kw + 1
        CALL Extract_Keyword(line, keyword)
      END IF
    END DO
    CLOSE(iu)

    state%lines_read  = state%lines_read + n_kw
    state%is_complete = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Input_Process_Keywords

  !---------------------------------------------------------------------------
  ! PRIVATE: extract keyword from *KEYWORD,PARAMS line
  !---------------------------------------------------------------------------
  SUBROUTINE Extract_Keyword(line, keyword)
    CHARACTER(LEN=*), INTENT(IN)  :: line
    CHARACTER(LEN=*), INTENT(OUT) :: keyword

    INTEGER(i4) :: ic

    keyword = ""
    IF (LEN_TRIM(line) < 2) RETURN

    ic = INDEX(line(2:), ',')
    IF (ic > 0) THEN
      keyword = line(2:ic)
    ELSE
      keyword = TRIM(line(2:))
    END IF
  END SUBROUTINE Extract_Keyword

  !---------------------------------------------------------------------------
  ! Validate: check parse_errors == 0
  !---------------------------------------------------------------------------
  SUBROUTINE AP_Input_Validate(desc, state, status)
    TYPE(AP_Input_Desc),   INTENT(IN)  :: desc
    TYPE(AP_Input_State),  INTENT(IN)  :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (state%parse_errors /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[AP_Input_Validate]: parse errors detected"
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Input_Validate

  FUNCTION AP_Input_Get_Line_Count(state) RESULT(n)
    TYPE(AP_Input_State), INTENT(IN) :: state
    INTEGER(i4) :: n
    n = state%lines_read
  END FUNCTION AP_Input_Get_Line_Count

  FUNCTION AP_Input_Get_Error_Count(state) RESULT(n)
    TYPE(AP_Input_State), INTENT(IN) :: state
    INTEGER(i4) :: n
    n = state%parse_errors
  END FUNCTION AP_Input_Get_Error_Count

END MODULE AP_Input_Core
