# UFC 结构体与理论参考索引

> **文档位置**：`UFC/docs/UFC_结构体与理论参考索引.md`  
> **版本**：v1.0  
> **最后更新**：2026-04-15  
> **用途**：跨层结构体（TYPE）速查 + 理论文档定位索引，供导航文档引用。

---

## 1. 概述

本文档是 UFC 六层架构中 **L3_MD / L4_PH / L5_RT** 三层核心结构体（Fortran TYPE）的集中索引，同时建立结构体与理论推导文档的交叉引用关系。

**使用方式**：

- 查找某 TYPE 定义位置 → 直接检索第 2–4 节表格
- 查找某理论专题文档 → 检索第 5 节
- 了解 ABAQUS 概念映射 → 查阅第 6 节
- 了解与其他规范文档的关系 → 查阅第 7 节

**四类 TYPE 约定（全架构统一）**：


| 类型    | 缩写   | 职责                     |
| ----- | ---- | ---------------------- |
| Desc  | 描述型  | 输入参数、模型定义、静态元数据（建模期写入） |
| State | 状态型  | 步内可变量：应力、应变、内变量、收敛状态   |
| Algo  | 算法型  | 积分策略、迭代控制、数值参数         |
| Ctx   | 上下文型 | 运行时临时引用束：索引、句柄、缓存指针    |


---

## 2. L3_MD 层结构体索引

L3_MD 为模型定义层，存放前处理数据的真相源（Desc 为主）。

### 2.1 Model 域


| 结构体名          | 定义模块/文件              | 职责                     | 理论参考          |
| ------------- | -------------------- | ---------------------- | ------------- |
| `ModelDesc`   | `MD_Model_Types.f90` | 模型级描述：名称、维数、分析类型、子域计数  | § 5.1 有限元软件架构 |
| `ModelState`  | `MD_Model_Types.f90` | 模型状态标记（isBuilt 等白名单字段） | —             |
| `ModelAlgo`   | `MD_Model_Types.f90` | 模型级算法参数                | —             |
| `ModelCtx`    | `MD_Model_Types.f90` | 模型运行上下文引用束             | —             |
| `AnalysisCtx` | `MD_Model_Types.f90` | 分析上下文（分析类型枚举等）         | § 5.1         |
| `GlobalState` | `MD_Model_Types.f90` | 全局求解状态                 | —             |
| `JobDesc`     | `MD_Model_Types.f90` | 作业描述（Job 级元数据）         | —             |
| `Model`       | `MD_Model_Types.f90` | 模型容器聚合型                | § 5.1         |
| `Job`         | `MD_Model_Types.f90` | 作业容器聚合型                | —             |


> 合同卡：`L3_MD/Model/CONTRACT.md`

### 2.2 Mesh 域


| 结构体名            | 定义模块/文件            | 职责                      | 理论参考             |
| --------------- | ------------------ | ----------------------- | ---------------- |
| `MeshNodeDesc`  | `MD_Mesh_Node.f90` | 节点描述：坐标、ID、边界标志         | § 5.2 连续介质力学     |
| `MeshNodeState` | `MD_Mesh_Node.f90` | 节点状态：位移、速度、加速度          | § 5.2、§ 5.7 时间积分 |
| `MD_Node_Type`  | `MD_Node.f90`      | 节点类型（扩展 DescBase）：坐标、约束 | § 5.2            |
| `MD_Node_State` | `MD_Node.f90`      | 节点状态（扩展 StateBase）      | § 5.7            |


> 合同卡：`L3_MD/Mesh/CONTRACT_Mesh.md`（引用）

### 2.3 Element 域


