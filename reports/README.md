# UFC Reports Index

UFC 仓库报告文档目录。报告与 `docs/`（规范/指南类）区分：报告侧重一次性/阶段性产出。

**与 `docs/` 去重与真源裁决**：见 [`SSOT_AND_DEDUP_POLICY.md`](SSOT_AND_DEDUP_POLICY.md)（含 `data/` 证据包约定）。

**Domain Procedure Registry 漂移（机器）**：[`DESIGN_GENERATED_DRIFT.md`](DESIGN_GENERATED_DRIFT.md) — 默认由 `python UFC/tools/domain_procedure_registry_align.py` 写入本目录；对照 `docs/03_Domain_Pillars/DomainProcedureRegistry/design/**/manifest.json`、`ufc_core/`、`docs/03_Domain_Pillars/DomainProcedureRegistry/generated/`；可用 `--out` 改路径；CI 可对 exit code 门禁。

**Code_Templates / 开发者指南 / 域柱 Fortran 围栏真源扫描（机器）**：[`code_templates_ssot_scan.md`](code_templates_ssot_scan.md) — 由 `python UFC/tools/scan_code_templates_ssot.py` 或 `python UFC/ufc_harness/run_harness.py code-templates-ssot` 写入；默认扫描 `docs/02_Developer_Guide/Code_Templates/`（`.f90`+`.md`）、`docs/02_Developer_Guide/` 下其余路径（`.md`，**排除** `Code_Templates/` 以免重复）、`docs/03_Domain_Pillars/`（`.md`）；亦由 `plan-checks` 串联执行。

## 目录结构

```
REPORTS/
├── data/          ← 数据文件（.json / .csv 等）；索引见 data/README.md
├── archive/       ← 已结题 sprint / 一次性报告；**索引见 archive/README.md**
└── *.md           ← 活性报告（以下各节表格）
```

**stub（指针页）**：保持 **与历史相同的 `REPORTS/<文件名>.md` 路径**（全库外链、CONTRACT 引用不必改），但根文件只保留 **数行至一页** 的说明表（报告 ID、全文链接、真源入口）；**长文正文**在 **`archive/<同名>.md`**。目的：**减轻根目录体量**；代价：读长文需多点一次 archive 链接。

**活性 vs 冷数据**：根目录 Markdown 默认视为仍被互链或任务引用；仅阶段性、已无人维护且与当前代码无对账义务的文档请迁入 **`archive/`** 并在 [`archive/README.md`](archive/README.md) 登记一行说明。

---

## 1. 过程算法与四型

| 文件 | 说明 |
|------|------|
| `Procedure_Algorithm_L3L4L5_synthesis.md` | 八域过程算法全景合订：**根 stub** → [全文](archive/Procedure_Algorithm_L3L4L5_synthesis.md) |
| `Material_Procedure_Algorithm.md` | 材料域过程算法：**根 stub** → [全文](archive/Material_Procedure_Algorithm.md) |
| `Element_Procedure_Algorithm.md` | 单元域过程算法：**根 stub** → [全文](archive/Element_Procedure_Algorithm.md) |
| `LoadBC_Procedure_Algorithm.md` | LoadBC 域过程算法：**根 stub** → [全文](archive/LoadBC_Procedure_Algorithm.md) |
| `Contact_Procedure_Algorithm.md` | Contact 域过程算法：**根 stub** → [全文](archive/Contact_Procedure_Algorithm.md) |
| `Output_Procedure_Algorithm.md` | Output 域过程算法：**根 stub** → [全文](archive/Output_Procedure_Algorithm.md) |
| `WriteBack_Procedure_Algorithm.md` | WriteBack 域过程算法：**根 stub** → [全文](archive/WriteBack_Procedure_Algorithm.md) |
| `Section_Procedure_Algorithm.md` | Section 域过程算法：**根 stub** → [全文](archive/Section_Procedure_Algorithm.md) |
| `Analysis_Procedure_Algorithm.md` | Analysis 域过程算法：**根 stub** → [全文](archive/Analysis_Procedure_Algorithm.md) |

## 2. 域四型合成本

以下合订在 **`archive/`** 保留全文；`REPORTS/` 根目录仅保留 **stub**（路径不变，便于 CONTRACT 与互链）。报告 ID 见 `REPORT_Naming_Quad_OnePager_FiveScenes.md` §1。

