! ================================================================================
! Program: test_keyword_framework
! ================================================================================
! Purpose:
!   Unit test driver for Phase 4 KeyWord Enhancement Project
!   Testing public interfaces and framework functionality
!
! Author: UFC Development Team
! Date: 2026-04-10
! Version: v1.1 (Week 2 Day 3 - Enhanced Validation Tests)
! ================================================================================

PROGRAM test_keyword_framework
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType
  USE MD_KeyWord_Parser_Types
  USE MD_KeyWord_Parser_Recursive
  IMPLICIT NONE

  INTEGER(i4) :: total_tests = 0
  INTEGER(i4) :: passed_tests = 0
  INTEGER(i4) :: failed_tests = 0

  ! Initialize
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') "Phase 4 KeyWord Enhancement - Unit Test Framework"
  WRITE(*, '(A)') "Week 2 Day 3: Extended Validation Test Coverage"
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') ""

  ! ============================================================================
  ! Test Group 1: Parser Tests (PUBLIC)
  ! ============================================================================
  WRITE(*, '(A)') "--- Test Group 1: Parser Framework Tests ---"

  CALL test_parse_line_keywords()
  CALL test_parse_line_with_params()
  CALL test_parse_line_no_keyword()

  ! ============================================================================
  ! Test Group 2: Validation Tests (EXTENDED)
  ! ============================================================================
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "--- Test Group 2: Enhanced Validation Framework Tests ---"

  CALL test_validate_single_node()
  CALL test_validate_parent_child_relation()
  CALL test_validate_required_params()
  CALL test_validate_keyword_tree_framework()
  CALL test_validate_assembly_structure()
  CALL test_validate_contact_pair_structure()
  CALL test_validate_nested_keywords()

  ! ============================================================================
  ! Test Group 3: Mapping Tests (PUBLIC)
  ! ============================================================================
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "--- Test Group 3: Mapping Framework Tests ---"

  CALL test_map_keyword_tree_framework()

  ! ============================================================================
  ! Summary Report
  ! ============================================================================
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') "                  TEST SUMMARY REPORT"
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A, I4, A)') "  Total tests:     ", total_tests, ""
  WRITE(*, '(A, I4, A)') "  Passed tests:    ", passed_tests, " [OK]"
  WRITE(*, '(A, I4, A)') "  Failed tests:    ", failed_tests, " [FAIL]"

  IF (failed_tests == 0) THEN
    WRITE(*, '(A)') ""
    WRITE(*, '(A)') "  SUCCESS: All tests passed!"
  ELSE
    WRITE(*, '(A)') ""
    WRITE(*, '(A)') "  WARNING: Some tests failed"
  END IF

  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') ""

