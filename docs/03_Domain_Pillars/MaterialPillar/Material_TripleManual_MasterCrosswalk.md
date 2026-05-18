# 三本手册 → 材料域总合同（章节对照 / 双列辅 Desc）

**版本**：v1.2  
**状态**：人工维护；与脚本产物、合同、源码 `PUBLIC` 符号**冲突时**以 **`ufc_core/L3_MD/Material/CONTRACT.md`** + **`Contract/MD_Mat_Def.f90`** 为准。  
**范围**：**材料本构与材料块内关键字**；整模型 L0–L5（Model / Part / Mesh / …）见团队总体架构文档，**不在此页展开**。

---

## 1. 三本 PDF 真源（与仓库内 Markdown 镜像一致）

下列 **PDF 文件名** 与 **`Markdown/ABAQUS_USB_2016/README.md`**（相对仓库根 `TEST7/`）中「来源」表一致：来自上级目录 **`ABAQUS手册/`** 的 USB 2016 摘录。**若本地未放置该目录**，以下路径为约定占位；正文检索优先用 **Markdown 镜像**。

| 手册 | PDF（约定路径，相对 `TEST7/`） | Markdown 镜像（相对 `UFC/` 仓根：`docs/03/.../MaterialPillar/` → `../../../../Markdown/...`） | UFC 脚本/合同 |
|------|----------------------------------|----------------------------------------------------------------------------------------------------------|----------------|
| **材料卷 Part V** | `ABAQUS手册/ANALYSIS_3.pdf` | [`ANALYSIS_3.md`](../../../../Markdown/ABAQUS_USB_2016/ANALYSIS_3/ANALYSIS_3.md) | [`ANALYSIS_3_Materials_PartV_Manual.md`](../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md) |
| **关键字手册**（Input Reference） | `ABAQUS手册/KEYWORD.pdf`（**不是** `UFC/Manual/KEYWORD.pdf`，除非你们另行拷贝） | [`KEYWORD.md`](../../../../Markdown/ABAQUS_USB_2016/KEYWORD/KEYWORD.md) | [`analysis3_material_keyword_ufc_fields.csv`](../../../REPORTS/analysis3_material_keyword_ufc_fields.csv) |
| **用户子程序**（UMAT / VUMAT / CREEP …） | USB 2016 摘录 README **未单列**独立 `USER.pdf`；安装介质常见为 **User Subroutines Reference** 单册（文件名因版本/语言而异，如含 *Subroutine* 的 PDF）。若贵司拷贝为 `ABAQUS手册/USER.pdf`，与本行并列即可。 | 子程序章节正文分散在 Analysis 各卷 MD 中；**节标题索引**：[`ABAQUS_手册_节小节标题与路径清单.md`](../../../../Markdown/ABAQUS_USB_2016/authority/ABAQUS_手册_节小节标题与路径清单.md)（检索「User subroutine」「UMAT」） | 本页 **§4**；实现 `MD_MAT_UMAT_Intf` |

**KEYWORD 手册页**：本页 **§3.7** 与下列章级表中的 **「KEYWORD 手册页（CSV）」** 列，均来自 CSV 列 **`manual_pages`**（脚本自 **KEYWORD.pdf** 抽取的物理页列表，逗号分隔）。与纸质页对不齐时，以贵司手边 **Input Reference** 纸书目录为准改 CSV 后重导。

**换 Abaqus 版本时**：更新 `ABAQUS手册/` 下 PDF、重跑 `UFC/tools/extract_analysis3_materials_ufc_mapping.py` 刷新 `REPORTS/*.csv` / `*.json`，再同步本页 **§3.7**。

**单仓克隆**：若工作区**仅有** `UFC/` 子仓库，不存在与 mono-repo 根同级的 **`Markdown/`**、**`ABAQUS手册/`**，则上表 **`../../../../Markdown/...`** 相对链接会 **404**。请将 Abaqus 手册正文以 **git submodule**、**`UFC/docs/` 下 vendor 镜像**（如 `docs/vendor/ABAQUS_USB_2016/`）、或**内部文档服务器**挂入后，在本页 **§1** 将 Markdown 列链接改为你们约定的**手册根路径**（或在组织级 `README` / `docs/README` 中统一写死「手册根 → 相对路径」并在此互链）。

