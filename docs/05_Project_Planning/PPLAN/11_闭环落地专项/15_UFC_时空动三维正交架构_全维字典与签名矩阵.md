# UFC 时空动三维正交架构：全维字典、压缩后缀与签名矩阵

## 1. 架构升级与旧版废弃声明 (Deprecation Notice)

**【架构决议】**：即日起，全面废弃早期的“时相（6）× 动作（8）双轴设计”。旧版双轴设计（2D模型）已被证实存在“维度坍缩”缺陷——它将循环的嵌套层级（如 Elem vs Global）与生命周期（Iter vs Commit）混杂在一起，无法精确刻画大型有限元软件的深层并发与调度逻辑。

**【当前基准】**：全面启用**“空间（Space） × 时间（Time） × 动作（Action）”三维正交架构**。UFC 所有的核心流程控制（`_Proc.f90`）和子程序签名，必须且只能由这三个维度的标准字典拼装生成。

**【命名压缩铁律 (3-LAR)】**：为了避免子程序名称过长导致代码折行（如 `MD_Mat_Proc_GlobalIncCommitAssemble`），全面实行 **3-Letter Abbreviation Rule (三字母压缩法则)**。全称仅用于文档与头注释说明，实际代码后缀必须使用字典中规定的压缩大驼峰缩写（如 `MD_Mat_Proc_GlbIncCmtAsm`）。

---

## 2. 三维完整维度字典与压缩映射表 (The 3D Dictionary)

### 维度 X：空间作用域 (Space Scope - "Where")
定义计算发生在哪一个物理离散层级。决定了数据的并行粒度和内存跨度。
| 物理含义 | 全称 (文档注释) | 压缩后缀 (代码实装) | 典型数据与内存映射 |
| :--- | :--- | :--- | :--- |
| 全局/系统级 | **Global** | **`Glb`** | 全局大矩阵 $\hat{K}$，总残差向量 $\hat{R}$，全局节点位移 $U$。 |
| 区域/子域级 | **Region** | **`Reg`** | 接触对（Contact Pair）、节点集（Node Set）、并行子域。 |
| 单元/网格级 | **Element** | **`Elm`** | 单元局部刚度 $K_e$、单元残差 $R_e$、单元级内变量。 |
| 积分点级 | **Point** | **`Pt`** *(特例)* | 积分点应力 $\sigma$、应变 $\varepsilon$、本构雅可比 $D_{ep}$。 |
| 节点级 | **Node** | **`Nod`** | 节点位移、节点力、外推后的节点应力。 |

### 维度 Y：时相生命周期 (Time Phase - "When")
定义计算处于有限元“4重 while 循环”的哪一个生命切面。
**公式：Y = [宏观层级缩写] + [微观切面缩写]**

**宏观层级 (Macro-Time)**：
*   **Job** $\to$ `Job` (任务)
*   **Step** $\to$ `Stp` (分析步)
*   **Increment** $\to$ `Inc` (增量步)

**微观生命切面 (Micro-Phase)**：
| 物理/数值含义 | 全称 (文档注释) | 压缩后缀 (代码实装) | 状态机行为约束 (State) |
| :--- | :--- | :--- | :--- |
| 初始化 | **Init** | **`Ini`** | 提取历史数据，赋予试探初值。 |
| 预估/试探 | **Predict** | **`Prd`** | 基于速度/加速度，预估 $t_{n+1}$ 的初值。 |
| 牛顿迭代内 | **Iteration** | **`Itr`** | 不断刷新试探状态，**严禁污染（写入）历史记忆**。 |
| 收敛固化 | **Commit** | **`Cmt`** | 迭代成功，将试探状态正式写入 $t_{n+1}$，固化历史。 |
| 发散回滚 | **Rollback** | **`Rbk`** | 迭代失败（需 Cutback），丢弃试探状态，回滚至 $t_n$。 |
| 结束清理 | **Finalize** | **`Fin`** | 释放当前生命周期专属的内存或临时句柄。 |

*组合示例*：增量步收敛固化（Increment Commit） $\to$ **`IncCmt`**。

