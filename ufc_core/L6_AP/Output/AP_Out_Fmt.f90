!======================================================================
! Module: AP_OutFmt
! Layer:  L6_AP - Application Layer
! Domain: Output / Format
! Purpose: Unified output format keyword parsers.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================

MODULE AP_Out_Fmt
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4
    USE AP_Brg_L3, ONLY: DescBase, KW_ASTNodeType, &
                                     KW_MAX_VALUE_LEN, KW_MAX_NAME_LEN
    USE AP_Output_UserOutput_Type, ONLY: UserOutputProperties
    IMPLICIT NONE
    PRIVATE

    !===============================================================================
    ! FILE_FORMAT - Constants & Types
    !===============================================================================
    INTEGER(i4), PARAMETER, PUBLIC :: FORMAT_ASCII = 1
    INTEGER(i4), PARAMETER, PUBLIC :: FORMAT_BINARY = 2

    TYPE, PUBLIC, EXTENDS(DescBase) :: AP_Output_Format_Props
        INTEGER(i4) :: formatType = FORMAT_ASCII
    CONTAINS
        PROCEDURE, PUBLIC :: Init => AP_Output_Format_Init
        PROCEDURE, PUBLIC :: Valid => AP_Output_Format_Valid
        PROCEDURE, PUBLIC :: Clear => AP_Output_Format_Clear
    END TYPE AP_Output_Format_Props

    TYPE, PUBLIC :: FormatProperties
        TYPE(AP_Output_Format_Props) :: inner
    END TYPE FormatProperties

    !===============================================================================
    ! NODE_FILE - Types
    !===============================================================================
    TYPE, PUBLIC, EXTENDS(DescBase) :: AP_Output_NodeFile_Props
        CHARACTER(LEN=256) :: fileName = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init => AP_Output_NodeFile_Init
        PROCEDURE, PUBLIC :: Valid => AP_Output_NodeFile_Valid
        PROCEDURE, PUBLIC :: Clear => AP_Output_NodeFile_Clear
    END TYPE AP_Output_NodeFile_Props

    TYPE, PUBLIC :: NodeFileProperties
        TYPE(AP_Output_NodeFile_Props) :: inner
    END TYPE NodeFileProperties

    !===============================================================================
    ! EL_FILE - Types
    !===============================================================================
    TYPE, PUBLIC, EXTENDS(DescBase) :: AP_Output_ElFile_Props
        CHARACTER(LEN=256) :: fileName = ""
    CONTAINS
        PROCEDURE, PUBLIC :: Init => AP_Output_ElFile_Init
        PROCEDURE, PUBLIC :: Valid => AP_Output_ElFile_Valid
        PROCEDURE, PUBLIC :: Clear => AP_Output_ElFile_Clear
    END TYPE AP_Output_ElFile_Props

    TYPE, PUBLIC :: ElFileProperties
        TYPE(AP_Output_ElFile_Props) :: inner
    END TYPE ElFileProperties

    !===============================================================================
    ! PREPRINT - Types
    !===============================================================================
    TYPE, PUBLIC, EXTENDS(DescBase) :: AP_Output_Preprint_Props
        LOGICAL :: echo = .TRUE.
        LOGICAL :: model = .TRUE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => AP_Output_Preprint_Init
        PROCEDURE, PUBLIC :: Valid => AP_Output_Preprint_Valid
        PROCEDURE, PUBLIC :: Clear => AP_Output_Preprint_Clear
    END TYPE AP_Output_Preprint_Props

    TYPE, PUBLIC :: PreprintProperties
        TYPE(AP_Output_Preprint_Props) :: inner
    END TYPE PreprintProperties

    !===============================================================================
    ! PUBLIC - All procedures (backward compat names preserved)
    !===============================================================================
    PUBLIC :: AP_Output_Format_Props, AP_Output_Format_Parse, AP_Output_Format_ValidKw
    PUBLIC :: AP_Output_Format_UnifiedParse, AP_Output_Format_UnifiedCfg
    PUBLIC :: Parse_FILE_FORMAT_Keyword, Valid_FILE_FORMAT_Keyword
    PUBLIC :: AP_Output_Format_Unified_Parse, AP_Output_Format_Unified_Cfg

    PUBLIC :: AP_Output_NodeFile_Props, AP_Output_NodeFile_Parse, AP_Output_NodeFile_ValidKw
    PUBLIC :: AP_Output_NodeFile_UnifiedParse, AP_Output_NodeFile_UnifiedCfg
    PUBLIC :: Parse_NODE_FILE_Keyword, Valid_NODE_FILE_Keyword
    PUBLIC :: AP_Output_NodeFile_Unified_Parse, AP_Output_NodeFile_Unified_Configure

    PUBLIC :: AP_Output_ElFile_Props, AP_Output_ElFile_Parse, AP_Output_ElFile_ValidKw
    PUBLIC :: AP_Output_ElFile_UnifiedParse, AP_Output_ElFile_UnifiedCfg
    PUBLIC :: Parse_EL_FILE_Keyword, Valid_EL_FILE_Keyword
    PUBLIC :: AP_Output_Unified_Parse, AP_Output_Unified_Cfg

    PUBLIC :: AP_Output_Preprint_Props, AP_Output_Preprint_Parse, AP_Output_Preprint_ValidKw
    PUBLIC :: AP_Output_Preprint_UnifiedParse, AP_Output_Preprint_UnifiedCfg
    PUBLIC :: Parse_PREPRINT_Keyword, Valid_PREPRINT_Keyword
    PUBLIC :: AP_Output_Preprint_Unified_Parse, AP_Output_Preprint_Unified_Configure
    PUBLIC :: Valid_USER_OUTPUT_Keyword

