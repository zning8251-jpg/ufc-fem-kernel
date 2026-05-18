!===================================================================
! MODULE : MD_KeyWord_ParserRecursive
! LAYER  : L3_MD
! DOMAIN : KeyWord (KW)
! ROLE   : Impl / ParseRecursive
! BRIEF  : Recursive keyword parser -- line scanning, keyword
!          identification, parameter parsing, data-block extraction,
!          AST construction and recursive tree validation.
!===================================================================

MODULE MD_KeyWord_ParserRecursive
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE MD_KeyWordParser_Def
  IMPLICIT NONE
  
  PRIVATE
  PUBLIC :: MD_Parse_KeyWord_Block, MD_Validate_KeyWord_Tree, &
            MD_Map_KeyWord_Tree_To_Model, MD_Parse_Line
  
  ! Global rule table (initialised once at application startup)
  INTEGER(i4), PARAMETER :: MAX_RULES = 50_i4
  TYPE(KeyWord_ParsingRule_Type), ALLOCATABLE, SAVE :: g_KeyWord_Rules(:)
  INTEGER(i4), SAVE :: g_n_Rules = 0_i4
  LOGICAL, SAVE :: g_rules_initialized = .FALSE.
  
CONTAINS
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Initialize_KeyWord_Rules
  ! PHASE      : P0
  ! PURPOSE    : Initialise the global keyword rule table (call once).
  ! ------------------------------------------------------------------
  
  SUBROUTINE MD_Initialize_KeyWord_Rules(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    IF (.NOT. ALLOCATED(g_KeyWord_Rules)) THEN
      ALLOCATE(g_KeyWord_Rules(MAX_RULES))
    END IF
    
    ! Register rule #1: *PART (top-level)
    CALL MD_KW_RuleFactory("*PART", "ROOT", .FALSE., 1_i4, &
                                g_KeyWord_Rules(1), status)
    g_KeyWord_Rules(1)%cfg%description = "Part definition"
    g_KeyWord_Rules(1)%param_specs(1)%param_name = "NAME"
    g_KeyWord_Rules(1)%param_specs(1)%param_type = "STRING"
    g_KeyWord_Rules(1)%param_specs(1)%is_required = .TRUE.
    
    ! Register rule #2: *NODE (under *PART)
    CALL MD_KW_RuleFactory("*NODE", "*PART", .TRUE., 0_i4, &
                                g_KeyWord_Rules(2), status)
    g_KeyWord_Rules(2)%cfg%description = "Node definitions"
    g_KeyWord_Rules(2)%has_data_block = .TRUE.
    g_KeyWord_Rules(2)%data_block_format = "INT REAL REAL REAL"
    g_KeyWord_Rules(2)%expected_fields = -1_i4  ! 可变数目行
    
    ! Register rule #3: *ELEMENT (under *PART)
    CALL MD_KW_RuleFactory("*ELEMENT", "*PART", .TRUE., 2_i4, &
                                g_KeyWord_Rules(3), status)
    g_KeyWord_Rules(3)%param_specs(1)%param_name = "TYPE"
    g_KeyWord_Rules(3)%param_specs(1)%param_type = "STRING"
    g_KeyWord_Rules(3)%param_specs(2)%param_name = "ELSET"
    g_KeyWord_Rules(3)%param_specs(2)%param_type = "STRING"
    
    ! Register rule #4: *MATERIAL (top-level)
    CALL MD_KW_RuleFactory("*MATERIAL", "ROOT", .FALSE., 1_i4, &
                                g_KeyWord_Rules(4), status)
    g_KeyWord_Rules(4)%param_specs(1)%param_name = "NAME"
    g_KeyWord_Rules(4)%param_specs(1)%param_type = "STRING"
    
    ! Register rule #5: *ELASTIC (under *MATERIAL)
    CALL MD_KW_RuleFactory("*ELASTIC", "*MATERIAL", .TRUE., 0_i4, &
                                g_KeyWord_Rules(5), status)
    g_KeyWord_Rules(5)%data_block_format = "REAL REAL"  ! E, nu
    
    ! Register rule #6: *BOUNDARY (top-level)
    CALL MD_KW_RuleFactory("*BOUNDARY", "ROOT", .TRUE., 0_i4, &
                                g_KeyWord_Rules(6), status)
    g_KeyWord_Rules(6)%cfg%description = "Boundary conditions"
    
    ! Register rule #7: *LOAD (top-level)
    CALL MD_KW_RuleFactory("*LOAD", "ROOT", .TRUE., 0_i4, &
                                g_KeyWord_Rules(7), status)
    g_KeyWord_Rules(7)%cfg%description = "Loads"
    
    ! Register rule #8: *STEP (top-level)
    CALL MD_KW_RuleFactory("*STEP", "ROOT", .FALSE., 1_i4, &
                                g_KeyWord_Rules(8), status)
    g_KeyWord_Rules(8)%param_specs(1)%param_name = "NAME"
    g_KeyWord_Rules(8)%param_specs(1)%param_type = "STRING"
    
    ! Register rule #9: *STATIC (under *STEP)
    CALL MD_KW_RuleFactory("*STATIC", "*STEP", .TRUE., 0_i4, &
                                g_KeyWord_Rules(9), status)
    
    ! Register rule #10: *DYNAMIC (under *STEP)
    CALL MD_KW_RuleFactory("*DYNAMIC", "*STEP", .TRUE., 0_i4, &
                                g_KeyWord_Rules(10), status)
    
    g_n_Rules = 10_i4
    g_rules_initialized = .TRUE.
    status%status_code = 0_i4
    
  END SUBROUTINE MD_Initialize_KeyWord_Rules
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Parse_Line
  ! PHASE      : P1
  ! PURPOSE    : Parse a single line into keyword + params or data.
  ! ------------------------------------------------------------------
  
  SUBROUTINE MD_Parse_Line(line, is_keyword, keyword, params, status)
    CHARACTER(len=*), INTENT(IN) :: line
    LOGICAL, INTENT(OUT) :: is_keyword
    CHARACTER(len=32), INTENT(OUT) :: keyword
    CHARACTER(len=256), ALLOCATABLE, INTENT(OUT) :: params(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=512) :: trimmed_line
    INTEGER(i4) :: i, comma_pos, space_pos, n_params
    CHARACTER(len=256) :: param_str, keyword_part, param_part
    
    trimmed_line = ADJUSTL(line)
    status%status_code = 0_i4
    
    IF (LEN_TRIM(trimmed_line) > 0 .AND. trimmed_line(1:1) == '*') THEN
      is_keyword = .TRUE.
      
      ! [Step 1] Separate keyword and parameters from keyword line
      comma_pos = INDEX(trimmed_line, ',')
      space_pos = INDEX(trimmed_line, ' ')
      
      IF (comma_pos == 0 .AND. space_pos == 0) THEN
        ! Keyword only, no parameters
        keyword = TRIM(ADJUSTL(trimmed_line))
        ALLOCATE(params(0))
        n_params = 0_i4
      ELSE IF (comma_pos > 0) THEN
        ! Keyword followed by comma-separated parameters
        keyword = TRIM(ADJUSTL(trimmed_line(1:comma_pos-1)))
        param_part = TRIM(ADJUSTL(trimmed_line(comma_pos+1:)))
        CALL MD_Parse_Parameters(param_part, params, n_params, status)
      ELSE IF (space_pos > 0) THEN
        ! Keyword followed by space-separated parameters (rare)
        keyword = TRIM(ADJUSTL(trimmed_line(1:space_pos-1)))
        param_part = TRIM(ADJUSTL(trimmed_line(space_pos+1:)))
        CALL MD_Parse_Parameters(param_part, params, n_params, status)
      ELSE
        keyword = TRIM(ADJUSTL(trimmed_line))
        ALLOCATE(params(0))
        n_params = 0_i4
      END IF
    ELSE
      ! Non-keyword line (usually a data line)
      is_keyword = .FALSE.
      keyword = ""
      CALL MD_Parse_Parameters(trimmed_line, params, n_params, status)
    END IF
    
  END SUBROUTINE MD_Parse_Line
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Parse_Parameters
  ! PHASE      : P1
  ! PURPOSE    : Split a comma-separated line into parameter tokens.
  ! ------------------------------------------------------------------
  
  SUBROUTINE MD_Parse_Parameters(line, params, n_params, status)
    CHARACTER(len=*), INTENT(IN) :: line
    CHARACTER(len=256), ALLOCATABLE, INTENT(OUT) :: params(:)
    INTEGER(i4), INTENT(OUT) :: n_params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=512) :: work_line
    INTEGER(i4) :: i, comma_pos, max_params
    CHARACTER(len=256), ALLOCATABLE :: temp_params(:)
    
    work_line = TRIM(line)
    max_params = 20
    ALLOCATE(temp_params(max_params))
    
    n_params = 0_i4
    
    DO WHILE (LEN_TRIM(work_line) > 0 .AND. n_params < max_params)
      comma_pos = INDEX(work_line, ',')
      
      IF (comma_pos == 0) THEN
        n_params = n_params + 1_i4
        temp_params(n_params) = TRIM(ADJUSTL(work_line))
        work_line = ""
      ELSE
        n_params = n_params + 1_i4
        temp_params(n_params) = TRIM(ADJUSTL(work_line(1:comma_pos-1)))
        work_line = TRIM(ADJUSTL(work_line(comma_pos+1:)))
      END IF
    END DO
    
    IF (n_params > 0) THEN
      ALLOCATE(params(n_params))
      params(1:n_params) = temp_params(1:n_params)
    ELSE
      ALLOCATE(params(0))
    END IF
    
    DEALLOCATE(temp_params)
    status%status_code = 0_i4
    
  END SUBROUTINE MD_Parse_Parameters
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Parse_KeyWord_Block  (RECURSIVE)
  ! PHASE      : P1
  ! PURPOSE    : Recursively parse nested keyword blocks from file.
  ! ------------------------------------------------------------------
  
  RECURSIVE SUBROUTINE MD_Parse_KeyWord_Block(inp_unit, parent_keyword, &
                                              parent_nesting_level, &
                                              nodes, n_nodes, status)
    INTEGER(i4), INTENT(IN) :: inp_unit, parent_nesting_level
    CHARACTER(len=*), INTENT(IN) :: parent_keyword
    TYPE(KeyWord_Node_Type), ALLOCATABLE, INTENT(OUT) :: nodes(:)
    INTEGER(i4), INTENT(OUT) :: n_nodes
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=512) :: line, current_keyword
    LOGICAL :: is_keyword, eof
    CHARACTER(len=32) :: keyword
    CHARACTER(len=256), ALLOCATABLE :: params(:), data_block_line(:)
    INTEGER(i4) :: io_stat, n_params, max_nodes, i, j
    INTEGER(i4) :: node_id_counter, current_node_id, n_data_rows
    INTEGER(i4) :: rule_idx, n_children
    TYPE(KeyWord_Node_Type), ALLOCATABLE :: temp_nodes(:), child_nodes(:)
    REAL(wp), ALLOCATABLE :: temp_data(:,:)
    
    max_nodes = 100_i4
    ALLOCATE(temp_nodes(max_nodes))
    ALLOCATE(data_block_line(1000))
    n_nodes = 0_i4
    node_id_counter = 1_i4
    eof = .FALSE.
    
    DO WHILE (.NOT. eof)
      
      READ(inp_unit, '(A)', IOSTAT=io_stat) line
      
      IF (io_stat /= 0) THEN
        eof = .TRUE.
        EXIT
      END IF
      
      IF (LEN_TRIM(line) > 1 .AND. line(1:2) == '**') CYCLE
      IF (LEN_TRIM(line) == 0) CYCLE
      
      CALL MD_Parse_Line(line, is_keyword, keyword, params, status)
      IF (status%status_code /= 0_i4) EXIT
      
      IF (is_keyword) THEN
        
        current_keyword = TRIM(keyword)
        
        IF (parent_keyword /= "ROOT") THEN
          IF (.NOT. is_child_keyword(current_keyword, parent_keyword)) THEN
            BACKSPACE(inp_unit)
            EXIT
          END IF
        END IF
        
        IF (n_nodes < max_nodes) THEN
          n_nodes = n_nodes + 1_i4
          current_node_id = node_id_counter
          node_id_counter = node_id_counter + 1_i4
          
          CALL MD_KW_NodeFactory(current_keyword, -1_i4, &
                                      parent_nesting_level + 1_i4, &
                                      temp_nodes(n_nodes), status)
          temp_nodes(n_nodes)%node_id = current_node_id
          
          DO
            READ(inp_unit, '(A)', IOSTAT=io_stat) line
            IF (io_stat /= 0) THEN
              eof = .TRUE.
              EXIT
            END IF
            
            IF (LEN_TRIM(line) == 0) CYCLE
            IF (line(1:1) == '*') THEN
              BACKSPACE(inp_unit)
              EXIT
            END IF
            
            IF (line(1:2) == '**') CYCLE
            
            CALL MD_Parse_Parameters(line, params, n_params, status)
            IF (n_params > 0) THEN
              IF (.NOT. ASSOCIATED(temp_nodes(n_nodes)%params)) THEN
                ALLOCATE(temp_nodes(n_nodes)%params(n_params))
                ALLOCATE(temp_nodes(n_nodes)%param_strings(n_params))
                temp_nodes(n_nodes)%n_params = n_params
                DO j = 1, n_params
                  temp_nodes(n_nodes)%params(j) = params(j)
                  temp_nodes(n_nodes)%param_strings(j) = params(j)
                END DO
              END IF
            END IF
          END DO
          
          CALL find_rule_by_keyword(current_keyword, rule_idx, status)
          IF (rule_idx > 0 .AND. rule_idx <= g_n_Rules) THEN
            IF (g_KeyWord_Rules(rule_idx)%has_data_block) THEN
              n_data_rows = 0_i4
              
              DO
                IF (eof) EXIT
                READ(inp_unit, '(A)', IOSTAT=io_stat) line
                IF (io_stat /= 0) THEN
                  eof = .TRUE.
                  EXIT
                END IF
                
                IF (LEN_TRIM(line) == 0) CYCLE
                IF (line(1:1) == '*') THEN
                  BACKSPACE(inp_unit)
                  EXIT
                END IF
                
                IF (line(1:2) == '**') CYCLE
                
                n_data_rows = n_data_rows + 1_i4
                IF (n_data_rows <= 1000) THEN
                  data_block_line(n_data_rows) = TRIM(line)
                END IF
              END DO
              
              IF (n_data_rows > 0) THEN
                ALLOCATE(temp_data(n_data_rows, 4))
                CALL parse_data_block_to_matrix(data_block_line, n_data_rows, &
                                               temp_data, status)
                ALLOCATE(temp_nodes(n_nodes)%data_block(n_data_rows, 4))
                temp_nodes(n_nodes)%data_block = temp_data
                temp_nodes(n_nodes)%n_rows = n_data_rows
                temp_nodes(n_nodes)%n_cols = 4_i4
                DEALLOCATE(temp_data)
              END IF
            END IF
          END IF
          
          CALL MD_Parse_KeyWord_Block(inp_unit, current_keyword, &
                                      parent_nesting_level + 1_i4, &
                                      child_nodes, n_children, status)
          
          IF (n_children > 0) THEN
            ALLOCATE(temp_nodes(n_nodes)%child_keywords(n_children))
            temp_nodes(n_nodes)%child_keywords(1:n_children) = &
              child_nodes(1:n_children)
            temp_nodes(n_nodes)%n_children = n_children
            DEALLOCATE(child_nodes)
          END IF
          
          temp_nodes(n_nodes)%is_complete = .TRUE.
        END IF
      END IF
      
    END DO
    
    IF (n_nodes > 0) THEN
      ALLOCATE(nodes(n_nodes))
      nodes(1:n_nodes) = temp_nodes(1:n_nodes)
    ELSE
      ALLOCATE(nodes(0))
    END IF
    
    DEALLOCATE(temp_nodes)
    DEALLOCATE(data_block_line)
    status%status_code = 0_i4
    
  END SUBROUTINE MD_Parse_KeyWord_Block
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Validate_KeyWord_Tree
  ! PHASE      : P1
  ! PURPOSE    : Validate complete keyword tree (entry point).
  ! ------------------------------------------------------------------
  
  SUBROUTINE MD_Validate_KeyWord_Tree(root_node, status)
    TYPE(KeyWord_Node_Type), INTENT(INOUT) :: root_node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL validate_node_recursive(root_node, "ROOT", status)
    
  END SUBROUTINE MD_Validate_KeyWord_Tree
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : validate_node_recursive  (RECURSIVE)
  ! PURPOSE    : Validate a single node and recurse into children.
  ! ------------------------------------------------------------------
  
  RECURSIVE SUBROUTINE validate_node_recursive(node, parent_keyword, status)
    TYPE(KeyWord_Node_Type), INTENT(INOUT) :: node
    CHARACTER(len=*), INTENT(IN) :: parent_keyword
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, rule_idx
    LOGICAL :: param_found
    INTEGER(i4) :: j
    
    ! [Step 1] Look up rule
    CALL find_rule_by_keyword(node%keyword_name, rule_idx, status)
    
    ! [Step 2] Validate parent-child relationship
    IF (parent_keyword /= "ROOT") THEN
      IF (.NOT. is_child_keyword(node%keyword_name, parent_keyword)) THEN
        status%status_code = 1_i4
        RETURN
      END IF
    END IF
    
    ! [Step 3] Validate required parameters
    IF (rule_idx > 0 .AND. rule_idx <= g_n_Rules) THEN
      DO i = 1, g_KeyWord_Rules(rule_idx)%n_param_specs
        IF (g_KeyWord_Rules(rule_idx)%param_specs(i)%is_required) THEN
          param_found = .FALSE.
          
          IF (ASSOCIATED(node%params)) THEN
            DO j = 1, node%n_params
              IF (INDEX(node%params(j), &
                        TRIM(g_KeyWord_Rules(rule_idx)%param_specs(i)%param_name)) > 0) THEN
                param_found = .TRUE.
                EXIT
              END IF
            END DO
          END IF
          
          IF (.NOT. param_found) THEN
            status%status_code = 1_i4
          END IF
        END IF
      END DO
    END IF
    
    ! [Step 4] Validate parameter format
    IF (ASSOCIATED(node%params)) THEN
      DO i = 1, node%n_params
        IF (INDEX(node%params(i), '=') == 0) THEN
          status%status_code = 1_i4
        END IF
      END DO
    END IF
    
    ! [Step 5] Validate data block
    IF (rule_idx > 0 .AND. rule_idx <= g_n_Rules) THEN
      IF (g_KeyWord_Rules(rule_idx)%has_data_block) THEN
        IF (.NOT. ASSOCIATED(node%data_block)) THEN
          status%status_code = 1_i4
        ELSE
          IF (g_KeyWord_Rules(rule_idx)%expected_fields > 0) THEN
            IF (node%n_cols /= g_KeyWord_Rules(rule_idx)%expected_fields) THEN
              status%status_code = 1_i4
            END IF
          END IF
        END IF
      END IF
    END IF
    
    ! [Step 6] Recursively validate child nodes
    IF (ASSOCIATED(node%child_keywords)) THEN
      DO i = 1, node%n_children
        CALL validate_node_recursive(node%child_keywords(i), &
                                      node%keyword_name, status)
        IF (status%status_code /= 0_i4 .AND. status%status_code /= 1_i4) THEN
          RETURN
        END IF
      END DO
    END IF
    
    node%is_validated = .TRUE.
    status%status_code = 0_i4
    
  END SUBROUTINE validate_node_recursive
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : MD_Map_KeyWord_Tree_To_Model
  ! PHASE      : P1
  ! PURPOSE    : Map validated keyword tree to model descriptor.
  ! ------------------------------------------------------------------
  
  SUBROUTINE MD_Map_KeyWord_Tree_To_Model(root_node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: root_node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    ! [Step 1] Initialise model_desc
    ! TODO: CALL L3_MD_Model_Init(model_desc, status)
    
    ! [Step 2] Traverse children of root node
    IF (ASSOCIATED(root_node%child_keywords)) THEN
      DO i = 1, root_node%n_children
        CALL map_keyword_node(root_node%child_keywords(i), status)
        IF (status%status_code /= 0_i4) RETURN
      END DO
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE MD_Map_KeyWord_Tree_To_Model
  
  ! ------------------------------------------------------------------
  ! SUBROUTINE : map_keyword_node  (RECURSIVE)
  ! PURPOSE    : Dispatch keyword to specific mapper by name.
  ! ------------------------------------------------------------------
  
  RECURSIVE SUBROUTINE map_keyword_node(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i
    
    ! [Step 1] Dispatch by keyword type
    SELECT CASE(TRIM(node%keyword_name))
      
      CASE("*PART")
        CALL map_part_keyword(node, status)
      
      CASE("*NODE")
        CALL map_node_keyword(node, status)
      
      CASE("*ELEMENT")
        CALL map_element_keyword(node, status)
      
      CASE("*MATERIAL")
        CALL map_material_keyword(node, status)
      
      CASE("*ELASTIC")
        CALL map_elastic_keyword(node, status)
      
      CASE("*STEP")
        CALL map_step_keyword(node, status)
      
      CASE("*STATIC")
        CALL map_static_keyword(node, status)
      
      CASE("*BOUNDARY")
        CALL map_boundary_keyword(node, status)
      
      CASE("*LOAD")
        CALL map_load_keyword(node, status)
      
      CASE("*SECTION")
        CALL map_section_keyword(node, status)
      
      ! Week 2 Day 1: 14 additional keyword handlers
      CASE("*ASSEMBLY")
        CALL map_assembly_keyword(node, status)
      
      CASE("*INSTANCE")
        CALL map_instance_keyword(node, status)
      
      CASE("*CONTACT PAIR")
        CALL map_contact_pair_keyword(node, status)
      
      CASE("*SURFACE INTERACTION")
        CALL map_surface_interaction_keyword(node, status)
      
      CASE("*FRICTION")
        CALL map_friction_keyword(node, status)
      
      CASE("*AMPLITUDE")
        CALL map_amplitude_keyword(node, status)
      
      CASE("*ORIENTATION")
        CALL map_orientation_keyword(node, status)
      
      CASE("*PROPERTY")
        CALL map_property_keyword(node, status)
      
      CASE("*RESTART")
        CALL map_restart_keyword(node, status)
      
      CASE("*OUTPUT")
        CALL map_output_keyword(node, status)
      
      CASE("*FIELDOUTPUT")
        CALL map_fieldoutput_keyword(node, status)
      
      CASE("*NODEOUTPUT")
        CALL map_nodeoutput_keyword(node, status)
      
      CASE("*ELEMENTOUTPUT")
        CALL map_elementoutput_keyword(node, status)
      
      CASE("*PRINT")
        CALL map_print_keyword(node, status)
      
      CASE DEFAULT
        ! Ignore unknown keywords
        status%status_code = 0_i4
    END SELECT
    
    IF (status%status_code /= 0_i4) RETURN
    
    ! [Step 2] Recurse into child nodes
    IF (ASSOCIATED(node%child_keywords)) THEN
      DO i = 1, node%n_children
        CALL map_keyword_node(node%child_keywords(i), status)
        IF (status%status_code /= 0_i4) RETURN
      END DO
    END IF
    
  END SUBROUTINE map_keyword_node
  
  ! ------------------------------------------------------------------
  ! Keyword-specific mapper subroutines
  ! ------------------------------------------------------------------
  
  SUBROUTINE map_part_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=256) :: part_name
    INTEGER(i4) :: i
    
    ! Extract PART name
    IF (ASSOCIATED(node%params) .AND. node%n_params > 0) THEN
      ! Find NAME= parameter
      DO i = 1, node%n_params
        IF (INDEX(node%params(i), 'NAME=') > 0) THEN
          part_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
          ! TODO: store part_name in model_desc
        END IF
      END DO
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_part_keyword
  
  SUBROUTINE map_node_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, j, n_nodes
    REAL(wp) :: node_id, x, y, z
    
    ! Extract node data from data_block
    IF (ASSOCIATED(node%data_block)) THEN
      n_nodes = node%n_rows
      
      DO i = 1, n_nodes
        ! Data format: [node_id, x, y, z]
        node_id = node%data_block(i, 1)
        x = node%data_block(i, 2)
        y = node%data_block(i, 3)
        z = node%data_block(i, 4)
        
        ! TODO: store node info into model_desc%mesh
      END DO
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_node_keyword
  
  SUBROUTINE map_element_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=32) :: elem_type
    CHARACTER(len=256) :: elem_set
    INTEGER(i4) :: i
    
    ! Extract element type (TYPE=C3D8) from params
    IF (ASSOCIATED(node%params)) THEN
      DO i = 1, node%n_params
        IF (INDEX(node%params(i), 'TYPE=') > 0) THEN
          elem_type = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
        END IF
        IF (INDEX(node%params(i), 'ELSET=') > 0) THEN
          elem_set = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
        END IF
      END DO
    END IF
    
    ! Extract element definitions from data_block
    IF (ASSOCIATED(node%data_block)) THEN
      ! Data format: [elem_id, node1, node2, ...] (varies by element type)
      ! TODO: parse data_block according to elem_type
      ! TODO: store element info into model_desc
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_element_keyword
  
  SUBROUTINE map_material_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=256) :: mat_name
    INTEGER(i4) :: i
    
    ! Extract material name
    IF (ASSOCIATED(node%params)) THEN
      DO i = 1, node%n_params
        IF (INDEX(node%params(i), 'NAME=') > 0) THEN
          mat_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
          ! TODO: store material name in model_desc
        END IF
      END DO
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_material_keyword
  
  SUBROUTINE map_elastic_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: E, nu
    
    ! Extract elastic parameters (E, nu) from data_block
    IF (ASSOCIATED(node%data_block) .AND. node%n_rows > 0) THEN
      E = node%data_block(1, 1)
      nu = node%data_block(1, 2)
      ! TODO: store E, nu into model_desc
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_elastic_keyword
  
  SUBROUTINE map_step_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=256) :: step_name
    INTEGER(i4) :: i
    
    ! Extract step name
    IF (ASSOCIATED(node%params)) THEN
      DO i = 1, node%n_params
        IF (INDEX(node%params(i), 'NAME=') > 0) THEN
          step_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
          ! TODO: store step name in model_desc
        END IF
      END DO
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_step_keyword
  
  SUBROUTINE map_static_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Extract static analysis parameters
    ! TODO: extract time step etc. from data_block
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_static_keyword
  
  SUBROUTINE map_boundary_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Extract boundary conditions from data_block
    IF (ASSOCIATED(node%data_block)) THEN
      ! Data format: [node_id, dof, value]
      ! TODO: store BCs into model_desc
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_boundary_keyword
  
  SUBROUTINE map_load_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Extract load data from data_block
    IF (ASSOCIATED(node%data_block)) THEN
      ! Data format: [node_id, dof, value]
      ! TODO: store load info into model_desc
    END IF
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_load_keyword
  
  SUBROUTINE map_section_keyword(node, status)
    TYPE(KeyWord_Node_Type), INTENT(IN) :: node
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Extract section definition
    ! TODO: extract section type, properties from params
    
    status%status_code = 0_i4
    
  END SUBROUTINE map_section_keyword

