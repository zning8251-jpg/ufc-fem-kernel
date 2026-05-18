# UFC 跨层错误传播协议

## 1. 概述

本协议定义 UFC 六层架构中错误的生成、传播、包装和拦截规则。

**核心原则：**
- 每个 SUBROUTINE 通过 `TYPE(ErrorStatusType), INTENT(OUT) :: status` 返回错误状态
- 错误沿调用链**向上**传播：`L4 → L5 → L6`（被调用方 → 调用方）
- 错误**严重度只升不降**（escalation-only）
- 每个层级边界处有**门禁检查**（Harness Gate）

## 2. 错误码分区

| 层 | 前缀 | 码段 | 示例 |
|----|------|------|------|
| L1_IF (基础设施) | `IF_ERR_IF_` | 1000–1999 | 内存分配、文件 I/O |
| L1_IF (数学) | `IF_ERROR_CODE_MATH_` | 2000–2999 | 奇异矩阵、收敛失败 |
| L2_NM (数值方法) | `IF_ERR_NM_` | 3000–3999 | 求解器发散、时间步无效 |
| L3_MD (模型数据) | `IF_ERR_MD_` | 4000–4999 | 材料未找到、网格无效 |
| L4_PH (物理组件) | `IF_ERR_PH_` | 5000–5999 | 本构更新失败、接触不收敛 |
| L5_RT (运行时) | `IF_ERR_RT_` | 6000–6999 | 增量步失败、装配失败 |
| L6_AP (应用层) | `IF_ERR_AP_` | 7000–7999 | 输入解析错误、许可证错误 |

**已定义的错误码**参见 `IF_Err_Reg.f90`。新增错误码须通过 `UFC_Register_Error_Code` 注册。

## 3. 严重度等级

| 等级 | 值 | 含义 | 门禁行为 |
|------|---|------|---------|
| `INFO` | 0 | 信息性日志 | 继续 |
| `WARNING` | 1 | 潜在问题，可继续 | 继续 + 记录警告 |
| `ERROR` | 2 | 操作失败，可能可恢复 | 按门禁阈值决定 |
| `CRITICAL` | 3 | 严重错误，不可靠地继续 | 多数门禁 → 停止 |
| `FATAL` | 4 | 不可恢复，必须终止 | 所有门禁 → 停止 |

## 4. 传播路径

### 4.1 典型调用链

```
L6_AP (Job Manager)
  └─ L5_RT (StepDriver)
       └─ L5_RT (Solver / Newton iteration)
            └─ L5_RT (Assembly)
                 ├─ L4_PH (Element Compute)  ──── 本构 ──── L4_PH (Material)
                 ├─ L4_PH (Contact)
                 └─ L4_PH (LoadBC)
                      └─ L2_NM (Linear Solver)
                           └─ L1_IF (Memory/IO)
```

### 4.2 传播规则

#### 规则 P-1: 逐层传播（Propagate）

同层或相邻层内的调用使用 `UFC_Err_Propagate`：

```fortran
CALL sub_step(args, local_status)
IF (local_status%status_code /= IF_STATUS_OK) THEN
  CALL UFC_Err_Propagate(local_status, status, "My_Procedure")
  RETURN
END IF
```

`UFC_Err_Propagate` 的行为：
1. 复制所有错误字段
2. 将调用方名称追加到 `source` 链：`"Caller <- Callee <- Origin"`
3. 严重度只升不降
4. `error_count` 递增

#### 规则 P-2: 跨层包装（Wrap）

在层级边界处使用 `UFC_Err_Wrap` 将底层错误码重新编码为本层码段：

```fortran
CALL PH_Element_Compute(elem_ctx, ph_status)
IF (ph_status%status_code /= IF_STATUS_OK) THEN
  CALL UFC_Err_Wrap(ph_status, status, &
       IF_ERR_RT_INCREMENT_FAILED, "RT_Asm_Compute", &
       "element compute failed at elem_id=" // TRIM(id_str))
  RETURN
END IF
```

`UFC_Err_Wrap` 的行为：
1. 用新的码段替换 `status_code`
2. 保留原始消息并追加包装上下文
3. `source` 链使用 `<~` 标记包装边界：`"Wrapper <~ Original"`
4. 严重度只升不降

#### 规则 P-3: 严重度升级

| 场景 | 升级规则 |
|------|---------|
| 多次 WARNING 累积 | 可在 Harness 层升级为 ERROR |
| 嵌套错误 | 外层严重度 ≥ 内层严重度 |
| 迭代不收敛 | 首次 WARNING → 多次后升级为 ERROR |

