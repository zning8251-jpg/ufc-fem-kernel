# UFC 物理目录与模块命名映射基准 (100% 完整版)

> **修订说明**：前序蓝图为便于口语化表述，使用了 `Elem`、`Interact` 等缩写目录，这与 UFC **真实的架构目录** (`ufc_core`) 发生了冲突，且遗漏了大量域级划分。
> 本清单基于 `ufc_core` 的绝对真实目录结构（`DESIGN_LayerDomain_Reference.md`）生成，解决全称与缩写的冲突问题。

---

## 一、 核心架构冲突解析：“目录全称”与“代码缩写”的二象性

UFC 为了兼顾“工程目录的可读性”与“Fortran调用的紧凑性”，制定了极其严格的双轨命名法：

1. **物理目录级 (Directory Level)**：**必须使用完整英文单词**（大驼峰）。
  - *正确*：`Element`, `Material`, `Interaction`, `Assembly`
  - *错误*：`Elem`, `Mat`, `Interact`, `Asm`
2. **代码模块级 (Module/File Level)**：**必须使用极简三段式缩写** `[Prefix]_[AbbrDomain]_[Suffix].f90`。
  - *正确*：`PH_Elem_Core.f90`, `MD_Mat_Def.f90`, `RT_Asm_Solver.f90`
  - *错误*：`PH_Element_Core.f90`

---

## 二、 UFC 核心七层架构：全景域与子域完整清单

以下清单 100% 映射了 `ufc_core` 中现有的所有物理域，并为您配齐了它对应的**“模块前缀映射 (Module Prefix)”**。

### L0_Global (全局内存枢纽层)

*(此层为特例，无深层域划分，仅提供全局环境支持)*

- 对应文件：`UFC_GlobalContainer_Core.f90`

### L1_IF (Interface Layer - 接口层)

*(模块统一前缀：`IF_[Abbr]`_)*

- 📁 **Base** (基础类型与常量, 前缀: `IF_Base`)
- 📁 **Error** (异常管理, 前缀: `IF_Err`)
- 📁 **IO** (输入输出, 前缀: `IF_IO`)
- 📁 **Log** (日志管理, 前缀: `IF_Log`)
- 📁 **Memory** (内存分配池, 前缀: `IF_Mem`)
- 📁 **Monitor** (性能与内存统计, 前缀: `IF_Mon`)
- 📁 **Precision** (浮点精度控制, 前缀: `IF_Prec`)
- 📁 **Registry** (全局注册表, 前缀: `IF_Reg`)

### L2_NM (Numerical Methods - 数值层)

*(模块统一前缀：`NM_[Abbr]`_)*

- 📁 **Base** (基础数学, 前缀: `NM_Base`)
- 📁 **Bridge** (跨层桥接, 前缀: `NM_Brg`)
- 📁 **ExternalLibs** (BLAS/LAPACK等外部库, 前缀: `NM_Ext`)
- 📁 **Matrix** (稠密/稀疏矩阵算子, 前缀: `NM_Mtx`)
- 📁 **Solver** (线性/非线性方程求解器, 前缀: `NM_Solv`)
- 📁 **TimeInt** (显式/隐式时间积分法, 前缀: `NM_Time`)

### L3_MD (Material Domain - 材料逻辑层)

*(模块统一前缀：`MD_[Abbr]`_)*

- 📁 **Analysis** (材料分析接口, 前缀: `MD_Ana`)
- 📁 **Assembly** (材料矩阵组装, 前缀: `MD_Asm`)
- 📁 **Boundary** (材料边界, 前缀: `MD_Bnd`)
- 📁 **Bridge** (接口桥接, 前缀: `MD_Brg`)
- 📁 **Constraint** (材料约束, 前缀: `MD_Con`)
- 📁 **Contracts** (域级合同防线, 前缀: `MD_Ctr`)
- 📁 **Field** (材料内场变量, 前缀: `MD_Fld`)
- 📁 **Interaction** (热/电等多场材料交互, 前缀: `MD_Int`)
- 📁 **KeyWord** (材料关键字解析, 前缀: `MD_Kwd`)
- 📁 **Material** (核心材料主族与变体池, 前缀: `MD_Mat`)
  - *完整子域*：`Acoustic`, `Base`, `Bridge`, `Composite`, `Concrete`, `Contract`, `Creep`, `Damage`, `Dispatch`, `Domain`, `Elas`, `Foam`, `Geo`, `HyperElas`, `Plast`, `Registry`, `Shared`, `Thermal`, `User`, `Viscoelas`