| 结构体名                 | 定义模块/文件             | 职责                                | 理论参考        |
| -------------------- | ------------------- | --------------------------------- | ----------- |
| `MD_Elem_Base_Desc`  | `MD_Elem_Types.f90` | 单元描述：类型 ID（C3D8 等）、节点数、DOF 数、积分点数 | § 5.5 单元理论  |
| `MD_Elem_Base_Algo`  | `MD_Elem_Types.f90` | 单元算法参数：沙漏控制类型、质量矩阵类型              | § 5.5       |
| `MD_Elem_Base_Ctx`   | `MD_Elem_Types.f90` | 单元上下文：步内引用句柄                      | —           |
| `MD_Elem_Base_State` | `MD_Elem_Types.f90` | 单元状态：应力、应变（WriteBack 白名单）         | § 5.3 有限元方法 |


> 合同卡：`L3_MD/Element/`（域内 CONTRACT 见 L4 侧）

### 2.4 Interaction / Contact 域


| 结构体名                      | 定义模块/文件                    | 职责                    | 理论参考        |
| ------------------------- | -------------------------- | --------------------- | ----------- |
| `MD_ContactPairDef`       | `MD_Interaction_Types.f90` | 接触对定义：主从面 ID、接触属性名引用  | —           |
| `MD_ContactProperty_Type` | `MD_Interaction_Types.f90` | 接触属性：算法类型码（罚、增广拉格朗日等） | § 5.6 非线性求解 |


> 合同卡：`L3_MD/Interaction/CONTRACT.md`

---

## 3. L4_PH 层结构体索引

L4_PH 为物理实现层，承载单元公式、材料本构、接触算法的四类 TYPE。

### 3.1 Material 域


| 结构体名                               | 定义模块/文件                        | 职责                               | 理论参考          |
| ---------------------------------- | ------------------------------ | -------------------------------- | ------------- |
| `PH_Mat_Slot`                 | `PH_Mat_Domain_Core.f90`  | 材料槽：聚合 ctx（props/matId/matModel） | § 5.4 材料本构    |
| `PH_Mat_State`                | `PH_Mat_*_Core.f90`            | 材料状态：应力 σ、切线 C_tan、SDV、SDV_n     | § 5.4         |
| `PH_Mat_Ctx`                  | `PH_Mat_Domain_Core.f90`      | 材料上下文：步进/增量与局部计算嵌套（`%inc` / `%lcl`） | § 5.4         |
| `PH_Mat_Algo`                 | `PH_Mat_Domain_Core.f90`      | 积分格式、子步容差、有限应变开关（Algo 角色，`PH_Mat_Slot%algo`） | § 5.4         |
| `PH_Mat_Eval_Arg`             | `PH_Mat_Domain_Core.f90`      | 本构评估 SIO 参数包（`inp`/`out`，含 status 传播） | § 5.4         |
| `PH_Mat_State_DualWrite_*`    | `PH_Mat_Domain_Core.f90`      | 应力/切线/SDV 双轨写入口（嵌套 `PH_Mat_State` 与扁平遗留字段同步） | § 5.4         |
| `PH_UMAT_Context`                  | `PH_Mat_Core_UMAT_Adapter.f90` | UMAT 上下文：ABAQUS UMAT 接口参数映射      | § 6 ABAQUS 对标 |


> 合同卡：`L4_PH/Material/CONTRACT.md`

### 3.2 Element 域


| 结构体名                             | 定义模块/文件                      | 职责                                     | 理论参考        |
| -------------------------------- | ---------------------------- | -------------------------------------- | ----------- |
| `PH_Elem_Base_Ctx`               | `PH_Elem_Types.f90`          | 单元上下文：mat_ctx 嵌入、elem_type_id、Gauss 规则 | § 5.5       |
| `GaussRule`                      | `PH_Elem_Types.f90`          | 高斯积分规则：积分点数、权重、坐标                      | § 5.3、§ 5.5 |
| `PH_Mat_Base_Ctx`                | `PH_Mat_Types.f90`           | 材料上下文基类（被 PH_Elem_Base_Ctx 嵌入）         | § 5.4       |
| `PH_Element_Compute_Ke_Arg`      | `PH_Element_Domain_Core.f90` | Ke 计算 *_Arg：l3_elem_idx、nDof、Ke、status | § 5.3       |
| `PH_Element_Compute_Fe_Arg`      | `PH_Element_Domain_Core.f90` | Fe 计算 *_Arg：等效节点力                      | § 5.3       |
| `PH_Element_Compute_BMatrix_Arg` | `PH_Element_Domain_Core.f90` | B 矩阵计算参数包                              | § 5.3、§ 5.5 |


