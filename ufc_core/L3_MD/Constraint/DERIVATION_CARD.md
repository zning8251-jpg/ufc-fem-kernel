# Constraint 域推演卡

> 层级: L3_MD / Constraint
> 日期: 2026-04-26
> 版本: v2.0

---

## A. 初始状态（8 文件）

| # | 文件 | `MODULE` | 行数 | 轨道 | 问题 |
|---|------|----------|------|------|------|
| 1 | `MD_Constr_Def.f90` | `MD_Constr_Def` | 67→**~350** | **已重建** | 从 9 个消费者逆向推导，恢复 4 富类型 + `MD_ConstraintUnion` + 16 常量 + 12 过程 |
| 2 | `MD_Const_Mgr.f90` | `MD_Const_Mgr` | 696 | 生产 | 域容器 `MD_Constraint_Domain` + TBP；命名用 `Const` 而非 `Constr`（域内唯一异类）；Header 写 `MD_Const`；重复 Status 头块 |
| 3 | `MD_Constr_Core.f90` | `MD_Constr_Core` | 197 | **死代码** | 7 过程操作扁平类型；**0 外部 USE**；Header 写 `MD_Constraint_Core` |
| 4 | `MD_Constr_Brg.f90` | `MD_Constr_Brg` | 23 | **空骨架** | **0 过程、0 消费者**；Header 写 `MD_Constraint_Brg` |
| 5 | `MD_Constr_PairDef.f90` | `MD_Constr_PairDef` | ~590 | 生产 | 重复 QUENCH 标签；编码腐蚀（数学符号）；Header 写 `MD_ConstraintPairDef` |
| 6 | `MD_Constr_PropDB.f90` | `MD_Constr_PropDB` | 184 | 生产 | 重复 QUENCH 标签；编码腐蚀（希腊字母）；Header 写 `MD_ConstraintPropDB` |
| 7 | `MD_Constr_SurfBridge.f90` | `MD_Constr_SurfBridge` | 433 | 生产 | Header 写 `MD_ConstraintSurfBridge`（已匹配 MODULE 声明）|
| 8 | `MD_Constr_Sync.f90` | `MD_Constr_Sync` | 66 | 生产 | 重复 QUENCH 标签；编码腐蚀（→ 符号）；Header 写 `MD_ConstraintSync` |
| — | `MD_Constr_Test.f90` (tests/) | `MD_Constr_Test` | 63 | 测试 | USE 死代码 `MD_Constr_Core` |

### 双类型系统冲突（RESOLVED）

`MD_Constr_Def.f90` 曾仅含扁平原型类型（`MD_Constraint_Desc`/`MD_ConstraintEntry`），
而生产代码从此模块导入富类型（`TieConstraintDef` 等）。

**已解决**：从 9 个消费者文件逆向推导字段结构，完整重建了 `MD_Constr_Def.f90`：
- 4 富类型 TYPE：`TieConstraintDef`, `MPCConstraintDef`, `CplConstraintDef`, `RigidBodyDef`
- 1 容器 TYPE：`MD_ConstraintUnion`（tie/mpc/cpl/rigid 动态数组 + 计数 + validated）
- 1 监控 TYPE：`MD_Constraint_State`（占位保留）
- 16 常量：`CONSTRAINT_*`, `MPC_TYPE_*`, `COUPLING_TYPE_*`, `RBE_TYPE_*`, `DOF_*`
- 12 过程：Init/Valid/Cleanup（4 类型 × 3）+ `MPCConstraintDef_AddTerm` + `CplConstraintDef_SetDOFs`
- 扁平类型（`MD_Constraint_Desc`/`MD_ConstraintEntry`）已移除（唯一消费者 `MD_Constr_Core.f90` 已删除）

---

## B. 命名评估

### 域缩写一致性

