! Harness-only MD_Base_ObjModel: minimal object-model bases for MD_Mat_Def syntax check.
MODULE MD_Base_ObjModel
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CAT_DESC, CAT_STATE, CAT_CTX, CAT_ALGO
  PUBLIC :: BaseSta, BaseSta_SetStatus, BaseSta_ClearStatus, BaseSta_GetStatus
  PUBLIC :: BaseSta_IsOK, BaseSta_IsError
  PUBLIC :: BaseDesc, BaseState, BaseAlgo, BaseCtx
  PUBLIC :: DescBase, StateBase, CtxBase, AlgoBase
  PUBLIC :: DescBase_Init, DescBase_Destroy, StateBase_Init, StateBase_Destroy
  PUBLIC :: CtxBase_Init, AlgoBase_Init
  PUBLIC :: TreeSerializer, TreeDeserializer

  INTEGER(i4), PARAMETER :: CAT_DESC = 1_i4
  INTEGER(i4), PARAMETER :: CAT_STATE = 2_i4
  INTEGER(i4), PARAMETER :: CAT_ALGO = 3_i4
  INTEGER(i4), PARAMETER :: CAT_CTX = 7_i4

  TYPE :: TreeSerializer
    INTEGER(i4) :: placeholder = 0_i4
  END TYPE TreeSerializer

  TYPE :: TreeDeserializer
    INTEGER(i4) :: placeholder = 0_i4
  END TYPE TreeDeserializer

  TYPE :: BaseSta
    TYPE(ErrorStatusType) :: status_
    LOGICAL :: has_error = .FALSE.
  CONTAINS
    PROCEDURE :: SetStatus => BaseSta_SetStatus
    PROCEDURE :: ClearStatus => BaseSta_ClearStatus
    PROCEDURE :: GetStatus => BaseSta_GetStatus
    PROCEDURE :: IsOK => BaseSta_IsOK
    PROCEDURE :: IsError => BaseSta_IsError
  END TYPE BaseSta

  TYPE :: BaseDesc
    CHARACTER(LEN=80) :: name = ''
    LOGICAL :: is_init = .FALSE.
  END TYPE BaseDesc

  TYPE :: BaseState
    LOGICAL :: is_init = .FALSE.
  END TYPE BaseState

  TYPE :: BaseAlgo
    LOGICAL :: is_init = .FALSE.
  END TYPE BaseAlgo

  TYPE :: BaseCtx
    LOGICAL :: is_init = .FALSE.
  END TYPE BaseCtx

  TYPE, EXTENDS(BaseDesc) :: DescBase
    INTEGER(i4) :: algo_category = CAT_DESC
    CHARACTER(LEN=64) :: algo_type_name = ''
    CHARACTER(LEN=64) :: algo_var_name = ''
  CONTAINS
    PROCEDURE :: Init => DescBase_Init
    PROCEDURE :: Destroy => DescBase_Destroy
    PROCEDURE :: RegLayout => DescBase_RegLayout
    PROCEDURE :: Ensure => DescBase_Ensure
    PROCEDURE :: Valid => DescBase_Valid
  END TYPE DescBase

  TYPE, EXTENDS(BaseState) :: StateBase
    INTEGER(i4) :: algo_category = CAT_STATE
    CHARACTER(LEN=64) :: algo_type_name = ''
    CHARACTER(LEN=64) :: algo_var_name = ''
  CONTAINS
    PROCEDURE :: Init => StateBase_Init
    PROCEDURE :: Destroy => StateBase_Destroy
  END TYPE StateBase

  TYPE, EXTENDS(BaseAlgo) :: AlgoBase
    INTEGER(i4) :: algo_category = CAT_ALGO
  END TYPE AlgoBase

  TYPE, EXTENDS(BaseCtx) :: CtxBase
    INTEGER(i4) :: algo_category = CAT_CTX
  END TYPE CtxBase

CONTAINS

  SUBROUTINE BaseSta_SetStatus(this, status)
    CLASS(BaseSta), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(IN) :: status
    this%status_ = status
    this%has_error = (status%status_code /= IF_STATUS_OK)
  END SUBROUTINE BaseSta_SetStatus

  SUBROUTINE BaseSta_ClearStatus(this)
    CLASS(BaseSta), INTENT(INOUT) :: this
    CALL init_error_status(this%status_)
    this%has_error = .FALSE.
  END SUBROUTINE BaseSta_ClearStatus

  FUNCTION BaseSta_GetStatus(this) RESULT(status)
    CLASS(BaseSta), INTENT(IN) :: this
    TYPE(ErrorStatusType) :: status
    status = this%status_
  END FUNCTION BaseSta_GetStatus

  LOGICAL FUNCTION BaseSta_IsOK(this) RESULT(ok)
    CLASS(BaseSta), INTENT(IN) :: this
    ok = .NOT. this%has_error
  END FUNCTION BaseSta_IsOK

  LOGICAL FUNCTION BaseSta_IsError(this) RESULT(err)
    CLASS(BaseSta), INTENT(IN) :: this
    err = this%has_error
  END FUNCTION BaseSta_IsError

  SUBROUTINE DescBase_Init(this)
    CLASS(DescBase), INTENT(INOUT) :: this
    this%is_init = .TRUE.
  END SUBROUTINE DescBase_Init

  SUBROUTINE DescBase_Destroy(this)
    CLASS(DescBase), INTENT(INOUT) :: this
    this%is_init = .FALSE.
  END SUBROUTINE DescBase_Destroy

  SUBROUTINE DescBase_RegLayout(this)
    CLASS(DescBase), INTENT(INOUT) :: this
  END SUBROUTINE DescBase_RegLayout

  SUBROUTINE DescBase_Ensure(this)
    CLASS(DescBase), INTENT(INOUT) :: this
  END SUBROUTINE DescBase_Ensure

  LOGICAL FUNCTION DescBase_Valid(this) RESULT(ok)
    CLASS(DescBase), INTENT(IN) :: this
    ok = this%is_init
  END FUNCTION DescBase_Valid

  SUBROUTINE StateBase_Init(this, n)
    CLASS(StateBase), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n
    this%is_init = .TRUE.
  END SUBROUTINE StateBase_Init

  SUBROUTINE StateBase_Destroy(this)
    CLASS(StateBase), INTENT(INOUT) :: this
    this%is_init = .FALSE.
  END SUBROUTINE StateBase_Destroy

  SUBROUTINE CtxBase_Init(this)
    CLASS(CtxBase), INTENT(INOUT) :: this
    this%is_init = .TRUE.
  END SUBROUTINE CtxBase_Init

  SUBROUTINE AlgoBase_Init(this)
    CLASS(AlgoBase), INTENT(INOUT) :: this
    this%is_init = .TRUE.
  END SUBROUTINE AlgoBase_Init

END MODULE MD_Base_ObjModel
