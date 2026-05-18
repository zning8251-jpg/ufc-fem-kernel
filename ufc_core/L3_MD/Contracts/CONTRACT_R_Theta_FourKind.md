# CONTRACT_R_Theta_FourKind（L3_MD 跨域缩略）

**目的**：约定灵敏度 / 优化场景下 **全局平衡残差 R**、设计变量 **θ** 在四型（Desc / State / Algo / Ctx）中的**落位原则**，避免把 **R** 误写入仅含标量统计的 Solver State 或过窄的瞬态 Ctx。

**本文件为缩略锚点**；展开论述与图以仓库下列文档为准：

- **总纲**：[`UFC/docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md`](../../../docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md)（§11.4.1 等）
- **集成规范**：[`UFC/docs/05_Project_Planning/PPLAN/05_实施指南/UFC_AI_Ready_架构集成规范.md`](../../../docs/05_Project_Planning/PPLAN/05_实施指南/UFC_AI_Ready_架构集成规范.md)（§3.2）
- **L2 数值求解**：[`../../L2_NM/Solver/CONTRACT.md`](../../L2_NM/Solver/CONTRACT.md)

**域级合同（与本主题衔接）**：

- [`../Assembly/CONTRACT.md`](../Assembly/CONTRACT.md) — 装配域不做 L5 CSR 组装；Populate 消费 Desc
- [`../Analysis/Step/CONTRACT.md`](../Analysis/Step/CONTRACT.md) — 步输入 Desc；不承载运行时全局 R 向量
- [`../Analysis/Solver/CONTRACT.md`](../Analysis/Solver/CONTRACT.md) — 求解器域与 R 的边界
- [`../Interaction/CONTRACT.md`](../Interaction/CONTRACT.md) — θ 经 Desc/Ctx 注入等说明

**§2 / §5（缩略）**

- **§2**：**θ** 优先经 **Desc**（设计参数、材料参数句柄）或合同化的 **Ctx** 注入 PH/L5；避免隐式全局可变。
- **§5**：**R** 的权威载体在 **L5 组装 / L2 求解工作区**；L3 合同卡仅声明 **不** 重复承载的字段，与 Populate 只读填充边界一致。
