# L1_IF 基础设施层 — 完整域级拆解 v1.0

> **层级**: L1_IF (Infrastructure Layer)  
> **版本**: v1.0 (阶段 2.1 L1 完整拆解)  
> **创建日期**: 2026-04-04  
> **层级职责**: 精度控制、内存管理、错误处理、日志系统、IO、性能监控  
> **域级总数**: 6 个  
> **子域总数**: 0 个（L1 为基础无子域）  
> **功能模块总数**: 22 个  
> **命名前缀**: `IF_` (Infrastructure Foundation)

---

## 📋 L1_IF 层顶层设计

```
L1_IF (基础设施层)
│
├─ 精度控制 (Precision) ← 全局精度常数定义
├─ 内存管理 (Memory) ← 内存池、分配策略
├─ 错误处理 (Error) ← 错误码、异常机制
├─ 日志系统 (Log) ← 日志记录、诊断输出
├─ 输入输出 (IO) ← 文件 IO、检查点
└─ 性能监控 (Monitor) ← 计时、性能统计
```

---

## 🎯 一、六个域级完整拆解

### 1.1 域级 1: **Base** — 基础类型与工具

**域级职责**: 
- 定义基础类型、工具函数、设备管理
- 精度常数统一定义（单精度、双精度、四精度）
- 全局常数表与工具库

**子域**: 无（基础层）

**功能模块**:
```
L1_IF/Base/
├── IF_Precision_Desc.f90           [四型] Desc: 精度定义 TYPE
│   └─ TYPE :: IF_Precision_Desc
│      REAL(real64), PARAMETER :: wp = 8_8  ! 默认双精度
│      REAL(real64), PARAMETER :: dp = 8_8  ! 双精度
│      REAL(real32), PARAMETER :: sp = 4_4  ! 单精度
│
├── IF_Precision_Ctx.f90            [四型] Ctx: 精度上下文
│   └─ TYPE :: IF_Precision_Ctx
│      INTEGER :: precision_mode    ! 1=sp, 2=dp, 3=quad
│      REAL(wp) :: tolerance        ! 精度容限
│
├── IF_Base_Utility.f90             [四型] —: 基础工具函数
│   ├─ FUNCTION safe_divide(a, b, eps) RESULT(res)
│   ├─ FUNCTION small_value(dim) RESULT(eps)
│   └─ SUBROUTINE assert(condition, message)
│
└── IF_DeviceManager.f90            [四型] —: 设备管理
    ├─ SUBROUTINE init_device()
    ├─ SUBROUTINE check_device_capability()
    └─ FUNCTION get_device_info() RESULT(info)
```

**命名规范**:
- Desc 模块: `IF_*_Desc.f90` — 包含 `TYPE *_Desc` 定义
- Ctx 模块: `IF_*_Ctx.f90` — 包含 `TYPE *_Ctx` 定义
- 其他: `IF_*_Utility.f90` 等，不涉及四型

**关键函数**:
```fortran
! 精度查询接口
FUNCTION get_precision_mode() RESULT(mode)
  INTEGER :: mode  ! 返回当前精度模式
END FUNCTION

! 误差容限自适应
FUNCTION get_tolerance(problem_scale) RESULT(tol)
  REAL(wp), INTENT(IN) :: problem_scale
  REAL(wp) :: tol
  tol = problem_scale * EPSILON(1.0_wp) * 1000  ! 自适应容限
END FUNCTION
```

---

### 1.2 域级 2: **Error** — 错误处理体系

**域级职责**:
- 全局错误码定义（符合 Fortran 标准）
- 错误状态管理与传播
- 异常处理与错误恢复

**子域**: 无

