!===============================================================================
! MODULE:  MD_Sect_PropPtMass
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Def
! BRIEF:   Point mass property (*POINT MASS) ?Desc types, parse and validate.
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Sect | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Section/CONTRACT.md

MODULE MD_Sect_PropPtMass
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, uf_set_error_status
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, UF_Model
    USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_DataLineType, KW_ParamValueType, &
                           KW_MAX_VALUE_LEN, KW_MAX_NAME_LEN
    IMPLICIT NONE
    PRIVATE

    !---------------------------------------------------------------------------
    ! TYPE:  PtMassAltDesc
    ! KIND:  Desc
    ! DESC:  Point mass entry (*POINT MASS) ?read-only definition record
    !---------------------------------------------------------------------------
    TYPE, PUBLIC, EXTENDS(DescBase) :: PtMassAltDesc
        INTEGER(i4) :: pointMassId = 0_i4
        INTEGER(i4) :: nodeId = 0_i4
        CHARACTER(LEN=64) :: nsetName = ""
        INTEGER(i4) :: targetId = 0_i4
        REAL(wp) :: mass = 0.0_wp
        LOGICAL :: isActive = .TRUE.
        LOGICAL :: isValid  = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout => PtMassAltDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure    => PtMassAltDesc_Ensure
        PROCEDURE, PUBLIC :: Init      => PtMassAltDesc_Init_Base
        PROCEDURE, PUBLIC :: Valid     => PtMassAltDesc_Valid_Fn
        PROCEDURE, PUBLIC :: Clear     => PtMassAltDesc_Clear
    END TYPE PtMassAltDesc

    !---------------------------------------------------------------------------
    ! TYPE:  PtMassAltManager
    ! KIND:  Ctx
    ! DESC:  Container managing a collection of PtMassAltDesc entries
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: PtMassAltManager
        INTEGER(i4) :: numPointMasses = 0_i4
        TYPE(PtMassAltDesc), ALLOCATABLE :: pointMasses(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add        => PtMassAltManager_Add
        PROCEDURE, PUBLIC :: Find       => PtMassAltManager_Find
        PROCEDURE, PUBLIC :: FindByNode => PtMassAltManager_FindByNode
        PROCEDURE, PUBLIC :: Clear      => PtMassAltManager_Clear
    END TYPE PtMassAltManager

    ! Public exports
    PUBLIC :: PtMassAltDesc
    PUBLIC :: PtMassAltManager
    PUBLIC :: Parse_POINTMASS_Keyword
    PUBLIC :: Parse_POINTMASS_DataLine
    PUBLIC :: MD_Prop_PointMass_Unified_Parse
    PUBLIC :: MD_Prop_PointMass_Unified_Configure
    PUBLIC :: Valid_POINTMASS_Keyword
    PUBLIC :: Valid_POINTMASS_Node
    PUBLIC :: Validate_POINTMASS_PhysicalValues

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
    ! SUBROUTINE: PtMassAltDesc_RegLayout
    ! PHASE:      P0
    ! PURPOSE:    Register layout (placeholder)
    !---------------------------------------------------------------------------
    SUBROUTINE PtMassAltDesc_RegLayout(this)
        CLASS(PtMassAltDesc), INTENT(INOUT) :: this
    END SUBROUTINE PtMassAltDesc_RegLayout

    SUBROUTINE PtMassAltDesc_Ensure(this)
        CLASS(PtMassAltDesc), INTENT(INOUT) :: this
        IF (this%pointMassId == 0) this%pointMassId = 1
    END SUBROUTINE PtMassAltDesc_Ensure

    SUBROUTINE PtMassAltDesc_Init_Base(this)
        CLASS(PtMassAltDesc), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::POINTMASS'
    END SUBROUTINE PtMassAltDesc_Init_Base

    SUBROUTINE PtMassAltDesc_Init(this, pointMassId, name, nodeId, mass, status)
        CLASS(PtMassAltDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: pointMassId
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: nodeId
        REAL(wp), INTENT(IN) :: mass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%pointMassId = pointMassId
        this%name   = TRIM(name)
        this%nodeId = nodeId
        this%mass   = mass
        this%isActive = .TRUE.
    END SUBROUTINE PtMassAltDesc_Init

    FUNCTION PtMassAltDesc_Valid_Fn(this) RESULT(ok)
        CLASS(PtMassAltDesc), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .FALSE.
        IF (this%nodeId <= 0 .AND. LEN_TRIM(this%nsetName) == 0) RETURN
        IF (this%mass <= 0.0_wp) RETURN
        ok = .TRUE.
    END FUNCTION PtMassAltDesc_Valid_Fn

    SUBROUTINE PtMassAltDesc_Clear(this)
        CLASS(PtMassAltDesc), INTENT(INOUT) :: this
        this%pointMassId = 0
        this%name    = ""
        this%nodeId  = 0
        this%nsetName = ""
        this%targetId = 0
        this%mass     = 0.0_wp
        this%isActive = .FALSE.
        this%isValid  = .FALSE.
    END SUBROUTINE PtMassAltDesc_Clear

    !---------------------------------------------------------------------------
    ! SUBROUTINE: PtMassAltManager_Add
    ! PHASE:      P0
    ! PURPOSE:    Add a point mass entry to the manager
    !---------------------------------------------------------------------------
    SUBROUTINE PtMassAltManager_Add(this, pointMass, status)
        CLASS(PtMassAltManager), INTENT(INOUT) :: this
        TYPE(PtMassAltDesc), INTENT(IN) :: pointMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(PtMassAltDesc), ALLOCATABLE :: temp_pointMasses(:)
        INTEGER(i4) :: new_id
        CALL init_error_status(status)
        IF (.NOT. ALLOCATED(this%pointMasses)) THEN
            ALLOCATE(this%pointMasses(10))
            this%numPointMasses = 0
        ELSE IF (this%numPointMasses >= SIZE(this%pointMasses)) THEN
            ALLOCATE(temp_pointMasses(SIZE(this%pointMasses) * 2))
            temp_pointMasses(1:this%numPointMasses) = this%pointMasses
            CALL MOVE_ALLOC(temp_pointMasses, this%pointMasses)
        END IF
        new_id = this%numPointMasses + 1
        this%numPointMasses = new_id
        this%pointMasses(new_id) = pointMass
        this%pointMasses(new_id)%pointMassId = new_id
    END SUBROUTINE PtMassAltManager_Add

    FUNCTION PtMassAltManager_Find(this, name) RESULT(pointMass)
        CLASS(PtMassAltManager), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(PtMassAltDesc), POINTER :: pointMass
        INTEGER(i4) :: i
        pointMass => NULL()
        IF (.NOT. ALLOCATED(this%pointMasses)) RETURN
        DO i = 1, this%numPointMasses
            IF (TRIM(this%pointMasses(i)%name) == TRIM(name)) THEN
                pointMass => this%pointMasses(i)
                RETURN
            END IF
        END DO
    END FUNCTION PtMassAltManager_Find

    FUNCTION PtMassAltManager_FindByNode(this, nodeId) RESULT(pointMass)
        CLASS(PtMassAltManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: nodeId
        TYPE(PtMassAltDesc), POINTER :: pointMass
        INTEGER(i4) :: i
        pointMass => NULL()
        IF (.NOT. ALLOCATED(this%pointMasses)) RETURN
        DO i = 1, this%numPointMasses
            IF (this%pointMasses(i)%nodeId == nodeId) THEN
                pointMass => this%pointMasses(i)
                RETURN
            END IF
        END DO
    END FUNCTION PtMassAltManager_FindByNode

    SUBROUTINE PtMassAltManager_Clear(this)
        CLASS(PtMassAltManager), INTENT(INOUT) :: this
        IF (ALLOCATED(this%pointMasses)) DEALLOCATE(this%pointMasses)
        this%numPointMasses = 0
    END SUBROUTINE PtMassAltManager_Clear

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_Prop_PointMass_Unified_Configure
    ! PHASE:      P0
    ! PURPOSE:    Configure point mass property parser
    !---------------------------------------------------------------------------
    SUBROUTINE MD_Prop_PointMass_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Prop_PointMass_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Prop_PointMass_Unified_Configure

    SUBROUTINE MD_Prop_PointMass_Unified_Parse(prop_type, ast_node, pointMass, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: prop_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PtMassAltDesc), INTENT(OUT) :: pointMass
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(prop_type) == 'POINTMASS' .OR. TRIM(prop_type) == 'POINT MASS') THEN
            CALL Parse_POINTMASS_Keyword(ast_node, pointMass, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Prop_PointMass_Unified_Parse: unsupported prop_type ' // TRIM(prop_type)
        END IF
    END SUBROUTINE MD_Prop_PointMass_Unified_Parse

    SUBROUTINE Parse_POINTMASS_DataLine(data_line, node_id, mass, status)
        TYPE(KW_DataLineType), INTENT(IN) :: data_line
        INTEGER(i4), INTENT(OUT) :: node_id
        REAL(wp), INTENT(OUT) :: mass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (data_line%col_count < 2) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "*POINT MASS data line requires at least 2 values: node_id, mass")
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
    END SUBROUTINE Parse_POINTMASS_DataLine

    SUBROUTINE Parse_POINTMASS_Keyword(ast_node, pointMass, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PtMassAltDesc), INTENT(OUT) :: pointMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: nset_name
        INTEGER(i4) :: node_id
        REAL(wp) :: mass
        LOGICAL :: has_nset
        CALL init_error_status(status)
        CALL pointMass%Clear()
        CALL sect_prop_get_param_value(ast_node, "NSET", nset_name)
        has_nset = (LEN_TRIM(nset_name) > 0)
        IF (ast_node%data_line_count < 1) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "*POINT MASS requires at least one data line")
            RETURN
        END IF
        CALL Parse_POINTMASS_DataLine(ast_node%data_lines(1), node_id, mass, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        pointMass%name   = "POINTMASS-NODE" // TRIM(sect_prop_int_to_str(node_id))
        pointMass%nodeId = node_id
        pointMass%mass   = mass
        IF (has_nset) pointMass%nsetName = TRIM(nset_name)
        IF (.NOT. pointMass%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Point mass validation failed"
        END IF
    END SUBROUTINE Parse_POINTMASS_Keyword

    !---------------------------------------------------------------------------
    ! SUBROUTINE: Validate_POINTMASS_PhysicalValues
    ! PHASE:      P0
    ! PURPOSE:    Validate physical values of a point mass descriptor
    !---------------------------------------------------------------------------
    SUBROUTINE Validate_POINTMASS_PhysicalValues(pointMass, status)
        TYPE(PtMassAltDesc), INTENT(IN) :: pointMass
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (pointMass%mass < 1.0e-6_wp .OR. pointMass%mass > 1.0e6_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Mass out of reasonable range (1e-6 to 1e6 kg)")
            RETURN
        END IF
    END SUBROUTINE Validate_POINTMASS_PhysicalValues

    SUBROUTINE Valid_POINTMASS_Keyword(pointMass, model, status)
        TYPE(PtMassAltDesc), INTENT(IN) :: pointMass
        TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. pointMass%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Point mass validation failed"
            RETURN
        END IF
        IF (PRESENT(model) .AND. pointMass%nodeId > 0) THEN
            CALL Valid_POINTMASS_Node(pointMass, model, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF
        CALL Validate_POINTMASS_PhysicalValues(pointMass, status)
    END SUBROUTINE Valid_POINTMASS_Keyword

    SUBROUTINE Valid_POINTMASS_Node(pointMass, model, status)
        TYPE(PtMassAltDesc), INTENT(IN) :: pointMass
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
                " not found for *POINT MASS")
        END IF
    END SUBROUTINE Valid_POINTMASS_Node

END MODULE MD_Sect_PropPtMass