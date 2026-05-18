!======================================================================
! Module: MD_OutMgr
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Manager
! Purpose: Output manager - registration, query, validation.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================

MODULE MD_Out_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Out_API, ONLY: MD_Output_Domain, MD_OutputRequest_Desc, &
       OUT_FIELD, OUT_HISTORY, OUT_CONTACT, OUT_ENERGY
  USE MD_Step_Mgr,   ONLY: MD_Step_Domain
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Out_Mgr_RegisterRequest
  PUBLIC :: MD_Out_Mgr_GetStats
  PUBLIC :: MD_Out_Mgr_GetRequestsForStep

CONTAINS

  !=============================================================================
  ! MD_Out_Mgr_RegisterRequest
  ! Register output request to Domain; if step_ref>0, update step%output_ids.
  ! step_domain may be unallocated (e.g. parse before BindDomains).
  !=============================================================================
  SUBROUTINE MD_Out_Mgr_RegisterRequest(domain, step_domain, desc, status)
    TYPE(MD_Output_Domain), INTENT(INOUT) :: domain
    TYPE(MD_Step_Domain),  INTENT(INOUT), OPTIONAL :: step_domain
    TYPE(MD_OutputRequest_Desc), INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    INTEGER(i4) :: req_id
    INTEGER(i4) :: step_ref

    CALL init_error_status(status)
    step_ref = desc%step_ref

    CALL domain%AddRequest(desc, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    req_id = domain%n_requests  ! Actual id after add

    ! Update step index tree when step_ref > 0 and step_domain provided
    IF (step_ref > 0_i4 .AND. PRESENT(step_domain) .AND. step_domain%initialized) THEN
      CALL step_domain%AddOutputId(step_ref, req_id, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Out_Mgr_RegisterRequest

  !=============================================================================
  ! MD_Out_Mgr_GetRequestsForStep
  ! Get output request indices for a step. Uses step%output_ids when available
  ! (index tree, Phase C); otherwise falls back to step_ref scan.
  ! L5_RT should call this with output_domain + step_domain to use index tree.
  !=============================================================================
  SUBROUTINE MD_Out_Mgr_GetRequestsForStep(output_domain, step_domain, step_idx, &
       req_indices, n_found, status)
    TYPE(MD_Output_Domain), INTENT(IN)  :: output_domain
    TYPE(MD_Step_Domain),   INTENT(IN)  :: step_domain
    INTEGER(i4),            INTENT(IN)  :: step_idx
    INTEGER(i4),            INTENT(OUT) :: req_indices(:)
    INTEGER(i4),            INTENT(OUT) :: n_found
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    IF (step_idx >= 1_i4 .AND. step_idx <= step_domain%n_steps .AND. &
         ALLOCATED(step_domain%steps(step_idx)%output_ids) .AND. &
         SIZE(step_domain%steps(step_idx)%output_ids) > 0_i4) THEN
      CALL output_domain%GetRequestsForStep(step_idx, req_indices, n_found, status, &
           step_output_ids=step_domain%steps(step_idx)%output_ids)
    ELSE
      CALL output_domain%GetRequestsForStep(step_idx, req_indices, n_found, status)
    END IF
  END SUBROUTINE MD_Out_Mgr_GetRequestsForStep

  !=============================================================================
  ! MD_Out_Mgr_GetStats
  ! Get output domain statistics.
  !=============================================================================
  SUBROUTINE MD_Out_Mgr_GetStats(domain, n_requests, status)
    TYPE(MD_Output_Domain), INTENT(IN)  :: domain
    INTEGER(i4),           INTENT(OUT) :: n_requests
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    n_requests = domain%n_requests
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Out_Mgr_GetStats

END MODULE MD_Out_Mgr