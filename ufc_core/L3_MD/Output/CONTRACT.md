# Output 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Output (输出定义与管理)  
**Abbreviation**: Out (`MD_Out_*`, `MD_Output_*`)  
**Version**: v3.1  
**Updated**: 2026-04-30  
**Status**: ✅ ACTIVE (P5 Output 域柱)

### 报告侧：过程算法叙事（stub / archive）

- **入口（根 stub）**：[`Output_Procedure_Algorithm.md`](../../../REPORTS/Output_Procedure_Algorithm.md)；长文：[`archive/Output_Procedure_Algorithm.md`](../../../REPORTS/archive/Output_Procedure_Algorithm.md)。
- **Registry**：[Domain Procedure Registry](../../../docs/03_Domain_Pillars/DomainProcedureRegistry/README.md)（与叙事无机器对账；优先级见该 README）。

---

## 1. 域职责定义

### 核心职责
输出请求的 Desc 真相源：Field/History/Contact/Energy 输出定义、输出变量注册、输出频率控制、输出格式配置、变量注册表管理。

### 职责边界
| 做什么 | 不做什么 |
|--------|----------|
| 定义输出请求（Field/History/Contact/Energy） | 不做物理量实际计算（L4_PH） |
| 输出变量注册与查询 | 不做文件 I/O（L5_RT/Output 负责） |
| 输出频率/格式/目标集合配置 | 不做应力/应变后处理 |
| 步级输出触发判断（IsOutputDue） | 不做可视化/动画渲染 |
| WriteBack 接收 L5 更新（lastWrittenInc/Time/Frames） | 不修改 L3 其他域数据 |
| 统一场输出描述与操作 | 不做求解器调度 |

### SIO / `*_Arg`（本域偏好）
Domain facade 的 GetSummary 等接口已 Arg-wrapped。层间边界与 L5 `_Proc` 仍以全仓库 SIO 硬约束为准。

### 竖切试点说明（2026-04）

以下源码单元已从仓库**移除**（无编译单元 `USE`、或与当前 `MD_Out_Def` / `MD_Out_API` **类型真源不一致**，属死代码/悬空实现）：

- **`MD_Out_Parser.f90`**：曾依赖未在真源中定义的 `MD_Output_Desc`、`OUTPUT_TYPE_*` 等；**关键字解析**以 **`MD_Out_Parse`** + `MD_KW_Mapper` 为唯一接线路径。
- **`MD_Out_Mapper.f90`**：依赖同样的悬空 `MD_Output_Desc`；L3→L4 输出映射在域柱后续波次按合同重接，不保留不可链接副本。
- **`MD_Out_Core.f90`**：引用 `MD_Out_Def` 中**不存在**的 `MD_Output_RegistryDesc` 等；注册与生命周期以 **`MD_Output_Domain`**（`MD_Out_API`）+ **`MD_Out_Mgr`** 为准。

---

## 2. 四类 TYPE 清单

### 四型裁剪决策
- **Desc**: Y — 输出请求描述符（变量列表/频率/格式/目标集合）
- **State**: Y — WriteBack-gated 运行时状态（lastWrittenInc/Time/Frames）
- **Algo**: Y — 默认格式/压缩级别/并行 I/O 配置
- **Ctx**: Y — 输出操作上下文

### 2.1 Desc 类型（不可变模型定义）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_OutputRequest_Desc` | `MD_Out_API` | name, request_id, request_type, variables(32), n_variables, target_set, frequency, time_interval, format, step_ref | Write-Once 输出请求描述符 |
| `MD_Output_Desc` | `MD_Out_Def` | output_name, output_id, output_type, variables(:), num_variables, target_set, frequency | SIO 扩展输出描述符 |
| `MD_OutputRequest_Type` | `MD_Out_Def` | 输出请求类型定义 | 扩展请求类型 |
| `MD_OutputVariable_Type` | `MD_Out_Def` | 输出变量定义 | 变量元数据 |
| `UF_OutputVar` | `MD_Out_Lib` | name, var_id, n_components, category, position | Legacy 输出变量定义 |
| `UF_FieldOutputDef` | `MD_Out_Lib` | name, n_variables, variables(:), frequency, format | Legacy 场输出定义 |
| `UF_HistoryOutputDef` | `MD_Out_Lib` | name, n_variables, variables(:), record_freq | Legacy 历史输出定义 |

