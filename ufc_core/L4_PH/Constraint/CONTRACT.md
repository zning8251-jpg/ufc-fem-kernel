# Constraint 域级合同卡 (L4_PH)

**Layer**: L4_PH (物理计算层)  
**Domain**: Constraint (多点约束与运动学耦合)  
**Prefix**: `PH_Constr_*`, `PH_Constraint_*`  
**Version**: v4.2  
**Created**: 2026-04-27  
**Updated**: 2026-05-05  
**Status**: ACTIVE

---

## 1. 域职责定义

### 核心职责
- **定位**: L4_PH 层 Constraint 域，各类约束的局部数值形式实现
- **职责**:
  - MPC 多点约束：线性约束方程 C u = g，罚函数/拉格朗日/消元施加
  - Tie 约束：表面绑定约束，主从节点配对、权重计算、违反检测
  - 周期性约束 (Periodic)：周期边界节点配对、宏观应变/应力计算
  - 约束局部贡献：局部约束矩阵 Kc、残差 r、等效节点力
  - 约束违反检测与一致性校验

### 非职责
- 不做全局 CSR 组装（L5 `RT_Asm_*` 处理）
- 不持有 L3 模型树（约束 Desc 在 L3 `MD_Constraint_*`）
- 不持久化约束 Desc
- 拉格朗日主从消元由 L5 侧与 DOF 映射结合

---

## 2. 四类 TYPE 清单

### 2.1 Desc

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `PH_Constraint_Desc` | `PH_Constr_Def` | n_terms, dep_idx, rhs, dof_ids(64), coeffs(64) | 约束参数描述（Populate 后只读） |
| `MPC_Constraint` | `PH_ConstrMPC_Def` | ... | MPC 约束实体 |
| `MPC_Params` | `PH_ConstrMPC_Def` | ... | MPC 参数 |
| `Tie_Constraint_Params` | `PH_ConstrTie_Def` | ... | Tie 约束参数 |
| `Period_BC_Params` | `PH_ConstrPeriod_Def` | ... | 周期 BC 参数 |

### 2.2 State

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `PH_Constraint_State` | `PH_Constr_Domain` (re-export via `PH_Constr_Def`) | assembled, n_active, n_suppressed, current_step | 跨步持久约束状态 |
| `MPC_State` | `PH_ConstrMPC_Def` | ... | MPC 状态 |
| `Tie_Constraint_State` | `PH_ConstrTie_Def` | ... | Tie 状态 |
| `Period_BC_State` | `PH_ConstrPeriod_Def` | ... | 周期 BC 状态 |

### 2.3 Algo

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `PH_Constraint_Algo` | `PH_Constr_Def` | method (penalty/Lagrange/direct), alpha (罚参数) | 步级约束施加配置 |

### 2.4 Ctx

| TYPE 名称 | 模块 | 核心字段 | 说明 |
|-----------|------|----------|------|
| `PH_Constraint_Ctx` | `PH_Constr_Domain` (re-export via `PH_Constr_Def`) | T_row, rhs_contrib, K_aug_row, violation, is_violated | 热路径临时工作区 |
| `PH_Constr_MPC_Apply_Ctx` | `PH_ConstrMPC_Brg` | ... | MPC 施加上下文 |
| `PH_Constr_Tie_Apply_Ctx` | `PH_ConstrTie_Brg` | ... | Tie 施加上下文 |
| `PH_Constr_Period_Apply_Ctx` | `PH_ConstrPeriod_Brg` | ... | 周期施加上下文 |

---

## 3. 功能模块清单

