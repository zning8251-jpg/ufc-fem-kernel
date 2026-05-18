!===============================================================================
! MODULE: AP_UI_Brg
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Brg — cross-layer bridge for UI domain
! BRIEF:  Bridge module for UI domain cross-layer type adaptation.
!===============================================================================
MODULE AP_UI_Brg
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  ! PUBLIC :: AP_UI_Brg_FromL3  ! TODO: Add bridge procedures

CONTAINS

  ! TODO: Add bridge procedures for cross-layer data transfer

END MODULE AP_UI_Brg
