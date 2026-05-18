!======================================================================
! MODULE:  MD_Int_Connector
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Connector domain definitions.
!          Spring, Joint, Dashpot, Bushing types.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_Connector
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, uf_set_error_status
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase
    USE MD_KW_Def, ONLY: KW_ASTNodeType
    IMPLICIT NONE
    PRIVATE

    !=============================================================================
    ! Type Definitions
    !=============================================================================

    ! Spring Connector Properties
    TYPE, PUBLIC, EXTENDS(DescBase) :: SpringProperties
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: dof = 0
        REAL(wp) :: stiffness = 0.0_wp
        REAL(wp) :: damping = 0.0_wp
        CHARACTER(LEN=64) :: amplitudeName = ""
        LOGICAL :: nonlinear = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: Clear => SpringProperties_Clear
        PROCEDURE, PUBLIC :: Init => SpringProperties_Init
        PROCEDURE, PUBLIC :: Valid => SpringProperties_Valid_Fn
    END TYPE SpringProperties

    ! Joint Connector Properties
    TYPE, PUBLIC, EXTENDS(DescBase) :: JointProperties
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: jointType = 1  ! 1=REVOLUTE, 2=TRANSLATIONAL, 3=UNIVERSAL, 4=CYLINDRICAL
        REAL(wp) :: rotationStiffness = 0.0_wp
        REAL(wp) :: translationStiffness = 0.0_wp
        CHARACTER(LEN=64) :: amplitudeName = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init => JointProperties_Init
        PROCEDURE, PUBLIC :: Valid => JointProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => JointProperties_Clear
    END TYPE JointProperties

    ! Dashpot Connector Properties
    TYPE, PUBLIC, EXTENDS(DescBase) :: DashProperties
        CHARACTER(LEN=64) :: name = ""
        INTEGER(i4) :: dof = 0
        REAL(wp) :: dampingCoefficient = 0.0_wp
        CHARACTER(LEN=64) :: amplitudeName = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init => DashProperties_Init
        PROCEDURE, PUBLIC :: Valid => DashProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => DashProperties_Clear
    END TYPE DashProperties

    ! Type alias for compatibility with MD_KWMapper
    ! Note: DashpotProperties is an alias for DashProperties
    ! In MD_KWMapper, use DashProperties directly or create a type alias there

    ! Bushing Connector Properties
    TYPE, PUBLIC, EXTENDS(DescBase) :: BushingProperties
        CHARACTER(LEN=64) :: name = ""
        REAL(wp) :: stiffness(6) = 0.0_wp  ! 6 DOF stiffness matrix
        REAL(wp) :: damping(6) = 0.0_wp     ! 6 DOF damping matrix
        CHARACTER(LEN=64) :: amplitudeName = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init => BushingProperties_Init
        PROCEDURE, PUBLIC :: Valid => BushingProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => BushingProperties_Clear
    END TYPE BushingProperties

    ! Generic Connector Properties
    TYPE, PUBLIC, EXTENDS(DescBase) :: ConnectorProperties
        CHARACTER(LEN=64) :: name = ""
        CHARACTER(LEN=64) :: connectorType = ""  ! SPRING, JOINT, DASHPOT, BUSHING, etc.
        CHARACTER(LEN=64) :: sectionName = ""
        CHARACTER(LEN=64) :: behaviorName = ""
        INTEGER(i4) :: numNodes = 0
    CONTAINS
        PROCEDURE, PUBLIC :: Init => ConnectorProperties_Init
        PROCEDURE, PUBLIC :: Valid => ConnectorProperties_Valid_Fn
        PROCEDURE, PUBLIC :: Clear => ConnectorProperties_Clear
    END TYPE ConnectorProperties

    ! Connector Properties Manager
    TYPE, PUBLIC :: ConnPropsMgr
        INTEGER(i4) :: numConnectors = 0_i4
        TYPE(ConnectorProperties), ALLOCATABLE :: connectors(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add => ConnPropsMgr_Add
        PROCEDURE, PUBLIC :: Find => ConnPropsMgr_Find
        PROCEDURE, PUBLIC :: Clear => ConnPropsMgr_Clear
    END TYPE ConnPropsMgr

    !=============================================================================
    ! PUBLIC Interface
    !=============================================================================
    PUBLIC :: SpringProperties, JointProperties, DashProperties, BushingProperties
    PUBLIC :: ConnectorProperties, ConnPropsMgr
    ! Parsing functions
    PUBLIC :: Parse_SPRING_Keyword, Parse_JOINT_Keyword, Parse_DASHPOT_Keyword
    PUBLIC :: Parse_BUSHING_Keyword, Parse_CONNECTOR_Keyword
    ! Unified parse functions
    PUBLIC :: MD_Connector_Spring_Unified_Parse, MD_Connector_Spring_Unified_Configure
    PUBLIC :: MD_Connector_Joint_Unified_Parse, MD_Connector_Joint_Unified_Configure
    PUBLIC :: MD_Connector_Dashpot_Unified_Parse, MD_Connector_Dashpot_Unified_Configure
    PUBLIC :: MD_Connector_Bushing_Unified_Parse, MD_Connector_Bushing_Unified_Configure

CONTAINS

    !=============================================================================
    ! Spring Properties Procedures
    !=============================================================================

    SUBROUTINE SpringProperties_Clear(this)
        CLASS(SpringProperties), INTENT(INOUT) :: this
        this%name = ""
        this%dof = 0
        this%stiffness = 0.0_wp
        this%damping = 0.0_wp
        this%amplitudeName = ""
        this%nonlinear = .FALSE.
    END SUBROUTINE SpringProperties_Clear

    SUBROUTINE SpringProperties_Init(this, name, status)
        CLASS(SpringProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(name) == 0) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "Spring name must be specified")
            RETURN
        END IF
        this%name = TRIM(name)
        this%dof = 0
        this%stiffness = 0.0_wp
        this%damping = 0.0_wp
        this%amplitudeName = ""
        this%nonlinear = .FALSE.
    END SUBROUTINE SpringProperties_Init

    FUNCTION SpringProperties_Valid_Fn(this) RESULT(ok)
        CLASS(SpringProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%stiffness < 0.0_wp) ok = .FALSE.
        IF (this%damping < 0.0_wp) ok = .FALSE.
    END FUNCTION SpringProperties_Valid_Fn

    SUBROUTINE Parse_SPRING_Keyword(ast_node, spring, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(SpringProperties), INTENT(OUT) :: spring
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL spring%Init(TRIM(name), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 2) THEN
            spring%dof = INT(ast_node%data_lines(1)%real_values(1), i4)
            spring%stiffness = ast_node%data_lines(1)%real_values(2)
            IF (ast_node%data_lines(1)%col_count >= 3) THEN
                spring%damping = ast_node%data_lines(1)%real_values(3)
            END IF
        END IF
        IF (.NOT. spring%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Spring validation failed"
        END IF
    END SUBROUTINE Parse_SPRING_Keyword

    SUBROUTINE MD_Connector_Spring_Unified_Parse(conn_type, ast_node, spring, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: conn_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(SpringProperties), INTENT(OUT) :: spring
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(conn_type) == 'SPRING') THEN
            CALL Parse_SPRING_Keyword(ast_node, spring, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Connector_Spring_Unified_Parse: unsupported conn_type ' // TRIM(conn_type)
        END IF
    END SUBROUTINE MD_Connector_Spring_Unified_Parse

    SUBROUTINE MD_Connector_Spring_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Default configuration
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Connector_Spring_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Connector_Spring_Unified_Configure

    !=============================================================================
    ! Joint Properties Procedures
    !=============================================================================

    SUBROUTINE JointProperties_Init(this, name, status)
        CLASS(JointProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(name) == 0) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "Joint name must be specified")
            RETURN
        END IF
        this%name = TRIM(name)
        this%jointType = 1
        this%rotationStiffness = 0.0_wp
        this%translationStiffness = 0.0_wp
        this%amplitudeName = ""
    END SUBROUTINE JointProperties_Init

    FUNCTION JointProperties_Valid_Fn(this) RESULT(ok)
        CLASS(JointProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%jointType < 1 .OR. this%jointType > 4) ok = .FALSE.
        IF (this%rotationStiffness < 0.0_wp) ok = .FALSE.
        IF (this%translationStiffness < 0.0_wp) ok = .FALSE.
    END FUNCTION JointProperties_Valid_Fn

    SUBROUTINE JointProperties_Clear(this)
        CLASS(JointProperties), INTENT(INOUT) :: this
        this%name = ""
        this%jointType = 1
        this%rotationStiffness = 0.0_wp
        this%translationStiffness = 0.0_wp
        this%amplitudeName = ""
    END SUBROUTINE JointProperties_Clear

    SUBROUTINE Parse_JOINT_Keyword(ast_node, joint, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(JointProperties), INTENT(OUT) :: joint
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL joint%Init(TRIM(name), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 3) THEN
            joint%jointType = INT(ast_node%data_lines(1)%real_values(1), i4)
            joint%rotationStiffness = ast_node%data_lines(1)%real_values(2)
            joint%translationStiffness = ast_node%data_lines(1)%real_values(3)
        END IF
        IF (.NOT. joint%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Joint validation failed"
        END IF
    END SUBROUTINE Parse_JOINT_Keyword

    SUBROUTINE MD_Connector_Joint_Unified_Parse(conn_type, ast_node, joint, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: conn_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(JointProperties), INTENT(OUT) :: joint
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(conn_type) == 'JOINT') THEN
            CALL Parse_JOINT_Keyword(ast_node, joint, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Connector_Joint_Unified_Parse: unsupported conn_type ' // TRIM(conn_type)
        END IF
    END SUBROUTINE MD_Connector_Joint_Unified_Parse

    SUBROUTINE MD_Connector_Joint_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Default configuration
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Connector_Joint_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Connector_Joint_Unified_Configure

    !=============================================================================
    ! Dashpot Properties Procedures
    !=============================================================================

    SUBROUTINE DashProperties_Init(this, name, status)
        CLASS(DashProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(name) == 0) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "Dashpot name must be specified")
            RETURN
        END IF
        this%name = TRIM(name)
        this%dof = 0
        this%dampingCoefficient = 0.0_wp
        this%amplitudeName = ""
    END SUBROUTINE DashProperties_Init

    FUNCTION DashProperties_Valid_Fn(this) RESULT(ok)
        CLASS(DashProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (this%dampingCoefficient < 0.0_wp) ok = .FALSE.
    END FUNCTION DashProperties_Valid_Fn

    SUBROUTINE DashProperties_Clear(this)
        CLASS(DashProperties), INTENT(INOUT) :: this
        this%name = ""
        this%dof = 0
        this%dampingCoefficient = 0.0_wp
        this%amplitudeName = ""
    END SUBROUTINE DashProperties_Clear

    SUBROUTINE Parse_DASHPOT_Keyword(ast_node, dashpot, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(DashProperties), INTENT(OUT) :: dashpot
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL dashpot%Init(TRIM(name), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 2) THEN
            dashpot%dof = INT(ast_node%data_lines(1)%real_values(1), i4)
            dashpot%dampingCoefficient = ast_node%data_lines(1)%real_values(2)
        END IF
        IF (.NOT. dashpot%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Dashpot validation failed"
        END IF
    END SUBROUTINE Parse_DASHPOT_Keyword

    SUBROUTINE MD_Connector_Dashpot_Unified_Parse(conn_type, ast_node, dashpot, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: conn_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(DashProperties), INTENT(OUT) :: dashpot
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(conn_type) == 'DASHPOT') THEN
            CALL Parse_DASHPOT_Keyword(ast_node, dashpot, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Connector_Dashpot_Unified_Parse: unsupported conn_type ' // TRIM(conn_type)
        END IF
    END SUBROUTINE MD_Connector_Dashpot_Unified_Parse

    SUBROUTINE MD_Connector_Dashpot_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Default configuration
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Connector_Dashpot_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Connector_Dashpot_Unified_Configure

    !=============================================================================
    ! Bushing Properties Procedures
    !=============================================================================

    SUBROUTINE BushingProperties_Init(this, name, status)
        CLASS(BushingProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(name) == 0) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "Bushing name must be specified")
            RETURN
        END IF
        this%name = TRIM(name)
        this%stiffness = 0.0_wp
        this%damping = 0.0_wp
        this%amplitudeName = ""
    END SUBROUTINE BushingProperties_Init

    FUNCTION BushingProperties_Valid_Fn(this) RESULT(ok)
        CLASS(BushingProperties), INTENT(IN) :: this
        LOGICAL :: ok
        INTEGER(i4) :: i
        ok = .TRUE.
        DO i = 1, 6
            IF (this%stiffness(i) < 0.0_wp) ok = .FALSE.
            IF (this%damping(i) < 0.0_wp) ok = .FALSE.
        END DO
    END FUNCTION BushingProperties_Valid_Fn

    SUBROUTINE BushingProperties_Clear(this)
        CLASS(BushingProperties), INTENT(INOUT) :: this
        this%name = ""
        this%stiffness = 0.0_wp
        this%damping = 0.0_wp
        this%amplitudeName = ""
    END SUBROUTINE BushingProperties_Clear

    SUBROUTINE Parse_BUSHING_Keyword(ast_node, bushing, name, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(BushingProperties), INTENT(OUT) :: bushing
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        CALL init_error_status(status)
        CALL bushing%Init(TRIM(name), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        IF (ast_node%data_line_count > 0 .AND. ast_node%data_lines(1)%col_count >= 6) THEN
            DO i = 1, MIN(6, ast_node%data_lines(1)%col_count)
                bushing%stiffness(i) = ast_node%data_lines(1)%real_values(i)
            END DO
            IF (ast_node%data_lines(1)%col_count >= 12) THEN
                DO i = 1, 6
                    bushing%damping(i) = ast_node%data_lines(1)%real_values(6 + i)
                END DO
            END IF
        END IF
        IF (.NOT. bushing%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Bushing validation failed"
        END IF
    END SUBROUTINE Parse_BUSHING_Keyword

    SUBROUTINE MD_Connector_Bushing_Unified_Parse(conn_type, ast_node, bushing, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: conn_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(BushingProperties), INTENT(OUT) :: bushing
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(conn_type) == 'BUSHING') THEN
            CALL Parse_BUSHING_Keyword(ast_node, bushing, context_name, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Connector_Bushing_Unified_Parse: unsupported conn_type ' // TRIM(conn_type)
        END IF
    END SUBROUTINE MD_Connector_Bushing_Unified_Parse

    SUBROUTINE MD_Connector_Bushing_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Default configuration
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Connector_Bushing_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Connector_Bushing_Unified_Configure

    !=============================================================================
    ! Connector Properties Procedures
    !=============================================================================

    SUBROUTINE ConnectorProperties_Init(this, name, status)
        CLASS(ConnectorProperties), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(name) == 0) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, "Connector name must be specified")
            RETURN
        END IF
        this%name = TRIM(name)
        this%connectorType = ""
        this%sectionName = ""
        this%behaviorName = ""
        this%numNodes = 0
    END SUBROUTINE ConnectorProperties_Init

    FUNCTION ConnectorProperties_Valid_Fn(this) RESULT(ok)
        CLASS(ConnectorProperties), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .TRUE.
        IF (LEN_TRIM(this%connectorType) == 0) ok = .FALSE.
    END FUNCTION ConnectorProperties_Valid_Fn

    SUBROUTINE ConnectorProperties_Clear(this)
        CLASS(ConnectorProperties), INTENT(INOUT) :: this
        this%name = ""
        this%connectorType = ""
        this%sectionName = ""
        this%behaviorName = ""
        this%numNodes = 0
    END SUBROUTINE ConnectorProperties_Clear

    !=============================================================================
    ! ConnPropsMgr Procedures
    !=============================================================================

    SUBROUTINE ConnPropsMgr_Add(this, connector, status)
        CLASS(ConnPropsMgr), INTENT(INOUT) :: this
        TYPE(ConnectorProperties), INTENT(IN) :: connector
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(ConnectorProperties), ALLOCATABLE :: temp(:)
        INTEGER(i4) :: i

        CALL init_error_status(status)

        ! Check if connector already exists
        DO i = 1, this%numConnectors
            IF (TRIM(this%connectors(i)%name) == TRIM(connector%name)) THEN
                CALL uf_set_error_status(status, IF_STATUS_INVALID, "Connector already exists: " // TRIM(connector%name))
                RETURN
            END IF
        END DO

        ! Resize array
        IF (.NOT. ALLOCATED(this%connectors)) THEN
            ALLOCATE(this%connectors(10))
        ELSE IF (this%numConnectors >= SIZE(this%connectors)) THEN
            ALLOCATE(temp(this%numConnectors + 10))
            DO i = 1, this%numConnectors
                temp(i) = this%connectors(i)
            END DO
            DEALLOCATE(this%connectors)
            CALL MOVE_ALLOC(temp, this%connectors)
        END IF

        this%numConnectors = this%numConnectors + 1
        this%connectors(this%numConnectors) = connector
    END SUBROUTINE ConnPropsMgr_Add

    SUBROUTINE ConnPropsMgr_Clear(this)
        CLASS(ConnPropsMgr), INTENT(INOUT) :: this
        IF (ALLOCATED(this%connectors)) THEN
            DEALLOCATE(this%connectors)
        END IF
        this%numConnectors = 0
    END SUBROUTINE ConnPropsMgr_Clear

    FUNCTION ConnPropsMgr_Find(this, name) RESULT(connector)
        CLASS(ConnPropsMgr), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ConnectorProperties), POINTER :: connector
        INTEGER(i4) :: i

        NULLIFY(connector)
        DO i = 1, this%numConnectors
            IF (TRIM(this%connectors(i)%name) == TRIM(name)) THEN
                connector => this%connectors(i)
                RETURN
            END IF
        END DO
    END FUNCTION ConnPropsMgr_Find

    !=============================================================================
    ! Parse_CONNECTOR_Keyword - Generic Connector Parsing
    !=============================================================================

    SUBROUTINE Parse_CONNECTOR_Keyword(ast_node, connector, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ConnectorProperties), INTENT(OUT) :: connector
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=64) :: name_val
        
        CALL init_error_status(status)
        
        ! Extract connector name from parameters or use default
        name_val = "CONNECTOR_DEFAULT"
        IF (ast_node%param_count > 0) THEN
            ! Extract name from first parameter if available
            ! This is a simplified implementation
        END IF
        
        CALL connector%Init(TRIM(name_val), status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        
        ! Extract connector type and other properties from AST node
        ! This is a placeholder - full implementation would parse all parameters
        
        IF (.NOT. connector%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Connector validation failed"
        END IF
    END SUBROUTINE Parse_CONNECTOR_Keyword

END MODULE MD_Int_Connector