### 2.2 State 类型（可变运行时状态）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Output_State` | `MD_Out_API` | lastWrittenInc, lastWrittenTime, totalFrames, step_idx, incr_idx | WriteBack-gated 运行时状态 |
| `UF_HistoryOutputState` | `MD_Out_Lib` | 历史输出记录状态 | Legacy 历史记录 |

### 2.3 Algo 类型（算法配置）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `OutputAlgo` | `MD_Out_API` | default_format, compression_level, parallel_io | 输出算法参数 |
| `MD_Output_Algo` | `MD_Out_Def` | 输出算法扩展 | SIO 扩展算法配置 |

### 2.4 Ctx 类型（调用时上下文）

| TYPE 名称 | 来源模块 | 核心字段 | 说明 |
|-----------|----------|----------|------|
| `MD_Output_Ctx` | `MD_Out_Def` | 输出操作上下文 | SIO 扩展上下文 |
| `UF_OutputManager` | `MD_Out_Lib` | field_outputs(:), history_outputs(:), n_field/n_history | Legacy 输出管理器（Ctx 类） |

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|---------|-----------|------|
| `MD_Out_API.f90` | `MD_Out_API` | Domain facade | MD_Output_Domain: Init/Finalize/AddRequest/GetRequest/GetRequestsForStep/IsOutputDue/WriteBack/GetSummary | **AUTHORITY** |
| `MD_Out_Def.f90` | `MD_Out_Def` | `_Def` | SIO 四型定义 (Desc/State/Algo/Ctx) + OutputRequest/Variable 类型 | ACTIVE |
| `MD_Out_Mgr.f90` | `MD_OutMgr` | `_Mgr` | MD_Out_Mgr_RegisterRequest/GetStats/GetRequestsForStep | ACTIVE |
| `MD_Out_Lib.f90` | `MD_OutLib` | `_Lib` | Legacy 输出定义：field_init/add_variable/set_frequency/should_output; history_def_init/state_init/record_point; outmgr_init/add_field/add_history | ACTIVE |
| `MD_Out_Parse.f90` | `MD_Out_Parse` | `_Parse` | Parse_OUTPUT_FILTER/FORMAT/FREQUENCY/REQUEST_Keyword（**KW 路径接入口**） | ACTIVE |
| `MD_Out_Sync.f90` | `MD_Out_Sync` | `_Sync` | Legacy 同步 | ACTIVE |
| `MD_Out_VarReg.f90` | `MD_Out_VarReg` | `_VarReg` | 变量注册表 | ACTIVE |
| `MD_Out_UniFld.f90` | `MD_Out_UniFld` | — | 统一场输出描述（5004 行） | ACTIVE |
| `MD_Out_UniFldOps.f90` | `MD_Out_UniFldOps` | `_Ops` | 统一场输出操作 | ACTIVE |
| `MD_Out_FieldExport.f90` | `MD_Out_FieldExport` | — | 场数据导出 | ACTIVE |
| `MD_Out_ReportPlot.f90` | `MD_Out_ReportPlot` | — | Parse_ANIMATION/EXPORT/PLOT/POST_PROCESSING/REPORT_Keyword | ACTIVE |
| `MD_OutDP_Brg.f90` | `MD_OutDP_Brg` | `_Brg` | 数据平台桥接（骨架） | SKELETON |

---

## 4. 对外接口（公开 API）

### 域容器 (`MD_Output_Domain` TBP，`MD_Out_API`)
| 接口 | 功能 | 参数 |
|------|------|------|
| `Init` / `MD_Output_Domain_Init` | 域初始化 | capacity, status |
| `Finalize` / `MD_Output_Domain_Finalize` | 域释放 | status |
| `AddRequest` / `MD_Output_Domain_AddRequest` | 添加输出请求 | MD_OutputRequest_Desc, status |
| `GetRequest` / `MD_Output_Domain_GetRequest` | 按索引获取请求 | idx, desc, status |
| `GetRequestsForStep` / `MD_Output_Domain_GetRequestsForStep` | 按 Step 获取请求 | step_idx, requests, status |
| `IsOutputDue` / `MD_Output_Domain_IsOutputDue` | 增量步输出触发检查 | inc, time, due |
| `WriteBack` / `MD_Output_WriteBack` | 接收 L5 写回 | inc, time, frames, status |
| `GetSummary` | 获取域摘要 | summary_arg |

