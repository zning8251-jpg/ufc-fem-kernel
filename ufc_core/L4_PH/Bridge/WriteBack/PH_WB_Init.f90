!===============================================================================
! MODULE: PH_WB_Init
! LAYER:  L4_PH
! DOMAIN: WriteBack
! ROLE:   Core
! BRIEF:  WriteBack domain lifecycle (Init/Finalize)
!
! Status: ACTIVE | Last verified: 2026-04-28
!===============================================================================

MODULE PH_WB_Init
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR
  USE PH_WB_Mgr, ONLY: PH_WriteBack_Desc, PH_WriteBack_State
  
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: PH_WriteBack_InitDomain, PH_WriteBack_FinalizeDomain
  
CONTAINS
  
  SUBROUTINE PH_WriteBack_InitDomain(desc, state, nnodes, nelems, status)
    !! Initialize WriteBack domain
    !! @param[in] desc WriteBack descriptor
    !! @param[inout] state WriteBack state
    !! @param[in] nnodes Number of nodes
    !! @param[in] nelems Number of elements
    !! @param[out] status Error status
    TYPE(PH_WriteBack_Desc), INTENT(IN) :: desc
    TYPE(PH_WriteBack_State), INTENT(INOUT) :: state
    INTEGER(i4), INTENT(IN) :: nnodes, nelems
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Validate descriptor
    IF (.NOT. desc%Validate()) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'PH_WBInit_Algo: Invalid descriptor configuration'
      RETURN
    END IF
    
    ! Initialize state
    CALL state%Init(nnodes, nelems)
    
    status%status_code = IF_STATUS_OK
    status%message = 'PH_WriteBack domain initialized successfully'
  END SUBROUTINE PH_WriteBack_InitDomain
  
  SUBROUTINE PH_WriteBack_FinalizeDomain(state, status)
    !! Finalize WriteBack domain
    !! @param[inout] state WriteBack state
    !! @param[out] status Error status
    TYPE(PH_WriteBack_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Finalize state
    CALL state%Finalize()
    
    status%status_code = IF_STATUS_OK
    status%message = 'PH_WriteBack domain finalized successfully'
  END SUBROUTINE PH_WriteBack_FinalizeDomain
  
END MODULE PH_WB_Init