---

## 2. 列约定（总表）

| 列名 | 含义 |
|------|------|
| **Part V §** | Analysis 手册 Part V **章 / 节主题**（与 `ANALYSIS_3` Part I TOC 一致） |
| **KEYWORD（主）** | Input Reference **材料块内**主行为关键字 |
| **KEYWORD 手册页（CSV）** | `analysis3_material_keyword_ufc_fields.csv` 的 **`manual_pages`**；无 CSV 行时填 **—** |
| **KEYWORD（从属 / 常伴）** | 同卡常见伴随关键字 |
| **USER** | 用户子程序手册中与该行强相关的接口 |
| **`mat_family`** | UFC **1..11**；**NULL** = 跨族元数据 |
| **辅 Desc（文档规范名）** | **`MD_Mat_<Segment>_Desc`** 形态 |
| **辅 Desc（源码 `PUBLIC`）** | 当前 Fortran **符号** |

**主 Desc**：**`MD_Mat_Desc`**（文档）= **`MD_Mat_Desc`**（`MD_Mat_Def.f90`）。**四型 + Args**：见 `L4_PH/Material/CONTRACT.md` 与 `ANALYSIS_3` Part II §2。

---

## 3. 章 ↔ KEYWORD ↔ USER ↔ `mat_family` ↔ 辅 Desc（**双列** + **手册页**）

### 3.1 第 21 章 — Materials: Introduction（跨族元数据）

| Part V § | KEYWORD（主） | KEYWORD 手册页（CSV） | KEYWORD（从属 / 常伴） | USER | `mat_family` | 辅 Desc（文档规范名） | 辅 Desc（源码 `PUBLIC`） |
|----------|---------------|------------------------|------------------------|------|----------------|-------------------------|---------------------------|
| 21.x 材料库 / 数据定义 / 组合 | `*MATERIAL` | —（CSV 未列；页码从 KEYWORD.md / 纸书 *MATERIAL 补） | `*DENSITY`、`*DEPVAR` | `*USER MATERIAL` → §4 | **NULL** | — | — |
| 21.x 密度 | `*DENSITY` | 51, 61, 62, 247, 300, 413, 426, 574–583, 587, 637–641, 699 | 与弹/塑/超弹组合约束见手册 | — | **NULL** | — | — |

### 3.2 第 22 章 — Elastic mechanical properties

| Part V § | KEYWORD（主） | KEYWORD 手册页（CSV） | KEYWORD（从属 / 常伴） | USER | `mat_family` | 辅 Desc（文档规范名） | 辅 Desc（源码 `PUBLIC`） |
|----------|---------------|------------------------|------------------------|------|----------------|-------------------------|---------------------------|
| 22.x 线弹性 | `*ELASTIC` | 45, 51–82, 87, 321–322, 571, 589–590 | `TYPE=`、数据行、温度/场 | — | **1** | 线弹 Typed | `MD_Mat_Elas_*`、`MD_Mat_Desc` |
| 22.x Hypoelasticity | `*HYPOELASTIC` | 52, 101–102 | 数据行 | — | **1** | hypo Typed | `Elas/` hypo stem |
| 22.x Hyperelasticity / foam | `*HYPERELASTIC` | 51, 105–118, 155, 204–207, 489 | `TYPE=`、应变能系数 | **UMAT** | **4** | 超弹 Typed | `MD_MAT_MODEL_HYP` 等 |
| 22.x Hyperelasticity / foam | `*HYPERFOAM` | 51, 131–136, 167 | 同左 | **UMAT** | **4** | 同左 | `HyperElas/` |
| 22.x Linear viscoelasticity / PRF | `*VISCOELASTIC` | 52, 54, 143, 175–199, 207, 213–214 | Prony / 频域；与超弹组合 | **UMAT** | **5**（±**4**） | `MD_Mat_Visco_*` | `MD_MAT_MODEL_VISC` |
| 22.x / 23.x 织物 | `*FABRIC` | 51, 413, 415–416, 426–427, 429 | 与密度、弹组合 | — | **3 / 8** | 织物 Typed | `Geo/`、`Composite/` |

