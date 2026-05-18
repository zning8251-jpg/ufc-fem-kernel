!===============================================================================
! MODULE: MD_Mat_Plast_RateDep
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Impl
! BRIEF:  Plastic family implementation -- MD_Mat_Plast_RateDep.
! **W1**：**props** / **`MD_Mat_Desc`/`cfg%id`** / **Populate** → L4 **`desc%props`** / **`UF_Plastic_Eval_Dispatch_FromDesc`** / **`PH_MatPlast_*`**（**267**）。
!===============================================================================
MODULE MD_Mat_Plast_RateDep
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, uf_set_error_status
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, UF_Model
  USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_MAX_NAME_LEN, KW_MAX_VALUE_LEN
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MAT_CATEGORY_PL
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_RATE_DEPENDENT_PLAST_MAT_ID = 267_i4

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_RATE_TYPE_POWER_LAW = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_RATE_TYPE_JOHNSON_COOK = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_RATE_TYPE_STRAIN = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_RATE_TYPE_TIME = 2_i4

  INTEGER(i4), PARAMETER :: MD_MAT_RD_PROP_E = 1_i4
  INTEGER(i4), PARAMETER :: MD_MAT_RD_PROP_NU = 2_i4
  INTEGER(i4), PARAMETER :: MD_MAT_RD_PROP_SY0 = 3_i4
  INTEGER(i4), PARAMETER :: MD_MAT_RD_PROP_M_RATE = 4_i4
  INTEGER(i4), PARAMETER :: MD_MAT_RD_PROP_C_RATE = 5_i4
  INTEGER(i4), PARAMETER :: MD_MAT_RD_MIN_PROPS = 5_i4
  REAL(wp), PARAMETER :: MD_MAT_RD_ZERO = 0.0_wp
  REAL(wp), PARAMETER :: MD_MAT_RD_ONE = 1.0_wp
  REAL(wp), PARAMETER :: MD_MAT_RD_TWO = 2.0_wp
  REAL(wp), PARAMETER :: MD_MAT_RD_HALF = 0.5_wp
  REAL(wp), PARAMETER :: MD_MAT_RD_THREE = 3.0_wp

  TYPE, PUBLIC, EXTENDS(DescBase) :: RateDependentProperties
    INTEGER(i4) :: rateType = 1_i4
    INTEGER(i4) :: modelType = 1_i4
    REAL(wp) :: D = 0.0_wp
    REAL(wp) :: n = 0.0_wp
    REAL(wp) :: epsilon_dot_0 = 1.0_wp
    REAL(wp) :: A = 0.0_wp
    REAL(wp) :: B = 0.0_wp
    REAL(wp) :: C = 0.0_wp
    REAL(wp) :: m = 0.0_wp
    REAL(wp) :: T_melt = 0.0_wp
    REAL(wp) :: T_transition = 0.0_wp
    INTEGER(i4) :: dependencies = 0
    REAL(wp), ALLOCATABLE :: tempData(:)
    REAL(wp), ALLOCATABLE :: fieldVarData(:,:)
    INTEGER(i4) :: nDataPoints = 0
  CONTAINS
    GENERIC, PUBLIC :: Init => RateDependentProperties_Init_Base, RateDependentProperties_Init
    PROCEDURE, PUBLIC :: Valid => RateDependentProperties_Valid_Fn
    PROCEDURE, PUBLIC :: Clear => RateDependentProperties_Clear
    PROCEDURE, PUBLIC :: ComputeRateFactor => RateDependentProperties_ComputeRateFactor
    PROCEDURE, PUBLIC :: ComputeStress => RateDependentProperties_ComputeStress
  END TYPE RateDependentProperties

  TYPE, PUBLIC :: RateDependentPropertiesManager
    INTEGER(i4) :: numProperties = 0_i4
    TYPE(RateDependentProperties), ALLOCATABLE :: properties(:)
  CONTAINS
    PROCEDURE, PUBLIC :: Add => RateDependentPropertiesManager_Add
    PROCEDURE, PUBLIC :: Find => RateDependentPropertiesManager_Find
    PROCEDURE, PUBLIC :: Clear => RateDependentPropertiesManager_Clear
  END TYPE RateDependentPropertiesManager

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: RateDepPlast_MatDesc
    REAL(wp) :: E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: sy0 = 0.0_wp
    REAL(wp) :: m_rate = 0.0_wp
    REAL(wp) :: C_rate = 0.0_wp
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: InitFromProps => RateDepPlast_MatDesc_InitFromProps
    PROCEDURE, PUBLIC :: Valid => RateDepPlast_MatDesc_Valid
  END TYPE RateDepPlast_MatDesc

  PUBLIC :: RateDependentProperties, RateDependentPropertiesManager
  PUBLIC :: MD_Mat_RateDependent_Unified_Configure, MD_Mat_RateDependent_Unified_Parse
  PUBLIC :: Parse_RATE_DEPENDENT_Keyword
  PUBLIC :: Valid_RATE_DEPENDENT_Keyword, Valid_RATE_DEPENDENT_Mat, Validate_RATE_DEPENDENT_PhysicalValues
  PUBLIC :: UF_RateDepPlast_ValidateProps

