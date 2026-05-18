# Contracts 域级合同卡 (L3_MD)

**Layer**: L3_MD (模型数据层)  
**Domain**: Contracts (跨域契约与灵敏度/优化规格)  
**Version**: v1.0  
**Updated**: 2026-05-04  
**Status**: ✅ ACTIVE (跨域契约宿主)

---

## 1. 域职责定义

### 核心职责

L3_MD 层跨域契约与灵敏度/优化规格的唯一宿主，定义 **全局残差 R**、**设计变量 θ** 在四型（Desc/State/Algo/Ctx）中的落位原则，以及灵敏度分析场景下各域间的契约边界。

### 职责边界

| 做什么 | 不做什么 |
|--------|----------|
| 跨域契约文档管理（R-Theta 四型落位原则） | 持有运行时数据或 TYPE 定义 |
| 灵敏度/优化场景下 R/θ 的权威约定 | 物理计算（L4_PH 职责） |
| 与 Assembly/Solver/Interaction 合同卡衔接 | 求解流程编排（L5_RT 职责） |
| 约定 L3 不重复承载的字段 | 全局矩阵/残差装配（L5/L2 职责） |
| 四型裁剪原则文档化 | 关键字解析或模型构建 |

### 设计意图

本域为**纯文档域**（无 `.f90` 源码），作为跨域契约的单一入口（SSOT for cross-domain contracts）。消费者通过引用本域下的契约文档，确保灵敏度/优化场景下各域四型裁剪的一致性。

### 依赖关系

- **契约引用域**: Assembly、Analysis/Solver、Interaction、Material、Section
- **下游消费**: L4_PH 灵敏度 Populate、L5_RT 灵敏度求解器

---

## 2. 四类 TYPE 清单

> **注**: 本域为**纯文档域**，**不定义 Fortran TYPE**。契约内容以 Markdown 文档形式存在，供其他域合同卡引用。

### 四型裁剪决策

| 四型 | 本域持有 | 说明 |
|------|----------|------|
| **Desc** | N | 无运行时 Desc；契约文档声明各域 Desc 落位原则 |
| **State** | N | 无运行时 State；R 权威载体在 L5 组装/L2 求解工作区 |
| **Algo** | N | 无算法实现；仅约定灵敏度分析的流程边界 |
| **Ctx** | N | 无运行时 Ctx；θ 注入方式由下游域合同卡定义 |

---

## 3. 核心契约文档

| 文档 | 说明 | 关联合同卡 |
|------|------|-----------|
| [`CONTRACT_R_Theta_FourKind.md`](./CONTRACT_R_Theta_FourKind.md) | R-Theta 四型落位原则（灵敏度/优化场景） | Assembly/Solver/Interaction/Material |

### 3.1 R-Theta 四型落位原则（摘要）

- **θ（设计变量）**：优先经 **Desc**（设计参数、材料参数句柄）或合同化的 **Ctx** 注入 PH/L5；避免隐式全局可变。
- **R（全局残差）**：权威载体在 **L5 组装 / L2 求解工作区**；L3 合同卡仅声明 **不** 重复承载的字段，与 Populate 只读填充边界一致。

---

## 4. 跨域关系

### 上游依赖

- **L2_NM/Solver**: 求解器域与 R 的边界约定
- **L3_MD/Assembly**: 装配域不做 L5 CSR 组装；Populate 消费 Desc
- **L3_MD/Analysis/Step**: 步输入 Desc；不承载运行时全局 R 向量
- **L3_MD/Analysis/Solver**: 求解器域与 R 的边界
- **L3_MD/Interaction**: θ 经 Desc/Ctx 注入等说明

### 下游消费

- **L4_PH**: 灵敏度 Populate 消费 R-Theta 契约
- **L5_RT**: 灵敏度求解器遵循 R 载体约定

### 域际关系图

```
L2_NM/Solver ──(R载体约定)──> Contracts/R-Theta
L3_MD/Assembly ──(Desc消费)──> Contracts/R-Theta
L3_MD/Solver ──(R边界)──────> Contracts/R-Theta
L3_MD/Interaction ─(θ注入)──> Contracts/R-Theta
                              ↓
                    L4_PH/L5_RT 灵敏度求解
```

---

## 5. 金线调用序

本域无运行时调用序（纯文档域）。

---

## 6. 错误处理

本域不定义错误处理逻辑。消费者引用本域契约时，应遵循各自域合同卡的错误处理约定。

---

## 7. 与跨层灵敏度契约的衔接

- **总纲**: [`UFC/docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md`](../../../docs/05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md)（§11.4.1 等）
- **集成规范**: [`UFC/docs/05_Project_Planning/PPLAN/05_实施指南/UFC_AI_Ready_架构集成规范.md`](../../../docs/05_Project_Planning/PPLAN/05_实施指南/UFC_AI_Ready_架构集成规范.md)（§3.2）
- **L2 数值求解**: [`../../L2_NM/Solver/CONTRACT.md`](../../L2_NM/Solver/CONTRACT.md)

---

## 8. 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0 | 2026-05-04 | 初始创建，修复 CI 合同卡覆盖率阻断 |
