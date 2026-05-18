# ABAQUS 核心功能子集 ↔ UFC 层域映射表（骨架）

> **定位**：把 **ABAQUS 用户可见的核心能力子集**（工作流 / 关键字语义 / 隐式–显式分支）映射到 **UFC 六层 + `ufc_core` 域桶**，用于 **自研对齐、缺口分析与合同拆分**。  
> **非承诺**：不表示与 **ABAQUS 内部源码目录** 一致；不替代官方手册与验证。  
> **目录真源**：`ufc_core` 物理树以 [`UFC_ufc_core_目录权威分类.md`](UFC_ufc_core_目录权威分类.md) 为 **最终目录基线**。

**文档日期**：2026-04-22  
**状态**：骨架 — 「成熟度」列待填；子域可细化到 `*.f90` / `CONTRACT.md` 后更新。

**对标产品版本（本子集）**

| 项 | 说明 |
|----|------|
| **主版本** | **ABAQUS 2024**：关键字命名、文档章节、CAE 导出 INP 以 2024 为 **主对齐面**。 |
| **兼容交集** | **6.14**：以「6.14 时代经典 INP 在 2024 仍解析、语义不变或向后兼容」的能力为 **UFC 首阶段可验收交集**；2024 **新增/弃用** 的参数与块另列「版本差分」（待与手册逐条对齐，**不**在此粘贴大段手册原文）。 |
| **UFC 立场** | 实现与合同以 **仓库内 `CONTRACT.md` + 行为子集** 为准；与商业软件逐字节格式一致 **非** 当前目标。 |

---

## 1. 图例

| 列 | 含义 |
|----|------|
| **ABAQUS 能力子集** | 产品功能切片（可验收粒度）。 |
| **典型入口 / 关键词** | INP / CAE 侧常见锚点（示意，非完整语法树）。 |
| **求解分支** | `STD` ≈ Standard/隐式主线；`EXP` ≈ Explicit；`BOTH`；`N/A`。 |
| **UFC 层** | `L1_IF` … `L6_AP`（可多选）。 |
| **UFC 域桶（主）** | 与目录基线一致的 **第一层子目录** 名（如 `L3_MD/Mesh` → 域桶 `Mesh`）。 |
| **备注（子域 / 模块）** | 第二层及以下或关键模块名（**待与 manifest / Registry 对齐**）。 |
| **合同 / 扩展锚点** | 仓库内 `CONTRACT.md`、PPLAN、或扩展点技能入口。 |
| **成熟度** | 建议：`未开始` / `骨架` / `α` / `β` / `对标中`。 |

---

## 2. 核心映射表（骨架）

