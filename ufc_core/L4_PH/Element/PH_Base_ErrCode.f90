!===============================================================================
! MODULE: PH_Base_ErrCode
! LAYER:  L4_PH
! DOMAIN: Element
! ROLE:   Proc
! BRIEF:  Physics layer specific error codes and categories
!===============================================================================
MODULE PH_Base_ErrCode
  USE IF_Err_Def, ONLY: i4
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! ERROR CATEGORIES (Layer-specific)
  !=============================================================================
  
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CATEGORY_ELEMENT = 14_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CATEGORY_CONTACT = 15_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CATEGORY_CONSTRAINT = 16_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CATEGORY_THERMAL  = 17_i4

  !=============================================================================
  ! ERROR CODES: 5000-5999 (Physics Layer)
  !=============================================================================
  
  ! Element errors: 5000-5099
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_ELEMENT_BASE = 5000_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_ELEMENT_INVALID_TYPE = 5001_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_ELEMENT_DEGENERATE = 5002_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_ELEMENT_JACOBIAN_NEGATIVE = 5003_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_ELEMENT_ZERO_VOLUME = 5004_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_ELEMENT_INVALID_SHAPE = 5005_i4
  
  ! Material behavior errors: 5100-5199
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_MATERIAL_BASE = 5100_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_MATERIAL_BEHAVIOR_FAILED = 5101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_MATERIAL_STATE_INVALID = 5102_i4
  
  ! Contact errors: 5200-5299
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_CONTACT_BASE = 5200_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_CONTACT_SEARCH_FAILED = 5201_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_CONTACT_PENETRATION = 5202_i4
  
  ! Constraint errors: 5300-5399
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_CONSTRAINT_BASE = 5300_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_CONSTRAINT_ENFORCEMENT_FAILED = 5301_i4
  
  ! Thermal errors: 5400-5499
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_THERMAL_BASE = 5400_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ERROR_CODE_THERMAL_INVALID_TEMPERATURE = 5401_i4

END MODULE PH_Base_ErrCode