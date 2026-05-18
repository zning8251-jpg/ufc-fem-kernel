# `docs/` 文档整理指南（可执行边界）

**文档分级与按需加载（T0–T5、Agent 加载顺序）** → [`DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`](./DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md)（本页侧重 **合并/删旧/冲突** 的可执行边界）。**MR 自检（三桶）**：`docs/` / `design_plan/` / `plan/` 职责与「空目录观感」→ [`README.md` 锚点 `docs-root-three-buckets`](./README.md#docs-root-three-buckets)。

## 1. 是否可行？

**可行**，但必须分 **阶段** 做，否则风险是：外链大面积失效、PPLAN 与 `CONTRACT.md` 真源打架、无法审计「删了什么」。

| 区域 | 体量（约） | 建议策略 |
|------|------------|----------|
| `01_Architecture_Spec` | 少量 | 以 **Master Spec + 27 总决选** 为锚；其余重复叙事 **合并进锚点 + stub** |
| `02_Developer_Guide` | ~100 md | **按主题簇**合并（SIO / 模板 / 重构战役各 1 本手册）；先列目录再动刀 |
| `03_Domain_Pillars` | **1000+** md | **禁止**无清单批量删；优先 **Layer_Architecture_Splits** 等子树 **README 索引 + 去明显重复** |
| `04_Verification_Tests` | 极少 | 保持；与 `REPORTS/` 分工写清即可 |
| `05_Project_Planning/PPLAN` | ~260 md | **不**为「不散」而揉成单文件；用 **总纲 + README 表 + 归档策略** |

## 2. 合并 / 提炼 / 冲突时的原则

1. **以最新设计为准**：通常 = `01_Architecture_Spec` 当前总纲、`PPLAN` 现行实施路线、`ufc_core/**/CONTRACT.md`。  
2. **旧稿公共部分**：提炼为 **短「共识段」** 放进主文档；**不**在长文里复制两遍。  
3. **冲突**：**不静默删**——要么在主文档加 **「裁决」小节**（一句谁为准），要么删旧稿但 **同一 MR 内** 更新所有引用（grep 全仓）。  
4. **无价值旧资产**：仅当同时满足：**无入链**、**内容被新稿完全覆盖**、**非归档法定义务** 时，可 **删除**；否则 **移到** `docs/archive/…` 并保留 **README 说明来源与日期**（优于硬删）。

## 3. 已落地的「不散」范例（可复制）

- **材料卷 ANALYSIS_3**：[`03_Domain_Pillars/Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md`](./03_Domain_Pillars/Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md)（Part I 脚本区 + Part II 人工沉淀；旧文件名 **stub**）。  
- **材料柱产物**：[`03_Domain_Pillars/MaterialPillar/README.md`](./03_Domain_Pillars/MaterialPillar/README.md)（脚本 **唯一** 输出目录）。

## 4. 归档路径 `archive_20260418`

多篇 PPLAN 仍写相对链接 `../archive_20260418/...`。**当前克隆中该目录可能不存在**（未提交或已迁出）。处理选项：

- **需要对照**：从 Git 历史恢复该树，或从备份介质取回。  
- **不需要**：在 PR 中 **批量改链** 到现行 PPLAN 子路径或本指南，并删除失效表格行（需全仓 grep）。

<a id="archived-assets"></a>

## 5. 建议的下一批「白名单」合并（需你点头再改正文）

在下列 **明确列表** 获批前，代理 **默认只做** README / 断链 / stub，**不做**大段合并：

- [x] `02_Developer_Guide` 中标题含 **「总指挥部 / 战役 / SOP」** 且段落高度重叠的 N 个文件 → 1 个 `UFC_Developer_Strategy_and_Refactor_Playbook.md`（旧文件 stub）  
- [x] `03_Domain_Pillars/Layer_Architecture_Splits` 顶层与 `03-实施路线` **乱码 README** 已重写；**六层子 README** 仍分层维护（未强行合成单文件）  

## 6. 已执行的一批「文档减法」（可复制）

| 动作 | 说明 |
|------|------|
| 删除空推断清单 | `PPLAN/06_核心架构/UFC_层级域级f90文件推断清单_v1.0.md`（0 字节占位） |
| 下线重复命名规范 | `PPLAN/04_技术标准/UFC_命名规范_v1.0.md`（已由 v3.0 覆盖）；全仓链接已改指 `UFC_命名规范_v3.0.md` |
| 去掉 Registry 幽灵副本 | 已移入 `docs/archive/DomainProcedureRegistry_generated/`；真源为 `03_Domain_Pillars/DomainProcedureRegistry/` |
| 编码修复 | `03_Domain_Pillars/Element_HotPath_AssessmentReport.md` 自 GB18030 转 UTF-8，避免 `check_docs_health` 中断 |
| 闭环总纲链接真源 | 全库 `05_中间架构层新版总纲_十件套v2.0.md`（已不存在）→ **`05_中间架构层新版总纲_全景套件v3.0.md`**；模板中 SIO 链到 `04_技术标准/UFC_Principle14_结构化IO参数传递规范.md` |
| PPLAN 根 README 入口 | `../UFC_命名…`、`../DomainProcedureRegistry/…` 改为 **`../02_Developer_Guide/…`**、**`../03_Domain_Pillars/DomainProcedureRegistry/…`**（与 `docs/` 实际路径一致） |

**汇编阅读版**（非删稿）：`01_Architecture_Spec/UFC_全景架构_按章节汇编_阅读版.md`（`python tools/assemble_panorama_reader.py`）；开发者战役短稿见 `02_Developer_Guide/UFC_Developer_Strategy_and_Refactor_Playbook.md`。

---

*本页为 **整理规则与边界**；具体技术结论仍以各域 `CONTRACT.md` 与 PPLAN 现行章节为准。*