CONTAINS

  SUBROUTINE assert_true(condition, test_name)
    LOGICAL, INTENT(IN) :: condition
    CHARACTER(len=*), INTENT(IN) :: test_name

    total_tests = total_tests + 1

    IF (condition) THEN
      WRITE(*, '(A, A, A)') "    [PASS] ", TRIM(test_name), ""
      passed_tests = passed_tests + 1
    ELSE
      WRITE(*, '(A, A, A)') "    [FAIL] ", TRIM(test_name), ""
      failed_tests = failed_tests + 1
    END IF
  END SUBROUTINE assert_true

  ! ============================================================================
  ! Group 1: Parser Tests
  ! ============================================================================

  SUBROUTINE test_parse_line_keywords()
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    CHARACTER(len=256) :: line, keyword_name
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Test 1: *PART keyword
    line = "*PART, NAME=PART_1"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword .AND. (TRIM(keyword_name) == "*PART")
    CALL assert_true(test_pass, "Parse line - recognize *PART keyword")
    IF (ALLOCATED(params)) DEALLOCATE(params)

    ! Test 2: *MATERIAL keyword
    line = "*MATERIAL, NAME=STEEL"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword .AND. (TRIM(keyword_name) == "*MATERIAL")
    CALL assert_true(test_pass, "Parse line - recognize *MATERIAL keyword")
    IF (ALLOCATED(params)) DEALLOCATE(params)

    ! Test 3: *NODE keyword
    line = "*NODE"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword
    CALL assert_true(test_pass, "Parse line - recognize *NODE keyword")
    IF (ALLOCATED(params)) DEALLOCATE(params)

  END SUBROUTINE test_parse_line_keywords

  SUBROUTINE test_parse_line_with_params()
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    CHARACTER(len=256) :: line, keyword_name
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    line = "*ELEMENT, TYPE=C3D8, ELSET=PART_1"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword .AND. (status%status_code == 0_i4)
    CALL assert_true(test_pass, "Parse line with params - extraction success")
    IF (ALLOCATED(params)) DEALLOCATE(params)

  END SUBROUTINE test_parse_line_with_params

  SUBROUTINE test_parse_line_no_keyword()
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    CHARACTER(len=256) :: line, keyword_name
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    line = "1,  0.0,  0.0,  0.0"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = .NOT. is_keyword
    CALL assert_true(test_pass, "Parse line - correctly identify non-keyword line")
    IF (ALLOCATED(params)) DEALLOCATE(params)

  END SUBROUTINE test_parse_line_no_keyword

  ! ============================================================================
  ! Group 2: Validation Tests
  ! ============================================================================

  SUBROUTINE test_validate_keyword_tree_framework()
    TYPE(KeyWord_Node_Type) :: root
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Create root node
    root%keyword_name = "ROOT"
    root%n_children = 0
    root%n_params = 0

    ! Call validation
    CALL MD_Validate_KeyWord_Tree(root, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, &
      "Validate keyword tree - framework callable and returns success")

  END SUBROUTINE test_validate_keyword_tree_framework

  ! ============================================================================
  ! [Week 2 Day 3] Extended Validation Tests
  ! ============================================================================

  SUBROUTINE test_validate_single_node()
    TYPE(KeyWord_Node_Type) :: node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Create a single *PART node
    node%keyword_name = "*PART"
    node%n_children = 0
    node%n_params = 1
    node%parent_id = 0_i4
    node%nesting_level = 1_i4

    ! Validate single node
    CALL MD_Validate_KeyWord_Tree(node, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, &
      "Validate single node - *PART node structure valid")

  END SUBROUTINE test_validate_single_node

  SUBROUTINE test_validate_parent_child_relation()
    TYPE(KeyWord_Node_Type) :: root, part_node, node_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Create root
    root%keyword_name = "ROOT"
    root%n_children = 1
    root%n_params = 0
    root%parent_id = -1_i4
    root%node_id = 0_i4
    ALLOCATE(root%child_keywords(1))

    ! Create *PART node
    part_node%keyword_name = "*PART"
    part_node%n_children = 1
    part_node%n_params = 1
    part_node%parent_id = 0_i4
    part_node%node_id = 1_i4
    part_node%nesting_level = 1_i4
    ALLOCATE(part_node%child_keywords(1))

    ! Create *NODE child
    node_node%keyword_name = "*NODE"
    node_node%n_children = 0
    node_node%n_params = 0
    node_node%parent_id = 1_i4
    node_node%node_id = 2_i4
    node_node%nesting_level = 2_i4

    ! Link structure
    part_node%child_keywords(1) = node_node
    root%child_keywords(1) = part_node

    ! Validate parent-child relationship
    CALL MD_Validate_KeyWord_Tree(root, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, &
      "Validate parent-child - *PART/*NODE hierarchy valid")

    ! Cleanup
    DEALLOCATE(root%child_keywords)
    DEALLOCATE(part_node%child_keywords)

  END SUBROUTINE test_validate_parent_child_relation

  SUBROUTINE test_validate_required_params()
    TYPE(KeyWord_Node_Type) :: material_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Create *MATERIAL node with required NAME parameter
    material_node%keyword_name = "*MATERIAL"
    material_node%n_children = 0
    material_node%n_params = 1
    material_node%parent_id = 0_i4
    material_node%nesting_level = 1_i4
    ALLOCATE(material_node%params(1))
    material_node%params(1) = "NAME"
    ALLOCATE(material_node%param_strings(1))
    material_node%param_strings(1) = "STEEL_1"

    ! Validate required parameters
    CALL MD_Validate_KeyWord_Tree(material_node, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, &
      "Validate required params - *MATERIAL with NAME parameter")

    ! Cleanup
    DEALLOCATE(material_node%params)
    DEALLOCATE(material_node%param_strings)

  END SUBROUTINE test_validate_required_params

  SUBROUTINE test_validate_assembly_structure()
    TYPE(KeyWord_Node_Type) :: assembly_node, instance_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Create *ASSEMBLY node
    assembly_node%keyword_name = "*ASSEMBLY"
    assembly_node%n_children = 1
    assembly_node%n_params = 1
    assembly_node%parent_id = 0_i4
    assembly_node%node_id = 3_i4
    assembly_node%nesting_level = 1_i4
    ALLOCATE(assembly_node%params(1))
    assembly_node%params(1) = "NAME"
    ALLOCATE(assembly_node%param_strings(1))
    assembly_node%param_strings(1) = "ASSEMBLY_1"
    ALLOCATE(assembly_node%child_keywords(1))

    ! Create *INSTANCE child
    instance_node%keyword_name = "*INSTANCE"
    instance_node%n_children = 0
    instance_node%n_params = 2
    instance_node%parent_id = 3_i4
    instance_node%node_id = 4_i4
    instance_node%nesting_level = 2_i4
    ALLOCATE(instance_node%params(2))
    instance_node%params(1) = "PART"
    instance_node%params(2) = "NAME"
    ALLOCATE(instance_node%param_strings(2))
    instance_node%param_strings(1) = "PART_1"
    instance_node%param_strings(2) = "INSTANCE_1"

    ! Link structure
    assembly_node%child_keywords(1) = instance_node

    ! Validate assembly structure
    CALL MD_Validate_KeyWord_Tree(assembly_node, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, &
      "Validate assembly - *ASSEMBLY/*INSTANCE structure valid")

    ! Cleanup
    DEALLOCATE(assembly_node%params)
    DEALLOCATE(assembly_node%param_strings)
    DEALLOCATE(assembly_node%child_keywords)
    DEALLOCATE(instance_node%params)
    DEALLOCATE(instance_node%param_strings)

  END SUBROUTINE test_validate_assembly_structure

  SUBROUTINE test_validate_contact_pair_structure()
    TYPE(KeyWord_Node_Type) :: contact_pair_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Create *CONTACT PAIR node
    contact_pair_node%keyword_name = "*CONTACT PAIR"
    contact_pair_node%n_children = 0
    contact_pair_node%n_params = 3
    contact_pair_node%parent_id = 0_i4
    contact_pair_node%nesting_level = 1_i4
    ALLOCATE(contact_pair_node%params(3))
    contact_pair_node%params(1) = "SURFACE1"
    contact_pair_node%params(2) = "SURFACE2"
    contact_pair_node%params(3) = "TYPE"
    ALLOCATE(contact_pair_node%param_strings(3))
    contact_pair_node%param_strings(1) = "SURF_1"
    contact_pair_node%param_strings(2) = "SURF_2"
    contact_pair_node%param_strings(3) = "SURFACE-TO-SURFACE"

    ! Validate contact pair structure
    CALL MD_Validate_KeyWord_Tree(contact_pair_node, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, &
      "Validate contact pair - *CONTACT PAIR parameters valid")

    ! Cleanup
    DEALLOCATE(contact_pair_node%params)
    DEALLOCATE(contact_pair_node%param_strings)

  END SUBROUTINE test_validate_contact_pair_structure

  SUBROUTINE test_validate_nested_keywords()
    TYPE(KeyWord_Node_Type) :: root, step_node, static_node, boundary_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Create root
    root%keyword_name = "ROOT"
    root%n_children = 1
    root%n_params = 0
    root%parent_id = -1_i4
    root%node_id = 0_i4
    ALLOCATE(root%child_keywords(1))

    ! Create *STEP node
    step_node%keyword_name = "*STEP"
    step_node%n_children = 2
    step_node%n_params = 1
    step_node%parent_id = 0_i4
    step_node%node_id = 5_i4
    step_node%nesting_level = 1_i4
    ALLOCATE(step_node%params(1))
    step_node%params(1) = "NAME"
    ALLOCATE(step_node%param_strings(1))
    step_node%param_strings(1) = "STEP_1"
    ALLOCATE(step_node%child_keywords(2))

    ! Create *STATIC child
    static_node%keyword_name = "*STATIC"
    static_node%n_children = 0
    static_node%n_params = 0
    static_node%parent_id = 5_i4
    static_node%node_id = 6_i4
    static_node%nesting_level = 2_i4

    ! Create *BOUNDARY child
    boundary_node%keyword_name = "*BOUNDARY"
    boundary_node%n_children = 0
    boundary_node%n_params = 0
    boundary_node%parent_id = 5_i4
    boundary_node%node_id = 7_i4
    boundary_node%nesting_level = 2_i4

    ! Link structure
    step_node%child_keywords(1) = static_node
    step_node%child_keywords(2) = boundary_node
    root%child_keywords(1) = step_node

    ! Validate nested structure
    CALL MD_Validate_KeyWord_Tree(root, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, &
      "Validate nested - *STEP/*STATIC/*BOUNDARY structure valid")

    ! Cleanup
    DEALLOCATE(root%child_keywords)
    DEALLOCATE(step_node%params)
    DEALLOCATE(step_node%param_strings)
    DEALLOCATE(step_node%child_keywords)

  END SUBROUTINE test_validate_nested_keywords

  ! ============================================================================
  ! Group 3: Mapping Tests
  ! ============================================================================

  SUBROUTINE test_map_keyword_tree_framework()
    TYPE(KeyWord_Node_Type) :: root
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Create root node
    root%keyword_name = "ROOT"
    root%n_children = 0
    root%n_params = 0

    ! Call mapping
    CALL MD_Map_KeyWord_Tree_To_Model(root, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, &
      "Map keyword tree - framework callable and returns success")

  END SUBROUTINE test_map_keyword_tree_framework

END PROGRAM test_keyword_framework
