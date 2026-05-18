# Manual（Abaqus PDF）抽取与 UFC 全层-全域对照说明

本文档依据仓库规则 **`.cursor/rules/pdf-processing.mdc`**（pdfplumber 用于正文/表格、PyMuPDF 用于目录与快速翻页），结合已运行的抽取脚本产物 **`UFC/REPORTS/manual_extract_raw.json`**，说明：**能否**用 Manual 来“完善全层-全域目录/子目录与域级功能子程序清单”，以及**二元结构 / 命名 / 接口签名**在 **Abaqus 手册** 与 **UFC 内核** 之间如何对齐。

---

## 1. 结论：可以，但必须分清两套“目录”语义

| 维度 | Manual（Abaqus PDF） | UFC（`ufc_core`） |
|------|----------------------|-------------------|
| **目录** | 产品文档章节（Volume / Part / Section）、关键字 `*STEP` 等 | 物理目录：`L1_IF` … `L6_AP` + 域文件夹（`Material/`、`Assembly/`…） |
| **功能子程序** | Fortran **用户子程序**（`UMAT`、`UEL`…）+ 固定形参表 | 层缀模块过程：`PH_Mat_*`、`RT_*_Proc`、`MD_*` 等 + **SIO 五参**演进 |
| **二元结构** | 多为 **输入量 / 输出量**（形参表里 `STRESS`、`STATEV`…） | **四类 TYPE**：`Desc` / `State` / `Algo` / `Ctx` + **单一 `*_Arg`**（Principle #14） |
| **命名** | Abaqus 固定子程序名（`UMAT`） | `{Layer}_{Domain}_{Feature}_{Role}.f90` + 过程名动词族（见 `ufc-naming.mdc`） |

因此：**Manual 适合作为“产品侧功能清单 + 接口真值来源”**；**UFC 侧清单应以 `ufc_core` 扫描/域 CONTRACT 为准**，再用 Manual 做**交叉索引**（尤其是用户子程序与 `*MATERIAL` / `*STEP` 章节）。

---

## 2. 已落地的抽取流水线（可重复执行）

- **规则**：`UFC/.cursor/rules/pdf-processing.mdc` — 表格/正文优先 pdfplumber；大 PDF 避免全量扫描超时，目录与首页用 **PyMuPDF**。
- **脚本**：`UFC/tools/extract_manual_outlines.py`  
  - 输出：`UFC/REPORTS/manual_extract_raw.json`（每本 PDF：`fitz.toc` + `fitz.front_text_joined` + 小文件 `pdfplumber_sample`）。
- **当前 Manual 卷册**（`UFC/Manual/`）：
  - `THEORY.pdf` — 理论（本构、单元公式、接触理论等）→ 主要映射 **L2_NM**（算法/数值）+ **L4_PH**（物理核）。
  - `ANALYSIS_1.pdf` … `ANALYSIS_5.pdf` — Analysis User’s Guide 分卷 → **L3_MD**（模型/关键字/步）、**L5_RT**（求解/步进/装配）、**L6_AP**（作业/前后处理叙事）。
  - `USER.pdf` — User Subroutines Reference（6.14）→ **扩展点 / 适配器**（与 `PH_*_UMAT` / `Legacy_Adapters_Reference` 对齐）。

---

## 3. Manual 章节层级 → UFC 层级/域（建议映射）

以下为**导航用映射**，不是自动代码生成；细化到“每个子程序”需再结合 `UFC/docs` 与域 `CONTRACT.md`。

| Manual 典型章节 | UFC 层 | UFC 域（示例） |
|-----------------|--------|----------------|
| 材料本构理论（Theory 4.x） | L4_PH（主）/ L2_NM（辅） | `L4_PH/Material/`、`L2_NM/Solver` |
| 单元库、插值、沙漏（Theory / Analysis IV） | L4_PH | `L4_PH/Element/` |
| 接触、约束（Analysis V / Theory） | L3_MD + L4_PH + L5_RT | `L3_MD/Interaction`、`L4_PH/Contact`、`L5_RT/Cont` |
| 分析步、非线性求解、增量控制（Analysis II/III） | L5_RT（主）/ L3_MD（步描述） | `L5_RT/Solver`、`L5_RT/Step`、`L3_MD/Analysis` |
| 关键字、模型树（Analysis I） | L3_MD | `L3_MD/**/KW`、`Material`、`Mesh` |
| 用户子程序参考（USER.pdf） | L4_PH + `ufc_harness`/适配层 | `PH_Mat_*`、`PH_UMAT_Def`、文档模板 `docs/02_Developer_Guide/.../Adapters` |

