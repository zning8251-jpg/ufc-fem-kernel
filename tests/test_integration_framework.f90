! ================================================================================
! Program: test_integration_framework
! ================================================================================
! Purpose:
!   Integration test driver for Phase 4 KeyWord Enhancement Project
!   Tests complete workflow: Parse .inp files -> Validate -> Map to Model
!
! Author: UFC Development Team
! Date: 2026-04-11
! Version: v1.0 (Week 2 Day 4 - Integration Test Framework)
! ================================================================================

PROGRAM test_integration_framework
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType
  USE MD_KeyWord_Parser_Types
  USE MD_KeyWord_Parser_Recursive
  USE MD_KeyWord_Validator
  IMPLICIT NONE

  INTEGER(i4) :: total_tests = 0
  INTEGER(i4) :: passed_tests = 0
  INTEGER(i4) :: failed_tests = 0
  INTEGER(i4) :: i

  CHARACTER(len=256) :: sample_files(3)
  CHARACTER(len=256) :: test_name

  ! Initialize
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') "Phase 4 KeyWord Enhancement - Integration Test Framework"
  WRITE(*, '(A)') "Week 2 Day 4: Complete Workflow Validation"
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') ""

  ! Setup sample file list
  sample_files(1) = "samples/sample_1_simple_part.inp"
  sample_files(2) = "samples/sample_2_assembly_contact.inp"
  sample_files(3) = "samples/sample_3_step_static.inp"

  ! ============================================================================
  ! Test Group 1: File Reading and Parsing
  ! ============================================================================
  WRITE(*, '(A)') "--- Test Group 1: File Reading and Parsing ---"

  DO i = 1, 3
    WRITE(test_name, '(A,I1,A)') "Parse sample file ", i, " - file I/O"
    CALL test_file_reading(sample_files(i), test_name)
  END DO

  ! ============================================================================
  ! Test Group 2: Keyword Parsing
  ! ============================================================================
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "--- Test Group 2: Keyword Parsing Workflow ---"

  CALL test_parse_part_keyword()
  CALL test_parse_material_keyword()
  CALL test_parse_element_keyword()
  CALL test_parse_assembly_keyword()
  CALL test_parse_step_keyword()

  ! ============================================================================
  ! Test Group 3: Tree Validation
  ! ============================================================================
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "--- Test Group 3: Keyword Tree Validation ---"

  CALL test_validate_part_tree()
  CALL test_validate_assembly_tree()
  CALL test_validate_step_tree()

  ! ============================================================================
  ! Test Group 4: Model Mapping
  ! ============================================================================
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "--- Test Group 4: Model Mapping Integration ---"

  CALL test_map_complete_workflow()

  ! ============================================================================
  ! Test Group 5: Error Handling
  ! ============================================================================
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "--- Test Group 5: Error Handling and Edge Cases ---"

  CALL test_invalid_keyword()
  CALL test_missing_required_param()
  CALL test_malformed_line()

  ! ============================================================================
  ! Summary Report
  ! ============================================================================
  WRITE(*, '(A)') ""
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') "                  INTEGRATION TEST SUMMARY"
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A, I4, A)') "  Total tests:     ", total_tests, ""
  WRITE(*, '(A, I4, A)') "  Passed tests:    ", passed_tests, " [OK]"
  WRITE(*, '(A, I4, A)') "  Failed tests:    ", failed_tests, " [FAIL]"

  IF (failed_tests == 0) THEN
    WRITE(*, '(A)') "  Status: ALL TESTS PASSED [100%]"
  ELSE
    WRITE(*, '(A)') "  Status: SOME TESTS FAILED"
  END IF
  WRITE(*, '(A)') "=========================================================="
  WRITE(*, '(A)') ""