! ------------------------------------------------------------------
! Helper functions
! ------------------------------------------------------------------

FUNCTION is_child_keyword(keyword, parent_keyword) RESULT(is_child)
  CHARACTER(len=*), INTENT(IN) :: keyword, parent_keyword
  LOGICAL :: is_child
  
  is_child = .FALSE.
  
  IF (parent_keyword == "*PART") THEN
    is_child = (keyword == "*NODE" .OR. keyword == "*ELEMENT" .OR. &
                keyword == "*SURFACE" .OR. keyword == "*ELSET" .OR. &
                keyword == "*NSET")
  ELSE IF (parent_keyword == "*MATERIAL") THEN
    is_child = (keyword == "*ELASTIC" .OR. keyword == "*PLASTIC" .OR. &
                keyword == "*HYPERELASTIC" .OR. keyword == "*VISCOELASTIC")
  ELSE IF (parent_keyword == "*STEP") THEN
    is_child = (keyword == "*STATIC" .OR. keyword == "*DYNAMIC" .OR. &
                keyword == "*FREQUENCY" .OR. keyword == "*BUCKLING" .OR. &
                keyword == "*HEAT TRANSFER")
  ELSE IF (parent_keyword == "ROOT") THEN
    is_child = (keyword == "*PART" .OR. keyword == "*MATERIAL" .OR. &
                keyword == "*ASSEMBLY" .OR. keyword == "*STEP" .OR. &
                keyword == "*BOUNDARY" .OR. keyword == "*LOAD" .OR. &
                keyword == "*INTERACTION" .OR. keyword == "*OUTPUT" .OR. &
                keyword == "*SECTION" .OR. keyword == "*CONSTRAINT" .OR. &
                keyword == "*SURFACE")
  END IF
  
