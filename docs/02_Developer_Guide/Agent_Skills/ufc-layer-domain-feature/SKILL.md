---
name: ufc-layer-domain-feature
description: "UFC 层级-域级-功能级-子程序模板生成与实施，对齐六层+四类+四链+三步+三级+两图+一体。SIO：统一 *_Arg（[IN]/[OUT] 注释），弃用 inp/out 对偶；五参（四型+args）或六参（+RT_Com_Base_Ctx）。当用户指定「层级+域+功能集+子程序/模块」并希望按 UFC 规范立即生成模板并进入实施时，必须使用本技能。模板包含：四链、数据结构拆解、Module 头部 TYPE/SUBROUTINE 列举表。触发：ufc gen、ufc template、层级域级功能级子程序。规范入口：UFC/docs/README.md、docs/05_Project_Planning/PPLAN/README.md；实施依据：docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md。"
---
# UFC 层级-域级-功能级-子程序：模板生成与实施技能

用户用**一句命令式**指定「层级-域级-功能级-子程序」后，按本技能流程**先生成模板设计、再直接进入实施阶段**，全程遵守 **六层+四类+四链+三步+三级+两图+一体** 及统一数据容器规范。

**架构设计总纲（本技能对齐）**

- **六层**: L1_IF + L2_NM + L3_MD + L4_PH + L5_RT + L6_AP
- **四类**: TYPE — Desc / Algo / Ctx / State
- **四链**: 理论链 + 逻辑链 + 计算链 + 数据链
- **三步**: 分析步 + 载荷增量步 + 平衡迭代步
- **三级**: 层级–域级–功能集（命名：f90/Module、TYPE、过程、变量、子程序）
- **两图**: 层级架构设计图 + 域级框架计算流程和路线图
- **一体**: 数据结构一体化（总-分多级嵌套，结构体/类集成化管理）

---

## 子程序签名与统一 IO 容器（SIO / Principle #14）

生成或修改 **域入口子程序**（`_Proc` / `_Apply` / `_API` / `UMAT_Impl` 等）时，遵守下列约定；与 `UFC/docs/templates` 中 `RT_XXX_*_Proc`、`PH_XXX_Mat` 等模板一致。

### 设计哲学

- **统一 IO bundle**：每调用一次的输入与输出集中在**一个**派生类型里（如 `RT_XXX_Load_Arg`、`RT_XXX_Mat_Arg`、`RT_SD_Arg`、`PH_Mat_XXX_Arg`），命名为 `args`、`mat_arg` 或与域一致的 `*_Arg`。
- **方向不靠形参个数表达**：在 TYPE 定义内用注释标注 **`[IN]`** / **`[OUT]`** / **`[INOUT]`**（仅注释，不在 TYPE 内写 `INTENT`）。禁止再用 **`inp` / `out` 两个哑元** 人为劈开「半边输入、半边输出」。
- **四型仍分离**：`Desc`、`State`、`Algo`、`Ctx` 四类角色保持独立形参（传完整结构体，热路径不拆散成员），与「统一 IO bundle」正交。

### 子程序形参个数（两种 canonical 形式）

| 形式 | 形参模式 | 说明 |
|------|----------|------|
| **五参** | `(desc, state, algo, ctx, args)` | 四型 + **单一** `args`；无单独 `RT_Com_Ctx` 时使用（或该域在上下文里不暴露增量簿记）。 |
| **六参** | `(desc, state, algo, ctx, RT_Com_Ctx, args)` | 在四型之后增加 **`RT_Com_Base_Ctx`**（只读或读为主），**第六参仍为唯一的 `args`**，用 `args` 替代原先的 `inp`/`out` **对偶**。 |

对照（弃用）：

- **旧**：`(desc, state, algo, ctx, inp, out)` — 六个形参里后两个是 **输入包 + 输出包** 两套 TYPE。
- **新**：六个形参时应为 **`…, RT_Com_Ctx, args`**，不是 `…, inp, out`；五个形参时为 **`…, args`**  alone。

