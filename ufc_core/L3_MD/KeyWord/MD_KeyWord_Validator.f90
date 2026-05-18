!===================================================================
! MODULE : MD_KeyWord_Validator
! LAYER  : L3_MD
! DOMAIN : KeyWord (KW)
! ROLE   : Impl / Validate
! BRIEF  : Keyword whitelist check, required-parameter validation,
!          and parameter-value range validation for ABAQUS INP.
!===================================================================

MODULE MD_KeyWord_Validator
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: MD_Is_Valid_Keyword, MD_Validate_Required_Params, &
            MD_Validate_Parameter_Values
  
  ! ------------------------------------------------------------------
  ! ABAQUS keyword whitelist (commonly used keywords)
  ! ------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: N_VALID_KEYWORDS = 30_i4
  CHARACTER(len=32), PARAMETER :: VALID_KEYWORDS(N_VALID_KEYWORDS) = [ &
    "*PART              ", "*ASSEMBLY          ", "*MATERIAL          ", &
    "*ELASTIC           ", "*PLASTIC           ", "*DENSITY           ", &
    "*NODE              ", "*ELEMENT           ", "*NSET              ", &
    "*ELSET             ", "*SURFACE           ", "*CONTACT PAIR      ", &
    "*BOUNDARY          ", "*CLOAD             ", "*DLOAD             ", &
    "*AMPLITUDE         ", "*STEP              ", "*STATIC            ", &
    "*DYNAMIC           ", "*OUTPUT            ", "*FIELD OUTPUT      ", &
    "*HISTORY OUTPUT    ", "*PRINT             ", "*END STEP          ", &
    "*RESTART           ", "*INCLUDE           ", "*PREPRINT          ", &
    "*HEADING           ", "*COMMENT           ", "*PARAMETER         " &
  ]
  
  ! ------------------------------------------------------------------
  ! Parameter specification (required params per keyword)
  ! ------------------------------------------------------------------
  TYPE :: ParameterSpec_Type
    CHARACTER(len=32)  :: param_name    ! Parameter name
    LOGICAL            :: is_required   ! Whether required
    CHARACTER(len=256) :: valid_values  ! Valid values (comma-separated, empty=any)
  END TYPE ParameterSpec_Type
  
  ! *PART keyword: NAME required
  TYPE(ParameterSpec_Type), PARAMETER :: PART_PARAMS(1) = [ &
    ParameterSpec_Type("NAME", .TRUE., "") &
  ]
  
  ! *MATERIAL keyword: NAME required
  TYPE(ParameterSpec_Type), PARAMETER :: MATERIAL_PARAMS(1) = [ &
    ParameterSpec_Type("NAME", .TRUE., "") &
  ]
  
  ! *ELEMENT keyword: TYPE required
  TYPE(ParameterSpec_Type), PARAMETER :: ELEMENT_PARAMS(2) = [ &
    ParameterSpec_Type("TYPE", .TRUE., "C3D8,C3D4,S3R,S4R"), &
    ParameterSpec_Type("ELSET", .FALSE., "") &
  ]
  
  ! *NODE keyword: no required params
  TYPE(ParameterSpec_Type), PARAMETER :: NODE_PARAMS(1) = [ &
    ParameterSpec_Type("NSET", .FALSE., "") &
  ]
  