## 5. Harness 门禁

### 5.1 门禁层次

| 门禁 | 位置 | 默认阈值 | 说明 |
|------|------|---------|------|
| Element Gate | L4 → L5 元素计算后 | ERROR (2) | 单元计算失败 |
| Constitutive Gate | L4 Material 返回后 | ERROR (2) | 本构更新失败 |
| Iteration Gate | Newton 迭代内 | ERROR (2) | 非线性不收敛 |
| Increment Gate | 增量步完成后 | ERROR (2) | 增量步失败 |
| Step Gate | 分析步完成后 | CRITICAL (3) | 分析步级错误 |
| Job Gate | 作业级 | FATAL (4) | 仅致命错误停止 |

### 5.2 门禁检查 API

```fortran
USE IF_Err_Chain, ONLY: UFC_Err_Gate_Check, &
                        UFC_ERR_GATE_CONTINUE, UFC_ERR_GATE_WARN, UFC_ERR_GATE_HALT

INTEGER(i4) :: gate_action
gate_action = UFC_Err_Gate_Check(status, IF_ERROR_SEVERITY_ERROR)

SELECT CASE (gate_action)
CASE (UFC_ERR_GATE_CONTINUE)
  ! proceed normally
CASE (UFC_ERR_GATE_WARN)
  CALL log_warn("MyModule", "gate warning: " // TRIM(status%message))
  ! proceed with caution
CASE (UFC_ERR_GATE_HALT)
  CALL log_error("MyModule", "gate HALT: " // TRIM(status%message))
  RETURN
END SELECT
```

### 5.3 门禁在 Newton 迭代中的示例

```fortran
DO iter = 1, max_iter
  CALL RT_Asm_Compute(assembly, iter_status)

  gate_action = UFC_Err_Gate_Check(iter_status, IF_ERROR_SEVERITY_ERROR)
  IF (gate_action == UFC_ERR_GATE_HALT) THEN
    CALL UFC_Err_Wrap(iter_status, status, &
         IF_ERR_RT_ITERATION_NOT_CONVERGED, "RT_Solv_Newton", &
         "halted at iteration " // TRIM(iter_str))
    RETURN
  END IF

  IF (converged) EXIT
END DO
```

## 6. 错误恢复策略

| 策略 | 码 | 适用场景 |
|------|---|---------|
| `NONE` | 0 | 无恢复，立即传播 |
| `RETRY` | 1 | 重试（如减小步长） |
| `SKIP` | 2 | 跳过（如跳过损坏的单元输出） |
| `FALLBACK` | 3 | 回退（如换用弹性预测器） |
| `ABORT` | 4 | 终止（不可恢复） |

恢复策略通过 `ErrorRecoveryHandler`（定义在 `IF_Err_Def.f90`）注册。

## 7. 实现文件清单

| 文件 | 职责 |
|------|------|
| `L1_IF/Error/IF_Err_Def.f90` | ErrorStatusType 及所有常量定义 |
| `L1_IF/Error/IF_Err_Brg.f90` | 核心 API: init/set/clear/check |
| `L1_IF/Error/IF_Err_Reg.f90` | 错误码注册表及分层码段 |
| `L1_IF/Error/IF_Err_Chain.f90` | 跨层传播/包装/门禁 (**新增**) |
| `L1_IF/Error/IF_Err.f90` | 全局错误栈域容器 |

## 8. 各层合同卡须包含的错误相关小节

每个域的 `CONTRACT.md` 应包含：

```markdown
### 错误传播
- 本域使用的错误码: {列出 IF_ERR_XX_* 常量}
- 传播方向: {上游 → 本域 → 下游}
- 门禁阈值: {本域出口的默认 severity 阈值}
- 恢复策略: {NONE | RETRY | SKIP | FALLBACK}
```

## 9. 编码规范

1. **所有公开子程序必须有 `status` 参数**（INTENT(OUT) 或 INTENT(INOUT)）
2. **每个子程序入口调用 `init_error_status(status)`**
3. **调用子步骤后立即检查 `local_status%status_code`**
4. **在层边界使用 `UFC_Err_Wrap`** 而非直接传播
5. **禁止吞掉错误**：不得忽略非 OK 的 `local_status` 而继续执行
6. **禁止降低严重度**：包装或传播时 severity 只升不降
7. **错误消息包含上下文**：函数名、关键参数值、迭代号等