**功能模块**:
```
L1_IF/Error/
├── IF_Error_Desc.f90               [四型] Desc: 错误码定义表
│   ├─ INTEGER, PARAMETER :: IF_ERR_SUCCESS = 0
│   ├─ INTEGER, PARAMETER :: IF_ERR_ALLOC_FAILED = -101
│   ├─ INTEGER, PARAMETER :: IF_ERR_INVALID_INPUT = -201
│   ├─ INTEGER, PARAMETER :: IF_ERR_DIV_BY_ZERO = -301
│   ├─ INTEGER, PARAMETER :: IF_ERR_CONVERGENCE = -401
│   ├─ INTEGER, PARAMETER :: IF_ERR_IO_FAILED = -501
│   └─ ... (共 20+ 个错误码)
│
├── IF_Error_State.f90              [四型] State: 错误状态
│   └─ TYPE :: IF_Error_State
│      INTEGER :: code              ! 错误码
│      CHARACTER(LEN=256) :: message ! 错误消息
│      INTEGER :: line              ! 出现行号
│      CHARACTER(LEN=64) :: file    ! 出现文件
│      INTEGER :: count             ! 错误计数
│
├── IF_Error_Handler.f90            [四型] Algo: 错误处理逻辑
│   ├─ SUBROUTINE set_error(status, code, msg)
│   ├─ SUBROUTINE propagate_error(status_in, status_out)
│   ├─ FUNCTION is_error(status) RESULT(has_error)
│   └─ SUBROUTINE print_error_message(status)
│
└── IF_Error_Ctx.f90                [四型] Ctx: 错误上下文
    └─ TYPE :: IF_Error_Ctx
       TYPE(IF_Error_State), ALLOCATABLE :: error_stack(:)
       INTEGER :: error_count
       LOGICAL :: stop_on_error
```

**错误码映射**:
```
-1xx: Memory/Allocation 相关 (-101, -102, ...)
-2xx: Input Validation 相关 (-201, -202, ...)
-3xx: Numerical 相关 (-301, -302, ...) (Division, Convergence)
-4xx: Algorithm 相关 (-401, -402, ...)
-5xx: IO 相关 (-501, -502, ...)
```

---

### 1.3 域级 3: **IO** — 输入输出系统

**域级职责**:
- 文件读写封装
- 检查点保存/恢复
- ODB 格式处理

**子域**: 无

**功能模块**:
```
L1_IF/IO/
├── IF_IO_Desc.f90                  [四型] Desc: IO 配置
│   └─ TYPE :: IF_IO_Desc
│      CHARACTER(LEN=256) :: input_file
│      CHARACTER(LEN=256) :: output_dir
│      INTEGER :: checkpoint_interval
│      LOGICAL :: use_parallel_io
│
├── IF_IO_State.f90                 [四型] State: IO 状态
│   └─ TYPE :: IF_IO_State
│      LOGICAL :: input_ready
│      LOGICAL :: output_ready
│      INTEGER :: total_io_bytes
│      INTEGER :: last_checkpoint_id
│
├── IF_IO_Reader.f90                [四型] Algo: 读取逻辑
│   ├─ SUBROUTINE read_inp_file(filename, model, status)
│   ├─ FUNCTION parse_keyword_line(line) RESULT(keyword)
│   └─ SUBROUTINE validate_input_format(status)
│
├── IF_IO_Writer.f90                [四型] Algo: 写入逻辑
│   ├─ SUBROUTINE write_odb_frame(frame_data, filename, status)
│   ├─ SUBROUTINE write_checkpoint(model, step_id, status)
│   └─ SUBROUTINE write_diagnostic_log(message, level)
│
└── IF_IO_Ctx.f90                   [四型] Ctx: IO 上下文
    └─ TYPE :: IF_IO_Ctx
       INTEGER :: file_unit_inp = 10
       INTEGER :: file_unit_out = 20
       INTEGER :: file_unit_chk = 30
       LOGICAL :: is_parallel
```

---

### 1.4 域级 4: **Log** — 日志系统

**域级职责**:
- 日志记录与管理
- 诊断输出控制
- 运行时信息收集

**子域**: 无

**功能模块**:
```
L1_IF/Log/
├── IF_Log_Desc.f90                 [四型] Desc: 日志配置
│   └─ TYPE :: IF_Log_Desc
│      INTEGER :: log_level = IF_LOG_INFO  ! 日志级别
│      INTEGER :: max_log_lines = 100000
│      LOGICAL :: enable_file_log
│      CHARACTER(LEN=256) :: log_file
│
├── IF_Log_Algo.f90                 [四型] Algo: 日志记录逻辑
│   ├─ SUBROUTINE log_message(level, message)
│   ├─ SUBROUTINE log_warning(message)
│   ├─ SUBROUTINE log_error(message)
│   ├─ SUBROUTINE log_debug(message)
│   └─ SUBROUTINE flush_log()
│
└── IF_Log_Ctx.f90                  [四型] Ctx: 日志上下文
    ├─ INTEGER, PARAMETER :: IF_LOG_DEBUG = 1
    ├─ INTEGER, PARAMETER :: IF_LOG_INFO = 2
    ├─ INTEGER, PARAMETER :: IF_LOG_WARNING = 3
    ├─ INTEGER, PARAMETER :: IF_LOG_ERROR = 4
    └─ TYPE :: IF_Log_Ctx
       INTEGER :: message_count
       INTEGER :: warning_count
       INTEGER :: error_count
```