### 3.3 第 23 章 — Inelastic mechanical properties

| Part V § | KEYWORD（主） | KEYWORD 手册页（CSV） | KEYWORD（从属 / 常伴） | USER | `mat_family` | 辅 Desc（文档规范名） | 辅 Desc（源码 `PUBLIC`） |
|----------|---------------|------------------------|------------------------|------|----------------|-------------------------|---------------------------|
| 23.x 金属塑 | `*PLASTIC` | 53–54, 155, 207, 241–247, 249, 257, 259–260, 262, 266, 288–289, 292 | 硬化表、`HARDENING=` | **UMAT** | **2** | `MD_Pls_*` | `MD_MAT_CATEGORY_PL` |
| 23.x 蠕变 | `*CREEP` | 54, 269–276, 281, 288, 290, 327–328 | 与塑、温度、时间 | **CREEP** | **6** | Creep Typed | `MD_MAT_CATEGORY_CR` |
| 23.x 岩土 | `*DRUCKER PRAGER` | 53–54, 266, 337, 341–342, 345–347, 353, 362–363, 590 | Cap 等 | **UMAT** | **3** | **`MD_Mat_DP_Desc`** | **`MD_Mat_DP_Desc`** |
| 23.x 岩土 | `*MOHR COULOMB` | 53, 379, 383, 385 | 与塑组合 | **UMAT** | **3** | **`MD_Mat_Mohr_Coulomb_Desc`** | **`MohrCoulomb_MatDesc`** |
| 23.x 混凝土 | `*CONCRETE` | 53, 443–449, 467, 474, 476–480 | 损伤/塑交叉 | **UMAT** | **7**（+**2**） | `Damage/`+`Plast/` | `MD_MAT_CATEGORY_DA` |

### 3.4 第 24 章 — Progressive damage and failure

| Part V § | KEYWORD（主） | KEYWORD 手册页（CSV） | KEYWORD（从属 / 常伴） | USER | `mat_family` | 辅 Desc（文档规范名） | 辅 Desc（源码 `PUBLIC`） |
|----------|---------------|------------------------|------------------------|------|----------------|-------------------------|---------------------------|
| 24.x 损伤（**本 CSV 未单独列** `*DAMAGE INITIATION` 等） | — | 见 KEYWORD.md / 扩展 `PRIORITY_KEYWORDS` | 与 `*PLASTIC`、层合交叉 | **UMAT** | **7** | `MD_Dmg_*` | `Damage/` |

### 3.5 第 25 章 — Hydrodynamic properties

| Part V § | KEYWORD（主） | KEYWORD 手册页（CSV） | KEYWORD（从属 / 常伴） | USER | `mat_family` | 辅 Desc（文档规范名） | 辅 Desc（源码 `PUBLIC`） |
|----------|---------------|------------------------|------------------------|------|----------------|-------------------------|---------------------------|
| 25.x EOS | `*EOS` | 51, 53, 306, 571–591, 619 | 显式路径 | **VUMAT** 等 | **11** | User bundle | `MD_MAT_MODEL_USER` |

### 3.6 第 26 章 — Other material properties

| Part V § | KEYWORD（主） | KEYWORD 手册页（CSV） | KEYWORD（从属 / 常伴） | USER | `mat_family` | 辅 Desc（文档规范名） | 辅 Desc（源码 `PUBLIC`） |
|----------|---------------|------------------------|------------------------|------|----------------|-------------------------|---------------------------|
| 26.x 热学 | `*CONDUCTIVITY` | 56, 629–630 | 耦合步 | — | **9** | `Thermal/` | `MD_MAT_CATEGORY_EL` + 热标志 |
| 26.x 热学 | `*SPECIFIC HEAT` | 56, 247, 300, 584, 587, 631–632 | 同左 | — | **9** | 同左 | — |
| 26.x 热学 | `*EXPANSION` | 51, 413, 605–617 | 与弹耦合 | — | **9** | 同左 | `MD_Mat_Desc` + thermal |
| 26.x 声学 | `*ACOUSTIC MEDIUM` 等 | —（CSV 未列；页码从 KEYWORD.md 补） | — | — | **10** | `MD_Mat_Acous_*` | `MD_Mat_AcousticProps` 等 |
| 26.x 用户材料 | `*USER MATERIAL` | 51, 56, 697–701, 705 | `*DEPVAR`、`CONSTANTS` | **UMAT / VUMAT** | **11** | **`MD_Mat_UMAT_Intf`** | **`MD_MAT_UMAT_Intf`** |

