!===================================================================
! MODULE : MD_KW_Abaqus
! LAYER  : L3_MD
! DOMAIN : KeyWord (KW)
! ROLE   : Aggregate / Entry
! BRIEF  : Unified high-level interface for parsing ABAQUS INP files.
!          Re-exports commonly used types/constants from MD_KW_Def
!          and provides kw_parse_inp_file / kw_parse_inp_to_ast /
!          kw_map_ast_to_model entry points.
!===================================================================

MODULE MD_KW_Abaqus
    USE IF_Prec_Core, ONLY: wp, i4
    USE MD_KW_Lexer
    USE MD_KW_Mapper
    USE MD_KW_Parser
    USE MD_KW_Reg
    USE MD_KW_Reg_Ext, ONLY: register_extended_keywords
    USE MD_KW_Def
    USE MD_Model_Lib_Core
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! Re-export commonly used types and constants
    ! ==========================================================================
    PUBLIC :: KW_TokenType
    PUBLIC :: KW_ParamValueType
    PUBLIC :: KW_ASTNodeType
    PUBLIC :: KW_ParserStateType
    PUBLIC :: KW_MapperStateType
    
    ! Token types
    PUBLIC :: TOKEN_EOF, TOKEN_KEYWORD, TOKEN_DATA, TOKEN_COMMENT
    PUBLIC :: TOKEN_PARAM_NAME, TOKEN_PARAM_VALUE, TOKEN_COMMA, TOKEN_EQUALS
    
    ! Keyword categories
    PUBLIC :: KW_CAT_MODEL, KW_CAT_PART, KW_CAT_MESH, KW_CAT_MATERIAL
    PUBLIC :: KW_CAT_SECTION, KW_CAT_CONSTRAINT, KW_CAT_LOAD, KW_CAT_CONTACT
    PUBLIC :: KW_CAT_STEP, KW_CAT_OUTPUT, KW_CAT_AMPLITUDE, KW_CAT_SPECIAL

    ! ==========================================================================
    ! Public High-Level Interface
    ! ==========================================================================
    PUBLIC :: kw_parse_inp_file        ! Parse INP file directly to Model
    PUBLIC :: kw_parse_inp_to_ast      ! Parse INP file to AST only
    PUBLIC :: kw_map_ast_to_model      ! Map AST to Model
    PUBLIC :: kw_init_keyword_system   ! Initialize keyword system
    PUBLIC :: kw_print_statistics      ! Print parsing statistics
    PUBLIC :: kw_get_supported_keywords ! Get list of supported keywords

