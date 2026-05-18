!===============================================================================
! MODULE: IF_Base_Core
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Core — low-level API operating on Desc/State types
! BRIEF:  Init/Finalize/accessors for Base domain descriptor.
!===============================================================================
MODULE IF_Base_Core
  USE IF_Prec_Core,     ONLY: wp, i4
  USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Base_Def, ONLY: IF_Base_Desc
  IMPLICIT NONE
  PRIVATE

  !-- P0: Init/Finalize ----------------------------------------------------
  PUBLIC :: IF_Base_Core_Init
  PUBLIC :: IF_Base_Core_Finalize
  !-- P0: Accessors ---------------------------------------------------------
  PUBLIC :: IF_Base_Get_NDim
  PUBLIC :: IF_Base_Get_Analysis_Type
  PUBLIC :: IF_Base_Get_Version
  PUBLIC :: IF_Base_Global_Init

CONTAINS

  !-- [P0] Init: initialise Desc from defaults ----------------------------
  SUBROUTINE IF_Base_Core_Init(desc, status)
    TYPE(IF_Base_Desc),    INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Base_Core_Init

  !-- [P0] Finalize: no-op (Desc is value-type) ---------------------------
  SUBROUTINE IF_Base_Core_Finalize(desc, status)
    TYPE(IF_Base_Desc),    INTENT(IN)  :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Base_Core_Finalize

  FUNCTION IF_Base_Get_NDim(desc) RESULT(ndim)
    TYPE(IF_Base_Desc), INTENT(IN) :: desc
    INTEGER(i4) :: ndim
    ndim = desc%ndim
  END FUNCTION IF_Base_Get_NDim

  FUNCTION IF_Base_Get_Analysis_Type(desc) RESULT(atype)
    TYPE(IF_Base_Desc), INTENT(IN) :: desc
    INTEGER(i4) :: atype
    atype = desc%analysis_type
  END FUNCTION IF_Base_Get_Analysis_Type

  SUBROUTINE IF_Base_Get_Version(desc, version)
    TYPE(IF_Base_Desc), INTENT(IN)  :: desc
    CHARACTER(LEN=*),   INTENT(OUT) :: version
    version = desc%version
  END SUBROUTINE IF_Base_Get_Version

  !-- [P0] Global_Init: configure Desc from user input --------------------
  SUBROUTINE IF_Base_Global_Init(desc, ndim, analysis_type, status)
    TYPE(IF_Base_Desc),    INTENT(INOUT) :: desc
    INTEGER(i4),           INTENT(IN)    :: ndim
    INTEGER(i4),           INTENT(IN)    :: analysis_type
    TYPE(ErrorStatusType), INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (ndim < 1 .OR. ndim > 3) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_Base_Global_Init: ndim must be 1-3"
      RETURN
    END IF
    desc%ndim          = ndim
    desc%analysis_type = analysis_type
    status%status_code = IF_STATUS_OK
  END SUBROUTINE IF_Base_Global_Init

END MODULE IF_Base_Core
