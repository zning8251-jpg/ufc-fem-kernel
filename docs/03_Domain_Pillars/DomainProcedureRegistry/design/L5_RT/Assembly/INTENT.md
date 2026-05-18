# `L5_RT` / `Assembly` 设计意图（域桶）

> **域桶**：`ufc_core/L5_RT/Assembly/`（含子域目录）。  
> **验收向**：本 INTENT + [`CONVENTIONS.md`](../../../CONVENTIONS.md) + 域内 `CONTRACT.md`（若存在）+ `manifest.json` ↔ `align.py`。

## 1. 问题与目标

- **职责**：本目录为 **六层架构** 中 `L5_RT` 之下的一级 **域桶**；子目录为子域，**`manifest.json`** 仍按 **整桶递归** 与 `ufc_core` / `generated/` 对账。
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

- 域合同：[`CONTRACT.md`](../../../../../ufc_core/L5_RT/Assembly/CONTRACT.md)
- [`manifest.schema.json`](../../manifest.schema.json)  
- 推断清单（叙述密度参考）：[`UFC_层级域级f90文件推断清单_v2.0.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md)  
- 设计目录说明：[`design/README.md`](../../README.md)  

## 6. L3/L4/L5 域柱同步锚点

**分类**：半柱域（L3 Assembly/Mesh/Constraint/LoadBC 真源 + L5 全局装配；L4 提供物理贡献）。

| 层 | 角色 | 目标模块 | 说明 |
|----|------|----------|------|
| L3_MD | 装配输入真源 | `MD_Asm_Mgr`, `MD_Mesh_API`, `MD_Constr_Mgr`, `MD_LBC_*` | 装配体、拓扑、约束、载荷边界定义 |
| L4_PH | 物理贡献提供者 | `PH_ElemDomain_Ops`, `PH_Cont_Domain`, `PH_Constr_Domain`, `PH_LBC_*` | 提供 Ke/Fe、接触、约束和载荷的物理侧结果 |
| L5_RT | 全局归约与调度 | `RT_Asm_Solv`, `RT_Asm_DofMap`, `RT_Asm_Proc`, `RT_Asm_Def` | DofMap、单元循环、Triplet/CSR、约束/接触/载荷汇入 |

**跨层主链**：`StepDriver -> RT_Asm_DofMap_Build -> PH_Element_Compute_Ke/Fe -> RT_Triplet_Add / CSR -> Solver`。

**硬约束**：
- Assembly 不计算单元 Ke/Fe；这些由 L4 Element/Material 完成。
- Assembly 热路径不回 L3 全库扫描；只能通过已构建 DofMap、缓存和必要的索引 API 消费。
- 改变稀疏模式的约束/接触/罚项必须显式传播 reanalyze 标志给 Solver。
