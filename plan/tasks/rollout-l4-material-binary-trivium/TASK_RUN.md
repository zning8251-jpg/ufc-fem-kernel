---
task_run_version: "1.0"
session: "rollout-l4-material-binary-trivium"
status: completed
current_step_id: "7"
updated_at: "2026-05-15T20:16:00Z"
governance_change_id: "rollout-l4-material-binary-trivium"
---

# TASK_RUN

UFC 长任务运行卡（约定路径：`plan/tasks/<session>/TASK_RUN.md`，见 `plan/README.md`）。**单一真相源**：子任务状态以本文件为准；新开 IDE 会话时先读本文件并执行 `python ufc_harness/run_harness.py agent-task status --session rollout-l4-material-binary-trivium`。

变更包（规格环）：[`plan/changes/rollout-l4-material-binary-trivium/`](../../changes/rollout-l4-material-binary-trivium)。

## Goal

L4_PH / Material 试点：按「二元结构（四型+Args）+ 空间/时间/动作」方法论对齐入口脊索（见变更包 `tasks.md` §1），防漂移与流程失控。

## Roles（逻辑角色）

| 角色 | 职责摘要 |
|------|----------|
| 实现 | 改 `ufc_core/L4_PH/Material` 下列文件并补测 |
| 守门 | `discipline verify` → `guardian --fail-on-p0` → `naming` |
| 文档 | 变更包与 CONTRACT 对齐；不擅自改 `docs/` 规范正文除非任务授权 |

## Context pointers（按需加载）

- `AGENTS.md`；`npx openskills read ufc-governance-triad,fem-kernel-architecture,ufc-structured-io,ufc-naming-checker,fem-kernel-data-contract`
- `ufc_governance/triad/flow/PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md`
- `ufc_core/L4_PH/Material/CONTRACT.md`
- `plan/changes/rollout-l4-material-binary-trivium/specs/l4-material-binary-trivium/spec.md`

## References

| Tier | Path / anchor | 用途 |
|------|----------------|------|
| T2 | `ufc_core/L4_PH/Material/CONTRACT.md` | 域合同 SSOT |
| T3 | `plan/changes/rollout-l4-material-binary-trivium/` | 本波次规格与任务 |
| Flow | `ufc_governance/triad/flow/PLAYBOOK_FEATURE.md` | 通用七步 |

## Subtasks

| id | subtask | state | next_harness | notes |
|----|---------|-------|--------------|-------|
| 1 | 读 CONTRACT + 变更包 spec | done | `python ufc_harness/run_harness.py change-package validate --change-id rollout-l4-material-binary-trivium --strict` | 先验证制品齐全 |
| 2 | 对脊索文件 discipline 提示 | done | `python ufc_harness/run_harness.py discipline verify --touch-path …` | `PH_Mat_Def` / `PH_Mat_Dsp` / `PH_L4_Populate` 各一次 |
| 3 | Guardian 收窄路径 | done | `python ufc_harness/run_harness.py guardian <file> --fail-on-p0` | **整域** `ufc_core/L4_PH/Material` 仍有存量 P0（见 Log）；本波对三脊索单文件扫描 P0=0 |
| 4 | Naming 收窄路径 | done | `python ufc_harness/run_harness.py naming <file>` | 同上三文件；整域 `naming Material` 仍有存量告警，后续波次消化 |
| 5 | 实现 §1 审计结论（f90） | done | （同上 2–4 每批） | 删重复 `PH_Mat_Dispatch.f90`（真源为 `PH_Mat_Dsp`）；脊索补 `Purpose/Theory/Status`；`naming_checker` 登记 `ph_mat_dsp`/`ph_l4_populate`；`CONTRACT.md` 表更新 |
| 6 | 波次末 closure | done | `python ufc_harness/run_harness.py closure --skip-plan-checks` | 报告 `REPORTS/loop_run_20260515_201602.md` |
| 7 | 严格变更包 + 复盘 | done | `python ufc_harness/run_harness.py change-package validate --change-id rollout-l4-material-binary-trivium --strict` | strict OK；未跑 `agent-slow-loop`（可选） |

`state` 取值：`pending` | `in_progress` | `done` | `blocked`

## Next action（只写当前一步）

- **current_step_id**：`7` — 本 session 波次已收尾；下一域请新开 `change_id` + `agent-task init`（见变更包 `tasks.md` §4）。

## Log（可选）

| ts (UTC) | step_id | harness | rc | note |
|----------|---------|---------|----|------|
| 2026-05-15T12:00:00Z | 0 | init | 0 | TASK_RUN 与变更包 rollout-l4-material-binary-trivium 绑定 |
| 2026-05-15T18:30:00Z | 1 | change-package | 0 | strict validate OK rollout-l4-material-binary-trivium |
| 2026-05-15T20:05:00Z | 1 | audit | 0 | 脊索与 CONTRACT 一致：`PH_Mat_Def` 再导出四型+`*_Arg`；Populate 写槽；分派守卫在 `PH_Mat_Dsp`（`PH_Mat_Dispatch_*` 过程名保留） |
| 2026-05-15T20:06:00Z | 3 | guardian | 1 | `guardian ufc_core/L4_PH/Material --fail-on-p0`：**整域**存量 P0>0（例 FLOW-003/DEP-001 等），本波不展开全域修复 |
| 2026-05-15T20:10:00Z | 5 | impl | 0 | 删除重复 `PH_Mat_Dispatch.f90`；`CONTRACT` 表改列 `PH_Mat_Dsp.f90`；`ufc_harness/.../naming_checker.py` 增加 `_PH_MAT_FACE_MODULE_NAMES` |
| 2026-05-15T20:16:00Z | 6 | closure | 0 | `closure --skip-plan-checks` → `REPORTS/loop_run_20260515_201602.md` |
| 2026-05-15T20:16:00Z | 7 | change-package | 0 | strict validate OK（合并 closure 后） |
