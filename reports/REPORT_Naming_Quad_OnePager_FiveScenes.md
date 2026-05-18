# REPORT：域柱合订 + 一页纸（命名与五场景）（规范）

**路径**：`UFC/REPORTS/REPORT_Naming_Quad_OnePager_FiveScenes.md`  
**性质**：约定 **材料/单元/截面合订、一页纸及 P3–P6 域柱合订 REPORT** 的 **规范简称、文首元数据、互链句**；**五场景 S0–S4** 与 **`Pillar_L3L4L5_CrossLayer_Design_Template.md`** 冷/热金线对齐。**不替代**各域 `CONTRACT.md`。本地 **Abaqus PDF** 只作 **语义/关键字锚点**（见 **§6**），**不**整段抄入 UFC 文档。

---

## 1. 文档族与「规范简称」（文件名保持仓库真名）

| 报告 ID | 规范简称（中文） | 仓库文件名（真名） | 域 / 角色 |
|---------|------------------|-------------------|-----------|
| **REP-ONE-PAGER** | **一页填槽** | `OnePager_FourKind_MasterAux_Nesting.md` | 横切 **材料 / 单元 / 截面**；主/辅四型、总分、ABI_Flat、**R-01–R-08** |
| **REP-MAT-UMAT** | **材料合订（UMAT）** | `Material_L3L4L5_four_type_UMAT_discussion_synthesis.md` | 材料域柱 + UMAT；**附录 F/G** |
| **REP-ELEM-UEL** | **单元合订（UEL）** | `Element_L3L4L5_four_type_UEL_discussion_synthesis.md` | 单元域柱 + UEL；**附录 C** |
| **REP-SECT-MES** | **截面合订（M–E–S）** | `Section_L3L4L5_four_type_synthesis.md` | 第三轴；**§9 S0** |
| **REP-CONT-PILLAR** | **接触合订（P3）** | `Contact_L3L4L5_four_type_synthesis.md` | 接触/Interaction；**搜索–检测–力–刚度** |
| **REP-LOADBC-PILLAR** | **载荷/BC 合订（P4）** | `LoadBC_L3L4L5_four_type_synthesis.md` | LoadBC |
| **REP-OUTPUT-PILLAR** | **输出合订（P5）** | `Output_L3L4L5_four_type_synthesis.md` | Output（半柱 L3+L5 为主） |
| **REP-WB-PILLAR** | **写回合订（P6）** | `WriteBack_L3L4L5_four_type_synthesis.md` | WriteBack / Checkpoint |

**文件名说明（与材料/单元对齐）**：截面文件为历史名 **`…_synthesis.md`**（无 `discussion_` 段）；**新开同类 REPORT** 建议采用 **§2** 模板，旧三文件 **不重命名**（避免外链与书签大面积失效）；引用时优先写 **报告 ID** 或 **规范简称**。

---

## 2. 新开 REPORT 文件名模板（建议）

```
REPORT_<DomainTag>_L3L4L5_<Focus>_<DocKind>.md
```

| 段 | 取值示例 | 说明 |
|----|-----------|------|
| `DomainTag` | `Mat` / `Elem` / `Sect` / `X` | 域或横切主题 |
| `L3L4L5` | 固定 | 层跨度锚点 |
| `Focus` | `four_type_UMAT` / `four_type_UEL` / `four_type_MES` | 与 ABI 或正交维对齐 |
| `DocKind` | **`discussion_synthesis`**（大篇幅合订） / **`onepager`**（一页规范） | 与 **材料/单元** 现名一致 |

**一页纸** 类可继续用 **`OnePager_<Topic>.md`** 前缀，便于在 `REPORTS/` 目录排序。

---

## 3. 五场景 **S0–S4**（统一语义；与 Pillar 冷/热对应）

| 代号 | 场景名 | 一句话 | 典型落点（前缀/模块族） |
|------|--------|--------|-------------------------|
| **S0** | **冷真源 / 定义与注册** | L3（或合同指定层）持 **SSOT**；步内 **只读** | `MD_*_Def`、`MD_*_Reg`、域 **Desc** |
| **S1** | **Populate** | L3→L4 **灌槽/缓存**；**不与 Newton 内环混写** | `PH_L4_Populate_*`、`MD_*PH_Brg` |
| **S2** | **热输入 / 局部上下文** | 步内写 **ctx、增量、索引绑定**；可经窄 `*_Arg` | `*%ctx%lcl*`、`PH_*_Update_args` |
| **S3** | **Dispatch（薄）** | L5（或门脸）**校验 + 查表 + 路由**；**不持大数组主源** | `RT_*_Dispatch_*`、`RT_*_Brg_MakeCtx` |
| **S4** | **Execute / Hook** | L4 **物理核**或 **用户子程序**；**主写入 state/装配缓冲** | `PH_*_Execute*`、`PH_UMAT_*` / `PH_UEL_*`、ABI_Flat |