---

## 3.7 CSV 行一一对照（`abaqus_keyword` + `manual_pages`）

**机器真源**：[`analysis3_material_keyword_ufc_fields.csv`](../../../REPORTS/analysis3_material_keyword_ufc_fields.csv)（列与脚本同步）。下表 **`manual_pages`** 为原文逗号分隔；**Part V（推断）** 为便于检索的人工归类。

| `abaqus_keyword` | `manual_pages`（KEYWORD） | Part V（推断） | USER（典型） | `mat_family` | `ufc_host_type`（CSV） | 辅 Desc（文档） | 辅 Desc（源码 / `code_ref`） |
|------------------|---------------------------|----------------|--------------|----------------|-------------------------|-----------------|--------------------------------|
| `*CONCRETE` | 53,443,446,447,448,449,467,474,476,477,478,479,480 | 23 / 24 | UMAT | 7（+2） | `MD_Mat_Desc` | `Damage/`+`Plast/` | `MD_MAT_CATEGORY_DA` |
| `*CONDUCTIVITY` | 56,629,630 | 26 | — | 9 | `MD_Mat_Desc` | `Thermal/` | `MD_MAT_CATEGORY_EL` + 耦合标志 |
| `*CREEP` | 54,269,270,272,273,274,275,276,281,288,290,327,328 | 23 | CREEP | 6 | `MD_Mat_Desc` | `Creep/` Typed | `MD_MAT_CATEGORY_CR` |
| `*DENSITY` | 51,61,62,247,300,413,426,574,575,576,580,581,583,587,637,638,640,641,699 | 21 | — | NULL | `MD_Mat_Desc` | — | `PUBLIC MD_Mat_Desc` |
| `*DRUCKER PRAGER` | 53,54,266,337,341,342,345,346,347,353,362,363,590 | 23 | UMAT | 3 | `MD_Mat_Desc` + `MD_Mat_DP_Desc` | `MD_Mat_DP_Desc` | `MD_Mat_DP_Desc` |
| `*ELASTIC` | 45,51,52,73,74,75,76,77,78,79,80,81,82,87,321,322,571,589,590 | 22 | — | 1 | `MD_Mat_Desc` | 线弹 Typed | `MD_Mat_Desc` + `Elas/*` |
| `*EOS` | 51,53,306,571,574,575,576,580,581,582,583,584,585,587,589,590,591,619 | 25 | VUMAT 等 | 11 | `MD_Mat_Desc` / User | `User/` | `MD_MAT_MODEL_USER` |
| `*EXPANSION` | 51,413,605,606,607,608,609,610,613,614,615,616,617 | 26 | — | 9 | `MD_Mat_Desc` | `Thermal/` + 弹耦合 | `MD_Mat_Desc` + thermal |
| `*FABRIC` | 51,413,415,416,426,427,429 | 23 | — | 3/8 | `MD_Mat_Desc` | 织物 | `GEOMAT` / `COMPOSITE` |
| `*HYPERELASTIC` | 51,105,113,114,115,116,118,155,204,207,489 | 22 | UMAT | 4 | `MD_Mat_Desc` | `HyperElas/` | `MD_MAT_MODEL_HYP` |
| `*HYPERFOAM` | 51,131,135,136,167 | 22 | UMAT | 4 | `MD_Mat_Desc` | `HyperElas/` | `MD_MAT_MODEL_HYP` |
| `*HYPOELASTIC` | 52,101,102 | 22 | — | 1 | `MD_Mat_Desc` | `Elas/` hypo | `MD_MAT_CATEGORY_EL` |
| `*MOHR COULOMB` | 53,379,383,385 | 23 | UMAT | 3 | `MD_Mat_Desc` + `MD_Mat_Mohr_Coulomb_Desc` | `MD_Mat_Mohr_Coulomb_Desc` | `MohrCoulomb_MatDesc` |
| `*PLASTIC` | 53,54,155,207,241,242,243,244,245,246,247,249,257,259,260,262,266,288,289,292 | 23 | UMAT | 2 | `MD_Mat_Desc` | `Plast/*` | `MD_Mat_Desc` / `MD_MAT_CATEGORY_PL` |
| `*SPECIFIC HEAT` | 56,247,300,584,587,631,632 | 26 | — | 9 | `MD_Mat_Desc` | `Thermal/` | — |
| `*USER MATERIAL` | 51,56,697,699,700,701,705 | 26 | UMAT/VUMAT | 11 | `MD_Mat_Desc` + `MD_Mat_UMAT_Intf` | `MD_Mat_UMAT_Intf` | `MD_MAT_UMAT_Intf`, MatCtxLegacy |
| `*VISCOELASTIC` | 52,54,143,175,182,183,184,185,193,196,197,198,199,207,213,214 | 22 | UMAT | 5 | `MD_Mat_Desc` | `Viscoelas/` | `MD_MAT_MODEL_VISC` |