### Manager 接口
| 接口 | 功能 |
|------|------|
| `MD_Out_Mgr_RegisterRequest` | 注册请求并更新 Step 索引 |
| `MD_Out_Mgr_GetStats` | 获取输出统计 |
| `MD_Out_Mgr_GetRequestsForStep` | 按 Step 获取请求 |

---

## 5. 跨层数据流

```
INP (*OUTPUT/*FIELD OUTPUT/*HISTORY OUTPUT/*NODE OUTPUT/*ELEMENT OUTPUT)
  → L6_AP / MD_KW_Mapper (map_output/map_output_request/map_output_frequency)
  → MD_Out_Mgr::RegisterRequest → MD_Output_Domain::AddRequest (L3 冷存储)
  → PH_L4_Populate_Output (L4 输出框架, 待补)
  → RT_Output_* (L5 实际文件 I/O)
  → MD_WB_Output (L5→L3 WriteBack: lastWrittenInc/Time/Frames)
```

### 常量定义
| 类别 | 常量 | 说明 |
|------|------|------|
| 输出请求类型 | `OUT_FIELD=1`, `OUT_HISTORY=2`, `OUT_CONTACT=3`, `OUT_ENERGY=4` | 输出请求分类 |
| 输出格式 | `FMT_ODB=1`, `FMT_VTK=2`, `FMT_HDF5=3`, `FMT_CSV=4` | 输出文件格式 |
| 输出位置 | `POS_INTEGRATION_POINT=1`, `POS_CENTROID=2`, `POS_NODE=3`, `POS_ELEMENT=4`, `POS_SECTION_POINT=5` | 变量输出位置 |
| 变量分类 | `VAR_NODAL=1`, `VAR_ELEMENT=2`, `VAR_CONTACT=3`, `VAR_ENERGY=4` | 输出变量类别 |

### 支持的输出变量（32 种）
`U`, `RF`, `S`, `E`, `PE`, `PEEQ`, `MISES`, `PRESSURE`, `TEMP`, `DAMAGE`, `SDV`, `CSTRESS`, `CSTRAIN`, `ALLSE`, `ALLWK`, `ELASE`, `CFORCE`, `CNORMAL`, `CSHEAR`, `CGAP`, `V`, `A`, `COORD`, `NFORC`, `CENT`, `TIME`, `STEP`, `DTIME`, `NLGEOM`, `HFLUX`, `HFILM`, `HRAD`

### WriteBack 白名单
- `output_state%lastWrittenInc`
- `output_state%lastWrittenTime`
- `output_state%totalFrames`

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/KeyWord | T(合同) | *OUTPUT/*FIELD OUTPUT/*HISTORY OUTPUT 解析写入 |
| R2 | L3_MD/Analysis/Step | T(合同) | Step 引用输出请求 ID |
| R3 | L3_MD/WriteBack | B(桥接) | MD_WB_Output 写回运行时状态 |
| R4 | L3_MD/Field | T(合同) | Field 输出请求引用场变量 |
| R5 | L4_PH (经 Populate) | B(桥接) | 输出框架注入 L4（待补） |
| R6 | L5_RT/Output | B(桥接) | RT_Output_* 实际文件 I/O |
| R7 | L6_AP/Input | E(外部) | AP_Inp_* 解析输出命令 |
| R8 | L1_IF/Error | U(USE) | 错误码定义 |

### 四链说明

| 链 | 映射说明 |
|---|----------|
| **理论链** | 输出变量定义→请求描述→频率/格式控制→文件写入 |
| **逻辑链** | KeyWord→Output Desc→AddRequest→Step 绑定→L5 Write→WriteBack |
| **计算链** | L3 无计算；输出数据由 L4/L5 提供 |
| **数据链** | INP→MD_OutputRequest_Desc(冷)→L5 RT_Output(热)→WriteBack→Output State |

---

## 7. 验收标准

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Output Desc 为 Write-Once | 硬 | Code Review | — |
| 禁止在本域做物理量计算 | 硬 | Code Review | — |
| Output State 仅通过 WriteBack 白名单路径更新 | 硬 | WriteBack 网关校验 | — |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 输出变量名须在 SUPPORTED_VARIABLES 列表中 | 软 | Validate | — |
| 新增输出变量须更新变量注册表 | 软 | Code Review | — |

---

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v3.0 | 2026-04-28 | 新建标准化 7 章节格式 |
