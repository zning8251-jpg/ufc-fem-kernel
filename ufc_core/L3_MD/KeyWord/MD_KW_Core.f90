!===================================================================
! MODULE:  MD_KW_Core
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Core
! BRIEF:   Core keyword operations: register, parse, match, extract.
!          Uses all four types from MD_KeyWord_Def.
!===================================================================
MODULE MD_KW_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_KW_Def,    ONLY: MD_KW_Desc, MD_KW_State, &
                           MD_KW_Algo, MD_KW_Ctx, &
                           MD_KeyWordEntry, MD_KW_MAX_KEYWORDS, &
                           MD_KW_NAME_LEN, MD_KW_LINE_LEN
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_KeyWord_Core_Init
  PUBLIC :: MD_KeyWord_Core_Finalize
  PUBLIC :: MD_KeyWord_Register
  PUBLIC :: MD_KeyWord_Parse_Line
  PUBLIC :: MD_KeyWord_Match
  PUBLIC :: MD_KeyWord_Get_Int_Param
  PUBLIC :: MD_KeyWord_Get_Real_Param
  PUBLIC :: MD_KeyWord_Is_DataLine
  PUBLIC :: MD_KeyWord_Get_Current

CONTAINS

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KeyWord_Core_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize keyword parsing subsystem
  !-----------------------------------------------------------------
  SUBROUTINE MD_KeyWord_Core_Init(desc, state, algo, ctx, status)
    TYPE(MD_KW_Desc),     INTENT(INOUT) :: desc                 ! [inout] Keyword registry
    TYPE(MD_KW_State),    INTENT(INOUT) :: state                ! [inout] Parser state
    TYPE(MD_KW_Algo),     INTENT(IN)    :: algo                 ! [in]    Parse config
    TYPE(MD_KW_Ctx),      INTENT(OUT)   :: ctx                  ! [out]   Parse context
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    CALL init_error_status(status)
    desc%n_keywords       = 0
    state%current_keyword = ""
    state%current_line    = 0
    state%in_data_block   = .FALSE.
    state%parse_errors    = 0
    ctx%file_unit         = 0
    ctx%total_lines       = 0
    ctx%eof_reached       = .FALSE.
    status%status_code    = IF_STATUS_OK
  END SUBROUTINE MD_KeyWord_Core_Init

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KeyWord_Core_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Finalize keyword parsing subsystem
  !-----------------------------------------------------------------
  SUBROUTINE MD_KeyWord_Core_Finalize(desc, state, ctx, status)
    TYPE(MD_KW_Desc),     INTENT(INOUT) :: desc                 ! [inout]
    TYPE(MD_KW_State),    INTENT(INOUT) :: state                ! [inout]
    TYPE(MD_KW_Ctx),      INTENT(INOUT) :: ctx                  ! [inout]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    CALL init_error_status(status)
    desc%n_keywords       = 0
    state%current_keyword = ""
    state%current_line    = 0
    state%in_data_block   = .FALSE.
    state%parse_errors    = 0
    ctx%eof_reached       = .TRUE.
    status%status_code    = IF_STATUS_OK
  END SUBROUTINE MD_KeyWord_Core_Finalize

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KeyWord_Register
  ! PHASE:      P0
  ! PURPOSE:    Register a keyword in the descriptor table
  !-----------------------------------------------------------------
  SUBROUTINE MD_KeyWord_Register(desc, name, n_params, has_data_lines, status)
    TYPE(MD_KW_Desc),     INTENT(INOUT) :: desc                 ! [inout]
    CHARACTER(LEN=*),      INTENT(IN)   :: name                 ! [in]
    INTEGER(i4),           INTENT(IN)   :: n_params             ! [in]
    LOGICAL,               INTENT(IN)   :: has_data_lines       ! [in]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    INTEGER(i4) :: idx

    CALL init_error_status(status)
    IF (desc%n_keywords >= MD_KW_MAX_KEYWORDS) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_KeyWord_Register]: max keywords exceeded"
      RETURN
    END IF

    desc%n_keywords = desc%n_keywords + 1
    idx = desc%n_keywords

    desc%keywords(idx)%name           = name
    desc%keywords(idx)%n_params       = n_params
    desc%keywords(idx)%has_data_lines = has_data_lines
    desc%keywords(idx)%valid          = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KeyWord_Register

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KeyWord_Parse_Line
  ! PHASE:      P1
  ! PURPOSE:    Parse one INP line, identify keyword or data
  !-----------------------------------------------------------------
  SUBROUTINE MD_KeyWord_Parse_Line(desc, state, line, status)
    TYPE(MD_KW_Desc),     INTENT(IN)    :: desc                 ! [in]
    TYPE(MD_KW_State),    INTENT(INOUT) :: state                ! [inout]
    CHARACTER(LEN=*),      INTENT(IN)   :: line                 ! [in]
    TYPE(ErrorStatusType), INTENT(OUT)  :: status

    INTEGER(i4) :: i
    CHARACTER(LEN=MD_KW_NAME_LEN) :: kw_name

    CALL init_error_status(status)
    state%current_line = state%current_line + 1

    IF (LEN_TRIM(line) == 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (line(1:1) == '*') THEN
      kw_name = ADJUSTL(line(2:))
      state%in_data_block = .FALSE.

      DO i = 1, desc%n_keywords
        IF (desc%keywords(i)%valid .AND. &
            TRIM(desc%keywords(i)%name) == TRIM(kw_name)) THEN
          state%current_keyword = TRIM(kw_name)
          IF (desc%keywords(i)%has_data_lines) THEN
            state%in_data_block = .TRUE.
          END IF
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
      END DO

      state%parse_errors = state%parse_errors + 1
      status%status_code = IF_STATUS_INVALID
      status%message = "[MD_KeyWord_Parse_Line]: unknown keyword"
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KeyWord_Parse_Line

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KeyWord_Match
  ! PHASE:      P0
  ! PURPOSE:    Check if a keyword name exists in registry
  !-----------------------------------------------------------------
  SUBROUTINE MD_KeyWord_Match(desc, name, found, status)
    TYPE(MD_KW_Desc),     INTENT(IN)  :: desc                   ! [in]
    CHARACTER(LEN=*),      INTENT(IN) :: name                   ! [in]
    LOGICAL,               INTENT(OUT) :: found                 ! [out]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    found = .FALSE.
    DO i = 1, desc%n_keywords
      IF (desc%keywords(i)%valid .AND. &
          TRIM(desc%keywords(i)%name) == TRIM(name)) THEN
        found = .TRUE.
        EXIT
      END IF
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KeyWord_Match

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KeyWord_Get_Int_Param
  ! PHASE:      P1
  ! PURPOSE:    Extract integer from comma-separated data line
  !-----------------------------------------------------------------
  SUBROUTINE MD_KeyWord_Get_Int_Param(line, pos, value, status)
    CHARACTER(LEN=*),      INTENT(IN)  :: line                  ! [in]
    INTEGER(i4),           INTENT(IN)  :: pos                   ! [in]
    INTEGER(i4),           INTENT(OUT) :: value                 ! [out]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(LEN=MD_KW_LINE_LEN) :: work
    INTEGER(i4) :: i, cnt, start, end_pos, ios

    CALL init_error_status(status)
    value = 0
    work  = ADJUSTL(line)

    cnt   = 0
    start = 1
    DO i = 1, LEN_TRIM(work)
      IF (work(i:i) == ',' .OR. i == LEN_TRIM(work)) THEN
        cnt = cnt + 1
        IF (i == LEN_TRIM(work) .AND. work(i:i) /= ',') THEN
          end_pos = i
        ELSE
          end_pos = i - 1
        END IF
        IF (cnt == pos) THEN
          READ(work(start:end_pos), *, IOSTAT=ios) value
          IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "[MD_KeyWord_Get_Int_Param]: parse error"
            RETURN
          END IF
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
        start = i + 1
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
    status%message = "[MD_KeyWord_Get_Int_Param]: position not found"
  END SUBROUTINE MD_KeyWord_Get_Int_Param

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KeyWord_Get_Real_Param
  ! PHASE:      P1
  ! PURPOSE:    Extract real from comma-separated data line
  !-----------------------------------------------------------------
  SUBROUTINE MD_KeyWord_Get_Real_Param(line, pos, value, status)
    CHARACTER(LEN=*),      INTENT(IN)  :: line                  ! [in]
    INTEGER(i4),           INTENT(IN)  :: pos                   ! [in]
    REAL(wp),              INTENT(OUT) :: value                 ! [out]
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CHARACTER(LEN=MD_KW_LINE_LEN) :: work
    INTEGER(i4) :: i, cnt, start, end_pos, ios

    CALL init_error_status(status)
    value = 0.0_wp
    work  = ADJUSTL(line)

    cnt   = 0
    start = 1
    DO i = 1, LEN_TRIM(work)
      IF (work(i:i) == ',' .OR. i == LEN_TRIM(work)) THEN
        cnt = cnt + 1
        IF (i == LEN_TRIM(work) .AND. work(i:i) /= ',') THEN
          end_pos = i
        ELSE
          end_pos = i - 1
        END IF
        IF (cnt == pos) THEN
          READ(work(start:end_pos), *, IOSTAT=ios) value
          IF (ios /= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "[MD_KeyWord_Get_Real_Param]: parse error"
            RETURN
          END IF
          status%status_code = IF_STATUS_OK
          RETURN
        END IF
        start = i + 1
      END IF
    END DO

    status%status_code = IF_STATUS_INVALID
    status%message = "[MD_KeyWord_Get_Real_Param]: position not found"
  END SUBROUTINE MD_KeyWord_Get_Real_Param

  !-----------------------------------------------------------------
  ! FUNCTION:  MD_KeyWord_Is_DataLine
  ! PHASE:     P1
  ! PURPOSE:   Query whether current state is inside a data block
  !-----------------------------------------------------------------
  FUNCTION MD_KeyWord_Is_DataLine(state) RESULT(is_data)
    TYPE(MD_KW_State), INTENT(IN) :: state                      ! [in]
    LOGICAL :: is_data
    is_data = state%in_data_block
  END FUNCTION MD_KeyWord_Is_DataLine

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KeyWord_Get_Current
  ! PHASE:      P1
  ! PURPOSE:    Get name of currently active keyword
  !-----------------------------------------------------------------
  SUBROUTINE MD_KeyWord_Get_Current(state, keyword)
    TYPE(MD_KW_State), INTENT(IN)  :: state                     ! [in]
    CHARACTER(LEN=*),  INTENT(OUT) :: keyword                   ! [out]
    keyword = state%current_keyword
  END SUBROUTINE MD_KeyWord_Get_Current

END MODULE MD_KW_Core
