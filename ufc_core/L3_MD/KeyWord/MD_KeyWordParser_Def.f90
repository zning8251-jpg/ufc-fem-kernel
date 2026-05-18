!===================================================================
! MODULE:  MD_KeyWordParser_Def
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Def
! BRIEF:   Type definitions for recursive keyword parser.
!          Defines AST node, parsing rule, and param spec types.
!===================================================================
MODULE MD_KeyWordParser_Def
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: KeyWord_Node_Type
  PUBLIC :: KeyWord_ParsingRule_Type
  PUBLIC :: KeyWord_ParamSpec_Type
  PUBLIC :: MD_KW_NodeFactory
  PUBLIC :: MD_KW_RuleFactory
  PUBLIC :: MD_KW_TreeInit
  PUBLIC :: MD_KW_TreePrint

  ! [REMOVED] Legacy aliases MD_KeyWord_NodeFactory, MD_KeyWord_RuleFactory (migrated to canonical names)
  ! [REMOVED] Legacy aliases MD_KeyWord_Tree_Init, MD_KeyWord_Tree_Print (no external refs)


  !-----------------------------------------------------------------
  ! TYPE:  KeyWord_Node_Type
  ! KIND:  Desc
  ! DESC:  AST node representing one ABAQUS keyword block
  !        Lifecycle: create -> parse params -> recurse -> validate
  !-----------------------------------------------------------------
  TYPE :: KeyWord_Node_Type
    ! Identifiers
    CHARACTER(LEN=32) :: keyword_name  = ""                     ! [in]  Keyword name
    INTEGER(i4)       :: node_id       = 0_i4                   ! [out] Unique node ID
    INTEGER(i4)       :: parent_id     = -1_i4                  ! [in]  Parent node ID
    INTEGER(i4)       :: nesting_level = 0_i4                   ! [in]  Nesting depth

    ! Parameter block
    CHARACTER(LEN=32), POINTER  :: params(:)        => NULL()   ! [out] Param names
    INTEGER(i4)                 :: n_params         = 0_i4      ! [out] Param count
    REAL(wp), POINTER           :: param_values(:)  => NULL()   ! [out] Numeric values
    CHARACTER(LEN=256), POINTER :: param_strings(:) => NULL()   ! [out] String values

    ! Data block
    REAL(wp), POINTER  :: data_block(:,:) => NULL()             ! [out] Data matrix
    INTEGER(i4)        :: n_rows = 0_i4                         ! [out] Row count
    INTEGER(i4)        :: n_cols = 0_i4                         ! [out] Column count
    CHARACTER(LEN=256) :: data_block_description = ""           ! [in]  Data description

    ! Nested keyword tree
    TYPE(KeyWord_Node_Type), POINTER :: child_keywords(:) => NULL()  ! [out] Children
    INTEGER(i4)                      :: n_children = 0_i4            ! [out] Child count

    ! Metadata
    INTEGER(i4) :: line_number  = 0_i4                          ! [out] Source line number
    LOGICAL     :: is_complete  = .FALSE.                       ! [out] Parse complete?
    LOGICAL     :: is_validated = .FALSE.                       ! [out] Validation done?
  END TYPE KeyWord_Node_Type


  !-----------------------------------------------------------------
  ! TYPE:  KeyWord_ParsingRule_Type
  ! KIND:  Algo
  ! DESC:  Parsing rule for one keyword (param format, nesting)
  !        Lifecycle: initialized at startup, read-only during parse
  !-----------------------------------------------------------------
  TYPE :: KeyWord_ParsingRule_Type
    CHARACTER(LEN=32)  :: keyword_name   = ""                   ! [in] Keyword name
    CHARACTER(LEN=32)  :: parent_keyword = ""                   ! [in] Parent keyword
    CHARACTER(LEN=256) :: description    = ""                   ! [in] Description

    ! Parameter specifications
    TYPE(KeyWord_ParamSpec_Type), POINTER :: param_specs(:) => NULL()  ! [in]
    INTEGER(i4)                          :: n_param_specs = 0_i4      ! [in]

    ! Data block specification
    LOGICAL            :: has_data_block    = .FALSE.            ! [in] Has data block?
    CHARACTER(LEN=256) :: data_block_format = ""                 ! [in] Format string
    INTEGER(i4)        :: expected_fields   = -1_i4              ! [in] Expected fields

    ! Nesting constraints
    CHARACTER(LEN=32), POINTER :: allowed_children(:) => NULL() ! [in] Valid children
    INTEGER(i4)                :: n_allowed_children = 0_i4     ! [in] Child count

    ! Priority and classification
    INTEGER(i4)        :: priority = 1_i4                       ! [in] P0/P1/P2
    CHARACTER(LEN=32)  :: category = "GENERAL"                  ! [in] Category string
  END TYPE KeyWord_ParsingRule_Type


  !-----------------------------------------------------------------
  ! TYPE:  KeyWord_ParamSpec_Type
  ! KIND:  Desc
  ! DESC:  Single parameter specification (name, type, constraints)
  !-----------------------------------------------------------------
  TYPE :: KeyWord_ParamSpec_Type
    CHARACTER(LEN=32)  :: param_name             = ""           ! [in] Parameter name
    CHARACTER(LEN=16)  :: param_type             = "STRING"     ! [in] Type (INT/REAL/STRING/LOGICAL)
    LOGICAL            :: is_required            = .FALSE.      ! [in] Required?
    CHARACTER(LEN=256) :: default_value          = ""           ! [in] Default value
    CHARACTER(LEN=256) :: constraint_description = ""           ! [in] Constraint description
  END TYPE KeyWord_ParamSpec_Type