CONTAINS

    SUBROUTINE kw_get_supported_keywords(keywords, count)
        CHARACTER(LEN=KW_MAX_NAME_LEN), ALLOCATABLE, INTENT(OUT) :: keywords(:)
        INTEGER(i4), INTENT(OUT) :: count
        
        TYPE(KW_MetadataType) :: all_kw(512)
        INTEGER(i4) :: i
        
        CALL kw_init_keyword_system()
        CALL kw_registry_get_all(all_kw, count)
        
        IF (count > 0) THEN
            ALLOCATE(keywords(count))
            DO i = 1, count
                keywords(i) = all_kw(i)%keyword_name
            END DO
        END IF
    END SUBROUTINE kw_get_supported_keywords

    SUBROUTINE kw_init_keyword_system()
        IF (.NOT. kw_is_initialized()) THEN
            CALL kw_registry_init()
            CALL register_extended_keywords()
        END IF
    END SUBROUTINE kw_init_keyword_system

    SUBROUTINE kw_map_ast_to_model(parser, model, success)
        TYPE(KW_ParserStateType), INTENT(INOUT), TARGET :: parser
        TYPE(UF_ModelDef), INTENT(INOUT), TARGET :: model
        LOGICAL, INTENT(OUT) :: success
        
        TYPE(KW_MapperStateType) :: mapper
        
        CALL kw_mapper_init(mapper, parser, model)
        CALL kw_mapper_map_to_model(mapper, success)
        CALL kw_mapper_cleanup(mapper)
    END SUBROUTINE kw_map_ast_to_model

    SUBROUTINE kw_parse_inp_file(filename, model, success, verbose)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        TYPE(UF_ModelDef), INTENT(INOUT) :: model
        LOGICAL, INTENT(OUT) :: success
        LOGICAL, INTENT(IN), OPTIONAL :: verbose
        
        TYPE(KW_ParserStateType) :: parser
        TYPE(KW_MapperStateType) :: mapper
        LOGICAL :: parse_ok, map_ok, be_verbose
        INTEGER(i4) :: nodes, elements, materials, sections, steps
        
        success = .FALSE.
        be_verbose = .FALSE.
        IF (PRESENT(verbose)) be_verbose = verbose
        
        ! Initialize systems
        CALL kw_init_keyword_system()
        
        IF (be_verbose) THEN
            WRITE(*, '(A)') "==================================================="
            WRITE(*, '(A)') "UniField Abaqus INP Parser"
            WRITE(*, '(A)') "==================================================="
            WRITE(*, '(A,A)') "Input file: ", TRIM(filename)
            WRITE(*, '(A,I0,A)') "Registry: ", kw_registry_get_count(), " keywords registered"
        END IF
        
        ! Initialize parser
        CALL kw_parser_init(parser)
        
        ! Parse file to AST
        IF (be_verbose) WRITE(*, '(A)') "Parsing INP file..."
        CALL kw_parser_parse_file(parser, filename, parse_ok)
        
        IF (.NOT. parse_ok) THEN
            IF (be_verbose) THEN
                WRITE(*, '(A,I0,A)') "Parse failed with ", kw_parser_get_errors(parser), " errors"
            END IF
            CALL kw_parser_cleanup(parser)
            RETURN
        END IF
        
        IF (be_verbose) THEN
            WRITE(*, '(A,I0,A)') "Parsed ", parser%node_count, " keyword blocks"
        END IF
        
        ! Map AST to Model
        IF (be_verbose) WRITE(*, '(A)') "Mapping to model..."
        CALL kw_mapper_init(mapper, parser, model)
        CALL kw_mapper_map_to_model(mapper, map_ok)
        
        IF (be_verbose) THEN
            CALL kw_mapper_get_statistics(mapper, nodes, elements, materials, sections, steps)
            WRITE(*, '(A)') "Mapping complete:"
            WRITE(*, '(A,I0)') "  Nodes:     ", nodes
            WRITE(*, '(A,I0)') "  Elements:  ", elements
            WRITE(*, '(A,I0)') "  Materials: ", materials
            WRITE(*, '(A,I0)') "  Sections:  ", sections
            WRITE(*, '(A,I0)') "  Steps:     ", steps
        END IF
        
        ! Cleanup
        CALL kw_mapper_cleanup(mapper)
        CALL kw_parser_cleanup(parser)
        
        success = map_ok
        
        IF (be_verbose) THEN
            IF (success) THEN
                WRITE(*, '(A)') "INP file parsed successfully!"
            ELSE
                WRITE(*, '(A)') "INP parsing completed with errors."
            END IF
            WRITE(*, '(A)') "==================================================="
        END IF
    END SUBROUTINE kw_parse_inp_file

    SUBROUTINE kw_parse_inp_to_ast(filename, parser, success)
        CHARACTER(LEN=*), INTENT(IN) :: filename
        TYPE(KW_ParserStateType), INTENT(OUT) :: parser
        LOGICAL, INTENT(OUT) :: success
        
        CALL kw_init_keyword_system()
        CALL kw_parser_init(parser)
        CALL kw_parser_parse_file(parser, filename, success)
    END SUBROUTINE kw_parse_inp_to_ast

    SUBROUTINE kw_print_statistics(parser, mapper)
        TYPE(KW_ParserStateType), INTENT(IN) :: parser
        TYPE(KW_MapperStateType), INTENT(IN), OPTIONAL :: mapper
        
        INTEGER(i4) :: nodes, elements, materials, sections, steps
        INTEGER(i4) :: i, cat_counts(20)
        
        WRITE(*, '(A)') ""
        WRITE(*, '(A)') "=== INP Parsing Statistics ==="
        WRITE(*, '(A)') ""
        WRITE(*, '(A,I0)') "Total AST nodes:     ", parser%node_count
        WRITE(*, '(A,I0)') "Parse errors:        ", parser%error_count
        WRITE(*, '(A,I0)') "Parse warnings:      ", parser%warning_count
        WRITE(*, '(A,I0)') "Lines read:          ", parser%lexer%total_lines
        WRITE(*, '(A,I0)') "Tokens produced:     ", parser%lexer%total_tokens
        
        ! Count by category
        cat_counts = 0
        DO i = 1, parser%node_count
            IF (parser%nodes(i)%category >= 1 .AND. parser%nodes(i)%category <= 20) THEN
                cat_counts(parser%nodes(i)%category) = cat_counts(parser%nodes(i)%category) + 1
            END IF
        END DO
        
        WRITE(*, '(A)') ""
        WRITE(*, '(A)') "Keywords by category:"
        WRITE(*, '(A,I0)') "  Model:       ", cat_counts(KW_CAT_MODEL)
        WRITE(*, '(A,I0)') "  Part:        ", cat_counts(KW_CAT_PART)
        WRITE(*, '(A,I0)') "  Mesh:        ", cat_counts(KW_CAT_MESH)
        WRITE(*, '(A,I0)') "  Material:    ", cat_counts(KW_CAT_MATERIAL)
        WRITE(*, '(A,I0)') "  Section:     ", cat_counts(KW_CAT_SECTION)
        WRITE(*, '(A,I0)') "  Constraint:  ", cat_counts(KW_CAT_CONSTRAINT)
        WRITE(*, '(A,I0)') "  Load:        ", cat_counts(KW_CAT_LOAD)
        WRITE(*, '(A,I0)') "  Contact:     ", cat_counts(KW_CAT_CONTACT)
        WRITE(*, '(A,I0)') "  Step:        ", cat_counts(KW_CAT_STEP)
        WRITE(*, '(A,I0)') "  Output:      ", cat_counts(KW_CAT_OUTPUT)
        WRITE(*, '(A,I0)') "  Amplitude:   ", cat_counts(KW_CAT_AMPLITUDE)
        WRITE(*, '(A,I0)') "  Special:     ", cat_counts(KW_CAT_SPECIAL)
        
        IF (PRESENT(mapper)) THEN
            CALL kw_mapper_get_statistics(mapper, nodes, elements, materials, sections, steps)
            WRITE(*, '(A)') ""
            WRITE(*, '(A)') "Mapped entities:"
            WRITE(*, '(A,I0)') "  Nodes:       ", nodes
            WRITE(*, '(A,I0)') "  Elements:    ", elements
            WRITE(*, '(A,I0)') "  Materials:   ", materials
            WRITE(*, '(A,I0)') "  Sections:    ", sections
            WRITE(*, '(A,I0)') "  Steps:       ", steps
        END IF
        
        WRITE(*, '(A)') ""
        WRITE(*, '(A)') "==============================="
    END SUBROUTINE kw_print_statistics
END MODULE MD_KW_Abaqus