### 维度 Z：核心动作原语 (Core Action - "What")
定义当前模块在图灵机视角下的数据流向。
| 动作本质 | 全称 (文档注释) | 压缩后缀 (代码实装) | IO 特征 |
| :--- | :--- | :--- | :--- |
| 读 (Read) | **Populate** | **`Pop`** | `Ctx` $\leftarrow$ Global (从全局池捞取组装 `Ctx`) |
| 算 (Compute) | **Evaluate** | **`Evl`** | `Args` $\leftarrow$ `(Desc, State, Ctx)` (纯测算，无副作用) |
| 写 (Write) | **Assemble** | **`Asm`** | Global $\leftarrow$ `Args` (局部矩阵累加回上一级宏观结构) |
| 算+写 (Project)| **Map** | **`Map`** | Node $\leftarrow$ `Pt` (跨空间尺度投影，如外推) |
| 落盘 (I/O) | **Export** | **`Exp`** | Disk $\leftarrow$ `State` (写 ODB 或打印日志) |

---

## 3. 三维空间正交组合矩阵 (The 3D Combination Matrix)

所有的业务流程代码，必须通过挑选上述三轴的**压缩后缀**进行拼装。
**终极子程序签名公式：**
`SUBROUTINE [Prefix]_[Domain]_[Feature]_Proc_[X][Y][Z] (desc, state, algo, ctx, args)`

**核心高频组合矩阵示例（FEM 骨干）：**

| 场景描述 | 空(X) + 时(Y) + 动(Z) | 全称推演 (注释用) | UFC 标准压缩签名 (代码用) |
| :--- | :--- | :--- | :--- |
| **整体刚度阵组装** | `Glb` + `Itr` + `Asm` | Global Iteration Assemble | `..._Proc_GlbItrAsm` |
| **单元积分求值** | `Elm` + `Itr` + `Evl` | Element Iteration Evaluate | `..._Proc_ElmItrEvl` |
| **材料本构应力更新** | `Pt` + `Itr` + `Evl` | Point Iteration Evaluate | `..._Proc_PtItrEvl` |
| **增量步收敛数据固化** | `Glb` + `IncCmt`+ `Evl` | Global Inc Commit Evaluate | `..._Proc_GlbIncCmtEvl` |
| **高斯点外推到节点** | `Elm` + `IncCmt`+ `Map` | Element Inc Commit Map | `..._Proc_ElmIncCmtMap` |
| **发散丢弃当前增量步** | `Glb` + `IncRbk`+ `Evl` | Global Inc Rollback Evaluate| `..._Proc_GlbIncRbkEvl` |

---

## 4. 新旧架构对比：为什么 3D + 压缩后缀 彻底碾压 2D？

### 致命痛点 1：指代不清的维度坍缩
*   ❌ **旧版双轴（2D）**：`PH_Elem_Proc_IterAssemble`
    *   **含糊**：到底是在单元内把积分点拼成 $K_e$？还是把 $K_e$ 拼成全局的 $\hat{K}$？
*   ✅ **新版三轴压缩（3D）**：`PH_Elem_Proc_GlbItrAsm`
    *   **精准且紧凑**：极度明确这是向 **Glb（全局）** 进行装配！

### 致命痛点 2：无法处理“跨尺度”的时空耦合
*   ❌ **旧版双轴（2D）**：`MD_Mat_Proc_Commit`
    *   **含糊**：到底是在 Iter 结束时固化，还是整个 Inc 收敛了才固化？导致塑性算法极易崩溃。
*   ✅ **新版三轴压缩（3D）**：`MD_Mat_Proc_PtIncCmtEvl`
    *   **精准且紧凑**：极其明确指出：是在 **Pt（积分点）** 上，等到整个 **Inc（增量步）** 收敛（**Cmt**）时，执行固化操作（**Evl**）！

### 终极结论
以此“三维正交架构 + 3-LAR命名压缩”为主轴，旧的“双轴设计”已彻底被格式化。所有的代码签入、模板生成、系统工程字典，全部无条件切换至本三维坐标系及其对应的标准缩写体系。