# Bridge域合同卡 (L6_AP/Bridge)

**Layer**: L6_AP (应用层)  
**Domain**: Bridge (跨层桥接)  
**Version**: v1.0  
**Created**: 2026-04-17  
**Status**: ✅ 新建

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 一、职责边界

### 核心职责
- **定位**: UFC L6_AP层Bridge域,L6_AP→L3/L4/L5跨层桥接
- **职责**: L3模型数据桥接、L4物理结果查询、L5运行时状态查询、类型转换适配器、StepRunner桥接
- **边界**: 仅负责跨层数据传递与类型转换;不执行物理计算/运行时调度
- **依赖**: L3_MD(模型数据), L4_PH(物理计算结果), L5_RT(运行时状态)

### 设计意图
Bridge域作为L6_AP层的"跨层桥接中枢",承担5个核心职责:
1. **L3模型数据桥接**: Re-Export L3_MD所有公开接口,避免L6_AP直接依赖L3_MD模块
2. **L4物理结果查询**: 按elem_id查询物理结果(刚度矩阵/残差/力向量)
3. **L5运行时状态查询**: 作业状态/场变量(u/v/a/T)/求解器配置
4. **类型转换适配器**: MD_Mat_Desc↔UF_MaterialDef双向转换
5. **StepRunner桥接**: 符合UF_Job_StepRunner_Ifc接口,调用RT_RunModel_Ctx执行全作业

---

## 二、文件清单 (3个核心文件)

### 核心文件
| 文件 | 行数 | 职责 |
|------|------|------|
| AP_Brg_L3.f90 | ~354 | L3桥接(Re-Export模式,11个域) |
| AP_Brg_L4.f90 | ~117 | L4桥接(物理结果查询) |
| AP_Brg_L5.f90 | ~347 | L5桥接(运行时状态/StepRunner) |

---

## 三、桥接方向与模式

### L6→L3桥接 (AP_Brg_L3.f90)
- **设计模式**: Re-Export Pattern
- **桥接域**(11个):
  1. **ModelTree**: MD_ModelTree_DFS_Traverse/BFS_Traverse/QueryOptimize/BuildIndex/FindByPath/FindByType
  2. **ModelCtx**: MD_Model_Ctx
  3. **Step**: UF_StepDef/UF_StepManager/StepDesc/StepTree+PROC_*/NLGEOM_*/INTEG_*常量
  4. **Material**: UF_MaterialDef/MD_Mat_Desc/MatDesc/MaterialDesc+弹性/塑性/超弹性/损伤/复合材料Desc+UMAT接口
  5. **Section**: UF_SectionDef/UF_SectionDBType+SECTION_*/SHELL_*/BEAM_*常量
  6. **LoadBC**: LoadDef/BCDef/UF_BCDef/UF_CLoadDef/UF_DLoadDef/UF_BodyForceDef/UF_ThermalLoadDef
  7. **Part**: UF_PartDef/UF_Node/UF_Element
  8. **Assembly**: UF_Assem
  9. **Instance**: UF_Instance+Instance_SetTranslation/SetRotation
  10. **Output**: UF_FieldOutputDef/UF_HistoryOutputDef
  11. **Contact**: FrictionParams/ContactDef/ContactPairDef

- **桥接接口**(3个):
  - `MaterialDesc_Init_Structured_Wrapper`: MD_Mat_Desc→UF_MaterialDef适配器包装
  - `MD_Mat_Desc_To_UF_MaterialDef`: 遗留类型→结构化类型转换
  - `UF_MaterialDef_To_MD_Mat_Desc`: 结构化类型→遗留类型转换

### L6→L4桥接 (AP_Brg_L4.f90)
- **设计模式**: Adapter Pattern
- **公共接口**(5个):
  - `Brg_AP_Get_Physical_Results`: 按elem_id查询物理结果(刚度矩阵/残差/力向量)
  - `Brg_AP_Get_Physical_Results_FromCtx`: 按PH_Elem_Ctx查询物理结果(完整实现)
  - `Brg_AP_Format_Output`: 输出格式化(STUB占位)
  - `Brg_AP_Query_Element_Response`: 按elem_id查询单元响应(STUB占位)
  - `Brg_AP_Query_Element_Response_FromCtx`: 按PH_Elem_Ctx查询单元响应(完整实现)

