!===============================================================================
! MODULE:  MD_Sect_PropRotInertia
! LAYER:   L3_MD
! DOMAIN:  Section
! ROLE:    _Def
! BRIEF:   Rotary inertia property (*ROTARY INERTIA) â€?Desc, parse, validate.
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Sect | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Section/CONTRACT.md

MODULE MD_Sect_PropRotInertia
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, uf_set_error_status
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, UF_Model
    USE MD_KW_Def, ONLY: KW_ASTNodeType, KW_DataLineType, KW_ParamValueType, &
                           KW_MAX_VALUE_LEN, KW_MAX_NAME_LEN
    IMPLICIT NONE
    PRIVATE

    !---------------------------------------------------------------------------
    ! TYPE:  RotInertiaDesc
    ! KIND:  Desc
    ! DESC:  Rotary inertia entry â€?symmetric 3x3 tensor definition record
    !---------------------------------------------------------------------------
    TYPE, PUBLIC, EXTENDS(DescBase) :: RotInertiaDesc
        INTEGER(i4) :: inertiaId = 0_i4
        INTEGER(i4) :: nodeId = 0_i4
        CHARACTER(LEN=64) :: elsetName = ""
        CHARACTER(LEN=64) :: orientationName = ""
        INTEGER(i4) :: targetId = 0_i4
        ! Inertia tensor components (symmetric 3x3)
        REAL(wp) :: Ixx = 0.0_wp
        REAL(wp) :: Iyy = 0.0_wp
        REAL(wp) :: Izz = 0.0_wp
        REAL(wp) :: Ixy = 0.0_wp
        REAL(wp) :: Ixz = 0.0_wp
        REAL(wp) :: Iyz = 0.0_wp
        REAL(wp) :: alpha     = 0.0_wp
        REAL(wp) :: composite = 0.0_wp
        LOGICAL :: isActive = .TRUE.
        LOGICAL :: isValid  = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: RegLayout          => RotInertiaDesc_RegLayout
        PROCEDURE, PUBLIC :: Ensure             => RotInertiaDesc_Ensure
        PROCEDURE, PUBLIC :: Init               => RotInertiaDesc_Init_Base
        PROCEDURE, PUBLIC :: Valid              => RotInertiaDesc_Valid_Fn
        PROCEDURE, PUBLIC :: Clear              => RotInertiaDesc_Clear
        PROCEDURE, PUBLIC :: GetInertiaMatrix   => RotInertiaDesc_GetInertiaMatrix
        PROCEDURE, PUBLIC :: IsPositiveDefinite => RotInertiaDesc_IsPositiveDefinite
    END TYPE RotInertiaDesc

    !---------------------------------------------------------------------------
    ! TYPE:  RotInertiaManager
    ! KIND:  Ctx
    ! DESC:  Container managing a collection of RotInertiaDesc entries
    !---------------------------------------------------------------------------
    TYPE, PUBLIC :: RotInertiaManager
        INTEGER(i4) :: numInertias = 0_i4
        TYPE(RotInertiaDesc), ALLOCATABLE :: inertias(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add        => RotInertiaManager_Add
        PROCEDURE, PUBLIC :: Find       => RotInertiaManager_Find
        PROCEDURE, PUBLIC :: FindByNode => RotInertiaManager_FindByNode
        PROCEDURE, PUBLIC :: Clear      => RotInertiaManager_Clear
    END TYPE RotInertiaManager

    ! Public exports
    PUBLIC :: RotInertiaDesc
    PUBLIC :: RotInertiaManager
    PUBLIC :: Parse_ROTARYINERTIA_Keyword
    PUBLIC :: Parse_ROTARYINERTIA_DataLine
    PUBLIC :: MD_Prop_RotaryInertia_Unified_Parse
    PUBLIC :: MD_Prop_RotaryInertia_Unified_Configure
    PUBLIC :: Valid_ROTARYINERTIA_Keyword
    PUBLIC :: Valid_ROTARYINERTIA_Target
    PUBLIC :: Validate_ROTARYINERTIA_Orientation
    PUBLIC :: Validate_ROTARYINERTIA_PhysicalValues

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
    ! SUBROUTINE: RotInertiaDesc_RegLayout
    ! PHASE:      P0
    ! PURPOSE:    Register layout (placeholder)
    !---------------------------------------------------------------------------
    SUBROUTINE RotInertiaDesc_RegLayout(this)
        CLASS(RotInertiaDesc), INTENT(INOUT) :: this
    END SUBROUTINE RotInertiaDesc_RegLayout

    SUBROUTINE RotInertiaDesc_Ensure(this)
        CLASS(RotInertiaDesc), INTENT(INOUT) :: this
        IF (this%inertiaId == 0) this%inertiaId = 1
    END SUBROUTINE RotInertiaDesc_Ensure

    SUBROUTINE RotInertiaDesc_Init_Base(this)
        CLASS(RotInertiaDesc), INTENT(INOUT) :: this
        CALL DescBase_Init(this)
        this%algo_type_name = 'DESC::ROTARYINERTIA'
    END SUBROUTINE RotInertiaDesc_Init_Base

    SUBROUTINE RotInertiaDesc_Init(this, inertiaId, name, nodeId, Ixx, Iyy, Izz, &
                                   Ixy, Ixz, Iyz, alpha, composite, status)
        CLASS(RotInertiaDesc), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: inertiaId
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: nodeId
        REAL(wp), INTENT(IN) :: Ixx, Iyy, Izz, Ixy, Ixz, Iyz
        REAL(wp), INTENT(IN), OPTIONAL :: alpha, composite
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL this%Init()
        this%inertiaId = inertiaId
        this%name   = TRIM(name)
        this%nodeId = nodeId
        this%Ixx = Ixx; this%Iyy = Iyy; this%Izz = Izz
        this%Ixy = Ixy; this%Ixz = Ixz; this%Iyz = Iyz
        IF (PRESENT(alpha))     this%alpha     = alpha
        IF (PRESENT(composite)) this%composite = composite
        this%isActive = .TRUE.
    END SUBROUTINE RotInertiaDesc_Init

    FUNCTION RotInertiaDesc_Valid_Fn(this) RESULT(ok)
        CLASS(RotInertiaDesc), INTENT(IN) :: this
        LOGICAL :: ok
        ok = .FALSE.
        IF (this%nodeId <= 0) RETURN
        IF (this%Ixx <= 0.0_wp .OR. this%Iyy <= 0.0_wp .OR. this%Izz <= 0.0_wp) RETURN
        IF (.NOT. this%IsPositiveDefinite()) RETURN
        ok = .TRUE.
    END FUNCTION RotInertiaDesc_Valid_Fn

    SUBROUTINE RotInertiaDesc_Clear(this)
        CLASS(RotInertiaDesc), INTENT(INOUT) :: this
        this%inertiaId = 0
        this%name    = ""
        this%nodeId  = 0
        this%elsetName = ""
        this%orientationName = ""
        this%targetId = 0
        this%Ixx = 0.0_wp; this%Iyy = 0.0_wp; this%Izz = 0.0_wp
        this%Ixy = 0.0_wp; this%Ixz = 0.0_wp; this%Iyz = 0.0_wp
        this%alpha     = 0.0_wp
        this%composite = 0.0_wp
        this%isActive = .FALSE.
        this%isValid  = .FALSE.
    END SUBROUTINE RotInertiaDesc_Clear

    SUBROUTINE RotInertiaDesc_GetInertiaMatrix(this, I_matrix)
        CLASS(RotInertiaDesc), INTENT(IN) :: this
        REAL(wp), INTENT(OUT) :: I_matrix(3, 3)
        I_matrix(1, 1) = this%Ixx
        I_matrix(2, 2) = this%Iyy
        I_matrix(3, 3) = this%Izz
        I_matrix(1, 2) = this%Ixy; I_matrix(2, 1) = this%Ixy
        I_matrix(1, 3) = this%Ixz; I_matrix(3, 1) = this%Ixz
        I_matrix(2, 3) = this%Iyz; I_matrix(3, 2) = this%Iyz
    END SUBROUTINE RotInertiaDesc_GetInertiaMatrix

    FUNCTION RotInertiaDesc_IsPositiveDefinite(this) RESULT(is_pd)
        CLASS(RotInertiaDesc), INTENT(IN) :: this
        LOGICAL :: is_pd
        REAL(wp) :: det_2x2, det_3x3
        REAL(wp) :: I_matrix(3, 3)
        is_pd = .FALSE.
        IF (this%Ixx <= 0.0_wp .OR. this%Iyy <= 0.0_wp .OR. this%Izz <= 0.0_wp) RETURN
        det_2x2 = this%Ixx * this%Iyy - this%Ixy**2
        IF (det_2x2 <= 0.0_wp) RETURN
        det_2x2 = this%Ixx * this%Izz - this%Ixz**2
        IF (det_2x2 <= 0.0_wp) RETURN
        det_2x2 = this%Iyy * this%Izz - this%Iyz**2
        IF (det_2x2 <= 0.0_wp) RETURN
        CALL this%GetInertiaMatrix(I_matrix)
        det_3x3 = I_matrix(1,1) * (I_matrix(2,2)*I_matrix(3,3) - I_matrix(2,3)*I_matrix(3,2)) &
                - I_matrix(1,2) * (I_matrix(2,1)*I_matrix(3,3) - I_matrix(2,3)*I_matrix(3,1)) &
                + I_matrix(1,3) * (I_matrix(2,1)*I_matrix(3,2) - I_matrix(2,2)*I_matrix(3,1))
        IF (det_3x3 > 0.0_wp) is_pd = .TRUE.
    END FUNCTION RotInertiaDesc_IsPositiveDefinite

    !---------------------------------------------------------------------------
    ! SUBROUTINE: RotInertiaManager_Add
    ! PHASE:      P0
    ! PURPOSE:    Add a rotary inertia entry to the manager
    !---------------------------------------------------------------------------
    SUBROUTINE RotInertiaManager_Add(this, rotaryInertia, status)
        CLASS(RotInertiaManager), INTENT(INOUT) :: this
        TYPE(RotInertiaDesc), INTENT(IN) :: rotaryInertia
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(RotInertiaDesc), ALLOCATABLE :: temp_inertias(:)
        INTEGER(i4) :: new_id
        CALL init_error_status(status)
        IF (.NOT. ALLOCATED(this%inertias)) THEN
            ALLOCATE(this%inertias(10))
            this%numInertias = 0
        ELSE IF (this%numInertias >= SIZE(this%inertias)) THEN
            ALLOCATE(temp_inertias(SIZE(this%inertias) * 2))
            temp_inertias(1:this%numInertias) = this%inertias
            CALL MOVE_ALLOC(temp_inertias, this%inertias)
        END IF
        new_id = this%numInertias + 1
        this%numInertias = new_id
        this%inertias(new_id) = rotaryInertia
        this%inertias(new_id)%inertiaId = new_id
    END SUBROUTINE RotInertiaManager_Add

    FUNCTION RotInertiaManager_Find(this, name) RESULT(rotaryInertia)
        CLASS(RotInertiaManager), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(RotInertiaDesc), POINTER :: rotaryInertia
        INTEGER(i4) :: i
        rotaryInertia => NULL()
        IF (.NOT. ALLOCATED(this%inertias)) RETURN
        DO i = 1, this%numInertias
            IF (TRIM(this%inertias(i)%name) == TRIM(name)) THEN
                rotaryInertia => this%inertias(i)
                RETURN
            END IF
        END DO
    END FUNCTION RotInertiaManager_Find

    FUNCTION RotInertiaManager_FindByNode(this, nodeId) RESULT(rotaryInertia)
        CLASS(RotInertiaManager), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: nodeId
        TYPE(RotInertiaDesc), POINTER :: rotaryInertia
        INTEGER(i4) :: i
        rotaryInertia => NULL()
        IF (.NOT. ALLOCATED(this%inertias)) RETURN
        DO i = 1, this%numInertias
            IF (this%inertias(i)%nodeId == nodeId) THEN
                rotaryInertia => this%inertias(i)
                RETURN
            END IF
        END DO
    END FUNCTION RotInertiaManager_FindByNode

    SUBROUTINE RotInertiaManager_Clear(this)
        CLASS(RotInertiaManager), INTENT(INOUT) :: this
        IF (ALLOCATED(this%inertias)) DEALLOCATE(this%inertias)
        this%numInertias = 0
    END SUBROUTINE RotInertiaManager_Clear

    !---------------------------------------------------------------------------
    ! SUBROUTINE: MD_Prop_RotaryInertia_Unified_Configure
    ! PHASE:      P0
    ! PURPOSE:    Configure rotary inertia property parser
    !---------------------------------------------------------------------------
    SUBROUTINE MD_Prop_RotaryInertia_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Prop_RotaryInertia_Unified_Configure: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE MD_Prop_RotaryInertia_Unified_Configure

    SUBROUTINE MD_Prop_RotaryInertia_Unified_Parse(prop_type, ast_node, rotaryInertia, context_name, status)
        CHARACTER(LEN=*), INTENT(IN) :: prop_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(RotInertiaDesc), INTENT(OUT) :: rotaryInertia
        CHARACTER(LEN=*), INTENT(IN) :: context_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(prop_type) == 'ROTARYINERTIA' .OR. TRIM(prop_type) == 'ROTARY INERTIA') THEN
            CALL Parse_ROTARYINERTIA_Keyword(ast_node, rotaryInertia, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'MD_Prop_RotaryInertia_Unified_Parse: unsupported prop_type ' // TRIM(prop_type)
        END IF
    END SUBROUTINE MD_Prop_RotaryInertia_Unified_Parse

    SUBROUTINE Parse_ROTARYINERTIA_DataLine(data_line, I11, I22, I33, I12, I13, I23, status)
        TYPE(KW_DataLineType), INTENT(IN) :: data_line
        REAL(wp), INTENT(OUT) :: I11, I22, I33, I12, I13, I23
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (data_line%col_count < 6) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "*ROTARY INERTIA data line requires 6 values: I11, I22, I33, I12, I13, I23")
            RETURN
        END IF
        I11 = data_line%real_values(1); I22 = data_line%real_values(2)
        I33 = data_line%real_values(3); I12 = data_line%real_values(4)
        I13 = data_line%real_values(5); I23 = data_line%real_values(6)
        IF (I11 <= 0.0_wp .OR. I22 <= 0.0_wp .OR. I33 <= 0.0_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Principal moments of inertia (I11, I22, I33) must be positive")
            RETURN
        END IF
    END SUBROUTINE Parse_ROTARYINERTIA_DataLine

    SUBROUTINE Parse_ROTARYINERTIA_Keyword(ast_node, rotaryInertia, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(RotInertiaDesc), INTENT(OUT) :: rotaryInertia
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: elset_name, orientation_name, alpha_str, composite_str
        REAL(wp) :: I11, I22, I33, I12, I13, I23, alpha, composite
        INTEGER(i4) :: ios
        LOGICAL :: has_elset, has_orientation, has_alpha, has_composite
        CALL init_error_status(status)
        CALL rotaryInertia%Clear()
        CALL sect_prop_get_param_value(ast_node, "ELSET", elset_name)
        has_elset = (LEN_TRIM(elset_name) > 0)
        CALL sect_prop_get_param_value(ast_node, "ORIENTATION", orientation_name)
        has_orientation = (LEN_TRIM(orientation_name) > 0)
        CALL sect_prop_get_param_value(ast_node, "ALPHA", alpha_str)
        has_alpha = (LEN_TRIM(alpha_str) > 0)
        IF (has_alpha) THEN
            READ(alpha_str, *, IOSTAT=ios) alpha
            IF (ios /= 0) alpha = 0.0_wp
        ELSE
            alpha = 0.0_wp
        END IF
        CALL sect_prop_get_param_value(ast_node, "COMPOSITE", composite_str)
        has_composite = (LEN_TRIM(composite_str) > 0)
        IF (has_composite) THEN
            READ(composite_str, *, IOSTAT=ios) composite
            IF (ios /= 0) composite = 0.0_wp
        ELSE
            composite = 0.0_wp
        END IF
        IF (ast_node%data_line_count < 1) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "*ROTARY INERTIA requires at least one data line")
            RETURN
        END IF
        CALL Parse_ROTARYINERTIA_DataLine(ast_node%data_lines(1), &
                                          I11, I22, I33, I12, I13, I23, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        rotaryInertia%name      = "ROTARYINERTIA"
        rotaryInertia%nodeId    = 0
        rotaryInertia%Ixx = I11; rotaryInertia%Iyy = I22; rotaryInertia%Izz = I33
        rotaryInertia%Ixy = I12; rotaryInertia%Ixz = I13; rotaryInertia%Iyz = I23
        rotaryInertia%alpha     = alpha
        rotaryInertia%composite = composite
        IF (has_elset)       rotaryInertia%elsetName       = TRIM(elset_name)
        IF (has_orientation) rotaryInertia%orientationName = TRIM(orientation_name)
        IF (.NOT. rotaryInertia%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Rotary inertia validation failed"
        END IF
    END SUBROUTINE Parse_ROTARYINERTIA_Keyword

    !---------------------------------------------------------------------------
    ! SUBROUTINE: Validate_ROTARYINERTIA_Orientation
    ! PHASE:      P0
    ! PURPOSE:    Validate orientation reference for rotary inertia
    !---------------------------------------------------------------------------
    SUBROUTINE Validate_ROTARYINERTIA_Orientation(rotaryInertia, model, status)
        TYPE(RotInertiaDesc), INTENT(IN) :: rotaryInertia
        TYPE(UF_Model), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        ! TODO: implement when orientation system is available
    END SUBROUTINE Validate_ROTARYINERTIA_Orientation

    SUBROUTINE Validate_ROTARYINERTIA_PhysicalValues(rotaryInertia, status)
        TYPE(RotInertiaDesc), INTENT(IN) :: rotaryInertia
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (rotaryInertia%Ixx < 1.0e-6_wp .OR. rotaryInertia%Ixx > 1.0e6_wp .OR. &
            rotaryInertia%Iyy < 1.0e-6_wp .OR. rotaryInertia%Iyy > 1.0e6_wp .OR. &
            rotaryInertia%Izz < 1.0e-6_wp .OR. rotaryInertia%Izz > 1.0e6_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Inertia values out of reasonable range (1e-6 to 1e6 kg*m2)")
            RETURN
        END IF
        IF (rotaryInertia%alpha < 0.0_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Alpha (damping coef) must be non-negative")
            RETURN
        END IF
        IF (rotaryInertia%composite < 0.0_wp .OR. rotaryInertia%composite > 1.0_wp) THEN
            CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                "Composite damping must be between 0 and 1")
            RETURN
        END IF
    END SUBROUTINE Validate_ROTARYINERTIA_PhysicalValues

    SUBROUTINE Valid_ROTARYINERTIA_Keyword(rotaryInertia, model, status)
        TYPE(RotInertiaDesc), INTENT(IN) :: rotaryInertia
        TYPE(UF_Model), INTENT(IN), OPTIONAL :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (.NOT. rotaryInertia%Valid()) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Rotary inertia validation failed"
            RETURN
        END IF
        IF (PRESENT(model)) THEN
            IF (LEN_TRIM(rotaryInertia%elsetName) > 0) THEN
                CALL Valid_ROTARYINERTIA_Target(rotaryInertia, model, status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END IF
            IF (LEN_TRIM(rotaryInertia%orientationName) > 0) THEN
                CALL Validate_ROTARYINERTIA_Orientation(rotaryInertia, model, status)
                IF (status%status_code /= IF_STATUS_OK) RETURN
            END IF
        END IF
        CALL Validate_ROTARYINERTIA_PhysicalValues(rotaryInertia, status)
    END SUBROUTINE Valid_ROTARYINERTIA_Keyword

    SUBROUTINE Valid_ROTARYINERTIA_Target(rotaryInertia, model, status)
        TYPE(RotInertiaDesc), INTENT(IN) :: rotaryInertia
        TYPE(UF_Model), INTENT(IN) :: model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, part_idx
        LOGICAL :: elset_found
        CALL init_error_status(status)
        IF (LEN_TRIM(rotaryInertia%elsetName) > 0) THEN
            elset_found = .FALSE.
            DO part_idx = 1, SIZE(model%parts)
                IF (ALLOCATED(model%parts(part_idx)%elemSets)) THEN
                    DO i = 1, SIZE(model%parts(part_idx)%elemSets)
                        IF (TRIM(model%parts(part_idx)%elemSets(i)%name) == &
                            TRIM(rotaryInertia%elsetName)) THEN
                            elset_found = .TRUE.
                            EXIT
                        END IF
                    END DO
                END IF
                IF (elset_found) EXIT
            END DO
            IF (.NOT. elset_found) THEN
                CALL uf_set_error_status(status, IF_STATUS_INVALID, &
                    "Element set '" // TRIM(rotaryInertia%elsetName) // &
                    "' not found for *ROTARY INERTIA")
            END IF
        END IF
    END SUBROUTINE Valid_ROTARYINERTIA_Target

END MODULE MD_Sect_PropRotInertia