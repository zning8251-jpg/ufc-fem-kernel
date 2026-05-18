!===============================================================================
! MODULE: IF_Err_Reg
! LAYER:  L1_IF
! DOMAIN: Error
! ROLE:   _Reg
! BRIEF:  Centralized error code registry for all six layers.
!===============================================================================
!
! Data chain:
!   Error codes: L1_IF(1000-1999), Math(2000-2999), L2_NM(3000-3999),
!                L3_MD(4000-4999), L4_PH(5000-5999), L5_RT(6000-6999),
!                L6_AP(7000-7999)
!
! Contents (A-Z):
!   Types:
!     ErrorCodeEntry             [Desc] Single registered error code entry
!   Subroutines:
!     Finalize_ErrorCode_Registry [P0] Finalize registry
!     Init_ErrorCode_Registry     [P0] Initialize registry + pre-register
!     UFC_Register_Error_Code     [P0] Register a new error code
!   Functions:
!     UFC_Get_Error_Name          [P2] Lookup error name from code
!     UFC_Is_Error_Code_Valid     [P2] Validate error code for layer
!
! Constants: IF_ERR_IF_*, IF_ERR_NM_*, IF_ERR_MD_*, IF_ERR_PH_*,
!            IF_ERR_RT_*, IF_ERR_AP_*
!
! Status: Phase A | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Err_Reg
  ! Kinds from IF_Err_Def (same wp/i4 as IF_Prec) to avoid IF_Prec↔IF_Err cycle for gfortran
  USE IF_Err_Def, ONLY: IF_Err_Status_State, wp, i4
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: UFC_Register_Error_Code
  PUBLIC :: UFC_Get_Error_Name
  PUBLIC :: UFC_Is_Error_Code_Valid
  PUBLIC :: Init_ErrorCode_Registry
  PUBLIC :: Finalize_ErrorCode_Registry
  
  ! ==================================================================
  ! Global error code ranges per layer
  ! ==================================================================
  INTEGER(i4), PARAMETER :: IF_L1_ERROR_MIN = 1000
  INTEGER(i4), PARAMETER :: IF_L1_ERROR_MAX = 1999
  
  ! Aligned with IF_Err_Def: L1=1000-1999, Math=2000-2999, L2=3000-3999, ...
  INTEGER(i4), PARAMETER :: IF_L2_ERROR_MIN = 3000
  INTEGER(i4), PARAMETER :: IF_L2_ERROR_MAX = 3999
  
  INTEGER(i4), PARAMETER :: IF_L3_ERROR_MIN = 4000
  INTEGER(i4), PARAMETER :: IF_L3_ERROR_MAX = 4999
  
  INTEGER(i4), PARAMETER :: IF_L4_ERROR_MIN = 5000
  INTEGER(i4), PARAMETER :: IF_L4_ERROR_MAX = 5999
  
  INTEGER(i4), PARAMETER :: IF_L5_ERROR_MIN = 6000
  INTEGER(i4), PARAMETER :: IF_L5_ERROR_MAX = 6999
  
  INTEGER(i4), PARAMETER :: IF_L6_ERROR_MIN = 7000
  INTEGER(i4), PARAMETER :: IF_L6_ERROR_MAX = 7999
  
  ! ==================================================================
  ! Global status codes (cross-layer)
  ! ==================================================================
  INTEGER(i4), PARAMETER :: IF_STATUS_OK = 0
  INTEGER(i4), PARAMETER :: IF_STATUS_INVALID = -1
  INTEGER(i4), PARAMETER :: IF_STATUS_WRITEBACK_DENIED = -2
  INTEGER(i4), PARAMETER :: IF_STATUS_NOT_INITIALIZED = -3
  INTEGER(i4), PARAMETER :: IF_STATUS_OUT_OF_RANGE = -4
  INTEGER(i4), PARAMETER :: IF_STATUS_DUPLICATE = -5
  INTEGER(i4), PARAMETER :: IF_STATUS_REGISTRY_FULL = -6
  
  ! ==================================================================
  ! Error code registry structure
  ! ==================================================================
  INTEGER(i4), PARAMETER :: IF_MAX_REGISTERED_ERRORS = 500
  
  !--------------------------------------------------------------------
  ! TYPE: ErrorCodeEntry  [Desc]  (canonical: IF_Err_CodeEntry_Desc)
  ! Single registered error code entry.
  !--------------------------------------------------------------------
  TYPE :: ErrorCodeEntry
    INTEGER(i4) :: code
    CHARACTER(LEN=64) :: name
    CHARACTER(LEN=256) :: description
    CHARACTER(LEN=8) :: layer
    LOGICAL :: is_registered
  END TYPE ErrorCodeEntry
  
  TYPE(ErrorCodeEntry), SAVE :: g_error_registry(IF_MAX_REGISTERED_ERRORS)
  INTEGER, SAVE :: g_registry_count = 0
  LOGICAL, SAVE :: g_registry_initialized = .FALSE.
  
  ! ==================================================================
  ! Layer-specific error codes (pre-registered common errors)
  ! ==================================================================
  
  ! L1_IF errors (1000-1999)
  INTEGER(i4), PARAMETER :: IF_ERR_IF_MEMORY_ALLOC_FAILED = 1001
  INTEGER(i4), PARAMETER :: IF_ERR_IF_MEMORY_DEALLOC_FAILED = 1002
  INTEGER(i4), PARAMETER :: IF_ERR_IF_FILE_NOT_FOUND = 1010
  INTEGER(i4), PARAMETER :: IF_ERR_IF_FILE_READ_ERROR = 1011
  INTEGER(i4), PARAMETER :: IF_ERR_IF_FILE_WRITE_ERROR = 1012
  INTEGER(i4), PARAMETER :: IF_ERR_IF_INVALID_PRECISION = 1020
  INTEGER(i4), PARAMETER :: IF_ERR_IF_LOG_OPEN_FAILED = 1030
  INTEGER(i4), PARAMETER :: IF_ERR_IF_LOG_WRITE_FAILED = 1031
  
  ! L2_NM errors (3000-3999)
  INTEGER(i4), PARAMETER :: IF_ERR_NM_SOLVER_DIVERGED = 3001
  INTEGER(i4), PARAMETER :: IF_ERR_NM_SOLVER_MAX_ITER = 3002
  INTEGER(i4), PARAMETER :: IF_ERR_NM_MATRIX_SINGULAR = 3010
  INTEGER(i4), PARAMETER :: IF_ERR_NM_MATRIX_NOT_POS_DEF = 3011
  INTEGER(i4), PARAMETER :: IF_ERR_NM_EIGEN_NOT_CONVERGED = 3020
  INTEGER(i4), PARAMETER :: IF_ERR_NM_INVALID_TIME_STEP = 3030
  
  ! L3_MD errors (4000-4999)
  INTEGER(i4), PARAMETER :: IF_ERR_MD_MODEL_NOT_BUILT = 4001
  INTEGER(i4), PARAMETER :: IF_ERR_MD_MODEL_ALREADY_FROZEN = 4002
  INTEGER(i4), PARAMETER :: IF_ERR_MD_MATERIAL_NOT_FOUND = 4010
  INTEGER(i4), PARAMETER :: IF_ERR_MD_SECTION_NOT_FOUND = 4011
  INTEGER(i4), PARAMETER :: IF_ERR_MD_ELEMENT_NOT_FOUND = 4020
  INTEGER(i4), PARAMETER :: IF_ERR_MD_NODE_NOT_FOUND = 4021
  INTEGER(i4), PARAMETER :: IF_ERR_MD_INVALID_MESH = 4030
  INTEGER(i4), PARAMETER :: IF_ERR_MD_WRITEBACK_DENIED = 4040
  
  ! L4_PH errors (5000-5999)
  INTEGER(i4), PARAMETER :: IF_ERR_PH_INVALID_ELEMENT_TYPE = 5001
  INTEGER(i4), PARAMETER :: IF_ERR_PH_INVALID_MATERIAL_MODEL = 5002
  INTEGER(i4), PARAMETER :: IF_ERR_PH_CONSTITUTIVE_UPDATE_FAILED = 5010
  INTEGER(i4), PARAMETER :: IF_ERR_PH_STRAIN_EXCEEDED = 5011
  INTEGER(i4), PARAMETER :: IF_ERR_PH_CONTACT_NOT_CONVERGED = 5020
  INTEGER(i4), PARAMETER :: IF_ERR_PH_INVALID_SECTION = 5030
  
  ! L5_RT errors (6000-6999)
  INTEGER(i4), PARAMETER :: IF_ERR_RT_STEP_NOT_FOUND = 6001
  INTEGER(i4), PARAMETER :: IF_ERR_RT_STEP_ALREADY_COMPLETED = 6002
  INTEGER(i4), PARAMETER :: IF_ERR_RT_INCREMENT_FAILED = 6010
  INTEGER(i4), PARAMETER :: IF_ERR_RT_ITERATION_NOT_CONVERGED = 6011
  INTEGER(i4), PARAMETER :: IF_ERR_RT_ASSEMBLY_FAILED = 6020
  INTEGER(i4), PARAMETER :: IF_ERR_RT_BOUNDARY_CONDITION_ERROR = 6030
  INTEGER(i4), PARAMETER :: IF_ERR_RT_RESTART_FAILED = 6040
  
  ! L6_AP errors (7000-7999)
  INTEGER(i4), PARAMETER :: IF_ERR_AP_COMMAND_NOT_FOUND = 7001
  INTEGER(i4), PARAMETER :: IF_ERR_AP_INVALID_COMMAND_SYNTAX = 7002
  INTEGER(i4), PARAMETER :: IF_ERR_AP_INPUT_PARSE_ERROR = 7010
  INTEGER(i4), PARAMETER :: IF_ERR_AP_OUTPUT_WRITE_ERROR = 7011
  INTEGER(i4), PARAMETER :: IF_ERR_AP_JOB_SUBMISSION_FAILED = 7020
  INTEGER(i4), PARAMETER :: IF_ERR_AP_LICENSE_ERROR = 7030
  
