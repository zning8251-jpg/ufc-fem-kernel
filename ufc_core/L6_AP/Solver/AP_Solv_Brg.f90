!===============================================================================
! MODULE: AP_Solv_Brg
! LAYER:  L6_AP
! DOMAIN: Solver
! ROLE:   Brg — cross-layer bridge
! BRIEF:  Bridge module for Solver domain cross-layer data transfer.
!===============================================================================
MODULE AP_Solv_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  ! PUBLIC :: AP_Solver_Brg_FromL3  ! TODO: Add bridge procedures

CONTAINS

  ! TODO: Add bridge procedures for cross-layer data transfer

END MODULE AP_Solv_Brg
