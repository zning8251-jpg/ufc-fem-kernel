# Logging 域级合同卡 (L5_RT)

**Layer**: L5_RT (运行时协调层)  
**Domain**: Logging (运行时分级日志)  
**Prefix**: `RT_Log_*`  
**Version**: v2.1  
**Created**: 2026-04-26  
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L5_RT 层 Logging 域，运行时分级日志记录与系统监控
- **职责**:
  - 分级日志输出：Debug / Info / Warn / Error / Fatal
  - 统一配置管理：日志级别、输出目标、前缀格式
  - 步/增量上下文关联：日志消息自动关联当前步/增量信息
  - AI 遥测钩子：推理耗时、回退计数、置信度记录（AI 关闭时零开销）
  - 统一管理接口：RT_Log_Unified_Manage / RT_Log_Unified_Cfg

### 非职责
- 不定义输出变量（Output 域负责）
- 不写 ODB/HDF5 文件（L6 AP / Output 域）
- 不包含冗余封装层和未使用的异步模块（已移除）

---

## 2. 四类 TYPE 清单

### 2.1 Desc

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Log_Desc` | `RT_Log_Def` | log_level, log_unit, prefix | 日志配置描述 |
| `RT_LogConfig` | `RT_LogSys` | ... | 日志系统配置 |

### 2.2 State

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Logging_State` | `RT_Log_Def` | active, n_messages, n_warnings, n_errors | 日志统计状态 |

### 2.3 Algo
- **(无独立 Algo)** — 缓冲/轮转策略内嵌于 RT_LogSys 过程

### 2.4 Ctx

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `RT_Log_Ctx` | `RT_Log_Def` | line_buffer, step_id, inc_num | 日志上下文 |
| `RT_Logger` | `RT_LogSys` | ... | 日志记录器实例 |

---

## 3. 功能模块清单

| 文件 | MODULE | 后缀角色 | 核心子程序 | 状态 |
|------|--------|----------|-----------|------|
| `RT_Log_Def.f90` | `RT_Log_Def` | `_Def` (TYPE) | RT_Log_Desc, RT_Logging_State, RT_Log_Ctx | **ACTIVE** |
| `RT_Log_Sys.f90` | `RT_LogSys` | 特化(System) | RT_Log_Init/Debug/Info/Warn/Error/Fatal/Finalize/Unified_Manage/Unified_Cfg + map_output_target/rt_config_to_if_config | **ACTIVE** (金线) |
| `RT_Log_Core.f90` | `RT_Log_Core` | `_Core` | 核心日志实现 | **ACTIVE** |
| `RT_Log_Brg.f90` | `RT_Log_Brg` | `_Brg` (桥接) | L1 IF 桥接 | **ACTIVE** |

*注：RT_Logging、RT_Logging_Domain_Core、RT_Log_Async、RT_Monitor_Brg 已移除*

---

## 4. 对外接口（公开 API）

### 日志记录接口

| 子程序 | 模块 | 说明 |
|--------|------|------|
| `RT_Log_Init` | `RT_LogSys` | 日志系统初始化 |
| `RT_Log_Debug` | `RT_LogSys` | Debug 级别日志 |
| `RT_Log_Info` | `RT_LogSys` | Info 级别日志 |
| `RT_Log_Warn` | `RT_LogSys` | Warning 级别日志 |
| `RT_Log_Error` | `RT_LogSys` | Error 级别日志 |
| `RT_Log_Fatal` | `RT_LogSys` | Fatal 级别日志 |
| `RT_Log_Finalize` | `RT_LogSys` | 日志系统清理 |

### 管理接口

| 子程序 | 模块 | 说明 |
|--------|------|------|
| `RT_Log_Unified_Manage` | `RT_LogSys` | 统一日志管理 |
| `RT_Log_Unified_Cfg` | `RT_LogSys` | 统一日志配置 |

---

## 5. 跨层数据流

### 日志数据流
```
各域 (StepDriver/Solver/Element/...)
  → RT_Log_Info/Warn/Error(message)  ← 日志记录调用
    → RT_LogSys (缓冲/格式化)       ← L5 日志系统
      → L1_IF/IO (IF_IO_API)        ← 底层 I/O
        → stdout / 文件              ← 输出目标
```

### AI 遥测数据流
```
AI 插槽调用
  → inference_time_ms             ← 推理耗时
  → n_fallbacks                   ← 回退计数
  → confidence histogram          ← 置信度直方图
    → RT_Log_Info (仅 AI 开启时)  ← 日志记录
```

### 四链说明

| 链 | 说明 |
|----|------|
| **理论链** | 无自有理论；职责为运行时状态的可观测性 |
| **逻辑链** | 各域 → Logging(RT_Log_System) → L1_IF(IO) → stdout/文件 |
| **计算链** | 无计算；日志写入 O(1) per call，缓冲刷新 O(buf_size) |
| **数据链** | 运行时状态消息(热/冷) → 日志缓冲区 → L1_IF IO 输出 |

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L1_IF/Log | U (基础设施) | 使用 L1 IF_IO_API 作为底层输出 |
| R2 | L5_RT/StepDriver | S (被消费) | StepDriver 调用日志记录步/增量/迭代信息 |
| R3 | L5_RT/Solver | S (被消费) | Solver 调用日志记录收敛/残差信息 |
| R4 | L1_IF/Base/AI | S (被消费) | AI 遥测钩子 |

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 不使用 STOP | **硬** | grep 扫描 | CI |
| 日志子系统不阻塞热路径 | **硬** | 代码审查 | PR |
| ERROR 检查在热路径内为轻量级 | **硬** | 性能测试 | 待建 |
| 日志格式统一 | **软** | 代码审查 | PR |
| AI 遥测零开销（AI 关闭时） | **硬** | 条件编译检查 | CI |

### 错误处理

| 错误码范围 | 错误场景 | 严重级 | 恢复策略 |
|------------|----------|--------|----------|
| ERR_L5_LOGGING_50500 | 日志文件打开失败 | WARNING | 回退到 stdout |
| ERR_L5_LOGGING_50501 | 日志缓冲区溢出 | WARNING | 截断并刷新 |
| ERR_L5_LOGGING_50502 | 无效日志级别 | WARNING | 使用 INFO 级别 |

日志子系统自身错误**不终止分析**，仅降级处理。错误码范围：**50500–50599**。

---

## 7. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | 五级日志 | Debug/Info/Warn/Error/Fatal 均可用 | ✅ 已实现 |
| A2 | 配置管理 | RT_LogConfig 支持级别/目标/前缀配置 | ✅ 已实现 |
| A3 | 初始化/清理 | RT_Log_Init/Finalize | ✅ 已实现 |
| A4 | 统一管理 | Unified_Manage/Unified_Cfg | ✅ 已实现 |
| A5 | L1 桥接 | 通过 IF_IO_API 输出 | ✅ 已实现 |
| A6 | AI 遥测 | 推理耗时/回退/置信度钩子（零开销） | ✅ 已实现 |
| A7 | 不阻塞热路径 | ERROR 检查轻量级 | ✅ 已实现 |
| A8 | 冗余清理 | RT_Logging/Async/Monitor_Brg 已移除 | ✅ 已清理 |
| A9 | 错误降级 | 自身错误不终止分析 | ✅ 已实现 |
| A10 | 单元测试 | 待建 | 待补全 |