CONTAINS
  
  !====================================================================
  ! [P0] Init_ErrorCode_Registry - Initialize error code registry
  !====================================================================
  SUBROUTINE Init_ErrorCode_Registry(status)
    TYPE(IF_Err_Status_State), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    IF (g_registry_initialized) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    
    ! Initialize registry array
    DO i = 1, IF_MAX_REGISTERED_ERRORS
      g_error_registry(i)%is_registered = .FALSE.
    END DO
    
    g_registry_count = 0
    g_registry_initialized = .TRUE.
    
    ! Pre-register common error codes
    CALL Register_Predefined_Errors(status)
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE Init_ErrorCode_Registry
  
  !====================================================================
  ! [P0] UFC_Register_Error_Code - Register a new error code
  !====================================================================
  SUBROUTINE UFC_Register_Error_Code(code, name, description, layer, status)
    INTEGER(i4), INTENT(IN) :: code
    CHARACTER(LEN=*), INTENT(IN) :: name
    CHARACTER(LEN=*), INTENT(IN) :: description
    CHARACTER(LEN=*), INTENT(IN) :: layer
    TYPE(IF_Err_Status_State), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    IF (.NOT. g_registry_initialized) THEN
      status%status_code = IF_STATUS_NOT_INITIALIZED
      status%message = "Error code registry not initialized"
      RETURN
    END IF
    
    ! Check if registry is full
    IF (g_registry_count >= IF_MAX_REGISTERED_ERRORS) THEN
      status%status_code = IF_STATUS_REGISTRY_FULL
      status%message = "Error code registry is full"
      RETURN
    END IF
    
    ! Validate error code range
    IF (.NOT. UFC_Is_Error_Code_Valid(code, layer)) THEN
      status%status_code = IF_STATUS_OUT_OF_RANGE
      status%message = "Error code " // TRIM(ADJUSTL(ITOA(code))) // &
                             " is outside valid range for layer " // TRIM(layer)
      RETURN
    END IF
    
    ! Check for duplicate
    DO i = 1, g_registry_count
      IF (g_error_registry(i)%code == code) THEN
        status%status_code = IF_STATUS_DUPLICATE
        status%message = "Error code " // TRIM(ADJUSTL(ITOA(code))) // &
                               " already registered"
        RETURN
      END IF
    END DO
    
    ! Register new error code
    g_registry_count = g_registry_count + 1
    g_error_registry(g_registry_count)%code = code
    g_error_registry(g_registry_count)%name = TRIM(name)
    g_error_registry(g_registry_count)%description = TRIM(description)
    g_error_registry(g_registry_count)%layer = TRIM(layer)
    g_error_registry(g_registry_count)%is_registered = .TRUE.
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE UFC_Register_Error_Code
  
  !====================================================================
  ! [P2] UFC_Get_Error_Name - Get error name from code
  !====================================================================
  FUNCTION UFC_Get_Error_Name(code) RESULT(name)
    INTEGER(i4), INTENT(IN) :: code
    CHARACTER(LEN=64) :: name
    
    INTEGER(i4) :: i
    
    name = "UNKNOWN_ERROR"
    
    DO i = 1, g_registry_count
      IF (g_error_registry(i)%code == code) THEN
        name = g_error_registry(i)%name
        RETURN
      END IF
    END DO
    
    ! Check standard status codes
    SELECT CASE (code)
    CASE (IF_STATUS_OK)
      name = "IF_STATUS_OK"
    CASE (IF_STATUS_INVALID)
      name = "IF_STATUS_INVALID"
    CASE (IF_STATUS_WRITEBACK_DENIED)
      name = "IF_STATUS_WRITEBACK_DENIED"
    CASE (IF_STATUS_NOT_INITIALIZED)
      name = "IF_STATUS_NOT_INITIALIZED"
    CASE (IF_STATUS_OUT_OF_RANGE)
      name = "IF_STATUS_OUT_OF_RANGE"
    CASE (IF_STATUS_DUPLICATE)
      name = "IF_STATUS_DUPLICATE"
    CASE (IF_STATUS_REGISTRY_FULL)
      name = "IF_STATUS_REGISTRY_FULL"
    END SELECT
    
  END FUNCTION UFC_Get_Error_Name
  
  !====================================================================
  ! [P2] UFC_Is_Error_Code_Valid - Check if error code is valid for layer
  !====================================================================
  FUNCTION UFC_Is_Error_Code_Valid(code, layer) RESULT(is_valid)
    INTEGER(i4), INTENT(IN) :: code
    CHARACTER(LEN=*), INTENT(IN) :: layer
    LOGICAL :: is_valid
    
    CHARACTER(LEN=8) :: layer_upper
    
    layer_upper = TO_UPPER(layer)
    is_valid = .FALSE.
    
    SELECT CASE (layer_upper)
    CASE ('L1_IF', 'IF')
      is_valid = (code >= IF_L1_ERROR_MIN .AND. code <= IF_L1_ERROR_MAX)
    CASE ('L2_NM', 'NM')
      is_valid = (code >= IF_L2_ERROR_MIN .AND. code <= IF_L2_ERROR_MAX)
    CASE ('L3_MD', 'MD')
      is_valid = (code >= IF_L3_ERROR_MIN .AND. code <= IF_L3_ERROR_MAX)
    CASE ('L4_PH', 'PH')
      is_valid = (code >= IF_L4_ERROR_MIN .AND. code <= IF_L4_ERROR_MAX)
    CASE ('L5_RT', 'RT')
      is_valid = (code >= IF_L5_ERROR_MIN .AND. code <= IF_L5_ERROR_MAX)
    CASE ('L6_AP', 'AP')
      is_valid = (code >= IF_L6_ERROR_MIN .AND. code <= IF_L6_ERROR_MAX)
    END SELECT
    
  END FUNCTION UFC_Is_Error_Code_Valid
  
  !====================================================================
  ! [P0] Finalize_ErrorCode_Registry - Finalize error code registry
  !====================================================================
  SUBROUTINE Finalize_ErrorCode_Registry()
    
    IF (.NOT. g_registry_initialized) RETURN
    
    g_registry_count = 0
    g_registry_initialized = .FALSE.
    
  END SUBROUTINE Finalize_ErrorCode_Registry
  
  !====================================================================
  ! [P0] Register_Predefined_Errors (private) - Pre-register common codes
  !====================================================================
  SUBROUTINE Register_Predefined_Errors(status)
    TYPE(IF_Err_Status_State), INTENT(OUT) :: status
    
    TYPE(IF_Err_Status_State) :: local_status
    
    ! L1_IF errors
    CALL UFC_Register_Error_Code(IF_ERR_IF_MEMORY_ALLOC_FAILED, &
         "IF_ERR_IF_MEMORY_ALLOC_FAILED", &
         "Memory allocation failed in L1_IF layer", &
         "L1_IF", local_status)
    
    CALL UFC_Register_Error_Code(IF_ERR_IF_FILE_NOT_FOUND, &
         "IF_ERR_IF_FILE_NOT_FOUND", &
         "File not found in L1_IF IO operations", &
         "L1_IF", local_status)
    
    ! L2_NM errors
    CALL UFC_Register_Error_Code(IF_ERR_NM_SOLVER_DIVERGED, &
         "IF_ERR_NM_SOLVER_DIVERGED", &
         "Solver diverged in L2_NM layer", &
         "L2_NM", local_status)
    
    CALL UFC_Register_Error_Code(IF_ERR_NM_MATRIX_SINGULAR, &
         "IF_ERR_NM_MATRIX_SINGULAR", &
         "Matrix is singular, cannot solve", &
         "L2_NM", local_status)
    
    ! L3_MD errors
    CALL UFC_Register_Error_Code(IF_ERR_MD_MODEL_NOT_BUILT, &
         "IF_ERR_MD_MODEL_NOT_BUILT", &
         "Model has not been built yet", &
         "L3_MD", local_status)
    
    CALL UFC_Register_Error_Code(IF_ERR_MD_WRITEBACK_DENIED, &
         "IF_ERR_MD_WRITEBACK_DENIED", &
         "WriteBack operation denied - field not in whitelist", &
         "L3_MD", local_status)
    
    ! L4_PH errors
    CALL UFC_Register_Error_Code(IF_ERR_PH_INVALID_ELEMENT_TYPE, &
         "IF_ERR_PH_INVALID_ELEMENT_TYPE", &
         "Invalid element type in L4_PH", &
         "L4_PH", local_status)
    
    ! L5_RT errors
    CALL UFC_Register_Error_Code(IF_ERR_RT_STEP_NOT_FOUND, &
         "IF_ERR_RT_STEP_NOT_FOUND", &
         "Step not found in L5_RT", &
         "L5_RT", local_status)
    
    CALL UFC_Register_Error_Code(IF_ERR_RT_ITERATION_NOT_CONVERGED, &
         "IF_ERR_RT_ITERATION_NOT_CONVERGED", &
         "Iteration did not converge in L5_RT", &
         "L5_RT", local_status)
    
    ! L6_AP errors
    CALL UFC_Register_Error_Code(IF_ERR_AP_COMMAND_NOT_FOUND, &
         "IF_ERR_AP_COMMAND_NOT_FOUND", &
         "Command not found in L6_AP", &
         "L6_AP", local_status)
    
    CALL UFC_Register_Error_Code(IF_ERR_AP_INPUT_PARSE_ERROR, &
         "IF_ERR_AP_INPUT_PARSE_ERROR", &
         "Failed to parse input file in L6_AP", &
         "L6_AP", local_status)
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE Register_Predefined_Errors
  
  !====================================================================
  ! Utility function: Integer to String
  !====================================================================
  FUNCTION ITOA(i) RESULT(str)
    INTEGER(i4), INTENT(IN) :: i
    CHARACTER(LEN=12) :: str
    WRITE(str, '(I12)') i
  END FUNCTION ITOA
  
  !====================================================================
  ! Utility function: To Upper Case
  !====================================================================
  FUNCTION TO_UPPER(str) RESULT(upper_str)
    CHARACTER(LEN=*), INTENT(IN) :: str
    CHARACTER(LEN=LEN(str)) :: upper_str
    INTEGER(i4) :: i, diff
    
    upper_str = str
    diff = IACHAR('a') - IACHAR('A')
    
    DO i = 1, LEN(upper_str)
      IF (IACHAR(upper_str(i:i)) >= IACHAR('a') .AND. &
          IACHAR(upper_str(i:i)) <= IACHAR('z')) THEN
        upper_str(i:i) = ACHAR(IACHAR(upper_str(i:i)) - diff)
      END IF
    END DO
    
  END FUNCTION TO_UPPER
  
END MODULE IF_Err_Reg