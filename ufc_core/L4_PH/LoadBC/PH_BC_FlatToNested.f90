!===============================================================================
! MODULE:  PH_BC_FlatToNested
! LAYER:   L4_PH
! DOMAIN:  BC
! ROLE:    Proc
! BRIEF:   WriteBack from flat arrays to semantic tree (BC only).
!===============================================================================
MODULE PH_BC_FlatToNested
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: slen = 64

  TYPE, PUBLIC :: PH_WriteBack_Mask_Type
    LOGICAL, ALLOCATABLE :: bc_mutable(:)
    LOGICAL :: allow_magnitude_change = .TRUE.
    LOGICAL :: allow_isFixed_change = .TRUE.
    LOGICAL :: allow_type_change = .FALSE.
  END TYPE

  TYPE, PUBLIC :: PH_WriteBack_Status_Type
    INTEGER(i4) :: n_modified = 0_i4
    INTEGER(i4) :: n_released = 0_i4
    LOGICAL :: writeback_success = .TRUE.
    CHARACTER(len=slen) :: last_operation = ""
  END TYPE

  PUBLIC :: PH_BC_Create_WriteBack_Mask
  PUBLIC :: PH_BC_WriteBack_From_Cache
  PUBLIC :: PH_BC_Release_Failed
  PUBLIC :: PH_BC_Validate_WriteBack

CONTAINS

  SUBROUTINE PH_BC_Create_WriteBack_Mask(n_bcs, mask)
    INTEGER(i4), INTENT(IN) :: n_bcs
    TYPE(PH_WriteBack_Mask_Type), INTENT(OUT) :: mask

    IF (ALLOCATED(mask%bc_mutable)) DEALLOCATE(mask%bc_mutable)
    ALLOCATE(mask%bc_mutable(n_bcs))
    mask%bc_mutable = .TRUE.
    mask%allow_magnitude_change = .TRUE.
    mask%allow_isFixed_change = .TRUE.
    mask%allow_type_change = .FALSE.
  END SUBROUTINE

  SUBROUTINE PH_BC_WriteBack_From_Cache(mask, status)
    TYPE(PH_WriteBack_Mask_Type), INTENT(IN) :: mask
    TYPE(PH_WriteBack_Status_Type), INTENT(OUT) :: status

    status%n_modified = 0_i4
    status%n_released = 0_i4
    status%writeback_success = .TRUE.
    status%last_operation = 'WriteBack_Stub'
  END SUBROUTINE

  SUBROUTINE PH_BC_Release_Failed(bc_index, mask, status)
    INTEGER(i4), INTENT(IN) :: bc_index
    TYPE(PH_WriteBack_Mask_Type), INTENT(IN) :: mask
    TYPE(PH_WriteBack_Status_Type), INTENT(INOUT) :: status

    status%n_released = status%n_released + 1_i4
    status%last_operation = 'ReleasedBC'
  END SUBROUTINE

  FUNCTION PH_BC_Validate_WriteBack(mask, n_bcs, status) RESULT(is_valid)
    TYPE(PH_WriteBack_Mask_Type), INTENT(IN) :: mask
    INTEGER(i4), INTENT(IN) :: n_bcs
    TYPE(PH_WriteBack_Status_Type), INTENT(INOUT) :: status
    LOGICAL :: is_valid

    is_valid = .TRUE.
    IF (SIZE(mask%bc_mutable) /= n_bcs) THEN
      status%writeback_success = .FALSE.
      status%last_operation = 'ValidateFailed'
      is_valid = .FALSE.
    END IF
  END FUNCTION

END MODULE PH_BC_FlatToNested
