# 推演卡综合：L6_AP — 应用层

> 推演引擎 v1.0 | 2026-04-26 | 8 域全覆盖
>
> L6 特征：最外层应用入口，Phase 集中在 Config/Step，面向用户的读入/作业/输出。

---

## Config

**域**：L6_AP / Config | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：命令行解析、运行时参数管理（int/real/string 键值对）

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `AP_Config_Core_Init` | Config | Init | O(1) |
| `AP_Config_Core_Finalize` | Config | Init(Fin) | O(1) |
| `AP_Config_Set_Int` | Config | Access(Set) | O(1) |
| `AP_Config_Set_Real` | Config | Access(Set) | O(1) |
| `AP_Config_Set_String` | Config | Access(Set) | O(1) |
| `AP_Config_Get_Int` | (any) | Access(Get) | O(1) |
| `AP_Config_Get_Real` | (any) | Access(Get) | O(1) |
| `AP_Config_Get_String` | (any) | Access(Get) | O(1) |
| `AP_Config_Parse_CommandLine` | Config | Compute | O(n_args) |
| `AP_Config_Print` | (any) | Access(Log) | O(n_entries) |

---

## Input

**域**：L6_AP / Input | **域类型**：数据域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(Y)

**核心意图**：INP 文件读取与关键字处理

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `AP_Input_Core_Init` | Config | Init | O(1) |
| `AP_Input_Core_Finalize` | Config | Init(Fin) | O(1) |
| `AP_Input_Read_File` | Config | Bridge(Populate) | O(n_lines) |
| `AP_Input_Process_Keywords` | Config | Compute | O(n_kw) |
| `AP_Input_Validate` | Config | Validate | O(n_kw) |
| `AP_Input_Get_Line_Count` | (any) | Access(Get) | O(1) |
| `AP_Input_Get_Error_Count` | (any) | Access(Get) | O(1) |

**子域**：`Command/`（AP_InpCmd* 命令处理）、`Parser/`（AP_Parser* 解析引擎）、`Script/`（AP_Script* 脚本支持）

---

## Job

**域**：L6_AP / Job | **域类型**：编排域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(Y)

**核心意图**：作业创建/运行/状态管理——最高层编排入口

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `AP_Job_Core_Init` | Config | Init | O(1) |
| `AP_Job_Core_Finalize` | Config | Init(Fin) | O(1) |
| `AP_Job_Create` | Config | Init | O(1) |
| `AP_Job_Run` | Step | Control(Loop) | O(n_steps) |
| `AP_Job_Get_Status` | (any) | Access(Get) | O(1) |
| `AP_Job_Abort` | (any) | Control(End) | O(1) |
| `AP_Job_Summary` | (any) | Access(Log) | O(1) |

---

## Output

**域**：L6_AP / Output | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：后处理输出——报告、VTK 可视化、数据分析

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `AP_Output_Core_Init` | Config | Init | O(1) |
| `AP_Output_Core_Finalize` | Config | Init(Fin) | O(1) |
| `AP_Output_Write_Report` | Step | Bridge(WriteBack) | O(n_data) |
| `AP_Output_Write_Summary_Table` | Step | Bridge(WriteBack) | O(n_rows) |
| `AP_Output_Write_VTK_Header` | Step | Bridge(WriteBack) | O(1) |
| `AP_Output_Write_VTK_Nodes` | Step | Bridge(WriteBack) | O(n_nodes) |
| `AP_Output_Write_VTK_Cells` | Step | Bridge(WriteBack) | O(n_elem) |
| `AP_Output_Write_VTK_Point_Vector` | Step | Bridge(WriteBack) | O(n_nodes) |
| `AP_Output_Write_VTK_Point_Scalar` | Step | Bridge(WriteBack) | O(n_nodes) |
| `AP_Output_Write_VTK_Full` | Step | Control(Loop) | O(n_nodes+n_elem) |

---

## Registry

**域**：L6_AP / Registry | **域类型**：数据域 | **四型**：Desc(Y) State(Y) Algo(N) Ctx(Y)

**核心意图**：应用级单元/材料模型注册表（面向用户的注册与查询）

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `AP_Registry_Core_Init` | Config | Init | O(1) |
| `AP_Registry_Core_Finalize` | Config | Init(Fin) | O(1) |
| `AP_Registry_Register_Element` | Config | Access(Add) | O(1) |
| `AP_Registry_Register_Material` | Config | Access(Add) | O(1) |
| `AP_Registry_Lookup_Element` | (any) | Access(Find) | O(n) |
| `AP_Registry_Lookup_Material` | (any) | Access(Find) | O(n) |
| `AP_Registry_Get_Count` | (any) | Access(Get) | O(1) |
| `AP_Registry_Print` | (any) | Access(Log) | O(n) |

---

## Solver

**域**：L6_AP / Solver | **域类型**：编排域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：应用级求解器配置与步驱动入口

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `AP_Solver_Core_Init` | Config | Init | O(1) |
| `AP_Solver_Core_Finalize` | Config | Init(Fin) | O(1) |
| `AP_Solver_Configure` | Config | Access(Set) | O(1) |
| `AP_Solver_Get_Type` | (any) | Access(Get) | O(1) |
| `AP_Solver_Run_Step` | Step | Control(Loop) | O(1) |
| `AP_Solver_Run_All_Steps` | Step | Control(Loop) | O(n_steps) |

---

## UI

**域**：L6_AP / UI | **域类型**：观测域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(N)

**核心意图**：用户界面输出——Banner、进度、节标题、警告/错误

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `AP_UI_Core_Init` | Config | Init | O(1) |
| `AP_UI_Core_Finalize` | Config | Init(Fin) | O(1) |
| `AP_UI_Print_Banner` | Config | Access(Log) | O(1) |
| `AP_UI_Print_Progress` | Step | Access(Log) | O(1) |
| `AP_UI_Print_Section` | (any) | Access(Log) | O(1) |
| `AP_UI_Print_Warning` | (any) | Access(Log) | O(1) |
| `AP_UI_Print_Error` | (any) | Access(Log) | O(1) |
| `AP_UI_Print_Done` | Config | Access(Log) | O(1) |

---

## Bridge

**域**：L6_AP / Bridge | **域类型**：桥接域 | 无 `*_Core.f90`

**核心意图**：L6↔L3/L4/L5 跨层桥接

| 子模块 | 方向 | 说明 |
|--------|------|------|
| `AP_BrgL3` | L6→L3 | 应用层→模型层数据传递 |
| `AP_BrgL4` | L6→L4 | 应用层→物理层配置 |
| `AP_BrgL5` | L6→L5 | 应用层→运行时编排 |
| `AP_Mat_Brg` | L6→L3/L4 | 材料注册桥接 |

**Phase**：Config | **Verb**：Bridge(Populate)
