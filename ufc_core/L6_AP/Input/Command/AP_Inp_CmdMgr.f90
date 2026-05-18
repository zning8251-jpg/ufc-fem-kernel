!===============================================================================
! MODULE: AP_Inp_CmdMgr
! LAYER:  L6_AP
! DOMAIN: Input/Command
! ROLE:   Mgr
! BRIEF:  Collection management, query, validation for Command domain.
!
! Process phases:
!   P0: AP_Cmd_Mgr_Init / AP_Cmd_Mgr_Finalize
!   P1: AP_Cmd_Mgr_AddCommand / AP_Cmd_Mgr_AddHandler / AP_Cmd_Mgr_AddHistory
!   P3: AP_Cmd_Mgr_GetCommand / AP_Cmd_Mgr_GetHandler / AP_Cmd_Mgr_GetHistory
!       AP_Cmd_Mgr_GetHandlerByName / AP_Cmd_Mgr_GetCommandCount /
!       AP_Cmd_Mgr_GetHandlerCount / AP_Cmd_Mgr_GetHistoryCount
!
! Status: FOUR-TYPE | Last verified: 2026-04-28
!===============================================================================
MODULE AP_Inp_CmdMgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Inp_Def,    ONLY: Cmd, CmdHandler, HistoryEntry
  USE AP_Inp_Domain, ONLY: AP_Cmd_Domain
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: AP_Cmd_Mgr_Init
  PUBLIC :: AP_Cmd_Mgr_Finalize
  PUBLIC :: AP_Cmd_Mgr_AddCommand
  PUBLIC :: AP_Cmd_Mgr_AddHandler
  PUBLIC :: AP_Cmd_Mgr_AddHistory
  PUBLIC :: AP_Cmd_Mgr_GetCommand
  PUBLIC :: AP_Cmd_Mgr_GetHandler
  PUBLIC :: AP_Cmd_Mgr_GetHandlerByName
  PUBLIC :: AP_Cmd_Mgr_GetHistory
  PUBLIC :: AP_Cmd_Mgr_GetCommandCount
  PUBLIC :: AP_Cmd_Mgr_GetHandlerCount
  PUBLIC :: AP_Cmd_Mgr_GetHistoryCount

CONTAINS

  SUBROUTINE AP_Cmd_Mgr_Init(domain, status)
    TYPE(AP_Cmd_Domain), INTENT(INOUT) :: domain
    TYPE(ErrorStatusType), INTENT(OUT)  :: status
    CALL domain%Init(status)
  END SUBROUTINE AP_Cmd_Mgr_Init

  SUBROUTINE AP_Cmd_Mgr_Finalize(domain)
    TYPE(AP_Cmd_Domain), INTENT(INOUT) :: domain
    CALL domain%Finalize()
  END SUBROUTINE AP_Cmd_Mgr_Finalize

  SUBROUTINE AP_Cmd_Mgr_AddCommand(domain, cmd, cmd_id, status)
    TYPE(AP_Cmd_Domain), INTENT(INOUT) :: domain
    TYPE(Cmd),           INTENT(IN)    :: cmd
    INTEGER(i4),        INTENT(OUT)   :: cmd_id
    TYPE(ErrorStatusType), INTENT(OUT)  :: status
    CALL domain%AddCommand(cmd, cmd_id, status)
  END SUBROUTINE AP_Cmd_Mgr_AddCommand

  SUBROUTINE AP_Cmd_Mgr_AddHandler(domain, h, handler_id, status)
    TYPE(AP_Cmd_Domain), INTENT(INOUT) :: domain
    TYPE(CmdHandler),    INTENT(IN)    :: h
    INTEGER(i4),        INTENT(OUT)   :: handler_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL domain%AddHandler(h, handler_id, status)
  END SUBROUTINE AP_Cmd_Mgr_AddHandler

  SUBROUTINE AP_Cmd_Mgr_AddHistory(domain, cmd, source, timestamp, status)
    TYPE(AP_Cmd_Domain), INTENT(INOUT) :: domain
    TYPE(Cmd),           INTENT(IN)    :: cmd
    CHARACTER(LEN=*),    INTENT(IN)    :: source
    INTEGER(i4),        INTENT(IN), OPTIONAL :: timestamp
    TYPE(ErrorStatusType), INTENT(OUT)  :: status
    CALL domain%AddHistory(cmd, source, timestamp, status)
  END SUBROUTINE AP_Cmd_Mgr_AddHistory

  SUBROUTINE AP_Cmd_Mgr_GetCommand(domain, idx, cmd, found)
    TYPE(AP_Cmd_Domain), INTENT(IN)  :: domain
    INTEGER(i4),         INTENT(IN)  :: idx
    TYPE(Cmd),          INTENT(OUT) :: cmd
    LOGICAL,            INTENT(OUT) :: found
    CALL domain%GetCommandById(idx, cmd, found)
  END SUBROUTINE AP_Cmd_Mgr_GetCommand

  SUBROUTINE AP_Cmd_Mgr_GetHandler(domain, idx, h, found)
    TYPE(AP_Cmd_Domain), INTENT(IN)  :: domain
    INTEGER(i4),         INTENT(IN)  :: idx
    TYPE(CmdHandler),    INTENT(OUT) :: h
    LOGICAL,             INTENT(OUT) :: found
    CALL domain%GetHandlerById(idx, h, found)
  END SUBROUTINE AP_Cmd_Mgr_GetHandler

  SUBROUTINE AP_Cmd_Mgr_GetHandlerByName(domain, name, h, found)
    TYPE(AP_Cmd_Domain), INTENT(IN)  :: domain
    CHARACTER(LEN=*),    INTENT(IN)  :: name
    TYPE(CmdHandler),    INTENT(OUT) :: h
    LOGICAL,             INTENT(OUT) :: found
    CALL domain%GetHandlerByName(name, h, found)
  END SUBROUTINE AP_Cmd_Mgr_GetHandlerByName

  SUBROUTINE AP_Cmd_Mgr_GetHistory(domain, idx, entry, found)
    TYPE(AP_Cmd_Domain), INTENT(IN)  :: domain
    INTEGER(i4),         INTENT(IN)  :: idx
    TYPE(HistoryEntry),  INTENT(OUT) :: entry
    LOGICAL,             INTENT(OUT) :: found
    CALL domain%GetHistoryById(idx, entry, found)
  END SUBROUTINE AP_Cmd_Mgr_GetHistory

  FUNCTION AP_Cmd_Mgr_GetCommandCount(domain) RESULT(n)
    TYPE(AP_Cmd_Domain), INTENT(IN) :: domain
    INTEGER(i4) :: n
    n = domain%n_commands
  END FUNCTION AP_Cmd_Mgr_GetCommandCount

  FUNCTION AP_Cmd_Mgr_GetHandlerCount(domain) RESULT(n)
    TYPE(AP_Cmd_Domain), INTENT(IN) :: domain
    INTEGER(i4) :: n
    n = domain%n_handlers
  END FUNCTION AP_Cmd_Mgr_GetHandlerCount

  FUNCTION AP_Cmd_Mgr_GetHistoryCount(domain) RESULT(n)
    TYPE(AP_Cmd_Domain), INTENT(IN) :: domain
    INTEGER(i4) :: n
    n = domain%n_history
  END FUNCTION AP_Cmd_Mgr_GetHistoryCount

END MODULE AP_Inp_CmdMgr