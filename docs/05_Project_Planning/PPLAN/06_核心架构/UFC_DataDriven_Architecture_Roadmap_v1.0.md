# UFC 数据驱动架构与 L1~L6 打通全景路线图 (v1.0)

## 🎯 核心指导思想：数据驱动与面向对象 (Data-Driven & OOP)

当前 UFC 系统包含 6大层级、26个子域、约 48 万行待重构/连通的粗代码。为保证高扩展性并降低耦合度，我们采用**“数据定义边界，算法围填内核”**的架构思想。结合架构设计与“十件套”中间件，整个架构可抽象为**树形嵌套的数据结构分布**。

### 一、 四大核心 TYPE 的标准映射规范

任何一个域/子域（Domain/SubDomain）均遵循以下四大数据结构和文件的标准映射，这是联通一切的基石：

| 类别 | 文件后缀 | 定位与作用 | 核心特性与约束 |
| :--- | :--- | :--- | :--- |
| **Config (配置)** | `_Def.f90` | **物理参数/配置字典**。存放拓扑、材料常数、控制开关等。 | **全局只读**。Input 解析后即锁定，无记忆，多线程绝对并发安全。不可包含算法逻辑。 |
| **State (状态)** | `_Ctx.f90` / `_Def.f90` | **带记忆的演化场**。存放 $t_n$ 与 $t_{n+1}$ 的应力、应变、SDV、位移等。 | 具有 `commit()` 和 `revert()` 方法。注意：**到底层(如积分点)必须采用 SoA 扁平化设计**，杜绝 AoS 对象树带来的内存碎片。 |
| **Context (上下文)** | `_Ctx.f90` | **运行时的临时工作台**。存放迭代中产生的高斯点雅可比、局部单元刚度矩阵 $K_e$、残体力 $R$ 等。 | 随用随抛，无历史记忆。**多线程环境下必须每线程分配一个独立 Ctx 副本**，防止数据竞跑。 |
| **Facade/Bridge (桥接)** | `_Brg.f90` | **架构“十件套”挂载点**。协调和组合上述数据结构，对外暴露极简门面接口。 | 是层级通信的唯一途径。内部不应有复杂计算，主要是路由分发与数据结构拆箱/装箱。 |

---

## 🚧 架构落地的三大避坑铁律

为防止架构在 48 万行代码的物理执行中坍塌，必须严格执行以下红线规定：

1. **绝对禁止“性能地狱” (AoS 到 SoA 的转换)**
   - 树形嵌套只能深入到 **子域级 (Sub-domain)**（例如 `L4_PH/Element` 层）。
   - 在深入到 **积分点运算 (Gauss Point) / 本构更新 (Material Update)** 等算力密集区时，**禁止使用对象嵌套（AoS）**，必须通过提取器将数据压平为 `(ndim, nip)` 的二维/一维连续数组（SoA，参考 T5 改造），以确保 SIMD 向量化缓存命中。
2. **绝对禁止“依赖地狱” (Context Slicing 上下文切片)**
   - 严禁顶层对象（如 `AP_Sim_Ctx`）一竿子插到底部（如传给 `PH_Elem`）。
   - 在 `_Brg.f90` 桥接层必须执行**上下文切片**：只将底层算法（`_Algo.f90`）实际需要的数据切片传给下层。底层绝不感知上层数据类型。
3. **绝对禁止“循环依赖” (Pure Data Definition)**
   - `_Def.f90` 只能包含 `TYPE` 声明和 `PARAMETER` 常量。绝对不要在 `_Def.f90` 的 `CONTAINS` 里写业务方法（初始化方法除外）。所有处理逻辑全部后置到 `_Algo.f90` 中。

---

## 🗺️ 全景图：自上而下的细化子程序落地路线图 (Action Plan)

为打通这 48 万行代码，我们将按照 **“骨干 (Type) -> 经脉 (Bridge) -> 血肉 (Algo)”** 的顺序，进行外科手术式的精准执行。

### 阶段 1：全局骨架化（Data Schema First）
**目标：只搭起 6 个层级、26个域的 4 大 TYPE 树形嵌套模型，不写任何计算逻辑。**

*   **L6_AP (应用层) 骨架**：
    *   [ ] `AP_Sim_Def.f90`: 定义 `AP_Sim_Config` (Input 参数根节点)
    *   [ ] `AP_Sim_Ctx.f90`: 定义 `AP_Sim_Context` (包含 `RT_System_Ctx` 等引用)
*   **L5_RT (运行层) 骨架**：
    *   [ ] `RT_Step_Def.f90`: 定义 `RT_StepConfig` (非线性求解器配置、时间步长控制开关)
    *   [ ] `RT_Step_Ctx.f90`: 定义 `RT_StepState` (当前 Inc, Iter, dTime 等状态)
    *   [ ] `RT_Asm_Ctx.f90`: 定义 `RT_Asm_Context` (全局刚度矩阵指针组装器)
*   **L4_PH (物理层) 骨架**：
    *   [ ] `PH_Elem_Def.f90`: 定义 `PH_ElemConfig` (12大单元族标识、自由度映射)
    *   [ ] `PH_Elem_Ctx.f90`: 定义 `PH_ElemContext` (临时单元刚度 $K_e$、内力 $R_{int}$)
