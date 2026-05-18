# `design_plan/` — Harness 默认 `--plan` 根（设计计划骨架）

本目录为 **`doc-structure` / `plan-checks` 未传 `plan` 参数时的默认根路径**（由 `harness_config.json` → `paths.plan_relative_to_ufc` 指定，当前为 **`design_plan`**；可用环境变量 **`UFC_DEFAULT_PLAN`** 覆盖）。

## 为何不用 `PLAN/`（全大写）

在 **Windows** 等**大小写不敏感**文件系统上，`PLAN` 与运行任务目录 **`plan/`** 会解析为**同一路径**，导致设计骨架与任务区混桶。故 Harness 默认改用 **`design_plan/`** 专放「章节目录骨架」；**运行任务**仍在 **`plan/`**（小写，见 `plan/README.md`）。

## 与 `docs/`、`plan/` 的区分

| 目录 | 用途 |
|------|------|
| **`design_plan/`**（此处） | 满足 `doc_structure.required_dirs` 的目录树；正文权威以 **`docs/05_Project_Planning/PPLAN/`** 为主。 |
| **`docs/`** | 规范、架构、PPLAN 正文等。 |
| **`plan/`** | **运行任务区**（`TASK_RUN.md`、任务包、**`plan/changes/`** 规格变更包）。 |

## 双轨期与 `ufc_governance/`

规范叙事默认真源仍在 **`docs/`**；迁移与 flip 规则见 [`ufc_governance/MIGRATION.md`](../ufc_governance/MIGRATION.md)。本目录继续只做 **Harness 章节目录骨架**；各子目录 `README.md` 请链到 PPLAN / `ufc_governance`，勿复制大段正文。

## 章节目录骨架（`doc_structure.required_dirs`）

下列子目录各含 **`README.md`** 索引，链到 PPLAN / `docs` 真源（**不**复制长篇正文）：

- [`01_架构总纲与设计哲学/`](01_架构总纲与设计哲学/README.md)
- [`02_域级建模与实施清单/`](02_域级建模与实施清单/README.md)
- [`03_技术规范与标准/`](03_技术规范与标准/README.md)
- [`04_实施路线与任务规划/`](04_实施路线与任务规划/README.md)
- [`05_技术标准与参考/`](05_技术标准与参考/README.md)
- [`06_实施指南/`](06_实施指南/README.md)
- [`99_归档库/`](99_归档库/README.md)
