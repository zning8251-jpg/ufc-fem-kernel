!===============================================================================
! MODULE: AP_InpDomain
! LAYER:  L6_AP
! DOMAIN: Input/Parser
! ROLE:   Domain ?input file parsing domain container
! BRIEF:  Reads ABAQUS-format .inp files, validates syntax, builds command
!         queue for model construction. Maps keywords to L3_MD domain writers.
!
! Process phases:
!   P0: AP_Input_Domain_Init / AP_Input_Domain_Finalize
!   P1: AP_Input_Parse / AP_Input_MapKeywords
!===============================================================================
! NAMING NOTE (UFC_naming_v3.0): LEGACY duplicate MODULE: AP_Inp is also defined in AP_Inp.f90. This file provides domain-specific parser logic. Retained as-is.
MODULE AP_InpDomain
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Inp_Def, ONLY: ParsedKeywordEntry, ParsedCommandEntry, &
                            AP_INPUT_KEYWORD_ID_INVALID, AP_INPUT_CMD_ID_INVALID, &
                            AP_Inp_AddKW_Arg, AP_Inp_AddCmd_Arg
  IMPLICIT NONE
  PRIVATE

  ! --- Parser state enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_PARSE_NOT_STARTED = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_PARSE_IN_PROGRESS = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_PARSE_COMPLETE    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_PARSE_FAILED      = 3_i4

  TYPE, PUBLIC :: AP_Input_State
    INTEGER(i4) :: parseStatus     = AP_PARSE_NOT_STARTED
    INTEGER(i4) :: totalKeywords   = 0_i4
    INTEGER(i4) :: parsedKeywords  = 0_i4
    INTEGER(i4) :: nParseErrors    = 0_i4
    INTEGER(i4) :: nParseWarnings  = 0_i4
    INTEGER(i4) :: totalDataLines  = 0_i4
    INTEGER(i4) :: currentLine     = 0_i4
    REAL(wp)    :: parseTime       = 0.0_wp  ! wall-clock for parsing
  END TYPE AP_Input_State

  TYPE, PUBLIC :: AP_Input_Ctrl
    CHARACTER(LEN=512) :: inputFilePath  = ' '
    CHARACTER(LEN=256) :: jobName        = ' '
    INTEGER(i4)        :: validationLevel = 2_i4  ! 0=none, 1=basic, 2=full
    LOGICAL            :: echoInput      = .FALSE.  ! echo parsed input
    LOGICAL            :: strictMode     = .FALSE.  ! fail on warnings
    LOGICAL            :: continueOnError = .FALSE. ! skip bad keywords
  END TYPE AP_Input_Ctrl

  TYPE, PUBLIC :: AP_Input_Domain
    TYPE(AP_Input_State) :: state
    TYPE(AP_Input_Ctrl)  :: ctrl
    ! Flat domain storage (index tree + flat)
    TYPE(ParsedKeywordEntry), ALLOCATABLE :: parsed_keywords(:)
    TYPE(ParsedCommandEntry),  ALLOCATABLE :: parsed_commands(:)
    INTEGER(i4) :: n_keywords = 0_i4
    INTEGER(i4) :: n_commands = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: ParseKeyword
    PROCEDURE :: ValidateSyntax
    PROCEDURE :: GetSummary
    PROCEDURE :: AddParsedKeyword
    PROCEDURE :: AddParsedCommand
    PROCEDURE :: GetKeywordById
    PROCEDURE :: GetCmdById
  END TYPE AP_Input_Domain