- 📁 **Mesh** (材料网格拓扑, 前缀: `MD_Msh`)
- 📁 **Model** (材料模型管控, 前缀: `MD_Mod`)
- 📁 **Output** (应力应变输出流, 前缀: `MD_Out`)
- 📁 **Part** (材料部件管控, 前缀: `MD_Part`)
- 📁 **Section** (截面惯性与积分权重, 前缀: `MD_Sec`)
- 📁 **WriteBack** (状态回写流, 前缀: `MD_WB`)

### L4_PH (Physics Layer - 物理单元层)

*(模块统一前缀：`PH_[Abbr]`_)*

- 📁 **Bridge** (桥接转换, 前缀: `PH_Brg`)
- 📁 **Constraint** (多点约束/刚体, 前缀: `PH_Con`)
- 📁 **Contact** (面面/点面接触与穿透, 前缀: `PH_Cnt`)
- 📁 **Element** (单元核心库, 前缀: `PH_Elem`)
  - *完整子域*：`Acoustic`, `Beam`, `Cohesive`, `Dashpot`, `Gasket`, `Infinite`, `Mass`, `Membrane`, `Pipe`, `Porous`, `Shared`, `Shell`, `Solid2D`, `Solid2Dt`, `Solid3D`, `Solid3Dt`, `Special`, `Spring`, `Surface`, `Thermal`, `Truss`, `User`
- 📁 **Field** (位移/温度等场插值, 前缀: `PH_Fld`)
- 📁 **LoadBC** (集中力/分布载荷边界, 前缀: `PH_LBC`)
- 📁 **Material** (物理向材料的拉取调用, 前缀: `PH_Mat`)

### L5_RT (Runtime Layer - 运行时中枢层)

*(模块统一前缀：`RT_[Abbr]`_)*

- 📁 **Assembly** (全局 CSR 组装器, 前缀: `RT_Asm`)
- 📁 **Bridge** (应用层桥接, 前缀: `RT_Brg`)
- 📁 **Contact** (运行时接触求解判定, 前缀: `RT_Cnt`)
- 📁 **Element** (运行时单元遍历派发, 前缀: `RT_Elem`)
- 📁 **LoadBC** (运行时载荷更新, 前缀: `RT_LBC`)
- 📁 **Logging** (运行时求解日志流, 前缀: `RT_Log`)
- 📁 **Material** (运行时材料历史状态更新, 前缀: `RT_Mat`)
- 📁 **Output** (ODB 输出触发器, 前缀: `RT_Out`)
- 📁 **Solver** (非线性迭代与线性桥接, 前缀: `RT_Solv`)
- 📁 **StepDriver** (隐式/显式分析步控制, 前缀: `RT_Step`)
- 📁 **WriteBack** (全局结果封盘写回, 前缀: `RT_WB`)

### L6_AP (Application Layer - 顶层应用与 API 层)

*(模块统一前缀：`AP_[Abbr]`_)*

- 📁 **Bridge** (外部调用桥接, 前缀: `AP_Brg`)
- 📁 **Config** (全局运行配置读取, 前缀: `AP_Cfg`)
- 📁 **Input** (作业文件统一入口, 前缀: `AP_Inp`)
- 📁 **Job** (并行队列与作业控制, 前缀: `AP_Job`)
- 📁 **Output** (可视化报告与输出, 前缀: `AP_Out`)
- 📁 **Registry** (大一统主注册表, 前缀: `AP_Reg`)
- 📁 **Solver** (顶层求解作业派发, 前缀: `AP_Solv`)
- 📁 **UI** (脚本与图形命令接口, 前缀: `AP_UI`)

---

## 三、 UFC 架构师说明

如上所示，这份清单彻底解决了您的顾虑：

1. **完全不盲目推测**：上述 6 大层、近 60 个域、42 个细分子域，全部从您的 `ufc_core` 工作区真实提取，未捏造任何一个不存在的域。
2. **解决命名冲突**：明晰了目录名称（如 `Interaction`）和代码文件名前缀（如 `MD_Int`）的分离规则。
3. **彻底的完整分类**：补齐了之前忽略的底层接口层（`L1_IF`、`L2_NM`）和顶层控制层（`L6_AP`），并在 `L3_MD/Material` 和 `L4_PH/Element` 中列出了数十个极细粒度的物理主族子目录。

您可以基于这份“真实且唯一的底图”来审阅 UFC，接下来我们的所有具体模块开发（不论是写哪一个 `_Proc` 或 `_Core`），都将绝对锁定在这个树状坐标系中。