### 生成模板时的自检

- [ ] 模块 `PUBLIC` 导出统一的 `*_Arg` TYPE；不再导出成对的 `*_In` / `*_Out`（除非遗留兼容层单独声明）。
- [ ] 入口子程序 `INTENT(INOUT) :: args`（或按实现只读 `[IN]` 段时用 `INTENT(IN)` 的子过程 — 由调用约定决定；多数 `_Apply` 为 `INOUT`）。
- [ ] 文件头 / SIO 注释块中写的是 **`args`** 与 **`[IN]`/`[OUT]`**，不写「inp/out 对」。

---

## 何时使用本技能

在以下任一情况**必须**触发本技能：

- 用户说「**UFC 模板**」「**按 UFC 规则生成并实施**」「**生成 Lx 某域某功能并实施**」
- 用户给出**四元组**：层级（L3_MD/L4_PH/L5_RT/L6_AP）+ 域（如 BC/Step/Mat/Elem/Cont）+ 功能集（驼峰，如 Dirichlet/Static/Nonlin）+ 子程序/模块名（可选）
- 用户说「**层级-域级-功能级-子程序**」「**ufc gen**」「**ufc template**」并附带上述四元组或可推断信息
- 用户希望为某个**核心子程序**生成：**f90 头注释（含四链：理论/逻辑/计算/数据、数据结构拆解、TYPE/SUBROUTINE 列举表、Unicode 公式）+ 四链 Mermaid 图**，并落地到代码与文档

---

## 命令式输入解析

从用户输入中解析或确认以下四项（缺项时主动一问一答补全）：

| 项                          | 含义                   | 示例                                            |
| --------------------------- | ---------------------- | ----------------------------------------------- |
| **Layer**             | 层级                   | L3_MD, L4_PH, L5_RT, L6_AP                      |
| **Domain**            | 域                     | BC, Step, Solv, Mat, Elem, Cont, Asm, Job, ...  |
| **Feature**           | 功能集（驼峰）         | Dirichlet, Static, Nonlin, Hex8, Penalty, ...   |
| **Subroutine/Module** | 子程序或模块名（可选） | RT_Solv_Nonlin_Core, PH_BC_Dirichlet_Apply, ... |

**命名约定**：模块前缀 = 层前缀（MD_/PH_/RT_/AP_）；模块名建议 `{Prefix}_{Domain}_{FeatureCamel}_Core` 或同类；子程序名与域/功能集一致。

---

## 执行流程（模板设计 → 实施）

按顺序执行，不跳步。

### 第一步：加载规范与速查卡（路径以仓库为准）

