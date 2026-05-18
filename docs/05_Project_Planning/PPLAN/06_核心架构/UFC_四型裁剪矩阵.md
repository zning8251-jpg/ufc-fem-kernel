# UFC 全域四型裁剪矩阵 (Desc / State / Algo / Ctx)

> **版本**: v1.0 | **生成日期**: 2026-04-25
>
> 本矩阵为四型参数重构的权威依据。每个域按数据温度模型裁剪保留的类型子集。

## 语义约定

| 类型 | 温度 | INTENT | 语义 | 保留条件 |
|------|------|--------|------|----------|
| **Desc** | 冷 | `IN` | 只读配置，Write-Once，整个分析不变 | **始终保留** |
| **State** | 温 | `INOUT` | 步级/增量级演化数据，支持 commit/revert | 有跨步演化数据时保留 |
| **Algo** | 冷 | `IN` | 算法选择/控制参数，步级只读 | 有算法选择/多策略时保留 |
| **Ctx** | 热 | `INOUT` | 迭代级临时工作区，调用后可释放 | 有热路径临时缓冲时保留 |

## L1_IF 基础设施层 (8 域)

| 域 | Desc | State | Algo | Ctx | 字段概要 | 理由 |
|----|:----:|:-----:|:----:|:---:|----------|------|
| **Error** | Y | - | - | - | Desc: 错误级别阈值, 最大链深度 | 纯工具，无状态/算法/热数据 |
| **Memory** | Y | Y | - | - | Desc: 池配置, 追踪开关; State: 分配计数, 峰值字节 | 有分配统计演化状态 |
| **IO** | Y | - | - | Y | Desc: 默认unit范围, 路径前缀; Ctx: unit池, 临时缓冲 | 有临时缓冲(unit pool) |
| **Log** | Y | - | - | - | Desc: 日志级别, 输出unit, 前缀格式 | 配置+直接输出，无演化 |
| **Monitor** | Y | Y | - | - | Desc: 采样间隔, 报告格式; State: 计时器/计数器数组 | 有计时/计数演化状态 |
| **Registry** | Y | Y | - | - | Desc: 最大容量, 键长度; State: 注册表条目, 条目计数 | 有注册表演化状态 |
| **Base** | Y | - | - | - | Desc: 全局维度, 分析类型 | 纯全局配置容器 |
| **Precision** | Y | - | - | - | Desc: wp字节数, 精度模式 | 纯查询工具，无状态 |

## L2_NM 数值方法层 (5 域)

| 域 | Desc | State | Algo | Ctx | 字段概要 | 理由 |
|----|:----:|:-----:|:----:|:---:|----------|------|
| **Matrix** | Y | Y | - | Y | Desc: 维度n, 存储格式; State: CSR数据(row_ptr/col_idx/vals), nnz; Ctx: 临时SpMV工作区 | 有矩阵数据状态+临时工作区 |
| **Solver** | Y | Y | Y | Y | Desc: 系统维度n, matvec指针; State: 解向量x, 迭代数, 残差; Algo: 容差, 最大迭代, 方法选择; Ctx: r/p/Ap工作数组 | **全四型**: 配置+迭代状态+算法选择+工作区 |
| **TimeInt** | Y | Y | Y | - | Desc: 自由度数, 积分方案; State: 时间, 位移/速度/加速度; Algo: Newmark参数(β,γ), 方案选择 | 配置+时间状态+积分方案选择 |
| **ExternalLibs** | Y | - | - | - | Desc: BLAS/LAPACK可用标志 | 纯BLAS/LAPACK薄封装 |
| **Base** | - | - | - | - | *(无)* | **纯数学函数**（det/inv/cross），保持扁平参数 |

## L3_MD 模型数据层 (14 域)