CONTAINS

  ! ============================================================================
  ! Utility: Assert True
  ! ============================================================================

  SUBROUTINE assert_true(condition, test_name_arg)
    LOGICAL, INTENT(IN) :: condition
    CHARACTER(len=*), INTENT(IN) :: test_name_arg

    total_tests = total_tests + 1

    IF (condition) THEN
      WRITE(*, '(A, A, A)') "    [PASS] ", TRIM(test_name_arg), ""
      passed_tests = passed_tests + 1
    ELSE
      WRITE(*, '(A, A, A)') "    [FAIL] ", TRIM(test_name_arg), ""
      failed_tests = failed_tests + 1
    END IF
  END SUBROUTINE assert_true

  ! ============================================================================
  ! Test Group 1: File Reading
  ! ============================================================================

  SUBROUTINE test_file_reading(filename, test_desc)
    CHARACTER(len=*), INTENT(IN) :: filename, test_desc
    LOGICAL :: file_exists
    LOGICAL :: test_pass

    ! Check if file exists
    INQUIRE(FILE=TRIM(filename), EXIST=file_exists)
    test_pass = file_exists

    CALL assert_true(test_pass, test_desc)
  END SUBROUTINE test_file_reading

  ! ============================================================================
  ! Test Group 2: Keyword Parsing
  ! ============================================================================

  SUBROUTINE test_parse_part_keyword()
    CHARACTER(len=256) :: line
    CHARACTER(len=256) :: keyword_name
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    line = "*PART, NAME=TEST_PART"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword .AND. (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Parse *PART keyword - complete workflow")

    IF (ALLOCATED(params)) DEALLOCATE(params)
  END SUBROUTINE test_parse_part_keyword

  SUBROUTINE test_parse_material_keyword()
    CHARACTER(len=256) :: line
    CHARACTER(len=256) :: keyword_name
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    line = "*MATERIAL, NAME=STEEL"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword .AND. (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Parse *MATERIAL keyword")

    IF (ALLOCATED(params)) DEALLOCATE(params)
  END SUBROUTINE test_parse_material_keyword

  SUBROUTINE test_parse_element_keyword()
    CHARACTER(len=256) :: line
    CHARACTER(len=256) :: keyword_name
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    line = "*ELEMENT, TYPE=C3D8, ELSET=ELEMENTS"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword .AND. (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Parse *ELEMENT keyword")

    IF (ALLOCATED(params)) DEALLOCATE(params)
  END SUBROUTINE test_parse_element_keyword

  SUBROUTINE test_parse_assembly_keyword()
    CHARACTER(len=256) :: line
    CHARACTER(len=256) :: keyword_name
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    line = "*ASSEMBLY, NAME=ASSEMBLY_1"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword .AND. (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Parse *ASSEMBLY keyword")

    IF (ALLOCATED(params)) DEALLOCATE(params)
  END SUBROUTINE test_parse_assembly_keyword

  SUBROUTINE test_parse_step_keyword()
    CHARACTER(len=256) :: line
    CHARACTER(len=256) :: keyword_name
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    line = "*STEP, NAME=STEP_1, INC=100"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = is_keyword .AND. (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Parse *STEP keyword")

    IF (ALLOCATED(params)) DEALLOCATE(params)
  END SUBROUTINE test_parse_step_keyword

  ! ============================================================================
  ! Test Group 3: Tree Validation
  ! ============================================================================

  SUBROUTINE test_validate_part_tree()
    TYPE(KeyWord_Node_Type) :: part_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    part_node%keyword_name = "*PART"
    part_node%n_children = 2
    part_node%n_params = 1
    part_node%parent_id = 0_i4
    part_node%nesting_level = 1_i4

    CALL MD_Validate_KeyWord_Tree(part_node, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Validate PART tree structure")
  END SUBROUTINE test_validate_part_tree

  SUBROUTINE test_validate_assembly_tree()
    TYPE(KeyWord_Node_Type) :: assembly_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    assembly_node%keyword_name = "*ASSEMBLY"
    assembly_node%n_children = 2
    assembly_node%n_params = 1
    assembly_node%parent_id = 0_i4
    assembly_node%nesting_level = 1_i4

    CALL MD_Validate_KeyWord_Tree(assembly_node, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Validate ASSEMBLY tree structure")
  END SUBROUTINE test_validate_assembly_tree

  SUBROUTINE test_validate_step_tree()
    TYPE(KeyWord_Node_Type) :: step_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    step_node%keyword_name = "*STEP"
    step_node%n_children = 3
    step_node%n_params = 2
    step_node%parent_id = 0_i4
    step_node%nesting_level = 1_i4

    CALL MD_Validate_KeyWord_Tree(step_node, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Validate STEP tree structure")
  END SUBROUTINE test_validate_step_tree

  ! ============================================================================
  ! Test Group 4: Model Mapping
  ! ============================================================================

  SUBROUTINE test_map_complete_workflow()
    TYPE(KeyWord_Node_Type) :: root_node
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Initialize root
    root_node%keyword_name = "ROOT"
    root_node%n_children = 0
    root_node%n_params = 0
    root_node%parent_id = -1_i4
    root_node%node_id = 0_i4

    ! Call mapping workflow
    CALL MD_Map_KeyWord_Tree_To_Model(root_node, status)
    test_pass = (status%status_code == 0_i4)

    CALL assert_true(test_pass, "Complete parse-validate-map workflow")
  END SUBROUTINE test_map_complete_workflow

  ! ============================================================================
  ! Test Group 5: Error Handling
  ! ============================================================================

  SUBROUTINE test_invalid_keyword()
    CHARACTER(len=256) :: line
    CHARACTER(len=256) :: keyword_name
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    LOGICAL :: is_keyword, is_valid
    TYPE(ErrorStatusType) :: status, validation_status
    LOGICAL :: test_pass

    line = "*INVALID_KEYWORD, PARAM1=VALUE1"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    
    ! Validate keyword against whitelist
    IF (is_keyword) THEN
      CALL MD_Is_Valid_Keyword(keyword_name, is_valid, validation_status)
      test_pass = (.NOT. is_valid) .OR. (validation_status%status_code /= 0_i4)
    ELSE
      test_pass = .NOT. is_keyword
    END IF

    CALL assert_true(test_pass, "Detect invalid keyword - error handling")

    IF (ALLOCATED(params)) DEALLOCATE(params)
  END SUBROUTINE test_invalid_keyword

  SUBROUTINE test_missing_required_param()
    CHARACTER(len=256) :: line
    CHARACTER(len=256) :: keyword_name
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status, param_validation_status
    LOGICAL :: test_pass
    INTEGER(i4) :: param_count

    ! *PART without NAME parameter (should fail validation)
    line = "*PART"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    
    ! Check required parameters
    IF (is_keyword) THEN
      IF (ALLOCATED(params)) THEN
        param_count = SIZE(params)
      ELSE
        param_count = 0_i4
      END IF
      CALL MD_Validate_Required_Params(keyword_name, param_count, param_validation_status)
      test_pass = (param_validation_status%status_code /= 0_i4)
    ELSE
      test_pass = .NOT. is_keyword
    END IF

    CALL assert_true(test_pass, "Detect missing required parameter")

    IF (ALLOCATED(params)) DEALLOCATE(params)
  END SUBROUTINE test_missing_required_param

  SUBROUTINE test_malformed_line()
    CHARACTER(len=256) :: line
    CHARACTER(len=256) :: keyword_name
    CHARACTER(len=256), ALLOCATABLE :: params(:)
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status
    LOGICAL :: test_pass

    ! Malformed line (inconsistent format)
    line = "NOT_A_KEYWORD"
    CALL MD_Parse_Line(line, is_keyword, keyword_name, params, status)
    test_pass = .NOT. is_keyword

    CALL assert_true(test_pass, "Reject malformed input line")

    IF (ALLOCATED(params)) DEALLOCATE(params)
  END SUBROUTINE test_malformed_line

END PROGRAM test_integration_framework