> 合同卡：`L4_PH/Element/CONTRACT.md`

### 3.3 Contact 域


| 结构体名                    | 定义模块/文件                     | 职责                       | 理论参考        |
| ----------------------- | --------------------------- | ------------------------ | ----------- |
| `PH_Cont_Desc`          | `PH_Cont_Types.f90`         | 接触域描述聚合（含约束/摩擦/搜索子 Desc） | § 5.6       |
| `PH_Cont_Constr_Desc`   | `PH_Cont_Types.f90`         | 接触约束描述：罚刚度、间隙容差          | § 5.6       |
| `PH_Cont_Friction_Desc` | `PH_Cont_Types.f90`         | 摩擦描述：摩擦系数、库仑模型参数         | § 5.6       |
| `PH_Cont_Search_Desc`   | `PH_Cont_Types.f90`         | 接触搜索描述：搜索半径、面面/点面切换      | —           |
| `PH_Cont_Algo`          | `PH_Cont_Types.f90`         | 接触算法聚合（含约束/摩擦子 Algo）     | § 5.6       |
| `PH_Cont_Constr_Algo`   | `PH_Cont_Types.f90`         | 接触约束算法：增广拉格朗日参数、罚法参数     | § 5.6       |
| `PH_Cont_Friction_Algo` | `PH_Cont_Types.f90`         | 摩擦算法参数                   | § 5.6       |
| `PH_Contact_Base_Ctx`   | `PH_Cont_Types.f90`         | 接触基础上下文                  | —           |
| `PH_Thermal_Cont_Desc`  | `PH_Thermal_Cont_Types.f90` | 热接触描述：热导率、热阻             | § 5.4（多场耦合） |
| `PH_Thermal_Cont_State` | `PH_Thermal_Cont_Types.f90` | 热接触状态：热流量                | —           |
| `PH_Thermal_Cont_Algo`  | `PH_Thermal_Cont_Types.f90` | 热接触算法参数                  | —           |
| `PH_Thermal_Cont_Ctx`   | `PH_Thermal_Cont_Types.f90` | 热接触上下文                   | —           |


> 合同卡：`L4_PH/Contact/CONTRACT_Contact.md`（引用）

---

## 4. L5_RT 层结构体索引

L5_RT 为运行时层，以 Ctx 为主，Solver/StepDriver 域含完整四类 TYPE。

### 4.1 公共运行时 TYPE


| 结构体名              | 定义模块/文件              | 职责                                               | 理论参考        |
| ----------------- | -------------------- | ------------------------------------------------ | ----------- |
| `RT_Com_Base_Ctx` | `RT_Com_Types.f90`   | 公共运行时上下文：时间/步/增量步信息、分析类型标志、UEL 参数（ndload、lflags） | § 5.7       |
| `RT_CSRMatrix`    | `RT_Shared_Type.f90` | CSR 稀疏矩阵结构：ia/ja/val 三数组                         | § 5.3 有限元组装 |


### 4.2 StepDriver 域