- **重新导出类型**: PH_Mat_Ctx+PH_Core类型(PH_Field_Type/PH_PhysCfg_Type/PH_FieldMgr_Type等9个控制类型)

- **数据转换**: Ke矩阵二维→一维展开,Re向量直接复制

### L6→L5桥接 (AP_Brg_L5.f90)
- **设计模式**: StepRunner Pattern
- **全局状态**(1个): g_brg_rt_ctx(RT_Drv_Ctx指针,用于StepRunner桥接)

- **求解器配置**(2个):
  - `Brg_AP_Configure_Solver`: 基础接口(STUB占位,委托ToCtx版本)
  - `Brg_AP_Configure_Solver_ToCtx`: 完整实现(解析solver_cfg字符串→设置RT_Sol_Cfg)
    - 分析类型: static→隐式/dynamic→HHT-α/explicit→显式
    - 求解器类型: iterative→RT_SOL_LINSOL_I/direct→RT_SOL_LINSOL_D/auto→RT_SOL_LINSOL_A

- **作业注入**(2个):
  - `Brg_AP_SetJobCtx_InContainer`: 注入JobCtx到L6容器(g_ufc_global%ap_layer%SetJobCtx)
  - `Brg_AP_SetRTDrvCtx`: 存储RT_Drv_Ctx到全局指针(供StepRunner使用)

- **StepRunner桥接**(1个):
  - `Brg_AP_StepRunner_RT`: 符合UF_Job_StepRunner_Ifc接口,stepIndex=1时调用RT_RunModel_Ctx执行全作业
    - 返回AP_JOB_RT_FULL_JOB_DONE表示作业完成
    - 错误码: -1(未初始化ctx/model/solver或stepIndex!=1)

- **状态查询**(3个):
  - `Brg_AP_Get_Job_Status`: 基础接口(STUB占位)
  - `Brg_AP_Get_Job_Status_FromCtx`: 从RT_Drv_Ctx查询作业状态码+消息
  - `Brg_AP_Query_Runtime_State`: 基础接口(STUB占位)
  - `Brg_AP_Query_Runtime_State_FromField`: 从RT_FieldState_Type查询场变量(u/v/a/T)

- **重新导出类型**: RT_Step_Ctx/RT_Sol_Ctx/RT_Drv_Ctx/RT_RunModel_Ctx+UF_RT_JobStatus/UF_Model

---

## 四、四类TYPE映射

| Type种类 | TYPE名称 | 核心职责 | 字段示例 |
|----------|----------|----------|----------|
| **Desc** | 无(仅转发L3 Desc) | Re-Export L3_MD类型 | MD_Mat_Desc/UF_MaterialDef |
| **State** | 无(仅转发L5 State) | Re-Export L5_RT类型 | RT_Drv_Ctx/RT_Sol_Cfg |
| **Algo** | 无 | Bridge无算法 | - |
| **Ctx** | 无 | Bridge无Ctx | - |

---

## 五、四链映射

| 链 | 映射说明 |
|---|----------|
| **理论链** | L3模型定义→桥接转换→L4/L5物理/运行时处理 |
| **逻辑链** | L6调用Bridge→路由分发→L4/L5函数调用→结果返回 |
| **计算链** | 材料本构评估/单元刚度计算/接触检测/载荷施加 |
| **数据链** | L3 Desc→L4 Ctx/L5 RT类型转换,ID映射表 |

---

## 六、核心接口清单

### L3桥接
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Mat_Desc_To_UF_MaterialDef | 遗留→结构化转换 | md_desc, uf_def, status |
| UF_MaterialDef_To_MD_Mat_Desc | 结构化→遗留转换 | uf_def, md_desc, status |
| MaterialDesc_Init_Structured_Wrapper | 三段式适配器 | md_desc, status |

### L4桥接
| 接口 | 功能 | 参数 |
|------|------|------|
| Brg_AP_Get_Physical_Results | 查询物理结果 | elem_id, results, status |
| Brg_AP_Get_Physical_Results_FromCtx | 按Ctx查询结果 | elem_ctx, results, status |
| Brg_AP_Query_Element_Response | 查询单元响应 | elem_id, response, status |