---

### 1.5 域级 5: **Memory** — 内存管理体系

**域级职责**:
- 内存池管理
- 动态分配策略
- 内存泄漏检测

**子域**: 无

**功能模块**:
```
L1_IF/Memory/
├── IF_Mem_Desc.f90                 [四型] Desc: 内存池配置
│   └─ TYPE :: IF_Mem_Desc
│      INTEGER(i8) :: pool_size = 1_i8 * 1024_i8**3  ! 1 GB
│      INTEGER :: num_pools = 10
│      LOGICAL :: track_allocation
│
├── IF_Mem_Allocator.f90            [四型] Algo: 分配策略
│   ├─ SUBROUTINE allocate_array_1d(array, n, status)
│   ├─ SUBROUTINE allocate_array_2d(array, n, m, status)
│   ├─ SUBROUTINE deallocate_array(array, status)
│   └─ SUBROUTINE compact_memory()
│
└── IF_Mem_Ctx.f90                  [四型] Ctx: 内存上下文
    └─ TYPE :: IF_Mem_Ctx
       INTEGER(i8) :: used_memory
       INTEGER(i8) :: peak_memory
       INTEGER :: allocation_count
       LOGICAL :: memory_warning
```

---

### 1.6 域级 6: **Monitor** — 性能监控系统

**域级职责**:
- 计时与性能统计
- 运行时诊断
- 性能报告生成

**子域**: 无

**功能模块**:
```
L1_IF/Monitor/
├── IF_Mon_Desc.f90                 [四型] Desc: 监控指标定义
│   └─ TYPE :: IF_Mon_Desc
│      LOGICAL :: enable_timer
│      LOGICAL :: enable_counter
│      INTEGER :: num_timers = 100
│
├── IF_Mon_State.f90                [四型] State: 监控状态
│   └─ TYPE :: IF_Mon_State
│      REAL(wp) :: total_wall_time
│      REAL(wp) :: total_cpu_time
│      INTEGER :: iteration_count
│      REAL(wp), ALLOCATABLE :: timer_results(:)
│
└── IF_Mon_Ctx.f90                  [四型] Ctx: 监控上下文
    ├─ SUBROUTINE start_timer(timer_id)
    ├─ SUBROUTINE stop_timer(timer_id)
    ├─ FUNCTION get_elapsed_time(timer_id) RESULT(elapsed)
    ├─ SUBROUTINE print_performance_report()
    └─ TYPE :: IF_Mon_Ctx
       REAL(wp) :: start_time
       REAL(wp) :: end_time
       INTEGER :: call_count
```

---

## 📊 二、L1_IF 层模块统计表

| 序号 | 域级 | 模块数 | 功能 | 四型覆盖 | 优先级 |
|------|------|--------|------|---------|--------|
| 1 | Base | 4 | 基础类型、精度、工具 | Desc+Ctx | ⭐⭐ |
| 2 | Error | 4 | 错误码、异常处理 | Desc+State+Algo+Ctx | ⭐⭐⭐ |
| 3 | IO | 5 | 文件 IO、检查点 | Desc+State+Algo+Ctx | ⭐⭐ |
| 4 | Log | 3 | 日志、诊断 | Desc+Algo+Ctx | ⭐⭐ |
| 5 | Memory | 3 | 内存管理 | Desc+Algo+Ctx | ⭐⭐ |
| 6 | Monitor | 3 | 性能监控 | Desc+State+Ctx | ⭐⭐ |
| **合计** | | **22** | | | |

---

## 🔗 三、命名规范与接口契约

### 3.1 命名规范总结

**层级前缀**: `IF_` (不可省略)

**域级前缀**:
- Base → IF_Base_*
- Error → IF_Error_*
- IO → IF_IO_*
- Log → IF_Log_*
- Memory → IF_Mem_*
- Monitor → IF_Mon_*

