# REPORTS 与 `docs/` 去重策略（SSOT）

**性质**：执行约定（T4 读时摘结论）；**不**升格为架构或合同真源。

## 1. 单一真源（SSOT）速查

| `REPORTS/` 子类 | 典型文件 | 长期真源（优先阅读） |
|-----------------|----------|----------------------|
| 过程算法、四型合订 | `*_Procedure_Algorithm.md`、`*_four_type_synthesis.md`、`Procedure_Algorithm_L3L4L5_synthesis.md`、`FourKind_MasterAux_Nesting_Design_Spec.md` | 稳定结论回迁 `docs/02_Developer_Guide/` 或相关域 `ufc_core/**/CONTRACT.md`；本目录长文可 **stub + `archive/`**（根路径不变） |
| 域清册、主索引 | `*_Domain_Inventory.md`、`Master_Domain_Inventory_Index.md` | `docs/03_Domain_Pillars/DomainProcedureRegistry/README.md`；清册标 **快照日期**，与 Registry 冲突以 Registry 为准 |
| 命名、压缩 | `REPORT_Naming_*.md`、`Domain_Compression_Canon.md` | `rules/ufc-naming.mdc` + `docs/02_Developer_Guide/`；报告侧保留变更说明与场景讨论 |
| 手册映射、关键字 | `Abaqus_*Mapping*.md`、`Keyword_*` | `docs/03_Domain_Pillars/Abaqus_Manual_Alignment/README.md` 与域柱正文；本目录保留抽取过程稿与机器辅助映射 |

**禁止**：第三份与 `DomainProcedureRegistry/generated/` 并行的「幽灵生成树」；参见 `docs/README.md` 与 `docs/archive/` 约定。

## 2. 重复时的处理顺序

1. 以 `docs/` + 域 `CONTRACT.md` 为裁决。  
2. 报告仍有用时：在报告顶部增加 **SSOT 提醒** 与日期；或改为 **stub**（数行 + 链接）。  
3. 结论已完全迁入 `docs/` 时：报告可整包迁入 `REPORTS/archive/` 并在本目录 README 索引中标注「已归档」。  
4. **根目录 stub**：外链需稳定指向 `REPORTS/<name>.md` 时，可将长文迁入 `archive/<name>.md`，根目录保留短 stub（示例：八域 **四型合订** 与 **材料 UMAT 合订** 已统一采用「根 stub + `archive/` 全文」）。

## 3. `data/` 目录

见同目录 [`data/README.md`](data/README.md)：证据包、引用关系、体积与 LFS 建议。

## 4. `archive/` 与活性根目录

- **根目录 `REPORTS/*.md`**：仍被日常协作引用的合订、清册、手册映射、命名主规；**或** 仅保留 **stub**、正文在 `archive/` 的稳定外链锚点（见 §2 第 4 条）。  
- **`archive/`**：一次性收尾、sprint 日志、历史 handoff、**stub 对应的长文正文**；索引见 [`archive/README.md`](archive/README.md)。迁入 archive 前确认无 `docs/` 或其它仓库路径硬依赖（或已改为链到 archive）。

## 5. 相关入口

- 文档分级与按需加载：`docs/DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`  
- 维护边界：`docs/DOC_MAINTENANCE_GUIDE.md`  
- 目录分区规则：`rules/ufc-directory-layout.mdc`  
- 任务编排（人类真相源）：`plan/README.md`
