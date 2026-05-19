---
task_run_version: "1.0"
session: "p1-material-c2-mateval-split"
status: active
current_step_id: "1"
updated_at: "2026-05-19T04:46:11Z"
---

# TASK_RUN

UFC 长任务运行卡（约定路径：`plan/tasks/<session>/TASK_RUN.md`，见 `plan/README.md`）。**单一真相源**：子任务状态以本文件为准；新开 IDE 会话时先读本文件并执行 `python ufc_harness/run_harness.py agent-task status --session <session>`。

- 可选：在上方 YAML front matter 增加 `governance_change_id: "<change_id>"`，与 `plan/changes/<change_id>/` 对齐（见 `ufc_governance/triad/flow/PLAYBOOK_FEATURE.md`）。

## Goal

C2 PR-A: move Elas+Plast legacy point Eval from PH_MatEval to family modules; PH_MatEval facade re-exports.

## Roles（逻辑角色）


| 角色  | 职责摘要                                                    |
| --- | ------------------------------------------------------- |
| 实现  | 改 `ufc_core` / 技能要求的模板与测试                               |
| 守门  | `guardian` / `pillar-loop` / 窄 `--rules`                |
| 文档  | `doc-structure` / `plan-checks`（改 `docs/` 设计文档须任务单明确授权） |


## Context pointers（按需加载）

- `AGENTS.md` 技能速查；**分级与加载顺序**：`docs/DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`
- `docs/README.md` / `docs/00-快速导航.md`（入口指针）
- 本任务相关 `CONTRACT.md` 路径：（填写）
- 可选：`python ufc_harness/run_harness.py agent-bundle --task "…"`

## References（3–5 行路径指针，禁止整目录粘贴）


| Tier | Path / anchor                        | 用途      |
| ---- | ------------------------------------ | ------- |
| T1   | `docs/01_Architecture_Spec/...`      | （填一条锚点） |
| T2   | `ufc_core/.../CONTRACT.md`           | （填域合同）  |
| T3   | `docs/05_Project_Planning/PPLAN/...` | （填单文件）  |


## Subtasks


| id  | subtask        | state   | next_harness                                                     | notes                  |
| --- | -------------- | ------- | ---------------------------------------------------------------- | ---------------------- |
| 1   | 收窄路径跑 Guardian | pending | `python ufc_harness/run_harness.py guardian <path> --fail-on-p0` | `<path>` 默认 `ufc_core` |
| 2   | Naming         | pending | `python ufc_harness/run_harness.py naming`                       |                        |
| 3   | Closure        | pending | `python ufc_harness/run_harness.py closure`                      |                        |


`state` 取值：`pending` | `in_progress` | `done` | `blocked`

## Next action（只写当前一步）

- **current_step_id**：与上方 Subtasks 中 **in_progress** 或首个 **pending** 对齐。
- 本段用一句话写清「现在只做哪一条子任务」。

（在此编辑）

## Log（可选）


| ts (UTC) | step_id | harness | rc  | note |
| -------- | ------- | ------- | --- | ---- |
|          |         |         |     |      |