---

## 4. “功能子程序”在手册与 UFC 中的含义

### 4.1 手册侧（Abaqus/Standard 节选，来自 `USER.pdf` 首页目录抽取）

下列为 **Abaqus 用户子程序名称**（产品 API），**不是** UFC 模块名；UFC 中对应 **适配/桥接/物理核** 多条路径。

| 子程序 | 手册职责（摘录） | UFC 建议落点（概念） |
|--------|------------------|----------------------|
| `UMAT` | 定义力学材料行为 | `L4_PH/Material/` + UMAT 适配（`PH_Mat_*`、`PH_UMAT_*`） |
| `UMATHT` | 定义材料热行为 | `L4_PH/Material/` + 热-力耦合路径 |
| `UEL` / `UELMAT` / `VUEL` | 用户单元 | `L4_PH/Element/` + UEL 适配 |
| `DLOAD` / `VDLOAD` | 非均布载荷 | `L5_RT/LoadBC` / `L3_MD/Load` |
| `DISP` | 边界运动学 | `L5_RT/LoadBC`、`L3_MD/BC` |
| `FRIC` / `UINTER` | 接触本构 / 面相互作用 | `L4_PH/Contact`、`L3_MD/Interaction` |
| `CREEP` | 蠕变 | `L4_PH/Material/` 或 `L3_MD/.../Creep` |
| `USDFLD` / `UFIELD` | 场变量 | `L3_MD/Field` / `L4_PH/Field` |

完整列表以 `USER.pdf` 正文为准；JSON 中 `USER.pdf` → `fitz.front_text_joined` 已含多页 **CONTENTS** 可继续用脚本解析为 CSV。

### 4.2 UFC 侧（示例：L5 Assembly 域 `_Proc` 清单）

`UFC/ufc_core/L5_RT/Assembly/RT_Asm_Proc.f90` 头注释列举的**域级过程**（与 Manual 无同名关系，属于运行时编排）：

- `RT_Asm_Init`、`RT_Asm_BuildPattern`、`RT_Asm_AssembleK`、`RT_Asm_AssembleM`、`RT_Asm_AssembleF`、`RT_Asm_ApplyConstraints`、`RT_Asm_ComputeResidual`、`RT_Asm_Finalize`

当前实现仍使用 **legacy SIO**：`(desc, state, algo, ctx, inp, out)` 与成对 `*_In`/`*_Out` TYPE（见同文件类型定义）；**新建域**应按 `ufc-structured-io` 迁到 **五参 + 单一 `args`**。

---

## 5. “二元结构”对照（你关心的维度）

### 5.1 Abaqus 用户子程序（手册）

- **二元**：形参表中 **输入**（如 `STRAN`、`DSTRAN`、`PROPS`）与 **输出/更新**（如 `STRESS`、`DDSDDE`、`STATEV`）由 **参数位置 + 约定** 表达。
- **签名**：固定 `SUBROUTINE UMAT(...)` 名 + 长参数表（产品 ABI）。

### 5.2 UFC（Principle #14 / `ufc-structured-io`）

- **四型分离**：`Desc`、`State`、`Algo`、`Ctx` —— 角色与生命周期分离。
- **IO 单包**：`TYPE(xxx_Arg)` 内用注释标 `[IN]` / `[OUT]` / `[INOUT]`，**禁止**把四类再嵌进 `Arg`。
- **五参典型**：`SUBROUTINE xxx(desc, state, algo, ctx, args)`，`args` 必含 `ErrorStatusType :: status`（规则 R-04）。
- **六参**：在四型后加 `RT_Com_Base_Ctx`，第六仍是唯一 `args`。

