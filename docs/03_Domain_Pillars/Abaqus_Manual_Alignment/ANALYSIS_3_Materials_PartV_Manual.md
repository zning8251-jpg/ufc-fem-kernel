# ANALYSIS_3 材料卷（Part V）— 综合手册

**版本**：v1.2（合并版） — 与 Abaqus 2016 Analysis User’s Guide **Volume III / Part V Materials** 对齐  
**真源**：`UFC/Manual/ANALYSIS_3.pdf` + `UFC/REPORTS/analysis3_materials_ufc_mapping.json`、`analysis3_material_keyword_ufc_fields.csv`（本脚本）。  
**合同**：`UFC/ufc_core/L3_MD/Material/CONTRACT.md`、`L4_PH/Material/CONTRACT.md`、`L3_MD/Material/Contract/MD_Mat_Def.f90`。  
**结构**：**Part I**（手册 TOC / 页码 / 字段预览，**脚本自动替换**）+ **Part II**（分族与 TYPE 沉淀，**人工维护**）。

---

## Part I — 手册目录、页码与字段映射（自动更新）

下列区块由 `extract_analysis3_materials_ufc_mapping.py` **整段替换**（勿在标记之间手改）。<!-- ANALYSIS3_AUTO_PART1_BEGIN -->

> 生成：`UFC/tools/extract_analysis3_materials_ufc_mapping.py`（**PyMuPDF** 目录/翻页 + **pdfplumber** 表格）。
> 真源：手册 **Part V MATERIALS**；UFC **`mat_family` 1..11** 与 `MD_Mat_Def.f90` / 各族 Desc。
> **TYPE 文档规范名**：材料主卡 **`MD_Mat_Desc`**（三段式）；Fortran `PUBLIC` **`MD_Mat_Desc`**（`Contract/MD_Mat_Def.f90`，自 L3 Material 合同 **v2.2** 与文档对齐）；对照见 **[综合手册 Part II](ANALYSIS_3_Materials_PartV_Manual.md#part-ii-type-naming)** 命名表。注册层轻量描述符为 **`MD_Mat_LiteDesc`**（`Base/MD_Mat_BaseDef.f90`），勿与主卡混用。

### 1. 不是「一字母一文件」的一一映射

Abaqus **一章**常对应 **多个关键字行为**（可组合）。本表为 **主锚点**：

- **`mat_family` = NULL**：跨族元数据（第 21 章材料库/组合/密度等）→ 落在 **`MD_Mat_Desc`** / **`PH_Mat_Desc`** 通用字段与 Populate 逻辑。
- **子节**：以 **TOC 标题关键字** 归入 11 主族之一；争议项在 JSON 的 `classification` 字段标为 `keyword` / `chapter`。

### 2. 手册大章 → UFC 主族（章级锚点）

| Abaqus 章 | 手册主题 | 主 UFC `mat_family` | L3 目录 | L4 目录 |
|-----------|----------|---------------------|---------|---------|
| 21 | Materials: Introduction | （NULL，元数据） | `Contract/` `Domain/` `Shared/` | `PH_Mat_Domain_Core` / Populate |
| 22 | Elastic Mechanical Properties | **1** Elastic | `Elas/`（+部分 `HyperElas/` `Viscoelas/`） | `Elas/` `HyperElas/` `Viscoelas/` |
| 23 | Inelastic Mechanical Properties | **2** Plastic 为主 | `Plast/` `Geo/` `Creep/` | `Plast/` `Geo/` `Creep/` |
| 24 | Progressive Damage and Failure | **7** Damage | `Damage/` | `Damage/` |
| 25 | Hydrodynamic Properties | **11** User/Special | `User/` 等 | `Contract`+显式 |
| 26 | Other Material Properties | **9/10/11** 按节 | `Thermal/` `Acoustic/` `User/` | 对应子目录 |

### 3. TOC 抽样行（带物理页 + 推断族）

完整机器表见 **`UFC/REPORTS/analysis3_materials_ufc_mapping.json`**（`toc_part5_major`）。

| 物理页 | 目录标题 | `mat_family` | UFC 子目录 | 备注 |
|--------|----------|--------------|------------|------|
| 35 | 21. Materials: Introduction | — | — | `MD_Mat_Desc`/ `PH_Mat_Desc` 通用：材料库、组合表、密度等 |
| 37 | 21.1 Introduction | — | — | `MD_Mat_Desc`/ `PH_Mat_Desc` 通用：材料库、组合表、密度等 |
| 39 | 21.1.1 Material library: overview | — | — | `MD_Mat_Desc`/ `PH_Mat_Desc` 通用：材料库、组合表、密度等 |
| 41 | 21.1.2 Material data definition | — | — | `MD_Mat_Desc`/ `PH_Mat_Desc` 通用：材料库、组合表、密度等 |
| 49 | 21.1.3 Combining material behaviors | — | — | `MD_Mat_Desc`/ `PH_Mat_Desc` 通用：材料库、组合表、密度等 |
| 59 | 21.2 General properties | — | — | `MD_Mat_Desc`/ `PH_Mat_Desc` 通用：材料库、组合表、密度等 |
| 61 | 21.2.1 Density | — | — | `MD_Mat_Desc`/ `PH_Mat_Desc` 通用：材料库、组合表、密度等 |
| 63 | 22. Elastic Mechanical Properties | 1 | Elas/ | `Elas/` 为主；子节含 4/5 等 |
| 65 | 22.1 Overview | 1 | Elas/ | `Elas/` 为主；子节含 4/5 等 |
| 67 | 22.1.1 Elastic behavior: overview | 1 | Elas/ | `Elas/` 为主；子节含 4/5 等 |
| 71 | 22.2 Linear elasticity | 1 | Elas/ | `Elas/` |
| 73 | 22.2.1 Linear elastic behavior | 1 | Elas/ | `Elas/` |
| 83 | 22.2.2 No compression or no tension | 1 | Elas/ | `Elas/` |
| 87 | 22.2.3 Plane stress orthotropic failure measures | 1 | Elas/ | `Elas/` |
| 93 | 22.3 Porous elasticity | 1 | Elas/ | 手册在弹性卷 — UFC：`Elas/` 弹性矩阵 + `Geo/` 孔压耦合描述分工见域合同 |
| 95 | 22.3.1 Elastic behavior of porous materials | 1 | Elas/ | 手册在弹性卷 — UFC：`Elas/` 弹性矩阵 + `Geo/` 孔压耦合描述分工见域合同 |
| 99 | 22.4 Hypoelasticity | 1 | Elas/ | `Elas/`（率型表述） |
| 101 | 22.4.1 Hypoelastic behavior | 1 | Elas/ | `Elas/`（率型表述） |
| 103 | 22.5 Hyperelasticity | 4 | HyperElas/ | `HyperElas/` |
| 105 | 22.5.1 Hyperelastic behavior of rubberlike materials | 4 | HyperElas/ | `HyperElas/` |
| 131 | 22.5.2 Hyperelastic behavior in elastomeric foams | 4 | HyperElas/ | `HyperElas/` |
| 143 | 22.5.3 Anisotropic hyperelastic behavior | 4 | HyperElas/ | `HyperElas/` |
| 153 | 22.6 Stress softening in elastomers | 4 | HyperElas/ | `HyperElas/`（Mullins 等） |
| 155 | 22.6.1 Mullins effect | 4 | HyperElas/ | `HyperElas/` |
| 167 | 22.6.2 Energy dissipation in elastomeric foams | 1 | Elas/ | `Elas/` 为主；子节含 4/5 等 |
| 173 | 22.7 Linear viscoelasticity | 5 | Viscoelas/ | `Viscoelas/` |
| 175 | 22.7.1 Time domain viscoelasticity | 5 | Viscoelas/ | `Viscoelas/` |
| 193 | 22.7.2 Frequency domain viscoelasticity | 5 | Viscoelas/ | `Viscoelas/` |
| 201 | 22.8 Nonlinear viscoelasticity | 5 | Viscoelas/ | `Viscoelas/` |
| 203 | 22.8.1 Hysteresis in elastomers | 5 | Viscoelas/ | `Viscoelas/` |
| 207 | 22.8.2 Parallel rheological framework | 5 | Viscoelas/ | `Viscoelas/` |
| 217 | 22.9 Rate sensitive elastomeric foams | 1 | Elas/ | `Elas/` 为主；子节含 4/5 等 |
| 219 | 22.9.1 Low-density foams | 1 | Elas/ | `Elas/` 为主；子节含 4/5 等 |
| 227 | 23. Inelastic Mechanical Properties | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 229 | 23.1 Overview | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 231 | 23.1.1 Inelastic behavior | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 239 | 23.2 Metal plasticity | 2 | Plast/ | `Plast/` |
| 241 | 23.2.1 Classical metal plasticity | 2 | Plast/ | `Plast/` |
| 249 | 23.2.2 Models for metals subjected to cyclic loading | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 265 | 23.2.3 Rate-dependent yield | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 269 | 23.2.4 Rate-dependent plasticity: creep and swelling | 6 | Creep/ | `Creep/` — 与 `Plast/` 率相关小节交叉，以关键字为准 |
| 283 | 23.2.5 Annealing or melting | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 287 | 23.2.6 Anisotropic yield/creep | 2 | Plast/ | `Plast/`（屈服+蠕变各向异性 — 主塑性族） |
| 295 | 23.2.7 Johnson-Cook plasticity | 2 | Plast/ | `Plast/` |
| 303 | 23.2.8 Dynamic failure models | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 309 | 23.2.9 Porous metal plasticity | 2 | Plast/ | `Plast/` |
| 317 | 23.2.10 Cast iron plasticity | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 321 | 23.2.11 Two-layer viscoplasticity | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 327 | 23.2.12 ORNL – Oak Ridge National Laboratory constitutive model | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 331 | 23.2.13 Deformation plasticity | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 335 | 23.3 Other plasticity models | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 337 | 23.3.1 Extended Drucker-Prager models | 3 | Geo/ | `Geo/` — 例：`MD_Geo_DruckerPrager` + `PH_Mat_DP_*` |
| 365 | 23.3.2 Modified Drucker-Prager/Cap model | 3 | Geo/ | `Geo/` — 例：`MD_Geo_DruckerPrager` + `PH_Mat_DP_*` |
| 379 | 23.3.3 Mohr-Coulomb plasticity | 3 | Geo/ | `Geo/` — 例：`MD_Geo_DruckerPrager` + `PH_Mat_DP_*` |
| 389 | 23.3.4 Critical state (clay) plasticity model | 3 | Geo/ | `Geo/` — 例：`MD_Geo_DruckerPrager` + `PH_Mat_DP_*` |
| 399 | 23.3.5 Crushable foam plasticity models | 2 | Plast/ | `Plast/`（金属泡沫）— 与 Geo 区分见手册 |
| 411 | 23.4 Fabric materials | 3 | Geo/ | `Geo/` 或 `Composite/` 扩展 — 当前多走 `Geo`/anisotropic 路由 |
| 413 | 23.4.1 Fabric material behavior | 3 | Geo/ | `Geo/` 或 `Composite/` 扩展 — 当前多走 `Geo`/anisotropic 路由 |
| 433 | 23.5 Jointed materials | 3 | Geo/ | `Geo/` 或 `Composite/` 扩展 — 当前多走 `Geo`/anisotropic 路由 |
| 435 | 23.5.1 Jointed material model | 3 | Geo/ | `Geo/` 或 `Composite/` 扩展 — 当前多走 `Geo`/anisotropic 路由 |
| 441 | 23.6 Concrete | 7 | Damage/ | `Damage/` + `Plast/` 交叉 — UFC 以 `PH_MAT_DAMAGE` 为主标记 |
| 443 | 23.6.1 Concrete smeared cracking | 7 | Damage/ | `Damage/` + `Plast/` 交叉 — UFC 以 `PH_MAT_DAMAGE` 为主标记 |
| 457 | 23.6.2 Cracking model for concrete | 7 | Damage/ | `Damage/` + `Plast/` 交叉 — UFC 以 `PH_MAT_DAMAGE` 为主标记 |
| 467 | 23.6.3 Concrete damaged plasticity | 7 | Damage/ | `Damage/` + `Plast/` 交叉 — UFC 以 `PH_MAT_DAMAGE` 为主标记 |
| 487 | 23.7 Permanent set in rubberlike materials | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 489 | 23.7.1 Permanent set in rubberlike materials | 2 | Plast/ | `Plast/` 为主族；子节经关键字细分为 3/6/7 |
| 493 | 24. Progressive Damage and Failure | 7 | Damage/ | `Damage/` |
| 495 | 24.1 Progressive damage and failure: overview | 7 | Damage/ | `Damage/` |
| 497 | 24.1.1 Progressive damage and failure | 7 | Damage/ | `Damage/` |
| 501 | 24.2 Damage and failure for ductile metals | 7 | Damage/ | `Damage/` |
| 503 | 24.2.1 Damage and failure for ductile metals: overview | 7 | Damage/ | `Damage/` |
| 507 | 24.2.2 Damage initiation for ductile metals | 7 | Damage/ | `Damage/` |
| 523 | 24.2.3 Damage evolution and element removal for ductile metals | 7 | Damage/ | `Damage/` |
| 535 | 24.3 Damage and failure for fiber-reinforced composites | 7 | Damage/ | `Damage/` |
| 537 | 24.3.1 Damage and failure for fiber-reinforced composites: overview | 7 | Damage/ | `Damage/` |
| 541 | 24.3.2 Damage initiation for fiber-reinforced composites | 7 | Damage/ | `Damage/` |
| 545 | 24.3.3 Damage evolution and element removal for fiber-reinforced compo | 7 | Damage/ | `Damage/` |
| 553 | 24.4 Damage and failure for ductile materials in low-cycle fatigue ana | 7 | Damage/ | `Damage/` |
| 555 | 24.4.1 Damage and failure for ductile materials in low-cycle fatigue a | 7 | Damage/ | `Damage/` |
| 557 | 24.4.2 Damage initiation for ductile materials in low-cycle fatigue | 7 | Damage/ | `Damage/` |
| 559 | 24.4.3 Damage evolution for ductile materials in low-cycle fatigue | 7 | Damage/ | `Damage/` |
| 563 | 25. Hydrodynamic Properties | 11 | User/ | `User/`（SPU/EOS）或显式专用路径 — 见 CONTRACT 注 |
| 565 | 25.1 Overview | 11 | User/ | `User/` / 状态方程 |
| 567 | 25.1.1 Hydrodynamic behavior: overview | 11 | User/ | `User/`（SPU/EOS）或显式专用路径 — 见 CONTRACT 注 |
| 569 | 25.2 Equations of state | 11 | User/ | `User/` / 状态方程 |
| 571 | 25.2.1 Equation of state | 11 | User/ | `User/`（SPU/EOS）或显式专用路径 — 见 CONTRACT 注 |
| 595 | 26. Other Material Properties | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 597 | 26.1 Mechanical properties | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 599 | 26.1.1 Material damping | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 605 | 26.1.2 Thermal expansion | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 613 | 26.1.3 Field expansion | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 619 | 26.1.4 Viscosity | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 625 | 26.2 Heat transfer properties | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 627 | 26.2.1 Thermal properties: overview | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 629 | 26.2.2 Conductivity | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 631 | 26.2.3 Specific heat | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 633 | 26.2.4 Latent heat | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 635 | 26.3 Acoustic properties | 10 | Acoustic/ | `L3_MD/Material/Acoustic/` · `PH_Mat_Acoustic_*` |
| 637 | 26.3.1 Acoustic medium | 10 | Acoustic/ | `L3_MD/Material/Acoustic/` · `PH_Mat_Acoustic_*` |
| 647 | 26.4 Mass diffusion properties | 11 | User/ | 扩散场 — 偏 `L3_MD` Field/MassDiff，非结构 11 主族本构核 |
| 649 | 26.4.1 Diffusivity | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 655 | 26.4.2 Solubility | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 657 | 26.5 Electromagnetic properties | 11 | User/ | `User/` 电磁/耦合特殊 — 与 `GROUP_MAT_COMPAT` G5 对齐 |
| 659 | 26.5.1 Electrical conductivity | 11 | User/ | `User/` 电磁/耦合特殊 — 与 `GROUP_MAT_COMPAT` G5 对齐 |
| 661 | 26.5.2 Piezoelectric behavior | 11 | User/ | `User/` 电磁/耦合特殊 — 与 `GROUP_MAT_COMPAT` G5 对齐 |
| 667 | 26.5.3 Magnetic permeability | 11 | User/ | `User/` 电磁/耦合特殊 — 与 `GROUP_MAT_COMPAT` G5 对齐 |
| 673 | 26.6 Pore fluid flow properties | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 675 | 26.6.1 Pore fluid flow properties | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 677 | 26.6.2 Permeability | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 683 | 26.6.3 Porous bulk moduli | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 685 | 26.6.4 Sorption | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 689 | 26.6.5 Swelling gel | 6 | Creep/ | `Creep/` — 与 `Plast/` 率相关小节交叉，以关键字为准 |
| 691 | 26.6.6 Moisture swelling | 6 | Creep/ | `Creep/` — 与 `Plast/` 率相关小节交叉，以关键字为准 |
| 695 | 26.7 User materials | 9 | Thermal/ | `Thermal/` / `Acoustic/` / `User/` — 子节关键字再分 |
| 697 | 26.7.1 User-defined mechanical material behavior | 11 | User/ | `User/` + `PH_UMAT_*` / Dispatch 适配 |
| 705 | 26.7.2 User-defined thermal material behavior | 11 | User/ | `User/` + `PH_UMAT_*` / Dispatch 适配 |

### 4. Properties（数据结构）与 UFC 对齐思路

手册 **Type / Data lines** → UFC：**`MD_Mat_Desc`**（源码 `MD_Mat_Desc`；`cfg` / `pop` / `props` / `nProps` / `nStateV` / `behavior` …）见 `MD_Mat_Def.f90`；各族 **typed Desc**（如 **`MD_Mat_DP_Desc`**）由 Populate 从 `props` 解包。

#### 从 PDF 抽样的正文片段（关键词过滤）

##### density_21_2_1 — physical page 61

```text
DENSITY
DENSITY
• *DENSITY
Density can be deﬁned as a function of temperature and ﬁeld variables. Based on user-deﬁned data
```

##### elastic_22_2_1 — physical page 73

```text
LINEAR ELASTICITY
LINEAR ELASTIC BEHAVIOR
• *ELASTIC
*ELASTIC, MODULI=INSTANTANEOUS
```

##### combine_21_1_3 — physical page 49

```text
Abaqus provides a broad range of possible material behaviors.
the appropriate behaviors for the purpose of an analysis. This section describes the general rules for
combining material behaviors. Speciﬁc information for each material behavior is also summarized at
the end of each material behavior description section in this chapter.
Some of the material behaviors in Abaqus are completely unrestricted: they can be used alone or
together with other behaviors. For example, thermal properties such as conductivity can be used in any
Some material behaviors in Abaqus require the presence of other material behaviors, and some
exclude the use of other material behaviors. For example, metal plasticity requires the deﬁnition of elastic
material behavior or an equation of state and excludes all other rate-independent plasticity behaviors.
Abaqus requires that the material be sufﬁciently deﬁned to provide suitable properties for those elements
“Complete mechanical” category behavior or an “Elasticity” category behavior, as discussed below. In
All aspects of a material’s behavior need not be fully deﬁned; any behavior that is omitted is assumed
not to exist in that part of the model. For example, if elastic material behavior is deﬁned for a metal but
the material is adequately deﬁned for the purpose of the analysis. The material can include behaviors
```

### 5. `*MATERIAL` 子选项 ↔ `MD_Mat_Desc` / Desc 字段（字段级）

- **机器表**：`UFC/REPORTS/analysis3_material_keyword_ufc_fields.csv`（每关键字多行 = 多个物理量映射）。
- **JSON**：`keyword_page_index`（fitz 命中页）、`keyword_pdfplumber_tables`（表格原始网格）、`keyword_ufc_fieldmap_static`（静态绑定，可人工扩展）。

说明：**pdfplumber** 对扫描版/复杂排版表格可能失败；`pdfplumber_table_preview` 为空不代表手册无表，可增大 `max_pages` 或改 `table_settings` 后重跑。

#### 静态绑定预览（前 18 行）

| Abaqus keyword | UFC host | UFC logical field | Family Desc |
|----------------|----------|-------------------|-------------|
| *CONCRETE | MD_Mat_Desc | props(:); pop%nStateV | `Damage/` + `Plast/` |
| *CONDUCTIVITY | MD_Mat_Desc | props(:) via thermal Populate | `Thermal/` |
| *CREEP | MD_Mat_Desc | props(:); pop%nStateV (SDV) | `L3_MD/Material/Creep/` |
| *DENSITY | MD_Mat_Desc | props(k) packed by Populate OR section-l | — (跨族) |
| *DRUCKER PRAGER | MD_Mat_Desc + MD_Mat_DP_Desc | 主卡 props + Populate → MD_Mat_DP_Desc typ | `L3_MD/Material/Geo/MD_Geo_D |
| *ELASTIC | MD_Mat_Desc | props(:); cfg%matModel / cfg%materialTyp | `L3_MD/Material/Elas/*` + `P |
| *EOS | MD_Mat_Desc / User bundle | props(:) | `User/` |
| *EXPANSION | MD_Mat_Desc | props(:) | `Thermal/` + elastic couplin |
| *FABRIC | MD_Mat_Desc | props(:); cfg%behavior | `Geo/` / `Composite/`（织物） |
| *HYPERELASTIC | MD_Mat_Desc | props(:); cfg%matModel | `HyperElas/` + `PH_Mat_Hyper |
| *HYPERFOAM | MD_Mat_Desc | props(:) | `HyperElas/` |
| *HYPOELASTIC | MD_Mat_Desc | props(:) | `Elas/` hypo 分支 |
| *MOHR COULOMB | MD_Mat_Desc + MD_Mat_Mohr_Co | props(:) or typed Geo Desc | `Geo/PH_MatGeo_MohrCoulomb*` |
| *PLASTIC | MD_Mat_Desc | props(:); behavior; pop%nStateV | `L3_MD/Material/Plast/*` + ` |
| *SPECIFIC HEAT | MD_Mat_Desc | props(:) | `Thermal/` |
| *USER MATERIAL | MD_Mat_Desc + MD_Mat_UMAT_In | props(:); nProps; nStateV; materialType= | `User/` + `PH_UMAT_*` |
| *VISCOELASTIC | MD_Mat_Desc | props(:); pop%nStateV | `Viscoelas/` + `PH_Mat_Visco |

---

**维护**：扩展 `PRIORITY_KEYWORDS` 与 `KEYWORD_UFC_FIELDMAP`；换手册版本后重跑。
<!-- ANALYSIS3_AUTO_PART1_END -->

---

## Part II — 分族、关键字与 TYPE 总册（人工沉淀）

<a id="part-ii-type-naming"></a>

**版本**：v1.1（与 Abaqus 2016 Analysis User’s Guide **Volume III / Part V Materials** 对齐）  
**真源**：`UFC/Manual/ANALYSIS_3.pdf` + 自动生成产物 `UFC/REPORTS/analysis3_materials_ufc_mapping.json`、`analysis3_material_keyword_ufc_fields.csv`（`tools/extract_analysis3_materials_ufc_mapping.py`）。  
**UFC 合同**：`UFC/ufc_core/L3_MD/Material/CONTRACT.md`、`UFC/ufc_core/L4_PH/Material/CONTRACT.md`、`UFC/ufc_core/L3_MD/Material/Contract/MD_Mat_Def.f90`。  
**三本手册总对照（材料卷 × KEYWORD × USER × 辅 Desc 双列）**：[`Material_TripleManual_MasterCrosswalk.md`](../MaterialPillar/Material_TripleManual_MasterCrosswalk.md)。

---

### 0. TYPE 命名规范（文档规范名 ⇄ Fortran `PUBLIC`）

本册与 **`analysis3_material_keyword_ufc_fields.csv`** 的 **`ufc_host_type`** 列采用 **三段下划线**：**`MD_Mat_<Segment>_<Role>`**（Layer = `MD`，Domain = `Mat`，第三段起为 **本构/接口短名** + 末尾 **角色** `Desc` / `State` / `Algo` / `Ctx` / `Intf` …）。与 `ufc-naming-checker`、域柱技能中的 **可读分段** 一致。

| 文档规范名（本表 / CSV） | 当前源码 `PUBLIC`（典型位置） | 说明 |
|--------------------------|-------------------------------|------|
| **`MD_Mat_Desc`** | `MD_Mat_Desc`（`MD_Mat_Def.f90`） | **L3 材料主卡**：`cfg` / `pop` / `props` / `nProps` / `nStateV` / `behavior` …。文档与 Fortran **v2.2 起已对齐**；注册层见 **`MD_Mat_LiteDesc`**。 |
| **`MD_Mat_UMAT_Intf`** | `MD_MAT_UMAT_Intf` | UMAT 接口 bundle；历史名中 **`MAT` 全大写** 段保留在源码。 |
| **`MD_Mat_Base_Desc`** | `MD_Mat_Base_Desc` | 辅 Desc 基类，已一致。 |
| **`MD_Mat_DP_Desc`** | `MD_Mat_DP_Desc` | Drucker–Prager 辅 Desc，已一致。 |
| **`MD_Mat_Mohr_Coulomb_Desc`**（目标形态） | `MohrCoulomb_MatDesc`（`MD_MatPLG_MohrCoulomb.f90`） | Mohr–Coulomb 辅 Desc；迁移期 **CSV 写规范名**，代码检索用右列。 |
| **`MD_Material_Desc`** | `MD_Material_Desc` | **多材料表**容器，与单卡 **`MD_Mat_Desc`** 区分。 |
| **`DP_Mat_Desc`**（目标） | `DP_MatDesc`（`EXTENDS(MD_Mat_Desc)`） | 合约内遗留扩展名；新 Typed 优先 **`MD_Mat_<Feature>_Desc`**。 |
| **`PH_Mat_Desc`** | `PH_Mat_Desc`（L4） | 槽主 Desc，已一致。 |

**规则**：在 **`ANALYSIS_3_*.md`** 与脚本导出列中写 **左列**；实现与合同仍以 **`MD_Mat_Def.f90`** 与各模块 `PUBLIC` 为准。

---

### 1. 术语：手册「分类」与 UFC「域/族」

| 概念 | 说明 |
|------|------|
| **手册分族** | Part V 的 **章（21–26）** 与 **节标题**（如 23.2 金属塑性、23.3 岩土塑性）；以及 `*DENSITY`、`*ELASTIC` 等 **关键字子选项**。 |
| **UFC `mat_family` 1..11** | 实现侧 **固定 11 主族**（`MD_Ana_Comp.f90` / `L3_MD/Material/CONTRACT.md`），与 PDF 卷名 **不是字面一一对应**。 |
| **主 / 辅 TYPE** | **主 Desc**：跨关键字共享的 **材料卡**；**辅 Desc**：某本构族 **Typed** 参数体。L4 热路径上 **State / Algo / Ctx** 与 **`*_Arg`** 与 `ufc-structured-io` 五参一致。 |

---

### 2. UFC 材料域「主 / 辅 Desc」约定（沉淀规则）

以下规则与 **`ufc-layer-domain-feature` / `ufc-structured-io`** 一致，便于与工单 `Feature_Manifest_*` 对齐。

| 角色 | 层级 | 典型 TYPE / 载体 | 职责 |
|------|------|------------------|------|
| **主 Desc** | **L3** | **`MD_Mat_Desc`**（源码 `MD_Mat_Desc`，`MD_Mat_Def.f90`） | `cfg`（`matId` / `matModel` / `materialType` / `behavior`…）、`pop`（`nProps` / `nStateV` / `mat_model_id`）、**打包 `props(:)`**；**所有** `*MATERIAL` 子选项的数值最终须能落入此卡或可派生 Typed 子 Desc。 |
| **辅 Desc** | **L3** | 各族 **`MD_Mat_<Feature>_Desc`**（如 `MD_Mat_DP_Desc`） | 从 `props` / `cfg` **Populate** 得到的 **语义化字段**（E、ν、β、d…）；**Extend** `MD_Mat_Base_Desc` 等模式见 `Geo/`、`Plast/`。 |
| **槽 Desc（L4）** | **L4** | `PH_Mat_Desc` / `slot_pool%desc` | Populate 后 **IP 热路径** 读写的真源；**不**在热路径上回扫 L3 `MD_Mat_Lib`。 |
| **State** | **L4** | `PH_Mat_*_State` / `PH_Mat_PLM_*_State` | 应力、塑性应变、**`ddsdde`**、`STATEV` 类比量、`status` 等 **演化量**。 |
| **Algo** | **L4** | `PH_Mat_*_Algo` / `MD_Mat_Base_Algo` 扩展 | `ntens`、`compute_tangent`、子步开关等 **算法控制**。 |
| **Ctx** | **L4** | `PH_Mat_Base_Ctx`（试点可扩） | 应变增量、温度、场变量引用等 **增量上下文**（**INTENT(IN)** 为主）。 |
| **Args** | **L4** | `PH_Mat_*_*_Arg` | **SIO 单次 IO bundle**；`[IN]`/`[OUT]` 注释；**禁止**新建 `inp`/`out` 对偶。 |

**一句话**：手册 **Data lines** → **`MD_Mat_Desc%props` + `cfg/pop`**（主 Desc；源码 `MD_Mat_Desc`）→ Populate → **辅 Desc 字段** + **L4 槽** → **State/Algo/Ctx + Args** 参与 **`_Proc` / `_Core` 五参**。

---

### 3. Part V 章级分族（手册 → UFC `mat_family`）

| 章 | 手册名（Part V） | 手册侧「大类」 | 主 `mat_family` | UFC L3 主目录 | 备注 |
|----|------------------|----------------|-----------------|---------------|------|
| **21** | Materials: Introduction | 材料库 / 数据定义 / **行为组合** / **通用属性（密度等）** | **NULL**（跨族元数据） | `Contract/`、`Domain/`、`Shared/` | 不单独占 1–11；约束 **Populate + 组合合法性**。 |
| **22** | Elastic Mechanical Properties | 线弹 / 正交 / 孔弹 / 率型 / **超弹** / **粘弹** / Mullins 等 | **1**（主）+ **4/5**（子节） | `Elas/`、`HyperElas/`、`Viscoelas/` | 同一章跨多个 UFC 主族，以 **节标题 + `*KEYWORD`** 细分。 |
| **23** | Inelastic Mechanical Properties | 金属塑、蠕变、**岩土**、混凝土、织物… | **2**（主）+ **3/6/7** | `Plast/`、`Geo/`、`Creep/`、`Damage/` | 见 §5 关键字表。 |
| **24** | Progressive Damage and Failure | 渐进损伤 / 失效 | **7** | `Damage/` | 与 23 混凝土等 **关键字上交叉**，UFC 以 **`PH_MAT_DAMAGE`** 为主标记。 |
| **25** | Hydrodynamic Properties | 流体动压 / **EOS** | **11** | `User/` 等 | 与显式 / SPU 路径合同对齐。 |
| **26** | Other Material Properties | 热 / 声 / 用户 | **9 / 10 / 11** | `Thermal/`、`Acoustic/`、`User/` | 按节与 `GROUP_MAT_COMPAT` 收紧。 |

---

### 4. UFC 十一主族与「主/辅 Desc」默认形态

| `mat_family` | 主族 | **主 Desc** | **辅 Desc（典型）** | L4 族标记（示例） |
|-------------|------|-------------|---------------------|-------------------|
| 1 | Elastic | **`MD_Mat_Desc`** | `MD_Mat_Elastic_*` / 线弹 Typed | `PH_MAT_ELASTIC` |
| 2 | Plastic | **`MD_Mat_Desc`** | `MD_Pls_*` / J2、随动等 Typed | `PH_MAT_ELASTO_PLASTIC` |
| 3 | Geo | **`MD_Mat_Desc`** | `MD_Mat_DP_Desc`、`MD_Mat_Mohr_Coulomb_Desc`（目标名）、`CamClay*`… | `PH_MAT_GEOTECH` |
| 4 | Hyper | **`MD_Mat_Desc`** | 超弹能量系数 Typed / `HyperElas` | `PH_MAT_HYPERELASTIC` |
| 5 | VE | **`MD_Mat_Desc`** | `MD_Mat_Visco_*` / Prony | `PH_MAT_VISCOELASTIC` |
| 6 | Creep | **`MD_Mat_Desc`** | `Creep/` 各 Typed | `PH_MAT_CREEP` |
| 7 | Damage | **`MD_Mat_Desc`** | `Damage/` 各 Typed | `PH_MAT_DAMAGE` |
| 8 | Composite | **`MD_Mat_Desc`** | `Composite/` 层合 Typed | `PH_MAT_COMPOSITE` |
| 9 | Thermal | **`MD_Mat_Desc`** | `MD_Mat_Therm_*` / `MD_Thm_*` | 热标量 / 耦合 |
| 10 | Acoustic | **`MD_Mat_Desc`** | `MD_Mat_Acous_*` | `PH_MAT_ACOUSTIC` |
| 11 | User / Special | **`MD_Mat_Desc`** + **`MD_Mat_UMAT_Intf`**（源码 `MD_MAT_UMAT_Intf`）/ `MatCtxLegacy` | 用户打包 Typed | `PH_MAT_USER_*` |

---

### 5. `*MATERIAL` 子选项（材料卷命中）× 数据结构 × 主/辅 TYPE

下表由 **`analysis3_material_keyword_ufc_fields.csv`** 与静态 **`KEYWORD_UFC_FIELDMAP`** 归纳；**物理页**以 CSV 为准（节选 **首页**）。

| Abaqus 关键字 | 手册数据载体（抽象） | **主 Desc 字段逻辑** | **辅 Desc / Typed** | **State（L4 典型）** | **Algo** | **Ctx** | **Args** |
|---------------|----------------------|----------------------|------------------------|----------------------|----------|---------|----------|
| `*DENSITY` | ρ，可随温度/场变量 | **`MD_Mat_Desc%props`**（源码 `MD_Mat_Desc`）序或截面 bundle | — | 无独立密度 State | — | 场变量依赖时走 `Ctx`/`cfg` | Populate / 校验 `Arg%status` |
| `*ELASTIC` | E,ν 或 Dij | **`MD_Mat_Desc`**：`props(:)` + `cfg%matModel` | 各族线弹 Typed（若建模） | `stress`, `ddsdde` | `compute_tangent` | `dstran` 等 | `PH_Mat_Elas_*_Arg` 等 |
| `*PLASTIC` | 屈服、硬化表 | **`MD_Mat_Desc`**：`props` + `behavior` + `pop%nStateV` | `MD_Pls_*` / J2 Typed | 塑性应变、`peeq`、`is_plastic` | 同上 | 同上 | `*_Update_Arg` |
| `*CREEP` | 蠕变常数 | **`MD_Mat_Desc`**：`props` + `pop%nStateV` | `Creep/` Typed | `creep` 应变 / SDV | 蠕变子步控制 | 时间增量 | Args |
| `*HYPOELASTIC` | 率型模量 | **`MD_Mat_Desc`**：`props` | `Elas/` hypo | 应力率路径 | — | `dstran` | Args |
| `*HYPERELASTIC` / `*HYPERFOAM` | 应变能系数 | **`MD_Mat_Desc`**：`props` + `cfg%matModel` | `HyperElas/` | 有限应变度量相关状态 | 有限应变开关 | 变形梯度引用（合同扩） | Args |
| `*VISCOELASTIC` | Prony / 频域数据 | **`MD_Mat_Desc`**：`props` + `pop%nStateV` | `MD_Mat_Visco_*` | 粘弹历史状态 | 子步 / 积分 | 频率或时间 | Args |
| `*DRUCKER PRAGER` | β,d,ψ… | **`MD_Mat_Desc`**：`props`（打包） | **`MD_Mat_DP_Desc`**（Populate 解包） | **`PH_Mat_PLM_DP_State`**（例） | **`PH_Mat_PLM_DP_Algo`** | **`PH_Mat_Base_Ctx`** | **`PH_Mat_DP_Update_Arg`** |
| `*MOHR COULOMB` | φ,c,ψ… | **`MD_Mat_Desc`**：`props` | **`MD_Mat_Mohr_Coulomb_Desc`**（目标名；源码 `MohrCoulomb_MatDesc`） | 同族 `State` | 同族 `Algo` | `Ctx` | Args |
| `*CONDUCTIVITY` / `*SPECIFIC HEAT` / `*EXPANSION` / `*LATENTHEAT` … | 热物性 | **`MD_Mat_Desc`**：`props` + Thermal Populate | `Thermal/` `MD_Thm_*` / `MD_Mat_Therm_*` | 热学状态（若耦合） | 热步算法开关 | 温度/耦合 `Ctx` | Args |
| `*CONCRETE` / 损伤关键字 | 损伤变量、软化 | **`MD_Mat_Desc`**：`props` + `pop%nStateV` | `Damage/` + 与 `Plast` 交叉 Typed | 损伤 internal | 切线开关 | `Ctx` | Args |
| `*EOS` / `*USER MATERIAL` | 状态方程 / UMAT 常数 | **`MD_Mat_Desc`** + **`MD_Mat_UMAT_Intf`**（源码 `MD_MAT_UMAT_Intf`） | `User/` bundle | `statev` 类比 | UMAT 标志 | `MatCtxLegacy` / `Ctx` | **`PH_UMAT_*` Arg** 合同 |

**说明**：

- **同一材料卡**可挂 **多个关键字**（`*ELASTIC` + `*PLASTIC` + `*DENSITY`）；**主 Desc 唯一**，辅 Desc 可 **多个**（按组合表合法扩展）。  
- **具体 Fortran `PUBLIC` 名**以仓库 **`MD_Mat_Def.f90`** 与各族模块为准；本表 **§0** 给出 **文档规范名 ⇄ 源码** 对照，不替代编译期符号。  
- 完整 **关键字命中页** 见 **`UFC/REPORTS/analysis3_material_keyword_ufc_fields.csv`**。

---

### 6. 与现有工单 / 脚本的关系

| 产物 | 用途 |
|------|------|
| `Feature_Manifest_L4_PH_Material_DruckerPrager.md` | **单族**（DP）四类 + SIO 的完整工单示例。 |
| 本文 **Part I**（脚本刷新标记区） | 手册 Part V TOC × `mat_family` + pdfplumber 表预览入口。 |
| `Material_11Families_L3L4L5_三层打通清单.md` | L3/L4/L5 **改造顺序**与目录真源。 |
| `analysis3_materials_ufc_mapping.json` | 机器可读：TOC、`keyword_page_index`、`keyword_pdfplumber_tables`；静态域图 **`keyword_ufc_fieldmap_static`** 中 **`ufc_host_type`** 与 **§0** 同规范。 |

---

### 7. 维护流程

1. 升级 **Abaqus 手册版本** 后：重跑 `python UFC/tools/extract_analysis3_materials_ufc_mapping.py`。  
2. 新增关键字：扩展脚本内 **`PRIORITY_KEYWORDS`**、**`KEYWORD_UFC_FIELDMAP`** 与本表 §5。  
3. 某族 **Typed Desc** 落地后：在本表 §4/§5 增加 **精确 TYPE 名** 与 **`_Proc`/`_Core` 模块链接**。

---

*本册为设计沉淀；若与 `CONTRACT.md` 或 `MD_Mat_Def.f90` 冲突，以 **合同与代码** 为准并回修本表（含 **§0** 对照行）。*