CONTAINS
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Is_Valid_Keyword
  ! PHASE      : P0
  ! PURPOSE    : Check whether a keyword exists in the whitelist.
  !              Returns status_code = 0 (valid) or 1 (invalid).
  ! ------------------------------------------------------------------
  
  SUBROUTINE MD_Is_Valid_Keyword(keyword, is_valid, status)
    CHARACTER(len=*), INTENT(IN) :: keyword
    LOGICAL, INTENT(OUT) :: is_valid
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    CHARACTER(len=32) :: kw_upper
    
    kw_upper = ADJUSTL(TRIM(keyword))
    CALL UPPERCASE_STRING(kw_upper)
    
    is_valid = .FALSE.
    
    ! Check whitelist
    DO i = 1, N_VALID_KEYWORDS
      IF (TRIM(ADJUSTL(kw_upper)) == TRIM(ADJUSTL(VALID_KEYWORDS(i)))) THEN
        is_valid = .TRUE.
        EXIT
      END IF
    END DO
    
    IF (is_valid) THEN
      status%status_code = 0_i4
    ELSE
      status%status_code = 1_i4
    END IF
    
  END SUBROUTINE MD_Is_Valid_Keyword
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Validate_Required_Params
  ! PHASE      : P0
  ! PURPOSE    : Verify that all required params are present.
  !              Returns status_code = 0 (valid) or 1 (missing).
  ! ------------------------------------------------------------------
  
  SUBROUTINE MD_Validate_Required_Params(keyword, param_count, status)
    CHARACTER(len=*), INTENT(IN) :: keyword
    INTEGER(i4), INTENT(IN) :: param_count
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=32) :: kw_upper
    LOGICAL :: requires_params
    
    kw_upper = ADJUSTL(TRIM(keyword))
    CALL UPPERCASE_STRING(kw_upper)
    
    requires_params = .FALSE.
    
    ! Check whether keyword requires mandatory params
    SELECT CASE (TRIM(kw_upper))
      CASE ("*PART")
        requires_params = .TRUE.
        IF (param_count < 1_i4) THEN
          status%status_code = 1_i4
          RETURN
        END IF
      
      CASE ("*MATERIAL")
        requires_params = .TRUE.
        IF (param_count < 1_i4) THEN
          status%status_code = 1_i4
          RETURN
        END IF
      
      CASE ("*ELEMENT")
        requires_params = .TRUE.
        IF (param_count < 1_i4) THEN
          status%status_code = 1_i4
          RETURN
        END IF
      
      CASE DEFAULT
        ! Other keywords have no required params
        status%status_code = 0_i4
        RETURN
    END SELECT
    
    status%status_code = 0_i4
    
  END SUBROUTINE MD_Validate_Required_Params
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Validate_Parameter_Values
  ! PHASE      : P0
  ! PURPOSE    : Validate parameter value against allowed set.
  !              Returns status_code = 0 (valid) or 1 (invalid).
  ! ------------------------------------------------------------------
  
  SUBROUTINE MD_Validate_Parameter_Values(keyword, param_name, param_value, status)
    CHARACTER(len=*), INTENT(IN) :: keyword, param_name, param_value
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=32) :: kw_upper, pn_upper
    LOGICAL :: is_valid_value
    
    kw_upper = ADJUSTL(TRIM(keyword))
    pn_upper = ADJUSTL(TRIM(param_name))
    CALL UPPERCASE_STRING(kw_upper)
    CALL UPPERCASE_STRING(pn_upper)
    
    is_valid_value = .FALSE.
    
    ! For *ELEMENT TYPE param, check against valid element types
    IF (TRIM(kw_upper) == "*ELEMENT" .AND. TRIM(pn_upper) == "TYPE") THEN
      SELECT CASE (TRIM(ADJUSTL(param_value)))
        CASE ("C3D8", "C3D4", "S3R", "S4R", "C3D6", "C3D10")
          is_valid_value = .TRUE.
        CASE DEFAULT
          is_valid_value = .FALSE.
      END SELECT
      
      IF (.NOT. is_valid_value) THEN
        status%status_code = 1_i4
        RETURN
      END IF
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE MD_Validate_Parameter_Values
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : UPPERCASE_STRING
  ! PURPOSE    : Convert string to uppercase in-place.
  ! ------------------------------------------------------------------
  
  SUBROUTINE UPPERCASE_STRING(str)
    CHARACTER(len=*), INTENT(INOUT) :: str
    INTEGER(i4) :: i, j
    
    DO i = 1, LEN_TRIM(str)
      j = IACHAR(str(i:i))
      IF (j >= IACHAR('a') .AND. j <= IACHAR('z')) THEN
        str(i:i) = ACHAR(j - IACHAR('a') + IACHAR('A'))
      END IF
    END DO
  END SUBROUTINE UPPERCASE_STRING

END MODULE MD_KeyWord_Validator