| 结构体名                    | 定义模块/文件                   | 职责                                       | 理论参考        |
| ----------------------- | ------------------------- | ---------------------------------------- | ----------- |
| `RT_StepDriver_Desc`    | `RT_StepDriver_Types.f90` | 分析步描述：步类型、时间配置（嵌套 TimeCfg）               | § 5.1、§ 5.7 |
| `RT_StepDriver_State`   | `RT_StepDriver_Types.f90` | 步内状态：当前时间、增量编号、收敛标志                      | § 5.7       |
| `RT_StepDriver_Algo`    | `RT_StepDriver_Types.f90` | 步控制算法：自动时步、收敛准则、最大迭代数                    | § 5.6 非线性求解 |
| `RT_StepDriver_Ctx`     | `RT_StepDriver_Types.f90` | 步运行上下文：Solver/Assembly 引用句柄              | —           |
| `RT_StepDriver_TimeCfg` | `RT_StepDriver_Types.f90` | 时间配置辅助型：t_start、t_end、dt_init、dt_min/max | § 5.7       |


> 合同卡：`L5_RT/StepDriver/CONTRACT.md`

### 4.3 Assembly 域


| 结构体名           | 定义模块/文件            | 职责                         | 理论参考  |
| -------------- | ------------------ | -------------------------- | ----- |
| `RT_Asm_Desc`  | `RT_Asm_Types.f90` | 组装描述：DoF 映射表、CSR 结构、约束类型列表 | § 5.3 |
| `RT_Asm_State` | `RT_Asm_Types.f90` | 组装状态：非零元计数、约束激活状态、装配进度     | § 5.3 |
| `RT_Asm_Algo`  | `RT_Asm_Types.f90` | 组装算法：装配策略（行式/列式）、稀疏格式、并行调度 | § 5.3 |


> 合同卡：`L5_RT/Assembly/CONTRACT.md`

### 4.4 Solver 域


| 结构体名                | 定义模块/文件             | 职责                                 | 理论参考  |
| ------------------- | ------------------- | ---------------------------------- | ----- |
| `RT_Solv_Types`（聚合） | `RT_Solv_Types.f90` | 求解器描述：类型（Direct/Iterative）、容差、最大迭代 | § 5.6 |
| `RT_Solv_Type`（辅助）  | `RT_Solv_Type.f90`  | 求解器类型枚举与辅助型                        | § 5.6 |


> 合同卡：`L5_RT/Solver/CONTRACT.md`

---

## 5. 理论参考索引

### 5.1 架构层理论文档


| 编号   | 理论专题      | 文档路径                                        | 关联结构体                                                           |
| ---- | --------- | ------------------------------------------- | --------------------------------------------------------------- |
| T-01 | 有限元软件标准架构 | `docs/六层架构拆分/01-理论基础/01-01-有限元软件标准架构.md`    | `ModelDesc`、`JobDesc`、`RT_Com_Base_Ctx`                         |
| T-02 | 计算力学理论基础  | `docs/六层架构拆分/01-理论基础/01-02-计算力学理论基础.md`     | `MeshNodeDesc`、`PH_Mat_State`                              |
| T-03 | 符号约定与基本概念 | `docs/六层架构拆分/01-理论基础/01-03-01-符号约定与基本概念.md` | 全架构                                                             |
| T-04 | 连续介质力学理论  | `docs/六层架构拆分/01-理论基础/01-03-02-连续介质力学理论.md`  | `MeshNodeDesc`、`MeshNodeState`、`PH_Mat_State`              |
| T-05 | 有限元方法理论   | `docs/六层架构拆分/01-理论基础/01-03-03-有限元方法理论.md`   | `RT_Asm_Desc`、`PH_Element_Compute_Ke_Arg`、`RT_CSRMatrix`        |
| T-06 | 材料本构理论    | `docs/六层架构拆分/01-理论基础/01-03-04-材料本构理论.md`    | `PH_Mat_State`、`PH_Mat_Ctx`、`PH_Mat_Algo`      |
| T-07 | 单元理论      | `docs/六层架构拆分/01-理论基础/01-03-05-单元理论.md`      | `MD_Elem_Base_Desc`、`PH_Elem_Base_Ctx`、`GaussRule`              |
| T-08 | 非线性求解理论   | `docs/六层架构拆分/01-理论基础/01-03-06-非线性求解理论.md`   | `RT_StepDriver_Algo`、`RT_Solv_Types`、`PH_Cont_Constr_Algo`      |
| T-09 | 时间积分理论    | `docs/六层架构拆分/01-理论基础/01-03-07-时间积分理论.md`    | `RT_StepDriver_TimeCfg`、`RT_StepDriver_State`、`RT_Com_Base_Ctx` |
| T-10 | 计算架构变量推导  | `docs/六层架构拆分/01-理论基础/01-04-计算架构变量推导.md`     | 跨层 Desc/State/Algo/Ctx 全体                                       |