### L5桥接
| 接口 | 功能 | 参数 |
|------|------|------|
| Brg_AP_Configure_Solver_ToCtx | 配置求解器 | solver_cfg, sol_ctx, status |
| Brg_AP_SetJobCtx_InContainer | 注入JobCtx | job_ctx, status |
| Brg_AP_SetRTDrvCtx | 存储RT_Drv_Ctx | rt_ctx, status |
| Brg_AP_StepRunner_RT | StepRunner桥接 | stepIndex, job_status |
| Brg_AP_Get_Job_Status_FromCtx | 查询作业状态 | rt_ctx, status_code, msg |
| Brg_AP_Query_Runtime_State_FromField | 查询场变量 | field_state, u/v/a/T |

---

## 七、跨域依赖矩阵

### L3_MD层(11个域)
| 域 | 桥接内容 |
|---|----------|
| Model/ModelTree | 模型树遍历/查询 |
| Step | 分析步配置 |
| Material | 材料Desc/UMAT接口 |
| Section | 截面Def |
| LoadBC | 载荷/BC Def |
| Part | 部件Def |
| Assembly | 装配体Def |
| Instance | 实例Def |
| Output | 输出Def |
| Contact | 接触对Def |
| Keyword | 关键字Def |

### L4_PH层(9个域)
| 域 | 桥接内容 |
|---|----------|
| Material | 物理结果查询 |
| Element | 单元响应查询 |
| Contact | 接触结果查询 |
| LoadBC | 载荷结果查询 |
| Constraint | 约束结果查询 |
| Field | 场变量查询 |
| Output | 输出格式化 |
| WriteBack | 回写状态查询 |
| Bridge | RT转换 |

### L5_RT层(13个域)
| 域 | 桥接内容 |
|---|----------|
| Assembly | 装配状态 |
| Contact | 接触状态 |
| Solver | 求解器配置/状态 |
| StepDriver | 步驱动状态 |
| Element | 单元运行时 |
| LoadBC | 载荷运行时 |
| Material | 材料运行时 |
| Mesh | 网格运行时 |
| Output | 输出系统 |
| WriteBack | 回写状态 |
| Logging | 日志 |
| Coupling | 多场耦合 |
| Bridge | L3/L4/L6桥接 |

---

## 八、依赖关系

### 向上依赖(被谁使用)
- L6_AP/Input: INP解析后模型构建
- L6_AP/Job: 作业管理
- L6_AP/Output: 输出格式化
- L6_AP/UI: 前后处理

### 向下依赖(依赖谁)
- L3_MD: 模型数据(11个域)
- L4_PH: 物理计算结果(9个域)
- L5_RT: 运行时状态(13个域)

---

## 九、桥接模式说明

### L3→L4桥接
- **L3_MD调用L4_PH本构/单元计算函数**(热路径)
- **接口封装**: Bridge模块隔离L3与L4/L5的直接依赖
- **类型转换**: L3的Desc/State类型转换为L4/L5的Ctx/Args类型

### L3→L5桥接
- **L3_MD向L5_RT传递模型数据/接收运行时状态**
- **ID映射**: Model ID与Runtime ID双向映射(节点/单元/材料/截面)

---

## 十、STUB状态

### 待实现接口
- `Brg_AP_Format_Output`: 输出格式化
- `Brg_AP_Query_Element_Response`: 按elem_id查询单元响应
- `Brg_AP_Get_Job_Status`: 基础接口
- `Brg_AP_Query_Runtime_State`: 基础接口
- `Brg_AP_Configure_Solver`: 基础接口

---

## 十一、热路径规范

- **热路径**: 是(单元计算/材料本构在热路径中)
- **热路径零L3**: 步内减少USE MD_*(G4:M0审计销项)
- **Re-Export模式**: 避免L6_AP直接依赖L3_MD模块

---

## 十二、测试策略

### 单元级测试
- L3桥接: Re-Export接口正确性
- L4桥接: 物理结果查询正确性
- L5桥接: 运行时状态查询正确性

### 集成级测试
- Bridge↔L3_MD: 模型数据传递
- Bridge↔L4_PH: 物理结果查询
- Bridge↔L5_RT: 运行时状态查询
- Bridge↔L6_AP: StepRunner桥接