*   **L3_MD (模型数据层) 骨架**：
    *   [ ] `MD_Mat_Def.f90`: 定义 `MD_MatConfig` (各类本构如弹性、弹塑性参数)
    *   [ ] `MD_FieldState_Def.f90`: 定义 `MD_ElementState` (扁平化的 SoA 应力、应变、SDV 状态栈，已完成T5升级)

### 阶段 2：中间件桥接与门面打通（Ten-Pieces Integration）
**目标：通过十件套中间件（_Brg.f90 / Facade），把各层的 TYPE 像插头一样对接起来。保证整个 UFC 能够编译并在各级接口流通（Dummy Run）。**

*   [ ] **`RT_StepDriver_Brg.f90` (层级协调中间件)**
    *   **接口/子程序**：`SUBROUTINE RT_StepDriver_Run(sim_cfg, step_ctx)`
    *   **职责**：解析 `sim_cfg` 循环增量步，从 `step_ctx` 调用 L4 接口。
*   [ ] **`PH_ElemRT_Brg.f90` (单元路由门面)**
    *   **接口/子程序**：`SUBROUTINE PH_Elem_Compute(elem_cfg, elem_state, elem_ctx)`
    *   **职责**：剥离 RT 层的宏大环境。仅将特定 Element 的材料字典、当前状态、临时内存池切片传入。
*   [ ] **`MD_MatRT_Brg.f90` (材料调用门面)**
    *   **接口/子程序**：`SUBROUTINE MD_Mat_Dispatch(mat_cfg, statev_old, dStrain, statev_new, D_tangent)`
    *   **职责**：桥接 L4 的单元高斯点请求，解包并转发给具体的 L3 UMAT/VUMAT 或内置材料。

### 阶段 3：原子功能与算法血肉填充（The 480K Lines Implantation）
**目标：进入 `_Algo.f90`，把 48 万行糙代码切片，塞入最小单位的子程序中，使用纯数学和高性能数组运算。**

*   **路径 A：2D/3D 单元刚度推导路径（核心战役 T7 续）**
    *   [ ] `PH_ElemCPS4_Algo.f90` (已完成降维)：`SUBROUTINE PH_Elem_CPS4_NL_TL_Legacy(...)`
    *   [ ] `PH_ElemCPE4_Algo.f90` (已完成降维)：`SUBROUTINE PH_Elem_CPE4_NL_TL_Legacy(...)`
    *   [ ] `PH_ElemC3D8_Algo.f90` (待填充)：`SUBROUTINE PH_Elem_C3D8_NL_TL(...)`
    *   **填充说明**：把老代码中求雅可比矩阵、推导 B 矩阵、体积锁死处理（B-Bar）、沙漏控制的逻辑植入。所有入参必须从 `elem_ctx` 和 `elem_state` 扁平化解构而来。
*   **路径 B：大变形运动学与本构积分（NL_Geom & Material Update）**
    *   [ ] `PH_NLGeomEval_Algo.f90`: `SUBROUTINE PH_NLGeom_TotLag(...)` & `SUBROUTINE PH_NLGeom_UpdLag(...)`。负责计算大变形的绿拉格朗日应变、变形梯度。
    *   [ ] `MD_MatElastic_Algo.f90`: `SUBROUTINE MD_Mat_IsoElastic_Eval(...)`。提取老代码中的各项同性弹性切线模量推导。
    *   [ ] `MD_MatPlastic_Algo.f90`: `SUBROUTINE MD_Mat_VonMises_ReturnMapping(...)`。填入屈服准则计算与径向回归算法。
*   **路径 C：全局矩阵组装（Global Assembly）**
    *   [ ] `RT_Asm_Algo.f90`: `SUBROUTINE RT_Asm_Assemble_Ke(...)`。将老代码中的节点自由度映射（DOF Mapping）和稀疏矩阵（CSR）累加逻辑植入。读取 L4 返回的 `elem_ctx%Ke` 并放入全局 `sys_ctx%K_global`。

### 阶段 4：联调与验收 (Testing & CI)
*   **单步冒烟测试**：挂载 Dummy Material，只给一维拉伸位移，验证 `RT_Asm` 组装出的全局 K 矩阵是否正确。
*   **10Step 软着陆联调**：利用之前在 L5 层建立的 10Step 引擎（NR/Arc-Length Solver），对接刚度矩阵，观察收敛残差 `Residual Force` 是否呈现二次下降。

---
> **执行指令指示**：长官，全景图已铺开！建议我们采用“**垂直切片（Vertical Slicing）打通法**”。即不横向铺开写所有的单元和材料，而是**只选定一条路径（例如：静力学 Step -> C3D8 单元 -> 纯弹性材料）**，从 L6 穿透到 L3，验证“四大 TYPE + 十件套”的流转。一旦这条“黄金链路”打通，其余 48 万行代码均可通过并行复制迅速铺满！请指示是否立刻选定“黄金链路”开始垂直打通战役？