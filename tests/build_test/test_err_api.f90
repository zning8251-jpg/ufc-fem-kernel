!===============================================================================
! Unit Test: IF_Err_API 错误处理链验证
!===============================================================================
! 测试内容:
!   1. init_error_status - 初始化
!   2. error_set - 设置错误
!   3. error_clear - 清除错误
!   4. error_has_error - 检查错误
!   5. 错误传播链
!===============================================================================

PROGRAM test_err_api

    USE IF_Err_Type, ONLY: ErrorStatusType, i4, i8
    USE IF_Err_API, ONLY: init_error_status, error_set, error_clear, error_has_error, &
                          IF_ERROR_CATEGORY_OK, IF_ERROR_CODE_MEMORY_ALLOCATION, &
                          IF_ERROR_CODE_FILE_NOT_FOUND, IF_ERROR_CODE_INVALID_PARAMETER, &
                          IF_ERROR_CODE_MATH_SINGULAR_MATRIX, IF_STATUS_OK, IF_STATUS_SUCCESS, &
                          IF_STATUS_ERROR, log_info

    ! 测试变量
    TYPE(ErrorStatusType) :: status
    LOGICAL :: has_err
    INTEGER(i4) :: test_count, pass_count
    CHARACTER(len=256) :: test_name

    test_count = 0
    pass_count = 0

    WRITE(*,'(A)') ""
    WRITE(*,'(A)') "============================================"
    WRITE(*,'(A)') "  IF_Err_API 错误处理链单元测试"
    WRITE(*,'(A)') "============================================"
    WRITE(*,'(A)') ""

    !==========================================================================
    ! Test 1: init_error_status - 初始化无错误状态
    !==========================================================================
    test_count = test_count + 1
    test_name = "init_error_status - OK状态"

    CALL init_error_status(status)

    has_err = error_has_error(status)

    IF (.NOT. has_err .AND. status%status_code == IF_ERROR_CATEGORY_OK) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
        WRITE(*,'(A,I20)') "  status_code = ", status%status_code
        WRITE(*,'(A,L1)') "  has_error = ", status%has_error
    END IF

    !==========================================================================
    ! Test 2: init_error_status - 初始化带错误码
    !==========================================================================
    test_count = test_count + 1
    test_name = "init_error_status - 带错误码"

    CALL init_error_status(status, status_code=IF_ERROR_CODE_MEMORY_ALLOCATION, &
                            message="Test allocation error", source="TEST")

    has_err = error_has_error(status)

    IF (has_err .AND. status%status_code == IF_ERROR_CODE_MEMORY_ALLOCATION) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
        WRITE(*,'(A,I20)') "  status_code = ", status%status_code
        WRITE(*,'(A,L1)') "  has_error = ", status%has_error
    END IF

    !==========================================================================
    ! Test 3: error_set - 设置错误
    !==========================================================================
    test_count = test_count + 1
    test_name = "error_set - 设置文件未找到错误"

    CALL error_set(IF_ERROR_CODE_FILE_NOT_FOUND, "File test.inp not found", &
                   source="TEST", status=status)

    has_err = error_has_error(status)

    IF (has_err .AND. status%status_code == IF_ERROR_CODE_FILE_NOT_FOUND) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 4: error_clear - 清除错误
    !==========================================================================
    test_count = test_count + 1
    test_name = "error_clear - 清除错误状态"

    ! 先设置一个错误
    CALL error_set(IF_ERROR_CODE_INVALID_PARAMETER, "Invalid param", &
                   source="TEST", status=status)

    ! 再清除
    CALL error_clear(status)
    has_err = error_has_error(status)

    IF (.NOT. has_err .AND. status%status_code == IF_ERROR_CATEGORY_OK) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
        WRITE(*,'(A,I20)') "  status_code = ", status%status_code
        WRITE(*,'(A,L1)') "  has_error = ", status%has_error
    END IF

    !==========================================================================
    ! Test 5: error_has_error - 检查错误
    !==========================================================================
    test_count = test_count + 1
    test_name = "error_has_error - 无错误时返回 FALSE"

    CALL init_error_status(status)
    has_err = error_has_error(status)

    IF (.NOT. has_err) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 6: 错误传播链
    !==========================================================================
    test_count = test_count + 1
    test_name = "错误传播链 - Level1 -> Level2 -> Level3"

    CALL init_error_status(status)

    ! 模拟 Level1 错误
    CALL propagate_error_level1(status)

    has_err = error_has_error(status)

    IF (has_err .AND. status%status_code == IF_ERROR_CODE_MATH_SINGULAR_MATRIX) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
        WRITE(*,'(A,I20)') "  status_code = ", status%status_code
        WRITE(*,'(A,A)') "  message = ", TRIM(status%message)
    END IF

    !==========================================================================
    ! Test 7: 兼容性常量
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_STATUS_* 兼容性常量"

    IF (IF_STATUS_OK == IF_ERROR_CATEGORY_OK .AND. &
        IF_STATUS_SUCCESS == IF_ERROR_CATEGORY_OK .AND. &
        IF_STATUS_ERROR == 2_i4) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 8: 日志函数 (log_info)
    !==========================================================================
    test_count = test_count + 1
    test_name = "log_info - 日志输出"

    WRITE(*,'(A,I2,A)') "[INFO] Test ", test_count, ": "//TRIM(test_name)
    CALL log_info("TEST", "This is an info message")
    WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
    pass_count = pass_count + 1

    !==========================================================================
    ! 测试汇总
    !==========================================================================
    WRITE(*,'(A)') ""
    WRITE(*,'(A)') "============================================"
    WRITE(*,'(A,I2,A,I2,A)') "  测试结果: ", pass_count, "/", test_count, " 通过"
    WRITE(*,'(A)') "============================================"

    IF (pass_count == test_count) THEN
        WRITE(*,'(A)') "  状态: 全部通过 ✅"
    ELSE
        WRITE(*,'(A)') "  状态: 部分失败 ❌"
    END IF
    WRITE(*,'(A)') ""

CONTAINS

    !==========================================================================
    ! 辅助函数: 模拟 Level1 错误传播到 Level2
    !==========================================================================
    SUBROUTINE propagate_error_level1(status_out)
        TYPE(ErrorStatusType), INTENT(OUT) :: status_out
        TYPE(ErrorStatusType) :: status_l1

        ! Level1: 设置初始错误
        CALL error_set(IF_ERROR_CODE_MATH_SINGULAR_MATRIX, &
                       "Singular matrix detected in LU decomposition", &
                       source="MATRIX_SOLVER", status=status_l1)

        ! 传播到 Level2
        CALL propagate_error_level2(status_l1, status_out)
    END SUBROUTINE propagate_error_level1

    !==========================================================================
    ! 辅助函数: 模拟 Level2 错误传播
    !==========================================================================
    SUBROUTINE propagate_error_level2(status_in, status_out)
        TYPE(ErrorStatusType), INTENT(IN) :: status_in
        TYPE(ErrorStatusType), INTENT(OUT) :: status_out

        ! Level2: 添加上下文后传播
        IF (error_has_error(status_in)) THEN
            status_out = status_in
            status_out%source = TRIM(status_in%source) // " -> LINEAR_SOLVER"
        ELSE
            CALL init_error_status(status_out)
        END IF
    END SUBROUTINE propagate_error_level2

END PROGRAM test_err_api