**写回 / 分期归档**：不占用第六「主场景」代号；在合同与 **Pillar** 中记为 **Populate 之后 / 作业末** 的 **W** 路径，与 **S4** 的「步内权威」区分主次。

**与 Pillar 对照**：**S0+S1** ≈ 冷路径 **C***；**S2–S4** ≈ 热路径 **H***（细分为输入准备 / 调度 / 执行）。

---

## 4. 文首元数据（各 REPORT 建议粘贴）

在 **`#` 标题行之后**、正文第一节之前，增加 **固定两行**（随文改 ID）：

```markdown
**报告 ID**：`REP-…`（见 `REPORTS/REPORT_Naming_Quad_OnePager_FiveScenes.md` §1）  
**五场景索引**：**S0–S4** 定义见同文件 **§3**。
```

---

## 5. 维护

- 新增/改名 REPORT：先更新 **§1 表** 与本文件版本行；再改 **Pillar** 文首「镜像」句（若有）。  
- **PDF 换版**（如 2016→2024）：仅更新 **§6** 表内「页数/卷名」抽检行，**不**自动改写各域 `CONTRACT`。  
- **版本**：**v0.5** · **2026-05-04** — §6 新增 **`Abaqus_UserSubroutine_UFC_Map.md`** 行；P1–P6 域柱交叉引用 v0.5 全面补全（18 份四类TYPE←→Procedure/Algorithm 互链 + Design Spec R-12/R-13 + OnePager §1 Algo 语义 + Pillar §4.3）。  
- **v0.4** · **2026-05-03** — §6 增 **`Abaqus_UserSubroutine_UFC_Map.md`** 交叉引用。  
- **v0.3** · **2026-05-03** — §1 增 **P3–P6** 四合订；新增 **§6** 本地 PDF 索引与 PyMuPDF 抽检说明。

---

## 6. 外部 Abaqus PDF（`D:\TEST7\Manual\`；PyMuPDF 抽检元数据）

**许可**：以下均为 **Dassault / Abaqus 官方文档**；仅可在 **已获授权** 的使用场景下作 **内部设计与关键字对齐**；UFC 文档 **不摘录** 受版权保护的长段正文。

| 本地文件 | 元数据题名 / 卷 | 页数（抽检） | 与设计文档的典型对齐 |
|----------|-----------------|-------------|----------------------|
| **`ANALYSIS_2.pdf`** | *Analysis User's Guide* **Vol. II: ANALYSIS** | 1529 | **步、过程、求解控制**；与 **Output / WriteBack** 的节拍、**LoadBC** 与步内 prescribed 条件时序交叉核对。 |
| **`ANALYSIS_5.pdf`** | *Analysis User's Guide* **Vol. V: PRESCRIBED CONDITIONS, CONSTRAINTS & INTERACTIONS** | 962 | **载荷、边界、幅值、约束、接触/交互**；与 **LoadBC / Contact** 合订本 **Part VII / §34+** 级目录对齐（书签以 PDF 内 TOC 为准）。 |
| **`KEYWORD.pdf`** | *Keywords Reference Guide*（2016） | 1634 | **`*STEP`、`*BOUNDARY`、`*CLOAD`、`*CONTACT`、`*OUTPUT`…** 与 L3 关键字解析 / Populate **合同字段** 对照。 |
| **`USER.pdf`** | *User Subroutines Reference Guide*（**6.14**，与 2016 Analysis 卷版本号可能不一致） | 643 | **UINTER、DLOAD、UAMP、UVARM…** 与 UFC **用户钩子 / ABI_Flat** 命名对齐；以 **本仓库 `CONTRACT` + 合订本** 为真源，手册仅辅证。 |

**抽检方式**：终端脚本 **`UFC/temp_pdf_extractor.py`**（`import fitz`）输出 `metadata`、`page_count`、`get_toc(simple=True)[:30]`；**禁止**用 IDE 默认二进制方式「强读」PDF 正文。  
**子程序名 ↔ UFC 域柱**：**`REPORTS/Abaqus_UserSubroutine_UFC_Map.md`**（**无**完整 Fortran 签名；接口以持证 **USER.pdf** 为准）。

---

## 8. Forward References → 新版命名规范合订

| 新规范 | 本版内容去向 |
|--------|-------------|
| **`REPORT_Naming_Unified_Spec.md`** (v1.0) | **§3(场景)** 五场景定义 + **§5(命名模板)** 域缩/层缀/四型 已迁移至新规范；本报告保留 **§3(简要场景)** 供快速查阅。更新规范请以新文档为准。 |
| **`Master_Domain_Inventory_Index.md`** (v1.0) | 跨域 Inventory 主索引，统一引用 8 份域级模块清单。 |