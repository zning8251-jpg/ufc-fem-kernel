# 第 12 件：Diagnostics (诊断观测与序列化件) 设计规范与模板

> **文档位置**：`UFC/docs/05_Project_Planning/PPLAN/13_高阶组件技术规范_Spec/11_第12件_Diagnostics_诊断与序列化件_设计规范与模板.md`  
> **所属套件**：全景套件 v3.0 第 12 件  
> **目标**：规范内核错误的冒泡传播机制（异常捕获），打通基于四型的序列化存储，以支持断点续算 (Checkpoint/Restart)。

---

## 1. 核心目标与技术红线

### 1.1 核心目标
1. **异常冒泡 (Error Bubbling)**：提供标准错误码体系。当底层计算发散时，将错误状态层层传递回 L5_RT 的总控单元，触发步长折半。
2. **状态快照 (State Checkpointing)**：提供统一的数据序列化网关，能够将整个 `_State` 扁平数组一键导出为 HDF5 或二进制块。

### 1.2 架构红线 (Red Lines)
- **禁止使用 `STOP`**：任何计算层面上（L4/L5）都不允许调用 `STOP` 指令。程序退出只能由最顶级的 `L6_AP` 执行。
- **避免字符串操作**：在热路径中打印报错极其消耗性能，异常冒泡只允许使用 `INTEGER` 类型的 `Status Code` 往上传递。最终的报错翻译由本件套 (`_Diag`) 统一负责映射。

---

## 2. 核心架构时序与机制

1. **[底层计算]**：发生错误（如 Jacobian 为负），返回 `status = 401`。
2. **[层层冒泡]**：`_Core` -> `_Brg` -> `_Proc`，沿途只要 `status /= 0` 就立即 `RETURN`。
3. **[L5 捕获]**：L5 的 `StepDriver` 捕获到非零状态码，调用 `Diag_Dump_Error(status)`，翻译错误信息并输出日志。同时启动状态回滚与重新划分增量步。
4. **[分析步末尾]**：L5 正常收敛后，调用 `Diag_Write_Checkpoint(global_state)` 将当期状态落盘。

---

## 3. 伪代码模板与合同定义

```fortran
!=============================================================================
! MODULE: RT_Diag_API
! 描述: 运行时观测与诊断组件
!=============================================================================
MODULE RT_Diag_API
    ! USE HDF5_LIB 
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: RT_Diag_Check_Status
    PUBLIC :: RT_Diag_Write_Checkpoint
    
    ! 标准异常枚举池
    INTEGER, PARAMETER, PUBLIC :: UFC_SUCCESS = 0
    INTEGER, PARAMETER, PUBLIC :: UFC_ERR_NEGATIVE_JACOBIAN = 401
    INTEGER, PARAMETER, PUBLIC :: UFC_ERR_UMAT_NAN = 402
    INTEGER, PARAMETER, PUBLIC :: UFC_ERR_NONLIN_DIVERGE = 501

CONTAINS

    !> 集中翻译与处理错误码 (冷路径调用)
    SUBROUTINE RT_Diag_Check_Status(status_code, should_abort)
        INTEGER, INTENT(IN)  :: status_code
        LOGICAL, INTENT(OUT) :: should_abort
        
        should_abort = .FALSE.
        
        IF (status_code == UFC_SUCCESS) RETURN
        
        ! 仅在此处调用耗时的文件 IO
        WRITE(6, '("UFC DIAGNOSTICS: ")', ADVANCE='NO')
        SELECT CASE(status_code)
            CASE(UFC_ERR_NEGATIVE_JACOBIAN)
                WRITE(6, *) "FATAL: Negative Jacobian encountered."
                should_abort = .FALSE. ! 可以折半重试
            CASE(UFC_ERR_UMAT_NAN)
                WRITE(6, *) "FATAL: UMAT returned NaN or Infinity."
                should_abort = .TRUE.  ! 数据已脏，不可恢复，通知 L6 退出
            CASE DEFAULT
                WRITE(6, *) "Unknown error code: ", status_code
        END SELECT
    END SUBROUTINE RT_Diag_Check_Status

    !> 利用四型的扁平特性进行零拷贝快照
    SUBROUTINE RT_Diag_Write_Checkpoint(global_state_array)
        REAL*8, INTENT(IN) :: global_state_array(:)
        ! 极简的二进制或 HDF5 写入
        ! 由于去除了对象的嵌套，这只需一行代码的 I/O 带宽
        ! H5Dwrite(...)
    END SUBROUTINE RT_Diag_Write_Checkpoint

END MODULE RT_Diag_API
```

---

## 4. 合同检验点 (Checklist)
1. 搜索整个核心库源码，确认是否干净地消除了 `STOP` 和 `CALL EXIT()` 调用？
2. 检查 `_Core.f90` 是否遵守了仅依靠 `INTEGER` 状态码冒泡的规则，而没有内嵌大段的 `WRITE` 字符串日志。
3. 检查断点文件 (Checkpoint) 是否做到了直接倾倒 (Dump) 一维状态数组，而不是繁琐地用 `DO` 循环去一个个对象解析。