END FUNCTION is_child_keyword

FUNCTION keyword_has_data_block(keyword) RESULT(has_data)
  CHARACTER(len=*), INTENT(IN) :: keyword
  LOGICAL :: has_data
  
  SELECT CASE(TRIM(keyword))
    CASE("*NODE", "*ELEMENT", "*LOAD", "*BOUNDARY", "*ELASTIC", &
         "*PLASTIC", "*STATIC", "*DYNAMIC", "*FREQUENCY", "*OUTPUT", &
         "*SURFACE", "*NSET", "*ELSET")
      has_data = .TRUE.
    CASE DEFAULT
      has_data = .FALSE.
  END SELECT
  
END FUNCTION keyword_has_data_block

SUBROUTINE parse_data_block_to_matrix(data_lines, n_rows, matrix, status)
  CHARACTER(len=*), INTENT(IN) :: data_lines(:)
  INTEGER(i4), INTENT(IN) :: n_rows
  REAL(wp), ALLOCATABLE, INTENT(INOUT) :: matrix(:,:)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: i, j, n_cols, io_stat
  CHARACTER(len=512) :: line
  
  n_cols = SIZE(matrix, 2)
  
  DO i = 1, n_rows
    line = TRIM(data_lines(i))
    READ(line, *, IOSTAT=io_stat) (matrix(i, j), j=1, n_cols)
    IF (io_stat /= 0) THEN
      matrix(i, :) = 0.0_wp
    END IF
  END DO
  
  status%status_code = 0_i4
  