| 文件 | MODULE | 后缀角色 | 核心子程序 | 状态 |
|------|--------|----------|-----------|------|
| `PH_Constr_Def.f90` | `PH_Constr_Def` | `_Def` | 约束基础 TYPE | **ACTIVE** |
| `PH_Constr_Domain.f90` | `PH_ConstraintDomain` | Domain 容器 | Init/Finalize/Register/AddMPC/Assemble_KauxFaux/Apply_Transformation/BuildDofMask/ExtendCSR/Apply_Elimination/Update_Lambda | **ACTIVE** (金线) |
| `PH_Constr_Ctx.f90` | `PH_Constr_Ctx` | `_Ctx` | Ctx Init/Clear/Copy/Valid (含 SIO Structured 版本) | **ACTIVE** |
| `PH_Constr_Core.f90` | `PH_Constr_Core` | `_Core` | 约束核心逻辑；**含** `PH_Constr_IntCodeToStatus`（Tie/MPC Brg 共用 core 整数返回码映射） | **ACTIVE** |
| `PH_ConstrMPC_Def.f90` | `PH_ConstrMPC_Def` | `_Def` | MPC_Term, MPC_Constraint, MPC_Params, MPC_State | **ACTIVE** |
| `PH_Constr_MPC.f90` | `PH_Constr_MPC` | 特化(Compute) | MPCCore_AssembleMatrix/Penalty/Lagrange/CheckConsistency/ComputeViolation | **ACTIVE** |
| `PH_ConstrMPC_Brg.f90` | `PH_ConstrMPC_Brg` | `_Brg` | MPC_Apply/Init/AddTerm/AssembleMatrix/ApplyConstraint/CheckViolation/Finalize | **ACTIVE** |
| `PH_ConstrTie_Def.f90` | `PH_ConstrTie_Def` | `_Def` | Tie_Constraint_Params/State, Tie_Node_Pair, Tie_Surface_Pair | **ACTIVE** |
| `PH_Constr_Tie.f90` | `PH_Constr_Tie` | 特化(Compute) | TieCore_BuildNodePair/CalcWeights/ComputeViolation/FindNearestMasterElem/UpdateWeights | **ACTIVE** |
| `PH_ConstrTie_Brg.f90` | `PH_ConstrTie_Brg` | `_Brg` | Tie_Apply/Init/BuildNodePairs/CalcWeights/ApplyConstraint/CheckViolation | **ACTIVE** |
|| `PH_Constr_Period.f90` | `PH_Constr_Period` | 特化(Compute) | PeriodCore_ComputeMacroStrain/Stress/IdentifyBoundaryNodes | **ACTIVE** |
| `PH_ConstrPeriod_Brg.f90` | `PH_ConstrPeriod_Brg` | `_Brg` | Period_Apply/Init/BuildNodePairs/ApplyDisplacement/ComputeMacro | **ACTIVE** |
| **`PH_ConstrEmbedded_Def.f90`** | **`PH_ConstrEmbedded_Def`** | **`_Def`** | **EmbeddedRegion_Params/State/Brg_Ctx** | **P0 2026-05-05** |
| **`PH_Constr_Embedded.f90`** | **`PH_Constr_Embedded`** | **Compute** | **SearchHostElem/ComputeWeights/AssemblePenalty/CheckViolation** | **P0 2026-05-05** |
| **`PH_ConstrEmbedded_Brg.f90`** | **`PH_ConstrEmbedded_Brg`** | **`_Brg`** | **Embedded_Apply/Init/BuildNodePairs/ApplyConstraint** | **P0 2026-05-05** |

---

## 4. 对外接口（公开 API）

### PH_Constraint_Domain TBP (金线)

| TBP | 说明 |
|-----|------|
| `%Init` / `%Finalize` | Step 级生命周期 |
| `%Register` | 约束注册 |
| `%AddMPCEquation` | 添加 MPC 方程 |
| `%GetSummary` | 摘要/诊断 |
| `%Assemble_KauxFaux` | 约束贡献组装 |
| `%Apply_Transformation` | 约束变换施加 |
| `%BuildDofMaskFromMPC` | DOF 掩码构建 |
| `%ExtendCSRForMPC` | CSR 扩展 |
| `%Apply_Elimination_CSR` | 消元法 CSR 施加 |
| `%Update_Lambda` | 拉格朗日乘子更新 |

### 约束子类型 Compute 接口

| 子程序 | 模块 | 说明 |
|--------|------|------|
| `PH_Constr_MPC_Apply` | `PH_ConstrMPC_Brg` | MPC 统一施加入口 |
| `PH_Constr_Tie_Apply` | `PH_ConstrTie_Brg` | Tie 统一施加入口 |
| `PH_Constr_Period_Apply` | `PH_ConstrPeriod_Brg` | 周期约束统一施加入口 |

---

## 5. 跨层数据流

