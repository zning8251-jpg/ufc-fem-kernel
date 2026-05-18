# `L3_MD` / `Material` 设计意图（域桶）

> **域桶**：`ufc_core/L3_MD/Material/`（含子域目录）。  
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
| 目录真源 | 当前磁盘目录为 `Acoustic/Composite/Concrete/Creep/Damage/Dispatch/Elas/Foam/Geo/HyperElas/Plast/Registry/Shared/Thermal/User/Viscoelas` 等；11 家族主目录以 `Elas/Plast/Geo/HyperElas/Viscoelas/Creep/Damage/Composite/Thermal/Acoustic/User` 为治理矩阵 | manifest 与合同使用 underscore/current-name 路径，不再回退旧 compact/camelCase 命名 | P0 |
| manifest 漂移 | 旧清单仍可能包含 `Base/MD_Mat_Def.f90`、`Domain/MD_Mat.f90`、camelCase 文件名或错误 module metadata | 以 `ufc_core/L3_MD/Material/**/*.f90` 磁盘实际路径为权威重建 Material bucket 清单 | P0 |
| legacy aggregate | `Dispatch/MD_Mat_Lib.f90` 仍承载类型、DB、validation、registry helper、compute-like legacy public surface | 保留 facade；新增代码导向 `Contract/`、`Domain/`、`Registry/`、`Shared/` 或 L4 `PH_Mat_*` | P1 |
| L3 热路径 | `MD_MatRT_Brg::MD_Mat_Dispatch` 与 `MD_MatLibPH_Brg::MD_PH_RouteToConstitutive*` 仍有热路径风险 | 作为 legacy 迁移对象；新链路使用 L4 slot + L5 `RT_Mat` route ctx | P1 |

## 5. 参考

- 域合同：[`CONTRACT.md`](../../../../../ufc_core/L3_MD/Material/CONTRACT.md)
- [`manifest.schema.json`](../../manifest.schema.json)  
- 推断清单（叙述密度参考）：[`UFC_层级域级f90文件推断清单_v2.0.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md)  
- 设计目录说明：[`design/README.md`](../../README.md)  

## 6. L3/L4/L5 域柱同步锚点

**分类**：全柱域（L3 Material Desc 真源、L4 Material 物理计算、L5 调度消费）。

| 层 | 角色 | 目标模块 | 说明 |
|----|------|----------|------|
| L3_MD | 材料定义真源 | `Contract/MD_Mat_Def.f90`, `Domain/MD_MatDomain_Def.f90`, `Domain/MD_Mat_Mgr.f90`, `Registry/MD_MatReg_Algo.f90`, `Dispatch/MD_Mat_Lib.f90` | 材料常数、表、类型、UMAT/VUMAT 路由数据；不计算应力/切线 |
| L4_PH | 本构计算 | `PH_Mat_Domain_Core`, `PH_Mat_Reg_*`, `PH_Mat_*_Core`, `PH_MatPLMEval` | `slot_pool%ctx%props` 与 `state%C_tan/stress/stateVars` 是热路径主数据 |
| L5_RT | 调度消费 | `RT_Asm_Solv`, `RT_Mat_*`, `RT_Solv_*` | 通过 Element/Assembly/Solver 间接消费材料切线、应力和状态 |

**跨层主链**：`MD_Mat_Desc -> PH_L4_Populate_Material -> PH_Mat_Slot -> PH_Element_Compute_Ke/Fe -> RT_Asm_GlobalStiffness/ComputeResidual`。

**硬约束**：
- L3 Material 不提供 `Compute_Ctan`、应力更新或状态变量演化。
- L4 Material 热路径必须读 Populate 后的 slot，不在积分点循环中调用 L3 材料库。
- L5 只调度材料相关计算和消费结果，不持久复制 L3 材料 Desc。

**P1 闭环卡**：`ufc_core/L3_MD/Material/DOMAIN_PILLAR_CARD.md` 是 Material 域柱的人工验收锚点；manifest 对账只记录文件漂移，不替代三层职责判定。

## 7. 全量治理同步记录

- `manifest.json` 已按当前磁盘路径治理为 underscore/current-name 规则的对账目标；若 registry 工具仍报告非 Material bucket drift，只记录不在本阶段修复。
- `ufc_core/L3_MD/Material/GOVERNANCE.md` 是 L3 Material 全量治理台账，覆盖 11 家族矩阵、legacy 禁止扩展清单、`MD_Mat_Lib` public surface 分组、Lib↔Registry cycle 和热路径违规清单。