END SUBROUTINE parse_data_block_to_matrix

SUBROUTINE find_rule_by_keyword(keyword, rule_idx, status)
  CHARACTER(len=*), INTENT(IN) :: keyword
  INTEGER(i4), INTENT(OUT) :: rule_idx
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: i
  
  rule_idx = -1_i4
  
  DO i = 1, g_n_Rules
    IF (TRIM(g_KeyWord_Rules(i)%keyword_name) == TRIM(keyword)) THEN
      rule_idx = i
      status%status_code = 0_i4
      RETURN
    END IF
  END DO
  
  status%status_code = 0_i4
  
END SUBROUTINE find_rule_by_keyword

! ------------------------------------------------------------------
! 14 additional keyword mapper subroutines
! ------------------------------------------------------------------

SUBROUTINE map_assembly_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  CHARACTER(len=256) :: assembly_name
  INTEGER(i4) :: i
  
  ! Extract assembly name
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'NAME=') > 0) THEN
        assembly_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
        ! TODO: store assembly name in model_desc
      END IF
    END DO
  END IF
  
  status%status_code = 0_i4
  
END SUBROUTINE map_assembly_keyword

SUBROUTINE map_instance_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  CHARACTER(len=256) :: part_name, instance_name
  INTEGER(i4) :: i
  
  ! Extract instance info (PART=, NAME=)
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'PART=') > 0) THEN
        part_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
      IF (INDEX(node%params(i), 'NAME=') > 0) THEN
        instance_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! TODO: store instance info (part_name, instance_name) in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_instance_keyword

