# 材料域：11 主族 × L3/L4/L5 三层打通清单

**状态**：执行清单（与 `L3_MD/Material/CONTRACT.md`、`L4_PH/Material/CONTRACT.md`、本目录 `Material_Family_Rollout_Matrix.md` 对齐）。  
**按 `mat_family` 1→11 顺序开展**：见 [`Material_11Families_Sequential_Rollout.md`](./Material_11Families_Sequential_Rollout.md)、[`Material_Family_WorkOrder_Template.md`](./Material_Family_WorkOrder_Template.md)。  
**操作范式**：你已确认的 PyMuPDF 页窗抽取 → 理论方程 → **工单 Manifest** → **四类 TYPE + SIO 五参** 装箱（`ufc-layer-domain-feature` + `ufc-structured-io`），**禁止**把手册 Fortran 形参表直接当 UFC 域边界。

---

## 0. 真源（不要另造一套「族编号」）

| 项目 | 位置 |
|------|------|
| 族个数 `AC_N_MAT_FAM = 11` | `UFC/ufc_core/L3_MD/Analysis/MD_Ana_Comp.f90` |
| 物理解算组 G1–G9 × 材料族 1–11 合法组合 | 同文件 `GROUP_MAT_COMPAT(AC_N_GROUP, AC_N_MAT_FAM)` |
| L3 子目录命名与族语义 | `UFC/ufc_core/L3_MD/Material/CONTRACT.md` §「子域划分（11 主族）」 |
| L4 族内核目录与 T1 标记 | `UFC/ufc_core/L4_PH/Material/CONTRACT.md` §「族内核目录」 |
| L5 薄实现 | `UFC/ufc_core/L5_RT/Material/RT_Mat_{Def,Core,Brg}.f90` |
| 族推进验收等级（L0–L5） | 本目录 `Material_Family_Rollout_Matrix.md` |

**审计产物**：运行 `python UFC/tools/material_pillar_audit.py` → 默认写入 `UFC/docs/03_Domain_Pillars/MaterialPillar/material_pillar_inventory.csv`（**唯一真源目录**，以脚本最新输出为准）。

