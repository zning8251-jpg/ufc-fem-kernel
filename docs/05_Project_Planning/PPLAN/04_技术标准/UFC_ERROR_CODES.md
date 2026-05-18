# UFC 错误码完整参考

> **版本**: v1.0  
> **创建日期**: 2026-03-06  
> **最后更新**: 2026-03-06  
> **适用范围**: UFC 全栈错误码参考  
> **上级参考**: UFC_架构设计总纲_六层四类四链三步三级两图一体.md（v2.0）

---

## 📋 文档说明

本文档提供 UFC 项目所有错误码的完整参考，包括：

- 错误码分类（按层级、按类型）
- 错误码含义说明
- 错误处理最佳实践
- 错误码扩展指南

**错误码范围分配**:

- L1_IF: 1000-1999
- L2_NM: 2000-2999
- L3_MD: 3000-3999
- L4_PH: 4000-4999
- L5_RT: 5000-5999
- L6_AP: 6000-6999
- 通用错误: 9000-9999

---

## 目录

1. [L1_IF 错误码（1000-1999）](#l1_if-错误码1000-1999)
2. [L2_NM 错误码（2000-2999）](#l2_nm-错误码2000-2999)
3. [L3_MD 错误码（3000-3999）](#l3_md-错误码3000-3999)
4. [L4_PH 错误码（4000-4999）](#l4_ph-错误码4000-4999)
5. [L5_RT 错误码（5000-5999）](#l5_rt-错误码5000-5999)
6. [L6_AP 错误码（6000-6999）](#l6_ap-错误码6000-6999)
7. [通用错误码（9000-9999）](#通用错误码9000-9999)
8. [错误处理最佳实践](#错误处理最佳实践)
9. [错误码扩展指南](#错误码扩展指南)

---

## L1_IF 错误码（1000-1999）

### 1000-1099: 通用基础设施错误


| 错误码  | 常量名                           | 说明      | 严重程度    |
| ---- | ----------------------------- | ------- | ------- |
| 1000 | `STATUS_OK`                   | 成功（无错误） | INFO    |
| 1001 | `STATUS_ERROR`                | 一般错误    | ERROR   |
| 1002 | `STATUS_WARNING`              | 警告      | WARNING |
| 1003 | `UFC_ERR_NOT_INITIALIZED`     | 对象未初始化  | ERROR   |
| 1004 | `UFC_ERR_ALREADY_INITIALIZED` | 对象已初始化  | WARNING |
| 1005 | `UFC_ERR_NULL_PTR`            | 空指针     | ERROR   |
| 1006 | `UFC_ERR_INVALID_ARG`         | 无效参数    | ERROR   |


### 1100-1199: 线程安全错误（P0 优化）


| 错误码  | 常量名                            | 说明       | 严重程度    |
| ---- | ------------------------------ | -------- | ------- |
| 1101 | `UFC_ERR_LOCK_CONTENTION`      | 锁竞争      | WARNING |
| 1102 | `UFC_ERR_THREAD_SAFE_NOT_INIT` | 线程安全未初始化 | ERROR   |


### 1200-1299: 路径安全错误（P0 优化）


| 错误码  | 常量名                           | 说明           | 严重程度  |
| ---- | ----------------------------- | ------------ | ----- |
| 1201 | `UFC_ERR_PATH_TOO_LONG`       | 路径过长（>512字符） | ERROR |
| 1202 | `UFC_ERR_PATH_TOO_DEEP`       | 路径深度超限（>20层） | ERROR |
| 1203 | `UFC_ERR_INVALID_PATH_CHAR`   | 路径包含非法字符     | ERROR |
| 1204 | `UFC_ERR_NULL_CHAR`           | 路径包含空字符      | ERROR |
| 1205 | `UFC_ERR_CONTROL_CHAR`        | 路径包含控制字符     | ERROR |
| 1206 | `UFC_ERR_INVALID_PATH_START`  | 路径必须以"mdb"开头 | ERROR |
| 1207 | `UFC_ERR_UNMATCHED_BRACKET`   | 括号不匹配        | ERROR |
| 1208 | `UFC_ERR_UNMATCHED_QUOTE`     | 引号不匹配        | ERROR |
| 1209 | `UFC_ERR_INVALID_PATH_FORMAT` | 路径格式无效       | ERROR |
| 1210 | `UFC_ERR_EMPTY_PATH`          | 路径为空         | ERROR |


### 1300-1399: 内存边界检查错误（P0 优化）


| 错误码  | 常量名                       | 说明    | 严重程度  |
| ---- | ------------------------- | ----- | ----- |
| 1301 | `UFC_ERR_CORRUPTED_BLOCK` | 内存块损坏 | ERROR |
| 1302 | `UFC_ERR_BUFFER_OVERFLOW` | 缓冲区溢出 | ERROR |
| 1303 | `UFC_ERR_DOUBLE_FREE`     | 双重释放  | ERROR |
| 1304 | `UFC_ERR_INVALID_SIZE`    | 无效大小  | ERROR |


### 1400-1499: SLAB 分配器错误（P0 优化）


| 错误码  | 常量名                      | 说明           | 严重程度  |
| ---- | ------------------------ | ------------ | ----- |
| 1401 | `UFC_ERR_SLAB_EXHAUSTED` | SLAB 耗尽      | ERROR |
| 1402 | `UFC_ERR_SIZE_TOO_LARGE` | 大小超过 SLAB 限制 | ERROR |


### 1500-1599: 路径缓存错误（P1 优化）


| 错误码  | 常量名                   | 说明   | 严重程度    |
| ---- | --------------------- | ---- | ------- |
| 1501 | `UFC_ERR_CACHE_EMPTY` | 缓存为空 | WARNING |


### 1600-1699: NUMA 错误（P1 优化）


| 错误码  | 常量名                         | 说明          | 严重程度  |
| ---- | --------------------------- | ----------- | ----- |
| 1601 | `UFC_ERR_INVALID_NUMA_NODE` | 无效的 NUMA 节点 | ERROR |
| 1602 | `UFC_ERR_NUMA_ALLOC_FAILED` | NUMA 分配失败   | ERROR |


### 1700-1799: 碎片整理错误（P1 优化）


| 错误码  | 常量名                     | 说明     | 严重程度    |
| ---- | ----------------------- | ------ | ------- |
| 1701 | `UFC_ERR_DEFRAG_FAILED` | 碎片整理失败 | WARNING |


### 1800-1899: 内存预取错误（P2 优化）


| 错误码  | 常量名                       | 说明   | 严重程度    |
| ---- | ------------------------- | ---- | ------- |
| 1801 | `UFC_ERR_PREFETCH_FAILED` | 预取失败 | WARNING |


### 1900-1999: 自适应调整错误（P2 优化）


| 错误码  | 常量名                                | 说明      | 严重程度    |
| ---- | ---------------------------------- | ------- | ------- |
| 1901 | `UFC_ERR_ADAPTIVE_ADJUST_FAILED`   | 自适应调整失败 | WARNING |
| 1902 | `UFC_ERR_HOTSPOT_DETECTION_FAILED` | 热点检测失败  | WARNING |


---

## L2_NM 错误码（2000-2999）

### 2000-2099: 线性求解器错误


| 错误码  | 常量名                                   | 说明       | 严重程度    |
| ---- | ------------------------------------- | -------- | ------- |
| 2001 | `NM_ERR_SOLVER_FAILED`                | 求解器失败    | ERROR   |
| 2002 | `NM_ERR_MATRIX_SINGULAR`              | 矩阵奇异     | ERROR   |
| 2003 | `NM_ERR_MATRIX_NOT_POSITIVE_DEFINITE` | 矩阵不正定    | ERROR   |
| 2004 | `NM_ERR_CONVERGENCE_FAILED`           | 收敛失败     | ERROR   |
| 2005 | `NM_ERR_MAX_ITERATIONS`               | 达到最大迭代次数 | WARNING |


### 2100-2199: 时间积分错误


| 错误码  | 常量名                            | 说明     | 严重程度    |
| ---- | ------------------------------ | ------ | ------- |
| 2101 | `NM_ERR_TIME_STEP_TOO_LARGE`   | 时间步长过大 | ERROR   |
| 2102 | `NM_ERR_TIME_STEP_TOO_SMALL`   | 时间步长过小 | WARNING |
| 2103 | `NM_ERR_NUMERICAL_INSTABILITY` | 数值不稳定  | ERROR   |


### 2200-2299: 特征值求解错误


| 错误码  | 常量名                          | 说明      | 严重程度  |
| ---- | ---------------------------- | ------- | ----- |
| 2201 | `NM_ERR_EIGEN_FAILED`        | 特征值求解失败 | ERROR |
| 2202 | `NM_ERR_EIGEN_NOT_CONVERGED` | 特征值未收敛  | ERROR |


---

## L3_MD 错误码（3000-3999）

### 3000-3099: 材料错误


| 错误码  | 常量名                            | 说明          | 严重程度    |
| ---- | ------------------------------ | ----------- | ------- |
| 3001 | `MD_ERR_MATERIAL_NOT_FOUND`    | 材料未找到       | ERROR   |
| 3002 | `MD_ERR_MATERIAL_INVALID`      | 材料参数无效      | ERROR   |
| 3003 | `MD_ERR_MATERIAL_DUPLICATE`    | 材料名称重复      | WARNING |
| 3004 | `MD_ERR_POISSON_RATIO_INVALID` | 泊松比无效（>0.5） | ERROR   |
| 3005 | `MD_ERR_YOUNG_MODULUS_INVALID` | 杨氏模量无效（<=0） | ERROR   |


### 3100-3199: 网格错误


| 错误码  | 常量名                           | 说明     | 严重程度  |
| ---- | ----------------------------- | ------ | ----- |
| 3101 | `MD_ERR_MESH_INVALID`         | 网格无效   | ERROR |
| 3102 | `MD_ERR_MESH_NOT_FOUND`       | 网格未找到  | ERROR |
| 3103 | `MD_ERR_NODE_NOT_FOUND`       | 节点未找到  | ERROR |
| 3104 | `MD_ERR_ELEMENT_NOT_FOUND`    | 单元未找到  | ERROR |
| 3105 | `MD_ERR_CONNECTIVITY_INVALID` | 连接关系无效 | ERROR |


### 3200-3299: 部件错误


| 错误码  | 常量名                     | 说明     | 严重程度    |
| ---- | ----------------------- | ------ | ------- |
| 3201 | `MD_ERR_PART_NOT_FOUND` | 部件未找到  | ERROR   |
| 3202 | `MD_ERR_PART_DUPLICATE` | 部件名称重复 | WARNING |


### 3300-3399: 截面错误


| 错误码  | 常量名                        | 说明     | 严重程度  |
| ---- | -------------------------- | ------ | ----- |
| 3301 | `MD_ERR_SECTION_NOT_FOUND` | 截面未找到  | ERROR |
| 3302 | `MD_ERR_SECTION_INVALID`   | 截面参数无效 | ERROR |


---

## L4_PH 错误码（4000-4999）

### 4000-4099: 单元计算错误


| 错误码  | 常量名                            | 说明         | 严重程度  |
| ---- | ------------------------------ | ---------- | ----- |
| 4001 | `PH_ERR_ELEMENT_TYPE_UNKNOWN`  | 未知单元类型     | ERROR |
| 4002 | `PH_ERR_ELEMENT_DEGENERATE`    | 单元退化       | ERROR |
| 4003 | `PH_ERR_JACOBIAN_NEGATIVE`     | 雅可比矩阵行列式为负 | ERROR |
| 4004 | `PH_ERR_SHAPE_FUNCTION_FAILED` | 形函数计算失败    | ERROR |


### 4100-4199: 材料本构错误


| 错误码  | 常量名                           | 说明     | 严重程度  |
| ---- | ----------------------------- | ------ | ----- |
| 4101 | `PH_ERR_MATERIAL_EVAL_FAILED` | 材料评估失败 | ERROR |
| 4102 | `PH_ERR_STRESS_UPDATE_FAILED` | 应力更新失败 | ERROR |
| 4103 | `PH_ERR_PLASTICITY_FAILED`    | 塑性计算失败 | ERROR |


### 4200-4299: 接触算法错误


| 错误码  | 常量名                               | 说明     | 严重程度    |
| ---- | --------------------------------- | ------ | ------- |
| 4201 | `PH_ERR_CONTACT_DETECTION_FAILED` | 接触检测失败 | ERROR   |
| 4202 | `PH_ERR_CONTACT_PENETRATION`      | 接触穿透   | WARNING |


---

## L5_RT 错误码（5000-5999）

### 5000-5099: 求解器错误


| 错误码  | 常量名                         | 说明    | 严重程度  |
| ---- | --------------------------- | ----- | ----- |
| 5001 | `RT_ERR_SOLVER_FAILED`      | 求解器失败 | ERROR |
| 5002 | `RT_ERR_ASSEMBLY_FAILED`    | 装配失败  | ERROR |
| 5003 | `RT_ERR_CONVERGENCE_FAILED` | 收敛失败  | ERROR |


### 5100-5199: Step 控制错误


| 错误码  | 常量名                       | 说明        | 严重程度  |
| ---- | ------------------------- | --------- | ----- |
| 5101 | `RT_ERR_STEP_NOT_FOUND`   | Step 未找到  | ERROR |
| 5102 | `RT_ERR_STEP_FAILED`      | Step 执行失败 | ERROR |
| 5103 | `RT_ERR_INCREMENT_FAILED` | 增量步失败     | ERROR |
| 5104 | `RT_ERR_ITERATION_FAILED` | 迭代步失败     | ERROR |


### 5200-5299: 状态管理错误


| 错误码  | 常量名                      | 说明    | 严重程度  |
| ---- | ------------------------ | ----- | ----- |
| 5201 | `RT_ERR_STATE_INVALID`   | 状态无效  | ERROR |
| 5202 | `RT_ERR_STATE_NOT_FOUND` | 状态未找到 | ERROR |


---

## L6_AP 错误码（6000-6999）

### 6000-6099: 输入解析错误


| 错误码  | 常量名                       | 说明     | 严重程度  |
| ---- | ------------------------- | ------ | ----- |
| 6001 | `AP_ERR_PARSE_FAILED`     | 解析失败   | ERROR |
| 6002 | `AP_ERR_INVALID_COMMAND`  | 无效命令   | ERROR |
| 6003 | `AP_ERR_FILE_NOT_FOUND`   | 文件未找到  | ERROR |
| 6004 | `AP_ERR_FILE_READ_FAILED` | 文件读取失败 | ERROR |


### 6100-6199: 输出错误


| 错误码  | 常量名                       | 说明       | 严重程度  |
| ---- | ------------------------- | -------- | ----- |
| 6101 | `AP_ERR_OUTPUT_FAILED`    | 输出失败     | ERROR |
| 6102 | `AP_ERR_ODB_WRITE_FAILED` | ODB 写入失败 | ERROR |


### 6200-6299: Job 管理错误


| 错误码  | 常量名                    | 说明       | 严重程度  |
| ---- | ---------------------- | -------- | ----- |
| 6201 | `AP_ERR_JOB_NOT_FOUND` | Job 未找到  | ERROR |
| 6202 | `AP_ERR_JOB_FAILED`    | Job 执行失败 | ERROR |


---

## 通用错误码（9000-9999）

### 9000-9099: 系统错误


| 错误码  | 常量名                         | 说明     | 严重程度  |
| ---- | --------------------------- | ------ | ----- |
| 9001 | `UFC_ERR_OUT_OF_MEMORY`     | 内存不足   | ERROR |
| 9002 | `UFC_ERR_FILE_OPEN_FAILED`  | 文件打开失败 | ERROR |
| 9003 | `UFC_ERR_FILE_WRITE_FAILED` | 文件写入失败 | ERROR |
| 9004 | `UFC_ERR_SYMBOL_NOT_FOUND`  | 符号未找到  | ERROR |


---

## 错误处理最佳实践

### 8.1 错误检查模式

**推荐模式**:

```fortran
SUBROUTINE MySubroutine(input, output, status)
  TYPE(InputType), INTENT(IN) :: input
  TYPE(OutputType), INTENT(OUT) :: output
  TYPE(ErrorStatusType), INTENT(INOUT) :: status
  
  ! 1. 参数验证
  IF (input%value <= 0) THEN
    CALL UFC_Error_Raise(status, UFC_ERR_INVALID_ARG, &
      'Input value must be positive')
    RETURN
  END IF
  
  ! 2. 执行操作
  CALL DoSomething(input, output, status)
  IF (status%status_code /= STATUS_OK) THEN
    RETURN  ! 错误已设置，直接返回
  END IF
  
  ! 3. 结果验证
  IF (.NOT. IsValid(output)) THEN
    CALL UFC_Error_Raise(status, UFC_ERR_INVALID_RESULT, &
      'Output validation failed')
    RETURN
  END IF
END SUBROUTINE
```

### 8.2 错误传播

**原则**: 错误应向上传播，不要吞没错误

```fortran
! 错误：吞没错误
CALL Subroutine1(input, output, status)
IF (status%status_code /= STATUS_OK) THEN
  status%status_code = STATUS_OK  ! ❌ 错误：吞没错误
END IF

! 正确：传播错误
CALL Subroutine1(input, output, status)
IF (status%status_code /= STATUS_OK) THEN
  RETURN  ! ✅ 正确：直接返回，错误向上传播
END IF
```

### 8.3 错误消息格式

**推荐格式**: `"<模块名>: <操作> failed: <原因>"`

```fortran
CALL UFC_Error_Raise(status, MD_ERR_MATERIAL_NOT_FOUND, &
  'MD_Material: Material lookup failed: Material "Steel" not found')
```

---

## 错误码扩展指南

### 9.1 添加新错误码

**步骤**:

1. 确定错误码范围（按层级）
2. 选择未使用的错误码
3. 定义常量名（遵循命名规范）
4. 更新本文档
5. 在代码中使用

**示例**:

```fortran
! 在 IF_Err_Codes.f90 中添加
INTEGER(i4), PARAMETER, PUBLIC :: MD_ERR_NEW_ERROR = 3006

! 在代码中使用
CALL UFC_Error_Raise(status, MD_ERR_NEW_ERROR, &
  'New error message')
```

### 9.2 错误码命名规范

**格式**: `Layer_ERR_<Description>`

**示例**:

- `MD_ERR_MATERIAL_NOT_FOUND` - L3_MD 材料未找到
- `PH_ERR_ELEMENT_DEGENERATE` - L4_PH 单元退化
- `RT_ERR_CONVERGENCE_FAILED` - L5_RT 收敛失败

---

## 附录

### A.1 错误码速查表


| 层级    | 范围        | 主要错误类型         |
| ----- | --------- | -------------- |
| L1_IF | 1000-1999 | 初始化、内存、路径、线程安全 |
| L2_NM | 2000-2999 | 求解器、时间积分、特征值   |
| L3_MD | 3000-3999 | 材料、网格、部件、截面    |
| L4_PH | 4000-4999 | 单元、材料本构、接触     |
| L5_RT | 5000-5999 | 求解器、Step、状态管理  |
| L6_AP | 6000-6999 | 输入解析、输出、Job管理  |
| 通用    | 9000-9999 | 系统级错误          |


### A.2 相关文档

- `UFC_API_REFERENCE.md` - API 参考手册
- `UFC_DEVELOPER_GUIDE.md` - 开发者指南
- `UFC_架构设计总纲_六层四类四链三步三级两图一体.md` - 架构总纲

---

**文档状态**: Draft v1.0  
**最后更新**: 2026-03-06  
**维护者**: UFC 开发团队