---

## 十三、错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L6_BRIDGE_xxx`（60100–60199） |
| 严重级 | Warning / Error（桥接失败为 Error） |
| 传播规则 | 桥接层捕获下层错误，附加 Bridge 上下文后向上传播至 L6 调用方 |
| 恢复策略 | 类型转换失败返回默认值 + Warning；查询失败返回 status<0 + Error |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L3_MD/Bridge | T(合同) | L3 桥接模块正式合同，Re-Export 全部 L3 公开类型 |
| 2 | L5_RT/Bridge | T(合同) | L5 桥接模块正式合同，StepRunner 委托与状态查询 |
| 3 | L6_AP/Input | S(消费) | 消费 Input 解析结果，通过桥接注入 L3/L5 |
| 4 | L6_AP/Output | S(消费) | 消费 Output 配置，格式化 L4 物理结果 |
| 5 | L1_IF | U(USE) | Fortran USE 基础设施模块（IF_Prec_Core, IF_Error 等） |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Re-Export 接口签名与 L3 公开接口一致 | 硬约束 | 编译期 + 接口比对脚本 | PR 合入 |
| 类型转换双向可逆（MD_Mat_Desc↔UF_MaterialDef） | 硬约束 | 单元测试 round-trip | CI |
| StepRunner 接口符合 UF_Job_StepRunner_Ifc | 硬约束 | 编译期 TYPE 检查 | PR 合入 |
| STUB 接口返回合法默认值 | 软约束 | 集成测试 | Nightly |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc | 无（转发 L3 Desc） | Re-Export L3_MD 类型定义 |
| 2 | State | 无（转发 L5 State） | Re-Export L5_RT 运行时状态 |
| 3 | Algo | 无 | Bridge 无独立算法 |
| 4 | Ctx | 无 | Bridge 无独立上下文 |
| 5 | Arg (SIO) | 无 | 薄桥接层不需要 *_Arg |
| 6 | Proc | AP_Brg_L3/L4/L5.f90 | 三个桥接模块即为 Proc |
| 7 | Test | Bridge 单元测试 | Re-Export 正确性 + round-trip |
| 8 | CONTRACT | 本文件 | 域级合同卡 |
| 9 | Config | 无 | 无独立配置 |
| 10 | Error | ERR_L6_BRIDGE_xxx | 60100–60199 |
| 11 | Domain | AP_Bridge 域 | L6_AP/Bridge/ |
| 12 | Registry | 无 | 不注册服务 |
| 13 | Doc | 本合同 + 代码注释 | 桥接模式说明 |

---

## 十四、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 2026-04-17 | 初始版本,创建Bridge域合同卡 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `AP_Brg_L3.f90` | `AP_BrgL3` | — | — |
| `AP_Brg_L4.f90` | `AP_BrgL4` | — | `Brg_AP_Get_Ph_Re_FromCtx` (SUB,PRV,Query); `Brg_AP_Get_Physical_Results` (SUB,PUB,Query) |
| `AP_Brg_L5.f90` | `AP_BrgL5` | — | `Brg_AP_Configure_Solver_ToCtx` (SUB,PUB,Compute); `Brg_AP_Configure_Solver` (SUB,PUB,Compute); `Brg_AP_SetJobCtx_InContainer` (SUB,PUB,Mutate); `Brg_AP_SetRTDrvCtx` (SUB,PUB,Mutate); `Brg_AP_StepRunner_RT` (SUB,PUB,—); `Brg_AP_Get_Job_Status_FromCtx` (SUB,PUB,Query); `Brg_AP_Get_Job_Status` (SUB,PUB,Query); `Brg_AP_Query_Runtime_State_FromField` (SUB,PUB,Query); `Brg_AP_Query_Runtime_State` (SUB,PUB,Query) |
| `AP_Mat_Brg.f90` | `AP_Mat_Brg` | — | `MD_Mat_Desc_To_UF_MaterialDef` (SUB,PRV,—); `UF_MaterialDef_To_MD_Mat_Desc` (SUB,PRV,—); `MaterialDesc_Init_Structured_Wrapper` (SUB,PUB,Init) |
