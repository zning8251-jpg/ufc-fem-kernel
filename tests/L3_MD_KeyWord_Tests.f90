! ================================================================================
! Module: L3_MD_KeyWord_Tests
! ================================================================================
! Purpose:
!   单元测试框架 (pFUnit) - Phase 4 KeyWord 补强项目
!   测试递归解析器、验证逻辑、模型映射的完整功能
!
! Test Structure:
!   1. 初始化测试 (Setup)
!   2. 关键字解析测试 (Parsing)
!   3. 验证逻辑测试 (Validation)
!   4. 模型映射测试 (Mapping)
!   5. 集成测试 (Integration)
!
! Author: UFC Development Team
! Date: 2026-04-09
! Version: v1.0 (Week 2 Day 2)
! ================================================================================

MODULE L3_MD_KeyWord_Tests
  USE pfunit_mod
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType
  USE MD_KeyWord_Parser_Types
  USE MD_KeyWord_Parser_Recursive
  IMPLICIT NONE

  PRIVATE
  PUBLIC :: test_parse_part_keyword, &
            test_parse_node_data, &
            test_parse_element_data, &
            test_parse_material_keyword, &
            test_parse_elastic_data, &
            test_validate_keyword_tree, &
            test_map_assembly_keyword, &
            test_map_contact_pair_keyword, &
            test_map_output_keyword, &
            test_full_integration

  ! 全局测试变量
  TYPE(KeyWord_Node_Type), ALLOCATABLE :: test_root_node
  TYPE(ErrorStatusType) :: test_status