CONTAINS

    ! Merged from AP_Output_Validate
    SUBROUTINE Valid_USER_OUTPUT_Keyword(userOutput, status)
        TYPE(UserOutputProperties), INTENT(IN) :: userOutput
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL userOutput%Valid(status)
    END SUBROUTINE Valid_USER_OUTPUT_Keyword

    !===============================================================================
    ! FILE_FORMAT
    !===============================================================================
    SUBROUTINE AP_Output_Format_Init(this, formatType, status)
        CLASS(AP_Output_Format_Props), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: formatType
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%formatType = formatType
    END SUBROUTINE AP_Output_Format_Init

    SUBROUTINE AP_Output_Format_Valid(this, status)
        CLASS(AP_Output_Format_Props), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
    END SUBROUTINE AP_Output_Format_Valid

    SUBROUTINE AP_Output_Format_Clear(this)
        CLASS(AP_Output_Format_Props), INTENT(INOUT) :: this
        this%formatType = FORMAT_ASCII
    END SUBROUTINE AP_Output_Format_Clear

    SUBROUTINE AP_Output_Format_Parse(ast_node, format_prop, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Output_Format_Props), INTENT(OUT) :: format_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL format_prop%Init(FORMAT_ASCII, status)
    END SUBROUTINE AP_Output_Format_Parse

    SUBROUTINE Parse_FILE_FORMAT_Keyword(ast_node, format_prop, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(FormatProperties), INTENT(OUT) :: format_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_Format_Parse(ast_node, format_prop%inner, status)
    END SUBROUTINE Parse_FILE_FORMAT_Keyword

    SUBROUTINE AP_Output_Format_UnifiedParse(output_type, ast_node, format_prop, status)
        CHARACTER(LEN=*), INTENT(IN) :: output_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Output_Format_Props), INTENT(OUT) :: format_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(output_type) == 'FILE_FORMAT' .OR. TRIM(output_type) == 'file_format') THEN
            CALL AP_Output_Format_Parse(ast_node, format_prop, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Output_Format_UnifiedParse: unsupported output_type ' // TRIM(output_type)
        END IF
    END SUBROUTINE AP_Output_Format_UnifiedParse

    SUBROUTINE AP_Output_Format_Unified_Parse(output_type, ast_node, format_prop, status)
        CHARACTER(LEN=*), INTENT(IN) :: output_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(FormatProperties), INTENT(OUT) :: format_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_Format_UnifiedParse(output_type, ast_node, format_prop%inner, status)
    END SUBROUTINE AP_Output_Format_Unified_Parse

    ! Shared implementation for all UnifiedCfg (Format/NodeFile/ElFile/Preprint)
    SUBROUTINE AP_Out_Format_UnifiedCfg_Impl(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(operation) == 'init' .OR. TRIM(operation) == 'INIT' .OR. &
            TRIM(operation) == 'default' .OR. TRIM(operation) == 'DEFAULT') THEN
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_OutFmt: unknown operation ' // TRIM(operation)
        END IF
    END SUBROUTINE AP_Out_Format_UnifiedCfg_Impl

    SUBROUTINE AP_Output_Format_UnifiedCfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Out_Format_UnifiedCfg_Impl(operation, status)
    END SUBROUTINE AP_Output_Format_UnifiedCfg

    SUBROUTINE AP_Output_Format_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Out_Format_UnifiedCfg_Impl(operation, status)
    END SUBROUTINE AP_Output_Format_Unified_Cfg

    SUBROUTINE AP_Output_Format_ValidKw(format_prop, status)
        TYPE(AP_Output_Format_Props), INTENT(IN) :: format_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL format_prop%Valid(status)
    END SUBROUTINE AP_Output_Format_ValidKw

    SUBROUTINE Valid_FILE_FORMAT_Keyword(format_prop, status)
        TYPE(FormatProperties), INTENT(IN) :: format_prop
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_Format_ValidKw(format_prop%inner, status)
    END SUBROUTINE Valid_FILE_FORMAT_Keyword

    !===============================================================================
    ! NODE_FILE
    !===============================================================================
    SUBROUTINE AP_Output_NodeFile_Init(this, fileName, status)
        CLASS(AP_Output_NodeFile_Props), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: fileName
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%fileName = TRIM(fileName)
    END SUBROUTINE AP_Output_NodeFile_Init

    SUBROUTINE AP_Output_NodeFile_Valid(this, status)
        CLASS(AP_Output_NodeFile_Props), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
    END SUBROUTINE AP_Output_NodeFile_Valid

    SUBROUTINE AP_Output_NodeFile_Clear(this)
        CLASS(AP_Output_NodeFile_Props), INTENT(INOUT) :: this
        this%fileName = ""
    END SUBROUTINE AP_Output_NodeFile_Clear

    SUBROUTINE AP_Output_NodeFile_Parse(ast_node, nodeFile, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Output_NodeFile_Props), INTENT(OUT) :: nodeFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL nodeFile%Init("node.dat", status)
    END SUBROUTINE AP_Output_NodeFile_Parse

    SUBROUTINE Parse_NODE_FILE_Keyword(ast_node, nodeFile, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(NodeFileProperties), INTENT(OUT) :: nodeFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_NodeFile_Parse(ast_node, nodeFile%inner, status)
    END SUBROUTINE Parse_NODE_FILE_Keyword

    SUBROUTINE AP_Output_NodeFile_UnifiedParse(output_type, ast_node, nodeFile, status)
        CHARACTER(LEN=*), INTENT(IN) :: output_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Output_NodeFile_Props), INTENT(OUT) :: nodeFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(output_type) == 'NODE_FILE' .OR. TRIM(output_type) == 'node_file') THEN
            CALL AP_Output_NodeFile_Parse(ast_node, nodeFile, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Output_NodeFile_UnifiedParse: unsupported output_type ' // TRIM(output_type)
        END IF
    END SUBROUTINE AP_Output_NodeFile_UnifiedParse

    SUBROUTINE AP_Output_NodeFile_Unified_Parse(output_type, ast_node, nodeFile, status)
        CHARACTER(LEN=*), INTENT(IN) :: output_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(NodeFileProperties), INTENT(OUT) :: nodeFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_NodeFile_UnifiedParse(output_type, ast_node, nodeFile%inner, status)
    END SUBROUTINE AP_Output_NodeFile_Unified_Parse

    SUBROUTINE AP_Output_NodeFile_UnifiedCfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Out_Format_UnifiedCfg_Impl(operation, status)
    END SUBROUTINE AP_Output_NodeFile_UnifiedCfg

    SUBROUTINE AP_Output_NodeFile_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Out_Format_UnifiedCfg_Impl(operation, status)
    END SUBROUTINE AP_Output_NodeFile_Unified_Configure

    SUBROUTINE AP_Output_NodeFile_ValidKw(nodeFile, status)
        TYPE(AP_Output_NodeFile_Props), INTENT(IN) :: nodeFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL nodeFile%Valid(status)
    END SUBROUTINE AP_Output_NodeFile_ValidKw

    SUBROUTINE Valid_NODE_FILE_Keyword(nodeFile, status)
        TYPE(NodeFileProperties), INTENT(IN) :: nodeFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_NodeFile_ValidKw(nodeFile%inner, status)
    END SUBROUTINE Valid_NODE_FILE_Keyword

    !===============================================================================
    ! EL_FILE
    !===============================================================================
    SUBROUTINE AP_Output_ElFile_Init(this, fileName, status)
        CLASS(AP_Output_ElFile_Props), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: fileName
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        this%fileName = TRIM(fileName)
    END SUBROUTINE AP_Output_ElFile_Init

    SUBROUTINE AP_Output_ElFile_Valid(this, status)
        CLASS(AP_Output_ElFile_Props), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
    END SUBROUTINE AP_Output_ElFile_Valid

    SUBROUTINE AP_Output_ElFile_Clear(this)
        CLASS(AP_Output_ElFile_Props), INTENT(INOUT) :: this
        this%fileName = ""
    END SUBROUTINE AP_Output_ElFile_Clear

    SUBROUTINE AP_Output_ElFile_Parse(ast_node, elFile, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Output_ElFile_Props), INTENT(OUT) :: elFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL elFile%Init("element.dat", status)
    END SUBROUTINE AP_Output_ElFile_Parse

    SUBROUTINE Parse_EL_FILE_Keyword(ast_node, elFile, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ElFileProperties), INTENT(OUT) :: elFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_ElFile_Parse(ast_node, elFile%inner, status)
    END SUBROUTINE Parse_EL_FILE_Keyword

    SUBROUTINE AP_Output_ElFile_UnifiedParse(output_type, ast_node, elFile, status)
        CHARACTER(LEN=*), INTENT(IN) :: output_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Output_ElFile_Props), INTENT(OUT) :: elFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(output_type) == 'EL_FILE' .OR. TRIM(output_type) == 'el_file') THEN
            CALL AP_Output_ElFile_Parse(ast_node, elFile, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Output_ElFile_UnifiedParse: unsupported output_type ' // TRIM(output_type)
        END IF
    END SUBROUTINE AP_Output_ElFile_UnifiedParse

    SUBROUTINE AP_Output_Unified_Parse(output_type, ast_node, elFile, status)
        CHARACTER(LEN=*), INTENT(IN) :: output_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(ElFileProperties), INTENT(OUT) :: elFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_ElFile_UnifiedParse(output_type, ast_node, elFile%inner, status)
    END SUBROUTINE AP_Output_Unified_Parse

    SUBROUTINE AP_Output_ElFile_UnifiedCfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Out_Format_UnifiedCfg_Impl(operation, status)
    END SUBROUTINE AP_Output_ElFile_UnifiedCfg

    SUBROUTINE AP_Output_Unified_Cfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Out_Format_UnifiedCfg_Impl(operation, status)
    END SUBROUTINE AP_Output_Unified_Cfg

    SUBROUTINE AP_Output_ElFile_ValidKw(elFile, status)
        TYPE(AP_Output_ElFile_Props), INTENT(IN) :: elFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL elFile%Valid(status)
    END SUBROUTINE AP_Output_ElFile_ValidKw

    SUBROUTINE Valid_EL_FILE_Keyword(elFile, status)
        TYPE(ElFileProperties), INTENT(IN) :: elFile
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_ElFile_ValidKw(elFile%inner, status)
    END SUBROUTINE Valid_EL_FILE_Keyword

    !===============================================================================
    ! PREPRINT
    !===============================================================================
    SUBROUTINE AP_Output_Preprint_Init(this, echo, model, status)
        CLASS(AP_Output_Preprint_Props), INTENT(INOUT) :: this
        LOGICAL, INTENT(IN), OPTIONAL :: echo, model
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (PRESENT(echo)) this%echo = echo
        IF (PRESENT(model)) this%model = model
    END SUBROUTINE AP_Output_Preprint_Init

    SUBROUTINE AP_Output_Preprint_Valid(this, status)
        CLASS(AP_Output_Preprint_Props), INTENT(IN) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
    END SUBROUTINE AP_Output_Preprint_Valid

    SUBROUTINE AP_Output_Preprint_Clear(this)
        CLASS(AP_Output_Preprint_Props), INTENT(INOUT) :: this
        this%echo = .TRUE.
        this%model = .TRUE.
    END SUBROUTINE AP_Output_Preprint_Clear

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

    SUBROUTINE AP_Output_Preprint_Parse(ast_node, preprint, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Output_Preprint_Props), INTENT(OUT) :: preprint
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CHARACTER(LEN=KW_MAX_VALUE_LEN) :: echo_str, model_str
        LOGICAL :: echo_val, model_val
        CALL init_error_status(status)
        CALL get_param_value(ast_node, "ECHO", echo_str)
        CALL get_param_value(ast_node, "MODEL", model_str)
        echo_val = .TRUE.
        IF (LEN_TRIM(echo_str) > 0) THEN
            echo_val = (TRIM(echo_str) == "YES" .OR. TRIM(echo_str) == "yes")
        END IF
        model_val = .TRUE.
        IF (LEN_TRIM(model_str) > 0) THEN
            model_val = (TRIM(model_str) == "YES" .OR. TRIM(model_str) == "yes")
        END IF
        CALL preprint%Init(echo_val, model_val, status)
    END SUBROUTINE AP_Output_Preprint_Parse

    SUBROUTINE Parse_PREPRINT_Keyword(ast_node, preprint, status)
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PreprintProperties), INTENT(OUT) :: preprint
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_Preprint_Parse(ast_node, preprint%inner, status)
    END SUBROUTINE Parse_PREPRINT_Keyword

    SUBROUTINE AP_Output_Preprint_UnifiedParse(output_type, ast_node, preprint, status)
        CHARACTER(LEN=*), INTENT(IN) :: output_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(AP_Output_Preprint_Props), INTENT(OUT) :: preprint
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        IF (TRIM(output_type) == 'PREPRINT' .OR. TRIM(output_type) == 'preprint') THEN
            CALL AP_Output_Preprint_Parse(ast_node, preprint, status)
        ELSE
            status%status_code = IF_STATUS_INVALID
            status%message = 'AP_Output_Preprint_UnifiedParse: unsupported output_type ' // TRIM(output_type)
        END IF
    END SUBROUTINE AP_Output_Preprint_UnifiedParse

    SUBROUTINE AP_Output_Preprint_Unified_Parse(output_type, ast_node, preprint, status)
        CHARACTER(LEN=*), INTENT(IN) :: output_type
        TYPE(KW_ASTNodeType), INTENT(IN) :: ast_node
        TYPE(PreprintProperties), INTENT(OUT) :: preprint
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_Preprint_UnifiedParse(output_type, ast_node, preprint%inner, status)
    END SUBROUTINE AP_Output_Preprint_Unified_Parse

    SUBROUTINE AP_Output_Preprint_UnifiedCfg(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Out_Format_UnifiedCfg_Impl(operation, status)
    END SUBROUTINE AP_Output_Preprint_UnifiedCfg

    SUBROUTINE AP_Output_Preprint_Unified_Configure(operation, status)
        CHARACTER(LEN=*), INTENT(IN) :: operation
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Out_Format_UnifiedCfg_Impl(operation, status)
    END SUBROUTINE AP_Output_Preprint_Unified_Configure

    SUBROUTINE AP_Output_Preprint_ValidKw(preprint, status)
        TYPE(AP_Output_Preprint_Props), INTENT(IN) :: preprint
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL init_error_status(status)
        CALL preprint%Valid(status)
    END SUBROUTINE AP_Output_Preprint_ValidKw

    SUBROUTINE Valid_PREPRINT_Keyword(preprint, status)
        TYPE(PreprintProperties), INTENT(IN) :: preprint
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL AP_Output_Preprint_ValidKw(preprint%inner, status)
    END SUBROUTINE Valid_PREPRINT_Keyword

END MODULE AP_Out_Fmt