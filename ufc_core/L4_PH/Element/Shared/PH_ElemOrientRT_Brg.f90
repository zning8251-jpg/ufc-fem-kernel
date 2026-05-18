!===============================================================================
! MODULE: PH_ElemOrientRT_Brg
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Brg
! BRIEF:  Bridge orientation types from L5_RT to L4_PH for composite elements
!===============================================================================
MODULE PH_ElemOrientRT_Brg
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: wp, i4
  USE RT_Asm_Orient_Core, ONLY: RT_Orientation
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Orientation

END MODULE PH_ElemOrientRT_Brg
