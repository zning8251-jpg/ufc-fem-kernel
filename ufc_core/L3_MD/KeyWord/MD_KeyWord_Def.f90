!===================================================================
! MODULE:  MD_KeyWord_Def
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Def
! BRIEF:   Canonical four-type definitions for KeyWord domain
!          (Desc/State/Algo/Ctx). AUTHORITY source.
!===================================================================
MODULE MD_KeyWord_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_KW_Desc
  PUBLIC :: MD_KW_State
  PUBLIC :: MD_KW_Algo
  PUBLIC :: MD_KW_Ctx
  PUBLIC :: MD_KW_DescEntry

  !-----------------------------------------------------------------
  ! Constants
  !-----------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_MAX_REGISTERED = 512_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_KW_NAME_LEN      = 64_i4


  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_DescEntry
  ! KIND:  Desc
  ! DESC:  Single keyword registration entry (write-once)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_DescEntry
    CHARACTER(LEN=64)  :: kw_name        = ""       ! [in] Keyword name (e.g. "*NODE")
    CHARACTER(LEN=64)  :: name           = ""       ! [in] Alias for kw_name (Core compat)
    INTEGER(i4)        :: kw_category    = 0_i4     ! [in] KW_CAT_* category
    INTEGER(i4)        :: priority       = 0_i4     ! [in] P0/P1/P2 priority level
    INTEGER(i4)        :: n_params       = 0_i4     ! [in] Number of parameters
    CHARACTER(LEN=256) :: description    = ""       ! [in] Human-readable description
    CHARACTER(LEN=64)  :: parse_module   = ""       ! [in] Module providing parser
    CHARACTER(LEN=64)  :: parse_proc     = ""       ! [in] Procedure for parsing
    LOGICAL            :: has_validate   = .FALSE.  ! [in] Has validator?
    LOGICAL            :: has_data_lines = .FALSE.  ! [in] Expects data lines
    CHARACTER(LEN=64)  :: validate_proc  = ""       ! [in] Validation procedure
    LOGICAL            :: is_registered  = .FALSE.  ! [out] Registration flag
    LOGICAL            :: valid          = .FALSE.  ! [out] Valid flag (alias)
  END TYPE MD_KW_DescEntry


  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_Desc
  ! KIND:  Desc
  ! DESC:  KeyWord domain descriptor - registry of all known keywords
  !        (write-once after registration, read-only during parse)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_Desc
    INTEGER(i4)           :: n_registered = 0_i4                       ! [out] Count of registered entries
    INTEGER(i4)           :: n_keywords   = 0_i4                       ! [out] Alias (Core compat)
    TYPE(MD_KW_DescEntry) :: entries(MD_KW_MAX_REGISTERED)             ! [out] Entry array
    TYPE(MD_KW_DescEntry) :: keywords(MD_KW_MAX_REGISTERED)            ! [out] Alias array (Core compat)
  END TYPE MD_KW_Desc


  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_State
  ! KIND:  State
  ! DESC:  Parse progress tracking (mutable during parse, frozen after)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_State
    CHARACTER(LEN=64) :: current_keyword  = ""       ! [inout] Currently parsing keyword
    INTEGER(i4)       :: current_line     = 0_i4     ! [inout] Current line number
    INTEGER(i4)       :: current_col      = 0_i4     ! [inout] Current column number
    INTEGER(i4)       :: error_count      = 0_i4     ! [inout] Accumulated error count
    INTEGER(i4)       :: parse_errors     = 0_i4     ! [inout] Alias for error_count
    INTEGER(i4)       :: warning_count    = 0_i4     ! [inout] Accumulated warning count
    INTEGER(i4)       :: keywords_parsed  = 0_i4     ! [inout] Total keywords parsed
    LOGICAL           :: is_parsing       = .FALSE.  ! [inout] Currently in parse session
    LOGICAL           :: in_data_block    = .FALSE.  ! [inout] Inside data block
    LOGICAL           :: has_fatal_error  = .FALSE.  ! [inout] Fatal error occurred
  END TYPE MD_KW_State


  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_Algo
  ! KIND:  Algo
  ! DESC:  Parse strategy configuration (frozen after setup)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_Algo
    LOGICAL     :: strict_mode     = .FALSE.  ! [in] Strict: unknown keywords = ERROR
    LOGICAL     :: case_sensitive  = .FALSE.  ! [in] Case-sensitive matching
    INTEGER(i4) :: error_limit     = 100_i4   ! [in] Max errors before abort
    INTEGER(i4) :: warning_limit   = 500_i4   ! [in] Max warnings before suppress
    LOGICAL     :: allow_unknown   = .TRUE.   ! [in] Allow unregistered keywords
    LOGICAL     :: validate_params = .TRUE.   ! [in] Validate parameter types/ranges
    LOGICAL     :: recursive_parse = .TRUE.   ! [in] Enable recursive block parsing
  END TYPE MD_KW_Algo


  !-----------------------------------------------------------------
  ! TYPE:  MD_KW_Ctx
  ! KIND:  Ctx
  ! DESC:  Parse runtime handle (transient, per-parse operation)
  !-----------------------------------------------------------------
  TYPE, PUBLIC :: MD_KW_Ctx
    INTEGER(i4) :: parse_stage    = 0_i4     ! [inout] 0=idle, 1=lex, 2=parse, 3=map
    INTEGER(i4) :: ast_root_id   = 0_i4     ! [inout] AST root node ID
    INTEGER(i4) :: current_depth = 0_i4     ! [inout] Recursive parse depth
    INTEGER(i4) :: file_unit     = 0_i4     ! [inout] Input file unit number
    INTEGER(i4) :: total_lines   = 0_i4     ! [inout] Total lines read
    LOGICAL     :: in_step_block = .FALSE.  ! [inout] Inside *STEP block
    LOGICAL     :: in_part_block = .FALSE.  ! [inout] Inside *PART block
    LOGICAL     :: eof_reached   = .FALSE.  ! [inout] End-of-file reached
  END TYPE MD_KW_Ctx

END MODULE MD_KeyWord_Def
