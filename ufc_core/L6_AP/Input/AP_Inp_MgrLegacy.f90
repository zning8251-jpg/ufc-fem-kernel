!===============================================================================
! MODULE: AP_Inp_MgrLegacy
! LAYER:  L6_AP
! DOMAIN: Input
! ROLE:   Mgr (Legacy)
! BRIEF:  Legacy manager — collection management, query, validation for Input domain.
!
! Process phases:
!   P0: AP_Input_Mgr_Init
!   P1: AP_Input_Mgr_AddKeyword / AP_Input_Mgr_AddCommand
!   P3: AP_Input_Mgr_GetKeyword / AP_Input_Mgr_GetCmd
!       AP_Input_Mgr_GetKeywordCount / AP_Input_Mgr_GetCmdCount
!
! Status: FOUR-TYPE | Last verified: 2026-04-28
!===============================================================================
MODULE AP_Inp_MgrLegacy
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Inp_Def, ONLY: ParsedKeywordEntry, ParsedCommandEntry
  USE AP_Inp_Mgr, ONLY: AP_Input_Domain
  USE AP_Inp_Def, ONLY: Cmd
  USE AP_Inp_Script, ONLY: g_cmd_domain
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Input_Mgr_Init
  PUBLIC :: AP_Input_Mgr_AddKeyword
  PUBLIC :: AP_Input_Mgr_AddCommand
  PUBLIC :: AP_Input_Mgr_GetKeyword
  PUBLIC :: AP_Input_Mgr_GetCmd
  PUBLIC :: AP_Input_Mgr_GetKeywordCount
  PUBLIC :: AP_Input_Mgr_GetCmdCount

CONTAINS

  SUBROUTINE AP_Input_Mgr_Init(domain, status)
    TYPE(AP_Input_Domain), INTENT(INOUT) :: domain
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL domain%Init(status)
  END SUBROUTINE AP_Input_Mgr_Init

  SUBROUTINE AP_Input_Mgr_AddKeyword(domain, keyword_id, line_number, name, category, has_data, status)
    TYPE(AP_Input_Domain), INTENT(INOUT) :: domain
    INTEGER(i4),            INTENT(IN)    :: keyword_id
    INTEGER(i4),            INTENT(IN)    :: line_number
    CHARACTER(LEN=*),       INTENT(IN)    :: name
    INTEGER(i4),            INTENT(IN)    :: category
    LOGICAL,                INTENT(IN)    :: has_data
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status
    CALL domain%AddParsedKeyword(keyword_id, line_number, name, category, has_data, status)
  END SUBROUTINE AP_Input_Mgr_AddKeyword

  SUBROUTINE AP_Input_Mgr_AddCommand(domain, cmd_id, keyword_idx, line_number, name, opt, params, param_str, status)
    TYPE(AP_Input_Domain), INTENT(INOUT) :: domain
    INTEGER(i4),            INTENT(OUT)   :: cmd_id
    INTEGER(i4),            INTENT(IN)    :: keyword_idx
    INTEGER(i4),            INTENT(IN)    :: line_number
    CHARACTER(LEN=*),       INTENT(IN)    :: name
    CHARACTER(LEN=*),       INTENT(IN)    :: opt
    REAL(wp),               INTENT(IN)    :: params(3)
    CHARACTER(LEN=*),       INTENT(IN)    :: param_str
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status
    TYPE(Cmd) :: cmd
    cmd%name = name(1:MIN(16, LEN_TRIM(name)))
    cmd%opt = opt(1:MIN(64, LEN_TRIM(opt)))
    cmd%params = params
    cmd%param_str = param_str(1:MIN(256, LEN_TRIM(param_str)))
    cmd%line = line_number
    CALL g_cmd_domain%AddCommand(cmd, cmd_id, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    CALL domain%AddParsedCommand(cmd_id, keyword_idx, line_number, name, opt, params, param_str, status)
  END SUBROUTINE AP_Input_Mgr_AddCommand

  SUBROUTINE AP_Input_Mgr_GetKeyword(domain, idx, entry, found)
    TYPE(AP_Input_Domain), INTENT(IN)  :: domain
    INTEGER(i4),            INTENT(IN)  :: idx
    TYPE(ParsedKeywordEntry), INTENT(OUT) :: entry
    LOGICAL,                INTENT(OUT) :: found
    CALL domain%GetKeywordById(idx, entry, found)
  END SUBROUTINE AP_Input_Mgr_GetKeyword

  SUBROUTINE AP_Input_Mgr_GetCmd(domain, idx, entry, found)
    TYPE(AP_Input_Domain), INTENT(IN)  :: domain
    INTEGER(i4),            INTENT(IN)  :: idx
    TYPE(ParsedCommandEntry), INTENT(OUT) :: entry
    LOGICAL,                INTENT(OUT) :: found
    CALL domain%GetCmdById(idx, entry, found)
  END SUBROUTINE AP_Input_Mgr_GetCmd

  FUNCTION AP_Input_Mgr_GetKeywordCount(domain) RESULT(n)
    TYPE(AP_Input_Domain), INTENT(IN) :: domain
    INTEGER(i4) :: n
    n = domain%n_keywords
  END FUNCTION AP_Input_Mgr_GetKeywordCount

  FUNCTION AP_Input_Mgr_GetCmdCount(domain) RESULT(n)
    TYPE(AP_Input_Domain), INTENT(IN) :: domain
    INTEGER(i4) :: n
    n = domain%n_commands
  END FUNCTION AP_Input_Mgr_GetCmdCount

END MODULE AP_Inp_MgrLegacy