| ABAQUS 能力子集 | 典型入口 / 关键词 | 求解分支 | UFC 层（主） | UFC 域桶（主） | 备注（子域 / 模块） | 合同 / 扩展锚点 | 成熟度 |
|-----------------|-------------------|----------|--------------|----------------|---------------------|-----------------|--------|
| **Standard 静力（隐式）** | `*STEP` + `*STATIC` / `*SOILS` 等隐式步 | STD | L3_MD, L4_PH, L5_RT, L2_NM | `Analysis`, `Assembly`, `Mesh`, `Material`, `Boundary`, `Constraint`, `Element`(PH), `Material`(PH), `Solver`/`LinSolv`, `StepDriver` | 模型数据在 MD；本构积分在 PH `Material`；刚度装配在 RT `Assembly`；线性求解在 NM `Solver/LinSolv`；步进在 RT `StepDriver` | L3/L4 联通契约；`fem-kernel-extensibility`（材料/单元插件边界） | 骨架 |
| **Explicit 动力** | `*DYNAMIC`, `EXPLICIT` | EXP | L3_MD, L4_PH, L5_RT, L2_NM | 上表 + `TimeInt` | 时间积分与稳定步长多在 NM `TimeInt` 与 RT `StepDriver` 协同；显式向量算子依赖 NM `Matrix`/`Solver` 子域 | 同上 + Explicit 稳定性专题（待链 PPLAN） | 骨架 |
| **通用接触（面–面 / 自接触等）** | `*CONTACT`, `*SURFACE INTERACTION`, `*FRICTION` | BOTH | L3_MD, L4_PH, L5_RT | `Interaction`, `Contact`(PH), `Contact`(RT), `Constraint` | MD 存接触对/表面定义；PH 接触力学与摩擦；RT 运行时接触搜索/更新 | `ufc-domain-interaction`；PH Contact 子域 | 骨架 |
| **Tie / MPC / Coupling / Rigid** | `*TIE`, `*MPC`, `*COUPLING`, `*KINEMATIC` | BOTH | L3_MD, L4_PH, L5_RT | `Constraint`, `Constraint`(PH), `Constraint`(RT) | 约束装配与消元/拉格朗日乘子路径跨 MD/PH/RT | PPLAN 约束域设计文档 | 骨架 |
| **Standard UMAT** | `*USER MATERIAL` + 隐式步 | STD | L4_PH, L3_MD, L1_IF | `Material`(PH), `Material`(MD), `Base`/`Error` | 状态变量与应变驱动在 PH；材料参数表在 MD；错误/精度在 IF | `fem-kernel-extensibility`；`ufc-solver-router`（STD） | 骨架 |
| **VUMAT** | `*USER MATERIAL` + Explicit | EXP | L4_PH, L2_NM, L5_RT | `Material`(PH), `Solver`, `StepDriver` | 与显式步进、向量更新、沙漏控制等耦合 | `ufc-solver-router`（EXP） | 骨架 |
| **UEL（隐式/显式分支）** | `*UEL` | BOTH | L4_PH, L3_MD | `Element`(PH), `Mesh/Element`(MD) | 单元族在 MD `Elem/<族>`；单元物理与小时沙漏等在 PH `Element/<族>` | `fem-kernel-extensibility`（UEL） | 骨架 |
| **场输出 / 历史输出 / 监视器（定义→执行）** | `*OUTPUT`, `*FIELD OUTPUT`, `*HISTORY OUTPUT`, `*NODE OUTPUT`, `*ELEMENT OUTPUT`, `*MONITOR`… | BOTH | L3_MD, L5_RT, L6_AP | `Output`, `Output`(RT), `Output`(AP) | **L3**：解析输出请求 Schema，**不写盘**（见 `L3_MD/Output/CONTRACT.md` P7）。**L5**：`RT_Out_*` 编排抽取与频率策略。**L6**：实际文件/通道。2024 与 6.14 在变量名集合、ODB 细节上可能有差 — 以 UFC 变量注册表与最小可行子集为准。 | `ufc-domain-output`；[`L3_MD/Output/CONTRACT.md`](../../../ufc_core/L3_MD/Output/CONTRACT.md)；[`L5_RT/Output/CONTRACT.md`](../../../ufc_core/L5_RT/Output/CONTRACT.md) | 骨架 |
| **Restart（检查点写 / 读入续算）** | `*RESTART WRITE`, `*RESTART READ`, `*IMPORT`（restart 语义）等 | BOTH | L3_MD, L5_RT, L6_AP | `Output`, `Model`（Import 配置）, `Bridge`, `Job` | **定义侧**：`*RESTART` / 监视等与输出 Schema 一并进入 L3（P7：**不**在 L3 执行 I/O）。**执行侧**：L5 `RT_Out_Restart`（检查点保存/恢复）；模型导入类型见 `MD_ModelLib` 中 restart 相关选项（注释/类型与续算衔接）。**格式**：UFC 以自有/选定交换格式为真源，**不**承诺与 `.sim`/`.odb` 重启包一一兼容。 | 上节 Output 合同 + [`L5_RT/Output/CONTRACT.md`](../../../ufc_core/L5_RT/Output/CONTRACT.md) Restart 行；Model Import 见 `MD_ModelLib_Algo` 文档注释 | 骨架 |
| **幅值（时间缩放 \(A(t)\)）** | `*AMPLITUDE`；载荷/边界上的幅值引用 | BOTH | L3_MD | `Analysis/Amplitude`，并与 `Boundary`、`LoadBC` 耦合 | 解析型曲线（TABULAR / SMOOTH / RAMP / …）与 **UAMP** 结构化求值分路；加载侧经 `Amp_GetFactor` / 域 `EvalAtTime`（见 Amplitude 合同）。与 **Step** 时间轴、增量索引一同消费。 | [`L3_MD/Analysis/Amplitude/CONTRACT.md`](../../../ufc_core/L3_MD/Analysis/Amplitude/CONTRACT.md)；[`L3_MD/Analysis/CONTRACT.md`](../../../ufc_core/L3_MD/Analysis/CONTRACT.md) Amplitude 子表 | 骨架 |
| **边界与载荷（模型侧）** | `*BOUNDARY`, `*CLOAD`, `*DLOAD`, `*TEMPERATURE`… | BOTH | L3_MD, L4_PH | `Boundary`, `LoadBC`(PH) | 模型定义在 MD；物理施加算子在 PH | PPLAN LoadBC 设计 | 骨架 |
| **运行时载荷 / 接触施加** | Solver 回调链 | BOTH | L5_RT | `LoadBC`, `Contact` | 与步内残差与 Jacobian 装配对接 | RT 域合同 | 骨架 |
| **INP 关键字解析** | `*HEADING`, `*NODE`, `*ELEMENT`… | N/A | L3_MD, L6_AP | `KeyWord`, `Input` | AP 侧脚本/解析；MD 侧模型树填充 | `ufc-domain-keyword` | 骨架 |
| **作业 / 进程级** | Job、日志、监视器（非求解热路径） | N/A | L1_IF, L6_AP | `Base`, `Monitor`, `Job`, `Config` | 设备、日志、作业容器；与 **Restart** 行分工：此处偏 **作业外壳**，Restart 偏 **检查点 I/O 链** | L1/L6 域建模文档 | 骨架 |
| **稀疏矩阵 / 预条件** | 线性子问题 | STD | L2_NM | `Matrix`, `Solver/LinSolv`, `Solver/Conv` | CSR 与 SpMV；Krylov/AMG 等（视实现裁剪） | L2 `CONTRACT`、Registry | 骨架 |

