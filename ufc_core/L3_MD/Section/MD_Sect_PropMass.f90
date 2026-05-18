!===============================================================================
! MODULE:  MD_Sect_PropMass
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Def
! BRIEF:   Point mass property (*MASS) ?Desc types, parse and validate.
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Sect | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Section/CONTRACT.md

MODULE MD_Sect_PropMass
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, uf_set_error_status
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, UF_Model
    USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_DataLineType, KW_ParamValueType, &
                           KW_MAX_VALUE_LEN, KW_MAX_NAME_LEN
    IMPLICIT NONE
    PRIVATE

    !---------------------------------------------------------------------------
    ! TYPE:  PtMassDesc
    ! KIND:  Desc
    ! DESC:  Single point mass entry ?read-only definition record
    !---------------------------------------------------------------------------
    TYPE, PUBLIC, EXTENDS(DescBase) :: PtMassDesc
        INTEGER(i4) :: massId = 0_i4
        INTEGER(i4) :: nodeId = 0_i4
        CHARACTER(LEN=64) :: elsetName = ""
        INTEGER(i4) :: targetId = 0_i4
        REAL(wp) :: mass = 0.0_wp
        REAL(wp) :: alpha = 0.0_wp
        LOGICAL :: isActive = .TRUE.
        LOGICAL :: isValid = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => PtMassDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure    => PtMassDesc_Ensure
        PROCEDURE, PUBLIC :: Init      => PtMassDesc_Init_Base
        PROCEDURE, PUBLIC :: Valid     => PtMassDesc_Valid_Fn
        PROCEDURE, PUBLIC :: Clear     => PtMassDesc_Clear
    END TYPE PtMassDesc

    !---------------------------------------------------------------------------
    ! TYPE:  PtMassManager
    ! KIND:  Ctx
    ! DESC:  Container managing a collection of PtMassDesc entries
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: PtMassManager
        INTEGER(i4) :: numMasses = 0_i4
        TYPE(PtMassDesc), ALLOCATABLE :: masses(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add        => PtMassManager_Add
        PROCEDURE, PUBLIC :: Find       => PtMassManager_Find
        PROCEDURE, PUBLIC :: FindByNode => PtMassManager_FindByNode
        PROCEDURE, PUBLIC :: Clear      => PtMassManager_Clear
    END TYPE PtMassManager

    ! Public exports
    PUBLIC :: PtMassDesc
    PUBLIC :: PtMassManager
    PUBLIC :: Parse_MASS_Keyword
    PUBLIC :: Parse_MASS_DataLine
    PUBLIC :: MD_Prop_Mass_Unified_Parse
    PUBLIC :: MD_Prop_Mass_Unified_Cfg
    PUBLIC :: Valid_MASS_Keyword
    PUBLIC :: Valid_MASS_Node
    PUBLIC :: Valid_MASS_PhysicalValues

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

    FUNCTION sect_prop_int_to_str(i) RESULT(str)
        INTEGER(i4), INTENT(IN) :: i
        CHARACTER(LEN=16) :: str
        WRITE(str, '(I0)') i
    END FUNCTION sect_prop_int_to_str

    !---------------------------------------------------------------------------
    ! SUBROUTINE: PtMassDesc_RegLayout
    ! PHASE:      P0
    ! PURPOSE:    Register layout (placeholder)
    !---------------------------------------------------------------------------
    SUBROUTINE PtMassDesc_RegLayout(this)
        CLASS(PtMassDesc), INTENT(INOUT) :: this
    END SUBROUTINE PtMassDesc_RegLayout

    SUBROUTINE PtMassDesc_Ensure(this)
        CLASS(PtMassDesc), INTENT(INOUT) :: this
        IF (this%massId == 0) this%massId = 1
    END SUBROUTINE PtMassDesc_Ensure

    SUBROUTINE PtMassDesc_Init_Base(this)
        CLASS(PtMassDesc), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::MASS'
    END SUBROUTINE PtMassDesc_Init_Base

    SUBROUTINE PtMassDesc_Init(this, massId, name, nodeId, mass, alpha, status)
        CLASS(PtMassDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: massId
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: nodeId
        REAL(wp), INTENT(IN) :: mass
        REAL(wp), INTENT(IN), OPTIONAL :: alpha
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%massId = massId
        this%name = TRIM(name)
        this%nodeId = nodeId
        this%mass = mass
        IF (PRESENT(alpha)) this%alpha = alpha
        this%isActive = .TRUE.
    END SUBROUTINE PtMassDesc_Init

    FUNCTION PtMassDesc_Valid_Fn(this) RESULT(ok)
        CLASS(PtMassDesc), INTENT(IN) :: this
        LOGICAL :: ok
        ok = (this%nodeId > 0) .AND. (this%mass > 0.0_wp)
    END FUNCTION PtMassDesc_Valid_Fn

    SUBROUTINE PtMassDesc_Clear(this)
        CLASS(PtMassDesc), INTENT(INOUT) :: this
        this%massId = 0
        this%name = ""
        this%nodeId = 0
        this%elsetName = ""
        this%targetId = 0
        this%mass = 0.0_wp
        this%alpha = 0.0_wp
        this%isActive = .FALSE.
        this%isValid = .FALSE.
    END SUBROUTINE PtMassDesc_Clear

    !---------------------------------------------------------------------------
    ! SUBROUTINE: PtMassManager_Add
    ! PHASE:      P0
    ! PURPOSE:    Add a point mass entry to the manager
    !---------------------------------------------------------------------------
    SUBROUTINE PtMassManager_Add(this, pointMass, status)
        CLASS(PtMassManager), INTENT(INOUT) :: this
        TYPE(PtMassDesc), INTENT(IN) :: pointMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(PtMassDesc), ALLOCATABLE :: temp_masses(:)
        INTEGER(i4) :: new_id
        CALL init_error_status(status)
        IF (.NOT. ALLOCATED(this%masses)) THEN
            ALLOCATE(this%masses(10))
            this%numMasses = 0
        ELSE IF (this%numMasses >= SIZE(this%masses)) THEN
            ALLOCATE(temp_masses(SIZE(this%masses) * 2))
            temp_masses(1:this%numMasses) = this%masses
            CALL MOVE_ALLOC(temp_masses, this%masses)
        END IF
        new_id = this%numMasses + 1
        this%numMasses = new_id
        this%masses(new_id) = pointMass
        this%masses(new_id)%massId = new_id
    END SUBROUTINE PtMassManager_Add

    FUNCTION PtMassManager_Find(this, name) RESULT(pointMass)
        CLASS(PtMassManager), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(PtMassDesc), POINTER :: pointMass
        INTEGER(i4) :: i
        pointMass => NULL()
        IF (.NOT. ALLOCATED(this%masses)) RETURN
        DO i = 1, this%numMasses
            IF (TRIM(this%masses(i)%name) == TRIM(name)) THEN
                pointMass => this%masses(i)
                RETURN
            END IF
        END DO
    END FUNCTION PtMassManager_Find

    FUNCTION PtMassManager_FindByNode(this, nodeId) RESULT(pointMass)
        CLASS(PtMassManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: nodeId
        TYPE(PtMassDesc), POINTER :: pointMass
        INTEGER(i4) :: i
        pointMass => NULL()
        IF (.NOT. ALLOCATED(this%masses)) RETURN
        DO i = 1, this%numMasses
            IF (this%masses(i)%nodeId == nodeId) THEN
                pointMass => this%masses(i)
                RETURN
            END IF
        END DO
    END FUNCTION PtMassManager_FindByNode

    SUBROUTINE PtMassManager_Clear(this)
        CLASS(PtMassManager), INTENT(INOUT) :: this
        IF (ALLOCATED(this%masses)) DEALLOCATE(this%masses)
        this%numMasses = 0
    END SUBROUTINE PtMassManager_Clear

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_Prop_Mass_Unified_Cfg
    ! PHASE:      P0
    ! PURPOSE:    Configure mass property parser
    !---------------------------------------------------------------------------
    SUBROUTINE MD_Prop_Mass_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Prop_Mass_Unified_Cfg: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Prop_Mass_Unified_Cfg

    SUBROUTINE MD_Prop_Mass_Unified_Parse(prop_type, ast_node, pointMass, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: prop_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PtMassDesc), INTENT(OUT) :: pointMass
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(prop_type) == 'MASS') THEN
            CALL Parse_MASS_Keyword(ast_node, pointMass, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Prop_Mass_Unified_Parse: unsupported prop_type ' // TRIM(prop_type)
        END IF
    END SUBROUTINE MD_Prop_Mass_Unified_Parse

    SUBROUTINE Parse_MASS_DataLine(data_line, node_id, mass, status)
        TYPE(KW_DataLineType), INTENT(IN) :: data_line
        INTEGER(i4), INTENT(OUT) :: node_id
        REAL(wp), INTENT(OUT) :: mass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (data_line%col_count < 2) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "*MASS data line requires at least 2 values: node_id, mass")
            RETURN
        END IF
        node_id = data_line%int_values(1)
        mass    = data_line%real_values(2)
        IF (node_id <= 0) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "Node ID must be positive")
            RETURN
        END IF
        IF (mass <= 0.0_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "Mass must be positive")
            RETURN
        END IF
    END SUBROUTINE Parse_MASS_DataLine

    SUBROUTINE Parse_MASS_Keyword(ast_node, pointMass, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PtMassDesc), INTENT(OUT) :: pointMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, alpha_str
        INTEGER(i4) :: node_id, ios
        REAL(wp) :: mass, alpha
        LOGICAL :: has_elset, has_alpha
        CALL init_error_status(status)
        CALL pointMass%Clear()
        CALL sect_prop_get_param_value(ast_node, "ELSET", elset_name)
        has_elset = (LEN_TRIM(elset_name) > 0)
        CALL sect_prop_get_param_value(ast_node, "ALPHA", alpha_str)
        has_alpha = (LEN_TRIM(alpha_str) > 0)
        IF (has_alpha) THEN
            READ(alpha_str, *, IOSTAT=ios) alpha
            IF (ios /= 0) alpha = 0.0_wp
        ELSE
            alpha = 0.0_wp
        END IF
        IF (ast_node%data_line_count < 1) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "*MASS requires at least one data line")
            RETURN
        END IF
        CALL Parse_MASS_DataLine(ast_node%data_lines(1), node_id, mass, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        pointMass%name   = "MASS-NODE" // TRIM(sect_prop_int_to_str(node_id))
        pointMass%nodeId = node_id
        pointMass%mass   = mass
        pointMass%alpha  = alpha
        IF (has_elset) pointMass%elsetName = TRIM(elset_name)
        IF (.NOT. pointMass%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Point mass validation failed"
        END IF
    END SUBROUTINE Parse_MASS_Keyword

    !---------------------------------------------------------------------------
    ! SUBROUTINE: Valid_MASS_Keyword
    ! PHASE:      P0
    ! PURPOSE:    Validate a parsed point mass descriptor
    !---------------------------------------------------------------------------
    SUBROUTINE Valid_MASS_Keyword(pointMass, model, status)
        TYPE(PtMassDesc), INTENT(IN) :: pointMass
        TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. pointMass%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Point mass validation failed"
            RETURN
        END IF
        IF (PRESENT(model)) THEN
            CALL Valid_MASS_Node(pointMass, model, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
        CALL Valid_MASS_PhysicalValues(pointMass, status)
    END SUBROUTINE Valid_MASS_Keyword

    SUBROUTINE Valid_MASS_Node(pointMass, model, status)
        TYPE(PtMassDesc), INTENT(IN) :: pointMass
        TYPE(UF_Model), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, part_idx
        LOGICAL :: node_found
        CALL init_error_status(status)
        node_found = .FALSE.
        DO part_idx = 1, SIZE(model%parts)
            IF (ALLOCATED(model%parts(part_idx)%nodes)) THEN
                DO i = 1, SIZE(model%parts(part_idx)%nodes)
                    IF (model%parts(part_idx)%nodes(i)%cfg%id == pointMass%nodeId) THEN
                        node_found = .TRUE.
                        EXIT
                    END IF
                END DO
            END IF
            IF (node_found) EXIT
        END DO
        IF (.NOT. node_found) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Node " // TRIM(sect_prop_int_to_str(pointMass%nodeId)) // &
                " not found for *MASS")
        END IF
    END SUBROUTINE Valid_MASS_Node

    SUBROUTINE Valid_MASS_PhysicalValues(pointMass, status)
        TYPE(PtMassDesc), INTENT(IN) :: pointMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (pointMass%mass < 1.0e-6_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Mass too small (< 1.0e-6 kg), check if this is intended")
            RETURN
        END IF
        IF (pointMass%mass > 1.0e6_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Mass too large (> 1.0e6 kg), check if this is intended")
            RETURN
        END IF
        IF (pointMass%alpha < 0.0_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Alpha (damping coef) must be non-negative")
            RETURN
        END IF
    END SUBROUTINE Valid_MASS_PhysicalValues

END MODULE MD_Sect_PropMass