### 5.2 深度理论推导文档


| 编号   | 理论专题          | 文档路径                                                                             | 关联结构体                                          |
| ---- | ------------- | -------------------------------------------------------------------------------- | ---------------------------------------------- |
| T-11 | EAS 增强应变模式    | `docs/05_Project_Planning/PPLAN/08_理论推导/EAS_Theory_Review_v1.md`                 | `PH_Elem_Base_Ctx`、`PH_Element_Compute_Ke_Arg` |
| T-12 | F-bar 选择性减缩积分 | `docs/05_Project_Planning/PPLAN/08_理论推导/Fbar_Theory_Review_v1.md`                | `PH_Elem_Base_Ctx`、`GaussRule`                 |
| T-13 | 几何非线性 TL/UL   | `docs/05_Project_Planning/PPLAN/08_理论推导/Geometric_Nonlinear_Theory_Review_v1.md` | `PH_Mat_State`（C_tan）、`RT_Asm_NLGeom_`*   |


### 5.3 L4 物理层专项文档


| 编号   | 理论专题        | 文档路径                                                   | 关联结构体                                                           |
| ---- | ----------- | ------------------------------------------------------ | --------------------------------------------------------------- |
| T-14 | 本构模型体系      | `docs/六层架构拆分/04-六层架构拆解/L4_PH-物理层/L4-02-本构模型体系.md`      | `PH_Mat_State`、`PH_Mat_Ctx`、`PH_Mat_Algo`      |
| T-15 | BEAM 单元族参考  | `docs/六层架构拆分/04-六层架构拆解/L4_PH-物理层/L4-03-BEAM单元族完整参考.md` | `MD_Elem_Base_Desc`（BEAM 族）、`PH_Elem_Base_Ctx`                  |
| T-16 | L5 Step 分析步 | `docs/六层架构拆分/04-六层架构拆解/L5_RT-运行时层/L5-02-Step分析步.md`    | `RT_StepDriver_Desc`、`RT_StepDriver_State`、`RT_StepDriver_Algo` |
| T-17 | 分析类型完整手册    | `docs/六层架构拆分/04-六层架构拆解/L5_RT-运行时层/L5-06-分析类型完整手册.md`   | `RT_Com_Base_Ctx`（analysis_type 枚举）、`RT_StepDriver_Desc`        |


---

## 6. ABAQUS 对标说明

UFC 结构体与 ABAQUS 输入文件/求解器概念的映射关系。