| 前缀 | 文件数 | 示例 |
|-------|--------|------|
| `Constr` | 7 | `MD_Constr_Def`, `MD_Constr_Core`, `MD_Constr_Sync` … |
| `Const` | 1 | `MD_Const_Mgr` |

**决定**：`Const` 为异类，且易与 "常量" 混淆。统一为 `Constr`：`MD_Const_Mgr` → `MD_Constr_Mgr`。

### Header 模块名 vs MODULE 声明

所有文件 Header 使用旧长形式名（`MD_Constraint_*` / `MD_ConstraintSurfBridge` 等），与实际 MODULE 声明（`MD_Constr_*`）不一致。须逐一修正。

### 三段式命名闭合

| 文件 | 三段式 | 功能后缀 |
|------|--------|----------|
| `MD_Constr_Def.f90` | `MD_Constr_Def` | `_Def` (定义) |
| `MD_Constr_Mgr.f90` | `MD_Constr_Mgr` | `_Mgr` (容器管理) |
| `MD_Constr_PairDef.f90` | `MD_Constr_PairDef` | `_PairDef` (Contact Pair 定义) |
| `MD_Constr_PropDB.f90` | `MD_Constr_PropDB` | `_PropDB` (属性数据库) |
| `MD_Constr_SurfBridge.f90` | `MD_Constr_SurfBridge` | `_SurfBridge` (表面桥接) |
| `MD_Constr_Sync.f90` | `MD_Constr_Sync` | `_Sync` (遗留同步) |

---

## C. 死代码诊断

### C1. `MD_Constr_Core.f90` — 死代码

- **模块**：`MD_Constr_Core` (197 行)
- **外部 USE**：0（`grep -r "USE MD_Constr_Core"` 仅匹配测试骨架）
- **内部过程**：7 — 全部操作扁平类型 `MD_Constraint_Desc`
- **结论**：**删除**。蓝图归档见 §F。

### C2. `MD_Constr_Brg.f90` — 空骨架

- **模块**：`MD_Constr_Brg` (23 行)
- **外部 USE**：0
- **过程数**：0（仅 TODO 注释）
- **L3→L4 桥接**：已由 `Bridge/Bridge_L4/MD_ConstraintPH_Brg.f90` 承担
- **结论**：**删除**。薄封装/门面规则。

---

## D. CONTRACT 偏差

| # | CONTRACT 引用 | 实际 | 偏差类型 |
|---|---------------|------|----------|
| D1 | `MD_Constraint_Def.f90` / `MD_Constraint_Def` | `MD_Constr_Def.f90` / `MD_Constr_Def` | 文件名+MODULE 名 |
| D2 | `MD_Const.f90` / `MD_Const` | `MD_Const_Mgr.f90` / `MD_Const_Mgr` → `MD_Constr_Mgr.f90` / `MD_Constr_Mgr` | 文件名+MODULE 名 |
| D3 | `MD_ConstraintSurfBridge.f90` / `MD_ConstraintSurfBridge` | `MD_Constr_SurfBridge.f90` / `MD_Constr_SurfBridge` | 文件名+MODULE 名 |
| D4 | `MD_ConstraintPairDef.f90` / `MD_ConstraintPairDef` | `MD_Constr_PairDef.f90` / `MD_Constr_PairDef` | 文件名+MODULE 名 |
| D5 | `MD_ConstraintPropDB.f90` / `MD_ConstraintPropDB` | `MD_Constr_PropDB.f90` / `MD_Constr_PropDB` | 文件名+MODULE 名 |
| D6 | `MD_ConstraintSync.f90` / `MD_ConstraintSync` | `MD_Constr_Sync.f90` / `MD_Constr_Sync` | 文件名+MODULE 名 |
| D7 | 十件套 `ConstraintAlgo`, `ConstraintCtx` | 实际缺少 `MD_Constr_` 前缀 | 类型名前缀 |

---

## E. 最终状态（5 文件）