CONTAINS

  ! ============================================================================
  ! [Test Group 1] 解析器单元测试
  ! ============================================================================

  !> Test: 解析 *PART 关键字
  SUBROUTINE test_parse_part_keyword()
    TYPE(KeyWord_Node_Type) :: part_node
    CHARACTER(len=256) :: line, part_name
    TYPE(ErrorStatusType) :: status
    LOGICAL :: is_keyword
    INTEGER(i4) :: n_params

    ! Setup
    CALL setup_test_environment()

    ! 测试输入行
    line = "*PART, NAME=PART_1"

    ! Execute
    CALL MD_Parse_Line(line, is_keyword, part_node%keyword_name, part_node%params, status)

    ! Assert
    IF (is_keyword) THEN
      CALL assert_that(TRIM(part_node%keyword_name) == "*PART", &
                       "Failed: keyword name should be *PART")
      CALL assert_that(ASSOCIATED(part_node%params), &
                       "Failed: params should be allocated")
    END IF

    ! Cleanup
    CALL cleanup_test_environment()

  END SUBROUTINE test_parse_part_keyword

  !> Test: 解析 *NODE 数据块
  SUBROUTINE test_parse_node_data()
    TYPE(KeyWord_Node_Type) :: node_node
    CHARACTER(len=256) :: data_lines(5)
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: i

    ! Setup
    CALL setup_test_environment()

    ! 创建测试数据块
    data_lines(1) = "1,  0.0,  0.0,  0.0"
    data_lines(2) = "2,  1.0,  0.0,  0.0"
    data_lines(3) = "3,  1.0,  1.0,  0.0"
    data_lines(4) = "4,  0.0,  1.0,  0.0"

    ! Execute
    node_node%keyword_name = "*NODE"
    node_node%n_rows = 4
    node_node%n_cols = 4
    ALLOCATE(node_node%data_block(4, 4))

    CALL parse_data_block_to_matrix(data_lines(1:4), 4, node_node%data_block, status)

    ! Assert
    CALL assert_that(status%status_code == 0_i4, &
                     "Failed: data block parsing should succeed")
    CALL assert_that(node_node%data_block(1, 1) == 1.0_wp, &
                     "Failed: first node ID should be 1")
    CALL assert_that(node_node%data_block(2, 2) == 1.0_wp, &
                     "Failed: second node X coord should be 1.0")

    ! Cleanup
    IF (ALLOCATED(node_node%data_block)) DEALLOCATE(node_node%data_block)
    CALL cleanup_test_environment()

  END SUBROUTINE test_parse_node_data

  !> Test: 解析 *ELEMENT 数据块
  SUBROUTINE test_parse_element_data()
    TYPE(KeyWord_Node_Type) :: elem_node
    CHARACTER(len=256) :: data_lines(2)
    TYPE(ErrorStatusType) :: status

    ! Setup
    CALL setup_test_environment()

    ! 创建测试数据块 (C3D8 单元)
    data_lines(1) = "1,  1,  2,  3,  4,  5,  6,  7,  8"
    data_lines(2) = "2,  5,  6,  7,  8,  9, 10, 11, 12"

    ! Execute
    elem_node%keyword_name = "*ELEMENT"
    elem_node%n_rows = 2
    elem_node%n_cols = 9  ! elem_id + 8 node IDs
    ALLOCATE(elem_node%data_block(2, 9))

    CALL parse_data_block_to_matrix(data_lines(1:2), 2, elem_node%data_block, status)

    ! Assert
    CALL assert_that(status%status_code == 0_i4, &
                     "Failed: element data block parsing should succeed")
    CALL assert_that(elem_node%data_block(1, 1) == 1.0_wp, &
                     "Failed: first element ID should be 1")
    CALL assert_that(elem_node%data_block(1, 9) == 8.0_wp, &
                     "Failed: first element last node ID should be 8")

    ! Cleanup
    IF (ALLOCATED(elem_node%data_block)) DEALLOCATE(elem_node%data_block)
    CALL cleanup_test_environment()

  END SUBROUTINE test_parse_element_data

  !> Test: 解析 *MATERIAL 关键字
  SUBROUTINE test_parse_material_keyword()
    CHARACTER(len=256) :: line
    TYPE(KeyWord_Node_Type) :: mat_node
    LOGICAL :: is_keyword
    TYPE(ErrorStatusType) :: status

    ! Setup
    CALL setup_test_environment()

    line = "*MATERIAL, NAME=STEEL_1"

    ! Execute
    CALL MD_Parse_Line(line, is_keyword, mat_node%keyword_name, mat_node%params, status)

    ! Assert
    IF (is_keyword) THEN
      CALL assert_that(TRIM(mat_node%keyword_name) == "*MATERIAL", &
                       "Failed: keyword name should be *MATERIAL")
    END IF

    ! Cleanup
    CALL cleanup_test_environment()

  END SUBROUTINE test_parse_material_keyword

  !> Test: 解析 *ELASTIC 数据块
  SUBROUTINE test_parse_elastic_data()
    TYPE(KeyWord_Node_Type) :: elastic_node
    CHARACTER(len=256) :: data_lines(1)
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: E, nu

    ! Setup
    CALL setup_test_environment()

    ! 创建测试数据块 (E, nu)
    data_lines(1) = "2.1E+05,  0.3"

    ! Execute
    elastic_node%keyword_name = "*ELASTIC"
    elastic_node%n_rows = 1
    elastic_node%n_cols = 2
    ALLOCATE(elastic_node%data_block(1, 2))

    CALL parse_data_block_to_matrix(data_lines(1:1), 1, elastic_node%data_block, status)

    ! Extract values
    E = elastic_node%data_block(1, 1)
    nu = elastic_node%data_block(1, 2)

    ! Assert
    CALL assert_that(status%status_code == 0_i4, &
                     "Failed: elastic data parsing should succeed")
    CALL assert_that(ABS(E - 2.1E+05_wp) < 1.0E+02_wp, &
                     "Failed: Young's modulus should be ~2.1E+05")
    CALL assert_that(ABS(nu - 0.3_wp) < 0.01_wp, &
                     "Failed: Poisson's ratio should be ~0.3")

    ! Cleanup
    IF (ALLOCATED(elastic_node%data_block)) DEALLOCATE(elastic_node%data_block)
    CALL cleanup_test_environment()

  END SUBROUTINE test_parse_elastic_data

  ! ============================================================================
  ! [Test Group 2] 验证逻辑测试
  ! ============================================================================

  !> Test: 验证关键字树完整性
  SUBROUTINE test_validate_keyword_tree()
    TYPE(KeyWord_Node_Type) :: root_node
    TYPE(ErrorStatusType) :: status

    ! Setup
    CALL setup_test_environment()

    ! 创建简单的关键字树
    root_node%keyword_name = "ROOT"
    root_node%n_children = 0
    root_node%n_params = 0

    ! Execute
    CALL MD_Validate_KeyWord_Tree(root_node, status)

    ! Assert
    CALL assert_that(status%status_code == 0_i4, &
                     "Failed: keyword tree validation should succeed")

    ! Cleanup
    CALL cleanup_test_environment()

  END SUBROUTINE test_validate_keyword_tree

  ! ============================================================================
  ! [Test Group 3] 模型映射测试
  ! ============================================================================

  !> Test: 映射 *ASSEMBLY 关键字
  SUBROUTINE test_map_assembly_keyword()
    TYPE(KeyWord_Node_Type) :: assembly_node
    CHARACTER(len=256) :: assembly_name
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: i

    ! Setup
    CALL setup_test_environment()

    ! 创建测试节点
    assembly_node%keyword_name = "*ASSEMBLY"
    assembly_node%n_params = 1
    ALLOCATE(assembly_node%params(1))
    assembly_node%params(1) = "NAME=ASSEMBLY_1"

    ! Execute
    CALL map_assembly_keyword(assembly_node, status)

    ! Assert
    CALL assert_that(status%status_code == 0_i4, &
                     "Failed: assembly keyword mapping should succeed")

    ! Cleanup
    IF (ALLOCATED(assembly_node%params)) DEALLOCATE(assembly_node%params)
    CALL cleanup_test_environment()

  END SUBROUTINE test_map_assembly_keyword

  !> Test: 映射 *CONTACT PAIR 关键字
  SUBROUTINE test_map_contact_pair_keyword()
    TYPE(KeyWord_Node_Type) :: contact_node
    TYPE(ErrorStatusType) :: status

    ! Setup
    CALL setup_test_environment()

    ! 创建测试节点
    contact_node%keyword_name = "*CONTACT PAIR"
    contact_node%n_params = 3
    ALLOCATE(contact_node%params(3))
    contact_node%params(1) = "SURFACE1=SURF_1"
    contact_node%params(2) = "SURFACE2=SURF_2"
    contact_node%params(3) = "TYPE=SURFACE-TO-SURFACE"

    ! Execute
    CALL map_contact_pair_keyword(contact_node, status)

    ! Assert
    CALL assert_that(status%status_code == 0_i4, &
                     "Failed: contact pair mapping should succeed")

    ! Cleanup
    IF (ALLOCATED(contact_node%params)) DEALLOCATE(contact_node%params)
    CALL cleanup_test_environment()

  END SUBROUTINE test_map_contact_pair_keyword

  !> Test: 映射 *OUTPUT 关键字
  SUBROUTINE test_map_output_keyword()
    TYPE(KeyWord_Node_Type) :: output_node
    TYPE(ErrorStatusType) :: status

    ! Setup
    CALL setup_test_environment()

    ! 创建测试节点
    output_node%keyword_name = "*OUTPUT"
    output_node%n_params = 2
    ALLOCATE(output_node%params(2))
    output_node%params(1) = "FREQUENCY=1"
    output_node%params(2) = "TYPE=FIELD_OUTPUT"

    ! Execute
    CALL map_output_keyword(output_node, status)

    ! Assert
    CALL assert_that(status%status_code == 0_i4, &
                     "Failed: output keyword mapping should succeed")

    ! Cleanup
    IF (ALLOCATED(output_node%params)) DEALLOCATE(output_node%params)
    CALL cleanup_test_environment()

  END SUBROUTINE test_map_output_keyword

  ! ============================================================================
  ! [Test Group 4] 集成测试
  ! ============================================================================

  !> Test: 完整流程集成测试
  SUBROUTINE test_full_integration()
    TYPE(KeyWord_Node_Type) :: root_node, part_node, node_node
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: i

    ! Setup
    CALL setup_test_environment()

    ! 创建根节点
    root_node%keyword_name = "ROOT"
    root_node%n_children = 2
    ALLOCATE(root_node%child_keywords(2))

    ! 创建 PART 节点
    part_node%keyword_name = "*PART"
    part_node%n_params = 1
    part_node%n_children = 1
    ALLOCATE(part_node%params(1))
    part_node%params(1) = "NAME=PART_1"
    ALLOCATE(part_node%child_keywords(1))

    ! 创建 NODE 节点
    node_node%keyword_name = "*NODE"
    node_node%n_rows = 1
    node_node%n_cols = 4
    ALLOCATE(node_node%data_block(1, 4))
    node_node%data_block(1, :) = [1.0_wp, 0.0_wp, 0.0_wp, 0.0_wp]

    ! 组织树结构
    part_node%child_keywords(1) = node_node
    root_node%child_keywords(1) = part_node

    ! Execute: 验证树
    CALL MD_Validate_KeyWord_Tree(root_node, status)

    ! Assert
    CALL assert_that(status%status_code == 0_i4, &
                     "Failed: full integration test should succeed")

    ! Cleanup
    IF (ALLOCATED(root_node%child_keywords)) DEALLOCATE(root_node%child_keywords)
    IF (ALLOCATED(part_node%params)) DEALLOCATE(part_node%params)
    IF (ALLOCATED(part_node%child_keywords)) DEALLOCATE(part_node%child_keywords)
    IF (ALLOCATED(node_node%data_block)) DEALLOCATE(node_node%data_block)
    CALL cleanup_test_environment()

  END SUBROUTINE test_full_integration

  ! ============================================================================
  ! 测试辅助函数
  ! ============================================================================

  SUBROUTINE setup_test_environment()
    ! 初始化全局规则表 (Week 2 Day 2 新增)
    TYPE(ErrorStatusType) :: init_status
    CALL MD_Initialize_KeyWord_Rules(init_status)
  END SUBROUTINE setup_test_environment

  SUBROUTINE cleanup_test_environment()
    ! 清理测试环境
    IF (ALLOCATED(test_root_node)) DEALLOCATE(test_root_node)
  END SUBROUTINE cleanup_test_environment

END MODULE L3_MD_KeyWord_Tests