SUBROUTINE map_contact_pair_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: i
  CHARACTER(len=256) :: surf1, surf2, interaction_type
  
  ! Extract contact pair info from params
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'SURFACE1=') > 0) THEN
        surf1 = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
      IF (INDEX(node%params(i), 'SURFACE2=') > 0) THEN
        surf2 = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
      IF (INDEX(node%params(i), 'TYPE=') > 0) THEN
        interaction_type = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! TODO: store contact pair info (surf1, surf2, interaction_type) in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_contact_pair_keyword

SUBROUTINE map_surface_interaction_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  CHARACTER(len=256) :: interaction_name
  INTEGER(i4) :: i
  
  ! Extract surface interaction name
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'NAME=') > 0) THEN
        interaction_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! TODO: store surface interaction info in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_surface_interaction_keyword

SUBROUTINE map_friction_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: mu_s, mu_k, friction_coeff
  
  ! Extract friction coefficients (mu_s, mu_k) from data_block
  IF (ASSOCIATED(node%data_block) .AND. node%n_rows > 0) THEN
    mu_s = node%data_block(1, 1)
    IF (node%n_cols > 1) mu_k = node%data_block(1, 2)
    ! TODO: store friction params in model_desc
  END IF
  
  status%status_code = 0_i4
  
END SUBROUTINE map_friction_keyword