**顶层设计**

| 文件 | 说明 |
|------|------|
| `OnePager_FourKind_MasterAux_Nesting.md` | 四型主辅嵌套 OnePager |
| `FourKind_MasterAux_Nesting_Design_Spec.md` | 四型主辅嵌套设计规范：**根 stub** → [全文](archive/FourKind_MasterAux_Nesting_Design_Spec.md) |
| `Pillar_L3L4L5_CrossLayer_Design_Template.md` | L3/L4/L5 跨层柱设计模板：**根 stub** → [全文](archive/Pillar_L3L4L5_CrossLayer_Design_Template.md) |

**L3/L4/L5 域级四型合成（8 域）**

| 文件 | 说明 |
|------|------|
| `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md` | 材料域 UMAT 合订：**根 stub** → [全文](archive/Material_L3L4L5_four_type_UMAT_discussion_synthesis.md) |
| `Element_L3L4L5_four_type_UEL_discussion_synthesis.md` | 单元域 UEL 合订：**根 stub** → [全文](archive/Element_L3L4L5_four_type_UEL_discussion_synthesis.md) |
| `LoadBC_L3L4L5_four_type_synthesis.md` | LoadBC（P4）四型合订：**根 stub** → [全文](archive/LoadBC_L3L4L5_four_type_synthesis.md) |
| `Contact_L3L4L5_four_type_synthesis.md` | 接触（P3）四型合订：**根 stub** → [全文](archive/Contact_L3L4L5_four_type_synthesis.md) |
| `Output_L3L4L5_four_type_synthesis.md` | 输出（P5）四型合订：**根 stub** → [全文](archive/Output_L3L4L5_four_type_synthesis.md) |
| `WriteBack_L3L4L5_four_type_synthesis.md` | 写回（P6）四型合订：**根 stub** → [全文](archive/WriteBack_L3L4L5_four_type_synthesis.md) |
| `Section_L3L4L5_four_type_synthesis.md` | 截面（M–E–S）四型合订：**根 stub** → [全文](archive/Section_L3L4L5_four_type_synthesis.md) |
| `Analysis_L3L4L5_four_type_synthesis.md` | 分析域四型合订：**根 stub** → [全文](archive/Analysis_L3L4L5_four_type_synthesis.md) |

## 3. 域清册

| 文件 | 说明 |
|------|------|
| `Master_Domain_Inventory_Index.md` | 主域清册索引 |
| `Material_Domain_Inventory.md` | 材料域清册 |
| `Element_Domain_Inventory.md` | 单元域清册 |
| `LoadBC_Domain_Inventory.md` | LoadBC 域清册 |
| `Contact_Domain_Inventory.md` | Contact 域清册 |
| `Output_Domain_Inventory.md` | Output 域清册 |
| `WriteBack_Domain_Inventory.md` | WriteBack 域清册 |
| `Section_Domain_Inventory.md` | Section 域清册 |
| `Analysis_Domain_Inventory.md` | Analysis 域清册 |

## 4. 命名与规范

| 文件 | 说明 |
|------|------|
| `REPORT_Naming_Unified_Spec.md` | 统一命名规范报告（**日常优先**）：**根 stub** → [全文](archive/REPORT_Naming_Unified_Spec.md) |
| `REPORT_Naming_Quad_OnePager_FiveScenes.md` | 命名四象限 OnePager：**报告 ID 总表 + §6 PDF 锚点**仍被多域合订互链；细则以 Unified Spec 为准 |
| `Model_Domain_FourType_Procedure_Naming_Spec.md` | Model 域四型过程命名规范 |
| `Domain_Compression_Canon.md` | 域压缩 Canon — 域缩写与命名对齐基准 |

## 5. 手册对齐

| 文件 | 说明 |
|------|------|
| `Abaqus_Analysis_Manual_to_UFC_Architecture_Mapping.md` | ABAQUS 分析手册 → UFC 架构映射 |
| `Abaqus_UserSubroutine_UFC_Map.md` | ABAQUS 用户子程序 UFC 映射 |
| `Keyword_to_UFC_Architecture_Mapping.md` | 关键字 → UFC 架构映射 |
| `Keyword_Parameter_Catalog.md` | 关键字参数目录（Markdown 版） |
| `Manual_UFC_domain_subroutine_mapping_guide.md` | Manual（Abaqus PDF）抽取与 UFC 全层-全域对照说明 |
| `usub_ufc_alignment.md` | ABAQUS U* 子程序 ↔ UFC 对齐表（自动生成） |