| # | 文件 | `MODULE` | 功能后缀 | 说明 |
|---|------|----------|----------|------|
| 1 | `MD_Constr_Def.f90` | `MD_Constr_Def` | `_Def` | **AUTHORITY** — 4 富类型 + Union + State + 16 常量 + 12 过程 |
| 2 | `MD_Constr_Mgr.f90` | `MD_Constr_Mgr` | `_Mgr` | 域容器 + Algo/Ctx + CRUD + Validate |
| 3 | `MD_Constr_Brg.f90` | `MD_Constr_Brg` | `_Brg` | 表面/elset 名 → 节点列表 (从 `_SurfBridge` 重命名) |
| 4 | `MD_Constr_Prop.f90` | `MD_Constr_Prop` | `_Prop` | 接触属性数据库 (从 `_PropDB` 重命名) |
| 5 | `MD_Constr_Sync.f90` | `MD_Constr_Sync` | `_Sync` | Legacy / UF_* → MD_ConstraintUnion 同步 |
| — | `MD_Constr_Test.f90` (tests/) | `MD_Constr_Test` | — | 测试 → USE `MD_Constr_Mgr` |

### 已删除文件

| 文件 | 原 MODULE | 原因 |
|------|-----------|------|
| ~~`MD_Constr_Core.f90`~~ | `MD_Constr_Core` | 死代码（蓝图归档 §F） |
| ~~`MD_Constr_Brg.f90`~~ (旧) | `MD_Constr_Brg` | 空骨架（0 过程、0 消费者） |
| ~~`MD_Constr_PairDef.f90`~~ | `MD_Constr_PairDef` | 死代码（0 直接 USE 消费者；类型由 `MD_Int_API.f90` 独立定义） |

---

## F. Core 蓝图闭合校验

`MD_Constr_Core.f90`（197 行，MODULE `MD_Constr_Core`）定义 7 个过程，操作扁平类型 `MD_Constraint_Desc`/`MD_ConstraintEntry`。虽然生产不使用这些扁平过程，但它们定义了域应具备的算法蓝图：

| # | 蓝图过程 | 签名 | 生产对应 | 状态 |
|---|----------|------|----------|------|
| 1 | `MD_Constraint_Core_Init` | `(desc, state, status)` | `MD_Constraint_Domain%Init(status)` in `MD_Constr_Mgr` | COVERED |
| 2 | `MD_Constraint_Core_Finalize` | `(desc, state, status)` | `MD_Constraint_Domain%Finalize()` in `MD_Constr_Mgr` | COVERED |
| 3 | `MD_Constraint_Add_MPC` | `(desc, n_terms, dof_ids, coeffs, rhs, status)` | `MD_Constraint_Domain%AddMPC(mpc_def, status)` in `MD_Constr_Mgr` | COVERED（使用富类型 `MPCConstraintDef` 而非扁平 dof/coeff 参数） |
| 4 | `MD_Constraint_Add_Tie` | `(desc, slave_dof, master_dof, status)` | `MD_Constraint_Domain%AddTie(tie_def, status)` in `MD_Constr_Mgr` | COVERED（使用富类型 `TieConstraintDef`） |
| 5 | `MD_Constraint_Add_Equation` | `(desc, n_terms, dof_ids, coeffs, rhs, status)` | 通过 `AddMPC` 覆盖（`cons_type=3` 等效于 `CONSTRAINT_MPC`） | COVERED（合并入 MPC 路径） |
| 6 | `MD_Constraint_Get_By_Index` | `(desc, idx, cons, status)` | `MD_Constraint_Domain%GetTie/MPC/Coupling/RigidConstraint(idx, def, status)` | COVERED（按类型分化为 4 个 Get 过程） |
| 7 | `MD_Constraint_Validate` | `(desc, status)` | `MD_Constraint_Domain%ValidateAll(valid, status)` | COVERED |

