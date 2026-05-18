# 推演卡：L4_PH / Constraint

> 推演引擎 v1.0 | 2026-04-26 | 域类型：计算域（约束方程推演）

---

## [A] 意图推断

**域**：L4_PH / Constraint

**CONTRACT 摘要**：多点约束与运动学耦合核——MPC、Tie、Periodic、RBE 等的局部数值形式。包括约束方程、拉格朗日乘子/罚函数贡献、局部切线刚度。

**核心意图**：
- 域级初始化/终结化
- MPC 变换矩阵构造
- 罚函数施加
- 拉格朗日乘子构造
- 约束反力计算
- 约束违规检查

**Verb 族分布**：Init, Compute, Assemble(Apply), Control(Check)

**Phase 分布**：Config, Populate, Iteration

---

## [B] 四型裁剪

| 四型 | 保留？ | 字段 | 理由 |
|------|-------|------|------|
| **Desc** | Y | MPC 类型、Tie 容差、Periodic 向量 (Populate slot) | 约束参数视图 |
| **State** | Y | 拉格朗日乘子、罚因子、激活状态 | 跨增量演化态 |
| **Algo** | Y | enforcement_method(Elimination/Penalty/Lagrange)、增广策略 | 方法选择 |
| **Ctx** | Y | 从/主节点 ID、约束方程系数、步/增量索引 | 增量级临时工作区 |

**签名模式**：`(desc, state, algo, ctx, status)` — 全四型

---

## [C] 算法锚定

**推演策略**：计算域 → 约束方程数值形式

**理论基础**：

```
线性约束：C * u = g

罚法贡献：  deltaK = alpha * C^T * C,  deltaF = alpha * C^T * g
拉格朗日：  扩充系统 [K C^T; C 0] [u; lambda]^T = [F; g]
消元法：    在 L5 侧与 DOF 映射结合
```

**算法步骤分解**：

| 步骤 | 名称 | Phase | Verb | 复杂度 | 说明 |
|------|------|-------|------|--------|------|
| S1 | Core_Init | Config | Init | O(1) | 域级初始化 |
| S2 | Core_Finalize | Config | Init(Fin) | O(1) | 域级清理 |
| S3 | Build_MPC_Transform | Iteration | Compute(Build) | O(n_mpc*n_dof) | MPC 变换矩阵 T |
| S4 | Apply_Penalty | Iteration | Assemble(Apply) | O(n_constr) | 罚函数：K += alpha*C^T*C |
| S5 | Build_Lagrange | Iteration | Compute(Build) | O(n_constr) | 拉格朗日：构造扩充方程 |
| S6 | Compute_Reaction | Iteration | Compute | O(n_constr) | 约束反力 |
| S7 | Check_Violation | Iteration | Control(Check) | O(n_constr) | 约束违规检查 |

---

## [D] 过程绑定

| 过程名 | Phase | Verb | 参数签名 | 热/冷 | 归属文件 |
|--------|-------|------|---------|-------|---------|
| `PH_Constraint_Core_Init` | Config | Init | (..., status) | COLD | PH_Constraint_Core.f90 |
| `PH_Constraint_Core_Finalize` | Config | Init(Fin) | (..., status) | COLD | PH_Constraint_Core.f90 |
| `PH_Constraint_Build_MPC_Transform` | Iteration | Compute(Build) | (..., T_mpc, status) | HOT | PH_Constraint_Core.f90 |
| `PH_Constraint_Apply_Penalty` | Iteration | Assemble(Apply) | (..., K, F, status) | HOT | PH_Constraint_Core.f90 |
| `PH_Constraint_Build_Lagrange` | Iteration | Compute(Build) | (..., K_aug, F_aug, status) | HOT | PH_Constraint_Core.f90 |
| `PH_Constraint_Compute_Reaction` | Iteration | Compute | (..., reaction, status) | HOT | PH_Constraint_Core.f90 |
| `PH_Constraint_Check_Violation` | Iteration | Control(Check) | (..., max_viol, status) | HOT | PH_Constraint_Core.f90 |

---

## [E] 血肉清单

### 已有骨架

| 文件 | 行数 | 包含过程 |
|------|------|---------|
| PH_Constraint_Core.f90 | ~200 | 7 个过程（全部已实现） |
| PH_Constraint_Def.f90 | — | TYPE 定义 |
| PH_Constr_Ctx.f90 | — | 上下文 TYPE |
| PH_ConstrTie*.f90 | 3 文件 | Tie 约束 |
| PH_ConstrMPC*.f90 | 3 文件 | MPC 约束 |
| PH_ConstrPeriod*.f90 | 3 文件 | 周期边界 |
| 14 个文件 | — | 域完整实现 |

### 待补全

| 缺失过程 | Phase x Verb | 优先级 | 说明 |
|---------|-------------|--------|------|
| Phase 注释标注 | — | P1 | 现有 7 个过程缺少标准 Phase 注释 |

### 评估结论

**PH_Constraint 域核心过程已完整（7 个）。** 覆盖 MPC 变换、罚函数、拉格朗日三种约束施加方式。待补全 Phase 注释标注。
