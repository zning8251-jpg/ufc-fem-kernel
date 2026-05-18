!===============================================================================
! MODULE:  MD_Sect_PropNonStructMass
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Def
! BRIEF:   Nonstructural mass property (*NONSTRUCTURAL MASS) â€?Desc, parse, validate.
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Sect | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Section/CONTRACT.md

MODULE MD_Sect_PropNonStructMass
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, uf_set_error_status
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, UF_Model
    USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_DataLineType, KW_ParamValueType, &
                           KW_MAX_VALUE_LEN, KW_MAX_NAME_LEN
    IMPLICIT NONE
    PRIVATE

    ! Distribution type constants
    INTEGER(i4), PARAMETER, PUBLIC :: DIST_UNIFORM = 1
    INTEGER(i4), PARAMETER, PUBLIC :: DIST_USER    = 2

    !---------------------------------------------------------------------------
    ! TYPE:  NonStructMassDesc
    ! KIND:  Desc
    ! DESC:  Nonstructural mass entry â€?read-only definition record
    !---------------------------------------------------------------------------
    TYPE, PUBLIC, EXTENDS(DescBase) :: NonStructMassDesc
        INTEGER(i4) :: nonstructMassId = 0_i4
        CHARACTER(LEN=64) :: elsetName = ""
        INTEGER(i4) :: targetId = 0_i4
        REAL(wp) :: massPerVolume = 0.0_wp
        REAL(wp) :: massPerArea   = 0.0_wp
        REAL(wp) :: massPerLength = 0.0_wp
        REAL(wp) :: totalMass     = 0.0_wp
        INTEGER(i4) :: distributionType = 1_i4
        LOGICAL :: isActive = .TRUE.
        LOGICAL :: isValid  = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => NonStructMassDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure    => NonStructMassDesc_Ensure
        PROCEDURE, PUBLIC :: Init      => NonStructMassDesc_Init_Base
        PROCEDURE, PUBLIC :: Valid     => NonStructMassDesc_Valid_Fn
        PROCEDURE, PUBLIC :: Clear     => NonStructMassDesc_Clear
    END TYPE NonStructMassDesc

    !---------------------------------------------------------------------------
    ! TYPE:  NonStructMassManager
    ! KIND:  Ctx
    ! DESC:  Container managing a collection of NonStructMassDesc entries
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: NonStructMassManager
        INTEGER(i4) :: numNonstructMasses = 0_i4
        TYPE(NonStructMassDesc), ALLOCATABLE :: nonstructMasses(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add   => NonStructMassManager_Add
        PROCEDURE, PUBLIC :: Find  => NonStructMassManager_Find
        PROCEDURE, PUBLIC :: Clear => NonStructMassManager_Clear
    END TYPE NonStructMassManager

    ! Public exports
    PUBLIC :: NonStructMassDesc
    PUBLIC :: NonStructMassManager
    PUBLIC :: Parse_NONSTRUCTURALMASS_Keyword
    PUBLIC :: Parse_NONSTRUCTURALMASS_DataLine
    PUBLIC :: MD_Prop_NonstructuralMass_Unified_Parse
    PUBLIC :: MD_Prop_NonstructuralMass_Unified_Configure
    PUBLIC :: Validate_NONSTRUCTURALMASS_Keyword
    PUBLIC :: Validate_NONSTRUCTURALMASS_Elset
    PUBLIC :: Validate_NONSTRUCTURALMASS_PhysicalValues

CONTAINS

    !---------------------------------------------------------------------------
    ! SUBROUTINE: sect_prop_get_param_value
    ! PHASE:      P0
    ! PURPOSE:    Extract named parameter value from AST node
    !---------------------------------------------------------------------------
    SUBROUTINE sect_prop_get_param_value(ast_node, param_name, param_value)
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
    END SUBROUTINE sect_prop_get_param_value

    !---------------------------------------------------------------------------
    ! SUBROUTINE: NonStructMassDesc_RegLayout
    ! PHASE:      P0
    ! PURPOSE:    Register layout (placeholder)
    !---------------------------------------------------------------------------
    SUBROUTINE NonStructMassDesc_RegLayout(this)
        CLASS(NonStructMassDesc), INTENT(INOUT) :: this
    END SUBROUTINE NonStructMassDesc_RegLayout

    SUBROUTINE NonStructMassDesc_Ensure(this)
        CLASS(NonStructMassDesc), INTENT(INOUT) :: this
        IF (this%nonstructMassId == 0) this%nonstructMassId = 1
    END SUBROUTINE NonStructMassDesc_Ensure

    SUBROUTINE NonStructMassDesc_Init_Base(this)
        CLASS(NonStructMassDesc), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::NONSTRUCTURALMASS'
    END SUBROUTINE NonStructMassDesc_Init_Base

    SUBROUTINE NonStructMassDesc_Init(this, nonstructMassId, name, elsetName, &
                                      massPerVolume, massPerArea, massPerLength, &
                                      totalMass, status)
        CLASS(NonStructMassDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: nonstructMassId
        CHARACTER(LEN=*), INTENT(IN) :: name
        CHARACTER(LEN=*), INTENT(IN) :: elsetName
        REAL(wp), INTENT(IN), OPTIONAL :: massPerVolume, massPerArea, massPerLength, totalMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%nonstructMassId = nonstructMassId
        this%name     = TRIM(name)
        this%elsetName = TRIM(elsetName)
        IF (PRESENT(massPerVolume)) this%massPerVolume = massPerVolume
        IF (PRESENT(massPerArea))   this%massPerArea   = massPerArea
        IF (PRESENT(massPerLength)) this%massPerLength = massPerLength
        IF (PRESENT(totalMass))     this%totalMass     = totalMass
        this%isActive = .TRUE.
    END SUBROUTINE NonStructMassDesc_Init

    FUNCTION NonStructMassDesc_Valid_Fn(this) RESULT(ok)
        CLASS(NonStructMassDesc), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .FALSE.
        IF (LEN_TRIM(this%elsetName) == 0) RETURN
        IF (this%massPerVolume <= 0.0_wp .AND. this%massPerArea <= 0.0_wp .AND. &
            this%massPerLength <= 0.0_wp .AND. this%totalMass <= 0.0_wp) RETURN
        ok = .TRUE.
    END FUNCTION NonStructMassDesc_Valid_Fn

    SUBROUTINE NonStructMassDesc_Clear(this)
        CLASS(NonStructMassDesc), INTENT(INOUT) :: this
        this%nonstructMassId = 0
        this%name      = ""
        this%elsetName = ""
        this%targetId  = 0
        this%massPerVolume = 0.0_wp
        this%massPerArea   = 0.0_wp
        this%massPerLength = 0.0_wp
        this%totalMass     = 0.0_wp
        this%distributionType = DIST_UNIFORM
        this%isActive = .FALSE.
        this%isValid  = .FALSE.
    END SUBROUTINE NonStructMassDesc_Clear

    !---------------------------------------------------------------------------
    ! SUBROUTINE: NonStructMassManager_Add
    ! PHASE:      P0
    ! PURPOSE:    Add a nonstructural mass entry to the manager
    !---------------------------------------------------------------------------
    SUBROUTINE NonStructMassManager_Add(this, nonstructMass, status)
        CLASS(NonStructMassManager), INTENT(INOUT) :: this
        TYPE(NonStructMassDesc), INTENT(IN) :: nonstructMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(NonStructMassDesc), ALLOCATABLE :: temp_nonstructMasses(:)
        INTEGER(i4) :: new_id
        CALL init_error_status(status)
        IF (.NOT. ALLOCATED(this%nonstructMasses)) THEN
            ALLOCATE(this%nonstructMasses(10))
            this%numNonstructMasses = 0
        ELSE IF (this%numNonstructMasses >= SIZE(this%nonstructMasses)) THEN
            ALLOCATE(temp_nonstructMasses(SIZE(this%nonstructMasses) * 2))
            temp_nonstructMasses(1:this%numNonstructMasses) = this%nonstructMasses
            CALL MOVE_ALLOC(temp_nonstructMasses, this%nonstructMasses)
        END IF
        new_id = this%numNonstructMasses + 1
        this%numNonstructMasses = new_id
        this%nonstructMasses(new_id) = nonstructMass
        this%nonstructMasses(new_id)%nonstructMassId = new_id
    END SUBROUTINE NonStructMassManager_Add

    FUNCTION NonStructMassManager_Find(this, name) RESULT(nonstructMass)
        CLASS(NonStructMassManager), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(NonStructMassDesc), POINTER :: nonstructMass
        INTEGER(i4) :: i
        nonstructMass => NULL()
        IF (.NOT. ALLOCATED(this%nonstructMasses)) RETURN
        DO i = 1, this%numNonstructMasses
            IF (TRIM(this%nonstructMasses(i)%name) == TRIM(name)) THEN
                nonstructMass => this%nonstructMasses(i)
                RETURN
            END IF
        END DO
    END FUNCTION NonStructMassManager_Find

    SUBROUTINE NonStructMassManager_Clear(this)
        CLASS(NonStructMassManager), INTENT(INOUT) :: this
        IF (ALLOCATED(this%nonstructMasses)) DEALLOCATE(this%nonstructMasses)
        this%numNonstructMasses = 0
    END SUBROUTINE NonStructMassManager_Clear

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_Prop_NonstructuralMass_Unified_Configure
    ! PHASE:      P0
    ! PURPOSE:    Configure nonstructural mass property parser
    !---------------------------------------------------------------------------
    SUBROUTINE MD_Prop_NonstructuralMass_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Prop_NonstructuralMass_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Prop_NonstructuralMass_Unified_Configure

    SUBROUTINE MD_Prop_NonstructuralMass_Unified_Parse(prop_type, ast_node, nonstructMass, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: prop_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(NonStructMassDesc), INTENT(OUT) :: nonstructMass
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(prop_type) == 'NONSTRUCTURAL_MASS' .OR. TRIM(prop_type) == 'NONSTRUCTURAL MASS') THEN
            CALL Parse_NONSTRUCTURALMASS_Keyword(ast_node, nonstructMass, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Prop_NonstructuralMass_Unified_Parse: unsupported prop_type ' // TRIM(prop_type)
        END IF
    END SUBROUTINE MD_Prop_NonstructuralMass_Unified_Parse

    SUBROUTINE Parse_NONSTRUCTURALMASS_DataLine(data_line, mass_value, status)
        TYPE(KW_DataLineType), INTENT(IN) :: data_line
        REAL(wp), INTENT(OUT) :: mass_value
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (data_line%col_count < 1) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "*NONSTRUCTURAL MASS data line requires at least 1 value: mass_value")
            RETURN
        END IF
        mass_value = data_line%real_values(1)
        IF (mass_value <= 0.0_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "Mass value must be positive")
            RETURN
        END IF
    END SUBROUTINE Parse_NONSTRUCTURALMASS_DataLine

    SUBROUTINE Parse_NONSTRUCTURALMASS_Keyword(ast_node, nonstructMass, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(NonStructMassDesc), INTENT(OUT) :: nonstructMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, type_str
        REAL(wp) :: mass_value
        LOGICAL :: has_elset, has_type
        CALL init_error_status(status)
        CALL nonstructMass%Clear()
        CALL sect_prop_get_param_value(ast_node, "ELSET", elset_name)
        has_elset = (LEN_TRIM(elset_name) > 0)
        CALL sect_prop_get_param_value(ast_node, "TYPE", type_str)
        has_type = (LEN_TRIM(type_str) > 0)
        IF (has_type) THEN
            IF (TRIM(type_str) == "USER") THEN
                nonstructMass%distributionType = DIST_USER
            ELSE
                nonstructMass%distributionType = DIST_UNIFORM
            END IF
        END IF
        IF (ast_node%data_line_count < 1) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "*NONSTRUCTURAL MASS requires at least one data line")
            RETURN
        END IF
        CALL Parse_NONSTRUCTURALMASS_DataLine(ast_node%data_lines(1), mass_value, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        nonstructMass%name = "NONSTRUCTMASS"
        IF (has_elset) THEN
            nonstructMass%elsetName = TRIM(elset_name)
            nonstructMass%name = "NONSTRUCTMASS-" // TRIM(elset_name)
        END IF
        nonstructMass%massPerVolume = mass_value
        IF (.NOT. nonstructMass%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Nonstructural mass validation failed"
        END IF
    END SUBROUTINE Parse_NONSTRUCTURALMASS_Keyword

    !---------------------------------------------------------------------------
    ! SUBROUTINE: Validate_NONSTRUCTURALMASS_Elset
    ! PHASE:      P0
    ! PURPOSE:    Validate element set reference for nonstructural mass
    !---------------------------------------------------------------------------
    SUBROUTINE Validate_NONSTRUCTURALMASS_Elset(nonstructMass, model, status)
        TYPE(NonStructMassDesc), INTENT(IN) :: nonstructMass
        TYPE(UF_Model), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, part_idx
        LOGICAL :: elset_found
        CALL init_error_status(status)
        elset_found = .FALSE.
        DO part_idx = 1, SIZE(model%parts)
            IF (ALLOCATED(model%parts(part_idx)%elemSets)) THEN
                DO i = 1, SIZE(model%parts(part_idx)%elemSets)
                    IF (TRIM(model%parts(part_idx)%elemSets(i)%name) == &
                        TRIM(nonstructMass%elsetName)) THEN
                        elset_found = .TRUE.
                        EXIT
                    END IF
                END DO
            END IF
            IF (elset_found) EXIT
        END DO
        IF (.NOT. elset_found) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Element set '" // TRIM(nonstructMass%elsetName) // &
                "' not found for *NONSTRUCTURAL MASS")
        END IF
    END SUBROUTINE Validate_NONSTRUCTURALMASS_Elset

    SUBROUTINE Validate_NONSTRUCTURALMASS_Keyword(nonstructMass, model, status)
        TYPE(NonStructMassDesc), INTENT(IN) :: nonstructMass
        TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. nonstructMass%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Nonstructural mass validation failed"
            RETURN
        END IF
        IF (PRESENT(model)) THEN
            CALL Validate_NONSTRUCTURALMASS_Elset(nonstructMass, model, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
        CALL Validate_NONSTRUCTURALMASS_PhysicalValues(nonstructMass, status)
    END SUBROUTINE Validate_NONSTRUCTURALMASS_Keyword

    SUBROUTINE Validate_NONSTRUCTURALMASS_PhysicalValues(nonstructMass, status)
        TYPE(NonStructMassDesc), INTENT(IN) :: nonstructMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (nonstructMass%massPerVolume > 0.0_wp) THEN
            IF (nonstructMass%massPerVolume < 1.0e-3_wp .OR. &
                nonstructMass%massPerVolume > 1.0e4_wp) THEN
                CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                    "Mass per volume out of reasonable range (1e-3 to 1e4 kg/m3)")
                RETURN
            END IF
        END IF
        IF (nonstructMass%massPerArea > 0.0_wp) THEN
            IF (nonstructMass%massPerArea < 1.0e-3_wp .OR. &
                nonstructMass%massPerArea > 1.0e3_wp) THEN
                CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                    "Mass per area out of reasonable range (1e-3 to 1e3 kg/m2)")
                RETURN
            END IF
        END IF
        IF (nonstructMass%massPerLength > 0.0_wp) THEN
            IF (nonstructMass%massPerLength < 1.0e-3_wp .OR. &
                nonstructMass%massPerLength > 1.0e3_wp) THEN
                CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                    "Mass per length out of reasonable range (1e-3 to 1e3 kg/m)")
                RETURN
            END IF
        END IF
    END SUBROUTINE Validate_NONSTRUCTURALMASS_PhysicalValues

END MODULE MD_Sect_PropNonStructMass