### Populate 数据流（冷路径）
```
L3_MD/Constraint (MD_Const_*, MD_Constraint_*)
  → PH_L4_Populate_Constraint()  ← 只读 API 写入 L4 slot
    → PH_Constraint_Desc / State / Algo / Ctx
```

### 约束计算流（热路径，NR 迭代内）
```
PH_Constraint_Domain
  → PH_Constr_MPC_Compute()   ← 局部 r, Kc
  → PH_Constr_Tie_Compute()   ← 局部约束力
  → PH_Constr_Period_Compute() ← 周期约束贡献
    → 局部贡献 → L5 RT_Asm_ApplyConstraints  ← 全局组装
```

### 理论基础
- 线性约束: C u = g
- 罚函数法: ΔK ∝ α C^T C, ΔF ∝ α C^T g
- 拉格朗日乘子: 扩充系统 [K C^T; C 0]
- 消元法: 在 L5 侧与 DOF 映射结合

---

## 6. 域间契约

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L3_MD/Constraint | S (消费) | Desc 经 Populate 只读获取 |
| R2 | L4_PH/Element | T (合同) | 约束与单元共享节点 |
| R3 | L5_RT/Assembly | B (桥接) | RT_Asm_ApplyConstraints 消费局部贡献 |
| R4 | L1_IF/Error | U (USE) | 错误码定义 |

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 禁止在约束热路径直读 L3 | **硬** | Harness | H-HOT-01 |
| 不做全局 CSR 组装 (由 L5) | **硬** | Code Review | — |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | **硬** | Harness | H-ERR-01 |
| 不使用 STOP | **硬** | grep 扫描 | CI |
| 约束施加方法须在枚举中声明 | **软** | Code Review | — |

### 错误处理

| 错误码范围 | 错误场景 | 严重级 | 恢复策略 |
|------------|----------|--------|----------|
| ERR_L4_CONSTRAINT_40200 | 约束残差大于容差 | WARNING | 日志 + 继续迭代 |
| ERR_L4_CONSTRAINT_40201 | 约束方程奇异 | ERROR | 上报 L5 决定截断 |
| ERR_L4_CONSTRAINT_402xx | 其它 | — | 经 ErrorStatusType 返回 |

---

## 7. 验收标准

| 编号 | 验收项 | 标准 | 状态 |
|------|--------|------|------|
| A1 | 四型定义完整 | Desc/State/Algo/Ctx 各有定义 | ✅ 已实现 |
| A2 | Domain 容器完整 | PH_Constraint_Domain TBP 完整 | ✅ 已实现 |
| A3 | MPC 约束可用 | MPC 方程添加/组装/施加/违反检测 | ✅ 已实现 |
| A4 | Tie 约束可用 | 节点配对/权重/施加/违反检测 | ✅ 已实现 |
| A5 | 周期约束可用 | 节点配对/位移施加/宏观应变应力 | ✅ 已实现 |
| A6 | 三种施加方法 | Penalty/Lagrange/Elimination | ✅ 已实现 |
| A7 | Ctx SIO 完整 | Init/Clear/Copy/Valid 含 Structured 版 | ✅ 已实现 |
| A8 | Populate 入口 | PH_L4_Populate_Constraint 可从 L3 填充 | ✅ 已实现 |
| A9 | 错误传播 | ErrorStatusType，不使用 STOP | ✅ 已实现 |
| A10 | 热路径零 L3 | 步内 Compute 不直读 L3 | ✅ 已实现 |
| **A11** | **Embedded Def 四型** | **EmbeddedRegion_Params/State/Brg_Ctx** | **P0 2026-05-05** |
| **A12** | **Embedded Core 算法** | **SearchHostElem/ComputeWeights/AssemblePenalty** | **P0 2026-05-05** |
| **A13** | **Embedded Bridge** | **L3→L4 Populate Init/BuildNodePairs/Apply** | **P0 2026-05-05** |

### 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| v4.0 | 2026-04-27 | 初版 v4 结构 |
|| v4.1 | 2026-04-30 | Pilot：Tie_Brg/MPC_Brg 共用 IntCodeToStatus |
|| v4.2 | 2026-05-05 | P0 fill: Embedded 三模块 + Def/State/Brg_Ctx |