CONTAINS

  SUBROUTINE RateDependentProperties_Init_Base(this)
    CLASS(RateDependentProperties), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    this%algo_type_name = 'DESC::RATEDEPENDENT'
  END SUBROUTINE RateDependentProperties_Init_Base

  SUBROUTINE RateDependentProperties_Init(this, modelType, status)
    CLASS(RateDependentProperties), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: modelType
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    CALL this%Init()
    IF (modelType /= MD_MAT_RATE_TYPE_POWER_LAW .AND. modelType /= MD_MAT_RATE_TYPE_JOHNSON_COOK) THEN
      CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "Invalid rate dependent model type")
      RETURN
    END IF
    this%modelType = modelType
    this%rateType = MD_MAT_RATE_TYPE_STRAIN
    this%dependencies = 0
  END SUBROUTINE RateDependentProperties_Init

  FUNCTION RateDependentProperties_Valid_Fn(this) RESULT(ok)
    CLASS(RateDependentProperties), INTENT(IN) :: this
    LOGICAL :: ok
    ok = .FALSE.
    IF (this%modelType == MD_MAT_RATE_TYPE_POWER_LAW) THEN
      IF (this%D < 0.0_wp) RETURN
      IF (this%n < 0.0_wp) RETURN
      IF (this%epsilon_dot_0 <= 0.0_wp) RETURN
    ELSE IF (this%modelType == MD_MAT_RATE_TYPE_JOHNSON_COOK) THEN
      IF (this%A <= 0.0_wp) RETURN
      IF (this%T_melt <= 0.0_wp) RETURN
    END IF
    ok = .TRUE.
  END FUNCTION RateDependentProperties_Valid_Fn

  SUBROUTINE RateDependentProperties_Clear(this)
    CLASS(RateDependentProperties), INTENT(INOUT) :: this
    this%rateType = MD_MAT_RATE_TYPE_STRAIN
    this%modelType = MD_MAT_RATE_TYPE_POWER_LAW
    this%D = 0.0_wp
    this%n = 0.0_wp
    this%epsilon_dot_0 = 1.0_wp
    this%A = 0.0_wp
    this%B = 0.0_wp
    this%C = 0.0_wp
    this%m = 0.0_wp
    this%T_melt = 0.0_wp
    this%T_transition = 0.0_wp
    this%dependencies = 0
    this%nDataPoints = 0
    IF (ALLOCATED(this%tempData)) DEALLOCATE(this%tempData)
    IF (ALLOCATED(this%fieldVarData)) DEALLOCATE(this%fieldVarData)
  END SUBROUTINE RateDependentProperties_Clear

  FUNCTION RateDependentProperties_ComputeRateFactor(this, strainRate) RESULT(factor)
    CLASS(RateDependentProperties), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: strainRate
    REAL(wp) :: factor
    REAL(wp) :: rate_ratio
    factor = 1.0_wp
    IF (this%modelType == MD_MAT_RATE_TYPE_POWER_LAW) THEN
      IF (this%epsilon_dot_0 > 1.0e-10_wp) THEN
        rate_ratio = strainRate / this%epsilon_dot_0
        factor = 1.0_wp + this%D * (rate_ratio ** this%n)
      END IF
    ELSE IF (this%modelType == MD_MAT_RATE_TYPE_JOHNSON_COOK) THEN
      IF (this%epsilon_dot_0 > 1.0e-10_wp .AND. strainRate > 1.0e-10_wp) THEN
        rate_ratio = strainRate / this%epsilon_dot_0
        IF (rate_ratio > 1.0e-10_wp) THEN
          factor = 1.0_wp + this%C * LOG(rate_ratio)
        END IF
      END IF
    END IF
  END FUNCTION RateDependentProperties_ComputeRateFactor

  FUNCTION RateDependentProperties_ComputeStress(this, strain, strainRate, temperature) RESULT(stress)
    CLASS(RateDependentProperties), INTENT(IN) :: this
    REAL(wp), INTENT(IN) :: strain, strainRate
    REAL(wp), INTENT(IN), OPTIONAL :: temperature
    REAL(wp) :: stress
    REAL(wp) :: rate_factor, temp_factor, base_stress
    IF (this%modelType == MD_MAT_RATE_TYPE_POWER_LAW) THEN
      base_stress = 1.0e6_wp
    ELSE
      base_stress = this%A + this%B * (strain ** this%n)
    END IF
    rate_factor = this%ComputeRateFactor(strainRate)
    temp_factor = 1.0_wp
    IF (this%modelType == MD_MAT_RATE_TYPE_JOHNSON_COOK .AND. PRESENT(temperature)) THEN
      IF (this%T_melt > this%T_transition) THEN
        temp_factor = 1.0_wp - ((temperature - this%T_transition) / &
            (this%T_melt - this%T_transition)) ** this%m
        temp_factor = MAX(0.0_wp, temp_factor)
      END IF
    END IF
    stress = base_stress * rate_factor * temp_factor
  END FUNCTION RateDependentProperties_ComputeStress

  SUBROUTINE RateDependentPropertiesManager_Add(this, prop, status)
    CLASS(RateDependentPropertiesManager), INTENT(INOUT) :: this
    TYPE(RateDependentProperties), INTENT(IN) :: prop
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(RateDependentProperties), ALLOCATABLE :: temp_props(:)
    INTEGER(i4) :: new_id
    CALL init_error_status(status)
    IF (.NOT. ALLOCATED(this%properties)) THEN
      ALLOCATE(this%properties(10))
      this%numProperties = 0
    ELSE IF (this%numProperties >= SIZE(this%properties)) THEN
      ALLOCATE(temp_props(SIZE(this%properties) * 2))
      temp_props(1:this%numProperties) = this%properties
      CALL MOVE_ALLOC(temp_props, this%properties)
    END IF
    new_id = this%numProperties + 1
    this%numProperties = new_id
    this%properties(new_id) = prop
  END SUBROUTINE RateDependentPropertiesManager_Add

  FUNCTION RateDependentPropertiesManager_Find(this, index) RESULT(prop)
    CLASS(RateDependentPropertiesManager), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: index
    TYPE(RateDependentProperties), POINTER :: prop
    prop => NULL()
    IF (.NOT. ALLOCATED(this%properties)) RETURN
    IF (index < 1 .OR. index > this%numProperties) RETURN
    prop => this%properties(index)
  END FUNCTION RateDependentPropertiesManager_Find

  SUBROUTINE RateDependentPropertiesManager_Clear(this)
    CLASS(RateDependentPropertiesManager), INTENT(INOUT) :: this
    INTEGER(i4) :: i
    IF (ALLOCATED(this%properties)) THEN
      DO i = 1, this%numProperties
        CALL this%properties(i)%Clear()
      END DO
      DEALLOCATE(this%properties)
    END IF
    this%numProperties = 0
  END SUBROUTINE RateDependentPropertiesManager_Clear

  SUBROUTINE md_mat_rate_get_param(ast_node, param_name, param_value)
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    CHARACTER(LEN=*), INTENT(IN) :: param_name
    CHARACTER(LEN=*), INTENT(OUT) :: param_value
    INTEGER(i4) :: i
    CHARACTER(LEN=KW_MAX_NAME_LEN) :: key
    param_value = ""
    DO i = 1, ast_node%param_count
      key = TRIM(ast_node%params(i)%name)
      IF (TRIM(key) == TRIM(param_name)) THEN
        param_value = TRIM(ast_node%params(i)%value)
        RETURN
      END IF
    END DO
  END SUBROUTINE md_mat_rate_get_param

  SUBROUTINE MD_Mat_RateDependent_Unified_Configure(operation, status)
    CHARACTER(LEN=*), INTENT(IN) :: operation
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
        TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
      CONTINUE
    ELSE
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_Mat_RateDependent_Unified_Configure: unknown operation ' // TRIM(operation)
    END IF
  END SUBROUTINE MD_Mat_RateDependent_Unified_Configure

  SUBROUTINE MD_Mat_RateDependent_Unified_Parse(material_type, ast_node, rateDep, material_name, status)
    CHARACTER(LEN=*), INTENT(IN) :: material_type
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    TYPE(RateDependentProperties), INTENT(OUT) :: rateDep
    CHARACTER(LEN=*), INTENT(IN) :: material_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (TRIM(material_type) == 'MD_MAT_RATE_DEPENDENT' .OR. TRIM(material_type) == 'RATE DEPENDENT') THEN
      CALL Parse_RATE_DEPENDENT_Keyword(ast_node, rateDep, material_name, status)
    ELSE
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_Mat_RateDependent_Unified_Parse: unsupported material_type ' // TRIM(material_type)
    END IF
  END SUBROUTINE MD_Mat_RateDependent_Unified_Parse

  SUBROUTINE Parse_RATE_DEPENDENT_Keyword(ast_node, rateDep, material_name, status)
    TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
    TYPE(RateDependentProperties), INTENT(OUT) :: rateDep
    CHARACTER(LEN=*), INTENT(IN) :: material_name
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CHARACTER(LEN=KW_MAX_VALUE_LEN) :: type_str, dependencies_str
    INTEGER(i4) :: model_type, dependencies, i, data_line_count

    CALL init_error_status(status)
    CALL rateDep%Clear()
    CALL md_mat_rate_get_param(ast_node, "TYPE", type_str)
    IF (LEN_TRIM(type_str) == 0) THEN
      model_type = MD_MAT_RATE_TYPE_POWER_LAW
    ELSE
      SELECT CASE (TRIM(type_str))
      CASE ("POWER LAW", "POWERLAW")
        model_type = MD_MAT_RATE_TYPE_POWER_LAW
      CASE ("JOHNSON COOK", "JOHNSONCOOK", "JC")
        model_type = MD_MAT_RATE_TYPE_JOHNSON_COOK
      CASE DEFAULT
        model_type = MD_MAT_RATE_TYPE_POWER_LAW
      END SELECT
    END IF

    CALL RateDependentProperties_Init(rateDep, model_type, status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    CALL md_mat_rate_get_param(ast_node, "DEPENDENCIES", dependencies_str)
    IF (LEN_TRIM(dependencies_str) > 0) THEN
      READ(dependencies_str, *, IOSTAT=i) dependencies
      IF (i /= 0) dependencies = 0
    ELSE
      dependencies = 0
    END IF
    rateDep%dependencies = dependencies

    data_line_count = ast_node%data_line_count
    IF (data_line_count < 1) THEN
      CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "*RATE DEPENDENT requires at least one data line")
      RETURN
    END IF

    IF (model_type == MD_MAT_RATE_TYPE_POWER_LAW) THEN
      IF (ast_node%data_lines(1)%col_count < 3) THEN
        CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "*RATE DEPENDENT POWER LAW requires: D, n, epsilon_dot_0")
        RETURN
      END IF
      rateDep%D = ast_node%data_lines(1)%real_values(1)
      rateDep%n = ast_node%data_lines(1)%real_values(2)
      rateDep%epsilon_dot_0 = ast_node%data_lines(1)%real_values(3)
    ELSE IF (model_type == MD_MAT_RATE_TYPE_JOHNSON_COOK) THEN
      IF (ast_node%data_lines(1)%col_count < 7) THEN
        CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "*RATE DEPENDENT JOHNSON COOK requires at least 7 parameters")
        RETURN
      END IF
      rateDep%A = ast_node%data_lines(1)%real_values(1)
      rateDep%B = ast_node%data_lines(1)%real_values(2)
      rateDep%n = ast_node%data_lines(1)%real_values(3)
      rateDep%C = ast_node%data_lines(1)%real_values(4)
      rateDep%m = ast_node%data_lines(1)%real_values(5)
      rateDep%T_melt = ast_node%data_lines(1)%real_values(6)
      IF (ast_node%data_lines(1)%col_count >= 7) THEN
        rateDep%T_transition = ast_node%data_lines(1)%real_values(7)
      END IF
      IF (ast_node%data_lines(1)%col_count >= 8) THEN
        rateDep%epsilon_dot_0 = ast_node%data_lines(1)%real_values(8)
      ELSE
        rateDep%epsilon_dot_0 = 1.0_wp
      END IF
    END IF

    IF (.NOT. rateDep%Valid()) THEN
      CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "Rate dependent validation failed")
      RETURN
    END IF
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE Parse_RATE_DEPENDENT_Keyword

  SUBROUTINE Validate_RATE_DEPENDENT_PhysicalValues(rateDep, status)
    TYPE(RateDependentProperties), INTENT(IN) :: rateDep
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (rateDep%modelType == MD_MAT_RATE_TYPE_POWER_LAW) THEN
      IF (rateDep%D < 0.0_wp .OR. rateDep%D > 10.0_wp) THEN
        CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "Power law coef D out of reasonable range (0 to 10)")
        RETURN
      END IF
      IF (rateDep%n < 0.0_wp .OR. rateDep%n > 5.0_wp) THEN
        CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "Power law exponent n out of reasonable range (0 to 5)")
        RETURN
      END IF
      IF (rateDep%epsilon_dot_0 < 1.0e-6_wp .OR. rateDep%epsilon_dot_0 > 1.0e6_wp) THEN
        CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "Reference strain rate out of reasonable range (1e-6 to 1e6 1/s)")
        RETURN
      END IF
    ELSE IF (rateDep%modelType == MD_MAT_RATE_TYPE_JOHNSON_COOK) THEN
      IF (rateDep%A < 1.0e5_wp .OR. rateDep%A > 1.0e9_wp) THEN
        CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "Johnson-Cook parameter A out of reasonable range (1e5 to 1e9 Pa)")
        RETURN
      END IF
      IF (rateDep%T_melt < 273.15_wp .OR. rateDep%T_melt > 5000.0_wp) THEN
        CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "Melting temperature out of reasonable range (273 to 5000 K)")
        RETURN
      END IF
    END IF
  END SUBROUTINE Validate_RATE_DEPENDENT_PhysicalValues

  SUBROUTINE Valid_RATE_DEPENDENT_Keyword(rateDep, material_name, model, status)
    TYPE(RateDependentProperties), INTENT(IN) :: rateDep
    CHARACTER(LEN=*), INTENT(IN) :: material_name
    TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (.NOT. rateDep%Valid()) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Rate dependent validation failed"
      RETURN
    END IF
    IF (PRESENT(model)) THEN
      CALL Valid_RATE_DEPENDENT_Mat(material_name, model, status)
      IF (status%status_code /= MD_MAT_STATUS_OK) RETURN
    END IF
    CALL Validate_RATE_DEPENDENT_PhysicalValues(rateDep, status)
  END SUBROUTINE Valid_RATE_DEPENDENT_Keyword

  SUBROUTINE Valid_RATE_DEPENDENT_Mat(material_name, model, status)
    CHARACTER(LEN=*), INTENT(IN) :: material_name
    TYPE(UF_Model), INTENT(IN) :: model
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    IF (LEN_TRIM(material_name) == 0) THEN
      CALL uf_set_error_status(status, MD_MAT_STATUS_INVALID, "Mat name must be specified for RATE DEPENDENT")
    END IF
  END SUBROUTINE Valid_RATE_DEPENDENT_Mat

  SUBROUTINE UF_RateDepPlast_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (nprops < MD_MAT_RD_MIN_PROPS) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "RateDep (267): need 5 props (E,nu,sy0,m_rate,C_rate) per PH_Mat_Reg_Core."
      RETURN
    END IF
    IF (props(MD_MAT_RD_PROP_E) <= MD_MAT_RD_ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "RateDep: E must be positive."
      RETURN
    END IF
    IF (props(MD_MAT_RD_PROP_NU) < -MD_MAT_RD_ONE .OR. props(MD_MAT_RD_PROP_NU) >= MD_MAT_RD_HALF) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "RateDep: Poisson's ratio must be in [-1, 0.5)."
      RETURN
    END IF
    IF (props(MD_MAT_RD_PROP_SY0) <= MD_MAT_RD_ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "RateDep: sy0 must be positive."
      RETURN
    END IF
    IF (props(MD_MAT_RD_PROP_M_RATE) < MD_MAT_RD_ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "RateDep: m_rate must be non-negative."
      RETURN
    END IF
    IF (props(MD_MAT_RD_PROP_C_RATE) < MD_MAT_RD_ZERO) THEN
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "RateDep: C_rate must be non-negative."
      RETURN
    END IF
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE UF_RateDepPlast_ValidateProps

  SUBROUTINE RateDepPlast_MatDesc_InitFromProps(this, props, nprops, status)
    CLASS(RateDepPlast_MatDesc), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: nch
    CHARACTER(LEN=*), PARAMETER :: rd_name = "PlasticRateDep"

    CALL init_error_status(status)
    CALL UF_RateDepPlast_ValidateProps(props, nprops, status)
    IF (status%status_code /= MD_MAT_STATUS_OK) RETURN

    this%E = props(MD_MAT_RD_PROP_E)
    this%nu = props(MD_MAT_RD_PROP_NU)
    this%sy0 = props(MD_MAT_RD_PROP_SY0)
    this%m_rate = props(MD_MAT_RD_PROP_M_RATE)
    this%C_rate = props(MD_MAT_RD_PROP_C_RATE)

    this%cfg%id = MD_MAT_RATE_DEPENDENT_PLAST_MAT_ID
    nch = INT(LEN_TRIM(rd_name), KIND=i4)
    IF (nch > 32_i4) nch = 32_i4
    this%cfg%materialType = rd_name(1:nch)
    this%cfg%class_id = MD_MAT_CATEGORY_PL
    this%pop%nProps = nprops
    this%pop%nStateV = 7_i4

    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    ALLOCATE(this%props(nprops))
    this%props = props(1:nprops)
    this%init = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE RateDepPlast_MatDesc_InitFromProps

  FUNCTION RateDepPlast_MatDesc_Valid(this) RESULT(ok)
    CLASS(RateDepPlast_MatDesc), INTENT(IN) :: this
    LOGICAL :: ok

    ok = this%init .AND. this%E > MD_MAT_RD_ZERO .AND. this%sy0 > MD_MAT_RD_ZERO
  END FUNCTION RateDepPlast_MatDesc_Valid

END MODULE MD_Mat_Plast_RateDep