## 6. 架构与蓝图

| 文件 | 说明 |
|------|------|
| `UFC_L3L4L5_CrossLayer_DataFlow_v1.md` | L3/L4/L5 跨层数据流 v1：**根 stub** → [全文](archive/UFC_L3L4L5_CrossLayer_DataFlow_v1.md) |
| `UFC_L3L4L5_二元重构蓝图规范_v1.0.md` | L3/L4/L5 二元重构蓝图 v1.0：**根 stub** → [全文](archive/UFC_L3L4L5_二元重构蓝图规范_v1.0.md) |
| `UFC_SevenLayer_Workflow_Guide.md` | 七层工作流实操指南：**根 stub** → [全文](archive/UFC_SevenLayer_Workflow_Guide.md) |
| `AI_SevenLayer_Stack_UFC_Mechanism_and_Optimization.md` | AI 七层栈（Prompt→Context→Skills→MCP→Agent→Harness→Loop）完整机制与优化方案 |

## 7. 材料域专题

| 文件 | 说明 |
|------|------|
| `Material_P0_FourType_BinaryMap.md` | 材料域 P0 映射：四 TYPE、二元切分、L5 链 |
| `MT0_Material_Leaf41_COMPAT_DRIFT.md` | MT-0.2/MT-0.3 — Material Leaf41 vs `GROUP_MAT_COMPAT` & ID 漂移 |
| `UMAT_parameter_to_UFC_types_and_scale_taxonomy.md` | UMAT 参数 ↔ UFC 类型 · 尺度与后缀（短版索引） |

**2026-05 材料域二元改造 sprint**（审计 / 日志 / 推广指南）已迁入 **`archive/`**，见 [`archive/README.md`](archive/README.md)。

## 8. 索引与术语

| 文件 | 说明 |
|------|------|
| `Base_Boundary_LoadBC_FourType_Algorithm_Unified_Index.md` | Base/Boundary (L3)、LoadBC 域四型与过程文档统一索引 |
| `Procedure_Pointer_Inventory.md` | 过程指针（Procedure Pointer）全景清单 |
| `TBP_Unification_Phases_and_LoadBC_Lexicon.md` | TBP 实现名分阶段治理 + LoadBC 域命名字汇 |

---

## 子目录

### data/ — 数据文件

非报告的文件，作为报告生成时的输入或中间产物。索引与体积策略见 [`data/README.md`](data/README.md)。

| 文件 | 说明 |
|------|------|
| `analysis3_materials_ufc_mapping.json` | 材料 UFC 字段映射数据 |
| `analysis3_material_keyword_ufc_fields.csv` | 材料关键字 UFC 字段对应表 |
| `manual_extract_raw.json` | ABAQUS Manual 原始抽取结果 |
| `material_public_types_index.json` | 材料域公开 TYPE 索引 |
| `material_pillar_inventory_baseline_2026-05-02.csv` | Material Pillar 清册基线 |
| `user_subroutine_keyword_pages_ABAQUS_USER_6_14.json` | 用户子程序关键字页索引 |
| `usub_ufc_alignment.csv` | U* 子程序 ↔ UFC 对齐表（CSV 版） |

若本地工作区另有生成物（如 `.docx`、测试用 `.png`、重命名清单），**不写入本表**；纳入 `data/` 时同步更新 [`data/README.md`](data/README.md)。

### archive/ — 已归档

冷数据与 sprint 全文索引见 **[`archive/README.md`](archive/README.md)**（含 Material Pillar 收尾、L4 gap 决策、材料二元改造套件与 handoff）。

---

## 与 `docs/` 的分工

- `docs/`：规范和指南（长期维护、作为 SSOT）
- `REPORTS/`：分析报告和阶段性产出（读后归档或废除）
- 两者选题重叠时的裁决与 `data/` 约定：[`SSOT_AND_DEDUP_POLICY.md`](SSOT_AND_DEDUP_POLICY.md)
