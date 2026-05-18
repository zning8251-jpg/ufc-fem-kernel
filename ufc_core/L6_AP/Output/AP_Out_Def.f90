!======================================================================
! Module: AP_Out_Def
! Layer:  L6_AP - Application Layer
! Domain: Output / Type Definitions
! Purpose: Type definitions for Output domain.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE AP_Out_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! --- Output request/frame ID (index into flat domain) ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTPUT_REQUEST_ID_INVALID = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTPUT_FRAME_ID_INVALID   = 0_i4

  ! --- Request type (align with FldOutReq/HistOutReq) ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTPUT_REQ_FIELD   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTPUT_REQ_HISTORY = 2_i4

  ! --- Output request entry (flat domain slot) ---
  TYPE, PUBLIC :: OutputRequestEntry
    INTEGER(i4) :: request_id   = 0_i4
    INTEGER(i4) :: req_type     = 0_i4   ! AP_OUTPUT_REQ_FIELD / AP_OUTPUT_REQ_HISTORY
    CHARACTER(LEN=64) :: name   = ' '
    CHARACTER(LEN=64) :: region = ' '
    INTEGER(i4) :: position     = 0_i4   ! node/elem_in/centroid (OUT_LOC_* from L3)
    INTEGER(i4) :: frequency    = 1_i4
    INTEGER(i4) :: n_vars       = 0_i4
    INTEGER(i4), ALLOCATABLE :: variables(:)
    CHARACTER(LEN=256) :: variable_str = ' '  ! e.g. PRESELECT, U, S (for bridge to L3)
    INTEGER(i4) :: step_id      = 0_i4   ! step when request was defined
  END TYPE OutputRequestEntry

  ! --- Frame entry (flat domain slot) ---
  TYPE, PUBLIC :: FrameEntry
    INTEGER(i4) :: frame_id     = 0_i4
    INTEGER(i4) :: step_id      = 0_i4
    INTEGER(i4) :: inc_id       = 0_i4
    REAL(wp)    :: time         = 0.0_wp
    INTEGER(i4) :: request_id   = 0_i4   ! which output request
  END TYPE FrameEntry

  ! --- Output domain ID (for index tree) ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTPUT_DOMAIN_REQUEST = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTPUT_DOMAIN_FRAME   = 2_i4

END MODULE AP_Out_Def