| ABAQUS 概念                  | UFC 对应结构体                                      | 所在层   | 说明                               |
| -------------------------- | ---------------------------------------------- | ----- | -------------------------------- |
| `*MODEL` / Job             | `JobDesc` / `ModelDesc`                        | L3_MD | ABAQUS inp 文件根级定义                |
| `*NODE`                    | `MD_Node_Type`（`MeshNodeDesc`）                 | L3_MD | 节点坐标真相源                          |
| `*ELEMENT`                 | `MD_Elem_Base_Desc`                            | L3_MD | 单元拓扑与类型 ID 真相源                   |
| `*MATERIAL` / `*ELASTIC` 等 | `PH_Mat_Slot.ctx`                         | L4_PH | props 经 Populate 注入，原始 Desc 在 L3 |
| `*BOUNDARY` / `*CLOAD`     | L4 `PH_LoadBC_Domain` Desc                     | L4_PH | 经 Bridge 从 L3 `MD_Ldbc_*` 转入     |
| `*CONTACT PAIR`            | `MD_ContactPairDef`（L3）/ `PH_Cont_Desc`（L4）    | L3/L4 | L3 存定义，L4 存算法                    |
| `*STEP` / `*STATIC` 等      | `RT_StepDriver_Desc`                           | L5_RT | 分析步类型与时间控制                       |
| UMAT subroutine            | `PH_UMAT_Context` / `PH_Mat_Core_UMAT_Adapter` | L4_PH | UMAT 接口适配，props/STATEV 映射        |
| VUMAT subroutine           | `PH_Mat_*`（显式路径）                               | L4_PH | 显式动力学材料接口                        |
| `ddsdde`（UMAT 输出）          | `PH_Mat_State.C_tan`                      | L4_PH | 一致切线刚度矩阵                         |
| `stress`（UMAT in/out）      | `PH_Mat_State.stress`                     | L4_PH | 当前应力张量（Voigt 记法）                 |
| `statev`（UMAT SDV）         | `PH_Mat_State.stateVars(_n)`              | L4_PH | 内变量数组，`_n` 为步初值                  |
| `lflags`（UEL 标志）           | `RT_Com_Base_Ctx.analysis_type` + lflags 字段    | L5_RT | 分析类型/过程标志向量                      |
| 全局刚度矩阵 K                   | `RT_CSRMatrix`                                 | L5_RT | CSR 稀疏格式三数组                      |
| 全局力向量 F                    | `RT_Asm_State`（装配后向量）                          | L5_RT | 由 `RT_Asm_ComputeResidual` 填充    |


---

## 7. 交叉引用

### 7.1 本文档被以下导航/规范引用


| 引用文档       | 路径                                         | 引用方式        |
| ---------- | ------------------------------------------ | ----------- |
| UFC 导航总纲   | `docs/六层架构拆分/00-总纲/`                       | 结构体快速定位入口   |
| L3_MD 域合同卡 | `ufc_core/L3_MD/*/CONTRACT.md`             | 四型配置条目      |
| L4_PH 域合同卡 | `ufc_core/L4_PH/*/CONTRACT.md`             | 四型配置条目      |
| L5_RT 域合同卡 | `ufc_core/L5_RT/*/CONTRACT.md`             | 四型配置条目      |
| PPLAN 实施规划 | `docs/05_Project_Planning/PPLAN/README.md` | 实施阶段结构体演进追踪 |


### 7.2 本文档引用的上游规范


| 规范文档          | 路径                                                                             | 关联章节                 |
| ------------- | ------------------------------------------------------------------------------ | -------------------- |
| UFC 六层架构总纲    | `UFC_架构设计总纲_六层四类四链三步三级两图一体_原始版.md`                                             | 第 2 节 L3_MD–L5_RT 索引 |
| 理论手册          | `docs/六层架构拆分/01-理论基础/`                                                         | 第 5 节全部              |
| HYPLAS 淬炼方案   | `docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md` | L4_PH 物理层            |
| SIO 结构化 IO 规范 | `*_Proc.f90` / Principle #14                                                   | `*_Arg` 命名约定         |


### 7.3 关键命名约定


| 层     | 前缀约定    | 示例                                                         |
| ----- | ------- | ---------------------------------------------------------- |
| L3_MD | `MD`_   | `MD_Model_Types`、`MD_Elem_Base_Desc`                       |
| L4_PH | `PH`_   | `PH_Mat_State`、`PH_Elem_Base_Ctx`                     |
| L5_RT | `RT`_   | `RT_Asm_Desc`、`RT_StepDriver_Types`                        |
| 统一参数包 | `*_Arg` | `PH_Element_Compute_Ke_Arg`、`PH_Mat_Eval_Arg` |


---

*维护说明：新增 TYPE 时须同步更新对应层的索引表；新增理论文档须补充 §5 条目并关联结构体。*