**闭合评定**：7/7 全部覆盖。生产 `MD_Constr_Mgr` 以富类型（`TieConstraintDef` / `MPCConstraintDef` / `CplConstraintDef` / `RigidBodyDef`）替代扁平的 `MD_ConstraintEntry`，并将 `Get_By_Index` 分化为按约束类型的 4 个独立查询。蓝图中的 `Add_Equation` 已合并入 MPC 路径（ABAQUS `*EQUATION` 本质是 MPC 的一种形式）。

---

## G. 影响矩阵

| 变更 | 影响文件 |
|------|----------|
| 删除 `MD_Constr_Core.f90` | `MD_Constr_Test.f90`（重写） |
| 删除 `MD_Constr_Brg.f90` (旧) | 无（0 消费者） |
| 删除 `MD_Constr_PairDef.f90` | 无（0 直接 USE 消费者） |
| `MD_Const_Mgr` → `MD_Constr_Mgr` | `MD_L3_Layer.f90`, `PH_L4_Populate.f90`, `MD_Constr_Sync.f90` |
| `MD_Constr_SurfBridge` → `MD_Constr_Brg` | `RT_Asm_Solv.f90` |
| `MD_Constr_PropDB` → `MD_Constr_Prop` | `MD_Model_Brg.f90`, `MD_Model_Lib.f90`, `MD_KW_Mapper.f90`, `MD_Int_Sync.f90` |
| `MD_Constr_Def.f90` 字段补充 | `CplConstraintDef`: +`n_coupled`/`coupled_nodes`；`RigidBodyDef`: `elem_set`→`element_set`, +`n_tied`/`tied_nodes`/`tie_nset` |
| Header 修正 | 域内 6 文件 |
| 去重 QUENCH | `MD_Constr_Sync.f90`, `MD_Constr_PropDB.f90`, `MD_Constr_PairDef.f90` |
| 编码修复 | `MD_Constr_Sync.f90`, `MD_Constr_PropDB.f90`, `MD_Constr_PairDef.f90` |

---

## H. 实施计划

| Step | 任务 | 状态 |
|------|------|------|
| H1 | 删除 `MD_Constr_Core.f90`（蓝图已归档 §F） | DONE |
| H2 | 删除 `MD_Constr_Brg.f90`（旧空骨架） | DONE |
| H3 | 重命名 `MD_Const_Mgr` → `MD_Constr_Mgr`（文件+MODULE+3 消费者） | DONE |
| H4 | 修复 Header（Module 名对齐 MODULE 声明）— 6 文件 | DONE |
| H5 | 修复 `MD_Constr_Mgr.f90` 重复 Status 头块 | DONE |
| H6 | 去重 QUENCH 标签（Sync, PropDB, PairDef） | DONE |
| H7 | 修复编码腐蚀（Sync, PropDB, PairDef） | DONE |
| H8 | 重写 `MD_Constr_Test.f90` → USE `MD_Constr_Mgr` | DONE |
| H9 | 更新 CONTRACT.md（对齐实际文件名/MODULE 名, v2.1） | DONE |
| H10 | 统一四型名：`ConstraintAlgo`→`MD_Constr_Algo`, `ConstraintCtx`→`MD_Constr_Ctx` | DONE |
| H11 | 删除死代码 `MD_Constr_PairDef.f90`（0 USE 消费者） | DONE |
| H12 | 补充 `MD_Constr_Def.f90` 缺失字段：`CplConstraintDef`+`n_coupled`/`coupled_nodes`；`RigidBodyDef`+`n_tied`/`tied_nodes`/`tie_nset`+`elem_set`→`element_set` | DONE |
| H13 | 重命名 `MD_Constr_SurfBridge` → `MD_Constr_Brg`（文件+MODULE+1 消费者 `RT_Asm_Solv.f90`） | DONE |
| H14 | 重命名 `MD_Constr_PropDB` → `MD_Constr_Prop`（文件+MODULE+4 消费者） | DONE |
| H15 | 更新 CONTRACT.md v2.3 + DERIVATION_CARD v2.0 | DONE |
