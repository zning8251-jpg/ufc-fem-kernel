# UFC 架构 Spine 索引（设计基因与章节目录锚点）

> **用途**：把「愿景 / 十大基因 / 子总纲 / 各层详解 / 演进路线」**映射到仓库已有文档**，避免重复分叉。  
> **维护**：新增章节时只增加一行链接，不复制长文。

---

## 第一部分：背景与总纲

| 主题 | 锚点文档 |
|------|-----------|
| 六层、四类、四链、三步、三级、两图、一体 | [v2.0 总纲（归档）](../../archive_20260418/archive/PLAN_History/99_归档库/01_历史版本文档/UFC_架构设计总纲_六层四类四链三步三级两图一体.md)；**工作主线**：[v5.1 整合版](../01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md)（文件名 v5.0，内容已迭代至 v5.1） |
| 三层联通、热路径、数据链、验证 | 原「三层联通总规范」未随仓库；请阅 [域边界与链路整治](../../archive_20260418/PPLAN_过程稿/域分级重构/UFC_系统化整治方案_域边界与链路打通.md)、[v5.1 总纲](../01_架构总纲/UFC_架构设计总纲_深度整合版_v5.0.md) |
| 四型 TYPE（Desc/State/Algo/Ctx） | 各层 `ufc_core/**/contracts/`、[UFC_数据结构与结构体规范](../../UFC_数据结构与结构体规范.md) |
| 热路径隔离（零 L3、无暗道） | [L5_RT/Assembly/CONTRACT.md](../../../ufc_core/L5_RT/Assembly/CONTRACT.md)、[L5_RT/Solver/CONTRACT.md](../../../ufc_core/L5_RT/Solver/CONTRACT.md)、[L5_RT/StepDriver/CONTRACT.md](../../../ufc_core/L5_RT/StepDriver/CONTRACT.md) |
| 三步状态机 + 非线性扩展 | [L5_RT/StepDriver/CONTRACT.md](../../../ufc_core/L5_RT/StepDriver/CONTRACT.md)、[L5_RT/Solver/CONTRACT.md](../../../ufc_core/L5_RT/Solver/CONTRACT.md) |
| **端到端数据流（权威总图）** | **[UFC_权威端到端数据流总图.md](UFC_权威端到端数据流总图.md)**（整合 3 份数据流文档，含 CONTRACT 交叉校验） |
| UEL / UMAT 数据链 | [UFC_DataFlow_UEL_UMAT.md](../../archive_20260418/PPLAN_过程稿/数据流转/UFC_DataFlow_UEL_UMAT.md)（归档辅助）、[L4_PH Element 合同](../../../ufc_core/L4_PH/Element/CONTRACT.md)、[L4_PH Material 合同](../../../ufc_core/L4_PH/Material/CONTRACT.md) |
| Step / Load / BC / Contact 数据链 | [UFC_DataFlow_Step_LoadBC_Contact.md](../../archive_20260418/PPLAN_过程稿/数据流转/UFC_DataFlow_Step_LoadBC_Contact.md)（归档辅助） |
| L3 外存 / IO | `ufc_core/L3_MD/**/CONTRACT.md`；实施侧见 [05_实施指南/](../05_实施指南/) |
| 命名与数据结构 | [UFC_命名与数据结构规范.md](../../UFC_命名与数据结构规范.md)；编码约定见仓库根 [AGENTS.md](../../../AGENTS.md) |
| AI-ready / 观测 | 技能 `fem-kernel-observability`；各域合同「诊断/观测」节（逐步补） |

---

## 第二部分：L1–L6 各层

| 层 | 合同 / 入口 |
|----|-------------|
| L1_IF | `L1_IF/**/CONTRACT.md`（若有）、错误/精度模块头注释 |
| L2_NM | `L2_NM/**/CONTRACT.md`（若有）、矩阵/求解器核心 |
| L3_MD | `ufc_core/L3_MD/**/CONTRACT.md`、[02_域级建模/](../02_域级建模/) |
| L4_PH | `L4_PH/contracts/`、`docs/templates/PH_*.f90` |
| L5_RT | `L5_RT/**/CONTRACT.md`、`RT_StepDriver_Core.f90` |
| L6_AP | `ufc_core/L6_AP/**`、PPLAN 中 AP/Job 相关稿 |

---

## 第三部分：演进与工具

| 主题 | 锚点 |
|------|------|
| PPLAN 总入口 | [PPLAN/README.md](../README.md) |
| MVP / 整改 | [05_实施指南/](../05_实施指南/)、[03_实施规划/实施路线/](../03_实施规划/实施路线/) |
| Harness（合同/USE/语法 门禁） | [ufc_harness/run_harness.py](../../../ufc_harness/run_harness.py)、CI 门禁 [scripts/ci/check_harness_gates.py](../../../scripts/ci/check_harness_gates.py) |
| 合同卡完整性检查 | [scripts/ci/check_contracts.py](../../../scripts/ci/check_contracts.py) |
| 命名规范检查 | [ufc_harness/tools/code_development/naming_checker.py](../../../ufc_harness/tools/code_development/naming_checker.py) |

---

## 相关索引

- [docs/index.md](../../index.md)