CONTAINS

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_NodeFactory
  ! PHASE:      P0
  ! PURPOSE:    Create and initialize a keyword AST node
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_NodeFactory(keyword_name, parent_id, nesting_level, &
                               node, status)
    CHARACTER(LEN=*), INTENT(IN)          :: keyword_name       ! [in]  Keyword name
    INTEGER(i4), INTENT(IN)               :: parent_id          ! [in]  Parent node ID
    INTEGER(i4), INTENT(IN)               :: nesting_level      ! [in]  Nesting depth
    TYPE(KeyWord_Node_Type), INTENT(OUT)  :: node               ! [out] Created node
    TYPE(ErrorStatusType), INTENT(OUT)    :: status              ! [out] Error status

    node%keyword_name  = TRIM(ADJUSTL(keyword_name))
    node%parent_id     = parent_id
    node%nesting_level = nesting_level
    node%node_id       = 0_i4
    node%is_complete   = .FALSE.
    node%is_validated  = .FALSE.

    ALLOCATE(node%params(0))
    ALLOCATE(node%param_values(0))
    ALLOCATE(node%param_strings(0))
    ALLOCATE(node%data_block(0, 0))
    ALLOCATE(node%child_keywords(0))

    status%status_code = 0
  END SUBROUTINE MD_KW_NodeFactory

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_RuleFactory
  ! PHASE:      P0
  ! PURPOSE:    Create a keyword parsing rule
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_RuleFactory(keyword_name, parent_keyword, &
                               has_data_block, n_param_specs, &
                               rule, status)
    CHARACTER(LEN=*), INTENT(IN)                :: keyword_name     ! [in]
    CHARACTER(LEN=*), INTENT(IN)                :: parent_keyword   ! [in]
    LOGICAL, INTENT(IN)                         :: has_data_block   ! [in]
    INTEGER(i4), INTENT(IN)                     :: n_param_specs    ! [in]
    TYPE(KeyWord_ParsingRule_Type), INTENT(OUT)  :: rule             ! [out]
    TYPE(ErrorStatusType), INTENT(OUT)          :: status            ! [out]

    rule%keyword_name   = TRIM(ADJUSTL(keyword_name))
    rule%parent_keyword = TRIM(ADJUSTL(parent_keyword))
    rule%has_data_block = has_data_block
    rule%n_param_specs  = n_param_specs

    ALLOCATE(rule%param_specs(n_param_specs))
    ALLOCATE(rule%allowed_children(0))

    status%status_code = 0
  END SUBROUTINE MD_KW_RuleFactory

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_TreeInit
  ! PHASE:      P0
  ! PURPOSE:    Initialize keyword AST root node
  !-----------------------------------------------------------------
  SUBROUTINE MD_KW_TreeInit(root_node, status)
    TYPE(KeyWord_Node_Type), INTENT(OUT) :: root_node           ! [out]
    TYPE(ErrorStatusType), INTENT(OUT)   :: status              ! [out]

    CALL MD_KW_NodeFactory("ROOT", -1_i4, 0_i4, root_node, status)
    root_node%node_id = 0_i4
  END SUBROUTINE MD_KW_TreeInit

  !-----------------------------------------------------------------
  ! SUBROUTINE: MD_KW_TreePrint
  ! PHASE:      P0
  ! PURPOSE:    Print keyword AST (debug utility)
  !-----------------------------------------------------------------
  RECURSIVE SUBROUTINE MD_KW_TreePrint(node, indent_level, unit)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node                 ! [in]
    INTEGER(i4), INTENT(IN)             :: indent_level         ! [in]
    INTEGER(i4), INTENT(IN)             :: unit                 ! [in]

    CHARACTER(LEN=256) :: indent_str
    INTEGER(i4)        :: i, indent_spaces

    indent_spaces = indent_level * 2
    indent_str = ""
    DO i = 1, indent_spaces
      indent_str = TRIM(indent_str) // " "
    END DO

    WRITE(unit, '(A,A,A,I5,A,I2)') TRIM(indent_str), "* ", &
      TRIM(node%keyword_name), " [ID:", node%node_id, &
      " Children:", node%n_children, "]"

    IF (node%n_children > 0) THEN
      DO i = 1, node%n_children
        CALL MD_KW_TreePrint(node%child_keywords(i), indent_level + 1, unit)
      END DO
    END IF
  END SUBROUTINE MD_KW_TreePrint

END MODULE MD_KeyWordParser_Def
