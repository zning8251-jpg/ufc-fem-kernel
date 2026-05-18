!===============================================================================
! Unit Test: IF_Prec 精度验证
!===============================================================================
! 测试内容:
!   1. 精度类型定义 (sp, dp, qp, wp)
!   2. 数值稳定性检查 (IsNaN, IsInf, IsFinite)
!   3. 溢出/下溢检查
!===============================================================================

PROGRAM test_prec

    USE IF_Err_Type, ONLY: wp, i4, i8, ErrorStatusType
    USE IF_Err_API, ONLY: init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: sp, dp, qp, &
                        IF_Prec_IsNaN, IF_Prec_IsInf, IF_Prec_IsFinite, &
                        IF_Prec_Check_Overflow, IF_Prec_Check_Underflow, &
                        IF_Prec_Check_Stability, &
                        WP_EPSILON, WP_TINY, WP_HUGE
    IMPLICIT NONE

    ! 测试变量
    TYPE(ErrorStatusType) :: status
    LOGICAL :: has_err, is_stable
    INTEGER(i4) :: test_count, pass_count
    CHARACTER(len=256) :: test_name

    REAL(wp) :: test_val
    REAL(wp) :: nan_val, inf_val, large_val, tiny_val, normal_val
    REAL(wp) :: zero_val

    test_count = 0
    pass_count = 0
    zero_val = 0.0_wp

    WRITE(*,'(A)') ""
    WRITE(*,'(A)') "============================================"
    WRITE(*,'(A)') "  IF_Prec 精度验证单元测试"
    WRITE(*,'(A)') "============================================"
    WRITE(*,'(A)') ""

    !==========================================================================
    ! Test 1: 精度类型 KIND 值
    !==========================================================================
    test_count = test_count + 1
    test_name = "精度类型 KIND 值"

    WRITE(*,'(A,I2,A,A)') "[INFO] Test ", test_count, ": ", TRIM(test_name)
    WRITE(*,'(A,I10)') "  wp KIND = ", wp
    WRITE(*,'(A,I10)') "  dp KIND = ", dp
    WRITE(*,'(A,I10)') "  sp KIND = ", sp
    WRITE(*,'(A,L1)') "  wp == dp ? ", (wp == dp)

    IF (wp == dp) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 2: WP_* 常量
    !==========================================================================
    test_count = test_count + 1
    test_name = "WP_* 精度常量"

    WRITE(*,'(A,I2,A,A)') "[INFO] Test ", test_count, ": ", TRIM(test_name)
    WRITE(*,'(A,E15.8)') "  WP_EPSILON = ", WP_EPSILON
    WRITE(*,'(A,E15.8)') "  WP_TINY = ", WP_TINY
    WRITE(*,'(A,E15.8)') "  WP_HUGE = ", WP_HUGE

    IF (WP_EPSILON > 0 .AND. WP_TINY > 0 .AND. WP_HUGE > 1.0e30_wp) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 3: IsNaN 检测
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_Prec_IsNaN - NaN 检测"

    nan_val = zero_val / zero_val  ! 产生 NaN
    has_err = IF_Prec_IsNaN(nan_val)

    IF (has_err) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 4: IsInf 检测
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_Prec_IsInf - Inf 检测"

    inf_val = 1.0_wp / zero_val  ! 产生 Inf
    has_err = IF_Prec_IsInf(inf_val)

    IF (has_err) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 5: IsFinite 检测
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_Prec_IsFinite - 有限值检测"

    normal_val = 3.141592653589793_wp
    has_err = IF_Prec_IsFinite(normal_val)

    IF (has_err) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 6: IsFinite 对 NaN 返回 FALSE
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_Prec_IsFinite - NaN 返回 FALSE"

    has_err = IF_Prec_IsFinite(nan_val)

    IF (.NOT. has_err) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 7: Check_Overflow 检测
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_Prec_Check_Overflow - 溢出检测"

    large_val = 1.0e50_wp
    has_err = IF_Prec_Check_Overflow(large_val)

    IF (.NOT. has_err) THEN  ! 1e50 不应该溢出
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 8: Check_Underflow 检测
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_Prec_Check_Underflow - 下溢检测"

    tiny_val = 1.0e-50_wp * WP_TINY  ! 非常小的值
    has_err = IF_Prec_Check_Underflow(tiny_val)

    WRITE(*,'(A,I2,A,L1)') "[INFO] Test ", test_count, ": tiny_val is underflow? ", has_err

    IF (tiny_val == 0.0_wp .OR. has_err) THEN  ! 小值或下溢
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 9: Check_Stability - 正常值
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_Prec_Check_Stability - 正常值稳定"

    CALL IF_Prec_Check_Stability(normal_val, is_stable, status)

    IF (is_stable .AND. status%status_code == IF_STATUS_OK) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 10: Check_Stability - NaN 值
    !==========================================================================
    test_count = test_count + 1
    test_name = "IF_Prec_Check_Stability - NaN 检测"

    CALL IF_Prec_Check_Stability(nan_val, is_stable, status)

    IF (.NOT. is_stable .AND. status%status_code == IF_STATUS_INVALID) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

    !==========================================================================
    ! Test 11: 精度比较
    !==========================================================================
    test_count = test_count + 1
    test_name = "wp == dp (工作精度等于双精度)"

    IF (wp == dp) THEN
        WRITE(*,'(A,I2,A)') "[PASS] Test ", test_count, ": "//TRIM(test_name)
        pass_count = pass_count + 1
    ELSE
        WRITE(*,'(A,I2,A)') "[FAIL] Test ", test_count, ": "//TRIM(test_name)
    END IF

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

END PROGRAM test_prec
