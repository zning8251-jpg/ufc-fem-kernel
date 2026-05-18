# Model域合同卡 (L3_MD/Model)

**Layer**: L3_MD (模型数据层)  
**Domain**: Model (模型树根与元数据)  
**Version**: v3.2.0  
**Updated**: 2026-05-07  
**Status**: ✅ Model 域全面重构完成；**对外过程命名真源**对齐 **[`UFC/REPORTS/Model_Domain_FourType_Procedure_Naming_Spec.md`](../../../REPORTS/Model_Domain_FourType_Procedure_Naming_Spec.md) v1.2**：专题级入口为 **`MD_Model_<TopicSlug>_Parse` / `MD_Model_<TopicSlug>_Cfg`**（完整 `Model` 前缀，**禁止** 新代码使用 `MD_Mo_*`、`Unified_*`、`Un_Pa`/`Un_Cf`）。遗留 `MD_Mo_*` 仅由 [`config/model_naming_lexicon.yaml`](../../../config/model_naming_lexicon.yaml) **解码**，不得扩展。

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### Model 域过程命名（v3.2，对齐 REPORT v1.2）

- **MODULE / 文件**：`MD_Model_<专题>_<角色>.f90`，`MODULE` = 文件名 stem；对外 **TYPE** 名保持可读（如 `DistributionProperties`），不强制压缩。
- **专题级对外入口（权威）**：`MD_Model_<TopicSlug>_Parse`、`MD_Model_<TopicSlug>_Cfg`，其中 **TopicSlug = 模块 stem 去掉前缀 `MD_Model_` 后的整段**（见 REPORT §6.3）。配置入口用词一律 **`Cfg`**，**禁止** 为新 PUBLIC 引入 `Configure` / `Unified_Configure` / `Unified_Cfg`。
- **关键字边界**：`Parse_*_Keyword`、`Valid_*_Keyword`、`PhysicalConstants_Parse_Keyword` 等 **保持可读全称**，供 `MD_KW_Mapper` 与校验直接 `CALL`；专题入口可在外部调度或注册表中引用。
- **`MD_KW.f90` 注册**：`parse_module` / `parse_proc` / `validate_proc` 字符串必须与磁盘 **实际符号** 一致（例如 `*PARAMETER`：`parse_proc="MD_Model_Data_Param_Parse"`，`validate_proc="Valid_Param_Keyword"`）。
- **遗留**：历史 `MD_Model_*_Unified_*`、`MD_Model_CoordSys_*`、`MD_Mo_*` 若仍存在于某分支，仅允许 **薄包装** `CALL` 转至 `*_Parse`/`*_Cfg` 后删除；**不得** 在新模块新增上述形态。

| 模块 stem（示例） | 权威 Parse | 权威 Cfg |
|-------------------|------------|----------|
| `MD_Model_Data_Table` | `MD_Model_Data_Table_Parse` | `MD_Model_Data_Table_Cfg` |
| `MD_Model_Data_Param` | `MD_Model_Data_Param_Parse` | `MD_Model_Data_Param_Cfg` |
| `MD_Model_Data_Dist` | `MD_Model_Data_Dist_Parse` | `MD_Model_Data_Dist_Cfg` |
| `MD_Model_Data_Variable` | `MD_Model_Data_Variable_Parse` | `MD_Model_Data_Variable_Cfg` |
| `MD_Model_Data_PhysConst` | `MD_Model_Data_PhysConst_Parse` | `MD_Model_Data_PhysConst_Cfg` |
| `MD_Model_Coord_Transform` | `MD_Model_Coord_Transform_Parse` | `MD_Model_Coord_Transform_Cfg` |
| `MD_Model_Coord_Sys` | `MD_Model_Coord_Sys_Parse` | `MD_Model_Coord_Sys_Cfg` |
| `MD_Model_Import` | `MD_Model_Import_Parse` | `MD_Model_Import_Cfg` |
| `MD_Model_Prestress` | `MD_Model_Prestress_Parse` | `MD_Model_Prestress_Cfg` |
| `MD_Model_Substruct` | `MD_Model_Substruct_Parse` | `MD_Model_Substruct_Cfg` |

## 一、职责边界

### 核心职责
- **定位**: UFC L3_MD层Model域,模型级Desc(名称、维数、分析类型、子域计数)真相源
- **职责**: 模型树管理、元数据定义、子域容器管理、模型验证、IO序列化
- **边界**: 仅提供模型级元数据;不写文件;不执行单元/本构Algo
- **依赖**: 上游Base/Types;下游Part/Mesh/Step/Material等子域

---

## 二、文件清单 (v3.2.0, 2026-05-07；Model 域 `MD_Model_*.f90` 共 **26** 个，不含 `Tests/`，以磁盘为准)

### 核心文件 (Model/ 目录)
| 文件 | 模块名 | 状态 | 职责 |
|------|--------|------|------|
| `MD_Model_Def.f90` | `MD_Model_Def` | **AUTHORITY** | 统一 Desc/State/Ctx/Algo，辅 TYPE 嵌套 (cfg%/pop%) |
| `MD_Model_Mgr.f90` | `MD_Model_Mgr` | **容器权威** | `TYPE(MD_Model_Domain)`、`TYPE(MD_Model_Ctx)`、`TYPE(MD_Model_AdvProps)`（高级 Import/Prestress/Substruct 容器）；导入统一 Desc |
| `MD_Model_Core.f90` | `MD_Model_Core` | ACTIVE | P0 生命周期：`model_name`/`spatial_dim` 字段 |
| `MD_Model_Tree.f90` | `MD_Model_Tree` | ACTIVE | 模型树 (extends MD_Model_Desc) |
| `MD_Model_Access.f90` | `MD_Model_Access` | ACTIVE | CLASS(MD_Model_Desc) 取子域 |
| `MD_Model_Builder.f90` | `MD_Model_Builder` | ACTIVE | 模型构建 |
| `MD_Model_VarCtx.f90` | `MD_Model_VarCtx` | ACTIVE | 变量上下文管理 (从 Lib 提取) |
| `MD_Model_Data_Table.f90` | `MD_Model_Data_Table` | ACTIVE | Table：类型 + Parse + Validate（*TABLE，合并；对齐 Parameter 试点） |
| `MD_Model_Data_Param.f90` | `MD_Model_Data_Param` | ACTIVE | Parameter：类型 + Parse + Validate（*PARAMETER，试点合并） |
| `MD_Model_Data_Field.f90` | `MD_Model_Data_Field` | ACTIVE | Field：类型 + Parse + Validate（*FIELD，合并） |
| `MD_Model_Data_Dist.f90` | `MD_Model_Data_Dist` | ACTIVE | Distribution：类型 + Parse + Validate（*DISTRIBUTION，合并） |
| `MD_Model_Data_Variable.f90` | `MD_Model_Data_Variable` | ACTIVE | Variable：类型 + Parse + Validate（*VARIABLE，合并） |
| `MD_Model_Data_Filter.f90` | `MD_Model_Data_Filter` | ACTIVE | Filter：类型 + Parse + Validate（Model 数据侧 *FILTER，合并） |
| `MD_Model_Data_PhysConst.f90` | `MD_Model_Data_PhysConst` | ACTIVE | PhysicalConstants：类型 + Parse + Validate（宏 *PHYSICAL CONSTANTS，合并） |
| `MD_Model_Data_Def.f90` | `MD_Model_Data_Def` | **FACADE** | Data 类型再导出聚合 |
| `MD_Model_Data_Proc.f90` | `MD_Model_Data_Proc` | **FACADE** | Data 模块 `USE` 聚合（与 `MD_Model_Data_Def` 配对） |
| `MD_Model_Coord_Transform.f90` | `MD_Model_Coord_Transform` | ACTIVE | *TRANSFORM：类型 + Parse + Validate（合并；文件名 `MD_Model_Coord_Transform`） |
| `MD_Model_Coord_Sys.f90` | `MD_Model_Coord_Sys` | ACTIVE | *SYSTEM：类型 + Parse + Validate（合并；文件名 `MD_Model_Coord_Sys`） |
| `MD_Model_Coord_Orient.f90` | `MD_Model_Coord_Orient` | ACTIVE | *ORIENTATION：类型 + Parse + Validate；**`MD_Model_Coord_Orient_Parse` / `MD_Model_Coord_Orient_Cfg`** |
| `MD_Model_Coord_Normal.f90` | `MD_Model_Coord_Normal` | ACTIVE | *NORMAL：类型 + Parse + Validate；**`MD_Model_Coord_Normal_Parse` / `MD_Model_Coord_Normal_Cfg`** |
| `MD_Model_Lib_Core.f90` | `MD_Model_Lib_Core` | ACTIVE | 核心库实现 (UF_ModelDef)；消费者 **直接** `USE`（已移除 `MD_Model_Lib` 薄 Facade） |
| `MD_Model_Import.f90` | `MD_Model_Import` | ACTIVE | *IMPORT：类型 + Parse（合并；文件名 `MD_Model_Import`） |
| `MD_Model_Prestress.f90` | `MD_Model_Prestress` | ACTIVE | *PRESTRESS：类型 + 解析（合并） |
| `MD_Model_Substruct.f90` | `MD_Model_Substruct` | ACTIVE | *SUBSTRUCTURE：类型 + 解析（合并） |
| `MD_Model_Reg.f90` | `MD_Model_Reg` | ACTIVE | 高级功能（IMPORT/PRESTRESS/SUBSTRUCTURE）关键字注册表 |
| `MD_Model_Data.f90` | `MD_Model_Data` | **FACADE** | 旧 Table 类型向后兼容再导出 |
| `Tests/MD_Model_test.f90` | `MD_Model_Test` | **SKELETON** | 测试 |