SUBROUTINE map_amplitude_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  CHARACTER(len=256) :: amplitude_name
  INTEGER(i4) :: i
  
  ! Extract amplitude name
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'NAME=') > 0) THEN
        amplitude_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! Read time-amplitude pairs from data_block
  IF (ASSOCIATED(node%data_block)) THEN
    ! TODO: store amplitude data (time, amplitude) in model_desc
  END IF
  
  status%status_code = 0_i4
  
END SUBROUTINE map_amplitude_keyword

SUBROUTINE map_orientation_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  CHARACTER(len=256) :: orientation_name
  REAL(wp) :: euler1, euler2, euler3
  INTEGER(i4) :: i
  
  ! Extract orientation name
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'NAME=') > 0) THEN
        orientation_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! Read Euler angles (phi1, Phi, phi2) from data_block
  IF (ASSOCIATED(node%data_block) .AND. node%n_rows > 0) THEN
    euler1 = node%data_block(1, 1)
    euler2 = node%data_block(1, 2)
    euler3 = node%data_block(1, 3)
    ! TODO: store orientation info in model_desc
  END IF
  
  status%status_code = 0_i4
  
END SUBROUTINE map_orientation_keyword

SUBROUTINE map_property_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  CHARACTER(len=256) :: property_name, property_type
  INTEGER(i4) :: i
  
  ! Extract property name and type
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'NAME=') > 0) THEN
        property_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
      IF (INDEX(node%params(i), 'TYPE=') > 0) THEN
        property_type = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! TODO: store property definition in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_property_keyword

