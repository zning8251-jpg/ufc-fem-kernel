# `L3_MD` / `Constraint` 设计意图（域桶）

> **域桶**：`ufc_core/L3_MD/Constraint/`（含子域目录）。  
> **验收向**：本 INTENT + [`CONVENTIONS.md`](../../../CONVENTIONS.md) + 域内 `CONTRACT.md`（若存在）+ `manifest.json` ↔ `align.py`。

## 1. 问题与目标

- **职责**：本目录为 **六层架构** 中 `L3_MD` 之下的一级 **域桶**；子目录为子域，**`manifest.json`** 仍按 **整桶递归** 与 `ufc_core` / `generated/` 对账。
- **过程体命名**：目标 MODULE 与主文件名以 **`_Ops` / `_Brg` / `_Def` / …** 角色后缀为主；遗留 ``*_Algo.f90`` 仅作迁移对象，参见 [CONVENTIONS.md §7](../../../CONVENTIONS.md)。

## 2. PR 边界与物理拆分

- **每波 PR**：单 **域桶**（本目录）或单 **子域子树**（在提交说明与 PPLAN 中点名路径）+ **构建通过**；与算法/物理补全尽量 **拆 PR**。
- **域级物理拆分 / 目录搬迁**：走 **PPLAN / 变更记录**；若与 `_Ops` 收敛交叉，**先冻结目录与 CMake，再改模块名与 `manifest`**（见 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) §1、§9.1）。

## 3. 与 Registry

- **`manifest.json`**：机器可读清单；初稿由本工具 + ``align.py --bootstrap`` 生成，**允许**人工删改与 `module` 例外字段。  
- **工作流**：`domain_procedure_registry_scan.py` → `domain_procedure_registry_align.py`；漂移报告：`REPORTS/DESIGN_GENERATED_DRIFT.md`（`domain_procedure_registry_align.py` 生成）。

## 4. 与现状差距（维护时填写）

| 条目 | `generated/` / 源码现状 | 目标（本 INTENT） | 优先级 |
|------|-------------------------|-------------------|--------|
| （可选） | | | |

## 5. 参考

- 域合同：[`CONTRACT.md`](../../../../../ufc_core/L3_MD/Constraint/CONTRACT.md)
- [`manifest.schema.json`](../../manifest.schema.json)  
- 推断清单（叙述密度参考）：[`UFC_层级域级f90文件推断清单_v2.0.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md)  
- 设计目录说明：[`design/README.md`](../../README.md)  

## 6. L3/L4/L5 域柱同步锚点

**分类**：半柱域（L3 真源 + L4 约束施加 + L5 Assembly 消费点）。

| 层 | 角色 | 目标模块 | 说明 |
|----|------|----------|------|
| L3_MD | Constraint Desc 真源 | `MD_Constr_Def`, `MD_Constr_Mgr`, `MD_Constr_Brg`, `MD_Constr_Prop`, `MD_Constr_Sync` | `MD_ConstraintUnion` 是约束定义与引用关系的主数据袋 |
| L4_PH | 约束施加/登记 | `PH_Constr_Def`, `PH_Constr_Domain` | Populate 阶段登记约束，不复制 L3 表面网格 |
| L5_RT | 全局装配消费 | `RT_Asm_Solv` | `RT_Asm_ApplyL3Constraints` 在 Assembly 阶段消费 MPC/Tie/Coupling/Rigid |

**跨层主链**：`KeyWord/AP Input -> MD_ConstraintUnion -> PH_L4_Populate_Constraint -> PH_Constraint_Ctx -> RT_Asm_ApplyL3Constraints`。

**硬约束**：
- L3 只维护约束定义、表面解析和 Legacy 同步，不做数值装配。
- L4 只登记/准备约束施加上下文，不把解析后的网格副本写回 L3。
- L5 在全局 K/F 装配阶段处理约束贡献；若改变 CSR 模式，调用方必须触发重新符号分析。