**对应关系（概念）**：手册的 “inp/out 参数表” ↔ UFC 的 “四型 + `*_Arg`”；不是逐字段一一相等，而是 **Populate / Step / IP 调用** 上的一层打包与拆分。

---

## 6. 命名与接口签名（落地检查）

- **命名**：以 `UFC/docs/05_Project_Planning/PPLAN/04_技术标准/UFC_命名规范_v3.0.md` 与 `.cursor/rules/ufc-naming.mdc` 为准；**不得**把 `UMAT` 直接当作 UFC 模块名。
- **接口**：新建 `_Proc` / `_Core` 以 **`UFC/docs/templates`** 与 `RT_Solv_Proc.f90`、`RT_LoadBC_Proc.f90` 等 **SIO v2** 为基准；存量 `inp/out` 见技能 **R-01b（遗留）**。

---

## 7. 自动生成：U 子程序 ↔ UFC 文件 / 模块 / 五参示例

已提供脚本（以 `tools/gen_umat_adapter.py` 的 `ALL_SUBROUTINES` 为主数据源）：

```text
python tools/build_usub_ufc_alignment_table.py
```

产物：

- `UFC/REPORTS/usub_ufc_alignment.csv`
- `UFC/REPORTS/usub_ufc_alignment.md`

列含：`legacy_adapter_path`、`target_module`、`target_core_api`、`ufc_core_core_file`（是否在 `ufc_core` 命中 API）、`sio_five_param_example`（同域启发式五参示例）等。

## 8. 其它可选下一步

1. **手册**：在 `tools/extract_manual_outlines.py` 上增加一步 —— 用正则从 `USER.pdf` 的 `front_text_joined` 抽取 `(NAME, section)` 输出 `REPORTS/abaqus_user_subroutines.csv`，与上表 **差集合并**（覆盖 `gen_umat_adapter` 未登记的 U*）。  
2. **内核**：对 `ufc_core` 运行域注册/命名扫描，将 `PUBLIC` 过程与 `target_core_api` **精确 JOIN**。  
3. **文档入口**：全层总览仍以 **`UFC/docs/README.md`**、**`UFC/docs/05_Project_Planning/PPLAN/README.md`** 为准；本文件仅 **REPORTS** 级过程说明，不替代 PPLAN。

---

## 9. 文件索引

| 路径 | 说明 |
|------|------|
| `UFC/.cursor/rules/pdf-processing.mdc` | PDF 处理规则（pypdf / pdfplumber / OCR） |
| `UFC/tools/extract_manual_outlines.py` | Manual 抽取脚本 |
| `UFC/REPORTS/manual_extract_raw.json` | 抽取原始 JSON |
| `UFC/tools/build_usub_ufc_alignment_table.py` | U* ↔ UFC 对齐表生成 |
| `UFC/REPORTS/usub_ufc_alignment.csv` / `.md` | 对齐表产物 |
| `UFC/REPORTS/Manual_UFC_domain_subroutine_mapping_guide.md` | 本说明 |
| `UFC/tools/extract_analysis3_materials_ufc_mapping.py` | **ANALYSIS_3（材料卷）** PyMuPDF 目录抽取 → `mat_family` 与 L3/L4 映射 |
| `UFC/REPORTS/analysis3_materials_ufc_mapping.json` | 上述映射机器表 + Properties 正文片段 + `keyword_pdfplumber_tables` |
| `UFC/REPORTS/analysis3_material_keyword_ufc_fields.csv` | **`*MATERIAL` 子选项** ↔ **`MD_Mat_Desc` / 各族 Desc** 字段级对照（含 pdfplumber 表预览列） |
| `UFC/docs/03_Domain_Pillars/Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md` | **材料卷 Part V 综合手册**：Part I = 手册 TOC/映射（脚本刷新）；Part II = 分族 × TYPE 沉淀 |
| `…/ANALYSIS_3_Materials_UFC_Mapping.md`、`…/_Family_UFC_TYPE_Catalog.md` | **stub**，指向上一行综合手册 |

---

*生成说明：抽取脚本已在本机跑通；若需扩展 THEORY 全书目录深度，可增大 `toc_and_front_fitz` 的 `front_pages` 或对单卷 ANALYSIS 分卷单独抽取以降低单次 JSON 体积。*