---

## 3. UMAT vs VUMAT 路径（骨架）

| 项目 | Standard（UMAT） | Explicit（VUMAT） |
|------|-------------------|-------------------|
| **驱动量** | 应变增量 / Jacobian 所需应力率 | 速度梯度 / 增量更新 |
| **UFC 求解路由** | `STD` 隐式链 | `EXP` 显式链 |
| **主域桶（示意）** | `L4_PH/Material`, `L2_NM/Solver/LinSolv`, `L5_RT/Solver` | `L4_PH/Material`, `L2_NM/TimeInt`, `L2_NM/Solver`, `L5_RT/StepDriver` |
| **扩展注册** | 材料插件接口（与 Bridge 分层） | 同上 + 显式稳定步与沙漏 |
| **验证** | 单单元 / 路径测试 + 与参考解 | 波传播 / 能量守恒类用例 |

---

## 4. UEL 路径（骨架）

| 项目 | 说明 |
|------|------|
| **模型数据** | `L3_MD/Elem/<族>`：自由度、形函数数据、与 MD 单元描述绑定。 |
| **物理内核** | `L4_PH/Element/<族>`：内力、刚度、沙漏（若适用）。 |
| **运行时** | `L5_RT/Element/Mesh` 等：步内调度与装配对接（以合同为准）。 |
| **用户扩展** | UEL 与 UMAT 同属 `fem-kernel-extensibility`；需声明与 `RT_SolverType` / 时间积分的兼容矩阵。 |

---

## 5. Contact：Standard vs Explicit（骨架）

| 维度 | Standard | Explicit |
|------|----------|----------|
| **MD** | 接触对、表面、相互作用属性 | 同左 |
| **PH** | 法向/切向本构、摩擦、部分稳定化 | 碰撞检测、惩罚/动力学接触 |
| **RT** | 约束装配、搜索与状态更新 | 高频搜索、步内更新 |
| **NM** | 线性化子问题的线搜索/接触牛顿（若实现） | 稳定时间步、对角化质量等 |

---

## 6. 与「小型 ABAQUS」范围的对照（非目录）

| 能力轴 | 是否在本子集映射中覆盖 | 备注 |
|--------|-------------------------|------|
| **几何非线性 / 材料非线性** | 是（隐含在 Standard/Explicit 行） | 需单独 V&V 矩阵 |
| **并行 / 域分解** | 部分（L1 `Parallel`，L2 `Solver/Parallel`，L5 `Bridge`） | 与 `MPI`/`OMP` 策略绑定 |
| **CAE 图形界面** | 否（AP `UI` 可选） | 非求解核必须 |
| **完整 ODB** | 否（以 `Output` 链为占位） | 可定义最小可行子集 |
| **Restart 文件与商业格式逐位一致** | 否 | 交集语义可对齐；容器格式自有 |
| **幅值全集（含谱/PSD 等）** | 部分 | 以 Amplitude 合同已列类型为真源；其余标「待扩展」 |

---

## 7. Restart · 幅值 · 输出 — 与 ABAQUS 2024 / 6.14 交集（速查）

| ABAQUS 用户概念（2024 文档用语；6.14 多为同名块） | INP / 作业侧锚点（示意） | UFC 分层落点（摘要） |
|--------------------------------------------------|---------------------------|----------------------|
| **输出请求** | `*OUTPUT` 及 FIELD/HISTORY/NODE/ELEMENT 等子块 | **L3** 解析入 Schema；**L5** 步末/增量末调度；**L6** 写通道 |
| **重启写出 / 读入** | `*RESTART WRITE`、`READ`；续算作业 | **L3** 仅定义与策略字段；**L5** `RT_Out_Restart`；导入续算与 **Model** Import 类型衔接 |
| **幅值** | `*AMPLITUDE`；BC/Load 引用幅值名 | **L3** `Analysis/Amplitude`；求值在步进中与 **Boundary/LoadBC** 消费 |

**6.14 ↔ 2024**：上表三行在经典静力/动力工作流中通常 **同名**；若遇参数改名或新增必选参数，在本文件 **§2** 对应行备注「仅 2024」或「6.14  Deprecated」，并链到 PPLAN 差分附录（待建）。

---

## 8. 维护

1. **目录变更**：先改 [`UFC_ufc_core_目录权威分类.md`](UFC_ufc_core_目录权威分类.md) **基线**，再回改本表「域桶 / 子域」列。  
2. **能力增删**：在 **§2 表** 增行优于硬改多列；保持 **ABAQUS 子集** 可验收命名。  
3. **成熟度**：由域负责人在本表或链接的 `design/.../INTENT.md` 中更新。  
4. **版本差分**：2024 相对 6.14 的关键字级变更建议单独维护「差分附录」，避免与本映射主表混写导致可读性下降。