### Base 基础设施 (已移入 L3_MD/Base/)
| 文件 | 模块名 | 状态 | 职责 |
|------|--------|------|------|
| `../Base/MD_Base_ObjModel.f90` | `MD_BaseObjModel` | ACTIVE | 四型基类/容器 |
| `../Base/MD_Base_TreeIndex.f90` | `MD_BaseTreeIndex` | CORE | 树索引/路径解析 |
| `../Base/MD_Base_DataModMgr.f90` | `MD_BaseDataModMgr` | CORE | 数据模型管理器 |
| `../Base/MD_Base_IOSerialMgr.f90` | `MD_BaseIOSerialMgr` | CORE | IO 序列化 |
| `../Base/MD_Base_FieldVarMgr.f90` | `MD_BaseFieldVarMgr` | CORE | 场变量管理器 |
| `../Base/MD_Base_MathUtils.f90` | `MD_BaseMathUtils` | CORE | 数学工具 |
| `../Base/MD_BaseTypes.f90` | `MD_BaseTypes` | ACTIVE | Base Types |
| `../Base/MD_Base_Enums.f90` | `MD_BaseEnums` | CORE | Enums |
| `../Base/MD_Base_ElemLib.f90` | `MD_BaseElemLib` | CORE | 单元库 |
| `../Base/MD_Base_Def.f90` | `MD_Base_Def` | ACTIVE | Base 类型聚合 |
| `../Base/MD_Kinematics_Def.f90` | `MD_Kinematics_Def` | ACTIVE | 运动学元类型 |

### 竖切说明（2026-05 全面重构）
- **Base 移出**：11 个跨域基础设施模块 (`MD_Base_*` + `MD_Kinematics_Def`) 从 `Model/` 移入 `L3_MD/Base/`，消费者 USE 语句不变。
- **MD_Model_Desc 合并**：轻量 (Def) 与扩展 (Mgr) 两种 Desc 变体已统一为权威 `MD_Model_Def::MD_Model_Desc`，含 `cfg%/pop%` 辅 TYPE 嵌套。
- **字段重命名**：`name` → `model_name`，`ndim` → `spatial_dim`。
- **MD_Model_Mgr 精简**：移除内联扩展 Desc 定义，指向统一 Desc。
- **巨文件拆分**：`MD_Model_Data_Def.f90` / `MD_Model_Data_Proc.f90` 为 Def/Proc Facade（再导出拆分实现）；坐标系为 `MD_Model_Coord_Sys`、`MD_Model_Coord_Transform`、`MD_Model_Coord_Orient`、`MD_Model_Coord_Normal` 单文件模块。Lib 核心为 `MD_Model_Lib_Core`。v3.1.4 **已删除** 仅再导出的 `MD_Model_Lib.f90`、`MD_Model_CoordSys.f90`。
- **命名规范化（v3.2）**：Data/Coord/Adv 专题对外入口统一为 **`MD_Model_<TopicSlug>_Parse` / `_Cfg`**（REPORT v1.2）；**禁止** 为新 PUBLIC 引入 `MD_Mo_*`、`Unified_*`。关键字级 `Parse_*_Keyword`、`PhysicalConstants_Parse_Keyword`、`Valid_*_Keyword` 等**保持可读全称**。
- **冗余文件清理**：已删除 `MD_Model_Types.f90`（28 行仅再导出）、`MD_Model_DomBrg.f90`（22 行空骨架）。
- **Job 遗留清理**：已清理 `MD_BaseTypes.f90` 及 `RT_Step_WS.f90` 中对不存在的 `Job`/`AnalysisCtx`/`JobDesc` 类型的引用。
- **消费者更新**：`MD_KW.f90` / `MD_KW_Mapper.f90` 中 `parse_module` / `parse_proc` / `validate_proc` 须与磁盘一致。Data 关键字模块：`MD_Model_Data_Table`、`MD_Model_Data_Param`、`MD_Model_Data_Field`、`MD_Model_Data_Dist`、`MD_Model_Data_Variable`、`MD_Model_Data_Filter`、`MD_Model_Data_PhysConst`；注册表 `parse_proc` 使用各模块 **`MD_Model_Data_*_Parse`**。**已删除** `MD_Model_Lib`、`MD_Model_CoordSys` 等仅再导出 Facade。

### 历史说明（文件/模块名曾混乱；磁盘以实际 f90 为准）
- 若文档仍写 `MD_Model.f90` / `MD_ModelDomain.f90`：以当前 `L3_MD/Model/` 下**实际存在**的源文件名为准；**不要**再新增与 `MD_Model_Mgr` 并行的第二套域容器模块。

### 已知遗留（非本波修改范围）
- 无（本波已清理所有已知遗留）。

---

## 三、四类TYPE映射 (v2.3 后统一)

| Type种类 | TYPE名称 | 核心职责 | 字段示例 | 来源 |
|----------|----------|----------|----------|------|
| **Desc** | `MD_Model_Desc` | 统一模型描述符 (含cfg%/pop%辅TYPE) | model_name, spatial_dim, cfg%analysis_type, n_materials | `MD_Model_Def` (AUTHORITY) |
| **State** | `MD_Model_State` | 模型构建进度 | parsed, populated, validated, build_phase | `MD_Model_Def` |
| **Algo** | `MD_Model_Algo` | 模型级算法策略 (精简) | renumber_strategy, partition_method | `MD_Model_Def` |
| **Ctx** | `MD_Model_Ctx` | 构建上下文 (Def中定义) | parse_unit, source_file, strict_mode | `MD_Model_Def` |
| **Ctx** | `MD_Model_Ctx` (Mgr版) | 扩展上下文 (extends BaseCtx) | desc/state/algo 指针, ThreadWS | `MODULE MD_Model_Mgr` |

---

## 四、四链映射

| 链 | 映射说明 |
|---|----------|
| **理论链** | 模型树结构→子域容器→Populate注入各PH域 |
| **逻辑链** | Model↔Part↔Mesh↔Step↔Material闭环 |
| **计算链** | 无(L3仅管理元数据,不执行计算) |
| **数据链** | INP→MD_Model_Desc→各子域Desc→L4/L5 Populate |

---

## 五、模型树层次结构

```
ModelTree (根)
├── Parts (ObjContainer)
├── Assemblies (ObjContainer)
├── Materials (ObjContainer)
├── Sections (ObjContainer)
├── Meshes (ObjContainer)
├── Amplitudes (ObjContainer)
├── LoadBCs (ObjContainer)
├── Steps (ObjContainer)
├── Interactions (ObjContainer)
└── Outputs (ObjContainer)
```

---

## 六、核心接口清单

### 模型管理
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Model_Domain_Init | 域容器初始化 | status |
| MD_Model_Domain_Finalize | 释放域容器 | status |
| MD_Model_Domain_SetDesc | 解析期写入Desc | model_desc, status |
| MD_Model_Domain_GetInfo | 只读查询 | model_info, status |

### 模型验证
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Model_ValidateModel | 一致性验证 | status |
| MD_Model_ValidateSubdomains | 子域验证 | status |

### 模型树管理
| 接口 | 功能 | 参数 |
|------|------|------|
| MD_Model_Tree_Init | 初始化模型树 | status |
| MD_Model_Tree_AddChild | 添加子节点 | child_node, status |
| MD_Model_Tree_GetChild | 查询子节点 | child_name, child_node, status |

---

## 七、跨域依赖矩阵(10个调用方)

