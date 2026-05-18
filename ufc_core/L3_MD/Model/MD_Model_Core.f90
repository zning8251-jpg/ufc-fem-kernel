!===============================================================================
! MODULE:  MD_Model_Core
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Core (lifecycle management)
! BRIEF:   P0 core operations: Init, Finalize, Validate, SetName, Register,
!          Query, Summary. Operates on MD_Model_Desc and MD_Model_State.
!===============================================================================
MODULE MD_Model_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Model_Def, ONLY: MD_Model_Desc, MD_Model_State
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Model_Core_Init
  PUBLIC :: MD_Model_Core_Finalize
  PUBLIC :: MD_Model_Core_Set_Name
  PUBLIC :: MD_Model_Core_Get_NDim
  PUBLIC :: MD_Model_Core_Register_Part
  PUBLIC :: MD_Model_Core_Register_Step
  PUBLIC :: MD_Model_Core_Get_N_Parts
  PUBLIC :: MD_Model_Core_Get_N_Steps
  PUBLIC :: MD_Model_Core_Validate_All
  PUBLIC :: MD_Model_Core_Summary

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Core_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize model descriptor and state to defaults
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Core_Init(desc, state, status)
    TYPE(MD_Model_Desc),   INTENT(INOUT) :: desc    ! [inout] model descriptor
    TYPE(MD_Model_State),  INTENT(OUT)   :: state   ! [out] model state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status  ! [out] error status

    CALL init_error_status(status)

    desc%model_name  = ""
    desc%spatial_dim = 3
    desc%n_parts = 0
    desc%n_steps = 0
    desc%part_ids = 0
    desc%step_ids = 0

    state%parsed      = .FALSE.
    state%populated   = .FALSE.
    state%validated   = .FALSE.
    state%build_phase = 0

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Core_Init


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Core_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Reset model descriptor and invalidate state
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Core_Finalize(desc, state, status)
    TYPE(MD_Model_Desc),   INTENT(INOUT) :: desc    ! [inout] model descriptor
    TYPE(MD_Model_State),  INTENT(INOUT) :: state   ! [inout] model state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status  ! [out] error status

    CALL init_error_status(status)

    desc%model_name  = ""
    desc%n_parts = 0
    desc%n_steps = 0
    desc%part_ids = 0
    desc%step_ids = 0

    state%validated = .FALSE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Core_Finalize


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Core_Set_Name
  ! PHASE:      P0
  ! PURPOSE:    Set model name (validates non-empty)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Core_Set_Name(desc, name, status)
    TYPE(MD_Model_Desc),   INTENT(INOUT) :: desc    ! [inout] model descriptor
    CHARACTER(LEN=*),      INTENT(IN)    :: name    ! [in] model name
    TYPE(ErrorStatusType), INTENT(OUT)   :: status  ! [out] error status

    CALL init_error_status(status)

    IF (LEN_TRIM(name) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    desc%model_name = name
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Core_Set_Name


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Core_Get_NDim
  ! PHASE:      P0
  ! PURPOSE:    Query spatial dimension from descriptor
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Core_Get_NDim(desc) RESULT(ndim)
    TYPE(MD_Model_Desc), INTENT(IN) :: desc  ! [in] model descriptor
    INTEGER(i4) :: ndim
    ndim = desc%spatial_dim
  END FUNCTION MD_Model_Core_Get_NDim


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Core_Register_Part
  ! PHASE:      P0
  ! PURPOSE:    Register a part ID (capacity limited to 256)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Core_Register_Part(desc, part_id, status)
    TYPE(MD_Model_Desc),   INTENT(INOUT) :: desc     ! [inout] model descriptor
    INTEGER(i4),           INTENT(IN)    :: part_id  ! [in] part ID to register
    TYPE(ErrorStatusType), INTENT(OUT)   :: status   ! [out] error status

    CALL init_error_status(status)

    IF (desc%n_parts >= 256) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    desc%n_parts = desc%n_parts + 1
    desc%part_ids(desc%n_parts) = part_id

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Core_Register_Part


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Core_Register_Step
  ! PHASE:      P0
  ! PURPOSE:    Register a step ID (capacity limited to 100)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Core_Register_Step(desc, step_id, status)
    TYPE(MD_Model_Desc),   INTENT(INOUT) :: desc     ! [inout] model descriptor
    INTEGER(i4),           INTENT(IN)    :: step_id  ! [in] step ID to register
    TYPE(ErrorStatusType), INTENT(OUT)   :: status   ! [out] error status

    CALL init_error_status(status)

    IF (desc%n_steps >= 100) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    desc%n_steps = desc%n_steps + 1
    desc%step_ids(desc%n_steps) = step_id

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Core_Register_Step


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Core_Get_N_Parts
  ! PHASE:      P0
  ! PURPOSE:    Query registered part count
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Core_Get_N_Parts(desc) RESULT(n)
    TYPE(MD_Model_Desc), INTENT(IN) :: desc  ! [in] model descriptor
    INTEGER(i4) :: n
    n = desc%n_parts
  END FUNCTION MD_Model_Core_Get_N_Parts


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Core_Get_N_Steps
  ! PHASE:      P0
  ! PURPOSE:    Query registered step count
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Core_Get_N_Steps(desc) RESULT(n)
    TYPE(MD_Model_Desc), INTENT(IN) :: desc  ! [in] model descriptor
    INTEGER(i4) :: n
    n = desc%n_steps
  END FUNCTION MD_Model_Core_Get_N_Steps


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Core_Validate_All
  ! PHASE:      P0
  ! PURPOSE:    Validate model completeness (name, ndim, parts)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Core_Validate_All(desc, status)
    TYPE(MD_Model_Desc),   INTENT(IN)  :: desc    ! [in] model descriptor
    TYPE(ErrorStatusType), INTENT(OUT) :: status  ! [out] error status

    CALL init_error_status(status)

    IF (LEN_TRIM(desc%model_name) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (desc%spatial_dim < 1 .OR. desc%spatial_dim > 3) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    IF (desc%n_parts <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Core_Validate_All


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Core_Summary
  ! PHASE:      P0
  ! PURPOSE:    Write model summary to output unit
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Core_Summary(desc, unit_num, status)
    TYPE(MD_Model_Desc),   INTENT(IN)  :: desc      ! [in] model descriptor
    INTEGER(i4),           INTENT(IN)  :: unit_num  ! [in] output unit number
    TYPE(ErrorStatusType), INTENT(OUT) :: status    ! [out] error status

    CALL init_error_status(status)

    WRITE(unit_num, '(A)')    '=== Model Summary ==='
    WRITE(unit_num, '(A,A)')  '  Name   : ', TRIM(desc%model_name)
    WRITE(unit_num, '(A,I0)') '  NDim   : ', desc%spatial_dim
    WRITE(unit_num, '(A,I0)') '  N_Parts: ', desc%n_parts
    WRITE(unit_num, '(A,I0)') '  N_Steps: ', desc%n_steps

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Core_Summary

END MODULE MD_Model_Core
