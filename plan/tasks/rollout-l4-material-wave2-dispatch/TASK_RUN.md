---
task_run_version: "1.0"
session: "rollout-l4-material-wave2-dispatch"
status: completed
current_step_id: "7"
updated_at: "2026-05-15T20:42:00Z"
governance_change_id: "rollout-l4-material-wave2-dispatch"
---

# TASK_RUN

UFC 长任务运行卡（约定路径：`plan/tasks/<session>/TASK_RUN.md`，见 `plan/README.md`）。**单一真相源**：子任务状态以本文件为准；新开 IDE 会话时先读本文件并执行 `python ufc_harness/run_harness.py agent-task status --session rollout-l4-material-wave2-dispatch`。

变更包（规格环）：[`plan/changes/rollout-l4-material-wave2-dispatch/`](../../changes/rollout-l4-material-wave2-dispatch)。

## Goal

L4_PH / **Material / Dispatch** 第二波：`guardian` + `naming` **基线**记入 Log，再按变更包 [`tasks.md`](../../changes/rollout-l4-material-wave2-dispatch/tasks.md) 小步消 P0（优先单文件 `--fail-on-p0`）。

## Roles（逻辑角色）

| 角色 | 职责摘要 |
|------|----------|
| 实现 | 仅改 `ufc_core/L4_PH/Material/Dispatch/**/*.f90`（§3 可选一笔） |
| 守门 | `discipline verify --touch-path` → `guardian <file> --fail-on-p0` → `naming` |
| 文档 | 变更包与 `CONTRACT.md` 对齐；不擅自改 `docs/` 规范正文除非任务授权 |

## Context pointers（按需加载）

- `AGENTS.md`；`npx openskills read ufc-governance-triad,fem-kernel-architecture,ufc-structured-io,ufc-naming-checker,fem-kernel-data-contract`
- [`ufc_governance/triad/flow/PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md`](../../../ufc_governance/triad/flow/PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md)
- [`ufc_core/L4_PH/Material/CONTRACT.md`](../../../ufc_core/L4_PH/Material/CONTRACT.md)
- [`plan/changes/rollout-l4-material-wave2-dispatch/specs/l4-material-dispatch-wave2/spec.md`](../../changes/rollout-l4-material-wave2-dispatch/specs/l4-material-dispatch-wave2/spec.md)

## References

| Tier | Path / anchor | 用途 |
|------|----------------|------|
| T2 | `ufc_core/L4_PH/Material/CONTRACT.md` | 域合同 SSOT |
| T3 | `plan/changes/rollout-l4-material-wave2-dispatch/` | 本波次规格与任务 |
| Flow | `ufc_governance/triad/flow/PLAYBOOK_FEATURE.md` | 通用七步 |

## Subtasks

| id | subtask | state | next_harness | notes |
|----|---------|-------|--------------|-------|
| 1 | 读 CONTRACT + spec；变更包 strict | done | `python ufc_harness/run_harness.py change-package validate --change-id rollout-l4-material-wave2-dispatch --strict` | |
| 2 | Dispatch 目录 baseline guardian | done | `python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0` | rc=1；P0=11（见 Log）；JSON `REPORTS/guardian_dispatch_wave2.json` |
| 3 | Dispatch 目录 baseline naming | done | `python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/Dispatch` | rc=1（存量 module_suffix 等；已扩展 checker 白名单） |
| 4 | 摘录 §1.3 目标（至多 3 条） | done | — | FLOW-003@`PH_MatEval`/`PH_MatPLMEval`；INTF-001@`PH_MatELA_ElasCall` |
| 5 | （可选）单笔 f90 修复 + 三连 harness | done | `discipline` + `guardian` + `naming` on `PH_MatELA_ElasCall.f90` | 补 MOD-001 头；`naming_checker` 增加 Dispatch 6 MODULE 名白名单；单文件 naming OK |
| 6 | closure | done | `python ufc_harness/run_harness.py closure --skip-plan-checks` | `REPORTS/loop_run_20260515_204017.md` |
| 7 | 严格变更包 | done | `python ufc_harness/run_harness.py change-package validate --change-id rollout-l4-material-wave2-dispatch --strict` | |

`state` 取值：`pending` | `in_progress` | `done` | `blocked`

## Next action（只写当前一步）

- **current_step_id**：`7` — 本波次已收尾；下一子树请新开 `change_id`（见变更包 `tasks.md` §5）。

## Log（可选）

| ts (UTC) | step_id | harness | rc | note |
|----------|---------|---------|----|------|
| 2026-05-15T20:38:00Z | 0 | init | 0 | TASK_RUN 绑定 `governance_change_id=rollout-l4-material-wave2-dispatch` |
| 2026-05-15T20:40:00Z | 1 | change-package | 0 | strict OK |
| 2026-05-15T20:40:30Z | 2 | guardian | 1 | Dispatch 目录：P0=11、P1=37、P2=17（`REPORTS/guardian_dispatch_wave2.json`）；P0 均为 FLOW-003，集中在 `PH_MatEval.f90` / `PH_MatPLMEval.f90` |
| 2026-05-15T20:40:45Z | 3 | naming | 1 | Dispatch 目录首跑：存量 module_suffix；后于子任务 5 扩展 `_PH_MAT_FACE_MODULE_NAMES` 后 **复跑 naming Dispatch → rc=0** |
| 2026-05-15T20:41:00Z | 4 | triage | 0 | §1.3 优先：**(1)** `PH_MatEval` FLOW-003 **(2)** `PH_MatPLMEval` FLOW-003 **(3)** `UF_Mat_Elastic_Calc` INTF-001（P1，Arg 迁移） |
| 2026-05-15T20:41:30Z | 5 | impl | 0 | `PH_MatELA_ElasCall.f90` Purpose/Theory/Status；`naming_checker.py` Dispatch 白名单 |
| 2026-05-15T20:42:00Z | 6 | closure | 0 | skip-plan-checks |
| 2026-05-15T20:42:00Z | 7 | change-package | 0 | strict OK |
| 2026-05-15T22:10:00Z | 8 | impl | 0 | P1：`UF_Mat_Elastic_Calc` → `UF_Mat_Elastic_Calc_Arg`（INTF-001）；新增 `PH_Mat_Defn_UMAT_Bridge`（`Defn_Invoke_UMAT`+`PH_Mat_TypeToId`）；`PH_MatPLM_PlastCall`/`PH_Mat_Spcl_Def`/`MD_MatLibPH_Brg` 挂接；`ufc_core/Testing/test_defn_invoke_umat.f90`；Guardian INTF-001@`PH_MatELA_ElasCall` → 0 |
| 2026-05-15T23:45:00Z | 9 | follow-up | 0 | **New change_id** [`intf001-mat-plast-spcl-arg`](../../changes/intf001-mat-plast-spcl-arg/)：`UF_Mat_Plast_Calc`/`UF_Mat_Special_Calc` → `*_Arg`；plastic `PH_Mat_TypeToId` 201–227 + stub `201:227`；`change-package validate --strict` |
| 2026-05-16T14:00:00Z | 10 | impl | 0 | [`intf001-mat-plast-spcl-arg`](../../changes/intf001-mat-plast-spcl-arg/)：`Defn_Invoke_UMAT` → **`Defn_Invoke_UMAT_Arg`**；`PH_MatELA_ElasCall`/`PH_MatPLM_PlastCall`/`PH_Mat_Spcl_Def` + tests；Guardian INTF-001@`PH_Mat_Defn_UMAT_Bridge` → 0 |
