# `plan/` — 运行任务区（与 `design_plan/` 区分）

**编排总览（目录 × 七段闭环 × 状态机/持久化/策略）** → [`UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md`](UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md)

**L3/L4/L5 域柱改造工作流（七步·任务分解·交接·验收）** → [`workflows/README.md`](workflows/README.md) · 规范 [`docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md)

本目录 **`UFC/plan/`**（小写）存放**任务编排、长任务状态、非生产产出**；**不得**放入 `ufc_core` 级生产 Fortran 或内核实现代码。

Harness **默认 `--plan` 设计骨架**在同级目录 **`design_plan/`**（因 Windows 上不可与 `plan/` 仅靠大小写区分 `PLAN` / `plan`）。

## 双轨期：工程治理三件套（`ufc_governance/`）

规范叙事默认真源仍在 **`docs/`**；**规格变更包**在 **`plan/changes/<change_id>/`**（见 [`plan/changes/README.md`](changes/README.md)）。迁移状态与 flip 规则见 **`ufc_governance/MIGRATION.md`**；试点索引见 **`ufc_governance/library/00_constitution/TRIAD_SYSTEM_INDEX.md`**。

Harness：`python ufc_harness/run_harness.py change-package validate --change-id <id>`；编排技能：`npx openskills read ufc-governance-triad`。

## 四目录角色速览（与 `docs/` / `REPORTS/`）

| 目录 | 权威角色 | 说明 |
|------|----------|------|
| `docs/` | 规范与叙事真源（T0–T3 主体） | 架构、指南、域柱、PPLAN 正文；详见 `docs/README.md` |
| **`plan/`**（本目录） | 运行任务区（T4） | 人类编排真相源：`tasks/` / `backlog/` / `archive/` / **`changes/`**（规格变更包） |
| `design_plan/` | Harness `--plan` 章节目录骨架（T4） | 仅索引链到 `docs/05_Project_Planning/PPLAN/`，禁止复制长篇正文 |
| `REPORTS/` | 阶段报告与证据（T4） | 过程稿、清册、合订本；与 `docs/` 去重见 `REPORTS/SSOT_AND_DEDUP_POLICY.md`；**冷归档**见 `REPORTS/archive/README.md` |

| 路径 | 存放内容 | 禁止 |
|------|----------|------|
| **`plan/tasks/<task_id>/`** | 已立项、进行中的任务包。**必含** `TASK_RUN.md`（`agent-task init` 生成）。可增：`artifacts/`、`notes.md`。 | 生产代码、`.f90` 实现、可进构建的源码树 |
| **`plan/changes/<change_id>/`** | 规格驱动变更包（proposal/design/tasks/specs）。见 `plan/changes/README.md` 与 `ufc_governance/triad/spec/POLICY.md`。 | 与 `tasks/<id>` 混用同一目录名导致歧义（勿复用同名） |
| **`plan/backlog/`** | 未排期想法：单文件 `*.md` 或临时条目。 | 与 `tasks/` 内正式包重复堆放 |
| **`plan/archive/<task_id>/`** | 已完结任务：从 `tasks/<id>/` **整体迁入**。 | 在 `archive/` 继续改代码后再同步回 `ufc_core`（应新开 `tasks/` 任务） |

各子目录一行约定：`tasks/README.md`、`backlog/README.md`、`archive/README.md`。

## 与仓库其它目录的关系

- **`ufc_core/`**：**仅**六层生产代码与层内测试/合同。
- **`REPORTS/`**：Harness/Guardian/closure 等**机器生成报告**；长任务人类编排主卡在 **`plan/tasks/<id>/TASK_RUN.md`**。
- **`design_plan/`**：**Harness 默认 `--plan`** 设计目录骨架（`doc_structure.required_dirs`）。
- **`ufc_governance/`**：工程治理三件套与迁移桶；双轨期说明见 [`ufc_governance/MIGRATION.md`](../ufc_governance/MIGRATION.md)。

## 工具

```text
python ufc_harness/run_harness.py agent-task init --session <task_id> --goal "…"
python ufc_harness/run_harness.py agent-task status --session <task_id>
python ufc_harness/run_harness.py agent-task validate --session <task_id> [--strict]
python ufc_harness/run_harness.py agent-task list
```

- 默认写入 **`plan/tasks/<task_id>/TASK_RUN.md`**。
- 测试/CI 可设 **`UFC_PLAN_ROOT`** 指向临时目录。

## `task_id` 命名建议

字母数字、连字符、下划线；与分支名或 Issue 编号对齐，避免空格与中文路径。
