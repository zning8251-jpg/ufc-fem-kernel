# UFC 功能子程序开发步步为营指南 (Feature Implementation SOP)

本指南旨在将 UFC 的宏观架构（六层结构、四大类型、三重正交坐标）降维为**对单个“功能模块（如某个特定单元、本构或组装算法）”的精确施工图纸**。

任何 UFC 功能子程序的开发或旧资产（`UF_*`）改造，必须严格按照以下 **4 大阶段、12 个明确步骤（Step-by-Step）** 执行，犹如工业流水线般严丝合缝。

---

## 阶段零 (Phase 0)：三维定位与蓝图确认
在写下第一行代码前，必须在架构图谱上锚定该功能的绝对坐标。

*   **Step 0.1 确定层与域 (Layer & Domain)**：
    *   它是属于哪一层？（L1_IF, L2_NM, L3_MD, L4_PH, L5_RT, L6_AP）
    *   它是属于哪个域？（如：`PH_Elem`, `MD_Mat`, `RT_Asm`）
    *   *产出确定*：确定了文件的前缀，如 `PH_Elem_`。
*   **Step 0.2 确定三重正交算法时空 (Time-Space-Action)**：
    *   **空间轴 (Space)**：Glb(全局), Dom(子域), Elm(单元), Pt(积分点), Face(面)
    *   **时间轴 (Time)**：Init(初始化), Inc(增量步), Itr(牛顿迭代)
    *   **动作轴 (Action)**：Pre(准备), Evl(核心计算), Post(后处理更新)
    *   *产出确定*：确定了入口子程序的后缀名，例如 `PtItrEvl` (积分点-迭代-计算核心)。

---

## 阶段一 (Phase 1)：数据结构极简塑形 (Data Structure Design)
**目标文件**：`[Prefix]_[Domain]_Def.f90`
**核心法则**：将旧代码中几百个散乱的局部变量、COMMON块，强制归炉到四大 TYPE 中。绝不允许在定义数据结构的文件名中使用四大类型作为后缀。

*   **Step 1.1 提取 `_Desc` (静态只读配置)**：
    *   剥离所有在分析过程中**绝对不会改变**的物理属性（如弹性模量、泊松比、单元节点数）。
*   **Step 1.2 提取 `_State` (演化历史变量)**：
    *   剥离所有**依赖路径、需要保存到下一步**的状态变量（如等效塑性应变、损伤因子、背应力张量）。
*   **Step 1.3 提取 `_Algo` (算法控制开关)**：
    *   剥离所有的**无状态非物理控制参数**（如最大迭代次数、收敛容差、是否开启B-bar防锁死的逻辑开关）。
*   **Step 1.4 提取 `_Ctx` (软缓存与上下文)**：
    *   定义**本迭代步内部临时使用**的工作内存（如试探应力、当前高斯点的 B 矩阵），算完即焚，不保留到下一步。
*   **Step 1.5 封装 `_Arg` (跨层 SIO 通讯包)**：
    *   针对 Phase 0 确定的坐标（如 `PtItrEvl`），定义对应的输入输出包 `[Domain]_[Coordinate]_Arg`（如 `MD_Mat_PtItrEvl_Arg`）。
    *   必须带有严格的 `[IN]` 和 `[OUT]` 注释标记。

---

## 阶段二 (Phase 2)：算法过程的三维正交编排 (Algorithmic Process Routing)
**目标文件**：`[Prefix]_[Domain]_Proc.f90`
**核心法则**：这里是流水线的传送带，只管分发，不准含有具体的物理或数学计算公式。

*   **Step 2.1 声明标准的 5参/6参 SIO 签名**：
    *   `SUBROUTINE [Prefix]_[Domain]_Proc_[Coordinate](desc, state, algo, ctx, arg)`
*   **Step 2.2 跨层嵌套解包 (仅限贯通域柱的中间层)**：
    *   例如 L4 调用 L3 时，在此处将 L4 的大 `Ctx` 软缓存拆解，提取出属于 L3 的 `mat_ctx`。
*   **Step 2.3 核心路由分发 (Routing)**：
    *   通过 `SELECT CASE (desc%feature_id)`（如材料ID、单元ID），将控制流精确制导并派发给 `_Core.f90` 中的对应物理黑盒。
*   **Step 2.4 异常冒泡拦截 (Error Bubbling)**：
    *   检查返回的 `arg%err_code`。如果非 0（发生畸变、材料不收敛等），立即 `RETURN`，将异常向上层抛出，绝不在此处做容错掩盖。

---

## 阶段三 (Phase 3)：核心算子的黑盒锻造 (Core Operator Implementation)
**目标文件**：`[Prefix]_[Domain]_Core.f90`
**核心法则**：这是 UFC 最硬核的数学物理禁区。外部进不来，内部不依赖。

*   **Step 3.1 物理逻辑移栽与剥离**：
    *   将旧的本构推导、雅可比矩阵求逆、形函数导数计算代码，完整地复制到此处的 `SUBROUTINE [Prefix]_[Domain]_Core_[FeatureName]_[Coordinate]` 中。
*   **Step 3.2 命名空间净化大扫除**：
    *   **抹杀前缀**：把旧代码里所有的 `UF_`、`C_` 等历史前缀全部删掉。
    *   **蛇形强制**：所有内部局部变量全部改为极简的 `snake_case`（如 `g_mod`, `trial_stress`）。
*   **Step 3.3 结果封装与回填**：
    *   计算完成后，将结果（如切线刚度矩阵、当前应力）精确装入 `arg` 的 `[OUT]` 字段中。

---

## 阶段四 (Phase 4)：高阶防线与外部桥接 (Advanced Hook & Bridging) - 可选
**目标文件**：`[Prefix]_[Domain]_Brg.f90` 或 `_Ops.f90`

*   **Step 4.1 挂载外挂数学库 (`_Brg.f90`)**：
    *   如果当前功能涉及求解大型稀疏矩阵（如 L2_NM 层接入 PETSc / MKL / AMG），必须通过 `_Brg.f90` 做防腐层转换 CSR 格式。
*   **Step 4.2 张量或通用数学库操作 (`_Ops.f90`)**：
    *   如果涉及到大量通用的张量偏导、极分解等纯数学操作，提取为无状态的 `_Ops` 子程序进行调用。

---
**执行准则总结**：任何模块的开发，必须按 `Def (选材)` -> `Proc (布管)` -> `Core (灌浆)` 的绝对顺序推进！不允许跨步！