# `ufc_governance/` — UFC 工程治理与「三件套」总桶

本目录与 `[ufc_harness/](../ufc_harness)` 同级，集中承载 **规格环（Spec）/ 流程环（Flow）/ 纪律环（Discipline）** 的模板、对照文档与机器可读配置；**不**替代 `ufc_harness` 内的可执行门禁，而是为其提供输入与约定。

## 三桶关系（双轨期）


| 区域                            | 角色                                                                     |
| ----------------------------- | ---------------------------------------------------------------------- |
| `[docs/](../docs)`            | **当前默认真源**：规范、PPLAN、开发者指南（未 flip 前以仓库既有入口为准）。                          |
| `**ufc_governance/library/`** | **迁移目标桶**：总纲、子纲、设计叙事分批迁入；每文件须遵守 `[MIGRATION.md](MIGRATION.md)` 的元数据约定。 |
| `[plan/](../plan)`            | 运行任务、`TASK_RUN.md`、**变更包**目录 `[plan/changes/](../plan/changes)`。       |


## 子目录速览


| 路径                                              | 说明                                                                                 |
| ----------------------------------------------- | ---------------------------------------------------------------------------------- |
| `[triad/](triad/README.md)`                     | 三件套：spec / flow / discipline 与 `[triad/CROSSWALK.md](triad/CROSSWALK.md)` 外源方法论对照。 |
| `[library/](library/00_constitution/README.md)` | 分级规范库占位；flip 前多为索引与试点正文。                                                           |
| `[migration/](migration/INVENTORY.csv)`         | 迁移清单与 flip 门禁。                                                                     |


## 入口命令（Harness）

```text
python UFC/ufc_harness/run_harness.py change-package validate --change-id <id> [--strict]
python UFC/ufc_harness/run_harness.py discipline verify [--touch-path <path> ...] [--strict]
```

详见 [`ufc_harness/README.md`](../ufc_harness/README.md)。

## OpenSpec npm（兜底 CLI）

- **安装**：在 `UFC/` 下执行 `npm ci` 或 `npm install`（见根目录 [`package.json`](../package.json)，含 `@fission-ai/openspec`）。  
- **验证 CLI**：`cd UFC && npx openspec --version`  
- **与自研校验**：变更包仍以 **`ufc_harness change-package validate`** 与 `plan/changes/` 为准；若按上游 OpenSpec 初始化出 `openspec/` 目录，可再用 `npx openspec validate …` 交叉验证。

**CI**：monorepo `.github/workflows/ufc-ci.yml` 的 **Harness doc / SSOT** job 已包含 `npm ci`、`npx openspec --version` 以及 `python scripts/ci/check_change_packages_strict.py --ufc-root UFC`（对每个含 `proposal.md` 的 `plan/changes/*` 执行 **`--strict`**）。

## Agent 技能

编排入口：`npx openskills read ufc-governance-triad`（技能文件 `[skills/ufc-governance-triad/SKILL.md](../skills/ufc-governance-triad/SKILL.md)`）。