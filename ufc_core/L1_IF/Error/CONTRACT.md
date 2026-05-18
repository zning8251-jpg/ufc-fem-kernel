## Error 域级合同卡（L1_IF）

- **层级**：L1_IF
- **域名**：Error / 错误处理与异常管理
- **缩写**：IF_Error (`IF_Error_*`)
- **职责**：提供统一的错误码定义、错误信息格式化、异常抛出与捕获机制；支持优雅降级与调试追踪。
- **四型配置**：
  - **Desc**：错误码枚举（如 `ERR_SUCCESS`, `ERR_INVALID_INPUT`）。
  - **State**：错误栈、最后错误信息。
  - **Ctx**：无。
  - **Algo**：错误信息格式化、栈回溯。
- **核心接口**：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Codes | eErrorCode | 错误码定义 |
| Handler | Error_Throw, Error_Catch | 异常抛出/捕获 |
| Message | Get_Error_Message | 获取错误描述 |
| Stack | Error_Push_Stack, Error_Print_Stack | 错误栈管理 |

- **依赖**：Precision（字符串处理）、Log（日志记录）。
- **热路径**：**否** — 错误处理属于异常路径。
- **实现锚点**：
  - `IF_Error_Types.f90` — 错误码定义
  - `IF_Error_Handler.f90` — 异常处理核心
  - `IF_Error_Stack.f90` — 错误栈管理

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v1.0  
**最后更新**：2026-03-23  
**状态**：✅ 已补全

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L1_ERROR_xxx` (10200–10299) — 本域定义错误系统自身 |
| 严重级 | WARNING: 错误栈溢出(截断); ERROR: 错误处理机制初始化失败; FATAL: 无 |
| 传播规则 | 经 `ErrorStatusType` 返回；不自行 STOP |
| 恢复策略 | WARNING：日志 + 截断旧栈条目; ERROR：回退至最小日志模式 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L2_NM/* | U(USE) | 数值方法层使用错误码体系 |
| R2 | L3_MD/* | U(USE) | 模型数据层使用错误码体系 |
| R3 | L4_PH/* | U(USE) | 有限元组件层使用错误码体系 |
| R4 | L5_RT/* | U(USE) | 运行时层使用错误码体系 |
| R5 | L6_AP/* | U(USE) | 应用层使用错误码体系 |
| R6 | L1_IF/Precision | U(USE) | 字符串处理精度 |
| R7 | L1_IF/Log | U(USE) | 错误日志输出 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 不得向上依赖 (L2–L6) | 硬 | Code Review | — |
| 错误码须在分配范围内唯一 | 硬 | Harness | H-ERR-02 |
| 错误栈深度须有上限 | 软 | Code Review | — |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | eErrorCode 枚举 | 错误码定义 |
| 2 | State 定义 | 错误栈 / 最后错误信息 | 运行时错误状态 |
| 3 | Algo 定义 | 错误信息格式化 / 栈回溯 | 格式化算法 |
| 4 | Ctx 定义 | N/A | 无上下文 |
| 5 | Init/Finalize | Error_Init / Error_Finalize | 错误系统生命周期 |
| 6 | Query | Get_Error_Message | 错误信息查询 |
| 7 | Validate | 错误码范围校验 | 内嵌 |
| 8 | Populate | N/A | L1 无 Populate 链 |
| 9 | Bridge | N/A | 最底层无桥接 |
| 10 | WriteBack | N/A | 基础设施不回写 |
| 11 | Parse | N/A | 不涉及关键字解析 |
| 12 | Compute | N/A | 非计算域 |
| 13 | Error | ErrorStatusType 自身 | 本域即错误系统 |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 无理论背景——工程基础设施 |
| 逻辑链 | 统一的错误码 + 严重级体系，所有层 USE 此模块传播错误 |
| 计算链 | 无数值计算——错误路径为异常路径 |
| 数据链 | ErrorStatusType 为全栈统一错误传播载体 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_Err.f90` | `IF_Err` | `IF_Error_Stats`, `IF_Error_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `GetStats` (TBP,PRV,—); `IF_Err_Finalize` (SUB,PRV,Finalize); `IF_Err_GetStats` (SUB,PRV,Query); `IF_Err_Init` (SUB,PRV,Init) |
| `IF_Err_Brg.f90` | `IF_Err_Brg` | `LogConfigType` | `init_error_status` (SUB,PUB,—); `error_set` (SUB,PUB,Mutate); `error_clear` (SUB,PUB,Mutate); `error_has_error` (FN,PUB,Query); `err_api_write_log` (SUB,PRV,IO); `log_debug` (SUB,PUB,—); `log_info` (SUB,PUB,—); `log_warn` (SUB,PUB,—); `log_error` (SUB,PUB,—); `log_fatal` (SUB,PUB,—); `set_log_level` (SUB,PUB,IO); `set_console_output` (SUB,PUB,IO); `uf_set_error_status` (SUB,PRV,Mutate); `uf_set_error_log` (SUB,PRV,Mutate); `warn_deprecated` (SUB,PUB,—) |
| `IF_Err_Chain.f90` | `IF_Err_Chain` | `ErrorChainStats` | `UFC_Err_Chain_Init` (SUB,PUB,Init); `UFC_Err_Propagate` (SUB,PUB,—); `UFC_Err_Wrap` (SUB,PUB,—); `UFC_Err_Gate_Check` (FN,PUB,Validate); `UFC_Err_Is_Fatal` (FN,PUB,Query); `UFC_Err_Is_Recoverable` (FN,PUB,Query); `UFC_Err_Get_Layer` (FN,PUB,Query); `UFC_Err_Chain_Summary` (SUB,PUB,IO) |
| `IF_Err_Def.f90` | `IF_Err_Def` | `ErrorStatusType`, `LogEntry`, `LogBuffer`, `LogStatistics`, `LoggerType`, `DebugLoggerType`, `PerfLoggerType`, `DebugScope`, `DebugTrace`, `PerfTimer`, `PerfCounter`, `PerfStatistics`, `GlobalErrorStackType`, `CallStackEntry`, `ErrorContextType` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `RecoveryFunction` (FN,PRV,—); `ErrorContext_Init` (SUB,PRV,Init); `ErrorContext_Finalize` (SUB,PRV,Finalize); `ErrorRecoveryRegistry_Init` (SUB,PRV,Init); `ErrorRecoveryRegistry_Finalize` (SUB,PRV,Finalize) |
| `IF_Err_Reg.f90` | `IF_Err_Reg` | `ErrorCodeEntry` | `Init_ErrorCode_Registry` (SUB,PUB,—); `UFC_Register_Error_Code` (SUB,PUB,—); `UFC_Get_Error_Name` (FN,PUB,Query); `UFC_Is_Error_Code_Valid` (FN,PUB,Query); `Finalize_ErrorCode_Registry` (SUB,PUB,—); `Register_Predefined_Errors` (SUB,PRV,—); `ITOA` (FN,PRV,—); `TO_UPPER` (FN,PRV,—) |
