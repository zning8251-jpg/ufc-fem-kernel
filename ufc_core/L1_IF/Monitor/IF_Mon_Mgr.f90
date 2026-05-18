!===============================================================================
! MODULE: IF_Mon_Mgr
! LAYER:  L1_IF
! DOMAIN: Monitor
! ROLE:   _Mgr
! BRIEF:  Monitor domain collection management, query, validation.
!===============================================================================
!
! Contents (A-Z):
!   IF_Monitor_Mgr_GetLogState  [P3] Query flat domain log state
!   IF_Monitor_Mgr_Validate     [P2] Validate domain state
!
! Status: Production | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Mon_Mgr
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Mon_Def, ONLY: IF_Mon_Log_State
  USE IF_Mon_Core, ONLY: IF_Monitor_Domain, IF_Monitor_GetDomain
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: IF_Monitor_Mgr_GetLogState, IF_Monitor_Mgr_Validate

CONTAINS

  !--------------------------------------------------------------------
  ! [P3] IF_Monitor_Mgr_GetLogState - query flat domain
  !--------------------------------------------------------------------
  SUBROUTINE IF_Monitor_Mgr_GetLogState(log_state, status)
    TYPE(IF_Mon_Log_State), INTENT(OUT) :: log_state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(IF_Monitor_Domain), POINTER :: dom

    CALL init_error_status(status)
    dom => IF_Monitor_GetDomain()
    IF (.NOT. ASSOCIATED(dom)) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Monitor domain not initialized"
      RETURN
    END IF
    IF (.NOT. dom%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Monitor domain not initialized"
      RETURN
    END IF
    log_state = dom%state%log
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Monitor_Mgr_GetLogState

  !--------------------------------------------------------------------
  ! [P2] IF_Monitor_Mgr_Validate - validate domain state
  !--------------------------------------------------------------------
  SUBROUTINE IF_Monitor_Mgr_Validate(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(IF_Monitor_Domain), POINTER :: dom

    CALL init_error_status(status)
    dom => IF_Monitor_GetDomain()
    IF (.NOT. ASSOCIATED(dom)) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Monitor_Mgr_Validate

END MODULE IF_Mon_Mgr
