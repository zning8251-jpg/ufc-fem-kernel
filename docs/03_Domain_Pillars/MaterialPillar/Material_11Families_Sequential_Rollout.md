# 11 主族顺序落地索引（mat_family 1→11）

**状态**：执行索引（与 [`Material_11Families_L3L4L5_三层打通清单.md`](./Material_11Families_L3L4L5_三层打通清单.md)、[`Material_Family_Rollout_Matrix.md`](./Material_Family_Rollout_Matrix.md) 对齐）。  
**工单模板**：[`Material_Family_WorkOrder_Template.md`](./Material_Family_WorkOrder_Template.md)  
**6.14 叶类型主表（严格 41 行）**：[`Abaqus614_Material_Leaf41.md`](./Abaqus614_Material_Leaf41.md)  
**Multitask 子任务 backlog**：[`Material_Leaf41_Multitask_Backlog.md`](./Material_Leaf41_Multitask_Backlog.md) · [`Leaf41_UFC_Crosswalk.csv`](./Leaf41_UFC_Crosswalk.csv)  
**手册 TYPE 总册**：[`../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md`](../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md) Part II  

开展顺序：**严格 `mat_family` 1→11**（与计划一致）。每族独立 MR；大族（Hyper、User）可拆子 MR，仍归该族 Phase。

---

## 通用 DoD（每族 MR 复制）

见工单模板 §6；并满足 `UFC/ufc_core/L3_MD/Material/CONTRACT.md` **v2.3** §「11 主族顺序落地 · 过程命名与 Contract 分文件」硬约束。

---

## F1 — Elastic（`mat_family=1`）

| 项 | 内容 |
|----|------|
| L3 | `ufc_core/L3_MD/Material/Elas/`；Contract：`Contract/MD_MatELA_CoupledDesc.f90`（热-力-压电耦合等） |
| 手册 | `*ELASTIC`，`TYPE=ISOTROPIC` / `ORTHOTROPIC` / `TRAVERSE` / `ANISOTROPIC` / `HYPOELASTIC` / `POROUS` 等 |
| L4 | `ufc_core/L4_PH/Material/Elas/` · `PH_MAT_ELASTIC` |
| L5 | `L5_RT/Material/` 表驱动；`elem_to_mat_map` 见 L3 CONTRACT |
| Rollout 矩阵 | 当前 Elastic 多列为 DONE；后续扩「精确族核 dispatch 测试」见矩阵「Next closure」 |

**本 MR 建议首件**：选一子族（如 ISO）填工单模板 §1–§2，补 `props`/typed Desc 缺口并跑 audit。

---

## F2 — Plastic（`mat_family=2`）

| 项 | 内容 |
|----|------|
| L3 | `ufc_core/L3_MD/Material/Plast/` + Contract 塑性相关 TYPE |
| 手册 | `*PLASTIC`、Hill、Barlat、Johnson-Cook、GTN、率相关、Chaboche 等 |
| L4 | `L4_PH/Material/Plast/` · `PH_MAT_ELASTO_PLASTIC` |
| 与 F6 边界 | 蠕变/率相关 **主归属** 以 `CONTRACT.md` 子域划分为准；避免 Plast/Creep 双真源 |

---

## F3 — Geo（`mat_family=3`）

| 项 | 内容 |
|----|------|
| L3 | `Material/Geo/`；`Contract/MD_MatPlgGeotech_Def.f90` |
| 手册 | `*DRUCKER PRAGER`、`*MOHR COULOMB`、`*CLAY PLASTICITY`、`*CONCRETE DAMAGED PLASTICITY` 等 |
| L4 | `L4_PH/Material/Geo/` · `PH_MAT_GEOTECH` |
| 深度模板 | [`Feature_Manifest_L4_PH_Material_DruckerPrager.md`](../Abaqus_Manual_Alignment/Feature_Manifest_L4_PH_Material_DruckerPrager.md) |

---

## F4 — Hyperelastic（`mat_family=4`）

