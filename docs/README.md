# UFC Documentation Center

UFC（UniFieldCore）文档按 **五个主桶** 组织；**入口以本文件为准**。历史散件已逐步收拢；大规模实施稿集中在 **PPLAN**（不强行合并成单文件，以免丢失章节粒度）。

## 目录结构

```
docs/
├── 01_Architecture_Spec/    ← 架构 SSOT（17 文件）
├── 02_Developer_Guide/      ← 开发者指南（236 文件，含 14 个 UFC 专项 Agent 技能）
├── 03_AI_Skills_Export/     ← AI 技能导出稿（2 文件）
├── 03_Domain_Pillars/       ← 域柱与手册对齐（1290 文件）
├── 04_Verification_Tests/   ← 验证测试（6 文件）
├── 05_Project_Planning/     ← 项目与实施 / PPLAN（265 文件）
├── MaterialPillar/          ← 重定向 stub（1 文件）
├── archive/                 ← 已归档（幽灵副本 + 泛用技能，1393 文件）
├── README.md
├── DOC_MAINTENANCE_GUIDE.md
├── DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md  ← 文档分级 T0–T5 + 按需加载 + 旧稿治理入口
└── 00-快速导航.md
```

## 1. 五柱导航（你该去哪）

| 桶 | 路径 | 放什么 |
|----|------|--------|
| **架构 SSOT** | [`01_Architecture_Spec/`](./01_Architecture_Spec/) | 总规范、哲学、与 Abaqus/桥接相关的 **单一事实源**；**通读单行本**（`00`+`27`+哲学 14–18+闭环 00–24+99+`25`–`26` 汇编）：[`UFC_全景架构_按章节汇编_阅读版.md`](./01_Architecture_Spec/UFC_全景架构_按章节汇编_阅读版.md)（`python tools/assemble_panorama_reader.py` 可重生成） |
| **开发者** | [`02_Developer_Guide/`](./02_Developer_Guide/) | SIO、模板、数据合同、重构路线；`Agent_Skills/` 仅保留 UFC 专项 14 项（`fem-kernel-*` / `ufc-*`） |
| **域柱与手册对齐** | [`03_Domain_Pillars/`](./03_Domain_Pillars/) | L1–L6 域逻辑、材料/单元等柱、**Abaqus 手册对齐**、六层拆解子树；`DomainProcedureRegistry/` 在此桶内为唯一真源 |
| **验证** | [`04_Verification_Tests/`](./04_Verification_Tests/) | Patch、NAFEMS、参考数据与验证策略 |
| **项目与实施** | [`05_Project_Planning/README.md`](./05_Project_Planning/README.md) | **PPLAN**、闭环专项、路线图与过程管理 |

**PPLAN 索引**：[`05_Project_Planning/PPLAN/README.md`](./05_Project_Planning/PPLAN/README.md) · **总纲 v5.0 直达**：[`05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md`](./05_Project_Planning/PPLAN/01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md) · [`05_Project_Planning/README.md`](./05_Project_Planning/README.md)（本桶浅层入口表）

**仓库级 Agent 说明**（技能表、闭环架构、Fortran 约束）：`UFC/AGENTS.md`。

**闭环体系**：Prompt → [AGENTS.md + rules + docs] → Skills → MCP → Agent → [Harness] → Loop。详见 `UFC/AGENTS.md` 闭环架构节。

<a id="docs-root-three-buckets"></a>
### 1.1 与仓根 `design_plan/`、`plan/` 的一眼区分（避免「空目录=缺陷」误判）

| 路径 | 角色 | 为何常「看起来空」 |
|------|------|-------------------|
| **`docs/`（本树）** | 规范 / 域柱 / PPLAN **正文与真源** | 子目录多、文件多；个别 stub 或预留目录可能只有 `README.md` |
| **`UFC/design_plan/`** | Harness **`doc_structure`** 章节目录骨架 | **刻意**每章一个 `README.md` 链到 PPLAN/`docs`，**不**复制长篇正文（见该目录 [`README.md`](../design_plan/README.md)） |
| **`UFC/plan/`** | **运行任务区**（`tasks/` / `backlog/` / `archive/`） | 无进行中任务时，子桶往往 **只有各目录的 `README.md`**；有任务后才有 `plan/tasks/<id>/TASK_RUN.md` 等（见 [`plan/README.md`](../plan/README.md)） |

更细的 T 级与按需加载：[`DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`](./DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md)。

## 2. 闭环链路

UFC 采用 **Prompt → Context → Skills → MCP → Agent → Harness → Loop** 七节点闭环：

