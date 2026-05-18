# `L4_PH` / `Material` 设计意图（域桶）

> **域桶**：`ufc_core/L4_PH/Material/`（含子域目录）。  
> **验收向**：本 INTENT + [`CONVENTIONS.md`](../../../CONVENTIONS.md) + 域内 `CONTRACT.md`（若存在）+ `manifest.json` ↔ `align.py`。

## 1. 问题与目标

- **职责**：本目录为 **六层架构** 中 `L4_PH` 之下的一级 **域桶**；子目录为子域，**`manifest.json`** 仍按 **整桶递归** 与 `ufc_core` / `generated/` 对账。
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
| manifest 漂移 | 旧清单仍包含 compact/camelCase 路径，如 `PH_MatBaseDefn.f90`、`PH_MatDispatch.f90`、`PH_MatReg.f90` 等 | 以 `ufc_core/L4_PH/Material/**/*.f90` 当前磁盘路径为权威，使用 underscore/current-name 清单 | P0 |
| 目录真源 | 当前磁盘目录为 `AI/`、`Base/`、`Composite/`、`Contract/`、`Damage/`、`Dispatch/`、`Elas/`、`Geo/`、`Plast/` 加根部容器文件 | 合同与报告以当前目录为准；旧 `Elastic/Plastic/Geotech/UMAT/Shared` 口径仅作历史参考 | P0 |
| Domain container | `PH_Mat_Domain_Core.f90` 已成为 slot/cache 真源 | 明确只负责 `PH_Mat_Domain`、`PH_Mat_Slot`、Idx API，不承载族内本构算法 | P0 |
| Hot-path target | `MD_MatRT_Brg` legacy 调用仍存在于部分 Element | 后续迁移目标为 L5 `RT_Mat_Dispatch_Ctx` + L4 `PH_Mat_*` kernel；本阶段先稳定 L4 落点 | P1 |

## 5. 参考

- 域合同：[`CONTRACT.md`](../../../../../ufc_core/L4_PH/Material/CONTRACT.md)
- [`manifest.schema.json`](../../manifest.schema.json)  
- 推断清单（叙述密度参考）：[`UFC_层级域级f90文件推断清单_v2.0.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v2.0.md)  
- 设计目录说明：[`design/README.md`](../../README.md)  

## 6. L4 Material 同步治理锚点

- `manifest.json` 已按当前 36 个 `.f90` 源文件重建，作为 registry 对账真源。
- `ufc_core/L4_PH/Material/GOVERNANCE.md` 是本阶段 L4 Material 治理台账，记录目录真源、容器/内核/dispatch 分工与后续 hot-path 迁移入口。
- 本阶段不批量重命名 L4 Material 文件；先消除 manifest/合同漂移，再选择 CPE4 或 C3D8 做热路径迁移示范。
