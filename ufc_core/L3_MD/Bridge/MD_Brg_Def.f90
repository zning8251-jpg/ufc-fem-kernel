!===============================================================================
! L3_MD / Bridge / Def
! Bridge domain: 4-type definition for cross-layer data bridging (L3<->L4<->L5)
!===============================================================================
MODULE MD_Brg_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Bridge Descriptor: read-only configuration for a bridge instance
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Brg_Desc
    INTEGER(i4) :: bridge_id = 0             ! Unique bridge identifier
    INTEGER(i4) :: source_layer = 3          ! Source layer ID (3, 4, or 5)
    INTEGER(i4) :: target_layer = 4          ! Target layer ID (3, 4, or 5)
    LOGICAL :: is_active = .FALSE.           ! Whether this bridge is active
  CONTAINS
    PROCEDURE :: Init       => MD_Brg_Desc_Init
    PROCEDURE :: Valid      => MD_Brg_Desc_Valid
  END TYPE MD_Brg_Desc

  !-----------------------------------------------------------------------------
  ! Bridge State: runtime data for bridge transfer
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Brg_State
    LOGICAL :: data_ready = .FALSE.          ! Data available for transfer
    INTEGER(i4) :: transfer_count = 0        ! Number of transfers completed
    REAL(wp) :: last_transfer_time = 0.0_wp  ! Timestamp of last transfer
  CONTAINS
    PROCEDURE :: Init       => MD_Brg_State_Init
  END TYPE MD_Brg_State

  PRIVATE :: MD_Brg_Desc_Init, MD_Brg_Desc_Valid, MD_Brg_State_Init

CONTAINS

  SUBROUTINE MD_Brg_Desc_Init(this, status)
    CLASS(MD_Brg_Desc), INTENT(OUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    this%bridge_id = 0
    this%source_layer = 3
    this%target_layer = 4
    this%is_active = .FALSE.
    CALL init_error_status(status)
  END SUBROUTINE MD_Brg_Desc_Init

  SUBROUTINE MD_Brg_Desc_Valid(this, status)
    CLASS(MD_Brg_Desc), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (this%bridge_id <= 0) THEN
      status%status_code = 1
      status%message = "Bridge ID must be positive"
    END IF
  END SUBROUTINE MD_Brg_Desc_Valid

  SUBROUTINE MD_Brg_State_Init(this, status)
    CLASS(MD_Brg_State), INTENT(OUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    this%data_ready = .FALSE.
    this%transfer_count = 0
    this%last_transfer_time = 0.0_wp
    CALL init_error_status(status)
  END SUBROUTINE MD_Brg_State_Init

END MODULE MD_Brg_Def
