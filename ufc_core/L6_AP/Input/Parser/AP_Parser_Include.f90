!===============================================================================
! MODULE: AP_Parser_Include
! LAYER:  L6_AP
! DOMAIN: Input/Parser
! ROLE:   Impl — include file parsing for *INCLUDE keyword
! BRIEF:  Include file parsing for *INCLUDE keyword.
!
! Process phases:
!   P1: AP_Parser_Include_Process / AP_Parser_Include_Resolve
!===============================================================================
MODULE AP_Parser_Include
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, error_set
    USE IF_Prec_Core, ONLY: wp, i4
    ! UFC Parser API imports - via Bridge module
    USE AP_Brg_L3, ONLY: DescBase, KW_ASTNodeType, &
                                     KW_MAX_VALUE_LEN, KW_MAX_NAME_LEN
    IMPLICIT NONE
    PRIVATE

    !===============================================================================
    ! Type Definitions
    !===============================================================================
    TYPE, PUBLIC, EXTENDS(DescBase) :: AP_Parser_Include_Props
        CHARACTER(LEN=512) :: inputFile = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init => AP_Parser_Include_Init
        PROCEDURE, PUBLIC :: Valid => AP_Parser_Include_Valid
        PROCEDURE, PUBLIC :: Clear => AP_Parser_Include_Clear
    END TYPE AP_Parser_Include_Props

    PUBLIC :: AP_Parser_Include_Props
    ! Type alias for backward compatibility
    TYPE, PUBLIC :: IncludeProperties
        TYPE(AP_Parser_Include_Props) :: inner
    END TYPE IncludeProperties

    !===============================================================================
    ! Public Procedures
    !===============================================================================
    PUBLIC :: AP_Parser_Include_Parse
    PUBLIC :: AP_Parser_Include_ValidKw
    PUBLIC :: AP_Parser_UnifiedParse
    PUBLIC :: AP_Parser_UnifiedCfg
    ! Backward compatibility
    PUBLIC :: Parse_INCLUDE_Keyword
    PUBLIC :: Valid_INCLUDE_Keyword
    PUBLIC :: AP_Parser_Unified_Parse
    PUBLIC :: AP_Parser_Unified_Cfg

CONTAINS

    !===============================================================================
    ! Type-bound Procedures
    !===============================================================================
    SUBROUTINE AP_Parser_Include_Init(this, inputFile, status)
        CLASS(AP_Parser_Include_Props), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: inputFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%inputFile = TRIM(inputFile)
    END SUBROUTINE AP_Parser_Include_Init

    SUBROUTINE AP_Parser_Include_Valid(this, status)
        CLASS(AP_Parser_Include_Props), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (LEN_TRIM(this%inputFile) == 0) THEN
            CALL error_set(IF_STATUS_INVALID, "INCLUDE input file must be specified", status=status)
        END IF
    END SUBROUTINE AP_Parser_Include_Valid

    SUBROUTINE AP_Parser_Include_Clear(this)
        CLASS(AP_Parser_Include_Props), INTENT(INOUT) :: this
        this%inputFile = ""
    END SUBROUTINE AP_Parser_Include_Clear

    !===============================================================================
    ! Parse Procedures (merged from AP_Parser_Include_Parse)
    !===============================================================================
    SUBROUTINE AP_Parser_Include_Parse(ast_node, include_prop, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Parser_Include_Props), INTENT(OUT) :: include_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: input_str
        CALL init_error_status(status)
        CALL get_param_value(ast_node, "INPUT", input_str)
        CALL include_prop%Init(TRIM(input_str), status)
    END SUBROUTINE AP_Parser_Include_Parse

    SUBROUTINE get_param_value(ast_node, param_name, param_value)
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
    END SUBROUTINE get_param_value

    ! Backward compatibility wrapper
    SUBROUTINE Parse_INCLUDE_Keyword(ast_node, include_prop, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(IncludeProperties), INTENT(OUT) :: include_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Parser_Include_Parse(ast_node, include_prop%inner, status)
    END SUBROUTINE Parse_INCLUDE_Keyword

    SUBROUTINE AP_Parser_UnifiedParse(keyword_type, ast_node, include_prop, status)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Parser_Include_Props), INTENT(OUT) :: include_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(keyword_type) == 'INCLUDE' .OR. TRIM(keyword_type) == 'include') THEN
            CALL AP_Parser_Include_Parse(ast_node, include_prop, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Parser_UnifiedParse: unsupported keyword_type ' // TRIM(keyword_type)
        END IF
    END SUBROUTINE AP_Parser_UnifiedParse

    ! Backward compatibility wrapper
    SUBROUTINE AP_Parser_Unified_Parse(keyword_type, ast_node, include_prop, status)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(IncludeProperties), INTENT(OUT) :: include_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Parser_UnifiedParse(keyword_type, ast_node, include_prop%inner, status)
    END SUBROUTINE AP_Parser_Unified_Parse

    SUBROUTINE AP_Parser_UnifiedCfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
            ! Placeholder: no module-level config yet
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Parser_UnifiedCfg: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE AP_Parser_UnifiedCfg

    ! Backward compatibility wrapper
    SUBROUTINE AP_Parser_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Parser_UnifiedCfg(operation, status)
    END SUBROUTINE AP_Parser_Unified_Cfg

    !===============================================================================
    ! Validate Procedures (merged from AP_Parser_Include_Validate)
    !===============================================================================
    SUBROUTINE AP_Parser_Include_ValidKw(include_prop, status)
        TYPE(AP_Parser_Include_Props), INTENT(IN) :: include_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL include_prop%Valid(status)
    END SUBROUTINE AP_Parser_Include_ValidKw

    ! Backward compatibility wrapper
    SUBROUTINE Valid_INCLUDE_Keyword(include_prop, status)
        TYPE(IncludeProperties), INTENT(IN) :: include_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Parser_Include_ValidKw(include_prop%inner, status)
    END SUBROUTINE Valid_INCLUDE_Keyword

END MODULE AP_Parser_Include