**Abaqus 材料卷（ANALYSIS_3）分族与 TYPE 总册**：[`../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md#part-ii-type-naming`](../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md#part-ii-type-naming)（综合手册 **Part II**；原 `*_Catalog.md` 已并入）

**11 主族 × 建议二级子族（逻辑目录，对齐 Abaqus 用）**：[`Material_11Families_Subfamily_Directory.md`](./Material_11Families_Subfamily_Directory.md)（当前 L3/L4 主族下多为扁平 `.f90`，表中为 **建议二级目录名 + 现网 stem 映射**）。

---

## 1. 十一主族总表（材料类型清单）

| `mat_family` | 主族（CONTRACT 名） | L3_MD 目录 | L4_PH 族目录 / 代表标记 | L5_RT 衔接 |
|-------------|---------------------|------------|-------------------------|------------|
| **1** | Elastic | `L3_MD/Material/Elas/` | `L4_PH/Material/Elas/` · `PH_MAT_ELASTIC` | `RT_Mat_Brg_BuildTable_FromMaterial` 读 L4 `slot_pool` |
| **2** | Plastic | `Plast/` | `Plast/` · `PH_MAT_ELASTO_PLASTIC` | 同上；PLM dispatch 与 J2/随动等族核 |
| **3** | Geo | `Geo/` | `Geo/` · `PH_MAT_GEOTECH` | 同上；Mohr-Coulomb / **Drucker-Prager** / Cam-Clay |
| **4** | Hyper | `HyperElas/` | `HyperElas/` · `PH_MAT_HYPERELASTIC` | 同上；有限应变状态合同 |
| **5** | VE（粘弹） | `Viscoelas/` | `Viscoelas/` · `PH_MAT_VISCOELASTIC` | 同上；Prony/WLF 等时间步状态 |
| **6** | VP/Creep | `Creep/` | `Creep/` · `PH_MAT_CREEP` | 同上；蠕变/率相关与 Plast/VE 交叉时**单一族主归属**以 CONTRACT 为准 |
| **7** | Damage | `Damage/` | `Damage/` · `PH_MAT_DAMAGE` | 同上；SDV/损伤演化测试锚点 |
| **8** | Composite | `Composite/` | `Composite/` · `PH_MAT_COMPOSITE` | 同上；层合/截面边界见域合同 |
| **9** | Heat/Thermal | `Thermal/` | `Thermal/` · 热标量/耦合路由 | 同上；与 G2 组相容矩阵见 `GROUP_MAT_COMPAT` 第 9 列 |
| **10** | Acoustic | `Acoustic/` | `Acoustic/` · `PH_MAT_ACOUSTIC` | 同上；流体声学 vs 结构 G1 差异 |
| **11** | EM/User | `User/` | `Contract/` + Dispatch 中 UMAT/VUMAT 等 · `PH_MAT_USER_*` | 同上；禁止在 L3 扩热路径本构 |

---

## 2. 「三层打通」每层必做项（改造检查项）

### L3_MD（模型描述 / Populate 真源）

- [ ] 该族 **Desc/Validation/Registry** 以 `Contract/MD_Mat_Def.f90`、`Domain/`、`Registry/` 为 SSOT，**不**在 `Dispatch/MD_Mat_Lib.f90` 上新增本构求值/应力/切线 API（见 `GOVERNANCE.md` 冻结条）。
- [ ] **双写**：`MD_Mat_Desc_SyncDeprecatedFlat` 为嵌套 cfg ↔ 扁平 deprecated **唯一入口**。
- [ ] **冷桥**：`Bridge_L4/MD_MatLibPH_Brg.f90` 仅兼容路径；新热路径经 L4 Populate 后读 **slot**。

### L4_PH（物理核 / 族核 / SIO）

- [ ] **Populate 金线**：`PH_L4_Populate_Material` → `slot_pool%desc%props`；IP 循环 **禁止**调 `MD_PH_RouteToConstitutive_Idx` 热路径（见 L4 CONTRACT）。
- [ ] 族内新本构：**`_Proc` + `_Core`**（或域已约定的 `_Def`/Contract），对外 **五参 `(desc, state, algo, ctx, args)`**；`*_Arg` 内 `[IN]/[OUT]` 注释，**无** `inp`/`out` 对偶。
- [ ] **注册表**：`PH_Mat_Reg` / `PH_Mat_Dispatch` 与 `PH_MAT_*` 枚举一致，不绕过热路径门面 `PH_Mat_Core.f90`。

### L5_RT（薄路由 + 写回）

- [ ] **表驱动**：`RT_Mat_Brg_BuildTable_FromMaterial` 由 L4 已灌槽的 `PH_Mat_Domain` 构建 `RT_Mat_Dispatch_Table`。
- [ ] **无状态拷贝**：不在 L5 复制 Desc/IP 状态；诊断/写回走合同化 hook（见 Rollout Matrix L5 行）。

---

## 3. 建议改造顺序（与 Rollout 矩阵一致，可并行文档）

1. **Elastic（1）**：已 L1–L3 闭合为主；扩核测试与 dispatch 覆盖。  
2. **Geo（3）**：以 **Drucker-Prager** 工单为模板（见 `docs/03_Domain_Pillars/Abaqus_Manual_Alignment/Feature_Manifest_L4_PH_Material_DruckerPrager.md`），推广 Mohr-Coulomb、Cam-Clay。  
3. **Plastic（2）**：隔离 legacy UMAT 热路径后，补 **真实 J2/随动** 族核 dispatch 测试。  
4. **Hyper / VE / Creep（4–6）**：先 **状态增量合同**（有限应变、Prony、蠕变 old/new），再并 L5。  
5. **Damage / Composite（7–8）**：SDV 与截面/层合边界。  
6. **Thermal / Acoustic / User（9–11）**：按 `GROUP_MAT_COMPAT` 与物理解算组收紧非法组合；User 族只做 bundle + 适配，不回流 L3 求值。

---

## 4. 与本仓库其它产物的关系

| 产物 | 用途 |
|------|------|
| `Material_Family_Rollout_Matrix.md` | 族 × Route Level（L0–L5）验收状态 |
| `material_pillar_backlog.md` | L3 quarantine / 缺测试热行 |
| `Feature_Manifest_L4_PH_Material_DruckerPrager.md` | 单族理论 → UFC 装箱示例 |
| `REPORTS/Manual_UFC_domain_subroutine_mapping_guide.md` | 手册章节 ↔ UFC 域（导航，非代码真源） |

---

**维护**：新增 L4 族目录或 `PH_MAT_*` 枚举时，同步更新本表第 1 节与 `Material_Family_Rollout_Matrix.md`；`mat_family` 编号变更必须同时改 `MD_Ana_Comp.f90` 与两份 CONTRACT。
