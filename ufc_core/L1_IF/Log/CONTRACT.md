## Log 域级合同卡（L1_IF）

- **层级**：L1_IF
- **域名**：Log / 日志记录与追踪
- **缩写**：IF_Log (`IF_Log_*`)
- **职责**：提供分级日志记录（DEBUG/INFO/WARN/ERROR）、日志轮转、多目标输出（控制台/文件）；支持调试追踪与性能分析。
- **四型配置**：
  - **Desc**：日志级别枚举、日志条目 TYPE。
  - **State**：当前日志缓冲区、文件句柄。
  - **Ctx**：无。
  - **Algo**：日志格式化、轮转策略。
- **核心接口**：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Level | Set_Log_Level, Get_Log_Level | 日志级别管理 |
| Write | Log_Debug, Log_Info, Log_Warn, Log_Error | 分级写入 |
| File | Log_To_File, Log_Rotate | 文件日志管理 |
| Flush | Log_Flush | 缓冲区刷新 |

- **依赖**：Precision（时间戳）、Error（错误码）。
- **热路径**：**否** — 日志为辅助设施。
- **实现锚点**：
  - `IF_Log_Types.f90` — 日志类型定义
  - `IF_Log_Core.f90` — 日志核心逻辑
  - `IF_Log_File.f90` — 文件日志管理

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
| 错误码范围 | `ERR_L1_LOG_xxx` (10400–10499) |
| 严重级 | WARNING: 日志文件轮转失败(降级到控制台); ERROR: 日志系统初始化失败; FATAL: 无 |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |
| 恢复策略 | WARNING：降级到控制台输出; ERROR：静默失败(日志不能阻塞主流程) |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L2_NM/* | S(消费) | 数值方法层写入日志 |
| R2 | L3_MD/* | S(消费) | 模型数据层写入日志 |
| R3 | L4_PH/* | S(消费) | 有限元组件层写入日志 |
| R4 | L5_RT/* | S(消费) | 运行时层写入日志 |
| R5 | L6_AP/* | S(消费) | 应用层写入日志 |
| R6 | L1_IF/Error | U(USE) | 错误码定义 |
| R7 | L1_IF/IO | T(合同) | 日志文件输出 |
| R8 | L1_IF/Precision | U(USE) | 时间戳精度 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 不得向上依赖 (L2–L6) | 硬 | Code Review | — |
| 日志不得阻塞主计算流程 | 硬 | Code Review | — |
| 日志级别须可运行时切换 | 软 | Code Review | — |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | 日志级别枚举 / 日志条目 TYPE | 日志配置 |
| 2 | State 定义 | 日志缓冲区 / 文件句柄 | 运行时日志状态 |
| 3 | Algo 定义 | 日志格式化 / 轮转策略 | 格式与轮转 |
| 4 | Ctx 定义 | N/A | 无上下文 |
| 5 | Init/Finalize | Log_Init / Log_Finalize | 日志系统生命周期 |
| 6 | Query | Get_Log_Level | 日志级别查询 |
| 7 | Validate | 日志级别有效性 | 内嵌 |
| 8 | Populate | N/A | L1 无 Populate 链 |
| 9 | Bridge | N/A | 最底层无桥接 |
| 10 | WriteBack | N/A | 基础设施不回写 |
| 11 | Parse | N/A | 不涉及关键字解析 |
| 12 | Compute | N/A | 非计算域 |
| 13 | Error | status 参数返回 | 见错误处理 |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 无理论背景——日志基础设施 |
| 逻辑链 | 分级日志(DEBUG/INFO/WARN/ERROR)，全层统一写入接口 |
| 计算链 | 无数值计算——日志为辅助设施 |
| 数据链 | 日志条目 → 缓冲区 → 文件/控制台输出链 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_Log.f90` | `IF_Log` | `IF_Log_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `Info` (TBP,PRV,—); `Warning` (TBP,PRV,—); `Error` (TBP,PRV,—); `Trace` (TBP,PRV,—); `Debug` (TBP,PRV,—); `Fatal` (TBP,PRV,—); `Flush` (TBP,PRV,—); `IF_Log_Domain_Finalize` (SUB,PRV,Finalize); `IF_Log_Domain_Init` (SUB,PRV,Init); `IF_Log_Domain_Info` (SUB,PRV,IO); `IF_Log_Domain_Warning` (SUB,PRV,IO); `IF_Log_Domain_Error` (SUB,PRV,IO); `IF_Log_Domain_Trace` (SUB,PRV,IO); `IF_Log_Domain_Debug` (SUB,PRV,IO); `IF_Log_Domain_Fatal` (SUB,PRV,IO); `IF_Log_Domain_Flush` (SUB,PRV,IO) |
| `IF_Log_Def.f90` | `IF_Log_Def` | — | — |
| `IF_Log_Logger.f90` | `IF_Log_Logger` | `IF_LogConfig`, `IF_Logger` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `SetLevel` (TBP,PRV,—); `Log` (TBP,PRV,—); `Trace` (TBP,PRV,—); `Debug` (TBP,PRV,—); `Info` (TBP,PRV,—); `Warning` (TBP,PRV,—); `Error` (TBP,PRV,—); `Fatal` (TBP,PRV,—); `Flush` (TBP,PRV,—); `GetStats` (TBP,PRV,—); `IF_Logger_Init_Structured` (SUB,PRV,Init); `IF_Logger_Log_Structured` (SUB,PRV,IO); `IF_Logger_Init` (SUB,PRV,Init); `IF_Logger_Finalize` (SUB,PRV,Finalize); `IF_Logger_SetLevel` (SUB,PRV,Mutate); `IF_Logger_Log` (SUB,PRV,IO); `IF_Logger_Trace` (SUB,PRV,IO); `IF_Logger_Debug` (SUB,PRV,IO); `IF_Logger_Info` (SUB,PRV,IO); `IF_Logger_Warning` (SUB,PRV,IO); `IF_Logger_Error` (SUB,PRV,IO); `IF_Logger_Fatal` (SUB,PRV,IO); `IF_Logger_Flush` (SUB,PRV,IO); `IF_Logger_GetStats` (SUB,PRV,Query); `FormatLogEntry` (SUB,PRV,—); `IF_Log_Init` (SUB,PUB,Init); `IF_Log_Trace` (SUB,PUB,IO); `IF_Log_Debug` (SUB,PUB,IO); `IF_Log_Info` (SUB,PUB,IO); `IF_Log_Warning` (SUB,PUB,IO); `IF_Log_Error` (SUB,PUB,IO); `IF_Log_Fatal` (SUB,PUB,IO); `IF_Log_Flush` (SUB,PUB,IO); `IF_Log_GetStats` (SUB,PUB,Query) |
