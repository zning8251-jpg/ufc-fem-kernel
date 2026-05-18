! FK_MD_Brg_L2.f90
! L3_Model — Bridge to L2_Numeric (template)
!
! Architectural pattern: Bridge modules (*_Brg)
!   - Bridges are EXEMPT from strict layer ordering
!   - They mediate controlled communication between layers
!   - L3_MD requests L2_NM services through this bridge
!   - L2_NM never knows about L3_MD types
!
! Bridge naming: {FromLayer}_{Brg}_{ToLayer}
!   FK_MD_Brg_L2 = L3_Model bridges to L2_Numeric

MODULE FK_MD_Brg_L2
  USE FK_IF_Base_DP, ONLY: I4, WP

  IMPLICIT NONE
  PRIVATE

  !══════════════════════════════════════════════════════
  ! PUBLIC API
  !══════════════════════════════════════════════════════
  PUBLIC :: FK_MD_Brg_AllocMatrix
  PUBLIC :: FK_MD_Brg_FreeMatrix

CONTAINS

  !────────────────────────────────────────────────────
  SUBROUTINE FK_MD_Brg_AllocMatrix(nrows, ncols, matrix_id)
    INTEGER(I4), INTENT(IN)  :: nrows, ncols
    INTEGER(I4), INTENT(OUT) :: matrix_id

    ! Delegate to L2_NM matrix pool allocation
    matrix_id = 0
  END SUBROUTINE FK_MD_Brg_AllocMatrix

  !────────────────────────────────────────────────────
  SUBROUTINE FK_MD_Brg_FreeMatrix(matrix_id)
    INTEGER(I4), INTENT(IN) :: matrix_id

    ! Delegate to L2_NM matrix pool deallocation
  END SUBROUTINE FK_MD_Brg_FreeMatrix

END MODULE FK_MD_Brg_L2