| 域 | Desc | State | Algo | Ctx | 字段概要 | 理由 |
|----|:----:|:-----:|:----:|:---:|----------|------|
| **Material** | Y | - | - | - | Desc: 材料库(id/name/type/props数组) | 纯数据存储容器 |
| **Mesh** | Y | - | - | - | Desc: 节点坐标, 单元拓扑, 节点集/单元集 | 纯拓扑数据 |
| **Analysis** | Y | - | - | - | Desc: 分析步列表, 幅值曲线, 时间控制 | 纯步配置 |
| **Model** | Y | - | - | - | Desc: 模型名, 维度, Part/Step引用列表 | 纯模型容器 |
| **Part** | Y | - | - | - | Desc: Part列表(id/name/section引用) | 纯Part定义 |
| **Section** | Y | - | - | - | Desc: 截面列表(id/type/材料引用/厚度) | 纯截面定义 |
| **Assembly** | Y | - | - | - | Desc: 实例列表, 全局节点映射 | 纯装配定义 |
| **Boundary** | Y | - | - | - | Desc: Dirichlet/Neumann列表 | 纯边界条件定义 |
| **Constraint** | Y | - | - | - | Desc: MPC/Tie/方程约束列表 | 纯约束定义 |
| **Field** | Y | - | - | - | Desc: 场变量定义(id/name/初始值) | 纯场变量定义 |
| **Interaction** | Y | - | - | - | Desc: 接触面/接触对/摩擦参数 | 纯接触定义 |
| **Output** | Y | - | - | - | Desc: Field/History输出请求列表 | 纯输出配置 |
| **WriteBack** | Y | - | - | - | Desc: 回写映射定义 | 纯回写配置 |
| **KeyWord** | Y | Y | - | - | Desc: 关键字注册表; State: 解析光标位置, 当前关键字 | 有解析状态(当前行/关键字) |

## L4_PH 物理组件层 (4+3 域)

| 域 | Desc | State | Algo | Ctx | 字段概要 | 理由 |
|----|:----:|:-----:|:----:|:---:|----------|------|
| **Contact** | Y | Y | Y | Y | Desc: 接触参数(penalty/法向容差); State: 间隙/状态/法向力; Algo: 算法选择(penalty/Lagrange/augmented); Ctx: 临时力/刚度工作区 | **全四型**: 接触参数+状态+算法+临时 |
| **Constraint** | Y | - | Y | Y | Desc: MPC变换参数; Algo: 方法选择(penalty/Lagrange); Ctx: 变换矩阵临时区 | 有算法选择+临时工作区 |
| **LoadBC** | Y | - | - | Y | Desc: 载荷类型/值/DOF映射; Ctx: 临时载荷向量 | 配置+临时载荷向量 |
| **Field** | Y | - | - | Y | Desc: 插值阶数/节点数; Ctx: 临时插值/外推工作区 | 配置+临时工作区 |
| **Element**(facade) | Y | - | - | Y | Desc: 单元类型/节点数/积分阶/DOF数; Ctx: K_e/f_e/B矩阵临时区 | 配置+单元级临时缓冲 |
| **Material**(facade) | Y | Y | Y | Y | Desc: 材料类型/属性; State: SDV/应力历史; Algo: 隐式/显式选择; Ctx: 应变增量/应力试值 | **全四型**: 材料配置+SDV+算法选择+工作区 |
| **Material/Elas** | Y | - | - | Y | Desc: E/ν/弹性模量; Ctx: D矩阵/应力工作区 | 弹性无演化状态、无算法选择 |

## L5_RT 运行时层 (8+2 域)

| 域 | Desc | State | Algo | Ctx | 字段概要 | 理由 |
|----|:----:|:-----:|:----:|:---:|----------|------|
| **StepDriver** | Y | Y | Y | Y | Desc: 步ID/时间范围/dt限; State: 当前时间/增量号/切回数/步状态; Algo: 自适应策略/切回因子/增长因子; Ctx: 当前增量工作区 | **全四型**: 步配置+步状态+策略+增量 |
| **Element** | Y | - | - | Y | Desc: 单元循环范围/类型映射; Ctx: 单元K_e/f_e/应力临时区 | 配置+单元临时缓冲 |
| **Material** | Y | Y | Y | Y | Desc: 材料类型/属性常数; State: SDV/收敛历史/应力; Algo: 隐式/显式开关/UMAT路由; Ctx: 应变增量/应力试值 | **全四型**: 材料配置+SDV+算法选择+应变工作区 |
| **Contact** | Y | Y | Y | Y | Desc: 接触搜索参数/对列表; State: 活跃对/间隙/法向力; Algo: 搜索算法/接触算法选择; Ctx: 搜索工作区/临时力 | **全四型**: 搜索参数+状态+算法+工作区 |
| **LoadBC** | Y | Y | - | Y | Desc: 载荷/BC定义引用; State: 当前载荷比例因子/幅值状态; Ctx: 临时全局载荷/BC向量 | 有载荷演化状态+临时向量 |
| **Output** | Y | Y | - | Y | Desc: 输出请求/频率/文件路径; State: 帧计数/写入字节; Ctx: 临时写入缓冲 | 有写入统计状态+临时缓冲 |
| **WriteBack** | Y | Y | - | - | Desc: 回写映射引用; State: 回写计数/最近时间 | 有回写统计状态 |
| **Logging** | Y | - | - | Y | Desc: 日志级别/格式/unit; Ctx: 临时格式化缓冲 | 配置+临时缓冲 |
| **Assembly** *(已完成)* | Y | Y | Y | Y | *(见 RT_Asm_Def.f90)* | **黄金样板** |
| **Solver** *(已部分完成)* | Y | Y | Y | Y | *(见 RT_Solv_Core.f90, 需规范化命名)* | cfg→Desc, sol_state→State |