CONTAINS

  SUBROUTINE AP_Input_Domain_Finalize(this)
    CLASS(AP_Input_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%state = AP_Input_State()
    IF (ALLOCATED(this%parsed_keywords)) DEALLOCATE(this%parsed_keywords)
    IF (ALLOCATED(this%parsed_commands)) DEALLOCATE(this%parsed_commands)
    this%n_keywords = 0_i4
    this%n_commands = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE AP_Input_Domain_Finalize

  SUBROUTINE AP_Input_Domain_Init(this, status)
    CLASS(AP_Input_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctrl = AP_Input_Ctrl()
    this%n_keywords = 0_i4
    this%n_commands = 0_i4
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Input_Domain_Init

  !====================================================================
  ! AP_Input_Domain_ParseKeyword
  ! Parse a single keyword and update parse state
  !====================================================================
  SUBROUTINE AP_Input_Domain_ParseKeyword(this, keyword, status)
    CLASS(AP_Input_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),       INTENT(IN)    :: keyword
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Input domain not initialized"
      RETURN
    END IF

    ! Validate keyword (simplified - would parse keyword in production)
    IF (LEN_TRIM(keyword) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Keyword is empty"
      RETURN
    END IF

    ! Update parse state
    this%state%parsedKeywords = this%state%parsedKeywords + 1_i4
    this%state%parseStatus = AP_PARSE_IN_PROGRESS

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Input_Domain_ParseKeyword

  !====================================================================
  ! AP_Input_Domain_ValidateSyntax
  ! Validate syntax of parsed input
  !====================================================================
  SUBROUTINE AP_Input_Domain_ValidateSyntax(this, isValid, status)
    CLASS(AP_Input_Domain), INTENT(INOUT) :: this
    LOGICAL,                INTENT(OUT)   :: isValid
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    isValid = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Input domain not initialized"
      RETURN
    END IF

    ! Validate syntax (simplified - would validate in production)
    ! Check if parsing is complete
    IF (this%state%parseStatus == AP_PARSE_COMPLETE) THEN
      ! Check for errors
      IF (this%state%nParseErrors == 0) THEN
        isValid = .TRUE.
      END IF
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Input_Domain_ValidateSyntax

  !====================================================================
  ! AP_Input_Domain_GetSummary
  ! Get summary string of input domain
  !====================================================================
  SUBROUTINE AP_Input_Domain_GetSummary(this, summary, status)
    CLASS(AP_Input_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),     INTENT(OUT) :: summary
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Input domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,I0,A,I0,A,ES10.3)') &
      "Input Summary: TotalKeywords=", this%state%totalKeywords, &
      ", Parsed=", this%state%parsedKeywords, &
      ", Errors=", this%state%nParseErrors, &
      ", Warnings=", this%state%nParseWarnings, &
      ", DataLines=", this%state%totalDataLines, &
      ", CurrentLine=", this%state%currentLine, &
      ", ParseTime=", this%state%parseTime

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Input_Domain_GetSummary

  !====================================================================
  ! AP_Input_Domain_AddParsedKeyword  [Arg refactored ?Phase 3F]
  ! Add parsed keyword to flat domain (index tree + flat)
  ! Signature: (this, arg, status) ?arg = AP_Inp_AddKW_Arg
  !====================================================================
  SUBROUTINE AP_Input_Domain_AddParsedKeyword(this, arg, status)
    CLASS(AP_Input_Domain), INTENT(INOUT) :: this
    TYPE(AP_Inp_AddKW_Arg), INTENT(IN)   :: arg
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    TYPE(ParsedKeywordEntry), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, cap

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Input domain not initialized"
      RETURN
    END IF

    n = this%n_keywords + 1_i4
    IF (.NOT. ALLOCATED(this%parsed_keywords)) THEN
      cap = MAX(64_i4, n)
      ALLOCATE(this%parsed_keywords(cap))
    ELSE IF (n > SIZE(this%parsed_keywords)) THEN
      cap = SIZE(this%parsed_keywords) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_keywords) = this%parsed_keywords(1:this%n_keywords)
      CALL MOVE_ALLOC(tmp, this%parsed_keywords)
    END IF

    this%parsed_keywords(n)%keyword_id  = arg%keyword_id
    this%parsed_keywords(n)%line_number = arg%line_number
    this%parsed_keywords(n)%name        = arg%name(1:MIN(32, LEN_TRIM(arg%name)))
    this%parsed_keywords(n)%category    = arg%category
    this%parsed_keywords(n)%has_data    = arg%has_data
    this%n_keywords = n
    this%state%parsedKeywords = this%state%parsedKeywords + 1_i4
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Input_Domain_AddParsedKeyword

  !====================================================================
  ! AP_Input_Domain_AddParsedCommand  [Arg refactored ?Phase 3F]
  ! Add parsed command to flat domain
  ! Signature: (this, arg, status) ?arg = AP_Inp_AddCmd_Arg
  !====================================================================
  SUBROUTINE AP_Input_Domain_AddParsedCommand(this, arg, status)
    CLASS(AP_Input_Domain), INTENT(INOUT) :: this
    TYPE(AP_Inp_AddCmd_Arg), INTENT(IN)   :: arg
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    TYPE(ParsedCommandEntry), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, cap

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Input domain not initialized"
      RETURN
    END IF

    n = this%n_commands + 1_i4
    IF (.NOT. ALLOCATED(this%parsed_commands)) THEN
      cap = MAX(64_i4, n)
      ALLOCATE(this%parsed_commands(cap))
    ELSE IF (n > SIZE(this%parsed_commands)) THEN
      cap = SIZE(this%parsed_commands) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_commands) = this%parsed_commands(1:this%n_commands)
      CALL MOVE_ALLOC(tmp, this%parsed_commands)
    END IF

    this%parsed_commands(n)%cfg%id          = arg%cmd_id      ! canonical (Phase D)
    this%parsed_commands(n)%cmd_id      = arg%cmd_id      ! @deprecated alias
    this%parsed_commands(n)%keyword_idx = arg%keyword_idx
    this%parsed_commands(n)%line        = arg%line_number  ! canonical (Phase D)
    this%parsed_commands(n)%line_number = arg%line_number  ! @deprecated alias
    this%parsed_commands(n)%name        = arg%name(1:MIN(16, LEN_TRIM(arg%name)))
    this%parsed_commands(n)%opt         = arg%opt(1:MIN(64, LEN_TRIM(arg%opt)))
    this%parsed_commands(n)%params      = arg%params
    this%parsed_commands(n)%param_str   = arg%param_str(1:MIN(256, LEN_TRIM(arg%param_str)))
    this%n_commands = n
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Input_Domain_AddParsedCommand

  !====================================================================
  ! AP_Input_Domain_GetKeywordById
  ! Get parsed keyword by index (O(1))
  !====================================================================
  SUBROUTINE AP_Input_Domain_GetKeywordById(this, idx, entry, found)
    CLASS(AP_Input_Domain), INTENT(IN)  :: this
    INTEGER(i4),            INTENT(IN)  :: idx
    TYPE(ParsedKeywordEntry), INTENT(OUT) :: entry
    LOGICAL,                INTENT(OUT) :: found

    found = .FALSE.
    IF (.NOT. this%initialized) RETURN
    IF (idx < 1) RETURN
    IF (.NOT. ALLOCATED(this%parsed_keywords)) RETURN
    IF (idx > this%n_keywords) RETURN
    entry = this%parsed_keywords(idx)
    found = .TRUE.

  END SUBROUTINE AP_Input_Domain_GetKeywordById

  !====================================================================
  ! AP_Input_Domain_GetCmdById
  ! Get parsed command by index (O(1))
  !====================================================================
  SUBROUTINE AP_Input_Domain_GetCmdById(this, idx, entry, found)
    CLASS(AP_Input_Domain), INTENT(IN)  :: this
    INTEGER(i4),            INTENT(IN)  :: idx
    TYPE(ParsedCommandEntry), INTENT(OUT) :: entry
    LOGICAL,                INTENT(OUT) :: found

    found = .FALSE.
    IF (.NOT. this%initialized) RETURN
    IF (idx < 1) RETURN
    IF (.NOT. ALLOCATED(this%parsed_commands)) RETURN
    IF (idx > this%n_commands) RETURN
    entry = this%parsed_commands(idx)
    found = .TRUE.

  END SUBROUTINE AP_Input_Domain_GetCmdById

END MODULE AP_InpDomain
