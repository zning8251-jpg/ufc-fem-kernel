!===================================================================
! MODULE:  MD_KeyWord_Domain
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Domain
! BRIEF:   Domain container for keyword parsing system.
!          Aggregates Desc/State/Algo/Ctx for INP file parsing.
!          Standalone domain (not on MD_L3_LayerContainer).
!===================================================================
MODULE MD_KeyWord_Domain
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_KW_Def,    ONLY: KW_ASTNodeType, KW_LexerStateType, &
                           KW_ParserStateType, &
                           KW_MAX_NAME_LEN, KW_MAX_PARAMS
  USE MD_KW,        ONLY: KW_Coverage_Report, KW_Priority_Check, &
                           KW_Audit_P0_Must, KW_Generate_Report
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_MAX_KEYWORDS  = 500_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_MAX_AST_NODES = 10000_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_MAX_TOKENS    = 50000_i4


  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_KeywordDef_Desc
  ! KIND:  Desc
  ! DESC:  Single keyword definition (frozen after registration)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_KeywordDef_Desc
    CHARACTER(LEN=KW_MAX_NAME_LEN) :: name = ""                 ! [in] Keyword name
    INTEGER(i4)                    :: category = 0_i4           ! [in] KW_CAT_*
    INTEGER(i4)                    :: priority = 0_i4           ! [in] P0/P1/P2
    INTEGER(i4)                    :: n_params = 0_i4           ! [in] Param count
    LOGICAL                        :: has_data_lines = .FALSE.  ! [in] Data lines?
    CHARACTER(LEN=64)              :: target_domain = ""        ! [in] Target domain
  END TYPE MD_KW_KeywordDef_Desc



  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_DomainAlgo
  ! KIND:  Algo
  ! DESC:  Parsing algorithm parameters (frozen after setup)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_DomainAlgo
    LOGICAL     :: strict_mode    = .TRUE.                      ! [in] Stop on first error
    LOGICAL     :: case_sensitive = .FALSE.                     ! [in] Case sensitivity
    INTEGER(i4) :: max_errors     = 100_i4                      ! [in] Max errors
    LOGICAL     :: audit_coverage = .TRUE.                      ! [in] Enable coverage audit
    INTEGER(i4) :: parse_priority = 0_i4                        ! [in] Current priority
  END TYPE MD_KW_DomainAlgo



  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_DomainCtx
  ! KIND:  Ctx
  ! DESC:  Transient parsing context (per-parse operation)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_DomainCtx
    INTEGER(i4)   :: current_line_num  = 0_i4                   ! [inout] Current line
    INTEGER(i4)   :: current_col_num   = 0_i4                   ! [inout] Current column
    INTEGER(i4)   :: tokens_parsed     = 0_i4                   ! [out]   Tokens parsed
    INTEGER(i4)   :: keywords_parsed   = 0_i4                   ! [out]   Keywords parsed
    INTEGER(i4)   :: ast_nodes_created = 0_i4                   ! [out]   AST nodes
    CHARACTER(LEN=64) :: current_keyword = ""                   ! [inout] Current keyword
    LOGICAL       :: in_data_block     = .FALSE.                ! [inout] In data block
    INTEGER(i4)   :: last_error_line   = 0_i4                   ! [out]   Last error line
  END TYPE MD_KW_DomainCtx



  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_ParseState
  ! KIND:  State
  ! DESC:  Parser state tracking (updated during parse, frozen after)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_ParseState
    INTEGER(i4) :: n_keywords_parsed = 0_i4                     ! [out] Keywords parsed
    INTEGER(i4) :: n_ast_nodes       = 0_i4                     ! [out] AST node count
    INTEGER(i4) :: n_errors          = 0_i4                     ! [out] Error count
    INTEGER(i4) :: n_warnings        = 0_i4                     ! [out] Warning count
    LOGICAL     :: parse_complete    = .FALSE.                  ! [out] Parse done?
    TYPE(KW_Coverage_Report) :: coverage                        ! [out] Coverage report
  END TYPE MD_KW_ParseState



  !-----------------------------------------------------------------
  ! TYPE:  MD_KeyWord_Domain
  ! KIND:  Ctx (domain container)
  ! DESC:  Top-level domain container aggregating all four types
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KeyWord_Domain
    ! Desc (Write-Once after parse)
    TYPE(MD_KW_KeywordDef_Desc), ALLOCATABLE   :: keywords(:)            ! [out]
    TYPE(KW_ASTNodeType), ALLOCATABLE :: ast_nodes(:)           ! [out]
    INTEGER(i4)                       :: n_keywords  = 0_i4     ! [out]
    INTEGER(i4)                       :: n_ast_nodes = 0_i4     ! [out]
    INTEGER(i4)                       :: root_node_idx = 0_i4   ! [out]

    ! State (Parse phase only)
    TYPE(MD_KW_ParseState)               :: state                  ! [inout]

    ! Algo (Parse configuration)
    TYPE(MD_KW_DomainAlgo)                      :: algo                   ! [in]

    ! Ctx (transient, not stored)
    TYPE(KW_LexerStateType)           :: lexer                  ! [inout]
    TYPE(KW_ParserStateType)          :: parser                 ! [inout]

    ! Internal
    LOGICAL                           :: initialized  = .FALSE. ! [out]
    LOGICAL                           :: parse_frozen = .FALSE. ! [out]
  CONTAINS
    PROCEDURE :: Init            => MD_KW_Domain_Init
    PROCEDURE :: Finalize        => MD_KW_Domain_Finalize
    PROCEDURE :: RegisterKeyword => MD_KW_Domain_RegisterKW
    PROCEDURE :: Parse           => MD_KW_Domain_Parse
    PROCEDURE :: GetKeyword      => MD_KW_Domain_GetKW
    PROCEDURE :: GetKeywordByName => MD_KW_Domain_GetKWByName
    PROCEDURE :: GetASTRoot      => MD_KW_Domain_GetASTRoot
    PROCEDURE :: AuditCoverage   => MD_KW_Domain_AuditCoverage
    PROCEDURE :: GetSummary      => MD_KW_Domain_GetSummary
  END TYPE MD_KeyWord_Domain


  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_GetSummary_Arg
  ! KIND:  Arg
  ! DESC:  Argument bundle for GetSummary
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""                       ! [out]
    TYPE(ErrorStatusType) :: status                             ! [out]
  END TYPE MD_KW_GetSummary_Arg