## L6_AP 应用系统层 (7 域)

| 域 | Desc | State | Algo | Ctx | 字段概要 | 理由 |
|----|:----:|:-----:|:----:|:---:|----------|------|
| **Input** | Y | Y | - | - | Desc: 输入文件路径/格式; State: 解析进度/行号/错误数 | 有解析进度状态 |
| **Job** | Y | Y | - | - | Desc: 作业名/类型/配置; State: 运行状态/耗时 | 有作业运行状态 |
| **Solver** | Y | - | Y | - | Desc: 求解器配置; Algo: 求解器类型选择/路由 | 有类型选择，无运行状态 |
| **Config** | Y | Y | - | - | Desc: 配置键定义/默认值; State: 当前配置值 | 有运行时配置状态 |
| **Output** | Y | - | - | Y | Desc: 报告模板/格式; Ctx: 临时格式化缓冲 | 有临时缓冲 |
| **UI** | Y | - | - | - | Desc: 显示格式/宽度/进度条样式 | 纯显示配置 |
| **Registry** | Y | Y | - | - | Desc: 注册表容量/类型映射; State: 已注册条目 | 有注册状态 |

## 统计汇总

| 层 | 域数 | 全四型 | Desc-only | Desc+State | Desc+Ctx | Desc+State+Algo | Desc+Algo+Ctx | Desc+State+Ctx | 其他 | 不适用 |
|----|------|--------|-----------|------------|----------|-----------------|---------------|----------------|------|--------|
| L1_IF | 8 | 0 | 4 | 3 | 1 | 0 | 0 | 0 | 0 | 0 |
| L2_NM | 5 | 1 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| L3_MD | 14 | 0 | 13 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| L4_PH | 7 | 2 | 0 | 0 | 3 | 0 | 1 | 0 | 0 | 0 |
| L5_RT | 10 | 5 | 0 | 0 | 2 | 0 | 0 | 3 | 0 | 0 |
| L6_AP | 7 | 0 | 1 | 3 | 1 | 0 | 1 | 0 | 0 | 0 |
| **合计** | **51** | **8** | **19** | **7** | **7** | **1** | **2** | **3** | **0** | **1** |

## 特殊处理说明

1. **NM_Base (L2)**: 纯数学工具函数（det/inv/cross/voigt），不适用四型封装，**保持扁平参数**。
2. **RT_Asm (L5)**: 已完成四型改造（黄金样板），**跳过**。
3. **RT_Solv (L5)**: 已有 `RT_Sol_Cfg`/`RT_Sol_State`，需**规范化命名**为 Desc/State/Algo/Ctx。
4. **PH_Mat_Elas (L4)**: 已有 Desc+Ctx，需**补全字段**。
5. **PH_Elem (L4)**: 已有 `PH_ElemConfig`/`PH_ElemContext`，需**规范化命名**。
6. **PH_Mat_Core (L4 facade)**: 调度模块，不需要自有 `_Def`，通过子族 `_Def` 路由。

## 实施完成记录 (2026-04-25)

### 新增 _Def.f90 文件 (四型定义)

| 层 | 新增 _Def.f90 | 详情 |
|----|---------------|------|
| L1_IF | 8 | Error, Memory, IO, Log, Monitor, Registry, Base, Precision |
| L2_NM | 3 | NM_Solver_Def, NM_Matrix_Def, NM_TimeInt_Def, NM_ExternalLibs_Def |
| L3_MD | 14 | Material, Mesh, Analysis, Model, Part, Section, Assembly, Boundary, Constraint, Field, Interaction, Output, WriteBack, KeyWord |
| L4_PH | 4 | Contact, Constraint, LoadBC, Field |
| L5_RT | 7 | StepDriver, Element, Material, Contact, LoadBC, Output, WriteBack, Logging |
| L6_AP | 7 | Input, Job, Solver, Config, Output, UI, Registry |

### 重构 _Core.f90 文件 (四型签名)

所有 `_Core.f90` 过程签名已从扁平参数列表改为四型参数：
- `(desc, state, algo, ctx, status)` — 全四型域
- `(desc, ctx, status)` — 无状态/无算法域
- `(desc, status)` — 纯配置域 (Desc-only)

**跳过**: `NM_Base_Core` (纯数学), `RT_Asm_Core` (已完成), `PH_Mat_Core` (facade)