| 调用方 | 依赖内容 |
|--------|----------|
| L6_AP/Input/Command/AP_Inp_*.f90 | *MODEL/*PART解析 |
| L5_RT/Solver/RT_Solv_*.f90 | 模型信息读取 |
| L5_RT/Assembly/RT_Assem_*.f90 | 装配体引用 |
| L4_PH/Element/PH_Elem_*.f90 | 单元模型引用 |
| L4_PH/Material/PH_Mat_*.f90 | 材料模型引用 |
| L3_MD/Part/MD_Part_*.f90 | Part域 |
| L3_MD/Element/Mesh/MD_Mesh_*.f90 | Mesh域 |
| L3_MD/Step/MD_Step_*.f90 | Step域 |
| L3_MD/Assembly/MD_Assem_*.f90 | Assembly域 |
| L3_MD/Material/MD_Mat_*.f90 | Material域 |

---

## 八、依赖关系

### 向上依赖(被谁使用)
- L5_RT/Solver: 模型信息读取
- L4_PH/Element: 单元模型引用
- L4_PH/Material: 材料模型引用
- L6_AP: 模型树遍历

### 向下依赖(依赖谁)
- L1_IF/Base: 上游Base/Types
- L3_MD/Part: Part域
- L3_MD/Element/Mesh: Mesh域
- L3_MD/Step: Step域

---

## 九、Bridge接口

### L3→L5 Bridge
| 接口 | 功能 | 说明 |
|------|------|------|
| MD_Model_RT_Brg | L3→L5桥接 | 模型运行时数据 |
| MD_UI_RT_Brg | UI→L5桥接 | 见Bridge/BRIDGE_INDEX.md |

### L3→L4 Bridge
| 接口 | 功能 | 说明 |
|------|------|------|
| MD_Model_Brg | L3→L4桥接 | 模型数据传递 |

---

## 十、热路径规范

- **热路径**: 否
- **冷路径**: 建模期/Populate期
- **步内**: 仅读取模型信息,不修改

---

## 十一、测试策略

### 单元级测试
- 模型初始化: 验证model_name/n_dims
- 子域容器: 验证各子域计数
- 模型验证: 一致性检查

### 集成级测试
- Model↔Part/Mesh/Step: 子域引用正确性
- Model↔L4_PH: Populate数据传递

---

## 十二、错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L3_MODEL_xxx` (30900–30999) |
| 严重级 | WARNING: 子域容器为空(可能合法); ERROR: 模型验证失败(缺少必需子域); FATAL: 无 |
| 传播规则 | 经 `status` 参数返回；验证错误累计后一次性上报 |
| 恢复策略 | WARNING：日志记录；ERROR：中止 Populate 前报告所有失败项 |

---

## 十三、域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Part | T(合同) | 模型树 → Part 容器 |
| R2 | L3_MD/Element/Mesh | T(合同) | 模型树 → Mesh 容器 |
| R3 | L3_MD/Material | T(合同) | 模型树 → Material 容器 |
| R4 | L3_MD/Section | T(合同) | 模型树 → Section 容器 |
| R5 | L3_MD/Assembly | T(合同) | 模型树 → Assembly 容器 |
| R6 | L3_MD/Analysis/Step | T(合同) | 模型树 → Step 容器 |
| R7 | L3_MD/Interaction | T(合同) | 模型树 → Interaction 容器 |
| R8 | L3_MD/Output | T(合同) | 模型树 → Output 容器 |
| R9 | L4_PH (经 Populate) | B(桥接) | 模型数据注入 L4 |
| R10 | L5_RT (经 Bridge) | B(桥接) | 模型信息查询 |
| R11 | L6_AP/Input | E(外部) | *MODEL 解析来源 |
| R12 | L1_IF/Base | U(USE) | 基础类型 |

---

## 十四、约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Model 为模型树根，所有子域须通过 Model 容器注册 | 硬 | Code Review | — |
| Model Desc 为 Write-Once，建模完成后只读 | 硬 | Code Review | — |
| 禁止在 Model 域执行计算 | 硬 | Code Review | — |
| L3→L4/L5 须经 Bridge | 硬 | Harness | H-DEP-03 |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 模型树结构变更须同步本 CONTRACT §五 | 软 | Code Review | — |

---

## 十五、十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | MD_Model_Desc, MD_Model_MetaDesc | 模型名/维数/分析类型/元数据 |
| 2 | State 定义 | MD_Model_State | isBuilt, n_subdomains |
| 3 | Algo 定义 | N/A | Model 不执行算法 |
| 4 | Ctx 定义 | N/A | 无运行时上下文 |
| 5 | Init/Finalize | MD_Model_Domain_Init / Finalize | 域容器初始化/释放 |
| 6 | Query | MD_Model_Domain_GetInfo, MD_Model_Tree_GetChild | 只读查询 |
| 7 | Validate | MD_Model_ValidateModel / ValidateSubdomains | 模型一致性验证 |
| 8 | Populate | 经 Bridge → L4/L5 | 模型数据注入 |
| 9 | Bridge | MD_Model_RT_Brg, MD_Model_Brg | L4/L5 桥接 |
| 10 | WriteBack | N/A | 模型级不参与写回 |
| 11 | Parse | 经 KeyWord *MODEL / *PART | — |
| 12 | Compute | N/A | L3 无计算 |
| 13 | Error | status 参数返回 | 见 §十二 |

---

### 细粒度子程序清单

> **说明（附录表格）**：下列宽表仍以历史合并文件名作为**逻辑分桶**键；磁盘实现以 `§二` 清单为准。Model 专题对外过程名以 **v3.2 `MD_Model_<TopicSlug>_Parse` / `_Cfg`** 为准（REPORT v1.2）；附录行若仍出现旧符号，以 `§二` 与源码为准。

## 十七、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 早期 | 初始简版合同卡(55行) |
| v2.0 | 2026-04-17 | 扩充为标准格式,200+行 |
| v2.2 | 2026-05-06 | Model 域重构：Base 独立、Desc 合并、巨文件拆分 |
| v2.3 | 2026-05-06 | 细化重构：命名规范化(32+ 过程重命名)、*Arg 类型添加、ModelTree 编译 bug 修复 |
| v3.0 | 2026-05-06 | 合同卡标记：全面重构完成（拆分、清理、消费者对齐） |
| v3.1 | 2026-05-07 | 统一 Parse/Cfg 入口改名为 `MD_Mo_*`；Lexicon 见 `config/model_naming_lexicon.yaml`；`MD_KW` 注册与旧名**薄包装**兼容；附录与生成 Registry 同步 |
| v3.1.1 | 2026-05-07 | *TRANSFORM 三文件合并为 `MD_Model_Coord_Transform.f90`（`MD_Model_Coord_Transform`）；`TransformProps` 短字段 `nset`/`ityp`/`pa`/`pb`/`tmat`；Model 域 `MD_Model_*.f90` 计数 **34→32** |
| v3.1.2 | 2026-05-07 | *IMPORT：`MD_Model_Adv_Import_Type` + `MD_Model_Adv_Import_Parse` → `MD_Model_Import.f90`；高级注册表模块后更名为 `MD_Model_Reg`（磁盘曾用 `MD_Model_Adv_Unified_Reg`）；IMPORT 的 `parse_module`=`MD_Model_Import`；Model 域 `MD_Model_*.f90` 计数 **32→31** |
| v3.1.3 | 2026-05-07 | *PRESTRESS / *SUBSTRUCTURE：两对 `*_Type` + `*_Parse` 合并为 `MD_Model_Prestress.f90`、`MD_Model_Substruct.f90`；`ADVANCED_FEATURES` 中对应 `parse_module` 为 `MD_Model_Prestress`、`MD_Model_Substruct`；**`EstimateMemorySavings`** 内实数局部变量提升至函数声明部（标准 F2003）；Model 域 `MD_Model_*.f90` 计数 **31→29** |
| v3.1.4 | 2026-05-07 | 删除 `MD_Model_Lib`、`MD_Model_CoordSys` 薄 Facade；`MD_Model_Data_Param` / `MD_Model_Data_Dist` / `MD_Model_Data_PhysConst`，`MD_Model_Coord_Normal` / `MD_Model_Coord_Orient`，`MD_Model_Reg`；`AdvPropsMgr` 并入 `MD_Model_Mgr`；全仓 `USE MD_Model_Lib`→`MD_Model_Lib_Core`；`MD_KW` `parse_module` 对齐；**29→26** |
| v3.2.0 | 2026-05-07 | **合同对齐 REPORT v1.2**：对外专题入口 `MD_Model_<TopicSlug>_Parse`/`_Cfg`；`TYPE(MD_Model_AdvProps)` 取代 `AdvPropsMgr`；补全 `MD_Model_Data_{Param,Dist,Variable,PhysConst}.f90`；§二 增补 `MD_Model_Data_Proc` 行；Model 域 **`MD_Model_*.f90` 计数 24→26**（含 `Coord_Orient`/`Coord_Normal`）；`MD_KW` `parse_proc` 与 Data 模块一致 |

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `MD_Base_DataModMgr.f90` | `MD_BaseDataModMgr` | `FieldMeta`, `TypeMeta`, `TypeReg` | `Init` (TBP,PRV,—); `Module_Init_Intf` (SUB,PRV,Init); `Module_Cleanup_Intf` (SUB,PRV,Finalize); `TypeReg_Init` (SUB,PUB,Init); `TypeReg_Init_TBP` (SUB,PRV,Init); `type_init` (SUB,PUB,Init); `type_reg` (SUB,PUB,—); `type_find` (SUB,PUB,Query); `type_flds` (SUB,PUB,—); `TypeReg_ClearAllTypes` (SUB,PRV,Mutate); `TypeReg_RegisterType` (SUB,PUB,—); `TypeReg_FindType` (SUB,PUB,Query); `TypeReg_GetTypeInfo` (SUB,PUB,Query); `TypeReg_GetFieldInfo` (SUB,PUB,Query); `TypeReg_ValidateType` (SUB,PUB,Validate); `TypeReg_Shutdown` (SUB,PUB,—); `TypeReg_ValidateTypeParams` (SUB,PRV,Validate); `TypeReg_ValidateFieldsArray` (SUB,PRV,Validate); `TypeReg_ValidateFields` (SUB,PRV,Validate); `TypeReg_CalculateTypeSize` (SUB,PRV,Compute); `DataAccess_Init` (SUB,PUB,Init); `DataAccess_AllocateDataObj` (SUB,PUB,—); `DataAccess_DeallocateDataObj` (SUB,PUB,Finalize); `DataAccess_FindById` (FN,PUB,Query); `DataAccess_FindByName` (FN,PUB,Query); `CalcDataStride` (FN,PUB,—); `MAPLOGICALTOIND` (FN,PUB,—); `data_create_object` (SUB,PUB,Init); `data_destroy_object` (SUB,PUB,Finalize); `data_associate_pointer` (SUB,PUB,—); `data_disassociate_pointer` (SUB,PUB,—); `data_get_pointer` (SUB,PUB,Query); `data_is_associated` (FN,PUB,Query); `data_get_stats` (SUB,PUB,Query); `obj_new` (SUB,PUB,—); `obj_set` (SUB,PUB,Mutate); `obj_get` (SUB,PUB,Query); `obj_del` (SUB,PUB,—); `obj_save` (SUB,PUB,—); `obj_load` (SUB,PUB,Parse); `obj_new_and_set` (SUB,PUB,Mutate); `obj_copy_field` (SUB,PUB,—); `Uma_Init` (SUB,PUB,Init); `Uma_InitMemorySystem` (SUB,PRV,Init); `Uma_InitTypeSystem` (SUB,PRV,Init); `Uma_RegisterModule` (SUB,PUB,—); `Uma_FindModule` (FN,PUB,Query); `Uma_GetModuleInterface` (FN,PUB,Query); `Uma_AllocateModuleMemory` (SUB,PUB,—); `Uma_DeallocateModuleMemory` (SUB,PUB,Finalize); `fw_init` (SUB,PUB,Init); `fw_add_mod` (SUB,PUB,Mutate); `fw_done` (SUB,PUB,—) |
| `MD_Base_ElemLib.f90` | `MD_BaseElemLib` | — | `UF_ComputeJacobian` (SUB,PUB,Compute); `UF_GetGaussPoints` (SUB,PUB,Query); `UF_GetShapeFunctions` (SUB,PUB,Query) |
| `MD_Base_Enums.f90` | `MD_BaseEnums` | `Utils_Error_In`, `Utils_Error_Out` | `uf_error` (SUB,PUB,—) |
| `MD_Base_FieldVarMgr.f90` | `MD_BaseFieldVarMgr` | — | `InitVars` (SUB,PUB,—); `DestroyVars` (SUB,PUB,—); `RegField` (SUB,PUB,—); `FindField` (FN,PUB,—); `GetFieldId` (SUB,PUB,—); `EnsureFields` (SUB,PUB,—); `GetR1D` (SUB,PUB,—); `GetR2D` (SUB,PUB,—); `GetI1D` (SUB,PUB,—); `GetI2D` (SUB,PUB,—); `GetL1D` (SUB,PUB,—); `ViewR1D` (SUB,PUB,—); `ViewR2D` (SUB,PUB,—); `ViewI1D` (SUB,PUB,—); `ViewI2D` (SUB,PUB,—); `RegViewR1D` (SUB,PUB,—); `RegViewI1D` (SUB,PUB,—); `RegViewR2D` (SUB,PUB,—); `RegViewI2D` (SUB,PUB,—); `Core_Init` (SUB,PUB,Init); `Core_Free` (SUB,PUB,Finalize); `Core_HasErr` (FN,PUB,Query); `Dof_Ensure` (SUB,PUB,—); `Dof_Build` (SUB,PUB,Populate); `Model_Init` (SUB,PUB,Init); `Model_BuildDof` (SUB,PUB,Populate); `Model_SetupUIF` (SUB,PUB,Init) |
| `MD_Base_IOSerialMgr.f90` | `MD_BaseIOSerialMgr` | `FileHandle` | `Init` (TBP,PRV,—); `Destroy` (TBP,PRV,—); `Open` (TBP,PRV,—); `Close` (TBP,PRV,—); `ReadLine` (TBP,PRV,—); `WriteLine` (TBP,PRV,—); `IsOpen` (TBP,PRV,—); `GetSize` (TBP,PRV,—); `GetPosition` (TBP,PRV,—); `Seek` (TBP,PRV,—); `Flush` (TBP,PRV,—); `FileHandle_Init` (SUB,PRV,Init); `FileHandle_Destroy` (SUB,PRV,Finalize); `FileHandle_Open` (SUB,PRV,—); `FileHandle_Close` (SUB,PRV,—); `FileHandle_ReadLine` (SUB,PRV,Parse); `FileHandle_WriteLine` (SUB,PRV,IO); `FileHandle_IsOpen` (FN,PRV,Query); `FileHandle_GetSize` (FN,PRV,Query); `FileHandle_GetPosition` (FN,PRV,Query); `FileHandle_Seek` (SUB,PRV,—); `FileHandle_Flush` (SUB,PRV,—); `BR_Init` (SUB,PRV,Init); `BR_Destroy` (SUB,PRV,Finalize); `BR_Open` (SUB,PRV,—); `BR_Close` (SUB,PRV,—); `BR_ReadInt1` (SUB,PRV,Parse); `BR_ReadInt2` (SUB,PRV,Parse); `BR_ReadInt4` (SUB,PRV,Parse); `BR_ReadInt8` (SUB,PRV,Parse); `BR_ReadDP` (SUB,PRV,Parse); `BR_ReadArrInt1` (SUB,PRV,Parse); `BR_ReadArrInt4` (SUB,PRV,Parse); `BR_ReadArrDP` (SUB,PRV,Parse); `BR_ReadStr` (SUB,PRV,Parse); `BR_IsOpen` (FN,PRV,Query); `BW_Init` (SUB,PRV,Init); `BW_Destroy` (SUB,PRV,Finalize); `BW_Open` (SUB,PRV,—); `BW_Close` (SUB,PRV,—); `BW_WriteInt1` (SUB,PRV,IO); `BW_WriteInt2` (SUB,PRV,IO); `BW_WriteInt4` (SUB,PRV,IO); `BW_WriteInt8` (SUB,PRV,IO); `BW_WriteDP` (SUB,PRV,IO); `BW_WriteArrInt1` (SUB,PRV,IO); `BW_WriteArrInt4` (SUB,PRV,IO); `BW_WriteArrDP` (SUB,PRV,IO); `BW_WriteStr` (SUB,PRV,IO); `BW_IsOpen` (FN,PRV,Query); `BW_Flush` (SUB,PRV,—); `HDF5File_Init` (SUB,PRV,Init); `HDF5File_Destroy` (SUB,PRV,Finalize); `HDF5File_Open` (SUB,PRV,—); `HDF5File_Close` (SUB,PRV,—); `HDF5File_CreateGroup` (SUB,PRV,Init); `HDF5File_OpenGroup` (SUB,PRV,—); `HDF5File_CreateDataset` (SUB,PRV,Init); `HDF5File_OpenDataset` (SUB,PRV,—); `HDF5File_IsOpen` (FN,PRV,Query); `HDF5File_GetGroup` (FN,PRV,Query); `HDF5File_GetDataset` (FN,PRV,Query); `HDF5Group_Init` (SUB,PRV,Init); `HDF5Group_Destroy` (SUB,PRV,Finalize); `HDF5Group_Open` (SUB,PRV,—); `HDF5Group_Close` (SUB,PRV,—); `HDF5Group_CreateSubgroup` (SUB,PRV,Init); `HDF5Group_OpenSubgroup` (SUB,PRV,—); `HDF5Group_CreateDataset` (SUB,PRV,Init); `HDF5Group_OpenDataset` (SUB,PRV,—); `HDF5Group_IsOpen` (FN,PRV,Query); `HDF5Dataset_Init` (SUB,PRV,Init); `HDF5Dataset_Destroy` (SUB,PRV,Finalize); `HDF5Dataset_Open` (SUB,PRV,—); `HDF5Dataset_Close` (SUB,PRV,—); `HDF5Dataset_ReadInt1` (SUB,PRV,Parse); `HDF5Dataset_ReadInt4` (SUB,PRV,Parse); `HDF5Dataset_ReadDP` (SUB,PRV,Parse); `HDF5Dataset_WriteInt1` (SUB,PRV,IO); `HDF5Dataset_WriteInt4` (SUB,PRV,IO); `HDF5Dataset_WriteDP` (SUB,PRV,IO); `HDF5Dataset_GetDims` (SUB,PRV,Query); `HDF5Dataset_IsOpen` (FN,PRV,Query); `XMLDocument_Init` (SUB,PRV,Init); `XMLDocument_Destroy` (SUB,PRV,Finalize); `XMLDocument_Load` (SUB,PRV,Parse); `XMLDocument_Save` (SUB,PRV,—); `XMLDocument_GetRoot` (FN,PRV,Query); `XMLDocument_SetRoot` (SUB,PRV,Mutate); `XMLDocument_FindElement` (FN,PRV,Query); `XMLDocument_FindElements` (FN,PRV,Query); `XMLElement_Init` (SUB,PRV,Init); `XMLElement_Destroy` (SUB,PRV,Finalize); `XMLElement_SetName` (SUB,PRV,Mutate); `XMLElement_SetText` (SUB,PRV,Mutate); `XMLElement_AddAttribute` (SUB,PRV,Mutate); `XMLElement_GetAttribute` (FN,PRV,Query); `XMLElement_AddChild` (SUB,PRV,Mutate); `XMLElement_GetChild` (FN,PRV,Query); `XMLElement_GetChildren` (FN,PRV,Query); `XMLElement_FindChild` (FN,PRV,Query); `XMLElement_FindChildren` (FN,PRV,Query); `XMLElement_ToString` (FN,PRV,—); `resize_attributes` (SUB,PRV,—); `resize_children` (SUB,PRV,—); `RW_Serialize_Int1` (SUB,PRV,—); `RW_Serialize_Int2` (SUB,PRV,—); `RW_Serialize_Int4` (SUB,PRV,—); `RW_Serialize_Int8` (SUB,PRV,—); `RW_Serialize_DP` (SUB,PRV,—); `RW_Serialize_String` (SUB,PRV,—); `RW_Serialize_ArrayInt1` (SUB,PRV,—); `RW_Serialize_ArrayInt4` (SUB,PRV,—); `RW_Serialize_ArrayDP` (SUB,PRV,—); `RW_Deserialize_Int1` (SUB,PRV,—); `RW_Deserialize_Int2` (SUB,PRV,—); `RW_Deserialize_Int4` (SUB,PUB,—); `RW_Deserialize_Int8` (SUB,PRV,—); `RW_Deserialize_DP` (SUB,PUB,—); `RW_Deserialize_String` (SUB,PRV,—); `RW_Deserialize_ArrayInt1` (SUB,PRV,—); `RW_Deserialize_ArrayInt4` (SUB,PRV,—); `RW_Deserialize_ArrayDP` (SUB,PRV,—); `RW_SymbolTable_Init` (SUB,PRV,Init); `RW_SymbolTable_Destroy` (SUB,PRV,Finalize); `RW_SymbolTable_Reg` (SUB,PRV,—); `RW_SymbolTable_Find` (FN,PRV,Query); `RW_SymbolTable_Get` (FN,PRV,Query); `RW_SymbolTable_Set` (SUB,PRV,Mutate); `RW_SymbolTable_Clear` (SUB,PRV,Mutate); `RW_SymbolTable_GetTotalSize` (FN,PRV,Query); `RW_Get_Variable` (FN,PRV,Query); `RW_Set_Variable` (SUB,PRV,Mutate); `RW_Clear_SymbolTable` (SUB,PUB,Mutate); `RW_Serializer_Init` (SUB,PRV,Init); `RW_Serializer_Destroy` (SUB,PRV,Finalize); `RW_Serializer_Open` (SUB,PRV,—); `RW_Serializer_Close` (SUB,PRV,—); `RW_Serializer_Flush` (SUB,PRV,—); `RW_Serializer_Serialize` (SUB,PRV,—); `RW_Deserializer_Init` (SUB,PRV,Init); `RW_Deserializer_Destroy` (SUB,PRV,Finalize); `RW_Deserializer_Open` (SUB,PRV,—); `RW_Deserializer_Close` (SUB,PRV,—); `RW_Deserializer_Deserialize` (SUB,PRV,—); `RW_MemMgr_Alloc` (SUB,PRV,—); `RW_MemMgr_Dealloc` (SUB,PRV,—); `RW_MemMgr_Realloc` (SUB,PRV,—); `RW_MemMgr_GetStats` (SUB,PRV,Query); `RW_MemMgr_Reset` (SUB,PRV,Mutate) |
| `MD_Base_MathUtils.f90` | `MD_BaseMathUtils` | `Timer` | `Start` (TBP,PRV,—); `Stop` (TBP,PRV,—); `Reset` (TBP,PRV,—); `IsRunning` (TBP,PRV,—); `GetElapsedTime` (TBP,PRV,—); `GetElapsedSeconds` (TBP,PRV,—); `ToUpper` (FN,PUB,—); `ToLower` (FN,PUB,—); `TrimStr` (FN,PUB,—); `SplitStr` (SUB,PUB,—); `JoinStr` (FN,PUB,—); `StrToInt` (FN,PUB,—); `StrToReal` (FN,PUB,—); `IntToStr` (FN,PUB,—); `RealToStr` (FN,PUB,—); `StrContains` (FN,PUB,—); `StrStartsWith` (FN,PUB,—); `StrEndsWith` (FN,PUB,—); `StrReplace` (FN,PUB,—); `Timer_Start` (SUB,PUB,—); `Timer_Stop` (SUB,PUB,—); `Timer_Reset` (SUB,PUB,Mutate); `Timer_IsRunning` (FN,PRV,Query); `Timer_GetElapsedTime` (FN,PRV,Query); `Timer_GetElapsedSeconds` (FN,PRV,Query); `Stopwatch_Start` (SUB,PUB,—); `Stopwatch_Stop` (SUB,PUB,—); `Stopwatch_Reset` (SUB,PUB,Mutate); `Stopwatch_Lap` (SUB,PUB,—); `Stopwatch_IsRunning` (FN,PRV,Query); `Stopwatch_GetTotalTime` (FN,PRV,Query); `Stopwatch_GetLapTime` (FN,PRV,Query); `Stopwatch_GetLapCount` (FN,PRV,Query); `Stopwatch_GetAverageLapTime` (FN,PRV,Query); `Date_Init` (SUB,PUB,Init); `Date_Set` (SUB,PUB,Mutate); `Date_Get` (SUB,PUB,Query); `DaysInMonth` (FN,PRV,—); `Date_IsValid` (FN,PRV,Query); `Date_AddDays` (SUB,PUB,Mutate); `Date_AddMonths` (SUB,PUB,Mutate); `Date_AddYears` (SUB,PUB,Mutate); `Date_Difference` (FN,PRV,—); `Date_ToString` (FN,PRV,—); `Date_FromString` (SUB,PUB,—); `Time_Init` (SUB,PUB,Init); `Time_Set` (SUB,PUB,Mutate); `Time_Get` (SUB,PUB,Query); `Time_IsValid` (FN,PRV,Query); `Time_AddSeconds` (SUB,PUB,Mutate); `Time_AddMinutes` (SUB,PUB,Mutate); `Time_AddHours` (SUB,PUB,Mutate); `Time_Difference` (FN,PRV,—); `Time_ToString` (FN,PRV,—); `Time_FromString` (SUB,PUB,—); `SortInt` (SUB,PUB,—); `SortReal` (SUB,PUB,—); `UniqueInt` (SUB,PUB,—); `UniqueReal` (SUB,PUB,—); `FindInt` (FN,PUB,—); `FindReal` (FN,PUB,—); `CountInt` (FN,PUB,—); `CountReal` (FN,PUB,—); `SumInt` (FN,PUB,—); `SumReal` (FN,PUB,—); `MeanReal` (FN,PUB,—); `StdDevReal` (FN,PUB,—); `MinInt` (FN,PUB,—); `MinReal` (FN,PUB,—); `MaxInt` (FN,PUB,—); `MaxReal` (FN,PUB,—); `smart_allocate_1d` (SUB,PRV,—); `smart_allocate_2d` (SUB,PRV,—); `smart_allocate_int1d` (SUB,PUB,—); `smart_allocate_int2d` (SUB,PUB,—); `smart_grow_real_vector` (SUB,PUB,—); `smart_grow_int_vector` (SUB,PUB,—); `smart_grow_real_Mtx` (SUB,PUB,—); `cache_array_size` (SUB,PUB,—); `get_cached_size` (FN,PUB,—); `predictive_preallocate_real1d` (SUB,PUB,—); `adaptive_growth_factor` (SUB,PUB,—); `Array_Append_Int1D` (SUB,PUB,—); `Array_Append_Int2D` (SUB,PUB,—); `Array_Append_DP1D` (SUB,PUB,—); `Array_Append_DP2D` (SUB,PUB,—); `MathUtils_Init` (SUB,PUB,Init); `MathUtils_Destroy` (SUB,PUB,Finalize); `GaussQuadrature_Init` (SUB,PUB,Init); `GaussQuadrature_Destroy` (SUB,PUB,Finalize); `GaussQuadrature_Setup` (SUB,PUB,Init); `GaussQuadrature_GetPoints` (FN,PRV,Query); `GaussQuadrature_GetWeights` (FN,PRV,Query); `VecOps_Init` (SUB,PUB,Init); `VecOps_Destroy` (SUB,PUB,Finalize); `VecOps_Dot` (FN,PRV,—); `VecOps_Norm2` (FN,PRV,—); `VecOps_Scale` (SUB,PUB,—); `VecOps_Axpy` (SUB,PUB,—); `VecOps_Add` (SUB,PUB,Mutate); `VecOps_Subtract` (SUB,PUB,—); `VecOps_Cross` (SUB,PUB,—); `Sparse_MatVec_Wrapper` (SUB,PUB,—); `vec_dot` (FN,PUB,—); `vec_axpy` (SUB,PUB,—); `vec_norm2` (FN,PUB,—); `vec_scale` (SUB,PUB,—); `vec_copy` (SUB,PUB,—); `vec_zero` (SUB,PUB,—); `vec_add` (SUB,PUB,Mutate); `vec_sub` (SUB,PUB,—); `vec_cross_3d` (SUB,PUB,—); `mat_vec` (SUB,PUB,—); `mat_mat` (SUB,PUB,—); `mat_trans` (SUB,PUB,—); `mat_inv_3x3` (SUB,PUB,—); `gauss_line` (SUB,PUB,—); `gauss_triangle` (SUB,PUB,—); `gauss_quad` (SUB,PUB,—); `gauss_tetrahedron` (SUB,PUB,—); `gauss_hexahedron` (SUB,PUB,—); `gauss_prism` (SUB,PUB,—); `gauss_pyramid` (SUB,PUB,—); `newton_raphson` (SUB,PUB,—); `f` (FN,PRV,—); `df` (FN,PRV,—); `bisection` (SUB,PUB,—); `f` (FN,PRV,—); `secant` (SUB,PUB,—); `f` (FN,PRV,—); `newton_system` (SUB,PUB,—); `f` (SUB,PRV,—); `Jacobian` (SUB,PRV,—); `gauss_seidel` (SUB,PUB,—); `jacobi_iter` (SUB,PUB,—); `interp_line` (SUB,PUB,—); `lagrange_interp` (SUB,PUB,—); `spline_interp` (SUB,PUB,—) |
| `MD_Base_ObjModel.f90` | `MD_BaseObjModel` | — | `Serialize_IF` (SUB,PRV,—); `Deserialize_IF` (SUB,PRV,—); `Init_IF` (SUB,PRV,—); `Shutdown_IF` (SUB,PRV,—); `Mgr_Init_IF` (SUB,PRV,Init); `Mgr_Final_IF` (SUB,PRV,—); `Mgr_Create_IF` (SUB,PRV,Init); `Mgr_Delete_IF` (SUB,PRV,Mutate); `Mgr_Find_IF` (FN,PRV,Query); `Mgr_Get_IF` (SUB,PRV,Query); `Mgr_GetCount_IF` (FN,PRV,Query); `Mgr_List_IF` (SUB,PRV,—); `Mgr_Valid_IF` (FN,PRV,Validate); `Mgr_ValidateConsistency_IF` (SUB,PRV,Validate); `Mgr_GetStatistics_IF` (SUB,PRV,Query); `Reg_Init_IF` (SUB,PRV,Init); `Reg_Cleanup_IF` (SUB,PRV,Finalize); `Reg_Reg_IF` (SUB,PRV,—); `Reg_Unregister_IF` (SUB,PRV,—); `Reg_Lookup_IF` (FN,PRV,Query); `Reg_Exists_IF` (FN,PRV,—); `Reg_GetCount_IF` (FN,PRV,Query); `Reg_List_IF` (SUB,PRV,—); `API_Init_IF` (SUB,PRV,Init); `API_Cleanup_IF` (SUB,PRV,Finalize); `Desc_Init_Intf` (SUB,PRV,Init); `Desc_Destroy_Intf` (SUB,PRV,Finalize); `Desc_Valid_Intf` (FN,PRV,Validate); `Desc_GetStatus_Intf` (FN,PRV,Query); `Desc_Serialize_Intf` (SUB,PRV,—); `Desc_Deserialize_Intf` (SUB,PRV,—); `State_Init_Intf` (SUB,PRV,Init); `State_Destroy_Intf` (SUB,PRV,Finalize); `State_Clear_Intf` (SUB,PRV,Mutate); `State_GetStatus_Intf` (FN,PRV,Query); `State_Serialize_Intf` (SUB,PRV,—); `State_Deserialize_Intf` (SUB,PRV,—); `Algo_Init_Intf` (SUB,PRV,Init); `Algo_Destroy_Intf` (SUB,PRV,Finalize); `Algo_Cfg_Intf` (SUB,PRV,—); `Algo_GetStatus_Intf` (FN,PRV,Query); `Algo_Serialize_Intf` (SUB,PRV,—); `Algo_Deserialize_Intf` (SUB,PRV,—); `Ctx_Init_Intf` (SUB,PRV,Init); `Ctx_Destroy_Intf` (SUB,PRV,Finalize); `Ctx_Reset_Intf` (SUB,PRV,Mutate); `Ctx_GetStatus_Intf` (FN,PRV,Query); `Ctx_Serialize_Intf` (SUB,PRV,—); `Ctx_Deserialize_Intf` (SUB,PRV,—); `RegLayout_Proc` (SUB,PRV,—); `Ensure_Proc` (SUB,PRV,—); `AlgoBase_Cfg` (SUB,PUB,—); `AlgoBase_Deserialize` (SUB,PUB,—); `AlgoBase_Destroy` (SUB,PUB,Finalize); `AlgoBase_GetCategory` (FN,PRV,Query); `AlgoBase_GetStatus` (FN,PRV,Query); `AlgoBase_GetTypeName` (FN,PRV,Query); `AlgoBase_GetVarName` (FN,PRV,Query); `AlgoBase_Init` (SUB,PUB,Init); `AlgoBase_IsAlgo` (FN,PRV,Query); `AlgoBase_Serialize` (SUB,PUB,—); `AlgoBase_SetTypeName` (SUB,PUB,Mutate); `AlgoBase_SetVarName` (SUB,PUB,Mutate); `Base_ClearBinding` (SUB,PUB,Mutate); `Base_Init` (SUB,PUB,Init); `BaseCtx_ClearStatus` (SUB,PUB,Mutate); `BaseCtx_IsError` (FN,PRV,Query); `BaseCtx_IsOK` (FN,PRV,Query); `BaseCtx_SetStatus` (SUB,PUB,Mutate); `BaseSta_ClearStatus` (SUB,PUB,Mutate); `BaseSta_GetStatus` (FN,PRV,Query); `BaseSta_IsError` (FN,PRV,Query); `BaseSta_IsOK` (FN,PRV,Query); `BaseSta_SetStatus` (SUB,PUB,Mutate); `Container_Add` (SUB,PUB,Mutate); `Container_Clean` (SUB,PUB,—); `Container_Clear` (SUB,PUB,Mutate); `Container_ExpandHashEntries` (SUB,PUB,—); `Container_Find` (FN,PRV,Query); `Container_GetAllIDs` (SUB,PUB,Query); `Container_GetByID` (FN,PRV,Query); `Container_GetByIndex` (FN,PRV,Query); `Container_GetByName` (FN,PRV,Query); `Container_GetCapacity` (FN,PRV,Query); `Container_GetCount` (FN,PRV,Query); `Container_Init` (SUB,PRV,Init); `Container_RebuildIndex` (SUB,PRV,—); `Container_Remove` (SUB,PUB,Mutate); `Container_Resize` (SUB,PRV,—); `Container_Update` (SUB,PRV,Compute); `Container_Valid` (SUB,PRV,Validate); `CtxBase_Deserialize` (SUB,PRV,—); `CtxBase_Destroy` (SUB,PRV,Finalize); `CtxBase_GetCategory` (FN,PRV,Query); `CtxBase_GetStatus` (FN,PRV,Query); `CtxBase_GetTypeName` (FN,PRV,Query); `CtxBase_GetVarName` (FN,PRV,Query); `CtxBase_Init` (SUB,PUB,Init); `CtxBase_IsCtx` (FN,PRV,Query); `CtxBase_Reset` (SUB,PRV,Mutate); `CtxBase_Serialize` (SUB,PRV,—); `CtxBase_SetTypeName` (SUB,PRV,Mutate); `CtxBase_SetVarName` (SUB,PRV,Mutate); `DescBase_Deserialize` (SUB,PUB,—); `DescBase_Destroy` (SUB,PUB,Finalize); `DescBase_GetCategory` (FN,PRV,Query); `DescBase_GetStatus` (FN,PRV,Query); `DescBase_GetTypeName` (FN,PRV,Query); `DescBase_GetVarName` (FN,PRV,Query); `DescBase_Init` (SUB,PUB,Init); `DescBase_IsDesc` (FN,PRV,Query); `DescBase_Serialize` (SUB,PUB,—); `DescBase_SetTypeName` (SUB,PUB,Mutate); `DescBase_SetVarName` (SUB,PUB,Mutate); `DescBase_Valid` (FN,PRV,Validate); `Deserial_BeginArray` (FN,PUB,—); `Deserial_BeginObject` (FN,PUB,—); `Deserial_Close` (SUB,PUB,—); `Deserial_Destroy` (SUB,PUB,Finalize); `Deserial_EndArray` (SUB,PUB,—); `Deserial_EndObject` (SUB,PUB,—); `Deserial_Init` (SUB,PUB,Init); `Deserial_Open` (SUB,PUB,—); `Deserial_ReadArrayInt` (SUB,PUB,Parse); `Deserial_ReadArrayReal` (SUB,PUB,Parse); `Deserial_ReadBool` (FN,PUB,Parse); `Deserial_ReadInt` (FN,PUB,Parse); `Deserial_ReadReal` (FN,PUB,Parse); `Deserial_ReadString` (FN,PUB,Parse); `dm_Eq` (FN,PRV,—); `dm_Free` (SUB,PRV,Finalize); `dm_Init` (SUB,PRV,Init); `dm_MakeEq` (SUB,PRV,—); `dm_Neq` (FN,PRV,—); `dm_NodeRng` (FN,PRV,—); `dm_SetNdof` (SUB,PRV,Mutate); `DofSys_Build` (SUB,PRV,Populate); `DofSys_Ensure` (SUB,PRV,—); `ds_BuildEq` (SUB,PRV,Populate); `ds_eq_of_lbl` (FN,PRV,—); `ds_eq_of_node_slot` (FN,PRV,—); `ds_Init` (SUB,PRV,Init); `ds_InitNdof` (SUB,PRV,Init); `ds_node_eq_rng` (FN,PRV,—); `ElemMatIntf_Bind` (SUB,PRV,—); `ElemMatIntf_Clean` (SUB,PRV,—); `ElemMatIntf_Init` (SUB,PRV,Init); `ElemSet_FromIds` (SUB,PUB,—); `ElemSet_Intersect` (SUB,PUB,—); `ElemSet_Subtract` (SUB,PUB,—); `ElemSet_Union` (SUB,PUB,—); `ElemStepCtx_Clean` (SUB,PRV,—); `ElemStepCtx_Init` (SUB,PRV,Init); `fs_bind` (SUB,PRV,—); `fs_get` (SUB,PRV,Query); `fs_get_ptr_1d` (SUB,PRV,Query); `fs_init` (SUB,PRV,Init); `fs_find` (FN,PRV,Query); `fd_compat` (FN,PRV,—); `fh_assoc` (FN,PRV,—); `fs_reg_f` (SUB,PRV,—); `GetCategory` (FN,PRV,—); `HashString` (FN,PUB,—); `Init_EnergyBuckets` (SUB,PUB,—); `IPState_Ensure` (SUB,PRV,—); `IPState_Init` (SUB,PRV,Init); `IPState_RegLayout` (SUB,PRV,—); `IPState_Reset` (SUB,PRV,Mutate); `IPState_Restore` (SUB,PRV,—); `IPState_Save` (SUB,PRV,—); `IPState_Update` (SUB,PRV,Compute); `Is_Elem_In_Set` (FN,PRV,Mutate); `Is_Node_In_Set` (FN,PRV,Mutate); `IsAlgo` (FN,PRV,—); `IsCtx` (FN,PRV,—); `IsDesc` (FN,PRV,—); `IsState` (FN,PRV,—); `lm_Free` (SUB,PRV,Finalize); `lm_Init` (SUB,PRV,Init); `lm_Slot` (FN,PRV,—); `ModelSys_BuildDof` (SUB,PRV,Populate); `ModelSys_SetupUIF` (SUB,PRV,Init); `move_alloc_f90` (SUB,PRV,—); `move_alloc_f90_uf` (SUB,PRV,—); `ms_init` (SUB,PRV,Init); `NodeSet_FromIds` (SUB,PUB,—); `NodeSet_Intersect` (SUB,PUB,—); `NodeSet_Subtract` (SUB,PUB,—); `NodeSet_Union` (SUB,PUB,—); `Obj_Bound` (FN,PRV,—); `Obj_Destroy` (SUB,PRV,Finalize); `Obj_GetInfo` (SUB,PRV,Query); `Obj_Id` (FN,PRV,—); `Obj_Init` (SUB,PRV,Init); `Obj_Invalidate` (SUB,PRV,—); `Obj_Name` (FN,PRV,—); `Obj_SetId` (SUB,PRV,Mutate); `Obj_SetName` (SUB,PRV,Mutate); `Obj_Valid` (FN,PRV,Validate); `Serial_BeginArray` (SUB,PUB,—); `Serial_BeginObject` (SUB,PUB,—); `Serial_Close` (SUB,PUB,—); `Serial_Destroy` (SUB,PUB,Finalize); `Serial_EndArray` (SUB,PRV,—); `Serial_EndObject` (SUB,PRV,—); `Serial_Init` (SUB,PUB,Init); `Serial_Open` (SUB,PUB,—); `Serial_WriteArrayInt` (SUB,PUB,IO); `Serial_WriteArrayReal` (SUB,PUB,IO); `Serial_WriteBool` (SUB,PUB,IO); `Serial_WriteComma` (SUB,PRV,IO); `Serial_WriteIndent` (SUB,PRV,IO); `Serial_WriteInt` (SUB,PUB,IO); `Serial_WriteReal` (SUB,PUB,IO); `Serial_WriteString` (SUB,PUB,IO); `SetTypeName` (SUB,PRV,—); `SetVarName` (SUB,PRV,—); `SortInt` (SUB,PUB,—); `StateBase_Clear` (SUB,PUB,Mutate); `StateBase_Deserialize` (SUB,PUB,—); `StateBase_Destroy` (SUB,PUB,Finalize); `StateBase_GetCategory` (FN,PRV,Query); `StateBase_GetStatus` (FN,PRV,Query); `StateBase_GetTypeName` (FN,PRV,Query); `StateBase_GetVarName` (FN,PRV,Query); `StateBase_Init` (SUB,PUB,Init); `StateBase_IsState` (FN,PRV,Query); `StateBase_Serialize` (SUB,PUB,—); `StateBase_SetTypeName` (SUB,PUB,Mutate); `StateBase_SetVarName` (SUB,PUB,Mutate); `TrimAll` (FN,PUB,—); `TypeName` (FN,PRV,—); `uf_reset` (SUB,PRV,Mutate); `uf_add_field` (SUB,PRV,Mutate); `uf_AddField` (SUB,PRV,Mutate); `uf_AttachDm` (SUB,PRV,—); `uf_field_span` (SUB,PRV,—); `uf_get_eq_span` (SUB,PRV,Query); `uf_get_field` (SUB,PRV,Query); `uf_GetEqSpan` (SUB,PRV,Query); `uf_GetField` (SUB,PRV,Query); `uf_ResetView` (SUB,PRV,Mutate); `UniqueInt` (SUB,PUB,—); `VarName` (FN,PRV,—); `CoreBase_RegLayout` (SUB,PRV,—); `CoreBase_Ensure` (SUB,PRV,—); `DescBase_RegLayout` (SUB,PRV,—); `DescBase_Ensure` (SUB,PRV,—); `StateBase_RegLayout` (SUB,PRV,—); `StateBase_Ensure` (SUB,PRV,—); `AlgoBase_RegLayout` (SUB,PRV,—); `AlgoBase_Ensure` (SUB,PRV,—); `CtxBase_RegLayout` (SUB,PRV,—); `CtxBase_Ensure` (SUB,PRV,—) |
| `MD_Base_TreeIndex.f90` | `MD_BaseTreeIndex` | `PathComponents` | `Init` (TBP,PRV,—); `Clear` (TBP,PRV,—); `GetCount` (TBP,PRV,—); `GetComponent` (TBP,PRV,—); `IsAbsolute` (TBP,PRV,—); `ParsePath_IF` (SUB,PRV,—); `GetNodeID_IF` (FN,PRV,—); `GetNodeName_IF` (FN,PRV,—); `GetNodeType_IF` (FN,PRV,—); `GetParentID_IF` (FN,PRV,—); `PathComponents_Init` (SUB,PRV,Init); `PathComponents_Clear` (SUB,PRV,Mutate); `PathComponents_GetCount` (FN,PRV,Query); `PathComponents_GetComponent` (FN,PRV,Query); `PathComponents_IsAbsolute` (FN,PRV,Query); `LazyIndex_Init` (SUB,PRV,Init); `LazyIndex_MarkDirty` (SUB,PRV,—); `LazyIndex_RebuildIfDirty` (SUB,PRV,—); `LazyIndex_ForceRebuild` (SUB,PRV,—); `LazyIndex_IsDirty` (FN,PRV,Query); `LazyIndex_SetAutoRebuild` (SUB,PRV,Mutate); `LazyIdx_SetRebuildThresh` (SUB,PRV,Mutate); `MemPool_Init` (SUB,PRV,Init); `MemPool_Destroy` (SUB,PRV,Finalize); `MemPool_Allocate` (FN,PRV,—); `MemPool_Deallocate` (SUB,PRV,Finalize); `MemPool_GetFreeCount` (FN,PRV,Query); `MemPool_GetPoolSize` (FN,PRV,Query); `MemPool_Clear` (SUB,PRV,Mutate); `BatchOp_BeginBatch` (SUB,PRV,—); `BatchOp_EndBatch` (SUB,PRV,—); `BatchOp_IsBatchMode` (FN,PRV,Query); `BatchOp_IncrementBatch` (SUB,PRV,—); `BatchOp_SetMaxBatchSize` (SUB,PRV,Mutate); `TreeNode_SetParentID` (SUB,PRV,Mutate); `TreeNode_SetActive` (SUB,PRV,Mutate); `TreeNode_SetVisible` (SUB,PRV,Mutate); `TreeNode_IsActive` (FN,PRV,Query); `TreeNode_IsVisible` (FN,PRV,Query); `TreeNode_GetPath` (FN,PRV,Query); `TreeNode_GetFullPath` (FN,PRV,Query); `TreeNode_Valid` (FN,PRV,Validate); `TreeNodeType_Init` (SUB,PRV,Init); `TreeNodeType_GetCode` (FN,PRV,Query); `TreeNodeType_SetCode` (SUB,PRV,Mutate); `TreeNodeType_IsModel` (FN,PRV,Query); `TreeNodeType_IsPart` (FN,PRV,Query); `TreeNodeType_IsAssembly` (FN,PRV,Query); `TreeNodeType_IsMaterial` (FN,PRV,Query); `TreeNodeType_IsSection` (FN,PRV,Query); `TreeNodeType_IsMesh` (FN,PRV,Query); `TreeNodeType_IsAmplitude` (FN,PRV,Query); `TreeNodeType_IsLoadBC` (FN,PRV,Query); `TreeNodeType_IsInteraction` (FN,PRV,Query); `TreeNodeType_IsStep` (FN,PRV,Query); `TreeNodeType_IsNode` (FN,PRV,Query); `TreeNodeType_IsElement` (FN,PRV,Query); `TreeNodeType_IsNodeSet` (FN,PRV,Query); `TreeNodeType_IsElemSet` (FN,PRV,Query); `TreeNodeType_IsSurface` (FN,PRV,Query); `TreeNode_ResolvePath` (SUB,PRV,—); `TreeNode_ParsePath` (SUB,PRV,Parse); `TreeNode_Serialize` (SUB,PRV,—); `TreeNode_Deserialize` (SUB,PRV,—); `TreeNode_SetIndexMgr` (SUB,PRV,Mutate); `TreeNode_SetLazyIndex` (SUB,PRV,Mutate); `TreeNode_UpdateIndex` (SUB,PRV,Compute); `TreeNode_SetBatchMgr` (SUB,PRV,Mutate); `TreeNode_BeginBatch` (SUB,PRV,—); `TreeNode_EndBatch` (SUB,PRV,—); `TreeNode_SetPathResolver` (SUB,PRV,Mutate); `IDList_Init` (SUB,PRV,Init); `IDList_Add` (SUB,PRV,Mutate); `IDList_Remove` (SUB,PRV,Mutate); `IDList_Contains` (FN,PRV,—); `IDList_Clear` (SUB,PRV,Mutate); `IDList_GetCount` (FN,PRV,Query); `IDList_GetIDs` (FN,PRV,Query); `ParentChildMap_Init` (SUB,PRV,Init); `ParentChildMap_AddChild` (SUB,PRV,Mutate); `ParentChildMap_RemoveChild` (SUB,PRV,Mutate); `ParentChildMap_GetChildren` (FN,PRV,Query); `ParentChildMap_Clear` (SUB,PRV,Mutate); `ParentChildMap_GetCount` (FN,PRV,Query); `ParentChildMap_FindEntry` (FN,PRV,Query); `ParentChildMap_Expand` (SUB,PRV,—); `IndexMgr_Init` (SUB,PRV,Init); `IndexMgr_Finalize` (SUB,PRV,Finalize); `IndexMgr_Clean` (SUB,PRV,—); `IndexMgr_Create` (SUB,PRV,Init); `IndexMgr_Delete` (SUB,PRV,Mutate); `IndexMgr_Find` (FN,PRV,Query); `IndexMgr_Get` (SUB,PRV,Query); `IndexMgr_GetCount` (FN,PRV,Query); `IndexMgr_List` (SUB,PRV,—); `IndexMgr_ValidateConsistency` (SUB,PRV,Validate); `IndexMgr_GetStatistics` (SUB,PRV,Query); `IndexMgr_Reg` (SUB,PRV,—); `IndexMgr_Unregister` (SUB,PRV,—); `IndexMgr_FindByID` (FN,PRV,Query); `IndexMgr_FindByName` (FN,PRV,Query); `IndexMgr_FindByType` (FN,PRV,Query); `IndexMgr_FindChildren` (FN,PRV,Query); `IndexMgr_UpdateParent` (SUB,PRV,Compute); `IndexMgr_Rebuild` (SUB,PRV,—); `IndexMgr_Clear` (SUB,PRV,Mutate); `IndexMgr_Valid` (FN,PRV,Validate); `Resolver_ParsePath` (SUB,PRV,Parse); `Resolver_ResolvePath` (FN,PRV,—); `Resolver_BuildPath` (FN,PRV,Populate); `Resolver_ValidatePath` (SUB,PRV,Validate); `Resolver_NormalizePath` (FN,PRV,—); `Resolver_JoinPath` (FN,PRV,—); `Resolver_ParseComponent` (SUB,PRV,Parse) |
| `MD_BaseTypes.f90` | `MD_Kernel_Mesh_Types` | `MD_ElemDef_Type`, `MD_NodeTbl_Type`, `MD_ElemTbl_Type`, `MD_ElemDefTbl_Type`, `MD_MeshCtrl_Type`, `MD_MatDef_Type`, `MD_MatLib_Type`, `MD_MatAssign_Type`, `MD_MatCtrl_Type`, `MD_SectDef_Type`, `MD_SectCtrl_Type`, `MD_NodeSet_Type`, `MD_ElemSet_Type`, `MD_SetCtrl_Type`, `MD_AmpDef_Type`, `MD_AmpCtrl_Type`, `MD_StepCfg_Type`, `MD_StepDef_Type`, `MD_ModelCtrl_Type` | — |
| `MD_BaseTypes.f90` | `MD_Model_Kernel_Types` | — | — |
| `MD_BaseTypes.f90` | `MD_Element_Types` | `ShapeFuncResult` | `Init` (TBP,PRV,—); `Clear` (TBP,PRV,—); `ShapeFuncResult_Init` (SUB,PRV,Init); `ShapeFuncResult_Clear` (SUB,PRV,Mutate) |
| `MD_BaseTypes.f90` | `MD_Element_Base` | `UF_ElemFormul`, `UF_ElemType`, `UF_ElemCtx`, `UF_ElemFlags` | — |
| `MD_BaseTypes.f90` | `MD_TypeSystem` | `State_Instance` | — |
| `MD_Base_Def.f90` | `MD_Base_Def` | `MD_NodeTbl_Type`, `MD_ElemTbl_Type`, `MD_ElemDef_Type`, `MD_ElemDefTbl_Type`, `MD_MeshCtrl_Type`, `MD_MatDef_Type`, `MD_MatLib_Type`, `MD_MatAssign_Type`, `MD_MatCtrl_Type`, `MD_SectDef_Type`, `MD_SectCtrl_Type`, `MD_NodeSet_Type`, `MD_ElemSet_Type`, `MD_Surface_Type`, `MD_SetCtrl_Type`, `MD_AmpDef_Type`, `MD_AmpCtrl_Type`, `MD_StepCfg_Type`, `MD_StepDef_Type`, `MD_MPC_Constraint_Type`, `MD_Eq_Constraint_Type`, `MD_Coupling_Constraint_Type`, `MD_RigidBody_Constraint_Type`, `MD_ConstCtrl_Type`, `MD_Part_Type`, `MD_Instance_Type`, `MD_Assembly_Type`, `MD_PartCtrl_Type`, `MD_ModelCtrl_Type` | `MD_ModelCtrl_Init` (SUB,PUB,Init); `MD_ModelCtrl_Free` (SUB,PUB,Finalize); `MD_ModelCtrl_Free_LocalMesh` (SUB,PRV,Finalize) |
| `MD_Kinematics_Def.f90` | `MD_Kinematics_Def` | `KinematicsMeta`, `KinematicsTime`, `KinematicsTemp`, `KinematicsMech`, `KinematicsThermal`, `UF_Kinematics` | — |
| ~~`MD_Model.f90`~~ | — | — | **历史占位行**：旧 `MD_ModelDomain`；**以 `MD_Model_Mgr.f90` + `MD_Model_Def.f90` 为真源**（见 §二） |
| `MD_Model_Access.f90` | `MD_Model_Access` | — | `MD_Model_Access_GetMaterial` (FN,PUB,Query); `MD_Model_Access_GetMaterialID` (FN,PUB,Query); `MD_Model_Access_GetMatNameFromSect` (FN,PUB,Query); `MD_Model_Access_GetSection` (FN,PUB,Query) |
| `MD_Model_Builder.f90` | `MD_Model_Builder` | `MD_Model_Builder_Build_Desc`, `MD_Model_Builder_Build_Algo`, `MD_Model_Builder_Build_Ctx`, `MD_Model_Builder_Build_State`, `MD_Model_Builder_Build_In`, `MD_Model_Builder_Build_Out` | `MD_Model_Builder_Build` (SUB,PUB,Populate); `UF_build_model_from_inp` (SUB,PUB,Populate) |
| `MD_Model_Coord_Transform.f90` | `MD_Model_Coord_Transform` | `TransformProps`, `TransformPropsMgr` | `Parse_TRANSFORM_Keyword`；校验子程序；**`MD_Model_Coord_Transform_Parse` / `MD_Model_Coord_Transform_Cfg`**；内部 `xfm_*` |
| `MD_Model_Coord_Sys.f90` | `MD_Model_Coord_Sys` | `SystemProps` | `Parse_SYSTEM_Keyword`；校验子程序；**`MD_Model_Coord_Sys_Parse` / `MD_Model_Coord_Sys_Cfg`**；`sys_*` |
| `MD_Model_Coord_Orient.f90` | `MD_Model_Coord_Orient` | `OrientProps`, `OrientPropsManager` | `Parse_ORIENTATION_Keyword`；**`MD_Model_Coord_Orient_Parse` / `MD_Model_Coord_Orient_Cfg`** |
| `MD_Model_Coord_Normal.f90` | `MD_Model_Coord_Normal` | `NormalProps` 等 | `Parse_NORMAL_Keyword`；**`MD_Model_Coord_Normal_Parse` / `MD_Model_Coord_Normal_Cfg`** |
| `MD_Model_Data_Table.f90` | `MD_Model_Data_Table` | `TableEntry`, `TableProperties`, `TablePropertiesManager` | `Parse_TABLE_Keyword`；`Valid_TABLE_Keyword`；**`MD_Model_Data_Table_Parse` / `MD_Model_Data_Table_Cfg`**；TBP/管理器例程 |
| `MD_Model_Data_Param.f90` | `MD_Model_Data_Param` | `ParameterEntry`, `ParameterProperties` | `Parse_Param_Keyword`；`Valid_Param_Keyword`；**`MD_Model_Data_Param_Parse` / `MD_Model_Data_Param_Cfg`** |
| `MD_Model_Data_Field.f90` | `MD_Model_Data_Field` | `FieldDataEntry`, `FieldProperties` | `Parse_FIELD_Keyword`；`Valid_FIELD_Keyword`；**`MD_Model_Data_Field_Parse` / `MD_Model_Data_Field_Cfg`** |
| `MD_Model_Data_Dist.f90` | `MD_Model_Data_Dist` | `DistributionProperties`, `MD_MODEL_DIST_LOCATION_*` | `Parse_DISTRIBUTION_Keyword`；`Valid_DISTRIBUTION_Keyword`；`Validate_Distribution_TableReference`；**`MD_Model_Data_Dist_Parse` / `MD_Model_Data_Dist_Cfg`** |
| `MD_Model_Data_Variable.f90` | `MD_Model_Data_Variable` | `VariableProperties` | `Parse_VARIABLE_Keyword`；`Valid_VARIABLE_Keyword`；**`MD_Model_Data_Variable_Parse` / `MD_Model_Data_Variable_Cfg`** |
| `MD_Model_Data_Filter.f90` | `MD_Model_Data_Filter` | `FilterProperties` | `Parse_FILTER_Keyword`；`Valid_FILTER_Keyword`；**`MD_Model_Data_Filter_Parse` / `MD_Model_Data_Filter_Cfg`** |
| `MD_Model_Data_PhysConst.f90` | `MD_Model_Data_PhysConst` | `PhysicalConstantsProperties` | `PhysicalConstants_Parse_Keyword`；`PhysicalConstants_Validate_Keyword`；**`MD_Model_Data_PhysConst_Parse` / `MD_Model_Data_PhysConst_Cfg`** |
| `MD_Model_Mgr.f90` | `MD_Model_Mgr` | `MD_Model_Domain`, `MD_Model_Ctx`, **`MD_Model_AdvProps`** | 域/`Ctx` TBP 与 `MD_Model_Domain_*`、`MD_Model_Ctx_*`；**`MD_Model_AdvProps_*`**（Import/Prestress/Substructure 容器） |
| `MD_Model_Core.f90` | `MD_Model_Core` | — | `MD_Model_Core_Init`; `MD_Model_Core_Finalize`; `MD_Model_Core_Set_Name`; `MD_Model_Core_Get_NDim`; `MD_Model_Core_Register_Part`; `MD_Model_Core_Register_Step`; `MD_Model_Core_Get_N_Parts`; `MD_Model_Core_Get_N_Steps`; `MD_Model_Core_Validate_All`; `MD_Model_Core_Summary` — **操作 `MD_Model_Def` 轻量 Desc** |
| `MD_Model_Lib_Core.f90` | `MD_Model_Lib_Core` | `Desc_Model`, `UF_ModelVarContext`, … | `MD_Model_*` 统计/校验；**`MD_Theory_Query` / `MD_Theory_Describe`**（及 `MD_Theory_QueryByIndex` 等）；`Model_FromDesc*`；VarCtx 辅助例程 |
| `MD_Model_Import.f90` | `MD_Model_Import` | `ImportProperties`, `ImportResults` | `Parse_IMPORT_Keyword`；**`MD_Model_Import_Parse` / `MD_Model_Import_Cfg`**；TBP/工具例程 |
| `MD_Model_Prestress.f90` | `MD_Model_Prestress` | `PrestressProperties`, `PrestressResults` | `Parse_PRESTRESS_Keyword`；**`MD_Model_Prestress_Parse` / `MD_Model_Prestress_Cfg`**；TBP/工具例程 |
| `MD_Model_Substruct.f90` | `MD_Model_Substruct` | `SubstructureProperties`, `SubstructureResults` | `Parse_SUBSTRUCTURE_*_Keyword`；**`MD_Model_Substruct_Parse` / `MD_Model_Substruct_Cfg`**；TBP/工具例程 |
| `MD_Model_Reg.f90` | `MD_Model_Reg` | `AdvFeatureRegistryEntry` | `Reg_Advanced_Features` (SUB,PUB,—); `Valid_Advanced_Reg` (SUB,PUB,—); `Get_Advanced_Feature_Count` (FN,PUB,Query); `Print_Advanced_Reg_Status` (SUB,PUB,—) |
| `MD_Model_Tree.f90` | `MD_Model_Tree` | `ModelTree` | — |
| `MD_Model_Types.f90` | `MD_ModelTypes` | — | — |
| `MD_Model_Def.f90` | `MD_Model_Def` | `ModelDesc` | `RegLayout` (TBP,PRV,—); `Ensure` (TBP,PRV,—); `Init` (TBP,PRV,—); `ModelDesc_Init` (SUB,PRV,Init); `ModelDesc_RegLayout` (SUB,PRV,—); `ModelDesc_Ensure` (SUB,PRV,—); `ModelState_Init` (SUB,PRV,Init); `ModelState_RegLayout` (SUB,PRV,—); `ModelState_Ensure` (SUB,PRV,—); `ModelAlgo_Init` (SUB,PRV,Init); `ModelAlgo_RegLayout` (SUB,PRV,—); `ModelAlgo_Ensure` (SUB,PRV,—); `ModelCtx_Init` (SUB,PRV,Init); `ModelCtx_RegLayout` (SUB,PRV,—); `ModelCtx_Ensure` (SUB,PRV,—); `GlobalState_Init` (SUB,PRV,Init); `GlobalState_RegLayout` (SUB,PRV,—); `GlobalState_Ensure` (SUB,PRV,—); `JobDesc_Init` (SUB,PRV,Init); `JobDesc_RegLayout` (SUB,PRV,—); `JobDesc_Ensure` (SUB,PRV,—); `AnalysisCtx_Init` (SUB,PRV,Init); `AnalysisCtx_RegLayout` (SUB,PRV,—); `AnalysisCtx_Ensure` (SUB,PRV,—) |