1. 读 **文档权威口径** [`docs/README.md`](../../../README.md) 与 **PPLAN 入口** [`docs/05_Project_Planning/PPLAN/README.md`](../../../05_Project_Planning/PPLAN/README.md)。
2. 读 **架构主线（v5.0）**：[`docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md`](../../../05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md)（六层、四类、四链、三步、依赖方向）。
3. 读 **实施与热路径**：[`docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md)（Populate/热路径）。
4. 读 **开发者指南与检查清单**：[`docs/05_Project_Planning/PPLAN/04_技术标准/UFC_DEVELOPER_GUIDE.md`](../../../05_Project_Planning/PPLAN/04_技术标准/UFC_DEVELOPER_GUIDE.md)；**每轮检查**：[`04-05-执行检查清单.md`](../../../03_Domain_Pillars/Layer_Architecture_Splits/03-实施路线/04-05-执行检查清单.md)（原「子程序标准化规范」「ufc_core/docs 检查清单」未随仓库则以此替代）。
5. **按需**读 **L3↔L4 契约**：[`docs/05_Project_Planning/PPLAN/05_实施指南/L3_MD_L4_PH_联通契约与缺陷分析.md`](../../../05_Project_Planning/PPLAN/05_实施指南/L3_MD_L4_PH_联通契约与缺陷分析.md)；**架构深挖**用 `npx openskills read fem-kernel-architecture`。
6. 目标域若在 `ufc_core` 已有合同，读对应 [`UFC/ufc_core/L3_MD/`](../../../ufc_core/L3_MD/) 或 [`UFC/ufc_core/L4_PH/`](../../../ufc_core/L4_PH/) 下各域 **`CONTRACT.md`**（路径以仓库为准，非单一 `contracts/` 目录）。

### 第二步：架构自查（必过）

- 用 v5.0 总纲 + HYPLAS 方案做一轮**依赖方向 / 四类 TYPE / 容器路径 / 热路径是否踩 L3** 自查；若有任一项与合同或总纲冲突，先纠偏再继续。
- 将「当前任务」写成会话断点格式（层级/域级/功能集、容器路径、下一步）。

### 第三步：生成模板设计（输出可粘贴的文本与路径）

生成以下内容并**直接呈现**给用户（便于复制到文件或由你代写）。**一次性做完**：四链 + 数据结构拆解 + TYPE/SUBROUTINE 列举表。

1. **容器与四类 TYPE（一体：总-分多级嵌套）**

   - 对应 `g_ufc_global%<layer_key>%<domain>` 路径（layer_key 如 model_data/physics/runtime/application）。
   - 本功能集的 Desc/State/Algo/Ctx 建议名称与用途（一句话）。
   - 嵌套关系：哪些 TYPE 内含子结构、与域容器的数组/单例/临时对应关系。
2. **四链（理论链 + 逻辑链 + 计算链 + 数据链）**

   - **理论链（Theory chain）**：手册/理论出处 → 关键公式/符号（Unicode）→ 本模块职责；可简化为「手册节号 + 变量符号 + 弱形式/离散一句」。
   - **逻辑链（Logic chain）**：谁调用本模块 → 本模块 → 调用的下层/同层模块（文本列表或 Mermaid 节点）。
   - **计算链（Computation chain）**：关键公式用 **Unicode**（如 r(u)=f_ext−f_int, K_t=∂r/∂u）；与实现对应的主要计算步骤。
   - **数据链（Data chain）**：四类 TYPE 名称、容器路径、输入/输出/读写约定；传结构体不暴露成员。
3. **数据结构拆解（便于多级嵌套与一体设计）**

   - Container path：`g_ufc_global%...`
   - Desc：数组或单例；主要字段（列举）；只读。
   - State：数组或单例；主要字段；在 Step/Iter 中更新。
   - Algo：单例；主要字段；求解时只读。
   - Ctx：按次创建、不常驻容器；由谁创建/释放。
   - Nested：若 State/Desc 内引用其他 TYPE 或全局状态，写明嵌套/索引关系。
4. **f90 文件头注释块**

   - 按 **`docs/05_Project_Planning/PPLAN/04_技术标准/UFC_DEVELOPER_GUIDE.md`** + 本技能四链/数据结构拆解要求填写，建议包含：
     - Module, Layer, Domain, Feature, Purpose
     - **Theory chain**（理论链）, **Logic chain**, **Computation chain** (Unicode), **Data chain** (四类 TYPE)
     - **Data structure**（数据结构拆解：容器路径、四类存放方式、嵌套）
     - Three-step mapping（若属 Step/Inc/Iter）, **Contents（Types 与 Subroutines 的 A-Z 列举表）**, Notes
     - `!>>> 依据:docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md …`（与仓库现有模块头一致）
     - Status / Last verified
5. **四链 Mermaid 图（*_Chains.md）**

   - 至少包含：**逻辑链图**、**计算链图**。
   - 按需增加：理论链图（手册→公式→本模块）、数据链图（g_ufc_global→域→四类）。
   - 风格：flowchart TD，节点用英文/公式，与头注释一致。
6. **三步映射（若为本模块所属）**

   - 标明属于 Step / Increment / Iteration 哪一级，以及对应入口子程序名。

### 第四步：进入实施阶段

在完成模板设计后，按总设计与实施规范执行以下项（既有模块以「补全与规整」为主，新模块以「骨架 + 规整」为主）。

1. **创建或更新 f90 文件**

   - 在 **UFC/ufc_core/** 下对应层级与域的路径创建或定位目标 `.f90`。
   - 将第三步生成的**文件头注释块**（含四链、数据结构拆解、Contents 表）写入该文件顶部；若已存在旧头，替换为规范头。
   - 若为新模块：生成 `MODULE ... END MODULE` 骨架和 `PUBLIC` 子程序占位，并保持与命名规范一致。
2. **补全底层代码实现**

   - 根据第三步的**总设计**（四链、四类 TYPE、容器路径、三步映射）和 **PLAN** 中的实施规范，补全本模块内尚未实现的子程序/函数体。
   - 接口以传递 TYPE（Desc/State/Algo/Ctx）为主，**每调用 IO 用单一 `args`（`*_Arg`）bundle + 成员上 `[IN]`/`[OUT]` 注释**，不用 `inp`/`out` 对偶；若规范要求增量上下文则加 **`RT_Com_Base_Ctx`**，形成六参形式；与数据链、数据结构拆解一致。
   - 若为桥接模块，保持「仅封装 USE 与转发调用」；若为 Core，实现与计算链、理论链对应的核心计算。
3. **消除无用冗余代码**

   - 删除本模块内已废弃、重复或与当前四链/四类设计无关的代码片段。
   - 合并逻辑高度相似的子程序，保留单一权威实现；旧入口可标记 `[DEPRECATED]` 并改为 PRIVATE 或删除。
   - 清理未使用变量、多余 USE、死分支与注释掉的废码。
4. **命名规范化**

   - 遵循**三级命名**：层级–域级–功能集；模块/TYPE/过程/变量与 **NAMING.md** 及命名规范一致。
   - **长名称压缩**：在符合工程/有限元通用符号与可读性前提下，对过长标识符做合理缩写（如 Consistent→Cons, Configuration→Cfg），避免阅读模糊；新缩写需在命名规范或 NAMING.md 中可查。
   - 不引入未在规范中登记的新前缀或缩写。
5. **代码结构与排版**

   - **代码段间加空行**：不同子程序/函数之间、逻辑块之间（声明与可执行段、IF/DO 块之间）适当空行，增强可读性。
   - **执行语句不串联**：同一行不用分号串联多条执行语句；每条语句单独一行，便于阅读与调试。
   - **子程序/子函数/过程按字母顺序规整**：模块内 `CONTAINS` 后的子程序和函数按名称 A–Z 排序规整化（可与头注释 Contents 表一致），便于查找与维护。
6. **Fortran 90 语法检查**

   - 实施后对修改过的 `.f90` 做 F90 语法检查：类型匹配、接口一致、INTENT 正确、ALLOCATABLE/POINTER 使用、模块 USE 可见性等。
   - 若有项目内 linter 或编译脚本，运行通过后再视为本步完成。
7. **创建或更新 Chains.md**

   - 在同目录下创建或更新 `*_Chains.md`，内容至少包含：逻辑链、计算链 Mermaid 图；按需增加理论链、数据链图。与头注释四链及数据结构拆解一致。
8. **更新文档与索引（如有新范式）**

   - 若形成新的「域+功能集」范式，在 **`docs/05_Project_Planning/PPLAN/README.md`**、[`UFC/docs/index.md`](../../index.md) 或 `ufc_core` 各域 `CONTRACT.md` 中补充引用；大稿归档入 `UFC/docs/archive/` 对应子目录。
   - 若有命名或接口变更，同步 [`UFC/docs/UFC_命名与数据结构规范.md`](../../UFC_命名与数据结构规范.md) 或层内说明。
9. **会话断点**

   - 用 [`UFC/docs/六层架构拆分/03-实施路线/04-05-执行检查清单.md`](../../六层架构拆分/03-实施路线/04-05-执行检查清单.md) 中的可执行检查项写回当前任务上下文（层级/域级/功能集、容器路径、下一步），便于下次恢复。

**第四步实施阶段检查清单（执行后自检）**

- [ ] 头注释已含四链、数据结构拆解、Contents 表
- [ ] 底层实现已按总设计补全（或确认为仅桥接/占位）
- [ ] 无用/冗余代码已删除或合并
- [ ] 命名符合三级与 NAMING.md，长名已合理压缩且可读
- [ ] 代码段间有空行，执行语句单行、无分号串联
- [ ] 子程序/函数/过程已按名称 A–Z 排序
- [ ] F90 语法/编译或 linter 已通过
- [ ] *_Chains.md 已创建或更新
- [ ] 文档/NAMING 已更新（若有新范式或命名变更）

---

## 输入输出示例

**用户输入示例**：

- 「按 UFC 规则为 L4_PH BC Dirichlet 生成模板并实施」
- 「ufc gen L5_RT Solv Nonlin RT_Solv_Nonlin_Core」
- 「为 L3_MD Mat Elastic 生成模板并直接实施」

**你的输出**：

- 解析出的 Layer / Domain / Feature / Subroutine（或 Module）。
- 第二步自查结果（依赖/四类/热路径/合同）一句话结论。
- 第三步的完整模板设计（四链、数据结构拆解、Contents、头注释块、Mermaid 图）。
- 第四步实施结果：已创建/修改的 f90 与 Chains.md；若涉及既有模块，说明补全实现、去冗余、命名规范化、排版（空行/单行语句/子程序字母序）、F90 语法检查的完成情况；以及会话断点摘要。

---

## 项目文档锚点（技能内引用，2026-03-29 更新）

| 用途 | 路径（相对于工作区根 `UFC/`） |
|------|------------------------|
| 文档权威入口 | `docs/README.md`、`docs/05_Project_Planning/PPLAN/README.md` |
| 架构主线 v5.0 | `docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md` |
| HYPLAS 淬炼（实施/热路径） | `docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md` |
| 开发者指南（替代已迁移的「子程序标准化」单文件） | `docs/05_Project_Planning/PPLAN/04_技术标准/UFC_DEVELOPER_GUIDE.md` |
| L3↔L4 联通契约 | `docs/05_Project_Planning/PPLAN/05_实施指南/L3_MD_L4_PH_联通契约与缺陷分析.md` |
| 执行检查清单 | `docs/六层架构拆分/03-实施路线/04-05-执行检查清单.md` |
| 命名与数据结构 | `docs/UFC_命名与数据结构规范.md` |
| 知识体系总览 | `docs/00-知识体系与设计框架总览.md` |
| f90 头注释 + Chains 示例（若存在） | `ufc_core/L5_RT/Solv/` 等目录内 `*_Core.f90`、`*_Chains.md` |

---

## 与 fem-kernel-architecture 的配合

- **fem-kernel-architecture**：偏架构设计、域级迭代、四链打通、四阶段（Discovery → Design → Implementation → Documentation）。
- **本技能**：偏「给定层级-域-功能-子程序」后的**模板生成 + 直接实施**（头注释、Mermaid、容器/TYPE、f90 与 Chains.md 落地）。
- 当用户既要做架构迭代又要对某个具体「层级-域-功能-子程序」生成模板并实施时，可先按 fem-kernel-architecture 做域级设计，再对本技能说「为 Lx 某域某功能某子程序生成模板并实施」。

---

**版本**: v1.5 | **日期**: 2026-03-28  
**升级说明**: v1.5 增补 **子程序签名与统一 IO 容器**：弃用 `(…, inp, out)`，采用 **五参 `(…, args)`** 或 **六参 `(…, RT_Com_Ctx, args)`**；方向由 `*_Arg` 内 **`[IN]`/`[OUT]`** 注释表达。v1.4 起锚点已切至 **`docs/05_Project_Planning/PPLAN/`**、检查清单与开发者指南路径见上表。