| 节点 | 载体 | 入口 |
|------|------|------|
| Prompt | 用户查询 | — |
| Context | 规则 + 文档 + 记忆 | `UFC/AGENTS.md`、`UFC/rules/`、本文档；**按需加载顺序**见 [`DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`](./DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md) |
| Skills | 技能 SKILL.md | `UFC/skills/`、`UFC/AGENTS.md#skills` |
| MCP | 外部工具服务器 | `UFC/AGENTS.md#mcp` |
| Agent | Qoder/Cursor AI | — |
| Harness | 仓库工具集 | `UFC/ufc_harness/README.md` |
| Loop | 反馈反哺 | 记忆更新、文档修正、技能迭代 |

## 3. 已合并 / 防再散（维护约定）

| 主题 | 真源路径 | 说明 |
|------|-----------|------|
| **开发者战略 / 重构战役短稿（合并）** | [`02_Developer_Guide/UFC_Developer_Strategy_and_Refactor_Playbook.md`](./02_Developer_Guide/UFC_Developer_Strategy_and_Refactor_Playbook.md) | 原 10 篇重叠「总指挥部 / 双螺旋 / SOP / 模板」等 **stub 指向此手册**；勿在旧文件名上续写 |
| **L345 形式对齐 / 首 PR 接缝** | [`UFC_L345_形式对齐域级检查表_P1-P6.md`](./02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md) · [`PR01_P1_P2_材料单元装配金线.md`](./02_Developer_Guide/PR01_P1_P2_材料单元装配金线.md) | **v1.4**：域柱垂直切片；**PR01**：P1∩P2∩Assembly 金线模板与 ①→⑥ |
| **材料柱** 清单与 CSV | [`03_Domain_Pillars/MaterialPillar/`](./03_Domain_Pillars/MaterialPillar/README.md) | `tools/material_pillar_audit.py`、`material_mat_catalog.py` **默认写此目录**；`docs/MaterialPillar/` 仅保留 **重定向 README**，勿再双轨投放 |
| **材料卷 ↔ UFC** | [`03_Domain_Pillars/Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md`](./03_Domain_Pillars/Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md) | **单一综合手册**（Part I 脚本刷新 + Part II 沉淀）；同目录下 `*_Mapping.md` / `*_Catalog.md` 为 **stub** |
| **AI 技能导出** | [`03_AI_Skills_Export/`](./03_AI_Skills_Export/) | 与 `.claude/skills` 等工具链配合的导出稿，**不**与 `02_Developer_Guide` 混放 |
| **Agent_Skills 泛用技能归档** | [`archive/Agent_Skills_generic/`](./archive/Agent_Skills_generic/) | 14 个与 UFC 无关的泛用 Claude 技能（`algorithmic-art`、`canvas-design`、`docx`、`pptx`、`xlsx` 等）已移入归档；`02_Developer_Guide/Agent_Skills/` 仅保留 UFC 专项技能（`fem-kernel-*` / `ufc-*`） |
| **DomainProcedureRegistry 幽灵副本** | [`archive/DomainProcedureRegistry_generated/`](./archive/DomainProcedureRegistry_generated/) | 根级 `DomainProcedureRegistry/generated/`（1058 生成文件）已移入归档；唯一真源为 [`03_Domain_Pillars/DomainProcedureRegistry/`](./03_Domain_Pillars/DomainProcedureRegistry/) |

## 4. 若仍觉得「散」

- **读架构**：从 `01_Architecture_Spec/00_UFC_全景架构白皮书_Master_Specification.md` 与 `27_UFC_01至26全景架构决策汇总与实施路线总决选.md` 起，再下钻域柱。
- **写代码**：`02_Developer_Guide` + 对应层 `ufc_core/**/CONTRACT.md`。
- **追工单**：`05_Project_Planning/PPLAN/`；不必与 `01` 重复粘贴，用 **链接** 互指即可。

## 5. 全库整理（合并 / 删旧 / 冲突裁决）

**原则与可操作边界**（体量、白名单、归档说明）：[`DOC_MAINTENANCE_GUIDE.md`](./DOC_MAINTENANCE_GUIDE.md)。

## 6. 文档分级与按需加载（体系入口）

**T0–T5 分级、Agent 加载顺序、旧稿治理与 `design_plan`/`plan` 分工**：[`DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`](./DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md)。  
与 **任务编排** 合读：[`../plan/UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md`](../plan/UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md)。

## 7. archive/ — 已归档

| 目录 | 说明 |
|------|------|
| [`archive/DomainProcedureRegistry_generated/`](./archive/DomainProcedureRegistry_generated/) | 根级幽灵副本（1058 生成 manifest），原 `docs/DomainProcedureRegistry/generated/`；真源在 `03_Domain_Pillars/DomainProcedureRegistry/` |
| [`archive/Agent_Skills_generic/`](./archive/Agent_Skills_generic/) | 14 个与 UFC 无关的泛用 Claude 技能模板（~550 文件，含 `.ttf` / `.xsd` / `.py` 等非 Markdown 资产） |

*本 README 只描述格局与真源；具体设计内容以各子目录 Markdown 与合同文件为准。*