SUBROUTINE map_restart_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  CHARACTER(len=256) :: restart_file
  INTEGER(i4) :: i, restart_step
  
  ! Extract restart params (FILE=, STEP=)
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'FILE=') > 0) THEN
        restart_file = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
      IF (INDEX(node%params(i), 'STEP=') > 0) THEN
        ! Read restart step number
        ! TODO: parse STEP= value
      END IF
    END DO
  END IF
  
  ! TODO: store restart info in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_restart_keyword

SUBROUTINE map_output_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: i, frequency
  CHARACTER(len=256) :: output_type
  
  ! Extract output params (FREQUENCY=, TYPE=)
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'FREQUENCY=') > 0) THEN
        ! TODO: parse FREQUENCY value
      END IF
      IF (INDEX(node%params(i), 'TYPE=') > 0) THEN
        output_type = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! TODO: store output definition in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_output_keyword

SUBROUTINE map_fieldoutput_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  CHARACTER(len=256) :: variables, variable_type
  INTEGER(i4) :: i, frequency
  
  ! Extract field output params (VARIABLES=, FREQUENCY=)
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'VARIABLES=') > 0) THEN
        variables = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
      IF (INDEX(node%params(i), 'FREQUENCY=') > 0) THEN
        ! TODO: parse frequency value
      END IF
    END DO
  END IF
  
  ! TODO: store field output variable list in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_fieldoutput_keyword