**四型后缀**:
- Desc 定义: `IF_*_Desc.f90` → `TYPE IF_*_Desc`
- State 定义: `IF_*_State.f90` → `TYPE IF_*_State`
- Algo 实现: `IF_*_Algo.f90` 或 `IF_*_*.f90` → 子程序集
- Ctx 上下文: `IF_*_Ctx.f90` → `TYPE IF_*_Ctx`

**示例**:
```
✓ IF_Error_Desc.f90 (正确)
✓ IF_Error_State.f90 (正确)
✓ IF_Error_Handler.f90 (正确，Algo 实现)
✓ IF_Error_Ctx.f90 (正确)

✗ Error_Desc.f90 (缺层级前缀)
✗ IF_ErrorDesc.f90 (缺下划线分隔)
✗ IF_Error_Def.f90 (后缀不规范)
```

### 3.2 跨层接口约束

**L1_IF 向上提供接口**:
- 所有上层 (L2-L6) 必须 USE L1_IF 的基础模块
- 错误状态必须通过 `IF_Error_State` 类型传播
- 日志输出必须通过 `IF_Log_*` 接口

**L1_IF 向下依赖**:
- 仅依赖 Fortran 2003 标准库
- 不引入外部库

---

## 📝 四、使用指南与最佳实践

### 4.1 每个域级的使用场景

**Base 域** — 在程序入口初始化
```fortran
USE IF_Precision_Desc, ONLY: wp
USE IF_Precision_Ctx, ONLY: IF_Precision_Ctx
...
```

**Error 域** — 所有子程序必须返回状态
```fortran
TYPE(IF_Error_State) :: status
CALL some_operation(status)
IF (is_error(status)) THEN
  CALL print_error_message(status)
  RETURN
END IF
```

**IO 域** — 文件操作统一接口
```fortran
CALL read_inp_file('model.inp', model, status)
CALL write_odb_frame(frame, 'output.odb', status)
```

**Log 域** — 调试与诊断信息
```fortran
CALL log_debug('Entering subroutine XYZ')
CALL log_warning('Tolerance check failed')
```

**Memory 域** — 动态数组管理
```fortran
REAL(wp), ALLOCATABLE :: array(:,:)
CALL allocate_array_2d(array, n, m, status)
! ... 使用 array ...
CALL deallocate_array(array, status)
```

**Monitor 域** — 性能统计
```fortran
CALL start_timer(1)
! ... 计算密集操作 ...
CALL stop_timer(1)
CALL print_performance_report()
```

### 4.2 常见错误与规避

| 错误 | 原因 | 规避 |
|------|------|------|
| 忘记检查错误状态 | 状态传播中断 | 每次调用后检查 `is_error(status)` |
| 内存泄漏 | 未调用 deallocate | 配对使用 `allocate_array_*` 和 `deallocate_array` |
| 日志信息丢失 | 未 flush | 定期调用 `flush_log()` |
| 精度不一致 | 混合精度使用 | 全局统一使用 `wp` (L1_Precision_Desc 中定义) |

---

## 🎯 五、后续阶段接入点

**L1_IF 完成后**，上层模块应：

1. ✅ **L2_NM** — 导入 L1_IF_Base, L1_IF_Error，实现数值算法
2. ✅ **L3_MD** — 导入 L1_IF_Error, L1_IF_Log，实现模型定义
3. ✅ **L4_PH** — 导入所有 L1_IF 模块，实现物理计算
4. ✅ **L5_RT** — 导入所有 L1_IF 模块，实现运行时调度
5. ✅ **L6_AP** — 导入 L1_IF_IO, L1_IF_Log，实现应用接口

---

## ✅ 交付清单

| 项目 | 状态 | 说明 |
|------|------|------|
| 6 个域级完整拆解 | ✅ | Base/Error/IO/Log/Memory/Monitor |
| 22 个功能模块清单 | ✅ | 含四型规范与函数签名 |
| 命名规范文档 | ✅ | 层前缀 + 域前缀 + 四型后缀 |
| 接口契约 | ✅ | 跨层约束与依赖定义 |
| 使用指南 | ✅ | 每域级的代码示例 |

---

**最后更新**: 2026-04-04  
**下一步**: 阶段 2.2 — L2_NM 数值算法层完整拆解