| 项 | 内容 |
|----|------|
| L3 | `Contract/MD_MatHYP_Def.f90`（大表）+ `Material/HyperElas/` |
| 手册 | `*HYPERELASTIC` 各 `TYPE=`（Neo、Mooney、Ogden、Yeoh、Arruda-Boyce、Foam、Marlow…） |
| L4 | `L4_PH/Material/HyperElas/` · `PH_MAT_HYPERELASTIC` |
| 拆 MR 建议 | 按 `TYPE=` 分子 MR（仍属 F4） |

---

## F5 — Viscoelastic（`mat_family=5`）

| 项 | 内容 |
|----|------|
| L3 | `Contract/MD_MatVSC_Def.f90` + `Material/Viscoelas/` |
| 手册 | `*VISCOELASTIC`、Prony、WLF 等 |
| L4 | `L4_PH/Material/Viscoelas/` · `PH_MAT_VISCOELASTIC` |
| 与 F6 | 明确率/粘弹/蠕变文档边界 |

---

## F6 — Creep / VP（`mat_family=6`）

| 项 | 内容 |
|----|------|
| L3 | `Material/Creep/` + Contract 蠕变相关 |
| 手册 | `*CREEP`、可压碎泡沫等与蠕变/孔隙相关关键字（以手册为准） |
| L4 | `L4_PH/Material/Creep/` · `PH_MAT_CREEP` |

---

## F7 — Damage（`mat_family=7`）

| 项 | 内容 |
|----|------|
| L3 | `Contract/MD_MatDMG_Def.f90` + `Material/Damage/` |
| 手册 | `*DAMAGE INITIATION` / `*DAMAGE EVOLUTION` 等 |
| L4 | `L4_PH/Material/Damage/` · SDV / 演化测试锚点 |

---

## F8 — Composite（`mat_family=8`）

| 项 | 内容 |
|----|------|
| L3 | `Material/Composite/` |
| 手册 | 层合、Hashin、Puck、渐进损伤等 |
| L4 | `L4_PH/Material/Composite/`（截面/层合边界见 L4 CONTRACT） |

---

## F9 — Thermal（`mat_family=9`）

| 项 | 内容 |
|----|------|
| L3 | `Material/Thermal/` |
| 手册 | `*CONDUCTIVITY`、`*EXPANSION`、`*SPECIFIC HEAT`、`*LATENT HEAT` 等 |
| L4 | `L4_PH/Material/Thermal/`（以 L4 CONTRACT 目录为准） |
| 相容 | `MD_Ana_Comp.f90` `GROUP_MAT_COMPAT` 第 9 列 |

---

## F10 — Acoustic（`mat_family=10`）

| 项 | 内容 |
|----|------|
| L3 | `Material/Acoustic/` |
| 手册 | `*ACOUSTIC MEDIUM`、吸声等 |
| L4 | `L4_PH/Material/Acoustic/` · `PH_MAT_ACOUSTIC` |

---

## F11 — User / EM / SPU（`mat_family=11`）

| 项 | 内容 |
|----|------|
| L3 | `Material/User/`；`Contract/MD_MatSPU_Def.f90`；`MD_MAT_UMAT_*` 在 `Contract/MD_Mat_Def.f90` |
| 手册 | `*USER MATERIAL`、VUMAT、UEL |
| 约束 | **冷路径** bundle；不默认依赖 `ABA_PARAM.INC`；不在 L3 扩热路径本构 |
| L4/L5 | `PH_MAT_USER_*` + RT 薄路由 |

---

## 审计与基线

每族 MR 合并前执行：

```text
python UFC/tools/material_pillar_audit.py
```

基线快照（本仓库已落一版）：[`UFC/REPORTS/material_pillar_inventory_baseline_2026-05-02.csv`](../../../REPORTS/material_pillar_inventory_baseline_2026-05-02.csv)（由 `material_pillar_inventory.csv` 拷贝；后续 MR 可更新日期后缀）。