SUBROUTINE map_nodeoutput_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: i
  CHARACTER(len=256) :: nodeset_name
  
  ! Extract node output set name
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'NSET=') > 0) THEN
        nodeset_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! TODO: store node output set in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_nodeoutput_keyword

SUBROUTINE map_elementoutput_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: i
  CHARACTER(len=256) :: elementset_name
  
  ! Extract element output set name
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'ELSET=') > 0) THEN
        elementset_name = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! TODO: store element output set in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_elementoutput_keyword

SUBROUTINE map_print_keyword(node, status)
  TYPE(KeyWord_Node_Type), INTENT(IN) :: node
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: i, frequency
  CHARACTER(len=256) :: print_type
  
  ! Extract print params (FREQUENCY=, TYPE=)
  IF (ASSOCIATED(node%params)) THEN
    DO i = 1, node%n_params
      IF (INDEX(node%params(i), 'FREQUENCY=') > 0) THEN
        ! TODO: parse frequency value
      END IF
      IF (INDEX(node%params(i), 'TYPE=') > 0) THEN
        print_type = ADJUSTL(node%params(i)(INDEX(node%params(i), '=')+1:))
      END IF
    END DO
  END IF
  
  ! TODO: store print definition in model_desc
  
  status%status_code = 0_i4
  
END SUBROUTINE map_print_keyword

END MODULE MD_KeyWord_ParserRecursive