---

## 4. USER 子程序总索引（与材料块强相关）

| USER 手册条目 | 角色 | KEYWORD 入口 | `mat_family` | UFC 锚 |
|---------------|------|----------------|----------------|--------|
| **UMAT** | 隐式材料点本构 | `*USER MATERIAL` | **11** | `MD_MAT_UMAT_Intf`；L4 `PH_UMAT_*`、`PH_Mat_*_*_Arg` |
| **VUMAT** | 显式材料点 | `*USER MATERIAL` / 显式 deck | **11** | `RT_SolverType` / `ufc-solver-router` |
| **CREEP**（若使用） | 用户蠕变律 | `*CREEP` | **6** | `Creep/` 与用户钩子合同 |
| **USDFLD / UEXPAN / …** | 场、热膨胀等插件 | 各关键字 `USER` 选项 | 依宿主 | KeyWord / 耦合域合同 |

**UEL / VUEL**：单元接口；本页不展开。

---

## 5. 与「整模型 L0–L5」的边界

- **本页**：`*MATERIAL` 块内关键字 + Populate → 主/辅 Desc + L4 四型 + `Args`（材料子 AST：**K0–K5**，见 [`Material_11Families_Subfamily_Directory.md`](Material_11Families_Subfamily_Directory.md)）。  
- **整模型**：Part / Mesh / Section / Interaction / … 另图。

---

## 6. 维护流程

1. **改 KEYWORD 页码**：改脚本数据源或 CSV → 同步 **§3.7** 与 §3.2–3.6 的「手册页」列。  
2. **新增 `abaqus_keyword` 行**：`PRIORITY_KEYWORDS` / `KEYWORD_UFC_FIELDMAP` → 重导 CSV → **§3.7** 增行。  
3. **辅 Desc 双列**：以 `ANALYSIS_3` §0 与 `MD_Mat_Def.f90` 为准更新。

---

## 7. 相关链接

- [`Material_Complete_DataStructure_Index.md`](Material_Complete_DataStructure_Index.md) — L3 `Material/` 真源索引与 `MD_Mat_Desc` / `MD_Mat_Desc` 易混说明  
- [`Material_11Families_Subfamily_Directory.md`](Material_11Families_Subfamily_Directory.md)  
- [`ANALYSIS_3_Materials_PartV_Manual.md`](../Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md)  
- [`L3_MD/Material/CONTRACT.md`](../../../ufc_core/L3_MD/Material/CONTRACT.md)、[`L4_PH/Material/CONTRACT.md`](../../../ufc_core/L4_PH/Material/CONTRACT.md)  
- [`Markdown/ABAQUS_USB_2016/README.md`](../../../../Markdown/ABAQUS_USB_2016/README.md)

---

*§3.7 与 CSV **一一对应**；§3.1–3.6 为章级导读（含合并行）。纸质页以贵司 KEYWORD 纸书为准校核 `manual_pages`。*
