# 推演卡综合：L1_IF — 基础设施层

> 推演引擎 v1.0 | 2026-04-26 | 8 域全覆盖
>
> L1 特征：所有域均为 Config Phase，Verb 集中在 Init / Access，无 HOT_PATH。

---

## Base

**域**：L1_IF / Base | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：全局初始化、版本查询、分析类型/维度管理、3x3 张量工具

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `IF_Base_Core_Init` | Config | Init | O(1) |
| `IF_Base_Core_Finalize` | Config | Init(Fin) | O(1) |
| `IF_Base_Get_Version` | (any) | Access(Get) | O(1) |
| `IF_Base_Global_Init` | Config | Init | O(1) |
| `IF_Base_Get_NDim` | (any) | Access(Get) | O(1) |
| `IF_Base_Get_Analysis_Type` | (any) | Access(Get) | O(1) |

**子域 Symbol**：编译期 FEM 常量表（应力/应变/刚度 Voigt 索引）— 无运行时过程。
**子域 Parallel**：OpenMP 线程工作空间 — `IF_ThreadWS_*` 定义/桥接。
**子域 AI**：ONNX 推理引擎 — `IF_AI_*` 会话/批量/缓存。

---

## Precision

**域**：L1_IF / Precision | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：`wp`/`i4`/`i8` 精度管理、数值极值/机器精度查询

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `IF_Precision_Core_Init` | Config | Init | O(1) |
| `IF_Precision_Core_Finalize` | Config | Init(Fin) | O(1) |
| `IF_Precision_Real_To_String` | (any) | Compute | O(1) |
| `IF_Precision_Get_WP_Bytes` | (any) | Access(Get) | O(1) |
| `IF_Precision_Is_Double` | (any) | Access(Get) | O(1) |
| `IF_Precision_Machine_Eps` | (any) | Access(Get) | O(1) |
| `IF_Precision_Huge_Val` | (any) | Access(Get) | O(1) |

---

## Registry

**域**：L1_IF / Registry | **域类型**：数据域 | **四型**：Desc(N) State(Y) Algo(N) Ctx(Y)

**核心意图**：字符串键值注册表（模型/治理级注册）

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `IF_Registry_Core_Init` | Config | Init | O(1) |
| `IF_Registry_Core_Finalize` | Config | Init(Fin) | O(1) |
| `IF_Registry_Register` | Config | Access(Add) | O(1) |
| `IF_Registry_Lookup` | (any) | Access(Find) | O(n) |
| `IF_Registry_Contains` | (any) | Access(Find) | O(n) |
| `IF_Registry_Remove` | Config | Access(Remove) | O(n) |
| `IF_Registry_Clear` | Config | Init(Reset) | O(n) |
| `IF_Registry_Get_Count` | (any) | Access(Get) | O(1) |

---

## Monitor

**域**：L1_IF / Monitor | **域类型**：观测域 | **四型**：Desc(N) State(Y) Algo(N) Ctx(Y)

**核心意图**：计时器、计数器、性能报告

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `IF_Monitor_Core_Init` | Config | Init | O(1) |
| `IF_Monitor_Core_Finalize` | Config | Init(Fin) | O(1) |
| `IF_Monitor_Timer_Start` | (any) | Control(Begin) | O(1) |
| `IF_Monitor_Timer_Stop` | (any) | Control(End) | O(1) |
| `IF_Monitor_Counter_Inc` | (any) | Evolve(Update) | O(1) |
| `IF_Monitor_Report` | (any) | Access(Get) | O(n_timers) |
| `IF_Monitor_Reset` | (any) | Init(Reset) | O(n_timers) |

---

## Log

**域**：L1_IF / Log | **域类型**：观测域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(N)

**核心意图**：结构化日志（级别、缓冲、统计）

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `IF_Log_Core_Init` | Config | Init | O(1) |
| `IF_Log_Core_Finalize` | Config | Init(Fin) | O(1) |
| `IF_Log_Set_Level` | Config | Access(Set) | O(1) |
| `IF_Log_Debug` | (any) | Access(Log) | O(1) |
| `IF_Log_Info` | (any) | Access(Log) | O(1) |
| `IF_Log_Warn` | (any) | Access(Log) | O(1) |
| `IF_Log_Error` | (any) | Access(Log) | O(1) |
| `IF_Log_Separator` | (any) | Access(Log) | O(1) |
| `IF_Log_Flush` | (any) | Control(End) | O(buffer) |

---

## IO

**域**：L1_IF / IO | **域类型**：数据域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(Y)

**核心意图**：文件 I/O、解析/写入、检查点/重启

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `IF_IO_Core_Init` | Config | Init | O(1) |
| `IF_IO_Core_Finalize` | Config | Init(Fin) | O(1) |
| `IF_IO_Open` | Config | Init | O(1) |
| `IF_IO_Close` | Config | Init(Fin) | O(1) |
| `IF_IO_Write_Real_Array` | Step | Bridge(WriteBack) | O(n) |
| `IF_IO_Read_Real_Array` | Config | Bridge(Populate) | O(n) |
| `IF_IO_Read_Checkpoint` | Config | Bridge(Populate) | O(n) |
| `IF_IO_File_Exists` | (any) | Access(Find) | O(1) |

---

## Memory

**域**：L1_IF / Memory | **域类型**：数据域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(Y)

**核心意图**：命名内存池、分配跟踪、泄漏检查

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `IF_Memory_Core_Init` | Config | Init | O(1) |
| `IF_Memory_Core_Finalize` | Config | Init(Fin) | O(1) |
| `IF_Memory_Track_Alloc` | (any) | Access(Add) | O(1) |
| `IF_Memory_Track_Dealloc` | (any) | Access(Remove) | O(1) |
| `IF_Memory_Get_Usage` | (any) | Access(Get) | O(1) |
| `IF_Memory_Check_Leaks` | Config | Validate | O(n_allocs) |
| `IF_Memory_Compact` | Config | Compute | O(n_pools) |

---

## Error

**域**：L1_IF / Error | **域类型**：数据域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(N)

**核心意图**：`ErrorStatusType`、错误码、栈/链式传播

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `IF_Error_Core_Init` | Config | Init | O(1) |
| `IF_Error_Core_Finalize` | Config | Init(Fin) | O(1) |
| `IF_Error_Create` | (any) | Init | O(1) |
| `IF_Error_Chain` | (any) | Evolve(Update) | O(1) |
| `IF_Error_Set_Source` | (any) | Access(Set) | O(1) |
| `IF_Error_Get_Message` | (any) | Access(Get) | O(1) |
| `IF_Error_Log` | (any) | Access(Log) | O(1) |