CONTAINS

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize keyword domain container
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_Init(this, max_keywords, max_ast_nodes, status)
    CLASS(MD_KeyWord_Domain), INTENT(INOUT) :: this             ! [inout]
    INTEGER(i4),              INTENT(IN)    :: max_keywords     ! [in]
    INTEGER(i4),              INTENT(IN)    :: max_ast_nodes    ! [in]
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    IF (max_keywords < 1_i4 .OR. max_ast_nodes < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    ALLOCATE(this%keywords(max_keywords))
    ALLOCATE(this%ast_nodes(max_ast_nodes))
    this%n_keywords   = 0_i4
    this%n_ast_nodes  = 0_i4
    this%state        = MD_KW_ParseState()
    this%algo         = MD_KW_DomainAlgo()
    this%initialized  = .TRUE.
    this%parse_frozen = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_Domain_Init

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Release all keyword and AST resources
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_Finalize(this)
    CLASS(MD_KeyWord_Domain), INTENT(INOUT) :: this             ! [inout]

    IF (.NOT. this%initialized) RETURN

    IF (ALLOCATED(this%keywords))  DEALLOCATE(this%keywords)
    IF (ALLOCATED(this%ast_nodes)) DEALLOCATE(this%ast_nodes)

    this%n_keywords   = 0_i4
    this%n_ast_nodes  = 0_i4
    this%state        = MD_KW_ParseState()
    this%initialized  = .FALSE.
    this%parse_frozen = .FALSE.
  END SUBROUTINE MD_KW_Domain_Finalize

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_RegisterKW
  ! PHASE:      P0
  ! PURPOSE:    Register a keyword definition during setup phase
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_RegisterKW(this, kw_def, status)
    CLASS(MD_KeyWord_Domain), INTENT(INOUT) :: this             ! [inout]
    TYPE(MD_KW_KeywordDef_Desc),       INTENT(IN)    :: kw_def           ! [in]
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain not initialized"
      RETURN
    END IF

    IF (this%parse_frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain already frozen"
      RETURN
    END IF

    this%n_keywords = this%n_keywords + 1_i4
    IF (this%n_keywords > SIZE(this%keywords)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Maximum keyword capacity exceeded"
      RETURN
    END IF

    this%keywords(this%n_keywords) = kw_def
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_Domain_RegisterKW

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_Parse
  ! PHASE:      P1
  ! PURPOSE:    Parse INP file content into AST
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_Parse(this, inp_lines, n_lines, status)
    CLASS(MD_KeyWord_Domain), INTENT(INOUT) :: this             ! [inout]
    CHARACTER(LEN=*),         INTENT(IN)    :: inp_lines(:)     ! [in]
    INTEGER(i4),              INTENT(IN)    :: n_lines          ! [in]
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    INTEGER(i4) :: i
    TYPE(MD_KW_DomainCtx) :: ctx

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain not initialized"
      RETURN
    END IF

    IF (this%parse_frozen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain already parsed and frozen"
      RETURN
    END IF

    ! Reset parser state
    this%state = MD_KW_ParseState()
    ctx = MD_KW_DomainCtx()

    ! Lexical analysis + parsing loop
    DO i = 1, n_lines
      ctx%current_line_num = i
      ! TODO: Implement lexer -> parser -> AST pipeline
      this%state%n_keywords_parsed = this%state%n_keywords_parsed + 1_i4
    END DO

    this%state%parse_complete = .TRUE.
    this%parse_frozen = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_Domain_Parse

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_GetKW
  ! PHASE:      P0
  ! PURPOSE:    Get keyword definition by name
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_GetKW(this, name, kw_def, found, status)
    CLASS(MD_KeyWord_Domain), INTENT(IN)  :: this               ! [in]
    CHARACTER(LEN=*),         INTENT(IN)  :: name               ! [in]
    TYPE(MD_KW_KeywordDef_Desc),       INTENT(OUT) :: kw_def             ! [out]
    LOGICAL,                  INTENT(OUT) :: found              ! [out]
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    found = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain not initialized"
      RETURN
    END IF

    DO i = 1, this%n_keywords
      IF (TRIM(this%keywords(i)%name) == TRIM(name)) THEN
        kw_def = this%keywords(i)
        found = .TRUE.
        EXIT
      END IF
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_Domain_GetKW

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_GetASTRoot
  ! PHASE:      P0
  ! PURPOSE:    Get root node index of parsed AST
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_GetASTRoot(this, root_idx, status)
    CLASS(MD_KeyWord_Domain), INTENT(IN)  :: this               ! [in]
    INTEGER(i4),              INTENT(OUT) :: root_idx           ! [out]
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain not initialized"
      RETURN
    END IF

    IF (.NOT. this%state%parse_complete) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Parsing not yet complete"
      RETURN
    END IF

    root_idx = this%root_node_idx
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_Domain_GetASTRoot

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_AuditCoverage
  ! PHASE:      P0
  ! PURPOSE:    Audit P0/P1/P2 keyword coverage
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_AuditCoverage(this, covered_keywords, status)
    CLASS(MD_KeyWord_Domain), INTENT(INOUT) :: this             ! [inout]
    CHARACTER(LEN=*),         INTENT(IN)    :: covered_keywords(:)  ! [in]
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain not initialized"
      RETURN
    END IF

    CALL KW_Audit_P0_Must(covered_keywords, this%state%coverage, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL KW_Generate_Report(this%state%coverage)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_Domain_AuditCoverage

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_GetKWByName
  ! PHASE:      P0
  ! PURPOSE:    Get keyword definition by name (linear search)
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_GetKWByName(this, name, kw_def, found, status)
    CLASS(MD_KeyWord_Domain), INTENT(IN)  :: this               ! [in]
    CHARACTER(LEN=*),         INTENT(IN)  :: name               ! [in]
    TYPE(MD_KW_KeywordDef_Desc),       INTENT(OUT) :: kw_def             ! [out]
    LOGICAL,                  INTENT(OUT) :: found              ! [out]
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    found  = .FALSE.
    kw_def = MD_KW_KeywordDef_Desc()

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain not initialized"
      RETURN
    END IF

    DO i = 1, this%n_keywords
      IF (TRIM(this%keywords(i)%name) == TRIM(name)) THEN
        found  = .TRUE.
        kw_def = this%keywords(i)
        EXIT
      END IF
    END DO

    IF (found) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') "Keyword '", TRIM(name), "' not found"
    END IF
  END SUBROUTINE MD_KW_Domain_GetKWByName

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_Domain_GetSummary
  ! PHASE:      P0
  ! PURPOSE:    Get domain summary string (Arg wrapper)
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_Domain_GetSummary(this, arg)
    CLASS(MD_KeyWord_Domain),        INTENT(IN)    :: this      ! [in]
    TYPE(MD_KW_GetSummary_Arg), INTENT(INOUT) :: arg       ! [inout]
    CALL MD_KW_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE MD_KW_Domain_GetSummary

  SUBROUTINE MD_KW_GetSummary_Impl(this, summary, status)
    CLASS(MD_KeyWord_Domain), INTENT(IN)  :: this               ! [in]
    CHARACTER(LEN=512),       INTENT(OUT) :: summary            ! [out]
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "KeyWord domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,L1,A,I0,A,I0)') &
      "KeyWord Summary: Keywords=", this%n_keywords, &
      ", ASTNodes=", this%n_ast_nodes, &
      ", ParseComplete=", this%state%parse_complete, &
      ", Errors=", this%state%n_errors, &
      ", Warnings=", this%state%n_warnings

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_KW_GetSummary_Impl

END MODULE MD_KeyWord_Domain
